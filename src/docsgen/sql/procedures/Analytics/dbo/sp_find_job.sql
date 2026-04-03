CREATE proc [dbo].[sp_find_job] @q nvarchar(max) as
declare @details bigint = case when right(@q, 1) = ' '   then 1 else 0 end 

set @q = TRIM(@q)
SELECT j1.job_enabled, Job_Name, step_id, step_name, command , job_id, '\' [\],  stopSql + '
--'+ startSql StopstartSql , updateSql, addSql,     enableSql
into #t1
FROM jobs j1
WHERE j1.Job_Name LIKE '%' + @q + '%'
   OR j1.command LIKE '%' + @q + '%'
 --  OR EXISTS (
 --      SELECT 1
 --      FROM jobs j2
 --      WHERE j2.command LIKE '%' + CAST(j1.job_id AS NVARCHAR(50)) + '%'  -- Проверка наличия job_id в командах
 --  )
   order by 2, 3 
  
   
   if @details = 0 begin  select * from #t1  
   order by 2, 3 
   
   return end 

   select job_id, step_id, max(Finished) Finished into #statToday from jobh with(nolock)
   where created>=cast( getdate()  as date)  and is_Succeeded=1
   group by job_id, step_id

   select a.*, b.current_executed_step_id, c.Finished [TODAY SUCCES???] , b.last_run, b.start_execution_date, '\' [\],  a.StopstartSql , a.updateSql, a.addSql,    a.enableSql   from #t1 a
   left join [v_Запущенные джобы] b on a.job_id=b.job_id
   left join #statToday c on c.job_id=a.job_id and c.step_id=a.step_id
   order by 2,3

   declare @job1    varchar(max) =   (select top 1 Job_Name from #t1)
   exec sp_message
   exec  sp_query_log @job1

