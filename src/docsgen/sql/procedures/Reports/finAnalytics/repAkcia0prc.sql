


CREATE PROCEDURE [finAnalytics].[repAkcia0prc]
	@repMonthFrom date,
	@repMonthTo date
	
AS
BEGIN
   

Drop table if exists #pbr
select 
a.*
,[daysInYear] = DATEPART(dayofyear, datefromParts(year(a.repmonth),12,31))
into #PBR
from dwh2.[finAnalytics].[PBR_AKCIA0] a 

where a.REPMONTH between @repMonthFrom and @repMonthTo

--select * from #pbr

drop table if exists #rep
create table #rep(
			rowNum int not null,
			rowName nvarchar(300) not null,
			amount float null,
			isgroup int not null
			)
INSERT INTO #rep VALUES (1,'Объём выдач по акции 0%',0.0,0)
INSERT INTO #rep VALUES (2,'Кол-во выдач по акции 0%',0.0,0)
INSERT INTO #rep VALUES (3,'Доля акции 0% от всех выдач PDL:',NULL,1)
INSERT INTO #rep VALUES (4,'- по объёму',0.0,0)
INSERT INTO #rep VALUES (5,'- по кол-ву',0.0,0)
INSERT INTO #rep VALUES (6,'Доля акции 0% от первичных PDL:',NULL,1)
INSERT INTO #rep VALUES (7,'- по объёму',0.0,0)
INSERT INTO #rep VALUES (8,'- по кол-ву',0.0,0)
INSERT INTO #rep VALUES (9,'Воспользовались акцией 0%:',NULL,1)
INSERT INTO #rep VALUES (10,'- по объёму',0.0,0)
INSERT INTO #rep VALUES (11,'- по кол-ву',0.0,0)
INSERT INTO #rep VALUES (12,'Доля воспользовавшихся акцией 0% (от заёмщиков, соответствующих условиям акции):',NULL,1)
INSERT INTO #rep VALUES (13,'- по объёму',0.0,0)
INSERT INTO #rep VALUES (14,'- по кол-ву',0.0,0)

INSERT INTO #rep VALUES (16,'Сумма недополученных доходов при срабатывании акции 0% (по ОСВ)',0.0,0)
INSERT INTO #rep VALUES (17,'Причина невыполнения условий акции 0%:',NULL,1)

INSERT INTO #rep VALUES (18,'-  погашение в день выдачи:',NULL,1)
INSERT INTO #rep VALUES (19,'- по объёму',NULL,0)
INSERT INTO #rep VALUES (20,'- по кол-ву',NULL,0)

INSERT INTO #rep VALUES (21,'-  просрочка:',NULL,1)
INSERT INTO #rep VALUES (22,'- по объёму',0.0,0)
INSERT INTO #rep VALUES (23,'- по кол-ву',0.0,0)

INSERT INTO #rep VALUES (24,'-  пролонгация:',NULL,1)
INSERT INTO #rep VALUES (25,'- по объёму',0.0,0)
INSERT INTO #rep VALUES (26,'- по кол-ву',0.0,0)

INSERT INTO #rep VALUES (27,'-  Частичное досрочное погашение:',NULL,1)
INSERT INTO #rep VALUES (28,'- по объёму',0.0,0)
INSERT INTO #rep VALUES (29,'- по кол-ву',0.0,0)

INSERT INTO #rep VALUES (30,'Средняя ставка по PDL с учётом акции 0%:',NULL,1)
INSERT INTO #rep VALUES (31,'- по всем выдачам PDL',0.0,0)
INSERT INTO #rep VALUES (32,'- по первичным выдачам PDL',0.0,0)
INSERT INTO #rep VALUES (33,'Проверка объёма выдач',0.0,1)
INSERT INTO #rep VALUES (34,'Проверка кол-ва выдач',0.0,1)

--select * from #rep


--p1
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = sum(isnull(b.dogSum,0))
,a.isgroup
from #rep a
left join #PBR b on 1=1
where a.rowNum=1 and upper(b.[isAkcia]) = 'ДА'
group by
b.repmonth
,a.rowNum	
,a.rowName
,a.isgroup

union all

--p2
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = count(*)
,a.isgroup
from #rep a
left join #PBR b on 1=1
where a.rowNum=2 and upper(b.[isAkcia]) = 'ДА'
group by
b.repmonth
,a.rowNum	
,a.rowName
,a.isgroup

