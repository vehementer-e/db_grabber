
CREATE PROCEDURE [finAnalytics].[repSales]
    @monthFrom date,
    @monthTo date,
    @dsSelector int
AS
BEGIN

declaRE @DateTo date = (select
                        maxRepDate = max(l1.maxRepDate) 
                        from (
                        select
                        maxRepDate = max(repdate)--greatest(max(repdate),eomonth(@MonthTo))
                        from dwh2.finAnalytics.PBR_WEEKLY a

                        where a.REPDATE > (select eomonth(max(b.repmonth)) from dwh2.finAnalytics.PBR_MONTHLY b) 
                        and a.REPDATE <= eomonth(@MonthTo)
                        and a.saleDate > (select eomonth(max(b.repmonth)) from dwh2.finAnalytics.PBR_MONTHLY b) 
                        and a.saleDate <= eomonth(@MonthTo)
                        union all
                        select maxRepDate =(select eomonth(max(b.repmonth)) from dwh2.finAnalytics.PBR_MONTHLY b
                        where b.repmonth<=@MonthTo) 
                        ) l1
                        )--eomonth(@MonthTo)


--select @DateTo

drop table if exists #plan
CREATE TABLE #plan (
product varchar(300) not null
,pCount float null
,pAmount float null
,pAVGChaeck float null
,pAVGPRC float null
)

insert into #plan
select
product
,pCount	= sum(isnull(pCount,0))
,pAmount = sum(isnull(pAmount,0))	
,pAVGChaeck	= case when sum(isnull(pCount,0)) != 0 then sum(pAmount) / sum(isnull(pCount,0)) else 0 end
,pAVGPRC = case when sum(isnull(pAmount,0)) !=0 then sum(isnull(pAVGPRC,0) * isnull(pAmount,0)) / sum(isnull(pAmount,0)) else 0 end


from dwh2.finAnalytics.SPR_repSalesPlanMain a
where a.repmonth between @monthFrom and eomonth(@dateTo)

group by product

--select * from #plan


drop table if exists #loans
CREATE TABLE #loans (
[код] nvarchar(28)	
,[CRMClientGUID] char(36)
,[Дата договора]datetime2
,[Сумма] numeric
,[Адрес проживания CRM] nvarchar(300)	
,[Срок] numeric
,[Агент партнер] nvarchar(200)	
,[product] varchar(27)
,[Сумма комиссионных продуктов снижающих ставку] float
,[Вид займа] nvarchar(max)
,[Дата выдачи] datetime2
,[Сумма расторжений по КП] float
,[ПСК текущая] numeric
,[ПСК первоначальная] numeric
,[Текущая процентная ставка] numeric
,[Первая процентная ставка] numeric
,[канал] nvarchar(510)
,[Признак КП снижающий ставку] int
,[Сумма комиссионных продуктов] float
,[Сумма комиссионных продуктов Carmoney] float
,[Сумма комиссионных продуктов Carmoney Net] float
,[CP_info] nvarchar(4000)	
,[Дата обновления записи по займу] datetime
,[Дистанционная выдача] int
,[checkDouble] int
)

INSERT INTO #loans 
(код,CRMClientGUID,[Дата договора],[Сумма],[Адрес проживания CRM],[Срок],[Агент партнер],[product],[Сумма комиссионных продуктов снижающих ставку],
[Вид займа],[Дата выдачи],[Сумма расторжений по КП],[ПСК текущая],[ПСК первоначальная],[Текущая процентная ставка],[Первая процентная ставка],[канал]
,[Признак КП снижающий ставку],[Сумма комиссионных продуктов],[Сумма комиссионных продуктов Carmoney],[Сумма комиссионных продуктов Carmoney Net]
,[CP_info],[Дата обновления записи по займу],[Дистанционная выдача])

EXEC Analytics._birs.loans_for_finance @MonthFrom, @dateTo

merge into #loans t1
using(
select
код
,[rn] = ROW_NUMBER() over (Partition by код order by код)
from #loans
) t2 on (t1.код=t2.код)
when matched then update
set t1.[checkDouble] = t2.rn;

delete from #loans where cast([Дата выдачи] as date) not between @MonthFrom and @dateTo

--select /*min([Дата выдачи]),max([Дата выдачи])*/  * from #loans where checkDouble=1



drop table if exists #RR
CREATE TABLE #RR (

[Месяц] date
,[Дата] date
,[Сумма_ПТС] float
,[Доля для RR ПТС] float
,[Доля для RR инстоллмент] float
,[Сумма_инстоллмент] float
,[Заявок ПТС] float
,[Заявок CPA ПТС] float
,[Заявок CPA нецелевой ПТС] float
,[Заявок CPA полуцелевой ПТС] float
,[Заявок CPA целевой ПТС] float
,[Заявок Триггеры ПТС] float
,[Заявок CPC ПТС] float
,[Заявок Банки ПТС] float
,[Заявок Партнеры ПТС] float
,[Заявок Органика ПТС] float
,[Заявок Канал привлечения не определен - КЦ ПТС] float
,[Заявок Канал привлечения не определен - МП ПТС] float
,[Заявок Сайт орган.трафик ПТС] float
,[Заем выдан ПТС] float
,[Выданная сумма новые ПТС] float
,[Заявок ПТС накоп] float
,[Заем выдан ПТС накоп] float
,[Выданная сумма ПТС накоп] float
,[Выданная сумма новые ПТС накоп] float
)

INSERT INTO #RR EXEC Analytics.[_birs].[rr]
delete from #rr where Дата!=@dateTo
--select * from #RR 



