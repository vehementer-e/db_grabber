CREATE   proc [dbo].[Проверка падения джобов]
as
begin



   
drop table if exists #job_fails
SELECT --top 100
[Текст] = step_info+char(10)+case when owner_sid=0x0105000000000005150000005C4CFCF833317E29EC2F9A25903E0000 or step_info like '%Analytics%' then  'google_Search_falling_jobs_analytics'  else  'google_Search_falling_jobs_DWH' end,
[subject] = step_result,
format(step_id , '0_')+format(run_dateandtime , 'yyyyMMddHHmmss_')+cast(job_id as nvarchar(36)) step_id_job_id_run_dateandtime
, job_id
, step_id
, Finish_DateAndTime
, command
--select distinct * from #job_fails
into #job_fails
  FROM jobh with(nolock)
  where [is_intended_to_fall]=0 and [is_Succeeded]=0  --and (Job_Name like 'Analytics%' or Job_Name like '%reports%')
  and Finish_DateAndTime>=dateadd(minute, -30, isnull((select max(run_dateandtime) from dbo.[Учтенные падения джобов_view]), cast(getdate() as date)))  and Run_Status<>'retry'
  order by Run_DateAndTime
 
--delete from [Учтенные падения джобов_view] where run_dateandtime>='20230608'
  --if( select max(Finish_DateAndTime) from #job_fails) is not null
  --begin
  ----alter table config add last_failed_job_Finish_DateAndTime2 datetime2
  --update config set last_failed_job_Finish_DateAndTime2 = ( select max(Finish_DateAndTime) from #job_fails)
  ----select * from config
  --end

			   drop table if exists #stat
			 
SELECT a.job_id
	,a.step_id
	,a.Finish_DateAndTime
	,b.Finish_DateAndTime Finish_DateAndTime_history
	,b.Run_Status Run_Status_history
	, b.is_Succeeded  is_Succeeded_history
INTO #stat
FROM #job_fails a
LEFT JOIN jobh b ON a.job_id = b.job_id
	AND a.step_id = b.step_id
	AND b.Finish_DateAndTime < a.Finish_DateAndTime
	AND b.Run_Status <> 'retry'
												
--select * into [dbo].[Учтенные падения джобов2]	 from  [dbo].[Учтенные падения джобов]
	
 ;
delete a from  #job_fails a
join  [dbo].[Учтенные падения джобов2]  b on a.step_id_job_id_run_dateandtime=b.step_id_job_id_run_dateandtime
;
with v as (

SELECT *
,case when cast(Finish_DateAndTime_history as date)>=cast(getdate() as date) then 1 else 0 end [today] 
,case when cast(Finish_DateAndTime_history as date)>=cast(getdate()-1 as date) then 1 else 0 end [today - 1] 
,case when cast(Finish_DateAndTime_history as date)>=cast(getdate()-3 as date) then 1 else 0 end [today - 3] 
,case when cast(Finish_DateAndTime_history as date)>=cast(getdate()-7 as date) then 1 else 0 end [today - 7] 
,case when cast(Finish_DateAndTime_history as date)>=cast(getdate()-14 as date) then 1 else 0 end [today - 14] 
,case when cast(Finish_DateAndTime_history as date)>=cast(getdate()-21 as date) then 1 else 0 end [today - 21] 
	,ROW_NUMBER() OVER (
		PARTITION BY job_id
		,step_id
		,Finish_DateAndTime ORDER BY Finish_DateAndTime_history DESC
		) count_falls  ,count(case when is_Succeeded_history=0 then Finish_DateAndTime_history end ) OVER (
		PARTITION BY job_id		 
		,step_id
		,Finish_DateAndTime ORDER BY Finish_DateAndTime_history DESC
		) rn	,	   count(  Finish_DateAndTime_history ) OVER (
		PARTITION BY job_id		 
		,step_id
		,Finish_DateAndTime  
		) cnt
FROM #stat
--order by Finish_DateAndTime_history

)
  , v_ as (
select a.job_id, a.step_id	 , a.Finish_DateAndTime
, max(case when count_falls=rn then rn end  )+1 [xN fail]
,stat                           = '30 tries succ rate'     + ' - '+ isnull( format( case when max(cnt)                                                              >=30 then sum(case when rn<=30 then is_Succeeded_history end  )            / nullif( (0.0+count(case when rn<=30          then is_Succeeded_history end  ) ) , 0)      end , '0%') , 'Нет данных') 
/*,[90 tries succ rate]          = */+char(10)+'90 tries succ rate'     + ' - '+ isnull( format( case when max(cnt)                                                              >=90 then sum(case when rn<=90 then is_Succeeded_history end  )            / nullif( (0.0+count(case when rn<=90          then is_Succeeded_history end  ) ) , 0)      end , '0%') , 'Нет данных') 
/*,[7 tries succ rate]           = */+char(10)+'7 tries succ rate'      + ' - '+ isnull( format( case when max(cnt)                                                              >=7  then sum(case when rn<=7 then is_Succeeded_history end   )            / nullif( (0.0+count(case when rn<=7           then is_Succeeded_history end   ) ) , 0)     end , '0%') , 'Нет данных') 
/*,[today succ rate]             = */+char(10)+'today succ rate'        + ' - '+ isnull( format( case when (0.0+count(case when [today]=1 then is_Succeeded_history end  ))      > 0 then  sum(case when [today]=1 then is_Succeeded_history end        )   / nullif( (0.0+count(case when [today]=1       then is_Succeeded_history end  )) , 0)       end , '0%') , 'Нет данных') 
/*,[today - 1 succ rate]         = */+char(10)+'today - 1 succ rate'    + ' - '+ isnull( format( case when (0.0+count(case when [today - 1]=1 then is_Succeeded_history end  ))  > 0 then  sum(case when [today - 1]=1 then is_Succeeded_history end    )   / nullif( (0.0+count(case when [today - 1]=1   then is_Succeeded_history end  )) , 0)       end , '0%') , 'Нет данных') 
/*,[today - 3 succ rate]         = */+char(10)+'today - 3 succ rate'    + ' - '+ isnull( format( case when (0.0+count(case when [today - 1]=1 then is_Succeeded_history end  ))  > 0 then  sum(case when [today - 3]=1 then is_Succeeded_history end    )   / nullif( (0.0+count(case when [today - 3]=1   then is_Succeeded_history end  )) , 0)       end , '0%') , 'Нет данных') 
/*,[today - 7 succ rate]         = */+char(10)+'today - 7 succ rate'    + ' - '+ isnull( format( case when (0.0+count(case when [today - 7]=1 then is_Succeeded_history end  ))  > 0 then  sum(case when [today - 7]=1 then is_Succeeded_history end    )   / nullif( (0.0+count(case when [today - 7]=1   then is_Succeeded_history end  )) , 0)       end , '0%') , 'Нет данных') 
/*,[today - 14 succ rate]        = */+char(10)+'today - 14 succ rate'   + ' - '+ isnull( format( case when (0.0+count(case when [today - 14]=1 then is_Succeeded_history end  )) > 0 then  sum(case when [today - 14]=1 then is_Succeeded_history end   )   / nullif( (0.0+count(case when [today - 14]=1  then is_Succeeded_history end   )) , 0)      end , '0%') , 'Нет данных') 
/*,[today - 21 succ rate]        = */+char(10)+'today - 21 succ rate'   + ' - '+ isnull( format( case when (0.0+count(case when [today - 21]=1 then is_Succeeded_history end  )) > 0 then  sum(case when [today - 21]=1 then is_Succeeded_history end   )   / nullif( (0.0+count(case when [today - 21]=1  then is_Succeeded_history end   )) , 0)      end , '0%') , 'Нет данных') 

from v	  a
group by job_id, step_id	, Finish_DateAndTime
)

select * into #stat_ from 	v_

 --drop table  [dbo].[Учтенные падения джобов] 
 --drop table  [dbo].[Учтенные падения джобов] 
 --select step_id_job_id_run_dateandtime into [dbo].[Учтенные падения джобов] from #job_fails where 1=0
;

 insert into  [dbo].[Учтенные падения джобов2] 
 select step_id_job_id_run_dateandtime from #job_fails

 ;
 with j_sat as (

   select a.*, b.stat, b.[xN fail] from   #job_fails a
   left join #stat_ b on a.job_id=b.job_id and a.step_id=b.step_id and a.Finish_DateAndTime=b.Finish_DateAndTime

 )






--Проверка падения джобов
--insert into ##monitoring_each_15_min
select distinct [Текст], send_to ,  subject   from (
select 


a.Текст+CHAR(10)+CHAR(10)
+'step stat:'+CHAR(10)+CHAR(10)
+a.stat

+ case when x.step_id_outcome is not null then CHAR(10)+CHAR(10)+'JOB stat:'+CHAR(10)+CHAR(10) +x.stat else '' end  Текст

, case when x.step_id_outcome is not null then replace(a.subject, '-> STEP ', '-> STEP '+isnull('^'+format(a.[xN fail], '0')+' ', '') +'+ JOB '+isnull('^'+format(x.[xN fail], '0')+' ', '')) else replace(a.subject, '-> STEP ', '-> STEP '+isnull('^'+format(a.[xN fail], '0')+' ', ''))  end subject  from j_sat a
outer apply (select top 1 b.step_id step_id_outcome, b.[xN fail], b.stat from j_sat b where a.job_id=b.job_id   and a.step_id<>0  and b.step_id=0 and b.Finish_DateAndTime between a.Finish_DateAndTime and dateadd(second, 60, a.Finish_DateAndTime) order by b.Finish_DateAndTime  ) x
outer apply (select top 1 b.step_id step_id_outcome from j_sat b where a.job_id=b.job_id   and a.step_id=0  and b.step_id<>0 and dateadd(second, -60, b.Finish_DateAndTime)<=a.Finish_DateAndTime  order by b.Finish_DateAndTime desc) x1
 where x1.step_id_outcome is null
) a1 
, 
(select 'p.ilin@techmoney.ru' [send_to]  ) a2 where Текст is not null






end