
CREATE   proc [dbo].[Подготовка оперативной витрины со статистикой для партнеров заявки день в день]

as

begin


drop table if exists #z


select  b.ДатаЗаявки
,  b.НомерЗаявки  Номер
,b.СсылкаЗаявки	Ссылка
, b.СтатусЗаявки Статус 
, b.[Сумма Первичная] СуммаПервичная
, isnull(b.ОдобреннаяСумма, 0) ОдобреннаяСуммаВерификаторами
, b.Офис Офис
, '' СтатусСсылка
, b.ДатаСтатуса датастатуса

 into #z

from  v_request b  
where cast(b.ДатаЗаявки as date)=cast(getdate() as date)
and b.СтатусЗаявки in (
'Одобрены документы клиента',
'Одобрено',
'Назначение встречи',
'Контроль одобрения документов клиента',
'Контроль данных',
'Контроль верификация документов клиента',
'Контроль верификации документов',
'Договор подписан',
'Договор зарегистрирован',
'Выполнение контроля данных',
'Встреча назначена',
'Верификация КЦ',
'Верификация документов клиента',
'Верификация документов'
) and МестоСоздания='Оформление на партнерском сайте'
and isnull(Офис, '')<>'Мобильное приложение'
and 1=1

drop table if exists #s


--while exists(			   
--select 1 from [v_Запущенные джобы]
--where 		  step_name='1cCRM2DWH_ЗаявкаНаЗаймПодПТС SSIS'
-- and job_name='etl. 1cCRM2DWH_ЗаявкаНаЗаймПодПТС every 2min from 6 till 23:50'
-- union all
-- select 1 where 0=(select count(*) from _v_sysjobs where step_name='1cCRM2DWH_ЗаявкаНаЗаймПодПТС SSIS' 
-- and Job_Name = 'etl. 1cCRM2DWH_ЗаявкаНаЗаймПодПТС every 2min from 6 till 23:50' )
--
--) 
--begin
--
--
----if @counter=30 begin exec log_email	   'awaiting 1cCRM2DWH_ЗаявкаНаЗаймПодПТС SSIS/ @counter=30'  end 
----select 'waiting',  getdate()
----exec message 'message' 
--waitfor delay '00:00:20'--ожидание 	etl. 1cCRM2DWH_ЗаявкаНаЗаймПодПТС every 2min from 6 till 23:50	 1cCRM2DWH_ЗаявкаНаЗаймПодПТС SSIS
--
--end 
--



--select a.Ссылка, dateadd(year, -2000, max(b.Период ) ) ДатаПоследнегоСтатуса into #s from #z a
--left join stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС b on a.Ссылка=b.Заявка and a.СтатусСсылка=b.Статус
--group by  a.Ссылка

drop table if exists #t2

--select cast(null as nvarchar(max))  j into ##t2

--delete from ##t2
--insert into ##t2
select text = (select
  (
select * from (
select a.СуммаПервичная, format(a.ДатаЗаявки , 'HH:mm:ss') [Дата заявки   ] , a.ОдобреннаяСуммаВерификаторами [Одобр сумма  ], Офис  ,Статус , isnull( format(a.датастатуса, 'HH:mm:ss') , '?') [Дата Статуса], format( getdate(), 'dd-MMM HH:mm:ss') as created
from #z a
--left join #s b on a.Ссылка=b.Ссылка
) x 
order by [Дата заявки   ]--[Дата Статуса] desc

for json auto 
)  x )
into #t2


begin tran

--drop table if exists  dbo.[Оперативная витрина со статистикой для партнеров заявки день в день]
--select * into  dbo.[Оперативная витрина со статистикой для партнеров заявки день в день] from #t3
delete from dbo.[Оперативная витрина со статистикой для партнеров заявки день в день]
insert into dbo.[Оперативная витрина со статистикой для партнеров заявки день в день]
select  isnull(text, '[{"СуммаПервичная":0,"Одобр сумма вериф":0,"Офис":"Нет заявок","Статус":"","Дата Статуса":"","created":"'+format( getdate(), 'dd-MMM HH:mm:ss')+'"}]' )  from #t2

commit tran

--select * from dbo.[Оперативная витрина со статистикой для партнеров заявки день в день]



end