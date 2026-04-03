






CREATE PROCEDURE [finAnalytics].[repSalesPDN_AUTO]
	@dateTo date
	--,@monthFrom date
AS
BEGIN

--t69p1
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
[tabNum] = 69
,[tabName] = 'Объём Автокредит'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t69p2
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
[tabNum] = 69
,[tabName] = 'Объём Автокредит'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t69p3
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
[tabNum] = 69
,[tabName] = 'Объём Автокредит'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t69p4
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
[tabNum] = 69
,[tabName] = 'Объём Автокредит'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t69p5
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
[tabNum] = 69
,[tabName] = 'Объём Автокредит'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t70p1
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
[tabNum] = 70
,[tabName] = 'Количество Автокредит'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t70p2
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
[tabNum] = 70
,[tabName] = 'Количество Автокредит'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t70p3
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
[tabNum] = 70
,[tabName] = 'Количество Автокредит'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t70p4
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
[tabNum] = 70
,[tabName] = 'Количество Автокредит'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t70p5
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
[tabNum] = 70
,[tabName] = 'Количество Автокредит'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) is not null
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo

--t71p1
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
[tabNum] = 71
,[tabName] = 'Доля по объему Автокредит'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t71p2
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
[tabNum] = 71
,[tabName] = 'Доля по объему Автокредит'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t71p3
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
[tabNum] = 71
,[tabName] = 'Доля по объему Автокредит'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t71p4
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
[tabNum] = 71
,[tabName] = 'Доля по объему Автокредит'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t71p5
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
[tabNum] = 71
,[tabName] = 'Доля по объему Автокредит'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t72p1
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
[tabNum] = 72
,[tabName] = 'Средний чек Автокредит, тыс.руб.'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН <=50') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t72p2
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
[tabNum] = 72
,[tabName] = 'Средний чек Автокредит, тыс.руб.'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН >50% и <=80%') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t72p3
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
[tabNum] = 72
,[tabName] = 'Средний чек Автокредит, тыс.руб.'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН >80%') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t72p4
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
[tabNum] = 72
,[tabName] = 'Средний чек Автокредит, тыс.руб.'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t72p5
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
[tabNum] = 72
,[tabName] = 'Средний чек Автокредит, тыс.руб.'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t73p1
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
[tabNum] = 73
,[tabName] = 'Ставка Автокредит'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН <=50') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t73p2
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
[tabNum] = 73
,[tabName] = 'Ставка Автокредит'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН >50% и <=80%') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t73p3
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
[tabNum] = 73
,[tabName] = 'Ставка Автокредит'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН >80%') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t73p4
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
[tabNum] = 73
,[tabName] = 'Ставка Автокредит'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)') and upper(a.spr1) = upper('Автокредит')) c1 on 1=1

--t73p5
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
[tabNum] = 73
,[tabName] = 'Ставка Автокредит'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) is not null
and upper(a.spr1) = upper('Автокредит')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) = upper('Автокредит')) c1 on 1=1


end
