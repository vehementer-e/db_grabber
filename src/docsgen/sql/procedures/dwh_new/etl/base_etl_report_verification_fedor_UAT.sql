
-- =============================================
-- Author:		Курдин С.В.
-- Create date: 2020-01-30
-- Description:	Создание основной таблицы для отчета для Верификации из ФЕДОРА
-- exec [etl].[base_etl_report_verification_fedor_UAT]
-- =============================================

CREATE PROCEDURE [etl].[base_etl_report_verification_fedor_UAT]
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
	  and not [Номер] like 'СДRC%'

------------------------------------------------------------
------------------ НОВЫЙ АЛГОРИТМ---------------------------
------------------------------------------------------------

------------------------------------------------------------
drop table if exists #dm_Verification_001_actual_new
select 
	   [ЗаявкаНомер_Исх]

      ,[СтатусДляСостояния_Исх]
      ,[СтатусДляСостояния_След]
	  ,[ЗадачаСтатуса_Исх]
	  ,[ЗадачаСтатуса_След]
      ,[СостояниеЗаявки_Исх]
      ,[СостояниеЗаявки_След]

      ,[Период_Исх]
      ,[Период_След]

      ,[СтатусНаим_Исх]
      ,[СтатусНаим_След]

      ,[ИсполнительНаим_Исх]
      ,[ИсполнительНаим_След]
      ,[ВремяЗатрачено]

      ,[ПричинаНаим_Исх]
      ,[ПричинаНаим_След]
	  ,[Tm]
	  
into #dm_Verification_001_actual_new
from Reports.[dbo].[dm_Verification_fedor_UAT_001_actual] with (nolock)
where cast([Период_Исх] as date)>=@StartDate
--select * from Reports.[dbo].[dm_Verification_fedor_001_actual] where [ЗаявкаНомер_Исх]='20012910000056'
-- select * from #dm_Verification_001_actual_new

drop table if exists #user_spent_time_status
select 
	   [ЗаявкаНомер_Исх] as [ЗаявкаНомер]
	   ,[ИсполнительНаим_След]
	   ,sum([ВремяЗатрачено]) [ВремяЗатрачено]
	   ,[СтатусДляСостояния_Исх]
	   --,sum([Tm]) [Tm]
into #user_spent_time_status
from #dm_Verification_001_actual_new
where [СостояниеЗаявки_Исх] = 'В работе'
group by [ЗаявкаНомер_Исх] ,[ИсполнительНаим_След] ,[СтатусДляСостояния_Исх]

--  select * from #user_spent_time_status


--select * from #uniq_vdk_spent_time
drop table if exists #user_spent_time_status_details
select 
	   [ЗаявкаНомер_Исх] as [ЗаявкаНомер]
	   ,[ИсполнительНаим_След]
	   ,([ВремяЗатрачено]) [ВремяЗатрачено]
	   ,[СтатусДляСостояния_Исх]
into #user_spent_time_status_details
from #dm_Verification_001_actual_new
where [СостояниеЗаявки_Исх] = 'В работе'
--group by [ЗаявкаНомер_Исх] ,[ИсполнительНаим_След] ,[СтатусДляСостояния_Исх]
--  select * from #user_spent_time_status_details

drop table if exists #cancelled_in_status_new
select 
		[ЗаявкаНомер_Исх] 
		,[СтатусДляСостояния_Исх] 
		,[СтатусНаим_След] 

into #cancelled_in_status_new
from #dm_Verification_001_actual_new
where [СтатусДляСостояния_Исх]='Аннулировано'
-- select * from #cancelled_in_status_new

drop table if exists #cancelled_on_cd_new
select [ЗаявкаНомер_Исх]
into #cancelled_on_cd_new
from #cancelled_in_status_new
where [СтатусДляСостояния_Исх] = 'Контроль данных'
-- select * from #cancelled_on_cd_new


drop table if exists #cancelled_on_vdk_new
select [ЗаявкаНомер_Исх]
into #cancelled_on_vdk_new
from #cancelled_in_status_new
where [СтатусДляСостояния_Исх] = N'Верификация клиента'

drop table if exists #cancelled_on_vd_new
select [ЗаявкаНомер_Исх]
into #cancelled_on_vd_new 
from #cancelled_in_status_new
where [СтатусДляСостояния_Исх] = N'Верификация ТС'


------------ отложено в текущий момент
drop table if exists #postponed_new
select *
into #postponed_new
from (
		select 
			   [ЗаявкаНомер_Исх] --,[СтатусДляСостояния_Исх] ,cast([Период_След] as date) as [dt]
			   ,[СтатусДляСостояния_Исх] 
			   ,[Период_Исх]
			   ,cast(getdate() as date) as [dt] 
			   ,getdate() as [Период_След] 
			   ,[СтатусНаим_След] 
			   ,[ИсполнительНаим_Исх] 
			   ,[ИсполнительНаим_След] 
			   --,[ПричинаНаим_След] 
			   --,[ВремяЗатрачено]
			   ,rank() over(partition by [ЗаявкаНомер_Исх] ,[СтатусДляСостояния_Исх] order by [Период_След] desc) as [r]  
		from #dm_Verification_001_actual_new
		where [СостояниеЗаявки_Исх] in (N'Отложена') and [СостояниеЗаявки_След] is null
		--order by [ЗаявкаНомер_Исх] desc , [Период_След] desc
	) r0
