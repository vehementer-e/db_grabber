CREATE PROCEDURE [dbo].[sup_kill_session]
	@CurTask varchar(1024)
AS

DENY CONNECT SQL TO [loader]
	ALTER LOGIN [loader] DISABLE
DENY CONNECT SQL TO [ReportViewer]
	ALTER LOGIN [ReportViewer] DISABLE

DENY CONNECT SQL TO RMQLoader
	ALTER LOGIN RMQLoader DISABLE
	
begin try
	
IF OBJECT_ID('tempdb..#UDT_KILL_PROCESSES') IS NOT NULL DROP TABLE #UDT_KILL_PROCESSES

SELECT r.session_id,r.login_time, r.host_name, r.program_name, r.login_name,
         r.status, r.last_request_start_time,t.text,getdate() AS OP_DATE,
         s.blocked,
    --Определяем можем ли убить запрос от этого пользователя
	case when r.login_name NOT IN ('CM\sqlservice', 'CM\Shubkin_A_N', 'CM\Sabanin_A_A') /*сесси кого оставляем*/
				/*Кого убиваем*/
				AND (
				r.login_name LIKE 'CM\%' OR
				r.login_name not like 'CM\' OR
				r.login_name IN (NULL)
				) THEN 1 ELSE 0 END AS killsession
         
  INTO #TMP_UDT_KILL_PROCESSES  
  FROM   sys.dm_exec_sessions  r
      INNER JOIN sys.sysprocesses s ON s.spid = r.session_id
    CROSS APPLY sys.dm_exec_sql_text (s.sql_handle) t
    WHERE r.session_id > 50 AND r.session_id <> @@spid
	
		
--select * from #TMP_UDT_KILL_PROCESSES

--надо подумать куда сохраить запишем на всякий случай, кого убиваем
/*
SELECT GETDATE() AS date_time,
		'dwh.dbo.p_sup_kill_session' AS name,
		login_name AS [system_user],
		'kill' AS state_name,
		session_id as err_line,
		CONCAT('[HOST]=',[HOST_NAME],';[login_time]=',CONVERT(VARCHAR,login_time,120),';[last_request]=',CONVERT(VARCHAR,last_request_start_time,120),';[program_name]=', [program_name],';[blocked]=', [blocked],';[killsession]=', [killsession]) AS err_object,
		[text] AS err_message
FROM  #TMP_UDT_KILL_PROCESSES
where killsession = 1
*/
--



DECLARE @sid AS int
DECLARE kill_cursor CURSOR LOCAL FOR SELECT DISTINCT r.session_id FROM #TMP_UDT_KILL_PROCESSES r WHERE r.killsession=1

OPEN kill_cursor
DECLARE @tablename sysname
FETCH NEXT FROM kill_cursor INTO @sid
WHILE (@@FETCH_STATUS <> -1) BEGIN

	IF (SELECT count(1) FROM sys.sysprocesses WHERE spid=@sid)>0
	begin
		DECLARE @sql AS varchar(1000)  
		SET @sql='kill ' + cast(@sid AS varchar(3))
		EXEC( @sql)
	end

	FETCH NEXT FROM kill_cursor INTO @sid
END
CLOSE kill_cursor
DEALLOCATE kill_cursor
  	
	/*Останавливаем задания*/

	if object_id('tempdb..#CurrentJobs') is not null
		drop table #CurrentJobs
	create table #CurrentJobs 
		(
		[Job ID] uniqueidentifier,
		[Last Run Date] varchar(255),
		[Last Run Time] varchar(255),
		[Next Run Date] varchar(255),
		[Next Run Time] varchar(255),
		[Next Run Schedule ID] varchar(255),
		[Requested To Run] varchar(255),
		[Request Source] varchar(255),
		[Request Source ID] varchar(255),
		[Running] varchar(255),
		[Current Step] varchar(255),
		[Current Retry Attempt] varchar(255),
		[State] varchar(255)
		);
	insert into #CurrentJobs
			EXECUTE master.dbo.xp_sqlagent_enum_jobs 1,'';


	

declare job_cursor cursor local for 
	select sj.name as  JobName, sj.job_id
		from 
		#CurrentJobs cj
		 join msdb.dbo.sysjobs sj
			on cj.[Job ID]= sj.job_id
		and Running = 1 
		and sj.name != @CurTask

DECLARE @JobName sysname, @job_id uniqueidentifier

OPEN job_cursor

FETCH NEXT FROM job_cursor INTO @JobName, @job_id
WHILE (@@FETCH_STATUS <> -1) 
BEGIN
	
	
	EXEC msdb.dbo.sp_stop_job  @JobName
	
	FETCH NEXT FROM job_cursor INTO @JobName, @job_id
END
CLOSE job_cursor
DEALLOCATE job_cursor
	

end try      
begin catch
	
	;throw

end catch

