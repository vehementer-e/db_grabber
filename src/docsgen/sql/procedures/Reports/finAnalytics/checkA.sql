

CREATE PROCEDURE [finAnalytics].[checkA]
	@repmonth date
	
AS
BEGIN
    DROP TABLE IF EXISTS #RESULT
CREATE TABLE #RESULT (
	blockName varchar(300) null,
	blockOrder int null,
	pokazatel varchar(200) null,
	pokazatelOrder int null,
	amount money null,
	pokazatelID varchar(5) null
)

insert INTO #RESULT
--t1p1
select
blockName = 'А3 (80 > ПДН > 50) Предоставление средств до 28.02.2022'
,blockOrder = 1
,pokazatel = 'Сумма требований'
,pokazatelOrder = 1
,amount = ISNULL(a.amount,0)
,pokazatelID = 't1p1'

from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab10'
and a.groupName='в т.ч. ПДН >50% и <=80%'
and a.blockName= 'Требования, всего, млн руб.'

insert INTO #RESULT
--t1p2
select
blockName = 'А3 (80 > ПДН > 50) Предоставление средств до 28.02.2022'
,blockOrder = 1
,pokazatel = 'Резервы по требованиям'
,pokazatelOrder = 2
,amount = ISNULL(a.amount,0) * -1
,pokazatelID = 't1p2'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab10'
and a.groupName='в т.ч. ПДН >50% и <=80%'
and a.blockName= 'Резерв, всего, млн руб.'

insert INTO #RESULT
--t2p1
select
blockName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.03.2022'
,blockOrder = 2
,pokazatel = 'Сумма требований'
,pokazatelOrder = 1
,amount = ISNULL(a.amount,0)
,pokazatelID = 't2p1'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab11'
and a.groupName='в т.ч. ПДН >50% и <=80%'
and a.blockName= 'Требования, всего, млн руб.'

insert INTO #RESULT
--t2p2
select
blockName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.03.2022'
,blockOrder = 2
,pokazatel = 'Резервы по требованиям'
,pokazatelOrder = 2
,amount = ISNULL(a.amount,0) * -1
,pokazatelID = 't2p2'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab11'
and a.groupName='в т.ч. ПДН >50% и <=80%'
and a.blockName= 'Резерв, всего, млн руб.'

insert INTO #RESULT
--t3p1
select
blockName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.10.2022'
,blockOrder = 3
,pokazatel = 'Сумма требований'
,pokazatelOrder = 1
,amount = ISNULL(a.amount,0)
,pokazatelID = 't3p1'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab12'
and a.groupName='в т.ч. ПДН >50% и <=80%'
and a.blockName= 'Требования, всего, млн руб.'

insert INTO #RESULT
--t3p2
select
blockName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.10.2022'
,blockOrder = 3
,pokazatel = 'Резервы по требованиям'
,pokazatelOrder = 2
,amount = ISNULL(a.amount,0) * -1
,pokazatelID = 't3p2'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab12'
and a.groupName='в т.ч. ПДН >50% и <=80%'
and a.blockName= 'Резерв, всего, млн руб.'

insert INTO #RESULT
--t4p1
select
blockName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.11.2022'
,blockOrder = 4
,pokazatel = 'Сумма требований'
,pokazatelOrder = 1
,amount = ISNULL(a.amount,0)
,pokazatelID = 't4p1'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab13'
and a.groupName='в т.ч. ПДН >50% и <=80%'
and a.blockName= 'Требования, всего, млн руб.'

insert INTO #RESULT
--t4p2
select
blockName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.11.2022'
,blockOrder = 4
,pokazatel = 'Резервы по требованиям'
,pokazatelOrder = 2
,amount = ISNULL(a.amount,0) * -1
,pokazatelID = 't4p2'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab13'
and a.groupName='в т.ч. ПДН >50% и <=80%'
and a.blockName= 'Резерв, всего, млн руб.'

