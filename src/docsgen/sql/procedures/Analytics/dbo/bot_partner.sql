CREATE    proc 
--exec
[dbo].[bot_partner]

as
begin


drop table if exists #t1

select Номер, Юрлицо, [Верификация КЦ]

, Одобрено, Отказано, [Заем выдан], [Выданная сумма]
, cast(format(a.[Заем выдан], 'yyyy-MM-01') as date) [Заем выдан месяц]
, cast(a.[Заем выдан] as date) [Заем выдан день]
, cast(a.[Верификация КЦ] as date) [Верификация КЦ день]
,[Процентная ставка] процставкакредит
,[Сумма дополнительных услуг] суммадопуслуг
,[Признак Страховка] ПризнакСтраховка
,[Признак Комиссионный продукт] ПризнакКП
, Юрлицо Юрлицо_КВ
into #t1 
from v_fa a
where [Группа каналов] in ('Партнеры') and cast(isnull([Заем выдан], [Верификация КЦ])as date)>=cast(getdate()-100 as date)
and Дубль=0

union all

select Номер, case when [Вид займа] = 'Первичный' then '1) Партнеры (новые)' else '2) Партнеры (повторные)' end + case isPts when 1 then ' ПТС' else ' БЗ' end Юрлицо, [Верификация КЦ]

, Одобрено, Отказано, [Заем выдан], [Выданная сумма]
, cast(format(a.[Заем выдан], 'yyyy-MM-01') as date) [Заем выдан месяц]
, cast(a.[Заем выдан] as date) [Заем выдан день]
, cast(a.[Верификация КЦ] as date) [Верификация КЦ день]
,[Процентная ставка] процставкакредит
,[Сумма дополнительных услуг] суммадопуслуг
,[Признак Страховка] ПризнакСтраховка
,[Признак Комиссионный продукт] ПризнакКП
, Юрлицо Юрлицо_КВ

--into #t1 
from v_fa a
where [Группа каналов] in ('Партнеры' ) and cast(isnull([Заем выдан], [Верификация КЦ])as date)>=cast(getdate()-100 as date)
and Дубль=0


--select * from #t1
--where юрлицо='ИП Маилян Мгер Станиславович'
--order by 1 desc

--drop table if exists #t2
--
--select Номер, процставкакредит,суммадопуслуг, ПризнакСтраховка into #t2 from reports.dbo.dm_Factor_Analysis
--where  [Группа каналов] in ('Партнеры', 'Банки')  and isnull([Заем выдан], [Верификация КЦ])>=getdate()-100

drop table if exists #mt

select 
a.Номер 
, a.Юрлицо
, a.[Верификация КЦ]
, a.[Верификация КЦ день]
, a.Одобрено
, a.Отказано
, a.[Заем выдан]
, a.[Выданная сумма]
, a.[Заем выдан месяц]
, a.[Заем выдан день]
, процставкакредит
, case when a.[Заем выдан день] is not null   then 1 end [Признак займ]
, ПризнакКП  ПризнакКП
, суммадопуслуг
, ПризнакСтраховка
, Юрлицо_КВ

into #mt 
from #t1 a
--join #t2 b on a.Номер=b.Номер

--select * from #mt


drop table if exists #costs_stg
select Месяц, Заявка, сумма, created into #costs_stg from stg.[files].[партнеры расходы на привлечение_stg]
--select * from #costs_stg
drop table if exists #cost_cur_month

select a.Номер
, a.[Выданная сумма]
, a.[Заем выдан месяц]
,
cast( 
case when ПризнакСтраховка=1 then isnull(b1.[Привлечение со страховкой] , b2.[Привлечение со страховкой]) 
else isnull(b1.[Привлечение без страховки], b2.[Привлечение без страховки]) end * a.[Выданная сумма]
	 as numeric(18,2)) КВ
	 , a.Юрлицо

into #cost_cur_month

