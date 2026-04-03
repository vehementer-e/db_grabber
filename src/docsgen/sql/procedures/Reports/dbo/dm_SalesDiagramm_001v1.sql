-- exec [dbo].[report_dashboard_001v2_CC_body] 
CREATE PROC dbo.dm_SalesDiagramm_001v1
AS
BEGIN
	SET NOCOUNT ON;

	--24.03.2020
	SET DATEFIRST 1;


declare @dtFrom date,
	    @dtTo date,
		@stage nvarchar(255), 
		@Metrika nvarchar(20),
		@Param nvarchar(255),
		@MaxValue int
		--, @PageNo int
		, @WeekFrom int
		, @WeekTo int

--declare @Field

set @WeekFrom=datepart(ww,dateadd(week,-10,getdate()));
set @WeekTo=datepart(ww,getdate());
--set @Metrika = case when @ReportMetrika = N'Объемы' then N'Займы' else @ReportMetrika end;	--N'Займы'	--N'Объемы';	--N'Заявки'; --
set @MaxValue = (select (count(distinct [Номер]) + 100) as [maxValue] from [dbo].[dm_Factor_Analysis_001]
																 where datepart(ww,[ДатаЗаявкиПолная]) between @WeekFrom and @WeekTo 
																		and datepart(yyyy,[ДатаЗаявкиПолная])=datepart(yyyy,getdate())
																		and not [Группа каналов] in (N'Тест')) 


---------------------------------------------
---------------------------------------------
------------- Собираем ЛИДЫ
if object_id('tempdb.dbo.#Leads') is not null drop table #Leads

select l.[Год] ,l.[Неделя] ,sum(l.[КолвоФакт]) as [КолвоФакт] ,l.[Группа каналов] ,N'Лиды' as [Метрика0]
into #Leads 
from (
	--DWH-1567 Оптимизация хранения лидов. Отказ от использования таблицы lcrm_leads_full_channel
	--SELECT datepart(yyyy,[UF_REGISTERED_AT]) as [Год] ,datepart(ww,[UF_REGISTERED_AT]) as [Неделя] ,count(distinct [ID]) as [КолвоФакт] ,[Группа каналов]
	--from [Stg].[dbo].[lcrm_tbl_full_w_chanals2]
	--where datepart(ww,[UF_REGISTERED_AT]) between @WeekFrom and @WeekTo and datepart(yyyy,[UF_REGISTERED_AT])=datepart(yyyy,getdate()) and [Группа каналов]<>N'Тест'
	--group by cast([UF_REGISTERED_AT] as datetime) ,cast([UF_REGISTERED_AT] as time) ,datepart(yyyy,[UF_REGISTERED_AT]) ,datepart(ww,[UF_REGISTERED_AT]) ,[Группа каналов]
	SELECT datepart(yyyy,[UF_REGISTERED_AT]) as [Год] ,datepart(ww,[UF_REGISTERED_AT]) as [Неделя] ,count(distinct [ID]) as [КолвоФакт] ,[Группа каналов]
	from Stg._LCRM.lcrm_leads_full_calculated
	where datepart(ww,[UF_REGISTERED_AT]) between @WeekFrom and @WeekTo and datepart(yyyy,[UF_REGISTERED_AT])=datepart(yyyy,getdate()) and [Группа каналов]<>N'Тест'
	group by cast([UF_REGISTERED_AT] as datetime) ,cast([UF_REGISTERED_AT] as time) ,datepart(yyyy,[UF_REGISTERED_AT]) ,datepart(ww,[UF_REGISTERED_AT]) ,[Группа каналов]
	  ) l
group by l.[Год] ,l.[Неделя] ,l.[Группа каналов]

------------- Собираем  ЗАЯВКИ ЗАЙМЫ ОБЪЕМЫ
if object_id('tempdb.dbo.#SalesDiagramm') is not null drop table #SalesDiagramm

select distinct 
	  [Дата] ,[Время] ,[Номер] ,[LCRM ID]
      
	  --,[Текущий статус] ,[Признак повторности]

	  --,[Канал] ,[Канал-подтип] ,[Канал Итог] 
	  ,[Канал от источника] ,[Группа каналов]

      --,[ПризнакЗаявка] ,[ВидЗаявки]
	  ,[МесяцЗаявки] ,[НеделяЗаявки] ,[Сумма заявки]
	  
	  --,[ПризнакЗайм]
	  ,[ГодВыдачи] ,[МесяцВыдач] ,[НеделяЗайма] ,[Выданная сумма]
	   ,[Заем выдан] ,[Заем аннулирован] ,[Аннулировано]
   --   ,[Способ выдачи]

	  --,[ДИАПАЗОН_КД_ЗаймДней] ,[Диапазон5]
     
   --   ,[Заявка есть в Отчете по лидам] ,[Канал привлечения Отчет по лидам] ,[Канал привлечения строкой Отчет по лидам]
      
   --   ,[ДатаЗаявкиПолная] ,[Дубль] ,[Дубль_ClientGuid] ,[ВидЗаявкиНовый] 

into #SalesDiagramm 
from [dbo].[dm_Factor_Analysis_001]
where datepart(ww,[ДатаЗаявкиПолная]) between @WeekFrom and @WeekTo and datepart(yyyy,[ДатаЗаявкиПолная])=datepart(yyyy,getdate())


