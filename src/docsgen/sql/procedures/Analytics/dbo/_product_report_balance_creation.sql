

CREATE     proc [dbo].[_product_report_balance_creation]
as 

drop table if exists #sp

select  a.number number, min(a.[Дата отправки иска в суд]) legal
into #sp
from _collection.deals a
group by a.number

--group by a.number

drop table if exists #fond_rate

select month, rate into #fond_rate from (
select cast( '2022.01.01' as date) month, 0.15713410924 rate union all
select '2022.02.01', 0.15700337338 union all
select '2022.03.01', 0.17950441211 union all
select '2022.04.01', 0.18457403126 union all
select '2022.05.01', 0.18905659851 union all
select '2022.06.01', 0.18394078890 union all
select '2022.07.01', 0.18263419222 union all
select '2022.08.01', 0.18277621270 union all
select '2022.09.01', 0.18415106507 union all
select '2022.10.01', 0.18888224251 union all
select '2022.11.01', 0.18166039723 union all
select '2022.12.01', 0.18125063631 union all
select '2023.01.01', 0.17977462928 union all
select '2023.02.01', 0.17734490780 union all
select '2023.03.01', 0.17512883686 union all
select '2023.04.01', 0.17222895924 union all
select '2023.05.01', 0.16957429875 union all
select '2023.06.01', 0.16824237901 union all
select '2023.07.01', 0.17004153340 union all
select '2023.08.01', 0.16831907196 union all
select '2023.09.01', 0.16967667551 union all
select '2023.10.01', 0.17240978894 union all
select '2023.11.01', 0.17636461448 union all
select '2023.12.01', 0.18044552228 union all
select '2024.01.01', 0.18097777349 union all
select '2024.02.01', 0.18237112789 union all
select '2024.03.01', 0.18537167959 union all
select '2024.04.01', 0.18748457295 union all
select '2024.05.01', 0.18856911000 union all
select '2024.06.01', 0.19019297530 union all
select '2024.07.01', 0.19221208722 union all
select '2024.08.01', 0.19934112026 union all
select '2024.09.01', 0.21132483412 union all
select '2024.10.01', 0.22500517816 union all
select '2024.11.01', 0.23500068021 union all
select '2024.12.01', 0.23787548372 union all
select '2025.01.01', 0.24177167909 union all
select '2025.02.01', 0.24238543762 union all
select '2025.03.01', 0.24460956134 union all
select '2025.04.01', 0.24211968107 union all
select '2025.05.01', 0.24233957710 union all
select '2025.06.01', 0.23384963359 union all
select '2025.07.01', 0.21951957821 union all
select '2025.08.01', 0.21000000000 union all
select '2025.09.01', 0.20500000000 union all
select '2025.10.01', 0.20000000000 union all
select '2025.11.01', 0.20000000000 union all
select '2025.12.01', 0.20000000000 union all
select '2026.01.01', 0.19000000000 union all
select '2026.02.01', 0.19000000000 union all
select '2026.03.01', 0.19000000000 union all
select '2026.04.01', 0.19000000000 union all
select '2026.05.01', 0.19000000000 union all
select '2026.06.01', 0.19000000000 union all
select '2026.07.01', 0.17000000000 union all
select '2026.08.01', 0.17000000000 union all
select '2026.09.01', 0.17000000000 union all
select '2026.10.01', 0.15000000000 union all
select '2026.11.01', 0.15000000000 union all
select '2026.12.01', 0.15000000000 union all
select '2027.01.01', 0.15000000000 union all
select '2027.02.01', 0.15000000000 union all
select '2027.03.01', 0.15000000000 union all
select '2027.04.01', 0.15000000000 union all
select '2027.05.01', 0.15000000000 union all
select '2027.06.01', 0.15000000000 union all
select '2027.07.01', 0.15000000000 union all
select '2027.08.01', 0.15000000000 union all
select '2027.09.01', 0.15000000000 union all
select '2027.10.01', 0.15000000000 union all
select '2027.11.01', 0.15000000000 union all
select '2027.12.01', 0.15000000000 union all
select '2028.01.01', 0.13000000000 union all
select '2028.02.01', 0.13000000000 union all
select '2028.03.01', 0.13000000000 union all
select '2028.04.01', 0.13000000000 union all
select '2028.05.01', 0.13000000000 union all
select '2028.06.01', 0.13000000000 union all
select '2028.07.01', 0.13000000000 union all
select '2028.08.01', 0.13000000000 union all
select '2028.09.01', 0.13000000000 union all
select '2028.10.01', 0.13000000000 union all
select '2028.11.01', 0.13000000000 union all
select '2028.12.01', 0.13000000000 union all
select '2029.01.01', 0.13000000000 union all
select '2029.02.01', 0.13000000000 union all
select '2029.03.01', 0.13000000000 union all
select '2029.04.01', 0.13000000000 union all
select '2029.05.01', 0.13000000000 union all
select '2029.06.01', 0.13000000000 union all
select '2029.07.01', 0.13000000000 union all
select '2029.08.01', 0.13000000000 union all
select '2029.09.01', 0.13000000000 union all
select '2029.10.01', 0.13000000000 union all
select '2029.11.01', 0.13000000000 union all
select '2029.12.01', 0.13000000000 union all
select '2030.01.01', 0.13000000000 union all
select '2030.02.01', 0.13000000000 union all
select '2030.03.01', 0.13000000000 union all
select '2030.04.01', 0.13000000000 union all
select '2030.05.01', 0.13000000000 union all
select '2030.06.01', 0.13000000000 union all
select '2030.07.01', 0.13000000000 union all
select '2030.08.01', 0.13000000000 union all
select '2030.09.01', 0.13000000000 union all
select '2030.10.01', 0.13000000000 union all
select '2030.11.01', 0.13000000000 union all
select '2030.12.01', 0.13000000000 --union all
)
x

