
-- =============================================
-- Author:		Курдин С.В.
-- Create date: 2019-05-20
-- Description:	Создание основной таблицы для отчета для ЗАЯВОК и ЗАЙМОВ из МФО
-- =============================================

CREATE PROCEDURE [etl].[base_etl_report_kpi]
	-- Add the parameters for the stored procedure here

AS
BEGIN  --auxtab_RequestMFO_1c

	SET NOCOUNT ON;

if OBJECT_ID('[Reports].[dbo].[report_kpi]') is not null
drop table [Reports].[dbo].[report_kpi];

-- Создание вспомогательной таблицы "Комментарии к заявке"
create table [Reports].[dbo].[report_kpi]
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
,[ДатаЧислом] int null --Дата отчета
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
,[Параметр35] nvarchar(255) null 
,[Параметр36] nvarchar(255) null 
,[Параметр37] nvarchar(255) null 
,[Параметр38] nvarchar(255) null 

,[Когорта] nvarchar(255) null 
,[СуммаДопПродуктов] decimal(15,2)  null
,[КолвоДопПродуктов] decimal(15,2)  null
);

---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------
------------ ДЛЯ ЗАЯВОК И ЗАЙМОВ

--with RequestTable as
--(
drop table if exists #RequestTable
select null as [НаименованиеПараметра] ,null as [Неделя] 
		,null as [Параметр1] ,null as [Параметр2] ,null as [Параметр3]	,null as [Параметр4] ,null as [Параметр5] ,null as [Параметр6] ,null as [Параметр7] 
		,N'ИТОГ_2_ЗАЯВКИ_по_каналам' as [НаименованиеЛиста] ,[СуммаЗаявки] as [Сумма] ,datepart(yyyy,[ЗаявкаДатаОперации]) as [Год] 
		,[Докредитование] ,null as [Параметр8] ,null as [Регион] ,null as [Параметр9]
		,datediff(day,0,dateadd(day,datediff(day,0,Getdate()),-1))+2 as [ДатаЧислом] 
		,datediff(day,0,dateadd(day,datediff(day,0,[ЗаявкаПериодУчета]),0))+2 as [ПериодУчета] 
		,null as [Точка] ,[ПовторностьNew] ,[ЗаявкаСрок] as [Срок] ,null as [РОРегион] ,null as [Дивизион] ,null as [Параметр10] 
		,null as [Параметр11] ,null as [Параметр12]
		,[КредитныйПродукт]	
		,null as [Параметр13] ,null as [Параметр14] ,null as [Параметр15] ,N'Ежедневный' as [ПериодичностьОтчета] 
		,null as [Дата] ,[Колво] ,null as [Параметр35] ,null as [Параметр36] ,null as [Параметр37] ,null as [Параметр38] 
		,case
			when [СуммаЗаявки]<=150000 then N'до 150'
			when [СуммаЗаявки]>150000 and [СуммаЗаявки]<=700000 then N'151-700'
			when [СуммаЗаявки]>700000 and [СуммаЗаявки]<=1000000 then N'701-1000'
			when [СуммаЗаявки]>1000000 then N'более 1000'
			else N'Прочее'
		end as [Когорта]
		,0 as [СуммаДопПродуктов] ,0 as [КолвоДопПродуктов] ,cast([ЗаявкаПериодУчета] as datetime) as [ПериодУчета2]
into #RequestTable
from [dwh_new].[dbo].[mt_requests_loans_mfo] with (nolock)
where [ЗаявкаПериодУчета]>=dateadd(month,-2,dateadd(MONTH,datediff(MONTH,0,Getdate()-1),0)) and [ЗаявкаДатаОперации]<dateadd(day,datediff(day,0,Getdate()),0)
		and [ЕстьОсновнаяЗаявка] is null and [ЗаявкаПризнакАннулирования]=N''
--)

--,LoanTable as
--(
drop table if exists #LoanTable
select null as [НаименованиеПараметра] ,null as [Неделя] 
		,null as [Параметр1] ,null as [Параметр2] ,null as [Параметр3]	,null as [Параметр4] ,null as [Параметр5] ,null as [Параметр6] ,null as [Параметр7]  
		,N'ИТОГ_2_ЗАЙМЫ_по_каналам' as [НаименованиеЛиста],[СуммаДоговора] as [Сумма] 
		,datepart(yyyy,[ДатаВыдачиДоговора]) as [Год] ,[Докредитование] as [Докредитование] ,null as [Параметр8] ,null as [Регион] ,null as [Параметр9]
		,datediff(day,0,dateadd(day,datediff(day,0,Getdate()),-1))+2 as [ДатаЧислом] 
		,datediff(day,0,dateadd(day,datediff(day,0,[ПериодУчетаДоговор]),0))+2 as [ПериодУчета] 
		,null as [Точка] ,[ПовторностьNew] as [ПовторностьNew],[ДоговорСрок] as [Срок],null as [РОРегион] ,null as [Дивизион] ,null as [Параметр10]
		,null as [Параметр11] ,null as [Параметр12]
		,[КредитныйПродукт] as [КредитныйПродукт]
		,null as [Параметр13] ,null as [Параметр14] ,null as [Параметр15] ,N'Ежедневный' as [ПериодичностьОтчета]
		,null as [Дата] ,[ДоговорКолво] as [Колво] ,null as [Параметр35] ,null as [Параметр36] ,null as [Параметр37] ,null as [Параметр38] 
		,case
			when [СуммаДоговора]<=150000 then N'до 150'
			when [СуммаДоговора]>150000 and [СуммаДоговора]<=700000 then N'151-700'
			when [СуммаДоговора]>700000 and [СуммаДоговора]<=1000000 then N'701-1000'
			when [СуммаДоговора]>1000000 then N'более 1000'
			else N'Прочее'
		end as [Когорта]
		,[ДоговорСуммаДопПродуктов] as [СуммаДопПродуктов] 
		,[ДоговорКолвоДопПродуктов] as [КолвоДопПродуктов] 
		,cast([ПериодУчетаДоговор] as datetime) as [ПериодУчета2]
		--,dateadd(day,datediff(day,0,[ДатаВыдачиДоговора]),0) as [ДатаОперации]
		--,[ДоговорНомерМФО]
into #LoanTable
from [dwh_new].[dbo].[mt_requests_loans_mfo] with (nolock)
where not [ДатаВыдачиДоговора] is null and [ПериодУчетаДоговор]>=dateadd(month,-2,dateadd(MONTH,datediff(MONTH,0,Getdate()-1),0))
		and [ДатаВыдачиДоговора]< dateadd(day,datediff(day,0,Getdate()),0)
--)

--select [ДоговорНомерМФО] from #LoanTable where [ПериодУчета2] = '2020-05-01'


---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------
------------ ДЛЯ КРЕДИТНОГО ПОРТФЕЛЯ


