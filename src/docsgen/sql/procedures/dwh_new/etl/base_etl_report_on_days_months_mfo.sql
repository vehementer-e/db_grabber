
-- =============================================
-- Author:		Курдин С.В.
-- Create date: 2019-05-20
-- Description:	Создание основной таблицы для отчета для ЗАЯВОК и ЗАЙМОВ из МФО
-- exec [etl].[base_etl_report_on_days_months_mfo]
-- =============================================

CREATE PROCEDURE [etl].[base_etl_report_on_days_months_mfo]
	-- Add the parameters for the stored procedure here

AS
BEGIN  --auxtab_RequestMFO_1c

	SET NOCOUNT ON;

	--24.03.2020
	SET DATEFIRST 1;

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
if OBJECT_ID('[Reports].[dbo].[report_on_days_months_mfo]') is not null
drop table [Reports].[dbo].[report_on_days_months_mfo]

-- Создание вспомогательной таблицы "Комментарии к заявке"
create table [Reports].[dbo].[report_on_days_months_mfo]
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
,[Год] int null
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
,[СуммаДопПродуктов] decimal(15,2)  null 
,[КолвоДопПродуктов] decimal(15,2)  null 
);
*/
--DWH-1764
TRUNCATE TABLE [Reports].[dbo].[report_on_days_months_mfo]

--with rl as	--request (заявки)
--(
drop table if exists #rl
select [ЗаявкаНаименованиеПараметра] as [НаименованиеПараметра] ,datepart(wk,[ЗаявкаДатаОперации]) as [Неделя] 
	  ,null as [Параметр1]	,null as [Параметр2] ,null as [Параметр3]	,null as [Параметр4] ,null as [Параметр5] ,null as [Параметр6] ,null as [Параметр7] 
	  ,N'ИТОГ_2_ЗАЯВКИ_по_каналам' as [НаименованиеЛиста] ,[СуммаЗаявки] as [Сумма] ,datepart(yyyy,[ЗаявкаДатаОперации]) as [Год] 
	  ,[Докредитование] ,null as [Параметр8] ,[ЗаявкаРегион] as [Регион] ,null as [Параметр9]
	  ,datediff(day,0,dateadd(day,datediff(day,0,Getdate()),-1))+2 as [ДатаЧислом] 
	  ,datediff(day,0,dateadd(day,datediff(day,0,[ЗаявкаПериодУчета]),0))+2 as [ПериодУчета]
	  ,[ЗаявкаТочка] as [Точка] ,[ПовторностьNew] ,[ЗаявкаСрок] as [Срок] ,[ЗаявкаРОРегион] as [РОРегион] ,null as [Дивизион] ,null as [Параметр10]
	  ,[ЗаявкаВыезднойМенеджер] as [ВыезднойМенеджер] ,null as [Параметр11] ,null as [Параметр12]
	  ,[КредитныйПродукт]
	  ,null as [Параметр13] ,null as [Параметр14] ,null as [Параметр15] ,null as [ПериодичностьОтчета] 
	  ,null as [Дата] 
	  ,[Колво] ,dateadd(day,datediff(day,0,[ЗаявкаДатаОперации]),0) as [ДатаОперации] 
	  ,datepart(dw,[ЗаявкаДатаОперации]) as [ДеньНедели]	
	  ,[ПервичнаяСумма] ,[СуммаДопПродуктовЗаявка] as [СуммаДопПродуктов] ,[КолвоДопПродуктовЗаявка] as [КолвоДопПродуктов]
into #rl	   
from [dwh_new].[dbo].[mt_requests_loans_mfo]
where [ЗаявкаДатаОперации] between @DateStart and dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0)) -- между началом месяца предыдущего дня и концом предыдущего дня
	  and [ЕстьОсновнаяЗаявка] is null and [ЗаявкаПризнакАннулирования]=N''

union all

