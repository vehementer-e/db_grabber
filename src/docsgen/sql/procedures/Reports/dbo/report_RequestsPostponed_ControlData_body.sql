-- exec [dbo].[report_dashboard_001_CC] 
CREATE PROCEDURE [dbo].[report_RequestsPostponed_ControlData_body] 

@pageNo int
AS
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for procedure here

drop table if exists #dokred
select z.[НомерЗаявки]
into #dokred
from Stg.[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] z
--left join Stg.[_1cCRM].[Перечисление_ВидыДокредитования] d on z.[Докредитование]=d.[Ссылка]
where z.[Докредитование]=0xB3603565B63EB9B14723A40BFBC73122	-- ДокредитованиеПодТекущийЗалог


drop table if exists #t1
select [ЗаявкаНомер_Исх] ,[ЗаявкаСсылка_Исх] ,[СостояниеЗаявки] ,[СтатусДляСостояния]  ,[Период_Исх]
	  --,datepart(hh,[Период_Исх]) as [ВремяСтатусаВх]
      ,[СтатусНаим_Исх] ,[Период_След] ,[СтатусНаим_След]
	  --,row_number() over(partition by [ЗаявкаНомер_Исх] order by [Период_Исх] asc) as [row_numb]
	  ,[ИсполнительНаим_Исх] ,[ИсполнительНаим_След]
	  ,[ПричинаНаим_Исх] ,[ПричинаНаим_След]

      ,case when not [ПричинаНаим_Исх] is null then [ПричинаНаим_Исх] when [ПричинаНаим_Исх] is null and not [ПричинаНаим_След] is null then [ПричинаНаим_След] end as [ПричинаНаим_След2] 

into #t1

from [dwh_new].[dbo].[mt_requests_transition_mfo] with (nolock) 
where [СостояниеЗаявки]=N'Отложено' and [СтатусДляСостояния]=N'Контроль данных' and 
	  [ИсполнительНаим_Исх] <> N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ' and
	  --[ЗаявкаДата_Исх] between dateadd(month,0,dateadd(MONTH,datediff(MONTH,0,Getdate()),0)) and  Getdate()
	  [Период_След] between (case  when datepart(dd,Getdate()) = 1 then dateadd(MONTH,datediff(MONTH,0,dateadd(day,-1,Getdate())),0) else  dateadd(MONTH,datediff(MONTH,0,Getdate()),0) end)
							and (case  when datepart(dd,Getdate()) = 1 then dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0)) else Getdate() end)
	  --[ЗаявкаНомер_Исх]=N'19102910000102' --N'19102810000270'
	  --[ЗаявкаНомер_Исх] in (select [ЗаявкаНомер_Исх] from [dwh_new].[dbo].[mt_requests_transition_mfo] with (nolock) where [ЗаявкаДата_Исх] between dateadd(month,0,dateadd(MONTH,datediff(MONTH,0,Getdate()),0)) and  Getdate())
--order by [ЗаявкаНомер_Исх] desc ,[Период_Исх] desc

union all

--------------------------- добавим заявки на момент формирования отчета в отложенном состоянии

select [ЗаявкаНомер_Исх] ,[ЗаявкаСсылка_Исх] ,[СостояниеЗаявки] ,[СтатусДляСостояния]  
	  ,[Период_След] as [Период_Исх] ,[СтатусНаим_Исх] ,getdate() as [Период_След] ,[СтатусНаим_След]
	  ,[ИсполнительНаим_След] as [ИсполнительНаим_Исх] ,N'' as [ИсполнительНаим_След]
	  ,[ПричинаНаим_След] as [ПричинаНаим_Исх] ,N'' as [ПричинаНаим_След]
	  ,case when not [ПричинаНаим_Исх] is null then [ПричинаНаим_Исх] when [ПричинаНаим_Исх] is null and not [ПричинаНаим_След] is null then [ПричинаНаим_След] end as [ПричинаНаим_След2] 