drop table if exists #PBR
create table #PBR(
    client varchar(300) null,
    dogNum varchar(100) not null,
    saleDate date not null,
    saleType varchar(100) null,
    dogPeriodMonth int not null,
    dogPeriodDays int null,
    dogSum money not null,
    finProd varchar(100) null,
    nomenkGroup varchar(100) null,
    PDNOnSaleDate float null,
    stavaOnSaleDate float null, 
    isZaemshik varchar(10) null,
    isAkcia varchar(10) null,
    prosDaysTotal int null,
    isRestruk varchar(10) null,
	isDogPoruch varchar(300) null,
    spr1 varchar(100) null,
    spr2 varchar(100) null,
    spr3 varchar(100) null,
    spr4 varchar(100) null,
    spr5 varchar(100) null,
    spr6 varchar(100) null
)


INSERT INTO #PBR
(client, dogNum, saleDate, saleType, dogPeriodMonth, dogPeriodDays, dogSum, finProd, nomenkGroup, PDNOnSaleDate, stavaOnSaleDate, isZaemshik, isAkcia, prosDaysTotal, isRestruk, isDogPoruch )
select
l3.client
,l3.dogNum
,l3.saleDate
,l3.saleType
,l3.dogPeriodMonth
,l3.dogPeriodDays
,l3.dogSum
,l3.finProd
,l3.nomenkGroup
,l3.PDNOnSaleDate
,l3.stavkaOnSaleDate
,l3.isZaemshik
,l3.isAkcia
,l3.prosDaysTotal
,l3.isRestruk
,l3.isDogPoruch
from (
select
l2.client
,l2.dogNum
,l2.saleDate
,l2.saleType
,l2.dogPeriodMonth
,l2.dogPeriodDays
,l2.dogSum
,l2.finProd
,l2.nomenkGroup
,l2.PDNOnSaleDate
,l2.stavkaOnSaleDate
,l2.isZaemshik
,l2.isAkcia
,l2.prosDaysTotal
,l2.isRestruk
,l2.isDogPoruch
,[rn] = ROW_NUMBER() over (Partition by l2.dogNum order by l2.repmonth desc)
from(
select
l1.client
,l1.dogNum
,l1.saleDate
,l1.saleType
,l1.dogPeriodMonth
,l1.dogPeriodDays
,l1.dogSum
,l1.finProd
,l1.nomenkGroup
,l1.PDNOnSaleDate
,l1.stavkaOnSaleDate
,l1.isZaemshik
,l1.isAkcia
,l1.prosDaysTotal
,l1.isRestruk
,l1.isDogPoruch
,l1.repmonth
from(
select
    [client] = a.client
    ,[dogNum] = a.dogNum
    ,[saleDate] = a.saleDate
    ,[saleType] = a.saleType
    ,[dogPeriodMonth] = a.dogPeriodMonth
    ,[dogPeriodDays] = a.dogPeriodDays
    ,[dogSum] = isnull(a.dogSum,0)
    ,[finProd] = a.finProd
    ,[nomenkGroup] = a.nomenkGroup
    ,[PDNOnSaleDate] = a.PDNOnSaleDate
    ,[stavkaOnSaleDate] = a.stavaOnSaleDate
    ,[isZaemshik] = a.isZaemshik
    ,[isAkcia] = a.isAkcia
    ,[prosDaysTotal] = a.prosDaysTotal
    ,[isRestruk] = a.isRestruk
	,[isDogPoruch] = a.isDogPoruch
    ,[repmonth] = a.repmonth
from dwh2.finAnalytics.PBR_MONTHLY a

where a.REPMONTH between @monthFrom AND @MonthTo
and a.saleDate between @monthFrom AND eomonth(@MonthTo)--@DateTo
and upper(a.dogStatus) in (upper('Закрыт'),upper('Действует'))
) l1

union all

select
l1.client
,l1.dogNum
,l1.saleDate
,l1.saleType
,l1.dogPeriodMonth
,l1.dogPeriodDays
,l1.dogSum
,l1.finProd
,l1.nomenkGroup
,l1.PDNOnSaleDate
,l1.stavkaOnSaleDate
,l1.isZaemshik
,l1.isAkcia
,l1.prosDaysTotal
,l1.isRestruk
,l1.isDogPoruch
,l1.repmonth
from(
select
    [client] = a.client
    ,[dogNum] = a.dogNum
    ,[saleDate] = a.saleDate
    ,[saleType] = a.saleType
    ,[dogPeriodMonth] = a.dogPeriodMonth
    ,[dogPeriodDays] = a.dogPeriodDays
    ,[dogSum] = isnull(a.dogSum,0)
    ,[finProd] = a.finProd
    ,[nomenkGroup] = a.nomenkGroup
    ,[PDNOnSaleDate] = a.PDNOnSaleDate
    ,[stavkaOnSaleDate] = a.stavaOnSaleDate
    ,[isZaemshik] = a.isZaemshik
    ,[isAkcia] = a.isAkcia
    ,[prosDaysTotal] = a.prosDaysTotal
    ,[isRestruk] = a.isRestruk
	,[isDogPoruch] = a.isDogPoruch
    ,[repmonth] = a.REPDATE
from dwh2.finAnalytics.PBR_WEEKLY a

where a.REPDATE > (select eomonth(max(b.repmonth)) from dwh2.finAnalytics.PBR_MONTHLY b) 
and a.REPDATE <= @DateTo--eomonth(@MonthTo)
and a.saleDate > (select eomonth(max(b.repmonth)) from dwh2.finAnalytics.PBR_MONTHLY b) 
and a.saleDate <= @DateTo--eomonth(@MonthTo)
and upper(a.dogStatus) in (upper('Закрыт'),upper('Действует'))
) l1
) l2
) l3

where l3.rn=1


