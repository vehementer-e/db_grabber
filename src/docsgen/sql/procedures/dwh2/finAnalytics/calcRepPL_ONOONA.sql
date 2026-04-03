





CREATE PROC [finAnalytics].[calcRepPL_ONOONA] 
    @repmonth date
AS
BEGIN
	DECLARE @subject NVARCHAR(2048) = 'Расчет данных для PL для публикуемой. Данные ОНО/ОНА.'
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
	
	
/*Шаг 1 - расчитываем остатки*/

drop table if exists #accRests

select
acc.repMonth
,acc.acc2order
,restIN_BU = sum(isnull(restIN_BU,0))
,restIN_NU = sum(isnull(restIN_NU,0))
,sumDT_BU = sum(isnull(sumDT_BU,0))
,sumDT_NU = sum(isnull(sumDT_NU,0))
,sumKT_BU = sum(isnull(sumKT_BU,0))
,sumKT_NU = sum(isnull(sumKT_NU,0))
,restOUT_BU = sum(isnull(restOUT_BU,0))
,restOUT_NU = sum(isnull(restOUT_NU,0))
into #accRests
from dwh2.[finAnalytics].[OSV_MONTHLY] acc
where (
		acc2order in (
					'60401',
					'60414',
					'62001',
					'60901',
					'60903',
					'60804',
					'60805',
					'60806',
					--'60305'
					--'60335',
					'48810',
					'48710',
					'49410'
					--'60323'
					)
		or
		accNum in ('60305810000000000002'
				  ,'60335810000000000010'
				  ,'60335810000000000014'
				  ,'60323810010000000000'
    				)
		)
and acc.repMonth = @repmonth

group by 
acc.repMonth
,acc.acc2order


/*Шаг 2 - создаем скелет отчета*/
drop table if exists #rep
create table #rep(
rowNum int not null,
nalogObject nvarchar(300) null,
balAccNum nvarchar(30) null,
valCode nvarchar(30) null,	
restActive_IN float null,
restPassive_IN float null,
nalogBase_IN float null,
timeDiffNalog_IN float null,
timeDiffMinus_IN float null,
nalogDelayPassiveFR_IN float null,
nalogDelayPassiveKap_IN float null,
nalogDelayActiveFR_IN float null,
nalogDelayActiveKap_IN float null,
nalogDelaySPOD_IN float null,
restActive_OUT float null,
restPassive_OUT float null,
nalogBase_OUT float null,
timeDiffNalog_OUT float null,
timeDiffMinus_OUT float null,
nalogDelayPassiveFR_OUT float null,
nalogDelayPassiveKap_OUT float null,
nalogDelayActiveFR_OUT float null,
nalogDelayActiveKap_OUT float null,
nalogDelaySPOD_OUT float null
)

insert into #rep
select
rowNum	
,nalogObject	
,balAccNum	
,valCode	
--На начало периода
,restActive_IN = 0	
,restPassive_IN = 0	
,nalogBase_IN = 0	
,timeDiffNalog_IN = 0	
,timeDiffMinus_IN = 0	
,nalogDelayPassiveFR_IN = 0	
,nalogDelayPassiveKap_IN = 0
,nalogDelayActiveFR_IN = 0
,nalogDelayActiveKap_IN = 0
,nalogDelaySPOD_IN = 0
--На конец периода
,restActive_OUT = 0	
,restPassive_OUT = 0	
,nalogBase_OUT = 0	
,timeDiffNalog_OUT = 0	
,timeDiffMinus_OUT = 0	
,nalogDelayPassiveFR_OUT = 0	
,nalogDelayPassiveKap_OUT = 0
,nalogDelayActiveFR_OUT = 0
,nalogDelayActiveKap_OUT = 0
,nalogDelaySPOD_OUT = 0

from dwh2.[finAnalytics].[SPR_repPL_ONOONA]


/*Шаг 3 - наполняем скелет остатками*/

