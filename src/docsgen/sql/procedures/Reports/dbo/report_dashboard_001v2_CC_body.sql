-- exec [dbo].[report_dashboard_001v2_CC_body] 
CREATE  PROCEDURE  [dbo].[report_dashboard_001v2_CC_body] 
AS
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for procedure here

 --   select * from   [Stg].[files].[CC_DailyPlans] 

if object_id('tempdb.dbo.#tt') is not null drop table #tt

declare @GetDate2000 datetime

set @GetDate2000=dateadd(year,2000,getdate());


-----------------
drop table if exists #table_plan2

select p.[ПериодУчетаМес] ,p.[ПериодУчетаДн] ,p.[ДатаПлан] ,p.[СуммаПлан] ,p.[СуммаПлан] as [Пл_СуммаНакопительноДн]
		,sum(p.[СуммаПлан]) over (partition by dateadd(day,datediff(day,0,p.[ПериодУчетаМес]),0)
									order by p.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Пл_СуммаНакопительноМес]
		,/*case when cast(p.[ПериодУчетаМес] as date)='2019-11-01' then 422000000 else */ 
		sum(p.[СуммаПлан]) over (partition by dateadd(day,datediff(day,0,p.[ПериодУчетаМес]),0)) /*end*/ as [Пл_СуммаМес]
		,/*case 
			when cast(p.[ПериодУчетаМес] as date)='2019-11-01' then 24470852
			else */
			sum(p.[План КП]) over (partition by dateadd(day,datediff(day,0,p.[ПериодУчетаМес]),0)
									order by p.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) /*end*/ as [Пл_ПланКПМес]

into #table_plan2

from (select dateadd(month,datediff(month,0,[Дата]),0) as [ПериодУчетаМес] 
			,dateadd(day,datediff(day,0,[Дата]),0) as [ПериодУчетаДн]
			,[Дата] as [ДатаПлан]
			,[Займы руб] as [СуммаПлан]
			,isnull([План КП],0) as [План КП]
	  from [Stg].[files].[CC_DailyPlans] ) p --with (nolock) 
where p.[ДатаПлан]>=dateadd(day,datediff(day,0,dateadd(month,-2,Getdate())),0)




-----------------
drop table if exists #aux_LoanCRM_1c

SELECT cast(dateadd(year,-2000,t1.[Период]) as datetime) as [Период]
	  ,t3.[ДатаВыдачи] as [ДатаВыдачи]      
	  ,t1.[Заявка]
	  ,t3.[Номер] as [ЗаявкаНомер]

	  ,t3.[Сумма] as [СуммаВыданная]
      ,t1.[Статус]
	  ,t2.[Наименование] as [СтатусНаим]

into #aux_LoanCRM_1c

from (select max([Период]) as [Период] ,[Заявка] ,[Статус] 
	  from [Stg].[_1cCRM].[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС] with (nolock)
	  where [Статус]=0xA81400155D94190011E80784923C6097  -- статус заем выдан
			and not [Заявка] in (select [Заявка] 
								 from [Stg].[_1cCRM].[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС] with  (nolock)
								 where [Статус]=0xA81400155D94190011E80784923C6096 --заем аннулирован
								 )
	  group by [Заявка] ,[Статус]
	 ) t1
 left join [Stg].[_1cCRM].[Справочник_СтатусыЗаявокПодЗалогПТС] t2  with   (nolock)
	on t1.[Статус]=t2.[Ссылка]
left join [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] t3  with (nolock)
	on t1.[Заявка]=t3.[Ссылка]
--left join [Stg].[dbo].[Agreement_InterestRate] t4
--on t3.[ЗаявкаНомер]=t4.[ДоговорНомер] 
where t1.[Период] >= dateadd(MONTH,datediff(MONTH,0,@GetDate2000),0) and t3.[ДатаВыдачи] < dateadd(day,datediff(day,0,@GetDate2000),0)
	
--select * from aux_LoanCRM_1c order by [ДатаВыдачи] desc



-----------------
drop table if exists #aux_AgrIntRate

