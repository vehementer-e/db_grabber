
create   procedure dbo.[ПОдготовка отчета по заявкам Банка СОЮЗ]
as

begin



--select distinct Заявка from [#Офис заведения заявки] where Наименование='БАНК АО "СОЮЗ"'

drop table if exists #reg
select u.username, min(r.created_at) [Дата регистрации в МП] into #reg from stg._LK.users u
join stg._LK.register_mp r on u.id=r.user_id
group by u.username

drop table if exists #t1

select  Номер, Юрлицо, [Верификация КЦ]

, Одобрено, Отказано, [Заем выдан], [Выданная сумма]
, cast(a.[Заем выдан] as date) [Заем выдан день]
, cast(format(a.[Заем выдан], 'yyyy-MM-01') as date) [Заем выдан месяц]
, cast( dateadd(day, datediff(day, '1900-01-01', a.[Заем выдан]) / 7 * 7, '1900-01-01') as date)  [Заем выдан неделя]
, cast(a.[Верификация КЦ] as date) [Верификация КЦ день]
, cast( dateadd(day, datediff(day, '1900-01-01', a.[Верификация КЦ]) / 7 * 7, '1900-01-01') as date)  [Верификация КЦ неделя]

, cast(format(a.[Верификация КЦ], 'yyyy-MM-01') as date) [Верификация КЦ месяц]
, r.[Дата регистрации в МП]
into #t1 
from reports.dbo.dm_Factor_Analysis_001 a
left join #reg r on a.Телефон=r.username
where a.[Юрлицо при создании]='БАНК АО "СОЮЗ"' and Дубль=0

drop table if exists #t2



select   a.*, b.[Заем выдан месяц], b.[Заем выдан день], b.Юрлицо, b.[Верификация КЦ день], b.[Дата регистрации в МП]
into #t2
from reports.dbo.dm_Factor_Analysis a join #t1 b on a.Номер=b.Номер



drop table if exists #costs_stg
select * into #costs_stg from stg.[files].[партнеры расходы на привлечение_stg]
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

into #cost_cur_month

from #t2 a
left join stg.files.[ставки кв юрлиц по месяцам_stg] b1 on a.[Заем выдан месяц]=cast(b1.Месяц as date) and  b1.Юрлицо=a.Юрлицо
left join stg.files.[ставки кв юрлиц по месяцам_stg] b2 on a.[Заем выдан месяц]=cast(b2.Месяц as date) and   b2.Юрлицо='Все остальные агенты'
where [Заем выдан месяц]>(select max(Месяц) from #costs_stg )

insert into #costs_stg
select [Заем выдан месяц], Номер, КВ, getdate()  from #cost_cur_month

--select * from #costs_stg




select 
       c.[Признак сегодня]
      ,c.[Признак эта неделя]
      ,c.[Признак этот месяц]
      ,c.[Признак вчера]
      ,c.Дата [Отчетная Дата]
      ,c.Неделя [Отчетная неделя]
	  ,a.*, type = 'Заявка' from analytics.dbo.v_Calendar c 
left join (

select a.*,  b.СуммаКВ   from #t2 a
left join (select Заявка, sum(Сумма) СуммаКВ from #costs_stg group by Заявка) b on a.Номер=b.Заявка
--where a.[Заем выдан день] is not  null
) a on c.Дата=a.[Верификация КЦ день]
where Дата between '20221107' and getdate()

union all

select 
 c.[Признак сегодня]
      ,c.[Признак эта неделя]
      ,c.[Признак этот месяц]
      ,c.[Признак вчера]
      ,c.Дата [Отчетная Дата]
      ,c.Неделя [Отчетная неделя]

	  ,a.*
	  , type = 'Займ' from analytics.dbo.v_Calendar c 
left join (

select a.*,  b.СуммаКВ   from #t2 a
left join (select Заявка, sum(Сумма) СуммаКВ from #costs_stg group by Заявка) b on a.Номер=b.Заявка
--where a.[Заем выдан день] is not  null
) a on c.Дата=a.[Заем выдан день]
where Дата between '20221107' and getdate()


end