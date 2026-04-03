--[dbo].[reports_Отчет_по_статусам_заявки_new]  @date = '2025-08-01', @ClientRequestNumber = '23120921520916',
CREATE PROC dbo.reports_Отчет_по_статусам_заявки_new
	@date date = null,
	@ClientRequestNumber varchar(255) = NULL,
	@isDebug int = 0
as
BEGIN
	SELECT @isDebug = isnull(@isDebug, 0)
	set @date  = isnull(@date, 
		dateadd(dd, -1, getdate()))
	set @ClientRequestNumber = nullif(@ClientRequestNumber, '')
	DROP TABLE IF EXISTS #t_ClientRequest
	CREATE TABLE #t_ClientRequest
	(
		IdClientRequest uniqueidentifier, 
		Number nvarchar(255),
		RequestDate smalldatetime,
		ClientName nvarchar(1000),
		CreditProductType varchar(50),
		IdCreditProduct int,
		IsDocumentalVerification bit,
		ProductSubTypeId	int
	)

	INSERT #t_ClientRequest
	(
		IdClientRequest, 
		Number,
		RequestDate,
		ClientName,
		CreditProductType,
		IdCreditProduct,
		IsDocumentalVerification,
		ProductSubTypeId
	)
	SELECT DISTINCT
		IdClientRequest = cr.Id,
		cr.Number COLLATE Cyrillic_General_CI_AS,
		RequestDate = cast(dateadd(HOUR, 3, cr.CreatedRequestDate) as smalldatetime) , --[Дата заявки]
		ClientName = concat_ws(' '
				, isnull(cr.ClientLastName  , cr_ci.LastName)
				, isnull(cr.ClientFirstName , cr_ci.FirstName)
				, isnull(cr.ClientMiddleName, cr_ci.MiddleName)
				) COLLATE Cyrillic_General_CI_AS, --[ФИО Клиента]
		-- @changelog 17.10-2025 | dwh-320 | Поправил источник поля тип продукта
		CreditProductType = pt.[Name] COLLATE Cyrillic_General_CI_AS, --[Тип продукта]
		cr.IdCreditProduct,
		cr.IsDocumentalVerification,
		cr.ProductSubTypeId --ПодТип продукта

		
	FROM 
		Stg._fedor.core_ClientRequest AS cr
		LEFT JOIN Stg._fedor.core_ClientRequestClientInfo cr_ci on cr.Id=cr_ci.Id
		LEFT JOIN Stg._fedor.dictionary_ProductType AS pt ON pt.Id = cr.ProductTypeId
		
	WHERE cr.CreatedRequestDate >= @date
	and (cr.Number = @ClientRequestNumber or @ClientRequestNumber is null)
	and (	COALESCE(cr.ClientFirstName, cr_ci.FirstName, '') not like 'Тест%'  COLLATE Cyrillic_General_CI_AS
	and COALESCE(cr.ClientMiddleName, cr_ci.MiddleName, '') not like 'Тест%' COLLATE Cyrillic_General_CI_AS
	and COALESCE(cr.ClientLastName, cr_ci.LastName, '')<>'ТЕСТОВАЯ' COLLATE Cyrillic_General_CI_AS)
	CREATE clustered INDEX cix ON #t_ClientRequest(IdClientRequest)
	CREATE INDEX ix_Number ON #t_ClientRequest(Number)
	
	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ClientRequest_1
		SELECT * INTO ##t_ClientRequest_1 FROM #t_ClientRequest
	END

	DROP TABLE IF EXISTS #t_except1
	CREATE TABLE #t_except1(Number nvarchar(255))

	/*
	6 октября 2023 г. 11:21
	если в ClientRequestHistory есть записи для данной заявки 
	со значением IdClientRequestStatus=5(это отказ), 
	но без значения IdClientRequestStatus=3(Пред одобр), 
	то значит на такой заявке был отказ до КД
	*/
	INSERT #t_except1(Number)
	SELECT DISTINCT R.Number
	FROM #t_ClientRequest AS R
		INNER JOIN Stg._fedor.core_ClientRequestHistory AS H5
			ON H5.IdClientRequest = R.IdClientRequest
			AND H5.IdClientRequestStatus = 5
			and H5.IsDeleted = 0
		LEFT JOIN Stg._fedor.core_ClientRequestHistory AS H3
			ON H3.IdClientRequest = R.IdClientRequest
			AND H3.IdClientRequestStatus = 3
			and H3.IsDeleted = 0
	WHERE H3.IdClientRequest IS NULL

	CREATE INDEX ix ON #t_except1(Number)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_except1
		SELECT * INTO ##t_except1 FROM #t_except1
	END

	DELETE R
	FROM #t_ClientRequest AS R
		INNER JOIN #t_except1 AS E ON E.Number = R.Number

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ClientRequest_2
		SELECT * INTO ##t_ClientRequest_2 FROM #t_ClientRequest
	END

	drop table if exists #t_ClientRequestStatusDate
	select crh.IdClientRequest,
		RequestStatusDate = dateadd(HOUR, 3, crh.CreatedOn),
		crh.IdClientRequestStatus,
		RequestStatusName = crs.Name COLLATE Cyrillic_General_CI_AS,
		user_fio = concat(u.LastName, ' ', u.FirstName, ' ', u.MiddleName) COLLATE Cyrillic_General_CI_AS
	into #t_ClientRequestStatusDate
	from (
		SELECT 
			last_statusDate = max(H.CreatedOn)
			,H.IdClientRequest 
			,H.IdClientRequestStatus
		FROM  Stg._fedor.core_ClientRequestHistory AS H
		WHERE h.[IsDeleted] = 0
		and 
		EXISTS(SELECT TOP(1) 1 FROM #t_ClientRequest AS R WHERE R.IdClientRequest = H.IdClientRequest) --01.08 вернул условие
			
		GROUP by H.IdClientRequest, IdClientRequestStatus
	) AS last_status_date
	inner join stg._fedor.core_ClientRequestHistory crh 
		ON crh.IdClientRequest = last_status_date.IdClientRequest
		and last_status_date.last_statusDate = crh.CreatedOn
		and last_status_date.IdClientRequestStatus = crh.IdClientRequestStatus
		and crh.[IsDeleted] = 0
	inner join stg._fedor.dictionary_ClientRequestStatus crs on crs.Id = crh.IdClientRequestStatus
	inner join [stg].[_fedor].[core_user] u WITH(NOLOCK) ON u.Id = crh.IdOwner
	where 1=1
	and crs.Name not in(
	'Аннулировано'
	,'предварительное одобрение'
	,'черновик'
	,'Ожидание подписи документов EDO')
	
	
	 
	create clustered index cix  on #t_ClientRequestStatusDate(IdClientRequest)
	create  index ix_IdClientRequest_RequestStatusDate  on #t_ClientRequestStatusDate(IdClientRequest, RequestStatusDate)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ClientRequestStatusDate
		SELECT * INTO ##t_ClientRequestStatusDate FROM #t_ClientRequestStatusDate
	END

	drop table if exists #t_checklists_rejects
	;with loginom_checklists_rejects AS(
		SELECT 
			min(try_cast(replace(cis.LoginomNumber,'.','') AS bigint))  logn,
			cli.IdClientRequest
		FROM
			[Stg].[_fedor].[core_CheckListItem] cli 
			inner JOIN [Stg].[_fedor].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
				--and cis.[IdBehavior] =2 --	Статус - хард-код, по которому откажет логином
				and cis.[IdBehavior] IN (2, 3) -- 3. В информацию по Check* выводим информацию если по заявке был отказа, не важно кем системой или верификатором
		WHERE EXISTS(SELECT TOP(1) 1 FROM #t_ClientRequest AS R WHERE R.IdClientRequest = cli.IdClientRequest)
		GROUP BY cli.IdClientRequest
	)
	SELECT 
	cli.IdClientRequest,
	cit.[Name] CheckListItemTypeName,
	cis.[Name] CheckListItemStatusName
	into #t_checklists_rejects
	FROM [Stg].[_fedor].[core_CheckListItem] cli
		JOIN [Stg].[_fedor].[dictionary_CheckListItemType] cit ON  cit.id = cli.IdType
		JOIN [Stg].[_fedor].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
		JOIN loginom_checklists_rejects rl ON rl.IdClientRequest = cli.IdClientRequest 
			AND try_cast(replace(cis.LoginomNumber,'.','') AS bigint) = rl.logn
	WHERE EXISTS(SELECT TOP(1) 1 FROM #t_ClientRequest AS R WHERE R.IdClientRequest = cli.IdClientRequest)

	create clustered index ix  on #t_checklists_rejects(	IdClientRequest)
	
	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_checklists_rejects
		SELECT * INTO ##t_checklists_rejects FROM #t_checklists_rejects
	END

	drop table if exists #t_clientVerification
	SELECT 
		t.IdClientRequest
		,status
		,fio
		,status_date
	into #t_clientVerification
	FROM
	(SELECT
		  R.IdClientRequest
		  --number = V.[Номер заявки] COLLATE Cyrillic_General_CI_AS
		  ,status = V.[Статус]  
		  ,fio = V.[ФИО сотрудника верификации/чекер] COLLATE Cyrillic_General_CI_AS
		  ,status_date = V.[Дата статуса] 
		  ,rn = row_number() OVER (PARTITION BY V.[Номер заявки], V.[Статус] ORDER BY V.[Дата статуса] DESC)
	  FROM [Reports].[dbo].[dm_FedorVerificationRequests] AS V
		INNER JOIN #t_ClientRequest AS R 
			ON R.Number = V.[Номер заявки] COLLATE Cyrillic_General_CI_AS
	  WHERE 1=1
		AND [Состояние заявки]   !='Статус изменен'
		and [Статус] in ('Контроль данных'
			, 'Верификация клиента'
			, 'Верификация ТС'
			, 'Одобрено'
			, 'Заем выдан'
			, 'Подтверждение дохода'
			, 'Проверка способа выдачи')

	/*
	  UNION
	  SELECT
		  R.IdClientRequest
		  --number = V.[Номер заявки] COLLATE Cyrillic_General_CI_AS
		  ,status = V.[Статус]  
		  ,fio = V.[ФИО сотрудника верификации/чекер] 
		  ,status_date = V.[Дата статуса]
		  ,rn = row_number() OVER (PARTITION BY V.[Номер заявки], V.[Статус] ORDER BY V.[Дата статуса] DESC)
	  FROM [Reports].[dbo].dm_FedorVerificationRequests_Installment AS V
		INNER JOIN #t_ClientRequest AS R 
			ON R.Number = V.[Номер заявки] COLLATE Cyrillic_General_CI_AS
	  WHERE 1=1
		AND [Состояние заявки]   !='Статус изменен'
		and [Статус] in ('Контроль данных'
			, 'Верификация клиента'
			, 'Верификация ТС'
			, 'Одобрено'
			, 'Заем выдан')
	union
	select 
		 R.IdClientRequest
		  --number = V.[Номер заявки] COLLATE Cyrillic_General_CI_AS
		  ,status = V.[Статус]  
		  ,fio = V.[ФИО сотрудника верификации/чекер] 
		  ,status_date = V.[Дата статуса]
		  ,rn = row_number() OVER (PARTITION BY V.[Номер заявки], V.[Статус] ORDER BY V.[Дата статуса] DESC)
		FROM [Reports].[dbo].dm_FedorVerificationRequests_PDL AS V
		INNER JOIN #t_ClientRequest AS R 
			ON R.Number = V.[Номер заявки] COLLATE Cyrillic_General_CI_AS
	  WHERE 1=1
		AND [Состояние заявки]   !='Статус изменен'
		and [Статус] in ('Контроль данных'
			, 'Верификация клиента'
			, 'Верификация ТС'
			, 'Одобрено'
			, 'Заем выдан')
	*/
	
	union
	select 
		 R.IdClientRequest
		  --number = V.[Номер заявки] COLLATE Cyrillic_General_CI_AS
		  ,status = V.[Статус]  
		  ,fio = V.[ФИО сотрудника верификации/чекер] 
		  ,status_date = V.[Дата статуса]
		  ,rn = row_number() OVER (PARTITION BY V.[Номер заявки], V.[Статус] ORDER BY V.[Дата статуса] DESC)
		FROM Reports.dbo.dm_FedorVerificationRequests_without_coll AS V
		INNER JOIN #t_ClientRequest AS R 
			ON R.Number = V.[Номер заявки] COLLATE Cyrillic_General_CI_AS
	  WHERE 1=1
		AND [Состояние заявки]   !='Статус изменен'
		and [Статус] in ('Контроль данных'
			, 'Верификация клиента'
			, 'Верификация ТС'
			, 'Одобрено'
			, 'Заем выдан'
			, 'Подтверждение дохода'
			, 'Проверка способа выдачи')

	--T_DWH-120
	union
	select 
			R.IdClientRequest
			--number = V.[Номер заявки] COLLATE Cyrillic_General_CI_AS
			,status = V.[Статус]  
			,fio = V.[ФИО сотрудника верификации/чекер] 
			,status_date = V.[Дата статуса]
			,rn = row_number() OVER (PARTITION BY V.[Номер заявки], V.[Статус] ORDER BY V.[Дата статуса] DESC)
		FROM Reports.dbo.dm_FedorVerificationRequests_AutocredVTB AS V
		INNER JOIN #t_ClientRequest AS R 
			ON R.Number = V.[Номер заявки] COLLATE Cyrillic_General_CI_AS
		WHERE 1=1
		AND [Состояние заявки]   !='Статус изменен'
		and [Статус] in ('Контроль данных'
			, 'Верификация клиента'
			, 'Верификация ТС'
			, 'Одобрено'
			, 'Заем выдан'
			)
	  ) t
	WHERE t.rn=1
	
	create clustered index cix on #t_clientVerification(IdClientRequest)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_clientVerification
		SELECT * INTO ##t_clientVerification FROM #t_clientVerification
	END


	drop table if exists #t_ClientRequestStatus
	select 
		t.IdClientRequest
		,t.RequestStatusDate
		,t.RequestStatusName
		,UserFio  = upper(isnull(cv.fio, t.user_fio))
	into #t_ClientRequestStatus
	from #t_ClientRequestStatusDate t
		left join #t_clientVerification cv on cv.IdClientRequest = t.IdClientRequest
			and cv.status = t.RequestStatusName --COLLATE Cyrillic_General_CI_AS
	where t.RequestStatusName in ('Контроль данных'
		, 'Верификация клиента'
		, 'Верификация ТС'
		, 'Одобрено'
		, 'Заем выдан'
		, 'Подтверждение дохода'
		, 'Проверка способа выдачи')


	--autoapprove_VK
	/*
	INSERT #t_ClientRequestStatus
	(
	    IdClientRequest,
		RequestStatusDate,
		RequestStatusName,
		UserFio
	)
	SELECT 
		t.IdClientRequest
		,t.status_date
		,t.status
		,t.fio
	FROM (
		SELECT
			  R.IdClientRequest
			  --number = [Номер заявки] COLLATE Cyrillic_General_CI_AS
			  ,status = 'autoapprove_VK' --[Статус]  
			  ,fio = [ФИО сотрудника верификации/чекер] 
			  ,status_date = [Дата статуса]
			  ,rn = row_number() OVER (PARTITION BY [Номер заявки],[Статус] ORDER BY [Дата статуса])
		  FROM Reports.dbo.dm_FedorVerificationRequests_Installment AS V
			INNER JOIN #t_ClientRequest AS R 
				ON R.Number = V.[Номер заявки] COLLATE Cyrillic_General_CI_AS
		  WHERE 1=1
			--AND (V.Статус IN ('Верификация Call 2') AND V.[Статус следующий] = 'Одобрено')
			AND V.Статус IN ('Верификация клиента') AND V.IsSkipped = 1 --DWH-2515
	  ) AS t
	WHERE t.rn=1

	INSERT #t_ClientRequestStatus
	(
	    IdClientRequest,
		RequestStatusDate,
		RequestStatusName,
		UserFio
	)
	SELECT 
		t.IdClientRequest
		,t.status_date
		,t.status
		,t.fio
	FROM (
		SELECT
			  R.IdClientRequest
			  --number = [Номер заявки] COLLATE Cyrillic_General_CI_AS
			  ,status = 'autoapprove_VK' --[Статус]  
			  ,fio = [ФИО сотрудника верификации/чекер] 
			  ,status_date = [Дата статуса]
			  ,rn = row_number() OVER (PARTITION BY [Номер заявки],[Статус] ORDER BY [Дата статуса])
		  FROM Reports.dbo.dm_FedorVerificationRequests_PDL AS V
			INNER JOIN #t_ClientRequest AS R 
				ON R.Number = V.[Номер заявки] COLLATE Cyrillic_General_CI_AS
		  WHERE 1=1
			--AND (V.Статус IN ('Верификация Call 2') AND V.[Статус следующий] = 'Одобрено')
			AND V.Статус IN ('Верификация клиента') AND V.IsSkipped = 1 --DWH-2515
	  ) AS t
	WHERE t.rn=1
	*/

	INSERT #t_ClientRequestStatus
	(
	    IdClientRequest,
		RequestStatusDate,
		RequestStatusName,
		UserFio
	)
	SELECT 
		t.IdClientRequest
		,t.status_date
		,t.status
		,t.fio
	FROM (
		SELECT
			  R.IdClientRequest
			  --number = [Номер заявки] COLLATE Cyrillic_General_CI_AS
			  ,status = 'autoapprove_VK' --[Статус]  
			  ,fio = [ФИО сотрудника верификации/чекер] 
			  ,status_date = [Дата статуса]
			  ,rn = row_number() OVER (PARTITION BY [Номер заявки],[Статус] ORDER BY [Дата статуса])
		  FROM Reports.dbo.dm_FedorVerificationRequests_without_coll AS V
			INNER JOIN #t_ClientRequest AS R 
				ON R.Number = V.[Номер заявки] COLLATE Cyrillic_General_CI_AS
		  WHERE 1=1
			--AND (V.Статус IN ('Верификация Call 2') AND V.[Статус следующий] = 'Одобрено')
			AND V.Статус IN ('Верификация клиента') AND V.IsSkipped = 1 --DWH-2515
	  ) AS t
	WHERE t.rn=1


	create clustered index cix on #t_ClientRequestStatus(IdClientRequest)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ClientRequestStatus
		SELECT * INTO ##t_ClientRequestStatus FROM #t_ClientRequestStatus
	END

	drop table if exists #t_client_type
	select number
		, client_type = client_type_for_sales
	into #t_client_type
	FROM dwh2.risk.applications s
	--from  dwh2.[dbo].[tvf_risk_apr_segment]() AS S
	 WHERE EXISTS(SELECT TOP(1) 1 FROM #t_ClientRequest AS R WHERE R.Number = S.number)

	CREATE CLUSTERED INDEX cix on #t_client_type(number)

	drop table if exists #t_lastClientRequestStatusDate
	select 
		t.IdClientRequest
		,t.RequestStatusDate
		,t.RequestStatusName
		into #t_lastClientRequestStatusDate
		from (select RequestStatusDate = max(t.RequestStatusDate)
		, t.IdClientRequest
		from #t_ClientRequestStatusDate  t
		group by IdClientRequest) last
		inner join #t_ClientRequestStatusDate t
			on t.IdClientRequest = last.IdClientRequest
			and t.RequestStatusDate  =last.RequestStatusDate
	
	create clustered index cix on #t_lastClientRequestStatusDate(IdClientRequest)

	--DWH-2914
	DROP TABLE IF EXISTS #t_partner

	SELECT
		R.IdClientRequest,
		partner_name = G.Name COLLATE Cyrillic_General_CI_AS -- Партнер
	INTO #t_partner
	FROM #t_ClientRequest AS R
		INNER JOIN Stg._fedor.core_ClientRequestAndLeadGenerator AS L
			ON L.ClientRequestId = R.IdClientRequest
		INNER JOIN Stg._fedor.dictionary_ConfigGeneralizedLeadGenerator AS C
			ON C.Id = L.ConfigGeneralizedLeadGeneratorId
		INNER JOIN Stg._fedor.dictionary_GeneralizedLeadGenerator AS G
			ON G.Id = C.GeneralizedLeadGeneratorId


	DROP TABLE IF EXISTS #t_Report

	select 
		R.Number, -- [Заявка]
		R.RequestDate, -- = cast(dateadd(HOUR, 3, cr.CreatedRequestDate) as smalldatetime) , --[Дата заявки]
		[finalStatusName] = last_clrs.RequestStatusName, --[Статус],
		--null as name,
		return_type = ct.client_type, --[return type]
		RequestStatusDate = cast(last_clrs.RequestStatusDate as smalldatetime), --[Момент Статуса]
		--ClientFirstName	
		R.ClientName, -- =concat(Cr.ClientLastName, ' ', Cr.ClientFirstName, ' ', Cr.ClientMiddleName),--[ФИО Клиента]
		
		CheckListItemTypeName = checklists_rejects.CheckListItemTypeName, --[Check List]
		CheckListItemStatusName = checklists_rejects.CheckListItemStatusName, --[Check List Status]
		oi.fpd30, --[fpd30]
		oi.fpd15, --[fpd30]
		oi.tpd0, --
		accepted_amount = cast(ЗаявкаНаЗаймПодПТС.Сумма as money), --[Одобренная сумма]
		amount = cast(oi.Amount as money), --[Сумма договора]
		CreditProductName = dic_cp.name, --[Продукт]
		R.CreditProductType, -- = 
			--CASE
			--	WHEN isnull(cr.Type, 0) = 4 THEN 'SmartInstallment'
			--	WHEN isnull(cr.IsInstallment, 0) = 1 OR isnull(cr.Type,0) = 2  THEN 'Installment'
			--	WHEN isnull(cr.IsProbation, 0) = 1 THEN 'Испытательный срок'
			--	WHEN isnull(cr.Type, 0) = 0 THEN 'ПТС'
			--	ELSE 'ПТС'
			--END, --[Тип продукта]
		kontrol_dannyh_date		= cast(crs_kd.RequestStatusDate as smalldatetime), --[Дата Контроль данных]
		kontrol_dannyh			= crs_kd.UserFio , --[Контроль данных]
		verifikaciya_klienta_date = cast(crs_vk.RequestStatusDate as smalldatetime),  --[Дата Верификация клиента]
		verifikaciya_klienta	= crs_vk.UserFio,  --[Верификация клиента]
		verifikaciya_ts_date	= cast(crs_vts.RequestStatusDate as smalldatetime),  --[Дата Верификация ТС]
		verifikaciya_ts			= crs_vts.UserFio,  --[Верификация ТС]
		odobreno_date			= cast(crs_od.RequestStatusDate  as smalldatetime), --[Дата Одобрено]
		odobreno				= crs_od.UserFio , --[Одобрено]
		vydan					= cast(crs_zv.RequestStatusDate  as smalldatetime), --[vydan]
		--autoapprove_vk			= cast(auto_vk.status_date AS smalldatetime)
		--autoapprove_vk			= cast(auto_vk.RequestStatusDate AS smalldatetime)
		--DWH-2668
		autoapprove_vk = 
			CASE
				WHEN R.IsDocumentalVerification = 1 THEN 'auto approve'
				ELSE NULL
			END,
		pr.partner_name, --DWH-2914
		IncomeConfirmation_StatusDate = cast(crs_IncomeConfirmation.RequestStatusDate as smalldatetime), --DWH-189
		IncomeConfirmation = crs_IncomeConfirmation.UserFio,
		ProductSubType_Name = psb.Name,
		CheckingIssuanceMethod_StatusDate = cast(crs_IncomeConfirmation.RequestStatusDate as smalldatetime), --DWH-243
		CheckingIssuanceMethod = crs_IncomeConfirmation.UserFio
	INTO #t_Report
	from #t_ClientRequest AS R
	inner join stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС 
		on ЗаявкаНаЗаймПодПТС.Номер =  R.Number --cr.Number COLLATE Cyrillic_General_CI_AS
	inner join #t_lastClientRequestStatusDate last_clrs 
		on last_clrs.IdClientRequest = R.IdClientRequest --cr.id

	LEFT JOIN stg._fedor.dictionary_CreditProduct dic_cp 
		ON dic_cp.id = R.IdCreditProduct -- cr.IdCreditProduct
	left join stg.[_fedor].[dictionary_ProductSubType] psb 
		on psb.Id =r.ProductSubTypeId

	LEFT JOIN dbo.dm_OverdueIndicators oi 
		ON oi.Number = R.Number -- cr.Number  COLLATE Cyrillic_General_CI_AS
	left join #t_checklists_rejects checklists_rejects 
		on checklists_rejects.IdClientRequest = R.IdClientRequest -- cr.Id
	left join #t_ClientRequestStatus crs_kd  
		on crs_kd.IdClientRequest = R.IdClientRequest --cr.Id
			and crs_kd.RequestStatusName = 'Контроль данных'
	left join #t_ClientRequestStatus cv
		on crs_kd.IdClientRequest = R.IdClientRequest --cr.Id
			and crs_kd.RequestStatusName = 'Верификация клиента'
	left join #t_ClientRequestStatus crs_vk
		on crs_vk.IdClientRequest = R.IdClientRequest --cr.Id
			and crs_vk.RequestStatusName = 'Верификация клиента'
	left join #t_ClientRequestStatus crs_vts
		on crs_vts.IdClientRequest = R.IdClientRequest --cr.Id
			and crs_vts.RequestStatusName = 'Верификация ТС'
	left join #t_ClientRequestStatus crs_od
		on crs_od.IdClientRequest = R.IdClientRequest --cr.Id
			and crs_od.RequestStatusName = 'Одобрено'
	left join #t_ClientRequestStatus crs_zv
		on crs_zv.IdClientRequest = R.IdClientRequest --cr.Id
			and crs_zv.RequestStatusName = 'Заем выдан'
	left join #t_ClientRequestStatus crs_IncomeConfirmation
		on crs_IncomeConfirmation.IdClientRequest = R.IdClientRequest --cr.Id
		and crs_IncomeConfirmation.RequestStatusName = 'Подтверждение дохода'
	left join #t_ClientRequestStatus as crs_CheckingIssuanceMethod
		on crs_CheckingIssuanceMethod.IdClientRequest = R.IdClientRequest --cr.Id
		and crs_CheckingIssuanceMethod.RequestStatusName = 'Проверка способа выдачи'
	left join #t_client_type ct
		on ct.number = R.Number -- cr.Number COLLATE Cyrillic_General_CI_AS
	LEFT JOIN #t_partner AS pr
		ON pr.IdClientRequest = R.IdClientRequest

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Report
		SELECT * INTO ##t_Report FROM #t_Report
	END

	SELECT 
		R.Number,
		R.RequestDate,
		R.finalStatusName,
		R.return_type,
		R.RequestStatusDate,
		R.ClientName,
		R.CheckListItemTypeName,
		R.CheckListItemStatusName,
		R.fpd30,
		R.fpd15,
		R.tpd0,
		R.accepted_amount,
		R.amount,
		R.CreditProductName,
		R.CreditProductType,
		R.kontrol_dannyh_date,
		R.kontrol_dannyh,
		R.verifikaciya_klienta_date,
		R.verifikaciya_klienta,
		R.verifikaciya_ts_date,
		R.verifikaciya_ts,
		R.odobreno_date,
		R.odobreno,
		R.vydan,
		R.autoapprove_vk,
		R.partner_name,
		r.IncomeConfirmation_StatusDate,
		r.IncomeConfirmation,
		r.ProductSubType_Name,
		r.CheckingIssuanceMethod_StatusDate,
		r.CheckingIssuanceMethod
	FROM #t_Report AS R

end