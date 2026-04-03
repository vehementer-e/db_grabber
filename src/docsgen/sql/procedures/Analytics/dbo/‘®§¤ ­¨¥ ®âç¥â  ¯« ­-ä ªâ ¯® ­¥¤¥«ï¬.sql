
CREATE   proc [dbo].[Создание отчета план-факт по неделям]

--grant execute on dbo.[Создание отчета план-факт по неделям] to ReportViewer
as
begin

declare @now_d date = getdate() 
declare @now_month date = (select Месяц from  v_calendar where Дата= @now_d   )
declare @now_week date  = (select Неделя from  v_calendar where Дата=@now_d	 )

drop table if exists #ch
select * into #ch from 
(
select 'CPA нецелевой' канал             , 'CPA'   группа  , 1 order_num
union all select 'CPA полуцелевой' канал , 'CPA'		   , 1
union all select 'CPA целевой' канал	 , 'CPA'		   , 1
union all select 'CPC' канал			 , 'CPC'		   , 2
union all select 'Органика' канал		 , 'Органика'	   , 3
union all select 'Партнеры' канал		 , 'Партнеры'	   , 4
union all select 'Триггеры' канал		 , 'Триггеры'	   , 6
union all select 'Банки' канал		 , 'Банки'			   , 7
union all select 'Телеком' канал		 , 'Телеком'			   , 8

)x







drop table if exists #chpl

;

with cpl as (

select cast(format(Дата, 'yyyy-MM-01') as date) Месяц, cast(Дата as date) Дата
, [Займы руб]
, [Займы руб]/(sum([Займы руб]) over(partition by cast(format(Дата, 'yyyy-MM-01') as date))+0.0) [weight of day] 
from stg.files.contactcenterplans_buffer_stg a 


)


select
cpl.Дата
, case when b.[Группа каналов]='cpa' then b.[Канал от источника] else b.[Группа каналов] end [Канал]
, [Выданная сумма]*[weight of day] [Выданная сумма]
into #chpl
from cpl 

join 

stg.files.[план по каналам_stg] b on cpl.Месяц=b.Месяц
where b.[Тип продукта]='ПТС'


set language russian

drop table if exists #d

select * into #d from [dbo].[TF_Sys_DateGen] (dateadd(day, -40, @now_d) , dateadd(day, 40, @now_d))

select * from (
select a.Дата
, a.Неделя
, format(a.Месяц, 'MMMM')  [Месяц текст]
, format(a.Дата, 'dd MMM')  [Дата текст]
, format(a.Неделя, 'dd.MM')+'-'+ format(a.[Неделя окончание], 'dd.MM') [Неделя текст]
, a.[Неделя окончание]
, a.Месяц
, b.группа
, b.канал
, b.order_num
, x.[Выданная сумма план]
, x1.[Выданная сумма факт] 
, case when a.Неделя=@now_week then 1 else 0 end [Только текущая неделя]
, case when a.Месяц=@now_month then 1 else 0 end [Только текущий месяц]
, case when a.Дата<=@now_d then 1 else 0 end [По сегодня]
, case when a.Дата<=dateadd(day, -1,@now_d ) then 1 else 0 end [По вчера]

from #d a cross join #ch  b
outer apply (select sum([Выданная сумма]) [Выданная сумма план] from #chpl c where a.Дата=c.Дата and b.канал=c.Канал ) x
outer apply (select sum(Сумма) [Выданная сумма факт] from [оперативная витрина с выдачами и каналами] c where a.Дата=c.ДатаВыдачи and b.канал=c.Канал and c.IsInstallment=0 ) x1
where a.Месяц=@now_month or format( a.[Неделя окончание],  'yyyy-MM-01')= @now_month
) ч
--where [По сегодня]=1

end

--exec  dbo.[Создание отчета план-факт по неделям]