--p1
merge into #rep t1
using(
select
*
from #accRests b 
where b.acc2order = '60401'
) t2 on (t1.rowNum=1)
when matched then update
set 
	t1.restActive_IN = t2.restIN_BU,
	t1.nalogBase_IN = t2.restIN_BU,

	t1.restActive_OUT = t2.restOUT_BU,
	t1.nalogBase_OUT = t2.restout_BU;

--p2
merge into #rep t1
using(
select
*
from #accRests b 
where b.acc2order = '60414'
) t2 on (t1.rowNum=2)
when matched then update
set 
	t1.restPassive_IN = t2.restIN_BU * -1,
	t1.nalogBase_IN = t2.restIN_NU * -1,

	t1.restPassive_OUT = t2.restOUT_BU * -1,
	t1.nalogBase_OUT = t2.restOUT_NU * -1;

--p3
merge into #rep t1
using(
select
*
from #accRests b 
where b.acc2order = '62001'
) t2 on (t1.rowNum=3)
when matched then update
set 
	t1.restActive_IN = t2.restIN_BU,
	t1.nalogBase_IN = t2.restIN_BU,--t1.nalogBase_IN = t2.restIN_NU,

	t1.restActive_OUT = t2.restOUT_BU,
	t1.nalogBase_OUT = t2.restout_BU;--t1.nalogBase_OUT = t2.restout_NU;

--p4
merge into #rep t1
using(
select
*
from #accRests b 
where b.acc2order = '60901'
) t2 on (t1.rowNum=4)
when matched then update
set 
	t1.restActive_IN = t2.restIN_BU,
	t1.nalogBase_IN = t2.restIN_BU,--t1.nalogBase_IN = t2.restIN_NU,

	t1.restActive_OUT = t2.restOUT_BU,
	t1.nalogBase_OUT = t2.restout_BU;--t1.nalogBase_OUT = t2.restout_NU;

--p5
merge into #rep t1
using(
select
*
from #accRests b 
where b.acc2order = '60903'
) t2 on (t1.rowNum=5)
when matched then update
set 
	t1.restPassive_IN = t2.restIN_BU *-1,
	t1.nalogBase_IN = t2.restIN_NU *-1,

	t1.restPassive_OUT = t2.restOUT_BU *-1,
	t1.nalogBase_OUT = t2.restout_NU *-1;

--p6 сальдо на конец периода по счета 60804 по БУ минус сальдо на конец периода по счета 60805 по БУ
merge into #rep t1
using(
select
restIN_BU = sum(isnull(restIN_BU,0))--sum(isnull(case when b.acc2order = '60805' then restIN_BU *-1 else restIN_BU end,0))
,restIN_NU = sum(isnull(restIN_NU,0))-- sum(isnull(case when b.acc2order = '60805' then restIN_NU *-1 else restIN_NU end,0))
,sumDT_BU = sum(isnull(sumDT_BU,0))--sum(isnull(case when b.acc2order = '60805' then sumDT_BU *-1 else sumDT_BU end,0))
,sumDT_NU = sum(isnull(sumDT_NU,0))--sum(isnull(case when b.acc2order = '60805' then sumDT_NU *-1 else sumDT_NU end,0))
,sumKT_BU = sum(isnull(sumKT_BU,0))--sum(isnull(case when b.acc2order = '60805' then sumKT_BU *-1 else sumKT_BU end,0))
,sumKT_NU = sum(isnull(sumKT_NU,0))--sum(isnull(case when b.acc2order = '60805' then sumKT_NU *-1 else sumKT_NU end,0))
,restOUT_BU = sum(isnull(restOUT_BU,0))--sum(isnull(case when b.acc2order = '60805' then restOUT_BU *-1 else restOUT_BU end,0))
,restOUT_NU = sum(isnull(restOUT_NU,0))--sum(isnull(case when b.acc2order = '60805' then restOUT_NU *-1 else restOUT_NU end,0))
--select *
from #accRests b 
where b.acc2order in ('60804','60805')
) t2 on (t1.rowNum=6)
when matched then update
set 
	t1.restActive_IN = t2.restIN_BU,
	t1.restActive_OUT = t2.restOUT_BU;

