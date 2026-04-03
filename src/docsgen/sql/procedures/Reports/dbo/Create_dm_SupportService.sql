
-- exec [dbo].[Create_dm_SupportService]

CREATE  PROCEDURE  [dbo].[Create_dm_SupportService] 
AS
BEGIN
	SET NOCOUNT ON;


declare @GetDate2000 datetime

set @GetDate2000 = dateadd(year,2000,getdate());


drop table if exists #employee
select   
	  [Ссылка] id
      ,[Наименование] Employee
into #employee
from [Stg].[_1cItil].[Справочник_Пользователи]


drop table if exists #Performer
select		
		i.[Ссылка] as [ИнцидентСсылка]
		,i.[Дата]
		,i.[Номер]
		,i.[НомерОбращения]
		,i.[Проведен]
		,i.[Наименование] as [ТемаОбращения]
		,e2.employee as [Инициатор]

		,st.[Код] as [Этап]

		,s.[Наименование] as [Услуга]
		,i.[КрайнийСрокУстраненияSLA]
		,i.[ДатаСоздания]
		,p.[МоментПередачи]
		,i.[ДатаЗавершения]

		
		,e.Employee as [Сотрудник]
		,i.[ГруппаПользователей_Строка] as [ГруппаПользователей]
		,o.[Представление] as [ТипОбращения]

into #Performer -- select *
from [Stg].[_1cItil].[Документ_itilprofИнциденты_Исполнители] p

left join #employee e on p.[Исполнитель_Ссылка]=e.id

left join stg.[_1cItil].[Документ_itilprofИнциденты] i on p.[Ссылка]=i.[Ссылка]
left join #employee e2 on i.[Инициатор]=e2.id
left join stg.[_1cItil].[Перечисление_ТипОбращения] o on i.[ТипОбращения]=o.[Ссылка]
left join stg.[_1cItil].[Справочник_itilprofКаталогУслуг] s on i.[Услуга]=s.[Ссылка] 
left join stg.[_1cItil].[Справочник_itilprofЭтапыМаршрутов] st on p.[Этап]=st.[Ссылка] 

where not i.[Ссылка] is null 
		--and i.[Дата] >= dateadd(month,-2,dateadd(day,datediff(day,0,@GetDate2000),0)) and i.[Дата] <= @GetDate2000

--select * from #Performer order by 2 desc


begin tran

  delete from [dbo].[dm_SupportService] -- where [Дата] >= select dateadd(month,-2,dateadd(day,datediff(day,0,getdate()),0))

  insert into [dbo].[dm_SupportService] ([Дата] ,[Номер] ,[НомерОбращения] ,[Проведен] ,[ТемаОбращения] ,[Инициатор] 
													,[Этап] ,[Услуга] ,[КрайнийСрокУстраненияSLA] ,[ДатаСоздания] ,[МоментПередачи] 
													,[ДатаЗавершения] ,[Сотрудник] ,[ГруппаПользователей] ,[ТипОбращения])

  select [Дата] ,[Номер] ,[НомерОбращения] ,[Проведен] ,[ТемаОбращения] ,[Инициатор] 
		 ,[Этап] ,[Услуга] ,[КрайнийСрокУстраненияSLA] ,[ДатаСоздания] ,[МоментПередачи] 
		 ,[ДатаЗавершения] ,[Сотрудник] ,[ГруппаПользователей] ,[ТипОбращения] 

  from #Performer
  

  commit tran


END