select [ЗаявкаНаименованиеПараметра] as [НаименованиеПараметра] ,datepart(wk,[ДатаВыдачиДоговора]) as [Неделя] 
	  ,null as [Параметр1]	,null as [Параметр2] ,null as [Параметр3]	,null as [Параметр4] ,null as [Параметр5] ,null as [Параметр6] ,null as [Параметр7] 
	  ,N'ИТОГ_2_ЗАЙМЫ_по_каналам' as [НаименованиеЛиста] ,[СуммаДоговора] as [Сумма] ,datepart(yyyy,[ДатаВыдачиДоговора]) as [Год] 
	  ,[Докредитование] ,null as [Параметр8] ,[ДоговорРегион] as [Регион] ,null as [Параметр9]
	  ,datediff(day,0,dateadd(day,datediff(day,0,Getdate()),-1))+2 as [ДатаЧислом] 
	  ,datediff(day,0,dateadd(day,datediff(day,0,[ДатаВыдачиДоговора]),0))+2 as [ПериодУчета]
	  ,[ДоговорТочка] as [Точка] ,[ПовторностьNew] ,[ДоговорСрок] as [Срок] ,[ДоговорРОРегион] as [РОРегион] ,null as [Дивизион] ,null as [Параметр10]
	  ,[ДоговорВыезднойМенеджер] as [ВыезднойМенеджер] ,null as [Параметр11] ,null as [Параметр12]
	  ,[ДоговорКредитныйПродукт]
	  ,null as [Параметр13] ,null as [Параметр14] ,null as [Параметр15] ,null as [ПериодичностьОтчета] 
	  ,null as [Дата] 
	  ,[Колво] ,dateadd(day,datediff(day,0,[ДатаВыдачиДоговора]),0) as [ДатаОперации] 
	  ,datepart(dw,[ДатаВыдачиДоговора]) as [ДеньНедели]	
	  ,[ПервичнаяСумма] ,[ДоговорСуммаДопПродуктов] as [СуммаДопПродуктов] ,[ДоговорКолвоДопПродуктов] as [КолвоДопПродуктов] --,[ДоговорТекСтатусМФО] 

from [dwh_new].[dbo].[mt_requests_loans_mfo]
where [ДатаВыдачиДоговора] >= @DateStart /*and dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0)) */
		and [ДатаВыдачиДоговора]< dateadd(day,datediff(day,0,Getdate()),0) -- между началом месяца предыдущего дня и концом предыдущего дня
	  and not [ДатаВыдачиДоговора] is null --and [ЗаявкаПризнакАннулирования]=N''
--)

--select * from [dwh_new].[dbo].[mt_requests_loans_mfo] where dateadd(month,datediff(month,0,[ДатаВыдачиДоговора]),0) = '2020-05-01' and [ЗаявкаПризнакАннулирования]=N''
--select * from #rl where [НаименованиеЛиста] = N'ИТОГ_2_ЗАЙМЫ_по_каналам' and dateadd(month,datediff(month,0,[ДатаОперации]),0) = '2020-05-01'


insert into [Reports].[dbo].[report_on_days_months_mfo]([НаименованиеПараметра] ,[Неделя] 
													,[Параметр1] ,[Параметр2] ,[Параметр3] ,[Параметр4]
													,[Параметр5] ,[Параметр6] ,[Параметр7] ,[НаименованиеЛиста] ,[Сумма] 
													,[Год] ,[Докредитование] ,[Параметр8] ,[Регион] ,[Параметр9] 
													,[ДатаЧислом] ,[ПериодУчета] ,[Точка] ,[ПовторностьNew] ,[Срок] 
													,[РОРегион] ,[Дивизион] ,[Параметр10] ,[Параметр11] ,[Параметр12] 
													,[КредитныйПродукт]	,[Параметр13] ,[Параметр14] ,[Параметр15] ,[ПериодичностьОтчета] 
													,[Дата] ,[Колво] ,[ДатаОперации] ,[ДеньНедели] ,[ПервичнаяСумма]
													,[СуммаДопПродуктов] ,[КолвоДопПродуктов])

    -- Insert statements for procedure here
select [НаименованиеПараметра] ,[Неделя] ,[Параметр1]	,[Параметр2] ,[Параметр3]	,[Параметр4] ,[Параметр5] ,[Параметр6] ,[Параметр7] ,[НаименованиеЛиста] 
		,sum([Сумма]) as [Сумма] 
		,[Год] ,[Докредитование] ,[Параметр8] ,[Регион] ,[Параметр9] ,[ДатаЧислом] ,[ПериодУчета] ,[Точка] ,[ПовторностьNew] ,[Срок] ,[РОРегион] ,[Дивизион] 
		,[Параметр10] ,[Параметр11] ,[Параметр12] ,[КредитныйПродукт] ,[Параметр13] ,[Параметр14] ,[Параметр15] ,[ПериодичностьОтчета] ,[Дата] 
		,sum([Колво]) as [Колво] 
		,[ДатаОперации] ,[ДеньНедели]	
		,sum([ПервичнаяСумма]) as [ПервичнаяСумма] ,sum([СуммаДопПродуктов]) as [СуммаДопПродуктов] ,sum([КолвоДопПродуктов]) as [КолвоДопПродуктов]

