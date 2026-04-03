

CREATE  proc [dbo].[sale_report_budget_plan_fact_mail]	   @date_sp date = null, @mode varchar(max) = 'update'

as
 

  

--declare @date_sp date --= '20260119'
--declare @date_sp date  = '20260201'
--exec [sale_report_budget_plan_fact_mail]   '20260201'


set language english
declare @now_date date = case when @date_sp is null then getdate() else 	@date_sp end
declare @report_date date = dateadd(day, -1, @now_date)
declare @datefrom date = datefromparts(year(@report_date),month(@report_date),1)
 
 drop table if exists #txt

;
with plann as 
(

select case when  productType in ('inst', 'pdl') then 'BEZZALOG' when productType = 'BIG INST' then 'BIG INST' else producttype end producttype2 
, sum(sumLoan) issuedSum
, sum(addproductSumNet) addproductSumNet 
, sum(interestRateSum)/ nullif( sum(sumLoan) ,0) interestRate
, 'total' groupName
from sale_plan_budget_view_new
where cast(DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0) as date) = @datefrom

 group by case when  productType in ('inst', 'pdl') then 'BEZZALOG' when productType = 'BIG INST' then 'BIG INST' else producttype end
 with rollup  

 union all


 select  'BIG INST PSB' producttype2 
, sum(sumLoan) issuedSum
, sum(addproductSumNet) addproductSumNet 
, sum(interestRateSum)/ nullif( sum(sumLoan) ,0) interestRate
, 'BI PSB' groupName
from sale_plan_budget_view_new
where cast(DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0) as date) = @datefrom
and productType = 'BIG INST'
and channel = 'ПСБ'

 union all


 select  'BIG INST MARKET' producttype2 
, sum(sumLoan) issuedSum
, sum(addproductSumNet) addproductSumNet 
, sum(interestRateSum)/ nullif( sum(sumLoan) ,0) interestRate

