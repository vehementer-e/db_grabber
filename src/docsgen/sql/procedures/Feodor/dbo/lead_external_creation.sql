	  --declare @start_date date = '20240425'
CREATE procedure [dbo].[lead_external_creation] 	 @full_upd int = 1 


as 
--return

declare @date datetime = getdate()
drop table if exists #lead_external


CREATE TABLE [dbo].[#lead_external](      [id] [NVARCHAR](36)    , [created] [DATETIME2](0)    , [sum] [INT]    , [link_created] [DATETIME2](0)    , [hash] [VARBINARY](8000)    , [row_created] [DATETIME]    , [guid] [UNIQUEIDENTIFIER]    , [lead_update_confirmed] [DATETIME2](7)    , [productType] [NVARCHAR](255)    , [isBigInstallment] [INT]);

if @full_upd=1
begin

insert   
into #lead_external

select a.id, a.created, a.sum, a.link_created, a.hash  hash
, @date row_created

, NEWID() guid
, cast(null as datetime2) lead_update_confirmed
, a.[productType]
, a.isBigInstallment
from analytics.dbo.v_request_external a  with(nolock)
left join lead_external b on a.id=b.id and a.hash =b.hash  and b.lead_update_confirmed is not null
where b.id is null
--insert into #lead_external

end
else 

begin

insert   
into #lead_external

select a.id, a.created, a.sum, a.link_created, a.hash  hash
, @date row_created

, NEWID() guid
, cast(null as datetime2) lead_update_confirmed
, a.[productType]
, a.isBigInstallment
from analytics.dbo.v_request_external a  with(nolock)
left join lead_external b on a.id=b.id and a.hash =b.hash  and b.lead_update_confirmed is not null
where b.id is null and a.created>=getdate()-1


end


 
 --alter table lead_external add [productType] varchar(255)
 --alter table lead_external add [isBigInstallment] tinyint

--drop table if exists lead_external
--select * into lead_external from #lead_external
--delete from lead_external 
insert into lead_external
select * from #lead_external 






drop table if exists #upd
select a.id, case when b.id is null then 1 end for_upd, case when a.hash =  b.external_hash then 1 end del
, datediff(second, b.UF_REGISTERED_AT , a.link_created  ) external_link_sla 
, a.guid
, a.sum
, a.hash
, a.[productType]
, a.isBigInstallment

into #upd from #lead_external a
left join lead b on a.id=b.id-- and a.hash = b.external_hash 

 delete from #upd where del=1


 --alter table lead add external_hash varbinary(8000)
 --alter table lead add external_link_sla int

 --alter table lead add productTypeExternal varchar(255)
 
						 
declare @a [carm\p.ilin].leadtype 

insert into  @a
  select  id from 	#upd where for_upd=1
exec lead_creation 		@a, null
 


 update a set a.external_link_sla=b.external_link_sla  , a.row_updated=getdate(), a.sum = b.sum, a.external_hash = b.hash, a.productTypeExternal = b.productType,  a.isBigInstallment = b.isBigInstallment  from feodor.dbo.[lead] a join #upd b on a.id=b.id
 update a set a.lead_update_confirmed= getdate() from #lead_external  a join [lead] b on a.id=b.id and a.hash =b.external_hash 
 update a set a.lead_update_confirmed=b.lead_update_confirmed from  lead_external  a join #lead_external b on a.guid=b.guid
 update a set a.lead_update_confirmed=dateadd(second, -1, b.lead_update_confirmed) from  lead_external  a join #lead_external b on a.id=b.id and a.lead_update_confirmed is null



  
 -- alter table lead add has_call_weighted_attribution tinyint
 -- alter table lead add is_abandoned tinyint
 -- alter table lead add is_autoanswer tinyint
 -- alter table lead add connected_last datetime2
 -- alter table lead add isBigInstallment tinyint
