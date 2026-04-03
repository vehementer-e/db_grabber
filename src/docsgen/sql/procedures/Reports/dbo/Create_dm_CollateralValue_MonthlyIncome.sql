-- =============================================
-- Author:		А. Никитин
-- Create date: 2023-02-03
-- Description:	DWH-1922. Заполнение витрины dbo.dm_CollateralValue_MonthlyIncome
-- =============================================
CREATE   PROC dbo.Create_dm_CollateralValue_MonthlyIncome
	@ProcessGUID varchar(36) = NULL,
	@isDebug int = 0,
	@report_date date = NULL
as
begin
SET XACT_ABORT ON

DECLARE @StartDate datetime, @row_count int
DECLARE @ProcStartDate datetime = getdate(), @DurationSec int, @InsertRows int = 0
DECLARE @description nvarchar(1024), @message nvarchar(1024)
DECLARE @error_description nvarchar(1024)

SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
SELECT @isDebug = isnull(@isDebug, 0)
SELECT @report_date = isnull(@report_date, cast(getdate() as date))

BEGIN TRY

	DROP table if exists #active_cmr
	CREATE TABLE #active_cmr(НомерДоговора varchar(21))

	SELECT @StartDate = getdate(), @row_count = 0

	INSERT #active_cmr(НомерДоговора)
	select b.external_id НомерДоговора -- iif(b.external_id  is null, 0,1) as 'Активный' 
	from dbo.dm_CMRStatBalance_2 AS b (NOLOCK)
		INNER JOIN Stg._1cCMR.Справочник_Договоры AS d (NOLOCK)
			ON b.external_id = d.Код
	where b.d = @report_date --cast(getdate() as date)
		--DWH-1922
		AND isnull(d.IsInstallment, 0) = 0
		AND isnull(d.IsSmartInstallment, 0) = 0

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #active_cmr', @row_count, datediff(SECOND, @StartDate, getdate())
	END


	-- 1350 Найдем тип договора
	SELECT @StartDate = getdate(), @row_count = 0

	drop table if exists #type_loan
	CREATE TABLE #type_loan
	(
		return_type nvarchar(100),
		НомерЗаявки nvarchar(14),
		Номер nchar(14),
		rn bigint
	)

	INSERT #type_loan
	(
		return_type,
		НомерЗаявки,
		Номер,
		rn
	)
	select 
		case when a.Докредитование=0xB3603565B63EB9B14723A40BFBC73122 then N'Докредитование'  -- Докредитование
		 when a.Докредитование=0xA8424EE85197CF54453F1F80BDC849D5 then N'Параллельный' -- Параллельный заем
		 when a.[ВидЗайма]=0x974A656AFB7A557B48A6B58E3DECA593     then N'Новый' -- Новый
		 when a.[ВидЗайма]=0xB201F1B23D6AB42947A9828895F164FE     then N'Повторный'
		 else N'' end return_type
		 ,a.НомерЗаявки
		 ,a.Номер
		 ,rn = ROW_NUMBER() over (partition by a.НомерЗаявки order by (select null))
	from Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS a (NOLOCK)
		--DWH-1922
		INNER JOIN #active_cmr AS a_cmr
			ON a_cmr.НомерДоговора = a.НомерЗаявки

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #type_loan', @row_count, datediff(SECOND, @StartDate, getdate())
	END

		delete from #type_loan
		where rn>1


	SELECT @StartDate = getdate(), @row_count = 0

	drop table if exists #cmr
	CREATE TABLE #cmr
	(
		[ПометкаУдаления] binary(1),
		[CMR.НомерДоговора] nvarchar(14),
		ДатаДоговора date,
		[Фамилия] nvarchar(150),
		[Имя] nvarchar(150),
		[Отчество] nvarchar(150),
		[ДатаРождения] datetime2(0),
		[ПаспортСерия] nvarchar(4),
		[ПаспортНомер] nvarchar(6),
		[СMR.СтоимостьТС] numeric(15, 2),
		rn0 bigint
	)

	INSERT #cmr
	(
		ПометкаУдаления,
		[CMR.НомерДоговора],
		ДатаДоговора,
		Фамилия,
		Имя,
		Отчество,
		ДатаРождения,
		ПаспортСерия,
		ПаспортНомер,
		[СMR.СтоимостьТС],
		rn0
	)
	SELECT 
		  d.[ПометкаУдаления] 
		  ,d.[Код]    [CMR.НомерДоговора]
		  ,cast(dateadd(year, -2000,d.Дата) as date) ДатаДоговора
		  ,d.[Фамилия]
		  ,d.[Имя]
		  ,d.[Отчество]
		  ,d.[ДатаРождения]   
		  ,d.[ПаспортСерия]
		  ,d.[ПаспортНомер]     
		  ,z.СтоимостьТС as [СMR.СтоимостьТС]
		 -- ,iif(b.external_id  is null, 0,1) as 'Активный'
		  --,b2.external_id
		  --, rn0 = ROW_NUMBER() over (partition by d.[Код] order by isnull (z.СтоимостьТС , -1) desc)
		  , rn0 = 1
	  FROM [Stg].[_1cCMR].[Справочник_Договоры] AS d (NOLOCK)
		left join [Stg].[_1cCMR].[Справочник_Заявка] AS z (NOLOCK)
			ON d.[Заявка] = z.Ссылка
		--DWH-1922
		INNER JOIN #active_cmr AS a_cmr
			ON a_cmr.НомерДоговора = d.[Код]

	  --select * from #cmr where rn>1

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #cmr', @row_count, datediff(SECOND, @StartDate, getdate())
	END



	SELECT @StartDate = getdate(), @row_count = 0

	-- 2021-08-23 добавили проверку выдачи денежных средств
	drop table if exists #active_cmr_vidan
	CREATE TABLE #active_cmr_vidan
	(
		НомерДоговора nvarchar(14),
		ДатаВыдачи datetime2(0),
		СуммаВыдачи numeric(10, 2)
	)

	INSERT #active_cmr_vidan
	(
		НомерДоговора,
		ДатаВыдачи
	)
	select d.Код AS НомерДоговора
		--, dateadd(year, -2000, max(vds.ДатаВыдачи)) AS ДатаВыдачи
		, max(vds.ДатаВыдачи) AS ДатаВыдачи
	FROM [Stg].[_1cCMR].[Справочник_Договоры] AS d (NOLOCK)
		join [Stg].[_1cCMR].[Документ_ВыдачаДенежныхСредств] AS vds (NOLOCK)
			ON d.Ссылка = vds.Договор
		--DWH-1922
		INNER JOIN #active_cmr AS a_cmr
			ON a_cmr.НомерДоговора = d.[Код]
	where vds.Проведен=1
		and vds.ПометкаУдаления=0
	group by d.Код

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #active_cmr_vidan', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	UPDATE V
	SET V.СуммаВыдачи = vds.Сумма
	FROM #active_cmr_vidan AS V
		INNER JOIN Stg._1cCMR.Справочник_Договоры AS d (NOLOCK)
			ON d.Код = V.НомерДоговора
		INNER JOIN Stg._1cCMR.Документ_ВыдачаДенежныхСредств AS vds (NOLOCK)
			ON vds.Договор = d.Ссылка
			AND vds.ДатаВыдачи = V.ДатаВыдачи
			AND vds.Проведен=1
			AND vds.ПометкаУдаления=0

	-- -2000 year
	UPDATE V
	SET ДатаВыдачи = dateadd(year, -2000, V.ДатаВыдачи)
	FROM #active_cmr_vidan AS V

	SELECT @StartDate = getdate(), @row_count = 0

	drop table if exists #umfo
	CREATE TABLE #umfo
	(
		[УМФО.НомерДоговора] nvarchar(50),
		[УМФО.ЗалоговаяСтоимость] numeric(15, 2),
		[УМФО.СправедливаяСтоимость] numeric(15, 2),
		[УМФО.РыночнаяСтоимость] numeric(15, 2),
		rn bigint
	)

	INSERT #umfo
	(
		[УМФО.НомерДоговора],
		[УМФО.ЗалоговаяСтоимость],
		[УМФО.СправедливаяСтоимость],
		[УМФО.РыночнаяСтоимость],
		rn
	)
	SELECT 
		za.НомерДоговора [УМФО.НомерДоговора],
		oz.ЗалоговаяСтоимость as [УМФО.ЗалоговаяСтоимость],
		oz.СправедливаяСтоимость as [УМФО.СправедливаяСтоимость],
		oz.РыночнаяСтоимость as [УМФО.РыночнаяСтоимость]
		,rn = row_number() 
		OVER (
			PARTITION BY za.Ссылка
			ORDER BY z.Дата, oz.ЗалоговаяСтоимость desc, oz.СправедливаяСтоимость desc,	oz.РыночнаяСтоимость DESC
		)
	FROM [Stg].[_1cUMFO].[Документ_АЭ_ДоговорЗалога] z (NOLOCK)
		join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный za (NOLOCK)
			ON z.Займ = za.Ссылка
		join [Stg].[_1cUMFO].[Документ_АЭ_ДоговорЗалога_ОбъектыЗалога] oz (NOLOCK)
			ON oz.Ссылка = z.Ссылка
		--DWH-1922
		INNER JOIN #active_cmr AS a_cmr
			ON a_cmr.НомерДоговора = za.НомерДоговора
	where z.ПометкаУдаления = 0x00
		and za.ПометкаУдаления = 0x00

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #umfo', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	   delete from #umfo where rn>1
	 --  where Идентификатор is not null


	SELECT @StartDate = getdate(), @row_count = 0

	   --- федор
	drop table if exists #feodor
	CREATE TABLE #feodor
	(
		[Feodor.НомерДоговора] nvarchar(255),
		[Федор.Оценочная стоимость автомобиля] numeric(18, 2),  -- 1 Оценочная стоимость автомобия
		[Федор.Рыночная стоимость на момент оценки] numeric(18, 2), -- 2 Рыночная стоимость на момент оценки
		[Федор.Рыночная стоимость от логинома] numeric(18, 2), -- 3 Рыночная стоимость от логинома
		[Федор.TsPrice] numeric(18, 2),
		[Федор.доход по справке] numeric(18, 2), -- доход по справке
		[Федор.доход Росстат] numeric(18, 2), -- доход Росстат
		[Федор.Доход из БКИ] numeric(18, 2), -- Доход из БКИ
		[Федор.Месячный доход] numeric(18, 2), -- Месячный доход
		[Федор.Дополнительный доход] numeric(18, 2), -- Дополнительный доход  
	)

	INSERT #feodor
	(
		[Feodor.НомерДоговора],
		[Федор.Оценочная стоимость автомобиля],
		[Федор.Рыночная стоимость на момент оценки],
		[Федор.Рыночная стоимость от логинома],
		[Федор.TsPrice],
		[Федор.доход по справке],
		[Федор.доход Росстат],
		[Федор.Доход из БКИ],
		[Федор.Месячный доход],
		[Федор.Дополнительный доход]
	)
	SELECT  
		-- [Id]
		--,
		R.[Number] COLLATE Cyrillic_General_CI_AS AS [Feodor.НомерДоговора] 
		-- Клиент
		--,[ClientFirstName]
		--,[ClientLastName]
		--,[ClientMiddleName]
		--,[ClientBirthDay]
		--,[ClientPhoneMobile]     
		--,[ClientPassportSerial]
		--,[ClientPassportNumber]   

		-- Залог стоимость
		,R.[CarEstimationPrice]  as [Федор.Оценочная стоимость автомобиля]  -- 1 Оценочная стоимость автомобия
		,R.[TsMarketPrice]  as [Федор.Рыночная стоимость на момент оценки] -- 2 Рыночная стоимость на момент оценки
		,R.[LoginomMarketPrice] as [Федор.Рыночная стоимость от логинома] -- 3 Рыночная стоимость от логинома
		,R.[TsPrice] as [Федор.TsPrice]
		--,[TotalExpense]   
		-- доход
		,R.ReferenceIncome as [Федор.доход по справке] -- доход по справке
		,R.RosstatIncome as [Федор.доход Росстат] -- доход Росстат
		,R.BkiIncome as [Федор.Доход из БКИ] -- Доход из БКИ
		,R.ClientMonthlyIncome as [Федор.Месячный доход] -- Месячный доход
		,R.ClientIncomeAdditional as [Федор.Дополнительный доход] -- Дополнительный доход  

		--,[CreatedOn]
		--,[IdOwner]
		--,[IsDeleted]
		--,[IdStatus]
		--,[IdClient]
	
		----сам предмет залога
		--,[Vin]
		--,[DateReturn]
		--,[IdTsBrand]
		--,[IdTsModel]
		--,[TsYear]
	FROM Stg._fedor.core_ClientRequest AS R (NOLOCK)
		--DWH-1922
		INNER JOIN #active_cmr AS a_cmr
			ON a_cmr.НомерДоговора = convert(varchar(21), R.[Number] COLLATE Cyrillic_General_CI_AS)

	  --select top 100 * from #feodor

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #feodor', @row_count, datediff(SECOND, @StartDate, getdate())
	END



	SELECT @StartDate = getdate(), @row_count = 0

	  --- Эдо
	-- dwh-1404
	drop table if exists #t1_edo
	CREATE TABLE #t1_edo
	(
		СсылкаНаПараметрЗаявления binary(16),
		ПараметрЗаявления nvarchar(150), 
		СтрокаЗначениеПараметраЗаявления nvarchar(1024),
		ДатаПараметраЗаявления datetime2(0), 
		ЧислоЗначениеПараметраЗаявления numeric(15, 3),
		СсылкаНаДетальныйПарметр binary(16)
	)
 
	INSERT #t1_edo
	(
		СсылкаНаПараметрЗаявления,
		ПараметрЗаявления,
		СтрокаЗначениеПараметраЗаявления,
		ДатаПараметраЗаявления,
		ЧислоЗначениеПараметраЗаявления,
		СсылкаНаДетальныйПарметр
	)
	SELECT a.Ссылка as СсылкаНаПараметрЗаявления, 
			b.Наименование as ПараметрЗаявления, 
			a.Значение_Строка AS СтрокаЗначениеПараметраЗаявления,
			a.Значение_Дата AS ДатаПараметраЗаявления, 
			a.Значение_Число AS ЧислоЗначениеПараметраЗаявления,
			a.[Значение_Ссылка] AS СсылкаНаДетальныйПарметр 
	from stg.[_1cDCMNT].[Справочник_ВнутренниеДокументы_ДополнительныеРеквизиты] AS a (NOLOCK)
		join stg.[_1cDCMNT].[ПланВидовХарактеристик_ДополнительныеРеквизитыИСведения] AS b (NOLOCK)
			ON a.Свойство=b.ссылка

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #t1_edo', @row_count, datediff(SECOND, @StartDate, getdate())
	END


	SELECT @StartDate = getdate(), @row_count = 0

	drop table if exists #edo
	CREATE TABLE #edo
	(
	[ЭДО.НомерДоговора] nvarchar(1024),
	[ЭДО.ЕжемесячныйДоход] numeric(15, 3),
	[ЭДО.ОценочнаяСтоимость] numeric(15, 3),
	[ЭДО.РыночнаяСтоимость] numeric(15, 3),
	rn1 bigint
	)

	INSERT #edo
	(
		[ЭДО.НомерДоговора],
		[ЭДО.ЕжемесячныйДоход],
		[ЭДО.ОценочнаяСтоимость],
		[ЭДО.РыночнаяСтоимость],
		rn1
	)
	select m.[ЭДО.НомерДоговора],
		m.[ЭДО.ЕжемесячныйДоход],
		m.[ЭДО.ОценочнаяСтоимость],
		m.[ЭДО.РыночнаяСтоимость],
		m.rn1 
	from
		(
		select 
		dogovor.СтрокаЗначениеПараметраЗаявления [ЭДО.НомерДоговора], 
		dohod.ЧислоЗначениеПараметраЗаявления as [ЭДО.ЕжемесячныйДоход],
		stoimost.ЧислоЗначениеПараметраЗаявления as [ЭДО.ОценочнаяСтоимость],
		stoimost2.ЧислоЗначениеПараметраЗаявления as [ЭДО.РыночнаяСтоимость],
		rn1 = row_number() 
			OVER(
				PARTITION BY dogovor.СтрокаЗначениеПараметраЗаявления 
				ORDER BY 
					isnull(dohod.ЧислоЗначениеПараметраЗаявления, -1) desc,
					isnull(stoimost.ЧислоЗначениеПараметраЗаявления, -1) desc,
					isnull(stoimost2.ЧислоЗначениеПараметраЗаявления, -1) DESC
			)
		from #t1_edo dogovor 
		--DWH-1922
		INNER JOIN #active_cmr AS a_cmr
			ON a_cmr.НомерДоговора = dogovor.СтрокаЗначениеПараметраЗаявления
		left join #t1_edo AS dohod 
			ON dogovor.СсылкаНаПараметрЗаявления=dohod.СсылкаНаПараметрЗаявления 
			AND dohod.ПараметрЗаявления='Ежемесячный доход (Заем)'
		left join #t1_edo AS stoimost 
			ON dogovor.СсылкаНаПараметрЗаявления=stoimost.СсылкаНаПараметрЗаявления 
			AND stoimost.ПараметрЗаявления='Оценочная стоимость авто (Заем)'
		left join #t1_edo AS stoimost2 
			ON dogovor.СсылкаНаПараметрЗаявления=stoimost2.СсылкаНаПараметрЗаявления 
			AND stoimost2.ПараметрЗаявления='Рыночная стоимость авто (Заем)'
		where dogovor.ПараметрЗаявления = 'Номер заявки (Заем)'
		) AS m
	WHERE m.rn1=1

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #edo', @row_count, datediff(SECOND, @StartDate, getdate())
	END


	SELECT @StartDate = getdate(), @row_count = 0

	-- нумерация по старым договорам с лидирующим нулем
	update #edo
	set [ЭДО.НомерДоговора] = Right([ЭДО.НомерДоговора], Len([ЭДО.НомерДоговора])-1)
	where LEFT([ЭДО.НомерДоговора],1) = '0'

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'update #edo', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	SELECT @StartDate = getdate(), @row_count = 0

	;with
	dubli_edo as
	(
		select *, rn = ROW_NUMBER() over( partition by [ЭДО.НомерДоговора] order by [ЭДО.ОценочнаяСтоимость],[ЭДО.РыночнаяСтоимость])
		from #edo
	)
	delete from dubli_edo where rn >1

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'delete dubli_edo', @row_count, datediff(SECOND, @StartDate, getdate())
	END


	SELECT @StartDate = getdate(), @row_count = 0

	-- Спейс
	drop table if exists #space
	CREATE TABLE #space
	(
		[Спейс.НомерДоговора] nvarchar(255),
		[Спейс.Оценочная стоимость] money,
		[Спейс.Рыночная стоимость] money,
		[Спейс.Среднемесячный доход] decimal(10, 2),
		[Спейс.Зарплата] numeric(9, 2),
		rn2 bigint
	)

	INSERT #space
	(
		[Спейс.НомерДоговора],
		[Спейс.Оценочная стоимость],
		[Спейс.Рыночная стоимость],
		[Спейс.Среднемесячный доход],
		[Спейс.Зарплата],
		rn2
	)
	select 
		m.[Спейс.НомерДоговора],
		m.[Спейс.Оценочная стоимость],
		m.[Спейс.Рыночная стоимость],
		m.[Спейс.Среднемесячный доход],
		m.[Спейс.Зарплата],
		m.rn2 
	from
		(
		SELECT
			Deal.Number [Спейс.НомерДоговора],
			pl.AssessedPrice AS 'Спейс.Оценочная стоимость',
			pl.MarketPrice AS 'Спейс.Рыночная стоимость',
			ex.AvgMonthlyIncome AS 'Спейс.Среднемесячный доход',
			pow.Salary AS 'Спейс.Зарплата'
			,rn2 = row_number()
				OVER(
					PARTITION BY Deal.Number 
					ORDER BY pl.AssessedPrice desc, pl.MarketPrice desc, ex.AvgMonthlyIncome desc, pow.Salary DESC
				)
		FROM Stg._Collection.Deals AS Deal (NOLOCK)
			LEFT JOIN Stg._Collection.customers AS c (NOLOCK) ON c.Id = Deal.IdCustomer 
			LEFT JOIN [Stg].[_Collection].DealPledgeItem AS dpi (NOLOCK) ON dpi.DealId = Deal.Id
			LEFT JOIN [Stg].[_Collection].[PledgeItem] AS pl (NOLOCK) ON pl.Id = dpi.PledgeItemId 
			left join STG._Collection.IncomeExpensesCustomerInfo AS ex (NOLOCK) on ex.IdCustomer = c.Id
			left join stg._Collection.PlaceOfWork AS pow (NOLOCK) on pow.IdCustomer = c.id
			--DWH-1922
			INNER JOIN #active_cmr AS a_cmr
				ON a_cmr.НомерДоговора = Deal.Number
		) AS m 
	where m.rn2 =1

	--select * from #space where rn2 >1

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT '#space', @row_count, datediff(SECOND, @StartDate, getdate())
	END


	SELECT @StartDate = getdate(), @row_count = 0

	--- CRM
	drop table if exists #crm
	CREATE TABLE #crm
	(
		[CRM.ОценочнаяСтоимость] numeric(15, 2),
		[CRM.РыночнаяОценкаСтоимости] numeric(15, 0),
		[CRM.СуммарныйМесячныйДоход] numeric(10, 0),
		[CRM.Номер] nchar(14),
		rn_crm bigint
	)

	INSERT #crm
	(
		[CRM.ОценочнаяСтоимость],
		[CRM.РыночнаяОценкаСтоимости],
		[CRM.СуммарныйМесячныйДоход],
		[CRM.Номер],
		rn_crm
	)
	SELECT 
		--[Ссылка]
		--,
		R.[ОценочнаяСтоимость] as [CRM.ОценочнаяСтоимость],
		R.[РыночнаяОценкаСтоимости] as [CRM.РыночнаяОценкаСтоимости]
		,R.[СуммарныйМесячныйДоход] as [CRM.СуммарныйМесячныйДоход]
		,R.[Номер] as [CRM.Номер]
		--,[Проведен]
		--,[ПометкаУдаления]
		--,rn_crm = ROW_NUMBER() over(partition by R.[Ссылка] order by R.Дата desc)
		,rn_crm = 1
	FROM [Stg].[_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] AS R (NOLOCK)
		--DWH-1922
		INNER JOIN #active_cmr AS a_cmr
			ON a_cmr.НомерДоговора = R.Номер
	where R.ПометкаУдаления = 0x00 and R.[Проведен] = 0x00

	  --select * from #crm where rn_crm >1

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT '#crm', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	/*
	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS tmp.TMP_AND_CollateralValue_MonthlyIncome  -- #t_result

		select 
			cmr_a.НомерДоговора
			, cmr.ДатаДоговора
			, v.ДатаВыдачи
			, cmr.Фамилия 
			, cmr.Имя
			, cmr.Отчество
			, cmr.[СMR.СтоимостьТС]
			, umfo.[УМФО.ЗалоговаяСтоимость]
			, umfo.[УМФО.РыночнаяСтоимость]
			, umfo.[УМФО.СправедливаяСтоимость]
			, feodor.[Feodor.НомерДоговора],
			  feodor.[Федор.Оценочная стоимость автомобиля],
			  feodor.[Федор.Рыночная стоимость на момент оценки],
			  feodor.[Федор.Рыночная стоимость от логинома],
			  feodor.[Федор.TsPrice],
			  feodor.[Федор.доход по справке],
			  feodor.[Федор.доход Росстат],
			  feodor.[Федор.Доход из БКИ],
			  feodor.[Федор.Месячный доход],
			  feodor.[Федор.Дополнительный доход]
			, edo.[ЭДО.НомерДоговора],
			  edo.[ЭДО.ЕжемесячныйДоход],
			  edo.[ЭДО.ОценочнаяСтоимость],
			  edo.[ЭДО.РыночнаяСтоимость],
			  edo.rn1
			, spce.[Спейс.НомерДоговора],
			 spce.[Спейс.Оценочная стоимость],
			 spce.[Спейс.Рыночная стоимость],
			 spce.[Спейс.Среднемесячный доход],
			 spce.[Спейс.Зарплата],
			 spce.rn2
			, crm.[CRM.ОценочнаяСтоимость],
			  crm.[CRM.РыночнаяОценкаСтоимости],
			  crm.[CRM.СуммарныйМесячныйДоход],
			  crm.[CRM.Номер],
			  crm.rn_crm
			--into reports_CollateralValue_MonthlyIncome
			,t.return_type
		INTO tmp.TMP_AND_CollateralValue_MonthlyIncome
		from
		#active_cmr cmr_a
		left join #cmr cmr on cmr_a.НомерДоговора = cmr.[CMR.НомерДоговора]
		left join #umfo umfo on cmr_a.НомерДоговора = umfo.[УМФО.НомерДоговора]
		left join #feodor feodor on cmr_a.НомерДоговора = feodor.[Feodor.НомерДоговора]
		left join #edo edo on cmr_a.НомерДоговора = edo.[ЭДО.НомерДоговора]
		left join #space spce on cmr_a.НомерДоговора = spce.[Спейс.НомерДоговора]
		left join #crm crm on cmr_a.НомерДоговора = crm.[CRM.Номер]
		join #active_cmr_vidan  v on v.НомерДоговора = cmr_a.НомерДоговора
		left join #type_loan t on cmr_a.НомерДоговора = t.НомерЗаявки
		order by  v.ДатаВыдачи desc, cmr.ДатаДоговора desc, cmr_a.НомерДоговора

		RETURN 0
	END
	*/


	BEGIN TRAN
		--DELETE D
		--FROM dbo.dm_CollateralValue_MonthlyIncome AS D
		--WHERE D.report_date = @report_date
		TRUNCATE TABLE dbo.dm_CollateralValue_MonthlyIncome

		INSERT dbo.dm_CollateralValue_MonthlyIncome
		(
			DWHInsertedDate,
			ProcessGUID,
			report_date,
			НомерДоговора,
			ДатаДоговора,
			ДатаВыдачи,
			Фамилия,
			Имя,
			Отчество,
			[СMR.СтоимостьТС],
			[УМФО.ЗалоговаяСтоимость],
			[УМФО.РыночнаяСтоимость],
			[УМФО.СправедливаяСтоимость],
			[Федор.Оценочная стоимость автомобиля],
			[Федор.Рыночная стоимость на момент оценки],
			[Федор.Рыночная стоимость от логинома],
			[Федор.TsPrice],
			[Федор.доход по справке],
			[Федор.доход Росстат],
			[Федор.Доход из БКИ],
			[Федор.Месячный доход],
			[Федор.Дополнительный доход],
			[ЭДО.ЕжемесячныйДоход],
			[ЭДО.ОценочнаяСтоимость],
			[ЭДО.РыночнаяСтоимость],
			[Спейс.Оценочная стоимость],
			[Спейс.Рыночная стоимость],
			[Спейс.Среднемесячный доход],
			[Спейс.Зарплата],
			[CRM.ОценочнаяСтоимость],
			[CRM.РыночнаяОценкаСтоимости],
			[CRM.СуммарныйМесячныйДоход],
			return_type,
			СуммаВыдачи
		)
		SELECT 
			DWHInsertedDate = getdate(),
			ProcessGUID = @ProcessGUID,
			--
			report_date = @report_date,
			cmr_a.НомерДоговора,
			cmr.ДатаДоговора,
			v.ДатаВыдачи,
			cmr.Фамилия,
			cmr.Имя,
			cmr.Отчество,
			cmr.[СMR.СтоимостьТС],
			umfo.[УМФО.ЗалоговаяСтоимость],
			umfo.[УМФО.РыночнаяСтоимость],
			umfo.[УМФО.СправедливаяСтоимость],
			--, feodor.[Feodor.НомерДоговора],
			feodor.[Федор.Оценочная стоимость автомобиля],
			feodor.[Федор.Рыночная стоимость на момент оценки],
			feodor.[Федор.Рыночная стоимость от логинома],
			feodor.[Федор.TsPrice],
			feodor.[Федор.доход по справке],
			feodor.[Федор.доход Росстат],
			feodor.[Федор.Доход из БКИ],
			feodor.[Федор.Месячный доход],
			feodor.[Федор.Дополнительный доход],
			--, edo.[ЭДО.НомерДоговора],
			edo.[ЭДО.ЕжемесячныйДоход],
			edo.[ЭДО.ОценочнаяСтоимость],
			edo.[ЭДО.РыночнаяСтоимость],
			--edo.rn1
			--, spce.[Спейс.НомерДоговора],
			spce.[Спейс.Оценочная стоимость],
			spce.[Спейс.Рыночная стоимость],
			spce.[Спейс.Среднемесячный доход],
			spce.[Спейс.Зарплата],
			--spce.rn2
			crm.[CRM.ОценочнаяСтоимость],
			crm.[CRM.РыночнаяОценкаСтоимости],
			crm.[CRM.СуммарныйМесячныйДоход],
			--crm.[CRM.Номер],
			--crm.rn_crm,
			t.return_type,
			v.СуммаВыдачи
	   FROM #active_cmr AS cmr_a
		   left join #cmr cmr on cmr_a.НомерДоговора = cmr.[CMR.НомерДоговора]
		   left join #umfo umfo on cmr_a.НомерДоговора = umfo.[УМФО.НомерДоговора]
		   left join #feodor feodor on cmr_a.НомерДоговора = feodor.[Feodor.НомерДоговора]
		   left join #edo edo on cmr_a.НомерДоговора = edo.[ЭДО.НомерДоговора]
		   left join #space spce on cmr_a.НомерДоговора = spce.[Спейс.НомерДоговора]
		   left join #crm crm on cmr_a.НомерДоговора = crm.[CRM.Номер]
		   join #active_cmr_vidan AS v on v.НомерДоговора = cmr_a.НомерДоговора
		   left join #type_loan t on cmr_a.НомерДоговора = t.НомерЗаявки
	   --order by  v.ДатаВыдачи desc, cmr.ДатаДоговора desc, cmr_a.НомерДоговора
	   --ORDER BY cmr_a.НомерДоговора

		SELECT @InsertRows = @@ROWCOUNT
	COMMIT


	SELECT @DurationSec = datediff(SECOND, @ProcStartDate, getdate())

	SELECT @message = concat(
		'Формирование витрины dbo.dm_CollateralValue_MonthlyIncome. ',
		'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
		'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
	)

	SELECT @description =
		(
		SELECT
			'InsertRows' = @InsertRows,
			'DurationSec' = @DurationSec
		FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
		)

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Create_dm_CollateralValue_MonthlyIncome',
		@eventType = 'Info',
		@message = @message,
		@description = @description, 
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID

END TRY
BEGIN CATCH
	SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
			ROLLBACK;

	SELECT @message = concat(
		'Ошибка формирования витрины dbo.dm_CollateralValue_MonthlyIncome. ',
		'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
		'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
	)

	SELECT @description =
		(
		SELECT
			'InsertRows' = @InsertRows,
			'DurationSec' = @DurationSec
		FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
		)

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Create_dm_CollateralValue_MonthlyIncome',
		@eventType = 'Error',
		@message = @message,
		@description = @error_description, 
		@SendEmail = 1,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @error_description, 1
END CATCH

END