from [dwh_new].[dbo].[mt_requests_transition_mfo] tt0 with (nolock) 
where [СтатусДляСостояния]=N'Контроль данных' and [СтатусНаим_След]=N'Отложено рассмотрение' and [СостояниеЗаявки]=N'В работе'
	  and [ИсполнительНаим_След] <> N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ' --
	  and  [Период_След] between (case  when datepart(dd,Getdate()) = 1 then dateadd(MONTH,datediff(MONTH,0,dateadd(day,-1,Getdate())),0) else  dateadd(MONTH,datediff(MONTH,0,Getdate()),0) end)
							and (case  when datepart(dd,Getdate()) = 1 then dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0)) else Getdate() end)
	  and exists (select * from(select distinct max([Период_След]) over(partition by [ЗаявкаСсылка_Исх]) as [Период_След],[ЗаявкаСсылка_Исх] 
								from [dwh_new].[dbo].[mt_requests_transition_mfo]) t1 
								where tt0.[ЗаявкаСсылка_Исх]=t1.[ЗаявкаСсылка_Исх] and tt0.[Период_След]=t1.[Период_След]) 



drop table if exists #t_time
select min([Период_Исх]) over(partition by [ЗаявкаСсылка_Исх] ,[СтатусДляСостояния]) as [Период_Исх_Мин] 
	  ,max([Период_Исх]) over(partition by [ЗаявкаСсылка_Исх] ,[СтатусДляСостояния]) as [Период_Исх_Макс]
	  ,[ЗаявкаСсылка_Исх] --= (select [ЗаявкаСсылка_Исх] from t1)
	  ,[СтатусДляСостояния]

into #t_time

