-- Author:		Artem Orlov
-- Create date: 07.10.2019
-- Description: витрина origination

-- =============================================
--exec MainData
CREATE   PROCEDURE [dbo].[MainData2] 
AS
BEGIN
SET NOCOUNT ON;

drop table if exists dbo.dm_MainData2
--drop table if exists dbo.dm_Main_Data

-----------------------------------------показатели просрочки + все платежи-----------------------------------------
if OBJECT_ID('tempdb..#help') is not NULL  drop table #help
select  external_id,  credit_date , cast(end_date as date) as end_date, cdate
	, principal_rest
	, overdue_days	
	, dateadd(day,1,dateadd(month, 1, credit_date)) as dt_1
	, dateadd(day,1,dateadd(month, 2, credit_date)) as dt_2
	, dateadd(day,1,dateadd(month, 3, credit_date)) as dt_3
	, dateadd(day,1,dateadd(month, 4, credit_date)) as dt_4
	, dateadd(day,1,dateadd(month, 5, credit_date)) as dt_5
	, dateadd(day,1,dateadd(month, 6, credit_date)) as dt_6
	, dateadd(day,1,dateadd(month, 7, credit_date)) as dt_7
	, dateadd(day,1,dateadd(month, 8, credit_date)) as dt_8
	, dateadd(day,1,dateadd(month, 9, credit_date)) as dt_9
	, dateadd(day,1,dateadd(month, 10, credit_date)) as dt_10
	, dateadd(day,1,dateadd(month, 11, credit_date)) as dt_11
	, dateadd(day,1,dateadd(month, 12, credit_date)) as dt_12
	, dateadd(day,1,dateadd(month, 16, credit_date)) as dt_16
	, principal_cnl_run + percents_cnl_run + fines_cnl_run + overpayments_cnl_run + otherpayments_cnl_run as all_payments
into #help
from [dwh_new].dbo.stat_v_balance2
--where external_id =  18062123380001 
--order by CreditDays
-- select top 100 * from  #help

if OBJECT_ID('tempdb..#dpd_3') is not NULL  drop table #dpd_3
select external_id, max(overdue_days) as max_dpd_3month
into #dpd_3
from #help
where cdate <= dt_3
group by external_id

if OBJECT_ID('tempdb..#dpd_4') is not NULL  drop table #dpd_4
select external_id, max(overdue_days) as max_dpd_4month
into #dpd_4
from #help
where cdate <= dt_4
group by external_id

if OBJECT_ID('tempdb..#dpd_5') is not NULL  drop table #dpd_5
select external_id, max(overdue_days) as max_dpd_5month
into #dpd_5
from #help
where cdate <= dt_5
group by external_id

if OBJECT_ID('tempdb..#dpd_6') is not NULL  drop table #dpd_6
select external_id, max(overdue_days) as max_dpd_6month
into #dpd_6
from #help
where cdate <= dt_6
group by external_id

if OBJECT_ID('tempdb..#dpd_12') is not NULL  drop table #dpd_12
select external_id, max(overdue_days) as max_dpd_12month
into #dpd_12
from #help
where cdate <= dt_12
group by external_id

if OBJECT_ID('tempdb..#dpd_16') is not NULL  drop table #dpd_16
select external_id, max(overdue_days) as max_dpd_16month
into #dpd_16
from #help
where cdate <= dt_16
group by external_id

if OBJECT_ID('tempdb..#dpd_max') is not NULL  drop table #dpd_max
select external_id, max(overdue_days) as max_dpd
into #dpd_max
from #help
where cdate < cast(getdate() as date)
group by external_id
-- select * from #dpd_max
-- select * from #help where external_id = 19070100000096
--------------------------------------------маркетинговые каналы--------------------------------------



-----------------------------fssp---------------------------------------
/*				if OBJECT_ID('tempdb..#fssp') is not NULL  drop table #fssp
SELECT FinapplicationId, sum(summa) as FSSP_amt
into #fssp -- select *
FROM [C1-VSR-SQL05].[BPMOnline_night00].[dbo].[KmReportFromFSSP]
group by FinapplicationId								*/
-- select * from #fssp
-- select * from [C1-VSR-SQL05].[BPMOnline_night00].[dbo].[KmReportFromFSSP] Where id = '9FC2E278-59CA-4818-A63A-D75350D77E08'

------------------------------------------АДРЕСА----------------------------------------
if OBJECT_ID('tempdb..#registration_address') is not NULL  drop table #registration_address
SELECT номер
	  ,registration_address
 --     ,case when[1]='' then NULL else [1] end    AS Country
 --     ,case when[2]='' then NULL else [2] end    AS [Index]
      ,case when[3]='' then NULL else [3] end    AS Region_reg
      ,case when[4]='' then NULL else [4] end    AS District_reg
      ,case when[5]='' then NULL else [5] end    AS City_reg
      ,case when[6]='' then NULL else [6] end    AS Locality_reg
