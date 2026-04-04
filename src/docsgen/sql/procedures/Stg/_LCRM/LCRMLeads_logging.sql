

-- Usage: запуск процедуры с параметрами
-- EXEC _LCRM.LCRMLeads_logging
--      @action = 0,
--      @message = 'info',
--      @process = 'procedure';
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   PROC _LCRM.LCRMLeads_logging
@action int = 0,
@message nvarchar(200) ='info',
@process nvarchar(200) ='procedure'
as
begin

--Declare @message nvarchar(200)

exec logdb.dbo.[LogAndSendMailToAdmin] @process,'Info',@message, ''


		--Set @message = N'[ClearLCRMLeads] procedure started' 

		select @message

		--2023-03-24 А.Никитин. комментарю, т.к. возникает ошибка
		/*
		ErrorMessage: Отправка сообщения в lcrm-backup-restore-dwh-monitoring канал завершилась с ошибкой PHP 
		Fatal error:  Maximum execution time of 60 seconds exceeded in C:\inetpub\wwwroot\RabbitMQSender\vendor\php-amqplib\php-amqplib\PhpAmqpLib\Wire\IO\StreamIO.php on line 461 ,
		код ошибки 500 
		ErrorNumber: 51000   ErrorSEVERITY: 16   ErrorState: 1   
		ErrorProcedure: dbo.Send_to_slack_message_by_COMC   
		Error_line: 77 
		*/
		--exec [dwh-ex].bot.dbo.[Send_to_slack_message] 'lcrm-backup-restore-dwh-monitoring',
		--											  @message 

end
