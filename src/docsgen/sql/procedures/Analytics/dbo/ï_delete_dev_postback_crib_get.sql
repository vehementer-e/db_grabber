CREATE   proc [dbo].[dev_postback_crib_get]
@search_string nvarchar(max) = null,
@date_from date = null,
@date_to date = null
as
begin


--exec select_table 'stg._crib.[dm_postbacks]'

drop table if exists #t1

select 	top  0
    a.[taskId] 
,   a.[created] 
,   a.[updated] 
,   a.[STATUS] 
,   a.[eventRequestId] 
,   a.[eventName] 
,   a.[postback_leadgen_name] 
,   a.[cribId] 
,   a.[lcrmId] 
,   a.[phone] 
,   a.[lead_created] 
,   a.[lead_leadgen_name] 
,   a.[request_number] 
,   a.[request_created] 
,   a.[request_status_for_postback] 
,   a.[DWHInsertedDate] 
,   a.[ProcessGUID] 
,   a.visit_stat_info 
,   a.leadgeneratorid 
,   a.leadgeneratorclickid 
,   a.city_region 
   into #t1
from 

stg._crib.dm_postbacks a
where cast(a.[created]  as date) between  isnull(@date_from, '20190101') and 	isnull(@date_to, getdate()+1)

if len(@search_string )=14

insert into #t1
select 
    a.[taskId] 
,   a.[created] 
,   a.[updated] 
,   a.[STATUS] 
,   a.[eventRequestId] 
,   a.[eventName] 
,   a.[postback_leadgen_name] 
,   a.[cribId] 
,   a.[lcrmId] 
,   a.[phone] 
,   a.[lead_created] 
,   a.[lead_leadgen_name] 
,   a.[request_number] 
,   a.[request_created] 
,   a.[request_status_for_postback] 
,   a.[DWHInsertedDate] 
,   a.[ProcessGUID] 
,   a.visit_stat_info 
,   a.leadgeneratorid 
,   a.leadgeneratorclickid 	 
,   a.city_region 



from 

stg._crib.dm_postbacks a
where 
[request_number]  =@search_string 						  
and cast(a.[created]  as date) between  isnull(@date_from, '20190101') and 	isnull(@date_to, getdate()+1)


if len(@search_string )=10
insert into #t1


select 
    a.[taskId] 
,   a.[created] 
,   a.[updated] 
,   a.[STATUS] 
,   a.[eventRequestId] 
,   a.[eventName] 
,   a.[postback_leadgen_name] 
,   a.[cribId] 
,   a.[lcrmId] 
,   a.[phone] 
,   a.[lead_created] 
,   a.[lead_leadgen_name] 
,   a.[request_number] 
,   a.[request_created] 
,   a.[request_status_for_postback] 
,   a.[DWHInsertedDate] 
,   a.[ProcessGUID] 
,   a.visit_stat_info 
,   a.leadgeneratorid 
,   a.leadgeneratorclickid 
,   a.city_region 
from 

stg._crib.dm_postbacks a
where 
----------------------поиск по дате a.[created] [@date_from -> @date_to]  ,  
[phone]  =@search_string 
and cast(a.[created]  as date) between  isnull(@date_from, '20190101') and 	isnull(@date_to, getdate()+1)
 


if @search_string is null
insert into #t1
select 
    a.[taskId] 
,   a.[created] 
,   a.[updated] 
,   a.[STATUS] 
,   a.[eventRequestId] 
,   a.[eventName] 
,   a.[postback_leadgen_name] 
,   a.[cribId] 
,   a.[lcrmId] 
,   a.[phone] 
,   a.[lead_created] 
,   a.[lead_leadgen_name] 
,   a.[request_number] 
,   a.[request_created] 
,   a.[request_status_for_postback] 
,   a.[DWHInsertedDate] 
,   a.[ProcessGUID] 
,   a.visit_stat_info 
,   a.leadgeneratorid 
,   a.leadgeneratorclickid 
,   a.city_region 

from 
stg._crib.dm_postbacks a
where cast(a.[created]  as date) between  isnull(@date_from, '20190101') and 	isnull(@date_to, getdate()+1)


  select a.*, b.[Регион проживания], b.[Первичная сумма] from #t1	 a
  left join reports.dbo.dm_Factor_Analysis_001 b on a.request_number=b.Номер


end