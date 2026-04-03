-- =============================================
-- Author:		Курдин С.В.
-- Create date: 2019-05-22
-- Description:	Таблица содержит информацию о состоянии взаиморасчетов в ЦМР по выданным займа
--				
-- =============================================
CREATE PROCEDURE [etl].[base_etl_a_loan_status_days_cmr]
	-- Add the parameters for the stored procedure here
--	@ForDate datetime =cast(getdate() as date)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @DateStart datetime,
		@DateStart2 datetime,
		@DateStart2000 datetime,
		@DateStartCurr datetime,
		@DateStartCurr2000 datetime
set @DateStart=	dateadd(MONTH,datediff(MONTH,0,dateadd(month,-43,dateadd(year,2000,Getdate()))),0)	--dateadd(MONTH,datediff(MONTH,0,dateadd(month,-43,Getdate())),0)
--dateadd(day,-datediff(day,cast('20170101' as datetime),getdate()),getdate())
--dateadd(month,datediff(month,0,GetDate()),-720);
--dateadd(day,datediff(day,0,GetDate()-2),0);
set	@DateStart2=dateadd(year,2000,@DateStart);
set @DateStart2000= dateadd(day,datediff(day,0,dateadd(year,2000,dateadd(day,-10,Getdate()))),0);
set @DateStartCurr=dateadd(day,0,dateadd(day,datediff(day,0,Getdate()),0));	-- Переменная для начала (дня) оперативного обновления данных по периоду статуса за последние 14 дней для поля с текущей датой
set @DateStartCurr2000=dateadd(day,-14,dateadd(day,datediff(day,0,dateadd(year,2000,Getdate())),0));	-- Переменная для начала (дня) оперативного обновления данных по периоду статуса за последние 14 дней для поля с текущей датой + 2000

--delete from [dwh_new].[dbo].[mt_credit_portfolio_cmr_v2] 
--where [ДатаОбновленияЗаписи] >= @DateStartCurr;

if OBJECT_ID('[dwh_new].[dbo].[a_loan_status_days_cmr]') is not null
drop table [dwh_new].[dbo].[a_loan_status_days_cmr];
--truncate table [dwh_new].[dbo].[a_loan_status_days_cmr];

create table [dwh_new].[dbo].[a_loan_status_days_cmr]
(
[ДатаУчета] datetime null 
,[Договор] binary(16) null 
,[ДоговорНомер] nvarchar(255) null 
,[СтатусСсылка] binary(16) null 
,[СтатусПоДнямНаимИсх] nvarchar(255) null 
,[СтатусПоДням] binary(16) null 
,[СтатусПоДнямНаим] nvarchar(255) null 
,[КолвоПолнДнПросрочки]  numeric(7,0) null
,[ДатаВозникновенияПросрочки] datetime null
,[Бакет_cmr] nvarchar(50) null															

--,[Активен_cmr] int null
--,[Обслуживается_cmr] int null
);

with cmr_st as
(
select d.[Ссылка] as [Договор] ,d.[Код] as [ДоговорНомер] ,d.[Сумма]
	   ,r.[ДатаУчета]

from [Stg].[_1cCMR].[Справочник_Договоры] d with (nolock)
left join  [Stg].[dbo].[aux_CreditPortfCMR_Acc] r with (nolock)
on d.[Ссылка]=r.[Договор]
--where r.[ДатаУчета] > = dateadd(day,datediff(day,0,dateadd(day,-11,Getdate())),0);			--not r.[Договор] is null
--order by r.[ДатаУчета] desc
)
,	cmr_StatusName as
(
select [Ссылка] ,[Наименование]
from [Stg].[_1cCMR].[Справочник_СтатусыДоговоров] sd with (nolock))
, cmr_st0 as
(
select r.[ДатаУчета] ,r.[Договор] ,s.[Статус] ,r.[ДоговорНомер]
		,LAG(s.[Статус]) over(partition by r.[Договор] order by r.[ДатаУчета]) as [ДопСтатус]
		,case when [Статус] is null then 0 else 1 end as [СчетчикГруппыСтатусов]
		,p.[КоличествоПолныхДнейПросрочки] ,p.[ДатаВозникновенияПросрочки]
		,case
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)=0 then N'Непросроченный'
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>0 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<4 then N'_1-3' --N'a' -- N'_1-3' --
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>3 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<31 then N'_4-30' --N'b' -- N'_4-30' --
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>30 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<61 then N'31-60' --N'c' -- N'31-60' --
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>60 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<91 then N'61-90' --N'd' -- N'61-90' --
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>90 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<121 then N'91-120' --N'f' -- N'91-120' --
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>120 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<151 then N'121-150' --N'g' -- N'121-150' --
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>150 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<181 then N'151-180' --N'h' -- N'151-180' --
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>180 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<211 then N'181-210' --N'' -- N'181-210' --
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>210 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<241 then N'211-240'
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>240 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<271 then N'241-270' --N'' -- N'241-270' --
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>270 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<301 then N'271-300' --
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>300 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<331 then N'301-330' --
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>330 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<361 then N'331-360'
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>360 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<391 then N'361-390'
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>390 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<421 then N'391-420'
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>420 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<451 then N'421-450'
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>450 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<481 then N'451-480'
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>480 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<511 then N'481-510'
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>510 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<541 then N'511-540'
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>540 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<571 then N'541-570'
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>570 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<601 then N'571-600'
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>600 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<631 then N'601-630'
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>630 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<661 then N'631-660'
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>660 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<691 then N'661-690'
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>690 and isnull(p.[КоличествоПолныхДнейПросрочки],0)<721 then N'691-720'
			when isnull(p.[КоличествоПолныхДнейПросрочки],0)>720 then N'Более 720'
		end as [Бакет_cmr]
