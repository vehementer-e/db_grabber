-- Author:		Artem Orlov
-- Create date: 07.10.2019
-- Description: витрина origination

-- =============================================
--exec MainData
CREATE PROC dbo.MainData
AS
BEGIN
SET NOCOUNT ON;

--drop table if exists dbo.dm_MainData
--drop table if exists dbo.dm_Main_Data

-----------------------------------------показатели просрочки + все платежи-----------------------------------------

drop table if exists #t1;
select external_id, max(isnull(overdue_days,0)) dpd_max into #t1 from [dwh_new].dbo.stat_v_balance2 group by external_id

drop table if exists #tttt;
create table #tttt(external_id varchar(255), cdate date, credit_date date,end_date date , principal_rest float, overdue_days	int, all_payments float , dpd_max int, od_period int)

DECLARE @i int = 0
WHILE @i < 13
BEGIN
    SET @i = @i + 1
		insert into #tttt
		select 
		 b.external_id
		,b.cdate
		,b.credit_date 
		,cast(b.end_date as date) as end_date
		,b.principal_rest
		,b.overdue_days	
		,b.principal_cnl_run + b.percents_cnl_run + b.fines_cnl_run + b.overpayments_cnl_run + b.otherpayments_cnl_run as all_payments
		,b.overdue_days_flowrate as dpd_max
		,@i as od_period
	from [dwh_new].dbo.stat_v_balance2 b 
	where dateadd(day,1,dateadd(month, @i, b.credit_date)) = b.cdate
END

insert into #tttt
		select 
		 b.external_id
		,b.cdate
		,b.credit_date 
		,cast(b.end_date as date) as end_date
		,b.principal_rest
		,b.overdue_days	
		,b.principal_cnl_run + b.percents_cnl_run + b.fines_cnl_run + b.overpayments_cnl_run + b.otherpayments_cnl_run as all_payments
		,b.overdue_days_flowrate as dpd_max
		,16 as od_period
	from [dwh_new].dbo.stat_v_balance2 b 
	where dateadd(day,1,dateadd(month, 16, b.credit_date)) = b.cdate

drop table if exists #dpd_buffer;

select 
 t1.external_id
