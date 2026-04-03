-- =============================================
-- Author:		КУрдин С.В.
-- Create date: 2019-05-22
-- Description:	Для отчета "ПОСТУПЛЕНИЕ КОЛЛЕКТИНГ" Таблица "ПОСТУПЛЕНИЕ ПЛАТЕЖЕЙ" содержит информацию о суммах учтенных в счет погашения ОД, процентов и пеней
--	exec [etl].[base_etl_report_collecting_receipt_cmr]			
-- =============================================
CREATE PROCEDURE [etl].[base_etl_report_collecting_receipt_cmr]
	-- Add the parameters for the stored procedure here
--	@ForDate datetime =cast(getdate() as date)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		--24.03.2020
	SET DATEFIRST 1;

--	declare	@DateReport datetime2
--	set @DateReport=@ForDate

declare @DateStart datetime,
		@DateStart2 datetime,
		@DateStart2000 datetime,
		@DateStartCurr datetime,
		@DateStartCurr2000 datetime,
		@GetDate2000 datetime
set @DateStart=dateadd(MONTH,datediff(MONTH,0,dateadd(month,-1,Getdate())),0)
--dateadd(day,-datediff(day,cast('20170101' as datetime),getdate()),getdate())
--dateadd(month,datediff(month,0,GetDate()),-720);
--dateadd(day,datediff(day,0,GetDate()-2),0);
set	@DateStart2=dateadd(year,2000,@DateStart);
set @DateStart2000= dateadd(day,datediff(day,0,dateadd(year,2000,dateadd(day,-10,Getdate()))),0);
set @DateStartCurr=dateadd(day,-14,dateadd(day,datediff(day,0,Getdate()),0)); --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-43,Getdate())),0); --dateadd(day,-15,dateadd(day,datediff(day,0,Getdate()),0)); --
set @DateStartCurr2000=dateadd(day,-14,dateadd(day,datediff(day,0,dateadd(year,2000,Getdate())),0)); --dateadd(MONTH,datediff(MONTH,0,dateadd(month,-43,dateadd(year,2000,Getdate()))),0); --dateadd(day,-15,dateadd(day,datediff(day,0,dateadd(year,2000,Getdate())),0)); --
set @GetDate2000=dateadd(year,2000,getdate());

/*
if OBJECT_ID('[Reports].[dbo].[report_Collecting_receipt_cmr]') is not null
drop table [Reports].[dbo].[report_collecting_receipt_cmr];

create table [Reports].[dbo].[report_collecting_receipt_cmr]
(
[НаименованиеПараметра] nvarchar(255) null
,[Неделя] int  null
,[Параметр1] nvarchar(255) null
,[Параметр2] nvarchar(255) null
,[Параметр3] nvarchar(255) null
,[Параметр4] nvarchar(255) null
,[Параметр5] nvarchar(255) null
,[Параметр6] nvarchar(255) null
,[Параметр7] nvarchar(255) null

,[НаименованиеЛиста] nvarchar(255) null
,[Сумма] decimal(15,2) null
,[Год] int  null
,[Докредитование] nvarchar(255) null
,[Параметр8] nvarchar(255) null

,[Регион] nvarchar(255) null

,[Параметр9] nvarchar(255) null --,[ДопПараметр_1]
,[ДатаЧислом] int  null --Дата отчета
,[ПериодУчета] int null --

,[Точка] nvarchar(255) null
,[ПовторностьNew] nvarchar(255) null 
,[Срок] int null
,[РОРегион] nvarchar(255) null
,[Дивизион] nvarchar(255) null
,[Параметр10] nvarchar(255) null  -- Исполнитель
,[Параметр11] nvarchar(255) null --,[ДопПараметр_2]
,[Параметр12] nvarchar(255) null  -- ВремяРассмотрения
,[КредитныйПродукт] nvarchar(255)  null

,[Параметр13] nvarchar(255) null  -- Отказ причина
,[Параметр14] nvarchar(255) null  -- Отказ причина по коду
,[Параметр15] nvarchar(255) null  -- Отказ по факторам

,[ПериодичностьОтчета] nvarchar(255) null

,[Дата] datetime null 
,[Колво] decimal(15,2)  null
,[ДатаОперации] datetime null 

,[ДеньНедели] int  null
,[ПервичнаяСумма] decimal(15,2)  null
);
*/
--DWH-1764
TRUNCATE TABLE [Reports].[dbo].[report_collecting_receipt_cmr]

