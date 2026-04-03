CREATE PROC [dbo].[Create_dm_case_uuid_to_lcrm_references]
as 
begin
 return

  set nocount on
   drop table if exists #t

   
 declare @max_creationdate datetime =  (select max(creationdate) from Feodor.dbo.dm_case_uuid_to_lcrm_references)
  declare @start_creating datetime = getdate()

 declare @long_update int = case when cast(@max_creationdate as date)<>cast(@start_creating as date) then 1 else 0 end 
 


 declare @update_dt datetime     
 
 set  @update_dt=case when @long_update=1 then  cast(@max_creationdate-2 as date) else dateadd(hour, -4, @max_creationdate) end
  -- select @update_dt

  drop table if exists #fp
  select distinct  IdExternal into #fp from feodor.[dbo].dm_feodor_projects where RecallProject=0

  -- declare @update_dt datetime     
  -- set  @update_dt='20211230'
  -- select @update_dt
   SELECT  cc.uuid uuid
       , cc.projectuuid projectuuid
       , cc.creationdate creationdate
       --, try_cast(q.lcrm_id as numeric) lcrm_id
       , cf.lcrm_id as lcrm_id --DWH-1871
	   , cc.statetitle 
    into #t
  
    FROM [NaumenDbReport].[dbo].[mv_call_case]     cc    with(index=NCL_idx_creationdate_projectuuid)
    join [NaumenDbReport].[dbo].[mv_custom_form] cf on cc.uuid=cf.owneruuid
    join #fp fp on fp.IdExternal=cc.projectuuid 
	--DWH-1871
	--cross apply openjson(jsondata,'$.group001')
	--       with(
	--       lcrm_id   nvarchar(50)        '$.lcrm_id'
	--       )  q
   where  cc.creationdate> @update_dt
   ;
   with v as
   (select *, ROW_NUMBER() over(partition by lcrm_id order by (select null)) rn from #t )

   delete from v where rn>1 or lcrm_id is null

  -- go




   begin tran

	delete from Feodor.dbo.dm_case_uuid_to_lcrm_references where creationdate > @update_dt
	insert into Feodor.dbo.dm_case_uuid_to_lcrm_references
		select 
    a.[uuid] 
,   a.[projectuuid] 
,   a.[creationdate] 
,   a.[lcrm_id] 
,    getdate() [created] 
,   a.[statetitle] 

from 

#t a

--	exec analytics.dbo.generate_select_table_script 'Feodor.dbo.dm_case_uuid_to_lcrm_references'



	--select * into Feodor.dbo.dm_case_uuid_to_lcrm_references from Feodor.dbo.dm_case_uuid_to_lcrm_references_last_2_days

   --drop table if exists Feodor.dbo.dm_case_uuid_to_lcrm_references_last_2_days
   --select *, getdate() as created into Feodor.dbo.dm_case_uuid_to_lcrm_references_last_2_days from #t
   --   CREATE CLUSTERED INDEX [ClusteredIndex-Lcrm_id] ON [dbo].[dm_case_uuid_to_lcrm_references_last_2_days]
   --(
   --	[lcrm_id] DESC
   --)
   --   CREATE CLUSTERED INDEX [ClusteredIndex-Lcrm_id] ON [dbo].[dm_case_uuid_to_lcrm_references]
   --(
   --	[lcrm_id] DESC
   --)

   commit tran



   if @long_update = 0 
   
   begin
   drop table if exists #t1
					
select 	lcrm_id into #t1 from #t	  a
left join v_dm_leads_history B ON A.lcrm_id=B.ID
WHERE B.uuid IS NULL 

insert into dm_leads_history_ids_to_update
select 	 lcrm_id from 	#t1			 a
left join dm_leads_history_ids_to_update b on a.lcrm_id=b.id
where b.id is null
group by lcrm_id
   select @@ROWCOUNT, @long_update


   end		   

   if @long_update = 1 begin
   drop table if exists #t2
					
select 	lcrm_id into #t2 from dm_case_uuid_to_lcrm_references	  a
left join v_dm_leads_history B ON A.lcrm_id=B.ID
WHERE B.uuid IS NULL 			  

insert into dm_leads_history_ids_to_update
select 	 lcrm_id from 	#t2			 a
left join dm_leads_history_ids_to_update b on a.lcrm_id=b.id
where b.id is null
group by lcrm_id

   select @@ROWCOUNT, @long_update


   end



   --alter table Feodor.dbo.dm_case_uuid_to_lcrm_references
   --add [statetitle] nvarchar(256)
 
if not exists (select * from Analytics.dbo.[v_Запущенные джобы] where job_name='temp analytics job') 
EXEC msdb.dbo.sp_start_job 'temp analytics job'
--select * from 		   Analytics.dbo.[v_Запущенные джобы]
--order by 2

end
 