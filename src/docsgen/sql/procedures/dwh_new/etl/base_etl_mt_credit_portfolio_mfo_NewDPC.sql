

-- =============================================
-- Author:		КУрдин С.В.
-- Create date: 2019-05-22
-- Description:	Таблица "ЗАЙМЫ" содержит информацию о выданных займах, их текущих статусах,
--				дате заявки, дате выдачи, точке входа, точке партнера, Агенте партнера, сумме доп услуг по договору
-- exec [etl].[base_etl_mt_credit_portfolio_mfo_NewDPC]
-- =============================================
CREATE PROCEDURE [etl].[base_etl_mt_credit_portfolio_mfo_NewDPC]
	-- Add the parameters for the stored procedure here
--	@ForDate datetime =cast(getdate() as date)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		--24.03.2020
	SET DATEFIRST 1;

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

delete from [dwh_new].[dbo].[mt_credit_portfolio_mfo] 
where [ДатаОбновленияЗаписи] >= @DateStartCurr;

--if OBJECT_ID('[dwh_new].[dbo].[mt_credit_portfolio_mfo]') is not null
--drop table [dwh_new].[dbo].[mt_credit_portfolio_mfo];

--create table [dwh_new].[dbo].[mt_credit_portfolio_mfo]
--(
--[ДатаОбновленияЗаписи] datetime null 
--,[ПериодУчетаЧислом] int null
--,[ПериодУчета] datetime2 null
--,[Ссылка] binary(16) null
--,[ДатаОперации] datetime null 
--,[ДоговорНомер] nvarchar(255) null	
--,[ДоговорНомерМФО] nvarchar(255) null
--,[Договор] binary(16) null

--,[Фамилия] nvarchar(255) null
--,[Имя] nvarchar(255) null
--,[Отчество] nvarchar(255) null
--,[ДатаРождения] date null 

--,[ДатаВыдачиДоговора]  datetime null 
--,[ДатаОкончанияДоговора] datetime  null

--,[ПервичнаяСумма] decimal(15,2)  null
--,[СуммаДоговора] decimal(15,2) null
--,[СуммаДопПродуктов] decimal(15,2) null
--,[СуммаБезДопУслуг] decimal(15,2) null
--,[СуммаОДОплачено] decimal(15,2) null
--,[ОстатокОД] decimal(15,2) null
--,[Колво] decimal(15,2)  null

--,[Срок] int null
--,[ПроцентнаяСтавка] decimal(15,2)  null
--,[КредитныйПродукт] nvarchar(255)  null

--,[Докредитование] nvarchar(255) null
--,[Повторность] nvarchar(255) null
--,[ДатаПогашПервДог] datetime null 
--,[ПовторностьNew] nvarchar(255) null 

--,[ТочкаКод] nvarchar(255) null	
--,[Точка] nvarchar(255) null
--,[ВыезднойМенеджер] nvarchar(255) null

--,[Регион] nvarchar(255) null
--,[Регион2] nvarchar(255) null
--,[РОРегион] nvarchar(255) null
--,[Дивизион] nvarchar(255) null
--,[Агент] nvarchar(255)  null
--,[АгентМФО] nvarchar(255)  null

-- ,[НомерГрафика] int null

-- ,[ДатаНачала] datetime  null
-- ,[ДатаДоговора] datetime  null
-- ,[ДеньНедели] int  null

-- ,[Неделя] int  null
-- ,[ДеньМесяца] int  null
-- ,[Месяц] int  null
-- ,[Год] int  null

-- ,[НаименованиеЛиста] nvarchar(255) null
-- ,[НаименованиеПараметра] nvarchar(255) null

-- ,[ПериодичностьОтчета] nvarchar(255) null

-- ,[Когорта] nvarchar(255)  null

-- ,[ВидДоговора] nvarchar(255) null
-- ,[ТекСтатусМФО] binary(16) null
-- ,[СтатусНаим] nvarchar(255) null
-- ,[Лидогенератор] binary(16) null

-- ---- дополнительно
--,[КаналМФО_ТочкаВх] nvarchar(255) null
--,[ТочкаВходаЗаявки] nvarchar(255) null
--,[МестоСоздЗаявки] nvarchar(255) null
--,[СпособВыдачиЗайма] nvarchar(255) null
--,[ЕстьОсновнаяЗаявка] nvarchar(255) null
--,[ЗаявкаНомер] nvarchar(255) null
--,[ТекСтатусЗаявки] nvarchar(255) null
--,[ЗаявкаСсылка] binary(16) null
--,[ИсточникДанных] nvarchar(50) null
--,[КолвоПолнДнПроср] numeric(7,0) null
--);

--with t0 as -- Сумма поступившая в счет погашения долга
--(
drop table if exists #t0
SELECT [Договор] ,sum([Сумма]) as [СуммаОДОплачено]
into #t0
FROM [prodsql02].[mfo].[dbo].[РегистрНакопления_ГП_ОстаткиЗаймов]  with (nolock)

where [Период]<dateadd(year,2000,dateadd(day,datediff(day,0,Getdate()),0))
--		and dateadd(year,-2000,oz.[Период]) >= dateadd(month,datediff(month,0,Getdate()),0)
		and [ВидДвижения]=0
		and [Вид]=0xA3DBD252B629EFDE45312018E2F4C5DF  --ОД
group by  [Договор]
--)