--,	CredPortfTable as
--(
drop table if exists #CredPortfTable
select [НаименованиеПараметра] ,null as [Неделя] 
		,null as [Параметр1] ,null as [Параметр2] ,null as [Параметр3]	,null as [Параметр4] ,null as [Параметр5] ,null as [Параметр6] ,null as [Параметр7] 
		,[НаименованиеЛиста] ,[ОстатокОД] as [Сумма] ,[Год] ,[Докредитование] ,null as [Параметр8] ,null as [Регион] ,null as [Параметр9]
		,datediff(day,0,dateadd(day,datediff(day,0,Getdate()),-1))+2 as [ДатаЧислом] 
		,datediff(day,0,dateadd(day,datediff(day,0,[ПериодУчета]),0))+2 as [ПериодУчета] 
		,null as [Точка] ,[ПовторностьNew] ,[Срок] ,null as [РОРегион] ,null as [Дивизион] ,null as [Параметр10] 
		,null as [Параметр11] ,null as [Параметр12]
		,[КредитныйПродукт]	
		,null as [Параметр13] ,null as [Параметр14] ,null as [Параметр15] ,[ПериодичностьОтчета] 
		,null as [Дата] ,[Колво] ,null as [Параметр35] ,null as [Параметр36] ,null as [Параметр37] ,null as [Параметр38] ,[Когорта]
		,0 as [СуммаДопПродуктов] ,0 as [КолвоДопПродуктов] ,[ИсточникДанных] ,cast([ПериодУчета] as datetime) as [ПериодУчета2]
into #CredPortfTable 
from [dwh_new].[dbo].[mt_credit_portfolio_mfo] with (nolock)
where not [ТочкаКод] in (N'9984' ,N'9945' ,N'9949' ,N'9948') and [ДатаОбновленияЗаписи]=dateadd(day,0,dateadd(day,datediff(day,0,Getdate()),0)) and [ИсточникДанных]<>N'УМФО'

union all
select distinct * 
from 
(
select  [НаименованиеПараметра] 
		,null as [Неделя] 
		,null as [Параметр1] ,null as [Параметр2] ,null as [Параметр3]	,null as [Параметр4] ,null as [Параметр5] ,null as [Параметр6] ,null as [Параметр7] 
		,N'KPI кредитный портфель_УМФО' as [НаименованиеЛиста] ,[ОстатокОД] as [Сумма] ,[Год] ,N'Нет' as [Докредитование] ,null as [Параметр8] ,null as [Регион] ,null as [Параметр9]
		,datediff(day,0,dateadd(day,datediff(day,0,Getdate()),-1))+2 as [ДатаЧислом] 
		,[ПериодУчетаЧислом] as [ПериодУчета]  
		,null as [Точка] ,N'Нет' as [ПовторностьNew] ,[Срок] ,null as [РОРегион] ,null as [Дивизион] ,null as [Параметр10] 
		,null as [Параметр11] ,null as [Параметр12]
		,[КредитныйПродукт]	
		,null as [Параметр13] ,null as [Параметр14] ,null as [Параметр15] ,[ПериодичностьОтчета] 
		,null as [Дата] ,[Колво] ,null as [Параметр35] ,null as [Параметр36] ,null as [Параметр37] ,null as [Параметр38] ,[Когорта]
		,0 as [СуммаДопПродуктов] ,0 as [КолвоДопПродуктов] ,[ИсточникДанных] ,cast(dateadd(month,datediff(month,0,[ПериодУчетаЧислом]),0) as datetime) as [ПериодУчета2]

from [dwh_new].[dbo].[mt_credit_portfolio_mfo] with (nolock) 
where [НаименованиеЛиста]=N'Платежи по ОД_УМФО' and [ДатаОбновленияЗаписи]=dateadd(day,0,dateadd(day,datediff(day,0,Getdate()),0))
) umfo2
--)

---------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------
------------ ДЛЯ ПОСТУПЛЕНИЯ ПЛАТЕЖЕЙ

--,	PaymentReceiptTable as -- поступление платежей
--(
drop table if exists #PaymentReceiptTable
select  [НаименованиеПараметра] as [НаименованиеПараметра] ,0 as [Неделя] 
		,null as [Параметр1] ,null as [Параметр2] ,null as [Параметр3]	,null as [Параметр4] ,null as [Параметр5] ,null as [Параметр6] ,null as [Параметр7] 
		,pr.[НаименованиеЛиста] ,pr.[Сумма] ,pr.[Год] ,rl.[Докредитование] ,null as [Параметр8] ,null as [Регион] ,null as [Параметр9]
		,datediff(day,0,dateadd(day,datediff(day,0,Getdate()),-1))+2 as [ДатаЧислом] 
		,pr.[ПериодУчетаЧислом]  as [ПериодУчета]
		,null as [Точка] ,rl.[ПовторностьNew] ,rl.[ДоговорСрок] as [Срок] ,null as [РОРегион] ,null as [Дивизион] ,null as [Параметр10] 
		,null as [Параметр11] ,null as [Параметр12]
		,rl.[КредитныйПродукт]	
		,null as [Параметр13] ,null as [Параметр14] ,null as [Параметр15] ,null as [ПериодичностьОтчета] 
		,null as [Дата] ,0 as [Колво] ,null as [Параметр35] ,null as [Параметр36] ,null as [Параметр37] ,null as [Параметр38] ,rl.[ЗаявкаКогорта] as [Когорта]
		,0 as [СуммаДопПродуктов] ,0 as [КолвоДопПродуктов] ,cast(dateadd(month,datediff(month,0,pr.[ПериодУчетаЧислом]),0) as datetime) as [ПериодУчета2]
into #PaymentReceiptTable		--select * from #PaymentReceiptTable
from (
	  select 
			case 
				when [ИсточникДанных]=N'УМФО' then N'Платежи по ОД_УМФО' 
				else N'Платежи по ОД' 
			end as [НаименованиеЛиста]
			,case 
				when [ИсточникДанных]=N'УМФО' then N'Кредитование бизнеса' 
				else N'' 
			end as [НаименованиеПараметра]
			,sum([ОДОплачено]) as [Сумма] 
			,[ПериодУчетаЧислом]
			,[ПериодУчета]
			,[Договор]
			,datepart(yyyy,[ПериодУчета]) as [Год]
	  from [dwh_new].[dbo].[mt_payments_receipt_cmr_umfo] with (nolock)
	  where not [Договор] is null and [ОДОплачено]>0 and [ПериодУчета] between dateadd(MONTH,datediff(MONTH,0,dateadd(month,0,dateadd(day,-1,Getdate()))),0) and dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0))
	  group by [ИсточникДанных] ,[ПериодУчетаЧислом] ,[ПериодУчета] ,[Договор]

		union all

	  select 
			case 
				when [ИсточникДанных]=N'УМФО' then N'Платежи по процентам_УМФО' 
				else N'Платежи по процентам' 
			end as [НаименованиеЛиста]
			,case 
				when [ИсточникДанных]=N'УМФО' then N'Кредитование бизнеса' 
				else N'' 
			end as [НаименованиеПараметра]
			,sum([ПроцентыОплачено]) as [Сумма] 
			,[ПериодУчетаЧислом]
			,[ПериодУчета]
			,[Договор]
			,datepart(yyyy,[ПериодУчета]) as [Год]
	  from [dwh_new].[dbo].[mt_payments_receipt_cmr_umfo] with (nolock)
	  where not [Договор] is null and [ПроцентыОплачено]>0 
			and [ПериодУчета] between dateadd(MONTH,datediff(MONTH,0,dateadd(month,0,dateadd(day,-1,Getdate()))),0) and dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0))
	  group by [ИсточникДанных] ,[ПериодУчетаЧислом] ,[ПериодУчета] ,[Договор]

		union all

	  select 
			case 
				when [ИсточникДанных]=N'УМФО' then N'Платежи по пеням_УМФО' 
				else N'Платежи по пеням' 
			end as [НаименованиеЛиста]
			,case 
				when [ИсточникДанных]=N'УМФО' then N'Кредитование бизнеса' 
				else N'' 
			end as [НаименованиеПараметра]
			,sum([ПениОплачено]) as [Сумма] 
			,[ПериодУчетаЧислом]
			,[ПериодУчета]
			,[Договор]
			,datepart(yyyy,[ПериодУчета]) as [Год]
	  from [dwh_new].[dbo].[mt_payments_receipt_cmr_umfo] with (nolock)
	  where not [Договор] is null and [ПениОплачено]>0 and [ПериодУчета] between dateadd(MONTH,datediff(MONTH,0,dateadd(month,0,dateadd(day,-1,Getdate()))),0) and dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0))
	  group by [ИсточникДанных] ,[ПериодУчетаЧислом] ,[ПериодУчета] ,[Договор]
	  ) pr
left join [dbo].[mt_requests_loans_mfo] rl
on pr.[Договор]=rl.[ДоговорСсылка]
--)


