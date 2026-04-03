
CREATE proc   [dbo].[_request_add_product]
as
 
 /*
 drop table if exists lk_requests_test_branches
select * into  lk_requests_test_branches from openquery (lkprod , 'select * from requests_test_branches limit 10000' ) 


alter table _request_log add addProductInsuranceDraft nvarchar(50)              
alter table _request_log add addProductInsuranceCall1 nvarchar(50)                   
alter table _request_log add addProductInsuranceCall2  nvarchar(50)               
alter table _request_log add addProductInsuranceCall3 nvarchar(50)        

alter table _request add addProductInsuranceDraft 	nvarchar(50)        
alter table _request add addProductInsuranceCall1	nvarchar(50)        
alter table _request add addProductInsuranceCall2	nvarchar(50)        
alter table _request add addProductInsuranceCall3	nvarchar(50)        


*/

 update b set b.abAddProductInsuranceDraft = c.name
 from 
Stg._LK.[requests_test_branches] a 
join _request b on a.request_id=b.id and b.abAddProductInsuranceDraft is null and a.ab_test_id=4
join [Stg].[_LK].[ab_cases] c on c.id=a.ab_case_id  


 update b set b.abAddProductInsuranceDraft = c.name
 from 
Stg._LK.[requests_test_branches] a 
join _request b on a.request_id=b.id and b.abAddProductInsuranceDraft is null and a.ab_test_id=5
join [Stg].[_LK].[ab_cases] c on c.id=a.ab_case_id  



 
--  alter table Analytics.dbo._request alter column abAddProductInsuranceDraft varchar(255)
--  alter table Analytics.dbo._request_log alter column abAddProductInsuranceDraft varchar(255)
 
 
--select c.name from 
--Stg._LK.[requests_test_branches] a 
--join _request b on a.request_id=b.id and b.abAddProductInsuranceDraft is null and a.ab_test_id=4
--join [Stg].[_LK].[ab_cases] c on c.id=a.ab_case_id  

--select * from Stg._LK.[requests_test_branches] 

drop table if exists #addDraft

select b.guid, a.product + case when a.seller <> '' then '('+ a.seller+')' else '' end product, a.created, a.ison, a.ischangeState into #addDraft from  _request b join
dbo.v_request_add_product_history a   on a.link=b.link and (  a.status in ('черновик', 'Прикрепление фото паспорта') or a.created < b.call1) and a.isMain=1 
and a.status<>'Забраковано'
and a.status<>'Подписание 1-го пакета (ПТС)'

