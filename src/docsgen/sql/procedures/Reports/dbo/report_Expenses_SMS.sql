-- =======================================================
-- Created: 11.06.2023. А.Никитин
-- Description:	DWH-2100 Затраты на СМС
-- =======================================================
CREATE   PROC dbo.report_Expenses_SMS
	@dt_Begin date = NULL,
	@dt_End date = NULL
	--@ProcessGUID varchar(36) = NULL, -- guid процесса
	--@isDebug int = 0
AS
BEGIN

	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @ProcessGUID varchar(36)

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	--SELECT @isDebug = isnull(@isDebug, 0)     
	
	SELECT @dt_Begin = isnull(@dt_Begin, dateadd(DAY, 1, eomonth(getdate(), -3)))
	SELECT @dt_End = isnull(@dt_End, eomonth(getdate()))

	SELECT @dt_End = dateadd(DAY, 1, @dt_End)



	DECLARE @eventName nvarchar(255), @eventType nvarchar(50), @message nvarchar(1024) --, @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)
	DECLARE @LastPartitionID int
	DECLARE @Rowversion_Lead binary(8), @Rowversion_LeadAndSurvey binary(8)
	DECLARE @DeleteRows int = 0, @InsertRows int = 0, @CountRows int = 0
	DECLARE @DurationSec int, @StartDate_1 datetime = getdate(), @StartDate datetime = getdate()

	SELECT @eventName = 'dbo.report_Expenses_SMS', @eventType = 'info', @SendEmail = 0

	BEGIN TRY
		DROP TABLE IF EXISTS #t_report_Expenses_SMS

		CREATE TABLE #t_report_Expenses_SMS
		(
			ДатаSMS date,
			Функция nvarchar(30),
			Продукт nvarchar(30),
			ШаблонSMS nvarchar(255),
			КоличествоSMS int
		)

		INSERT #t_report_Expenses_SMS
		(
		    ДатаSMS,
		    Функция,
		    Продукт,
		    ШаблонSMS,
		    КоличествоSMS
		)
		SELECT 
			A.ДатаSMS,
			A.Функция,
			A.Продукт,
			A.ШаблонSMS,
			КоличествоSMS = count(*)
		FROM (
				SELECT 
					ДатаSMS = cast(C.created_at AS date),
					--Система = S.code,
					--КодШаблонаSMS = T.code,
					--(ПРОДАЖИ, COLLECTION, АНДЕРРАЙТИНГ, СЕРВИС) 
					Функция = 
						--test
						CASE 
							WHEN T.name LIKE '[А-Г]%' THEN 'ПРОДАЖИ' 
							WHEN T.name LIKE '[Д-О]%' THEN 'COLLECTION' 
							WHEN T.name LIKE '[П-У]%' THEN 'АНДЕРРАЙТИНГ' 
							ELSE 'СЕРВИС'
						END,
					Продукт = 
						--test
						CASE 
							WHEN CONT.full_name LIKE '[А-К]%' THEN 'ПТС' 
							ELSE 'Installment/PDL' 
						END,
					ШаблонSMS = CONCAT(T.name,' (',T.code,')')
					--КоличествоSMS = count(*)
				FROM Stg._COMCENTER.communications AS C 
					INNER JOIN Stg._COMCENTER.templates AS T -- шаблоны
						ON C.template_guid = T.guid
					INNER JOIN Stg._COMCENTER.methods AS M -- метод = sms. шаблоны связаны с methods по полю method_guid
						ON T.method_guid = M.guid
						AND M.code = 'sms'
					INNER JOIN Stg._COMCENTER.system_codes AS S -- системы, которые инициировали отправку
						ON C.system_code_guid = S.guid
					INNER JOIN Stg._COMCENTER.contacts_methods AS contMeth 
						ON contMeth.guid = C.contact_method_guid 
					INNER JOIN Stg._COMCENTER.contacts AS CONT
						ON CONT.guid = contMeth.contact_guid 
				WHERE 1=1
					AND C.created_at BETWEEN @dt_Begin AND @dt_End
			) AS A
		GROUP BY A.ДатаSMS, A.Функция, A.Продукт, A.ШаблонSMS

		SELECT 
			ГодSMS = convert(varchar(4), A.ДатаSMS, 120),
			МесяцSMS = convert(varchar(7), A.ДатаSMS, 120),
			A.ДатаSMS,
            A.Функция,
            A.Продукт,
            A.ШаблонSMS,
            A.КоличествоSMS 
		FROM #t_report_Expenses_SMS AS A
		ORDER BY A.ДатаSMS, A.Функция, A.Продукт, A.ШаблонSMS
	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @message = 'Ошибка dbo.report_Expenses_SMS'

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
