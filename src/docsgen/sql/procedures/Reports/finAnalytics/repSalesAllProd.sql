
CREATE PROCEDURE [finAnalytics].[repSalesAllProd]
	@dateTo date
AS
BEGIN

--t1p1
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 and isnull(b.pAmount,0) != 0 then l1.fAmount / c.[Доля для RR ПТС] / b.pAmount end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 1
,[tabName] = 'Всего продажи'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём продаж, млн р.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where a.spr4 is null
) l1
left join #plan b on upper(b.product)=upper('Всего продажи')
left join #RR c on c.Дата = @dateTo

--t1p2
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 and isnull(b.pAmount,0) != 0 then l1.fAmount / c.[Доля для RR ПТС] / b.pCount end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 1
,[tabName] = 'Всего продажи'
,[pokazatelNum] = 2
,[pokazatel] = 'Количество, шт.'
,[pAmount] = 0
,[fAmount] = count(distinct a.dogNum)

from #PBR a
where a.spr4 is null
) l1
left join #plan b on upper(b.product)=upper('Всего продажи')
left join #RR c on c.Дата = @dateTo

--t1p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pAVGChaeck
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(b.pAVGChaeck,0) !=0 then l1.fAmount /  b.pAVGChaeck end
,[RR] = l1.fAmount 

from(
select
[tabNum] = 1
,[tabName] = 'Всего продажи'
,[pokazatelNum] = 3
,[pokazatel] = 'Средний чек, млн р.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0)) / count(distinct a.dogNum)

from #PBR a
where a.spr4 is null
) l1
left join #plan b on upper(b.product)=upper('Всего продажи')
left join #RR c on c.Дата = @dateTo

--t1p4
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
,[tekPRC] = case when isnull(b.pAVGPRC,0) != 0 then l1.fAmount /  b.pAVGPRC end
,[RR] = l1.fAmount 

from(
select
[tabNum] = 1
,[tabName] = 'Всего продажи'
,[pokazatelNum] = 4
,[pokazatel] = 'Средняя ставка'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100

from #PBR a
where a.spr4 is null
) l1
left join #plan b on upper(b.product)=upper('Всего продажи')
left join #RR c on c.Дата = @dateTo

--t2p1
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
,[tekPRC] = null
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 2
,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач онлайн, млн р.'
,[pAmount] = 0
,[fAmount] = cast(sum(isnull(a.dogSum,0)) as float)

from #PBR a
where a.spr4 is null
and upper(a.saleType) like upper('%онлайн%')
) l1
left join #RR c on c.Дата = @dateTo

--t2p2
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
,[tekPRC] = null
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 2
,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 2
,[pokazatel] = 'Объём выдач офлайн, млн р.'
,[pAmount] = 0
,[fAmount] = cast(sum(isnull(a.dogSum,0)) as float)

from #PBR a
where a.spr4 is null
and upper(a.saleType) like upper('%дистанционный%')
) l1
left join #RR c on c.Дата = @dateTo

--t2p3
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
,[tekPRC] = null
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 2
,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 3
,[pokazatel] = 'Кол-во выдач онлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where a.spr4 is null
and upper(a.saleType) like upper('%онлайн%')
) l1
left join #RR c on c.Дата = @dateTo

--t2p4
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
,[tekPRC] = null
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 2
,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 4
,[pokazatel] = 'Кол-во выдач офлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where a.spr4 is null
and upper(a.saleType) like upper('%дистанционный%')
) l1
left join #RR c on c.Дата = @dateTo

--t2p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(b.fAmount,0) != 0 then l1.fAmount / b.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = case when isnull(b.fAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / b.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 2
,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 5
,[pokazatel] = 'Доля выдач онлайн по объёму, %'
,[pAmount] = 0
,[fAmount] = cast(sum(isnull(a.dogSum,0)) as float)

from #PBR a
where a.spr4 is null
and upper(a.saleType) like upper('%онлайн%')
) l1

left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr4 is null) b on 1=1
left join #RR c on c.Дата = @dateTo

--t2p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(b.fAmount,0) != 0 then l1.fAmount / b.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = case when isnull(b.fAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / b.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 2
,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 6
,[pokazatel] = 'Доля выдач онлайн по кол-ву, %'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where a.spr4 is null
and upper(a.saleType) like upper('%онлайн%')
) l1