--p7
merge into #rep t1
using(
select
*
from #accRests b 
where b.acc2order = '60806'
) t2 on (t1.rowNum=7)
when matched then update
set 
	t1.restPassive_IN = t2.restIN_BU *-1,
	t1.restPassive_OUT = t2.restOUT_BU *-1;

--p9
merge into #rep t1
using(
select
*
from #accRests b 
where b.acc2order = '60305'
) t2 on (t1.rowNum=9)
when matched then update
set 
	t1.restPassive_IN = t2.restIN_BU *-1,
	t1.restPassive_OUT = t2.restOUT_BU *-1;

--p10
merge into #rep t1
using(
select
*
from #accRests b 
where b.acc2order = '60335'
) t2 on (t1.rowNum=10)
when matched then update
set 
	t1.restPassive_IN = t2.restIN_BU *-1,
	t1.restPassive_OUT = t2.restOUT_BU *-1;

--p12
merge into #rep t1
using(
select
*
from #accRests b 
where b.acc2order = '48810'
) t2 on (t1.rowNum=12)
when matched then update
set 
	t1.restPassive_IN = t2.restIN_BU *-1,
	t1.nalogBase_IN = t2.restIN_NU *-1,

	t1.restPassive_OUT = t2.restOUT_BU *-1,
	t1.nalogBase_OUT = t2.restout_NU *-1;

--p13
merge into #rep t1
using(
select
*
from #accRests b 
where b.acc2order = '48710'
) t2 on (t1.rowNum=13)
when matched then update
set 
	t1.restPassive_IN = t2.restIN_BU *-1,
	t1.nalogBase_IN = t2.restIN_NU *-1,

	t1.restPassive_OUT = t2.restOUT_BU *-1,
	t1.nalogBase_OUT = t2.restout_NU *-1;

--p14
merge into #rep t1
using(
select
*
from #accRests b 
where b.acc2order = '49410'
) t2 on (t1.rowNum=14)
when matched then update
set 
	t1.restPassive_IN = t2.restIN_BU *-1,
	t1.nalogBase_IN = t2.restIN_NU *-1,

	t1.restPassive_OUT = t2.restOUT_BU *-1,
	t1.nalogBase_OUT = t2.restout_NU *-1;

--p15
merge into #rep t1
using(
select
*
from #accRests b 
where b.acc2order = '60323'
) t2 on (t1.rowNum=15)
when matched then update
set 
	t1.restActive_IN = t2.restIN_BU,
	t1.restActive_OUT = t2.restOUT_BU;


/*Шаг 4 - расчет временных разниц и налоговых обязательств*/

declare @stavkaNP float = (select [stavka] FROM [dwh2].[finAnalytics].[SPR_repPL_NP] where @repmonth between [dateFrom] and [dateTo])

