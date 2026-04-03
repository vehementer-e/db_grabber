CREATE proc [dbo].[_request_lead_updater] as
declare @dt  datetime2 = getdate()
declare @hourly  bigint 


set @hourly = 1


if eXISTS (
select top 1 * from jobh where id='0A6E6967-71FE-4F2E-90C9-83AF9452CAB1' and step_id=1 and succeeded>= format( getdate()   , 'yyyy-MM-dd HH:00:00')  ) 
set @hourly=0


--declare @hourly  bigint = case when datepart(minute, getdate()) <=5 then 1 end
declare @dayly  bigint = 0
if not exists (
select  top 1 * from jobh where command like '%' + '_request_lead_updater' + '%' and succeeded>=cast(getdate() as date) ) set @dayly=1
--alter table _request add  originalLeadId nvarchar(36)
--alter table _request_log add  originalLeadId nvarchar(36)

--select * from dwh where table_name=   '_request'  
--ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN source nvarchar(50)
--ALTER TABLE Analytics.dbo.[_request_log] ALTER COLUMN source nvarchar(50)
--alter table _request add entrypoint nvarchar(10)
--alter table _request_log add entrypoint nvarchar(10)
--alter table _request add source nvarchar(10)
--alter table _request_log add source nvarchar(10)

 --update aa set     aa.source = b.uf_source   from _request aa  join   stg._lcrm.lcrm_leads_full_channel_request b on b.id=aa.leadId  and b.uf_source not in ('') and isnumeric(aa.leadid)=1 and len( b.uf_source ) <=40
 --update aa set     aa.source = b.uf_source   from _request aa  join   stg._lcrm.lcrm_leads_full_channel_request b on b.uf_row_id=aa.number and b.uf_source not in ('') and isnumeric(aa.leadid)=1 and len( b.uf_source ) <=40 and  aa.source  is null
 
 --update aa set aa.entrypoint = a.entrypoint  from _request aa  join  v_lead2  a	with(nolock) on aa.leadid=a.id  and aa.entrypoint is null  and aa.created>='20240425'   
 --update aa set    aa.source =  a.source from _request aa  join  v_lead2   a  with(nolock)	on aa.leadid=a.id  and aa.source is null  and a.source is not null  and aa.created>='20240425'  
 
 --alter table _request add lastCommunicationCreated datetime2(0)
 --alter table _request_log add lastCommunicationCreated datetime2(0)


 --alter table _request add parentGuid nvarchar(36)
 --alter table _request_log add  parentGuid nvarchar(36)

--ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN closedDpdBeginDay smallint null
--ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN DpdBeginDay smallint		 null
--ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN DpdMaxBeginDay smallint	 null
--ALTER TABLE Analytics.dbo.[_request_log] ALTER COLUMN closedDpdBeginDay smallint null
--ALTER TABLE Analytics.dbo.[_request_log] ALTER COLUMN DpdBeginDay smallint		 null
--ALTER TABLE Analytics.dbo.[	] ALTER COLUMN DpdMaxBeginDay smallint	 null

--alter table _request     add lastLoaylCommunicationCreated datetime2(0)
--alter table _request_log add lastLoaylCommunicationCreated datetime2(0)


--alter table _request     add rbp nvarchar(50)
--alter table _request_log add rbp nvarchar(50)



--alter table _request     add dpdDays int
--alter table _request_log add dpdDays int



--alter table _request     add channel nvarchar(30)
--alter table _request_log add channel nvarchar(30)

--alter table _request     add channelConfirmed datetime2(0)
--alter table _request_log add channelConfirmed datetime2(0)


 --update aa set     aa.channel = b.[канал от источника]   from _request aa  join   stg._lcrm.lcrm_leads_full_channel_request b on b.id=aa.leadId  and b.[канал от источника]<>'' and isnumeric(aa.leadid)=1-- and len( b.uf_source ) <=40
 --update aa set     aa.channel = b.[канал от источника]   from _request aa  join   stg._lcrm.lcrm_leads_full_channel_request b on  b.uf_row_id=aa.number  and b.uf_source not in ('') and isnumeric(aa.leadid)=1 and aa.channel is null
 --update aa set     aa.channel = b.channel   from _request aa  join   v_lead2 b on  b.id=aa.leadId  and aa.channel is null
 --update aa set     aa.channel = b.channel  , aa.channelConfirmed = getdate() from _request aa  join   v_fa b on  b.number=aa.number 


 