-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
---------- ДЛЯ ApprovalTakeTable
--
--,
--	TableVerifSource as  -- основная таблица (1)
--(
drop table if exists #TableVerifSource
select
rts.[ЗаявкаСсылка_Исх] 
,rts.[ЗаявкаНомер_Исх]
,rts.[СтатусНаим_Исх]
,rts.[СтатусНаим_След]
,N'' as [НаименованиеПараметра]
,dateadd(MONTH,datediff(MONTH,0,rts.[Период_Исх]),0) as [ДатаСобытия]
,rts.[Период_Исх]
,rts.[Период_След]
,N'' as [ДопПараметр_1]

,zl.[Регион] as [Регион]
,zl.[РОРегион]
,rts.[ИсполнительСсылка_След] as [ИсполнительСсылка]
,rts.[ИсполнительНаим_След] as [Исполнитель]

,1 as [Колво]
--,cast((datediff(second,rts.[Период_Исх],rts.[Период_След])/86400) as numeric(15,10))  as [wqw]
,cast((datediff(second,rts.[Период_Исх],rts.[Период_След])/86400) as numeric(15,10)) as [СрВремяРасссмотрения]
,zl.[ПризнакАннулирования]
,zl.[ЕстьОсновнаяЗаявка]
,zl.[СуммаДоговора] as [СуммаЗаявки]
,case  when zl.[ПервичнаяСумма]<>0 then zl.[ПервичнаяСумма] else zl.[СуммаДоговора] end as [ПервичнаяСумма]
into #TableVerifSource
from [dwh_new].[dbo].[mt_requests_transition_mfo] rts with (nolock) 
left join (select [ЗаявкаСсылка] as [Ссылка] ,[ЗаявкаНомер] ,[ЕстьОсновнаяЗаявка] 
				 ,[ЗаявкаРегион] as [Регион] ,[ЗаявкаРОРегион] as [РОРегион] 
				 ,[СуммаЗаявки] as [СуммаДоговора] ,[ПервичнаяСумма] 
				 ,[ЗаявкаПризнакАннулирования] as [ПризнакАннулирования]
		   from [dwh_new].[dbo].[mt_requests_loans_mfo]  with (nolock)) zl
on rts.[ЗаявкаСсылка_Исх]=zl.[Ссылка]
where (rts.[СтатусНаим_Исх] in (N'Верификация КЦ') 
	  or rts.[СтатусНаим_След] in (N'Отказано' ,N'Отказ документов клиента'))
	  and rts.[Период_Исх]>= dateadd(MONTH,datediff(MONTH,0,dateadd(month,-1,Getdate())),0)
--	  and zl.[ПризнакАннулирования]=N''
--	  and zl.[ЕстьОсновнаяЗаявка] is null
--),
--------------------------------------------------------------------------
--RequestForVerification as  -- Заявки на верификацию (1)
--(
drop table if exists #RequestForVerification
select  tvs.[ПризнакАннулирования] ,tvs.[ЕстьОсновнаяЗаявка],
		tvs.[ЗаявкаСсылка_Исх] ,tvs.[ЗаявкаНомер_Исх] ,tvs.[СтатусНаим_Исх] ,tvs.[СтатусНаим_След] 
		,N'Общее кол-во заявок на верификацию' as [НаименованиеПараметра] ,tvs.[ДатаСобытия] ,tvs.[Период_Исх] ,tvs.[Период_След]
		,N'' as [ДопПараметр_1] ,[Регион] ,[РОРегион] ,[ИсполнительСсылка] ,[Исполнитель] ,[Колво] ,[СрВремяРасссмотрения] ,[СуммаЗаявки] ,[ПервичнаяСумма]
into #RequestForVerification
from #TableVerifSource tvs
left join (select [ЗаявкаСсылка_Исх] ,[СтатусНаим_Исх] ,[Период_Исх] ,rank() over (partition by [ЗаявкаСсылка_Исх] ,[СтатусНаим_Исх] order by [Период_Исх] desc) as [rank]
		   from #TableVerifSource) tvs1
on tvs.[ЗаявкаСсылка_Исх] = tvs1.[ЗаявкаСсылка_Исх] and tvs.[Период_Исх] = tvs1.[Период_Исх] 
where tvs.[СтатусНаим_Исх] = N'Верификация КЦ' and tvs1.[rank]=1
		and [ПризнакАннулирования]=N''
		and [ЕстьОсновнаяЗаявка] is null
--),
--	FailuresOfVerifiers as -- отказы со стороны верификаторов (2)
--(
drop table if exists #FailuresOfVerifiers
select [ПризнакАннулирования] ,[ЕстьОсновнаяЗаявка] ,tvs.[ЗаявкаСсылка_Исх] ,[ЗаявкаНомер_Исх] ,tvs.[СтатусНаим_Исх] ,[СтатусНаим_След] 
		,N'Кол-во отказов со стороны верификаторов' as [НаименованиеПараметра] ,[ДатаСобытия] ,tvs.[Период_Исх] ,[Период_След]
		,N'' as [ДопПараметр_1] ,[Регион] ,[РОРегион] ,[ИсполнительСсылка] ,[Исполнитель] ,[Колво] ,[СрВремяРасссмотрения] ,[СуммаЗаявки] ,[ПервичнаяСумма]
into #FailuresOfVerifiers
from #TableVerifSource tvs
left join (select [ЗаявкаСсылка_Исх] ,[СтатусНаим_Исх] ,[Период_Исх] ,rank() over (partition by [ЗаявкаСсылка_Исх] ,[СтатусНаим_Исх] order by [Период_Исх] desc) as [rank]
		   from #TableVerifSource) tvs1
on tvs.[ЗаявкаСсылка_Исх] = tvs1.[ЗаявкаСсылка_Исх] and tvs.[Период_Исх] = tvs1.[Период_Исх] 
where [СтатусНаим_След] in (N'Отказано' ,N'Отказ документов клиента')
		and tvs1.[rank]=1
--		and [ПризнакАннулирования]=N''
--		and [ЕстьОсновнаяЗаявка] is null
--)
--,	aux_ApprovalTakeRateMFO as
--(
drop table if exists #aux_ApprovalTakeRateMFO
select distinct
datepart(dd,vrf2.[Период_Исх]) as [ДеньМесяца]
,datepart(wk,vrf2.[Период_Исх]) as [Неделя]
,datepart(yyyy,vrf2.[Период_Исх]) as [Год]
,cast(dateadd(MONTH,datediff(MONTH,0,vrf2.[Период_Исх]),0) as datetime) as [ДатаЧислом]
,cast(dateadd(MONTH,datediff(MONTH,0,vrf2.[Период_Исх]),0) as datetime) as [ПериодУчета]

,vrf2.[ЗаявкаСсылка_Исх] 
,vrf2.[ЗаявкаНомер_Исх]
,vrf2.[СтатусНаим_Исх]
,vrf2.[СтатусНаим_След]

,vrf2.[НаименованиеПараметра]

,N'' as [Параметр1]
,N'' as [Параметр2]
,N'' as [Параметр3]
,N'' as [Параметр4]
,N'' as [Параметр5]
,N'' as [Параметр6]
,N'' as [Параметр7]
,N'ApprovalTakeRate' as [НаименованиеЛиста]
,vrf2.[Колво]

,N'' as [Докредитование]
,N'' as [Параметр8]
,vrf2.[Регион]
,vrf2.[ДопПараметр_1]

,vrf2.[РОРегион]
,N'' as [Дивизион]
,vrf2.[Исполнитель]
,N'' as [ДопПараметр_2]
,vrf2.[СрВремяРасссмотрения] as [ВремяРасссмотрения]
,N'' as [Параметр13]
,N'' as [Параметр14]
,N'' as [Параметр15]
,N'' as [Параметр16]
,N'' as [Параметр17]
,N'' as [Параметр18]
,N'' as [Параметр19]
,vrf2.[ДатаСобытия]
,vrf2.[СуммаЗаявки]  
,vrf2.[ПервичнаяСумма]
--,rts.[ЗаявкаСсылка_Исх] 
--,rts.[ЗаявкаНомер_Исх]
--,rts.[СтатусНаим_Исх]
--,rts.[СтатусНаим_След]
--,zl.[ЕстьОсновнаяЗаявка]
--,rts.[Период_Исх]
--,rts.[Период_След]
into #aux_ApprovalTakeRateMFO
from (
	  select  distinct *
	  from #RequestForVerification  -- Заявки на верификацию (1)

	  union all

	  select distinct  *
	  from #FailuresOfVerifiers
	  ) vrf2
--)
--,	ApprovalTakeTable as
--(
drop table if exists #ApprovalTakeTable
select ar.[НаименованиеПараметра] ,null as [Неделя] 
		,null as [Параметр1] ,null as [Параметр2] ,null as [Параметр3]	,null as [Параметр4] ,null as [Параметр5] ,null as [Параметр6] ,null as [Параметр7] 
		,(ar.[НаименованиеЛиста]+N'_KPI') as [НаименованиеЛиста] ,[Колво] as [Сумма] ,ar.[Год] ,N'' as [Докредитование] ,null as [Параметр8] ,null as [Регион] ,null as [Параметр9]
		,datediff(day,0,dateadd(day,datediff(day,0,Getdate()),-1))+2 as [ДатаЧислом] 
		,datediff(day,0,dateadd(day,datediff(day,0,ar.[ПериодУчета]),0))+2 as [ПериодУчета] 
		,null as [Точка] ,N'' as [ПовторностьNew] ,null as [Срок] ,null as [РОРегион] ,null as [Дивизион] ,null as [Параметр10] 
		,null as [Параметр11] ,null as [Параметр12]
		,N'' as [КредитныйПродукт]	
		,null as [Параметр13] ,null as [Параметр14] ,null as [Параметр15] ,N'' as [ПериодичностьОтчета] 
		,null as [Дата] ,[Колво] ,null as [Параметр35] ,null as [Параметр36] ,null as [Параметр37] ,null as [Параметр38] ,N'' as [Когорта]
		,0 as [СуммаДопПродуктов] ,0 as [КолвоДопПродуктов] ,cast(ar.[ПериодУчета] as datetime) as [ПериодУчета2]
into #ApprovalTakeTable
from (select [НаименованиеПараметра] ,[НаименованиеЛиста] ,sum([Колво]) as [Колво] ,[ПериодУчета] ,[Год]
	  from #aux_ApprovalTakeRateMFO 
	  group by [НаименованиеПараметра] ,[НаименованиеЛиста] ,[ПериодУчета] ,[Год]) ar
--where not [ТочкаКод] in (N'9984' ,N'9945' ,N'9949' ,N'9948')
--)

drop table if exists #t_res

select 
		cast([НаименованиеПараметра] as nvarchar(255)) as [НаименованиеПараметра] ,[Неделя] 
		,[Параметр1] ,[Параметр2] ,[Параметр3]	,[Параметр4] , [Параметр5] ,[Параметр6] ,[Параметр7] 
		,[НаименованиеЛиста] ,sum([Сумма]) as [Сумма] ,[Год] ,[Докредитование] ,[Параметр8] ,[Регион] ,[Параметр9]
		,[ДатаЧислом] 
		,[ПериодУчета] 
		,[Точка] ,[ПовторностьNew] ,[Срок] ,[РОРегион] ,[Дивизион] ,[Параметр10] 
		,[Параметр11] ,[Параметр12]
		,[КредитныйПродукт]	
		,[Параметр13] ,[Параметр14] ,[Параметр15] ,cast([ПериодичностьОтчета] as nvarchar(255)) as [ПериодичностьОтчета] 
		,[Дата] ,sum([Колво]) as [Колво] ,[Параметр35] ,[Параметр36] ,[Параметр37] ,[Параметр38] ,[Когорта]
		,sum([СуммаДопПродуктов]) as [СуммаДопПродуктов] ,sum([КолвоДопПродуктов]) as [КолвоДопПродуктов]
		,[ПериодУчета2] 

into #t_res
from #RequestTable
group by [НаименованиеПараметра] ,[Неделя] 
		,[Параметр1] ,[Параметр2] ,[Параметр3]	,[Параметр4] , [Параметр5] ,[Параметр6] ,[Параметр7] 
		,[НаименованиеЛиста] ,[Год] ,[Докредитование] ,[Параметр8] ,[Регион] ,[Параметр9]
		,[ДатаЧислом] 
		,[ПериодУчета] 
		,[Точка] ,[ПовторностьNew] ,[Срок] ,[РОРегион] ,[Дивизион] ,[Параметр10] 
		,[Параметр11] ,[Параметр12]
		,[КредитныйПродукт]	
		,[Параметр13] ,[Параметр14] ,[Параметр15] ,[ПериодичностьОтчета] 
		,[Дата] ,[Параметр35] ,[Параметр36] ,[Параметр37] ,[Параметр38] ,[Когорта] ,[ПериодУчета2]

union all

select 
		cast([НаименованиеПараметра] as nvarchar(255)) as [НаименованиеПараметра] ,[Неделя] 
		,[Параметр1] ,[Параметр2] ,[Параметр3]	,[Параметр4] , [Параметр5] ,[Параметр6] ,[Параметр7] 
		,[НаименованиеЛиста] ,sum([Сумма]) as [Сумма] ,[Год] ,[Докредитование] ,[Параметр8] ,[Регион] ,[Параметр9]
		,[ДатаЧислом] 
		,[ПериодУчета] 
		,[Точка] ,[ПовторностьNew] ,[Срок] ,[РОРегион] ,[Дивизион] ,[Параметр10] 
		,[Параметр11] ,[Параметр12]
		,[КредитныйПродукт]	
		,[Параметр13] ,[Параметр14] ,[Параметр15] ,cast([ПериодичностьОтчета] as nvarchar(255)) as [ПериодичностьОтчета]  
		,[Дата] ,sum([Колво]) as [Колво] ,[Параметр35] ,[Параметр36] ,[Параметр37] ,[Параметр38] ,[Когорта]
		,sum([СуммаДопПродуктов]) as [СуммаДопПродуктов] ,sum([КолвоДопПродуктов]) as [КолвоДопПродуктов]
		,[ПериодУчета2]
--[НаименованиеЛиста_MFO] ,sum([Сумма]) as [Сумма] ,[Докредитование_MFO] ,[ДатаЧислом] ,[ПериодУчета] ,[ПовторностьNew_MFO] ,[Срок_MFO] 
--		,[КредитныйПродукт_MFO]	,sum([Колво_MFO]) as [Колво_MFO]
from #LoanTable 
group by [НаименованиеПараметра] ,[Неделя] 
		,[Параметр1] ,[Параметр2] ,[Параметр3]	,[Параметр4] , [Параметр5] ,[Параметр6] ,[Параметр7] 
		,[НаименованиеЛиста] ,[Год] ,[Докредитование] ,[Параметр8] ,[Регион] ,[Параметр9]
		,[ДатаЧислом] 
		,[ПериодУчета] 
		,[Точка] ,[ПовторностьNew] ,[Срок] ,[РОРегион] ,[Дивизион] ,[Параметр10] 
		,[Параметр11] ,[Параметр12]
		,[КредитныйПродукт]	
		,[Параметр13] ,[Параметр14] ,[Параметр15] ,[ПериодичностьОтчета] 
		,[Дата] ,[Параметр35] ,[Параметр36] ,[Параметр37] ,[Параметр38] ,[Когорта] ,[ПериодУчета2]

union all

select  cast([НаименованиеПараметра] as nvarchar(255)) as [НаименованиеПараметра] ,[Неделя] 
		,[Параметр1] ,[Параметр2] ,[Параметр3]	,[Параметр4] , [Параметр5] ,[Параметр6] ,[Параметр7] 
		,[НаименованиеЛиста] ,sum([Сумма]) as [Сумма] ,[Год] ,[Докредитование] ,[Параметр8] ,[Регион] ,[Параметр9]
		,[ДатаЧислом] 
		,[ПериодУчета] 
		,[Точка] ,[ПовторностьNew] ,[Срок] ,[РОРегион] ,[Дивизион] ,[Параметр10] 
		,[Параметр11] ,[Параметр12]
		,[КредитныйПродукт]	
		,[Параметр13] ,[Параметр14] ,[Параметр15] ,cast([ПериодичностьОтчета] as nvarchar(255)) as [ПериодичностьОтчета]  
		,[Дата] ,sum([Колво]) as [Колво] ,[Параметр35] ,[Параметр36] ,[Параметр37] ,[Параметр38] ,[Когорта]	
		,sum([СуммаДопПродуктов]) as [СуммаДопПродуктов] ,sum([КолвоДопПродуктов]) as [КолвоДопПродуктов] ,[ПериодУчета2]
from #CredPortfTable
group by [НаименованиеПараметра] ,[Неделя] 
		,[Параметр1] ,[Параметр2] ,[Параметр3]	,[Параметр4] , [Параметр5] ,[Параметр6] ,[Параметр7] 
		,[НаименованиеЛиста] ,[Год] ,[Докредитование] ,[Параметр8] ,[Регион] ,[Параметр9]
		,[ДатаЧислом] 
		,[ПериодУчета] 
		,[Точка] ,[ПовторностьNew] ,[Срок] ,[РОРегион] ,[Дивизион] ,[Параметр10] 
		,[Параметр11] ,[Параметр12]
		,[КредитныйПродукт]	
		,[Параметр13] ,[Параметр14] ,[Параметр15] ,[ПериодичностьОтчета] 
		,[Дата] ,[Параметр35] ,[Параметр36] ,[Параметр37] ,[Параметр38] ,[Когорта] ,[ПериодУчета2]


union all

select  [НаименованиеПараметра] ,[Неделя] 
		,[Параметр1] ,[Параметр2] ,[Параметр3]	,[Параметр4] , [Параметр5] ,[Параметр6] ,[Параметр7] 
		,[НаименованиеЛиста] ,sum([Сумма]) as [Сумма] ,[Год] ,[Докредитование] ,[Параметр8] ,[Регион] ,[Параметр9]
		,[ДатаЧислом] 
		,[ПериодУчета] 
		,[Точка] ,[ПовторностьNew] ,[Срок] ,[РОРегион] ,[Дивизион] ,[Параметр10] 
		,[Параметр11] ,[Параметр12]
		,[КредитныйПродукт]	
		,[Параметр13] ,[Параметр14] ,[Параметр15] ,cast([ПериодичностьОтчета] as nvarchar(255)) as [ПериодичностьОтчета]  
		,[Дата] ,sum([Колво]) as [Колво] ,[Параметр35] ,[Параметр36] ,[Параметр37] ,[Параметр38] ,[Когорта]	
		,sum([СуммаДопПродуктов]) as [СуммаДопПродуктов] ,sum([КолвоДопПродуктов]) as [КолвоДопПродуктов] ,[ПериодУчета2]
from #PaymentReceiptTable
group by [НаименованиеПараметра] ,[Неделя] 
		,[Параметр1] ,[Параметр2] ,[Параметр3]	,[Параметр4] , [Параметр5] ,[Параметр6] ,[Параметр7] 
		,[НаименованиеЛиста] ,[Год] ,[Докредитование] ,[Параметр8] ,[Регион] ,[Параметр9]
		,[ДатаЧислом] 
		,[ПериодУчета] 
		,[Точка] ,[ПовторностьNew] ,[Срок] ,[РОРегион] ,[Дивизион] ,[Параметр10] 
		,[Параметр11] ,[Параметр12]
		,[КредитныйПродукт]	
		,[Параметр13] ,[Параметр14] ,[Параметр15] ,[ПериодичностьОтчета] 
		,[Дата] ,[Параметр35] ,[Параметр36] ,[Параметр37] ,[Параметр38] ,[Когорта] ,[ПериодУчета2]

union all

select *
from #ApprovalTakeTable


insert into [Reports].[dbo].[report_kpi] ([НаименованиеПараметра] ,[Неделя] ,[Параметр1] ,[Параметр2] ,[Параметр3] ,[Параметр4]
										  ,[Параметр5] ,[Параметр6] ,[Параметр7] ,[НаименованиеЛиста] ,[Сумма]
										  ,[Год] ,[Докредитование] ,[Параметр8] ,[Регион] ,[Параметр9]
										  ,[ДатаЧислом] ,[ПериодУчета] ,[Точка] ,[ПовторностьNew] ,[Срок]
										  ,[РОРегион] ,[Дивизион] ,[Параметр10] ,[Параметр11] ,[Параметр12]
										  ,[КредитныйПродукт]	,[Параметр13] ,[Параметр14] ,[Параметр15] ,[ПериодичностьОтчета]
										  ,[Дата] ,[Колво] ,[Параметр35] ,[Параметр36] ,[Параметр37] ,[Параметр38] ,[Когорта]
										  ,[СуммаДопПродуктов] ,[КолвоДопПродуктов])

    -- Insert statements for procedure here
select [НаименованиеПараметра] ,[Неделя] ,[Параметр1] ,[Параметр2] ,[Параметр3] ,[Параметр4]
		,[Параметр5] ,[Параметр6] ,[Параметр7] ,[НаименованиеЛиста] ,[Сумма]
		,[Год] ,[Докредитование] ,[Параметр8] ,[Регион] ,[Параметр9]
		,[ДатаЧислом] ,[ПериодУчета] ,[Точка] ,[ПовторностьNew] ,[Срок]
		,[РОРегион] ,[Дивизион] ,[Параметр10] ,[Параметр11] ,[Параметр12]
		,[КредитныйПродукт]	,[Параметр13] ,[Параметр14] ,[Параметр15] ,[ПериодичностьОтчета]
		,[Дата] ,[Колво] ,[Параметр35] ,[Параметр36] ,[Параметр37] ,[Параметр38] ,[Когорта]
		,[СуммаДопПродуктов] ,[КолвоДопПродуктов] 
from #t_res




insert into [Reports].[dbo].[Carmoney_Three_Report_kpi] ([cdate] ,[Period] ,[Indicatr] ,[Qty] ,[Sm])

select  
		getdate() as cdate 
		,cast([ДатаЧислом]-2 as datetime) [Period]
		,'Кредитный портфель' [Indicatr] 
		,sum([Колво]) as [Qty] 
		,sum([Сумма]) as [Sm]
--into [Reports].[dbo].[Carmoney_Three_Report_kpi]
from #CredPortfTable
where [НаименованиеЛиста] in ('KPI кредитный портфель' ,'KPI кредитный портфель_УМФО')
group by cast([ДатаЧислом]-2 as datetime)

union all
select  
		getdate() as cdate 
		,cast([ДатаЧислом]-2 as datetime) [Period]
		,'Поступление ОД' [Indicatr] 
		,sum([Колво]) as [Qty] 
		,sum([Сумма]) as [Sm]

from #PaymentReceiptTable
where [НаименованиеЛиста] in ('Платежи по ОД' ,'Платежи по ОД_УМФО')
group by cast([ДатаЧислом]-2 as datetime)



----------------------- Приведенные дни
drop table if exists #QtyDay
select cast(Getdate() as date) t0day
      ,cast(dateadd(day,-1,getdate()) as date) accdate
	  ,d1.[NewQtyDays] lastday
	  ,d2.[NewQtyDays] currday
	  ,case when d2.[NewQtyDays]>0 then d1.[NewQtyDays]/d2.[NewQtyDays] else 0 end as koef
into #QtyDay
from [dwh_new].[dbo].[calendar_expected_dates_Rep] d1
cross join (select distinct [NewQtyDays]
			from [dwh_new].[dbo].[calendar_expected_dates_Rep] 
			where cast([date] as date) = case 
									when datepart(hh, getdate()) < 23 
										then cast(dateadd(day,-1,getdate()) as date)
									else cast(getdate() as date) end
			) d2
where cast(d1.[date] as date) =  cast(dateadd(day,-1,dateadd(month,datediff(month,0,dateadd(month,1,getdate())),0)) as date)
--select * from #QtyDay


----------------------- Погашено ОД
drop table if exists #repaymentprincipaldebt	--платежи по ОД
select cast([ПериодУчета2] as date) as [period]  
		,getdate() as rdate 
		,cast(getdate() as date) as accdate 
		,N'Погашение ОД' as [Indicator]
		--, [НаименованиеПараметра] as [НаименованиеПараметра]
		,sum(case when [НаименованиеЛиста]=N'Платежи по ОД' then [Сумма] else 0 end) as [Value_CMR]
		,sum(case when [НаименованиеЛиста]=N'Платежи по ОД_УМФО' then [Сумма] else 0 end) as [Value_UMFO]
		--,null as [Avr]

into #repaymentprincipaldebt
--select *
from #t_res z 
where [НаименованиеЛиста] in (N'Платежи по ОД' ,N'Платежи по ОД_УМФО') and cast([ПериодУчета2] as date) = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)
group by cast([ПериодУчета2] as date) --,[НаименованиеПараметра]
--select * from #repaymentprincipaldebt

----------------------- Прирост портфеля
drop table if exists #portf_growth	--платежи по ОД

select t1.[period] 
		,N'Портфель просрочка' as [Indicator]
		,isnull([Value_L],0) [Value_L]
		,isnull([Value_CMR],0) [Value_CMR]
		,isnull([Value_UMFO],0) [Value_UMFO]
		,isnull([Value_L],0)-isnull([Value_CMR],0) as [GrowthPortf]
		,isnull([Value_L],0)*koef as [fcValue_L]  
		,isnull([Value_CMR],0)*koef as [fcValue_CMR] 
		,(isnull([Value_UMFO],0)*koef) as [fcValue_UMFO]
		,(isnull([Value_L],0)-isnull([Value_CMR],0))*koef as [fsGrowthPortf]
		,isnull([Value_L],0)*koef-isnull([Value_CMR],0)*koef as [fsGrowthPortf2]
into #portf_growth
from (select cast([ПериодУчета2] as date) as [period]  
			,sum([Сумма]) as [Value_L] 
			--,sum(case when [НаименованиеЛиста]=N'Платежи по ОД_УМФО' then [Сумма] else 0 end) as [Value_UMFO]
	  --select *
	  from #t_res
	  where [НаименованиеЛиста] in (N'ИТОГ_2_ЗАЙМЫ_по_каналам') and cast([ПериодУчета2] as date) = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)
	  group by cast([ПериодУчета2] as date) --,[НаименованиеПараметра]
	  ) t1
