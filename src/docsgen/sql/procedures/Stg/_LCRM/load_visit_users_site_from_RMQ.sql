--exec [load_visit_users_site_from_RMQ]
CREATE   procedure [_LCRM].[load_visit_users_site_from_RMQ]
as

-- 22042020 Выкачиваем stg

begin


set nocount on 

-- Обновление из очереди

truncate table [_LCRM].[lcrm_queue_visite_site_update]

if object_id('tempdb.dbo.#t')  is not null drop table #t
  	  select --top 10 --l.*
	       [message_guid]
      ,[message_type]
      ,[state]
	  ,[publishTime]
      ,[version]
      ,[docUrl]
      ,[props_guid]
      --,[data]
      ,[data_publisher]
      ,[data_scheme]
      ,[data_publishTime]
      ,[data_guid]
      ,[data_type]
      ,[data_state]
      ,[data_version]
      ,[data_docUrl]
     -- ,[data_data]
      ,[TypeClientdatacreated]
      ,[TypeClientdataguid]
      ,[TypeClientdataupdated]
      ,[TypeVisit_created]
      ,[TypeVisit_updated]
      ,[TypeVisit_guid]
      ,[TypeVisit_adriverPostView]
      ,[TypeVisit_clickGoogleId]
      ,[TypeVisit_clickYandexId]
      --,[TypeVisit_client]
      ,[TypeVisit_clientGoogleId]
      ,[TypeVisit_clientYandexId]
      ,[TypeVisit_comagicVid]
      ,[TypeVisit_jivoVid]
      ,[TypeVisit_language]
      ,[TypeVisit_page]
      ,[TypeVisit_platform]
      ,[TypeVisit_referer]
      ,[TypeVisit_statCampaign]
      ,[TypeVisit_statFrom]
      ,[TypeVisit_statInfo]
      ,[TypeVisit_statSource]
      ,[TypeVisit_statSystem]
      ,[TypeVisit_statTerm]
      ,[TypeVisit_statType]
      ,[TypeVisit_userAgent]
      ,[TypeVisit_client_type]
      ,[TypeVisit_client_ref_type]
      ,[TypeVisit_client_guid]
      into #t
	  --FROM [RMQ].[ReceivedMessages] with(nolock)
	  FROM RMQ.ReceivedMessages_CRIB_ModelVisit with(nolock)
	   outer apply  OPENJSON(ReceivedMessage, '$')
  with (
         publisher nvarchar(100) '$.publisher'
        ,scheme  nvarchar(100) '$.scheme'
        ,publishTime  nvarchar(100) '$.publishTime'
        ,message_guid  nvarchar(100) '$.guid'
        ,message_type  nvarchar(100) '$.type'
        ,state  nvarchar(100) '$.state'
        ,version nvarchar(100) '$.version' 
        ,docUrl  nvarchar(100) '$.docUrl'
		,props_guid  nvarchar(100) '$.props.guid'
        ,data nvarchar(max) '$.data' as JSOn
       ) l 
       outer apply OPENJSON(l.data, '$')
	   with(

         data_publisher nvarchar(100) '$.publisher'
        ,data_scheme  nvarchar(100) '$.scheme'
        ,data_publishTime  nvarchar(100) '$.publishTime'
        ,data_guid nvarchar(100) '$.guid'
        ,data_type nvarchar(100) '$.type'
        ,data_state  nvarchar(100) '$.state'
        ,data_version nvarchar(100) '$.version' 
        ,data_docUrl  nvarchar(100) '$.docUrl'
        ,data_data nvarchar(max) '$.data' as JSOn
) m
 outer apply OPENJSON(m.data_data, '$')
          with(

-- если data_type='client'  тогда поля:
           TypeClientdatacreated  nvarchar(100) '$.created'
          ,TypeClientdataguid     nvarchar(100) '$.guid'
          ,TypeClientdataupdated  nvarchar(100) '$.updated'

---- если data_type='visit'  тогда поля:
,
TypeVisit_created	              nvarchar(100)	'$.created',
TypeVisit_updated	              nvarchar(100)	'$.updated',
TypeVisit_guid	                nvarchar(100)	'$.guid',
--,dataadriverPostView,
TypeVisit_adriverPostView	      nvarchar(100)	'$.adriverPostView',
--dataclickGoogleId
TypeVisit_clickGoogleId	        nvarchar(100)	'$.clickGoogleId',
--,dataclickYandexId,
TypeVisit_clickYandexId	        nvarchar(100)	'$.clickYandexId',
--dataclienttype,
--dataclientref_type,
--dataclientguid,
TypeVisit_client	              nvarchar(max)	'$.client' as json,

--dataclientGoogleId,
TypeVisit_clientGoogleId	      nvarchar(100)	'$.clientGoogleId',
--dataclientYandexId,
TypeVisit_clientYandexId	      nvarchar(100)	'$.clientYandexId',
--datacomagicVid,
TypeVisit_comagicVid	          nvarchar(100)	'$.comagicVid',
--datajivoVid,
TypeVisit_jivoVid	              nvarchar(100)	'$.jivoVid',


--
--datalanguage
TypeVisit_language	            nvarchar(100)	'$.language',
--,datapage
TypeVisit_page	                nvarchar(200)	'$.page',
--,dataplatform,
TypeVisit_platform	            nvarchar(100)	'$.platform',
--datareferer,
TypeVisit_referer	              nvarchar(300)	'$.referer',
--datastatCampaign
TypeVisit_statCampaign	        nvarchar(100)	'$.statCampaign',
--,datastatFrom,
TypeVisit_statFrom	            nvarchar(100)	'$.statFrom',
--datastatInfo,
TypeVisit_statInfo	            nvarchar(100)	'$.statInfo',
--datastatSource,
TypeVisit_statSource	          nvarchar(100)	'$.statSource',
--datastatSystem,
TypeVisit_statSystem	          nvarchar(100)	'$.statSystem',
--datastatTerm,
TypeVisit_statTerm	            nvarchar(100)	'$.statTerm',
--datastatType,
TypeVisit_statType	            nvarchar(100)	'$.statType',

--datauserAgent
TypeVisit_userAgent	            nvarchar(300)	'$.userAgent'


)n
         outer apply OPENJSON(n.TypeVisit_client ,'$')
         with 
              (
              TypeVisit_client_type       nvarchar(100) '$.ref',
              TypeVisit_client_ref_type   nvarchar(100) '$.ref_type',
              TypeVisit_client_guid       nvarchar(100) '$.guid'
            ) o
  where FromQueue = 'DWH.CRIB.ModelVisitOnUpdate' and
  [ReceiveDate] >  dateadd(day,-1,getdate())
