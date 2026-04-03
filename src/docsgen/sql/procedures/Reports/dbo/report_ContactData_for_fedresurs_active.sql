--DWH-1184
CREATE   PROC  [dbo].[report_ContactData_for_fedresurs_active]
as
begin
DECLARE @d_Balance DATE

SELECT @d_Balance = max(a.d)
FROM (
	SELECT b.d, cnt = count(*)
	FROM Reports.dbo.dm_CMRStatBalance_2 as b
	WHERE b.d > cast(dateadd(day, -3, getdate()) as date)
	GROUP BY b.d
	HAVING count(*) > 1000
) AS A

SELECT
	  is_active_today	=	b.external_id 
	,						credit_agents.agentName
	,						credit_agents.agentFullName
	,						credit_agents.stDate
	,						credit_agents.endDate
	, agent_reestr		=	credit_agents.reestr
	, IsRfCitizen		=	iif(Гражданство.Наименование = 'РОССИЯ', 1, 0)
	, LastName			=	COALESCE(NULLIF(Клиенты.Фамилия,'') ,Договор.Фамилия )
	, FirstName			=	COALESCE(NULLIF(Клиенты.Имя,''), Договор.Имя)
	, MiddleName		=	COALESCE(NULLIF(Клиенты.Отчество,''), Договор.Отчество)
 	, DateOfBirth		=	cast(Клиенты.[ДатаРождения] as date)
 	, Inn				=	inn.ИНН
 	, PassportSeries	=	COALESCE(nullif(Паспорт.Серия,''), Заявка.[Серия Паспорта])
 	, PassportNumber	=	COALESCE(nullif(Паспорт.Номер,''), Заявка.[Номер Паспорта])
 	, PassportIssueDate =	cast(Паспорт.ДатаВыдачи as date)
	, ContactUic		=	Договор.УникальныйИдентификаторОбъектаБКИ
	, ContactDate		=	cast(Договор.ДатаДоговораЗайма as date)
	, ContractNumber	=	credit_agents.external_id
	, Status			=	(CASE WHEN credit_agents.endDate >= cast(getdate() as date) THEN 'Договор передан в КА' ELSE 'Договор отозван из КА' END) 

FROM		dwh_new.dbo.[v_agent_credits_with_client] credit_agents
INNER JOIN	dwh2.hub.ДоговорЗайма Договор							ON credit_agents.external_id		= Договор.КодДоговораЗайма
INNER JOIN  dwh2.link.Клиент_ДоговорЗайма Линк_ДоговорЗайма			ON Линк_ДоговорЗайма.КодДоговораЗайма			= Договор.КодДоговораЗайма
INNER JOIN	dwh2.hub.Клиенты Клиенты								ON Клиенты.GuidКлиент				= credit_agents.crmClientGuid AND
														   				Клиенты.GuidКлиент				= Линк_ДоговорЗайма.GuidКлиент
LEFT JOIN	Reports.dbo.dm_CMRStatBalance_2 b						ON credit_agents.external_id		= b.external_id AND 
														   				b.d								= @d_Balance
left JOIN	dwh2.sat.Клиент_ПаспортныеДанные Паспорт				ON Клиенты.GuidКлиент				= Паспорт.GuidКлиент
LEFT JOIN	[dwh2].[hub].[Заявка] Заявка							ON Заявка.НомерЗаявки				= Договор.КодДоговораЗайма
LEFT JOIN	[dwh2].[sat].Клиент_Гражданство	Гражданство				ON Гражданство.GuidКлиент			= Клиенты.GuidКлиент
LEFT JOIN dwh2.dm.v_Клиент_ИНН AS inn ON inn.GuidКлиент	= credit_agents.crmClientGuid 
	
WHERE b.external_id is not null AND
	  credit_agents.endDate > getdate()
ORDER BY Status

end