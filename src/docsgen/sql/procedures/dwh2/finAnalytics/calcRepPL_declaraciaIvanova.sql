


CREATE PROC [finAnalytics].[calcRepPL_declaraciaIvanova] 
    @repmonth date
AS
BEGIN
	DECLARE @subject NVARCHAR(2048) = 'Расчет данных для PL для публикуемой. Декларация Иванова.'
    declare @emailList varchar(255)=''
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	 --старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

	begin try
	begin tran  
	
	/*Создаем скелет отчета*/
drop table if exists #rep

select
[repmonth] = @repmonth
,[part] = a.part	
,[partNum] = a.partNum	
,[rowNum] = a.rowNum	
,[rowName] = a.rowName	
,[accNum] = a.accNum	
,[pokazatel] = a.pokazatel	
,[amountBU] = a.[amountBU]
,[correctionPlus] = a.correctionPlus	
,[correctionMinus] = a.correctionMinus	
,[amountNU] = a.amountNU	
,[comment] = a.comment

into #rep

from dwh2.finAnalytics.SPR_repPL_declaraciaIvanova a


/*Часть 1*/

/*по лицевикам*/
merge into #rep t1
using(
select
[rowNum] = a.rowNum	
,[accNum] = a.accNum	
,[amountBU] = case when a.accNum in (
									'71701810005280200000'
									--,'71702810005310200000'
									--,'71702810005310300000'
									)
									then 0 else isnull(rest.restOUT_BU * -1,0) end
,[amountNU] = case when a.accNum in (
									'71501810003240700000'
									)
									then isnull(rest.restOUT_NU * -1,0) else 0 end
from dwh2.finAnalytics.SPR_repPL_declaraciaIvanova a
left join dwh2.[finAnalytics].[SPR_PL_ACC] acc on a.accNum = acc.accNUM
left join dwh2.[finAnalytics].[repPLAccRests] rest on acc.ID=rest.accUID and rest.repmonth=@repmonth
where partNum=1
) t2 on (t1.partNum=1 and t1.rowNum=t2.rowNum)
when matched then update
set t1.amountBU = t2.amountBU,
	t1.amountNU = t2.amountNU;

/*Корректировки*/
merge into #rep t1
using(
	select
	[amountBU] = isnull(sum(isnull(sumKT_BU,0)),0)
	from dwh2.finAnalytics.OSV_MONTHLY a
	where a.repMonth between dateFromParts(year(@repmonth),1,1) and @repmonth
	and accNum='60323810010000000000'
) t2 on (t1.partNum=1 and t1.rowNum=1400)
when matched then update
set t1.correctionPlus = t2.amountBU;

merge into #rep t1
using(
	select
	[correctionMinus] = amountBU - amountNU
	,[rowNum] = a.rowNum
	from #rep a
	where a.partNum=1 and a.rowNum in (1000)
) t2 on (t1.partNum=1 and t1.rowNum=t2.rowNum)
when matched then update
set t1.correctionMinus = t2.correctionMinus;

/*Данные по НУ*/
merge into #rep t1
using(
select
[rowNum] = a.rowNum	
,[amountNU] = a.amountBU + a.correctionPlus	- a.correctionMinus
from #rep a
where partNum=1 and rowNum != 1000
) t2 on (t1.partNum=1 and t1.rowNum=t2.rowNum)
when matched then update
set t1.amountNU = t2.amountNU;