--with TempTable_CollectingPayIn as
--(

drop table if exists #TempTable_CollectingPayIn
SELECT [ПериодУчетаЧислом]
      ,[ПериодУчета]
      ,cast([ДатаОперации] as smalldatetime) as [ДатаОперацииИсх]	--[ДатаОперации] as [ДатаОперацииИсх]	--
      --,[Контрагент]
      ,[Договор] as [ДоговорСсылка]
      ,[ДоговорНомер]
      ,sum([ОДНачислено]) as [ОДНачислено] ,sum([ОДОплачено]) as [ОДОплачено]
      ,sum([ПроцентыНачислено]) as [ПроцНачислено] ,sum([ПроцентыОплачено]) as [ПроцОплачено]
      ,sum([ПениНачислено]) as [ПениНачислено] ,sum([ПениОплачено]) as [ПениОплачено]
      ,sum([ГосПошлинаНачислено]) as [ГосПошлинаНачислено] ,sum([ГосПошлинаОплачено]) as [ГосПошлинаОплачено]
      ,sum([ПереплатаНачислено]) as [ПереплатаНачислено] ,sum([ПереплатаОплачено]) as [ПереплатаОплачено]
      ,sum([ПроцентыГрейсПериодаНачислено]) as [ПроцГрейсПериодаНачислено] ,sum([ПроцентыГрейсПериодаОплачено]) as [ПроцГрейсПериодаОплачено]
      ,sum([ПениГрейсПериодаНачислено]) as [ПениГрейсПериодаНачислено] ,sum([ПениГрейсПериодаОплачено]) as [ПениГрейсПериодаОплачено]
      ,[ИсточникДанных]
      ,[КолвоПолнДнПросрВчера]
	  ,case
		when [КолвоПолнДнПросрВчера]=0 or [КолвоПолнДнПросрВчера] is null  then N'0'
		else
			case
				when [КолвоПолнДнПросрВчера]>0 and [КолвоПолнДнПросрВчера]<4 then N'от 0 до 3 дней'
				when [КолвоПолнДнПросрВчера]>3 and [КолвоПолнДнПросрВчера]<31 then N'от 3 до 30 дней'
				when [КолвоПолнДнПросрВчера]>30 and [КолвоПолнДнПросрВчера]<61 then N'от 30 до 60 дней'
				when [КолвоПолнДнПросрВчера]>60 and [КолвоПолнДнПросрВчера]<91 then N'от 60 до 90 дней'
				when [КолвоПолнДнПросрВчера]>90 and [КолвоПолнДнПросрВчера]<121 then N'от 90 до 120 дней'
				when [КолвоПолнДнПросрВчера]>120 and [КолвоПолнДнПросрВчера]<151 then N'от 120 до 150 дней'
				when [КолвоПолнДнПросрВчера]>150 and [КолвоПолнДнПросрВчера]<181 then N'от 150 до 180 дней'
				when [КолвоПолнДнПросрВчера]>180 and [КолвоПолнДнПросрВчера]<211 then N'от 180 до 210 дней'
				when [КолвоПолнДнПросрВчера]>210 and [КолвоПолнДнПросрВчера]<241 then N'от 210 до 240 дней'
				when [КолвоПолнДнПросрВчера]>240 and [КолвоПолнДнПросрВчера]<271 then N'от 240 до 270 дней'
				when [КолвоПолнДнПросрВчера]>270 and [КолвоПолнДнПросрВчера]<301 then N'от 270 до 300 дней'
				when [КолвоПолнДнПросрВчера]>300 and [КолвоПолнДнПросрВчера]<331 then N'от 300 до 330 дней'
				when [КолвоПолнДнПросрВчера]>330 and [КолвоПолнДнПросрВчера]<361 then N'от 330 до 360 дней'
				when [КолвоПолнДнПросрВчера]>360 then N'от 360 дней'
			end
		end as [НаименованиеПараметра]
into #TempTable_CollectingPayIn
  FROM [dwh_new].[dbo].[mt_payments_receipt_cmr_umfo]
  where [ДатаОперации] >= dateadd(year,-1,dateadd(year,datediff(year,0,Getdate()),0)) /*dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0)*/ 
		and [ДатаОперации] < dateadd(day,datediff(day,0,Getdate()),0) --and [ПериодУчета]>=@DateStart 
		and [ИсточникДанных] = 'ЦМР'
  group by [ПериодУчетаЧислом] ,[ПериодУчета] ,[ДатаОперации] ,[Договор] ,[ДоговорНомер]
			,[ИсточникДанных] ,[КолвоПолнДнПросрВчера]

union all

SELECT [ПериодУчетаЧислом]
      ,[ПериодУчета]
      ,cast([ДатаОперации] as smalldatetime) as [ДатаОперацииИсх]	--[ДатаОперации] as [ДатаОперацииИсх]	--
      --,[Контрагент]
      ,[Договор] as [ДоговорСсылка]
      ,[ДоговорНомер]
      ,sum([ОДНачислено]) as [ОДНачислено] ,sum([ОДОплачено]) as [ОДОплачено]
      ,sum([ПроцентыНачислено]) as [ПроцНачислено] ,sum([ПроцентыОплачено]) as [ПроцОплачено]
      ,sum([ПениНачислено]) as [ПениНачислено] ,sum([ПениОплачено]) as [ПениОплачено]
      ,sum([ГосПошлинаНачислено]) as [ГосПошлинаНачислено] ,sum([ГосПошлинаОплачено]) as [ГосПошлинаОплачено]
      ,sum([ПереплатаНачислено]) as [ПереплатаНачислено] ,sum([ПереплатаОплачено]) as [ПереплатаОплачено]
      ,sum([ПроцентыГрейсПериодаНачислено]) as [ПроцГрейсПериодаНачислено] ,sum([ПроцентыГрейсПериодаОплачено]) as [ПроцГрейсПериодаОплачено]
      ,sum([ПениГрейсПериодаНачислено]) as [ПениГрейсПериодаНачислено] ,sum([ПениГрейсПериодаОплачено]) as [ПениГрейсПериодаОплачено]
      ,[ИсточникДанных]
      ,[КолвоПолнДнПросрВчера]
	  ,case
		when [КолвоПолнДнПросрВчера]=0 or [КолвоПолнДнПросрВчера] is null  then N'0'
		else
			case
				when [КолвоПолнДнПросрВчера]>0 and [КолвоПолнДнПросрВчера]<4 then N'от 0 до 3 дней'
				when [КолвоПолнДнПросрВчера]>3 and [КолвоПолнДнПросрВчера]<31 then N'от 3 до 30 дней'
				when [КолвоПолнДнПросрВчера]>30 and [КолвоПолнДнПросрВчера]<61 then N'от 30 до 60 дней'
				when [КолвоПолнДнПросрВчера]>60 and [КолвоПолнДнПросрВчера]<91 then N'от 60 до 90 дней'
				when [КолвоПолнДнПросрВчера]>90 and [КолвоПолнДнПросрВчера]<121 then N'от 90 до 120 дней'
				when [КолвоПолнДнПросрВчера]>120 and [КолвоПолнДнПросрВчера]<151 then N'от 120 до 150 дней'
				when [КолвоПолнДнПросрВчера]>150 and [КолвоПолнДнПросрВчера]<181 then N'от 150 до 180 дней'
				when [КолвоПолнДнПросрВчера]>180 and [КолвоПолнДнПросрВчера]<211 then N'от 180 до 210 дней'
				when [КолвоПолнДнПросрВчера]>210 and [КолвоПолнДнПросрВчера]<241 then N'от 210 до 240 дней'
				when [КолвоПолнДнПросрВчера]>240 and [КолвоПолнДнПросрВчера]<271 then N'от 240 до 270 дней'
				when [КолвоПолнДнПросрВчера]>270 and [КолвоПолнДнПросрВчера]<301 then N'от 270 до 300 дней'
				when [КолвоПолнДнПросрВчера]>300 and [КолвоПолнДнПросрВчера]<331 then N'от 300 до 330 дней'
				when [КолвоПолнДнПросрВчера]>330 and [КолвоПолнДнПросрВчера]<361 then N'от 330 до 360 дней'
				when [КолвоПолнДнПросрВчера]>360 then N'от 360 дней'
			end
		end as [НаименованиеПараметра]

from [dwh_new].[dbo].[mt_payments_receipt_cmr_umfo]
  where [ДатаОперации] >= '2020-05-01' /*dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0)*/ 
		and [ДатаОперации] < dateadd(day,datediff(day,0,Getdate()),0) --and [ПериодУчета]>=@DateStart 
		and [ИсточникДанных] = 'УМФО'
  group by [ПериодУчетаЧислом] ,[ПериодУчета] ,[ДатаОперации] ,[Договор] ,[ДоговорНомер]
			,[ИсточникДанных] ,[КолвоПолнДнПросрВчера]

			
--)
-- select * from #TempTable_CollectingPayIn where cast([ДатаОперацииИсх] as date) >= '20200201' order by [ДатаОперацииИсх]
-- select * from [dwh_new].[dbo].[mt_payments_receipt_cmr_umfo] where cast([ДатаОперации] as date) >= '20200201' order by [ДатаОперации]

