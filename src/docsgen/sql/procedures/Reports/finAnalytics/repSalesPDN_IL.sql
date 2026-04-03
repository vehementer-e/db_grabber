






CREATE PROCEDURE [finAnalytics].[repSalesPDN_IL]
	@dateTo date
	--,@monthFrom date
AS
BEGIN

--t42p1
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
,[tekPRC] = NUll--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 42
,[tabName] = 'Объём'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo

--t42p2
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
,[tekPRC] = NUll--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 42
,[tabName] = 'Объём'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo

--t42p3
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
,[tekPRC] = NUll--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 42
,[tabName] = 'Объём'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo

--t42p4
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
,[tekPRC] = NUll--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 42
,[tabName] = 'Объём'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo

--t42p5
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
,[tekPRC] = NUll--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 42
,[tabName] = 'Объём'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo

--t43p1
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
,[RR] =case when isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 43
,[tabName] = 'Количество'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo

--t43p2
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
,[tekPRC] = NULL--case when isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] end 
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 43
,[tabName] = 'Количество'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo

--t43p3
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
[tabNum] = 43
,[tabName] = 'Количество'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo

--t43p4
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
[tabNum] = 43
,[tabName] = 'Количество'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo

--t43p5
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
[tabNum] = 43
,[tabName] = 'Количество'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) is not null
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo

--t44p1
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
[tabNum] = 44
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) in (upper('Installment'),upper('PDL'))) c1 on 1=1

--t44p2
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
[tabNum] = 44
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) in (upper('Installment'),upper('PDL'))) c1 on 1=1

--t44p3
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
[tabNum] = 44
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) in (upper('Installment'),upper('PDL'))) c1 on 1=1

--t44p4
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
[tabNum] = 44
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) in (upper('Installment'),upper('PDL'))) c1 on 1=1

--t44p5
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
[tabNum] = 44
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) in (upper('Installment'),upper('PDL'))) c1 on 1=1

--t45p1
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
[tabNum] = 45
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН <=50') and upper(a.spr1) in (upper('Installment'),upper('PDL'))) c1 on 1=1

--t45p2
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
[tabNum] = 45
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН >50% и <=80%') and upper(a.spr1) in (upper('Installment'),upper('PDL'))) c1 on 1=1

--t45p3
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
[tabNum] = 45
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН >80%') and upper(a.spr1) in (upper('Installment'),upper('PDL'))) c1 on 1=1

--t45p4
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
[tabNum] = 45
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)') and upper(a.spr1) in (upper('Installment'),upper('PDL'))) c1 on 1=1

--t45p5
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
[tabNum] = 45
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) in (upper('Installment'),upper('PDL'))) c1 on 1=1

--t46p1
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
[tabNum] = 46
,[tabName] = 'Ставка'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН <=50') and upper(a.spr1) in (upper('Installment'),upper('PDL'))) c1 on 1=1

--t46p2
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
[tabNum] = 46
,[tabName] = 'Ставка'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН >50% и <=80%') and upper(a.spr1) in (upper('Installment'),upper('PDL'))) c1 on 1=1

--t46p3
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
[tabNum] = 46
,[tabName] = 'Ставка'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН >80%') and upper(a.spr1) in (upper('Installment'),upper('PDL'))) c1 on 1=1

--t46p4
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
[tabNum] = 46
,[tabName] = 'Ставка'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)') and upper(a.spr1) in (upper('Installment'),upper('PDL'))) c1 on 1=1

--t46p5
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
[tabNum] = 46
,[tabName] = 'Ставка'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) is not null
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.spr1) in (upper('Installment'),upper('PDL'))) c1 on 1=1

--t47p1
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
,[tekPRC] = NUll--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 47
,[tabName] = 'Объём'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo

--t47p2
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
,[tekPRC] = NUll--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 47
,[tabName] = 'Объём'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo

--t47p3
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
,[tekPRC] = NUll--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 47
,[tabName] = 'Объём'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo

--t47p4
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
,[tekPRC] = NUll--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 47
,[tabName] = 'Объём'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo

--t47p5
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
,[tekPRC] = NUll--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 47
,[tabName] = 'Объём'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo

--t48p1
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
,[RR] =case when isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 48
,[tabName] = 'Количество'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo

--t48p2
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
,[tekPRC] = NULL--case when isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] end 
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 48
,[tabName] = 'Количество'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo

--t48p3
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
[tabNum] = 48
,[tabName] = 'Количество'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo

--t48p4
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
[tabNum] = 48
,[tabName] = 'Количество'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo

--t48p5
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
[tabNum] = 48
,[tabName] = 'Количество'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) is not null
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo

--t49p1
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
[tabNum] = 49
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.isDogPoruch) like UPPER('%самоход%')) c1 on 1=1

--t49p2
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
[tabNum] = 49
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.isDogPoruch) like UPPER('%самоход%')) c1 on 1=1

--t49p3
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
[tabNum] = 49
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.isDogPoruch) like UPPER('%самоход%')) c1 on 1=1

