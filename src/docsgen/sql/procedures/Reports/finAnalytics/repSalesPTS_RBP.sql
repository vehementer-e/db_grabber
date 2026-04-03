



CREATE PROCEDURE [finAnalytics].[repSalesPTS_RBP]
	@dateTo date
	--,@monthFrom date
AS
BEGIN

--t27p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = isnull(b.pAmount,0)
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(b.pAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] / b.pAmount end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 27
,[tabName] = 'Объём'
,[pokazatelNum] = 1
,[pokazatel] = 'RBP - 40'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 40') and upper(a.spr1) = upper('ПТС')
) l1
left join #plan b on upper(b.product)=upper('RBP - 40')
left join #RR c on c.Дата = @dateTo

--t27p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = isnull(b.pAmount,0)
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(b.pAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] / b.pAmount end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 27
,[tabName] = 'Объём'
,[pokazatelNum] = 2
,[pokazatel] = 'RBP - 56'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 56') and upper(a.spr1) = upper('ПТС')
) l1
left join #plan b on upper(b.product)=upper('RBP - 56')
left join #RR c on c.Дата = @dateTo

--t27p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = isnull(b.pAmount,0)
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(b.pAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] / b.pAmount end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 27
,[tabName] = 'Объём'
,[pokazatelNum] = 3
,[pokazatel] = 'RBP - 66'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 66') and upper(a.spr1) = upper('ПТС')
) l1
left join #plan b on upper(b.product)=upper('RBP - 66')
left join #RR c on c.Дата = @dateTo

--t27p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = isnull(b.pAmount,0)
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(b.pAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then   l1.fAmount / c.[Доля для RR ПТС] / b.pAmount end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 27
,[tabName] = 'Объём'
,[pokazatelNum] = 4
,[pokazatel] = 'RBP - 86'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 86') and upper(a.spr1) = upper('ПТС')
) l1
left join #plan b on upper(b.product)=upper('RBP - 86')
left join #RR c on c.Дата = @dateTo

--t27p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = 0
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС]  end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 27
,[tabName] = 'Объём'
,[pokazatelNum] = 5
,[pokazatel] = 'non - RBP'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('non - RBP') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo

--t27p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = isnull(b.pAmount,0)
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(b.pAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] / b.pAmount end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 27
,[tabName] = 'Объём'
,[pokazatelNum] = 6
,[pokazatel] = 'Исп. срок'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('Исп. срок') and upper(a.spr1) = upper('ПТС')
) l1
left join #plan b on upper(b.product)=upper('Исп.срок')
left join #RR c on c.Дата = @dateTo

--t27p7
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = 0
,[fAmount] = l1.fAmount
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС]  end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 27
,[tabName] = 'Объём'
,[pokazatelNum] = 7
,[pokazatel] = 'Рефинансирование'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('Рефинанс.') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo

--t27p8
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 and b.pAmount !=0 then l1.fAmount / b.pAmount /  c.[Доля для RR ПТС]  end
,[RR] =case when isnull(c.[Доля для RR ПТС],0) != 0 and b.pAmount !=0 then  l1.fAmount / b.pAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 27
,[tabName] = 'Объём'
,[pokazatelNum] = 8
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) is not null and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (
select pAmount = isnull(SUM(isnull(pAmount,0)),0) from #plan b where upper(b.product) in 
						 (
						 upper('RBP - 40'),
						 upper('RBP - 56'),
						 upper('RBP - 66'),
						 upper('RBP - 86'),
						 upper('non - RBP'),
						 upper('Исп. срок'),
						 upper('Рефинансирование')
						 )
) b on 1=1

--t28p1
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
,[tekPRC] = NULL--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 28
,[tabName] = 'Количество'
,[pokazatelNum] = 1
,[pokazatel] = 'RBP - 40'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) = upper('RBP - 40') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo

--t28p2
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
,[tekPRC] = NULL--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 28
,[tabName] = 'Количество'
,[pokazatelNum] = 2
,[pokazatel] = 'RBP - 56'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) = upper('RBP - 56') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo

--t28p3
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
,[tekPRC] = NULL--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 28
,[tabName] = 'Количество'
,[pokazatelNum] = 3
,[pokazatel] = 'RBP - 66'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) = upper('RBP - 66') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo

--t28p4
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
,[tekPRC] = NULL--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 28
,[tabName] = 'Количество'
,[pokazatelNum] = 4
,[pokazatel] = 'RBP - 86'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) = upper('RBP - 86') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo

--t28p5
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
,[tekPRC] = NULL--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 28
,[tabName] = 'Количество'
,[pokazatelNum] = 5
,[pokazatel] = 'non - RBP'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) = upper('non - RBP') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo

--t28p6
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
,[tekPRC] = NULL--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 28
,[tabName] = 'Количество'
,[pokazatelNum] = 6
,[pokazatel] = 'Исп. срок'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) = upper('Исп. срок') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo

--t28p7
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
,[tekPRC] = NULL--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 28
,[tabName] = 'Количество'
,[pokazatelNum] = 7
,[pokazatel] = 'Рефинансирование'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) = upper('Рефинанс.') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo

--t28p8
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
,[tekPRC] =NULL--case when isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС]  end 
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 28
,[tabName] = 'Количество'
,[pokazatelNum] = 8
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) is not null and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo

--t29p1
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
,[RR] = NULL

from(
select
[tabNum] = 29
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 1
,[pokazatel] = 'RBP - 40'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 40') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t29p2
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
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 29
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 2
,[pokazatel] = 'RBP - 56'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 56') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t29p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = case when isnull(c1.fAmount,0) != 0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 29
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 3
,[pokazatel] = 'RBP - 66'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 66') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t29p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null 
,[fAmount] = case when isnull(c1.fAmount,0) != 0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 29
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 4
,[pokazatel] = 'RBP - 86'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 86') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t29p5
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
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 29
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 5
,[pokazatel] = 'non - RBP'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('non - RBP') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t29p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = case when isnull(c1.fAmount,0) != 0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 29
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 6
,[pokazatel] = 'Исп. срок'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('Исп. срок') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t29p7
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
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 29
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 7
,[pokazatel] = 'Рефинансирование'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('Рефинанс.') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t29p8
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
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 29
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 8
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) is not null and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t30p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 30
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 1
,[pokazatel] = 'RBP - 40'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 40') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr3) = upper('RBP - 40') and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t30p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 30
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 2
,[pokazatel] = 'RBP - 56'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 56') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr3) = upper('RBP - 56') and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t30p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 30
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 3
,[pokazatel] = 'RBP - 66'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 66') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr3) = upper('RBP - 66') and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t30p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null 
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 30
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 4
,[pokazatel] = 'RBP - 86'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 86') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr3) = upper('RBP - 86') and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t30p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 30
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 5
,[pokazatel] = 'non - RBP'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('non - RBP') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr3) = upper('non - RBP') and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t30p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 30
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 6
,[pokazatel] = 'Исп. срок'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('Исп. срок') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr3) = upper('Исп. срок') and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t30p7
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 30
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 7
,[pokazatel] = 'Рефинансирование'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('Рефинанс.') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr3) = upper('Рефинанс.') and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t30p8
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 30
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 8
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) is not null and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t31p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 31
,[tabName] = 'Ставка'
,[pokazatelNum] = 1
,[pokazatel] = 'RBP - 40'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) = upper('RBP - 40') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) = upper('RBP - 40') and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t31p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 31
,[tabName] = 'Ставка'
,[pokazatelNum] = 2
,[pokazatel] = 'RBP - 56'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) = upper('RBP - 56') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) = upper('RBP - 56') and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t31p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 31
,[tabName] = 'Ставка'
,[pokazatelNum] = 3
,[pokazatel] = 'RBP - 66'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) = upper('RBP - 66') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) = upper('RBP - 66') and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t31p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null 
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 31
,[tabName] = 'Ставка'
,[pokazatelNum] = 4
,[pokazatel] = 'RBP - 86'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) = upper('RBP - 86') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) = upper('RBP - 86') and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t31p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 31
,[tabName] = 'Ставка'
,[pokazatelNum] = 5
,[pokazatel] = 'non - RBP'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) = upper('non - RBP') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) = upper('non - RBP') and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t31p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 31
,[tabName] = 'Ставка'
,[pokazatelNum] = 6
,[pokazatel] = 'Исп. срок'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) = upper('Исп. срок') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) = upper('Исп. срок') and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t31p7
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 31
,[tabName] = 'Ставка'
,[pokazatelNum] = 7
,[pokazatel] = 'Рефинансирование'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) = upper('Рефинанс.') and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) = upper('Рефинанс.') and upper(a.spr1) = upper('ПТС')) c1 on 1=1

--t31p8
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0) !=0 then l1.fAmount / c1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = null

from(
select
[tabNum] = 31
,[tabName] = 'Ставка'
,[pokazatelNum] = 8
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) is not null and upper(a.spr1) = upper('ПТС')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) is not null and upper(a.spr1) = upper('ПТС')) c1 on 1=1



end