insert INTO #RESULT
--t5p1
select
blockName = 'А4 (ПДН > 80) Предоставление средств до 28.02.2022'
,blockOrder = 5
,pokazatel = 'Сумма требований'
,pokazatelOrder = 1
,amount = ISNULL(a.amount,0)
,pokazatelID = 't5p1'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab10'
and a.groupName='в т.ч. ПДН >80%'
and a.blockName= 'Требования, всего, млн руб.'

insert INTO #RESULT
--t5p2
select
blockName = 'А4 (ПДН > 80) Предоставление средств до 28.02.2022'
,blockOrder = 5
,pokazatel = 'Резервы по требованиям'
,pokazatelOrder = 2
,amount = ISNULL(a.amount,0) * -1
,pokazatelID = 't5p2'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab10'
and a.groupName='в т.ч. ПДН >80%'
and a.blockName= 'Резерв, всего, млн руб.'

insert INTO #RESULT
--t6p1
select
blockName = 'А4 (ПДН > 80) Предоставление средств с 01.03.2022'
,blockOrder = 6
,pokazatel = 'Сумма требований'
,pokazatelOrder = 1
,amount = ISNULL(a.amount,0)
,pokazatelID = 't6p1'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab11'
and a.groupName='в т.ч. ПДН >80%'
and a.blockName= 'Требования, всего, млн руб.'

insert INTO #RESULT
--t6p2
select
blockName = 'А4 (ПДН > 80) Предоставление средств с 01.03.2022'
,blockOrder = 6
,pokazatel = 'Резервы по требованиям'
,pokazatelOrder = 2
,amount = ISNULL(a.amount,0) * -1
,pokazatelID = 't6p2'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab11'
and a.groupName='в т.ч. ПДН >80%'
and a.blockName= 'Резерв, всего, млн руб.'

insert INTO #RESULT
--t7p1
select
blockName = 'А4 (ПДН > 80) Предоставление средств с 01.10.2022'
,blockOrder = 7
,pokazatel = 'Сумма требований'
,pokazatelOrder = 1
,amount = ISNULL(a.amount,0)
,pokazatelID = 't7p1'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab12'
and a.groupName='в т.ч. ПДН >80%'
and a.blockName= 'Требования, всего, млн руб.'

insert INTO #RESULT
--t7p2
select
blockName = 'А4 (ПДН > 80) Предоставление средств с 01.10.2022'
,blockOrder = 7
,pokazatel = 'Резервы по требованиям'
,pokazatelOrder = 2
,amount = ISNULL(a.amount,0) * -1
,pokazatelID = 't7p2'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab12'
and a.groupName='в т.ч. ПДН >80%'
and a.blockName= 'Резерв, всего, млн руб.'

insert INTO #RESULT
--t8p1
select
blockName = 'А4 (ПДН > 80) Предоставление средств с 01.11.2022'
,blockOrder = 8
,pokazatel = 'Сумма требований'
,pokazatelOrder = 1
,amount = ISNULL(a.amount,0)
,pokazatelID = 't8p1'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab13'
and a.groupName='в т.ч. ПДН >80%'
and a.blockName= 'Требования, всего, млн руб.'

insert INTO #RESULT
--t8p2
select
blockName = 'А4 (ПДН > 80) Предоставление средств с 01.11.2022'
,blockOrder = 8
,pokazatel = 'Резервы по требованиям'
,pokazatelOrder = 2
,amount = ISNULL(a.amount,0) * -1
,pokazatelID = 't8p2'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab13'
and a.groupName='в т.ч. ПДН >80%'
and a.blockName= 'Резерв, всего, млн руб.'

insert INTO #RESULT
--t9p1
select
blockName = 'А5 (ПДН не рассчитывается)'
,blockOrder = 9
,pokazatel = 'Сумма требований'
,pokazatelOrder = 1
,amount = ISNULL(a.amount,0)
,pokazatelID = 't9p1'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab13'--'Tab9'
and a.groupName='в т.ч. без ПДН (до 10 тыс.руб.)'
and a.blockName= 'Требования, всего, млн руб.'

