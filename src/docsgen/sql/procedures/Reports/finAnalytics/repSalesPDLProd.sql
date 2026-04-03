


CREATE PROCEDURE [finAnalytics].[repSalesPDLProd]
	@dateTo date,
	@monthFrom date
AS
BEGIN

--t18p1
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
,[tekPRC] = case when isnull(b.pAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then   l1.fAmount / c.[Доля для RR ПТС] / b.pAmount end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 18
,[tabName] = 'Объём выдач PDL'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач, млн.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
) l1
left join #plan b on upper(b.product)=upper('PDL')
left join #RR c on c.Дата = @dateTo

--t18p2
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
,[tekPRC] = case when isnull(b.pAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then   l1.fAmount / c.[Доля для RR ПТС] / b.pAmount end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 18
,[tabName] = 'Объём выдач PDL'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('PDL новые')
left join #RR c on c.Дата = @dateTo

--t18p3
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
,[tekPRC] = case when isnull(b.pAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then   l1.fAmount / c.[Доля для RR ПТС] / b.pAmount end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 18
,[tabName] = 'Объём выдач PDL'
,[pokazatelNum] = 3
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('PDL повторники')
left join #RR c on c.Дата = @dateTo

--t18p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end
,[fAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end
,[RR] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end

from(
select
[tabNum] = 18
,[tabName] = 'Объём выдач PDL'
,[pokazatelNum] = 4
,[pokazatel] = '% Новые'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('PDL новые')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL')) d on 1=1

--t18p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end
,[fAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end
,[RR] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end

from(
select
[tabNum] = 18
,[tabName] = 'Объём выдач PDL'
,[pokazatelNum] = 5
,[pokazatel] = '% Повторники'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('PDL повторники')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL')) d on 1=1

--t19p1
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 and b.pCount !=0 then l1.fAmount / c.[Доля для RR ПТС] / b.pCount end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 19
,[tabName] = 'Количество выдач PDL'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач, млн.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
) l1
left join #plan b on upper(b.product)=upper('PDL')
left join #RR c on c.Дата = @dateTo

--t19p2
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 and b.pCount !=0 then l1.fAmount / c.[Доля для RR ПТС] / b.pCount end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 19
,[tabName] = 'Количество выдач PDL'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('PDL новые')
left join #RR c on c.Дата = @dateTo

--t19p3
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 and b.pCount !=0 then l1.fAmount / c.[Доля для RR ПТС] / b.pCount end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 19
,[tabName] = 'Количество выдач PDL'
,[pokazatelNum] = 3
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('PDL повторники')
left join #RR c on c.Дата = @dateTo

--t19p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end
,[fAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end
,[RR] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end

from(
select
[tabNum] = 19
,[tabName] = 'Количество выдач PDL'
,[pokazatelNum] = 4
,[pokazatel] = '% Новые'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('PDL новые')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('PDL')) d on 1=1

--t19p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end
,[fAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end
,[RR] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount end

from(
select
[tabNum] = 19
,[tabName] = 'Количество выдач PDL'
,[pokazatelNum] = 5
,[pokazatel] = '% Повторники'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('PDL повторники')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('PDL')) d on 1=1

--t20p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pAVGChaeck
,[fAmount] = case when isnull(l1.fAmount,0) !=0 then d.fAmount / l1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(l1.fAmount,0) !=0 and isnull(b.pAVGChaeck,0) !=0 then d.fAmount / l1.fAmount / b.pAVGChaeck end
,[RR] = case when isnull(l1.fAmount,0) !=0 then d.fAmount / l1.fAmount end

from(
select
[tabNum] = 20
,[tabName] = 'Средний чек по PDL'
,[pokazatelNum] = 1
,[pokazatel] = 'Средний чек, тыс.руб.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
) l1
left join #plan b on upper(b.product)=upper('PDL')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL')) d on 1=1

--t20p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pAVGChaeck
,[fAmount] = case when isnull(l1.fAmount,0) !=0 then d.fAmount / l1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(l1.fAmount,0) !=0 and isnull(b.pAVGChaeck,0) !=0 then d.fAmount / l1.fAmount / b.pAVGChaeck end
,[RR] = case when isnull(l1.fAmount,0) !=0 then d.fAmount / l1.fAmount end

from(
select
[tabNum] = 20
,[tabName] = 'Средний чек по PDL'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('PDL новые')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL') and upper(a.spr2) = upper('Новые')) d on 1=1

--t20p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pAVGChaeck
,[fAmount] = case when isnull(l1.fAmount,0) !=0 then d.fAmount / l1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(l1.fAmount,0) !=0 and isnull(b.pAVGChaeck,0) !=0 then d.fAmount / l1.fAmount / b.pAVGChaeck end
,[RR] = case when isnull(l1.fAmount,0) !=0 then d.fAmount / l1.fAmount end

from(
select
[tabNum] = 20
,[tabName] = 'Средний чек по PDL'
,[pokazatelNum] = 3
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('PDL повторники')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL') and upper(a.spr2) = upper('Повторники')) d on 1=1

--t21p1
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
,[tekPRC] = case when isnull(b.pAVGPRC,0) != 0 then l1.fAmount / b.pAVGPRC end
,[RR] = l1.fAmount

from(
select
[tabNum] = 21
,[tabName] = 'Средние ставки по PDL'
,[pokazatelNum] = 1
,[pokazatel] = 'Средняя ставка'
,[pAmount] = 0
,[fAmount] = case when sum(isnull(a.dogSum,0)) !=0 then sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100 end

from #PBR a
where upper(a.spr1) = upper('PDL')
) l1
left join #plan b on upper(b.product)=upper('PDL')
left join #RR c on c.Дата = @dateTo

--t21p2
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
,[tekPRC] = case when isnull(b.pAVGPRC,0) !=0 then l1.fAmount / b.pAVGPRC end
,[RR] = l1.fAmount

from(
select
[tabNum] = 21
,[tabName] = 'Средние ставки по PDL'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = case when sum(isnull(a.dogSum,0)) !=0 then sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100 end

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('PDL новые')
left join #RR c on c.Дата = @dateTo

--t21p3
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
,[tekPRC] = case when isnull(b.pAVGPRC,0) !=0 then l1.fAmount / b.pAVGPRC end
,[RR] = l1.fAmount

from(
select
[tabNum] = 21
,[tabName] = 'Средние ставки по PDL'
,[pokazatelNum] = 3
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = case when sum(isnull(a.dogSum,0)) !=0 then sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100 end

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('PDL повторники')
left join #RR c on c.Дата = @dateTo

--t22p1
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
[tabNum] = 22
,[tabName] = 'Объёмы выдач по PDL по срокам и средневзв. сроки'
,[pokazatelNum] = 1
,[pokazatel] = '7 дней'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and a.dogPeriodDays = 7
) l1
left join #RR c on c.Дата = @dateTo

--t22p2
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
[tabNum] = 22
,[tabName] = 'Объёмы выдач по PDL по срокам и средневзв. сроки'
,[pokazatelNum] = 2
,[pokazatel] = '14 дней'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and a.dogPerioddays = 14
) l1
left join #RR c on c.Дата = @dateTo

--t22p3
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
[tabNum] = 22
,[tabName] = 'Объёмы выдач по PDL по срокам и средневзв. сроки'
,[pokazatelNum] = 3
,[pokazatel] = '21 день'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and a.dogPerioddays = 21
) l1
left join #RR c on c.Дата = @dateTo

--t22p4
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
[tabNum] = 22
,[tabName] = 'Объёмы выдач по PDL по срокам и средневзв. сроки'
,[pokazatelNum] = 4
,[pokazatel] = '30 дней'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and a.dogPeriodDays = 30
) l1
left join #RR c on c.Дата = @dateTo

--t22p5
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
[tabNum] = 22
,[tabName] = 'Объёмы выдач по PDL по срокам и средневзв. сроки'
,[pokazatelNum] = 5
,[pokazatel] = 'Средневзвешенный срок, дней'
,[pAmount] = 0
,[fAmount] = case when sum(isnull(a.dogSum,0)) != 0 then sum(isnull(a.dogSum,0) * a.dogPeriodDays) / sum(isnull(a.dogSum,0)) end

from #PBR a
where upper(a.spr1) = upper('PDL')
) l1
left join #RR c on c.Дата = @dateTo

--t22p6
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
[tabNum] = 22
,[tabName] = 'Объёмы выдач по PDL по срокам и средневзв. сроки'
,[pokazatelNum] = 6
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = case when sum(isnull(a.dogSum,0)) != 0 then sum(isnull(a.dogSum,0) * a.dogPeriodDays) / sum(isnull(a.dogSum,0)) end

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.spr2) = upper('Новые')
) l1
left join #RR c on c.Дата = @dateTo

--t22p7
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
[tabNum] = 22
,[tabName] = 'Объёмы выдач по PDL по срокам и средневзв. сроки'
,[pokazatelNum] = 7
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = case when sum(isnull(a.dogSum,0)) != 0 then sum(isnull(a.dogSum,0) * a.dogPeriodDays) / sum(isnull(a.dogSum,0)) end

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.spr2) = upper('Повторники')
) l1
left join #RR c on c.Дата = @dateTo

--t23p1
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
[tabNum] = 23
,[tabName] = 'Объёмы и количество выдач по PDL онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач онлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo

--t23p2
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
[tabNum] = 23
,[tabName] = 'Объёмы и количество выдач по PDL онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 2
,[pokazatel] = 'Объём выдач офлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.saleType) = upper('дистанционный')
) l1
left join #RR c on c.Дата = @dateTo

--t23p3
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
[tabNum] = 23
,[tabName] = 'Объёмы и количество выдач по PDL онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 3
,[pokazatel] = 'Кол-во выдач онлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo

--t23p4
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
[tabNum] = 23
,[tabName] = 'Объёмы и количество выдач по PDL онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 4
,[pokazatel] = 'Кол-во выдач офлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.saleType) = upper('дистанционный')
) l1
left join #RR c on c.Дата = @dateTo

