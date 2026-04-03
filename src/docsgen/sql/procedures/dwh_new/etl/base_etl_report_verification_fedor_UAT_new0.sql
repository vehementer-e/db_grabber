
-- =============================================
-- Author:		Курдин С.В.
-- Create date: 2020-01-30
-- Description:	Создание основной таблицы для отчета для Верификации из ФЕДОРА
-- exec [etl].[base_etl_report_verification_fedor_prod_new0]
-- =============================================

CREATE PROCEDURE [etl].[base_etl_report_verification_fedor_UAT_new0]
	-- Add the parameters for the stored procedure here

AS
BEGIN  --auxtab_RequestMFO_1c

	SET NOCOUNT ON;

declare @GetDate2000 datetime,
		@StartDate date

set @GetDate2000=dateadd(year,2000,getdate());
set @StartDate	= cast(dateadd(month,-2,dateadd(month,datediff(month,0,Getdate()),0)) as date);
--select dateadd(year,datediff(year,0,Getdate()),0)
    -- Insert statements for procedure here
--select cast(dateadd(month,-1,dateadd(year ,2000 ,dateadd(day,-15,@StartDate))) as date)



if object_id('tempdb.dbo.#fio') is not null drop table #fio
select [Номер] as [ЗаявкаНомер] ,([Фамилия]+' '+[Имя]+' '+[Отчество]) fio  --[ЗаявкаНомер] ,([Фамилия]+' '+[Имя]+' '+[Отчество]) fio
into #fio
from [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] with (nolock) --[dwh_new].[dbo].[mt_requests_loans_mfo]
where cast([Дата] as date) >= cast(dateadd(month,-1,dateadd(year ,2000 ,dateadd(day,-15,@StartDate))) as date)  --[ЗаявкаДатаОперации]>=dateadd(month,-1,getdate())
	  and not [Номер] like 'СДRC%'


drop table if exists #status_for
create table #status_for([Статус] nvarchar(50) collate Cyrillic_General_CI_AS null) -- SQL_Latin1_General_CP1_CI_AS
insert into #status_for([Статус])
values
		(N'Предварительное одобрение'),
		(N'Верификация Call 1.5'),
		(N'Верификация Call 2'),
		(N'Верификация Call 3')


drop table if exists #structure_firstTable
create table #structure_firstTable([num_rows] int null ,[name_indicator] nvarchar(250) null) -- SQL_Latin1_General_CP1_CI_AS
insert into #structure_firstTable([num_rows] ,[name_indicator])
values
(1 ,'Общее кол-во заведенных заявок')
,(2 ,'Кол-во автоматических отказов Логином')
,(3 ,'%  автоматических отказов Логином')
,(4 ,'Общее кол-во уникальных заявок на этапе')
,(5 ,'Общее кол-во заявок на верификации')
,(6 ,'Общее кол-во заявок на верификации на этапе Верификация клиентов')
,(7 ,'Общее кол-во заявок на верификации на этапе Верификация ТС')
,(8 ,'TTY  - % заявок рассмотренных в течение 30 минут на этапе Верификация клиентов')
,(9 ,'TTY  - % заявок рассмотренных в течение 10 минут на этапе Верификация ТС')
,(10 ,'Среднее время заявки в ожидании очереди (Average queue time) на этапе Верификация клиентов')
,(11 ,'Среднее время заявки в ожидании очереди (Average queue time) на этапе Верификация ТС')
,(12 ,'Средний Processing time на верификации (время обработки заявки)')
,(13 ,'Средний Processing time на верификации на этапе Верификация клиентов')
,(14 ,'Средний Processing time на верификации на этапе Верификация ТС')
,(15 ,'Кол-во одобренных займов после верификации')
,(16 ,'Кол-во одобренных заявок после верификации на этапе Верификация клиентов')
,(17 ,'Кол-во одобренных заявок после верификации на этапе Верификация ТС')
,(18 ,'Кол-во отказов со стороны верификаторов')
,(19 ,'Кол-во отказов со стороны верификаторов на этапе Верификация клиентов')
,(20 ,'Кол-во отказов со стороны верификаторов на этапе Верификация ТС')
,(21 ,'Approval rate верификации - % одобренных после верификации')
,(22 ,'Approval rate верификации % одобренных после верификации  на этапе Верификация клиентов')
,(23 ,'Approval rate верификации % одобренных после верификации  на этапе Верификация ТС')
,(24 ,'Approval rate % Логином')
,(25 ,'Общее кол-во отложенных заявок')
,(26 ,'Общее кол-во отложенных заявок на этапе Верификация клиентов')
,(27 ,'Общее кол-во отложенных заявок на этапе Верификация ТС')
,(28 ,'Общее кол-во заявок, отправленных на доработку')
,(29 ,'Общее кол-во заявок, отправленных на доработку на этапе Верификация клиентов')
,(30 ,'Общее кол-во  заявок, отправленных на доработку на этапе Верификация ТС')
,(31 ,'Take rate Уровень выдачи, выраженный через одобрения')

-- Кол-во одобренных займов после этапа

drop table if exists #calendar_day
select created dt
into #calendar_day
from dwh_new.dbo.calendar
where created >= dateadd(year,datediff(year,0,Getdate()),0) and created <= Getdate()
--select * from #calendar

drop table if exists #calendar_month
select distinct
	   dateadd(month,datediff(month,0,created),0) dt
into #calendar_month
from dwh_new.dbo.calendar
where created >= dateadd(year,datediff(year,0,Getdate()),0) and created <= Getdate()


drop table if exists #mt_requests_transition_fedor_prod_0
select *
into #mt_requests_transition_fedor_prod_0
from [dwh_new].[dbo].[mt_requests_transition_fedor_UAT] with (nolock)
-- select * from #mt_requests_transition_fedor_prod_0


---- Дата и Время прихода на статус 
drop table if exists #Request_first_time_on_status
select t.*
into #Request_first_time_on_status
from (
select distinct
		[ЗаявкаНомер_Исх]
		,cast([Период_Исх] as date) as [dt_firsttime]
		,[Период_Исх]		
		,[СтатусДляСостояния_Исх] status_first
		--,employee
		,rank() over(partition by [ЗаявкаНомер_Исх] ,[СтатусДляСостояния_Исх] order by [Период_Исх]) r

from #mt_requests_transition_fedor_prod_0 with (nolock)
--where [ЗадачаСтатуса_Исх] in (N'task:В работе')
) t
where t.r = 1
-- select * from #Request_first_time_on_status

drop table if exists #mt_requests_transition_fedor_prod
select distinct
	   [ЗаявкаНомер_Исх]

      ,[СтатусДляСостояния_Исх]	status_first
      ,[СтатусДляСостояния_След]
	  ,[ЗадачаСтатуса_Исх]
	  ,[ЗадачаСтатуса_След]
      ,[СостояниеЗаявки_Исх]
      ,[СостояниеЗаявки_След]

      ,dateadd(hour,3,[Период_Исх]) [Период_Исх]	-- прибавляем 3 часа, так как в Федоре время UTC
	  --,
      ,case when [Период_След] is null then getdate() else dateadd(hour,3,[Период_След]) end as [Период_След]

      ,[СтатусНаим_Исх]
      ,[СтатусНаим_След]

      ,[ИсполнительНаим_Исх] as employee
      ,[ИсполнительНаим_След]
      ,[ВремяЗатрачено]

      ,[ПричинаНаим_Исх]
      ,[ПричинаНаим_След]
	  ,[Tm]
	  
	  ,'День' [Периодичность] 
into #mt_requests_transition_fedor_prod
from [dwh_new].[dbo].[mt_requests_transition_fedor_UAT] with (nolock)
--left join 
 where not [СтатусДляСостояния_След] is null

 union all

--drop table if exists #mt_requests_transition_fedor_prod

