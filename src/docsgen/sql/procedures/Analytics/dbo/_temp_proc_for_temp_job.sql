CREATE   proc _temp_proc_for_temp_job
as

--exec msdb.dbo.sp_stop_job  @job_name= 'Analytics._temp_proc_for_temp_job'--STOP 
--exec msdb.dbo.sp_start_job  @job_name= 'Analytics._temp_proc_for_temp_job', @step_name = 'Analytics._temp_proc_for_temp_job'

--sp_create_job 'Analytics._temp_proc_for_temp_job', '_temp_proc_for_temp_job', '0'

exec [_product_report_balance_creation]
exec log_email  '_temp_proc_for_temp_job completed!'


return

drop table if exists #temp_lead_stats
SELECT 
    lead_id AS id, 
    SUM(speaking_time) AS total_time
INTO #temp_lead_stats
FROM v_lead_call
where speaking_time is not null
GROUP BY lead_id; 
  




UPDATE target
SET target.speaking_time = src.total_time
FROM analytics.dbo.v_lead2 AS target
INNER JOIN #temp_lead_stats AS src ON target.id = src.id;

-- Удаляем временную таблицу после использования
DROP TABLE #temp_lead_stats;


exec log_email  '_temp_proc_for_temp_job completed!'