from [dwh_new].[dbo].[mt_requests_transition_mfo] with (nolock)
where [ЗаявкаСсылка_Исх] in (select [ЗаявкаСсылка_Исх] from #t1)

--select * from t_time


------------------время прихода на статус
drop table if exists #mintime

select [Период_Исх] as [Период_Исх_Мин] ,[ЗаявкаНомер_Исх] ,[ЗаявкаСсылка_Исх] ,[СтатусДляСостояния] ,[СтатусНаим_След] 

into #mintime

from [dwh_new].[dbo].[mt_requests_transition_mfo] rt with (nolock)
where exists  (select [Период_Исх_Мин] 
					 ,[ЗаявкаСсылка_Исх] 
			   from #t_time t_time
			   where rt.[Период_Исх]=t_time.[Период_Исх_Мин] and  rt.[ЗаявкаСсылка_Исх]=t_time.[ЗаявкаСсылка_Исх] and rt.[СтатусДляСостояния]=t_time.[СтатусДляСостояния])


--------время ухода из статусф
drop table if exists #maxtime
select [Период_Исх] as [Период_Исх_Макс] ,[ЗаявкаНомер_Исх] ,[ЗаявкаСсылка_Исх] ,[СтатусДляСостояния] ,[СтатусНаим_След] ,[Период_След] as [Период_След_Макс] 

into #maxtime
from [dwh_new].[dbo].[mt_requests_transition_mfo] rt with (nolock) 
where exists  (select [Период_Исх_Макс], [ЗаявкаСсылка_Исх] 
			   from #t_time t_time
			   where rt.[Период_Исх]=t_time.[Период_Исх_Макс] and  rt.[ЗаявкаСсылка_Исх]=t_time.[ЗаявкаСсылка_Исх] and rt.[СтатусДляСостояния]=t_time.[СтатусДляСостояния])



drop table if exists #t2

select  p.[ИсполнительНаим_Исх] as [ИсполнительНаим_След]	--[ИсполнительНаим_След] 
		,p.[ЗаявкаНомер_Исх] as [НомерЗаявки] ,p.[ЗаявкаСсылка_Исх] ,r.[ЗаявкаДатаОперации] as [ДатаЗаявки]
		,(r.[Фамилия]+' '+r.[Имя]+' '+r.[Отчество]) as [ФИОКлиента]
		,convert(nvarchar,mn.[Период_Исх_Мин],108) as [ВремяНаКД]
		,mn.[Период_Исх_Мин] as [Период_Исх] 
		,p.[СтатусНаим_Исх] 
		,p.[Период_Исх] as [Период_Отложено] ,p.[СтатусНаим_Исх] as [Статус_Отложено] 
		,p.[Период_След] as [Период_Восстановлено] 
		,p.[СтатусНаим_След] as [Статус_Восстановлено]
		,datediff(mi,p.[Период_Исх],p.[Период_След]) as [ПродолжОтложено]
		--,(datediff(day,p.[Период_Исх],p.[Период_След])*60*9) as [ПродолжОтложено2]
		--,(datediff(mi,p.[Период_Исх],p.[Период_След]) - datediff(day,p.[Период_Исх],p.[Период_След])*60*9) as [ПродолжОтложено0]
		--,isnull([P_lag_2], getdate()) as [ПериодПослеВосстановления]
		,mx.[Период_След_Макс] as [ПериодПослеВосстановления] 
		--,isnull([lag_2],N'Не восстановлено') as [СтатусПослеВосстановления] 
		,mx.[СтатусНаим_След] as [СтатусПослеВосстановления] 
		,[ПричинаНаим_Исх] as [ОтложеноПричина]
		,r.[МестоСоздЗаявки]
		,r.[ЗаявкаТочка] 
	  ,p.[СостояниеЗаявки]
	  ,p.[СтатусДляСостояния]

into #t2

from #t1 p
left join #mintime mn with (nolock)
	on p.[ЗаявкаСсылка_Исх]=mn.[ЗаявкаСсылка_Исх] and p.[СтатусДляСостояния]=mn.[СтатусДляСостояния] --and p.[Период_Исх]=mn.[Период_Исх_Мин] 
left join #maxtime mx with (nolock)
	on p.[ЗаявкаСсылка_Исх]=mx.[ЗаявкаСсылка_Исх] and p.[СтатусДляСостояния]=mx.[СтатусДляСостояния] --and p.[Период_Исх]=mn.[Период_Исх_Мин] 
left join [dwh_new].[dbo].[mt_requests_loans_mfo] r with (nolock)
	on p.[ЗаявкаСсылка_Исх]=r.[ЗаявкаСсылка]

--where --not datepart(HH, [Период_След]) in (22 ,23 ,0 ,1 ,2 ,3 ,4 ,5 ,6 ,7)	--p.[ЗаявкаСсылка_Исх] in (select [ЗаявкаСсылка_Исх] from [dwh_new].[dbo].[mt_requests_loans_mfo] where  [СтатусДляСостояния]=N'Контроль данных' and [СостояниеЗаявки] = N'Отложено' )
--		--and 
--		[Период_След] between (case  when datepart(dd,Getdate()) = 1 then dateadd(MONTH,datediff(MONTH,0,dateadd(day,-1,Getdate())),0) else  dateadd(MONTH,datediff(MONTH,0,Getdate()),0) end)
--							and (case  when datepart(dd,Getdate()) = 1 then dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0)) else Getdate() end)
--order by p.[Период_Исх] desc
--)


if @pageNo =1

select distinct 
		[ИсполнительНаим_След]
	    ,[НомерЗаявки] 
		,[ЗаявкаСсылка_Исх]
		,[ДатаЗаявки] ,[ФИОКлиента] 
		,[ОтложеноПричина]
		,[ВремяНаКД]

		,[Период_Исх] 
		,case when [Статус_Восстановлено]=N'Отложено рассмотрение' then N'Отложено рассмотрение' else [СтатусНаим_Исх] end as [СтатусНаим_Исх] 
		,[Период_Отложено] 
		,case when [Статус_Восстановлено]=N'Отложено рассмотрение' then N'Отложено рассмотрение' else [Статус_Отложено] end as [Статус_Отложено] 
		,[Период_Восстановлено] 
		,case when [Статус_Восстановлено]=N'Отложено рассмотрение' then N'НЕ восстановлено' else [СтатусНаим_Исх] end as [Статус_Восстановлено]
		,[ПродолжОтложено]

		,[ПериодПослеВосстановления] 

		,case when [Статус_Восстановлено]=N'Отложено рассмотрение' then N'НЕ восстановлено' else [СтатусПослеВосстановления] end as [СтатусПослеВосстановления]
		
		,[МестоСоздЗаявки]
		,[ЗаявкаТочка]  	  
		,[СостояниеЗаявки]
	  ,[СтатусДляСостояния]