insert into #fond_rate
select distinct month, 0.15713410924  from calendar_view where year< '20220101'
 

 drop table if exists #request
 select   number
 , loanNumber
 , firstLoanProductType
 , firstLoanIssued
 , issued
 , returnType
 , loyaltyPts
 , loyaltyBezzalog
 , loyalty
 , productType
 , firstLoanRbp
 , rbp
 , fpd0
 , source
 , channel
 , issuedSum
 , isPts
 , issuedMonth
 , isPdl
 , cession
 , cessionSum
 , created3
 , created3Month
 , addproductsumnet
 , case when call1 is not null then 1 else 0 end hasCall1
 into #request from request 
 

drop table if exists #dpd_start_day

 select number, min(date) dpdStartDay into #dpd_start_day from v_balance where dpdbeginday>=30
 group by number

drop table if exists #t237842309402389
 
 CREATE TABLE [dbo].[#t237842309402389]
(
      [date] [DATE]
    , [ispts] [INT]
    , [issuedMonth] [DATE]
    , [firstIssuedMonth] [DATE]
    , [returnType] [NVARCHAR](20)
    , [loyaltyPts] [INT]
    , [loyaltyBezzalog] [INT]
    , [loyalty] [INT]
    , [firstLoanProductType] [VARCHAR](4)
    , [ispdl] [INT]
    , [dpdBeginDay0_1_45] [INT]
    , [isLegal] [INT]
    , [productType] [VARCHAR](10)
    , [paid] int
    , [percentsPaid] int
    , row_type [VARCHAR](20)
    , mob [INT]
    , clientMOB [INT]
    , firstLoanRbp  [VARCHAR](50)
    , rbp  [VARCHAR](50)
	, issuedSum [MONEY]
	, fpd0 int
	, issuedCnt int 
    , [principalPaid] int
	, source varchar(255)
	, channel varchar(255)
	 ,  issuedSumBucket10000 int

);

insert into #t237842309402389

select a.month date
,  a.ispts ispts
,   a.issuedMonth issuedMonth
,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull(  b.firstLoanIssued, b.issued) ), 0) as date) firstIssuedMonth