, b1.end_date
, isnull(cast(b1.all_payments as real),0) as all_paym_1m
, isnull(cast(b2.all_payments as real),0) as all_paym_2m
, isnull(cast(b3.all_payments as real),0) as all_paym_3m
, isnull(cast(b4.all_payments as real),0) as all_paym_4m
, isnull(cast(b5.all_payments as real),0) as all_paym_5m
, isnull(cast(b6.all_payments as real),0) as all_paym_6m 
, isnull(cast(b7.all_payments as real),0) as all_paym_7m
, isnull(cast(b8.all_payments as real),0) as all_paym_8m
, isnull(cast(b9.all_payments as real),0) as all_paym_9m
, isnull(cast(b10.all_payments as real),0) as all_paym_10m
, isnull(cast(b11.all_payments as real),0) as all_paym_11m
, isnull(cast(b12.all_payments as real),0) as all_paym_12m
, isnull(case when b4.overdue_days >=31  then b4.principal_rest  when b4.overdue_days  is not NULL then 0 end,0) as [30+4MoB]
, isnull(case when b6.overdue_days >=91  then b6.principal_rest  when b6.overdue_days  is not NULL then 0 end,0) as [90+6MoB]
, isnull(case when b7.overdue_days >=91  then b7.principal_rest  when b7.overdue_days  is not NULL then 0 end,0) as [90+7MoB]
, isnull(case when b8.overdue_days >=91  then b8.principal_rest  when b8.overdue_days  is not NULL then 0 end,0) as [90+8MoB]
, isnull(case when b9.overdue_days >=91  then b9.principal_rest  when b9.overdue_days  is not NULL then 0 end,0) as [90+9MoB]
, isnull(case when b10.overdue_days >=91 then b10.principal_rest when b10.overdue_days is not NULL then 0 end,0) as [90+10MoB]
, isnull(case when b11.overdue_days >=91 then b11.principal_rest when b11.overdue_days is not NULL then 0 end,0) as [90+11MoB]	
, isnull(case when b12.overdue_days >=91 then b12.principal_rest when b12.overdue_days is not NULL then 0 end,0) as [90+12MoB]
, isnull(case when b16.overdue_days >=91 then b16.principal_rest when b16.overdue_days is not NULL then 0 end,0) as [90+16MoB]
, b1.overdue_days as overdue_days_1m
, isnull(b1.principal_rest,0) as principal_rest_1m
, b2.overdue_days as overdue_days_2m
, isnull(b2.principal_rest,0) as principal_rest_2m
, b3.overdue_days as overdue_days_3m
, isnull(b3.principal_rest,0) as principal_rest_3m
, b4.overdue_days as overdue_days_4m
, isnull(b4.principal_rest,0) as principal_rest_4m
, b5.overdue_days as overdue_days_5m
, isnull(b5.principal_rest,0) as principal_rest_5m
, b6.overdue_days as overdue_days_6m
, isnull(b6.principal_rest,0) as principal_rest_6m
, b7.overdue_days as overdue_days_7m
, isnull(b7.principal_rest,0) as principal_rest_7m
, b8.overdue_days as overdue_days_8m
, isnull(b8.principal_rest,0) as principal_rest_8m
, b9.overdue_days as overdue_days_9m
, isnull(b9.principal_rest,0) as principal_rest_9m
, b10.overdue_days as overdue_days_10m
, isnull(b10.principal_rest,0) as principal_rest_10m
, b11.overdue_days as overdue_days_11m
, isnull(b11.principal_rest,0) as principal_rest_11m
, b12.overdue_days as overdue_days_12m
, isnull(b12.principal_rest,0) as principal_rest_12m
, b16.overdue_days as overdue_days_16m
, isnull(b16.principal_rest,0) as principal_rest_16m
, b1.all_payments as all_payments_1m
, b2.all_payments as all_payments_2m
, b3.all_payments as all_payments_3m
, b4.all_payments as all_payments_4m
, b5.all_payments as all_payments_5m
, b6.all_payments as all_payments_6m
, b7.all_payments as all_payments_7m
, b8.all_payments as all_payments_8m
, b9.all_payments as all_payments_9m
, b10.all_payments as all_payments_10m
, b11.all_payments as all_payments_11m
, b12.all_payments as all_payments_12m
, b16.all_payments as all_payments_16m
, max_dpd_3month = isnull(b3.dpd_max,0)
, max_dpd_4month = isnull(b4.dpd_max,0)
, max_dpd_6month = isnull(b6.dpd_max,0)
, max_dpd_12month = isnull(b12.dpd_max,0)
, max_dpd = isnull(t1.dpd_max,0)
into #dpd_buffer
from 
#t1 t1
left join #tttt b1  on b1.external_id  = t1.external_id and b1.od_period = 1
left join #tttt b2  on b2.external_id  = t1.external_id and b2.od_period = 2
left join #tttt b3  on b3.external_id  = t1.external_id and b3.od_period = 3
left join #tttt b4  on b4.external_id  = t1.external_id and b4.od_period = 4
left join #tttt b5  on b5.external_id  = t1.external_id and b5.od_period = 5
left join #tttt b6  on b6.external_id  = t1.external_id and b6.od_period = 6
left join #tttt b7  on b7.external_id  = t1.external_id and b7.od_period = 7
left join #tttt b8  on b8.external_id  = t1.external_id and b8.od_period = 8
left join #tttt b9  on b9.external_id  = t1.external_id and b9.od_period = 9
left join #tttt b10 on b10.external_id = t1.external_id and b10.od_period = 10
left join #tttt b11 on b11.external_id = t1.external_id and b11.od_period = 11
left join #tttt b12 on b12.external_id = t1.external_id and b12.od_period = 12
left join #tttt b16 on b16.external_id = t1.external_id and b16.od_period = 16






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
-- > 00:00:07

drop table if exists #gp_zayavka_buffer
select 
	номер, 
	cast(АдресРегистрации as varchar(200)) as АдресРегистрации ,
	[ОдобреннаяСуммаВерификаторами],
	[рыночнаястоимостьавтонамоментоценки],
	[ОценочнаяCтоимостьАвто],
	[рекомендсуммаквыдаче],
	[ДисконтАвто],
	[ЛиквидностьТС],
	[ГП_ПредставлениеКритериевРиска]
