
-- =============================================
-- Author:		Курдин С.В.
-- Create date: 2020-01-30
-- Description:	Создание основной таблицы для отчета для Верификации
-- exec [etl].[base_etl_report_verification]
-- =============================================

CREATE PROCEDURE [etl].[base_etl_report_verification]
	-- Add the parameters for the stored procedure here

AS
BEGIN  --auxtab_RequestMFO_1c

	SET NOCOUNT ON;


declare @GetDate2000 datetime,
		@StartDate date

set @GetDate2000=dateadd(year,2000,getdate());
set @StartDate	= cast(dateadd(month,-2,dateadd(month,datediff(month,0,Getdate()),0)) as date);
    -- Insert statements for procedure here
--select cast(dateadd(month,-1,dateadd(year ,2000 ,dateadd(day,-15,@StartDate))) as date)


if object_id('tempdb.dbo.#fio') is not null drop table #fio
select [Номер] as [ЗаявкаНомер] ,([Фамилия]+' '+[Имя]+' '+[Отчество]) fio  --[ЗаявкаНомер] ,([Фамилия]+' '+[Имя]+' '+[Отчество]) fio
into #fio
from [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] with (nolock) --[dwh_new].[dbo].[mt_requests_loans_mfo]
where cast([Дата] as date) >= cast(dateadd(month,-1,dateadd(year ,2000 ,dateadd(day,-15,@StartDate))) as date)  --[ЗаявкаДатаОперации]>=dateadd(month,-1,getdate())


------------------------------------------------------------
------------------ НОВЫЙ АЛГОРИТМ---------------------------
------------------------------------------------------------

------------------------------------------------------------
drop table if exists #dm_Verification_001_actual_new
select 
	   [ЗаявкаНомер_Исх]
      ,(case when [СтатусНаим_Исх] = 'Отложено рассмотрение' and [СтатусНаим_След]<>'Восстановлено рассмотрение' then 'В работе' else [СостояниеЗаявки] end) as [СостояниеЗаявки]
      ,[СтатусДляСостояния]
      ,[Период_Исх]
      ,[Период_След]
      ,(case when [СтатусНаим_Исх] = 'Отложено рассмотрение' and [СтатусНаим_След]<>'Восстановлено рассмотрение' then 'Восстановлено рассмотрение' else [СтатусНаим_Исх] end) as [СтатусНаим_Исх]
      ,[СтатусНаим_След]
      ,[ИсполнительНаим_Исх]
      ,[ИсполнительНаим_След]
      ,[ВремяЗатрачено]
      ,[ПричинаНаим_Исх]
      ,[ПричинаНаим_След]

into #dm_Verification_001_actual_new
from Reports.[dbo].[dm_Verification_001_actual] with (nolock)
where cast([Период_Исх] as date)>=@StartDate
--select * from Reports.[dbo].[dm_Verification_001_actual] order by 1 desc where [ЗаявкаНомер_Исх]='20012910000056'
--select * from Reports.[dbo].[dm_Verification_001_actual] order by 4 desc



drop table if exists #user_spent_time_status
select 
	   [ЗаявкаНомер_Исх] as [ЗаявкаНомер]
	   ,[ИсполнительНаим_След]
	   ,sum([ВремяЗатрачено]) [ВремяЗатрачено]
	   ,[СтатусДляСостояния]
into #user_spent_time_status
from #dm_Verification_001_actual_new
where [СостояниеЗаявки] = 'В работе'
group by [ЗаявкаНомер_Исх] ,[ИсполнительНаим_След] ,[СтатусДляСостояния]

--select * from #uniq_vdk_spent_time
drop table if exists #user_spent_time_status_details
select 
	   [ЗаявкаНомер_Исх] as [ЗаявкаНомер]
	   ,[ИсполнительНаим_След]
	   ,([ВремяЗатрачено]) [ВремяЗатрачено]
	   ,[СтатусДляСостояния]
into #user_spent_time_status_details
from #dm_Verification_001_actual_new
where [СостояниеЗаявки] = 'В работе'
--group by [ЗаявкаНомер_Исх] ,[ИсполнительНаим_След] ,[СтатусДляСостояния]


drop table if exists #cancelled_in_status_new
select 
		[ЗаявкаНомер_Исх] 
		,[СтатусДляСостояния] 
		,[СтатусНаим_След] 

