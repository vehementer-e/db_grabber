


CREATE PROCEDURE [finAnalytics].[repSalesAUTOProd]
	@dateTo date
AS
BEGIN

--t57p1
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
[tabNum] = 57
,[tabName] = 'Объём выдач по Автокредиту'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач, млн.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Автокредит')
) l1
left join #plan b on upper(b.product)=upper('Автокредит')
left join #RR c on c.Дата = @dateTo

--t57p2
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
[tabNum] = 57
,[tabName] = 'Объём выдач по Автокредиту'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('Автокредит новые')
left join #RR c on c.Дата = @dateTo

--t57p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = isnull(b.pAmount,0)
,[fAmount] = isnull(l1.fAmount,0)
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 and isnull(b.pAmount,0) !=0 then isnull(l1.fAmount,0) / c.[Доля для RR ПТС] / b.pAmount else 0 end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then isnull(l1.fAmount,0) / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 57
,[tabName] = 'Объём выдач по Автокредиту'
,[pokazatelNum] = 3
,[pokazatel] = 'Докреды'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Докреды')
) l1
left join #plan b on upper(b.product)=upper('Автокредит докреды')
left join #RR c on c.Дата = @dateTo

--t57p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = isnull(b.pAmount,0)
,[fAmount] = isnull(l1.fAmount,0)
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 and isnull(b.pAmount,0) != 0 
				then isnull(l1.fAmount,0) / c.[Доля для RR ПТС] / b.pAmount
				else 0 end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 
				then isnull(l1.fAmount,0) / c.[Доля для RR ПТС]
				else 0 end

from(
select
[tabNum] = 57
,[tabName] = 'Объём выдач по Автокредиту'
,[pokazatelNum] = 4
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('Автокредит повторники')
left join #RR c on c.Дата = @dateTo

--t57p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[fAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[rrDolya] = null
,[tekPRC] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[RR] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end

from(
select
[tabNum] = 57
,[tabName] = 'Объём выдач по Автокредиту'
,[pokazatelNum] = 5
,[pokazatel] = '% Новые'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Новые')
) l1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Автокредит')) d on 1=1


--t57p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[fAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[rrDolya] = null
,[tekPRC] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[RR] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end

from(
select
[tabNum] = 57
,[tabName] = 'Объём выдач по Автокредиту'
,[pokazatelNum] = 6
,[pokazatel] = '% Докреды'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Докреды')
) l1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Автокредит')) d on 1=1

--t57p7
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[fAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[rrDolya] = null
,[tekPRC] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[RR] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end

from(
select
[tabNum] = 57
,[tabName] = 'Объём выдач по Автокредиту'
,[pokazatelNum] = 7
,[pokazatel] = '% Повторники'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Повторники')
) l1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Автокредит')) d on 1=1

--t58p1
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) !=0 
					and isnull(b.pCount,0) !=0
					then l1.fAmount / c.[Доля для RR ПТС] / b.pCount else 0 end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) !=0 
				then l1.fAmount / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 58
,[tabName] = 'Количество выдач по Автокредиту'
,[pokazatelNum] = 1
,[pokazatel] = 'Количество выдач'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Автокредит')
) l1
left join #plan b on upper(b.product)=upper('Автокредит')
left join #RR c on c.Дата = @dateTo

--t58p2
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
,[tekPRC] =  case when isnull(c.[Доля для RR ПТС],0) !=0 
					and isnull(b.pCount,0) !=0
					then l1.fAmount / c.[Доля для RR ПТС] / b.pCount else 0 end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) !=0 
				then l1.fAmount / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 58
,[tabName] = 'Количество выдач по Автокредиту'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('Автокредит новые')
left join #RR c on c.Дата = @dateTo

--t58p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = isnull(b.pCount,0)
,[fAmount] = isnull(l1.fAmount,0)
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 and isnull(b.pCount,0) != 0 
					then isnull(l1.fAmount,0) / c.[Доля для RR ПТС] / b.pCount
					else 0 end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0
				then isnull(l1.fAmount,0) / c.[Доля для RR ПТС]
				else 0 end

from(
select
[tabNum] = 58
,[tabName] = 'Количество выдач по Автокредиту'
,[pokazatelNum] = 3
,[pokazatel] = 'Докреды'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Докреды')
) l1
left join #plan b on upper(b.product)=upper('Автокредит докреды')
left join #RR c on c.Дата = @dateTo

