
CREATE  procedure  [etl].[dwh_etl_loans_writeoff_debt_reversal_campaign_cmr]

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
		,[Регистратор_Ссылка]
		,[ВидДвижения]
		--,case when [ВидДвижения] = 0 then 'Приход' when [ВидДвижения] = 1 then 'Расход' end as [Приход_Расход]
		,sum([ОДНачисленоУплачено]) [ОДСписание]
		,sum([ПроцентыНачисленоУплачено]) [ПроцентыСписание]
		,sum([ПениНачисленоУплачено]) [ПениСписание]
		,sum([ГосПошлина]) [ГосПошлинаСписание]

		,[ХозяйственнаяОперация]

into #t
from Stg.[_1cCMR].[РегистрНакопления_РасчетыПоЗаймам] with (nolock) 
where [ВидДвижения] = 1 
	  and  [ХозяйственнаяОперация] = 0xB81200155D4D085911E944418439AF38 /*Это сторно по акции*/
	  and ([ОДНачисленоУплачено]>0 or [ПроцентыНачисленоУплачено]>0 or [ПениНачисленоУплачено]>0 or [ГосПошлина]>0)
	  --and [Период] >= @DateStart2000
group by [Период] ,[Договор] ,[Регистратор_Ссылка] ,[ВидДвижения] ,[ХозяйственнаяОперация]



drop table if exists #t00
select distinct 
      [ContractStartDate]
      ,[external_id]

      ,[ContractEndDate]
into #t00 -- select *
from [Reports].[dbo].[dm_CMRStatBalance_2] c
  where not [ContractEndDate] is null 

drop table if exists #t12
select [Период]
      ,[Регистратор_ТипСсылки]
      ,[Регистратор_Ссылка]
      ,[НомерСтроки]
      ,[Активность]
      ,[ВидДвижения]
      ,[Договор]
      ,[Акция]
      ,[Удалить_ДатаНачала]
      ,[Удалить_ДатаОкончания]
      ,[Активна]
into #t12
from Stg.[_1cCMR].[РегистрНакопления_АктивныеАкции]

drop table if exists #t4 
select --r.*
		cast(dateadd(year ,-2000 ,cast(r.[Период] as datetime2)) as date) [Период] 
		--,r.[Регистратор_Ссылка]
		--,r.[ВидДвижения]
		--,case when r.[ВидДвижения] = 0 then 'Приход' when r.[ВидДвижения] = 1 then 'Расход' end as [Приход_Расход]
		,d.[Код] external_id 
		--,r.[Договор]
		,[ОДСписание]
		,[ПроцентыСписание]
		,[ПениСписание]
		,[ГосПошлинаСписание]

		--,r.[ХозяйственнаяОперация]
		,h.[Наименование] [НаимХозОперации]

into #t4
from #t r
left join [Stg].[_1cCMR].[Справочник_ТипыХозяйственныхОпераций] h on h.[Ссылка]=r.[ХозяйственнаяОперация]
left join [Stg].[_1cCMR].[Справочник_Договоры] d on d.[Ссылка]=r.[Договор]
where h.[Наименование] = 'Сторно по акции' and r.[ВидДвижения] = 1



---- drop table [dwh_new].[dbo].[loans_writeoff_reversal_campaign_cmr]
delete from [dwh_new].[dbo].[loans_writeoff_reversal_campaign_cmr] --where dt_lastpayment >= @DateStart
insert into [dwh_new].[dbo].[loans_writeoff_reversal_campaign_cmr]   /*Списание по хоз.операции сторно по акции*/

	select *
	--into [dwh_new].[dbo].[loans_writeoff_reversal_campaign_cmr]   
	from #t4 
	--where [Период] >= @DateStart
	order by 4 desc ,6 asc

-- select * from [dwh_new].[dbo].[loans_writeoff_reversal_campaign_cmr]  


end
