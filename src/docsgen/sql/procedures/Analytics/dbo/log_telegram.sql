
CREATE     proc [dbo].[log_telegram]
@text nvarchar(max) = 'message',
@recepients nvarchar(max) = '-420003757' , 
@isRocket int =0
as
begin

drop table if exists #tg
--drop table if exists dbo.log_telegrams
--select getdate() dt, cast('message' as nvarchar(max))  text, '-420003757' recepients, cast(NEWID() as nvarchar(36)) id into dbo.log_telegrams

--ALTER TABLE log_telegrams_long add      isRocket tinyint
select getdate() dt, @text text, @recepients recepients, NEWID() id, @isRocket isRocket into #tg

begin tran
insert into log_telegrams (dt, text, recepients, id,  isRocket) 
select dt, text, recepients, id , isRocket from #tg

--exec sp_SelectTable 'log_telegrams'


insert into log_telegrams_long  (dt, text, recepients, id, sending_date, isRocket) 
select dt,  text, recepients, id, getdate() sending_date, isRocket from #tg

commit tran

--alter table log_telegrams_long add tgid bigint
--alter table log_telegrams_long add  isRocket tinyint
--alter table log_telegrams  add  isRocket tinyint
end
--exec [log_telegram] '👩'
--exec [log_telegram] 'Как дела?'
--exec [log_telegram] 'Что делаешь
--
--
--
--
--'

