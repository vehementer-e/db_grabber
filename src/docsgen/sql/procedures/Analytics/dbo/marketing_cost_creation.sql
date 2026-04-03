
CREATE proc [dbo].[marketing_cost_creation]
as  


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
1-isPts isinstallment,
[Выданная сумма],
[Тип трафика],
[Вид займа],
source,
productType,
productType2

into #fa
from v_fa



--select productType2, min(Номер)
-- from #fa
-- group by productType2

--drop table if exists #lcrm

--select 
--id,
--UF_ROW_ID,
--uf_source

--into #lcrm
--from  stg._LCRM.lcrm_leads_full_channel_request

--;
--with v as (select * , ROW_NUMBER() over(partition by UF_ROW_ID order by id) rn from #lcrm ) delete from v where rn>1


--Распределяем расходы на партнеров. Основная часть платится за выдачу, но есть расходы после выдачи - их мы распределяем на поколение которое выдавалось когда произошла оплата

drop table if exists [#партнеры расходы на привлечение_stg]
select a.*, case when b.Номер is null then 1 end [Для распределения] 
into [#партнеры расходы на привлечение_stg]
from marketing_cost_partner a
left join #fa b on a.Заявка=b.Номер -- and case when b.[Заем выдан месяц]=a.Месяц then 1 end =1

drop table if exists [#партнеры расходы на оформление_stg]
select a.*, case when b.Номер is null then 1 end [Для распределения] into [#партнеры расходы на оформление_stg]
from marketing_cost_partner_registration a
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


drop table if exists #traffic_sale_net

select 
  [Период оказания услуг]  month
--, [Тип трафика (ПТС/Беззалог)]	ispts
, sum(case when [Тип трафика (ПТС/Беззалог)]='ПТС' then [Поступление (без НДС)] end ) 	[Продажа трафика ПТС NET]
, sum(case when [Тип трафика (ПТС/Беззалог)]='Беззалог' then [Поступление (без НДС)] end ) 	[Продажа трафика Беззалог NET]
 					 into #traffic_sale_net

from Stg.files.[продажа трафика]
    where 1=0
 group by 

  [Период оказания услуг]  
--, [Тип трафика (ПТС/Беззалог)]	
 insert into #traffic_sale_net
select month,  pts_net,  bezzalog_net from marketing_sell_agr
where month is not null

--exec python 'xl2sql(r"G:\Общие диски\Commercial Team\Internet Marketing\Расходы\Расходы_ CPC + Медийка + Остальное.xlsx", "Продажа трафика2", "marketing_sell_agr")', 1



--select * from marketing_sell_agr
--select * from #traffic_sale_net

--select * from #traffic_sale_net
--order by 1


drop table if exists #runRates

select month m  , a.[rr_pts] , a.[rr_inst]into #runRates  from v_rr  a
insert into #runRates
select дата m , 1 [rr_pts], 1 [rr_inst]  from v_calendar a
left join #runRates b on a.месяц >=b.m
where a.дата=a.месяц and b.m is null
and a.дата >='20190501'



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
, [request_costs_cpa].[Расходы на CPA]  [Расходы на CPA]
, [request_costs_cpa].[CPA трафик в МП источник]  [CPA трафик в МП источник]
, case when a.[Вид займа]='Первичный' and a.[Группа каналов]='CPC' and a.productType2 = 'PTS'   then 1 end / cast(sum(1) over(partition by a.[Вид займа], a.[Заем выдан месяц], a.[Группа каналов], a.productType2) as float) [Доля первичных займов CPC ПТС]
, case when a.[Группа каналов]='Триггеры' and  a.productType2 = 'PTS'  then 1 end / cast(sum(1) over(partition by  a.[Заем выдан месяц], a.[Группа каналов], a.productType2) as float) [Доля займов Триггеры ПТС]
, case when a.[Вид займа]='Первичный'     and  a.productType2 = 'PTS'  then 1 end /                              cast(sum(1) over(partition by a.[Вид займа], a.[Заем выдан месяц], a.productType2)                     as float) [Доля первичных займов ПТС]
, case when a.[Вид займа]='Первичный'     and  a.productType2 = 'BEZZALOG'  then 1 end /                              cast(sum(1) over(partition by a.[Вид займа], a.[Заем выдан месяц], a.productType2)    as float) [Доля первичных займов Инстоллмент]
, a.source [Источник]
, GETDATE() created
, a.productType
--, ROW_NUMBER() over(partition by a.Номер order by (select 1 )) rn
from #fa a
--left join #lcrm lfc on lfc.uf_row_id=a.[Номер]
left join (select заявка, sum(Сумма) Сумма from [#партнеры расходы на привлечение] p group by заявка ) p on p.Заявка=a.Номер
left join (select заявка, sum(Сумма) Сумма from [#партнеры расходы на оформление]  o group by заявка ) o on o.Заявка=a.Номер
left join v_request_cost_partner po_online on po_online.number=a.Номер 

and 
case
when po_online.Привлечение ='Привлечение' and  a.[Заем выдан месяц] > @last_load_привлечение_stg  then 1 
when po_online.Привлечение ='Оформление'  and  a.[Заем выдан месяц] > @last_load_оформление_stg   then 1 
else 0 
end = 1

left join Analytics.dbo.[request_costs_cpa] on [request_costs_cpa].number=a.Номер
where isnull(a.[Заем выдан день],[Верификация КЦ день]) between '20200101' and getdate()-1
)
,
--p as (select *, cast(format(date, 'yyyy-MM-01') as date) m from sale_plan)
--, rr as (select m,   sum(case when date <getdate()-1 then ptsSum end)/nullif(sum(ptsSum), 0) rr_pts,  sum(case when date <getdate()-1 then bezzalogSum end)/nullif(sum(bezzalogSum), 0) rr_inst  from p
--group by m
--)
rr as (select * from #runRates)
, v_rr as (

select   v.*, case when isinstallment=0 then  rr_pts else  rr_inst end rr  from v 
left join rr rr on rr.m=v.[Заем выдан месяц]


)
select       
a.[Номер]   
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
,   a.rr*nullif(isnull(a.[Доля первичных займов ПТС] * b.[Медийка ПТС],0) +  a.rr*isnull(a.[Доля первичных займов Инстоллмент] * b.[Медийка беззалог],0) , 0) [Медийка]
,   a.rr*a.[Доля первичных займов ПТС] * ПрочиеМаркетинговыеРасходы [Прочие маркетинговые расходы]
,   a.rr*a.[Доля займов Триггеры ПТС] * [Расходы на триггеры] [Расходы на триггеры]
,   a.[Источник]   
,   a.[created]   
,   a.rr
,  nullif( a.rr*isnull(a.[Доля первичных займов ПТС]         * ts.[Продажа трафика ПТС NET]     ,0)
+          a.rr*isnull(a.[Доля первичных займов Инстоллмент] * ts.[Продажа трафика Беззалог NET],0)

, 0) [Продажа трафика net]
, a.productType
into #f

from    
v_rr a
--left join stg.[files].[расходы по месяцам от подразделений_stg] b on a.[Заем выдан месяц]=b.Месяц
left join dbo.v_costs_by_months b on a.[Заем выдан месяц]=b.Месяц
left join #traffic_sale_net ts on a.[Заем выдан месяц]=ts.month
left join rr rr on rr.m=b.Месяц



--select * from v_costs_by_months


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
delete from request_costs
insert into request_costs
select * from #f1
--drop table if exists request_costs
--select * into  request_costs from #f1-- where rn=1
commit tran

--exec analytics.dbo.log_email'Подготовка витрины стоимость займа опер завершена', 'p.ilin@techmoney.ru'
 