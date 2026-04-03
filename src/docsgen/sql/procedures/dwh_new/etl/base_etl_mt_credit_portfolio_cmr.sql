-- =============================================
-- Author:		КУрдин С.В.
-- Create date: 2019-05-22
-- Description:	Таблица "ЗАЙМЫ" содержит информацию о выданных займах, их текущих статусах,
--				дате заявки, дате выдачи, точке входа, точке партнера, Агенте партнера, сумме доп услуг по договору
-- =============================================
CREATE PROCEDURE [etl].[base_etl_mt_credit_portfolio_cmr]
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
set @DateStart2000= dateadd(day,datediff(day,0,dateadd(year,2000,dateadd(day,-12,Getdate()))),0);
set @DateStartCurr=dateadd(day,0,dateadd(day,datediff(day,0,Getdate()),0));	-- Переменная для начала (дня) оперативного обновления данных по периоду статуса за последние 14 дней для поля с текущей датой
set @DateStartCurr2000=dateadd(day,-14,dateadd(day,datediff(day,0,dateadd(year,2000,Getdate())),0));	-- Переменная для начала (дня) оперативного обновления данных по периоду статуса за последние 14 дней для поля с текущей датой + 2000

delete from [dwh_new].[dbo].[mt_credit_portfolio_cmr] 
where [ДатаОбновленияЗаписи] >= @DateStartCurr;

--if OBJECT_ID('[dwh_new].[dbo].[mt_credit_portfolio_cmr]') is not null
--drop table [dwh_new].[dbo].[mt_credit_portfolio_cmr];

--create table [dwh_new].[dbo].[mt_credit_portfolio_cmr]
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

--with 
--t0_cmr as
--(
drop table if exists #t0_cmr
select distinct sd.[Период] ,sd.[Договор] ,d.[Дата] ,d.[Код] as [ДоговорНомер] ,d.[Сумма] as [ДоговорСумма] ,sd.[Статус] ,rs.[Наименование] as [СтатусНаим]
				,d.[Фамилия] as [Фамилия] ,d.[Имя] as [Имя] ,d.[Отчество] as [Отчество] ,dateadd(year,-2000, cast(d.[ДатаРождения] as datetime2)) as [ДатаРождения]
				,d.[СуммаДопПродуктов] ,d.[Срок] ,d.[ПроцентнаяСтавка] ,d.[ВыезднойМенеджер] ,d.[Заявка] ,d.[КредитныйПродукт]
				,d.[Точка] ,d.[Клиент]
into #t0_cmr
from
(
select [Период] ,[Договор] ,[Статус]
	  ,rank() over(partition by [Договор] order by [Период] desc) as [rank_p]
from [Stg].[_1cCMR].[РегистрСведений_СтатусыДоговоров] with (nolock) -- добавлен with (nolock)
) sd
left join [Stg].[_1cCMR].[Справочник_Договоры] d with (nolock)
	on sd.[Договор]=d.[Ссылка]
left join [Stg].[_1cCMR].[Справочник_СтатусыДоговоров] rs with (nolock)
	on sd.[Статус]=rs.[Ссылка]
where sd.[rank_p]=1 and not rs.[Наименование] in (N'Зарегистрирован' ,N'Погашен' ,N'Аннулирован' ,N'Продан'
												 --,N'Действует',N'Платеж опаздывает' ,N'Просрочен' ,N'Проблемный',N'Legal' ,N'Решение суда',N'Приостановка начислений'
												 )
--)
--select * from t0_cmr
--order by [Договор] desc


