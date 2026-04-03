-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [riskCollection].[create_61_90_report] AS begin

declare @rdt date
set @rdt = (
SELECT
case when day(GETDATE()) > 15 then DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	when day(GETDATE()) <= 15 and MONTH(GETDATE()) = 1 then DATEFROMPARTS(YEAR(dateadd(yy,-1,GETDATE())), MONTH(dateadd(mm,-1,GETDATE())), 1)
else DATEFROMPARTS(YEAR(GETDATE()), MONTH(dateadd(mm,-1,GETDATE())), 1) end rdt)

BEGIN TRY
---------------------------
--Данные по планам на 61_90
---------------------------

drop table if exists #plans
select rep_dt_month, bucket_from, Product, sum([Приведенный]) reduced_plan
into #plans
from dwh2.riskcollection.daily_plans_1_90 
where rep_dt_month >= '2025-01-01' and bucket_from = '(4)_61_90' and Product ='PTS'
group by rep_dt_month, bucket_from, Product


---------------------------
--Первичные данные по ИМХА
---------------------------
drop table if exists #imha_1 
select 
datefromparts(year(asv.Date), month(asv.Date), 1) as f_d
, asv.CustomerId
, Deals.number as external_id
, year(asv.Date) y
, month(asv.Date) m
,asv.Date
,ass.Name
, asb.name sub_st_name
,asv.Comment
,row_number() over (partition by Deals.number order by asv.Date) as rn
into #imha_1
from stg.[_Collection].[AutoStatusValue] asv
left join stg.[_Collection].[AutosubStatus] asb
	on asb.id = asv.AutoSubStatusId
left join stg.[_Collection].[AutoStatus] ass
	on ass.id = asb.AutoStatusId
left join stg._Collection.Deals Deals
	on Deals.idcustomer = asv.CustomerId
where asv.Date >= @rdt and  ass.id = 1 

drop table if exists #imha_2
select * 
into #imha_2
from #imha_1 
where rn = 1

drop table if exists #imha_3
select * 
into #imha_3
from (
select imha.*, dm.dpd_p_coll, dm.bucket_p_coll, dm.ClaimantStage, 
	ROW_NUMBER() over (partition by imha.CustomerId, imha.Date order by dm.dpd_p_coll desc) rnn
from #imha_2 imha
join dwh2.riskCollection.collection_datamart dm on imha.external_id = dm.external_id and imha.Date = dm.d
) a where rnn = 1

--select * from #imha_3
---------------------------
--Подготавливаем основную выборку данных по бакету 61-90, для дальнейших вычислений
---------------------------
drop table if exists #cur_buck_prep
select datefromparts(year(d), month(d), 1) as f_d,
	dm.*,
	case when dm.[Тип продукта] in ('PDL') then 'PDL' 
	when dm.[Тип продукта] in ('ПТС', 'ПТС31','ПТС (Автокред)','T-Банк','ПТС Займ для Самозанятых','ПТС Лайт для самозанятых') then 'PTS' 
	else 'Installment' end [product]
	, case when dm.ClaimantStage in ('Hard') then 'Hard' else 'Prelegal' end ClaimantSt
	, imh.external_id imh
	, case when dm.ClaimantStage in ('Hard') then (
	case when isnull(csd.[TPD],0) = 1 then 'TPD'
		when isnull(csd.[flg_Non_Contact],0) = 1 then 'Non_Contact'
		when isnull(csd.[flg_Refused_to_pay_at_PreLegal_2plus],0) = 1 then'Refused_to_pay'
		when csd.segment_code = 'trialPeriod' then 'TrialPeriod'
		else 'old_logic' end 
	) end type_Hard
into #cur_buck_prep 
from dwh2.riskCollection.collection_datamart dm
left join #imha_3 imh on imh.external_id = dm.external_id and year(imh.Date) = YEAR(dm.d) and month(imh.Date) = month(dm.d) and dm.ClaimantStage = imh.ClaimantStage and imh.Date <= dm.d /* насколько должно быть imh.Date >= dm.d жесткое ?*/
left join dwh2.dm.Collection_StrategyDataMart csd on dm.d = csd.StrategyDate and dm.external_id = csd.external_id
where d >= @rdt  and d != cast(getdate() as date)
and bucket_p_coll_num = 4 
and isnull(kk_status,0) = 0

