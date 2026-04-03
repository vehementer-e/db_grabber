CREATE procedure [risk].[create_conversion_report] as
--exec [risk].[create_conversion_report]
begin
declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID);
declare @rdt date = '2025-01-01';

BEGIN TRY
--------------------------------поиск даты заявки. нужно только с 'Call 1' или 'Call 03'
drop table if exists #dates;
select
distinct guid
,first_value(call_date) over(partition by guid order by call_date) as first_call_date
into #dates
from stg._loginom.Originationlog
where stage in ('Call 1', 'Call 03')
and call_date >= @rdt
;
--------------------------------выборка по guid (на Call 03 нет number)
drop table if exists #smpl;
select 
distinct orig.guid
,orig.number
,orig.stage
,orig.call_date
,dates.first_call_date --самая ранняя дата только на 'Call 1' или 'Call 03'
,orig.Decision
,ls.leadsource
,case when orig.stage = 'Call 03' then 0 else doubles.[Дубль] end [Дубль]
,app.RBP_GR
,row_number() over(partition by orig.guid, orig.stage order by call_date) as rn --rn по guid внутри стадии
into #smpl
from stg._loginom.Originationlog orig
left join stg._loginom.application ls
	on orig.guid = ls.guid
	and ls.stage = 'Call 1'
left join Reports.dbo.dm_Factor_Analysis doubles --в этой табличке есть признак дубля заявки
	on orig.number = doubles.Номер
left join risk.applications2 app -- отсюда возьмем уже расчитанный rbp
	on orig.number = app.number
left join #dates dates
	on dates.guid = orig.guid
where orig.call_date between @rdt and cast(getdate() as date)
and orig.DWHInsertedDate < cast(getdate() as date)
and orig.userName = 'service'
;
--------------------------------добавляем next_stage, убираем дубли
drop table if exists #next_stages;
select 
guid
,number
,call_date
,first_call_date
,stage
,lead(stage) over(partition by guid order by call_date) as next_stage
,Decision
,leadsource
,RBP_GR
into #next_stages
from #smpl
where rn = 1
and [Дубль] = 0
;
--------------------------------AR_FIN
drop table if exists #ar;
select 
distinct ns.guid
,case when c4.Decision ='Decline' or c4.Decision is null then 0 else 1 end AR_CALL4
,case when c5.Decision ='Decline' or c5.Decision is null then 0 else 1 end AR_CALL5
,c5.Decision as C5_decision
into #ar
from #next_stages ns
left join #next_stages c4
	on c4.guid = ns.guid
	and c4.stage = 'Call 4'
left join #next_stages c5
	on ns.guid = c5.guid
	and c5.stage = 'Call 5'
;
--------------------------------AutoApprove
--inst
drop table if exists #calc;
select 
distinct number
,[Values] as isAutoApprove
into #calc
from stg._loginom.strategy_calc calc--Вертикальная таблица с расчетами из стратегии
where Names = 'isAutoApprove'
and [Values] = 1
and exists (select number from #smpl where number = calc.number)
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
and exists (select number from #smpl where number = calc_big.number)
and call_date>='2025-12-22 11:44'
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
--------------------------------total со всеми флагами и параметрами
drop table if exists #total;
select
ns.guid
,ns.number
,cast(ns.first_call_date as date) as first_call_date
,ns.stage
,ns.next_stage
,ns.Decision
,ns.leadsource
,ns.RBP_GR
,coalesce(app.productTypeCode, call1.productTypeCode, strategy.productTypeCode, precall.productTypeCode) as productTypeCode
,case when ns.Decision = 'Accept' then 1 else 0 end approve --если одобрили на этапе, то 1
,case when ns.next_stage is null then 0 else 1 end convers --если перешел на другую стадию, то 1
,case when ar.AR_CALL5 = 1 or (ar.AR_CALL4 = 1 and ar.C5_decision is null) then 1 else 0 end AR_FIN 
,case when credits.external_id is not null then 1 else 0 end TU
,case 
	when coalesce(app.productTypeCode, call1.productTypeCode, strategy.productTypeCode, precall.productTypeCode) in ('installment', 'pdl') 
	then coalesce(calc.isAutoApprove, 0)
	when coalesce(app.productTypeCode, call1.productTypeCode, strategy.productTypeCode, precall.productTypeCode) in ('bigInstallment', 'bigInstallmentMarket') 
	then coalesce(calc_big.isFullAutoApprove, 0)
	else 0
	end AutoApprove
into #total
from #next_stages ns
left join #ar ar
	on ns.guid = ar.guid
left join risk.credits credits
	on ns.number = credits.external_id
left join #calc calc
	on ns.number = calc.number
left join #calc_big calc_big
	on ns.number = calc_big.number
--продукты
left join #application app
	on app.number = ns.number
	and app.rn = 1
left join #call1 call1
	on call1.number = ns.number
	and call1.rn = 1
left join #strategy strategy
	on strategy.guid = ns.guid
	and strategy.rn = 1
left join #precall precall
	on precall.guid = ns.guid
	and precall.rn = 1
--
;
--------------------------------удалить тестовые заявки и инстоллменты с call03
delete from #total
where number in ('19061300000088' ,'20101300041806' ,'21011900071506' ,'21011900071507')
;
delete from #total
where productTypeCode = 'installment'
and stage = 'Call 03'
;
--------------------------------внесение данных
if OBJECT_ID('risk.conversion_report') is null
begin
	select top(0) * into risk.conversion_report
	from #total
end;

BEGIN TRANSACTION
	delete from risk.conversion_report
	insert into risk.conversion_report
	select * from #total;
COMMIT TRANSACTION;

drop table if exists #dates;
drop table if exists #biginstm;
drop table if exists #smpl;
drop table if exists #next_stages;
drop table if exists #ar;
drop table if exists #calc;
drop table if exists #calc_big;
drop table if exists #prods;
drop table if exists #prods2;
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