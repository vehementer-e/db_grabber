

CREATE     proc [_birs].[Регулярные обзвоны Одобренные но не выданные]


@start_date_ssrs date = null,
@end_date_ssrs date = null

as

begin



drop table if exists #t1, #aproved_wo_loan, #bl

select cast(Phone  as nvarchar(10)) UF_PHONE into #bl
from stg._1ccrm.BlackPhoneList



select Номер					    Номер
,      Телефон						Телефон
,      [РегионПроживания]			[РегионПроживания]
,      [текущийСтатус]				[текущийСтатус]
,      [Вид займа] 					[Вид займа] 
,      ФИо							ФИо
,      Одобрено						Одобрено
,      [Заем выдан]					[Заем выдан]
,      Отказано						Отказано
,      [Отказ документов клиента]	[Отказ документов клиента]
,      [Сумма одобренная]			[Сумма одобренная]
,      Место_создания_2				Место_создания_2
,      Партнер 						Партнер 
,      ispts  						ispts  

into #t1
from reports.dbo.dm_Factor_Analysis
 

declare @start_date date = @start_date_ssrs 
declare @end_date date = @end_date_ssrs






select a.* into #aproved_wo_loan
from      #t1 a 
left join #bl bl on bl.UF_PHONE=A.Телефон
where cast(Одобрено as date) between @start_date and @end_date	   and a.ispts=1
	and [Заем выдан] is null
	and bl.UF_PHONE is null
	and len(Телефон)=10
	and фио not like '%тест %'
	and фио not like '%тестов %'
	and фио not like '%тестовая %'
	and фио not like '% мп %'
	and фио not like '%лкп %'
	and фио not like '%прогон %'





delete from #t1
where Телефон not in (select Телефон
	from #aproved_wo_loan);

	with v as (select *, ROW_NUMBER() over(partition by телефон order by Одобрено) rn from #aproved_wo_loan )
	delete from v where rn>1


select a.Номер                 
,      a.ФИО               
, a.[текущийСтатус] 
,a.[Вид займа] 
,      a.Телефон               
,    o.gmt   as [GMT партнера]
,      cast(a.Одобрено as datetime2)    Дата_Одобрения
, a.[Сумма одобренная] 
, a.Место_создания_2 
, o.capital 
, a.РегионПроживания
from        #aproved_wo_loan                         a             
outer apply (select top 1 *
	from #t1 exclude
	where a.Телефон=exclude.Телефон
		and (
			exclude.Отказано >= a.Одобрено
			or exclude.[Отказ документов клиента] >= a.Одобрено
			or exclude.[Заем выдан] >= a.Одобрено))  x             

left join   v_gmt         o with(nolock) on a.РегионПроживания=o.region
--left join   [Stg].[_1cCRM].Справочник_Офисы          o with(nolock) on a.[Партнер]=o.[Наименование]
--left join   [Stg].[_1cCRM].[Справочник_ЧасовыеПояса] b with(nolock) on o.[Часовойпояс]=b.[Ссылка]
where x.Телефон is null

end