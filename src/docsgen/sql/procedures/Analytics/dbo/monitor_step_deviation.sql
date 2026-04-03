create   procedure dbo.monitor_step_deviation
(
    @step_field sysname, -- поле шага
    @period_type varchar(10), -- day/week/month
    @history_periods int = 30 -- размер исторического окна
)
as
begin
    set nocount on;
    if not exists (
        select 1 from sys.columns 
        where object_id = object_id('dbo.request') and name = @step_field
    )
    begin
        raiserror('Указанного поля шага не существует', 16, 1);
        return;
    end

declare @sql nvarchar(max);
declare @period_expr nvarchar(max);
declare @period_filter nvarchar(max);
declare @created_expr nvarchar(max);

    if @period_type = 'day'
    begin
        set @period_expr = 'cast(' + quotename(@step_field) + ' as date)'
        set @created_expr = 'cast(created as date)'
        set @period_filter = ' < cast(getdate() as date)'
    end
    else if @period_type = 'week'
    begin
        set @period_expr = 'dateadd(week, datediff(week, 0, ' + quotename(@step_field) + '), 0)'
        set @created_expr = 'dateadd(week, datediff(week, 0, created), 0)'
        set @period_filter = ' < dateadd(week, datediff(week, 0, getdate()), 0)'
    end
    else
    begin
        set @period_expr = 'datefromparts(year(' + quotename(@step_field) + '), month(' + quotename(@step_field) + '), 1)'
        set @created_expr = 'datefromparts(year(created), month(created), 1)'
        set @period_filter = ' < datefromparts(year(getdate()), month(getdate()), 1)'
    end

    set @sql = '
with base as (
	select 
		' + @period_expr + ' as period_date,
		count(*) as step_cnt
	from dbo.request
	where ' + quotename(@step_field) + ' is not null
		and ' + @period_expr + @period_filter + '
		and ' + quotename(@step_field) + ' >= dateadd(month, -12, getdate()) -- оптимизация: берем за последний год
		and productType = ''PTS''
		and returnType = ''Первичный''
		and _carDocPhotoPTS is not null
		and isDubl = 0
		and entrypoint not like ''LKD''
	group by ' + @period_expr + '
),
created_stats as (
	select 
		' + @created_expr + ' as created_period,
		count(*) as created_cnt
	from dbo.request
	where created >= dateadd(month, -12, getdate())
		and productType = ''PTS''
		and returnType = ''Первичный''
		and _carDocPhotoPTS is not null
		and isDubl = 0
		and entrypoint not like ''LKD''
	group by ' + @created_expr + '
		
),
metrics as (
	select 
		b.period_date,
		b.step_cnt,
		isnull(c.created_cnt, 0) as created_cnt,
		conversion = cast(b.step_cnt as float) / nullif(c.created_cnt, 0)
	from base b
	left join created_stats c on b.period_date = c.created_period
),
ordered as (
	select *, rn = row_number() over (order by period_date desc)
	from metrics
),
history as (
	select 
		avg_step = avg(step_cnt * 1.0),
		std_step = stdev(step_cnt * 1.0),
		avg_conv = avg(conversion),
		std_conv = stdev(conversion)
	from ordered
	where rn between 2 and ' + cast(@history_periods + 1 as varchar) + '
)
select 
	curr.period_date,
	curr.step_cnt as current_steps,
	curr.conversion as current_conv,
	h.avg_step,
	h.std_step,
	z_score_step = (curr.step_cnt - h.avg_step) / nullif(h.std_step, 0),
	z_score_conv = (curr.conversion - h.avg_conv) / nullif(h.std_conv, 0),
	status = case 
	when abs((curr.step_cnt - h.avg_step) / nullif(h.std_step, 0)) >= 2.58 then ''Критично отклонение''
	when abs((curr.step_cnt - h.avg_step) / nullif(h.std_step, 0)) >= 1.96 then ''Повышенное отклонение''
	else ''Норма''
	end
from ordered curr
cross join history h
where curr.rn = 1;'

    exec sp_executesql @sql;
end
