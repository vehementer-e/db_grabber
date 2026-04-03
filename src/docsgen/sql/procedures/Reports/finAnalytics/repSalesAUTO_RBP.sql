




CREATE PROCEDURE [finAnalytics].[repSalesAUTO_RBP]
	@dateTo date
	--,@monthFrom date
AS
BEGIN

--t64p1
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
[tabNum] = 64
,[tabName] = 'Объём Автокредит'
,[pokazatelNum] = 1
,[pokazatel] = 'RBP - 40'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 40') and upper(a.spr1) = upper('Автокредит')
) l1
left join #plan b on upper(b.product)=upper('RBP АВТО - 40')
left join #RR c on c.Дата = @dateTo

--t64p2
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
[tabNum] = 64
,[tabName] = 'Объём Автокредит'
,[pokazatelNum] = 2
,[pokazatel] = 'RBP - 56'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 56') and upper(a.spr1) = upper('Автокредит')
) l1
left join #plan b on upper(b.product)=upper('RBP АВТО - 56')
left join #RR c on c.Дата = @dateTo

--t64p3
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
[tabNum] = 64
,[tabName] = 'Объём Автокредит'
,[pokazatelNum] = 3
,[pokazatel] = 'RBP - 66'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 66') and upper(a.spr1) = upper('Автокредит')
) l1
left join #plan b on upper(b.product)=upper('RBP АВТО - 66')
left join #RR c on c.Дата = @dateTo

--t64p4
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
[tabNum] = 64
,[tabName] = 'Объём Автокредит'
,[pokazatelNum] = 4
,[pokazatel] = 'RBP - 86'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 86') and upper(a.spr1) = upper('Автокредит')
) l1
left join #plan b on upper(b.product)=upper('RBP АВТО - 86')
left join #RR c on c.Дата = @dateTo

--t64p5
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
[tabNum] = 64
,[tabName] = 'Объём Автокредит'
,[pokazatelNum] = 5
,[pokazatel] = 'non - RBP'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('non - RBP') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t64p6
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
[tabNum] = 64
,[tabName] = 'Объём Автокредит'
,[pokazatelNum] = 6
,[pokazatel] = 'Исп. срок'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('Исп. срок') and upper(a.spr1) = upper('Автокредит')
) l1
left join #plan b on upper(b.product)=upper('Исп.срок АВТО')
left join #RR c on c.Дата = @dateTo

--t64p7
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
[tabNum] = 64
,[tabName] = 'Объём Автокредит'
,[pokazatelNum] = 7
,[pokazatel] = 'Рефинансирование'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('Рефинанс.') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t64p8
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
[tabNum] = 64
,[tabName] = 'Объём Автокредит'
,[pokazatelNum] = 8
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) is not null and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (
select pAmount = isnull(SUM(isnull(pAmount,0)),0) from #plan b where upper(b.product) in 
						 (
						 upper('RBP АВТО - 40'),
						 upper('RBP АВТО - 56'),
						 upper('RBP АВТО - 66'),
						 upper('RBP АВТО - 86'),
						 upper('Исп.срок АВТО')
						 )
) b on 1=1

