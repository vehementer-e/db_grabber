CREATE procedure [risk].[base_etl_applications2] as
--exec [risk].[base_etl_applications2]
begin
declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID);
declare @rdt date = dateadd(dd,-30,cast(GETDATE()as date)); --обновляем данные за последние 14 дней

BEGIN TRY
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
--------------------------------ОТБОР ЗАЯВОК ОТ принятия решений
drop table if exists #smpl;
select 
distinct orig.number
,orig.stage
,orig.call_date
,orig.strategy_version
,orig.client_type_1
,orig.client_type_2
,orig.Decision
,orig.Decision_Code
,orig.APR
,orig.Branch_id
,orig.probation
,orig.no_probation
,orig.offername
,orig.apr_segment
,orig.EqxScore
,coalesce(biginstm.productTypeCode, orig.productTypeCode) as productTypeCode --если есть bigInstallmentMarket в application, то он !!!
,orig.productTypeCode as orig_productTypeCode --продукт в Originationlog !!!
,orig.request_amount --запрошенная сумма
,orig.Approved --json-поле, из него будем брать одобренную сумму
,orig.Is_installment
-------------поля для расчета входящего pdn
,orig.income_amount
,orig.rosstat_income
,orig.username
,orig.bki_income
,orig.application_income
,orig.needBki
-------------
,ls.leadsource
,ls.sourceRequest
,ls.sourceRequests

,app.pts_type --тип ПТС (бумажный/электронный)

into #smpl
from stg._loginom.Originationlog orig
left join stg._loginom.application ls
	on orig.number = ls.number
	and ls.stage = 'Call 1'
left join stg._loginom.application app
	on orig.number = app.number
	and app.stage = 'Call 2'
left join #biginstm biginstm
	on orig.number = biginstm.number
	and biginstm.rn = 1
where orig.call_date >= @rdt
and orig.number not in ('19061300000088' ,'20101300041806' ,'21011900071506' ,'21011900071507')
and orig.userName = 'service'
;
--------------------------------ОТБОР по Call 1 + расчет компонентов для входящего ПДН
drop table if exists #call1;
select 
distinct smpl.number
,smpl.apr
,smpl.call_date as C1_date
,smpl.APR as C1_APR
,smpl.probation
,smpl.no_probation
,smpl.apr_segment
,smpl.sourceRequest
,smpl.sourceRequests
,smpl.EqxScore
,smpl.leadsource
,smpl.offername as C1_offername
,smpl.client_type_1
,smpl.decision as C1_decision
,smpl.decision_code as C1_dec_code
,case when smpl.Branch_id in ('3645','5271') then 1 else 0 end REFIN_FL
,smpl.strategy_version
,smpl.productTypeCode
,smpl.orig_productTypeCode --!!!
,smpl.request_amount
,smpl.pts_type
,smpl.Is_installment
,smpl.username
,row_number() over(partition by smpl.number order by smpl.call_date desc) as rn

----компоненты для входящего ПДН
,bki.needBki
,app.Monthly_credit_payments as [app_exp]
,coalesce(kbki2.kbkiEqxAverageMonthlyPaymentTotalAmtPdn, kbki1.kbkiEqxAverageMonthlyPaymentTotalAmtPdn) as bki_exp_amount
,[avg_income] =
				case when smpl.call_date >'2023-12-31' then 
					case when smpl.productTypeCode = 'autoCredit' 
						then risk.min_value(smpl.income_amount,risk.max_value(smpl.rosstat_income,smpl.bki_income*10)) else 
						case when smpl.request_amount > 50000 then
							case when smpl.application_income > 0 then smpl.application_income
							else risk.min_value(isnull(smpl.rosstat_income, 0), isnull(smpl.income_amount, 0))
							end
						else smpl.income_amount*0.9 
						end
					end
				else case	
						when smpl.application_income >= smpl.bki_income
							and smpl.application_income >= risk.min_value(isnull(smpl.rosstat_income, 0), isnull(smpl.income_amount, 0))
							then smpl.application_income
						when smpl.bki_income >= smpl.application_income
							and smpl.bki_income >= risk.min_value(isnull(smpl.rosstat_income, 0), isnull(smpl.income_amount, 0))
							then smpl.bki_income
						when risk.min_value(isnull(smpl.rosstat_income, 0), isnull(smpl.income_amount, 0)) >= smpl.application_income
							and risk.min_value(isnull(smpl.rosstat_income, 0), isnull(smpl.income_amount, 0)) >= smpl.bki_income
							then risk.min_value(isnull(smpl.rosstat_income, 0), isnull(smpl.income_amount, 0))
					end
				end
