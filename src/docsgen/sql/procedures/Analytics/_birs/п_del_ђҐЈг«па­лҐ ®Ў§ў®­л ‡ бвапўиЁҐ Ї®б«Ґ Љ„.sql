

CREATE   proc [_birs].[Регулярные обзвоны Застрявшие после КД]


@start_date_ssrs date = null,
@end_date_ssrs date = null

as

begin



drop table if exists #t1, #zastr, #bl

select cast(Phone  as nvarchar(10)) UF_PHONE into #bl
from stg._1ccrm.BlackPhoneList




select Номер
,      Телефон
,[Текущий статус] [текущийСтатус]
,      [Регион проживания]
,      ФИо
,[Вид займа]

,      [Контроль данных]
,      [Заем выдан]
,      Одобрено
,      Отказано
,      [Отказ документов клиента]
,      [Первичная сумма]
,      [Место создания 2] Место_создания_2
,      Партнер 
,      isPts  

into #t1
from reports.dbo.dm_Factor_Analysis_001


declare @start_date date = @start_date_ssrs 
declare @end_date date = @end_date_ssrs

--declare @start_date date = '20200101' 
--declare @end_date date = '20210201'

drop table if exists #zastr

select a.*, bl.UF_PHONE into #zastr
from      #t1 a 
left join #bl bl on bl.UF_PHONE=A.Телефон
where cast([Контроль данных] as date) between @start_date and @end_date
	
	delete from #zastr where  Одобрено is not null
	delete from #zastr where  [Отказ документов клиента] is not null
	delete from #zastr where  Отказано is not null
	delete from #zastr where   UF_PHONE is not null
	delete from #zastr where   len(Телефон)<>10
				
	delete from #zastr where   фио like '%тест %'
	delete from #zastr where   фио like '%тестов %'
	delete from #zastr where   фио like '%тестовая %'
	delete from #zastr where   фио like '% мп %'
	delete from #zastr where   фио like '%лкп %'
	delete from #zastr where   фио like '%прогон %'





delete from #t1
where Телефон not in (select Телефон
	from #zastr);

	with v as (select *, ROW_NUMBER() over(partition by телефон order by [Контроль данных]) rn from #zastr )
	delete from v where rn>1


select a.Номер                 
,      a.ФИО               
,      a.[Вид займа]    
, a.[текущийСтатус] 
,      a.Телефон               
,     gmt.gmt as [GMT партнера]
,      cast(a.[Контроль данных] as datetime)    Дата_КД
, a.[Первичная сумма] 
, a.Место_создания_2 
, a.[Регион проживания] 
, a.isPts 
, gmt.capital
--into #f1
from        #zastr                         a             
outer apply (select top 1 Телефон
	from #t1 exclude
	where a.Телефон=exclude.Телефон
		and (
			exclude.Отказано >= a.[Контроль данных]
			or exclude.[Отказ документов клиента] >= a.[Контроль данных]
			or exclude.[Заем выдан] >= a.[Контроль данных]))  x             

--left join   [Stg].[_1cCRM].Справочник_Офисы          o with(nolock) on a.[Партнер]=o.[Наименование]
--left join   [Stg].[_1cCRM].[Справочник_ЧасовыеПояса] b with(nolock) on o.[Часовойпояс]=b.[Ссылка]
left join v_gmt gmt on gmt.region=a.[Регион проживания]
where x.Телефон is null

--exec create_table '#f1'


end