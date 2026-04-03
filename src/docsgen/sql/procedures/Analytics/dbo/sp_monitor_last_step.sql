create   procedure sp_monitor_last_step
 @current_step_col   nvarchar(128),  -- текущий шаг
    @next_step_col      nvarchar(128),  -- следующий шаг
    @period_type        nvarchar(20) = 'day', -- 'day', 'week', 'month'
    @history_depth      int = 30,       -- количество таких же периодов в прошлом для сравнения
    @check_seasonality  bit = 1         -- 1 = включить сезонность (только для 'day')
as
begin
    set nocount on;

    declare @sql nvarchar(max);
    declare @partition_clause nvarchar(max) = '';
    declare @days_in_period int;

    -- 1. валидация полей
    if not exists (select 1 from sys.columns where object_id = object_id('request') and name = @current_step_col)
    begin
        raiserror('ошибка: поле [%s] не найдено.', 16, 1, @current_step_col);
        return;
    end

    -- 2. определяем размер скользящего окна в днях
    set @days_in_period = case 
        when @period_type = 'day'   then 1
        when @period_type = 'week'  then 7
        when @period_type = 'month' then 30
        else 1
    end;

    -- 3. настройка сезонности (только для посуточного режима)
    if @check_seasonality = 1 and @period_type = 'day'
    begin
        set @partition_clause = 'partition by datepart(weekday, period_start)';
    end

    -- 4. сборка динамического sql
    set @sql = N'
    with daily_data as (
        -- сначала агрегируем данные по дням (чистые сутки)
        select 
            dateadd(day, datediff(day, 0, ' + quotename(@current_step_col) + '), 0) as day_date,
            count(number) as daily_count
        from request
        where ' + quotename(@current_step_col) + ' is not null 
          and ' + quotename(@next_step_col) + ' is not null
          -- исключаем текущий незавершенный день
          and ' + quotename(@current_step_col) + ' < dateadd(day, datediff(day, 0, getdate()), 0)
        group by dateadd(day, datediff(day, 0, ' + quotename(@current_step_col) + '), 0)
    ),
    sliding_periods as (
        -- формируем скользящие окна (суммируем последние N дней для каждой даты)
        select 
            day_date as period_start,
            sum(daily_count) over (
                order by day_date 
                rows between ' + cast((@days_in_period - 1) as nvarchar) + ' preceding and current row
            ) as passed_count
        from daily_data
    ),
    stats as (
        -- считаем среднее и отклонение по истории таких же скользящих окон
        select 
            *,
            avg(cast(passed_count as float)) over (
                ' + @partition_clause + '
                order by period_start 
                rows between ' + cast(@history_depth as nvarchar) + ' preceding and 1 preceding
            ) as avg_val,
            stdevp(cast(passed_count as float)) over (
                ' + @partition_clause + '
                order by period_start 
                rows between ' + cast(@history_depth as nvarchar) + ' preceding and 1 preceding
            ) as std_dev,
            count(*) over (
                ' + @partition_clause + '
                order by period_start 
                rows between ' + cast(@history_depth as nvarchar) + ' preceding and 1 preceding
            ) as rows_in_window
        from sliding_periods
    ),
    z_score_calc as (
        select 
            *,
            case 
                when rows_in_window < ' + cast(@history_depth as nvarchar) + ' then null 
                when std_dev = 0 or std_dev is null then 0
                else (passed_count - avg_val) / std_dev 
            end as z_score
        from stats
    )
    -- выводим только последнюю строку (вчерашний день + окно назад)
    select --top 1
        case 
            when ' + cast(@days_in_period as nvarchar) + ' = 1 then convert(nvarchar, period_start, 104)
            else convert(nvarchar, dateadd(day, -' + cast((@days_in_period - 1) as nvarchar) + ', period_start), 104) 
                 + '' - '' + convert(nvarchar, period_start, 104)
        end as [интервал анализа],
        passed_count as [всего заявок],
        round(avg_val, 2) as [среднее (история)],
        case 
            when z_score is null then N''обучение''
            when abs(z_score) > 3 then N''критическое отклонение''
            when abs(z_score) > 2 then N''повышенное отклонение''
            else N''норма''
        end as [статус],
        case 
            when z_score > 2 then N'' рост''
            when z_score < -2 then N'' падение''
            else N''--''
        end as [направление]
    from z_score_calc
    order by period_start desc;';

    exec sp_executesql @sql;
end
