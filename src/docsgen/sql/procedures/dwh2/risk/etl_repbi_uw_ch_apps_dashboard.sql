
--exec [risk].[etl_repbi_uw_ch_apps_dashboard];
CREATE PROC [risk].[etl_repbi_uw_ch_apps_dashboard]
AS
BEGIN
DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
declare @rdt date = '2023-10-25';

BEGIN TRY
	EXEC risk.set_debug_info @sp_name
		,'START INST';
--------------------------------поиск bigInstallmentMarket !!! RDWH-39
--есть часть потока которые пришли как bigInstallmentMarket, а на колл 1 в originationlog мы их пересадили в installment/pdl
drop table if exists #biginstm;
select
number
,productTypeCode
,row_number() over (partition by number order by (select null)) as rn
into #biginstm
from stg._loginom.application app
where stage = 'Call 1'
and productTypeCode = 'bigInstallmentMarket'
;
-------------------------------выботка по Call 1. Из applications не берем, потому что нужны и дубли заявок
drop table if exists #call1;
select 
orig.number
,cast(orig.call_date as date) as C1_date
,orig.decision as C1_decision
,orig.client_type_1
,orig.strategy_version
,orig.probation
,case when orig.Branch_id in ('3645','5271') then 1 else 0 end REFIN_FL
,orig.APR_SEGMENT
,coalesce(biginstm.productTypeCode, orig.productTypeCode) as productTypeCode --если есть bigInstallmentMarket в application, то он !!!
,orig.productTypeCode as orig_productTypeCode --продукт в Originationlog !!!
,EqxScore
,row_number() over (partition by orig.number order by orig.call_date desc) as rn
into #call1
from stg._loginom.Originationlog orig
left join #biginstm biginstm
	on orig.number = biginstm.number
	and biginstm.rn = 1