--t65p1
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
[tabNum] = 65
,[tabName] = 'Количество Автокредит'
,[pokazatelNum] = 1
,[pokazatel] = 'RBP - 40'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) = upper('RBP - 40') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t65p2
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
[tabNum] = 65
,[tabName] = 'Количество Автокредит'
,[pokazatelNum] = 2
,[pokazatel] = 'RBP - 56'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) = upper('RBP - 56') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t65p3
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
[tabNum] = 65
,[tabName] = 'Количество Автокредит'
,[pokazatelNum] = 3
,[pokazatel] = 'RBP - 66'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) = upper('RBP - 66') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t65p4
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
[tabNum] = 65
,[tabName] = 'Количество Автокредит'
,[pokazatelNum] = 4
,[pokazatel] = 'RBP - 86'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) = upper('RBP - 86') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t65p5
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
[tabNum] = 65
,[tabName] = 'Количество Автокредит'
,[pokazatelNum] = 5
,[pokazatel] = 'non - RBP'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) = upper('non - RBP') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t65p6
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
[tabNum] = 65
,[tabName] = 'Количество Автокредит'
,[pokazatelNum] = 6
,[pokazatel] = 'Исп. срок'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) = upper('Исп. срок') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t65p7
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
[tabNum] = 65
,[tabName] = 'Количество Автокредит'
,[pokazatelNum] = 7
,[pokazatel] = 'Рефинансирование'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) = upper('Рефинанс.') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t65p8
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
[tabNum] = 65
,[tabName] = 'Количество Автокредит'
,[pokazatelNum] = 8
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr3) is not null and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t66p1
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
[tabNum] = 66
,[tabName] = 'Доля по объему Автокредит'
,[pokazatelNum] = 1
,[pokazatel] = 'RBP - 40'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 40') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t66p2
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
[tabNum] = 66
,[tabName] = 'Доля по объему Автокредит'
,[pokazatelNum] = 2
,[pokazatel] = 'RBP - 56'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 56') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t66p3
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
[tabNum] = 66
,[tabName] = 'Доля по объему Автокредит'
,[pokazatelNum] = 3
,[pokazatel] = 'RBP - 66'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 66') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t66p4
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
[tabNum] = 66
,[tabName] = 'Доля по объему Автокредит'
,[pokazatelNum] = 4
,[pokazatel] = 'RBP - 86'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 86') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t66p5
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
[tabNum] = 66
,[tabName] = 'Доля по объему Автокредит'
,[pokazatelNum] = 5
,[pokazatel] = 'non - RBP'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('non - RBP') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t66p6
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
[tabNum] = 66
,[tabName] = 'Доля по объему Автокредит'
,[pokazatelNum] = 6
,[pokazatel] = 'Исп. срок'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('Исп. срок') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t66p7
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
[tabNum] = 66
,[tabName] = 'Доля по объему Автокредит'
,[pokazatelNum] = 7
,[pokazatel] = 'Рефинансирование'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('Рефинанс.') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t66p8
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
[tabNum] = 66
,[tabName] = 'Доля по объему Автокредит'
,[pokazatelNum] = 8
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) is not null and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t67p1
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
[tabNum] = 67
,[tabName] = 'Средний чек Автокредит, тыс.руб.'
,[pokazatelNum] = 1
,[pokazatel] = 'RBP - 40'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 40') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr3) = upper('RBP - 40') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t67p2
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
[tabNum] = 67
,[tabName] = 'Средний чек Автокредит, тыс.руб.'
,[pokazatelNum] = 2
,[pokazatel] = 'RBP - 56'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 56') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr3) = upper('RBP - 56') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t67p3
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
[tabNum] = 67
,[tabName] = 'Средний чек Автокредит, тыс.руб.'
,[pokazatelNum] = 3
,[pokazatel] = 'RBP - 66'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 66') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr3) = upper('RBP - 66') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t67p4
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
[tabNum] = 67
,[tabName] = 'Средний чек Автокредит, тыс.руб.'
,[pokazatelNum] = 4
,[pokazatel] = 'RBP - 86'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('RBP - 86') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr3) = upper('RBP - 86') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t67p5
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
[tabNum] = 67
,[tabName] = 'Средний чек Автокредит, тыс.руб.'
,[pokazatelNum] = 5
,[pokazatel] = 'non - RBP'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('non - RBP') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr3) = upper('non - RBP') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t67p6
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
[tabNum] = 67
,[tabName] = 'Средний чек Автокредит, тыс.руб.'
,[pokazatelNum] = 6
,[pokazatel] = 'Исп. срок'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('Исп. срок') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr3) = upper('Исп. срок') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t67p7
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
[tabNum] = 67
,[tabName] = 'Средний чек Автокредит, тыс.руб.'
,[pokazatelNum] = 7
,[pokazatel] = 'Рефинансирование'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) = upper('Рефинанс.') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr3) = upper('Рефинанс.') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t67p8
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
[tabNum] = 67
,[tabName] = 'Средний чек Автокредит, тыс.руб.'
,[pokazatelNum] = 8
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr3) is not null and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where a.spr3 is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t68p1
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
[tabNum] = 68
,[tabName] = 'Ставка Автокредит'
,[pokazatelNum] = 1
,[pokazatel] = 'RBP - 40'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) = upper('RBP - 40') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) = upper('RBP - 40') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t68p2
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
[tabNum] = 68
,[tabName] = 'Ставка Автокредит'
,[pokazatelNum] = 2
,[pokazatel] = 'RBP - 56'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) = upper('RBP - 56') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) = upper('RBP - 56') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t68p3
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
[tabNum] = 68
,[tabName] = 'Ставка Автокредит'
,[pokazatelNum] = 3
,[pokazatel] = 'RBP - 66'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) = upper('RBP - 66') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) = upper('RBP - 66') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t68p4
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
[tabNum] = 68
,[tabName] = 'Ставка Автокредит'
,[pokazatelNum] = 4
,[pokazatel] = 'RBP - 86'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) = upper('RBP - 86') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) = upper('RBP - 86') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t68p5
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
[tabNum] = 68
,[tabName] = 'Ставка Автокредит'
,[pokazatelNum] = 5
,[pokazatel] = 'non - RBP'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) = upper('non - RBP') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) = upper('non - RBP') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t68p6
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
[tabNum] = 68
,[tabName] = 'Ставка Автокредит'
,[pokazatelNum] = 6
,[pokazatel] = 'Исп. срок'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) = upper('Исп. срок') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) = upper('Исп. срок') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t68p7
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
[tabNum] = 68
,[tabName] = 'Ставка Автокредит'
,[pokazatelNum] = 7
,[pokazatel] = 'Рефинансирование'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) = upper('Рефинанс.') and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) = upper('Рефинанс.') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t68p8
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
[tabNum] = 68
,[tabName] = 'Ставка Автокредит'
,[pokazatelNum] = 8
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = sum(a.dogSum * a.stavaOnSaleDate) / 100

from #PBR a
where upper(a.spr3) is not null and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr3) is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1



end