/*Итоги*/
--ИТОГО ВЫРУЧКА ОТ РЕАЛИЗАЦИИ ПРОЧЕГО ИМУЩЕСТВА - ЗАЛОГОВ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=1
and rowNum between 200 and 399
) t2 on (t1.partNum=1 and t1.rowNum=400)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО ВЫРУЧКА ОТ РЕАЛИЗАЦИИ АМОРТИЗИРУЕМОГО ИМУЩЕСТВА И ИМУЩЕСТВЕННЫХ ПРАВ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=1
and rowNum between 600 and 799
) t2 on (t1.partNum=1 and t1.rowNum=800)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО ВЫРУЧКА ОТ РЕАЛИЗАЦИИ ПРАВА ТРЕБОВАНИЯ ДОЛГА
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=1
and rowNum between 1000 and 1199
) t2 on (t1.partNum=1 and t1.rowNum=1200)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО ПРОЧИЕ ДОХОДЫ ОТ РЕАЛИЗАЦИИ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=1
and rowNum between 1400 and 1899
) t2 on (t1.partNum=1 and t1.rowNum=1900)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО ДОХОДЫ ОТ РЕАЛИЗАЦИИ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=1
and rowNum in (400,800,1200,1900)
) t2 on (t1.partNum=1 and t1.rowNum=2000)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

/*Часть 2*/

/*по лицевикам*/
merge into #rep t1
using(
select
[rowNum] = a.rowNum	
,[accNum] = a.accNum	
,[amountBU] = isnull(rest.restOUT_BU * -1,0)
,[amountNU] = case when a.accNum in (
									'71201810003812400000' 
									,'71201810003812800000'
									) then isnull(rest.restOUT_NU * -1,0) else 0 end
from dwh2.finAnalytics.SPR_repPL_declaraciaIvanova a
left join dwh2.[finAnalytics].[SPR_PL_ACC] acc on a.accNum = acc.accNUM
left join dwh2.[finAnalytics].[repPLAccRests] rest on acc.ID=rest.accUID and rest.repmonth=@repmonth
where partNum=2
) t2 on (t1.partNum=2 and t1.rowNum=t2.rowNum)
when matched then update
set t1.amountBU = t2.amountBU,
	t1.amountNU = t2.amountNU;

/*Корректировки*/
merge into #rep t1
using(
	select
	[correctionPlus] = amountNU - amountBU
	,[rowNum] = a.rowNum
	from #rep a
	where a.partNum=2 and a.rowNum in (4300,4500)
) t2 on (t1.partNum=2 and t1.rowNum=t2.rowNum)
when matched then update
set t1.correctionPlus = t2.correctionPlus;

/*Данные по НУ*/
merge into #rep t1
using(
select
[rowNum] = a.rowNum	
,[amountNU] = case when a.rowNum not in (4300,4500) then a.amountBU + a.correctionPlus	- a.correctionMinus else a.amountNU end
from #rep a
where partNum=2
) t2 on (t1.partNum=2 and t1.rowNum=t2.rowNum)
when matched then update
set t1.amountNU = t2.amountNU;