--t23p5
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
,[tekPRC] = NULL
,[RR] = case when isnull(b.fAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / b.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 23
,[tabName] = 'Объёмы и количество выдач по PDL онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 5
,[pokazatel] = 'Доля выдач онлайн по объёму, %'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL')) b on 1=1

--t23p6
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
,[tekPRC] = NULL
,[RR] = case when isnull(b.fAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / b.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 23
,[tabName] = 'Объёмы и количество выдач по PDL онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 6
,[pokazatel] = 'Доля выдач онлайн по кол-ву, %'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('PDL')) b on 1=1

--t24p1
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
[tabNum] = 24
,[tabName] = 'Объёмы и количество выдач по PDL онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач онлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.Сумма,0))

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('PDL')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo

--t24p2
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
[tabNum] = 24
,[tabName] = 'Объёмы и количество выдач по PDL онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 2
,[pokazatel] = 'Объём выдач офлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.Сумма,0))

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('PDL')
and upper(a.[Дистанционная выдача]) = 0
) l1
left join #RR c on c.Дата = @dateTo

--t24p3
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
[tabNum] = 24
,[tabName] = 'Объёмы и количество выдач по PDL онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 3
,[pokazatel] = 'Кол-во выдач онлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.код) as float)

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('PDL')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo

