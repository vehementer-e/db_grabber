

CREATE PROCEDURE [finAnalytics].[repSalesILProd]
	@dateTo date
AS
BEGIN

--t11p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pAmount
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / c.[Доля для RR ПТС] / b.pAmount
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 11
,[tabName] = 'Объём выдач Installment'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач, млн.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Installment')
) l1
left join #plan b on upper(b.product)=upper('IL')
left join #RR c on c.Дата = @dateTo

--t11p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pAmount
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / c.[Доля для RR ПТС] / b.pAmount
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 11
,[tabName] = 'Объём выдач Installment'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('IL новые')
left join #RR c on c.Дата = @dateTo

--t11p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pAmount
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / c.[Доля для RR ПТС] / b.pAmount
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 11
,[tabName] = 'Объём выдач Installment'
,[pokazatelNum] = 3
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('IL повторники')
left join #RR c on c.Дата = @dateTo

--t11p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = l1.fAmount / d.fAmount
,[fAmount] = l1.fAmount / d.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / d.fAmount 
,[RR] = l1.fAmount / d.fAmount 

from(
select
[tabNum] = 11
,[tabName] = 'Объём выдач Installment'
,[pokazatelNum] = 4
,[pokazatel] = '% Новые'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('IL новые')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Installment')) d on 1=1

--t11p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = l1.fAmount / d.fAmount
,[fAmount] = l1.fAmount / d.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / d.fAmount
,[RR] = l1.fAmount / d.fAmount

from(
select
[tabNum] = 11
,[tabName] = 'Объём выдач Installment'
,[pokazatelNum] = 5
,[pokazatel] = '% Повторники'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('IL повторники')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Installment')) d on 1=1

--t12p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pCount
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / c.[Доля для RR ПТС] / b.pCount
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 12
,[tabName] = 'Количество выдач Installment'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач, млн.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Installment')
) l1
left join #plan b on upper(b.product)=upper('IL')
left join #RR c on c.Дата = @dateTo

--t12p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pCount
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / c.[Доля для RR ПТС] / b.pCount
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 12
,[tabName] = 'Количество выдач Installment'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('IL новые')
left join #RR c on c.Дата = @dateTo

--t12p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pCount
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / c.[Доля для RR ПТС] / b.pCount
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 12
,[tabName] = 'Количество выдач Installment'
,[pokazatelNum] = 3
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('IL повторники')
left join #RR c on c.Дата = @dateTo

--t12p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = l1.fAmount / d.fAmount
,[fAmount] = l1.fAmount / d.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / d.fAmount 
,[RR] = l1.fAmount / d.fAmount 

from(
select
[tabNum] = 12
,[tabName] = 'Количество выдач Installment'
,[pokazatelNum] = 4
,[pokazatel] = '% Новые'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('IL новые')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('Installment')) d on 1=1

--t12p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = l1.fAmount / d.fAmount
,[fAmount] = l1.fAmount / d.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / d.fAmount
,[RR] = l1.fAmount / d.fAmount

from(
select
[tabNum] = 12
,[tabName] = 'Количество выдач Installment'
,[pokazatelNum] = 5
,[pokazatel] = '% Повторники'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('IL повторники')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('Installment')) d on 1=1

--t13p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pAVGChaeck
,[fAmount] = d.fAmount / l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = d.fAmount / l1.fAmount / b.pAVGChaeck
,[RR] = d.fAmount / l1.fAmount

from(
select
[tabNum] = 13
,[tabName] = 'Средний чек по Installment'
,[pokazatelNum] = 1
,[pokazatel] = 'Средний чек, тыс.руб.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Installment')
) l1
left join #plan b on upper(b.product)=upper('IL')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Installment')) d on 1=1

--t13p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pAVGChaeck
,[fAmount] = d.fAmount / l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = d.fAmount / l1.fAmount / b.pAVGChaeck
,[RR] = d.fAmount / l1.fAmount