into #cancelled_in_status_new
from #dm_Verification_001_actual_new
where [СтатусНаим_След]='Заявка аннулирована'
--select * from #cancelled_in_status_new

drop table if exists #cancelled_on_cd_new
select [ЗаявкаНомер_Исх]
into #cancelled_on_cd_new
from #cancelled_in_status_new
where [СтатусДляСостояния] = 'Контроль данных'

drop table if exists #cancelled_on_vdk_new
select [ЗаявкаНомер_Исх]
into #cancelled_on_vdk_new
from #cancelled_in_status_new
where [СтатусДляСостояния] = N'Верификация документов клиента'

drop table if exists #cancelled_on_vd_new
select [ЗаявкаНомер_Исх]
into #cancelled_on_vd_new 
from #cancelled_in_status_new
where [СтатусДляСостояния] = N'Верификация документов'


------------ отложено в текущий момент
drop table if exists #postponed_new
select *
into #postponed_new
from (
		select 
			   [ЗаявкаНомер_Исх] --,[СтатусДляСостояния] ,cast([Период_След] as date) as [dt]
			   ,[СтатусДляСостояния] 
			   ,cast([Период_След] as date) as [dt] 
			   ,[Период_След] 
			   ,[СтатусНаим_След] 
			   ,[ИсполнительНаим_Исх] 
			   ,[ИсполнительНаим_След] 
			   --,[ПричинаНаим_След] 
			   --,[ВремяЗатрачено]
			   ,rank() over(partition by [ЗаявкаНомер_Исх] ,[СтатусДляСостояния] order by [Период_След] desc) as [r]  
		from #dm_Verification_001_actual_new
		--order by [ЗаявкаНомер_Исх] desc , [Период_След] desc
	) r0
where  r0.r=1 and r0.[СтатусНаим_След] in (N'Отложено рассмотрение')


-------------------- Общее количество заявок на статусе

drop table if exists #t0_total_new
select 
	  [ЗаявкаНомер_Исх] --,[СтатусДляСостояния] ,cast([Период_След] as date) as [dt] 
	  ,[СтатусДляСостояния] 
	  ,cast([Период_След] as date) as [dt] 
	  ,[Период_След] 
	  ,[СтатусНаим_Исх] 
	  ,[СтатусНаим_След] 
	  ,[ИсполнительНаим_Исх] 
	  ,[ИсполнительНаим_След] 
	  ,[ПричинаНаим_След] 
	  ,[ВремяЗатрачено]
	    
into #t0_total_new
from #dm_Verification_001_actual_new
where  [СостояниеЗаявки] in (N'В работе') --and  not [СтатусНаим_Исх] in (N'Отложено рассмотрение') --and  not [СтатусНаим_След] in (N'Восстановлено рассмотрение')
order by [ЗаявкаНомер_Исх] desc ,[Период_След] desc


drop table if exists #firsthands_new
select * 
into #firsthands_new
from (
		select
				[ЗаявкаНомер_Исх] 
			   ,[СостояниеЗаявки] 
			   ,[СтатусДляСостояния]
			   ,[Период_Исх]
			   ,[Период_След]
			   ,[СтатусНаим_Исх]
			   ,[СтатусНаим_След]
			   ,rank() over(partition by [ЗаявкаНомер_Исх] ,[СтатусДляСостояния] order by [Период_Исх]) as [r_first]			   
			   ,[ИсполнительНаим_Исх]
			   ,[ИсполнительНаим_След]
			   
			   ,[ПричинаНаим_След]
		from #dm_Verification_001_actual_new
		where [СостояниеЗаявки] = 'В работе'
			  and not [ИсполнительНаим_След] in ('РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ' ,'ИНТЕГРАЦИЯ ИНТЕГРАЦИЯ ИНТЕГРАЦИЯ')
			  --and not [ПричинаНаим_След] in ('Запрос в Логином')
	) t
where [r_first] = 1
order by [ЗаявкаНомер_Исх] desc ,[Период_Исх] desc 

drop table if exists #user_arrivaldate_status
select [ЗаявкаНомер_Исх] ,[СтатусДляСостояния] ,[Период_Исх] ,[ИсполнительНаим_След] 
into #user_arrivaldate_status
from #firsthands_new

