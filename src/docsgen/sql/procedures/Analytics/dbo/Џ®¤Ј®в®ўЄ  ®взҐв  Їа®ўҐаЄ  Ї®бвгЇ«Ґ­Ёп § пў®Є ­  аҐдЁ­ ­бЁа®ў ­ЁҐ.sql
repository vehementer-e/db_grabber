

CREATE   proc [dbo].[Подготовка отчета проверка поступления заявок на рефинансирование] as
begin



--drop table if exists #t1
--
--select x.* into #t1 from (
-- select 
-- z.Номер as Номер 
-- , isnull(Фамилия, '') +' '+ isnull(Имя, '') +' '+ isnull(Отчество, '') ФИО
--, Дата
--, [Признак Рефинансирование] = case when z.Офис = 0xA2EE00505683924B11EA84B0C7D61A32 /* 3645 id точки рефинансирования*/ or ozz.Заявка is not null then 1 else 0 end
--, getdate() created
-- from 
-- stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС z
-- left join 
-- (
-- select  Заявка--, Офис  
--FROM [Stg].[_1cCRM].[РегистрСведений_ИзмененияВидаЗаполненияВЗаявках]
--where Офис=0xA2EE00505683924B11EA84B0C7D61A32
-- )
-- ozz on ozz.Заявка =  z.ссылка
-- )
-- x
--left join dbo.[Отчет поступившие заявки рефинансирование] b on x.Номер=b.Номер
--
--
-- where [Признак Рефинансирование]=1 and dateadd(year, -2000, x.Дата)>=cast(getdate()-1 as date)
-- and isnumeric(x.Номер)=1 and b.Номер is null

   drop table if exists #t1

select x.* into #t1 from (
 select 
 z.НомерЗаявки as Номер 
 ,  ФИО
, ДатаЗаявки Дата
, [Признак Рефинансирование] =  [ПризнакРефинансирование]
, getdate() created
 from 
 v_request	 z
 )
 x
left join dbo.[Отчет поступившие заявки рефинансирование] b on x.Номер=b.Номер
 where [Признак Рефинансирование]=1 and Дата>=cast(getdate()-1 as date)
 and isnumeric(x.Номер)=1 and b.Номер is null

 

 

;
with v as (
select * , ROW_NUMBER() over(partition by Номер order by (select 1)) rn from #t1
)
delete from v where rn>1


--select a.Номер, фио, getdate() created  into #t1 from reports.dbo.dm_Factor_Analysis_001 a
--left join dbo.[Отчет поступившие заявки рефинансирование] b on a.Номер=b.Номер
--where [Признак рефинансирование]=1   and b.Номер is  null
--and 1=0


--select Номер into dbo.[Отчет поступившие заявки рефинансирование] from reports.dbo.dm_Factor_Analysis_001
--where [Признак рефинансирование]=1 and ДатаЗаявкиПолная<getdate()-3
--

declare @sql nvarchar(max) = (select STRING_AGG( cast( 'exec log_email ''Поступила заявка рефинансирование - '+фио+' - '+Номер+''', ''p.ilin@techmoney.ru; helpagents@carmoney.ru''' as nvarchar(max)) , ';' ) sql_text from #t1)
--select @sql
exec (@sql)

--exec log_email 'Поступила заявка рефинансирование - 22122700634865', 'p.ilin@techmoney.ru';exec log_email 'Поступила заявка рефинансирование - 22122800637207', 'p.ilin@techmoney.ru';exec log_email 'Поступила заявка рефинансирование - 22122600634447', 'p.ilin@techmoney.ru';exec log_email 'Поступила заявка рефинансирование - 22122700635058', 'p.ilin@techmoney.ru';exec log_email 'Поступила заявка рефинансирование - 22122600634430', 'p.ilin@techmoney.ru';exec log_email 'Поступила заявка рефинансирование - 22122700635476', 'p.ilin@techmoney.ru';exec log_email 'Поступила заявка рефинансирование - 22122600634422', 'p.ilin@techmoney.ru';exec log_email 'Поступила заявка рефинансирование - 22122700635458', 'p.ilin@techmoney.ru';exec log_email 'Поступила заявка рефинансирование - 22122800636579', 'p.ilin@techmoney.ru'

insert into dbo.[Отчет поступившие заявки рефинансирование]
select Номер, created from #t1

--alter table dbo.[Отчет поступившие заявки рефинансирование]
--add created datetime2 


--select * from dbo.[Отчет поступившие заявки рефинансирование]
--order by 1 desc
end