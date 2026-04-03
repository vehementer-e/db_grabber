 
CREATE PROC [dbo].[lead_case_creation] @date date = null
as  
--  exec [dbo].[lead_case_crm_creation]
--declare @date date = '20250301' 
    --declare @dt  datetime2 = '20250301' 




    declare @dt  datetime2 =  dateadd(day, -3, cast( getdate()  as date) )  


  if exists (
  select * from Analytics.dbo.jobh where command like '%' + 'lead_case_creation' + '%' and Succeeded>= cast( getdate()  as date) and 1=0
  )
    set @dt    =  dateadd(hour, -3, getdate())  
   drop table if exists #t

 
 --  declare @dt  datetime2 =  dateadd(day, -3, cast( getdate()  as date) )  

  drop table if exists #fp
  select distinct  IdExternal into #fp from feodor.[dbo].dm_feodor_project2 where RecallProject=0 
  and id>0
   
   drop table if exists #case 

   SELECT  cc.uuid uuid
       , cc.projectuuid projectuuid
       , cc.creationdate creationdate 
	   , cc.statetitle 
    into #case
  
    FROM [NaumenDbReport].[dbo].[mv_call_case]     cc    with(index=NCL_idx_creationdate_projectuuid)  
    join #fp fp on fp.IdExternal=cc.projectuuid  

   where  cc.creationdate> @dt 



   drop table if exists #t

   SELECT  cc.uuid uuid
       , cc.projectuuid projectuuid
       , cast(cc.creationdate as datetime2(7)) creationdate 
       ,  cast( cf.lead_id  as nvarchar(36)) as lead_id 
	   , cc.statetitle 
    into #t
  
    FROM  #case    cc  
    join [NaumenDbReport].[dbo].[mv_custom_form] cf on cc.uuid=cf.owneruuid 
 

   ;
   with v as
   (select *, ROW_NUMBER() over(partition by lead_id order by creationdate ) rn from #t )

   delete from v where rn>1 or lead_id is null

   
   drop table if exists #t_insert
   select a.* into #t_insert from  #t a
   left join  Feodor.dbo.dm_case_uuid_to_lf_references b on a.lead_id=b.lead_id and b.creationdate>=a.creationdate
   where b.lead_id is   null
  

  --select * from #t_insert

   
    begin tran

	--delete from Feodor.dbo.dm_case_uuid_to_lf_references where creationdate > @update_dt
	delete a from Feodor.dbo.dm_case_uuid_to_lf_references a join  #t_insert b on a.lead_id=b.lead_id

	insert into Feodor.dbo.dm_case_uuid_to_lf_references
		select 
    a.[uuid] 
,   a.[projectuuid] 
,   a.[creationdate] 
,   a.lead_id 
,    getdate() [created] 
,   a.[statetitle] 

from 

#t_insert a   
 
   commit tran

    


   if @date is   null

   begin  

   insert into #t 
   select a.uuid, a.projectuuid, a.creationdate, a.lead_id, a.statetitle

from Feodor.dbo.dm_case_uuid_to_lf_references a with(nolock)
  join lead b with(nolock) on a.lead_id=b.id
and b.creationdate is   null 
where
b.UF_REGISTERED_AT>=cast( getdate()-1   as date)
and a.creationdate >=cast( getdate()-1   as date)

end

;with v  as (select *, row_number() over(partition by  a.lead_id order by (select null)) rn from #t a ) delete from v where rn>1


  
drop table if exists #ref

select a.lead_id ID  ,a.statetitle, a.uuid,a.projectuuid, a.creationdate, case when b.id is null then 1 else 0 end for_upd into #ref 


from #t a
left join Feodor.dbo.lead b with(Nolock) on a.lead_id=b.ID--	and isnull( b.creationdate, '20010101') <=a.creationdate
where   b.creationdate is null   or (a.creationdate<b.creationdate and b.ВремяПервойПопытки IS NULL )
--and  a.lead_id is not null
 



    --select *  from #calls
drop table if exists #changed
 
select distinct ID lead_id into #changed from #ref	a  
where ID is not null	  and for_upd=1



--select * from #changed

declare @a [CARM\P.Ilin].[leadType] 

insert into  @a
  select  lead_id from 	#changed
exec lead_creation 		@a, null




drop table if exists  [#dm_feodor_projects]
select IdExternal, RecallProject, LaunchControlName,   rn_IdExternal into [#dm_feodor_projects]

from  [Feodor].[dbo].[dm_feodor_project2]

drop table if exists #mv_employee
select a.login, max( a.title) title into #mv_employee 
from 
[NaumenDbReport].[dbo].[mv_employee] a
group by a.login


 

		


drop table if exists #for_merge
select 
      REF.ID [ID]
  
 	  , [CompanyNaumen] = 
	  case  
	  when fp_ref.LaunchControlName is not null then fp_ref.LaunchControlName
 end

      , ref.creationdate   ,uuid
	  ,case when ref.statetitle = 'Выполнено' then 1 else 0 end as [Удален из обзвона]	  
 
  into #for_merge
  from   #ref ref   											    						    
  left join [#dm_feodor_projects]fp_ref on fp_ref.[IdExternal]=ref.[projectuuid] and  fp_ref.[rn_IdExternal]=1
 												  
  		   ;
	    with v as
   (select *, ROW_NUMBER() over(partition by [ID] order by creationdate) rn from #for_merge )

   delete from v where rn>1  

	;
   
 		    MERGE feodor.dbo.[lead] AS target
    USING (
 select 
  [ID] 
 ,[CompanyNaumen] [CompanyNaumen]  
 ,creationdate
 ,uuid
 ,[Удален из обзвона]
 
  
 from
 #for_merge lcrmnau) AS source
    ON target.ID = source.ID
    WHEN MATCHED THEN
        UPDATE SET
  target.[CompanyNaumen]    			 =case when isnull(target.[CompanyNaumen], '')='' and target.ВремяПервойПопытки is null then  source.[CompanyNaumen]   else target.[CompanyNaumen]  end 
 ,target.creationdate					 =case when target.creationdate	is null or target.creationdate>  source.creationdate   then   source.creationdate 	   else  target.creationdate end
 ,target.uuid							 =case when target.creationdate	is null or target.creationdate>  source.creationdate   then   source.uuid 	   else  target.uuid end
 ,target.[Удален из обзвона]					 =  case when target.ВремяПервойПопытки is null and isnull( target.[Удален из обзвона], 0)<>1 and   source.[Удален из обзвона]  =1 then 1 else   target.[Удален из обзвона]	  end
, target. row_updated		 =getdate()
 
  ;



   
