




CREATE PROC [finAnalytics].[calcRep845] 
    @repmonth date
AS
BEGIN
	
	DECLARE @subject NVARCHAR(2048) = 'Расчет данных для отчета 845'
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

  begin try
	
	DROP TABLE IF EXISTS #rep

CREATE Table #rep(
	[repmonth] date not null,
	[rowNum] int not null,
	[rowName] nvarchar(50) null,
	[pokazatel] nvarchar(max) null,
	[aplicator] int null,
	[DTAcc] nvarchar(10) null,
	[KTAcc] nvarchar(10) null,
	[isBold] int null,
	[comment] nvarchar(255) null,
	[amount] float not null
)

insert into #rep
select
[repmonth] = @repmonth
,rowNum	
,rowName	
,pokazatel	
,aplicator	
,DTAcc	
,KTAcc	
,isBold
,comment
,amount = 0

from dwh2.[finAnalytics].[SPR_rep_f845] 

declare @dateFrom datetime = dateadd(year,2000,@repmonth)
declare @dateToTmp datetime = dateadd(day,1,dateadd(year,2000,eomonth(@repmonth)))
declare @dateTo datetime = dateadd(second,-1,@dateToTmp)

--select @dateFrom,@dateTo

DROP TABLE IF EXISTS #prov

SELECT 

[Дата операции] = cast(dateadd(year,-2000,a.Период) as date)
,[СчетДтКод] = Dt.Код
,[СчетКтКод] = Kt.Код
,[Сумма БУ] = isnull(a.Сумма,0)
,[Содержание] = a.Содержание
,[НомерМемориальногоОрдера] = a.НомерМемориальногоОрдера
,[Номер договора КТ] = crkt.Номер
,[Номер договора ДТ] = crdt.Номер
,[Статья ДДС] = isnull(ddsCT.Наименование,ddsDT.Наименование)
,[Клиент] = isnull(cldt.Наименование,clkt.Наименование)
,[Договор] = isnull(dogDT.Наименование,dogKT.Наименование)

into #prov 

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.СубконтоDt2_Ссылка=crdt.Ссылка and crdt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_СтатьиДвиженияДенежныхСредств ddsCT on a.СубконтоCt2_Ссылка = ddsCT.Ссылка and ddsCT.ПометкаУдаления = 0x00
left join stg._1cUMFO.Справочник_СтатьиДвиженияДенежныхСредств ddsDT on a.СубконтоDt2_Ссылка = ddsDT.Ссылка and ddsDT.ПометкаУдаления = 0x00
left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов dogDT on a.СубконтоDt2_Ссылка=dogDT.Ссылка
left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов dogKT on a.СубконтоDt2_Ссылка=dogKT.Ссылка
left join stg._1cUMFO.Справочник_Контрагенты cldt on a.Субконтоdt1_Ссылка=cldt.Ссылка
left join stg._1cUMFO.Справочник_Контрагенты clKt on a.СубконтоCt1_Ссылка=clKt.Ссылка

where a.Период between @dateFrom and @dateTo
and a.Активность=01
and ( Dt.Код in ('20501','47422','61217','48809','42317','43709','43809','43719','52008',
				 '47423','71101','60311','60312','60301','60305','60307','60308','60335',
				 '60336','60323','60322','47416','71702','60331','60332','60901','42316',
				 '43708','43808','60320','60906'
				 )

	or
	  Kt.Код in ('71001','48509','48809','49409','47422','20501','42317','60806','60311',
				 '60312','60301','60305','60308','60307','60336','60323','60322','47416',
				 '47423','48501','60331','60332','60309','71701','71702','60906','42316',
				 '43708','43808','52008','10614','20601'
				 )
	)

--select * from #prov


/*Заполнение данных по безусловным показателям*/
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Сумма БУ] = sum([Сумма БУ])
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
) t2 on (t1.DTAcc = t2.СчетДтКод and t1.KTAcc = t2.СчетКтКод and t1.comment is null)
when matched then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

/*Блок заполнения из Справочника НАЛОГИ*/
--p180
merge into #rep t1
using(
		select
		[Назначение платежа]
		,[Сумма] = sum([Сумма])
		from dwh2.[finAnalytics].[SPR_nalogi_845]
		where [Дата платежа] between @repmonth and EOMONTH(@repmonth)
		and upper(Компания) = upper('КарМани')
		group by [Назначение платежа]
) t2 on (t1.rowNum = 180 and t2.[Сумма] is not null and upper(t2.[Назначение платежа]) = upper('НДФЛ инвесторы'))
when matched
then update
set t1.amount = abs(t2.[Сумма]) * t1.aplicator;