into #gp_zayavka_buffer 
from stg.[_1cMFO].[Документ_ГП_Заявка] with(nolock) 
where дата >'40160228'

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
		from #gp_zayavka_buffer qq
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
				left join stg.[_1cMFO].[Справочник_ГП_Офисы] so with(nolock)  on so.наименование =ps.name ) qq
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
FROM stg._loginom.WorkFlow with(nolock) 
group by number, stage

if OBJECT_ID('tempdb..#loginom_info') is not NULL  drop table #loginom_info
select * into #loginom_info from (
Select cast(q.number as varchar(30)) as number
	,case when w.number is NULL then 'call 1' else 'call 2' end as max_stage
	,case when w.spr_version_2 is NULL then q.spr_version_1 else w.spr_version_2 end as version_spr
	, q.stage1_date, q.score_1 , q.bad_debt_1, q.decision_1, w.score_2, w.bad_debt_2, w.decision_2 , rn = ROW_NUMBER() over (partition by q.number order by q.stage1_date desc)

from ( select a.number, a.stage_date as stage1_date, a.score as score_1 , a.bad_debt as bad_debt_1, a.decision as decision_1, a.spr_version as spr_version_1
	   from stg._loginom.WorkFlow a with(nolock) join #log on a.number = #log.number and a.run_id = #log.max_run_id and  #log.stage = 'call 1' and a.stage = 'call 1' /*where a.number = '19080500000078'*/ ) q
	left join ( select  a.number, a.score as score_2 , a.bad_debt as bad_debt_2, a.decision as decision_2, a.spr_version as spr_version_2--
				from stg._loginom.WorkFlow a with(nolock) join #log on a.number = #log.number and a.run_id = #log.max_run_id and  #log.stage = 'call 2' and a.stage = 'call 2') w
	on q.number = w.number
	) rr where rr.rn =1


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
FROM stg._loginom.[OriginationLog]  with(nolock)
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
select distinct external_id, v.name UW_VDC, rn = ROW_NUMBER() over (partition by external_id order by stage_time desc) 
from [dwh_new].dbo.requests_history rh
join [dwh_new].dbo.requests r on rh.request_id=r.id
join [dwh_new].dbo.verifiers v on v.id=verifier
where status in (6,12)) a
left join (select external_id, UW_VD, stage_time, rn = ROW_NUMBER() over (partition by external_id order by stage_time desc) from (
select distinct external_id, v.name UW_VD, status, lag(rh.status) over (partition by request_id order by stage_time) lag_status, rh.stage_time 
from [dwh_new].dbo.requests_history rh
join [dwh_new].dbo.requests r on rh.request_id=r.id
join [dwh_new].dbo.verifiers v on v.id=verifier
) a
where status in (8,14) and lag_status not in (2,3,4,14)) b
on a.external_id=b.external_id
where b.rn = 1 and a.rn =1

---------------------------------------------------------------------------------

drop table if exists #channels_buffer_tmp

--DWH-1567 Оптимизация хранения лидов. Отказ от использования таблицы lcrm_leads_full_channel
--SELECT 
--	cast(ch.UF_ROW_ID as varchar(255)) as external_id
--	,ch.[Канал от источника]
--	,ch.[Группа каналов]
--	,ch.UF_SIM_OPERATOR
--	,ch.UF_SIM_REGION
--	,ch.CPA 
--    ,ch.CPC
--    ,ch.[Партнеры] 
--	,ch.uf_clb_type 
--    ,ch.uf_clb_channel
--	,ch.UF_UPDATED_AT
--into #channels_buffer_tmp
--from 
--stg.dbo.lcrm_tbl_full_w_chanals2 ch with(nolock)
--where UF_REGISTERED_AT >= '20160101'
--and UF_ROW_ID is not null
select 
	cast(R.UF_ROW_ID as varchar(255)) as external_id
	,R.[Канал от источника]
	,R.[Группа каналов]
	,cast(null as  [nvarchar](186)) [UF_SIM_OPERATOR]
	,cast(null as  [nvarchar](70)) [UF_SIM_REGION]
	,C.CPA 
    ,C.cpc
    ,C.[Партнеры]
	,R.UF_CLB_TYPE 
    ,R.UF_CLB_CHANNEL
	,R.UF_UPDATED_AT
