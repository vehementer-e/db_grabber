-- ============================================= 
-- Author: А. Никитин
-- Create date: 24.10.2022
-- Description: DWH-1790 Витрина по статусам заявки
-- ============================================= 
CREATE   PROC dm.Fill_ClientRequestStatus
	@ProcessGUID uniqueidentifier = NULL,
	@reLoadDay int = 3,
	@isDebug int = 0
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	SELECT @isDebug = isnull(@isDebug, 0)
	SET @ProcessGUID = isnull(@ProcessGUID, newid())

	IF @isDebug = 1 BEGIN
		SELECT @ProcessGUID                    
	END

	declare @InsertRows int, @DeleteRows int, @TempRows int
	DECLARE @StartDate datetime, @DurationSec int
	declare @error_description nvarchar(1024)
	DECLARE @Max_Период datetime, @Insert_Период datetime
	DECLARE @description nvarchar(1024), @message nvarchar(1024)

	BEGIN TRY
		SELECT @StartDate = getdate()

		SELECT @Max_Период = dateadd(YEAR, 2000, isnull(max(S.Период), '2000-01-01'))
		FROM dm.ClientRequestStatus AS S

		SELECT @Max_Период = dateadd(DAY, - @reLoadDay, @Max_Период)

		DROP TABLE IF EXISTS #t_ClientRequestStatus
		CREATE TABLE #t_ClientRequestStatus
		(
			DWHInsertedDate datetime NOT NULL,
			ЗаявкаСсылка binary(16) NOT NULL,
			external_id nvarchar(21) NOT NULL,
			Период datetime2 NOT NULL,
			СтатусСсылка binary(16) NULL,
			КодСтатуса nvarchar(128) NULL,
			НаименованиеСтатуса nvarchar(255) NULL
		)

		INSERT #t_ClientRequestStatus
		(
		    DWHInsertedDate,
		    ЗаявкаСсылка,
		    external_id,
		    Период,
		    СтатусСсылка,
		    КодСтатуса,
		    НаименованиеСтатуса
		)
		SELECT 
			DWHInsertedDate = getdate(),
			ЗаявкаСсылка = ЗаявкаНаЗайм.Ссылка,
			external_id = ЗаявкаНаЗайм.Номер,
			Период = dateadd(YEAR, -2000, СтатусыЗаявок.Период),
			СтатусСсылка = СтатусыЗаявок.Статус,
			СправочникСтатусыЗаявок.КодСтатуса,
			НаименованиеСтатуса = СправочникСтатусыЗаявок.Наименование
		FROM Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗайм
			INNER JOIN Stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС AS СтатусыЗаявок
				ON СтатусыЗаявок.Заявка = ЗаявкаНаЗайм.Ссылка
			LEFT JOIN Stg._1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС AS СправочникСтатусыЗаявок
				ON СправочникСтатусыЗаявок.Ссылка = СтатусыЗаявок.Статус 
		WHERE 1=1
			AND СтатусыЗаявок.Период >= @Max_Период

		SELECT @TempRows = @@ROWCOUNT

		IF @TempRows > 0
		BEGIN
			SELECT @Insert_Период = min(Период)
			FROM #t_ClientRequestStatus

			BEGIN TRAN
				DELETE S
				FROM dm.ClientRequestStatus AS S
				WHERE S.Период >= @Insert_Период

				SELECT @DeleteRows = @@ROWCOUNT

				INSERT dm.ClientRequestStatus
				(
					DWHInsertedDate,
					ЗаявкаСсылка,
					external_id,
					Период,
					СтатусСсылка,
					КодСтатуса,
					НаименованиеСтатуса
				)
				SELECT 
					S.DWHInsertedDate,
                    S.ЗаявкаСсылка,
                    S.external_id,
                    S.Период,
                    S.СтатусСсылка,
                    S.КодСтатуса,
                    S.НаименованиеСтатуса
				FROM #t_ClientRequestStatus AS S

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
			'Формирование витрины dm.ClientRequestStatus. ',
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
			@eventName = 'Fill_ClientRequestStatus',
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
			'Ошибка формирования витрины dm.ClientRequestStatus. ',
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
			@eventName = 'Error Fill_ClientRequestStatus',
			@eventType = 'Error',
			@message = @message,
			@description = @error_description, 
			@SendEmail = 0,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH
END