--,  bkt as  -- разбивка договоров по бакетам просрочки
--(
drop table if exists #bkt
select 
cn0.[Договор]
,cn0.[КоличествоПолныхДнейПросрочки] as [КолвоПолнДнПроср]
,case
	when [КоличествоПолныхДнейПросрочки] =0 then N'Непросроченный'
	when cn0.[КоличествоПолныхДнейПросрочки]>0 and cn0.[КоличествоПолныхДнейПросрочки]<4 then N'_1-3' --N'a' -- N'_1-3' --
	when cn0.[КоличествоПолныхДнейПросрочки]>3 and cn0.[КоличествоПолныхДнейПросрочки]<31 then N'_4-30' --N'b' -- N'_4-30' --
	when cn0.[КоличествоПолныхДнейПросрочки]>30 and cn0.[КоличествоПолныхДнейПросрочки]<61 then N'31-60' --N'c' -- N'31-60' --
	when cn0.[КоличествоПолныхДнейПросрочки]>60 and cn0.[КоличествоПолныхДнейПросрочки]<91 then N'61-90' --N'd' -- N'61-90' --
	when cn0.[КоличествоПолныхДнейПросрочки]>90 and cn0.[КоличествоПолныхДнейПросрочки]<121 then N'91-120' --N'f' -- N'91-120' --
	when cn0.[КоличествоПолныхДнейПросрочки]>120 and cn0.[КоличествоПолныхДнейПросрочки]<151 then N'121-150' --N'g' -- N'121-150' --
	when cn0.[КоличествоПолныхДнейПросрочки]>150 and cn0.[КоличествоПолныхДнейПросрочки]<181 then N'151-180' --N'h' -- N'151-180' --
	when cn0.[КоличествоПолныхДнейПросрочки]>180 and cn0.[КоличествоПолныхДнейПросрочки]<211 then N'181-210' --N'' -- N'181-210' --
	when cn0.[КоличествоПолныхДнейПросрочки]>210 and cn0.[КоличествоПолныхДнейПросрочки]<241 then N'211-240'
end as [Бакет]
into #bkt
from [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_АналитическиеПоказателиЗайма_ИтогиСрезПоследних] cn0  with (nolock)
where cn0.[КоличествоПолныхДнейПросрочки]<241

union all

select 
cn1.[Договор]
,cn1.[КоличествоПолныхДнейПросрочки] as [КолвоПолнДнПроср]
,case
	when cn1.[КоличествоПолныхДнейПросрочки]>240 and cn1.[КоличествоПолныхДнейПросрочки]<271 then N'241-270' --N'' -- N'241-270' --
	when cn1.[КоличествоПолныхДнейПросрочки]>270 and cn1.[КоличествоПолныхДнейПросрочки]<301 then N'271-300' --
	when cn1.[КоличествоПолныхДнейПросрочки]>300 and cn1.[КоличествоПолныхДнейПросрочки]<331 then N'301-330' --
	when cn1.[КоличествоПолныхДнейПросрочки]>330 and cn1.[КоличествоПолныхДнейПросрочки]<361 then N'331-360'
	when cn1.[КоличествоПолныхДнейПросрочки]>360 and cn1.[КоличествоПолныхДнейПросрочки]<391 then N'361-390'
	when cn1.[КоличествоПолныхДнейПросрочки]>390 and cn1.[КоличествоПолныхДнейПросрочки]<421 then N'391-420'
	when cn1.[КоличествоПолныхДнейПросрочки]>420 and cn1.[КоличествоПолныхДнейПросрочки]<451 then N'421-450'
	when cn1.[КоличествоПолныхДнейПросрочки]>450 and cn1.[КоличествоПолныхДнейПросрочки]<481 then N'451-480'
	when cn1.[КоличествоПолныхДнейПросрочки]>480 and cn1.[КоличествоПолныхДнейПросрочки]<511 then N'481-510'
	when cn1.[КоличествоПолныхДнейПросрочки]>510 and cn1.[КоличествоПолныхДнейПросрочки]<541 then N'511-540'
end as [Бакет]
from [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_АналитическиеПоказателиЗайма_ИтогиСрезПоследних] cn1  with (nolock)
where cn1.[КоличествоПолныхДнейПросрочки]>240 and cn1.[КоличествоПолныхДнейПросрочки]<541 

union all

select
cn2.[Договор]
,cn2.[КоличествоПолныхДнейПросрочки] as [КолвоПолнДнПроср]
,case
	when cn2.[КоличествоПолныхДнейПросрочки]>540 and cn2.[КоличествоПолныхДнейПросрочки]<571 then N'541-570'
	when cn2.[КоличествоПолныхДнейПросрочки]>570 and cn2.[КоличествоПолныхДнейПросрочки]<601 then N'571-600'
	when cn2.[КоличествоПолныхДнейПросрочки]>600 and cn2.[КоличествоПолныхДнейПросрочки]<631 then N'601-630'
	when cn2.[КоличествоПолныхДнейПросрочки]>630 and cn2.[КоличествоПолныхДнейПросрочки]<661 then N'631-660'
	when cn2.[КоличествоПолныхДнейПросрочки]>660 and cn2.[КоличествоПолныхДнейПросрочки]<691 then N'661-690'
	when cn2.[КоличествоПолныхДнейПросрочки]>690 and cn2.[КоличествоПолныхДнейПросрочки]<721 then N'691-720'
	when cn2.[КоличествоПолныхДнейПросрочки]>720 then N'Более 720'
end as [Бакет]
from [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_АналитическиеПоказателиЗайма_ИтогиСрезПоследних] cn2  with (nolock)
where cn2.[КоличествоПолныхДнейПросрочки]>540 

--) 

--,	t1 as -- Остаток задолженности на текущую дату
--(
drop table if exists #t1
select d.[Ссылка] ,d.[Номер] 
	  ,d.[Фамилия] as [Фамилия]
	  ,d.[Имя] as [Имя]
	  ,d.[Отчество] as [Отчество]
	  ,d.[ДатаРождения] as [ДатаРождения]
	  ,d.[Сумма]	  
	  ,d.[СуммаДополнительныхУслуг]
	  ,t0.[СуммаОДОплачено]

	  ,(d.[Сумма]-isnull(t0.[СуммаОДОплачено],0)) as [ОстатокОД]
	  ,d.[Срок]
	  ,case when d.[ПроцентнаяСтавка]<>0 then d.[ПроцентнаяСтавка] else kp.[ТекущаяСсуда] end as [ПроцентнаяСтавка]
	  ,kp.[Наименование] as [КредитныйПродукт]
	  ,dk.[Имя] as [Докредитование]

	  ,o.[Код] as [ТочкаКод]
	  ,o.[Ссылка] as [ТочкаСсылка]
	  ,o.[Наименование] as [Точка]
	  ,case when o.[ВыезднойМенеджер]=0x01 then N'ВыезднойМенеджер' else N'' end as [ВыезднойМенеджер]

	  ,cl.[Наименование] as [Агент]
	  ,cl.[Наименование] as [АгентМФО]
	  
	  ,d.[Дата]

	  ,b.[КолвоПолнДнПроср]
	  ,case when b.[Бакет] is null then N'Непросроченный' else b.[Бакет] end as [Бакет]
	  
	  ,dll.[ПериодСтатуса] ,dll.[СтатусСсылка] ,dll.[ТекСтатус]
--	  ,d.[дз_ДатаПродажиДоговора]
--	  ,case 
--			where cast(d.[дз_ДатаПродажиДоговора] as datetime) = N'2001-01-01 00:00:00.000' then null 
--			else dateadd(year,-2000,d.[дз_ДатаПродажиДоговора]) 
--	   end as [ДатаПродажиДоговора]
	  ,d.[Заявка]
	  ,d.[Контрагент]

into #t1
from [prodsql02].[mfo].[dbo].[Документ_ГП_Договор] d  with (nolock)
	left join #t0 t0
	on t0.[Договор]=d.[Ссылка]
	
	left join (select dll0.[Договор] ,dll0.[Период] as [ПериодСтатуса] ,dll1.[Ссылка] as [СтатусСсылка] ,dll1.[Наименование] as [ТекСтатус]
			   from [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокДоговоров_ИтогиСрезПоследних] dll0  with (nolock)
			   left join [prodsql02].[mfo].[dbo].[Справочник_ГП_СтатусыДоговоров] dll1  with (nolock)
			   on dll0.[Статус]=dll1.[Ссылка]) dll
	on d.[Ссылка]=dll.[Договор]

	left join [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_АналитическиеПоказателиЗайма_ИтогиСрезПоследних] ap  with (nolock)
	on d.[Ссылка]=ap.[Договор]

	left join [prodsql02].[mfo].[dbo].[Справочник_ГП_КредитныеПродукты] kp  with (nolock)
	on d.[КредитныйПродукт]=kp.[Ссылка]

	left join [prodsql02].[mfo].[dbo].[Перечисление_ВидыДокредитования] dk with (nolock)
	on d.[Докредитование]=dk.[Ссылка]

	left join [prodsql02].[mfo].[dbo].[Справочник_ГП_Офисы] o with (nolock)
	on d.[Точка]=o.[Ссылка]

	left join [prodsql02].[mfo].[dbo].[Справочник_Контрагенты] cl with (nolock)
	on o.[Партнер]=cl.[Ссылка]

	left join #bkt b
	on d.[Ссылка]=b.[Договор]

where d.[ПометкаУдаления]=0x00 
		and d.[дз_ДатаПродажиДоговора]='2001-01-01 00:00:00.000' -- дата продажи договора договор не продан
		and not dll.[СтатусСсылка] in (0x8B9EA19EB317EBEC488EBC2FF031FF35 -- договор Зарегистрирован
									   ,0x92DEFAEB96D38A58436D2DDC3CBD71AF -- договор Аннулирован
									   ,0xB074EC051022E2274B7AA44702431457 -- договор Погашен
									  --  ,0x8E3D13AB5F879408487A2A67D0C48E59 -- договор Действует
									  -- ,0xB10FFD63A822FFA54AFA23D4C527B9F0 -- договор Платеж опаздывает
									  -- ,0xBF104B01284EDD134BCFD40ADA0C7EF7 -- договор Проcрочен
									  -- ,0xA897F7B3F077CB034E9CC0DF90C817E1 -- договор Проблемный
									   ) 
--)

