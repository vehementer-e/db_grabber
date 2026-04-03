CREATE proc [dbo].[marketing_calc_cost_cpa]
as
return
--/*
begin try
declare @date date =  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           getdate()), 0) as date)
declare @sql    varchar(max) =   '

df = gs2df("1UuELmYFaU_rT7NndHGNfBLmC7xJwBan0eqhCGdLeiA4", range="'+format(@date, 'yyyyMM')+'!A:V")
insert_into_table(df, "marketing_rate_stg", v="1")
'
drop table if exists marketing_rate_stg
exec python @sql , 1
delete a from v_marketing_rate a where cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           datefrom), 0) as date) = @date
 insert into   marketing_rate
 select * from marketing_rate_stg
  

  
set @date   =  cast(DATEADD(MONTH, -1+DATEDIFF(MONTH, 0,           getdate()), 0) as date)
set @sql      =   '

df = gs2df("1UuELmYFaU_rT7NndHGNfBLmC7xJwBan0eqhCGdLeiA4", range="'+format(@date, 'yyyyMM')+'!A:V")
insert_into_table(df, "marketing_rate_stg", v="1")
'
drop table if exists marketing_rate_stg
exec python @sql , 1
delete a from v_marketing_rate a where cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           datefrom), 0) as date) = @date
 insert into   marketing_rate
 select * from marketing_rate_stg
  
 end try
 begin catch
 select 1
 end catch

select * into #t363636 from marketing_rate


drop table if exists #rate

select * from  marketing_rate

;with rate as (




select a.*, nullif(d.value, '') partnerId2 from v_marketing_rate a
outer apply  string_split(partnerid+',', ',')  d


)


select * into #rate from rate

 ;
 
 drop table if exists #request
select a.number, a.created
, a.guid
, a.partnerId
, a.source
, a.ispts
, a.issuedSum
, cast(a.call1   as date)  call1
, cast(a.issued   as date)  issued
  into #request

from _request a with(nolock) 
 
where cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           call1), 0) as date)  >= cast(DATEADD(MONTH, -1+ DATEDIFF(MONTH, 0,     getdate()      ), 0) as date)  

and cast( call1  as date)  < cast( getdate()  as date) 
and isnull(cast( issued  as date), '20010101')  < cast( getdate()  as date) 

--select * from #rate where source like '%' + 'leadssu-inst' + '%'


drop table if exists #request_cost
select a.number, a.created
, a.partnerId
, a.source
, a.guid
, a.ispts
, cast(a.call1   as date)  call1
, cast(a.issued   as date)  issued 
, case 
when a.ispts=1 and  r.partnerLoanPts <1 then  r.partnerLoanPts*a.issuedSum
when a.ispts=1 and  r.partnerLoanPts >=1 then   r.partnerLoanPts
--when a.ispts=1 and  r.partnerRequestPts >=1 then   r.partnerRequestPts
when a.ispts=0 and  r.partnerLoanBezzalog >=1 then   r.partnerLoanBezzalog

when a.ispts=1 and  r.offerLoanPts <1 then  r.offerLoanPts*a.issuedSum
when a.ispts=1 and  r.offerLoanPts >=1 then   r.offerLoanPts
--when a.ispts=1 and  r.offerRequestPts >=1 then   r.offerRequestPts
when a.ispts=0 and  r.offerLoanBezzalog >=1 then   r.offerLoanBezzalog


when a.ispts=1 and  r1.partnerRequestPts >= 1 then  r1.partnerRequestPts
when a.ispts=1 and  r1.offerRequestPts >= 1 then  r1.offerRequestPts 


 end expectedCpaCost
, case 
when a.ispts=1 and  r.partnerLoanPts <1 then  'займ'
when a.ispts=1 and  r.partnerLoanPts >=1 then    'займ'
--when a.ispts=1 and  r.partnerRequestPts >=1 then   r.partnerRequestPts
when a.ispts=0 and  r.partnerLoanBezzalog >=1 then    'займ'

when a.ispts=1 and  r.offerLoanPts <1 then  'займ'
when a.ispts=1 and  r.offerLoanPts >=1 then   'займ'
--when a.ispts=1 and  r.offerRequestPts >=1 then   r.offerRequestPts
when a.ispts=0 and  r.offerLoanBezzalog >=1 then   'займ'


when a.ispts=1 and  r1.partnerRequestPts >= 1 then   'заявку'
when a.ispts=1 and  r1.offerRequestPts >= 1 then    'заявку'


 end expectedCpaCostType
 into #request_cost

from #request a with(nolock) 
outer apply
(select top 1 * from #rate rate_loan where rate_loan.source=a.source and ( isnull(rate_loan.partnerId2, '$$$') =a.partnerId or rate_loan.partnerId2 is null ) and  cast(a.issued   as date) between rate_loan.datefrom and rate_loan.dateTo  order by case when   isnull(rate_loan.partnerId2, '$$$')=a.partnerId then 1 end desc,  rate_loan.datefrom desc ) r
outer apply
(select top 1 * from #rate rate_request where rate_request.source=a.source and ( isnull(rate_request.partnerId2, '$$$') =a.partnerId or rate_request.partnerId2 is null ) and  cast(a.call1   as date) between rate_request.datefrom and rate_request.dateTo   order by case when  isnull(rate_request.partnerId2, '$$$') =a.partnerId then 1 end desc,rate_request.datefrom  desc  ) r1
--where a.source='vbr-crossoffer'
--where a.issued is not null
 --order by 8 desc
 


 --select * from #request_cost
 --where source like '%' + 'leadssu-inst' + '%'
 
 
 update a set a.expectedCpaCost = b.expectedCpaCost, a.expectedCpaCostType = b.expectedCpaCostType from _request a  join #request_cost b on a.guid=b.guid
--alter table _request_log     drop column expectedCpaCost 
--alter table _request     drop column expectedCpaCost              
--alter table _request     add expectedCpaCost numeric(15,2)
--alter table _request_log add expectedCpaCost numeric(15,2)        
--alter table _request     add expectedCpaCostType varchar(20)
--alter table _request_log add expectedCpaCostType varchar(20)

 


 --select * from _request 
 --order by issued desc




 --select distinct decline from v_lead2 where created>=getdate()-3


 drop table if exists #cost_lead
 select a.phone, a.source, a.DECLINE, a.created,   a.id,  a.status , b.offerLeadPts into #cost_lead  from v_lead2 a with(nolock ) 
 
 
 join #rate b on a.created >= b.datefrom AND a.created < DATEADD(DAY, 1, b.dateto)



 and a.source=b.source and  offerLeadPts >= 0
 and decline<>'Дубль'
 and   a.created   < cast( getdate()  as date) 

 ;with v  as (select *, row_number() over(partition by id order by offerLeadPts desc,  (select null)) rn from #cost_lead ) delete from v where rn>1




 drop table if exists #marketing_cost_lead 
  ;
  ;with v  as (select *, row_number() over(partition by phone, cast( created  as date) , source order by  created) rn from #cost_lead )
  
  select *, case when rn=1 then offerLeadPts else 0 end leadCost into #marketing_cost_lead from v
 ;


  --drop table if exists marketing_cost_lead
  --select * into marketing_cost_lead from #marketing_cost_lead
  delete from marketing_cost_lead
  insert into marketing_cost_lead
  select * from #marketing_cost_lead






-- select * from #rate where offerLeadPts
-->0
-- select * from marketing_rate	where [Оффер за лид ПТС]>0 or комментарий is not null
--*/