create   proc dbo.[Проверка телеграмм для доставки]
as
begin
drop table if exists #t1
if not exists (select top 1 id from log_telegrams) return


insert into log_telegrams_long 
select dt, text, recepients, id, getdate() sending_date from log_telegrams

DECLARE @json NVARCHAR(Max)
SET @json = (SELECT * FROM log_telegrams FOR JSON PATH, ROOT('data'))
SELECT value
FROM OPENJSON(@json,'$.data');



--select dt, text, recepients, id, getdate() sending_date into log_telegrams_long from log_telegrams


end