,  b.returnType
,  b.loyaltyPts
,  b.loyaltyBezzalog
,  b.loyalty
,  b.firstLoanProductType firstLoanProductType
,  a.ispdl ispdl
,  case when a.dpdBeginDay>=45 then 45 when a.dpdBeginDay >=1 then 1 else 0 end dpdBeginDay0_1_45
 
,  CASE WHEN a.date >= legal THEN 1 END  isLegal
,  b.productType productType
,  sum(a.paid) paid 
,  sum(percentsPaid) percentsPaid
, 'Кэш' row_type
, a.mob 
, datediff(month, isnull( b.firstLoanIssued, b.issued) , d ) clientMOB
, b.firstLoanRbp
, b.rbp
, null
, b.fpd0
, null
, sum(a.[principalPaid])
, b.source
, b.channel
, ceiling(b.issuedSum/10000.0)*10000 issuedSumBucket10000
--select top 100 *
from v_balance a
join #request b on a.number=b.loanNumber and b.issued is not null
left join #sp sp on sp.number=b.number
group by  a.month  
,  a.ispts  
,  a.issuedMonth 
 , cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull(  b.firstLoanIssued, b.issued) ), 0) as date)
,  b.returnType
,  b.loyaltyPts
,  b.loyaltyBezzalog
,  b.loyalty
,  b.firstLoanProductType  
,  a.ispdl  
,  case when a.dpdBeginDay>=45 then 45 when a.dpdBeginDay >=1 then 1 else 0 end  
,  CASE WHEN a.date >= legal THEN 1 END   
,  b.productType  
, a.mob 
, datediff(month, isnull( b.firstLoanIssued, b.issued) , d )
, b.firstLoanRbp
, b.rbp
, b.fpd0
, b.source
, b.channel
, ceiling(b.issuedSum/10000.0)*10000  

having isnull( sum(a.paid) , 0)  <> 0  or 
  isnull(sum(percentsPaid)  , 0) <> 0   



insert into #t237842309402389




select month, ispts, issuedMonth, firstIssuedMonth , returnType

,  loyaltyPts
,  loyaltyBezzalog
,  loyalty
,  firstLoanProductType  
,  ispdl  
, dpdBeginDay0_1_45
, isLegal
, productType
, sum(paid) paid
, sum(percentsPaid) percentsPaid
, row_type
, mob
, clientMOB
, firstLoanRbp
, rbp
, issuedSum
, fpd0
, issuedCnt   
, [principalPaid]  
, source  
, channel  
,  issuedSumBucket10000  


from (  
select a.date date
,  a.ispts ispts
,   a.issuedMonth issuedMonth
,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull(  b.firstLoanIssued, b.issued) ), 0) as date) firstIssuedMonth

,  b.returnType
,  b.loyaltyPts
,  b.loyaltyBezzalog
,  b.loyalty
,  b.firstLoanProductType firstLoanProductType
,  a.ispdl ispdl
,  case when a.dpdBeginDay>=45 then 45 when a.dpdBeginDay >=1 then 1 else 0 end dpdBeginDay0_1_45
 
,  CASE WHEN a.date >= legal THEN 1 END  isLegal
,  b.productType productType
, - sum(a.principalRest * isnull(fr.rate , 0) /365.0)  paid 
,  cast(null as int) percentsPaid
, '(Фондирование)' row_type
, a.mob 
, datediff(month, isnull( b.firstLoanIssued, b.issued) , d ) clientMOB
, b.firstLoanRbp
, b.rbp
, null   issuedSum
, b.fpd0
, null   issuedCnt
, cast(null as int) [principalPaid]
, b.source
, b.channel
, ceiling(b.issuedSum/10000.0)*10000 issuedSumBucket10000
, a.month
--select top 100 *
from v_balance a
join #request b on a.number=b.loanNumber and b.issued is not null
left join #sp sp on sp.number=b.number
left join #fond_rate fr on fr.month = a.month
group by  a.date  
,  a.ispts  
,  a.issuedMonth 
 , cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull(  b.firstLoanIssued, b.issued) ), 0) as date)