--t58p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = isnull(b.pCount,0)
,[fAmount] = isnull(l1.fAmount,0)
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when c.[Доля для RR ПТС] != 0 and isnull(b.pCount,0) != 0 
					then isnull(l1.fAmount,0) / c.[Доля для RR ПТС] / isnull(b.pCount,0)
					else 0 end
,[RR] = case when c.[Доля для RR ПТС] != 0 
			then isnull(l1.fAmount,0) / c.[Доля для RR ПТС]
			else 0 end

from(
select
[tabNum] = 58
,[tabName] = 'Количество выдач по Автокредиту'
,[pokazatelNum] = 4
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('Автокредит повторники')
left join #RR c on c.Дата = @dateTo

--t58p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[fAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[rrDolya] = null
,[tekPRC] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[RR] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end

from(
select
[tabNum] = 58
,[tabName] = 'Количество выдач по Автокредиту'
,[pokazatelNum] = 5
,[pokazatel] = '% Новые'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Новые')
) l1
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('Автокредит')) d on 1=1

--t58p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[fAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[rrDolya] = null
,[tekPRC] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[RR] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end

from(
select
[tabNum] = 58
,[tabName] = 'Количество выдач по Автокредиту'
,[pokazatelNum] = 6
,[pokazatel] = '% Докреды'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Докреды')
) l1
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('Автокредит')) d on 1=1

--t58p7
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[fAmount] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[rrDolya] = null
,[tekPRC] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end
,[RR] = case when isnull(d.fAmount,0) !=0 then l1.fAmount / d.fAmount else 0 end

from(
select
[tabNum] = 58
,[tabName] = 'Количество выдач по Автокредиту'
,[pokazatelNum] = 7
,[pokazatel] = '% Повторники'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Повторники')
) l1
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('Автокредит')) d on 1=1

--t59p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pAVGChaeck
,[fAmount] = case when isnull(l1.fAmount,0) !=0 then d.fAmount / l1.fAmount else 0 end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(l1.fAmount,0) !=0 
				and isnull(b.pAVGChaeck,0) !=0
				then d.fAmount / l1.fAmount / b.pAVGChaeck else 0 end
,[RR] = case when isnull(l1.fAmount,0) !=0 then d.fAmount / l1.fAmount else 0 end

from(
select
[tabNum] = 59
,[tabName] = 'Средний чек по Автокредиту'
,[pokazatelNum] = 1
,[pokazatel] = 'Средний чек, тыс.руб.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Автокредит')
) l1
left join #plan b on upper(b.product)=upper('Автокредит')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Автокредит')) d on 1=1

--t59p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = b.pAVGChaeck
,[fAmount] = case when isnull(l1.fAmount,0) !=0 then d.fAmount / l1.fAmount else 0 end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(l1.fAmount,0) !=0 
					and isnull(b.pAVGChaeck,0) !=0 
					then d.fAmount / l1.fAmount / b.pAVGChaeck else 0 end
,[RR] = case when isnull(l1.fAmount,0) !=0 then d.fAmount / l1.fAmount else 0 end

