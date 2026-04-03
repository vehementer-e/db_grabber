

-- exec [etl].[base_etl_mt_requests_transition_fedor] --1

CREATE PROCEDURE [etl].[base_etl_mt_requests_transition_fedor_UAT]
	-- Add the parameters for the stored procedure here


--@param int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--declare @param int
--set @param = 1

if object_id('tempdb.dbo.#tmp') is not null drop table #tmp;

declare @DateStart datetime,
		@DateStart2 datetime,
		@DateStart2000 datetime,
		@DateStartCurr datetime,
		@DateStartCurr2000 datetime
set @DateStart = dateadd(MONTH,datediff(MONTH,0,dateadd(month,-43,Getdate())),0);
set	@DateStart2=dateadd(year,2000,@DateStart);
set @DateStart2000= dateadd(day,datediff(day,0,dateadd(year,2000,dateadd(day,-20,Getdate()))),0);

/*
if @param = 1  --2 -- Переменная для запуска в 23 часа для начала (дня) оперативного обновления данных по периоду статуса за последние 4 месяца
	begin 
		set @DateStartCurr = dateadd(month,-3,dateadd(month,datediff(month,0,Getdate()),0)); /*dateadd(month,-3,dateadd(month,datediff(month,0,Getdate()),0));*/
		set @DateStartCurr2000 = dateadd(month,-3,dateadd(month,datediff(month,0,dateadd(year,2000,Getdate())),0))	;
	end;				

if @param = 2  --2 -- Переменная для запуска в для начала (дня) оперативного обновления данных
	begin 
		set @DateStartCurr = dateadd(month,-3,dateadd(month,datediff(month,0,Getdate()),0)); /*dateadd(month,-3,dateadd(month,datediff(month,0,Getdate()),0));*/
		set @DateStartCurr2000 = dateadd(month,-3,dateadd(month,datediff(month,0,dateadd(year,2000,Getdate())),0))	;
	end;

/*
if @param = 3  --1 -- Переменная для запуска в для начала (дня) оперативного обновления данных по периоду статуса за последние 15 дней
	begin 
		set @DateStartCurr = dateadd(day,-31,dateadd(day,datediff(day,0,Getdate()),0));
		set @DateStartCurr2000 = dateadd(day,-31,dateadd(day,datediff(day,0,dateadd(year,2000,Getdate())),0));
	end;					
*/
*/

-------------- Таблица задача - состояние
drop table if exists #Task_State
create table #Task_State ([id] int null ,[Task] nvarchar(50) null ,[State] nvarchar(50) null)
insert into #Task_State
values
 (2,'В работе', 'В работе')
,(8,'Вернулась из отложенных', 'Ожидание')
,(7,'Вернулась с доработки', 'Ожидание')
,(5,'Выполнена', 'Выполнена')
,(1,'Новая', 'Ожидание')
,(3,'Отложена', 'Отложена')
,(4,'Отменена', 'Отменена')
,(9,'Переназначена', 'Ждет Исполнителя')
,(6,'Требуется доработка', 'Отложена')


-------------- временные таблицы
drop table if exists #core_ClientRequest
select  * 
into #core_ClientRequest
from stg.[_fedor].[core_ClientRequest]
-- select * from #core_ClientRequest

drop table if exists #dictionary_ClientRequestStatus
select  * 
into #dictionary_ClientRequestStatus
from stg.[_fedor].[dictionary_ClientRequestStatus] --where not idexternal is null



drop table if exists #dictionary_TaskStatus
select  * 
into #dictionary_TaskStatus
from stg.[_fedor].[dictionary_TaskStatus] /* ('Отложена' ,'Отменена' ,'Требуется доработка') */
where IsDeleted = 0
--select * from #dictionary_TaskStatus

drop table if exists #core_Task
select  * 
into #core_Task
from stg.[_fedor].[core_Task]
where IsDeleted = 0

drop table if exists #core_TaskAndClientRequest
select  * 
into #core_TaskAndClientRequest
from stg.[_fedor].[core_TaskAndClientRequest]
where IsDeleted = 0
--select * from #core_TaskAndClientRequest 


drop table if exists #core_user
select  * 
into #core_user
from stg.[_fedor].[core_user]
where IsDeleted = 0
--select * from #core_user

