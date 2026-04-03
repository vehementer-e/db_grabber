

-- =============================================
-- Author:		Andrey Shubkin
-- Create date: 2020-10-21
-- Description:	Send message to slack
-- exec [SendNotification].[Send2GChat_DwhAdminNotofications]  '*info - test send to slack*  25.08.2021 17:06:18  test send to slack test message<br><br>test message desc'
-- =============================================
CREATE   PROCEDURE [SendNotification].[Send2GChat_DwhAdminNotofications] 
	@text nvarchar(max)
	,@subject		 nvarchar(255)	 = null
	,@threadKey nvarchar(255) = null out

AS
BEGIN
	SET NOCOUNT ON;
	declare   @channelName nvarchar(255)= 'DwhAdminNotofications'
	begin try
		if nullif(trim(@text),'') is null
		begin
			;throw 50001, 'сообещние не может быть пустым', 16
		end
		exec	[SendNotification].Send2GChat
				@channelName	= @channelName
				,@textValue		= @text
				,@threadKey		= @threadKey out
	end try
	begin catch
			if  ERROR_NUMBER() in(50001 ----пустой text
			, 51429) --Ошибка вызова сервиса GCHAT. statusCode = 429 statusText = Too Many Requests 
			return;

		declare @recipients nvarchar(255) = 'dwh112@carmoney.ru'
			set @subject = CONCAT_WS(' ', 'Ошибка отправки в GChat -', @channelName)
		declare @body nvarchar(1024)= concat_ws(
			'ErrorMessage:', ERROR_MESSAGE()
			,'messageText:', @text
			)


	EXEC msdb.dbo.sp_send_dbmail  @recipients   = @recipients
	,                            @body         = @body
	,                            @body_format  = 'HTML'
	,                            @subject      = @subject

	end catch
-- EXEC [dwh-ex].bot.dbo.Send_to_slack_DwhNotofications @text

END
