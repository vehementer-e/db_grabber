
CREATE proc [dbo].[appmetrica_action_merge] @mode nvarchar(max) as


if @mode = 'merge'
begin



;with v  as (select *, row_number() over(partition by appmetrica_device_id, event_datetime, event_name  order by (select null)) rn from appmetrica_action_bfr2 )

--select cast( event_datetime  as date) , count(*) cnt from v where rn>1
--group by cast( event_datetime  as date) 
--order by 1
delete from v where rn>1
;


MERGE appmetrica_action_stg AS a  USING (SELECT * FROM appmetrica_action_bfr2 ) AS b      
ON a.id = b.appmetrica_device_id and  a.created= b.event_datetime and a.event= b.event_name 


WHEN MATCHED THEN  UPDATE SET    
 a.id = b.appmetrica_device_id
,a.created       = b.event_datetime
,a.event           = b.event_name
,a.appVersion     = b.app_version_name 
 WHEN NOT MATCHED BY TARGET THEN INSERT (
   id
  ,created
  ,event
  ,appVersion  )       
  
                                 VALUES ( 
   b.appmetrica_device_id
  ,b.event_datetime
  ,b.event_name
  ,b.app_version_name
  )
;

--truncate table appmetrica_action_bfr2



--select * from appmetrica_action_bfr2
--select * from dwh where table_name = 'appmetrica_action_stg'


--EXEC sp_rename 'Analytics.dbo.appmetrica_action_stg.event_datetime', 'created'
--EXEC sp_rename 'Analytics.dbo.appmetrica_action_stg.appmetrica_device_id', 'id'
--EXEC sp_rename 'Analytics.dbo.appmetrica_action_stg.event_name', 'event'
--EXEC sp_rename 'Analytics.dbo.appmetrica_action_stg.app_version_name', 'appVersion'
return

end

if @mode = 'client_search'
begin

 --alter table appmetrica_action_stg add userId bigint , phone nvarchar(10) , registered datetime2(0)
 --alter table appmetrica_action_bfr2 drop column   userId 
 --alter table appmetrica_action_bfr2 drop column   phone 
 --alter table appmetrica_action_bfr2 drop column   registered 
 --select * from appmetrica_action_bfr2

 drop table if exists #link_device_user
 select app_metrica_device_id id  , user_id userId, created registered, try_cast(phone as varchar(10)) phone into #link_device_user from v_register_mp 
 where app_metrica_device_id is not null --='1018602893841431938'


 --select *, count(*) over(partition by  app_metrica_device_id) from #link_device_user
 --where app_metrica_device_id is not null

 --select * from #link_device_user
 --where app_metrica_device_id='1018602893841431938'



 --select * from appmetrica_action_stg
 --order by 1 desc

 drop table if exists #t2

 select a.id, a.created, b.userId, b.phone, b.registered, datediff(second, b.registered, a.created ) registeredToEventMinute  into #t2 from appmetrica_action_stg a join #link_device_user b on a.id=b.id
 where a.userid is null


-- select * from #t2


-- 3426539355807173637	2024-12-18 11:16:41	2
--15919357644359298875	2024-12-08 10:03:59	2
--8633516958631932237	2024-12-16 16:28:51	2
--6260042885640466968	2024-12-07 21:29:50	2
--10340594477438579471	2024-12-12 06:59:04	2

-- select app_metrica_device_id, event_datetime, count(distinct phone) from #t2
-- group by app_metrica_device_id, event_datetime
-- having count(distinct phone) >1

--  select * from appmetrica_action_stg a join #link_device_user b on a.appmetrica_device_id=b.app_metrica_device_id
--  where a.appmetrica_device_id='3426539355807173637'


drop table if exists #t3
  ;with v  as (select *,    row_number() over(partition by id, created order by case when registeredToEventMinute>=0 then 1 else 0 end desc,
  
   case when  registeredToEventMinute>=0 then 1 else -1 end*  registeredToEventMinute     ) rn from #t2 ) 
  select id, created, userId, phone, registered into #t3 from v
  where --v.id='3426539355807173637' and 
  rn=1



  update  a
  set 
  a. userId = b.userId
  , a. phone = b.phone
  , a. registered = b.registered  from appmetrica_action_stg a 
  join #t3 b on a.id=b.id and a.created=b.created
  

  --select * from appmetrica_action_stg

  --order by 1

  
  --delete from v where rn>1

   
--select * into appmetrica_action_stg from appmetrica_action_bfr2
--where 1=0

--drop table if exists appmetrica_action_stg
--select count(*) from appmetrica_action_bfr2 with(nolock)
--select * from appmetrica_action_stg


--insert into appmetrica_action_stg select * from appmetrica_action_bfr2 with(nolock)

--appmetrica_device_id
--7959674476643139032
--select a.*, b.phone, b.phone from appmetrica_action_stg a
--left join v_register_mp b on a.appmetrica_device_id=b.app_metrica_device_id
--order by 1




 
-- delete from appmetrica_action_stg

end