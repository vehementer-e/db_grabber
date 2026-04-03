--revision


CREATE  proc [dbo].[marketing_revision]

@type nvarchar(max) = 'LCRM + CRIB'	 ,
@cur int = 0   
as
 
--alter table config add costs_cpa_for_manual_revision date 

--drop table if exists #t2
 
--select id, source, phone, created, status  into #t2 from v_lead2
--where source ='bankiru' and cast(format( date  , 'yyyy-MM-01') as date)  = '20240501'	 
	
	
			     	
--select * from #t2	
	
	
--  select *, case when ROW_NUMBER() over(partition by phone, cast(created   as date)   order by created) >1 then 'Дубль' else '' end Дубль from (	
 
--select  id, source, phone, created, status from #T2	
--) x	
--order by 3, 4	



declare @month date

if @cur = 0 

set @month   =  dateadd(month,  -1, cast(format(getdate(), 'yyyy-MM-01')  as date))
if @cur = 1 

set @month = dateadd(month,  0, cast(format(getdate(), 'yyyy-MM-01')  as date))


if (select costs_cpa_for_manual_revision from config ) is not null 
set @month = (select costs_cpa_for_manual_revision from config )


declare @to date = dateadd(month, 1, @month)

if @type= 'lead'
begin 



--declare @month date   declare @cur int = 0   if @cur = 0  set @month   =  dateadd(month,  -1, cast(format(getdate(), 'yyyy-MM-01')  as date))	 if @cur = 1   set @month = dateadd(month,  0, cast(format(getdate(), 'yyyy-MM-01')  as date))  declare @to date = dateadd(month, 1, @month)

							  
drop table if exists 	#t2
select id, source, partner_id, phone, created, status, decline, sum  sum , appmetrica into #t2 from v_lead2	with(nolock)
where isnull(case when  source in ('bankiru' ,'bankiru-deepapi' ,'bankiru-deepapi-pts' , 'vbr-api', 'zalogcars', 'Trafficshark'
,'avtolombard24', 'alfalombardru', 'avtolombardsru', 'avtolombardcru', 'sravniru-deepapi', 'click2'
,'sravniru-deepapi'
,'sravniru_adventum'
,'sravniru'
,'sravni-bank'
,'sravniru-ptsinst'
,'sravniru-banner'
,'sravniru-installment-ref'
, 'ldg-ref'
, 'diskrit'
, 'trafficshark'
, 'ldg-ref' 
, 'knowhow-api'


) then source end,  appmetrica) is not null  --or id in (select id from badids_lf)
 



and  created between @month  and @to


