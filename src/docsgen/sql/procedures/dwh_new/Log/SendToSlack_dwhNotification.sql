-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 2020-10-20
-- Description:	Send message to slack
-- =============================================
CREATE PROCEDURE [Log].[SendToSlack_dwhNotification] 
  @text nvarchar(max)
	
AS
BEGIN
	SET NOCOUNT ON;
begin try   
   EXEC [dwh-ex].bot.dbo.Send_to_slack_DwhNotofications @text
end try

begin catch
	declare @recipients nvarchar(255) = (select emails
	from log.Emails
	where [loggerName] = 'adminlog')
	declare @subject nvarchar(255) = 'Cant send to slack'
	declare @body nvarchar(1024)= ' ErrorMessage: '+ isnull(ERROR_MESSAGE(),'')


	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
	,                            @recipients   = @recipients
	,                            @body         = @body
	,                            @body_format  = 'HTML'
	,                            @subject      = @subject
end catch
   END