UPDATE #PBR 
set spr1 = /*case when upper(nomenkGroup) not like upper('%installment%')
                 and upper(nomenkGroup) not like upper('%pdl%')
				 and upper(nomenkGroup) not like upper('Автокредит')
                 and upper(finProd) not like upper('%бизнес%') then 'ПТС'
                  
				  when upper(nomenkGroup) like upper('%installment%') then 'Installment'
                  when upper(nomenkGroup) like upper('%PDL%') then 'PDL'
				  when upper(nomenkGroup) like upper('Автокредит') then 'Автокредит'
                  when upper(finProd) like upper('%бизнес%') then 'Бизнес-займ'
                  else '-'
                  end*/
			case when dwh2.[finAnalytics].[nomenk2prod](nomenkGroup) = 'ПТС' then 'ПТС'
				 when dwh2.[finAnalytics].[nomenk2prod](nomenkGroup) = 'Installment' then 'Installment'
                 when dwh2.[finAnalytics].[nomenk2prod](nomenkGroup) = 'PDL' then 'PDL'
				 when dwh2.[finAnalytics].[nomenk2prod](nomenkGroup) = 'Автокредит' then 'Автокредит'
                 when dwh2.[finAnalytics].[nomenk2prod](nomenkGroup) = 'Бизнес-займ' then 'Бизнес-займ'
                 else '-'
                 end


merge into #PBR t1
using (
select 
a.код
,b.spr1
,[Вид займа] = case when upper(a.[Вид займа]) = upper('Параллельный') and b.spr1 = 'ПТС' then 'Докреды'
					when upper(a.[Вид займа]) = upper('Параллельный') and b.spr1 in ('PDL','Installment') then 'Повторники'
                    when upper(a.[Вид займа]) = upper('докредитование') then 'Докреды'
                    when upper(a.[Вид займа]) = upper('первичный') then 'Новые'
                    when upper(a.[Вид займа]) = upper('повторный') then 'Повторники'
                    else a.[Вид займа] end
from #loans a
left join #PBR b on a.код=b.dogNum
) t2 on (t1.dogNum=t2.код)
when matched then update
set spr2=t2.[Вид займа];


merge into #PBR t1
using (
select 
a.dogNum
,a.spr1
,a.spr2
,b.product
,[spr3] = case when (upper(a.spr1) = upper('ПТС') or upper(a.spr1) = upper('Автокредит'))
                and upper(a.spr2) = upper('Новые')
                and upper(b.product) like upper('%RBP%40%') then 'RBP - 40'

               when (upper(a.spr1) = upper('ПТС') or upper(a.spr1) = upper('Автокредит'))
                and upper(a.spr2) = upper('Новые')
                and upper(b.product) like upper('%RBP%56%') then 'RBP - 56'

               when (upper(a.spr1) = upper('ПТС') or upper(a.spr1) = upper('Автокредит'))
                and upper(a.spr2) = upper('Новые')
                and upper(b.product) like upper('%RBP%66%') then 'RBP - 66'

               when (upper(a.spr1) = upper('ПТС') or upper(a.spr1) = upper('Автокредит'))
                and upper(a.spr2) = upper('Новые')
                and upper(b.product) like upper('%RBP%86%') then 'RBP - 86'

               when (upper(a.spr1) = upper('ПТС') or upper(a.spr1) = upper('Автокредит'))
                and upper(a.spr2) = upper('Новые')
                and upper(b.product) like upper('%non%RBP%') then 'non - RBP'

               when (upper(a.spr1) = upper('ПТС') or upper(a.spr1) = upper('Автокредит'))
                and upper(a.spr2) = upper('Новые')
                and upper(b.product) like upper('%Исп. срок%') then 'Исп. срок'

               when (upper(a.spr1) = upper('ПТС') or upper(a.spr1) = upper('Автокредит'))
                and upper(a.spr2) = upper('Новые')
                and upper(b.product) like upper('%Рефинансирование%') then 'Рефинанс.'

               else null end
            
from #PBR a
left join #loans b on a.dogNum=b.код
) t2 on (t1.dogNum=t2.dogNum)
when matched then update
set t1.spr3=t2.spr3;


UPDATE #PBR 
set spr4 = case when upper(client) like upper('%техмани%') then 'Компании Группы'
                when upper(client) like upper('%айоти%') then 'Компании Группы'
                when upper(client) like upper('%смарт горизонт%') then 'Компании Группы'
                when upper(client) like upper('%смарттехгрупп%') then 'Компании Группы'
                when upper(client) like upper('%пао стг%') then 'Компании Группы'
                when upper(client) like upper('%стг пао%') then 'Компании Группы'
                when upper(client) like upper('%кармани%') then 'Компании Группы'
                when upper(client) like upper('%запросто%') then 'Компании Группы'
                else null end


UPDATE #PBR 
set spr6 = case when PDNOnSaleDate >0 and PDNOnSaleDate <=0.5 then 'ПДН <=50'
                when PDNOnSaleDate >0.5 and PDNOnSaleDate <=0.8 then 'ПДН >50% и <=80%'
                when PDNOnSaleDate >0.8 then 'ПДН >80%'
                when PDNOnSaleDate =0 then 'Без ПДН (до 10 т.р.)'
                else '-' end


drop table if exists #CHECK
CREATE TABLE #CHECK(
	[groupNum] [int] NOT NULL,
	[checkName] [varchar](100) NULL,
	[checkAlgorithm] [varchar](300) NULL,
	[checkAmount] [float] NULL,
	[checkResult] [varchar](10) NULL,
	[dataLoadDate] [datetime] NOT NULL
)

--------------Проверка----------
delete from #Check where groupNum=1

--c1p1
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 1
,[checkName] = 'Проверка разбивки объёма выдач'
,[checkAlgorithm] = 'Объем ПТС - Объем ПТС Новые - Объем ПТС Докреды - Объем ПТС Повторники'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c2.fAmount,0) - isnull(c3.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c2.fAmount,0) - isnull(c3.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('ПТС')
) l1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('ПТС') and upper(a.spr2) = upper('Новые')) c1 on 1=1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('ПТС') and upper(a.spr2) = upper('Докреды')) c2 on 1=1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('ПТС') and upper(a.spr2) = upper('Повторники')) c3 on 1=1

