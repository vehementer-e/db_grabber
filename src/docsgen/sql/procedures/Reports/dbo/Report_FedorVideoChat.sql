/*
exec dbo.Report_FedorVideoChat 'VK.Detail', '2023-08-01', '2023-08-01'
exec dbo.Report_FedorVideoChat 'VTC.Detail', '2023-08-01', '2023-08-01'
exec dbo.Report_FedorVideoChat 'Result.Detail', '2023-08-01', '2023-08-01'
exec dbo.Report_FedorVideoChat 'Result.Statistics', '2023-08-01', '2023-08-01'
*/
CREATE   PROC dbo.Report_FedorVideoChat
--declare
	@Page nvarchar(100) = 'VK.Detail'
	,@dtFrom date = null
	,@dtTo date =  null
	--,@ProcessGUID varchar(36) = NULL -- guid процесса
	--,@isDebug int = 0
AS
BEGIN

SET NOCOUNT ON;

BEGIN TRY
	DECLARE @ProcessGUID varchar(36) = NULL -- guid процесса
	DECLARE @EventDateTime datetime
	DECLARE @delay varchar(12)
	DECLARE @eventType nvarchar(1024), @eventName nvarchar(1024)
	DECLARE @description nvarchar(1024), @message nvarchar(1024), @error_number int
	DECLARE @isFill_All_Tables bit = 0
	declare @dt_from date, @dt_to date
	DECLARE @total_requests int
	DECLARE @calendar table (Дата date)

	--SELECT @isDebug = isnull(@isDebug, 0)

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @eventType = 'info', @eventName = 'dbo.Report_FedorVideoChat'

	if @dtFrom is not null
		set @dt_from=@dtFrom
	else 
		SET @dt_from=format(getdate(),'yyyyMM01')

	if @dtTo is not null
		set @dt_to=dateadd(day,1,@dtTo)
	else 
		SET @dt_to=dateadd(day,1,cast(getdate() as date))


	drop table if exists #t_dm_FedorVideoChatRequests

	SELECT TOP(0) R.*
	INTO #t_dm_FedorVideoChatRequests
	FROM dbo.dm_FedorVideoChatRequests AS R

	INSERT #t_dm_FedorVideoChatRequests
	SELECT R.*
	FROM dbo.dm_FedorVideoChatRequests AS R
	WHERE 1=1
		AND R.ДатаВремяЗвонка >= @dt_from
		AND R.ДатаВремяЗвонка < @dt_to

		AND R.РезультатЗвонка IS NOT NULL
		--не включать в отчет заявки, результаты которых "Проверка не проводилась (системная)", 
		AND R.РезультатЗвонка NOT IN ('Проверка не проводилась (системная)')
		--не включать тестовые заявки
		AND R.ФИО_Верификатора NOT IN (
			SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
			FROM Stg._fedor.core_user AS U
			WHERE U.IsQAUser = 1
		)


	--Детализация ВК
	IF @Page = 'VK.Detail'
	BEGIN
		SELECT 
			[Дата] = R.ДатаВремяЗвонка,
			[Номер заявки] = R.НомерЗаявки,
			[ФИО клиента] = R.ФИО_Клиента,
			[ФИО верификатора] = R.ФИО_Верификатора,
			[Итог проверки] = R.РезультатЗвонка,
			[Комментарий из чек-листа] = R.КомментарийИзЧекЛиста
		FROM #t_dm_FedorVideoChatRequests AS R
		WHERE R.Этап = 'Верификация клиента'
		ORDER BY R.ДатаВремяЗвонка, R.НомерЗаявки

		RETURN 0
	END

	--Детализация ВТС
	IF @Page = 'VTC.Detail'
	BEGIN
		SELECT 
			[Дата] = R.ДатаВремяЗвонка,
			[Номер заявки] = R.НомерЗаявки,
			[ФИО клиента] = R.ФИО_Клиента,
			[ФИО верификатора] = R.ФИО_Верификатора,
			[Итог проверки] = R.РезультатЗвонка,
			[Комментарий из чек-листа] = R.КомментарийИзЧекЛиста
		FROM #t_dm_FedorVideoChatRequests AS R
		WHERE R.Этап = 'Верификация ТС'
		ORDER BY R.ДатаВремяЗвонка, R.НомерЗаявки

		RETURN 0
	END

	DROP TABLE IF EXISTS #t_Result_VK
	CREATE TABLE #t_Result_VK(
		result_name nvarchar(255), 
		result_weight numeric(5,1),
		sort_order int
	)

	DROP TABLE IF EXISTS #t_Result_VTC
	CREATE TABLE #t_Result_VTC(result_name nvarchar(255), result_weight numeric(5,1))

	DROP TABLE IF EXISTS #t_Result_Detail
	SELECT TOP(0)
		[Дата] = R.ДатаВремяЗвонка,
		[Номер заявки] = R.НомерЗаявки,
		[ФИО клиента] = R.ФИО_Клиента,
		[ФИО верификатора] = R.ФИО_Верификатора,
		R.Этап,
		[Итог проверки] = R.РезультатЗвонка,
		[Комментарий из чек-листа] = R.КомментарийИзЧекЛиста
	INTO #t_Result_Detail
	FROM #t_dm_FedorVideoChatRequests AS R


	--Детализация результат по заявке, Отчет по ВЧ
	IF @Page IN ('Result.Detail', 'Result.Statistics', 'Result.Monthly.Statistics')
	BEGIN
		/*
		Для того, чтобы вывести итоговый результат по заявке, мы разработали матрицу с учетом веса каждого результата:
		ВК	 	ВТС	 
		1. Все фото корректны, ВЧ не требуется	0	1. Все фото корректны, ВЧ не требуется	0,1
		2. Успешно	1	2. Успешно	1
		3. Клиент не отвечает на звонки по ВЧ	0,4	3. Клиент не отвечает на звонки по ВЧ	0,5
		4. Проблема с интернетом	0,4	4. Проблема с интернетом	0,5
		5. Клиент не рядом с авто	0,4	5. Клиент не рядом с авто	0,5
		6. Клиент отказался (негатив)	0,4	6. Клиент отказался (негатив)	0,5
		7. Клиент отказался (сделает самостоятельно)	0,4	7. Клиент отказался (сделает самостоятельно)	0,5
		8. Не удалось сделать фото	0,4	8. Не удалось сделать фото	0,5
		9. Проблемы с телефоном (разряжен; садится; не поддерживает видео)	0,4	9. Проблемы с телефоном (разряжен; садится; не поддерживает видео)	0,5
		10. Фото сделано, но низкого качества	0,4	10. Фото сделано, но низкого качества	0,5
		11. Тех. проблема с сервисом	0,4	11. Тех. проблема с сервисом	0,5
		12. Нет всех фото, сделает самостоятельно	0	 	 
		*/
		INSERT INTO #t_Result_VK(result_name, result_weight, sort_order)
		VALUES
		--( N'Проверка не проводилась (системная)', 0, 0), 
		( N'Все фото корректны, ВЧ не требуется', 0, 1), 
		( N'Успешно', 1, 2), 
		( N'Клиент не отвечает на звонки по ВЧ', 0.4, 3), 
		( N'Проблема с интернетом', 0.4, 4), 
		( N'Клиент не рядом с авто', 0.4, 5), 
		( N'Клиент отказался (негатив)', 0.4, 6), 
		( N'Клиент отказался (сделает самостоятельно)', 0.4, 7), 
		( N'Не удалось сделать фото', 0.4, 8), 
		( N'Проблемы с телефоном (разряжен; садится; не поддерживает видео)', 0.4, 9), 
		( N'Фото сделано, но низкого качества', 0.4, 10), 
		( N'Тех. проблема с сервисом', 0.4, 11), 
		( N'Нет всех фото, сделает самостоятельно', 0, 12)

		--SELECT * FROM #t_Result_VK

		INSERT #t_Result_VTC(result_name, result_weight)
		VALUES
		--( N'Проверка не проводилась (системная)', 0), 
		( N'Все фото корректны, ВЧ не требуется', 0.1), 
		( N'Фото клиента соответствует требованиям', 0), 
		( N'Не качественные фото/отсутствуют фото', 0), 
		( N'Успешно', 1), 
		( N'Клиент не отвечает на звонки по ВЧ', 0.5), 
		( N'Фото в паспорте не соответствует фото клиента/фото клиента на фоне авто', 0), 
		( N'Инвалидность (нерабочая группа)', 0), 
		( N'Проблема с интернетом', 0.5), 
		( N'Клиент "Олень" (приведен 3-ми лицами)', 0), 
		( N'Клиент не рядом с авто', 0.5), 
		( N'Визуальный андеррайтинг клиента.  Клиент не подходит по статусу ТС (дорогое авто и неопрятный человек, алкоголик итд)', 0), 
		( N'Клиент отказался (негатив)', 0.5), 
		( N'Клиент отказался (сделает самостоятельно)', 0.5), 
		( N'Фотошоп фото клиента', 0), 
		( N'Не удалось сделать фото', 0.5), 
		( N'Типаж БОМЖ, ЦЫГАНЕ, НАРКОМАН', 0), 
		( N'КОБАЛЬТ - совпадение с базой мошенников', 0), 
		( N'Проблемы с телефоном (разряжен; садится; не поддерживает видео)', 0.5), 
		( N'Фото сделано, но низкого качества', 0.5), 
		( N'Тех. проблема с сервисом', 0.5), 
		( N'Проверка не проводилась', 0)
		--SELECT * FROM #t_Result_VTC

		INSERT #t_Result_Detail
		(
		    Дата,
		    [Номер заявки],
		    [ФИО клиента],
		    [ФИО верификатора],
		    Этап,
		    [Итог проверки],
		    [Комментарий из чек-листа]
		)
		SELECT 
			--VK_result_weight = isnull(VK.result_weight, 0.0),
			--VTC_result_weight = isnull(VTC.result_weight, 0.0),
			Дата = 
				iif(
					isnull(VK.result_weight, 0.0) > isnull(VTC.result_weight, 0.0), 
					isnull(VK.Дата, VTC.Дата),
					isnull(VTC.Дата, VK.Дата)
				),
			[Номер заявки] = isnull(VK.[Номер заявки], VTC.[Номер заявки]), 
			[ФИО клиента] = isnull(VK.[ФИО клиента], VTC.[ФИО клиента]), 
			[ФИО верификатора] = 
				iif(
					isnull(VK.result_weight, 0.0) > isnull(VTC.result_weight, 0.0), 
					isnull(VK.[ФИО верификатора], VTC.[ФИО верификатора]),
					isnull(VTC.[ФИО верификатора], VK.[ФИО верификатора])
				), 
			Этап = 
				iif(
					isnull(VK.result_weight, 0.0) > isnull(VTC.result_weight, 0.0), 
					isnull(VK.Этап, VTC.Этап),
					isnull(VTC.Этап, VK.Этап)
				),
			[Итог проверки] = 
				iif(
					isnull(VK.result_weight, 0.0) > isnull(VTC.result_weight, 0.0), 
					isnull(VK.[Итог проверки], VTC.[Итог проверки]),
					isnull(VTC.[Итог проверки], VK.[Итог проверки])
				), 
			[Комментарий из чек-листа] = 
				iif(
					isnull(VK.result_weight, 0.0) > isnull(VTC.result_weight, 0.0), 
					isnull(VK.[Комментарий из чек-листа], VTC.[Комментарий из чек-листа]),
					isnull(VTC.[Комментарий из чек-листа], VK.[Комментарий из чек-листа])
				)
		FROM (
			SELECT 
				[Дата] = R.ДатаВремяЗвонка,
				[Номер заявки] = R.НомерЗаявки,
				[ФИО клиента] = R.ФИО_Клиента,
				[ФИО верификатора] = R.ФИО_Верификатора,
				R.Этап,
				[Итог проверки] = R.РезультатЗвонка,
				result_weight = isnull(A.result_weight, 0),
				[Комментарий из чек-листа] = R.КомментарийИзЧекЛиста
			FROM #t_dm_FedorVideoChatRequests AS R
				LEFT JOIN #t_Result_VK AS A
					ON R.РезультатЗвонка = A.result_name
			WHERE R.Этап = 'Верификация клиента'
				--test
				--AND R.НомерЗаявки = '23072701082931'
			) AS VK
			FULL OUTER JOIN
			(
			SELECT 
				[Дата] = R.ДатаВремяЗвонка,
				[Номер заявки] = R.НомерЗаявки,
				[ФИО клиента] = R.ФИО_Клиента,
				[ФИО верификатора] = R.ФИО_Верификатора,
				R.Этап,
				[Итог проверки] = R.РезультатЗвонка,
				result_weight = isnull(A.result_weight, 0),
				[Комментарий из чек-листа] = R.КомментарийИзЧекЛиста
			FROM #t_dm_FedorVideoChatRequests AS R
				LEFT JOIN #t_Result_VTC AS A
					ON R.РезультатЗвонка = A.result_name
			WHERE R.Этап = 'Верификация ТС'
				--test
				--AND R.НомерЗаявки = '23072701082931'
			) AS VTC
			ON VK.[Номер заявки] = VTC.[Номер заявки]

		--SELECT * 
		--FROM #t_dm_FedorVideoChatRequests AS R
		--WHERE 1=1
		--	AND R.НомерЗаявки = '23072701082931'

		--Детализация результат по заявке
		IF @Page IN ('Result.Detail')
		BEGIN
			SELECT 
				R.Дата,
				R.[Номер заявки],
				R.[ФИО клиента],
				R.[ФИО верификатора],
				R.Этап,
				R.[Итог проверки],
				R.[Комментарий из чек-листа] 
			FROM #t_Result_Detail AS R
			ORDER BY R.Дата

			RETURN 0
		END

		--Отчет по ВЧ
		IF @Page IN ('Result.Statistics')
		BEGIN
			SELECT @total_requests = count(*) FROM #t_Result_Detail AS R

			SELECT 
				sort_order = isnull(S.sort_order, 999),
				R.[Итог проверки],
				[Кол-во] = count(*),
				[Проценты] = cast(iif(@total_requests > 0, 100.0 * count(*) / @total_requests, 0) AS numeric(10,1))
			FROM #t_Result_Detail AS R
				LEFT JOIN #t_Result_VK AS S
					ON S.result_name = R.[Итог проверки]
			GROUP BY R.[Итог проверки], isnull(S.sort_order, 999)
			UNION 
			SELECT				
				sort_order = 1000,
				[Итог проверки] = 'Итого:',
				[Кол-во] = @total_requests,
				[Проценты] = cast(100.0 AS numeric(10,1))
			ORDER BY sort_order

			RETURN 0
		END

		--Отчет по ВЧ
		IF @Page IN ('Result.Monthly.Statistics')
		BEGIN
			--calendar по месяцам
			;WITH СL AS (
				SELECT Дата = cast(format(@dt_from, 'yyyyMM01') AS date)
				UNION ALL
				SELECT Дата = dateadd(MONTH, 1, СL.Дата)
				FROM СL
				WHERE СL.Дата < cast(format(@dt_to, 'yyyyMM01') AS date)
			)
			INSERT @calendar(Дата)
			SELECT СL.Дата 
			FROM СL
			--ORDER BY СL.Дата
			OPTION(MAXRECURSION 0)


			;WITH Result_x_Month AS (
				SELECT 
					S.result_name,
					S.sort_order,
					C.Дата
				FROM #t_Result_VK AS S
					INNER JOIN @calendar AS C
						ON 1=1
			),
			Total_Monthly AS (
				SELECT				
					sort_order = 1000,
					[Итог проверки] = 'Итого:',
					[Дата] = cast(format(R.Дата, 'yyyyMM01') AS date),
					[Кол-во] = count(*),
					[Проценты] = cast(100.0 AS numeric(10,1))
					--[Проценты] = cast(1.0 AS numeric(10,1))
				FROM #t_Result_Detail AS R
				GROUP BY cast(format(R.Дата, 'yyyyMM01') AS date)
			),
			Monthly AS (
				SELECT 
					sort_order = isnull(S.sort_order, 999),
					R.[Итог проверки],
					[Дата] = cast(format(R.Дата, 'yyyyMM01') AS date),
					[Кол-во] = count(*)
					--[Проценты] = cast(iif(@total_requests > 0, 100.0 * count(*) / @total_requests, 0) AS numeric(10,1))
				FROM #t_Result_VK AS S
					LEFT JOIN #t_Result_Detail AS R
						ON S.result_name = R.[Итог проверки]
				GROUP BY 
					isnull(S.sort_order, 999),
					R.[Итог проверки],
					cast(format(R.Дата, 'yyyyMM01') AS date)
			) 
			SELECT 
				X.sort_order,
				[Итог проверки] = X.result_name,
				X.Дата,
				[Кол-во] = isnull(M.[Кол-во], 0),
				[Проценты] = cast(iif(T.[Кол-во] > 0, 100.0 * isnull(M.[Кол-во], 0) / T.[Кол-во], 0) AS numeric(10,1))
				--[Проценты] = cast(iif(T.[Кол-во] > 0, 1.0 * isnull(M.[Кол-во], 0) / T.[Кол-во], 0) AS numeric(10,1))
			FROM Result_x_Month AS X
				LEFT JOIN Monthly AS M
					ON M.[Итог проверки] = X.result_name
					AND M.Дата = X.Дата
				LEFT JOIN Total_Monthly AS T
					ON T.Дата = M.Дата
			UNION 
			SELECT
				T.sort_order,
				T.[Итог проверки],
				T.Дата,
				T.[Кол-во],
				T.Проценты				
			FROM Total_Monthly AS T
			ORDER BY Дата, sort_order

			RETURN 0
		END

	END


	RETURN 0

END TRY
BEGIN CATCH
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(13)+char(10)
		+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))+char(13)+char(10)
		+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(13)+char(10)
		+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')+char(13)+char(10)
		+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(13)+char(10)
		+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
			ROLLBACK;

	SELECT @message = concat(
		'EXEC dbo.Report_FedorVideoChat ',
		'@Page=''', @Page, ''', ',
		'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+'''')
		--, ', ',
		--'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		--'@isDebug=', convert(varchar(10), @isDebug)
	)

	SELECT @eventType = concat(@Page, ' error')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @eventName ,
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END