--,	cmr_debt as
--(

drop table if exists #cmr_debt
select distinct ---*--[Период] ,
			rz.[ВидДвижения] ,rz.[Договор] ,sum(rz.[ОДНачисленоУплачено]) as [ОДОплачено] ,sum(rz.[ОДПоГрафику]) as [ОДПоГрафику] --,rz.[ДниПросрочки]

into #cmr_debt

from [Stg].[_1cCMR].[РегистрНакопления_РасчетыПоЗаймам] rz with (nolock)
where rz.[Период]<=dateadd(year,2000,getdate()) 
	  and [ВидДвижения]=1	--оплачено
	  and exists (select [Договор] from #t0_cmr d where d.[Договор]= rz.[Договор]) 
group by rz.[Договор] ,rz.[ВидДвижения]
--)

--,	cmr_TermDebt as	-- просрочка
--(
drop table if exists #cmr_TermDebt
select distinct * 
into #cmr_TermDebt
from (
select [Период] --,rz.[ВидДвижения] 
	   ,rz.[Договор] --,sum(rz.[ОДНачисленоУплачено]) as [ОДОплачено] ,sum(rz.[ОДПоГрафику]) as [ОДПоГрафику] --
	   ,rz.[ДниПросрочки]
		,rank() over(partition by [Договор] order by [Период] desc) as [rank_t]
from [Stg].[_1cCMR].[РегистрНакопления_РасчетыПоЗаймам] rz with (nolock) -- добавлен with (nolock)
where rz.[Период]<=dateadd(year,2000,getdate()) 
	  --and [ВидДвижения]=1	--оплачено
	  and exists (select [Договор] from #t0_cmr d where d.[Договор]= rz.[Договор]) 
--group by rz.[Договор] ,rz.[ВидДвижения]
) td
where td.[rank_t]=1
--)


--,	t_an_pokaz as	--аналитические показатели
--(
drop table if exists #t_an_pokaz
select distinct *
into #t_an_pokaz
from
(
select [Период]
      ,[Договор]
      ,[ДатаВозникновенияПросрочки]
      ,[ДатаПоследнегоПлатежа]
      ,[КоличествоПолныхДнейПросрочки] as [КолвоПолнДнПроср]
      ,[ПросроченнаяЗадолженность] as [ПросрЗадолж2]
      ,[СуммаПоследнегоПлатежа]
      ,[РегистраторМФО]
	  ,rank() over(partition by [Договор] order by [Период] desc) as [rank_p]
from [Stg].[_1cCMR].[РегистрСведений_АналитическиеПоказателиМФО] with (nolock) -- добавлен with (nolock)
) ap
where ap.[rank_p]=1
--)
--select * from cmr_TermDebt order by [ДниПросрочки] desc ,[Договор] desc--, [Период] desc


--,	CredPortf_cmr0 as
--(

drop table if exists #CredPortf_cmr0
select d.[Период] as [Период_cmr] ,d.[Договор] as [Договор_cmr] ,d.[ДоговорНомер] as [ДоговорНомер_cmr] 
		,d.[ДоговорСумма] as [ДоговорСумма_cmr] ,d.[СтатусНаим] as [СтатусНаим_cmr] ,d.[ДоговорСумма] as [СуммаДоговора_cmr]
		,td.[ДниПросрочки] as [ДниПросрочки_cmr] ,td.[Период] as [ПослПериодОтражДнПросрч_cmr]
		,dbt.[ОДОплачено] as [СуммаОДОплачено_cmr] ,dbt.[ОДПоГрафику] as [ОДПоГрафику_cmr] 
		,d.[ДоговорСумма]-isnull(dbt.[ОДОплачено],0) as [ОстатокОД_cmr] 
		,isnull(dbt.[ОДПоГрафику],0)-isnull(dbt.[ОДОплачено],0) as [ЗадолжПоГрафику_cmr]
		,1 as [Колво_cmr]
		,isnull(ap.[КолвоПолнДнПроср],0) as [КолвоПолнДнПроср_cmr] 
		,case
			when isnull(ap.[КолвоПолнДнПроср],0)=0 then N'Непросроченный'
			when isnull(ap.[КолвоПолнДнПроср],0)>0 and isnull(ap.[КолвоПолнДнПроср],0)<4 then N'_1-3' --N'a' -- N'_1-3' --
			when isnull(ap.[КолвоПолнДнПроср],0)>3 and isnull(ap.[КолвоПолнДнПроср],0)<31 then N'_4-30' --N'b' -- N'_4-30' --
			when isnull(ap.[КолвоПолнДнПроср],0)>30 and isnull(ap.[КолвоПолнДнПроср],0)<61 then N'31-60' --N'c' -- N'31-60' --
			when isnull(ap.[КолвоПолнДнПроср],0)>60 and isnull(ap.[КолвоПолнДнПроср],0)<91 then N'61-90' --N'd' -- N'61-90' --
			when isnull(ap.[КолвоПолнДнПроср],0)>90 and isnull(ap.[КолвоПолнДнПроср],0)<121 then N'91-120' --N'f' -- N'91-120' --
			when isnull(ap.[КолвоПолнДнПроср],0)>120 and isnull(ap.[КолвоПолнДнПроср],0)<151 then N'121-150' --N'g' -- N'121-150' --
			when isnull(ap.[КолвоПолнДнПроср],0)>150 and isnull(ap.[КолвоПолнДнПроср],0)<181 then N'151-180' --N'h' -- N'151-180' --
			when isnull(ap.[КолвоПолнДнПроср],0)>180 and isnull(ap.[КолвоПолнДнПроср],0)<211 then N'181-210' --N'' -- N'181-210' --
			when isnull(ap.[КолвоПолнДнПроср],0)>210 and isnull(ap.[КолвоПолнДнПроср],0)<241 then N'211-240'
			when isnull(ap.[КолвоПолнДнПроср],0)>240 and isnull(ap.[КолвоПолнДнПроср],0)<271 then N'241-270' --N'' -- N'241-270' --
			when isnull(ap.[КолвоПолнДнПроср],0)>270 and isnull(ap.[КолвоПолнДнПроср],0)<301 then N'271-300' --
			when isnull(ap.[КолвоПолнДнПроср],0)>300 and isnull(ap.[КолвоПолнДнПроср],0)<331 then N'301-330' --
			when isnull(ap.[КолвоПолнДнПроср],0)>330 and isnull(ap.[КолвоПолнДнПроср],0)<361 then N'331-360'
			when isnull(ap.[КолвоПолнДнПроср],0)>360 and isnull(ap.[КолвоПолнДнПроср],0)<391 then N'361-390'
			when isnull(ap.[КолвоПолнДнПроср],0)>390 and isnull(ap.[КолвоПолнДнПроср],0)<421 then N'391-420'
			when isnull(ap.[КолвоПолнДнПроср],0)>420 and isnull(ap.[КолвоПолнДнПроср],0)<451 then N'421-450'
			when isnull(ap.[КолвоПолнДнПроср],0)>450 and isnull(ap.[КолвоПолнДнПроср],0)<481 then N'451-480'
			when isnull(ap.[КолвоПолнДнПроср],0)>480 and isnull(ap.[КолвоПолнДнПроср],0)<511 then N'481-510'
			when isnull(ap.[КолвоПолнДнПроср],0)>510 and isnull(ap.[КолвоПолнДнПроср],0)<541 then N'511-540'
			when isnull(ap.[КолвоПолнДнПроср],0)>540 and isnull(ap.[КолвоПолнДнПроср],0)<571 then N'541-570'
			when isnull(ap.[КолвоПолнДнПроср],0)>570 and isnull(ap.[КолвоПолнДнПроср],0)<601 then N'571-600'
			when isnull(ap.[КолвоПолнДнПроср],0)>600 and isnull(ap.[КолвоПолнДнПроср],0)<631 then N'601-630'
			when isnull(ap.[КолвоПолнДнПроср],0)>630 and isnull(ap.[КолвоПолнДнПроср],0)<661 then N'631-660'
			when isnull(ap.[КолвоПолнДнПроср],0)>660 and isnull(ap.[КолвоПолнДнПроср],0)<691 then N'661-690'
			when isnull(ap.[КолвоПолнДнПроср],0)>690 and isnull(ap.[КолвоПолнДнПроср],0)<721 then N'691-720'
			when isnull(ap.[КолвоПолнДнПроср],0)>720 then N'Более 720'
		end as [Бакет_cmr]
	   ,ap.[ПросрЗадолж2] as [ПросрЗадолж2_cmr]
	   ,N'ЦМР' as [CMR]

	   ,d.[Дата]
	   ,d.[Фамилия] ,d.[Имя] ,d.[Отчество] ,d.[ДатаРождения]
	   ,d.[СуммаДопПродуктов]
	   ,d.[Срок]
	   ,d.[КредитныйПродукт] as [КредитныйПродукт]
	   ,d.[ПроцентнаяСтавка]
	   ,d.[ВыезднойМенеджер]
	   ,d.[Заявка]
	   ,d.[Точка]

into #CredPortf_cmr0

from #t0_cmr d
left join #cmr_TermDebt td
on d.[Договор]=td.[Договор]
left join #cmr_debt dbt
on d.[Договор]=dbt.[Договор]
left join #t_an_pokaz ap
on d.[Договор]=ap.[Договор]
--)

--,	cmr_Loan_LastStatus as
--(

drop table if exists #cmr_Loan_LastStatus
select s.[Период] as [Период] ,s.[Договор] as [Договор] ,s.[Статус] as [Статус] ,sd.[Наименование] as [СтатусНаим]
into #cmr_Loan_LastStatus
from (select distinct [Период] ,[Договор] ,[Статус] ,rank() over(partition by [Договор] order by [Период] desc) as [rank_p] 
	  from [Stg].[_1cCMR].[РегистрСведений_СтатусыДоговоров] with (nolock)) s  -- добавлен with (nolock)
left join [Stg].[_1cCMR].[Справочник_СтатусыДоговоров] sd with (nolock) -- добавлен with (nolock)
on s.[Статус]=sd.[Ссылка]
where s.[rank_p]=1
--)


--,	t1 as -- Остаток задолженности на текущую дату
--(
drop table if exists #t1
select d.[Договор_cmr] as [Ссылка] ,[ДоговорНомер_cmr] as [Номер] 
	  ,d.[Фамилия] as [Фамилия]
	  ,d.[Имя] as [Имя]
	  ,d.[Отчество] as [Отчество]
	  ,cast(d.[ДатаРождения] as date) as [ДатаРождения]
	  ,d.[ДоговорСумма_cmr] as [Сумма]	  
	  ,d.[СуммаДопПродуктов] as [СуммаДополнительныхУслуг]
	  ,d.[СуммаОДОплачено_cmr] as [СуммаОДОплачено]

	  ,(d.[ДоговорСумма_cmr]-isnull(d.[СуммаОДОплачено_cmr],0)) as [ОстатокОД]
	  ,d.[Срок]
	  ,case when d.[ПроцентнаяСтавка]<>0 then d.[ПроцентнаяСтавка] else d.[ПроцентнаяСтавка] end as [ПроцентнаяСтавка]	-- kp.[ТекущаяСсуда] end as [ПроцентнаяСтавка]
	  ,null as [КредитныйПродукт]	--,kp.[Наименование] as [КредитныйПродукт]
	  ,null as [Докредитование]		--,dk.[Имя] as [Докредитование]

	  ,null as [ТочкаКод]	--,o.[Код] as [ТочкаКод]
	  ,null as [ТочкаСсылка]		--,o.[Ссылка] as [ТочкаСсылка]
	  ,null as [Точка]		--,o.[Наименование] as [Точка]
	  ,case when d.[ВыезднойМенеджер]=0x01 then N'ВыезднойМенеджер' else N'' end as [ВыезднойМенеджер]

	  ,null as [Агент] --,cl.[Наименование] as [Агент]
	  ,null as [АгентМФО]	--,cl.[Наименование] as [АгентМФО]
	  
	  ,d.[Дата]

	  ,d.[КолвоПолнДнПроср_cmr] as [КолвоПолнДнПроср]
	  ,d.[Бакет_cmr] as [Бакет]
	  
	  ,ap.[Период] as [ПериодСтатуса] ,ap.[Статус] as [СтатусСсылка] ,ap.[СтатусНаим] as [ТекСтатус]
--	  ,d.[дз_ДатаПродажиДоговора]
--	  ,case 
--			where cast(d.[дз_ДатаПродажиДоговора] as datetime) = N'2001-01-01 00:00:00.000' then null 
--			else dateadd(year,-2000,d.[дз_ДатаПродажиДоговора]) 
--	   end as [ДатаПродажиДоговора]
	  ,d.[Заявка]
	  ,null as [Контрагент]		--,d.[Клиент] as [Контрагент]

into #t1

from #CredPortf_cmr0 d
	left join #cmr_Loan_LastStatus ap
	on d.[Договор_cmr]=ap.[Договор]

	--left join [prodsql02].[cmr].[dbo].[Справочник_КредитныеПродукты] kp
	--on d.[КредитныйПродукт]=kp.[Ссылка]

	--left join [prodsql02].[mfo].[dbo].[Перечисление_ВидыДокредитования] dk
	--on d.[Докредитование]=dk.[Ссылка]

	--left join [prodsql02].[cmr].[dbo].[Справочник_Точки] o
	--on d.[Точка]=o.[Ссылка]

	--left join [prodsql02].[cmr].[dbo].[Справочник_Клиенты] cl
	--on o.[Партнер]=cl.[Ссылка]
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

insert into [dwh_new].[dbo].[mt_credit_portfolio_cmr] ([ДатаОбновленияЗаписи] ,[ПериодУчетаЧислом]
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

,null as [ДатаВыдачиДоговора]	--,dv.[ДатаВыдачиЗайма] as [ДатаВыдачиДоговора]  --y
,null as [ДатаОкончанияДоговора]	--,case when not dv.[ДатаВыдачиЗайма] is null then dateadd(month,zl.[Срок], dv.[ДатаВыдачиЗайма]) end as [ДатаОкончанияДоговора]  --y

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
,null as [ДатаПогашПервДог]	--,dateadd(year,-2000,cast(ssd0.[ПериодПогашения] as datetime2)) as [ДатаПогашПервДог]
,null as [ПовторностьNew]	--,case when ssd0.[ПериодПогашения] is null then N'Нет' else N'Да' end as [ПовторностьNew] 

,zl.[ТочкаКод]  --y
,zl.[Точка]  --y
,zl.[ВыезднойМенеджер]  --y

--,case 
--	when tch.[РП_Регион] is null then N'Москва' 
--	when tch.[РП_Регион] like N'%Москва%' or tch.[РП_Регион]=N'Микрофинансирование' then N'Москва' 
--	else 
--		case when tch.[РП_Регион] like N'РП ВМ%' then substring(tch.[РП_Регион], 7,50) else substring(tch.[РП_Регион], 4,50) end
--end as [Регион]
,null as [Регион]
--,case 
--	when tch.[РП_Регион] is null then N'Москва'
--	when tch.[РП_Регион]=N'Микрофинансирование' then N'Москва' 
--	else substring(tch.[РП_Регион], 4,50)
--end as [Регион2]
,null as [Регион2]
,null as [РОРегион]	--,case when tch.[РО_Регион] is null then N'Центральный регион' else substring(tch.[РО_Регион], 4,50) end as [РОРегион]
,N'' [Дивизион]  --y
,zl.[Агент]  --y
,zl.[АгентМФО]  --y

,null as [НомерГрафика]

,null as [ДатаНачала]	--,dv.[ДатаВыдачиЗайма] as [ДатаНачала]
,null as [ДатаДоговора]	--,dp.[ДатаПодписанияДоговора] as [ДатаДоговора]

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
,N'ЦМР' as [ИсточникДанных]
,zl.[КолвоПолнДнПроср]

from #tabl2 zl
	
--	left join [prodsql02].[mfo].[dbo].[Документ_ГП_Заявка] z -- zayvka
--		ON zl.[Заявка]=z.[Ссылка]

--	left join (select mt1.[ПодчНаим] as [РО_Регион],mt0.[РодительНаим] as [РП_Регион]
--					  ,mt0.[ПодчКод] as [ТочкаКод],mt0.[ПодчНаим] as [Точка]
--					  ,mt0.[Подчиненный] as [ТочкаСсылка],ofc.[Агент] 
--			   from [dwh_new_Kurdin_S_V].[dbo].[auxtab_TableOfficeMFO_1c] mt0
--			   left join (select * from [dwh_new_Kurdin_S_V].[dbo].[auxtab_TableOfficeMFO_1c]) mt1
--					on mt0.[ПроРодитель]=mt1.[Подчиненный]
--				left join (select ofc0.[Ссылка],ofc1.[Наименование] as [Агент]
--						   from [prodsql02].[mfo].[dbo].[Справочник_ГП_Офисы] ofc0
--						   left join [prodsql02].[mfo].[dbo].[Справочник_Контрагенты] ofc1
--								on ofc0.[Партнер]=ofc1.[Ссылка]
--						   ) ofc
--				 on mt0.[Подчиненный]=ofc.[Ссылка]
--				 where mt0.[ПодчНаим] like N'%Партнер%' or mt0.[ПодчНаим] like N'Личный%кабинет%' or mt0.[ПодчНаим] like N'Колл центр' or mt0.[ПодчНаим] like N'%ВМ%'
--				) tch -- Точка-РП-РО
--		on zl.[ТочкаСсылка]=tch.[ТочкаСсылка]



--	left join (SELECT max(cast(dateadd(year,-2000,[Период]) as datetime2)) as [ДатаВыдачиЗайма],[Заявка]
--			   FROM [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокЗаявок]
--			   WHERE [Статус]=0xA398265179685AF34EED1A6B6349A87B -- Статус заем выдан
--			   GROUP BY [Заявка]
--				) dv
--		ON zl.[Заявка]=dv.[Заявка]

--	left join (SELECT max(cast(dateadd(year,-2000,[Период]) as datetime2)) as [ДатаПодписанияДоговора],[Заявка]
--			   FROM [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокЗаявок]
--			   WHERE [Статус]=0xB35F4DD3132676754B1711F049B4CB3A -- Статус договор подаисан
--			   GROUP BY [Заявка]
--				) dp
--		ON zl.[Заявка]=dp.[Заявка]

--	left join (SELECT min(sd0.[Период]) as [ПериодПогашения] ,d0.[Контрагент] as [Контрагент] --,d0.[Номер] as [НомерПогашДоговора]
--			   FROM [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СписокДоговоров_ИтогиСрезПоследних] sd0
--					left join (
--							   select [Ссылка],[Номер],[Контрагент]
--							   from [prodsql02].[mfo].[dbo].[Документ_ГП_Договор]
--							   ) d0
--					on sd0.[Договор]=d0.[Ссылка]
--				where [Статус]=0xB074EC051022E2274B7AA44702431457  -- Статус Погашен
--				group by d0.[Контрагент]
--			   ) ssd0 -- таблица с договорами с минимальной датой в статусе погашен из МФО
--		on zl.[Контрагент]=ssd0.[Контрагент] and zl.[Дата]>ssd0.[ПериодПогашения]


----  where cast(dateadd(year,-2000,z.[Дата]) as datetime2)  >= dateadd(month,-3,dateadd(month,datediff(month,0,GetDate()),0)) 
----		and cast(dateadd(year,-2000,z.[Дата]) as datetime2)<dateadd(day,datediff(day,0,GetDate()),0) 
----		and z.[ПометкаУдаления]=0x00 --and Month(z.[Дата])=Month(@DateReport)
----		and d.[Ссылка] is not null

/*
drop table if exists #GetDefaultCreditsAndBalanceByParam
select *
into dwh_new.dbo.mt_GetDefaultCreditsAndBalanceByParam
from dwh_new.dbo.GetDefaultCreditsAndBalanceByParam(0, 1 , 4)
*/
END

