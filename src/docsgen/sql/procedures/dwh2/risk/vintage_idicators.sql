CREATE procedure [risk].[vintage_idicators] as
begin
declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID);
--exec risk.vintage_idicators
BEGIN TRY
--------------------------------поиск предыдущего продукта 
drop table if exists #prev_prods;
select
distinct external_id
,first_value(credit_type) over (partition by person_id order by startdate) as prev_prod
into #prev_prods
from risk.credits
;
--------------------------------признак пролонгации для PDL 
drop table if exists #prolongation;
select 
number
,period_start
,row_number() over (partition by number order by period_start) as rn
into #prolongation
from dbo.dm_restructurings
where reason_credit_vacation = 'Пролонгация PDL'
;
--------------------------------AutoApprove RDWH-48
--inst
drop table if exists #calc;
select 
distinct number
,[Values] as isAutoApprove
into #calc
from stg._loginom.strategy_calc calc--Вертикальная таблица с расчетами из стратегии
where Names = 'isAutoApprove'
and [Values] = 1
and exists (select number from dbo.dm_OverdueIndicators where number = calc.number)
and datetime>='2025-12-22 11:44'
;
--big
drop table if exists #calc_big;
select 
distinct number
,isFullAutoApprove
into #calc_big
from stg._loginom.Originationlog calc_big
where productTypeCode in ('bigInstallment', 'bigInstallmentMarket')
and isFullAutoApprove is not null
and exists (select number from dbo.dm_OverdueIndicators where number = calc_big.number)
and call_date>='2025-12-22 11:44'
;
--------------------------------индикаторы - основная выборка данных
drop table if exists #vintages;
select 
oi.number
,oi.amount
,oi.fpd0
,oi.fpd4
,oi.fpd7
,oi.fpd10
,oi.fpd15
,oi.fpd30
,oi.spd0
,oi.tpd0
,oi.spd0_not_fpd0
,oi._15_4_CMR
,oi._30_4_CMR
,oi._90_6_CMR
,oi._90_12_CMR
,credits.generation as vintage
,credits.credit_type
,credits.PDLTerm
,app.probation
,coalesce(app.CLIENT_TYPE, 'НОВЫЙ') as CLIENT_TYPE
,app.REFIN_FL_ as REFIN_FL
,case 
	when app.CLIENT_TYPE in ('ПОВТОРНЫЙ', 'ДОКРЕД') and prev_prods.prev_prod in ('pts', 'PTS_31', 'PTS_REFIN') then 'Повторный ПТС'
	when app.CLIENT_TYPE in ('ПОВТОРНЫЙ', 'ДОКРЕД') and prev_prods.prev_prod = 'INST' then 'Повторный ИНСТ'
	when app.CLIENT_TYPE in ('ПОВТОРНЫЙ', 'ДОКРЕД') and prev_prods.prev_prod = 'PDL' then 'Повторный PDL'
	else 'Новый'
	end repeated_client_type
,case when credits.factenddate is null then 0 else 1 end flg_closed
,case 
	when credits.factenddate is not null
	and credits.max_dpd = 0
	and prol1.period_start is null
	--and flg_statement_without_prolong=1 - пока непонятно, нужно или нет
	then 1 
	else 0 
	end flg_closed_wo_overdue_and_prolongation --закрыт без просрочки и пролонгаций			
,case 
	when (prol1.period_start is not null and prol2.period_start is null) and (oi.fpd0 + oi.fpd4 + oi.fpd7 + oi.fpd10 + oi.fpd30) = 0 then 1 
	when (prol1.period_start is not null and prol2.period_start is not null and prol3.period_start is null) 
		and (oi.fpd0 + oi.fpd4 + oi.fpd7 + oi.fpd10 + oi.fpd30) = 0 then 1 
	when (prol1.period_start is not null and prol2.period_start is not null and prol3.period_start is not null and prol4.period_start is null) 
		and (oi.fpd0 + oi.fpd4 + oi.fpd7 + oi.fpd10 + oi.fpd30) = 0 then 1 
	when (prol1.period_start is not null and prol2.period_start is not null and prol3.period_start is not null and prol4.period_start is not null) 
		and (oi.fpd0 + oi.fpd4 + oi.fpd7 + oi.fpd10 + oi.fpd30) = 0 then 1 
	else 0
	end flg_prolong_without_overdue --пролонгации без просрочек
,case 
	when (prol1.period_start is not null and prol2.period_start is null) 
		and (oi.fpd0 + oi.fpd4 + oi.fpd7 + oi.fpd10 + oi.fpd30) > 0 then 1 
	when (prol1.period_start is not null and prol2.period_start is not null and prol3.period_start is null) 
		and (oi.fpd0 + oi.fpd4 + oi.fpd7 + oi.fpd10 + oi.fpd30) > 0 then 1 
	when (prol1.period_start is not null and prol2.period_start is not null and prol3.period_start is not null and prol4.period_start is null) 
		and (oi.fpd0 + oi.fpd4 + oi.fpd7 + oi.fpd10 + oi.fpd30) > 0 then 1
	when (prol1.period_start is not null and prol2.period_start is not null and prol3.period_start is not null and prol4.period_start is not null) 
		and (oi.fpd0 + oi.fpd4 + oi.fpd7 + oi.fpd10 + oi.fpd30) > 0 then 1 
	else 0 
	end flg_prolongation_with_overdue --пролонгация с просрочкой 
,case when credits.max_dpd > 0 then 1 else 0 end flag_overdue 
,case 
	when credits.credit_type in ('INST', 'PDL') then coalesce(calc.isAutoApprove, 0)
	when credits.credit_type in ('bigInstallment', 'bigInstallmentMarket') then coalesce(calc_big.isFullAutoApprove, 0)
	else 0
	end AutoApprove --RDWH-48
into #vintages
from dbo.dm_OverdueIndicators oi
inner join risk.credits credits
	on credits.external_id = oi.number
left join risk.applications2 app
	on oi.number = app.number
left join #prev_prods prev_prods
	on oi.number = prev_prods.external_id
left join #calc calc
	on oi.number = calc.number
left join #calc_big calc_big
	on oi.number = calc_big.number
--left join #without_overdue wo
--on oi.number = wo.external_id
---пролонгации 4 штуки, максимально допустимо 4 пролонгации по 1 мес.
left join #prolongation prol1
	on oi.number = prol1.number
	and prol1.rn = 1
left join #prolongation prol2
	on oi.number = prol2.number
	and prol2.rn = 2
left join #prolongation prol3
	on oi.number = prol3.number
	and prol3.rn = 3
left join #prolongation prol4
	on oi.number = prol4.number
	and prol4.rn = 4
