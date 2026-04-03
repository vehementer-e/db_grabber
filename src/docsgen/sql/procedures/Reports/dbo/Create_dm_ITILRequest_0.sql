
--exec [dbo].[Create_dm_RequestsApproved]

CREATE   procedure [dbo].[Create_dm_ITILRequest_0] 
as
begin

set nocount on
 --return


drop table if exists #employee
select   
	  [Ссылка] id
      ,[Наименование] Employee
into #employee
from [Stg].[_1cItil].[Справочник_Пользователи]



drop table if exists #doc_itilprofIncident

select --top(10000)
	  dd.[Ссылка]
      ,dd.[ПометкаУдаления]
	  ,cast(dateadd(year,-2000, cast(dd.[Дата] as datetime2)) as datetime) [dt_open]
	  --, cast(dd.[Дата] as datetime2) as [Дата]
      --,cast(dateadd(year,-2000, cast(dd.[Дата] as datetime2))) as [Дата]
      ,[Номер]
		,case
			when dd.[КрайнийСрокУстраненияSLA] = '2001-01-01'
				then dd.[КрайнийСрокУстраненияSLA]
			else cast(dateadd(year,-2000, cast(dd.[КрайнийСрокУстраненияSLA] as datetime2)) as datetime) 
		end as dt_sla0 --[КрайнийСрокУстраненияSLA]
		,case
			when dd.[ДатаЗавершения] = '2001-01-01'
				then dateadd(second,-1,dateadd(year,datediff(year,0,dateadd(year,1,Getdate())),0)) -- сделал конец этого года --dd.[ДатаЗавершения]
			else cast(dateadd(year,-2000, cast(dd.[ДатаЗавершения] as datetime2)) as datetime) 
		end as dt_close0 --[ДатаЗавершения]

		,case
			when dd.[КрайнийСрокУстраненияSLA] <> '2001-01-01'
				then cast(dateadd(year,-2000, cast(dd.[КрайнийСрокУстраненияSLA] as datetime2)) as datetime) 
		end as dt_sla --[КрайнийСрокУстраненияSLA]
		,case
			when dd.[ДатаЗавершения] <> '2001-01-01'
				then cast(dateadd(year,-2000, cast(dd.[ДатаЗавершения] as datetime2)) as datetime) 
		end as dt_close --[ДатаЗавершения]

		,employee
		,o.[Представление] as [ТипОбращения]
		,dd.[ГруппаПользователей_Строка] as [ГруппаПользователей]
		,[ЭтоГоловнойДокумент]

into #doc_itilprofIncident -- select *
from stg.[_1cItil].[Документ_itilprofИнциденты] dd
left join #employee e on dd.[ТекущийИсполнитель_Ссылка]=e.id
left join stg.[_1cItil].[Перечисление_ТипОбращения] o on dd.[ТипОбращения]=o.[Ссылка] 
where dd.[ПометкаУдаления] = 0x00 and cast(dd.[Дата] as date) >= dateadd(year,2000, dateadd(year,datediff(year,0,Getdate()),0))


drop table if exists #add_requst
select distinct
		r.[Номер] old_N
		,r.[dt_open] old_dt
		,c.[Номер]
		,c.[dt_open] 
into #add_requst
from dbo.dm_ITILRequest r
left join (select [Номер] ,[dt_open]  from #doc_itilprofIncident) c on r.[Номер]=c.[Номер] and r.[dt_open]=c.[dt_open]


delete from dbo.dm_ITILRequest where [Номер] in (select [Номер] from #add_requst where not [Номер] is null)


insert into dbo.dm_ITILRequest (
										[Ссылка]
										,[ПометкаУдаления]
										,[dt_open]
										,[Номер]
										,[dt_sla0]
										,[dt_close0]
										,[dt_sla]
										,[dt_close]
										,[employee]
										,[ТипОбращения]
										,[ГруппаПользователей]
										,[ЭтоГоловнойДокумент])
select * 
--into dbo.dm_ITILRequest
from #doc_itilprofIncident
	

end