insert INTO #RESULT
--t9p2
select
blockName = 'А5 (ПДН не рассчитывается)'
,blockOrder = 9
,pokazatel = 'Резервы по требованиям'
,pokazatelOrder = 2
,amount = ISNULL(a.amount,0) * -1
,pokazatelID = 't9p2'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab13'--'Tab9'
and a.groupName='в т.ч. без ПДН (до 10 тыс.руб.)'
and a.blockName= 'Резерв, всего, млн руб.'

insert INTO #RESULT
--t10p1
select
blockName = 'А2'
,blockOrder = 10
,pokazatel = 'Сумма требований'
,pokazatelOrder = 1
,amount = isnull(sum(ISNULL(a.amount,0)),0)
,pokazatelID = 't10p1'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab14'
--and a.groupName='в т.ч. без ПДН (до 10 тыс.руб.)'
and a.blockName= 'Требования, всего, млн руб.'

insert INTO #RESULT
--t10p2
select
blockName = 'А2'
,blockOrder = 10
,pokazatel = 'Резервы по требованиям'
,pokazatelOrder = 2
,amount = isnull(sum(ISNULL(a.amount,0)),0) * -1
,pokazatelID = 't10p2'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab14'
--and a.groupName='в т.ч. без ПДН (до 10 тыс.руб.)'
and a.blockName= 'Резерв, всего, млн руб.'

insert INTO #RESULT
--t11p1
select
blockName = 'Доп.раздел для сверки с ОСВ (ПДН <= 50) '
,blockOrder = 11
,pokazatel = 'Сумма требований'
,pokazatelOrder = 1
,amount = ISNULL(a.amount,0)
,pokazatelID = 't11p1'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab9'
and a.groupName='в т.ч. ПДН <=50%'
and a.blockName= 'Требования, всего, млн руб.'

insert INTO #RESULT
--t11p2
select
blockName = 'Доп.раздел для сверки с ОСВ (ПДН <= 50) '
,blockOrder = 11
,pokazatel = 'Резервы по требованиям'
,pokazatelOrder = 2
,amount = ISNULL(a.amount,0) * -1
,pokazatelID = 't11p2'
from dwh2.finanalytics.repPDN a
where 
a.Repdate=eomonth(@repmonth)
and a.tabName='Tab9'
and a.groupName='в т.ч. ПДН <=50%'
and a.blockName= 'Резерв, всего, млн руб.'

insert INTO #RESULT
--t12p1
select
blockName = 'Сверка с ОСВ'
,blockOrder = 12
,pokazatel = 'Сумма требований'
,pokazatelOrder = 1
,amount = l1.t1Amount - l1.t2Amount
,pokazatelID = 't12p1'
from (
select 
t1Amount = (select SUM(amount) from #RESULT where pokazatelID in ('t1p1','t2p1','t3p1','t4p1','t5p1','t6p1','t7p1','t8p1','t9p1','t11p1')) 
,t2Amount = (
select
--SUM(isnull(restOUT_BU,0))
SUM(isnull(restOUT_NU,0))
from dwh2.finAnalytics.OSV_MONTHLY a
where a.repmonth=@repmonth
and 
(
a.acc2order in ('48701','48702','48801','48802','49401','49402')
or
(a.acc2order='60323' and upper(a.subconto3)=upper('Пени'))
))) l1


insert INTO #RESULT
--t12p2
select
blockName = 'Сверка с ОСВ'
,blockOrder = 12
,pokazatel = 'Резервы по требованиям'
,pokazatelOrder = 2
,amount = l1.t1Amount + l1.t2Amount
,pokazatelID = 't12p2'
from (
select 
t1Amount = (select SUM(amount) from #RESULT where pokazatelID in ('t1p2','t2p2','t3p2','t4p2','t5p2','t6p2','t7p2','t8p2','t9p2','t11p2')) 
,t2Amount = (
select
--SUM(isnull(case when a.acc2order='60323' then restOUT_NU*-1 else restOUT_NU*-1 end,0))
SUM(isnull(restOUT_NU,0))*-1
from dwh2.finAnalytics.OSV_MONTHLY a
where a.repmonth=@repmonth
and 
(
a.acc2order in ('48710','48810','49410','60324')
or
(a.acc2order='60323' and upper(a.subconto3)=upper('Мошенники'))
)
)) l1

select * from #RESULT


END