left join #repaymentprincipaldebt t2 on t1.[period]=t2.[period]
cross join #QtyDay q

--select * from #portf_growth

----------------------- Показатели предыдущих периодов
drop table if exists #minus1month
select * 
into #minus1month
from [dwh_new].[dbo].[mt_report_carmoney_kpi] 
where [OnOff]=1 and [Факт/План]='Факт' 
		and [period] = dateadd(month,-1,dateadd(month,datediff(month,0,Getdate()),0))
		and Indicator in (N'Сумма займов накопительно' ,N'Сумма страховки по Договору' ,N'Сумма страховки Полученная в ДОХОД'  
						 ,N'Портфель просрочка' ,N'просрочка 1-90 дней' ,N'просрочка 90+ дней'
						 ,N'НАЧИСЛЕННАЯ ВЫРУЧКА' ,N'РЕЗЕРВ на ОД (на дату отчета)' ,N'РЕЗЕРВ на % (на дату отчета)') 
	  and rdate in (select max(rdate) from [dwh_new].[dbo].[mt_report_carmoney_kpi] where [period] = dateadd(month,-1,dateadd(MONTH,datediff(MONTH,0,Getdate()),0)) )
--select [Value] from #minus1month where [Indicator]=N'Сумма займов накопительно'

drop table if exists #minus2month
select * 
into #minus2month --select *
from [dwh_new].[dbo].[mt_report_carmoney_kpi] 
where [OnOff]=1 and [Факт/План]='Факт' 
		and [period] = dateadd(month,-2,dateadd(MONTH,datediff(MONTH,0,Getdate()),0))
		and Indicator in (N'Сумма займов накопительно' ,N'Сумма страховки по Договору' ,N'Сумма страховки Полученная в ДОХОД' 
						 ,N'Портфель просрочка' ,N'просрочка 1-90 дней' ,N'просрочка 90+ дней' 
						 ,N'НАЧИСЛЕННАЯ ВЫРУЧКА' ,N'РЕЗЕРВ на ОД (на дату отчета)' ,N'РЕЗЕРВ на % (на дату отчета)') 
	  and rdate in (select max(rdate) from [dwh_new].[dbo].[mt_report_carmoney_kpi] where [period] = dateadd(month,-2,dateadd(MONTH,datediff(MONTH,0,Getdate()),0)) )