--select ','''+source+'''' from v_source where source like 'sravn%'

--select * from v_source
--order by 2

--select * from #t2

--drop table if exists 	#re
-- select id, sum into #re from v_request_external
	
	drop table if exists dbo.marketing_revision_lead

  select x.[id] 
,  x.[source] 
,  x.[partner_id] 
,  x.[phone] 
,  x.[created] 
,  x.[status] 
,  x.[decline] 
,  x.sum sum
,  case when ROW_NUMBER() over(partition by phone,source, cast(created   as date)   order by created) >1 then 'Дубль' else '' end Дубль
  , appmetrica
into dbo.marketing_revision_lead

from (	
 
select  id, source, partner_id, phone, created, status, decline  ,  sum  , appmetrica from #T2	
) x	
--left join 	#re re on re.id=x.id
--order by 2, 4, 5	


--select top 1 * from jobs where Job_Name like '%cpa%'
--exec msdb.dbo.sp_start_job'Analytics._birs Заявки CPA на гугл-диск по итогам месяца'

end


if @type= 'lead_xl'
select * from dbo.marketing_revision_lead


if @type= 'lead_source_xl'
select * from dbo.marketing_revision_lead
where source= 'bankiru-deepapi'



if @type= 'postback'
begin
--declare @month date	  = dateadd(month,  0, cast(format(getdate(), 'yyyy-MM-01')  as date))
--declare @month date	  = dateadd(month, -1, cast(format(getdate(), 'yyyy-MM-01')  as date))

--select @month

drop table if exists #postback_request 
select 
    x.request_number
,   x.lead_leadgen_name
,   x.created 
,   x.visit_stat_info 
,   x.leadgeneratorid 
,   x.leadgeneratorclickid 
,   x.city_region 
,   x.cribid

into #postback_request from (
select 
    a.request_number
,   a.lead_leadgen_name
,   a.created 
,   a.visit_stat_info 
,   a.leadgeneratorid 
,   a.leadgeneratorclickid 
,   a.city_region 
,   row_number() over(partition by a.request_number order by  a.created )  rn 
,   cribid--select * 
from    stg._crib.dm_postbacks	a
where a.request_number is not null
 ) x where x.rn=1	and 1=0



 drop table if exists #r

 select distinct marketing_lead_id  into #r from stg._LF.request

 drop table if exists #lead
 drop table if exists #pb 

 select a.lead_id, a.created_at_time into #pb from  stg._LF.postback a
 drop table if exists #request1

 select a.marketing_lead_id, number, created_at_time into #request1 from stg._LF.request a


 select a.id, partner_id, source_id, visit_id, phone, created_at_time, entrypoint_id into #lead from stg._LF.lead a 
 join #r b on a.id=b.marketing_lead_id



insert into #postback_request 

 select b.number, sa.name, a.created_at_time, v.stat_info, l.partner_id, v.stat_term, null,l.id  from #pb a
 left join 	 #request1 b	 on a.lead_id=b.marketing_lead_id		and b.created_at_time<=a.created_at_time
 left join 	 #lead l on l.id=a.lead_id
 left join 	 stg._LF.source_account sa on sa.id=l.source_id
 left join 	 stg._LF.referral_visit v on v.id=l.visit_id 


drop table if exists #r
drop table if exists #lcrm_leads_full_channel_request


select uf_row_id, uf_source, UF_REGISTERED_AT_date, UF_REGISTERED_AT, UF_PARTNER_ID, UF_CLID, cast(id as nvarchar(36)) id, uf_phone PhoneNumber, UF_TYPE  into #lcrm_leads_full_channel_request 
from stg.[_LCRM].[lcrm_leads_full_channel_request]
where uf_type like 'api%'
and 1=0


insert  into #lcrm_leads_full_channel_request  
select b.number, sa.name, cast(l.created_at_time as date) created_at_time, l.created_at_time, l.partner_id, l.id, l.id, l.phone,  e.name from 
#request1 b	
  join 	 #lead l on l.id=b.marketing_lead_id
  join 	 stg._LF.entrypoint e on e.id=l.entrypoint_id and e.name='api'	
 left join 	 stg._LF.source_account sa on sa.id=l.source_id
 left join 	 stg._LF.referral_visit v on v.id=l.visit_id 


drop table if exists #t1

;

with v  as (
select 	 --top 100
  b.ID [LCRM ID]
, isnull(pb.cribid , b.UF_CLID) [CRIB лид ID]
, case when pb.lead_leadgen_name is not null then 'POSTBACK' else b.UF_TYPE end [Тип]
, null [Тип (теневой)]
,  case when pb.lead_leadgen_name is not null then   pb.lead_leadgen_name else  b.UF_SOURCE end + case when b.ID in (select id from badids_lf) then ' (дефект)' else '' end [Источник]
,null [Источник (теневой)]
, null [Канал - подтип]
, isnull(b.PhoneNumber, a.Телефон) [Телефон]
,null [Телефон доп.]
, a.Номер [Номер заявки]
, cast( b.UF_REGISTERED_AT as smalldatetime)  [Дата создания]
, cast( a.call1 as smalldatetime) [Дата актуализации (Дата Заявки)] 
, isnull(b.UF_PARTNER_ID, pb.leadgeneratorid ) [ID партнера]
, pb.leadgeneratorclickid [ID клика партнера]
, a.[Выданная сумма]  [Одобренная сумма займа (Выданная сумма)]
, a.[Первичная сумма]  [Желаемая сумма займа]
, cast(a.[Заем выдан] as smalldatetime) [Дата выдачи займа]
, null [Заявка - Статус Новый]
, null [Создан как заявка?]
, isnull(pb.city_region,  a.[Регион проживания]) [Регион (итоговый)]
, null  [Шаг подтверждения]
, null [Комментарий]
, case when a.ispts =0 then 1 else 0 end [Заявка инстоллмент]
, cast( a.call1 as date) [День Заявки]
, cast(a.approved as date) [День одобрения займа]
, cast(a.[Заем выдан] as date) [День выдачи займа]
, b.UF_REGISTERED_AT_date [День создания]
, case when a.[Группа каналов] in ('Партнеры', 'Банки', 'Телеком')  then 1 else  0 end as [Оплата за привлечение по партнерскому каналу]
, a.[Группа каналов]  [Группа каналов]
,  a.[Канал от источника]   [Канал от источника]
--,  sz.[Партнеры привлечение]
, a.[Вид займа]
, pb.visit_stat_info
, case when datediff(day, b.UF_REGISTERED_AT_date, cast( a.call1 as date) ) >10 then 1 else 0 end [Более 10 дней с лида]
, cast(a.[Заем погашен] as smalldatetime) [Заем погашен]
, a.ФИО
, a.ispdl
, a.isPts
, a.isInstallment
, a.productType

--, cpa2.Стоимость   Стоимость_Расчетная_Для_Сверки
from  v_fa a  
left join 	 #postback_request pb on pb.request_number=a.Номер
left join #lcrm_leads_full_channel_request  b on a.Номер=b.UF_ROW_ID		 and pb.request_number is null-- and uf_type='api'
--left join Analytics.dbo.[v_Отчет стоимость займа опер] sz on sz.Номер=a.Номер
--left join Analytics.dbo.[Отчет аллоцированные расходы CPA] cpa on cpa.Номер=a.Номер
--left join [dbo].[dm_report_lcrm_cpa_cpc_costs] cpa2 on cpa2.UF_ROW_ID=a.Номер
where   ( cast(format(  a.call1 , 'yyyy-MM-01')  as date)=@month or   cast(format(a.[Заем выдан], 'yyyy-MM-01')  as date) =@month)	 and ( [Предварительное одобрение] is not null or [Отказано] is not null)
 
)

select * into #t1 from v 


;with v  as (select *, row_number() over(partition by [Номер заявки] order by [LCRM ID]) rn from #t1 ) delete from v where rn>1


drop table if exists dbo.marketing_revision_postback


select a.*, x.[Номер заявки] [Номер заявки ПТС тот же лидген] , x.Источник [Источник заявки ПТС тот же лидген], GETDATE() ДатаОтчета
, [Кол-во перс. данных]
into dbo.marketing_revision_postback
from #t1 a
outer apply (select top 1 [Номер заявки], Источник from #t1 b where a.[Заявка инстоллмент]=1 and a.[День выдачи займа] is not null and b.[Заявка инстоллмент]=0 and b.Телефон=a.Телефон 
and 
b.Источник<>''
and 
a.Источник<>''
and 
(
a.Источник like '%'+b.Источник+'%' or
b.Источник like '%'+a.Источник+'%'  )

) x

outer apply (select count(distinct ФИО) [Кол-во перс. данных] from #t1 b
where b.Телефон=a.Телефон 
and 
b.Источник<>''
and 
a.Источник<>''
and 
(
a.Источник like '%'+b.Источник+'%' or
b.Источник like '%'+a.Источник+'%'  )

) frod
--where a.[Заявка инстоллмент]=1 and [День выдачи займа] is not null


end
if @type= 'request_pb_xl'
select * from dbo.marketing_revision_postback

if @type= 'postback_source_xl'
select * from dbo.marketing_revision_postback
where Источник= 'bankiru-deepapi'



if @type= 'request'
begin

drop table if exists #t
select cast(id as nvarchar(36)) id , UF_CLID, UF_ROW_ID, UF_TYPE,  UF_SOURCE, PhoneNumber, UF_REGISTERED_AT,  UF_PARTNER_ID ,  UF_REGISTERED_AT_date ,  cast(id as nvarchar(4000))  stat_term, cast(null as nvarchar(255)) tracker_name into #t

from stg.[_LCRM].[lcrm_leads_full_channel_request]
where 1=0




 drop table if exists #r1

 select distinct marketing_lead_id  into #r1 from stg._LF.request

 drop table if exists #request2

 select a.marketing_lead_id, number, created_at_time into #request2 from stg._LF.request a


 drop table if exists #lead1


 select a.id, partner_id, source_id, visit_id, phone, created_at_time, entrypoint_id, type_code into #lead1 from stg._LF.lead a 
 join #r1 b on a.id=b.marketing_lead_id



 insert into #t
select  b.id, b.id UF_CLID, a.number UF_ROW_ID, b.type_code UF_TYPE,  sa.name UF_SOURCE, b.phone PhoneNumber, b.created_at_time UF_REGISTERED_AT, isnull( b.partner_id, v.stat_info)  UF_PARTNER_ID, cast( b.created_at_time     as date) 	 , stat_term
, am.tracker_name

from #request2 a
left join #lead1 b on a.marketing_lead_id=b.id
left join stg._lf.source_account sa on sa.id=b.source_id
left join stg._lf.referral_visit v on v.id=b.visit_id
left join stg._lf.referral_appmetrica_event am on am.id=v.appmetrica_event_id


--select * from dwh where table_name like '%appm%'

--declare @month date	  = dateadd(month,  0, cast(format(getdate(), 'yyyy-MM-01')  as date))

drop table if exists #t0

;

with v  as (
select 	 --top 100
  b.ID [LCRM ID]
, b.UF_CLID [CRIB лид ID]
, b.UF_TYPE [Тип]
, Null [Тип (теневой)]
, a.Источник + case when b.ID in (select id from badids_lf) then ' (дефект)' else '' end [Источник]
,Null [Источник (теневой)]
,Null [Канал - подтип]
, b.PhoneNumber [Телефон]
, Null [Телефон доп.]
, a.Номер [Номер заявки]
, cast( b.UF_REGISTERED_AT as smalldatetime)  [Дата создания]
, cast( a.call1 as smalldatetime) [Дата актуализации (Дата Заявки)] 
, b.UF_PARTNER_ID [ID партнера]
, b.stat_term [ID клика партнера]
, a.[Выданная сумма]  [Одобренная сумма займа (Выданная сумма)]
 ,a.[Первичная сумма]  [Желаемая сумма займа]
, cast(a.[Заем выдан] as smalldatetime) [Дата выдачи займа]
, null [Заявка - Статус Новый]
, Null [Создан как заявка?]
,    a.[Регион проживания]  [Регион (итоговый)]
,Null  [Шаг подтверждения]
, null [Комментарий]
, case when a.ispts =0 then 1 else 0 end [Заявка инстоллмент]
, cast( a.call1 as date) [День Заявки]
, cast(a.Одобрено as date) [День одобрения займа]
, cast(a.[Заем выдан] as date) [День выдачи займа]
, b.UF_REGISTERED_AT_date [День создания]
, case when a.[Группа каналов] in ('Партнеры', 'Банки', 'Телеком')  then 1 else  0 end as [Оплата за привлечение по партнерскому каналу]
, a.[Группа каналов]  [Группа каналов]
, a.[Канал от источника]  [Канал от источника]
--,  sz.[Партнеры привлечение]
, a.[ВИд займа]
, cpa2.Стоимость   Стоимость_Расчетная_Для_Сверки
, cast(a.[Заем погашен] as smalldatetime) [Заем погашен]
, a.ispdl
, a.isPts
, a.isInstallment
, a.ФИО
, b.tracker_name
, a.productType

from  v_fa a  
join #t b on a.Номер=b.UF_ROW_ID
--left join Analytics.dbo.[v_Отчет стоимость займа опер] sz on sz.Номер=a.Номер
--left join Analytics.dbo.[Отчет аллоцированные расходы CPA] cpa on cpa.Номер=a.Номер
left join [dbo].[dm_report_lcrm_cpa_cpc_costs] cpa2 on cpa2.UF_ROW_ID=a.Номер
where   ( cast(format(  a.call1 , 'yyyy-MM-01')  as date)=@month or   cast(format(a.[Заем выдан], 'yyyy-MM-01')  as date) =@month)
 	--and 1=0
)

select * into #t0 from v 


;with v  as (select *, row_number() over(partition by [Номер заявки] order by [LCRM ID]) rn from #t0 ) delete from v where rn>1

drop table if exists dbo.marketing_revision_request
select a.*, x.[Номер заявки] [Номер заявки ПТС тот же лидген] , x.Источник [Источник заявки ПТС тот же лидген], GETDATE() ДатаОтчета, [Кол-во перс. данных] into dbo.marketing_revision_request from #t0 a
outer apply (select top 1 [Номер заявки], Источник from #t0 b where a.[Заявка инстоллмент]=1 and a.[День выдачи займа] is not null and b.[Заявка инстоллмент]=0 and b.Телефон=a.Телефон 
and 
b.Источник<>''
and 
a.Источник<>''
and 
(
a.Источник like '%'+b.Источник+'%' or
b.Источник like '%'+a.Источник+'%'  )

) x

outer apply (select count(distinct ФИО) [Кол-во перс. данных] from #t0 b
where b.Телефон=a.Телефон 
and 
b.Источник<>''
and 
a.Источник<>''
and 
(
a.Источник like '%'+b.Источник+'%' or
b.Источник like '%'+a.Источник+'%'  )

) frod


--where a.[Заявка инстоллмент]=1 and [День выдачи займа] is not null

end

if @type= 'request_xl'
select * from dbo.marketing_revision_request

 

 
if @type= 'request_source_xl'
select * from dbo.marketing_revision_request
where источник='bankiru-deepapi'

 
--drop proc  [costs_cpa_for_manual_revision] 
 
if @type= 'current month'
begin

update config set  costs_cpa_for_manual_revision =  cast(DATEADD(MONTH,  DATEDIFF(MONTH, 0,    getdate()       ), 0) as date)   --текущий мес


exec dbo.marketing_revision 'postback'
exec dbo.marketing_revision 'lead'
exec dbo.marketing_revision 'request'
exec python 'marketing_revision(source="bankiru-deepapi")', 1
exec python 'marketing_revision()', 1
--exec sp_create_job 'Analytics._marketing_revision at 8:00', 'exec [marketing_revision] ''current month''', '1', '80000'
end


if @type= 'last month'
begin

update config set  costs_cpa_for_manual_revision =  cast(DATEADD(MONTH,  -1+DATEDIFF(MONTH, 0,    getdate()       ), 0) as date)   


exec dbo.marketing_revision 'postback'
exec dbo.marketing_revision 'lead'
exec dbo.marketing_revision 'request'
exec python 'marketing_revision(source="bankiru-deepapi")', 1
exec python 'marketing_revision()', 1
--exec sp_create_job 'Analytics._marketing_revision at 8:00', 'exec [marketing_revision] ''current month''', '1', '80000'
end


if @type= 'last but one month'
begin

update config set  costs_cpa_for_manual_revision =    cast(DATEADD(MONTH,  -2+DATEDIFF(MONTH, 0,    getdate()       ), 0) as date)   


exec dbo.marketing_revision 'postback'
exec dbo.marketing_revision 'lead'
exec dbo.marketing_revision 'request'
exec python 'marketing_revision(source="bankiru-deepapi")', 1
exec python 'marketing_revision()', 1


--exec sp_create_job 'Analytics._marketing_revision last but one month manual' , 'marketing_revision ''last but one month'' ', '0'
end




