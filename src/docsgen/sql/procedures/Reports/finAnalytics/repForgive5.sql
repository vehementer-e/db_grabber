






CREATE PROCEDURE [finAnalytics].[repForgive5]
	@repmonth date
	with recompile

AS
BEGIN

select
nomenkGR = 'Всего'
,colNum = 1
,rowNum = 1
,rowName = 'Списано по 377-ФЗ (сумма)'
,sumAmount = isnull(SUM([Сумма проводки]),0)
from dwh2.finAnalytics.repForgive4
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'

union all

select
nomenkGR = 'ПТС'
,colNum = 2
,rowNum = 1
,rowName = 'Списано по 377-ФЗ (сумма)'
,sumAmount = isnull(SUM([Сумма проводки]),0)
from dwh2.finAnalytics.repForgive4
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
and [Номенклатурная группа] = 'ПТС'

union all

select
nomenkGR = 'IL'
,colNum = 3
,rowNum = 1
,rowName = 'Списано по 377-ФЗ (сумма)'
,sumAmount = isnull(SUM([Сумма проводки]),0)
from dwh2.finAnalytics.repForgive4
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
and [Номенклатурная группа] = 'IL'

union all

select
nomenkGR = 'PDL'
,colNum = 4
,rowNum = 1
,rowName = 'Списано по 377-ФЗ (сумма)'
,sumAmount = isnull(SUM([Сумма проводки]),0)
from dwh2.finAnalytics.repForgive4
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
and [Номенклатурная группа] = 'PDL'

union all

select
nomenkGR = 'Автокредит'
,colNum = 5
,rowNum = 1
,rowName = 'Списано по 377-ФЗ (сумма)'
,sumAmount = isnull(SUM([Сумма проводки]),0)
from dwh2.finAnalytics.repForgive4
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
and [Номенклатурная группа] = 'Автокредит'

union all

select
nomenkGR = 'Big Installment'
,colNum = 6
,rowNum = 1
,rowName = 'Списано по 377-ФЗ (сумма)'
,sumAmount = isnull(SUM([Сумма проводки]),0)
from dwh2.finAnalytics.repForgive4
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
and [Номенклатурная группа] = 'Big Installment'

union all

select
nomenkGR = 'БЗ'
,colNum = 7
,rowNum = 1
,rowName = 'Списано по 377-ФЗ (сумма)'
,sumAmount = isnull(SUM([Сумма проводки]),0)
from dwh2.finAnalytics.repForgive4
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
and [Номенклатурная группа] = 'БЗ'

union all

select
l1.nomenkGR
,l1.colNum
,rowNum = 1
,rowName = 'Списано по 377-ФЗ (сумма)'
,sumAmount = l1.sumAmount-l2.sumAmount

from (
select
nomenkGR = 'Контроль'
,colNum = 8
,sumAmount = isnull(SUM([Сумма проводки]),0)
,dogCount = ISNULL(count(distinct dogNum),0)
from dwh2.finAnalytics.repForgive4 
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
) l1

left join (
select
nomenkGR = 'Контроль'
,colNum = 8
,sumAmount = isnull(SUM([Сумма проводки]),0)
,dogCount = ISNULL(count(distinct dogNum),0)
from dwh2.finAnalytics.repForgive4 
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
and [Номенклатурная группа] is not null
) l2 on 1=1

union all

select
nomenkGR = 'Всего'
,colNum = 1
,rowNum = 2
,rowName = 'Списано по 377-ФЗ (кол-во)'
,dogCount = ISNULL(count(distinct dogNum),0)
from dwh2.finAnalytics.repForgive4
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'

union all

select
nomenkGR = 'ПТС'
,colNum = 2
,rowNum = 2
,rowName = 'Списано по 377-ФЗ (кол-во)'
,dogCount = ISNULL(count(distinct dogNum),0)
from dwh2.finAnalytics.repForgive4
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
and [Номенклатурная группа] = 'ПТС'

union all

select
nomenkGR = 'IL'
,colNum = 3
,rowNum = 2
,rowName = 'Списано по 377-ФЗ (кол-во)'
,dogCount = ISNULL(count(distinct dogNum),0)
from dwh2.finAnalytics.repForgive4
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
and [Номенклатурная группа] = 'IL'

union all

select
nomenkGR = 'PDL'
,colNum = 4
,rowNum = 2
,rowName = 'Списано по 377-ФЗ (кол-во)'
,dogCount = ISNULL(count(distinct dogNum),0)
from dwh2.finAnalytics.repForgive4
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
and [Номенклатурная группа] = 'PDL'

union all

select
nomenkGR = 'Автокредит'
,colNum = 5
,rowNum = 2
,rowName = 'Списано по 377-ФЗ (кол-во)'
,dogCount = ISNULL(count(distinct dogNum),0)
from dwh2.finAnalytics.repForgive4
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
and [Номенклатурная группа] = 'Автокредит'

union all

select
nomenkGR = 'Big Installment'
,colNum = 6
,rowNum = 2
,rowName = 'Списано по 377-ФЗ (кол-во)'
,dogCount = ISNULL(count(distinct dogNum),0)
from dwh2.finAnalytics.repForgive4
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
and [Номенклатурная группа] = 'Big Installment'

union all

select
nomenkGR = 'БЗ'
,colNum = 7
,rowNum = 2
,rowName = 'Списано по 377-ФЗ (кол-во)'
,dogCount = ISNULL(count(distinct dogNum),0)
from dwh2.finAnalytics.repForgive4
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
and [Номенклатурная группа] = 'БЗ'

union all

select
l1.nomenkGR
,l1.colNum
,rowNum = 2
,rowName = 'Списано по 377-ФЗ (кол-во)'
,dogCount = l1.dogCount - l2.dogCount

from (
select
nomenkGR = 'Контроль'
,colNum = 8
,sumAmount = isnull(SUM([Сумма проводки]),0)
,dogCount = ISNULL(count(distinct dogNum),0)
from dwh2.finAnalytics.repForgive4 
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
) l1

left join (
select
nomenkGR = 'Контроль'
,colNum = 8
,sumAmount = isnull(SUM([Сумма проводки]),0)
,dogCount = ISNULL(count(distinct dogNum),0)
from dwh2.finAnalytics.repForgive4 
where repmonth = @repmonth	
and Символ = 'Списание задолженности размещенных средств (проценты по 377-ФЗ) (55606, сч.71802)'
and [Номенклатурная группа] is not null
) l2 on 1=1


END