into #channels_buffer_tmp
from Stg._LCRM.lcrm_leads_full_channel_request AS R (NOLOCK)
	INNER JOIN Stg._LCRM.lcrm_leads_full_calculated AS C (NOLOCK)
		ON R.ID = C.ID
where R.UF_REGISTERED_AT_date >= '20160101'





drop table if exists #channels_buffer
select 
	 ch.external_id
	,ch.[Канал от источника]
	,ch.[Группа каналов]
	,ch.UF_SIM_OPERATOR
	,ch.UF_SIM_REGION
	,ch.CPA 
    ,ch.CPC
    ,ch.[Партнеры] 
	,ch.uf_clb_type 
    ,ch.uf_clb_channel
into #channels_buffer
from(
	select *
	,rn = ROW_NUMBER() over (partition by external_id order by UF_UPDATED_AT desc)
	from #channels_buffer_tmp
	) ch
where ch.rn = 1

drop table if exists #eqv_scoring_distinct
select external_id, score into #eqv_scoring_distinct from (select external_id,score, rn = ROW_NUMBER() over (partition by external_id order by response_date desc) from [dwh_new].[bki].[eqv_scoring] where flag_correct = 1 ) A where rn =1

------------------------------------ All data------------------------------------ 
--if OBJECT_ID('tempdb..##Main_data') is not NULL  drop table ##Main_data
begin tran
delete from dm_MainData
insert into dm_MainData