drop table if exists #core_TaskAssignUser
select  * 
into #core_TaskAssignUser
from stg.[_fedor].[core_TaskAssignUser]
where IsDeleted = 0 
--select * from #core_TaskAssignUser

--select  u.* ,t.* from #core_TaskAssignUser t
--left join #core_user u on t.IdUser=u.Id


---- задачи за последние 90 дней за выбранный период
drop table if exists #core_TaskHistory
select  *
into #core_TaskHistory
from stg.[_fedor].[core_TaskHistory] 
where IsDeleted = 0
--where [CreatedOn] >= dateadd(day,-90,dateadd(day,datediff(day,0,Getdate()),0))

--select * from #core_TaskHistory order by 2 asc



---- связываем задачи с номерами заявок
drop table if exists #pre_request_list_task
select  distinct
		cr.Id as [ЗаявкаСсылка]
		,cr.number as [ЗаявкаНомер]
		,th.Idtask as [ЗадачаСсылка]  
into #pre_request_list_task 
from #core_TaskHistory th
left join #core_Task t on t.id=th.Idtask
left join #core_TaskAndClientRequest tcr on  tcr.IdTask=t.id
left join #core_ClientRequest cr  on cr.Id=tcr.IdClientRequest
where th.IsDeleted = 0  and
	  th.Idtask in (select distinct 
							Idtask 
					from #core_TaskHistory 
					--where [CreatedOn] >= dateadd(day,-14,dateadd(day,datediff(day,0,Getdate()),0))
					)

--select * from #pre_request_list_task



---- заявки за выбранный период
drop table if exists #core_ClientRequestHistory
select  * 
into #core_ClientRequestHistory 
from stg.[_fedor].[core_ClientRequestHistory]
where IsDeleted = 0 
--where [CreatedOn] >= dateadd(day,-90,dateadd(day,datediff(day,0,Getdate()),0))

 --select * from #core_ClientRequestHistory


--------  заявок
drop table if exists #pre_request_list
select distinct
	   
	   crh.IdClientRequest as [ЗаявкаСсылка]
	  ,cr.number as [ЗаявкаНомер]
	  ,null as [ЗадачаСсылка]

into #pre_request_list 
from #core_ClientRequestHistory crh
 left join #core_ClientRequest cr  on crh.IdClientRequest=cr.id
--where crh.[CreatedOn] >= dateadd(day,-14,dateadd(day,datediff(day,0,Getdate()),0))


drop table if exists #request_list
select 
	   [ЗаявкаНомер] 
into #request_list 
from #pre_request_list

union all
select 
	   [ЗаявкаНомер] 
from #pre_request_list_task


---------------------------------------------------
----------- ОСНОВНАЯ ТАБЛИЦА. НАЧАЛО --------------
---------------------------------------------------

drop table if exists #fedor_ts_a

select 
      [ЗаявкаСсылка]							= crh.IdClientRequest
	  ,[ЗаявкаДата]								= cr.[CreatedOn]
      --,[время заведения]                       =cast(cr.[CreatedOn] as time)
      ,[ЗаявкаНомер]	                        = cr.number
      ,[ФИО клиента]							= ClientLastName+' '+ClientFirstName	+' '+ ClientMiddleName
 /*     ,cr.idclient */
	  ,[СтатусСсылка]							= crs.idexternal
      ,[СтатусНаименование]                     = crs.[Name]
      ,[Период]									= crh.CreatedOn
