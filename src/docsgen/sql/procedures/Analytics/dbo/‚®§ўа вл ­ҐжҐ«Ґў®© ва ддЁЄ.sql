CREATE   proc [dbo].[Возвраты нецелевой траффик]
as

begin


drop table if exists #t1

select * into #t1 from mv_dm_Factor_Analysis
where [Признак Заем выдан]=1


drop table if exists #f

select isnull(v.id, b.id) id

, 

case 
when b.id is not null then 'Займ со звонка'
when v.id is not null then 'Возврат'
else 'LCRM атрибуция'
end [Тип займа]
,case when datediff(day, v.[Дата лида], a.[Заем выдан] ) <=90 then 'Возврат через 0 - 90 дней' 
      when datediff(day, v.[Дата лида], a.[Заем выдан] ) >90 then 'Возврат через 91+ день'  end [Период возврата]
,a.[Заем выдан]
,a.[Заем выдан месяц]
,a.[Выданная сумма]
,a.ДатаЗаявкиПолная
into #f
from #t1 a
left join v_feodor_leads b on a.Номер=b.[Номер заявки]
left join v_feodor_leads v on a.Номер=v.[возврат]
where [Вид займа]='Первичный' and a.isPts=1 and [Канал от источника]='CPA нецелевой'

drop table if exists #f1

select a.* , b.[Группа каналов], b.[Канал от источника], b.CompanyNaumen
into #f1
from #f a
left join 

Feodor.dbo.dm_leads_history b on a.id=b.id


order by 1

drop table if exists dbo.[Отчет по источниками нецелевого траффика с учетом возвратов]
select *, getdate() as created into dbo.[Отчет по источниками нецелевого траффика с учетом возвратов] from #f1


--select * from dbo.[Отчет по источниками нецелевого траффика с учетом возвратов] 
--order by 3

end