--t24p4
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
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 24
,[tabName] = 'Объёмы и количество выдач по PDL онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 4
,[pokazatel] = 'Кол-во выдач офлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.код) as float)

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('PDL')
and upper(a.[Дистанционная выдача]) = 0
) l1
left join #RR c on c.Дата = @dateTo

--t24p5
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
,[tekPRC] = NULL
,[RR] = case when isnull(b.fAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / b.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 24
,[tabName] = 'Объёмы и количество выдач по PDL онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 5
,[pokazatel] = 'Доля выдач онлайн по объёму, %'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.Сумма,0))

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('PDL')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.Сумма,0)) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('PDL')) b on 1=1

--t24p6
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
,[tekPRC] = NULL
,[RR] = case when isnull(b.fAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / b.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 24
,[tabName] = 'Объёмы и количество выдач по PDL онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 6
,[pokazatel] = 'Доля выдач онлайн по кол-ву, %'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.код) as float)

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('PDL')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct a.код) as float) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('PDL')) b on 1=1

--t25p1
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
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач по акции 0%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да')
) l1
left join #RR c on c.Дата = @dateTo

--t25p2
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
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 2
,[pokazatel] = 'Кол-во выдач по акции 0%'
,[pAmount] = 0
,[fAmount] = cast( isnull(count(distinct a.dogNum),0) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да')
) l1
left join #RR c on c.Дата = @dateTo

