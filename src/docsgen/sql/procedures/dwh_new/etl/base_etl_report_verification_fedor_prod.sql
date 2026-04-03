
-- =============================================
-- Author:		Курдин С.В.
-- Create date: 2020-01-30
-- Description:	Создание основной таблицы для отчета для Верификации из ФЕДОРА
-- exec [etl].[base_etl_report_verification_fedor]
-- =============================================

CREATE PROCEDURE [etl].[base_etl_report_verification_fedor_prod]
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
,(4 ,'Общее кол-во уникальных заявок на верификации')
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
,(16 ,'Кол-во одобренных займов после верификации на этапе Верификация клиентов')
,(17 ,'Кол-во одобренных займов после верификации на этапе Верификация ТС')
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
from [dwh_new].[dbo].[mt_requests_transition_fedor_prod] with (nolock)
 where not [СтатусДляСостояния_След] is null

 union all
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

      ,'' employee
      ,'' [ИсполнительНаим_След]
      ,[ВремяЗатрачено]

      ,[ПричинаНаим_Исх]
      ,[ПричинаНаим_След]
	  ,[Tm]
	  ,'Месяц' [Периодичность] 
from [dwh_new].[dbo].[mt_requests_transition_fedor_prod] with (nolock)
 where not [СтатусДляСостояния_След] is null

 
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


---- Общее кол-во заведенных заявок
drop table if exists #total_Qty_all
select 
		[ЗаявкаНомер_Исх]
		,cast([Период_След] as date) as [dt]
		,count(*) Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
