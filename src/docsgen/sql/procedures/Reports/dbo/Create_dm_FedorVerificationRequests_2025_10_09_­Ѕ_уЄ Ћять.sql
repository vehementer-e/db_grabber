--select * from  dbo.dm_FedorVerificationRequests
-- exec [Reports].[dbo].[Create_dm_FedorVerificationRequests] 10
create   PROC dbo.Create_dm_FedorVerificationRequests_2025_10_09_не_удалять
@days int=25, -- было 10, что мало для расчета после новогодних выходных
@isDebug int = 0

as

begin
	SET XACT_ABORT  ON
	begin try
	set nocount on
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @StartDate datetime, @row_count int

	--declare @days int=10
	--select * from dbo.dm_FedorVerificationRequests where '20110800049410'=[Номер заявки] [Дата статуса]>'20201113'

	-------------- Таблица задача - состояние
	  drop table if exists #Task_State
	  create table #Task_State (
							   [id] int null 
							 , [Task] nvarchar(50) null 
							 , [State] nvarchar(50) null
							 )

	  insert into #Task_State
	  values (1,'Новая'                       , 'Ожидание')
		   , (2,'В работе'                    , 'В работе')
		   , (3,'Отложена'                    , 'Отложена')
		   , (4,'Отменена'                    , 'Отменена')
		   , (5,'Выполнена'                   , 'Выполнена')
		   , (6,'Требуется доработка'         , 'Отложена')
		   , (7,'Вернулась с доработки'       , 'Ожидание')
		   , (8,'Вернулась из отложенных'     , 'Ожидание')
		   , (9,'Переназначена'               , 'Ждет Исполнителя')

	-- таблицы fedor

	-- справочники
	  drop table if exists #dictionary_ClientRequestStatus
	  select Id
		   , Name=Name         collate Cyrillic_General_CI_AS
		   , IdExternal   
		   , Code=Code         collate Cyrillic_General_CI_AS
		   , IsDeleted
		   , SortOrder
		into #dictionary_ClientRequestStatus
		from stg.[_fedor].[dictionary_ClientRequestStatus] 

	-- select * from  #dictionary_ClientRequestStatus
	  drop table if exists #dictionary_TaskStatus
	  select Id
		   , Name=Name       collate Cyrillic_General_CI_AS
		   , IsDeleted
		   , SortOrder
		into #dictionary_TaskStatus
		from stg.[_fedor].[dictionary_TaskStatus] 
	   where IsDeleted = 0
	--select * from #dictionary_TaskStatus

	--факты
	drop table if exists #core_ClientRequest
	select 
		cr.* 
		,ФИО_Клиента =TRIM(concat_ws(' '
				, isnull(cr.ClientLastName  , cr_ci.LastName)
				, isnull(cr.ClientFirstName , cr_ci.FirstName)
				, isnull(cr.ClientMiddleName, cr_ci.MiddleName)
				)) COLLATE Cyrillic_General_CI_AS
		,КодТипКредитногоПродукта = pt.Code
		,КодПодТипКредитногоПродукта = pst.Code
	into #core_ClientRequest
	from Stg._fedor.core_ClientRequest cr 
		left join Stg._fedor.core_ClientRequestClientInfo cr_ci
			on cr_ci.id = cr.id
		LEFT JOIN Stg._fedor.dictionary_ProductType AS pt
			ON pt.Id = cr.ProductTypeId
		LEFT JOIN Stg._fedor.dictionary_ProductSubType AS pst
			ON pst.Id = cr.ProductSubTypeId
	where 1=1
		--убрали т.к. для Installment есть другие отчеты
		and (
			(isnull(cr.IsInstallment,0) <> 1 and isnull(cr.Type, 0) = 0) -- 'ПТС'
			or isnull(pt.Code, '') in ('ptsLite') -- DWH-303
		)
		and try_cast(cr.Number as bigint) is not null
		and (COALESCE(cr.ClientFirstName, cr_ci.FirstName, '') not like 'Тест%'  COLLATE Cyrillic_General_CI_AS
		and COALESCE(cr.ClientMiddleName, cr_ci.MiddleName, '') not like 'Тест%' COLLATE Cyrillic_General_CI_AS
		and COALESCE(cr.ClientLastName, cr_ci.LastName, '')<>'ТЕСТОВАЯ' COLLATE Cyrillic_General_CI_AS)
		and cr.CreatedOn>'20200902' -- дата старта ФЕДОР в проде
		 and   dateadd(hour,3,cr.[CreatedOn]) 				  >dateadd(day,-@days,cast(getdate() as date))


	CREATE INDEX ix1 ON #core_ClientRequest(Id)
	CREATE INDEX ix2 ON #core_ClientRequest(Number)

	  --select * from #core_ClientRequest order by number, createdon where crmnumber='20090700031430'

	  drop table if exists #core_Task
	  select * 
		into #core_Task
		from stg.[_fedor].[core_Task] 
	   where CreatedOn>'20200902' -- дата старта ФЕДОР в проде
		 and 
		 IsDeleted = 0
		   and   dateadd(hour,3,[CreatedOn]) 				  >dateadd(day,-@days,cast(getdate() as date))

	   --select * from #core_Task

	  drop table if exists #core_TaskAndClientRequest
	  select t.IdTask
			,t.IdClientRequest
		into #core_TaskAndClientRequest
		from stg.[_fedor].[core_TaskAndClientRequest] t
	   where IsDeleted = 0
	   and exists(select top(1) 1 from #core_ClientRequest cr where cr.id = t.IdClientRequest)
	create index ix_IdClientRequest on #core_TaskAndClientRequest(IdClientRequest) include(IdTask)



	  drop table if exists #core_user
	  select * 
		into #core_user
		from stg.[_fedor].[core_user]
	   --where IsDeleted = 0 Убрали т.к. нужно по всем сотрудникам собирать витрину
	   --or LASTnAME  like '%Ставц%' or LASTnAME  like '%Кавери%' or LASTnAME  like '%Лесик%' 
	--select * from #core_user  WHERE LASTnAME  like '%Волос%'/*  A96E3624-C23B-4889-A908-3944DB05223E  - Прибылов

	  drop table if exists #core_TaskAssignUser
	  select * 
		into #core_TaskAssignUser
		from stg.[_fedor].[core_TaskAssignUser] 
	   where CreatedOn>'20200902' -- дата старта ФЕДОР в проде
		 and IsDeleted = 0 
			and   dateadd(hour,3,[CreatedOn]) 				  >dateadd(day,-@days,cast(getdate() as date))
	-- select * from #core_TaskAssignUser

	  drop table if exists #core_TaskHistory
	  select *
		into #core_TaskHistory
		from stg.[_fedor].[core_TaskHistory] 
	   where CreatedOn>'20200902' -- дата старта ФЕДОР в проде
		 and IsDeleted = 0
			and   dateadd(hour,3,[CreatedOn]) 				  >dateadd(day,-@days,cast(getdate() as date))

	--
	/*
	select * from #core_TaskHistory th 
	left join #dictionary_TaskStatus ts on ts.id=th.IdTaskStatus
	join #core_Task ct on th.idtask=ct.id
	   left join #core_TaskAndClientRequest tcr on  tcr.IdTask=ct.id
		  left join #core_ClientRequest cr  on cr.Id=tcr.IdClientRequest
          
	where th.createdOn>'20200902' and  cr.createdOn<'20200902'


	*/
	  drop table if exists #core_ClientRequestHistory
	  select * 
		into #core_ClientRequestHistory 
		from stg.[_fedor].[core_ClientRequestHistory]
	   where CreatedOn>'20200902' -- дата старта ФЕДОР в проде
		 and IsDeleted = 0 
		   and   dateadd(hour,3,[CreatedOn]) 				  >dateadd(day,-@days,cast(getdate() as date))

	--select * from #core_ClientRequestHistory
	--/ таблицы fedor


	-- витрина

	  drop table if exists #fedor_ts

	  select [ЗаявкаСсылка]         = crh.IdClientRequest
			 , [ЗаявкаДата]			= cr.[CreatedOn]
		   , [ЗаявкаНомер]	        = cr.number
	       , [ФИО клиента]			= cr.ФИО_Клиента
		   
		  -- trim(concat(cr.ClientLastName, ' ', cr.ClientFirstName, ' ', cr.ClientMiddleName))
  		   , [СтатусСсылка]				  	= isnull(cast(crs.idexternal as nvarchar(64)),format(crs.id,'0'))
		   , [СтатусНаименование]     = crs.[Name]
		   , [Период]									= crh.CreatedOn
		   , [ИсполнительСсылка]			= null      
		   , [ИсполнительНаименование]= N'This is Fedor himself' --null--u1.LastName + ' ' + u1.FirstName + u1.MiddleName 
		   , taskId                   = null
		   , taskUser                 = null
		   , [owner]									= N'FEDOR RODEF'
			 , [СчетчикГруппыТекСтатуса]= case when crs.[Name] in (select [Name]  from #dictionary_ClientRequestStatus) then 1 else 0 end
			 , [Состояние]							= N'Статус изменен'
			 , [Работник] = N'This is Fedor himself'
			 , [Назначен] = N'This is Fedor himself'
			 , [Офис заведения заявки] = P.Name
		into #fedor_ts
		from #core_ClientRequestHistory crh
		join #core_ClientRequest cr  on crh.IdClientRequest=cr.id
		--DWH-1620 Добавить поле в отчете по верификации Офис заведения заявки
		LEFT JOIN Stg._fedor.dictionary_point AS P
			ON P.Id = cr.IdPoint
		join #dictionary_ClientRequestStatus crs on crs.Id=crh.IdClientRequestStatus
		--where ClientFirstName not like 'Тест%'  and ClientMiddleName not like 'Тест%' and trim(ClientLastName)<>'ТЕСТОВАЯ'
		--DWH-2677
		--where isnull(cr.ClientFirstName, '') not like 'Тест%' and isnull(cr.ClientMiddleName, '') not like 'Тест%' and trim(isnull(cr.ClientLastName, ''))<>'ТЕСТОВАЯ'
	  and   dateadd(hour,3,cr.[CreatedOn]) 				  >dateadd(day,-@days,cast(getdate() as date))
	  union all
	  select [ЗаявкаСсылка]			= cr.Id
		   , [ЗаявкаДата]			= cr.[CreatedOn]
		   , [ЗаявкаНомер]          = cr.number
	       , [ФИО клиента]			= cr.ФИО_Клиента
		   --trim(concat(cr.ClientLastName, ' ', cr.ClientFirstName, ' ', cr.ClientMiddleName))
		   , [СтатусСсылка]						= cast(th.IdTaskStatus as nvarchar(64))
		   , [СтатусНаименование]     = N'task:'+ts.[Name]
		   , [Период]			      = th.CreatedOn
		   , [ИсполнительСсылка]		= u1.id
			 , [ИсполнительНаименование]= case when (isnull(u0.LastName,N'FEDOR')+N' '+isnull(u0.FirstName,N'FEDOR')+N' '+isnull(u0.MiddleName,N'FEDOR')) like N'%Системный пользователь для FEDOR%'
																		 then isnull(u.LastName,N'FEDOR') + N' ' + isnull(u.FirstName,N'FEDOR') + N' ' + isnull(u.MiddleName,N'FEDOR')
																	   else isnull(u0.LastName,N'FEDOR') + N' ' + isnull(u0.FirstName,N'FEDOR') + N' ' + isnull(u0.MiddleName,N'FEDOR') 
																 end
		   , taskId                   = t.id 
		   , ИсполнительНаименование_m= isnull(u1.LastName,N'Fedor') + N' ' + isnull(u1.FirstName,N'Fedor') +N' '+ isnull(u1.MiddleName,N'') 
		   , [owner]									= [owner].lastName + N' ' + [owner].FirstName + N' ' + [owner].MiddleName 
		   , [СчетчикГруппыТекСтатуса]= case when 'task:'+ts.[Name] in (select [Name] from #dictionary_ClientRequestStatus) then 1 else 0 end 
			 , [Состояние]							= tks.[State]
			 , [Работник]=  isnull(u0.LastName,N'FEDOR') + N' ' + isnull(u0.FirstName,N'FEDOR') + N' ' + isnull(u0.MiddleName,N'FEDOR') 
			 , [Назначен]=  isnull(u.LastName,N'FEDOR') + N' ' + isnull(u.FirstName,N'FEDOR') + N' ' + isnull(u.MiddleName,N'FEDOR') 
			 , [Офис заведения заявки] = P.Name
												             
		  --- select  * 
		from #core_ClientRequest cr 
		--DWH-1620 Добавить поле в отчете по верификации Офис заведения заявки
		LEFT JOIN Stg._fedor.dictionary_point AS P
			ON P.Id = cr.IdPoint
		left join #core_TaskAndClientRequest tcr on cr.Id=tcr.IdClientRequest
		left join #core_Task t      on  tcr.IdTask=t.id
		left join #core_TaskHistory th on t.id=th.Idtask
		left join #dictionary_TaskStatus ts on ts.id=th.IdTaskStatus
   
		left join #dictionary_TaskStatus ts1 on ts1.id=t.IdStatus
   

		left join #core_user u0 on u0.id=th.IdOwner
		left join #core_user u1 on u1.id=t.IdOwner
		left join #core_TaskAssignUser tau on tau.IdTask=t.Id
		left join #core_user u  on u.id=tau.IdUser
		left join #core_user [owner]  on [owner].id=tau.Idowner
		left join #Task_State tks on tks.[id]=ts.[Id]
	   --where  th.IsDeleted = 0 and  ( ClientFirstName not like 'Тест%'  and ClientMiddleName not like 'Тест%' and trim(ClientLastName)<>'ТЕСТОВАЯ')
	   --DWH-2677
	   where th.IsDeleted = 0 
		--and (isnull(cr.ClientFirstName, '') not like 'Тест%' and isnull(cr.ClientMiddleName, '') not like 'Тест%' and trim(isnull(cr.ClientLastName, ''))<>'ТЕСТОВАЯ')
		   and   dateadd(hour,3,cr.[CreatedOn]) 				  >dateadd(day,-@days,cast(getdate() as date))
		   -- 2021_02_09
		   and tau.IsDeleted = 0
   --Фикс на время пока не исправят проблему на феде
   ;with cte as (
		select След_статус = lead(СтатусНаименование) over(partition by [ЗаявкаНомер] order by [Период] )
			,След_статус_Период = lead([Период]) over(partition by [ЗаявкаНомер] order by [Период] )
			,s.*

		from #fedor_ts s
		)

		update cte
			set Период = dateadd(mcs, 1, След_статус_Период)

		where СтатусНаименование = 'Верификация Call 1.5'
		and След_статус = 'task:Выполнена'
		and Период <=След_статус_Период



	--select * from #fedor_ts where Период>'20201113'order by 3, Период
	--select * from #fedor_ts where Период>'20201216'order by 3, Период
	delete from #fedor_ts where ЗаявкаНомер in ('20101600042702','20101600042739','20101600042761','20101600042765')

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##fedor_ts
		SELECT * INTO ##fedor_ts FROM #fedor_ts
	END

	-----
	  drop table if exists #fedor_t_counter
	  select [ЗаявкаСсылка]
			   , [ЗаявкаДата]
			   , [ЗаявкаНомер]
			   , [ФИО клиента]
  		   , [Период]
			   , [СтатусСсылка]
			   , [СтатусНаименование] as [ТекСтатус]
			   , [Состояние]
  		   , [ИсполнительСсылка]
			   , [ИсполнительНаименование]
  		   , [СчетчикГруппыТекСтатуса]
			   , sum([СчетчикГруппыТекСтатуса]) over(partition by [ЗаявкаНомер] order by [Период]
		   													rows between unbounded preceding and current row) as [ГруппаТекСтатуса] 
			, [Работник]
			, [Назначен]
			, [Офис заведения заявки]
		into #fedor_t_counter
		from #fedor_ts

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##fedor_t_counter
		SELECT * INTO ##fedor_t_counter FROM #fedor_t_counter
	END

	-----
	  drop table if exists #fedor_t_stateend2
	  select [ЗаявкаСсылка]
			   , [ЗаявкаДата]
			   , [ЗаявкаНомер]
			   , [ФИО клиента]
  			   , [Период]
			   , [СтатусСсылка]
			   , [ТекСтатус]
			   , [Состояние]
  			   , [ИсполнительСсылка]
			   , [ИсполнительНаименование]
			   , [Работник]
			   , [Назначен]
  			   , [СчетчикГруппыТекСтатуса]
			   , [ГруппаТекСтатуса] 
  			   , first_value([ТекСтатус]) over(partition by [ЗаявкаНомер] ,[ГруппаТекСтатуса] order by [Период]) as [ВСтатусе]
				, [Офис заведения заявки]
		into #fedor_t_stateend2
		from #fedor_t_counter

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##fedor_t_stateend2
		SELECT * INTO ##fedor_t_stateend2 FROM #fedor_t_stateend2
	END
	-- select * from #fedor_t_stateend2 where [ЗаявкаНомер] = '20060200022444'

	-----
	  drop table if exists #fedor_t_stateend_next
	  select [ЗаявкаСсылка]
			   , [ЗаявкаДата]
			   , [ЗаявкаНомер]
			   , [ФИО клиента]
			   , [Период] as [Период_Исх]
			   , lag([Период]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [Период_След]
			   , [СтатусСсылка] as [СтатусСсылка_Исх]
			   , lag([СтатусСсылка]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [СтатусСсылка_След]
			   , [ТекСтатус] as [СтатусНаим_Исх]
			   , lag([ТекСтатус]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [СтатусНаим_След]
			   , [ИсполнительСсылка] as [ИсполнительСсылка_Исх]
			   , lag([ИсполнительСсылка]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [ИсполнительСсылка_След]
			   , [ИсполнительНаименование] as [ИсполнительНаим_Исх]
			   , lag([ИсполнительНаименование]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [ИсполнительНаим_След]
			   , Работник
			   , Назначен

			   --DWH-2101. Исправление ошибки. были перепутаны вычисления _Пред и _След
			   --, lag(Работник) over (partition by [ЗаявкаНомер] order by [Период] desc) as [Работник_Пред]
			   --, lag(Назначен) over (partition by [ЗаявкаНомер] order by [Период] desc) as [Назначен_Пред]
			   --, lead(Работник) over (partition by [ЗаявкаНомер] order by [Период] desc) as [Работник_След]
			   --, lead(Назначен) over (partition by [ЗаявкаНомер] order by [Период] desc) as [Назначен_След]
			   , lead(Работник) over (partition by [ЗаявкаНомер] order by [Период] desc) as [Работник_Пред]
			   , lead(Назначен) over (partition by [ЗаявкаНомер] order by [Период] desc) as [Назначен_Пред]
			   , lag(Работник) over (partition by [ЗаявкаНомер] order by [Период] desc) as [Работник_След]
			   , lag(Назначен) over (partition by [ЗаявкаНомер] order by [Период] desc) as [Назначен_След]

			   , [ВСтатусе] as [СтатусДляСостояния_Исх]
			   , [ТекСтатус] as [ЗадачаСтатуса_Исх]
			   , [Состояние] as [СостояниеЗаявки_Исх]
			   , lag([ВСтатусе]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [СтатусДляСостояния_След]
			   , lag([ТекСтатус]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [ЗадачаСтатуса_След]
			   , lag([Состояние]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [СостояниеЗаявки_След]
		   , ШагЗаявки=ROW_NUMBER() over (partition by ЗаявкаНомер order by [Период] )
		   , lead([ТекСтатус]) over (partition by [ЗаявкаНомер] order by [Период] desc) as [СтатусНаим_Пред]
			   --, [ИсполнительСсылка] as [ИсполнительСсылка_Исх]
			, [Офис заведения заявки]	   
		into #fedor_t_stateend_next
		from #fedor_t_stateend2

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##fedor_t_stateend_next
		SELECT * INTO ##fedor_t_stateend_next FROM #fedor_t_stateend_next
	END


	  drop table if exists #tmp
	  select [ЗаявкаСсылка_Исх]			      = [ЗаявкаСсылка]
			 , [Период_Исх]				          = [Период_Исх]
			 , [ЗаявкаНомер_Исх]			      = [ЗаявкаНомер]
			 , [ЗаявкаДата_Исх]			        = [ЗаявкаДата]
			 , [СтатусСсылка_Исх]			      = [СтатусСсылка_Исх]
			 , [СтатусНаим_Исх]			        = [СтатусНаим_Исх]
			 , [ИсполнительСсылка_Исх]		  = [ИсполнительСсылка_Исх]
			 , [ИсполнительНаим_Исх]		    = [ИсполнительНаим_Исх]
			 , [ПричинаСсылка_Исх]			    = null
			 , [ПричинаНаим_Исх]			      = null --case when [СтатусНаим_Исх] = 'Отказано' then r.reject_reason end
			 , [ЗаявкаСсылка_След]			    = [ЗаявкаСсылка]
			 , [Период_След]				        = [Период_След]
			 , [Период_След_2]				      = [Период_След]
			 , [СтатусСсылка_След]			    = [СтатусСсылка_След]
			 , [СтатусНаим_След]			      = [СтатусНаим_След]
			 , [ИсполнительСсылка_След]	    = [ИсполнительСсылка_След]
			 , [ИсполнительНаим_След]		    = [ИсполнительНаим_След] 
			 , [ПричинаСсылка_След]		      = null
			 , [ПричинаНаим_След]			      = null --case when [СтатусНаим_След] = 'Отказано' then r.reject_reason end
			 , [СтатусДляСостояния_Исх]	    = [СтатусДляСостояния_Исх]   
			 , [ЗадачаСтатуса_Исх]			    = case when [СтатусНаим_Исх] like 'task%' 
																	   then [СтатусНаим_Исх] 
																	   else case when not [СтатусНаим_След] is null or not [СтатусНаим_След] like 'task%'  
																					   then 'task: Изменить статус' 
																			   end 
															   end
			 , [СостояниеЗаявки_Исх]		    = [СостояниеЗаявки_Исх]
			 , [СтатусДляСостояния_След]	  = [СтатусДляСостояния_След]
			 , [ЗадачаСтатуса_След]		      = case when [СтатусНаим_След] like 'task%' 
												 then [СтатусНаим_След] 
												 else case when not [СтатусНаим_След] is null 
																					   then 'task: Изменить статус' 
																			   end 
															   end
			 , [СостояниеЗаявки_След]		    = [СостояниеЗаявки_След]
			 , [ВремяЗатрачено]			        = cast(cast(isnull([Период_След],getdate()) as datetime) as decimal(15,10)) - cast(cast([Период_Исх] as datetime) as decimal(15,10))
			 , [Tm]						              = cast('20000101 '+convert(nvarchar,cast(isnull([Период_След],getdate()) as datetime) - cast([Период_Исх] as datetime) ,8) as datetime)
     
         
			 , [ФИО клиента]
		   , ШагЗаявки
		   -- правка для верификации
			-- учтем что здесь еще нет сдвига на 3 часа
		   , [ВремяЗатраченоОжиданиеВерификацииКлиента] = 
		 --  case 
			--when [СостояниеЗаявки_Исх]='Ожидание' and [СтатусДляСостояния_Исх]='Верификация клиента'  
			--then 
			cast(cast(isnull(case when  cast([Период_След] as time)>'04:00' and cast([Период_След] as time)<='19:00' then [Период_След]
					 else 
						  case when  cast([Период_След] as time)>'19:00' and cast([Период_След] as time)<='20:59:59' then
							   cast(format(dateadd(day,1,cast([Период_След] as date)),'yyyyMMdd 04:00') as datetime) 
						  else
							   cast(format([Период_След],'yyyyMMdd 04:00') as datetime) 
						  end
					 end , getdate()) as datetime) as decimal(15,10))
					 -
					 cast(cast(case when  cast([Период_Исх] as time)>'04:00' and cast([Период_Исх] as time)<='19:00' then [Период_Исх] 
					 else 
						  case when  cast([Период_Исх] as time)>'19:00' and cast([Период_Исх] as time)<='20:59:59' then
							   cast(format(dateadd(day,1,cast([Период_Исх] as date)),'yyyyMMdd 04:00') as datetime) 
						  else
							   cast(format([Период_Исх] ,'yyyyMMdd 04:00') as datetime) 
						  end
					 end as datetime) as decimal(15,10))
			, [ЗадачаСтатуса_Пред]		      = case when [СтатусНаим_Пред] like 'task%' 
												 then [СтатусНаим_Пред] 
												 else case when not [СтатусНаим_Пред] is null 
																					   then 'task: Изменить статус' 
																			   end 
															   end
			   , Работник
			   , Назначен
			   , [Работник_Пред]
			   , [Назначен_Пред]
			   , [Работник_След]
			   , [Назначен_След]		 
				, [Офис заведения заявки]
			--end 
		into #tmp
		from #fedor_t_stateend_next f	

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##tmp
		SELECT * INTO ##tmp FROM #tmp
	END

		--select * from #tmp order by 3,ШагЗаявки


	drop table if exists #mt_requests_transition_fedor_prod

	  ; with p as (
	  select p.* 
		from #tmp p
	   where not (p.[СтатусДляСостояния_Исх]=p.[СтатусДляСостояния_След] and p.[ЗадачаСтатуса_Исх]=p.[ЗадачаСтатуса_След] and p.[Период_Исх]=p.[Период_След])
	),
	 st as (
				  select ЗаявкаНомер_Исх
					   , max(ШагЗаявки) ПоследнийШаг 
					from p
				   group by ЗаявкаНомер_Исх
				   )
  
	  select p.* 
		   , ST.ПоследнийШаг
		into #mt_requests_transition_fedor_prod 
		from p       
		left join st on st.ЗаявкаНомер_Исх=p.ЗаявкаНомер_Исх

	/*
	select * from #mt_requests_transition_fedor_prod
	order by ЗаявкаСсылка_Исх,Период_Исх
	*/

	--DWH-2066 Сохранение данных по чеклисту в таблицах dm
	DROP TABLE IF EXISTS #t_Проверки_в_ЧекЛисте
	CREATE TABLE #t_Проверки_в_ЧекЛисте(
		IdClientRequest uniqueidentifier,
		ЗвонокРаботодателюПоТелефонамИзКонтурФокус varchar(255),
		ЗвонокРаботодателюПоТелефонамИзИнтернет varchar(255),
		ЗвонокРаботодателюПоТелефонуИзАнкеты varchar(255),
		ЗвонокКонтактномуЛицу varchar(255),
		ПроверкаДохода varchar(255)
	)

	INSERT #t_Проверки_в_ЧекЛисте
	(
	    IdClientRequest,
	    ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
	    ЗвонокРаботодателюПоТелефонамИзИнтернет,
	    ЗвонокРаботодателюПоТелефонуИзАнкеты,
	    ЗвонокКонтактномуЛицу,
		ПроверкаДохода
	)
	SELECT IdClientRequest,
		ЗвонокРаботодателюПоТелефонамИзКонтурФокус = [Звонок работодателю по телефонам из Контур Фокус],
		ЗвонокРаботодателюПоТелефонамИзИнтернет = [Звонок работодателю по телефонам из Интернет],
		ЗвонокРаботодателюПоТелефонуИзАнкеты = [Звонок работодателю по телефону из Анкеты],
		ЗвонокКонтактномуЛицу = [Звонок контактному лицу],
		ПроверкаДохода = [Проверка дохода]
	FROM  
		(
			SELECT 
				CheckListItem.IdClientRequest,
				CheckListItemType_Name = CheckListItemType.Name,
				CheckListItemStatus_Name = isnull(CheckListItemStatus.Name, 'назначен') -- звонок назначен, но еще не выполнен
			FROM Stg._fedor.core_CheckListItem AS CheckListItem
				INNER JOIN #mt_requests_transition_fedor_prod AS ClientRequest
					ON ClientRequest.[ЗаявкаСсылка_Исх] = CheckListItem.IdClientRequest
				INNER JOIN Stg._fedor.dictionary_CheckListItemType AS CheckListItemType
					ON CheckListItemType.Id = CheckListItem.IdType
				LEFT JOIN Stg._fedor.core_CheckListItemTypeAndCheckListItemStatus AS CH_IT_IS
					ON CH_IT_IS.IdType = CheckListItem.IdType
					AND CH_IT_IS.IdCheckListItemStatus = CheckListItem.IdStatus
				LEFT JOIN Stg._fedor.dictionary_CheckListItemStatus AS CheckListItemStatus
					ON CheckListItemStatus.Id = CheckListItem.IdStatus
			WHERE 1=1
				AND CheckListItemType.Name IN (
					'Звонок работодателю по телефонам из Контур Фокус',
					'Звонок работодателю по телефонам из Интернет',
					'Звонок работодателю по телефону из Анкеты',
					'Звонок контактному лицу',
					--'Звонок на мобильный телефон клиента'
					'Проверка дохода'
				)
		) AS SourceTable  
		PIVOT  
		(  
		  max(CheckListItemStatus_Name)
		  FOR CheckListItemType_Name IN (
			[Звонок работодателю по телефонам из Контур Фокус],
			[Звонок работодателю по телефонам из Интернет],
			[Звонок работодателю по телефону из Анкеты],
			[Звонок контактному лицу],
			[Проверка дохода]
		  )
		) AS PivotTable

	ALTER TABLE #mt_requests_transition_fedor_prod
	ADD ЗвонокРаботодателюПоТелефонамИзКонтурФокус varchar(255),
		ЗвонокРаботодателюПоТелефонамИзИнтернет varchar(255),
		ЗвонокРаботодателюПоТелефонуИзАнкеты varchar(255),
		ЗвонокКонтактномуЛицу varchar(255),
		ПроверкаДохода varchar(255)

	UPDATE M
	SET ЗвонокРаботодателюПоТелефонамИзКонтурФокус = C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
		ЗвонокРаботодателюПоТелефонамИзИнтернет = C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
		ЗвонокРаботодателюПоТелефонуИзАнкеты = C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
		ЗвонокКонтактномуЛицу = C.ЗвонокКонтактномуЛицу,
		ПроверкаДохода = C.ПроверкаДохода
	FROM #mt_requests_transition_fedor_prod AS M
		INNER JOIN #t_Проверки_в_ЧекЛисте AS C
			ON C.IdClientRequest = M.ЗаявкаСсылка_Исх
	--//DWH-2066

	--DWH-2286 Тип клиента
	DROP TABLE IF EXISTS #t_return_type
	CREATE TABLE #t_return_type(request_number varchar(50) NOT NULL, return_type varchar(255) NULL)

	INSERT #t_return_type(request_number, return_type)
	SELECT A.request_number, A.return_type
	FROM (
		SELECT 
			T.request_number, 
			T.return_type,
			rn = row_number() OVER(PARTITION BY T.request_number ORDER BY T.call_date)
		FROM Stg._loginom.return_type AS T
		) AS A
	WHERE A.rn = 1

	CREATE INDEX ix ON #t_return_type(request_number)

	ALTER TABLE #mt_requests_transition_fedor_prod
	ADD ТипКлиента varchar(30)

	UPDATE M
	SET ТипКлиента = cast(R.return_type AS varchar(30))
	FROM #mt_requests_transition_fedor_prod AS M
		INNER JOIN #t_return_type AS R
			ON R.request_number = M.ЗаявкаНомер_Исх COLLATE Cyrillic_General_CI_AS
	--//DWH-2286 Тип клиента

	--DWH-303
	ALTER TABLE #mt_requests_transition_fedor_prod
	ADD КодТипКредитногоПродукта varchar(30),
		КодПодТипКредитногоПродукта varchar(30)
 
	UPDATE M
	SET КодТипКредитногоПродукта = R.КодТипКредитногоПродукта COLLATE Cyrillic_General_CI_AS,
		КодПодТипКредитногоПродукта = R.КодПодТипКредитногоПродукта COLLATE Cyrillic_General_CI_AS
	FROM #mt_requests_transition_fedor_prod AS M
		INNER JOIN #core_ClientRequest AS R
			ON R.Number = M.ЗаявкаНомер_Исх
	--//DWH-303

	--DWH-2916 Партнер
	DROP TABLE IF EXISTS #t_partner

	SELECT
		--request_id = R.Id,
		request_number = R.Number COLLATE Cyrillic_General_CI_AS,
		partner_name = G.Name COLLATE Cyrillic_General_CI_AS -- Партнер
	INTO #t_partner
	FROM #core_ClientRequest AS R
		INNER JOIN Stg._fedor.core_ClientRequestAndLeadGenerator AS L
			ON L.ClientRequestId = R.Id
		INNER JOIN Stg._fedor.dictionary_ConfigGeneralizedLeadGenerator AS C
			ON C.Id = L.ConfigGeneralizedLeadGeneratorId
		INNER JOIN Stg._fedor.dictionary_GeneralizedLeadGenerator AS G
			ON G.Id = C.GeneralizedLeadGeneratorId

	CREATE INDEX ix1 ON #t_partner(request_number)

	ALTER TABLE #mt_requests_transition_fedor_prod
	ADD Партнер varchar(50)

	UPDATE M
	SET Партнер = cast(P.partner_name AS varchar(50))
	FROM #mt_requests_transition_fedor_prod AS M
		INNER JOIN #t_partner AS P
			ON P.request_number = M.ЗаявкаНомер_Исх COLLATE Cyrillic_General_CI_AS
	--//DWH-2916 Партнер


	--DWH-228 [Тип документа подтверждающего доход]
	DROP TABLE IF EXISTS #t_IncomeVerification

	select 
		a.ClientRequestId,
		IncomeVerificationSource = string_agg(a.IncomeVerificationSource, '; ')
	into #t_IncomeVerification
	from (
			select 
				ClientRequestId = cr.Id, 
				IncomeVerificationSource = s.Name
			from #core_ClientRequest AS cr 
				inner join Stg._fedor.core_IncomeDocument as d
					on d.ClientRequestId = cr.Id
				inner join Stg._fedor.dictionary_IncomeVerificationSource as s
					on s.Id = d.IncomeVerificationSourceId
			group by cr.Id, s.Name
		) as a
	group by a.ClientRequestId

	ALTER TABLE #mt_requests_transition_fedor_prod
	ADD [Тип документа подтверждающего доход] varchar(500)

	UPDATE M
	SET [Тип документа подтверждающего доход] = substring(v.IncomeVerificationSource, 1, 500)
	FROM #mt_requests_transition_fedor_prod AS M
		INNER JOIN #t_IncomeVerification AS v
			ON v.ClientRequestId = M.ЗаявкаСсылка_Исх
	--//DWH-228

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##mt_requests_transition_fedor_prod
		SELECT * INTO ##mt_requests_transition_fedor_prod FROM #mt_requests_transition_fedor_prod
	END

	declare @now datetime=getdate()
	--drop table if exists  dbo.dm_FedorVerificationRequests

	--DWH-1716 Оптимизировать обновление данных в отчете верификации
	begin tran
		TRUNCATE TABLE dbo.dm_FedorVerificationRequests_STG

		SELECT @StartDate = getdate(), @row_count = 0

		INSERT dbo.dm_FedorVerificationRequests_STG
		SELECT *
		FROM dbo.dm_FedorVerificationRequests (NOLOCK)

		SELECT @row_count = @@ROWCOUNT
		IF @isDebug = 1 BEGIN
			SELECT 'INSERT full table into dbo.dm_FedorVerificationRequests_STG', @row_count, datediff(SECOND, @StartDate, getdate())
		END



		SELECT @StartDate = getdate(), @row_count = 0

	  DELETE
	  FROM dbo.dm_FedorVerificationRequests_STG
	  WHERE [Дата заведения заявки]	>=dateadd(day,-@days,cast(getdate() as date))

	  --DWH-2879. избавляемся от возможных дублей
	  DELETE D
	  FROM dbo.dm_FedorVerificationRequests_STG AS D
	  WHERE EXISTS(
			SELECT TOP(1) 1
			FROM #core_ClientRequest AS X
			WHERE X.Number = D.[Номер заявки]
		)


	  insert into dbo.dm_FedorVerificationRequests_STG
	  --declare @now datetime=getdate()
	  select [Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], Статус, Задача, [Состояние заявки], [Дата статуса], [Дата след.статуса], [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], ПричинаНаим_Исх, ПричинаНаим_След, [Последнее состояние заявки на дату по сотруднику], [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], СотрудникПоследнегоСтатуса, ШагЗаявки, ПоследнийШаг , [Последний статус заявки]
	  , [Время в последнем статусе]=first_value( [Время в последнем статусе]) over (partition by [Номер заявки] order by [Время в последнем статусе] desc) 
	  , [Время в последнем статусе, hh:mm:ss] =first_value( [Время в последнем статусе, hh:mm:ss]) over (partition by [Номер заявки] order by [Время в последнем статусе] desc) 
	  , [ВремяЗатраченоОжиданиеВерификацииКлиента] 
	 -- , [Задача предыдущая]
	  , iif(isnull(ПризнакИсключенияСотрудника,0) = 1 
					or  isnull(ПризнакИсключенияСледСотрудника,0) = 1 
					or isnull(ПризнакИсключенияПредСотрудника,0) = 1
			, 1
			, 0
			) as ПризнакИсключенияСотрудника

		, Работник
		, Назначен
		, [Работник_Пред]
		, [Назначен_Пред]
		, [Работник_След]
		, [Назначен_След]	
		, [Офис заведения заявки]
		, ЗвонокРаботодателюПоТелефонамИзКонтурФокус
		, ЗвонокРаботодателюПоТелефонамИзИнтернет
		, ЗвонокРаботодателюПоТелефонуИзАнкеты
		, ЗвонокКонтактномуЛицу
		, ТипКлиента
		, Партнер
		, ПроверкаДохода
		, [Тип документа подтверждающего доход]
		, КодТипКредитногоПродукта
		, КодПодТипКредитногоПродукта
	  from (

	  select q.[Дата заведения заявки]
		  ,q.[Время заведения]
		  ,q.[Номер заявки]
		  ,q.[ФИО клиента]
		  ,q.[Статус]
		  ,q.[Задача]
		  ,q.[Состояние заявки]
		  ,q.[Дата статуса]
		  ,q.[Дата след.статуса]
		  ,q.[ФИО сотрудника верификации/чекер]
		  ,q.[ВремяЗатрачено]
		  ,q.[Время, час:мин:сек]
		  ,q.[Статус следующий]
		  ,q.[Задача следующая]
		  ,q.[Состояние заявки следующая]
		  ,q.[ПричинаНаим_Исх]
		  ,q.[ПричинаНаим_След]
		  ,q.[Последнее состояние заявки на дату по сотруднику]
		  ,q.[Последний статус заявки на дату по сотруднику]
		  ,q.[Последний статус заявки на дату]
		  ,q.[СотрудникПоследнегоСтатуса]
		  ,q.[ШагЗаявки]
		  ,q.[ПоследнийШаг]
		  ,q.[Последний статус заявки]
      
			 , [Время в последнем статусе]        =     case when [Статус следующий]=[Последний статус заявки] then   cast(cast(@now as datetime)   as decimal(15,10))  -       cast(     cast([Дата след.статуса] as datetime) as decimal(15,10))  end
			 , [Время в последнем статусе, hh:mm:ss] =  case when [Статус следующий]=[Последний статус заявки] then --cast('20000101 '+convert(nvarchar,cast(@now as datetime)- cast(isnull([Дата след.статуса],getdate()) as datetime) ,8) as datetime) 
			   format(abs(datediff(day,@now,[Дата след.статуса])%60),'00')+' д. '+format(abs(datediff(hour,@now,[Дата след.статуса])%60),'00')+' ч. '+format(abs(datediff(minute,@now,[Дата след.статуса])%60),'00')+' мин. '+ format(abs(datediff(second,@now,[Дата след.статуса])%60),'00')+' с.'
			 end
			,q.[ВремяЗатраченоОжиданиеВерификацииКлиента]
			,q.[Задача предыдущая]
			,q.ПризнакИсключенияСотрудника
			, lag(q.ПризнакИсключенияСотрудника) over (partition by [Номер заявки] order by [ШагЗаявки]) ПризнакИсключенияСледСотрудника
			, lead(q.ПризнакИсключенияСотрудника) over (partition by [Номер заявки] order by [ШагЗаявки]) ПризнакИсключенияПредСотрудника
			, Работник
			, Назначен
			, [Работник_Пред]
			, [Назначен_Пред]
			, [Работник_След]
			, [Назначен_След]	
			, q.[Офис заведения заявки]
			, q.ЗвонокРаботодателюПоТелефонамИзКонтурФокус
			, q.ЗвонокРаботодателюПоТелефонамИзИнтернет
			, q.ЗвонокРаботодателюПоТелефонуИзАнкеты
			, q.ЗвонокКонтактномуЛицу
			, q.ТипКлиента
			, q.Партнер
			, q.ПроверкаДохода
			, q.[Тип документа подтверждающего доход]
			, q.КодТипКредитногоПродукта
			, q.КодПодТипКредитногоПродукта
		from
		(
		select [Дата заведения заявки]				    = cast(dateadd(hour,3,[ЗаявкаДата_Исх]) as date)
  			 , [Время заведения]					        = cast(dateadd(hour,3,[ЗаявкаДата_Исх]) as time) 
  			 , [Номер заявки]						          = [ЗаявкаНомер_Исх]
  			 , [ФИО клиента]						          = [ФИО клиента] collate Cyrillic_General_CI_AS 
  			 , [Статус]								            = [СтатусДляСостояния_Исх] collate Cyrillic_General_CI_AS 
  			 , [Задача]								            = [ЗадачаСтатуса_Исх] collate Cyrillic_General_CI_AS 
  			 , [Состояние заявки]					        = [СостояниеЗаявки_Исх] collate Cyrillic_General_CI_AS 
  			 , [Дата статуса]						          = dateadd(hour,3,[Период_Исх])
  			 , [Дата след.статуса]				   	    = dateadd(hour,3,[Период_След])
  			 , [ФИО сотрудника верификации/чекер]	= [ИсполнительНаим_Исх] collate Cyrillic_General_CI_AS 
  			 , [ВремяЗатрачено]						        = [ВремяЗатрачено]
			 , [Время, час:мин:сек]					      = [Tm]
  			 , [Статус следующий]					        = [СтатусДляСостояния_След] collate Cyrillic_General_CI_AS 
  			 , [Задача следующая]					        = [ЗадачаСтатуса_След] collate Cyrillic_General_CI_AS 
  			 , [Состояние заявки следующая]		    = [СостояниеЗаявки_След] collate Cyrillic_General_CI_AS
  			 , [ПричинаНаим_Исх]                  = [ПричинаНаим_Исх] --collate Cyrillic_General_CI_AS 
  			 , [ПричинаНаим_След]                 = [ПричинаНаим_След] --collate Cyrillic_General_CI_AS 
			 , [Последнее состояние заявки на дату по сотруднику] = first_value([СостояниеЗаявки_Исх]) over (partition by [ЗаявкаНомер_Исх],cast(dateadd(hour,3,[Период_След]) as date),[ИсполнительНаим_Исх] order by dateadd(hour,3,[Период_След]) desc) collate Cyrillic_General_CI_AS 
			 , [Последний статус заявки на дату по сотруднику] = first_value( [СтатусДляСостояния_След]) over (partition by [ЗаявкаНомер_Исх],cast(dateadd(hour,3,[Период_След]) as date),[ИсполнительНаим_Исх] order by dateadd(hour,3,[Период_След]) desc) collate Cyrillic_General_CI_AS 
			 , [Последний статус заявки на дату]  = first_value( [СтатусДляСостояния_След]) over (partition by [ЗаявкаНомер_Исх],cast(dateadd(hour,3,[Период_След]) as date)order by dateadd(hour,3,[Период_След]) desc) collate Cyrillic_General_CI_AS 
			 , [Последний статус заявки]  = first_value( [СтатусДляСостояния_След]) over (partition by [ЗаявкаНомер_Исх] order by dateadd(hour,3,[Период_След]) desc) collate Cyrillic_General_CI_AS 
           
			 , СотрудникПоследнегоСтатуса         = lag([ИсполнительНаим_Исх]) over (partition by [ЗаявкаНомер_Исх] order by dateadd(hour,3,[Период_Исх])) collate Cyrillic_General_CI_AS 
			 , ШагЗаявки
			 , ПоследнийШаг
			 , [ВремяЗатраченоОжиданиеВерификацииКлиента]
			 , [Задача предыдущая]					        = [ЗадачаСтатуса_Пред] collate Cyrillic_General_CI_AS 
			 , iif([ЗадачаСтатуса_Пред] = N'task:Новая' and [ЗадачаСтатуса_Исх]=N'task:Автоматически отложено' and [ЗадачаСтатуса_След] =N'task:Переназначена',1,0) ПризнакИсключенияСотрудника
			, Работник = Работник collate Cyrillic_General_CI_AS 
			, Назначен = Назначен collate Cyrillic_General_CI_AS 
			, [Работник_Пред] = Работник_Пред collate Cyrillic_General_CI_AS 
			, [Назначен_Пред] = Назначен_Пред collate Cyrillic_General_CI_AS 
			, [Работник_След] = Работник_След collate Cyrillic_General_CI_AS 
			, [Назначен_След] = Назначен_След collate Cyrillic_General_CI_AS 
			, [Офис заведения заявки] = [Офис заведения заявки] collate Cyrillic_General_CI_AS
			--DWH-2066
			, ЗвонокРаботодателюПоТелефонамИзКонтурФокус
			, ЗвонокРаботодателюПоТелефонамИзИнтернет
			, ЗвонокРаботодателюПоТелефонуИзАнкеты
			, ЗвонокКонтактномуЛицу
			--DWH-2286
			, ТипКлиента
			, Партнер
			, ПроверкаДохода
			, [Тип документа подтверждающего доход]
			, КодТипКредитногоПродукта
			, КодПодТипКредитногоПродукта
	   --
		--select * 
		from #mt_requests_transition_fedor_prod
		)q

		) q1


		SELECT @row_count = @@ROWCOUNT
		IF @isDebug = 1 BEGIN
			SELECT 'INSERT increment into dbo.dm_FedorVerificationRequests_STG', @row_count, datediff(SECOND, @StartDate, getdate())
		END

		-- костыль от 2021-12-06
		-- DWH-1428
		delete 
		--select *
		from  dbo.dm_FedorVerificationRequests_STG
		where 
		[Дата статуса]  between '2021-12-05 20:00:00' and '2021-12-06 06:59:00' 
		and
		[Задача следующая]= 'task:Автоматически отложено' and Задача ='task:Новая'
		--and (Назначен  = 'КОНЧИКОВА ЕЛЕНА ЕВГЕНЬЕВНА' or Назначен  = 'НЕКРАСОВА НАТАЛИЯ ВЛАДИМИРОВНА')

		--IF @isDebug = 1 BEGIN
		--	DROP TABLE IF EXISTS ##dm_FedorVerificationRequests_STG
		--	SELECT * INTO ##dm_FedorVerificationRequests_STG FROM dbo.dm_FedorVerificationRequests_STG
		--END
	commit tran

	if OBJECT_ID('dbo.dm_FedorVerificationRequests_to_del') is null
	begin
		select top(0)
		*
		into dbo.dm_FedorVerificationRequests_to_del
		from dbo.dm_FedorVerificationRequests_STG
		create index ix_Статус_Задача_Дата_статуса 
		on dbo.dm_FedorVerificationRequests_to_del
		(
			[Статус] ASC,
			[Задача] ASC,
			[Статус следующий] ASC,
			[Состояние заявки] ASC,
			[Дата статуса] ASC
		)
		INCLUDE([Дата след.статуса],[Назначен],[Номер заявки],[ФИО клиента],[ВремяЗатрачено],[Работник],[Работник_След],[Дата заведения заявки],[Время заведения],[ШагЗаявки])

		CREATE NONCLUSTERED INDEX [ix_Номер_заявки] 
		ON dbo.dm_FedorVerificationRequests_to_del
		(
			[Номер заявки] ASC,
			[Дата статуса] ASC,
			[Состояние заявки] ASC,
			[Статус] ASC
		)
		INCLUDE([ФИО сотрудника верификации/чекер])
	end
	IF (SELECT count(*) FROM dbo.dm_FedorVerificationRequests_STG) > 0
	begin
		
		truncate table dbo.dm_FedorVerificationRequests_to_del
	--DWH-1716 Оптимизировать обновление данных в отчете верификации
		BEGIN TRAN
			alter table dbo.dm_FedorVerificationRequests switch  to dbo.dm_FedorVerificationRequests_to_del
				with (WAIT_AT_LOW_PRIORITY  ( MAX_DURATION = 1 minutes, ABORT_AFTER_WAIT = SELF ))

			alter table dbo.dm_FedorVerificationRequests_STG switch  to dbo.dm_FedorVerificationRequests
				with (WAIT_AT_LOW_PRIORITY  ( MAX_DURATION = 1 minutes, ABORT_AFTER_WAIT = SELF  ))
		COMMIT TRAN
	END

	-- select * from dbo.dm_FedorVerificationRequests where [Дата заведения заявки]>='20210208' order by [Номер заявки],[Дата статуса]

	end try
	begin catch
		if @@TRANCOUNT>0
			rollback tran
		;throw
	end catch
end
-- ALTER TABLE dbo.dm_FedorVerificationRequests  ADD ПризнакИсключенияСотрудника int NULL
