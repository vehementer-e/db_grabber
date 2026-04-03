

CREATE   proc [dbo].[Создание витрины с установленными приложениями]

as

begin

delete from mp_collection_devices
insert into mp_collection_devices
select * from openquery(lkprod, 'select * from mp_collection_devices')

drop table if exists #t1
exec generate_create_table_script'Analytics.dbo.mp_collection_devices'
;
with mp_collection_devices as (

select       a.[id]  
,   a.[device_id]  
,   a.[last_ip]  
,   a.[user_id] 
,   cast(a.[applications_id]    as nvarchar(max))  [applications_id]
,   a.[version_os]  
,   a.[version_mp] 
,   a.[brand_device]  
,   a.[model_device]  
,   a.[mobile_operators]  
,   a.[coordinates]   
,   a.[enabled_vpn]  
,   a.[created_at]  
,   a.[updated_at]   
from     Analytics.dbo.mp_collection_devices a

)





select '1' s, a.device_id, u.user_id , a.[applications_id],   a.created_at
into #t1
from mp_collection_devices a
join (select device_id , user_id, ROW_NUMBER() over(partition by device_id order by created_at) rn from mp_collection_devices where 
 user_id<>''
) u on a.device_id=u.device_id and rn=1
where a.user_id='' and applications_id<>'[]'

union all

select '2' s, a.device_id, a.user_id, a.[applications_id],  a.created_at from mp_collection_devices a

where a.user_id<>'' and applications_id<>'[]'


drop table if exists #t2

;
with mp_collection_devices_v as (
select     
 user_id  
,right(left([applications_id], len([applications_id])-1), len(left([applications_id], len([applications_id])-1))-1)  [applications_id]	
,created_at
--,ROW_NUMBER() over(partition by device_id order by created_at) rn
 from #t1
 )


 select user_id
 , try_cast(replace( replace(value, ' ', '') , '"', '') as nvarchar(50)) application
 
 ,       created_at	
   
	 into #t2
	  from mp_collection_devices_v
  outer apply	
  STRING_SPLIT([applications_id], ',')	
--order by 3 , 5

create nonclustered index t on #t2
(
application
)

--select distinct top 100000  application  from #t2
--order by 1 desc



	
select application
, count(distinct user_id) ЧислоУстановок	
--, max( user_id) ЧислоУстановок	
	
from #t2	
group by application	
order by 2 desc	



	
select application
, count(distinct user_id) ЧислоУстановок	
--, max( user_id) ЧислоУстановок	
	
from #t2	
where created_at>='20210101'
group by application	
order by 2 desc	


select application
, count(distinct user_id) ЧислоУстановок	
--, max( user_id) ЧислоУстановок	
	
from #t2	
where created_at<'20211207'
group by application	
order by 2 desc	





end