--	  ,case when[7]='' then NULL else [7] end    AS Street
--	  ,case when[8]='' then NULL else [8] end    AS House
--	  ,case when[9]='' then NULL else [9] end    AS Building
--	  ,case when[10]='' then NULL else [10] end  AS Flat
into #registration_address
From  (	Select 	номер
				, АдресРегистрации as registration_address
				, value 
				, ROW_NUMBER() OVER(PARTITION BY cast(АдресРегистрации as varchar(200)),номер ORDER BY (SELECT NULL)) as rn
		from (select номер, cast(АдресРегистрации as varchar(200)) as АдресРегистрации from stg.[_1cMFO].[Документ_ГП_Заявка] where дата >'40160228' ) qq
			CROSS APPLY STRING_SPLIT(АдресРегистрации, ',') 		 ) Q			
PIVOT(
    MAX(VALUE)
    FOR RN IN([3],[4],[5],[6])  
) as PVT 



if OBJECT_ID('tempdb..#sales_address') is not NULL  drop table #sales_address
SELECT ps_id
	  ,sales_address
 --     ,case when[1]='' then NULL else [1] end    AS Country
 --     ,case when[2]='' then NULL else [2] end    AS [Index]
      ,case when[3]='' then NULL else [3] end    AS Region_sale
      ,case when[4]='' then NULL else [4] end    AS District_sale
      ,case when[5]='' then NULL else [5] end    AS City_sale
      ,case when[6]='' then NULL else [6] end    AS Locality_sale
--	  ,case when[7]='' then NULL else [7] end    AS Street
--	  ,case when[8]='' then NULL else [8] end    AS House
--	  ,case when[9]='' then NULL else [9] end    AS Building
--	  ,case when[10]='' then NULL else [10] end  AS Flat
into  #sales_address
From  (	Select 	ps_id
				, sales_address 
				, value 
				, ROW_NUMBER() OVER(PARTITION BY cast(sales_address as varchar(200)),ps_id ORDER BY (SELECT NULL)) as rn
		from (Select ps.id as ps_id ,cast(so.адрес as varchar(200)) as sales_address from [dwh_new].dbo.points_of_sale  ps  
				left join stg.[_1cMFO].[Справочник_ГП_Офисы] so on so.наименование =ps.name) qq
			CROSS APPLY STRING_SPLIT(sales_address, ',') 		 ) Q			
PIVOT(
    MAX(VALUE)
    FOR RN IN([3],[4],[5],[6])  
) as PVT 
------------------------------------------------------------------------------------


--------------------------------------system--------------------------------------
if OBJECT_ID('tempdb..#log') is not NULL  drop table #log
SELECT number, stage, max(run_id) as max_run_id
into #log
FROM stg._loginom.WorkFlow 
	--[LoginomDB].[dbo].[WorkFlow]--переписали в рамках задачи DWH-1140 03/06/2021
group by number, stage

if OBJECT_ID('tempdb..#loginom_info') is not NULL  drop table #loginom_info
Select cast(q.number as varchar(30)) as number
	,case when w.number is NULL then 'call 1' else 'call 2' end as max_stage
	,case when w.spr_version_2 is NULL then q.spr_version_1 else w.spr_version_2 end as version_spr
	, q.stage1_date, q.score_1 , q.bad_debt_1, q.decision_1, w.score_2, w.bad_debt_2, w.decision_2