union all

--p3
select
repmonth = b.repmonth
,a.rowNum	
,a.rowName
,[amount] = null
,a.isgroup
from #rep a
left join (select distinct repmonth from #PBR) b on 1=1
where a.rowNum=3


union all

--p4
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = case when b.amountPDL != 0 then round(b.amountisAkcia / b.amountPDL,3) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when upper(b.[isAkcia]) = 'ДА' then isnull(b.dogSum,0) else 0 end)
,[amountPDL] = sum(isnull(b.dogSum,0))
from #PBR b
group by
b.repmonth
) b on 1=1

where a.rowNum = 4

union all

--p5
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = case when b.amountPDL != 0 then round(cast(b.amountisAkcia as float) / cast(b.amountPDL as float),3) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when upper(b.[isAkcia]) = 'ДА' then 1 else 0 end)
,[amountPDL] = count(*)
from #PBR b
group by
b.repmonth
) b on 1=1

where a.rowNum = 5

union all

--p6
select
repmonth = b.repmonth
,a.rowNum	
,a.rowName
,[amount] = null
,a.isgroup
from #rep a
left join (select distinct repmonth from #PBR) b on 1=1
where a.rowNum=6

union all

--p7
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = case when b.amountPDL != 0 then round(cast(b.amountisAkcia as float) / cast(b.amountPDL as float),3) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when upper(b.[isAkcia]) = 'ДА' then isnull(b.dogSum,0) else 0 end)
,[amountPDL] = sum(case when upper(b.[isFirstFromSales]) = upper('Первичный') then isnull(b.dogSum,0) else 0 end)
from #PBR b
group by
b.repmonth
) b on 1=1

where a.rowNum = 7

union all

--p8
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = case when b.amountPDL != 0 then round(cast(b.amountisAkcia as float) / cast(b.amountPDL as float),3) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when upper(b.[isAkcia]) = 'ДА' then 1 else 0 end)
,[amountPDL] = sum(case when upper(b.[isFirstFromSales]) = upper('Первичный') then 1 else 0 end)
from #PBR b
group by
b.repmonth
) b on 1=1

where a.rowNum = 8

union all

--p9
select
repmonth = b.repmonth
,a.rowNum	
,a.rowName
,[amount] = null
,a.isgroup
from #rep a
left join (select distinct repmonth from #PBR) b on 1=1
where a.rowNum = 9

union all

--p10
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = [amountisAkcia]--case when b.amountPDL != 0 then cast(b.amountisAkcia as float) / cast(b.amountPDL as float) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(isnull(b.dogSum,0))
,[amountPDL] = null
from #PBR b
where 1=1
and upper(b.[isAciaResult]) = upper('Сработала Акция')

group by
b.repmonth
) b on 1=1

where a.rowNum = 10

union all

--p11
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = [amountisAkcia]--case when b.amountPDL != 0 then cast(b.amountisAkcia as float) / cast(b.amountPDL as float) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = count(*)
,[amountPDL] = null
from #PBR b
where 1=1
and upper(b.[isAciaResult]) = upper('Сработала Акция')
group by
b.repmonth
) b on 1=1

where a.rowNum = 11

union all

--p12
select
repmonth = b.repmonth
,a.rowNum	
,a.rowName
,[amount] = null
,a.isgroup
from #rep a
left join (select distinct repmonth from #PBR) b on 1=1
where a.rowNum =12

union all

--p13
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = case when b.amountPDL != 0 then round(cast(b.amountisAkcia as float) / cast(b.amountPDL as float),3) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when 
							upper(b.[isAciaResult]) = upper('Сработала Акция')
							then isnull(b.dogSum,0) else 0 end)
,[amountPDL] = sum(case when 
							upper(b.[isAkcia]) = 'ДА'
							then isnull(b.dogSum,0) else 0 end)
from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 13

union all

--p14
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = case when b.amountPDL != 0 then round(cast(b.amountisAkcia as float) / cast(b.amountPDL as float),3) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when 
							upper(b.[isAciaResult]) = upper('Сработала Акция')
							then 1 else 0 end)
,[amountPDL] = sum(case when 
							upper(b.[isAkcia]) = 'ДА'
							then 1 else 0 end)
from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 14

