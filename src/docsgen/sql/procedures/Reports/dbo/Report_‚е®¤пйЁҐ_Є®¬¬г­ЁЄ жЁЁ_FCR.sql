--exec dbo.Report_Входящие_коммуникации_FCR @dateBegin='2024-06-01', @dateEnd ='2024-06-01'
CREATE   PROC dbo.Report_Входящие_коммуникации_FCR
	@dateBegin date=null,
	@dateEnd date=null,
	@FIO_Operator varchar(8000) = NULL,
	@ComminicationTheme varchar(8000) = NULL,
	@CreditProduct varchar(8000) = NULL, --КредитныйПродукт
	@Page varchar(100) = 'Detail',
	@isDebug int = 0
as
begin
	SELECT @isDebug = isnull(@isDebug, 0)

	
	DROP TABLE IF EXISTS #t_FIO_Operator
	CREATE TABLE #t_FIO_Operator(FIO_Operator varchar(100))

	IF nullif(@FIO_Operator,'') IS NOT NULL
	BEGIN
		INSERT #t_FIO_Operator(FIO_Operator)
		SELECT S.value
		FROM string_split(@FIO_Operator, ',') AS S
	END


	DROP TABLE IF EXISTS #t_ComminicationTheme
	CREATE TABLE #t_ComminicationTheme(ComminicationTheme varchar(100))

	IF nullif(@ComminicationTheme,'') IS NOT NULL
	BEGIN
		INSERT #t_ComminicationTheme(ComminicationTheme)
		SELECT S.value
		FROM string_split(@ComminicationTheme, ',') AS S
	END


	DROP TABLE IF EXISTS #t_CreditProduct
	CREATE TABLE #t_CreditProduct(CreditProduct varchar(100))

	IF nullif(@CreditProduct,'') IS NOT NULL
	BEGIN
		INSERT #t_CreditProduct(CreditProduct)
		SELECT S.value
		FROM string_split(@CreditProduct, ',') AS S
	END


	DROP TABLE IF EXISTS #t_Входящие_коммуникации

	select 
		master_id = cast(NULL AS int),
		isFCR = cast(0 AS int), --isFCR - обращение решено в ходе первого звонка
		row_id = row_number() OVER(ORDER BY convert(datetime, 
					concat(
						convert(varchar(10), D.ДатаВзаимодействия, 120), ' ', convert(varchar(8), D.ВремяВзаимодействия)
					),
					120
				)
			),
		--Уникальное обращение выявляется из связки 
		--"ФИО клиента" 
		--И "номер телефона" 
		--И "Тип обращения" 
		--И "Детали обращения" 
		--И "Поддетали обращения".
		com_id = 
			cast(
				hashbytes(
					'SHA2_256',
					concat(D.ФИО_клиента, '|', 
						D.НомерТелефона, '|', 
						D.ТипОбращения, '|', 
						D.ДеталиОбращения, '|', 
						D.ПоддеталиОбращения)
				) AS uniqueidentifier
			),
		ДатаВремяВзаимодействия = convert(datetime, 
			concat(
				convert(varchar(10), D.ДатаВзаимодействия, 120), ' ', convert(varchar(8), D.ВремяВзаимодействия)
			),
			120
		),
		isDuplicate = cast(0 AS int),
		group_id = cast(NULL AS int),
		D.* 
	INTO #t_Входящие_коммуникации
	from dbo.dm_Все_коммуникации_На_основе_отчета_из_crm AS D
	where 1=1
		AND D.ДатаВзаимодействия between dateadd(DAY, -1, @dateBegin) and dateadd(DAY, 1, @dateEnd)
		AND D.Направление = 'Входящее'
		AND D.Session_id IS NOT NULL -- тел. звонок
		AND D.Результат IS NOT NULL
	--order by ДатаВзаимодействия , ВремяВзаимодействия

	CREATE INDEX ix_1
	ON #t_Входящие_коммуникации(com_id, ДатаВремяВзаимодействия)
	INCLUDE (row_id)

	--24*60*60 = 86400 - секунд в 24-х часах
	UPDATE C
	SET isDuplicate = 1
	FROM #t_Входящие_коммуникации AS C
	WHERE EXISTS(
		--существует предыдущая коммуникация с тем же com_id, произошедшая менее чем за 24 часа до текущей
		SELECT TOP(1) 1
		FROM #t_Входящие_коммуникации AS P
		WHERE C.com_id = P.com_id
			AND P.ДатаВремяВзаимодействия <= C.ДатаВремяВзаимодействия
			AND P.ДатаВремяВзаимодействия >= dateadd(SECOND, -86400, C.ДатаВремяВзаимодействия)
			AND P.row_id <> C.row_id
		)

	-- group_id для записей с isDuplicate = 0
	UPDATE T
	SET T.group_id = A.rn
	FROM #t_Входящие_коммуникации AS T
		INNER JOIN (
			SELECT 
				C.row_id,
				rn = row_number() OVER(PARTITION BY C.com_id ORDER BY C.ДатаВремяВзаимодействия)
			FROM #t_Входящие_коммуникации AS C
			WHERE C.isDuplicate = 0
		) AS A
		ON A.row_id = T.row_id

	-- group_id для записей с isDuplicate = 1
	UPDATE T
	SET T.group_id = A.rn1 - A.rn2
	FROM #t_Входящие_коммуникации AS T
		INNER JOIN (
			SELECT 
				C.row_id,
				rn1 = row_number() OVER(PARTITION BY C.com_id ORDER BY C.ДатаВремяВзаимодействия),
				rn2 = row_number() OVER(PARTITION BY C.com_id, C.isDuplicate ORDER BY C.ДатаВремяВзаимодействия)
			FROM #t_Входящие_коммуникации AS C
		) AS A
		ON A.row_id = T.row_id
		AND T.isDuplicate = 1

	--master_id
	UPDATE T
	SET T.master_id = A.row_id
	FROM #t_Входящие_коммуникации AS T
		INNER JOIN (
			SELECT 
				C.row_id,
				C.com_id,
				C.group_id
			FROM #t_Входящие_коммуникации AS C
			WHERE C.isDuplicate = 0
		) AS A
		ON A.com_id = T.com_id
		AND A.group_id = T.group_id

	CREATE INDEX ix_2
	ON #t_Входящие_коммуникации(master_id, isDuplicate)

	--isFCR - обращение решено в ходе первого звонка
	UPDATE C
	SET C.isFCR = 1
	FROM #t_Входящие_коммуникации AS C
	WHERE C.isDuplicate = 0
		AND NOT EXISTS(
			SELECT TOP(1) 1
			FROM #t_Входящие_коммуникации AS T
			WHERE T.master_id = C.master_id
				AND T.isDuplicate = 1
		)



	DROP TABLE IF EXISTS #t_Входящие_коммуникации_за_период

	SELECT 
		C.master_id,
		C.isFCR,
		C.row_id,
		C.com_id,
		C.ДатаВремяВзаимодействия,
		C.isDuplicate,
		C.group_id,
		C.ДатаВзаимодействия,
		C.ВремяВзаимодействия,
		C.ФИО_оператора,
		C.НомерТелефонаОператора,
		C.ФИО_клиента,
		C.НомерТелефона,
		C.ДлительностьЗвонка,
		C.Session_id,
		КредитныйПродукт = isnull(nullif(trim(C.КредитныйПродукт), ''), '<НЕ УКАЗАН>'),
		C.НомерЗаявки,
		--
		ПодразделениеСотрудника = isnull(nullif(trim(C.ПодразделениеСотрудника), ''), '<НЕ УКАЗАНО>'),
		ТипОбращения = isnull(nullif(trim(C.ТипОбращения), ''), '<НЕ УКАЗАНО>'),
		ДеталиОбращения = isnull(nullif(trim(C.ДеталиОбращения), ''), '<НЕ УКАЗАНО>'),
		ПоддеталиОбращения = isnull(nullif(trim(C.ПоддеталиОбращения), ''), '<НЕ УКАЗАНО>')
	INTO #t_Входящие_коммуникации_за_период
	FROM #t_Входящие_коммуникации AS C
	WHERE 1=1
		AND C.ДатаВзаимодействия between @dateBegin and @dateEnd
		AND (@FIO_Operator IS NULL
			OR EXISTS(
				SELECT TOP(1) 1 
				FROM #t_FIO_Operator AS T 
				WHERE T.FIO_Operator = isnull(C.ФИО_оператора, '<НЕ УКАЗАН>')
			)
		)
		AND (
			@ComminicationTheme IS NULL
			OR EXISTS(
				SELECT TOP(1) 1 
				FROM #t_ComminicationTheme AS T
				WHERE T.ComminicationTheme = isnull(C.ТипОбращения, '<НЕ УКАЗАНО>')
				)
		)
		AND (
			@CreditProduct IS NULL
			OR EXISTS(
				SELECT TOP(1) 1 
				FROM #t_CreditProduct AS T
				WHERE T.CreditProduct = isnull(C.КредитныйПродукт, '<НЕ УКАЗАН>')
				)
		)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Входящие_коммуникации
		SELECT * INTO ##t_Входящие_коммуникации FROM #t_Входящие_коммуникации	

		DROP TABLE IF EXISTS ##t_Входящие_коммуникации_за_период
		SELECT * INTO ##t_Входящие_коммуникации_за_период FROM #t_Входящие_коммуникации_за_период
	END


	IF @Page = 'Detail' BEGIN
		SELECT 
			T.master_id,
			T.isFCR,
			T.row_id,
			T.com_id,
			T.ДатаВремяВзаимодействия,
			T.isDuplicate,
			T.group_id,
			T.ДатаВзаимодействия,
			T.ВремяВзаимодействия,
			T.ФИО_оператора,
			T.НомерТелефонаОператора,
			T.ФИО_клиента,
			T.НомерТелефона,
			T.ДлительностьЗвонка,
			T.Session_id,
			T.КредитныйПродукт,
			T.НомерЗаявки,
			T.ПодразделениеСотрудника,
			T.ТипОбращения,
			T.ДеталиОбращения,
			T.ПоддеталиОбращения 
		FROM #t_Входящие_коммуникации_за_период AS T

		RETURN 0
	END

	/*
	- 	ПодразделениеСотрудника (0 уровень)
	- 	Тип обращения (1 уровень)
	- 	Детали обращения (2 уровень)
	- 	Поддетали обращения (3 уровень)

	--ТипОбращения	ДеталиОбращения	ПоддеталиОбращения

	FCR – исчисляется в разрезе поддеталей обращения,
	*/

	--FCR – исчисляется в разрезе поддеталей обращения,
	DROP TABLE IF EXISTS #t_ПоддеталиОбращения
	--DROP TABLE IF EXISTS #t_ДеталиОбращения
	--DROP TABLE IF EXISTS #t_ТипОбращения
	--DROP TABLE IF EXISTS #t_ПодразделениеСотрудника
	DROP TABLE IF EXISTS #t_Report_FCR

	IF @Page = 'Statistics' BEGIN

		SELECT 
			B.ПодразделениеСотрудника,
			B.ТипОбращения,
			B.ДеталиОбращения,
			B.ПоддеталиОбращения,
			B.count_FCR,
			B.count_com,
			FCR = iif(B.count_com <> 0, 1.0 * B.count_FCR / B.count_com, 0.0)
		INTO #t_ПоддеталиОбращения
		FROM (
			SELECT 
				A.ПодразделениеСотрудника,
				A.ТипОбращения,
				A.ДеталиОбращения,
				A.ПоддеталиОбращения,
				count_FCR = sum(A.isFCR), -- кол-во обращений, решенных в ходе первого звонка
				count_com = count(DISTINCT A.master_id) -- кол-во уникальных обращений
			FROM #t_Входящие_коммуникации_за_период AS A
			GROUP BY
				A.ПодразделениеСотрудника,
				A.ТипОбращения,
				A.ДеталиОбращения,
				A.ПоддеталиОбращения
			) AS B

		/*
		--для уровня 2 (детали обращения)
		SELECT 
			A.ПодразделениеСотрудника,
			A.ТипОбращения,
			A.ДеталиОбращения,
			count_FCR = sum(A.count_FCR), -- кол-во обращений, решенных в ходе первого звонка
			count_com = sum(A.count_com), -- кол-во уникальных обращений
			--FCR = avg(A.FCR)
			FCR = iif(sum(A.count_com) <> 0, 1.0 * sum(A.count_FCR) / sum(A.count_com), 0.0)
		INTO #t_ДеталиОбращения
		FROM #t_ПоддеталиОбращения AS A
		GROUP BY
			A.ПодразделениеСотрудника,
			A.ТипОбращения,
			A.ДеталиОбращения

		--для уровня 1 (тип обращения)
		SELECT 
			A.ПодразделениеСотрудника,
			A.ТипОбращения,
			count_FCR = sum(A.count_FCR), -- кол-во обращений, решенных в ходе первого звонка
			count_com = sum(A.count_com), -- кол-во уникальных обращений
			--FCR = avg(A.FCR)
			FCR = iif(sum(A.count_com) <> 0, 1.0 * sum(A.count_FCR) / sum(A.count_com), 0.0)
		INTO #t_ТипОбращения
		FROM #t_ДеталиОбращения AS A
		GROUP BY
			A.ПодразделениеСотрудника,
			A.ТипОбращения

		--для уровня 0 берется FCR по всем типам обращения, выбранных в фильтре, зарегистрированных на линии
		SELECT 
			A.ПодразделениеСотрудника,
			count_FCR = sum(A.count_FCR), -- кол-во обращений, решенных в ходе первого звонка
			count_com = sum(A.count_com), -- кол-во уникальных обращений
			--FCR = avg(A.FCR)
			FCR = iif(sum(A.count_com) <> 0, 1.0 * sum(A.count_FCR) / sum(A.count_com), 0.0)
		INTO #t_ПодразделениеСотрудника
		FROM #t_ТипОбращения AS A
		GROUP BY
			A.ПодразделениеСотрудника
		*/

		-------------

		SELECT 
			group_id = 0,
			row_id = newid(),
			rn = cast(0 AS int),
			A.ПодразделениеСотрудника,
			A.ТипОбращения,
			A.ДеталиОбращения,
			A.ПоддеталиОбращения,
			A.count_FCR,
			A.count_com,
			A.FCR 
		INTO #t_Report_FCR
		FROM #t_ПоддеталиОбращения AS A

		/*
		UNION ALL
		SELECT 
			group_id = 1,
			row_id = newid(),
			rn = cast(0 AS int),
			B.ПодразделениеСотрудника,
			B.ТипОбращения,
			B.ДеталиОбращения,
			ПоддеталиОбращения = NULL,
			B.count_FCR,
			B.count_com,
			B.FCR
		FROM #t_ДеталиОбращения AS B

		UNION ALL
		SELECT 
			group_id = 2,
			row_id = newid(),
			rn = cast(0 AS int),
			T.ПодразделениеСотрудника,
			T.ТипОбращения,
			ДеталиОбращения = NULL,
			ПоддеталиОбращения = NULL,
			T.count_FCR,
			T.count_com,
			T.FCR
		FROM #t_ТипОбращения AS T

		UNION ALL
		SELECT 
			group_id = 3,
			row_id = newid(),
			rn = cast(0 AS int),
			T.ПодразделениеСотрудника,
			ТипОбращения = NULL,
			ДеталиОбращения = NULL,
			ПоддеталиОбращения = NULL,
			T.count_FCR,
			T.count_com,
			T.FCR
		FROM #t_ПодразделениеСотрудника AS T
		*/

		UPDATE A
		SET A.rn = B.rn
		FROM #t_Report_FCR AS A
			INNER JOIN (
				SELECT
					R.row_id,
					rn = row_number() OVER(ORDER BY
						isnull(R.ПодразделениеСотрудника, 'ЯЯЯ'),
						isnull(R.ТипОбращения, 'ЯЯЯ'),
						isnull(R.ДеталиОбращения, 'ЯЯЯ'),
						isnull(R.ПоддеталиОбращения, 'ЯЯЯ')
					),
					R.ПодразделениеСотрудника,
					R.ТипОбращения,
					R.ДеталиОбращения,
					R.ПоддеталиОбращения,
					R.count_FCR,
					R.count_com,
					R.FCR	
				FROM #t_Report_FCR AS R
			) AS B
			ON B.row_id = A.row_id
		----------------------------------------------
		/*
		UPDATE R
		SET ПоддеталиОбращения = 'ИТОГО'
		FROM #t_Report_FCR AS R
		WHERE R.ПоддеталиОбращения IS NULL
			AND R.ДеталиОбращения IS NOT NULL

		UPDATE R
		SET ДеталиОбращения = 'ИТОГО'
		FROM #t_Report_FCR AS R
		WHERE R.ДеталиОбращения IS NULL
			AND R.ТипОбращения IS NOT NULL

		UPDATE R
		SET ТипОбращения = 'ИТОГО'
		FROM #t_Report_FCR AS R
		WHERE R.ТипОбращения IS NULL
			AND R.ПодразделениеСотрудника IS NOT NULL
		*/
		----------------------------------------------
		SELECT 
			--R.row_id,
			R.group_id,
			R.rn,
			R.ПодразделениеСотрудника,
			R.ТипОбращения,
			R.ДеталиОбращения,
			R.ПоддеталиОбращения,
			R.count_FCR,
			R.count_com,
			R.FCR
		FROM #t_Report_FCR AS R
		WHERE 1=1
			AND R.group_id = 0
		ORDER BY R.rn

		--RETURN 0
	END
	--//IF @Page = 'Statistics'

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ПоддеталиОбращения
		SELECT * INTO ##t_ПоддеталиОбращения FROM #t_ПоддеталиОбращения

		--DROP TABLE IF EXISTS ##t_ДеталиОбращения
		--SELECT * INTO ##t_ДеталиОбращения FROM #t_ДеталиОбращения
		
		--DROP TABLE IF EXISTS ##t_ТипОбращения
		--SELECT * INTO ##t_ТипОбращения FROM #t_ТипОбращения
	
		--DROP TABLE IF EXISTS ##t_ПодразделениеСотрудника
		--SELECT * INTO ##t_ПодразделениеСотрудника FROM #t_ПодразделениеСотрудника

		DROP TABLE IF EXISTS ##t_Report_FCR
		SELECT * INTO ##t_Report_FCR FROM #t_Report_FCR
	END

END