--p500
merge into #rep t1
using(
		select
		[Назначение платежа]
		,[Сумма] = sum([Сумма])
		from dwh2.[finAnalytics].[SPR_nalogi_845]
		where [Дата платежа] between @repmonth and EOMONTH(@repmonth)
		and upper(Компания) = upper('КарМани')
		group by [Назначение платежа]
) t2 on (t1.rowNum = 500 and t2.[Сумма] is not null and upper(t2.[Назначение платежа]) = upper('НДС'))
when matched
then update
set t1.amount = abs(t2.[Сумма]) * t1.aplicator;

--p510
merge into #rep t1
using(
		select
		[Назначение платежа]
		,[Сумма] = sum([Сумма])
		from dwh2.[finAnalytics].[SPR_nalogi_845]
		where [Дата платежа] between @repmonth and EOMONTH(@repmonth)
		and upper(Компания) = upper('КарМани')
		group by [Назначение платежа]
) t2 on (t1.rowNum = 510 and t2.[Сумма] is not null and upper(t2.[Назначение платежа]) = upper('транспортный налог'))
when matched
then update
set t1.amount = abs(t2.[Сумма]) * t1.aplicator;

--p515
merge into #rep t1
using(
		select
		[Назначение платежа]
		,[Сумма] = sum([Сумма])
		from dwh2.[finAnalytics].[SPR_nalogi_845]
		where [Дата платежа] between @repmonth and EOMONTH(@repmonth)
		and upper(Компания) = upper('КарМани')
		group by [Назначение платежа]
) t2 on (t1.rowNum = 515 and t2.[Сумма] is not null and upper(t2.[Назначение платежа]) = upper('Налог на прибыль'))
when matched
then update
set t1.amount = abs(t2.[Сумма]) * t1.aplicator;

--p790
merge into #rep t1
using(
		select
		[Назначение платежа]
		,[Сумма] = sum([Сумма])
		from dwh2.[finAnalytics].[SPR_nalogi_845]
		where [Дата платежа] between @repmonth and EOMONTH(@repmonth)
		and upper(Компания) = upper('КарМани')
		group by [Назначение платежа]
) t2 on (t1.rowNum = 790 and t2.[Сумма] is not null and upper(t2.[Назначение платежа]) = upper('Налог на прибыль'))
when matched
then update
set t1.amount = abs(t2.[Сумма]) * t1.aplicator;

--p520
merge into #rep t1
using(
		select
		[Назначение платежа]
		,[Сумма] = sum([Сумма])
		from dwh2.[finAnalytics].[SPR_nalogi_845]
		where [Дата платежа] between @repmonth and EOMONTH(@repmonth)
		and upper(Компания) = upper('КарМани')
		group by [Назначение платежа]
) t2 on (t1.rowNum = 520 and t2.[Сумма] is not null and upper(t2.[Назначение платежа]) = upper('НДФЛ инвесторы'))
when matched
then update
set t1.amount = abs(t2.[Сумма]) * t1.aplicator;

--p1380
merge into #rep t1
using(
		select
		[Назначение платежа]
		,[Сумма] = sum([Сумма])
		from dwh2.[finAnalytics].[SPR_nalogi_845]
		where [Дата платежа] between @repmonth and EOMONTH(@repmonth)
		and upper(Компания) = upper('КарМани')
		group by [Назначение платежа]
) t2 on (t1.rowNum = 1380 and t2.[Сумма] is not null and upper(t2.[Назначение платежа]) = upper('НДС'))
when matched
then update
set t1.amount = abs(t2.[Сумма]) * t1.aplicator;

--p1390
merge into #rep t1
using(
		select
		[Назначение платежа]
		,[Сумма] = sum([Сумма])
		from dwh2.[finAnalytics].[SPR_nalogi_845]
		where [Дата платежа] between @repmonth and EOMONTH(@repmonth)
		and upper(Компания) = upper('КарМани')
		group by [Назначение платежа]
) t2 on (t1.rowNum = 1390 and t2.[Сумма] is not null and upper(t2.[Назначение платежа]) = upper('транспортный налог'))
when matched
then update
set t1.amount = abs(t2.[Сумма]) * t1.aplicator;

/*Блок заполнения из Справочника НМА/ОС*/
--p480
merge into #rep t1
using(
		select
		--[Назначение платежа]
		[Сумма] = sum([Списание])
		from dwh2.[finAnalytics].[SPR_nmaos_845] --select * from dwh2.[finAnalytics].[SPR_nmaos_845]
		where [Дата] between @repmonth and EOMONTH(@repmonth)
		--and upper(Компания) = upper('КарМани')
		and [Тип] = 'ОС'
		--group by [Назначение платежа]
) t2 on (t1.rowNum = 480 and t2.[Сумма] is not null)
when matched
then update
set t1.amount = abs(t2.[Сумма]) * t1.aplicator;

