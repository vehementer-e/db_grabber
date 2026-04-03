
-- ============================================= 
-- Author: А. Никитин
-- Create date: 27.05.2022
-- Description: запись в лог, рассылка email, отправка в Slack
-- ============================================= 
CREATE PROC [dbo].[AddEventLog_SendEmail_SendToSlack]
	@logger_name nvarchar(127) = 'adminlog', -- например: 'adminlog', 'Airflow'
	@process_guid varchar(36) = NULL, -- guid процесса
	--
	@event_level varchar(30) = 'info', -- например: 'error', 'info', 'warning'
	@event_type varchar(127) = NULL, -- например: 'task_start', 'create_balance', 'create_indexes', 'data_quality_check'
	@event_name varchar(256) = NULL, -- например: 'Заполнение витрины ...', 'Расчет баланса'
	--
	@event_step_number int = NULL, -- 1,2,3,...
	@event_step_type varchar(127) = NULL, -- например: 'start load t1', 'create index ix1'
	@event_step_name varchar(256) = NULL, -- например: 'Начало загрузки таблицы t1'
	--
	@event_status varchar(30) = NULL, -- например: 'failed', 'running', 'skipped', 'succeeded'
	@event_message nvarchar(2048) = NULL, -- текст сообщения в произвольной форме, например, сообщение об ошибке
	@event_description nvarchar(2048) = NULL, -- структурированная информация, например, параметры в формате json, xml
	--
	@event_message_text nvarchar(max) = NULL, -- большое сообщение для расширенного логирования
	--
	@SendEmail int = 0, -- 0 - не посылать email, 1 - send email into 'adminlog' email list (2022-02-19. А.Никитин)
	@SendSlack int = 0 -- 0 - не отправлять в Slack, 1 - в Slack
AS
BEGIN
SET NOCOUNT ON;
    DECLARE @tsql nvarchar(4000), @subject nvarchar(1024), @body nvarchar(1024)
	DECLARE @recipients nvarchar(1024) = '', @copy_recipients nvarchar(1024), @blind_copy_recipients nvarchar(1024)
	DECLARE @event_log_id int
	DECLARE @toslack_text nvarchar(max) = N''
	DECLARE @html_table nvarchar(4000)

	INSERT dbo.event_log
	(
		--event_date_time,
		--event_date,
		logger_name,
		process_guid,
		event_level,
		event_type,
		event_name,
		event_step_number,
		event_step_type,
		event_step_name,
		event_status,
		event_message,
		event_description
	)
	SELECT
		@logger_name, -- например: 'adminlog', 'Airflow'
		@process_guid, -- guid процесса
		@event_level, -- например: 'error', 'info', 'warning'
		@event_type, -- например: 'task_start', 'create_balance', 'create_indexes', 'data_quality_check'
		@event_name, -- например: 'Заполнение витрины ...', 'Расчет баланса'
		@event_step_number, -- 1,2,3,...
		@event_step_type, -- например: 'start load t1', 'create index ix1'
		@event_step_name, -- например: 'Начало загрузки таблицы t1'
		@event_status, -- например: 'failed', 'running', 'skipped', 'succeeded'
		@event_message, -- текст сообщения в произвольной форме, например, сообщение об ошибке
		@event_description -- структурированная информация, например, параметры в формате json, xml

	SELECT @event_log_id = scope_identity()

	IF @event_message_text IS NOT NULL
	BEGIN
		INSERT dbo.event_log_ext(event_log_id, event_message_text)
		SELECT @event_log_id, @event_message_text
	END

	--преобразовывать json в таблицу html
	IF isjson(@event_description) = 1
	BEGIN
		SELECT @html_table = (
			SELECT concat('<tr><td>', J.[Key], '</td><td>', J.Value, '</td></tr>')
			FROM openjson(@event_description) AS J
			FOR XML PATH('')
			)

		SELECT @html_table = replace(replace(@html_table, '&lt;', '<'), '&gt;', '>')
		SELECT @html_table = concat('<table cellspacing="0" border="1" cellpadding="5">',
			'<tr><td><b>Параметр</b></td><td><b>Значение</b></td></tr>', @html_table, '</table>')
	END


	SET @body = CONCAT(
			cast(format(getdate(), 'dd.MM.yyyy HH:mm:ss') AS nvarchar(22)) 
			,' ' , isnull(@event_name, '')
			, isnull(@event_message, ''), '<br>', '<br>'
			, isnull(isnull(@html_table, @event_description), ''), '<br>', '<br>'
			, isnull(@event_message_text, '')
			)

	SET @subject =concat(@event_level, ' - ', @event_name)

	SELECT 
		@recipients = E.emails,
		@copy_recipients = E.copy_recipients,
		@blind_copy_recipients = E.blind_copy_recipients
	--select *
	FROM dbo.Emails AS E
	WHERE E.loggerName = @logger_name --'adminlog'

	IF trim(isnull(@recipients, '')) = ''
	BEGIN
		SELECT 
			@recipients = E.emails,
			@copy_recipients = E.copy_recipients,
			@blind_copy_recipients = E.blind_copy_recipients
	
		FROM dbo.Emails AS E
		WHERE E.loggerName = @logger_name
	END


	IF isnull(@SendEmail, 0) = 1 AND trim(isnull(@recipients, '')) <> '' 
	BEGIN
		/*
		SET @tsql = '     
					EXEC msdb.dbo.sp_send_dbmail  
						@profile_name = ''Default'',  
						@recipients = ''' + @recipients + ''',  
						@body = '''+ @body+''',  
						@body_format=''HTML'', 
						@subject = '''+@subject+''' 
			'; 
			--         select @tsql 
		EXEC (@tsql)
		*/
		EXEC msdb.dbo.sp_send_dbmail  
			@profile_name = 'Default',
			@recipients = @recipients,
			@copy_recipients = @copy_recipients,
			@blind_copy_recipients = @blind_copy_recipients,
			@body = @body,
			@body_format= 'HTML', 
			@subject = @subject
	END

	IF isnull(@SendSlack, 0) = 1
	BEGIN
		SET @toslack_text=concat(
		
		case 
		when @event_level  = 'error' or @event_status = 'failed'
			then ':alarm:'
		when @event_level = 'info' and @event_status = 'succeeded' 
			then ':heavy_check_mark:'
		when @event_level = 'warning' then ':warning:'
			else ':information_source:'
		end, ' '
		
			, '*', @subject, '*', ' '
			,char(13), char(10), ' '
			,cast(format(getdate(), 'dd.MM.yyyy HH:mm:ss') AS nvarchar(22)), ' '
			,char(13), char(10), ' '
			--isnull(@event_name, ''),' ', 
			,isnull(@event_message, '')
			)

		BEGIN TRY
			EXEC dbo.SendToSlack_DwhAdminNotofications
				@text = @toslack_text
		END TRY
		BEGIN CATCH
			IF trim(isnull(@recipients, '')) <> '' 
			BEGIN
				/*
				SET @tsql = '     
							EXEC msdb.dbo.sp_send_dbmail  
								@profile_name = ''Default'',  
								@recipients = ''' + @recipients + ''',  
								@body = ''Cant send to slack'',  
								@body_format=''HTML'', 
								@subject = '''+@subject+''' 
					';
					--         select @tsql 
				EXEC (@tsql) 
				*/
				EXEC msdb.dbo.sp_send_dbmail 
					@recipients = @recipients,
					@copy_recipients = @copy_recipients,
					@blind_copy_recipients = @blind_copy_recipients,
					@body = 'Cant send to slack',  
					@body_format = 'HTML',
					@subject = @subject
			END
		END CATCH
	END

END 

