CREATE   proc [dbo].[Подготовка вечерних отчетов]
as

begin



declare @report_date date = getdate()


drop table if exists #fa

SELECT 	fa.[Заем выдан]
	,fa.Номер
	,fa.[Текущий статус]
	,fa.[Место cоздания]
	,fa.ФИО
    ,fa.МесяцЗаявки
	,fa.[Выданная сумма]
	,fa.[Сумма одобренная]
	,fa.[Первичная сумма]
	,fa.Одобрено
    ,fa.Дата
    ,fa.[ПризнакОдобрено]
	,1-fa.ispts isInstallment
	,fa.[Вид займа]
	,fa.[ПризнакКонтрольданных]
	,fa.[Сумма заявки]
	,fa.[Контроль данных]
	,fa.[ПризнакЗаявка]
	,fa.[ПризнакЗайм]
	,fa.Дубль
	,fa.ДатаЗаявкиПолная
	,IIF(fa.[Сумма одобренная] > fa.[Выданная сумма], 1, 0) 'Одобрено больше выданного'
	,CASE 
		WHEN format(fa.[Заем выдан]   , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') THEN 'Сегодня' ELSE format(fa.[Заем выдан]   , 'yyyy-MM-dd') 
	END [Дата выдачи день текст] 
	,ГодВыдачи
	,ГодЗаявки
	,[Процентная ставка] ПроцСтавкаКредит
	,[Сумма Дополнительных Услуг Carmoney Net] СуммаДопУслугCarmoneyNet
INTO #fa
FROM Reports.dbo.dm_Factor_Analysis_001 fa
WHERE 1-fa.ispts  = 0

	--Таблица TU с дельтой

-- DROP TABLE IF EXISTS Analytics.dbo.[Отчет вечерний TUдельта]

DROP TABLE IF EXISTS #tud1 

select 
	1 Номер,
	'Одобрено' Значение,
	sum(ПризнакОдобрено) Одобрено
into #tud1 --кол-во одобрений в текущем месяце
from #fa fa
where format(convert(date, [Одобрено] , 104), 'yyyy-MM-01')  = format( getdate()  , 'yyyy-MM-01') 
	
drop table if exists #tud2

select 
	2 Номер,
	'Одобрено' Значение,
	sum(ПризнакОдобрено) Одобрено
into #tud2 ----кол-во одобрений в прошлом месяце
from #fa fa
where format(convert(date, [Одобрено] , 104), 'yyyy-MM-01') = format( dateadd(month, -1, getdate())  , 'yyyy-MM-01') 

drop table if exists #tud3

select 
	1 Номер,
	'Займ выдан в день одобрения' Значение,
	sum(iif(convert(varchar(10),fa.[Заем выдан],104) = convert(varchar(10),fa.Одобрено,104), 1,0)) ЗаймвДеньОдобрения
into #tud3 --займ в день одобрения текущий месяц
from #fa fa
where [Заем выдан] is not null 
	and format(convert(date, [Заем выдан] , 104), 'yyyy-MM-01')  = format( getdate()  , 'yyyy-MM-01') 
	
drop table if exists #tud4

select 
	2 Номер,
	'Займ выдан в день одобрения' Значение,
	sum(iif(convert(varchar(10),fa.[Заем выдан],104) = convert(varchar(10),fa.Одобрено,104), 1,0)) ЗаймвДеньОдобрения
into #tud4 --займ в день одобрения прошлый месяц
from #fa fa
where [Заем выдан] is not null 
	and format(convert(date, [Заем выдан] , 104), 'yyyy-MM-01') = format( dateadd(month, -1, getdate())  , 'yyyy-MM-01') 

drop table if exists #tud5

select 
	'TUвДеньОдобрения' Значение,
	cast(tud3.ЗаймвДеньОдобрения as float)/cast(tud1.Одобрено as float) TUвДеньОдобрения
into #tud5 --TUвДеньОдобрения текущий месяц
from #tud1 tud1
join #tud3 tud3 on tud1.Номер = tud3.Номер

drop table if exists #tud6

select 
	'TUвДеньОдобрения' Значение,
	cast(tud4.ЗаймвДеньОдобрения as float)/cast(tud2.Одобрено as float) TUвДеньОдобрения
into #tud6 --TUвДеньОдобрения прошлый месяц
from #tud2 tud2
join #tud4 tud4 on tud2.Номер = tud4.Номер

drop table if exists #tud7

select 
	sum(ПризнакОдобрено) Одобрено,
	'Одобрено' Значение
	,format(convert(date, [Одобрено] , 104), 'yyyy-MM-01') Месяц
	,case 
		when cast(ГодЗаявки as varchar(4)) =  (cast(datepart(yy,dateadd(dd,-1,cast(getdate() as date))) as varchar(4))) then 'Текущий год' else cast(ГодЗаявки as varchar(4)) 
	end [Год текст]
into  #tud7
from #fa fa
group by format(convert(date, [Одобрено] , 104), 'yyyy-MM-01')
	,case when cast(ГодЗаявки as varchar(4)) =  (cast(datepart(yy,dateadd(dd,-1,cast(getdate() as date))) as varchar(4))) then 'Текущий год' else cast(ГодЗаявки as varchar(4)) end

drop table if exists #tud8

select 
	sum(iif(convert(varchar(10),fa.[Заем выдан],104) = convert(varchar(10),fa.Одобрено,104), 1,0)) ОдобреноВДеньВыдачи,
	'ЗаймВыданВДеньОдобрения' Значение
	,format(convert(date, [Заем выдан] , 104), 'yyyy-MM-01')  Месяц
	,case 
		when cast(ГодВыдачи as varchar(4)) =  (cast(datepart(yy,dateadd(dd,-1,cast(getdate() as date))) as varchar(4))) then 'Текущий год' else cast(ГодВыдачи as varchar(4)) 
	end [Год текст]
	into  #tud8
from #fa fa
where [Заем выдан] is not null and fa.isInstallment = 0
group by format(convert(date, [Заем выдан] , 104), 'yyyy-MM-01')
	,case when cast(ГодВыдачи as varchar(4)) =  (cast(datepart(yy,dateadd(dd,-1,cast(getdate() as date))) as varchar(4))) then 'Текущий год' else cast(ГодВыдачи as varchar(4)) end


drop table if exists #vechtudel

select 
	t1.Одобрено  - t2.Одобрено Дельта,
	'Одобрено' Значение,
	'Дельта' Месяц,
	'Текущий год' Год
-- into Analytics.dbo.[Отчет вечерний TUдельта] 
into #vechtudel
from #tud1 t1
join #tud2 t2 on t1.Значение = t2.Значение

union 

select 
	t3.ЗаймвДеньОдобрения- t4.ЗаймвДеньОдобрения Дельта,
	'ЗаймВыданВДеньОдобрения' Значение,
	'Дельта' Показатель,
	'Текущий год' Год
from #tud3 t3
join #tud4 t4 on t3.Значение = t4.Значение


union 

select 
	round((cast(sum(t5.TUвДеньОдобрения) as float)- cast(sum(t6.TUвДеньОдобрения) as float))*100,2) Дельта,
	'TUвДеньОдобрения %' Значение,
	'Дельта' Показатель,
	'Текущий год' Год
from #tud5 t5
join #tud6 t6 on t5.Значение = t6.Значение

union

select 
	sum(ПризнакОдобрено) Одобрено,
	'Одобрено' Значение
	,format(convert(date, [Одобрено] , 104), 'yyyy-MM-01') Месяц
	,case 
		when cast(ГодЗаявки as varchar(4)) =  (cast(datepart(yy,dateadd(dd,-1,cast(getdate() as date))) as varchar(4))) then 'Текущий год' else cast(ГодЗаявки as varchar(4)) 
	end [Год текст]
from #fa fa
group by format(convert(date, [Одобрено] , 104), 'yyyy-MM-01')
	,case when cast(ГодЗаявки as varchar(4)) =  (cast(datepart(yy,dateadd(dd,-1,cast(getdate() as date))) as varchar(4))) then 'Текущий год' else cast(ГодЗаявки as varchar(4)) end

union 

select 
	sum(iif(convert(varchar(10),fa.[Заем выдан],104) = convert(varchar(10),fa.Одобрено,104), 1,0)) ОдобреноВДеньВыдачи,
	'ЗаймВыданВДеньОдобрения' Значение
	,format(convert(date, [Заем выдан] , 104), 'yyyy-MM-01')  Месяц
	,case 
		when cast(ГодВыдачи as varchar(4)) =  (cast(datepart(yy,dateadd(dd,-1,cast(getdate() as date))) as varchar(4))) then 'Текущий год' else cast(ГодВыдачи as varchar(4)) 
	end [Год текст]
from #fa fa
where [Заем выдан] is not null and fa.isInstallment = 0
group by format(convert(date, [Заем выдан] , 104), 'yyyy-MM-01')
	,case when cast(ГодВыдачи as varchar(4)) =  (cast(datepart(yy,dateadd(dd,-1,cast(getdate() as date))) as varchar(4))) then 'Текущий год' else cast(ГодВыдачи as varchar(4)) end

union 

select 
	round(cast(sum(tud8.ОдобреноВДеньВыдачи) as float)/cast(sum(tud7.Одобрено) as float) *100,2) TUвДеньОдобрения,
	'TUвДеньОдобрения %' Значение
	,tud7.Месяц  Месяц
	 ,tud7.[Год текст] [Год текст]
from #tud7 tud7 
join #tud8 tud8 on tud7.Месяц = tud8.Месяц
group by tud7.Месяц  
	 ,tud7.[Год текст]


	--Таблица TU 


-- DROP TABLE IF EXISTS Analytics.dbo.[Отчет вечерний TU]

DROP TABLE IF EXISTS #tu1

select cast([Одобрено] as date) Дата,
	sum(ПризнакОдобрено) Одобрено,
	'Одобрено' Значение
	,case
		when format(convert(date, [Одобрено] , 104), 'yyyy-MM-01')  = format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' 
		when format(convert(date, [Одобрено] , 104), 'yyyy-MM-01') = format( dateadd(month, -1, getdate())  , 'yyyy-MM-01') then 'Предыдущий месяц' 
		else format(convert(date, [Одобрено] , 104), 'yyyy-MM-01') 
	end Месяц
into #tu1
from #fa fa
group by cast([Одобрено] as date),
	case
		when format(convert(date, [Одобрено] , 104), 'yyyy-MM-01')  = format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' 
		when format(convert(date, [Одобрено] , 104), 'yyyy-MM-01') = format( dateadd(month, -1, getdate())  , 'yyyy-MM-01') then 'Предыдущий месяц' 
		else format(convert(date, [Одобрено] , 104), 'yyyy-MM-01') 
	end 

DROP TABLE IF EXISTS #tu2

select cast([Заем выдан] as date) МесяцВыдачи,
	sum(iif(convert(varchar(10),fa.[Заем выдан],104) = convert(varchar(10),fa.Одобрено,104), 1,0)) ОдобреноВДеньВыдачи,
	'ЗаймВыданВДеньОдобрения' Значение
	,case
		when format(convert(date, [Заем выдан] , 104), 'yyyy-MM-01')  = format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' 
		when format(convert(date, [Заем выдан] , 104), 'yyyy-MM-01') = format( dateadd(month, -1, getdate())  , 'yyyy-MM-01') then 'Предыдущий месяц' 
		else format(convert(date, [Заем выдан] , 104), 'yyyy-MM-01') 
	end Месяц
into  #tu2
from #fa fa
where [Заем выдан] is not null and fa.isInstallment = 0
group by cast([Заем выдан] as date),
	case
		when format(convert(date, [Заем выдан] , 104), 'yyyy-MM-01')  = format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' 
		when format(convert(date, [Заем выдан] , 104), 'yyyy-MM-01') = format( dateadd(month, -1, getdate())  , 'yyyy-MM-01') then 'Предыдущий месяц' 
		else format(convert(date, [Заем выдан] , 104), 'yyyy-MM-01') 
	end 

DROP TABLE IF EXISTS #vechtu

select * 
into #vechtu
-- into  Analytics.dbo.[Отчет вечерний TU]
from #tu1

union 

select * from #tu2

union

select tu1.Дата МесяцВыдачи,
	round(cast(sum(tu2.ОдобреноВДеньВыдачи)  as float) / cast(sum(tu1.Одобрено) as float) *100,2) TUвДеньОдобрения,
	'TUвДеньОдобрения %' Значение
	,tu1.Месяц
from #tu1 tu1
join #tu2 tu2 on tu1.Дата = tu2.МесяцВыдачи
group by tu1.Дата, tu1.Месяц

 -- Таблица План-факт

-- drop table if exists Analytics.dbo.[Отчет вечерний План_факт]

drop table if exists #cpl 

select cast(format(Дата, 'yyyy-MM-01') as date) Месяц, cast(Дата as date) Дата
	, [Займы руб]
	, [Займы руб]/ nullif((sum([Займы руб]) over(partition by cast(format(Дата, 'yyyy-MM-01') as date))+0.0), 0) [weight of day] 
into #cpl 
from stg.files.contactcenterplans_buffer_stg a 
where Дата>='20200101'
--select * from #cpl

drop table if exists #chpl

select c.Месяц
	, c.Дата
	, iif(b.[Вид займа] = 'Новые','Новые','Повторные') ВидЗайма
	, sum([Выданная сумма]*[weight of day]) [Выданная сумма]
into #chpl
from #cpl c
	join stg.files.[план по каналам_stg] b on c.Месяц=b.Месяц
where b.[Тип продукта] = 'ПТС'
group by c.Месяц
	, c.Дата
	, iif(b.[Вид займа] = 'Новые','Новые','Повторные')

drop table if exists #fa1 

select cast([Заем выдан] as date) ДатаВыдачи
	,iif([Вид займа] = 'Первичный','Новые','Повторные') ВидЗайма
	,sum([Выданная сумма]) 'Выданная сумма'
into #fa1 
from #fa
where [Заем выдан] is not null and isinstallment = 0
group by cast([Заем выдан] as date)
	,iif([Вид займа] = 'Первичный','Новые','Повторные')

drop table if exists #vechpf

select c.Дата, 
	c.ВидЗайма,
	c.[Выданная сумма] План,
	fa.[Выданная сумма],
	round(cast(fa.[Выданная сумма] as float) / cast(c.[Выданная сумма] as float) *100,2) '%Выполнения',
	case when format(c.Дата   , 'yyyy-MM-01') =  format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' else format(c.Дата   , 'yyyy-MM-01') end [Дата месяц текст]
-- into Analytics.dbo.[Отчет вечерний План_факт]
into #vechpf
from #chpl c
left join #fa1 fa on fa.ДатаВыдачи = c.Дата and fa.ВидЗайма = c.ВидЗайма 

	-- Таблица План-показатели
-- drop table if exists Analytics.dbo.[Отчет вечерний План_показатели]


drop table if exists #plf

create table #plf(
    pok_name nvarchar(100),
	position int
);

