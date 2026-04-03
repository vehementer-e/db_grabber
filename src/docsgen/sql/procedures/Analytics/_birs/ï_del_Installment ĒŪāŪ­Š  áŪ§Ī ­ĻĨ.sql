CREATE   proc [_birs].[Installment воронка создание]

@mode nvarchar(max) = 'select'		   , @recreate int =0

as
begin
   
if @mode  = 'visits'
begin  

drop table if exists #visits

select-- top 0
  created = cast(created as date) 
, stat_source =  stat_source
, stat_type =   stat_type 
, visits = count(*) 
, unique_visits = count(distinct client_google_id)  

into #visits  --select top 100 *

from stg._crib.visits   with(nolock)
where cast(created as date)>= cast(getdate()-10 as date)
group by 
  cast(created as date)  
, stat_source	    
, stat_type


--select * into _birs.visits_stat
--from #visits

delete a from _birs.visits_stat  a join #visits b on  a.created = b.created  
insert into   _birs.visits_stat 
select * from #visits




end
      
if @mode  = 'calls_inst'
begin  

drop table if exists #calls_inst_stg 
select --top 0 
attempt_start, project_id, client_number,case when  login is not null then attempt_start end attempt_start_login  into #calls_inst_stg from NaumenDbReport.dbo.detail_outbound_sessions
where project_id in (
'corebo00000000000ogs9ci91h86tk38', 
'corebo00000000000nr8tj5chijbg124', 
'corebo00000000000ogthe6vlmtgegak', 
'corebo00000000000ntveeltm4rn8h3c', 
'corebo00000000000o850i7n9g4sb1io', 
'corebo00000000000o852j2fm4a48cj4', 
'corebo00000000000ntveaeqb47pg1q0', 
'corebo00000000000nqvsc5jtklnqd70'
) and attempt_start>=cast(getdate()-10 as date) --'20230511'


--select * into _birs.installment_calls_on_abandoned_requests_and_drafts
--from #calls_inst_stg

delete a from   _birs.installment_calls_on_abandoned_requests_and_drafts  a join #calls_inst_stg b on cast(a.attempt_start as date) =  cast(b.attempt_start as date)
insert into   _birs.installment_calls_on_abandoned_requests_and_drafts 
select * from #calls_inst_stg


end
   
if @mode  = 'update_lead_request'
begin

drop table if exists #requests
select id, try_cast(lcrm_id as numeric) lcrm_id into #requests
from   stg._LK.requests
where is_installment=1	   or product_types_id in (2,3)

drop table if exists #installment_lead_request

--select * from config

select
  a.ДатаЛидаЛСРМ                                                                                             [ДатаЛидаЛСРМ]
, a.is_inst_lead                                                                                             [is_inst_lead]
, a.UF_SOURCE	                                                                                             [UF_SOURCE]
, a.UF_TYPE		                                                                                             [UF_TYPE]
, case when isnull(UF_TYPE, '')<>'api' or r.lcrm_id  is not null then a.id end                               [id]
,  r.id                                                                                                      [request_id]
, count(a.id)                                                                                                [Лидов]
, count(ВремяПервойПопытки)                                                                                  [Лидов с попыткой] 
, count(ВремяПервогоДозвона)                                   	                                             [Лидов с дозвоном]
, count(case when UF_LOGINOM_STATUS='accepted' then a.id end)                                                [Лидов accepted]
, count(case when ФлагПрофильныйИтог=1 then a.id end) 	                                                     [Лидов профильных]
, a.uf_stat_ad_type		                                                                                     [uf_stat_ad_type]
, try_cast(case when isnull(UF_TYPE, '')<>'api' or r.lcrm_id  is not null then UF_PHONE end as nvarchar(10)) [UF_PHONE]
, case when isnull(UF_TYPE, '')<>'api' or r.lcrm_id  is not null then UF_REGISTERED_AT end                   [UF_REGISTERED_AT]
, case when UF_LOGINOM_STATUS='accepted' then 1 else 0 end                                                   [is_accepted] 
, case when isnull(UF_TYPE, '')<>'api' or r.lcrm_id  is not null then [UF_PARTNER_ID аналитический] end    	 [UF_PARTNER_ID аналитический]
, case when isnull(UF_TYPE, '')<>'api' or r.lcrm_id  is not null then [UF_LOGINOM_STATUS]   end    	         [UF_LOGINOM_STATUS]  
, case when isnull(UF_TYPE, '')<>'api' or r.lcrm_id  is not null then [ВремяПервойПопытки]  end    	         [ВремяПервойПопытки] 
, case when isnull(UF_TYPE, '')<>'api' or r.lcrm_id  is not null then [ВремяПервогоДозвона] end    	         [ВремяПервогоДозвона]
 