--c1p2
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 1
,[checkName] = 'Проверка разбивки кол-ва выдач'
,[checkAlgorithm] = 'Кол-во ПТС - Кол-во ПТС Новые - Кол-во ПТС Докреды - Кол-во ПТС Повторники'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c2.fAmount,0) - isnull(c3.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c2.fAmount,0) - isnull(c3.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС')
) l1
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС') and upper(a.spr2) = upper('Новые')) c1 on 1=1
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС') and upper(a.spr2) = upper('Докреды')) c2 on 1=1
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('ПТС') and upper(a.spr2) = upper('Повторники')) c3 on 1=1

--c1p3
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 1
,[checkName] = 'Проверка объёма онл/офл по ПБР'
,[checkAlgorithm] = 'Объем всего - Объем Онлайн - Объем оффлайн'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c2.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c2.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a
) l1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.saleType) = upper('Онлайн')) c1 on 1=1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.saleType) = upper('Дистанционный')) c2 on 1=1

--c1p4
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 1
,[checkName] = 'Проверка объёма онл/офл по КБ'
,[checkAlgorithm] = 'Объем всего - Объем Онлайн - Объем оффлайн'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c2.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c2.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = sum(isnull(a.Сумма,0)) from #loans a
) l1
left join (select [fAmount] = sum(isnull(a.Сумма,0)) from #loans a where a.[Дистанционная выдача]=1) c1 on 1=1
left join (select [fAmount] = sum(isnull(a.Сумма,0)) from #loans a where a.[Дистанционная выдача]=0) c2 on 1=1

--c1p5
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 1
,[checkName] = 'Проверка кол-ва онл/офл по ПБР'
,[checkAlgorithm] = 'Кол-во всего - Кол-во Онлайн - Кол-во оффлайн'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c2.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c2.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = cast(count(distinct a.DogNum) as float) from #PBR a
) l1
left join (select [fAmount] = cast(count(distinct a.DogNum) as float) from #PBR a where upper(a.saleType) = upper('Онлайн')) c1 on 1=1
left join (select [fAmount] = cast(count(distinct a.DogNum) as float) from #PBR a where upper(a.saleType) = upper('Дистанционный')) c2 on 1=1

--c1p6
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 1
,[checkName] = 'Проверка кол-ва онл/офл по КБ'
,[checkAlgorithm] = 'Кол-во всего - Кол-во Онлайн - Кол-во оффлайн'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c2.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c2.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = cast(count(distinct a.код) as float) from #loans a
) l1
left join (select [fAmount] = cast(count(distinct a.код) as float) from #loans a where a.[Дистанционная выдача]=1) c1 on 1=1
left join (select [fAmount] = cast(count(distinct a.код) as float) from #loans a where a.[Дистанционная выдача]=0) c2 on 1=1

--c1p7
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 1
,[checkName] = 'Проверка объема ПБР и PBI'
,[checkAlgorithm] = 'Объем всего ПБР - Объем всего PBI'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a
) l1
left join (select [fAmount] = sum(isnull(a.Сумма,0)) from #loans a) c1 on 1=1


--c1p8
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 1
,[checkName] = 'Проверка кол-ва ПБР и PBI'
,[checkAlgorithm] = 'Кол-во ПБР всего - Кол-во PBI всего'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a
) l1
left join (select [fAmount] = cast(count(distinct a.код) as float) from #loans a ) c1 on 1=1


--c1p9
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 1
,[checkName] = 'Проверка на нулевые ПДН'
,[checkAlgorithm] = 'Кол-во договоров в ПБР по ФЛ где ПДН=0'
,[checkAmount] = isnull(l1.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0)  = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where (a.PDNOnSaleDate = 0 or a.PDNOnSaleDate is null)
																		and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l1

--c1p10 Проверка объема ПБР и 840 Объем всего ПБР - строка 2.6 + 2.16 ф. 840
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 1
,[checkName] = 'Проверка объема ПБР и 840'
,[checkAlgorithm] = 'Объем всего ПБР - строка 2.6 + 2.16 ф. 840'
,[checkAmount] = [repSumAmount] - [840SumAmount]
,[checkResult] = case when [repSumAmount] - [840SumAmount] = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select
[840SumAmount] = isnull((
					select
					[sumAmount] = sum([sumAmount])
					from(
					select
					repmonth = l1.repmonth
					,[sumAmount] = sum(l1.[sumAmonut] - l1.[sumAmountPrev])
					from(
					select
					repmonth
					,repMonthNum = month(repmonth)
					,punkt 
					,[sumAmonut] = isnull(value,0)
					,[sumAmountPrev] = case when month(repmonth) > 1 then lag(isnull(value,0)) over (Partition by punkt  order by repmonth)
									else 0 end
					from dwh2.[finAnalytics].[rep840] a
					where 1=1
					and punkt in ('2.6','2.16')
					) l1
					group by l1.repmonth
					) l2

					where l2.repmonth between @monthFrom and @monthTo
				 ),0)
,[repSumAmount] = isnull((select sum(isnull(a.dogSum,0)) from #PBR a),0)
) l1

--c1p11 Проверка кол-ва ПБР и 840 Кол-во ПБР всего - строка 2.5.+ 2.15 ф.840
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 1
,[checkName] = 'Проверка кол-ва ПБР и 840'
,[checkAlgorithm] = 'Кол-во ПБР всего - строка 2.5.+ 2.15 ф.840'
,[checkAmount] = [repSumAmount] - [840SumAmount]
,[checkResult] = case when [repSumAmount] - [840SumAmount] = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select
[840SumAmount] = isnull((
					select
					[sumAmount] = sum([sumAmount])
					from(
					select
					repmonth = l1.repmonth
					,[sumAmount] = sum(l1.[sumAmonut] - l1.[sumAmountPrev])
					from(
					select
					repmonth
					,repMonthNum = month(repmonth)
					,punkt 
					,[sumAmonut] = isnull(value,0)
					,[sumAmountPrev] = case when month(repmonth) > 1 then lag(isnull(value,0)) over (Partition by punkt  order by repmonth)
									else 0 end
					from dwh2.[finAnalytics].[rep840] a
					where 1=1
					and punkt in ('2.5','2.15')
					) l1
					group by l1.repmonth
					) l2

					where l2.repmonth between @monthFrom and @monthTo
				 ),0)
,[repSumAmount] = isnull((select cast(count(distinct a.dogNum) as float) from #PBR a),0)
) l1

--c1p12 Проверка объема ПБР и ОСВ Объем всего ПБР - сумма операций по проводкам с Видом операции "Выдача займа": Дт 48801 / 48701 / 49401 Кт 47422 / 20501, а также Дт 48801 Кт  60332 / 60323. 
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 1
,[checkName] = 'Проверка объема ПБР и ОСВ'
,[checkAlgorithm] = 'Объем всего ПБР - сумма операций по проводкам с Видом операции "Выдача займа": Дт 48801 / 48701 / 49401 Кт 47422 / 20501, а также Дт 48801 Кт  60332 / 60323'
,[checkAmount] = [repSumAmount] - [OSVSumAmount]
,[checkResult] = case when [repSumAmount] - [OSVSumAmount] = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select
[OSVSumAmount] = isnull((
					select
						--[OSVCount] = count(*)
						[OSVAmount] = sum(isnull([Сумма БУ],0))
						--,[OSVAmount2] = sum(isnull([Сумма НУ],0))
						from(
						select
						[Номер договора ДТ]
						,[Сумма БУ] = sum(isnull([Сумма БУ],0))
						,[Сумма НУ] = sum([СуммаНУ])
						from(

						SELECT 

						[Дата операции] = cast(dateadd(year,-2000,a.Период) as date)
						,[СчетДтКод] = Dt.Код
						,[СчетКтКод] = Kt.Код
						,[Сумма БУ] = isnull(a.Сумма,0)
						,[СуммаНУ] = isnull(a.СуммаНУДт,0)
						,[Содержание] = a.Содержание
						,[Номер договора ДТ] = crdt.Номер
						from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
						left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
						left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
						left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0
						left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.СубконтоDt2_Ссылка=crdt.Ссылка and crdt.ПометкаУдаления=0
						where cast(dateadd(year,-2000,a.Период) as date) between @monthFrom and @dateTo--eomonth(@monthTo)
						and a.Активность=01
						and (
								(Kt.Код in ('47422','20501') and  Dt.Код in ('48801','48701','49401')
								and	upper(Содержание) = upper('Выдача займа')
								)
							or
								(
								(Kt.Код in ('60323','60332') and  Dt.Код in ('48801'))
								)
							)
						) l1
						group by [Номер договора ДТ]
						) l1
				 ),0)
,[repSumAmount] = isnull((select sum(isnull(a.dogSum,0)) from #PBR a),0)
) l1

--c1p13 Проверка кол-ва ПБР и ОСВ Кол-во ПБР всего - количество операций по проводкам с Видом операции "Выдача займа": Дт 48801 / 48701 / 49401 Кт 47422 / 60323 / 20501, а также Дт 48801 Кт 60332. Проводки с одинаковым номером договора (лицевого счета займа) считать как 1 операция
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 1
,[checkName] = 'Проверка кол-ва ПБР и ОСВ'
,[checkAlgorithm] = 'Кол-во ПБР всего - количество операций по проводкам с Видом операции "Выдача займа": Дт 48801 / 48701 / 49401 Кт 47422 / 60323 / 20501, а также Дт 48801 Кт 60332. Проводки с одинаковым номером договора (лицевого счета займа) считать как 1 операция'
,[checkAmount] = [repSumAmount] - [OSVSumAmount]
,[checkResult] = case when [repSumAmount] - [OSVSumAmount] = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select
[OSVSumAmount] = isnull((
					select
						[OSVCount] = count(*)
						--[OSVAmount] = sum(isnull([Сумма БУ],0))
						--,[OSVAmount2] = sum(isnull([Сумма НУ],0))
						from(
						select
						[Номер договора ДТ]
						,[Сумма БУ] = sum(isnull([Сумма БУ],0))
						,[Сумма НУ] = sum([СуммаНУ])
						from(

						SELECT 

						[Дата операции] = cast(dateadd(year,-2000,a.Период) as date)
						,[СчетДтКод] = Dt.Код
						,[СчетКтКод] = Kt.Код
						,[Сумма БУ] = isnull(a.Сумма,0)
						,[СуммаНУ] = isnull(a.СуммаНУДт,0)
						,[Содержание] = a.Содержание
						,[Номер договора ДТ] = crdt.Номер
						from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
						left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
						left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
						left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0
						left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.СубконтоDt2_Ссылка=crdt.Ссылка and crdt.ПометкаУдаления=0
						where cast(dateadd(year,-2000,a.Период) as date) between @monthFrom and @dateTo--eomonth(@monthTo)
						and a.Активность=01
						and (
								(Kt.Код in ('47422','20501') and  Dt.Код in ('48801','48701','49401')
								and	upper(Содержание) = upper('Выдача займа')
								)
							or
								(
								(Kt.Код in ('60323','60332') and  Dt.Код in ('48801'))
								)
							)
						) l1
						group by [Номер договора ДТ]
						) l1
				 ),0)
,[repSumAmount] = isnull((select cast(count(distinct a.dogNum) as float) from #PBR a),0)
) l1

--------------Проверка 2----------
delete from #CHECK where groupNum=2

--c2p1
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 2
,[checkName] = 'Проверка разбивки объёма выдач'
,[checkAlgorithm] = 'Объем IL - Объем IL Новые - Объем IL Повторники'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c3.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c3.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Installment')
) l1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Installment') and upper(a.spr2) = upper('Новые')) c1 on 1=1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Installment') and upper(a.spr2) = upper('Повторники')) c3 on 1=1


--c2p2
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 2
,[checkName] = 'Проверка разбивки кол-ва выдач'
,[checkAlgorithm] = 'Кол-во IL - Кол-во IL Новые - Кол-во IL Повторники'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c3.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c3.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('Installment')
) l1
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('Installment') and upper(a.spr2) = upper('Новые')) c1 on 1=1
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('Installment') and upper(a.spr2) = upper('Повторники')) c3 on 1=1

--c2p3
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 2
,[checkName] = 'Проверка объёма онл/офл по ПБР'
,[checkAlgorithm] = 'Объем Всего IL - Объем онлайн IL - Объем офлайн IL'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c3.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c3.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Installment')
) l1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Installment') and upper(a.saleType) = upper('Онлайн')) c1 on 1=1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Installment') and upper(a.saleType) = upper('Дистанционный')) c3 on 1=1

