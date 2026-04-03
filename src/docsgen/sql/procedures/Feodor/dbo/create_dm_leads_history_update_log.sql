

/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/
CREATE     proc [dbo].[create_dm_leads_history_update_log]
as




--with l as (
select * into #l from  [Feodor].[dbo].[dm_leads_history_update_log] a with(nolock)
union all
SELECT [Run_DateAndTime]
      ,'$ JOB '+[Run_Status] +' -> '+ cast(datediff(minute, [Run_DateAndTime], [Finish_DateAndTime])  as nvarchar(10)) 
      ,[Finish_DateAndTime]
      ,case when is_Succeeded=0 then [message] else '' end error
	--  , command
  FROM [Analytics].[dbo].[_v_sysjobhistory]  with(nolock)
  where job_id='835E00EC-7C9E-4C88-BCA2-43BF209BDA0E' and step_id=6
--)
--, max_id as (
select max(id) max_id into #max_id from #l with(nolock)
--)

--, msdb_lh as (
   SELECT
    job.name, 
    job.job_id, 
    job.originating_server, 
    activity.run_requested_date, 
	activity.last_executed_step_id,
	activity.last_executed_step_date--,

 --   DATEDIFF( minute, activity.last_executed_step_date, GETDATE() ) as StepDuration
 into #msdb_lh
FROM 
    msdb.dbo.sysjobs_view job with(nolock)
JOIN --select top 100 * from  msdb.dbo.sysjobactivity activity with(nolock) where job_id='835E00EC-7C9E-4C88-BCA2-43BF209BDA0E'
    msdb.dbo.sysjobactivity activity with(nolock)
ON 
    job.job_id = activity.job_id
JOIN
    msdb.dbo.syssessions sess with(nolock)
ON
    sess.session_id = activity.session_id
JOIN
(
    SELECT
        MAX( agent_start_date ) AS max_agent_start_date
	--	select *
    FROM
        msdb.dbo.syssessions  with(nolock)
) sess_max 
ON
    sess.agent_start_date = sess_max.max_agent_start_date
WHERE 
   job.job_id='835E00EC-7C9E-4C88-BCA2-43BF209BDA0E' and run_requested_date IS NOT NULL AND stop_execution_date IS NULL --and 


 --  )

 --select * from #l
 --order by id desc

;with v as (

SELECT top 100000000 
       case when l.param='start' then l.[id] end [start]
      ,l.[param]
      ,l.[dt]
   --   ,l.[value]
	  ,datediff(minute,  l.dt , lead(l.[dt]) over(partition by l.[id] order by l.dt) ) [lag]
	  ,case when l.param='start' and l2.dt is not null then   cast(datediff(minute,  l.dt, l2.dt)  as nvarchar(10)) 
	        when l.param='start' and l2.dt is null and l.id=max_id.max_id and (select top 1 last_executed_step_id from #msdb_lh where last_executed_step_id=6 ) is not null then cast(datediff(minute, l.dt, getdate()) as nvarchar(10))+'...running'
	        when l.param='start' and l2.dt is null and l.id<>max_id.max_id then 'fail'
			when l.param<>'start' then '' end  [start - end]
	  ,l1.value as depth
	  ,(select top 1 last_executed_step_id from #msdb_lh  ) last_executed_step_id
	  ,case when left(l.param, 1) =  '$' then cast(l.value  as varchar(max)) end 'Error_info'
  FROM  #l l
  left join #l l1 on l1.id=l.id and l1.param='depth_id'
  left join #l l2 on l2.id=l.id and l2.param='end'
  cross join #max_id max_id
  where l.id is not null and l.param<>'depth_id'
  order by l.id desc, l.dt
  )

  select * from v with(nolock)

--select * from v_dm_leads_history_update_log with(nolock)
--where dt>=getdate()-1
--
--select * from dm_leads_history_update_log where id is null