/*Итоги*/
--5
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=2
and rowNum between 200 and 499
) t2 on (t1.partNum=2 and t1.rowNum=500)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--9
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=2
and rowNum between 600 and 899
) t2 on (t1.partNum=2 and t1.rowNum=900)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО ПОЛОЖ-ОЕ САЛЬДО ПЕРЕОЦЕНКИ ИН.ВАЛ., А ТАКЖЕ ИМУЩ-ВА И ТРЕБ-ИЙ, СТ-ТЬ КОТ. ВЫРАЖЕНА В ИН.ВАЛ.
merge into #rep t1
using(
select
[amountBU] = sum(case when a.rowNum =9 then a.amountBU *-1 else a.amountBU end)
,[correctionPlus] = sum(case when a.rowNum =9 then a.correctionPlus *-1 else a.correctionPlus end)
,[correctionMinus] = sum(case when a.rowNum =9 then a.correctionMinus *-1 else a.correctionMinus end)
,[amountNU] = sum(case when a.rowNum =9 then a.amountNU *-1 else a.amountNU end)
from #rep a
where partNum=2
and rowNum in (500,999)
) t2 on (t1.partNum=2 and t1.rowNum=1000)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО ДОХОД ОТ ПРЕДОСТАВЛЕНИЯ В АРЕНДУ 
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=2
and rowNum between 1200 and 1299
) t2 on (t1.partNum=2 and t1.rowNum=1300)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО ПРЕДОСТАВ. КРЕДИТОВ И ЗАЙМОВ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=2
and rowNum between 1500 and 2899 --in (15,16,17,18,19,20,21,22,23,24,25,26,27,28)
) t2 on (t1.partNum=2 and t1.rowNum=2900)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО ДОХОДЫ В ВИДЕ ШТРАФОВ ПЕНИ ИНЫХ САНКЦИЙ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=2
and rowNum between 3100 and 3499--in (31,32,33,34)
) t2 on (t1.partNum=2 and t1.rowNum=3500)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО ДОХОДЫ ПРОШЛЫХ ЛЕТ,ВЫЯВЛЕННЫЕ В ОТЧЕТНОМ ГОДУ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=2
and rowNum between 3700 and 3899--in (37,38)
) t2 on (t1.partNum=2 and t1.rowNum=3900)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО СУММЫ ОТЧИСЛЕНИЙ В РЕЗЕРВ НА ВОЗМОЖНЫЕ ПОТЕРИ ПО ССУДАМ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=2
and rowNum between 4100 and 4699--in (41,42,43,44,45,46)
) t2 on (t1.partNum=2 and t1.rowNum=4700)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО ПРОЧИЕ ВНЕРЕАЛИЗАЦИОННЫЕ ДОХОДЫ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=2
and rowNum between 4900 and 5099--in (49,50)
) t2 on (t1.partNum=2 and t1.rowNum=5100)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО ВНЕРЕАЛИЗАЦИОННЫЕ ДОХОДЫ 
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=2
and rowNum in (1000,1300,2900,3500,3900,4700,5100)
) t2 on (t1.partNum=2 and t1.rowNum=5200)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];



/*Часть 3*/

/*по лицевикам*/
merge into #rep t1
using(
select
[rowNum] = a.rowNum	
,[accNum] = a.accNum	
,[amountBU] = isnull(rest.restOUT_BU,0)
from dwh2.finAnalytics.SPR_repPL_declaraciaIvanova a
left join dwh2.[finAnalytics].[SPR_PL_ACC] acc on a.accNum = acc.accNUM
left join dwh2.[finAnalytics].[repPLAccRests] rest on acc.ID=rest.accUID and rest.repmonth=@repmonth
where partNum=3
) t2 on (t1.partNum=3 and t1.rowNum=t2.rowNum)
when matched then update
set t1.amountBU = t2.amountBU;


/*Корректировки*/
merge into #rep t1
using(
	select
	correctionPlus = sum(isnull(l1.correctionPlus,0))
	,correctionMinus = sum(isnull(l1.correctionMinus,0))
	from(
	select
	correctionPlus = case when a.[Сумма корректировки] <0 then abs(a.[Сумма корректировки]) else 0 end
	,correctionMinus = case when a.[Сумма корректировки] >0 then a.[Сумма корректировки] else 0 end
	from dwh2.[finAnalytics].[SPR_PL_OS_NMA] a
	where a.repMonth between datefromParts(Year(@repmonth),1,1) and @repmonth
	and a.Показатель = 'Амортизация ОС(мебель и офисное оборудование)'
	) l1
) t2 on (t1.partNum=3 and t1.rowNum=5400)
when matched then update
set t1.correctionPlus = t2.correctionPlus,
	t1.correctionMinus = t2.correctionMinus;

/*Только 2025 год*/
merge into #rep t1
using(
	select
	rowNum = 400
	,correctionPlus = 0
	,correctionMinus = 89409
) t2 on (t1.partNum=3 and t1.rowNum=t2.rowNum and t1.repmonth between '2025-09-01' and '2025-12-01')
when matched then update
set t1.correctionPlus = t2.correctionPlus,
	t1.correctionMinus = t2.correctionMinus;