-------------------------------------------------------------
-------------------- ИСПОЛНИТЕЛЬ ПРИ СМЕНЕ СТАТУСА (последние руки)
drop table if exists #lasthands_new
select * 
into #lasthands_new
from (
		select
				[ЗаявкаНомер_Исх] 
			   ,[СостояниеЗаявки] 
			   ,[СтатусДляСостояния] 
			   ,cast([Период_След] as date) as [dt] 
			   ,[Период_Исх]
			   ,[Период_След]
			   ,[СтатусНаим_Исх] 
			   ,[СтатусНаим_След]
			   ,[ИсполнительНаим_Исх] 
			   ,[ИсполнительНаим_След] 
			   ,[ПричинаНаим_След] 
			   ,[ВремяЗатрачено] 
			   ,rank() over(partition by [ЗаявкаНомер_Исх] ,[СтатусДляСостояния] order by [Период_След] desc) as [r_last]
		from #dm_Verification_001_actual_new
		where [СостояниеЗаявки] = 'В работе'
			  and not [ИсполнительНаим_След] in ('РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ' ,'ИНТЕГРАЦИЯ ИНТЕГРАЦИЯ ИНТЕГРАЦИЯ')
			  --and not [ПричинаНаим_След] in ('Запрос в Логином')
	) t
where [r_last] = 1
order by [ЗаявкаНомер_Исх] desc ,[Период_Исх] desc 

--select * from #lasthands_new where [ЗаявкаНомер_Исх]='20012910000222'

drop table if exists #unique_lasthands_new
select 
		v.[ЗаявкаНомер_Исх] 
		,v.[СтатусДляСостояния]		
		,v.[ВремяЗатрачено]
		,v.[ИсполнительНаим_След]
		--,[ДатаПриходаНаСтатус] 
		--,f.[fio] as [ФИО клиеентпа]
		,l.[ЗаявкаНомер_Исх] as [ЗаявкаНомер_Исх_ПослРуки]
		--,l.[СтатусДляСостояния] as [СтатусДляСостояния_] 
		,l.[ИсполнительНаим_След] as [ИсполнительНаим_ПослРуки]
		,ld.dt dt
		,l.[Период_След] as [dt_operation] 
into #unique_lasthands_new
from #dm_Verification_001_actual_new v
left join #lasthands_new l on v.[ЗаявкаНомер_Исх]=l.[ЗаявкаНомер_Исх] and v.[СтатусДляСостояния]=l.[СтатусДляСостояния] and v.[ИсполнительНаим_След]=l.[ИсполнительНаим_След] 
left join (select distinct 
				 [ЗаявкаНомер_Исх] 
				 ,[СтатусДляСостояния] 
				 ,cast([Период_След] as date) as dt 
		   from #lasthands_new
		   where not [СтатусНаим_След] in ('Отложено рассмотрение' ,[СтатусДляСостояния])
		   ) ld on v.[ЗаявкаНомер_Исх]=ld.[ЗаявкаНомер_Исх] and v.[СтатусДляСостояния]=ld.[СтатусДляСостояния]
where not l.[ЗаявкаНомер_Исх] is null

--select * from #unique_lasthands_new where [ЗаявкаНомер_Исх]='20012910000222'

drop table if exists #ArrivalOnStatus_new
select distinct
	   [ЗаявкаНомер_Исх] 
	  ,cast([Период_Исх] as date) as [ДатаПриходаНаСтатус] 
	  ,[СтатусНаим_Исх] 
	  ,[СтатусДляСостояния]
into #ArrivalOnStatus_new
from #dm_Verification_001_actual_new tun01 --where [ЗаявкаНомер_Исх]= N'19112510000008'
where [Период_Исх] >= dateadd(MONTH,datediff(MONTH,0,dateadd(month,-1,Getdate())),0) 
		and [СтатусНаим_Исх] in (N'Контроль данных' ,N'Верификация документов клиента',N'Верификация документов')