--and 
  --and ReceiveDate > '2020-04-10'
  --and data_version='1586941067'
;
  
with row_data as (
select 
message_guid
,data_type
,[state]
,[publishTime]



, TypeClientdatacreated =case when data_type='client' then TypeClientdatacreated else '' end
, TypeClientdataguid    =case when data_type='client' then TypeClientdataguid    else '' end
, TypeClientdataupdated =case when data_type='client' then TypeClientdataupdated else '' end
, TypeVisit_adriverPostView	=case when data_type='visit' then TypeVisit_adriverPostView else '' end
, TypeVisit_clickGoogleId	  =case when data_type='visit' then TypeVisit_clickGoogleId else '' end	    
, TypeVisit_clickYandexId	  =case when data_type='visit' then TypeVisit_clickYandexId else '' end	    
--, TypeVisit_client	        =case when data_type='visit' then TypeVisit_client  else '' end	          
, TypeVisit_clientGoogleId	=case when data_type='visit' then TypeVisit_clientGoogleId else '' end	  
, TypeVisit_clientYandexId	=case when data_type='visit' then TypeVisit_clientYandexId else '' end	  
, TypeVisit_comagicVid	    =case when data_type='visit' then TypeVisit_comagicVid else '' end	      
, TypeVisit_created	        =case when data_type='visit' then TypeVisit_created else '' end	          
, TypeVisit_guid	          =case when data_type='visit' then TypeVisit_guid else '' end	            
, TypeVisit_jivoVid	        =case when data_type='visit' then TypeVisit_jivoVid else '' end	          
, TypeVisit_language	      =case when data_type='visit' then TypeVisit_language else '' end	        
, TypeVisit_page	          =case when data_type='visit' then TypeVisit_page else '' end	            
, TypeVisit_platform	      =case when data_type='visit' then TypeVisit_platform else '' end	        
, TypeVisit_referer	        =case when data_type='visit' then TypeVisit_referer else '' end	          
, TypeVisit_statCampaign	  =case when data_type='visit' then TypeVisit_statCampaign else '' end	    
, TypeVisit_statFrom	      =case when data_type='visit' then TypeVisit_statFrom else '' end	        
, TypeVisit_statInfo	      =case when data_type='visit' then TypeVisit_statInfo else '' end	        
, TypeVisit_statSource	    =case when data_type='visit' then TypeVisit_statSource else '' end	      
, TypeVisit_statSystem	    =case when data_type='visit' then TypeVisit_statSystem else '' end	      
, TypeVisit_statTerm	      =case when data_type='visit' then TypeVisit_statTerm else '' end	        
, TypeVisit_statType	      =case when data_type='visit' then TypeVisit_statType else '' end	        
, TypeVisit_updated	        =case when data_type='visit' then  TypeVisit_updated else '' end	          
, TypeVisit_userAgent	      =case when data_type='visit' then TypeVisit_userAgent else '' end	        
, TypeVisit_client_type	    =case when data_type='visit' then TypeVisit_client_type else '' end    
, TypeVisit_client_ref_type	=case when data_type='visit' then TypeVisit_client_ref_type else '' end
, TypeVisit_client_guid	    =case when data_type='visit' then TypeVisit_client_guid else '' end    


from #t t

)