from(
select
[tabNum] = 13
,[tabName] = 'Средний чек по Installment'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('IL новые')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Installment') and upper(a.spr2) = upper('Новые')) d on 1=1

--t13p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pAVGChaeck
,[fAmount] = d.fAmount / l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = d.fAmount / l1.fAmount / b.pAVGChaeck
,[RR] = d.fAmount / l1.fAmount

from(
select
[tabNum] = 13
,[tabName] = 'Средний чек по Installment'
,[pokazatelNum] = 3
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('IL повторники')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Installment') and upper(a.spr2) = upper('Повторники')) d on 1=1

--t14p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pAVGPRC
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / b.pAVGPRC
,[RR] = l1.fAmount

from(
select
[tabNum] = 14
,[tabName] = 'Средние ставки по Installment'
,[pokazatelNum] = 1
,[pokazatel] = 'Средняя ставка'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100

from #PBR a
where upper(a.spr1) = upper('Installment')
) l1
left join #plan b on upper(b.product)=upper('IL')
left join #RR c on c.Дата = @dateTo

--t14p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pAVGPRC
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / b.pAVGPRC
,[RR] = l1.fAmount

from(
select
[tabNum] = 14
,[tabName] = 'Средние ставки по Installment'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('IL новые')
left join #RR c on c.Дата = @dateTo

--t14p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pAVGPRC
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / b.pAVGPRC
,[RR] = l1.fAmount

from(
select
[tabNum] = 14
,[tabName] = 'Средние ставки по Installment'
,[pokazatelNum] = 3
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('IL повторники')
left join #RR c on c.Дата = @dateTo

--t15p1
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
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 15
,[tabName] = 'Объёмы выдач по Installment по срокам и средневзв. сроки'
,[pokazatelNum] = 1
,[pokazatel] = '3 месяца'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Installment')
and a.dogPeriodMonth = 3
) l1
left join #RR c on c.Дата = @dateTo

--t15p2
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
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 15
,[tabName] = 'Объёмы выдач по Installment по срокам и средневзв. сроки'
,[pokazatelNum] = 2
,[pokazatel] = '6 месяцев'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Installment')
and a.dogPeriodMonth = 6
) l1
left join #RR c on c.Дата = @dateTo

--t15p3
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
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 15
,[tabName] = 'Объёмы выдач по Installment по срокам и средневзв. сроки'
,[pokazatelNum] = 3
,[pokazatel] = '9 месяцев'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Installment')
and a.dogPeriodMonth = 9
) l1
left join #RR c on c.Дата = @dateTo

--t15p4
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
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 15
,[tabName] = 'Объёмы выдач по Installment по срокам и средневзв. сроки'
,[pokazatelNum] = 4
,[pokazatel] = '12 месяцев'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Installment')
and a.dogPeriodMonth = 12
) l1
left join #RR c on c.Дата = @dateTo

--t15p5
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
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 15
,[tabName] = 'Объёмы выдач по Installment по срокам и средневзв. сроки'
,[pokazatelNum] = 5
,[pokazatel] = 'Средневзвешенный срок, мес.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.dogPeriodMonth) / sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Installment')
) l1
left join #RR c on c.Дата = @dateTo

--t15p6
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
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 15
,[tabName] = 'Объёмы выдач по Installment по срокам и средневзв. сроки'
,[pokazatelNum] = 6
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.dogPeriodMonth) / sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.spr2) = upper('Новые')
) l1
left join #RR c on c.Дата = @dateTo

--t15p7
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
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 15
,[tabName] = 'Объёмы выдач по Installment по срокам и средневзв. сроки'
,[pokazatelNum] = 7
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.dogPeriodMonth) / sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.spr2) = upper('Повторники')
) l1
left join #RR c on c.Дата = @dateTo

--t16p1
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
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 16
,[tabName] = 'Объёмы и количество выдач по IL онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач онлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo

--t16p2
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
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 16
,[tabName] = 'Объёмы и количество выдач по IL онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 2
,[pokazatel] = 'Объём выдач офлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.saleType) = upper('дистанционный')
) l1
left join #RR c on c.Дата = @dateTo

--t16p3
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
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 16
,[tabName] = 'Объёмы и количество выдач по IL онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 3
,[pokazatel] = 'Кол-во выдач онлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo

--t16p4
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
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 16
,[tabName] = 'Объёмы и количество выдач по IL онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 4
,[pokazatel] = 'Кол-во выдач офлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.saleType) = upper('дистанционный')
) l1
left join #RR c on c.Дата = @dateTo

--t16p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = l1.fAmount / b.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = l1.fAmount / b.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 16
,[tabName] = 'Объёмы и количество выдач по IL онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 5
,[pokazatel] = 'Доля выдач онлайн по объёму, %'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Installment')) b on 1=1

--t16p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = l1.fAmount / b.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = l1.fAmount / b.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 16
,[tabName] = 'Объёмы и количество выдач по IL онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 6
,[pokazatel] = 'Доля выдач онлайн по кол-ву, %'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Installment')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('Installment')) b on 1=1

--t17p1
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
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 17
,[tabName] = 'Объёмы и количество выдач по IL онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач онлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.Сумма,0))

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('Installment')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo

--t17p2
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
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 17
,[tabName] = 'Объёмы и количество выдач по IL онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 2
,[pokazatel] = 'Объём выдач офлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.Сумма,0))

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('Installment')
and upper(a.[Дистанционная выдача]) = 0
) l1
left join #RR c on c.Дата = @dateTo

--t17p3
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
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 17
,[tabName] = 'Объёмы и количество выдач по IL онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 3
,[pokazatel] = 'Кол-во выдач онлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.код) as float)

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('Installment')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo

--t17p4
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
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 17
,[tabName] = 'Объёмы и количество выдач по IL онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 4
,[pokazatel] = 'Кол-во выдач офлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.код) as float)

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('Installment')
and upper(a.[Дистанционная выдача]) = 0
) l1
left join #RR c on c.Дата = @dateTo

--t17p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = l1.fAmount / b.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = l1.fAmount / b.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 17
,[tabName] = 'Объёмы и количество выдач по IL онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 5
,[pokazatel] = 'Доля выдач онлайн по объёму, %'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.Сумма,0))

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('Installment')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.Сумма,0)) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('Installment')) b on 1=1

--t17p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = l1.fAmount / b.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = l1.fAmount / b.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 17
,[tabName] = 'Объёмы и количество выдач по IL онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 6
,[pokazatel] = 'Доля выдач онлайн по кол-ву, %'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.код) as float)

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('Installment')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct a.код) as float) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('Installment')) b on 1=1

end
