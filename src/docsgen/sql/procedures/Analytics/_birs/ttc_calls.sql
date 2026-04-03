CREATE   proc [_birs].[ttc_calls]
@mode nvarchar(max) = 'update',
@days int = 0--,
as
begin



declare @date_start date = 	getdate()-@days
drop table if exists  #t1
--select * from #t1 
SELECT projectuuid
	,projecttitle projecttitle
	,[Код в БД] result
	,CASE 
		WHEN isnumeric(replace([Интервалы], ';', '')) = 1
			THEN [Интервалы]
		ELSE ''
		END intervals
		into #t1
FROM _gsheets.[dic_Попытки Naumen]



drop table if exists #t2

select projectuuid, result ,   value mins , ROW_NUMBER() over(partition by projectuuid,  result order by (select null)) rn into #t2 from #t1
cross apply string_split(intervals, ';')


drop table if exists #t4
SELECT 
     a.session_id
	,a.attempt_start
	,a.uuid
	,a.projecttitle
	,a.projectuuid  projectuuid
	,a.creationdate
	,isnull(a.timezone	, 'GMT+03:00') timezone
	,a.attempt_result
	,a.attempt_end
	,a.uuid id



into #t4
from Feodor.dbo.dm_calls_history   a
join (select distinct projectuuid projectuuid  from #t1 where intervals<>'' )	    b on a.projectuuid=b.projectuuid
and creationdate>=@date_start


insert 
into #t4

SELECT 
     a.session_id
	,a.attempt_start
	,a.uuid
	,a.projecttitle
	,a.projectuuid  projectuuid
	,a.creationdate
	,isnull(a.timezone	, 'GMT+03:00') timezone
	,a.attempt_result
	,a.attempt_end
	,a.uuid id


from Feodor.dbo.dm_calls_history_current_day   a
join (select distinct projectuuid projectuuid  from #t1 where intervals<>'' )	    b on a.projectuuid=b.projectuuid
and creationdate>=@date_start
and attempt_start is not null


;with v  as (select *, row_number() over(partition by session_id order by (select null)) rn from #t4 ) delete from v where rn>1



drop table if exists #RecallTime

select naumencallid collate Cyrillic_General_CI_AS naumencallid, min(dateadd(hour, 3, RecallTime)) RecallTime into #RecallTime  from stg._fedor.core_LeadCommunicationCall
where RecallTime >= @date_start		   
group by naumencallid  collate Cyrillic_General_CI_AS

			-- select * from  stg._fedor.core_LeadCommunicationCall
 --select * from #RecallTime



drop table if exists #t4_rn
select *
, ROW_NUMBER() over(partition by id order by attempt_start) rn
--, lag(attempt_start) over(partition by id order by attempt_start) lg
, lead(attempt_start) over(partition by id order by attempt_start) ld

into #t4_rn
from #t4


drop table if exists #calls_target_time

;


with v as (
select x.projectuuid ,x.id, x.session_id, x.attempt_result, x.attempt_end, x.attempt_start, x.rn rn_диалог , null tt , x.ld
from #t4_rn x										 
union all 											 
select b.projectuuid , b.id, b.session_id, b.attempt_result, b.attempt_end, b.attempt_start, b.rn  , 1 tt , null
from v a join #t4_rn b on a.id=b.id and a.rn_диалог+1= b.rn and a.attempt_result=b.attempt_result
)
,
v_ as
(
select   a.id,a.projectuuid, a.session_id, a.rn_диалог, a.attempt_start, a.attempt_end, a.attempt_result, a.ld, isnull(b.sumtt, 0)+1 rn1  from v a
left join (select id, rn_диалог, sum(tt) sumtt from v where tt is not null group by id, rn_диалог) b on a.id=b.id and a.rn_диалог=b.rn_диалог 
where tt is null
--order by a.id, a.rn_диалог, a.tt  
)

select id
, session_id [На основании какой сессии расчитан target]
, attempt_start [Начало сессии на основании которой расчитан target]
, attempt_result [Результат сессии на основании которой расчитан target]
,rn_диалог [Порядковый номер диалога]
,rn1 [Номер попытки с этим же результатом]
,lead(session_id) over(partition by id order by attempt_start)  lead_session_id
,ld lead_session_id_attempt_start
, mins [Интервалы]
, b.RecallTime  RecallTimeFeodor
, attempt_end
, isnull( b.RecallTime, case when try_cast(mins as int)>=0 then dateadd(minute, try_cast(mins as int), a.attempt_end)end)  target_attempt_start
into #calls_target_time
from v_ a
left join #RecallTime b on a.session_id=b.NaumenCallId
outer apply (
select top 1 * from  #t2 b where  a.projectuuid=b.projectuuid and    a.attempt_result=b.result  order by abs(a.rn1-b.rn)  ) x
option (maxrecursion 0)



--select * from #calls_target_time
--where id='ocpcas00000000000oi39cgpf1to0n40'
--order by [Порядковый номер диалога]



drop table if exists #Справочник



CREATE TABLE [dbo].[#Справочник]
(
      [projectid] [VARCHAR](32)
    , [Проект] [VARCHAR](62)
    , [НазваниеПроектаДляОтчета] [VARCHAR](100)
    , [MSC Старт кампании] [BIGINT]
    , [MSC Окончание кампании] [BIGINT]
    , [MSC Старт клиент может говорить будние]       [BIGINT]
    , [MSC Старт клиент может говорить выходные]     [BIGINT]
    , [MSC Окончание клиент может говорить будние]   [BIGINT]
    , [MSC Окончание клиент может говорить выходные] [BIGINT]
    , [НужнаДетализация] [VARCHAR](1)
);



insert into #Справочник

select 
    a.[projectid] 
,   a.[Проект] 
,   a.[Название проекта для отчета] 
,   a.[ЧасСтартаКампанииПоМск]    *3600000	  [MSC Старт кампании]
,   a.[ЧасОкончанияКампанииПоМск] *3600000-10 [MSC Окончание кампании]	 
,   a.[ЧасПоМскСКОторогоКЛиентМожетГоворитьБудние] 	    *3600000	 [MSC Старт клиент может говорить будние]
,   a.[ЧасПоМскСКОторогоКЛиентМожетГоворитьВыходные] 	*3600000     [MSC Старт клиент может говорить выходные]
,   a.[ЧасПоМскДоКОторогоКЛиентМожетГоворитьБудние]     *3600000-10	 [MSC Окончание клиент может говорить будние]
,   a.[ЧасПоМскДоКОторогоКЛиентМожетГоворитьВыходные] 	*3600000-10  [MSC Окончание клиент может говорить выходные]
,   a.[НужнаДетализация] 
from   --select * from 
analytics._gsheets.[v_dic_Проекты TTC] a

--select * from #Справочник

drop table if exists #itog
select 
  session_id
, attempt_start
, a.attempt_end
, attempt_result
, uuid
, creationdate
, projecttitle
, projectuuid
, isnull(b.target_attempt_start, case when b1.[Порядковый номер диалога]=1 then creationdate end) target_time
, b1.[Номер попытки с этим же результатом]
, b1.Интервалы
, timezone
, b1.[Порядковый номер диалога]

into #itog
from #t4_rn a
left join #calls_target_time b on a.session_id=b.lead_session_id
join #calls_target_time b1 on b1.[На основании какой сессии расчитан target]=a.session_id
--select top 1000 * from #calls_target_time
--order by id, [Порядковый номер диалога]


 --select * from #itog
 --where uuid='ocpcas00000000000oieetfog2klmq9k'

drop table if exists #a5
;
with справочник as (

select НазваниеПроектаДляОтчета Проект
,projectid
, cast([MSC Старт кампании]                           as bigint)        [MSC Старт кампании]                              
, cast([MSC Окончание кампании] 						as bigint)      [MSC Окончание кампании] 						
, cast([MSC Старт клиент может говорить будние] 		as bigint)      [MSC Старт клиент может говорить будние] 		
, cast([MSC Старт клиент может говорить выходные] 	as bigint)          [MSC Старт клиент может говорить выходные] 	
, cast([MSC Окончание клиент может говорить будние] 		as bigint)  [MSC Окончание клиент может говорить будние] 		
, cast([MSC Окончание клиент может говорить выходные]  	as bigint)      [MSC Окончание клиент может говорить выходные]  	
, cast(НужнаДетализация 								as bigint)      НужнаДетализация 								
from (
select * from #Справочник
) x
)
, a1
as (

select *
, dateadd(hour, -3+cast(right(left(timezone, 6),2) as int), a.target_time) МестноеВРемя
, cast(cast(dateadd(hour, -3+cast(right(left(timezone, 6),2) as int), a.target_time)as date) as datetime) МестноеВРемя_dt_dttime
, cast(cast(target_time as date) as datetime) [target_time_date]
, 3-cast(right(left(timezone, 6),2) as int) СмещениеЧасов
from #itog a  join справочник s on a.projectuuid=s.projectid
)

,  a2
as (

select 
*, 
dateadd(MILLISECOND, [MSC Старт кампании] , [target_time_date])  as [Старт кампании по Мск] ,

dateadd(MILLISECOND, [MSC Окончание кампании] ,[target_time_date]) as [Окончание кампании по Мск],

dateadd(day, 1,  dateadd(MILLISECOND, [MSC Старт кампании] , [target_time_date]) )  as [Старт кампании по Мск В Следующий День] ,

case 
when datepart(dw, МестноеВРемя) in (1,2,3,4,5) then dateadd(hour, СмещениеЧасов,  dateadd(MILLISECOND, [MSC Старт клиент может говорить будние] , МестноеВРемя_dt_dttime) )
when datepart(dw, МестноеВРемя) in(6,7)        then dateadd(hour, СмещениеЧасов,  dateadd(MILLISECOND, [MSC Старт клиент может говорить выходные] , МестноеВРемя_dt_dttime) ) 	 
end	 

as [Старт Клиент Может Говорить по Мск] ,

case 
when datepart(dw, МестноеВРемя) in (1,2,3,4,5) then dateadd(hour, СмещениеЧасов,  dateadd(MILLISECOND, [MSC Окончание клиент может говорить будние] , МестноеВРемя_dt_dttime) )
when datepart(dw, МестноеВРемя) in(6,7) then       dateadd(hour, СмещениеЧасов,  dateadd(MILLISECOND, [MSC Окончание клиент может говорить выходные] , МестноеВРемя_dt_dttime) ) end 	

as [Окончание Клиент Может Говорить по Мск],

case 
when datepart(dw, МестноеВРемя) in (7,1,2,3,4) then dateadd(day, 1, dateadd(hour, СмещениеЧасов, dateadd(MILLISECOND, [MSC Старт клиент может говорить будние] , МестноеВРемя_dt_dttime)  ))
when datepart(dw, МестноеВРемя)  in(5,6) then dateadd(day, 1, dateadd(hour, СмещениеЧасов, dateadd(MILLISECOND, [MSC Старт клиент может говорить выходные] , МестноеВРемя_dt_dttime)  ))
end   	 
as [Старт Клиент Может Говорить по Мск на след день]


	 from


a1   

 )
 , a3
 as
 (
 select 
 *
 , case when  [target_time]<= [Старт кампании по Мск] then 1 else 0 end [Создан не позже чем старт кампании]
 , case when  [target_time]>= [Окончание кампании по Мск] then 1 else 0 end [Создан не раньше чем окончание кампании]
 , case when  [target_time]<= [Старт Клиент Может Говорить по Мск] then 1 else 0 end [Создан до момента когда удобно говорить]
 , case when  [target_time]>= [Окончание Клиент Может Говорить по Мск] then 1 else 0 end [Создан после момента когда удобно говорить]
 from a2
 )
 , a4
 as
 (
 select 
 *
 , 
 case when [Создан не позже чем старт кампании] = 1 then  [Старт кампании по Мск]  
                 when  [Создан не раньше чем окончание кампании]=1 then [Старт кампании по Мск В Следующий День]
				 else target_time end УдобныйСтартКампаниии
, 
 case when [Создан до момента когда удобно говорить]=1 then [Старт Клиент Может Говорить по Мск]  
                 when  [Создан после момента когда удобно говорить]=1 then [Старт Клиент Может Говорить по Мск на след день]
				 else target_time end УдобноеВремяКлиенту
				 from a3 
 )


  , a5 as (
  select 
  *
, 
  case when
  case when  УдобныйСтартКампаниии >= УдобноеВремяКлиенту
 then УдобныйСтартКампаниии
  else УдобноеВремяКлиенту    end  
  
  
  between [Окончание кампании по Мск] and [Старт кампании по Мск В Следующий День] then 
								 -------------------------
								 [Старт кампании по Мск В Следующий День]
								 -------------------------
       else 

 case when  УдобныйСтартКампаниии >= УдобноеВремяКлиенту
 then УдобныйСтартКампаниии
  else УдобноеВремяКлиенту    end 
				 end [target_time_client_time]
,case when target_time between [Старт кампании по Мск] and [Окончание кампании по Мск] and target_time between [Старт Клиент Может Говорить по Мск] and [Окончание Клиент Может Говорить по Мск] and format( cast (target_time as date) , 'dd.MM')<>'01.01'  then 1 end as [РабочееВремя]
from a4  
  )

 --select * from #a5
 --where uuid='ocpcas00000000000oieetfog2klmq9k'

select   *, TTC  = 
case 
when datediff(minute, [target_time_client_time], attempt_start)<0 then 0 
else  cast(datediff(minute, [target_time_client_time], attempt_start) as bigint) end  
into #a5 from a5



drop table if exists #ttc

select 
   a.uuid 
,  a.creationdate
,  a.projectuuid
,  a.session_id
,  a.projecttitle
,  a.target_time
,  a.attempt_start
,  a.attempt_end
,  a.attempt_result
,  a.[Порядковый номер диалога]
,  a.[Номер попытки с этим же результатом]
,  a.Интервалы
,  a.timezone
,  a.МестноеВРемя
,  a.target_time_client_time  
,  a.TTC 

into #ttc
from #a5 a
--order by creationdate,  attempt_start
 
--select  min(attempt_start) from #ttc
delete from  ttc_all_calls where creationdate>= (select  min(creationdate) from #ttc )
insert into ttc_all_calls
select *  from #ttc


--SELECT *
--FROM ttc_all_calls
--where uuid=  'ocpcas00000000000oieetfog2klmq9k'
--order by attempt_start  	 desc
--									  SELECT *
--FROM #ttc
--where uuid=  'ocpcas00000000000oieetfog2klmq9k'
--order by attempt_start  	 desc
--


end