, client as (
select message_guid
,[state]
,[publishTime]
, TypeClientdatacreated 
, TypeClientdataguid    
, TypeClientdataupdated 
from row_data where data_type='client'
)
,visit as (
select message_guid
, TypeVisit_adriverPostView	
, TypeVisit_clickGoogleId	  
, TypeVisit_clickYandexId	  
--, TypeVisit_client	        
, TypeVisit_clientGoogleId	
, TypeVisit_clientYandexId	
, TypeVisit_comagicVid	    
, TypeVisit_created	        
, TypeVisit_guid	          
, TypeVisit_jivoVid	        
, TypeVisit_language	      
, TypeVisit_page	          
, TypeVisit_platform	      
, TypeVisit_referer	        
, TypeVisit_statCampaign	  
, TypeVisit_statFrom	      
, TypeVisit_statInfo	      
, TypeVisit_statSource	    
, TypeVisit_statSystem	    
, TypeVisit_statTerm	      
, TypeVisit_statType	      
, TypeVisit_updated	        
, TypeVisit_userAgent	      
, TypeVisit_client_type	    
, TypeVisit_client_ref_type	
, TypeVisit_client_guid	    
from row_data where data_type='visit'
)

insert into [_LCRM].[lcrm_queue_visite_site_update]
select 
  client.message_guid
, client.[state]
, client.[publishTime]
, TypeClientdatacreated 
, TypeClientdataguid    
, TypeClientdataupdated 