merge into #rep t1
using(
	select
	rowNum = 500
	,correctionPlus = 0
	,correctionMinus = 1730174
) t2 on (t1.partNum=3 and t1.rowNum=t2.rowNum and t1.repmonth between '2025-09-01' and '2025-12-01')
when matched then update
set t1.correctionPlus = t2.correctionPlus,
	t1.correctionMinus = t2.correctionMinus;

merge into #rep t1
using(
	select
	correctionPlus = sum(isnull(l1.correctionPlus,0))
	,correctionMinus = sum(isnull(l1.correctionMinus,0))
	from(
	select
	correctionPlus = case when a.[Сумма корректировки] <0 then abs(a.[Сумма корректировки]) else 0 end
	,correctionMinus = case when a.[Сумма корректировки] >0 then a.[Сумма корректировки] else 0 end
	from dwh2.[finAnalytics].[SPR_PL_OS_NMA] a
	where a.repMonth between datefromParts(Year(@repmonth),1,1) and @repmonth
	and a.Показатель = 'Амортизация НМА'
	) l1
) t2 on (t1.partNum=3 and t1.rowNum=5500)
when matched then update
set t1.correctionPlus = t2.correctionPlus,
	t1.correctionMinus = t2.correctionMinus;

--оборот за период с 01.01 по конец отчетного периода по Дт по БУ счета 60305810000000000002
merge into #rep t1
using(
	select
	[correctionPlus] = isnull(sum(isnull(sumDT_BU,0)),0)
	from dwh2.finAnalytics.OSV_MONTHLY a
	where a.repMonth between dateFromParts(year(@repmonth),1,1) and @repmonth
	and accNum='60305810000000000002'
) t2 on (t1.partNum=3 and t1.rowNum=5800)
when matched then update
set t1.correctionPlus = t2.correctionPlus;

--оборот за период с 01.01 по конец отчетного периода по Дт по БУ счета 60335810000000000010 и 60335810000000000014
merge into #rep t1
using(
	select
	[correctionPlus] = isnull(sum(isnull(sumDT_BU,0)),0)
	from dwh2.finAnalytics.OSV_MONTHLY a
	where a.repMonth between dateFromParts(year(@repmonth),1,1) and @repmonth
	and accNum in ('60335810000000000010','60335810000000000014')
) t2 on (t1.partNum=3 and t1.rowNum=6400)
when matched then update
set t1.correctionPlus = t2.correctionPlus;

--оборот за период с 01.01 по конец отчетного периода по Дт по БУ счета 60323810010000000000
merge into #rep t1
using(
	select
	[correctionPlus] = isnull(sum(isnull(sumDT_BU,0)),0)
	from dwh2.finAnalytics.OSV_MONTHLY a
	where a.repMonth between dateFromParts(year(@repmonth),1,1) and @repmonth
	and accNum in ('60323810010000000000')
) t2 on (t1.partNum=3 and t1.rowNum=8500)
when matched then update
set t1.correctionPlus = t2.correctionPlus;


/*Данные по НУ*/
merge into #rep t1
using(
select
[rowNum] = a.rowNum	
,[amountNU] = a.amountBU + a.correctionPlus	- a.correctionMinus--case when a.rowNum != 43 then a.amountBU + a.correctionPlus	- a.correctionMinus else a.amountNU end
from #rep a
where partNum=3
) t2 on (t1.partNum=3 and t1.rowNum=t2.rowNum)
when matched then update
set t1.amountNU = t2.amountNU;