--alter table _request add originaLentrypoint nvarchar(36)
--alter table _request_log add originaLentrypoint nvarchar(36)

 
--alter table _request add clientCategoryPts nvarchar(36)
--alter table _request_log add clientCategoryPts nvarchar(36)
--alter table _request add clientLimitPts int
--alter table _request_log add clientLimitPts int

--alter table _request add clientMaxDpdPts tinyint
--alter table _request_log add clientMaxDpdPts tinyint


 

--alter table _request add clientMaxDpdBezzalog smallint
--alter table _request_log add clientMaxDpdBezzalog smallint
--alter table _request add clientMaxDpdPts smallint
--alter table _request_log add clientMaxDpdPts smallint




 
--alter table _request add clientCategoryBezzalog nvarchar(36)
--alter table _request_log add clientCategoryBezzalog nvarchar(36)
--alter table _request add clientLimitBezzalog int
--alter table _request_log add clientLimitBezzalog  int

--alter table _request add thikHit int
--alter table _request_log add thikHit  int



--alter table _request     add firstLoanRbp nvarchar(50)
--alter table _request_log add firstLoanRbp nvarchar(50)

--alter table _request     add firstLoanNumber nvarchar(30)
--alter table _request_log add firstLoanNumber nvarchar(30)



--alter table _request     add checkingSla  [decimal](38, 10)
--alter table _request_log add checkingSla  [decimal](38, 10)


--alter table _request     add partnerId nvarchar(255)
--alter table _request_log add partnerId nvarchar(255)





if  @dayly = 0 begin
update aa set aa.leadId = coalesce(a.marketing_lead_id,  cast(a.lcrmID as nvarchar(36)), lk.lead_Id) 
--, aa.row_updated= @dt  
, aa.row_updated= getdate() 
, aa.originalLeadId = coalesce(a.original_lead_id,  lk.lead_Id ,  cast(a.lcrmID as nvarchar(36))  ) 
, aa.entrypoint = r.entrypoint
, aa.channel = case when aa.channelConfirmed is not null  then aa.channel else r.channel end
, aa.source = case when r.source is not null then r.source else a.source end 
, aa.partnerId = r.[partnerId]
from request aa 
join  v_request a	on aa.guid=a.guid    
left join v_request_lk lk on lk.id=aa.id 
left join v_request_lf2 	r on r.guid=a.guid--r.number=a.number
where 
(
coalesce(a.marketing_lead_id,  cast(a.lcrmID as nvarchar(36)), lk.lead_Id)  <> isnull(aa.leadId, '-1') 
or 
coalesce(a.original_lead_id,  lk.lead_Id ,  cast(a.lcrmID as nvarchar(36))  )   <> isnull(aa.originalLeadId, '-1') 
or  
isnull(aa.entrypoint , '')<> r.entrypoint 
or isnull(aa.source, '')<> r.source
or ( isnull(aa.channel, '')<> r.[channel] and aa.channelConfirmed is null )
)

and aa.created2>=getdate()-30 
if @hourly =1 begin

 update aa set 
aa.originaLentrypoint = a.entrypoint
--, aa.row_updated= @dt  
--, aa.row_updated= getdate() 
 
from request aa 
join  v_lead2  a	with(nolock) on aa.originalLeadid=a.id  and aa.originaLentrypoint is null   and aa.created2>=getdate()-30 

 update aa set 
  aa.source =  a.source
, aa.partnerId= a.partner_Id 
, aa.row_updated= @dt  
--, aa.row_updated= getdate() 
from _request aa 
join  v_lead2  a	with(nolock) on aa.leadid=a.id  and aa.source is null  and a.source is not null  and aa.created>=getdate()-30

 update aa set     aa.channel = b.channel  , aa.channelConfirmed = getdate() from _request aa  join   v_fa b on  b.number=aa.number and isnull(aa.channel, '' )<> b.channel

 
