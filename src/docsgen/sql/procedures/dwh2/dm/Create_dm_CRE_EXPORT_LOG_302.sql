-- =======================================================
-- Create: 4.06.2025. А.Никитин
-- Description:	
-- =======================================================
create   PROC dm.Create_dm_CRE_EXPORT_LOG_302
	@mode int = 1, -- 1-increment, 0-full
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isDebug int = 0
as
begin
	SET NOCOUNT ON 
	SET XACT_ABORT ON

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)     

	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024) --, @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)

	DECLARE @DurationSec int, @StartDate datetime = getdate()
	DECLARE @DeleteRows int, @InsertRows int

	SELECT @eventName = 'dwh2.dm.Create_dm_CRE_EXPORT_LOG_302', @eventType = 'info', @SendEmail = 0

	BEGIN TRY
		if OBJECT_ID('dm.CRE_EXPORT_LOG_302') is null
		BEGIN
		    SELECT TOP(0) *
			INTO dm.CRE_EXPORT_LOG_302
			FROM dm.v_CRE_EXPORT_LOG_302

			alter table dm.CRE_EXPORT_LOG_302
				alter column GuidCRE_EXPORT_LOG_302 uniqueidentifier not null

			ALTER TABLE dm.CRE_EXPORT_LOG_302
				ADD CONSTRAINT PK_dm_CRE_EXPORT_LOG_302 PRIMARY KEY CLUSTERED (GuidCRE_EXPORT_LOG_302)

			create index ix_INSERT_DATE
			on dm.CRE_EXPORT_LOG_302(INSERT_DATE)
			include (КодСобытия)

			create index ix_ДатаСобытия_dt
			on dm.CRE_EXPORT_LOG_302(ДатаСобытия_dt)
			include (КодСобытия)

			--CREATE NONCLUSTERED INDEX ix_НомерЗаявки 
			--	ON dm.CRE_EXPORT_LOG_302(НомерЗаявки, GuidЗаявки)
		END

		DROP TABLE IF EXISTS #t_change

		SELECT C.id, C.GuidCRE_EXPORT_LOG_302
		INTO #t_change
		FROM link.CRE_EXPORT_LOG_302_change AS C

		create index ix1 on #t_change(id)
		create index ix2 on #t_change(GuidCRE_EXPORT_LOG_302)


		DROP TABLE IF EXISTS #t_CRE_EXPORT_LOG_302

		SELECT TOP(0) *
		INTO #t_CRE_EXPORT_LOG_302
		FROM dm.v_CRE_EXPORT_LOG_302

		IF @mode = 0
		BEGIN
			INSERT #t_CRE_EXPORT_LOG_302
			SELECT R.* 
			FROM dm.v_CRE_EXPORT_LOG_302 AS R
		END

		IF @mode = 1
		BEGIN
			INSERT #t_CRE_EXPORT_LOG_302
			SELECT distinct R.* 
			FROM dm.v_CRE_EXPORT_LOG_302 AS R
				INNER JOIN (
						SELECT DISTINCT T.GuidCRE_EXPORT_LOG_302 FROM #t_change AS T
					) AS C
					ON R.GuidCRE_EXPORT_LOG_302 = C.GuidCRE_EXPORT_LOG_302
		END

		IF @isDebug = 1 BEGIN
			drop table if exists ##t_CRE_EXPORT_LOG_302
			select * into ##t_CRE_EXPORT_LOG_302 from #t_CRE_EXPORT_LOG_302
		END

		BEGIN TRAN
			DELETE R 
			FROM dm.CRE_EXPORT_LOG_302 AS R
				INNER JOIN #t_CRE_EXPORT_LOG_302 AS T
					ON T.GuidCRE_EXPORT_LOG_302 = R.GuidCRE_EXPORT_LOG_302

			SELECT @DeleteRows = @@ROWCOUNT

			INSERT dm.CRE_EXPORT_LOG_302
			(
				dm_created_at,
				GuidCRE_EXPORT_LOG_302,
				--ИсторияСобытий
				GuidБКИ_НФ_ИсторияСобытий,
				ДатаСобытия,
				ДатаСобытия_dt,
				isActiveСобытия,
				ДатаЗаписиСобытия,
				--CRE_IMPORT_LOG_302
				GuidCRE_IMPORT_LOG_302,
				IMPORT_LOG_ID,
				IMPORT_SUCCESS,
				IMPORT_ERROR_CODE,
				IMPORT_ERROR_DESC,
				--Объект
				ТипОбъекта,
				НомерОбъекта,
				СсылкаОбъекта,
				GuidОбъекта,
				--Событие
				КодСобытия,
				НаименованиеСобытия,
				isDeleteСобытия,
				--CRE_EXPORT_LOG_302
				ID,
				BKI_NAME,
				INSERT_DATE,
				EVENT_ID,
				EVENT_DATE,
				OPERATION_TYPE,
				SOURCE_CODE,
				REF_CODE,
				UUID,
				APPLICATION_NUMBER,
				APPLICANT_CODE,
				ORDER_NUM,
				EXPORT_FILENAME,
				IMPORT_FILENAME,
				EXPORT_EVENT_SUCCESS,
				ERROR_CODE,
				ERROR_DESC,
				CHANGE_CODE,
				SPECIAL_CHANGE_CODE,
				ACCOUNT,
				JOURNAL_ID,
				TRADE_ID,
				TRADEDETAIL_ID,
				IMPORT_ID,
				EXPORT_META_ID,
				created_at,
				updated_at,
				--REJECT
				REJECT_ERROR_DESC,
				--TICKET
				GuidCRE_TICKET_LOG_302,
				TICKET_DATE
			)
			SELECT distinct 
				dm_created_at,
				GuidCRE_EXPORT_LOG_302,
				--ИсторияСобытий
				GuidБКИ_НФ_ИсторияСобытий,
				ДатаСобытия,
				ДатаСобытия_dt,
				isActiveСобытия,
				ДатаЗаписиСобытия,
				--CRE_IMPORT_LOG_302
				GuidCRE_IMPORT_LOG_302,
				IMPORT_LOG_ID,
				IMPORT_SUCCESS,
				IMPORT_ERROR_CODE,
				IMPORT_ERROR_DESC,
				--Объект
				ТипОбъекта,
				НомерОбъекта,
				СсылкаОбъекта,
				GuidОбъекта,
				--Событие
				КодСобытия,
				НаименованиеСобытия,
				isDeleteСобытия,
				--CRE_EXPORT_LOG_302
				ID,
				BKI_NAME,
				INSERT_DATE,
				EVENT_ID,
				EVENT_DATE,
				OPERATION_TYPE,
				SOURCE_CODE,
				REF_CODE,
				UUID,
				APPLICATION_NUMBER,
				APPLICANT_CODE,
				ORDER_NUM,
				EXPORT_FILENAME,
				IMPORT_FILENAME,
				EXPORT_EVENT_SUCCESS,
				ERROR_CODE,
				ERROR_DESC,
				CHANGE_CODE,
				SPECIAL_CHANGE_CODE,
				ACCOUNT,
				JOURNAL_ID,
				TRADE_ID,
				TRADEDETAIL_ID,
				IMPORT_ID,
				EXPORT_META_ID,
				created_at,
				updated_at,
				--REJECT
				REJECT_ERROR_DESC,
				--TICKET
				GuidCRE_TICKET_LOG_302,
				TICKET_DATE
			FROM #t_CRE_EXPORT_LOG_302 AS T

			SELECT @InsertRows = @@ROWCOUNT

			DELETE C
			FROM link.CRE_EXPORT_LOG_302_change AS C
				INNER JOIN #t_change AS T
					ON T.id = C.id
		COMMIT

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @message = 
			concat(
				'Заполнение dwh2.dm.CRE_EXPORT_LOG_302. ',
				'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
				'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
				'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
			)

		IF @isDebug = 1 BEGIN
			SELECT @message
			EXEC LogDb.dbo.LogAndSendMailToAdmin 
				@eventName = @eventName, 
				@eventType = @eventType, 
				@message = @message, 
				@SendEmail = @SendEmail, 
				@ProcessGUID = @ProcessGUID
		END
	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @message = 
			concat(
				'Ошибка заполнения dwh2.dm.CRE_EXPORT_LOG_302. ',
				'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
				'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
				'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
			)

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = @eventName,
			@eventType = 'Error',
			@message = @message,
			@description = @error_description,
			@SendEmail = @SendEmail,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH
END