/*Итоги*/
--ИТОГО КОМИССИОННЫЕ РАСХОДЫ, БАНКОВСКИЕ УСЛУГИ, УСЛУГИ ПЛАТЕЖНЫХ СИСТЕМ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 200 and 699
) t2 on (t1.partNum=3 and t1.rowNum=700)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО УСЛУГИ СВЯЗИ, ИНТЕРНЕТА И АНАЛОГИЧНЫЕ УСЛУГИ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 900 and 1399
) t2 on (t1.partNum=3 and t1.rowNum=1400)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО РАСХОДЫ НА СОДЕРЖАНИЕ ПОМЕЩЕНИЙ
merge into #rep t1
using(
select
[amountBU] = sum(case when a.rowNum =9 then a.amountBU *-1 else a.amountBU end)
,[correctionPlus] = sum(case when a.rowNum =9 then a.correctionPlus *-1 else a.correctionPlus end)
,[correctionMinus] = sum(case when a.rowNum =9 then a.correctionMinus *-1 else a.correctionMinus end)
,[amountNU] = sum(case when a.rowNum =9 then a.amountNU *-1 else a.amountNU end)
from #rep a
where partNum=3
and rowNum between 1600 and 2299
) t2 on (t1.partNum=3 and t1.rowNum=2300)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО УСЛУГИ СПРАВОЧНЫХ СИСТЕМ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 2500 and 2699
) t2 on (t1.partNum=3 and t1.rowNum=2700)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО РАСХОДЫ НА РАЗРАБОТКУ ПО /  ЛИЦЕНЗИИ ПО
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 2900 and 3299
) t2 on (t1.partNum=3 and t1.rowNum=3300)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО РАСХОДЫ ПО АРЕНДЕ ПОМЕЩЕНИЙ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 3500 and 3899
) t2 on (t1.partNum=3 and t1.rowNum=3900)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО МАТЕРИАЛЬНЫЕ РАСХ. НА ПРИОБРЕТЕНИЕ СЫРЬЯ И МАТЕРИАЛОВ, СПИСАННЫХ ПРИ ОКАЗАНИИ УСЛУГ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 4300 and 5099
) t2 on (t1.partNum=3 and t1.rowNum=5100)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО СУММЫ НАЧИСЛЕННОЙ АМОРТИЗАЦИИ ПО ОСНОВНЫМ СРЕДСТВАМ/НМА
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 5300 and 5599
) t2 on (t1.partNum=3 and t1.rowNum=5600)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО РАСХОДЫ ПО ОПЛАТЕ ТРУДА, ПРЕДУСМ. СТ. 255 НК РФ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 5800 and 6599
) t2 on (t1.partNum=3 and t1.rowNum=6600)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО РАСХОДЫ НА РЕМОНТ ОСНОВНЫХ СРЕДСТВ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 6800 and 5999
) t2 on (t1.partNum=3 and t1.rowNum=7000)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО СУММЫ НАЛОГОВ И СБОРОВ, НАЧИСЛЕННЫЕ В УСТАНОВЛЕННОМ ПОРЯДКЕ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 7200 and 7499
) t2 on (t1.partNum=3 and t1.rowNum=7500)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО РАСХОДЫ НА ОХРАНУ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 7700 and 7799
) t2 on (t1.partNum=3 and t1.rowNum=7800)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО РАСХОДЫ НА ОПЛАТУ ЮРИДИЧЕСКИХ, ИНФОРМАЦИОННЫХ,КОНСУЛЬТАЦИОННЫХ И АНАЛОГИЧНЫХ УСЛУГ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 8000 and 8599
) t2 on (t1.partNum=3 and t1.rowNum=8600)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО РАСХОДЫ ПО ВЫБЫТИЮ ПРОЧЕГО ИМУЩЕСТВА - ЗАЛОГОВ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 8800 and 8999
) t2 on (t1.partNum=3 and t1.rowNum=9000)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО РАСХОДЫ НА РЕКЛАМУ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 9200 and 10499
) t2 on (t1.partNum=3 and t1.rowNum=10500)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО ПОДДЕРЖКА И СОПРОВОЖДЕНИЕ ПО
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 10700 and 10799
) t2 on (t1.partNum=3 and t1.rowNum=10800)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО Убытки в особом порядке
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 11000 and 11099
) t2 on (t1.partNum=3 and t1.rowNum=11100)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО ПРОЧИЕ РАСХОДЫ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum between 11300 and 14699
) t2 on (t1.partNum=3 and t1.rowNum=14700)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО РАСХОДЫ ОТ РЕАЛИЗАЦИИ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=3
and rowNum in (700,1400,2300,2700,3300,3900,4100,5100,5600,6600,7000,7500,7800,8600,9000,10500,10800,11100,14700)
) t2 on (t1.partNum=3 and t1.rowNum=14800)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];



