-- ============================================= 
-- Author: А. Никитин
-- Create date: 24.10.2022
-- Description: DWH-1791 Витрина по событиям заявки
-- ============================================= 
CREATE   PROC dm.Fill_ClientRequestEvent
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

	DECLARE @InsertRows int, @DeleteRows int, @TempRows int
	DECLARE @StartDate datetime, @DurationSec int
	declare @error_description nvarchar(1024)
	DECLARE @Max_Дата datetime, @Insert_Дата datetime
	DECLARE @description nvarchar(1024), @message nvarchar(1024)

	BEGIN TRY
		SELECT @StartDate = getdate()

		SELECT @Max_Дата = dateadd(YEAR, 2000, isnull(max(E.Дата), '2000-01-01'))
		FROM dm.ClientRequestEvent AS E

		SELECT @Max_Дата = dateadd(DAY, - @reLoadDay, @Max_Дата)

		DROP TABLE IF EXISTS #t_ClientRequestEvent
		CREATE TABLE #t_ClientRequestEvent
		(
			DWHInsertedDate datetime NOT NULL,
			ЗаявкаСсылка binary(16) NOT NULL,
			external_id nvarchar(21) NOT NULL,
			Дата datetime2 NOT NULL,
			СобытиеСсылка binary(16) NULL,
			КодСобытия nvarchar(128) NULL,
			НаименованиеСобытия nvarchar(255) NULL
		)

		INSERT #t_ClientRequestEvent
		(
		    DWHInsertedDate,
		    ЗаявкаСсылка,
		    external_id,
		    Дата,
		    СобытиеСсылка,
		    КодСобытия,
		    НаименованиеСобытия
		)
		SELECT 
			DWHInsertedDate = getdate(),
			ЗаявкаСсылка = ЗаявкаНаЗайм.Ссылка,
			external_id = ЗаявкаНаЗайм.Номер,
			Дата = dateadd(YEAR, -2000, ИсторияСобытийЗаявок.Дата),
			СобытиеСсылка = ИсторияСобытийЗаявок.Событие,
			КодСобытия = Справочник_События.Код,
			НаименованиеСобытия = Справочник_События.Наименование
		FROM Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗайм
			INNER JOIN Stg._1cCRM.РегистрСведений_ИсторияСобытийЗаявокНаЗаймПодПТС AS ИсторияСобытийЗаявок
				ON ЗаявкаНаЗайм.Ссылка = ИсторияСобытийЗаявок.Объект
			LEFT JOIN Stg._1cCRM.Справочник_СобытияЗаявокНаЗаймПодПТС AS Справочник_События
				ON Справочник_События.Ссылка = ИсторияСобытийЗаявок.Событие
		WHERE 1=1
			AND ИсторияСобытийЗаявок.Дата >= @Max_Дата

		SELECT @TempRows = @@ROWCOUNT

		IF @TempRows > 0
		BEGIN
			SELECT @Insert_Дата = min(Дата)
			FROM #t_ClientRequestEvent

			BEGIN TRAN
				DELETE E
				FROM dm.ClientRequestEvent AS E
				WHERE E.Дата >= @Insert_Дата

				SELECT @DeleteRows = @@ROWCOUNT

				INSERT dm.ClientRequestEvent
				(
					DWHInsertedDate,
					ЗаявкаСсылка,
					external_id,
					Дата,
					СобытиеСсылка,
					КодСобытия,
					НаименованиеСобытия
				)
				SELECT 
					E.DWHInsertedDate,
                    E.ЗаявкаСсылка,
                    E.external_id,
                    E.Дата,
                    E.СобытиеСсылка,
                    E.КодСобытия,
                    E.НаименованиеСобытия
				FROM #t_ClientRequestEvent AS E

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
			'Формирование витрины dm.ClientRequestEvent. ',
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
			@eventName = 'Fill_ClientRequestEvent',
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
			'Ошибка формирования витрины dm.ClientRequestEvent. ',
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
			@eventName = 'Error Fill_ClientRequestEvent',
			@eventType = 'Error',
			@message = @message,
			@description = @error_description, 
			@SendEmail = 0,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH
END