from #mt a
left join stg.files.[ставки кв юрлиц по месяцам_stg] b1 on a.[Заем выдан месяц]=cast(b1.Месяц as date) and  b1.Юрлицо=a.Юрлицо_КВ
left join stg.files.[ставки кв юрлиц по месяцам_stg] b2 on a.[Заем выдан месяц]=cast(b2.Месяц as date) and   b2.Юрлицо='Все остальные агенты'
where [Заем выдан месяц]>(select max(Месяц) from #costs_stg )

insert into #costs_stg
select [Заем выдан месяц], Номер, КВ, getdate()   from #cost_cur_month

--select * from #costs_stg

drop table if exists #mt_costs

select a.*,     b.СуммаКВ into #mt_costs from #mt a
left join (select Заявка, max(Сумма) СуммаКВ from #costs_stg group by Заявка) b on a.Номер=b.Заявка 
--where a.[Заем выдан день] is not  null
order by СуммаКВ


drop table if exists #partners
select distinct Юрлицо into #partners from #mt_costs

drop table if exists #f
--select distinct Источник from #t1 order by 1

--select * from #partners

declare @today date = cast(getdate() as date)

drop table if exists #rr

select [Доля для RR] into #rr from (
select 
Дата
,[Займы руб]
,cast(format(Дата, 'yyyy-MM-01') as date) Месяц
, sum([Займы руб]) over(partition by cast(format(Дата, 'yyyy-MM-01') as date) order by Дата) /sum([Займы руб]  ) over(partition by cast(format(Дата, 'yyyy-MM-01') as date)) [Доля для RR]

from stg.files.contactcenterplans_buffer_stg
) x where Дата=cast(getdate()-1 as date)


set language russian
set datefirst 7

;


with dates as (
select 'stat_today'     command , @today since, @today till union all
select 'stat_yesterday'    , dateadd(day, -1, @today), dateadd(day, -1, @today) union all
select 'stat_week'         , DATEADD(DD, 2 - DATEPART(DW, DATEADD(DD, -1, @today)), DATEADD(DD, -1, @today)), dateadd(day, 6, DATEADD(DD, 2 - DATEPART(DW, DATEADD(DD, -1, @today)), DATEADD(DD, -1, @today))) union all
select 'stat_month'        , cast(format(@today, 'yyyy-MM-01') as date), dateadd(day, -1, dateadd(month, 1, cast(format(@today, 'yyyy-MM-01') as date) )) union all
select 'stat_quarter'        , cast(DATEADD(qq   , DATEDIFF(qq   , 0, @today), 0) as date) , dateadd(day, -1, dateadd(qq, 1, cast(DATEADD(qq   , DATEDIFF(qq   , 0, @today), 0) as date) )) union all
select 'stat_last_month'    , dateadd(month, -1, cast(format(@today, 'yyyy-MM-01') as date)) , dateadd(day, -1, cast(format(@today, 'yyyy-MM-01') as date))-- union all

)
--select * from dates


select a.*, b.Юрлицо, text =
cast(
--case when since<>till then N'🎄' else N'🎄' end +'Период: '+char(10)+'<b>'+format(since, 'dd.MMM') + case when since<>till then ' - '+format(till, 'dd.MMM') else '' end +'</b>' +char(10)+char(10)+
case when since<>till then N'📆' else N'📅' end +'Период: '+char(10)+'<b>'+format(since, 'dd.MMM') + case when since<>till then ' - '+format(till, 'dd.MMM') else '' end +'</b>' +char(10)+char(10)+
N'🆕 '+'Заявок - ' +'<b>'+format(isnull(x1.cnt, 0), '0') +' шт.'+'</b>' +char(10) +
N'💸 '+'Выдано - ' +'<b>'+format(isnull(x2.[Выданная сумма], 0), '#,0') +' руб.'+'</b>' +char(10)+
N'💸 '+'Выдано - ' +'<b>'+format(isnull(x2.[Выдано шт], 0), '0') +' шт.'+'</b>' +char(10)+
N'✅ '+'Одобрено - ' +'<b>'+format(isnull(x1.Одобрено, 0), '0') +' шт.'+'</b>' +char(10)+
N'❌ '+'Отказано - ' +'<b>'+format(isnull(x1.Отказано, 0), '0') +' шт.'+'</b>' +char(10)+
N'➕ '+'Выдано с КП - ' +'<b>'+format(isnull(x2.[ПризнакКП шт], 0), '0') +' шт.'+'</b>' +char(10)+char(10) +
N'🤑 '+'Сумма КВ - ' +'<b>'+format(isnull(x2.СуммаКВ, 0), '#,0') +' руб.'+'</b>' +char(10)+
N'🤑 '+'Ставка КВ - ' +'<b>'+format(isnull(x2.СуммаКВ_проценты, 0), '0.0%') +''+'</b>' +char(10)+char(10) +
N'💵 '+'Чек - ' +'<b>'+format(isnull(x2.Чек, 0), '#,0') +' руб.'+'</b>' +char(10)  +
N'🏦 '+'Ставка - ' +'<b>'+format(isnull(x2.Ставка, 0), '0.0') +'%'+'</b>' +char(10)  +
N'👌' +'AR - ' +'<b>'+format(isnull(x1.AR, 0), 'P1') +''+'</b>' +char(10)+char(10) +
N'➕ '+'Доля займов с КП - ' +'<b>'+format(isnull(x2.ДоляКП_шт, 0), 'P1') +''+'</b>' +char(10)+
N'➕ '+'Доля КП - ' +'<b>'+format(isnull(x2.ДоляКП, 0), 'P1') +''+'</b>' +
case when a.command='stat_month' then
char(10)+char(10) +
N'🤞 '+'RR Выдачи- ' +'<b>'+format(isnull(x2.[Выданная сумма]/ nullif(cast( (select top 1 * from #rr) as float) , 0), 0), '#,0') +' руб.'+'</b>' +char(10)+
N'🤞 '+'RR КВ- ' +'<b>'+format(isnull(x2.СуммаКВ/ nullif(cast( (select top 1 * from #rr) as float) , 0), 0), '#,0') +' руб.'+'</b>'
else '' end 
as nvarchar(max)),
x2.[Выдано шт] 

into #f
from dates a
cross join #partners  b
outer apply (select Юрлицо,  sum(1 ) cnt
, count(Отказано) Отказано 
, count(Одобрено) Одобрено 
, count(Одобрено)/ cast(nullif((count(Отказано) +count(Одобрено)), 0) as float) AR 

from #mt_costs c where [Верификация КЦ день] between since and till and c.Юрлицо=b.Юрлицо group by Юрлицо ) x1
outer apply 
(select Юрлицо,  sum([Выданная сумма] ) [Выданная сумма] 
,  count([Выданная сумма] ) [Выдано шт] 
,  sum(ПризнакКП) [ПризнакКП шт] 
,  isnull(sum(СуммаКВ), 0) СуммаКВ 
,  sum(СуммаКВ)  /cast(nullif(sum([Выданная сумма] ), 0)as float)  СуммаКВ_проценты
,  sum(ПризнакКП)/cast(nullif(sum([Признак займ] ), 0)  as float)  ДоляКП_шт
,  sum(суммадопуслуг)/nullif(sum([Выданная сумма] ), 0) ДоляКП
,  avg([Выданная сумма] )   Чек
,  sum([Выданная сумма]*ПроцСтавкаКредит)/nullif(sum(case when ПроцСтавкаКредит is not null then [Выданная сумма] end ), 0)  Ставка

from #mt_costs c where [Заем выдан день] between since and till and c.Юрлицо=b.Юрлицо group by Юрлицо 

) x2

begin tran

--drop table if exists  dbo.[Оперативная витрина со статистикой для партнеров]
--select * into  dbo.[Оперативная витрина со статистикой для партнеров] from #f
delete from dbo.[Оперативная витрина со статистикой для партнеров]
insert into dbo.[Оперативная витрина со статистикой для партнеров]
select *  from #f

commit tran


--select * from  dbo.[Оперативная витрина со статистикой для партнеров] where юрлицо like '%решения%'
--order by Юрлицо, 1


end