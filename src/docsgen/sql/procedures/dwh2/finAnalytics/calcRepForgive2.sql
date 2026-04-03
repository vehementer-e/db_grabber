


CREATE PROCEDURE [finAnalytics].[calcRepForgive2]
	@repmonth date

AS
BEGIN

DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

DROP TABLE IF EXISTS #rep3

select
repMonth	
, l1.[Займ]	
, l1.[Заемщик]
, l1.[Паспорт серия]
, l1.[Паспорт номер]
, l1.[Паспорт дата выдачи]
, l1.[Паспорт кем выдан]
, l1.[Паспорт код подразделения]
, l1.[Адрес регистрации]
, l1.[Ссылка]
, l1.[Ссылка.Причина]
, l1.[Счет аналитического учета списания основного долга]
, l1.[Счет аналитического учета списания процентов]
, l1.[Счет учета расчетов с прочими дебиторами]
, l1.[Сумма начальный остаток]
, l1.[Проценты (Дт. 71001 - Кт. 48802)]
, l1.[Пени (Дт. 71701 - Кт. 60323)]
, l1.[Сумма задолженности]
, l1.[Основной долг (Дт. 71802 - Кт. 48801)]
, l1.[Проценты (Дт. 71802 - Кт. 48802)]
, l1.[Пени (Дт. 71802 - Кт. 60323)]
, l1.[Пени (по суду)]
, l1.[Штрафы]
, l1.[Сумма задолженности (штрафы, пени,прочие доходы)]
, l1.[Штрафы (по суду)]
, l1.[Прочие доходы]
, l1.[Прочие доходы (по суду)]
, l1.[Комиссии]
, l1.[Сумма погашено ОД]
, l1.[Сумма погашено проценты]
, l1.[Сумма погашено пени]
, l1.[Сумма погашено госпошлина]
, l1.[Сумма оборот платежи]
, l1.[Сумма восстанволено резервов]
, l1.[Сумма восстанволено резервов НУ]
, l1.[Номенклатурная группа]
, l1.[Номер договора]

INTO #Rep3

