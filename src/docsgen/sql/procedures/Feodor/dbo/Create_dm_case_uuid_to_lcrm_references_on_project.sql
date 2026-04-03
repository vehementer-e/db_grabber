create   PROC [dbo].[Create_dm_case_uuid_to_lcrm_references_on_project]
as 
begin
 --return

  set nocount on
   drop table if exists #t



 declare @update_dt datetime     
 
  
   set @update_dt   = '20230519'

  drop table if exists #fp
  select distinct  IdExternal into #fp from feodor.[dbo].dm_feodor_projects where RecallProject=0
  and id=42

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

	--delete from Feodor.dbo.dm_case_uuid_to_lcrm_references where creationdate > @update_dt
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
		    

   commit tran



insert into dm_leads_history_ids_to_update
select 	 lcrm_id from 	#t			 a
left join dm_leads_history_ids_to_update b on a.lcrm_id=b.id
where b.id is null
group by lcrm_id
   select @@ROWCOUNT 


   end		   
