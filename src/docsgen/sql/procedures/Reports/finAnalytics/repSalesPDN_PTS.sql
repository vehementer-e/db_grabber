





CREATE PROCEDURE [finAnalytics].[repSalesPDN_PTS]
	@dateTo date
	--,@monthFrom date
AS
BEGIN

--t37p1
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 37
,[tabName] = 'Объём'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo

--t37p2
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 37
,[tabName] = 'Объём'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo

--t37p3
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 37
,[tabName] = 'Объём'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo

--t37p4
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 37
,[tabName] = 'Объём'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo

--t37p5
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 37
,[tabName] = 'Объём'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo

--t38p1
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 38
,[tabName] = 'Количество'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo

--t38p2
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] =case when isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 38
,[tabName] = 'Количество'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo

--t38p3
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
,[tekPRC] =case when isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 38
,[tabName] = 'Количество'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo

--t38p4
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 38
,[tabName] = 'Количество'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo

--t38p5
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
,[tekPRC] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 38
,[tabName] = 'Количество'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) is not null
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo

--t39p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0)!=0 then  l1.fAmount / c1.fAmount end 
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 39
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) = upper('ПТС')
																and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
																) c1 on 1=1

--t39p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0)!=0 then  l1.fAmount / c1.fAmount end 
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 39
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) = upper('ПТС')
															and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
															) c1 on 1=1

--t39p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0)!=0 then  l1.fAmount / c1.fAmount end 
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 39
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) = upper('ПТС')
														and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
														) c1 on 1=1

--t39p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0)!=0 then  l1.fAmount / c1.fAmount end 
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 39
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) = upper('ПТС')
															and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
															) c1 on 1=1

--t39p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0)!=0 then  l1.fAmount / c1.fAmount end 
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 39
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) = upper('ПТС')
														and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
														) c1 on 1=1

--t40p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0)!=0 then  l1.fAmount / c1.fAmount end 
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 40
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН <=50') 
														and upper(a.spr1) = upper('ПТС')
														and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
														) c1 on 1=1

--t40p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0)!=0 then  l1.fAmount / c1.fAmount end 
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 40
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН >50% и <=80%') 
													and upper(a.spr1) = upper('ПТС')
													and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
													) c1 on 1=1

--t40p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0)!=0 then  l1.fAmount / c1.fAmount end 
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 40
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН >80%') 
														and upper(a.spr1) = upper('ПТС')
														and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
														) c1 on 1=1

--t40p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0)!=0 then  l1.fAmount / c1.fAmount end 
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 40
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)') 
												and upper(a.spr1) = upper('ПТС')
												and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
												) c1 on 1=1

--t40p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0)!=0 then  l1.fAmount / c1.fAmount end 
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 40
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) is not null 
															and upper(a.spr1) = upper('ПТС')
															and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
															) c1 on 1=1

--t41p1
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0)!=0 then  l1.fAmount / c1.fAmount end 
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 41
,[tabName] = 'Ставка'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН <=50') 
														and upper(a.spr1) = upper('ПТС')
														and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
														) c1 on 1=1

--t41p2
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0)!=0 then  l1.fAmount / c1.fAmount end 
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 41
,[tabName] = 'Ставка'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН >50% и <=80%') 
														and upper(a.spr1) = upper('ПТС')
														and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
														) c1 on 1=1

--t41p3
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0)!=0 then  l1.fAmount / c1.fAmount end 
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 41
,[tabName] = 'Ставка'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН >80%') 
														and upper(a.spr1) = upper('ПТС')
														and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
														) c1 on 1=1

--t41p4
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0)!=0 then  l1.fAmount / c1.fAmount end 
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 41
,[tabName] = 'Ставка'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)') 
													and upper(a.spr1) = upper('ПТС')
													and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
													) c1 on 1=1

--t41p5
insert into #SALES
(tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR)
select
[tabNum] = l1.tabNum
,[tabName] = l1.tabName
,[pokazatelNum] = l1.pokazatelNum
,[pokazatel] = l1.pokazatel
,[pAmount] = NULL
,[fAmount] = case when isnull(c1.fAmount,0)!=0 then  l1.fAmount / c1.fAmount end 
,[rrDolya] = c.[Доля для RR ПТС]
,[tekPRC] = NULL
,[RR] = NULL

from(
select
[tabNum] = 41
,[tabName] = 'Ставка'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) is not null
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null 
													and upper(a.spr1) = upper('ПТС')
													and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
													) c1 on 1=1


end