--t49p4
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
[tabNum] = 49
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.isDogPoruch) like UPPER('%самоход%')) c1 on 1=1

--t49p5
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
[tabNum] = 49
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.isDogPoruch) like UPPER('%самоход%')) c1 on 1=1

--t50p1
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
[tabNum] = 50
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН <=50') and upper(a.isDogPoruch) like UPPER('%самоход%')) c1 on 1=1

--t50p2
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
[tabNum] = 50
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН >50% и <=80%') and upper(a.isDogPoruch) like UPPER('%самоход%')) c1 on 1=1

--t50p3
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
[tabNum] = 50
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН >80%') and upper(a.isDogPoruch) like UPPER('%самоход%')) c1 on 1=1

--t50p4
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
[tabNum] = 50
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)') and upper(a.isDogPoruch) like UPPER('%самоход%')) c1 on 1=1

--t50p5
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
[tabNum] = 50
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) is not null and upper(a.isDogPoruch) like UPPER('%самоход%')) c1 on 1=1

--t51p1
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
[tabNum] = 51
,[tabName] = 'Ставка'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН <=50') and upper(a.isDogPoruch) like UPPER('%самоход%')) c1 on 1=1

--t51p2
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
[tabNum] = 51
,[tabName] = 'Ставка'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН >50% и <=80%') and upper(a.isDogPoruch) like UPPER('%самоход%')) c1 on 1=1

--t51p3
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
[tabNum] = 51
,[tabName] = 'Ставка'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН >80%') and upper(a.isDogPoruch) like UPPER('%самоход%')) c1 on 1=1

--t51p4
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
[tabNum] = 51
,[tabName] = 'Ставка'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)') and upper(a.isDogPoruch) like UPPER('%самоход%')) c1 on 1=1

--t51p5
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
[tabNum] = 51
,[tabName] = 'Ставка'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) is not null
--and upper(a.spr1) in (upper('Installment'),upper('PDL'))
and upper(a.isDogPoruch) like UPPER('%самоход%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.isDogPoruch) like UPPER('%самоход%')) c1 on 1=1

--t52p1
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
,[tekPRC] = NUll--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 52
,[tabName] = 'Объём'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
 or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo

--t52p2
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
,[tekPRC] = NUll--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 52
,[tabName] = 'Объём'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
 or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo

--t52p3
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
,[tekPRC] = NUll--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 52
,[tabName] = 'Объём'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or  upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo

--t52p4
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
,[tekPRC] = NUll--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 52
,[tabName] = 'Объём'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo

--t52p5
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
,[tekPRC] = NUll--case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 52
,[tabName] = 'Объём'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo

--t53p1
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
,[RR] =case when isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 53
,[tabName] = 'Количество'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo

--t53p2
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
,[tekPRC] = NULL--case when isnull(c.[Доля для RR ПТС],0) != 0 then  l1.fAmount / c.[Доля для RR ПТС] end 
,[RR] = case when isnull(c.[Доля для RR ПТС],0) != 0 then l1.fAmount / c.[Доля для RR ПТС] end

from(
select
[tabNum] = 53
,[tabName] = 'Количество'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo

--t53p3
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
[tabNum] = 53
,[tabName] = 'Количество'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo

--t53p4
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
[tabNum] = 53
,[tabName] = 'Количество'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo

--t53p5
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
[tabNum] = 53
,[tabName] = 'Количество'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) is not null
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo

--t54p1
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
[tabNum] = 54
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))) c1 on 1=1

--t54p2
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
[tabNum] = 54
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))) c1 on 1=1

--t54p3
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
[tabNum] = 54
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))) c1 on 1=1

--t54p4
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
[tabNum] = 54
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))) c1 on 1=1

--t54p5
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
[tabNum] = 54
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))) c1 on 1=1

--t55p1
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
[tabNum] = 55
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН <=50') and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))) c1 on 1=1

--t55p2
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
[tabNum] = 55
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН >50% и <=80%') and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))) c1 on 1=1

--t55p3
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
[tabNum] = 55
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН >80%') and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))) c1 on 1=1

--t55p4
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
[tabNum] = 55
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)') and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))) c1 on 1=1

--t55p5
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
[tabNum] = 55
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) is not null and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))) c1 on 1=1

--t56p1
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
[tabNum] = 56
,[tabName] = 'Ставка'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН <=50') and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))) c1 on 1=1

--t56p2
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
[tabNum] = 56
,[tabName] = 'Ставка'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН >50% и <=80%') and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))) c1 on 1=1

--t56p3
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
[tabNum] = 56
,[tabName] = 'Ставка'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН >80%') and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))) c1 on 1=1

--t56p4
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
[tabNum] = 56
,[tabName] = 'Ставка'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)') and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))) c1 on 1=1

--t56p5
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
[tabNum] = 56
,[tabName] = 'Ставка'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) is not null
and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and (upper(a.spr1) in (upper('Installment'),upper('PDL'))
	or upper(a.isDogPoruch) like UPPER('%самоход%'))) c1 on 1=1


end