--------------------------------------------
----------------- Заявки на КД NEW
------------- Общие КД
-----Для КД общее кол-во
drop table if exists #cd_total_new
select --* 
		2 as [НомерТабл]
	   ,N'Общее кол-во заявок на КД' as [Показатель]
	   ,t.[ЗаявкаНомер_Исх] as [ЗаявкаНомер] 
	   ,t.[СтатусДляСостояния]
	   ,t.[dt] --,[Час] 
	   ,t.[ИсполнительНаим_След] 
	   ,t.[ВремяЗатрачено] as [ВремяЗатрачено] --ut.[ВремяЗатрачено] as [ВремяЗатрачено] 
	   ,ar.[ДатаПриходаНаСтатус] 
	   ,f.[fio]
	   ,[Период_След] as [dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]
into #cd_total_new
--select *
from #t0_total_new t
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния]=t.[СтатусДляСостояния]
--left join #user_arrivaldate_status ur on ur.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ur.[СтатусДляСостояния]=t.[СтатусДляСостояния] and ur.[ИсполнительНаим_След]= t.[ИсполнительНаим_След]
left join #user_spent_time_status_details ut on ut.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] and  ut.[СтатусДляСостояния]=t.[СтатусДляСостояния] and ut.[ИсполнительНаим_След]=t.[ИсполнительНаим_След]
left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх]  

where t.[СтатусДляСостояния] in (N'Контроль данных') 
		--and  t.[dt]=cast(getdate() as date)
			and t.[ИсполнительНаим_След] <> N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ' 
				--and not t.[ЗаявкаНомер_Исх] in (select * from #cancelled_on_cd_new) --and t.[СтатусНаим_След]<>'Заявка аннулирована'
					and not t.[ЗаявкаНомер_Исх] in (select numer from Reports.dbo.dm_Verification_001_Exception)
order by t.[ЗаявкаНомер_Исх] desc
--select * from #cd_total_new order by [dt_operation]

--select * from #t0_total_new where [ИсполнительНаим_След] = 'КОЛОСОВА ТАМАРА ВАСИЛЬЕВНА' and dt='2020-02-09' and [СтатусДляСостояния] in (N'Контроль данных')  order by 4

------------- Уникальные КД
drop table if exists #uniq_cd_new
select distinct 
	   2 as [НомерТабл]
	   ,N'Уникальное кол-во заявок на КД' as [Показатель] 
	   ,[ЗаявкаНомер_Исх_ПослРуки] as [ЗаявкаНомер] 
	   ,t.[СтатусДляСостояния] 
	   ,[dt] --,[Час] 
	   ,t.[ИсполнительНаим_След] 
	   ,ut.[ВремяЗатрачено] as [ВремяЗатрачено] --ut.[ВремяЗатрачено] as [ВремяЗатрачено]
	   ,[ДатаПриходаНаСтатус] 
	   ,f.fio
	   ,[dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]

into #uniq_cd_new
from #unique_lasthands_new t 
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния]=t.[СтатусДляСостояния]
left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] 
left join #user_spent_time_status ut on ut.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] and  ut.[СтатусДляСостояния]=t.[СтатусДляСостояния] and ut.[ИсполнительНаим_След]=t.[ИсполнительНаим_След]
--left join #user_arrivaldate_status ur on ur.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ur.[СтатусДляСостояния]=t.[СтатусДляСостояния] and ur.[ИсполнительНаим_След]= t.[ИсполнительНаим_След]

where t.[СтатусДляСостояния]='Контроль данных'
		--and [dt]=cast(getdate() as date) 
			and not [ЗаявкаНомер_Исх_ПослРуки] in (select numer from Reports.dbo.dm_Verification_001_Exception)
				and not t.[ЗаявкаНомер_Исх_ПослРуки] in (select * from #cancelled_on_cd_new)

order by [ЗаявкаНомер_Исх_ПослРуки] desc

--select * from #uniq_cd_new


------------- Одобрено КД
drop table if exists #approve_cd_new
select --*
		2 as [НомерТабл]
		,N'Одобренное кол-во заявок на КД' as [Показатель] 
		,t.[ЗаявкаНомер_Исх] as [ЗаявкаНомер] 
		,t.[СтатусДляСостояния] 
		,cast([Период_След] as date) as [dt] 
		,[ИсполнительНаим_След] 
		,0 as [ВремяЗатрачено] 
		,[ДатаПриходаНаСтатус] 
		,f.[fio]
		,[Период_След] as dt_operation
	    --,[Период_След] as [dt_arrival]

into #approve_cd_new 
from #dm_Verification_001_actual_new t
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния]=t.[СтатусДляСостояния]
left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] 