from (
select
repMonth = @repmonth
--,[Номер договора] = substring(zaim,CHARINDEX('№ ',zaim)+2,CHARINDEX(' от ',zaim)-8)
,[Займ] =  a.zaim
,[Заемщик] = a.client
,[Паспорт серия] =  a.passSeria
,[Паспорт номер] = a.passNum
,[Паспорт дата выдачи] = a.passDate
,[Паспорт кем выдан] = a.passIssuer
,[Паспорт код подразделения] = a.passCode
,[Адрес регистрации] = a.addressReg
,[Ссылка] = a.spisanieText
,[Ссылка.Причина] = case 
						when upper(a.spisanieReason) = UPPER('Служебная записка') 
							and upper(a.spisanieText) like upper('%Списание (прощение) займов%') 
							then CONCAT(a.spisanieReason, ' («Прощаем займы»)') 
						when upper(a.spisanieReason) = UPPER('Признание задолженности безнадежной к взысканию (банкрот)') 	
							then 'Признание задолженности безнадежной к взысканию'
							else a.spisanieReason end
,[Счет аналитического учета списания основного долга] = a.accOD
,[Счет аналитического учета списания процентов] = a.accPRC
,[Счет учета расчетов с прочими дебиторами] = a.accOther
,[Сумма начальный остаток] = a.sumRestBegin
,[Проценты (Дт. 71001 - Кт. 48802)] = a.sumSpisPRC
,[Пени (Дт. 71701 - Кт. 60323)] = a.sumSpisPenia
,[Сумма задолженности] = a.sumFogive
,[Основной долг (Дт. 71802 - Кт. 48801)] = a.sumFogiveOD
,[Проценты (Дт. 71802 - Кт. 48802)] = a.sumFogivePRC
,[Пени (Дт. 71802 - Кт. 60323)] = a.sumFogivePenia
,[Пени (по суду)] = a.sumFogivePeniaSUD
,[Штрафы] = a.sumFogiveShtraf
,[Сумма задолженности (штрафы, пени,прочие доходы)] = a.sumFogiveZadolg
,[Штрафы (по суду)] = a.sumFogiveShtrafSUD
,[Прочие доходы] = a.sumFogiveOther
,[Прочие доходы (по суду)] = a.sumFogiveOtherSUD
,[Комиссии] =  a.sumFogiveComiss
,[Сумма погашено ОД] = a.sumPogashOD
,[Сумма погашено проценты] = a.sumPogashPRC
,[Сумма погашено пени] = a.sumPogashPenia
,[Сумма погашено госпошлина] = a.sumPogashGP
,[Сумма оборот платежи] = a.sumOborot
,[Сумма восстанволено резервов] = a.sumReservBackBU
,[Сумма восстанволено резервов НУ] = a.sumReservBackNU
,[Номенклатурная группа] = /*case when upper(b.nomenkGroup) like upper('%основной%')
							or  upper(b.nomenkGroup) like upper('%ПТС31%')
							or  upper(b.nomenkGroup) like upper('%Рефинансирование%') then 'ПТС'
								when upper(b.nomenkGroup) like upper('%installment%') then 'IL'
								when upper(b.nomenkGroup) like upper('%PDL%') then 'PDL'
								when upper(b.nomenkGroup) like upper('%бизнес%займ%') then 'БЗ'
							else '-' end*/
							--case when dwh2.[finAnalytics].[nomenk2prod](b.nomenkGroup) = 'ПТС' then 'ПТС'
							--	 when dwh2.[finAnalytics].[nomenk2prod](b.nomenkGroup) = 'Installment' then 'IL'
							--	 when dwh2.[finAnalytics].[nomenk2prod](b.nomenkGroup) = 'PDL' then 'PDL'
							--	 when dwh2.[finAnalytics].[nomenk2prod](b.nomenkGroup) = 'Бизнес-займ' then 'БЗ'
							--	 when dwh2.[finAnalytics].[nomenk2prod](b.nomenkGroup) = 'Автокредит' then 'Автокредит'
							--else '-' end

			case 
					when dwh2.[finAnalytics].[nomenk2prod](b.nomenkGroup) = 'Бизнес-займ' then 'БЗ'
					when dwh2.[finAnalytics].[nomenk2prod](b.nomenkGroup) = 'Installment' then 'IL'
					when dwh2.[finAnalytics].[nomenk2prod](b.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](b.nomenkGroup) end

,[Номер договора] = substring(a.zaim,CHARINDEX('№ ',a.zaim)+2,CHARINDEX(' от ',a.zaim)-8)
--, dataLoadDate
from finAnalytics.akcia_vzisk_MONTHLY a
left join finAnalytics.PBR_MONTHLY b on b.REPMONTH=@repmonth and b.dogNum=substring(a.zaim,CHARINDEX('№ ',a.zaim)+2,CHARINDEX(' от ',a.zaim)-8)

where a.repMonth = @repmonth
) l1



DROP TABLE IF EXISTS #spReason
CREATE TABLE #spReason(
reasonName varchar(500) not null,
rowNum int not null
)

insert into #spReason select 'Дисконтный калькулятор', 1
insert into #spReason select 'Оферта 20% + новый график', 2
insert into #spReason select 'Согласно Приказа №213 от 06.12.2018 "Об утверждении лимитов расходования средств, направленных на погашение задолженности ФЛ"', 3
insert into #spReason select 'Признание задолженности безнадежной к взысканию', 4
--insert into #spReason select 'Признание задолженности безнадежной к взысканию (банкрот)', 4
insert into #spReason select 'Списание договора по №377-ФЗ Статья 2 п.1', 5
insert into #spReason select 'Служебная записка (мошенник)', 6
insert into #spReason select 'Служебная записка («Прощаем займы»)', 7


delete from finAnalytics.repForgive2 where repmonth = @repmonth


--------------------'Все продукты'
insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
Select
repmonth = @repmonth
,spisReason = a.reasonName
,nomenkGR = 'Все продукты'
,sumSpisPRC = isnull(b.sumSpisPRC,0)
,sumSpisPenia = isnull(b.sumSpisPenia,0)
,sumFogiveOD = isnull(b.sumFogiveOD,0)
,sumFogivePRC = isnull(b.sumFogivePRC,0)
,sumFogivePenia = isnull(b.sumFogivePenia,0)
,sumItog = isnull(b.sumItog,0)
,dogCount = isnull(b.dogCount,0)
,rowNum = a.rowNum
,dogCountOD = isnull(b.dogCountOD,0)

