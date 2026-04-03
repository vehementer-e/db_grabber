



CREATE PROCEDURE [finAnalytics].[repSalesBZProd]
	@dateTo date
	--,@monthFrom date
AS
BEGIN

--t26p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 26
,[tabName] = 'Данные по Бизнес-займам'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач, млн.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Бизнес-займ')
) l1
left join #RR c on c.Дата = @dateTo

--t26p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 26
,[tabName] = 'Данные по Бизнес-займам'
,[pokazatelNum] = 2
,[pokazatel] = 'Количество выдач'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr1) = upper('Бизнес-займ')
) l1
left join #RR c on c.Дата = @dateTo

--t26p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0) != 0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = case when isnull(c1.fAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c1.fAmount  / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 26
,[tabName] = 'Данные по Бизнес-займам'
,[pokazatelNum] = 3
,[pokazatel] = 'Средний чек, тыс.руб.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Бизнес-займ')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr1) = upper('Бизнес-займ')) c1 on 1=1

--t26p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0) != 0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = case when isnull(c1.fAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c1.fAmount  / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 26
,[tabName] = 'Данные по Бизнес-займам'
,[pokazatelNum] = 4
,[pokazatel] = 'Средняя ставка'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) /100

from #PBR a
where upper(a.spr1) = upper('Бизнес-займ')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Бизнес-займ')) c1 on 1=1

--t26p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0) != 0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = case when isnull(c1.fAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c1.fAmount  / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 26
,[tabName] = 'Данные по Бизнес-займам'
,[pokazatelNum] = 5
,[pokazatel] = 'Средневзвешенный срок, мес.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.dogPeriodMonth,0))

from #PBR a
where upper(a.spr1) = upper('Бизнес-займ')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Бизнес-займ')) c1 on 1=1


end
