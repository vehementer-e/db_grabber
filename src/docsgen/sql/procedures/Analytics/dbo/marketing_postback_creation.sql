 
CREATE    proc  [dbo].[marketing_postback_creation] @mode nvarchar(max) = 'update'
 
as 
 
if @mode = 'update'
begin
 


 drop table if exists #id
select distinct a.taskId into #id from v_postback  a left join postback b on a.taskid=b.taskid
where (b.taskid is null or a.updated<>b.updated  )
and a.created>=getdate()-60
and a.created>='20250301'

--select @date



drop table if exists #s
drop table if exists #t1
drop table if exists #p
select id, name into #s from stg._lf.source_account



select a.[taskId] id, created created_at_time,  lead_id, phone , eventName event_name, updated updated_at_time, STATUS, source, sendingStatus into #p from v_postback a
join #id b on a.taskId=b.taskId
 



drop table if exists #pd

select distinct lead_id into #pd from #p


drop table if exists #lead


select a.id, a.source_id, region_id, created_at_time, partner_id, visit_id, type_code into #lead from stg._lf.lead a join #pd   b on a.id=b.lead_id

drop table if exists #vd

select distinct visit_id into #vd from #lead

drop table if exists #visit
select a.id, a.created_at_time, a.stat_info, a.stat_term into #visit from stg._lf.referral_visit a join #vd b on a.id=b.visit_id




drop table if exists #request

select number, created_at_time, marketing_lead_id, date, id into #request from stg._lf.request

select
    [taskId]=a.id
,   [created]=a.[created_at_time]
,   [updated]=a.[updated_at_time]
,   [STATUS] =	a.STATUS
,   [eventRequestId] =''
,   [eventName] = a.[event_name] +case when r.id is null then '('+b.type_code+')' else '' end
,   [postback_leadgen_name]= a.source
,   lead_id= a.lead_id
,   [phone]=a.[phone]
,   [lead_created] =b.created_at_time
,   [lead_leadgen_name] = c.name
,   [request_number] =r.number
,   [request_created] =r.date
,   [request_status_for_postback] =event_name

,   leadgeneratorid = isnull(v.stat_info, b.partner_id)
,   leadgeneratorclickid =v.stat_term
,   city_region =region.name
, sendingStatus =  a.sendingStatus 
into #t1
from #p a
left join #lead b on a.lead_id=b.id
left join stg._lf.region region on region.id=b.region_id
left join #request r on r.marketing_lead_id=b.id	 and r.[created_at_time]<=a.[created_at_time]
left join  #visit  v on v.id=b.visit_id
left join #s c on c.id=b.source_id
--left  JOIN  stg._lf.config_postback_config cpc ON a.postback_config_id = cpc.id
--left join #s c1 on c1.id=cpc.source_id

--where a.created_at_time >= getdate()-90
 
delete  a from postback a join #t1 b on a.taskid=b.taskid
insert into postback
select * from #t1 

--alter table postback add sendingStatus nvarchar(50)

--drop table if exists postback
--select * into postback from #t1
end