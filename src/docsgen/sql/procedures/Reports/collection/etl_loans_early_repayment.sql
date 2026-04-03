

-- exec [etl].[dwh_etl_loans_early_repayment_mfo]
													
create    procedure  collection.[etl_loans_early_repayment]
as
begin
 begin try
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
where [ВидДвижения] = 1 
	and ([ОДНачисленоУплачено] + [ПроцентыНачисленоУплачено] + [ПениНачисленоУплачено])>0
		--and ([ОДНачисленоУплачено]>0 or [ПроцентыНачисленоУплачено]>0 or [ПениНачисленоУплачено]>0 or [ГосПошлина]>0)
	  and [ХозяйственнаяОперация] = 0x80D900155D64100111E78663D3A87B83 /*ДП*/
	  --and [Период] >= @DateStart2000


drop table if exists #t00
select distinct 
      [ContractStartDate]
      ,[external_id]
      ,[ContractEndDate]
into #t00 -- select *
from dwh2.dbo.[dm_CMRStatBalance] c
  where not [ContractEndDate] is null 


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
begin tran
truncate table collection.[loans_early_repayment] --where dt_lastpayment >= @DateStart

insert into collection.[loans_early_repayment]   
(	 [dt_lastpayment]
	, [ContractEndDate]
	, [dt_diff]
	, [external_id]
	, [Наим_ХозОперации]
	, [Договор]
	, [ХозяйственнаяОперация]
	, [ContractEndDate_plan]
)

	select
		  r.[dt_lastpayment]
		, r.[ContractEndDate]
		, r.[dt_diff]
		, r.[external_id]
		, r.[Наим_ХозОперации]
		, r.[Договор]
		, r.[ХозяйственнаяОперация]
		, r.[ContractEndDate_plan]
		
		from #t0 r
	where rk=1 --dtdiff<>0 --rk<>1--external_id = '17100610580002' --rk<>1--dtdiff<>0
	order by 4 desc ,6 asc

	commit tran
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch

end
