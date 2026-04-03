
CREATE   proc [dbo].[Стоимость займа Подготовка отчета]
as 
begin


drop table if exists #fa

select 
Номер
,case when [Группа каналов]   ='cpa'    then  [Канал от источника] else     [Группа каналов] end Канал                                                                                     
,case when [вид займа]='Параллельный' then 'Докредитование' else [вид займа] end [вид займа_3] ,
[Канал от источника],
[Группа каналов],
[Дата заявки день]     =cast(ДатаЗаявкиПолная as date) ,
[Верификация КЦ день]  =cast([Верификация КЦ] as date) ,
[Заем выдан день]      =cast([Заем выдан] as date) ,
[Заем выдан месяц]     =cast(format([Заем выдан], 'yyyy-MM-01') as date) ,
isinstallment,
[Выданная сумма],
[Тип трафика],
[Вид займа]--,

into #fa
from reports.dbo.dm_Factor_Analysis_001
where isnull( cast([Заем выдан] as date) ,cast([Верификация КЦ] as date)) between '20200101' and getdate()-1


--drop table if exists #lcrm
--
--select 
--id,
--UF_ROW_ID,
--uf_source
--
--into #lcrm
--from  stg._LCRM.lcrm_leads_full_channel_request

;
--with v as (select * , ROW_NUMBER() over(partition by UF_ROW_ID order by id) rn from #lcrm ) delete from v where rn>1


--Распределяем расходы на партнеров. Основная часть платится за выдачу, но есть расходы после выдачи - их мы распределяем на поколение которое выдавалось когда произошла оплата

drop table if exists [#партнеры расходы на привлечение_stg]
select a.*, case when b.Номер is null then 1 end [Для распределения] 
into [#партнеры расходы на привлечение_stg]
from stg.files.[партнеры расходы на привлечение] a
left join #fa b on a.Заявка=b.Номер  and case when b.[Заем выдан месяц]=a.Месяц then 1 end =1

drop table if exists [#партнеры расходы на оформление_stg]
select a.*, case when b.Номер is null then 1 end [Для распределения] into [#партнеры расходы на оформление_stg]
from stg.files.[партнеры расходы на оформление_stg] a
left join #fa b on a.Заявка=b.Номер  and case when b.[Заем выдан месяц]=a.Месяц then 1 end =1

drop table if exists [#Сумма оплат за предыдущие периоды для распределения (привлечение)]
select a.Месяц, [Сумма оплат за предыдущие периоды]/nullif(cast(cnt.cnt as float) , 0) [Сумма оплат за предыдущие периоды для распределения в расчете на 1 займ]
into [#Сумма оплат за предыдущие периоды для распределения (привлечение)]  
from (
select a.Месяц, sum(a.Сумма) [Сумма оплат за предыдущие периоды] 
FROM [#партнеры расходы на привлечение_stg] a 
where [Для распределения]=1
group by a.Месяц
) a
left join (select Месяц, count(*) cnt from [#партнеры расходы на привлечение_stg] where [Для распределения] is null group by Месяц ) cnt on cnt.Месяц=a.Месяц

drop table if exists [#Сумма оплат за предыдущие периоды для распределения (оформление)]
select a.Месяц, [Сумма оплат за предыдущие периоды]/nullif(cast(cnt.cnt as float) , 0) [Сумма оплат за предыдущие периоды для распределения в расчете на 1 займ]
into [#Сумма оплат за предыдущие периоды для распределения (оформление)]  
from (
select a.Месяц, sum(a.Сумма) [Сумма оплат за предыдущие периоды] 
FROM [#партнеры расходы на оформление_stg] a 
where [Для распределения]=1
group by a.Месяц
) a
left join (select Месяц, count(*) cnt from [#партнеры расходы на оформление_stg] where [Для распределения] is null group by Месяц ) cnt on cnt.Месяц=a.Месяц


drop table if exists [#партнеры расходы на привлечение]
select a.Месяц, a.Заявка, a.Сумма+isnull(b.[Сумма оплат за предыдущие периоды для распределения в расчете на 1 займ], 0) Сумма
into [#партнеры расходы на привлечение]
from  [#партнеры расходы на привлечение_stg] a
left join [#Сумма оплат за предыдущие периоды для распределения (привлечение)] b on a.Месяц=b.Месяц
where [Для распределения] is null
			  
drop table if exists [#партнеры расходы на оформление]
select a.Месяц, a.Заявка, a.Сумма+isnull(b.[Сумма оплат за предыдущие периоды для распределения в расчете на 1 займ], 0) Сумма
into [#партнеры расходы на оформление]
from  [#партнеры расходы на оформление_stg] a
left join [#Сумма оплат за предыдущие периоды для распределения (оформление)] b on a.Месяц=b.Месяц
where [Для распределения] is null


declare @last_load_привлечение_stg date = (select  cast(format(dateadd(month, 0, max(Месяц)) , 'yyyy-MM-01') as date) max_created from  [#партнеры расходы на привлечение] )
--select @last_load_привлечение_stg
declare @last_load_оформление_stg  date =  (select cast(format(dateadd(month, 0, max(Месяц)) , 'yyyy-MM-01') as date) max_created from  [#партнеры расходы на оформление] )
drop table if exists #f

--собираем основные атрибуты для модели стоимость займа. Партнеры привлечение/оформление, CPC, медийка, прочие, триггеры, CPA

;
with v as (
select a.Номер
, a.[Тип трафика] 
, a.[Канал от источника] 
, a.[Группа каналов]
, [Дата заявки день] 
, isnull(a.[Заем выдан день], [Верификация КЦ день]) [Отчетная дата]
, Канал
, [вид займа_3]
, a.[Заем выдан день]
, a.[Выданная сумма]
, a.[Заем выдан месяц]
, a.isinstallment 
, isnull(p.Сумма, case when po_online.Привлечение ='Привлечение' then po_online.[Общая сумма вознаграждения Агента (в руб)] end) [Партнеры привлечение]
, isnull(o.Сумма, case when po_online.Привлечение ='Оформление' then po_online.[Общая сумма вознаграждения Агента (в руб)] end) [Партнеры оформление]
, [Стоимость займа Распределенные расходы CPA].[Расходы на CPA]  [Расходы на CPA]
, [Стоимость займа Распределенные расходы CPA].[CPA трафик в МП источник]  [CPA трафик в МП источник]
, case when a.[Вид займа]='Первичный' and a.[Группа каналов]='CPC' and a.isInstallment=0 then 1 end / cast(sum(1) over(partition by a.[Вид займа], a.[Заем выдан месяц], a.[Группа каналов], a.isinstallment) as float) [Доля первичных займов CPC ПТС]
, case when a.[Группа каналов]='Триггеры' and a.isInstallment=0 then 1 end / cast(sum(1) over(partition by  a.[Заем выдан месяц], a.[Группа каналов], a.isinstallment) as float) [Доля займов Триггеры ПТС]
, case when a.[Вид займа]='Первичный' and a.isInstallment=0 then 1 end /                              cast(sum(1) over(partition by a.[Вид займа], a.[Заем выдан месяц], a.isinstallment)                     as float) [Доля первичных займов ПТС]
, case when a.[Вид займа]='Первичный' and a.isInstallment=1 then 1 end /                              cast(sum(1) over(partition by a.[Вид займа], a.[Заем выдан месяц], a.isinstallment)    as float) [Доля первичных займов Инстоллмент]
, [Стоимость займа Распределенные расходы CPA].uf_source [Источник]
--, [Стоимость займа Распределенные расходы CPA].[Postback] [Postback]
, GETDATE() created
--, ROW_NUMBER() over(partition by a.Номер order by (select 1 )) rn
from #fa a
--left join #lcrm lfc on lfc.uf_row_id=a.[Номер]
left join (select заявка, sum(Сумма) Сумма from [#партнеры расходы на привлечение] p group by заявка ) p on p.Заявка=a.Номер
left join (select заявка, sum(Сумма) Сумма from [#партнеры расходы на оформление]  o group by заявка ) o on o.Заявка=a.Номер
left join Analytics.dbo.[КВ партнерам к оплате] po_online on po_online.Номер=a.Номер 

and 
case
when po_online.Привлечение ='Привлечение' and  a.[Заем выдан месяц] > @last_load_привлечение_stg  then 1 
when po_online.Привлечение ='Оформление'  and  a.[Заем выдан месяц] > @last_load_оформление_stg   then 1 
else 0 
end = 1

left join Analytics.dbo.[Стоимость займа Распределенные расходы CPA] on [Стоимость займа Распределенные расходы CPA].Номер=a.Номер
)
,
p as (select *, cast(format(Дата, 'yyyy-MM-01') as date) m from stg.[files].[ContactCenterPlans_buffer])
, rr as (select m,   sum(case when Дата <getdate()-1 then [Займы руб] end)/sum([Займы руб]) rr_pts,  sum(case when Дата <getdate()-1 then [Сумма займов инстоллмент план] end)/nullif(sum([Сумма займов инстоллмент план]), 0) rr_inst  from p
group by m
)
, v_rr as (

select   v.*, case when isinstallment=0 then  rr_pts else  rr_inst end rr  from v 
left join rr rr on rr.m=v.[Заем выдан месяц]


)
select       
a.[Номер]   
,   a.[Источник]   
--,   a.[Postback]   
,   a.[Тип трафика]   
,   a.[Канал от источника]   
,   a.[Группа каналов]   
, a.Канал
, a.[вид займа_3]   
,   a.[Дата заявки день]   
,   a.[Отчетная дата]   
,   a.[Заем выдан день]   
,   a.[Выданная сумма]   
,   a.[Заем выдан месяц]   
,   a.[isinstallment]   
,   a.[Партнеры привлечение]  
,   a.[Партнеры оформление]   
,   a.[Расходы на CPA]  
,   a.[CPA трафик в МП источник]  
,   a.[Доля первичных займов CPC ПТС]   
,   a.rr*a.[Доля первичных займов CPC ПТС]   * b.Контекст [Контекст]
,   a.[Доля первичных займов ПТС] 
,   a.[Доля первичных займов Инстоллмент]   
,   a.rr*nullif(isnull(a.[Доля первичных займов ПТС] * [Медийка ПТС],0) +  a.rr*isnull(a.[Доля первичных займов Инстоллмент] * [Медийка инстоллмент],0) , 0) [Медийка]
,   a.rr*a.[Доля первичных займов ПТС] * ПрочиеМаркетинговыеРасходы [Прочие маркетинговые расходы]
,   a.rr*a.[Доля займов Триггеры ПТС] * [Расходы на триггеры] [Расходы на триггеры]

,   a.[created]   
,   a.rr
into #f

from    
v_rr a
left join stg.[files].[расходы по месяцам от подразделений_stg] b on a.[Заем выдан месяц]=b.Месяц
left join rr rr on rr.m=b.Месяц






--второстепенный столбец для отчетности
drop table if exists #f1
select a.*
, case when a.isInstallment=1 and year(a.[Заем выдан день])='2022' then 4 else  x.[Количество месяцев продукт продавался] end [Количество месяцев продукт продавался]
,   case when cast(format([Отчетная дата], 'yyyy-MM-01') as date)  <=cast(format(getdate(), 'yyyy-MM-01') as date) 
or month([Отчетная дата])=1  then 1 end [Признак для расчета среднего по годам]

into #f1
from  #f a
left join (
select isInstallment, year([Заем выдан день]) год, count(distinct month(case when [Заем выдан день]<=cast(format(getdate(), 'yyyy-MM-01') as date) 
or month([Заем выдан день])=1  then [Заем выдан день] end) ) [Количество месяцев продукт продавался]
--into #f1
from #f
group by isInstallment, year([Заем выдан день])
) x on a.isInstallment=x.isInstallment and x.год=year(a.[Отчетная дата])
	  
begin tran
delete from Analytics.dbo.[Стоимость займа]
insert into Analytics.dbo.[Стоимость займа]
select * from #f1
--drop table if exists Analytics.dbo.[Стоимость займа]
--select * into  Analytics.dbo.[Стоимость займа] from #f1-- where rn=1
commit tran

exec analytics.dbo.log_email'Подготовка витрины стоимость займа опер завершена v2', 'p.ilin@techmoney.ru'
	
	
--select * from  Analytics.dbo.[Стоимость займа]


end