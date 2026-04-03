

CREATE proc [dbo].[bot_analytics_portfolio]
as




while not exists (select top 1 * from v_balance where principalRest >0 and date= cast(getdate() as date) )

waitfor delay '0:01:00'
select 1



drop table if exists #loan

select number, max(productType2) productType2 into #loan from request where productType2 in ('autocredit' , 'big inst')
group by number

drop table if exists #t1

select Месяц month, max(Дата) date into #t1 from v_Calendar where  Дата between dateadd(month, -15, getdate()) and getdate()
group by Месяц

drop table if exists #report_portfolio_month

select a.month  ,   a.date   , case when c.productType2='autocredit' then c.productType2 when c.productType2='big inst' then 'Инстоллмент' else  b.[Тип Продукта]  end Продукт, sum([остаток од])  [остаток од млн] 
, sum(case when dpd<=90 then [остаток од] end )  as [остаток од активный млн]
into #report_portfolio_month from #t1 a
left join v_balance b on b.d=  a.date 
left join #loan c on c.number=b.number 
group by  a.month  ,   a.date  , case when c.productType2='autocredit' then c.productType2 when c.productType2='big inst' then 'Инстоллмент' else  b.[Тип Продукта]  end
order by 1 desc

delete from  report_portfolio_month
insert into 
report_portfolio_month 
select *
from #report_portfolio_month





drop table if exists #t2

select week week, max(date) date into #t2 from calendar_view where  date between dateadd(month, -5, getdate()) and getdate()
group by week

drop table if exists #report_portfolio_week

select a.week  ,   a.date   , case when c.productType2='autocredit' then c.productType2 when c.productType2='big inst' then 'Инстоллмент' else  b.[Тип Продукта]  end Продукт, sum([остаток од])  [остаток од млн] 
, sum(case when dpd<=90 then [остаток од] end )  as [остаток од активный млн]

into #report_portfolio_week from #t2 a
left join v_balance b on b.d=  a.date 
left join #loan c on c.number=b.number 
group by  a.week  ,   a.date  , case when c.productType2='autocredit' then c.productType2 when c.productType2='big inst' then 'Инстоллмент' else  b.[Тип Продукта]  end
order by 1 desc

delete from  report_portfolio_week
insert into report_portfolio_week
select *  
from #report_portfolio_week
 
 