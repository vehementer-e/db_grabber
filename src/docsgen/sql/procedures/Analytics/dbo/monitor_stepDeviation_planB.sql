create   procedure dbo.monitor_stepDeviation_planB
(
    @step_field sysname,
    @period_type varchar(10),
    @history_periods int = 30,
    @check_seasonality bit = 1
)
as
begin
set nocount on;
    
if not exists (select 1 from sys.columns where object_id = object_id('dbo.request') and name = @step_field)
begin
    raiserror('Поле %s не найдено', 16, 1, @step_field);
    return;
end

declare @date_from datetime, @date_to datetime;
set @date_to = cast(getdate() as date); 

if @period_type = 'day'   set @date_from = dateadd(day, -1, @date_to);
else if @period_type = 'week'  begin set @date_to = dateadd(week, datediff(week, 0, getdate()), 0); set @date_from = dateadd(week, -1, @date_to); end
else if @period_type = 'month' begin set @date_to = datefromparts(year(getdate()), month(getdate()), 1); set @date_from = dateadd(month, -1, @date_to); end

declare @sql nvarchar(max);
set @sql = N'
with raw_data as (
    select 
        case 
            when @p_type = ''day''   then cast(call1 as date)
            when @p_type = ''week''  then dateadd(week, datediff(week, 0, call1), 0)
            when @p_type = ''month'' then datefromparts(year(call1), month(call1), 1)
			end as period_start,
			count(number) as total_requests,
			count(case when ' + quotename(@step_field) + ' is not null then number end) as step_requests
    from dbo.request
    where call1 >= dateadd(year, -1, getdate()) -- Ограничиваем историю 1 годом для скорости
        and returnType = ''Первичный''
        and isDubl = ''0''
        and productType = ''PTS''
    group by 
        case 
            when @p_type = ''day''   then cast(call1 as date)
            when @p_type = ''week''  then dateadd(week, datediff(week, 0, call1), 0)
            when @p_type = ''month'' then datefromparts(year(call1), month(call1), 1)
        end
),
metrics as (
    select 
        period_start,
		total_requests,
        step_requests,
        case when total_requests = 0 then 0 else cast(step_requests as float) / total_requests end as step_ratio
    from raw_data
),
current_v as (
    select step_requests, step_ratio 
    from metrics 
    where period_start = @d_from
		and total_requests >= 50 
),
history_source as (
    select period_start, step_ratio
    from metrics
    where period_start < @d_from
		and total_requests >= 50
        and (
        (@p_type <> ''day'' or @use_season = 0) 
        or datepart(weekday, period_start) = datepart(weekday, @d_from)
        )
),
history_limited as (
    select top (@h_limit) step_ratio
    from history_source
    order by period_start desc
),
stats as (
    select 
        avg(step_ratio) as avg_ratio,
        stdev(step_ratio) as std_ratio
    from history_limited
)
select 
    @d_from as [период],
    c.step_requests as [заявок_на_шаге],
    cast(c.step_ratio * 100 as decimal(10,2)) as [текущая_конверсия_%],
    cast(s.avg_ratio * 100 as decimal(10,2)) as [средняя_конверсия_%],
    case 
        when s.std_ratio = 0 or s.std_ratio is null then 0
        else cast((c.step_ratio - s.avg_ratio) / s.std_ratio as decimal(10,2))
    end as [z_score_по_конверсии],
    case 
        when abs((c.step_ratio - s.avg_ratio) / nullif(s.std_ratio, 0)) >= 3 then ''Критичное отклонение''
        when abs((c.step_ratio - s.avg_ratio) / nullif(s.std_ratio, 0)) >= 2 then ''Повышенное отклонение''
        else ''Норма''
    end as [статус]
from current_v c 
cross join stats s;';

exec sp_executesql @sql, 
    N'@d_from datetime, @p_type varchar(10), @h_limit int, @use_season bit', 
    @date_from, @period_type, @history_periods, @check_seasonality;
end