from #spReason a
left join(
select
spisReason = a.[Ссылка.Причина]
,nomenkGR = 'Все продукты'
,sumSpisPRC = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
,sumSpisPenia = isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
,sumFogiveOD = isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
,sumFogivePRC = isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
,sumFogivePenia = isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, sumItog = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
		+   isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
		+   isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, dogCount = COUNT(Distinct 
						case when isnull(a.[Проценты (Дт. 71001 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71701 - Кт. 60323)],0)
								+   isnull(a.[Основной долг (Дт. 71802 - Кт. 48801)],0)
								+   isnull(a.[Проценты (Дт. 71802 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71802 - Кт. 60323)],0) !=0 then a.[Номер договора] end)
, [dogCountOD] = COUNT(Distinct 
						case when a.[Основной долг (Дт. 71802 - Кт. 48801)] !=0 then a.[Номер договора] end)
from #rep3 a
group by a.[Ссылка.Причина]
) b on a.reasonName=b.spisReason

insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'ИТОГО'
,nomenkGR = 'Все продукты'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 8
,[dogCountOD] = SUM([dogCountOD])
from finAnalytics.repForgive2 where repmonth = @repmonth


insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
,nomenkGR = 'Все продукты'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 9
,[dogCountOD] = SUM([dogCountOD])
from finAnalytics.repForgive2 where repmonth = @repmonth
and spisReason not in (
				'Служебная записка (мошенник)'
				,'Служебная записка («Прощаем займы»)'
				,'Признание задолженности безнадежной к взысканию'
				,'ИТОГО'
				)


insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'Не коллекшн'
,nomenkGR = 'Все продукты'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 10
,[dogCountOD] = SUM([dogCountOD])
from finAnalytics.repForgive2 where repmonth = @repmonth
and spisReason in (
				'Служебная записка (мошенник)'
				,'Служебная записка («Прощаем займы»)'
				)


insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'ИТОГО Сверка с отчетом по акциям'
,nomenkGR = 'Все продукты'
,sumSpisPRC = a.sumSpisPRC + b.sumSpisPRC * -1
,sumSpisPenia = a.sumSpisPenia + b.sumSpisPenia * -1
,sumFogiveOD = a.sumFogiveOD + b.sumFogiveOD * -1
,sumFogivePRC = a.sumFogivePRC + b.sumFogivePRC * -1
,sumFogivePenia = a.sumFogivePenia + b.sumFogivePenia *-1
,sumItog = a.sumItog + b.sumItog *-1
,dogCount = a.dogCount + b.dogCount *-1
,rowNum = 11
,[dogCountOD] = a.dogCountOD + b.dogCountOD *-1
from finAnalytics.repForgive2 a

left join(
select
sumSpisPRC = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
,sumSpisPenia = isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
,sumFogiveOD = isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
,sumFogivePRC = isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
,sumFogivePenia = isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, sumItog = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
		+   isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
		+   isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, dogCount = COUNT(Distinct 
						case when isnull(a.[Проценты (Дт. 71001 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71701 - Кт. 60323)],0)
								+   isnull(a.[Основной долг (Дт. 71802 - Кт. 48801)],0)
								+   isnull(a.[Проценты (Дт. 71802 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71802 - Кт. 60323)],0) !=0 then a.[Номер договора] end)
, dogCountOD = COUNT(Distinct 
						case when a.[Основной долг (Дт. 71802 - Кт. 48801)] !=0 then a.[Номер договора] end)
from #rep3 a
) b on 1=1
where repmonth = @repmonth
and spisReason='ИТОГО'