--t25p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 3
,[pokazatel] = 'Доля акции 0% от всех выдач PDL:'
,[pAmount] = NULL
,[fAmount] = NULL
,[rrDolya] = NULL
,[tekPRC] = NULL
,[RR] = NULL

--t25p4
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
,[RR] = case when isnull(c1.fAmount,0) != 0 then l1.fAmount / c1.fAmount end

from(
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 4
,[pokazatel] = '- по объёму'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL')) c1 on 1=1

--t25p5
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
,[RR] = case when isnull(c1.fAmount,0) != 0 then l1.fAmount / c1.fAmount end

from(
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 5
,[pokazatel] = '- по кол-ву'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogSum,0)) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogSum,0)) as float) from #PBR a where upper(a.spr1) = upper('PDL')) c1 on 1=1

--t25p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 6
,[pokazatel] = 'Доля акции 0% от первичных PDL:'
,[pAmount] = NULL
,[fAmount] = NULL
,[rrDolya] = NULL
,[tekPRC] = NULL
,[RR] = NULL

--t25p7
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
,[RR] = case when isnull(c1.fAmount,0) != 0 then l1.fAmount / c1.fAmount end

from(
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 7
,[pokazatel] = '- по объёму'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да')
and upper(a.spr2) = upper('Новые')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL') and upper(a.spr2) = upper('Новые')) c1 on 1=1

--t25p8
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
,[RR] = case when isnull(c1.fAmount,0) != 0 then l1.fAmount / c1.fAmount end

from(
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 8
,[pokazatel] = '- по кол-ву'
,[pAmount] = 0
,[fAmount] = cast(count(distinct isnull(a.dogSum,0)) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да')
and upper(a.spr2) = upper('Новые')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogSum,0)) as float) from #PBR a where upper(a.spr1) = upper('PDL') and upper(a.spr2) = upper('Новые')) c1 on 1=1

--t25p9
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 9
,[pokazatel] = 'Воспользовались акцией 0%:'
,[pAmount] = NULL
,[fAmount] = NULL
,[rrDolya] = NULL
,[tekPRC] = NULL
,[RR] = NULL

--t25p10
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
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 10
,[pokazatel] = '- по объёму'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да')
and isnull(a.prosDaysTotal,0) = 0
and upper(a.isRestruk) = upper('Нет')
) l1
left join #RR c on c.Дата = @dateTo

--t25p11
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
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 11
,[pokazatel] = '- по кол-ву'
,[pAmount] = 0
,[fAmount] = cast( isnull(count(distinct a.dogNum),0) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да')
and isnull(a.prosDaysTotal,0) = 0
and upper(a.isRestruk) = upper('Нет')
) l1
left join #RR c on c.Дата = @dateTo

--t25p12
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 12
,[pokazatel] = 'Доля воспользовавшихся акцией 0% (от заёмщиков, соответствующих условиям акции):'
,[pAmount] = NULL
,[fAmount] = NULL
,[rrDolya] = NULL
,[tekPRC] = NULL
,[RR] = NULL

--t25p13
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
,[RR] = case when isnull(c1.fAmount,0) != 0 then l1.fAmount / c1.fAmount end