-- select *
-- from [dwh_new].[dbo].[mt_payments_receipt_cmr_umfo]
--  where [ДатаОперации] >= dateadd(year,-1,dateadd(year,datediff(year,0,Getdate()),0)) /*dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0)*/ 
--		and [ДатаОперации] < dateadd(day,datediff(day,0,Getdate()),0) 
--		and [ИсточникДанных]<>N'ЦМР'
--		and [ДоговорНомер] = '19102500301001'
--order by 3 desc


--, PayIn_Res as
--(
drop table if exists #PayIn_Res
select  [ДатаОперацииИсх] ,[ПериодУчетаЧислом] ,[ПериодУчета] ,[ДоговорСсылка] ,[ДоговорНомер] ,[НаименованиеПараметра] 
		,N'Платежи по ОД' as [НаименованиеЛиста]
		,[ОДОплачено] as [Всего]
into #PayIn_Res
from #TempTable_CollectingPayIn where [ОДОплачено]>0

union all

select  [ДатаОперацииИсх] ,[ПериодУчетаЧислом] ,[ПериодУчета] ,[ДоговорСсылка] ,[ДоговорНомер] ,[НаименованиеПараметра]	
		,N'Платежи по процентам' as [НаименованиеЛиста]
		,[ПроцОплачено] as [Всего]
from #TempTable_CollectingPayIn where [ПроцОплачено]>0

union all

select  [ДатаОперацииИсх] ,[ПериодУчетаЧислом] ,[ПериодУчета] ,[ДоговорСсылка] ,[ДоговорНомер] ,[НаименованиеПараметра]
		,N'Платежи по пеням' as [НаименованиеЛиста]
		,[ПениОплачено] as [Всего]
from #TempTable_CollectingPayIn where [ПениОплачено]>0

union all

select  [ДатаОперацииИсх] ,[ПериодУчетаЧислом] ,[ПериодУчета] ,[ДоговорСсылка] ,[ДоговорНомер] ,[НаименованиеПараметра]
		,N'Госпошлина' as [НаименованиеЛиста]
		,[ГосПошлинаОплачено] as [Всего]
from #TempTable_CollectingPayIn where [ГосПошлинаОплачено]>0
--)
----select * from #PayIn_Res