union all
/*
--p15
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = round(b.amountisAkcia, 2)--case when b.amountPDL != 0 then cast(b.amountisAkcia as float) / cast(b.amountPDL as float) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when 
							upper(b.[isAciaResult]) = upper('Сработала Акция')
							then isnull(b.dogSum,0) * isnull(b.stavaOnSaleDate,0) / 100 / b.daysInYear * b.dogPeriodDays 
							else 0 end)
,[amountPDL] = null
from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 15

union all
*/
--p16
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = b.amountisAkcia--case when b.amountPDL != 0 then cast(b.amountisAkcia as float) / cast(b.amountPDL as float) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when 
							upper(b.[isAciaResult]) = upper('Сработала Акция')
							then isnull(prcStornoSumm,0)
							else 0 end)
,[amountPDL] = null
from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 16

union all

--p17--p18
select
repmonth = b.repmonth
,a.rowNum	
,a.rowName
,[amount] = null
,a.isgroup
from #rep a
left join (select distinct repmonth from #PBR) b on 1=1
where a.rowNum in (17,18)

union all

--p19
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = b.amountisAkcia--case when b.amountPDL != 0 then cast(b.amountisAkcia as float) / cast(b.amountPDL as float) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when 
							upper(b.[isAciaResult]) = upper('Погашение в день выдачи')
							then isnull(b.dogSum,0)
							else 0 end)
,[amountPDL] = null
from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 19

union all

--p20
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = b.amountisAkcia--case when b.amountPDL != 0 then cast(b.amountisAkcia as float) / cast(b.amountPDL as float) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when 
							upper(b.[isAciaResult]) = upper('Погашение в день выдачи')
							then 1
							else 0 end)
,[amountPDL] = null
from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 20

union all

--p21
select
repmonth = b.repmonth
,a.rowNum	
,a.rowName
,[amount] = null
,a.isgroup
from #rep a
left join (select distinct repmonth from #PBR) b on 1=1
where a.rowNum =21

union all

--p22
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = b.amountisAkcia--case when b.amountPDL != 0 then cast(b.amountisAkcia as float) / cast(b.amountPDL as float) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when 
							upper(b.[isAciaResult]) = upper('Просрочка')
							then isnull(b.dogSum,0)
							else 0 end)
,[amountPDL] = null
from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 22

union all

--p23
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = b.amountisAkcia--case when b.amountPDL != 0 then cast(b.amountisAkcia as float) / cast(b.amountPDL as float) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when 
							upper(b.[isAciaResult]) = upper('Просрочка')
							then 1
							else 0 end)
,[amountPDL] = null
from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 23

union all

--p24
select
repmonth = b.repmonth
,a.rowNum	
,a.rowName
,[amount] = null
,a.isgroup
from #rep a
left join (select distinct repmonth from #PBR) b on 1=1
where a.rowNum =24

union all

--p25
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = b.amountisAkcia--case when b.amountPDL != 0 then cast(b.amountisAkcia as float) / cast(b.amountPDL as float) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when 
							upper(b.[isAciaResult]) = upper('Пролонгация')
							then isnull(b.dogSum,0)
							else 0 end)
,[amountPDL] = null
from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 25

union all

--p26
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = b.amountisAkcia--case when b.amountPDL != 0 then cast(b.amountisAkcia as float) / cast(b.amountPDL as float) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when 
							upper(b.[isAciaResult]) = upper('Пролонгация')
							then 1
							else 0 end)
,[amountPDL] = null
from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 26

union all

--p27
select
repmonth = b.repmonth
,a.rowNum	
,a.rowName
,[amount] = null
,a.isgroup
from #rep a
left join (select distinct repmonth from #PBR) b on 1=1
where a.rowNum =27

union all

--p28
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = b.amountisAkcia--case when b.amountPDL != 0 then cast(b.amountisAkcia as float) / cast(b.amountPDL as float) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when 
							upper(b.[isAciaResult]) = upper('ЧДП')
							then isnull(b.dogSum,0)
							else 0 end)
,[amountPDL] = null
from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 28

union all

--p29
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = b.amountisAkcia--case when b.amountPDL != 0 then cast(b.amountisAkcia as float) / cast(b.amountPDL as float) else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when 
							upper(b.[isAciaResult]) = upper('ЧДП')
							then 1
							else 0 end)
,[amountPDL] = null
from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 29

union all