/*
      ,[сумма (в зависимости от статуса)1]	    = RequestedSum   
      ,[сумма (в зависимости от статуса)2]	    = ApprovedSum
      ,[сумма (в зависимости от статуса)3]	    = SumContract
      ,[сумма (в зависимости от статуса)4]	    = ClientSum
*/
      ,[ИсполнительСсылка]						= null      
      ,[ИсполнительНаименование]				='This is Fedor himself' --null--u1.LastName + ' ' + u1.FirstName + u1.MiddleName 
      ,taskId=null
      ,taskUser=null
      ,[owner]									= 'FEDOR RODEF'

	  ,[СчетчикГруппыТекСтатуса]				= case when crs.[Name] in (select [Name]  from #dictionary_ClientRequestStatus) then 1 else 0 end
	  ,[Состояние]								= 'Статус изменен'

into #fedor_ts_a
--select *
from #core_ClientRequestHistory crh
 join #core_ClientRequest cr  on crh.IdClientRequest=cr.id
 join #dictionary_ClientRequestStatus crs on crs.Id=crh.IdClientRequestStatus
 --left join stg.[_fedor].[core_user] u1 on u1.id=t.IdOwner
where  cr.number in (select distinct [ЗаявкаНомер] from #request_list)


 union all
--select * from [Fedor.Core].[core].[ClientRequest] cr

select 
	  [ЗаявкаСсылка]							= cr.Id
	  ,[ЗаявкаДата]								= cr.[CreatedOn]
      --,[время заведения]                      = cast(cr.[CreatedOn] as time)
      ,[ЗаявкаНомер]	                        = cr.number

      ,[ФИО клиента]                            = ClientLastName+' '+ClientFirstName	+' '+ ClientMiddleName
 /*     ,cr.idclient	*/

	  ,[СтатусСсылка]							= t.Id
      ,[СтатусНаименование]                     = 'task:'+ts.[Name]
      ,[Период]			                        = th.CreatedOn
/*     
	  ,[сумма (в зависимости от статуса)1]	    = RequestedSum   
      ,[сумма (в зависимости от статуса)2]	    = ApprovedSum
      ,[сумма (в зависимости от статуса)3]	    = SumContract
      ,[сумма (в зависимости от статуса)4]	    = ClientSum
*/      
      ,[ИсполнительСсылка]						= u1.id
	  ,[ИсполнительНаименование]		        = isnull(u.LastName,'FEDOR') + ' ' + isnull(u.FirstName,'FEDOR') + ' ' + isnull(u.MiddleName,'FEDOR') 
      ,t.id 
      ,[ИсполнительНаименование_m]		        = isnull(u1.LastName,'Fedor') + ' ' + isnull(u1.FirstName,'Fedor') + isnull(u1.MiddleName,'') 
      ,[owner]									= [owner].lastName + ' ' + [owner].FirstName + [owner].MiddleName 

	  ,[СчетчикГруппыТекСтатуса]				= case when 'task:'+ts.[Name] in (select [Name] from #dictionary_ClientRequestStatus) then 1 else 0 end 
	  ,[Состояние]								= tks.[State]

--select *
from #core_TaskHistory th
left join #dictionary_TaskStatus ts on ts.id=th.IdTaskStatus
left join #core_Task t on t.id=th.Idtask
left join #dictionary_TaskStatus ts1 on ts1.id=t.IdStatus
left join #core_TaskAndClientRequest tcr on  tcr.IdTask=t.id
left join #core_ClientRequest cr  on cr.Id=tcr.IdClientRequest

left join #core_user u1 on u1.id=t.IdOwner
left join #core_TaskAssignUser tau on tau.IdTask=t.Id
left join #core_user u  on u.id=tau.IdUser
left join #core_user [owner]  on [owner].id=tau.Idowner

left join #Task_State tks on tks.[id]=ts.[Id]

where cr.number in  (select distinct [ЗаявкаНомер] from #request_list)  
	  and th.IsDeleted = 0




---------------------------------------------------
----------- ОСНОВНАЯ ТАБЛИЦА. ЗАВЕРШЕНИЕ ----------
---------------------------------------------------

-----
drop table if exists #fedor_ts
select --distinct 
		* 
into #fedor_ts 
from #fedor_ts_a


-----
drop table if exists #fedor_t_counter
select --distinct
		[ЗаявкаСсылка]
		,[ЗаявкаДата]
		,[ЗаявкаНомер]
		,[ФИО клиента]

		,[Период]
		,[СтатусСсылка]
		,[СтатусНаименование] as [ТекСтатус]
		,[Состояние]

		,[ИсполнительСсылка]
		,[ИсполнительНаименование]

		,[СчетчикГруппыТекСтатуса]
		,sum([СчетчикГруппыТекСтатуса]) over(partition by [ЗаявкаНомер] order by [Период]
														rows between unbounded preceding and current row) as [ГруппаТекСтатуса] 
into #fedor_t_counter
from #fedor_ts	--#fedor_t_state
--select * from #fedor_ts_a

-----
drop table if exists #fedor_t_stateend2
select [ЗаявкаСсылка]
		,[ЗаявкаДата]
		,[ЗаявкаНомер]
		,[ФИО клиента]

		,[Период]
		,[СтатусСсылка]
		,[ТекСтатус]
		,[Состояние]

		,[ИсполнительСсылка]
		,[ИсполнительНаименование]

		,[СчетчикГруппыТекСтатуса]
		,[ГруппаТекСтатуса] 

		,first_value([ТекСтатус]) over(partition by [ЗаявкаНомер] ,[ГруппаТекСтатуса] order by [Период]) as [ВСтатусе]

				  
into #fedor_t_stateend2				  
from #fedor_t_counter


-----
drop table if exists #fedor_t_stateend_next
select [ЗаявкаСсылка]
		,[ЗаявкаДата]
		,[ЗаявкаНомер]
		,[ФИО клиента]

		,[Период] as [Период_Исх]
		,lag([Период]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [Период_След]

		,[СтатусСсылка] as [СтатусСсылка_Исх]
		,lag([СтатусСсылка]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [СтатусСсылка_След]

		,[ТекСтатус] as [СтатусНаим_Исх]
		,lag([ТекСтатус]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [СтатусНаим_След]

		,[ИсполнительСсылка] as [ИсполнительСсылка_Исх]
		,lag([ИсполнительСсылка]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [ИсполнительСсылка_След]

		,[ИсполнительНаименование] as [ИсполнительНаим_Исх]
		,lag([ИсполнительНаименование]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [ИсполнительНаим_След]

		--,[СчетчикГруппыТекСтатуса]
		--,[ГруппаТекСтатуса] 

		,[ВСтатусе] as [СтатусДляСостояния_Исх]
		,[ТекСтатус] as [ЗадачаСтатуса_Исх]
		,[Состояние] as [СостояниеЗаявки_Исх]

		,lag([ВСтатусе]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [СтатусДляСостояния_След]
		,lag([ТекСтатус]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [ЗадачаСтатуса_След]
		,lag([Состояние]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [СостояниеЗаявки_След]

				  
into #fedor_t_stateend_next				  
from #fedor_t_stateend2

--select * from #fedor_t_stateend_next order by 3 desc ,5 desc

-----
drop table if exists #tmp
select --* 
	   [ЗаявкаСсылка_Исх]			= [ЗаявкаСсылка]
	   ,[Период_Исх]				= [Период_Исх]
	   ,[ЗаявкаНомер_Исх]			= [ЗаявкаНомер]
	   ,[ЗаявкаДата_Исх]			= [ЗаявкаДата]
	   ,[СтатусСсылка_Исх]			= [СтатусСсылка_Исх]
	   ,[СтатусНаим_Исх]			= [СтатусНаим_Исх]
	   ,[ИсполнительСсылка_Исх]		= [ИсполнительСсылка_Исх]
	   ,[ИсполнительНаим_Исх]		= [ИсполнительНаим_Исх]
	   ,[ПричинаСсылка_Исх]			= null
	   ,[ПричинаНаим_Исх]			= null
	   ,[ЗаявкаСсылка_След]			= [ЗаявкаСсылка]
	   ,[Период_След]				= [Период_След]
	   ,[Период_След_2]				= [Период_След]
	   ,[СтатусСсылка_След]			= [СтатусСсылка_След]
	   ,[СтатусНаим_След]			= [СтатусНаим_След]
	   ,[ИсполнительСсылка_След]	= [ИсполнительСсылка_След]
	   ,[ИсполнительНаим_След]		= [ИсполнительНаим_След]
	   ,[ПричинаСсылка_След]		= null
	   ,[ПричинаНаим_След]			= null
	   
	   ,[СтатусДляСостояния_Исх]	= [СтатусДляСостояния_Исх]   
	   ,[ЗадачаСтатуса_Исх]			= case 
										when [СтатусНаим_Исх] like 'task%' 
											then [СтатусНаим_Исх] 
											else case 
													when not [СтатусНаим_След] is null or not [СтатусНаим_След] like 'task%'  
														then 'task: Изменить статус' 
												 end 
									  end
	   ,[СостояниеЗаявки_Исх]		= [СостояниеЗаявки_Исх]

	   
	   ,[СтатусДляСостояния_След]	= [СтатусДляСостояния_След]
	   ,[ЗадачаСтатуса_След]		= case 
										when [СтатусНаим_След] like 'task%' 
											then [СтатусНаим_След] 
											else case 
													when not [СтатусНаим_След] is null 
														then 'task: Изменить статус' 
												 end 
									  end
	   ,[СостояниеЗаявки_След]		= [СостояниеЗаявки_След]
	   ,[ВремяЗатрачено]			= cast(cast(isnull([Период_След],getdate()) as datetime) as decimal(15,10)) - cast(cast([Период_Исх] as datetime) as decimal(15,10))
	   ,[Tm]						= convert(nvarchar,cast(isnull([Период_След],getdate()) as datetime) - cast([Период_Исх] as datetime) ,8)

	   ,[ФИО клиента]

into #tmp
from #fedor_t_stateend_next	

begin tran

delete from [dwh_new].[dbo].[mt_requests_transition_fedor_UAT] 
where [ЗаявкаНомер_Исх] in (select [ЗаявкаНомер_Исх] from #tmp)
--where [Период_Исх] >=  @DateStartCurr; --@DateStartCurr;	--dateadd(day,datediff(day,0,Getdate()),0); -- @DateStart; --dateadd(day,datediff(day,0,Getdate()),0); --

insert into [dwh_new].[dbo].[mt_requests_transition_fedor_UAT] ([ЗаявкаСсылка_Исх]
															   ,[Период_Исх]
															   ,[ЗаявкаНомер_Исх]			
															   ,[ЗаявкаДата_Исх]			
															   ,[СтатусСсылка_Исх]			
															   ,[СтатусНаим_Исх]			
															   ,[ИсполнительСсылка_Исх]		
															   ,[ИсполнительНаим_Исх]		
															   ,[ПричинаСсылка_Исх]			
															   ,[ПричинаНаим_Исх]			
															   ,[ЗаявкаСсылка_След]			
															   ,[Период_След]				
															   ,[Период_След_2]				
															   ,[СтатусСсылка_След]			
															   ,[СтатусНаим_След]			
															   ,[ИсполнительСсылка_След]	
															   ,[ИсполнительНаим_След]		
															   ,[ПричинаСсылка_След]		
															   ,[ПричинаНаим_След]			
	   
															   ,[СтатусДляСостояния_Исх]		
															   ,[ЗадачаСтатуса_Исх]			
															   ,[СостояниеЗаявки_Исх]
	   
															   ,[СтатусДляСостояния_След]
															   ,[ЗадачаСтатуса_След]	
															   ,[СостояниеЗаявки_След]	
															   ,[ВремяЗатрачено]		
															   ,[Tm]
															   ,[ФИО клиента]
															)

select * 
--into [dwh_new].[dbo].[mt_requests_transition_fedor_UAT]
from #tmp
order by 1 desc,2 desc

commit tran

END


-- alter table [dwh_new].[dbo].[mt_requests_transition_fedor_UAT] add [ФИО клиента] nvarchar(250) null

--select *  from [dwh_new].[dbo].[mt_requests_transition_fedor_UAT] 
-- drop table [dwh_new].[dbo].[mt_requests_transition_fedor_UAT] 

------      select * from #tmp
/*
select distinct
	   [ЗаявкаНомер_Исх]
	   ,[ЗаявкаДата_Исх]	
	   ,[Период_Исх]
	   ,[Период_След]

	   ,[СтатусНаим_Исх]
	   ,[СтатусНаим_След]

	   ,[ИсполнительНаим_Исх]
	   ,[ИсполнительНаим_След]
	   
	   ,[СтатусДляСостояния] 
	   ,[ЗадачаСтатуса_Исх]
	   ,[СостояниеЗаявки_Исх]
	   
	   ,[СтатусДляСостояния_След]
	   ,[ЗадачаСтатуса_След]
	   ,[СостояниеЗаявки_След]
	   ,[ВремяЗатрачено]
	   ,convert(nvarchar,cast([ВремяЗатрачено] as datetime) ,8) as [Tm]
	   ,convert(nvarchar,cast(isnull([Период_След],getdate()) as datetime) - cast([Период_Исх] as datetime) ,8) as ttt
from #tmp
order by 1 desc,2 asc
*/