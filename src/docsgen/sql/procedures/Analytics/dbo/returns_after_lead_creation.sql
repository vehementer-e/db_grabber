

CREATE     proc [dbo].[returns_after_lead_creation]--[dbo].[Создание витрины с возвратами]

as
begin


drop table if exists #Factor_Analysis;

select Номер, Телефон, isInstallment, [Выданная сумма], [Заем выдан], ДатаЗаявкиПолная into #Factor_Analysis from mv_dm_Factor_Analysis
where [Вид займа]='Первичный' and [Заем выдан] is not null	 and [Группа каналов]<>'Партнеры'

;with v as (select *, ROW_NUMBER() over(partition by Телефон order by [Заем выдан] ) rn from #Factor_Analysis ) delete from v where rn>1


drop table if exists #f_leads;

select 
  Телефон
, [Дата лида]
, [Номер заявки]
, id 
, lead_id 

into #f_leads 

from v_feodor_leads
where [Статус лида]<>'Новый'


--select * from #f_leads

delete a from #Factor_Analysis a join #f_leads f on a.Номер=f.[Номер заявки]

drop table if exists #ret_ref;
select a.Номер 
,a.isInstallment 
,a.[Заем выдан] 
,a.[Выданная сумма] 
, x.id 
, GETDATE() as created 
,x.lead_id
into #ret_ref 
from #Factor_Analysis a 
--left join  #f_leads    on a.Номер=f.[Номер заявки]
outer apply 
(select top 1 
* 
from 
#f_leads f 
where f.Телефон=a.Телефон 
and a.ДатаЗаявкиПолная>=f.[Дата лида] 
order by [Дата лида] desc

) x
 --  where f.[Номер заявки] is null			 



drop table if exists #ret_ref2;
select a.Номер 
,a.isInstallment 
,a.ДатаЗаявкиПолная 
,a.[Заем выдан] 
,a.[Выданная сумма] 
, x.id 
, GETDATE() as created 
,x.lead_id

into #ret_ref2 
from #Factor_Analysis a 
--left join  #f_leads    on a.Номер=f.[Номер заявки]
outer apply 
(select top 1 
* 
from 
#f_leads f 
where f.Телефон=a.Телефон 
and a.ДатаЗаявкиПолная between f.[Дата лида]  and dateadd(day, 30, 	f.[Дата лида])
order by [Дата лида] 

) x
 --  where f.[Номер заявки] is null

--select *, count(*) over(partition by id) cnt from #ret_ref
--order by cnt desc


begin tran
delete from returns_references2
--drop table if exists returns_references2
--select * into returns_references2 from #ret_ref2
insert into returns_references2
select * 
from #ret_ref2

--select * 
--from returns_references2
commit tran

insert into feodor.[dbo].[dm_leads_history_ids_to_update]
select b.id from returns_references2 b
left join Feodor.dbo.dm_leads_history a   on a.id=b.id 
where isnull(a.[Возврат] , '')<>b.Номер	  and b.id is not null




begin tran
delete from returns_references
--drop table if exists returns_references
insert into returns_references
select * 
from #ret_ref
commit tran

exec [dbo].[Возвраты нецелевой траффик]


 end
