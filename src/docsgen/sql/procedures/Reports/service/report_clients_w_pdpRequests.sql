-- =============================================
-- Author:		Aleksandr Shubkin
-- Create date: 16.10.2025
-- Description:	 Процедура для формирования набора данных 
--				 для отчета по клиентам, подавшим заявления на ПДП.
--				 Реализована в рамках DWH-312.
-- Example: exec Service.report_clients_w_pdpRequests 
-- =============================================
CREATE   PROCEDURE [service].[report_clients_w_pdpRequests] 
AS
BEGIN
	SET NOCOUNT ON;
	-- Дата подачи заявления на ПДП
	DROP TABLE IF EXISTS #t_pdp_requestDate
	SELECT 
		Договор_Номер = ДоговорНаЗайм.Номер,
		ДатаЗаявление = dateadd(year,-2000,	заялениеДП.Дата)
		,НомерЗаявления = заялениеДП.Номер
	INTO #t_pdp_requestDate
	FROM		stg._1cCRM.Документ_ЗаявлениеНаДосрочноеПогашение заялениеДП
	INNER JOIN	stg._1cCRM.Справочник_ВидыЧДП									AS ВидыЧДП			
		ON заялениеДП.ВидЧДП	= ВидыЧДП.ССЫлка 
	INNER JOIN	stg._1cCRM.Справочник_СтатусыЗаявленийНаДосрочноеПогашение		AS статусыЗаявления 
		ON заялениеДП.Статус	= статусыЗаявления.ССЫлка
	INNER JOIN	stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС							AS ДоговорНаЗайм	
		ON заялениеДП.Договор	= ДоговорНаЗайм.ССЫлка
	WHERE	заялениеДП.ПометкаУдаления = 0x00
		and (ВидыЧДП.Наименование = 'ПДП')
		and статусыЗаявления.Наименование in ('Ожидает списания')
	
	-- Набор договоров
	DROP TABLE IF EXISTS #t_contracts
	SELECT
		ДоговорЗайма.КодДоговораЗайма,
		ДоговорЗайма.GuidДоговораЗайма,
		ДоговорЗайма.ДатаДоговораЗайма,
		ДоговорЗайма.СуммаВыдачи,
		ДоговорЗайма.ТипПродукта
	INTO #t_contracts
	FROM dwh2.hub.ДоговорЗайма ДоговорЗайма
	WHERE ДоговорЗайма.ДатаЗакрытияДоговора IS NULL 
	and exists(select top(1) 1 from  #t_pdp_requestDate AS contracts_w_pdp
		where ДоговорЗайма.КодДоговораЗайма =  contracts_w_pdp.Договор_Номер)
	-- Плановая дата погашения займа
	DROP TABLE IF EXISTS #t_loanClosement
	SELECT
		[Код],
		[Плановая дата погашения займа] = MAX([ДатаПлатежа])
	INTO #t_loanClosement
	FROM dwh2.[dm].[CMRExpectedRepayments] payments
	where exists(select top(1) 1 from #t_contracts AS contracts
		where contracts.КодДоговораЗайма = payments.Код)
	GROUP BY [Код]
	
	-- Дата поступления оплаты
	DROP TABLE IF EXISTS #t_paymentDate
	SELECT
	    q2.CMRContractsGUID,
	    ПоследняяДатаСПоступлениями = q2.d
	INTO #t_paymentDate
	FROM (
		SELECT
			CMRContractsGUID,
	        d,
	        [сумма поступлений],
	        rn = ROW_NUMBER() OVER (
	            PARTITION BY external_id
	            ORDER BY d DESC
	        )
		FROM [dwh2].[dbo].[dm_CMRStatBalance] balance
	    WHERE [сумма поступлений] > 0	
		and exists(select top(1) 1 from #t_contracts contracts
			where contracts.КодДоговораЗайма = balance.external_id
		)
	)  q2
	WHERE q2.rn = 1

	-- Последняя запись по каждому договору на сегодня
	declare @today date = cast(getdate() as date)
	DROP TABLE IF EXISTS #t_todayBalance
	SELECT
		CMRContractsGUID,
		[Рассчетный остаток всего на сегодня],
		[Переплата на сегодня]
	INTO #t_todayBalance
	FROM (
		SELECT 
			balance.CMRContractsGUID,
			balance.d,
			[Рассчетный остаток всего на сегодня] = balance.[Расчетный остаток всего],
			[Переплата на сегодня] = -1 * balance.overdue,
			rn = ROW_NUMBER() OVER (
	            PARTITION BY CMRContractsGUID
	            ORDER BY d DESC
	        )
		FROM [dwh2].[dbo].[dm_CMRStatBalance] balance
	    WHERE	balance.[сумма поступлений] > 0
			--AND balance.d  <= @today
			AND EXISTS (select top(1) 1 from #t_contracts contracts
				where contracts.КодДоговораЗайма = balance.external_id
			)
	) q3
	WHERE rn = 1
	
	-- Информация по клиенту
	DROP TABLE IF EXISTS #t_restOfTheFields
	SELECT
		ДоговорЗайма.КодДоговораЗайма,
		ДоговорЗайма.GuidДоговораЗайма,
		ДоговорЗайма.ДатаДоговораЗайма,
		ДоговорЗайма.СуммаВыдачи,
		ДоговорЗайма.ТипПродукта,
		Клиенты.ФИО,
		Клиент_Email.Email,
		Клиент_Телефон.НомерТелефонаБезКодов,
		Регион.РегионФактическогоПроживания
	INTO #t_restOfTheFields
	FROM	   #t_contracts						AS ДоговорЗайма
	INNER JOIN dwh2.link.Клиент_ДоговорЗайма	AS Линк_Клиент_ДоговорЗайма
		ON 	ДоговорЗайма.КодДоговораЗайма = Линк_Клиент_ДоговорЗайма.КодДоговораЗайма
	INNER JOIN dwh2.hub.Клиенты					AS Клиенты
		ON 	Клиенты.GuidКлиент = Линк_Клиент_ДоговорЗайма.GuidКлиент
	LEFT JOIN dwh2.sat.Клиент_Email Клиент_Email
		ON 	Клиент_Email.GuidКлиент = Клиенты.GuidКлиент
		and Клиент_Email.nRow       = 1
	LEFT JOIN dwh2.sat.Клиент_Телефон Клиент_Телефон
		ON  Клиент_Телефон.GuidКлиент = Клиенты.GuidКлиент
		AND Клиент_Телефон.nRow       = 1
	LEFT JOIN dwh2.sat.Клиент_РегионФактическогоПроживания Регион
		on 	Регион.GuidКлиент = Клиенты.GuidКлиент
	
	-- Полноценный набор данных
	SELECT DISTINCT
		  [Номер договора]						= fields.КодДоговораЗайма
		, [Сумма займа]							= fields.СуммаВыдачи
		, [Дата выдачи займа]					= cast(fields.ДатаДоговораЗайма as date)
		, [Плановая дата погашения займа]		= loan.[Плановая дата погашения займа]
		, [Продукт]								= fields.ТипПродукта
		, [ФИО клиента]							= fields.ФИО
		, [Адрес электронной почты]				= fields.Email
		, [Номер телефона]						= fields.НомерТелефонаБезКодов
		, [Регион проживания]					= fields.РегионФактическогоПроживания
		, [Дата поступления оплаты]				= cast(payDay.ПоследняяДатаСПоступлениями as date)
		, [Дата подачи заявления на ПДП]		= cast(pdp_date.ДатаЗаявление			  as date)
		, [Рассчетный остаток всего на сегодня] = today_balance.[Рассчетный остаток всего на сегодня]
		, [Переплата на сегодня]				= today_balance.[Переплата на сегодня]
	FROM		#t_restOfTheFields fields
	LEFT JOIN	#t_loanClosement loan
		   ON   fields.КодДоговораЗайма		= loan.Код
	LEFT JOIN	#t_paymentDate payDay
		   ON   fields.GuidДоговораЗайма	= payDay.CMRContractsGUID	 
	LEFT JOIN	#t_pdp_requestDate pdp_date
		   ON   fields.КодДоговораЗайма		= pdp_date.Договор_Номер
	LEFT JOIN	#t_todayBalance today_balance
		   ON	fields.GuidДоговораЗайма    = today_balance.CMRContractsGUID
END