left join (select [fAmount] = count(distinct a.dogNum) from #PBR a where a.spr4 is null) b on 1=1
left join #RR c on c.Дата = @dateTo

--t3p1
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
,[tekPRC] = null
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
from(

select
[tabNum] = 3
,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач онлайн, млн р.'
,[pAmount] = 0
,[fAmount] = cast(sum(a.[Сумма]) as float)

from #loans a
where a.[Дистанционная выдача] =1
) l1
left join #RR c on c.Дата = @dateTo

--t3p2
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
,[tekPRC] = null
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
from(

select
[tabNum] = 3
,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 2
,[pokazatel] = 'Объём выдач офлайн, млн р.'
,[pAmount] = 0
,[fAmount] = cast(sum(a.[Сумма]) as float)

from #loans a
where a.[Дистанционная выдача] =0
) l1
left join #RR c on c.Дата = @dateTo

--t3p3
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
,[tekPRC] = null
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
from(

select
[tabNum] = 3
,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 3
,[pokazatel] = 'Кол-во выдач онлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.[код]) as float)

from #loans a
where a.[Дистанционная выдача] =1
) l1
left join #RR c on c.Дата = @dateTo

--t3p4
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
,[tekPRC] = null
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
from(

select
[tabNum] = 3
,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 4
,[pokazatel] = 'Кол-во выдач офлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.[код]) as float)

from #loans a
where a.[Дистанционная выдача] =0
) l1
left join #RR c on c.Дата = @dateTo

--t3p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(b.fAmount,0) != 0 then l1.fAmount / b.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = case when isnull(b.fAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / b.fAmount / c.[Доля для RR ПТС] end

from(

select
[tabNum] = 3
,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 5
,[pokazatel] = 'Доля выдач онлайн по объёму, %'
,[pAmount] = 0
,[fAmount] = cast(sum(a.[Сумма]) as float)

from #loans a
where a.[Дистанционная выдача] =1
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr4 is null) b on 1=1

--t3p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(b.fAmount,0) != 0 then l1.fAmount / b.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = case when isnull(b.fAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / b.fAmount / c.[Доля для RR ПТС] end

from(

select
[tabNum] = 3
,[tabName] = 'Объёмы и количество выдач онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 6
,[pokazatel] = 'Доля выдач онлайн по кол-ву, %'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.[код]) as float)

from #loans a
where a.[Дистанционная выдача] =1
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = count(distinct a.dogNum) from #PBR a where a.spr4 is null) b on 1=1  

--t4p1
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
,[tekPRC] = case when isnull(b.pAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] / b.pAmount end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 4
,[tabName] = 'Объём выдач по ПТС'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач, млн.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
) l1
left join #plan b on upper(b.product)=upper('ПТС')
left join #RR c on c.Дата = @dateTo

--t4p2
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
,[tekPRC] = case when isnull(b.pAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] / b.pAmount end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 4
,[tabName] = 'Объём выдач по ПТС'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('ПТС новые')
left join #RR c on c.Дата = @dateTo

--t4p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = l1.fAmount / (d.fAmount - e.fAmount) * b.pAmount
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / c.[Доля для RR ПТС] / (l1.fAmount / (d.fAmount - e.fAmount) * b.pAmount)
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 4
,[tabName] = 'Объём выдач по ПТС'
,[pokazatelNum] = 3
,[pokazatel] = 'Докреды'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Докреды')
) l1
left join #plan b on upper(b.product)=upper('ПТС докреды/повторники')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('ПТС')) d on 1=1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('ПТС') and upper(a.spr2) = upper('Новые')) e on 1=1

--t4p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = l1.fAmount / (d.fAmount - e.fAmount) * b.pAmount
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / c.[Доля для RR ПТС] / (l1.fAmount / (d.fAmount - e.fAmount) * b.pAmount)
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 4
,[tabName] = 'Объём выдач по ПТС'
,[pokazatelNum] = 4
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('ПТС докреды/повторники')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('ПТС')) d on 1=1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('ПТС') and upper(a.spr2) = upper('Новые')) e on 1=1

--t4p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = l1.fAmount / d.fAmount
,[fAmount] = l1.fAmount / d.fAmount
,[rrDolya] = null
,[tekPRC] = l1.fAmount / d.fAmount
,[RR] = l1.fAmount / d.fAmount

from(
select
[tabNum] = 4
,[tabName] = 'Объём выдач по ПТС'
,[pokazatelNum] = 5
,[pokazatel] = '% Новые'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Новые')
) l1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('ПТС')) d on 1=1


--t4p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = l1.fAmount / d.fAmount
,[fAmount] = l1.fAmount / d.fAmount
,[rrDolya] = null
,[tekPRC] = l1.fAmount / d.fAmount
,[RR] = l1.fAmount / d.fAmount

