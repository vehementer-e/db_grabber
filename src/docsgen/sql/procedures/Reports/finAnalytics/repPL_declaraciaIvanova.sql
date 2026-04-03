



CREATE PROCEDURE [finAnalytics].[repPL_declaraciaIvanova]
	@repYear date,
	@selector int

AS
BEGIN

	declare @repMonthTo date = (select max(repmonth) 
								from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
								where year(repmonth) = year(@repYear))

    /*Свод Таблица 2*/

drop table if exists #tab2
Create table #tab2(
	[Repmonth] date not null,
	[rowNum] int not null,
	[pokazatel] nvarchar(300) null,
	[amountBU] float null,
	[amountNU] float null
)

insert into #tab2
select
[Repmonth] = @repMonthTo
,[rowNum] = 1
,[pokazatel] = 'ДОХОДЫ ОТ РЕАЛИЗАЦИИ'
,[amountBU] = (select amountBU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =1 and rowNum = 2000)
,[amountNU] = (select amountNU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =1 and rowNum = 2000)

insert into #tab2
select
[Repmonth] = @repMonthTo
,[rowNum] = 2
,[pokazatel] = 'ДОХОДЫ ВНЕРЕАЛИЗАЦИОННЫЕ'
,[amountBU] = (select amountBU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =2 and rowNum = 5200)
,[amountNU] = (select amountNU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =2 and rowNum = 5200)

insert into #tab2
select
[Repmonth] = @repMonthTo
,[rowNum] = 3
,[pokazatel] = 'не вкл. в НОБ'
,[amountBU] = (select amountBU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =5 and rowNum = 500)
,[amountNU] = 0

insert into #tab2
select
[Repmonth] = @repMonthTo
,rowNum = 4
,pokazatel = 'ИТОГО ДОХОДЫ'	
,amountBU = sum(amountBU)
,amountNU = sum(amountNU)
from #tab2
where rowNum in (1,2,3)

insert into #tab2
select
[Repmonth] = @repMonthTo
,rowNum = 5
,pokazatel = ''	
,amountBU = null
,amountNU = null

insert into #tab2
select
[Repmonth] = @repMonthTo
,[rowNum] = 6
,[pokazatel] = 'РАСХОДЫ ОТ РЕАЛИЗАЦИИ'
,[amountBU] = (select amountBU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =3 and rowNum = 14800)
,[amountNU] = (select amountNU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =3 and rowNum = 14800)

insert into #tab2
select
[Repmonth] = @repMonthTo
,[rowNum] = 7
,[pokazatel] = 'РАСХОДЫ ВНЕРЕАЛИЗАЦИОННЫЕ'
,[amountBU] = (select amountBU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =4 and rowNum = 4100)
,[amountNU] = (select amountNU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =4 and rowNum = 4100)

insert into #tab2
select
[Repmonth] = @repMonthTo
,[rowNum] = 8
,[pokazatel] = 'не вкл. в НОБ'
,[amountBU] = (select amountBU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =6 and rowNum = 2500)
,[amountNU] = 0

insert into #tab2
select
[Repmonth] = @repMonthTo
,rowNum = 9
,pokazatel = 'ИТОГО РАСХОДЫ'	
,amountBU = sum(amountBU)
,amountNU = sum(amountNU)
from #tab2
where rowNum in (6,7,8)

insert into #tab2
select
[Repmonth] = @repMonthTo
,rowNum = 10
,pokazatel = ''	
,amountBU = null
,amountNU = null

insert into #tab2
select
[Repmonth] = @repMonthTo
,rowNum = 11
,pokazatel = 'Фин.результат'	
,amountBU = sum(case when rowNum = 9 then amountBU *-1 else amountBU end)
,amountNU = sum(case when rowNum = 9 then amountNU *-1 else amountNU end)
from #tab2
where rowNum in (4,9)

insert into #tab2
select
[Repmonth] = @repMonthTo
,rowNum = 12
,pokazatel = 'убытки прощлых лет'	
,amountBU = null
,amountNU = null

insert into #tab2
select
[Repmonth] = @repMonthTo
,rowNum = 13
,pokazatel = 'база для расчета НП'	
,amountBU = null
,amountNU = sum(case when rowNum = 12 then amountNU *-1 else amountNU end)
from #tab2
where rowNum in (11,12)

