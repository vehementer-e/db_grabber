-- =======================================================
-- Create: 31.03.2023. А.Никитин
-- Description:	DWH-2008 Оперативная витрина по лидам за последние 5 дней
--		удаление старых записей
-- =======================================================
-- Usage: запуск процедуры с параметрами
-- EXEC _LCRM.clear_dm_lead_in_recent_days_for_ivr
--      @ProcessGUID = NULL,
--      @isDebug = 0;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   PROC _LCRM.clear_dm_lead_in_recent_days_for_ivr
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	--@mode int = 1, -- 0 - full, 1 - increment
	@isDebug int = 0
AS 
BEGIN
	SET NOCOUNT ON 
	SET XACT_ABORT ON

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)     

	DECLARE @dt_from datetime
	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024) --, @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)
	--DECLARE @InsertRows int = 0, @UpdateRows int = 0
	DECLARE @DeleteRows int = 0

	SELECT @eventName = '_LCRM.clear_dm_lead_in_recent_days_for_ivr', @eventType = 'info', @SendEmail = 0

	BEGIN TRY

		SELECT @dt_from = cast(dateadd(DAY, -5, getdate()) AS date)

		DELETE A
		FROM _LCRM.dm_lead_in_recent_days_for_ivr AS A
		WHERE A.UF_REGISTERED_AT < @dt_from

		SELECT @DeleteRows = @@ROWCOUNT

		SELECT @message = concat(
				'Удаление старых записей.',
				' @dt_from: ', format(@dt_from, 'yyyy-MM-dd'),
				', @DeleteRows = ', convert(varchar(10), @DeleteRows)
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
		SET @error_description = 'ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @message = 'Ошибка удаления старых записей из _LCRM.dm_lead_in_recent_days_for_ivr'

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
