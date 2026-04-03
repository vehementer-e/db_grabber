--exec [dbo].[dev_create_job]
CREATE   proc [dbo].[dev_create_job]
as


begin
  			  
--EXEC msdb.dbo.sp_start_job @job_name =  'Analytics._birs Детализация для отчета по заявкам Excel GD'
--EXEC msdb.dbo.sp_delete_job @job_name =  'Analytics._birs КВ партнерам по итогам месяца'

declare @job_name_  nvarchar(max) =   N'Analytics._birs cost_of_calls_creation 9:00'-- + format(getdate(), 'yyyy-MM-dd HH:mm:ss')
declare @sql nvarchar(max) =  replace( N' 
	
exec _birs.[cost_of_calls_creation]

'

     , '''', '''''' )
declare @enabled nvarchar(max) = '1' 
declare @start nvarchar(max) = '90000' 
declare @task nvarchar(max)  



= '

USE [msdb]

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 13.04.2023 21:41:21 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N''[Uncategorized (Local)]'' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N''JOB'', @type=N''LOCAL'', @name=N''[Uncategorized (Local)]''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'''+@job_name_ +''', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N''No description available.'', 
		@category_name=N''[Uncategorized (Local)]'', 
		@owner_login_name=N''CM\P.Ilin'', 
		@notify_email_operator_name=N''analytics alert operator'', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback


EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'''+@job_name_+''' , 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command='''+@sql+''', 
		@database_name=N''Analytics'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback



EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'''+'step2'+''' , 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command='''+'return'+''', 
		@database_name=N''Analytics'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'''+'step3'+''' , 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N''TSQL'', 
		@command='''+'return'+''', 
		@database_name=N''Analytics'', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback





EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'''+@job_name_+''', 
		@enabled='+@enabled+', 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20220617, 
		@active_end_date=99991231, 
		@active_start_time='+@start+', 
		@active_end_time=235959

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N''(local)''
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
--GO


'

print (@task)
--return
exec (@task)
select 'Джоб создан' result,  @job_name_ JobName, @sql Command, 'EXEC msdb.dbo.sp_start_job @job_name =  '''+@job_name_+ '''' START_JOB_SCRIPT
--EXEC msdb.dbo.sp_start_job @job_name =  @job_name_
--exec Analytics.dbo.Запросы @job_name_

--EXEC msdb.dbo.sp_stop_job 'temp analytics job'

--EXEC msdb.dbo.sp_delete_job @job_name =  'Analytics._files pay_gateway_rates_calculation'
--
--
--go
----exec Analytics.dbo.Запросы'REPORTS. each 1h from 9:00 till 23:00'
--
--exec Analytics.dbo.Запросы'temp analytics job'
--exec Analytics.dbo.Джобы 0, 1


 



end