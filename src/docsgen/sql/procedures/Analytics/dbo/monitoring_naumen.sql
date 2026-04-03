create    proc monitoring_naumen
as
begin
drop table if exists #t343434344
select   a.projectid ,   [Уведомление, мин], [Название проекта для отчета], ЧасСтартаКампанииПоМск, ЧасОкончанияКампанииПоМск	 into #t343434344
from _gsheets.[v_dic_Проекты TTC] a  where [Уведомление, мин] is not null	 
--select * from #t343434344


--select * from log_emails_dwh where text like 'no case%' order by 1 and recepients <>'p.ilin@smarthorizon.ru'

   declare @sql nvarchar(max) =    (

select   string_agg(	'if not exists (select top 1 uuid from v_case where    projectuuid='''+projectid+''' and creationdate>='''+format(	dateadd(MINUTE, -[Уведомление, мин],  getdate()) , 'yyyy-MM-dd HH:mm:ss' ) +''') and   (datepart(hour, getdate())+0.0+datepart(minute, getdate())/60.0 between ('+format(ЧасСтартаКампанииПоМск , '0.000')+ '+' + format([Уведомление, мин]/60.0  , '0.000') +')' + ' and ' + format(ЧасОкончанияКампанииПоМск , '0.000') +') exec log_email ''NO CASE IN '+[Название проекта для отчета]+' PROJECT= '+projectid+''',
''p.ilin@smarthorizon.ru; davydova@carmoney.ru; v.danilov@techmoney.ru''
--''p.ilin@smarthorizon.ru''
, ''https://ncc.cm.carmoney.ru/published?ObjectsList.sort_column=creationDate&ObjectsList.sort_dir=asc&uuid='+projectid+'&CallCasesTab&objectslist_pn=0''

' , '
') from    #t343434344




)


 exec (@sql)
--select  @sql



end



--select * from jobs
--order by Job_Name, step_id

--exec msdb.dbo.sp_update_jobstep @job_name= 'Analytics._monitoring each 15 min'
--		,  @step_id = 1
--		, @command = 'exec [dbo].[get_monitoring_letter_each_15_min]
		
--	exec	_monitoring.naumen_check
--		'