--p660
merge into #rep t1
using(
		select
		--[Назначение платежа]
		[Сумма] = sum([Списание])
		from dwh2.[finAnalytics].[SPR_nmaos_845] --select * from dwh2.[finAnalytics].[SPR_nmaos_845]
		where [Дата] between @repmonth and EOMONTH(@repmonth)
		--and upper(Компания) = upper('КарМани')
		and [Тип] = 'НМА'
		--group by [Назначение платежа]
) t2 on (t1.rowNum = 660 and t2.[Сумма] is not null)
when matched
then update
set t1.amount = abs(t2.[Сумма]) * t1.aplicator;

--p1530
merge into #rep t1
using(
		select
		--[Назначение платежа]
		[Сумма] = sum([Списание])
		from dwh2.[finAnalytics].[SPR_nmaos_845] --select * from dwh2.[finAnalytics].[SPR_nmaos_845]
		where [Дата] between @repmonth and EOMONTH(@repmonth)
		--and upper(Компания) = upper('КарМани')
		and [Тип] = 'НМА'
		--group by [Назначение платежа]
) t2 on (t1.rowNum = 1530 and t2.[Сумма] is not null)
when matched
then update
set t1.amount = abs(t2.[Сумма]) * t1.aplicator;


--p1510
merge into #rep t1
using(
		select
		--[Назначение платежа]
		[Сумма] = sum([Списание])
		from dwh2.[finAnalytics].[SPR_nmaos_845] --select * from dwh2.[finAnalytics].[SPR_nmaos_845]
		where [Дата] between @repmonth and EOMONTH(@repmonth)
		--and upper(Компания) = upper('КарМани')
		and [Тип] = 'ОС'
		--group by [Назначение платежа]
) t2 on (t1.rowNum = 1510 and t2.[Сумма] is not null)
when matched
then update
set t1.amount = abs(t2.[Сумма]) * t1.aplicator;

/*Блок расчетов по ДДС*/
--p146
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	where upper(isnull([Статья ДДС],'-')) = upper('Поступление привлеченных средств прочих')
	and upper([Клиент]) = upper('СМАРТ ГОРИЗОНТ ООО')
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 146
			and t2.[Сумма БУ] is not null 
			--and upper(isnull(t2.[Статья ДДС],'-')) = upper('Поступление привлеченных средств прочих')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p150
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 150
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Выплата купонного дохода')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p160
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 160
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Выплата купонного дохода')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p220
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 220 
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Расчеты с Партнерами/ Агентами за выдачу микрозайма')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p230
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 230 
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Лидогенераторы')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p240
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 240 
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Контекст')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;


