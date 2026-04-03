




CREATE PROCEDURE [finAnalytics].[repSalesPDNAll]
	@dateTo date
	--,@monthFrom date
AS
BEGIN

--t32p1
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
[tabNum] = 32
,[tabName] = 'Объём'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo

--t32p2
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
[tabNum] = 32
,[tabName] = 'Объём'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo

--t32p3
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
[tabNum] = 32
,[tabName] = 'Объём'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo

--t32p4
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
[tabNum] = 32
,[tabName] = 'Объём'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo

--t32p5
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
[tabNum] = 32
,[tabName] = 'Объём'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo

--t33p1
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
[tabNum] = 33
,[tabName] = 'Количество'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo

--t33p2
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
[tabNum] = 33
,[tabName] = 'Количество'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo

--t33p3
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
[tabNum] = 33
,[tabName] = 'Количество'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo

--t33p4
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
[tabNum] = 33
,[tabName] = 'Количество'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo

--t33p5
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
[tabNum] = 33
,[tabName] = 'Количество'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] = cast(count(Distinct isnull(a.dogNum,0)) as float)

from #PBR a
where upper(a.spr6) is not null
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo

--t34p1
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
[tabNum] = 34
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null
									and upper(a.nomenkGroup) not like upper('%Самозанят%')
									) c1 on 1=1

--t34p2
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
[tabNum] = 34
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null
													and upper(a.nomenkGroup) not like upper('%Самозанят%')
													) c1 on 1=1

--t34p3
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
[tabNum] = 34
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null
													and upper(a.nomenkGroup) not like upper('%Самозанят%')
													) c1 on 1=1

--t34p4
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
[tabNum] = 34
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null
													and upper(a.nomenkGroup) not like upper('%Самозанят%')
													) c1 on 1=1

--t34p5
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
[tabNum] = 34
,[tabName] = 'Доля по объему'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null
														and upper(a.nomenkGroup) not like upper('%Самозанят%')
														) c1 on 1=1

--t35p1
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
[tabNum] = 35
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН <=50')
																	and upper(a.nomenkGroup) not like upper('%Самозанят%')
																	) c1 on 1=1

--t35p2
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
[tabNum] = 35
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН >50% и <=80%')
																			and upper(a.nomenkGroup) not like upper('%Самозанят%')
																			) c1 on 1=1

--t35p3
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
[tabNum] = 35
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('ПДН >80%')
																	and upper(a.nomenkGroup) not like upper('%Самозанят%')
																	) c1 on 1=1

--t35p4
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
[tabNum] = 35
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
																				and upper(a.nomenkGroup) not like upper('%Самозанят%')
																				) c1 on 1=1

--t35p5
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
[tabNum] = 35
,[tabName] = 'Средний чек, тыс.руб.'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0))

from #PBR a
where upper(a.spr6) is not null
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) is not null
															and upper(a.nomenkGroup) not like upper('%Самозанят%')
															) c1 on 1=1

--t36p1
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
[tabNum] = 36
,[tabName] = 'Ставка'
,[pokazatelNum] = 1
,[pokazatel] = 'ПДН <=50'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН <=50')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН <=50')
													and upper(a.nomenkGroup) not like upper('%Самозанят%')
													) c1 on 1=1

--t36p2
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
[tabNum] = 36
,[tabName] = 'Ставка'
,[pokazatelNum] = 2
,[pokazatel] = 'ПДН >50% и <=80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН >50% и <=80%')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН >50% и <=80%')
													and upper(a.nomenkGroup) not like upper('%Самозанят%')
													) c1 on 1=1

--t36p3
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
[tabNum] = 36
,[tabName] = 'Ставка'
,[pokazatelNum] = 3
,[pokazatel] = 'ПДН >80%'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('ПДН >80%')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('ПДН >80%')
												and upper(a.nomenkGroup) not like upper('%Самозанят%')
												) c1 on 1=1

--t36p4
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
[tabNum] = 36
,[tabName] = 'Ставка'
,[pokazatelNum] = 4
,[pokazatel] = 'Без ПДН (до 10 т.р.)'
,[pAmount] = 0
,[fAmount] = sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) = upper('Без ПДН (до 10 т.р.)')
														and upper(a.nomenkGroup) not like upper('%Самозанят%')
														) c1 on 1=1

--t36p5
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
[tabNum] = 36
,[tabName] = 'Ставка'
,[pokazatelNum] = 5
,[pokazatel] = 'ИТОГО'
,[pAmount] = 0
,[fAmount] =  sum(isnull(a.dogSum,0) * isnull(a.stavaOnSaleDate,0)) / 100

from #PBR a
where upper(a.spr6) is not null
and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1
left join #RR c on c.Дата = @dateTo
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null
													and upper(a.nomenkGroup) not like upper('%Самозанят%')
													) c1 on 1=1


end