from(
select
[tabNum] = 4
,[tabName] = 'Объём выдач по ПТС'
,[pokazatelNum] = 6
,[pokazatel] = '% Докреды'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Докреды')
) l1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('ПТС')) d on 1=1

--t4p7
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = l1.fAmount / d.fAmount
,[fAmount] = l1.fAmount / d.fAmount
,[rrDolya] = null
,[tekPRC] = l1.fAmount / d.fAmount
,[RR] = l1.fAmount / d.fAmount

from(
select
[tabNum] = 4
,[tabName] = 'Объём выдач по ПТС'
,[pokazatelNum] = 7
,[pokazatel] = '% Повторники'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Повторники')
) l1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('ПТС')) d on 1=1

--t5p1
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
[tabNum] = 5
,[tabName] = 'Количество выдач по ПТС'
,[pokazatelNum] = 1
,[pokazatel] = 'Количество выдач'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('ПТС')
) l1
left join #plan b on upper(b.product)=upper('ПТС')
left join #RR c on c.Дата = @dateTo

--t5p2
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
[tabNum] = 5
,[tabName] = 'Количество выдач по ПТС'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('ПТС новые')
left join #RR c on c.Дата = @dateTo

--t5p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = l1.fAmount / (d.fAmount - e.fAmount) * b.pCount
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / c.[Доля для RR ПТС] / (l1.fAmount / (d.fAmount - e.fAmount) * b.pCount)
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 5
,[tabName] = 'Количество выдач по ПТС'
,[pokazatelNum] = 3
,[pokazatel] = 'Докреды'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Докреды')
) l1
left join #plan b on upper(b.product)=upper('ПТС докреды/повторники')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС')) d on 1=1
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС') and upper(a.spr2) = upper('Новые')) e on 1=1

--t5p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = l1.fAmount / (d.fAmount - e.fAmount) * b.pCount
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / c.[Доля для RR ПТС] / (l1.fAmount / (d.fAmount - e.fAmount) * b.pCount)
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 5
,[tabName] = 'Количество выдач по ПТС'
,[pokazatelNum] = 4
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('ПТС докреды/повторники')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС')) d on 1=1
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС') and upper(a.spr2) = upper('Новые')) e on 1=1

--t5p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = l1.fAmount / d.fAmount
,[fAmount] = l1.fAmount / d.fAmount
,[rrDolya] = null
,[tekPRC] = l1.fAmount / d.fAmount
,[RR] = l1.fAmount / d.fAmount

from(
select
[tabNum] = 5
,[tabName] = 'Количество выдач по ПТС'
,[pokazatelNum] = 5
,[pokazatel] = '% Новые'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Новые')
) l1
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС')) d on 1=1

--t5p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = l1.fAmount / d.fAmount
,[fAmount] = l1.fAmount / d.fAmount
,[rrDolya] = null
,[tekPRC] = l1.fAmount / d.fAmount
,[RR] = l1.fAmount / d.fAmount

from(
select
[tabNum] = 5
,[tabName] = 'Количество выдач по ПТС'
,[pokazatelNum] = 6
,[pokazatel] = '% Докреды'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Докреды')
) l1
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС')) d on 1=1

--t5p7
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = l1.fAmount / d.fAmount
,[fAmount] = l1.fAmount / d.fAmount
,[rrDolya] = null
,[tekPRC] = l1.fAmount / d.fAmount
,[RR] = l1.fAmount / d.fAmount

from(
select
[tabNum] = 5
,[tabName] = 'Количество выдач по ПТС'
,[pokazatelNum] = 7
,[pokazatel] = '% Повторники'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Повторники')
) l1
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС')) d on 1=1

--t6p1
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
[tabNum] = 6
,[tabName] = 'Средний чек по ПТС'
,[pokazatelNum] = 1
,[pokazatel] = 'Средний чек, тыс.руб.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('ПТС')
) l1
left join #plan b on upper(b.product)=upper('ПТС')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('ПТС')) d on 1=1

--t6p2
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
[tabNum] = 6
,[tabName] = 'Средний чек по ПТС'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('ПТС новые')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('ПТС') and upper(a.spr2) = upper('Новые')) d on 1=1