--,	PaymentReceiptCMR_1c as
--(
drop table if exists #PaymentReceiptCMR_1c
select 
 pir.[ПериодУчетаЧислом]
 ,pir.[ПериодУчета]
 ,pir.[ДатаОперацииИсх] as [ДатаОперации]

 , pir.[ДоговорСсылка] as [Ссылка]
 ,pir.[ДоговорНомер]
	
 ,null as [ДоговорНомерМФО]
 ,null as [Договор_MFO]

,dd.[Фамилия]
,dd.[Имя]
,dd.[Отчество]
,Null  as [ДатаРождения]--,dateadd(year,-2000,cast(dd.[ДатаРождения] as date)) as [ДатаРождения]


,null as [ДатаВыдачиДоговора]
,null as [ДатаОкончанияДоговора]

,dd.[ПервичнаяСумма] as [ПервичнаяСумма]
,dd.[СуммаДоговора] as [СуммаДоговора]
,dd.[ДоговорСуммаДопПродуктов] as [СуммаДопПродуктов]
,dd.[ДоговорСуммаБезДопУслуг] as [СуммаБезДопУслуг_MFO]
,pir.[Всего] as [СуммаПлатежа]

,1 as [Колво]

,dd.[ДоговорСрок] as [Срок]
,dd.[ПроцентнаяСтавка] as [ПроцентнаяСтавка]
,dd.[КредитныйПродукт] as [КредитныйПродукт]

,null as [Докредитование]
,null as [Повторность]
,null as [ДатаПогашПервДог_MFO]
,null as [ПовторностьNew]

,null as [ТочкаКод]
,null as [Точка]
,dd.[ЗаявкаВыезднойМенеджер] as [ВыезднойМенеджер]
,null as [Регион]
,null as [Регион2]
,null as [РОРегион]
,null as [Дивизион]
,null as [Агент]
,null as [АгентМФО]

 ,null as [НомерГрафика_MFO] 

 ,null as [ДатаНачала]
 ,null as [ДатаДоговора]

,datepart(dw,pir.[ДатаОперацииИсх]) as [ДеньНедели]
,datepart(wk,pir.[ДатаОперацииИсх]) as [Неделя]
,datepart(dd,pir.[ДатаОперацииИсх]) as [ДеньМесяца]
,datepart(mm,pir.[ДатаОперацииИсх]) as [Месяц]
,datepart(yyyy,pir.[ДатаОперацииИсх]) as [Год]

 ,pir.[НаименованиеЛиста] as [НаименованиеЛиста]
 ,pir.[НаименованиеПараметра] as [НаименованиеПараметра]

 ,N'Ежедневный' as [ПериодичностьОтчета]

 ,case
	when dd.[СуммаДоговора]<=150000 then N'до 150'
	when dd.[СуммаДоговора]>150000 and dd.[СуммаДоговора]<=700000 then N'151-700'
	when dd.[СуммаДоговора]>700000 and dd.[СуммаДоговора]<=1000000 then N'701-1000'
	when dd.[СуммаДоговора]>1000000 then N'более 1000'
	else N'Прочее'
end as [Когорта]

into #PaymentReceiptCMR_1c

from #PayIn_Res pir
left join [dwh_new].[dbo].[mt_requests_loans_mfo] dd
on pir.[ДоговорСсылка]=dd.[ДоговорСсылка] 
--)