--c2p4
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 2
,[checkName] = 'Проверка объёма онл/офл по КБ'
,[checkAlgorithm] = 'Объем Всего IL - Объем онлайн IL - Объем офлайн IL'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c3.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c3.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = sum(isnull(a.Сумма,0)) from #loans a left join #pbr b on a.код=b.dogNum  where upper(b.spr1) = upper('Installment')
) l1
left join (select [fAmount] = sum(isnull(a.Сумма,0)) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('Installment') and a.[Дистанционная выдача]=1) c1 on 1=1
left join (select [fAmount] = sum(isnull(a.Сумма,0)) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('Installment') and a.[Дистанционная выдача]=0) c3 on 1=1

--c2p5
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 2
,[checkName] = 'Проверка кол-ва онл/офл по ПБР'
,[checkAlgorithm] = 'Кол-во Всего IL - Кол-во онлайн IL - Кол-во офлайн IL'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c3.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c3.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('Installment')
) l1
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('Installment') and upper(a.saleType) = upper('Онлайн')) c1 on 1=1
left join (select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('Installment') and upper(a.saleType) = upper('Дистанционный')) c3 on 1=1


--c2p6
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 2
,[checkName] = 'Проверка объёма онл/офл по КБ'
,[checkAlgorithm] = 'Объем Всего IL - Объем онлайн IL - Объем офлайн IL'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c3.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) - isnull(c3.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = cast(count(distinct a.код) as float) from #loans a left join #pbr b on a.код=b.dogNum  where upper(b.spr1) = upper('Installment')
) l1
left join (select [fAmount] = cast(count(distinct a.код) as float) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('Installment') and a.[Дистанционная выдача]=1) c1 on 1=1
left join (select [fAmount] = cast(count(distinct a.код) as float) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('Installment') and a.[Дистанционная выдача]=0) c3 on 1=1


