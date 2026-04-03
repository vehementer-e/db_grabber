
--exec [dbo].[Create_dm_calls_history_on_project]

create   PROC [dbo].[Create_dm_calls_history_on_project]
as 
begin


   
 declare @update_dt datetime     


 		set		  @update_dt = 	'20230519'

  set nocount on
  
  drop table if exists #t 

			--select min(creationdate) from NaumenDbReport.dbo.mv_call_case
			--where projectuuid='corebo00000000000of7kfv710f939q4'
  drop table if exists #projects

  select  * into #projects from (
 --select  'corebo00000000000mqi35tcal14edv4' project_id union all    --Fedor TLS
 --select  'corebo00000000000mqpsrh9u28s16g8' project_id union all    --Fedor Автоинформатор лидген
 --select  'corebo00000000000mtmnhcj42ev6svs' project_id union all    --Триггеры
 --select  'corebo00000000000mtmnk1gt6gdvdc0' project_id union all    --Пилот
 --select  'corebo00000000000n1r61c517rn6rqo' project_id union all    --25%
 --select  'corebo00000000000n35ltu7n0jje82k' project_id union all    --Fedor Автоинформатор лидген 2
 --select  'corebo00000000000n56buhov4c5cjug' project_id union all    --Целевой
 --select  'corebo00000000000nfv3p83uiqcn9kg' project_id union all    --Целевой перезвоны
 --select  'corebo00000000000n8i9hcja56hji2o' project_id union all    --РобоIVR Пилот
 --select  'corebo00000000000n56bur0s6arg22o' project_id union all     --Пилот2
 --select  'corebo00000000000n9lae4v61imm0m4' project_id union all    --Пилот QPM
 --select  'corebo00000000000n9q7vju6irp0vmg' project_id union all     --Sales ОКБ
 --select  'corebo00000000000nbb1b9jb7da9aa0' project_id union all     --Fedor Рефинансирование
 --select  'corebo00000000000nbchkar1njd70ms' project_id union all     --Пилот МТС Маркетолог
 --select  'corebo00000000000nchqr3rfktcr5hc' project_id union all     --Fedor TLS МП Повторные
 --select  'corebo00000000000nchpe3fv0j6f4ag' project_id union all     --Fedor TLS МП Новые
 --select  'corebo00000000000nfl3ha5m324gqro' project_id union all     --CPC
 --select  'corebo00000000000nfv43b583tqck9k' project_id union all     --СРС перезвоны
 --select  'corebo00000000000nd135ldk2oc12gs' project_id union all     --Элекснет
 --select  'corebo00000000000nhc39ilthenudg4' project_id union all    --IVR МФО
 --select  'corebo00000000000nqckou5524ntca0' project_id--union all    --Лиды Installment
 select distinct idexternal project_id from feodor.dbo.dm_feodor_projects	 where id= 42
 ) p
 --select * from #projects a
 --left join feodor.dbo.dm_feodor_projects b on a.project_id=b.IdExternal


drop table if exists #dos
select dos.attempt_start
,      dos.attempt_end
,      dos.pickup_time 
,      dos.case_uuid 
,      dos.session_id 
,      dos.number_type 
,      dos.queue_time 
,      dos.operator_pickup_time 
,      dos.speaking_time 
,      dos.wrapup_time 
,      dos.login 
,      dos.attempt_result 
,      dos.hangup_initiator 
,      dos.attempt_number 
,	   cl.connected --DWH-1929
into #dos
from [NaumenDbReport].[dbo].[detail_outbound_sessions] dos with(index=[ix_project_id_attempt_start])
	LEFT JOIN NaumenDbReport.dbo.call_legs AS cl --WITH(INDEX=idx_session_id)
		ON cl.created >= dateadd(DAY, -1, @update_dt)
		AND cl.session_id = dos.session_id
		AND cl.leg_id = 1