from #t2 
--where --[НомерЗаявки]=N'19102400000106'--[ИсполнительНаим_Исх] <> N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ' --and
order by [НомерЗаявки] desc ,[Период_Отложено] desc




if @pageNo =2

with t0 as
(
select [ЗаявкаНомер_Исх] ,[ЗаявкаСсылка_Исх] ,[СостояниеЗаявки] ,[СтатусДляСостояния]  ,[Период_Исх]
	  --,datepart(hh,[Период_Исх]) as [ВремяСтатусаВх]
      ,[СтатусНаим_Исх] ,[Период_След] ,[СтатусНаим_След]
	  ,[ИсполнительНаим_Исх] ,[ИсполнительНаим_След]
	  ,[ПричинаНаим_Исх] ,[ПричинаНаим_След]
      ,case when not [ПричинаНаим_Исх] is null then [ПричинаНаим_Исх] when [ПричинаНаим_Исх] is null and not [ПричинаНаим_След] is null then [ПричинаНаим_След] end as [ПричинаНаим_След2] 

from [dwh_new].[dbo].[mt_requests_transition_mfo] with (nolock) 
where [СостояниеЗаявки]=N'Отложено' and [СтатусДляСостояния]=N'Контроль данных' and 
	  [ИсполнительНаим_Исх] <> N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ' and
	  [Период_След] between (case  when datepart(dd,Getdate()) = 1 then dateadd(MONTH,datediff(MONTH,0,dateadd(day,-1,Getdate())),0) else  dateadd(MONTH,datediff(MONTH,0,Getdate()),0) end)
							and (case  when datepart(dd,Getdate()) = 1 then dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0)) else Getdate() end)

union all

--------------------------- добавим заявки на момент формирования отчета в отложенном состоянии

select [ЗаявкаНомер_Исх] ,[ЗаявкаСсылка_Исх] ,[СостояниеЗаявки] ,[СтатусДляСостояния]  
	  ,[Период_Исх] ,[СтатусНаим_Исх] ,[Период_След] ,[СтатусНаим_След]
	  ,[ИсполнительНаим_След] as [ИсполнительНаим_Исх] ,N'' as [ИсполнительНаим_След]
	  ,[ПричинаНаим_След] as [ПричинаНаим_Исх] ,N'' as [ПричинаНаим_След]
	  ,case when not [ПричинаНаим_Исх] is null then [ПричинаНаим_Исх] when [ПричинаНаим_Исх] is null and not [ПричинаНаим_След] is null then [ПричинаНаим_След] end as [ПричинаНаим_След2] 

from [dwh_new].[dbo].[mt_requests_transition_mfo] tt0 with (nolock) 
where [СтатусДляСостояния]=N'Контроль данных' and [СтатусНаим_След]=N'Отложено рассмотрение'
	  and [ИсполнительНаим_След] <> N'РЕГЛАМЕНТ РЕГЛАМЕНТ РЕГЛАМЕНТ' --
	  and  [Период_След] between (case  when datepart(dd,Getdate()) = 1 then dateadd(MONTH,datediff(MONTH,0,dateadd(day,-1,Getdate())),0) else  dateadd(MONTH,datediff(MONTH,0,Getdate()),0) end)
							and (case  when datepart(dd,Getdate()) = 1 then dateadd(SECOND,-1,dateadd(day,datediff(day,0,Getdate()),0)) else Getdate() end)
	  and exists (select * from(select distinct max([Период_След]) over(partition by [ЗаявкаСсылка_Исх]) as [Период_След],[ЗаявкаСсылка_Исх] 
								from [dwh_new].[dbo].[mt_requests_transition_mfo]) t1 
								where tt0.[ЗаявкаСсылка_Исх]=t1.[ЗаявкаСсылка_Исх] and tt0.[Период_След]=t1.[Период_След]) 
)