--p250
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 250 
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Услуги верификации (Кредитные отчеты)')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p260
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 260 
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Услуги верификации (Скоринг)')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p270
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 270 
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Прочие услуги по оценке физических и юридических лиц')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p280
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 280 
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Расчеты с Партнерами/ Агентами за выдачу микрозайма')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p290
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 290 
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Лидогенераторы')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p300
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 300
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Контекст')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p310
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 310
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Прочие услуги по оценке физических и юридических лиц')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p320
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 320
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Услуги верификации (Кредитные отчеты)')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p330
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 330
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Услуги верификации (Скоринг)')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p340	
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 340
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Расчеты с Партнерами/ Агентами за выдачу микрозайма')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p345	
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 345
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Лидогенераторы')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p350
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 350
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Расчеты с Партнерами/ Агентами за выдачу микрозайма')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p450
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 450
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Государственные пошлины')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p460
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 460
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Прочие судебные расходы и коллекторские расходы')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p470
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 470
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Государственные пошлины')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p550
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 550
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Расчеты с Партнерами/ Агентами за выдачу микрозайма')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p560
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 560
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) != upper('Расчеты с Партнерами/ Агентами за выдачу микрозайма')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p570
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 570
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Расчеты с Партнерами/ Агентами за выдачу микрозайма')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p580
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	--,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	where upper(isnull([Статья ДДС],'-')) != upper('Расчеты с Партнерами/ Агентами за выдачу микрозайма')
--	and СчетДтКод = '20501'
--	and СчетКтКод = '60312'
	group by
	СчетДтКод	
	,СчетКтКод
	--,[Статья ДДС]
) t2 on (t1.rowNum = 580
			and t2.[Сумма БУ] is not null 
			--and upper(isnull(t2.[Статья ДДС],'-')) != upper('Расчеты с Партнерами/ Агентами за выдачу микрозайма')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p586
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	--,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	where upper(isnull([Статья ДДС],'-')) != upper('Расчеты с Партнерами/ Агентами за выдачу микрозайма')
--	and СчетДтКод = '20501'
--	and СчетКтКод = '60312'
	group by
	СчетДтКод	
	,СчетКтКод
	--,[Статья ДДС]
) t2 on (t1.rowNum = 586
			and t2.[Сумма БУ] is not null 
			--and upper(isnull(t2.[Статья ДДС],'-')) != upper('Расчеты с Партнерами/ Агентами за выдачу микрозайма')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p585
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	--,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	where upper(isnull([Статья ДДС],'-')) = upper('Страховая премия по договорам коллективного страхования')
	and СчетДтКод = '20501'
	and СчетКтКод = '60312'
	group by
	СчетДтКод	
	,СчетКтКод
	--,[Статья ДДС]
) t2 on (t1.rowNum = 585
			and t2.[Сумма БУ] is not null 
			--and upper(isnull(t2.[Статья ДДС],'-')) != upper('Расчеты с Партнерами/ Агентами за выдачу микрозайма')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p590
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 590
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Страховая премия по агентским договорам страхования')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p592
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 592
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Страховая премия по договорам коллективного страхования')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p594
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 594
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Страховая премия по договорам коллективного страхования')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p600
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 600
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Страховая премия по агентским договорам страхования')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p616
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 616
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Лидогенераторы')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p618
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 618
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Поступление привлеченных средств прочих')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p620
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 620
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Государственные пошлины')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p630
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 630
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Государственные пошлины')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

----p618
--merge into #rep t1
--using(
--	select
--	СчетДтКод	
--	,СчетКтКод
--	,[Статья ДДС]
--	,[Сумма БУ] = abs(sum([Сумма БУ]))
--	from #prov
--	where 
--	upper([Клиент]) = upper('СМАРТ ГОРИЗОНТ ООО')
--	and СчетДтКод = '20501'
--	and СчетКтКод = '60323'
--	group by
--	СчетДтКод	
--	,СчетКтКод
--	,[Статья ДДС]
--) t2 on (t1.rowNum = 618 )
--when matched
--then update
--set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p640
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	where [Статья ДДС] ='Арендная плата'
	and upper([Клиент]) = upper('МЕРИДИАН ООО')
	and upper([Договор]) = upper('КРАТКОСРОЧНЫЙ ДОГОВОР СУБАРЕНДЫ № 181 от 01.06.2021')
	--and upper([Содержание]) like upper('%Аренда плата%')
	and upper([Содержание]) like upper('%Аренд%')
	and СчетДтКод = '60312'
	and СчетКтКод = '20501'
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 640)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p650
merge into #rep t1
using(
	select
	[Сумма БУ] = case when l2.[Сумма БУ] != 0 then l1.[Сумма БУ] else 0 end
	from (
	select
	[Сумма БУ] = abs(sum(a.[Сумма БУ]))
	from #prov a
	where upper([Клиент]) = upper('МАЙНИТЕК ООО')
	and upper([Договор]) = upper('№ ЛД-232/2024 от 31.07.2024')
	and СчетДтКод = '60311'
	and СчетКтКод = '20501'
	) l1
	left join (
	select
	[Сумма БУ] = isnull(abs(sum([Сумма БУ])),0)
	from #prov
	where upper([Клиент]) = upper('МАЙНИТЕК ООО')
	and upper([Договор]) = upper('№ ЛД-232/2024 от 31.07.2024')
	and СчетДтКод = '60906'
	and СчетКтКод = '60311'
	) l2 on 1=1
) t2 on (t1.rowNum = 650)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1540
merge into #rep t1
using(
	select
	[Сумма БУ] = case when l2.[Сумма БУ] != 0 then l1.[Сумма БУ] else 0 end
	from (
	select
	[Сумма БУ] = abs(sum(a.[Сумма БУ]))
	from #prov a
	where upper([Клиент]) = upper('МАЙНИТЕК ООО')
	and upper([Договор]) = upper('№ ЛД-232/2024 от 31.07.2024')
	and СчетДтКод = '60311'
	and СчетКтКод = '20501'
	) l1
	left join (
	select
	[Сумма БУ] = isnull(abs(sum([Сумма БУ])),0)
	from #prov
	where upper([Клиент]) = upper('МАЙНИТЕК ООО')
	and upper([Договор]) = upper('№ ЛД-232/2024 от 31.07.2024')
	and СчетДтКод = '60906'
	and СчетКтКод = '60311'
	) l2 on 1=1
) t2 on (t1.rowNum = 1540)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p670
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 670
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Лидогенераторы')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p680
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 680
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Контекст')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p690
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 690
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Услуги верификации (Кредитные отчеты)')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p700
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 700
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Услуги верификации (Скоринг)')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p710
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 710
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Прочие услуги по оценке физических и юридических лиц')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p720
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 720
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Лидогенераторы')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p730
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 730
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Контекст')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p740
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 740
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Прочие услуги по оценке физических и юридических лиц')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p750
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 750
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Услуги верификации (Кредитные отчеты)')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p760
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 760
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Услуги верификации (Скоринг)')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p850
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 850
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Возврат ОД по микрозаймам')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p860
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 860
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Цессия')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p866
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 866
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Денежный поток по договору цессии')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p870
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 870
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Денежный поток по договору цессии')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p880
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 880
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Цессия')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p940
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	where upper(isnull([Статья ДДС],'-')) = upper('Прочие')
	and СчетДтКод = '60323'
	and СчетКтКод = '20501'
	and upper([Содержание]) like upper('%Возврат ошибочно%')
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 940)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;