where  r0.r=1


-------------------- Общее количество заявок на статусе

drop table if exists #t0_total_new
select 
	  [ЗаявкаНомер_Исх] --,[СтатусДляСостояния_Исх] ,cast([Период_След] as date) as [dt] 

	  ,[СтатусДляСостояния_Исх]
	  ,[СтатусДляСостояния_След]

	  ,[ЗадачаСтатуса_Исх]
	  ,[ЗадачаСтатуса_След]

	  ,[СостояниеЗаявки_Исх]
	  ,[СостояниеЗаявки_След]

	  ,cast([Период_След] as date) as [dt] 
	  ,[Период_След] 
	  ,[СтатусНаим_Исх] 
	  ,[СтатусНаим_След] 
	  ,[ИсполнительНаим_Исх] 
	  ,[ИсполнительНаим_След] 
	  ,[ПричинаНаим_След] 
	  ,[ВремяЗатрачено]
	  ,[Tm]  
into #t0_total_new
from #dm_Verification_001_actual_new
where  [СостояниеЗаявки_Исх] in (N'В работе') 
order by [ЗаявкаНомер_Исх] desc ,[Период_След] desc
-- select * from #t0_total_new where [СтатусДляСостояния_Исх] <> 'Контроль данных'
-- select * from #dm_Verification_001_actual_new where [СтатусДляСостояния_Исх] <> 'Контроль данных'

drop table if exists #firsthands_new
select * 
into #firsthands_new
from (
		select
				[ЗаявкаНомер_Исх] 

			  ,[СтатусДляСостояния_Исх]
			  ,[СтатусДляСостояния_След]

			  ,[ЗадачаСтатуса_Исх]
			  ,[ЗадачаСтатуса_След]

			  ,[СостояниеЗаявки_Исх]
			  ,[СостояниеЗаявки_След]

			   ,[Период_Исх]
			   ,[Период_След]
			   ,[СтатусНаим_Исх]
			   ,[СтатусНаим_След]
			   ,rank() over(partition by [ЗаявкаНомер_Исх] ,[СтатусДляСостояния_Исх] order by [Период_Исх]) as [r_first]			   
			   ,[ИсполнительНаим_Исх]
			   ,[ИсполнительНаим_След]
			   
			   ,[ПричинаНаим_След]
		from #dm_Verification_001_actual_new
		--where --[СостояниеЗаявки_Исх] = 'В работе'
			  --and 
			  --not [ИсполнительНаим_Исх] in ('This is Fedor himself' ,'FEDOR FEDOR FEDOR')
			  --and not [ПричинаНаим_След] in ('Запрос в Логином')
	) t
where [r_first] = 1
order by [ЗаявкаНомер_Исх] desc ,[Период_Исх] desc 


drop table if exists #user_arrivaldate_status
select [ЗаявкаНомер_Исх] ,[СтатусДляСостояния_Исх] ,[Период_Исх] ,[ИсполнительНаим_След] 
into #user_arrivaldate_status
from #firsthands_new
-- select * from #user_arrivaldate_status

-------------------------------------------------------------
-------------------- ИСПОЛНИТЕЛЬ ПРИ СМЕНЕ СТАТУСА (последние руки)
drop table if exists #lasthands_new
select * 
into #lasthands_new
from (
		select
				[ЗаявкаНомер_Исх] 

			  ,[СтатусДляСостояния_Исх]
			  ,[СтатусДляСостояния_След]

			  ,[ЗадачаСтатуса_Исх]
			  ,[ЗадачаСтатуса_След]

			  ,[СостояниеЗаявки_Исх]
			  ,[СостояниеЗаявки_След]

			   ,cast([Период_След] as date) as [dt] 
			   ,[Период_Исх]
			   ,[Период_След]
			   ,[СтатусНаим_Исх] 
			   ,[СтатусНаим_След]
			   ,[ИсполнительНаим_Исх] 
			   ,[ИсполнительНаим_След] 
			   ,[ПричинаНаим_След] 
			   ,[ВремяЗатрачено] 
			   ,rank() over(partition by [ЗаявкаНомер_Исх] ,[СтатусДляСостояния_Исх] order by [Период_След] desc) as [r_last]
		from #dm_Verification_001_actual_new
		--where --[СостояниеЗаявки_Исх] = 'В работе'
		--	  --and 
		--	  not [ИсполнительНаим_След] in ('This is Fedor himself' ,'FEDOR FEDOR FEDOR')
			  --and not [ПричинаНаим_След] in ('Запрос в Логином')
	) t