--------------------'ПТС'
insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
Select
repmonth = @repmonth
,spisReason = a.reasonName
,nomenkGR = 'ПТС'
,sumSpisPRC = isnull(b.sumSpisPRC,0)
,sumSpisPenia = isnull(b.sumSpisPenia,0)
,sumFogiveOD = isnull(b.sumFogiveOD,0)
,sumFogivePRC = isnull(b.sumFogivePRC,0)
,sumFogivePenia = isnull(b.sumFogivePenia,0)
,sumItog = isnull(b.sumItog,0)
,dogCount = isnull(b.dogCount,0)
,rowNum = a.rowNum
,[dogCountOD] = isnull(b.dogCountOD,0)
from #spReason a
left join(
select
spisReason = a.[Ссылка.Причина]
,nomenkGR = a.[Номенклатурная группа]
,sumSpisPRC = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
,sumSpisPenia = isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
,sumFogiveOD = isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
,sumFogivePRC = isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
,sumFogivePenia = isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, sumItog = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
		+   isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
		+   isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, dogCount = COUNT(Distinct 
						case when isnull(a.[Проценты (Дт. 71001 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71701 - Кт. 60323)],0)
								+   isnull(a.[Основной долг (Дт. 71802 - Кт. 48801)],0)
								+   isnull(a.[Проценты (Дт. 71802 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71802 - Кт. 60323)],0) !=0 then a.[Номер договора] end)
, dogCountOD = COUNT(Distinct 
						case when a.[Основной долг (Дт. 71802 - Кт. 48801)] !=0 then a.[Номер договора] end)
from #rep3 a
where a.[Номенклатурная группа] = 'ПТС'
group by a.[Ссылка.Причина],a.[Номенклатурная группа]
) b on a.reasonName=b.spisReason

--select * from #rep3 a

insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'ИТОГО'
,nomenkGR = 'ПТС'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 8
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and nomenkGR='ПТС'


insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
,nomenkGR = 'ПТС'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 9
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and spisReason not in (
				'Служебная записка (мошенник)'
				,'Служебная записка («Прощаем займы»)'
				,'Признание задолженности безнадежной к взысканию'
				,'ИТОГО'
				)
and nomenkGR='ПТС'


insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'Не коллекшн'
,nomenkGR = 'ПТС'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 10
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and spisReason in (
				'Служебная записка (мошенник)'
				,'Служебная записка («Прощаем займы»)'
				)
and nomenkGR = 'ПТС'

--------------------'Автокредит'
insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
Select
repmonth = @repmonth
,spisReason = a.reasonName
,nomenkGR = 'Автокредит'
,sumSpisPRC = isnull(b.sumSpisPRC,0)
,sumSpisPenia = isnull(b.sumSpisPenia,0)
,sumFogiveOD = isnull(b.sumFogiveOD,0)
,sumFogivePRC = isnull(b.sumFogivePRC,0)
,sumFogivePenia = isnull(b.sumFogivePenia,0)
,sumItog = isnull(b.sumItog,0)
,dogCount = isnull(b.dogCount,0)
,rowNum = a.rowNum
,dogCountOD = isnull(b.dogCountOD,0)
from #spReason a
left join(
select
spisReason = a.[Ссылка.Причина]
,nomenkGR = a.[Номенклатурная группа]
,sumSpisPRC = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
,sumSpisPenia = isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
,sumFogiveOD = isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
,sumFogivePRC = isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
,sumFogivePenia = isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, sumItog = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
		+   isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
		+   isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, dogCount = COUNT(Distinct 
						case when isnull(a.[Проценты (Дт. 71001 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71701 - Кт. 60323)],0)
								+   isnull(a.[Основной долг (Дт. 71802 - Кт. 48801)],0)
								+   isnull(a.[Проценты (Дт. 71802 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71802 - Кт. 60323)],0) !=0 then a.[Номер договора] end)
, dogCountOD = COUNT(Distinct 
						case when a.[Основной долг (Дт. 71802 - Кт. 48801)] !=0 then a.[Номер договора] end)
from #rep3 a
where a.[Номенклатурная группа] = 'Автокредит'
group by a.[Ссылка.Причина],a.[Номенклатурная группа]
) b on a.reasonName=b.spisReason

--select * from #rep3 a

insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'ИТОГО'
,nomenkGR = 'Автокредит'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 8
,dogCountOD = SUM(dogCountOd)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and nomenkGR='Автокредит'


insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
,nomenkGR = 'Автокредит'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 9
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and spisReason not in (
				'Служебная записка (мошенник)'
				,'Служебная записка («Прощаем займы»)'
				,'Признание задолженности безнадежной к взысканию'
				,'ИТОГО'
				)
and nomenkGR='Автокредит'


insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'Не коллекшн'
,nomenkGR = 'Автокредит'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 10
,dogCountOD = SUM(dogCountOd)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and spisReason in (
				'Служебная записка (мошенник)'
				,'Служебная записка («Прощаем займы»)'
				)
and nomenkGR = 'Автокредит'


--------------------'IL'
insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
Select
repmonth = @repmonth
,spisReason = a.reasonName
,nomenkGR = 'IL'
,sumSpisPRC = isnull(b.sumSpisPRC,0)
,sumSpisPenia = isnull(b.sumSpisPenia,0)
,sumFogiveOD = isnull(b.sumFogiveOD,0)
,sumFogivePRC = isnull(b.sumFogivePRC,0)
,sumFogivePenia = isnull(b.sumFogivePenia,0)
,sumItog = isnull(b.sumItog,0)
,dogCount = isnull(b.dogCount,0)
,rowNum = a.rowNum
,dogCountOD = isnull(b.dogCountOD,0)
from #spReason a
left join(
select
spisReason = a.[Ссылка.Причина]
,nomenkGR = a.[Номенклатурная группа]
,sumSpisPRC = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
,sumSpisPenia = isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
,sumFogiveOD = isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
,sumFogivePRC = isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
,sumFogivePenia = isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, sumItog = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
		+   isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
		+   isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, dogCount = COUNT(Distinct 
						case when isnull(a.[Проценты (Дт. 71001 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71701 - Кт. 60323)],0)
								+   isnull(a.[Основной долг (Дт. 71802 - Кт. 48801)],0)
								+   isnull(a.[Проценты (Дт. 71802 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71802 - Кт. 60323)],0) !=0 then a.[Номер договора] end)
, dogCountOD = COUNT(Distinct 
						case when a.[Основной долг (Дт. 71802 - Кт. 48801)] !=0 then a.[Номер договора] end)
from #rep3 a
where a.[Номенклатурная группа] = 'IL'
group by a.[Ссылка.Причина],a.[Номенклатурная группа]
) b on a.reasonName=b.spisReason

--select * from #rep3 a

insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'ИТОГО'
,nomenkGR = 'IL'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 8
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and nomenkGR='IL'


insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
,nomenkGR = 'IL'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 9
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and spisReason not in (
				'Служебная записка (мошенник)'
				,'Служебная записка («Прощаем займы»)'
				,'Признание задолженности безнадежной к взысканию'
				,'ИТОГО'
				)
and nomenkGR='IL'


insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'Не коллекшн'
,nomenkGR = 'IL'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 10
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and spisReason in (
				'Служебная записка (мошенник)'
				,'Служебная записка («Прощаем займы»)'
				)
and nomenkGR = 'IL'


--------------------'Big Installment'
insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
Select
repmonth = @repmonth
,spisReason = a.reasonName
,nomenkGR = 'Big Installment'
,sumSpisPRC = isnull(b.sumSpisPRC,0)
,sumSpisPenia = isnull(b.sumSpisPenia,0)
,sumFogiveOD = isnull(b.sumFogiveOD,0)
,sumFogivePRC = isnull(b.sumFogivePRC,0)
,sumFogivePenia = isnull(b.sumFogivePenia,0)
,sumItog = isnull(b.sumItog,0)
,dogCount = isnull(b.dogCount,0)
,rowNum = a.rowNum
,dogCountOD = isnull(b.dogCountOD,0)
from #spReason a
left join(
select
spisReason = a.[Ссылка.Причина]
,nomenkGR = a.[Номенклатурная группа]
,sumSpisPRC = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
,sumSpisPenia = isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
,sumFogiveOD = isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
,sumFogivePRC = isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
,sumFogivePenia = isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, sumItog = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
		+   isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
		+   isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, dogCount = COUNT(Distinct 
						case when isnull(a.[Проценты (Дт. 71001 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71701 - Кт. 60323)],0)
								+   isnull(a.[Основной долг (Дт. 71802 - Кт. 48801)],0)
								+   isnull(a.[Проценты (Дт. 71802 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71802 - Кт. 60323)],0) !=0 then a.[Номер договора] end)
, dogCountOD = COUNT(Distinct 
						case when a.[Основной долг (Дт. 71802 - Кт. 48801)] !=0 then a.[Номер договора] end)
from #rep3 a
where a.[Номенклатурная группа] = 'Big Installment'
group by a.[Ссылка.Причина],a.[Номенклатурная группа]
) b on a.reasonName=b.spisReason