--p1 - p15
merge into #rep t1
using(
select
rowNum	
,restActive_IN	--4
,restPassive_IN	--5
,nalogBase_IN	--6

/*При условии, что столбец 5 равен 0 
		и если (столбец 4 - cтолбец 6)>0, то (столбец 4 - cтолбец 6) , 
		иначе = 0
	    А при условии, что столбец 5 не равен 0 
		и если (столбец 6 - cтолбец 5)>0, то (столбец 6 - cтолбец 5), 
		иначе = 0
		*/
,timeDiffNalog_IN = case when restPassive_IN = 0 then 
						case when restActive_IN - nalogBase_IN > 0 then restActive_IN - nalogBase_IN
							 else 0
						end
					  when restPassive_IN != 0 then 
						case when nalogBase_IN - restPassive_IN > 0 then nalogBase_IN - restPassive_IN
							 else 0
						end
					else null end
/*
		При условии, что столбец 5 равен 0 
		и если (столбец 6 - cтолбец 4)>0, то (столбец 6- cтолбец 4) , 
		иначе = 0
		А при условии, что столбец 5 не равен 0 
		и если (столбец 5 - cтолбец 6)>0, то (столбец 5 - cтолбец 6), 
		иначе = 0
*/
,timeDiffMinus_IN = case when restPassive_IN = 0 then 
						case when nalogBase_IN - restActive_IN > 0 then nalogBase_IN - restActive_IN
							 else 0
						end
					  when restPassive_IN != 0 then 
						case when restPassive_IN - nalogBase_IN > 0 then restPassive_IN - nalogBase_IN
							 else 0
						end
					else null end
,restActive_OUT	--4
,restPassive_OUT	--5
,nalogBase_OUT	--6

,timeDiffNalog_OUT = case when restPassive_OUT = 0 then 
						case when restActive_OUT - nalogBase_OUT > 0 then restActive_OUT - nalogBase_OUT
							 else 0
						end
					  when restPassive_OUT != 0 then 
						case when nalogBase_OUT - restPassive_OUT > 0 then nalogBase_OUT - restPassive_OUT
							 else 0
						end
					else null end
,timeDiffMinus_OUT = case when restPassive_OUT = 0 then 
						case when nalogBase_OUT - restActive_OUT > 0 then nalogBase_OUT - restActive_OUT
							 else 0
						end
					  when restPassive_OUT != 0 then 
						case when restPassive_OUT - nalogBase_OUT > 0 then restPassive_OUT - nalogBase_OUT
							 else 0
						end
					else null end

from #rep  
where rowNum in (1,2,3,4,5,6,7,9,10,12,13,14,15)
) t2 on (t1.rowNum=t2.rowNum)
when matched then update
set 
	t1.timeDiffNalog_IN = t2.timeDiffNalog_IN,
	t1.timeDiffMinus_IN = t2.timeDiffMinus_IN,
	t1.timeDiffNalog_OUT = t2.timeDiffNalog_OUT,
	t1.timeDiffMinus_OUT = t2.timeDiffMinus_OUT,

	t1.nalogDelayPassiveFR_IN = t2.timeDiffNalog_IN * @stavkaNP,
	t1.nalogDelayActiveFR_IN = t2.timeDiffMinus_IN * @stavkaNP,
	t1.nalogDelayPassiveFR_OUT = t2.timeDiffNalog_OUT * @stavkaNP,
	t1.nalogDelayActiveFR_OUT = t2.timeDiffMinus_OUT * @stavkaNP;

/*Шаг 5 - расчет итоговых строк*/

merge into #rep t1
using(
select
timeDiffNalog_IN = sum(timeDiffNalog_IN)
,timeDiffMinus_IN = sum(timeDiffMinus_IN)
,nalogDelayPassiveFR_IN = sum(nalogDelayPassiveFR_IN)
,nalogDelayPassiveKap_IN = sum(nalogDelayPassiveKap_IN)
,nalogDelayActiveFR_IN = sum(nalogDelayActiveFR_IN)
,nalogDelayActiveKap_IN = sum(nalogDelayActiveKap_IN)
,nalogDelaySPOD_IN = sum(nalogDelaySPOD_IN)

,timeDiffNalog_OUT = sum(timeDiffNalog_OUT)
,timeDiffMinus_OUT = sum(timeDiffMinus_OUT)
,nalogDelayPassiveFR_OUT = sum(nalogDelayPassiveFR_OUT)
,nalogDelayPassiveKap_OUT = sum(nalogDelayPassiveKap_OUT)
,nalogDelayActiveFR_OUT = sum(nalogDelayActiveFR_OUT)
,nalogDelayActiveKap_OUT = sum(nalogDelayActiveKap_OUT)
,nalogDelaySPOD_OUT = sum(nalogDelaySPOD_OUT)

from #rep
where rowNum in (1,2,3,4,5,6,7)
) t2 on (t1.rowNum=8)
when matched then update
set 
	t1.timeDiffNalog_IN = t2.timeDiffNalog_IN
	,t1.timeDiffMinus_IN = t2.timeDiffMinus_IN
	,t1.nalogDelayPassiveFR_IN = t2.nalogDelayPassiveFR_IN
	,t1.nalogDelayPassiveKap_IN = t2.nalogDelayPassiveKap_IN
	,t1.nalogDelayActiveFR_IN = t2.nalogDelayActiveFR_IN
	,t1.nalogDelayActiveKap_IN = t2.nalogDelayActiveKap_IN
	,t1.nalogDelaySPOD_IN = t2.nalogDelaySPOD_IN

	,t1.timeDiffNalog_OUT = t2.timeDiffNalog_OUT
	,t1.timeDiffMinus_OUT = t2.timeDiffMinus_OUT
	,t1.nalogDelayPassiveFR_OUT = t2.nalogDelayPassiveFR_OUT
	,t1.nalogDelayPassiveKap_OUT = t2.nalogDelayPassiveKap_OUT
	,t1.nalogDelayActiveFR_OUT = t2.nalogDelayActiveFR_OUT
	,t1.nalogDelayActiveKap_OUT = t2.nalogDelayActiveKap_OUT
	,t1.nalogDelaySPOD_OUT = t2.nalogDelaySPOD_OUT;

