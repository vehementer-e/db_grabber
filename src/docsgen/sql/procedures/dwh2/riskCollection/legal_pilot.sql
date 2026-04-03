CREATE procedure [riskCollection].[legal_pilot] as 
begin

BEGIN TRY

---------------------------------------судебные данне
drop table if exists #court;
SELECT 
jdm.external_id
,deals.Date as startdate
,case 
	when deals.Date <'2022-11-01' and jdm.product = 'Installment' then 'OLD-Installment' 
	when deals.Date >= '2022-11-01' and jdm.product = 'Installment' then 'NEW-Installment' 
	else jdm.product 
	end Prod_Type

,jdm.[Дата отправки требования]
,jdm.[Дата отправки иска в суд]
,jdm.[Дата судебного решения]
,jdm.[ИЛ дата получения Carmoney]
,jdm.[Дата получения решения суд]
,jdm.[Дата принятия к производству]
,jdm.[ИП дата возбуждения]
,ROW_NUMBER() over (partition by jdm.external_id order by jdm.[ИП дата возбуждения] desc) rn

,cdm.[остаток од]
,cdm.[остаток %]

into #court
FROM riskCollection.collection_judicial_datamart jdm 
left join stg._Collection.deals deals
	on deals.number = jdm.external_id
left join riskCollection.collection_datamart cdm
	on jdm.external_id = cdm.external_id 
	and cdm.d = jdm.[Дата отправки иска в суд]
where deals.Date >= '2020-01-01'
;
---------------------------------------данные по платежам + распределение платежей по mob
drop table if exists #pays;
select 
court.*
,cdm.d
,cdm.pay_total

,case 
	when cdm.d between court.[Дата отправки требования] and cast(coalesce(court.[ИЛ дата получения Carmoney],'9999-01-01') as date) 
	then pay_total 
	else 0
	end cash_before_IL
,case 
	when cdm.d > cast(coalesce(court.[ИЛ дата получения Carmoney],'9999-01-01') as date) 
	then pay_total
	else 0 
	end cash_after_IL
,case 
	when datediff(dd,court.[Дата отправки иска в суд], cdm.d)/30+1 > 47 then 48 --все, что после 47, это 48
	else datediff(dd,court.[Дата отправки иска в суд], cdm.d)/30+1 --делим на 30, чтоб получить месяц, добавляем 1, чтобы был 1-й месяц, 2-й месяц и т.д.
	end mob1

into #pays
from #court court
left join riskCollection.collection_datamart cdm 
	on cdm.external_id = court.external_id 	
	and cdm.pay_total > 0
	and cdm.d >= cast(coalesce(court.[Дата отправки иска в суд],'9999-01-01') as date)
where court.rn = 1 
;
---------------------------------------группировка платежей с расделением на cash before_IL и after_IL
drop table if exists #db1;
select 
external_id
,startdate
,Prod_Type
,[Дата отправки требования]
,[Дата отправки иска в суд]
,[Дата судебного решения]
,[ИЛ дата получения Carmoney]
,[Дата получения решения суд]
,[Дата принятия к производству]
,[ИП дата возбуждения]
,[остаток од]
,[остаток %]

,sum(pays.pay_total) as pay_total
,sum(pays.cash_before_IL) as cash_before_IL
,sum(pays.cash_after_IL) as cash_after_IL

INTO #db1
from #pays pays
group by 
external_id
,startdate
,Prod_Type
,[Дата отправки требования]
,[Дата отправки иска в суд]
,[Дата судебного решения]
,[ИЛ дата получения Carmoney]
,[Дата получения решения суд]
,[Дата принятия к производству]
,[ИП дата возбуждения]
,[остаток од]
,[остаток %]
;
---------------------------------------внесение
BEGIN TRANSACTION

truncate table riskcollection.legal_pilot_db1;
if OBJECT_ID('riskcollection.legal_pilot_db1') is null
begin
	select top(0) * into riskcollection.legal_pilot_db1
	from #db1
end;
insert into riskcollection.legal_pilot_db1
select * from #db1;


truncate table riskcollection.legal_pilot_db2;
if OBJECT_ID('riskcollection.legal_pilot_db2') is null
begin
	select top(0) * into riskcollection.legal_pilot_db2
	from #pays
end;
insert into riskcollection.legal_pilot_db2
select * from #pays;

COMMIT TRANSACTION;

drop table if exists #court;
drop table if exists #pays;
drop table if exists #db1;

END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
	END CATCH
END;