--select * from #rep3 a

insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'ИТОГО'
,nomenkGR = 'Big Installment'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 8
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and nomenkGR='Big Installment'


insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
,nomenkGR = 'Big Installment'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 9
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and spisReason not in (
				'Служебная записка (мошенник)'
				,'Служебная записка («Прощаем займы»)'
				,'Признание задолженности безнадежной к взысканию'
				,'ИТОГО'
				)
and nomenkGR='Big Installment'


insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'Не коллекшн'
,nomenkGR = 'Big Installment'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 10
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and spisReason in (
				'Служебная записка (мошенник)'
				,'Служебная записка («Прощаем займы»)'
				)
and nomenkGR = 'Big Installment'


--------------------'PDL'
insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
Select
repmonth = @repmonth
,spisReason = a.reasonName
,nomenkGR = 'PDL'
,sumSpisPRC = isnull(b.sumSpisPRC,0)
,sumSpisPenia = isnull(b.sumSpisPenia,0)
,sumFogiveOD = isnull(b.sumFogiveOD,0)
,sumFogivePRC = isnull(b.sumFogivePRC,0)
,sumFogivePenia = isnull(b.sumFogivePenia,0)
,sumItog = isnull(b.sumItog,0)
,dogCount = isnull(b.dogCount,0)
,rowNum = a.rowNum
,dogCountOD = isnull(b.dogCountOD,0)
from #spReason a
left join(
select
spisReason = a.[Ссылка.Причина]
,nomenkGR = a.[Номенклатурная группа]
,sumSpisPRC = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
,sumSpisPenia = isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
,sumFogiveOD = isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
,sumFogivePRC = isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
,sumFogivePenia = isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, sumItog = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
		+   isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
		+   isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, dogCount = COUNT(Distinct 
						case when isnull(a.[Проценты (Дт. 71001 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71701 - Кт. 60323)],0)
								+   isnull(a.[Основной долг (Дт. 71802 - Кт. 48801)],0)
								+   isnull(a.[Проценты (Дт. 71802 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71802 - Кт. 60323)],0) !=0 then a.[Номер договора] end)
, dogCountOD = COUNT(Distinct 
						case when a.[Основной долг (Дт. 71802 - Кт. 48801)] !=0 then a.[Номер договора] end)
from #rep3 a
where a.[Номенклатурная группа] = 'PDL'
group by a.[Ссылка.Причина],a.[Номенклатурная группа]
) b on a.reasonName=b.spisReason

--select * from #rep3 a

insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'ИТОГО'
,nomenkGR = 'PDL'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 8
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and nomenkGR='PDL'


insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
,nomenkGR = 'PDL'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 9
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and spisReason not in (
				'Служебная записка (мошенник)'
				,'Служебная записка («Прощаем займы»)'
				,'Признание задолженности безнадежной к взысканию'
				,'ИТОГО'
				)
and nomenkGR='PDL'


insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'Не коллекшн'
,nomenkGR = 'PDL'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 10
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and spisReason in (
				'Служебная записка (мошенник)'
				,'Служебная записка («Прощаем займы»)'
				)
and nomenkGR = 'PDL'


--------------------'БЗ'
insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])

Select
repmonth = @repmonth
,spisReason = a.reasonName
,nomenkGR = 'БЗ'
,sumSpisPRC = isnull(b.sumSpisPRC,0)
,sumSpisPenia = isnull(b.sumSpisPenia,0)
,sumFogiveOD = isnull(b.sumFogiveOD,0)
,sumFogivePRC = isnull(b.sumFogivePRC,0)
,sumFogivePenia = isnull(b.sumFogivePenia,0)
,sumItog = isnull(b.sumItog,0)
,dogCount = isnull(b.dogCount,0)
,rowNum = a.rowNum
,dogCountOD = isnull(b.dogCountOD,0)
from #spReason a
left join(
select
spisReason = a.[Ссылка.Причина]
,nomenkGR = a.[Номенклатурная группа]
,sumSpisPRC = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
,sumSpisPenia = isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
,sumFogiveOD = isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
,sumFogivePRC = isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
,sumFogivePenia = isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, sumItog = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
		+   isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
		+   isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
, dogCount = COUNT(Distinct 
						case when isnull(a.[Проценты (Дт. 71001 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71701 - Кт. 60323)],0)
								+   isnull(a.[Основной долг (Дт. 71802 - Кт. 48801)],0)
								+   isnull(a.[Проценты (Дт. 71802 - Кт. 48802)],0)
								+   isnull(a.[Пени (Дт. 71802 - Кт. 60323)],0) !=0 then a.[Номер договора] end)
, dogCountOD = COUNT(Distinct 
						case when a.[Основной долг (Дт. 71802 - Кт. 48801)] !=0 then a.[Номер договора] end)
from #rep3 a
where a.[Номенклатурная группа] = 'БЗ'
group by a.[Ссылка.Причина],a.[Номенклатурная группа]
) b on a.reasonName=b.spisReason