, TypeVisit_adriverPostView	
, TypeVisit_clickGoogleId	  
, TypeVisit_clickYandexId	  
--, TypeVisit_client	        
, TypeVisit_clientGoogleId	
, TypeVisit_clientYandexId	
, TypeVisit_comagicVid	    
, TypeVisit_created	        
, TypeVisit_guid	          
, TypeVisit_jivoVid	        
, TypeVisit_language	      
, TypeVisit_page	          
, TypeVisit_platform	      
, TypeVisit_referer	        
, TypeVisit_statCampaign	  
, TypeVisit_statFrom	      
, TypeVisit_statInfo	      
, TypeVisit_statSource	    
, TypeVisit_statSystem	    
, TypeVisit_statTerm	      
, TypeVisit_statType	      
, TypeVisit_updated	        
, TypeVisit_userAgent	      
, TypeVisit_client_type	    
, TypeVisit_client_ref_type	
, TypeVisit_client_guid	    

--into [_LCRM].[lcrm_queue_visite_site_update]

from  client
left join visit on client.message_guid=visit.message_guid

--============================== Created ==============================-
if object_id('tempdb.dbo.#t2')  is not null drop table #t2
  	  select --top 10 --l.*
	       [message_guid]
      ,[message_type]
      ,[state]
	  ,[publishTime]
      ,[version]
      ,[docUrl]
      ,[props_guid]
      --,[data]
      ,[data_publisher]
      ,[data_scheme]
      ,[data_publishTime]
      ,[data_guid]
      ,[data_type]
      ,[data_state]
      ,[data_version]
      ,[data_docUrl]
     -- ,[data_data]
      ,[TypeClientdatacreated]
      ,[TypeClientdataguid]
      ,[TypeClientdataupdated]
      ,[TypeVisit_created]
      ,[TypeVisit_updated]
      ,[TypeVisit_guid]
      ,[TypeVisit_adriverPostView]
      ,[TypeVisit_clickGoogleId]
      ,[TypeVisit_clickYandexId]
      --,[TypeVisit_client]
      ,[TypeVisit_clientGoogleId]
      ,[TypeVisit_clientYandexId]
      ,[TypeVisit_comagicVid]
      ,[TypeVisit_jivoVid]
      ,[TypeVisit_language]
      ,[TypeVisit_page]
      ,[TypeVisit_platform]
      ,[TypeVisit_referer]
      ,[TypeVisit_statCampaign]
      ,[TypeVisit_statFrom]
      ,[TypeVisit_statInfo]
      ,[TypeVisit_statSource]
      ,[TypeVisit_statSystem]
      ,[TypeVisit_statTerm]
      ,[TypeVisit_statType]
      ,[TypeVisit_userAgent]
      ,[TypeVisit_client_type]
      ,[TypeVisit_client_ref_type]
      ,[TypeVisit_client_guid]
      into #t2
	  --FROM [RMQ].[ReceivedMessages] with(nolock)
	  FROM RMQ.ReceivedMessages_CRIB_ModelVisit with(nolock)
	   outer apply  OPENJSON(ReceivedMessage, '$')
  with (
         publisher nvarchar(100) '$.publisher'
        ,scheme  nvarchar(100) '$.scheme'
        ,publishTime  nvarchar(100) '$.publishTime'
        ,message_guid  nvarchar(100) '$.guid'
        ,message_type  nvarchar(100) '$.type'
        ,state  nvarchar(100) '$.state'
        ,version nvarchar(100) '$.version' 
        ,docUrl  nvarchar(100) '$.docUrl'
		,props_guid  nvarchar(100) '$.props.guid'
        ,data nvarchar(max) '$.data' as JSOn
       ) l 
       outer apply OPENJSON(l.data, '$')
	   with(

         data_publisher nvarchar(100) '$.publisher'
        ,data_scheme  nvarchar(100) '$.scheme'
        ,data_publishTime  nvarchar(100) '$.publishTime'
        ,data_guid nvarchar(100) '$.guid'
        ,data_type nvarchar(100) '$.type'
        ,data_state  nvarchar(100) '$.state'
        ,data_version nvarchar(100) '$.version' 
        ,data_docUrl  nvarchar(100) '$.docUrl'
        ,data_data nvarchar(max) '$.data' as JSOn
) m
 outer apply OPENJSON(m.data_data, '$')
          with(

-- если data_type='client'  тогда поля:
           TypeClientdatacreated  nvarchar(100) '$.created'
          ,TypeClientdataguid     nvarchar(100) '$.guid'
          ,TypeClientdataupdated  nvarchar(100) '$.updated'

---- если data_type='visit'  тогда поля:
,
TypeVisit_created	              nvarchar(100)	'$.created',
TypeVisit_updated	              nvarchar(100)	'$.updated',
TypeVisit_guid	                nvarchar(100)	'$.guid',
--,dataadriverPostView,
TypeVisit_adriverPostView	      nvarchar(100)	'$.adriverPostView',
--dataclickGoogleId
TypeVisit_clickGoogleId	        nvarchar(100)	'$.clickGoogleId',
--,dataclickYandexId,
TypeVisit_clickYandexId	        nvarchar(100)	'$.clickYandexId',
--dataclienttype,
--dataclientref_type,
--dataclientguid,
TypeVisit_client	              nvarchar(max)	'$.client' as json,

--dataclientGoogleId,
TypeVisit_clientGoogleId	      nvarchar(100)	'$.clientGoogleId',
--dataclientYandexId,
TypeVisit_clientYandexId	      nvarchar(100)	'$.clientYandexId',
--datacomagicVid,
TypeVisit_comagicVid	          nvarchar(100)	'$.comagicVid',
--datajivoVid,
TypeVisit_jivoVid	              nvarchar(100)	'$.jivoVid',


--
--datalanguage
TypeVisit_language	            nvarchar(100)	'$.language',
--,datapage
TypeVisit_page	                nvarchar(200)	'$.page',
--,dataplatform,
TypeVisit_platform	            nvarchar(100)	'$.platform',
--datareferer,
TypeVisit_referer	              nvarchar(300)	'$.referer',
--datastatCampaign
TypeVisit_statCampaign	        nvarchar(100)	'$.statCampaign',
--,datastatFrom,
TypeVisit_statFrom	            nvarchar(100)	'$.statFrom',
--datastatInfo,
TypeVisit_statInfo	            nvarchar(100)	'$.statInfo',
--datastatSource,
TypeVisit_statSource	          nvarchar(100)	'$.statSource',
--datastatSystem,
TypeVisit_statSystem	          nvarchar(100)	'$.statSystem',
--datastatTerm,
TypeVisit_statTerm	            nvarchar(100)	'$.statTerm',
--datastatType,
TypeVisit_statType	            nvarchar(100)	'$.statType',

--datauserAgent
TypeVisit_userAgent	            nvarchar(300)	'$.userAgent'


)n
         outer apply OPENJSON(n.TypeVisit_client ,'$')
         with 
              (
              TypeVisit_client_type       nvarchar(100) '$.ref',
              TypeVisit_client_ref_type   nvarchar(100) '$.ref_type',
              TypeVisit_client_guid       nvarchar(100) '$.guid'
            ) o
  where FromQueue = 'DWH.CRIB.ModelVisitOnCreate' and
  [ReceiveDate] >  dateadd(day,-1,getdate())
  --and ReceiveDate > '2020-04-10'
  --and data_version='1586941067'
