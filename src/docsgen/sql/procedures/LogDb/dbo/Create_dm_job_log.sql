
-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2021-08-24
-- Description:	Create job log dm
-- exec [dbo].[Create_dm_job_log] 
-- =============================================
CREATE        PROCEDURE [dbo].[Create_dm_job_log] 	
AS
BEGIN
	SET NOCOUNT ON;
begin try
	drop table if exists #tJobs
	select top(0) 
		[Category], 
		[Job], 
		[Step], 
		[Step Order], 
		[Start Time], 
		[Job Outcome], 
		[Duration In Seconds], 
		[Min Duration In Seconds], 
		[Max Duration In Seconds], 
		[Average Duration In Seconds],
		--[Pct Increase], 
		[Error Message]
	into #tJobs
	from [msdb].[dbo].[job_step_history_analysis]
	insert into #tJobs ([Category]
		, [Job], [Step], [Step Order], [Start Time], [Job Outcome], [Duration In Seconds], [Min Duration In Seconds], [Max Duration In Seconds], [Average Duration In Seconds], [Error Message])
	select [Category], [Job], [Step], [Step Order], [Start Time], [Job Outcome], [Duration In Seconds]
	, [Min Duration In Seconds], [Max Duration In Seconds], [Average Duration In Seconds], [Error Message] 
		from [msdb].[dbo].[job_step_history_analysis]
	
	/*
--	create clustered index cix on #tJobs([Job])

--	select 
--		[Category]
--		, t.Job
--		,t.Step
--		,[Start Time] = t.[Start Time]
--		,t.[Step Order]
--		,t.[Duration In Seconds]
--		,t.[Job Outcome]
--		,t.[Error Message]
--		,[next_job_Start_Time] = next_job.[Start Time]
--		,GroupID =cast(null as smallint)
--		,job_start_time = cast(null as datetime)
--		,JobId = cast(null as uniqueidentifier)
--		,JobName =cast(null as nvarchar(255))
--	into #tJobs_data
--  FROM #tJobs t
--  outer apply
--  (
--	select
--		Job,
--		[Start Time] = min([Start Time])
--	from #tJobs next_job
--	where next_job.[Step Order] = 0
--		and next_job.Job=t.Job
--		and next_job.[Start Time]>t.[Start Time]
--	group by job
--  ) next_job 
--  --where t.[Start Time] between '2023-09-16 01:10:00.000' and '2023-09-18 01:20:00.000'
--  create clustered index cix on #tJobs_data(JobId)


--update t
--	set GroupID = [group].GroupID
--		,job_start_time = [group].JobStartTime
--		,JobId = cast(hashbytes('SHA2_256', concat(t.Job ,'|', JobStartTime)) as uniqueidentifier)
--		,JobName = concat(t.Job ,'|', format(JobStartTime, 'yyyy-MM-dd HH:mm:ss'))
-- from #tJobs_data t
--	inner join 
--	(
--		select 
--			job,
--			next_job_Start_Time = isnull(next_job_Start_Time, getdate()),
--			JobStartTime = min([Start Time]),
--			GroupID = row_number() over(partition by job order by next_job_Start_Time)
--		from #tJobs_data 
--		where [Step Order] = 0
--		group by job,
--			next_job_Start_Time
--	) [group] on [group].job  = t.job
--		and t.[Start Time]>=[group].JobStartTime 
--			and  t.[Start Time]<[group].next_job_Start_Time
*/

if exists (select top(1) 1 from #tJobs)
begin
begin tran
	--delete t from		dbo.job_step_history_analysis t
	--where exists(select top(1) 1 from #tJobs_data s where s.JobId = t.JobId
	--)
	truncate table [dbo].job_step_history_analysis

	insert into [dbo].job_step_history_analysis
	(
	 [Category]
	, [Job]
	, [Job start time]
	, Step
	, [Start Time]
	, [Step end Time]
	, [Duration In Seconds]
	, [Step Order]
	, [Job Outcome]
	, [Error Message]
	)
	select 
		[Category]
		,Job
		,[Job start time] = null
		,[Step] = Step
		,[Start Time]  = [Start Time]
		,[Step end Time]  = dateadd(second,[Duration In Seconds], [Start Time])
		,[Duration In Seconds]
		,[Step Order]
		,[Job Outcome]
		,[Error Message]
	from #tJobs
commit tran
end


	/*
	if exists (select top(1) 1 from #t)
	begin
		begin tran
			truncate table [dbo].[job_step_history_analysis]
			insert into [dbo].[job_step_history_analysis]
			(
				[Category], [Job], [Step], [Step Order], [Start Time], [Job Outcome], [Duration In Seconds], [Min Duration In Seconds], [Max Duration In Seconds], [Average Duration In Seconds], [Error Message]
			)
			select [Category], [Job], [Step], [Step Order], [Start Time], [Job Outcome], [Duration In Seconds], [Min Duration In Seconds], [Max Duration In Seconds], [Average Duration In Seconds],[Error Message]
				from #t
		commit tran
	end
	*/
end try

begin catch
	if @@TRANCOUNT>0
		rollback tran
	
	;throw
end catch
END