select distinct
	   [ЗаявкаНомер_Исх]

      ,[СтатусДляСостояния_Исх]	status_first
      ,[СтатусДляСостояния_След]
	  ,[ЗадачаСтатуса_Исх]
	  ,[ЗадачаСтатуса_След]
      ,[СостояниеЗаявки_Исх]
      ,[СостояниеЗаявки_След]

      ,dateadd(hour,3,[Период_Исх]) [Период_Исх]
      ,case when [Период_След] is null then getdate() else dateadd(hour,3,[Период_След]) end as [Период_След]

      ,[СтатусНаим_Исх]
      ,[СтатусНаим_След]

      ,'Без сотрудника' employee
      ,'Без сотрудника' [ИсполнительНаим_След]
      ,[ВремяЗатрачено]

      ,[ПричинаНаим_Исх]
      ,[ПричинаНаим_След]
	  ,[Tm]
	  ,'Месяц' [Периодичность] 

--into #mt_requests_transition_fedor_prod

from [dwh_new].[dbo].[mt_requests_transition_fedor_UAT] with (nolock)
 where not [СтатусДляСостояния_След] is null

-- select * from #mt_requests_transition_fedor_prod where employee = 'Без сотрудника'
 
----------------------------------------------
--------------РАСЧЕТ ПО ДНЯМ. НАЧАЛО----------
----------------------------------------------

drop table if exists #user_status_on_day
select distinct
		dateadd(day,datediff(day,0,[Период_Исх]),0) dt
		,employee
		,status_first
into #user_status_on_day
from #mt_requests_transition_fedor_prod e
where status_first<>'Черновик'
-- select * from #mt_requests_transition_fedor_prod


---- Дата и Время в статусе первой руки в работу 
drop table if exists #Request_dt_firsthands
select t.*
into #Request_dt_firsthands
from (
select 
		[ЗаявкаНомер_Исх]
		,cast([Период_Исх] as date) as [dt_firsthands]
		,[Период_Исх]		
		,status_first
		,employee
		,rank() over(partition by [ЗаявкаНомер_Исх] ,status_first order by [Период_Исх]) r

from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in (N'task:В работе')
) t
where t.r = 1
--select * from #Request_dt_firsthands


---- Дата и Время в статусе последней руки из работы 
drop table if exists #Request_dt_lasthands
select t.*
into #Request_dt_lasthands
from (
select 
		[ЗаявкаНомер_Исх]
		,cast([Период_Исх] as date) as [dt_lasthands]
		,status_first
		,employee
		,rank() over(partition by [ЗаявкаНомер_Исх] ,status_first order by [Период_Исх] desc) [r]

from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in (N'task:В работе') and [ЗадачаСтатуса_След] in (N'task:Выполнена')
) t
where t.r = 1
-- select * from #Request_dt_lasthands



-----------------------------------------
-----------------------------------------
-----------------------------------------
------ ФАКТОРИНГ ------------------------


---- Общее кол-во заведенных заявок
drop table if exists #m_total_Qty_all_2
select 
		[ЗаявкаНомер_Исх] 
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
		,cast([Период_След] as date) as [dt]
		,count(*) Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
		,'Общее кол-во заведенных заявок' Indicator
		
into #m_total_Qty_all_2		 
from #mt_requests_transition_fedor_prod 
where [СтатусДляСостояния_След] in (N'Предварительное одобрение' ,N'Верификация Call 1.5',N'Верификация Call 2',N'Верификация Call 3')
group by 
grouping sets
(
([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)
-- select * from #m_total_Qty_all_2 where not pdt is null
-- select * from #m_total_Qty_all_2 where pdt is null

-- кол-во автоматических отказов на этапах

drop table if exists #canceled_Qty_all_2
select --count(*)
		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
		,cast([Период_След] as date) as [dt]
		,count(*) Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
		,'Кол-во автоматических отказов Логином' Indicator	

into #canceled_Qty_all_2
from #mt_requests_transition_fedor_prod 
where [СтатусДляСостояния_След] in ('Отказано' ,'Отказ документов клиента')
group by
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)
-- select * from #canceled_Qty_all_2


-- Уникальное кол-во заявок на этапе

drop table if exists #uniq_Qty_2
select --count(distinct [ЗаявкаНомер_Исх]) uniq_Qty
		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
		,cast([Период_След] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) uniq_Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
		,'Общее кол-во уникальных заявок на этапе' Indicator	
					 
into #uniq_Qty_2
from #mt_requests_transition_fedor_prod where [ЗадачаСтатуса_Исх] = 'task:Новая'
group by --[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)


-- Общее кол-во заявок на этапе

drop table if exists #total_Qty_Status_2
select 
		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
		,cast([Период_След] as date) as [dt]
		,count(*) total_Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee		
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
		,'Общее кол-во заявок на этапе' Indicator	

into #total_Qty_Status_2  
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('task:Новая' ,'task:Вернулась из отложенных' ,'task:Вернулась с доработки')
group by 
--[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)



-- Общее кол-во заявок выполненных на этапе
drop table if exists #total_Qty_res_2
select --count(*) total_Qty_res
		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [pdt]
		,cast([Период_Исх] as date) as [dt]
		,count(*) total_Qty_res
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
		,'Общее кол-во заявок выполненных на этапе' Indicator	

into #total_Qty_res_2  
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('task:Выполнена')
group by 
--[ЗаявкаНомер_Исх] ,cast([Период_Исх] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_Исх] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)
-- select * from #total_Qty_res_2 where employee = ''


-- Кол-во Заявок TTY время рассмотрения заявок меньше 10 минут

drop table if exists #Qty_request_TTY10_2
select t.* 
		,'TTY  - % заявок рассмотренных в течение 10 минут на этапе' Indicator		
