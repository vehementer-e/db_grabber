CREATE proc sale_report_partial_repayment as 



select * from ##report_partial_repayment

return

drop table if exists #t1
select *  into #t1 from v_partial_repayment
where created<='20250501' and created>='20240701'
--;with v as (select *, ROW_NUMBER() over(partition by loanNumber, cast(created as date) order by created ) rn from #t1 )
--delete from v where rn>1
---------------------------------------------
---------------------------------------------



--select a.*, b.productType from #t1 a left join _request b on a.loanNumber=b.loanNumber
--order by a.created

--drop table if exists #t2
--select * into #t2 from v_partial_repayment 
--where  created>='20250501'


--;with v as (select *, ROW_NUMBER() over(partition by loanNumber, cast(created as date) order by created ) rn from #t2 )
--delete from v where rn>1
---------------------------------------------
---------------------------------------------


drop table if exists #next_pay_sum


select a.scheduleCreated, a.scheduleLink, b.loanNumber,  a.payDate,  a.paySum, b.created  PartialRepaymentRequest into #next_pay_sum  from loan_schedule_cmr_view a 
join #t1 b on a.loanNumber=b.loanNumber and a.scheduleCreated < b.created  and a.payDate >=b.created 

;
with v as (
select *, row_number() over(partition by loanNumber, PartialRepaymentRequest order by scheduleCreated desc, case when paySum=0 then 0 else 1 end desc ,  payDate   ) rn from  #next_pay_sum 
)
delete from  v where rn>1

---------------------------------------------
---------------------------------------------



drop table if exists #schedule

select a.* into #schedule from loan_schedule a join (select distinct loannumber from #t1) b on a.loanNumber=b.loanNumber and a.isProbationPay =0




drop table if exists #scheduleLastPay
 select loanNumber, max(payDate) lastPayDate into #scheduleLastPay from #schedule
 group by loanNumber


drop table if exists #balance_pay_date

select a.date, a.loanNumber, 
    a.[ЧДП Основной долг Уплачено]
  + a.[ЧДП Проценты Уплачено] 
  + a.[ЧДП Пени Уплачено]       
  + a.[ЧДП ГосПошлина Уплачено]  ЧДП_Уплачено
  into #balance_pay_date from v_balance a 
join #schedule s on a.loanNumber=s.loanNumber and s.payDate  = a.date



drop table if exists #dpd

select a.d, a.loanNumber, a.dpdBeginDay into #dpd from v_balance a 
join (select distinct   date, loanNumber from #t1 ) s on a.loanNumber=s.loanNumber and s.date  = a.date




drop table if exists #repayment

  select number, Сумма, Дата into #repayment from mv_repayments 
  where Дата>='20240601' and number in (select      loanNumber from #t1  )


  create index t on #repayment (number, Дата)


drop table if exists #_request


  select loanNumber, closed, isPts, productType, issuedSum into #_request from _request
  where loanNumber is not null


  --select count(*) from stg._1cCMR.Документ_ГрафикПлатежей





  --drop table if exists ##
  --select   * from stg._1cCMR.РегистрСведений_ДанныеГрафикаПлатежей 

  drop table if exists #final


select a.loanNumber, case when r.closed <=  x.nextPayDate then 'ПДП' else '' end + case when x.payDate=slp.lastPayDate then ' Последний платеж' 
else '' end 

ТипЧДП_ПДП  
, datediff(day , a.created, x.payDate ) dayToPay  

,  #dpd.dpdBeginDay  
, case when  #dpd.dpdBeginDay  >0 then 'Заявление от просрочника' else 'Без просрочки' end Просрочка
,  a.issued
,  a.DoB
,  a.isConducted
,  a.isAutoCreated
,  a.created PartialRepaymentRequest

,  x.payDate

, repaymentSum.Сумма
, balance_day_before_request.[ПереплатаНачислено нарастающим итогом] - 
  balance_day_before_request.[ПереплатаУплачено нарастающим итогом] Переплата


, isnull(  repaymentSum.Сумма ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом]- 
  balance_day_before_request.[ПереплатаУплачено нарастающим итогом] 

  ДенегКПлатежу
  , balance_day_request.[Расчетный остаток всего] [Расчетный остаток на дату заявления]
  , nps.paySum [Сумма платежа]
, nps.payDate payDate2
, case when  isnull(  repaymentSumDayRequest.СуммаВДеньЗаявления ,0 ) 
+ balance_day_before_request.[ПереплатаНачислено нарастающим итогом]
-   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего]  then 'Достаточно для ПДП в дату заявления'


when  isnull(  repaymentSum.Сумма ,0 ) 
+ balance_day_before_request.[ПереплатаНачислено нарастающим итогом]
-   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then 'Достаточно для ПДП'




when  isnull(  repaymentSum.Сумма ,0 ) 
+ balance_day_before_request.[ПереплатаНачислено нарастающим итогом]
-   balance_day_before_request.[ПереплатаУплачено нарастающим итогом] -1000 >=nps.paySum  then 'Достаточно для ЧДП (>1000)'

else 'Недостаточно' end [Сколько денег внесено]


, 
case when  isnull(  repaymentSumDayRequest.СуммаВДеньЗаявления ,0 ) 
+ balance_day_before_request.[ПереплатаНачислено нарастающим итогом]
-   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего]  then null


when  isnull(   repaymentSumDayRequest1.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего]  then 1 
when  isnull(   repaymentSumDayRequest2.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего]  then 2 
when  isnull(   repaymentSumDayRequest3.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего]  then 3 
when  isnull(   repaymentSumDayRequest4.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего]  then 4 
when  isnull(   repaymentSumDayRequest5.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего]  then 5 
when  isnull(   repaymentSumDayRequest6.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего]  then 6 
when  isnull(   repaymentSumDayRequest7.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего]  then 7 
when  isnull(   repaymentSumDayRequest8.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего]  then 8 
when  isnull(   repaymentSumDayRequest9.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего]  then 9 
when  isnull(  repaymentSumDayRequest10.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  10
when  isnull(  repaymentSumDayRequest11.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  11
when  isnull(  repaymentSumDayRequest12.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  12
when  isnull(  repaymentSumDayRequest13.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  13
when  isnull(  repaymentSumDayRequest14.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  14
when  isnull(  repaymentSumDayRequest15.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  15
when  isnull(  repaymentSumDayRequest16.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  16
when  isnull(  repaymentSumDayRequest17.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  17
when  isnull(  repaymentSumDayRequest18.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  18
when  isnull(  repaymentSumDayRequest19.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  19
when  isnull(  repaymentSumDayRequest20.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  20
when  isnull(  repaymentSumDayRequest21.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  21
when  isnull(  repaymentSumDayRequest22.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  22
when  isnull(  repaymentSumDayRequest23.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  23
when  isnull(  repaymentSumDayRequest24.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  24
when  isnull(  repaymentSumDayRequest25.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  25
when  isnull(  repaymentSumDayRequest26.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  26
when  isnull(  repaymentSumDayRequest27.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  27
when  isnull(  repaymentSumDayRequest28.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  28
when  isnull(  repaymentSumDayRequest29.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  29
when  isnull(  repaymentSumDayRequest30.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  30
when  isnull(  repaymentSumDayRequest31.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  31
when  isnull(  repaymentSumDayRequest32.СуммаВДеньЗаявления ,0 ) + balance_day_before_request.[ПереплатаНачислено нарастающим итогом] -   balance_day_before_request.[ПереплатаУплачено нарастающим итогом]  >= balance_day_request.[Расчетный остаток всего] then  32

else - 1000
 end [Через сколько дней внес достаточно]


,  b. ЧДП_Уплачено

--, x1.created nextPartialRepaymentRequest
, x .nextPayDate
, r.productType
, r.issuedSum 
--ПереплатаНаДатуЗаявления
--СколькоВнес
into #final
from #t1 a 
outer apply (select top 1 * from #schedule b where b.payDate >= cast( a.created  as date) and b.loanNumber=a.loanNumber order by b.payDate ) x
--outer apply (select top 1 * from #t2 b where b.loanNumber=a.loanNumber and cast(b.created as date)> x.payDate and cast(b.created as date) <=x.nextPayDate ) x1
left join #_request r on r.loanNumber = a.loanNumber  
outer apply (select sum(c.Сумма) Сумма  from #repayment c where c.number = a.loanNumber and c.Дата >=cast(a.created  as date) and cast( c.Дата as date) <=  x.payDate
) repaymentSum
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) =cast(a.created  as date) and cast( c.Дата as date) <=  x.payDate
) repaymentSumDayRequest
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 1, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate)  repaymentSumDayRequest1
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 2, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate)  repaymentSumDayRequest2
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 3, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate)  repaymentSumDayRequest3
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 4, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate)  repaymentSumDayRequest4
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 5, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate)  repaymentSumDayRequest5
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 6, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate)  repaymentSumDayRequest6
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 7, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate)  repaymentSumDayRequest7
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 8, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate)  repaymentSumDayRequest8
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 9, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate)  repaymentSumDayRequest9
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 10, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest10
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 11, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest11
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 12, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest12
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 13, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest13
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 14, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest14
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 15, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest15
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 16, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest16
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 17, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest17
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 18, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest18
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 19, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest19
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 20, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest20
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 21, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest21
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 22, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest22
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 23, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest23
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 24, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest24
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 25, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest25
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 26, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest26
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 27, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest27
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 28, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest28
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 29, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest29
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 30, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest30
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 31, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest31
outer apply (select sum(c.Сумма) СуммаВДеньЗаявления from #repayment c where c.number = a.loanNumber and  cast(c.Дата as date) between cast(a.created  as date) and dateadd(day, 32, cast(a.created  as date))   and cast( c.Дата as date) <=  x.payDate) repaymentSumDayRequest32






 
left join #balance_pay_date b on b.loanNumber=a.loanNumber and b.date = x.payDate
left join #dpd   on #dpd.loanNumber=a.loanNumber and #dpd.d = a.date
left join v_balance balance_day_before_request with(nolock)   on balance_day_before_request.loanNumber=a.loanNumber and balance_day_before_request.d = dateadd(day, -1,  a.date)
left join v_balance balance_day_request with(nolock)   on balance_day_request.loanNumber=a.loanNumber and balance_day_request.d = dateadd(day, 0,  a.date)

left join #next_pay_sum nps on nps.loanNumber=a.loanNumber and nps.PartialRepaymentRequest = a.created
left join #scheduleLastPay slp on slp.loanNumber=a.loanNumber
--where r.isPts=1
order by 2,  dpdBeginDay  , DOB 
 
;

;with v as (select *, ROW_NUMBER() over(partition by loanNumber, payDate order by PartialRepaymentRequest ) rn from #final )
delete from v where rn>1

 
 drop table if exists ##report_partial_repayment
select * into ##report_partial_repayment from #final
where paydate is not null
order by 2,  dpdBeginDay  , DOB 


select *     from ##report_partial_repayment
where paydate is not null
order by 2,  dpdBeginDay  , DOB 
;

select top 1000 *, lead(created) over(partition by loanNumber order by created) leadd  


from #t1 
--where created between '20250401' and '20250501'
order by created desc



select * from #t1
where created between '20250401' and '20250501'

order by created


select * from v_balance
where number='25032803149950'
order by date