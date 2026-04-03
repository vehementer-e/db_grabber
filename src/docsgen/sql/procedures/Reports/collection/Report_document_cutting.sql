-- =============================================
-- Author:		А.Никитин
-- Create date: 2024-12-03
-- Description:	DWH-2851 Реализовать отчет по результатам нарезки документов
-- =============================================
/*
EXEC collection.Report_document_cutting
	,@dtFrom = '2024-11-01'
	,@dtTo = '2024-12-10'

*/
CREATE PROC collection.Report_document_cutting
--declare
	--@Page nvarchar(100) = 'Detail'
	@dtFrom date = null -- '2021-04-01'
	,@dtTo date =  null --'2021-04-26'
	,@ClientFIO nvarchar(1000) = NULL
	,@ProcessGUID varchar(36) = NULL -- guid процесса
	--,@isDebug int = 0
AS
BEGIN
	SET NOCOUNT ON;
BEGIN TRY

	--SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50)
	DECLARE @description nvarchar(1024), @message nvarchar(1024), @error_number int
	DECLARE @dt_from date, @dt_to date

	IF @dtFrom is not NULL BEGIN
		SET @dt_from = @dtFrom
	END 
	ELSE BEGIN
		SET @dt_from = dateadd(MONTH, -1, cast(format(getdate(),'yyyyMM01') AS date))
	END

	IF @dtTo is not NULL BEGIN
		IF @dtTo > cast(getdate() AS date) BEGIN
			SELECT @dtTo = cast(getdate() AS date)
		END

		SET @dt_to = dateadd(day,1,@dtTo)
	END
	ELSE BEGIN
		SET @dt_to = dateadd(day,1,cast(getdate() as date))
	END 

	SELECT 
		D.ВходящиеДокументы_Ссылка,
		D.Номер_Вх_Документа,
		D.Вид_Корреспонденции,
		D.Дата_Вх_Документа,
		D.Номер_Договора,
		D.ФИО_клиента,
		D.Количество_документов,
		D.Список_документов,
		Дата_завершения_разрезки = D.ЗаданияНарезкиЕдиныйСкан_ДатаДобавления,
		D.Всего_документов,
		D.Через_сервис,
		D.Вручную,
		D.Из_них_не_разрезано,
		--% успешного разрезания через сервис
		--расчет по формуле = (Из них разрезано через сервис / Из них разрезано Всего)*100%
		Процент_успешного_разрезания = 
			CASE
				WHEN D.Всего_документов <> 0
				THEN D.Через_сервис * 1.0 / D.Всего_документов
				ELSE 0
			END
	--FROM dwh2.dm.document_cutting AS D
	FROM Reports.collection.document_cutting AS D
	WHERE 1=1
		AND @dt_from <= D.Дата_Вх_Документа AND D.Дата_Вх_Документа < @dt_to
		AND (D.ФИО_клиента LIKE '%'+@ClientFIO+'%' OR @ClientFIO is null)
	ORDER BY D.Дата_Вх_Документа

END TRY
BEGIN CATCH
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
			ROLLBACK;

	SELECT @message = concat(
		'EXEC dbo.Report_document_cutting ',
		--'@Page=''', @Page, ''', ',
		'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		'@ClientFIO=', iif(@ClientFIO IS NULL,'NULL', @ClientFIO), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+'''')
	)
		--, ', ',
		--'@isDebug=', convert(varchar(10), @isDebug)
		--)

	--SELECT @eventType = concat(@Page, ' ERROR')
	SELECT @eventType = 'ERROR'

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Report_document_cutting',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END