-- select * from #PaymentReceiptCMR_1c where cast([ДатаОперации] as date) >= '20200201' and cast([ДатаОперации] as date) <= '20200229'  order by 3 asc


 


--begin tran

insert into [Reports].[dbo].[report_collecting_receipt_cmr] ([НаименованиеПараметра] ,[Неделя] ,[Параметр1] ,[Параметр2] ,[Параметр3] ,[Параметр4]
																				,[Параметр5] ,[Параметр6] ,[Параметр7] ,[НаименованиеЛиста] ,[Сумма] 
																				,[Год] ,[Докредитование] ,[Параметр8] ,[Регион] ,[Параметр9] 
																				,[ДатаЧислом] ,[ПериодУчета] ,[Точка] ,[ПовторностьNew] ,[Срок] 
																				,[РОРегион] ,[Дивизион] ,[Параметр10] ,[Параметр11] ,[Параметр12] 
																				,[КредитныйПродукт]	,[Параметр13] ,[Параметр14] ,[Параметр15] ,[ПериодичностьОтчета] 
																				,[Дата] ,[Колво] ,[ДатаОперации] ,[ДеньНедели] ,[ПервичнаяСумма])

select [НаименованиеПараметра] ,[Неделя] 
		,null as [Параметр1] ,null as [Параметр2] ,null as [Параметр3]	,null as [Параметр4] ,null as [Параметр5] ,null as [Параметр6] ,null as [Параметр7] 
		,[НаименованиеЛиста] ,[СуммаПлатежа] as [Сумма] ,[Год] ,[Докредитование] ,null as [Параметр8] ,null as [Регион] 
		,datediff(day,0,dateadd(day,datediff(day,0,[ДатаОперации]),0))+2 as [Параметр9]
		,datediff(day,0,dateadd(day,datediff(day,0,Getdate()),-1))+2 as [ДатаЧислом] 
		,datediff(day,0,dateadd(day,datediff(day,0,pr.[ПериодУчета]),0))+2 as [ПериодУчета] 
		,[Точка] ,null as [ПовторностьNew] ,[Срок] ,null as [РОРегион] ,[Дивизион] ,null as [Параметр10] 
		,[ВыезднойМенеджер] as [Параметр11] ,null as [Параметр12]
		,[КредитныйПродукт]	
		,null as [Параметр13] ,null as [Параметр14] ,null as [Параметр15] ,[ПериодичностьОтчета] 
		,null as [Дата] ,[Колво] ,[ДатаОперации] ,[ДеньНедели]	,[ПервичнаяСумма]
