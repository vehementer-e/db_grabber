



CREATE PROCEDURE [finAnalytics].[repComm]
	@repmonthFrom date,
	@repmonthTo date

AS
BEGIN


DROP TABLE IF EXISTS #rm

select
distinct
repmonth

into #rm
from(
Select
distinct repmonth
from dwh2.finAnalytics.commAll
union all
Select
distinct repmonth
from dwh2.finAnalytics.commPs
) l1

where l1.repmonth between @repmonthFrom and @repmonthTo

--select * from #rm

DROP TABLE IF EXISTS #rep

CREATE TABLE #rep (
repmonth date not null,
rowNum int not null,
rowName varchar(20) null,
isBold int not null,
isGray int not null,
pokazatel varchar(300) null,
commAmount money null
)

/*Создание скелета отчета*/

INSERT INTO #rep
select 
[repmonth] = a.repmonth
,[rowNum] = b.rowNum
,[rowName] = b.rowName
,[isBold] = b.isBold
,[isGrey] = b.isGrey
,[pokazatel] = b.pokazatel
,[commAmount] = null
from #rm a, DWH2.finanalytics.SPR_comm_all b

--p400   КП при выдаче
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where commType='КП при выдаче'
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 400)
when matched then update
set t1.[commAmount] = t2.platAmount;


--p500      КарМани. Снижение % и финпомощь
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where 
commType='КП при выдаче'
and platType='КарМани. Снижение % и финпомощь'
and isPSK='ПСК'
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 500)
when matched then update
set t1.[commAmount] = t2.platAmount;


--p600     Включаемые в ПСК
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where 
commType='КП при выдаче'
and platType in ('Каско (1%)','НС (0,5%)','Потеря работы (3-й пакет "Спокойная жизнь")','Страхование квартиры (3-й пакет "Спокойная жизнь")','Телемедицина (3-й пакет "Спокойная жизнь")')
and isPSK='ПСК'
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 600)
when matched then update
set t1.[commAmount] = t2.platAmount;


--p700     Страхование заемщиков (расходы)
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where 
commType='КП при выдаче'
and platType in ('Страхование заемщиков (расходы)')
--and isPSK='ПСК'
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 700)
when matched then update
set t1.[commAmount] = t2.platAmount;


--p800     Не включаемые в ПСК (коробки)
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where 
commType='КП при выдаче'
and platType in ('Прочие (коробки)')
--and isPSK='ПСК'
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 800)
when matched then update
set t1.[commAmount] = t2.platAmount;


--p900  Другие КП
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where commType='Другие КП'
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 900)
when matched then update
set t1.[commAmount] = t2.platAmount;


--p1000      СМС-информирование  о залоге
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where 
commType='Другие КП'
and platType in ('СМС-информирование  о залоге')
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 1000)
when matched then update
set t1.[commAmount] = t2.platAmount;


--p1100     Cрочное снятие залога
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where 
commType='Другие КП'
and platType in ('Cрочное снятие залога')
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 1100)
when matched then update
set t1.[commAmount] = t2.platAmount;


--p1200      Снятие запрета с автомобиля
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where 
commType='Другие КП'
and platType in ('Снятие запрета с автомобиля')
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 1200)
when matched then update
set t1.[commAmount] = t2.platAmount;

--p1300      Возмещения по договору залога
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where 
commType='Другие КП'
and platType in ('Возмещения по договору залога')
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 1300)
when matched then update
set t1.[commAmount] = t2.platAmount;

--p1400      Комиссии за справки
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where 
commType='Другие КП'
and platType in ('Комиссии за справки')
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 1400)
when matched then update
set t1.[commAmount] = t2.platAmount;

--p1500      Оценка рыночной стоимости авто
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where 
commType='Другие КП'
and platType in ('Оценка рыночной стоимости авто')
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 1500)
when matched then update
set t1.[commAmount] = t2.platAmount;

--p1510           Возмещение расходов по договору залога (возврат ТС)
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where 
commType='Другие КП'
and platType in ('Возмещение расходов по договору залога (возврат ТС)')
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 1510)
when matched then update
set t1.[commAmount] = t2.platAmount;

--p1520 Вознаграждение по партнерским договорам с ЮЛ
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where 
commType='Другие КП'
and platType in ('Вознаграждение по партнерским договорам с ЮЛ')
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 1520)
when matched then update
set t1.[commAmount] = t2.platAmount;

--p1600 Возврат при отказе от услуг (расходы)
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where commType='Возвраты'
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 1600)
when matched then update
set t1.[commAmount] = t2.platAmount;


--p1800  EcommPay (доходы)
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(case when rowName = '13' then platAmount * -1 else platAmount end)
from dwh2.finAnalytics.commPS
where rowName in ('17','13')--platSys='EcommPay (доходы)'
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 1800)
when matched then update
set t1.[commAmount] = t2.platAmount;


--p2000      по выдаче займов
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commPS
where platSys in ('БРС','Cloud paymemts (Тинькоф)','EcommPay','CONTACT','СБП')
and platType='по выдаче займов'
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 2000)
when matched then update
set t1.[commAmount] = t2.platAmount;


--p2100      по возврату займов
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commPS
where platSys in ('CONTACT','Биллинговый центр')
and platType='по возврату займов'
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 2100)
when matched then update
set t1.[commAmount] = t2.platAmount;


--p2200      другие услуги
merge into #rep t1
using(
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commPS
where rowName in ('5.3','8')--platSys in ('CONTACT') and platType='другие услуги'
group by repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 2200)
when matched then update
set t1.[commAmount] = t2.platAmount;