insert into 
	#plf (pok_name, position)
values 
	('План',1),
	('Факт',2),
	('Выполнено %',3),
	('Осталось до плана',4)

drop table if exists #fa2

select convert(varchar(10), [Заем выдан], 104) Дата,
	sum([Выданная сумма]) 'Сумма факт',
	sum([СуммаДопУслугCarmoneyNet]) 'Сумма КП'
into #fa2
from #fa
where isinstallment = 0 and [Заем выдан] is not null
group by convert(varchar(10), [Заем выдан], 104)
order by 1 

drop table if exists #p1

SELECT 'План' Значение,
	[Займы руб] Сегодня
into #p1
 FROM stg.files.contactcenterplans_buffer_stg d
 where case when format(Дата   , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') then 'Сегодня' else format(Дата   , 'yyyy-MM-dd') end = 'Сегодня'
 
 union
 
 SELECT 'Факт' Значение,
	sum([Выданная сумма]) Факт
 FROM #fa
 where case when format([Заем выдан]   , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') then 'Сегодня' else format([Заем выдан]   , 'yyyy-MM-dd') end = 'Сегодня' and isinstallment = 0 
 
 union
 
 SELECT 'Выполнено %' Значение,
	fa1.[Сумма факт]/[Займы руб]*100 '%Выполнения'
 FROM stg.files.contactcenterplans_buffer_stg d
 join #fa2 fa1 on convert(varchar(10), d.Дата, 104) = fa1.Дата
 where case when format(d.Дата   , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') then 'Сегодня' else format(d.Дата   , 'yyyy-MM-dd') end = 'Сегодня'
  
  union
 
 SELECT 'Осталось до плана' Значение,
	[Займы руб] - fa1.[Сумма факт] 'Осталось до плана'
 FROM stg.files.contactcenterplans_buffer_stg d
  join #fa2 fa1 on convert(varchar(10), d.Дата, 104) = fa1.Дата
 where case when format(d.Дата   , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') then 'Сегодня' else format(d.Дата   , 'yyyy-MM-dd') end = 'Сегодня'
order by 2 desc

drop table if exists #p2

SELECT 'План' Значение,
	sum([Займы руб]) Месяц
into #p2
 FROM stg.files.contactcenterplans_buffer_stg d
 where case when format(d.Дата   , 'yyyy-MM-01') =  format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' else format(Дата  , 'yyyy-MM-01') end  = 'Текущий месяц'
 
 union

 SELECT 'Факт' Значение,
	sum([Выданная сумма]) Факт
 FROM #fa
 where case when format([Заем выдан]   , 'yyyy-MM-01') =  format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' else format([Заем выдан]   , 'yyyy-MM-01') end  = 'Текущий месяц' and isinstallment = 0 

 union
 
 SELECT 'Выполнено %' Значение,
	sum(fa1.[Сумма факт])/sum([Займы руб])*100 '%Выполнения'
 FROM stg.files.contactcenterplans_buffer_stg d
 left join #fa2 fa1 on convert(varchar(10), d.Дата, 104) = fa1.Дата
 where case when format(d.Дата   , 'yyyy-MM-01') =  format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' else format(d.Дата   , 'yyyy-MM-01') end  = 'Текущий месяц'
  
  union
  
  SELECT 'Осталось до плана' Значение,
	sum([Займы руб])- sum(fa1.[Сумма факт]) 'Осталось до плана'
 FROM stg.files.contactcenterplans_buffer_stg d
 left join #fa2 fa1 on convert(varchar(10), d.Дата, 104) = fa1.Дата
 where case when format(d.Дата   , 'yyyy-MM-01') =  format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' else format(d.Дата   , 'yyyy-MM-01') end  = 'Текущий месяц'
order by 2 desc


drop table if exists #p3

SELECT 'План' Значение,
	[План КП аналитический по дням] Сегодня
into #p3
 FROM stg.files.contactcenterplans_buffer_stg d
 where case when format(Дата   , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') then 'Сегодня' else format(Дата   , 'yyyy-MM-dd') end = 'Сегодня'

 union

 SELECT 'Факт' Значение,
	sum([Сумма КП]) Факт
 FROM #fa2
 where case when format(convert(date,Дата,104)  , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') then 'Сегодня' else format(convert(date,Дата,104)   , 'yyyy-MM-dd') end = 'Сегодня'
 
 union
 
 SELECT 'Выполнено %' Значение,
	sum([Сумма КП])/sum([План КП аналитический по дням])*100 '%Выполнения'
 FROM stg.files.contactcenterplans_buffer_stg d
 join #fa2 fa1 on convert(varchar(10), d.Дата, 104) = fa1.Дата
 where case when format(d.Дата   , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') then 'Сегодня' else format(d.Дата   , 'yyyy-MM-dd') end = 'Сегодня'
 
 union

  SELECT 'Осталось до плана' Значение,
	sum([План КП аналитический по дням]) - sum([Сумма КП]) 'Осталось до плана'
 FROM stg.files.contactcenterplans_buffer_stg d
 join #fa2 fa1 on convert(varchar(10), d.Дата, 104) = fa1.Дата
 where case when format(d.Дата   , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') then 'Сегодня' else format(d.Дата  , 'yyyy-MM-dd') end = 'Сегодня'
order by 2 desc

drop table if exists #p4

SELECT 'План' Значение,
	sum([План КП аналитический по дням]) Месяц
into #p4
 FROM stg.files.contactcenterplans_buffer_stg d
 where case when format(Дата   , 'yyyy-MM-01') =  format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' else format(Дата   , 'yyyy-MM-01') end  = 'Текущий месяц'

 union

 SELECT 'Факт' Значение,
	sum([Сумма КП]) Факт
 FROM #fa2
 where case when format(convert(date,Дата,104)   , 'yyyy-MM-01') =  format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' else format(convert(date,Дата,104)   , 'yyyy-MM-01') end  = 'Текущий месяц'

 union

  SELECT 'Выполнено %' Значение,
	sum([Сумма КП])/sum([План КП аналитический по дням])*100 '%Выполнения'
  FROM stg.files.contactcenterplans_buffer_stg d
 left join #fa2 fa1 on convert(varchar(10), d.Дата, 104) = fa1.Дата
 where case when format(d.Дата   , 'yyyy-MM-01') =  format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' else format(d.Дата   , 'yyyy-MM-01') end  = 'Текущий месяц'
 
 union

  SELECT 'Осталось до плана' Значение,
	sum([План КП аналитический по дням])- sum([Сумма КП]) 'Осталось до плана'
 FROM stg.files.contactcenterplans_buffer_stg d
 left join #fa2 fa1 on convert(varchar(10), d.Дата, 104) = fa1.Дата
 where case when format(d.Дата   , 'yyyy-MM-01') =  format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' else format(d.Дата   , 'yyyy-MM-01') end  = 'Текущий месяц'
order by 2 desc

drop table if exists #p5

SELECT 'План' Значение,
	[План по ставке] Сегодня
into #p5
 FROM [Stg].[files].[contactcenterplans_buffer_stg] d
 where case when format(Дата   , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') then 'Сегодня' else format(Дата   , 'yyyy-MM-dd') end = 'Сегодня'

 union

 SELECT 'Факт' Значение,
	sum(cast(d.[Выданная сумма] * d.ПроцСтавкаКредит as real)/100)/sum(d.[Выданная сумма])*100 Факт
 FROM #fa d
 where case when format(d.[Заем выдан]   , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') then 'Сегодня' else format(d.[Заем выдан]   , 'yyyy-MM-dd') end = 'Сегодня' and isinstallment = 0

 union

  SELECT 'Выполнено %' Значение,
	sum(cast(d.[Выданная сумма] * d.ПроцСтавкаКредит as real)/100)/sum(d.[Выданная сумма])*100
	/(select  [План по ставке] Сегодня
	 FROM [Stg].[files].[contactcenterplans_buffer_stg] d
	 where case when format(Дата   , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') then 'Сегодня' else format(Дата   , 'yyyy-MM-dd') end = 'Сегодня')*100 '%Выполнения'
 FROM #fa d
 where case when format(d.[Заем выдан]   , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') then 'Сегодня' else format(d.[Заем выдан]   , 'yyyy-MM-dd') end  = 'Сегодня' and d.isinstallment = 0

  union

  SELECT 'Осталось до плана' Значение,
	(select  avg([План по ставке]) Сегодня
	 FROM [Stg].[files].[contactcenterplans_buffer_stg] d
	 where case when format(Дата   , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') then 'Сегодня' else format(Дата   , 'yyyy-MM-dd') end = 'Сегодня') - 
	 (sum(cast(d.[Выданная сумма] * d.ПроцСтавкаКредит as real)/100)/sum(d.[Выданная сумма]))*100 'Осталось до плана'
 FROM #fa d
 where case when format(d.[Заем выдан]   , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') then 'Сегодня' else format(d.[Заем выдан]   , 'yyyy-MM-dd') end = 'Сегодня' and isinstallment = 0
order by 2 desc

drop table if exists #p6

SELECT 'План' Значение,
	avg([План по ставке]) Месяц
into #p6
 FROM [Stg].[files].[contactcenterplans_buffer_stg] d
 where case when format(Дата   , 'yyyy-MM-01') =  format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' else format(Дата   , 'yyyy-MM-01') end  = 'Текущий месяц'

 union

 SELECT 'Факт' Значение,
	sum(cast(d.[Выданная сумма] * d.ПроцСтавкаКредит as real)/100)/sum(d.[Выданная сумма])*100 Факт
 FROM #fa d
where case when format(d.[Заем выдан]   , 'yyyy-MM-01') =  format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' else format(d.[Заем выдан]   , 'yyyy-MM-01') end  = 'Текущий месяц' and isinstallment = 0

 union

  SELECT 'Выполнено %' Значение,
	sum(cast(d.[Выданная сумма] * d.ПроцСтавкаКредит as real)/100)/sum(d.[Выданная сумма])*100/
	(select  avg([План по ставке]) Сегодня
	 FROM [Stg].[files].[contactcenterplans_buffer_stg] d
	 where case when format(Дата   , 'yyyy-MM-01') =  format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' else format(Дата   , 'yyyy-MM-01') end  = 'Текущий месяц')*100 '%Выполнения'
 FROM #fa d
 where case when format(d.[Заем выдан]  , 'yyyy-MM-01') =  format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' else format(d.[Заем выдан]   , 'yyyy-MM-01') end  = 'Текущий месяц' and isinstallment = 0

  union

  SELECT 'Осталось до плана' Значение,
	(select  avg([План по ставке]) Месяц
	 FROM [Stg].[files].[contactcenterplans_buffer_stg] d
	 where case when format(Дата   , 'yyyy-MM-01') =  format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' else format(Дата   , 'yyyy-MM-01') end  = 'Текущий месяц') - 
	 (sum(cast(d.[Выданная сумма] * d.ПроцСтавкаКредит as real)/100)/sum(d.[Выданная сумма]))*100 'Осталось до плана'
 FROM #fa d
 where case when format(d.[Заем выдан]   , 'yyyy-MM-01') =  format( getdate()  , 'yyyy-MM-01') then 'Текущий месяц' else format(d.[Заем выдан]   , 'yyyy-MM-01') end  = 'Текущий месяц' and isinstallment = 0
order by 2 desc

drop table if exists #vechpp

select 'Выдачи' Наименование, 
	p.position, 
	p1.Значение Показатель,
	round(p1.Сегодня,0) Сегодня
	,round(p2.Месяц,0) Месяц
-- into Analytics.dbo.[Отчет вечерний План_показатели]
into #vechpp
from #p1 p1 (nolock)
join #p2 p2 (nolock) on p1.Значение=p2.Значение
join #plf p on p1.Значение = p.pok_name

union 

select 'КП' Значение,
	p.position, 
p3.Значение Показатель,
	round(p3.Сегодня,0) Сегодня
	,round(p4.Месяц,0) Месяц
from #p3 p3 (nolock)
join #p4 p4 (nolock) on p3.Значение=p4.Значение
join #plf p on p3.Значение = p.pok_name

union



select 'Ставка' Значение,
	p.position,
	p5.Значение Показатель,
	round(p5.Сегодня,1) Сегодня,
	round(p6.Месяц,1) Месяц 
from #p5 p5 
join #p6 p6 on p5.Значение=p6.Значение
join #plf p on p.pok_name = p5.Значение


 --Таблица сводные показатели

 -- drop table if exists Analytics.dbo.[Отчет вечерний Сводные_показатели]

drop table if exists #meetings_w_rn_2

SELECT
             m.[Ссылка]
      ,dateadd(year, -2000, cast(format(m.Дата, 'yyyy-MM-ddTHH:mm:00') as datetime)) ДатаВстречи
      ,dateadd(year, -2000, cast(format(m.ДатаПоВремениКлиента, 'yyyy-MM-ddTHH:mm:00') as datetime)) ДатаВстречиПоВРемениКлиента
	  ,z.МобильныйТелефон Телефон
	  ,z.Номер НомерЗаявки
	  ,dateadd(year, -2000, z.Дата) ДатаЗаявки
	  ,ROW_NUMBER() over(partition by z.Номер order by ДатаМодификации desc) rn
	  ,Сумма
	  into  #meetings_w_rn_2
        FROM [Stg].[_1cCRM].[Документ_CRM_Мероприятие] m (nolock)
		left join [Stg].[_1cCRM].[Документ_CRM_Взаимодействие]  v (nolock) on  m.[ВзаимодействиеОснование]=v.[Ссылка]  
		left join [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] z (nolock) on  v.[Заявка_Ссылка]=z.[Ссылка] 

		where m.ПометкаУдаления=0 and year(m.ДатаПоВремениКлиента)>4000
		
drop table if exists  #vechsp
		select  
		'Кол-во встреч в офис на завтра' Показатель,
		count(ДатаВстречи) Количество,
		null Сумма
--		into Analytics.dbo.[Отчет вечерний Сводные_показатели]
into #vechsp



		
		from #meetings_w_rn_2

where 
		cast(ДатаВстречи as date)=cast(getdate()+1 as date) and rn=1

union

select 
	'На рассмотрении' Показатель,
	sum([ПризнакКонтрольданных]) Количество,
	sum([Сумма заявки]) СуммаЗаявки
from #fa
where [Одобрено] is null and Дубль = 0 and [ПризнакКонтрольданных]=1 and [Текущий статус] not in ('Аннулировано',
'Забраковано',
'Заем аннулирован',
'Клиент передумал',
'Отказ документов клиента',
'Отказано')



union

select 
	'Одобренные' Показатель,
	sum([ПризнакОдобрено]) Количество,
	sum([Сумма заявки]) СуммаЗаявки
from #fa
where  [Заем выдан] is null and Дубль = 0 and [ПризнакОдобрено]=1 and [Текущий статус] not in ('Аннулировано',
	'Забраковано',
	'Заем аннулирован',
	'Клиент передумал')


union 

select 
	'Контроль получения ДС' Показатель,
	sum([ПризнакЗаявка]) Количество,
	sum([Сумма заявки]) СуммаЗаявки
from #fa
where [Текущий статус] = 'Контроль получения ДС'

union 

select 
	'Выдано' Показатель,
	sum([ПризнакЗайм]) Количество,
	sum([Выданная сумма]) СуммаЗаявки
from #fa
where convert(nvarchar(10),[Заем выдан],104) = convert(nvarchar(10),getdate(),104) 

-- Показатель rr
 
--  drop table if exists Analytics.dbo.[Отчет вечерний rr]

drop table if exists #fa3 

select cast([Заем выдан] as date) ДатаВыдачи
	,sum([Выданная сумма]) 'Выданная сумма'
into #fa3 
from #fa
where [Заем выдан] is not null and format(convert(date, [Заем выдан] , 104), 'yyyy-MM-01')  = format( getdate()  , 'yyyy-MM-01') and isinstallment = 0
group by cast([Заем выдан] as date)
	
	
drop table if exists #vechrr
	
select 
	round(sum(fa3.[Выданная сумма]) / sum(c.[Займы руб]) *100,2) '%Выполнения'
--	into Analytics.dbo.[Отчет вечерний rr]
into #vechrr
from stg.files.contactcenterplans_buffer_stg c
left join #fa3 fa3 on fa3.ДатаВыдачи = c.Дата
where format(convert(date, ДатаВыдачи , 104), 'yyyy-MM-01')  = format( getdate()  , 'yyyy-MM-01')

-- Таблица UpSale

-- drop table if exists Analytics.dbo.[Отчет вечерний UpSale]
drop table if exists #upsale

select 	fa.[Заем выдан]
	,fa.Номер
	,fa.[Текущий статус]
	,fa.[Место cоздания]
	,fa.ФИО
    ,fa.МесяцЗаявки
	,fa.[Выданная сумма]
	,fa.[Сумма одобренная]
	,fa.[Первичная сумма]
	,fa.Одобрено
    ,fa.Дата
    ,fa.[ПризнакОдобрено]
	,IIF(fa.[Сумма одобренная] > fa.[Выданная сумма], 1, 0) 'Одобрено больше выданного'
	,CASE 
		WHEN format(fa.[Заем выдан]   , 'yyyy-MM-dd') =  format( getdate()  , 'yyyy-MM-dd') THEN 'Сегодня' ELSE format(fa.[Заем выдан]   , 'yyyy-MM-dd') 
	END [Дата выдачи день текст] 
-- INTO Analytics.dbo.[Отчет вечерний upsale]
into #upsale
FROM #fa fa
WHERE fa.[Заем выдан] is not null 


begin tran

delete from Analytics.dbo.[Отчет вечерний UpSale]
insert into Analytics.dbo.[Отчет вечерний UpSale]
select *
from #upsale


delete from  Analytics.dbo.[Отчет вечерний TUдельта]
insert into Analytics.dbo.[Отчет вечерний TUдельта]
select *
from #vechtudel

delete from Analytics.dbo.[Отчет вечерний TU]
insert into Analytics.dbo.[Отчет вечерний TU]
select *
from #vechtu

delete from Analytics.dbo.[Отчет вечерний План_факт]
insert into Analytics.dbo.[Отчет вечерний План_факт]
select *
from #vechpf

delete from Analytics.dbo.[Отчет вечерний План_показатели]
insert into Analytics.dbo.[Отчет вечерний План_показатели]
select *
from #vechpp

delete from Analytics.dbo.[Отчет вечерний Сводные_показатели]
insert into Analytics.dbo.[Отчет вечерний Сводные_показатели]
select *
from #vechsp

delete from  Analytics.dbo.[Отчет вечерний rr]
insert into  Analytics.dbo.[Отчет вечерний rr]
select *
from #vechrr

commit tran




exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob 'b91cb9b4-a9c4-4d93-b9e2-106354ba4796'

end
