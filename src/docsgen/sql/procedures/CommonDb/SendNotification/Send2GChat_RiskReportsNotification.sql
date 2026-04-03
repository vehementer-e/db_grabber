

-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 2020-10-21
-- Description:	Send message to slack
-- exec [dbo].[SendToSlack_dwhNotification]  'тест'
-- =============================================
CREATE   PROCEDURE SendNotification.[Send2GChat_RiskReportsNotification] 
  @text nvarchar(max)
 ,@subject		 nvarchar(255)	 = null
 ,@threadKey nvarchar(255) = null out
AS
BEGIN
	SET NOCOUNT ON;
		declare   @channelName nvarchar(255)= 'RiskReportsNotification'
  begin try
	exec	SendNotification.Send2GChat
		@channelName	= @channelName
		,@textValue		= @text
		,@threadKey		= @threadKey out


	--EXEC [dwh-ex].bot.dbo.Send_to_slack_DwhNotofications
	--	@text = @text
		end try
    begin catch
	if  ERROR_NUMBER() = 50001--пустой text
			return;
	declare @recipients nvarchar(255) = 'dwh112@carmoney.ru'
		set @subject = CONCAT_WS(' ', 'Ошибка отправки в GChat -', @channelName)
	declare @body nvarchar(1024)= concat_ws(
		'ErrorMessage:', ERROR_MESSAGE()
		,'messageText:', @text
		)


	EXEC msdb.dbo.sp_send_dbmail @recipients   = @recipients
	,                            @body         = @body
	,                            @body_format  = 'HTML'
	,                            @subject      = @subject
    end catch

  
   
END