;
  
with row_data as (
select 
message_guid
,data_type
,[state]
,[publishTime]

, TypeClientdatacreated =case when data_type='client' then TypeClientdatacreated else '' end
, TypeClientdataguid    =case when data_type='client' then TypeClientdataguid    else '' end
, TypeClientdataupdated =case when data_type='client' then TypeClientdataupdated else '' end
, TypeVisit_adriverPostView	=case when data_type='visit' then TypeVisit_adriverPostView else '' end
, TypeVisit_clickGoogleId	  =case when data_type='visit' then TypeVisit_clickGoogleId else '' end	    
, TypeVisit_clickYandexId	  =case when data_type='visit' then TypeVisit_clickYandexId else '' end	    
--, TypeVisit_client	        =case when data_type='visit' then TypeVisit_client  else '' end	          
, TypeVisit_clientGoogleId	=case when data_type='visit' then TypeVisit_clientGoogleId else '' end	  
, TypeVisit_clientYandexId	=case when data_type='visit' then TypeVisit_clientYandexId else '' end	  
, TypeVisit_comagicVid	    =case when data_type='visit' then TypeVisit_comagicVid else '' end	      
, TypeVisit_created	        =case when data_type='visit' then TypeVisit_created else '' end	          
, TypeVisit_guid	          =case when data_type='visit' then TypeVisit_guid else '' end	            
, TypeVisit_jivoVid	        =case when data_type='visit' then TypeVisit_jivoVid else '' end	          
, TypeVisit_language	      =case when data_type='visit' then TypeVisit_language else '' end	        
, TypeVisit_page	          =case when data_type='visit' then TypeVisit_page else '' end	            
, TypeVisit_platform	      =case when data_type='visit' then TypeVisit_platform else '' end	        
, TypeVisit_referer	        =case when data_type='visit' then TypeVisit_referer else '' end	          
, TypeVisit_statCampaign	  =case when data_type='visit' then TypeVisit_statCampaign else '' end	    
, TypeVisit_statFrom	      =case when data_type='visit' then TypeVisit_statFrom else '' end	        
, TypeVisit_statInfo	      =case when data_type='visit' then TypeVisit_statInfo else '' end	        
, TypeVisit_statSource	    =case when data_type='visit' then TypeVisit_statSource else '' end	      
, TypeVisit_statSystem	    =case when data_type='visit' then TypeVisit_statSystem else '' end	      
, TypeVisit_statTerm	      =case when data_type='visit' then TypeVisit_statTerm else '' end	        
, TypeVisit_statType	      =case when data_type='visit' then TypeVisit_statType else '' end	        
, TypeVisit_updated	        =case when data_type='visit' then  TypeVisit_updated else '' end	          
, TypeVisit_userAgent	      =case when data_type='visit' then TypeVisit_userAgent else '' end	        
, TypeVisit_client_type	    =case when data_type='visit' then TypeVisit_client_type else '' end    
, TypeVisit_client_ref_type	=case when data_type='visit' then TypeVisit_client_ref_type else '' end
, TypeVisit_client_guid	    =case when data_type='visit' then TypeVisit_client_guid else '' end    


from #t2 t

)