where [r_last] = 1
order by [ЗаявкаНомер_Исх] desc ,[Период_Исх] desc 

--select * from #lasthands_new where [ЗаявкаНомер_Исх]='20012910000222'

drop table if exists #unique_lasthands_new
select 
		v.[ЗаявкаНомер_Исх] 
		,v.[СтатусДляСостояния_Исх]
		,v.[СтатусДляСостояния_След]

		 ,v.[ЗадачаСтатуса_Исх]
		 ,v.[ЗадачаСтатуса_След]

		 ,v.[СостояниеЗаявки_Исх]
		 ,v.[СостояниеЗаявки_След]		
				
		,v.[ВремяЗатрачено]
		,v.[ИсполнительНаим_След]
		--,[ДатаПриходаНаСтатус] 
		--,f.[fio] as [ФИО клиеентпа]
		,l.[ЗаявкаНомер_Исх] as [ЗаявкаНомер_Исх_ПослРуки]
		--,l.[СтатусДляСостояния_Исх] as [СтатусДляСостояния_] 
		,l.[ИсполнительНаим_След] as [ИсполнительНаим_ПослРуки]
		,ld.dt dt
		,l.[Период_След] as [dt_operation] 
into #unique_lasthands_new
from #dm_Verification_001_actual_new v
left join #lasthands_new l on v.[ЗаявкаНомер_Исх]=l.[ЗаявкаНомер_Исх] and v.[СтатусДляСостояния_Исх]=l.[СтатусДляСостояния_Исх] and v.[ИсполнительНаим_След]=l.[ИсполнительНаим_След] 
left join (select distinct 
				 [ЗаявкаНомер_Исх] 

				  ,[СтатусДляСостояния_Исх]
				  ,[СтатусДляСостояния_След]

				  ,[ЗадачаСтатуса_Исх]
				  ,[ЗадачаСтатуса_След]

				  ,[СостояниеЗаявки_Исх]
				  ,[СостояниеЗаявки_След]

				 ,cast([Период_След] as date) as dt 
			--select  *
		   from #lasthands_new
		   where not [СостояниеЗаявки_Исх] in ('Отложена')  
		   ) ld on v.[ЗаявкаНомер_Исх]=ld.[ЗаявкаНомер_Исх] and v.[СтатусДляСостояния_Исх]=ld.[СтатусДляСостояния_Исх]
where not l.[ЗаявкаНомер_Исх] is null

--select * from #unique_lasthands_new where [ЗаявкаНомер_Исх]='20012910000222'

drop table if exists #ArrivalOnStatus_new
select distinct
	   [ЗаявкаНомер_Исх] 
	  ,cast([Период_Исх] as date) as [ДатаПриходаНаСтатус] 
	  ,[СтатусНаим_Исх] 

	  ,[СтатусДляСостояния_Исх]
	  ,[СтатусДляСостояния_След]

	  ,[ЗадачаСтатуса_Исх]
	  ,[ЗадачаСтатуса_След]

	  ,[СостояниеЗаявки_Исх]
	  ,[СостояниеЗаявки_След]

into #ArrivalOnStatus_new
from #dm_Verification_001_actual_new tun01 --where [ЗаявкаНомер_Исх]= N'19112510000008'
where [Период_Исх] >= dateadd(MONTH,datediff(MONTH,0,dateadd(month,-1,Getdate())),0) 
		and [СтатусДляСостояния_Исх] in (N'Контроль данных' ,N'Верификация клиента',N'Верификация ТС')
--select * from #ArrivalOnStatus_new



--------------------------------------------
----------------- Заявки на КД NEW
------------- Общие КД
-----Для КД общее кол-во
drop table if exists #cd_total_new
select --* 
		2 as [НомерТабл]
	   ,N'Общее кол-во заявок на КД' as [Показатель]
	   ,t.[ЗаявкаНомер_Исх] as [ЗаявкаНомер] 
	   ,t.[СтатусДляСостояния_Исх]
	  ,t.[СтатусДляСостояния_След]

	  ,t.[ЗадачаСтатуса_Исх]
	  ,t.[ЗадачаСтатуса_След]

	  ,t.[СостояниеЗаявки_Исх]
	  ,t.[СостояниеЗаявки_След]

	   ,t.[dt] --,[Час] 
	   ,t.[ИсполнительНаим_След] 
	   ,t.[ВремяЗатрачено] as [ВремяЗатрачено] --ut.[ВремяЗатрачено] as [ВремяЗатрачено] 
	   ,ar.[ДатаПриходаНаСтатус] 
	   ,'' as [fio]--f.[fio]
	   ,[Период_След] as [dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]