--p30
select
repmonth = b.repmonth
,a.rowNum	
,a.rowName
,[amount] = null
,a.isgroup
from #rep a
left join (select distinct repmonth from #PBR) b on 1=1
where a.rowNum =30

union all

--p31
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = case when b.amountPDL != 0 then 
						round((cast(b.amountPDL as float) - cast(b.amountisAkcia as float)) *  b.[avgStavka] / cast(b.amountPDL as float),3)
						else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when 
							upper(b.[isAciaResult]) = upper('Сработала Акция')
							then isnull(b.dogSum,0)
							else 0 end)
,[amountPDL] = sum(isnull(b.dogSum,0))
,[avgStavka] = SUM(isnull(b.dogSum,0) * b.stavaOnSaleDate / 100)  / SUM(isnull(b.dogSum,0))
from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 31

union all

--p32
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = case when b.amountPDL != 0 then 
						round((cast(b.amountPDL as float) - cast(b.amountisAkcia as float)) *  b.[avgStavka] / cast(b.amountPDL as float),3)
						else 0 end
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkcia] = sum(case when 
							upper(b.[isAciaResult]) = upper('Сработала Акция')
							and upper(b.isFirstFromSales) = upper('Первичный')
							then isnull(b.dogSum,0)
							else 0 end)
,[amountPDL] = sum(case when upper(b.isFirstFromSales) = upper('Первичный') then isnull(b.dogSum,0) else 0 end)
,[avgStavka] = SUM(isnull(b.dogSum,0) * b.stavaOnSaleDate / 100)  / SUM(isnull(b.dogSum,0))
from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 32

union all

--p33
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = [amountisAkciaAll] 
		  - [amountisAkciaDone] 
		  - [amountisAkciaCancelPros] 
		  - [amountisAkciaCancelProl]
		  - [amountisAkciaCancel1Day]
		  - [amountisAkciaCancelCHPD]
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkciaDone] = sum(case when 
							upper(b.[isAciaResult]) = upper('Сработала Акция')
							then isnull(b.dogSum,0)
							else 0 end)
,[amountisAkciaCancelPros] = sum(case when 
							upper(b.[isAciaResult]) = upper('Просрочка')
							then isnull(b.dogSum,0)
							else 0 end)
,[amountisAkciaCancelProl] = sum(case when 
							upper(b.[isAciaResult]) = upper('Пролонгация')
							then isnull(b.dogSum,0)
							else 0 end)
,[amountisAkciaCancel1Day] = sum(case when 
							upper(b.[isAciaResult]) = upper('Погашение в день выдачи')
							then isnull(b.dogSum,0)
							else 0 end)
,[amountisAkciaAll] = sum(case when 
							upper(b.[isAkcia]) = upper('Да')
							then isnull(b.dogSum,0)
							else 0 end)
,[amountisAkciaCancelCHPD] = sum(case when 
							upper(b.[isAciaResult]) = upper('ЧДП')
							then isnull(b.dogSum,0)
							else 0 end)


from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 33

union all

--p34
select
b.repmonth
,a.rowNum	
,a.rowName
,[amount] = [amountisAkciaAll] 
		  - [amountisAkciaDone] 
		  - [amountisAkciaCancelPros] 
		  - [amountisAkciaCancelProl]
		  - [amountisAkciaCancel1Day]
		  - [amountisAkciaCancelCHPD]
,a.isgroup
from #rep a
left join (
select
b.repmonth
,[amountisAkciaDone] = sum(case when 
							upper(b.[isAciaResult]) = upper('Сработала Акция')
							then 1
							else 0 end)
,[amountisAkciaCancelPros] = sum(case when 
							upper(b.[isAciaResult]) = upper('Просрочка')
							then 1
							else 0 end)
,[amountisAkciaCancelProl] = sum(case when 
							upper(b.[isAciaResult]) = upper('Пролонгация')
							then 1
							else 0 end)
,[amountisAkciaCancel1Day] = sum(case when 
							upper(b.[isAciaResult]) = upper('Погашение в день выдачи')
							then 1
							else 0 end)
,[amountisAkciaCancelCHPD] = sum(case when 
							upper(b.[isAciaResult]) = upper('ЧДП')
							then 1
							else 0 end)
,[amountisAkciaAll] = sum(case when 
							upper(b.[isAkcia]) = upper('Да')
							then 1
							else 0 end)

from #PBR b
where 1=1
group by
b.repmonth
) b on 1=1

where a.rowNum = 34


END
