
create       proc [dbo].[notify_each_1_min] 
@debug int = 0
as 

begin

if datepart(hour, getdate()) between 1 and 5
return

set nocount off;

 

drop table if exists ##monitoring_each_1_min;
CREATE TABLE ##monitoring_each_1_min(
	[Текст]   [nvarchar](max) NOT NULL,
	[send_to] [nvarchar](max) NOT NULL,
	[subject] [nvarchar](max) NOT NULL
)
 
 


insert into ##monitoring_each_1_min
exec [notify_job_fail]
 

--select * from ##monitoring_each_15_min

drop table if exists #to_send
select *, newid() id into #to_send from ##monitoring_each_1_min
--where subject='Займы без привязки к каналу в ДВХ'
 
declare @sql nvarchar(max) =
'
declare @Текст nvarchar(max) 
declare @send_to nvarchar(max) 
declare @subject nvarchar(max) 



' + (
select STRING_AGG( sql, ';')
from (
select cast('select @Текст = Текст, @send_to='+case when @debug=1 then '''P.Ilin@techmoney.ru''' else 'send_to' end +', @subject=subject from #to_send where id='''+cast(id as nvarchar(max))+''' exec log_email @subject, @send_to, @Текст ; 
' as nvarchar(max)) sql , * from #to_send
) x
)

--select @sql
exec (@sql)

--select top 100 * from log_emails_big
--order by 1 desc
  
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------
  ----------------------------------------------------------------------------------




end