/*Часть 4*/

/*по лицевикам*/
merge into #rep t1
using(
select
[rowNum] = a.rowNum	
,[accNum] = a.accNum	
,[amountBU] = isnull(rest.restOUT_BU,0)
,[amountNU] = case when a.rowNum in (2600,2700,2800,2900,3000/*,3900*/) then isnull(rest.restOUT_NU,0) else 0 end
from dwh2.finAnalytics.SPR_repPL_declaraciaIvanova a
left join dwh2.[finAnalytics].[SPR_PL_ACC] acc on a.accNum = acc.accNUM
left join dwh2.[finAnalytics].[repPLAccRests] rest on acc.ID=rest.accUID and rest.repmonth=@repmonth
where partNum=4
) t2 on (t1.partNum=4 and t1.rowNum=t2.rowNum)
when matched then update
set t1.amountBU = t2.amountBU,
	t1.amountNU = t2.amountNU;


/*Корректировки*/
merge into #rep t1
using(
	select
	rowNum
	,[correctionPlus] = amountNU - amountBU
	from #rep a
	where a.partNum=4 and a.rowNum in (2700,2800,2900,3000/*,3900*/)
) t2 on (t1.partNum=4 and t1.rowNum = t2.rowNum)
when matched then update
set t1.correctionPlus = t2.correctionPlus;

merge into #rep t1
using(
	select
	[rowNum] = a.rowNum	
	,[accNum] = a.accNum	
	,[amountNU] = case when a.rowNum in (3900) then isnull(rest.restOUT_NU,0) else 0 end
	from dwh2.finAnalytics.SPR_repPL_declaraciaIvanova a
	left join dwh2.[finAnalytics].[SPR_PL_ACC] acc on a.accNum = acc.accNUM
	left join dwh2.[finAnalytics].[repPLAccRests] rest on acc.ID=rest.accUID and rest.repmonth=@repmonth
	where partNum=4 and a.rowNum in (3900)
) t2 on (t1.partNum=4 and t1.rowNum = t2.rowNum)
when matched then update
set t1.correctionPlus = t2.[amountNU] - t1.[amountBU];

/*Доработка по FINA-176*/ --repmonth	part	partNum	rowNum	rowName	accNum	pokazatel	amountBU	correctionPlus	correctionMinus	amountNU	comment
						  --2025-11-01	ВНЕРЕАЛИЗАЦИОННЫЕ РАСХОДЫ	4	3900		71502810004140700000	Уступка прав требования по договорам займа ФЛ	5943497,52	381582968,97	0	387526466,49	
						  -- с Января 2026
if @repmonth >= '2026-01-01'
merge into #rep t1
using(
	select
	rowNum = 3900
	,[correctionMinus] = abs(l1.[corrRegistr])
	from (
	SELECT 
	  [repmonth] = dateDogCession
      ,[corrRegistr] = [corrRegistr]
  FROM [dwh2].[finAnalytics].[CessionUbt]
  where  dateDogCession = @repmonth
  ) l1
) t2 on (t1.partNum=4 and t1.rowNum = t2.rowNum)
when matched then update
set t1.correctionMinus = t2.correctionMinus;