from #PaymentReceiptCMR_1c pr

--commit tran


--drop table if exists #t0
--if OBJECT_ID('tempdb.dbo.#t0') is not null drop table tempdb.dbo.#t0;

--select * into #t0 from PaymentReceiptCMR_1c; 
begin tran

delete from [dwh_new].[dbo].[mt_reciept_period_dpd] 
where [Indicator] in (N'Платежи по ОД' ,N'Платежи по процентам' ,N'Платежи по пеням') and [cdate] >= dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0) and [Факт/План] = N'Факт'

insert into [dwh_new].[dbo].[mt_reciept_period_dpd] ([cdate] ,[Indicator] ,[Факт/План] ,[Value] ,[dpd])
select [ДатаОперации] as [cdate] ,[НаименованиеЛиста] as [Indicator] ,N'Факт' as [Факт/План] ,sum([СуммаПлатежа]) as [Value]

	   ,case 
			when [НаименованиеПараметра] = N'0' then N'0'
			when [НаименованиеПараметра] = N'от 0 до 3 дней' then N'1-3'
			when [НаименованиеПараметра] = N'от 3 до 30 дней' then N'4-30'
			when [НаименованиеПараметра] = N'от 30 до 60 дней' then N'31-60'
			when [НаименованиеПараметра] = N'от 60 до 90 дней' then N'61-90'
			when [НаименованиеПараметра] = N'от 90 до 120 дней' then N'91-120'
			when [НаименованиеПараметра] = N'от 120 до 150 дней' then N'121-150'
			when [НаименованиеПараметра] = N'от 150 до 180 дней' then N'151-180'
			when [НаименованиеПараметра] = N'от 180 до 210 дней' then N'181-210'
			when [НаименованиеПараметра] = N'от 210 до 240 дней' then N'211-240'
			when [НаименованиеПараметра] = N'от 240 до 270 дней' then N'241-270'
			when [НаименованиеПараметра] = N'от 270 до 300 дней' then N'271-300'
			when [НаименованиеПараметра] = N'от 300 до 330 дней' then N'301-330'
			when [НаименованиеПараметра] = N'от 330 до 360 дней' then N'331-360'
			when [НаименованиеПараметра] = N'от 360 дней' then N'360+'
		end as [dpd]

from #PaymentReceiptCMR_1c
where [НаименованиеЛиста] in (N'Платежи по ОД' ,N'Платежи по процентам' ,N'Платежи по пеням') and [ДатаОперации] >= dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0)
group by [ДатаОперации] ,[НаименованиеЛиста] ,[НаименованиеПараметра]

commit tran