merge into #rep t1
using(
select
timeDiffNalog_IN = sum(timeDiffNalog_IN)
,timeDiffMinus_IN = sum(timeDiffMinus_IN)
,nalogDelayPassiveFR_IN = sum(nalogDelayPassiveFR_IN)
,nalogDelayPassiveKap_IN = sum(nalogDelayPassiveKap_IN)
,nalogDelayActiveFR_IN = sum(nalogDelayActiveFR_IN)
,nalogDelayActiveKap_IN = sum(nalogDelayActiveKap_IN)
,nalogDelaySPOD_IN = sum(nalogDelaySPOD_IN)

,timeDiffNalog_OUT = sum(timeDiffNalog_OUT)
,timeDiffMinus_OUT = sum(timeDiffMinus_OUT)
,nalogDelayPassiveFR_OUT = sum(nalogDelayPassiveFR_OUT)
,nalogDelayPassiveKap_OUT = sum(nalogDelayPassiveKap_OUT)
,nalogDelayActiveFR_OUT = sum(nalogDelayActiveFR_OUT)
,nalogDelayActiveKap_OUT = sum(nalogDelayActiveKap_OUT)
,nalogDelaySPOD_OUT = sum(nalogDelaySPOD_OUT)

from #rep
where rowNum in (9,10)
) t2 on (t1.rowNum=11)
when matched then update
set 
	t1.timeDiffNalog_IN = t2.timeDiffNalog_IN
	,t1.timeDiffMinus_IN = t2.timeDiffMinus_IN
	,t1.nalogDelayPassiveFR_IN = t2.nalogDelayPassiveFR_IN
	,t1.nalogDelayPassiveKap_IN = t2.nalogDelayPassiveKap_IN
	,t1.nalogDelayActiveFR_IN = t2.nalogDelayActiveFR_IN
	,t1.nalogDelayActiveKap_IN = t2.nalogDelayActiveKap_IN
	,t1.nalogDelaySPOD_IN = t2.nalogDelaySPOD_IN

	,t1.timeDiffNalog_OUT = t2.timeDiffNalog_OUT
	,t1.timeDiffMinus_OUT = t2.timeDiffMinus_OUT
	,t1.nalogDelayPassiveFR_OUT = t2.nalogDelayPassiveFR_OUT
	,t1.nalogDelayPassiveKap_OUT = t2.nalogDelayPassiveKap_OUT
	,t1.nalogDelayActiveFR_OUT = t2.nalogDelayActiveFR_OUT
	,t1.nalogDelayActiveKap_OUT = t2.nalogDelayActiveKap_OUT
	,t1.nalogDelaySPOD_OUT = t2.nalogDelaySPOD_OUT;