/*Данные по НУ*/
merge into #rep t1
using(
select
[rowNum] = a.rowNum	
,[amountNU] = case when a.rowNum not in (2200,2300,2600,2700,2800,2900,3000) then a.amountBU + a.correctionPlus	- a.correctionMinus else a.amountNU end
from #rep a
where partNum=4
) t2 on (t1.partNum = 4 and t1.rowNum=t2.rowNum)
when matched then update
set t1.amountNU = t2.amountNU;

/*Итоги*/
--ИТОГО % ПО ДОГОВОРАМ ЗАЙМА И ПРОЧИМ ПРИВЛЕЧЕННЫМ ДЕНЕЖ. СР-АМ ФИЗ. И ЮР. ЛИЦ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=4
and rowNum between 200 and 1999
) t2 on (t1.partNum=4 and t1.rowNum=2000)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО Расходы в виде пени, штрафов и иных санкций
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=4
and rowNum between 2200 and 2399
) t2 on (t1.partNum=4 and t1.rowNum=2400)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО СУММЫ ОТЧИСЛЕНИЙ В РЕЗЕРВ НА ВОЗМОЖНЫЕ ПОТЕРИ ПО ССУДАМ, ПОДЛЕЖАЩИМ РЕЗЕРВИРОВАНИЮ С УЧЕТОМ ПОЛОЖЕНИЙ СТ.292 НК
merge into #rep t1
using(
select
[amountBU] = sum(case when a.rowNum =9 then a.amountBU *-1 else a.amountBU end)
,[correctionPlus] = sum(case when a.rowNum =9 then a.correctionPlus *-1 else a.correctionPlus end)
,[correctionMinus] = sum(case when a.rowNum =9 then a.correctionMinus *-1 else a.correctionMinus end)
,[amountNU] = sum(case when a.rowNum =9 then a.amountNU *-1 else a.amountNU end)
from #rep a
where partNum=4
and rowNum between 2600 and 3099
) t2 on (t1.partNum=4 and t1.rowNum=3100)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=4
and rowNum between 3500 and 3599
) t2 on (t1.partNum=4 and t1.rowNum=3600)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО ПРОЧИЕ ВНЕРЕАЛИЗАЦИОННЫЕ РАСХОДЫ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=4
and rowNum between 3800 and 3999
) t2 on (t1.partNum=4 and t1.rowNum=4000)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];

--ИТОГО ВНЕРЕАЛИЗАЦИОННЫЕ РАСХОДЫ 
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=4
and rowNum in (2000,2400,3100,3300,3600,4000)
) t2 on (t1.partNum=4 and t1.rowNum=4100)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];



/*Часть 5*/

/*по лицевикам*/
merge into #rep t1
using(
select
[rowNum] = a.rowNum	
,[accNum] = a.accNum	
,[amountBU] = isnull(rest.restOUT_BU * -1,0)
from dwh2.finAnalytics.SPR_repPL_declaraciaIvanova a
left join dwh2.[finAnalytics].[SPR_PL_ACC] acc on a.accNum = acc.accNUM
left join dwh2.[finAnalytics].[repPLAccRests] rest on acc.ID=rest.accUID and rest.repmonth=@repmonth
where partNum=5
) t2 on (t1.partNum=5 and t1.rowNum=t2.rowNum)
when matched then update
set t1.amountBU = t2.amountBU;


/*Данные по НУ*/
merge into #rep t1
using(
select
[rowNum] = a.rowNum	
,[amountNU] = a.amountBU + a.correctionPlus	- a.correctionMinus--case when a.rowNum != 43 then a.amountBU + a.correctionPlus	- a.correctionMinus else a.amountNU end
from #rep a
where partNum=5
) t2 on (t1.partNum = 5 and t1.rowNum=t2.rowNum)
when matched then update
set t1.amountNU = t2.amountNU;

/*Итоги*/
--ИТОГО Доходы не включаемые в НОБ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=5
and rowNum between 100 and 499
) t2 on (t1.partNum=5 and t1.rowNum=500)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];


/*Часть 6*/

