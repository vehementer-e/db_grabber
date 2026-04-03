-- ============================================= 
-- Author: А. Никитин
-- Create date: 27.12.2022
-- Description: DWH-1792 Общая витрина
-- заполнение витрины dm.LK_RequestEvent - события в Личном кабинете Клиента
-- ============================================= 
CREATE   PROC dm.Fill_LK_RequestEvent
	@ProcessGUID uniqueidentifier = NULL,
	@reLoadDay int = 3,
	@isDebug int = 0
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	SELECT @isDebug = isnull(@isDebug, 0)
	SET @ProcessGUID = isnull(@ProcessGUID, newid())

	DECLARE @InsertRows int, @DeleteRows int, @TempRows int
	DECLARE @StartDate datetime, @DurationSec int
	declare @error_description nvarchar(1024)
	DECLARE @max_updated_at datetime, @insert_updated_at datetime
	DECLARE @description nvarchar(1024), @message nvarchar(1024)

	BEGIN TRY
		SELECT @StartDate = getdate()

		SELECT @max_updated_at = isnull(max(E.updated_at), '2000-01-01')
		FROM dm.LK_RequestEvent AS E

		SELECT @max_updated_at = dateadd(DAY, - @reLoadDay, @max_updated_at)

		IF @isDebug = 1 BEGIN
			SELECT @ProcessGUID, @max_updated_at
		END
		

		DROP TABLE IF EXISTS #t_LK_RequestEvent
		CREATE TABLE #t_LK_RequestEvent
		(
			DWHInsertedDate datetime NOT NULL,
			id int,
			request_id int,
			external_id nvarchar(255),
			event_id int,
			is_sended int,
			is_ignored numeric(3, 0),
			ignore_reason nvarchar(512),
			created_at datetime2,
			updated_at datetime2,
			event_code int,
			event_name nvarchar(255)
		)

		INSERT #t_LK_RequestEvent
		(
		    DWHInsertedDate,
		    id,
		    request_id,
			external_id,
		    event_id,
		    is_sended,
		    is_ignored,
		    ignore_reason,
		    created_at,
		    updated_at,
		    event_code,
		    event_name
		)
		SELECT 
			DWHInsertedDate = getdate(),
			RE.id,
			RE.request_id,
			external_id = R.num_1c,
			RE.event_id,
			RE.is_sended,
			RE.is_ignored,
			RE.ignore_reason,
			created_at = dateadd(HOUR, 3, RE.created_at), --перевод в msk, т.к. в таблицах LK все даты по Гринвичу
			updated_at = dateadd(HOUR, 3, RE.updated_at),
			event_code = E.code,
			event_name = E.name
		FROM Stg._LK.requests_events AS RE
			INNER JOIN Stg._LK.events AS E
				ON RE.event_id = E.id
			INNER JOIN Stg._LK.requests AS R
				ON R.id = RE.request_id
		WHERE 1=1
			AND RE.updated_at >= @max_updated_at

		SELECT @TempRows = @@ROWCOUNT

		IF @TempRows > 0
		BEGIN
			SELECT @insert_updated_at = min(E.updated_at)
			FROM #t_LK_RequestEvent AS E

			BEGIN TRAN
				DELETE E
				FROM dm.LK_RequestEvent AS E
				WHERE E.updated_at >= @insert_updated_at

				SELECT @DeleteRows = @@ROWCOUNT

				INSERT dm.LK_RequestEvent
				(
				    DWHInsertedDate,
				    id,
				    request_id,
				    external_id,
				    event_id,
				    is_sended,
				    is_ignored,
				    ignore_reason,
				    created_at,
				    updated_at,
				    event_code,
				    event_name
				)
				SELECT 
					E.DWHInsertedDate,
                    E.id,
                    E.request_id,
                    E.external_id,
                    E.event_id,
                    E.is_sended,
                    E.is_ignored,
                    E.ignore_reason,
                    E.created_at,
                    E.updated_at,
                    E.event_code,
                    E.event_name
				FROM #t_LK_RequestEvent AS E

				SELECT @InsertRows = @@ROWCOUNT
			COMMIT
		END

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())


		IF @isDebug = 1 BEGIN
			SELECT concat('Удалено: ', convert(varchar(10), @DeleteRows), '. ',
				'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
				'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
			)
		END

		SELECT @message = concat(
			'Формирование витрины dm.LK_RequestEvent. ',
			'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
			'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
			'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
		)

		SELECT @description =
			(
			SELECT
				'DeleteRows' = @DeleteRows,
				'InsertRows' = @InsertRows,
				'DurationSec' = @DurationSec
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
			)

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = 'Fill_LK_RequestEvent',
			@eventType = 'Info',
			@message = @message,
			@description = @description, 
			@SendEmail = 0,
			@ProcessGUID = @ProcessGUID

	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @message = concat(
			'Ошибка формирования витрины dm.LK_RequestEvent. ',
			'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
			'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
			'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
		)

		SELECT @description =
			(
			SELECT
				'DeleteRows' = @DeleteRows,
				'InsertRows' = @InsertRows,
				'DurationSec' = @DurationSec
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
			)

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = 'Error Fill_LK_RequestEvent',
			@eventType = 'Error',
			@message = @message,
			@description = @error_description, 
			@SendEmail = 0,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH
END