--c2p7
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 2
,[checkName] = 'Проверка объема ПБР и PBI'
,[checkAlgorithm] = 'Объем Всего ПБР - Объем всего PBI'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Installment')
) l1
left join (select [fAmount] = sum(isnull(a.Сумма,0)) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('Installment') ) c1 on 1=1

--c2p8
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 2
,[checkName] = 'Проверка кол-ва ПБР и PBI'
,[checkAlgorithm] = 'Кол-во Всего ПБР - Кол-во всего PBI'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('Installment')
) l1
left join (select [fAmount] = cast(count(distinct a.код) as float) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('Installment') ) c1 on 1=1

--------------Проверка 3----------
delete from #CHECK where groupNum=3

--c3p1
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 3
,[checkName] = 'Проверка разбивки объёма выдач'
,[checkAlgorithm] = 'Объем PDL - Объем PDL Новые - Объем PDL Повторники'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) -  isnull(c3.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0)  - isnull(c3.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL')
) l1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL') and upper(a.spr2) = upper('Новые')) c1 on 1=1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL') and upper(a.spr2) = upper('Повторники')) c3 on 1=1

--c3p2
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 3
,[checkName] = 'Проверка разбивки кол-ва выдач'
,[checkAlgorithm] = 'Кол-во PDL - Кол-во PDL Новые - Кол-во PDL Повторники'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) -  isnull(c3.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0)  - isnull(c3.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr1) = upper('PDL')
) l1
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr1) = upper('PDL') and upper(a.spr2) = upper('Новые')) c1 on 1=1
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr1) = upper('PDL') and upper(a.spr2) = upper('Повторники')) c3 on 1=1


--c3p3
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 3
,[checkName] = 'Проверка объёма онл/офл по ПБР'
,[checkAlgorithm] = 'Объем PDL - Объем PDL онлайн - Объем PDL офлайн'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) -  isnull(c3.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0)  - isnull(c3.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL')
) l1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL') and upper(a.saleType) = upper('Онлайн')) c1 on 1=1
left join (select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL') and upper(a.saleType) = upper('Дистанционный')) c3 on 1=1


--c3p4
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 3
,[checkName] = 'Проверка объёма онл/офл по КБ'
,[checkAlgorithm] = 'Объем PDL - Объем PDL онлайн - Объем PDL офлайн'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) -  isnull(c3.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0)  - isnull(c3.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = sum(isnull(a.Сумма,0)) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('PDL')
) l1
left join (select [fAmount] = sum(isnull(a.Сумма,0)) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('PDL') and a.[Дистанционная выдача]=1) c1 on 1=1
left join (select [fAmount] = sum(isnull(a.Сумма,0)) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('PDL') and a.[Дистанционная выдача]=0) c3 on 1=1