---
where oi.startDate >= '20190801' 
and oi.startDate < getdate() 
and oi.amount > 0
;
--------------------------------1. All_PTS
drop table if exists #vint_indicators;
with src1_pts as 
(
select 
vintage
,cast('1. All_PTS' as varchar(100)) as grp
,count(distinct number) as cnt
,cast(sum(amount) as float) as amnt
,case when count(fpd0) = 0 then null else cast(sum(fpd0) as float) / cast(count(fpd0) as float) end fpd0_cnt
,case when count(fpd0) = 0 then null else cast(sum(case when fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when fpd0 is not null then amount else 0 end) as float) end fpd0_amnt
,case when count(fpd4) = 0 then null else cast(sum(fpd4) as float) / cast(count(fpd4) as float) end fpd4_cnt
,case when count(fpd4) = 0 then null else cast(sum(case when fpd4 = 1 then amount else 0 end) as float) / cast(sum(case when fpd4 is not null then amount else 0 end) as float) end fpd4_amnt
,case when count(fpd7) = 0 then null else cast(sum(fpd7) as float) / cast(count(fpd7) as float) end fpd7_cnt
,case when count(fpd7) = 0 then null else cast(sum(case when fpd7 = 1 then amount else 0 end) as float) / cast(sum(case when fpd7 is not null then amount else 0 end) as float) end fpd7_amnt
,case when count(fpd10) = 0 then null else cast(sum(fpd10) as float) / cast(count(fpd10) as float) end fpd10_cnt
,case when count(fpd10) = 0 then null else cast(sum(case when fpd10 = 1 then amount else 0 end) as float) / cast(sum(case when fpd10 is not null then amount else 0 end) as float) end fpd10_amnt
,case when count(fpd15) = 0 then null else cast(sum(fpd15) as float) / cast(count(fpd15) as float) end fpd15_cnt
,case when count(fpd15) = 0 then null else cast(sum(case when fpd15 = 1 then amount else 0 end) as float) / cast(sum(case when fpd15 is not null then amount else 0 end) as float) end fpd15_amnt
,case when count(fpd30) = 0 then null else cast(sum(fpd30) as float) / cast(count(fpd30) as float) end fpd30_cnt
,case when count(fpd30) = 0 then null else cast(sum(case when fpd30 = 1 then amount else 0 end) as float) / cast(sum(case when fpd30 is not null then amount else 0 end) as float) end fpd30_amnt
,case when count(spd0) = 0 then null else cast(sum(spd0) as float) / cast(count(spd0) as float) end spd0_cnt
,case when count(spd0) = 0 then null else cast(sum(case when spd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0 is not null then amount else 0 end) as float) end spd0_amnt
,case when count(tpd0) = 0 then null else cast(sum(tpd0) as float) / cast(count(tpd0) as float) end tpd0_cnt
,case when count(tpd0) = 0 then null else cast(sum(case when tpd0 = 1 then amount else 0 end) as float) / cast(sum(case when tpd0 is not null then amount else 0 end) as float) end tpd0_amnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(spd0_not_fpd0) as float) / cast(count(spd0_not_fpd0) as float) end spd0_not_fpd0_cnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(case when spd0_not_fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0_not_fpd0 is not null then amount else 0 end) as float) end spd0_not_fpd0_amnt
,case when count(_15_4_CMR) = 0 then null else cast(sum(_15_4_CMR) as float) / cast(count(_15_4_CMR) as float) end cnt_15@4
,case when count(_15_4_CMR) = 0 then null else cast(sum(case when _15_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _15_4_CMR is not null then amount else 0 end) as float) end amnt_15@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(_30_4_CMR) as float) / cast(count(_30_4_CMR) as float) end cnt_30@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(case when _30_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _30_4_CMR is not null then amount else 0 end) as float) end amnt_30@4
,case when count(_90_6_CMR) = 0 then null else cast(sum(_90_6_CMR) as float) / cast(count(_90_6_CMR) as float) end cnt_90@6
,case when count(_90_6_CMR) = 0 then null else cast(sum(case when _90_6_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_6_CMR is not null then amount else 0 end) as float) end amnt_90@6
,case when count(_90_12_CMR) = 0 then null else cast(sum(_90_12_CMR) as float) / cast(count(_90_12_CMR) as float) end cnt_90@12
,case when count(_90_12_CMR) = 0 then null else cast(sum(case when _90_12_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_12_CMR is not null then amount else 0 end) as float) end amnt_90@12
from #vintages
where credit_type in ('pts', 'PTS_31', 'PTS_REFIN')
group by vintage
)
select 
row_number() over (partition by grp order by vintage) as rn
,round(avg(amnt / cnt) over (partition by grp, vintage), 0) as avg_amnt
,*
,getdate() as dt_dml
into #vint_indicators
from src1_pts
order by 1
;
--------------------------------2. ПТС NEW_TOTAL
with src2_pts as 
(
select 
vintage
,cast('2. NEW TOTAL' as varchar(100)) as grp
,count(distinct number) as cnt
,cast(sum(amount) as float) as amnt
,case when count(fpd0) = 0 then null else cast(sum(fpd0) as float) / cast(count(fpd0) as float) end fpd0_cnt
,case when count(fpd0) = 0 then null else cast(sum(case when fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when fpd0 is not null then amount else 0 end) as float) end fpd0_amnt
,case when count(fpd4) = 0 then null else cast(sum(fpd4) as float) / cast(count(fpd4) as float) end fpd4_cnt
,case when count(fpd4) = 0 then null else cast(sum(case when fpd4 = 1 then amount else 0 end) as float) / cast(sum(case when fpd4 is not null then amount else 0 end) as float) end fpd4_amnt
,case when count(fpd7) = 0 then null else cast(sum(fpd7) as float) / cast(count(fpd7) as float) end fpd7_cnt
,case when count(fpd7) = 0 then null else cast(sum(case when fpd7 = 1 then amount else 0 end) as float) / cast(sum(case when fpd7 is not null then amount else 0 end) as float) end fpd7_amnt
,case when count(fpd10) = 0 then null else cast(sum(fpd10) as float) / cast(count(fpd10) as float) end fpd10_cnt
,case when count(fpd10) = 0 then null else cast(sum(case when fpd10 = 1 then amount else 0 end) as float) / cast(sum(case when fpd10 is not null then amount else 0 end) as float) end fpd10_amnt
,case when count(fpd15) = 0 then null else cast(sum(fpd15) as float) / cast(count(fpd15) as float) end fpd15_cnt
,case when count(fpd15) = 0 then null else cast(sum(case when fpd15 = 1 then amount else 0 end) as float) / cast(sum(case when fpd15 is not null then amount else 0 end) as float) end fpd15_amnt
,case when count(fpd30) = 0 then null else cast(sum(fpd30) as float) / cast(count(fpd30) as float) end fpd30_cnt
,case when count(fpd30) = 0 then null else cast(sum(case when fpd30 = 1 then amount else 0 end) as float) / cast(sum(case when fpd30 is not null then amount else 0 end) as float) end fpd30_amnt
,case when count(spd0) = 0 then null else cast(sum(spd0) as float) / cast(count(spd0) as float) end spd0_cnt
,case when count(spd0) = 0 then null else cast(sum(case when spd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0 is not null then amount else 0 end) as float) end spd0_amnt
,case when count(tpd0) = 0 then null else cast(sum(tpd0) as float) / cast(count(tpd0) as float) end tpd0_cnt
,case when count(tpd0) = 0 then null else cast(sum(case when tpd0 = 1 then amount else 0 end) as float) / cast(sum(case when tpd0 is not null then amount else 0 end) as float) end tpd0_amnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(spd0_not_fpd0) as float) / cast(count(spd0_not_fpd0) as float) end spd0_not_fpd0_cnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(case when spd0_not_fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0_not_fpd0 is not null then amount else 0 end) as float) end spd0_not_fpd0_amnt
,case when count(_15_4_CMR) = 0 then null else cast(sum(_15_4_CMR) as float) / cast(count(_15_4_CMR) as float) end cnt_15@4
,case when count(_15_4_CMR) = 0 then null else cast(sum(case when _15_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _15_4_CMR is not null then amount else 0 end) as float) end amnt_15@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(_30_4_CMR) as float) / cast(count(_30_4_CMR) as float) end cnt_30@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(case when _30_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _30_4_CMR is not null then amount else 0 end) as float) end amnt_30@4
,case when count(_90_6_CMR) = 0 then null else cast(sum(_90_6_CMR) as float) / cast(count(_90_6_CMR) as float) end cnt_90@6
,case when count(_90_6_CMR) = 0 then null else cast(sum(case when _90_6_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_6_CMR is not null then amount else 0 end) as float) end amnt_90@6
,case when count(_90_12_CMR) = 0 then null else cast(sum(_90_12_CMR) as float) / cast(count(_90_12_CMR) as float) end cnt_90@12
,case when count(_90_12_CMR) = 0 then null else cast(sum(case when _90_12_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_12_CMR is not null then amount else 0 end) as float) end amnt_90@12
from #vintages
where credit_type in ('pts', 'PTS_31', 'PTS_REFIN')
and client_type = 'НОВЫЙ'
group by vintage
)
insert into #vint_indicators
select 
row_number() over (partition by grp order by vintage) as rn
,round(avg(amnt / cnt) over (partition by grp, vintage), 0) as avg_amnt
,*
,getdate() as dt_dml
from src2_pts
order by 1
;
--------------------------------3. ПТС New without refin and probation
with src3_pts as 
(
select 
vintage
,cast('3. NEW WO REF/PROBATION' as varchar(100)) as grp
,count(distinct number) as cnt
,cast(sum(amount) as float) as amnt
,case when count(fpd0) = 0 then null else cast(sum(fpd0) as float) / cast(count(fpd0) as float) end fpd0_cnt
,case when count(fpd0) = 0 then null else cast(sum(case when fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when fpd0 is not null then amount else 0 end) as float) end fpd0_amnt
,case when count(fpd4) = 0 then null else cast(sum(fpd4) as float) / cast(count(fpd4) as float) end fpd4_cnt
,case when count(fpd4) = 0 then null else cast(sum(case when fpd4 = 1 then amount else 0 end) as float) / cast(sum(case when fpd4 is not null then amount else 0 end) as float) end fpd4_amnt
,case when count(fpd7) = 0 then null else cast(sum(fpd7) as float) / cast(count(fpd7) as float) end fpd7_cnt
,case when count(fpd7) = 0 then null else cast(sum(case when fpd7 = 1 then amount else 0 end) as float) / cast(sum(case when fpd7 is not null then amount else 0 end) as float) end fpd7_amnt
,case when count(fpd10) = 0 then null else cast(sum(fpd10) as float) / cast(count(fpd10) as float) end fpd10_cnt
,case when count(fpd10) = 0 then null else cast(sum(case when fpd10 = 1 then amount else 0 end) as float) / cast(sum(case when fpd10 is not null then amount else 0 end) as float) end fpd10_amnt
,case when count(fpd15) = 0 then null else cast(sum(fpd15) as float) / cast(count(fpd15) as float) end fpd15_cnt
,case when count(fpd15) = 0 then null else cast(sum(case when fpd15 = 1 then amount else 0 end) as float) / cast(sum(case when fpd15 is not null then amount else 0 end) as float) end fpd15_amnt
,case when count(fpd30) = 0 then null else cast(sum(fpd30) as float) / cast(count(fpd30) as float) end fpd30_cnt
,case when count(fpd30) = 0 then null else cast(sum(case when fpd30 = 1 then amount else 0 end) as float) / cast(sum(case when fpd30 is not null then amount else 0 end) as float) end fpd30_amnt
,case when count(spd0) = 0 then null else cast(sum(spd0) as float) / cast(count(spd0) as float) end spd0_cnt
,case when count(spd0) = 0 then null else cast(sum(case when spd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0 is not null then amount else 0 end) as float) end spd0_amnt
,case when count(tpd0) = 0 then null else cast(sum(tpd0) as float) / cast(count(tpd0) as float) end tpd0_cnt
,case when count(tpd0) = 0 then null else cast(sum(case when tpd0 = 1 then amount else 0 end) as float) / cast(sum(case when tpd0 is not null then amount else 0 end) as float) end tpd0_amnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(spd0_not_fpd0) as float) / cast(count(spd0_not_fpd0) as float) end spd0_not_fpd0_cnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(case when spd0_not_fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0_not_fpd0 is not null then amount else 0 end) as float) end spd0_not_fpd0_amnt
,case when count(_15_4_CMR) = 0 then null else cast(sum(_15_4_CMR) as float) / cast(count(_15_4_CMR) as float) end cnt_15@4
,case when count(_15_4_CMR) = 0 then null else cast(sum(case when _15_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _15_4_CMR is not null then amount else 0 end) as float) end amnt_15@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(_30_4_CMR) as float) / cast(count(_30_4_CMR) as float) end cnt_30@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(case when _30_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _30_4_CMR is not null then amount else 0 end) as float) end amnt_30@4
,case when count(_90_6_CMR) = 0 then null else cast(sum(_90_6_CMR) as float) / cast(count(_90_6_CMR) as float) end cnt_90@6
,case when count(_90_6_CMR) = 0 then null else cast(sum(case when _90_6_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_6_CMR is not null then amount else 0 end) as float) end amnt_90@6
,case when count(_90_12_CMR) = 0 then null else cast(sum(_90_12_CMR) as float) / cast(count(_90_12_CMR) as float) end cnt_90@12
,case when count(_90_12_CMR) = 0 then null else cast(sum(case when _90_12_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_12_CMR is not null then amount else 0 end) as float) end amnt_90@12
from #vintages
where credit_type in ('pts', 'PTS_31', 'PTS_REFIN')
and client_type = 'НОВЫЙ'
and (probation is null or probation = 0) 
and refin_fl = 0
group by vintage
)
insert into #vint_indicators
select 
row_number() over (partition by grp order by vintage) as rn
,round(avg(amnt / cnt) over (partition by grp, vintage), 0) as avg_amnt
,*
,getdate() as dt_dml
from src3_pts
order by 1
;
--------------------------------4. ПТС POVT_ALL
with src4_pts as
(
select 
vintage
,cast('4. POVT_ALL' as varchar(100)) as grp
,count(distinct number) as cnt
,cast(sum(amount) as float) as amnt
,case when count(fpd0) = 0 then null else cast(sum(fpd0) as float) / cast(count(fpd0) as float) end fpd0_cnt
,case when count(fpd0) = 0 then null else cast(sum(case when fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when fpd0 is not null then amount else 0 end) as float) end fpd0_amnt
,case when count(fpd4) = 0 then null else cast(sum(fpd4) as float) / cast(count(fpd4) as float) end fpd4_cnt
,case when count(fpd4) = 0 then null else cast(sum(case when fpd4 = 1 then amount else 0 end) as float) / cast(sum(case when fpd4 is not null then amount else 0 end) as float) end fpd4_amnt
,case when count(fpd7) = 0 then null else cast(sum(fpd7) as float) / cast(count(fpd7) as float) end fpd7_cnt
,case when count(fpd7) = 0 then null else cast(sum(case when fpd7 = 1 then amount else 0 end) as float) / cast(sum(case when fpd7 is not null then amount else 0 end) as float) end fpd7_amnt
,case when count(fpd10) = 0 then null else cast(sum(fpd10) as float) / cast(count(fpd10) as float) end fpd10_cnt
,case when count(fpd10) = 0 then null else cast(sum(case when fpd10 = 1 then amount else 0 end) as float) / cast(sum(case when fpd10 is not null then amount else 0 end) as float) end fpd10_amnt
,case when count(fpd15) = 0 then null else cast(sum(fpd15) as float) / cast(count(fpd15) as float) end fpd15_cnt
,case when count(fpd15) = 0 then null else cast(sum(case when fpd15 = 1 then amount else 0 end) as float) / cast(sum(case when fpd15 is not null then amount else 0 end) as float) end fpd15_amnt
,case when count(fpd30) = 0 then null else cast(sum(fpd30) as float) / cast(count(fpd30) as float) end fpd30_cnt
,case when count(fpd30) = 0 then null else cast(sum(case when fpd30 = 1 then amount else 0 end) as float) / cast(sum(case when fpd30 is not null then amount else 0 end) as float) end fpd30_amnt
,case when count(spd0) = 0 then null else cast(sum(spd0) as float) / cast(count(spd0) as float) end spd0_cnt
,case when count(spd0) = 0 then null else cast(sum(case when spd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0 is not null then amount else 0 end) as float) end spd0_amnt
,case when count(tpd0) = 0 then null else cast(sum(tpd0) as float) / cast(count(tpd0) as float) end tpd0_cnt
,case when count(tpd0) = 0 then null else cast(sum(case when tpd0 = 1 then amount else 0 end) as float) / cast(sum(case when tpd0 is not null then amount else 0 end) as float) end tpd0_amnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(spd0_not_fpd0) as float) / cast(count(spd0_not_fpd0) as float) end spd0_not_fpd0_cnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(case when spd0_not_fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0_not_fpd0 is not null then amount else 0 end) as float) end spd0_not_fpd0_amnt
,case when count(_15_4_CMR) = 0 then null else cast(sum(_15_4_CMR) as float) / cast(count(_15_4_CMR) as float) end cnt_15@4
,case when count(_15_4_CMR) = 0 then null else cast(sum(case when _15_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _15_4_CMR is not null then amount else 0 end) as float) end amnt_15@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(_30_4_CMR) as float) / cast(count(_30_4_CMR) as float) end cnt_30@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(case when _30_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _30_4_CMR is not null then amount else 0 end) as float) end amnt_30@4
,case when count(_90_6_CMR) = 0 then null else cast(sum(_90_6_CMR) as float) / cast(count(_90_6_CMR) as float) end cnt_90@6
,case when count(_90_6_CMR) = 0 then null else cast(sum(case when _90_6_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_6_CMR is not null then amount else 0 end) as float) end amnt_90@6
,case when count(_90_12_CMR) = 0 then null else cast(sum(_90_12_CMR) as float) / cast(count(_90_12_CMR) as float) end cnt_90@12
,case when count(_90_12_CMR) = 0 then null else cast(sum(case when _90_12_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_12_CMR is not null then amount else 0 end) as float) end amnt_90@12
from #vintages
where credit_type in ('pts', 'PTS_31', 'PTS_REFIN')
and client_type in ('ПОВТОРНЫЙ', 'ДОКРЕД')
and refin_fl = 0
group by vintage
)
insert into #vint_indicators
select 
row_number() over (partition by grp order by vintage) as rn
,round(avg(amnt / cnt) over (partition by grp, vintage), 0) as avg_amnt
,*
,getdate() as dt_dml
from src4_pts
order by 1
;
--------------------------------5. ПТС ПОВТОРНЫЕ (ACTIVE)
with src5_pts as
(
select 
vintage
,cast('5. Active povt' as varchar(100)) as grp
,count(distinct number) as cnt
,cast(sum(amount) as float) as amnt
,case when count(fpd0) = 0 then null else cast(sum(fpd0) as float) / cast(count(fpd0) as float) end fpd0_cnt
,case when count(fpd0) = 0 then null else cast(sum(case when fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when fpd0 is not null then amount else 0 end) as float) end fpd0_amnt
,case when count(fpd4) = 0 then null else cast(sum(fpd4) as float) / cast(count(fpd4) as float) end fpd4_cnt
,case when count(fpd4) = 0 then null else cast(sum(case when fpd4 = 1 then amount else 0 end) as float) / cast(sum(case when fpd4 is not null then amount else 0 end) as float) end fpd4_amnt
,case when count(fpd7) = 0 then null else cast(sum(fpd7) as float) / cast(count(fpd7) as float) end fpd7_cnt
,case when count(fpd7) = 0 then null else cast(sum(case when fpd7 = 1 then amount else 0 end) as float) / cast(sum(case when fpd7 is not null then amount else 0 end) as float) end fpd7_amnt
,case when count(fpd10) = 0 then null else cast(sum(fpd10) as float) / cast(count(fpd10) as float) end fpd10_cnt
,case when count(fpd10) = 0 then null else cast(sum(case when fpd10 = 1 then amount else 0 end) as float) / cast(sum(case when fpd10 is not null then amount else 0 end) as float) end fpd10_amnt
,case when count(fpd15) = 0 then null else cast(sum(fpd15) as float) / cast(count(fpd15) as float) end fpd15_cnt
,case when count(fpd15) = 0 then null else cast(sum(case when fpd15 = 1 then amount else 0 end) as float) / cast(sum(case when fpd15 is not null then amount else 0 end) as float) end fpd15_amnt
,case when count(fpd30) = 0 then null else cast(sum(fpd30) as float) / cast(count(fpd30) as float) end fpd30_cnt
,case when count(fpd30) = 0 then null else cast(sum(case when fpd30 = 1 then amount else 0 end) as float) / cast(sum(case when fpd30 is not null then amount else 0 end) as float) end fpd30_amnt
,case when count(spd0) = 0 then null else cast(sum(spd0) as float) / cast(count(spd0) as float) end spd0_cnt
,case when count(spd0) = 0 then null else cast(sum(case when spd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0 is not null then amount else 0 end) as float) end spd0_amnt
,case when count(tpd0) = 0 then null else cast(sum(tpd0) as float) / cast(count(tpd0) as float) end tpd0_cnt
,case when count(tpd0) = 0 then null else cast(sum(case when tpd0 = 1 then amount else 0 end) as float) / cast(sum(case when tpd0 is not null then amount else 0 end) as float) end tpd0_amnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(spd0_not_fpd0) as float) / cast(count(spd0_not_fpd0) as float) end spd0_not_fpd0_cnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(case when spd0_not_fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0_not_fpd0 is not null then amount else 0 end) as float) end spd0_not_fpd0_amnt
,case when count(_15_4_CMR) = 0 then null else cast(sum(_15_4_CMR) as float) / cast(count(_15_4_CMR) as float) end cnt_15@4
,case when count(_15_4_CMR) = 0 then null else cast(sum(case when _15_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _15_4_CMR is not null then amount else 0 end) as float) end amnt_15@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(_30_4_CMR) as float) / cast(count(_30_4_CMR) as float) end cnt_30@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(case when _30_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _30_4_CMR is not null then amount else 0 end) as float) end amnt_30@4
,case when count(_90_6_CMR) = 0 then null else cast(sum(_90_6_CMR) as float) / cast(count(_90_6_CMR) as float) end cnt_90@6
,case when count(_90_6_CMR) = 0 then null else cast(sum(case when _90_6_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_6_CMR is not null then amount else 0 end) as float) end amnt_90@6
,case when count(_90_12_CMR) = 0 then null else cast(sum(_90_12_CMR) as float) / cast(count(_90_12_CMR) as float) end cnt_90@12
,case when count(_90_12_CMR) = 0 then null else cast(sum(case when _90_12_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_12_CMR is not null then amount else 0 end) as float) end amnt_90@12
from #vintages
where credit_type in ('pts', 'PTS_31', 'PTS_REFIN')
and client_type = 'ДОКРЕД' 
and refin_fl = 0
group by vintage
)
insert into #vint_indicators
select 
row_number() over (partition by grp order by vintage) as rn
,round(avg(amnt / cnt) over (partition by grp, vintage), 0) as avg_amnt
,*
,getdate() as dt_dml
from src5_pts
order by 1
;
--------------------------------6. ПТС ПОВТОРНЫЕ (REPEATED)
with src6_pts as
(
select 
vintage
,cast('6. POVT REPEATED' as varchar(100)) as grp
,count(distinct number) as cnt
,cast(sum(amount) as float) as amnt
,case when count(fpd0) = 0 then null else cast(sum(fpd0) as float) / cast(count(fpd0) as float) end fpd0_cnt
,case when count(fpd0) = 0 then null else cast(sum(case when fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when fpd0 is not null then amount else 0 end) as float) end fpd0_amnt
,case when count(fpd4) = 0 then null else cast(sum(fpd4) as float) / cast(count(fpd4) as float) end fpd4_cnt
,case when count(fpd4) = 0 then null else cast(sum(case when fpd4 = 1 then amount else 0 end) as float) / cast(sum(case when fpd4 is not null then amount else 0 end) as float) end fpd4_amnt
,case when count(fpd7) = 0 then null else cast(sum(fpd7) as float) / cast(count(fpd7) as float) end fpd7_cnt
,case when count(fpd7) = 0 then null else cast(sum(case when fpd7 = 1 then amount else 0 end) as float) / cast(sum(case when fpd7 is not null then amount else 0 end) as float) end fpd7_amnt
,case when count(fpd10) = 0 then null else cast(sum(fpd10) as float) / cast(count(fpd10) as float) end fpd10_cnt
,case when count(fpd10) = 0 then null else cast(sum(case when fpd10 = 1 then amount else 0 end) as float) / cast(sum(case when fpd10 is not null then amount else 0 end) as float) end fpd10_amnt
,case when count(fpd15) = 0 then null else cast(sum(fpd15) as float) / cast(count(fpd15) as float) end fpd15_cnt
,case when count(fpd15) = 0 then null else cast(sum(case when fpd15 = 1 then amount else 0 end) as float) / cast(sum(case when fpd15 is not null then amount else 0 end) as float) end fpd15_amnt
,case when count(fpd30) = 0 then null else cast(sum(fpd30) as float) / cast(count(fpd30) as float) end fpd30_cnt
,case when count(fpd30) = 0 then null else cast(sum(case when fpd30 = 1 then amount else 0 end) as float) / cast(sum(case when fpd30 is not null then amount else 0 end) as float) end fpd30_amnt
,case when count(spd0) = 0 then null else cast(sum(spd0) as float) / cast(count(spd0) as float) end spd0_cnt
,case when count(spd0) = 0 then null else cast(sum(case when spd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0 is not null then amount else 0 end) as float) end spd0_amnt
,case when count(tpd0) = 0 then null else cast(sum(tpd0) as float) / cast(count(tpd0) as float) end tpd0_cnt
,case when count(tpd0) = 0 then null else cast(sum(case when tpd0 = 1 then amount else 0 end) as float) / cast(sum(case when tpd0 is not null then amount else 0 end) as float) end tpd0_amnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(spd0_not_fpd0) as float) / cast(count(spd0_not_fpd0) as float) end spd0_not_fpd0_cnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(case when spd0_not_fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0_not_fpd0 is not null then amount else 0 end) as float) end spd0_not_fpd0_amnt
,case when count(_15_4_CMR) = 0 then null else cast(sum(_15_4_CMR) as float) / cast(count(_15_4_CMR) as float) end cnt_15@4
,case when count(_15_4_CMR) = 0 then null else cast(sum(case when _15_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _15_4_CMR is not null then amount else 0 end) as float) end amnt_15@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(_30_4_CMR) as float) / cast(count(_30_4_CMR) as float) end cnt_30@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(case when _30_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _30_4_CMR is not null then amount else 0 end) as float) end amnt_30@4
,case when count(_90_6_CMR) = 0 then null else cast(sum(_90_6_CMR) as float) / cast(count(_90_6_CMR) as float) end cnt_90@6
,case when count(_90_6_CMR) = 0 then null else cast(sum(case when _90_6_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_6_CMR is not null then amount else 0 end) as float) end amnt_90@6
,case when count(_90_12_CMR) = 0 then null else cast(sum(_90_12_CMR) as float) / cast(count(_90_12_CMR) as float) end cnt_90@12
,case when count(_90_12_CMR) = 0 then null else cast(sum(case when _90_12_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_12_CMR is not null then amount else 0 end) as float) end amnt_90@12
from #vintages
where credit_type in ('pts', 'PTS_31', 'PTS_REFIN')
and client_type = 'ПОВТОРНЫЙ'
and refin_fl = 0
group by vintage
)
insert into #vint_indicators
select 
row_number() over (partition by grp order by vintage) as rn
,round(avg(amnt / cnt) over (partition by grp, vintage), 0) as avg_amnt
,*
,getdate() as dt_dml
from src6_pts
order by 1
;
--------------------------------7. ПТС РЕФИНАНС
with src7_pts as
(
select 
vintage
,cast('7. REFIN' as varchar(100)) as grp
,count(distinct number) as cnt
,cast(sum(amount) as float) as amnt
,case when count(fpd0) = 0 then null else cast(sum(fpd0) as float) / cast(count(fpd0) as float) end fpd0_cnt
,case when count(fpd0) = 0 then null else cast(sum(case when fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when fpd0 is not null then amount else 0 end) as float) end fpd0_amnt
,case when count(fpd4) = 0 then null else cast(sum(fpd4) as float) / cast(count(fpd4) as float) end fpd4_cnt
,case when count(fpd4) = 0 then null else cast(sum(case when fpd4 = 1 then amount else 0 end) as float) / cast(sum(case when fpd4 is not null then amount else 0 end) as float) end fpd4_amnt
,case when count(fpd7) = 0 then null else cast(sum(fpd7) as float) / cast(count(fpd7) as float) end fpd7_cnt
,case when count(fpd7) = 0 then null else cast(sum(case when fpd7 = 1 then amount else 0 end) as float) / cast(sum(case when fpd7 is not null then amount else 0 end) as float) end fpd7_amnt
,case when count(fpd10) = 0 then null else cast(sum(fpd10) as float) / cast(count(fpd10) as float) end fpd10_cnt
,case when count(fpd10) = 0 then null else cast(sum(case when fpd10 = 1 then amount else 0 end) as float) / cast(sum(case when fpd10 is not null then amount else 0 end) as float) end fpd10_amnt
,case when count(fpd15) = 0 then null else cast(sum(fpd15) as float) / cast(count(fpd15) as float) end fpd15_cnt
,case when count(fpd15) = 0 then null else cast(sum(case when fpd15 = 1 then amount else 0 end) as float) / cast(sum(case when fpd15 is not null then amount else 0 end) as float) end fpd15_amnt
,case when count(fpd30) = 0 then null else cast(sum(fpd30) as float) / cast(count(fpd30) as float) end fpd30_cnt
,case when count(fpd30) = 0 then null else cast(sum(case when fpd30 = 1 then amount else 0 end) as float) / cast(sum(case when fpd30 is not null then amount else 0 end) as float) end fpd30_amnt
,case when count(spd0) = 0 then null else cast(sum(spd0) as float) / cast(count(spd0) as float) end spd0_cnt
,case when count(spd0) = 0 then null else cast(sum(case when spd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0 is not null then amount else 0 end) as float) end spd0_amnt
,case when count(tpd0) = 0 then null else cast(sum(tpd0) as float) / cast(count(tpd0) as float) end tpd0_cnt
,case when count(tpd0) = 0 then null else cast(sum(case when tpd0 = 1 then amount else 0 end) as float) / cast(sum(case when tpd0 is not null then amount else 0 end) as float) end tpd0_amnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(spd0_not_fpd0) as float) / cast(count(spd0_not_fpd0) as float) end spd0_not_fpd0_cnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(case when spd0_not_fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0_not_fpd0 is not null then amount else 0 end) as float) end spd0_not_fpd0_amnt
,case when count(_15_4_CMR) = 0 then null else cast(sum(_15_4_CMR) as float) / cast(count(_15_4_CMR) as float) end cnt_15@4
,case when count(_15_4_CMR) = 0 then null else cast(sum(case when _15_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _15_4_CMR is not null then amount else 0 end) as float) end amnt_15@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(_30_4_CMR) as float) / cast(count(_30_4_CMR) as float) end cnt_30@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(case when _30_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _30_4_CMR is not null then amount else 0 end) as float) end amnt_30@4
,case when count(_90_6_CMR) = 0 then null else cast(sum(_90_6_CMR) as float) / cast(count(_90_6_CMR) as float) end cnt_90@6
,case when count(_90_6_CMR) = 0 then null else cast(sum(case when _90_6_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_6_CMR is not null then amount else 0 end) as float) end amnt_90@6
,case when count(_90_12_CMR) = 0 then null else cast(sum(_90_12_CMR) as float) / cast(count(_90_12_CMR) as float) end cnt_90@12
,case when count(_90_12_CMR) = 0 then null else cast(sum(case when _90_12_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_12_CMR is not null then amount else 0 end) as float) end amnt_90@12
from #vintages
where credit_type in ('pts', 'PTS_31', 'PTS_REFIN')
and refin_fl = 1
group by vintage
)
insert into #vint_indicators
select 
row_number() over (partition by grp order by vintage) as rn
,round(avg(amnt / cnt) over (partition by grp, vintage), 0) as avg_amnt
,*
,getdate() as dt_dml
from src7_pts
order by 1
;
--------------------------------8. ПТС ИСПЫТАТЕЛЬНЫЙ СРОК НОВЫЕ
with src8_pts as
(
select 
vintage
,cast('8. Probation New' as varchar(100)) as grp
,count(distinct number) as cnt
,cast(sum(amount) as float) as amnt
,case when count(fpd0) = 0 then null else cast(sum(fpd0) as float) / cast(count(fpd0) as float) end fpd0_cnt
,case when count(fpd0) = 0 then null else cast(sum(case when fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when fpd0 is not null then amount else 0 end) as float) end fpd0_amnt
,case when count(fpd4) = 0 then null else cast(sum(fpd4) as float) / cast(count(fpd4) as float) end fpd4_cnt
,case when count(fpd4) = 0 then null else cast(sum(case when fpd4 = 1 then amount else 0 end) as float) / cast(sum(case when fpd4 is not null then amount else 0 end) as float) end fpd4_amnt
,case when count(fpd7) = 0 then null else cast(sum(fpd7) as float) / cast(count(fpd7) as float) end fpd7_cnt
,case when count(fpd7) = 0 then null else cast(sum(case when fpd7 = 1 then amount else 0 end) as float) / cast(sum(case when fpd7 is not null then amount else 0 end) as float) end fpd7_amnt
,case when count(fpd10) = 0 then null else cast(sum(fpd10) as float) / cast(count(fpd10) as float) end fpd10_cnt
,case when count(fpd10) = 0 then null else cast(sum(case when fpd10 = 1 then amount else 0 end) as float) / cast(sum(case when fpd10 is not null then amount else 0 end) as float) end fpd10_amnt
,case when count(fpd15) = 0 then null else cast(sum(fpd15) as float) / cast(count(fpd15) as float) end fpd15_cnt
,case when count(fpd15) = 0 then null else cast(sum(case when fpd15 = 1 then amount else 0 end) as float) / cast(sum(case when fpd15 is not null then amount else 0 end) as float) end fpd15_amnt
,case when count(fpd30) = 0 then null else cast(sum(fpd30) as float) / cast(count(fpd30) as float) end fpd30_cnt
,case when count(fpd30) = 0 then null else cast(sum(case when fpd30 = 1 then amount else 0 end) as float) / cast(sum(case when fpd30 is not null then amount else 0 end) as float) end fpd30_amnt
,case when count(spd0) = 0 then null else cast(sum(spd0) as float) / cast(count(spd0) as float) end spd0_cnt
,case when count(spd0) = 0 then null else cast(sum(case when spd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0 is not null then amount else 0 end) as float) end spd0_amnt
,case when count(tpd0) = 0 then null else cast(sum(tpd0) as float) / cast(count(tpd0) as float) end tpd0_cnt
,case when count(tpd0) = 0 then null else cast(sum(case when tpd0 = 1 then amount else 0 end) as float) / cast(sum(case when tpd0 is not null then amount else 0 end) as float) end tpd0_amnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(spd0_not_fpd0) as float) / cast(count(spd0_not_fpd0) as float) end spd0_not_fpd0_cnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(case when spd0_not_fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0_not_fpd0 is not null then amount else 0 end) as float) end spd0_not_fpd0_amnt
,case when count(_15_4_CMR) = 0 then null else cast(sum(_15_4_CMR) as float) / cast(count(_15_4_CMR) as float) end cnt_15@4
,case when count(_15_4_CMR) = 0 then null else cast(sum(case when _15_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _15_4_CMR is not null then amount else 0 end) as float) end amnt_15@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(_30_4_CMR) as float) / cast(count(_30_4_CMR) as float) end cnt_30@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(case when _30_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _30_4_CMR is not null then amount else 0 end) as float) end amnt_30@4
,case when count(_90_6_CMR) = 0 then null else cast(sum(_90_6_CMR) as float) / cast(count(_90_6_CMR) as float) end cnt_90@6
,case when count(_90_6_CMR) = 0 then null else cast(sum(case when _90_6_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_6_CMR is not null then amount else 0 end) as float) end amnt_90@6
,case when count(_90_12_CMR) = 0 then null else cast(sum(_90_12_CMR) as float) / cast(count(_90_12_CMR) as float) end cnt_90@12
,case when count(_90_12_CMR) = 0 then null else cast(sum(case when _90_12_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_12_CMR is not null then amount else 0 end) as float) end amnt_90@12
from #vintages
where credit_type in ('pts', 'PTS_31', 'PTS_REFIN')
and client_type = 'НОВЫЙ' 
and probation = 1
group by vintage
)
insert into #vint_indicators
select 
row_number() over (partition by grp order by vintage) as rn
,round(avg(amnt / cnt) over (partition by grp, vintage), 0) as avg_amnt
,*
,getdate() as dt_dml
from src8_pts
order by 1
;
--------------------------------Автокреды
with src_auto as
(
select 
vintage
,cast('AUTOCREDIT' as varchar(100)) as grp
,count(distinct number) as cnt
,cast(sum(amount) as float) as amnt
,case when count(fpd0) = 0 then null else cast(sum(fpd0) as float) / cast(count(fpd0) as float) end fpd0_cnt
,case when count(fpd0) = 0 then null else cast(sum(case when fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when fpd0 is not null then amount else 0 end) as float) end fpd0_amnt
,case when count(fpd4) = 0 then null else cast(sum(fpd4) as float) / cast(count(fpd4) as float) end fpd4_cnt
,case when count(fpd4) = 0 then null else cast(sum(case when fpd4 = 1 then amount else 0 end) as float) / cast(sum(case when fpd4 is not null then amount else 0 end) as float) end fpd4_amnt
,case when count(fpd7) = 0 then null else cast(sum(fpd7) as float) / cast(count(fpd7) as float) end fpd7_cnt
,case when count(fpd7) = 0 then null else cast(sum(case when fpd7 = 1 then amount else 0 end) as float) / cast(sum(case when fpd7 is not null then amount else 0 end) as float) end fpd7_amnt
,case when count(fpd10) = 0 then null else cast(sum(fpd10) as float) / cast(count(fpd10) as float) end fpd10_cnt
,case when count(fpd10) = 0 then null else cast(sum(case when fpd10 = 1 then amount else 0 end) as float) / cast(sum(case when fpd10 is not null then amount else 0 end) as float) end fpd10_amnt
,case when count(fpd15) = 0 then null else cast(sum(fpd15) as float) / cast(count(fpd15) as float) end fpd15_cnt
,case when count(fpd15) = 0 then null else cast(sum(case when fpd15 = 1 then amount else 0 end) as float) / cast(sum(case when fpd15 is not null then amount else 0 end) as float) end fpd15_amnt
,case when count(fpd30) = 0 then null else cast(sum(fpd30) as float) / cast(count(fpd30) as float) end fpd30_cnt
,case when count(fpd30) = 0 then null else cast(sum(case when fpd30 = 1 then amount else 0 end) as float) / cast(sum(case when fpd30 is not null then amount else 0 end) as float) end fpd30_amnt
,case when count(spd0) = 0 then null else cast(sum(spd0) as float) / cast(count(spd0) as float) end spd0_cnt
,case when count(spd0) = 0 then null else cast(sum(case when spd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0 is not null then amount else 0 end) as float) end spd0_amnt
,case when count(tpd0) = 0 then null else cast(sum(tpd0) as float) / cast(count(tpd0) as float) end tpd0_cnt
,case when count(tpd0) = 0 then null else cast(sum(case when tpd0 = 1 then amount else 0 end) as float) / cast(sum(case when tpd0 is not null then amount else 0 end) as float) end tpd0_amnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(spd0_not_fpd0) as float) / cast(count(spd0_not_fpd0) as float) end spd0_not_fpd0_cnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(case when spd0_not_fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0_not_fpd0 is not null then amount else 0 end) as float) end spd0_not_fpd0_amnt
,case when count(_15_4_CMR) = 0 then null else cast(sum(_15_4_CMR) as float) / cast(count(_15_4_CMR) as float) end cnt_15@4
,case when count(_15_4_CMR) = 0 then null else cast(sum(case when _15_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _15_4_CMR is not null then amount else 0 end) as float) end amnt_15@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(_30_4_CMR) as float) / cast(count(_30_4_CMR) as float) end cnt_30@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(case when _30_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _30_4_CMR is not null then amount else 0 end) as float) end amnt_30@4
,case when count(_90_6_CMR) = 0 then null else cast(sum(_90_6_CMR) as float) / cast(count(_90_6_CMR) as float) end cnt_90@6
,case when count(_90_6_CMR) = 0 then null else cast(sum(case when _90_6_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_6_CMR is not null then amount else 0 end) as float) end amnt_90@6
,case when count(_90_12_CMR) = 0 then null else cast(sum(_90_12_CMR) as float) / cast(count(_90_12_CMR) as float) end cnt_90@12
,case when count(_90_12_CMR) = 0 then null else cast(sum(case when _90_12_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_12_CMR is not null then amount else 0 end) as float) end amnt_90@12
from #vintages
where credit_type = 'AUTOCREDIT'
group by vintage
)
insert into #vint_indicators
select 
row_number() over (partition by grp order by vintage) as rn
,round(avg(amnt / cnt) over (partition by grp, vintage), 0) as avg_amnt
,*
,getdate() as dt_dml
from src_auto
order by 1
;
--------------------------------bigInstallment
with src_big as
(
select 
vintage
,cast('Big Installment ПСБ' as varchar(100)) as grp
,count(distinct number) as cnt
,cast(sum(amount) as float) as amnt
,case when count(fpd0) = 0 then null else cast(sum(fpd0) as float) / cast(count(fpd0) as float) end fpd0_cnt
,case when count(fpd0) = 0 then null else cast(sum(case when fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when fpd0 is not null then amount else 0 end) as float) end fpd0_amnt
,case when count(fpd4) = 0 then null else cast(sum(fpd4) as float) / cast(count(fpd4) as float) end fpd4_cnt
,case when count(fpd4) = 0 then null else cast(sum(case when fpd4 = 1 then amount else 0 end) as float) / cast(sum(case when fpd4 is not null then amount else 0 end) as float) end fpd4_amnt
,case when count(fpd7) = 0 then null else cast(sum(fpd7) as float) / cast(count(fpd7) as float) end fpd7_cnt
,case when count(fpd7) = 0 then null else cast(sum(case when fpd7 = 1 then amount else 0 end) as float) / cast(sum(case when fpd7 is not null then amount else 0 end) as float) end fpd7_amnt
,case when count(fpd10) = 0 then null else cast(sum(fpd10) as float) / cast(count(fpd10) as float) end fpd10_cnt
,case when count(fpd10) = 0 then null else cast(sum(case when fpd10 = 1 then amount else 0 end) as float) / cast(sum(case when fpd10 is not null then amount else 0 end) as float) end fpd10_amnt
,case when count(fpd15) = 0 then null else cast(sum(fpd15) as float) / cast(count(fpd15) as float) end fpd15_cnt
,case when count(fpd15) = 0 then null else cast(sum(case when fpd15 = 1 then amount else 0 end) as float) / cast(sum(case when fpd15 is not null then amount else 0 end) as float) end fpd15_amnt
,case when count(fpd30) = 0 then null else cast(sum(fpd30) as float) / cast(count(fpd30) as float) end fpd30_cnt
,case when count(fpd30) = 0 then null else cast(sum(case when fpd30 = 1 then amount else 0 end) as float) / cast(sum(case when fpd30 is not null then amount else 0 end) as float) end fpd30_amnt
,case when count(spd0) = 0 then null else cast(sum(spd0) as float) / cast(count(spd0) as float) end spd0_cnt
,case when count(spd0) = 0 then null else cast(sum(case when spd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0 is not null then amount else 0 end) as float) end spd0_amnt
,case when count(tpd0) = 0 then null else cast(sum(tpd0) as float) / cast(count(tpd0) as float) end tpd0_cnt
,case when count(tpd0) = 0 then null else cast(sum(case when tpd0 = 1 then amount else 0 end) as float) / cast(sum(case when tpd0 is not null then amount else 0 end) as float) end tpd0_amnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(spd0_not_fpd0) as float) / cast(count(spd0_not_fpd0) as float) end spd0_not_fpd0_cnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(case when spd0_not_fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0_not_fpd0 is not null then amount else 0 end) as float) end spd0_not_fpd0_amnt
,case when count(_15_4_CMR) = 0 then null else cast(sum(_15_4_CMR) as float) / cast(count(_15_4_CMR) as float) end cnt_15@4
,case when count(_15_4_CMR) = 0 then null else cast(sum(case when _15_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _15_4_CMR is not null then amount else 0 end) as float) end amnt_15@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(_30_4_CMR) as float) / cast(count(_30_4_CMR) as float) end cnt_30@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(case when _30_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _30_4_CMR is not null then amount else 0 end) as float) end amnt_30@4
,case when count(_90_6_CMR) = 0 then null else cast(sum(_90_6_CMR) as float) / cast(count(_90_6_CMR) as float) end cnt_90@6
,case when count(_90_6_CMR) = 0 then null else cast(sum(case when _90_6_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_6_CMR is not null then amount else 0 end) as float) end amnt_90@6
,case when count(_90_12_CMR) = 0 then null else cast(sum(_90_12_CMR) as float) / cast(count(_90_12_CMR) as float) end cnt_90@12
,case when count(_90_12_CMR) = 0 then null else cast(sum(case when _90_12_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_12_CMR is not null then amount else 0 end) as float) end amnt_90@12
from #vintages
where credit_type = 'bigInstallment'
group by vintage
)
insert into #vint_indicators
select 
row_number() over (partition by grp order by vintage) as rn
,round(avg(amnt / cnt) over (partition by grp, vintage), 0) as avg_amnt
,*
,getdate() as dt_dml
from src_big
order by 1
;
--------------------------------bigInstallmentMarket
with src_bigmarket as
(
select 
vintage
,cast('Big Installment Рыночный' as varchar(100)) as grp
,count(distinct number) as cnt
,cast(sum(amount) as float) as amnt
,case when count(fpd0) = 0 then null else cast(sum(fpd0) as float) / cast(count(fpd0) as float) end fpd0_cnt
,case when count(fpd0) = 0 then null else cast(sum(case when fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when fpd0 is not null then amount else 0 end) as float) end fpd0_amnt
,case when count(fpd4) = 0 then null else cast(sum(fpd4) as float) / cast(count(fpd4) as float) end fpd4_cnt
,case when count(fpd4) = 0 then null else cast(sum(case when fpd4 = 1 then amount else 0 end) as float) / cast(sum(case when fpd4 is not null then amount else 0 end) as float) end fpd4_amnt
,case when count(fpd7) = 0 then null else cast(sum(fpd7) as float) / cast(count(fpd7) as float) end fpd7_cnt
,case when count(fpd7) = 0 then null else cast(sum(case when fpd7 = 1 then amount else 0 end) as float) / cast(sum(case when fpd7 is not null then amount else 0 end) as float) end fpd7_amnt
,case when count(fpd10) = 0 then null else cast(sum(fpd10) as float) / cast(count(fpd10) as float) end fpd10_cnt
,case when count(fpd10) = 0 then null else cast(sum(case when fpd10 = 1 then amount else 0 end) as float) / cast(sum(case when fpd10 is not null then amount else 0 end) as float) end fpd10_amnt
,case when count(fpd15) = 0 then null else cast(sum(fpd15) as float) / cast(count(fpd15) as float) end fpd15_cnt
,case when count(fpd15) = 0 then null else cast(sum(case when fpd15 = 1 then amount else 0 end) as float) / cast(sum(case when fpd15 is not null then amount else 0 end) as float) end fpd15_amnt
,case when count(fpd30) = 0 then null else cast(sum(fpd30) as float) / cast(count(fpd30) as float) end fpd30_cnt
,case when count(fpd30) = 0 then null else cast(sum(case when fpd30 = 1 then amount else 0 end) as float) / cast(sum(case when fpd30 is not null then amount else 0 end) as float) end fpd30_amnt
,case when count(spd0) = 0 then null else cast(sum(spd0) as float) / cast(count(spd0) as float) end spd0_cnt
,case when count(spd0) = 0 then null else cast(sum(case when spd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0 is not null then amount else 0 end) as float) end spd0_amnt
,case when count(tpd0) = 0 then null else cast(sum(tpd0) as float) / cast(count(tpd0) as float) end tpd0_cnt
,case when count(tpd0) = 0 then null else cast(sum(case when tpd0 = 1 then amount else 0 end) as float) / cast(sum(case when tpd0 is not null then amount else 0 end) as float) end tpd0_amnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(spd0_not_fpd0) as float) / cast(count(spd0_not_fpd0) as float) end spd0_not_fpd0_cnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(case when spd0_not_fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0_not_fpd0 is not null then amount else 0 end) as float) end spd0_not_fpd0_amnt
,case when count(_15_4_CMR) = 0 then null else cast(sum(_15_4_CMR) as float) / cast(count(_15_4_CMR) as float) end cnt_15@4
,case when count(_15_4_CMR) = 0 then null else cast(sum(case when _15_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _15_4_CMR is not null then amount else 0 end) as float) end amnt_15@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(_30_4_CMR) as float) / cast(count(_30_4_CMR) as float) end cnt_30@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(case when _30_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _30_4_CMR is not null then amount else 0 end) as float) end amnt_30@4
,case when count(_90_6_CMR) = 0 then null else cast(sum(_90_6_CMR) as float) / cast(count(_90_6_CMR) as float) end cnt_90@6
,case when count(_90_6_CMR) = 0 then null else cast(sum(case when _90_6_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_6_CMR is not null then amount else 0 end) as float) end amnt_90@6
,case when count(_90_12_CMR) = 0 then null else cast(sum(_90_12_CMR) as float) / cast(count(_90_12_CMR) as float) end cnt_90@12
,case when count(_90_12_CMR) = 0 then null else cast(sum(case when _90_12_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_12_CMR is not null then amount else 0 end) as float) end amnt_90@12
from #vintages
where credit_type = 'bigInstallmentMarket'
group by vintage
)
insert into #vint_indicators
select 
row_number() over (partition by grp order by vintage) as rn
,round(avg(amnt / cnt) over (partition by grp, vintage), 0) as avg_amnt
,*
,getdate() as dt_dml
from src_bigmarket
order by 1
;
--------------------------------ИНСТОЛМЕНТ
with src_inst as
(
select 
vintage
,cast('INSTALLMENT' as varchar(100)) as grp
,count(distinct number) as cnt
,cast(sum(amount) as float) as amnt
,case when count(fpd0) = 0 then null else cast(sum(fpd0) as float) / cast(count(fpd0) as float) end fpd0_cnt
,case when count(fpd0) = 0 then null else cast(sum(case when fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when fpd0 is not null then amount else 0 end) as float) end fpd0_amnt
,case when count(fpd4) = 0 then null else cast(sum(fpd4) as float) / cast(count(fpd4) as float) end fpd4_cnt
,case when count(fpd4) = 0 then null else cast(sum(case when fpd4 = 1 then amount else 0 end) as float) / cast(sum(case when fpd4 is not null then amount else 0 end) as float) end fpd4_amnt
,case when count(fpd7) = 0 then null else cast(sum(fpd7) as float) / cast(count(fpd7) as float) end fpd7_cnt
,case when count(fpd7) = 0 then null else cast(sum(case when fpd7 = 1 then amount else 0 end) as float) / cast(sum(case when fpd7 is not null then amount else 0 end) as float) end fpd7_amnt
,case when count(fpd10) = 0 then null else cast(sum(fpd10) as float) / cast(count(fpd10) as float) end fpd10_cnt
,case when count(fpd10) = 0 then null else cast(sum(case when fpd10 = 1 then amount else 0 end) as float) / cast(sum(case when fpd10 is not null then amount else 0 end) as float) end fpd10_amnt
,case when count(fpd15) = 0 then null else cast(sum(fpd15) as float) / cast(count(fpd15) as float) end fpd15_cnt
,case when count(fpd15) = 0 then null else cast(sum(case when fpd15 = 1 then amount else 0 end) as float) / cast(sum(case when fpd15 is not null then amount else 0 end) as float) end fpd15_amnt
,case when count(fpd30) = 0 then null else cast(sum(fpd30) as float) / cast(count(fpd30) as float) end fpd30_cnt
,case when count(fpd30) = 0 then null else cast(sum(case when fpd30 = 1 then amount else 0 end) as float) / cast(sum(case when fpd30 is not null then amount else 0 end) as float) end fpd30_amnt
,case when count(spd0) = 0 then null else cast(sum(spd0) as float) / cast(count(spd0) as float) end spd0_cnt
,case when count(spd0) = 0 then null else cast(sum(case when spd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0 is not null then amount else 0 end) as float) end spd0_amnt
,case when count(tpd0) = 0 then null else cast(sum(tpd0) as float) / cast(count(tpd0) as float) end tpd0_cnt
,case when count(tpd0) = 0 then null else cast(sum(case when tpd0 = 1 then amount else 0 end) as float) / cast(sum(case when tpd0 is not null then amount else 0 end) as float) end tpd0_amnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(spd0_not_fpd0) as float) / cast(count(spd0_not_fpd0) as float) end spd0_not_fpd0_cnt
,case when count(spd0_not_fpd0) = 0 then null else cast(sum(case when spd0_not_fpd0 = 1 then amount else 0 end) as float) / cast(sum(case when spd0_not_fpd0 is not null then amount else 0 end) as float) end spd0_not_fpd0_amnt
,case when count(_15_4_CMR) = 0 then null else cast(sum(_15_4_CMR) as float) / cast(count(_15_4_CMR) as float) end cnt_15@4
,case when count(_15_4_CMR) = 0 then null else cast(sum(case when _15_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _15_4_CMR is not null then amount else 0 end) as float) end amnt_15@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(_30_4_CMR) as float) / cast(count(_30_4_CMR) as float) end cnt_30@4
,case when count(_30_4_CMR) = 0 then null else cast(sum(case when _30_4_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _30_4_CMR is not null then amount else 0 end) as float) end amnt_30@4
,case when count(_90_6_CMR) = 0 then null else cast(sum(_90_6_CMR) as float) / cast(count(_90_6_CMR) as float) end cnt_90@6
,case when count(_90_6_CMR) = 0 then null else cast(sum(case when _90_6_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_6_CMR is not null then amount else 0 end) as float) end amnt_90@6
,case when count(_90_12_CMR) = 0 then null else cast(sum(_90_12_CMR) as float) / cast(count(_90_12_CMR) as float) end cnt_90@12
,case when count(_90_12_CMR) = 0 then null else cast(sum(case when _90_12_CMR = 1 then amount else 0 end) as float) / cast(sum(case when _90_12_CMR is not null then amount else 0 end) as float) end amnt_90@12
from #vintages
where credit_type = 'INST'
group by vintage
)
insert into #vint_indicators
select 
row_number() over (partition by grp order by vintage) as rn
,round(avg(amnt / cnt) over (partition by grp, vintage), 0) as avg_amnt
,*
,getdate() as dt_dml
from src_inst
order by 1
;
--------------------------------внесение данных
if OBJECT_ID('risk.vintage_idicators_report') is null --винтажи по всем продуктам с группировкой. в отчете используется для птс, авто, биг
begin
	select top(0) * into risk.vintage_idicators_report
	from #vint_indicators
end;

delete from risk.vintage_idicators_report;
insert into risk.vintage_idicators_report
select * from #vint_indicators;

if OBJECT_ID('risk.vintage_idicators_det_report') is null --исходник по винтажам со всеми флагами. в отчете используется для инст и пдл. также для bi
begin
	select top(0) * into risk.vintage_idicators_det_report
	from #vintages
end;

delete from risk.vintage_idicators_det_report;
insert into risk.vintage_idicators_det_report
select * from #vintages;

drop table if exists #prev_prods;
drop table if exists #prolongation;
drop table if exists #calc;
drop table if exists #calc_big;
drop table if exists #vintages;
drop table if exists #vint_indicators;


END TRY

begin catch
		DECLARE @msg NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		DECLARE @subject NVARCHAR(255) = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

	if @@TRANCOUNT>0
		rollback TRANSACTION;
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'risk_tech@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;