
CREATE   procedure monitoring.[Jobs_NotificationStatus]
as
begin
	drop table if exists #t_jobsNotificationInfo
	if 	(select count(1) from msdb.dbo.sysjobs
			where enabled != 0 
				and notify_level_email != 2
				and name not like 'TEST. %'
				and name not like 'SSIS Server Maintenance%'
				and name not like 'syspolicy_purge_history') > 0
	------------------------------------------------------------------
			select sj.name
				,isnull(sp.name, 'Логин находится в группе')									   as Job_owner
				,sj.date_created																   as date_created
				,isnull(cast(jsch.Schedule_Enabled as nvarchar(25)), 'Расписание не установлено')  as Schedule_Enabled
			into #t_jobsNotificationInfo 
			from msdb.dbo.sysjobs sj
			left join sys.syslogins sp on sj.owner_sid = sp.sid
			left join (select jsch.job_id, max(sch.[enabled]) as Schedule_Enabled from msdb.dbo.sysjobschedules jsch
						join msdb.dbo.sysschedules  sch on jsch.schedule_id = sch.schedule_id
						group by jsch.job_id) jsch on jsch.job_id = sj.job_id
			where sj.enabled != 0 
				and sj.notify_level_email != 2
				and sj.name not like 'TEST. %'
				and sj.name not like 'SSIS Server Maintenance%'
				and sj.name not like 'syspolicy_purge_history'

			DECLARE @tableHTML NVARCHAR(MAX) ;

			SET @tableHTML =

			N'<H1>Задания с выключенными оповещениями на c2-vsr-dwh2</H1>' +
			N'<table border="1">' +
			N'<tr><th>name</th><th>Job_owner</th><th>date_created</th><th>Schedule_Enabled</th></tr>' +
			CAST ( ( SELECT td = "name"           
			,               ''                                      
			,               td = Job_owner                     
			,               ''                                      
			,               td = date_created   
			,               ''                                      
			,               td = Schedule_Enabled 

			from #t_jobsNotificationInfo
			FOR XML PATH('tr'), TYPE
			) AS NVARCHAR(MAX) ) +
			N'</table>' ;

				  EXEC msdb.dbo.sp_send_dbmail @recipients   = 'dwh112@carmoney.ru'
				  ,                            @subject      = 'Задания с выключенными оповещениями на C3-DWH-DB01.carm.corp'
				  ,                            @body         = @tableHTML
				  ,                            @body_format  = 'HTML';
end