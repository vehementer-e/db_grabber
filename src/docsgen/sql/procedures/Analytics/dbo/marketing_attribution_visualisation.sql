
--EXEC msdb.dbo.sp_start_job @job_name =  'Analytics._marketing_attribution_visualisation each day at 12' [marketing_attribution_visualisation ]
--sp_create_job 'Analytics._marketing_attribution_visualisation each day at 12', 'marketing_attribution_visualisation', '1', '120000'
CREATE     proc [dbo].[marketing_attribution_visualisation]	  @mode nvarchar(max) = 'update'
as
 
if @mode = 'select' 
begin
select -- top 1006
    a.[ДатаЗаявки] 
,   a.[НомерЗаявки] 
,   a.[ТипКредитногоПродукта] 
,   a.[МестоСоздания] 	+ isnull( ' '+ a.[ТипКредитногоПродукта] , '') 	 [МестоСоздания]
,   a.[Телефон] 
,   a.[marketing_status] 
,   a.[type] 
,   a.[entrypoint] 
,   a.[original_lead_idd] 
,   a.[lead_id] 
,   a.[source_name] 
,   a.[Источник] 
,   a.[leads_info] 
,   a.[visits_info] 
,   a.[минут С визита] 
,   a.[stat_source] 
,   a.[channel_name] 
,   a.[Exceptions info] 
,   a.[Заем выдан] 
,   a.[ДатаЛида] 
,   a.[Номер] 

from 
 marketing_attribution_visualisation_log a
--where channel_name like '%КЦ%' and [leads_info] like '%ref%'
--order by   a.[Заем выдан]  desc
--
--drop table if exists marketing_attribution_visualisation
--select * into marketing_attribution_visualisation from Analytics._birs.lf_check_tbl a
 

return
  end

if @mode = 'update'
begin

		
drop table if exists #lf_r

select number number, original original ,marketing marketing, phone phone, created created into  #lf_r
from v_request_lf
				   




drop table if exists #lk

select num_1c num_1c, id id, created created, origin origin, phone phone,    product product, status  status, EmojiStatus EmojiStatus into  #lk
from v_request_lk	 

drop table if exists #r

select НомерЗаявки, ДатаЗаявки created, Телефон, МестоСоздания, ТипКредитногоПродукта , [Верификация КЦ], СтатусЗаявки , lk_request_id id  into  #r
from v_request 		 

drop table if exists #fa

select d.Номер  Номер	 ,
d.[Канал от источника] [Канал от источника] ,
d.[Exceptions info] [Exceptions info],
d.[Вид займа] [Вид займа],
d.[Источник] [Источник],
d.[Заем выдан]	 [Заем выдан]
into  #fa
from dm_factor_analysis_001 d  

drop table if exists #request

select b.id,
isnull(a.created, b.created) created,
isnull( c.phone , isnull(a.Телефон, b.phone))  phone,
isnull(a.ТипКредитногоПродукта, b.product) ТипКредитногоПродукта,
isnull(a.СтатусЗаявки, b.status) СтатусЗаявки,
isnull( isnull(a.НомерЗаявки ,  b.num_1c), cast(b.id as nvarchar(20)) ) номер_k ,
isnull( isnull(a.НомерЗаявки ,  b.num_1c), cast(b.id as nvarchar(20)) )+EmojiStatus +case when a.id is null then ' (нет в CRM)' else'' end 
 +case when c.number is null then ' (нет в LF)' else'' end 

Номер,
case   isnull( b.origin ,  a.МестоСоздания)		
when 'Оформление в мобильном приложении'	 then 'МП'  
when 'ЛКК клиента'	 then 'ЛКК' 
when 'FEDOR_TLS'	 then 'FEDOR' 
when 'Ввод операторами FEDOR'	 then 'FEDOR' 
when 'Ввод операторами КЦ'	 then 'КЦ' 
when 'PARTNER'	 then 'Партнеры' 
when 'Оформление на партнерском сайте'	 then 'Партнеры' 
else 	 isnull( b.origin ,  a.МестоСоздания)	end  МестоСоздания,
c.marketing marketing,
c.original original ,
d.[Канал от источника] [Канал от источника] ,
d.[Exceptions info] [Exceptions info],
d.[Вид займа] [Вид займа],
d.[Источник] [Источник],
d.[Заем выдан]	 [Заем выдан]

   into #request