insert into #tab2
select
[Repmonth] = @repMonthTo
,rowNum = 14
,pokazatel = 'к уплате'	
,amountBU = null
,amountNU = amountNU * b.stavka
from #tab2 a
left join dwh2.[finAnalytics].[SPR_repPL_NP] b on @repMonthTo between b.dateFrom and b.dateTo
where rowNum in (13)

insert into #tab2
select
[Repmonth] = @repMonthTo
,rowNum = 15
,pokazatel = 'Сверка фин.результата с ф.843'	
,amountBU = case when a.amountBU - b.sumAmount > 1000 then a.amountBU - b.sumAmount else 0 end
,amount843 = null
from #tab2 a
left join [dwh2].[finAnalytics].[repPLf843] b on @repMonthTo = b.repmonth and b.rowname='18'
where a.rowNum in (11)



/*Свод Таблица 3*/

drop table if exists #tab3
Create table #tab3(
	[Repmonth] date not null,
	[rowNum] int not null,
	[pokazatel] nvarchar(300) null,
	[amountBU] float null,
	[amountNU] float null
)

insert into #tab3
select
[Repmonth] = @repMonthTo
,[rowNum] = 1
,[pokazatel] = 'ДОХОДЫ ОТ РЕАЛИЗАЦИИ'
,[amountBU] = (select amountBU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =1 and rowNum = 2000)
			-
			  (select sumAmount = sum(sumAmount) from [dwh2].[finAnalytics].[repPLDeclaraciaMonthly]
				where repmonth between datefromParts(year(@repMonthTo),1,1) and @repMonthTo
				and rowName = '1')
,[amountNU] = (select amountNU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =1 and rowNum = 2000)
			-
			  (select sumAmount = sum(sumAmount) from [dwh2].[finAnalytics].[repPLDeclaraciaMonthly]
				where repmonth between datefromParts(year(@repMonthTo),1,1) and @repMonthTo
				and rowName = '40')

insert into #tab3
select
[Repmonth] = @repMonthTo
,[rowNum] = 2
,[pokazatel] = 'ДОХОДЫ ВНЕРЕАЛИЗАЦИОННЫЕ'
,[amountBU] = (select amountBU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =2 and rowNum = 5200)
			-
			  (select sumAmount = sum(sumAmount) from [dwh2].[finAnalytics].[repPLDeclaraciaMonthly]
				where repmonth between datefromParts(year(@repMonthTo),1,1) and @repMonthTo
				and rowName = '2')
,[amountNU] = (select amountNU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =2 and rowNum = 5200)
			-
			  (select sumAmount = sum(sumAmount) from [dwh2].[finAnalytics].[repPLDeclaraciaMonthly]
				where repmonth between datefromParts(year(@repMonthTo),1,1) and @repMonthTo
				and rowName = '41')

insert into #tab3
select
[Repmonth] = @repMonthTo
,[rowNum] = 3
,[pokazatel] = 'не вкл. в НОБ'
,[amountBU] = (select amountBU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =5 and rowNum = 500)
			-
			  (select sumAmount = sum(sumAmount) from [dwh2].[finAnalytics].[repPLDeclaraciaMonthly]
				where repmonth between datefromParts(year(@repMonthTo),1,1) and @repMonthTo
				and rowName = '3')
,[amountNU] = null

insert into #tab3
select
[Repmonth] = @repMonthTo
,rowNum = 4
,pokazatel = ''	
,amountBU = null
,amountNU = null

insert into #tab3
select
[Repmonth] = @repMonthTo
,[rowNum] = 5
,[pokazatel] = 'РАСХОДЫ ОТ РЕАЛИЗАЦИИ'
,[amountBU] = (select round(amountBU,0) from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =3 and rowNum = 14800)
			+
			  (select sumAmount = round(sum(sumAmount),0) from [dwh2].[finAnalytics].[repPLDeclaraciaMonthly]
				where repmonth between datefromParts(year(@repMonthTo),1,1) and @repMonthTo
				and rowName = '6')
,[amountNU] = (select round(amountNU,0) from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =3 and rowNum = 14800)
			+
			  (select sumAmount = round(sum(sumAmount),0) from [dwh2].[finAnalytics].[repPLDeclaraciaMonthly]
				where repmonth between datefromParts(year(@repMonthTo),1,1) and @repMonthTo
				and rowName = '45')

