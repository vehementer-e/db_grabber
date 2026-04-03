CREATE   proc [dbo].[log_email_]
@text nvarchar(max) = 'message',
@recepients nvarchar(max)
as
begin

--drop table if exists dbo.log_email




--select getdate() dt, cast('' as nvarchar(max)) text, cast('' as nvarchar(max)) recepients into dbo.log_email



--select * from log_email
--delete from log_email


insert into log_emails
select getdate(), @text, @recepients


--exec [dbo].[log_email] 'fj', 'p.ilin@carmoney.ru'

end

