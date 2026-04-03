



CREATE PROCEDURE [finAnalytics].[calcRepForgive2_2]
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
  l1.repMonth	
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
, l1.[Дата акции]
--0 дней = "просрочка 0"; 1 день - "просрочка 1-90"; 91-360 дней = "просрочка 91-360"; больше/равно 361 день = "просрочка 360+")
,[Бакет просрочки] = case 
						when isnull(bucket.prosDaysTotal,0) = 0 then '    в т.ч. просрочка 0'
						when isnull(bucket.prosDaysTotal,0) between 1 and 90 then '    в т.ч. просрочка 1-90'
						when isnull(bucket.prosDaysTotal,0) between 91 and 360 then '    в т.ч. просрочка 91-360'
						when isnull(bucket.prosDaysTotal,0) >=361 then '    в т.ч. просрочка 360+'
					else '-' end
,[Бакет сортировка] = case 
						when isnull(bucket.prosDaysTotal,0) = 0 then 1
						when isnull(bucket.prosDaysTotal,0) between 1 and 90 then 2
						when isnull(bucket.prosDaysTotal,0) between 91 and 360 then 3
						when isnull(bucket.prosDaysTotal,0) >=361 then 4
					else '-' end

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
,[Дата акции] = convert(date,substring(a.spisanieText,CHARINDEX(' от ',a.spisanieText)+4,10),104)
--, dataLoadDate
from finAnalytics.akcia_vzisk_MONTHLY a
left join finAnalytics.PBR_MONTHLY b on b.REPMONTH=@repmonth and b.dogNum=substring(a.zaim,CHARINDEX('№ ',a.zaim)+2,CHARINDEX(' от ',a.zaim)-8)

where a.repMonth = @repmonth
) l1

left join (
select
dogNum
,repMonth
,prosDaysTotal
from dwh2.finAnalytics.PBR_MONTHLY
where repmonth = dateadd(month,-1,@repmonth)
) bucket on l1.[Номер договора] = bucket.dogNum 



DROP TABLE IF EXISTS #spReason
CREATE TABLE #spReason(
reasonName varchar(500) not null,
bucket varchar(100) not null,
rowNum int not null
)

insert into #spReason select 'Дисконтный калькулятор', '    в т.ч. просрочка 0',1
insert into #spReason select 'Дисконтный калькулятор', '    в т.ч. просрочка 1-90',2
insert into #spReason select 'Дисконтный калькулятор', '    в т.ч. просрочка 91-360',3
insert into #spReason select 'Дисконтный калькулятор', '    в т.ч. просрочка 360+',4

insert into #spReason select 'Оферта 20% + новый график', '    в т.ч. просрочка 0',5
insert into #spReason select 'Оферта 20% + новый график', '    в т.ч. просрочка 1-90',6
insert into #spReason select 'Оферта 20% + новый график', '    в т.ч. просрочка 91-360',7
insert into #spReason select 'Оферта 20% + новый график', '    в т.ч. просрочка 360+',8

insert into #spReason select 'Согласно Приказа №213 от 06.12.2018 "Об утверждении лимитов расходования средств, направленных на погашение задолженности ФЛ"', '    в т.ч. просрочка 0',9
insert into #spReason select 'Согласно Приказа №213 от 06.12.2018 "Об утверждении лимитов расходования средств, направленных на погашение задолженности ФЛ"', '    в т.ч. просрочка 1-90',10
insert into #spReason select 'Согласно Приказа №213 от 06.12.2018 "Об утверждении лимитов расходования средств, направленных на погашение задолженности ФЛ"', '    в т.ч. просрочка 91-360',11
insert into #spReason select 'Согласно Приказа №213 от 06.12.2018 "Об утверждении лимитов расходования средств, направленных на погашение задолженности ФЛ"', '    в т.ч. просрочка 360+',12

delete from finAnalytics.repForgive2_2 where repmonth = @repmonth


--------------------'Все продукты'
insert into finAnalytics.repForgive2_2
([repmonth], [spisReason], [bucket], [nomenkGR], [sumSpisPRC], [sumSpisPenia], [sumFogiveOD], [sumFogivePRC], [sumFogivePenia], [sumItog], [restoreRVP], [finrez], [rowNum], [bucketNum])
Select
repmonth = @repmonth
,spisReason = a.reasonName
,bucket = a.bucket
,nomenkGR = 'Все продукты'
,sumSpisPRC = isnull(b.sumSpisPRC,0) * -1
,sumSpisPenia = isnull(b.sumSpisPenia,0) * -1
,sumFogiveOD = isnull(b.sumFogiveOD,0) * -1
,sumFogivePRC = isnull(b.sumFogivePRC,0) * -1
,sumFogivePenia = isnull(b.sumFogivePenia,0) * -1
,sumItog = isnull(b.sumItog,0) * -1
,restoreRVP = abs(isnull(b.restoreRVP,0))
,finrez = isnull(b.sumItog,0) * -1
		+ abs(isnull(b.restoreRVP,0))			