----
into #call1
from #smpl smpl
left join stg._loginom.Originationlog bki
	on smpl.number = bki.number
	and bki.stage = 'Call 2'
	and bki.needBki = 1
left join stg._loginom.application app
	on smpl.number = app.number
	and app.stage='Call 2'
left join stg._loginom.Origination_kbkiEqxAggregates kbki2
	on smpl.number = kbki2.number
	and kbki2.stage = 'Call 2'
	and app.stage='Call 2'
left join stg._loginom.Origination_kbkiEqxAggregates kbki1
	on smpl.number = kbki1.number
	and kbki1.stage = 'Call 1'
where smpl.stage = 'Call 1' 
--and smpl.[Дубль] = 0
;
--------------------------------ОТБОР по Call 2
drop table if exists #call2;
select 
distinct number
,client_type_2
,decision as C2_decision
,decision_code as C2_dec_code
,strategy_version
,case when Branch_id in ('3645','5271') then 1 else 0 end as REFIN_FL
,apr c2_apr
,apr_segment as c2_apr_segment
,probation
,EqxScore
,pts_type
,case when (probation = 1 and no_probation = 1) then 1 else 0 end as no_probation
,row_number() over(partition by number order by call_date desc) as rn
into #call2
from #smpl
where stage = 'Call 2'
--and [Дубль] = 0
;
--------------------------------ОТБОР по Call 1.2
drop table if exists #call1_2;
select 
distinct number
,decision as C12_decision
,decision_code as C12_dec_code
,row_number() over(partition by number order by call_date desc) as rn
into #call1_2
from #smpl
where stage = 'Call 1.2'
--and [Дубль] = 0
;
--------------------------------ОТБОР по Call 1.5
drop table if exists #call1_5;
select distinct number
,decision as C15_decision
,decision_code as C15_dec_code
,row_number() over(partition by number order by call_date desc)  as rn
into #call1_5
from #smpl
where stage = 'Call 1.5'
--and [Дубль] = 0
;
--------------------------------ОТБОР по Call 3
drop table if exists #call3;
select 
distinct number
,decision as C3_decision
,decision_code as C3_dec_code
,row_number() over(partition by number order by call_date desc) as rn
into #call3
from #smpl
where stage = 'Call 3'
--and [Дубль] = 0
;
--------------------------------ОТБОР по Call 4
drop table if exists #call4;
select 
distinct number
,decision as C4_decision
,decision_code as C4_dec_code
,case 
	when ISJSON(t.Approved) = 1 
	then (select MAX(j.[limit]) from OPENJSON(t.Approved) with ([limit] float '$.limit') AS j) 
	else null end max_limit
,row_number() over(partition by number order by call_date desc) as rn
into #call4
from #smpl t
where stage = 'Call 4'
--and [Дубль] = 0
;
--------------------------------ОТБОР по Call 5
drop table if exists #call5;
select 
distinct number
,decision as C5_decision
,decision_code as C5_dec_code
,case 
	when ISJSON(Approved) = 1 
	then (select MAX(j.[limit]) from OPENJSON(Approved) with ([limit] float '$.limit') AS j) 
	else null end max_limit
,row_number() over(partition by number order by call_date desc) as rn
into #call5
from #smpl
where stage = 'Call 5'
--and [Дубль] = 0
;
-------------------------------------------------------------------------------
----------тут кусок по выданным договорам, чтобы подтянуть данные по выдачам--
-------------------------------------------------------------------------------
-------------------------------определяем дату выдачи кредита ---ВЗЯТЬ ИЗ КРЕДИТС?
drop table if exists #cred_cmr_startdate;
select
a.Договор as credit_id
,cast(dateadd(year, - 2000, min(ДатаВыдачи)) as date) as startdate
into #cred_cmr_startdate
from stg._1ccmr.Документ_ВыдачаДенежныхСредств a
where (a.Проведен = 0x01 AND a.ПометкаУдаления = 0x00 and a.Статус = 0xBB0F3EC282AA989A421CBFE2808BEB5F) 
or a.Договор in ('25051523340087', '25051023319147')
group by a.Договор
;
-------------------------------определяем ставку---ВЗЯТЬ ИЗ КРЕДИТС?
drop table if exists #Int_rate_initial;
select 
a.Код as external_id
,iif(cast(p.ПроцентнаяСтавка as int) = 0, p.НачисляемыеПроценты, p.ПроцентнаяСтавка) as InitialRate
,row_number() over(partition by a.код order by p.Период asc) as rn
into #Int_rate_initial
from stg._1ccmr.Справочник_Договоры a
left join stg._1Ccmr.РегистрСведений_ПараметрыДоговора p 
	on a.ССылка = p.Договор
