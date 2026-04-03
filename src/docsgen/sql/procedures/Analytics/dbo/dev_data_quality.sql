


CREATE   proc [dbo].[data_quality] 
as
begin

---------------------------------------------------------------
-------------------Data Quality feodor.dbo.dm_calls_history----
drop table if exists #dm_calls_history_Session_ids
select session_id, projectuuid, attempt_start ,cast( attempt_start as date) attempt_start_date into #dm_calls_history_Session_ids from Feodor.dbo.dm_calls_history with(nolock)
drop table if exists #dos_Session_ids
select session_id, project_id projectuuid, attempt_start ,cast( attempt_start as date) attempt_start_date into #dos_Session_ids from  NaumenDbReport.dbo.detail_outbound_sessions with(nolock)


drop table if exists #rez
select * into #rez from #dos_Session_ids
where projectuuid in ( 
select IdExternal from Feodor.dbo.dm_feodor_projects) 
except 
select * from #dm_calls_history_Session_ids


drop table if exists Analytics.dbo.__data_quality_dm_calls_history_ids_to_append
select * into Analytics.dbo.__data_quality_dm_calls_history_ids_to_append
from #rez
order by 1

select * from Analytics.dbo.__data_quality_dm_calls_history_ids_to_append 
order by attempt_start desc


--drop table if exists #ch_doubles
--;
--with v as (select session_id, count(*) cnt from #dm_calls_history_Session_ids group by session_id)
--select * into #ch_doubles from v where cnt>1

--drop table if exists #dates_with_doubles
--select distinct cast(attempt_start as date)  attempt_start_date  into #dates_with_doubles from #ch_doubles a left join  NaumenDbReport.dbo.detail_outbound_sessions b on a.session_id=b.session_id
--;
--with v as (
--select *, ROW_NUMBER() over(partition by session_id order by unblocked_time desc) rn from Feodor.dbo.dm_calls_history where cast(attempt_start as date) in (select * from #dates_with_doubles)
--)
----delete   from v where rn>1
--select *  from v where rn>1

drop table if exists #ch_agr
select projectuuid, attempt_start_date, count(*) cnt into #ch_agr from #dm_calls_history_Session_ids
group by projectuuid, attempt_start_date
--order by 


drop table if exists #dos_agr
select project_id, cast(attempt_start as date) attempt_start_date , count(*) cnt into #dos_agr from NaumenDbReport.dbo.detail_outbound_sessions with(nolock)
group by project_id,  cast(attempt_start as date)
--order by 


select distinct x.attempt_start_date from (

select distinct attempt_start_date, project_id from #dos_agr
union 
select distinct attempt_start_date, projectuuid from #ch_agr

) x
left join #dos_agr d on d.attempt_start_date=x.attempt_start_date and d.project_id=x.project_id
left join #ch_agr  c on c.attempt_start_date=x.attempt_start_date and c.projectuuid=x.project_id

where x.project_id in ( 
select IdExternal from Feodor.dbo.dm_feodor_projects) 
and d.cnt<>c.cnt
order by 1
------------------------------------------
------------------------------------------
		
	drop table if exists #t1
	     select 
	     uuid
	   , creationdate 
	   , timezone
	   , phonenumbers
       , casecomment
       , statetitle
       , projecttitle
       , projectuuid
       , Title
       , channel
       , try_cast(lcrm_id as bigint) lcrm_id
       , attempt_start
       , attempt_end	
       , number_type	
       , pickup_time
       , queue_time
       , operator_pickup_time
       , speaking_time
       , wrapup_time
       , login
       , attempt_result
       , hangup_initiator
       , attempt_number
       , session_id 

       , null as calldispositiontitle
       , unblocked_time
	into #t1 
	from openquery(naumen, '
	SELECT   
	     cc.uuid
       , cc.creationdate
       , cc.timezone
       , cc.phonenumbers
       , cc.casecomment
       , cc.statetitle
       , cc.projecttitle
       , cc.projectuuid
       , cf.jsondata -> ''group001'' -> ''Title''    Title
       , cf.jsondata -> ''group001'' -> ''channel''  channel
       , cf.jsondata -> ''group001'' -> ''lcrm_id''  lcrm_id
       , dos.attempt_start
       , dos.attempt_end	
       , dos.number_type	
       , dos.pickup_time
       , dos.queue_time
       , dos.operator_pickup_time
       , dos.speaking_time
       , dos.wrapup_time
       , dos.login
       , dos.attempt_result
       , dos.hangup_initiator
       , dos.attempt_number
       , dos.session_id 

       , null as calldispositiontitle
       , qc.unblocked_time
         
    FROM  detail_outbound_sessions dos  
    join  mv_call_case  cc     on dos.case_uuid=cc.uuid
    left join  mv_custom_form cf on cf.owneruuid = cc.uuid
    left join queued_calls qc on qc.session_id=dos.session_id
	where cast(dos.attempt_start  as date)=''20210822''

	 ')
	
   ;with v  as (select *, row_number() over(partition by [session_id] order by  case when [unblocked_time] is null then 0 else 1 end desc, [unblocked_time]) rn from #t1 ) 
   delete from v where rn>1 or lcrm_id is null



end