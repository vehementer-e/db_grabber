
CREATE   proc [dbo].[job_history_stat_creation]
as

begin



select 
  Run_Date 
, Step_Name
, step_id
, job_id
, Job_Name
, Run_Status
, command
,owner_sid
, subsystem   
, case when Run_Status='Failed' then message   end fail_message 
, count(*) cnt
into #t1
from jobh
where Run_Date>=cast(getdate()-2 as date)

group by Run_Date , Step_Name, step_id, job_id, Job_Name, Run_Status, command ,owner_sid, subsystem,  case when Run_Status='Failed' then message end   



if (select count(*) from #t1)	=0
select 1/0


delete a from	   _v_sysjobhistory_stat a
left join (select distinct job_id , Run_Date from  #t1)	b on a.job_id=b.job_id	and b.Run_Date=a.Run_Date
where b.job_id is not null


	   insert
into 		 _v_sysjobhistory_stat
select 
  Run_Date 
, Step_Name
, step_id
, job_id
, Job_Name
, Run_Status
, command
, owner_sid
, subsystem   
, fail_message 
, cnt
from #t1






end