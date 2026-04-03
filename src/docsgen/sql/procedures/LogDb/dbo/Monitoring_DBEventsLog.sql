-- ============================================= 
-- Author: А. Никитин
-- Create date: 12.10.2022
-- Description: DWH-1767. Мониторинг лога, рассылка email, отправка в Slack/RocketChat
-- ============================================= 
CREATE   PROC [dbo].[Monitoring_DBEventsLog]
	@dt_from datetime = NULL,
	@dt_to datetime = NULL
AS
BEGIN
SET NOCOUNT ON;

	IF @dt_from IS NULL BEGIN
		SELECT @dt_from = cast(dateadd(DAY,-1,getdate()) AS date)
	END
	IF @dt_to  IS NULL BEGIN
		SELECT @dt_to = getdate()
	END

	DECLARE @html_table nvarchar(max)
	--DECLARE @text nvarchar(4000)
	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024), @description nvarchar(1024)

	--преобразовать recordset в таблицу html
	SELECT @html_table = (
		SELECT string_agg(
			concat(
				'<tr>',
					'<td>', convert(varchar(10), L.EventID), '</td>',
					'<td>', convert(varchar(19), L.EventDateTime, 120), '</td>',
					'<td>', L.EventType, '</td>',
					'<td>', L.EventDDL, '</td>',
					'<td>', L.DatabaseName, '</td>',
					'<td>', L.SchemaName, '</td>',
					'<td>', L.ObjectName, '</td>',
					'<td>', L.HostName, '</td>',
					'<td>', L.IPAddress, '</td>',
					'<td>', L.ProgramName, '</td>',
					'<td>', L.LoginName, '</td>',
				'</tr>'
			), char(13)+char(10)
		)  WITHIN GROUP (ORDER BY L.EventID)
		FROM LogDB.dbo.DBEventsLog AS L
		WHERE L.EventDateTime BETWEEN @dt_from AND @dt_to
	)

	SELECT @html_table = 
		concat('<table cellspacing="0" border="1" cellpadding="5">',
				'<tr>',
					'<td><b>EventID</b></td>',
					'<td><b>EventDateTime</b></td>',
					'<td><b>EventType</b></td>',
					'<td><b>EventDDL</b></td>',
					'<td><b>DatabaseName</b></td>',
					'<td><b>SchemaName</b></td>',
					'<td><b>ObjectName</b></td>',
					'<td><b>HostName</b></td>',
					'<td><b>IPAddress</b></td>',
					'<td><b>ProgramName</b></td>',
					'<td><b>LoginName</b></td>',
				'</tr>',
				@html_table,
				'</table>'
		)


	--SELECT @eventName = substring('DDL Event on ' + DB_NAME(), 1, 50),
	--	@eventType = substring(@EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'), 1, 50),
	--	@message  = substring(@EventData.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'NVARCHAR(MAX)'), 1, 1024),
	--	@description  = ''

	--SELECT @text = concat(@eventName, '. ', @message, '. ', format(getdate(),'dd.MM.yyyy HH:mm:ss'))

	--EXEC LogDb.dbo.SendToSlack_dwhNotification @text

	--EXEC LogDb.dbo.LogAndSendMailToAdmin
	--	@eventName = @eventName,
	--	@eventType = @eventType,
	--	@message = @message,
	--	@description = @description

	declare @recipients nvarchar(1024)=''   
	select  @recipients=[emails] 
	from    dbo.Emails
	where 	[loggerName]        ='adminlog'    

    declare @tsql nvarchar(max) 
		,@subject nvarchar(1024) 
		,@body nvarchar(max) 

	set @subject = concat(
		'События DDL c ',
		format(@dt_from, 'dd.MM.yyyy HH:mm:ss'),
		' по ',
		format(@dt_to, 'dd.MM.yyyy HH:mm:ss')
	)

	set @body = concat(
		'<H1>', @subject, '</H1><br><br>', @html_table
	)
	
	if ltrim(rtrim(@recipients)) <>'' 
	begin 
	
				EXEC msdb.dbo.sp_send_dbmail  
											@recipients = @recipients ,  
											@body = @body,  
											@body_format='HTML', 
											@subject = @subject 
	
	end 

	--test
	--SELECT @html_table
	--SELECT @subject
END 

