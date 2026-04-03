 
 create      proc  _productReportEventCall @mode nvarchar(max) = 'update' as
 
   
 if @mode = 'update'
 begin

 declare @date date = dateadd(month, -5,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date))
-- declare @date date = getdate()-7
 

 drop table if exists #status
select a.number number, a.id  id, a.ispts isptsEvent,  a.eventOrder  eventOrder,  cast(  a.eventName as nvarchar(100))  eventName ,a.created eventCreated
,   lead(created) over(partition by number order by a.created, a.eventOrder)    leading_event_created 
,   datediff(second, created, lead(created) over(partition by number order by a.created, a.eventOrder)    )   leading_event_created_second_dif
,   isnull( lead(created) over(partition by number order by a.created, a.eventOrder)  ,  dateadd(hour,  8*24, a.created)  ) leading_event_created_isnull
,   isnull( lead(created) over(partition by number order by a.created, a.eventOrder)  ,  dateadd(hour,   24, a.created)  ) leading_event_created_isnull_24_hour
, a.islkk islkkEvent
--, isnull( lag(created) over(partition by number order by Дата, a.status_order) , dateadd(hour, -1, a.Дата) ) lag_event_created_isnull


into #status 

from _request_event  a
where a.created>=@date --and isFake=0 and eventOrder<>4.5



--select * from #status
--where isptsevent=1 and eventname = 'Переход на экран с фото документов авто' and leading_event_created is null

--select * from #status


-- declare @date date = dateadd(month, -1,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date))


drop table if exists #sms
 
SELECT  
    a.[created] 
,   a.[phone] 
,   a.[parts] 
,   a.[length] 
,   a.[text] 
,   a.[template] 
,   a.[template_text]  
,   a.[source] 


into #sms 

from v_sms a
where created>=@date




;with v  as (select *, row_number() over(partition by id, eventCreated  order by eventOrder desc ) rn from #status ) delete from v where rn>1
 




 drop table if exists #case
 select uuid, phone,projecttitle, creationdate, Номер number, original_lead_id, Задача taskLink into  #case from lead_case_crm where creationdate>=@date


 --select projecttitle, count(*) cnt from lead_case_crm
 --group by projecttitle
 --order by 2


 drop table if exists #case_call

 select a.* , b.session_id, b.attempt_start,  b.attempt_end attempt_end , case when b.login   is not null then 1 else 0 end is_login 
 , b. hangup_initiator hangup_initiator, b. attempt_result attempt_result
 into #case_call from #case  a 
 left join lead_call_crm b on a.uuid=b.case_uuid
 --alter table lead_call_crm  add attempt_end  datetime2
 drop table if exists #leg

 select session_id, connected into #leg from v_lead_call a
 
 where creationdate>=@date and connected is not null 

 drop table if exists #case_call_leg

 select a.*, case when b.session_id is not null then 1 else 0 end is_connected , DATEDIFF(second, b.connected, a.attempt_end ) pay_seconds
 	  , case when datediff(SECOND, connected, attempt_end) in (32,33, 56, 57) and hangup_initiator='queue_script' then 1 else 0 end isAutoanswer

 
 into #case_call_leg from #case_call a
 left join #leg b on a.session_id=b.session_id
 --left join v_lead2 l on l.id=a.original_lead_id



drop table if exists #t434343

select a.number
, a.id  
, a.eventName eventName
, pr.originalLeadId  originalLeadId
, pr.phone phone
, pr.entrypoint
, pr.returnType   returnType 
, pr.call1 		  call1 
, pr.approved 	  approved 
, pr.issued 	  issued 
, a.isptsEvent 
, a.eventCreated
, a.eventOrder 
, isnull( a.isLkkEvent , case when pr.origin = 'mobile' then 0   else 1  end  ) isLkkEvent
, a.leading_event_created
, a.leading_event_created_isnull
, a.leading_event_created_isnull_24_hour
, a.leading_event_created_second_dif
, b.uuid
, b.creationdate
, b.session_id
, b.attempt_start
, b.attempt_result
, b.is_connected
, b.pay_seconds
, b.isAutoanswer
, b.is_login



, (pay_seconds/60.0)*2 cost
into #t434343 from #status a 
left join #case_call_leg b on a.number=b.number and b.attempt_start>=a.eventCreated and b .attempt_start <=a.leading_event_created_isnull
left join _request pr on pr.id=a.id
--left join v_request c	 on c.	lk_request_id=a.request_id
--left join v_lead2 l with (nolock) on l.id=pr.originalLeadId


--select * from #t434343
--where attempt_start> leading_event_created
--order by number , attempt_start



--select cast( eventCreated  as date), count(distinct iD), count(distinct case when creationdate is not null then id end )  from #t434343
--where isptsevent=1 and eventname = 'Переход на экран с фото документов авто' and leading_event_created is null
--group by  cast( eventCreated  as date)
--order by  cast( eventCreated  as date)


--select *   
-- from #t434343
--where isptsevent=1 and eventname = 'Переход на экран с фото документов авто' and leading_event_created is null




--select * from #sms
drop table if exists ##t3278723832832
select a.id, pr.ispts isptsEvent,pr.origin, cast( format(a.eventOrder , '00') +') '+ a.eventName as nvarchar(40)) eventName ,  a.eventCreated   ,  cast(a.eventCreated    as date) date   , a.leading_event_created
, count(distinct b.created ) sms_cnt
,case when  count(distinct b.created ) >0 then 1 else 0 end  has_sms_cnt
, mIN(b.template_text) template_text
, mIN(b.created) firstSmsAfterEvent
, min(datediff(minute, a.eventCreated , b.created) ) SMSafterNmin
into ##t3278723832832
from #status a 
 join request pr on pr.id=a.id and pr.isnew=1
left join #sms b on pr.phone=b.phone and b.created>=a.eventCreated and b .created <=a.leading_event_created_isnull_24_hour and b.source='LK' and b.template_text like '%' + 'код подтв' + '%'

group by  a.id,pr.origin, cast( format(a.eventOrder , '00') +') '+ a.eventName as nvarchar(40)) , a.eventCreated   , a.leading_event_created , pr.ispts, cast(a.eventCreated    as date)
 

--select * from #sms where template_text like '%' + 'код подтв' + '%' and source='lk'

select  top 1000000  a.number,  a.origin,  a._profile ,  a.[_passport]   , a.issued, b.session_id,  b.attempt_result,  b.attempt_start, b.hangup_initiator,b.hangup_initiator, b.pay_seconds , a._profile ,  a.[_passport] , a.*
from _request a 
with(nolock) 
left join #case_call_leg b on b.attempt_start  between a._profile and a.[_passport]  
and b.is_connected =1
and a.returntype='первичный'
and a.number=b.number
where a.ispts=0 and

cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           a.issued), 0) as date) ='20241001'
order by a.number, attempt_start
--order by 1, 4
--order by a.created, b.attempt_start


