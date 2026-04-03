-- =======================================================
-- Create: 14.03.2023. А.Никитин
-- Description:	DWH-1987 Оптимизация процедуры dbo.Подготовка отчета стоимость CPA опер
-- актуализация витрины dbo.dm_lcrm_leads_for_report
-- =======================================================
CREATE PROC [dbo].[create_dm_lcrm_leads_for_report]
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@mode int = 1, -- 0 - full, 1 - increment
	@dt_begin_in date = NULL,
	@isDebug int = 0
AS 
BEGIN
  -- set @mode=0
	SET NOCOUNT ON 
	SET XACT_ABORT ON

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)     

	DECLARE @calendar TABLE(
		dt_from date,
		dt_to date
	)
	DECLARE @dt_begin date, @dt_from date, @dt_to date, @dt_old date
	DECLARE @Return_Table_Name varchar(100)
	DECLARE @Return_Number int, @Return_Message varchar(1000)
	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024), @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)
	DECLARE @InsertRows int = 0, @DeleteRows int = 0
	DECLARE @max_UF_UPDATED_AT datetime2
	DECLARE @ID_Table_Name varchar(100) -- название таблицы со списком ID

	SELECT @eventName = 'Analytics.dbo.create_dm_lcrm_leads_for_report', @eventType = 'info', @SendEmail = 0
	SELECT @dt_old = cast(dateadd(DAY, -90, getdate()) AS date)

	--название таблицы, которая будет заполнена
	SELECT @Return_Table_Name = '#t_leads'

	DROP TABLE IF EXISTS #t_leads
	CREATE TABLE #t_leads
	(
		[ID] numeric(10,0),
		[UF_REGISTERED_AT] [datetime2] NULL,
		[UF_REGISTERED_AT_date] [date] NULL,
		[UF_UPDATED_AT] [datetime2] NULL,
		[UF_UPDATED_AT_date] [date] NULL,

		[UF_ACTUALIZE_AT] [datetime2] NULL,
		[UF_SOURCE] [VARCHAR](128),
		[UF_ROW_ID] [VARCHAR](128),
		UF_CLB_TYPE [VARCHAR](128),
		UF_PARTNER_ID [VARCHAR](256),

		[UF_LOGINOM_DECLINE] [VARCHAR](128),
		UF_STEP int,
		[UF_FULL_FORM_LEAD] int,
		[UF_REGIONS_COMPOSITE] [nvarchar] (128) NULL,
		[UF_TYPE] [VARCHAR](128),

		[UF_TARGET] [int] NULL,
		[Канал от источника] [NVARCHAR](255),
		[Группа каналов] [NVARCHAR](255),
		[UF_APPMECA_TRACKER] [varchar](128) NULL,
		[UF_LOGINOM_STATUS] [VARCHAR](128),
		
		phonenumber [VARCHAR](20),

		[UF_STAT_CAMPAIGN] [varchar](512) NULL,
		[UF_STAT_AD_TYPE] [varchar](128) NULL,
		[UF_RC_REJECT_CM] [varchar](512) NULL,
		[UF_LOGINOM_PRIORITY] [int] NULL,
		[UF_STAT_SOURCE] [varchar](128) NULL ,
		[UF_CLID] [VARCHAR](128)

	)


	BEGIN TRY

		IF @mode = 0 -- full
		BEGIN
			SELECT @dt_begin = cast(dateadd(DAY, -90, getdate()) AS date)
		END

		IF @mode = 1 -- increment
		BEGIN
			SELECT @dt_begin = max(D.UF_REGISTERED_AT_date)
			FROM dbo.dm_lcrm_leads_for_report AS D

			IF isnull(@dt_begin, '2000-01-01') < cast(dateadd(DAY, -90, getdate()) AS date)
			BEGIN
				SELECT @dt_begin = cast(dateadd(DAY, -90, getdate()) AS date)
			END

			IF @dt_begin > cast(dateadd(DAY, -1, getdate()) AS date)
			BEGIN
				SELECT @dt_begin = cast(dateadd(DAY, -1, getdate()) AS date)
			END

			SELECT @max_UF_UPDATED_AT = max(D.UF_UPDATED_AT)
			FROM dbo.dm_lcrm_leads_for_report AS D
		END


		/*
		-- по месяцам
		;WITH СL AS (
			SELECT 
				dt_from = @dt_begin,
				dt_to = eomonth(@dt_begin)

			UNION ALL

			SELECT 
				dt_from = dateadd(DAY, 1, dt_to),
				dt_to = iif(
					eomonth(dateadd(DAY, 1, dt_to)) < cast(dateadd(DAY, -1, getdate()) AS date),
					eomonth(dateadd(DAY, 1, dt_to)),
					cast(dateadd(DAY, -1, getdate()) AS date)
					)
			FROM СL
			WHERE dt_to < cast(dateadd(DAY, -1, getdate()) AS date)
		)
		INSERT @calendar(dt_from, dt_to)
		SELECT dt_from, dt_to
		FROM СL
		OPTION(MAXRECURSION 0)
		*/

		IF @dt_begin_in IS NOT NULL BEGIN
			SELECT @dt_begin = @dt_begin_in
		END

		-- по дням
		;WITH СL AS (
			SELECT 
				dt_from = @dt_begin,
				dt_to = @dt_begin

			UNION ALL

			SELECT 
				dt_from = dateadd(DAY, 1, dt_to),
				dt_to = dateadd(DAY, 1, dt_to)
			FROM СL
			WHERE dt_to < cast(dateadd(DAY, -1, getdate()) AS date)
		)
		INSERT @calendar(dt_from, dt_to)
		SELECT dt_from, dt_to
		FROM СL
		OPTION(MAXRECURSION 0)

		--test
		--DELETE @calendar
		--INSERT @calendar(dt_from, dt_to)
		--SELECT @dt_old, @dt_old


		IF @isDebug = 1 BEGIN
			SELECT C.dt_from, C.dt_to
			FROM @calendar AS C
			ORDER BY C.dt_from
			--test
			--RETURN 0
		END

		DECLARE cur_calendar CURSOR FOR
		SELECT C.dt_from, C.dt_to
		FROM @calendar AS C
		ORDER BY C.dt_from

		OPEN cur_calendar

		FETCH NEXT FROM cur_calendar INTO @dt_from, @dt_to

		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			TRUNCATE TABLE #t_leads

			SELECT @InsertRows = 0, @DeleteRows = 0, @Return_Number = NULL, @Return_Message = NULL

			EXEC Stg._LCRM.get_leads
				@Debug = @isDebug, -- 0 - штатное выполнение, 1 - отладочный режим
				@Begin_Registered = @dt_from, -- начальная дата
				@End_Registered = @dt_to, -- конечная дата
				@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
				@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
				@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение

			IF @Return_Number = 0 BEGIN

				--дедупликация
				;with v 
				AS (
					SELECT 
						F.*,
						row_number() over(
							PARTITION by F.ID 
							ORDER BY F.UF_UPDATED_AT desc
						) AS rn 
					FROM #t_leads AS F
				)
				DELETE 
				FROM v 
				WHERE rn > 1

				BEGIN TRAN
			
				DELETE D
				FROM dbo.dm_lcrm_leads_for_report AS D
				WHERE D.UF_REGISTERED_AT_date BETWEEN @dt_from AND @dt_to

				SELECT @DeleteRows = @@ROWCOUNT

				INSERT dbo.dm_lcrm_leads_for_report
				(
					ID,
					UF_REGISTERED_AT,
					UF_REGISTERED_AT_date,
					UF_UPDATED_AT,
					UF_UPDATED_AT_date,
					UF_ACTUALIZE_AT,
					UF_SOURCE,
					UF_ROW_ID,
					UF_CLB_TYPE,
					UF_PARTNER_ID,
					UF_LOGINOM_DECLINE,
					UF_STEP,
					UF_FULL_FORM_LEAD,
					UF_REGIONS_COMPOSITE,
					UF_TYPE,
					UF_TARGET,
					[Канал от источника],
					[Группа каналов],
					UF_APPMECA_TRACKER,
					UF_LOGINOM_STATUS,
					phonenumber,
					UF_STAT_CAMPAIGN,
					UF_STAT_AD_TYPE,
					UF_RC_REJECT_CM,
					UF_LOGINOM_PRIORITY,
					UF_STAT_SOURCE	   ,
					[UF_CLID]
				)
				SELECT DISTINCT
					T.ID,
					T.UF_REGISTERED_AT,
					T.UF_REGISTERED_AT_date,
					T.UF_UPDATED_AT,
					T.UF_UPDATED_AT_date,
					T.UF_ACTUALIZE_AT,
					T.UF_SOURCE,
					T.UF_ROW_ID,
					T.UF_CLB_TYPE,
					T.UF_PARTNER_ID,
					T.UF_LOGINOM_DECLINE,
					T.UF_STEP,
					T.UF_FULL_FORM_LEAD,
					T.UF_REGIONS_COMPOSITE,
					T.UF_TYPE,
					T.UF_TARGET,
					T.[Канал от источника],
					T.[Группа каналов],
					T.UF_APPMECA_TRACKER,
					T.UF_LOGINOM_STATUS ,
					T.phonenumber,
					T.UF_STAT_CAMPAIGN,
					T.UF_STAT_AD_TYPE,
					T.UF_RC_REJECT_CM,
					T.UF_LOGINOM_PRIORITY,
					T.UF_STAT_SOURCE   ,
					T.[UF_CLID]
				FROM #t_leads AS T

				SELECT @InsertRows = @@ROWCOUNT

				COMMIT
			END


			SELECT @message = concat(
					'Добавление и обновление.',
					', @dt_from: ', format(@dt_from, 'yyyy-MM-dd'),
					', @dt_to: ', format(@dt_to, 'yyyy-MM-dd'),
					', @Return_Number = ', convert(varchar(10), @Return_Number),
					', @Return_Message: ', isnull(@Return_Message, ''),
					', @DeleteRows = ', convert(varchar(10), @DeleteRows),
					', @InsertRows = ', convert(varchar(10), @InsertRows)
				)

			IF @isDebug = 1 BEGIN
				SELECT @message
			END

			EXEC LogDb.dbo.LogAndSendMailToAdmin 
				@eventName = @eventName, 
				@eventType = @eventType, 
				@message = @message, 
				@SendEmail = @SendEmail, 
				@ProcessGUID = @ProcessGUID

			FETCH NEXT FROM cur_calendar INTO @dt_from, @dt_to
		END
		CLOSE cur_calendar
		DEALLOCATE cur_calendar

		--Добавление записей со старым UF_REGISTERED_AT, но с новым UF_UPDATED_AT
		DROP TABLE IF EXISTS #t_ID_UF_UPDATED_AT
		CREATE TABLE #t_ID_UF_UPDATED_AT(
			ID numeric(10, 0),
			UF_UPDATED_AT datetime2
		)
		
		DROP TABLE IF EXISTS #t_LEAD_ID
		CREATE TABLE #t_LEAD_ID(
			ID numeric(10, 0)
		)

		IF @mode = 1 BEGIN
			INSERT #t_ID_UF_UPDATED_AT(ID, UF_UPDATED_AT)
			SELECT C.ID, C.UF_UPDATED_AT
			FROM Stg._LCRM.lcrm_leads_full_calculated AS C (NOLOCK)
			WHERE 1=1
				AND C.UF_UPDATED_AT >= @max_UF_UPDATED_AT
				AND C.UF_REGISTERED_AT BETWEEN 
					@dt_old AND cast(cast(getdate() AS date) AS datetime2)

			CREATE UNIQUE INDEX clix1
			ON #t_ID_UF_UPDATED_AT(ID)

			DELETE T
			FROM #t_ID_UF_UPDATED_AT AS T
				INNER JOIN dbo.dm_lcrm_leads_for_report AS D
					ON D.ID = T.ID
					AND D.UF_UPDATED_AT >= T.UF_UPDATED_AT

			IF EXISTS(SELECT TOP(1) 1 FROM #t_ID_UF_UPDATED_AT)
			BEGIN
				INSERT #t_LEAD_ID(ID)
			    SELECT T.ID FROM #t_ID_UF_UPDATED_AT AS T

				SELECT @ID_Table_Name = '#t_LEAD_ID'

				TRUNCATE TABLE #t_leads

				SELECT @Return_Number = NULL, @Return_Message = NULL

				EXEC Stg._LCRM.get_leads
					@Debug = @isDebug, -- 0 - штатное выполнение, 1 - отладочный режим
					@ID_Table_Name = @ID_Table_Name, -- название таблицы со списком ID
					@Return_Table_Name = @Return_Table_Name, -- название таблицы для возвращения записей
					@Return_Number = @Return_Number OUTPUT, -- возвращаемый код, 0 - без ошибок
					@Return_Message = @Return_Message OUTPUT -- возвращаемое сообщение

				CREATE UNIQUE INDEX ix_ID
				ON #t_leads(ID)

				BEGIN TRAN
			
				DELETE D
				FROM dbo.dm_lcrm_leads_for_report AS D
				WHERE EXISTS(
						SELECT TOP(1) 1
						FROM #t_leads AS T
						WHERE T.ID = D.ID
					)

				SELECT @DeleteRows = @@ROWCOUNT

				INSERT dbo.dm_lcrm_leads_for_report
				(
					ID,
					UF_REGISTERED_AT,
					UF_REGISTERED_AT_date,
					UF_UPDATED_AT,
					UF_UPDATED_AT_date,
					UF_ACTUALIZE_AT,
					UF_SOURCE,
					UF_ROW_ID,
					UF_CLB_TYPE,
					UF_PARTNER_ID,
					UF_LOGINOM_DECLINE,
					UF_STEP,
					UF_FULL_FORM_LEAD,
					UF_REGIONS_COMPOSITE,
					UF_TYPE,
					UF_TARGET,
					[Канал от источника],
					[Группа каналов],
					UF_APPMECA_TRACKER,
					UF_LOGINOM_STATUS,
					phonenumber,
					UF_STAT_CAMPAIGN,
					UF_STAT_AD_TYPE,
					UF_RC_REJECT_CM,
					UF_LOGINOM_PRIORITY,
					UF_STAT_SOURCE	   ,
					[UF_CLID]
				)
				SELECT DISTINCT
					T.ID,
					T.UF_REGISTERED_AT,
					T.UF_REGISTERED_AT_date,
					T.UF_UPDATED_AT,
					T.UF_UPDATED_AT_date,
					T.UF_ACTUALIZE_AT,
					T.UF_SOURCE,
					T.UF_ROW_ID,
					T.UF_CLB_TYPE,
					T.UF_PARTNER_ID,
					T.UF_LOGINOM_DECLINE,
					T.UF_STEP,
					T.UF_FULL_FORM_LEAD,
					T.UF_REGIONS_COMPOSITE,
					T.UF_TYPE,
					T.UF_TARGET,
					T.[Канал от источника],
					T.[Группа каналов],
					T.UF_APPMECA_TRACKER,
					T.UF_LOGINOM_STATUS ,
					T.phonenumber,
					T.UF_STAT_CAMPAIGN,
					T.UF_STAT_AD_TYPE,
					T.UF_RC_REJECT_CM,
					T.UF_LOGINOM_PRIORITY,
					T.UF_STAT_SOURCE	 ,
					T.[UF_CLID]
				FROM #t_leads AS T

				SELECT @InsertRows = @@ROWCOUNT

				COMMIT

				SELECT @message = concat(
						'Добавление записей со старым UF_REGISTERED_AT.',
						', @Return_Number = ', convert(varchar(10), @Return_Number),
						', @Return_Message: ', isnull(@Return_Message, ''),
						', @DeleteRows = ', convert(varchar(10), @DeleteRows),
						', @InsertRows = ', convert(varchar(10), @InsertRows)
					)

				IF @isDebug = 1 BEGIN
					SELECT @message
				END

				EXEC LogDb.dbo.LogAndSendMailToAdmin 
					@eventName = @eventName, 
					@eventType = @eventType, 
					@message = @message, 
					@SendEmail = @SendEmail, 
					@ProcessGUID = @ProcessGUID
			END
		END
		--// Добавление записей со старым UF_REGISTERED_AT, но с новым UF_UPDATED_AT






		--Удаление старых записей
		SELECT @DeleteRows = NULL

		DELETE D
		FROM dbo.dm_lcrm_leads_for_report AS D
		WHERE D.UF_REGISTERED_AT_date < @dt_old

		SELECT @DeleteRows = @@ROWCOUNT

		SELECT @message = concat(
				'Удаление старых записей до ', format(@dt_old, 'yyyy-MM-dd'),
				', @DeleteRows = ', convert(varchar(10), @DeleteRows)
			)

		IF @isDebug = 1 BEGIN
			SELECT @message
		END

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = @eventName, 
			@eventType = @eventType, 
			@message = @message, 
			@SendEmail = @SendEmail, 
			@ProcessGUID = @ProcessGUID

	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @message = 'Ошибка заполнения Analytics.dbo.dm_lcrm_leads_for_report'

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = @eventName,
			@eventType = 'Error',
			@message = @message,
			@description = @error_description,
			@SendEmail = @SendEmail,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH


	--alter table config add   [oper_leads_table_created_at]	  datetime2
	update config set 				 [oper_leads_table_created_at] = getdate() 
    exec msdb.dbo.sp_start_job N'Analytics._monitoring Поступление лидов от источников'


	--select * from [v_Запущенные джобы]
	
	--alter table Analytics.dbo.dm_lcrm_leads_for_report add uf_clid 	  [VARCHAR](128) 


END