select [ДоговорНомер] ,[ДатаВыдачиПолн] as [ДатаВыдачи] ,[СуммаВыдачи] ,[КолвоЗаймов]
	  ,isnull([СтавкаНаСумму],0) as [СтавкаНаСумму] ,isnull([СуммаДопУслуг],0) as [СуммаДопУслуг]
      ,isnull([ПризнакКП],0) as [ПризнакКП] ,isnull([ПризнакСтраховка],0) as [ПризнакСтраховка]

      ,isnull([ПризнакКаско],0) as [ПризнакКаско] ,isnull([ПризнакСтрахованиеЖизни],0) as [ПризнакСтрахованиеЖизни] ,isnull([ПризнакРАТ],0) as [ПризнакРАТ]
	  ,isnull([ПризнакПозитивНастр],0) as [ПризнакПозитивНастр] ,isnull([ПризнакПомощьБизнесу],0) as [ПризнакПомощьБизнесу]

      ,isnull([SumEnsur],0) as [SumEnsur] ,isnull([SumRat],0) as [SumRat] ,isnull([SumKasko],0) as [SumKasko] 
	  ,isnull([SumPositiveMood],0) as SumPositiveMood ,isnull([SumHelpBusiness],0) as SumHelpBusiness

	  ,case when [ДопПродукт_СтатусСписанияСтраховки] in (N'SUCCEEDED',N'Completed')  then isnull([ПризнакКП],0) else 0 end as [ПризнакКП_succ]
	  ,case when [ДопПродукт_СтатусСписанияСтраховки] in (N'SUCCEEDED',N'Completed') then isnull([ПризнакСтраховка],0) else 0 end as [ПризнакСтраховка_succ]

	  ,case when [ДопПродукт_СтатусСписанияСтраховки] in (N'SUCCEEDED',N'Completed') then isnull([ПризнакКаско],0) else 0 end as [ПризнакКаско_succ]
	  ,case when [ДопПродукт_СтатусСписанияСтраховки] in (N'SUCCEEDED',N'Completed') then isnull([ПризнакСтрахованиеЖизни],0) else 0 end as [ПризнакСтрахованиеЖизни_succ]
	  ,case when [ДопПродукт_СтатусСписанияСтраховки] in (N'SUCCEEDED',N'Completed') then isnull([ПризнакРАТ],0) else 0 end as [ПризнакРАТ_succ]
	  ,case when [ДопПродукт_СтатусСписанияСтраховки] in (N'SUCCEEDED',N'Completed') then isnull([ПризнакПозитивНастр],0) else 0 end as [ПризнакПозитивНастр_succ]
	  ,case when [ДопПродукт_СтатусСписанияСтраховки] in (N'SUCCEEDED',N'Completed') then isnull([ПризнакПомощьБизнесу],0) else 0 end as [ПризнакПомощьБизнесу_succ]


	  ,case when [ДопПродукт_СтатусСписанияСтраховки] in (N'SUCCEEDED',N'Completed') then isnull([SumEnsur],0) else 0 end as [SumEnsur_succ]
	  ,case when [ДопПродукт_СтатусСписанияСтраховки] in (N'SUCCEEDED',N'Completed') then isnull([SumRat],0) else 0 end as [SumRat_succ]
	  ,case when [ДопПродукт_СтатусСписанияСтраховки] in (N'SUCCEEDED',N'Completed') then isnull([SumKasko],0) else 0 end as [SumKasko_succ]
	  ,case when [ДопПродукт_СтатусСписанияСтраховки] in (N'SUCCEEDED',N'Completed') then isnull(SumPositiveMood,0) else 0 end as [SumPositiveMood_succ]
	  ,case when [ДопПродукт_СтатусСписанияСтраховки] in (N'SUCCEEDED',N'Completed') then isnull([SumHelpBusiness],0) else 0 end as [SumHelpBusiness_succ]

	  ,case when [ДопПродукт_СтатусСписанияСтраховки] in (N'SUCCEEDED',N'Completed') then [СуммаДопУслуг] else 0 end as [СуммаДопУслугБезАкц]

into #aux_AgrIntRate

from [dbo].[report_Agreement_InterestRate]  with (nolock) --where cast([ДатаВыдачи] as date)='2019-11-01'
--where [ДатаВыдачи] between dateadd(MONTH,datediff(MONTH,0,getdate()),0) and dateadd(day,datediff(day,0,getdate()),0)



-----------------
drop table if exists #aux_Loan_AgrIntRate

select l.[Период] ,l.[ДатаВыдачи] ,l.[Заявка] ,l.[ЗаявкаНомер] ,l.[СуммаВыданная] ,l.[Статус] ,l.[СтатусНаим]

	  ,ar.[ДоговорНомер] ,ar.[ДатаВыдачи] as [ДатаВыдачиД] ,[СуммаВыдачи] ,[КолвоЗаймов]
	  ,[СтавкаНаСумму] ,[СуммаДопУслуг] 
	  
	  --,[ПризнакКП] ,[ПризнакСтраховка]
   --   ,[ПризнакКаско] ,[ПризнакСтрахованиеЖизни] ,[ПризнакРАТ]
   --   ,[SumEnsur] ,[SumRat] ,[SumKasko]

	  ,[ПризнакКП_succ] as [ПризнакКП] ,[ПризнакСтраховка_succ] as [ПризнакСтраховка]
      ,[ПризнакКаско_succ] as [ПризнакКаско] ,[ПризнакСтрахованиеЖизни_succ] as [ПризнакСтрахованиеЖизни] ,[ПризнакРАТ_succ] as [ПризнакРАТ]
	  ,[ПризнакПозитивНастр_succ] as [ПризнакПозитивНастр] ,[ПризнакПомощьБизнесу_succ] as [ПризнакПомощьБизнесу] 

      ,[SumEnsur_succ] as [SumEnsur] ,[SumRat_succ] as [SumRat] ,[SumKasko_succ] as [SumKasko] 
	  ,[SumPositiveMood_succ] as [SumPositiveMood] ,[SumHelpBusiness_succ] as [SumHelpBusiness]

	  ,ar.[СуммаДопУслугБезАкц] 	

into #aux_Loan_AgrIntRate

from #aux_LoanCRM_1c l --order by 1
right join #aux_AgrIntRate ar
on l.[ЗаявкаНомер]=ar.[ДоговорНомер]
where not ar.[ДатаВыдачи] is null and ar.[ДатаВыдачи]<dateadd(day,datediff(day,0,getdate()),0)

--select * from aux_Loan_AgrIntRate


-----------------
drop table if exists #AgrIntRate_Curr		-- таблица не используется