--t6p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = (
              l1.dolyaAmount / (d.fAmount - e.fAmount) * b.pAmount
              )
              /
              (
              l1.dolyaCount / (d.fCount - e.fCount) * b.pCount
              )
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / c.[Доля для RR ПТС] / (l1.fAmount / (d.fAmount - e.fAmount) * b.pAmount)
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 6
,[tabName] = 'Средний чек по ПТС'
,[pokazatelNum] = 3
,[pokazatel] = 'Докреды'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0)) / cast(count(distinct a.dogNum) as float)
,[dolyaAmount] = sum(isnull(a.dogSum,0))
,[dolyaCount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Докреды')
) l1
left join #plan b on upper(b.product)=upper('ПТС докреды/повторники')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)),[fCount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС')) d on 1=1
left join (select [fAmount] = sum(isnull(a.dogSum,0)),[fCount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС') and upper(a.spr2) = upper('Новые')) e on 1=1

--t6p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = (
              l1.dolyaAmount / (d.fAmount - e.fAmount) * b.pAmount
              )
              /
              (
              l1.dolyaCount / (d.fCount - e.fCount) * b.pCount
              )
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = l1.fAmount / c.[Доля для RR ПТС] / (l1.fAmount / (d.fAmount - e.fAmount) * b.pAmount)
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 6
,[tabName] = 'Средний чек по ПТС'
,[pokazatelNum] = 4
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0)) / cast(count(distinct a.dogNum) as float)
,[dolyaAmount] = sum(isnull(a.dogSum,0))
,[dolyaCount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('ПТС докреды/повторники')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)),[fCount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС')) d on 1=1
left join (select [fAmount] = sum(isnull(a.dogSum,0)),[fCount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС') and upper(a.spr2) = upper('Новые')) e on 1=1

--t7p1
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
[tabNum] = 7
,[tabName] = 'Средние ставки по ПТС'
,[pokazatelNum] = 1
,[pokazatel] = 'Средняя ставка'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100

from #PBR a
where upper(a.spr1) = upper('ПТС')
) l1
left join #plan b on upper(b.product)=upper('ПТС')
left join #RR c on c.Дата = @dateTo

--t7p2
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
[tabNum] = 7
,[tabName] = 'Средние ставки по ПТС'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('ПТС новые')
left join #RR c on c.Дата = @dateTo

--t7p3
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
[tabNum] = 7
,[tabName] = 'Средние ставки по ПТС'
,[pokazatelNum] = 3
,[pokazatel] = 'Докреды'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Докреды')
) l1
left join #plan b on upper(b.product)=upper('ПТС докреды/повторники')
left join #RR c on c.Дата = @dateTo

--t7p4
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
[tabNum] = 7
,[tabName] = 'Средние ставки по ПТС'
,[pokazatelNum] = 4
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('ПТС докреды/повторники')
left join #RR c on c.Дата = @dateTo

--t7p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount 

from(
select
[tabNum] = 7
,[tabName] = 'Средние ставки по ПТС'
,[pokazatelNum] = 5
,[pokazatel] = 'Ставка по займам без КП, снижающих ставку'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100

from #PBR a
left join #loans d on a.dogNum=d.код

where upper(a.spr1) = upper('ПТС')
--and upper(a.spr2) = upper('Повторники')
and d.[Сумма комиссионных продуктов снижающих ставку]=0
) l1
left join #RR c on c.Дата = @dateTo

--t7p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount 

from(
select
[tabNum] = 7
,[tabName] = 'Средние ставки по ПТС'
,[pokazatelNum] = 6
,[pokazatel] = 'Ставка по займам с КП, снижающими ставку'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100

from #PBR a
left join #loans d on a.dogNum=d.код

where upper(a.spr1) = upper('ПТС')
--and upper(a.spr2) = upper('Повторники')
and d.[Сумма комиссионных продуктов снижающих ставку]>0
) l1
left join #RR c on c.Дата = @dateTo

--t8p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 8
,[tabName] = 'Объёмы выдач по ПТС по срокам и средневзв. сроки'
,[pokazatelNum] = 1
,[pokazatel] = '24 месяца'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
and a.dogPeriodMonth=24
) l1
left join #RR c on c.Дата = @dateTo

--t8p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 8
,[tabName] = 'Объёмы выдач по ПТС по срокам и средневзв. сроки'
,[pokazatelNum] = 2
,[pokazatel] = '36 месяцев'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
and a.dogPeriodMonth=36
) l1
left join #RR c on c.Дата = @dateTo

--t8p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 8
,[tabName] = 'Объёмы выдач по ПТС по срокам и средневзв. сроки'
,[pokazatelNum] = 3
,[pokazatel] = '48 месяцев'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
and a.dogPeriodMonth=48
) l1
left join #RR c on c.Дата = @dateTo