--,	tabl2 as
--(
drop table if exists #tabl2
select 
t1.[Ссылка] 
,t1.[Номер]
,t1.[Фамилия]
,t1.[Имя]
,t1.[Отчество]
,t1.[ДатаРождения]

,t1.[Сумма]
,t1.[СуммаДополнительныхУслуг]
,t1.[СуммаОДОплачено]
,t1.[ОстатокОД]
,1 as [Колво]

,t1.[Срок]
,t1.[ПроцентнаяСтавка]
,t1.[КредитныйПродукт]

,t1.[Докредитование]

,t1.[ТочкаКод]
,t1.[ТочкаСсылка]
,t1.[Точка]
,t1.[ВыезднойМенеджер]

,t1.[Агент]
,t1.[АгентМФО]


,t1.[Дата]

,t1.[КолвоПолнДнПроср]
,cast(t1.[Бакет] as nvarchar(50)) as [НаименованиеПараметра]

,t1.[СтатусСсылка] as [СтатусДоговора]
,t1.[ТекСтатус] as [ДоговорТекСтатус]

,datepart(wk,getdate())as [Неделя]


,N'Ежедневный' as [ПериодичностьОтчета]


,getdate() as [ДатаОперации]

,datepart(dw,getdate()) as [ДеньНедели]
,datediff(day,0,dateadd(MONTH,datediff(MONTH,0,getdate()),0))+2 as [ПериодУчетаЧислом]
,0 as [ПервичнаяСумма]
,t1.[Заявка]
,t1.[Контрагент]
into #tabl2
from #t1 t1 
--)

----------------------------------------------------------------------------
----------------------------------------------------------------------------
------ ДЛЯ БИЗНЕС-ЗАЙМОВ (УМФО)
--,	BusinessLoan_UMFO as
--(
drop table if exists #BusinessLoan_UMFO
select dd.[Ссылка]
      ,dd.[Дата]
	  ,dd.[ФинансовыйПродукт]
	  ,fp.[Наименование] as [КредитныйПродукт]
      ,dd.[СрокЗайма]
      ,dd.[СуммаЗайма]
      ,dd.[ПроцентнаяСтавка]
      ,dd.[НомерДоговора]
into #BusinessLoan_UMFO
  from [Stg].[_1cUMFO].[Документ_АЭ_ЗаймПредоставленный] dd  with (nolock)--y
    left join [Stg].[_1cUMFO].[Справочник_АЭ_ФинансовыеПродукты] fp  with (nolock)--y
	on dd.[ФинансовыйПродукт]=fp.[Ссылка]
  where dd.[ПометкаУдаления]=0x00 AND dd.[Проведен]=0x01 and fp.[Наименование] like N'Бизнес%займ%'
--)