into #cd_total_new
--select *
from (select * from #t0_total_new where [СтатусДляСостояния_Исх] in (N'Контроль данных')) t
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния_Исх]=t.[СтатусДляСостояния_Исх]
--left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх]  

--where t.[СтатусДляСостояния_Исх] in (N'Контроль данных') 
--		--and  t.[dt]=cast(getdate() as date)
--			--and t.[ИсполнительНаим_След] <> N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ' 
--				--and not t.[ЗаявкаНомер_Исх] in (select * from #cancelled_on_cd_new) --and t.[СтатусНаим_След]<>'Заявка аннулирована'
--					and 
--					not t.[ЗаявкаНомер_Исх] in (select numer from Reports.dbo.dm_Verification_001_Exception)
order by t.[ЗаявкаНомер_Исх] desc
--select * from #cd_total_new order by [dt_operation]

--select * from #t0_total_new where [ИсполнительНаим_След] = 'КОЛОСОВА ТАМАРА ВАСИЛЬЕВНА' and dt='2020-02-09' and [СтатусДляСостояния_Исх] in (N'Контроль данных')  order by 4

------------- Уникальные КД
drop table if exists #uniq_cd_new
select distinct 
	   2 as [НомерТабл]
	   ,N'Уникальное кол-во заявок на КД' as [Показатель] 
	   ,t.[ЗаявкаНомер_Исх_ПослРуки] as [ЗаявкаНомер] 
	   ,t.[СтатусДляСостояния_Исх]
	  ,t.[СтатусДляСостояния_След]

	  ,t.[ЗадачаСтатуса_Исх]
	  ,t.[ЗадачаСтатуса_След]

	  ,t.[СостояниеЗаявки_Исх]
	  ,t.[СостояниеЗаявки_След]
 
	   ,t.[dt] --,[Час] 
	   ,t.[ИсполнительНаим_След] 
	   ,t.[ВремяЗатрачено] --ut.[ВремяЗатрачено] as [ВремяЗатрачено]
	   ,[ДатаПриходаНаСтатус] 
	   ,'' as [fio]--f.[fio]
	   ,[dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]

into #uniq_cd_new 
from (select * from #unique_lasthands_new where [СтатусДляСостояния_Исх]='Контроль данных') t 
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния_Исх]=t.[СтатусДляСостояния_Исх]
--left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] 
left join #user_spent_time_status ut on ut.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] and  ut.[СтатусДляСостояния_Исх]=t.[СтатусДляСостояния_Исх] and ut.[ИсполнительНаим_След]=t.[ИсполнительНаим_След]

--where t.[СтатусДляСостояния_Исх]='Контроль данных'
		--and [dt]=cast(getdate() as date) 
			--and not [ЗаявкаНомер_Исх_ПослРуки] in (select numer from Reports.dbo.dm_Verification_001_Exception)
			--	and not t.[ЗаявкаНомер_Исх_ПослРуки] in (select * from #cancelled_on_cd_new)

order by t.[ЗаявкаНомер_Исх_ПослРуки] desc

--select * from #uniq_cd_new


------------- Одобрено КД
drop table if exists #approve_cd_new
select --*
		2 as [НомерТабл]
		,N'Одобренное кол-во заявок на КД' as [Показатель] 
		,t.[ЗаявкаНомер_Исх] as [ЗаявкаНомер] 
		,t.[СтатусДляСостояния_Исх]
	  ,t.[СтатусДляСостояния_След]

	  ,t.[ЗадачаСтатуса_Исх]
	  ,t.[ЗадачаСтатуса_След]

	  ,t.[СостояниеЗаявки_Исх]
	  ,t.[СостояниеЗаявки_След]
 
		,cast([Период_След] as date) as [dt] 
		,[ИсполнительНаим_След] 
		,0 as [ВремяЗатрачено] 
		,[ДатаПриходаНаСтатус] 
	   ,'' as [fio]--f.[fio]
		,[Период_След] as dt_operation
	    --,[Период_След] as [dt_arrival]

into #approve_cd_new -- select *
from #dm_Verification_001_actual_new t
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния_Исх]=t.[СтатусДляСостояния_Исх]
--left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] 

where t.[СтатусДляСостояния_Исх] = N'Контроль данных' and t.[СтатусДляСостояния_След] = 'Верификация клиента'
		--and cast([Период_След] as date)=cast(getdate() as date)
			--and not t.[ЗаявкаНомер_Исх] in (select numer from Reports.dbo.dm_Verification_001_Exception)
				--and [СтатусНаим_След] in (N'Верификация документов клиента') and [ИсполнительНаим_След]<>N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ'
		


order by t.[ЗаявкаНомер_Исх] desc
--select * from #approve_cd_new order by [ЗаявкаНомер] desc