--c3p5
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 3
,[checkName] = 'Проверка кол-ва онл/офл по ПБР'
,[checkAlgorithm] = 'Кол-во PDL - Кол-во PDL онлайн - Кол-во PDL офлайн'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) -  isnull(c3.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0)  - isnull(c3.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr1) = upper('PDL')
) l1
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr1) = upper('PDL') and upper(a.saleType) = upper('Онлайн')) c1 on 1=1
left join (select [fAmount] = cast(count(distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr1) = upper('PDL') and upper(a.saleType) = upper('Дистанционный')) c3 on 1=1


--c3p6
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 3
,[checkName] = 'Проверка кол-ва онл/офл по КБ'
,[checkAlgorithm] = 'Кол-во PDL - Кол-во PDL онлайн - Кол-во PDL офлайн'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0) -  isnull(c3.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0)  - isnull(c3.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = cast(count(distinct isnull(a.код,0)) as float) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('PDL')
) l1
left join (select [fAmount] = cast(count(distinct isnull(a.код,0)) as float) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('PDL') and a.[Дистанционная выдача]=1) c1 on 1=1
left join (select [fAmount] = cast(count(distinct isnull(a.код,0)) as float) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('PDL') and a.[Дистанционная выдача]=0) c3 on 1=1

--c3p7
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 2
,[checkName] = 'Проверка объема ПБР и PBI'
,[checkAlgorithm] = 'Объем Всего ПБР - Объем всего PBI'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('PDL')
) l1
left join (select [fAmount] = sum(isnull(a.Сумма,0)) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('PDL') ) c1 on 1=1

