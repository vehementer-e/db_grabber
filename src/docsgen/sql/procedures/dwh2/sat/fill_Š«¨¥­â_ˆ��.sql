--exec  [sat].[fill_Клиент_ИНН] @source= '_1cCRM.Справочник_Партнеры', @mode =0 
--exec  [sat].[fill_Клиент_ИНН] @source= '_loginom.application', @mode =0 

CREATE PROC [sat].[fill_Клиент_ИНН]
	@mode int = 1 -- 0 - full, 1 - increment
	,@source varchar(100) = 'ALL' --таблица-источник
	,@INN_json_array nvarchar(max) = NULL
	,@isDebug int = 0
as
begin
	--truncate table sat.Клиент_ИНН
begin try
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @mode = isnull(@mode, 1)
	SELECT @source = isnull(@source, 'ALL')

	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	declare @ДатаПолученияИНН date = '2000-01-01'
	DECLARE @updated_at datetime = '1900-01-01'

	DROP TABLE IF EXISTS #t_Клиент_ИНН
	CREATE TABLE #t_Клиент_ИНН
	(
		[GuidКлиент] [uniqueidentifier] NOT NULL,
		[СсылкаКлиент] [binary] (16) NOT NULL,
		[ИНН] [varchar] (12) NULL,
		[ДатаПолученияИНН] [date] NULL,
		[ТаблицаИсточник] [varchar](100) NOT NULL,
		[created_at] [datetime] NOT NULL,
		[updated_at] [datetime] NOT NULL,
		[spFillName] [nvarchar] (255) NULL,
		[ВерсияДанных] [binary] (8) NULL,
		sourceService	nvarchar(255) null
	)

	--------------------------------------------------------------------------------------------
	-- 1 from '_1cCRM.Справочник_Партнеры'
	--------------------------------------------------------------------------------------------
	IF @source IN ('_1cCRM.Справочник_Партнеры', 'ALL')
	BEGIN
		if OBJECT_ID ('sat.Клиент_ИНН') is not null
			AND @mode = 1
		begin
			select @rowVersion = max(ВерсияДанных) 
				,@ДатаПолученияИНН = max(ДатаПолученияИНН)
				from sat.Клиент_ИНН WHERE ТаблицаИсточник IN('_1cCRM.Справочник_Партнеры')
			select @rowVersion = isnull(@rowVersion-100, 0x0)
				,@ДатаПолученияИНН = isnull(dateadd(dd,-5, cast(@ДатаПолученияИНН as date)), '2000-01-01')
				
		end

		INSERT #t_Клиент_ИНН
		(
			GuidКлиент,
			СсылкаКлиент,
			ИНН,
			ДатаПолученияИНН,
			ТаблицаИсточник,
			sourceService,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
			
		)
		SELECT DISTINCT
			GuidКлиент = cast([dbo].[getGUIDFrom1C_IDRREF](Партнеры.Ссылка) as uniqueidentifier),
			СсылкаКлиент = Партнеры.Ссылка,
			ИНН = cast(
				COALESCE(
					nullif(replace(ИсторияЗапросовИНН.ИНН,' ','') , '') 
					,nullif(replace(Партнеры.ИННИзСервиса,' ',''), '') 
					)
				AS varchar(12)),
			ДатаПолученияИНН =cast(ИсторияЗапросовИНН.ДатаПолученияИНН as date), 
			ТаблицаИсточник = '_1cCRM.Справочник_Партнеры',
			sourceService = ИсторияЗапросовИНН.ИсточникДанныхИНН_Код, --Система источник получения информации
			created_at = CURRENT_TIMESTAMP,
			updated_at = CURRENT_TIMESTAMP,
			spFillName = @spName,
			ВерсияДанных = cast(Партнеры.ВерсияДанных AS binary(8))
		--into #t_Клиент_ИНН
		--SELECT *
		from Stg._1cCRM.Справочник_Партнеры AS Партнеры
		left join (
		select 
			 ИсторияЗапросовИНН.Клиент
			,ИсторияЗапросовИНН.ИНН
			,ДатаПолученияИНН = iif(year(ИсторияЗапросовИНН.ДатаПолученияИНН)>3000
				, dateadd(year, -2000, ИсторияЗапросовИНН.ДатаПолученияИНН)
				, null)
			,ИсточникДанныхИНН_Код			= ИсточникиДанныхИНН.Код	
			,ИсточникДанныхИНН_Наименование = ИсточникиДанныхИНН.Наименование
			,nRow = ROW_NUMBER() over(partition by ИсторияЗапросовИНН.Клиент
				order by case when  ИсточникиДанныхИНН.Код = 'fns' then 0 else  1 end asc
				,ИсторияЗапросовИНН.ДатаПолученияИНН desc)

		from Stg._1cCRM.РегистрСведений_ИсторияЗапросовИНН  ИсторияЗапросовИНН 
		left join Stg._1cCRM.Справочник_ИсточникиДанныхИНН ИсточникиДанныхИНН on 
			ИсточникиДанныхИНН.Ссылка = ИсторияЗапросовИНН.ИсточникДанныхИНН
		) ИсторияЗапросовИНН on ИсторияЗапросовИНН.Клиент = Партнеры.Ссылка
			and nRow = 1 
		where dm.Check_INN_Fiz(COALESCE(
					nullif(replace(ИсторияЗапросовИНН.ИНН,' ','') , '') 
					,nullif(replace(Партнеры.ИННИзСервиса,' ',''), '') 
					)) = 0
			and (Партнеры.ВерсияДанных > @rowVersion
				or isnull(ИсторияЗапросовИНН.ДатаПолученияИНН, '2000-01-01')> = @ДатаПолученияИНН
				)

			 

		
		if OBJECT_ID('sat.Клиент_ИНН') is null
		begin
			select top(0)
				GuidКлиент,
				СсылкаКлиент,
				ИНН,
				ДатаПолученияИНН,
				ТаблицаИсточник,
				created_at,
				updated_at,
				spFillName,
				ВерсияДанных
			into sat.Клиент_ИНН
			from #t_Клиент_ИНН

			alter table sat.Клиент_ИНН
				alter column GuidКлиент uniqueidentifier not null

			alter table sat.Клиент_ИНН
				alter column ТаблицаИсточник varchar(100) not null

			ALTER TABLE sat.Клиент_ИНН
				ADD CONSTRAINT PK_Клиент_ИНН PRIMARY KEY CLUSTERED (GuidКлиент, ТаблицаИсточник)

			CREATE INDEX ix_ВерсияДанных ON sat.Клиент_ИНН(ТаблицаИсточник, ВерсияДанных)
		end
	
		--begin tran
		merge sat.Клиент_ИНН t
		using #t_Клиент_ИНН s
			on t.GuidКлиент = s.GuidКлиент
			AND t.ТаблицаИсточник = s.ТаблицаИсточник
		when not matched then insert
		(
			GuidКлиент,
			СсылкаКлиент,
			ИНН,
			ДатаПолученияИНН,
			ТаблицаИсточник,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных,
			sourceService
		) values
		(
			s.GuidКлиент,
			s.СсылкаКлиент,
			s.ИНН,
			s.ДатаПолученияИНН,
			s.ТаблицаИсточник,
			s.created_at,
			s.updated_at,
			s.spFillName,
			s.ВерсияДанных,
			s.sourceService
		)
		when matched and t.ВерсияДанных <> s.ВерсияДанных
			or isnull(t.sourceService, '') <> isnull(s.sourceService, '')
			or t.ИНН != s.ИНН
		then update SET
			t.ИНН = s.ИНН,
			t.ДатаПолученияИНН = s.ДатаПолученияИНН,
			--t.ТаблицаИсточник = s.ТаблицаИсточник,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName,
			t.ВерсияДанных = s.ВерсияДанных,
			t.sourceService = s.sourceService
			;
		--commit tran
	END	
	--//end if @source IN ('_1cCRM.Справочник_Партнеры', 'ALL')

	--------------------------------------------------------------------------------------------
	-- 2 from _loginom.Originationlog
	--------------------------------------------------------------------------------------------
	IF @source IN ('_loginom.Originationlog', 'ALL')
	BEGIN
		set @rowVersion = 0x0
		TRUNCATE TABLE #t_Клиент_ИНН

		if OBJECT_ID ('sat.Клиент_ИНН') is not null
			AND @mode = 1
		begin
			set @rowVersion = isnull((select max(ВерсияДанных)-100 from sat.Клиент_ИНН WHERE ТаблицаИсточник = '_loginom.Originationlog'), 0x0)
		end

		INSERT #t_Клиент_ИНН
		(
			GuidКлиент,
			СсылкаКлиент,
			ИНН,
			ДатаПолученияИНН,
			ТаблицаИсточник,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		)
		SELECT
			GuidКлиент = cast([dbo].[getGUIDFrom1C_IDRREF](t.Партнер) as uniqueidentifier),
			СсылкаКлиент = t.Партнер,
			ИНН = t.INN_Xneo,
			ДатаПолученияИНН = cast(t.Call_date AS date),
			ТаблицаИсточник = cast('_loginom.Originationlog' AS varchar(100)), --Таблица / Система источник получения информации
			created_at = CURRENT_TIMESTAMP,
			updated_at = CURRENT_TIMESTAMP,
			spFillName = @spName,
			ВерсияДанных = cast(t.rowver AS binary(8))
		--SELECT 
		--	t.Партнер,
		--	t.INN_Xneo,
		--	t.rowver,
		--	t.Номер,
		--	t.nRow 
		--into #t_Клиент_ИНН
		FROM (
				SELECT 
					ЗаявкаНаЗаймПодПТС.Партнер
					,t_Originationlog.INN_Xneo
					,t_Originationlog.rowver
					,ЗаявкаНаЗаймПодПТС.Номер
					,t_Originationlog.Call_date
					,nRow = ROW_NUMBER() over(partition by ЗаявкаНаЗаймПодПТС.Партнер order by t_Originationlog.Call_date desc)
				FROM (
						select 
							nRow = row_number() OVER(PARTITION BY L.guid ORDER BY L.Call_date DESC) 
							,INN_Xneo =	cast(replace(L.INN_Xneo,' ','') AS varchar(12))
							,L.rowver
							,RequestGuid = L.guid
							,L.Call_date
						from Stg._loginom.Originationlog AS L
						where L.rowver > @rowVersion
							AND dm.Check_INN_Fiz(replace(L.INN_Xneo,' ','')) = 0
							and L.username = 'service'
					) AS t_Originationlog 
					INNER JOIN Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС 
					ON 1=1
					--AND ЗаявкаНаЗаймПодПТС.Номер = cast(t.Number as nvarchar(21))
					AND ЗаявкаНаЗаймПодПТС.Ссылка = dbo.get1CIDRREF_FromGUID(t_Originationlog.RequestGuid)
					AND ЗаявкаНаЗаймПодПТС.Партнер <> 0x0
			
				WHERE t_Originationlog.nRow = 1	
			) AS t
		WHERE t.nRow = 1

		merge sat.Клиент_ИНН t
		using #t_Клиент_ИНН s
			on t.GuidКлиент = s.GuidКлиент
			AND t.ТаблицаИсточник = s.ТаблицаИсточник
		when not matched then insert
		(
			GuidКлиент,
			СсылкаКлиент,
			ИНН,
			ДатаПолученияИНН,
			ТаблицаИсточник,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		) values
		(
			s.GuidКлиент,
			s.СсылкаКлиент,
			s.ИНН,
			s.ДатаПолученияИНН,
			s.ТаблицаИсточник,
			s.created_at,
			s.updated_at,
			s.spFillName,
			s.ВерсияДанных
		)
		when matched and t.ВерсияДанных <> s.ВерсияДанных
		then update SET
			t.ИНН = s.ИНН,
			t.ДатаПолученияИНН = s.ДатаПолученияИНН,
			--t.ТаблицаИсточник = s.ТаблицаИсточник,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName,
			t.ВерсияДанных = s.ВерсияДанных
			;
	END	
	--//end if @source IN ('_loginom.Originationlog', 'ALL')


	--------------------------------------------------------------------------------------------
	-- 3 from RMQ.ReceivedMessages_interactions_inn
	--------------------------------------------------------------------------------------------
	IF @source IN ('RMQ.ReceivedMessages_interactions_inn', 'ALL')
		--AND @INN_json_array IS NOT NULL
	BEGIN
		set @rowVersion = 0x0
		TRUNCATE TABLE #t_Клиент_ИНН

		IF @INN_json_array IS NOT NULL
		BEGIN
			INSERT #t_Клиент_ИНН
			(
				GuidКлиент,
				СсылкаКлиент,
				ИНН,
				ДатаПолученияИНН,
				ТаблицаИсточник,
				created_at,
				updated_at,
				spFillName,
				ВерсияДанных,
				sourceService
			)
			SELECT 
				A.GuidКлиент,
				A.СсылкаКлиент,
				A.ИНН,
				A.ДатаПолученияИНН,
				A.ТаблицаИсточник,
				A.created_at,
				A.updated_at,
				A.spFillName,
				A.ВерсияДанных,
				sourceService = 'xneo'
			FROM (
				SELECT DISTINCT
					GuidКлиент = D.clientId, --cast([dbo].[getGUIDFrom1C_IDRREF](Партнеры.Ссылка) as uniqueidentifier),
					СсылкаКлиент = dbo.get1CIDRREF_FromGUID(D.clientId),
					ИНН = cast(replace(D.inn,' ','') AS varchar(12)),
					ДатаПолученияИНН = try_cast(dateadd(SECOND, D.publishTime, cast('1970-01-01' AS datetime)) AS date),
					ТаблицаИсточник = cast('RMQ.ReceivedMessages_interactions_inn' AS varchar(100)), --Таблица / Система источник получения информации
					created_at = CURRENT_TIMESTAMP,
					updated_at = CURRENT_TIMESTAMP,
					spFillName = @spName,
					ВерсияДанных = cast(NULL AS binary(8)),
					rn = row_number() OVER(PARTITION BY D.clientId ORDER BY getdate())
				FROM OPENJSON (@INN_json_array, '$') AS A
					OUTER APPLY (
						SELECT 
							T.clientId,
							T.inn,
							T.publishTime
						FROM OPENJSON (A.[value], '$')
							with (
								clientId nvarchar(64) '$.clientId',
								inn nvarchar(50) '$.inn',
								publishTime bigint '$.publishTime'
							) AS T
						) AS D
					WHERE 1=1
						AND try_convert(uniqueidentifier, D.clientId) IS NOT NULL
						AND dm.Check_INN_Fiz(replace(D.inn,' ','')) = 0
			) AS A
			WHERE A.rn = 1

			merge sat.Клиент_ИНН t
			using #t_Клиент_ИНН s
				on t.GuidКлиент = s.GuidКлиент
				AND t.ТаблицаИсточник = s.ТаблицаИсточник
			when not matched then insert
			(
				GuidКлиент,
				СсылкаКлиент,
				ИНН,
				ДатаПолученияИНН,
				ТаблицаИсточник,
				created_at,
				updated_at,
				spFillName,
				ВерсияДанных,
				sourceService
			) values
			(
				s.GuidКлиент,
				s.СсылкаКлиент,
				s.ИНН,
				s.ДатаПолученияИНН,
				s.ТаблицаИсточник,
				s.created_at,
				s.updated_at,
				s.spFillName,
				s.ВерсияДанных,
				s.sourceService
			)
			when matched --and t.ВерсияДанных <> s.ВерсияДанных
			then update SET
				t.ИНН = s.ИНН,
				t.ДатаПолученияИНН = s.ДатаПолученияИНН,
				--t.ТаблицаИсточник = s.ТаблицаИсточник,
				t.updated_at = s.updated_at,
				t.spFillName = s.spFillName,
				t.ВерсияДанных = s.ВерсияДанных,
				t.sourceService = s.sourceService

				;


		END --// IF @INN_json_array IS NOT NULL
		ELSE BEGIN

			-- из RMQ.ReceivedMessages_interactions_inn

			drop table if exists #t_data_RMQ
			select 
				recordId = t.guid_id,
				ReceivedMessage
			into #t_data_RMQ
			from Stg.RMQ.ReceivedMessages_interactions_inn t
			where t.ReceiveDate between dateadd(dd, -4, getdate()) and getdate()
				AND isnull(t.isDeleted,0) = 0
				--test
				--AND t.ReceiveDate > cast(getdate() AS date)

			if exists(select top(1) 1 from #t_data_RMQ)
			begin
				drop table if exists #result
				;with cte as (
					select t.recordId
						, t_data.publishTime
						, clientId = isnull(relationships.clientId, relationships._clientId)
						, relationships.eventId
						, relationships.interactionId
						, t_data.included
						from #t_data_RMQ t
						outer apply OPENJSON (t.ReceivedMessage, '$') 
						with (
						--	message_guid	nvarchar(128)	'$.meta'
							publishTime		bigint			'$.meta.time.publish'
							,relationships	nvarchar(max)   '$.data.relationships'  as json
							,included		nvarchar(max)	'$.included'  as json
						) t_data
						outer apply OPENJSON (t_data.relationships, '$') with
						(
							clientId	nvarchar(36)		'$.client.data.id'
							,_clientId	nvarchar(36)		'$._client.data.id'
							,eventId	nvarchar(36)		'$.event.data.id'
							,interactionId	nvarchar(36)	'$.interaction.data.id'
						)relationships
					)
				select
					t_data.recordId
					,t_data.clientId
					,eventName = t_event.name
					,t_client.inn
					,t_data.publishTime
				into #result
				from cte		t_data
				outer apply 
				(
					select *  
					from OPENJSON (t_data.included, '$')with
						(
							 id		nvarchar(36)	'$.id'
							,type	nvarchar(255)	'$.type'
							,inn	nvarchar(36)	'$.attributes.inn'
			
							)t
						where t.id = t_data.clientId
						and type in('clients', '_clients')
					) t_client
					outer apply 
					(
						select *  
						from OPENJSON (t_data.included, '$')with
							(
								Id		nvarchar(36)	'$.id'
								,type	nvarchar(255)	'$.type'
								,Name	nvarchar(255)	'$.attributes.name'
								,Code	smallint		'$.attributes.Code'
							)t
						where t.id = t_data.eventId
						and type = 'events'
					) t_event

				IF exists(select top(1) 1 from #result)
				BEGIN
					INSERT #t_Клиент_ИНН
					(
						GuidКлиент,
						СсылкаКлиент,
						ИНН,
						ДатаПолученияИНН,
						ТаблицаИсточник,
						created_at,
						updated_at,
						spFillName,
						ВерсияДанных
					)
					SELECT 
						A.GuidКлиент,
						A.СсылкаКлиент,
						A.ИНН,
						A.ДатаПолученияИНН,
						A.ТаблицаИсточник,
						A.created_at,
						A.updated_at,
						A.spFillName,
						A.ВерсияДанных
					FROM (
						SELECT DISTINCT
							GuidКлиент = D.clientId, --cast([dbo].[getGUIDFrom1C_IDRREF](Партнеры.Ссылка) as uniqueidentifier),
							СсылкаКлиент = dbo.get1CIDRREF_FromGUID(D.clientId),
							ИНН = cast(replace(D.inn,' ','') AS varchar(12)),
							ДатаПолученияИНН = try_cast(dateadd(SECOND, D.publishTime, cast('1970-01-01' AS datetime)) AS date),
							ТаблицаИсточник = cast('RMQ.ReceivedMessages_interactions_inn' AS varchar(100)), --Таблица / Система источник получения информации
							created_at = CURRENT_TIMESTAMP,
							updated_at = CURRENT_TIMESTAMP,
							spFillName = @spName,
							ВерсияДанных = cast(NULL AS binary(8)),
							rn = row_number() OVER(PARTITION BY D.clientId ORDER BY getdate())
						FROM #result AS D
						WHERE 1=1
							AND try_convert(uniqueidentifier, D.clientId) IS NOT NULL
							AND dm.Check_INN_Fiz(replace(D.inn,' ','')) = 0
					) AS A
					WHERE A.rn = 1


					BEGIN TRAN

						--1. ИНН реальных Клиентов (есть в Stg._1cCRM.Справочник_Партнеры)
						merge sat.Клиент_ИНН t
						--using #t_Клиент_ИНН s
						using (
							SELECT 
								I.GuidКлиент,
								I.СсылкаКлиент,
								I.ИНН,
								I.ДатаПолученияИНН,
								I.ТаблицаИсточник,
								I.created_at,
								I.updated_at,
								I.spFillName,
								I.ВерсияДанных
							FROM #t_Клиент_ИНН AS I
								INNER JOIN Stg._1cCRM.Справочник_Партнеры AS P
									ON I.СсылкаКлиент = P.Ссылка
							) AS s
							on t.GuidКлиент = s.GuidКлиент
							AND t.ТаблицаИсточник = s.ТаблицаИсточник
						when not matched then insert
						(
							GuidКлиент,
							СсылкаКлиент,
							ИНН,
							ДатаПолученияИНН,
							ТаблицаИсточник,
							created_at,
							updated_at,
							spFillName,
							ВерсияДанных
						) values
						(
							s.GuidКлиент,
							s.СсылкаКлиент,
							s.ИНН,
							s.ДатаПолученияИНН,
							s.ТаблицаИсточник,
							s.created_at,
							s.updated_at,
							s.spFillName,
							s.ВерсияДанных
						)
						when matched --and t.ВерсияДанных <> s.ВерсияДанных
						then update SET
							t.ИНН = s.ИНН,
							t.ДатаПолученияИНН = s.ДатаПолученияИНН,
							--t.ТаблицаИсточник = s.ТаблицаИсточник,
							t.updated_at = s.updated_at,
							t.spFillName = s.spFillName,
							t.ВерсияДанных = s.ВерсияДанных
							;

						--2. ИНН для blacklist (есть в dwh2.dm.реестр_blacklists_для_запроса_ИНН)
						UPDATE B
						SET ИНН = I.ИНН,
							ДатаПолученияИНН = I.ДатаПолученияИНН,
							ТаблицаИсточник = I.ТаблицаИсточник
						FROM #t_Клиент_ИНН AS I
							INNER JOIN dwh2.dm.реестр_blacklists_для_запроса_ИНН AS B
								ON I.GuidКлиент = B.row_id
							--отмечаем только успешные записи к удалению
						update rm
						set rm.isDeleted = 1
						from #result t
						inner join stg.rmq.ReceivedMessages_interactions_inn rm on rm.guid_id = t.recordId
					COMMIT TRAN
				END --//IF exists(select top(1) 1 from #result)
			END --//exists(select top(1) 1 from #t_data_RMQ)

		END --// @INN_json_array IS NULL

	END
	--//end IF @source IN ('RMQ.ReceivedMessages_interactions_inn', 'ALL')



	--------------------------------------------------------------------------------------------
	-- 4 from '_collection_pr.CustomerPersonalData'
	--------------------------------------------------------------------------------------------
	IF @source IN ('_collection_pr.CustomerPersonalData', 'ALL')
	BEGIN
		if OBJECT_ID ('sat.Клиент_ИНН') is not null
			AND @mode = 1
		BEGIN
			SELECT @updated_at = isnull((select max(updated_at) from sat.Клиент_ИНН WHERE ТаблицаИсточник = '_collection_pr.CustomerPersonalData'), '1900-01-01')
		end

		set @rowVersion = 0x0
		TRUNCATE TABLE #t_Клиент_ИНН

		INSERT #t_Клиент_ИНН
		(
			GuidКлиент,
			СсылкаКлиент,
			ИНН,
			ДатаПолученияИНН,
			ТаблицаИсточник,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		)
		SELECT 
			A.GuidКлиент,
			A.СсылкаКлиент,
			A.ИНН,
			A.ДатаПолученияИНН,
			A.ТаблицаИсточник,
			A.created_at,
			A.updated_at,
			A.spFillName,
			A.ВерсияДанных
		FROM (
			SELECT DISTINCT
				GuidКлиент = D.CrmCustomerId,
				СсылкаКлиент = dbo.get1CIDRREF_FromGUID(D.CrmCustomerId),
				ИНН = cast(replace(D.inn,' ','') AS varchar(12)),
				ДатаПолученияИНН = cast(NULL AS date),
				ТаблицаИсточник = cast('_collection_pr.CustomerPersonalData' AS varchar(100)), --Таблица / Система источник получения информации
				created_at = D.UpdateDate, --CURRENT_TIMESTAMP,
				updated_at = D.UpdateDate, --CURRENT_TIMESTAMP,
				spFillName = @spName,
				ВерсияДанных = cast(NULL AS binary(8)),
				rn = row_number() OVER(PARTITION BY D.CrmCustomerId ORDER BY getdate())
			FROM (
				select 
					t.CrmCustomerId,
					t.inn,
					t.UpdateDate
				FROM (
					SELECT 
						CrmCustomerId, 
						inn = COALESCE (
							 nullif(InnCollectionExternal,'')
							,nullif(InnCollection,'')
							,nullif(Inn,'')),
						crd.UpdateDate
					from Stg._collection_pr.Customers AS c
						INNER join Stg._collection_pr.CustomerPersonalData AS crd
							ON c.ID = crd.IdCustomer
					WHERE crd.UpdateDate >= @updated_at
				) t --where t.cnt>1
			WHERE 1=1
				AND try_convert(uniqueidentifier, t.CrmCustomerId) IS NOT NULL
				AND dm.Check_INN_Fiz(replace(t.inn,' ','')) = 0
			) AS D
		) AS A
		WHERE A.rn = 1


		merge sat.Клиент_ИНН t
		using #t_Клиент_ИНН s
			on t.GuidКлиент = s.GuidКлиент
			AND t.ТаблицаИсточник = s.ТаблицаИсточник
		when not matched then insert
		(
			GuidКлиент,
			СсылкаКлиент,
			ИНН,
			ДатаПолученияИНН,
			ТаблицаИсточник,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		) values
		(
			s.GuidКлиент,
			s.СсылкаКлиент,
			s.ИНН,
			s.ДатаПолученияИНН,
			s.ТаблицаИсточник,
			s.created_at,
			s.updated_at,
			s.spFillName,
			s.ВерсияДанных
		)
		when matched --and t.ВерсияДанных <> s.ВерсияДанных
		then update SET
			t.ИНН = s.ИНН,
			t.ДатаПолученияИНН = s.ДатаПолученияИНН,
			--t.ТаблицаИсточник = s.ТаблицаИсточник,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName,
			t.ВерсияДанных = s.ВерсияДанных
			;
	END	
	--//end IF @source IN ('_collection_pr.CustomerPersonalData', 'ALL')

	IF @source IN ('_loginom.application', 'ALL')
	BEGIN
		set @rowVersion =  0x00
		if OBJECT_ID ('sat.Клиент_ИНН') is not null
			AND @mode = 1
		BEGIN
			set @rowVersion = isnull((select max(ВерсияДанных) from sat.Клиент_ИНН WHERE ТаблицаИсточник = '_loginom.application'), 0x0)
		end
		TRUNCATE TABLE #t_Клиент_ИНН

		INSERT #t_Клиент_ИНН
		(
			GuidКлиент,
			СсылкаКлиент,
			ИНН,
			ДатаПолученияИНН,
			ТаблицаИсточник,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных,
			sourceService
		)
		select
			 GuidКлиент
			 ,СсылкаКлиент
			 ,ИНН
			 ,ДатаПолученияИНН
			 ,ТаблицаИсточник	= '_loginom.application'
			 ,created_at		= CURRENT_TIMESTAMP
			 ,updated_at		= CURRENT_TIMESTAMP
			 ,spFillName		= @spName
			 ,ВерсияДанных
			 ,sourceService
		from (
			SELECT 
				 GuidКлиент			= cast([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Партнер) as uniqueidentifier),
				 СсылкаКлиент		= ЗаявкаНаЗаймПодПТС.Партнер,
				 ИНН				= InnFromService,
				 ДатаПолученияИНН	= request_date,
				 ВерсияДанных		= rowver,
				 sourceService		= sourceService,
				 nRow				= Row_Number() over (partition by  ЗаявкаНаЗаймПодПТС.Партнер order by request_date desc)
			FROM (
				select distinct
					RequestGuid = GUID
					,InnFromService
					,sourceService = ISNULL(innSource, 'xneo')
					,rowver
					,request_date
					,nRow = ROW_NUMBER() over(partition by GUID order by row_id desc)
				from stg._loginom.application   a
				where dm.Check_INN_Fiz(replace(a.InnFromService,' ','')) = 0
					and a.rowver>=@rowVersion
				) t_application
				INNER JOIN Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС 
						ON 1=1
				AND ЗаявкаНаЗаймПодПТС.Ссылка = dbo.get1CIDRREF_FromGUID(t_application.RequestGuid)
				AND ЗаявкаНаЗаймПодПТС.Партнер <> 0x0
			where t_application.nRow = 1
			) t
			where t.nRow =1

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_Клиент_ИНН
			SELECT * INTO ##t_Клиент_ИНН FROM #t_Клиент_ИНН
		END

		merge sat.Клиент_ИНН t
		using #t_Клиент_ИНН s
			on t.GuidКлиент = s.GuidКлиент
			AND t.ТаблицаИсточник = s.ТаблицаИсточник
		when not matched then insert
		(
			GuidКлиент,
			СсылкаКлиент,
			ИНН,
			ДатаПолученияИНН,
			ТаблицаИсточник,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных,
			sourceService
		) values
		(
			s.GuidКлиент,
			s.СсылкаКлиент,
			s.ИНН,
			s.ДатаПолученияИНН,
			s.ТаблицаИсточник,
			s.created_at,
			s.updated_at,
			s.spFillName,
			s.ВерсияДанных,
			s.sourceService
		)
		when matched and t.ВерсияДанных <> s.ВерсияДанных
		then update SET
			t.ИНН = s.ИНН,
			t.ДатаПолученияИНН = s.ДатаПолученияИНН,
			--t.ТаблицаИсточник = s.ТаблицаИсточник,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName,
			t.ВерсияДанных = s.ВерсияДанных,
			t.sourceService = s.sourceService
			;
	END	
	--//end IF @source IN ('_collection_pr.CustomerPersonalData', 'ALL')


END try
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