from #rl
group by [НаименованиеПараметра] ,[Неделя] ,[Параметр1]	,[Параметр2] ,[Параметр3]	,[Параметр4] ,[Параметр5] ,[Параметр6] ,[Параметр7] ,[НаименованиеЛиста] 
		,[Год] ,[Докредитование] ,[Параметр8] ,[Регион] ,[Параметр9] ,[ДатаЧислом] ,[ПериодУчета] ,[Точка] ,[ПовторностьNew] ,[Срок] ,[РОРегион] ,[Дивизион] 
		,[Параметр10] ,[Параметр11] ,[Параметр12] ,[КредитныйПродукт] ,[Параметр13] ,[Параметр14] ,[Параметр15] ,[ПериодичностьОтчета] ,[Дата] 
		,[ДатаОперации] ,[ДеньНедели]

--union all

--select [НаименованиеПараметра_MFO] ,[Неделя_MFO] 
--		,null as [Параметр1]	,null as [Параметр2] ,null as [Параметр3]	,null as [Параметр4] ,null as [Параметр5] ,null as [Параметр6] ,null as [Параметр7] 
--		,[НаименованиеЛиста_MFO] ,[СуммаДоговора_MFO] as [Сумма] ,[Год_MFO] ,[Докредитование_MFO] ,null as [Параметр8] ,[Регион_MFO] ,null as [Параметр9]
--		,datediff(day,0,dateadd(day,datediff(day,0,Getdate()),-1))+2 as [ДатаЧислом] 
--		,datediff(day,0,dateadd(day,datediff(day,0,[ПериодУчета_MFO]),0))+2 as [ПериодУчета] 
--		,[Точка_MFO] ,[ПовторностьNew_MFO] ,[Срок_MFO] ,[РОРегион_MFO] ,[Дивизион_MFO] ,null as [Параметр10] 
--		,[ВыезднойМенеджер_MFO] as [Параметр11] ,null as [Параметр12]
--		,[КредитныйПродукт_MFO]	
--		,null as [Параметр13] ,null as [Параметр14] ,null as [Параметр15] ,[ПериодичностьОтчета_MFO] 
--		,null as [Дата] ,[Колво_MFO] ,[ДатаОперации_MFO] ,[ДеньНедели_MFO]	,[ПервичнаяСумма_MFO]
--		,[СуммаДопПродуктов_MFO] as [СуммаДопПродуктов] ,[КолвоДопПродуктов_MFO] as  [КолвоДопПродуктов]

--from [dwh_new_Kurdin_S_V].[dbo].[auxtab_AgreementMFO_1c]
--where not [ДатаВыдачиДоговора_MFO] is null and [ПериодУчета_MFO]>=dateadd(month,-1,dateadd(MONTH,datediff(MONTH,0,Getdate()),0))
--		and [ДатаОперации_MFO]<dateadd(day,datediff(day,0,Getdate()),0)

--------------------------------------------------------
------------ для отчета по новой схеме с 2019-12-16


--drop table [dwh_new].[dbo].[mt_report_loans_on_days]
delete from [dwh_new].[dbo].[mt_report_loans_on_days] 
where [Indicator] in (N'Займы шт День' ,N'Займы руб День') --and [cdate] between cast(@DateStart as date) and cast(dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0)) as date)
	and [Факт/План] = N'Факт'

insert into [dwh_new].[dbo].[mt_report_loans_on_days] ([cdate] ,[Indicator] ,[Факт/План] ,[Value] ,[dpd] ,[Term])

select cast([ДатаОперации] as date) as [cdate] ,N'Займы руб День' as [Indicator] ,N'Факт' as [Факт/План] ,sum([Сумма]) as [Value] ,null as [dpd] ,[Срок] as [Term]
--into [dwh_new].[dbo].[mt_report_loans_on_days] --([cdate] ,[Indicator] ,[Факт/План] ,[Value] ,[dpd] ,[Term])
from #rl
where [НаименованиеЛиста] in (N'ИТОГ_2_ЗАЙМЫ_по_каналам') and [ДатаОперации] between @DateStart and dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0))
group by cast([ДатаОперации] as date) ,[НаименованиеЛиста] ,[Срок]

union all
select cast([ДатаОперации] as date) as [cdate] ,N'Займы шт День' as [Indicator] ,N'Факт' as [Факт/План] ,cast(sum([Колво]) as decimal(38,2)) as [Value] ,null as [dpd] ,[Срок] as [Term]
from #rl
where [НаименованиеЛиста] in (N'ИТОГ_2_ЗАЙМЫ_по_каналам') and [ДатаОперации] between @DateStart and dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0))
group by cast([ДатаОперации] as date) ,[НаименованиеЛиста] ,[Срок]



END