,  b.returnType
,  b.loyaltyPts
,  b.loyaltyBezzalog
,  b.loyalty
,  b.firstLoanProductType  
,  a.ispdl  
,  case when a.dpdBeginDay>=45 then 45 when a.dpdBeginDay >=1 then 1 else 0 end  
,  CASE WHEN a.date >= legal THEN 1 END   
,  b.productType  
, a.mob 
, datediff(month, isnull( b.firstLoanIssued, b.issued) , d )
, b.firstLoanRbp
, b.rbp
, b.fpd0
, b.source
, b.channel
, ceiling(b.issuedSum/10000.0)*10000  
, a.month

having  isnull( sum(a.principalRest * isnull(fr.rate , 0) /365.0 ) , 0) <> 0
) x

group by month, ispts, issuedMonth, firstIssuedMonth , returnType

,  loyaltyPts
,  loyaltyBezzalog
,  loyalty
,  firstLoanProductType  
,  ispdl  
, dpdBeginDay0_1_45
, isLegal
, productType 
, row_type
, mob
, clientMOB
, firstLoanRbp
, rbp
, issuedSum
, fpd0
, issuedCnt   
, [principalPaid]  
, source  
, channel  
,  issuedSumBucket10000  




  
insert into #t237842309402389

select   a.МесяцПлатежа date
,  b.ispts ispts
,   b.issuedMonth issuedMonth
,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull(  b.firstLoanIssued, b.issued) ), 0) as date) firstIssuedMonth

,  b.returnType
,  b.loyaltyPts
,  b.loyaltyBezzalog
,  b.loyalty
,  b.firstLoanProductType firstLoanProductType
,  b.ispdl ispdl
, null dpdBeginDay0_1_45
 
,  null  isLegal
,  b.productType productType
,   sum(isnull(case when [ПлатежнаяСистема]= 'ECommPay' then [Прибыль расчетная екомм без НДС] else [ПрибыльБезНДС] end, 0))	 paid 
, null percentsPaid
, 'Комиссия платеж' row_type
,datediff(month, b.issued, a.[ДеньПлатежа] ) mob 
, datediff(month, isnull( b.firstLoanIssued, b.issued) , a.[ДеньПлатежа] ) clientMOB
, b.firstLoanRbp
, b.rbp
, null
, b.fpd0
, null
, null
, b.source
, b.channel
, ceiling(b.issuedSum/10000.0)*10000 issuedSumBucket10000


from mv_repayments a
join #request b on a.number=b.loanNumber --and b.issued is not null
group by     a.МесяцПлатежа
,   b.ispts  
,  b.issuedMonth 
 , cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull(  b.firstLoanIssued, b.issued) ), 0) as date)
,  b.returnType
,  b.loyaltyPts
,  b.loyaltyBezzalog
,  b.loyalty
,  b.firstLoanProductType  
,  b.ispdl  
 ,  b.productType  
, datediff(month, b.issued, a.[ДеньПлатежа] ) 
,  datediff(month, isnull( b.firstLoanIssued, b.issued) , a.[ДеньПлатежа] )
, b.firstLoanRbp
, b.rbp
, b.fpd0
, b.source
, b.channel
, ceiling(b.issuedSum/10000.0)*10000  

having   sum(isnull(case when [ПлатежнаяСистема]= 'ECommPay' then [Прибыль расчетная екомм без НДС] else [ПрибыльБезНДС] end, 0))  <> 0   
 

  



  insert into #t237842309402389
   
   
select cast(DATEADD(MONTH, DATEDIFF(MONTH, 0, cession), 0) as date)    date
,  a.ispts ispts
,  a.issuedMonth issuedMonth
,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull( a.firstLoanIssued, a.issued) ), 0) as date) firstIssuedMonth
 