drop table if exists #cur_buck
select distinct * 
into #cur_buck
from #cur_buck_prep

--select top 15 * from #cur_buck
---------------------------
--Определяем последнюю команду 
---------------------------
drop table if exists #imha_4
select * 
into #imha_4
from 
(
	select f_d, d, ClaimantSt, imh, type_Hard, ROW_NUMBER() over (partition by f_d, imh order by d desc) rn
	from #cur_buck
	where imh is not NULL 
	) a where rn = 1


drop table if exists #imh_final
select f_d, ClaimantSt, type_Hard, count(imh) imh_cnt
into #imh_final
from #imha_4
group by f_d, ClaimantSt, type_Hard
order by f_d, ClaimantSt, type_Hard

--select * from #imh_final
--Подсчет количества договоров в 1 бакете, после ИМХА
drop table if exists #impr_after_imh_cnt
select datefromparts(year(dm.d), month(dm.d), 1) as f_d
	, imha_4.ClaimantSt
	, imha_4.type_Hard
	, count(distinct case when bucket_p_coll_num = 1 or bucket_coll_num = 1 then c.imh else null end) impr_after_imh_cnt
into #impr_after_imh_cnt
from dwh2.riskCollection.collection_datamart dm
join (
	select f_d, min(d) d, imh
	from #cur_buck where imh is not null
	group by f_d, imh
	) c on dm.external_id = c.imh and dm.d >= c.d and c.f_d = datefromparts(year(dm.d), month(dm.d), 1)
join #imha_4 imha_4 on dm.external_id = imha_4.imh and datefromparts(year(dm.d), month(dm.d), 1) = imha_4.f_d
group by datefromparts(year(dm.d), month(dm.d), 1), imha_4.ClaimantSt, imha_4.type_Hard
order by datefromparts(year(dm.d), month(dm.d), 1), imha_4.ClaimantSt, imha_4.type_Hard

--Свод данных по командам Prelegal/Hard
drop table if exists #pre_final_1
select f_d
	, [product]
	, bucket_p_coll
	, ClaimantSt
	, sum(reduced_balance) m_reduced_balance --Факт
	, sum(ball_in_p1) m_ball_in_p1 --Портфель
	, sum(pay_total) m_pay_total --Платежи
	, sum(Saved_ballance) m_Saved_ballance --Сохраненный баланс
	, count(distinct external_id) d_cnt
into #pre_final_1
from #cur_buck 
where [product] = 'PTS'
group by f_d
	, [product]
	, bucket_p_coll
	, ClaimantSt
order by f_d
	, [product]
	, bucket_p_coll
	, ClaimantSt desc
--select * from #pre_final_1

drop table if exists #pre_final_1_2;
with a as (
select f_d, [product], bucket_p_coll, ClaimantSt, type_Hard
		, sum(reduced_balance) m_reduced_balance --Факт
		, sum(ball_in_p1) m_ball_in_p1 --Портфель
		, sum(pay_total) m_pay_total --Платежи
		, sum(Saved_ballance) m_Saved_ballance --Сохраненный баланс
		--, count(distinct external_id) d_cnt
		, count(distinct imh) imh_cnt
from #cur_buck
where [product] = 'PTS' and ClaimantSt = 'Hard'
group by f_d, [product], bucket_p_coll, ClaimantSt, type_Hard
),
b as (
select *, ROW_NUMBER() over(partition by f_d, external_id order by d) nn from #cur_buck
where ClaimantSt = 'Hard' and [product] = 'PTS'
)
select a.*,b.d_cnt
into #pre_final_1_2
from a
join (select f_d, [product], bucket_p_coll, ClaimantSt	, type_Hard, count(distinct external_id) d_cnt from b where nn = 1
	group by f_d, [product], bucket_p_coll, ClaimantSt	, type_Hard) b on a.f_d = b.f_d and a.product = b.product and a.bucket_p_coll = b.bucket_p_coll and a.type_Hard = b.type_Hard