----------------------- Портфель - договора по бакетам
drop table if exists #portf_backet
select cast([ПериодУчета2] as date) as [period] ,getdate() as [rdate] ,cast(getdate() as date) as [accdate]
		--[ДатаОперации] as [cdate] 
		,N'Портфель просрочка' as [Indicator] 
		,N'Факт' as [Факт/План] 
		,sum([Сумма]) as [Value]
		,0.00 as [fcValue]
		,case 
			when [НаименованиеПараметра] = N'Непросроченный' then N'0'
			when [НаименованиеПараметра] = N'_1-3' then N'1-3'
			when [НаименованиеПараметра] = N'_4-30' then N'4-30'
			when [НаименованиеПараметра] = N'Более 720' then N'720+'
			else [НаименованиеПараметра]
		end as [dpd]
		,0 as [OnOff] 
		,0 as [isChanged]
into #portf_backet
--select *
from #t_res
where [НаименованиеЛиста] in (N'KPI кредитный портфель' ,N'KPI кредитный портфель_УМФО') --and [ДатаОперации] >= dateadd(month,datediff(month,0,Getdate()),0)
group by cast([ПериодУчета2] as date) --,getdate() ,cast(getdate() as date) 
		,[НаименованиеПараметра]



----------------------- Показатели продаж