from(
select
[tabNum] = 59
,[tabName] = 'Средний чек по Автокредиту'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('Автокредит новые')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Автокредит') and upper(a.spr2) = upper('Новые')) d on 1=1

--t59p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = isnull(b.pAVGChaeck,0)
,[fAmount] = case when isnull(l1.fAmount,0) != 0 
				then isnull(d.fAmount,0) / l1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(b.pAVGChaeck,0) != 0 and isnull(l1.fAmount,0) != 0 
				then d.fAmount / l1.fAmount / b.pAVGChaeck end
,[RR] = case when isnull(l1.fAmount,0) != 0 
				then d.fAmount / l1.fAmount end

from(
select
[tabNum] = 59
,[tabName] = 'Средний чек по Автокредиту'
,[pokazatelNum] = 3
,[pokazatel] = 'Докреды'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Докреды')
) l1
left join #plan b on upper(b.product)=upper('Автокредит докреды')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Автокредит') and upper(a.spr2) = upper('Докреды')) d on 1=1

--t59p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = isnull(b.pAVGChaeck,0)
,[fAmount] = case when isnull(l1.fAmount,0) != 0 
				then isnull(d.fAmount,0) / l1.fAmount end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(b.pAVGChaeck,0) != 0 and isnull(l1.fAmount,0) != 0 
				then d.fAmount / l1.fAmount / b.pAVGChaeck end
,[RR] = case when isnull(l1.fAmount,0) != 0 
				then d.fAmount / l1.fAmount end

from(
select
[tabNum] = 59
,[tabName] = 'Средний чек по Автокредиту'
,[pokazatelNum] = 4
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('Автокредит повторники')
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Автокредит') and upper(a.spr2) = upper('Повторники')) d on 1=1

--t60p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = isnull(b.pAVGPRC,0)
,[fAmount] = isnull(l1.fAmount,0)
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(b.pAVGPRC,0) !=0 
				then l1.fAmount / isnull(b.pAVGPRC,0) end
,[RR] = isnull(l1.fAmount,0)

from(
select
[tabNum] = 60
,[tabName] = 'Средние ставки по Автокредиту'
,[pokazatelNum] = 1
,[pokazatel] = 'Средняя ставка'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100

from #PBR a
where upper(a.spr1) = upper('Автокредит')
) l1
left join #plan b on upper(b.product)=upper('Автокредит')
left join #RR c on c.Дата = @dateTo

--t60p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = isnull(b.pAVGPRC,0)
,[fAmount] = isnull(l1.fAmount,0)
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(b.pAVGPRC,0) != 0 
				then isnull(l1.fAmount,0) / isnull(b.pAVGPRC,0) end
,[RR] = l1.fAmount 

from(
select
[tabNum] = 60
,[tabName] = 'Средние ставки по Автокредиту'
,[pokazatelNum] = 2
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Новые')
) l1
left join #plan b on upper(b.product)=upper('Автокредит новые')
left join #RR c on c.Дата = @dateTo

--t60p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = isnull(b.pAVGPRC,0)
,[fAmount] = isnull(l1.fAmount,0)
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(b.pAVGPRC,0) != 0 
				then isnull(l1.fAmount,0) / isnull(b.pAVGPRC,0) end
,[RR] = l1.fAmount 

from(
select
[tabNum] = 60
,[tabName] = 'Средние ставки по Автокредиту'
,[pokazatelNum] = 3
,[pokazatel] = 'Докреды'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Докреды')
) l1
left join #plan b on upper(b.product)=upper('Автокредит докреды')
left join #RR c on c.Дата = @dateTo

--t60p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = isnull(b.pAVGPRC,0)
,[fAmount] = isnull(l1.fAmount,0)
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = case when isnull(b.pAVGPRC,0) != 0 
				then isnull(l1.fAmount,0) / isnull(b.pAVGPRC,0) end
,[RR] = isnull(l1.fAmount,0)

from(
select
[tabNum] = 60
,[tabName] = 'Средние ставки по Автокредиту'
,[pokazatelNum] = 4
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = case when sum(isnull(a.dogSum,0)) != 0 
					then sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100 else 0 end

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.spr2) = upper('Повторники')
) l1
left join #plan b on upper(b.product)=upper('Автокредит повторники')
left join #RR c on c.Дата = @dateTo

--t60p5
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
[tabNum] = 60
,[tabName] = 'Средние ставки по Автокредиту'
,[pokazatelNum] = 5
,[pokazatel] = 'Ставка по займам без КП, снижающих ставку'
,[pAmount] = 0
,[fAmount] = case when sum(isnull(a.dogSum,0)) != 0 
				then sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100 else 0 end

from #PBR a
left join #loans d on a.dogNum=d.код

where upper(a.spr1) = upper('Автокредит')
--and upper(a.spr2) = upper('Повторники')
and d.[Сумма комиссионных продуктов снижающих ставку]=0
) l1
left join #RR c on c.Дата = @dateTo

--t60p6
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
[tabNum] = 60
,[tabName] = 'Средние ставки по Автокредиту'
,[pokazatelNum] = 6
,[pokazatel] = 'Ставка по займам с КП, снижающими ставку'
,[pAmount] = 0
,[fAmount] = case when sum(isnull(a.dogSum,0)) != 0 
				then sum(isnull(a.dogSum,0) * a.stavaOnSaleDate) / sum(isnull(a.dogSum,0)) / 100 else 0 end

