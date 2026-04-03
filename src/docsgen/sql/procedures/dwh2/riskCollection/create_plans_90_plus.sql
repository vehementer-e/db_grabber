CREATE procedure [riskCollection].[create_plans_90_plus] as
begin

declare @rdt date; 
set @rdt = (
SELECT
case 
	when MONTH(GETDATE()) = 1 then DATEFROMPARTS(YEAR(dateadd(yy,-1,GETDATE())), MONTH(dateadd(mm,-1,GETDATE())), 1)
	else DATEFROMPARTS(YEAR(GETDATE()), MONTH(dateadd(mm,-1,GETDATE())), 1) end rdt);

BEGIN TRY
--------------------------прекращенные обязательства (исключать)
drop table if exists #done;
select external_id, min(strategydate) as strategydate, customerobligations
into #done
from dwh2.dm.Collection_StrategyDataMart
where customerobligations = 'Прекращены'
group by external_id,customerobligations
;
--------------------------завершение процедуры банкротства (исключать)
drop table if exists #done_bunkr;
SELECT 
tt.number as external_id
,cast(ChangeDate as date) as ChangeDate
,field
into #done_bunkr
FROM stg._collection.CustomerBankruptcyHistory h
left join stg._collection.CustomerBankruptcy t
on h.ObjectId = t.id
left join stg._collection.deals tt on t.customerid=tt.IdCustomer
where field = 'Дата завершения процедуры банкротства'
;
--------------------------добавляем разнесение платежей и продукт, а также исключения по банкротству
drop table if exists #raz_pl;
select dm.*
,case when [ClaimantStage] = 'Hard' and dpd_p_coll < 91 and dpd_p_coll >= 0 then '0-90 hard'
	when death_flag = 1 then 'death'
	when BankruptConfirmed = 1 then 'Bankrupt'
	when agent_name is not null then 'Agency'
	when beznadega_status = 'Безнадёжное взыскание подтверждено' 
	and BankruptConfirmed is null 
	and death_flag is null 
	and kk_status is null then 'Безнадёжное взыскание подтверждено'
	else ClaimantStage
end [Разнесение платежей]
,dm.[тип продукта] as [Product_type]
,case when done.CustomerObligations  = 'Прекращены' and done_bunkr.field = 'Дата завершения процедуры банкротства'
	then 1 else 0
	end expell
into #raz_pl
from dwh2.riskCollection.collection_datamart dm
left join #done done
	on dm.external_id = done.external_id
	and done.strategydate <= dm.d
left join #done_bunkr done_bunkr
	on dm.external_id = done_bunkr.external_id
	and done_bunkr.ChangeDate <= dm.d
where (pay_total> 0 or ball_in_p1 > 0)
and d >= @rdt
and kk_status is null
;
--------------------------добавляем разнесение платежей 2 уровня и бакет для планов
drop table if exists #raz_pl2;
select *
,case when [Разнесение платежей] = 'Hard' and flag_IL =  1 then 'ИП'
when [Разнесение платежей] = 'Hard' and flag_IL is null then 'Hard'
when [Разнесение платежей] = 'Безнадёжное взыскание подтверждено' and flag_IL =  1 then 'ИП'
when [Разнесение платежей] = 'Безнадёжное взыскание подтверждено' and flag_IL is null then 'Hard'
when [Разнесение платежей] = 'Bankrupt' then 'Hard'
else ''
end [Разнесение платежей_2lvl]

,case when [dpd_p_coll] < 91  then '(0)_0_90'
when [dpd_p_coll] < 361 then '(5)_91_360'
when [dpd_p_coll] < 1001 then '(6)_361_1000'
when [dpd_p_coll] >= 1001 then '(7)_1000+'
else [bucket_p_coll]
end bucket_plans_91
into #raz_pl2
from #raz_pl
where expell = 0
;
--------------------------балансы входа в разнесения и бакеты
drop table if exists #balls;
select 
d
,[Product_type]
,[Разнесение платежей]
,[Разнесение платежей_2lvl]
,bucket_plans_91
,sum(ball_in_p1) as ball_in_p1
into #balls
from #raz_pl2
where day(d) = 1
group by d
,[Product_type]
,[Разнесение платежей]
,[Разнесение платежей_2lvl]
,bucket_plans_91
;
-------------платежи в разрезе разнесения и бакетов
drop table if exists #pays;
select 
datefromparts(year(d), month(d), 1) as d
,[Product_type]
,[Разнесение платежей]
,[Разнесение платежей_2lvl]
,bucket_plans_91
,sum(pay_total) as pay_total
into #pays
from #raz_pl2
group by datefromparts(year(d), month(d), 1)
,[Product_type]
,[Разнесение платежей]
,[Разнесение платежей_2lvl]
,bucket_plans_91
;
-------------итог
drop table if exists #final;
select 
balls.d
,balls.[Product_type]
,balls.[Разнесение платежей]
,balls.[Разнесение платежей_2lvl]
,balls.bucket_plans_91
,balls.ball_in_p1
,pays.pay_total
into #final
from #balls balls 
left join #pays pays
	on balls.d = pays.d
	and balls.[Разнесение платежей] = pays.[Разнесение платежей]
	and balls.[Разнесение платежей_2lvl] = pays.[Разнесение платежей_2lvl]
	and balls.bucket_plans_91 = pays.bucket_plans_91
	and balls.Product_type = pays.Product_type
where balls.[Разнесение платежей] in 
('0-90 hard',
'Agency',
'Bankrupt',
'death',
'hard',
'Безнадёжное взыскание подтверждено')
;

if OBJECT_ID('riskcollection.plans_90_plus') is null
begin
	select top(0) * into riskcollection.plans_90_plus
	from #final
end;

BEGIN TRANSACTION
	delete from riskcollection.plans_90_plus
	where d >= @rdt

	insert into riskcollection.plans_90_plus
	select * from #final;
COMMIT TRANSACTION;

drop table if exists #done;
drop table if exists #done_bunkr;
drop table if exists #raz_pl;
drop table if exists #raz_pl2;
drop table if exists #balls;
drop table if exists #pays;
drop table if exists #final;

END TRY

begin catch
	if @@TRANCOUNT>0
		rollback TRANSACTION
	END CATCH
END;

--exec riskCollection.create_plans_90_plus