where t.[СтатусДляСостояния] = N'Контроль данных'
		--and cast([Период_След] as date)=cast(getdate() as date)
			and not t.[ЗаявкаНомер_Исх] in (select numer from Reports.dbo.dm_Verification_001_Exception)
				and [СтатусНаим_След] in (N'Верификация документов клиента') and [ИсполнительНаим_След]<>N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ'
		


order by t.[ЗаявкаНомер_Исх] desc
--select * from #approve_cd_new order by [ЗаявкаНомер] desc


--------------------------------------------
----------------- Заявки на ВДК NEW
------------- Общие ВДК
drop table if exists #vdk_total_new
select --* 
		2 as [НомерТабл]
	   ,N'Общее кол-во заявок на ВДК' as [Показатель]
	   ,t.[ЗаявкаНомер_Исх] as [ЗаявкаНомер] 
	   ,t.[СтатусДляСостояния]
	   ,t.[dt] --,[Час] 
	   ,t.[ИсполнительНаим_След] 
	   ,t.[ВремяЗатрачено] 
	   ,ar.[ДатаПриходаНаСтатус] 
	   ,f.[fio]
	   ,[Период_След] as [dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]

into #vdk_total_new
from #t0_total_new t
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния]=t.[СтатусДляСостояния]
left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] 
 
where t.[СтатусДляСостояния] in (N'Верификация документов клиента') 
		--and  t.[dt]=cast(getdate() as date)
			and t.[ИсполнительНаим_След] <> N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ' 
				and not t.[ЗаявкаНомер_Исх] in (select * from #cancelled_on_vdk_new) --and t.[СтатусНаим_След]<>'Заявка аннулирована'



------------- Уникальные ВДК
drop table if exists #uniq_vdk_new
select distinct 
	   2 as [НомерТабл]
	   ,N'Уникальное кол-во заявок на ВДК' as [Показатель] 
	   ,[ЗаявкаНомер_Исх_ПослРуки] as [ЗаявкаНомер] 
	   ,t.[СтатусДляСостояния] 
	   ,[dt] --,[Час] 
	   ,t.[ИсполнительНаим_След] 
	   ,ut.[ВремяЗатрачено] as [ВремяЗатрачено] --sum([ВремяЗатрачено]) [ВремяЗатрачено]
	   ,[ДатаПриходаНаСтатус] 
	   ,f.fio
	   ,[dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]

into #uniq_vdk_new
from #unique_lasthands_new t 
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния]=t.[СтатусДляСостояния]
left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] 
left join #user_spent_time_status ut on ut.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] and  ut.[СтатусДляСостояния]=t.[СтатусДляСостояния] and ut.[ИсполнительНаим_След]=t.[ИсполнительНаим_След]

where t.[СтатусДляСостояния]='Верификация документов клиента'
		--and [dt]=cast(getdate() as date) 
			and not t.[ЗаявкаНомер_Исх_ПослРуки] in (select * from #cancelled_on_vdk_new) --

order by [ЗаявкаНомер_Исх_ПослРуки] desc
--select * from #uniq_vdk_new


------------- Одобрено ВДК
drop table if exists #approve_vdk_new
select --*
		2 as [НомерТабл]
	    ,N'Одобренное кол-во заявок на ВДК' as [Показатель] 
		,t.[ЗаявкаНомер_Исх] as [ЗаявкаНомер] 
		,t.[СтатусДляСостояния] 
		,cast([Период_След] as date) as [dt] 
		,[ИсполнительНаим_След] 
		,0 as [ВремяЗатрачено] 
		,[ДатаПриходаНаСтатус] 
		,f.[fio]
		,t.[Период_След] as [dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]

into #approve_vdk_new 
from #dm_Verification_001_actual_new t
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния]=t.[СтатусДляСостояния]
left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] 

where t.[СтатусДляСостояния] = N'Верификация документов клиента' and [СтатусНаим_След] in (N'Одобрены документы клиента') and [ИсполнительНаим_След]<>N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ'
		--and cast([Период_След] as date)=cast(getdate() as date) 

order by t.[ЗаявкаНомер_Исх] desc