select dateadd(day,datediff(day,0,[ДатаВыдачи]),0) as [ДатаВыдачи] --as [Период] 
	  ,sum([СуммаВыдачи]) as [СуммаВыдачи] ,sum([КолвоЗаймов]) as [КолвоЗаймов]
	  ,sum([СтавкаНаСумму]) as [СтавкаНаСумму] ,sum([СуммаДопУслуг]) as [СуммаДопУслуг] 
	  
	  --,sum([ПризнакКП]) as [ПризнакКП] ,sum([ПризнакСтраховка]) as [ПризнакСтраховка]
   --   ,sum([ПризнакКаско]) as [ПризнакКаско] ,sum([ПризнакСтрахованиеЖизни]) as [ПризнакСтрахованиеЖизни] ,sum([ПризнакРАТ]) as [ПризнакРАТ]
   --   ,sum([SumEnsur]) as [SumEnsur] ,sum([SumRat]) as [SumRat] ,sum([SumKasko]) as [SumKasko]

	  ,sum([ПризнакКП_succ]) as [ПризнакКП] ,sum([ПризнакСтраховка_succ]) as [ПризнакСтраховка]
      ,sum([ПризнакКаско_succ]) as [ПризнакКаско] ,sum([ПризнакСтрахованиеЖизни_succ]) as [ПризнакСтрахованиеЖизни] ,sum([ПризнакРАТ_succ]) as [ПризнакРАТ]
	  ,sum([ПризнакПозитивНастр_succ]) as [ПризнакПозитивНастр] ,sum([ПризнакПомощьБизнесу_succ]) as [ПризнакПомощьБизнесу]

      ,sum([SumEnsur_succ]) as [SumEnsur] ,sum([SumRat_succ]) as [SumRat] ,sum([SumKasko_succ]) as [SumKasko] 
	  ,sum([SumPositiveMood]) as [SumPositiveMood] ,sum([SumHelpBusiness_succ]) as [SumHelpBusiness]


	  ,sum([СуммаДопУслугБезАкц]) as [СуммаДопУслугБезАкц]	

into #AgrIntRate_Curr

from #aux_AgrIntRate
where dateadd(day,datediff(day,0,[ДатаВыдачи]),0) = dateadd(day,datediff(day,0,getdate()),0)
group by dateadd(day,datediff(day,0,[ДатаВыдачи]),0)

--select * from AgrIntRate_Curr


-----------------
drop table if exists #dailyStat_queue		-- таблица не используется

select distinct tt1.[ДатаВыдачи] as [Период] ,tt1.[ДатаВыдачи] ,tt1.[СуммаВыдачи] as [СуммаВыданная]

into #dailyStat_queue 

from (select [DayleStatDatetime] as [ДатаВыдачи], [Sum] as [СуммаВыдачи]
			 ,rank() over(partition by cast([DayleStatDatetime] as date) order by  [DayleStatDatetime] desc) as [rank] 
	  from [Stg].[RMQ].[dwh_dailyStat_queue] with (nolock)
	  where cast([DayleStatDatetime] as date)=cast(getdate() as date) ) tt1
where tt1.[rank]=1 --) f0

/*
,	f0 as
(
select distinct
	  ds.[Период] ,ds.[ДатаВыдачи] ,ds.[СуммаВыданная]
	  
	  ,ac.[СуммаВыдачи] ,ac.[КолвоЗаймов]
	  ,ac.[СтавкаНаСумму] ,ac.[СуммаДопУслуг] ,ac.[ПризнакКП] ,ac.[ПризнакСтраховка]
      ,ac.[ПризнакКаско] ,ac.[ПризнакСтрахованиеЖизни] ,ac.[ПризнакРАТ]
      ,ac.[SumEnsur] ,ac.[SumRat] ,ac.[SumKasko]	
	  ,ac.[СуммаДопУслугБезАкц]
from dailyStat_queue ds		-- order by 1		select *  from dailyStat_queue
left join AgrIntRate_Curr ac
on dateadd(day,datediff(day,0,ds.[Период]),0) = ac.[ДатаВыдачи]
)
*/


-----------------
drop table if exists #f0		