update fa1 set fa1.isManualTakeUp =1  
from
v_communication_crm communication
join  _request fa1 on communication.number=fa1.number and fa1.approved is not null  and isSuccessfull=1  and communication.created >=approved and  communication.created <=isnull(fa1.issued, dateadd(day, 10, fa1.approved)) 
join stg.files.[сотрудники sales_stg]   o on communication.seller  =  o.сотрудник
 where fa1.isManualTakeUp is null and fa1.approved>=getdate()-30


 update b set b.parentGuid = a.[request_source_guid]
 from 
 lk_request_uniapi a join _request b on a.id=b.id  and b.parentguid is null and  a.[request_source_guid] is not null

 
 update b set b.rbp = a.rbp_gr
 from 
 [dwh2].[dbo].[v_risk_apr_segment]  a join _request b on a.number=b.number and b.rbp  is null and  a.rbp_gr is not null and b.call1>=getdate()-30



drop table if exists #thikhit
select   guid, THICK_HIT, call_date, userName
into #thikhit
 from stg._loginom.Originationlog with(nolock)
 where THICK_HIT is not null --and call_date>=getdate()-3


 ;with v  as (select *, row_number() over(partition by guid order by call_date desc) rn from #thikhit ) delete from v where rn>1


  update r set r.thikHit = THICK_HIT from _request r join #thikhit b on r.guid=b.guid


  if  (select count(distinct type) from _client_history where date = cast( getdate()  as date) )<>5

exec _client_history_creation

  
  
  exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '615B9902-77A6-4B5E-A7E4-D791D47F4B4B'

 --select * from [dwh2].[dbo].[v_risk_apr_segment]  where number='23032220808264'
  

 /*
drop table if exists #t2788282392 
select * into #t2788282392 from openquery (lkprod , 'select id,  request_source_guid from requests where request_source_guid is not null' ) 
update b set b.parentGuid = a.[request_source_guid]
from 
 #t2788282392 a join _request b on a.id=b.id  and b.parentguid is null and  a.[request_source_guid] is not null



--SELECT 
--           a.[id] ,   a.[num_1c] ,   a.[created_at] ,   a.[request_source_guid] ,   a.[lead_request_guid] ,   a.[request_source_lead_request_guid] ,   a.[request_source_product_type_guid] ,   a.[request_source_product_sub_type_guid] ,   a.[uprid_date] ,   a.[request_source_is_consents_received] ,   a.[is_ready_to_deposit] FROM Analytics.dbo.[lk_request_uniapi] a
*/

end



end else begin 


exec _client_history_creation




exec _request_product 60
 
 update aa set aa.leadId = coalesce(a.marketing_lead_id,  cast(a.lcrmID as nvarchar(36)), lk.lead_Id) 
, aa.row_updated= @dt  
--, aa.row_updated= getdate() 
, aa.originalLeadId = coalesce(a.original_lead_id,  lk.lead_Id ,  cast(a.lcrmID as nvarchar(36))  ) 
, aa.entrypoint = r.entrypoint
--, aa.channel = r.channel
, aa.source = case when r.source is not null then r.source else a.source end 
, aa.partnerId = r.partnerId
from _request aa 
join  v_request a	on aa.guid=a.guid    
left join v_request_lk lk on lk.id=aa.id 
left  join v_request_lf2 	r on r.guid=a.guid--r.number=a.number
where 
(
coalesce(a.marketing_lead_id,  cast(a.lcrmID as nvarchar(36)), lk.lead_Id)  <> isnull(aa.leadId, '-1') 
or 
coalesce(a.original_lead_id,  lk.lead_Id ,  cast(a.lcrmID as nvarchar(36))  )   <> isnull(aa.originalLeadId, '-1') 
or  
isnull(aa.entrypoint , '')<> r.entrypoint 
or isnull(aa.source, '')<> r.source
--or ( isnull(aa.channel, '')<> r.channel and aa.channelConfirmed is null )
)

and aa.created>='20240425'


;

with comm as (
select phone, created, 'crm' type   from v_communication_crm  where isSuccessfull =1 union all  select phone, created, 'feodor' type from v_communication_feodor where isSuccessfull =1
)  , req as ( select guid,   cast( max(b.created)  as datetime2(0))     lastCommunicationCreated
from 
_request  a left join comm b on
a.phone=b.phone and b.created between dateadd(day, -90 , isnull( a.call1 , a.created) )  and isnull( a.call1 , a.created)
 --and  isnull( a.call1 , a.created)>=getdate()-30 
 group by a.guid 
)
 update _request set _request.lastCommunicationCreated= req.lastCommunicationCreated from _request join req on _request.guid=req.guid 
 and isnull(_request.lastCommunicationCreated, getdate())<>   isnull(req.lastCommunicationCreated, getdate())

 ;

with comm as (
select  right(client_number, 10) phone, attempt_start  created  from reports.dbo.dm_report_DIP_detail_outbound_sessions
where login is not null
)  , req as ( select guid, cast( max(b.created)  as datetime2(0))  lastLoyalCommunicationCreated
from 
_request  a left join comm b on
a.phone=b.phone and b.created between dateadd(day, -90 , isnull( a.call1 , a.created) )  and isnull( a.call1 , a.created)
 --and  isnull( a.call1 , a.created)>=getdate()-30 
 group by a.guid 
)
 update _request set _request.lastLoyalCommunicationCreated= req.lastLoyalCommunicationCreated from _request join req on _request.guid=req.guid
 and isnull(_request.lastLoyalCommunicationCreated, getdate())<>   isnull(req.lastLoyalCommunicationCreated, getdate())


 exec marketingSourceIntersection

-- select * from dwh where column_name = 'lastLoaylCommunicationCreated'
-- EXEC sp_rename 'Analytics.dbo._request_log.lastLoaylCommunicationCreated', 'lastLoyalCommunicationCreated'
--EXEC sp_rename 'Analytics.dbo._request.lastLoaylCommunicationCreated', 'lastLoyalCommunicationCreated'
 --select * from _request
 --order by created desc

 --drop table if exists #calls
 --select attempt_start,   client_number into 	#calls from reports.dbo.dm_report_DIP_detail_outbound_sessions
 --where login is not null






 if not  exists (select top 1 * from v_balance where date = cast( getdate()  as date)  and dpd>0 ) begin exec log_email '!!! CRITICAL ERROR balance not calculated' select 1/0 return end
	drop table if exists #dpd_closed
	select number number
	, max(case when date=cast( getdate() as date)  then dpd_begin_day end ) DpdBeginDay  
	, max(case when date=closed then dpdBeginDay end ) closedDpdBeginDay  
	, max(   dpdBeginDay   ) DpdMaxBeginDay  
 
	into #dpd_closed from v_balance a --where date=closed
	group by number

	select a.number, datediff( day,  max(case when a.dpd_begin_day =0 then date end) , getdate()) dpdDays into #dpd from v_balance a join  #dpd_closed b on a.number=b.number
where b.DpdBeginDay>0
group by  a.number

drop table if exists #dpd_closed1
select a.number , max(a.DpdBeginDay )  DpdBeginDay,  max(a.closedDpdBeginDay   ) closedDpdBeginDay ,   max(a.DpdMaxBeginDay  )  DpdMaxBeginDay , datediff( day,  max(case when b.dpdBeginDay =0 then date end) , getdate()) dpdDays 
into #dpd_closed1

from #dpd_closed a left join  v_balance b   on a.number=b.number and a.DpdBeginDay>0
group by  a.number


--select * from #dpd_closed1


	drop table if exists #dpd_closed0
	select * into #dpd_closed0 from #dpd_closed1  where 1=0

	--exec sp_select_except '#dpd_closed', '_request', 'number', '#dpd_closed'
	
    INSERT INTO #dpd_closed0 ([closedDpdBeginDay], [DpdBeginDay], [DpdMaxBeginDay], [number], dpdDays)
    SELECT [closedDpdBeginDay], [DpdBeginDay], [DpdMaxBeginDay], [number], dpdDays
    FROM  #dpd_closed1
    EXCEPT
    SELECT [closedDpdBeginDay], [DpdBeginDay], [DpdMaxBeginDay], [number], dpdDays
    FROM _request
    WHERE _request.number IN (
        SELECT number
        FROM   #dpd_closed1
    );
	update _request set  

	  _request.[closedDpdBeginDay]  =  d.[closedDpdBeginDay]
	, _request.[DpdBeginDay] 	   =   d.[DpdBeginDay] 	  
	, _request.[DpdMaxBeginDay]    =   d.[DpdMaxBeginDay]   
	, _request.dpdDays             =   d.dpdDays   
	 --, _request.row_updated = @dt
	from _request join #dpd_closed1 d	  on d.number = _request.number

	
	update _request set  

	  _request.[closedDpdBeginDay]  = null
	, _request.[DpdBeginDay] 	   =  null
	, _request.[DpdMaxBeginDay]    =  null
	, _request.dpdDays    =  null
	--, _request.row_updated = @dt
	from _request left join #dpd_closed1 d	  on d.number = _request.number
	where d.number  is null and isnull(isnull(isnull(   _request.[closedDpdBeginDay] 
		, _request.[DpdBeginDay] 	 )   
		, _request.[DpdMaxBeginDay]    )
		, _request.dpdDays    )
		is not null 

		 

drop table if exists #reqCLientHistPts
		select a.guid, b.category, b.limit,   b.date, b.type, datediff(day, b.date,  isnull(a.call1, a.created) ) dif into #reqCLientHistPts from  _request a 
		join  client_history b on a.clientId=b.clientId
		and b.date between cast( dateadd(day, -10,   isnull(a.call1, a.created)  ) as date)  and  cast( isnull(a.call1, a.created)    as date)
		and 1=b.ispts
		and a.returnType=b.returnType

		;with v  as (select *, row_number() over(partition by guid order by dif , limit desc) rn from #reqCLientHistPts ) delete from v where rn>1
		 
drop table if exists #reqCLientHistBezzalog
		select a.guid, b.category, b.limit,   b.date, b.type, datediff(day, b.date,  isnull(a.call1, a.created) ) dif into #reqCLientHistBezzalog from  _request a 
		join  client_history b on a.clientId=b.clientId
		and b.date between cast( dateadd(day, -10,   isnull(a.call1, a.created)  )  as date) and  cast( isnull(a.call1, a.created)    as date)
		and 0=b.ispts
		and a.returnType=b.returnType

		;with v  as (select *, row_number() over(partition by guid order by dif , limit desc) rn from #reqCLientHistBezzalog ) delete from v where rn>1
		 
		--select distinct returnType from _request
		--select distinct returnType from client_history


		--select * from #reqCLientHist
update a set a.clientCategoryPts = b.category,  a.clientLimitPts = b.limit   from  _request a   join  #reqCLientHistPts b  on a.guid=b.guid  
update a set a.clientCategoryBezzalog = b.category,  a.clientLimitBezzalog = b.limit   from  _request a   join  #reqCLientHistBezzalog b  on a.guid=b.guid  

drop table if exists #reqCLientDpd

select a.guid
, max(case when  b.ispts=1 then c.dpdBeginDay end   ) clientMaxDpdPts
, max(case when   b.ispts=0 then c.dpdBeginDay end  ) clientMaxDpdBezzalog
into #reqCLientDpd
from  _request a  
join _request b on a.clientId=b.clientId and a.guid<>b.guid
join v_balance c on c.number=b.number and  c.date<cast( isnull(a.call1, a.created)   as date) 
group by  a.guid

update a set a.clientMaxDpdPts = b.clientMaxDpdPts,  a.clientMaxDpdBezzalog = b.clientMaxDpdBezzalog   from  _request a   join  #reqCLientDpd b  on a.guid=b.guid  


--update a set a.checkingSla = null  from  _request a   join  #checkingSla b  on a.number=b.number  
--drop table if exists #checkingSla
--select number, sum(time) checkingSla into #checkingSla from v_verification where  status='контроль данных' and type   in ('В работе', 'Ожидание',  'Отложено')
--group by number
--update a set a.checkingSla = b.checkingSla   from  _request a   join  #checkingSla b  on a.number=b.number  


drop table if exists #checkingSla
select number, sum(time) checkingSla into #checkingSla from v_verification where requestDate>=getdate()-30 and status='контроль данных' and type   in ('В работе', 'Ожидание',  'Отложено')
group by number
update a set a.checkingSla = b.checkingSla   from  _request a   join  #checkingSla b  on a.number=b.number  
 



--select top 100 * from _request
--select * from #reqCLientDpd

--select * from dwh where table_name='_request' and column_name like '%' + 'category' + '%'  

--EXEC sp_rename 'Analytics.dbo._request.clientCategory', 'clientCategoryPts'
--EXEC sp_rename 'Analytics.dbo._request.clientLimit', 'clientLimitPts'
	--select * from dwh where table_name='_request'
	 exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '615B9902-77A6-4B5E-A7E4-D791D47F4B4B'
 

end