;
-------------------------------определяем статус--ВЗЯТЬ ИЗ КРЕДИТС?
drop table if exists #cred_cmr_status;
select 
b.Код as external_id
,dateadd(yy, - 2000, a.Период) as dt_status
,c.Наименование as status
,row_number() over(partition by b.Код order by a.Период desc) as rn
into #cred_cmr_status
from stg._1cCMR.РегистрСведений_СтатусыДоговоров a
inner join stg._1cCMR.Справочник_Договоры b 
	on a.Договор = b.Ссылка
inner join stg._1cCMR.Справочник_СтатусыДоговоров c 
	on a.Статус = c.Ссылка
where b.ПометкаУдаления = 0x00
;
----------------------------------ВЗЯТЬ ИЗ КРЕДИТС startdate?
drop table if exists #cash_withdrawal;
select 
l.Код as external_id
,min(cwd.ДатаВыдачи) as cash_withdrawal_date
into #cash_withdrawal
from stg._1ccmr.Документ_ВыдачаДенежныхСредств cwd
inner join stg._1ccmr.Справочник_Договоры l 
	on cwd.Договор = l.Ссылка
where (cwd.Проведен = 0x01
and cwd.ПометкаУдаления = 0x00 
and cwd.Статус = 0xBB0F3EC282AA989A421CBFE2808BEB5F) --Выдано prodsql02.cmr.dbo.Перечисление_СтатусыВыдачиДенежныхСредств
or l.Код in ('25051523340087', '25051023319147') 
GROUP BY l.Код
;
-------------------------------сборка по выданным
drop table if exists #credits;
select
a.Код AS external_id
,a.сумма as amount
,st.startdate
,ir.InitialRate
,hub_ПодтипыПродуктов.ТипПродукта_Code as product_issue
into #credits
from stg._1ccmr.Справочник_Договоры a
left join Stg._1cCMR.Справочник_Заявка cmr_Заявка 
	on cmr_Заявка.Ссылка = a.Заявка
left join stg._1cCMR.Справочник_ПодтипыПродуктов cmr_ПодтипыПродуктов 
	on cmr_Заявка.ПодтипПродукта = cmr_ПодтипыПродуктов.ссылка
left join hub.v_hub_ГруппаПродуктов hub_ПодтипыПродуктов
	on cmr_ПодтипыПродуктов.ВнешнийGuid = hub_ПодтипыПродуктов.ПодтипПродуктd_ВнешнийGUID
inner join #cred_cmr_status cs 
	on cs.external_id = a.Код 
	and cs.rn = 1
	and (cs.status not in ('Аннулирован','Зарегистрирован') or cs.external_id in ('25051523340087', '25051023319147'))
inner join #cash_withdrawal cw 
	on cw.external_id  = a.Код
left join #cred_cmr_startdate st
	on a.Ссылка = st.credit_id
left join #Int_rate_initial ir 
	on ir.external_id = a.Код
	and ir.rn = 1
