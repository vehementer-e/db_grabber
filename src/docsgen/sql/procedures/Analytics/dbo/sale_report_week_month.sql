
CREATE proc [dbo].[sale_report_week_month] @mode   varchar(max) as


if @mode = 'run'

begin

exec _etl_gs 'selfemployed'

exec python 'weekly_report(test=False)', 1

end




if @mode = 'period'
begin




with weeks as (

select * from (
select top 16 week , min(date) minDate, min(month) month, max(date) date  from calendar_view 
where date<=getdate()-1
group by week
order by week desc
) x
--order by week
)

, months as (
select distinct month from calendar_view
where date<=getdate()-1   and date>= (select min(month) from weeks)

) 

, comb as (
select week , mindate, month from weeks
union all
select null , null, month from months
) 

, comb2 as (
select top 100  *, text = case when week is null then format(month , 'MMMM', 'ru-Ru') else format(mindate, 'dd-MM-yyyy') + ' - '+ format(dateadd(day, 6 , mindate), 'dd-MM-yyyy')  end from comb
order by month, case when week is null then '21000101' else week end
) 
, comb3 as (
select top 17 * from comb2
order by isnull(week, dateadd(month, 1, month)) desc
)
select top 1000 * from comb3
order by month, case when week is null then '21000101' else week end


end


if @mode = 'period_month'
begin
select * from (
select top 4 null week, min(date) minDate, month, min( format(month , 'MMMM', 'ru-Ru')) text  from calendar_view 
where date <getdate()-1
group by month
order by month desc
) x
order by month
end


if @mode = 'issued'
begin
declare @rr float = (select rr_pts from sale_plan_run_rate)

select c.week issuedWeek , c.month issuedMonth,

case when productType in ('pdl', 'inst' ) then 'bezzalog'
else productType end productType
, case 
when source like 'tpokupki%' then 'Т-Банк'
when source like 'psb%' then 'ПСБ'
when source like 'infoseti%' then 'ГПБ'
else 'other' end sourceGroup,
isnull(issuedSum, b.Сумма) issuedSum ,  1 as isIssued , @rr as rr, 
case when isSelfEmployedManual = 1 or se. [номер заявки] is not null  then 'selfEmployedManual'
else isnull(finalLimitChoice, 'withoutIncomeConfirm' ) end finalLimitChoice


from request a
left join stg._1cCMR.Справочник_Договоры b on a.link=b.Заявка
left join calendar_view c on c.date = cast( case when productType='autocredit' then  contractSigned else issued end as date)
left join (select distinct  [номер заявки] from _request_selfemployed_manual ) se on cast(se. [номер заявки] as nvarchar(20)) = a.number
where  cast( case when productType='autocredit' then  contractSigned else issued end as date) >=getdate()-150
and a.status_crm <>'Заем аннулирован'
end


--select distinct finalLimitChoice from request

if @mode = 'budget'
begin