--------------------------------------------
----------------- Заявки на ВД NEW
------------- Общие ВД
drop table if exists #vd_total_new
select --* 
		2 as [НомерТабл]
	   ,N'Общее кол-во заявок на ВД' as [Показатель]
	   ,t.[ЗаявкаНомер_Исх] as [ЗаявкаНомер] 
	   ,t.[СтатусДляСостояния]
	   ,t.[dt] --,[Час] 
	   ,t.[ИсполнительНаим_След] 
	   ,t.[ВремяЗатрачено] 
	   ,ar.[ДатаПриходаНаСтатус] 
	   ,f.[fio]
	   ,[Период_След] as [dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]

into #vd_total_new
from #t0_total_new t
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния]=t.[СтатусДляСостояния]
left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх]  

where t.[СтатусДляСостояния] in (N'Верификация документов') 
		--and  t.[dt]=cast(getdate() as date)
			and t.[ИсполнительНаим_След] <> N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ' 
				and not t.[ЗаявкаНомер_Исх] in (select * from #cancelled_on_vd_new) --and t.[СтатусНаим_След]<>'Заявка аннулирована'

order by t.[ЗаявкаНомер_Исх] desc


------------- Уникальные ВД
drop table if exists #uniq_vd_new
select distinct 
	   2 as [НомерТабл]
	   ,N'Уникальное кол-во заявок на ВД' as [Показатель] 
	   ,[ЗаявкаНомер_Исх_ПослРуки] as [ЗаявкаНомер] 
	   ,t.[СтатусДляСостояния] 
	   ,[dt] --,[Час] 
	   ,t.[ИсполнительНаим_След] 
	   ,ut.[ВремяЗатрачено] as [ВремяЗатрачено] 
	   ,[ДатаПриходаНаСтатус] 
	   ,f.fio
	   ,[dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]

into #uniq_vd_new 
from #unique_lasthands_new t 
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния]=t.[СтатусДляСостояния]
left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] 
left join #user_spent_time_status ut on ut.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] and  ut.[СтатусДляСостояния]=t.[СтатусДляСостояния] and ut.[ИсполнительНаим_След]=t.[ИсполнительНаим_След]

where t.[СтатусДляСостояния]='Верификация документов' 
		--and[dt]=cast(getdate() as date)
			and not t.[ЗаявкаНомер_Исх_ПослРуки] in (select * from #cancelled_on_vd_new) --
--select * from #uniq_vd_new


------------- Одобрено ВД
drop table if exists #approve_vd_new
select --*
		2 as [НомерТабл]
		,N'Одобренное кол-во заявок на ВД' as [Показатель] 
		,t.[ЗаявкаНомер_Исх] as [ЗаявкаНомер] 
		,t.[СтатусДляСостояния] 
		,cast([Период_След] as date) as [dt] 
		,[ИсполнительНаим_След] 
		,0 as [ВремяЗатрачено] 
		,[ДатаПриходаНаСтатус] 
		,f.[fio]
		,t.[Период_След] as [dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]

into #approve_vd_new 
from #dm_Verification_001_actual_new t
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния]=t.[СтатусДляСостояния]
left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] 
where t.[СтатусДляСостояния] = N'Верификация документов' and [СтатусНаим_След] in (N'Одобрены документы клиента' ,N'Одобрено') and [ИсполнительНаим_След]<>N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ'
		--and cast([Период_След] as date)=cast(getdate() as date) 
 


------------------------------------------------------
------------------------------------------------------
---------------- Вывод в отчет
------------------------------------------------------
------------------------------------------------------

drop table if exists #verification_table
---------- КД
--Общие на КД

select --* 
	  [period]		= dateadd(month,datediff(month,0,dt_operation),0)
      ,[rdate]		= getdate()
      ,[accdate]	= dt
      ,[Indicator]	= 'Кол-во заявок общее (время)'
      ,[Факт/План]	= 'Факт'
      ,[Value]		= [ВремяЗатрачено]

	  ,[Employee]	= [ИсполнительНаим_След]
	  ,[Status]		= [СтатусДляСостояния]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

into #verification_table

from #cd_total_new
--select * from #cd_total_new order by 5 desc
--select * from #res_total_cd



--Уникальные на КД