;
---------------------------------------------------
----------конец куска по выданным договорам--------
---------------------------------------------------
--------------------------------SB_Cash_25 для bigInstallmentMarket
drop table if exists #ags25;
select 
number
,SB_Cash_25
,row_number() over (partition by number order by call_date desc) as rn
into #ags25
from stg._loginom.EqxScore5SBCash25Aggregates ag
where exists (select number from #smpl where number = ag.number)
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
--------------------------------сбор данных на всех стадиях + проверка данных о договоре
drop table if exists #tisk;
select 
call1.number
,call1.C1_date
,day(call1.C1_date) as [DAY]
,month(call1.C1_date) as MON
,concat(month(call1.C1_date),'_',year(call1.C1_date)) as STAGE_DATE_AGG --ПЕРИОД
,case 
	when call1.pts_type = 1 then 'Бумажный' 
	when call1.pts_type = 2 then 'Электронный'
	else 'Не дошел до Call 2' 
	end pts_type
,call1.leadsource
,call1.productTypeCode
,call1.Is_installment
,coalesce(call2.EqxScore, call1.EqxScore) as EqxScore
,case 
	when call1.c1_date >= '20240903 11:40' then 'new_score' 
	when call1.c1_date >= '20240425' then '25.04-30.06.' 
	else 'old_score' 
	end period_date
,coalesce(call2.strategy_version, call1.strategy_version) as strategy_version_last --стратегия

----определяем тип клиента
,case 
	when (call2.client_type_2 ='docred' or call2.client_type_2 = 'parallel') then '2.ACTIVE' --если на С2 докредит или паралел, то это активный клиент
	when (call2.client_type_2='repeated') then '3.REPEATED' --если С2 повторный, значит это повторный клиент
	when (call1.client_type_1='repeated') then '3.REPEATED' --если на С1 повторный, значит повторный клиент
	when (call1.client_type_1='active') then '2.ACTIVE' --если на С1 активный, значит активный клиент
	else '1.NEW' --все остальные новые
	end CLIENT_TYPE 
----

----определяем тип стратегии
,case 
	when call1.strategy_version='INST_V1' then 'INST' --инстолмент
	when (call2.client_type_2 = 'docred' or call2.client_type_2 = 'parallel' or call2.client_type_2 = 'repeated') then 'REP'
	when (call1.client_type_1 = 'repeated' or call1.client_type_1 = 'active') then 'REP'
	else 'NEW'
	end STRAT_TYPE 
----

,case 
	when call5.C5_decision is not null then 'Call 5' --дошел до С5
	when call4.C4_decision is not null then 'Call 4' --дошел до С4
	when call3.C3_decision is not null then 'Call 3'--дошел до С3
	when call2.C2_decision is not null then 'Call 2'--дошел до С2
	when call1_5.C15_decision is not null then 'Call 1.5'--дошел до С15
	when call1_2.C12_decision is not null then 'Call 1.2'--дошел до С12
	else 'Call 1'
	end MAX_STAGE

,coalesce(call5.C5_dec_code, call4.C4_dec_code, call3.C3_dec_code, call2.C2_dec_code, call1_5.C15_dec_code, call1_2.C12_dec_code,call1.C1_dec_code) 
	as DECISION_CODE

,coalesce(call2.probation, call1.probation) as probation

----решения на С1, С12, С15, С2, С3, С4, C5
,call1.C1_decision
,call1_2.C12_decision
,call1_5.C15_decision
,call2.C2_decision
,call3.C3_decision
,call4.C4_decision
,call5.C5_decision 
----

,case when call1.REFIN_FL = 1 or call2.REFIN_FL = 1 then 1 else 0 end as REFIN_FL_ --признак рефинансирования

,call1.C1_APR
,call1.C1_offername
,call1.APR_SEGMENT as c1_apr_segment
,call2.C2_APR
,call2.c2_apr_segment
,call1.apr
----подсчет полож.решений (если решение на call отказ или не принято, то 0, иначе положительно)
,case when C1_decision ='Decline' then 0 else 1 end AR_CALL1 --подсчет неотказов (если решение на С1 отказ,то 0, иначе (положительно или доработка) , то 1)
,case when call1_2.C12_decision ='Decline' or call1_2.C12_decision is null then 0 else 1 end AR_CALL12
,case when call1_5.C15_decision ='Decline' or call1_5.C15_decision is null then 0 else 1 end AR_CALL15
,case when call2.C2_decision ='Decline' or call2.C2_decision is null then 0 else 1 end AR_CALL2
,case when call3.C3_decision ='Decline' or call3.C3_decision is null then 0 else 1 end AR_CALL3
,case when call4.C4_decision ='Decline' or call4.C4_decision is null then 0 else 1 end AR_CALL4
,case when call5.C5_decision ='Decline' or call5.C5_decision is null then 0 else 1 end AR_CALL5

,cast(isnull(replace(credits.amount,',','.'),0) as float) as amount_agr
,credits.startdate
,case when credits.external_id is not null then 1 else 0 end ISSUED_FL
,credits.InitialRate
,credits.product_issue

----RBP (risk best pricing. RBP1 - самый лучший сегмент, самые хорошие ставки)	
,case 
	--RDWH-39
	when call1.productTypeCode = 'bigInstallmentMarket' and BM_rbp.number is not null then BM_rbp.bigMarket_rbp
	when call1.productTypeCode in ('biginstallment', 'bigInstallmentMarket') and ags25.SB_Cash_25 >= 620 then 'RBP 1'
	when call1.productTypeCode in ('biginstallment', 'bigInstallmentMarket') and ags25.SB_Cash_25 >= 567 and ags25.SB_Cash_25 < 620 then 'RBP 2'
	when call1.productTypeCode in ('biginstallment', 'bigInstallmentMarket') and ags25.SB_Cash_25 >= 530 and ags25.SB_Cash_25 < 567 then 'RBP 3'
	when call1.productTypeCode in ('biginstallment', 'bigInstallmentMarket') and ags25.SB_Cash_25 >= 0 and ags25.SB_Cash_25 < 530 then 'RBP 4'
	when call1.productTypeCode in ('biginstallment', 'bigInstallmentMarket') and ags25.SB_Cash_25 is null then 'RBP 4'

	--RDWH-43
	when call1.productTypeCode = 'autoCredit' and coalesce(call2.EqxScore, call1.EqxScore) >= 670 then 'RBP 1'
	when call1.productTypeCode = 'autoCredit' and coalesce(call2.EqxScore, call1.EqxScore) >= 631 
		and coalesce(call2.EqxScore, call1.EqxScore) < 670 then 'RBP 2'
	when call1.productTypeCode = 'autoCredit' and coalesce(call2.EqxScore, call1.EqxScore) >= 590 
		and coalesce(call2.EqxScore, call1.EqxScore) < 631 then 'RBP 3'
	when call1.productTypeCode = 'autoCredit' and (coalesce(call2.EqxScore, call1.EqxScore) < 590 
		or coalesce(call2.EqxScore, call1.EqxScore) is null) then 'RBP 4'

	--RDWH-22
    when (call2.client_type_2 ='docred' or call2.client_type_2 = 'parallel') or (call2.client_type_2 is null and call1.client_type_1 =  'active') 
		then 'АКТИВНЫЕ'
    when (call1.client_type_1 = 'repeated' and call2.client_type_2 is null) or call2.client_type_2 = 'repeated' then 'ПОВТОРНЫЕ'
    when coalesce(call2.probation, call1.probation) = 1 then 'RBP PROBATION' --сегмент RBP испытательный срок
    when (call1.REFIN_FL = 1 or call2.REFIN_FL = 1) then 'RBP REFIN' ----сегмент RBP рефинансирование
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
----
,call1.request_amount
,call1.username

,case when call1.productTypeCode in ('bigInstallmentMarket', 'bigInstallment') then call5.max_limit else call4.max_limit end max_limit

,pdn_income = round(
	case when call1.avg_income > 0
		then (case when call1.needBki = 1 then call1.app_exp else call1.bki_exp_amount end)/call1.avg_income
		else null end
		,3)

into #tisk
from #call1 call1
left join #call2 call2
	on call1.number = call2.number
	and call2.rn = 1
left join #call1_5 call1_5
	on call1.number = call1_5.number
	and call1_5.rn = 1
left join #call3 call3
	on call1.number = call3.number
	and call3.rn = 1
left join #call4 call4
	on call1.number = call4.number
	and call4.rn = 1
left join #call5 call5
	on call1.number = call5.number
	and call5.rn = 1
left join #call1_2 call1_2
	on call1.number = call1_2.number
	and call1_2.rn = 1
left join stg._loginom.Originationlog m
	on call1.number = m.number
	and m.stage = 'Call 2'
	and m.call_date >= '20230127 12:18'
left join #credits credits
	on call1.number = credits.external_id
left join #ags25 ags25
	on call1.number = ags25.number
	and ags25.rn = 1
left join #bigMarket_rbp BM_rbp
	on call1.number = BM_rbp.Number
where call1.rn = 1 
;
--------------------------------final STATUS
drop table if EXISTS #tisk2;
select 
distinct tisk.*
,case	
	when (tisk.AR_CALL1+tisk.AR_CALL15+tisk.AR_CALL2+tisk.AR_CALL3+tisk.AR_CALL4+tisk.AR_CALL5)>0 and tisk.ISSUED_FL=1 then tisk.amount_agr
	else 0
	end LIMIT
,case	
	when rc.reasonName like '%Автоматический отказ%' or rc.stageType = 'Автоматический' then 'ОТКАЗ АВТОМАТ' 
	when rc.reasonCode = '100.0120.106' then 'ОТКАЗ АВТОМАТ'
	when (tisk.MAX_STAGE = 'Call 1.5' and tisk.AR_CALL15 = 0) then 'ОТКАЗ ВЕРИФИКАЦИИ' 
	when (tisk.MAX_STAGE = 'Call 3' and tisk.AR_CALL3 = 0) or (tisk.MAX_STAGE = 'Call 4' and tisk.AR_CALL4 = 0) then 'ОТКАЗ ВЕРИФИКАЦИИ'
	when (tisk.amount_agr is not null and tisk.ISSUED_FL =1) then 'ВЫДАНО' 
	when (tisk.MAX_STAGE = 'Call 4' and tisk.AR_CALL4 = 1) then 'ОДОБРЕНО' 
	when (tisk.AR_CALL5 = 1) then 'ОДОБРЕНО'
	when (tisk.MAX_STAGE = 'Call 1' and tisk.AR_CALL1 = 1) then 'АННУЛИРОВАНО' 
	when (tisk.MAX_STAGE = 'Call 1.2' and tisk.AR_CALL12 = 1) then 'АННУЛИРОВАНО'
	when (tisk.MAX_STAGE = 'Call 1.5' and tisk.AR_CALL15 = 1) then 'АННУЛИРОВАНО'
	when (tisk.MAX_STAGE = 'Call 2' and tisk.AR_CALL2 = 1) then 'АННУЛИРОВАНО'
	when (tisk.MAX_STAGE = 'Call 3' and tisk.AR_CALL3 = 1) then 'АННУЛИРОВАНО'
	when rc.stageType = 'РУЧНОЙ' then 'ОТКАЗ ВЕРИФИКАЦИИ'
	when tisk.Decision_Code = '100.0814.118' then 'ОТКАЗ ВЕРИФИКАЦИИ'
	else '7.WTF'
	end FIN_STATUS

into #tisk2
from #tisk tisk
left join stg.[_loginom].Origination_dict_reason_codes rc
	on rc.reasonCode = tisk.DECISION_CODE
;
--------------------------------входящий DTI и одобренные суммы по беззалогу
drop table if exists #dti;
select 
number
,case
	when incoming_DTI is null then '00.нд'
	when incoming_DTI < 0.5 then '01.[0; 0,5)'
	when incoming_DTI >= 0.5 and incoming_DTI < 0.8 then '02.[0,5; 0,8)'
	when incoming_DTI >= 0.8 then '03.[0,8; inf)'
	else '11.error'
	end incoming_DTI_group
,max_credit_limit_inst
,max_credit_limit_pdl 
,row_number() over (partition by number, stage order by call_date desc) as rn
into #dti
from stg._loginom.calculated_term_and_amount_installment t
where exists (select number from #tisk2 where #tisk2.number = t.number)
and Stage = 'Call 2'
;
--------------------------------Поиск предыдущего продукта 
drop table if exists #prev_prods;
select
external_id
,first_value(credit_type) over (partition by person_id order by startdate) as prev_prod
into #prev_prods
from risk.credits credits
where exists (select number from #tisk2 where #tisk2.number = credits.external_id)
;
--------------------------------pd score
drop table if exists #pd_score;
select 
number
,pd
,row_number() over (partition by number order by call_date desc) as rn
into #pd_score
from stg._loginom.Origination_equifax_aggregates_4 a4
where exists (select number from #tisk2 where #tisk2.number = a4.number)
;
--------------------------------Итоговый свод
drop table if exists #total;
select 
distinct tisk2.number
,tisk2.C1_date
,cast (tisk2.c1_date as date) as [date]
,case 
	when tisk2.CLIENT_TYPE = '1.NEW' then 'НОВЫЙ'
    when tisk2.CLIENT_TYPE = '2.ACTIVE' then 'ДОКРЕД'
	when tisk2.CLIENT_TYPE = '3.REPEATED' then 'ПОВТОРНЫЙ'
	end CLIENT_TYPE
,case 
	when tisk2.CLIENT_TYPE in ('3.REPEATED', '2.ACTIVE') and prev_prods.prev_prod = 'PTS' then 'Повторный ПТС'
	when tisk2.CLIENT_TYPE in ('3.REPEATED', '2.ACTIVE') and prev_prods.prev_prod in ('Installment', 'Pdl')  then 'Повторный Беззалог'
	else 'Новый'
	end repeated_client_type
,tisk2.leadsource
,tisk2.probation
,tisk2.REFIN_FL_
,tisk2.username
,tisk2.MAX_STAGE
,tisk2.C1_decision
,tisk2.C12_decision
,tisk2.C15_decision
,tisk2.C2_decision
,tisk2.C3_decision
,tisk2.C4_decision
,tisk2.C5_decision 
,tisk2.FIN_STATUS
,case when AR_CALL5 = 1 or (AR_CALL4 = 1 and C5_decision is null) then 1 else 0 end AR_FIN --21/10/25 ставничая
,tisk2.AR_CALL4
,tisk2.AR_CALL5
,tisk2.ISSUED_FL
,tisk2.startdate as date_issue
,tisk2.RBP_GR
,tisk2.request_amount

,coalesce(tisk2.max_limit, dti.max_credit_limit_inst, dti.max_credit_limit_pdl) as max_credit_limit --одобренные суммы по ПТС и беззалогу

,tisk2.LIMIT --выданная сумма
,tisk2.Is_installment
,case when tisk2.Is_installment = 1 then 'БЕЗЗАЛОГ' else 'ПТС' end product_type
,tisk2.productTypeCode
,tisk2.InitialRate --ставка

--скоры для разных случаев: pd для беззалога с августа, SB_Cash_25 для бигинст, EqxScore для ПТС и беззалога до августа
,tisk2.EqxScore
,pd_score.pd
,ags25.SB_Cash_25 --RDWH-19
--

,dti.incoming_DTI_group
---входящий пдн
,tisk2.pdn_income
,case
	when tisk2.pdn_income <= 0.5 then '1. <=0,5'
	when tisk2.pdn_income > 0.5 and tisk2.pdn_income <= 0.8 then '2. 0,5 - 0,8'
	when tisk2.pdn_income > 0.8 then '3. > 0,8'
	else 'Не рассчитан'
	end pdn_income_bucket
---

---пдн по выданным
,coalesce(ДоговорЗайма_ПДН_УМФО.pdn, ДоговорЗайма_ПДН_CMR.pdn, ДоговорЗайма_ПДН_risk.pdn) as pdn_cmr
,case
	when coalesce(ДоговорЗайма_ПДН_УМФО.pdn, ДоговорЗайма_ПДН_CMR.pdn, ДоговорЗайма_ПДН_risk.pdn) <= 0.5 then '1. <=0,5'
	when coalesce(ДоговорЗайма_ПДН_УМФО.pdn, ДоговорЗайма_ПДН_CMR.pdn, ДоговорЗайма_ПДН_risk.pdn) > 0.5 
		and coalesce(ДоговорЗайма_ПДН_УМФО.pdn, ДоговорЗайма_ПДН_CMR.pdn, ДоговорЗайма_ПДН_risk.pdn) <= 0.8 then '2. 0,5 - 0,8'
	when coalesce(ДоговорЗайма_ПДН_УМФО.pdn, ДоговорЗайма_ПДН_CMR.pdn, ДоговорЗайма_ПДН_risk.pdn) > 0.8 then '3. > 0,8'
	else 'Не рассчитан'
	end pdn_cmr_bucket
---

---индикаторы риска
,oi.fpd0
,oi.fpd4
,oi.fpd7
,oi.fpd15
,oi.fpd30
,oi._15_4_CMR
,oi._30_4_CMR
,oi._90_6_CMR
,oi._90_12_CMR
---

,appl.car_market_price
,tisk2.product_issue

,doubles.[Дубль]

into #total
from #tisk2 tisk2
left join dbo.dm_OverdueIndicators oi
	on tisk2.number = oi.number
left join Stg._loginom.application appl
	on tisk2.number = appl.number
	and appl.stage = 'Call 4'
left join #dti dti
	on tisk2.number = dti.number
	and dti.rn = 1
left join #prev_prods prev_prods
	on tisk2.number = prev_prods.external_id

-----------------------PDN
left join sat.ДоговорЗайма_ПДН ДоговорЗайма_ПДН_УМФО --в УМФО ПДН вернее
	on cast(tisk2.Number as nvarchar) = cast(ДоговорЗайма_ПДН_УМФО.КодДоговораЗайма as nvarchar)
	and ДоговорЗайма_ПДН_УМФО.Система = 'УМФО'
	and year(ДоговорЗайма_ПДН_УМФО.Дата_по) = 2999

left join sat.ДоговорЗайма_ПДН ДоговорЗайма_ПДН_CMR --ПДН в ЦМР, если нет в УМФО (в УМФО запись появляется не сразу), берем ЦМР
	on cast(tisk2.Number as nvarchar) = cast(ДоговорЗайма_ПДН_CMR.КодДоговораЗайма as nvarchar)
	and ДоговорЗайма_ПДН_CMR.Система = 'CMR'
	and year(ДоговорЗайма_ПДН_CMR.Дата_по) = 2999 --признак актуальности расчета
	and ДоговорЗайма_ПДН_CMR.pdn != -999 --значение -999 невалидно

left join sat.ДоговорЗайма_ПДН ДоговорЗайма_ПДН_risk --последний шанс для ПДН
	on cast(tisk2.Number as nvarchar) = cast(ДоговорЗайма_ПДН_risk.КодДоговораЗайма as nvarchar)
	and ДоговорЗайма_ПДН_risk.Система = 'risk'
-----------------------

left join #pd_score pd_score
	on tisk2.number = pd_score.number
	and pd_score.rn = 1
left join #ags25 ags25
	on tisk2.number = ags25.number
	and ags25.rn = 1
left join Reports.dbo.dm_Factor_Analysis doubles --в этой табличке есть признак дубля заявки
	on tisk2.number = doubles.Номер
;
--------------------------------внесение данных
if OBJECT_ID('risk.applications2') is null
begin
	select 
	top(0) number
	,C1_date
	,date
	,CLIENT_TYPE
	,repeated_client_type
	,leadsource
	,probation
	,REFIN_FL_
	,username
	,MAX_STAGE
	,C1_decision
	,C12_decision
	,C15_decision
	,C2_decision
	,C3_decision
	,C4_decision
	,C5_decision
	,FIN_STATUS
	,AR_FIN
	,AR_CALL4
	,AR_CALL5
	,ISSUED_FL
	,date_issue
	,RBP_GR
	,request_amount
	,max_credit_limit
	,LIMIT
	,Is_installment
	,product_type
	,productTypeCode
	,InitialRate
	,EqxScore
	,pd
	,SB_Cash_25
	,incoming_DTI_group
	,pdn_income
	,pdn_income_bucket
	,pdn_cmr
	,pdn_cmr_bucket
	,fpd0
	,fpd4
	,fpd7
	,fpd15
	,fpd30
	,_15_4_CMR
	,_30_4_CMR
	,_90_6_CMR
	,_90_12_CMR
	,car_market_price
	,product_issue
	into risk.applications2
	from #total
end;

if OBJECT_ID('risk.applications2_doubles') is null
begin
	select top(0) * 
	into risk.applications2_doubles
	from  #total
end;

BEGIN TRANSACTION
	--в нормальную табличку заносим только без дублей
	delete from risk.applications2
	where [date] >= @rdt
	;
	insert into risk.applications2
	select 
	number
	,C1_date
	,date
	,CLIENT_TYPE
	,repeated_client_type
	,leadsource
	,probation
	,REFIN_FL_
	,username
	,MAX_STAGE
	,C1_decision
	,C12_decision
	,C15_decision
	,C2_decision
	,C3_decision
	,C4_decision
	,C5_decision
	,FIN_STATUS
	,AR_FIN
	,AR_CALL4
	,AR_CALL5
	,ISSUED_FL
	,date_issue
	,RBP_GR
	,request_amount
	,max_credit_limit
	,LIMIT
	,Is_installment
	,product_type
	,productTypeCode
	,InitialRate
	,EqxScore
	,pd
	,SB_Cash_25
	,incoming_DTI_group
	,pdn_income
	,pdn_income_bucket
	,pdn_cmr
	,pdn_cmr_bucket
	,fpd0
	,fpd4
	,fpd7
	,fpd15
	,fpd30
	,_15_4_CMR
	,_30_4_CMR
	,_90_6_CMR
	,_90_12_CMR
	,car_market_price
	,product_issue
	from #total
	where [Дубль] = 0
	;
	--в нормальную табличку заносим всё, включая дубли и их признак
	delete from risk.applications2_doubles
	where [date] >= @rdt
	insert into risk.applications2_doubles
	select * from #total

COMMIT TRANSACTION
;
--------------------------обновить индикаторы риска
update risk.applications2
set 
fpd0 = oi.fpd0
,fpd4 = oi.fpd4
,fpd7 = oi.fpd7
,fpd15 = oi.fpd15
,fpd30 = oi.fpd30
,_15_4_CMR = oi._15_4_CMR
,_30_4_CMR = oi._30_4_CMR
,_90_6_CMR = oi._90_6_CMR
,_90_12_CMR = oi._90_12_CMR
from dbo.dm_OverdueIndicators oi
left join risk.applications2 total
	on oi.number = total.number
where oi.number = total.number
;
update risk.applications2_doubles
set 
fpd0 = oi.fpd0
,fpd4 = oi.fpd4
,fpd7 = oi.fpd7
,fpd15 = oi.fpd15
,fpd30 = oi.fpd30
,_15_4_CMR = oi._15_4_CMR
,_30_4_CMR = oi._30_4_CMR
,_90_6_CMR = oi._90_6_CMR
,_90_12_CMR = oi._90_12_CMR
from dbo.dm_OverdueIndicators oi
left join risk.applications2_doubles total
	on oi.number = total.number
where oi.number = total.number
;
insert into risk.applications2_history --логирование
select *, getdate() as insertdate from risk.applications2;

drop table if exists #biginstm;
drop table if exists #smpl;
drop table if exists #call1;
drop table if exists #call2;
drop table if exists #call1_2;
drop table if exists #call1_5;
drop table if exists #call3;
drop table if exists #call4;
drop table if exists #call5;
drop table if exists #tisk;
drop table if exists #tisk2;
drop table if exists #dti;
drop table if exists #pd_score;
drop table if exists #SB_cash;
drop table if exists #total;

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
			,@recipients = 'ala.kurikalov@smarthorizon.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;