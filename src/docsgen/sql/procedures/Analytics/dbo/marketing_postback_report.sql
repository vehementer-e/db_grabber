
CREATE       proc marketing_postback_report
@search_string nvarchar(max) = null,  @date_from date = null, @date_to date = null
as
begin


SELECT 
    a.[taskId] 
,   a.[created] 
,   a.[updated] 
,   a.[STATUS] 
,   a.[eventRequestId] 
,   a.[eventName] 
,   a.[postback_leadgen_name] 
,   a.[lead_id] 
,   a.[phone] 
,   a.[lead_created] 
,   a.[lead_leadgen_name] 
,   a.[request_number] 
,   a.[request_created] 
,   a.[request_status_for_postback] 
,   a.[leadgeneratorid] 
,   a.[leadgeneratorclickid] 
,   a.[city_region] 
, a.sendingStatus

into #t1
        FROM 

 analytics.dbo.postback a
where cast(a.created  as date) between  isnull(@date_from, getdate()-30) and 	isnull(@date_to, getdate()+1)

--select * from stg._lf.config_postback_config

--select top 100 *  from   stg._lf.referral_visit 
--select top 100 *  from stg._lf.postback a
--		 event_name
--request.status.changed

 
SELECT 
           a.[taskId] 
,   a.[created] 
,   a.[updated] 
,   a.[STATUS] 
,   a.[eventRequestId] 
,   a.[eventName] 
,   a.[postback_leadgen_name] 
,   a.[lead_id] 
,   a.[phone] 
,   a.[lead_created] 
,   a.[lead_leadgen_name] 
,   a.[request_number] 
,   a.[request_created] 
,   a.[request_status_for_postback] 
,   a.[leadgeneratorid] 
,   a.[leadgeneratorclickid] 
,   a.[city_region] 
, b.[Регион проживания], b.[Первичная сумма], b.ФИО
,sendingStatus 

from #t1	 a
  left join v_fa b on a.request_number=b.Номер
  --left join  stg._crib.dm_crm_requests 	r on r.requestnumber=a.request_number

end


--exec select_table 'stg._crib.[dm_postbacks]'
 
--declare @search_string nvarchar(max) = null, @date_from date = null, @date_to date = null


--drop table if exists #t1

--select 	top  0
--    a.[taskId] 
--,   a.[created] 
--,   a.[updated] 
--,   a.[STATUS] 
--,   a.[eventRequestId] 
--,   a.[eventName] 
--,   a.[postback_leadgen_name] 
--,   a.[cribId] 
--,  cast( a.[lcrmId]  as nvarchar(36))[lcrmId]
--,   a.[phone] 
--,   a.[lead_created] 
--,   a.[lead_leadgen_name] 
--,   a.[request_number] 
--,   a.[request_created] 
--,   a.[request_status_for_postback] 
--,   a.[DWHInsertedDate] 
--,   a.[ProcessGUID] 
--,   a.visit_stat_info 
--,   a.leadgeneratorid 
--,   a.leadgeneratorclickid 
--,   a.city_region 
--   into #t1
--from 

--stg._crib.dm_postbacks a
--where cast(a.[created]  as date) between  isnull(@date_from, '20190101') and 	isnull(@date_to, getdate()+1)
--and 1=0

--if len(@search_string )=14

--insert into #t1
--select 
--    a.[taskId] 
--,   a.[created] 
--,   a.[updated] 
--,   a.[STATUS] 
--,   a.[eventRequestId] 
--,   a.[eventName] 
--,   a.[postback_leadgen_name] 
--,   a.[cribId] 
--,   a.[lcrmId] 
--,   a.[phone] 
--,   a.[lead_created] 
--,   a.[lead_leadgen_name] 
--,   a.[request_number] 
--,   a.[request_created] 
--,   a.[request_status_for_postback] 
--,   a.[DWHInsertedDate] 
--,   a.[ProcessGUID] 
--,   a.visit_stat_info 
--,   a.leadgeneratorid 
--,   a.leadgeneratorclickid 	 
--,   a.city_region 




--from 

--stg._crib.dm_postbacks a
--where 
--[request_number]  =@search_string 						  
--and cast(a.[created]  as date) between  isnull(@date_from, '20190101') and 	isnull(@date_to, getdate()+1)
--and 1=0