union all
select --* 
	  [period]		= dateadd(month,datediff(month,0,dt_operation),0)
      ,[rdate]		= getdate()
      ,[accdate]	= dt
      ,[Indicator]	= 'Кол-во заявок уникальное (время)'
      ,[Факт/План]	= 'Факт'
      ,[Value]		= [ВремяЗатрачено]

	  ,[Employee]	= [ИсполнительНаим_След]
	  ,[Status]		= [СтатусДляСостояния]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

from #uniq_cd_new
--select * from #res_uniq_cd

--Оодобрено на КД

union all
select --* 
	  [period]		= dateadd(month,datediff(month,0,dt_operation),0)
      ,[rdate]		= getdate()
      ,[accdate]	= dt
      ,[Indicator]	= 'Кол-во заявок одобрено (время)'
      ,[Факт/План]	= 'Факт'
      ,[Value]		= [ВремяЗатрачено]

	  ,[Employee]	= [ИсполнительНаим_След]
	  ,[Status]		= [СтатусДляСостояния]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

from #approve_cd_new

--select * from #res_appr_cd


---------- ВДК
--Общие на ВДК

union all
select --* 
	  [period]		= dateadd(month,datediff(month,0,dt_operation),0)
      ,[rdate]		= getdate()
      ,[accdate]	= dt
      ,[Indicator]	= 'Кол-во заявок общее (время)'
      ,[Факт/План]	= 'Факт'
      ,[Value]		= [ВремяЗатрачено]

	  ,[Employee]	= [ИсполнительНаим_След]
	  ,[Status]		= [СтатусДляСостояния]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

from #vdk_total_new

--Уникальные на ВДК

union all
select --* 
	  [period]		= dateadd(month,datediff(month,0,dt_operation),0)
      ,[rdate]		= getdate()
      ,[accdate]	= dt
      ,[Indicator]	= 'Кол-во заявок уникальное (время)'
      ,[Факт/План]	= 'Факт'
      ,[Value]		= [ВремяЗатрачено]

	  ,[Employee]	= [ИсполнительНаим_След]
	  ,[Status]		= [СтатусДляСостояния]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

from #uniq_vdk_new

--Оодобрено на ВДК

union all
select --* 
	  [period]		= dateadd(month,datediff(month,0,dt_operation),0)
      ,[rdate]		= getdate()
      ,[accdate]	= dt
      ,[Indicator]	= 'Кол-во заявок одобрено (время)'
      ,[Факт/План]	= 'Факт'
      ,[Value]		= [ВремяЗатрачено]

	  ,[Employee]	= [ИсполнительНаим_След]
	  ,[Status]		= [СтатусДляСостояния]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

from #approve_vdk_new


---------- ВД
--Общие на ВД

union all
select --* 
	  [period]		= dateadd(month,datediff(month,0,dt_operation),0)
      ,[rdate]		= getdate()
      ,[accdate]	= dt
      ,[Indicator]	= 'Кол-во заявок общее (время)'
      ,[Факт/План]	= 'Факт'
      ,[Value]		= [ВремяЗатрачено]

	  ,[Employee]	= [ИсполнительНаим_След]
	  ,[Status]		= [СтатусДляСостояния]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

from #vd_total_new

--Уникальные на ВД

union all
select --* 
	  [period]		= dateadd(month,datediff(month,0,dt_operation),0)
      ,[rdate]		= getdate()
      ,[accdate]	= dt
      ,[Indicator]	= 'Кол-во заявок уникальное (время)'
      ,[Факт/План]	= 'Факт'
      ,[Value]		= [ВремяЗатрачено]

	  ,[Employee]	= [ИсполнительНаим_След]
	  ,[Status]		= [СтатусДляСостояния]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

from #uniq_vd_new

--Оодобрено на ВД

union all
select --* 
	  [period]		= dateadd(month,datediff(month,0,dt_operation),0)
      ,[rdate]		= getdate()
      ,[accdate]	= dt
      ,[Indicator]	= 'Кол-во заявок одобрено (время)'
      ,[Факт/План]	= 'Факт'
      ,[Value]		= [ВремяЗатрачено]

	  ,[Employee]	= [ИсполнительНаим_След]
	  ,[Status]		= [СтатусДляСостояния]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

from #approve_vd_new




--проверим кол-во записей для замены
delete v
from #dm_Verification_001_actual_new v
left join #cancelled_in_status_new c on v.ЗаявкаНомер_Исх=c.ЗаявкаНомер_Исх and v.СтатусДляСостояния=c.СтатусДляСостояния
where not c.ЗаявкаНомер_Исх is null