,rowNum = a.rowNum
,[bucketNum] = b.[bucketNum]
from #spReason a
left join(
select
spisReason = a.[Ссылка.Причина]
,bucket = a.[Бакет просрочки]
,nomenkGR = 'Все продукты'
,sumSpisPRC = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
,sumSpisPenia = isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
,sumFogiveOD = isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
,sumFogivePRC = isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
,sumFogivePenia = isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
,sumItog = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
		+   isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
		+   isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
,[restoreRVP] = isnull(SUM(a.[Сумма восстанволено резервов]),0)
,[bucketNum] = a.[Бакет сортировка]
from #rep3 a
group by a.[Ссылка.Причина], a.[Бакет просрочки],a.[Бакет сортировка]
) b on a.reasonName=b.spisReason and a.bucket = b.bucket

--------------------'ПТС'
insert into finAnalytics.repForgive2_2
([repmonth], [spisReason], [bucket], [nomenkGR], [sumSpisPRC], [sumSpisPenia], [sumFogiveOD], [sumFogivePRC], [sumFogivePenia], [sumItog], [restoreRVP], [finrez], [rowNum], [bucketNum])
Select
repmonth = @repmonth
,spisReason = a.reasonName
,bucket = a.bucket
,nomenkGR = 'ПТС'
,sumSpisPRC = isnull(b.sumSpisPRC,0) * -1
,sumSpisPenia = isnull(b.sumSpisPenia,0) * -1
,sumFogiveOD = isnull(b.sumFogiveOD,0) * -1
,sumFogivePRC = isnull(b.sumFogivePRC,0) * -1
,sumFogivePenia = isnull(b.sumFogivePenia,0) * -1
,sumItog = isnull(b.sumItog,0) * -1
,restoreRVP = abs(isnull(b.restoreRVP,0))
,finrez = isnull(b.sumItog,0) * -1
		+ abs(isnull(b.restoreRVP,0))			
,rowNum = a.rowNum
,[bucketNum] = b.[bucketNum]
from #spReason a
left join(
select
spisReason = a.[Ссылка.Причина]
,bucket = a.[Бакет просрочки]
,nomenkGR = 'ПТС'
,sumSpisPRC = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
,sumSpisPenia = isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
,sumFogiveOD = isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
,sumFogivePRC = isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
,sumFogivePenia = isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
,sumItog = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
		+   isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
		+   isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
,[restoreRVP] = isnull(SUM(a.[Сумма восстанволено резервов]),0)
,[bucketNum] = a.[Бакет сортировка]
from #rep3 a
Where a.[Номенклатурная группа] = 'ПТС'
group by a.[Ссылка.Причина], a.[Бакет просрочки],a.[Бакет сортировка]
) b on a.reasonName=b.spisReason and a.bucket = b.bucket

--select distinct a.[Номенклатурная группа] from #rep3 a

--------------------'IL'
insert into finAnalytics.repForgive2_2
([repmonth], [spisReason], [bucket], [nomenkGR], [sumSpisPRC], [sumSpisPenia], [sumFogiveOD], [sumFogivePRC], [sumFogivePenia], [sumItog], [restoreRVP], [finrez], [rowNum], [bucketNum])
Select
repmonth = @repmonth
,spisReason = a.reasonName
,bucket = a.bucket
,nomenkGR = 'IL'
,sumSpisPRC = isnull(b.sumSpisPRC,0) * -1
,sumSpisPenia = isnull(b.sumSpisPenia,0) * -1
,sumFogiveOD = isnull(b.sumFogiveOD,0) * -1
,sumFogivePRC = isnull(b.sumFogivePRC,0) * -1
,sumFogivePenia = isnull(b.sumFogivePenia,0) * -1
,sumItog = isnull(b.sumItog,0) * -1
,restoreRVP = abs(isnull(b.restoreRVP,0))
,finrez = isnull(b.sumItog,0) * -1
		+ abs(isnull(b.restoreRVP,0))			
