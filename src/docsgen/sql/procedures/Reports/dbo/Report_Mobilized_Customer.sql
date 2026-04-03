-- =======================================================
-- Create: 17.05.2023. А.Никитин
-- Description:	DWH-2074 отчет по мобилизованным клиентам
-- =======================================================
CREATE   PROC dbo.Report_Mobilized_Customer
	--@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isDebug int = 0
AS 
BEGIN
	SET NOCOUNT ON 
	SET XACT_ABORT ON

	DECLARE @ProcessGUID varchar(36)
	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024) --, @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)

	SELECT @eventName = 'dbo.Report_Mobilized_Customer', @eventType = 'info', @SendEmail = 0

	BEGIN TRY

		/*
		ФИО Клиента
		клиенты, по которым есть активный статус "Мобилизован" или "Мобилизация завершена" 
		или был статус "Мобилизован", который был снят по результату ответа сервиса

		Мобилизован
		Да (если был сделан запрос в сервис и получена "Дата начала мобилизации", но не получена или не наступила "Дата окончания мобилизации"
		<пусто> - если назначен статус "Мобилизован", но запросов в сервис после назначения статуса не производилось
		Нет - статус "Мобилизован" был снят системой по итогу запроса в сервис

		Дата начала мобилизации

		Дата окончания мобилизации

		Мобилизация завершена
		Да - есть активный статус "мобилизация завершена"
		Нет - нет активного статуса "мобилизация завершена" (еще не назначен или уже снят)

		Дата окончания льготного периода
		расчетное = Дата окончания мобилизации" + 30 к.д.
		*/

		DROP TABLE IF EXISTS #t_Mobilized_Customer
		CREATE TABLE #t_Mobilized_Customer
		(
			[ФИО Клиента] varchar(255),
			[Мобилизован] varchar(10),
			[Дата начала мобилизации] date,
			[Дата окончания мобилизации] date,
			[Мобилизация завершена] varchar(10),
			[Дата окончания льготного периода] date
		)
		INSERT #t_Mobilized_Customer
		(
		    [ФИО Клиента],
		    Мобилизован,
		    [Дата начала мобилизации],
		    [Дата окончания мобилизации],
		    [Мобилизация завершена],
		    [Дата окончания льготного периода]
		)
		SELECT 
			[ФИО Клиента] = concat(C.LastName, ' ', C.Name, ' ', C.MiddleName),

			--CS.IsActive,

			--Да (если был сделан запрос в сервис и получена "Дата начала мобилизации", 
			--	но не получена или не наступила "Дата окончания мобилизации"
			--<пусто> - если назначен статус "Мобилизован", но запросов в сервис после назначения статуса не производилось
			--Нет - статус "Мобилизован" был снят системой по итогу запроса в сервис
		    Мобилизован = 
				CASE 
					WHEN CS.Mobilized_StartDate IS NOT NULL AND CS.Mobilized_FinishDate IS NULL
						THEN 'Да'
					WHEN CS.IsActive = 1 AND CS.Mobilized_StartDate IS NULL
						THEN ''
					ELSE 'Нет'
				END,

		    [Дата начала мобилизации] = cast(CS.Mobilized_StartDate AS date),
		    [Дата окончания мобилизации] = cast(CS.Mobilized_FinishDate AS date),

			--Да - есть активный статус "мобилизация завершена"
			--Нет - нет активного статуса "мобилизация завершена" (еще не назначен или уже снят)
		    [Мобилизация завершена] = 
				CASE 
					WHEN CS.Mobilized_StartDate IS NOT NULL AND CS.Mobilized_FinishDate IS NOT NULL
						THEN 'Да'
					WHEN CS.Mobilized_FinishDate IS NULL
						THEN 'Нет'
					ELSE ''
				END,

			--расчетное = Дата окончания мобилизации" + 30 к.д.
		    [Дата окончания льготного периода] = dateadd(DAY, 30, cast(CS.Mobilized_FinishDate AS date))

			--C.* 
		FROM Stg._Collection.customers AS C
			INNER JOIN Stg._Collection.CustomerStatus AS CS
				ON CS.CustomerId = C.Id
				AND CS.CustomerStateId = 24 

		SELECT 
		    M.[ФИО Клиента],
		    M.Мобилизован,
		    M.[Дата начала мобилизации],
		    M.[Дата окончания мобилизации],
		    M.[Мобилизация завершена],
		    M.[Дата окончания льготного периода]
		FROM #t_Mobilized_Customer AS M
		ORDER BY M.[ФИО Клиента]


		SELECT @message = 'Выполнение отчета dbo.Report_Mobilized_Customer'

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

		SELECT @message = 'Ошибка выполнения отчета dbo.Report_Mobilized_Customer'

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
