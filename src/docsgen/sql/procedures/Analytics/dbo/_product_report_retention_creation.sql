 
CREATE    proc [dbo].[_product_report_retention_creation]   --[dbo].[_product_report_retention_creation]
as


drop table if exists #closed
select number  , ispts, closed actionCreated, [client_phone], product, client_id, 'closed' action  into #closed 
from mv_loans where closed is not null

insert into #closed
select number  , ispts, issued, [client_phone], product, client_id, 'issued' action    from mv_loans -- where closed is not null


--select * from #closed
--order by 3 desc

drop table if exists #request 

select clientId client_id, number, ispts, issued issued, call1 call1 , lower(productType) product_type, case when issued  is not null then 1 else 0 end isLoan,
 cast( call1  as date)  call1Date
, cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,    call1       ), 0) as date) call1month
, loyalty
, returnType
  
into #request from _request
where call1 is not null and clientId is not null and isDubl=0


--;with v  as (select *, row_number() over(partition by client_id, loyalty, product_Type , call1month order by issued desc  ) rn from #request )
--delete from v where rn>1 and issued is null and client_id is not null




;

 

 drop table if exists #transitions


 select * into #transitions from (
select 'Any' type, 'pts' product_type  , cast( null as varchar(20)) returnType union all
select 'Any' type, 'inst' product_type , null returnType union all
select 'Any' type, 'pdl' product_type , null returnType union all
select 'Any' type, 'BIG INST' product_type , null returnType union all
select 'Any' type, 'AUTOCREDIT' product_type , null returnType union all
select 'PDl' type, 'pdl' product_type , null returnType union all
select 'INST' type, 'inst' product_type , null returnType union all
select 'PTS', 'pts' product_type , null returnType union all
select 'PTS docr', 'pts' product_type , 'Докредитование' returnType union all
select 'PTS povt', 'pts' product_type , 'Повторный' returnType union all
select 'AUTOCREDIT', 'AUTOCREDIT' product_type , null returnType union all
select 'BIG INST', 'BIG INST' product_type , null returnType union all
select  'noPTS' type, 'pdl' product_type , null returnType union all
select 'noPTS' type, 'inst' product_type , null returnType --union all
 ) a  join 
 (
 select 'Заявка' type2, 1 isLoan  union all
 select 'Заявка' type2, 0     union all
select 'Займ' type2 , 1   
) b on 1=1


 --into #transitions
 
 drop table if exists #product_report_closed


select a.number
, a.action
, b.type
, b.type2

, max(a.product) product
, max(a.actionCreated) closed
, max(a.ispts) ispts
,  count(distinct case when r.call1 <= dateadd(day, 1,  cast(a.actionCreated  as date) )  then r.number end ) request_0_d  --cast( call1  as date)  end)  request_0_d
,  count(distinct case when r.call1 <= dateadd(day, 5,  cast(a.actionCreated  as date))   then r.number end )  request_5_d -- cast( call1  as date)  end)   request_5_d
,  count(distinct case when r.call1 <= dateadd(day, 14, cast(a.actionCreated  as date) )  then r.number end ) request_14_d -- cast( call1  as date)  end)  request_14_d
,  count(distinct case when r.call1 <= dateadd(day, 30, cast(a.actionCreated  as date) )  then r.number end ) request_30_d -- cast( call1  as date)  end)  request_30_d
,  count(distinct case when r.call1 <= dateadd(day, 60, cast(a.actionCreated  as date) )  then r.number end ) request_60_d -- cast( call1  as date)  end)  request_30_d