where orig.stage = 'Call 1'
and orig.call_date >= @rdt
and orig.Last_name not like '%Тест%'
;
-------------------------------выботка по Call 2
drop table if exists #call2;
select 
number
,RequiredChecks
,uw_segment
,client_type_2
,call_date as c2_date
,probation
,case when Branch_id in ('3645','5271') then 1 else 0 end REFIN_FL
,APR_SEGMENT as c2_apr_segment
,EqxScore
,row_number() over (partition by number order by call_date desc) as rn
into #call2
from [stg].[_loginom].[Originationlog]
where stage = 'Call 2'
and call_date >= @rdt
;
--------------------------------SB_Cash_25 для bigInstallmentMarket
drop table if exists #ags25;
select 
number
,SB_Cash_25
,row_number() over (partition by number order by call_date desc) as rn
into #ags25
from stg._loginom.EqxScore5SBCash25Aggregates ag
where exists (select number from #call1 where number = ag.number)
and SB_Cash_25 is not null
;
----rbp только для bigInstallmentMarket !!! RDWH-39
drop table if exists #bigMarket_rbp;
select 
biginstm.number
,biginstm.productTypeCode as bigproductTypeCode
,call1.orig_productTypeCode as c1productTypeCode
,case 
	when biginstm.productTypeCode = 'bigInstallmentMarket' and call1.orig_productTypeCode <> 'bigInstallmentMarket' then 'DOWNSELL'
	when SB_Cash_25 >= 620 then 'RBP 1'
	when SB_Cash_25 >= 567 and SB_Cash_25 < 620 then 'RBP 2'
	when SB_Cash_25 >= 530 and SB_Cash_25 < 567 then 'RBP 3'
	when SB_Cash_25 >= 0 and SB_Cash_25 < 530 then 'RBP 4'
	when SB_Cash_25 is null then 'RBP 4'
	else 'wtf'
	end bigMarket_rbp
into #bigMarket_rbp
from #biginstm biginstm
left join #call1 call1
	on biginstm.number = call1.number
	and call1.rn = 1
left join #ags25
	on biginstm.number = #ags25.number
	and #ags25.rn = 1
;
-------------------------------свод по заявкам
drop table if exists #apps;
select 
call1.number
,call1.C1_decision
,call2.uw_segment
,case 
	when call2.RequiredChecks LIKE '%2.109%' then 1 
	when (call2.RequiredChecks IS NULL OR call2.RequiredChecks = '') then 1000
	else 0
	end fl_chch_inst
,case 
	when RequiredChecks LIKE '%2.12%' then 1
	when (RequiredChecks IS NULL OR RequiredChecks = '') then 1000 
	else 0
	end fl_chch_pts
,case when call2.uw_segment = 1900 then 'Банкроты' else 'Другие сегменты' end gr_uw_segment
,case when coalesce(call2.c2_date,'20231101 18:16') >= '20231101 18:16' then 1 else 0 end fl_date
,case 
	when (call2.client_type_2 ='docred' or call2.client_type_2 = 'parallel') then '2.ACTIVE' --если на С2 докредит или паралел, то это активный клиент
	when (call2.client_type_2='repeated') then '3.REPEATED' --если С2 повторный, значит это повторный клиент
	when (call1.client_type_1='repeated') then '3.REPEATED' --если на С1 повторный, значит повторный клиент
	when (call1.client_type_1='active') then '2.ACTIVE' --если на С1 активный, значит активный клиент
	else '1.NEW' --все остальные новые
	end CLIENT_TYPE 
,call1.strategy_version
,case 
	--RDWH-39
	when call1.productTypeCode = 'biginstallment' and ags25.SB_Cash_25 >= 620 then 'RBP 1'
	when call1.productTypeCode = 'biginstallment' and ags25.SB_Cash_25 >= 567 and ags25.SB_Cash_25 < 620 then 'RBP 2'
	when call1.productTypeCode = 'biginstallment' and ags25.SB_Cash_25 >= 530 and ags25.SB_Cash_25 < 567 then 'RBP 3'
	when call1.productTypeCode = 'biginstallment' and ags25.SB_Cash_25 >= 0 and ags25.SB_Cash_25 < 530 then 'RBP 4'
	when call1.productTypeCode = 'biginstallment' and ags25.SB_Cash_25 is null then 'RBP 4'
	when call1.productTypeCode = 'bigInstallmentMarket' then BM_rbp.bigMarket_rbp

	--RDWH-43
	when call1.productTypeCode = 'autoCredit' and coalesce(call2.EqxScore, call1.EqxScore) >= 670 then 'RBP 1'
	when call1.productTypeCode = 'autoCredit' and coalesce(call2.EqxScore, call1.EqxScore) >= 631 
		and coalesce(call2.EqxScore, call1.EqxScore) < 670 then 'RBP 2'
	when call1.productTypeCode = 'autoCredit' and coalesce(call2.EqxScore, call1.EqxScore) >= 590 
		and coalesce(call2.EqxScore, call1.EqxScore) < 631 then 'RBP 3'
	when call1.productTypeCode = 'autoCredit' and (coalesce(call2.EqxScore, call1.EqxScore) < 590 
		or coalesce(call2.EqxScore, call1.EqxScore) is null) then 'RBP 4'

	--RDWH-22
    when (call2.client_type_2 ='docred' or call2.client_type_2 = 'parallel') or (call2.client_type_2 is null and call1.client_type_1 = 'active') 
		then 'АКТИВНЫЕ'
    when (call1.client_type_1 = 'repeated' and call2.client_type_2 is null) or call2.client_type_2 = 'repeated' then 'ПОВТОРНЫЕ'
    when coalesce(call2.probation, call1.probation) = 1 then 'RBP PROBATION'
    when (call1.REFIN_FL = 1 or call2.REFIN_FL = 1) then 'RBP REFIN'
	when coalesce(call2.c2_apr_segment, call1.APR_SEGMENT) in ('1','2','3','4', '1001','1002','1003', '1071', '1051') then 'RBP 1'
	when coalesce(call2.c2_apr_segment, call1.APR_SEGMENT) in ('10','20','21','22','23','24', '1101', '1171', '1151') then 'RBP 2'
	when call1.C1_date > '2021-11-11' 
		and ((call1.APR_SEGMENT in ('60','61','62','63','101','102','103','104','50','51','52','53','54', '1201', '1202', '1271', '1251') 
		and call2.c2_apr_segment is null)
		or call2.c2_apr_segment in ('60','61','62','63','101','102','103','104','50','51','52','53','54', '1201', '1202', '1271', '1251')) 
		then 'RBP 3'
	when coalesce(call2.c2_apr_segment, call1.APR_SEGMENT) in ('1301','1371','1351') then 'RBP 4'
    else 'RBP 4'
    end RBP_GR 
into #apps
from #call1 call1
left join #call2 call2
	on call1.number = call2.number
	and call2.rn = 1
left join #ags25 ags25
	on call1.number = ags25.number
	and ags25.rn = 1
left join #bigMarket_rbp BM_rbp
	on call1.number = BM_rbp.Number
where call1.rn = 1
;
-------------------------------sampleFedor - проверки
drop table if exists #sampleFedorInstallment;
select 
distinct [Номер заявки] as number
,[Статус]
,[Дата статуса]
,[Состояние заявки]
,[Задача]
into #sampleFedorInstallment
from Reports.dbo.dm_FedorVerificationRequests_without_coll with (nolock)
where ProductType_Code = 'installment'
and [Состояние заявки] = 'В работе'
and exists (select number from #apps where number = [Номер заявки])
;

drop table if exists #sampleFedorpts;
select 
distinct [Номер заявки] as number
,[Статус]
,[Дата статуса]
,[Состояние заявки]
,[Задача]
into #sampleFedorpts
from Reports.dbo.dm_FedorVerificationRequests with (nolock)
where exists (select number from #apps where number = [Номер заявки])
and [Состояние заявки] = 'В работе'
;
-------------------------------final по inst
drop table if exists #inst;
select 
apps.number
,c15.[Дата статуса] as DATE_c15
,case when apps.CLIENT_TYPE = '1.NEW' then 'Новые' else 'Повторные' end CLIENT_TYPE
,apps.gr_uw_segment
,case when apps.fl_chch_inst = 0 then 'Упрощенная проверка' else 'Полная проверка' end fl_chch
,apps.uw_segment
,case when (cnt_int_C15 > 0) then 1 else 0 end CH_FL --флаг была/не была заявка на С15
,c3.[Дата статуса] as DATE_c3
,case when (cnt_int_C3 > 0) then 1 else 0 end UW_C3_FL --флаг была/не была заявка на С3
into #inst
from #apps apps
left join
	(
	select 
	number
	,cast([Дата статуса] as date) as [Дата статуса]
	,count(number) over (partition by number) as cnt_int_C15
	,row_number() over (partition by number order by [Дата статуса] desc) as rn
	from #sampleFedorInstallment
	where [Статус] = 'Контроль данных'
	) c15
	on c15.[number] = apps.number
	and c15.rn = 1
left join
	(
	select 
	number
	,cast([Дата статуса] as date) as [Дата статуса]
	,count(number) over (partition by number) as cnt_int_C3
	,row_number() over (partition by number order by [Дата статуса] desc) as rn
	from #sampleFedorInstallment
	where [Статус] = 'Верификация клиента'
	) c3 
	on c3.number = apps.number
	and c3.rn = 1
where apps.C1_decision != 'Decline'
and apps.FL_DATE = 1
and apps.strategy_version = 'INST_V1'
;
----------------------------------------final по pts
drop table if exists #pts;
select 
apps.number
,c15pts.[Дата статуса] as DATE_c15
,c3pts.[Дата статуса] as DATE_c3
,case when (c15pts.cnt_int_C15 > 0) then 1 else 0 end CH_FL
,case when (cnt_int_C3 > 0) then 1 else 0 end UW_C3_FL
,case when apps.CLIENT_TYPE = '1.NEW' then 'Новые' else 'Повторные' end CLIENT_TYPE
,case when apps.CLIENT_TYPE <> '1.NEW' then null else apps.RBP_GR end gr_uw_segment
,case when apps.fl_chch_pts = 0 then 'Упрощенная проверка' else 'Полная проверка' end fl_chch
,apps.uw_segment
into #pts
from #apps apps
left join
	(
	select 
	number
	,cast([Дата статуса] as date) as [Дата статуса]
	,count(number) over (partition by number) as cnt_int_C15
	,row_number() over (partition by number order by [Дата статуса] desc) as rn
	from #sampleFedorpts
	where [Статус] = 'Контроль данных'
	) c15pts
	on c15pts.number = apps.number
	and c15pts.rn = 1
left join
	(
	select 
	number
	,cast([Дата статуса] as date) as [Дата статуса]
	,count(number) over (partition by number) as cnt_int_C3
	,row_number() over (partition by number order by [Дата статуса] desc) as rn
	from #sampleFedorpts
	where [Статус] = 'Верификация клиента'
	) c3pts 
	on c3pts.number = apps.number
	and c3pts.rn = 1
where apps.C1_decision != 'Decline'
and apps.strategy_version != 'INST_V1'
;
-----------------------------------------внесение
BEGIN TRANSACTION;
	delete from risk.repbi_uw_ch_apps_dashboard;		

	--Инст Неделя
	set datefirst 1; --понедельник = 1, воскресенье = 7
	insert into risk.repbi_uw_ch_apps_dashboard
	select 
	number
	,DATE_c15
	,CLIENT_TYPE
	,gr_uw_segment
	,fl_chch
	,uw_segment
	,CH_FL
	,DATE_c3
	,UW_C3_FL
	,concat_ws (' - ', format(dateadd(dd, 1 - datepart(dw, DATE_c3), DATE_c3), 'dd/MM')	
		,format(dateadd(dd, 7 - datepart(dw, DATE_c3), DATE_c3), 'dd/MM/yyyy')) as rep_period
	,-cast(format(cast(dateadd(dd, 7 - datepart(dw, DATE_c3), DATE_c3) as date), 'yyyyMMdd') as bigint) as rep_period_dt
	,'2. Неделя' as metric
	,concat_ws (' - ', format(dateadd(dd, 1 - datepart(dw, DATE_c15), DATE_c15), 'dd/MM')
		,format(dateadd(dd, 7 - datepart(dw, DATE_c15), DATE_c15), 'dd/MM/yyyy')) as rep_period_ch
	,-cast(format(cast(dateadd(dd, 7 - datepart(dw, DATE_c15), DATE_c15) as date), 'yyyyMMdd') as bigint) as rep_period_dt_ch
	,'Инстоллмент' as product
	from #inst
	;
	--Инст День
	insert into risk.repbi_uw_ch_apps_dashboard
	select 
	number
	,DATE_c15
	,CLIENT_TYPE
	,gr_uw_segment
	,fl_chch
	,uw_segment
	,CH_FL
	,DATE_c3
	,UW_C3_FL
	,format(DATE_c3, 'dd/MM/yyyy') as rep_period
	,- cast(format(DATE_c3, 'yyyyMMdd') as bigint) as rep_period_dt
	,'1. День' AS metric
	,format(DATE_c15, 'dd/MM/yyyy') as rep_period_ch
	,- cast(format(DATE_c15, 'yyyyMMdd') as bigint) as rep_period_dt_ch
	,'Инстоллмент'
	from #inst
	;
	--Инст Месяц
	insert into risk.repbi_uw_ch_apps_dashboard
	select 
	number
	,DATE_c15
	,CLIENT_TYPE
	,gr_uw_segment
	,fl_chch
	,uw_segment
	,CH_FL
	,DATE_c3
	,UW_C3_FL
	,format(cast(dateadd(m, datediff(m, 0, cast(DATE_c3 as date)), 0) as date), 'dd/MM/yyyy') as rep_period
	,-cast(format(cast(cast(dateadd(m, datediff(m, 0, cast(DATE_c3 as date)), 0) as date) as date), 'yyyyMMdd') as bigint) as rep_period_dt
	,'3. Месяц' AS metric
	,format(cast(dateadd(m, datediff(m, 0, cast(DATE_c15 as date)), 0) as date), 'dd/MM/yyyy') as rep_period_ch
	,-cast(format(cast(cast(dateadd(m, datediff(m, 0, cast(DATE_c15 as date)), 0) as date) as date), 'yyyyMMdd') as bigint) as rep_period_dt_ch
	,'Инстоллмент'
	from #inst
	;
	--pts Неделя
	insert into risk.repbi_uw_ch_apps_dashboard
	select 
	number
	,DATE_c15
	,CLIENT_TYPE
	,gr_uw_segment
	,fl_chch
	,uw_segment
	,CH_FL
	,DATE_c3
	,UW_C3_FL
	,concat_ws (' - ', format(dateadd(dd, 1 - datepart(dw, DATE_c3), DATE_c3), 'dd/MM')	
		,format(dateadd(dd, 7 - datepart(dw, DATE_c3), DATE_c3), 'dd/MM/yyyy')) as rep_period
	,-cast(format(cast(dateadd(dd, 7 - datepart(dw, DATE_c3), DATE_c3) as date), 'yyyyMMdd') as bigint) as rep_period_dt
	,'2. Неделя' AS metric
	,concat_ws (' - ', format(dateadd(dd, 1 - datepart(dw, DATE_c15), DATE_c15), 'dd/MM')
		,format(dateadd(dd, 7 - datepart(dw, DATE_c15), DATE_c15), 'dd/MM/yyyy')) as rep_period_ch
	,-cast(format(cast(dateadd(dd, 7 - datepart(dw, DATE_c15), DATE_c15) as date), 'yyyyMMdd') as bigint) as rep_period_dt_ch
	,'ПТС'
	FROM #pts;
	--pts День
	insert into risk.repbi_uw_ch_apps_dashboard
	select 
	number
	,DATE_c15
	,CLIENT_TYPE
	,gr_uw_segment
	,fl_chch
	,uw_segment
	,CH_FL
	,DATE_c3
	,UW_C3_FL
	,format(DATE_c3, 'dd/MM/yyyy') as rep_period
	,-cast(format(DATE_c3, 'yyyyMMdd') as bigint) as rep_period_dt
	,'1. День' as metric
	,format(DATE_c15, 'dd/MM/yyyy') as rep_period_ch
	,-cast(format(DATE_c15, 'yyyyMMdd') as bigint) as rep_period_dt_ch
	,'ПТС'
	from #pts;
	--pts Месяц
	insert into risk.repbi_uw_ch_apps_dashboard
	select 
	number
	,DATE_c15
	,CLIENT_TYPE
	,gr_uw_segment
	,fl_chch
	,uw_segment
	,CH_FL
	,DATE_c3
	,UW_C3_FL
	,format(cast(dateadd(m, datediff(m, 0, cast(DATE_c3 as date)), 0) as date), 'dd/MM/yyyy') as rep_period
	,-cast(format(cast(cast(dateadd(m, datediff(m, 0, cast(DATE_c3 as date)), 0) as date) as date), 'yyyyMMdd') as bigint) as rep_period_dt
	,'3. Месяц' as metric
	,format(cast(dateadd(m, datediff(m, 0, cast(DATE_c15 as date)), 0) as date), 'dd/MM/yyyy') as rep_period_ch
	,-cast(format(cast(cast(dateadd(m, datediff(m, 0, cast(DATE_c15 as date)), 0) as date) as date), 'yyyyMMdd') as bigint) as rep_period_dt_ch
	,'ПТС'
	from #pts;
COMMIT TRANSACTION;

drop table if exists #biginstm;
drop table if exists #ags25;
drop table if exists #call1;
drop table if exists #call2;
drop table if exists #apps;
drop table if exists #sampleFedorInstallment;
drop table if exists #sampleFedorpts;
drop table if exists #inst;
drop table if exists #pts;

EXEC risk.set_debug_info @sp_name
	,'FINISH';

END TRY

BEGIN CATCH
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

	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;

	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
		,@recipients = 'risk_tech@carmoney.ru; risk_portfolio@carmoney.ru; risk-technology@carmoney.ru'
		,@copy_recipients = 'dwh112@carmoney.ru'
		,@body = @msg
		,@body_format = 'TEXT'
		,@subject = @subject;

	throw 51000
		,@msg
		,1
END CATCH
END;
