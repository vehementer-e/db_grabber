CREATE   proc [dbo].[log_email]
@text nvarchar(max) = 'message',
@recepients nvarchar(max) = 'p.ilin@smarthorizon.ru',
@letter nvarchar(max) = ''	,
@html int = 0
as
begin

--drop table if exists dbo.log_email

--delete from log_emails_big


set @text = trim(REPLACE(REPLACE(@text, CHAR(13), ''), CHAR(10), ''))


--select getdate() dt, cast('' as nvarchar(max)) text, cast('' as nvarchar(max)) recepients into dbo.log_email



--select * from log_emails
--delete from log_email



exec msdb.dbo.sp_send_dbmail   
    @profile_name = null,  
    @recipients = @recepients,  
    @body = @letter,  
    @subject = @text


insert into log_emails_dwh
select getdate(), @text, @recepients, NEWID() id, @letter
--select top 0 * into log_emails_dwh from log_emails

--exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'C5B773C4-EA09-494E-A524-0B2EEF82DED5'
--exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '7DD42565-32F4-4FCB-B08F-A648EFA48CD0'
--
----
--exec [dbo].[log_email] 'p.ilin@techmoney.ru', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '2', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '3', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '4', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--exec [dbo].[log_email] '5', 'p.ilin@techmoney.ru'
--select * from  dbo.log_emails_big order by 1
end