from  #r a
full outer join  #lk b on a.id=b.id
left join  #lf_r c on c.number = 	 isnull(a.НомерЗаявки,  b.num_1c)
left join #fa d on d.Номер= isnull(a.НомерЗаявки,  b.num_1c)

where isnull(a.created, b.created)>=cast(getdate()-10 as date)
or d.[Заем выдан] 	>=cast(getdate()-10 as date)

	   



drop table if exists #visits 
select id id, client_id client_id, stat_source stat_source, source source, created created into #visits from v_visit

drop table if exists #ids

select id into #ids from v_lead2 a  with(nolock)

join (select distinct phone from #request)		  r on a.phone=r.phone

insert into #ids  

select distinct marketing   from #request 	 a
 
insert into #ids  

select distinct original   from #request 


;with v  as (select *, row_number() over(partition by id order by (select null)) rn from #ids ) delete from v where rn>1



drop table if exists #lead

select l.id
, l.source  source				  
, case  l.DECLINE	when 'Технические лиды' then 'Тех.лиды' when '' then N'🆗' else  l.DECLINE end decline_reason

, l.created	 created
, l.phone
, l.entrypoint 	  entrypoint
, l.channel    channel
, case l.type	when 'calculator_form_filled' then 'calculator' else type end type
, case l.status	when 'REQUEST_CREATED' then 'REQUEST' else  l.status end marketing_status

, l.visit_id	 visit_id

, 
case
when l.entrypoint	   in ('MP' ) then N'📱'	
when l.entrypoint	   in ('LANDING' ) then N'🛬'	
when l.entrypoint	   in ('SITE' ) then N'🌐'	
when l.entrypoint	   in ('CRM' ) then N'📞'	
when l.entrypoint	   in ('LKK' ) then N'🗃️'	
when l.entrypoint	   in ('LKP' ) then N'🤝'	
when l.entrypoint	   in ('DWH' ) then N'🍏'	
when l.entrypoint	   in ('CSV' ) then N'📥'	
when l.entrypoint	   in ('API' ) then N'🤖'	
when l.entrypoint	   in ('UNI_API' ) then N'💫'	
when l.entrypoint	   in ('TRIGGER' ) then N'🎣'	
when l.entrypoint	 not in ('CSV','DWH', 'EMAIL', 'API', 'TRIGGER', 'UNI_API') then N'🙋‍'	
else N'' end +
case when l.ВремяПервогоДозвона is not null then N'❤️' when l.ВремяПервойПопытки is not null then N'💤' when uuid is not null then N'🔙'  when l.id is null then N'🐢'
when  l.status  ='Технические лиды' then N'🔧'
when  l.status='completed' then N'🔧'
when  l.status='declined' then N'❌'
when  l.status='REQUEST_CREATED' then N'📋'
when l.id is null then N'🐢'
when  l.status='ACCEPTED' then N'👌'
else 
l.DECLINE  
end 	+
case  l.DECLINE  
WHEN 'Причина отказа клиента' THEN N'❌'
        WHEN 'Автоответчик' THEN N'📴'
        WHEN 'Красная категория' THEN N'🔴'
        WHEN 'Дубль 5 минут' THEN N'🔄'
        WHEN 'Низкая конверсия' THEN N'📉'
        WHEN 'Действующий договор по продукту installment' THEN N'🔐'
        WHEN 'Дубль лида из заявки' THEN N'🔄📄' 
        WHEN 'Черный список' THEN N'⚫'
        WHEN 'Дубль' THEN N'🔄📅'
        WHEN 'Неконтактный' THEN N'💤'
        WHEN 'Некорректный номер телефона' THEN N'📵'
        WHEN 'Технические лиды' THEN N'⚙️'
		 else '??'   
end 			  
call_result 													  
,
CASE
           WHEN l.channel_group = 'Триггеры' THEN N'🎣'
           WHEN l.channel_group = 'Органика' THEN N'🌿'
           WHEN l.channel_group = 'Банки' THEN N'🏧'
           WHEN l.channel_group = 'CPC' THEN N'💎'
           WHEN l.channel_group = 'Партнеры' THEN N'🤝'
           WHEN l.channel_group = 'Тест' THEN N'🧪'
           WHEN l.channel_group = 'Телеком' THEN N'📡'
           WHEN l.channel = 'CPA нецелевой' THEN N'💩'
           WHEN l.channel = 'CPA полуцелевой' THEN N'🥈'
           WHEN l.channel = 'CPA целевой' THEN N'🥇'
          -- WHEN l.channel = 'CPC Бренд' THEN N'9🏷️📈'
          -- WHEN l.channel = 'CPC Платный' THEN N'9💳📈'
          -- WHEN l.channel = 'Билайн' THEN N'🔟📞🐝'
          -- WHEN l.channel = 'Внутренние триггеры' THEN N'4🔔🏠'
          -- WHEN l.channel = 'Газпром' THEN N'🔟🏢💧'
          -- WHEN l.channel = 'Канал привлечения не определен - КЦ' THEN N'3❓📞'
          -- WHEN l.channel = 'Канал привлечения не определен - МП' THEN N'3❓📱'
          -- WHEN l.channel = 'Кросс-маркетинг' THEN N'5🔄🛒'
          -- WHEN l.channel = 'Мегафон' THEN N'🔟📞📡'
          -- WHEN l.channel = 'Медийная реклама' THEN N'9📺📢'
          -- WHEN l.channel = 'МТС' THEN N'🔟📞🔴'
          -- WHEN l.channel = 'НБКИ' THEN N'4📊🏦'
          -- WHEN l.channel = 'ОКБ' THEN N'4📊🏛️'
          -- WHEN l.channel = 'Оформление на партнерском сайте' THEN N'5🤝🤝'
          -- WHEN l.channel = 'Партнеры (лиды)' THEN N'5🤝📋'
          -- WHEN l.channel = 'Сайт орган.трафик' THEN N'3🌐📈'
          -- WHEN l.channel = 'Союз' THEN N'🔟🏢🤝'
          -- WHEN l.channel = 'Тест' THEN N'0️🧪📝'
          -- WHEN l.channel = 'Триггеры LCRM' THEN N'4️🔔📊'
          -- WHEN l.channel = 'Эквифакс' THEN N'4️📊🔍'
           ELSE '' -- или можно указать другое значение по умолчанию
       END AS channel_emoji
 


into #lead
from v_lead2 l with(nolock)
--left join Feodor.dbo.lead fl with(nolock) on fl.id=l.id
join #ids	  r on l.id=r.id



create index i on #lead (phone, created)
create index i on #visits (id, client_id, created)

--select * from #lead	   where phone='9192428055'

--select * from #lead
--where id='dc914c52-c08b-4bc2-b370-40af049213b0'




drop table if exists #leads_by_lead_stg
  select a.id
  , a.created 
  , a.visit_id visit_id_initial 
  , all_leads.visit_id visit_id_for_search 
  
  
  into  #leads_by_lead_stg
  from #lead  a 
--select a.phone, a.id, a.visit_id, b1.created, b1.source from v_lead  a 
join  #lead all_leads on all_leads.phone=a.phone and a.created >=all_leads.created



drop table if exists #visits_by_leads_with_visit

select a.* , b.client_id into  #visits_by_leads_with_visit  from
#leads_by_lead_stg a
join #visits b on a.visit_id_for_search=b.id 



 ;with v  as (select *,   ROW_NUMBER() over(partition by a.id, client_id order by (select 1 ))      
 rn  from #visits_by_leads_with_visit a ) delete from v where rn>1   


drop table if exists #visits_by_lead_stg


select * into 	#visits_by_lead_stg from (
select  a.id aid,  a.visit_id_initial    id1 ,b1.id id2,  b1.source source, b1.created created1, b1.stat_source stat_source
from #visits_by_leads_with_visit a
left join #visits b1 on b1.client_id=a.client_id  and b1.created between  dateadd(day, -90, a.created ) and  dateadd(minute, 0, a.created )
 ) x-- where rn=1


 -- select * from #lead
 -- where phone='9888793519'
 -- select * from #visits_by_leads_with_visit
 -- where id='11d0b876-87a5-47ca-b3a5-0ccce2572634' 
 -- select * from #visits_by_lead_stg
 -- where aid='11d0b876-87a5-47ca-b3a5-0ccce2572634'
--create index i on #visits_by_lead_stg (aid, id2)
--
--
-- ;with v  as (select *,   ROW_NUMBER() over(partition by aid, id2 order by (select 1 ))      
-- rn  from #visits_by_lead_stg ) delete from v where rn>1   
--
-- select top 100 * from  #visits_by_lead_stg
-- where id1 is not null


select  top 100 * from #visits_by_leads_with_visit
where client_id is null

drop table if exists #visits_by_lead

	

select  x.aid
, STRING_AGG(cast(  format (created1, 'dd-MM HH:mm:ss')   as nvarchar(max) ) +case when id2=id1 then N'🌟'  else '' end +' ->  '+ source + case when  source<>isnull(stat_source,'NULL') then   ' -> (stat: '+isnull(stat_source,'NULL') +')' else '' end , '
') within group (order by created1 desc)  vi1
into #visits_by_lead
from #visits_by_lead_stg  x
 group by  x.aid  






drop table if exists #leads_by_lead


 select  b.номер_k

, STRING_AGG( b1.channel_emoji+ cast( format (b1.created, 'dd-MM HH:mm:ss')   as nvarchar(max) )  + isnull(b1.call_result, '') +  ' / '+ b1.source  +case when b.original=b1.id   then '
'+N'   👼'+	 b.Номер  else '' end +									   case when b.marketing=b1.id    then '
'+N'   💸'+	 b.Номер  else '' end 

 , '
') within group (order by b1.created desc)  li1
	into #leads_by_lead
from #request	  b  --a 
--select a.phone, a.id, a.visit_id, b1.created, b1.source from v_lead  a 
 
left join #lead b1 on b1.phone=b.phone  and b1.created <=dateadd(minute, 0, b.created )
--left join #request r_m on r_m.original=B1.ID OR R_M.marketing=B1.ID

 group by  b.номер_k 

 --select * from #leads_by_lead
 --where 	 номер_k='24052702093716'
 --
 drop table if exists #f



-- select * into #t3 from (
--
--select phone, id, entrypoint , created, count(*) over(partition by phone, created ) cnt  from #lead
--) x 
--where cnt>1
--
--select * from  #t3
--order by created desc



select   b.created  ДатаЗаявки
--, b.номер_k Номер
, b.Номер НомерЗаявки
,  b.ТипКредитногоПродукта 
,  b.МестоСоздания 
+ case when b.[Вид займа] <> 'Первичный' then ' (Повт.)' else '' end	  МестоСоздания
 
, b.phone Телефон
, N'👼'+CASE WHEN  b.original =  b.marketing THEN  N'💸' ELSE'' END +l_original.marketing_status + isnull(''+l_original.call_result+'', '') +  case when   b.original <>  b.marketing then '
'+ N'💸' + l.marketing_status + isnull(l.call_result, '??') +format(datediff(day,  l_original.created, b.created), ' 0 days ')  +'' else ''  end   marketing_status
, l_original.type	 +  case when   b.original <>  b.marketing then ' <- ('+ l.type +')' else ''  end	   type
,  N'👼'+CASE WHEN  b.original =  b.marketing THEN  N'💸' ELSE'' END +l_original.entrypoint + format(datediff(MINUTE,  l_original.created, b.created), ' 0 min ') + case when   b.original <>  b.marketing then +'

'+ N'💸'+l.entrypoint+format(datediff(MINUTE, l_original.created, l.created), ' 0 ')   else '' end entrypoint 
,  isnull( case when   b.original <>  b.marketing then  original  end , x.info)  original_lead_idd
, isnull( b.marketing , x1.info)  lead_id 
, cast( case when   b.original <>  b.marketing then N'💸' else N''  end  +cast(l.source	as nvarchar(200))+ 	case when   b.original <>  b.marketing then  N'|| (original:'+ l_original.source +N')' else N''  end  as nvarchar(200))	source_name						    
, b.[Источник]  
, replace(   case when len(lbl.li1)>1500 then left(lbl.li1, 1500)+'...' else  lbl.li1 end , left( b.Номер, 14), N'🌟'+left( b.Номер, 14)  )	leads_info 
,  case when len(vbl.vi1)>1500 then left(vbl.vi1, 1500)+'...' else  vbl.vi1 end 	visits_info 
 
, datediff(minute,  v.created,  b.created 	 )		  [минут С визита]
, v.stat_source
, case when b.[Канал от источника] <> l.channel  then 	l.channel +' - > '+ b.[Канал от источника] else 	l.channel end 	 channel_name
, b.[Exceptions info] 
, b.[Заем выдан] 
,  l.created  ДатаЛида		
,  b.номер_k Номер
 into #f
from  #request	  b
left join #lead l on l.id=b.marketing 
left join #lead l_original on l_original.id=b.original  
left join #visits v on v.id=l.visit_id		
left join #leads_by_lead lbl on lbl.номер_k=b.номер_k
left join #visits_by_lead vbl on vbl.aid=l_original.id
outer apply (select top 1 N'⏮️: '+ ln.entrypoint+ ' '+isnull(ln.call_result, '')  + ' '+ format(datediff(second, b.created, ln.created), '0 secs') info  from #lead ln where b.original is null and ln.phone =b.phone and b.created>=ln.created order by abs(datediff(second, b.created, ln.created) )   )x
outer apply (select top 1 N'⏭️: ' +ln.entrypoint+ ' ' +isnull(ln.call_result, '')  + ' '+ format(datediff(second, b.created, ln.created), '0 secs') info  from #lead ln where b.original is null and ln.phone =b.phone and b.created<ln.created order by abs(datediff(second, b.created, ln.created) )   )x1
--where b.created<=cast(getdate() as date)																			  
--join v v1 on  v1.phone= isnull(a.Телефон , r.client_mobile_phone) and v1.created_at_time<=	    isnull(a.ДатаЗаявки , r.created_at )
--left join vv on vv.id=
--left join v_lead ll on ll.phone = isnull(a.Телефон , r.client_mobile_phone) 
--where  isnull(a.ДатаЗаявки , r.created_at ) >='20240513' and l.source_name='carmoney'   --  and  ( a.isPts=1 or r.product_types_id=1)		
--and ll.id is null
order by 1 	 


--drop table if exists _birs.lf_check_tbl
--select * into _birs.lf_check_tbl from #f
delete a from marketing_attribution_visualisation_log	 a join #f b on a.НомерЗаявки=b.НомерЗаявки
delete a from marketing_attribution_visualisation_log	 a join #f b on a.Номер=b.Номер
insert into marketing_attribution_visualisation_log
select * from #f
--select * from  _birs.lf_check_tbl
--where НОмерзаявки='24052022074971'

 EXEC  sp_birs_update  '1358FD02-6EE8-4CE6-8414-49616CA0B51F'
  

--alter table	_birs.lf_check_tbl alter column source_name nvarchar(255)
--alter table	_birs.lf_check_tbl add    Номер nvarchar(255)


--select top 100 * from marketing_attribution_visualisation_log
--order by 1 desc
 
  
 

 return


--select * from marketing_attribution_visualisation
--order by 1 desc

/*
select top 10000 a.ДатаЗаявки 
, a.НомерЗаявки
, c.[Вид займа]
, a.Телефон 
, a.МестоСоздания
, l_original.marketing_status
, l_original.type_code
, l_original.entrypoint_name+ case when   b.original_lead_id <>  b.marketing_lead_id then ' ('+ l.entrypoint_name+')' else '' end entrypoint_name  
,   case when   b.original_lead_id <>  b.marketing_lead_id then  original_lead_id  end  original_lead_idd
, b.marketing_lead_id  lead_id 
,  l.source_name									    
   ,   case when   b.original_lead_id <>  b.marketing_lead_id then  l_original.source_name  end  original_source_name
 
 , a.ДатаЗаявки 	   ДатаЗаявки2
 , datediff(minute,  v.created_at_time,  a.ДатаЗаявки 	 )		  [С визита]
, v.stat_source
, c.[Источник]  
, c.[Exceptions info]  , l.channel_name, a.[Заем выдан] ,  l.created_at_time
 
from v_request a
left join stg._lf.request b on a.НомерЗаявки=b.number
left join v_lead l on l.id=b.marketing_lead_id
left join v_lead l_original on l_original.id=b.original_lead_id
left join stg._lf.referral_visit v on v.id=l.visit_id			 

left join reports.dbo.dm_factor_analysis_001 c on c.Номер=a.НомерЗаявки
where  a.МестоСоздания = 'ЛКК клиента'	 and  cast(a.[ДатаЗаявки] as date)> ='20240501'  
order by 8	 , 1







select * from stg._LF.source_account where name='leadgid2'
--select * from stg._LF.mms_channel 
order by created_at 
select * from stg._LF.mms_channel 
order by created_at where id='650701fc-3fbb-4f45-a013-266b0c3fb1b4'
 


	 
select * from v_lead

where phone='9097969457'
order by created_at_time



select * from v_request
where телефон='9619141204'
order by ДатаЗаявки



use Analytics
go

select top 10000 a.ДатаЗаявки 
, a.НомерЗаявки
, a.Телефон 
, a.МестоСоздания
, l_original.type_code
, l_original.entrypoint_name+ case when   b.original_lead_id <>  b.marketing_lead_id then ' ('+ l.entrypoint_name+')' else '' end entrypoint_name  
,   case when   b.original_lead_id <>  b.marketing_lead_id then  original_lead_id  end  original_lead_id
, b.marketing_lead_id  lead_id 
 
, case when vv.id=v.id then l.source_name	else '' end  request_marketing_source
, case when l.source_name='carmoney' and count(case when  savv.name <>'carmoney' then 1 end) over(partition by a.НомерЗаявки ) >0 then 'ДЕФЕКТ' end	 ДЕФЕКТ
, savv.name  visit_source
, a.ДатаЗаявки 	   ДатаЗаявки2
, vv.id visit_id
, vv.created_at_time	   visit_created_at_time
, datediff(minute, vv.created_at_time,  a.ДатаЗаявки 	 )		  [С визита]
, v.stat_source
, c.[Источник]  
, c.[Exceptions info]  , l.channel_name, a.[Заем выдан] ,  l.created_at_time
 
from v_request a
left join stg._lf.request b on a.НомерЗаявки=b.number
left join v_lead l on l.id=b.marketing_lead_id
left join v_lead l_original on l_original.id=b.original_lead_id
left join stg._lf.referral_visit v on v.id=l.visit_id
left join stg._lf.referral_visit vv on vv.client_id=v.client_id		 and vv.created_at_time  between '20240503' and b.created_at_time
left join stg._lf.source_account savv on savv.id=vv.source_id

left join reports.dbo.dm_factor_analysis_001 c on c.Номер=a.НомерЗаявки
where  a.[ДатаЗаявки]>='20240425'-- and a.[Заем выдан]>= '20240425'	 
order by   a.[ДатаЗаявки]   desc	, vv.created_at_time desc

 				
				*/


end