--p2300 Корректировки / балансировки
merge into #rep t1
using(
select 
a.repmonth
,rowNum = 2300
,rowName = 'Корректировки / балансировки'
,commAmount = s1.platAmount 
			+ s2.platAmount 
			
from #rm a

left join (
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commPS
where rowName in ('12','13','13.1')--platSys='Корректировки / балансировки'
group by repmonth
) s1 on a.repmonth=s1.repmonth

left join (
select
repmonth
,platAmount = SUM(platAmount)
from dwh2.finAnalytics.commAll
where commType='Корректировки / балансировки'
group by repmonth
) s2 on a.repmonth=s2.repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 2300)
when matched then update
set t1.[commAmount] = t2.commAmount;

--p300 Комиссионные продукты
merge into #rep t1
using(
select 
a.repmonth
,rowNum = 300
,rowName = 'Комиссионные продукты'
,commAmount = SUM(commAmount)
			
from #rm a
left join #rep b on a.repmonth=b.repmonth
where b.rowName in ('2.1','2.2')
group by a.repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 300)
when matched then update
set t1.[commAmount] = t2.commAmount;


--p1900   Услуги платежных систем по выдаче и возврату займов
merge into #rep t1
using(
select 
a.repmonth
,rowNum = 1900
,rowName = 'Услуги платежных систем по выдаче и возврату займов'
,commAmount = SUM(commAmount)
			
from #rm a
left join #rep b on a.repmonth=b.repmonth
where b.rowName in ('4.2.1','4.2.2','4.2.3')
group by a.repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 1900)
when matched then update
set t1.[commAmount] = t2.commAmount;

--p1700 Комиссии ПС по выдаче и возврату займов
merge into #rep t1
using(
select 
a.repmonth
,rowNum = 1700
,rowName = 'Комиссии ПС по выдаче и возврату займов'
,commAmount = SUM(commAmount)
			
from #rm a
left join #rep b on a.repmonth=b.repmonth
where b.rowName in ('4.1','4.2')
group by a.repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 1700)
when matched then update
set t1.[commAmount] = t2.commAmount;

----p2
--INSERT INTO #rep
--select 
--a.repmonth
--,rowNum = 2
--,rowName = 'в том числе:'
--,commAmount = null
--from #rm a


--p100 Комиссии + аутсорс КЦ
merge into #rep t1
using(
select 
a.repmonth
,rowNum = 1
,rowName = 'Комиссии + аутсорс КЦ'
,commAmount = SUM(commAmount)
			
from #rm a
left join #rep b on a.repmonth=b.repmonth
where b.rowName in ('2','3','4','5')
group by a.repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 100)
when matched then update
set t1.[commAmount] = t2.commAmount;

----p21
--INSERT INTO #rep
--select 
--a.repmonth
--,rowNum = 21
--,rowName = 'Проверка (в руб.)'
--,commAmount = null
--from #rm a

--p2500 КП при выдаче
merge into #rep t1
using(
select 
a.repmonth
,rowNum = 2500
,rowName = 'Проверка КП при выдаче'
,commAmount = SUM(
				case when b.rowName in ('2.1.1','2.1.2','2.1.3','2.1.4') then commAmount*-1 else commAmount end
				)
			
from #rm a
left join #rep b on a.repmonth=b.repmonth
where b.rowName in ('2.1','2.1.1','2.1.2','2.1.3','2.1.4')
group by a.repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 2500)
when matched then update
set t1.[commAmount] = t2.commAmount;

--p2600 Другие КП
merge into #rep t1
using(
select 
a.repmonth
,rowNum = 2600
,rowName = 'Другие КП'
,commAmount = SUM(
				case when b.rowName in ('2.2.1','2.2.2','2.2.3','2.2.4','2.2.5','2.2.6','2.2.7','2.2.8') then commAmount*-1 else commAmount end
				)
			
from #rm a
left join #rep b on a.repmonth=b.repmonth
where b.rowName in ('2.2','2.2.1','2.2.2','2.2.3','2.2.4','2.2.5','2.2.6','2.2.7','2.2.8')
group by a.repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 2600)
when matched then update
set t1.[commAmount] = t2.commAmount;

--p2700 НДС (разница между тем, что нам платят клиенты (за вычетом НДС) и мы платим СК,  должна составлять сумму НДС)
merge into #rep t1
using(
select 
a.repmonth
,rowNum = 2700
,rowName = 'НДС (разница между тем, что нам платят клиенты (за вычетом НДС) и мы платим СК,  должна составлять сумму НДС)'
,commAmount = SUM(commAmount)
			/
			  SUM(
				case when b.rowName in ('2.1.2') then commAmount else 0 end
				)
			
from #rm a
left join #rep b on a.repmonth=b.repmonth
where b.rowName in ('2.1.2','2.1.3')
group by a.repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 2700)
when matched then update
set t1.[commAmount] = t2.commAmount;


--p2800 Услуги платежных систем по выдаче и возврату займов
merge into #rep t1
using(
select 
a.repmonth
,rowNum = 2800
,rowName = 'Услуги платежных систем по выдаче и возврату займов'
,commAmount = SUM(
				case when b.rowName in ('4.2.1','4.2.2','4.2.3') then commAmount*-1 else commAmount end
				)
			
from #rm a
left join #rep b on a.repmonth=b.repmonth
where b.rowName in ('4.2','4.2.1','4.2.2','4.2.3')
group by a.repmonth
) t2 on (t1.repmonth=t2.repmonth and t1.rowNum = 2800)
when matched then update
set t1.[commAmount] = t2.commAmount;

select * from #rep --order by repmonth, rowNum
  
END