into #loginom_info
from ( select a.number, a.stage_date as stage1_date, a.score as score_1 , a.bad_debt as bad_debt_1, a.decision as decision_1, a.spr_version as spr_version_1
	   from stg._loginom.WorkFlow a 
		--[LoginomDB].[dbo].[WorkFlow] --переписали в рамках задачи DWH-1140 03/06/2021
	   
	   join #log on a.number = #log.number and a.run_id = #log.max_run_id and  #log.stage = 'call 1' and a.stage = 'call 1' /*where a.number = '19080500000078'*/ ) q
	left join ( select  a.number, a.score as score_2 , a.bad_debt as bad_debt_2, a.decision as decision_2, a.spr_version as spr_version_2--
				from stg._loginom.WorkFlow a 
					--[LoginomDB].[dbo].[WorkFlow] a --переписали в рамках задачи DWH-1140 03/06/2021
				
				join #log on a.number = #log.number and a.run_id = #log.max_run_id and  #log.stage = 'call 2' and a.stage = 'call 2') w
	on q.number = w.number

if OBJECT_ID('tempdb..#loginom_reject') is not NULL  drop table #loginom_reject
select distinct cast(number as varchar(30)) as number
, Stage
, max(car_price) as car_price
, max(Car_found_flag) as Car_found_flag
, max(R_100_0100_003) as R_100_0100_003
, max(R_100_0080_001) as R_100_0080_001
, max(R_100_0100_002) as R_100_0100_002
, max(R_100_0070_007) as R_100_0070_007
, max(R_100_0100_005) as R_100_0100_005
, max(R_100_0100_001) as R_100_0100_001
, max(R_100_0090_002) as R_100_0090_002
, max(R_100_0090_003) as R_100_0090_003
, max(R_100_0050_001) as R_100_0050_001
, max(R_100_0070_002) as R_100_0070_002
into #loginom_reject
FROM	
stg._loginom.Originationlog
--[LoginomDB].[dbo].[OriginationLog] --переписали в рамках задачи DWH-1140 03/06/2021
--where number not in ('19071100000155','19071100000149')
group by Number, stage
----------------------------------------------------------------------------------
-- select * from  #loginom_info where number = '19080500000078'
-- select * from #loginom_reject  where number = '19080500000078'


--------------------------------------statuses--------------------------------------
if OBJECT_ID('tempdb..#tmp_statuses') is not NULL  drop table #tmp_statuses
select 
external_id,
is_KC,
is_KC_app,
is_KD,
case when is_KD=1 and is_VDK=1 then 1 else 0 end id_KD_app,
is_VDK,
is_VDK_app,
is_VD,
is_VD_app,
is_app,
is_rej
 into #tmp_statuses
from (select external_id,  
sign(sum(case when rh.status =  2 then 1 else 0 end       ))as is_KC,
sign(sum(case when rh.status =  3 then 1 else 0 end       ))as is_KC_app,
sign(sum(case when rh.status =  4 then 1 else 0 end       ))as is_KD,
sign(sum(case when rh.status =  5 then 1 else 0 end       ))as is_VDK,
sign(sum(case when rh.status =  6 then 1 else 0 end       ))as is_VDK_app,
sign(sum(case when rh.status =  7 then 1 else 0 end       ))as is_VD,
sign(sum(case when rh.status =  8 then 1 else 0 end       ))as is_VD_app,
sign(sum(case when rh.status in (11,15) then 1 else 0 end ))as is_app,
sign(sum(case when rh.status in (12,14) then 1 else 0 end ))as is_rej
from [dwh_new].dbo.tmp_v_requests r 
join [dwh_new].dbo.requests_history rh on rh.request_id=r.id
group by external_id) a
---------------------------------------------------------------------------------

--------------------------------------verifiers--------------------------------------
if OBJECT_ID('tempdb..#verifiers') is not NULL  drop table #verifiers
select a.*,UW_VD 
into #verifiers
from (
select distinct external_id, v.name UW_VDC
from [dwh_new].dbo.requests_history rh
join [dwh_new].dbo.requests r on rh.request_id=r.id
join [dwh_new].dbo.verifiers v on v.id=verifier
where status in (6,12)) a
left join (select external_id, UW_VD from (
select distinct external_id, v.name UW_VD, status, lag(rh.status) over (partition by request_id order by stage_time) lag_status
from [dwh_new].dbo.requests_history rh
join [dwh_new].dbo.requests r on rh.request_id=r.id
join [dwh_new].dbo.verifiers v on v.id=verifier) a
where status in (8,14) and lag_status not in (2,3,4,14)) b
on a.external_id=b.external_id
---------------------------------------------------------------------------------

drop table if exists #chnls;
select  
  ch.UF_ROW_ID
, ch.[Канал от источника]
, ch.[Группа каналов]
, ch.UF_SIM_OPERATOR
, ch.UF_SIM_REGION
, ch.CPA 
, ch.CPC
, ch.[Партнеры] 
, ch.uf_clb_type 
, ch.uf_clb_channel
into #chnls
from stg.dbo.lcrm_tbl_full_w_chanals2 ch with (nolock) 
where ch.UF_ROW_ID is not null and ch.UF_REGISTERED_AT >'20160228'
------------------------------------ All data------------------------------------ 
--if OBJECT_ID('tempdb..##Main_data') is not NULL  drop table ##Main_data
drop table if exists #t_main
select distinct  a.external_id
			, cast( a.request_date as date) as appl_date
			, b1.end_date
--			,  dateadd(day,6,dateadd(month, 1,  cast( a.request_date as date) )) as dt_fpd_4
			, a.return_type
			, a.new_status	
			, rr.[name]		as reject_reason
			, rr.category   as reject_category
		/*	, case when reject_reasons.category = '%Не отказано%' and a.new_status in ('%07.Одобрено%','%08.Договор зарегистрирован%','%09.Договор подписан%','%10.Заем аннулирован%','%11.Заем выдан%', '%12.Заем погашен%') then 'одобрено' 
				when a.new_status in ('00.Отказ документов клиента', '00.Отказано') then 'отказано'
				 when a.new_status in ('00.Заявка аннулирована','00.Отказано клиентом') then 'отказ клиента'
				   when a.new_status in ('00.Верификация','00.Черновик','01.Верификация КЦ','02.Предварительное одобрение','03.Контроль данных','04.Верификация документов клиента'
										,'05.Одобрены документы клиента''06.Верификация документов')  then 'заявка аннулирована' end as approved 		*/
			, a.initial_amount
            --, case when #loginom_info.number is not null and isNULL(finappl.scoringball,sc.score) is null then 1 else 0 end as is_loginom
              , case when SUBSTRING(rr.name,1,3) = 'AUT'  or rr.name in ('Зона действия бизнеса','Проверка ФМС') 
						or rr.name like '%050.6%' then 'AUT' 
					 when SUBSTRING(rr.name,1,2) = 'CH' or SUBSTRING(rr.name,1,5) in ('034.1','034.2', '057.4', '057.5', '057.6', '057.7', '075.1', '075.2', '092. ') then 'CH'
					 when SUBSTRING(rr.name,1,2) = 'От' then 'CL'					 
					 when SUBSTRING(rr.name,1,2) = 'UW' or  rr.name like '0[0-9][0-9]%'then 'UW' 
					 else 'Other' end as reject_code
            , is_KC
            , is_KC_app
            , is_KD
            , id_KD_app
            , is_VDK
            , is_VDK_app
            , is_VD
            , is_VD_app
			, case when a.status in (11,10,15,16,9) then 1 else 0 end as is_app_correct
			, case when a.status in (11,10,15,16,9, 14,12) then 1 else 0 end as AR_correct
			, case when rr.name like '%050.%' and rr.name not like '%Внутренний скоринг%' then 'BKI'
				   when rr.name like '%AUT.041%'then 'FSSP auto'
				   when rr.name like '%UW.041%'then 'FSSP verif'
				   when rr.name like '%Внутренний скоринг%' then 'score'
				   when rr.name = 'NaN' then 'approve' else 'other' end as decl_rsn_gr
			, UW_VDC
			, UW_VD
            , is_rej
			, a.accepted_amount
            , case when  substring(new_status,1,2) in ('02','05','06','08','10','11') then 1 else 0 end as AR
           -- ,case when isNULL(finappl.scoringball,sc.score) is not null then isNULL(finappl.scoringball,sc.score) 
            --      when isNULL(finappl.scoringball,sc.score) is null and score_2 is not null then score_2 else score_1 end as score_norm
			, cast(appl.ОдобреннаяСуммаВерификаторами as real) as approve_amount
			, cast( [ГП_ПредставлениеКритериевРиска] as varchar(500)) as risks			
			, eqv.score as equifax_score
			--, isNULL(finappl.scoringball,sc.score) as score_our
			--, #fssp.FSSP_amt
			, '---loginom block---' as [---loginom block---]
			, #loginom_info.number
			, max_stage
			, stage1_date
			, score_1
			, bad_debt_1
			, decision_1
			, score_2
			, bad_debt_2
			, decision_2
			, lr2. car_price
			, lr2.Car_found_flag
			, version_spr
			, lr1.R_100_0100_003 as fms_1
			, lr1.R_100_0080_001 as fssp_1
			, lr1.R_100_0100_002 as age_1
			, lr1.R_100_0070_007 as bankrots_1
			, lr1.R_100_0100_005 as passport_term_1
			, lr1.R_100_0100_001 as region_reg_1
			, lr1.R_100_0050_001 as cut_off_1
			, lr1.R_100_0070_002 as black_list_1
			, lr2.R_100_0100_003 as fms_2
			, lr2.R_100_0080_001 as fssp_2
			, lr2.R_100_0100_002 as age_2
			, lr2.R_100_0070_007 as bankrots_2
			, lr2.R_100_0100_005 as passport_term_2
			, lr2.R_100_0100_001 as region_reg_2
			, lr2.R_100_0050_001 as cut_off_2
			, lr2.R_100_0070_002 as black_list_2
			, lr2.R_100_0090_002 as fnp_2
			, lr2.R_100_0090_003 as gibdd_2
			,'--- collateral info ---' as [---collateral info---]
			, a.collateral_id
			, v_collaterals.vin
			, v_collaterals.vehicle_type
			, v_collaterals.brand
			, v_collaterals.model
			, v_collaterals.[year]
			, v_collaterals.top_brands
			, v_collaterals.collateral_segment
			, appl.[рыночнаястоимостьавтонамоментоценки] as market_price
			, appl.[ОценочнаяCтоимостьАвто] as estimated_price
			, appl.[рекомендсуммаквыдаче] as recommend_amount
			, ДисконтАвто as koef_discont
			, isNULL(liq.Ликвидность,0.0) as koef_liquidity
			,'--- financed info ---' as [---financed info---]
			, case when b.external_id is not NULL then 1 else 0 end as financed
			, b.amount, b.term			
			--, case when dateadd(DAY,2,dateadd(MONTH,1,b.start_date))<CURRENT_TIMESTAMP then isnull(fpd0.fpd_state,0) else null end as fpd0
			--, case when dateadd(DAY,6,dateadd(MONTH,1,b.start_date))<CURRENT_TIMESTAMP then isnull(fpd4.fpd_state,0) else null end  as fpd4
			--, case when dateadd(DAY,9,dateadd(MONTH,1,b.start_date))<CURRENT_TIMESTAMP then isnull(fpd7.fpd_state,0) else null end  as fpd7
			--, case when dateadd(DAY,32,dateadd(MONTH,1,b.start_date))<CURRENT_TIMESTAMP then isnull(fpd30.fpd_state,0) else null end  as fpd30
			--, case when dateadd(DAY,62,dateadd(MONTH,1,b.start_date))<CURRENT_TIMESTAMP then isnull(fpd60.fpd_state,0) else null end  as fpd60
			--, case when dateadd(DAY,92,dateadd(MONTH,1,b.start_date))<CURRENT_TIMESTAMP then isnull(fpd90.fpd_state,0) else null end  as fpd90
			--, case when dateadd(DAY,2,dateadd(MONTH,2,b.start_date))<CURRENT_TIMESTAMP then isnull(spd0.fpd_state,0) else null end  as spd0
			--, case when dateadd(DAY,6,dateadd(MONTH,2,b.start_date))<CURRENT_TIMESTAMP then isnull(spd4.fpd_state,0) else null end  as spd4
			--, case when dateadd(DAY,9,dateadd(MONTH,2,b.start_date))<CURRENT_TIMESTAMP then isnull(spd7.fpd_state,0) else null end  as spd7
			--, case when dateadd(DAY,32,dateadd(MONTH,2,b.start_date))<CURRENT_TIMESTAMP then isnull(spd30.fpd_state,0) else null end  as spd30
			--, case when dateadd(DAY,62,dateadd(MONTH,2,b.start_date))<CURRENT_TIMESTAMP then isnull(Spd60.fpd_state,0) else null end  as spd60
			--, case when dateadd(DAY,92,dateadd(MONTH,2,b.start_date))<CURRENT_TIMESTAMP then isnull(spd90.fpd_state,0) else null end  as spd90
			--, case when dateadd(DAY,2,dateadd(MONTH,3,b.start_date))<CURRENT_TIMESTAMP then isnull(tpd0.fpd_state,0) else null end  as tpd0
			--, case when dateadd(DAY,6,dateadd(MONTH,3,b.start_date))<CURRENT_TIMESTAMP then isnull(tpd4.fpd_state,0) else null end  as tpd4
			--, case when dateadd(DAY,9,dateadd(MONTH,3,b.start_date))<CURRENT_TIMESTAMP then isnull( tpd7.fpd_state,0) else null end  as tpd7
			--, case when dateadd(DAY,32,dateadd(MONTH,3,b.start_date))<CURRENT_TIMESTAMP then isnull(tpd30.fpd_state,0) else null end  as tpd30
			--, case when dateadd(DAY,62,dateadd(MONTH,3,b.start_date))<CURRENT_TIMESTAMP then isnull(tpd60.fpd_state,0) else null end  as tpd60
			--, case when dateadd(DAY,92,dateadd(MONTH,3,b.start_date))<CURRENT_TIMESTAMP then isnull(tpd90.fpd_state,0) else null end  as tpd90
            , case when dateadd(DAY,32,dateadd(MONTH,1,b.start_date))<CURRENT_TIMESTAMP then fpd30 else NULL end fpd30_old 
            , case when dateadd(DAY,6,dateadd(MONTH,1,b.start_date))<CURRENT_TIMESTAMP then fpd4 else NULL end fpd4_old
   --         , case when dateadd(DAY,2,dateadd(MONTH,6,b.start_date))<CURRENT_TIMESTAMP then isnull(HR90@6_v2,0) else NULL end hr90@6_old
   --         , case when dateadd(DAY,2,dateadd(MONTH,4,b.start_date))<CURRENT_TIMESTAMP then isnull(HR30@4,0) else NULL end hr30@4_old
			--, case when dateadd(DAY,2,dateadd(MONTH,12,b.start_date))<CURRENT_TIMESTAMP then isnull(HR90@12,0) else NULL end hr90@12_old
			--, case when dateadd(DAY,2,dateadd(MONTH,3,b.start_date))<CURRENT_TIMESTAMP then isnull(HR90_6.hr,0) else NULL end HR90@6
			--, case when dateadd(DAY,2,dateadd(MONTH,1,b.start_date))<CURRENT_TIMESTAMP then isnull(HR30_4.hr,0) else NULL end HR30@4
			--, case when dateadd(DAY,2,dateadd(MONTH,3,b.start_date))<CURRENT_TIMESTAMP then isnull(HR90_12.hr,0) else NULL end HR90@12
			--, case when dateadd(DAY,2,dateadd(MONTH,5,b.start_date))<CURRENT_TIMESTAMP then isnull(HR60_5.hr,0) else NULL end HR60@5
			--, case when dateadd(DAY,2,dateadd(MONTH,7,b.start_date))<CURRENT_TIMESTAMP then isnull(HR120_7.hr,0) else NULL end HR120@7
			--, case when dateadd(DAY,2,dateadd(MONTH,9,b.start_date))<CURRENT_TIMESTAMP then isnull(HR180_9.hr,0) else NULL end HR180@9
			--, case when dateadd(DAY,2,dateadd(MONTH,1,b.start_date))<CURRENT_TIMESTAMP then isnull(HR30_4_g.hr,0) else NULL end HR30@4_gross
			--, case when dateadd(DAY,2,dateadd(MONTH,3,b.start_date))<CURRENT_TIMESTAMP then isnull(HR90_6_g.hr,0) else NULL end HR90@6_gross
			--, case when dateadd(DAY,2,dateadd(MONTH,2,b.start_date))<CURRENT_TIMESTAMP then isnull(HR60_5_g.hr,0) else NULL end HR60@5_gross
			--, case when dateadd(DAY,2,dateadd(MONTH,4,b.start_date))<CURRENT_TIMESTAMP then isnull(HR120_7_g.hr,0) else NULL end HR120@7_gross
			--, case when dateadd(DAY,2,dateadd(MONTH,6,b.start_date))<CURRENT_TIMESTAMP then isnull(HR180_9_g.hr,0) else NULL end HR180@9_gross
			--, case when dateadd(DAY,2,dateadd(MONTH,3,b.start_date))<CURRENT_TIMESTAMP then isnull(HR90_12_g.hr,0) else NULL end HR90@12_gross
			, case when b4.overdue_days >=31  then b4.principal_rest  when b4.overdue_days  is not NULL then 0 end as [30+4MoB]
			, case when b6.overdue_days >=91  then b6.principal_rest  when b6.overdue_days  is not NULL then 0 end as [90+6MoB]
			, case when b7.overdue_days >=91  then b7.principal_rest  when b7.overdue_days  is not NULL then 0 end as [90+7MoB]
			, case when b8.overdue_days >=91  then b8.principal_rest  when b8.overdue_days  is not NULL then 0 end as [90+8MoB]
			, case when b9.overdue_days >=91  then b9.principal_rest  when b9.overdue_days  is not NULL then 0 end as [90+9MoB]
			, case when b10.overdue_days >=91 then b10.principal_rest when b10.overdue_days is not NULL then 0 end as [90+10MoB]
			, case when b11.overdue_days >=91 then b11.principal_rest when b11.overdue_days is not NULL then 0 end as [90+11MoB]	
			, case when b12.overdue_days >=91 then b12.principal_rest when b12.overdue_days is not NULL then 0 end as [90+12MoB]
			, case when b16.overdue_days >=91 then b16.principal_rest when b16.overdue_days is not NULL then 0 end as [90+16MoB]
			, max_dpd_3month, max_dpd_4month, max_dpd_6month, max_dpd_12month , max_dpd 
			, cast(b1.all_payments as real) as all_paym_1m
			, cast(b2.all_payments as real) as all_paym_2m
			, cast(b3.all_payments as real) as all_paym_3m
			, cast(b4.all_payments as real) as all_paym_4m
			, cast(b5.all_payments as real) as all_paym_5m
			, cast(b6.all_payments as real) as all_paym_6m 
			, cast(b7.all_payments as real) as all_paym_7m
			, cast(b8.all_payments as real) as all_paym_8m
			, cast(b9.all_payments as real) as all_paym_9m
			, cast(b10.all_payments as real) as all_paym_10m
			, cast(b11.all_payments as real) as all_paym_11m
			, cast(b12.all_payments as real) as all_paym_12m
			, '--- sales info ---' as [---sales info---] 			
			, chanels.[name] as channel
			, ch.[Канал от источника]
			, ch.[Группа каналов]
			, ch.UF_SIM_OPERATOR
			, ch.UF_SIM_REGION
			, case when ch.CPA is not null then uf_clb_type 
                 when ch.CPC is not null then uf_clb_channel
                 when ch.[Партнеры] is not null then [Партнеры] 
                 when ch.[Группа каналов] = 'Органика' then [Канал от источника] 
				 else NUll  end as level_2

			, a.point_of_sale
			, v_points_of_sale.macro_region	as sale_macro_region
			, v_points_of_sale.region_type as sale_region_type
			, v_points_of_sale.regional_office
			, v_points_of_sale.[name] as pos_name		
			, #sales_address.Region_sale
			, #sales_address.City_sale
			, #sales_address.District_sale			
			, #sales_address.Locality_sale
			, '--- client info ---' as [---client info---] 
			, a.id as request_id
			, a.external_link
			, #registration_address.Region_reg
			, #registration_address.City_reg
			, #registration_address.District_reg			
			, #registration_address.Locality_reg
			, reg.auto_region
			, reg.federal_okrug 
			, last_name
			, first_name
			, middle_name
			, case  when right(rtrim(middle_name),3)  in ('ВИЧ', 'ГЛЫ','ЬИЧ') then 'Мужской'
					when right(rtrim(middle_name),3)  in ('ВНА', 'ЫЗЫ','ЧНА') then 'Женский'
					else 'Other' end as calc_gender
			, '--- other info ---' as [---other info---] 

			, a.generation
			, concat( a.[request_year] , '_', case when a.[request_week]<10 then '0' else '' end,a.[request_week]  ) as app_wk
			/*, UF_CLB_CHANNEL
			, UF_CLB_TYPE*/
--into dm_MainData2
-- 2021_02_16
into #t_main
from  [dwh_new].dbo.tmp_v_requests a 
left join [dwh_new].dbo.tmp_v_credits b on a.external_id = b.external_id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](1,1)) fpd0 on fpd0.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](1,4)) fpd4 on fpd4.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](1,7)) fpd7 on fpd7.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](1,30)) fpd30 on fpd30.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](1,60)) fpd60 on fpd60.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](1,90)) fpd90 on fpd90.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](2,1)) spd0 on spd0.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](2,4)) spd4 on spd4.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](2,7)) spd7 on spd7.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](2,30)) spd30 on spd30.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](2,60)) spd60 on spd60.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](2,90)) spd90 on spd90.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](3,1)) tpd0 on tpd0.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](3,4)) tpd4 on tpd4.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](3,7)) tpd7 on tpd7.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](3,30)) tpd30 on tpd30.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](3,60)) tpd60 on tpd60.credit_id = b.id
--left join (select * from [dwh_new].dbo.[GetPaymentDefaultCMR_paynum_overdue](3,90)) tpd90 on tpd90.credit_id = b.id
--left join (select credit_id, 1 as hr from [dwh_new].dbo.GetDefaultCreditsByParamCMR(6, 6 , 90))  HR90_6 on HR90_6.credit_id = b.id
--left join (select credit_id, 1 as hr from [dwh_new].dbo.GetDefaultCreditsByParamCMR(4, 4 , 30))  HR30_4 on HR30_4.credit_id = b.id
--left join (select credit_id, 1 as hr from [dwh_new].dbo.GetDefaultCreditsByParamCMR(12, 12 , 90)) HR90_12 on HR90_12.credit_id = b.id
--left join (select credit_id, 1 as hr from [dwh_new].dbo.GetDefaultCreditsByParamCMR(5, 5 , 60)) HR60_5 on HR60_5.credit_id = b.id
--left join (select credit_id, 1 as hr from [dwh_new].dbo.GetDefaultCreditsByParamCMR(7, 7 , 120)) HR120_7 on HR120_7.credit_id = b.id
--left join (select credit_id, 1 as hr from [dwh_new].dbo.GetDefaultCreditsByParamCMR(9, 9 , 180)) HR180_9 on HR180_9.credit_id = b.id
--left join (select credit_id, 1 as hr from [dwh_new].dbo.GetDefaultCreditsByParamCMR(0, 4 , 30))  HR30_4_g on HR30_4_g.credit_id = b.id
--left join (select credit_id, 1 as hr from [dwh_new].dbo.GetDefaultCreditsByParamCMR(0, 6 , 90))  HR90_6_g on HR90_6_g.credit_id = b.id
--left join (select credit_id, 1 as hr from [dwh_new].dbo.GetDefaultCreditsByParamCMR(0, 5 , 60))  HR60_5_g on HR60_5_g.credit_id = b.id
--left join (select credit_id, 1 as hr from [dwh_new].dbo.GetDefaultCreditsByParamCMR(0, 7 , 120)) HR120_7_g on HR120_7_g.credit_id = b.id
--left join (select credit_id, 1 as hr from [dwh_new].dbo.GetDefaultCreditsByParamCMR(0, 9 , 180)) HR180_9_g on HR180_9_g.credit_id = b.id
--left join (select credit_id, 1 as hr from [dwh_new].dbo.GetDefaultCreditsByParamCMR(0, 12 , 90)) HR90_12_g on HR90_12_g.credit_id = b.id

								left join #dpd_3 on a.external_id = #dpd_3.external_id
								left join #dpd_4 on a.external_id = #dpd_4.external_id
								left join #dpd_6 on a.external_id = #dpd_6.external_id
								left join #dpd_12 on a.external_id = #dpd_12.external_id
								left join #dpd_max on a.external_id = #dpd_max.external_id
									  left join #help b1 on a.external_id = b1.external_id and b1.cdate = b1.dt_1
									  left join #help b2 on a.external_id = b2.external_id and b2.cdate = b2.dt_2
									  left join #help b3 on a.external_id = b3.external_id and b3.cdate = b3.dt_3
									  left join #help b4 on a.external_id = b4.external_id and b4.cdate = b4.dt_4
									  left join #help b5 on a.external_id = b5.external_id and b5.cdate = b5.dt_5
									  left join #help b6 on a.external_id = b6.external_id and b6.cdate = b6.dt_6
									  left join #help b7 on a.external_id = b7.external_id and b7.cdate = b7.dt_7
									  left join #help b8 on a.external_id = b8.external_id and b8.cdate = b8.dt_8
									  left join #help b9 on a.external_id = b9.external_id and b9.cdate = b9.dt_9
									  left join #help b10 on a.external_id = b10.external_id and b10.cdate = b10.dt_10
									  left join #help b11 on a.external_id = b11.external_id and b11.cdate = b11.dt_11 
									  left join #help b12 on a.external_id = b12.external_id and b12.cdate = b12.dt_12
									  left join #help b16 on a.external_id = b16.external_id and b16.cdate = b16.dt_16
										left join [dwh_new].dbo.v_collaterals on  a.collateral_id = v_collaterals.id
											left join [dwh_new].dbo.v_points_of_sale on a.point_of_sale =  v_points_of_sale.id
											left join [dwh_new].dbo.chanels on a.chanel = chanels.id
                                            left join #tmp_statuses ts on ts.external_id=a.external_id
											left join [dwh_new].dbo.persons per on a.person_id = per.id
											left join [dwh_new].[bki].[eqv_scoring] eqv on a.external_id collate Cyrillic_General_CI_AS = eqv.external_id collate Cyrillic_General_CI_AS	and eqv.flag_correct = 1
												left join (select external_id, case when score is NULL then 0 else score end as score 	from  [dwh_new].[visualization].[v_rbp]) sc on a.external_id collate Cyrillic_General_CI_AS = sc.external_id collate Cyrillic_General_CI_AS
												--left join [C1-VSR-SQL05].[BPMOnline_night00].[dbo].[FinApplication] finappl on cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(a.external_link)  as nvarchar(200)) = finappl.id
													left join stg.[_1cMFO].[Документ_ГП_Заявка]  appl on a.external_id collate Cyrillic_General_CI_AS  = appl.номер collate Cyrillic_General_CI_AS 
														left join stg.[_1cMFO].Справочник_ГП_ЛиквидностьТС liq on appl.ЛиквидностьТС = liq.ссылка		
															--left join #fssp on finappl.id = #fssp.FinapplicationId 
															left join #verifiers ver on ver.external_id=a.external_id
																left join [dwh_new].dbo.reject_reasons rr on a.reject_reason = rr.id 
																--left join   stg.dbo.lcrm_tbl_full_w_chanals2 ch on a.external_id = cast(ch.UF_ROW_ID as varchar(1488))
																left join #chnls ch on a.external_id = cast(ch.UF_ROW_ID as varchar(1488))
																	left join #registration_address on a.external_id = #registration_address.номер
																	left join (select rtrim(ltrim(a.region)) region , id auto_region, federal_okrug, external_id  from [dwh_new].staging.addresses a
																	left join (select distinct region_dwh,id, federal_okrug  
																		from dwh_new.[dbo].[code_regions_auto]  where region_dwh is not null and id <>123) b
																		on rtrim(ltrim(a.region))  collate Cyrillic_General_CI_AS = b.region_dwh ) as reg on a.external_id = reg.external_id
																	left join #sales_address on a.point_of_sale = #sales_address.ps_id
																		full outer join #loginom_info on a.external_id = #loginom_info.number
																		full outer join #loginom_reject  lr1 on a.external_id =lr1.Number and lr1.Stage = 'Call 1' 
																		full outer join #loginom_reject  lr2 on a.external_id =lr2.Number and lr2.Stage = 'Call 2' 
Where 1=1 
-- and a.generation >= '2019-06'
-- and  case when b.external_id is not NULL then 1 else 0 end = 1
 --and vehicle_type = 'B'
-- and case when b4.overdue_days >=31  then b4.principal_rest when b4.overdue_days is not NULL then 0 end = 0
-- and a.external_id in (19070100000284, 19070100000080, 19063000000015)
--order by 5
 -- select * from  #loginom_reject
 
 --2021_02_16
drop table if exists dbo.dm_MainData2
 select * into dbo.dm_MainData2
 from #t_main



/*select * from ##Main_data
where external_id = '19080100000239'
order by appl_date desc*/

end