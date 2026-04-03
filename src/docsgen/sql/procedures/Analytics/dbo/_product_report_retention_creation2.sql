 
CREATE    proc [dbo].[_product_report_retention_creation2]   --[dbo].[_product_report_retention_creation]
as



--sp_create_job 'Analytics._adhoc _product_report_retention_creation2', '_product_report_retention_creation2' , '0'
--EXEC msdb.dbo.sp_start_job @job_name =  'Analytics._adhoc _product_report_retention_creation2'


drop table if exists #closed
select number  , ispts, closed actionCreated, [client_phone], product, client_id, 'closed' action  into #closed 
from mv_loans where closed  >=getdate()-365*6

insert into #closed
select number  , ispts, issued, [client_phone], product, client_id, 'issued' action    from mv_loans 
where issued>='20250101'


--select * from #closed
--order by 3 desc

drop table if exists #request 

select clientId client_id, number, ispts, issued issued, call1 call1 , lower(productType) product_type, case when issued  is not null then 1 else 0 end isLoan,
 cast( call1  as date)  call1Date
, cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,    call1       ), 0) as date) call1month
, loyalty
, returnType
, approved
, declined
  
into #request from _request
where call1 is not null and clientId is not null and isDubl=0 and productType='pts'




create index t on #request (client_id, call1)

--;with v  as (select *, row_number() over(partition by client_id, loyalty, product_Type , call1month order by issued desc  ) rn from #request )
--delete from v where rn>1 and issued is null and client_id is not null

drop table if exists #closed2

select a.* into #closed2 from #closed a 
join request b on a.number=b.loanNumber and b.productType='pts'

 
;

 

 drop table if exists #transitions


 select * into #transitions from (
 
select 'PTS docr' type, 'pts' product_type , 'Докредитование' returnType union all
select 'PTS povt', 'pts' product_type , 'Повторный' returnType  
 ) a  join 
 (
 select 'Заявка' type2, 1 isLoan  union all
 select 'Заявка' type2, 0     union all
select 'Займ' type2 , 1   
) b on 1=1

join (

select 'Повторный' returnType2,  '1.01) 0-1' perName, 0 s, 1 e union all
select 'Повторный' returnType2,  '1.02) 0-5' perName, 0 s, 5 e  union all
select 'Повторный' returnType2,  '1.03) 6-14' perName, 5 s, 14 e  union all
select 'Повторный' returnType2,  '1.04) 15-30' perName, 14 s, 30 e  union all
select 'Повторный' returnType2,  '1.05) 31-90' perName, 30 s, 90 e  union all
select 'Повторный' returnType2,  '1.06) 91-180' perName, 90 s, 180 e  union all
select 'Повторный' returnType2,  '1.07) 181-365' perName, 180 s, 365 e  union all
select 'Повторный' returnType2,  '1.08) 366-2год' perName, 365 s, 365*2 e  union all
select 'Повторный' returnType2,  '1.09) 2год-3год' perName, 365*2 s, 365*3 e  union all


select 'Докредитование' returnType2 ,  '2.01) 0-1' perName, 0 s, 1 e      union all
select 'Докредитование' returnType2 ,  '2.02) 0-5' perName, 0 s, 5 e      union all
select 'Докредитование' returnType2 ,  '2.03) 6-14' perName, 5 s, 14 e    union all
select 'Докредитование' returnType2 ,  '2.04) 15-30' perName, 14 s, 30 e  union all
select 'Докредитование' returnType2 ,  '2.05) 31-60' perName, 30 s, 60 e  union all
select 'Докредитование' returnType2 ,  '2.06) 61-90' perName, 60 s, 90 e  union all
select 'Докредитование' returnType2 ,  '2.07) 91-180' perName, 90 s, 180 e   

 

) per on per.returnType2 =a.returnType --union all


 --into #transitions
 
 drop table if exists #product_report_closed


select a.number
, a.action
, b.type
, b.perName
, b.type2
 