from #PBR a
left join #loans d on a.dogNum=d.код

where upper(a.spr1) = upper('Автокредит')
--and upper(a.spr2) = upper('Повторники')
and d.[Сумма комиссионных продуктов снижающих ставку]>0
) l1
left join #RR c on c.Дата = @dateTo

--t61p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = isnull(l1.fAmount,0)
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then isnull(l1.fAmount,0) / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 61
,[tabName] = 'Объёмы выдач по Автокредиту по срокам и средневзв. сроки'
,[pokazatelNum] = 1
,[pokazatel] = '24 месяца'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and a.dogPeriodMonth=24
) l1
left join #RR c on c.Дата = @dateTo

--t61p2
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
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 61
,[tabName] = 'Объёмы выдач по Автокредиту по срокам и средневзв. сроки'
,[pokazatelNum] = 2
,[pokazatel] = '36 месяцев'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and a.dogPeriodMonth=36
) l1
left join #RR c on c.Дата = @dateTo

--t61p3
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
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 61
,[tabName] = 'Объёмы выдач по Автокредиту по срокам и средневзв. сроки'
,[pokazatelNum] = 3
,[pokazatel] = '48 месяцев'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and a.dogPeriodMonth=48
) l1
left join #RR c on c.Дата = @dateTo

--t61p4
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
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 61
,[tabName] = 'Объёмы выдач по Автокредиту по срокам и средневзв. сроки'
,[pokazatelNum] = 4
,[pokazatel] = '60 месяцев'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and a.dogPeriodMonth=60
) l1
left join #RR c on c.Дата = @dateTo

--t61p5
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
[tabNum] = 61
,[tabName] = 'Объёмы выдач по Автокредиту по срокам и средневзв. сроки'
,[pokazatelNum] = 5
,[pokazatel] = 'Средневзвешенный срок, мес.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * a.dogPeriodMonth) / sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Автокредит')
) l1

--t61p6
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
[tabNum] = 61
,[tabName] = 'Объёмы выдач по Автокредиту по срокам и средневзв. сроки'
,[pokazatelNum] = 6
,[pokazatel] = 'Новые'
,[pAmount] = 0
,[fAmount] = case when sum(isnull(a.dogSum,0)) != 0 
				then sum(isnull(a.dogSum,0) * a.dogPeriodMonth) / sum(isnull(a.dogSum,0)) else 0 end

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and  upper(a.spr2) = upper('Новые')
) l1

--t61p7
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
[tabNum] = 61
,[tabName] = 'Объёмы выдач по Автокредиту по срокам и средневзв. сроки'
,[pokazatelNum] = 7
,[pokazatel] = 'Докреды'
,[pAmount] = 0
,[fAmount] = case when sum(isnull(a.dogSum,0)) != 0 
					then sum(isnull(a.dogSum,0) * a.dogPeriodMonth) / sum(isnull(a.dogSum,0)) else 0 end

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and  upper(a.spr2) = upper('Докреды')
) l1

--t61p8
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
[tabNum] = 61
,[tabName] = 'Объёмы выдач по Автокредиту по срокам и средневзв. сроки'
,[pokazatelNum] = 8
,[pokazatel] = 'Повторники'
,[pAmount] = 0
,[fAmount] = case when sum(isnull(a.dogSum,0)) != 0 
				then sum(isnull(a.dogSum,0) * a.dogPeriodMonth) / sum(isnull(a.dogSum,0)) else 0 end

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and  upper(a.spr2) = upper('Повторники')
) l1

--t62p1
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
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 
				then l1.fAmount / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 62
,[tabName] = 'Объёмы и количество выдач по Автокредиту онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач онлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo

--t62p2
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
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 
				then l1.fAmount / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 62
,[tabName] = 'Объёмы и количество выдач по Автокредиту онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 2
,[pokazatel] = 'Объём выдач офлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.saleType) = upper('дистанционный')
) l1
left join #RR c on c.Дата = @dateTo

--t62p3
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
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 
			then l1.fAmount / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 62
,[tabName] = 'Объёмы и количество выдач по Автокредиту онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 3
,[pokazatel] = 'Кол-во выдач онлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo

--t62p4
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
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 
				then l1.fAmount / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 62
,[tabName] = 'Объёмы и количество выдач по Автокредиту онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 4
,[pokazatel] = 'Кол-во выдач офлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.saleType) = upper('дистанционный')
) l1
left join #RR c on c.Дата = @dateTo

--t62p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = case when isnull(b.fAmount,0) != 0 
				then l1.fAmount / isnull(b.fAmount,0) end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 and isnull(b.fAmount,0) != 0  
				then l1.fAmount / b.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 62
,[tabName] = 'Объёмы и количество выдач по Автокредиту онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 5
,[pokazatel] = 'Доля выдач онлайн по объёму, %'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Автокредит')) b on 1=1

--t62p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = case when isnull(b.fAmount,0) != 0 
				then l1.fAmount / isnull(b.fAmount,0) end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = case when isnull(b.fAmount,0) != 0 and isnull(c.[Доля для RR ПТС],0) != 0 
				then l1.fAmount / b.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 62
,[tabName] = 'Объёмы и количество выдач по Автокредиту онлайн / офлайн (Проверка БР)'
,[pokazatelNum] = 6
,[pokazatel] = 'Доля выдач онлайн по кол-ву, %'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.dogNum) as float)

from #PBR a
where upper(a.spr1) = upper('Автокредит')
and upper(a.saleType) = upper('онлайн')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('Автокредит')) b on 1=1

--t63p1
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
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 
				then l1.fAmount / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 63
,[tabName] = 'Объёмы и количество выдач по Автокредиту онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 1
,[pokazatel] = 'Объём выдач онлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(a.[Сумма])

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('Автокредит')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo

--t63p2
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
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 
				then l1.fAmount / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 63
,[tabName] = 'Объёмы и количество выдач по Автокредиту онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 2
,[pokazatel] = 'Объём выдач офлайн, млн р.'
,[pAmount] = 0
,[fAmount] = sum(a.[Сумма])

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('Автокредит')
and upper(a.[Дистанционная выдача]) = 0
) l1
left join #RR c on c.Дата = @dateTo

--t63p3
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
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 
				then l1.fAmount / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 63
,[tabName] = 'Объёмы и количество выдач по Автокредиту онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 3
,[pokazatel] = 'Кол-во выдач онлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.код) as float) 

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('Автокредит')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo

--t63p4
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
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 
				then l1.fAmount / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 63
,[tabName] = 'Объёмы и количество выдач по Автокредиту онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 4
,[pokazatel] = 'Кол-во выдач офлайн, шт.'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.код) as float) 

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('Автокредит')
and upper(a.[Дистанционная выдача]) = 0
) l1
left join #RR c on c.Дата = @dateTo

--t63p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = case when isnull(b.fAmount,0) != 0 
					then l1.fAmount / b.fAmount else 0 end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = case when isnull(b.fAmount,0) != 0 
				and isnull(c.[Доля для RR ПТС],0) != 0 
				then l1.fAmount / b.fAmount / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 63
,[tabName] = 'Объёмы и количество выдач по Автокредиту онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 5
,[pokazatel] = 'Доля выдач онлайн по объёму, %'
,[pAmount] = 0
,[fAmount] = sum(a.[Сумма])

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('Автокредит')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(a.[Сумма]) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('Автокредит')) b on 1=1

--t63p6
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = null
,[fAmount] = case when isnull(b.fAmount,0) != 0 
					then l1.fAmount / b.fAmount else 0 end
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = null
,[RR] = case when isnull(b.fAmount,0) != 0 
				and isnull(c.[Доля для RR ПТС],0) != 0 
				then l1.fAmount / b.fAmount / c.[Доля для RR ПТС] else 0 end

from(
select
[tabNum] = 63
,[tabName] = 'Объёмы и количество выдач по Автокредиту онлайн / офлайн (по данным КБ)'
,[pokazatelNum] = 6
,[pokazatel] = 'Доля выдач онлайн по кол-ву, %'
,[pAmount] = 0
,[fAmount] = cast(count(distinct a.код) as float) 

from #loans a
left join #pbr b on a.код=b.dogNum
where upper(b.spr1) = upper('Автокредит')
and upper(a.[Дистанционная выдача]) = 1
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct a.код) as float) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('Автокредит')) b on 1=1

end
