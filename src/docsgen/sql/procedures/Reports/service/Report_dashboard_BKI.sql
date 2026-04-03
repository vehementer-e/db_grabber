-- =============================================
-- Author:		А.Никитин
-- Create date: 2025-06-07
-- Description:	
-- =============================================
/*
EXEC Reports.service.Report_dashboard_BKI
	@Page = 'Detail'
	,@dtFrom = '2024-11-01'
	,@dtTo = '2024-12-10'

*/
CREATE PROC service.Report_dashboard_BKI
	@Page nvarchar(100) = 'Detail'
	,@dtFrom date = null -- '2021-04-01'
	,@dtTo date =  null --'2021-04-26'
	,@bki_name varchar(1000) = NULL
	,@entity_name varchar(1000) = NULL
	,@ProcessGUID varchar(36) = NULL -- guid процесса
	,@isDebug int = 0
AS
BEGIN
	SET NOCOUNT ON;
BEGIN TRY

	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50)
	DECLARE @description nvarchar(1024), @message nvarchar(1024), @error_number int
	DECLARE @dt_from date, @dt_to date

	IF @dtFrom is not NULL BEGIN
		SET @dt_from = @dtFrom
	END 
	ELSE BEGIN
		--SET @dt_from = cast(format(getdate(),'yyyyMM01') AS date)	         
		SET @dt_from = cast(dateadd(DAY, -1, getdate()) AS date)
	END

	IF @dtTo is not NULL BEGIN
		IF @dtTo > cast(getdate() AS date) BEGIN
			SELECT @dtTo = cast(getdate() AS date)
		END

		SET @dt_to = dateadd(day,1,@dtTo)
		--SET @dt_to = @dtTo
	END
	ELSE BEGIN
		--SET @dt_to = dateadd(day,1,cast(getdate() as date))
		SET @dt_to = cast(getdate() as date)
	END 

	DECLARE @t_bki_name table(bki_name varchar(55))
	IF @bki_name IS NOT NULL BEGIN
		INSERT @t_bki_name(bki_name)
		select bki_name = trim(value) 
		FROM string_split(@bki_name, ',')
	END

	DECLARE @t_entity_name table([entity_name] varchar(55))
	IF @entity_name IS NOT NULL BEGIN
		INSERT @t_entity_name([entity_name])
		select [entity_name] = trim(value) 
		FROM string_split(@entity_name, ',')
	END




	-- IMPORT
	DROP TABLE IF EXISTS #t_CRE_IMPORT_LOG_302

	SELECT TOP 0 
		INSERT_DAY = cast(NULL AS date),
		L.* 
	INTO #t_CRE_IMPORT_LOG_302
	--SELECT top 10 *
	FROM dwh2.dm.CRE_IMPORT_LOG_302 AS L

	-- 1 по INSERT_DATE
	INSERT #t_CRE_IMPORT_LOG_302
	SELECT 
		INSERT_DAY = cast(L.INSERT_DATE AS date),
		L.* 
	FROM dwh2.dm.CRE_IMPORT_LOG_302 AS L with(index = ix_INSERT_DATE)
	WHERE @dt_from <= L.INSERT_DATE AND L.INSERT_DATE < @dt_to
		--and L.КодСобытия not IN ('1.12', '3.1') --?
		--временно
		--and L.ТипОбъекта in ('Заявка', 'ДоговорЗайма')

	create index ix_Guid
	on #t_CRE_IMPORT_LOG_302(GuidCRE_IMPORT_LOG_302)

	-- 2 по ДатаСобытия_dt
	INSERT #t_CRE_IMPORT_LOG_302
	SELECT 
		INSERT_DAY = cast(L.INSERT_DATE AS date),
		L.* 
	FROM dwh2.dm.CRE_IMPORT_LOG_302 AS L with(index = ix_ДатаСобытия_dt)
	WHERE @dt_from <= L.ДатаСобытия_dt AND L.ДатаСобытия_dt < @dt_to
		-- не добавлены на пред. шаге
		and not exists(
				select top(1) 1
				from #t_CRE_IMPORT_LOG_302 as x
				where x.GuidCRE_IMPORT_LOG_302 = L.GuidCRE_IMPORT_LOG_302
			)
		--временно
		--and L.ТипОбъекта in ('Заявка', 'ДоговорЗайма')


	-- EXPORT
	DROP TABLE IF EXISTS #t_CRE_EXPORT_LOG_302

	SELECT TOP 0 
		INSERT_DAY = cast(NULL AS date),
		L.* 
	INTO #t_CRE_EXPORT_LOG_302
	FROM dwh2.dm.CRE_EXPORT_LOG_302 AS L

	-- 1 по INSERT_DATE
	INSERT #t_CRE_EXPORT_LOG_302
	SELECT 
		INSERT_DAY = cast(L.INSERT_DATE AS date),
		L.* 
	--SELECT top 10 *
	FROM dwh2.dm.CRE_EXPORT_LOG_302 AS L with(index = ix_INSERT_DATE)
	WHERE @dt_from <= L.INSERT_DATE AND L.INSERT_DATE < @dt_to
		--and L.КодСобытия not IN ('1.12', '3.1') --?
		-- ?
		--and @dt_from <= L.REJECT_DATE AND L.REJECT_DATE < @dt_to 
		--временно
		--and L.ТипОбъекта in ('Заявка', 'ДоговорЗайма')

	create index ix_Guid
	on #t_CRE_EXPORT_LOG_302(GuidCRE_IMPORT_LOG_302)

	-- 2 по ДатаСобытия_dt
	INSERT #t_CRE_EXPORT_LOG_302
	SELECT 
		INSERT_DAY = cast(L.INSERT_DATE AS date),
		L.* 
	FROM dwh2.dm.CRE_EXPORT_LOG_302 AS L with(index = ix_ДатаСобытия_dt)
	WHERE @dt_from <= L.ДатаСобытия_dt AND L.ДатаСобытия_dt < @dt_to
		-- не добавлены на пред. шаге
		and not exists(
				select top(1) 1
				from #t_CRE_EXPORT_LOG_302 as x
				where x.GuidCRE_EXPORT_LOG_302 = L.GuidCRE_EXPORT_LOG_302
			)
		--временно
		--and L.ТипОбъекта in ('Заявка', 'ДоговорЗайма')
	------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #t_Detail

	-- EXPORT
	SELECT
		GuidDetail = newid(),

		--ИсторияСобытий
		--L.GuidБКИ_НФ_ИсторияСобытий,
		--L.ДатаСобытия,
		--L.ДатаСобытия_dt,
		--ДатаСобытия_dt_2_workday = cast(null as date),
		--L.isActiveСобытия,
		--L.ДатаЗаписиСобытия,

		[ENTITY_NAME] = cast(isnull(L.ТипОбъекта, '_Не определено') AS nvarchar(30)),

		--L.BKI_NAME,
		-- если есть ошибка CRE, переопределить BKI_NAME = 'CRE'
		BKI_NAME = 
			CASE
				WHEN L.EXPORT_EVENT_SUCCESS = 0 or L.IMPORT_SUCCESS = 0 THEN 'CRE'
				ELSE L.BKI_NAME
			END,

		L.INSERT_DAY,
		L.GuidCRE_EXPORT_LOG_302,
		L.ID,
		L.INSERT_DATE,
		L.EVENT_ID,
		EVENT_NAME = cast(isnull(L.НаименованиеСобытия, 'Не определено') AS nvarchar(255)),
		L.EVENT_DATE,
		L.OPERATION_TYPE,
		L.SOURCE_CODE,
		L.REF_CODE,
		L.UUID,
		L.APPLICATION_NUMBER,
		ENTITY_NUMBER = isnull(L.НомерОбъекта, coalesce(L.APPLICATION_NUMBER, L.ACCOUNT, L.UUID)),
		L.APPLICANT_CODE,
		L.ORDER_NUM,
		L.EXPORT_FILENAME,
		L.IMPORT_FILENAME,
		L.EXPORT_EVENT_SUCCESS,
		L.ERROR_CODE,
		L.ERROR_DESC,
		L.CHANGE_CODE,
		L.SPECIAL_CHANGE_CODE,
		L.ACCOUNT,
		L.JOURNAL_ID,
		L.TRADE_ID,
		L.TRADEDETAIL_ID,
		L.IMPORT_ID,
		L.EXPORT_META_ID,
		-- любая ошибка: или в CRE или из REJECT
		isError = 
			CASE
				--WHEN isnull(L.EXPORT_EVENT_SUCCESS,1) <> 1 THEN 1
				WHEN L.EXPORT_EVENT_SUCCESS = 0 THEN 1
				--WHEN isnull(L.IMPORT_SUCCESS,1) <> 1 THEN 1
				WHEN L.IMPORT_SUCCESS = 0 THEN 1
				WHEN L.REJECT_ERROR_DESC IS NOT NULL THEN 1
				ELSE 0
			END,
		-- ошибка CRE
		isErrorCRE = 
			CASE
				WHEN L.EXPORT_EVENT_SUCCESS = 0 THEN 1
				WHEN L.IMPORT_SUCCESS = 0 THEN 1
				ELSE 0
			END,
		-- ошибка из REJECT
		isErrorREJECT = 
			CASE
				WHEN L.REJECT_ERROR_DESC IS NOT NULL THEN 1
				ELSE 0
			END,
		L.GuidCRE_IMPORT_LOG_302,
		L.IMPORT_LOG_ID,
		L.IMPORT_SUCCESS,
		L.IMPORT_ERROR_CODE,
		L.IMPORT_ERROR_DESC,
		L.REJECT_ERROR_DESC
	INTO #t_Detail
	FROM #t_CRE_EXPORT_LOG_302 AS L
	WHERE 1=1
		and @dt_from <= L.INSERT_DATE AND L.INSERT_DATE < @dt_to
		and L.EVENT_ID is not null
	
		AND (L.BKI_NAME IN (SELECT bki_name FROM @t_bki_name)
			OR @bki_name is null)
		AND (isnull(L.ТипОбъекта, '_Не определено') IN (SELECT [entity_name] FROM @t_entity_name)
			OR @entity_name is null)


	alter table #t_Detail
	alter column GuidCRE_EXPORT_LOG_302 uniqueidentifier null


	-- IMPORT 
	insert #t_Detail
	SELECT
		GuidDetail = newid(),

		--ИсторияСобытий
		--L.GuidБКИ_НФ_ИсторияСобытий,
		--L.ДатаСобытия,
		--L.ДатаСобытия_dt,
		--ДатаСобытия_dt_2_workday = cast(null as date),
		--L.isActiveСобытия,
		--L.ДатаЗаписиСобытия,

		[ENTITY_NAME] = cast(isnull(L.ТипОбъекта, '_Не определено') AS nvarchar(30)),
		BKI_NAME = 'CRE',
		L.INSERT_DAY,
		GuidCRE_EXPORT_LOG_302 = null,
		ID = null,
		L.INSERT_DATE,
		L.EVENT_ID,
		EVENT_NAME = cast(isnull(L.НаименованиеСобытия, 'Не определено') AS nvarchar(255)),
		L.EVENT_DATE,
		L.OPERATION_TYPE,
		L.SOURCE_CODE,
		L.REF_CODE,
		L.UUID,
		L.APPLICATION_NUMBER,
		ENTITY_NUMBER = isnull(L.НомерОбъекта, coalesce(L.APPLICATION_NUMBER, L.ACCOUNT, L.UUID)),
		L.APPLICANT_CODE,
		ORDER_NUM = null,
		EXPORT_FILENAME = null,
		L.IMPORT_FILENAME,
		EXPORT_EVENT_SUCCESS = null,
		ERROR_CODE = null,
		ERROR_DESC = null,
		CHANGE_CODE = null,
		SPECIAL_CHANGE_CODE = null,
		L.ACCOUNT,
		L.JOURNAL_ID,
		TRADE_ID = null,
		TRADEDETAIL_ID = null,
		IMPORT_ID = null,
		EXPORT_META_ID = null,
		-- любая ошибка
		isError = 
			CASE
				WHEN L.IMPORT_SUCCESS = 0 THEN 1
				ELSE 0
			END,
		-- ошибка CRE
		isErrorCRE = 
			CASE
				WHEN L.IMPORT_SUCCESS = 0 THEN 1
				ELSE 0
			END,
		-- ошибка из REJECT
		isErrorREJECT = 0,
		L.GuidCRE_IMPORT_LOG_302,
		IMPORT_LOG_ID = L.ID,
		L.IMPORT_SUCCESS,
		IMPORT_ERROR_CODE = L.ERROR_CODE,
		IMPORT_ERROR_DESC = L.ERROR_DESC,
		REJECT_ERROR_DESC = null
	FROM #t_CRE_IMPORT_LOG_302 AS L
		left join #t_Detail as D
			on D.GuidCRE_IMPORT_LOG_302 = L.GuidCRE_IMPORT_LOG_302
	WHERE 1=1
		and @dt_from <= L.INSERT_DATE AND L.INSERT_DATE < @dt_to
		and L.EVENT_ID is not null

		and D.GuidCRE_IMPORT_LOG_302 is null -- запись не добавлена на пред. шаге
		AND ('CRE' IN (SELECT bki_name FROM @t_bki_name)
			OR @bki_name is null)
		AND (isnull(L.ТипОбъекта, '_Не определено') IN (SELECT [entity_name] FROM @t_entity_name)
			OR @entity_name is null)


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Detail
		SELECT * INTO ##t_Detail FROM #t_Detail
	END

	IF @Page = 'Detail' BEGIN
		SELECT top 20000 D.*
		FROM #t_Detail AS D
		ORDER BY D.BKI_NAME, D.INSERT_DAY

		RETURN 0
	END
	--// 'Detail'


	------------------------------------------------------------------------------
	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ErrorDetail
		--DROP TABLE IF EXISTS Reports.tmp.TMP_AND_ErrorDetail

		SELECT top 20000 D.*
		INTO ##t_ErrorDetail
		--INTO Reports.tmp.TMP_AND_ErrorDetail
		FROM #t_Detail AS D
		WHERE D.isError = 1
			and isnull(D.REJECT_ERROR_DESC, '***') not like '%warningNum%'
	END

	IF @Page = 'ErrorDetail' BEGIN
		SELECT top 20000 D.*
		FROM #t_Detail AS D
		WHERE D.isError = 1
			and isnull(D.REJECT_ERROR_DESC, '***') not like '%warningNum%'
		ORDER BY D.BKI_NAME, D.INSERT_DAY

		RETURN 0
	END
	--// 'ErrorDetail'

	------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #t_Statistics

	SELECT 
		B.[ENTITY_NAME], 
		B.BKI_NAME, 
		B.INSERT_DAY,
		B.count_total,
		count_accept = B.count_total - B.count_error,
		B.count_error,
		percent_error = 1.0 * B.count_error / B.count_total,
		count_error_date = 0 --Кол-во с ошибками на дату
	INTO #t_Statistics
	FROM (
		SELECT 
			A.[ENTITY_NAME], A.BKI_NAME, A.INSERT_DAY,
			count_total = count(*),
			count_error = count(CASE WHEN A.isError = 1 THEN 1 ELSE NULL END)
			--count_accept = count(*) - count(CASE WHEN A.isError = 1 THEN 1 ELSE NULL END)
		FROM (
			SELECT 
				D.[ENTITY_NAME], D.BKI_NAME, D.INSERT_DAY, D.ENTITY_NUMBER, --D.UUID, -- Номер Договора/Заявки
				isError = max(D.isError)
			FROM #t_Detail AS D
			GROUP BY D.[ENTITY_NAME], D.BKI_NAME, D.INSERT_DAY, D.ENTITY_NUMBER --D.UUID

			--добавить весь #t_Detail, кроме 'CRE', для того, чтобы в 'CRE' были все события
			union
			SELECT 
				D.[ENTITY_NAME], BKI_NAME = 'CRE', D.INSERT_DAY, D.ENTITY_NUMBER, --D.UUID, -- Номер Договора/Заявки
				--isError = max(D.isError)
				isError = 0 -- ошибки уже посчитаны
			FROM #t_Detail AS D
			WHERE D.BKI_NAME <> 'CRE'
				AND ('CRE' IN (SELECT bki_name FROM @t_bki_name)
					OR @bki_name is null)
			GROUP BY D.[ENTITY_NAME], D.BKI_NAME, D.INSERT_DAY, D.ENTITY_NUMBER --D.UUID

			) AS A
		GROUP BY A.[ENTITY_NAME], A.BKI_NAME, A.INSERT_DAY
		) AS B

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Statistics
		SELECT * INTO ##t_Statistics FROM #t_Statistics
	END

	IF @Page = 'Statistics' BEGIN
		SELECT 
			S.[ENTITY_NAME],
			S.BKI_NAME,
			S.INSERT_DAY,
			S.count_total,
			S.count_accept,
			S.count_error,
			S.percent_error,
			S.count_error_date
		FROM #t_Statistics AS S

		RETURN 0
	END
	--// 'Statistics'


	------------------------------------------------------------------------------
	DROP TABLE IF EXISTS #t_Statistics2

	SELECT 
		B.[ENTITY_NAME], 
		B.BKI_NAME, 
		B.INSERT_DAY,
		B.EVENT_ID,

		-- с группировкой по UUID
		B.count_total,
		count_accept = B.count_total - B.count_error,
		B.count_error,
		percent_error = 1.0 * B.count_error / B.count_total,

		-- без группировки по UUID
		event_count_total = C.count_total,
		event_count_accept = C.count_total - C.count_error,
		event_count_error = C.count_error,
		event_percent_error = 1.0 * C.count_error / C.count_total,

		--
		count_error_date = 0 --Кол-во с ошибками на дату
	INTO #t_Statistics2
	FROM (
		--группировать по UUID
		SELECT 
			A.[ENTITY_NAME], A.BKI_NAME, A.INSERT_DAY, A.EVENT_ID,
			count_total = count(*),
			count_error = count(CASE WHEN A.isError = 1 THEN 1 ELSE NULL END)
			--count_accept = count(*) - count(CASE WHEN A.isError = 1 THEN 1 ELSE NULL END)
		FROM (
			SELECT 
				D.[ENTITY_NAME], D.BKI_NAME, D.INSERT_DAY, D.EVENT_ID, D.ENTITY_NUMBER, --, D.UUID, -- Номер Договора/Заявки
				isError = max(D.isError)
			FROM #t_Detail AS D
			GROUP BY D.[ENTITY_NAME], D.BKI_NAME, D.INSERT_DAY, D.EVENT_ID, D.ENTITY_NUMBER --, D.UUID

			--добавить весь #t_Detail, кроме 'CRE'
			union
			SELECT 
				D.[ENTITY_NAME], BKI_NAME = 'CRE', D.INSERT_DAY, D.EVENT_ID, D.ENTITY_NUMBER, --, D.UUID, -- Номер Договора/Заявки
				--isError = max(D.isError)
				isError = 0 -- ошибки уже посчитаны
			FROM #t_Detail AS D
			where D.BKI_NAME <> 'CRE'
				AND ('CRE' IN (SELECT bki_name FROM @t_bki_name)
					OR @bki_name is null)
			GROUP BY D.[ENTITY_NAME], D.BKI_NAME, D.INSERT_DAY, D.EVENT_ID, D.ENTITY_NUMBER --, D.UUID

			--Итого
			union
			SELECT 
				D.[ENTITY_NAME], D.BKI_NAME, D.INSERT_DAY, EVENT_ID = 'Итого', D.ENTITY_NUMBER, --, D.UUID, -- Номер Договора/Заявки
				isError = max(D.isError)
			FROM #t_Detail AS D
			GROUP BY D.[ENTITY_NAME], D.BKI_NAME, D.INSERT_DAY, D.ENTITY_NUMBER --, D.UUID

			--добавить весь #t_Detail, кроме 'CRE'
			union
			SELECT 
				D.[ENTITY_NAME], BKI_NAME = 'CRE', D.INSERT_DAY, EVENT_ID = 'Итого', D.ENTITY_NUMBER, --, D.UUID, -- Номер Договора/Заявки
				--isError = max(D.isError)
				isError = 0 -- ошибки уже посчитаны
			FROM #t_Detail AS D
			where D.BKI_NAME <> 'CRE'
				AND ('CRE' IN (SELECT bki_name FROM @t_bki_name)
					OR @bki_name is null)
			GROUP BY D.[ENTITY_NAME], D.BKI_NAME, D.INSERT_DAY, D.ENTITY_NUMBER --, D.UUID
			--//Итого


			) AS A
		GROUP BY A.[ENTITY_NAME], A.BKI_NAME, A.INSERT_DAY, A.EVENT_ID
		) AS B
		INNER JOIN 

		--не группировать по UUID
		(
		SELECT 
			D.[ENTITY_NAME], D.BKI_NAME, D.INSERT_DAY, D.EVENT_ID,
			count_total = count(*),
			count_error = count(CASE WHEN D.isError = 1 THEN 1 ELSE NULL END)
			--count_accept = count(*) - count(CASE WHEN A.isError = 1 THEN 1 ELSE NULL END)
		FROM 
			(
			select A.GuidDetail, A.[ENTITY_NAME], A.BKI_NAME, A.INSERT_DAY, A.EVENT_ID, A.isError
			from #t_Detail as A

			--добавить весь #t_Detail, кроме 'CRE'
			union
			select A.GuidDetail, A.[ENTITY_NAME], BKI_NAME = 'CRE', A.INSERT_DAY, A.EVENT_ID, 
				--A.isError
				isError = 0 -- ошибки уже посчитаны
			from #t_Detail as A
			where A.BKI_NAME <> 'CRE'
				AND ('CRE' IN (SELECT bki_name FROM @t_bki_name)
					OR @bki_name is null)

			--Итого
			union
			select A.GuidDetail, A.[ENTITY_NAME], A.BKI_NAME, A.INSERT_DAY, EVENT_ID = 'Итого', A.isError
			from #t_Detail as A

			--добавить весь #t_Detail, кроме 'CRE'
			union
			select A.GuidDetail, A.[ENTITY_NAME], BKI_NAME = 'CRE', A.INSERT_DAY, EVENT_ID = 'Итого', 
				--A.isError
				isError = 0 -- ошибки уже посчитаны
			from #t_Detail as A
			where A.BKI_NAME <> 'CRE'
				AND ('CRE' IN (SELECT bki_name FROM @t_bki_name)
					OR @bki_name is null)
			) AS D
		GROUP BY D.[ENTITY_NAME], D.BKI_NAME, D.INSERT_DAY, D.EVENT_ID

		) AS C
		ON C.[ENTITY_NAME] = B.[ENTITY_NAME]
		AND C.BKI_NAME = B.BKI_NAME
		AND C.INSERT_DAY = B.INSERT_DAY
		AND C.EVENT_ID = B.EVENT_ID


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Statistics2
		SELECT * INTO ##t_Statistics2 FROM #t_Statistics2
	END

	IF @Page = 'Statistics2' BEGIN
		SELECT 
			S.[ENTITY_NAME],
			S.BKI_NAME,
			S.INSERT_DAY,
			S.EVENT_ID,
			-- с группировкой по UUID
			S.count_total,
			S.count_accept,
			S.count_error,
			S.percent_error,
			-- без группировки по UUID
			S.event_count_total,
			S.event_count_accept,
			S.event_count_error,
			S.event_percent_error,
			--
			S.count_error_date
		FROM #t_Statistics2 AS S

		RETURN 0
	END
	--// 'Statistics2'





	--отчет по соблюдению сроков отправки
	IF @Page in ('Deadline','StatSending') BEGIN

		DROP TABLE IF EXISTS #t_Deadline

		-- EXPORT
		SELECT
			GuidDetail = newid(),

			--ИсторияСобытий
			L.GuidБКИ_НФ_ИсторияСобытий,
			L.ДатаСобытия,
			L.ДатаСобытия_dt,
			ДатаСобытия_dt_2_workday = cast(null as date),
			L.isActiveСобытия,
			L.ДатаЗаписиСобытия,
			ДатаЗаписиСобытия_dt = cast(L.ДатаЗаписиСобытия as date),
			ДатаЗаписиСобытия_dt_2_workday = cast(null as date),

			[ENTITY_NAME] = cast(isnull(L.ТипОбъекта, '_Не определено') AS nvarchar(30)),

			--L.BKI_NAME,
			-- если есть ошибка CRE, переопределить BKI_NAME = 'CRE'
			BKI_NAME = 
				CASE
					WHEN L.EXPORT_EVENT_SUCCESS = 0 or L.IMPORT_SUCCESS = 0 THEN 'CRE'
					ELSE L.BKI_NAME
				END,

			L.INSERT_DAY,
			L.GuidCRE_EXPORT_LOG_302,
			L.ID,
			L.INSERT_DATE,
			EVENT_ID = L.КодСобытия,
			EVENT_NAME = cast(isnull(L.НаименованиеСобытия, 'Не определено') AS nvarchar(255)),
			L.EVENT_DATE,
			L.OPERATION_TYPE,
			L.SOURCE_CODE,
			L.REF_CODE,
			L.UUID,
			L.APPLICATION_NUMBER,
			ENTITY_NUMBER = isnull(L.НомерОбъекта, coalesce(L.APPLICATION_NUMBER, L.ACCOUNT, L.UUID)),
			L.APPLICANT_CODE,
			L.ORDER_NUM,
			L.EXPORT_FILENAME,
			L.IMPORT_FILENAME,
			L.EXPORT_EVENT_SUCCESS,
			L.ERROR_CODE,
			L.ERROR_DESC,
			L.CHANGE_CODE,
			L.SPECIAL_CHANGE_CODE,
			L.ACCOUNT,
			L.JOURNAL_ID,
			L.TRADE_ID,
			L.TRADEDETAIL_ID,
			L.IMPORT_ID,
			L.EXPORT_META_ID,
			-- любая ошибка: или в CRE или из REJECT
			isError = 
				CASE
					--WHEN isnull(L.EXPORT_EVENT_SUCCESS,1) <> 1 THEN 1
					WHEN L.EXPORT_EVENT_SUCCESS = 0 THEN 1
					--WHEN isnull(L.IMPORT_SUCCESS,1) <> 1 THEN 1
					WHEN L.IMPORT_SUCCESS = 0 THEN 1
					WHEN L.REJECT_ERROR_DESC IS NOT NULL THEN 1
					ELSE 0
				END,
			-- ошибка CRE
			isErrorCRE = 
				CASE
					WHEN L.EXPORT_EVENT_SUCCESS = 0 THEN 1
					WHEN L.IMPORT_SUCCESS = 0 THEN 1
					ELSE 0
				END,
			-- ошибка из REJECT
			isErrorREJECT = 
				CASE
					WHEN L.REJECT_ERROR_DESC IS NOT NULL THEN 1
					ELSE 0
				END,
			L.GuidCRE_IMPORT_LOG_302,
			L.IMPORT_LOG_ID,
			IMPORT_INSERT_DATE = I.INSERT_DATE,
			IMPORT_INSERT_DAY = I.INSERT_DAY,
			L.IMPORT_SUCCESS,
			L.IMPORT_ERROR_CODE,
			L.IMPORT_ERROR_DESC,
			L.REJECT_ERROR_DESC,
			--TICKET
			L.GuidCRE_TICKET_LOG_302,
			--TICKET_DATE получения тикета из таблицы TICKET_LOG_302 
			--для № договора/заявки, по которому отсутствует запись в таблице REJECT_LOG_302
			--L.TICKET_DATE
			TICKET_DATE = 
				case 
					when L.REJECT_ERROR_DESC is null then L.TICKET_DATE 
					else cast(null as datetime)
				end
		INTO #t_Deadline
		FROM #t_CRE_EXPORT_LOG_302 AS L
			left join #t_CRE_IMPORT_LOG_302 AS I
				on I.GuidCRE_IMPORT_LOG_302 = L.GuidCRE_IMPORT_LOG_302
		WHERE 1=1
			and @dt_from <= L.ДатаСобытия_dt AND L.ДатаСобытия_dt < @dt_to
			AND (L.BKI_NAME IN (SELECT bki_name FROM @t_bki_name)
				OR @bki_name is null)
			AND (isnull(L.ТипОбъекта, '_Не определено') IN (SELECT [entity_name] FROM @t_entity_name)
				OR @entity_name is null)
			--
			and L.GuidБКИ_НФ_ИсторияСобытий is not null
			--
			--and L.КодСобытия in (
			--	'1.1', '1.2', '1.3', '1.4', '2.1', 
			--	'2.2', '2.2.1', '2.3', '2.4', '2.5', 
			--	'2.11',
			--	'1.7', '1.9', '1.10', '1.12', '2.6',
			--	'3.1'
			--	)
			--
			and isnull(L.REJECT_ERROR_DESC, '***') not like '%warningNum%'


		alter table #t_Deadline
		alter column GuidCRE_EXPORT_LOG_302 uniqueidentifier null

		-- IMPORT 
		insert #t_Deadline
		SELECT
			GuidDetail = newid(),
			--ИсторияСобытий
			L.GuidБКИ_НФ_ИсторияСобытий,
			L.ДатаСобытия,
			L.ДатаСобытия_dt,
			ДатаСобытия_dt_2_workday = cast(null as date),
			L.isActiveСобытия,
			L.ДатаЗаписиСобытия,
			ДатаЗаписиСобытия_dt = cast(L.ДатаЗаписиСобытия as date),
			ДатаЗаписиСобытия_dt_2_workday = cast(null as date),
			[ENTITY_NAME] = cast(isnull(L.ТипОбъекта, '_Не определено') AS nvarchar(30)),
			BKI_NAME = 'CRE',
			INSERT_DAY = null,
			GuidCRE_EXPORT_LOG_302 = null,
			ID = null,
			INSERT_DATE = null,
			EVENT_ID = L.КодСобытия,
			EVENT_NAME = cast(isnull(L.НаименованиеСобытия, 'Не определено') AS nvarchar(255)),
			L.EVENT_DATE,
			L.OPERATION_TYPE,
			L.SOURCE_CODE,
			L.REF_CODE,
			L.UUID,
			L.APPLICATION_NUMBER,
			ENTITY_NUMBER = isnull(L.НомерОбъекта, coalesce(L.APPLICATION_NUMBER, L.ACCOUNT, L.UUID)),
			L.APPLICANT_CODE,
			ORDER_NUM = null,
			EXPORT_FILENAME = null,
			L.IMPORT_FILENAME,
			EXPORT_EVENT_SUCCESS = null,
			ERROR_CODE = null,
			ERROR_DESC = null,
			CHANGE_CODE = null,
			SPECIAL_CHANGE_CODE = null,
			L.ACCOUNT,
			L.JOURNAL_ID,
			TRADE_ID = null,
			TRADEDETAIL_ID = null,
			IMPORT_ID = null,
			EXPORT_META_ID = null,
			-- любая ошибка
			isError = 
				CASE
					WHEN L.IMPORT_SUCCESS = 0 THEN 1
					ELSE 0
				END,
			-- ошибка CRE
			isErrorCRE = 
				CASE
					WHEN L.IMPORT_SUCCESS = 0 THEN 1
					ELSE 0
				END,
			-- ошибка из REJECT
			isErrorREJECT = 0,
			L.GuidCRE_IMPORT_LOG_302,
			IMPORT_LOG_ID = L.ID,
			IMPORT_INSERT_DATE = L.INSERT_DATE,
			IMPORT_INSERT_DAY = L.INSERT_DAY,
			L.IMPORT_SUCCESS,
			IMPORT_ERROR_CODE = L.ERROR_CODE,
			IMPORT_ERROR_DESC = L.ERROR_DESC,
			REJECT_ERROR_DESC = null,
			--TICKET
			GuidCRE_TICKET_LOG_302 = null,
			TICKET_DATE = null
		FROM #t_CRE_IMPORT_LOG_302 AS L
			left join #t_Deadline as D
				on D.GuidCRE_IMPORT_LOG_302 = L.GuidCRE_IMPORT_LOG_302
			left join #t_Deadline as D2
				on D2.GuidБКИ_НФ_ИсторияСобытий = L.GuidБКИ_НФ_ИсторияСобытий
		WHERE 1=1
			and @dt_from <= L.ДатаСобытия_dt AND L.ДатаСобытия_dt < @dt_to

			and D.GuidCRE_IMPORT_LOG_302 is null -- запись не добавлена на пред. шаге
			and D2.GuidБКИ_НФ_ИсторияСобытий is null -- событие не добавлено на пред. шаге

			--AND (L.BKI_NAME IN (SELECT bki_name FROM @t_bki_name)
			--	OR @bki_name is null)
			AND (isnull(L.ТипОбъекта, '_Не определено') IN (SELECT [entity_name] FROM @t_entity_name)
				OR @entity_name is null)
			--
			and L.GuidБКИ_НФ_ИсторияСобытий is not null
			--
			--and L.КодСобытия in (
			--	'1.1', '1.2', '1.3', '1.4', '2.1', 
			--	'2.2', '2.2.1', '2.3', '2.4', '2.5', 
			--	'2.11',
			--	'1.7', '1.9', '1.10', '1.12', '2.6',
			--	'3.1'
			--	)



		--БКИ_НФ_ИсторияСобытий
		-- добавить события без отправки

		insert #t_Deadline
		SELECT
			GuidDetail = newid(),
			--ИсторияСобытий
			L.GuidБКИ_НФ_ИсторияСобытий,
			ДатаСобытия = L.Дата,
			ДатаСобытия_dt = L.Дата_dt,
			ДатаСобытия_dt_2_workday = cast(null as date),
			isActiveСобытия = L.isActive,
			ДатаЗаписиСобытия = L.ДатаЗаписи,
			ДатаЗаписиСобытия_dt = cast(L.ДатаЗаписи as date),
			ДатаЗаписиСобытия_dt_2_workday = cast(null as date),
			[ENTITY_NAME] = cast(isnull(isnull(X.ТипОбъекта, L.ТипОбъекта), '_Не определено') AS nvarchar(30)),
			BKI_NAME = 'CMR', --'CRE',
			INSERT_DAY = null,
			GuidCRE_EXPORT_LOG_302 = null,
			ID = null,
			INSERT_DATE = null,
			EVENT_ID = L.КодСобытия,
			EVENT_NAME = cast(isnull(L.НаименованиеСобытия, 'Не определено') AS nvarchar(255)),
			EVENT_DATE = L.Дата,
			OPERATION_TYPE = null,
			SOURCE_CODE = null,
			REF_CODE = null,
			UUID = null,
			APPLICATION_NUMBER = null,
			--ENTITY_NUMBER = L.НомерОбъекта,
			ENTITY_NUMBER = 
				case 
					when X.ТипОбъекта in ('Субъект') then isnull(L.НаименованиеКлиент, L.НомерОбъекта)
					else L.НомерОбъекта
				end,
			APPLICANT_CODE = null,
			ORDER_NUM = null,
			EXPORT_FILENAME = null,
			IMPORT_FILENAME = null,
			EXPORT_EVENT_SUCCESS = null,
			ERROR_CODE = null,
			ERROR_DESC = null,
			CHANGE_CODE = null,
			SPECIAL_CHANGE_CODE = null,
			ACCOUNT = null,
			JOURNAL_ID = null,
			TRADE_ID = null,
			TRADEDETAIL_ID = null,
			IMPORT_ID = null,
			EXPORT_META_ID = null,
			-- любая ошибка
			isError = 0,
			-- ошибка CRE
			isErrorCRE = 0,
			-- ошибка из REJECT
			isErrorREJECT = 0,
			GuidCRE_IMPORT_LOG_302 = null,
			IMPORT_LOG_ID = null,
			IMPORT_INSERT_DATE = null,
			IMPORT_INSERT_DAY = null,
			IMPORT_SUCCESS = null,
			IMPORT_ERROR_CODE = null,
			IMPORT_ERROR_DESC = null,
			REJECT_ERROR_DESC = null,
			--TICKET
			GuidCRE_TICKET_LOG_302 = null,
			TICKET_DATE = null
		--FROM #t_CRE_IMPORT_LOG_302 AS L
		--select top 100 *
		FROM dwh2.dm.БКИ_НФ_ИсторияСобытий as L with(index = ix_Дата_dt)
			left join dwh2.link.v_БКИ_НФ_События_ТипОбъекта as X
				on X.КодСобытия = L.КодСобытия
			left join #t_Deadline as D
				on D.GuidБКИ_НФ_ИсторияСобытий = L.GuidБКИ_НФ_ИсторияСобытий
		WHERE 1=1
			and @dt_from <= L.Дата_dt AND L.Дата_dt < @dt_to
			and D.GuidБКИ_НФ_ИсторияСобытий is null -- запись не добавлена на пред. шаге
			--AND (L.BKI_NAME IN (SELECT bki_name FROM @t_bki_name)
			--	OR @bki_name is null)
			AND (isnull(isnull(X.ТипОбъекта, L.ТипОбъекта), '_Не определено')
					IN (SELECT [entity_name] FROM @t_entity_name)
				OR @entity_name is null
			)
			--
			--and L.КодСобытия in (
			--	'1.1', '1.2', '1.3', '1.4', '2.1', 
			--	'2.2', '2.2.1', '2.3', '2.4', '2.5', 
			--	'2.11',
			--	'1.7', '1.9', '1.10', '1.12', '2.6',
			--	'3.1'
			--	)


		--Дата события + 2 р.д.
		update T set ДатаСобытия_dt_2_workday = A.DT
		from #t_Deadline as T
			inner join (
			select
				d.GuidDetail,
				d.ДатаСобытия_dt,
				c.DT,
				rn = row_number() over(
					partition by d.GuidDetail
					order by c.DT
				)
			from #t_Deadline as d
				inner join dwh2.Dictionary.calendar as c
					on c.DT > d.ДатаСобытия_dt
					and isnull(c.isRussiaDayOff, 0) = 0
					and c.DT < dateadd(day, 12, d.ДатаСобытия_dt)
			where 1=1
				and d.ДатаСобытия_dt is not null
			) as A
			on A.GuidDetail = T.GuidDetail
			and A.rn = 2


		--ДатаЗаписиСобытия + 2 р.д.
		--ДатаЗаписиСобытия_dt_2_workday = cast(null as date),
		update T set ДатаЗаписиСобытия_dt_2_workday = A.DT
		from #t_Deadline as T
			inner join (
			select
				d.GuidDetail,
				d.ДатаЗаписиСобытия_dt,
				c.DT,
				rn = row_number() over(
					partition by d.GuidDetail
					order by c.DT
				)
			from #t_Deadline as d
				inner join dwh2.Dictionary.calendar as c
					on c.DT > d.ДатаЗаписиСобытия_dt
					and isnull(c.isRussiaDayOff, 0) = 0
					and c.DT < dateadd(day, 12, d.ДатаЗаписиСобытия_dt)
			where 1=1
				and d.ДатаЗаписиСобытия_dt is not null
			) as A
			on A.GuidDetail = T.GuidDetail
			and A.rn = 2

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_Deadline
			SELECT * INTO ##t_Deadline FROM #t_Deadline
		END


		drop table if exists #t_DeadlineResult
		SELECT 
			d.*,
			-- Сколько дней прошло с даты формирования до даты принятия события?
			day_diff = datediff(day, d.ДатаЗаписиСобытия_dt, cast(d.TICKET_DATE as date)),

			-- Событие принято в срок
			--isDeadline = 
			--	cast(
			--		case
			--			--when isnull(d.INSERT_DAY, getdate()) > d.ДатаСобытия_dt_2_workday then 'Нет'
			--			when d.INSERT_DAY <= d.ДатаСобытия_dt_2_workday then 'Да'
			--			when d.INSERT_DAY > d.ДатаСобытия_dt_2_workday then 'Нет'
			--			else cast(null as varchar(3))
			--		end 
			--	as varchar(10))
			/*
			Расчетное на стороне ДВХ
			Да - если Текущая дата - Дата события <= 2 р.д. для событий 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.2.1, 2.3, 2.4, 2.5, 2.11
			Да - если Текущая дата - Дата формирования события <= 2 р.д. для событий 1.7, 1.9, 1.10, 1.12, 2.6, 3.1
			При несоблюдении условий поле заполняется значением "Нет"

			2025-10-19
			Событие принято в срок
			Да - если Текущая дата - Дата события <= 2 р.д. для событий 
			1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.2.1, 2.3, 2.4, 2.5, 2.11, 3.1, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4 
			(т.к события корректировок формируются в КРЕ и у них есть только один атрибут - дата события).

			Да - если Текущая дата - Дата формирования события <= 2 р.д. для событий 
			1.7, 1.9, 1.10, 1.12, 2.6, 3.1
			При несоблюдении условий поле заполняется значением "Нет"
			*/
			isDeadline = 
				cast(
				case 
					when d.EVENT_ID in (
						'1.1', '1.2', '1.3', '1.4', 
						'2.1', '2.2', '2.2.1', '2.3', '2.4', '2.5', '2.11',
						'3.1', '3.3', '3.4', '3.5',
						'4.1', '4.2', '4.3', '4.4'
						)
					then
						case
							-- ДатаСобытия_dt_2_workday еще не наступило
							when cast(getdate() as date) < d.ДатаСобытия_dt_2_workday
								then 'Да'
							when cast(isnull(d.TICKET_DATE, d.INSERT_DAY) as date) <= d.ДатаСобытия_dt_2_workday
								then 'Да'
							when cast(isnull(d.TICKET_DATE, d.INSERT_DAY) as date) > d.ДатаСобытия_dt_2_workday
								then 'Нет'
							else null
						end

					when d.EVENT_ID in ('1.7', '1.9', '2.6')
					then
						case
							-- ДатаЗаписиСобытия_dt_2_workday еще не наступило
							when cast(getdate() as date) < d.ДатаЗаписиСобытия_dt_2_workday
								then 'Да'
							when cast(isnull(d.TICKET_DATE, d.INSERT_DAY) as date) <= d.ДатаЗаписиСобытия_dt_2_workday
								then 'Да'
							when cast(isnull(d.TICKET_DATE, d.INSERT_DAY) as date) > d.ДатаЗаписиСобытия_dt_2_workday
								then 'Нет'
							else null
						end

					else null
				end
				as varchar(10))
		into #t_DeadlineResult
		FROM #t_Deadline as d
		where 1=1
			and d.EVENT_ID in (
				'1.1', '1.2', '1.3', '1.4', 
				'2.1', '2.2', '2.2.1', '2.3', '2.4', '2.5', '2.11',
				'3.1', '3.3', '3.4', '3.5',
				'4.1', '4.2', '4.3', '4.4',

				'1.7', '1.9', '2.6'
				)


		create index ix1 
		on #t_DeadlineResult(ДатаСобытия_dt, EVENT_ID, ENTITY_NUMBER, BKI_NAME)
		include(ДатаЗаписиСобытия)



		--события без отправки должны попадать в отчет
		--поэтому set BKI_NAME = 'НБКИ'
		insert #t_DeadlineResult
		SELECT 
			d.GuidDetail,
			--ИсторияСобытий
			d.GuidБКИ_НФ_ИсторияСобытий,
			d.ДатаСобытия,
			d.ДатаСобытия_dt,
			d.ДатаСобытия_dt_2_workday,
			d.isActiveСобытия,
			d.ДатаЗаписиСобытия,
			d.ДатаЗаписиСобытия_dt,
			d.ДатаЗаписиСобытия_dt_2_workday,
			d.[ENTITY_NAME],
			
			BKI_NAME = T.bki_name,

			d.INSERT_DAY,
			d.GuidCRE_EXPORT_LOG_302,
			d.ID,
			d.INSERT_DATE,
			d.EVENT_ID,
			d.EVENT_NAME,
			d.EVENT_DATE,
			d.OPERATION_TYPE,
			d.SOURCE_CODE,
			d.REF_CODE,
			d.UUID,
			d.APPLICATION_NUMBER,
			d.ENTITY_NUMBER,
			d.APPLICANT_CODE,
			d.ORDER_NUM,
			d.EXPORT_FILENAME,
			d.IMPORT_FILENAME,
			d.EXPORT_EVENT_SUCCESS,
			d.ERROR_CODE,
			d.ERROR_DESC,
			d.CHANGE_CODE,
			d.SPECIAL_CHANGE_CODE,
			d.ACCOUNT,
			d.JOURNAL_ID,
			d.TRADE_ID,
			d.TRADEDETAIL_ID,
			d.IMPORT_ID,
			d.EXPORT_META_ID,
			-- любая ошибка
			d.isError,
			-- ошибка CRE
			d.isErrorCRE,
			-- ошибка из REJECT
			d.isErrorREJECT,
			d.GuidCRE_IMPORT_LOG_302,
			d.IMPORT_LOG_ID,
			d.IMPORT_INSERT_DATE,
			d.IMPORT_INSERT_DAY,
			d.IMPORT_SUCCESS,
			d.IMPORT_ERROR_CODE,
			d.IMPORT_ERROR_DESC,
			d.REJECT_ERROR_DESC,
			--TICKET
			d.GuidCRE_TICKET_LOG_302,
			d.TICKET_DATE,
			d.day_diff,
			d.isDeadline
		FROM #t_DeadlineResult as d
			inner join Reports.service.tvf_getBkiName() as T
				on T.bki_name <> 'НБКИ'
		where d.BKI_NAME in ('CMR', 'CRE')

		--SELECT d.*
		update d set BKI_NAME = 'НБКИ'
		FROM #t_DeadlineResult as d
		where 1=1
			and d.BKI_NAME in ('CMR', 'CRE')

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_DeadlineResult
			SELECT * INTO ##t_DeadlineResult FROM #t_DeadlineResult
		END

		-- события, по которым было не соблюдение сроков хотя бы по одному бюро
		drop table if exists #t_violation

		SELECT distinct
			d.GuidБКИ_НФ_ИсторияСобытий,
			d.ENTITY_NUMBER
		into #t_violation
		FROM #t_DeadlineResult as d
		where 1=1
			and (d.isDeadline = 'Нет'
				or d.isDeadline is null)
			--не показывать как нарушение событие без отправки
			--если по этому событию была повторная выгрузка и удачная отправка без нарушений
			and not exists(
				select top(1) 1
				from #t_DeadlineResult as x
				where x.ДатаСобытия_dt = d.ДатаСобытия_dt -- событие в тот же день
					and x.EVENT_ID = d.EVENT_ID -- то же событие
					and x.ENTITY_NUMBER = d.ENTITY_NUMBER -- по той же сделке/договору
					and x.BKI_NAME = d.BKI_NAME -- в то же бюро
					and x.ДатаЗаписиСобытия >= d.ДатаЗаписиСобытия -- позже по времени
					and x.isDeadline = 'Да' -- без нарушений
				)
			
			

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_violation
			SELECT * INTO ##t_violation FROM #t_violation
		END

		--out
		IF @Page in ('Deadline') BEGIN
			SELECT d.*
			FROM #t_DeadlineResult as d
				inner join #t_violation as x
					on x.GuidБКИ_НФ_ИсторияСобытий = d.GuidБКИ_НФ_ИсторияСобытий
			where 1=1
				--test
				--and d.GuidБКИ_НФ_ИсторияСобытий in ('162CB20E-53EC-48C7-8CDC-674F1246F659')
			--order by 
			--	d.ДатаСобытия_dt,
			--	d.EVENT_ID,
			--	case when d.IMPORT_SUCCESS is null then -1 else d.IMPORT_SUCCESS end,
			--	case when d.EXPORT_EVENT_SUCCESS is null then -1 else d.EXPORT_EVENT_SUCCESS end,
			--	d.ENTITY_NUMBER
		END

	END
	--// 'Deadline', 'StatSending'




	--Консолидированный отчет по отправке событий
	IF @Page = 'StatSending' BEGIN

		drop table if exists #t_StatSending

		select 
			ДатаСобытия = d.ДатаСобытия_dt,
			Событие = d.EVENT_ID,
			НаименованиеСобытия = d.EVENT_NAME,
			СформированоСобытий	= count(distinct d.GuidБКИ_НФ_ИсторияСобытий),
			ОтправленоВ_CRE	= count(distinct d.GuidCRE_IMPORT_LOG_302),
			ПринятоНаСторонеCRE	= 
				count(distinct 
					case 
						when d.IMPORT_SUCCESS = 1 --and d.EXPORT_EVENT_SUCCESS = 1
							then d.GuidCRE_IMPORT_LOG_302
						else null
					end),

			--НеПринятоНаСторонеCRE
			ОшибкаCRE =
				count(distinct 
					case 
						when d.IMPORT_SUCCESS = 0 --or d.EXPORT_EVENT_SUCCESS = 0
							then d.GuidCRE_IMPORT_LOG_302
						else null
					end),
			ПропущеноCRE = 
				count(distinct 
					case 
						when d.IMPORT_SUCCESS = 2 then d.GuidCRE_IMPORT_LOG_302
						else null
					end)
		into #t_StatSending
		from #t_Deadline as d
		group by
			d.ДатаСобытия_dt,
			d.EVENT_ID,
			d.EVENT_NAME

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_StatSending
			SELECT * INTO ##t_StatSending FROM #t_StatSending
		END

		drop table if exists #t_StatSendingBase
		select 
			a.ДатаСобытия,
			a.Событие,
			a.НаименованиеСобытия,
			b.BKI_NAME
		into #t_StatSendingBase
		from (
				select distinct
					s.ДатаСобытия,
					s.Событие,
					s.НаименованиеСобытия
				from #t_StatSending as s
			) as a
			inner join (
				select BKI_NAME = T.bki_name
				from service.tvf_getBkiName() as T
			) as b
			on 1=1

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_StatSendingBase
			SELECT * INTO ##t_StatSendingBase FROM #t_StatSendingBase
		END


		drop table if exists #t_StatSendingBKI

		select 
			b.ДатаСобытия,
			b.Событие,
			b.НаименованиеСобытия,
			b.BKI_NAME,
			Отправлено_в_БКИ = count(distinct d.GuidCRE_EXPORT_LOG_302),
			ПринятоНаСторонеБКИ =
				count(distinct 
					case 
						when d.EXPORT_EVENT_SUCCESS = 1 
							and d.REJECT_ERROR_DESC is null
						then d.GuidCRE_EXPORT_LOG_302
						else null
					end),
			ОшибкаБКИ = 
				count(distinct 
					case 
						when d.REJECT_ERROR_DESC is not null
						then d.GuidCRE_EXPORT_LOG_302
						else null
					end)
		into #t_StatSendingBKI
		from #t_StatSendingBase as b
			left join #t_Deadline as d
				on d.ДатаСобытия_dt = b.ДатаСобытия
				and d.EVENT_ID = b.Событие
				and d.BKI_NAME = b.BKI_NAME
		group by
			b.ДатаСобытия,
			b.Событие,
			b.НаименованиеСобытия,
			b.BKI_NAME

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_StatSendingBKI
			SELECT * INTO ##t_StatSendingBKI FROM #t_StatSendingBKI
		END


		select 
			s.ДатаСобытия,
			s.Событие,
			s.НаименованиеСобытия,
			s.СформированоСобытий,
			s.ОтправленоВ_CRE,
			s.ПринятоНаСторонеCRE,
			--НеПринятоНаСторонеCRE
			s.ОшибкаCRE,
			s.ПропущеноCRE,
			--
			b.BKI_NAME,
			b.Отправлено_в_БКИ,
			b.ПринятоНаСторонеБКИ,
			b.ОшибкаБКИ
		from #t_StatSending as s
			left join #t_StatSendingBKI as b
				on s.ДатаСобытия = b.ДатаСобытия
				and s.Событие = b.Событие


	END
	--// 'StatSending'

	--индикаторы витрины
	IF @Page = 'Indicators' BEGIN
		declare @max_update_at datetime
		select 
			--min_created_at = min(t.created_at),
			@max_update_at = max(t.created_at)
		from (
			select created_at = max(L.created_at)
			FROM dwh2.dm.CRE_IMPORT_LOG_302 AS L with(index = ix_INSERT_DATE)
			WHERE @dt_from <= L.INSERT_DATE AND L.INSERT_DATE < @dt_to
			union
			select created_at = max(L.created_at)
			FROM dwh2.dm.CRE_IMPORT_LOG_302 AS L with(index = ix_ДатаСобытия_dt)
			WHERE @dt_from <= L.ДатаСобытия_dt AND L.ДатаСобытия_dt < @dt_to
			union
			select created_at = max(L.created_at)
			FROM dwh2.dm.CRE_EXPORT_LOG_302 AS L with(index = ix_INSERT_DATE)
			WHERE @dt_from <= L.INSERT_DATE AND L.INSERT_DATE < @dt_to
			union
			select created_at = max(L.created_at)
			FROM dwh2.dm.CRE_EXPORT_LOG_302 AS L with(index = ix_ДатаСобытия_dt)
			WHERE @dt_from <= L.ДатаСобытия_dt AND L.ДатаСобытия_dt < @dt_to
			union
			select created_at = max(L.created_at)
			FROM dwh2.dm.БКИ_НФ_ИсторияСобытий as L with(index = ix_Дата_dt)
			WHERE @dt_from <= L.Дата_dt AND L.Дата_dt < @dt_to
		) as t

		-- дата обновления витрин
		select ДатаОбновленияВитрин = format(@max_update_at, 'dd.MM.yyyy HH:mm:ss')

		RETURN 0
	END
	--// 'Indicators'


END TRY
BEGIN CATCH
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
			ROLLBACK;

	SELECT @message = concat(
		'EXEC Risk.Report_dashboard_BKI ',
		'@Page=''', @Page, ''', ',
		'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@isDebug=', convert(varchar(10), @isDebug)
	)

	SELECT @eventType = concat(@Page, ' ERROR')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Risk.Report_dashboard_BKI',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END