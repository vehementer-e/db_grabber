
create   proc dbo.[Способ оформления займа ПЭП1/ПЭП2/ПЭП3]
as
begin

drop table if exists #PTS
select [ДатаВыдачи] = cast([ДатаВыдачи] as date)
      --,[Дата]
   
      ,[number] = s.[Код]
	  --,cp.[Срок] [СрокЗайма]  
	  --,cp.[КредитныйПродукт]
    
	  ,[СуммаЗайма] = [Сумма]
into #PTS
from [Reports].[dbo].[dm_Sales] s with (nolock)
where ishistory = 0 
---------------------------------
--select count(*) from #PTS  where cast([ДатаВыдачи] as date) = '2020-03-19'

drop table if exists #mfo_doc_dog
select Номер, точка
into #mfo_doc_dog
from [Stg].[_1cMFO].[Документ_ГП_Договор] with (nolock)

drop table if exists #dcmnt_pep_request
select *
into #dcmnt_pep_request
from [Stg].[_1cDCMNT].[ПЭП_Заявка_Сборка] with (nolock)

--select * from #dcmnt_pep_request
--where ДатаПодписанияПЭП=1
--order by ПЭП2, ЗаявкаНомер

drop table if exists #t_end0
select distinct --d.[Номер] as [ДоговорНомер]
	    pts.[number] as [ДоговорНомер]
	   , pts.[ДатаВыдачи]
	   , 1 as [КолвоЗаймов]	  
	   , pts.[СуммаЗайма] [СуммаВыдачи]
		,case
			when o.[Код]=N'8999' then N'ПЭП1'
			when pep.[ДатаПодписанияПЭП]=1 and pep.[ПЭП2]=0 then N'ПЭП2'	--pep.[ПЭП2]=1 then N'ПЭП2'
			when o.[Наименование] like '%Партнер №%' then N'Партнер'
			when pep.[ВМ]=1 then N'ВМ'
		end as [СпособОформленияЗайма]
		,case when pep3.Номер is not null then 'pep3' else '' end pep3
into #t_end0 
from #PTS pts

left join #mfo_doc_dog  d with (nolock) on pts.[number]=d.[Номер]
left join [Stg].[_1cMFO].[Справочник_ГП_Офисы] o with (nolock) on d.[Точка]=o.[Ссылка]
left join #dcmnt_pep_request pep on pts.[number]=pep.[ЗаявкаНомер]
left join reports.dbo.dm_report_pep3_loans_sales_info pep3 on pep3.Номер=pts.number



;
with v as (

select *, ROW_NUMBER() OVer(partition by [ДоговорНомер] order by (select 1)) rn from #t_end0
)
delete from v where rn>1


drop table if exists dbo.[Отчет_Способ оформления займа ПЭП1/ПЭП2/ПЭП3]
select * into dbo.[Отчет_Способ оформления займа ПЭП1/ПЭП2/ПЭП3]
from #t_end0


end