--t8p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = null
,[tekPRC] = null
,[RR] = l1.fAmount 

from(
select
[tabNum] = 8
,[tabName] = 'Объёмы выдач по ПТС по срокам и средневзв. сроки'
,[pokazatelNum] = 4
,[pokazatel] = 'Средневзвешенный срок, мес.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.dogPeriodMonth) / sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
) l1

--t8p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = null
,[tekPRC] = null
,[RR] = l1.fAmount 

from(
select
[tabNum] = 8
,[tabName] = 'Объёмы выдач по ПТС по срокам и средневзв. сроки'
,[pokazatelNum] = 5
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.dogPeriodMonth) / sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
and  upper(a.spr2) = upper('Новые')
) l1

--t8p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = null
,[tekPRC] = null
,[RR] = l1.fAmount 

from(
select
[tabNum] = 8
,[tabName] = 'Объёмы выдач по ПТС по срокам и средневзв. сроки'
,[pokazatelNum] = 6
,[pokazatel] = 'Докреды'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.dogPeriodMonth) / sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
and  upper(a.spr2) = upper('Докреды')
) l1

--t8p7
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = null
,[tekPRC] = null
,[RR] = l1.fAmount 

from(
select
[tabNum] = 8
,[tabName] = 'Объёмы выдач по ПТС по срокам и средневзв. сроки'
,[pokazatelNum] = 7
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.dogPeriodMonth) / sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
and  upper(a.spr2) = upper('Повторники')
) l1

--t9p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 9
,[tabName] = 'Объёмы и количество выдач по ПТС онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач онлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo

--t9p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 9
,[tabName] = 'Объёмы и количество выдач по ПТС онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 2
,[pokazatel] = 'Объём выдач офлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.saleType) = upper('дистанционный')
) l1
left join #RR c on c.Дата = @dateTo

--t9p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 9
,[tabName] = 'Объёмы и количество выдач по ПТС онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 3
,[pokazatel] = 'Кол-во выдач онлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo

--t9p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 9
,[tabName] = 'Объёмы и количество выдач по ПТС онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 4
,[pokazatel] = 'Кол-во выдач офлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.saleType) = upper('дистанционный')
) l1
left join #RR c on c.Дата = @dateTo

--t9p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount / b.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount / b.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 9
,[tabName] = 'Объёмы и количество выдач по ПТС онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 5
,[pokazatel] = 'Доля выдач онлайн по объёму, %'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('ПТС')) b on 1=1

--t9p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount / b.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount / b.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 9
,[tabName] = 'Объёмы и количество выдач по ПТС онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 6
,[pokazatel] = 'Доля выдач онлайн по кол-ву, %'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('ПТС')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС')) b on 1=1

--t10p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 10
,[tabName] = 'Объёмы и количество выдач по ПТС онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач онлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(a.[Сумма])

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('ПТС')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo

--t10p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 10
,[tabName] = 'Объёмы и количество выдач по ПТС онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 2
,[pokazatel] = 'Объём выдач офлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(a.[Сумма])

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('ПТС')
and upper(a.[Дистанционная выдача]) = 0
) l1
left join #RR c on c.Дата = @dateTo

--t10p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 10
,[tabName] = 'Объёмы и количество выдач по ПТС онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 3
,[pokazatel] = 'Кол-во выдач онлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.код) as float) 

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('ПТС')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo

--t10p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 10
,[tabName] = 'Объёмы и количество выдач по ПТС онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 4
,[pokazatel] = 'Кол-во выдач офлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.код) as float) 

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('ПТС')
and upper(a.[Дистанционная выдача]) = 0
) l1
left join #RR c on c.Дата = @dateTo

--t10p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount / b.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount / b.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 10
,[tabName] = 'Объёмы и количество выдач по ПТС онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 5
,[pokazatel] = 'Доля выдач онлайн по объёму, %'
,[pAmount] = 0
,[fAmount] = sum(a.[Сумма])

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('ПТС')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(a.[Сумма]) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('ПТС')) b on 1=1

--t10p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = l1.fAmount / b.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = l1.fAmount / b.fAmount / c.[Доля для RR ПТС]

from(
select
[tabNum] = 10
,[tabName] = 'Объёмы и количество выдач по ПТС онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 6
,[pokazatel] = 'Доля выдач онлайн по кол-ву, %'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.код) as float) 

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('ПТС')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct a.код) as float) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('ПТС')) b on 1=1


end