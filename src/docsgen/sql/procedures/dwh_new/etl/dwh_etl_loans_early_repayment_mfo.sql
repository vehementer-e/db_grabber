

-- exec [etl].[dwh_etl_loans_early_repayment_mfo]

CREATE  procedure  [etl].[dwh_etl_loans_early_repayment_mfo]
as
begin

 set nocount on

declare @DateStart datetime,
		@DateStart2000 datetime

set @DateStart		= dateadd(year ,-1 ,dateadd(month,datediff(month,0,Getdate()),0));
set @DateStart2000	= dateadd(year ,2000 ,@DateStart);
 
 
drop table if exists #t
select --* 
		[Период]
		,[Договор]
		,[ХозяйственнаяОперация]
into #t
from Stg.[_1cCMR].[РегистрНакопления_РасчетыПоЗаймам] with (nolock) 
where [ВидДвижения] = 1 and ([ОДНачисленоУплачено] + [ПроцентыНачисленоУплачено] + [ПениНачисленоУплачено])>0
		--and ([ОДНачисленоУплачено]>0 or [ПроцентыНачисленоУплачено]>0 or [ПениНачисленоУплачено]>0 or [ГосПошлина]>0)
	  and [ХозяйственнаяОперация] = 0x80D900155D64100111E78663D3A87B83 /*ДП*/
	  --and [Период] >= @DateStart2000

--select count(distinct [Договор]) from #t where cast([Период] as date) >= '40200201' and cast([Период] as date) <= '40200229'

drop table if exists #t00
select distinct 
      [ContractStartDate]
      ,[external_id]

      ,[ContractEndDate]
into #t00 -- select *
from [Reports].[dbo].[dm_CMRStatBalance_2] c
  where not [ContractEndDate] is null 

--select count(distinct [external_id]) from #t00 where cast([ContractEndDate] as date) >= '20200201' and cast([ContractEndDate] as date) <= '20200229'
/*
drop table if exists #t0
select distinct 
		cast(dateadd(year, -2000, cast(r.[Период] as datetime2)) as date) dt_lastpayment	/* Дата последнего платежа */
		,cast([ContractEndDate] as date) [ContractEndDate]		/* Дата погашенмя */
		,datediff(day,[ContractEndDate] ,dateadd(year, -2000, cast(r.[Период] as datetime2))) dt_diff	/* Разнмца между датой погашенмя и датой последнего платежа */
		,d.[Код] external_id
		,h.[Наименование] [Наим_ХозОперации] 
		,r.[Договор]
		,r.[ХозяйственнаяОперация]
		,cast(dateadd(month, cast(d.[Срок] as int) ,[ContractStartDate]) as date) [ContractEndDate_plan]
		 
into #t0
from #t r
left join [Stg].[_1cCMR].[Справочник_ТипыХозяйственныхОпераций] h on h.[Ссылка]=r.[ХозяйственнаяОперация]
left join [Stg].[_1cCMR].[Справочник_Договоры] d on d.[Ссылка]=r.[Договор]
left join #t00 t on t.[external_id]=d.[Код]
where /*r.[ХозяйственнаяОперация] = 0x80D900155D64100111E78663D3A87B83 -- Операция "ДП" 
		and*/ 
		cast(dateadd(year, -2000, cast(r.[Период] as datetime2)) as date) <= cast([ContractEndDate] as date)
*/

drop table if exists #t0
select *
into #t0
from (
select rr.* 
		,rank() over(partition by external_id order by dt_lastpayment desc) rk
from (
 select distinct
		cast(dateadd(year, -2000, cast(r.[Период] as datetime2)) as date) dt_lastpayment
		,t.[ContractEndDate]
		,datediff(day,[ContractEndDate] ,dateadd(year, -2000, cast(r.[Период] as datetime2))) dt_diff	/* Разнмца между датой погашенмя и датой последнего платежа */
		,t.external_id
		,h.[Наименование] [Наим_ХозОперации]
		,r.[Договор]
		,r.[ХозяйственнаяОперация]
		,cast(dateadd(month, cast(d.[Срок] as int) ,[ContractStartDate]) as date) [ContractEndDate_plan]
 from #t r
 left join [Stg].[_1cCMR].[Справочник_Договоры] d on d.[Ссылка]=r.[Договор]
 left join #t00 t on t.[external_id]=d.[Код]
 left join [Stg].[_1cCMR].[Справочник_ТипыХозяйственныхОпераций] h on h.[Ссылка]=r.[ХозяйственнаяОперация]
) rr
--where cast(rr.[ContractEndDate] as date) >= '20200201' and cast(rr.[ContractEndDate] as date) <= '20200229'
) rrr
where rk=1

-- select * from #t0

---- select count(distinct (external_id)) from #t0 where [ContractEndDate] >= '20200201' and [ContractEndDate] <= '20200229'

---- drop table [dwh_new].[dbo].[loans_early_repayment_mfo] 
-- select * from [Stg].[_1cCMR].[Справочник_Договоры]

-- alter table [dwh_new].[dbo].[loans_early_repayment_mfo] add [ContractEndDate_plan] date null
/*
drop table if exists #test
	select r.*
into #test
	from
	(
	select *
	,rank() over(partition by external_id order by dt_lastpayment desc) rk
	from #t0
	--where [ContractEndDate] >= '20200201' and [ContractEndDate] <= '20200229'
--	order by 4 desc
	) r
	where rk=1 --or rk=2 --dtdiff<>0 --rk<>1--external_id = '17100610580002' --rk<>1--dtdiff<>0
	order by 4 desc ,6 asc

select * from #test where ContractEndDate >= '20200201' and ContractEndDate <= '20200229'
*/

delete from [dwh_new].[dbo].[loans_early_repayment_mfo] --where dt_lastpayment >= @DateStart

insert into [dwh_new].[dbo].[loans_early_repayment_mfo]   

	select r.*
--	into [dwh_new].[dbo].[loans_early_repayment_mfo]   
	from
	(
	select *
	/*,rank() over(partition by external_id order by dt_lastpayment desc) rk */
	from #t0
	) r
	where rk=1 --dtdiff<>0 --rk<>1--external_id = '17100610580002' --rk<>1--dtdiff<>0
	order by 4 desc ,6 asc

-- select * from [dwh_new].[dbo].[loans_early_repayment_mfo] where cast([ContractEndDate] as date) >= '20200201' and cast([ContractEndDate] as date) <= '20200229' order by 1 desc


end