drop table if exists #Qty_requst_start
select count(distinct [ЗаявкаНомер_Исх]) Qty ,count(distinct cast([Период_След] as date)) Qty_dt ,min([Период_След]) min_dt
into #Qty_requst_start
from #dm_Verification_001_actual_new
where [СостояниеЗаявки] = 'В работе' and not [ИсполнительНаим_След] in ('РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ' ,'ИНТЕГРАЦИЯ ИНТЕГРАЦИЯ ИНТЕГРАЦИЯ')

drop table if exists #Qty_requst_finish
select count(distinct [external_id]) Qty ,count(distinct cast([actiondate] as date)) Qty_dt ,min([actiondate]) min_dt
into #Qty_requst_finish
from #verification_table order by 1

/*
select distinct [ЗаявкаНомер_Исх]
--into #Qty_requst_start
from #dm_Verification_001_actual_new

select distinct [external_id]
--into #Qty_requst_finish
from #verification_table

select * 
from #dm_Verification_001_actual_new
where [ЗаявкаНомер_Исх] in (
'19112910000044'
,'19112810000258'
,'19121710000332'
,'19112910000182'
,'19112910000034'
,'19123010000343'
,'19113010000116'
,'19122510000349'
,'19122110000173'
,'19112710000185'
,'19112910000080'
,'19113010000063'
,'19121710000334'
)
and [СостояниеЗаявки]='В работе'
*/


/*
select vv.*--distinct [ЗаявкаНомер_Исх]
--into #Qty_requst_start
from 
(
delete v
from #dm_Verification_001_actual_new v
left join #cancelled_in_status_new c on v.ЗаявкаНомер_Исх=c.ЗаявкаНомер_Исх and v.СтатусДляСостояния=c.СтатусДляСостояния
where not c.ЗаявкаНомер_Исх is null
) vv

#dm_Verification_001_actual_new v
left join #cancelled_in_status_new c on v.ЗаявкаНомер_Исх=c.ЗаявкаНомер_Исх and v.СтатусДляСостояния=c.СтатусДляСостояния
where not c.ЗаявкаНомер_Исх is null
[СостояниеЗаявки] = 'В работе' 
		and not [ЗаявкаНомер_Исх] in (select distinct [ЗаявкаНомер_Исх] from #dm_Verification_001_actual_new where [СтатусНаим_След]='Заявка аннулирована') 
order by 1

delete v
from #dm_Verification_001_actual_new v
left join #cancelled_in_status_new c on v.ЗаявкаНомер_Исх=c.ЗаявкаНомер_Исх and v.СтатусДляСостояния=c.СтатусДляСостояния
where not c.ЗаявкаНомер_Исх is null

*/


declare @Qty_Day int, @rdate as datetime
set @Qty_Day = (select Qty_dt from #Qty_requst_finish);
set @rdate = (select min_dt from #Qty_requst_finish);

--select * from #Qty_requst_start

--select * from #Qty_requst_finish
 
if (select Qty_dt from #Qty_requst_start) = (select Qty_dt from #Qty_requst_finish) /*and (select min_dt from #Qty_requst_start) = @rdate */ -- закомментировал 04.08.2020

begin 
	begin tran

	delete 
	--select *
	from [dwh_new].[dbo].[mt_report_verification_new] --order by 3 desc 
	 where [accdate]>= @StartDate --  [begindate] >= @StartDate

	insert into [dwh_new].[dbo].[mt_report_verification_new]  ([period]  
																,[rdate]
																,[accdate]
																,[Indicator]
																,[Факт/План]
																,[Value]
																,[Employee]
																,[Status]
																,[external_id]
																,[Section]
																,[actiondate]
																,[begindate]
																,[fio_client])

	select *
	--into [dwh_new].[dbo].[mt_report_verification_new]   
	from #verification_table --order by 11 desc
	where [accdate]>= @StartDate

	commit tran


end

-- select * from #verification_table order by 11 desc
--   select count(*) from [dwh_new].[dbo].[mt_report_verification_new]
--drop table [dwh_new].[dbo].[mt_report_verification_new]
--alter table [dwh_new].[dbo].[mt_report_verification_new] add [fio_client] nvarchar(255) null

END

