--DWH-1184
CREATE PROC [dbo].[report_ContactData_for_fedresurs]
as
begin
	select 
	ac.agentName
	,ac.agentFullName
	,ac.stDate
	,ac.endDate
	,agent_reestr  = ac.reestr
	,IsRfCitizen= iif(Партнер.Гражданство = 0x80FA00155D2C1F0D11E783EFD780D669, 1, 0) --РОССИЯ

	,LastName= COALESCE(NULLIF(Партнер.CRM_Фамилия,'') ,Договор.Фамилия )
	,FirstName= COALESCE(NULLIF(Партнер.CRM_Имя,''), Договор.Имя)
	,MiddleName= COALESCE(NULLIF(Партнер.CRM_Отчество,''), Договор.Отчество)

	,DateOfBirth = cast(iif(year(Партнер.[ДатаРождения])>3000, dateadd(year, -2000, Партнер.[ДатаРождения]), Партнер.[ДатаРождения]) as date)
	,Inn = inn.ИНН
	,PassportSeries =	COALESCE(nullif(Договор.ПаспортСерия,''), z.СерияПаспорта)
	,PassportNumber =	COALESCE(nullif(Договор.ПаспортНомер,''), z.НомерПаспорта)
	,PassportIssueDate = COALESCE(
		iif(year(Договор.ПаспортДатаВыдачи)>3000, dateadd(year,-2000,Договор.ПаспортДатаВыдачи), null),
		iif(year(z.ДатаВыдачиПаспорта)>3000, dateadd(year, - 2000, z.ДатаВыдачиПаспорта), null)) 


	,ContactUic = dwh_new.dbo.[getGUIDFrom1C_IDRREF](Договор.Ссылка)
	,ContactDate = cast(iif(year(Договор.Дата)>3000, dateadd(year, -2000, Договор.Дата), Договор.Дата) as date)
	,ContractNumber = ac.external_id
	,Status = (case when ac.endDate >= cast(getdate() as date) then 'Договор передан в КА' else 'Договор отозван из КА' end) 

	from dwh_new.dbo.v_agent_credits_with_client_only_changed ac
	inner join stg._1ccmr.Справочник_Договоры Договор on Договор.Код = ac.external_id
	inner join stg.[_1cCRM].[Справочник_Партнеры] Партнер on Договор.Клиент= Партнер.Ссылка

	--left join dwh2.dm.реестр_ИНН_клиентов inn on inn.guid = ac.crmClientGuid
	--	--and inn.external_id = ac.external_id
	--DWH-2506
	LEFT JOIN dwh2.dm.v_Клиент_ИНН AS inn
		ON inn.GuidКлиент = ac.crmClientGuid
	--	AND inn.nRow = 1

	left join stg._1cmfo.документ_ГП_заявка z on ac.external_id=z.номер
	
	where 1=1
	order by Status
end 

