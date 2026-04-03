-- =============================================
-- Author:		Aleksandr Shubkin
-- Create date: 18.09.2025
-- Description: Процедура создана для актуализации кода процедуры [dbo].[reportCollection_NonPaymentReason]
--				В ней собираются подробные данные по причинам не платежа, стадиям и дням просрочки в разрезе "на каждый день"
--				В качестве параметров процедура принимает в себя год и месяц для фильтрации данны по промежуткам.
--				Результатом работы процедуры является актуализация данных в таблице	[Reports].[collection].[CollectionNonPaymentReasonFullDetail]
--				Процедура реализована в рамках DWH-245
-- =============================================
CREATE PROCEDURE [collection].[reportCollectionNonPaymentReason] 
	@year  int = NULL,
	@month int = NULL,
	@is_deBug bit = 0
AS
BEGIN
	BEGIN TRY
	SET NOCOUNT ON;
	-- 1. Параметры периода
	IF @month IS NULL SET @month = MONTH(GetDate());
	IF @year  IS NULL SET @year  = YEAR (GetDate());
	DECLARE @BeginDate date = datefromparts(@year, @month, 1);
	DECLARE @EndDate   date = eomonth(@BeginDate);

	if @is_deBug = 1
	begin
		select @BeginDate  as BeginDate
		select @EndDate	  as EndDate
	end

	--2. Источник: коммуникации с ненулевой причиной
	-- @changelog [sh.a.] | feat:	добавили групировку по клиенту
	--								с детализайией до communicationId
	DROP TABLE IF EXISTS #t_CommsWithNonPaymentReason;
	SELECT
		CommunicationId,
		NonPaymentReason,
		DealNumber,
		CrmCustomerId,
		[date]
	INTO #t_CommsWithNonPaymentReason
	FROM (
	    SELECT
			CommunicationId	 = c.id,
	        NonPaymentReason = TRIM(npr.Name),
	        DealNumber       = d.Number,
	        CrmCustomerId    = cu.CrmCustomerId,
	        [date]           = CAST(c.[date] AS date),
	        rn = ROW_NUMBER() OVER (
	                 PARTITION BY c.id, d.Number, cu.CrmCustomerId, TRIM(npr.Name)
	                 ORDER BY c.[date] DESC
	             )
	    FROM  stg._collection.Communications   AS c
	    JOIN  stg._collection.Customers        AS cu  ON cu.Id = c.CustomerId
	    JOIN  stg._collection.Deals            AS d   ON d.Id  = c.IdDeal
	    JOIN  stg._collection.NonPaymentReason AS npr ON npr.Id = c.NonPaymentReasonId
	    WHERE CAST(c.[date] AS date) BETWEEN @BeginDate AND @EndDate
	) t
	WHERE t.rn = 1
	-- where row_number = 1;

	-- 3. Источник: стадия клиента по дням 
	-- Получаем дневной срез стадии коллекта для GUID клиента.
	DROP TABLE IF EXISTS #t_ClientStageByDate;
	SELECT
		dt = cast(call_date as date),
	    CRMClientGUID,
	    Client_Stage = TRIM(Client_Stage)
	INTO #t_ClientStageByDate
	FROM stg._loginom.Collection_Client_Stage_history
	WHERE call_date BETWEEN @BeginDate AND @EndDate;

	-- 4. Сборка единого источника для загрузки
	-- Обогащаем коммуникации стадией, ФИО, данными по договору,
    -- подтягиваем DPD на начало дня.
	DROP TABLE IF EXISTS #t_srcFullDetail; 
	SELECT
		  [Дата]					= FD.[date]
		, [Guid клиента]			= FD.GuidКлиент
		, [ФИО клиента]				= FD.ФИО
		, [Номер договора]			= FD.КодДоговораЗайма
		, [Guid Договора]			= FD.GuidДоговораЗайма
		, [Тип продукта]  			= FD.ТипПродукта
		, [Подтип продукта]			= FD.ПодТипПродукта
		, [ID коммуникации]			= FD.CommunicationId
		, [Причина не платежа]		= FD.NonPaymentReason
		, [Стадия клиента]			= FD.Client_Stage
		, [dpd на начало дня]		= FD.[dpd_begin_day]
	INTO #t_srcFullDetail
	FROM (
		SELECT
			Reason.[date]
			, ФИО = ISNULL(NULLIF(TRIM(Клиенты.ФИО), N''), N'Не указано')
			, Клиенты.GuidКлиент
			, ДоговорЗайма.КодДоговораЗайма
			, ДоговорЗайма.GuidДоговораЗайма
			, ДоговорЗайма.ТипПродукта
			, ДоговорЗайма.ПодТипПродукта
			-- @changelog [sh.a.] | append comm id
			, CommunicationId = Reason.CommunicationId
			, NonPaymentReason=TRIM(Reason.NonPaymentReason)
			, Client_Stage = TRIM(Stages.Client_Stage)
			, Баланс.[dpd_begin_day]
		FROM #t_CommsWithNonPaymentReason			as Reason
		INNER JOIN [dwh2].[dbo].[dm_CMRStatBalance]	as Баланс	ON Баланс.external_id			 = Reason.DealNumber AND
																   Баланс.d						 = Reason.date
		LEFT JOIN #t_ClientStageByDate				as Stages	ON Stages.CRMClientGUID			 = Reason.CrmCustomerId AND 
																   Stages.dt					 = Reason.date
		LEFT JOIN dwh2.hub.Клиенты		as Клиенты				ON Клиенты.GuidКлиент			 = Reason.CrmCustomerId
		LEFT JOIN dwh2.hub.ДоговорЗайма as ДоговорЗайма			ON ДоговорЗайма.КодДоговораЗайма = Reason.DealNumber	
	) AS FD

	if @is_deBug = 1
	BEGIN
		select * from #t_srcFullDetail
	END
	-- 5. Изменение целевой таблицы
	-- Сначала удаляем «лишние» строки за период
	BEGIN TRAN;
	DELETE T
	FROM [collection].[CollectionNonPaymentReasonFullDetail] AS T
	WHERE T.[Дата] BETWEEN @BeginDate AND @EndDate
	AND NOT EXISTS (
		SELECT 1
		FROM #t_srcFullDetail AS S
		WHERE  S.[Дата]				= T.[Дата]
	    AND S.[Причина не платежа]	= T.[Причина не платежа]
	    AND S.[Стадия клиента]		= T.[Стадия клиента]
	    AND S.[Guid клиента]		= T.[Guid клиента]
		AND S.[Guid Договора]		= T.[Guid Договора]
		AND S.[ID коммуникации]		= T.[ID коммуникации]
	 );
	 ;MERGE [collection].[CollectionNonPaymentReasonFullDetail]	AS T
	 USING	#t_srcFullDetail		AS S
	 ON	 T.[Дата]				= S.[Дата]
	 AND T.[Причина не платежа]	= S.[Причина не платежа]
	 AND T.[Стадия клиента]		= S.[Стадия клиента]
	 AND T.[Guid клиента]		= S.[Guid клиента]
	 AND T.[ID коммуникации]	= S.[ID коммуникации]
	 -- @changelog [sh.a.] | feat:  Обновляем зерно мерджа по паре 
	 --							--	[Guid Клиент] х [Guid Договора] --
	 --								здесь и в delete
	 AND T.[Guid Договора]		= S.[Guid Договора]
	 WHEN MATCHED THEN
	 UPDATE SET
		T.[Дата]				= S.[Дата]				,
		T.[Guid клиента]		= S.[Guid клиента]		,
		T.[ФИО клиента]			= S.[ФИО клиента]		,
		T.[Номер договора]		= S.[Номер договора]	,
		T.[Guid Договора]		= S.[Guid Договора]		,
		T.[Тип продукта]  		= S.[Тип продукта]  	,
		T.[Подтип продукта]		= S.[Подтип продукта]	,
		T.[ID коммуникации]		= S.[ID коммуникации]	,
		T.[Причина не платежа]	= TRIM(S.[Причина не платежа]),
		T.[Стадия клиента]		= TRIM(S.[Стадия клиента]),
		T.[dpd на начало дня]	= S.[dpd на начало дня]	
	 WHEN NOT MATCHED BY TARGET THEN
	 INSERT (
		[Дата], [Guid клиента], [ФИО клиента],[Номер договора],
		[Guid Договора], [Тип продукта], [Подтип продукта],[ID коммуникации],	
		[Причина не платежа],[Стадия клиента], [dpd на начало дня]
	) VALUES  (
		S.[Дата], S.[Guid клиента], S.[ФИО клиента], S.[Номер договора],
		S.[Guid Договора], S.[Тип продукта], S.[Подтип продукта],S.[ID коммуникации],	
		S.[Причина не платежа],S.[Стадия клиента], S.[dpd на начало дня]
	);
	COMMIT;
	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0 ROLLBACK;
		DECLARE @msg nvarchar(2048) = ERROR_MESSAGE();
        DECLARE @errnum int = ERROR_NUMBER();
        DECLARE @state  int = ERROR_STATE();

        RAISERROR(N'Ошибка в reportCollectionNonPaymentReason (%d-%d): %s',
                  16, 1, @errnum, @state, @msg);
        RETURN;
	END CATCH;
END
