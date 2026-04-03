create   procedure dbo.monitor_deviation
(
	@period_type nvarchar(10) = 'day'
	, @history_days int = 90
	, @use_seasonality_override bit = null
)
as
begin
	set nocount on;
	declare @date_from date = dateadd(day, -@history_days, cast(getdate() as date));
	declare @date_to date = cast(getdate() as date);
	declare @group_expr nvarchar(max);
	if @period_type = 'day'
		set @group_expr = 'cast(create_date as date)';
	else if @period_type = 'week'
		set @group_expr = 'dateadd(week, datediff(week, 0, create_date), 0)';
	else if @period_type = 'month'
		set @group_expr = 'datefromparts(year(create_date), month(create_date), 1)';
	else
	begin
		raiserror ('Некорректный вид периода. Используйте day/week/month', 16, 1);
		return;
	end
	declare @sql nvarchar(max);
	set @sql = '
with base as (
	select
		' + @group_expr + ' as period_date,
		datepart(weekday, create_date) as weekday_num,
		count(*) as total_cnt,
		sum(case when carDocPfotoPTS is not null then 1 else 0 end) as success_cnt
	from dbo.request
	where create_date >= @date_from
		and create_date < @date_to
	group by ' + @group_expr + ', datepart(weekday, create_date)
),
overall as (
	select
		sum(total_cnt) as total_all,
		sum(success_cnt) as success_all,
		cast(sum(success_cnt) as float) / nullif(sum(total_cnt),0) as conv_all
	from base
),
weekday_stats as (
    select
        weekday_num,
        sum(success_cnt) as wd_success,
        sum(total_cnt) as wd_total,
        cast(sum(success_cnt) as float) / nullif(sum(total_cnt),0) as wd_conv
    from base
    group by weekday_num
),
seasonality_check as (
	select
		w.weekday_num,
		w.wd_conv,
		o.conv_all,
		(w.wd_conv - o.conv_all) / nullif(sqrt(o.conv_all * (1 - o.conv_all) / w.wd_total), 0) as z_value
	from weekday_stats w
	cross join overall o
),
seasonality_flag as (
	select 
		case when max(abs(z_value)) >= 2.58 then 1 else 0 end as has_seasonality
	from seasonality_check
),
final_agg as (
	select
		period_date,
		sum(total_cnt) as total_cnt,
		sum(success_cnt) as success_cnt,
		cast(sum(success_cnt) as float) / nullif(sum(total_cnt), 0) as conversion
	from base
	group by period_date
)
select 
	f.period_date,
	f.total_cnt,
	f.success_cnt,
	f.conversion,
	s.has_seasonality
from final_agg f
cross join seasonality_flag s
order by f.period_date;
';
exec sp_executesql
	@sql,
	N'@date_from date, @date_to date',
	@date_from = @date_from,
	@date_to = @date_to;
end