where dos.attempt_start >= cast(@update_dt as datetime2)
	and 
	exists(select top(1) 1 from #projects fp where  fp.project_id=dos.project_id )
option(recompile)
/*
статистика выполнения
Table 'detail_outbound_sessions'. Scan count 21, logical reads 199705, physical reads 0, page server reads 0, read-ahead reads 30, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table '#projects___________________________________________________________________________________________________________000000019E02'. Scan count 1, logical reads 1, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

*/

create clustered index ix on #dos(session_id)

select case_uuid
	into #t_case_uuid
	from #dos
group by case_uuid
create clustered index ix on #t_case_uuid(case_uuid)
drop table if exists #t_call_case


select top(0)
		 cc.uuid
       , cc.creationdate
       , cc.timezone
       , cc.phonenumbers
       , cc.casecomment
       , cc.statetitle
       , cc.projecttitle
       , cc.projectuuid
into  #t_call_case
from #t_case_uuid t 
inner loop /*через loop работает лучше всего, по времени, хотя большой scan таблицы идет  
Scan count 15284978, logical reads 14178937, physical reads 9843, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
для 100к записей в #t_case_uuid работает около 5мин
	*/ 
	join [NaumenDbReport].[dbo].[mv_call_case]  cc 
	on t.case_uuid = cc.uuid
--option ( recompile)


insert into #t_call_case
(
	uuid
	,creationdate
	,timezone
	,phonenumbers
	,casecomment
	,statetitle
	,projecttitle
	,projectuuid
)
select 
		 cc.uuid
       , cc.creationdate
       , cc.timezone
       , cc.phonenumbers
       , cc.casecomment
       , cc.statetitle
       , cc.projecttitle
       , cc.projectuuid
from #t_case_uuid t 
inner loop /*через loop работает лучше всего, по времени, хотя большой scan таблицы идет  
Scan count 15284978, logical reads 14178937, physical reads 9843, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
для 100к записей в #t_case_uuid работает около 5мин
	*/ 
	join [NaumenDbReport].[dbo].[mv_call_case]  cc 
	on t.case_uuid = cc.uuid
--	and cc.[creationdate] > =  cast(@update_dt as datetime2)
create clustered index ix on #t_call_case(uuid)



		
SELECT  cc.uuid
       , cc.creationdate
       , cc.timezone
       , cc.phonenumbers
       , cc.casecomment
       , cc.statetitle
       , cc.projecttitle
       , cc.projectuuid

		--, q.title
		--, q.channel
		--, q.lcrm_id
		--DWH-1871
		, title = cf.lcrm_title
		, channel = cf.lcrm_channel
		, lcrm_id = cf.lcrm_id

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

       , /*pc.calldispositiontitle*/ null as calldispositiontitle

       , qc.[unblocked_time]
       , dos.connected --DWH-1929

    into #t
  
    FROM #dos dos
    join #t_call_case   cc on dos.case_uuid=cc.uuid
    left join [NaumenDbReport].[dbo].[mv_custom_form] cf on cf.owneruuid = cc.uuid
    left join [NaumenDbReport].[dbo].queued_calls qc on qc.session_id=dos.session_id
	--DWH-1871
    --cross apply openjson(cf.jsondata,'$.group001')
    --      with(
    --      title     nvarchar(50)  '$.Title',
    --      channel   nvarchar(50)  '$.channel',
    --      lcrm_id   nvarchar(50)        '$.lcrm_id'
    --      )  q

   declare @end_of_main_join datetime = getdate()

   ;with v  as (select *, row_number() over(partition by [session_id] order by  case when [unblocked_time] is null then 0 else 1 end desc, [unblocked_time]) rn from #t ) 
   delete from v where rn>1



  begin tran

   
 

  insert into  feodor.dbo.dm_calls_history
    select  [uuid]
      ,[creationdate]
      ,[timezone]
      ,[phonenumbers]
      ,[casecomment]
      ,[statetitle]
      ,[projecttitle]
      ,[projectuuid]
      ,[title]
      ,[channel]
      ,lcrm_id=try_cast([lcrm_id] as bigint)
      ,[attempt_start]
      ,[attempt_end]
      ,[number_type]
      ,[pickup_time] 
      ,[queue_time]
      ,[operator_pickup_time]
      ,[speaking_time]
      ,[wrapup_time]
      ,[login]
      ,[attempt_result]
      ,[hangup_initiator]
      ,[attempt_number]
      ,[session_id]
      ,[calldispositiontitle]
      ,[unblocked_time] 
	  ,connected --DWH-1929
 
	  from    #t
	

  commit tran


insert into dm_leads_history_ids_to_update
select 	 lcrm_id from 	#t		 a
left join dm_leads_history_ids_to_update b on a.lcrm_id=b.id
where b.id is null
group by lcrm_id
   select @@ROWCOUNT 


   end

