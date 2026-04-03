

CREATE   proc [_birs].[Регулярные обзвоны Предодобренные без КД]

@start_date_ssrs date = null,
@end_date_ssrs date = null

as

begin



drop table if exists #t1, #nedoezd, #bl, #mailyan

select cast(Phone  as nvarchar(10)) UF_PHONE into #bl
from stg._1ccrm.BlackPhoneList



select Номер
,      Телефон
,[текущий Статус] [текущийСтатус]
,[Вид займа] 
,      ФИо
,      [Предварительное одобрение]
,      [Контроль данных]
,      [Заем выдан]
,      Отказано
,      [Отказ документов клиента]
,      [Первичная сумма]
,      [Место создания 2]  Место_создания_2
,      [Регион проживания]
,      Партнер
,1 - isPts isInstallment into #t1
from reports.dbo.dm_Factor_Analysis_001

select 'Партнер № 3177 Новороссийск' Партнер into #mailyan union all 
select 'Партнер № 3154 Самара' union all 
select 'Партнер № 3153 Краснодар' union all 
select 'Партнер № 3132 Таганрог' union all 
select 'Партнер № 3131 Волгоград' union all 
select 'Партнер № 3130 Ростов-на-Дону' union all 
select 'Партнер № 3129 Екатеринбург' union all 
select 'Партнер № 3128 Ставрополь' union all 
select 'Партнер № 2925 Пермь' union all 
select 'Партнер № 2900 Санкт-Петербург' union all 
select 'Партнер № 2856 ст. Багаевская' union all 
select 'Партнер № 2827 Краснодар' union all 
select 'Партнер № 2816 Москва' union all 
select 'Партнер № 2812 Краснодар' union all 
select 'Партнер № 2811 ст. Грушевская' union all 
select 'Партнер № 2810 Новочеркасск' union all 
select 'Партнер № 2809 Самара' union all 
select 'Партнер № 2808 Сочи' union all 
select 'Партнер № 2807 Новороссийск' union all 
select 'Партнер № 2806 Ставрополь' union all 
select 'Партнер № 2805 Екатеринбург' union all 
select 'Партнер № 2804 Батайск' union all 
select 'Партнер № 2803 Ростов-на-Дону' union all 
select 'Партнер № 2802 Ростов-на-Дону' union all 
select 'Партнер № 3223 Екатеринбург' union all 
select 'Партнер № 3245 Нижний Новгород' union all 
select 'Партнер № 3265 Казань' union all 
select 'Партнер № 3368 Москва' union all 
select 'Партнер № 3364 Ижевск' union all 
select 'Партнер № 3407 Москва' union all 
select 'Партнер № 3389 Таганрог' union all 
select 'Партнер № 2306 Санкт-Петербург' union all 
select 'Партнер № 3615 Владивосток' union all 
select 'Партнер № 948 Воронеж' union all 
select 'Партнер № 3645 Рефинансирование' union all 
select 'Партнер № 4692 Москва' union all 
select 'Партнер № 4622 Санкт-Петербург' union all 
select 'Партнер № 4742 Новосибирск' union all 
select 'Партнер № 5067 Волгоград' --union all 


declare @start_date date = @start_date_ssrs 
declare @end_date date = @end_date_ssrs

-- declare @start_date date = '20240301' 
-- declare @end_date date = '20240401'

drop table if exists #nedoezd

select a.*, bl.UF_PHONE into #nedoezd
from      #t1 a 
left join #bl bl on bl.UF_PHONE=A.Телефон
where cast([Предварительное одобрение] as date) between @start_date and @end_date
	
	delete from #nedoezd where  [Контроль данных] is not null
	delete from #nedoezd where   UF_PHONE is not null
	delete from #nedoezd where   len(Телефон)<>10

	delete from #nedoezd where   фио like '%тест %'
	delete from #nedoezd where   фио like '%тестов %'
	delete from #nedoezd where   фио like '%тестовая %'
	delete from #nedoezd where   фио like '% мп %'
	delete from #nedoezd where   фио like '%лкп %'
	delete from #nedoezd where   фио like '%прогон %'





delete from #t1
where Телефон not in (select Телефон
	from #nedoezd);

	with v as (select *, ROW_NUMBER() over(partition by телефон order by [Предварительное одобрение] desc) rn from #nedoezd )
	delete from v where rn>1


select a.Номер                 
,      a.ФИО               
, a.[текущийСтатус] 
, a.[Вид займа] 
,      a.Телефон               
,    [Регион проживания]   as [Регион проживания]
,     gmt.capital   as capital
,     gmt.gmt   as [GMT партнера]
,     a.[Предварительное одобрение]     Дата_Предварительного_Одобрения
, a.[Первичная сумма] 
, a.Место_создания_2 
, a.Партнер 
, case when m.Партнер is not null then 1 else 0 end ТочкаМаилян
,isInstallment
--into #f1
from        #nedoezd                         a             
outer apply (select top 1 Телефон
	from #t1 exclude
	where a.Телефон=exclude.Телефон
		and (
			exclude.Отказано >= a.[Предварительное одобрение]
			or exclude.[Контроль данных] >= a.[Предварительное одобрение]
			or exclude.[Отказ документов клиента] >= a.[Предварительное одобрение]
			or exclude.[Заем выдан] >= a.[Предварительное одобрение]))  x             

--left join   [Stg].[_1cCRM].Справочник_Офисы          o with(nolock) on a.[Партнер]=o.[Наименование]
--left join   [Stg].[_1cCRM].[Справочник_ЧасовыеПояса] b with(nolock) on o.[Часовойпояс]=b.[Ссылка]
left join v_gmt gmt on gmt.region=a.[Регион проживания]
left join   #mailyan m on m.Партнер=a.Партнер
where x.Телефон is null and a.[Вид займа] in ('Первичный', 'Повторный')


--exec create_table '#f1'  
end