declare @month date = (select month from sale_plan_run_rate)
 
 ; with budget as (
select  cast( case 
when productType  in ('INST', 'PDL') and channel='CM'   then 'BEZZALOG CM'
when productType in ('INST', 'PDL') and channel='ПСБ'   then 'BEZZALOG PSB'
when productType in ('INST', 'PDL') and channel='ГПБ'   then 'BEZZALOG GPB'
when productType in ('PTS') and channel='ПСБ'           then 'PTS PSB'
when productType in ('PTS') and channel='ГПБ'           then 'PTS GPB'
when productType in ('PTS') and channel='CM'            then 'PTS CM'
when productType in ('PTS') and channel='Т-Банк'        then 'PTS T-Bank'
when productType in ('BIG INST') and channel='ПСБ'     then 'BIG INST PSB'
when productType in ('BIG INST') and channel='ГПБ'     then 'BIG INST GPB'
when productType in ('BIG INST') and channel='Т-Банк'  then 'BIG INST T-Bank'
when productType in ('AUTOCREDIT') and channel='Т-Банк' then 'AUTOCREDIT T-Bank'
when productType in ('AUTOCREDIT') and channel='CM'     then 'AUTOCREDIT CM'


when productType in ('BIG INST')  then 'BIG INST MARKET'
when productType in ('AUTOCREDIT')  then 'AUTOCREDIT'
--when  product_type in ('No pledge bank') then 'BEZZALOG PSB'
--when  product_type in ('PTS Bank') then 'PTS PSB'
--when  product_type in ('PTS') then 'PTS CM'
--when  product_type in ('LONG INST') then 'BIG INST PSB'
   else '?' end as nvarchar(100)) productType, 
   sumLoan  sum, date from sale_plan_budget_view_new 
   ),
   request1  as (

   select cast( case 
   
   when source like 'psb%' and productType2 = 'BEZZALOG' then  'BEZZALOG PSB'
   when source like 'infoseti%' and productType2 = 'BEZZALOG' then  'BEZZALOG GPB'

   when  productType2 = 'BEZZALOG' then  'BEZZALOG CM'
   
   when source like 'psb%' and productType2 = 'PTS' then  'PTS PSB'
   when source like 'tpokupki%' and productType2 = 'PTS' then  'PTS T-Bank'
   when source like 'infoseti%' and productType2 = 'PTS' then  'PTS GPB'

   when  productType2 = 'PTS' then  'PTS CM'
   when source like 'tpokupki%' and productType2 = 'BIG INST' then  'BIG INST T-Bank'
   when source like 'infoseti%' and productType2 = 'BIG INST' then  'BIG INST GPB'
   when source like 'psb%' and productType2 = 'BIG INST' then  'BIG INST PSB'
   when  productType2 = 'BIG INST' then  'BIG INST MARKET'
   when source like 'tpokupki%' and productType2 = 'AUTOCREDIT' then  'AUTOCREDIT T-Bank'
   when   productType2 = 'AUTOCREDIT' then  'AUTOCREDIT CM'




   else  productType2 end as nvarchar(100)) productType2
   
   
   
   
   ,  (issuedSum)  issuedSum, issuedMonth
   
   from request 

   ), fact_agr as (

   select isnull( productType2, ' Итого') Продукт, sum(issuedSum) [Сумма факт] from request1 
   where issuedMonth  = @month
   group by rollup(productType2  )
   )

    , plan_agr  as (

   select isnull(productType , ' Итого') Продукт, 
  sum(sum)    [Сумма план]
  from budget a join calendar_view b on a.date=b.date and b.month = @month
group by rollup( productType )
 
)

select isnull(a.Продукт , b.Продукт) Продукт, a.[Сумма план], b.[Сумма факт] from plan_agr a
full outer join fact_agr b on a.Продукт = b.Продукт
order by case when isnull(a.Продукт , b.Продукт) like 'PTS%' then 1 when isnull(a.Продукт , b.Продукт) like 'bezzalog%' then 2 when isnull(a.Продукт , b.Продукт) like 'BIG%' then 3 when isnull(a.Продукт , b.Продукт) like 'AUTOCR%' then 4 else 5  end , a.Продукт -- desc

end

if @mode = 'funnel'
begin



select isnull(a.call1, a.created) date,
b.week ,
b.month   
, sum(case when leadRn=1  and (isAccepted =1 or id >0) then 1 end) [Лидов accpted]
, count(case when productType = 'pts' then call03 end) [call03]
, count(case when productType = 'pts' then call03approved end) call03approved
, count(case when productType = 'pts' then call1 end) call1
, count(case when productType = 'pts' then call1approved end) [call1approved]
, count(case when productType = 'pts' then checking end) checking
, count(case when productType = 'pts' and (carVerification is not null or declined is not null) then checking end) checkingNotStuck
, count(case when productType = 'pts'    then carVerification end) carVerification
, count(case when productType = 'pts'    then approved end) approved
, count(case when productType = 'pts'    then issued end) issued
, count(case when productType = 'pts'    then isnull(declined, approved)  end)  declinedOrApprobed
, case 
when source like 'tpokupki%' then 'Т-Банк'
when source like 'psb%' then 'ПСБ'
when source like 'infoseti%' then 'ГПБ'
else 'CM' end sourceGroup 
 