drop table if exists #req
select cast([ПериодУчета2] as date) as [period]  
		,N'Количество заявок' as [Indicator]
		,N'Факт' as [Факт/План]
		,sum([Сумма]) as [Value]
		,sum([Колво]) as [Qty]
		,null as [Avr]
into #req
--select *
from #t_res z 
where [НаименованиеЛиста] in (N'ИТОГ_2_ЗАЯВКИ_по_каналам' ,N'ИТОГ_2_ЗАЯВКИ__шт_по_каналам_УМФО') --and [ДатаОперации] >= dateadd(month,datediff(month,0,Getdate()),0)
group by cast([ПериодУчета2] as date) ,[НаименованиеПараметра]

--select * from #req

drop table if exists #loan
select cast([ПериодУчета2] as date) as [period]  
		,N'Кол-во займов' as [Indicator]
		, [НаименованиеПараметра] as [НаименованиеПараметра]
		,sum([Сумма]) as [Value]
		,sum([Колво]) as [Qty]
		,case when sum([Колво])<>0 then ceiling (sum([Сумма])/sum([Колво])) else 0 end as [Avr]
		,sum([СуммаДопПродуктов]) as [Summ_addprod]
		,sum([КолвоДопПродуктов]) as [Qty_addprod]
into #loan
--select *
from #t_res
where [НаименованиеЛиста] in (N'ИТОГ_2_ЗАЙМЫ_по_каналам' ,N'ИТОГ_2_ЗАЙМЫ__шт_по_каналам_УМФО') --and [ДатаОперации] >= dateadd(month,datediff(month,0,Getdate()),0)
group by cast([ПериодУчета2] as date) ,[НаименованиеПараметра]


drop table if exists #loansumm
select [period]  
		,N'Сумма займов накопительно' as [Indicator]
		,m.[Value] as [lastValue]
		,l.[Value] as [currValue]
		,(l.[Value]+m.[Value]) as [Value]

into #loansumm
--select *
from #loan l
cross join (select [Value] from #minus1month where [Indicator]=N'Сумма займов накопительно') m
where [period] = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)


drop table if exists #konv
select r.[period]  
		,N'Конвертация' as [Indicator]
		,case when r.[Qty]<>0 then l.[Qty]/r.[Qty] end as [Value]

into #konv
--select *
from #req r
left join #loan l on r.[period]=l.[period]


drop table if exists #t_notapproval
select cast([ПериодУчета2] as date) as [period]  
		,[НаименованиеПараметра] as [Indicator]
		,sum([Сумма]) as [Value]
		,sum([Колво]) as [Qty]
		,case when sum([Колво])<>0 then ceiling (sum([Сумма])/sum([Колво])*100) else 0 end as [Avr]
into #t_notapproval
--select *
from #t_res
where [НаименованиеЛиста] in (N'ApprovalTakeRate_KPI')
		and [НаименованиеПараметра] in (N'Кол-во отказов со стороны верификаторов' ,N'Общее кол-во заявок на верификацию')
		and cast([ПериодУчета2] as date) = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)
group by cast([ПериодУчета2] as date) ,[НаименованиеПараметра]
--select * from #t_notapproval

----------------------- итоговая таблица с показателями продаж
drop table if exists #group_sales
select [period] ,[Indicator] ,[Qty] as [Value] ,ceiling([Qty]*t.koef) [fcValue] --,null as [dpd] ,1 as [OnOff] ,1 as [isChanged]
into #group_sales
from #req r cross join #QtyDay t
where [period] = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)

union all
select [period] ,[Indicator] ,[Qty] [Value] ,ceiling([Qty]*t.koef) [fcValue] --,null as [dpd] ,1 as [OnOff] ,1 as [isChanged]
from #loan r cross join #QtyDay t
where [period] = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)

union all
select [period] ,N'Сумма займов' as [Indicator] ,[Value] ,ceiling([Value]*t.koef) [fcValue] --,null as [dpd] ,1 as [OnOff] ,1 as [isChanged]
from #loan r cross join #QtyDay t
where [period] = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)

union all 
select [period] ,[Indicator] ,[Value] ,(ceiling([currValue]*t.koef)+r.[lastValue]) [fcValue] --,null as [dpd] ,1 as [OnOff] ,1 as [isChanged]
from #loansumm r cross join #QtyDay t
--where [period] = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)

union all
select [period] ,N'Средний размер займа' as [Indicator] ,[Avr] as [Value] ,ceiling(([Value]*t.koef)/([Qty]*t.koef))  [fcValue] --,null as [dpd] ,1 as [OnOff] ,1 as [isChanged]
from #loan r cross join #QtyDay t
where [period] = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)

union all 
select [period] ,[Indicator] ,[Value] ,round([Value]*t.koef,5) [fcValue] --,null as [dpd] ,1 as [OnOff] ,1 as [isChanged]
from #konv r cross join #QtyDay t
where [period] = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)

union all
select r.[period] ,N'Approval Rate' as [Indicator] ,(1-n.[Qty]/r.[Qty]) as [Value] ,0.00 as [fcValue] --,null as [dpd] ,1 as [OnOff] ,1 as [isChanged]
from #req r 
cross join (select [Qty] from #t_notapproval where [Indicator]=N'Кол-во отказов со стороны верификаторов') n
where [period] = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)