,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType firstLoanProductType
,  a.ispdl ispdl
, null dpdBeginDay0_1_45
 
, null  isLegal
,  a.productType productType
, cessionSum paid
,  null percentsPaid 
, 'Цессия' row_type
, datediff(month, a.issued,   a.cession ) as mob
, datediff(month, isnull( a.firstLoanIssued, a.issued) , a.cession  ) clientMOB
, a.firstLoanRbp
, a.rbp
, null
, a.fpd0
, null
, null
, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000 issuedSumBucket10000

from #request a  
where issuedSum>0 and issued is not null and  a.cession is not null and  a.cessionSum> 0
 
 group by 
 cast(DATEADD(MONTH, DATEDIFF(MONTH, 0, cession), 0) as date)
,  a.ispts  
,  a.issuedMonth
,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull( a.firstLoanIssued, a.issued) ), 0) as date) 
,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType  
,  a.ispdl   
,  a.productType 
, datediff(month, a.issued,  a.cession  ) 
, datediff(month, isnull( a.firstLoanIssued, a.issued) , a.cession  )
, a.firstLoanRbp
, a.rbp
, a.cessionSum
, a.fpd0

, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000  

having  isnull( cessionSum , 0) <>0


--select * from request where cessionSum is not null




--delete from #t237842309402389 where percentsPaid is null
--delete from #t237842309402389 where row_type <>'Кэш'

--select * from #t237842309402389

insert into #t237842309402389


select a.issuedMonth date
,  a.ispts ispts
,  a.issuedMonth issuedMonth
,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull( a.firstLoanIssued, a.issued) ), 0) as date) firstIssuedMonth
 
,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType firstLoanProductType
,  a.ispdl ispdl
, null dpdBeginDay0_1_45
 
, null  isLegal
,  a.productType productType
,  -sum( b.[Сумма] ) paid
,  null percentsPaid 
, '(Выдано)' row_type
, 0 as mob
, datediff(month, isnull( a.firstLoanIssued, a.issued) ,a.issued ) clientMOB
, a.firstLoanRbp
, a.rbp
, sum(b.[Сумма])
, a.fpd0
, count(b.[Сумма])
, null

, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000   issuedSumBucket10000


from #request a  
join mv_loans b on a.loanNumber=b.number and a.issued is not null
group by 
 a.issuedMonth 
,  a.ispts  
,  a.issuedMonth
,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull( a.firstLoanIssued, a.issued) ), 0) as date) 
,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType  
,  a.ispdl   
,  a.productType 
, datediff(month, isnull( a.firstLoanIssued, a.issued) , a.issued )
, a.firstLoanRbp
, a.rbp
, a.fpd0

, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000 
having  isnull( -sum( isnull (b.[Сумма клиенту на руки], b.[Сумма] ) ) , 0) <>0



insert into #t237842309402389


select a.issuedMonth date
,  a.ispts ispts
,  a.issuedMonth issuedMonth
,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull( a.firstLoanIssued, a.issued) ), 0) as date) firstIssuedMonth
 
,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType firstLoanProductType
,  a.ispdl ispdl
, null dpdBeginDay0_1_45
 
, null  isLegal
,  a.productType productType
,  sum(  a.addproductsumnet ) paid
,  null percentsPaid 
, 'КП' row_type
, 0 as mob
, datediff(month, isnull( a.firstLoanIssued, a.issued) ,a.issued ) clientMOB
, a.firstLoanRbp
, a.rbp
, null
, a.fpd0
, null
, null

, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000   issuedSumBucket10000


from #request a  
join mv_loans b on a.loanNumber=b.number and a.issued is not null
group by 
 a.issuedMonth 
