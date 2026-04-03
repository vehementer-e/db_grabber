		CREATE   proc [dbo].[Цели займов]

		as

		begin
		
	
	  


  drop table if exists [Отчет Цели займов]		
		
CREATE TABLE [Отчет Цели займов]		
(       [Номер] [NVARCHAR](14)   		
, [Цель займа] [NVARCHAR](250) 		
, priority_source int		
		
);		
		
		
insert into [Отчет Цели займов]		
  		
select  r.Number collate Cyrillic_General_CI_AS Number		
      , Name collate Cyrillic_General_CI_AS  [Цель займа]		
	  , 1 as priority_source	
		
from Stg._fedor.core_CheckListItem  a 		
join (		
select  id from Stg._fedor.dictionary_CheckListItemType		
where name = 'Цель займа'		
) b 		
on a.IdType=b.Id		
join Stg._fedor.dictionary_CheckListItemStatus c on c.id=a.IdStatus		
left join Stg._fedor.core_ClientRequest r on r.id=a.IdClientRequest		
		
		
		
drop table if exists #LoanPurpose		
select top 1000 * into #LoanPurpose from [PRODSQL02].[fedor.core].dictionary.LoanPurpose		
		
insert into [Отчет Цели займов]		
select r.Number collate Cyrillic_General_CI_AS Number		
, lp.name  [Цель займа]		
, 2 as priority_source		
		
from  stg._fedor.core_ClientRequest r join #LoanPurpose lp on r.IdLoanPurpose=lp.id		
		
		
insert into [Отчет Цели займов]		
		
select Номер		
, cz.Наименование		
, 3 as priority_source		
		
from  stg._1cMFO.Документ_ГП_Заявка z join stg._1cmfo.Справочник_ГП_ЦелиЗаймов cz on cz.Ссылка=z.ЦельЗайма		



		
insert into [Отчет Цели займов]		
		
select Номер		
, null
, 4 as priority_source		
		
from  stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС	


insert into [Отчет Цели займов]		
		
select [Номер заявки]		
, null
, 5 as priority_source		
		
from  mv_loans	






		
;		
with v as (		
select *, ROW_NUMBER() over(partition by Номер order by priority_source) rn from [#Цели займов]		
) delete from v where rn>1		
;

drop table if exists [#Цели займов аналитические]
		
select a.*, isnull(b.[Цель займа аналитическая], 'Другое') [Цель займа аналитическая] into [#Цели займов аналитические] 
from [Отчет Цели займов] a left join stg.files.[цели займов_stg] b on a.[Цель займа]=b.[Цель займа]

--select * from [#Цели займов аналитические]
		;

--drop table if exists [#Цели займов]		
--		
--CREATE TABLE [#Цели займов]		
--(       [Номер] [NVARCHAR](14)   		
--, [Цель займа] [NVARCHAR](250) 		
--, priority_source int		
--		
--);		
--		
--		
--insert into [#Цели займов]		
--  		
--select  r.Number collate Cyrillic_General_CI_AS Number		
--      , Name collate Cyrillic_General_CI_AS  [Цель займа]		
--	  , 1 as priority_source	
--		
--from Stg._fedor.core_CheckListItem  a 		
--join (		
--select  id from Stg._fedor.dictionary_CheckListItemType		
--where name = 'Цель займа'		
--) b 		
--on a.IdType=b.Id		
--join Stg._fedor.dictionary_CheckListItemStatus c on c.id=a.IdStatus		
--left join Stg._fedor.core_ClientRequest r on r.id=a.IdClientRequest		
--		
--		
--		
--drop table if exists #LoanPurpose		
--select top 1000 * into #LoanPurpose from [PRODSQL02].[fedor.core].dictionary.LoanPurpose		
--		
--insert into [#Цели займов]		
--select r.Number collate Cyrillic_General_CI_AS Number		
--, lp.name  [Цель займа]		
--, 2 as priority_source		
--		
--from  Stg._fedor.core_ClientRequest r join #LoanPurpose lp on r.IdLoanPurpose=lp.id		
--		
--		
--insert into [#Цели займов]		
--		
--select Номер		
--, cz.Наименование		
--, 3 as priority_source		
--		
--from  Stg._1cMFO.Документ_ГП_Заявка z join stg._1cmfo.Справочник_ГП_ЦелиЗаймов cz on cz.Ссылка=z.ЦельЗайма		
--		
--		
--;		
--with v as (		
--select *, ROW_NUMBER() over(partition by Номер order by priority_source) rn from [#Цели займов]		
--) delete from v where rn>1		
--		
--		
--		;
--
----select [Текущая просрочка],* from mv_loans		
----where [Текущая просрочка]>=90		
--
--drop table if exists analytics.dbo.[Отчет цели займов]		
--select * into analytics.dbo.[Отчет цели займов] from [#Цели займов]		
--	;	
--
--
--with [Цели займов] as
--		(
--
--		select Номер
--		, lower(case when left ([Цель займа], 7) ='Займ на' then [Цель займа]		
--          when  left ([Цель займа], 3) ='на ' then 'Займ '+[Цель займа]		
--          when  [Цель займа] like 'Другое%' then 'займ на прочее'		
--          when  [Цель займа] ='Проверка не проводилась' then null		
--          else 'Займ на '+[Цель займа] 		
--		  end) [Цель займа]
--, [Цель займа] [Цель займа_изначальная]
--
--from 
--
--(
--	select Номер, replace ( replace (replace (replace ([Цель займа], '(удален)', ''), '(удален', ''), ' зп ', ' з/п' ) , 'ремонт автомобиля', 'ремонт авто' )  [Цель займа]  from [#Цели займов]
--
--) x
--
--		)
--
--
--select bucket,  b.[Цель займа], d, cast(sum([остаток од]) as bigint) [остаток од] 
--from v_balance  a
--left join [Цели займов] b on a.Код=b.Номер
--
--where d=cast(format(d, 'yyyy-MM-01') as date)
--and dpd>=91
--group by bucket,  b.[Цель займа],  d
--order by 2
--		
--select 		
--		
--  a.[Дата выдачи месяц]		
--, a.код		
--, a.[Дата выдачи день]		
--, [Просрока 91+ историческая]		
--, [Вид займа]		
--, cast(a.Сумма as bigint) Сумма		
--, case when b.dpd>=91 then 1 else 0 end [Текущая просрочка 91+]		
--, 1 [признак займ]		
--, [Признак погашен]		
--, lower(case when left ([Цель займа], 7) ='Займ на' then [Цель займа]		
--          when  left ([Цель займа], 3) ='на ' then 'Займ '+[Цель займа]		
--          when  [Цель займа] like 'Другое%' then [Цель займа]		
--          when  [Цель займа] like 'Другое%' then [Цель займа]		
--          when  [Цель займа] ='Проверка не проводилась' then null		
--          else 'Займ на '+[Цель займа] 		
--		  end) [Цель займа]
--, [Цель займа] [Цель займа_изначальная]
--		
--from mv_loans a		
--left join v_balance b on a.код=b.Код and b.d=cast(getdate() as date)		
--left join [#Цели займов] c on c.Номер=a.[Номер заявки]		
--where a.[Дата выдачи Месяц] BETWEEN '2020-09-01' and '2021-09-01'		
--order by [Просрока 91+ историческая], [Дата выдачи день]		


end