from(
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 13
,[pokazatel] = '- по объёму'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да')
and isnull(a.prosDaysTotal,0) = 0
and upper(a.isRestruk) = upper('Нет')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL') and upper(a.isAkcia) = upper('да')) c1 on 1=1

--t25p14
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
,[RR] = case when isnull(c1.fAmount,0) != 0 then l1.fAmount / c1.fAmount end

from(
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 14
,[pokazatel] = '- по кол-ву'
,[pAmount] = 0
,[fAmount] = cast( isnull(count(distinct a.dogNum),0) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да')
and isnull(a.prosDaysTotal,0) = 0
and upper(a.isRestruk) = upper('Нет')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast( isnull(count(distinct a.dogNum),0) as float) from #PBR a where upper(a.spr1) = upper('PDL') and upper(a.isAkcia) = upper('да')) c1 on 1=1

--t25p15
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
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 15
,[pokazatel] = 'Сумма недополученных доходов при срабатывании акции 0%'
,[pAmount] = 0
,[fAmount] = sum(
                isnull(a.dogSum,0) 
                * a.stavaOnSaleDate
                / 100
                / DATEDIFF(day,DATEFROMPARTS(year(@monthFrom),1,1),DATEFROMPARTS(year(@monthFrom),12,31))+1
                * a.dogPeriodDays
                )

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да')
and isnull(a.prosDaysTotal,0) = 0
and upper(a.isRestruk) = upper('Нет')
) l1
left join #RR c on c.Дата = @dateTo

--t25p16
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 16
,[pokazatel] = 'Причина невыполнения условий акции 0%:'
,[pAmount] = NULL
,[fAmount] = NULL
,[rrDolya] = NULL
,[tekPRC] = NULL
,[RR] = NULL

--t25p17
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 17
,[pokazatel] = '-  просрочка:'
,[pAmount] = NULL
,[fAmount] = NULL
,[rrDolya] = NULL
,[tekPRC] = NULL
,[RR] = NULL

--t25p18
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
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 18
,[pokazatel] = '- по объёму'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да')
and isnull(a.prosDaysTotal,0) > 0
) l1
left join #RR c on c.Дата = @dateTo

--t25p19
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
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 19
,[pokazatel] = '- по кол-ву'
,[pAmount] = 0
,[fAmount] = cast( isnull(count(distinct a.dogNum),0) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да')
and isnull(a.prosDaysTotal,0) > 0

) l1
left join #RR c on c.Дата = @dateTo

--t25p20
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 20
,[pokazatel] = '-  пролонгация:'
,[pAmount] = NULL
,[fAmount] = NULL
,[rrDolya] = NULL
,[tekPRC] = NULL
,[RR] = NULL

--t25p21
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
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 21
,[pokazatel] = '- по объёму'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да')
and isnull(a.prosDaysTotal,0) = 0
and upper(a.isRestruk) = upper('да')
) l1
left join #RR c on c.Дата = @dateTo

--t25p22
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
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 22
,[pokazatel] = '- по кол-ву'
,[pAmount] = 0
,[fAmount] = cast( isnull(count(distinct a.dogNum),0) as float)

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да')
and isnull(a.prosDaysTotal,0) = 0
and upper(a.isRestruk) = upper('да')
) l1
left join #RR c on c.Дата = @dateTo

--t25p23
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 23
,[pokazatel] = 'Средняя ставка по PDL с учётом акции 0%:'
,[pAmount] = NULL
,[fAmount] = NULL
,[rrDolya] = NULL
,[tekPRC] = NULL
,[RR] = NULL

--t25p24
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = case when isnull(l1.fAmount,0) != 0 then ( l1.fAmount - c1.fAmount) * c2.fAmount / l1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = case when isnull(l1.fAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then  
            ( l1.fAmount - c1.fAmount) * c2.fAmount / l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 24
,[pokazatel] = '- по всем выдачам PDL'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да') and isnull(a.prosDaysTotal,0) = 0 and upper(a.isRestruk) = upper('Нет')) c1 on 1=1
left join (select [fAmount] = sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100 from #PBR a where upper(a.spr1) = upper('PDL')) c2 on 1=1

--t25p25
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = case when isnull(l1.fAmount,0) != 0 then ( l1.fAmount - c1.fAmount) * c2.fAmount / l1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] =case when isnull(l1.fAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 then  
            ( l1.fAmount - c1.fAmount) * c2.fAmount / l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 25
,[tabName] = 'Акция 0%'
,[pokazatelNum] = 25
,[pokazatel] = '- по первичным выдачам PDL'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('PDL')
and upper(a.spr2) = upper('Новые')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL')
and upper(a.isAkcia) = upper('да') and isnull(a.prosDaysTotal,0) = 0 and upper(a.isRestruk) = upper('Нет')) c1 on 1=1
left join (select [fAmount] = sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100 from #PBR a where upper(a.spr1) = upper('PDL')) c2 on 1=1


end