/*по лицевикам*/
merge into #rep t1
using(
select
[rowNum] = a.rowNum	
,[accNum] = a.accNum	
,[amountBU] = isnull(rest.restOUT_BU,0)
from dwh2.finAnalytics.SPR_repPL_declaraciaIvanova a
left join dwh2.[finAnalytics].[SPR_PL_ACC] acc on a.accNum = acc.accNUM
left join dwh2.[finAnalytics].[repPLAccRests] rest on acc.ID=rest.accUID and rest.repmonth=@repmonth
where partNum=6
) t2 on (t1.partNum=6 and t1.rowNum=t2.rowNum)
when matched then update
set t1.amountBU = t2.amountBU;

/*Корректировки*/
--оборот за период с 01.01 по конец отчетного периода по Дт по БУ счета 60305810000000000002
merge into #rep t1
using(
	select
	[correctionMinus] = isnull(sum(isnull(sumDT_BU,0)),0)
	from dwh2.finAnalytics.OSV_MONTHLY a
	where a.repMonth between dateFromParts(year(@repmonth),1,1) and @repmonth
	and accNum='60305810000000000002'
) t2 on (t1.partNum=6 and t1.rowNum=700)
when matched then update
set t1.correctionMinus = t2.correctionMinus;

--оборот за период с 01.01 по конец отчетного периода по Дт по БУ счета 60335810000000000010 и 60335810000000000014
merge into #rep t1
using(
	select
	[correctionMinus] = isnull(sum(isnull(sumDT_BU,0)),0)
	from dwh2.finAnalytics.OSV_MONTHLY a
	where a.repMonth between dateFromParts(year(@repmonth),1,1) and @repmonth
	and accNum in ('60335810000000000010','60335810000000000014')
) t2 on (t1.partNum=6 and t1.rowNum=800)
when matched then update
set t1.correctionMinus = t2.correctionMinus;


/*Данные по НУ*/
merge into #rep t1
using(
select
[rowNum] = a.rowNum	
,[amountNU] = a.amountBU + a.correctionPlus	- a.correctionMinus--case when a.rowNum != 43 then a.amountBU + a.correctionPlus	- a.correctionMinus else a.amountNU end
from #rep a
where partNum=6
) t2 on (t1.partNum = 6 and t1.rowNum=t2.rowNum)
when matched then update
set t1.amountNU = t2.amountNU;

/*Итоги*/
--ИТОГО Расходы не включаемые в НОБ
merge into #rep t1
using(
select
[amountBU] = sum(a.amountBU)
,[correctionPlus] = sum(a.correctionPlus )
,[correctionMinus] = sum(a.correctionMinus)
,[amountNU] = sum(a.amountNU)
from #rep a
where partNum=6
and rowNum between 100 and 2499
) t2 on (t1.partNum=6 and t1.rowNum=2500)
when matched then update
set t1.[amountBU] = t2.[amountBU]
	,t1.[correctionPlus] = t2.[correctionPlus]
	,t1.[correctionMinus] = t2.[correctionMinus]
	,t1.[amountNU] = t2.[amountNU];


/*Очистка таблицы от старых данных за отчетный месяц*/
delete from dwh2.[finAnalytics].[repPLDeclaraciaIvanova] where repmonth = @repmonth

/*Добавление новых данных за отчетный месяц*/
INSERT INTO dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
([repmonth], [part], [partNum], [rowNum], [rowName], [accNum], [pokazatel], [amountBU], [correctionPlus], [correctionMinus], [amountNU], [comment])
select 
repmonth	
,part	
,partNum	
,rowNum	
,rowName	
,accNum	
,pokazatel	
,amountBU	
,correctionPlus	
,correctionMinus	
,amountNU	
,comment
from #rep


	
	commit tran

	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try
    
    begin catch

    
	DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для отчета PL для публикуемой. Декларация Иванова.'
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients =''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch
END