into #total_Qty_all		 
from #mt_requests_transition_fedor_prod 
where [СтатусДляСостояния_След] in (N'Предварительное одобрение' ,N'Верификация Call 1.5',N'Верификация Call 2',N'Верификация Call 3')
group by [ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
--select * from #total_Qty_all


-- кол-во автоматических отказов на этапах
drop table if exists #canceled_Qty_all
select --count(*)
		[ЗаявкаНомер_Исх]
		,cast([Период_След] as date) as [dt]
		,count(*) Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
into #canceled_Qty_all 
from #mt_requests_transition_fedor_prod 
where [СтатусДляСостояния_След] in ('Отказано' ,'Отказ документов клиента')
group by [ЗаявкаНомер_Исх]  ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee


-- Уникальное кол-во заявок на этапе
drop table if exists #uniq_Qty
select --count(distinct [ЗаявкаНомер_Исх]) uniq_Qty
		[ЗаявкаНомер_Исх]
		,cast([Период_След] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) uniq_Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee
			 
into #uniq_Qty
from #mt_requests_transition_fedor_prod where [ЗадачаСтатуса_Исх] = 'task:Новая'
group by [ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee


-- Общее кол-во заявок на этапе
drop table if exists #total_Qty_Status
select 
		[ЗаявкаНомер_Исх]
		,cast([Период_След] as date) as [dt]
		,count(*) total_Qty
		,status_first
		,[СтатусДляСостояния_След]
		,employee		
into #total_Qty_Status  
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('task:Новая' ,'task:Вернулась из отложенных' ,'task:Вернулась с доработки')
group by [ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee
--select * from #total_Qty_Status where employee = 'АЗАРОВА СВЕТЛАНА ВИКТОРОВНА' and dt='2020-02-21'


-- Общее кол-во заявок выполненных на этапе
drop table if exists #total_Qty_res
select --count(*) total_Qty_res
		[ЗаявкаНомер_Исх]
		,cast([Период_Исх] as date) as [dt]
		,count(*) total_Qty_res
		,status_first
		,[СтатусДляСостояния_След]
		,employee
into #total_Qty_res  
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('task:Выполнена')
group by [ЗаявкаНомер_Исх] ,cast([Период_Исх] as date) ,status_first ,[СтатусДляСостояния_След] ,employee


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
where [ВремяЗатрачено] <= 0.02083 -- это 10 минут


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


-- Кол-во одобренных заявок после этапа
drop table if exists #appr_Qty
select 
		r.[ЗаявкаНомер_Исх]
		,case when not lh.dt_lasthands is null then lh.dt_lasthands else case when not fh.dt_firsthands is null then fh.dt_firsthands else cast([Период_След] as date) end end  as [dt]
		,count(distinct r.[ЗаявкаНомер_Исх]) appr_Qty
		,r.status_first
		,[СтатусДляСостояния_След]
		,r.employee	 
into #appr_Qty
from #mt_requests_transition_fedor_prod r

left join #Request_dt_lasthands lh on  r.[ЗаявкаНомер_Исх] = lh.ЗаявкаНомер_Исх and r.status_first = lh.status_first and r.employee = lh.employee 
left join #Request_dt_firsthands fh on  r.[ЗаявкаНомер_Исх] = fh.ЗаявкаНомер_Исх and r.status_first = fh.status_first and r.employee = fh.employee

where [ЗадачаСтатуса_Исх] = 'task:Выполнена' and not [СтатусДляСостояния_След] in ('Отказано' ,'Аннулировано') and r.status_first<>'Черновик'
group by r.[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,r.status_first ,[СтатусДляСостояния_След] ,r.employee ,lh.dt_lasthands ,fh.dt_firsthands
--select * from #appr_Qty


-- Кол-во отказов 
drop table if exists #canceled_Qty_empl
select 
 		[ЗаявкаНомер_Исх]
		,cast([Период_След] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) canceled_Qty_empl
		,status_first
		,[СтатусДляСостояния_След]
		,employee
			 
into #canceled_Qty_empl
from #mt_requests_transition_fedor_prod 
where [СтатусДляСостояния_След] in ('Отказано' ,'Аннулировано')
group by [ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee 


-- Кол-во отложенных заявок на этапе
drop table if exists #postponed_Qty
select --count(distinct [ЗаявкаНомер_Исх]) postponed_Qty 
 		[ЗаявкаНомер_Исх]
		,cast([Период_Исх] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) postponed_Qty 
		,status_first
		,[СтатусДляСостояния_След]
		,employee	
into #postponed_Qty
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('Отложена')
group by [ЗаявкаНомер_Исх] ,cast([Период_Исх] as date) ,status_first ,[СтатусДляСостояния_След] ,employee


-- Кол-во заявок, отправленных на доработку на этапе
drop table if exists #revision_Qty
select 
 		[ЗаявкаНомер_Исх]
		,cast([Период_След] as date) as [dt]
		,count(distinct [ЗаявкаНомер_Исх]) revision_Qty 
		,status_first
		,[СтатусДляСостояния_След]
		,employee	
into #revision_Qty
from #mt_requests_transition_fedor_prod 
where [ЗадачаСтатуса_Исх] in ('Требуется доработка')
group by [ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,status_first ,[СтатусДляСостояния_След] ,employee 


-- Кол-во выданных займов
drop table if exists #Loans_Qty
select 
 		r.[ЗаявкаНомер_Исх]
		,cast([Период_След] as date) as [dt]
		,count(distinct r.[ЗаявкаНомер_Исх]) Loans_Qty
		,r.status_first
		,r.[СтатусДляСостояния_След]
		,r.employee 
into #Loans_Qty
from #mt_requests_transition_fedor_prod r
where r.[СтатусДляСостояния_След]='Заем выдан'
group by r.[ЗаявкаНомер_Исх] ,cast([Период_След] as date) ,r.status_first ,r.[СтатусДляСостояния_След] ,r.employee --,a.dt

--select * from #Loans_Qty

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

/*
drop table if exists #tttt
select * 
[period]  
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
,[State_next]
into #tttt
from #Result_col



--if (select Qty_dt from #Qty_requst_start) = (select Qty_dt from #Qty_requst_finish) and (select min_dt from #Qty_requst_start) = @rdate  
--begin
	begin tran

	delete 
	--select *
	from [dwh_new].[dbo].[mt_report_verification_fedor_prod_1] 
	 --where [accdate]>= @StartDate --  [begindate] >= @StartDate

	insert into [dwh_new].[dbo].[mt_report_verification_fedor_prod_1]  ([period]  
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
	--into [dwh_new].[dbo].[mt_report_verification_fedor]   
	from #verification_table
	where [accdate]>= @StartDate

	commit tran

--end




/*
drop table if exists #Table_Indicator
select * --[name] ,[collation_name] 
--into #Table_Indicator 
from tempdb.sys.columns
where object_id = OBJECT_ID('tempdb..#Result')

alter table #Result column [Общее кол-во заведенных заявок] int COLLATE Cyrillic_General_CI_AS

select [name] ,[collation_name] 
--into #Table_Indicator 
from tempdb.sys.columns
where object_id = OBJECT_ID('tempdb..#Result')

drop table if exists #Table_Column

select 
	[Общее кол-во заведенных заявок] [1]
	,[Кол-во автоматических отказов] [2]
	,[%  автоматических отказов] [3]
	,[Кол-во уникальных заявок на этапе] [4]
	,[Общее кол-во заявок на этапе] [5]
	,[TTY: % заявок рассмотренных в теч.10 мин] [6]
	,[Среднее время заявки в ожидании очереди] [7]
	,[Ср.время заявки в ожидании очереди (Tm)] [8]
	,[Средний Processing time на этапе (время)] [9]
	,[Средний Processing time на этапе(Tm)] [10]
	,[Кол-во одобренных заявок после этапа] [11]
	,[Кол-во отказов со стороны сотрудников] [12]
	,[Approval rate - % одобренных после этапа] [13]
	,[Кол-во отложенных заявок на этапе] [14]
	,[Кол-во заявок, отправленных на доработку] [15]
	,[Take rate Уровень выдачи,через одобрения] [16]
into #Table_Column
from #Table_Indicator where not [name] in ('Дата' ,'Период' ,'Исполнитель' ,'Статус' ,'Периодичность')

select [Дата] ,[Период] ,[Исполнитель] ,[Статус] ,[Периодичность]
	,[Общее кол-во заведенных заявок]
	,[Кол-во автоматических отказов]
	--,[%  автоматических отказов]
	,[Кол-во уникальных заявок на этапе]
	,[Общее кол-во заявок на этапе]
	--,[TTY: % заявок рассмотренных в теч.10 мин]
	--,[Среднее время заявки в ожидании очереди]
	--,[Ср.время заявки в ожидании очереди (Tm)]
	--,[Средний Processing time на этапе (время)]
	--,[Средний Processing time на этапе(Tm)]
	--,[Кол-во одобренных заявок после этапа]
	--,[Кол-во отказов со стороны сотрудников]
	--,[Approval rate - % одобренных после этапа]
	--,[Кол-во отложенных заявок на этапе]
	--,[Кол-во заявок, отправленных на доработку]
	--,[Take rate Уровень выдачи,через одобрения] 
from #Result
unpivot (
		[Value] for column_name in (
		collate Cyrillic_General_CI_AS [Общее кол-во заведенных заявок]
	,[Кол-во автоматических отказов]
	--,[%  автоматических отказов]
	,[Кол-во уникальных заявок на этапе]
	,[Общее кол-во заявок на этапе]
	--,[TTY: % заявок рассмотренных в теч.10 мин]
	--,[Среднее время заявки в ожидании очереди]
	--,[Ср.время заявки в ожидании очереди (Tm)]
	--,[Средний Processing time на этапе (время)]
	--,[Средний Processing time на этапе(Tm)]
	--,[Кол-во одобренных заявок после этапа]
	--,[Кол-во отказов со стороны сотрудников]
	--,[Approval rate - % одобренных после этапа]
	--,[Кол-во отложенных заявок на этапе]
	--,[Кол-во заявок, отправленных на доработку]
	--,[Take rate Уровень выдачи,через одобрения] 
	)
		) as unpvt
*/
/*
select [] 
from #Table_Indicator t
cross (select [Дата] ,[] from #Result) r

from #Result r
from 
*/


------------------------------------------------------------
------------------ НОВЫЙ АЛГОРИТМ---------------------------
------------------------------------------------------------

------------------------------------------------------------
drop table if exists #dm_Verification_001_actual_new
select 
	   [ЗаявкаНомер_Исх]

      ,status_first as [СтатусДляСостояния_Исх]
      ,[СтатусДляСостояния_След]
	  ,[ЗадачаСтатуса_Исх]
	  ,[ЗадачаСтатуса_След]
      ,[СостояниеЗаявки_Исх]
      ,[СостояниеЗаявки_След]

      ,[Период_Исх]
      ,[Период_След]

      ,[СтатусНаим_Исх]
      ,[СтатусНаим_След]

      ,employee as [ИсполнительНаим_Исх]
      ,[ИсполнительНаим_След]
      ,[ВремяЗатрачено]

      ,[ПричинаНаим_Исх]
      ,[ПричинаНаим_След]
	  ,[Tm]
	  
into #dm_Verification_001_actual_new
from #mt_requests_transition_fedor_prod
--from Reports.[dbo].[dm_Verification_fedor_prod_001_actual] with (nolock)
where cast([Период_Исх] as date)>=@StartDate
--select * from Reports.[dbo].[dm_Verification_fedor_001_actual] where [ЗаявкаНомер_Исх]='20012910000056'
-- select * from #dm_Verification_001_actual_new order by 1 desc ,8 desc

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
	from [dwh_new].[dbo].[mt_report_verification_fedor] 
	 --where [accdate]>= @StartDate --  [begindate] >= @StartDate

	insert into [dwh_new].[dbo].[mt_report_verification_fedor]  ([period]  
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
	--into [dwh_new].[dbo].[mt_report_verification_fedor]   
	from #verification_table
	where [accdate]>= @StartDate

	commit tran

end

--   select count(*) from [dwh_new].[dbo].[mt_report_verification_fedor]
--drop table [dwh_new].[dbo].[mt_report_verification_fedor]
--alter table [dwh_new].[dbo].[mt_report_verification_fedor] add [fio_client] nvarchar(255) null
*/
END