,rowNum = a.rowNum
,[bucketNum] = b.[bucketNum]
from #spReason a
left join(
select
spisReason = a.[Ссылка.Причина]
,bucket = a.[Бакет просрочки]
,nomenkGR = 'IL'
,sumSpisPRC = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
,sumSpisPenia = isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
,sumFogiveOD = isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
,sumFogivePRC = isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
,sumFogivePenia = isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
,sumItog = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
		+   isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
		+   isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
,[restoreRVP] = isnull(SUM(a.[Сумма восстанволено резервов]),0)
,[bucketNum] = a.[Бакет сортировка]
from #rep3 a
Where a.[Номенклатурная группа] = 'IL'
group by a.[Ссылка.Причина], a.[Бакет просрочки],a.[Бакет сортировка]
) b on a.reasonName=b.spisReason and a.bucket = b.bucket

--------------------'PDL'
insert into finAnalytics.repForgive2_2
([repmonth], [spisReason], [bucket], [nomenkGR], [sumSpisPRC], [sumSpisPenia], [sumFogiveOD], [sumFogivePRC], [sumFogivePenia], [sumItog], [restoreRVP], [finrez], [rowNum], [bucketNum])
Select
repmonth = @repmonth
,spisReason = a.reasonName
,bucket = a.bucket
,nomenkGR = 'PDL'
,sumSpisPRC = isnull(b.sumSpisPRC,0) * -1
,sumSpisPenia = isnull(b.sumSpisPenia,0) * -1
,sumFogiveOD = isnull(b.sumFogiveOD,0) * -1
,sumFogivePRC = isnull(b.sumFogivePRC,0) * -1
,sumFogivePenia = isnull(b.sumFogivePenia,0) * -1
,sumItog = isnull(b.sumItog,0) * -1
,restoreRVP = abs(isnull(b.restoreRVP,0))
,finrez = isnull(b.sumItog,0) * -1
		+ abs(isnull(b.restoreRVP,0))			
,rowNum = a.rowNum
,[bucketNum] = b.[bucketNum]
from #spReason a
left join(
select
spisReason = a.[Ссылка.Причина]
,bucket = a.[Бакет просрочки]
,nomenkGR = 'PDL'
,sumSpisPRC = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
,sumSpisPenia = isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
,sumFogiveOD = isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
,sumFogivePRC = isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
,sumFogivePenia = isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
,sumItog = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
		+   isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
		+   isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
,[restoreRVP] = isnull(SUM(a.[Сумма восстанволено резервов]),0)
,[bucketNum] = a.[Бакет сортировка]
from #rep3 a
Where a.[Номенклатурная группа] = 'PDL'
group by a.[Ссылка.Причина], a.[Бакет просрочки],a.[Бакет сортировка]
) b on a.reasonName=b.spisReason and a.bucket = b.bucket

--------------------'Автокредит'
insert into finAnalytics.repForgive2_2
([repmonth], [spisReason], [bucket], [nomenkGR], [sumSpisPRC], [sumSpisPenia], [sumFogiveOD], [sumFogivePRC], [sumFogivePenia], [sumItog], [restoreRVP], [finrez], [rowNum], [bucketNum])
Select
repmonth = @repmonth
,spisReason = a.reasonName
,bucket = a.bucket
,nomenkGR = 'Автокредит'
,sumSpisPRC = isnull(b.sumSpisPRC,0) * -1
,sumSpisPenia = isnull(b.sumSpisPenia,0) * -1
,sumFogiveOD = isnull(b.sumFogiveOD,0) * -1
,sumFogivePRC = isnull(b.sumFogivePRC,0) * -1
,sumFogivePenia = isnull(b.sumFogivePenia,0) * -1
,sumItog = isnull(b.sumItog,0) * -1
,restoreRVP = abs(isnull(b.restoreRVP,0))
,finrez = isnull(b.sumItog,0) * -1
		+ abs(isnull(b.restoreRVP,0))			
,rowNum = a.rowNum
,[bucketNum] = b.[bucketNum]
from #spReason a
left join(
select
spisReason = a.[Ссылка.Причина]
,bucket = a.[Бакет просрочки]
,nomenkGR = 'Автокредит'
,sumSpisPRC = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
,sumSpisPenia = isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
,sumFogiveOD = isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
,sumFogivePRC = isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
,sumFogivePenia = isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
,sumItog = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
		+   isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
		+   isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
,[restoreRVP] = isnull(SUM(a.[Сумма восстанволено резервов]),0)
,[bucketNum] = a.[Бакет сортировка]
from #rep3 a
Where a.[Номенклатурная группа] = 'Автокредит'
group by a.[Ссылка.Причина], a.[Бакет просрочки],a.[Бакет сортировка]
) b on a.reasonName=b.spisReason and a.bucket = b.bucket