,  a.ispts  
,  a.issuedMonth
,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull( a.firstLoanIssued, a.issued) ), 0) as date) 
,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType  
,  a.ispdl   
,  a.productType 
, datediff(month, isnull( a.firstLoanIssued, a.issued) , a.issued )
, a.firstLoanRbp
, a.rbp
, a.fpd0

, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000 
having  isnull(   sum(  a.addproductsumnet ) , 0) <>0



insert into #t237842309402389


select a.issuedMonth date
,  a.ispts ispts
,  a.issuedMonth issuedMonth
,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull( a.firstLoanIssued, a.issued) ), 0) as date) firstIssuedMonth
 
,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType firstLoanProductType
,  a.ispdl ispdl
, null dpdBeginDay0_1_45
 
, null  isLegal
,  a.productType productType
,  sum( case when a.ispts=0 and a.issuedMonth <='20250401' then 0.03* b.Сумма else a.addproductsumnet end ) paid
,  null percentsPaid 
, 'КП (для ретро = 3%)' row_type
, 0 as mob
, datediff(month, isnull( a.firstLoanIssued, a.issued) ,a.issued ) clientMOB
, a.firstLoanRbp
, a.rbp
, null
, a.fpd0
, null
, null

, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000   issuedSumBucket10000


from #request a  
join mv_loans b on a.loanNumber=b.number and a.issued is not null
group by 
 a.issuedMonth
,  a.ispts  
,  a.issuedMonth
,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull( a.firstLoanIssued, a.issued) ), 0) as date) 
,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType  
,  a.ispdl   
,  a.productType 
, datediff(month, isnull( a.firstLoanIssued, a.issued) , a.issued )
, a.firstLoanRbp
, a.rbp
, a.fpd0

, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000 
having  isnull(  sum( case when a.ispts=0 and a.issuedMonth <='20250401' then 0.03* b.Сумма else a.addproductsumnet end ) , 0) <>0










--select distinct ceiling(issuedSum/10000.0)*10000 issuedSumBucket10000  from request where issuedSum is not null


--insert into #t237842309402389


--select a.issued date
--,  a.ispts ispts
--,  a.issuedMonth issuedMonth
--,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull( a.firstLoanIssued, a.issued) ), 0) as date) firstIssuedMonth
 
--,  a.returnType
--, a.loyaltyPts
--, a.loyaltyBezzalog
--, a.loyalty
--,  a.firstLoanProductType firstLoanProductType
--,  a.ispdl ispdl
--, null dpdBeginDay0_1_45
 
--, null  isLegal
--,  a.productType productType
--,  -sum( isnull (b.[Сумма клиенту на руки], b.[Сумма] ) )* case when a.ispts=0 then  0.97 else 1 end paid
--,  null percentsPaid 
--, '(Выдано3%)' row_type
--, 0 as mob
--, datediff(month, isnull( a.firstLoanIssued, a.issued) ,a.issued ) clientMOB
--, a.firstLoanRbp
--, a.rbp
--, sum(b.[Сумма])
--, a.fpd0
--, count(b.[Сумма])
--, null

--, a.source
--, a.channel
--, ceiling(a.issuedSum/10000.0)*10000   issuedSumBucket10000

--from #request a  
--join mv_loans b on a.number=b.number and a.issued is not null --and a.ispts=0
--group by 
-- a.issued  
--,  a.ispts  
--,  a.issuedMonth
--,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,           isnull( a.firstLoanIssued, a.issued) ), 0) as date) 
--,  a.returnType
--, a.loyaltyPts
--, a.loyaltyBezzalog
--, a.loyalty
--,  a.firstLoanProductType  
--,  a.ispdl   
--,  a.productType 
--, datediff(month, isnull( a.firstLoanIssued, a.issued) , a.issued )
--, a.firstLoanRbp
--, a.rbp
--, a.fpd0

--, a.source
--, a.channel
--, ceiling(a.issuedSum/10000.0)*10000    

--having  isnull( -sum( isnull (b.[Сумма клиенту на руки], b.[Сумма] ) ) , 0) <>0









