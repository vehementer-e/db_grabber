CREATE procedure [riskCollection].[create_dialer_results] as 
begin

declare @rdt date; 
set @rdt = (
SELECT
case when day(GETDATE()) > 15 then DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
when day(GETDATE()) <= 15 and MONTH(GETDATE()) = 1 then DATEFROMPARTS(YEAR(dateadd(yy,-1,GETDATE())), MONTH(dateadd(mm,-1,GETDATE())), 1)
else DATEFROMPARTS(YEAR(GETDATE()), MONTH(dateadd(mm,-1,GETDATE())), 1) end rdt);

BEGIN TRY
---------------------------------------все контакты из mv_Communications с RPC, kept, rn (надо удалять дубли)
drop table if exists #cont;
select 
mc.CommunicationDatetime
,mc.CommunicationDate
,mc.id_1
,mc.number as external_id
,mc.PhoneNumber
,case 
	when mc.CommunicationType = 'Исходящий звонок' 
	and mc.CommunicationResult in ('Сообщение прослушано не полностью', 'Сообщение прослушано полностью (проинформирован)')
	then 'IVR'
	else mc.CommunicationType
	end CommunicationType
,mc.CommunicationResult
,mc.persontype
,mc.Контакт
,mc.PromiseSum
,cast(mc.PromiseDate as date) as PromiseDate
,ROW_NUMBER() over (partition by mc.id_1 order by mc.CommunicationDateTime) as rn

,cdm.pay_total
,cdm.d as pay_date

,cdm2.dpd_p_coll
,cdm2.bucket_p_coll
,cdm2.external_stage
,cdm2.[Тип продукта]
,cdm2.[Наименование продукта]
,case when mc.[Контакт] = 'Да' and mc.persontype = 'Клиент' then 1 else 0 end RPC
,case when cdm.[pay_total] >= mc.PromiseSum*0.95 and cdm.[pay_total] > 0 then 1 else 0 end kept --внес не менее 95% от обещанной суммы в сроки обещания

into #cont
from stg._Collection.mv_Communications mc
left join riskCollection.collection_datamart cdm
	on mc.Number = cdm.external_id
	and cdm.d between mc.CommunicationDate and mc.PromiseDate
	and CommunicationResult = 'Обещание оплатить'
	and cdm.pay_total>0
left join riskCollection.collection_datamart cdm2
	on mc.Number = cdm2.external_id
	and mc.CommunicationDate = cdm2.d
where mc.CommunicationDate >=@rdt
;
---------------------------------------Поиск АОНа
drop table if exists #aon;
select 
ROW_NUMBER() over (partition by cast(calldate as date), datepart(hour,calldate),  datepart(minute,calldate) , dst order by id desc) as rn
--Если номера одинаковые, то можно брать любой. Если номера разные, значит сработала функция обхода блокировок, и попыток дозвона больше одной, как и аонов
--поэтому сортируем по номеру записи (id), подразумевая, что попытка с последним АОНом записывается позже
--если в рамках минуты производилось несколько попыток с разных АОН, при этом каждая попытка имеет результат в mv_Communications
--то подтянуть корректно невозможно ввиду разницы времен calldate и CommunicationDatetime
,calldate
,src
,dst
into #aon
from stg._asterisk.cdr
where cast(calldate as date) >=@rdt
and isnumeric(src) = 1
;
---------------------------------------Свод
drop table if exists #total;
select 
cont.CommunicationDatetime
,cont.CommunicationDate
,cont.id_1
,cont.external_id
,cont.PhoneNumber
,cont.CommunicationType
,cont.CommunicationResult
,cont.persontype
,cont.Контакт
,cont.PromiseSum
,cont.PromiseDate
,cont.pay_total
,cont.pay_date
,cont.dpd_p_coll
,cont.bucket_p_coll
,cont.external_stage
,cont.[Тип продукта]
,cont.[Наименование продукта]
,cont.RPC
,cont.kept

,aon.calldate
,aon.src
,aon.dst

,case when cont.phonenumber is not null and cont.CommunicationType = 'Исходящий звонок'
	then ROW_NUMBER() over (partition by cont.CommunicationDate, cont.phonenumber, cont.CommunicationType order by cont.CommunicationDatetime) 
	else 0
	end [Попытка на телефон]
,case when cont.phonenumber is not null and cont.CommunicationType = 'Исходящий звонок'
	then ROW_NUMBER() over (partition by cont.CommunicationDate, cont.external_id, cont.CommunicationType order by cont.CommunicationDatetime) 
	else 0
	end [Попытка на договор]

into #total
from #cont cont
left join #aon aon
	on aon.dst = cont.phonenumber
	and datediff(ss, aon.calldate, cont.CommunicationDatetime) <= 90
	and datediff(ss, aon.calldate, cont.CommunicationDatetime) > 0
	and aon.rn = 1
	and cont.rn = 1
	and cont.CommunicationType = 'Исходящий звонок'
where cont.rn = 1
;
---------------------------------------внесение
if OBJECT_ID('riskcollection.dialer_results') is null
begin
	select top(0) * into riskcollection.dialer_results
	from #total
end;

BEGIN TRANSACTION
	delete from riskcollection.dialer_results
	where CommunicationDate >= @rdt

	insert into riskcollection.dialer_results
	select * from #total;

	delete t from (
	select *, row_number() over (partition by id_1 order by (select null)) as duprunk
	from riskcollection.dialer_results
	) as t
	where duprunk > 1;
COMMIT TRANSACTION;

drop table if exists #cont;
drop table if exists #aon;
drop table if exists #total;


END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
	END CATCH
END;