--------------------'Big Installment'
insert into finAnalytics.repForgive2_2
([repmonth], [spisReason], [bucket], [nomenkGR], [sumSpisPRC], [sumSpisPenia], [sumFogiveOD], [sumFogivePRC], [sumFogivePenia], [sumItog], [restoreRVP], [finrez], [rowNum], [bucketNum])
Select
repmonth = @repmonth
,spisReason = a.reasonName
,bucket = a.bucket
,nomenkGR = 'Big Installment'
,sumSpisPRC = isnull(b.sumSpisPRC,0) * -1
,sumSpisPenia = isnull(b.sumSpisPenia,0) * -1
,sumFogiveOD = isnull(b.sumFogiveOD,0) * -1
,sumFogivePRC = isnull(b.sumFogivePRC,0) * -1
,sumFogivePenia = isnull(b.sumFogivePenia,0) * -1
,sumItog = isnull(b.sumItog,0) * -1
,restoreRVP = abs(isnull(b.restoreRVP,0))
,finrez = isnull(b.sumItog,0) * -1
		+ abs(isnull(b.restoreRVP,0))			
,rowNum = a.rowNum
,[bucketNum] = b.[bucketNum]
from #spReason a
left join(
select
spisReason = a.[Ссылка.Причина]
,bucket = a.[Бакет просрочки]
,nomenkGR = 'Big Installment'
,sumSpisPRC = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
,sumSpisPenia = isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
,sumFogiveOD = isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
,sumFogivePRC = isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
,sumFogivePenia = isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
,sumItog = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
		+   isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
		+   isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
,[restoreRVP] = isnull(SUM(a.[Сумма восстанволено резервов]),0)
,[bucketNum] = a.[Бакет сортировка]
from #rep3 a
Where a.[Номенклатурная группа] = 'Big Installment'
group by a.[Ссылка.Причина], a.[Бакет просрочки],a.[Бакет сортировка]
) b on a.reasonName=b.spisReason and a.bucket = b.bucket


--------------------'БЗ'
insert into finAnalytics.repForgive2_2
([repmonth], [spisReason], [bucket], [nomenkGR], [sumSpisPRC], [sumSpisPenia], [sumFogiveOD], [sumFogivePRC], [sumFogivePenia], [sumItog], [restoreRVP], [finrez], [rowNum], [bucketNum])
Select
repmonth = @repmonth
,spisReason = a.reasonName
,bucket = a.bucket
,nomenkGR = 'БЗ'
,sumSpisPRC = isnull(b.sumSpisPRC,0) * -1
,sumSpisPenia = isnull(b.sumSpisPenia,0) * -1
,sumFogiveOD = isnull(b.sumFogiveOD,0) * -1
,sumFogivePRC = isnull(b.sumFogivePRC,0) * -1
,sumFogivePenia = isnull(b.sumFogivePenia,0) * -1
,sumItog = isnull(b.sumItog,0) * -1
,restoreRVP = abs(isnull(b.restoreRVP,0))
,finrez = isnull(b.sumItog,0) * -1
		+ abs(isnull(b.restoreRVP,0))			
,rowNum = a.rowNum
,[bucketNum] = b.[bucketNum]
from #spReason a
left join(
select
spisReason = a.[Ссылка.Причина]
,bucket = a.[Бакет просрочки]
,nomenkGR = 'БЗ'
,sumSpisPRC = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
,sumSpisPenia = isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
,sumFogiveOD = isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
,sumFogivePRC = isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
,sumFogivePenia = isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
,sumItog = isnull(SUM(a.[Проценты (Дт. 71001 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71701 - Кт. 60323)]),0)
		+   isnull(SUM(a.[Основной долг (Дт. 71802 - Кт. 48801)]),0)
		+   isnull(SUM(a.[Проценты (Дт. 71802 - Кт. 48802)]),0)
		+   isnull(SUM(a.[Пени (Дт. 71802 - Кт. 60323)]),0)
,[restoreRVP] = isnull(SUM(a.[Сумма восстанволено резервов]),0)
,[bucketNum] = a.[Бакет сортировка]
from #rep3 a
Where a.[Номенклатурная группа] = 'БЗ'
group by a.[Ссылка.Причина], a.[Бакет просрочки],a.[Бакет сортировка]
) b on a.reasonName=b.spisReason and a.bucket = b.bucket

--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

END
