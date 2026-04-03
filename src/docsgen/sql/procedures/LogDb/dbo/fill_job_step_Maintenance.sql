create    procedure dbo.fill_job_step_Maintenance
as
begin

--select top(1) * from [job_step_history_analysis]

drop table if exists #tJobs
 select 
	t.Job
	,t.Step
	,t.[Start Time]
	,[End_time] = dateadd(ss, [Duration In Seconds], t.[Start Time])
	,t.[Step Order]
	,t.[Duration In Seconds]
	,t.[Job Outcome]
	,t.[Error Message]
	into #tJobs
  FROM [dbo].[job_step_history_analysis] t
  where t.Job = 'Maintenance. Shrink_Log_Files daily'

 drop table if exists #tJobs_data

 select 
	t.Job
	,t.Step
	,[Start Time] = t.[Start Time]
	,t.[Step Order]
	,t.[Duration In Seconds]
	,t.[Job Outcome]
	,t.[Error Message]
	,[next_job_Start_Time] = next_job.[Start Time]
	,GroupID =cast(null as smallint)
	,job_start_time = cast(null as datetime)
	,JobId = cast(null as uniqueidentifier)
	,JobName =cast(null as nvarchar(255))
	into #tJobs_data
  FROM #tJobs t
  outer apply
  (
	select
		Job,
		[Start Time] = min([Start Time])
	from #tJobs next_job
	where next_job.[Step Order] = 0
		and next_job.Job=t.Job
		and next_job.[Start Time]>t.[Start Time]
	group by job
  ) next_job 
  --where t.[Start Time] between '2023-09-16 01:10:00.000' and '2023-09-18 01:20:00.000'
  create clustered index cix on #tJobs_data(JobId)
update t
	set GroupID = [group].GroupID
		,job_start_time = [group].JobStartTime
		,JobId = cast(hashbytes('SHA2_256', concat(t.Job ,'|', JobStartTime)) as uniqueidentifier)
		,JobName = concat(t.Job ,'|', format(JobStartTime, 'yyyy-MM-dd HH:mm:ss'))
 from #tJobs_data t
	inner join 
	(
		select 
			job,
			next_job_Start_Time = isnull(next_job_Start_Time, getdate()),
			JobStartTime = min([Start Time]),
			GroupID = row_number() over(partition by job order by next_job_Start_Time)
		from #tJobs_data 
		where [Step Order] = 0
		group by job,
			next_job_Start_Time
	) [group] on [group].job  = t.job
		and t.[Start Time]>=[group].JobStartTime 
			and  t.[Start Time]<[group].next_job_Start_Time
	
	--select 
	--	 JobId
	--	,Job
	--  ,JobName
	--	,[Job start time] = job_start_time
	--	,[Step Start Time]  = [Start Time]
	--	,[Step name] = t.Step
	--	,[Step end Time]  = dateadd(second,[Duration In Seconds], [Start Time])
	--	,[Duration In Seconds]
	--	,[Step Order]
	--	,[Job Outcome]
	--	,[Error Message]
	--into [dbo].[job_step_Maintenance]
	--from #tJobs_data
if exists(select top(1) 1 from #tJobs_data)
begin
	--truncate table  dbo.[job_step_Maintenance]
	delete t from		dbo.[job_step_Maintenance] t
	where exists(select top(1) 1 from #tJobs_data s where s.JobId = t.JobId
	)
	
	insert into [dbo].[job_step_Maintenance]
	(
	[JobId]
	, [Job]
	, JobName
	, [Job start time]
	, [Step name]
	, [Step Start Time]
	, [Step end Time]
	, [Duration In Seconds]
	, [Step Order]
	, [Job Outcome]
	, [Error Message]
	)
	select 
		 JobId
		,Job
		,JobName
		,[Job start time] = job_start_time
		,[Step name] = Step
		,[Step Start Time]  = [Start Time]
		,[Step end Time]  = dateadd(second,[Duration In Seconds], [Start Time])
		,[Duration In Seconds]
		,[Step Order]
		,[Job Outcome]
		,[Error Message]
	from #tJobs_data
end
end