--p950
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 950
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Цессия')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p960
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 960
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Цессия')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p970
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 970
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Денежный поток по договору цессии')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

----p1140
--merge into #rep t1
--using(
--	select
--	СчетДтКод	
--	,СчетКтКод
--	,[Статья ДДС]
--	,[Сумма БУ] = abs(sum([Сумма БУ]))
--	from #prov
--	group by
--	СчетДтКод	
--	,СчетКтКод
--	,[Статья ДДС]
--) t2 on (t1.rowNum = 1140
--			and t2.[Сумма БУ] is not null 
--			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Иные услуги')
--			and t1.DTAcc = t2.СчетДтКод
--			and t1.KTAcc = t2.СчетКтКод
--			)
--when matched
--then update
--set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1180
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1180
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Страховая премия по агентским договорам страхования')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1190
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1190
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Страховая премия по договорам коллективного страхования')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1210
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1210
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Цессия')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1220
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1220
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Денежный поток по договору цессии')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1220
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1220
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Государственные пошлины')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1230
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1230
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Прочие судебные расходы и коллекторские расходы')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;


--p1240
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	where upper(isnull([Статья ДДС],'-')) = upper('Прочие')
	and СчетДтКод = '60323'
	and СчетКтКод = '20501'
	and upper([Содержание]) like upper('%Возврат ошибочно%')
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1240)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;


--p1250
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1250
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Возврат комиссионного вознаграждения по агентским договорам страхования')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1252
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1252
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Государственные пошлины')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1270
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1270
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Цессия')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1280
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1280
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Государственные пошлины')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1290
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1290
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Возврат ОД по микрозаймам')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1360
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1360
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Цессия')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1370
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1370
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Денежный поток по договору цессии')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1400
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1400
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Страховая премия по агентским договорам страхования')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1410
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1410
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Страховая премия по договорам коллективного страхования')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1411
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1411
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Страховая премия по договорам коллективного страхования')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1412
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1412
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Страховая премия по агентским договорам страхования')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1413
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1413
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Прочие судебные расходы и коллекторские расходы')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1414
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov --select * from #prov
	where upper(isnull([Статья ДДС],'-')) = upper('Прочие')
	and upper(Содержание) like upper('%возврат%ошибочно%')
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1414
			and t2.[Сумма БУ] is not null 
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1415
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1415
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Возврат комиссионного вознаграждения по агентским договорам страхования')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1416
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1416
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Цессия')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;


--p1430
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1430
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Цессия')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1440
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1440
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Денежный поток по договору цессии')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1450
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1450
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Государственные пошлины')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1876
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1876
			and t2.[Сумма БУ] is not null 
			and upper(isnull(t2.[Статья ДДС],'-')) = upper('Поступления от выпуска долговых ценных бумаг')
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;