,	t_end as
(
select p.[ЗаявкаНомер_Исх] as [НомерЗаявки] ,p.[ЗаявкаСсылка_Исх] ,r.[ЗаявкаДатаОперации] as [ДатаЗаявки] 

		,[Период_Исх] as [Период_Отложено]	--[Период_След] as [Период_Отложено]

		,[ПричинаНаим_След] as [ОтложеноПричина]

		,c.[Комментарий] as [КомментарииКЗаявке]
	    ,dateadd(year,-2000,cast(c.[Период] as datetime2)) as [ДатаКомментария]
from (select distinct [ЗаявкаНомер_Исх] ,[ЗаявкаСсылка_Исх] , [Период_Исх] --,[Период_След] 
			,[ПричинаНаим_След2] as [ПричинаНаим_След] 
	  from t0) p
left join [dwh_new].[dbo].[mt_requests_loans_mfo] r with (nolock)
	on p.[ЗаявкаСсылка_Исх]=r.[ЗаявкаСсылка]
left join [Stg].[dbo].[aux_ListCommentRequestMFO_1c] c with (nolock)
	on p.[ЗаявкаСсылка_Исх] = c.[Заявка] 
		and p.[Период_Исх] >= dateadd(year,-2000,cast(c.[Период] as datetime2)	--and p.[Период_След] >= dateadd(year,-2000,cast(c.[Период] as datetime2)
		) 
)
,	t_end2 as
(
select distinct t.[НомерЗаявки] ,t.[ДатаЗаявки]  ,t.[Период_Отложено] ,t.[ОтложеноПричина] ,t.[КомментарииКЗаявке] ,t.[ДатаКомментария]
from t_end t
where not t.[КомментарииКЗаявке]=N''
)
select * from t_end2
order by [НомерЗаявки] desc , [Период_Отложено] desc ,[ДатаКомментария] desc



if @pageNo = 3

select distinct 
		[ИсполнительНаим_След]
	    ,[НомерЗаявки] 
		,[ЗаявкаСсылка_Исх]
		,[ДатаЗаявки] ,[ФИОКлиента] 
		,[ОтложеноПричина]
		,[ВремяНаКД]

		,[Период_Исх] 
		,case when [Статус_Восстановлено]=N'Отложено рассмотрение' then N'Отложено рассмотрение' else [СтатусНаим_Исх] end as [СтатусНаим_Исх] 
		,[Период_Отложено] 
		,case when [Статус_Восстановлено]=N'Отложено рассмотрение' then N'Отложено рассмотрение' else [Статус_Отложено] end as [Статус_Отложено] 
		,[Период_Восстановлено] 
		,case when [Статус_Восстановлено]=N'Отложено рассмотрение' then N'НЕ восстановлено' else [СтатусНаим_Исх] end as [Статус_Восстановлено]
		,[ПродолжОтложено]

		,[ПериодПослеВосстановления] 

		,case when [Статус_Восстановлено]=N'Отложено рассмотрение' then N'НЕ восстановлено' else [СтатусПослеВосстановления] end as [СтатусПослеВосстановления]
		
		,[МестоСоздЗаявки]
		,[ЗаявкаТочка]  	  
		,[СостояниеЗаявки]
	  ,[СтатусДляСостояния]
from #t2 
where [НомерЗаявки] in (select * from #dokred)
order by [НомерЗаявки] desc ,[Период_Отложено] desc


END