into #Qty_request_TTY10_2
from (
		select 
				[ЗаявкаНомер_Исх]
				,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
				,cast([Период_След] as date) as [dt]
				,count([ЗаявкаНомер_Исх]) Qty
				,status_first
				,[СтатусДляСостояния_След]
				,employee
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]						 
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:В работе')
		group by 
		--[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
		grouping sets 
		(
		([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		)
	 ) t
where [ВремяЗатрачено] <= 0.00695 -- это 10 минут
		--and [pdt] is null
-- select * from #Qty_request_TTY10_2 where employee = ''


-- Кол-во Заявок TTY время рассмотрения заявок меньше 30 минут
drop table if exists #Qty_request_TTY30_2
select t.* 
		,'TTY  - % заявок рассмотренных в течение 30 минут на этапе' Indicator		
into #Qty_request_TTY30_2
from (
		select 
				[ЗаявкаНомер_Исх]
				,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
				,cast([Период_След] as date) as [dt]
				,count([ЗаявкаНомер_Исх]) Qty				
				,status_first
				,[СтатусДляСостояния_След]
				,employee
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]				 
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:В работе')
		group by 
		--[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
		grouping sets 
		(
		([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		)

	 ) t
where [ВремяЗатрачено] <= 0.02083 -- это 30 минут
-- select * from #Qty_request_TTY10_2 where employee = ''


-- время заявки в ожидании очереди /*Среднее время заявки в ожидании очереди (Average queue time) на этапе */
drop table if exists #Request_queue_time_2 --#AVG_queue_time
select t.*	--t.[ВремяЗатрачено]/ (select * from #uniq_Qty) AVG_queue_time
		,'Среднее время заявки в ожидании очереди на этапе' Indicator		
into #Request_queue_time_2
from (
		select 
				[ЗаявкаНомер_Исх]
				,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
				,cast([Период_След] as date) as [dt]
				,count([ЗаявкаНомер_Исх]) Qty				
				,status_first
				,[СтатусДляСостояния_След]
				,employee
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]					
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:Новая' ,'task:Вернулась из отложенных' ,'task:Вернулась с доработки')
		group by 
		--[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee 
		grouping sets 
		(
		([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		)
	 ) t
-- select * from #Request_queue_time_2 where employee = ''


-- Средний Processing time на этапе (время обработки заявки)
drop table if exists #Request_Processing_time_2
select	t.*	--t.[ВремяЗатрачено]/ (select * from #total_Qty_res) AVG_queue_time
		,'Средний Processing time на этапе (время обработки заявки)' Indicator		
into #Request_Processing_time_2	--#AVG_Processing_time
from (
		select --sum([ВремяЗатрачено]) [ВремяЗатрачено]
				[ЗаявкаНомер_Исх]
				,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
				,cast([Период_След] as date) as [dt]
				,count([ЗаявкаНомер_Исх]) Qty
				,status_first
				,[СтатусДляСостояния_След]
				,employee
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]					
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:В работе' ,'task:Отложена' ,'task:Требуется доработка') 
		group by 
		--[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee 
		grouping sets 
		(
		([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		)
	) t


-- Кол-во одобренных заявок после этапа
drop table if exists #appr_Qty_2
select 
		r.[ЗаявкаНомер_Исх]
		,case 
			when not lh.dt_lasthands is null 
				then cast(dateadd(month,datediff(month,0,lh.dt_lasthands),0) as date)
			else case 
					when not fh.dt_firsthands is null 
						then cast(dateadd(month,datediff(month,0,fh.dt_firsthands),0) as date)
					else cast(dateadd(month,datediff(month,0,[Период_След]),0) as date)
				 end 
		end  as [pdt]
		,case when not lh.dt_lasthands is null then lh.dt_lasthands else case when not fh.dt_firsthands is null then fh.dt_firsthands else cast([Период_След] as date) end end  as [dt]
		,count(distinct r.[ЗаявкаНомер_Исх]) appr_Qty
		,r.status_first
		,[СтатусДляСостояния_След]
		,r.employee	
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
		,'Кол-во одобренных заявок после этапа' Indicator
				 
into #appr_Qty_2
from #mt_requests_transition_fedor_prod r

left join #Request_dt_lasthands lh on  r.[ЗаявкаНомер_Исх] = lh.ЗаявкаНомер_Исх and r.status_first = lh.status_first and r.employee = lh.employee 
left join #Request_dt_firsthands fh on  r.[ЗаявкаНомер_Исх] = fh.ЗаявкаНомер_Исх and r.status_first = fh.status_first and r.employee = fh.employee

where [ЗадачаСтатуса_Исх] = 'task:Выполнена' and not [СтатусДляСостояния_След] in ('Отказано' ,'Аннулировано') and r.status_first<>'Черновик'
group by 
--r.[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,r.status_first ,[СтатусДляСостояния_След] ,r.employee ,lh.dt_lasthands ,fh.dt_firsthands
grouping sets 
(
(r.[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,r.status_first ,[СтатусДляСостояния_След] ,r.employee ,lh.dt_lasthands ,fh.dt_firsthands)
, (	r.[ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) 
	,r.status_first ,[СтатусДляСостояния_След] ,r.employee 
	,cast(dateadd(month,datediff(month,0,lh.dt_lasthands),0) as date) 
	,cast(dateadd(month,datediff(month,0,fh.dt_firsthands),0) as date)
   )
)
-- select * from #appr_Qty_2 where not dt is null  --[ЗаявкаНомер_Исх]='20030300013507' employee = ''


-- Кол-во отказов 
drop table if exists #canceled_Qty_empl_2
select 
 		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
		,cast([Период_След] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) canceled_Qty_empl
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
		,'Кол-во отказов со стороны сотрудников' Indicator
					 
into #canceled_Qty_empl_2
from #mt_requests_transition_fedor_prod 
where [СтатусДляСостояния_След] in ('Отказано' ,'Аннулировано')
group by 
--[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee 
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)
-- select * from #canceled_Qty_empl_2 where employee = ''


-- Кол-во заявок только в работе на этапе
drop table if exists #Request_in_work_Qty_2
select --count(distinct [ЗаявкаНомер_Исх]) postponed_Qty 
 		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [pdt]
		,cast([Период_Исх] as date) as [dt]
		,count([ЗаявкаНомер_Исх]) Qty 
		,status_first
		,[СтатусДляСостояния_След]
		,employee	
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
		,'Кол-во заявок только в работе на этапе' Indicator
into #Request_in_work_Qty_2
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('task:В работе')
group by 
--[ЗаявкаНомер_Исх] ,cast([Период_Исх] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_Исх] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)

-- Кол-во отложенных заявок на этапе
drop table if exists #postponed_Qty_2
select --count(distinct [ЗаявкаНомер_Исх]) postponed_Qty 
 		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [pdt]
		,cast([Период_Исх] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) postponed_Qty 
		,status_first
		,[СтатусДляСостояния_След]
		,employee	
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
		,'Общее кол-во отложенных заявок на этапе' Indicator
into #postponed_Qty_2
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('task:Отложена')
group by 
--[ЗаявкаНомер_Исх] ,cast([Период_Исх] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_Исх] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)
-- select * from #postponed_Qty_2 where employee = ''


-- Кол-во заявок, отправленных на доработку на этапе
drop table if exists #revision_Qty_2
select 
 		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
		,cast([Период_След] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) revision_Qty 
		,status_first
		,[СтатусДляСостояния_След]
		,employee	
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
		,'Кол-во заявок на этапе, отправленных на доработку' Indicator
into #revision_Qty_2
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('task:Требуется доработка')
group by 
--[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee 
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)
-- select * from #postponed_Qty_2 where employee = ''


-- Кол-во выданных займов
drop table if exists #Loans_Qty_2
select 
 		r.[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
		,cast([Период_След] as date) as [dt]
		--,
		,count(distinct r.[ЗаявкаНомер_Исх]) Loans_Qty
		,r.status_first
		,r.[СтатусДляСостояния_След]
		,r.employee 
		,0.0000000 as [ВремяЗатрачено]
		,'Кол-во выданных займов' Indicator

into #Loans_Qty_2
from #mt_requests_transition_fedor_prod r
where r.[СтатусДляСостояния_След]='Заем выдан'
group by 
--r.[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,r.status_first ,r.[СтатусДляСостояния_След] ,r.employee --,a.dt
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)
-- select * from #Loans_Qty_2 where employee = ''


drop table if exists #tmp
select
[period]			= case when not [pdt] is null then [pdt] else cast(dateadd(month,datediff(month,0,[dt]),0) as date) end 
,[rdate]			= getdate()
,[accdate_month]	= [pdt]
,[accdate]			= [dt]
,[Indicator]		= Indicator
,[Факт/План]		= 'Факт'
,[Value]			= [ВремяЗатрачено]
,[Employee]			= employee
,[Status]			= status_first
,[external_id]		= [ЗаявкаНомер_Исх]
,[Section]			= 'Верификация'
,[actiondate]		= [dt]
,[begindate]		= null
,[fio_client]		= ''
,[Status_next]		= [СтатусДляСостояния_След]
,[Task_prev]		= ''
,[Task_next]		= ''
,[State_prev]		= ''
,[State_next]		= ''
,[frequency]		= ''
,[Qty]				= Qty
into #tmp
from 
(		
select		
		[ЗаявкаНомер_Исх] 
		,[pdt]
		,[dt]
		,Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,[ВремяЗатрачено]
		,Indicator

from #m_total_Qty_all_2		--where not [pdt] is null

union all
-- кол-во автоматических отказов на этапах
select * from #canceled_Qty_all_2 	-- where [pdt] is null

union all
-- Уникальное кол-во заявок на этапе
select * from #uniq_Qty_2 	--where not [pdt] is null

union all
-- Общее кол-во заявок на этапе
select * from #total_Qty_Status_2

union all
-- Общее кол-во заявок выполненных на этапе
select * from #total_Qty_res_2

union all
-- Кол-во Заявок TTY время рассмотрения заявок меньше 10 минут
select * from #Qty_request_TTY10_2

union all
-- Кол-во Заявок TTY время рассмотрения заявок меньше 30 минут
select * from #Qty_request_TTY30_2

union all
-- время заявки в ожидании очереди /*Среднее время заявки в ожидании очереди (Average queue time) на этапе */
select * from #Request_queue_time_2

union all
-- Средний Processing time на этапе (время обработки заявки)
select * from #Request_Processing_time_2

union all
-- Кол-во одобренных заявок после этапа
select * from #appr_Qty_2

union all
-- Кол-во отказов 
select * from #canceled_Qty_empl_2

union all
-- Кол-во только в работе 
select * from #Request_in_work_Qty_2

union all
-- Кол-во отложенных заявок на этапе
select * from #postponed_Qty_2

union all
-- Кол-во заявок, отправленных на доработку на этапе
select * from #revision_Qty_2

union all
-- Кол-во выданных займов
select * from #Loans_Qty_2
) t

--select * from #tmp where [external_id] = '20030300013507'

drop table if exists #verification_table
select 
		[period]  
		,[rdate]
		,[accdate_month]
		,[accdate]
		,[Indicator]
		,[Факт/План]
		,[Value]
		,[Employee]
		,[Status]
		,[external_id]
		,[Section]
		,[actiondate]
		,[begindate] = b.[dt_firsttime]
		,[fio_client]
		,[Status_next]
		,[Task_prev]
		,[Task_next]
		,[State_prev]
		,[State_next]
		,[frequency] = (case when not [accdate_month] is null and [accdate] is null then 'Месяц' when not [accdate] is null then 'День' end)
		,[Qty] 
into #verification_table
from #tmp t
left join #Request_first_time_on_status b on t.external_id=b.[ЗаявкаНомер_Исх] and t.[Status]=b.status_first

--select * from #verification_table where [accdate_month] is null

--delete 
--from
--(
--select r.* ,v.[external_id] ,v.[Status] ,v.[Employee]  from [dwh_new].[dbo].[mt_report_verification_fedor_prod_new] r
--left join #verification_table v on r.[external_id] = v.[external_id] and r.[Status]=v.[Status] and r.[Employee]=v.[Employee] and r.[Status_next]=v.[Status_next]
--)
--where not [external_id] is null

--select * from #Qty_requst_start

--select * from #Qty_requst_finish
 
--if (select Qty_dt from #Qty_requst_start) = (select Qty_dt from #Qty_requst_finish) and (select min_dt from #Qty_requst_start) = @rdate  
--begin
	if isnull((select count(*) from #verification_table) ,0) > 0
	begin
		begin tran

		delete 
		--select *
		from [dwh_new].[dbo].[mt_report_verification_fedor_UAT_new] 
		 --where [accdate]>= @StartDate --  [begindate] >= @StartDate

		insert into [dwh_new].[dbo].[mt_report_verification_fedor_UAT_new]  ([period]  
																	,[rdate]
																	,[accdate_month]
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
																	,[State_next]
																	,[frequency]
																	,[Qty])

	--drop table [dwh_new].[dbo].[mt_report_verification_fedor_prod_new]
		select *
		--into [dwh_new].[dbo].[mt_report_verification_fedor_UAT_new]    
		from #verification_table v
		--where [accdate]>= @StartDate

		commit tran
	end
--end

--   select * from [dwh_new].[dbo].[mt_report_verification_fedor_UAT_new] where [frequency]='Месяц' order by 3 desc
--drop table [dwh_new].[dbo].[mt_report_verification_fedor]
--alter table [dwh_new].[dbo].[mt_report_verification_fedor] add [fio_client] nvarchar(255) null

END


/*



---- Общее кол-во заведенных заявок
drop table if exists #total_Qty_all
select 
		[ЗаявкаНомер_Исх]
		,cast([Период_След] as date) as [dt]
		,count(*) Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
into #total_Qty_all	-- select *	 
from #mt_requests_transition_fedor_prod 
where [СтатусДляСостояния_След] in (N'Предварительное одобрение' ,N'Верификация Call 1.5',N'Верификация Call 2',N'Верификация Call 3')
group by [ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
--select * from #total_Qty_all

/*
drop table if exists #m_total_Qty_all_2

select 
		[ЗаявкаНомер_Исх] 
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
		,cast([Период_След] as date) as [dt]
		,count(*) Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
--into #m_total_Qty_all_2		 
from #mt_requests_transition_fedor_prod 
where [СтатусДляСостояния_След] in (N'Предварительное одобрение' ,N'Верификация Call 1.5',N'Верификация Call 2',N'Верификация Call 3')
group by 
grouping sets
(
([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)
*/

-- кол-во автоматических отказов на этапах
drop table if exists #canceled_Qty_all
select --count(*)
		[ЗаявкаНомер_Исх]

		,cast([Период_След] as date) as [dt]
		,count(*) Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
into #canceled_Qty_all 
from #mt_requests_transition_fedor_prod 
where [СтатусДляСостояния_След] in ('Отказано' ,'Отказ документов клиента')
group by [ЗаявкаНомер_Исх]  ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee

/*
drop table if exists #canceled_Qty_all_2
select --count(*)
		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
		,cast([Период_След] as date) as [dt]
		,count(*) Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
into #canceled_Qty_all_2
from #mt_requests_transition_fedor_prod 
where [СтатусДляСостояния_След] in ('Отказано' ,'Отказ документов клиента')
group by
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)


*/


-- Уникальное кол-во заявок на этапе
drop table if exists #uniq_Qty
select --count(distinct [ЗаявкаНомер_Исх]) uniq_Qty
		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
		,cast([Период_След] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) uniq_Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
					 
into #uniq_Qty
from #mt_requests_transition_fedor_prod where [ЗадачаСтатуса_Исх] = 'task:Новая'
group by [ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee


/*
drop table if exists #uniq_Qty_2
select --count(distinct [ЗаявкаНомер_Исх]) uniq_Qty
		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
		,cast([Период_След] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) uniq_Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
					 
into #uniq_Qty_2
from #mt_requests_transition_fedor_prod where [ЗадачаСтатуса_Исх] = 'task:Новая'
group by --[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)
*/

-- Общее кол-во заявок на этапе
drop table if exists #total_Qty_Status
select 
		[ЗаявкаНомер_Исх]
		,cast([Период_След] as date) as [dt]
		,count(*) total_Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee		
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
into #total_Qty_Status  
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('task:Новая' ,'task:Вернулась из отложенных' ,'task:Вернулась с доработки')
group by [ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
--select * from #total_Qty_Status where employee = 'АЗАРОВА СВЕТЛАНА ВИКТОРОВНА' and dt='2020-02-21'

/*
-- Общее кол-во заявок на этапе
drop table if exists #total_Qty_Status_2
select 
		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
		,cast([Период_След] as date) as [dt]
		,count(*) total_Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee		
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
into #total_Qty_Status_2  
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('task:Новая' ,'task:Вернулась из отложенных' ,'task:Вернулась с доработки')
group by 
--[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)
*/


-- Общее кол-во заявок выполненных на этапе
drop table if exists #total_Qty_res
select --count(*) total_Qty_res
		[ЗаявкаНомер_Исх]
		,cast([Период_Исх] as date) as [dt]
		,count(*) total_Qty_res
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]

into #total_Qty_res  
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('task:Выполнена')
group by [ЗаявкаНомер_Исх] ,cast([Период_Исх] as date) ,status_first ,[СтатусДляСостояния_След] ,employee


/*
drop table if exists #total_Qty_res_2
select --count(*) total_Qty_res
		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [pdt]
		,cast([Период_Исх] as date) as [dt]
		,count(*) total_Qty_res
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]

into #total_Qty_res_2  
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('task:Выполнена')
group by 
--[ЗаявкаНомер_Исх] ,cast([Период_Исх] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_Исх] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)
-- select * from #total_Qty_res_2 where employee = ''
*/

-- Кол-во Заявок TTY время рассмотрения заявок меньше 10 минут
drop table if exists #Qty_request_TTY10
select t.* 
into #Qty_request_TTY10
from (
		select 
				[ЗаявкаНомер_Исх]
				,cast([Период_След] as date) as [dt]
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]
				,status_first
				,[СтатусДляСостояния_След]
				,employee				 
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:В работе')
		group by [ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
	 ) t
where [ВремяЗатрачено] <= 0.00695 -- это 10 минут

/*
drop table if exists #Qty_request_TTY10_2
select t.* 
into #Qty_request_TTY10_2
from (
		select 
				[ЗаявкаНомер_Исх]
				,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
				,cast([Период_След] as date) as [dt]
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]
				,status_first
				,[СтатусДляСостояния_След]
				,employee				 
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:В работе')
		group by 
		--[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
		grouping sets 
		(
		([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		)
	 ) t
where [ВремяЗатрачено] <= 0.00695 -- это 10 минут
		--and [pdt] is null
-- select * from #Qty_request_TTY10_2 where employee = ''
*/


-- Кол-во Заявок TTY время рассмотрения заявок меньше 30 минут
drop table if exists #Qty_request_TTY30
select t.* 
into #Qty_request_TTY30
from (
		select 
				[ЗаявкаНомер_Исх]
				,cast([Период_След] as date) as [dt]
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]
				,status_first
				,[СтатусДляСостояния_След]
				,employee				 
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:В работе')
		group by [ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
	 ) t
where [ВремяЗатрачено] <= 0.02083 -- это 30 минут

/*
-- Кол-во Заявок TTY время рассмотрения заявок меньше 30 минут
drop table if exists #Qty_request_TTY30_2
select t.* 
into #Qty_request_TTY30_2
from (
		select 
				[ЗаявкаНомер_Исх]
				,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
				,cast([Период_След] as date) as [dt]
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]
				,status_first
				,[СтатусДляСостояния_След]
				,employee				 
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:В работе')
		group by 
		--[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
		grouping sets 
		(
		([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		)

	 ) t
where [ВремяЗатрачено] <= 0.02083 -- это 30 минут
-- select * from #Qty_request_TTY10_2 where employee = ''
*/


-- время заявки в ожидании очереди /*Среднее время заявки в ожидании очереди (Average queue time) на этапе */
drop table if exists #Request_queue_time --#AVG_queue_time
select t.*	--t.[ВремяЗатрачено]/ (select * from #uniq_Qty) AVG_queue_time
into #Request_queue_time
from (
		select 
				[ЗаявкаНомер_Исх]
				,cast([Период_След] as date) as [dt]
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]
				,status_first
				,[СтатусДляСостояния_След]
				,employee					
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:Новая' ,'task:Вернулась из отложенных' ,'task:Вернулась с доработки')
		group by [ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee 
	 ) t

/*

-- время заявки в ожидании очереди /*Среднее время заявки в ожидании очереди (Average queue time) на этапе */
drop table if exists #Request_queue_time_2 --#AVG_queue_time
select t.*	--t.[ВремяЗатрачено]/ (select * from #uniq_Qty) AVG_queue_time
into #Request_queue_time_2
from (
		select 
				[ЗаявкаНомер_Исх]
				,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
				,cast([Период_След] as date) as [dt]
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]
				,status_first
				,[СтатусДляСостояния_След]
				,employee					
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:Новая' ,'task:Вернулась из отложенных' ,'task:Вернулась с доработки')
		group by 
		--[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee 
		grouping sets 
		(
		([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		)
	 ) t
-- select * from #Request_queue_time_2 where employee = ''
*/


-- Средний Processing time на этапе (время обработки заявки)
drop table if exists #Request_Processing_time
select	t.*	--t.[ВремяЗатрачено]/ (select * from #total_Qty_res) AVG_queue_time
into #Request_Processing_time	--#AVG_Processing_time
from (
		select --sum([ВремяЗатрачено]) [ВремяЗатрачено]
				[ЗаявкаНомер_Исх]
				,cast([Период_След] as date) as [dt]
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]
				,status_first
				,[СтатусДляСостояния_След]
				,employee	
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:В работе' ,'task:Отложена' ,'task:Требуется доработка') 
		group by [ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee 
	) t

/*
-- Средний Processing time на этапе (время обработки заявки)
drop table if exists #Request_Processing_time_2
select	t.*	--t.[ВремяЗатрачено]/ (select * from #total_Qty_res) AVG_queue_time
into #Request_Processing_time_2	--#AVG_Processing_time
from (
		select --sum([ВремяЗатрачено]) [ВремяЗатрачено]
				[ЗаявкаНомер_Исх]
				,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
				,cast([Период_След] as date) as [dt]
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]
				,status_first
				,[СтатусДляСостояния_След]
				,employee	
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:В работе' ,'task:Отложена' ,'task:Требуется доработка') 
		group by 
		--[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee 
		grouping sets 
		(
		([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
		)
	) t

*/

-- Кол-во одобренных заявок после этапа
drop table if exists #appr_Qty
select 
		r.[ЗаявкаНомер_Исх]
		,case when not lh.dt_lasthands is null then lh.dt_lasthands else case when not fh.dt_firsthands is null then fh.dt_firsthands else cast([Период_След] as date) end end  as [dt]
		,count(distinct r.[ЗаявкаНомер_Исх]) appr_Qty
		,r.status_first
		,[СтатусДляСостояния_След]
		,r.employee	
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
				 
into #appr_Qty
from #mt_requests_transition_fedor_prod r

left join #Request_dt_lasthands lh on  r.[ЗаявкаНомер_Исх] = lh.ЗаявкаНомер_Исх and r.status_first = lh.status_first and r.employee = lh.employee 
left join #Request_dt_firsthands fh on  r.[ЗаявкаНомер_Исх] = fh.ЗаявкаНомер_Исх and r.status_first = fh.status_first and r.employee = fh.employee

where [ЗадачаСтатуса_Исх] = 'task:Выполнена' and not [СтатусДляСостояния_След] in ('Отказано' ,'Аннулировано') and r.status_first<>'Черновик'
group by r.[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,r.status_first ,[СтатусДляСостояния_След] ,r.employee ,lh.dt_lasthands ,fh.dt_firsthands
--select * from #appr_Qty

/*
-- Кол-во одобренных заявок после этапа
drop table if exists #appr_Qty_2
select 
		r.[ЗаявкаНомер_Исх]
		,case 
			when not lh.dt_lasthands is null 
				then cast(dateadd(month,datediff(month,0,lh.dt_lasthands),0) as date)
			else case 
					when not fh.dt_firsthands is null 
						then cast(dateadd(month,datediff(month,0,fh.dt_firsthands),0) as date)
					else cast(dateadd(month,datediff(month,0,[Период_След]),0) as date)
				 end 
		end  as [pdt]
		,case when not lh.dt_lasthands is null then lh.dt_lasthands else case when not fh.dt_firsthands is null then fh.dt_firsthands else cast([Период_След] as date) end end  as [dt]
		,count(distinct r.[ЗаявкаНомер_Исх]) appr_Qty
		,r.status_first
		,[СтатусДляСостояния_След]
		,r.employee	
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
				 
into #appr_Qty_2
from #mt_requests_transition_fedor_prod r

left join #Request_dt_lasthands lh on  r.[ЗаявкаНомер_Исх] = lh.ЗаявкаНомер_Исх and r.status_first = lh.status_first and r.employee = lh.employee 
left join #Request_dt_firsthands fh on  r.[ЗаявкаНомер_Исх] = fh.ЗаявкаНомер_Исх and r.status_first = fh.status_first and r.employee = fh.employee

where [ЗадачаСтатуса_Исх] = 'task:Выполнена' and not [СтатусДляСостояния_След] in ('Отказано' ,'Аннулировано') and r.status_first<>'Черновик'
group by 
--r.[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,r.status_first ,[СтатусДляСостояния_След] ,r.employee ,lh.dt_lasthands ,fh.dt_firsthands
grouping sets 
(
(r.[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,r.status_first ,[СтатусДляСостояния_След] ,r.employee ,lh.dt_lasthands ,fh.dt_firsthands)
, (	r.[ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) 
	,r.status_first ,[СтатусДляСостояния_След] ,r.employee 
	,cast(dateadd(month,datediff(month,0,lh.dt_lasthands),0) as date) 
	,cast(dateadd(month,datediff(month,0,fh.dt_firsthands),0) as date)
   )
)
-- select * from #appr_Qty_2 where employee = ''

*/


-- Кол-во отказов 
drop table if exists #canceled_Qty_empl
select 
 		[ЗаявкаНомер_Исх]
		,cast([Период_След] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) canceled_Qty_empl
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
			 
into #canceled_Qty_empl
from #mt_requests_transition_fedor_prod 
where [СтатусДляСостояния_След] in ('Отказано' ,'Аннулировано')
group by [ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee 

/*
-- Кол-во отказов 
drop table if exists #canceled_Qty_empl_2
select 
 		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
		,cast([Период_След] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) canceled_Qty_empl
		,status_first
		,[СтатусДляСостояния_След]
		,employee
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]
			 
into #canceled_Qty_empl_2
from #mt_requests_transition_fedor_prod 
where [СтатусДляСостояния_След] in ('Отказано' ,'Аннулировано')
group by 
--[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee 
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)
-- select * from #canceled_Qty_empl_2 where employee = ''

*/

-- Кол-во отложенных заявок на этапе
drop table if exists #postponed_Qty
select --count(distinct [ЗаявкаНомер_Исх]) postponed_Qty 
 		[ЗаявкаНомер_Исх]

		,cast([Период_Исх] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) postponed_Qty 
		,status_first
		,[СтатусДляСостояния_След]
		,employee	
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]

into #postponed_Qty
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('Отложена')
group by [ЗаявкаНомер_Исх] ,cast([Период_Исх] as date) ,status_first ,[СтатусДляСостояния_След] ,employee

/*
-- Кол-во отложенных заявок на этапе
drop table if exists #postponed_Qty_2
select --count(distinct [ЗаявкаНомер_Исх]) postponed_Qty 
 		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [pdt]
		,cast([Период_Исх] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) postponed_Qty 
		,status_first
		,[СтатусДляСостояния_След]
		,employee	
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]

into #postponed_Qty_2
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('Отложена')
group by 
--[ЗаявкаНомер_Исх] ,cast([Период_Исх] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_Исх] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)
-- select * from #postponed_Qty_2 where employee = ''


*/

-- Кол-во заявок, отправленных на доработку на этапе
drop table if exists #revision_Qty
select 
 		[ЗаявкаНомер_Исх]
		,cast([Период_След] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) revision_Qty 
		,status_first
		,[СтатусДляСостояния_След]
		,employee	
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]

into #revision_Qty
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('Требуется доработка')
group by [ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee 

/*
-- Кол-во заявок, отправленных на доработку на этапе
drop table if exists #revision_Qty_2
select 
 		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
		,cast([Период_След] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) revision_Qty 
		,status_first
		,[СтатусДляСостояния_След]
		,employee	
		,sum([ВремяЗатрачено]) [ВремяЗатрачено]

into #revision_Qty_2
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('Требуется доработка')
group by 
--[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee 
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)
-- select * from #postponed_Qty_2 where employee = ''

*/

-- Кол-во выданных займов
drop table if exists #Loans_Qty
select 
 		r.[ЗаявкаНомер_Исх]

		,cast([Период_След] as date) as [dt]
		--,
		,count(distinct r.[ЗаявкаНомер_Исх]) Loans_Qty
		,r.status_first
		,r.[СтатусДляСостояния_След]
		,r.employee 

into #Loans_Qty
from #mt_requests_transition_fedor_prod r
where r.[СтатусДляСостояния_След]='Заем выдан'
group by r.[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,r.status_first ,r.[СтатусДляСостояния_След] ,r.employee --,a.dt

--select * from #Loans_Qty
/*
-- Кол-во выданных займов
drop table if exists #Loans_Qty_2
select 
 		r.[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [pdt]
		,cast([Период_След] as date) as [dt]
		--,
		,count(distinct r.[ЗаявкаНомер_Исх]) Loans_Qty
		,r.status_first
		,r.[СтатусДляСостояния_След]
		,r.employee 

into #Loans_Qty_2
from #mt_requests_transition_fedor_prod r
where r.[СтатусДляСостояния_След]='Заем выдан'
group by 
--r.[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,r.status_first ,r.[СтатусДляСостояния_След] ,r.employee --,a.dt
grouping sets 
(
([ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
,([ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee)
)
-- select * from #Loans_Qty_2 where employee = ''

*/


-------------------------------------------------------------------------------

drop table if exists #Result_day
select	distinct
	[Дата]										= cast(t00.dt as date)
	,[Период]									= dateadd(month,datediff(month,0,t00.dt),0)
	,[Исполнитель]								= t0.employee
	,[Статус]									= t0.status_first
		--,[НомерЗаявки]							= t0.req
	,[Периодичность]							= 'День'

	,[Общее кол-во заведенных заявок]			= isnull((select sum(Qty) from #total_Qty_all where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
	,[Кол-во автоматических отказов]			= isnull((select sum(Qty) from #canceled_Qty_all where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
	,[%  автоматических отказов]				= case
													when isnull((select sum(Qty) from #total_Qty_all where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(sum(Qty) as float) from #canceled_Qty_all where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 / isnull((select cast(sum(Qty) as float) from #total_Qty_all where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end
	,[Кол-во уникальных заявок на этапе]		= isnull((select sum(uniq_Qty) from #uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
	,[Общее кол-во заявок на этапе]				= isnull((select sum(total_Qty) from #total_Qty_Status where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)

	,[TTY: % заявок рассмотренных в теч.10 мин]	= case
													when isnull((select sum(uniq_Qty) from #uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(count([ЗаявкаНомер_Исх]) as float) from #Qty_request_TTY10 where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(uniq_Qty) as float) from #uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end

	,[TTY: % заявок рассмотренных в теч.30 мин]	= case
													when isnull((select sum(uniq_Qty) from #uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(count([ЗаявкаНомер_Исх]) as float) from #Qty_request_TTY30 where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(uniq_Qty) as float) from #uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end


	,[Среднее время заявки в ожидании очереди]	= case
													when isnull((select sum(uniq_Qty) from #uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(sum([ВремяЗатрачено]) as float) from #Request_queue_time where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(uniq_Qty) as float) from #uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end 

	,[Ср.время заявки в ожидании очереди (Tm)]	= convert(nvarchar,cast((
												  case
													when isnull((select sum(uniq_Qty) from #uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(sum([ВремяЗатрачено]) as float) from #Request_queue_time where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(uniq_Qty) as float) from #uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end) as datetime) ,8)

	,[Средний Processing time на этапе (время)]	= case
													when isnull((select sum(total_Qty_res) from #total_Qty_res where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(sum([ВремяЗатрачено]) as float) from #Request_Processing_time where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(total_Qty_res) as float) from #total_Qty_res where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end

	,[Средний Processing time на этапе(Tm)]		= convert(nvarchar,cast((
												  case
													when isnull((select sum(total_Qty_res) from #total_Qty_res where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(sum([ВремяЗатрачено]) as float) from #Request_Processing_time where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(total_Qty_res) as float) from #total_Qty_res where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end) as datetime)  ,8)

	,[Кол-во одобренных заявок после этапа]		= isnull((select sum(appr_Qty) from #appr_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
	,[Кол-во отказов со стороны сотрудников]	= isnull((select sum(canceled_Qty_empl) from #canceled_Qty_empl where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)

	,[Approval rate - % одобренных после этапа]	= case
													when isnull((select sum(uniq_Qty) from #uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(sum(appr_Qty) as float) from #appr_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(uniq_Qty) as float) from #uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end

	,[Кол-во отложенных заявок на этапе]		= isnull((select sum(postponed_Qty) from #postponed_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
	,[Кол-во заявок, отправленных на доработку]	= isnull((select sum(revision_Qty) from #revision_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)


	,[Take rate Уровень выдачи,через одобрения]	= case
													when isnull((select sum(appr_Qty) from #appr_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(sum(Loans_Qty) as float) from #Loans_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(appr_Qty) as float) from #appr_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end

into #Result_day
from #calendar_day t00
left join #user_status_on_day t0 on t00.dt=t0.dt
where not t0.employee is null

--select * from #Result_day 
----------------------------------------------
--------------РАСЧЕТ ПО ДНЯМ. КОНЕЦ-----------
----------------------------------------------



----------------------------------------------
--------------РАСЧЕТ ПО МЕСЯЦАМ. НАЧАЛО-------
----------------------------------------------

drop table if exists #user_status_on_month
select distinct
		dateadd(month,datediff(month,0,[Период_Исх]),0) dt
		,employee
		,status_first
into #user_status_on_month
from #mt_requests_transition_fedor_prod e
where status_first<>'Черновик'



---- Дата и Время в статусе первой руки в работу 
drop table if exists #m_Request_dt_firsthands
select t.*
into #m_Request_dt_firsthands
from (
select 
		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [dt_firsthands]
		,[Период_Исх]		
		,status_first
		,employee
		,rank() over(partition by [ЗаявкаНомер_Исх] ,status_first order by [Период_Исх]) r

from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in (N'task:В работе')
) t
where t.r = 1
--select * from #Request_dt_firsthands


---- Дата и Время в статусе последней руки из работы 
drop table if exists #m_Request_dt_lasthands
select t.*
into #m_Request_dt_lasthands
from (
select 
		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [dt_lasthands]
		,status_first
		,employee
		,rank() over(partition by [ЗаявкаНомер_Исх] ,status_first order by [Период_Исх] desc) [r]

from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in (N'task:В работе') and [ЗадачаСтатуса_След] in (N'task:Выполнена')
) t
where t.r = 1
-- select * from #Request_dt_lasthands

--------------------------------------
--------------------------------------
--------------------------------------
---- Общее кол-во заведенных заявок
drop table if exists #m_total_Qty_all
select 
		[ЗаявкаНомер_Исх] 
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [dt]
		,count(*) Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
into #m_total_Qty_all		 
from #mt_requests_transition_fedor_prod 
where [СтатусДляСостояния_След] in (N'Предварительное одобрение' ,N'Верификация Call 1.5',N'Верификация Call 2',N'Верификация Call 3')
group by [ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee
--select * from #total_Qty_all


-- кол-во автоматических отказов на этапах
drop table if exists #m_canceled_Qty_all
select --count(*)
		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [dt]
		,count(*) Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
into #m_canceled_Qty_all 
from #mt_requests_transition_fedor_prod 
where [СтатусДляСостояния_След] in ('Отказано' ,'Отказ документов клиента')
group by [ЗаявкаНомер_Исх]  ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee


-- Уникальное кол-во заявок на этапе
drop table if exists #m_uniq_Qty
select --count(distinct [ЗаявкаНомер_Исх]) uniq_Qty
		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) uniq_Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
			 
into #m_uniq_Qty
from #mt_requests_transition_fedor_prod where [ЗадачаСтатуса_Исх] = 'task:Новая'
group by [ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee


-- Общее кол-во заявок на этапе
drop table if exists #m_total_Qty_Status
select 
		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [dt]
		,count(*) total_Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee		
into #m_total_Qty_Status  
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('task:Новая' ,'task:Вернулась из отложенных' ,'task:Вернулась с доработки')
group by [ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee
--select * from #total_Qty_Status where employee = 'АЗАРОВА СВЕТЛАНА ВИКТОРОВНА' and dt='2020-02-21'


-- Общее кол-во заявок выполненных на этапе
drop table if exists #m_total_Qty_res
select --count(*) total_Qty_res
		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [dt]
		,count(*) total_Qty_res
		,status_first
		,[СтатусДляСостояния_След]
		,employee
into #m_total_Qty_res  
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('task:Выполнена')
group by [ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee


-- Кол-во Заявок TTY время рассмотрения заявок меньше 10 минут
drop table if exists #m_Qty_request_TTY10
select t.* 
into #m_Qty_request_TTY10
from (
		select 
				[ЗаявкаНомер_Исх]
				,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [dt]
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]
				,status_first
				,[СтатусДляСостояния_След]
				,employee				 
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:В работе')
		group by [ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee
	 ) t
where [ВремяЗатрачено] <= 0.00695 -- это 10 минут

-- Кол-во Заявок TTY время рассмотрения заявок меньше 30 минут
drop table if exists #m_Qty_request_TTY30
select t.* 
into #m_Qty_request_TTY30
from (
		select 
				[ЗаявкаНомер_Исх]
				,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [dt]
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]
				,status_first
				,[СтатусДляСостояния_След]
				,employee				 
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:В работе')
		group by [ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee
	 ) t
where [ВремяЗатрачено] <= 0.02083 -- это 30 минут

-- время заявки в ожидании очереди /*Среднее время заявки в ожидании очереди (Average queue time) на этапе */
drop table if exists #m_Request_queue_time --#AVG_queue_time
select t.*	--t.[ВремяЗатрачено]/ (select * from #uniq_Qty) AVG_queue_time
into #m_Request_queue_time
from (
		select 
				[ЗаявкаНомер_Исх]
				,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [dt]
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]
				,status_first
				,[СтатусДляСостояния_След]
				,employee					
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:Новая' ,'task:Вернулась из отложенных' ,'task:Вернулась с доработки')
		group by [ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee 
	 ) t


-- Средний Processing time на этапе (время обработки заявки)
drop table if exists #m_Request_Processing_time
select	t.*	--t.[ВремяЗатрачено]/ (select * from #total_Qty_res) AVG_queue_time
into #m_Request_Processing_time	--#AVG_Processing_time
from (
		select --sum([ВремяЗатрачено]) [ВремяЗатрачено]
				[ЗаявкаНомер_Исх]
				,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [dt]
				,sum([ВремяЗатрачено]) [ВремяЗатрачено]
				,status_first
				,[СтатусДляСостояния_След]
				,employee	
		from #mt_requests_transition_fedor_prod 
		where [ЗадачаСтатуса_Исх] in ('task:В работе' ,'task:Отложена' ,'task:Требуется доработка') 
		group by [ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee 
		) t


-- Кол-во одобренных заявок после этапа
drop table if exists #m_appr_Qty
select 
		r.[ЗаявкаНомер_Исх]
		,case 
			when not lh.dt_lasthands is null 
				then lh.dt_lasthands 
			else case 
					when not fh.dt_firsthands is null 
						then fh.dt_firsthands 
					else cast(dateadd(month,datediff(month,0,r.[Период_Исх]),0) as date) 
				end 
		end  as [dt]
		,count(distinct r.[ЗаявкаНомер_Исх]) appr_Qty
		,r.status_first
		,[СтатусДляСостояния_След]
		,r.employee	 
into #m_appr_Qty
from #mt_requests_transition_fedor_prod r

left join #Request_dt_lasthands lh on  r.[ЗаявкаНомер_Исх] = lh.ЗаявкаНомер_Исх and r.status_first = lh.status_first and r.employee = lh.employee 
left join #Request_dt_firsthands fh on  r.[ЗаявкаНомер_Исх] = fh.ЗаявкаНомер_Исх and r.status_first = fh.status_first and r.employee = fh.employee

where [ЗадачаСтатуса_Исх] = 'task:Выполнена' and not [СтатусДляСостояния_След] in ('Отказано' ,'Аннулировано') and r.status_first<>'Черновик'
group by r.[ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,r.[Период_Исх]),0) as date) ,r.status_first ,[СтатусДляСостояния_След] ,r.employee ,lh.dt_lasthands ,fh.dt_firsthands
--select * from #appr_Qty


-- Кол-во отказов 
drop table if exists #m_canceled_Qty_empl
select 
 		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) canceled_Qty_empl
		,status_first
		,[СтатусДляСостояния_След]
		,employee
			 
into #m_canceled_Qty_empl
from #mt_requests_transition_fedor_prod 
where [СтатусДляСостояния_След] in ('Отказано' ,'Аннулировано')
group by [ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee 


-- Кол-во отложенных заявок на этапе
drop table if exists #m_postponed_Qty
select 
 		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) postponed_Qty 
		,status_first
		,[СтатусДляСостояния_След]
		,employee	
into #m_postponed_Qty
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('Отложена')
group by [ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee


-- Кол-во заявок, отправленных на доработку на этапе
drop table if exists #m_revision_Qty
select 
 		[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) revision_Qty 
		,status_first
		,[СтатусДляСостояния_След]
		,employee	
into #m_revision_Qty
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('Требуется доработка')
group by [ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_Исх]),0) as date) ,status_first ,[СтатусДляСостояния_След] ,employee 



-- Кол-во выданных займов
drop table if exists #m_Loans_Qty
select 
 		r.[ЗаявкаНомер_Исх]
		,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) as [dt]
		,count(distinct r.[ЗаявкаНомер_Исх]) Loans_Qty
		,r.status_first
		,r.[СтатусДляСостояния_След]
		,r.employee 
into #m_Loans_Qty
from #mt_requests_transition_fedor_prod r
where r.[СтатусДляСостояния_След]='Заем выдан'
group by r.[ЗаявкаНомер_Исх] ,cast(dateadd(month,datediff(month,0,[Период_След]),0) as date) ,r.status_first ,r.[СтатусДляСостояния_След] ,r.employee --,a.dt

--select * from #Loans_Qty


---------------------------------------------------------------------------------

drop table if exists #Result_month
select	distinct
	[Дата]										= cast(t00.dt as date)
	,[Период]									= dateadd(month,datediff(month,0,t00.dt),0)
	,[Исполнитель]								= t0.employee
	,[Статус]									= t0.status_first
		--,[НомерЗаявки]							= t0.req
	,[Периодичность]							= 'Месяц'
	
	,[Общее кол-во заведенных заявок]			= isnull((select sum(Qty) from #m_total_Qty_all where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
	,[Кол-во автоматических отказов]			= isnull((select sum(Qty) from #m_canceled_Qty_all where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
	,[%  автоматических отказов]				= case
													when isnull((select sum(Qty) from #m_total_Qty_all where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(sum(Qty) as float) from #m_canceled_Qty_all where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 / isnull((select cast(sum(Qty) as float) from #m_total_Qty_all where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end
	,[Кол-во уникальных заявок на этапе]		= isnull((select sum(uniq_Qty) from #m_uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
	,[Общее кол-во заявок на этапе]				= isnull((select sum(total_Qty) from #m_total_Qty_Status where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)

	,[TTY: % заявок рассмотренных в теч.10 мин]	= case
													when isnull((select sum(uniq_Qty) from #m_uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(count([ЗаявкаНомер_Исх]) as float) from #m_Qty_request_TTY10 where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(uniq_Qty) as float) from #m_uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end

	,[TTY: % заявок рассмотренных в теч.30 мин]	= case
													when isnull((select sum(uniq_Qty) from #m_uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(count([ЗаявкаНомер_Исх]) as float) from #m_Qty_request_TTY30 where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(uniq_Qty) as float) from #m_uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end

	,[Среднее время заявки в ожидании очереди]	= case
													when isnull((select sum(uniq_Qty) from #m_uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(sum([ВремяЗатрачено]) as float) from #m_Request_queue_time where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(uniq_Qty) as float) from #m_uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end 

	,[Ср.время заявки в ожидании очереди (Tm)]	= convert(nvarchar,cast((
												  case
													when isnull((select sum(uniq_Qty) from #m_uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(sum([ВремяЗатрачено]) as float) from #m_Request_queue_time where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(uniq_Qty) as float) from #m_uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end) as datetime) ,8)

	,[Средний Processing time на этапе (время)]	= case
													when isnull((select sum(total_Qty_res) from #m_total_Qty_res where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(sum([ВремяЗатрачено]) as float) from #m_Request_Processing_time where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(total_Qty_res) as float) from #m_total_Qty_res where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end

	,[Средний Processing time на этапе(Tm)]		= convert(nvarchar,cast((
												  case
													when isnull((select sum(total_Qty_res) from #m_total_Qty_res where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(sum([ВремяЗатрачено]) as float) from #m_Request_Processing_time where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(total_Qty_res) as float) from #m_total_Qty_res where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end) as datetime)  ,8)

	,[Кол-во одобренных заявок после этапа]		= isnull((select sum(appr_Qty) from #m_appr_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
	,[Кол-во отказов со стороны сотрудников]	= isnull((select sum(canceled_Qty_empl) from #m_canceled_Qty_empl where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)

	,[Approval rate - % одобренных после этапа]	= case
													when isnull((select sum(uniq_Qty) from #m_uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(sum(appr_Qty) as float) from #m_appr_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(uniq_Qty) as float) from #m_uniq_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end

	,[Кол-во отложенных заявок на этапе]		= isnull((select sum(postponed_Qty) from #m_postponed_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
	,[Кол-во заявок, отправленных на доработку]	= isnull((select sum(revision_Qty) from #m_revision_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)


	,[Take rate Уровень выдачи,через одобрения]	= case
													when isnull((select sum(appr_Qty) from #m_appr_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)<>0
													then (isnull((select cast(sum(Loans_Qty) as float) from #m_Loans_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)
														 /isnull((select cast(sum(appr_Qty) as float) from #m_appr_Qty where employee=t0.employee and dt=t00.dt and status_first=t0.status_first),0)) * 100
													else 0.00
												  end

into #Result_month
from #calendar_month t00
left join #user_status_on_month t0 on t00.dt=t0.dt
where not t0.employee is null
--COLLATE Cyrillic_General_CI_AS




----------------------------------------------
--------------РАСЧЕТ ПО МЕСЯЦАМ. КОНЕЦ--------
----------------------------------------------

drop table if exists #Result
select * 
into #Result
from #Result_day
union all
select * from #Result_month
/*
select * 
from #Result_day order by 1 desc

select * 
from #Result_month order by 1 desc

select * 
from #Result order by 1 desc
*/

drop table if exists #Result_col
select  [НомерСтрокиОтчета] = 1
		,[Дата] ,[Период] ,[Исполнитель]	,[Статус] ,[Периодичность]
		,'Общее кол-во заведенных заявок' [Indicator]
		,[Общее кол-во заведенных заявок]
into #Result_col
from #Result

union all
select  [НомерСтрокиОтчета] = 2
		,[Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
		,'Кол-во автоматических отказов' [Indicator]
		,[Кол-во автоматических отказов]
from #Result

union all
select  [НомерСтрокиОтчета] = 3
		,[Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
		,'%  автоматических отказов' [Indicator]
		,[%  автоматических отказов]
from #Result

union all
select  [НомерСтрокиОтчета] = 4
		,[Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
		,'[Кол-во уникальных заявок на этапе]' [Indicator]
		,[Кол-во уникальных заявок на этапе]
from #Result

union all
select  [НомерСтрокиОтчета] = 5
		,[Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
		,'[Общее кол-во заявок на этапе]' [Indicator]
		,[Общее кол-во заявок на этапе]
from #Result
----------------
-- 6 - 7
----------------
union all
select  [НомерСтрокиОтчета] = 8
		,[Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
		,'[TTY: % заявок рассмотренных в теч.30 мин]' [Indicator]
		,[TTY: % заявок рассмотренных в теч.30 мин]
from #Result

union all
select  [НомерСтрокиОтчета] = 9
		,[Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
		,'[TTY: % заявок рассмотренных в теч.10 мин]' [Indicator]
		,[TTY: % заявок рассмотренных в теч.10 мин]
from #Result

union all

select  [НомерСтрокиОтчета] = 10
		,[Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
		,'[Среднее время заявки в ожидании очереди]' [Indicator]
		,[Среднее время заявки в ожидании очереди]
from #Result

----------------
-- 11
----------------

/*
union all
select  [Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
		,'[Ср.время заявки в ожидании очереди (Tm)]' [Indicator]
		,[Ср.время заявки в ожидании очереди (Tm)]
from #Result
*/
union all
select  [НомерСтрокиОтчета] = 12
		,[Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
		,'[Средний Processing time на этапе (время)]' [Indicator]
		,[Средний Processing time на этапе (время)]
from #Result

----------------
-- 13 - 14
----------------

union all
select  [НомерСтрокиОтчета] = 15
		,[Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
		,'[Кол-во одобренных заявок после этапа]' [Indicator]
		,[Кол-во одобренных заявок после этапа]
from #Result

----------------
-- 16 - 17
----------------

union all
select  [НомерСтрокиОтчета] = 18
		,[Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
		,'[Кол-во отказов со стороны сотрудников]' [Indicator]
		,[Кол-во отказов со стороны сотрудников]
from #Result

----------------
-- 19 - 20
----------------

union all
select  [НомерСтрокиОтчета] = 21
		,[Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
		,'[Approval rate - % одобренных после этапа]' [Indicator]
		,[Approval rate - % одобренных после этапа]
from #Result

----------------
-- 22 - 24
----------------

union all
select  [НомерСтрокиОтчета] = 25
		,[Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
		,'[Кол-во отложенных заявок на этапе]' [Indicator]
		,[Кол-во отложенных заявок на этапе]
from #Result

----------------
-- 26 - 27
----------------

union all
select  [НомерСтрокиОтчета] = 28
		,[Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
		,'[Кол-во заявок, отправленных на доработку]' [Indicator]
		,[Кол-во заявок, отправленных на доработку]
from #Result

----------------
-- 29 - 30
----------------

union all
select  [НомерСтрокиОтчета] = 31
		,[Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
		,'[Take rate Уровень выдачи,через одобрения]' [Indicator]
		,[Take rate Уровень выдачи,через одобрения]
from #Result

select * from #Result

select * from #Result_col


*/
