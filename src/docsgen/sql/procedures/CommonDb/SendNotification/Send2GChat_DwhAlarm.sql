



-- =============================================
-- Author:		Anatoly Kotelevets
-- Create date: 2020-10-21
-- Description:	Send message to slack
-- exec SendNotification.[Send2GChat_DwhAlarm] @text = 'test'
-- =============================================
CREATE    PROCEDURE [SendNotification].[Send2GChat_DwhAlarm] 
	@text nvarchar(max)
	,@threadKey nvarchar(255) = null out	

AS
BEGIN
	SET NOCOUNT ON;
	declare   @channelName nvarchar(255)= 'DwhAlarm'
	begin try
	if nullif(trim(@text),'') is null
	begin
		;throw 50001, 'сообещние не может быть пустым', 16
	end
	--if 			
	--	(@text LIKE '%network%'										
	--		or @text LIKE  '%timeout%'									
	--		or @text LIKE  '%connection%'								
	--		or @text LIKE  '%сеть%'										
	--		or @text LIKE  '%сетев%'									
	--		or @text LIKE  '%не удалось открыть подключение%'			
	--		or @text LIKE  '%при установлении соединения%'				
	--		or @text LIKE  '%сервер не найден%'							
	--		or @text LIKE  '%can''t connect to mysql%'					
	--		or @text LIKE  '%истекло время ожидания соединения%'				
	--		or @text LIKE '%named pipes provider%')
		exec	[SendNotification].Send2GChat
			@channelName	= @channelName
			,@textValue		= @text
			,@threadKey		= @threadKey out
	end try
	begin catch
		if  ERROR_NUMBER() in(50001 ----пустой text
			, 51429) --Ошибка вызова сервиса GCHAT. statusCode = 429 statusText = Too Many Requests 
		begin
			return;
		end
		declare @recipients nvarchar(255) = 'dwh112@carmoney.ru'
		declare @subject nvarchar(255) =  CONCAT_WS(' ', 'Ошибка отправки в GChat -', @channelName)
		declare @body nvarchar(1024)= concat_ws(
		'ErrorMessage:', ERROR_MESSAGE()
		,'messageText:', @text
		)


		EXEC msdb.dbo.sp_send_dbmail @recipients   = @recipients
		,                            @body         = @body
		,                            @body_format  = 'HTML'
		,                            @subject      = @subject
	end catch

-- EXEC [dwh-ex].bot.dbo.Send_to_slack_DwhNotofications @text

END
