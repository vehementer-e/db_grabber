
CREATE proc [dbo].[Подготовка отчета по поступлениям инстоллмент]
as 

begin
											
											
drop table if exists #f											
select Номер, Срок, [Заем погашен день], [заем выдан месяц], [Признак Заем погашен], [Выданная сумма] 
,case 
when [заем выдан день] between '20211206' and '20211222' then cast('20211206' as date)
when [заем выдан день] between '20211223' and '20211228' then cast('20211223' as date)
when [заем выдан день] between '20211229' and '20220131' then cast('20211229' as date)
when [заем выдан день] >= '20220201'  then cast('20220201' as date)
end [Дата выдачи РИСКИ]
into #f from Analytics.dbo.mv_dm_factor_analysis where isinstallment=1 and [заем выдан месяц] <'20221101'											
											
drop table if exists #ep											
select a.НомерПлатежа, a.Код, ОД [ОД по графику] , Процент [Проценты по графику], ДатаПлатежа into #ep from reports.dbo.dm_CMRExpectedRepayments a join #f b on a.Код=b.Номер											
	
	--select * from #f order by [Заем выдан месяц]
											
drop table if exists #b											
											
											
select d											
, Код				
, a.Срок
, Сумма
, [d Неделя]
, [d Месяц]
, [Дата выдачи]
, [Дата выдачи Месяц]
--,[основной долг начислено нарастающим итогом]    [Начислено ОД]											
,[основной долг уплачено нарастающим итогом]		[Поступления ОД нарастающим итогом]									
--,[Проценты начислено  нарастающим итогом]			[Начислено проценты]								
,[Проценты уплачено  нарастающим итогом]			[Поступления Проценты нарастающим итогом]		
,[ПереплатаНачислено нарастающим итогом]
,[сумма поступлений]
,[сумма поступлений  нарастающим итогом]
, [Дата выдачи РИСКИ]
into #b 											
											
from  v_balance a join #f b on a.Код = b.Номер and d<cast(getdate() as date)	
set language russian
set datefirst 7

