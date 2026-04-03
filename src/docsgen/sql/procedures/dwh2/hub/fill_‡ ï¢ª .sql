--DWH2. hub -  fill_Заявка
--[hub].[fill_Заявка] @Guids = '0AF5AF0B-200E-437B-B1F1-E911755B2A91'
CREATE PROC hub.fill_Заявка
	@mode int = 1 -- 0 - full, 1 - increment, 2 - from dbo.СписокЗаявокДляПересчетаDataVault
	,@Guids nvarchar(max) = null 
	,@isDebug int = 0
as
begin
	--truncate table hub.Заявка
	SELECT @isDebug = isnull(@isDebug, 0)
	set @Guids = nullif(@Guids, '')
begin TRY
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	DECLARE @ВерсияДанных_CRM binary(8) = 0x0, @updated_at_LK datetime = '2000-01-01', @RowVersion_FEDOR binary(8) = 0x0

	if OBJECT_ID ('hub.Заявка') is not NULL
		AND @mode in (1, 2)
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from hub.Заявка), 0x0)
		--set @rowVersion = cast(cast(isnull((select max(ВерсияДанных) from hub.Заявка), 0x0) AS bigint) - 1000 AS binary(8))
		--SELECT 
		--	@ВерсияДанных_CRM = isnull(max(H.ВерсияДанных_CRM), 0x0),
		--	@updated_at_LK = isnull(max(H.updated_at_LK), '2000-01-01'),
		--	@RowVersion_FEDOR = isnull(max(H.RowVersion_FEDOR), 0x0)
		--from hub.Заявка AS H
		SELECT 
			@ВерсияДанных_CRM = isnull(cast(cast(max(H.ВерсияДанных_CRM) AS bigint) - 1000 AS binary(8)), 0x0),
			@updated_at_LK = isnull(dateadd(HOUR,-72,max(H.updated_at_LK)), '2000-01-01'),
			@RowVersion_FEDOR = isnull(cast(cast(max(H.RowVersion_FEDOR) AS bigint) - 1000 AS binary(8)), 0x0)
		from hub.Заявка AS H
	END

	drop table if exists #t_СписокЗаявокДляПересчетаDataVault
	create table #t_СписокЗаявокДляПересчетаDataVault(
		GuidЗаявки uniqueidentifier not null
	)
	create unique index ix1 on #t_СписокЗаявокДляПересчетаDataVault(GuidЗаявки)

	if @mode = 2 begin
		insert #t_СписокЗаявокДляПересчетаDataVault(GuidЗаявки)
		select distinct i.GuidЗаявки
		from dbo.СписокЗаявокДляПересчетаDataVault as i
		where i.GuidЗаявки is not null
	end


	-- список id заявок для загрузки
	--1	CRM
	drop table if exists #t_Заявка_CRM_id
	SELECT
		СсылкаЗаявки						= ЗаявкаНаЗаймПодПТС.Ссылка
		,НомерЗаявки						= ЗаявкаНаЗаймПодПТС.Номер
		,GuidЗаявки							= cast([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Ссылка) as uniqueidentifier)
	INTO #t_Заявка_CRM_id
	from Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС (nolock) --WITH(INDEX=ix_ВерсияДанных)
	where 
		((ВерсияДанных >= @ВерсияДанных_CRM and @Guids is null)
			or [dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Ссылка) in 
			(select trim(value) from string_split(@Guids, ','))
			or (
				@mode = 2
				and dbo.getGUIDFrom1C_IDRREF(ЗаявкаНаЗаймПодПТС.Ссылка) in 
				(select GuidЗаявки from #t_СписокЗаявокДляПересчетаDataVault)
			)
		)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Заявка_CRM_id
		SELECT * INTO ##t_Заявка_CRM_id FROM #t_Заявка_CRM_id AS T
	END

	--2	LK
	DROP TABLE IF EXISTS #t_Заявка_LK_id
	select distinct 
		СсылкаЗаявки						= dbo.get1CIDRREF_FromGUID(try_cast(Заявка_LK.guid AS uniqueidentifier))
		,НомерЗаявки						= Заявка_LK.num_1c
		,GuidЗаявки							= try_cast(Заявка_LK.guid AS uniqueidentifier)
	into #t_Заявка_LK_id
	from Stg._LK.requests AS Заявка_LK --WITH(INDEX=ix_updated_at)
	where 1=1
		AND try_cast(Заявка_LK.guid AS uniqueidentifier) IS NOT NULL
		AND (
			(Заявка_LK.updated_at >= @updated_at_LK and @Guids is null)
			OR Заявка_LK.guid in (select trim(value) from string_split(@Guids, ','))
			or (
				@mode = 2
				and Заявка_LK.guid in 
				(select GuidЗаявки from #t_СписокЗаявокДляПересчетаDataVault)
			)
		)
		--2025-05-28 
		--в LK добавлены старые заявки с другими гуидами и ДатаЗаявки = 2025-05-27
		--их не надо добавлять в hub !
		and not exists(
			select top(1) 1
			from hub.Заявка as X
			where X.НомерЗаявки = Заявка_LK.num_1c
				and X.GuidЗаявки <> try_cast(Заявка_LK.guid AS uniqueidentifier)
			)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Заявка_LK_id
		SELECT * INTO ##t_Заявка_LK_id FROM #t_Заявка_LK_id AS T
	END

	--3. FEDOR
	drop table if exists #t_Заявка_FEDOR_id
	select distinct 
		СсылкаЗаявки						= dbo.get1CIDRREF_FromGUID(try_cast(Заявка_FEDOR.Id AS uniqueidentifier))
		,НомерЗаявки						= Заявка_FEDOR.Number COLLATE Cyrillic_General_CI_AS
		,GuidЗаявки							= try_cast(Заявка_FEDOR.Id AS uniqueidentifier)
	into #t_Заявка_FEDOR_id
	from Stg._fedor.core_ClientRequest AS Заявка_FEDOR --WITH(INDEX=ix_RowVersion)
	where 1=1
		AND try_cast(Заявка_FEDOR.Id AS uniqueidentifier) IS NOT NULL
		AND (
			(Заявка_FEDOR.RowVersion >= @RowVersion_FEDOR and @Guids is null)
			OR Заявка_FEDOR.Id in (select trim(value) from string_split(@Guids, ','))
			or (
				@mode = 2
				and Заявка_FEDOR.Id in 
					(select GuidЗаявки from #t_СписокЗаявокДляПересчетаDataVault)
			)
		)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Заявка_FEDOR_id
		SELECT * INTO ##t_Заявка_FEDOR_id FROM #t_Заявка_FEDOR_id AS T
	END

	--4 объединенный список id
	drop table if exists #t_Заявка_id

	SELECT T.СсылкаЗаявки, T.НомерЗаявки, GuidЗаявки = cast(T.GuidЗаявки AS nvarchar(36))
	INTO #t_Заявка_id
	FROM #t_Заявка_CRM_id AS T
	UNION 
	SELECT T.СсылкаЗаявки, T.НомерЗаявки, GuidЗаявки = cast(T.GuidЗаявки AS nvarchar(36))
	FROM #t_Заявка_LK_id AS T
	UNION 
	SELECT T.СсылкаЗаявки, T.НомерЗаявки, GuidЗаявки = cast(T.GuidЗаявки AS nvarchar(36))
	FROM #t_Заявка_FEDOR_id AS T

	CREATE INDEX ix1 ON #t_Заявка_id(СсылкаЗаявки)
	CREATE INDEX ix2 ON #t_Заявка_id(GuidЗаявки)
	CREATE INDEX ix3 ON #t_Заявка_id(НомерЗаявки)

	--DELETE R
	--FROM #t_Заявка_id AS R
	--WHERE R.НомерЗаявки IS NULL
	--	OR charindex('СДRC', R.НомерЗаявки) > 0
	--	OR charindex('СЗRC', R.НомерЗаявки) > 0

	DELETE R
	FROM #t_Заявка_id AS R
	WHERE charindex('СДRC', R.НомерЗаявки) > 0
		OR charindex('СЗRC', R.НомерЗаявки) > 0


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Заявка_id
		SELECT * INTO ##t_Заявка_id FROM #t_Заявка_id AS T
	END
	--// id заявок для загрузки


	drop table if exists #t_Заявка_CRM

	select distinct 
		СсылкаЗаявки						= ЗаявкаНаЗаймПодПТС.Ссылка
		,НомерЗаявки						= ЗаявкаНаЗаймПодПТС.Номер
		,I.GuidЗаявки --					= cast([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Ссылка) as uniqueidentifier)
		,ДатаЗаявки							= iif(ЗаявкаНаЗаймПодПТС.Дата>'2001-01-01', dateadd(year,-2000,  ЗаявкаНаЗаймПодПТС.Дата), null)
		,Фамилия							= nullif(trim(ЗаявкаНаЗаймПодПТС.Фамилия),'')
		,Имя								= nullif(trim(ЗаявкаНаЗаймПодПТС.Имя),'')
		,Отчество							= nullif(
			CASE WHEN trim(ЗаявкаНаЗаймПодПТС.Отчество) IN ('-') THEN '' ELSE trim(ЗаявкаНаЗаймПодПТС.Отчество) END,'')
		,ФИО = concat(ЗаявкаНаЗаймПодПТС.Фамилия, ' ', ЗаявкаНаЗаймПодПТС.Имя, ' ', ЗаявкаНаЗаймПодПТС.Отчество)
		,Пол = dm.f_ЗаявкаНаЗаймПодПТС_Пол(1, ПолФизическогоЛица.Имя, nullif(trim(ЗаявкаНаЗаймПодПТС.Отчество),''))
		,[ДатаРождения]						= iif(ЗаявкаНаЗаймПодПТС.ДатаРождения>'2001-01-01', dateadd(year,-2000,  ЗаявкаНаЗаймПодПТС.ДатаРождения), null)
		,[Сумма заявки]						= cast(ЗаявкаНаЗаймПодПТС.Сумма as money)
		,[ГодВыпускаТС]						= cast(iif(ЗаявкаНаЗаймПодПТС.ГодВыпуска>'2001-01-01',  dateadd(year,-2000,  ЗаявкаНаЗаймПодПТС.ГодВыпуска), null) as date)
		,[Оценочная Стоимость]				= cast(ЗаявкаНаЗаймПодПТС.ОценочнаяСтоимость as money)
		,[Сумма Выданная]					= cast(ЗаявкаНаЗаймПодПТС.СуммаВыданная as money)
		,isPts								= cast(CASE WHEN ЗаявкаНаЗаймПодПТС.ПДЛ = 0 AND ЗаявкаНаЗаймПодПТС.Инстолмент = 0 THEN 1 ELSE 0 END as bit)
		,isPdl								= cast(ЗаявкаНаЗаймПодПТС.ПДЛ as bit)
		,[isInstallment]					= cast(ЗаявкаНаЗаймПодПТС.[Инстолмент] as bit)
		,[isSmartInstallment]				= cast(ЗаявкаНаЗаймПодПТС.СмартИнстолмент as bit)
		,[СуммарныйМесячныйДоход]			= cast(ЗаявкаНаЗаймПодПТС.СуммарныйМесячныйДоход as money)
		,[ДомашнийТелефон]					= nullif(trim(ЗаявкаНаЗаймПодПТС.[ДомашнийТелефон]),'')
		,[МобильныйТелефон]					= cast(try_cast(nullif(trim(ЗаявкаНаЗаймПодПТС.[МобильныйТелефон]),'') as bigint) as nvarchar(16))
		,[МобильныйТелефонКонтактногоЛица]	= nullif(trim(ЗаявкаНаЗаймПодПТС.[МобильныйТелефонКонтактногоЛица]),'')
		,[НомераТелефоновБезСимволов]		= cast(try_cast(nullif(trim(ЗаявкаНаЗаймПодПТС.[НомераТелефоновБезСимволов]),'') as bigint) as nvarchar(10))
		,[РабочийТелефон]					= nullif(trim(ЗаявкаНаЗаймПодПТС.[РабочийТелефон]), '')
		,РегионПроживанияКакВЗаявке			= nullif(trim(ЗаявкаНаЗаймПодПТС.АдресПроживания), '')
		--DWH-2404
		,[Сумма Первичная]					= cast(ЗаявкаНаЗаймПодПТС.СуммаПервичная as money)
		--Если isPdl=1 и isInstallment=1 то "Беззалог" иначе "ПТС"
		,[Наличие Залога]					= cast(
			CASE WHEN ЗаявкаНаЗаймПодПТС.Инстолмент = 1 OR ЗаявкаНаЗаймПодПТС.ПДЛ = 1 THEN 'Беззалог' ELSE 'ПТС' END as varchar(20))
		,[Серия Паспорта]					= nullif(trim(ЗаявкаНаЗаймПодПТС.СерияПаспорта), '')
		,[Номер Паспорта]					= nullif(trim(ЗаявкаНаЗаймПодПТС.НомерПаспорта), '')

		,created_at							= CURRENT_TIMESTAMP
		,updated_at							= CURRENT_TIMESTAMP
		,[spFillName]						= @spName
		,ВерсияДанных_CRM					= ЗаявкаНаЗаймПодПТС.ВерсияДанных

		,Link_GuidКредитныйПродукт			= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.КредитныйПродукт), '00000000-0000-0000-0000-000000000000')		as uniqueidentifier)
		,Link_GuidВидЗаполнения				= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.ВидЗаполнения), '00000000-0000-0000-0000-000000000000')			as uniqueidentifier)
		,Link_GuidВариантПредложенияСтавки	= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.ВариантПредложенияСтавки), '00000000-0000-0000-0000-000000000000')as uniqueidentifier)
		,Link_GuidМаркаМашины				= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.МаркаМашины), '00000000-0000-0000-0000-000000000000')				as uniqueidentifier)
		,Link_GuidМодельАвтомобиля			= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Модель), '00000000-0000-0000-0000-000000000000')					as uniqueidentifier)
		,Link_GuidТекущийСтатусЗаявки		= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Статус), '00000000-0000-0000-0000-000000000000')					as uniqueidentifier)
		,Link_GuidCRM_Автор					= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.CRM_Автор), '00000000-0000-0000-0000-000000000000')				as uniqueidentifier)
		,Link_GuidПричинаОтказа				= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.ПричинаОтказа), '00000000-0000-0000-0000-000000000000')			as uniqueidentifier)
		,Link_GuidКлиент					= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Партнер), '00000000-0000-0000-0000-000000000000')					as uniqueidentifier)
		,Link_GuidСпособОформления			= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.СпособОформления), '00000000-0000-0000-0000-000000000000')		AS uniqueidentifier)
		,Link_GuidОфис						= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Офис), '00000000-0000-0000-0000-000000000000')					AS uniqueidentifier)
		,Link_GuidСпособВыдачиЗайма			= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.СпособВыдачиЗайма), '00000000-0000-0000-0000-000000000000')		AS uniqueidentifier)
		
		,Link_GuidТипКредитногоПродукта		= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.ТипКредитногоПродукта), '00000000-0000-0000-0000-000000000000')	 AS uniqueidentifier)
		,Link_GuidПодТипКредитногоПродукта	= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.ПодТипКредитногоПродукта), '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)

		,Link_GuidБизнесРегион				= cast(nullif(БизнесРегионы.КодФИАС, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)

		--,ЗаявкаНаЗаймПодПТС.*
	into #t_Заявка_CRM
	from #t_Заявка_id AS I
		INNER JOIN Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS ЗаявкаНаЗаймПодПТС --WITH(INDEX=ix_ВерсияДанных)
			ON ЗаявкаНаЗаймПодПТС.Ссылка = I.СсылкаЗаявки
		LEFT JOIN Stg._1cCRM.Перечисление_ПолФизическогоЛица AS ПолФизическогоЛица
			ON ПолФизическогоЛица.Ссылка = ЗаявкаНаЗаймПодПТС.Пол
		LEFT JOIN Stg._1cCRM.РегистрСведений_ДополнительныеСведения AS ДополнительныеСведения
			ON ДополнительныеСведения.Объект_Ссылка = ЗаявкаНаЗаймПодПТС.Ссылка
			AND ДополнительныеСведения.Свойство = 0xBBB9B1B2DF965EF511EF703A9152CE35
		LEFT JOIN Stg._1cCRM.Справочник_БизнесРегионы AS БизнесРегионы
			ON БизнесРегионы.Ссылка = ДополнительныеСведения.Значение_Ссылка
			AND try_cast(БизнесРегионы.КодФИАС AS uniqueidentifier) IS NOT NULL
	--where 
	--	((ВерсияДанных >= @ВерсияДанных_CRM and @Guids is null)
	--		or [dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Ссылка) in 
	--		(select trim(value) from string_split(@Guids, ','))
	--	)

	DELETE R
	FROM #t_Заявка_CRM AS R
	WHERE R.НомерЗаявки IS NULL
		OR charindex('СДRC', R.НомерЗаявки) > 0
		OR charindex('СЗRC', R.НомерЗаявки) > 0

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Заявка_CRM 
		SELECT * INTO ##t_Заявка_CRM FROM #t_Заявка_CRM AS T
	END



	-- 2. _lk.requests
	drop table if exists #t_Заявка_LK

	select distinct 
		СсылкаЗаявки						= dbo.get1CIDRREF_FromGUID(try_cast(Заявка_LK.guid AS uniqueidentifier))
		,НомерЗаявки						= Заявка_LK.num_1c
		,GuidЗаявки							= try_cast(Заявка_LK.guid AS uniqueidentifier)
		,ДатаЗаявки							= cast(Заявка_LK.created_at AS datetime2(0))
		,Фамилия							= nullif(trim(Заявка_LK.client_last_name),'')
		,Имя								= nullif(trim(Заявка_LK.client_first_name),'')
		,Отчество							= nullif(
			CASE WHEN trim(Заявка_LK.client_patronymic) IN ('-') THEN '' ELSE trim(Заявка_LK.client_patronymic) END,'')
		,ФИО = concat(Заявка_LK.client_last_name, ' ', Заявка_LK.client_first_name, ' ', Заявка_LK.client_patronymic)
		,Пол = dm.f_ЗаявкаНаЗаймПодПТС_Пол(1, Заявка_LK.client_first_name, nullif(trim(Заявка_LK.client_patronymic),''))
		,[ДатаРождения]						= nullif(Заявка_LK.client_birthday,'0001-01-01')
		,[Сумма заявки]						= cast(Заявка_LK.summ as money)
		,[ГодВыпускаТС]						= try_cast(concat(cast(Заявка_LK.auto_year AS varchar(4)),'-01-01') as date)
		,[Оценочная Стоимость]				= cast(Заявка_LK.auto_price as money)
		,[Сумма Выданная]					= cast(NULL as money)
		,isPts								= cast(CASE WHEN Заявка_LK.product_types_id = 1 THEN 1 ELSE 0 END as bit)
		,isPdl								= cast(CASE WHEN Заявка_LK.product_types_id = 3 THEN 1 ELSE 0 END as bit)
		,[isInstallment]					= cast(CASE WHEN Заявка_LK.product_types_id = 2 THEN 1 ELSE 0 END as bit)
		,[isSmartInstallment]				= cast(CASE WHEN Заявка_LK.product_sub_type_id = 3 THEN 1 ELSE 0 END as bit)
		,[СуммарныйМесячныйДоход]			= cast(NULL as money)
		,[ДомашнийТелефон]					= nullif(trim(Заявка_LK.client_home_phone),'')
		,[МобильныйТелефон]					= cast(try_cast(nullif(trim(Заявка_LK.client_mobile_phone),'') as bigint) as nvarchar(16))
		,[МобильныйТелефонКонтактногоЛица]	= nullif(trim(Заявка_LK.client_guarantor_phone),'')
		,[НомераТелефоновБезСимволов]		= cast(try_cast(nullif(trim(Заявка_LK.client_mobile_phone),'') as bigint) as nvarchar(11))
		,[РабочийТелефон]					= nullif(trim(Заявка_LK.client_workplace_phone), '')
		,РегионПроживанияКакВЗаявке			= cast(NULL AS nvarchar(255)) --nullif(trim(Заявка_LK.registration_address), '')
		--DWH-2404
		,[Сумма Первичная]					= cast(NULL as money)
		--Если isPdl=1 и isInstallment=1 то "Беззалог" иначе "ПТС"
		,[Наличие Залога]					= cast(
			CASE WHEN Заявка_LK.product_types_id IN (1) THEN 'ПТС' ELSE 'Беззалог' END as varchar(20))
		,[Серия Паспорта]					= nullif(trim(Заявка_LK.client_passport_serial_number), '')
		,[Номер Паспорта]					= nullif(trim(Заявка_LK.client_passport_number), '')

		,created_at							= CURRENT_TIMESTAMP
		,updated_at							= CURRENT_TIMESTAMP
		,[spFillName]						= @spName
		,updated_at_LK						= Заявка_LK.updated_at
		--,Link_GuidКредитныйПродукт			= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.КредитныйПродукт), '00000000-0000-0000-0000-000000000000')		as uniqueidentifier)
		--,Link_GuidВидЗаполнения				= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.ВидЗаполнения), '00000000-0000-0000-0000-000000000000')			as uniqueidentifier)
		--,Link_GuidВариантПредложенияСтавки	= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.ВариантПредложенияСтавки), '00000000-0000-0000-0000-000000000000')as uniqueidentifier)
		--,Link_GuidМаркаМашины				= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.МаркаМашины), '00000000-0000-0000-0000-000000000000')				as uniqueidentifier)
		--,Link_GuidМодельАвтомобиля			= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Модель), '00000000-0000-0000-0000-000000000000')					as uniqueidentifier)
		--,Link_GuidТекущийСтатусЗаявки		= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Статус), '00000000-0000-0000-0000-000000000000')					as uniqueidentifier)
		--,Link_GuidCRM_Автор					= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.CRM_Автор), '00000000-0000-0000-0000-000000000000')				as uniqueidentifier)
		--,Link_GuidПричинаОтказа				= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.ПричинаОтказа), '00000000-0000-0000-0000-000000000000')			as uniqueidentifier)
		--,Link_GuidКлиент					= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Партнер), '00000000-0000-0000-0000-000000000000')					as uniqueidentifier)
		--,Link_GuidСпособОформления			= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.СпособОформления), '00000000-0000-0000-0000-000000000000')		AS uniqueidentifier)
		--,Link_GuidОфис						= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Офис), '00000000-0000-0000-0000-000000000000')					AS uniqueidentifier)
		--,Link_GuidСпособВыдачиЗайма			= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.СпособВыдачиЗайма), '00000000-0000-0000-0000-000000000000')		AS uniqueidentifier)
		
		,Link_GuidТекущийСтатусЗаявки		= cast(null AS uniqueidentifier)
		,Link_GuidБизнесРегион				= cast(null AS uniqueidentifier)
		,Link_GuidТипКредитногоПродукта		= try_cast(nullif(pt.guid, '00000000-0000-0000-0000-000000000000')	 AS uniqueidentifier)
		,Link_GuidПодТипКредитногоПродукта	= try_cast(nullif(pst.guid, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)

	into #t_Заявка_LK
	from #t_Заявка_id AS I
		INNER JOIN Stg._LK.requests AS Заявка_LK --WITH(INDEX=ix_updated_at)
			ON Заявка_LK.guid = I.GuidЗаявки

		left join stg._lk.product_types pt on pt.id = Заявка_LK.product_types_id
		left join stg._lk.product_sub_type pst on pst.id = Заявка_LK.product_sub_type_id
	where 1=1
		AND try_cast(Заявка_LK.guid AS uniqueidentifier) IS NOT NULL
	--	AND (
	--		(Заявка_LK.updated_at >= @updated_at_LK and @Guids is null)
	--		OR Заявка_LK.guid in (select trim(value) from string_split(@Guids, ','))
	--	)

		--в hub.Заявка могут попадать из LK и FEDOR заявки с пустым номером
		--AND Заявка_LK.num_1c IS NOT NULL --???
		--and 
		--	NOT (charindex('СДRC', isnull(Заявка_LK.num_1c, '')) > 0
		--		or charindex('СЗRC', isnull(Заявка_LK.num_1c, '')) > 0
		--	)

	DELETE R
	FROM #t_Заявка_LK AS R
	WHERE charindex('СДRC', R.НомерЗаявки) > 0
		OR charindex('СЗRC', R.НомерЗаявки) > 0

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Заявка_LK
		SELECT * INTO ##t_Заявка_LK FROM #t_Заявка_LK AS T
		--RETURN 0
	END


	-- 3. _fedor.core_ClientRequest
	drop table if exists #t_Заявка_FEDOR

	select distinct 
		СсылкаЗаявки						= dbo.get1CIDRREF_FromGUID(try_cast(Заявка_FEDOR.Id AS uniqueidentifier))
		,НомерЗаявки						= Заявка_FEDOR.Number COLLATE Cyrillic_General_CI_AS
		,GuidЗаявки							= try_cast(Заявка_FEDOR.Id AS uniqueidentifier)
		,ДатаЗаявки							= cast(dateadd(HOUR, -3, Заявка_FEDOR.CreatedOn) AS datetime2(0))
		,Фамилия							= nullif(trim(Заявка_FEDOR.ClientLastName),'') COLLATE Cyrillic_General_CI_AS
		,Имя								= nullif(trim(Заявка_FEDOR.ClientFirstName),'') COLLATE Cyrillic_General_CI_AS
		,Отчество							= nullif(
			CASE WHEN trim(Заявка_FEDOR.ClientMiddleName) IN ('-') THEN '' ELSE trim(Заявка_FEDOR.ClientMiddleName) END,'') COLLATE Cyrillic_General_CI_AS
		,ФИО = concat(Заявка_FEDOR.ClientLastName, ' ', Заявка_FEDOR.ClientFirstName, ' ', Заявка_FEDOR.ClientMiddleName) COLLATE Cyrillic_General_CI_AS
		,Пол = dm.f_ЗаявкаНаЗаймПодПТС_Пол(1, Заявка_FEDOR.ClientFirstName, nullif(trim(Заявка_FEDOR.ClientMiddleName),'')) COLLATE Cyrillic_General_CI_AS
		,[ДатаРождения]						= nullif(cast(Заявка_FEDOR.ClientBirthDay AS datetime2(0)), '0001-01-01')
		,[Сумма заявки]						= cast(Заявка_FEDOR.SumContract as money)
		,[ГодВыпускаТС]						= cast(NULL as date)
		,[Оценочная Стоимость]				= cast(Заявка_FEDOR.CarEstimationPrice as money)
		,[Сумма Выданная]					= cast(Заявка_FEDOR.ResultSum as money)
		,isPts								= cast(CASE WHEN ProductType.code = 'pts' THEN 1 ELSE 0 END as bit)
		,isPdl								= cast(CASE WHEN ProductType.code = 'pdl' THEN 1 ELSE 0 END as bit)
		,[isInstallment]					= cast(CASE WHEN ProductType.code = 'installment' THEN 1 ELSE 0 END as bit)
		,[isSmartInstallment]				= cast(CASE WHEN ProductSubType.code = 'smart-installment' THEN 1 ELSE 0 END as bit)
		,[СуммарныйМесячныйДоход]			= cast(Заявка_FEDOR.ClientMonthlyIncome AS money)
		,[ДомашнийТелефон]					= nullif(trim(Заявка_FEDOR.ClientPhoneHome),'') COLLATE Cyrillic_General_CI_AS
		,[МобильныйТелефон]					= cast(try_cast(nullif(trim(Заявка_FEDOR.ClientPhoneMobile),'') as bigint) as nvarchar(16))
	COLLATE Cyrillic_General_CI_AS
		,[МобильныйТелефонКонтактногоЛица]	= nullif(trim(Заявка_FEDOR.ClientContactPersonPhone),'') COLLATE Cyrillic_General_CI_AS
		,[НомераТелефоновБезСимволов]		=  cast(try_cast(nullif(trim(Заявка_FEDOR.ClientPhoneMobile),'') as bigint) as nvarchar(11))
		,[РабочийТелефон]					= nullif(trim(Заявка_FEDOR.ClientWorkPlacePhone), '') COLLATE Cyrillic_General_CI_AS
		,РегионПроживанияКакВЗаявке			= nullif(trim(Заявка_FEDOR.ClientAddressStay), '') COLLATE Cyrillic_General_CI_AS
		--DWH-2404
		,[Сумма Первичная]					= cast(Заявка_FEDOR.SumInitialContract as money)
		--Если isPdl=1 и isInstallment=1 то "Беззалог" иначе "ПТС"
		,[Наличие Залога]					= cast(
			CASE WHEN ProductType.code = 'pts' THEN 'ПТС' ELSE 'Беззалог' END as varchar(20)) COLLATE Cyrillic_General_CI_AS
		,[Серия Паспорта]					= nullif(trim(Заявка_FEDOR.ClientPassportSerial), '') COLLATE Cyrillic_General_CI_AS
		,[Номер Паспорта]					= nullif(trim(Заявка_FEDOR.ClientPassportNumber), '') COLLATE Cyrillic_General_CI_AS

		,created_at							= CURRENT_TIMESTAMP
		,updated_at							= CURRENT_TIMESTAMP
		,[spFillName]						= @spName
		,RowVersion_FEDOR = Заявка_FEDOR.RowVersion
		--,Link_GuidКредитныйПродукт			= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.КредитныйПродукт), '00000000-0000-0000-0000-000000000000')		as uniqueidentifier)
		--,Link_GuidВидЗаполнения				= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.ВидЗаполнения), '00000000-0000-0000-0000-000000000000')			as uniqueidentifier)
		--,Link_GuidВариантПредложенияСтавки	= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.ВариантПредложенияСтавки), '00000000-0000-0000-0000-000000000000')as uniqueidentifier)
		--,Link_GuidМаркаМашины				= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.МаркаМашины), '00000000-0000-0000-0000-000000000000')				as uniqueidentifier)
		--,Link_GuidМодельАвтомобиля			= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Модель), '00000000-0000-0000-0000-000000000000')					as uniqueidentifier)
		,Link_GuidТекущийСтатусЗаявки = ClientRequestStatus.IdExternal --cast(nullif([dbo].[getGUIDFrom1C_IDRREF](...), '00000000-0000-0000-0000-000000000000')					as uniqueidentifier)
		--,Link_GuidCRM_Автор					= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.CRM_Автор), '00000000-0000-0000-0000-000000000000')				as uniqueidentifier)
		--,Link_GuidПричинаОтказа				= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.ПричинаОтказа), '00000000-0000-0000-0000-000000000000')			as uniqueidentifier)
		--,Link_GuidКлиент					= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Партнер), '00000000-0000-0000-0000-000000000000')					as uniqueidentifier)
		--,Link_GuidСпособОформления			= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.СпособОформления), '00000000-0000-0000-0000-000000000000')		AS uniqueidentifier)
		--,Link_GuidОфис						= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.Офис), '00000000-0000-0000-0000-000000000000')					AS uniqueidentifier)
		--,Link_GuidСпособВыдачиЗайма			= cast(nullif([dbo].[getGUIDFrom1C_IDRREF](ЗаявкаНаЗаймПодПТС.СпособВыдачиЗайма), '00000000-0000-0000-0000-000000000000')		AS uniqueidentifier)

		,Link_GuidБизнесРегион				= cast(nullif(region.FiasCode, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_GuidТипКредитногоПродукта		= try_cast(nullif(ProductType.ExternalId, '00000000-0000-0000-0000-000000000000')	 AS uniqueidentifier)
		,Link_GuidПодТипКредитногоПродукта	= try_cast(nullif(ProductSubType.ExternalId, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)

		--,ЗаявкаНаЗаймПодПТС.*
	into #t_Заявка_FEDOR
	from #t_Заявка_id AS I
		INNER JOIN Stg._fedor.core_ClientRequest AS Заявка_FEDOR --WITH(INDEX=ix_RowVersion)
			ON Заявка_FEDOR.Id = I.GuidЗаявки
		LEFT JOIN Stg._fedor.dictionary_ProductType AS ProductType
			ON ProductType.Id = Заявка_FEDOR.ProductTypeId
		LEFT JOIN Stg._fedor.dictionary_ProductSubType AS ProductSubType
			ON ProductSubType.Id = Заявка_FEDOR.ProductSubTypeId
		LEFT JOIN Stg._fedor.dictionary_ClientRequestStatus AS ClientRequestStatus
			ON ClientRequestStatus.Id = Заявка_FEDOR.IdStatus
		LEFT JOIN Stg._fedor.dictionary_region AS region
			ON region.Id = Заявка_FEDOR.IdClientAddressRegionFact
			AND try_cast(region.FiasCode AS uniqueidentifier) IS NOT NULL
	where 1=1
		AND try_cast(Заявка_FEDOR.Id AS uniqueidentifier) IS NOT NULL
	--	AND (
	--		(Заявка_FEDOR.RowVersion >= @RowVersion_FEDOR and @Guids is null)
	--		OR Заявка_FEDOR.Id in (select trim(value) from string_split(@Guids, ','))
	--	)
		--в hub.Заявка могут попадать из LK и FEDOR заявки с пустым номером
		--AND Заявка_FEDOR.Number IS NOT NULL --???
		--and 
		--	NOT (charindex('СДRC', isnull(Заявка_FEDOR.Number, '')) > 0
		--		or charindex('СЗRC', isnull(Заявка_FEDOR.Number, '')) > 0
		--	)

	DELETE R
	FROM #t_Заявка_FEDOR AS R
	WHERE charindex('СДRC', R.НомерЗаявки) > 0
		OR charindex('СЗRC', R.НомерЗаявки) > 0

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Заявка_FEDOR
		SELECT * INTO ##t_Заявка_FEDOR FROM #t_Заявка_FEDOR AS T
		--RETURN 0
	END

	CREATE INDEX ix1 ON #t_Заявка_CRM(GuidЗаявки)
	CREATE INDEX ix1 ON #t_Заявка_LK(GuidЗаявки)
	CREATE INDEX ix1 ON #t_Заявка_FEDOR(GuidЗаявки)


	-- 4 full outer join
	drop table if exists #t_Заявка

	select distinct 
		СсылкаЗаявки = coalesce(CRM.СсылкаЗаявки, LK.СсылкаЗаявки, FEDOR.СсылкаЗаявки)
		,НомерЗаявки = coalesce(CRM.НомерЗаявки, LK.НомерЗаявки, FEDOR.НомерЗаявки)
		,GuidЗаявки = coalesce(CRM.GuidЗаявки, LK.GuidЗаявки, FEDOR.GuidЗаявки)
		,ДатаЗаявки = coalesce(CRM.ДатаЗаявки, LK.ДатаЗаявки, FEDOR.ДатаЗаявки)
		,Фамилия = coalesce(CRM.Фамилия, LK.Фамилия, FEDOR.Фамилия)
		,Имя = coalesce(CRM.Имя, LK.Имя, FEDOR.Имя)
		,Отчество = coalesce(CRM.Отчество, LK.Отчество, FEDOR.Отчество)
		,ФИО = coalesce(CRM.ФИО, LK.ФИО, FEDOR.ФИО)
		,Пол = coalesce(CRM.Пол, LK.Пол, FEDOR.Пол)
		,[ДатаРождения] = coalesce(CRM.[ДатаРождения], LK.[ДатаРождения], FEDOR.[ДатаРождения])
		,[Сумма заявки] = coalesce(CRM.[Сумма заявки], LK.[Сумма заявки], FEDOR.[Сумма заявки])
		,[ГодВыпускаТС] = coalesce(CRM.[ГодВыпускаТС], LK.[ГодВыпускаТС], FEDOR.[ГодВыпускаТС])
		,[Оценочная Стоимость] = coalesce(CRM.[Оценочная Стоимость], LK.[Оценочная Стоимость], FEDOR.[Оценочная Стоимость])
		,[Сумма Выданная] = coalesce(CRM.[Сумма Выданная], LK.[Сумма Выданная], FEDOR.[Сумма Выданная])
		,isPts = coalesce(CRM.isPts, LK.isPts, FEDOR.isPts)
		,isPdl = coalesce(CRM.isPdl, LK.isPdl, FEDOR.isPdl)
		,isInstallment = coalesce(CRM.isInstallment, LK.isInstallment, FEDOR.isInstallment)
		,isSmartInstallment = coalesce(CRM.isSmartInstallment, LK.isSmartInstallment, FEDOR.isSmartInstallment)
		,[СуммарныйМесячныйДоход] = coalesce(CRM.[СуммарныйМесячныйДоход], LK.[СуммарныйМесячныйДоход], FEDOR.[СуммарныйМесячныйДоход])
		,[ДомашнийТелефон] = coalesce(CRM.[ДомашнийТелефон], LK.[ДомашнийТелефон], FEDOR.[ДомашнийТелефон])
		,[МобильныйТелефон] = coalesce(CRM.[МобильныйТелефон], LK.[МобильныйТелефон], FEDOR.[МобильныйТелефон])
		,[МобильныйТелефонКонтактногоЛица] = coalesce(CRM.[МобильныйТелефонКонтактногоЛица], LK.[МобильныйТелефонКонтактногоЛица], FEDOR.[МобильныйТелефонКонтактногоЛица])
		,[НомераТелефоновБезСимволов] = coalesce(CRM.[НомераТелефоновБезСимволов], LK.[НомераТелефоновБезСимволов], FEDOR.[НомераТелефоновБезСимволов])
		,[РабочийТелефон] = coalesce(CRM.[РабочийТелефон], LK.[РабочийТелефон], FEDOR.[РабочийТелефон])
		,РегионПроживанияКакВЗаявке = coalesce(CRM.РегионПроживанияКакВЗаявке, LK.РегионПроживанияКакВЗаявке, FEDOR.РегионПроживанияКакВЗаявке)
		,[Сумма Первичная] = coalesce(CRM.[Сумма Первичная], LK.[Сумма Первичная], FEDOR.[Сумма Первичная])
		,[Наличие Залога] = coalesce(CRM.[Наличие Залога], LK.[Наличие Залога], FEDOR.[Наличие Залога])
		,[Серия Паспорта] = coalesce(CRM.[Серия Паспорта], LK.[Серия Паспорта], FEDOR.[Серия Паспорта])
		,[Номер Паспорта] = coalesce(CRM.[Номер Паспорта], LK.[Номер Паспорта], FEDOR.[Номер Паспорта])

		,created_at = coalesce(CRM.created_at, LK.created_at, FEDOR.created_at)
		,updated_at = coalesce(CRM.updated_at, LK.updated_at, FEDOR.updated_at)
		,spFillName = coalesce(CRM.spFillName, LK.spFillName, FEDOR.spFillName)
		,ВерсияДанных_CRM = CRM.ВерсияДанных_CRM
		,updated_at_LK = LK.updated_at_LK
		,RowVersion_FEDOR = FEDOR.RowVersion_FEDOR

	into #t_Заявка
	FROM #t_Заявка_CRM AS CRM
		FULL OUTER JOIN #t_Заявка_LK AS LK
			ON LK.GuidЗаявки = CRM.GuidЗаявки
		FULL OUTER JOIN #t_Заявка_FEDOR AS FEDOR
			ON FEDOR.GuidЗаявки = isnull(CRM.GuidЗаявки, LK.GuidЗаявки)

	CREATE INDEX ix1 ON #t_Заявка(GuidЗаявки)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Заявка_0
		SELECT * INTO ##t_Заявка_0 FROM #t_Заявка AS T
		--RETURN 0
	END



	DROP TABLE IF EXISTS #t_Регион
	-- var 1
	/*
	SELECT 
		B.GuidЗаявки,
		Регион = isnull(B.Регион, B.РегионПроживанияКакВЗаявке)
	INTO #t_Регион
	FROM (
		SELECT 
			T.GuidЗаявки,
			T.РегионПроживанияКакВЗаявке,
			A.Регион
		FROM (
				SELECT R.GuidЗаявки, R.РегионПроживанияКакВЗаявке
				FROM #t_Заявка AS R
				WHERE len(R.РегионПроживанияКакВЗаявке)-len(replace(R.РегионПроживанияКакВЗаявке,',','')) >= 4
			) AS T
			OUTER APPLY Stg.dbo.tvf_GetAddressWithPartsPvt(T.РегионПроживанияКакВЗаявке) AS A
		) AS B

	CREATE INDEX ix1 ON #t_Регион(GuidЗаявки)

	UPDATE T
	SET РегионПроживанияКакВЗаявке = D.РегионПроживанияКакВЗаявке
	FROM #t_Заявка AS T
		INNER JOIN (
			SELECT 
				B.GuidЗаявки,
				РегионПроживанияКакВЗаявке = isnull(C.РегионПроживания, B.РегионПроживанияКакВЗаявке)
			FROM (
				SELECT 
					R.GuidЗаявки,
					РегионПроживанияКакВЗаявке = isnull(A.Регион, R.РегионПроживанияКакВЗаявке)
				FROM #t_Заявка AS R
					LEFT JOIN #t_Регион AS A
						ON A.GuidЗаявки = R.GuidЗаявки
				) AS B
				LEFT JOIN dbo.КорректировкаРегионПроживанияКакВЗаявке AS C
					ON C.РегионПроживанияКакВЗаявке = B.РегионПроживанияКакВЗаявке
		) AS D
		ON D.GuidЗаявки = T.GuidЗаявки
	*/

	-- var 2
	--Регион м.б. на 1-й, 2-й или на 3-й (правильной) позиции в адресе
	SELECT 
		B.GuidЗаявки,
		Регион = coalesce(BR1.Наименование, BR2.Наименование, BR3.Наименование,
			C1.РегионПроживания, C2.РегионПроживания, C3.РегионПроживания)
	INTO #t_Регион
	FROM (
		SELECT 
			T.GuidЗаявки,
			T.РегионПроживанияКакВЗаявке,
			A.Страна,
			A.[Почтовый индекс],
			A.Регион
		FROM (
				SELECT R.GuidЗаявки, R.РегионПроживанияКакВЗаявке
				FROM #t_Заявка AS R
				WHERE 1=1
					--and len(R.РегионПроживанияКакВЗаявке)-len(replace(R.РегионПроживанияКакВЗаявке,',','')) >= 1
					and nullif(trim(R.РегионПроживанияКакВЗаявке),'') is not null
			) AS T
			OUTER APPLY Stg.dbo.tvf_GetAddressWithPartsPvt(T.РегионПроживанияКакВЗаявке) AS A
		) AS B
		--Регион есть в справочнике hub.БизнесРегион
		LEFT JOIN hub.БизнесРегион AS BR1 ON BR1.Наименование = B.Страна
		LEFT JOIN hub.БизнесРегион AS BR2 ON BR2.Наименование = B.[Почтовый индекс]
		LEFT JOIN hub.БизнесРегион AS BR3 ON BR3.Наименование = B.Регион

		--скорректированный Регион есть в справочнике hub.БизнесРегион
		LEFT JOIN dbo.КорректировкаРегионПроживанияКакВЗаявке AS C1
			ON C1.РегионПроживанияКакВЗаявке = B.Страна
		LEFT JOIN dbo.КорректировкаРегионПроживанияКакВЗаявке AS C2
			ON C2.РегионПроживанияКакВЗаявке = B.[Почтовый индекс]
		LEFT JOIN dbo.КорректировкаРегионПроживанияКакВЗаявке AS C3
			ON C3.РегионПроживанияКакВЗаявке = B.Регион
	WHERE coalesce(BR1.Наименование, BR2.Наименование, BR3.Наименование,
			C1.РегионПроживания, C2.РегионПроживания, C3.РегионПроживания
			) IS NOT NULL

	CREATE INDEX ix1 ON #t_Регион(GuidЗаявки)

	--добавить корректировку
	INSERT #t_Регион(GuidЗаявки, Регион)
	SELECT R.GuidЗаявки, C.РегионПроживания
	FROM #t_Заявка AS R
		INNER JOIN dbo.КорректировкаРегионПроживанияКакВЗаявке AS C
			ON C.РегионПроживанияКакВЗаявке = R.РегионПроживанияКакВЗаявке
	WHERE 1=1
		and not EXISTS(SELECT TOP(1) 1 FROM #t_Регион AS X WHERE X.GuidЗаявки = R.GuidЗаявки)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Регион
		SELECT * INTO ##t_Регион FROM #t_Регион AS T
		--RETURN 0
	END

	UPDATE R
	SET РегионПроживанияКакВЗаявке = A.Регион
	FROM #t_Заявка AS R
		inner JOIN #t_Регион AS A
			ON A.GuidЗаявки = R.GuidЗаявки

	--только регионы из справочника
	UPDATE R
	SET РегионПроживанияКакВЗаявке = NULL
	FROM #t_Заявка AS R
		LEFT JOIN hub.БизнесРегион AS BR ON BR.Наименование = R.РегионПроживанияКакВЗаявке
	where BR.Наименование is null

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Заявка
		SELECT * INTO ##t_Заявка FROM #t_Заявка AS T
		--RETURN 0
	END

	--de dublicate
	;with cte_dublicate as  (
		select nRow =  Row_Number() over(partition by GuidЗаявки order by updated_at desc), *
		from #t_Заявка
	)
	delete from cte_dublicate 
	where nRow>1

	if OBJECT_ID('link.ЗаявкаНаЗаймПодПТС_stage') is null
	begin
		create table link.ЗаявкаНаЗаймПодПТС_stage(
			Id					uniqueidentifier not null primary key default newid(),
			GuidЗаявки			uniqueidentifier not null,
			ВерсияДанныхЗаявки  binary(8),
			LinkName			nvarchar(255),
			LinkGuid			uniqueidentifier,
			TargetColName		nvarchar(255),
			created_at			datetime not null default getdate()
		)
		create index ix_LinkName on link.ЗаявкаНаЗаймПодПТС_stage(LinkName)

		ALTER TABLE link.ЗаявкаНаЗаймПодПТС_stage
		ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_stage
		PRIMARY KEY CLUSTERED (Id)
	END
    
	--линки из Заявка_CRM
	insert into link.ЗаявкаНаЗаймПодПТС_stage(
		GuidЗаявки
		,ВерсияДанныхЗаявки
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		GuidЗаявки,
		ВерсияДанныхЗаявки =  ВерсияДанных_CRM,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_Заявка_CRM
	CROSS APPLY (
    VALUES 
          (Link_GuidКредитныйПродукт,   'link.КредитныйПродукт_Заявка',	'GuidКредитныйПродукт')
        , (Link_GuidВидЗаполнения, 'link.ВидЗаполненияЗаявокНаЗаймПодПТС_Заявка', 'GuidВидЗаполненияЗаявокНаЗаймПодПТС')
        , (Link_GuidВариантПредложенияСтавки, 'link.ВариантыПредложенияСтавки_Заявка','GuidВариантПредложенияСтавки')
		, (Link_GuidМаркаМашины, 'link.МаркиАвтомобилей_Заявка', 'GuidМаркаМашины')
		, (Link_GuidМодельАвтомобиля, 'link.МоделиАвтомобилей_Заявка', 'GuidМодельАвтомобиля')
		, (Link_GuidТекущийСтатусЗаявки, 'link.ТекущийСтатус_Заявка', 'GuidТекущийСтатусЗаявки')
		, (Link_GuidCRM_Автор, 'link.CRMАвтор_Заявка', 'GuidCRMАвтор')
		, (Link_GuidПричинаОтказа, 'link.ПричиныОтказов_Заявка', 'GuidПричинаОтказа')
		, (Link_GuidКлиент, 'link.Клиент_Заявка', 'GuidКлиент')
		, (Link_GuidСпособОформления, 'link.СпособОформления_Заявка', 'GuidСпособОформления')
		, (Link_GuidОфис, 'link.Офис_Заявка', 'GuidОфис')
		, (Link_GuidСпособВыдачиЗайма, 'link.СпособВыдачиЗайма_Заявка', 'GuidСпособВыдачиЗайма')

		, (Link_GuidТипКредитногоПродукта, 'link.ТипКредитногоПродукта_Заявка', 'GuidТипКредитногоПродукта')
		, (Link_GuidПодТипКредитногоПродукта, 'link.ПодТипКредитногоПродукта_Заявка', 'GuidПодТипКредитногоПродукта')

		, (Link_GuidБизнесРегион, 'link.БизнесРегион_Заявка', 'GuidБизнесРегион')
		
		) t(LinkGuid, LinkName,  TargetColName)
		where LinkGuid is not null



	/*
	--линки из Заявка_FEDOR
	--1
	insert into link.ЗаявкаНаЗаймПодПТС_stage(
		GuidЗаявки
		,ВерсияДанныхЗаявки
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		F.GuidЗаявки,
		ВерсияДанныхЗаявки =  F.RowVersion_FEDOR,
		t.LinkName,
		t.LinkGuid,
		t.TargetColName
	from #t_Заявка_FEDOR AS F
	CROSS APPLY (
    VALUES 
		(Link_GuidТекущийСтатусЗаявки, 'link.ТекущийСтатус_Заявка', 'GuidТекущийСтатусЗаявки')
		--, (Link_GuidБизнесРегион, 'link.БизнесРегион_Заявка', 'GuidБизнесРегион')
		) t(LinkGuid, LinkName,  TargetColName)
	WHERE LinkGuid is not NULL
		--приоритет за CRM 
		AND NOT EXISTS(
			SELECT TOP(1) 1 
			FROM #t_Заявка_CRM AS X
			WHERE X.GuidЗаявки = F.GuidЗаявки
				AND X.Link_GuidТекущийСтатусЗаявки IS NOT NULL
		)

	--2
	insert into link.ЗаявкаНаЗаймПодПТС_stage(
		GuidЗаявки
		,ВерсияДанныхЗаявки
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		F.GuidЗаявки,
		ВерсияДанныхЗаявки =  F.RowVersion_FEDOR,
		t.LinkName,
		t.LinkGuid,
		t.TargetColName
	from #t_Заявка_FEDOR AS F
	CROSS APPLY (
    VALUES 
		--(Link_GuidТекущийСтатусЗаявки, 'link.ТекущийСтатус_Заявка', 'GuidТекущийСтатусЗаявки')
		(Link_GuidБизнесРегион, 'link.БизнесРегион_Заявка', 'GuidБизнесРегион')

		) t(LinkGuid, LinkName,  TargetColName)
	WHERE LinkGuid is not NULL
		--приоритет за CRM 
		AND NOT EXISTS(
			SELECT TOP(1) 1 
			FROM #t_Заявка_CRM AS X
			WHERE X.GuidЗаявки = F.GuidЗаявки
				AND X.Link_GuidБизнесРегион IS NOT NULL
		)
	*/


	-- общие линки из всех систем
	drop table if exists #t_link

	select distinct 
		СсылкаЗаявки = coalesce(CRM.СсылкаЗаявки, LK.СсылкаЗаявки, FEDOR.СсылкаЗаявки)
		,НомерЗаявки = coalesce(CRM.НомерЗаявки, LK.НомерЗаявки, FEDOR.НомерЗаявки)
		,GuidЗаявки = coalesce(CRM.GuidЗаявки, LK.GuidЗаявки, FEDOR.GuidЗаявки)
		,ВерсияДанныхЗаявки = cast(0x0 as binary(8))
		,Link_GuidТекущийСтатусЗаявки = coalesce(CRM.Link_GuidТекущийСтатусЗаявки, LK.Link_GuidТекущийСтатусЗаявки, FEDOR.Link_GuidТекущийСтатусЗаявки)
		,Link_GuidБизнесРегион = coalesce(CRM.Link_GuidБизнесРегион, LK.Link_GuidБизнесРегион, FEDOR.Link_GuidБизнесРегион)
		,Link_GuidТипКредитногоПродукта = coalesce(CRM.Link_GuidТипКредитногоПродукта, LK.Link_GuidТипКредитногоПродукта, FEDOR.Link_GuidТипКредитногоПродукта)
		,Link_GuidПодТипКредитногоПродукта = coalesce(CRM.Link_GuidПодТипКредитногоПродукта, LK.Link_GuidПодТипКредитногоПродукта, FEDOR.Link_GuidПодТипКредитногоПродукта)
	into #t_link
	FROM #t_Заявка_CRM AS CRM
		FULL OUTER JOIN #t_Заявка_LK AS LK
			ON LK.GuidЗаявки = CRM.GuidЗаявки
		FULL OUTER JOIN #t_Заявка_FEDOR AS FEDOR
			ON FEDOR.GuidЗаявки = isnull(CRM.GuidЗаявки, LK.GuidЗаявки)

	CREATE INDEX ix1 ON #t_link(GuidЗаявки)

	--DWH-278 если "тип продукта" не определен раньше, проставить на основе след логики:
	--1. isInstallment = 1 -> Инстолмент
	update l set Link_GuidТипКредитногоПродукта = t.GuidТипКредитногоПродукта
	from #t_link as l
		inner join #t_Заявка as r
			on r.GuidЗаявки = l.GuidЗаявки
			and r.isInstallment = 1
		inner join hub.ТипКредитногоПродукта as t
			on t.Код = 'installment'
	where l.Link_GuidТипКредитногоПродукта is null

	--2. _LK.requests.is_need_pts = 1 -> ПТС
	update l set Link_GuidТипКредитногоПродукта = t.GuidТипКредитногоПродукта
	from #t_link as l
		--inner join #t_Заявка as r
		--	on r.GuidЗаявки = l.GuidЗаявки
		--	and r.isPts = 1
		inner join Stg._LK.requests AS r
			on r.guid = cast(l.GuidЗаявки as nvarchar(36))
			and is_need_pts = 1
		inner join hub.ТипКредитногоПродукта as t
			on t.Код = 'pts'
	where l.Link_GuidТипКредитногоПродукта is null

	--3. заявки до 11.2021г -> ПТС
	update l set Link_GuidТипКредитногоПродукта = t.GuidТипКредитногоПродукта
	from #t_link as l
		inner join #t_Заявка as r
			on r.GuidЗаявки = l.GuidЗаявки
			and r.ДатаЗаявки <= '2021-11-01'
		inner join hub.ТипКредитногоПродукта as t
			on t.Код = 'pts'
	where l.Link_GuidТипКредитногоПродукта is null
	--//если "тип продукта" не определен раньше...


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_link
		SELECT * INTO ##t_link FROM #t_link
		--RETURN 0
	END

	insert into link.ЗаявкаНаЗаймПодПТС_stage(
		GuidЗаявки
		,ВерсияДанныхЗаявки
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		GuidЗаявки,
		ВерсияДанныхЗаявки,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_link
	CROSS APPLY (
    VALUES 
		  (Link_GuidТекущийСтатусЗаявки, 'link.ТекущийСтатус_Заявка', 'GuidТекущийСтатусЗаявки')
		, (Link_GuidБизнесРегион, 'link.БизнесРегион_Заявка', 'GuidБизнесРегион')
		, (Link_GuidТипКредитногоПродукта, 'link.ТипКредитногоПродукта_Заявка', 'GuidТипКредитногоПродукта')
		, (Link_GuidПодТипКредитногоПродукта, 'link.ПодТипКредитногоПродукта_Заявка', 'GuidПодТипКредитногоПродукта')
	) t(LinkGuid, LinkName,  TargetColName)
	where LinkGuid is not null



	--линки из истории изменения Заявки
	DECLARE @updated_at datetime = '2000-01-01'

	if OBJECT_ID ('link.ОфисПервоначальный_Заявка') is not NULL
		AND @mode in (1,2)
	begin
		set @updated_at = isnull((select dateadd(DAY, -1, max(updated_at)) from link.ОфисПервоначальный_Заявка), '2000-01-01')
	END

	DROP TABLE IF EXISTS #t_ИсторияИзмененияЗаявки
	SELECT 
		A.СсылкаЗаявки,
		A.GuidЗаявки,
		A.Link_GuidОфисПервоначальный
	INTO #t_ИсторияИзмененияЗаявки
	FROM (
			SELECT 
				СсылкаЗаявки = РегистрИзменения.Заявка
				,GuidЗаявки = cast([dbo].[getGUIDFrom1C_IDRREF](РегистрИзменения.Заявка) as uniqueidentifier)
				,Link_GuidОфисПервоначальный = cast(nullif([dbo].[getGUIDFrom1C_IDRREF](РегистрИзменения.Офис), '00000000-0000-0000-0000-000000000000')	AS uniqueidentifier)
				,rn = row_number() OVER(PARTITION BY РегистрИзменения.Заявка ORDER BY РегистрИзменения.ДатаИзменения DESC)
			FROM Stg._1cCRM.РегистрСведений_ИзмененияВидаЗаполненияВЗаявках AS РегистрИзменения
			WHERE РегистрИзменения.ДатаИзменения >= dateadd(YEAR, 2000, @updated_at)
			and exists(select top(1) 1 from #t_Заявка Заявка  where Заявка .СсылкаЗаявки = РегистрИзменения.Заявка)
		) AS A
	WHERE A.rn = 1

	insert into link.ЗаявкаНаЗаймПодПТС_stage(
		GuidЗаявки
		,ВерсияДанныхЗаявки
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		A.GuidЗаявки,
		ВерсияДанныхЗаявки = 0x00,
		T.LinkName,
		T.LinkGuid,
		T.TargetColName
	from #t_ИсторияИзмененияЗаявки AS A
	CROSS APPLY (
		VALUES 
			(A.Link_GuidОфисПервоначальный, 'link.ОфисПервоначальный_Заявка', 'GuidОфисПервоначальный')
		) T(LinkGuid, LinkName,  TargetColName)
	WHERE T.LinkGuid is not null
	--// линки из истории изменения Заявки


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ЗаявкаНаЗаймПодПТС_stage
		SELECT * INTO ##t_ЗаявкаНаЗаймПодПТС_stage FROM link.ЗаявкаНаЗаймПодПТС_stage
	END

	begin try
		--заполнение таблиц с линками
		BEGIN TRY
			IF @isDebug = 0 
				or 1=1
			BEGIN
				EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_ЗаявкаНаЗаймПодПТС_and_other'
			END
		END TRY
		BEGIN CATCH
			--??
		END CATCH
	end try
	begin catch
		/*нужно для обработки ошибки*/
	end catch



	--drop table hub.Заявка
	--create clustered index cix on #t_Заявка(GuidЗаявки)
	if OBJECT_ID('hub.Заявка') is null
	begin
	
		select top(0)
			СсылкаЗаявки
			,НомерЗаявки
			,GuidЗаявки
			,ДатаЗаявки
			,Фамилия
			,Имя
			,Отчество
			,ФИО
			,Пол
			,[ДатаРождения]
			,[Сумма заявки]
			,[ГодВыпускаТС]
			,[Оценочная Стоимость]
			,[Сумма Выданная]
			,isPts
			,isPdl
			,[isInstallment]
			,[isSmartInstallment]
			,[СуммарныйМесячныйДоход]
			,[ДомашнийТелефон]
			,[МобильныйТелефон]
			,[МобильныйТелефонКонтактногоЛица]
			,[НомераТелефоновБезСимволов]
			,[РабочийТелефон]
			,РегионПроживанияКакВЗаявке
			,[Сумма Первичная]
			,[Наличие Залога]
			,[Серия Паспорта]
			,[Номер Паспорта]
			,created_at							
			,updated_at				
			,[spFillName]						
			,ВерсияДанных_CRM
			,updated_at_LK
			,RowVersion_FEDOR
		into hub.Заявка
		from #t_Заявка

		alter table  hub.Заявка
			alter column СсылкаЗаявки binary(16) not null

		--alter table  hub.Заявка
		--	alter column НомерЗаявки nvarchar(14) not null

		alter table  hub.Заявка
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE  hub.Заявка
			ADD CONSTRAINT PK_hub_Заявка PRIMARY KEY CLUSTERED (GuidЗаявки)
	end 
	
	--begin tran
		merge hub.Заявка AS t
		using #t_Заявка AS s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки
			,НомерЗаявки
			,GuidЗаявки							
			,ДатаЗаявки							
			,Фамилия							
			,Имя								
			,Отчество							
			,ФИО								
			,Пол
			,[ДатаРождения]						
			,[Сумма заявки]						
			,[ГодВыпускаТС]						
			,[Оценочная Стоимость]				
			,[Сумма Выданная]					
			,isPts
			,isPdl
			,[isInstallment]					
			,[isSmartInstallment]				
			,[СуммарныйМесячныйДоход]			
			,[ДомашнийТелефон]					
			,[МобильныйТелефон]					
			,[МобильныйТелефонКонтактногоЛица]	
			,[НомераТелефоновБезСимволов]		
			,[РабочийТелефон]
			,РегионПроживанияКакВЗаявке
			,[Сумма Первичная]
			,[Наличие Залога]
			,[Серия Паспорта]
			,[Номер Паспорта]
			,created_at							
			,updated_at			
			,[spFillName]						
			,ВерсияДанных_CRM
			,updated_at_LK
			,RowVersion_FEDOR
		) values
		(
			s.СсылкаЗаявки
			,s.НомерЗаявки
			,s.GuidЗаявки
			,s.ДатаЗаявки
			,s.Фамилия
			,s.Имя
			,s.Отчество
			,s.ФИО
			,s.Пол
			,s.[ДатаРождения]
			,s.[Сумма заявки]						
			,s.[ГодВыпускаТС]						
			,s.[Оценочная Стоимость]				
			,s.[Сумма Выданная]					
			,s.isPts
			,s.isPdl
			,s.[isInstallment]					
			,s.[isSmartInstallment]				
			,s.[СуммарныйМесячныйДоход]			
			,s.[ДомашнийТелефон]					
			,s.[МобильныйТелефон]					
			,s.[МобильныйТелефонКонтактногоЛица]	
			,s.[НомераТелефоновБезСимволов]		
			,s.[РабочийТелефон]
			,s.РегионПроживанияКакВЗаявке
			,s.[Сумма Первичная]
			,s.[Наличие Залога]
			,s.[Серия Паспорта]
			,s.[Номер Паспорта]
			,s.created_at							
			,s.updated_at
			,s.[spFillName]						
			,s.ВерсияДанных_CRM
			,s.updated_at_LK
			,s.RowVersion_FEDOR
		)
		when matched and (
				isnull(t.ВерсияДанных_CRM, 0x0) <> isnull(s.ВерсияДанных_CRM, 0x0)
				OR isnull(t.updated_at_LK, '2000-01-01') <> isnull(s.updated_at_LK, '2000-01-01')
				OR isnull(t.RowVersion_FEDOR, 0x0) <> isnull(s.RowVersion_FEDOR, 0x0)
				OR @mode in (0, 2)
				OR @Guids is NOT NULL
			)
		then update SET
			t.СсылкаЗаявки							= s.СсылкаЗаявки
			,t.НомерЗаявки							= s.НомерЗаявки
			,t.ДатаЗаявки							= s.ДатаЗаявки
			,t.Фамилия								= s.Фамилия
			,t.Имя									= s.Имя
			,t.Отчество								= s.Отчество
			,t.ФИО									= s.ФИО
			,t.Пол									= s.Пол
			,t.[ДатаРождения]						= s.[ДатаРождения]
			,t.[Сумма заявки]						= s.[Сумма заявки]						
			,t.[ГодВыпускаТС]						= s.[ГодВыпускаТС]						
			,t.[Оценочная Стоимость]				= s.[Оценочная Стоимость]				
			,t.[Сумма Выданная]						= s.[Сумма Выданная]						
			,t.isPts								= s.isPts
			,t.isPdl								= s.isPdl
			,t.[isInstallment]						= s.[isInstallment]						
			,t.[isSmartInstallment]					= s.[isSmartInstallment]					
			,t.[СуммарныйМесячныйДоход]				= s.[СуммарныйМесячныйДоход]				
			,t.[ДомашнийТелефон]					= s.[ДомашнийТелефон]					
			,t.[МобильныйТелефон]					= s.[МобильныйТелефон]					
			,t.[МобильныйТелефонКонтактногоЛица]	= s.[МобильныйТелефонКонтактногоЛица]	
			,t.[НомераТелефоновБезСимволов]			= s.[НомераТелефоновБезСимволов]			
			,t.[РабочийТелефон]						= s.[РабочийТелефон]						
			,t.РегионПроживанияКакВЗаявке			= s.РегионПроживанияКакВЗаявке
			,t.[Сумма Первичная]					= s.[Сумма Первичная]
			,t.[Наличие Залога]						= s.[Наличие Залога]
			,t.[Серия Паспорта]						= s.[Серия Паспорта]
			,t.[Номер Паспорта]						= s.[Номер Паспорта]
			,t.updated_at							= s.updated_at
			,t.ВерсияДанных_CRM						= s.ВерсияДанных_CRM
			,t.updated_at_LK						= s.updated_at_LK
			,t.RowVersion_FEDOR						= s.RowVersion_FEDOR
			;
	--commit tran

	if @mode = 2 begin
		delete i
		from dbo.СписокЗаявокДляПересчетаDataVault as i
			inner join #t_СписокЗаявокДляПересчетаDataVault as t
				on t.GuidЗаявки = i.GuidЗаявки
	end

end try
begin catch
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	SELECT @message = concat('exec ', @spName)

	SELECT @eventType = 'Data Valut ERROR'

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @spName,
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 1,
		@SendToSlack = 1

	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch


end