--DWH-995
CREATE   proc dbo.create_dm_report_pep3_loans_sales_info
as
begin



drop table if exists #t1


select z.Номер
,      z.Ссылка
,      sp_st.Наименование as ТекущийСтатус
,      a3.Код КодТочкиПЭП3
,      dateadd(year, -2000, z.Дата) ДатаЗаявки
,      z_vidan.ДатаВыдачи
,      z_pogashen.ДатаПогашения
, Фамилия
, Имя
, Отчество
, МобильныйТелефон
, СерияПаспорта+' '+НомерПаспорта Паспорт
, СуммаВыданная
, getdate() as created
into #t1
from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС z 
left join stg._1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС sp_st on sp_st.Ссылка=z.Статус
join [Stg].[_1cCRM].[Справочник_Офисы]      a3 on z.Офис=a3.Ссылка and Код=2991
join (
select min(dateadd(year, -2000, Период)) ДатаВыдачи, Заявка     
from stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС st
where Статус=0xA81400155D94190011E80784923C6097 
group by Заявка)                           z_vidan on z_vidan.Заявка=z.Ссылка and z_vidan.ДатаВыдачи>='2020-03-24'
left join (
select min(dateadd(year, -2000, Период)) ДатаПогашения, Заявка     
from stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС st
where Статус=0xA81400155D94190011E80784923C6098 
group by Заявка)                           z_pogashen on z_pogashen.Заявка=z.Ссылка 



begin tran
--drop table if exists dbo.dm_report_pep3_loans_sales_info
--select * into dbo.dm_report_pep3_loans_sales_info from #t1
delete from dbo.dm_report_pep3_loans_sales_info
insert into dbo.dm_report_pep3_loans_sales_info
select * from #t1


commit tran



end