--------------------------------------------
----------------- Заявки на ВК NEW
------------- Общие ВК
drop table if exists #vdk_total_new
select --* 
		2 as [НомерТабл]
	   ,N'Общее кол-во заявок на ВК' as [Показатель]
	   ,t.[ЗаявкаНомер_Исх] as [ЗаявкаНомер] 
	   ,t.[СтатусДляСостояния_Исх]
	  ,t.[СтатусДляСостояния_След]

	  ,t.[ЗадачаСтатуса_Исх]
	  ,t.[ЗадачаСтатуса_След]

	  ,t.[СостояниеЗаявки_Исх]
	  ,t.[СостояниеЗаявки_След]

	   ,t.[dt] --,[Час] 
	   ,t.[ИсполнительНаим_След] 
	   ,t.[ВремяЗатрачено] 
	   ,ar.[ДатаПриходаНаСтатус] 
	   ,'' as [fio]--f.[fio]
	   ,t.[Период_След] as [dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]

into #vdk_total_new   -- select *
from #t0_total_new t
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния_Исх]=t.[СтатусДляСостояния_Исх]
--left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] 
 
where t.[СтатусДляСостояния_Исх] in (N'Верификация клиента') 
		--and  t.[dt]=cast(getdate() as date)
			--and t.[ИсполнительНаим_След] <> N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ' 
			--	and not t.[ЗаявкаНомер_Исх] in (select * from #cancelled_on_vdk_new) --and t.[СтатусНаим_След]<>'Заявка аннулирована'



------------- Уникальные ВК
drop table if exists #uniq_vdk_new
select distinct 
	   2 as [НомерТабл]
	   ,N'Уникальное кол-во заявок на ВК' as [Показатель] 
	   ,[ЗаявкаНомер_Исх_ПослРуки] as [ЗаявкаНомер] 
	   ,t.[СтатусДляСостояния_Исх] 
	  ,t.[СтатусДляСостояния_След]

	  ,t.[ЗадачаСтатуса_Исх]
	  ,t.[ЗадачаСтатуса_След]

	  ,t.[СостояниеЗаявки_Исх]
	  ,t.[СостояниеЗаявки_След]

	   ,[dt] --,[Час] 
	   ,t.[ИсполнительНаим_След] 
	   ,ut.[ВремяЗатрачено] as [ВремяЗатрачено] --sum([ВремяЗатрачено]) [ВремяЗатрачено]
	   ,[ДатаПриходаНаСтатус] 
	   ,'' as [fio]--f.[fio]
	   ,[dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]

into #uniq_vdk_new --select *
from #unique_lasthands_new t 
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния_Исх]=t.[СтатусДляСостояния_Исх]
--left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] 
left join #user_spent_time_status ut on ut.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] and  ut.[СтатусДляСостояния_Исх]=t.[СтатусДляСостояния_Исх] and ut.[ИсполнительНаим_След]=t.[ИсполнительНаим_След]

where t.[СтатусДляСостояния_Исх]='Верификация клиента'
		--and [dt]=cast(getdate() as date) 
			--and not t.[ЗаявкаНомер_Исх_ПослРуки] in (select * from #cancelled_on_vdk_new) --

order by [ЗаявкаНомер_Исх_ПослРуки] desc
--select * from #uniq_vdk_new


------------- Одобрено ВК
drop table if exists #approve_vdk_new
select distinct --*
		2 as [НомерТабл]
	    ,N'Одобренное кол-во заявок на ВК' as [Показатель] 
		,t.[ЗаявкаНомер_Исх] as [ЗаявкаНомер] 
		,t.[СтатусДляСостояния_Исх] 
	  ,t.[СтатусДляСостояния_След]

	  ,t.[ЗадачаСтатуса_Исх]
	  ,t.[ЗадачаСтатуса_След]

	  ,t.[СостояниеЗаявки_Исх]
	  ,t.[СостояниеЗаявки_След]

		,cast([Период_След] as date) as [dt] 
		,[ИсполнительНаим_След] 
		,0 as [ВремяЗатрачено] 
		,[ДатаПриходаНаСтатус] 
	   ,'' as [fio]--f.[fio]
		,t.[Период_След] as [dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]

into #approve_vdk_new 
from #dm_Verification_001_actual_new t
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния_Исх]=t.[СтатусДляСостояния_Исх]
--left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] 

where t.[СтатусДляСостояния_Исх] = N'Верификация клиента' and t.[СтатусДляСостояния_След] = 'Одобрен клиент'
		--and cast([Период_След] as date)=cast(getdate() as date) 

order by t.[ЗаявкаНомер_Исх] desc