,  count(distinct case when r.call1 <= dateadd(day, 90, cast(a.actionCreated  as date) )  then r.number end ) request_90_d -- cast( call1  as date)  end)  request_90_d
,  count(distinct case when r.call1 <= dateadd(day, 180, cast(a.actionCreated  as date) ) then r.number end ) request_180_d--  cast( call1  as date)  end)  request_180_d
,  count(distinct case when r.call1 <= dateadd(day, 365, cast(a.actionCreated  as date) ) then r.number end ) request_12_m--  cast( call1  as date)  end)  request_180_d
,  count(distinct case when r.call1 <= dateadd(day, cast(365*1.5 as int), cast(a.actionCreated  as date) ) then r.number end ) request_18_m--  cast( call1  as date)  end)  request_180_d
,  count(distinct case when r.call1 <= dateadd(day, cast(365*2 as int), cast(a.actionCreated  as date) ) then r.number end ) request_24_m--  cast( call1  as date)  end)  request_180_d

 
--,  count(distinct case when r.call1 <= dateadd(day, 1, cast(a.closed  as date) )  and  r.issued  is not null then  cast( call1  as date)  end)  loan_0_d
--,  count(distinct case when r.call1 <= dateadd(day, 30, a.closed ) and  r.issued  is not null then  cast( r.issued  as date)  end)  loan_30_d

into #product_report_closed
from #closed a
join #transitions b on 1=1
left join #request r  on r.client_id =a.client_id and b.product_type=r.product_type and r.call1>=a.actionCreated and b.isLoan=r.isLoan and (r.returnType= b.returnType or b.returnType is null)
group by a.number, b.type , b.type2, a.action


drop table if exists #product_report_closed2
select a.*, b.freeTermDays free_term_days, b.returnType [Вид займа любой продукт] , b.closedDpdBeginDay closed_Dpd_Begin_Day , lower(b.productType) product_type, b.loyaltyPts loyalty_pts, b.loyaltyBezzalog loyalty_nopts, b.firstLoanProductType  [Тип первого займа],
case when b.closed is not null then 1 else 0 end isClosed
, case when totalPay is null and scheduleTotalPay>0 then 0 else  cast(b.totalPay/1000.0 as int)*1000 end totalPay
, cast(b.scheduleTotalPay/1000.0 as int)*1000 scheduleTotalPay
, b.channel
, b.source
into #product_report_closed2 from #product_report_closed a
left join _request b on a.number=b.number

--select * from #product_report_closed2

drop table if exists product_report_retention
select * into product_report_retention  from --#product_report_closed2
--select * from #product_report_closed2
(
--SELECT 
--  a.[number] 
--  , a.action
--,   a.[type] 
--,   a.[type2] 
--,   'week' date_type 
--,   a.[product] 
--, cast(DATEADD(DD, 1 - DATEPART(DW, a.[closed]  ), a.[closed]  ) as date) as [closed]   
--,   a.[ispts] 
--,   a.[request_0_d] 
--,   a.[request_5_d] 
--,   a.[request_14_d] 
--,   a.[request_30_d] 
--,   a.[request_90_d] 
--,   a.[request_180_d]  
--,   a.request_12_m  
--,   a.request_18_m  
--,   a.request_24_m  


--,   a.[free_term_days] 
--,   a.[Вид займа любой продукт] 
--,   a.[closed_dpd_begin_day] 
--,   a.[product_type] 
--,   a.[loyalty_pts] 
--,   a.[loyalty_nopts] 
--,   a.[Тип первого займа] 
--, a.isClosed
--, a.totalPay
--, a.scheduleTotalPay
--,a.channel
--,a.source

--        FROM 

--        #product_report_closed2 a union all
		SELECT 
  a.[number] 
  , a.action

,   a.[type] 
,   a.[type2] 
,   'month' date_type

,   a.[product] 
,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,  a.[closed] 
         ), 0) as date) [closed]
,   a.[ispts] 
,   a.[request_0_d] 
,   a.[request_5_d] 
,   a.[request_14_d] 
,   a.[request_30_d] 
,   a.[request_90_d] 
,   a.[request_180_d]  
,   a.request_12_m  
,   a.request_18_m  
,   a.request_24_m  

,   a.[free_term_days] 
,   a.[Вид займа любой продукт] 
,   a.[closed_dpd_begin_day] 
,   a.[product_type] 
,   a.[loyalty_pts] 
,   a.[loyalty_nopts] 
,   a.[Тип первого займа] 
, a.isClosed
, a.totalPay
, a.scheduleTotalPay
,a.channel
,a.source
        FROM 

        #product_report_closed2 a
		) x


 --sp_table_granularity 'product_report_retention'