, client as (
select message_guid
, [state]
, [publishTime]
, TypeClientdatacreated 
, TypeClientdataguid    
, TypeClientdataupdated 
from row_data where data_type='client'
)
,visit as (
select message_guid
, TypeVisit_adriverPostView	
, TypeVisit_clickGoogleId	  
, TypeVisit_clickYandexId	  
--, TypeVisit_client	        
, TypeVisit_clientGoogleId	
, TypeVisit_clientYandexId	
, TypeVisit_comagicVid	    
, TypeVisit_created	        
, TypeVisit_guid	          
, TypeVisit_jivoVid	        
, TypeVisit_language	      
, TypeVisit_page	          
, TypeVisit_platform	      
, TypeVisit_referer	        
, TypeVisit_statCampaign	  
, TypeVisit_statFrom	      
, TypeVisit_statInfo	      
, TypeVisit_statSource	    
, TypeVisit_statSystem	    
, TypeVisit_statTerm	      
, TypeVisit_statType	      
, TypeVisit_updated	        
, TypeVisit_userAgent	      
, TypeVisit_client_type	    
, TypeVisit_client_ref_type	
, TypeVisit_client_guid	    
from row_data where data_type='visit'
)

insert into [_LCRM].[lcrm_queue_visite_site_update]
select 
  client.message_guid
, client.[state]
, client.[publishTime]
, TypeClientdatacreated 
, TypeClientdataguid    
, TypeClientdataupdated 

