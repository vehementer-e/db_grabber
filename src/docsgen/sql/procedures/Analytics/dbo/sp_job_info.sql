/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/
CREATE proc [dbo].[sp_job_info]  @is_json int=0 , @detailed int =0

as
 
return

/*
if @is_json=1
begin

select   (
   select * from (
   SELECT
    j.name AS job_name,
    ja.start_execution_date,      
	isnull(ja.last_executed_step_date , ja.start_execution_date) last_run, 
    ISNULL(last_executed_step_id,0)+1 AS current_executed_step_id,
    Js.step_name,
   replace( 
   replace( 
   replace( 
   Js.command
   , '/', '') 
   , '\', '') 
   , '"', '') 
   command
FROM msdb.dbo.sysjobactivity ja 
LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
JOIN msdb.dbo.sysjobsteps js
    ON ja.job_id = js.job_id
    AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
WHERE
  ja.session_id = (
    SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY agent_start_date DESC
  )
AND start_execution_date is not null
AND stop_execution_date is null
--and j.name='REPORTS. Factor_Analysis, every 16 min from 7:30 till 23:59'
)x
order by  last_run desc
for json auto
) x

return

end

   if @detailed=0
		 
--    SELECT
--    ja.job_id,
--    j.name AS job_name,
--    ja.start_execution_date,      
--    ISNULL(last_executed_step_id,0)+1 AS current_executed_step_id,
--    Js.step_name,
--    Js.command ,
--	isnull(ja.last_executed_step_date , ja.start_execution_date) last_run
----	into #t1
--FROM msdb.dbo.sysjobactivity ja 
--LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
--JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
--JOIN msdb.dbo.sysjobsteps js
--    ON ja.job_id = js.job_id
--    AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
--WHERE
--  ja.session_id = (
--    SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY agent_start_date DESC
--  )
--AND start_execution_date is not null
--AND stop_execution_date is null
----and j.name='REPORTS. Factor_Analysis, every 16 min from 7:30 till 23:59'
--order by  last_run desc


select a.*,
   'exec masdb.dbo.sp_stop_job '''+a.job_name+'''' stop_sql

from [v_Запущенные джобы]	  a
order by job_name



if @detailed=1
begin
drop table if exists 	   #h
select * into #h from  query_log_view  where log_datetime=(select max(log_datetime)   from query_log_view )


select a.*, b.sql_text
,
   'exec masdb.dbo.sp_stop_job '''+a.job_name+'''' stop_sql

from [v_Запущенные джобы]	  a
left join 	#h b on master.dbo.fn_varbintohexstr(a.job_id)  =b.job_id_hexstr	  and a.current_executed_step_id=b.step_id
						 order by job_name
  end




end
*/