insert into #tab3
select
[Repmonth] = @repMonthTo
,[rowNum] = 6
,[pokazatel] = 'РАСХОДЫ ВНЕРЕАЛИЗАЦИОННЫЕ'
,[amountBU] = (select amountBU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =4 and rowNum = 4100)
			+
			  (select sumAmount = sum(sumAmount) from [dwh2].[finAnalytics].[repPLDeclaraciaMonthly]
				where repmonth between datefromParts(year(@repMonthTo),1,1) and @repMonthTo
				and rowName = '7')
,[amountNU] = (select amountNU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =4 and rowNum = 4100)
			+
			  (select sumAmount = sum(sumAmount) from [dwh2].[finAnalytics].[repPLDeclaraciaMonthly]
				where repmonth between datefromParts(year(@repMonthTo),1,1) and @repMonthTo
				and rowName = '46')

insert into #tab3
select
[Repmonth] = @repMonthTo
,[rowNum] = 7
,[pokazatel] = 'не вкл. в НОБ'
,[amountBU] = (select amountBU from dwh2.[finAnalytics].[repPLDeclaraciaIvanova]
				where repmonth = @repMonthTo and partNum =6 and rowNum = 2500)
			+
			  (select sumAmount = sum(sumAmount) from [dwh2].[finAnalytics].[repPLDeclaraciaMonthly]
				where repmonth between datefromParts(year(@repMonthTo),1,1) and @repMonthTo
				and rowName = '8')
,[amountNU] = 0

insert into #tab3
select
[Repmonth] = @repMonthTo
,rowNum = 8
,pokazatel = ''	
,amountBU = null
,amountNU = null

insert into #tab3
select
[Repmonth] = @repMonthTo
,rowNum = 9
,pokazatel = 'Фин.результат'	
,amountBU = amountBU
		-
			  (select sumAmount = sum(sumAmount) from [dwh2].[finAnalytics].[repPLDeclaraciaMonthly]
				where repmonth between datefromParts(year(@repMonthTo),1,1) and @repMonthTo
				and rowName = '11')
,amountNU = amountNU
		-
			  (select sumAmount = sum(sumAmount) from [dwh2].[finAnalytics].[repPLDeclaraciaMonthly]
				where repmonth between datefromParts(year(@repMonthTo),1,1) and @repMonthTo
				and rowName = '50')
from #tab2
where rowNum = 11

insert into #tab3
select
[Repmonth] = @repMonthTo
,rowNum = 10
,pokazatel = 'убытки прощлых лет'	
,amountBU = null
,amountNU = null


insert into #tab3
select
[Repmonth] = @repMonthTo
,rowNum = 11
,pokazatel = 'база для расчета НП'	
,amountBU = null
,amountNU = amountNU 
		-
			  (select sumAmount = sum(sumAmount) from [dwh2].[finAnalytics].[repPLDeclaraciaMonthly]
				where repmonth between datefromParts(year(@repMonthTo),1,1) and @repMonthTo
				and rowName = '52')
		
from #tab2
where rowNum in (13)

insert into #tab3
select
[Repmonth] = @repMonthTo
,rowNum = 12
,pokazatel = 'к уплате'	
,amountBU = null
,amountNU = amountNU
		-
			  (select sumAmount = sum(sumAmount) from [dwh2].[finAnalytics].[repPLDeclaraciaMonthly]
				where repmonth between datefromParts(year(@repMonthTo),1,1) and @repMonthTo
				and rowName = '53')
from #tab2 a
where rowNum in (14)



 /*Свод Таблица 1*/

drop table if exists #tab1
Create table #tab1(
	[Repmonth] date not null,
	[rowNum] int not null,
	[pokazatel] nvarchar(300) null,
	[saldoKT] float null,
	[saldoDT] float null,
	[finrez] float null
)

