

CREATE       proc
--exec [dbo].[get_monitoring_letter_each_15_min] 1

[dbo].[get_monitoring_letter_each_15_min] 
@debug int = 0
as 

begin

if datepart(hour, getdate()) between 2 and 6
return

set nocount off;



if ( select lastUpdateTGsender from config )<dateadd(minute, -10, getdate())
begin
declare @lastUpdateTGsender   varchar(max) = 'lastUpdateTGsender <dateadd(minute, -10, getdate())'+  format( (select lastUpdateTGsender from config ), 'dd.MM HH:mm')
exec log_email @lastUpdateTGsender
end


if ( select lastUpdateTGsender from config )<dateadd(minute, -1, getdate()) and exists(select top 1 * from log_telegrams where text<>'')
begin
declare @lastUpdateTGsender1   varchar(max) = 'lastUpdateTGsender MESSAGE QUEUE'+  format( (select lastUpdateTGsender from config ), 'dd.MM HH:mm')
exec log_email @lastUpdateTGsender1
end


drop table if exists ##monitoring_each_15_min;
CREATE TABLE ##monitoring_each_15_min(
	[Текст]   [nvarchar](max) NOT NULL,
	[send_to] [nvarchar](max) NOT NULL,
	[subject] [nvarchar](max) NOT NULL
)
 
insert into ##monitoring_each_15_min
select

[Текст],
send_to = [send_to] ,
[subject] = 'last update - '+format(LAST_update , 'dd.MMM.yyyy HH:mm') 
from (
select top 1 текст = 'ТГ бот не работает' , lastUpdatePythonAnalyticsTG LAST_update  from config where lastUpdatePythonAnalyticsTG<= dateadd(minute, -10, getdate())
) a1 
, 
(select 'p.ilin@techmoney.ru' [send_to]  ) a2 where Текст is not null
 	   
insert into ##monitoring_each_15_min
select

[Текст],
send_to = [send_to] ,
[subject] = 'last update - '+format(LAST_update , 'dd.MMM.yyyy HH:mm') 
from (
select top 1 текст = 'Отчетный бот не работает' , lastUpdatePythonAnalytics LAST_update  from config where lastUpdatePythonAnalytics<= dateadd(minute, -10, getdate())
) a1 
, 
(select 'p.ilin@techmoney.ru' [send_to]  ) a2 where Текст is not null
 
  
drop table if exists #t2
select command, created, startTime,  'delete from python_commands where id='''+cast(id as nvarchar(36)) +'''' delete_sql into #t2  from python_commands where created between cast(getdate() as date) and dateadd(minute, -10, getdate()) and startTime is null
union all
select command, created, startTime, 'delete from python_commands where id='''+cast(id as nvarchar(36)) +'''' delete_sql from python_commands where startTime between cast(getdate() as date) and dateadd(minute, -10, getdate()) and endTime is null

if exists (select top 1 * from #t2)
begin

declare @html  nvarchar(max)
exec spQueryToHtmlTable 'select * from #t2' , default,  @html output	   
--select @html

exec msdb.dbo.sp_send_dbmail   
    @profile_name = null,  
    @recipients = 'p.ilin@techmoney.ru',  
    @body = @html,  
    @body_format = 'html',  
    @subject = 'Зависшие PYTHON команды'	
end

 if exists (
select * from [v_Запущенные джобы]
where job_name='report. CalculateOnlineDashBoard every 10min from 0 till 24' and 
start_execution_date<=dateadd(minute, -30, getdate())
)
 exec msdb.dbo.sp_send_dbmail   
    @profile_name = null,  
    @recipients = 'p.ilin@techmoney.ru',  
   @subject = 'report. CalculateOnlineDashBoard every 10min from 0 till 24 долго выполняется'




--insert into ##monitoring_each_15_min
--exec [notify_jobFail]


--insert into ##monitoring_each_15_min
--exec analytics.dbo.[Проверка превышения пск]

--insert into ##monitoring_each_15_min
--exec analytics.dbo.[Проверка соотвествия ставок инстоллмент]

insert into ##monitoring_each_15_min
exec analytics.dbo.[Проверка наличия заявок по RBP] 


--select * from ##monitoring_each_15_min

drop table if exists #to_send
select *, newid() id into #to_send from ##monitoring_each_15_min
--where subject='Займы без привязки к каналу в ДВХ'

--select * from #to_send
--

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