select distinct
	  [ДатаВыдачиПолн] as [Период] ,[ДатаВыдачиПолн] as [ДатаВыдачи] --,[СуммаВыдачи0]
	  ,sum(isnull([СуммаВыдачи],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [СуммаВыданная]
	  
	  ,sum(isnull([СуммаВыдачи],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [СуммаВыдачи] 
	  ,sum(isnull([КолвоЗаймов],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [КолвоЗаймов]

	  ,sum(isnull([СтавкаНаСумму],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [СтавкаНаСумму] 
	  ,sum(isnull([СуммаДопУслуг],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [СуммаДопУслуг] 
	  ,sum(isnull([ПризнакКП],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [ПризнакКП] 
	  ,sum(isnull([ПризнакСтраховка],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [ПризнакСтраховка]
      ,sum(isnull([ПризнакКаско],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [ПризнакКаско] 
	  ,sum(isnull([ПризнакСтрахованиеЖизни],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [ПризнакСтрахованиеЖизни] 
	  ,sum(isnull([ПризнакРАТ],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [ПризнакРАТ]
	  ,sum(isnull([ПризнакПозитивНастр],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [ПризнакПозитивНастр]
	  ,sum(isnull([ПризнакПомощьБизнесу],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [ПризнакПомощьБизнесу]

      ,sum(isnull([SumEnsur],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [SumEnsur] 
	  ,sum(isnull([SumRat],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [SumRat] 
	  ,sum(isnull([SumKasko],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [SumKasko]	
	  ,sum(isnull([SumPositiveMood],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [SumPositiveMood]
	  ,sum(isnull([SumHelpBusiness],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [SumHelpBusiness]	

	  ,sum(isnull([SumEnsur],0)+isnull([SumKasko],0)) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [СуммаДопУслугБезАкц]
	  --,sum(case when [ДопПродукт_СтатусСписанияСтраховки]=N'' then isnull([СуммаДопУслуг],0) else 0 end) over (partition by cast([ДатаВыдачи] as date) order by [ДатаВыдачиПолн]) as [СуммаДопУслугБезАкц]

into #f0

from [dbo].[report_Agreement_InterestRate] ds		-- order by 1
where cast([ДатаВыдачи] as date)=cast(getdate() as date)




-----------------
drop table if exists #table_fact2		

select ff.[ПериодУчетаМес] ,ff.[ПериодУчетаДн] ,ff.[ДатаВыдачи] , ff.[СуммаВыдачи]
	   ,sum(isnull(ff.[СуммаВыдачи],0)) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаДн]),0)
									order by ff.[ДатаВыдачи]
									rows between unbounded preceding
											and current row) as [Ф_СуммаНакопительноДн]
		,sum(isnull(ff.[СуммаВыдачи],0)) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_СуммаНакопительноМес]
		,ff.[КолвоЗаймов]
		,sum(ff.[КолвоЗаймов]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_КолвоЗаймовМес]
		,ff.[СтавкаНаСумму]
		,sum(ff.[СтавкаНаСумму]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_СтавкаНаСуммуМес]
		,ff.[СуммаДопУслуг]
		,sum(ff.[СуммаДопУслуг]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_СуммаДопУслугМес]
		,ff.[ПризнакКП]
		,sum(ff.[ПризнакКП]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_ПризнакКПМес]
		,ff.[ПризнакСтраховка]
		,sum(ff.[ПризнакСтраховка]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_ПризнакСтраховкаМес]
		,ff.[ПризнакКаско]
		,sum(ff.[ПризнакКаско]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_ПризнакКаскоМес]
		,ff.[ПризнакСтрахованиеЖизни]
		,sum(ff.[ПризнакСтрахованиеЖизни]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_ПризнакСтрахованиеЖизниМес]
		,ff.[ПризнакРАТ]
		,sum(ff.[ПризнакРАТ]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_ПризнакРАТМес]
		,ff.[ПризнакПозитивНастр]
		,sum(ff.[ПризнакПозитивНастр]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_ПризнакПозитивНастрМес]
		,ff.[ПризнакПомощьБизнесу]
		,sum(ff.[ПризнакПомощьБизнесу]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_ПризнакПомощьБизнесуМес]	
																					
		----------------------------											
		,ff.[SumEnsur]
		,sum(ff.[SumEnsur]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_SumEnsurМес]
		,ff.[SumRat]
		,sum(ff.[SumRat]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_SumRatМес]
		,ff.[SumKasko]
		,sum(ff.[SumKasko]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_SumKaskoМес]
		,ff.[SumPositiveMood]
		,sum(ff.[SumPositiveMood]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_SumPositiveMoodМес]
		,ff.[SumHelpBusiness]
		,sum(ff.[SumHelpBusiness]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_SumHelpBusinessМес]

		----------------------------
		,ff.[СуммаДопУслугБезАкц]
		,sum(ff.[СуммаДопУслугБезАкц]) over (partition by dateadd(day,datediff(day,0,ff.[ПериодУчетаМес]),0)
									order by ff.[ПериодУчетаДн]
									rows between unbounded preceding
											and current row) as [Ф_СуммаДопУслугБезАкцМес]

into #table_fact2

from (select 
			dateadd(month,datediff(month,0,f.[Период]),0) as [ПериодУчетаМес] 
			,dateadd(day,datediff(day,0,f.[ДатаВыдачи]),0) as [ПериодУчетаДн]
			,f.[ДатаВыдачи]
			,f.[СуммаВыданная] as [СуммаВыдачи]	,f.[КолвоЗаймов] as [КолвоЗаймов]
			,f.[СтавкаНаСумму] ,f.[СуммаДопУслуг]
			,f.[ПризнакКП] ,f.[ПризнакСтраховка]
			,f.[ПризнакКаско] ,f.[ПризнакСтрахованиеЖизни] ,f.[ПризнакРАТ]
			,f.[ПризнакПозитивНастр] ,f.[ПризнакПомощьБизнесу]

			,f.[SumEnsur] ,f.[SumRat] ,f.[SumKasko] 
			,f.[SumPositiveMood] ,f.[SumHelpBusiness] 			

			,f.[СуммаДопУслугБезАкц]
	  from (select dateadd(day,datediff(day,0,[ДатаВыдачиД]),0) as [Период] 
				   ,dateadd(day,datediff(day,0,[ДатаВыдачиД]),0) as [ДатаВыдачи] 
				   ,sum([СуммаВыдачи]) as [СуммаВыданная] ,sum([КолвоЗаймов]) as [КолвоЗаймов]
				   ,sum([СтавкаНаСумму]) as [СтавкаНаСумму] ,sum([СуммаДопУслуг]) as [СуммаДопУслуг]
				   ,sum([ПризнакКП]) as [ПризнакКП] ,sum([ПризнакСтраховка]) as [ПризнакСтраховка]
				   ,sum([ПризнакКаско]) as [ПризнакКаско] ,sum([ПризнакСтрахованиеЖизни]) as [ПризнакСтрахованиеЖизни] ,sum([ПризнакРАТ]) as [ПризнакРАТ]
				   ,sum([ПризнакПозитивНастр]) as [ПризнакПозитивНастр] ,sum([ПризнакПомощьБизнесу]) as [ПризнакПомощьБизнесу]

				   ,sum([SumEnsur]) as [SumEnsur] ,sum([SumRat]) as [SumRat] ,sum([SumKasko]) as [SumKasko] 
				   ,sum([SumPositiveMood]) as [SumPositiveMood] ,sum([SumHelpBusiness]) as [SumHelpBusiness]
				   
				   ,sum([СуммаДопУслугБезАкц]) as [СуммаДопУслугБезАкц]

			from #aux_Loan_AgrIntRate
--			where cast([ДатаВыдачи] as date)>'2019-04-30' and cast([ДатаВыдачи] as date)<'2019-06-21'  
			group by dateadd(day,datediff(day,0,[ДатаВыдачиД]),0) ,dateadd(day,datediff(day,0,[ДатаВыдачиД]),0) --order by dateadd(day,datediff(day,0,[ДатаВыдачиД]),0) desc

			union all

			select distinct [ДатаВыдачи] as [Период] ,[ДатаВыдачи] 
							,[СуммаВыданная] ,[КолвоЗаймов]
							,[СтавкаНаСумму] ,[СуммаДопУслуг]
							,[ПризнакКП] ,[ПризнакСтраховка]
							,[ПризнакКаско] ,[ПризнакСтрахованиеЖизни] ,[ПризнакРАТ] 
							,[ПризнакПозитивНастр] ,[ПризнакПомощьБизнесу]

							,[SumEnsur] ,[SumRat] ,[SumKasko] 
							,[SumPositiveMood] ,[SumHelpBusiness]

							,[СуммаДопУслугБезАкц]	
			from #f0 where [ДатаВыдачи]=(select max([Период]) from #f0)
			) f 
		   where f.[ДатаВыдачи] >= dateadd(MONTH,datediff(MONTH,0,Getdate()),0)

	  ) ff

--select * from table_fact2



-----------------
drop table if exists #dm_dashboard_CallCentr		

select  getdate() as [ТекДата] 
,convert(varchar(5), getdate(), 108) as [ТекВремя]
	   ,case when not f2.[ПериодУчетаМес] is null then f2.[ПериодУчетаМес] else p2.[ПериодУчетаМес] end as [ПериодУчетаМес] 
	   ,case when not f2.[ПериодУчетаДн] is null then f2.[ПериодУчетаДн] else p2.[ПериодУчетаДн] end as [ПериодУчетаДн]
	   ,f2.[ДатаВыдачи] 
	   ,f2.[СуммаВыдачи] ,f2.[Ф_СуммаНакопительноДн]
     ,cast(f2.[Ф_СуммаНакопительноМес] as decimal(38,2)) as [Ф_СуммаНакопительноМес]
	   ,p2.[СуммаПлан] ,p2.[Пл_СуммаНакопительноДн] ,p2.[Пл_СуммаМес] as [Пл_СуммаНакопительноМес] ,p2.[Пл_ПланКПМес]
	   ,f2.[СтавкаНаСумму] ,f2.[Ф_СтавкаНаСуммуМес] ,f2.[Ф_КолвоЗаймовМес] ,f2.[КолвоЗаймов]

	   ,cast(f2.[Ф_ПризнакКПМес] as decimal(38,2)) as  [Ф_ПризнакКПМес]
	   ,cast(f2.[Ф_ПризнакСтраховкаМес] as decimal(38,2)) as  [Ф_ПризнакСтраховкаМес]

	   ,cast((f2.[Ф_ПризнакРАТМес]+f2.[Ф_ПризнакСтрахованиеЖизниМес]+f2.[Ф_ПризнакКаскоМес]+f2.[Ф_ПризнакПозитивНастрМес]+f2.[Ф_ПризнакПомощьБизнесуМес]) as decimal(38,2)) as [Ф_ВсегоКПМес]
	  

	   ,f2.[Ф_ПризнакРАТМес]  
	   
	   ,cast(f2.[ПризнакСтраховка] as decimal(38,2)) as [ПризнакСтраховка] 

	   ,cast(f2.[ПризнакСтрахованиеЖизни] as decimal(38,2)) as [ПризнакСтрахованиеЖизни]  
	   ,cast(f2.[ПризнакКаско] as decimal(38,2)) as  [ПризнакКаско]
	   ,cast(f2.[ПризнакПозитивНастр] as decimal(38,2)) as  [ПризнакПозитивНастр]
	   ,cast(f2.[ПризнакПомощьБизнесу] as decimal(38,2)) as  [ПризнакПомощьБизнесу]

	   ,cast(f2.[Ф_ПризнакСтрахованиеЖизниМес] as decimal(38,2)) as [Ф_ПризнакСтрахованиеЖизниМес]  
	   ,cast(f2.[Ф_ПризнакКаскоМес] as decimal(38,2)) as  [Ф_ПризнакКаскоМес]
	   ,cast(f2.[Ф_ПризнакПозитивНастрМес] as decimal(38,2)) as  [Ф_ПризнакПозитивНастрМес]
	   ,cast(f2.[Ф_ПризнакПомощьБизнесуМес] as decimal(38,2)) as  [Ф_ПризнакПомощьБизнесуМес]

	   ,f2.[Ф_SumRatМес] ,f2.[Ф_SumEnsurМес] ,f2.[Ф_SumKaskoМес] 
	   ,f2.[Ф_SumPositiveMoodМес] ,f2.[Ф_SumHelpBusinessМес]

	   ,cast(f2.[СуммаДопУслугБезАкц] as decimal(38,7)) as [СуммаДопУслугБезАкц]
	   ,cast(f2.[Ф_СуммаДопУслугБезАкцМес] as decimal(38,7)) as  [Ф_СуммаДопУслугБезАкцМес]

into #dm_dashboard_CallCentr

from #table_fact2 f2
right join #table_plan2 p2-- order by [ДатаПлан] desc
on f2.[ПериодУчетаМес]=p2.[ПериодУчетаМес] and f2.[ПериодУчетаДн]=p2.[ПериодУчетаДн]
--order by f2.[ДатаВыдачи] desc


--select * from dm_dashboard_CallCentr order by [ДатаВыдачи] desc
--if object_id('tempdb.dbo.#tt') is not null drop table #tt


-----------------
drop table if exists #tt		

select
	[ТекДата] ,[ТекВремя]
	,cast([Пл_СуммаНакопительноДн] as decimal(16,0)) as [СуммаПланДн]
	,cast([Ф_СуммаНакопительноДн] as decimal(16,0)) as [СуммаФактДн]
	,case when not [Пл_СуммаНакопительноДн] is null then cast((isnull([Ф_СуммаНакопительноДн],0)/isnull([Пл_СуммаНакопительноДн],0) * 100) as decimal(16,2)) else 0 end  as [ПроцВыполнДн]
	,0  as [Встречи] 
	,cast([Ф_СуммаНакопительноМес] as decimal(16,0)) as [СуммаФактМес] 
	,case when not [Пл_СуммаНакопительноМес] is null then cast((isnull([Ф_СуммаНакопительноМес],0)/isnull([Пл_СуммаНакопительноМес],0) * 100) as decimal(16,2)) else 0 end  as [ПроцВыполнМес]
	,cast(isnull([Пл_СуммаНакопительноМес],0)-isnull([Ф_СуммаНакопительноМес],0) as decimal(16,0)) as [ОстДоЦели]
	,[ПериодУчетаДн]
	,[Ф_СтавкаНаСуммуМес]
	,case when not [Ф_СуммаНакопительноМес] is null then cast((isnull([Ф_СтавкаНаСуммуМес],0)/isnull([Ф_СуммаНакопительноМес],0)) as decimal(16,2)) else 0 end  as [СрВзвешСтавкаМес]

	,[Пл_ПланКПМес] as [ПланКПМес]
	,(isnull([Ф_SumRatМес],0)+isnull([Ф_SumEnsurМес],0) + isnull([Ф_SumKaskoМес],0) + isnull([Ф_SumPositiveMoodМес],0) + isnull([Ф_SumHelpBusinessМес],0)) as [СуммаКПМес]
	,case 
		when [Пл_ПланКПМес]=0 then 0 
		else cast(((isnull([Ф_SumRatМес],0)+isnull([Ф_SumEnsurМес],0) + isnull([Ф_SumKaskoМес],0) + isnull([Ф_SumPositiveMoodМес],0) + isnull([Ф_SumHelpBusinessМес],0))/[Пл_ПланКПМес]*100) as decimal(16,2)) 
	end as [ВыполнКППроц]
	,[Ф_КолвоЗаймовМес]

	--,isnull([Ф_ПризнакКПМес],0) as [Ф_ПризнакКПМес]
	--,case 
	--	when not [Ф_КолвоЗаймовМес] is null then cast(((isnull([Ф_ПризнакКаскоМес],0)+isnull([Ф_ПризнакСтрахованиеЖизниМес],0)+isnull([Ф_ПризнакПозитивНастрМес],0))/[Ф_КолвоЗаймовМес]*100) as decimal(16,2)) 
	--	else 0 
	--end as [ДоляПроникнСтрахПроц]

	--,case 
	--	when not [Ф_КолвоЗаймовМес] is null then cast(((isnull([Ф_ПризнакКаскоМес],0)+isnull([Ф_ПризнакСтрахованиеЖизниМес],0)+isnull([Ф_ПризнакПозитивНастрМес],0))/[Ф_КолвоЗаймовМес]*100) as decimal(16,2)) 
	--	else 0 
	--end as [ДоляПроникнСтрахПроц]

	,case 
		when not [Ф_КолвоЗаймовМес] is null then cast((isnull([Ф_ПризнакСтраховкаМес],0)/[Ф_КолвоЗаймовМес]*100) as decimal(16,2))  --ДОБАВИТЬ ПРИЗНАК СТРАХОВКИ
		else 0 
	end as [ДоляПроникнСтрахПроц]

	--,case when not [Ф_КолвоЗаймовМес] is null then cast(([Ф_ПризнакКПМес]/[Ф_КолвоЗаймовМес]*100) as decimal(16,2)) else 0 end as [ДоляПроникнСтрахПроц]
	--,case when not [Ф_КолвоЗаймовМес] is null then cast(([Ф_ВсегоКПМес]/[Ф_КолвоЗаймовМес]*100) as decimal(16,2)) else 0 end as [ДоляПроникнСтрахПроц]

	,isnull([Ф_СуммаДопУслугБезАкцМес],0) as [Ф_СуммаДопУслугБезАкцМес]
	,case when not [Ф_СуммаНакопительноМес] is null then cast(([Ф_СуммаДопУслугБезАкцМес]/[Ф_СуммаНакопительноМес]*100) as decimal(16,2)) else 0 end as [ДоляСтрахПроц]
	--,case when not [Ф_СуммаНакопительноМес] is null then cast(((isnull([Ф_SumEnsurМес],0) + isnull([Ф_SumKaskoМес],0))/[Ф_СуммаНакопительноМес]*100) as decimal(16,2)) else 0 end as [ДоляСтрахПроц]

	,isnull([Ф_ПризнакКПМес],0) as [ВсегоКПМес]		--,[Ф_ВсегоКПМес] as [ВсегоКПМес]

	,isnull([Ф_ПризнакРАТМес],0) as [КолвоРАТ]
	,isnull([Ф_SumRatМес],0) as [СуммаРАТ]
	,isnull([Ф_SumEnsurМес],0) as [СуммаСтрахЖизни]
	,isnull([Ф_SumKaskoМес],0) as [СуммаКаско]
	--,isnull([Ф_SumPositiveMoodМес],0) as [СуммаПозитивНастр]
	,(isnull([Ф_SumEnsurМес],0)+isnull([Ф_SumKaskoМес],0)) as [СуммаНС]
	--,(isnull([Ф_SumEnsurМес],0)+isnull([Ф_SumKaskoМес],0) + isnull([Ф_SumPositiveMoodМес],0)) as [СуммаНС]

	,case 
		when not [КолвоЗаймов] is null then cast((isnull([ПризнакСтраховка],0)/[КолвоЗаймов]*100) as decimal(16,2)) --ДОБАВИТЬ ПРИЗНАК СТРАХОВКИ
		else 0 
	end as [ДоляПроникнСтрахПроцДн]

	--,case 
	--	when not [КолвоЗаймов] is null then cast(((isnull([ПризнакКаско],0)+isnull([ПризнакСтрахованиеЖизни],0)+isnull([ПризнакПозитивНастр],0))/[КолвоЗаймов]*100) as decimal(16,2)) 
	--	else 0 
	--end as [ДоляПроникнСтрахПроцДн]


into #tt
from #dm_dashboard_CallCentr
where [ДатаВыдачи] = (select max([ДатаВыдачи]) as [ДатаВыдачи] from #dm_dashboard_CallCentr) --@DateOfReport--
	  and [ПериодУчетаДн]=dateadd(day,datediff(day,0,getdate()),0)

--select * from #tt
--drop table dbo.dm_dashboard_CallCentr_actual;
--select * into dbo.dm_dashboard_CallCentr_actual from #tt where [ТекВремя] = (select max([ТекВремя]) from #tt)
    /*

    select dateadd(day,datediff(day,0,getdate()),0)

    select datediff(day,0,getdate())
    select dateadd(day,datediff(day,0,getdate()),0)

    */

declare @СуммаВыдачи_tlg int,
		@КолвоЗаймов_tlg int,
		@ПризнакСтраховка_tlg int,

		@СуммаВыдачи_cur int,
		@КолвоЗаймов_cur int,
		@ПризнакСтраховка_cur int

set @СуммаВыдачи_tlg = (select [СуммаВыдачи] from dbo.dm_Telegram where dt = cast(getdate() as date));
set @КолвоЗаймов_tlg = (select [КолвоЗаймов] from dbo.dm_Telegram where dt = cast(getdate() as date));
set @ПризнакСтраховка_tlg = (select [ПризнакСтраховка] from dbo.dm_Telegram where dt = cast(getdate() as date));

set @СуммаВыдачи_cur = (select [СуммаВыдачи] from #dm_dashboard_CallCentr where cast([ПериодУчетаДн] as date) = cast(getdate() as date));
set @КолвоЗаймов_cur = (select [КолвоЗаймов] from #dm_dashboard_CallCentr where cast([ПериодУчетаДн] as date) = cast(getdate() as date));
set @ПризнакСтраховка_cur = (select [ПризнакСтраховка] from #dm_dashboard_CallCentr where cast([ПериодУчетаДн] as date) = cast(getdate() as date));


/*
if exists (select count(*) from #tt where [ТекВремя] = (select max([ТекВремя]) from #tt)) 

begin

	begin tran

		  delete from dbo.dm_dashboard_CallCentr_actual
		  insert into dbo.dm_dashboard_CallCentr_actual
			select * from #tt where [ТекВремя] = (select max([ТекВремя]) from #tt)

	commit tran
		--drop table dbo.dm_dashboard_CallCentr_actual
		--select * into dbo.dm_dashboard_CallCentr_actual from #tt

	--select distinct * from dbo.dm_dashboard_CallCentr_actual
end;
*/

-------- Добавим Бизнес займы
drop table if exists #BusinessLoan_UMFO
select 
	   cast(dateadd(year,-2000,dd.[Дата]) as date) dt
	   ,dd.[НомерДоговора]
	   ,dd.[ФинансовыйПродукт]
	   ,fp.[Наименование] as [КредитныйПродукт]
	   
	   ,dd.[СуммаЗайма]
	   ,dd.[ПроцентнаяСтавка]
	   ,dd.[СрокЗайма]
	   ,(dd.[СуммаЗайма] * dd.[ПроцентнаяСтавка]) [СтавкаНаСумму]

into #BusinessLoan_UMFO
from [Stg].[_1cUMFO].[Документ_АЭ_ЗаймПредоставленный] dd  with (nolock)--y
left join [Stg].[_1cUMFO].[Справочник_АЭ_ФинансовыеПродукты] fp  with (nolock) on dd.[ФинансовыйПродукт]=fp.[Ссылка]
where dd.[ПометкаУдаления]=0x00 AND dd.[Проведен]=0x01 and fp.[Родитель] = 0x810800155D01C00511E86A1E934E0BAE 

------------------
drop table if exists #BusinessLoan;
create table #BusinessLoan (dt date ,[СуммаЗайма] decimal(38,2)  ,[СтавкаНаСумму] decimal(38,2));

if (select count(*) from #BusinessLoan_UMFO) is not null

	begin 
		insert into #BusinessLoan
		select dt ,sum([СуммаЗайма]) [СуммаЗайма] ,sum([СтавкаНаСумму]) [СтавкаНаСумму] from #BusinessLoan_UMFO group by dt order by dt desc 
	end
	else 
		begin
		insert into #BusinessLoan
		select cast(getdate() as date) dt ,0.00 as [СуммаЗайма] ,0.00 as [СтавкаНаСумму]
	end;
-------------------------------------------------------------------------------------------------
--select * from #BusinessLoan

-------- Добавим ЗАЙМЫ P2P
drop table if exists #P2P
select 
	   cast(r.[created_at] as date) dt
	   ,r.[number]

	   ,N'P2P займ' as [КредитныйПродукт]
	   
	   ,r.[sum_contract] as [СуммаЗайма]
	   ,r.[interest_rate] as [ПроцентнаяСтавка]
	   ,r.[loan_period] as [СрокЗайма]
	   ,(r.[sum_contract] * r.[interest_rate]) [СтавкаНаСумму]

into #P2P
from [Stg].[_p2p].[requests] r
left join [Stg].[_p2p].[request_statuses]  s on r.[request_status_guid]=s.[guid]
where r.[request_status_guid] = '81079828-9834-4614-9825-84b646938758'			-- статус заем выдан

------------------
drop table if exists #P2PContract;
create table #P2PContract (dt date ,[СуммаЗайма] decimal(38,2)  ,[СтавкаНаСумму] decimal(38,2));

if (select count(*) from #P2P) is not null

	begin 
		insert into #P2PContract
		select dt ,sum([СуммаЗайма]) [СуммаЗайма] ,sum([СтавкаНаСумму]) [СтавкаНаСумму] from #P2P group by dt order by dt desc 
	end
	else 
		begin
		insert into #P2PContract
		select cast(getdate() as date) dt ,0.00 as [СуммаЗайма] ,0.00 as [СтавкаНаСумму]
	end;
-------------------------------------------------------------------------------------------------
--select * from #P2PContract

--select isnull(@СуммаВыдачи_tlg,0) ,@СуммаВыдачи_cur ,@СуммаВыдачи_tlg 


if (isnull(@СуммаВыдачи_tlg,0) < @СуммаВыдачи_cur and @СуммаВыдачи_cur is not null)
/* --'2020-02-13'
-- тек.Сумма выдач в телеграмме > 0 и текущая сумма выдач в дашборде >0 или суммы равны 
if (isnull(@СуммаВыдачи_tlg,0) >= 0 and @СуммаВыдачи_cur > 0) or (@СуммаВыдачи_tlg = @СуммаВыдачи_cur) and @СуммаВыдачи_cur is not null
*/

begin

	begin tran

		delete from dbo.dm_Telegram where datepart(mm ,dt) = datepart(mm ,getdate())

		insert into dbo.dm_Telegram (dt 
											,[СуммаВыдачи] 
											,[КолвоЗаймов] 
											,[ПризнакСтраховка] 
											,[updated] 
											,[СтавкаНаСумму] 
											,[СуммаДопУслугБезАкц] 
											,[СуммаВыдачи_Бизнес]
											,[СуммаВыдачи_p2p])
						--alter table dbo.dm_Telegram  add [СтавкаНаСумму] decimal(38,2) null ,[СуммаДопУслугБезАкц] decimal(38,2) null
						--alter table dbo.dm_Telegram  add [СуммаВыдачи_p2p] decimal(38,2) null
						--alter table dbo.dm_Telegram  drop column [СтавкаНаСумму]; decimal(38,2) null
		select
			  cast([ПериодУчетаДн] as date) dt
			  ,isnull(d.[СуммаВыдачи] ,0) as [СуммаВыдачи]
			  ,isnull([КолвоЗаймов] ,0) as [КолвоЗаймов]
			  ,isnull([ПризнакСтраховка] ,0) as [ПризнакСтраховка]
			  ,getdate() as [updated]
			  ,isnull(d.[СтавкаНаСумму] ,0) as [СтавкаНаСумму]
			  ,isnull(d.[СуммаДопУслугБезАкц] ,0) as [СуммаДопУслугБезАкц]
			  ,isnull(b.[СуммаЗайма] ,0) as [СуммаВыдачи_Бизнес]
			  ,isnull(p.[СуммаЗайма] ,0) as [СуммаВыдачи_p2p]
		--select *
		from #dm_dashboard_CallCentr d
		left join #BusinessLoan b on cast(d.[ПериодУчетаДн] as date)=b.dt
		left join #P2PContract p on cast(d.[ПериодУчетаДн] as date)=p.dt
		where [ПериодУчетаДн] between dateadd(month ,datediff(month ,0 ,getdate()),0) and getdate()

	commit tran
						
end;




END