;with v  as (select *, row_number() over(partition by guid order by created desc, ison desc) rn from #addDraft ) delete from v where rn>1


 update b set b.addProductInsuranceDraft = a.product
 from 
#addDraft a join _request b on a.guid=b.guid and a.ison=1

--select * from #addDraft order by created desc

drop table if exists #addCall1

select b.guid, a.product + case when a.seller <> '' then '('+ a.seller+')' else '' end product, a.created, a.ison into #addCall1 from  _request b join
dbo.v_request_add_product_history a   on a.link=b.link and (  a.status in ('Предварительное одобрение') or a.created < b.call1approved) and a.isMain=1 and  a.status<>'Забраковано'

;with v  as (select *, row_number() over(partition by guid order by created desc, ison desc) rn from #addCall1 ) delete from v where rn>1



 update b set b.addProductInsuranceCall1 = a.product
 from 
#addCall1 a join _request b on a.guid=b.guid  and a.ison=1



drop table if exists #addCall2

select b.guid, a.product + case when a.seller <> '' then '('+ a.seller+')' else '' end product, a.created, a.ison into #addCall2 from  _request b join
dbo.v_request_add_product_history a   on a.link=b.link and (    a.created < b.call2Approved) and a.isMain=1 and  a.status<>'Забраковано'

;with v  as (select *, row_number() over(partition by guid order by created desc, ison desc) rn from #addCall2 ) delete from v where rn>1
 
  update b set b.addProductInsuranceCall2 = a.product
 from 
#addCall2 a join _request b on a.guid=b.guid  and a.ison=1


 
drop table if exists #addCall3

select b.guid, a.product + case when a.seller <> '' then '('+ a.seller+')' else '' end product, a.created, a.ison into #addCall3 from  _request b join
dbo.v_request_add_product_history a   on a.link=b.link and ( a.status='Одобрено' or   a.created < b.approved) and a.isMain=1 and  a.status<>'Забраковано'

;with v  as (select *, row_number() over(partition by guid order by created desc, ison desc) rn from #addCall3 ) delete from v where rn>1
 
  update b set b.addProductInsuranceCall3 = a.product
 from 
#addCall3 a join _request b on a.guid=b.guid  and a.ison=1




drop table if exists #addFinal

select b.guid,b.link, a.product + case when a.seller <> '' then '('+ a.seller+')' else '' end product, a.created, a.ison, a.ischangestate, a.seller into #addFinal from  _request b join
dbo.v_request_add_product_history a   on a.link=b.link   and a.isMain=1 and  a.status<>'Забраковано'

;with v  as (select *, row_number() over(partition by guid order by created desc, ison desc) rn from #addFinal ) delete from v where rn>1
 
  update b set b. addProductInsuranceFinal = a.product 
 from 
#addFinal a join _request b on a.guid=b.guid   and a.ison=1



drop table if exists #addLastOn

select b.guid,b.link,   product, a.created, a.ison  into #addLastOn from  _request b join
dbo.v_request_add_product_history a   on a.link=b.link   and a.isMain=1 and  a.ison=1


;with v  as (select *, row_number() over(partition by guid order by created desc) rn from #addLastOn ) delete from v where rn>1




drop table if exists #addOffs
select a1.guid, a1.product,a1.created, a1.ison  , a.status, format(a.created, 'yyyy-MM-dd HH:mm:ss')+' ('+a.status+') '+ a.seller +' отключил '+a.product AddProductInsuranceOffDesc 
, a.created offDate
 into #addOffs

from  #addLastOn a1 join
dbo.v_request_add_product_history a  on a1.link=a.link and a.ison=0 and a.created>a1.created and a1.product = a.product
 

 ;with v  as (select *, row_number() over(partition by guid, product  order by  offDate desc ) rn from #addOffs ) delete from v where rn>1



;
drop table if exists #addOffsGr

select guid, STRING_AGG(AddProductInsuranceOffDesc, ',') within group(order by created desc) AddProductInsuranceOffDesc into #addOffsGr from #addOffs
group by guid
order by 1


--select * from #addOffsGr
 
   update b set b. addProductInsuranceOffDesc = a.addProductInsuranceOffDesc 
 from 
#addOffsGr a join _request b on a.guid=b.guid  



 --  update b set b. addProductInsuranceOffDesc = null 
 --from   _request b  


--select *  from dbo.v_request_add_product_history where ison=0 and ischangestate=1
--and seller<>''

  


 

exec python 'sql2gs( sql ="""


select id,  number, created, status_crm2, origin, call1, abAddProductInsuranceDraft segment 
, addProductInsuranceDraft
, addProductInsuranceCall1
, addProductInsuranceCall2
, addProductInsuranceCall3
, addProductInsuranceFinal
, addProductInsuranceOffDesc


, issued , yandexMetricaLogLink from  request a
where ispts=1
--and created>=''20250101''
and a.abAddProductInsuranceDraft is not null
and a.approved is not null
--and a.number=''24123002919302''
order by a.created

""", gs_id="1ngUdqHJokAAHEqmvfSk4ZwfbbsAE16MSMt8GWi1SfQw", sheet_name="ПТС")' 

 

 
exec python 'sql2gs( sql ="""


select id,  number, created, status_crm2, origin, call1, abAddProductInsuranceDraft segment 
, addProductInsuranceDraft
, addProductInsuranceCall1
, addProductInsuranceCall2
, addProductInsuranceCall3
, addProductInsuranceFinal
, addProductInsuranceOffDesc


, issued , yandexMetricaLogLink from  request a
where ispts=0
  and a.approved >= ''20250501''
 order by a.created

""", gs_id="1ngUdqHJokAAHEqmvfSk4ZwfbbsAE16MSMt8GWi1SfQw", sheet_name="Беззалог")' 
 
 --select * from requestTrigger where id=3610415-- and field='Согласие на подключение доп. продуктов'
 --order by created

 
 --select * from dbo.v_request_add_product_history
 --where number='25011302979388'
 --order by created

  
  
--select b.guid, b.number, a.status, a.product, a.created   from  _request b join
--dbo.v_request_add_product_history a   on a.link=b.link and (  a.status in ('черновик', 'Прикрепление фото паспорта') or a.created < b.call1) and a.isensur=1 and a.ison=1

--where b.guid='F598EBE5-C818-4A02-92B2-5C10CB3119E3'

--select * from dbo.v_request_add_product_history
--where number='25011202975070'
--order by created

;

--select * 
--,row_number() over( partition by guid, product order by (select 1) ) rn  from #addDraft
--order by 3 desc

--select guid, count(distinct product), min(created) created from #addDraft
--group by guid
--order by 2 desc, 3 desc

