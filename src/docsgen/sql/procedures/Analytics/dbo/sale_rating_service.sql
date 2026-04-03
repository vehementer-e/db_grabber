CREATE   proc [dbo].[sale_rating_service] @mode nvarchar(max) = 'agr'	  , @month date 


as
begin

drop table if exists #op

select distinct * into 	 #op
from (
select 'Борисова Юлия Сергеевна' operator_fio union all
select 'Грачева Юлия Сергеевна' operator_fio union all
select 'Серегина Светлана Викторовна' operator_fio union all
select 'Мусалитина Мария Николаевна' operator_fio union all
select 'Дмитриева Анна Викторовна' operator_fio union all
select 'Чейшвили Елена Владимировна' operator_fio union all
select 'Ефименко Марина Александровна' operator_fio union all
select 'Пенькова Екатерина Эдуардовна' operator_fio union all
select 'Лежепекова Виктория Сергеевна' operator_fio union all
select 'Алямкина Людмила Андреевна' operator_fio union all
select 'Родина Татьяна Николаевна' operator_fio union all
select 'Медведева Марина Алексеевна' operator_fio union all
select 'ИШКОВА ОЛЬГА ФЕДОРОВНА' operator_fio union all
select 'МИНКИНА ОКСАНА АЛЕКСАНДРОВНА' operator_fio union all
select 'КИШЕЧКИН ИВАН АНДРЕЕВИЧ' operator_fio union all
select 'Сенина Екатерина Васильевна' operator_fio union all
select 'Сенина Еатерина Васильевна' operator_fio union all
select 'Юдина Любовь Олеговна' operator_fio union all
select 'Щербина Екатерина Владимировна'
union
select сотрудник from analytics.dbo.employee where направление='Сервис'
) x
		 

if @mode='details'
begin


select 
  a.Номер
, a.ДатаЗаявкиПолная
, a.Автор
, a.[Контроль данных]
, a.[Заем выдан]  
, a.[Выданная сумма]
, a.[Вид займа] 
, a.[Заем погашен]
into #t1
FROM Reports.dbo.dm_Factor_Analysis_001     a   join #op b on b.operator_fio=a.Автор
and ДатаЗаявкиПолная >'20210101'


select a.*, b.[Текущая просрочка] from #t1 a
left join mv_loans b on a.Номер=b.код
order by 1


end


if @mode='agr'
begin

select 
Месяц = cast( format(ДатаЗаявкиПолная, 'yyyy-MM-01' ) as date)
, Автор
, sum(ПризнакЗаявка) 'Кол-во заявок'
, sum(ПризнакКонтрольДанных) 'Кол-во КД'
, sum([Выданная сумма]) 'Выданная сумма'
, 	 isnull(sum(ПризнакЗаявка), 0)*100+  isnull(sum(ПризнакКонтрольДанных), 0)*100 [Бонус]
, case when  cast( format(ДатаЗаявкиПолная, 'yyyy-MM-01' ) as date) =@month then 1 else 0 end [Запрошенный месяц]
FROM v_Fa 		  a	
 join #op b on b.operator_fio=a.Автор
and ДатаЗаявкиПолная >'20210101'
and ispts=1

group by cast( format(ДатаЗаявкиПолная, 'yyyy-MM-01' ) as date), Автор
order by 1, 2

end

end