from lead_request_bi a
left join calendar_view b on isnull(a.call1, a.created) = b.date
where isnull(isdubl, 0)=0-- and returnType='Первичный'
and isnull(a.call1, a.created) >= getdate()-200
group by isnull(a.call1, a.created), b.week, b.month ,
 case 
when source like 'tpokupki%' then 'Т-Банк'
when source like 'psb%' then 'ПСБ'
when source like 'infoseti%' then 'ГПБ'
else 'CM' end


end



if @mode = 'funnel biginst'
begin



select isnull(a.call1, a.created) date,
b.week ,
b.month   
, sum(case when leadRn=1  and (isAccepted =1 or id >0) then 1 end) [Лидов accpted]
, count(case when productType = 'big inst' then call03 end) [call03]
, count(case when productType = 'big inst' then call03approved end) call03approved
, count(case when productType = 'big inst' then call1 end) call1
, count(case when productType = 'big inst' then call1approved end) [call1approved]
, count(case when productType = 'big inst' then checking end) checking
, count(case when productType = 'big inst' and (approved is not null or declined is not null) then checking end) checkingNotStuck
, count(case when productType = 'big inst'    then carVerification end) carVerification
, count(case when productType = 'big inst'    then approved end) approved
, count(case when productType = 'big inst'    then issued end) issued
, count(case when productType = 'big inst'    then isnull(declined, approved)  end)  declinedOrApprobed
, case 
when source like 'psb%' then 'ПСБ' 
else 'РЫНОЧНЫЙ' end sourceGroup 
 


from lead_request_bi a
left join calendar_view b on isnull(a.call1, a.created) = b.date
where isnull(isdubl, 0)=0-- and returnType='Первичный'
and isnull(a.call1, a.created) >= getdate()-200
and isnull(a.call1, a.created) >= '20251020'
and (source like 'psb-deepapi' or  
 a.source     IN ('infoseti-deepapi-pts')  or 
 a.source  like '%big-inst%'
or  a.productSubType  in (  'Big Installment Рыночный'  , 'Big Installment Рыночный - Самозанятый') 
  
  
  )
  and isnull(a.channel , '')<>'Тест'
group by isnull(a.call1, a.created), b.week, b.month ,
 case  
when source like 'psb%' then 'ПСБ' 
else 'РЫНОЧНЫЙ' end


end










if @mode = 'approved'
begin
 
select b.week, b.month
, case when approved is not null then 1 else 0 end isApproved
, case when isnull(contractSigned, issued) is not null then 1 else 0 end isCOntractSigned
,  isLoan
, case when status_crm='Период охлаждения' and issued is null then 1 else 0 end as isFreezing
, case when paused is not null and issued is null then 1 else 0  end  as isPaused
, case when paused is not null and issued is null then number  end  as pausedNumber


from request a
left join calendar_view b on cast(a.approved as date)=b.date
where approved>=getdate()-120 and a.productType='pts' and isDubl=0

end



if @mode = 'approved biginst'
begin
 
select b.week, b.month
, case when approved is not null then 1 else 0 end isApproved
, case when isnull(contractSigned, issued) is not null then 1 else 0 end isCOntractSigned
,  isLoan
, case when status_crm='Период охлаждения' and issued is null then 1 else 0 end as isFreezing
, case when paused is not null and issued is null then 1 else 0  end  as isPaused
, case when paused is not null and issued is null then number  end  as pausedNumber
, case 
when source like 'psb%' then 'ПСБ' 
else 'РЫНОЧНЫЙ' end sourceGroup 

from request a
left join calendar_view b on cast(a.approved as date)=b.date
where approved>=getdate()-120 and a.productType='BIG INST' and isDubl=0

end


