

CREATE   proc [dbo].[Проверка сообщений для доставки]

as
begin


waitfor delay '00:00:02'


drop table if exists #log_emails 
begin tran
select dt, text, recepients,  id, letter into #log_emails from log_emails
delete from log_emails

declare @letter_id uniqueidentifier = newid()
insert into log_emails_big
select dt, text, recepients,  id, @letter_id id_letter, getdate(), letter from #log_emails

--alter table log_emails_big
--add id_letter uniqueidentifier
--alter table log_emails_big
--add sending_started datetime2
--alter table log_emails_big
--add letter nvarchar(max)
--alter table log_emails
--add letter nvarchar(max)

--select * from log_emails_big
--order by dt
--select * from log_emails 


select dt, text, recepients, --format(dt, 'dd-MMM HH:mm:ss')+' '+
text  text_message, letter from #log_emails
order by dt
--select * from log_emails
--select * from log_emails_big

commit tran



end