--p1770
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	where upper(isnull([Статья ДДС],'-')) = upper('Арендная плата')
	and upper([Клиент]) = upper('МЕРИДИАН ООО')
	and upper([Договор]) = upper('КРАТКОСРОЧНЫЙ ДОГОВОР СУБАРЕНДЫ № 181 от 01.06.2021')
	--and upper([Содержание]) like upper('%Аренда плата%')
	and upper([Содержание]) like upper('%Аренд%')
	and СчетДтКод = '60312'
	and СчетКтКод = '20501'
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1770)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1800
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov
	where upper(isnull([Статья ДДС],'-')) = upper('Арендная плата')
	and upper([Клиент]) = upper('МЕРИДИАН ООО')
	and upper([Договор]) = upper('КРАТКОСРОЧНЫЙ ДОГОВОР СУБАРЕНДЫ № 181 от 01.06.2021')
	--and upper([Содержание]) like upper('%Аренда плата%')
	and upper([Содержание]) like upper('%Аренд%')
	and СчетДтКод = '60312'
	and СчетКтКод = '20501'
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1800)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;


/*Прочие нестандартные проводки*/

----p146
--merge into #rep t1
--using(
--	select
--	СчетДтКод	
--	,СчетКтКод
--	,[Статья ДДС]
--	,[Сумма БУ] = abs(sum([Сумма БУ]))
--	from #prov --select * from #prov
--	where 
--	--upper([Содержание]) like upper('%выплат%купонн%доход%')
--	--and
--	upper([Клиент]) = upper('СМАРТ ГОРИЗОНТ ООО')
--	group by
--	СчетДтКод	
--	,СчетКтКод
--	,[Статья ДДС]
--) t2 on (t1.rowNum = 146
--			and t2.[Сумма БУ] is not null 
--			and t1.DTAcc = t2.СчетДтКод
--			and t1.KTAcc = t2.СчетКтКод
--			)
--when matched
--then update
--set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

----p150
--merge into #rep t1
--using(
--	select
--	СчетДтКод	
--	,СчетКтКод
--	,[Статья ДДС]
--	,[Сумма БУ] = abs(sum([Сумма БУ]))
--	from #prov --select * from #prov
--	where 
--	upper([Содержание]) like upper('%выплат%купонн%доход%')
--	--and
--	--upper([Клиент]) = upper('НКО АО НРД')
--	group by
--	СчетДтКод	
--	,СчетКтКод
--	,[Статья ДДС]
--) t2 on (t1.rowNum = 150
--			and t2.[Сумма БУ] is not null 
--			and t1.DTAcc = t2.СчетДтКод
--			and t1.KTAcc = t2.СчетКтКод
--			)
--when matched
--then update
--set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