--------------------------------------------
----------------- Заявки на ВТС NEW
------------- Общие ВТС
drop table if exists #vd_total_new
select distinct --* 
		2 as [НомерТабл]
	   ,N'Общее кол-во заявок на ВТС' as [Показатель]
	   ,t.[ЗаявкаНомер_Исх] as [ЗаявкаНомер] 
	   ,t.[СтатусДляСостояния_Исх]
	  ,t.[СтатусДляСостояния_След]

	  ,t.[ЗадачаСтатуса_Исх]
	  ,t.[ЗадачаСтатуса_След]

	  ,t.[СостояниеЗаявки_Исх]
	  ,t.[СостояниеЗаявки_След]

	   ,t.[dt] --,[Час] 
	   ,t.[ИсполнительНаим_След] 
	   ,t.[ВремяЗатрачено] 
	   ,ar.[ДатаПриходаНаСтатус] 
	   ,'' as [fio]--f.[fio]
	   ,[Период_След] as [dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]

into #vd_total_new
from #t0_total_new t
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния_Исх]=t.[СтатусДляСостояния_Исх]
--left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх]  

where t.[СтатусДляСостояния_Исх] in (N'Верификация ТС') 
		--and  t.[dt]=cast(getdate() as date)
			and t.[ИсполнительНаим_След] <> N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ' 
				and not t.[ЗаявкаНомер_Исх] in (select * from #cancelled_on_vd_new) --and t.[СтатусНаим_След]<>'Заявка аннулирована'

order by t.[ЗаявкаНомер_Исх] desc


------------- Уникальные ВТС
drop table if exists #uniq_vd_new
select distinct 
	   2 as [НомерТабл]
	   ,N'Уникальное кол-во заявок на ВТС' as [Показатель] 
	   ,[ЗаявкаНомер_Исх_ПослРуки] as [ЗаявкаНомер] 
	   ,t.[СтатусДляСостояния_Исх] 
	  ,t.[СтатусДляСостояния_След]

	  ,t.[ЗадачаСтатуса_Исх]
	  ,t.[ЗадачаСтатуса_След]

	  ,t.[СостояниеЗаявки_Исх]
	  ,t.[СостояниеЗаявки_След]

	   ,[dt] --,[Час] 
	   ,t.[ИсполнительНаим_След] 
	   ,ut.[ВремяЗатрачено] as [ВремяЗатрачено] 
	   ,[ДатаПриходаНаСтатус] 
	   ,'' as [fio]--f.[fio]
	   ,[dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]

into #uniq_vd_new 
from #unique_lasthands_new t 
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния_Исх]=t.[СтатусДляСостояния_Исх]
--left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] 
left join #user_spent_time_status ut on ut.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] and  ut.[СтатусДляСостояния_Исх]=t.[СтатусДляСостояния_Исх] and ut.[ИсполнительНаим_След]=t.[ИсполнительНаим_След]

where t.[СтатусДляСостояния_Исх]='Верификация ТС' 
		--and[dt]=cast(getdate() as date)
			and not t.[ЗаявкаНомер_Исх_ПослРуки] in (select * from #cancelled_on_vd_new) --
--select * from #uniq_vd_new


------------- Одобрено ВТС
drop table if exists #approve_vd_new
select distinct --*
		2 as [НомерТабл]
		,N'Одобренное кол-во заявок на ВТС' as [Показатель] 
		,t.[ЗаявкаНомер_Исх] as [ЗаявкаНомер] 
		,t.[СтатусДляСостояния_Исх] 
	  ,t.[СтатусДляСостояния_След]

	  ,t.[ЗадачаСтатуса_Исх]
	  ,t.[ЗадачаСтатуса_След]

	  ,t.[СостояниеЗаявки_Исх]
	  ,t.[СостояниеЗаявки_След]

		,cast([Период_След] as date) as [dt] 
		,[ИсполнительНаим_След] 
		,0 as [ВремяЗатрачено] 
		,[ДатаПриходаНаСтатус] 
	   ,'' as [fio]--f.[fio]
		,t.[Период_След] as [dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]

into #approve_vd_new 
from #dm_Verification_001_actual_new t
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния_Исх]=t.[СтатусДляСостояния_Исх]
--left join #fio f  on f.[ЗаявкаНомер]=t.[ЗаявкаНомер_Исх] 
where t.[СтатусДляСостояния_Исх] = N'Верификация ТС' and t.[СтатусДляСостояния_След] = 'Одобрено' 
		--and [СтатусНаим_След] in (N'Одобрены документы клиента' ,N'Одобрено') and [ИсполнительНаим_След]<>N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ'
		--and cast([Период_След] as date)=cast(getdate() as date) 
 

 -------------------------------------
 ------------- ВСЕ ДАННЫЕ
drop table if exists #all_data
select distinct --* 
		0 as [НомерТабл]
	   ,N'Все заявки' as [Показатель]
	   ,t.[ЗаявкаНомер_Исх] as [ЗаявкаНомер] 
	   ,t.[СтатусДляСостояния_Исх]
	  ,t.[СтатусДляСостояния_След]

	  ,t.[ЗадачаСтатуса_Исх]
	  ,t.[ЗадачаСтатуса_След]

	  ,t.[СостояниеЗаявки_Исх]
	  ,t.[СостояниеЗаявки_След]

	   ,cast([Период_След] as date) as [dt] 
	   ,t.[ИсполнительНаим_След] 
	   ,t.[ВремяЗатрачено] as [ВремяЗатрачено] --ut.[ВремяЗатрачено] as [ВремяЗатрачено] 
	   ,ar.[ДатаПриходаНаСтатус] 
	   ,'' as [fio]--f.[fio]
	   ,[Период_След] as [dt_operation]
	   --,ur.[Период_Исх] as [dt_arrival]
