
CREATE   proc [dbo].[Проверка наличия заявок по RBP]
@treshold int = 300
as

begin
--return 

drop table if exists #t1

	-- declare @treshold int = 300
   ;
with v as (

select case when RBP = 'RBP - 86' then 'RBP - 86' else 'RBP - 40/56/66' end RBP, max(ДатаЗаявкиПолная) ДатаЗаявкиПолная --into #t1 
from reports.dbo.dm_Factor_Analysis_001
where isPts=1 and RBP not in ('non-RBP')
group by case when RBP = 'RBP - 86' then 'RBP - 86' else 'RBP - 40/56/66' end
)

select * into #t1 from (
select 
Текст = string_agg( 'Последняя заявка по '+b.RBP+': '+format(b.ДатаЗаявкиПолная, 'dd-MMM HH:mm')+', а по '+a.RBP+': '+format(a.ДатаЗаявкиПолная, 'dd-MMM HH:mm') , '
'),
send_to = 'blagoveschenskaya@carmoney.ru; davydova@carmoney.ru; p.ilin@techmoney.ru',
subject = 'Отсутсвие заявок по RBP'
from v a
left join v b on b.RBP='RBP - 86'
where  datediff(MINUTE, a.ДатаЗаявкиПолная, b.ДатаЗаявкиПолная)>@treshold			  and  datepart(hour, b.ДатаЗаявкиПолная )>=11
)
x
where Текст is not null 
and datepart(hour, getdate())>9
--and 1=0

declare @text_rbp_monitoring nvarchar(max) = (select Текст from #t1)
declare @text_rbp_monitoring_old nvarchar(max) = (select text_rbp_monitoring from config)

update 	config set 	   text_rbp_monitoring = @text_rbp_monitoring

   
if (select case 
when  @text_rbp_monitoring is null  and	@text_rbp_monitoring_old  is not null then 1
   
end)=1
	begin
		 select 'Заявки по RBP появлись' , 'blagoveschenskaya@carmoney.ru; davydova@carmoney.ru; p.ilin@techmoney.ru', 'Заявки по RBP появлись'
return
end

if (select case 
when  @text_rbp_monitoring  =	@text_rbp_monitoring_old   then 1
   
end)=1
	begin
return
end
else begin

   select * from #t1

   end
end
--exec  [dbo].[Проверка наличия заявок по RBP]