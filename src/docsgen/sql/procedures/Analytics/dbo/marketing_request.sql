CREATE proc marketing_request as 



drop table if exists #t1
;
with  request_
as (
select 
  number
, original_lead_id original
, source origin
, b.code product
, marketing_lead_id marketing
, mobile_phone phone
, cast(a.created_at_time as datetime2(0)) created 
, cast(a.updated_at_time as datetime2(0)) updated 
, date  
, a.id  
from stg._lf.request   a
left join stg._lf.product_type	   b on a.product_type_id=b.id
	  
	  ), lead_ as (

select 
  lead.created_at_time			 
, cast(lead.created_at_time as datetime2(0)) created 
,dateadd(hour,  3,  dateadd(second, lead.updated_at   , '19700101'  ))				   updated_at2
, lead.phone   
, lead.name   
, lead.required_sum sum
, lead.id
, lead.client_id
, lead.visit_id
, dc.name  decline
, dc.name  decline_reason
, mms_priority
, lead.status_id	 status_id
, status.technical_name	 status
, status.marketing_name	 marketing_status
, lead.type_code  type
, lead.source_id
, e.name entrypoint
,  product_type_code
, cast( source_account.name as nvarchar(250)) source 
, isnull(lead.partner_id, stat_info) partner_id
, mms_channel.name	[channel]
, mms_channel_group.name	[channel_group]

, pt.name product
, pt.name product_code
, r.name region
, v.stat_system stat_system
, v.stat_type stat_type 
, v.stat_campaign stat_campaign
, v.stat_info stat_info 
, v.stat_term stat_term
, v.stat_source stat_source
, va.tracker_name  appmetrica 
, v.appmetrica_event_id
, cast( va.updated_at_time as datetime2(0))  appmetrica_updated

from stg._lf.lead	lead
left join stg._lf.lead_status status on status.id=lead.status_id
left join stg._lf.mms_channel on mms_channel.id=lead.mms_channel_id
left join stg._lf.mms_channel_group on mms_channel_group.id=lead.mms_channel_group_id
left join stg._lf.source_account on source_account.id=lead.source_id
left join stg._lf.entrypoint e on e.id=lead.entrypoint_id
left join stg._lf.product_type pt on pt.id=lead.product_type_id
left join stg._lf.region r on r.id=lead.region_id 
left join stg._lf.mms_decline_reason  dc on dc.id=lead.mms_decline_reason_id 
left join stg._lf.referral_visit v on v.id=lead.visit_id
left join stg._lf.referral_appmetrica_event  va on  va.id=v.appmetrica_event_id

 
 ), visit_ as (   select 
    a.[id] 								 
, cast(a.created_at_time as datetime2(0)) created 

,   b.name  [source] 
,   a.[created_type]  [type]
,   a.[client_id] 
,   a.[referer] 
,   a.[stat_source] 
,   a.[client_yandex_id] 
,   a.[client_google_id] 
,   a.[click_yandex_id] 
,   a.[click_google_id] 
,   a.[stat_system] 
,   a.[stat_type] 
,   a.[stat_campaign] 
,   a.[stat_info] 
,   a.[stat_term] 
,   a.[page] 
,   a.[comagic_vid] 
,   a.[ip] 
,   a.[userAgent] 
,   a.[language] 
,   a.[platform] 
,   a.[adriverPostView] 
,   a.[jivoVid] 
,   a.[appmetrica_event_id] 
,   a.[created_at] 
,   a.[updated_at] 
,   a.[DWHInsertedDate] 
,   a.[ProcessGUID] 
,   a.[updated_at_time] 
,   a.[UPDATED_BY] 
,   a.[UPDATED_DT] 

from 

Stg._LF.referral_visit a
left join stg._lf.source_account b on a.source_id=b.id
 )
--exec select_table 'visit', 'stg'



SELECT  
    [number]       = a.[number] 
,   [created] 	 = a.[created] 
,   [phone] 		 = a.[phone] 
,   [origin]  	 = a.[origin]  
,   [product_type] 	 = a.[product] 
,   [id] 			 = a.[id] 
, lead_id =   a.[marketing]  
, lead_created =   b.created 
, request_created =   a.[date]    
,[updated] =    a.[updated] 
, source =    b.source 
, [lead_name] =    b.name  
, [lead_prduct_type] =    b.product_code
, [lead_sum] =   b.[sum]  
,[client_id]   = b.[client_id] 
,[entrypoint]   = b.[entrypoint] 
,[partner_id]   = b.[partner_id] 
,[channel]   = b.[channel] 
,[channel_group]    = b.[channel_group]  
,[stat_system]   = b.[stat_system] 
,[stat_type]   = b.[stat_type] 
,[stat_campaign]   = b.[stat_campaign] 
,[stat_info]   = b.[stat_info] 
,[stat_term]   = b.[stat_term] 
,[stat_source]   = b.[stat_source] 
,[appmetrica]   = b.[appmetrica] 
,[visit_id]   = b.[visit_id] 
,   [visit_created]  =  v.created        
, visit_source =   v.source 
,   visit_stat_source = v.stat_source 
,  [visit_page]      =  v.[page]         
,  [visit_referer]   = v.[referer] 	 
,  [visit_userAgent] =   v.[userAgent] 	 
,  [visit_platform]  =    v.[platform]   	 
,  [region] =   b_original.[region] 
,  original_lead_id =  a.[original] 
,   original_lead_created = b_original.created 
, original_lead_updated=   b_original.updated_at2 
, appmetrica_event_id =   b.appmetrica_event_id 
, appmetrica_updated =   b.appmetrica_updated 
, lead_updated =   b.updated_at2 

into #T1
 FROM 

 request_ a with(nolock)
		left join lead_ b with(nolock) on a.[marketing]=b.id
		left join lead_ b_original with(nolock) on a.[marketing]=b_original.id
		left join visit_ v with(nolock) on v.id=b.visit_id
		where a.date>='20240425'
		--order by a.[date] 


		select * from #t1






		   --SELECT 
     --     *
     --       FROM 

     --       Stg._LF.v1_core_external_request_link a