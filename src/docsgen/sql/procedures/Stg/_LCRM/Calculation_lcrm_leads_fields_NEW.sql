-- =======================================================
-- Created: 16.02.2022. А.Никитин
-- Description:	DWH-1567 Оптимизация хранения лидов. Отказ от использования таблицы lcrm_leads_full_channel
-- расчет вычисляемых полей и заполнение таблицы _LCRM.lcrm_leads_full_calculated
-- =======================================================
CREATE   PROC _LCRM.Calculation_lcrm_leads_fields_NEW
	@Debug int = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	@Insert_Into_lcrm_leads_full int = 0 -- 1 - добавление записей в _LCRM.lcrm_leads_full
	WITH RECOMPILE  
AS
BEGIN
	SET XACT_ABORT ON
	SET NOCOUNT ON
begin try
    DECLARE @StartDate datetime, @row_count int
	DECLARE @batch_size int, @delete_count int
	drop table if exists #tPartitions
	create table #tPartitions(PartitionId int primary key)
	-- нет записей в табл. источнике
	IF NOT EXISTS(SELECT TOP(1) 1 FROM #tmp2BE338B9_lcrm_leads_channel AS S)
	BEGIN
	    RETURN
	END

	--DWH-1964. Удалить более старые записи
	SELECT @StartDate = getdate(), @row_count = 0

	DROP TABLE IF EXISTS #t_ID_UF_UPDATED_AT
	CREATE TABLE #t_ID_UF_UPDATED_AT(
		ID numeric(10, 0) NULL,
		UF_UPDATED_AT datetime2(7) NULL
	)
	truncate table #tPartitions
	insert into #tPartitions(PartitionId)
	select distinct $Partition.pfn_range_right_date_part_lcrm_leads_full_calculated(T.UF_REGISTERED_AT)
	from #tmp2BE338B9_lcrm_leads_channel t

	INSERT #t_ID_UF_UPDATED_AT WITH(TABLOCKX) 
		(ID, UF_UPDATED_AT)
	SELECT T.ID
		, T.UF_UPDATED_AT
	FROM _LCRM.lcrm_leads_full_calculated AS T with(nolock, index = [IX_leads_full_calculated_ID_include_UF_UPDATED_AT_DWH_HASH_UF_ROW_ID])
	inner join #tPartitions p on p.PartitionId = $Partition.pfn_range_right_date_part_lcrm_leads_full_calculated( T.UF_REGISTERED_AT)
	WHERE EXISTS(select top(1) 1 from #tmp2BE338B9_lcrm_leads_channel AS S where S.ID = T.ID
		)

	CREATE INDEX IX1 ON #t_ID_UF_UPDATED_AT(ID, UF_UPDATED_AT)

	DELETE S
	FROM #tmp2BE338B9_lcrm_leads_channel AS S
	WHERE EXISTS(
			SELECT top(1) 1 
			FROM #t_ID_UF_UPDATED_AT AS T WITH(INDEX = IX1)
			WHERE S.ID = T.ID
			AND S.UF_UPDATED_AT < T.UF_UPDATED_AT
		)
	SELECT @row_count = @@ROWCOUNT

	IF @Debug = 1 BEGIN
		SELECT 'Удаление более старых записей в #tmp2BE338B9_lcrm_leads_channel', @row_count, datediff(SECOND, @StartDate, getdate())
	END
	--// DWH-1964. Удалить более старые записи




	DROP TABLE IF EXISTS #t_w_chanals0

	CREATE TABLE #t_w_chanals0(
		ID numeric(10, 0) NULL,
		DWHInsertedDate datetime NOT NULL,
		-- поля для расчета вычисляемых полей
		UF_REGISTERED_AT datetime2 NULL,
		UF_PHONE varchar (128) NULL,
		UF_NAME varchar(512) NULL,
		UF_ROW_ID varchar(128) NULL,
		UF_STAT_CAMPAIGN varchar(512) NULL,
		UF_STAT_CLIENT_ID_YA varchar(128) NULL,
		UF_STAT_CLIENT_ID_GA varchar(128) NULL,
		UF_TYPE varchar(128) NULL,
		UF_SOURCE varchar(128) NULL,
		UF_STAT_AD_TYPE varchar(128) NULL,
		UF_APPMECA_TRACKER varchar(128) NULL,
		UF_STAT_SOURCE varchar(128) NULL,
		UF_LOGINOM_STATUS varchar (128) NULL,
		UF_LOGINOM_PRIORITY int NULL,
		UF_LOGINOM_GROUP varchar(128) NULL,
		UF_LOGINOM_CHANNEL varchar(128) NULL,
		UF_UPDATED_AT datetime2 NULL,
		-- вычисляемые поля
		PhoneNumber varchar(20) NULL, -- UF_PHONE, очищенный от всех символов, кроме цифр, и от кода страны
		UF_REGISTERED_AT_date date,  -- (case UF_REGISTERED_AT as date)
		UF_UPDATED_AT_date date, -- (case UF_UPDATED_AT as date)
		[Тип-Источник] nvarchar(255) NULL,
		[CPA] nvarchar(255) NULL,
		[cpc] nvarchar(100) NULL,
		[Партнеры] varchar(31) NULL,
		[Органика] nvarchar(100) NULL,
		[Остальные1] nvarchar(35) NULL,
		[Представление] varchar(33) NULL
		--[Канал от источника] nvarchar(255) NULL,
		--[Группа каналов] NVARCHAR(255) NULL
	)
	--CREATE CLUSTERED COLUMNSTORE INDEX CS_IX ON #t_w_chanals0


	--SELECT @StartDate = getdate(), @row_count = 0
	--CREATE NONCLUSTERED INDEX [nci_row] ON #tmp2BE338B9_lcrm_leads_channel(UF_ROW_ID, UF_TYPE, UF_SOURCE)
	--IF @Debug = 1 BEGIN
	--	SELECT 'CREATE INDEX ON #tmp2BE338B9_lcrm_leads_channel', @row_count, datediff(SECOND, @StartDate, getdate())
	--END


	SELECT @StartDate = getdate(), @row_count = 0

	INSERT #t_w_chanals0
	with(tablockX)
	(
		ID,
		DWHInsertedDate,
		--
		UF_REGISTERED_AT,
		UF_PHONE,
		UF_NAME,
		UF_ROW_ID,
		UF_STAT_CAMPAIGN,
		UF_STAT_CLIENT_ID_YA,
		UF_STAT_CLIENT_ID_GA,
		UF_TYPE,
		UF_SOURCE,
		UF_STAT_AD_TYPE,
		UF_APPMECA_TRACKER,
		UF_STAT_SOURCE,
		UF_LOGINOM_STATUS,
		UF_LOGINOM_PRIORITY,
		UF_LOGINOM_GROUP,
		UF_LOGINOM_CHANNEL,
		UF_UPDATED_AT,
		--
		PhoneNumber,
		UF_REGISTERED_AT_date,
		UF_UPDATED_AT_date,
		[Тип-Источник],
		CPA,
		cpc,
		Партнеры,
		Органика,
		Остальные1,
		Представление
	)
	SELECT 
		F.ID,
		F.DWHInsertedDate,
		--
		F.UF_REGISTERED_AT,
		F.UF_PHONE,
		F.UF_NAME,
		F.UF_ROW_ID,
		F.UF_STAT_CAMPAIGN,
		F.UF_STAT_CLIENT_ID_YA,
		F.UF_STAT_CLIENT_ID_GA,
		F.UF_TYPE,
		F.UF_SOURCE,
		F.UF_STAT_AD_TYPE,
		F.UF_APPMECA_TRACKER,
		F.UF_STAT_SOURCE,
		F.UF_LOGINOM_STATUS,
		F.UF_LOGINOM_PRIORITY,
		F.UF_LOGINOM_GROUP,
		F.UF_LOGINOM_CHANNEL,
		F.UF_UPDATED_AT,
		--
		PhoneNumber = replace(replace(replace(replace(replace(replace(replace(replace(trim(F.UF_PHONE),'-',''),'(',''),')',''),' ',''),'.',''),'"',''),'''',''),',',''),
		UF_REGISTERED_AT_date = cast(F.UF_REGISTERED_AT AS date),
		UF_UPDATED_AT_date = cast(F.UF_UPDATED_AT AS date),
		r2.[Тип-Источник],
		CPA = 
			CASE 
				--BP-1884
				--WHEN nullif(crq.Канал_от_источника,'') IS NOT NULL THEN crq.Канал_от_источника --DWH-1868
				WHEN F.UF_NAME LIKE '%тест%'OR F.UF_NAME LIKE '%test%' OR F.UF_SOURCE LIKE '%test%'
					THEN N'Тест' 
				ELSE 
					--CASE 
					--	WHEN F.UF_TYPE LIKE '%investicii%'
					--		THEN N'Инвестиции'
					--	ELSE 
					--	
					--END 
					--DWH-1631, BP-2105
					CASE 
						WHEN F.UF_TYPE in ('site3_gazprom_bank' , 'site3_gazprom_bank_installment')
							THEN 'Газпром' 
						WHEN F.UF_TYPE in ('site3_soyuz', 'site3_soyuz_installment')
							THEN 'Союз' 
						WHEN r2.[Канал от источника] is not null 
							THEN r2.[Канал от источника]
						WHEN r2_stat.[Канал от источника] is not NULL
							THEN r2_stat.[Канал от источника]
						ELSE NULL
					END
			END,
		cpc = _lcrm.CalculateCPC(F.UF_STAT_CAMPAIGN, F.UF_APPMECA_TRACKER, F.UF_STAT_SOURCE, F.UF_STAT_AD_TYPE, F.UF_STAT_SYSTEM, F.UF_CLB_CHANNEL),

		--dwh-1417
		Партнеры = _LCRM.CalculatePartner(F.UF_STAT_AD_TYPE, F.UF_TYPE),

		-- DWH-1395
		Органика = _lcrm.CalculateOrganic(F.UF_APPMECA_TRACKER, F.UF_STAT_CLIENT_ID_YA, F.UF_STAT_CLIENT_ID_GA, F.UF_TYPE),

		/*
		--DWH-1940. Комментарю
		Остальные1 = 
			CASE 
				WHEN isnull(F.UF_ROW_ID, '') <> '' 
					THEN 
						CASE 
							WHEN Spr.Представление IN ('Ввод операторами FEDOR', 'Ввод операторами LCRM', 'Ввод операторами стороннего КЦ', 'Ввод операторами КЦ')
								THEN N'Канал привлечения не определен - КЦ'
							ELSE
								CASE 
									WHEN Spr.Представление IN ('Оформление на клиентском сайте', 'Оформление в мобильном приложении')
										THEN N'Канал привлечения не определен - МП'
									ELSE
										CASE 
											WHEN Spr.Представление IN (N'Оформление на партнерском сайте') 
												THEN N'Оформление на партнерском сайте'
											ELSE 
												CASE 
													WHEN F.UF_TYPE IN ('registry_mobile_app', 'registry_lkk',N'mobile_register')
														THEN N'Канал привлечения не определен - МП'
													--ELSE N'Другое'
													--DWH-1631, BP-2105
													ELSE N'Канал привлечения не определен - КЦ'
												END
										END
								END
						END
					ELSE 
						CASE
							WHEN isnull(F.UF_ROW_ID, '') = ''
								THEN
									CASE 
										WHEN F.UF_TYPE IN ('registry_mobile_app', 'registry_lkk', 'mobile_register')
											THEN N'Канал привлечения не определен - МП'
										--ELSE N'Другое'
										--DWH-1631, BP-2105
										ELSE N'Канал привлечения не определен - КЦ'
									END
						END
			END,
		*/
		--DWH-1940
		Остальные1 =
			CASE 
				WHEN F.UF_TYPE IN ('registry_mobile_app', 'registry_lkk', 'mobile_register')
					THEN N'Канал привлечения не определен - МП'
				--ELSE N'Другое'
				--DWH-1631, BP-2105
				ELSE N'Канал привлечения не определен - КЦ'
			END,

		Spr.Представление
	--into #t_w_chanals0
	FROM #tmp2BE338B9_lcrm_leads_channel AS F
		LEFT JOIN [_1cCRM].[Документ_ЗаявкаНаЗаймПодПТС] AS Z 
			--ON cast(F.UF_ROW_ID AS nvarchar(28)) = Z.Номер
			ON F.UF_ROW_ID = Z.Номер
		LEFT JOIN [_1cCRM].[Перечисление_СпособыОформленияЗаявок] AS Spr 
			ON Z.СпособОформления=Spr.Ссылка
		LEFT JOIN files.leadRef2_buffer AS r2
			ON 
				CASE 
					WHEN isnull(F.UF_TYPE, '') = ''
						THEN cast(F.UF_SOURCE AS nvarchar(1024))
					ELSE cast(F.UF_TYPE AS nvarchar(1024))+' - '+ cast(F.UF_SOURCE AS nvarchar(1024))
				END = r2.[Тип-Источник]
		LEFT JOIN files.leadRef2_buffer AS r2_stat
			ON cast(F.UF_TYPE AS nvarchar(1024))+' - '+ cast(F.UF_STAT_SOURCE AS nvarchar(1024))
			= r2_stat.[Тип-Источник]
		--DWH-1868 Отказ от таблицы ChannelRequestExceptions
		--LEFT JOIN _mds.ChannelRequestExceptions_prod AS crq 
		--	ON crq.external_id = cast(F.UF_ROW_ID AS nvarchar(28))
	OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

	SELECT @row_count = @@ROWCOUNT
	IF @Debug = 1 BEGIN
		SELECT 'INSERT #t_w_chanals0', @row_count, datediff(SECOND, @StartDate, getdate())
	END


	DROP TABLE IF EXISTS #t_w_chanals1

	CREATE TABLE #t_w_chanals1(
		ID numeric(10, 0) NULL,
		DWHInsertedDate datetime NOT NULL,
		-- поля для расчета вычисляемых полей
		UF_REGISTERED_AT datetime2 NULL,
		UF_PHONE varchar (128) NULL,
		UF_NAME varchar(512) NULL,
		UF_ROW_ID varchar(128) NULL,
		UF_STAT_CAMPAIGN varchar(512) NULL,
		UF_STAT_CLIENT_ID_YA varchar(128) NULL,
		UF_STAT_CLIENT_ID_GA varchar(128) NULL,
		UF_TYPE varchar(128) NULL,
		UF_SOURCE varchar(128) NULL,
		UF_STAT_AD_TYPE varchar(128) NULL,
		UF_APPMECA_TRACKER varchar(128) NULL,
		UF_STAT_SOURCE varchar(128) NULL,
		UF_LOGINOM_STATUS varchar (128) NULL,
		UF_LOGINOM_PRIORITY int NULL,
		UF_LOGINOM_GROUP varchar(128) NULL,
		UF_LOGINOM_CHANNEL varchar(128) NULL,
		UF_UPDATED_AT datetime2 NULL,
		-- вычисляемые поля
		PhoneNumber varchar(20) NULL, -- UF_PHONE, очищенный от всех символов, кроме цифр, и от кода страны
		UF_REGISTERED_AT_date date,  -- (case UF_REGISTERED_AT as date)
		UF_UPDATED_AT_date date, -- (case UF_UPDATED_AT as date)
		[Тип-Источник] nvarchar(255) NULL,
		[CPA] nvarchar(255) NULL,
		[cpc] nvarchar(100) NULL,
		[Партнеры] varchar(31) NULL,
		[Органика] nvarchar(100) NULL,
		[Остальные1] nvarchar(35) NULL,
		[Представление] varchar(33) NULL,
		[Канал от источника] nvarchar(255) NULL
		--[Группа каналов] NVARCHAR(255) NULL
	)
	--CREATE CLUSTERED COLUMNSTORE INDEX CS_IX ON #t_w_chanals1


	SELECT @StartDate = getdate(), @row_count = 0

	INSERT #t_w_chanals1
	with(tablockX)
	(
	    ID,
	    DWHInsertedDate,
		--
		UF_REGISTERED_AT,
		UF_PHONE,
	    UF_NAME,
	    UF_ROW_ID,
	    UF_STAT_CAMPAIGN,
	    UF_STAT_CLIENT_ID_YA,
	    UF_STAT_CLIENT_ID_GA,
	    UF_TYPE,
	    UF_SOURCE,
	    UF_STAT_AD_TYPE,
	    UF_APPMECA_TRACKER,
	    UF_STAT_SOURCE,
		UF_LOGINOM_STATUS,
		UF_LOGINOM_PRIORITY,
		UF_LOGINOM_GROUP,
		UF_LOGINOM_CHANNEL,
		UF_UPDATED_AT,
		--
		PhoneNumber,
	    UF_REGISTERED_AT_date,
	    UF_UPDATED_AT_date,
	    [Тип-Источник],
	    CPA,
	    cpc,
	    Партнеры,
	    Органика,
	    Остальные1,
	    Представление,
	    [Канал от источника]
	)
    SELECT 
	    F.ID,
        F.DWHInsertedDate,
		--
		F.UF_REGISTERED_AT,
		F.UF_PHONE,
        F.UF_NAME,
        F.UF_ROW_ID,
        F.UF_STAT_CAMPAIGN,
        F.UF_STAT_CLIENT_ID_YA,
        F.UF_STAT_CLIENT_ID_GA,
        F.UF_TYPE,
        F.UF_SOURCE,
        F.UF_STAT_AD_TYPE,
        F.UF_APPMECA_TRACKER,
        F.UF_STAT_SOURCE,
		F.UF_LOGINOM_STATUS,
		F.UF_LOGINOM_PRIORITY,
		F.UF_LOGINOM_GROUP,
		F.UF_LOGINOM_CHANNEL,
		F.UF_UPDATED_AT,
		--
		PhoneNumber = 
			CASE 
				WHEN left(F.PhoneNumber, 1) = '+' AND len(F.PhoneNumber) = 12
					THEN substring(F.PhoneNumber,3,10)
				WHEN left(F.PhoneNumber, 1) = '8' AND len(F.PhoneNumber) = 11
					THEN substring(F.PhoneNumber,2,10)
				ELSE F.PhoneNumber
			END,
        F.UF_REGISTERED_AT_date,
        F.UF_UPDATED_AT_date,
        F.[Тип-Источник],
        F.CPA,
        F.cpc,
        F.Партнеры,
        F.Органика,
        F.Остальные1,
        F.Представление,
		--BP-1923
		[Канал от источника]=
			CASE 
				WHEN F.CPA IS NOT NULL THEN F.CPA
				WHEN F.CPC IS NOT NULL THEN F.CPC
				WHEN F.Партнеры IS NOT NULL THEN F.Партнеры
				WHEN F.UF_APPMECA_TRACKER LIKE 'CPA_Mobishark%' 
					OR F.UF_APPMECA_TRACKER LIKE 'AutocreatedAppleSearchCampaign%'
					OR F.UF_APPMECA_TRACKER = 'CPA_Admitad_CarMoney'
					OR F.UF_APPMECA_TRACKER LIKE 'CPA_Appska%'
					OR F.UF_APPMECA_TRACKER LIKE 'CPA_Kizzmedia%' --DWH-1745
					--DWH-1768
					OR F.UF_APPMECA_TRACKER LIKE 'CPA_Bemoreworth%'
					OR F.UF_APPMECA_TRACKER LIKE 'CPA_Lizzads%'
					OR F.UF_APPMECA_TRACKER LIKE 'CPA_RTBModel%'
					OR F.UF_APPMECA_TRACKER LIKE 'CPA_Hawkey%'
					OR F.UF_APPMECA_TRACKER LIKE 'CPA_Marversal%' 
					--// end DWH-1768
					OR F.UF_APPMECA_TRACKER LIKE 'CPA_Deemobi%' --DWH-1779
					OR F.UF_APPMECA_TRACKER LIKE 'CPA_Trafficshark%' --DWH-1779
					OR F.UF_APPMECA_TRACKER LIKE 'CPA_Zen_CarMoney%' --DWH-1793
					OR F.UF_APPMECA_TRACKER LIKE 'CPA_Whiteleads_CarMoney%' --DWH-1828 / было 'CPA_WL_CarMoney%' --DWH-1801
					OR F.UF_APPMECA_TRACKER LIKE 'CPA_Mobupps_CarMoney%' --DWH-1940 
					OR F.UF_APPMECA_TRACKER LIKE 'CPA_2Leads_CarMoney%' --DWH-1999
					OR F.UF_APPMECA_TRACKER LIKE 'CPA_MobZilla_CarMoney%'  
					THEN N'CPA целевой'
				WHEN F.Органика IS NOT NULL THEN F.Органика
				WHEN F.Остальные1 IS NOT NULL THEN F.Остальные1
				--ELSE N'Другое' 
				--DWH-1631, BP-2105
				ELSE N'Канал привлечения не определен - КЦ' 
			END
    --into #t_w_chanals1
	FROM #t_w_chanals0 AS F
	OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

	SELECT @row_count = @@ROWCOUNT
	IF @Debug = 1 BEGIN
		SELECT 'INSERT #t_w_chanals1', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	SELECT @StartDate = getdate(), @row_count = 0
	--CREATE NONCLUSTERED INDEX [nci_row] ON #t_w_chanals1([Канал от источника] ASC)
	IF @Debug = 1 BEGIN
		SELECT 'CREATE INDEX ON #t_w_chanals1', @row_count, datediff(SECOND, @StartDate, getdate())
	END


    DROP TABLE IF EXISTS #t_w_chanals2
        
	CREATE TABLE #t_w_chanals2(
		ID numeric(10, 0) NULL,
		DWHInsertedDate datetime NOT NULL,
		-- поля для расчета вычисляемых полей
		UF_REGISTERED_AT datetime2 NULL,
		UF_PHONE varchar (128) NULL,
		UF_NAME varchar(512) NULL,
		UF_ROW_ID varchar(128) NULL,
		UF_STAT_CAMPAIGN varchar(512) NULL,
		UF_STAT_CLIENT_ID_YA varchar(128) NULL,
		UF_STAT_CLIENT_ID_GA varchar(128) NULL,
		UF_TYPE varchar(128) NULL,
		UF_SOURCE varchar(128) NULL,
		UF_STAT_AD_TYPE varchar(128) NULL,
		UF_APPMECA_TRACKER varchar(128) NULL,
		UF_STAT_SOURCE varchar(128) NULL,
		UF_LOGINOM_STATUS varchar (128) NULL,
		UF_LOGINOM_PRIORITY int NULL,
		UF_LOGINOM_GROUP varchar(128) NULL,
		UF_LOGINOM_CHANNEL varchar(128) NULL,
		UF_UPDATED_AT datetime2 NULL,
		-- вычисляемые поля
		PhoneNumber varchar(20) NULL, -- UF_PHONE, очищенный от всех символов, кроме цифр, и от кода страны
		UF_REGISTERED_AT_date date,  -- (case UF_REGISTERED_AT as date)
		UF_UPDATED_AT_date date, -- (case UF_UPDATED_AT as date)
		[Тип-Источник] nvarchar(255) NULL,
		[CPA] nvarchar(255) NULL,
		[cpc] nvarchar(100) NULL,
		[Партнеры] varchar(31) NULL,
		[Органика] nvarchar(100) NULL,
		[Остальные1] nvarchar(35) NULL,
		[Представление] varchar(33) NULL,
		[Канал от источника] nvarchar(255) NULL,
		[Группа каналов] nvarchar(255) NULL,
		DWH_HASH varbinary(32) NULL
	)
	--CREATE CLUSTERED COLUMNSTORE INDEX CS_IX ON #t_w_chanals2

	DROP TABLE IF EXISTS #t_ID_HASH

	CREATE TABLE #t_ID_HASH(
		ID numeric(10, 0) NULL,
		DWH_HASH varbinary(32) NULL
	)


	SELECT @StartDate = getdate(), @row_count = 0

	INSERT #t_w_chanals2
	with(tablockX)
	(
	    ID,
	    DWHInsertedDate,
		--
		UF_REGISTERED_AT,
		UF_PHONE,
	    UF_NAME,
	    UF_ROW_ID,
	    UF_STAT_CAMPAIGN,
	    UF_STAT_CLIENT_ID_YA,
	    UF_STAT_CLIENT_ID_GA,
	    UF_TYPE,
	    UF_SOURCE,
	    UF_STAT_AD_TYPE,
	    UF_APPMECA_TRACKER,
	    UF_STAT_SOURCE,
		UF_LOGINOM_STATUS,
		UF_LOGINOM_PRIORITY,
		UF_LOGINOM_GROUP,
		UF_LOGINOM_CHANNEL,
		UF_UPDATED_AT,
		--
		PhoneNumber,
	    UF_REGISTERED_AT_date,
	    UF_UPDATED_AT_date,
	    [Тип-Источник],
	    CPA,
	    cpc,
	    Партнеры,
	    Органика,
	    Остальные1,
	    Представление,
	    [Канал от источника],
	    [Группа каналов],
		DWH_HASH
	)
    SELECT DISTINCT 
		F.ID,
        F.DWHInsertedDate,
		--
		F.UF_REGISTERED_AT,
		F.UF_PHONE,
        F.UF_NAME,
        F.UF_ROW_ID,
        F.UF_STAT_CAMPAIGN,
        F.UF_STAT_CLIENT_ID_YA,
        F.UF_STAT_CLIENT_ID_GA,
        F.UF_TYPE,
        F.UF_SOURCE,
        F.UF_STAT_AD_TYPE,
        F.UF_APPMECA_TRACKER,
        F.UF_STAT_SOURCE,
		F.UF_LOGINOM_STATUS,
		F.UF_LOGINOM_PRIORITY,
		F.UF_LOGINOM_GROUP,
		F.UF_LOGINOM_CHANNEL,
		F.UF_UPDATED_AT,
		--
		F.PhoneNumber,
        F.UF_REGISTERED_AT_date,
        F.UF_UPDATED_AT_date,
        F.[Тип-Источник],
        F.CPA,
        F.cpc,
        F.Партнеры,
        F.Органика,
        F.Остальные1,
        F.Представление,
        F.[Канал от источника],
		r1.[Группа каналов],
		DWH_HASH = hashbytes('SHA2_256', 
			concat(
				F.UF_PHONE,'|',
				F.PhoneNumber,'|',
				F.UF_ROW_ID,'|',
				convert(varchar(8), F.UF_REGISTERED_AT_date, 112),'|',
				convert(varchar(8), F.UF_UPDATED_AT_date, 112),'|',
				F.[Тип-Источник],'|',
				F.CPA,'|',
				F.cpc,'|',
				F.Партнеры,'|',
				F.Органика,'|',
				F.Остальные1,'|',
				F.Представление,'|',
				F.[Канал от источника],'|',
				r1.[Группа каналов],'|',
				convert(varchar(19), F.UF_REGISTERED_AT, 120),'|',
				F.UF_TYPE,'|',
				F.UF_SOURCE,'|',
				F.UF_LOGINOM_STATUS,'|',
				convert(varchar(10), F.UF_LOGINOM_PRIORITY),'|',
				F.UF_LOGINOM_GROUP,'|',
				F.UF_LOGINOM_CHANNEL,'|',
				convert(varchar(19), F.UF_UPDATED_AT, 120)
			)
		)
    --into #t_w_chanals2
    FROM #t_w_chanals1 AS F
		LEFT JOIN files.leadRef1_buffer AS r1
			ON f.[Канал от источника] = r1.[Канал от источника]
	OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

	SELECT @row_count = @@ROWCOUNT
	IF @Debug = 1 BEGIN
		SELECT 'INSERT #t_w_chanals2', @row_count, datediff(SECOND, @StartDate, getdate())
	END


	-------------------------------------------------------------------------------
	-- добавить записи в _LCRM.lcrm_leads_full_channel_request_NEW
	DROP TABLE IF EXISTS #t_crib_crm_requests
	CREATE TABLE #t_crib_crm_requests
	(
		requestNumber varchar(255),
		leadGeneratorId varchar(255),
		city_region varchar(255),
		visit_stat_info varchar(8000),
		leadGeneratorClickId varchar(255),
		lead_leadgen_name varchar(255)
	)

	INSERT #t_crib_crm_requests
	(
	    requestNumber,
	    leadGeneratorId,
	    city_region,
	    visit_stat_info,
	    leadGeneratorClickId,
	    lead_leadgen_name
	)
	SELECT 
		B.requestNumber,
		B.leadGeneratorId,
		B.city_region,
		B.visit_stat_info,
		B.leadGeneratorClickId,
		B.lead_leadgen_name
	FROM (
		SELECT 
			S.requestNumber,
			S.leadGeneratorId,
			S.city_region,
			S.visit_stat_info,
			S.leadGeneratorClickId,
			S.lead_leadgen_name,
			rn = row_number() OVER(PARTITION BY S.requestNumber ORDER BY S.updated)
		FROM #t_w_chanals2 AS F
			INNER JOIN _crib.dm_crm_requests AS S
				ON F.UF_ROW_ID = S.requestNumber
		) AS B
	WHERE B.rn = 1

	CREATE UNIQUE CLUSTERED INDEX ix_requestNumber ON #t_crib_crm_requests(requestNumber)


	DROP TABLE IF EXISTS #lcrm_leads_request 
	CREATE TABLE #lcrm_leads_request
	(
		ID numeric (10, 0) NOT NULL,
		DWHInsertedDate datetime NOT NULL,
		UF_NAME varchar (512) NULL,
		UF_PHONE varchar (128) NULL,
		PhoneNumber varchar(20) NULL, -- UF_PHONE, очищенный от всех символов, кроме цифр, и от кода страны
		UF_REGISTERED_AT datetime2 NULL,
		UF_REGISTERED_AT_date date NULL,  -- cast UF_REGISTERED_AT as date
		UF_UPDATED_AT datetime2 NULL,
		UF_UPDATED_AT_date date NULL, -- cast UF_UPDATED_AT as date
		UF_ROW_ID varchar (128) NULL,
		UF_AGENT_NAME varchar (128) NULL,
		UF_STAT_CAMPAIGN varchar (512) NULL,
		UF_STAT_CLIENT_ID_YA varchar (128) NULL,
		UF_STAT_CLIENT_ID_GA varchar (128) NULL,
		UF_TYPE varchar (128) NULL,
		UF_SOURCE varchar (128) NULL,
		UF_ACTUALIZE_AT datetime2 NULL,
		UF_CAR_MARK varchar (128) NULL,
		UF_CAR_MODEL varchar (128) NULL,
		UF_PHONE_ADD varchar (128) NULL,
		UF_PARENT_ID int NULL,
		UF_GROUP_ID varchar (128) NULL,
		UF_PRIORITY int NULL,
		UF_RC_REJECT_CM varchar (512) NULL,
		UF_APPMECA_TRACKER varchar (128) NULL,
		UF_LOGINOM_CHANNEL varchar (128) NULL,
		UF_LOGINOM_GROUP varchar (128) NULL,
		UF_LOGINOM_PRIORITY int NULL,
		UF_LOGINOM_STATUS varchar (128) NULL,
		UF_LOGINOM_DECLINE varchar (128) NULL,
		[Канал от источника] nvarchar (255) NULL,
		[Группа каналов] nvarchar (255) NULL,
		UF_CLID nvarchar (72) NULL,
		UF_MATCH_ALGORITHM nvarchar (26) NULL,
		UF_CLB_CHANNEL nvarchar (50) NULL,
		UF_LOAN_MONTH_COUNT int NULL,
		UF_STAT_SYSTEM nvarchar (16) NULL,
		UF_STAT_DETAIL_INFO nvarchar (1236) NULL,
		UF_STAT_TERM nvarchar (1070) NULL,
		UF_STAT_FIRST_PAGE nvarchar (2032) NULL,
		UF_STAT_INT_PAGE nvarchar (1268) NULL,
		UF_CLT_NAME_FIRST nvarchar (128) NULL,
		UF_CLT_BIRTH_DAY date NULL,
		UF_CLT_EMAIL nvarchar (60) NULL,
		UF_CLT_AVG_INCOME int NULL,
		UF_CAR_COST_RUB int NULL,
		UF_CAR_ISSUE_YEAR float NULL,
		UF_STAT_AD_TYPE varchar (128) NULL,
		--
		UF_STAT_SOURCE varchar (128) NULL,
		UF_FROM_SITE int NULL,
		UF_VIEWED int NULL,
		UF_PARTNER_ID nvarchar (256) NULL,
		UF_SUM_ACCEPTED float NULL,
		UF_SUM_LOAN float NULL,
		UF_REGIONS_COMPOSITE nvarchar (128) NULL,
		UF_ISSUED_AT datetime2 NULL,
		UF_TARGET int NULL,
		UF_FULL_FORM_LEAD int NULL,
		UF_STEP int NULL,
		UF_SOURCE_SHADOW nvarchar (128) NULL,
		UF_TYPE_SHADOW nvarchar (128) NULL,
		UF_CLB_TYPE nvarchar (128) NULL,
		UF_CLIENT_ID nvarchar (128) NULL,
		--
		leadGeneratorId varchar(255),
		city_region varchar(255),
		visit_stat_info varchar(8000),
		leadGeneratorClickId varchar(255),
		lead_leadgen_name varchar(255),
		--
		DWH_HASH varbinary(32) NOT NULL
	)

	SELECT @StartDate = getdate(), @row_count = 0

	INSERT #lcrm_leads_request with(TablockX)
	(
	    ID,
	    DWHInsertedDate,
	    UF_NAME,
	    UF_PHONE,
	    PhoneNumber,
	    UF_REGISTERED_AT,
	    UF_REGISTERED_AT_date,
	    UF_UPDATED_AT,
	    UF_UPDATED_AT_date,
	    UF_ROW_ID,
	    UF_AGENT_NAME,
	    UF_STAT_CAMPAIGN,
	    UF_STAT_CLIENT_ID_YA,
	    UF_STAT_CLIENT_ID_GA,
	    UF_TYPE,
	    UF_SOURCE,
	    UF_ACTUALIZE_AT,
	    UF_CAR_MARK,
	    UF_CAR_MODEL,
	    UF_PHONE_ADD,
	    UF_PARENT_ID,
	    UF_GROUP_ID,
	    UF_PRIORITY,
	    UF_RC_REJECT_CM,
	    UF_APPMECA_TRACKER,
	    UF_LOGINOM_CHANNEL,
	    UF_LOGINOM_GROUP,
	    UF_LOGINOM_PRIORITY,
	    UF_LOGINOM_STATUS,
	    UF_LOGINOM_DECLINE,
	    [Канал от источника],
	    [Группа каналов],
	    UF_CLID,
	    UF_MATCH_ALGORITHM,
	    UF_CLB_CHANNEL,
	    UF_LOAN_MONTH_COUNT,
	    UF_STAT_SYSTEM,
	    UF_STAT_DETAIL_INFO,
	    UF_STAT_TERM,
	    UF_STAT_FIRST_PAGE,
	    UF_STAT_INT_PAGE,
	    UF_CLT_NAME_FIRST,
	    UF_CLT_BIRTH_DAY,
	    UF_CLT_EMAIL,
	    UF_CLT_AVG_INCOME,
	    UF_CAR_COST_RUB,
	    UF_CAR_ISSUE_YEAR,
	    UF_STAT_AD_TYPE,
		--
		UF_STAT_SOURCE,
		UF_FROM_SITE,
		UF_VIEWED,
		UF_PARTNER_ID,
		UF_SUM_ACCEPTED,
		UF_SUM_LOAN,
		UF_REGIONS_COMPOSITE,
		UF_ISSUED_AT,
		UF_TARGET,
		UF_FULL_FORM_LEAD,
		UF_STEP,
		UF_SOURCE_SHADOW,
		UF_TYPE_SHADOW,
		UF_CLB_TYPE,
		UF_CLIENT_ID,
		--
		leadGeneratorId,
		city_region,
		visit_stat_info,
		leadGeneratorClickId,
		lead_leadgen_name,
		--
	    DWH_HASH
	)
	SELECT 
	    F.ID,
	    F.DWHInsertedDate,
	    F.UF_NAME,
	    F.UF_PHONE,
	    F.PhoneNumber,
	    C.UF_REGISTERED_AT,
	    F.UF_REGISTERED_AT_date,
	    C.UF_UPDATED_AT,
	    F.UF_UPDATED_AT_date,
	    F.UF_ROW_ID,
	    C.UF_AGENT_NAME,
	    F.UF_STAT_CAMPAIGN,
	    F.UF_STAT_CLIENT_ID_YA,
	    F.UF_STAT_CLIENT_ID_GA,
	    F.UF_TYPE,
	    F.UF_SOURCE,
	    C.UF_ACTUALIZE_AT,
	    C.UF_CAR_MARK,
	    C.UF_CAR_MODEL,
	    C.UF_PHONE_ADD,
	    C.UF_PARENT_ID,
	    C.UF_GROUP_ID,
	    C.UF_PRIORITY,
	    C.UF_RC_REJECT_CM,
	    F.UF_APPMECA_TRACKER,
	    C.UF_LOGINOM_CHANNEL,
	    C.UF_LOGINOM_GROUP,
	    C.UF_LOGINOM_PRIORITY,
	    C.UF_LOGINOM_STATUS,
	    C.UF_LOGINOM_DECLINE,
	    F.[Канал от источника],
	    F.[Группа каналов],
	    C.UF_CLID,
	    C.UF_MATCH_ALGORITHM,
	    C.UF_CLB_CHANNEL,
	    C.UF_LOAN_MONTH_COUNT,
	    C.UF_STAT_SYSTEM,
	    C.UF_STAT_DETAIL_INFO,
	    C.UF_STAT_TERM,
	    C.UF_STAT_FIRST_PAGE,
	    C.UF_STAT_INT_PAGE,
	    C.UF_CLT_NAME_FIRST,
	    C.UF_CLT_BIRTH_DAY,
	    C.UF_CLT_EMAIL,
	    C.UF_CLT_AVG_INCOME,
	    C.UF_CAR_COST_RUB,
	    C.UF_CAR_ISSUE_YEAR,
	    F.UF_STAT_AD_TYPE,
		--
		C.UF_STAT_SOURCE,
		C.UF_FROM_SITE,
		C.UF_VIEWED,
		C.UF_PARTNER_ID,
		C.UF_SUM_ACCEPTED,
		C.UF_SUM_LOAN,
		C.UF_REGIONS_COMPOSITE,
		C.UF_ISSUED_AT,
		C.UF_TARGET,
		C.UF_FULL_FORM_LEAD,
		C.UF_STEP,
		C.UF_SOURCE_SHADOW,
		C.UF_TYPE_SHADOW,
		C.UF_CLB_TYPE,
		C.UF_CLIENT_ID,
		--
		B.leadGeneratorId,
		B.city_region,
		B.visit_stat_info,
		B.leadGeneratorClickId,
		B.lead_leadgen_name,
		--
	    DWH_HASH = hashbytes('SHA2_256', 
			concat(
				F.UF_NAME,'|',
				F.UF_PHONE,'|',
				F.PhoneNumber,'|',
				convert(varchar(19), C.UF_REGISTERED_AT, 120),'|',
				convert(varchar(8), F.UF_REGISTERED_AT_date, 112),'|',
				convert(varchar(19), C.UF_UPDATED_AT, 120),'|',
				convert(varchar(8), F.UF_UPDATED_AT_date, 112),'|',
				F.UF_ROW_ID,'|',
				C.UF_AGENT_NAME,'|',
				F.UF_STAT_CAMPAIGN,'|',
				F.UF_STAT_CLIENT_ID_YA,'|',
				F.UF_STAT_CLIENT_ID_GA,'|',
				F.UF_TYPE,'|',
				F.UF_SOURCE,'|',
				convert(varchar(19), C.UF_ACTUALIZE_AT, 120),'|',
				C.UF_CAR_MARK,'|',
				C.UF_CAR_MODEL,'|',
				C.UF_PHONE_ADD,'|',
				convert(varchar(12), C.UF_PARENT_ID),'|',
				C.UF_GROUP_ID,'|',
				convert(varchar(12), C.UF_PRIORITY),'|',
				C.UF_RC_REJECT_CM,'|',
				F.UF_APPMECA_TRACKER,'|',
				C.UF_LOGINOM_CHANNEL,'|',
				C.UF_LOGINOM_GROUP,'|',
				convert(varchar(12), C.UF_LOGINOM_PRIORITY),'|',
				C.UF_LOGINOM_STATUS,'|',
				C.UF_LOGINOM_DECLINE,'|',
				F.[Канал от источника],'|',
				F.[Группа каналов],'|',
				C.UF_CLID,'|',
				C.UF_MATCH_ALGORITHM,'|',
				C.UF_CLB_CHANNEL,'|',
				convert(varchar(12), C.UF_LOAN_MONTH_COUNT),'|',
				C.UF_STAT_SYSTEM,'|',
				C.UF_STAT_DETAIL_INFO,'|',
				C.UF_STAT_TERM,'|',
				C.UF_STAT_FIRST_PAGE,'|',
				C.UF_STAT_INT_PAGE,'|',
				C.UF_CLT_NAME_FIRST,'|',
				C.UF_CLT_BIRTH_DAY,'|',
				convert(varchar(8), C.UF_CLT_BIRTH_DAY, 112),'|',
				C.UF_CLT_EMAIL,'|',
				convert(varchar(12), C.UF_CLT_AVG_INCOME),'|',
				convert(varchar(12), C.UF_CAR_COST_RUB),'|',
				convert(varchar(12), C.UF_CAR_ISSUE_YEAR),'|',
				F.UF_STAT_AD_TYPE,'|',
				--
				C.UF_STAT_SOURCE,'|',
				convert(varchar(12), C.UF_FROM_SITE),'|',
				convert(varchar(12), C.UF_VIEWED),'|',
				C.UF_PARTNER_ID,'|',
				convert(varchar(12), C.UF_SUM_ACCEPTED),'|',
				convert(varchar(12), C.UF_SUM_LOAN),'|',
				C.UF_REGIONS_COMPOSITE,'|',
				convert(varchar(19), C.UF_ISSUED_AT, 120),'|',
				convert(varchar(12), C.UF_TARGET),'|',
				convert(varchar(12), C.UF_FULL_FORM_LEAD),'|',
				convert(varchar(12), C.UF_STEP),'|',
				C.UF_SOURCE_SHADOW,'|',
				C.UF_TYPE_SHADOW,'|',
				C.UF_CLB_TYPE,'|',
				C.UF_CLIENT_ID,'|',
				--
				B.leadGeneratorId,'|',
				B.city_region,'|',
				hashbytes('SHA2_256', B.visit_stat_info),'|',
				B.leadGeneratorClickId,'|',
				B.lead_leadgen_name
			)
		)
	FROM #t_w_chanals2 AS F
		INNER JOIN #tmp2BE338B9_lcrm_leads_channel AS C
			ON F.ID = C.ID
		LEFT JOIN _LCRM.lcrm_leads_full_channel_request_NEW AS T WITH(NOLOCK) --DWH-1840
			ON F.ID = T.ID
		LEFT JOIN #t_crib_crm_requests AS B
			ON B.requestNumber = F.UF_ROW_ID
	WHERE F.UF_ROW_ID IS NOT NULL
		OR T.ID IS NOT NULL --DWH-1840 -- добавить записи, которые уже есть в _request

	SELECT @row_count = @@ROWCOUNT
	IF @Debug = 1 BEGIN
		SELECT 'INSERT #lcrm_leads_request', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	SELECT @StartDate = getdate(), @row_count = 0
	CREATE NONCLUSTERED INDEX [nci_row] ON #lcrm_leads_request(ID, DWH_HASH)
	IF @Debug = 1 BEGIN
		SELECT 'CREATE INDEX ON #lcrm_leads_request', @row_count, datediff(SECOND, @StartDate, getdate())
	END
	
	BEGIN TRAN
		SELECT @StartDate = getdate(), @row_count = 0

		-- из врем. табл. удалить записи с теми же значениями полей
		DELETE S
		FROM #lcrm_leads_request AS S WITH(INDEX=nci_row)
			INNER JOIN _LCRM.lcrm_leads_full_channel_request_NEW AS T WITH(INDEX=ci_id)
				ON S.ID = T.ID
				AND S.DWH_HASH = T.DWH_HASH

		SELECT @row_count = @@ROWCOUNT
		IF @Debug = 1 BEGIN
			SELECT 'DELETE FROM #lcrm_leads_request', @row_count, datediff(SECOND, @StartDate, getdate())
		END

		SELECT @StartDate = getdate(), @row_count = 0

		IF EXISTS(SELECT TOP(1) 1 FROM #lcrm_leads_request AS S)
		BEGIN
			DELETE T
			FROM 
			#lcrm_leads_request AS S WITH(INDEX=nci_row)
				INNER JOIN _LCRM.lcrm_leads_full_channel_request_NEW AS T WITH(INDEX=ci_id) --, readpast) --похоже, что readpast приводит к дублям по ID
					ON S.ID = T.ID
		END

		SELECT @row_count = @@ROWCOUNT
		IF @Debug = 1 BEGIN
			SELECT 'DELETE FROM lcrm_leads_full_channel_request', @row_count, datediff(SECOND, @StartDate, getdate())
		END

		--DWH-1840
		DELETE S
		FROM #lcrm_leads_request AS S
		WHERE S.UF_ROW_ID IS NULL

		SELECT @StartDate = getdate(), @row_count = 0
		INSERT _LCRM.lcrm_leads_full_channel_request_NEW
		--with(tablockX)
		(
		    ID,
		    DWHInsertedDate,
		    UF_NAME,
		    UF_PHONE,
		    PhoneNumber,
		    UF_REGISTERED_AT,
		    UF_REGISTERED_AT_date,
		    UF_UPDATED_AT,
		    UF_UPDATED_AT_date,
		    UF_ROW_ID,
		    UF_AGENT_NAME,
		    UF_STAT_CAMPAIGN,
		    UF_STAT_CLIENT_ID_YA,
		    UF_STAT_CLIENT_ID_GA,
		    UF_TYPE,
		    UF_SOURCE,
		    UF_ACTUALIZE_AT,
		    UF_CAR_MARK,
		    UF_CAR_MODEL,
		    UF_PHONE_ADD,
		    UF_PARENT_ID,
		    UF_GROUP_ID,
		    UF_PRIORITY,
		    UF_RC_REJECT_CM,
		    UF_APPMECA_TRACKER,
		    UF_LOGINOM_CHANNEL,
		    UF_LOGINOM_GROUP,
		    UF_LOGINOM_PRIORITY,
		    UF_LOGINOM_STATUS,
		    UF_LOGINOM_DECLINE,
		    [Канал от источника],
		    [Группа каналов],
		    UF_CLID,
		    UF_MATCH_ALGORITHM,
		    UF_CLB_CHANNEL,
		    UF_LOAN_MONTH_COUNT,
		    UF_STAT_SYSTEM,
		    UF_STAT_DETAIL_INFO,
		    UF_STAT_TERM,
		    UF_STAT_FIRST_PAGE,
		    UF_STAT_INT_PAGE,
		    UF_CLT_NAME_FIRST,
		    UF_CLT_BIRTH_DAY,
		    UF_CLT_EMAIL,
		    UF_CLT_AVG_INCOME,
		    UF_CAR_COST_RUB,
		    UF_CAR_ISSUE_YEAR,
		    UF_STAT_AD_TYPE,
			--
			UF_STAT_SOURCE,
			UF_FROM_SITE,
			UF_VIEWED,
			UF_PARTNER_ID,
			UF_SUM_ACCEPTED,
			UF_SUM_LOAN,
			UF_REGIONS_COMPOSITE,
			UF_ISSUED_AT,
			UF_TARGET,
			UF_FULL_FORM_LEAD,
			UF_STEP,
			UF_SOURCE_SHADOW,
			UF_TYPE_SHADOW,
			UF_CLB_TYPE,
			UF_CLIENT_ID,
			--
			leadGeneratorId,
			city_region,
			visit_stat_info,
			leadGeneratorClickId,
			lead_leadgen_name,
			--
		    DWH_HASH
		)
		SELECT
			F.ID,
            F.DWHInsertedDate,
            F.UF_NAME,
            F.UF_PHONE,
            F.PhoneNumber,
            F.UF_REGISTERED_AT,
            F.UF_REGISTERED_AT_date,
            F.UF_UPDATED_AT,
            F.UF_UPDATED_AT_date,
            F.UF_ROW_ID,
            F.UF_AGENT_NAME,
            F.UF_STAT_CAMPAIGN,
            F.UF_STAT_CLIENT_ID_YA,
            F.UF_STAT_CLIENT_ID_GA,
            F.UF_TYPE,
            F.UF_SOURCE,
            F.UF_ACTUALIZE_AT,
            F.UF_CAR_MARK,
            F.UF_CAR_MODEL,
            F.UF_PHONE_ADD,
            F.UF_PARENT_ID,
            F.UF_GROUP_ID,
            F.UF_PRIORITY,
            F.UF_RC_REJECT_CM,
            F.UF_APPMECA_TRACKER,
            F.UF_LOGINOM_CHANNEL,
            F.UF_LOGINOM_GROUP,
            F.UF_LOGINOM_PRIORITY,
            F.UF_LOGINOM_STATUS,
            F.UF_LOGINOM_DECLINE,
            F.[Канал от источника],
            F.[Группа каналов],
            F.UF_CLID,
            F.UF_MATCH_ALGORITHM,
            F.UF_CLB_CHANNEL,
            F.UF_LOAN_MONTH_COUNT,
            F.UF_STAT_SYSTEM,
            F.UF_STAT_DETAIL_INFO,
            F.UF_STAT_TERM,
            F.UF_STAT_FIRST_PAGE,
            F.UF_STAT_INT_PAGE,
            F.UF_CLT_NAME_FIRST,
            F.UF_CLT_BIRTH_DAY,
            F.UF_CLT_EMAIL,
            F.UF_CLT_AVG_INCOME,
            F.UF_CAR_COST_RUB,
            F.UF_CAR_ISSUE_YEAR,
            F.UF_STAT_AD_TYPE,
			--
			F.UF_STAT_SOURCE,
			F.UF_FROM_SITE,
			F.UF_VIEWED,
			F.UF_PARTNER_ID,
			F.UF_SUM_ACCEPTED,
			F.UF_SUM_LOAN,
			F.UF_REGIONS_COMPOSITE,
			F.UF_ISSUED_AT,
			F.UF_TARGET,
			F.UF_FULL_FORM_LEAD,
			F.UF_STEP,
			F.UF_SOURCE_SHADOW,
			F.UF_TYPE_SHADOW,
			F.UF_CLB_TYPE,
			F.UF_CLIENT_ID,
			--
			F.leadGeneratorId,
			F.city_region,
			F.visit_stat_info,
			F.leadGeneratorClickId,
			F.lead_leadgen_name,
			--
            F.DWH_HASH
		FROM #lcrm_leads_request AS F
		OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

		SELECT @row_count = @@ROWCOUNT
		IF @Debug = 1 BEGIN
			SELECT 'INSERT lcrm_leads_full_channel_request', @row_count, datediff(SECOND, @StartDate, getdate())
		END
	COMMIT TRAN
	--// добавить записи в _LCRM.lcrm_leads_full_channel_request_NEW


	-------------------------------------------------------------------------------
	-- добавить записи в _LCRM.lcrm_leads_full_calculated
	SELECT @StartDate = getdate(), @row_count = 0
	CREATE NONCLUSTERED INDEX [nci_row] ON #t_w_chanals2(ID, DWH_HASH)
		include(UF_REGISTERED_AT)
	IF @Debug = 1 BEGIN
		SELECT 'CREATE INDEX ON #t_w_chanals2', @row_count, datediff(SECOND, @StartDate, getdate())
	END
	SET LOCK_TIMEOUT 900000 --15мин
	BEGIN TRAN
		SELECT @StartDate = getdate(), @row_count = 0

		-- из врем. табл. удалить записи с теми же значениями полей
		/*
		--OLD
		DELETE S
		FROM #t_w_chanals2 AS S WITH(INDEX = nci_row)
			INNER JOIN _LCRM.lcrm_leads_full_calculated AS T WITH(INDEX = IX_leads_full_calculated_ID)
				ON S.ID = T.ID
				AND S.DWH_HASH = T.DWH_HASH
		*/
		truncate table #tPartitions

		insert into #tPartitions(PartitionId)
		select distinct $Partition.pfn_range_right_date_part_lcrm_leads_full_calculated(T.UF_REGISTERED_AT)
		from #t_w_chanals2 t

		INSERT #t_ID_HASH WITH(TABLOCKX)
			(ID, DWH_HASH)
		SELECT T.ID, T.DWH_HASH
		from _LCRM.lcrm_leads_full_calculated AS T with(nolock, index = IX_leads_full_calculated_ID_include_UF_UPDATED_AT_DWH_HASH_UF_ROW_ID)
		inner join #tPartitions p on p.PartitionId = $Partition.[pfn_range_right_date_part_lcrm_leads_full_calculated](T.UF_REGISTERED_AT)
		where exists(select top(1) 1 from  #t_w_chanals2 S where S.ID = T.ID
		)
		--FROM #t_w_chanals2 AS S WITH(INDEX = nci_row)
		--	INNER JOIN _LCRM.lcrm_leads_full_calculated AS T WITH(INDEX = IX_leads_full_calculated_ID)
		--		ON S.ID = T.ID


		CREATE INDEX IX1 ON #t_ID_HASH(ID, DWH_HASH)

		DELETE S
		FROM #t_w_chanals2 AS S --WITH(INDEX = nci_row)
		where exists (select top(1) 1 from #t_ID_HASH AS T WITH(INDEX = IX1)
				where S.ID = T.ID
				AND S.DWH_HASH = T.DWH_HASH
				)
			
			--INNER JOIN #t_ID_HASH AS T WITH(INDEX = IX1)
			--	ON S.ID = T.ID
			--	AND S.DWH_HASH = T.DWH_HASH

		SELECT @row_count = @@ROWCOUNT
		IF @Debug = 1 BEGIN
			SELECT 'DELETE FROM #t_w_chanals2', @row_count, datediff(SECOND, @StartDate, getdate())
		END


		SELECT @StartDate = getdate(), @row_count = 0

		IF EXISTS(SELECT TOP(1) 1 FROM #t_w_chanals2 AS S)
		BEGIN
			--удалить из основной таблицы

			/*
			DELETE T
			FROM _LCRM.lcrm_leads_full_calculated AS T --with(readpast) --похоже, что readpast приводит к дублям по ID
				--WITH(INDEX = IX_leads_full_calculated_ID)
				where exists(Select top(1) 1 from #t_w_chanals2 AS S 
					--WITH(INDEX = nci_row)
					where S.ID = T.ID)
			*/

			truncate table #tPartitions
			insert into #tPartitions(PartitionId)
			select distinct 
			$Partition.pfn_range_right_date_part_lcrm_leads_full_calculated(T.UF_REGISTERED_AT)
			from #t_w_chanals2 t
/*
			;with cte_lcrm_leads_full_calculated as 
			(
				select *
				from _LCRM.lcrm_leads_full_calculated t with(nolock)
				inner join #tPartitions p on p.PartitionId  
					= $Partition.[pfn_range_right_date_part_lcrm_leads_full_calculated](T.UF_REGISTERED_AT)
			)
			merge cte_lcrm_leads_full_calculated t
			using #t_w_chanals2 s
				on s.id = t.id
			when not matched then insert
				(
					ID,
					DWHInsertedDate,
					UF_PHONE,
					PhoneNumber,
					UF_ROW_ID,
					UF_REGISTERED_AT_date,
					UF_UPDATED_AT_date,
					[Тип-Источник],
					CPA,
					cpc,
					Партнеры,
					Органика,
					Остальные1,
					Представление,
					[Канал от источника],
					[Группа каналов],
					DWH_HASH,
					UF_REGISTERED_AT,
					UF_TYPE,
					UF_SOURCE,
					UF_LOGINOM_STATUS,
					UF_LOGINOM_PRIORITY,
					UF_LOGINOM_GROUP,
					UF_LOGINOM_CHANNEL,
					UF_UPDATED_AT,
					DWHUpdatedDate
				)
				values
				(
					s.ID,
					s.DWHInsertedDate,
					s.UF_PHONE,
					s.PhoneNumber,
					s.UF_ROW_ID,
					s.UF_REGISTERED_AT_date,
					s.UF_UPDATED_AT_date,
					s.[Тип-Источник],
					s.CPA,
					s.cpc,
					s.Партнеры,
					s.Органика,
					s.Остальные1,
					s.Представление,
					s.[Канал от источника],
					s.[Группа каналов],
					s.DWH_HASH,
					s.UF_REGISTERED_AT,
					s.UF_TYPE,
					s.UF_SOURCE,
					s.UF_LOGINOM_STATUS,
					s.UF_LOGINOM_PRIORITY,
					s.UF_LOGINOM_GROUP,
					s.UF_LOGINOM_CHANNEL,
					s.UF_UPDATED_AT,
					getdate()
					
				)
			when matched  and t.DWH_HASH !=s.DWH_HASH
				then update
			set
				DWHInsertedDate			=  s.DWHInsertedDate,
				UF_PHONE				=  s.UF_PHONE,
				PhoneNumber				=  s.PhoneNumber,
				UF_ROW_ID				=  s.UF_ROW_ID,
				UF_REGISTERED_AT_date	=  s.UF_REGISTERED_AT_date,
				UF_UPDATED_AT_date		=  s.UF_UPDATED_AT_date,
				[Тип-Источник]			=  s.[Тип-Источник],
				CPA						=  s.CPA,
				cpc						=  s.cpc,
				Партнеры				=  s.Партнеры,
				Органика				=  s.Органика,
				Остальные1				=  s.Остальные1,
				Представление			=  s.Представление,
				[Канал от источника]	=  s.[Канал от источника],
				[Группа каналов]		=  s.[Группа каналов],
				DWH_HASH				=  s.DWH_HASH,
				UF_REGISTERED_AT		=  s.UF_REGISTERED_AT,
				UF_TYPE					=  s.UF_TYPE,
				UF_SOURCE				=  s.UF_SOURCE,
				UF_LOGINOM_STATUS		=  s.UF_LOGINOM_STATUS,
				UF_LOGINOM_PRIORITY		=  s.UF_LOGINOM_PRIORITY,
				UF_LOGINOM_GROUP		=  s.UF_LOGINOM_GROUP,
				UF_LOGINOM_CHANNEL		=  s.UF_LOGINOM_CHANNEL,
				UF_UPDATED_AT			=  s.UF_UPDATED_AT,
				DWHUpdatedDate			=  getdate()
				;
			SELECT @row_count = @@ROWCOUNT
			IF @Debug = 1 BEGIN
				SELECT 'MERGE lcrm_leads_full_calculated', @row_count, datediff(SECOND, @StartDate, getdate())
			END
*/
			--DWH-2158 Пакетное удаление
			SELECT @batch_size = (select count(1) from #t_w_chanals2) * 10.0 / 100
			IF @batch_size = 0 BEGIN
				SELECT @batch_size = 1
			END
			--select @batch_size = 500
		
			
		
			SELECT @delete_count = 1

			--WHILE @delete_count > 0
			--begin
				DELETE 
					--TOP (@batch_size) 
					T
				FROM _LCRM.lcrm_leads_full_calculated AS T  
					--with(INDEX = [IX_leads_full_calculated_ID_include_UF_UPDATED_AT_DWH_HASH_UF_ROW_ID])
				inner join #t_w_chanals2 AS S-- WITH(INDEX = nci_row)
					ON S.ID = T.ID
					--and  $Partition.[pfn_range_right_date_part_lcrm_leads_full_calculated](T.UF_REGISTERED_AT) = 
					--	 $Partition.[pfn_range_right_date_part_lcrm_leads_full_calculated](s.UF_REGISTERED_AT)
				where exists(select top(1) 1 from 
				#tPartitions p where  p.PartitionId = 
					$Partition.[pfn_range_right_date_part_lcrm_leads_full_calculated](T.UF_REGISTERED_AT)
					)
				OPTION( QUERYTRACEON 610)
				SELECT @delete_count = @@ROWCOUNT
				SELECT @row_count = @row_count + @delete_count
			--end
		

		SELECT @row_count = @@ROWCOUNT
		IF @Debug = 1 BEGIN
			SELECT 'DELETE FROM lcrm_leads_full_calculated', @row_count, datediff(SECOND, @StartDate, getdate())
		END


		SELECT @StartDate = getdate(), @row_count = 0

		--добавить в основную таблицу
		INSERT _LCRM.lcrm_leads_full_calculated
		--with(tablockX)
		(
			ID,
			DWHInsertedDate,
			UF_PHONE,
			PhoneNumber,
			UF_ROW_ID,
			UF_REGISTERED_AT_date,
			UF_UPDATED_AT_date,
			[Тип-Источник],
			CPA,
			cpc,
			Партнеры,
			Органика,
			Остальные1,
			Представление,
			[Канал от источника],
			[Группа каналов],
			DWH_HASH,
			UF_REGISTERED_AT,
			UF_TYPE,
			UF_SOURCE,
			UF_LOGINOM_STATUS,
			UF_LOGINOM_PRIORITY,
			UF_LOGINOM_GROUP,
			UF_LOGINOM_CHANNEL,
			UF_UPDATED_AT,
			DWHUpdatedDate

		)
		SELECT 
			F.ID,
            F.DWHInsertedDate,
			F.UF_PHONE,
			F.PhoneNumber,
			F.UF_ROW_ID,
            F.UF_REGISTERED_AT_date,
            F.UF_UPDATED_AT_date,
            F.[Тип-Источник],
            F.CPA,
            F.cpc,
            F.Партнеры,
            F.Органика,
            F.Остальные1,
            F.Представление,
            F.[Канал от источника],
            F.[Группа каналов],
			F.DWH_HASH,
			F.UF_REGISTERED_AT,
			F.UF_TYPE,
			F.UF_SOURCE,
			F.UF_LOGINOM_STATUS,
			F.UF_LOGINOM_PRIORITY,
			F.UF_LOGINOM_GROUP,
			F.UF_LOGINOM_CHANNEL,
			F.UF_UPDATED_AT,
			DWHUpdatedDate = getdate()
		FROM #t_w_chanals2 AS F
		OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

		SELECT @row_count = @@ROWCOUNT
		IF @Debug = 1 BEGIN
			SELECT 'INSERT lcrm_leads_full_calculated', @row_count, datediff(SECOND, @StartDate, getdate())
		END

		
		END
	COMMIT TRAN
	--// добавить записи в _LCRM.lcrm_leads_full_calculated


	-- добавление записей в _LCRM.lcrm_leads_full
	IF @Insert_Into_lcrm_leads_full = 1
	BEGIN
		SELECT @StartDate = getdate(), @row_count = 0
		if not exists(Select top(1) 1 from tempdb.sys.indexes
			where object_id = object_id('tempdb..#tmp2BE338B9_lcrm_leads_channel')
			and name = 'CI_ID' and
			type_desc = 'CLUSTERED')
		begin
			CREATE CLUSTERED INDEX CI_ID ON #tmp2BE338B9_lcrm_leads_channel(ID, UF_REGISTERED_AT)
			IF @Debug = 1 BEGIN
				SELECT 'CREATE INDEX ON #tmp2BE338B9_lcrm_leads_channel', @row_count, datediff(SECOND, @StartDate, getdate())
			END
		end

		BEGIN TRAN
			SELECT @StartDate = getdate(), @row_count = 0

			DELETE T
			FROM #tmp2BE338B9_lcrm_leads_channel AS S --! WITH(INDEX=CI_ID)
				INNER JOIN _LCRM.lcrm_leads_full AS T --! WITH(INDEX=cix_id)
					ON S.ID = T.ID
					AND S.UF_REGISTERED_AT = T.UF_REGISTERED_AT

			SELECT @row_count = @@ROWCOUNT
			IF @Debug = 1 BEGIN
				SELECT 'DELETE FROM lcrm_leads_full', @row_count, datediff(SECOND, @StartDate, getdate())
			END

			SELECT @StartDate = getdate(), @row_count = 0
			INSERT _LCRM.lcrm_leads_full
		--	with(tablockX)
			(
				ID,
				UF_NAME,
				UF_PHONE,
				UF_REGISTERED_AT,
				UF_UPDATED_AT,
				UF_ROW_ID,
				UF_AGENT_NAME,
				UF_STAT_CAMPAIGN,
				UF_STAT_CLIENT_ID_YA,
				UF_STAT_CLIENT_ID_GA,
				UF_TYPE,
				UF_SOURCE,
				UF_STAT_AD_TYPE,
				UF_ACTUALIZE_AT,
				UF_CAR_MARK,
				UF_CAR_MODEL,
				UF_PHONE_ADD,
				UF_PARENT_ID,
				UF_GROUP_ID,
				UF_PRIORITY,
				UF_RC_REJECT_CM,
				UF_APPMECA_TRACKER,
				UF_LOGINOM_CHANNEL,
				UF_LOGINOM_GROUP,
				UF_LOGINOM_PRIORITY,
				UF_LOGINOM_STATUS,
				UF_LOGINOM_DECLINE,
				UF_CLID,
				UF_MATCH_ALGORITHM,
				UF_CLB_CHANNEL,
				UF_LOAN_MONTH_COUNT,
				UF_STAT_SYSTEM,
				UF_STAT_DETAIL_INFO,
				UF_STAT_TERM,
				UF_STAT_FIRST_PAGE,
				UF_STAT_INT_PAGE,
				UF_CLT_NAME_FIRST,
				UF_CLT_BIRTH_DAY,
				UF_CLT_EMAIL,
				UF_CLT_AVG_INCOME,
				UF_CAR_COST_RUB,
				UF_CAR_ISSUE_YEAR,
				--Добавили т.к потеряли
				UF_STAT_SOURCE,
				UF_FROM_SITE,
				UF_VIEWED,
				UF_PARTNER_ID,
				UF_SUM_ACCEPTED,
				UF_SUM_LOAN,
				UF_REGIONS_COMPOSITE,
				UF_ISSUED_AT,
				UF_TARGET,
				UF_FULL_FORM_LEAD,
				UF_STEP,
				UF_SOURCE_SHADOW,
				UF_TYPE_SHADOW,
				UF_CLB_TYPE,
				UF_CLIENT_ID
			)
			SELECT
				F.ID,
				F.UF_NAME,
				F.UF_PHONE,
				F.UF_REGISTERED_AT,
				F.UF_UPDATED_AT,
				F.UF_ROW_ID,
				F.UF_AGENT_NAME,
				F.UF_STAT_CAMPAIGN,
				F.UF_STAT_CLIENT_ID_YA,
				F.UF_STAT_CLIENT_ID_GA,
				F.UF_TYPE,
				F.UF_SOURCE,
				F.UF_STAT_AD_TYPE,
				F.UF_ACTUALIZE_AT,
				F.UF_CAR_MARK,
				F.UF_CAR_MODEL,
				F.UF_PHONE_ADD,
				F.UF_PARENT_ID,
				F.UF_GROUP_ID,
				F.UF_PRIORITY,
				F.UF_RC_REJECT_CM,
				F.UF_APPMECA_TRACKER,
				F.UF_LOGINOM_CHANNEL,
				F.UF_LOGINOM_GROUP,
				F.UF_LOGINOM_PRIORITY,
				F.UF_LOGINOM_STATUS,
				F.UF_LOGINOM_DECLINE,
				F.UF_CLID,
				F.UF_MATCH_ALGORITHM,
				F.UF_CLB_CHANNEL,
				F.UF_LOAN_MONTH_COUNT,
				F.UF_STAT_SYSTEM,
				F.UF_STAT_DETAIL_INFO,
				F.UF_STAT_TERM,
				F.UF_STAT_FIRST_PAGE,
				F.UF_STAT_INT_PAGE,
				F.UF_CLT_NAME_FIRST,
				F.UF_CLT_BIRTH_DAY,
				F.UF_CLT_EMAIL,
				F.UF_CLT_AVG_INCOME,
				F.UF_CAR_COST_RUB,
				F.UF_CAR_ISSUE_YEAR,
				--Добавили т.к потеряли
				F.UF_STAT_SOURCE,
				F.UF_FROM_SITE,
				F.UF_VIEWED,
				F.UF_PARTNER_ID,
				F.UF_SUM_ACCEPTED,
				F.UF_SUM_LOAN,
				F.UF_REGIONS_COMPOSITE,
				F.UF_ISSUED_AT,
				F.UF_TARGET,
				F.UF_FULL_FORM_LEAD,
				F.UF_STEP,
				F.UF_SOURCE_SHADOW,
				F.UF_TYPE_SHADOW,
				F.UF_CLB_TYPE,
				UF_CLIENT_ID
			FROM #tmp2BE338B9_lcrm_leads_channel AS F
			OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

			SELECT @row_count = @@ROWCOUNT
			IF @Debug = 1 BEGIN
				SELECT 'INSERT lcrm_leads_full', @row_count, datediff(SECOND, @StartDate, getdate())
			END
		COMMIT TRAN
	END
	--//end IF @Insert_Into_lcrm_leads_full = 1 -- добавление записей в _LCRM.lcrm_leads_full
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
END
