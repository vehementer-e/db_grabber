CREATE procedure [risk].[portfolio_report] as
begin
--exec [risk].[portfolio_report]
declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID);
declare @rdt date = '2024-01-01';
BEGIN TRY
-------------------признак "без БКИ" и needPTS. нужен только для залогов, собирается на Call 2
drop table if exists #bki;
select 
number
,coalesce(needBki,1) as needBki
,needPTS
,productTypeCode
,row_number() over (partition by number order by call_date desc) as rn
into #bki
from stg._loginom.Originationlog ol
where exists (
	select number from risk.applications2 ra2
	where ol.number = ra2.number)
and stage = 'Call 2'
and productTypeCode in ('pts', 'autoCredit', 'ptsLite', 'ptsLight')
and call_date >= @rdt
;
-------------------самозянтые
drop table if exists #semp;
select 
distinct number
,selectedOffer 
into #semp
from stg._loginom.application
where selectedOffer = 'selfEmployed'
;
-------------------типы проверок
drop table if exists #checks;
select 
distinct number
,verif_type
,row_number() over (partition by number order by call_date desc) as rn
into #checks
from risk.check_types_report
;
-------------------данные по авто
drop table if exists #cars;
select 
number
,name_brand
,year_ts
,row_number() over(partition by number order by stage_date desc) as rn 
into #cars
from stg._loginom.application
where stage = 'Call 2'
;
-------------------решения по коллам
drop table if exists #calls;
select 
number
,call_date
,stage
,decision
,case  
	when rc.[Classification level 1] = 'Минимальные требования (заявитель)' then '01. Минимальные требования (заявитель)'
	when rc.[Classification level 1] = 'Негативная информация (внутренние источники)' then '02. Негативная информация (внутр источники)'
	when rc.[Classification level 1] = 'Отказ по скору' then '03. Отказ по скору'
	when rc.[Classification level 1] = 'Негативная информация (внешние источники)' then '04. Негативная информация (внешние источники)'
	when rc.[Classification level 1] = 'Минимальные требования (предмет залога)' then '05. Минимальные требования (предмет залога)'
	when rc.[Classification level 1] = 'Отказ по лимиту' then '06. Отказ по лимиту'
	when rc.[Classification level 1] = 'Другое' then '07. Другое'
	when rc.[Classification level 1] = 'Верификация клиента' then '08. Верификация клиента'
	when rc.[Classification level 1] = 'Верификация авто' then '09. Верификация авто'
	when decision_code in ('100.0708.004', '100.0120.106') then '08. Верификация клиента'
	when decision = 'Accept' then '10. Одобрено'
	when rc.[Classification level 1] is null then '07. Другое'
	else rc.[Classification level 1]
	end [Classification level 1]
,rc.[Classification level 2]
,row_number() over (partition by number, stage order by call_date desc) as rn
into #calls
from stg._loginom.originationlog ol
left join stg._loginom.Origination_dict_reason_codes rc
	on ol.decision_code = rc.reasonCode
where exists (select number from risk.applications2 ra2 where ol.number = ra2.number)
and cast(ol.call_date as date) >= @rdt
;
-------------------свод
drop table if exists #total;
select
rapp.Number
,rapp.date
,case 
	when datepart(hh,rapp.C1_date) = 0 and datepart(n, rapp.C1_date) = 0 and datepart(ss, rapp.C1_date) = 0 then 24 
	else datepart(hh,rapp.C1_date) 
	end [Часы]
,rapp.date_issue
,case
	when rapp.productTypeCode is null and rapp.Is_installment != 1 then 'pts'
	when rapp.productTypeCode is null and rapp.Is_installment = 1 then 'unsecured'
	when rapp.productTypeCode = 'installment' then 'unsecured'
	when rapp.productTypeCode = 'pdl' then 'unsecured'
	else rapp.productTypeCode
	end productTypeCode
,rapp.request_amount
,rapp.LIMIT
,rapp.CLIENT_TYPE
,rapp.leadsource
,case when rapp.leadSource in ('infoseti-deepapi-installment', 'infoseti-deepapi-pts') then 'ГПБ'
	when rapp.leadSource in ('psb-deepapi', 'psb-ref') then 'ПСБ'
	when rapp.leadSource in ('vtb-lkd-buyauto', 'vtb-ref') then 'ВТБ'
	when rapp.leadSource = 'tpokupki-deepapi' then 'ТБанк'
	else 'other'
	end leadSource_macro
,rapp.pdn_cmr_bucket
,rapp.pdn_income_bucket
,rapp.rbp_gr
,rapp.C1_decision
,rapp.C12_decision
,rapp.C15_decision
,rapp.C2_decision
,rapp.C3_decision
,rapp.C4_decision
,rapp.C5_decision
,rapp.AR_FIN
,rapp.FIN_STATUS
,rapp.ISSUED_FL
,rapp.EqxScore
,rapp.pd
,rapp.SB_Cash_25
,rapp.car_market_price
,rapp._15_4_CMR
,rapp._30_4_CMR
,rapp._90_12_CMR
,rapp._90_6_CMR
,rapp.fpd0
,rapp.fpd30
,rapp.fpd7

,semp.selectedOffer

,checks.verif_type

,case when bki.productTypeCode = 'pts' then coalesce(bki.needBki, 1) else null end needBki

,cars.name_brand
,cars.year_ts

,bki.needPTS

,rapp.productTypeCode as productTypeCode_orig

,credits.credit_type as product_issue
into #total 
from risk.applications2 rapp
left join #semp semp
	on rapp.number = semp.number
left join #checks checks
	on rapp.number = checks.number
	and checks.rn = 1
left join #bki bki
	on rapp.number = bki.number
	and bki.rn = 1
left join #cars cars
	on cars.number = rapp.number
	and cars.rn = 1
left join risk.credits credits
	on credits.external_id = rapp.number
where rapp.date >= @rdt
;

-------------------внесение данных
if OBJECT_ID('risk.portfolio_report_data') is null
begin
	select top(0) * into risk.portfolio_report_data
	from #total
end;

if OBJECT_ID('risk.portfolio_report_calls') is null
begin
	select top(0) number
	,call_date
	,stage
	,decision
	,[Classification level 1]
	,[Classification level 2] into risk.portfolio_report_calls
	from #calls
end;

BEGIN TRANSACTION
	delete from risk.portfolio_report_data
	insert into risk.portfolio_report_data
	select * from #total;
	
	delete from risk.portfolio_report_calls
	insert into risk.portfolio_report_calls
	select
	number
	,call_date
	,stage
	,decision
	,[Classification level 1]
	,[Classification level 2]
	from #calls
	where rn = 1;
COMMIT TRANSACTION;

drop table if exists #bki;
drop table if exists #semp;
drop table if exists #checks;
drop table if exists #cars;
drop table if exists #total;
drop table if exists #calls;

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