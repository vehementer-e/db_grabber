-- =======================================================
-- Create: 17.07.2025. А.Никитин
-- Description:	заполнение линков между hub.Collection_EnforcementOrders и другими хабами
-- =======================================================
create   PROC link.exec_fill_link_between_Collection_EnforcementOrders_and_other
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	--@mode int = 1, -- 0 - full, 1 - increment
	@isDebug int = 0
AS 
BEGIN
	SET NOCOUNT ON 
	SET XACT_ABORT ON

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)     

	--DECLARE @dt_begin date, @dt_from date, @dt_to date, @dt_old date
	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024), @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)
	DECLARE @LinkName nvarchar(255), @cnt int
	SELECT @eventName = 'dwh2.link.exec_fill_link_between_Collection_EnforcementOrders_and_other', @eventType = 'info', @SendEmail = 0

	BEGIN TRY

		DECLARE cur_LinkName CURSOR FOR
		SELECT S.LinkName, cnt = count(*)
		FROM link.Collection_EnforcementOrders_stage AS S
		GROUP BY S.LinkName
		ORDER BY cnt DESC

		OPEN cur_LinkName

		FETCH NEXT FROM cur_LinkName INTO @LinkName, @cnt

		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			declare @reTry smallint = 3, @tryCount smallint = 0
			while @reTry > @tryCount 
			begin
				begin try
					EXEC link.fill_link_between_Collection_EnforcementOrders_and_other
						@LinkName = @LinkName

					SELECT @message = concat(
							'Добавление и обновление записей в линк-таблице ',
							@LinkName,
							', Кол-во записей: ', convert(varchar(10), @cnt)
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

					set @tryCount += @reTry + 1

				end try
				begin CATCH
					SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
						+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
						+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')

					IF @@TRANCOUNT > 0
						   ROLLBACK;

					SELECT @message = 'Ошибка вызова link.fill_link_between_Collection_EnforcementOrders_and_other'

					EXEC LogDb.dbo.LogAndSendMailToAdmin 
						@eventName = @eventName,
						@eventType = 'Error',
						@message = @message,
						@description = @error_description,
						@SendEmail = @SendEmail,
						@ProcessGUID = @ProcessGUID
                
					set @tryCount += 1;

					if @tryCount >= @reTry
					begin
						--;throw @ERROR_NUMBER, @ERROR_MESSAGE, 16
						;THROW 51000, @error_description, 1
					end
					ELSE BEGIN
						continue
					END
				end catch
			end

			FETCH NEXT FROM cur_LinkName INTO @LinkName, @cnt
		END
		CLOSE cur_LinkName
		DEALLOCATE cur_LinkName

	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @message = 'Ошибка вызова link.fill_link_between_Collection_EnforcementOrders_and_other'

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = @eventName,
			@eventType = 'Data Valut ERROR',
			@message = @message,
			@description = @error_description,
			@SendEmail = 1,
			@SendToSlack = 1,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH

END