union all
select r.[period] ,N'Take Rate' as [Indicator] ,(a.[lQty]/(r.[Qty]-n.[Qty])) as [Value] ,0.00 as [fcValue] --,null as [dpd] ,1 as [OnOff] ,1 as [isChanged]
from #req r 
cross join (select [Qty] as [Qty] from #t_notapproval where [Indicator]=N'Кол-во отказов со стороны верификаторов') n
cross join (select [Qty] as [lQty] from #loan where [period] = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)) a
where [period] = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)

union all
select [period] ,N'Кол-во займов со страховкой' as [Indicator] ,[Qty_addprod] as [Value] ,ceiling([Qty_addprod]*t.koef) [fcValue] --,null as [dpd] ,1 as [OnOff] ,1 as [isChanged]
from #loan r cross join #QtyDay t
where [period] = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)

union all
select [period] ,N'Сумма страховки по Договору' as [Indicator] ,[Summ_addprod] as [Value] ,ceiling([Summ_addprod]*t.koef) [fcValue] --,null as [dpd] ,1 as [OnOff] ,1 as [isChanged]
from #loan r cross join #QtyDay t
where [period] = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)

union all
select [period] ,N'Сумма страховки Полученная в ДОХОД' as [Indicator] 
		--,[Summ_addprod]
		,ceiling([Summ_addprod]*([oldValue]/[otheroldValue])) as [Value] 
		,ceiling([Summ_addprod]*t.koef*([oldValue]/[otheroldValue])) as [fcValue] 
		--,null as [dpd] ,1 as [OnOff] ,1 as [isChanged]
