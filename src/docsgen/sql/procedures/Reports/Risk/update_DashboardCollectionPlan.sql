
CREATE procedure [Risk].[update_DashboardCollectionPlan] as 

declare @srcname varchar(100) = 'DAILY COLLECTION DASHBOARD PLAN UPDATE';
declare @vinfo varchar(100);
declare @rdt date = cast(getdate() as date); --'2021-12-31'
declare @flag_exists int = 1;
declare @flag_sums int= 1;
declare @flag_coefs int= 1;
declare @flag_negative int = 1;




set @vinfo = concat('START rdt = ', format(@rdt, 'dd.MM.yyyy') );

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


--проверяем наличие пересчитанного плана 
select @flag_exists = iif(count(*)>0,0,1) 
from RiskDWH.dbo.coll_daily_plan_dashboard a
where a.date_on = @rdt
;



--Сравниваем сумму пересчитанного плана до конца месяца с изначальным планом
drop table if exists #check1;
with p as (
	select a.rep_month, a.bucket_from as dpd_bucket, 
	sum(a.total_balance) as saved_bal, 
	round( sum( a.total_balance * (isnull(c.k1,1) - isnull(c.k2,0)) / isnull(c.k1,1) ), 0) as val
	from RiskDWH.dbo.det_coll_plan a
	inner join (
		select b.rep_month, max(b.plan_version) as mx_vers
		from RiskDWH.dbo.det_coll_plan b
		group by b.rep_month
	) bb
	on a.rep_month = bb.rep_month
	and a.plan_version = bb.mx_vers
	left join RiskDWH.dbo.det_coll_bucket_migr_adj_coef c
	on a.bucket_from = c.bucket_from
	and a.bucket_to = c.bucket_to
	where a.rep_month = EOMONTH(dateadd(dd,-1, @rdt))
	group by a.rep_month, a.bucket_from
), agg as (
	select a.date_on, a.dt_dml, a.dpd_bucket, 
	round(sum(a.sum1)*1000000,0) as sum1,
	round(sum(a.sum2)*1000000,0) as sum2,
	round(sum(a.sum3)*1000000,0) as sum3
	from RiskDWH.dbo.coll_daily_plan_dashboard a
	where a.date_on = @rdt
	group by a.date_on, a.dt_dml, a.dpd_bucket
)
select agg.*, p.val,
round(agg.sum1 - p.val,4) as delta1,
round(agg.sum2 - p.val,4) as delta2,
round(agg.sum3 - p.val,4) as delta3
into #check1
from agg
left join p 
on agg.dpd_bucket = p.dpd_bucket
order by agg.dpd_bucket;



select @flag_sums = 
sign(
	sum(case when abs(a.delta1) > 10 then 1 else 0 end) +
	sum(case when abs(a.delta2) > 10 then 1 else 0 end) +
	sum(case when abs(a.delta3) > 10 then 1 else 0 end) 
)
from #check1 a
;



--Проверка суммы дневных коэффициентов (=1?)
drop table if exists #check2;
select 
EOMONTH(a.rep_dt) as rep_month,
a.bucket_from, 
a.product,
--round(sum(a.coefficient),4) as sum_coef,
round(sum(a.coefficient_adj),4) as sum_coef_adj
into #check2
from RiskDWH.dbo.det_coll_daily_plan a
where EOMONTH(a.rep_dt) = eomonth(dateadd(dd,-1,@rdt))
and exists (select 1 from RiskDWH.dbo.det_coll_plan b
				where eomonth(a.rep_dt) = b.rep_month
					and a.bucket_from = b.bucket_from
					and a.product = b.product)
group by EOMONTH(a.rep_dt) ,
a.bucket_from,
a.product
;


select @flag_coefs =
sign( sum(case when a.sum_coef_adj <> 1 then 1 else 0 end) )
from #check2 a
;




/*Проверка дневного плана на отрицательность*/
with base as (
select a.date_on, a.dt_dml, a.dpd_bucket, a.r_date,
case when a.r_date < @rdt then a.fact_sb
else a.plan_new end as plan_calc
from RiskDWH.dbo.stg_calc_coll_daily_plan a
where a.date_on = @rdt
)
select @flag_negative = sign(count(*))
from base bs
where bs.plan_calc < 0
;





select @vinfo = case when @flag_exists = 0 then 'План рассчитан' else '(!) НЕТ рассчитанного плана' end
exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

select @vinfo = case when @flag_sums = 0 then 'Суммы до конца месяца сходятся с начальным планом' else '(!) Суммы до конца месяца НЕ сходятся с начальным планом' end
exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

select @vinfo = case when @flag_coefs = 0 then 'Сумма дневных коэф равна 1' else '(!) Сумма дневных коэф НЕ равна 1' end
exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

select @vinfo = case when @flag_negative = 0 then 'В плане отсутствуют отрицательные значения' else '(!) В плане есть отрицательные значения' end
exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;





if (@flag_coefs + @flag_exists + @flag_negative + @flag_sums) = 0 
begin

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'MERGE';


--обновляем целевую таблицу с операционным планом Collection

drop table if exists #for_merge;
select 
a.r_date, 
a.dpd_bucket, 
isnull(a.sum1,0) as sum1, 
isnull(a.sum2,0) as sum2,
isnull(a.sum3,0) as sum3
into #for_merge
from RiskDWH.dbo.coll_daily_plan_dashboard a
where a.date_on = @rdt





merge into [stg].[files].[CollectionPlan_buffer] dst
using #for_merge src
on (dst.[Дата] = src.r_date and dst.[Бакет] = src.dpd_bucket)
when matched then 
update set 
	dst.[Сумма среднее] = src.sum1,
	dst.[Сумма план] = src.sum2,
	dst.[Сумма план успех] = src.sum3
when not matched then 
insert (
	[Дата]
	,[Бакет]
	,[Сумма среднее]
	,[Сумма план]
	,[Сумма план успех]
	,[created]
) values (
	src.r_date,
	src.dpd_bucket,
	src.sum1,
	src.sum2,
	src.sum3,
	cast(getdate() as datetime)
)
;


end;


exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';