--drop table if exists analytics.dbo.[Отчет входящий кэш инстоллмент по неделям по рисковым датам]				
delete from analytics.dbo.[Отчет входящий кэш инстоллмент по неделям по рисковым датам]				
;
		with v as (	
select a.[Дата выдачи РИСКИ], [d Неделя], sum([сумма поступлений]) [сумма поступлений], min(b.Сумма)Сумма   , GETDATE() created
from #b a
left join (select [Дата выдачи РИСКИ], sum(Сумма) Сумма  from #b a where d=[Дата выдачи] group by [Дата выдачи РИСКИ]) b on b.[Дата выдачи РИСКИ]=a.[Дата выдачи РИСКИ]
group by  a.[Дата выдачи РИСКИ], [d Неделя]
union all
		
select null, [d Неделя], sum([сумма поступлений]) [сумма поступлений], min(b.Сумма)Сумма  , GETDATE() created
from #b a
left join (select  sum(Сумма) Сумма  from #b a where d=[Дата выдачи]) b on 1=1
group by   [d Неделя]
)

insert into analytics.dbo.[Отчет входящий кэш инстоллмент по неделям по рисковым датам]

select [Дата выдачи РИСКИ], isnull(format([Дата выдачи РИСКИ], 'dd-MMM-yy'), 'Итого') [Дата выдачи РИСКИ текст] , [d Неделя], format([d Неделя], 'dd.MMM')+' - '+format(dateadd(day, 6, [d Неделя]), 'dd.MMM') [Неделя текст], [сумма поступлений], Сумма,	created,		sum([сумма поступлений]) over(partition by [Дата выдачи РИСКИ] order by [d Неделя]  rows between unbounded preceding and current row) [сумма поступлений накопительно]  
  --into analytics.dbo.[Отчет входящий кэш инстоллмент по неделям по рисковым датам]
from 						v
where [d Неделя] < -- select
dateadd(day, datediff(day, '1900-01-01', getdate()) / 7 * 7, '1900-01-01') 
--select * from analytics.dbo.[Отчет входящий кэш инстоллмент по неделям по рисковым датам]
--drop table if exists analytics.dbo.[Отчет входящий кэш инстоллмент по неделям]				
delete from analytics.dbo.[Отчет входящий кэш инстоллмент по неделям]				
;
		with v as (	
select a.[Дата выдачи Месяц], [d Неделя], sum([сумма поступлений]) [сумма поступлений], min(b.Сумма)Сумма   , GETDATE() created
from #b a
left join (select [Дата выдачи Месяц], sum(Сумма) Сумма  from #b a where d=[Дата выдачи] group by [Дата выдачи Месяц]) b on b.[Дата выдачи Месяц]=a.[Дата выдачи Месяц]
group by  a.[Дата выдачи Месяц], [d Неделя]
union all
		
select null, [d Неделя], sum([сумма поступлений]) [сумма поступлений], min(b.Сумма)Сумма  , GETDATE() created
from #b a
left join (select  sum(Сумма) Сумма  from #b a where d=[Дата выдачи]) b on 1=1
group by   [d Неделя]
)

insert into analytics.dbo.[Отчет входящий кэш инстоллмент по неделям]	
select [Дата выдачи Месяц], isnull(format([Дата выдачи Месяц], 'MMM-yy'), 'Итого') [Дата выдачи Месяц текст] , [d Неделя], format([d Неделя], 'dd.MMM')+' - '+format(dateadd(day, 6, [d Неделя]), 'dd.MMM') [Неделя текст], [сумма поступлений], Сумма,	created,		sum([сумма поступлений]) over(partition by [Дата выдачи Месяц] order by [d Неделя]  rows between unbounded preceding and current row) [сумма поступлений накопительно]  
  --into analytics.dbo.[Отчет входящий кэш инстоллмент по неделям]
from 						v
where [d Неделя] < -- select
dateadd(day, datediff(day, '1900-01-01', getdate()) / 7 * 7, '1900-01-01') 



--drop table if exists analytics.dbo.[Отчет входящий кэш инстоллмент по неделям 6 мес]				
delete from analytics.dbo.[Отчет входящий кэш инстоллмент по неделям 6 мес]				
;
		with v as (	
select a.[Дата выдачи Месяц], [d Неделя], sum([сумма поступлений]) [сумма поступлений], min(b.Сумма)Сумма   , GETDATE() created
from #b a
left join (select [Дата выдачи Месяц], sum(Сумма) Сумма  from #b a
where d=[Дата выдачи]
and a.Срок=6
group by [Дата выдачи Месяц])
b on b.[Дата выдачи Месяц]=a.[Дата выдачи Месяц]
where a.Срок=6

group by  a.[Дата выдачи Месяц], [d Неделя]
union all
		
select null, [d Неделя], sum([сумма поступлений]) [сумма поступлений], min(b.Сумма)Сумма  , GETDATE() created
from #b a

left join (select  sum(Сумма) Сумма  from #b a where d=[Дата выдачи]
and a.Срок=6

) b on 1=1
where a.Срок=6
group by   [d Неделя]
)

insert into  analytics.dbo.[Отчет входящий кэш инстоллмент по неделям 6 мес]				
select [Дата выдачи Месяц], isnull(format([Дата выдачи Месяц], 'MMM-yy'), 'Итого') [Дата выдачи Месяц текст] , [d Неделя], format([d Неделя], 'dd.MMM')+' - '+format(dateadd(day, 6, [d Неделя]), 'dd.MMM') [Неделя текст], [сумма поступлений], Сумма,	created,		sum([сумма поступлений]) over(partition by [Дата выдачи Месяц] order by [d Неделя]  rows between unbounded preceding and current row) [сумма поступлений накопительно]  
 -- into analytics.dbo.[Отчет входящий кэш инстоллмент по неделям 6 мес]
from 						v
where [d Неделя] < -- select
dateadd(day, datediff(day, '1900-01-01', getdate()) / 7 * 7, '1900-01-01') 



--drop table if exists analytics.dbo.[Отчет входящий кэш инстоллмент по неделям 12 мес]				
delete from analytics.dbo.[Отчет входящий кэш инстоллмент по неделям 12 мес]				
;
		with v as (	
select a.[Дата выдачи Месяц], [d Неделя], sum([сумма поступлений]) [сумма поступлений], min(b.Сумма)Сумма   , GETDATE() created
from #b a
left join (select [Дата выдачи Месяц], sum(Сумма) Сумма  from #b a
where d=[Дата выдачи]
and a.Срок=12
group by [Дата выдачи Месяц])
b on b.[Дата выдачи Месяц]=a.[Дата выдачи Месяц]
where a.Срок=12

group by  a.[Дата выдачи Месяц], [d Неделя]
union all
		
select null, [d Неделя], sum([сумма поступлений]) [сумма поступлений], min(b.Сумма)Сумма  , GETDATE() created
from #b a

left join (select  sum(Сумма) Сумма  from #b a where d=[Дата выдачи]
and a.Срок=12

) b on 1=1
where a.Срок=12
group by   [d Неделя]
)

  
insert into analytics.dbo.[Отчет входящий кэш инстоллмент по неделям 12 мес]
select [Дата выдачи Месяц], isnull(format([Дата выдачи Месяц], 'MMM-yy'), 'Итого') [Дата выдачи Месяц текст] , [d Неделя], format([d Неделя], 'dd.MMM')+' - '+format(dateadd(day, 6, [d Неделя]), 'dd.MMM') [Неделя текст], [сумма поступлений], Сумма,	created,		sum([сумма поступлений]) over(partition by [Дата выдачи Месяц] order by [d Неделя]  rows between unbounded preceding and current row) [сумма поступлений накопительно]  
  --into analytics.dbo.[Отчет входящий кэш инстоллмент по неделям 12 мес]
from 						v
where [d Неделя] < -- select
dateadd(day, datediff(day, '1900-01-01', getdate()) / 7 * 7, '1900-01-01') 


-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------

--drop table if exists analytics.dbo.[Отчет входящий кэш инстоллмент по месяцам]				
delete from analytics.dbo.[Отчет входящий кэш инстоллмент по месяцам]				
;
		with v as (	
select a.[Дата выдачи Месяц], [d Месяц], sum([сумма поступлений]) [сумма поступлений], min(b.Сумма)Сумма   , GETDATE() created
from #b a
left join (select [Дата выдачи Месяц], sum(Сумма) Сумма  from #b a
where d=[Дата выдачи]
and a.Срок=a.Срок
group by [Дата выдачи Месяц])
b on b.[Дата выдачи Месяц]=a.[Дата выдачи Месяц]
where a.Срок=a.Срок

group by  a.[Дата выдачи Месяц], [d Месяц]
union all
		
select null, [d Месяц], sum([сумма поступлений]) [сумма поступлений], min(b.Сумма)Сумма  , GETDATE() created
from #b a

left join (select  sum(Сумма) Сумма  from #b a where d=[Дата выдачи]
and a.Срок=a.Срок

) b on 1=1
where a.Срок=a.Срок
group by   [d Месяц]
)

insert into analytics.dbo.[Отчет входящий кэш инстоллмент по месяцам]
select [Дата выдачи Месяц], isnull(format([Дата выдачи Месяц], 'MMM-yy'), 'Итого') [Дата выдачи Месяц текст] , [d Месяц], format([d Месяц], 'MMM-yy') [Месяц текст], [сумма поступлений], Сумма,	created,		sum([сумма поступлений]) over(partition by [Дата выдачи Месяц] order by [d Месяц]  rows between unbounded preceding and current row) [сумма поступлений накопительно]  
  --into analytics.dbo.[Отчет входящий кэш инстоллмент по месяцам]
from 						v


-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------

--drop table if exists analytics.dbo.[Отчет входящий кэш инстоллмент по месяцам 6 мес]				
delete from analytics.dbo.[Отчет входящий кэш инстоллмент по месяцам 6 мес]				
;
		with v as (	
select a.[Дата выдачи Месяц], [d Месяц], sum([сумма поступлений]) [сумма поступлений], min(b.Сумма)Сумма   , GETDATE() created
from #b a
left join (select [Дата выдачи Месяц], sum(Сумма) Сумма  from #b a
where d=[Дата выдачи]
and a.Срок=6
group by [Дата выдачи Месяц])
b on b.[Дата выдачи Месяц]=a.[Дата выдачи Месяц]
where a.Срок=6

group by  a.[Дата выдачи Месяц], [d Месяц]
union all
		
select null, [d Месяц], sum([сумма поступлений]) [сумма поступлений], min(b.Сумма)Сумма  , GETDATE() created
from #b a

left join (select  sum(Сумма) Сумма  from #b a where d=[Дата выдачи]
and a.Срок=6

) b on 1=1
where a.Срок=6
group by   [d Месяц]
)


 insert  into analytics.dbo.[Отчет входящий кэш инстоллмент по месяцам 6 мес]
select [Дата выдачи Месяц], isnull(format([Дата выдачи Месяц], 'MMM-yy'), 'Итого') [Дата выдачи Месяц текст] , [d Месяц], format([d Месяц], 'MMM-yy') [Месяц текст], [сумма поступлений], Сумма,	created,		sum([сумма поступлений]) over(partition by [Дата выдачи Месяц] order by [d Месяц]  rows between unbounded preceding and current row) [сумма поступлений накопительно]  
 -- into analytics.dbo.[Отчет входящий кэш инстоллмент по месяцам 6 мес]
from 						v



-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------

delete from analytics.dbo.[Отчет входящий кэш инстоллмент по месяцам 12 мес]				
--drop table if exists analytics.dbo.[Отчет входящий кэш инстоллмент по месяцам 12 мес]				
;
		with v as (	
select a.[Дата выдачи Месяц], [d Месяц], sum([сумма поступлений]) [сумма поступлений], min(b.Сумма)Сумма   , GETDATE() created
from #b a
left join (select [Дата выдачи Месяц], sum(Сумма) Сумма  from #b a
where d=[Дата выдачи]
and a.Срок=12
group by [Дата выдачи Месяц])
b on b.[Дата выдачи Месяц]=a.[Дата выдачи Месяц]
where a.Срок=12

group by  a.[Дата выдачи Месяц], [d Месяц]
union all
		
select null, [d Месяц], sum([сумма поступлений]) [сумма поступлений], min(b.Сумма)Сумма  , GETDATE() created
from #b a

left join (select  sum(Сумма) Сумма  from #b a where d=[Дата выдачи]
and a.Срок=12

) b on 1=1
where a.Срок=12
group by   [d Месяц]
)


  insert into analytics.dbo.[Отчет входящий кэш инстоллмент по месяцам 12 мес]
select [Дата выдачи Месяц], isnull(format([Дата выдачи Месяц], 'MMM-yy'), 'Итого') [Дата выдачи Месяц текст] , [d Месяц], format([d Месяц], 'MMM-yy') [Месяц текст], [сумма поступлений], Сумма,	created,		sum([сумма поступлений]) over(partition by [Дата выдачи Месяц] order by [d Месяц]  rows between unbounded preceding and current row) [сумма поступлений накопительно]  
  --into analytics.dbo.[Отчет входящий кэш инстоллмент по месяцам 12 мес]
from 						v

		--select * from analytics.dbo.[Отчет входящий кэш инстоллмент]

--select *,		sum([сумма поступлений]) over(partition by [Дата выдачи Месяц] order by [d Неделя]  rows between unbounded preceding and current row) [сумма поступлений накопительно]   from 							 analytics.dbo.[Отчет входящий кэш инстоллмент]			
		

--drop table if exists #x											
--											
--											
--select Номер, ДатаПлатежа, [Заем погашен день]											
--into #x											
--from #f a outer apply (select top 1 * from 											
--#ep b where a.Номер=b.Код and b.ДатаПлатежа>=[Заем погашен день] order by b.ДатаПлатежа ) ч											
--where [Заем погашен день] is not null											
											
											
											
--drop table if exists #final											
--;
--with v as (
--select b.Код											
--, a.Срок											
--, a.[Выданная сумма]											
--, a.[Признак Заем погашен]											
--, a.[Заем погашен день]											
--,a.[Заем выдан месяц]											
--, b.ДатаПлатежа											
--, НомерПлатежа											
----, case when [Признак Заем погашен]=1 then x1.[основной долг начислено нарастающим итогом] else  x.[основной долг начислено нарастающим итогом] end [основной долг начислено нарастающим итогом]											
----, case when [Признак Заем погашен]=1 then x1.[основной долг уплачено нарастающим итогом] else  x.[основной долг уплачено нарастающим итогом] end [основной долг уплачено нарастающим итогом]											
----											
----, case when [Признак Заем погашен]=1 then x1.[Проценты начислено  нарастающим итогом] else  x.[Проценты начислено  нарастающим итогом] end [Проценты начислено  нарастающим итогом]											
----, case when [Признак Заем погашен]=1 then x1.[Проценты уплачено  нарастающим итогом] else  x.[Проценты уплачено  нарастающим итогом] end [Проценты уплачено  нарастающим итогом]											
--											
--, isnull(x_all.[Поступления ОД нарастающим итогом]											
--, x_all_last.[Поступления ОД нарастающим итогом] )  [Поступления ОД нарастающим итогом]											
--, sum([ОД по графику])      over(partition by b.код order by b.ДатаПлатежа rows between unbounded preceding and current row)  [ОД по графику нарастающим итогом]											
--, isnull(x_all.[Поступления Проценты нарастающим итогом]											
--, x_all_last.[Поступления Проценты нарастающим итогом]) [Поступления Проценты нарастающим итогом]											
--, sum([Проценты по графику]) over(partition by b.код order by b.ДатаПлатежа rows between unbounded preceding and current row) [Проценты по графику нарастающим итогом]											
--, case when a.[Заем погашен день]<=b.ДатаПлатежа then 1 else 0 end as [Закрыт к платежу]											
--, case when b.ДатаПлатежа<getdate()-1 then 'Созрел' else 'Не созрел' end [Прошла дата платежа]				
--, x.[Поступления ОД нарастающим итогом]+x.[Поступления Проценты нарастающим итогом] [Поступления итоговые]
--, x.[сумма поступлений  нарастающим итогом] [Поступления денег итоговые]
--, x.[Поступления Проценты нарастающим итогом] [Поступления Проценты итоговые]
--, x.[Поступления ОД нарастающим итогом] [Поступления ОД итоговые]
----into #final											
--from #f a 											
--left join #ep b on a.Номер=b.Код											
----outer apply (select top 1 * from #b c where c.Код=a.Номер and d=b.ДатаПлатежа and [Признак Заем погашен]=0) x											
----left join #x ref_p on ref_p.Номер=a.Номер											
----outer apply (select top 1 * from #b c where c.Код=a.Номер and ref_p.ДатаПлатежа=b.ДатаПлатежа order by d desc) x1											
--outer apply (select top 1 * from #b c where c.Код=a.Номер and d=b.ДатаПлатежа and (b.ДатаПлатежа<=a.[Заем погашен день] or a.[Заем погашен день] is  null) ) x_all											
--outer apply (select top 1 * from #b c where c.Код=a.Номер and b.ДатаПлатежа>a.[Заем погашен день] order by d desc  ) x_all_last											
--outer apply (select top 1 * from #b c where c.Код=a.Номер  order by d desc  ) x											
-- --where b.ДатаПлатежа<getdate()-1											
----and b.Код='21120820158629'											
--)
----select * from v
--select     
--    a.[Код] 
--,   a.Срок 
--,   a.[Выданная сумма] 
--,   a.[Признак Заем погашен] 
--,   a.[Заем погашен день]  
--,   a.[Заем выдан месяц]  
--,   a.[ДатаПлатежа]  
--,   a.[НомерПлатежа]  
--,   a.[Поступления ОД нарастающим итогом] 
--,   a.[ОД по графику нарастающим итогом]  
--,   a.[Поступления Проценты нарастающим итогом]  
--,   a.[Проценты по графику нарастающим итогом]  
--,   a.[Закрыт к платежу]  
--,   a.[Прошла дата платежа]    
--,   a.[Поступления ОД нарастающим итогом] + a.[Поступления Проценты нарастающим итогом]   [Поступления ОД и Проценты нарастающим итогом]
--,   a.[ОД по графику нарастающим итогом] + a.[Проценты по графику нарастающим итогом]   [ОД и проценты по графику нарастающим итогом]
--,   case when [Прошла дата платежа] = 'Созрел' and ROW_NUMBER() over (partition by [Код],[Прошла дата платежа]  order by [НомерПлатежа]  desc)=1 then 1 else 0 end [Финальный период]
--,   ROW_NUMBER() over (partition by [Код] order by (select 1)) rn
--,   GETDATE() as created
--,   [Поступления итоговые]
--,   [Поступления денег итоговые]
--,   [Поступления ОД итоговые]
--,   [Поступления Проценты итоговые]
--into #final 
--from     v a
--
--
----select * from #final
--
----order by a.Номер , b.ДатаПлатежа											
--	--	exec select_table '#final'
--											
--drop table if exists Analytics.dbo.[Отчет Погашение ОД и ПРОЦЕНТОВ инстоллмент]											
--select * into Analytics.dbo.[Отчет Погашение ОД и ПРОЦЕНТОВ инстоллмент]  from #final											
											
 --select a.*, b.[Займов винтаж], b.[Погашено винтаж] , b.[Выданная сумма винтаж] 
 --,case when count(case when [Прошла дата платежа] = 'Созрел' then 1 end) over (partition by a.[Заем выдан месяц], [НомерПлатежа]  ) =  count(*) over (partition by a.[Заем выдан месяц], [НомерПлатежа]  ) then 1 else 0  end as [Вызревший платеж]
 --
 --from Analytics.dbo.[Отчет Погашение ОД и ПРОЦЕНТОВ инстоллмент]		 a
 --left join 
 --(select
 --[Заем выдан месяц]
 --, count(case when rn=1 then Код end) [Займов винтаж]
 --, count(case when rn=1 then [Заем погашен день] end) [Погашено винтаж]
 --, sum(case when rn=1 then [Выданная сумма] end) [Выданная сумма винтаж] 
 --
 --from Analytics.dbo.[Отчет Погашение ОД и ПРОЦЕНТОВ инстоллмент]
 --group by [Заем выдан месяц]
 --) b
 --on a.[Заем выдан месяц]=b.[Заем выдан месяц]
 ----where код='21120620157477'
 --order by 1, НомерПлатежа
--											
--						select * from reports.dbo.dm_cmrexpectedrepayments					
 --where код='21122020168463'
 --order by ДатаПлатежа
											
--select * from #ep											
--where Код='21120820158629'											

end