into #installment_lead_request

from Feodor.dbo.dm_leads_history a
left join #requests r on a.id= r.lcrm_id  
--where  a.ДатаЛидаЛСРМ >='20230511'
where  a.ДатаЛидаЛСРМ >=cast(getdate()-40 as date)
group by
 a.ДатаЛидаЛСРМ
,a.is_inst_lead
,a.UF_SOURCE
,a.UF_TYPE
,case when isnull(UF_TYPE, '')<>'api' or r.lcrm_id  is not null then a.id end  	 
,r.id
,a.uf_stat_ad_type
,try_cast(case when isnull(UF_TYPE, '')<>'api' or r.lcrm_id  is not null then UF_PHONE end as nvarchar(10))
,case when isnull(UF_TYPE, '')<>'api' or r.lcrm_id  is not null then UF_REGISTERED_AT end  		 
,case when UF_LOGINOM_STATUS='accepted' then 1 else 0 end   
,case when isnull(UF_TYPE, '')<>'api' or r.lcrm_id  is not null then [UF_PARTNER_ID аналитический] end    	  
,case when isnull(UF_TYPE, '')<>'api' or r.lcrm_id  is not null then [UF_LOGINOM_STATUS]   end    
,case when isnull(UF_TYPE, '')<>'api' or r.lcrm_id  is not null then [ВремяПервойПопытки]  end    
,case when isnull(UF_TYPE, '')<>'api' or r.lcrm_id  is not null then [ВремяПервогоДозвона] end    

--select top 10000 * from #installment_lead_request
--where uf_stat_ad_type='promo' and uf_type<>'api'--and uf_stat_ad_type = ''
--order by 1 desc
 
--drop table if exists _birs.[installment_lead_request]
--select * into 	_birs.[installment_lead_request]
--select *
--from 	  #t1

delete a from _birs.[installment_lead_request]  a 
join   #installment_lead_request b on a.ДатаЛидаЛСРМ=b.ДатаЛидаЛСРМ
insert into 	_birs.[installment_lead_request]
select * from  #installment_lead_request
--where UF_PHONE='9829166875'
--order by 1

--select top 100 *
--from _birs.[installment_lead_request]  a
																					   
--alter table  _birs.[installment_lead_request] add uf_stat_ad_type  varchar(128) 
--alter table  _birs.[installment_lead_request] add UF_PHONE  nvarchar(10) 
--alter table  _birs.[installment_lead_request] add UF_REGISTERED_AT  datetime2(0) 
--alter table  _birs.[installment_lead_request] add is_accepted tinyint
--alter table  _birs.[installment_lead_request] add is_accepted tinyint								   
--alter table  _birs.[installment_lead_request] add [UF_PARTNER_ID аналитический] varchar(256) 
--alter table  _birs.[installment_lead_request] add [UF_LOGINOM_STATUS] varchar(128) 
--alter table  _birs.[installment_lead_request] add [ВремяПервойПопытки] datetime2 
--alter table  _birs.[installment_lead_request] add [ВремяПервогоДозвона] datetime2

end

if @mode  = 'update'
begin
 --exec [_birs].[Installment воронка создание]	'update_lead_request'


drop table if exists #help_id

SELECT id
	,ДатаЛидаЛСРМ
	,UF_TYPE
	,UF_PHONE
	,UF_LOGINOM_STATUS
	,ВремяПервойПопытки
	,UF_REGISTERED_AT
	,ВремяПервогоДозвона
	into  #help_id
FROM _birs.[installment_lead_request]
WHERE UF_TYPE <> 'api'
	AND ДатаЛидаЛСРМ >= '20230511'

drop table if exists  #lk_help_lead
SELECT 
     a.id	id_lk
    ,a.created_at
	,x.id lcrm_id
	,x.uf_type
	into #lk_help_lead
FROM _birs.[Installment тайминг таблица] a
cross APPLY (
	SELECT TOP 1 *
	FROM #help_id b
	WHERE b.UF_PHONE = a.client_mobile_phone
		AND a.created_at_date = b.ДатаЛидаЛСРМ
		AND a.created_at  < b.UF_REGISTERED_AT
		and isnull(try_cast(a.lcrm_id as numeric), 0)<>try_cast(b.id		as numeric)
		order by   UF_REGISTERED_AT
	) x

drop table if exists  #lk_help_lead2
SELECT 
     a.id	id_lk
   	,x.id lcrm_id
	,x.uf_type
	,x.ВремяПервойПопытки
	,x.ВремяПервогоДозвона
	into #lk_help_lead2