select distinct  a.external_id
			, cast( a.request_date as date) as appl_date
			, buf.end_date
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
			, cast( appl.[ГП_ПредставлениеКритериевРиска] as varchar(500)) as risks			
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
            , case when dateadd(DAY,32,dateadd(MONTH,1,start_date))<CURRENT_TIMESTAMP then fpd30 else NULL end fpd30 
            , case when dateadd(DAY,6,dateadd(MONTH,1,start_date))<CURRENT_TIMESTAMP then fpd4 else NULL end fpd4
            , case when dateadd(DAY,2,dateadd(MONTH,6,start_date))<CURRENT_TIMESTAMP then HR90@6_v2 else NULL end hr90@6
            , case when dateadd(DAY,2,dateadd(MONTH,4,start_date))<CURRENT_TIMESTAMP then HR30@4 else NULL end hr30@4
			, case when buf.overdue_days_4m >=31  then buf.principal_rest_4m  when buf.overdue_days_4m  is not NULL then 0 end as [30+4MoB]
			, case when buf.overdue_days_6m >=91  then buf.principal_rest_6m  when buf.overdue_days_6m  is not NULL then 0 end as [90+6MoB]
			, case when buf.overdue_days_7m >=91  then buf.principal_rest_7m  when buf.overdue_days_7m  is not NULL then 0 end as [90+7MoB]
			, case when buf.overdue_days_8m >=91  then buf.principal_rest_8m  when buf.overdue_days_8m  is not NULL then 0 end as [90+8MoB]
			, case when buf.overdue_days_9m >=91  then buf.principal_rest_9m  when buf.overdue_days_9m  is not NULL then 0 end as [90+9MoB]
			, case when buf.overdue_days_10m >=91 then buf.principal_rest_10m when buf.overdue_days_10m is not NULL then 0 end as [90+10MoB]
			, case when buf.overdue_days_11m >=91 then buf.principal_rest_11m when buf.overdue_days_11m is not NULL then 0 end as [90+11MoB]	
			, case when buf.overdue_days_12m >=91 then buf.principal_rest_12m when buf.overdue_days_12m is not NULL then 0 end as [90+12MoB]
			, case when buf.overdue_days_16m >=91 then buf.principal_rest_16m when buf.overdue_days_16m is not NULL then 0 end as [90+16MoB]
			, buf.max_dpd_3month
			, buf.max_dpd_4month
			, max_dpd_6month
			, max_dpd_12month 
			, max_dpd 
			, buf.all_paym_1m
			, buf.all_paym_2m
			, buf.all_paym_3m
			, buf.all_paym_4m
			, buf.all_paym_5m
			, buf.all_paym_6m 
			, buf.all_paym_7m
			, buf.all_paym_8m
			, buf.all_paym_9m
			, buf.all_paym_10m
			, buf.all_paym_11m
			, buf.all_paym_12m
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
--into ##Main_data
from  [dwh_new].dbo.tmp_v_requests a left join [dwh_new].dbo.tmp_v_credits b on a.external_id = b.external_id		
										left join #dpd_buffer buf on buf.external_id = a.external_id
										left join [dwh_new].dbo.v_collaterals on  a.collateral_id = v_collaterals.id
											left join [dwh_new].dbo.v_points_of_sale on a.point_of_sale =  v_points_of_sale.id
											left join [dwh_new].dbo.chanels on a.chanel = chanels.id
                                            left join #tmp_statuses ts on ts.external_id=a.external_id
											left join [dwh_new].dbo.persons per on a.person_id = per.id
											left join #eqv_scoring_distinct eqv on a.external_id collate Cyrillic_General_CI_AS = eqv.external_id collate Cyrillic_General_CI_AS	
												left join (select external_id, case when score is NULL then 0 else score end as score 	from  [dwh_new].[visualization].[v_rbp]) sc on a.external_id collate Cyrillic_General_CI_AS = sc.external_id collate Cyrillic_General_CI_AS
												--left join [C1-VSR-SQL05].[BPMOnline_night00].[dbo].[FinApplication] finappl on cast(dwh_new.dbo.getGUIDFrom1C_IDRREF(a.external_link)  as nvarchar(200)) = finappl.id
													--left join stg.[_1cMFO].[Документ_ГП_Заявка]  appl on a.external_id collate Cyrillic_General_CI_AS  = appl.номер collate Cyrillic_General_CI_AS 
														left join #gp_zayavka_buffer appl on a.external_id collate Cyrillic_General_CI_AS  = appl.номер collate Cyrillic_General_CI_AS 
														left join stg.[_1cMFO].Справочник_ГП_ЛиквидностьТС liq  with(nolock) on appl.ЛиквидностьТС = liq.ссылка		
															--left join #fssp on finappl.id = #fssp.FinapplicationId 
															left join #verifiers ver on ver.external_id=a.external_id
																left join [dwh_new].dbo.reject_reasons rr on a.reject_reason = rr.id 
																--left join   stg.dbo.lcrm_tbl_full_w_chanals2 ch on a.external_id = cast(ch.UF_ROW_ID as varchar(1488))
																left join #channels_buffer ch on a.external_id =ch.external_id
																	left join #registration_address on a.external_id = #registration_address.номер
																	left join (select rtrim(ltrim(a.region)) region , id auto_region, federal_okrug, external_id  from [dwh_new].staging.addresses a
																	left join (select distinct region_dwh,id, federal_okrug  
																		from dwh_new.[dbo].[code_regions_auto]  where region_dwh is not null and id <>123) b
																		on rtrim(ltrim(a.region))  collate Cyrillic_General_CI_AS = b.region_dwh ) as reg on a.external_id = reg.external_id
																	left join #sales_address on a.point_of_sale = #sales_address.ps_id
																		full outer join #loginom_info on a.external_id = #loginom_info.number
																		full outer join #loginom_reject  lr1 on a.external_id =lr1.Number and lr1.Stage = 'Call 1' 
																		full outer join #loginom_reject  lr2 on a.external_id =lr2.Number and lr2.Stage = 'Call 2' 
where a.external_id is not null
--Where 1=1 
-- and a.generation >= '2019-06'
-- and  case when b.external_id is not NULL then 1 else 0 end = 1
 --and vehicle_type = 'B'
-- and case when b4.overdue_days >=31  then b4.principal_rest when b4.overdue_days is not NULL then 0 end = 0
-- and a.external_id in (19070100000284, 19070100000080, 19063000000015)
--order by 5
 -- select * from  #loginom_reject
 

/*select * from ##Main_data
where external_id = '19080100000239'
order by appl_date desc*/
commit tran
end