--c2p8
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)
select
[groupNum] = 2
,[checkName] = 'Проверка кол-ва ПБР и PBI'
,[checkAlgorithm] = 'Кол-во Всего ПБР - Кол-во всего PBI'
,[checkAmount] = isnull(l1.fAmount,0) - isnull(c1.fAmount,0)
,[checkResult] = case when isnull(l1.fAmount,0) - isnull(c1.fAmount,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from(
select [fAmount] = cast(count(distinct a.dogNum) as float) from #PBR a where upper(a.spr1) = upper('PDL')
) l1
left join (select [fAmount] = cast(count(distinct a.код) as float) from #loans a left join #pbr b on a.код=b.dogNum where upper(b.spr1) = upper('PDL') ) c1 on 1=1


--------------Проверка 4 ПДН----------
delete from #CHECK where groupNum=4

--c4p1
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 4
,[checkName] = 'Проверка разбивки объёма выдач по всем продуктам'
,[checkAlgorithm] = 'Объём продаж на листе "Продукты" - Объём выдач ПТС для СЗ - Итого выдачи на листе "ПДН общий"'
,[checkAmount] = l1.checkAmount1 - l2.checkAmount2 - l3.checkAmount3
,[checkResult] = case when isnull(l1.checkAmount1,0) - isnull(l2.checkAmount2,0)  - isnull(l3.checkAmount3,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from (
select
[checkAmount1] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr4 is null
) l1
left join
(
select
[checkAmount2] = sum(isnull(a.dogSum,0)) from #PBR a where a.spr4 is null and a.nomenkGroup like '%Самозанят%'
) l2 on 1=1
left join
(
select
[checkAmount3] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l3 on 1=1

--c4p2
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 4
,[checkName] = 'Проверка разбивки кол-ва выдач по всем продуктам'
,[checkAlgorithm] = 'Кол-во продаж на листе "Продукты"- Кол-во выдач ПТС для СЗ - Итого кол-во выдач на листе "ПДН общий"'
,[checkAmount] = l1.checkAmount1 - l2.checkAmount2 - l3.checkAmount3
,[checkResult] = case when isnull(l1.checkAmount1,0) - isnull(l2.checkAmount2,0)  - isnull(l3.checkAmount3,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from (
select
[checkAmount1] = cast(count(Distinct isnull(a.dogNum,0)) as float) from #PBR a where a.spr4 is null
) l1
left join
(
select
[checkAmount2] = cast(count(Distinct isnull(a.dogNum,0)) as float) from #PBR a where a.spr4 is null and a.nomenkGroup like '%Самозанят%'
) l2 on 1=1
left join
(
select
[checkAmount3] = cast(count(Distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) is not null and upper(a.nomenkGroup) not like upper('%Самозанят%')
) l3 on 1=1

--c4p3
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 4
,[checkName] = 'Проверка объёма выданных ПТС (без СЗ)'
,[checkAlgorithm] = 'Объём выдач ПТС на листе "Продукты" - Объём выдач ПТС для СЗ - Итого выдачи ПТС на листе "ПДН ПТС"'
,[checkAmount] = l1.checkAmount1 - l2.checkAmount2 - l3.checkAmount3
,[checkResult] = case when isnull(l1.checkAmount1,0) - isnull(l2.checkAmount2,0)  - isnull(l3.checkAmount3,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from (
select
[checkAmount1] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('ПТС')
) l1
left join
(
select
[checkAmount2] = sum(isnull(a.dogSum,0)) from #PBR a where a.nomenkGroup like '%Самозанят%'
) l2 on 1=1
left join
(
select
[checkAmount3] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l3 on 1=1

--c4p4
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 4
,[checkName] = 'Проверка кол-ва выданных ПТС (без СЗ)'
,[checkAlgorithm] = 'Кол-во выдач ПТС на листе "Продукты" - Кол-во выдач ПТС для СЗ - Итого кол-во выдач ПТС на листе "ПДН ПТС"'
,[checkAmount] = l1.checkAmount1 - l2.checkAmount2 - l3.checkAmount3
,[checkResult] = case when isnull(l1.checkAmount1,0) - isnull(l2.checkAmount2,0)  - isnull(l3.checkAmount3,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from (
select
[checkAmount1] = cast(count(Distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr1) = upper('ПТС')
) l1
left join
(
select
[checkAmount2] = cast(count(Distinct isnull(a.dogNum,0)) as float) from #PBR a where a.nomenkGroup like '%Самозанят%'
) l2 on 1=1
left join
(
select
[checkAmount3] = cast(count(Distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) is not null
and upper(a.spr1) = upper('ПТС')
and upper(a.nomenkGroup) != upper('ПТС Займ для Самозанятых')
) l3 on 1=1

--c4p5
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 4
,[checkName] = 'Проверка объёма выданных Автокредитов'
,[checkAlgorithm] = 'Объём выдач Автокредитов на листе "Автокредит" - Итого выдачи Автокредитов на листе "ПДН Автокредит"'
,[checkAmount] = l1.checkAmount1 - l2.checkAmount2
,[checkResult] = case when isnull(l1.checkAmount1,0) - isnull(l2.checkAmount2,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from (
select
[checkAmount1] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) = upper('Автокредит')
) l1
left join
(
select
[checkAmount2] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null
and upper(a.spr1) = upper('Автокредит')
) l2 on 1=1


--c4p6
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 4
,[checkName] = 'Проверка кол-ва выданных Автокредитов'
,[checkAlgorithm] = 'Кол-во выдач Автокредитов на листе "Автокредит" - Итого кол-во выдач Автокредитов на листе "ПДН Автокредит"'
,[checkAmount] = l1.checkAmount1 - l2.checkAmount2
,[checkResult] = case when isnull(l1.checkAmount1,0) - isnull(l2.checkAmount2,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from (
select
[checkAmount1] = cast(count(Distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr1) = upper('Автокредит')
) l1
left join
(
select
[checkAmount2] = cast(count(Distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) is not null
and upper(a.spr1) = upper('Автокредит')
) l2 on 1=1

--c4p7
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 4
,[checkName] = 'Проверка объёма выданных IL+PDL'
,[checkAlgorithm] = 'Объём выдач беззалоговых займов (IL+PDL)  - Итого выдачи беззалоговых займов на листе "ПДН Installment+PDL"'
,[checkAmount] = l1.checkAmount1 - l2.checkAmount2
,[checkResult] = case when isnull(l1.checkAmount1,0) - isnull(l2.checkAmount2,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from (
select
[checkAmount1] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join
(
select
[checkAmount2] = sum(isnull(a.dogSum,0)) from #PBR a where upper(a.spr6) is not null
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l2 on 1=1


--c4p8
INSERT INTO #CHECK
(groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate)

select
[groupNum] = 4
,[checkName] = 'Проверка кол-ва выданных IL+PDL'
,[checkAlgorithm] = 'Кол-во выдач беззалоговых займов (IL+PDL) - Итого кол-во выдач беззалоговых займов на листе "ПДН Installment+PDL"'
,[checkAmount] = l1.checkAmount1 - l2.checkAmount2
,[checkResult] = case when isnull(l1.checkAmount1,0) - isnull(l2.checkAmount2,0) = 0 then 'OK' else 'Ошибка' end
,[dataLoadDate] = getdate()
from (
select
[checkAmount1] = cast(count(Distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l1
left join
(
select
[checkAmount2] = cast(count(Distinct isnull(a.dogNum,0)) as float) from #PBR a where upper(a.spr6) is not null
and upper(a.spr1) in (upper('Installment'),upper('PDL'))
) l2 on 1=1



DROP TABLE if exists #SALES
CREATE TABLE #SALES(
	[tabNum] [int] NULL,
	[tabName] [varchar](300) NULL,
	[pokazatelNum] [int] NULL,
	[pokazatel] [varchar](300) NULL,
	[pAmount] [float] NULL,
	[fAmount] [float] NULL,
	[rrDolya] [float] NULL,
	[tekPRC] [float] NULL,
	[RR] [float] NULL
)



delete from #SALES
--------------------Основная выборка

/*Расчет данных по Всем продуктам*/
/*Таблицы 1 - 10*/
exec reports.finAnalytics.repSalesAllProd @dateTo

/*Расчет данных по Instollment*/
/*Таблицы 11 - 17*/
exec reports.finAnalytics.repSalesILProd @dateTo

/*Расчет данных по PDL*/
/*Таблицы 18 - 25*/
exec reports.finAnalytics.repSalesPDLProd @dateTo, @monthFrom

/*Расчет данных по Бизнес-Займам*/
/*Таблица 26*/
exec reports.finAnalytics.repSalesBZProd @dateTo

/*Расчет данных по ПТС RBP*/
/*Таблица 27-31*/
exec reports.finAnalytics.repSalesPTS_RBP @dateTo

/*Расчет данных по ПДН Все продукты*/
/*Таблица 32-36*/
exec reports.finAnalytics.repSalesPDNAll @dateTo

/*Расчет данных по ПДН ПТС*/
/*Таблица 37-41*/
exec reports.finAnalytics.repSalesPDN_PTS @dateTo

/*Расчет данных по ПДН IL*/
/*Таблица 42-56*/
exec reports.finAnalytics.repSalesPDN_IL @dateTo

/*Расчет данных по Авто*/
/*Таблица 57-63*/
exec reports.finAnalytics.repSalesAUTOProd @dateTo

/*Расчет данных по Авто RBP*/
/*Таблица 64-68*/
exec reports.finAnalytics.repSalesAUTO_RBP @dateTo

/*Расчет данных по Авто PDN*/
/*Таблица 69-73*/
exec reports.finAnalytics.repSalesPDN_AUTO @dateTo



-----------Отчет
if @dsSelector = 1
begin
select
tabNum, tabName, pokazatelNum, pokazatel, pAmount, fAmount, rrDolya, tekPRC, RR
from #SALES
end

-----------Проверки
if @dsSelector = 2
begin
select groupNum, checkName, checkAlgorithm, checkAmount, checkResult, dataLoadDate
from #CHECK

end

END
