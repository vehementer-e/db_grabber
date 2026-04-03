CREATE   proc bot_leadgen

as 


declare @today date = cast(getdate() as date)

set language russian
set datefirst 7

drop table if exists #leadgen

           select 'bankiru-ref' Лидген into #leadgen  
 union  select 'bankiru'     Лидген  
 union  select 'ptsoff-leads'     Лидген  
 union  select 'Likemoney'     Лидген  
 union  select 'finya'     Лидген  
 union  select 'gidfinance'     Лидген  
 union  select 'gidfinance-installment'     Лидген  
 union  select 'gidfinance-installment-ref'     Лидген  
 union  select 'gidfinance-target'     Лидген  
 union  select 'credeo'     Лидген  
 union  select 'credeo-ref'     Лидген  
 union  select 'finardi-ref'     Лидген  
 union  select 'creditpts-api'     Лидген  
 union  select 'docpolis-ref'     Лидген  
 union  select 'leadnik-leads'     Лидген  
 union  select 'copyspace-ref'     Лидген  
 union  select 'zapravlyaem-dengami'     Лидген  
 union  select 'platonkin-ref'     Лидген  
 union  select 'procredits-ref'     Лидген  
 union  select 'procredits-ref'     Лидген  
 union  select 'greenking-ref'     Лидген  
 union  select 'osagome'     Лидген  
 union  select 'osagome-installment-ref'     Лидген  
 union  select 'caltat'     Лидген  
 union  select 'caltat-new'     Лидген  
 union  select 'finspin-api'     Лидген  
 union  select 'Youmen-ref'     Лидген  
 union 
select distinct value Лидген from  config
cross apply openjson(leadgen_bot_sources)
 union  SELECT distinct a.[uf_source]   FROM   Analytics._tg.leadgenBot_USERS a


-- select * from #leadgen

 --select * from reports.dbo.dm_Factor_Analysis_001 where Источник Like '%zapr%'

 drop table if exists #leads
 select uf_source, ДатаЛидаЛСРМ, sum(id) cnt into #leads from    [Feodor].[dbo].lead_cube a
 join #leadgen b on a.uf_source=b.Лидген
 where ДатаЛидаЛСРМ>getdate()-40
 group by uf_source, ДатаЛидаЛСРМ

drop table if exists #loans
select Код, ДатаВыдачи into #loans from reports.dbo.dm_Sales
where ДатаВыдачи>getdate()-40
and ishistory=0



drop table if exists #t1

select a.Источник, Телефон = 
cast(
'+7 ('+SUBSTRING(a.Телефон, 1, 3) + ') ' + 
                  SUBSTRING(a.Телефон, 4, 3) + '-' + 
                  SUBSTRING(a.Телефон, 7, 4)
 as nvarchar(max)) 
 , a.Номер
 , a.isInstallment
 , cast(a.ДатаЗаявкиПолная as date) [Дата заявки день]
 , isnull(cast( a.[Заем выдан]  as date), l.ДатаВыдачи) [Заем выдан день] 
 , cast( a.[Отказано]  as date) [Отказано день] 
 
 into #t1 
 
 from v_fa a
 left join #loans l on l.Код=a.Номер
where Источник <>'' and [Группа каналов]='CPA' and ДатаЗаявкиПолная>getdate()-40

drop table if exists #f
--select distinct Источник from #t1 order by 1

;


with dates as (
select 'stat_today'   command , @today since, @today till union all
select 'stat_yesterday'    , dateadd(day, -1, @today), dateadd(day, -1, @today) union all
select 'stat_week'         , DATEADD(DD, 2 - DATEPART(DW, DATEADD(DD, -1, @today)), DATEADD(DD, -1, @today)), dateadd(day, 6, DATEADD(DD, 2 - DATEPART(DW, DATEADD(DD, -1, @today)), DATEADD(DD, -1, @today))) union all
select 'stat_month'        , cast(format(@today, 'yyyy-MM-01') as date), dateadd(day, -1, dateadd(month, 1, cast(format(@today, 'yyyy-MM-01') as date) )) union all
select 'stat_last_3_d'        , dateadd(day, -2, @today), @today union all
select 'stat_last_5_d'        , dateadd(day, -4, @today), @today--union all
--select 'last_month'   , dateadd(month, -1, cast(format(@today, 'yyyy-MM-01') as date)) , dateadd(day, -1, cast(format(@today, 'yyyy-MM-01') as date))-- union all

)


select a.*, b.Лидген, text =
--case when since<>till then N'🎄' else N'🎄' end +'Период: '+char(10)+'<b>'+format(since, 'dd.MMM') + case when since<>till then ' - '+format(till, 'dd.MMM') else '' end +'</b>' +char(10)+char(10)+
case when since<>till then N'📆' else N'📅' end +'Период: '+char(10)+'<b>'+format(since, 'dd.MMM') + case when since<>till then ' - '+format(till, 'dd.MMM') else '' end +'</b>' +char(10)+char(10)+
N'🆕'+'Лидов - ' +format(isnull(l1.cnt, 0), '0') +' шт.'+char(10)+
N'ℹ'+'Заявок - ' +format(isnull(x1.cnt, 0), '0') +' шт.'+char(10)+char(10) +
'Выдано: '+char(10)+ isnull(x2.text, 'Нет выдач в этот период'+N'🙄')+char(10)+char(10)+
'Отказано: '+char(10)+ isnull(x3.text,'Нет отказов в этот период')

into #f
from dates a
cross join #leadgen  b
outer apply (select uf_source,  sum(cnt ) cnt from #leads c where ДатаЛидаЛСРМ between since and till and c.uf_source=b.Лидген group by uf_source ) l1
outer apply (select Источник, count(*)  cnt  from #t1 c where [Дата заявки день] between since and till and c.Источник=b.Лидген group by Источник) x1
outer apply (select Источник, string_agg(N'✅'+Телефон+',', char(10)) WITHIN GROUP  (ORDER BY right(Телефон, 4) ASC) text from #t1 c where [Заем выдан день] between since and till and c.Источник=b.Лидген group by Источник) x2
outer apply (select Источник, string_agg(N'❌'+Телефон+',', char(10))  WITHIN GROUP (ORDER BY right(Телефон, 4) ASC) text from #t1 c where [Отказано день] between since and till and c.Источник=b.Лидген group by Источник) x3


begin tran

--drop table if exists  dbo.[Оперативная витрина со статистикой для лидгенов]
--select * into  dbo.[Оперативная витрина со статистикой для лидгенов] from #f
delete from dbo.[Оперативная витрина со статистикой для лидгенов]
insert into dbo.[Оперативная витрина со статистикой для лидгенов]
select *  from #f

commit tran

 