FROM _birs.[Installment тайминг таблица] a
cross APPLY (
	SELECT TOP 1 *
	FROM #help_id b
	WHERE b.UF_PHONE = a.client_mobile_phone
		AND  b.ДатаЛидаЛСРМ between a.created_at_date and dateadd(day, 1,  a.created_at_date  )
		AND a.created_at  < b.UF_REGISTERED_AT
		and isnull(try_cast(a.lcrm_id as numeric), 0)<>try_cast(b.id		as numeric)
		order by   ВремяПервогоДозвона desc ) x

  drop table if exists #calls_inst 
  select attempt_start, project_id, client_number, attempt_start_login  into #calls_inst 
from _birs.installment_calls_on_abandoned_requests_and_drafts
  
drop table if exists  #lk_help_lead3
SELECT 
     a.id	                id_lk
	,x.attempt_start        attempt_start
	,x.attempt_start_login  attempt_start_login
	into #lk_help_lead3
FROM _birs.[Installment тайминг таблица] a
cross APPLY (
	SELECT TOP 1 *
	FROM #calls_inst b
	WHERE b.client_number = '8'+a.client_mobile_phone
		AND  cast(b.attempt_start as date) between a.created_at_date and dateadd(day, 1,  a.created_at_date  )
		AND a.created_at  < b.attempt_start
						  order by attempt_start_login desc
	) x

drop table if exists #voronka_inst

select 
  День = isnull( a.ДатаЛидаЛСРМ, b.created_at_date) 
, [Как создан] = 
					case 
					when a.ДатаЛидаЛСРМ  is null then 'REF' when a.uf_type ='api'   then  'api'
					when a.uf_type  in ('loginom', 'import')   then a.uf_type  
					else 'REF' end 

, is_inst_lead                  = isnull( a.is_inst_lead, 1) 
, uf_source                     = case when  a.ДатаЛидаЛСРМ is null then 'Без привязки к лиду' else  a.uf_source end   
, uf_type                       = case when  a.uf_type is null then 'Без привязки к лиду' else  a.uf_type end   
, [UF_PARTNER_ID аналитический] = a.[UF_PARTNER_ID аналитический] 
, UF_STAT_AD_TYPE               = a.UF_STAT_AD_TYPE 
, Телефон                       = isnull(b.[client_mobile_phone] , a.UF_PHONE)	 
, id_lead_request               = a.id 	  
, uf_registered_at              = a.uf_registered_at 	  
, is_accepted                   = a.is_accepted 	  


 ,[Лидов]            = case when b.id is not null then 1 else [Лидов] end             
 ,[Лидов accepted]   = case when b.id is not null then 1 else [Лидов accepted] end    
 ,[Лидов с попыткой] = case when b.id is not null then 1 else [Лидов с попыткой] end  
 ,[Лидов с дозвоном] = case when b.id is not null then 1 else [Лидов с дозвоном] end  
 ,[Лидов профильных] = case when b.id is not null then 1 else [Лидов профильных] end  

 ,     b.*

 , [Тип лида после заявки]=	 c.UF_TYPE            
 , [Время попытки после заявки]	= isnull(c.ВремяПервойПопытки,  c1.attempt_start)       
 , [Время дозвона после заявки]	= isnull(c.ВремяПервогоДозвона, c1.attempt_start_login) 
 
into #voronka_inst

from  _birs.[installment_lead_request] a
full outer join  _birs.[Installment тайминг таблица] b on a.request_id = b.id

left join #lk_help_lead2	 c on c.id_lk=b.id
left join #lk_help_lead3	  c1 on c1.id_lk=b.id
where isnull( a.ДатаЛидаЛСРМ, b.created_at_date)<getdate()-1

drop table if exists #loans
select [Заем выдан]  ,   [Заем погашен],    Телефон, Номер, isInstallment into #loans 
from mv_dm_Factor_Analysis 
where [Заем выдан] is not null	  and [Заем выдан]<='20231129'

