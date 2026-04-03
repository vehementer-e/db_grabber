-- =======================================================
-- Create: 25.04.2023. А.Никитин
-- Description:	
-- =======================================================
CREATE PROC [dm].[Create_dm_ЗаявкаНаЗаймПодПТС_СтатусыИСобытия]
	@mode int = 1, -- 1-increment, 0-full
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isDebug int = 0
AS 
BEGIN
	SET NOCOUNT ON 
	SET XACT_ABORT ON

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)     

	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024) --, @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)

	DECLARE @DurationSec int, @StartDate datetime = getdate()
	DECLARE @DeleteRows int, @InsertRows int

	SELECT @eventName = 'dwh2.dm.Create_dm_ЗаявкаНаЗаймПодПТС_СтатусыИСобытия', @eventType = 'info', @SendEmail = 0

	BEGIN TRY
		if OBJECT_ID('dm.ЗаявкаНаЗаймПодПТС_СтатусыИСобытия') is null
		BEGIN
		    SELECT TOP(0) 
				D.*
			INTO dm.ЗаявкаНаЗаймПодПТС_СтатусыИСобытия
			FROM dm.v_ЗаявкаНаЗаймПодПТС_СтатусыИСобытия AS D

			alter table dm.ЗаявкаНаЗаймПодПТС_СтатусыИСобытия
				alter column НомерЗаявки nvarchar(14) not null
			alter table dm.ЗаявкаНаЗаймПодПТС_СтатусыИСобытия
				alter column GuidЗаявки uniqueidentifier not null
			ALTER TABLE dm.ЗаявкаНаЗаймПодПТС_СтатусыИСобытия
				ADD CONSTRAINT PK_dm_ЗаявкаНаЗаймПодПТС_СтатусыИСобытия PRIMARY KEY CLUSTERED (НомерЗаявки, GuidЗаявки);
		END

		DROP TABLE IF EXISTS #t_change

		SELECT DISTINCT C.GuidЗаявки 
		INTO #t_change
		FROM link.ЗаявкаНаЗаймПодПТС_СтатусыИСобытия_change AS C

		DROP TABLE IF EXISTS #t_ЗаявкаНаЗаймПодПТС_СтатусыИСобытия

		SELECT TOP(0) *
		INTO #t_ЗаявкаНаЗаймПодПТС_СтатусыИСобытия
		FROM dm.v_ЗаявкаНаЗаймПодПТС_СтатусыИСобытия AS D

		IF @mode = 0
		BEGIN
			INSERT #t_ЗаявкаНаЗаймПодПТС_СтатусыИСобытия
			SELECT 
			  [created_at]
			, [СсылкаЗаявки]
			, [НомерЗаявки]
			, [GuidЗаявки]
			, [Черновик]
			, [Верификация КЦ]
			, [Предварительное одобрение]
			, [Встреча назначена]
			, [Контроль данных]
			, [Call2]
			, [Call2 accept]
			, [Верификация документов клиента]
			, [Одобрены документы клиента]
			, [Верификация документов]
			, [Одобрено]
			, [Договор зарегистрирован]
			, [Заем выдан]
			, [ЗаемВыданP2P]
			, [P2P]
			, [Заем погашен]
			, [Заем аннулирован]
			, [Аннулировано]
			, [Отказ документов клиента]
			, [Отказано]
			, [Отказ клиента]
			, [Клиент передумал]
			, [Забраковано]
			, [Договор подписан]
			, [Call0.3]
			, [Call0.3 accepted]
			, [PreCall 1]
			, [PreCall 1 accepted]
			, [Call 1]
			, [Call 1 accept]
			, [Call 1.2]
			, [Call 1.2 accept]
			, [Call 1.5]
			, [Call 1.5 accept]
			, [Call 2.1]
			, [Call 2.1 accept]
			, [Call 2.2]
			, [Call 2.2 accept]
			, [Call 3]
			, [Call 3 accept]
			, [Call 4]
			, [Call 4 accept]
			, [Call 5]
			, [Call 5 accept]
			, [Call checkTransfer]
			, [Call checkTransfer accept]
			, [Call checkTransfer_FEDOR]
			, [Call checkTransfer_FEDOR accept]
			FROM dm.v_ЗаявкаНаЗаймПодПТС_СтатусыИСобытия AS R
		END

		IF @mode = 1
		BEGIN
			INSERT #t_ЗаявкаНаЗаймПодПТС_СтатусыИСобытия
			SELECT 
			  r.[created_at]
			, r.[СсылкаЗаявки]
			, r.[НомерЗаявки]
			, r.[GuidЗаявки]
			, r.[Черновик]
			, r.[Верификация КЦ]
			, r.[Предварительное одобрение]
			, r.[Встреча назначена]
			, r.[Контроль данных]
			, r.[Call2]
			, r.[Call2 accept]
			, r.[Верификация документов клиента]
			, r.[Одобрены документы клиента]
			, r.[Верификация документов]
			, r.[Одобрено]
			, r.[Договор зарегистрирован]
			, r.[Заем выдан]
			, r.[ЗаемВыданP2P]
			, r.[P2P]
			, r.[Заем погашен]
			, r.[Заем аннулирован]
			, r.[Аннулировано]
			, r.[Отказ документов клиента]
			, r.[Отказано]
			, r.[Отказ клиента]
			, r.[Клиент передумал]
			, r.[Забраковано]
			, r.[Договор подписан]
			, r.[Call0.3]
			, r.[Call0.3 accepted]
			, r.[PreCall 1]
			, r.[PreCall 1 accepted]
			, r.[Call 1]
			, r.[Call 1 accept]
			, r.[Call 1.2]
			, r.[Call 1.2 accept]
			, r.[Call 1.5]
			, r.[Call 1.5 accept]
			, r.[Call 2.1]
			, r.[Call 2.1 accept]
			, r.[Call 2.2]
			, r.[Call 2.2 accept]
			, r.[Call 3]
			, r.[Call 3 accept]
			, r.[Call 4]
			, r.[Call 4 accept]
			, r.[Call 5]
			, r.[Call 5 accept]
			, r.[Call checkTransfer]
			, r.[Call checkTransfer accept]
			, r.[Call checkTransfer_FEDOR]
			, r.[Call checkTransfer_FEDOR accept]

			FROM dm.v_ЗаявкаНаЗаймПодПТС_СтатусыИСобытия AS R
			where exists(select top(1) 1 from #t_change AS C
					where R.GuidЗаявки = C.GuidЗаявки
					)
		END


		--update 1,2,3
		/*
		...
		
		*/




		BEGIN TRAN
			DELETE R 
			FROM dm.ЗаявкаНаЗаймПодПТС_СтатусыИСобытия AS R
				INNER JOIN #t_ЗаявкаНаЗаймПодПТС_СтатусыИСобытия AS T
					ON T.GuidЗаявки = R.GuidЗаявки

			SELECT @DeleteRows = @@ROWCOUNT

			INSERT dm.ЗаявкаНаЗаймПодПТС_СтатусыИСобытия
			(
				  [created_at]
				, [СсылкаЗаявки]
				, [НомерЗаявки]
				, [GuidЗаявки]
				, [Черновик]
				, [Верификация КЦ]
				, [Предварительное одобрение]
				, [Встреча назначена]
				, [Контроль данных]
				, [Call2]
				, [Call2 accept]
				, [Верификация документов клиента]
				, [Одобрены документы клиента]
				, [Верификация документов]
				, [Одобрено]
				, [Договор зарегистрирован]
				, [Заем выдан]
				, [ЗаемВыданP2P]
				, [P2P]
				, [Заем погашен]
				, [Заем аннулирован]
				, [Аннулировано]
				, [Отказ документов клиента]
				, [Отказано]
				, [Клиент передумал]
				, [Забраковано]
				, [Договор подписан]
				, [Отказ клиента]
				, [Call0.3]
				, [Call0.3 accepted]
				, [PreCall 1]
				, [PreCall 1 accepted]
				, [Call 1]
				, [Call 1 accept]
				, [Call 1.2]
				, [Call 1.2 accept]
				, [Call 1.5]
				, [Call 1.5 accept]
				, [Call 2.1]
				, [Call 2.1 accept]
				, [Call 2.2]
				, [Call 2.2 accept]
				, [Call 3]
				, [Call 3 accept]
				, [Call 4]
				, [Call 4 accept]
				, [Call 5]
				, [Call 5 accept]
				, [Call checkTransfer]
				, [Call checkTransfer accept]
				, [Call checkTransfer_FEDOR]
				, [Call checkTransfer_FEDOR accept]
			)
			SELECT 
			     [created_at]
				, [СсылкаЗаявки]
				, [НомерЗаявки]
				, [GuidЗаявки]
				, [Черновик]
				, [Верификация КЦ]
				, [Предварительное одобрение]
				, [Встреча назначена]
				, [Контроль данных]
				, [Call2]
				, [Call2 accept]
				, [Верификация документов клиента]
				, [Одобрены документы клиента]
				, [Верификация документов]
				, [Одобрено]
				, [Договор зарегистрирован]
				, [Заем выдан]
				, [ЗаемВыданP2P]
				, [P2P]
				, [Заем погашен]
				, [Заем аннулирован]
				, [Аннулировано]
				, [Отказ документов клиента]
				, [Отказано]
				, [Клиент передумал]
				, [Забраковано]
				, [Договор подписан]
				, [Отказ клиента]
				, [Call0.3]
				, [Call0.3 accepted]
				, [PreCall 1]
				, [PreCall 1 accepted]
				, [Call 1]
				, [Call 1 accept]
				, [Call 1.2]
				, [Call 1.2 accept]
				, [Call 1.5]
				, [Call 1.5 accept]
				, [Call 2.1]
				, [Call 2.1 accept]
				, [Call 2.2]
				, [Call 2.2 accept]
				, [Call 3]
				, [Call 3 accept]
				, [Call 4]
				, [Call 4 accept]
				, [Call 5]
				, [Call 5 accept]
				, [Call checkTransfer]
				, [Call checkTransfer accept]
				, [Call checkTransfer_FEDOR]
				, [Call checkTransfer_FEDOR accept]
			FROM #t_ЗаявкаНаЗаймПодПТС_СтатусыИСобытия AS T

			SELECT @InsertRows = @@ROWCOUNT

			DELETE C
			FROM link.ЗаявкаНаЗаймПодПТС_СтатусыИСобытия_change AS C
				INNER JOIN #t_change AS T
				--INNER JOIN #t_ЗаявкаНаЗаймПодПТС AS T
					ON T.GuidЗаявки = C.GuidЗаявки
		COMMIT

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @message = 
			concat(
				'Заполнение dwh2.dm.ЗаявкаНаЗаймПодПТС_СтатусыИСобытия. ',
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
				'Ошибка заполнения dwh2.dm.ЗаявкаНаЗаймПодПТС_СтатусыИСобытия. ',
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
