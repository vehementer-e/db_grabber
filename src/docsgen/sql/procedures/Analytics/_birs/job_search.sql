
CREATE     proc [_birs].[job_search]
@search_string nvarchar(max) = null

as
begin

drop table if exists #t1

SELECT TOP 0 
 [Job_Name]
,[job_id]
,[job_enabled]
,[start_step_id]
,[step_id]
,[step_name]
,[subsystem]
,[command]
,[On_Success]
,[On_fail]
,[schedule_id]
,[schedule_name]
, [schedule_enabled]
,   [updateSql] 
,   [addSql] 
,   [stopSql] 
,   [startSql] 

into #t1
FROM jobs
order by Job_Name, step_id
 

if @search_string is not null

insert into #t1

SELECT 
 [Job_Name]
,[job_id]
,[job_enabled]
,[start_step_id]
,[step_id]
,[step_name]
,[subsystem]
,[command]
,[On_Success]
,[On_fail]
,[schedule_id]
,[schedule_name]
, [schedule_enabled]  
,   [updateSql] 
,   [addSql] 
,   [stopSql] 
,   [startSql] 


FROM jobs

where [Job_Name] like '%'+@search_string+'%'
or [command] like '%'+@search_string+'%'
or [step_name] like '%'+@search_string+'%'
order by Job_Name, step_id

if @search_string is null

insert into #t1

SELECT 
 [Job_Name]
,[job_id]
,[job_enabled]
,[start_step_id]
,[step_id]
,[step_name]
,[subsystem]
,[command]
,[On_Success]
,[On_fail]
,[schedule_id]
,[schedule_name]
, [schedule_enabled]   
,   [updateSql] 
,   [addSql] 
,   [stopSql] 
,   [startSql] 

									FROM jobs

order by Job_Name, step_id

select*from #t1


end