, TypeVisit_adriverPostView	
, TypeVisit_clickGoogleId	  
, TypeVisit_clickYandexId	  
--, TypeVisit_client	        
, TypeVisit_clientGoogleId	
, TypeVisit_clientYandexId	
, TypeVisit_comagicVid	    
, TypeVisit_created	        
, TypeVisit_guid	          
, TypeVisit_jivoVid	        
, TypeVisit_language	      
, TypeVisit_page	          
, TypeVisit_platform	      
, TypeVisit_referer	        
, TypeVisit_statCampaign	  
, TypeVisit_statFrom	      
, TypeVisit_statInfo	      
, TypeVisit_statSource	    
, TypeVisit_statSystem	    
, TypeVisit_statTerm	      
, TypeVisit_statType	      
, TypeVisit_updated	        
, TypeVisit_userAgent	      
, TypeVisit_client_type	    
, TypeVisit_client_ref_type	
, TypeVisit_client_guid	    


from  client
left join visit on client.message_guid=visit.message_guid


begin tran

	delete from [_LCRM].[lcrm_queue_visite_site] 
	where message_guid in (select message_guid from [_LCRM].[lcrm_queue_visite_site_update])

	insert into [_LCRM].[lcrm_queue_visite_site]
	select * 
	from [_LCRM].[lcrm_queue_visite_site_update]

		select Count(* )
	from [_LCRM].[lcrm_queue_visite_site_update]
		select count(*) 
	from [_LCRM].[lcrm_queue_visite_site]

commit tran

;
with ssd
as
(SELECT [message_guid]
      ,[state]
      ,[publishTime]
      ,[TypeClientdatacreated]
      ,[TypeClientdataguid]
      ,[TypeClientdataupdated]
      ,[TypeVisit_adriverPostView]
      ,[TypeVisit_clickGoogleId]
      ,[TypeVisit_clickYandexId]
      ,[TypeVisit_clientGoogleId]
      ,[TypeVisit_clientYandexId]
      ,[TypeVisit_comagicVid]
      ,[TypeVisit_created]
      ,[TypeVisit_guid]
      ,[TypeVisit_jivoVid]
      ,[TypeVisit_language]
      ,[TypeVisit_page]
      ,[TypeVisit_platform]
      ,[TypeVisit_referer]
      ,[TypeVisit_statCampaign]
      ,[TypeVisit_statFrom]
      ,[TypeVisit_statInfo]
      ,[TypeVisit_statSource]
      ,[TypeVisit_statSystem]
      ,[TypeVisit_statTerm]
      ,[TypeVisit_statType]
      ,[TypeVisit_updated]
      ,[TypeVisit_userAgent]
      ,[TypeVisit_client_type]
      ,[TypeVisit_client_ref_type]
      ,[TypeVisit_client_guid]
	  , rn = ROW_NUMBER() over (partition by [message_guid]
											,[state]
											,[publishTime]
											,[TypeClientdatacreated]
											,[TypeClientdataguid]
											,[TypeClientdataupdated]
											,[TypeVisit_adriverPostView]
											,[TypeVisit_clickGoogleId]
											,[TypeVisit_clickYandexId]
											,[TypeVisit_clientGoogleId]
											,[TypeVisit_clientYandexId]
											,[TypeVisit_comagicVid]
											,[TypeVisit_created]
											,[TypeVisit_guid]
											,[TypeVisit_jivoVid]
											,[TypeVisit_language]
											,[TypeVisit_page]
											,[TypeVisit_platform]
											,[TypeVisit_referer]
											,[TypeVisit_statCampaign]
											,[TypeVisit_statFrom]
											,[TypeVisit_statInfo]
											,[TypeVisit_statSource]
											,[TypeVisit_statSystem]
											,[TypeVisit_statTerm]
											,[TypeVisit_statType]
											,[TypeVisit_updated]
											,[TypeVisit_userAgent]
											,[TypeVisit_client_type]
											,[TypeVisit_client_ref_type]
											,[TypeVisit_client_guid]
											order by [publishTime])
  FROM [_LCRM].[lcrm_queue_visite_site]
  )
  delete from ssd where rn>1

end
