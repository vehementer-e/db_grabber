-- =======================================================
-- Modify: 11.02.2022. А.Никитин
-- Description:	DWH-1434 Оптимизация процедуры
--[fill_1cАналитическиеПоказатели] 1
--exec [dbo].[fill_1cАналитическиеПоказатели] @mode = 2, @contractGuids = 'B0838374-6E5E-11EE-B812-C8B19D7A5302,1B45A6AC-E989-11E7-814E-00155D01BF07,B0838374-6E5E-11EE-B812-C8B19D7A5302,5D4A2748-6379-11EE-B812-C8B19D7A5302'
-- =======================================================
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[fill_1cАналитическиеПоказатели] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   PROC [dbo].[fill_1cАналитическиеПоказатели] 
	@mode int = 0, 
	@Debug int = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@ContractGuid nvarchar(36) = null,  --guid договора
	@contractGuids nvarchar(max) = null  --guids договоров
with recompile
AS
BEGIN
	SET XACT_ABORT ON
	DECLARE @msg nvarchar(MAX)
	SET DEADLOCK_PRIORITY HIGH 
	set @contractGuids = CONCAT_WS(',', @ContractGuid, @contractGuids)
	set @contractGuids = nullif(@contractGuids, '')


BEGIN TRY
	declare @contractS int

	declare @t_contracts table(contractId binary(16) primary key, contractGuid nvarchar(36))
	insert into @t_contracts(contractId, contractGuid)
	select distinct 
		contractId = [dbo].[get1CIDRREF_FromGUID](trim(value))
		, contractGuid = trim(value)
	from string_split(@contractGuids, ',')
		select @contractS =count(contractId) from  @t_contracts
				WHERE 1=1
	print @contractS

	/*
	@mode = 0 -- переопределить @mode в зависимости от времени

	@mode = 1 -- полное заполнение таблицы dbo._1cАналитическиеПоказатели

	@mode = 2 -- инкрементное заполнение 
	Т.е. в течение дня мы должны брать в расчет только те договора которые были изменены, т.е. по которым были платежи
	информация о таких договорах собирается в таблицу - dbo.CMRStatBalanceListTioCalculation
	процедурой [_1cCMR].[create_CMRStatBalance_ListTioCalculation]
	*/
	IF @mode = 0 -- переопределить @mode в зависимости от времени
	BEGIN
		SELECT @mode = CASE 
							WHEN cast(getdate() AS time)>'06:00' THEN 2 -- инкрементное заполнение 
							ELSE 1 --полное заполнение
					   END
	END

    DECLARE @StartDate datetime, @row_count int

	IF object_id('dbo._1cАналитическиеПоказатели') IS NULL
	BEGIN
	--drop table if exists dbo._1cАналитическиеПоказатели
		SELECT TOP(0) [Период]                                                         
		,             [Регистратор_ТипСсылки] = cast(NULL AS binary(4))                
		,             [Регистратор_Ссылка] = cast(NULL AS binary(16))                  
		,             [НомерСтроки] = cast(NULL AS numeric(9,0))                       
		,             [Активность]                                                     
		,             [Договор]                                                        
		,             [ДатаВозникновенияПросрочки]  = cast(NULL AS datetime2(0))                                   
		,             [ДатаПоследнегоПлатежа]    = cast(NULL AS datetime2(0))                                      
		,             [КоличествоПолныхДнейПросрочки]                                  
		,             [ПросроченнаяЗадолженность]                                      
		,             [СуммаПоследнегоПлатежа]                                         
		,             [РегистраторМФО] = cast(NULL AS varchar(150))                    
		,             [ДатаВозникновенияПросрочкиУМФО] = cast(NULL AS datetime2(0))    
		,             [КоличествоПолныхДнейПросрочкиУМФО] = cast(NULL AS numeric(10,0))
		,             [ОбластьДанныхОсновныеДанные] = cast(NULL AS numeric(7,0))       
		,             Источник = cast('CMR' AS varchar(30)) 
		,			  НомерДоговора = cast(NULL AS nvarchar(14))
		,			  GuidДоговора = cast(NULL AS varchar(36))
		,			  create_at = getdate()
			INTO dbo._1cАналитическиеПоказатели ON _1cCMR
		FROM [_1cCMR].[РегистрСведений_АналитическиеПоказателиМФО]

		CREATE CLUSTERED INDEX ci_ix 
		ON dbo._1cАналитическиеПоказатели(Период, [Договор])
		ON [_1cCMR]

		CREATE NONCLUSTERED INDEX IX_Договор 
		ON dbo._1cАналитическиеПоказатели([Договор]) 
		INCLUDE ([КоличествоПолныхДнейПросрочки], [ПросроченнаяЗадолженность], [КоличествоПолныхДнейПросрочкиУМФО]) 
		ON [_1cCMR]
	END

	--IF @mode = 1 -- полное заполнение
	--BEGIN
	--	DROP INDEX IF EXISTS ci_ix ON dbo._1cАналитическиеПоказатели
	--	DROP INDEX IF EXISTS IX_Договор ON dbo._1cАналитическиеПоказатели
	--END


	--IF cast(getdate() AS time)>'06:00'
	IF @mode = 2 -- инкрементное заполнение 
	BEGIN
		--Если сегодня что-то добавили в РегистрСведений_АналитическиеПоказателиМФО из etl
		IF NOT EXISTS(SELECT TOP(1) 1 FROM [_1cCMR].[РегистрСведений_АналитическиеПоказателиМФО] cmr
			WHERE DWHInsertedDate IS NOT NULL)
			RETURN --не добавили
		ELSE BEGIN
				--Новые данные
				DROP TABLE IF EXISTS #t_new_data
				CREATE TABLE #t_new_data
				(
					[Период] datetime2(0) NOT NULL,
					[Договор] binary(16) NOT NULL
				
				)

				SELECT @StartDate = getdate()

				INSERT #t_new_data WITH(TABLOCK) (Период, Договор)
				SELECT t.Период, t.Договор
					--INTO #t_new_data
				FROM 
				(SELECT период, договор
					FROM [_1cCMR].[РегистрСведений_АналитическиеПоказателиМФО] cmr
					WHERE Период>=dateadd(YEAR,2000,dateadd(DAY,-5,cast(getdate() AS date)))
				--EXCEPT
				--SELECT период, договор
				--	FROM [_1cCMR].[РегистрСведений_АналитическиеПоказателиМФО_temp] cmr
				--WHERE Период>=dateadd(YEAR,2000,dateadd(DAY,-5,cast(getdate() AS date)))
				) t
				OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

				SELECT @row_count = @@ROWCOUNT
				IF @Debug = 1 BEGIN
					SELECT 'SELECT * INTO #t_new_data', @row_count, datediff(SECOND, @StartDate, getdate())
				END
				IF NOT EXISTS (SELECT TOP(1) 1 FROM #t_new_data)
						RETURN --новых данных нет
					
		END
	END
	

	DROP TABLE IF EXISTS #Deals
	CREATE TABLE #Deals(
		external_id nvarchar(21) NOT NULL,
		Договор binary(16) NOT NULL
	)


	DROP TABLE IF EXISTS #РегистрСведений_ГП_АналитическиеПоказателиЗайма

	CREATE TABLE #РегистрСведений_ГП_АналитическиеПоказателиЗайма
	(
		[Период] [datetime] NOT NULL,
		[Договор] [binary] (16) NOT NULL,
		[ДатаВозникновенияПросрочки] [datetime] NOT NULL,
		[КоличествоПолныхДнейПросрочки] [numeric] (10, 0) NOT NULL,
		[ПросроченнаяЗадолженность] [numeric] (15, 2) NOT NULL,
		[ДатаПоследнегоПлатежа] [datetime] NOT NULL,
		[СуммаПоследнегоПлатежа] [numeric] (15, 2) NOT NULL,
		[DWHInsertedDate] [datetime] NULL,
		[ProcessGUID] [nvarchar] (36) NULL,
		--
		[Период_date] [date] NOT NULL,
	)

	SELECT @StartDate = getdate()

	IF @mode = 1 -- полное заполнение
	BEGIN
		INSERT #РегистрСведений_ГП_АналитическиеПоказателиЗайма
		WITH(TABLOCK)
		(
			Период,
			Договор,
			ДатаВозникновенияПросрочки,
			КоличествоПолныхДнейПросрочки,
			ПросроченнаяЗадолженность,
			ДатаПоследнегоПлатежа,
			СуммаПоследнегоПлатежа,
			DWHInsertedDate,
			ProcessGUID,
			Период_date
		)
		SELECT 
			R.Период,
			R.Договор,
			R.ДатаВозникновенияПросрочки,
			R.КоличествоПолныхДнейПросрочки,
			R.ПросроченнаяЗадолженность,
			R.ДатаПоследнегоПлатежа,
			R.СуммаПоследнегоПлатежа,
			R.DWHInsertedDate,
			R.ProcessGUID,
			Период_date = cast(R.Период AS date)
		FROM _1cMFO.[РегистрСведений_ГП_АналитическиеПоказателиЗайма] AS R WITH(NOLOCK)
		OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

		SELECT @row_count = @@ROWCOUNT
	END
	ELSE IF @mode = 2 -- инкрементное заполнение
	BEGIN
		--в течение дня мы должны брать в расчет только те договора, которые были изменены, т.е. по которым были платежи\
		if @contractGuids is null
		begin
		INSERT #Deals(external_id,  [Договор])
			SELECT
				external_id = Dogovor.Код,
				Dogovor.Ссылка
			FROM [_1cCMR].[Справочник_Договоры]  Dogovor (NOLOCK)
			LEFT JOIN _1cCMR.документ_платеж Payment (NOLOCK) ON Payment.Договор=Dogovor.Ссылка
			--WHERE Payment.Дата BETWEEN cast(dateadd(DAY,0, dateadd(YEAR,2000,getdate())) AS date) AND cast(dateadd(DAY,1, dateadd(YEAR,2000,getdate())) AS date)  
			WHERE Payment.Дата BETWEEN cast(dateadd(DAY,-1, dateadd(YEAR,2000,getdate())) AS date) AND cast(dateadd(DAY,1, dateadd(YEAR,2000,getdate())) AS date)  
			GROUP BY Dogovor.Код, Dogovor.Ссылка

			union

			select external_id, Договор from CMRStatBalanceListTioCalculation
		END
		else
		begin
			INSERT #Deals(external_id,  [Договор])
			SELECT
				external_id = Dogovor.Код,
				Dogovor.Ссылка
			FROM [_1cCMR].[Справочник_Договоры]  Dogovor (NOLOCK)
			where exists(select top(1) 1 from @t_contracts c where c.contractId =Dogovor.Ссылка)
			 
			--Dogovor.Ссылка = [dbo].[get1CIDRREF_FromGUID](@ContractGuid)
		end
		CREATE CLUSTERED INDEX CL_Договор_Deals ON #Deals(Договор)

		INSERT #РегистрСведений_ГП_АналитическиеПоказателиЗайма
		WITH(TABLOCKX)
		(
			Период,
			Договор,
			ДатаВозникновенияПросрочки,
			КоличествоПолныхДнейПросрочки,
			ПросроченнаяЗадолженность,
			ДатаПоследнегоПлатежа,
			СуммаПоследнегоПлатежа,
			DWHInsertedDate,
			ProcessGUID,
			Период_date
		)
		SELECT 
			R.Период,
			R.Договор,
			R.ДатаВозникновенияПросрочки,
			R.КоличествоПолныхДнейПросрочки,
			R.ПросроченнаяЗадолженность,
			R.ДатаПоследнегоПлатежа,
			R.СуммаПоследнегоПлатежа,
			R.DWHInsertedDate,
			R.ProcessGUID,
			Период_date = cast(R.Период AS date)
		FROM _1cMFO.[РегистрСведений_ГП_АналитическиеПоказателиЗайма] AS R
			INNER JOIN #Deals AS D
				ON D.Договор = R.Договор
		OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

		SELECT @row_count = @@ROWCOUNT
	END

	CREATE INDEX ix_Договор_Период
	ON #РегистрСведений_ГП_АналитическиеПоказателиЗайма(Договор, Период_date)

	IF @Debug = 1 BEGIN
		SELECT 'INSERT #РегистрСведений_ГП_АналитическиеПоказателиЗайма', @row_count, datediff(SECOND, @StartDate, getdate())
	END
		
	DROP TABLE IF EXISTS #t_cmr

	CREATE TABLE #t_cmr
	(
		[Период] datetime2(0) NOT NULL,
		[Регистратор_ТипСсылки] binary(4) NOT NULL,
		[Регистратор_Ссылка] binary(16) NOT NULL,
		[НомерСтроки] numeric(9, 0) NOT NULL,
		[Активность] binary(1) NOT NULL,
		[Договор] binary(16) NOT NULL,
		[ДатаВозникновенияПросрочки] datetime2(0) NOT NULL,
		[ДатаПоследнегоПлатежа] datetime2(0) NOT NULL,
		[КоличествоПолныхДнейПросрочки] numeric(10, 0) NOT NULL,
		[ПросроченнаяЗадолженность] numeric(15, 2) NOT NULL,
		[СуммаПоследнегоПлатежа] numeric(15, 2) NOT NULL,
		[РегистраторМФО] nvarchar(150) NOT NULL,
		[ДатаВозникновенияПросрочкиУМФО] datetime2(0) NULL,
		[КоличествоПолныхДнейПросрочкиУМФО] numeric(10, 0) NULL,
		[ОбластьДанныхОсновныеДанные] numeric(7, 0) NOT NULL,
		[Источник] varchar(3),
		--
		[Период_date] date NOT NULL,
		--
		НомерДоговора nvarchar(14),
		GuidДоговора varchar(36)
	)

	--toDo брать только новые из #t_new_data если update идет после 6 утра

	SELECT @StartDate = getdate()

	IF @mode = 1 -- полное заполнение
	BEGIN
		INSERT #t_cmr
		WITH(TABLOCKX)
		(
			Период,
			Регистратор_ТипСсылки,
			Регистратор_Ссылка,
			НомерСтроки,
			Активность,
			Договор,
			ДатаВозникновенияПросрочки,
			ДатаПоследнегоПлатежа,
			КоличествоПолныхДнейПросрочки,
			ПросроченнаяЗадолженность,
			СуммаПоследнегоПлатежа,
			РегистраторМФО,
			ДатаВозникновенияПросрочкиУМФО,
			КоличествоПолныхДнейПросрочкиУМФО,
			ОбластьДанныхОсновныеДанные,
			Источник,
			Период_date,
			НомерДоговора,
			GuidДоговора
		)
		SELECT 
			cmr.[Период]
			, cmr.[Регистратор_ТипСсылки]
			, cmr.[Регистратор_Ссылка]
			, cmr.[НомерСтроки]
			, cmr.[Активность]
			, cmr.[Договор]
			, cmr.[ДатаВозникновенияПросрочки]
			, cmr.[ДатаПоследнегоПлатежа]
			, cmr.[КоличествоПолныхДнейПросрочки]
			, cmr.[ПросроченнаяЗадолженность]
			, cmr.[СуммаПоследнегоПлатежа]
			, cmr.[РегистраторМФО]
			, cmr.[ДатаВозникновенияПросрочкиУМФО]
			, cmr.[КоличествоПолныхДнейПросрочкиУМФО] 
			, cmr.[ОбластьДанныхОсновныеДанные]
			, Источник = 'cmr'
			, Период_date = cast(cmr.Период AS date)
			, НомерДоговора = D.Код
			, GuidДоговора = dbo.getGUIDFrom1C_IDRREF(cmr.[Договор])
		from _1cCMR.РегистрСведений_АналитическиеПоказателиМФО AS cmr
			LEFT JOIN _1cCMR.Справочник_Договоры AS D
				ON D.Ссылка = cmr.Договор
		
		OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))
	END
	ELSE IF @mode = 2 -- инкрементное заполнение
	BEGIN
		INSERT #t_cmr
		WITH(TABLOCKX)
		(
			Период,
			Регистратор_ТипСсылки,
			Регистратор_Ссылка,
			НомерСтроки,
			Активность,
			Договор,
			ДатаВозникновенияПросрочки,
			ДатаПоследнегоПлатежа,
			КоличествоПолныхДнейПросрочки,
			ПросроченнаяЗадолженность,
			СуммаПоследнегоПлатежа,
			РегистраторМФО,
			ДатаВозникновенияПросрочкиУМФО,
			КоличествоПолныхДнейПросрочкиУМФО,
			ОбластьДанныхОсновныеДанные,
			Источник,
			Период_date,
			НомерДоговора,
			GuidДоговора
		)
		SELECT 
			cmr.[Период]
			, cmr.[Регистратор_ТипСсылки]
			, cmr.[Регистратор_Ссылка]
			, cmr.[НомерСтроки]
			, cmr.[Активность]
			, cmr.[Договор]
			, ДатаВозникновенияПросрочки = COALESCE (cmr_new.[ДатаВозникновенияПросрочкиНоваяМетодика], cmr.[ДатаВозникновенияПросрочки]		)
			, cmr.[ДатаПоследнегоПлатежа]
			, [КоличествоПолныхДнейПросрочки]  = COALESCE(cmr_new.[КоличествоПолныхДнейПросрочкиНоваяМетодика], cmr.КоличествоПолныхДнейПросрочки)
			, cmr.[ПросроченнаяЗадолженность]
			, cmr.[СуммаПоследнегоПлатежа]
			, cmr.[РегистраторМФО]
			, [ДатаВозникновенияПросрочкиУМФО] = CASE WHEN cmr.[Период] >='40190923' THEN cmr.[ДатаВозникновенияПросрочкиУМФО] ELSE isnull(m.ДатаВозникновенияПросрочки,cmr.[ДатаВозникновенияПросрочкиУМФО])
				END
			, [КоличествоПолныхДнейПросрочкиУМФО] = CASE WHEN cmr.[Период] >='40190923' THEN cmr.[КоличествоПолныхДнейПросрочкиУМФО] ELSE isnull(m.КоличествоПолныхДнейПросрочки,cmr.[КоличествоПолныхДнейПросрочкиУМФО]) END
			, cmr.[ОбластьДанныхОсновныеДанные]
			, Источник = 'cmr'
			, Период_date = cast(cmr.Период AS date)
			, НомерДоговора = D.external_id
			, GuidДоговора = dbo.getGUIDFrom1C_IDRREF(cmr.Договор)
		FROM #Deals AS D
			INNER JOIN   [_1cCMR].[РегистрСведений_АналитическиеПоказателиМФО] AS cmr
				ON D.Договор = cmr.Договор
			LEFT JOIN #РегистрСведений_ГП_АналитическиеПоказателиЗайма AS m 
				ON cmr.Договор = m.Договор 
				AND cast(cmr.Период AS date) = m.Период_date
			LEFT JOIN [_1cCMR].РегистрСведений_АналитическиеПоказателиМФОНоваяМетодика cmr_new
				on cmr.Договор=cmr_new.Договор 
				and cast(cmr.Период as date) =cast(cmr_new.Период as date)
		OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))
	END

	SELECT @row_count = @@ROWCOUNT
	IF @Debug = 1 BEGIN
		SELECT 'INSERT #t_cmr', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	--CREATE CLUSTERED INDEX ix_Договор_Период ON #t_cmr(Договор, Период_date)
	CREATE INDEX ix_Договор_Период ON #t_cmr(Договор, Период_date)


	DROP TABLE IF EXISTS #t_exists_only_mfo

	CREATE TABLE [#t_exists_only_mfo]
	(
		[Договор] binary(16) NOT NULL,
		[НомерДоговора] [nvarchar] (14),
		[Период_date] date NOT NULL
	)

	SELECT @StartDate = getdate()

	INSERT #t_exists_only_mfo
	WITH(TABLOCK)
		(Договор, НомерДоговора, Период_date)
	SELECT t.Договор, НомерДоговора = D.Код, t.Период_date
	FROM (
		SELECT DISTINCT m.Договор, m.Период_date
		--from _1cMFO.[РегистрСведений_ГП_АналитическиеПоказателиЗайма] m
		FROM #РегистрСведений_ГП_АналитическиеПоказателиЗайма AS m
		WHERE m.Период_date <='40190923' --берем из мфо только данные до 2019г
			EXCEPT
		SELECT DISTINCT cmr.Договор, cmr.Период_date
		FROM #t_cmr AS cmr
	) t
	INNER JOIN _1cCMR.Справочник_Договоры AS D
		ON D.Ссылка = t.Договор
		AND D.ПометкаУдаления = 0x00
	--WHERE EXISTS(SELECT TOP(1) 1
	--	FROM _1cCMR.Справочник_Договоры д
	--	WHERE д.Ссылка = t.Договор
	--		AND д.ПометкаУдаления = 0x00)
	OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

	SELECT @row_count = @@ROWCOUNT
	IF @Debug = 1 BEGIN
		SELECT 'INSERT #t_exists_only_mfo', @row_count, datediff(SECOND, @StartDate, getdate())
	END
	
	--CREATE CLUSTERED INDEX ix ON #t_exists_only_mfo (Договор, Период_date)

	DROP TABLE IF EXISTS #t_mfo

	CREATE TABLE #t_mfo
	(
		[Период] datetime2(0),
		[Регистратор_ТипСсылки] binary(4),
		[Регистратор_Ссылка] binary(16),
		[НомерСтроки] numeric(9,0),
		[Активность] binary(1),
		[Договор] binary(16) NOT NULL,
		[ДатаВозникновенияПросрочки] datetime2(0),
		[ДатаПоследнегоПлатежа] datetime2(0),
		[КоличествоПолныхДнейПросрочки] numeric(10, 0) NOT NULL,
		[ПросроченнаяЗадолженность] numeric(15, 2) NOT NULL,
		[СуммаПоследнегоПлатежа] numeric(15, 2) NOT NULL,
		[РегистраторМФО] varchar(150),
		[ДатаВозникновенияПросрочкиУМФО] datetime2(0),
		[КоличествоПолныхДнейПросрочкиУМФО] numeric(10, 0) NOT NULL,
		[ОбластьДанныхОсновныеДанные] numeric(7,0),
		[Источник] varchar(3),
		НомерДоговора nvarchar(14),
		GuidДоговора varchar(36)
	)


	SELECT @StartDate = getdate()

	INSERT #t_mfo
	WITH(TABLOCKX)
	(
		Период,
		Регистратор_ТипСсылки,
		Регистратор_Ссылка,
		НомерСтроки,
		Активность,
		Договор,
		ДатаВозникновенияПросрочки,
		ДатаПоследнегоПлатежа,
		КоличествоПолныхДнейПросрочки,
		ПросроченнаяЗадолженность,
		СуммаПоследнегоПлатежа,
		РегистраторМФО,
		ДатаВозникновенияПросрочкиУМФО,
		КоличествоПолныхДнейПросрочкиУМФО,
		ОбластьДанныхОсновныеДанные,
		Источник,
		НомерДоговора,
		GuidДоговора
	)
	SELECT [Период]						= cast(m.Период  AS datetime2(0))
	,      [Регистратор_ТипСсылки]		= cast(NULL AS binary(4))
	,      [Регистратор_Ссылка]			= cast(NULL AS binary(16))
	,      [НомерСтроки]				= cast(NULL AS numeric(9,0))
	,      [Активность]					= 0x01                           
	,      m.[Договор]                    
	,      [ДатаВозникновенияПросрочки]  = cast(ДатаВозникновенияПросрочки  AS datetime2(0))
	,      [ДатаПоследнегоПлатежа]       = cast(ДатаПоследнегоПлатежа  AS datetime2(0))
	,      [КоличествоПолныхДнейПросрочки]
	,      [ПросроченнаяЗадолженность]    
	,      [СуммаПоследнегоПлатежа]       
	,      [РегистраторМФО] = cast(NULL AS varchar(150))      
	,      [ДатаВозникновенияПросрочкиУМФО] = cast(ДатаВозникновенияПросрочки  AS datetime2(0))
	,      [КоличествоПолныхДнейПросрочкиУМФО] = [КоличествоПолныхДнейПросрочки]
	,      [ОбластьДанныхОсновныеДанные] = cast(NULL AS numeric(7,0))
	,      Источник = 'mfo'
	,	   НомерДоговора = t.НомерДоговора
	,	   GuidДоговора = dbo.getGUIDFrom1C_IDRREF(t.Договор)
		--INTO #t_mfo
	--FROM       _1cMFO.[РегистрСведений_ГП_АналитическиеПоказателиЗайма] m
	FROM #РегистрСведений_ГП_АналитическиеПоказателиЗайма AS m
		INNER JOIN #t_exists_only_mfo AS t 
			ON t.Договор = m.Договор
			AND t.Период_date = m.Период_date
	OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

	SELECT @row_count = @@ROWCOUNT
	IF @Debug = 1 BEGIN
		SELECT 'INSERT #t_mfo', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	
	BEGIN TRAN	
		IF @mode = 1 -- полное заполнение
		BEGIN
			TRUNCATE TABLE [dbo].[_1cАналитическиеПоказатели]
			--TRUNCATE TABLE tmp.TMP_AND_1cАналитическиеПоказатели
		END
		ELSE IF @mode = 2 -- инкрементное заполнение
		BEGIN
			SELECT @StartDate = getdate()

			DELETE R
			FROM [dbo].[_1cАналитическиеПоказатели] AS R
			--FROM tmp.TMP_AND_1cАналитическиеПоказатели AS R
				INNER JOIN #Deals AS D
					ON D.Договор = R.Договор

			SELECT @row_count = @@ROWCOUNT
			IF @Debug = 1 BEGIN
				SELECT 'DELETE FROM _1cАналитическиеПоказатели', @row_count, datediff(SECOND, @StartDate, getdate())
			END
		END

		SELECT @StartDate = getdate()

		INSERT [dbo].[_1cАналитическиеПоказатели] 
		--INSERT tmp.TMP_AND_1cАналитическиеПоказатели 
		--WITH(TABLOCKX)
		( 
			[Период], 
			[Регистратор_ТипСсылки], 
			[Регистратор_Ссылка], 
			[НомерСтроки], 
			[Активность], 
			[Договор], 
			[ДатаВозникновенияПросрочки], 
			[ДатаПоследнегоПлатежа], 
			[КоличествоПолныхДнейПросрочки], 
			[ПросроченнаяЗадолженность], 
			[СуммаПоследнегоПлатежа], 
			[РегистраторМФО], 
			[ДатаВозникновенияПросрочкиУМФО], 
			[КоличествоПолныхДнейПросрочкиУМФО], 
			[ОбластьДанныхОсновныеДанные], 
			[Источник],
			НомерДоговора,
			GuidДоговора,
			create_at
		) 
		SELECT [Период]							= dateadd(YEAR,-2000, [Период])                                                                                         
		,      [Регистратор_ТипСсылки]                                                                                                         
		,      [Регистратор_Ссылка]                                                                                                            
		,      [НомерСтроки]                                                                                                                   
		,      [Активность]                                                                                                                    
		,      [Договор]                                                                                                                       
		,      [ДатаВозникновенияПросрочки]		= nullif(dateadd(YEAR, -2000, [ДатаВозникновенияПросрочки]), '0001-01-01')
		,      [ДатаПоследнегоПлатежа]			= nullif(dateadd(YEAR,-2000, [ДатаПоследнегоПлатежа]), '0001-01-01') 
		,      [КоличествоПолныхДнейПросрочки]                                                                                                 
		,      [ПросроченнаяЗадолженность]                                                                                                     
		,      [СуммаПоследнегоПлатежа]                                                                                                        
		,      [РегистраторМФО]                                                                                                                
		,      [ДатаВозникновенияПросрочкиУМФО] = nullif(dateadd(YEAR,-2000, [ДатаВозникновенияПросрочкиУМФО]), '0001-01-01')
		,      [КоличествоПолныхДнейПросрочкиУМФО]                                                                                             
		,      [ОбластьДанныхОсновныеДанные]                                                                                                   
		,      [Источник]     
		,	   НомерДоговора
		,	   GuidДоговора
		,		create_at = getdate()
		FROM #t_cmr
		OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

		SELECT @row_count = @@ROWCOUNT
		IF @Debug = 1 BEGIN
			SELECT 'INSERT _1cАналитическиеПоказатели FROM #t_cmr', @row_count, datediff(SECOND, @StartDate, getdate())
		END
	
	
		--UNION

		SELECT @StartDate = getdate()

		INSERT [dbo].[_1cАналитическиеПоказатели] 
		--INSERT tmp.TMP_AND_1cАналитическиеПоказатели
		--WITH(TABLOCKX)
		( 
			[Период], 
			[Регистратор_ТипСсылки], 
			[Регистратор_Ссылка], 
			[НомерСтроки], 
			[Активность], 
			[Договор], 
			[ДатаВозникновенияПросрочки], 
			[ДатаПоследнегоПлатежа], 
			[КоличествоПолныхДнейПросрочки], 
			[ПросроченнаяЗадолженность], 
			[СуммаПоследнегоПлатежа], 
			[РегистраторМФО], 
			[ДатаВозникновенияПросрочкиУМФО], 
			[КоличествоПолныхДнейПросрочкиУМФО], 
			[ОбластьДанныхОсновныеДанные], 
			[Источник],
			НомерДоговора,
			GuidДоговора,
			create_at
		) 
		SELECT [Период]							= dateadd(YEAR,-2000, [Период])
		,      [Регистратор_ТипСсылки]                                                                                                 
		,      [Регистратор_Ссылка]                                                                                                    
		,      [НомерСтроки]                                                                                                           
		,      [Активность]                                                                                                            
		,      [Договор]                                                                                                               
		,      [ДатаВозникновенияПросрочки]		= nullif(dateadd(YEAR,-2000, [ДатаВозникновенияПросрочки]),'0001-01-01' )
		,      [ДатаПоследнегоПлатежа]			= nullif(dateadd(YEAR,-2000, [ДатаПоследнегоПлатежа]),'0001-01-01' )
		,      [КоличествоПолныхДнейПросрочки]                                                                                         
		,      [ПросроченнаяЗадолженность]                                                                                             
		,      [СуммаПоследнегоПлатежа]                                                                                                
		,      [РегистраторМФО]                                                                                                        
		,      [ДатаВозникновенияПросрочкиУМФО]	= nullif(dateadd(YEAR,-2000, [ДатаВозникновенияПросрочкиУМФО]),'0001-01-01' )                                                                     
		,      [КоличествоПолныхДнейПросрочкиУМФО]                                                                                     
		,      [ОбластьДанныхОсновныеДанные]                                                                                           
		,      [Источник]  
		,	   НомерДоговора
		,	   GuidДоговора
		,		create_at = getdate()
		FROM #t_mfo
		OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

		SELECT @row_count = @@ROWCOUNT
		IF @Debug = 1 BEGIN
			SELECT 'INSERT _1cАналитическиеПоказатели FROM #t_mfo', @row_count, datediff(SECOND, @StartDate, getdate())
		END
	COMMIT TRAN

	--if cast(getdate() as time)between '00:00' and '06:00'

	--IF @mode = 1 -- полное заполнение таблицы
	--begin
	--	SELECT @StartDate = getdate()

	--	--ALTER INDEX ci_ix ON [dbo].[_1cАналитическиеПоказатели]
	--	--	REBUILD WITH (SORT_IN_TEMPDB = OFF, ONLINE = OFF, RESUMABLE = OFF)

	--	--CREATE CLUSTERED INDEX ci_ix 
	--	--ON dbo._1cАналитическиеПоказатели(Период, [Договор])
	--	--ON [_1cCMR]

	--	--CREATE NONCLUSTERED INDEX IX_Договор 
	--	--ON dbo._1cАналитическиеПоказатели([Договор]) 
	--	--INCLUDE ([КоличествоПолныхДнейПросрочки], [ПросроченнаяЗадолженность], [КоличествоПолныхДнейПросрочкиУМФО]) 
	--	--ON [_1cCMR]

	--	IF @Debug = 1 BEGIN
	--		SELECT 'CREATE INDEXES ON dbo._1cАналитическиеПоказатели', datediff(SECOND, @StartDate, getdate())
	--	END
	--end

	IF @Debug = 0 BEGIN -- выполнять в штатном режиме
		begin try
			declare @date date= CAST(getdate() as date)
			declare @totalRecords int = (select count(1) from [dbo].[_1cАналитическиеПоказатели]
			where cast(Период as date) = @date)

			set @msg= concat('за текущий день ', 
			format(@date,'dd.MM.yyyy'), 
			' в _1cАналитическиеПоказатели ', @totalRecords, ' записей')
	
			exec LogDb.[dbo].[LogAndSendMailToAdmin] 
				@eventName = 'fill_1cАналитическиеПоказатели'
				,@eventType = 'info'
				,@message = 'Кол. записей за текущий день'
				,@description = @msg
		end try
		begin catch
		end catch

	END --// выполнять в штатном режиме
end try
begin catch
	IF @@TRANCOUNT >0
	BEGIN
		ROLLBACK TRANSACTION
	END  

	IF @Debug = 0 BEGIN -- выполнять в штатном режиме
		set @msg = ERROR_MESSAGE() 
		exec LogDb.[dbo].[LogAndSendMailToAdmin] 
				@eventName = 'fill_1cАналитическиеПоказатели'
				,@eventType = 'error'
				,@message = 'Ошибка в формирование 1cАналитическиеПоказатели'
				,@description = @msg
	END --// выполнять в штатном режиме

	;throw
end catch
end
