CREATE procedure [risk].[fill_contract_requests] as 
begin
--exec [risk].[fill_contract_requests]
declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID);
declare @rdt date = '2025-03-01';
BEGIN TRY
--------------------------выборка заявок: где-то запрос идет по person_id, где-то по guid; где-то с Call 1, где-то с Call 03
drop table if exists #apps;
select 
ol.guid
,ol.number
,ol.NSPK_score_value21
,ol.stage
,row_number() over (partition by ol.guid, ol.stage order by ol.NSPK_score_value21 desc) as rn
into #apps
from stg._loginom.Originationlog ol
where stage in ('Call 03', 'Call 1')
and call_date >= @rdt
and username = 'service'
and Last_name not like 'Тест%'
;
------RDWH-40
drop table if exists #apps_CCT;
select 
ol.guid
,ol.number
,ol.stage
,row_number() over (partition by ol.guid, ol.stage order by ol.NSPK_score_value21 desc) as rn
into #apps_CCT
from stg._loginom.Originationlog ol
where stage = 'Call_checkTransfer'
and call_date >= @rdt
and username = 'service'
;
---------------------------------------------------------запросы
drop table if exists #response;
select 
id
,cast(request_date as date) as request_date
,person_id --number
,guid
,source
,case 
	when isnull(cache_flg, 0) <> 1 and isnull(validReport_flg, 0) = 1 
	then 1 
	else 0 
	end request_NOcache_VALID --признак валидности и кэша. если 1, то ок
into #response
from Stg._loginom.Original_response
where process = 'Origination'
and request_date >= @rdt
and source in (
'5Score_SB_Cash_25',
'equifax',
'fincard',
'fps',
'JuicyScore',
'KbkiEqx',
'nbch',
'NSPK',
'spectrum_report_ads_price',
'spectrum_report_commercial_use',
'spectrum_report_documents',
'spectrum_report_mileages',
'spectrum_report_taxi'
,'SafeID'
,'fincert'
,'DBrain'
,'MobileScoring'
)
insert into #response
select * from risk.contract_requests_5Score_PSB--RDWH-40
;
--------------------------------поиск продукта
--1. любой продукт определяем 'Call 1' в stg._loginom.application
drop table if exists #application;
select
number
,Stage_date
,productTypeCode
,row_number() over (partition by number order by (select null)) as rn
into #application
from stg._loginom.application app
where stage = 'Call 1'
and productTypeCode is not null
and Stage_date >= @rdt
;
--2. любой продукт определяем 'Call 1' в stg._loginom.oridinationlog
drop table if exists #call1;
select 
guid
,number
,call_date
,productTypeCode
,row_number() over (partition by number order by call_date) as rn
into #call1
from stg._loginom.Originationlog
where stage = 'Call 1'
and productTypeCode is not null
and call_date >= @rdt
;
--3. strategy_version в stg._loginom.oridinationlog с call 03
drop table if exists #strategy;
select 
guid
,call_date
,strategy_version as productTypeCode
,row_number() over (partition by guid order by call_date) as rn
into #strategy
from stg._loginom.Originationlog
where stage = 'Call 03'
and strategy_version in ('bigInstallmentMarket', 'pts')
and call_date >= @rdt
;
--4. bigInstallmentMarket и pts ищем на 'PreCall 1' oridinationlog
drop table if exists #precall;
select 
guid
,call_date
,case 
	when availableProductType_code like '%bigInstallmentMarket%' then 'bigInstallmentMarket' 
	when availableProductType_code like '%pts%' then 'pts'
	end productTypeCode
,row_number() over (partition by guid order by call_date) as rn
into #precall
from stg._loginom.Originationlog
where stage = 'PreCall 1'
and (availableProductType_code like '%bigInstallmentMarket%' or availableProductType_code like '%pts%')
and call_date >= @rdt
;
---------------------------------------------------------
drop table if exists #total;
select 
response.id
,response.request_date
,response.person_id --number
,response.guid
,response.source
,response.request_NOcache_VALID
,coalesce(app.productTypeCode, call1.productTypeCode, strategy.productTypeCode, precall.productTypeCode) as productTypeCode
,coalesce(apps.NSPK_score_value21, apps2.NSPK_score_value21) as NSPK_score_value21
into #total
from #response response
left join #apps apps
	on apps.number = response.person_id
	and apps.stage = 'Call 1'
	and apps.rn = 1
left join #apps apps2
	on apps2.guid = response.guid
	and apps2.stage = 'Call 03'
	and apps2.rn = 1
--продукты
left join #application app
	on app.number = response.person_id
	and app.rn = 1
left join #call1 call1
	on call1.number = response.person_id
	and call1.rn = 1
left join #strategy strategy
	on strategy.guid = response.guid
	and strategy.rn = 1
left join #precall precall
	on precall.guid = response.guid
	and precall.rn = 1
--
;
------RDWH-40 добавить проверки KbkiEqx с Call_checkTransfer
insert into #total
select 
response.id
,response.request_date
,response.person_id --number
,response.guid
,'KbkiEqx (только Call_checkTransfer)' as source
,response.request_NOcache_VALID
,coalesce(app.productTypeCode, call1.productTypeCode, strategy.productTypeCode, precall.productTypeCode) as productTypeCode
,null as NSPK_score_value21
from #response response
join #apps_CCT apps_CCT
	on apps_CCT.number = response.person_id
	and apps_CCT.rn = 1
join #apps_CCT apps_CCT2
	on apps_CCT2.guid = response.guid
	and apps_CCT2.rn = 1
--продукты
left join #application app
	on app.number = response.person_id
	and app.rn = 1
left join #call1 call1
	on call1.number = response.person_id
	and call1.rn = 1
left join #strategy strategy
	on strategy.guid = response.guid
	and strategy.rn = 1
left join #precall precall
	on precall.guid = response.guid
	and precall.rn = 1
--
where response.source = 'KbkiEqx'
;
--------------------------------------------------------
if OBJECT_ID('risk.contract_requests') is null
begin
	select top(0) * into risk.contract_requests
	from #total
end;

BEGIN TRANSACTION
	delete from risk.contract_requests

	insert into risk.contract_requests
	select * from #total
	;
COMMIT TRANSACTION;

drop table if exists #biginstm;
drop table if exists #prods;
drop table if exists #prods2;
drop table if exists #apps;
drop table if exists #apps_CCT;
drop table if exists #response;
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