------------- Собираем  ПЛАНЫ ЛИДЫ ЗАЯВКИ ЗАЙМЫ ОБЪЕМЫ

if object_id('tempdb.dbo.#SalesPlan') is not null drop table #SalesPlan

select tp.[Год] ,tp.[Неделя] 
	  ,null as [Метрика] --case when @Metrika =	N'Объемы' and tp.[Метрика] = N'Займы' then N'Объемы' else tp.[Метрика] end as [Метрика]
	  ,tp.[Группа] as [Группа каналов] 
	  ,sum(tp.[Колво]) as [КолвоПланRR] 
	  ,sum(isnull(tp.[Сумма],0)) as [СуммаПланRR]
	  ,case when t2_cw.[КолвоПланТек] is null then sum(tp.[Колво]) else t2_cw.[КолвоПланТек] end [КолвоПланТек]
	  ,case when t2_cw.[СуммаПланТек] is null then sum(isnull(tp.[Сумма],0)) else t2_cw.[СуммаПланТек] end [СуммаПланТек]

into #SalesPlan 

from (select datepart(yyyy,[Дата]) as [Год] ,datepart(ww,[Дата]) as [Неделя] 
			,[Группа] ,[Метрика] ,[Колво] ,[Сумма] ,[created]
	  from [Stg].[files].[Sales_DailyPlans] where datepart(ww,[Дата]) between @WeekFrom and @WeekTo --and [Метрика]=@Metrika
	  ) tp
left join (
			select t_cw.[Дата] ,t_cw.[Год] ,t_cw.[Неделя] ,t_cw.[Группа] ,t_cw.[Метрика] ,t_cw.[КолвоПланНакопНед] as [КолвоПланТек] ,t_cw.[СуммаПланНакопНед] as [СуммаПланТек] 
			from (
				  select [Дата] ,datepart(yyyy,[Дата]) as [Год] ,datepart(ww,[Дата]) as [Неделя] 
						,[Группа] ,[Метрика] ,[Колво] ,[Сумма] ,[created]
						,sum([Колво]) over(partition by datepart(ww,[Дата]), [Группа] order by [Дата] asc) as [КолвоПланНакопНед]
						,sum(isnull([Сумма],0)) over(partition by datepart(ww,[Дата]), [Метрика] order by [Дата] asc) as [СуммаПланНакопНед]
				  from [Stg].[files].[Sales_DailyPlans] 
				  where datepart(ww,[Дата]) = @WeekTo and [Дата] <= getdate() --and [Метрика]=@Metrika
				--order by [Дата] desc ,[Группа] 
				)t_cw
			where cast(t_cw.[Дата] as date) = cast (getdate() as date)
		  ) t2_cw
on tp.[Год]=t2_cw.[Год] and tp.[Неделя]=t2_cw.[Неделя] and tp.[Метрика]=t2_cw.[Метрика] and tp.[Группа]=t2_cw.[Группа]
group by tp.[Год] ,tp.[Неделя] ,tp.[Метрика] ,tp.[Группа] ,t2_cw.[КолвоПланТек] ,t2_cw.[СуммаПланТек]


------------- ЗДЕСЬ ОПРЕДЕЛЯЕМ МАКСИМУМ НА НЕДЕЛЕ
if object_id('tempdb.dbo.#MinMAx') is not null drop table #MinMAx

select [Метрика] ,[Неделя]
	  ,min(s.[КолвоПланRR]) as [КолвоПланRR_Мин]
	  ,max(s.[КолвоПланRR]) as [КолвоПланRR_Макс]  
	  ,min(s.[СуммаПланRR]) as [СуммаПланRR_Мин]
	  ,max(s.[СуммаПланRR]) as [СуммаПланRR_Макс]
	  --,case when t2_cw.[КолвоПланТек] is null then sum(tp.[Колво]) else t2_cw.[КолвоПланТек] end [КолвоПланТек]
	  --,case when t2_cw.[СуммаПланТек] is null then sum(isnull(tp.[Сумма],0)) else t2_cw.[СуммаПланТек] end [СуммаПланТек]

into #MinMAx 

from (select sum([КолвоПланRR]) as [КолвоПланRR] ,sum([СуммаПланRR]) as [СуммаПланRR] ,[Метрика] ,[Неделя] from #SalesPlan group by [Метрика] ,[Неделя])  s
group by [Метрика] ,[Неделя]

--------------------------------------------
--------------------------------------------


--drop table dbo.dm_dashboard_CallCentr_actual;
--select * into dbo.dm_dashboard_CallCentr_actual from #tt where [ТекВремя] = (select max([ТекВремя]) from #tt)
    /*

begin tran

  truncate table dbo.dm_Verification_001_actual
  insert into dbo.dm_Verification_001_actual
    select * from #tt0 -- where [ТекВремя] = (select max([ТекВремя]) from #tt)

commit tran
	
	--drop table dbo.dm_dashboard_CallCentr_actual
	--select * into dbo.dm_dashboard_CallCentr_actual from #tt

--select distinct * from dbo.dm_dashboard_CallCentr_actual
*/
END