insert into #t237842309402389

--select top 100 * from #t237842309402389

select  a.created3Month date
,  a.ispts ispts
, a.created3Month   issuedMonth
, cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,    isnull( a.firstLoanIssued, a.created3Month)        ), 0) as date) firstIssuedMonth

,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType firstLoanProductType
,  a.ispdl ispdl
, null dpdBeginDay0_1_45
 
, null  isLegal
,  a.productType productType
,  -sum(b.MarketingCost) paid
,  null percentsPaid 
, '(Маркетинг)' row_type
, 0 as mob
, datediff(month, isnull( a.firstLoanIssued, a.created3Month) ,  a.created3Month ) clientMOB
, a.firstLoanRbp
, a.rbp
, null
, a.fpd0
, null
, null

, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000   issuedSumBucket10000

from #request a  join v_request_cost b on a.number=b.number
group by 
 a.created3Month  
,  a.ispts  
, a.created3Month 
, cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,    isnull( a.firstLoanIssued, a.created3Month)        ), 0) as date)  

,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType  
,  a.ispdl   
,  a.productType  
, datediff(month, isnull( a.firstLoanIssued, a.created3Month) ,  a.created3Month )
, a.firstLoanRbp
, a.rbp
, a.fpd0

, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000    

having  isnull(sum(b.MarketingCost)  , 0) <>0





insert into #t237842309402389
 

select  a.created3Month date
,  a.ispts ispts
, a.created3Month   issuedMonth
, cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,    isnull( a.firstLoanIssued, a.created3Month)        ), 0) as date) firstIssuedMonth

,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType firstLoanProductType
,  a.ispdl ispdl
, null dpdBeginDay0_1_45
 
, null  isLegal
,  a.productType productType
,  -sum(33.0) paid
,  null percentsPaid 
, '(Скоринг)' row_type
, 0 as mob
, datediff(month, isnull( a.firstLoanIssued, a.created3Month) ,  a.created3Month ) clientMOB
, a.firstLoanRbp
, a.rbp
, null
, a.fpd0
, null
, null

, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000   issuedSumBucket10000

from #request a 
where a.producttype in ('inst', 'pdl') and a.hasCall1 =1
group by 
 a.created3Month  
,  a.ispts  
, a.created3Month 
, cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,    isnull( a.firstLoanIssued, a.created3Month)        ), 0) as date)  

,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType  
,  a.ispdl   
,  a.productType  
, datediff(month, isnull( a.firstLoanIssued, a.created3Month) ,  a.created3Month )
, a.firstLoanRbp
, a.rbp
, a.fpd0

, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000   



insert into #t237842309402389
 

select  b.dpdStartDay date
,  a.ispts ispts
, a.created3Month   issuedMonth
, cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,    isnull( a.firstLoanIssued, a.created3Month)        ), 0) as date) firstIssuedMonth

,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType firstLoanProductType
,  a.ispdl ispdl
, null dpdBeginDay0_1_45
 
, null  isLegal
,  a.productType productType
,  -sum(200.0) paid
,  null percentsPaid 
, '(Collection 30+)' row_type
, 0 as mob
, datediff(month, isnull( a.firstLoanIssued, a.created3Month) ,  a.created3Month ) clientMOB
, a.firstLoanRbp
, a.rbp
, null
, a.fpd0
, null
, null

, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000   issuedSumBucket10000

from #request a 
join #dpd_start_day b on a.number=b.number 
where a.producttype in ('inst', 'pdl')  
group by 
b.dpdStartDay 
,  a.ispts  
, a.created3Month 
, cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,    isnull( a.firstLoanIssued, a.created3Month)        ), 0) as date)  

,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType  
,  a.ispdl   
,  a.productType  
, datediff(month, isnull( a.firstLoanIssued, a.created3Month) ,  a.created3Month )
, a.firstLoanRbp
, a.rbp
, a.fpd0

, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000  



--having  isnull(sum(b.MarketingCost)  , 0) <>0


