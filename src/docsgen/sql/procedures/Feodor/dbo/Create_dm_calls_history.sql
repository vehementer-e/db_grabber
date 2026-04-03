

--exec [dbo].[Create_dm_calls_history]

CREATE   PROC [dbo].[Create_dm_calls_history]
as 
begin


 declare @max_attempt_start datetime =  (select max(attempt_start) from Feodor.dbo.dm_calls_history)
  declare @start_creating_ch datetime = getdate()

 declare @long_update int = case when 
 not exists (select top 1 1 from Feodor.dbo.dm_calls_history_monitoring where start_creating_lh>=cast(getdate() as date)   )
 
 then 1 else 0 end 
 --select @long_update

 declare @update_dt datetime     
 
 set  @update_dt=case when @long_update=1 then  cast(@max_attempt_start-2 as date) else dateadd(hour, -4, @max_attempt_start) end
   select @update_dt



 

  set nocount on
  
  drop table if exists #t 


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
 select distinct idexternal project_id from feodor.dbo.dm_feodor_projects
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
	  , cf.lead_id   lead_id
    into #t
  
    FROM #dos dos
    join #t_call_case   cc on dos.case_uuid=cc.uuid
    left join [NaumenDbReport].[dbo].[mv_custom_form] cf on cf.owneruuid = cc.uuid
    left join [NaumenDbReport].[dbo].queued_calls qc on qc.session_id=dos.session_id
