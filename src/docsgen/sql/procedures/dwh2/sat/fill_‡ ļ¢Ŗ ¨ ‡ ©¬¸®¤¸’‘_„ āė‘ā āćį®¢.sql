
/*
[sat].[fill_ЗаявкаНаЗаймПодПТС_ДатыСтатусов] @mode = 0 @isDebug = 1
	exec [sat].[fill_ЗаявкаНаЗаймПодПТС_ДатыСтатусов]  @RequestGuids =  'C151B42F-4E84-4DB4-99BE-E62855AD156E',@isDebug = 1

	[sat].[fill_ЗаявкаНаЗаймПодПТС_ДатыСтатусов]@RequestGuids =  'C151B42F-4E84-4DB4-99BE-E62855AD156E',@isDebug = 1
*/
CREATE   PROC [sat].[fill_ЗаявкаНаЗаймПодПТС_ДатыСтатусов]
	@mode int = 1 -- 0 - full, 1 - increment, 2 - из списка
	,@isDebug int = 0
	,@RequestGuids nvarchar(max) = null
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_ДатыСтатусов
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @isDebug = isnull(@isDebug, 0)

	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion_loginom bigint
	declare @updated_at datetime = '1900-01-01'

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_ДатыСтатусов
	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_ДатыСтатусов') is not null
		AND @mode in( 1,2)
	begin
		SELECT 
			@rowVersion_loginom = isnull(max(cast(S.ВерсияДанных_loginom as bigint))-100, 0x0),
			@updated_at = dateadd(MINUTE, -160, isnull(max(S.updated_at), '1900-01-01'))
		FROM sat.ЗаявкаНаЗаймПодПТС_ДатыСтатусов AS S
	end

	----дозагрузка
	--IF @isDebug = 1 BEGIN
	--	select @rowVersion_loginom = 0x00000003F409EE34
	--END
	
	-- ДатаПоследнейЗаписиСтатуса
	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(
		СсылкаЗаявки binary(16),
		[GuidЗаявки] uniqueidentifier,
		Номер_int bigint
	)
	CREATE INDEX IX1 ON #t_Заявки(СсылкаЗаявки)
	print 'insert into #t_Заявки from ЗаявкаНаЗаймПодПТС_Статусы'
	--1 
	INSERT #t_Заявки(СсылкаЗаявки,GuidЗаявки, Номер_int)
	SELECT DISTINCT 
		Статусы.СсылкаЗаявки, 
		Заявка.[GuidЗаявки],
		Номер_int = try_cast(Заявка.НомерЗаявки AS bigint)
	FROM sat.ЗаявкаНаЗаймПодПТС_Статусы AS Статусы
		INNER JOIN hub.Заявка AS Заявка
			ON Заявка.GuidЗаявки = Статусы.GuidЗаявки
	WHERE Статусы.updated_at >= @updated_at
	
	print 'insert into #t_Заявки from @mode = 2'
	insert into #t_Заявки
	SELECT DISTINCT 
		Заявка.СсылкаЗаявки, 
		Заявка.[GuidЗаявки],
		Номер_int = try_cast(Заявка.НомерЗаявки AS bigint)
	FROM hub.Заявка AS Заявка
		where exists (select  top(1) 1 from string_split(@RequestGuids, ',') t
			where try_cast(trim(t.value) as uniqueidentifier) = Заявка.[GuidЗаявки]
		)
		and nullif(@RequestGuids,'') is not null
		and @mode = 2
	

	--2
	print 'insert into #t_Заявки from Originationlog'
	INSERT #t_Заявки(СсылкаЗаявки,GuidЗаявки, Номер_int)
	SELECT DISTINCT 
		ЗаявкаНаЗаймПодПТС.СсылкаЗаявки,
		ЗаявкаНаЗаймПодПТС.[GuidЗаявки],
		Номер_int = isnull(L.Number, 
			try_cast(ЗаявкаНаЗаймПодПТС.НомерЗаявки AS bigint)
			)
		
	FROM stg._loginom.Originationlog AS L
		INNER JOIN hub.Заявка AS ЗаявкаНаЗаймПодПТС
			ON ЗаявкаНаЗаймПодПТС.GuidЗаявки = try_cast(l.guid as uniqueidentifier)
		
	WHERE cast(L.rowver as bigint)>= @rowVersion_loginom
	and (number not in (19061300000088) or number is null)	--тестовая заявка


	
	DROP TABLE IF EXISTS #t_Заявки_2
	CREATE TABLE #t_Заявки_2(
		СсылкаЗаявки binary(16),
		GuidЗаявки  uniqueidentifier,
		Номер_int bigint
	)
	print 'insert into #t_Заявки_2'
	INSERT #t_Заявки_2(СсылкаЗаявки,GuidЗаявки, Номер_int)
	SELECT DISTINCT T.СсылкаЗаявки, GuidЗаявки, T.Номер_int FROM #t_Заявки AS T

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Заявки_2
		SELECT * INTO ##t_Заявки_2 FROM #t_Заявки_2
		--RETURN 0
	END
	print 'insert into #t_ЗаявкаНаЗаймПодПТС_ДатыСтатусов'
	select
		СсылкаЗаявки,
		НомерЗаявки,
		GuidЗаявки,
		[Черновик]							= min([Черновик]),
		[Верификация КЦ]					= min([Верификация КЦ]),
		[Предварительное одобрение]			= min([Предварительное одобрение]),
		[Встреча назначена]					= min([Встреча назначена]),
		[Контроль данных]					= min([Контроль данных]),
		[Верификация документов клиента]	= min([Верификация документов клиента]),
		[Одобрены документы клиента]		= min([Одобрены документы клиента]),
		[Верификация документов]			= min([Верификация документов]),
		[Одобрено]							= min([Одобрено]),
		[Договор зарегистрирован]			= min([Договор зарегистрирован]),
		[Заем выдан]						= min([Заем выдан]),
		[ЗаемВыданP2P]						= min([ЗаемВыданP2P]),
		[P2P]								= min([P2P]),
		[Заем погашен]						= min([Заем погашен]),
		[Заем аннулирован]					= min([Заем аннулирован]),
		[Аннулировано]						= min([Аннулировано]),
		[Отказ документов клиента]			= min([Отказ документов клиента]),
		[Отказано]							= min([Отказано]),
		[Отказ клиента]						= min ([Отказ клиента]),
		[Клиент передумал]					= min([Клиент передумал]),
		[Забраковано]						= min([Забраковано]),
		[Договор подписан]					= min([Договор подписан]),
		[PreCall 1]							=min([PreCall 1]			),
		[PreCall 1 accepted]				=min([PreCall 1 accepted]	),
		[Call0.3]							=min([Call0.3]				),
		[Call0.3 accepted]					=min([Call0.3 accepted]		),
		[Call 1]							=min([Call 1]				),
		[Call 1 accept]						=min([Call 1 accept]		),
		[Call 1.2]							=min([Call 1.2]				),
		[Call 1.2 accept]					=min([Call 1.2 accept]		),
		[Call 1.5]							=min([Call 1.5]				),
		[Call 1.5 accept]					=min([Call 1.5 accept]		),
		[Call2]								=min([Call2]				),
		[Call2 accept]						=min([Call2 accept]			),
		[Call 2.1]							=min([Call 2.1]				),
		[Call 2.1 accept]					=min([Call 2.1 accept]		),
		[Call 2.2]							=min([Call 2.2]				),
		[Call 2.2 accept]					=min([Call 2.2 accept]		),
		[Call 3]							=min([Call 3]				),
		[Call 3 accept]						=min([Call 3 accept]		),
		[Call 4]							=min([Call 4]				),
		[Call 4 accept]						=min([Call 4 accept]		),
		[Call 5]							=min([Call 5]				),
		[Call 5 accept]						=min([Call 5 accept]		),
		[Call checkTransfer]				=min([Call checkTransfer]	),
		[Call checkTransfer accept]			=min([Call checkTransfer accept]	)	 ,
		[Call checkTransfer_FEDOR]			=min([Call checkTransfer_FEDOR]		 ),
		[Call checkTransfer_FEDOR accept]	=min([Call checkTransfer_FEDOR accept]),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,
		ВерсияДанных_loginom				= cast(NULL AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_ДатыСтатусов
	from (
		SELECT 
			Статусы.СсылкаЗаявки,
            Заявка.НомерЗаявки,
            Статусы.GuidЗаявки,
            Статусы.ДатаСтатуса,
            Статусы.СтатусЗаявки
		FROM #t_Заявки_2 AS Заявки
			INNER JOIN sat.ЗаявкаНаЗаймПодПТС_Статусы AS Статусы
				ON Статусы.СсылкаЗаявки = Заявки.СсылкаЗаявки
			INNER JOIN hub.Заявка AS Заявка
				ON Заявка.GuidЗаявки = Статусы.GuidЗаявки
	) as SourceData
	PIVOT  
	(  
		min(ДатаСтатуса)
		FOR СтатусЗаявки IN (
			[Черновик]
			,[Верификация КЦ]
			,[Предварительное одобрение]
			,[Встреча назначена]
			,[Контроль данных]
			,[Верификация документов клиента]
			,[Одобрены документы клиента]
			,[Верификация документов]
			,[Одобрено]
			,[Договор зарегистрирован]
			,[Заем выдан]
			,[ЗаемВыданP2P]
			,[P2P]
			,[Заем погашен]
			,[Заем аннулирован]
			,[Аннулировано]
			,[Отказ документов клиента]
			,[Отказано]
			,[Отказ клиента]
			,[Клиент передумал]
			,[Забраковано]
			,[Договор подписан]
			,[PreCall 1]							
			,[PreCall 1 accepted]			
			,[Call0.3]							
			,[Call0.3 accepted]					
			,[Call 1]							
			,[Call 1 accept]						
			,[Call 1.2]							
			,[Call 1.2 accept]					
			,[Call 1.5]							
			,[Call 1.5 accept]					
			,[Call2]								
			,[Call2 accept]						
			,[Call 2.1]							
			,[Call 2.1 accept]					
			,[Call 2.2]							
			,[Call 2.2 accept]					
			,[Call 3]							
			,[Call 3 accept]						
			,[Call 4]							
			,[Call 4 accept]						
			,[Call 5]							
			,[Call 5 accept]						
			,[Call checkTransfer]				
			,[Call checkTransfer accept]			
			,[Call checkTransfer_FEDOR]			
			,[Call checkTransfer_FEDOR accept]	
		)
	) AS PivotTable
	group by 
		PivotTable.СсылкаЗаявки,
		PivotTable.НомерЗаявки,
		PivotTable.GuidЗаявки

	create clustered index cix on #t_ЗаявкаНаЗаймПодПТС_ДатыСтатусов(GuidЗаявки)
	print 'insert into #t_call'
		drop table if exists #t_call
	SELECT 
		НомерЗаявки = isnull(cast(L.Number as varchar(20)), Заявки.Номер_int), 
		Call_date = L.Call_date, 
		[Call_accept_date] =
			CASE 
				WHEN L.Decision = 'accept'
				THEN L.Call_date 
			END,
		Call = cast(Stage as nvarchar(255)),
		L.rowver,
		Заявки.GuidЗаявки
	INTO #t_call
	FROM #t_Заявки_2 AS Заявки
		INNER JOIN Stg._loginom.Originationlog AS L
			ON try_cast(L.guid as uniqueidentifier)  = Заявки.GuidЗаявки
			--and( l.Number =Заявки.Номер_int  or l.Number is null)
	WHERE 1=1
	and (l.number not in (19061300000088) or l.number is null)--тестовая заявка
	and L.Stage in (
		'PreCall 1'
		,'Call 03'
		,'Call 1'
		,'Call 1.2'
		,'Call 1.5'
		,'Call 2'
		,'Call 2.1'
		,'Call 2.2'
		,'Call 3'
		,'Call 4'
		,'Call 5'
		,'Call_checkTransfer'
		,'Call_checkTransfer_FEDOR'
		)
	print 'delete dublicate from #t_call'
	create clustered index cix on #t_call(GuidЗаявки, Call)
	;with v as (
		SELECT 
			*, 
			rn = row_number() over(partition by GuidЗаявки, Call order by [Call_accept_date], Call_date)
		FROM #t_call
	)
	DELETE from v where v.rn > 1
	IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##t_call
	SELECT * INTO ##t_call FROM #t_call
	--RETURN 0
	END

	print 'update ДатыСтатусов from loginom'
	;with cte as 
	(
	select GuidЗаявки
		,[PreCall 1]						= min(iif(call = 'PreCall 1',	Call_date		  , null))
		,[PreCall 1 accepted]				= min(iif(call = 'PreCall 1',	[Call_accept_date], null))		
		,[Call0.3]							= min(iif(Call = 'Call 03',		Call_date		  ,	null))
		,[Call0.3 accepted]					= min(iif(Call = 'Call 03',		[Call_accept_date],	null))	
		,[Call 1]							= min(iif(call = 'Call 1',		Call_date		   ,null))
		,[Call 1 accept]					= min(iif(call = 'Call 1',		[Call_accept_date] ,null))	
		,[Call 1.2]							= min(iif(call = 'Call 1.2',	Call_date		   ,null))		
		,[Call 1.2 accept]					= min(iif(call = 'Call 1.2',	[Call_accept_date] ,null))	
		,[Call 1.5]							= min(iif(call = 'Call 1.5',	Call_date		   ,null))		
		,[Call 1.5 accept]					= min(iif(call = 'Call 1.5',	[Call_accept_date] ,null))	
		,[Call2]							= min(iif(call = 'Call 2',		Call_date		   ,null))	
		,[Call2 accept]						= min(iif(call = 'Call 2',		[Call_accept_date] ,null))	
		,[Call 2.1]							= min(iif(call = 'Call 2.1',	Call_date		   ,null))		
		,[Call 2.1 accept]					= min(iif(call = 'Call 2.1',	[Call_accept_date] ,null))	
		,[Call 2.2]							= min(iif(call = 'Call 2.2',	Call_date		   ,null))		
		,[Call 2.2 accept]					= min(iif(call = 'Call 2.2',	[Call_accept_date] ,null))	
		,[Call 3]							= min(iif(call = 'Call 3',		Call_date		   ,null))
		,[Call 3 accept]					= min(iif(call = 'Call 3',		[Call_accept_date] ,null))	
		,[Call 4]							= min(iif(call = 'Call 4',		Call_date		   ,null))
		,[Call 4 accept]					= min(iif(call = 'Call 4',		[Call_accept_date] ,null))	
		,[Call 5]							= min(iif(call = 'Call 5',		Call_date		   ,null))
		,[Call 5 accept]					= min(iif(call = 'Call 5',		[Call_accept_date] ,null))	
		,[Call checkTransfer]				= min(iif(call = 'Call_checkTransfer',Call_date		   ,null))
		,[Call checkTransfer accept]		= min(iif(call = 'Call_checkTransfer',[Call_accept_date] , null))
		,[Call checkTransfer_FEDOR]			= min(iif(call = 'Call_checkTransfer_FEDOR',Call_date		   , null))
		,[Call checkTransfer_FEDOR accept]	= min(iif(call = 'Call_checkTransfer_FEDOR',[Call_accept_date] , null))
		,ВерсияДанных_loginom				= max(L.rowver)
		from #t_call l
		group by GuidЗаявки
	)
	UPDATE ДатыСтатусов
	SET 
		 [PreCall 1]						= isnull(l.[PreCall 1]						,	ДатыСтатусов.[PreCall 1]						)
		,[PreCall 1 accepted]				= isnull(l.[PreCall 1 accepted]				,	ДатыСтатусов.[PreCall 1 accepted]				)
		,[Call0.3]							= isnull(l.[Call0.3]						, 	ДатыСтатусов.[Call0.3]							)
		,[Call0.3 accepted]					= isnull(l.[Call0.3 accepted]				, 	ДатыСтатусов.[Call0.3 accepted]					)
		,[Call 1]							= isnull(l.[Call 1]							,	ДатыСтатусов.[Call 1]							)
		,[Call 1 accept]					= isnull(l.[Call 1 accept]					,	ДатыСтатусов.[Call 1 accept]					)
		,[Call 1.2]							= isnull(l.[Call 1.2]						, 	ДатыСтатусов.[Call 1.2]							)
		,[Call 1.2 accept]					= isnull(l.[Call 1.2 accept]				, 	ДатыСтатусов.[Call 1.2 accept]					)
		,[Call 1.5]							= isnull(l.[Call 1.5]						, 	ДатыСтатусов.[Call 1.5]							)
		,[Call 1.5 accept]					= isnull(l.[Call 1.5 accept]				, 	ДатыСтатусов.[Call 1.5 accept]					)
		,[Call2]							= isnull(l.[Call2]							, 	ДатыСтатусов.[Call2]							)
		,[Call2 accept]						= isnull(l.[Call2 accept]					, 	ДатыСтатусов.[Call2 accept]						)
		,[Call 2.1]							= isnull(l.[Call 2.1]						, 	ДатыСтатусов.[Call 2.1]							)
		,[Call 2.1 accept]					= isnull(l.[Call 2.1 accept]				, 	ДатыСтатусов.[Call 2.1 accept]					)
		,[Call 2.2]							= isnull(l.[Call 2.2]						, 	ДатыСтатусов.[Call 2.2]							)
		,[Call 2.2 accept]					= isnull(l.[Call 2.2 accept]				, 	ДатыСтатусов.[Call 2.2 accept]					)
		,[Call 3]							= isnull(l.[Call 3]							, 	ДатыСтатусов.[Call 3]							)
		,[Call 3 accept]					= isnull(l.[Call 3 accept]					, 	ДатыСтатусов.[Call 3 accept]					)
		,[Call 4]							= isnull(l.[Call 4]							, 	ДатыСтатусов.[Call 4]							)
		,[Call 4 accept]					= isnull(l.[Call 4 accept]					, 	ДатыСтатусов.[Call 4 accept]					)
		,[Call 5]							= isnull(l.[Call 5]							, 	ДатыСтатусов.[Call 5]							)
		,[Call 5 accept]					= isnull(l.[Call 5 accept]					, 	ДатыСтатусов.[Call 5 accept]					)
		,[Call checkTransfer]				= isnull(l.[Call checkTransfer]				, 	ДатыСтатусов.[Call checkTransfer]				)
		,[Call checkTransfer accept]		= isnull(l.[Call checkTransfer accept]		, 	ДатыСтатусов.[Call checkTransfer accept]		)
		,[Call checkTransfer_FEDOR]			= isnull(l.[Call checkTransfer_FEDOR]			, 	ДатыСтатусов.[Call checkTransfer_FEDOR]			)
		,[Call checkTransfer_FEDOR accept]	= isnull(l.[Call checkTransfer_FEDOR accept]	, 	ДатыСтатусов.[Call checkTransfer_FEDOR accept]	)
		,ВерсияДанных_loginom				= isnull(l.ВерсияДанных_loginom, ДатыСтатусов.ВерсияДанных_loginom	)			
	FROM #t_ЗаявкаНаЗаймПодПТС_ДатыСтатусов AS ДатыСтатусов
		LEFT JOIN cte AS L
			ON L.GuidЗаявки = ДатыСтатусов.GuidЗаявки



	--------------------------------------------------------------------
	----------------------------------------------------------------------------------
	--[ЗаемВыданP2P]
	----------------------------------------------------------------------------------
	UPDATE ДатыСтатусов
	SET ЗаемВыданP2P = dateadd(hour, 3, P2P.created_at)
	FROM #t_ЗаявкаНаЗаймПодПТС_ДатыСтатусов AS ДатыСтатусов
		INNER JOIN Stg._p2p.requests AS P2P
			ON P2P.number = ДатыСтатусов.НомерЗаявки
	WHERE P2P.request_status_guid in (
			'de5722f1-9178-466a-88bc-1a1282728752' --Погашен
			,'81079828-9834-4614-9825-84b646938758' --Заем выдан
		)

	----------------------------------------------------------------------------------
	IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##t_ЗаявкаНаЗаймПодПТС_ДатыСтатусов
	SELECT * INTO ##t_ЗаявкаНаЗаймПодПТС_ДатыСтатусов FROM #t_ЗаявкаНаЗаймПодПТС_ДатыСтатусов
	--RETURN 0
	END
	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_ДатыСтатусов') is null
	begin
		select top(0)
			СсылкаЗаявки
            ,GuidЗаявки
			,[Черновик]
			,[Верификация КЦ]
			,[Предварительное одобрение]
			,[Встреча назначена]
			,[Контроль данных]
			,[Верификация документов клиента]
			,[Одобрены документы клиента]
			,[Верификация документов]
			,[Одобрено]
			,[Договор зарегистрирован]
			,[Заем выдан]
			,[ЗаемВыданP2P]
			,[P2P]
			,[Заем погашен]
			,[Заем аннулирован]
			,[Аннулировано]
			,[Отказ документов клиента]
			,[Отказано]
			,[Отказ клиента]
			,[Клиент передумал]
			,[Забраковано]
			,[Договор подписан]
			,[PreCall 1]						
			,[PreCall 1 accepted]				
			,[Call0.3]							
			,[Call0.3 accepted]				
			,[Call 1]							
			,[Call 1 accept]					
			,[Call 1.2]						
			,[Call 1.2 accept]					
			,[Call 1.5]						
			,[Call 1.5 accept]					
			,[Call2]							
			,[Call2 accept]					
			,[Call 2.1]						
			,[Call 2.1 accept]					
			,[Call 2.2]						
			,[Call 2.2 accept]					
			,[Call 3]							
			,[Call 3 accept]					
			,[Call 4]							
			,[Call 4 accept]					
			,[Call 5]							
			,[Call 5 accept]					
			,[Call checkTransfer]				
			,[Call checkTransfer accept]		
			,[Call checkTransfer_FEDOR]		
			,[Call checkTransfer_FEDOR accept]
            ,created_at
            ,updated_at
            ,spFillName
            ,ВерсияДанных_loginom
		into sat.ЗаявкаНаЗаймПодПТС_ДатыСтатусов
		from #t_ЗаявкаНаЗаймПодПТС_ДатыСтатусов

		alter table sat.ЗаявкаНаЗаймПодПТС_ДатыСтатусов
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_ДатыСтатусов
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_ДатыСтатусов PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	begin tran
	/*
		if @mode = 0
		begin
			truncate table 	 sat.ЗаявкаНаЗаймПодПТС_ДатыСтатусов
		end
		*/
		print 'merge'
		merge sat.ЗаявкаНаЗаймПодПТС_ДатыСтатусов t
		using #t_ЗаявкаНаЗаймПодПТС_ДатыСтатусов s
		on  T.GuidЗаявки = S.GuidЗаявки
		when not matched then insert 
		(
			СсылкаЗаявки
            ,GuidЗаявки
			,[Черновик]
			,[Верификация КЦ]
			,[Предварительное одобрение]
			,[Встреча назначена]
			,[Контроль данных]
			,[Верификация документов клиента]
			,[Одобрены документы клиента]
			,[Верификация документов]
			,[Одобрено]
			,[Договор зарегистрирован]
			,[Заем выдан]
			,[ЗаемВыданP2P]
			,[P2P]
			,[Заем погашен]
			,[Заем аннулирован]
			,[Аннулировано]
			,[Отказ документов клиента]
			,[Отказано]
			,[Отказ клиента]
			,[Клиент передумал]
			,[Забраковано]
			,[Договор подписан]
			,[PreCall 1]						
			,[PreCall 1 accepted]				
			,[Call0.3]							
			,[Call0.3 accepted]				
			,[Call 1]							
			,[Call 1 accept]					
			,[Call 1.2]						
			,[Call 1.2 accept]					
			,[Call 1.5]						
			,[Call 1.5 accept]					
			,[Call2]							
			,[Call2 accept]					
			,[Call 2.1]						
			,[Call 2.1 accept]					
			,[Call 2.2]						
			,[Call 2.2 accept]					
			,[Call 3]							
			,[Call 3 accept]					
			,[Call 4]							
			,[Call 4 accept]					
			,[Call 5]							
			,[Call 5 accept]					
			,[Call checkTransfer]				
			,[Call checkTransfer accept]		
			,[Call checkTransfer_FEDOR]		
			,[Call checkTransfer_FEDOR accept]
            ,created_at
            ,updated_at
            ,spFillName
            ,ВерсияДанных_loginom
		)
		values(
			 s.СсылкаЗаявки
            ,s.GuidЗаявки
			,s.[Черновик]
			,s.[Верификация КЦ]
			,s.[Предварительное одобрение]
			,s.[Встреча назначена]
			,s.[Контроль данных]
			,s.[Верификация документов клиента]
			,s.[Одобрены документы клиента]
			,s.[Верификация документов]
			,s.[Одобрено]
			,s.[Договор зарегистрирован]
			,s.[Заем выдан]
			,s.[ЗаемВыданP2P]
			,s.[P2P]
			,s.[Заем погашен]
			,s.[Заем аннулирован]
			,s.[Аннулировано]
			,s.[Отказ документов клиента]
			,s.[Отказано]
			,s.[Отказ клиента]
			,s.[Клиент передумал]
			,s.[Забраковано]
			,s.[Договор подписан]
			,s.[PreCall 1]						
			,s.[PreCall 1 accepted]				
			,s.[Call0.3]							
			,s.[Call0.3 accepted]				
			,s.[Call 1]							
			,s.[Call 1 accept]					
			,s.[Call 1.2]						
			,s.[Call 1.2 accept]					
			,s.[Call 1.5]						
			,s.[Call 1.5 accept]					
			,s.[Call2]							
			,s.[Call2 accept]					
			,s.[Call 2.1]						
			,s.[Call 2.1 accept]					
			,s.[Call 2.2]						
			,s.[Call 2.2 accept]					
			,s.[Call 3]							
			,s.[Call 3 accept]					
			,s.[Call 4]							
			,s.[Call 4 accept]					
			,s.[Call 5]							
			,s.[Call 5 accept]					
			,s.[Call checkTransfer]				
			,s.[Call checkTransfer accept]		
			,s.[Call checkTransfer_FEDOR]		
			,s.[Call checkTransfer_FEDOR accept]
            ,s.created_at
            ,s.updated_at
            ,s.spFillName
			,s.ВерсияДанных_loginom
		)
		when matched then update 
			set 
			  [Черновик]						= s.[Черновик]						
			, [Верификация КЦ]					= s.[Верификация КЦ]					
			, [Предварительное одобрение]		= s.[Предварительное одобрение]		
			, [Встреча назначена]				= s.[Встреча назначена]				
			, [Контроль данных]					= s.[Контроль данных]					
			, [Верификация документов клиента]	= s.[Верификация документов клиента]	
			, [Одобрены документы клиента]		= s.[Одобрены документы клиента]		
			, [Верификация документов]			= s.[Верификация документов]			
			, [Одобрено]						= s.[Одобрено]						
			, [Договор зарегистрирован]			= s.[Договор зарегистрирован]			
			, [Заем выдан]						= s.[Заем выдан]						
			, [ЗаемВыданP2P]					= s.[ЗаемВыданP2P]					
			, [P2P]								= s.[P2P]								
			, [Заем погашен]					= s.[Заем погашен]					
			, [Заем аннулирован]				= s.[Заем аннулирован]				
			, [Аннулировано]					= s.[Аннулировано]					
			, [Отказ документов клиента]		= s.[Отказ документов клиента]		
			, [Отказано]						= s.[Отказано]						
			, [Отказ клиента]					= s.[Отказ клиента]					
			, [Клиент передумал]				= s.[Клиент передумал]				
			, [Забраковано]						= s.[Забраковано]						
			, [Договор подписан]				= s.[Договор подписан]				
			, [PreCall 1]						= s.[PreCall 1]						
			, [PreCall 1 accepted]				= s.[PreCall 1 accepted]				
			, [Call0.3]							= s.[Call0.3]							
			, [Call0.3 accepted]				= s.[Call0.3 accepted]				
			, [Call 1]							= s.[Call 1]							
			, [Call 1 accept]					= s.[Call 1 accept]					
			, [Call 1.2]						= s.[Call 1.2]						
			, [Call 1.2 accept]					= s.[Call 1.2 accept]					
			, [Call 1.5]						= s.[Call 1.5]						
			, [Call 1.5 accept]					= s.[Call 1.5 accept]					
			, [Call2]							= s.[Call2]							
			, [Call2 accept]					= s.[Call2 accept]					
			, [Call 2.1]						= s.[Call 2.1]						
			, [Call 2.1 accept]					= s.[Call 2.1 accept]					
			, [Call 2.2]						= s.[Call 2.2]						
			, [Call 2.2 accept]					= s.[Call 2.2 accept]					
			, [Call 3]							= s.[Call 3]							
			, [Call 3 accept]					= s.[Call 3 accept]					
			, [Call 4]							= s.[Call 4]							
			, [Call 4 accept]					= s.[Call 4 accept]					
			, [Call 5]							= s.[Call 5]							
			, [Call 5 accept]					= s.[Call 5 accept]					
			, [Call checkTransfer]				= s.[Call checkTransfer]				
			, [Call checkTransfer accept]		= s.[Call checkTransfer accept]		
			, [Call checkTransfer_FEDOR]		= s.[Call checkTransfer_FEDOR]		
			, [Call checkTransfer_FEDOR accept]	= s.[Call checkTransfer_FEDOR accept]
            , updated_at						= s.updated_at						
            , spFillName						= s.spFillName						
            , ВерсияДанных_loginom				= isnull(s.ВерсияДанных_loginom	, t.ВерсияДанных_loginom)
			;
	commit tran

end try
begin catch
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	SELECT @message = concat('exec ', @spName)

	SELECT @eventType = 'Data Valut ERROR'

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @spName,
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 1,
		@SendToSlack = 1

	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end