----------------------------------
----------------------------------
----------------------------------
----------------------------------

insert into #t237842309402389


select   a.created3Month  date
,  a.ispts ispts
,  a.created3Month  issuedMonth
, cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,    isnull( a.firstLoanIssued,  a.created3Month)        ), 0) as date) firstIssuedMonth

,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType firstLoanProductType
,  a.ispdl ispdl
, null dpdBeginDay0_1_45
 
, null  isLegal
,  a.productType productType
,  sum(b.sellTrafficIncomeNet) paid
,  null percentsPaid 
, 'Продажа трафика' row_type
, 0 as mob
, datediff(month, isnull( a.firstLoanIssued, a.issued) ,  a.issued ) clientMOB
, a.firstLoanRbp
, a.rbp
, null
, a.fpd0
, null
, null

, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000   issuedSumBucket10000

from #request a  join v_request_cost b on a.number=b.number
group by 
  a.created3Month
,  a.ispts  
, a.created3Month 
,  cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,    isnull( a.firstLoanIssued,  a.created3Month)        ), 0) as date)
,  a.returnType
, a.loyaltyPts
, a.loyaltyBezzalog
, a.loyalty
,  a.firstLoanProductType  
,  a.ispdl   
,  a.productType  
, datediff(month, isnull( a.firstLoanIssued, a.issued) ,  a.issued )
, a.firstLoanRbp
, a.rbp
, a.fpd0

, a.source
, a.channel
, ceiling(a.issuedSum/10000.0)*10000    

 having  isnull(  sum(b.sellTrafficIncomeNet) , 0) <>0

 
drop table if exists [product_report_balance] 



SELECT 
           a.[date] 
,   a.[ispts] 
,   a.[issuedMonth] 
,   a.firstIssuedMonth 
,   a.[returnType] 
,   a.[loyaltyPts] 
,   a.[loyaltyBezzalog] 
,   a.[loyalty] 
,  isnull( a.[firstLoanProductType] , a.[productType] ) [firstLoanProductType]
,   a.[ispdl] 
,   a.[dpdBeginDay0_1_45] 
,   a.[isLegal] 
,   a.[productType] 
,   a.[paid] 
,   a.[percentsPaid] 
,   a.[row_type] 
,   a.[mob] 
,   a.[clientMob] 
 ,  isnull( a.firstLoanRbp , a.rbp ) firstLoanRbp
 , issuedSum
,  fpd0
, issuedCnt
, principalPaid

, a.source
, a.channel
,    a.issuedSumBucket10000

into [product_report_balance]

        FROM 
#t237842309402389 a 

--truncate table product_report_balance_bi
drop table if exists product_report_balance_bi
select   'L12345'   groupBy   ,  'L'+format(loyalty  , '00') type, * into product_report_balance_bi from  [product_report_balance] union all
select   'MOB клиент'  ,  format(clientMob  , '00')    clientMob , *    from  [product_report_balance] union all
select   'MOB кредит'  ,  format( Mob  , '00')    Mob  , *   from  [product_report_balance]  union all
select   'Месяц'       ,  format( cast(DATEADD(MONTH, DATEDIFF(MONTH, 0,     date      ), 0) as date) , 'yyyy-MM')    Mob , *   from  [product_report_balance]  
 


 --delete from product_report_balance_bi where mob is null

 --select top 100 * from [product_report_balance] 
 --where  mob is null --and row_type <>'Цессия'


 
 --select top 100000 * from [product_report_balance_bi] 
 --where  mob is null --and row_type <>'Цессия'


 select * from product_report_balance_bi where returnType is null

-- select * from  product_report_balance_bi


-- select * from #t237842309402389
-- where firstloanrbp is null and ( returnType is null or returnType<>'Первичный' )



-- select * from _request where firstloanrbp is null
-- order by created desc


--return
--select * from 
        

--#t237842309402389 a 


--select count(*) from product_report_balance_bi