from cmr_st r
left join (select dateadd(day,datediff(day,0,dateadd(year,-2000,[Период])),0) as [ДатаУчета] ,[Договор] ,[Статус] from [Stg].[_1cCMR].[РегистрСведений_СтатусыДоговоров] with (nolock)) s
on r.[ДатаУчета]=s.[ДатаУчета] and r.[Договор]=s.[Договор]
left join (select distinct dateadd(day,datediff(day,0,dateadd(year,-2000,[Период])),0) as [ДатаУчета] ,[Договор] 
				  ,[КоличествоПолныхДнейПросрочки] ,[ДатаВозникновенияПросрочки] ,[ПросроченнаяЗадолженность] 
		   from [Stg].[_1cCMR].[РегистрСведений_АналитическиеПоказателиМФО] with (nolock)
		   ) p
on r.[ДатаУчета]=p.[ДатаУчета] and r.[Договор]=p.[Договор]
)
,	cmr_GroupOfStatuses as
(
select [ДатаУчета] ,cmr_st0.[Договор] ,[ДоговорНомер] ,[Статус]
		,sum([СчетчикГруппыСтатусов]) over(partition by cmr_st0.[Договор] order by [ДатаУчета]
						rows between unbounded preceding and current row) as [ГруппаСтатуса]  
		,[КоличествоПолныхДнейПросрочки] ,[ДатаВозникновенияПросрочки]
		,sn.[Наименование] as [СтатусПоДнямНаимИсх] 
		,[Бакет_cmr]
from cmr_st0 --order by [ДатаУчета] desc
left join cmr_StatusName sn
on cmr_st0.[Статус]=sn.[Ссылка]
)
,	cmr_StatOnDay as
(
select [ДатаУчета] ,[Договор] ,[ДоговорНомер] ,[Статус] as [СтатусСсылка] ,[СтатусПоДнямНаимИсх]
		--,[ГруппаСтатуса]
		,first_value([Статус]) over(partition by [Договор] ,[ГруппаСтатуса] order by [ДатаУчета]) as [СтатусПоДням]
		,first_value([СтатусПоДнямНаимИсх]) over(partition by [Договор] ,[ГруппаСтатуса] order by [ДатаУчета]) as [СтатусПоДнямНаим]
		,[КоличествоПолныхДнейПросрочки] ,[ДатаВозникновенияПросрочки] 
		,[Бакет_cmr]
from cmr_GroupOfStatuses
)

insert into [dwh_new].[dbo].[a_loan_status_days_cmr] ([ДатаУчета] ,[Договор] ,[ДоговорНомер]
															,[СтатусСсылка] ,[СтатусПоДнямНаимИсх]
															,[СтатусПоДням] ,[СтатусПоДнямНаим]
															,[КолвоПолнДнПросрочки] ,[ДатаВозникновенияПросрочки]
															,[Бакет_cmr])
select distinct * from cmr_StatOnDay 
order by [ДатаУчета] desc ,[ДоговорНомер] desc
--where [Договор] is null

END