insert into #tab1
select
 [repmonth] = @repMonthTo
 ,[rowNum] = 1
 ,[pokazatel] = 'Сальдо счетов доходов/расходов'
 ,[saldoKT] = abs(sum(case when isnull(restOUT_BU,0) <0 then isnull(restOUT_BU,0) else 0 end))
 ,[saldoDT] = abs(sum(case when isnull(restOUT_BU,0) >0 then isnull(restOUT_BU,0) else 0 end))
 ,[finrez] = abs(sum(case when isnull(restOUT_BU,0) <0 then isnull(restOUT_BU,0) else 0 end))
			-
			abs(sum(case when isnull(restOUT_BU,0) >0 then isnull(restOUT_BU,0) else 0 end))
 from dwh2.[finAnalytics].[SPR_PL_ACC] a
 left join dwh2.finAnalytics.repPLAccRests b on a.ID=b.accUID and b.repmonth = @repMonthTo
 where a.acc1order in ('710','711','712','713','714','715','716','717','718')

insert into #tab1
select
 [repmonth] = @repMonthTo
 ,[rowNum] = 2
 ,[pokazatel] = 'ДР/РР'
 ,[saldoKT] = (select isnull(amountBU,0) from #tab2 where rowNum = 1)
 ,[saldoDT] = (select isnull(amountBU,0) from #tab2 where rowNum = 6)
 ,[finrez] = (select isnull(amountBU,0) from #tab2 where rowNum = 1)
			-
			(select isnull(amountBU,0) from #tab2 where rowNum = 6)

insert into #tab1
select
 [repmonth] = @repMonthTo
 ,[rowNum] = 3
 ,[pokazatel] = 'ДВ/РВ'
 ,[saldoKT] = (select isnull(amountBU,0) from #tab2 where rowNum = 2)
 ,[saldoDT] = (select isnull(amountBU,0) from #tab2 where rowNum = 7)
 ,[finrez] = (select isnull(amountBU,0) from #tab2 where rowNum = 2)
			-
			(select isnull(amountBU,0) from #tab2 where rowNum = 7)

insert into #tab1
select
 [repmonth] = @repMonthTo
 ,[rowNum] = 4
 ,[pokazatel] = 'не НУ'
 ,[saldoKT] = (select isnull(amountBU,0) from #tab2 where rowNum = 3)
 ,[saldoDT] = (select isnull(amountBU,0) from #tab2 where rowNum = 8)
 ,[finrez] = (select isnull(amountBU,0) from #tab2 where rowNum = 3)
			-
			(select isnull(amountBU,0) from #tab2 where rowNum = 8)

insert into #tab1
select
 [repmonth] = @repMonthTo
 ,[rowNum] = 5
 ,[pokazatel] = 'ИТОГО'
 ,[saldoKT] = (select sum(isnull(saldoKT,0)) from #tab1 where rowNum in (2,3,4))
 ,[saldoDT] = (select sum(isnull(saldoDT,0)) from #tab1 where rowNum in (2,3,4))
 ,[finrez] = (select sum(isnull(saldoKT,0)) from #tab1 where rowNum in (2,3,4))
			-
			(select sum(isnull(saldoDT,0)) from #tab1 where rowNum in (2,3,4))

insert into #tab1
select
 [repmonth] = @repMonthTo
 ,[rowNum] = 6
 ,[pokazatel] = 'Контроль'
 ,[saldoKT] = (select isnull(saldoKT,0) from #tab1 where rowNum = 1)
			-
			  (select isnull(saldoKT,0) from #tab1 where rowNum = 5)
 ,[saldoDT] = (select isnull(saldoDT,0) from #tab1 where rowNum = 1)
			-
			  (select isnull(saldoDT,0) from #tab1 where rowNum = 5)
 ,[finrez] = (select isnull(finrez,0) from #tab1 where rowNum = 1)
			-
			  (select isnull(finrez,0) from #tab1 where rowNum = 5)
  
  if @selector = 1
  begin
  --
  select 
  Repmonth	
  ,rowNum	
  ,pokazatel	
  ,saldoKT = round(saldoKT,0)
  ,saldoDT = round(saldoDT,0)	
  ,finrez = round(finrez,0)
  from #tab1
  end

  if @selector = 2
  begin
  --
  select 
Repmonth	
,rowNum	
,pokazatel	
,amountBU = round(amountBU,0)
,amountNU = round(amountNU,0)

from #tab2
end

if @selector = 3
  begin
--
select 
Repmonth	
,rowNum	
,pokazatel	
,amountBU = round(amountBU,0)
,amountNU = round(amountNU,0)
 from #tab3
 end

END