drop table if exists #calendar
select * 
into #calendar
from dwh_new.dbo.calendar
where created between (select min([ДатаОперации]) from #PaymentReceiptCMR_1c) and getdate()


drop table if exists #PaymentReceiptCMR_1c_2
select * 
into #PaymentReceiptCMR_1c_2
from (
select distinct
		e.* ,p.* 
-- select *
from #PaymentReceiptCMR_1c p
left join dwh_new.dbo.loans_early_repayment_mfo e on e.external_id = p.[ДоговорНомер] and e.dt_lastpayment = cast(p.[ДатаОперации] as date)
) td
where not td.external_id is null

-- select */*distinct external_id*/ from dwh_new.dbo.loans_early_repayment_mfo where ContractEndDate >= '20200201' and ContractEndDate <= '20200229' order by 1 asc
-- select */*distinct external_id*/ from #PaymentReceiptCMR_1c_2 where dt_lastpayment = '20200424' order by 1 desc
-- select * from #PaymentReceiptCMR_1c_2 where [ДатаОперации] >= '20200201' and [ДатаОперации] <= '20200229' order by 3


begin tran

delete from [dwh_new].[dbo].[mt_reciept_period_dpd_early_payments] 
where [Indicator] in (N'Платежи по ОД' ,N'Платежи по процентам' ,N'Платежи по пеням') 
		and [cdate] >= dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0) 
		and [Факт/План] = N'Факт'

insert into [dwh_new].[dbo].[mt_reciept_period_dpd_early_payments] ([cdate] ,[Indicator] ,[Факт/План] ,[Value] ,Qty ,[dpd])
select [ДатаОперации] as [cdate] ,[НаименованиеЛиста] as [Indicator] ,N'Факт' as [Факт/План] ,sum([СуммаПлатежа]) as [Value] ,count(external_id) Qty

	   ,case 
			when [НаименованиеПараметра] = N'0' then N'0'
			when [НаименованиеПараметра] = N'от 0 до 3 дней' then N'1-3'
			when [НаименованиеПараметра] = N'от 3 до 30 дней' then N'4-30'
			when [НаименованиеПараметра] = N'от 30 до 60 дней' then N'31-60'
			when [НаименованиеПараметра] = N'от 60 до 90 дней' then N'61-90'
			when [НаименованиеПараметра] = N'от 90 до 120 дней' then N'91-120'
			when [НаименованиеПараметра] = N'от 120 до 150 дней' then N'121-150'
			when [НаименованиеПараметра] = N'от 150 до 180 дней' then N'151-180'
			when [НаименованиеПараметра] = N'от 180 до 210 дней' then N'181-210'
			when [НаименованиеПараметра] = N'от 210 до 240 дней' then N'211-240'
			when [НаименованиеПараметра] = N'от 240 до 270 дней' then N'241-270'
			when [НаименованиеПараметра] = N'от 270 до 300 дней' then N'271-300'
			when [НаименованиеПараметра] = N'от 300 до 330 дней' then N'301-330'
			when [НаименованиеПараметра] = N'от 330 до 360 дней' then N'331-360'
			when [НаименованиеПараметра] = N'от 360 дней' then N'360+'
		end as [dpd]

--into [dwh_new].[dbo].[mt_reciept_period_dpd_early_payments] 
from #PaymentReceiptCMR_1c_2		--#PaymentReceiptCMR_1c --#PaymentReceiptCMR_1c_2
where [НаименованиеЛиста] in (N'Платежи по ОД' ,N'Платежи по процентам' ,N'Платежи по пеням') and [ДатаОперации] >= dateadd(month,datediff(month,0,dateadd(month,-1,Getdate())),0)
		and [ДоговорНомер] in (select external_id from [dwh_new].[dbo].[loans_early_repayment_mfo]) 
group by [ДатаОперации] ,[НаименованиеЛиста] ,[НаименованиеПараметра]

commit tran




END

-- select * from [dwh_new].[dbo].[mt_reciept_period_dpd_early_payments] order by 1 desc
-- select * from [dwh_new].[dbo].[mt_reciept_period_dpd] order by 1 desc

--alter table [dwh_new].[dbo].[mt_reciept_period_dpd_early_payments] add Qty int null 