from #loan r 
cross join #QtyDay t 
cross join (select [Value] as [oldValue] from #minus1month where [Indicator]=N'Сумма страховки Полученная в ДОХОД') m1
cross join (select [Value] as [otheroldValue] from #minus1month where [Indicator]=N'Сумма страховки по Договору') m2
where r.[period] = cast(dateadd(month,datediff(month,0,Getdate()),0) as date)

--select * from #group_sales

----------------------- Показатели портфеля
drop table if exists #portf
select cast([ПериодУчета2] as date) as [period]  
		,case 
			when [НаименованиеПараметра] = N'Непросроченный' then N'без просрочки'
			when [НаименованиеПараметра] in (N'_1-3' ,N'_4-30' ,N'31-60' ,N'61-90') then N'просрочка 1-90 дней'
			when not [НаименованиеПараметра] in (N'Непросроченный' ,N'_1-3' ,N'_4-30' ,N'31-60' ,N'61-90') then N'просрочка 90+ дней'
		end as [Indicator]
		, [НаименованиеПараметра] as [НаименованиеПараметра]
		,sum([Сумма]) as [Value]
		,sum([Колво]) as [Qty]
into #portf
--select *
from #t_res
where [НаименованиеЛиста] in (N'KPI кредитный портфель' ,N'KPI кредитный портфель_УМФО') --and [ДатаОперации] >= dateadd(month,datediff(month,0,Getdate()),0)
group by cast([ПериодУчета2] as date) ,[НаименованиеПараметра]

union all
select cast([ПериодУчета2] as date) as [period]  
		,N'в т.ч. просрочка 360+ дней' as [Indicator]
		, [НаименованиеПараметра] as [НаименованиеПараметра]
		,sum([Сумма]) as [Value]
		,sum([Колво]) as [Qty]
--select *
from #t_res
where [НаименованиеЛиста] in (N'KPI кредитный портфель' ,N'KPI кредитный портфель_УМФО') 
		and [НаименованиеПараметра] in (N'361-390' ,N'391-420' ,N'421-450' ,N'451-480' ,N'481-510' ,N'511-540' ,N'541-570' ,N'571-600' ,N'601-630' ,N'631-660' ,N'661-690' ,N'691-720' ,N'Более 720')
group by cast([ПериодУчета2] as date) ,[НаименованиеПараметра]
--select * from #portf

drop table if exists #curr_portf
select [period] ,N'Портфель просрочка' as [Indicator] --,[НаименованиеПараметра] 
		,N'Факт' as [Факт/План] ,sum([Value]) [Value]  ,sum([Qty]) [Qty] --,null as [dpd] ,1 as [OnOff] ,1 as [isChanged] 
into #curr_portf
from #portf 
where [Indicator] in (N'без просрочки' ,N'просрочка 1-90 дней' ,N'просрочка 90+ дней') group by [period]

union all
select [period] ,[Indicator] --,[НаименованиеПараметра] 
		,N'Факт' as [Факт/План] ,sum([Value]) [Value]  ,sum([Qty]) [Qty]  --,null as [dpd] ,1 as [OnOff] ,1 as [isChanged] 
from #portf group by [period] ,[Indicator] --,[НаименованиеПараметра]

--select * from #curr_portf


drop table if exists #portf_koefgrowth
select cp.[period] [periods] --,cp.[Indicator] 
		--,cp.[Value]  
		--,m.[Value]+[fsGrowthPortf2] as [fsValue]
		,sum(isnull((m.[Value]+[fsGrowthPortf2])/[fsGrowthPortf2],0)) [koef0]	-- сравнение с предыдущим месяцем
		,sum(isnull((m.[Value]+[fsGrowthPortf2])/cp.[Value],0)) [koef1]		
		,sum(case when cp.[Indicator]=N'Портфель просрочка' then (m.[Value]+[fsGrowthPortf2]) else 0 end) as [fcValue_]   --fc (forecase) - прогноз
		,sum(case when cp.[Indicator]=N'просрочка 1-90 дней' then cp.[Value] else 0 end) as [Value_1_90]
		,sum(case when cp.[Indicator]=N'просрочка 90+ дней' then cp.[Value] else 0 end) as [Value_90]
		,sum(case when cp.[Indicator]=N'в т.ч. просрочка 360+ дней' then cp.[Value] else 0 end) as [Value_360]  		
into #portf_koefgrowth
from #curr_portf cp 
left join  #portf_growth pg on cp.[period]=pg.[period] and cp.[Indicator]=pg.[Indicator]
left join #minus1month m on cp.[Indicator]=m.[Indicator]
group by cp.[period]
--select * from #portf_koefgrowth


drop table if exists #group_portf
select cp.[period] ,cp.[Indicator] 
		,cp.[Value]  
		,case 
			when cp.[Indicator]=N'Портфель просрочка' then m.[Value]+pg.[fsGrowthPortf2]
			when cp.[Indicator]=N'без просрочки' then [fcValue_]-koef1*([Value_1_90]+[Value_1_90]) 
			when cp.[Indicator]=N'просрочка 1-90 дней' then koef1*[Value_1_90] 
			when cp.[Indicator]=N'просрочка 90+ дней' then koef1*[Value_90]  
			when cp.[Indicator]=N'в т.ч. просрочка 360+ дней' then koef1*[Value_360] 
		end as [fcValue] 
		--,null as [dpd] ,1 as [OnOff] ,1 as [isChanged] 
		--,k.*
into #group_portf
from #curr_portf cp
left join  #portf_growth pg on cp.[period]=pg.[period] and cp.[Indicator]=pg.[Indicator]
left join #minus1month m on cp.[Indicator]=m.[Indicator]
left join #portf_koefgrowth k on cp.[period]=k.[periods]
--select * from #group_portf

----------------------- Показатели финансовые
--
drop table if exists #t_rev	-- выручка
select cast([ПериодУчета2] as date) as [period]  
		--,getdate() as rdate 
		--,cast(getdate() as date) as accdate 
		,N'ВЫРУЧКА ПО ОПЛАТЕ' as [Indicator]

		,sum([Сумма]) as [Value]
		,0.00 as [fcValue]
		--,sum([Колво]) as [Qty]
		--,null as [Avr]
		--,null as [dpd] ,1 as [OnOff] ,1 as [isChanged]
into #t_rev
--select *
from #t_res z 
where [НаименованиеЛиста] in (N'Платежи по процентам' ,N'Платежи по процентам_УМФО' ,N'Платежи по пеням' ,N'Платежи по пеням_УМФО') --and [ДатаОперации] >= dateadd(month,datediff(month,0,Getdate()),0)
group by cast([ПериодУчета2] as date) --,[НаименованиеПараметра]
--select * from #t_rev

drop table if exists #t_addedrev	-- начисленная выручка
select cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date) as [period] 
		--,getdate() as rdate 
		--,cast(getdate() as date) as accdate 
		,mm.[Indicator]
		,case 
			when ((([lastValue]+[lastlastValue])/2)*datepart(dd,getdate())/datediff(day,dateadd(year,-1,[curperiod]),[curperiod]))<>0 
				then
					(([lastValue]+[curValue])/2)*[addlastValue]/datepart(dd,[addperiod])*datediff(day,dateadd(year,-1,[addperiod]),[addperiod])
					/ 
					(([lastValue]+[lastlastValue])/2)*datepart(dd,dateadd(day,-1,getdate()))/datediff(day,dateadd(year,-1,[curperiod]),[curperiod])
			else 0
		end	as [Value]
		,0.00 as [fcValue]
		--,null as [Qty]
		--,null as [Avr]
		--,null as [dpd] ,1 as [OnOff] ,1 as [isChanged]
into #t_addedrev
--select *
from #minus1month mm 
cross join (select [period] as [curperiod] ,sum([Value]) [curValue] from #curr_portf where [Indicator] in (N'Портфель просрочка') group by [period]) cp
cross join (select sum([Value]) [lastValue] from #minus1month where [Indicator] in (N'Портфель просрочка')) lp
cross join (select dateadd(day,-1,dateadd(month,1,[period])) as [addperiod] ,sum([Value]) [addlastValue] from #minus1month where [Indicator] in (N'НАЧИСЛЕННАЯ ВЫРУЧКА') group by [period]) alp
cross join (select sum([Value]) [lastlastValue] from #minus2month where [Indicator] in (N'Портфель просрочка')) l2p
where Indicator in (N'НАЧИСЛЕННАЯ ВЫРУЧКА') 
--select * from #t_addedrev


drop table if exists #t_reservOD	-- резерв на ОД
select cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date) as [period] 
		--,getdate() as rdate 
		--,cast(getdate() as date) as accdate 
		,mm.[Indicator]
		--,lp.[lastValue]
		--,cp.[curValue]
		--,mm.[Value] as [p]
		,case when lp.[lastValue]<>0 then [curValue]/lp.[lastValue]*mm.[Value] else 0 end as [Value]
		,case when lp.[lastValue]<>0 then fp.[curFcValue]/lp.[lastValue]*mm.[Value] else 0 end as [fcValue]
		--,null as [Qty]
		--,null as [Avr]
		--,null as [dpd] ,1 as [OnOff] ,1 as [isChanged]
into #t_reservOD
--select *
from #minus1month mm 
cross join (select sum([Value]) [curValue] from #curr_portf where [Indicator] in (N'Портфель просрочка')) cp
cross join (select sum([Value]) [lastValue] from #minus1month where [Indicator] in (N'Портфель просрочка')) lp
cross join (select sum([fcValue]) [curFcValue] from #group_portf where [Indicator] in (N'Портфель просрочка')) fp
where Indicator in (N'РЕЗЕРВ на ОД (на дату отчета)') 
--select * from #t_reservOD


drop table if exists #t_reservPercent	-- резерв на %
select cast(dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as date) as [period] 
		--,getdate() as rdate 
		--,cast(getdate() as date) as accdate 
		,[Indicator]
		--, [НаименованиеПараметра] as [НаименованиеПараметра]
		--,[Value] as [Value0]
		,case when [lastValue]<>0 then [curValue]/[lastValue]*[Value] else 0 end as [Value]
		,case when [lastValue]<>0 then [curFcValue]/[lastValue]*[Value] else 0 end as [fcValue]
		--,null as [Qty]
		--,null as [Avr]
		--,null as [dpd] ,1 as [OnOff] ,1 as [isChanged]
into #t_reservPercent
--select *
from #minus1month mm 
cross join (select sum([Value]) [curValue] from #curr_portf where [Indicator] in (N'просрочка 1-90 дней' ,N'просрочка 90+ дней')) cp
cross join (select sum([Value]) [lastValue] from #minus1month where [Indicator] in (N'просрочка 1-90 дней' ,N'просрочка 90+ дней')) lp
cross join (select sum([fcValue]) [curFcValue] from #group_portf where [Indicator] in (N'просрочка 1-90 дней' ,N'просрочка 90+ дней')) fp
where Indicator in (N'РЕЗЕРВ на % (на дату отчета)') 
--select * from #t_reservPercent

drop table if exists #t_reservOD_Total	-- резерв на ОД (ВСЕГО)
select o.[period] 
		,N'РЕЗЕРВ (ВСЕГО)  (на дату отчета)' as [Indicator] 
		,(isnull(o.[Value],0)+isnull(p.[Value],0)) as [Value]
		,(isnull(o.[fcValue],0)+isnull(p.[fcValue],0)) as [fcValue]
into #t_reservOD_Total
from #t_reservOD o
full join #t_reservPercent p on o.[period]=p.[period] 

drop table if exists #t_reserv_Part	-- резерв на ОД (ВСЕГО)
select p.[period] 
		,N'Доля РЕЗЕРВА от КП' as [Indicator] 
		,case when p.[Value]<>0 or not p.[Value] is null then (isnull(t.[Value],0)/p.[Value]) else 0 end as [Value]
		,case when p.[fcValue]<>0 or not p.[fcValue] is null then (isnull(t.[fcValue],0)/p.[fcValue]) else 0 end as [fcValue]
into #t_reserv_Part
from #group_portf p
full join #t_reservOD_Total t on p.[period]=t.[period] 
where p.[Indicator]=N'Портфель просрочка'
--select * from #t_reserv_Part

drop table if exists #group_fin
select * into #group_fin from #t_rev
union all
select * from #t_addedrev
union all
select * from #t_reservOD
union all
select * from #t_reservPercent
union all
select * from #t_reservOD_Total
union all
select * from #t_reserv_Part
--select * from #group_fin



drop table if exists #group_all
select [period] --,getdate() as rdate ,cast(getdate() as date) as accdate 
		,[Indicator] ,N'Факт' [Факт/План] ,[Value] --,[fcValue]
		,null as [dpd] ,1 as [OnOff] ,1 as [isChanged] 
into #group_all
from #group_sales 
union all

select [period] --,getdate() as rdate ,cast(getdate() as date) as accdate 
		,[Indicator] ,N'Факт' [Факт/План] ,[Value] --,[fcValue]
		,null as [dpd] ,1 as [OnOff] ,1 as [isChanged] 
from #group_portf
union all

select [period] --,getdate() as rdate ,cast(getdate() as date) as accdate 
		,[Indicator] ,N'Факт' [Факт/План] ,[Value] --,[fcValue]
		,null as [dpd] ,1 as [OnOff] ,1 as [isChanged] 
from #group_fin

union all

select [period] --,getdate() as rdate ,cast(getdate() as date) as accdate 
		,[Indicator] ,N'Прогноз' [Факт/План] --,[Value]
		,[fcValue]
		,null as [dpd] ,1 as [OnOff] ,1 as [isChanged] 
from #group_sales 
union all

select [period] --,getdate() as rdate ,cast(getdate() as date) as accdate 
		,[Indicator] ,N'Прогноз' [Факт/План] --,[Value] 
		,[fcValue]
		,null as [dpd] ,1 as [OnOff] ,1 as [isChanged] 
from #group_portf
union all

select [period] --,getdate() as rdate ,cast(getdate() as date) as accdate 
		,[Indicator] ,N'Прогноз' [Факт/План] --,[Value]
		,[fcValue]
		,null as [dpd] ,1 as [OnOff] ,1 as [isChanged] 
from #group_fin
union all

select [period] --,getdate() as rdate ,cast(getdate() as date) as accdate 
		,[Indicator] ,N'Факт' [Факт/План] ,[Value] --,[fcValue]
		,[dpd] ,0 as [OnOff] ,1 as [isChanged] 
from #portf_backet

--select * from #group_all


begin tran

declare @currdate date, @rdate as datetime
set @currdate = case when datepart(hh,getdate())<23 then cast(dateadd(day,-1,getdate()) as date) else cast(getdate() as date) end;
set @rdate = getdate();

delete 
--select *
from [dwh_new].[dbo].[mt_report_carmoney_kpi] 
 where --[OnOff]=1 and 
 [Факт/План] in (N'Факт', N'Прогноз')
		and [accdate]>=case when datepart(hh,getdate())<23 then cast(dateadd(day,-1,getdate()) as date) else cast(getdate() as date) end

insert into [dwh_new].[dbo].[mt_report_carmoney_kpi]  ([period] ,[rdate] ,[accdate] ,[Indicator] ,[Факт/План] ,[Value] ,[dpd] ,[OnOff] ,[isChanged])

select [period] ,@rdate as rdate ,@currdate as accdate 
		,[Indicator] ,[Факт/План] ,[Value]
		,[dpd] ,[OnOff] , [isChanged]  
from #group_all
--where [accdate]>=case when datepart(hh,getdate())<23 then cast(dateadd(day,-1,getdate()) as date) else cast(getdate() as date) end

commit tran

--select * from [dwh_new].[dbo].[mt_report_carmoney_kpi] order by accdate desc
	
END

