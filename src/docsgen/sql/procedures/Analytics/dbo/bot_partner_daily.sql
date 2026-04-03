
CREATE   proc [dbo].[bot_partner_daily]

as

begin

drop table if exists #t3

declare @report_date date = getdate()-1

;
with v as (
--declare @report_date date = getdate()-1

--
select  a.Регион,  c.Дата , sum(a.Доля*b.[Выданная сумма]*[weight of day] ) Сумма from sale_plan_partner  a 
--select  a.Регион,  c.Дата , sum(a.Доля*b.[Выданная сумма]*[weight of day] ) Сумма from stg.files.[план продаж партнеры_stg] a 

join sale_plan_channel b on a.Месяц=b.Месяц and b.[Группа каналов]='Партнеры' and [Тип продукта]='ПТС' and b.Месяц=cast(format(@report_date, 'yyyy-MM-01') as date)
--join (select cast(Дата as date) Дата, cast(format(Дата, 'yyyy-MM-01') as date) Месяц, [Займы руб]/(sum([Займы руб]) over(partition by cast(format(Дата, 'yyyy-MM-01') as date))+0.0) [weight of day] from  stg.files.contactcenterplans_buffer_stg ) c on a.Месяц=c.Месяц
join (select cast(date as date) Дата, cast(format(date, 'yyyy-MM-01') as date) Месяц, ptsSum/(sum(ptsSum) over(partition by cast(format(date, 'yyyy-MM-01') as date))+0.0) [weight of day] from  sale_plan ) c on a.Месяц=c.Месяц

group by  a.Месяц, a.Регион,  c.Дата
)
, rr as (
select Регион Регион, sum(Сумма) Сумма_План, sum(case when Дата<=@report_date then Сумма end ) Сумма_План_RR from v

group by Регион
)




select text = (
select *, format( getdate(), 'dd-MMM HH:mm:ss') created from    (
select Регион, format( isnull(Штуки , 0) , '#,0') Штуки, format( isnull([Выданная сумма] , 0) , '#,0') Сумма, format(isnull(Чек , 0)  , '#,0') Чек ,  format(Сумма_План, '#,0')  Сумма_План, format( isnull([Выданная сумма] , 0)/Сумма_План , '0%' ) [% выполнения] from rr a

left join (
--declare @report_date date = getdate()-1

select РО_регион, sum([Выданная сумма]) [Выданная сумма], count([Выданная сумма]) Штуки, avg([Выданная сумма]) Чек  from v_fa 
where [Группа каналов] ='Партнеры' and
isPts=1 and
cast([Заем выдан] as date) <=@report_date  and 
cast(format([Заем выдан] , 'yyyy-MM-01' ) as date) = cast(format(@report_date, 'yyyy-MM-01') as date) 
group by РО_регион
) f on f.РО_регион=a.Регион

) x 
order by Регион
for json auto
)
into #t3



begin tran

--drop table if exists  dbo.[Оперативная витрина со статистикой для партнеров статистика за месяц]
--select * into  dbo.[Оперативная витрина со статистикой для партнеров статистика за месяц] from #t3
delete from dbo.[Оперативная витрина со статистикой для партнеров статистика за месяц]
insert into dbo.[Оперативная витрина со статистикой для партнеров статистика за месяц]
select *  from #t3

commit tran

--select * from  dbo.[Оперативная витрина со статистикой для партнеров статистика за месяц]


end