order by a.f_d, a.[product], a.bucket_p_coll, ClaimantSt, a.type_Hard
--select * from #pre_final_1_2
--Свод данных без деления на команды, для подсчета процентовок разделения между командами
drop table if exists #pre_final_2
select f_d, [product], bucket_p_coll
		, sum(reduced_balance) m_reduced_balance --Факт
		, sum(ball_in_p1) m_ball_in_p1 --Портфель
		, sum(pay_total) m_pay_total --Платежи
		, sum(Saved_ballance) m_Saved_ballance --Сохраненный баланс
		, count(distinct external_id) d_cnt
		, count(distinct imh) imh_cnt
into #pre_final_2
from #cur_buck
where [product] = 'PTS'
group by f_d, [product], bucket_p_coll
order by f_d, [product], bucket_p_coll


--select * from #pre_final_2

--Итоговый свод
drop table if exists #final
select * into #final 
from (
select 
	a.f_d
	, a.product
	, a.bucket_p_coll
	--, a.ClaimantSt
	, case when a.ClaimantSt = 'Hard' then '61-90 hard' else '61-90 prelegal' end as Team
	, '' type_Hard
	, case when a.ClaimantSt = 'Hard' /*and a.type_Hard = 'old_logic' */then sp.reduced_plan 
		when a.ClaimantSt <> 'Hard' then (p.reduced_plan-sp.reduced_plan) end plan_red_ballance
	, (case when a.ClaimantSt = 'Hard' /*and a.type_Hard = 'old_logic' */then sp.reduced_plan 
		when a.ClaimantSt <> 'Hard' then (p.reduced_plan-sp.reduced_plan) end) / p.reduced_plan *100 prc_plan_red_ballance
	, a.m_reduced_balance
	, round((a.m_reduced_balance / b.m_reduced_balance)*100,2) prc_reduced_balance
	, a.m_ball_in_p1
	, round((a.m_ball_in_p1 / b.m_ball_in_p1)*100,2) prc_ball_in_p1
	, a.m_pay_total
	, round((a.m_pay_total / b.m_pay_total)*100,2) prc_pay_total
	, a.m_Saved_ballance
	, a.d_cnt
	, imh_f.imh_cnt
	, imh_af.impr_after_imh_cnt
from #pre_final_1 a
left join #pre_final_2 b on a.f_d = b.f_d and a.product = b.product 
left join #plans p on a.f_d = p.rep_dt_month and a.product = p.Product and a.bucket_p_coll = p.bucket_from
left join dwh2.riskcollection.prelegal_hard_61_90_plan_split sp on a.f_d = sp.rep_dt_month and  a.product = sp.Product and a.bucket_p_coll = sp.bucket_from
--left join #impr_after_imh_cnt imh_af on imh_af.f_d = a.f_d and imh_af.ClaimantSt = a.ClaimantSt
left join (select f_d, ClaimantSt, sum(impr_after_imh_cnt) impr_after_imh_cnt 
			from #impr_after_imh_cnt group by f_d, ClaimantSt) imh_af on imh_af.f_d = a.f_d and imh_af.ClaimantSt = a.ClaimantSt
--left join #imh_final imh_f on a.f_d = imh_f.f_d and a.ClaimantSt = imh_f.ClaimantSt 
--left join  imh_f on a.f_d = imh_f.f_d and a.ClaimantSt = imh_f.ClaimantSt
left join (select f_d, ClaimantSt, sum(imh_cnt) imh_cnt  
			from #imh_final group by f_d, ClaimantSt) imh_f on imh_f.f_d = a.f_d and imh_f.ClaimantSt = a.ClaimantSt
union
select 
	a.f_d
	, a.product
	, a.bucket_p_coll
	, '61-90 общий' Team
	, '' type_Hard
	, b.reduced_plan
	, 100 prc_plan_red_ballance
	, a.m_reduced_balance
	, 100 prc_reduced_balance
	, a.m_ball_in_p1
	, 100 prc_ball_in_p1
	, a.m_pay_total
	, 100 prc_pay_total
	, a.m_Saved_ballance
	, a.d_cnt
	, a.imh_cnt
	, imh_af.impr_after_imh_cnt
from #pre_final_2 a
left join #plans b on a.f_d = b.rep_dt_month and a.product = b.Product and a.bucket_p_coll = b.bucket_from
left join (select f_d, sum(impr_after_imh_cnt) impr_after_imh_cnt from #impr_after_imh_cnt group by f_d) imh_af on imh_af.f_d = a.f_d
) a 

drop table if exists #final_2
select 
	a.f_d
	, a.product
	, a.bucket_p_coll
	, '61-90 hard' as Team
	, a.type_Hard 
	, (a.m_ball_in_p1 / c.m_ball_in_p1) * sp.reduced_plan as plan_red_ballance
	, round((a.m_ball_in_p1 / c.m_ball_in_p1)*100,2) prc_plan_red_ballance
	, a.m_reduced_balance
	, round((a.m_reduced_balance / c.m_reduced_balance)*100,2) prc_reduced_balance
	, a.m_ball_in_p1
	, round((a.m_ball_in_p1 / c.m_ball_in_p1)*100,2) prc_ball_in_p1
	, a.m_pay_total
	, round((a.m_pay_total / c.m_pay_total)*100,2) prc_pay_total
	, a.m_Saved_ballance
	, a.d_cnt
	, imh_f.imh_cnt
	, imh_af.impr_after_imh_cnt
into #final_2
from #pre_final_1_2 a
left join #pre_final_2 b on a.f_d = b.f_d and a.product = b.product 
left join #pre_final_1 c on a.f_d = c.f_d and a.product = c.product and a.ClaimantSt = c.ClaimantSt 
left join #plans p on a.f_d = p.rep_dt_month and a.product = p.Product and a.bucket_p_coll = p.bucket_from
left join dwh2.riskcollection.prelegal_hard_61_90_plan_split sp on a.f_d = sp.rep_dt_month and  a.product = sp.Product and a.bucket_p_coll = sp.bucket_from
left join #impr_after_imh_cnt imh_af on imh_af.f_d = a.f_d and imh_af.ClaimantSt = a.ClaimantSt and a.type_Hard = imh_af.type_Hard
left join #imh_final imh_f on a.f_d = imh_f.f_d and a.ClaimantSt = imh_f.ClaimantSt and a.type_Hard = imh_f.type_Hard


BEGIN TRANSACTION
--Зачищаем данные, для исключения дублей
	--drop table [RiskDWH].dbo.prelegal_hard_61_90_report
	delete from dwh2.riskcollection.prelegal_hard_61_90_report 
	where f_d >= @rdt

--Вставка данных в итоговую таблицу
	insert into dwh2.riskcollection.prelegal_hard_61_90_report 
	select * 
	--into dwh2.riskcollection.prelegal_hard_61_90_report 
	from
		(
		select 
			*
			, m_reduced_balance / plan_red_ballance *100 as completion
			, m_reduced_balance / m_ball_in_p1 * 100 as eff
		from #final
		union
			select 
			*
			, m_reduced_balance / plan_red_ballance *100 as completion
			, m_reduced_balance / m_ball_in_p1 * 100 as eff
		from #final_2
		) a
	order by f_d, Team desc
COMMIT TRANSACTION;
--select * from dwh2.riskcollection.prelegal_hard_61_90_report order by f_d, Team desc

drop table if exists #plans
drop table if exists #cur_buck
drop table if exists #imha_1
drop table if exists #imha_2 
drop table if exists #imha_3
drop table if exists #imha_4 
drop table if exists #imh_final
drop table if exists #impr_after_imh_cnt
drop table if exists #pre_final_1
drop table if exists #pre_final_1_2
drop table if exists #pre_final_2
drop table if exists #final
drop table if exists #final_2

/*процедура dwh2.riskCollection.create_61_90_report*/
END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
	END CATCH
END