merge into #rep t1
using(
select
timeDiffNalog_IN = sum(timeDiffNalog_IN)
,timeDiffMinus_IN = sum(timeDiffMinus_IN)
,nalogDelayPassiveFR_IN = sum(nalogDelayPassiveFR_IN)
,nalogDelayPassiveKap_IN = sum(nalogDelayPassiveKap_IN)
,nalogDelayActiveFR_IN = sum(nalogDelayActiveFR_IN)
,nalogDelayActiveKap_IN = sum(nalogDelayActiveKap_IN)
,nalogDelaySPOD_IN = sum(nalogDelaySPOD_IN)

,timeDiffNalog_OUT = sum(timeDiffNalog_OUT)
,timeDiffMinus_OUT = sum(timeDiffMinus_OUT)
,nalogDelayPassiveFR_OUT = sum(nalogDelayPassiveFR_OUT)
,nalogDelayPassiveKap_OUT = sum(nalogDelayPassiveKap_OUT)
,nalogDelayActiveFR_OUT = sum(nalogDelayActiveFR_OUT)
,nalogDelayActiveKap_OUT = sum(nalogDelayActiveKap_OUT)
,nalogDelaySPOD_OUT = sum(nalogDelaySPOD_OUT)

from #rep
where rowNum in (12,13,14,15)
) t2 on (t1.rowNum=16)
when matched then update
set 
	t1.timeDiffNalog_IN = t2.timeDiffNalog_IN
	,t1.timeDiffMinus_IN = t2.timeDiffMinus_IN
	,t1.nalogDelayPassiveFR_IN = t2.nalogDelayPassiveFR_IN
	,t1.nalogDelayPassiveKap_IN = t2.nalogDelayPassiveKap_IN
	,t1.nalogDelayActiveFR_IN = t2.nalogDelayActiveFR_IN
	,t1.nalogDelayActiveKap_IN = t2.nalogDelayActiveKap_IN
	,t1.nalogDelaySPOD_IN = t2.nalogDelaySPOD_IN

	,t1.timeDiffNalog_OUT = t2.timeDiffNalog_OUT
	,t1.timeDiffMinus_OUT = t2.timeDiffMinus_OUT
	,t1.nalogDelayPassiveFR_OUT = t2.nalogDelayPassiveFR_OUT
	,t1.nalogDelayPassiveKap_OUT = t2.nalogDelayPassiveKap_OUT
	,t1.nalogDelayActiveFR_OUT = t2.nalogDelayActiveFR_OUT
	,t1.nalogDelayActiveKap_OUT = t2.nalogDelayActiveKap_OUT
	,t1.nalogDelaySPOD_OUT = t2.nalogDelaySPOD_OUT;

merge into #rep t1
using(
select
timeDiffNalog_IN = sum(timeDiffNalog_IN)
,timeDiffMinus_IN = sum(timeDiffMinus_IN)
,nalogDelayPassiveFR_IN = sum(nalogDelayPassiveFR_IN)
,nalogDelayPassiveKap_IN = sum(nalogDelayPassiveKap_IN)
,nalogDelayActiveFR_IN = sum(nalogDelayActiveFR_IN)
,nalogDelayActiveKap_IN = sum(nalogDelayActiveKap_IN)
,nalogDelaySPOD_IN = sum(nalogDelaySPOD_IN)

,timeDiffNalog_OUT = sum(timeDiffNalog_OUT)
,timeDiffMinus_OUT = sum(timeDiffMinus_OUT)
,nalogDelayPassiveFR_OUT = sum(nalogDelayPassiveFR_OUT)
,nalogDelayPassiveKap_OUT = sum(nalogDelayPassiveKap_OUT)
,nalogDelayActiveFR_OUT = sum(nalogDelayActiveFR_OUT)
,nalogDelayActiveKap_OUT = sum(nalogDelayActiveKap_OUT)
,nalogDelaySPOD_OUT = sum(nalogDelaySPOD_OUT)

from #rep
where rowNum in (8,11,16)
) t2 on (t1.rowNum=17)
when matched then update
set 
	t1.timeDiffNalog_IN = t2.timeDiffNalog_IN
	,t1.timeDiffMinus_IN = t2.timeDiffMinus_IN
	,t1.nalogDelayPassiveFR_IN = t2.nalogDelayPassiveFR_IN
	,t1.nalogDelayPassiveKap_IN = t2.nalogDelayPassiveKap_IN
	,t1.nalogDelayActiveFR_IN = t2.nalogDelayActiveFR_IN
	,t1.nalogDelayActiveKap_IN = t2.nalogDelayActiveKap_IN
	,t1.nalogDelaySPOD_IN = t2.nalogDelaySPOD_IN

	,t1.timeDiffNalog_OUT = t2.timeDiffNalog_OUT
	,t1.timeDiffMinus_OUT = t2.timeDiffMinus_OUT
	,t1.nalogDelayPassiveFR_OUT = t2.nalogDelayPassiveFR_OUT
	,t1.nalogDelayPassiveKap_OUT = t2.nalogDelayPassiveKap_OUT
	,t1.nalogDelayActiveFR_OUT = t2.nalogDelayActiveFR_OUT
	,t1.nalogDelayActiveKap_OUT = t2.nalogDelayActiveKap_OUT
	,t1.nalogDelaySPOD_OUT = t2.nalogDelaySPOD_OUT;


