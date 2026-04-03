
CREATE proc   [dbo].[_lead_dubl]  @days int = 30
as

--exec  _lead_dubl NULL


declare @date date = cast(getdate()-@days  as date)--cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date)
IF @DATE IS NULL SET @DATE ='20100101'


drop table if exists #t328923882382389
select  a.id , max(better.id2) dublId    into #t328923882382389
from lead_request a
join   lead_request better on cast(  a.created  as date)  between dateadd( day, -7, cast(  better.created3 as date) ) and dateadd(day, 7 ,  cast(  better.created3 as date)    ) 
and a.id <> isnull(better.id, '-999')
and  case when  a.created2>better.created2  and a.statusOrder <=  better.statusOrder   then 1
  when  a.created2<better.created2  and a.statusOrder  < better.statusOrder   then 1
  when  a.created2=better.created2  and a.statusOrder  <= better.statusOrder  and a.id>better.id  then 1
  when  a.created2=better.created2  and a.statusOrder  < better.statusOrder  then 1 end =1

  and a.phone=better.phone
where a.requestguid is null 
and a.created>=@date
--and a.created<=cast(getdate()-1   as date) 

 group by  a.id 

 update a set a.isdubl = case when b.id is not null then  1 end , a.dublId =  b.dublId   from _lead_request a 
 left join #t328923882382389 b on a.id=b.id
  
 where a.created >=@date



 --;

 --with v as (select id,  requestGuid,   row_number() over(partition by id order by isDubl,  created) rn from _lead_request a 
 --where   id is not null-- and created>=getdate()-30
 --)
 --update a set a.rn = case when v.rn>=255 then 255 else v.rn end from _lead_request a join v   on a.id=v.id and  isnull(a.requestGuid, '') =  isnull(v.requestGuid, '')
 

 
;WITH v AS (
    SELECT
        id,
        requestGuid,
        ROW_NUMBER() OVER (PARTITION BY id ORDER BY isDubl, created) AS rn
    FROM _lead_request
    WHERE id IS NOT NULL
)
UPDATE a
SET a.rn = CASE WHEN v.rn >= 255 THEN 255 ELSE v.rn END
FROM _lead_request a
JOIN v
    ON a.id = v.id
   AND (
        a.requestGuid = v.requestGuid
        OR (a.requestGuid IS NULL AND v.requestGuid IS NULL)
       );




 
 --select top 1000 * from _lead_request where id='18dee650-4651-4a1c-afd0-63689521edf8' created>=getdate()-1

  --alter table _lead_request add isdubl tinyint
  --alter table _lead_request add dublId nvarchar(36)
 --  select top 2 * from dwh where column_name='diblId' and table_name='_lead_request'
 --select * from #t1

 --select * from lead_request
 --where id = '0152F1FC-5A56-445A-B186-37806BE64449' or phone ='9878370803'
 --order by created

