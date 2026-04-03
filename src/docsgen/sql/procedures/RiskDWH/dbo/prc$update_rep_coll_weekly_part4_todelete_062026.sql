

--exec [dbo].[prc$update_rep_coll_weekly_part4]

CREATE procedure [dbo].[prc$update_rep_coll_weekly_part4] as 

set datefirst 1;

declare @src_name nvarchar(100) = 'Plans for weekly coll report';

--declare @rdt date = dateadd(dd,-1,cast(getdate() as date));
declare @rdt date = dateadd(dd,-1, cast(RiskDWH.dbo.date_trunc('wk', cast(getdate() as date)) as date));


declare @lysd_dt_from date = dateadd(dd,1,EOMONTH(@rdt, -13));
declare @lysd_dt_to date = dateadd(yy,-1,@rdt);

declare @lm_dt_from date = dateadd(dd,1,EOMONTH(@rdt,-2));
declare @lmsd_dt_to date = dateadd(MM,-1,@rdt);
declare @lm_dt_to date = eomonth(@rdt,-1);

declare @cm_dt_from date = dateadd(dd,1,eomonth(@rdt,-1));


declare @cw_dt_from date = RiskDWH.dbo.date_trunc('wk',@rdt);

declare @lw_dt_from date = dateadd(dd,-7,RiskDWH.dbo.date_trunc('wk',@rdt));
declare @lw_dt_to date = dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk',@rdt));

declare @march2020_from date = cast('2020-03-01' as date);
declare @march2020_to date = cast('2020-03-31' as date);


exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'START';


exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#month_coll_plan_base';

--база с планом (переходы в низшие бакеты для 1-30, 31-60, 61-90)
drop table if exists #month_coll_plan_base;

with last_plan as (
	select rep_month, max(plan_version) as mx_vers
	from RiskDWH.dbo.det_coll_plan
	group by rep_month
)
select 
coalesce(a.product,'PTS') as product, --15.02.2022
a.rep_month, a.bucket_from, a.bucket_to, a.total_balance,
a.total_balance * (isnull(b.k1,1) - isnull(b.k2,0)) / isnull(b.k1,1) as total_bal_adj 

into #month_coll_plan_base

from RiskDWH.dbo.det_coll_plan a
inner join last_plan l
on a.rep_month = l.rep_month
and a.plan_version = l.mx_vers
left join RiskDWH.dbo.det_coll_bucket_migr_adj_coef b
on a.bucket_from = b.bucket_from
and a.bucket_to = b.bucket_to

where a.bucket_from in ('(2)_1_30','(3)_31_60','(4)_61_90');


exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#month_coll_plan';
--план с дополнительными суммами по бакету выхода
drop table if exists #month_coll_plan;

select mm.rep_month, mm.bucket_from, mm.bucket_to, mm.total_balance, mm.total_bal_adj, mm.product
into #month_coll_plan
from (
	select m.rep_month, m.bucket_from, m.bucket_to, 
	m.total_balance, 
	m.total_bal_adj, 
	m.product --15.02.2022
	from #month_coll_plan_base m
union all
	select m.rep_month, concat(m.bucket_from, '_ttl') as bucket_from,  null as bucket_to, 
	sum(m.total_balance) as total_balance, 
	sum(m.total_bal_adj) as total_bal_adj,
	m.product --15.02.2022
	from #month_coll_plan_base m
	group by m.rep_month, concat(m.bucket_from, '_ttl'), m.product
) mm;

--план по дням (только с мая 2020)
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#daily_coll_plan';

drop table if exists #daily_coll_plan;

select a.rep_dt, b.bucket_from, b.bucket_to, 
a.coefficient * b.total_balance as total_balance,
a.coefficient * b.total_bal_adj as total_bal_adj,
coalesce(a.product,'PTS') as product --15.02.2022
into #daily_coll_plan
from RiskDWH.dbo.det_coll_daily_plan a
left join #month_coll_plan b
on concat(a.bucket_from,'_ttl') = b.bucket_from
and eomonth(a.rep_dt) = b.rep_month
and b.bucket_from like '%ttl'
and coalesce(a.product,'PTS') = b.product --15.02.2022



	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'rep_coll_weekly_plans';


--планы для отчета
delete from RiskDWH.dbo.rep_coll_weekly_plans
where rep_dt = @rdt;

insert into RiskDWH.dbo.rep_coll_weekly_plans
select 
@rdt as rep_dt,
cast(sysdatetime() as datetime) as dt_dml,
concat(aa.seg,'#',aa.bucket_from,'#',aa.bucket_to) as metric,
aa.seg, aa.bucket_from, aa.bucket_to, aa.total_balance, aa.total_bal_adj,
aa.product --15.02.2022


from (
	select 'CM' as seg, a.bucket_from, a.bucket_to, a.total_balance, a.total_bal_adj, a.product /*15.02.2022*/
	from #month_coll_plan a
	where a.rep_month = eomonth(@cm_dt_from)

union all

	select 'LM' as seg, a.bucket_from, a.bucket_to, a.total_balance, a.total_bal_adj, a.product /*15.02.2022*/
	from #month_coll_plan a
	where a.rep_month = eomonth(@lm_dt_from)

union all

	select 'CW' as seg, b.bucket_from, b.bucket_to, 
	sum(b.total_balance) as total_balance,
	sum(b.total_bal_adj) as total_bal_adj, 
	b.product /*15.02.2022*/
	from #daily_coll_plan b
	where b.rep_dt between @cw_dt_from and @rdt
	group by b.bucket_from, b.bucket_to, b.product /*15.02.2022*/

union all

	select 'LW' as seg, b.bucket_from, b.bucket_to, 
	sum(b.total_balance) as total_balance,
	sum(b.total_bal_adj) as total_bal_adj,
	b.product /*15.02.2022*/
	from #daily_coll_plan b
	where b.rep_dt between @lw_dt_from and @lw_dt_to
	group by b.bucket_from, b.bucket_to, b.product /*15.02.2022*/
) aa


--select cast(a.Дата as date) as rep_dt, a.Бакет, a.[Сумма план] 
--from [Stg].[files].[CollectionPlan_buffer]    a
--where cast(a.Дата as date) between '2020-03-01' and '2020-03-31'
--and a.Бакет in ('(2)_1_30','(3)_31_60','(4)_61_90')
--order by a.Бакет, a.Дата;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'drop temp (#) tables';

	drop table #daily_coll_plan;
	drop table #month_coll_plan;
	drop table #month_coll_plan_base;

	drop table if exists ##CMR_weekly

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'FINISH';
