
create   proc dbo.sale_partner_report_plan_fact

@report_date date , @mode nvarchar(max)

as


if @mode = '1'
 
--declare @report_date date = getdate()-1


select *,  cast(format([Заем выдан] , 'yyyy-MM-01' ) as date)  Месяц_выдачи, dense_RANK() over(partition by РО_регион order by sum_over_partner desc) dr  from (

select [Заем выдан], Партнер, Юрлицо, РП, РО_регион, [Выданная сумма], sum([Выданная сумма]) over(partition by Юрлицо, РО_регион) sum_over_partner  from 

v_fa
where 
    cast(format([Заем выдан] , 'yyyy-MM-01' ) as date) >= dateadd(month, -3, cast(format(@report_date , 'yyyy-MM-01' ) as date) )
and [Группа каналов] ='Партнеры'
and isPts=1
and cast([Заем выдан] as date) <=@report_date
--and РО_регион='РО Центральный регион'
) x
--order by sum_over_partner desc


 

if @mode = '2'

--declare @report_date date = getdate()-1
 begin
 ; 
with v as (
select  a.Регион,  c.Дата , sum(a.Доля*b.[Выданная сумма]*[weight of day] ) Сумма from sale_plan_partner a 
join sale_plan_channel b on a.Месяц=b.Месяц and b.[Группа каналов]='Партнеры' and [Тип продукта]='ПТС' and b.Месяц=cast(format(@report_date, 'yyyy-MM-01') as date)
join (select cast(date as date) Дата, cast(format(date, 'yyyy-MM-01') as date) Месяц, ptsSum/(sum(ptsSum) over(partition by cast(format(date, 'yyyy-MM-01') as date))+0.0) [weight of day] 

from  sale_plan ) c on a.Месяц=c.Месяц
group by  a.Месяц, a.Регион,  c.Дата
)
, rr as (
select Регион Регион, sum(Сумма) Сумма_План, sum(case when Дата<=@report_date then Сумма end ) Сумма_План_RR from v

group by Регион
)


select * from rr a

left join (
--declare @report_date date = getdate()-1

select РО_регион, sum([Выданная сумма]) [Выданная сумма]  from v_fa
where [Группа каналов] ='Партнеры' and
ispts=1 and
cast([Заем выдан] as date) <=@report_date  and 
cast(format([Заем выдан] , 'yyyy-MM-01' ) as date) = cast(format(@report_date, 'yyyy-MM-01') as date) 
group by РО_регион
) f on f.РО_регион=a.Регион

end

if @mode = '3'

select *
 

from (
select 
    b.Доля
, b.Регион
, cast(a.Дата as date) Дата
, cast(format(a.Дата, 'yyyy-MM-01') as date) Месяц
, ДлоляДня*chan.[Выданная сумма]*b.Доля Сумма_План
from v_calendar a
join sale_plan_partner b on a.Месяц=b.Месяц
left join ( select date Дата , ptsSum/nullif((sum(ptsSum) over(partition by cast(format( date, 'yyyy-MM-01') as date))+0.0), 0) ДлоляДня from  sale_plan  ) ccp  on ccp.Дата=a.Дата
join (select Месяц, sum([Выданная сумма] )  [Выданная сумма] from sale_plan_channel where [Группа каналов]='Партнеры' and [Тип продукта]='ПТС' group by Месяц ) chan on chan.Месяц=a.Месяц
where a.[ПРизнак этот месяц] =1
)
x
left join (select РО_регион, cast([Заем выдан] as date) [Заем выдан день], sum([Выданная сумма])   [Выданная сумма]
from v_fa where ispts=1 and [Группа каналов]='Партнеры' group by РО_регион, cast([Заем выдан] as date)
) f on x.Дата=f.[Заем выдан день] and f.РО_регион=x.Регион