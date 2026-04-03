CREATE PROC sat.fill_ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта
	@phone nvarchar(20) = NULL,
	@isDebug int = 0
as
begin
	--truncate table sat.ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта
begin TRY
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	SELECT @isDebug = isnull(@isDebug, 0)

	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @updated_at datetime = '1900-01-01'

	drop table if exists #t_ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта

	if OBJECT_ID ('sat.ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта') is not null
	begin
		--set @rowVersion = isnull((select max(ВерсияДанных) from sat.ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта), 0x0)
		SELECT 
			--@rowVersion = isnull(max(S.ВерсияДанных), 0x0),
			@updated_at = isnull(dateadd(HOUR, -2, max(S.updated_at)), '1900-01-01')
		FROM sat.ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта AS S
	end

	DROP TABLE IF EXISTS #t_Заявки
	CREATE TABLE #t_Заявки(СсылкаЗаявки binary(16), GuidЗаявки nvarchar(36)) -- uniqueidentifier)

	--1 новые заявки
	INSERT #t_Заявки(СсылкаЗаявки, GuidЗаявки)
	SELECT Заявка.СсылкаЗаявки, Заявка.GuidЗаявки 
	FROM hub.Заявка AS Заявка
	WHERE Заявка.updated_at > @updated_at
		AND (@phone IS NULL OR Заявка.МобильныйТелефон = @phone)

	CREATE UNIQUE INDEX ix1 ON #t_Заявки(GuidЗаявки)

	--2 новые статусы
	IF @phone IS NULL BEGIN
		INSERT #t_Заявки(СсылкаЗаявки, GuidЗаявки)
		SELECT DISTINCT Статусы.СсылкаЗаявки, Статусы.GuidЗаявки 
		FROM sat.ЗаявкаНаЗаймПодПТС_Статусы AS Статусы
		WHERE Статусы.updated_at > @updated_at
			AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_Заявки AS X WHERE X.GuidЗаявки = Статусы.GuidЗаявки)
	END
	
	DROP TABLE IF EXISTS #t_Заявки2
	CREATE TABLE #t_Заявки2(
		СсылкаЗаявки binary(16), 
		НомерЗаявки nvarchar(20),
		GuidЗаявки nvarchar(36),
		--
		[Наличие Залога] varchar(20),
		--
		СсылкаНаКлиента binary(16),
		GuidКлиента nvarchar(36),
		--
		ТелефонИзЗаявки nvarchar(16),
		ОсновнойТелефонКлиента nvarchar(20),
		--
		ДатаОпределенияВидаЗайма datetime2(0)
	)

	INSERT #t_Заявки2
	(
	    СсылкаЗаявки,
	    НомерЗаявки,
	    GuidЗаявки,
		[Наличие Залога],
	    СсылкаНаКлиента,
	    GuidКлиента,
	    ТелефонИзЗаявки,
	    ОсновнойТелефонКлиента,
		ДатаОпределенияВидаЗайма
	)
	SELECT 
		D.СсылкаЗаявки,
		D.НомерЗаявки,
		D.GuidЗаявки,
		D.[Наличие Залога],
		D.СсылкаНаКлиента,
		D.GuidКлиента,
		ТелефонИзЗаявки = D.Телефон,
		ОсновнойТелефонКлиента = P.НомерТелефонаБезКодов,
		ДатаОпределенияВидаЗайма = isnull(D.[Верификация КЦ], D.ДатаЗаявки)
	FROM #t_Заявки AS R
		INNER JOIN dm.v_ЗаявкаНаЗаймПодПТС_и_СтатусыИСобытия AS D
			ON D.GuidЗаявки = R.GuidЗаявки
		LEFT JOIN sat.Клиент_Телефон AS P
			ON P.GuidКлиент = D.GuidКлиента
			AND P.nRow = 1

	CREATE UNIQUE INDEX ix1 ON #t_Заявки2(GuidЗаявки)
	CREATE INDEX ix2 ON #t_Заявки2(ТелефонИзЗаявки)
	CREATE INDEX ix3 ON #t_Заявки2(ОсновнойТелефонКлиента)
	CREATE INDEX ix4 ON #t_Заявки2(GuidКлиента)

	--вспомогательная таблица для определения #t_dm_ЗаявкаНаЗаймПодПТС (для того, чтобы определить ДругиеЗаявки)
	DROP TABLE IF EXISTS #t_GuidЗаявки
	CREATE TABLE #t_GuidЗаявки(GuidЗаявки nvarchar(36))

	-- 1.1. D.МобильныйТелефон = R.ТелефонИзЗаявки
	INSERT #t_GuidЗаявки(GuidЗаявки)
	SELECT DISTINCT R.GuidЗаявки
	FROM #t_Заявки2 AS R
		INNER JOIN hub.Заявка AS D
			ON D.МобильныйТелефон = R.ТелефонИзЗаявки

	CREATE UNIQUE INDEX ix1 ON #t_GuidЗаявки(GuidЗаявки)

	-- 1.2. D.МобильныйТелефон = R.ОсновнойТелефонКлиента
	INSERT #t_GuidЗаявки(GuidЗаявки)
	SELECT DISTINCT D.GuidЗаявки
	FROM #t_Заявки2 AS R
		INNER JOIN hub.Заявка AS D
			ON D.МобильныйТелефон = R.ОсновнойТелефонКлиента
	WHERE NOT EXISTS(SELECT TOP(1) 1 FROM #t_GuidЗаявки AS X WHERE X.GuidЗаявки = D.GuidЗаявки)

	-- 2.1. ОсновнойТелефонКлиента = R.ТелефонИзЗаявки
	INSERT #t_GuidЗаявки(GuidЗаявки)
	SELECT DISTINCT Клиент.GuidЗаявки
	FROM #t_Заявки2 AS R
		INNER JOIN sat.Клиент_Телефон AS P
			ON P.НомерТелефонаБезКодов = R.ТелефонИзЗаявки
			AND P.nRow = 1
		INNER JOIN link.v_Клиент_Заявка AS Клиент
			ON Клиент.GuidКлиент = P.GuidКлиент
	WHERE NOT EXISTS(SELECT TOP(1) 1 FROM #t_GuidЗаявки AS X WHERE X.GuidЗаявки = Клиент.GuidЗаявки)

	-- 2.2. ОсновнойТелефонКлиента = R.ОсновнойТелефонКлиента
	INSERT #t_GuidЗаявки(GuidЗаявки)
	SELECT DISTINCT Клиент.GuidЗаявки
	FROM #t_Заявки2 AS R
		INNER JOIN sat.Клиент_Телефон AS P
			ON P.НомерТелефонаБезКодов = R.ОсновнойТелефонКлиента
			AND P.nRow = 1
		INNER JOIN link.v_Клиент_Заявка AS Клиент
			ON Клиент.GuidКлиент = P.GuidКлиент
	WHERE NOT EXISTS(SELECT TOP(1) 1 FROM #t_GuidЗаявки AS X WHERE X.GuidЗаявки = Клиент.GuidЗаявки)

	-- 3. GuidКлиента = R.GuidКлиента
	INSERT #t_GuidЗаявки(GuidЗаявки)
	SELECT DISTINCT Клиент.GuidЗаявки
	FROM #t_Заявки2 AS R
		INNER JOIN link.v_Клиент_Заявка AS Клиент
			ON Клиент.GuidКлиент = R.GuidКлиента
	WHERE NOT EXISTS(SELECT TOP(1) 1 FROM #t_GuidЗаявки AS X WHERE X.GuidЗаявки = Клиент.GuidЗаявки)


	DROP TABLE IF EXISTS #t_dm_ЗаявкаНаЗаймПодПТС
	CREATE TABLE #t_dm_ЗаявкаНаЗаймПодПТС
	(
		СсылкаЗаявки binary(16),
		НомерЗаявки nvarchar(20),
		GuidЗаявки nvarchar(36),
		ДатаЗаявки datetime2(0),
		СсылкаНаКлиента binary(16),
		GuidКлиента nvarchar(36),
		Телефон nvarchar(20),
		ОсновнойТелефонКлиента nvarchar(20),
		[Наличие Залога] varchar(20)
	)

	INSERT #t_dm_ЗаявкаНаЗаймПодПТС
	(
	    СсылкаЗаявки,
	    НомерЗаявки,
	    GuidЗаявки,
	    ДатаЗаявки,
	    СсылкаНаКлиента,
	    GuidКлиента,
	    Телефон,
	    ОсновнойТелефонКлиента,
	    [Наличие Залога]
	)
	SELECT 
		D.СсылкаЗаявки,
		D.НомерЗаявки,
		D.GuidЗаявки,
		D.ДатаЗаявки,
		D.СсылкаНаКлиента,
		D.GuidКлиента,
		D.Телефон,
		ОсновнойТелефонКлиента = P.НомерТелефонаБезКодов,
		D.[Наличие Залога]
	FROM #t_GuidЗаявки AS R
		INNER JOIN dm.ЗаявкаНаЗаймПодПТС AS D
			ON D.GuidЗаявки = R.GuidЗаявки
		LEFT JOIN sat.Клиент_Телефон AS P
			ON P.GuidКлиент = D.GuidКлиента
			AND P.nRow = 1

	CREATE INDEX ix1 ON #t_dm_ЗаявкаНаЗаймПодПТС(Телефон) 
	INCLUDE ([Наличие Залога], ДатаЗаявки, GuidЗаявки, GuidКлиента, ОсновнойТелефонКлиента)

	CREATE INDEX ix2 ON #t_dm_ЗаявкаНаЗаймПодПТС(ОсновнойТелефонКлиента)
	INCLUDE ([Наличие Залога], ДатаЗаявки, GuidЗаявки, GuidКлиента, Телефон)

	CREATE INDEX ix3 ON #t_dm_ЗаявкаНаЗаймПодПТС(GuidКлиента)
	INCLUDE ([Наличие Залога], ДатаЗаявки, GuidЗаявки, ОсновнойТелефонКлиента, Телефон)


	--ДругиеЗаявки - те, которые были на момент создания МастерЗаявки из #t_Заявки2
	DROP TABLE IF EXISTS #t_ДругиеЗаявки
	CREATE TABLE #t_ДругиеЗаявки
	(
		GuidМастерЗаявки nvarchar(36),
		--
		СсылкаЗаявки binary(16), 
		НомерЗаявки nvarchar(20),
		GuidЗаявки nvarchar(36),
		--
		СсылкаНаКлиента binary(16),
		GuidКлиента nvarchar(36),
		--
		ТелефонИзЗаявки nvarchar(16),
		ОсновнойТелефонКлиента nvarchar(20),
		--
	    СтатусЗаявки_НаДатуОпределенияВидаЗайма nvarchar(150)
	)

	--1.1 поиск по полю dm.ЗаявкаНаЗаймПодПТС.Телефон
	INSERT #t_ДругиеЗаявки
	(
		GuidМастерЗаявки,
		СсылкаЗаявки,
		НомерЗаявки,
		GuidЗаявки,
		СсылкаНаКлиента,
		GuidКлиента,
		ТелефонИзЗаявки,
		ОсновнойТелефонКлиента
	)
	SELECT 
		GuidМастерЗаявки = R.GuidЗаявки,
		D.СсылкаЗаявки,
		D.НомерЗаявки,
		D.GuidЗаявки,
		D.СсылкаНаКлиента,
		D.GuidКлиента,
		ТелефонИзЗаявки = D.Телефон,
		D.ОсновнойТелефонКлиента
	FROM #t_Заявки2 AS R
		INNER JOIN #t_dm_ЗаявкаНаЗаймПодПТС AS D
			ON D.Телефон = R.ТелефонИзЗаявки
			AND D.[Наличие Залога] = R.[Наличие Залога]
			AND D.ДатаЗаявки <= R.ДатаОпределенияВидаЗайма
			AND D.GuidЗаявки <> R.GuidЗаявки

	CREATE INDEX ix1 ON #t_ДругиеЗаявки(GuidЗаявки)

	--1.2 поиск по полю dm.ЗаявкаНаЗаймПодПТС.Телефон
	INSERT #t_ДругиеЗаявки
	(
		GuidМастерЗаявки,
		СсылкаЗаявки,
		НомерЗаявки,
		GuidЗаявки,
		СсылкаНаКлиента,
		GuidКлиента,
		ТелефонИзЗаявки,
		ОсновнойТелефонКлиента
	)
	SELECT 
		GuidМастерЗаявки = R.GuidЗаявки,
		D.СсылкаЗаявки,
		D.НомерЗаявки,
		D.GuidЗаявки,
		D.СсылкаНаКлиента,
		D.GuidКлиента,
		ТелефонИзЗаявки = D.Телефон,
		D.ОсновнойТелефонКлиента
	FROM #t_Заявки2 AS R
		INNER JOIN #t_dm_ЗаявкаНаЗаймПодПТС AS D
			ON D.Телефон = R.ОсновнойТелефонКлиента
			AND D.[Наличие Залога] = R.[Наличие Залога]
			AND D.ДатаЗаявки <= R.ДатаОпределенияВидаЗайма
			AND D.GuidЗаявки <> R.GuidЗаявки
	WHERE NOT EXISTS(SELECT TOP(1) 1 FROM #t_ДругиеЗаявки AS X WHERE X.GuidЗаявки = D.GuidЗаявки)



	--2.1 поиск по полю sat.Клиент_Телефон.НомерТелефонаБезКодов AND nRow = 1 (ОсновнойТелефонКлиента)
	INSERT #t_ДругиеЗаявки
	(
		GuidМастерЗаявки,
		СсылкаЗаявки,
		НомерЗаявки,
		GuidЗаявки,
		СсылкаНаКлиента,
		GuidКлиента,
		ТелефонИзЗаявки,
		ОсновнойТелефонКлиента
	)
	SELECT 
		GuidМастерЗаявки = R.GuidЗаявки,
		D.СсылкаЗаявки,
		D.НомерЗаявки,
		D.GuidЗаявки,
		D.СсылкаНаКлиента,
		D.GuidКлиента,
		ТелефонИзЗаявки = D.Телефон,
		D.ОсновнойТелефонКлиента
	FROM #t_Заявки2 AS R
		INNER JOIN #t_dm_ЗаявкаНаЗаймПодПТС AS D
			ON D.ОсновнойТелефонКлиента = R.ТелефонИзЗаявки
			AND D.[Наличие Залога] = R.[Наличие Залога]
			AND D.ДатаЗаявки <= R.ДатаОпределенияВидаЗайма
			AND D.GuidЗаявки <> R.GuidЗаявки
	WHERE NOT EXISTS(SELECT TOP(1) 1 FROM #t_ДругиеЗаявки AS X WHERE X.GuidЗаявки = D.GuidЗаявки)


	--2.2 поиск по полю sat.Клиент_Телефон.НомерТелефонаБезКодов AND nRow = 1 (ОсновнойТелефонКлиента)
	INSERT #t_ДругиеЗаявки
	(
		GuidМастерЗаявки,
		СсылкаЗаявки,
		НомерЗаявки,
		GuidЗаявки,
		СсылкаНаКлиента,
		GuidКлиента,
		ТелефонИзЗаявки,
		ОсновнойТелефонКлиента
	)
	SELECT 
		GuidМастерЗаявки = R.GuidЗаявки,
		D.СсылкаЗаявки,
		D.НомерЗаявки,
		D.GuidЗаявки,
		D.СсылкаНаКлиента,
		D.GuidКлиента,
		ТелефонИзЗаявки = D.Телефон,
		D.ОсновнойТелефонКлиента
	FROM #t_Заявки2 AS R
		INNER JOIN #t_dm_ЗаявкаНаЗаймПодПТС AS D
			ON D.ОсновнойТелефонКлиента = R.ОсновнойТелефонКлиента
			AND D.[Наличие Залога] = R.[Наличие Залога]
			AND D.ДатаЗаявки <= R.ДатаОпределенияВидаЗайма
			AND D.GuidЗаявки <> R.GuidЗаявки
	WHERE NOT EXISTS(SELECT TOP(1) 1 FROM #t_ДругиеЗаявки AS X WHERE X.GuidЗаявки = D.GuidЗаявки)

	--3 поиск по GuidКлиента
	INSERT #t_ДругиеЗаявки
	(
		GuidМастерЗаявки,
		СсылкаЗаявки,
		НомерЗаявки,
		GuidЗаявки,
		СсылкаНаКлиента,
		GuidКлиента,
		ТелефонИзЗаявки,
		ОсновнойТелефонКлиента
	)
	SELECT 
		GuidМастерЗаявки = R.GuidЗаявки,
		D.СсылкаЗаявки,
		D.НомерЗаявки,
		D.GuidЗаявки,
		D.СсылкаНаКлиента,
		D.GuidКлиента,
		ТелефонИзЗаявки = D.Телефон,
		D.ОсновнойТелефонКлиента
	FROM #t_Заявки2 AS R
		INNER JOIN #t_dm_ЗаявкаНаЗаймПодПТС AS D
			ON D.GuidКлиента = R.GuidКлиента
			AND D.[Наличие Залога] = R.[Наличие Залога]
			AND D.ДатаЗаявки <= R.ДатаОпределенияВидаЗайма
			AND D.GuidЗаявки <> R.GuidЗаявки
	WHERE NOT EXISTS(SELECT TOP(1) 1 FROM #t_ДругиеЗаявки AS X WHERE X.GuidЗаявки = D.GuidЗаявки)

	/*
	DROP TABLE IF EXISTS #t_СтатусыДругихЗаявок
	CREATE TABLE #t_СтатусыДругихЗаявок
	(
		GuidМастерЗаявки nvarchar(36),
		GuidЗаявки nvarchar(36),
		ДатаСтатуса datetime2(0),
		ДатаОкончанияСтатуса datetime2(0),
		СтатусЗаявки nvarchar(150)
	)

	INSERT #t_СтатусыДругихЗаявок
	(
	    GuidМастерЗаявки,
	    GuidЗаявки,
	    ДатаСтатуса,
	    ДатаОкончанияСтатуса,
	    СтатусЗаявки
	)
	SELECT 
		Заявки.GuidМастерЗаявки,
		Заявки.GuidЗаявки,
		Статусы.ДатаСтатуса,
		ДатаОкончанияСтатуса = lead(Статусы.ДатаСтатуса,1,cast('3000-01-01' AS datetime2(0)))
			OVER(PARTITION BY Заявки.GuidМастерЗаявки, Заявки.GuidЗаявки ORDER BY Статусы.ДатаСтатуса),
		Статусы.СтатусЗаявки
	FROM #t_ДругиеЗаявки AS Заявки
		INNER JOIN sat.ЗаявкаНаЗаймПодПТС_Статусы AS Статусы
			ON Статусы.GuidЗаявки = Заявки.GuidЗаявки


	UPDATE D
	SET D.СтатусЗаявки_НаДатуОпределенияВидаЗайма = S.СтатусЗаявки
	FROM #t_Заявки2 AS R
		INNER JOIN #t_ДругиеЗаявки AS D
			ON D.GuidМастерЗаявки = R.GuidЗаявки
		INNER JOIN #t_СтатусыДругихЗаявок AS S
			ON S.GuidМастерЗаявки = D.GuidМастерЗаявки
			AND S.GuidЗаявки = D.GuidЗаявки
			AND S.ДатаСтатуса <= R.ДатаОпределенияВидаЗайма AND R.ДатаОпределенияВидаЗайма < S.ДатаОкончанияСтатуса
	*/


	--ДругиеДоговора - те, которые были на момент создания МастерЗаявки из #t_Заявки2
	DROP TABLE IF EXISTS #t_ДругиеДоговора
	CREATE TABLE #t_ДругиеДоговора
	(
		GuidМастерЗаявки nvarchar(36),
		--
		СсылкаЗаявки binary(16), 
		GuidЗаявки nvarchar(36),
		--
		СсылкаДоговора binary(16), 
		НомерДоговора nvarchar(20),
		--
	    СтатусДоговора_НаДатуОпределенияВидаЗайма nvarchar(150),
		IsActive int,
		IsEnded int
	)

	INSERT #t_ДругиеДоговора
	(
	    GuidМастерЗаявки,
	    СсылкаЗаявки,
	    GuidЗаявки,
	    СсылкаДоговора,
		НомерДоговора
	)
	SELECT 
	    Заявки.GuidМастерЗаявки,
	    Заявки.СсылкаЗаявки,
	    Заявки.GuidЗаявки,
	    СсылкаДоговора = Договоры.Ссылка,
	    НомерДоговора = Заявки.НомерЗаявки
	FROM #t_ДругиеЗаявки AS Заявки
		INNER JOIN Stg._1cCMR.Справочник_Договоры AS Договоры
			ON Договоры.Код = Заявки.НомерЗаявки

	DROP TABLE IF EXISTS #t_СтатусыДругихДоговоров
	CREATE TABLE #t_СтатусыДругихДоговоров
	(
		GuidМастерЗаявки nvarchar(36),
		GuidЗаявки nvarchar(36),
		СсылкаДоговора binary(16), 
		ДатаСтатуса datetime2(0),
		ДатаОкончанияСтатуса datetime2(0),
		СтатусДоговора nvarchar(150)
	)

	INSERT #t_СтатусыДругихДоговоров
	(
	    GuidМастерЗаявки,
	    GuidЗаявки,
	    СсылкаДоговора,
	    ДатаСтатуса,
	    ДатаОкончанияСтатуса,
	    СтатусДоговора
	)
	SELECT 
	    Договора.GuidМастерЗаявки,
	    Договора.GuidЗаявки,
	    Договора.СсылкаДоговора,
	    ДатаСтатуса = dateadd(YEAR, -2000, СтатусыДоговоров.Период),
		ДатаОкончанияСтатуса = lead(dateadd(YEAR, -2000, СтатусыДоговоров.Период), 1, cast('3000-01-01' AS datetime2(0)))
			OVER(PARTITION BY Договора.GuidМастерЗаявки, Договора.СсылкаДоговора ORDER BY СтатусыДоговоров.Период),
	    СтатусДоговора = Статусы.Наименование
	FROM #t_ДругиеДоговора AS Договора
		INNER JOIN Stg._1cCMR.РегистрСведений_СтатусыДоговоров AS СтатусыДоговоров
			ON СтатусыДоговоров.Договор = Договора.СсылкаДоговора
		INNER JOIN Stg._1cCMR.Справочник_СтатусыДоговоров AS Статусы
			ON Статусы.Ссылка = СтатусыДоговоров.Статус

	UPDATE D
	SET D.СтатусДоговора_НаДатуОпределенияВидаЗайма = S.СтатусДоговора,
		D.IsActive = iif(S.СтатусДоговора IN 
			('Действует', 'Просрочен', 'Проблемный', 'Платеж опаздывает', 'Legal', 'Решение суда', 'Внебаланс') 
			, 1, 0),
		D.IsEnded = iif(S.СтатусДоговора IN ('Погашен', 'Продан'), 1, 0)
	FROM #t_Заявки2 AS R
		INNER JOIN #t_ДругиеДоговора AS D
			ON D.GuidМастерЗаявки = R.GuidЗаявки
		INNER JOIN #t_СтатусыДругихДоговоров AS S
			ON S.GuidМастерЗаявки = D.GuidМастерЗаявки
			AND S.GuidЗаявки = D.GuidЗаявки
			AND S.ДатаСтатуса <= R.ДатаОпределенияВидаЗайма AND R.ДатаОпределенияВидаЗайма < S.ДатаОкончанияСтатуса

	CREATE INDEX ix1 ON #t_ДругиеДоговора(GuidМастерЗаявки) INCLUDE(IsActive, IsEnded)


	select distinct
		СсылкаЗаявки = T.СсылкаЗаявки,
		GuidЗаявки = T.GuidЗаявки,

		--- есть активные займы то это докредитование, 
		--- есть закрытые займы то это повторный, 
		--- иначе - первичный.
		ВидЗаймаВРамкахПродукта = cast(
			CASE
				WHEN A.GuidЗаявки IS NOT NULL THEN 'Докредитование'
				WHEN E.GuidЗаявки IS NOT NULL THEN 'Повторный'
				ELSE 'Первичный'
			END 
			AS varchar(30)),

		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
		--ВерсияДанных = cast(LK_Заявка.RowVersion AS binary(8))
	into #t_ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта
	FROM #t_Заявки2 AS T
		--IsActive = 1
		LEFT JOIN (
			SELECT DISTINCT	R.GuidЗаявки
			FROM #t_Заявки2 AS R
				INNER JOIN #t_ДругиеДоговора AS D
					ON D.GuidМастерЗаявки = R.GuidЗаявки 
					AND D.IsActive = 1
		) AS A
		ON A.GuidЗаявки = T.GuidЗаявки

		--IsEnded = 1
		LEFT JOIN (
			SELECT DISTINCT	R.GuidЗаявки
			FROM #t_Заявки2 AS R
				INNER JOIN #t_ДругиеДоговора AS D
					ON D.GuidМастерЗаявки = R.GuidЗаявки 
					AND D.IsEnded = 1
		) AS E
		ON E.GuidЗаявки = T.GuidЗаявки




	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Заявки
		SELECT * INTO ##t_Заявки FROM #t_Заявки

		DROP TABLE IF EXISTS ##t_Заявки2
		SELECT * INTO ##t_Заявки2 FROM #t_Заявки2

		DROP TABLE IF EXISTS ##t_ДругиеЗаявки
		SELECT * INTO ##t_ДругиеЗаявки FROM #t_ДругиеЗаявки

		DROP TABLE IF EXISTS ##t_ДругиеДоговора
		SELECT * INTO ##t_ДругиеДоговора FROM #t_ДругиеДоговора

		DROP TABLE IF EXISTS ##t_СтатусыДругихДоговоров
		SELECT * INTO ##t_СтатусыДругихДоговоров FROM #t_СтатусыДругихДоговоров

		DROP TABLE IF EXISTS ##t_ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта
		SELECT * INTO ##t_ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта FROM #t_ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта
	END


	if OBJECT_ID('sat.ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта') is null
	begin
		select top(0)
			СсылкаЗаявки,
            GuidЗаявки,
			ВидЗаймаВРамкахПродукта,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		into sat.ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта
		from #t_ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта

		alter table sat.ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта
			alter column GuidЗаявки uniqueidentifier not null

		ALTER TABLE sat.ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта
			ADD CONSTRAINT PK_ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта PRIMARY KEY CLUSTERED (GuidЗаявки)
	end
	
	--begin tran

		merge sat.ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта t
		using #t_ЗаявкаНаЗаймПодПТС_ВидЗаймаВРамкахПродукта s
			on t.GuidЗаявки = s.GuidЗаявки
		when not matched then insert
		(
			СсылкаЗаявки,
            GuidЗаявки,
			ВидЗаймаВРамкахПродукта,
            created_at,
            updated_at,
            spFillName
            --ВерсияДанных
		) values
		(
			s.СсылкаЗаявки,
            s.GuidЗаявки,
			s.ВидЗаймаВРамкахПродукта,
            s.created_at,
            s.updated_at,
            s.spFillName
			--s.ВерсияДанных
		)
		when matched 
			and isnull(t.ВидЗаймаВРамкахПродукта, '**') <> isnull(s.ВидЗаймаВРамкахПродукта, '*')
		then update SET
			t.ВидЗаймаВРамкахПродукта = s.ВидЗаймаВРамкахПродукта,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
			--t.ВерсияДанных = s.ВерсияДанных
			;
	--commit tran

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