----p160
--merge into #rep t1
--using(
--	select
--	СчетДтКод	
--	,СчетКтКод
--	,[Статья ДДС]
--	,[Сумма БУ] = abs(sum([Сумма БУ]))
--	from #prov --select * from #prov
--	where 
--	upper([Содержание]) like upper('%выплат%купонн%доход%')
--	and
--	upper([Клиент]) = upper('НКО АО НРД')
--	group by
--	СчетДтКод	
--	,СчетКтКод
--	,[Статья ДДС]
--) t2 on (t1.rowNum = 160
--			and t2.[Сумма БУ] is not null 
--			and t1.DTAcc = t2.СчетДтКод
--			and t1.KTAcc = t2.СчетКтКод
--			)
--when matched
--then update
--set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p980
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov --select * from #prov
	where 
	upper([Содержание]) like upper('%возврат%')
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 980
			and t2.[Сумма БУ] is not null 
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p990
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	--,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov --select * from #prov
	where 
	(
	upper(Содержание) like upper('%ДКП%')
	or
	upper(Содержание) like upper('% купли%продажи %')
	or
	upper(Содержание) like upper('%залог%')
	or
	upper(Содержание) like upper('% авто%')
	)
	--and СчетДтКод='20501' and СчетКтКод='47422'
	group by
	СчетДтКод	
	,СчетКтКод
	--,[Статья ДДС]
) t2 on (t1.rowNum = 990
			and t2.[Сумма БУ] is not null 
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1060
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov --select * from #prov
	where 
	upper([Содержание]) like upper('%возврат%')
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1060
			and t2.[Сумма БУ] is not null 
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1200
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	--,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov --select * from #prov
	where 
	(
	upper(Содержание) like upper('% ДКП %')
	or
	upper(Содержание) like upper('% купли-продажи %')
	or
	upper(Содержание) like upper('%залог%')
	or
	upper(Содержание) like upper('% авто%')
	)
	group by
	СчетДтКод	
	,СчетКтКод
	--,[Статья ДДС]
) t2 on (t1.rowNum = 1200
			and t2.[Сумма БУ] is not null 
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1340
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov --select * from #prov
	where 
	upper(Клиент) = upper('СНГБ АО БАНК')
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1340
			and t2.[Сумма БУ] is not null 
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

----p1876
--merge into #rep t1
--using(
--	select
--	СчетДтКод	
--	,СчетКтКод
--	,[Статья ДДС]
--	,[Сумма БУ] = abs(sum([Сумма БУ]))
--	from #prov 
--	where 
--	upper([Клиент]) = upper('СОЛИД АО ИФК')
--	group by
--	СчетДтКод	
--	,СчетКтКод
--	,[Статья ДДС]
--) t2 on (t1.rowNum = 1876
--			and t2.[Сумма БУ] is not null 
--			and t1.DTAcc = t2.СчетДтКод
--			and t1.KTAcc = t2.СчетКтКод
--			)
--when matched
--then update
--set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1890
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov --select * from #prov
	where 
	(
		upper([Содержание]) like upper('%погашен%номинал%стоимост%')
		or
		upper([Содержание]) like upper('%част%номинальн%стоимос%Облигац%')
	)
	and
	upper([Клиент]) = upper('НКО АО НРД')
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1890
			and t2.[Сумма БУ] is not null 
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1892
merge into #rep t1
using(
	select
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
	,[Сумма БУ] = abs(sum([Сумма БУ]))
	from #prov --select * from #prov
	where 
	upper([Содержание]) like upper('%погашен%номинал%стоимост%')
	--and
	--upper([Клиент]) = upper('НКО АО НРД')
	group by
	СчетДтКод	
	,СчетКтКод
	,[Статья ДДС]
) t2 on (t1.rowNum = 1892
			and t2.[Сумма БУ] is not null 
			and t1.DTAcc = t2.СчетДтКод
			and t1.KTAcc = t2.СчетКтКод
			)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1970--1980--2000--2010
merge into #rep t1
using(
	select
	repmonth
	,rowNum = case
				when repmonth = dateadd(month,-1,@repmonth) and acc2order = '20501' then 1970
				when repmonth = dateadd(month,-1,@repmonth) and acc2order = '20601' then 1980
			
				when repmonth = @repmonth and acc2order = '20501' then 2000
				when repmonth = @repmonth and acc2order = '20601' then 2010
				else -1 end
	,acc2order
	,[Сумма БУ] = sum(restOUT_BU)
	from dwh2.finAnalytics.OSV_MONTHLY
	where repmonth between dateadd(month,-1,@repmonth) and @repmonth
	and acc2order in ('20501','20601')
	group by
	repmonth
	,acc2order
) t2 on (t1.rowNum = t2.rowNum and t2.[Сумма БУ] is not null)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;


--p1340
merge into #rep t1
using(
	select
	repmonth
	,rowNum = 1340
	,acc2order
	,[Сумма БУ] = sum(restIN_BU)
	
	from dwh2.finAnalytics.OSV_MONTHLY a
	where repmonth = @repmonth
	and acc2order in ('47423')
	and subconto1 = 'СНГБ АО БАНК'
	group by
	repmonth
	,acc2order
) t2 on (t1.rowNum = t2.rowNum and t2.[Сумма БУ] is not null)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;

--p1974,2004
merge into #rep t1
using(
	select
	repmonth
	,rowNum
	,[Сумма БУ] = sum([Сумма БУ])
	from(
	select
	repmonth
	,rowNum = case
				when repmonth = dateadd(month,-1,@repmonth) then 1974
				when repmonth = @repmonth then 2004
				else -1 end
	--,acc2order
	,[Сумма БУ] = restOUT_BU
	from dwh2.finAnalytics.OSV_MONTHLY a
	left join stg.[_1cUMFO].[Справочник_Контрагенты] b on a.subconto1UID = b.Ссылка
	left join stg.[_1cUMFO].[Справочник_Контрагенты] bUP on b.Родитель= bUP.Ссылка
	where repmonth between dateadd(month,-1,@repmonth) and @repmonth
	and acc2order in ('47423')
	--and upper(subconto1) in (upper('EcommPay'),upper('БИЛЛИНГОВЫЙ ЦЕНТР ЗАО'))
	and upper(bUP.Наименование) = upper('Платежные системы')
	--group by
	--repmonth
	--,subconto1
	) l1
	group by
	repmonth
	,rowNum
) t2 on (t1.rowNum = t2.rowNum and t2.[Сумма БУ] is not null)
when matched
then update
set t1.amount = abs(t2.[Сумма БУ]) * t1.aplicator;



/*Суммы по строкам*/
--p20
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum between 30 and 99--in (30,40,50,60,70,80,90)
) t2 on (t1.rowNum = 20 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount/* * t1.aplicator*/;

--p100
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum between 110 and 209--in (110,120,130,135,140,150,160,170,180,190,200)
) t2 on (t1.rowNum = 100 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount/* * t1.aplicator*/;

--p210
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum between 220 and 359--in (220,230,240,250,260,270,280,290,300,310,320,330,340,345,350)
) t2 on (t1.rowNum = 210 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount/* * t1.aplicator*/;

--p360
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum between 370 and 769
					--in (370,380,390,400,410,420,430,440,450,460,470,480,495,490,500,510,515,520,530,540,
					-- 550,560,570,580,585,590,592,594,600,610,613,616,620,630,640,650,660,670,680,690,700,710,720,
					-- 730,740,750,760)
) t2 on (t1.rowNum = 360 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount/* * t1.aplicator*/;

--p800
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum between 810 and 999--in (810,820,830,840,850,860,870,880,890,900,910,920,930,940,950,960,970,980,990)
) t2 on (t1.rowNum = 800 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;


--p1000
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum between 1010 and 1069--in (1010,1020,1030,1040,1050,1060)
) t2 on (t1.rowNum = 1000 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1110
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum between 1120 and 1299--in (1120,1130,1132,1134,1140,1150,1160,1165,1170,1180,1190,1200,1210,1250,1252,1260,1270,1280,1290)
) t2 on (t1.rowNum = 1110 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1300
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum between 1310 and 1459--in (1310,1312,1320,1330,1332,1340,1350,1360,1370,1380,1390,1400,1410,1411,1412,1413,1414,1415,1416,1420,1430,1440,1450)
) t2 on (t1.rowNum = 1300 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1460
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowName in ('1','2','3','4','7.1.','7.2.','8','9','7')
) t2 on (t1.rowNum = 1460 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1500
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum in (1510)
) t2 on (t1.rowNum = 1500 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1520
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum in (1530,1540)
) t2 on (t1.rowNum = 1520 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1670
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowName in ('11','12','13','14')
) t2 on (t1.rowNum = 1670 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1690
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum between 1700 and 1729--in (1700,1705,1710,1720)
) t2 on (t1.rowNum = 1690 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1730
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum between 1740 and 1789--in (1740,1750,1760,1770,1780)
) t2 on (t1.rowNum = 1730 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1790
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum between 1800 and 1809--in (1800,1802)
) t2 on (t1.rowNum = 1790 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1840
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum in (1850)
) t2 on (t1.rowNum = 1840 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1860
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum between 1870 and 1879--in (1870)
) t2 on (t1.rowNum = 1860 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1880
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum between 1890 and 1899--in (1890,1892)
) t2 on (t1.rowNum = 1880 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1900
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum in (1910)
) t2 on (t1.rowNum = 1900 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1930
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowName in ('27','28','32','33','34','35')
) t2 on (t1.rowNum = 1930 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1940
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowName in ('10','26','37')
) t2 on (t1.rowNum = 1940 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1960
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum between 1970 and 1989--in (1970,1972,1974,1980)
) t2 on (t1.rowNum = 1960 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p1990
merge into #rep t1
using(
	select 
	amount = sum(amount) 
	from #rep
	where rowNum between 2000 and 2019--in (2000,2002,2004,2010)
) t2 on (t1.rowNum = 1990 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

--p2020
merge into #rep t1
using(
	select 
	amount = round(sum(case when rowName = '41' then amount * -1 else amount end),0)
	from #rep
	where rowName in ('40','38','41')
) t2 on (t1.rowNum = 2020 and t2.amount is not null)
when matched
then update
set t1.amount = t2.amount /** t1.aplicator*/;

		delete from dwh2.finAnalytics.rep845 where repmonth = @repmonth

		insert into dwh2.finAnalytics.rep845
		select
		*
		from #rep
    
	declare @maxDateRest date = (select max(repmonth) from dwh2.finAnalytics.rep845)

	/*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID]= 50

	declare @repLink  nvarchar(max) = (select link from dwh2.[finAnalytics].[SYS_SPR_linkReport] where repName ='Отчет 845')
	
	DECLARE @msg_calcAll NVARCHAR(2048) = CONCAT (
				'Расчет данных для отчета ф845'
                ,char(10)
                ,char(13)
				,'за отчетный месяц: '
				,FORMAT( @REPMONTH, 'MMMM yyyy', 'ru-RU' )
				,char(10)
                ,char(13)
				,'Ссылка на отчет: '
				,@repLink
				)

	declare @emailList varchar(255)=''
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,31,32))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_calcAll
			,@body_format = 'TEXT'
			,@subject = @subject;

    --финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc


	end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры расчета даных для отчета 845 '
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
