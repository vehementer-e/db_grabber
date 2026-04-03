-- ============================================= 
-- Author: Andrey Shubkin 
-- Create date: 25.02.2019 
-- Description: add message into log and send email into 'adminlog' email list 
-- exec [LogAndSendMailToAdmin] 'procedure name','Error','Error execute procedure','awesome errors and descriptions' 
-- ============================================= 
CREATE PROC [dbo].[LogAndSendMailToAdmin]
       @eventName nvarchar(1024) 
      ,@eventType nvarchar(1024) 
      ,@message nvarchar(1024)='' 
      ,@description nvarchar(1024)='' 
	  ,@SendEmail int = 1 -- 0 - не посылать email, 1 - send email into 'adminlog' email list (2022-02-19. А.Никитин)
	  ,@ProcessGUID nvarchar(36) = NULL --DWH-1645 Расширить мониторинг формирования dm_CMRStatBalance
	  ,@eventMessageText nvarchar(max) = NULL -- большое сообщение для расширенного логирования
	  ,@loggerName nvarchar(50) = NULL
	  ,@SendToSlack bit = 0--Отправлять в slack
AS 
BEGIN 
SET NOCOUNT ON; 
    declare @tsql nvarchar(max)
    ,@subject nvarchar(4000) 
    ,@body nvarchar(4000) 
    ,@email_body nvarchar(max) 
	DECLARE @log_id int

	SELECT @loggerName = isnull(@loggerName, 'adminlog')

    insert into dbo._log   (  
       [loggerName] 
      ,[logDateTime] 
      ,[logDate] 
      ,[logDtStarted] 
      ,[logDtEnded] 
      ,[logEventName] 
      ,[logEventType] 
      ,[logEventParams] 
      ,[logEventStatus] 
      ,[logEventDescription]
	  ,ProcessGUID
	) 
    select 
       @loggerName --'adminlog'
       ,getdate() 
       ,getdate() 
       ,getdate() 
       ,getdate() 
       ,@eventName 
       ,@eventType 
       ,@message 
       ,'log' 
       ,@description  
	   ,@ProcessGUID

	SELECT @log_id = scope_identity()

	-- большое сообщение для расширенного логирования
	IF @eventMessageText IS NOT NULL
	BEGIN
		INSERT dbo._log_ext(log_id, logEventText)
		SELECT @log_id, @eventMessageText
	END

	-- 1 - send email into @loggerName email list (2022-02-19. А.Никитин)
	IF isnull(@SendEmail, 1) = 1
	BEGIN
		declare @recipients nvarchar(1024)=''   

		select  @recipients = [emails] 
		from    dbo.Emails
		where	[loggerName] = @loggerName --'adminlog'
          
		--select @recipients 


		set @body = concat(
				cast(format(getdate(), 'dd.MM.yyyy HH:mm:ss ') as nvarchar(22)), ' ',
				@eventName, ' ',
				@message, '<br><br>',
				iif(isnull(isjson(@description), 0) = 1, '', @description)
			)
		SET @email_body = concat(
				cast(format(getdate(), 'dd.MM.yyyy HH:mm:ss ') as nvarchar(22)), ' ',
				@eventName, ' ',
				@message, '<br><br>',
				iif(isnull(isjson(@description), 0) = 1, '', @description + '<br><br>'),
				@eventMessageText
			)

		set @subject = concat(@eventType, ' - ', @eventName)


		if ltrim(rtrim(@recipients)) <>'' 
		begin 
		begin try
		EXEC msdb.dbo.sp_send_dbmail    
				@recipients = @recipients,  
				@body = @email_body,  
				@body_format='HTML', 
				@subject = @subject
		end try
		begin catch
			select ERROR_MESSAGE(), ERROR_NUMBER()
		end catch
		end 
		if @SendToSlack = 1
		begin
			declare @toslack_text nvarchar(max)=N''
			set @toslack_text='*'+@subject+'*'+'\n'+/* не работает в slack+char(13)+char(10)+*/@body
			begin try
				exec LogDb.[dbo].SendToSlack_DwhAdminNotofications
					@text = @toslack_text
				--exec [dwh-ex].bot.[dbo].[Send_to_slack_DwhAdminNotofications] @toslack_text
			end try
			begin catch
			EXEC msdb.dbo.sp_send_dbmail  
					@recipients = @recipients ,  
					@body = 'Cant send to slack',  
					@body_format='HTML', 
					@subject = @subject 
			
		
			end catch
		end
	END

END 