into #all_data
--select *
from #dm_Verification_001_actual_new t
left join #ArrivalOnStatus_new ar on ar.[ЗаявкаНомер_Исх]=t.[ЗаявкаНомер_Исх] and  ar.[СтатусДляСостояния_Исх]=t.[СтатусДляСостояния_Исх]

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
	  ,[Status]		= [СтатусДляСостояния_Исх]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

	  ,[Status_next]= [СтатусДляСостояния_След]

	  ,[Task_prev]	= [ЗадачаСтатуса_Исх]
	  ,[Task_next]	= [ЗадачаСтатуса_След]

	  ,[State_prev]	= [СостояниеЗаявки_Исх]
	  ,[State_next]	= [СостояниеЗаявки_След]

into #verification_table
--select * 
from #cd_total_new
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
	  ,[Status]		= [СтатусДляСостояния_Исх]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

	  ,[Status_next]= [СтатусДляСостояния_След]

	  ,[Task_prev]	= [ЗадачаСтатуса_Исх]
	  ,[Task_next]	= [ЗадачаСтатуса_След]

	  ,[State_prev]	= [СостояниеЗаявки_Исх]
	  ,[State_next]	= [СостояниеЗаявки_След]
-- select * 
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
	  ,[Status]		= [СтатусДляСостояния_Исх]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

	  ,[Status_next]= [СтатусДляСостояния_След]

	  ,[Task_prev]	= [ЗадачаСтатуса_Исх]
	  ,[Task_next]	= [ЗадачаСтатуса_След]

	  ,[State_prev]	= [СостояниеЗаявки_Исх]
	  ,[State_next]	= [СостояниеЗаявки_След]
-- select *
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
	  ,[Status]		= [СтатусДляСостояния_Исх]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

	  ,[Status_next]= [СтатусДляСостояния_След]

	  ,[Task_prev]	= [ЗадачаСтатуса_Исх]
	  ,[Task_next]	= [ЗадачаСтатуса_След]

	  ,[State_prev]	= [СостояниеЗаявки_Исх]
	  ,[State_next]	= [СостояниеЗаявки_След]
-- select *
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
	  ,[Status]		= [СтатусДляСостояния_Исх]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

	  ,[Status_next]= [СтатусДляСостояния_След]

	  ,[Task_prev]	= [ЗадачаСтатуса_Исх]
	  ,[Task_next]	= [ЗадачаСтатуса_След]

	  ,[State_prev]	= [СостояниеЗаявки_Исх]
	  ,[State_next]	= [СостояниеЗаявки_След]
-- select *
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
	  ,[Status]		= [СтатусДляСостояния_Исх]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

	  ,[Status_next]= [СтатусДляСостояния_След]

	  ,[Task_prev]	= [ЗадачаСтатуса_Исх]
	  ,[Task_next]	= [ЗадачаСтатуса_След]

	  ,[State_prev]	= [СостояниеЗаявки_Исх]
	  ,[State_next]	= [СостояниеЗаявки_След]
-- select *
from #approve_vdk_new


---------- ВТС
--Общие на ВТС

union all
select --* 
	  [period]		= dateadd(month,datediff(month,0,dt_operation),0)
      ,[rdate]		= getdate()
      ,[accdate]	= dt
      ,[Indicator]	= 'Кол-во заявок общее (время)'
      ,[Факт/План]	= 'Факт'
      ,[Value]		= [ВремяЗатрачено]

	  ,[Employee]	= [ИсполнительНаим_След]
	  ,[Status]		= [СтатусДляСостояния_Исх]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

	  ,[Status_next]= [СтатусДляСостояния_След]

	  ,[Task_prev]	= [ЗадачаСтатуса_Исх]
	  ,[Task_next]	= [ЗадачаСтатуса_След]

	  ,[State_prev]	= [СостояниеЗаявки_Исх]
	  ,[State_next]	= [СостояниеЗаявки_След]
-- select *
from #vd_total_new

--Уникальные на ВТС

union all
select --* 
	  [period]		= dateadd(month,datediff(month,0,dt_operation),0)
      ,[rdate]		= getdate()
      ,[accdate]	= dt
      ,[Indicator]	= 'Кол-во заявок уникальное (время)'
      ,[Факт/План]	= 'Факт'
      ,[Value]		= [ВремяЗатрачено]

	  ,[Employee]	= [ИсполнительНаим_След]
	  ,[Status]		= [СтатусДляСостояния_Исх]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

	  ,[Status_next]= [СтатусДляСостояния_След]

	  ,[Task_prev]	= [ЗадачаСтатуса_Исх]
	  ,[Task_next]	= [ЗадачаСтатуса_След]

	  ,[State_prev]	= [СостояниеЗаявки_Исх]
	  ,[State_next]	= [СостояниеЗаявки_След]