--select * from #rep3 a

insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'ИТОГО'
,nomenkGR = 'БЗ'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 8
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and nomenkGR='БЗ'


insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'ИТОГО без Служебных записок и Задолженности, признанной безнадёжной'
,nomenkGR = 'БЗ'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 9
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and spisReason not in (
				'Служебная записка (мошенник)'
				,'Служебная записка («Прощаем займы»)'
				,'Признание задолженности безнадежной к взысканию'
				,'ИТОГО'
				)
and nomenkGR='БЗ'


insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select 
repmonth = @repmonth
,spisReason = 'Не коллекшн'
,nomenkGR = 'БЗ'
,sumSpisPRC = SUM(sumSpisPRC)
,sumSpisPenia = SUM(sumSpisPenia)
,sumFogiveOD = SUM(sumFogiveOD)
,sumFogivePRC = SUM(sumFogivePRC)
,sumFogivePenia = SUM(sumFogivePenia)
,sumItog = SUM(sumItog)
,dogCount = SUM(dogCount)
,rowNum = 10
,dogCountOD = SUM(dogCountOD)
from finAnalytics.repForgive2 
where repmonth = @repmonth
and spisReason in (
				'Служебная записка (мошенник)'
				,'Служебная записка («Прощаем займы»)'
				)
and nomenkGR = 'БЗ'

insert into finAnalytics.repForgive2
(repmonth, spisReason, nomenkGR, sumSpisPRC, sumSpisPenia, sumFogiveOD, sumFogivePRC, sumFogivePenia, sumItog, dogCount, rowNum, [dogCountOD])
select
repmonth = @repmonth
,l1.spisReason
,l1.nomenkGR
,sumSpisPRC = sum(l1.sumSpisPRC)
,sumSpisPenia = sum(l1.sumSpisPenia)
,sumFogiveOD = sum(l1.sumFogiveOD)
,sumFogivePRC = sum(l1.sumFogivePRC)
,sumFogivePenia = sum(l1.sumFogivePenia)
,sumItog = sum(l1.sumItog)
,dogCount = sum(l1.dogCount)
,l1.rowNum
,dogCountOD = sum(l1.dogCountOD)
from(
select
spisReason	
,nomenkGR = 'Контроль'
,sumSpisPRC	= case when nomenkGR != 'Все продукты' then sumSpisPRC * -1 else sumSpisPRC end
,sumSpisPenia = case when nomenkGR != 'Все продукты' then sumSpisPenia * -1 else sumSpisPenia end
,sumFogiveOD = case when nomenkGR != 'Все продукты' then sumFogiveOD * -1 else sumFogiveOD end
,sumFogivePRC = case when nomenkGR != 'Все продукты' then sumFogivePRC * -1 else sumFogivePRC end
,sumFogivePenia = case when nomenkGR != 'Все продукты' then sumFogivePenia * -1 else sumFogivePenia end	
,sumItog = case when nomenkGR != 'Все продукты' then sumItog * -1 else sumItog end	
,dogCount = case when nomenkGR != 'Все продукты' then dogCount * -1 else dogCount end	
,rowNum
,dogCountOD = case when nomenkGR != 'Все продукты' then dogCountOD * -1 else dogCountOD end	

from finAnalytics.repForgive2
where repmonth= @repmonth
) l1

group by 
l1.spisReason
,l1.nomenkGR
,l1.rowNum

--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

END