, max(a.product) product
, max(a.actionCreated) closed
, max(a.ispts) ispts
,  count(distinct case when   r.call1 >=  a.actionCreated and r.call1 between  dateadd(day, s,  cast( a.actionCreated  as date )  )  and   dateadd(day, e,  cast( a.actionCreated as date)   )  then r.number end ) request_cnt  --cast( call1  as date)  end)  request_0_d
,  count(distinct case when approved is not null and   r.call1 >=  a.actionCreated and r.call1 between  dateadd(day, s,  cast( a.actionCreated  as date )  )  and   dateadd(day, e,  cast( a.actionCreated as date)   )  then r.number end ) approved_cnt  --cast( call1  as date)  end)  request_0_d
,  count(distinct case when declined is not null and   r.call1 >=  a.actionCreated and r.call1 between  dateadd(day, s,  cast( a.actionCreated  as date )  )  and   dateadd(day, e,  cast( a.actionCreated as date)   )  then r.number end ) declined_cnt  --cast( call1  as date)  end)  request_0_d
,  count(distinct case when issued is not null and   r.call1 >=  a.actionCreated and r.call1 between  dateadd(day, s,  cast( a.actionCreated  as date )  )  and   dateadd(day, e,  cast( a.actionCreated as date)   )  then r.number end )   issued_cnt  --cast( call1  as date)  end)  request_0_d
 
  
into #product_report_closed
from #closed2 a
join #transitions b on 1=1
left join #request r  on r.client_id =a.client_id and b.product_type=r.product_type and r.call1>=a.actionCreated and b.isLoan=r.isLoan and  r.returnType= b.returnType  
group by a.number, b.type , b.type2, a.action
, b.perName


select * from #product_report_closed


drop table if exists #product_report_closed2
select a.*, b.freeTermDays free_term_days, b.returnType [Вид займа любой продукт] , b.closedDpdBeginDay closed_Dpd_Begin_Day , lower(b.productType) product_type, b.loyaltyPts loyalty_pts, b.loyaltyBezzalog loyalty_nopts, b.firstLoanProductType  [Тип первого займа],
case when b.closed is not null then 1 else 0 end isClosed
, case when totalPay is null and scheduleTotalPay>0 then 0 else  cast(b.totalPay/1000.0 as int)*1000 end totalPay
, cast(b.scheduleTotalPay/1000.0 as int)*1000 scheduleTotalPay
, b.channel
, b.source
, isnull(b.firstLoanRbp, b.rbp) firstLoanRbp
into #product_report_closed2 from #product_report_closed a
left join _request b on a.number=b.number

--select * from #product_report_closed2

drop table if exists product_report_retention2
select * into product_report_retention2  from #product_report_closed2




 select action ,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0, closed), 0) as date) month,  type2,    type, perName, request_cnt, approved_cnt, declined_cnt, issued_cnt, case when firstLoanRbp like '%rbp%' then firstLoanRbp else 'non-RBP' end firstLoanRbp  from product_report_retention2



 select * from product_report_retention2
 where closed>='20250701' and action = 'closed' and perName='1.01) 0-1' and request_cnt>0
/*

select case when ( b.channelgroup = 'Банки' or a.source like 'infoseti%' ) and a.producttype <>'AUTOCREDIT' then 1 else 0 end,  (issuedSUm) summ, issuedmonth from request a
left join channel b on a.channel = b.channel 
where year(issued) between 2024 and 2025


select isbank, count(*) cnt from (
select a1.client_Id
, max( case when   ( b.channelgroup = 'Банки' or a.source like 'infoseti%' ) and a.producttype <>'AUTOCREDIT' then 1 else 0 end) isBank


from mv_loans a1
left join request a on a1.number=a.loannumber
left join channel b on a.channel = b.channel 
where a.issued<='20250101'
group by client_Id

) x
group by isbank
 

 select isbank, count(*) cnt from (
select a1.client_Id
, max( case when  ( b.channelgroup = 'Банки' or a.source like 'infoseti%' ) and a.producttype <>'AUTOCREDIT' then 1 else 0 end) isBank


from mv_loans a1
left join request a on a1.number=a.loannumber
left join channel b on a.channel = b.channel 
where a.issued<='20260101'
group by client_Id

) x
group by isbank
 */



