
CREATE proc   _request_dubl  @days int = 30
as

--exec  _request_dubl NULL

declare @date date = cast(getdate()-@days  as date)--cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date)
IF @DATE IS NULL SET @DATE ='20100101'
drop table if exists #t247244782723871
--select  top 0   a.guid, better.statusOrder, better.created2-- into #t1
select   a.guid,  max(better.guid) guidDubl, cast( 'fio matched' as nvarchar(100)) type into #t247244782723871
from request a

   join  request better on cast(  a.created2 as date)  between dateadd( day, -7, cast(  better.created2 as date) ) and dateadd(day, 7 ,  cast(  better.created2 as date)    )
 and case
 when  a.created2>better.created2  and a.statusOrder <=  better.statusOrder   then 1
  when  a.created2<better.created2  and a.statusOrder  < better.statusOrder   then 1
  when  a.created2=better.created2  and a.statusOrder  <= better.statusOrder  and a.number>better.number  then 1
  when  a.created2=better.created2  and a.statusOrder  < better.statusOrder  then 1
  end =1
and a.guid<>better.guid
and a.ispts=better.ispts

and a.loanOrder=better.loanOrder
 
and ( a.fiobirthday= better.fiobirthday 
) 
where   a.created2>=@date

--where cAST(a.guid  as nvarchar(36)) in
--(
--'A29F32C1-419F-4649-A343-E8380EA310F7',
--'B69BABA1-8A16-4E47-9F4B-762C386B3AF2',
--'')
--where a.created2>=getdate()-30
group by   a.guid



insert into #t247244782723871
--select   a.created2,a.guid, better.guid, better.statusOrder, better.created2-- into #t1

select   a.guid,  max(better.guid) guidDubl  , 'passport matched' type
from request a

   join  request better on cast(  a.created2 as date)  between dateadd( day, -7, cast(  better.created2 as date) ) and dateadd(day, 7 ,  cast(  better.created2 as date)    )
 and case 
 when  a.created2>better.created2  and a.statusOrder <=  better.statusOrder   then 1
  when  a.created2<better.created2  and a.statusOrder  < better.statusOrder   then 1
  when  a.created2=better.created2  and a.statusOrder  <= better.statusOrder  and a.number>better.number  then 1
  when  a.created2=better.created2  and a.statusOrder  < better.statusOrder  then 1 end =1
and a.guid<>better.guid
and a.ispts=better.ispts

and a.loanOrder=better.loanOrder
 
and ( a.passportSerialNumber= better.passportSerialNumber 
)  
 left join #t247244782723871 c1 on c1.guid = a.guid 
 where  c1.guid is null
and   a.created2>=@date
group by   a.guid


insert into #t247244782723871
select   a.guid,  max(better.guid) guidDubl  , 'phone matched' type
from  request a

   join  request better on cast(  a.created2 as date)  between dateadd( day, -7, cast(  better.created2 as date) ) and dateadd(day, 7 ,  cast(  better.created2 as date)    )
 and case
 when  a.created2>better.created2  and a.statusOrder <=  better.statusOrder   then 1
  when  a.created2<better.created2  and a.statusOrder  < better.statusOrder   then 1
  when  a.created2=better.created2  and a.statusOrder  <= better.statusOrder  and a.number>better.number  then 1
  when  a.created2=better.created2  and a.statusOrder  < better.statusOrder  then 1 end =1
and a.guid<>better.guid
and a.ispts=better.ispts

and a.loanOrder=better.loanOrder
 
and ( a.phone= better.phone 
) 
left join #t247244782723871 c1 on c1.guid = a.guid  
where --a.created2>=getdate()-30 and
c1.guid is null
and   a.created2>=@date  
group by   a.guid


 



update  a set a.isDubl = case when   r1.guid  is not null and  a.issued  is   null then -1 when  b1.guid  is not null and  a.issued  is   null then 1  else 0 end ,dublGuid= b1.guidDubl   from request a left   join #t247244782723871 b1 on a.guid=b1.guid
left join v_request r1 on r1.guid=a.guid and r1.isTest=1
where a.created2>=@date




--select * from #t1 a 
--left join  #t1 b  on a.guidDubl=b.guid 
--where a.guid=b.guidDubl



--select * from #t1 where cAST(guid  as nvarchar(36)) in
--(
--'A29F32C1-419F-4649-A343-E8380EA310F7',
--'B69BABA1-8A16-4E47-9F4B-762C386B3AF2',
--'')




--alter table _request add   dublGuid nvarchar(36)
--alter table _request_log add   dublGuid nvarchar(36)

--where a.created2>=getdate()-15


--select number, * from request where cAST(guid  as nvarchar(36)) in
--(
--'A29F32C1-419F-4649-A343-E8380EA310F7',
--'B69BABA1-8A16-4E47-9F4B-762C386B3AF2',
--'0EB73C6F-307A-4E1D-B983-20AEE10D9E9D',
--'')

----select * from #t1
----select * from request