--,	Repayment_UMFO as 
-- (
 drop table if exists #Repayment_UMFO
-- сумма выплачено погашено ОД
SELECT dateadd(MONTH,datediff(MONTH,0,dateadd(day,-1,getdate())),0) as [ПериодУчета] 
	  ,dateadd(year,-2000,cast(rgpln.[Период] as datetime2)) as [Период]
      ,rgpln.[Регистратор_ТипСсылки]
      ,rgpln.[Регистратор_Ссылка]
	  ,N'' as [ТипДокумента]
      ,rgpln.[НомерСтроки]
      ,rgpln.[Активность]
	  ,1 as [ВидДвижения]
	  ,N'' as [ВидДвиженияНаим]
--      ,rgpln.[СчетДт]
--	  ,pln1.[Код] as [СчетДт_Код]
--	  ,pln2.[Код] as [СчетКт_Код]
	  ,t2j.[Контрагент]
	  ,t2j.[Займ]
	  ,dd0.[НомерДоговора] as [НомерДоговора]
--      ,rgpln.[СчетАналитическогоУчетаДт]
--      ,rgpln.[СчетАналитическогоУчетаКт]
      ,null as [ВидНачисления]
	  ,N'Основной долг' as [ВидНачисленияНаим]
      ,dateadd(year,-2000,cast(rgpln.[Период] as datetime2)) as [ДатаПлатежа]
	  ,dateadd(year,-2000,dateadd(MONTH,datediff(MONTH,0,cast(rgpln.[Период] as datetime2)),0)) as [ПериодУчетаДатаПлатежа]
	  ,0 as [СуммаПриход]
	  ,rgpln.[Сумма] as [СуммаРасход]
      ,rgpln.[Сумма] as [Сумма]

 --     ,rgpln.[Содержание]
--      ,rgpln.[EDHashDt]
--      ,rgpln.[EDHashCt]
--	  ,isnull(rgpln.[EDHashDt],0)+isnull(rgpln.[EDHashCt],0) as [Остаток]
into #Repayment_UMFO
from [C2-VSR-SQL04].[UMFO].[dbo].[РегистрБухгалтерии_БНФОБанковский] rgpln  with (nolock)
	left join  [C2-VSR-SQL04].[UMFO].[dbo].[ПланСчетов_БНФОБанковский] pln1 with (nolock)
		on rgpln.[СчетДт]=pln1.[Ссылка]
	left join  [C2-VSR-SQL04].[UMFO].[dbo].[ПланСчетов_БНФОБанковский] pln2 with (nolock)
		on rgpln.[СчетКт]=pln2.[Ссылка]
--	left join [C1-VSR-SQL05].[UMFO_NIGHT00].[dbo].[Документ_АЭ_ПогашениеПоЗаймамПредоставленным] doc1
--		on rgpln.[Регистратор_Ссылка]=doc1.[Ссылка]	
	left join (	select zp.[Регистратор_Ссылка] ,zp.[Займ] ,zp.[Контрагент] 
				from  [C2-VSR-SQL04].[UMFO].[dbo].[РегистрНакопления_АЭ_ВзаиморасчетыПоЗаймамПредоставленным] zp with (nolock)
				where zp.[Займ] in (select [Ссылка] from #BusinessLoan_UMFO) 
				group by zp.[Регистратор_Ссылка] ,zp.[Займ] ,zp.[Контрагент]
				) t2j
		on  rgpln.[Регистратор_Ссылка]=t2j.[Регистратор_Ссылка]
		left join  [C2-VSR-SQL04].[UMFO].[dbo].[Документ_АЭ_ЗаймПредоставленный] dd0 with (nolock)
		on t2j.[Займ]=dd0.[Ссылка]
where	t2j.[Займ] in (select [Ссылка] from #BusinessLoan_UMFO)	
--		and rgpln.[Период]>='4019-06-08'
		--and pln1.[Код] in ('49401','48701') or 
		and pln2.[Код] in ('49401','48701')
	   

union all


select dateadd(year,-2000,dateadd(MONTH,datediff(MONTH,0,ras.[Период]),0)) as [ПериодУчета] 
	  ,dateadd(year,-2000,cast(ras.[Период] as datetime2)) as [Период]
      ,ras.[Регистратор_ТипСсылки]
      ,ras.[Регистратор_Ссылка]
	  ,case when [Регистратор_ТипСсылки]=0x0000969A then N'??? Погашение займов'
			when [Регистратор_ТипСсылки]=0x000093A0 then N'??? Выдача займов'
	  end as [ТипДокумента]
      ,ras.[НомерСтроки]
      ,ras.[Активность]
      ,ras.[ВидДвижения]
	  ,case when ras.[ВидДвижения]=0 then N'Приход' else N'Расход' end as [ВидДвиженияНаим]
--      ,[Организация]
      ,ras.[Контрагент]
--	  ,cl.[Наименование] as [КонтрагентНаим]
      ,ras.[Займ]
	  ,d.[НомерДоговора] as [НомерДоговора]
      ,ras.[ВидНачисления]
	  ,vid.[Наименование] as [ВидНачисленияНаим]
      ,dateadd(year,-2000,cast([ДатаПлатежа] as datetime2)) as [ДатаПлатежа]
	  ,dateadd(year,-2000,dateadd(MONTH,datediff(MONTH,0,cast(ras.[ДатаПлатежа] as datetime2)),0)) as [ПериодУчетаДатаПлатежа]
	  ,case when ras.[ВидДвижения]=0 then ras.[Сумма] else 0 end as [СуммаПриход]
	  ,case when ras.[ВидДвижения]=1 then ras.[Сумма] else 0 end as [СуммаРасход]
      ,ras.[Сумма]
--      ,[ПодразделениеОрганизации]
from [C2-VSR-SQL04].[UMFO].[dbo].[РегистрНакопления_АЭ_ВзаиморасчетыПоГрафикуЗаймовПредоставленных] ras with (nolock)
	left join [Stg].[_1cUMFO].[Справочник_АЭ_ВидыНачисленийПоЗаймам] vid with (nolock)
		on ras.[ВидНачисления]=vid.[Ссылка]
	left join [C2-VSR-SQL04].[UMFO].[dbo].[Справочник_Контрагенты] cl with (nolock)
		on ras.[Контрагент]=cl.[Ссылка]
	left join [Stg].[_1cUMFO].[Документ_АЭ_ЗаймПредоставленный] d with (nolock)
		on ras.[Займ]=d.[Ссылка]
--  left join (
--			) ost
where ras.[Займ] in (select [Ссылка] from #BusinessLoan_UMFO) 
		and ras.[ВидНачисления]<>0x9B7650E549564EF611E720526D97FF6F --and ras.[Период]>='4019-05-01 00:00:00' --and ras.[ВидДвижения]=1


union all

-- сумма погашенных Пени
select dateadd(year,-2000,dateadd(MONTH,datediff(MONTH,0,vsh.[Период]),0)) as [ПериодУчета] 
      ,dateadd(year,-2000,cast(vsh.[Период] as datetime2)) as [Период]
	  ,vsh.[Регистратор_ТипСсылки]
      ,vsh.[Регистратор_Ссылка]
	  ,case 
			when vsh.[Регистратор_ТипСсылки]=0x00000338 then N'Корректировка взаиморасчетов'
			when vsh.[Регистратор_ТипСсылки]=0x0000A5E4 then N'Списание(прощение) займа'
			when vsh.[Регистратор_ТипСсылки]=0x0000969A then N'Погашение займа'
	  end as [ТипДокумента]
      ,vsh.[НомерСтроки]
      ,vsh.[Активность]
      ,vsh.[ВидДвижения]
	  ,case when vsh.[ВидДвижения]=0 then N'Приход' else N'Расход' end as [ВидДвиженияНаим]
      ,vsh.[Контрагент]	  	  
      ,vsh.[Займ]
	  ,d2.[НомерДоговора] as [НомерДоговора]
      ,vsh.[ВидНачисления]
	  ,vn.[Наименование] as [ВидНачисленияНаим]
      ,dateadd(year,-2000,cast(vsh.[ДатаПлатежа] as datetime2)) as [ДатаПлатежа]
	  ,dateadd(year,-2000,dateadd(MONTH,datediff(MONTH,0,cast(vsh.[ДатаПлатежа] as datetime2)),0)) as [ПериодУчетаДатаПлатежа]
	  ,case when vsh.[ВидДвижения]=0 then vsh.[Сумма] else 0 end as [СуммаПриход]
	  ,case when vsh.[ВидДвижения]=1 then vsh.[Сумма] else 0 end as [СуммаРасход]
      ,vsh.[Сумма]
--      ,vsh.[ПодразделениеОрганизации]

from [C2-VSR-SQL04].[UMFO].[dbo].[РегистрНакопления_АЭ_ВзаиморасчетыПоШтрафамЗаймовПредоставленных] vsh with (nolock)
	left join [Stg].[_1cUMFO].[Справочник_АЭ_ВидыНачисленийПоЗаймам] vn with (nolock)
		on vsh.[ВидНачисления]=vn.[Ссылка]
	left join [Stg].[_1cUMFO].[Документ_АЭ_ЗаймПредоставленный] d2 with (nolock)
		on vsh.[Займ]=d2.[Ссылка]

--    where vsr.[ВидНачисления]<>0x9B7650E549564EF611E720526D97FF6F
where vsh.[Займ] in (select [Ссылка] from #BusinessLoan_UMFO) 
			and vsh.[ВидНачисления]<>0x9B7650E549564EF611E720526D97FF6F --and vsh.[Период]>='4019-05-01'-- and vsh.[ВидДвижения]=1

--)

--,	groupRepayment_UMFO as
--(
drop table if exists #groupRepayment_UMFO
select [ПериодУчета]
      ,[Контрагент]
      ,[Займ]
	  ,[НомерДоговора]
	  ,[ВидНачисленияНаим]
--	  ,[ДатаПлатежа]
--	  ,[ПериодУчетаДатаПлатежа]
	  ,sum([СуммаРасход]) as [Оплачено]
      ,sum([Сумма]) as [Сумма]
into #groupRepayment_UMFO
from #Repayment_UMFO
where [ВидДвижения]=1
group by [ПериодУчета] ,[Контрагент] ,[Займ] ,[НомерДоговора] ,[ВидНачисленияНаим] --,[ПериодУчетаДатаПлатежа]
--)
--,	t_resRepayment_UMFO as
--(
drop table if exists #t_resRepayment_UMFO
select grp.[ПериодУчета]
	 ,bl.[Дата]
	 ,bl.[Ссылка]
	 ,bl.[НомерДоговора]
	 ,bl.[КредитныйПродукт]
	 ,bl.[СрокЗайма]
	 ,case when [ВидНачисленияНаим]=N'Основной долг' or [ВидНачисленияНаим] is null then bl.[СуммаЗайма] else 0 end as [СуммаЗайма]
	 ,case
		when bl.[СуммаЗайма]<=150000 then N'до 150'
		when bl.[СуммаЗайма]>150000 and bl.[СуммаЗайма]<=700000 then N'151-700'
		when bl.[СуммаЗайма]>700000 and bl.[СуммаЗайма]<=1000000 then N'701-1000'
		when bl.[СуммаЗайма]>1000000 then N'более 1000'
		else N'Прочее'
	 end as [Когорта_UMFO]
	 ,case when not grp.[Оплачено] is null then grp.[Оплачено] else 0 end as [Оплачено]
	 ,case when not grp.[ВидНачисленияНаим] is null then grp.[ВидНачисленияНаим] else N'Основной долг' end as [ВидНачисленияНаим]
	 ,case when [ВидНачисленияНаим]=N'Основной долг' or [ВидНачисленияНаим] is null then isnull([СуммаЗайма],0) - isnull(grp.[Оплачено],0) else 0 end as [ОстатокОД]
into #t_resRepayment_UMFO
from #BusinessLoan_UMFO bl
 left join (select *
 		   from #groupRepayment_UMFO
-- 		   where [ВидНачисленияНаим]=N'Основной долг'
 		   ) grp
 on bl.[Ссылка]=grp.[Займ]


 ----------- ОПРЕДЕЛИМ СРОК ЗАДОЛЖЕННОСТИ
-- ,	t0_UMFO as
--(
drop table if exists #t0_UMFO
select --[Период] ,
	   [ВидДвижения]
	  ,[Контрагент]
      ,[Займ]
      ,[ВидНачисления]
      ,[ДатаПлатежа]
      ,sum([Сумма]) as [Сумма]
into #t0_UMFO
from [Stg].[_1cUMFO].[РегистрНакопления_АЭ_ВзаиморасчетыПоГрафикуЗаймовПредоставленных] with (nolock)
where [Займ] in (select distinct [Ссылка] from #BusinessLoan_UMFO)
	  and [ВидДвижения]=0 -- приход/начисление
group by [ВидДвижения] ,[Контрагент] ,[Займ] ,[ВидНачисления] ,[ДатаПлатежа]
--)

--,	t1_UMFO as
--(
drop table if exists #t1_UMFO
select --	  [Период] ,[Регистратор_Ссылка] ,
	  [ВидДвижения]
	  ,[Контрагент]
      ,[Займ]
      ,[ВидНачисления]
      ,[ДатаПлатежа]
      ,sum([Сумма]) as [Сумма]
into #t1_UMFO
from [Stg].[_1cUMFO].[РегистрНакопления_АЭ_ВзаиморасчетыПоГрафикуЗаймовПредоставленных] with (nolock)
where [Займ] in (select distinct [Ссылка] from #BusinessLoan_UMFO)
	  and [ВидДвижения]=1 -- расход/оплачено
group by [ВидДвижения] ,[Контрагент] ,[Займ] ,[ВидНачисления] ,[ДатаПлатежа]
--)
--,	t3_UMFO as
--(
drop table if exists #t3_UMFO
select tu.[Займ] ,dateadd(year,-2000,tu.[ДатаПлатежа]) as [ДатаПлатежа] ,tu.[ВидНачисления]
	  ,tu.[Сумма] as [СуммаНачислено] ,t1u.[Сумма] as [СуммаОплачено]
	  ,(isnull(tu.[Сумма],0)-isnull(t1u.[Сумма],0)) as [СуммаЗадолженности]
into #t3_UMFO
from #t0_UMFO tu
left join #t1_UMFO t1u
	on tu.[Займ]=t1u.[Займ] and tu.[ВидНачисления]=t1u.[ВидНачисления] and tu.[ДатаПлатежа]=t1u.[ДатаПлатежа]
--)

--,	t_Debt_UMFO as		-- График задолженности по ОД
--(
drop table if exists #t_Debt_UMFO
select * into #t_Debt_UMFO from #t3_UMFO
where [ДатаПлатежа]<getdate() and [ВидНачисления]=0x9B7650E549564EF611E720526D97FF6F
--order by [Займ] desc ,[ДатаПлатежа] desc
--)

--,	t_Percent_UMFO as		-- График задолженности1 по процентам
--(
drop table if exists #t_Percent_UMFO
select * into #t_Percent_UMFO from #t3_UMFO
where [ДатаПлатежа]<getdate() and [ВидНачисления]=0x9B7650E549564EF611E720526D97FF70
--order by [Займ] desc ,[ДатаПлатежа] desc
--)

--,	t_resDebtTerm_UMFO as --- результат срока задолженности
--(
drop table if exists #t_resDebtTerm_UMFO
select dateadd(MONTH,datediff(MONTH,0,Getdate()),0) as [ПериодУчета] ,p.[Займ] ,p.[ДатаПлатежа] ,datediff(day, p.[ДатаПлатежа] ,dateadd(day,datediff(day,0,Getdate()),0)) as [ДнПросрочки] ,p.[СуммаЗадолженности]
into #t_resDebtTerm_UMFO
from (select [Займ] ,[ДатаПлатежа]
		     ,[СуммаНачислено] ,[СуммаОплачено]
		     ,[СуммаЗадолженности]
		     ,rank() over(partition by [Займ] order by [ДатаПлатежа] asc) as [rank]
	  from #t_Debt_UMFO
	  where [СуммаОплачено] is null
	  --order by [Займ] desc ,[ДатаПлатежа] desc
	  ) p
where [rank]=1
--)

--,	EnteringTable_UMFO as
--(
drop table if exists #EnteringTable_UMFO
select r.[ПериодУчета] ,r.[Ссылка] ,r.[НомерДоговора] as [Код],r.[КредитныйПродукт] ,r.[СрокЗайма] ,r.[СуммаЗайма] ,r.[Оплачено] ,r.[ВидНачисленияНаим] ,r.[ОстатокОД] 
		,isnull(dt.[ДнПросрочки],0) as [КоличествоПолныхДнейПросрочки] ,dt.[СуммаЗадолженности]
into #EnteringTable_UMFO 
 from #t_resRepayment_UMFO r
 left join #t_resDebtTerm_UMFO dt
 on r.[Ссылка]=dt.[Займ] and r.[ПериодУчета]=dt.[ПериодУчета]
 --)

-----------------------------------------------
--,	TempTable_CollectingPayIn_UMFO as
--(
drop table if exists #TempTable_CollectingPayIn_UMFO
select 
	[Код] as [ДоговорНомер]
	,[Ссылка] as [ДоговорСсылка]
	,[ПериодУчета] as [Период]

	,[Ссылка] as [Договор]


	,[КоличествоПолныхДнейПросрочки] as [КолвоПолнДнПросрочки]
	,[КоличествоПолныхДнейПросрочки] as [ДниПросрочки]
	,case
		when [КоличествоПолныхДнейПросрочки] =0 then N'Непросроченный'
		when [КоличествоПолныхДнейПросрочки]>0 and [КоличествоПолныхДнейПросрочки]<4 then N'_1-3' --N'a' -- N'_1-3' --
		when [КоличествоПолныхДнейПросрочки]>3 and [КоличествоПолныхДнейПросрочки]<31 then N'_4-30' --N'b' -- N'_4-30' --
		when [КоличествоПолныхДнейПросрочки]>30 and [КоличествоПолныхДнейПросрочки]<61 then N'31-60' --N'c' -- N'31-60' --
		when [КоличествоПолныхДнейПросрочки]>60 and [КоличествоПолныхДнейПросрочки]<91 then N'61-90' --N'd' -- N'61-90' --
		when [КоличествоПолныхДнейПросрочки]>90 and [КоличествоПолныхДнейПросрочки]<121 then N'91-120' --N'f' -- N'91-120' --
		when [КоличествоПолныхДнейПросрочки]>120 and [КоличествоПолныхДнейПросрочки]<151 then N'121-150' --N'g' -- N'121-150' --
		when [КоличествоПолныхДнейПросрочки]>150 and [КоличествоПолныхДнейПросрочки]<181 then N'151-180' --N'h' -- N'151-180' --
		when [КоличествоПолныхДнейПросрочки]>180 and [КоличествоПолныхДнейПросрочки]<211 then N'181-210' --N'' -- N'181-210' --
		when [КоличествоПолныхДнейПросрочки]>210 and [КоличествоПолныхДнейПросрочки]<241 then N'211-240'
		when [КоличествоПолныхДнейПросрочки]>240 and [КоличествоПолныхДнейПросрочки]<271 then N'241-270' --N'' -- N'241-270' --
		when [КоличествоПолныхДнейПросрочки]>270 and [КоличествоПолныхДнейПросрочки]<301 then N'271-300' --
		when [КоличествоПолныхДнейПросрочки]>300 and [КоличествоПолныхДнейПросрочки]<331 then N'301-330' --
		when [КоличествоПолныхДнейПросрочки]>330 and [КоличествоПолныхДнейПросрочки]<361 then N'331-360'
		when [КоличествоПолныхДнейПросрочки]>360 and [КоличествоПолныхДнейПросрочки]<391 then N'361-390'
		when [КоличествоПолныхДнейПросрочки]>390 and [КоличествоПолныхДнейПросрочки]<421 then N'391-420'
		when [КоличествоПолныхДнейПросрочки]>420 and [КоличествоПолныхДнейПросрочки]<451 then N'421-450'
		when [КоличествоПолныхДнейПросрочки]>450 and [КоличествоПолныхДнейПросрочки]<481 then N'451-480'
		when [КоличествоПолныхДнейПросрочки]>480 and [КоличествоПолныхДнейПросрочки]<511 then N'481-510'
		when [КоличествоПолныхДнейПросрочки]>510 and [КоличествоПолныхДнейПросрочки]<541 then N'511-540'
		when [КоличествоПолныхДнейПросрочки]>540 and [КоличествоПолныхДнейПросрочки]<571 then N'541-570'
		when [КоличествоПолныхДнейПросрочки]>570 and [КоличествоПолныхДнейПросрочки]<601 then N'571-600'
		when [КоличествоПолныхДнейПросрочки]>600 and [КоличествоПолныхДнейПросрочки]<631 then N'601-630'
		when [КоличествоПолныхДнейПросрочки]>630 and [КоличествоПолныхДнейПросрочки]<661 then N'631-660'
		when [КоличествоПолныхДнейПросрочки]>660 and [КоличествоПолныхДнейПросрочки]<691 then N'661-690'
		when [КоличествоПолныхДнейПросрочки]>690 and [КоличествоПолныхДнейПросрочки]<721 then N'691-720'
		when [КоличествоПолныхДнейПросрочки]>720 then N'Более 720'
	end as [Бакет]

	,case when [ВидНачисленияНаим]=N'Основной долг' then cast([Оплачено] as decimal(15,2)) else 0 end as [ОДНачисленоУплачено]
	,case when [ВидНачисленияНаим]=N'Проценты' then cast([Оплачено] as decimal(15,2)) else 0 end as [ПроцентыНачисленоУплачено]
	,case when [ВидНачисленияНаим]=N'Пени' then cast([Оплачено] as decimal(15,2)) else 0 end as [ПениНачисленоУплачено]
	,case when [ВидНачисленияНаим]=N'Госпошлина' then cast([Оплачено] as decimal(15,2)) else 0 end as [ГосПошлина]
	,0 as [Переплата]
	,0 as [ПроцентыГрейсПериода]
	,0 as [ПениГрейсПериода]

	,datediff(day,0,dateadd(MONTH,datediff(MONTH,0,[ПериодУчета]),0))+2 as [ПериодУчетаЧислом]
	,[ПериодУчета] as [ДатаОперацииИсх]
	,[ПериодУчета]
	,[СуммаЗайма]
	,[КредитныйПродукт]
	,[СрокЗайма]
	,[ОстатокОД]

into #TempTable_CollectingPayIn_UMFO
from #EnteringTable_UMFO
--)

--, PayIn_Res_UMFO as
--(
drop table if exists #PayIn_Res_UMFO
select  [ДатаОперацииИсх]
		,[ПериодУчетаЧислом]
		,[ПериодУчета]
		,[ДоговорСсылка]
		,[ДоговорНомер]
		,[Бакет] as [НаименованиеПараметра]	
		,N'Платежи по ОД_УМФО' as [НаименованиеЛиста]
		,sum([ОДНачисленоУплачено]) as [Всего]
--		,1 as [Колво]
		,[СуммаЗайма]
		,[КредитныйПродукт]
		,[СрокЗайма]
		,[ОстатокОД]
into #PayIn_Res_UMFO
from #TempTable_CollectingPayIn_UMFO where cast([ПериодУчета] as date)=cast(dateadd(MONTH,datediff(MONTH,0,dateadd(day,-1,Getdate())),0) as date) and [ОДНачисленоУплачено]>0
group by [ДатаОперацииИсх] ,[ПериодУчетаЧислом] ,[ПериодУчета] 
		,[ДоговорСсылка] ,[ДоговорНомер] ,[Бакет] ,[СуммаЗайма] ,[КредитныйПродукт]	,[СрокЗайма] ,[ОстатокОД]
--)

;with	PaymentReceiptUMFO as
(
--drop table if exists #PaymentReceiptUMFO
select 
 dateadd(day,datediff(day,0,Getdate()),0) as [ДатаОбновленияЗаписи]
 ,rip.[ПериодУчетаЧислом]
 ,rip.[ПериодУчета]
 
 ,rip.[ДоговорСсылка] as [Ссылка]
 ,rip.[ДатаОперацииИсх] as [ДатаОперации]
 ,rip.[ДоговорНомер]
	
 ,null as [ДоговорНомерМФО]
 ,null as [Договор_MFO]

,null as [Фамилия]
,null as [Имя]
,null as [Отчество]
,null as [ДатаРождения]

,null as [ДатаВыдачиДоговора]
,null as [ДатаОкончанияДоговора]

,rip.[СуммаЗайма] as [ПервичнаяСумма]
,rip.[СуммаЗайма] as [СуммаДоговора]
,null as [СуммаДопПродуктов]
,(isnull(rip.[СуммаЗайма],0)-0) as [СуммаБезДопУслуг_MFO]

,rip.[Всего] as [СуммаОДОплачено]
,rip.[ОстатокОД]

,1 as [Колво]

,rip.[СрокЗайма] as [Срок]
,null as [ПроцентнаяСтавка]
,rip.[КредитныйПродукт] as [КредитныйПродукт]

,null as [Докредитование]
,null as [Повторность]
,null as [ДатаПогашПервДог_MFO]
,null as [ПовторностьNew]

,null as [ТочкаКод]
,null as [Точка]
,N''  as [ВыезднойМенеджер]
,null as [Регион]
,null as [Регион2]
,null as [РОРегион]
,null as [Дивизион]
,null as [Агент]
,null as [АгентМФО]

 ,null as [НомерГрафика_MFO] 

 ,null as [ДатаНачала]
 ,null as [ДатаДоговора]

,datepart(dw,rip.[ДатаОперацииИсх]) as [ДеньНедели]
,datepart(wk,rip.[ДатаОперацииИсх]) as [Неделя]
,datepart(dd,rip.[ДатаОперацииИсх]) as [ДеньМесяца]
,datepart(mm,rip.[ДатаОперацииИсх]) as [Месяц]
,datepart(yyyy,rip.[ДатаОперацииИсх]) as [Год]

 ,rip.[НаименованиеЛиста] as [НаименованиеЛиста]
 ,rip.[НаименованиеПараметра] as [НаименованиеПараметра]

 ,N'Ежедневный' as [ПериодичностьОтчета]

 ,case
	when rip.[СуммаЗайма]<=150000 then N'до 150'
	when rip.[СуммаЗайма]>150000 and rip.[СуммаЗайма]<=700000 then N'151-700'
	when rip.[СуммаЗайма]>700000 and rip.[СуммаЗайма]<=1000000 then N'701-1000'
	when rip.[СуммаЗайма]>1000000 then N'более 1000'
	else N'Прочее'
end as [Когорта]

 ,null as [ВидДоговора]
 ,null as [ТекСтатусМФО]
 ,null as [СтатусНаим]
 ,null as [Лидогенератор]

 ---- дополнительно
,null as [КаналМФО_ТочкаВх]
,null as [ТочкаВходаЗаявки]
,null as [МестоСоздЗаявки]
,null as [СпособВыдачиЗайма]
,null as [ЕстьОсновнаяЗаявка]
,null as [ЗаявкаНомер]
,null as [ТекСтатусЗаявки]
,null as [ЗаявкаСсылка]
,N'УМФО' as [ИсточникДанных]
,et.[КоличествоПолныхДнейПросрочки] as [КолвоПолнДнПроср]

--into #PaymentReceiptUMFO
from #PayIn_Res_UMFO rip
left join (select distinct * from #EnteringTable_UMFO) et
on rip.[ДоговорСсылка]=et.[Ссылка]
)

insert into [dwh_new].[dbo].[mt_credit_portfolio_mfo] ([ДатаОбновленияЗаписи] ,[ПериодУчетаЧислом]
														,[ПериодУчета] ,[Ссылка] ,[ДатаОперации]
														,[ДоговорНомер] ,[ДоговорНомерМФО] ,[Договор] ,[Фамилия]
														,[Имя] ,[Отчество] ,[ДатаРождения] 

														,[ДатаВыдачиДоговора] ,[ДатаОкончанияДоговора]	

														,[ПервичнаяСумма] ,[СуммаДоговора] ,[СуммаДопПродуктов] ,[СуммаБезДопУслуг] ,[СуммаОДОплачено] ,[ОстатокОД]
														,[Колво]
														,[Срок] ,[ПроцентнаяСтавка] ,[КредитныйПродукт]
														,[Докредитование] ,[Повторность] ,[ДатаПогашПервДог] ,[ПовторностьNew]
														,[ТочкаКод] ,[Точка] ,[ВыезднойМенеджер] ,[Регион] ,[Регион2] ,[РОРегион] ,[Дивизион]
														,[Агент] ,[АгентМФО]

														 ,[НомерГрафика]

														 ,[ДатаНачала] ,[ДатаДоговора] 
														 ,[ДеньНедели] ,[Неделя] ,[ДеньМесяца] ,[Месяц] ,[Год]
														 ,[НаименованиеЛиста] ,[НаименованиеПараметра]   
														 ,[ПериодичностьОтчета] 
															
														 ,[Когорта] 
																
														 ,[ВидДоговора] ,[ТекСтатусМФО] ,[СтатусНаим] ,[Лидогенератор]
														 ----- дополнительно
														 ,[КаналМФО_ТочкаВх] ,[ТочкаВходаЗаявки] ,[МестоСоздЗаявки]
														,[СпособВыдачиЗайма] ,[ЕстьОсновнаяЗаявка] ,[ЗаявкаНомер] ,[ТекСтатусЗаявки] ,[ЗаявкаСсылка]
														,[ИсточникДанных]
														,[КолвоПолнДнПроср]  
														)

SELECT distinct
dateadd(day,datediff(day,0,Getdate()),0) as [ДатаОбновленияЗаписи]
,zl.[ПериодУчетаЧислом]
,case when dateadd(MONTH,datediff(MONTH,0,Getdate()),0)=dateadd(day,datediff(day,0,Getdate()),0) 
		then dateadd(MONTH,datediff(MONTH,0,Getdate()-1),0)
	 else dateadd(MONTH,datediff(MONTH,0,Getdate()),0)
end as [ПериодУчета]  --y
,zl.[Ссылка] as [СсылкаДоговор] --y
,case when dateadd(MONTH,datediff(MONTH,0,Getdate()),0)=dateadd(day,datediff(day,0,Getdate()),0) 
		then dateadd(day,datediff(day,0,Getdate()-1),0)
	 else dateadd(day,datediff(day,0,Getdate()),0) 
end as [ДатаОперации]  --y
,zl.[Номер] as [ДоговорНомер]  --y
,zl.[Номер] as [ДоговорНомерМФО]  --y
,zl.[Ссылка] as [Договор]  --y

,zl.[Фамилия]  --y
,zl.[Имя]  --y
,zl.[Отчество]  --y
,zl.[ДатаРождения]  --y

,dv.[ДатаВыдачиЗайма] as [ДатаВыдачиДоговора]  --y
,case when not dv.[ДатаВыдачиЗайма] is null then dateadd(month,zl.[Срок], dv.[ДатаВыдачиЗайма]) end as [ДатаОкончанияДоговора]  --y

,0 as [ПервичнаяСумма]  --y
,zl.[Сумма] as [СуммаДоговора]  --y
,zl.[СуммаДополнительныхУслуг] as [СуммаДопПродуктов]  --y
,(isnull(zl.[Сумма],0)-isnull(zl.[СуммаДополнительныхУслуг],0)) as [СуммаБезДопУслуг]  --y
,zl.[СуммаОДОплачено]  --y
,zl.[ОстатокОД] --y
,zl.[Колво]  --y

,zl.[Срок]  --y
,zl.[ПроцентнаяСтавка]  --y
,zl.[КредитныйПродукт]  --y

,zl.[Докредитование]  --y
,N'' as [Повторность]
,dateadd(year,-2000,cast(ssd0.[ПериодПогашения] as datetime2)) as [ДатаПогашПервДог]
,case when ssd0.[ПериодПогашения] is null then N'Нет' else N'Да' end as [ПовторностьNew] 

,zl.[ТочкаКод]  --y
,zl.[Точка]  --y
,zl.[ВыезднойМенеджер]  --y

,case 
	when tch.[РП_Регион] is null then N'Москва' 
	when tch.[РП_Регион] like N'%Москва%' or tch.[РП_Регион]=N'Микрофинансирование' then N'Москва' 
	else 
		case when tch.[РП_Регион] like N'РП ВМ%' then substring(tch.[РП_Регион], 7,50) else substring(tch.[РП_Регион], 4,50) end
end as [Регион]
,case 
	when tch.[РП_Регион] is null then N'Москва'
	when tch.[РП_Регион]=N'Микрофинансирование' then N'Москва' 
	else substring(tch.[РП_Регион], 4,50)
end as [Регион2]
,case when tch.[РО_Регион] is null then N'Центральный регион' else substring(tch.[РО_Регион], 4,50) end as [РОРегион]
,N'' [Дивизион]  --y
,zl.[Агент]  --y
,zl.[АгентМФО]  --y

,null as [НомерГрафика]

,dv.[ДатаВыдачиЗайма] as [ДатаНачала]
,dp.[ДатаПодписанияДоговора] as [ДатаДоговора]

,datepart(dw,dateadd(day,datediff(day,0,Getdate()),0)) as [ДеньНедели]
,datepart(wk,dateadd(day,datediff(day,0,Getdate()),0)) as [Неделя]
,datepart(dd,dateadd(day,datediff(day,0,Getdate()),0)) as [ДеньМесяца]
,datepart(mm,dateadd(day,datediff(day,0,Getdate()),0)) as [Месяц]
,datepart(yyyy,dateadd(day,datediff(day,0,Getdate()),0)) as [Год]

,N'KPI кредитный портфель' as [НаименованиеЛиста]  --y
,zl.[НаименованиеПараметра]  --y

,N'Ежедневный' as [ПериодичностьОтчета]

 ,case
	when zl.[Сумма]<=150000 then N'до 150'
	when zl.[Сумма]>150000 and zl.[Сумма]<=700000 then N'150-700'
	when zl.[Сумма]>700000 and zl.[Сумма]<=1000000 then N'701-1000'
	when zl.[Сумма]>1000000 then N'более 1000'
	else N'Прочее'
end as [Когорта]

,null [ВидДоговора]
,zl.[СтатусДоговора] as [ТекСтатусМФО]
,zl.[ДоговорТекСтатус] as [СтатусНаим]
 ,null as [Лидогенератор]


 --- Дополнительно
,N'' as [КаналМФО_ТочкаВх]

,N'' as [ТочкаВходаЗаявки]
,N'' as [МестоСоздЗаявки]
,N'' as [СпособВыдачиЗайма]
,null as [ЕстьОсновнаяЗаявка]
,null as [ЗаявкаНомер]
,null as [ТекСтатусЗаявки]
,zl.[Заявка] as [ЗаявкаСсылка]
,N'МФО' as [ИсточникДанных]
,zl.[КолвоПолнДнПроср]

FROM #tabl2 zl
	
	left join [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] z  with (nolock) -- zayvka
		ON zl.[Заявка]=z.[Ссылка]

	left join (select mt1.[ПодчНаим] as [РО_Регион],mt0.[РодительНаим] as [РП_Регион]
					  ,mt0.[ПодчКод] as [ТочкаКод],mt0.[ПодчНаим] as [Точка]
					  ,mt0.[Подчиненный] as [ТочкаСсылка],ofc.[Агент] 
			   from [Stg].[dbo].[aux_OfficeMFO_1c] mt0 --[dwh_new_Kurdin_S_V].[dbo].[auxtab_TableOfficeMFO_1c] mt0
			   left join (select * from [Stg].[dbo].[aux_OfficeMFO_1c]) mt1  --[dwh_new_Kurdin_S_V].[dbo].[auxtab_TableOfficeMFO_1c]) mt1
					on mt0.[ПроРодитель]=mt1.[Подчиненный]
				left join (select ofc0.[Ссылка],ofc1.[Наименование] as [Агент]
						   from [prodsql02].[mfo].[dbo].[Справочник_ГП_Офисы] ofc0  with (nolock)
						   left join [prodsql02].[mfo].[dbo].[Справочник_Контрагенты] ofc1 with (nolock)
								on ofc0.[Партнер]=ofc1.[Ссылка]
						   ) ofc
				 on mt0.[Подчиненный]=ofc.[Ссылка]
				 where mt0.[ПодчНаим] like N'%Партнер%' or mt0.[ПодчНаим] like N'Личный%кабинет%' or mt0.[ПодчНаим] like N'Колл центр' or mt0.[ПодчНаим] like N'%ВМ%'
				) tch -- Точка-РП-РО
		on zl.[ТочкаСсылка]=tch.[ТочкаСсылка]



	left join (SELECT max(cast(dateadd(year,-2000,[Период]) as datetime2)) as [ДатаВыдачиЗайма],[Заявка]
			   FROM [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокЗаявок] with (nolock)
			   WHERE [Статус]=0xA398265179685AF34EED1A6B6349A87B -- Статус заем выдан
			   GROUP BY [Заявка]
				) dv
		ON zl.[Заявка]=dv.[Заявка]

	left join (SELECT max(cast(dateadd(year,-2000,[Период]) as datetime2)) as [ДатаПодписанияДоговора],[Заявка]
			   FROM [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокЗаявок] with (nolock)
			   WHERE [Статус]=0xB35F4DD3132676754B1711F049B4CB3A -- Статус договор подаисан
			   GROUP BY [Заявка]
				) dp
		ON zl.[Заявка]=dp.[Заявка]

	left join (SELECT min(sd0.[Период]) as [ПериодПогашения] ,d0.[Контрагент] as [Контрагент] --,d0.[Номер] as [НомерПогашДоговора]
			   FROM [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокДоговоров_ИтогиСрезПоследних] sd0 with (nolock)
					left join (
							   select [Ссылка],[Номер],[Контрагент]
							   from [prodsql02].[mfo].[dbo].[Документ_ГП_Договор]
							   ) d0
					on sd0.[Договор]=d0.[Ссылка]
				where [Статус]=0xB074EC051022E2274B7AA44702431457  -- Статус Погашен
				group by d0.[Контрагент]
			   ) ssd0 -- таблица с договорами с минимальной датой в статусе погашен из МФО
		on zl.[Контрагент]=ssd0.[Контрагент] and zl.[Дата]>ssd0.[ПериодПогашения]


--  where cast(dateadd(year,-2000,z.[Дата]) as datetime2)  >= dateadd(month,-3,dateadd(month,datediff(month,0,GetDate()),0)) 
--		and cast(dateadd(year,-2000,z.[Дата]) as datetime2)<dateadd(day,datediff(day,0,GetDate()),0) 
--		and z.[ПометкаУдаления]=0x00 --and Month(z.[Дата])=Month(@DateReport)
--		and d.[Ссылка] is not null

union all

select distinct * from PaymentReceiptUMFO


drop table if exists #GetDefaultCreditsAndBalanceByParam
select *
into dwh_new.dbo.mt_GetDefaultCreditsAndBalanceByParam
from dwh_new.dbo.GetDefaultCreditsAndBalanceByParam(0, 1 , 4)


END