--	left join Analytics.dbo.[lead_case_crm]	 lc on lc.uuid=cc.uuid
--	left join stg._lf.[naumen_call_case] lf on lf.payload =cc.uuid
	--DWH-1871
   -- outer apply openjson(cf.jsondata,'$.group001')
   --       with(
   --       lead_id     nvarchar(50)  '$.lead_id'
   --       )  q

   declare @end_of_main_join datetime = getdate()

   ;with v  as (select *, row_number() over(partition by [session_id] order by  case when [unblocked_time] is null then 0 else 1 end desc, [unblocked_time]) rn from #t ) 
   delete from v where rn>1

  --alter table    feodor.dbo.dm_calls_history   add lead_id   [NVARCHAR](36)

  begin tran

   
  delete from  feodor.dbo.dm_calls_history   
	where attempt_start >= cast(@update_dt as datetime2)
	and $PARTITION.[pfn_date_part](attempt_start) >=$PARTITION.[pfn_date_part](cast(@update_dt as datetime2))
  declare @end_of_deleting_ch datetime = getdate()

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
	  ,try_cast(lead_id as nvarchar(36))   lead_id

 
	  from    #t
	

  commit tran


	  declare @end_of_inserting_ch datetime = getdate()


 			 
--select *, cast([ДатаВзаимодействия] as datetime)+ cast([ВремяВзаимодействия] as datetime) [ДатаВремяВзаимодействия] 

--from
--reports.[dbo].[dm_Все_коммуникации_На_основе_отчета_из_crm]


--create clustered index t on    analytics.dbo.[lead_call_crm] (session_id)
--create nonclustered index t1 on    analytics.dbo.[lead_call_crm] (attempt_start)	

--create clustered index t on    analytics.dbo.[lead_case_crm] (uuid)
--create nonclustered index t1 on    analytics.dbo.[lead_case_crm] (creationdate)




  if @long_update = 1
  begin
  
  drop table if exists #agr
select 
       attempt_start_date  = cast(attempt_start as date)                                  
,      projectuuid         =  projectuuid                                                     
,      ЧислоЗвонков        = count(lcrm_id)                                                     
,      ЧислоЛидов          = count(distinct lcrm_id)                                              
,      ЧислоДозвонов       = count(case when login is not null then lcrm_id end)               
,      ЧислоЛидовСДозвоном = count(distinct case when login is not null then lcrm_id end)
, getdate() as created
into #agr
from #t 

--where attempt_start>= @update_dt
group by cast(attempt_start as date)     , projectuuid

begin tran
delete from Feodor.dbo.dm_calls_history_agr where attempt_start_date>=cast(@update_dt as date)
insert into Feodor.dbo.dm_calls_history_agr
select * from #agr
commit tran

declare @start_date date = @update_dt



drop table if exists #t3;
with v
as
(
	select min(attempt_start)                                     attempt_start
	,      count(case when attempt_result='abandoned' and queue_time >0 and [login] is null then 1 end) abandoned_calls_count
	,      count(*)                                               calls_count
	,      sum(wrapup_time)                                       wrapup_time_sum
	,      sum(speaking_time)                                     speaking_time_sum
	,      count(wrapup_time)                                     wrapup_time_count
	,      count(speaking_time)                                   speaking_time_count
	,      count(coalesce(speaking_time, wrapup_time))            speaking_and_wrapup_time_count
	,      lcrm_id                                               
	,      creationdate                                          
	,      projectuuid                                          
	--into #t2
	from Feodor.dbo.dm_calls_history ch 
	where cast(creationdate as date) >= @start_date						 and  1=0
	group by lcrm_id
	,        ch.projectuuid
	,        creationdate
)


select cast(creationdate as date)                                                                                                  creationdate_date
,      projectuuid                                                                                                     
,      isnull(sum(abandoned_calls_count)                                                                                      , 0) abandoned_calls_count
,      isnull(sum(wrapup_time_sum)                                                                                            , 0) wrapup_time_sum
,      isnull(sum(speaking_time_sum)                                                                                          , 0) speaking_time_sum
,      isnull(sum(wrapup_time_count)                                                                                          , 0) wrapup_time_count
,      isnull(sum(speaking_time_count)                                                                                        , 0) speaking_time_count
,      isnull(sum(speaking_and_wrapup_time_count)                                                                             , 0) speaking_and_wrapup_time_count
,      isnull(sum(calls_count)                                                                                                , 0) number_of_calls
,      isnull(count(attempt_start)                                                                                            , 0) case_handled_in_any_time_count
,      isnull(count(case when attempt_start between creationdate and dateadd(minute, 15, creationdate) then attempt_start end), 0) case_handled_15_min_count
,      isnull(count(case when attempt_start between creationdate and dateadd(minute, 30, creationdate) then attempt_start end), 0) case_handled_30_min_count
,      isnull(count(case when attempt_start between creationdate and dateadd(minute, 60, creationdate) then attempt_start end), 0) case_handled_60_min_count
into #t3
from v


group by cast(creationdate as date)
,        projectuuid


begin tran

delete from feodor.dbo.dm_report_feodor_project_secondary_metrics where creationdate_date in (select distinct creationdate_date from #t3)
insert into feodor.dbo.dm_report_feodor_project_secondary_metrics 


			 select 
			  t3.creationdate_date
			 ,t3.projectuuid
			 ,t3.abandoned_calls_count
			 ,t3.wrapup_time_sum
			 ,t3.speaking_time_sum
			 ,t3.wrapup_time_count
			 ,t3.speaking_time_count
			 ,t3.speaking_and_wrapup_time_count
			 ,t3.number_of_calls
			 ,t3.case_handled_in_any_time_count
			 ,t3.case_handled_15_min_count
			 ,t3.case_handled_30_min_count
			 ,t3.case_handled_60_min_count
			 ,n_proj.projecttitle
			 ,getdate() as created
			-- into --drop table
			 from #t3 t3 left join Reports.dbo.dm_NaumenProjects n_proj on t3.projectuuid=n_proj.projectuuid
			-- order by 1


			commit tran

end



   if 1 = 0 
   
   begin


drop table if exists #t1
					
select 	lcrm_id into #t1 from #t	  a
left join v_dm_leads_history B ON A.lcrm_id=B.ID
WHERE isnull(B.ВремяПоследнейПопытки, '20010101') <a.attempt_start 



insert into dm_leads_history_ids_to_update
select 	 lcrm_id from 	#t1			 a
left join dm_leads_history_ids_to_update b on a.lcrm_id=b.id
where b.id is null
group by lcrm_id
   select @@ROWCOUNT, @long_update


   end		   

   if 0 = 1 begin
   drop table if exists #t2
					
select 	lcrm_id into #t2 from dm_calls_history	  a
left join v_dm_leads_history B ON A.lcrm_id=B.ID
WHERE isnull(B.ВремяПоследнейПопытки, '20010101') <a.attempt_start 


insert into dm_leads_history_ids_to_update
select 	 lcrm_id from 	#t2			 a
left join dm_leads_history_ids_to_update b on a.lcrm_id=b.id
where b.id is null
group by lcrm_id

   select @@ROWCOUNT, @long_update

   --select * from 		   Analytics.dbo.[v_Запущенные джобы]
   --order by 2
   end









	  declare @end_of_proc datetime = getdate()

  insert into  feodor.[dbo].[dm_calls_history_monitoring]
select @start_creating_ch             start_creating_lh
,      1                              job
,      @end_of_main_join              end_of_main_join
,      @end_of_deleting_ch            end_of_window_part
,      @end_of_inserting_ch            end_of_second_join
,      '@long_update = '+cast(@long_update  as varchar(1))                     string
, @end_of_inserting_ch end_of_inserting_ch
, @end_of_proc end_of_proc
--into feodor.dbo.dm_leads_history_monitoring

--alter table feodor.[dbo].[dm_calls_history_monitoring]  add  end_of_inserting_ch datetime
--alter table feodor.[dbo].[dm_calls_history_monitoring]  add  end_of_proc datetime
end
 
