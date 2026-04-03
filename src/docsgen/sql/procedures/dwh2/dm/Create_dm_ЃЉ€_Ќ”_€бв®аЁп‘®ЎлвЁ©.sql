-- =======================================================
-- Create: 8.06.2025. А.Никитин
-- Description:	
-- =======================================================
CREATE PROC dm.Create_dm_БКИ_НФ_ИсторияСобытий
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

	SELECT @eventName = 'dwh2.dm.Create_dm_БКИ_НФ_ИсторияСобытий', @eventType = 'info', @SendEmail = 0

	BEGIN TRY
		if OBJECT_ID('dm.БКИ_НФ_ИсторияСобытий') is null
		BEGIN
		    SELECT TOP(0) *
			INTO dm.БКИ_НФ_ИсторияСобытий
			FROM dm.v_БКИ_НФ_ИсторияСобытий

			alter table dm.БКИ_НФ_ИсторияСобытий
				alter column GuidБКИ_НФ_ИсторияСобытий uniqueidentifier not null

			ALTER TABLE dm.БКИ_НФ_ИсторияСобытий
				ADD CONSTRAINT PK_dm_БКИ_НФ_ИсторияСобытий PRIMARY KEY CLUSTERED (GuidБКИ_НФ_ИсторияСобытий)

			create index ix_Дата_dt
			on dm.БКИ_НФ_ИсторияСобытий(Дата_dt)
			include (КодСобытия)
		END

		DROP TABLE IF EXISTS #t_change

		SELECT C.id, C.GuidБКИ_НФ_ИсторияСобытий
		INTO #t_change
		FROM link.БКИ_НФ_ИсторияСобытий_change AS C

		create index ix1 on #t_change(id)
		create index ix2 on #t_change(GuidБКИ_НФ_ИсторияСобытий)


		DROP TABLE IF EXISTS #t_БКИ_НФ_ИсторияСобытий

		SELECT TOP(0) *
		INTO #t_БКИ_НФ_ИсторияСобытий
		FROM dm.v_БКИ_НФ_ИсторияСобытий

		IF @mode = 0
		BEGIN
			INSERT #t_БКИ_НФ_ИсторияСобытий
			SELECT R.* 
			FROM dm.v_БКИ_НФ_ИсторияСобытий AS R
		END

		IF @mode = 1
		BEGIN
			INSERT #t_БКИ_НФ_ИсторияСобытий
			SELECT distinct R.* 
			FROM dm.v_БКИ_НФ_ИсторияСобытий AS R
				INNER JOIN (
						SELECT DISTINCT T.GuidБКИ_НФ_ИсторияСобытий FROM #t_change AS T
					) AS C
					ON R.GuidБКИ_НФ_ИсторияСобытий = C.GuidБКИ_НФ_ИсторияСобытий
		END

		IF @isDebug = 1 BEGIN
			drop table if exists ##t_БКИ_НФ_ИсторияСобытий
			select * into ##t_БКИ_НФ_ИсторияСобытий from #t_БКИ_НФ_ИсторияСобытий
		END

		BEGIN TRAN
			DELETE R 
			FROM dm.БКИ_НФ_ИсторияСобытий AS R
				INNER JOIN #t_БКИ_НФ_ИсторияСобытий AS T
					ON T.GuidБКИ_НФ_ИсторияСобытий = R.GuidБКИ_НФ_ИсторияСобытий

			SELECT @DeleteRows = @@ROWCOUNT

			INSERT dm.БКИ_НФ_ИсторияСобытий
			(
				dm_created_at,
				GuidБКИ_НФ_ИсторияСобытий,
				ТипОбъекта,
				НомерОбъекта,
				СсылкаОбъекта,
				GuidОбъекта,
				КодСобытия,
				НаименованиеСобытия,
				isDeleteСобытия,
				Дата,
				isActive,
				ДатаЗаписи,
				Дата_dt,
				created_at,
				updated_at,
				GuidКлиент,
				СсылкаКлиент,
				КодКлиент,
				НаименованиеКлиент
			)
			SELECT distinct 
				dm_created_at,
				GuidБКИ_НФ_ИсторияСобытий,
				ТипОбъекта,
				НомерОбъекта,
				СсылкаОбъекта,
				GuidОбъекта,
				КодСобытия,
				НаименованиеСобытия,
				isDeleteСобытия,
				Дата,
				isActive,
				ДатаЗаписи,
				Дата_dt,
				created_at,
				updated_at,
				GuidКлиент,
				СсылкаКлиент,
				КодКлиент,
				НаименованиеКлиент
			FROM #t_БКИ_НФ_ИсторияСобытий AS T

			SELECT @InsertRows = @@ROWCOUNT

			DELETE C
			FROM link.БКИ_НФ_ИсторияСобытий_change AS C
				INNER JOIN #t_change AS T
					ON T.id = C.id
		COMMIT

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @message = 
			concat(
				'Заполнение dwh2.dm.БКИ_НФ_ИсторияСобытий. ',
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
				'Ошибка заполнения dwh2.dm.БКИ_НФ_ИсторияСобытий. ',
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
