-- ============================================= 
-- Author: А. Никитин
-- Create date: 27.12.2022
-- Description: DWH-1792 Общая витрина
-- заполнение витрины dm.LK_Status_MP
-- ============================================= 
CREATE   PROC [dm].[Fill_LK_Status_MP]
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
		FROM dm.LK_Status_MP AS E

		SELECT @max_updated_at = dateadd(DAY, - @reLoadDay, @max_updated_at)

		IF @isDebug = 1 BEGIN
			SELECT @ProcessGUID, @max_updated_at
		END
		

		DROP TABLE IF EXISTS #t_LK_Status_MP
		CREATE TABLE #t_LK_Status_MP
		(
			DWHInsertedDate datetime NOT NULL,
			id int,
			request_id int,
			external_id nvarchar(255),
			status_extended_id int,
			status_identifier nvarchar(255),
			status_name nvarchar(255),
			created_at datetime2,
			updated_at datetime2,
		)

		INSERT #t_LK_Status_MP
		(
		    DWHInsertedDate,
		    id,
		    request_id,
		    external_id,
		    status_extended_id,
		    status_identifier,
		    status_name,
		    created_at,
		    updated_at
		)
		SELECT
			DWHInsertedDate = getdate(),
			J.id,
			J.request_id,
			external_id = R.num_1c,
			J.status_extended_id,
			status_identifier = S.identifier,
			status_name = S.name,
			created_at = dateadd(HOUR, 3, J.created_at), --перевод в msk, т.к. в таблицах LK все даты по Гринвичу
			updated_at = dateadd(HOUR, 3, J.updated_at)
		FROM Stg._LK.request_status_extended AS J
			INNER JOIN Stg._LK.status_extended AS S
				ON S.id = J.status_extended_id
			INNER JOIN Stg._LK.requests AS R
				ON R.id = J.request_id
		WHERE 1=1
			AND J.updated_at >= @max_updated_at

		SELECT @TempRows = @@ROWCOUNT

		IF @TempRows > 0
		BEGIN
			SELECT @insert_updated_at = min(E.updated_at)
			FROM #t_LK_Status_MP AS E

			BEGIN TRAN
				DELETE E
				FROM dm.LK_Status_MP AS E
				WHERE E.updated_at >= @insert_updated_at

				SELECT @DeleteRows = @@ROWCOUNT

				INSERT dm.LK_Status_MP
				(
					DWHInsertedDate,
					id,
					request_id,
					external_id,
					status_extended_id,
					status_identifier,
					status_name,
					created_at,
					updated_at
				)
				SELECT 
					E.DWHInsertedDate,
                    E.id,
                    E.request_id,
                    E.external_id,
                    E.status_extended_id,
                    E.status_identifier,
                    E.status_name,
                    E.created_at,
                    E.updated_at
				FROM #t_LK_Status_MP AS E

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
			'Формирование витрины dm.LK_Status_MP. ',
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
			@eventName = 'Fill_LK_Status_MP',
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
			'Ошибка формирования витрины dm.LK_Status_MP. ',
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
			@eventName = 'Error Fill_LK_Status_MP',
			@eventType = 'Error',
			@message = @message,
			@description = @error_description, 
			@SendEmail = 0,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH
END