-- select *
from #uniq_vd_new

--Оодобрено на ВТС

union all
select --* 
	  [period]		= dateadd(month,datediff(month,0,dt_operation),0)
      ,[rdate]		= getdate()
      ,[accdate]	= dt
      ,[Indicator]	= 'Кол-во заявок одобрено (время)'
      ,[Факт/План]	= 'Факт'
      ,[Value]		= [ВремяЗатрачено]

	  ,[Employee]	= [ИсполнительНаим_След]
	  ,[Status]		= [СтатусДляСостояния_Исх]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

	  ,[Status_next]= [СтатусДляСостояния_След]

	  ,[Task_prev]	= [ЗадачаСтатуса_Исх]
	  ,[Task_next]	= [ЗадачаСтатуса_След]

	  ,[State_prev]	= [СостояниеЗаявки_Исх]
	  ,[State_next]	= [СостояниеЗаявки_След]
-- select *
from #approve_vd_new



-- Все заявки на статусах и задачах

union all
select --* 
	  [period]		= dateadd(month,datediff(month,0,dt_operation),0)
      ,[rdate]		= getdate()
      ,[accdate]	= dt
      ,[Indicator]	= 'Все данные (время)'
      ,[Факт/План]	= 'Факт'
      ,[Value]		= [ВремяЗатрачено]

	  ,[Employee]	= [ИсполнительНаим_След]
	  ,[Status]		= [СтатусДляСостояния_Исх]
	  ,[external_id]= [ЗаявкаНомер]
	  ,[Section]	= 'Верификация'
	  ,[actiondate]	= dt_operation
	  ,[begindate]	= [ДатаПриходаНаСтатус]
	  ,[fio_client]	= fio

	  ,[Status_next]= [СтатусДляСостояния_След]

	  ,[Task_prev]	= [ЗадачаСтатуса_Исх]
	  ,[Task_next]	= [ЗадачаСтатуса_След]

	  ,[State_prev]	= [СостояниеЗаявки_Исх]
	  ,[State_next]	= [СостояниеЗаявки_След]
-- select *
from #all_data


--проверим кол-во записей для замены
delete v
from #dm_Verification_001_actual_new v
left join #cancelled_in_status_new c on v.ЗаявкаНомер_Исх=c.ЗаявкаНомер_Исх and v.СтатусДляСостояния_Исх=c.СтатусДляСостояния_Исх
where not c.ЗаявкаНомер_Исх is null

drop table if exists #Qty_requst_start
select count(distinct [ЗаявкаНомер_Исх]) Qty ,count(distinct cast([Период_След] as date)) Qty_dt ,min([Период_След]) min_dt
into #Qty_requst_start
from #dm_Verification_001_actual_new
where [СостояниеЗаявки_Исх] = 'В работе' --and not [ИсполнительНаим_След] in ('This is Fedor himself' ,'FEDOR FEDOR FEDOR')

drop table if exists #Qty_requst_finish
select count(distinct [external_id]) Qty ,count(distinct cast([actiondate] as date)) Qty_dt ,min([actiondate]) min_dt
into #Qty_requst_finish
from #verification_table order by 1

declare @Qty_Day int, @rdate as datetime
set @Qty_Day = (select Qty_dt from #Qty_requst_finish);
set @rdate = (select min_dt from #Qty_requst_finish);

--select * from #Qty_requst_start

--select * from #Qty_requst_finish
 
if (select Qty_dt from #Qty_requst_start) = (select Qty_dt from #Qty_requst_finish) and (select min_dt from #Qty_requst_start) = @rdate  
begin
	begin tran

	delete 
	--select *
	from [dwh_new].[dbo].[mt_report_verification_fedor_UAT] 
	 --where [accdate]>= @StartDate --  [begindate] >= @StartDate

	insert into [dwh_new].[dbo].[mt_report_verification_fedor_UAT]  ([period]  
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
																,[fio_client]
																,[Status_next]
																,[Task_prev]
																,[Task_next]
																,[State_prev]
																,[State_next])

	select *
	--into [dwh_new].[dbo].[mt_report_verification_fedor_UAT]   
	from #verification_table
	where [accdate]>= @StartDate

	commit tran

end

--   select count(*) from [dwh_new].[dbo].[mt_report_verification_fedor]
--drop table [dwh_new].[dbo].[mt_report_verification_fedor]
--alter table [dwh_new].[dbo].[mt_report_verification_fedor] add [fio_client] nvarchar(255) null

END