merge into #rep t1
using(
select
amountPassiveIn =nalogDelayPassiveFR_IN -nalogDelayActiveFR_IN
,amountPassiveOUT =nalogDelayPassiveFR_OUT -nalogDelayActiveFR_OUT

,amountActiveIn =nalogDelayPassiveKap_IN -nalogDelayActiveKap_IN
,amountActiveOUT =nalogDelayPassiveKap_OUT -nalogDelayActiveKap_OUT
from #rep
where rowNum in (17)
) t2 on (t1.rowNum=18)
when matched then update
set 
	t1.nalogDelayPassiveFR_IN = t2.amountPassiveIn
	,t1.nalogDelayPassiveFR_OUT = t2.amountPassiveOUT
	,t1.nalogDelayActiveFR_IN = t2.amountActiveIn
	,t1.nalogDelayActiveFR_OUT = t2.amountActiveOUT;

merge into #rep t1
using(
select
amountPassiveIn =nalogDelayPassiveFR_IN -nalogDelaySPOD_IN
,amountPassiveOUT =nalogDelayPassiveFR_OUT -nalogDelaySPOD_OUT

,amountActiveIn =nalogDelayPassiveKap_IN -nalogDelayActiveKap_IN
,amountActiveOUT =nalogDelayPassiveKap_OUT -nalogDelayActiveKap_OUT
from #rep
where rowNum in (18)
) t2 on (t1.rowNum=19)
when matched then update
set 
	t1.nalogDelayPassiveFR_IN = t2.amountPassiveIn
	,t1.nalogDelayPassiveFR_OUT = t2.amountPassiveOUT
	,t1.nalogDelayActiveFR_IN = t2.amountActiveIn
	,t1.nalogDelayActiveFR_OUT = t2.amountActiveOUT;


delete from dwh2.finAnalytics.repPL_ONOONA where repmonth = @repmonth
insert into dwh2.finAnalytics.repPL_ONOONA 
select 
@repmonth
,rowNum	
,nalogObject	
,balAccNum	
,valCode	
,restActive_IN	
,restPassive_IN	
,nalogBase_IN	
,timeDiffNalog_IN	
,timeDiffMinus_IN	
,nalogDelayPassiveFR_IN	
,nalogDelayPassiveKap_IN	
,nalogDelayActiveFR_IN	
,nalogDelayActiveKap_IN	
,nalogDelaySPOD_IN	
,restActive_OUT	
,restPassive_OUT	
,nalogBase_OUT	
,timeDiffNalog_OUT	
,timeDiffMinus_OUT	
,nalogDelayPassiveFR_OUT	
,nalogDelayPassiveKap_OUT	
,nalogDelayActiveFR_OUT	
,nalogDelayActiveKap_OUT	
,nalogDelaySPOD_OUT
,getdate()
from #rep

	
	commit tran
    
	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

	end try
    
    begin catch

    
	DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для отчета PL для публикуемой  '
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
