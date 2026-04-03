create   procedure sp_monitor_step_full_analytics
    @current_step nvarchar(128),
    @next_step nvarchar(128),
    @period_type nvarchar(20) = 'day',
    @history_periods int = 30, 
    @check_seasonality bit = 0,
    @ignore_days int = 1,
    @date_column nvarchar(128) = NULL
as
begin
    set nocount on;
    declare @sql nvarchar(max);
    declare @partition_s nvarchar(max) = '';
    declare @final_date_col nvarchar(max) = isnull(quotename(@date_column), 'coalesce(call1, created)');
    
    declare @days_in_period int = case 
        when @period_type = 'day' then 1
		when @period_type = 'week' then 7
        when @period_type = '2week' then 14
		when @period_type = 'month' then 31
		else 1
    end;

if not exists (select 1 from sys.columns where object_id = object_id('request') and name = @current_step)
begin
    raiserror('Поле [%s] не найдено.', 16, 1, @current_step);
    return;
end

if not exists (select 1 from sys.columns where object_id = object_id('request') and name = @next_step)
begin
    raiserror('Поле [%s] не найдено.', 16, 1, @next_step);
    return;
end

if @check_seasonality = 1 and @period_type = 'day'
    set @partition_s = 'partition by datepart(weekday, day_date)';

set @sql = cast(N' ' as nvarchar(max)) + N'
declare @target_date datetime = dateadd(day, datediff(day, 0, getdate()) - ' + cast(@ignore_days as nvarchar) + ', 0);

with daily_data as (
    select 
        dateadd(day, datediff(day, 0, ' + @final_date_col + '), 0) as day_date,
        count(' + quotename(@current_step) + ') as total_count,
        count(' + quotename(@next_step) + ') as conv_count,
        avg(cast(datediff(second, ' + quotename(@current_step) + ', ' + quotename(@next_step) + ') as float)) as avg_time_raw
    from request
    where 
		productType = ''PTS'' 
		and returnType = ''Первичный'' 
		and isDubl = ''0''
        and ' + @final_date_col + ' < dateadd(day, 1, @target_date)
        and ' + @final_date_col + ' >= dateadd(day, -(' + cast(@history_periods as nvarchar) + ' + 60), @target_date)
    group by dateadd(day, datediff(day, 0, ' + @final_date_col + '), 0)
),
sliding_periods as (
    select day_date,
        sum(total_count) over (order by day_date rows between ' + cast((@days_in_period - 1) as nvarchar) + ' preceding and current row) as vol_sum,
        sum(conv_count) over (order by day_date rows between ' + cast((@days_in_period - 1) as nvarchar) + ' preceding and current row) as pass_sum,
        avg(avg_time_raw) over (order by day_date rows between ' + cast((@days_in_period - 1) as nvarchar) + ' preceding and current row) as time_sum
    from daily_data
),
metrics as (
    select *, (cast(pass_sum as float) / nullif(vol_sum, 0)) * 100 as cr_percent from sliding_periods
),
stats as (
    select *,
        avg(cast(vol_sum as float)) over (' + @partition_s + ' order by day_date rows between ' + cast(@history_periods as nvarchar) + ' preceding and 1 preceding) as avg_vol,
        stdevp(cast(vol_sum as float)) over (' + @partition_s + ' order by day_date rows between ' + cast(@history_periods as nvarchar) + ' preceding and 1 preceding) as std_vol,
        avg(cr_percent) over (' + @partition_s + ' order by day_date rows between ' + cast(@history_periods as nvarchar) + ' preceding and 1 preceding) as avg_cr,
        stdevp(cr_percent) over (' + @partition_s + ' order by day_date rows between ' + cast(@history_periods as nvarchar) + ' preceding and 1 preceding) as std_cr,
        avg(time_sum) over (' + @partition_s + ' order by day_date rows between ' + cast(@history_periods as nvarchar) + ' preceding and 1 preceding) as avg_time,
        stdevp(time_sum) over (' + @partition_s + ' order by day_date rows between ' + cast(@history_periods as nvarchar) + ' preceding and 1 preceding) as std_time,
        count(*) over (' + @partition_s + ' order by day_date rows between ' + cast(@history_periods as nvarchar) + ' preceding and 1 preceding) as rows_in_window
    from metrics
)
select 
    convert(nvarchar, day_date, 104) as target_date_out,
    vol_sum, round(cr_percent, 2), round(time_sum / 60.0, 1),
    round((vol_sum - avg_vol) / (nullif(std_vol, 0) + 1), 2) as z_v,
    round(isnull((cr_percent - avg_cr) / nullif(std_cr + 0.001, 0), 0), 2) as z_c,
    round((time_sum - avg_time) / (nullif(std_time, 0) + 1), 2) as z_t,
    rows_in_window,
    round(avg_vol, 0) as base_vol, 
    round(avg_cr, 2) as base_cr,   
    round(avg_time / 60.0, 1) as base_time
from stats where day_date = @target_date;';

    exec sp_executesql @sql;
end