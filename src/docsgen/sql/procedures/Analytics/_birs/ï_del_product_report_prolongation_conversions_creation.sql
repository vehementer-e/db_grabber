
CREATE   proc [_birs].[product_report_prolongation_conversions_creation]
as
begin


drop table if exists #v_prolongation_conversions

select * into #v_prolongation_conversions from v_loan_prolongation

drop table if exists  _birs.product_report_prolongation_conversions

select * 
 into _birs.product_report_prolongation_conversions

from (

select a.week
,a.date
, isnull( x_last_prolo.prolongation_number, 0)+1 prolongation_number
, a.dpd_begin_day  
, a.[Проценты уплачено] 
, a.number 
, a.issued
, a.closed
,  a.[is_dpd_begin_day]
, b.perc [prolongation_percents]
--, b.rn prolongation_number
, a.[Прошло дней с выдачи], max(b.perc) over(partition by a.number ) has_prolo
, b5.date [Дата пятой пролонгации] 
, case when ROW_NUMBER() over(partition by a.number , a.week order by b.date desc ) = 1 and b.date  is not null then 1 end chisl
, case when ROW_NUMBER() over(partition by a.number , a.week order by b.date desc , a.date ) =1 then 1 end znamen
from v_balance a
left join #v_prolongation_conversions b5 on a.number=b5.number and b5.rn=5
left join #v_prolongation_conversions b on a.number=b.number and a.date=b.date 
-- join mv_loans c on a.number=c.number and c.ispdl=1 
 outer apply (select max(last_prolo.rn) prolongation_number  from #v_prolongation_conversions  last_prolo where a.number=last_prolo.number and last_prolo.date<a.date ) x_last_prolo
where
a.ispdl=1 and 

(  b.number is not null or ( a.[Прошло дней с выдачи]>=7  and  ( a.date<= b5.date or b5.date is null) ) )
 
 ) x where chisl>0 or znamen>0



 end