--if len(@search_string )=10
--insert into #t1


--select 
--    a.[taskId] 
--,   a.[created] 
--,   a.[updated] 
--,   a.[STATUS] 
--,   a.[eventRequestId] 
--,   a.[eventName] 
--,   a.[postback_leadgen_name] 
--,   a.[cribId] 
--,   a.[lcrmId] 
--,   a.[phone] 
--,   a.[lead_created] 
--,   a.[lead_leadgen_name] 
--,   a.[request_number] 
--,   a.[request_created] 
--,   a.[request_status_for_postback] 
--,   a.[DWHInsertedDate] 
--,   a.[ProcessGUID] 
--,   a.visit_stat_info 
--,   a.leadgeneratorid 
--,   a.leadgeneratorclickid 
--,   a.city_region 
--from 

--stg._crib.dm_postbacks a
--where 
------------------------поиск по дате a.[created] [@date_from -> @date_to]  ,  
--[phone]  =@search_string 
--and cast(a.[created]  as date) between  isnull(@date_from, '20190101') and 	isnull(@date_to, getdate()+1)
--and 1=0
 


--if @search_string is null
--insert into #t1
--select 
--    a.[taskId] 
--,   a.[created] 
--,   a.[updated] 
--,   a.[STATUS] 
--,   a.[eventRequestId] 
--,   a.[eventName] 
--,   a.[postback_leadgen_name] 
--,   a.[cribId] 
--,   a.[lcrmId] 
--,   a.[phone] 
--,   a.[lead_created] 
--,   a.[lead_leadgen_name] 
--,   a.[request_number] 
--,   a.[request_created] 
--,   a.[request_status_for_postback] 
--,   a.[DWHInsertedDate] 
--,   a.[ProcessGUID] 
--,   a.visit_stat_info 
--,   a.leadgeneratorid 
--,   a.leadgeneratorclickid 
--,   a.city_region 

--from 
--stg._crib.dm_postbacks a
--where cast(a.[created]  as date) between  isnull(@date_from, '20190101') and 	isnull(@date_to, getdate()+1)
--and 1=0

----drop table if exists #l
----select id, source_id into #l from stg._lf.lead

--drop table if exists #s
--select id, name into #s from stg._lf.source_account

--INSERT INTO #t1 
--select
--    [taskId]=a.id
--,   [created]=a.[created_at_time]
--,   [updated]=a.[updated_at_time]
--,   [STATUS] =	cpc.name
--,   [eventRequestId] =''
--,   [eventName] = a.[event_name] +case when r.id is null then '('+b.type_code+')' else '' end
--,   [postback_leadgen_name]=c1.name
--,   [cribId]= a.lead_id
--,   [lcrmId]=a.lead_id
--,   [phone]=a.[phone]
--,   [lead_created] =b.created_at_time
--,   [lead_leadgen_name] = c.name
--,   [request_number] =r.number
--,   [request_created] =r.date
--,   [request_status_for_postback] =event_name
--,   [DWHInsertedDate]=null
--,   [ProcessGUID]=null
--,   visit_stat_info =v.stat_info
--,   leadgeneratorid =v.stat_info
--,   leadgeneratorclickid =v.stat_term
--,   city_region =''

--from stg._lf.postback a
--left join stg._lf.lead b on a.lead_id=b.id
--left join stg._lf.request r on r.marketing_lead_id=b.id	 and r.[created_at_time]<=a.[created_at_time]
--left join  stg._lf.referral_visit  v on v.id=b.visit_id
--left join #s c on c.id=b.source_id
--left  JOIN  stg._lf.config_postback_config cpc ON a.postback_config_id = cpc.id
--left join #s c1 on c1.id=cpc.source_id




--select a.*, b.[Заем выдан] from #t1	 a
--join v_fa b on a.request_number=b.Номер and  [Заем выдан] is null
--order by phone, created



--select status, count(*) cnt, max(b.[ВЕрификация КЦ]) [ВЕрификация КЦ] from #t1	 a
--join v_fa b on a.request_number=b.Номер and  [Заем выдан] is null
--group by status
--order by status


--select distinct  from #t1	 a
--select * from #t1	 a
-- left join v_fa b on a.request_number=b.Номер --and  [Заем выдан] is null
--where status like  '%выдача%'    
--order by  2
