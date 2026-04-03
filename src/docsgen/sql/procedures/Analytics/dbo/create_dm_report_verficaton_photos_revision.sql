CREATE PROC [dbo].[create_dm_report_verficaton_photos_revision]
	@start_date_update date = null
as
begin


/*
	set @start_date_update = isnull(@start_date_update, cast(getdate()-30 as date) )
	--
	--declare @start_date_update date set @start_date_update = '20200713'

	drop table if exists [#t] 
	drop table if exists [#Типы комментариев при проверках] 
	select * into [#Типы комментариев при проверках] from [Analytics].[dbo].[Типы комментариев при проверках]

 select 
       t.[Направление]
      ,t.[ВерхнийУровеньКомментария]
      ,t.[НижнийУровеньКомментария]
      ,t.[ЧеловекопонятноеНазваниеДляНижнегоУровня], 
  dateadd(year, -2000, c.Период) ДатаКомментария,
  c.[Комментарий],
  c.Заявка,
  c.[Пользователь_Ссылка],
  getdate() as created
  
   into #t
  from [#Типы комментариев при проверках] t
  join  stg.[_1cMFO].[РегистрСведений_ГП_КомментарииЗаявок]  c with(nolock) on c.Комментарий like '%'+t.[ВерхнийУровеньКомментария]+'%'
                                                                  and  c.Комментарий like '%'+t.[НижнийУровеньКомментария]+'%' 

																  and dateadd(year, -2000, c.Период)>=@start_date_update

--exec Analytics.dbo.generate_create_table_script 'reports.dbo.dm_report_verficaton_photos_revision'
--CREATE TABLE [dbo].[dm_report_verficaton_photos_revision]
--(
--      [Направление] [NVARCHAR](2000)
--    , [ВерхнийУровеньКомментария] [NVARCHAR](2000)
--    , [НижнийУровеньКомментария] [NVARCHAR](2000)
--    , [ЧеловекопонятноеНазваниеДляНижнегоУровня] [NVARCHAR](2000)
--    , [ДатаКомментария] [DATETIME]
--    , [Комментарий] [NTEXT]
--    , [Заявка] [BINARY](16)
--    , [Пользователь_Ссылка] [BINARY](16)
--    , [created] [DATETIME]
--);



begin tran

	delete from Analytics.dbo.dm_report_verficaton_photos_revision where ДатаКомментария>=@start_date_update
	insert into Analytics.dbo.dm_report_verficaton_photos_revision

	select * from #t

commit tran



	drop table if exists [#mv_dm_report_verficaton_photos_revision]
	

	select * into [#mv_dm_report_verficaton_photos_revision] 
	from analytics.[dbo].[v_dm_report_verficaton_photos_revision]
	
begin tran

	--drop table if exists  analytics.[dbo].[mv_dm_report_verficaton_photos_revision]
	--select * into analytics.[dbo].[mv_dm_report_verficaton_photos_revision] 
	--from [#mv_dm_report_verficaton_photos_revision]
	delete from analytics.[dbo].[mv_dm_report_verficaton_photos_revision]
	insert into analytics.[dbo].[mv_dm_report_verficaton_photos_revision]
	select * from [#mv_dm_report_verficaton_photos_revision]

commit tran
	
	*/
	drop table if exists [#mv_Заявки с доработкам федор]
	select * into [#mv_Заявки с доработкам федор] 
	from analytics.[dbo].[Заявки с доработкам федор]

begin tran


	--drop table if exists  analytics.[dbo].[mv_Заявки с доработкам федор]
	--select * into analytics.[dbo].[mv_Заявки с доработкам федор] 
	--from [#mv_Заявки с доработкам федор]

	delete from analytics.[dbo].[mv_Заявки с доработкам федор]
	insert into analytics.[dbo].[mv_Заявки с доработкам федор]
	select * from [#mv_Заявки с доработкам федор]

commit tran


drop table if exists #t11


select [Номер заявки]collate Cyrillic_General_CI_AS [Номер заявки], min([Дата статуса]) ДатаКД_Старт, max([Дата след.статуса]) ДатаКД_Конец
into #t11
from 

reports.dbo.dm_FedorVerificationRequests a 
where Статус='Контроль данных'
group by [Номер заявки]

drop table if exists #t12

select [Номер заявки] collate Cyrillic_General_CI_AS [Номер заявки], min([Дата статуса]) ДатаКД_Старт, max([Дата след.статуса]) ДатаКД_Конец
into #t12

from 

Reports.dbo.dm_FedorVerificationRequests_without_coll AS a 
where Статус='Контроль данных'
group by [Номер заявки]

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

drop table if exists #t1
;
with v as (
select a.*, c.Комментарий 

--into #t1
from (
select * from #t11

/*
union all

select [Номер заявки] collate Cyrillic_General_CI_AS [Номер заявки], min([Дата статуса]) ДатаКД_Старт, max([Дата след.статуса]) ДатаКД_Конец
from 

reports.dbo.dm_FedorVerificationRequests_Installment a 
where Статус='Контроль данных'
group by [Номер заявки]
*/
--DWH-2684
union all

select * from #t12


) a

left join (select *, comment Комментарий  from  request_comment ) c on c.number=a.[Номер заявки] and c.created between ДатаКД_Старт and ДатаКД_Конец

--left join stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС b  with(nolock)  on  a.[Номер заявки] =b.Номер
--left join stg._1cMFO.РегистрСведений_ГП_КомментарииЗаявок   c with(nolock) on  c.Заявка=b.Ссылка and dateadd(year, -2000, c.Период ) between ДатаКД_Старт and ДатаКД_Конец

)

, v_ as (
select *
, case when Комментарий like '%Докред%' and Комментарий like '%Необходимо подтверждение от руководства%'  then 1 
  else 0 end [Проблема Докред]
, case when Комментарий like '%полный адрес фактического места жительства%'  then 1 
       when Комментарий like '%Полный адрес, где вы проживаете%'  then 1 
       when Комментарий like '%Полностью пропишите фактический адрес проживания%'  then 1 
       when Комментарий like '%прописать фактический адрес проживания%'  then 1 
       when Комментарий like '%полный фактический адрес%'  then 1 
       when Комментарий like '%Напишите в комментарии свой фактический адрес проживания%'  then 1 
       when Комментарий like '%в комментариях к заявке укажите полный фактический адрес проживания%'  then 1 
  else 0 end [Проблема Фактический адрес]
, case 
       when Комментарий like '%Селфи -%'  then 1 
       when Комментарий like '%Селфи с 2-3 стр. паспорта -%'  then 1 
       when Комментарий like '%Селфи с 2-3 стр. паспорта:%'  then 1 
       when Комментарий like '%Селфи:%'  then 1 
       when Комментарий like '%Фото вашего лица:%'  then 1 
       when Комментарий like '%Фото лица и разворота паспорта со страницами с вашей фотографией и информацией, кем выдан паспорт:%'  then 1 

  else 0 end [Проблема Селфи]
, case when Комментарий like '%Фото 2-3 страницы паспорта -%'  then 1 
       when Комментарий like '%Фото 2-3 страницы паспорта:%'  then 1 
       when Комментарий like '%Селфи с 2-3 стр. паспорта:%'  then 1 
       --when Комментарий like '%Селфи:%'  then 1 
       --when Комментарий like '%Фото вашего лица:%'  then 1 
       when Комментарий like '%Фото лица и разворота паспорта со страницами с вашей фотографией и информацией, кем выдан паспорт:%'  then 1 
       when Комментарий like '%Фото последней действующей прописки в паспорте -%'  then 1 
       when Комментарий like '%Фото последней действующей прописки в паспорте -%'  then 1 
       when Комментарий like '%Фото последней действующей прописки в паспорте:%'  then 1 
       when Комментарий like '%Фото прописки в паспорте:%'  then 1 
       when Комментарий like '%Фото разворота паспорта с последним штампом о прописке:%'  then 1 
       when Комментарий like '%Фото семейного положения в паспорте:%'  then 1 
       when Комментарий like '%Фото семейного положения в паспорте 14-15 стр.%'  then 1 
       when Комментарий like '%Фото страниц паспорта с вашей фотографией и информацией, кем выдан паспорт:%'  then 1 
       when Комментарий like '%Фото страниц паспорта с вашей фотографией и информацией, кем выдан паспорт:%'  then 1 
       when Комментарий like '%Фото семейного положения в паспорте страница 14-15%'  then 1 
       when Комментарий like '%заверить адрес по прописке%'  then 1 
       when Комментарий like '%свидетельства о заключении%'  then 1 
       when Комментарий like '%свидетельство о заключении%'  then 1 
       when Комментарий like '%Фото 2-3 страниц паспорт:%'  then 1 
       when Комментарий like '%ФОТО ПЕРВОЙ СТРАНИЦЫ ПАСПОРТА%'  then 1 
       when Комментарий like '%Фото прописки в паспорте%'  then 1 
       when Комментарий like '%Фото РАЗВОРОТА 2-3 страницы паспорта%'  then 1 
       when Комментарий like '%Фото самой 1 стр паспорта%'  then 1 
       when Комментарий like '%Чтобы продолжить оформление займа%' and Комментарий like '%паспорт%'  then 1 
       when Комментарий like '%пришлите пожалуйста%' and Комментарий like '%паспорт%'  then 1 
 
  else 0 end [Проблема Паспорт]
, case when Комментарий like '%Фото внешнего разворота ПТС:%'  then 1 
       when Комментарий like '%Фото внутреннего разворота ПТС:%'  then 1 
       when Комментарий like '%Фото обеих сторон ПТС:%'  then 1 
       when Комментарий like '%Фото полного разворота ПТС с обновленными данными:%'  then 1 
       when Комментарий like '%Фото ПТС и СТС с обновленными данными:%'  then 1 
       when Комментарий like '%Фото ПТС и СТС:%'  then 1 
       when Комментарий like '%Фото пункта 1 из ПТС:%'  then 1 
       when Комментарий like '%Пришлите точно такие же развороты ПТС%'  then 1 
       when Комментарий like '%фото полного внешнего разворота ПТС%'  then 1 
       when Комментарий like '%разворот ПСМ%'  then 1 
       when Комментарий like '%Фото полных разворотов ПТС%'  then 1 
       when Комментарий like '%Фото внешнего разворота ПТС%'  then 1 
       when Комментарий like '%новые фото ПТС%'  then 1 
       when Комментарий like '%фото внешнего полного разворота ПТС%'   then 1 
       when Комментарий like '%полного разворота ПТС%'   then 1 
       when Комментарий like '%полный разворот ПТС%'   then 1 
       when Комментарий like '%Чтобы продолжить оформление займа%' and Комментарий like '%ПТС%'  then 1 

  else 0 end [Проблема ПТС]
, case when Комментарий like '%Фото обеих сторон СТС%'  then 1 
       when Комментарий like '%Фото ПТС и СТС с обновленными данными:%'  then 1 
       when Комментарий like '%Фото ПТС и СТС:%'  then 1 
       when Комментарий like '%Фото СТС с обновленными данными:%'  then 1 
       when Комментарий like '%Фото СТС, стороны с данными о владельце:%'  then 1 
       when Комментарий like '%Фото СТС, стороны с данными об авто:%'  then 1 
       when Комментарий like '%Фото СТС%'  then 1 
  else 0 end [Проблема СТС]
, case when Комментарий like '%Фото последней действующей прописки в паспорте -%'  then 1 
       when Комментарий like '%Фото последней действующей прописки в паспорте:%'  then 1 
       when Комментарий like '%Фото прописки в паспорте:%'  then 1 
       when Комментарий like '%Фото прописки в паспорте 6-7 стр%'  then 1 
       when Комментарий like '%Фото разворота паспорта с последним штампом о прописке:%'  then 1 
       when Комментарий like '%заверить адрес по прописке%'  then 1 
       when Комментарий like '%Фото прописки в паспорте%'  then 1 

  else 0 end [Проблема Прописка]
from v 
--select * from #t1
)
select *


--,
--nullif(
-- [Проблема ПТС в Кармани]
--
--+[Проблема Фактический адрес]	
--+[Проблема Селфи]	
--+[Проблема Паспорт]	
--+[Проблема ПТС]	
--+[Проблема СТС]	
--+[Проблема Прописка]
--, 0)  ch
into #t1
from v_
--where ДатаКД_Старт>='20220401'

--select *,
--nullif(
-- [Проблема Докред]
--
--+[Проблема Фактический адрес]	
--+[Проблема Селфи]	
--+[Проблема Паспорт]	
--+[Проблема ПТС]	
--+[Проблема СТС]	
--+[Проблема Прописка]
--, 0)  ch
--from #t1
--where (Комментарий like '%Пришлите%' or Комментарий like '%Чтобы продолжить оформление займа%' )
--and
--nullif(
-- [Проблема Докред]
--
--+[Проблема Фактический адрес]	
--+[Проблема Селфи]	
--+[Проблема Паспорт]	
--+[Проблема ПТС]	
--+[Проблема СТС]	
--+[Проблема Прописка]
--, 0) is null
--and 1=0
--order by 2 desc

drop table if exists #t2

select [Номер заявки]
, sum([Проблема Докред]           )  [Доработки КД количество проблем Докред]     
, sum([Проблема Фактический адрес])  [Доработки КД количество проблем Фактический адрес]
, sum([Проблема Селфи]			  )  [Доработки КД количество проблем Селфи]			  
, sum([Проблема Паспорт]		  )  [Доработки КД количество проблем Паспорт]		  
, sum([Проблема ПТС]			  )  [Доработки КД количество проблем ПТС]			  
, sum([Проблема СТС]			  )  [Доработки КД количество проблем СТС]			  
, sum([Проблема Прописка]		  )  [Доработки КД количество проблем Прописка]		  
, count( case when 
[Проблема Докред]              =1 or     
[Проблема Фактический адрес]   =1 or
[Проблема Селфи]			   =1 or
[Проблема Паспорт]		  	   =1 or
[Проблема ПТС]			  	   =1 or
[Проблема СТС]			  	   =1 or
[Проблема Прописка]		  	   =1 then 1 end) [Количество доработок]
into #t2
from #t1
group by [Номер заявки]
having 
 sum([Проблема Докред]           )    +
 sum([Проблема Фактический адрес]) 	  +
 sum([Проблема Селфи]			  )   +
 sum([Проблема Паспорт]		  ) 	  +
 sum([Проблема ПТС]			  ) 	  +
 sum([Проблема СТС]			  ) 	  +
 sum([Проблема Прописка]		  )   >0


begin tran

--drop table if exists analytics.dbo.[Отчет доработки КД]
--select * into analytics.dbo.[Отчет доработки КД]
--from  #t2
delete from  analytics.dbo.[Отчет доработки КД]
insert into analytics.dbo.[Отчет доработки КД]
select * from  #t2

--select * from analytics.dbo.[Отчет доработки КД]
commit tran

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------



--analytics.[dbo].[v_dm_report_verficaton_photos_revision]

--delete from Analytics.dbo.dm_report_verficaton_photos_revision where Заявка is null
--select * from Analytics.dbo.dm_report_verficaton_photos_revision
--order by Заявка

--select count(*) from Analytics.dbo.dm_report_verficaton_photos_revision
--select count(*) from reports.dbo.dm_report_verficaton_photos_revision where Заявка is not null
end