insert into 	 #loans
select [Дата выдачи], [Дата погашения], [Телефон договор CMR], [Номер заявки], isInstallment 
from mv_loans 
where [Номер заявки] not in (select Номер from #loans)

drop table if exists #green
select distinct cdate
, phone 
into #green 
from dwh2.[marketing].[povt_inst]
where  	market_proposal_category_code = 'green' 


drop table if exists #voronka_inst2

  select a.*, 
  Дубль2 = case 
  when a.[Выдача денег] is not null then 0
  when a.[Как создан]='ref' and  a.Телефон is not null and a.День is not null and  row_number() over(partition by a.[Как создан],  a.День, a.Телефон order by a.current_status desc, [Лидов профильных] desc, [Лидов с дозвоном] desc,  [Лидов с попыткой] desc,  [Лидов accepted] desc,  a.uf_registered_at) <> 1 then 1  
  when a.[Как создан]='api' and  a.Телефон is not null and a.День is not null and  row_number() over(partition by a.[Как создан],  a.День, a.Телефон order by a.current_status desc )  <>1 then 1
  when a.[Как создан]='api' and  a.Телефон is  null and is_accepted=0 then 1
  else 0 end	 
  , [Вид займа лид] =  ISNULL(a.[Вид займа],
  case 
  when  [docr_tel].cnt_dcr>0  then 'Докредитование'
  when  [povt_tel].cnt_povt>0 then 'Повторный'
  when  Телефон is not null and a.uf_registered_at is not null then 'Первичный'
  else 'Первичный' end ) 
 ,[Наличие зеленого предложения] = case when pinst.cdate is not null then 'Зеленый' end	 
 ,previous_closed_dt = [povt_tel].previous_closed_dt
   into #voronka_inst2
  from #voronka_inst	a
  outer apply (select count(*) cnt_povt, max([Заем погашен]) previous_closed_dt from #loans b where isInstallment=1 and   (/*(a.[Ссылка клиент]=b.[Ссылка клиент]  and a.[Ссылка клиент]<>0 ) or*/ a.Телефон=b.Телефон) and isnull(b.[Заем погашен], GETDATE() ) <= a.uf_registered_at  	 )  [povt_tel]
  outer apply (select count(*) cnt_dcr from #loans b where isInstallment=1 and (/*(a.[Ссылка клиент]=b.[Ссылка клиент]  and a.[Ссылка клиент]<>0 ) or*/  a.Телефон=b.Телефон) and b.[Заем выдан]<=a.uf_registered_at and isnull(b.[Заем погашен], GETDATE() ) > a.uf_registered_at  )    [docr_tel]	 

  left join #green	pinst on pinst.[cdate] =a.День and pinst.phone=a.Телефон--u.id


  	if @recreate = 1
	begin
    drop table if exists _birs.[Installment_conversions]
    select * into        _birs.[Installment_conversions] from #voronka_inst2

	return
	end


--
--
 
delete from _birs.[Installment_conversions]
insert into _birs.[Installment_conversions]
select * from #voronka_inst2
--  where [Телефон]='9628176119'
exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '2367C832-0562-4CF5-98F7-7AD4A978A255'	 , 1

end


if @mode = 'select' 
begin

--drop table if exists #visits

--select-- top 0
--  created = cast(created as date) 
--, stat_source =  stat_source
--, stat_type =   stat_type 
--, visits = count(*) 
--, unique_visits = count(distinct client_google_id)  

--into #visits  --select top 100 *

--from stg._crib.visits   with(nolock)
--group by 
--  cast(created as date)  
--, stat_source	    
--, stat_type

;

with v as (


select  
  isnull(b.created    , a.День           )                                        День2
, isnull(b.stat_source, a.uf_source      )                                        Источник2 
, isnull(b.stat_type  , a.UF_STAT_AD_TYPE)                                        UF_STAT_AD_TYPE2 
, case when 	b.created  is not null then 'REF' else [Как создан] end           [Как создан2]
, case when 	b.created  is not null then 'Первичный' else [Вид займа лид] end  [Вид займа лид2]
, case when 	b.created  is not null then 0  else Дубль2 end                     Дубль3
, b.visits                                                                         visits
, b.unique_visits                                                                  unique_visits 
, a.* 
, datediff(day, previous_closed_dt, isnull ( b.created , a.День ) )                days_since_previous_closed

from _birs.[Installment_conversions] a
full outer join _birs.visits_stat  b on 1=0
where isnull ( b.created , a.День ) between '20230511' and GETDATE()-1
)
--select count(*) cnt from v																									  
select --top 200000
* 	
, case when DATEDIFF(DAY, [Выдача денег], [Заем погашен])<=7 then 1 else 0 end  [ПДП 7 дней]
, cast(format(День2, 'yyyy-MM-01') as date) Месяц
, dateadd(day, datediff(day, '1900-01-01', День2) / 7 * 7, '1900-01-01')  Неделя
from v
--order by visits desc
return
exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '2367C832-0562-4CF5-98F7-7AD4A978A255'	 , 1

end

   
if @mode = 'bankiru-installment-context' 
begin

drop table if exists   #t2

select id, uf_registered_at, phonenumber, uf_type into #t2 from stg._LCRM.lcrm_leads_full_calculated
where uf_source = 'bankiru-installment-context'
;
with v as (
select phonenumber, min(uf_registered_at)  uf_registered_at, STRING_AGG(uf_type, ',')  within group(order by uf_registered_at ) types from 	#t2
group by   phonenumber
)
			 
select v.*, a.* from
  v left join
_birs.[Installment воронка]  a	  on v.phonenumber=a.Телефон and a.Дата>= dateadd(hour, -1, v.uf_registered_at)
order by 2

end


end