--select a.*, x.*, case when  a.creationdate>= x.leading_event_created then 1 end is_defect into #f from #case_call_leg a
--outer apply (select top 1 * from #status b where a.Номер=b.number and b.status_created <=a.creationdate   order by b.status_created desc ) x

--select * from #t434343

--select * from dwh where table_name='_request'
--ALTER TABLE Analytics.dbo.[_request] ALTER COLUMN returnType nvarchar(20)
--ALTER TABLE Analytics.dbo.[_request_log] ALTER COLUMN returnType nvarchar(20)
--ALTER TABLE #t434343 ALTER COLUMN returnType nvarchar(20)


;

 

drop table if exists #t1

select *
, row_number() over(partition by     a.id,  a.eventName order by attempt_start, creationdate) rn 
 , PERCENTILE_CONT (0.5)  within group(order by 
leading_event_created_second_dif)  over(partition by cast( eventCreated  as date) , a.eventName  , case when leading_event_created_second_dif  is not null then 1 else 0 end 
, isptsEvent, isLkkEvent, returnType, case when entrypoint in ('csv', 'api', 'trigger') then 'КЦ' else 'Digital' end  
 ) median
into #t1
from #t434343 a



--select * from #t1
--where eventName='Анкета' and returnType='Первичный'
--order by eventCreated, attempt_start

--select * from #t1
--order by eventCreated


--select * from #t1
--order by 2, status_created


 create nonclustered index index_1 on #t1
 (
 eventOrder, id, attempt_start
 )

drop table if exists #trials_by_type
drop table if exists #t2

;
with trials as (

select '1 - 1 попытка' type , 1 as min, 1    as max union all
select '1 - 2 попытка' type , 1 as min, 2    as max union all
select '1 - 3 попытка' type , 1 as min, 3    as max union all
select '1 - 4 попытка' type , 1 as min, 4    as max union all
select '1 - 5 попытка' type , 1 as min, 5    as max --union all
--select '1 - 6 попытка' type , 1 as min, 6    as max union all
--select '1 - 7 попытка' type , 1 as min, 7    as max union all
--select '1 - 8 попытка' type , 1 as min, 8    as max union all
--select '1 - 9 попытка' type , 1 as min, 9    as max --union all
)


, trials_by_type as (
select *   
,row_number() over( partition by  eventOrder,  id, type order by attempt_start desc ) rn_desc
,lag(attempt_start) over( partition by  eventOrder,  id, type order by attempt_start   ) lagAttemptStart
, case
when count(attempt_start) over( partition by  eventOrder,  id) >0 then 'Звонок'
--when count(creationdate) over( partition by  eventOrder,  id)  >0 then 'Звонок'
else 'Без звонка'
end callCentrAction

from trials a
left join #t1 b on b.rn between a.min and a.max
)
 --select format(1, '00')

 select * into #trials_by_type from trials_by_type


 --select * from #trials_by_type

 create nonclustered index index_1 on #trials_by_type
 (
  entrypoint
, eventName
, eventCreated
, callCentrAction
, isLkkEvent
, returnType 
, type 
 )
 


 --select * from #trials_by_type
 --order by eventCreated, number, max, attempt_start

 drop table if exists #t2
select type,  cast( format(a.eventOrder , '00') +') '+ a.eventName as nvarchar(30)) eventName ,a.isptsEvent ,

case when entrypoint in ('csv', 'api', 'trigger') then 'КЦ' else 'Digital' end entrypointType , cast( eventCreated  as date) date
, callCentrAction
, isLkkEvent
, returnType 
, count(distinct case when rn =max then  id  end ) [Лид-заявка_last]
, count(distinct case when rn =max and  leading_event_created is not null  then  id  end ) [Конверсия_last]
, count(distinct      id   ) [Лид-заявка]
, count(distinct uuid ) uuid
, count(distinct session_id ) session_id
, count(distinct case when rn =max   then  session_id end ) session_id_last
, sum(cost) cost
, sum(case when rn =max   then  cost end) cost_last
, count(distinct case when     is_connected = 1 then  session_id end ) connected
, count(distinct case when rn =max and   is_connected = 1 then  session_id end ) connected_last
, count(distinct case when     isAutoanswer = 1 then  session_id end ) autoanswer
, count(distinct case when rn =max and   isAutoanswer= 1 then  session_id end ) autoanswerLast
, count(distinct case when   is_login = 1 then  session_id end ) login
, count(distinct case when rn =max and  is_login = 1 then  session_id end ) login_last
, count(distinct case when rn =max and  is_login=1 and leading_event_created between  attempt_start and  dateadd(hour, 8*24, attempt_start ) then  id end  ) [Конверсия после дозвона]
, count(distinct case when rn =max and  is_login=1 and issued is not null and leading_event_created between  attempt_start and  dateadd(hour, 8*24, attempt_start ) then  id end  ) [Конверсия после дозвона и выдача]
, count(distinct case when rn =max and  is_connected=1 and  leading_event_created between  attempt_start and  dateadd(hour, 8*24, attempt_start ) then  id end  ) [Конверсия после соединения]
, count(distinct case when rn =max and  is_connected=1 and issued is not null and  leading_event_created between  attempt_start and  dateadd(hour, 8*24, attempt_start ) then  id end  ) [Конверсия после соединения и выдача]
, count(distinct case when rn =max and  is_connected=1 and  (  isAutoanswer= 1 or  pay_seconds<=10) and issued is not null and  leading_event_created between  attempt_start and  dateadd(hour, 8*24, attempt_start ) then  id end  ) [Конверсия после соединения и выдача но автоответ]
, count(distinct case when     leading_event_created is not null  then   id end  ) [Конверсия]
, count(distinct case when     call1 is not null  then   id end  ) [call1]
, count(distinct case when     approved is not null  then   id end  ) [approved]
, count(distinct case when     issued is not null  then   id end  ) issued
, count(distinct case when  attempt_start >  leading_event_created    then   id end  ) [Лидов со звонком после конверсии накопительно]
, count(distinct case when  attempt_start >  leading_event_created    then   session_id end  ) [Звонков после конверсии накопительно]
, avg(case when rn =1      then leading_event_created_second_dif end )  [Конверсия время]
, avg(case when rn =1      then median end )  [Конверсия время медиана]
, avg(case when rn =max    and  datepart(hour, eventCreated ) between 10 and 18 then datediff(minute, eventCreated, attempt_start ) end )  [timing_event]
, avg(case when rn =max      then datediff(minute, lagAttemptStart, attempt_start )  end )  [timing_lastCall]

into #t2

from #trials_by_type a 
group by type  
, callCentrAction
, returnType

, cast( format(a.eventOrder , '00') +') '+ a.eventName as nvarchar(30)) , cast( eventCreated  as date)  , case when entrypoint in ('csv', 'api', 'trigger') then 'КЦ' else 'Digital' end 
,a.isPtsEvent  
,a.isLkkEvent  
, case when  leading_event_created  is not null then 1 else 0 end  




 drop table if exists productReportEventCall
 select * into productReportEventCall from   #t2

 
return

end

if @mode='select'
begin

;
with v as (

SELECT    cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,     [date]      ), 0) as date) month

,   cast(DATEADD(DD, 1 - DATEPART(DW, [date] ), [date] ) as date) as week
, *

            FROM 

          productReportEventCall a
			)

			select reportDate = date, reportType = 'date' , * from v union all
			select reportDate = month, reportType = 'month' , * from v union all
			select reportDate = week , reportType = 'week' , * from v --union all

end