, 'BI MARKET' groupName
from sale_plan_budget_view_new
where cast(DATEADD(MONTH, DATEDIFF(MONTH, 0, date), 0) as date) = @datefrom
and productType = 'BIG INST'
and isnull(channel, '') <> 'ПСБ'

  
 --with rollup  




 )
 --select * from plann
 , fact as (
 select a.producttype2 
 , sum(a.issuedSum) issuedSum
 , sum(a.addproductSumNet) addproductSumNet
 , isnull( sum(a.issuedSum * isnull(b.interestRate, 0)/100.0)/ nullif( sum(a.issuedSum * case when b.interestRate >0 then 1 else 0 end ) ,0) , 0) interestRate
, 'total' groupName
 
 
 from  v_fa a 
 left join v_loan_report b on a.number=b.number
 
 where a.issuedMonth = @datefrom and issuedDate<=@report_date
 group by a.producttype2
 with rollup  
 
 union all 

  select 'BIG INST PSB' producttype2
 , sum(a.issuedSum) issuedSum
 , sum(a.addproductSumNet) addproductSumNet
 , isnull( sum(a.issuedSum * isnull(b.interestRate, 0)/100.0)/ nullif( sum(a.issuedSum * case when b.interestRate >0 then 1 else 0 end ) ,0) , 0) interestRate
, 'BI PSB' groupName
 
 
 from  v_fa a
 left join v_loan_report b on a.number=b.number

  where a.issuedMonth = @datefrom-- and issuedDate<=@report_date
 and a.producttype2  = 'BIG INST'
 and a.source   like  'psb%'
 --group by a.producttype2
 --with rollup  

  
 union all 

  select 'BIG INST MARKET' producttype2
 , sum(a.issuedSum) issuedSum
 , sum(a.addproductSumNet) addproductSumNet
 , isnull( sum(a.issuedSum * isnull(b.interestRate, 0)/100.0)/ nullif( sum(a.issuedSum * case when b.interestRate >0 then 1 else 0 end ) ,0) , 0) interestRate
, 'BI MARKET' groupName
 
 
 from  v_fa a
 left join v_loan_report b on a.number=b.number

  where a.issuedMonth = @datefrom-- and issuedDate<=@report_date
 and a.producttype2  = 'BIG INST'
 and isnull(a.source , '') not like  'psb%'
 --group by a.producttype2
 --with rollup  

 
 )





 , txt as (
/*    select
        'Статистика за ' +
        format(@datefrom, 'MMMM yyyy') +
        ' (1-' + format(day(@report_date), 'N0') + ')' +
        CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +

        STRING_AGG(
            'Займы ' +
            case when prouductType2 = 'Total' then 'Общая статистика' else prouductType2 end + ':' + CHAR(13) + CHAR(10) +
            'Общая выданная сумма - ' + format(issuedSumFact, 'N0') +
            ', что составляет ' + format(issuedSumFact * 1.0 / issuedSum, 'P1') +
            ' от общего плана в ' + format(issuedSum, 'N0') + '.' + CHAR(13) + CHAR(10) +
            'RR = ' + format(issuedSumRR, 'N0') +
            ' (' + format(issuedSumRR / issuedSum, 'P1') + ')' + CHAR(13) + CHAR(10) +
            'Ставка: план - ' + format(interestRate, 'P1') +
            ', факт - ' + format(interestRateFact, 'P1') + CHAR(13) + CHAR(10) +

			  
            'КП net - ' + format(addproductSumNetFact, 'N0') +
            ', что составляет ' + format( isnull(addproductSumNetFact * 1.0 / nullif( addproductSumNet , 0) ,0) , 'P1') +
            ' от общего плана в ' + format(addproductSumNet, 'N0') + '.' + CHAR(13) + CHAR(10) +


            'Доля кп net: план - ' + format(addproductSumNet / issuedSum, 'P2') +
            ', факт - ' + format(addproductSumNetFact / issuedSumFact, 'P2') +
            CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
        , CHAR(13) + CHAR(10)
        ) within group ( order by case when prouductType2 = 'PTS' then 1
                      when prouductType2 = 'BEZZALOG' then 2
                      when prouductType2 = 'BIG INST' then 3
                      when prouductType2 = 'AUTOCREDIT' then 4
                      when prouductType2 = 'Total' then 5 end ) as fullText
    from (
        select * 
        from (
            select isnull(a.producttype2, 'Total') prouductType2
                 , a.issuedSum
                 , a.addproductSumNet
                 , a.interestRate
                 , b.issuedSum issuedSumFact
                 , b.addproductSumNet addproductSumNetFact
                 , b.interestRate interestRateFact
                 , b.issuedSum / (select rr_pts from sale_plan_run_rate) issuedSumRR
            from plann a
            left join fact b on isnull(a.producttype2, '') = isnull(b.productType2, '')
        ) x
       
    ) y
	*/

select
    /* Оригинальный текст */
    'Статистика за ' + format(@datefrom, 'MMMM yyyy') + ' (1-' + format(day(@report_date), 'N0') + ')' + 
    CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
    STRING_AGG( case when groupName = 'total' then
        'Займы ' + case when prouductType2 = 'Total' then 'Общая статистика' else prouductType2 end + ':' + CHAR(13) + CHAR(10) +
        'Общая выданная сумма - ' + format(isnull( issuedSumFact ,0), 'N0') + ', что составляет ' + format(isnull(issuedSumFact * 1.0 / nullif(issuedSum,0), 0), 'P1') + ' от общего плана в ' + format(issuedSum, 'N0') + '.' + CHAR(13) + CHAR(10) +
        'RR = ' + format(isnull(issuedSumRR, 0), 'N0') + ' (' + format(isnull(issuedSumRR / nullif(issuedSum,0), 0), 'P1') + ')' + CHAR(13) + CHAR(10) +
        'Ставка: план - ' + format(isnull(interestRate, 0), 'P1') + ', факт - ' + format(isnull(interestRateFact, 0), 'P1') + CHAR(13) + CHAR(10) +
        'КП net - ' + format( isnull( addproductSumNetFact ,0), 'N0') + ', что составляет ' + format(isnull(addproductSumNetFact * 1.0 / nullif(addproductSumNet, 0), 0), 'P1') + ' от общего плана в ' + format(addproductSumNet, 'N0') + '.' + CHAR(13) + CHAR(10) +
        'Доля кп net: план - ' + format(isnull(addproductSumNet / nullif(issuedSum,0), 0), 'P2') + ', факт - ' + format(isnull(addproductSumNetFact / nullif(issuedSumFact,0), 0), 'P2') + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
  end
  , CHAR(13) + CHAR(10)) within group (order by sortOrder) as fullText,

    /* Форматирование под Telegram (HTML) */
    N'<b>📊 Статистика за ' + format(@datefrom, 'MMMM yyyy', 'ru-RU') + ' (1-' + format(day(@report_date), 'N0') + ')</b>' + 
    CHAR(10) + CHAR(10) +
    STRING_AGG(
	case when 1=1 then 
        N'<b>🔹 ' + case when prouductType2 = 'Total' then 'ОБЩАЯ СТАТИСТИКА' else 'Займы ' + prouductType2 end + ':</b>' + CHAR(10) +
		'План: <b>' + format(issuedSum, 'N0') + '</b>' + CHAR(10) +
        'Факт: <b>' + format(isnull( issuedSumFact ,0), 'N0') +'</b>'   + ' (<code>' + format(isnull(issuedSumFact * 1.0 / nullif(issuedSum,0), 0), 'P1') +'</code>)'  +CHAR(10) +
        'RR: <b>' + format(isnull(issuedSumRR, 0), 'N0') + '</b> (<code>' + format(isnull(issuedSumRR / nullif(issuedSum,0), 0), 'P1') + '</code>)' + CHAR(10)   +
		'КП net план: <b>' + format(addproductSumNet, 'N0') + '</b>' + CHAR(10) +
        'КП net факт: <b>' + format(isnull( addproductSumNetFact ,0), 'N0') + '</b>'   + '<code> (' + format(isnull(addproductSumNetFact * 1.0 / nullif(addproductSumNet, 0), 0), 'P1') + ')</code>'  + CHAR(10) +
        'Доля КП net: план <code>' + format(isnull(addproductSumNet / nullif(issuedSum,0), 0), 'P2') + '</code> | факт <code>' + format(isnull(addproductSumNetFact / nullif(issuedSumFact,0), 0), 'P2') + '</code>' + CHAR(10) +  
        'Ставка: план <code>' + format(isnull(interestRate, 0), 'P1') + '</code> | факт <code>' + format(isnull(interestRateFact, 0), 'P1') + '</code>' + CHAR(10)  
  end
  , CHAR(10)) within group (order by sortOrder) as fullTextTelegram,

    /* Форматирование под Telegram (HTML) для PSB */
    N'<b>📊 Статистика за ' + format(@datefrom, 'MMMM yyyy', 'ru-RU') + '</b>' + 
    CHAR(10) + CHAR(10) +
    STRING_AGG(
	case when groupName = 'BI PSB' then
        N'<b>🔹 ' + case when prouductType2 = 'Total' then 'ОБЩАЯ СТАТИСТИКА' else 'Займы ' + prouductType2 end + ':</b>' + CHAR(10) +
		'План: <b>' + format(issuedSum, 'N0') + '</b>' + CHAR(10) +
        'Факт: <b>' + format(isnull( issuedSumFact ,0), 'N0') +'</b>'   + ' (<code>' + format(isnull(issuedSumFact * 1.0 / nullif(issuedSum,0), 0), 'P1') +'</code>)'  +CHAR(10) +
		'КП net план: <b>' + format(addproductSumNet, 'N0') + '</b>' + CHAR(10) +
        'КП net факт: <b>' + format( isnull( addproductSumNetFact ,0), 'N0') + '</b>'   + '<code> (' + format(isnull(addproductSumNetFact * 1.0 / nullif(addproductSumNet, 0), 0), 'P1') + ')</code>'  + CHAR(10) +
        'Доля КП net: план <code>' + format(isnull(addproductSumNet / nullif(issuedSum,0), 0), 'P2') + '</code> | факт <code>' + format(isnull(addproductSumNetFact / nullif(issuedSumFact,0), 0), 'P2') + '</code>' + CHAR(10) +  
        'Ставка: план <code>' + format(isnull(interestRate, 0), 'P1') + '</code> | факт <code>' + format( isnull(interestRateFact, 0), 'P1') + '</code>' + CHAR(10)  
  end
  , CHAR(10)) within group (order by sortOrder) as fullTextPsbTelegram 

from (
    select *,
        case when prouductType2 = 'PTS' then 1.0
             when prouductType2 = 'BEZZALOG' then 2
             when prouductType2 = 'BIG INST' then 3
             when prouductType2 = 'BIG INST MARKET' then 3.1
             when prouductType2 = 'BIG INST PSB' then 3.2
             when prouductType2 = 'AUTOCREDIT' then 4
             when prouductType2 = 'Total' then 5 end as sortOrder
    from (
        select isnull( isnull(a.producttype2 , b.productType2) , 'Total') prouductType2
             , a.issuedSum
             , a.addproductSumNet
             , a.interestRate
             , b.issuedSum issuedSumFact
             , b.addproductSumNet addproductSumNetFact
             , b.interestRate interestRateFact
             , isnull( b.issuedSum / nullif( isnull((select rr_pts from sale_plan_run_rate where month = @datefrom ), 1.0) , 0) ,0) issuedSumRR
			 , a.groupName
        from plann a
        full outer join fact b on isnull(a.producttype2, '') = isnull(b.productType2, '') and a.groupName=b.groupName
    ) x
) y


)
 

 select * into #txt from txt

  
  declare @message1 nvarchar(max) = ( select fullText from #txt)
   

drop table if exists [sale_report_budget_plan_fact]
select * into [sale_report_budget_plan_fact] from #txt

update [оперативная витрина с выдачами и каналами агрегаты] set text = isnull( (select fullTextTelegram from Analytics.dbo.[sale_report_budget_plan_fact]), 'Нет данных' ) where command = 'budget'
update [оперативная витрина с выдачами и каналами агрегаты] set text = isnull( (select fullTextPsbTelegram from Analytics.dbo.[sale_report_budget_plan_fact]), 'Нет данных' ) where command = 'get_psb_stat'


select @message1	 d


 


if @mode = 'send' and day(@now_date)=1
begin
--exec log_email 'RR Budget' , 'p.ilin@techmoney.ru', @message
exec log_email 'RR Budget ИТОГ ЗА МЕСЯЦ' , 'p.ilin@techmoney.ru; blagoveschenskaya@carmoney.ru', @message1

return

end





if @mode = 'send'
begin
--exec log_email 'RR Budget' , 'p.ilin@techmoney.ru', @message
exec log_email 'RR Budget' , 'p.ilin@techmoney.ru; blagoveschenskaya@carmoney.ru', @message1


end
return

declare @completion_rate float

select @completion_rate = cast(sum([ДоляДняПтс]) AS DECIMAL(10, 6)) from sale_plan_view
where День between @datefrom and @report_date

drop table if exists #fact

select 
@datefrom Дата,
sum(case when ispts=0 then [Выданная сумма] end) БеззалогF,
sum(case when ispts=1 then [Выданная сумма] end) ПТСF,
sum([Выданная сумма]) ТоталF
into #fact
from v_fa
where cast([Заем выдан] as date) between @datefrom and @report_date
and productType in ('PTS', 'INST', 'PDL')


drop table if exists #plan

select isnull(x.Дата, b.month) Дата
, isnull (b.sum_bz,   x.Беззалог) Беззалог 
, isnull (b.sum_pts,   x.ПТС) ПТС 
 , Тотал =isnull( isnull (b.sum_pts,   x.ПТС)+isnull (b.sum_bz,   x.Беззалог)  ,0) into #plan
from ( 
select Дата = cast( '20240201' as date) ,  Беззалог = 42809712.0, ПТС = 252230000.0 union all
select Дата = '20240301'                , Беззалог = 43623920.0, ПТС = 288650000.0  union all
select Дата = '20240401'                , Беззалог = 67278996.0, ПТС = 302450000.0  union all		
select Дата = '20240501'                , Беззалог = 74239543.0, ПТС = 346150000.0  union all
select Дата = '20240601'                , Беззалог = 81437874.0, ПТС = 281750000.0  union all
select Дата = '20240701'                , Беззалог = 82717765.0, ПТС = 304200000.0  union all
select Дата = '20240801'                , Беззалог = 52330792.0, ПТС = 285000000.0  union all
select Дата = '20240901'                , Беззалог = 53390204.0, ПТС = 285000000.0  union all
select Дата = '20241001'                , Беззалог = 54565583.0, ПТС = 285000000.0  union all
select Дата = '20241101'                , Беззалог = 55478318.0, ПТС = 285000000.0  union all
select Дата = '20241201'                , Беззалог = 56331909.0, ПТС = 300000000.0  --union all
 ) x

 full outer  join 
 (
 SELECT 
              cast( format( a.[date], 'yyyy-MM-01') as date ) month
--,   a.[is_Pts] 
--,   a.[product_type] 
--,   a.[Вид займа любой продукт] 
--,   a.[cntRequest_budget] 
--,   a.[cntLoan_budget] 
,  sum(a.is_pts* a.[sumLoan_budget] )sum_pts
,  sum((1-a.is_pts)* a.[sumLoan_budget] )sum_bz

            FROM 

            Analytics.dbo.[sale_plan_budget_view] a
			where product_type not in ('AUTOCREDIT', 'LONG INST')
			group by 
                cast( format( a.[date], 'yyyy-MM-01') as date )


			) b on x. дата = b. month 

 

drop table if exists #planfact

select f.Дата, БеззалогF, ПТСF, ТоталF,
       Беззалог БеззалогP, ПТС ПТСP, Тотал ТоталP,
       (БеззалогF/Беззалог)*100 [% выполнения Беззалог], (ПТСF/ПТС)*100 [% выполнения ПТС], (ТоталF/Тотал)*100 [% выполнения Тотал],
       БеззалогF/@completion_rate [RR Беззалог], ПТСF/@completion_rate [RR ПТС], ТоталF/@completion_rate [RR Тотал],
       ((БеззалогF/@completion_rate)/Беззалог)*100 [% RR Беззалог], ((ПТСF/@completion_rate)/ПТС)*100 [% RR ПТС], ((ТоталF/@completion_rate)/Тотал)*100 [% RR Тотал]
into #planfact 
from #fact f left join #plan p on p.Дата=f.Дата
 
declare @rate_plan nvarchar(5)

select @rate_plan = ptsInterestRate from Analytics.dbo.[sale_plan]
where cast(date as date) = @datefrom 

declare @rate_fact nvarchar(5)

select @rate_fact = cast((try_cast(sum(case when [Процентная ставка]>0 then [Выданная сумма]*[Процентная ставка] else 0 end)as float)/nullif((sum(case when [Процентная ставка]>0 then [Выданная сумма] else 0 end)*100),0))*100 AS DECIMAL(4, 1))
from v_fa
where isPts=1 and cast([Заем выдан] as date) between @datefrom and @report_date
and productType ='PTS'


declare @share_plan nvarchar(5)

select @share_plan = cast([КП net месяц]/[Сумма месяц]*100 AS DECIMAL(5, 2)) from sale_plan_view
where cast(День as date) = @datefrom 

declare @share_fact nvarchar(5)

select @share_fact = cast(sum([Сумма Дополнительных Услуг Carmoney Net])/sum([Выданная сумма])*100 AS DECIMAL(5, 2))
from v_fa
where isPts=1 
and cast([Заем выдан] as date) between @datefrom and @report_date
and productType ='PTS'


declare @month nvarchar(10)
SET LANGUAGE Russian;
select @month = datename(month, @report_date)


declare @year nvarchar(10)
select @year = year(@report_date)


declare @date nvarchar(10)
select @date = '(1-'+ cast(day(@report_date) as varchar(2))+')'

 
update #planfact set [% выполнения Беззалог] = 0 where [% выполнения Беззалог] is null
update #planfact set [БеззалогF] = 0 where БеззалогF is null
update #planfact set [% RR Беззалог] = 0 where [% RR Беззалог] is null
update #planfact set [RR Беззалог] = 0 where [RR Беззалог] is null

 
  
declare @message nvarchar(max) = (select STRING_AGG ('Статистика за ' + @month + ' ' + @year + ' ' + @date + CHAR(10) + CHAR(10) +
                                                     'Беззалоговые займы:' + CHAR(10) +
													 'Общая выданная сумма - ' + convert(varchar(max), format(БеззалогF,'###,###,###')) + ', что составляет ' + convert(varchar(max),cast([% выполнения Беззалог] AS DECIMAL(10, 1))) + '% от общего плана в ' + convert(varchar(max), format(БеззалогP,'###,###,###')) + '.' + CHAR(10) +
													 'RR = ' + convert(varchar(max), format([RR Беззалог],'###,###,###')) + ' (' + convert(varchar(max),round([% RR Беззалог], 1)) + '%)' + CHAR(10) + CHAR(10) +
													 'Займы под ПТС:' + CHAR(10) +
													 'Общая выданная сумма - ' + convert(varchar(max), format(ПТСF,'###,###,###')) + ', что составляет ' + convert(varchar(max),cast([% выполнения ПТС] AS DECIMAL(10, 1))) + '% от общего плана в ' + convert(varchar(max), format(ПТСP,'###,###,###')) + '.' + CHAR(10) +
													 'RR = ' + convert(varchar(max), format([RR ПТС],'###,###,###')) + ' (' + convert(varchar(max),round([% RR ПТС], 1)) + '%)' + CHAR(10) +
													 'Ставка: план - ' + @rate_plan + '%, факт - ' + @rate_fact + '%' + CHAR(10) +
													 'Доля кп net: план - ' + @share_plan + '%, факт - ' + @share_fact + '%' + CHAR(10) + CHAR(10) +
													 'Общая статистика:' + CHAR(10) +
													 'Общая выданная сумма - ' + convert(varchar(max), format(ТоталF,'###,###,###')) + ', что составляет ' + convert(varchar(max),cast([% выполнения Тотал] AS DECIMAL(10, 1))) + '% от общего плана в ' + convert(varchar(max), format(ТоталP,'###,###,###')) + '.' + CHAR(10) +
													 'RR = ' + convert(varchar(max), format([RR Тотал],'###,###,###')) + ' (' + convert(varchar(max),round([% RR Тотал], 1)) + '%)'
													 , '')

from #planfact)


select @message	 d
--exec log_email 'RR Budget' , 'p.ilin@techmoney.ru', @message
exec log_email 'RR Budget' , 'p.ilin@techmoney.ru; blagoveschenskaya@carmoney.ru', @message

 
--exec  [dbo].[RR_calculation]	