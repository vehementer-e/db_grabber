-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2021_12_15
-- Description:	Перенесли в одну процедуру всю бизнес-логику для формирования куба Installment
-- =============================================
-- A. Nikitin
-- DWH-2420 Пересоздания отчета ТТС верификации
-- exec dbo.Create_dmFeodor_report_TTC_Common
-- =============================================
CREATE PROC dbo.Create_dmFeodor_report_TTC_Common
	@RequestNumber varchar(20) = NULL,  -- заполнение одной заявки с этим Номером
	@RequestBeginDate date = NULL, --заполнение с конкретной Даты заведения заявок
	@Days int = NULL, -- заполнение заявками за последние @Days дней
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isDebug int = 0
AS
BEGIN

	SELECT @isDebug = isnull(@isDebug, 0)
	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())

	DECLARE @mode int = 0 -- 0- full, 1- increment

	DROP TABLE IF EXISTS #t_Request
	CREATE TABLE #t_Request(RequestNumber nvarchar(50))

	IF @RequestNumber IS NOT NULL BEGIN
		INSERT #t_Request(RequestNumber)
		SELECT @RequestNumber

		SELECT @mode = 1
	END
	ELSE BEGIN
		IF @RequestBeginDate IS NOT NULL BEGIN
			INSERT #t_Request(RequestNumber)
			SELECT DISTINCT cr.Number COLLATE Cyrillic_General_CI_AS
			from Stg._fedor.core_ClientRequest AS cr 
			WHERE 1=1
				and cr.CreatedOn >= dateadd(HOUR, -3, cast(@RequestBeginDate AS datetime2))

			SELECT @mode = 1
		END
		ELSE BEGIN
			IF @Days IS NOT NULL BEGIN
				INSERT #t_Request(RequestNumber)
				SELECT DISTINCT cr.Number
				from Stg._fedor.core_ClientRequest AS cr 
				WHERE 1=1
					and cr.CreatedOn >= dateadd(HOUR, -3, cast(dateadd(DAY, -@Days, cast(getdate() as date)) AS datetime2))

				SELECT @mode = 1
			END
		END
	END

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Request
		SELECT * INTO ##t_Request FROM #t_Request
		RETURN 0
	END


	CREATE UNIQUE CLUSTERED INDEX clix1 ON #t_Request(RequestNumber)

	drop table if exists #Factor_Analysis_001

	select 
		 [Канал от источника]
		,[Группа каналов]
		,Продукт
		,[Вид займа]
		,Номер
		,[Признак Рефинансирование]
	into #Factor_Analysis_001
	from reports.dbo.dm_Factor_Analysis_001 AS A
	WHERE 1=1
		--AND (A.Номер = @RequestNumber OR @RequestNumber IS NULL)
		AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1  FROM #t_Request AS R WHERE R.RequestNumber = A.Номер))

	--IF @isDebug = 1 BEGIN
	--	DROP TABLE IF EXISTS ##Factor_Analysis_001
	--	SELECT * INTO ##Factor_Analysis_001 FROM #Factor_Analysis_001
	--END

	DROP table if exists #date_of_issue_of_the_loan
	CREATE TABLE #date_of_issue_of_the_loan(
		[Дата статуса выдан] datetime2(0),
		[Номер заявки выдан] nvarchar(255)
	)

	--Installment
	--INSERT #date_of_issue_of_the_loan([Дата статуса выдан], [Номер заявки выдан])
	--select max(cast([Дата статуса] as datetime2(0))) as [Дата статуса выдан], [Номер заявки] as [Номер заявки выдан]
	--FROM Reports.dbo.dm_FedorVerificationRequests_Installment fr
	--where Статус =N'Заем выдан'
	--	--AND (fr.[Номер заявки] = @RequestNumber OR @RequestNumber IS NULL)
	--	AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1  FROM #t_Request AS R WHERE R.RequestNumber = fr.[Номер заявки]))
	--group by [Номер заявки]

	--PTS
	INSERT #date_of_issue_of_the_loan([Дата статуса выдан], [Номер заявки выдан])
	select 
		max(cast([Дата статуса] as datetime2(0))) as [Дата статуса выдан], 
		[Номер заявки] COLLATE Cyrillic_General_CI_AS as [Номер заявки выдан]
	FROM Reports.dbo.dm_FedorVerificationRequests fr
	where Статус =N'Заем выдан'
		--AND (fr.[Номер заявки] = @RequestNumber OR @RequestNumber IS NULL)
		AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1  FROM #t_Request AS R WHERE R.RequestNumber = fr.[Номер заявки] COLLATE Cyrillic_General_CI_AS))
	group by [Номер заявки]

	--PDL
	--INSERT #date_of_issue_of_the_loan([Дата статуса выдан], [Номер заявки выдан])
	--select max(cast([Дата статуса] as datetime2(0))) as [Дата статуса выдан], [Номер заявки] as [Номер заявки выдан]
	--FROM Reports.dbo.dm_FedorVerificationRequests_PDL fr
	--where Статус =N'Заем выдан'
	--	--AND (fr.[Номер заявки] = @RequestNumber OR @RequestNumber IS NULL)
	--	AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1  FROM #t_Request AS R WHERE R.RequestNumber = fr.[Номер заявки]))
	--group by [Номер заявки]

	--DWH-2684. Installment + PDL
	INSERT #date_of_issue_of_the_loan([Дата статуса выдан], [Номер заявки выдан])
	select max(cast([Дата статуса] as datetime2(0))) as [Дата статуса выдан], [Номер заявки] as [Номер заявки выдан]
	FROM Reports.dbo.dm_FedorVerificationRequests_without_coll AS fr
	where Статус =N'Заем выдан'
		--AND (fr.[Номер заявки] = @RequestNumber OR @RequestNumber IS NULL)
		AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1  FROM #t_Request AS R WHERE R.RequestNumber = fr.[Номер заявки]))
	group by [Номер заявки]

	DROP table if exists #date_of_signing_the_loan_agreement

	--Installment
	--select max(cast([Дата статуса] as datetime2(0))) as [Дата статуса выдан], [Номер заявки] as [Номер заявки подписан]
	--FROM Reports.dbo.dm_FedorVerificationRequests_Installment fr
	--where Статус =N'Договор подписан'
	--	--AND (fr.[Номер заявки] = @RequestNumber OR @RequestNumber IS NULL)
	--	AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1  FROM #t_Request AS R WHERE R.RequestNumber = fr.[Номер заявки]))
	--group by [Номер заявки]

	--PTS
	select 
		max(cast([Дата статуса] as datetime2(0))) as [Дата статуса выдан], 
		[Номер заявки] COLLATE Cyrillic_General_CI_AS as [Номер заявки подписан]
	into #date_of_signing_the_loan_agreement
	FROM Reports.dbo.dm_FedorVerificationRequests fr
	where Статус =N'Договор подписан'
		--AND (fr.[Номер заявки] = @RequestNumber OR @RequestNumber IS NULL)
		AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1  FROM #t_Request AS R WHERE R.RequestNumber = fr.[Номер заявки] COLLATE Cyrillic_General_CI_AS))
	group by [Номер заявки]

	--PDL
	--INSERT #date_of_signing_the_loan_agreement
	--select max(cast([Дата статуса] as datetime2(0))) as [Дата статуса выдан], [Номер заявки] as [Номер заявки подписан]
	--FROM Reports.dbo.dm_FedorVerificationRequests_PDL fr
	--where Статус =N'Договор подписан'
	--	--AND (fr.[Номер заявки] = @RequestNumber OR @RequestNumber IS NULL)
	--	AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1  FROM #t_Request AS R WHERE R.RequestNumber = fr.[Номер заявки]))
	--group by [Номер заявки]

	--DWH-2684. Installment + PDL
	INSERT #date_of_signing_the_loan_agreement
	select max(cast([Дата статуса] as datetime2(0))) as [Дата статуса выдан], [Номер заявки] as [Номер заявки подписан]
	FROM Reports.dbo.dm_FedorVerificationRequests_without_coll AS fr
	where Статус =N'Договор подписан'
		--AND (fr.[Номер заявки] = @RequestNumber OR @RequestNumber IS NULL)
		AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1  FROM #t_Request AS R WHERE R.RequestNumber = fr.[Номер заявки]))
	group by [Номер заявки]



	DROP TABLE IF EXISTS #t_dm_FedorVerificationRequests_ALL
	CREATE TABLE #t_dm_FedorVerificationRequests_ALL
	(
		[ProductType_Code] [varchar](11) NULL,
		[Дата заведения заявки] [date] NULL,
		[Время заведения] [time](7) NULL,
		[Номер заявки] [nvarchar](255) NULL,
		[ФИО клиента] [nvarchar](255) NULL,
		[Статус] [nvarchar](260) NULL,
		[Задача] [nvarchar](260) NULL,
		[Состояние заявки] [nvarchar](50) NULL,
		[Дата статуса] [datetime2](0) NULL,
		[Дата_статусаТекущая] [date] NULL,
		[Дата след.статуса] [datetime2](0) NULL,
		[Дата_статуса_следующая] [date] NULL,
		[ФИО сотрудника верификации/чекер] [nvarchar](255) NULL,
		[ВремяЗатрачено] [decimal](16, 10) NULL,
		[Время, час:мин:сек] [datetime] NULL,
		[Статус следующий] [nvarchar](260) NULL,
		[Задача следующая] [nvarchar](260) NULL,
		[Состояние заявки следующая] [nvarchar](50) NULL,
		[ПричинаНаим_Исх] [int] NULL,
		[ПричинаНаим_След] [int] NULL,
		[Последнее состояние заявки на дату по сотруднику] [nvarchar](50) NULL,
		[Последний статус заявки на дату по сотруднику] [nvarchar](260) NULL,
		[Последний статус заявки на дату] [nvarchar](260) NULL,
		[СотрудникПоследнегоСтатуса] [nvarchar](255) NULL,
		[ШагЗаявки] [bigint] NULL,
		[ПоследнийШаг] [bigint] NULL,
		[Последний статус заявки] [nvarchar](260) NULL,
		[Время в последнем статусе] [decimal](16, 10) NULL,
		[Время в последнем статусе, hh:mm:ss] [nvarchar](255) NULL,
		[ВремяЗатраченоОжиданиеВерификацииКлиента] [decimal](16, 10) NULL,
		[СотрудникКД] [int] NULL,
		[СотрудникВК] [int] NULL,
		[ШагЗаявки_eq_ПоследнийШаг] [int] NULL,
		[ПризнакВыдан] [int] NULL,
		[ПризнакПодписан] [int] NULL,
		[ДатаВремяЗаведенияЗаявки] [datetime2](0) NULL,
		[ДатаПодписан] [datetime2](0) NULL,
		[ДатаВыдан] [datetime2](0) NULL,
		[Статус_TTC] [nvarchar](311) NULL,
		[ПризнакИсключенияСотрудника] [int] NULL,
		[IsSkipped] [bit] NULL
	)

	--1. PTS
	INSERT #t_dm_FedorVerificationRequests_ALL
	(
	    ProductType_Code,
	    [Дата заведения заявки],
	    [Время заведения],
	    [Номер заявки],
	    [ФИО клиента],
	    Статус,
	    Задача,
	    [Состояние заявки],
	    [Дата статуса],
	    Дата_статусаТекущая,
	    [Дата след.статуса],
	    Дата_статуса_следующая,
	    [ФИО сотрудника верификации/чекер],
	    ВремяЗатрачено,
	    [Время, час:мин:сек],
	    [Статус следующий],
	    [Задача следующая],
	    [Состояние заявки следующая],
	    ПричинаНаим_Исх,
	    ПричинаНаим_След,
	    [Последнее состояние заявки на дату по сотруднику],
	    [Последний статус заявки на дату по сотруднику],
	    [Последний статус заявки на дату],
	    СотрудникПоследнегоСтатуса,
	    ШагЗаявки,
	    ПоследнийШаг,
	    [Последний статус заявки],
	    [Время в последнем статусе],
	    [Время в последнем статусе, hh:mm:ss],
	    ВремяЗатраченоОжиданиеВерификацииКлиента,
	    СотрудникКД,
	    СотрудникВК,
	    ШагЗаявки_eq_ПоследнийШаг,
	    ПризнакВыдан,
	    ПризнакПодписан,
	    ДатаВремяЗаведенияЗаявки,
	    ДатаПодписан,
	    ДатаВыдан,
	    Статус_TTC,
	    ПризнакИсключенияСотрудника
	)
	SELECT   
		ProductType_Code = 'pts',
		fr.[Дата заведения заявки],
		fr.[Время заведения],
		fr.[Номер заявки] COLLATE Cyrillic_General_CI_AS,
		fr.[ФИО клиента] COLLATE Cyrillic_General_CI_AS,
		fr.Статус COLLATE Cyrillic_General_CI_AS,
		fr.Задача COLLATE Cyrillic_General_CI_AS,
		fr.[Состояние заявки] COLLATE Cyrillic_General_CI_AS,
		cast(fr.[Дата статуса] as datetime2(0)) as [Дата статуса],
		cast(fr.[Дата статуса] as date) [Дата_статусаТекущая],
		cast(fr.[Дата след.статуса] as datetime2(0)) as [Дата след.статуса],
		cast(fr.[Дата след.статуса] as date) as  [Дата_статуса_следующая] ,
		fr.[ФИО сотрудника верификации/чекер] COLLATE Cyrillic_General_CI_AS,
		fr.ВремяЗатрачено,
		fr.[Время, час:мин:сек],
		fr.[Статус следующий] COLLATE Cyrillic_General_CI_AS,
		fr.[Задача следующая] COLLATE Cyrillic_General_CI_AS,
		fr.[Состояние заявки следующая] COLLATE Cyrillic_General_CI_AS,
		fr.ПричинаНаим_Исх,
		fr.ПричинаНаим_След,
		fr.[Последнее состояние заявки на дату по сотруднику] COLLATE Cyrillic_General_CI_AS,
		fr.[Последний статус заявки на дату по сотруднику] COLLATE Cyrillic_General_CI_AS,
		fr.[Последний статус заявки на дату],
		fr.СотрудникПоследнегоСтатуса COLLATE Cyrillic_General_CI_AS,
		fr.ШагЗаявки,
		fr.ПоследнийШаг,
		fr.[Последний статус заявки] COLLATE Cyrillic_General_CI_AS,
		fr.[Время в последнем статусе],
		fr.[Время в последнем статусе, hh:mm:ss] COLLATE Cyrillic_General_CI_AS,
		fr.ВремяЗатраченоОжиданиеВерификацииКлиента

		, iif( kde.Employee is null, 0,1) СотрудникКД
		, iif( vke.Employee is null, 0,1) СотрудникВК

		, iif(fr.ШагЗаявки = fr.ПоследнийШаг, 1, 0) AS ШагЗаявки_eq_ПоследнийШаг

		, iif(loan.[Дата статуса выдан] is not null,1,0) as ПризнакВыдан
		, iif(loan2.[Дата статуса выдан] is not null,1,0) as ПризнакПодписан

		, ДатаВремяЗаведенияЗаявки = cast(
			datetimefromparts(
				year(fr.[Дата заведения заявки]), 
				month(fr.[Дата заведения заявки]), 
				day(fr.[Дата заведения заявки]),
				datepart(hour, fr.[Время заведения]), 
				datepart(minute,fr.[Время заведения]), 
				datepart(second, fr.[Время заведения]), 
				datepart(millisecond, fr.[Время заведения])
			)
			AS datetime2(0)
		)
		, loan2.[Дата статуса выдан]  as ДатаПодписан
		, loan.[Дата статуса выдан] as ДатаВыдан
		, trim(concat(
			fr.Статус, ' ',
			CASE 							     
				when fr.[Состояние заявки] in ('Статус изменен') then '' 
				ELSE 
					CASE 
						WHEN fr.Задача = 'task:Требуется доработка'and fr.[Состояние заявки]='Отложена' then N'Доработка'
						WHEN fr.Задача = 'task:Отложена' and fr.[Состояние заявки] in('Отложена') then N'Отложена'
						ELSE fr.[Состояние заявки] 
					END
			END)) AS Статус_TTC
		, fr.[ПризнакИсключенияСотрудника] 
	FROM Reports.dbo.dm_FedorVerificationRequests AS fr
		left join feodor.dbo.KDEmployees AS kde
			ON fr.[ФИО сотрудника верификации/чекер] COLLATE Cyrillic_General_CI_AS =  kde.Employee
		left join feodor.dbo.VEmployees AS vke
			ON fr.[ФИО сотрудника верификации/чекер] COLLATE Cyrillic_General_CI_AS = vke.Employee
		left join #date_of_issue_of_the_loan AS loan
			ON loan.[Номер заявки выдан] = fr.[Номер заявки] COLLATE Cyrillic_General_CI_AS
		left join #date_of_signing_the_loan_agreement AS loan2 
			ON loan2.[Номер заявки подписан] = fr.[Номер заявки] COLLATE Cyrillic_General_CI_AS
	WHERE 1=1
		--AND (fr.[Номер заявки] COLLATE Cyrillic_General_CI_AS = @RequestNumber OR @RequestNumber IS NULL)
		AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1 FROM #t_Request AS R WHERE R.RequestNumber = fr.[Номер заявки] COLLATE Cyrillic_General_CI_AS))

	/*
	--2. Installment
	INSERT #t_dm_FedorVerificationRequests_ALL
	(
	    ProductType_Code,
	    [Дата заведения заявки],
	    [Время заведения],
	    [Номер заявки],
	    [ФИО клиента],
	    Статус,
	    Задача,
	    [Состояние заявки],
	    [Дата статуса],
	    Дата_статусаТекущая,
	    [Дата след.статуса],
	    Дата_статуса_следующая,
	    [ФИО сотрудника верификации/чекер],
	    ВремяЗатрачено,
	    [Время, час:мин:сек],
	    [Статус следующий],
	    [Задача следующая],
	    [Состояние заявки следующая],
	    ПричинаНаим_Исх,
	    ПричинаНаим_След,
	    [Последнее состояние заявки на дату по сотруднику],
	    [Последний статус заявки на дату по сотруднику],
	    [Последний статус заявки на дату],
	    СотрудникПоследнегоСтатуса,
	    ШагЗаявки,
	    ПоследнийШаг,
	    [Последний статус заявки],
	    [Время в последнем статусе],
	    [Время в последнем статусе, hh:mm:ss],
	    ВремяЗатраченоОжиданиеВерификацииКлиента,
	    СотрудникКД,
	    СотрудникВК,
	    ШагЗаявки_eq_ПоследнийШаг,
	    ПризнакВыдан,
	    ПризнакПодписан,
	    ДатаВремяЗаведенияЗаявки,
	    ДатаПодписан,
	    ДатаВыдан,
	    Статус_TTC,
	    ПризнакИсключенияСотрудника,
		IsSkipped
	)
	SELECT   
		ProductType_Code = 'installment',
		fr.[Дата заведения заявки],
		fr.[Время заведения],
		fr.[Номер заявки],
		fr.[ФИО клиента],
		fr.Статус,
		fr.Задача,
		fr.[Состояние заявки],
		cast(fr.[Дата статуса] as datetime2(0)) as [Дата статуса],
		cast(fr.[Дата статуса] as date) [Дата_статусаТекущая],
		cast(fr.[Дата след.статуса] as datetime2(0)) as [Дата след.статуса],
		cast(fr.[Дата след.статуса] as date) as  [Дата_статуса_следующая] ,
		fr.[ФИО сотрудника верификации/чекер],
		fr.ВремяЗатрачено,
		fr.[Время, час:мин:сек],
		fr.[Статус следующий],
		fr.[Задача следующая],
		fr.[Состояние заявки следующая],
		fr.ПричинаНаим_Исх,
		fr.ПричинаНаим_След,
		fr.[Последнее состояние заявки на дату по сотруднику],
		fr.[Последний статус заявки на дату по сотруднику],
		fr.[Последний статус заявки на дату],
		fr.СотрудникПоследнегоСтатуса,
		fr.ШагЗаявки,
		fr.ПоследнийШаг,
		fr.[Последний статус заявки],
		fr.[Время в последнем статусе],
		fr.[Время в последнем статусе, hh:mm:ss],
		fr.ВремяЗатраченоОжиданиеВерификацииКлиента

		, iif( kde.Employee is null, 0,1) СотрудникКД
		, iif( vke.Employee is null, 0,1) СотрудникВК

		, iif(fr.ШагЗаявки = fr.ПоследнийШаг, 1, 0) AS ШагЗаявки_eq_ПоследнийШаг

		, iif(loan.[Дата статуса выдан] is not null,1,0) as ПризнакВыдан
		, iif(loan2.[Дата статуса выдан] is not null,1,0) as ПризнакПодписан

		, ДатаВремяЗаведенияЗаявки = cast(
			datetimefromparts(
				year(fr.[Дата заведения заявки]), 
				month(fr.[Дата заведения заявки]), 
				day(fr.[Дата заведения заявки]),
				datepart(hour, fr.[Время заведения]), 
				datepart(minute,fr.[Время заведения]), 
				datepart(second, fr.[Время заведения]), 
				datepart(millisecond, fr.[Время заведения])
			)
			AS datetime2(0)
		)
		, loan2.[Дата статуса выдан]  as ДатаПодписан
		, loan.[Дата статуса выдан] as ДатаВыдан
		, trim(concat(
			fr.Статус, ' ',
			CASE 							     
				when fr.[Состояние заявки] in ('Статус изменен') then '' 
				ELSE 
					CASE 
						WHEN fr.Задача = 'task:Требуется доработка'and fr.[Состояние заявки]='Отложена' then N'Доработка'
						WHEN fr.Задача = 'task:Отложена' and fr.[Состояние заявки] in('Отложена') then N'Отложена'
						ELSE fr.[Состояние заявки] 
					END
			END)) AS Статус_TTC
		, fr.[ПризнакИсключенияСотрудника] 
		, fr.IsSkipped
	FROM Reports.dbo.dm_FedorVerificationRequests_Installment AS fr
		left join feodor.dbo.KDEmployees  kde on  fr.[ФИО сотрудника верификации/чекер] =  kde.Employee
		left join feodor.dbo.VEmployees  vke on  fr.[ФИО сотрудника верификации/чекер] =  vke.Employee
		left join #date_of_issue_of_the_loan loan on loan.[Номер заявки выдан] = fr.[Номер заявки]
		left join #date_of_signing_the_loan_agreement loan2 on loan2.[Номер заявки подписан] = fr.[Номер заявки]
	WHERE 1=1
		--AND (fr.[Номер заявки] = @RequestNumber OR @RequestNumber IS NULL)
		AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1 FROM #t_Request AS R WHERE R.RequestNumber = fr.[Номер заявки]))


	--3. PDL
	INSERT #t_dm_FedorVerificationRequests_ALL
	(
	    ProductType_Code,
	    [Дата заведения заявки],
	    [Время заведения],
	    [Номер заявки],
	    [ФИО клиента],
	    Статус,
	    Задача,
	    [Состояние заявки],
	    [Дата статуса],
	    Дата_статусаТекущая,
	    [Дата след.статуса],
	    Дата_статуса_следующая,
	    [ФИО сотрудника верификации/чекер],
	    ВремяЗатрачено,
	    [Время, час:мин:сек],
	    [Статус следующий],
	    [Задача следующая],
	    [Состояние заявки следующая],
	    ПричинаНаим_Исх,
	    ПричинаНаим_След,
	    [Последнее состояние заявки на дату по сотруднику],
	    [Последний статус заявки на дату по сотруднику],
	    [Последний статус заявки на дату],
	    СотрудникПоследнегоСтатуса,
	    ШагЗаявки,
	    ПоследнийШаг,
	    [Последний статус заявки],
	    [Время в последнем статусе],
	    [Время в последнем статусе, hh:mm:ss],
	    ВремяЗатраченоОжиданиеВерификацииКлиента,
	    СотрудникКД,
	    СотрудникВК,
	    ШагЗаявки_eq_ПоследнийШаг,
	    ПризнакВыдан,
	    ПризнакПодписан,
	    ДатаВремяЗаведенияЗаявки,
	    ДатаПодписан,
	    ДатаВыдан,
	    Статус_TTC,
	    ПризнакИсключенияСотрудника,
		IsSkipped
	)
	SELECT   
		ProductType_Code = 'pdl',
		fr.[Дата заведения заявки],
		fr.[Время заведения],
		fr.[Номер заявки],
		fr.[ФИО клиента],
		fr.Статус,
		fr.Задача,
		fr.[Состояние заявки],
		cast(fr.[Дата статуса] as datetime2(0)) as [Дата статуса],
		cast(fr.[Дата статуса] as date) [Дата_статусаТекущая],
		cast(fr.[Дата след.статуса] as datetime2(0)) as [Дата след.статуса],
		cast(fr.[Дата след.статуса] as date) as  [Дата_статуса_следующая] ,
		fr.[ФИО сотрудника верификации/чекер],
		fr.ВремяЗатрачено,
		fr.[Время, час:мин:сек],
		fr.[Статус следующий],
		fr.[Задача следующая],
		fr.[Состояние заявки следующая],
		fr.ПричинаНаим_Исх,
		fr.ПричинаНаим_След,
		fr.[Последнее состояние заявки на дату по сотруднику],
		fr.[Последний статус заявки на дату по сотруднику],
		fr.[Последний статус заявки на дату],
		fr.СотрудникПоследнегоСтатуса,
		fr.ШагЗаявки,
		fr.ПоследнийШаг,
		fr.[Последний статус заявки],
		fr.[Время в последнем статусе],
		fr.[Время в последнем статусе, hh:mm:ss],
		fr.ВремяЗатраченоОжиданиеВерификацииКлиента

		, iif( kde.Employee is null, 0,1) СотрудникКД
		, iif( vke.Employee is null, 0,1) СотрудникВК

		, iif(fr.ШагЗаявки = fr.ПоследнийШаг, 1, 0) AS ШагЗаявки_eq_ПоследнийШаг

		, iif(loan.[Дата статуса выдан] is not null,1,0) as ПризнакВыдан
		, iif(loan2.[Дата статуса выдан] is not null,1,0) as ПризнакПодписан

		, ДатаВремяЗаведенияЗаявки = cast(
			datetimefromparts(
				year(fr.[Дата заведения заявки]), 
				month(fr.[Дата заведения заявки]), 
				day(fr.[Дата заведения заявки]),
				datepart(hour, fr.[Время заведения]), 
				datepart(minute,fr.[Время заведения]), 
				datepart(second, fr.[Время заведения]), 
				datepart(millisecond, fr.[Время заведения])
			)
			AS datetime2(0)
		)
		, loan2.[Дата статуса выдан]  as ДатаПодписан
		, loan.[Дата статуса выдан] as ДатаВыдан
		, trim(concat(
			fr.Статус, ' ',
			CASE 							     
				when fr.[Состояние заявки] in ('Статус изменен') then '' 
				ELSE 
					CASE 
						WHEN fr.Задача = 'task:Требуется доработка'and fr.[Состояние заявки]='Отложена' then N'Доработка'
						WHEN fr.Задача = 'task:Отложена' and fr.[Состояние заявки] in('Отложена') then N'Отложена'
						ELSE fr.[Состояние заявки] 
					END
			END)) AS Статус_TTC
		, fr.[ПризнакИсключенияСотрудника] 
		, fr.IsSkipped
	FROM Reports.dbo.dm_FedorVerificationRequests_PDL AS fr
		left join feodor.dbo.KDEmployees  kde on  fr.[ФИО сотрудника верификации/чекер] =  kde.Employee
		left join feodor.dbo.VEmployees  vke on  fr.[ФИО сотрудника верификации/чекер] =  vke.Employee
		left join #date_of_issue_of_the_loan loan on loan.[Номер заявки выдан] = fr.[Номер заявки]
		left join #date_of_signing_the_loan_agreement loan2 on loan2.[Номер заявки подписан] = fr.[Номер заявки]
	WHERE 1=1
		--AND (fr.[Номер заявки] = @RequestNumber OR @RequestNumber IS NULL)
		AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1 FROM #t_Request AS R WHERE R.RequestNumber = fr.[Номер заявки]))
	*/

	--DWH-2684. Installment + PDL
	INSERT #t_dm_FedorVerificationRequests_ALL
	(
	    ProductType_Code,
	    [Дата заведения заявки],
	    [Время заведения],
	    [Номер заявки],
	    [ФИО клиента],
	    Статус,
	    Задача,
	    [Состояние заявки],
	    [Дата статуса],
	    Дата_статусаТекущая,
	    [Дата след.статуса],
	    Дата_статуса_следующая,
	    [ФИО сотрудника верификации/чекер],
	    ВремяЗатрачено,
	    [Время, час:мин:сек],
	    [Статус следующий],
	    [Задача следующая],
	    [Состояние заявки следующая],
	    ПричинаНаим_Исх,
	    ПричинаНаим_След,
	    [Последнее состояние заявки на дату по сотруднику],
	    [Последний статус заявки на дату по сотруднику],
	    [Последний статус заявки на дату],
	    СотрудникПоследнегоСтатуса,
	    ШагЗаявки,
	    ПоследнийШаг,
	    [Последний статус заявки],
	    [Время в последнем статусе],
	    [Время в последнем статусе, hh:mm:ss],
	    ВремяЗатраченоОжиданиеВерификацииКлиента,
	    СотрудникКД,
	    СотрудникВК,
	    ШагЗаявки_eq_ПоследнийШаг,
	    ПризнакВыдан,
	    ПризнакПодписан,
	    ДатаВремяЗаведенияЗаявки,
	    ДатаПодписан,
	    ДатаВыдан,
	    Статус_TTC,
	    ПризнакИсключенияСотрудника,
		IsSkipped
	)
	SELECT   
		ProductType_Code = fr.ProductType_Code,
		fr.[Дата заведения заявки],
		fr.[Время заведения],
		fr.[Номер заявки],
		fr.[ФИО клиента],
		fr.Статус,
		fr.Задача,
		fr.[Состояние заявки],
		cast(fr.[Дата статуса] as datetime2(0)) as [Дата статуса],
		cast(fr.[Дата статуса] as date) [Дата_статусаТекущая],
		cast(fr.[Дата след.статуса] as datetime2(0)) as [Дата след.статуса],
		cast(fr.[Дата след.статуса] as date) as  [Дата_статуса_следующая] ,
		fr.[ФИО сотрудника верификации/чекер],
		fr.ВремяЗатрачено,
		fr.[Время, час:мин:сек],
		fr.[Статус следующий],
		fr.[Задача следующая],
		fr.[Состояние заявки следующая],
		fr.ПричинаНаим_Исх,
		fr.ПричинаНаим_След,
		fr.[Последнее состояние заявки на дату по сотруднику],
		fr.[Последний статус заявки на дату по сотруднику],
		fr.[Последний статус заявки на дату],
		fr.СотрудникПоследнегоСтатуса,
		fr.ШагЗаявки,
		fr.ПоследнийШаг,
		fr.[Последний статус заявки],
		fr.[Время в последнем статусе],
		fr.[Время в последнем статусе, hh:mm:ss],
		fr.ВремяЗатраченоОжиданиеВерификацииКлиента

		, iif( kde.Employee is null, 0,1) СотрудникКД
		, iif( vke.Employee is null, 0,1) СотрудникВК

		, iif(fr.ШагЗаявки = fr.ПоследнийШаг, 1, 0) AS ШагЗаявки_eq_ПоследнийШаг

		, iif(loan.[Дата статуса выдан] is not null,1,0) as ПризнакВыдан
		, iif(loan2.[Дата статуса выдан] is not null,1,0) as ПризнакПодписан

		, ДатаВремяЗаведенияЗаявки = cast(
			datetimefromparts(
				year(fr.[Дата заведения заявки]), 
				month(fr.[Дата заведения заявки]), 
				day(fr.[Дата заведения заявки]),
				datepart(hour, fr.[Время заведения]), 
				datepart(minute,fr.[Время заведения]), 
				datepart(second, fr.[Время заведения]), 
				datepart(millisecond, fr.[Время заведения])
			)
			AS datetime2(0)
		)
		, loan2.[Дата статуса выдан]  as ДатаПодписан
		, loan.[Дата статуса выдан] as ДатаВыдан
		, trim(concat(
			fr.Статус, ' ',
			CASE 							     
				when fr.[Состояние заявки] in ('Статус изменен') then '' 
				ELSE 
					CASE 
						WHEN fr.Задача = 'task:Требуется доработка'and fr.[Состояние заявки]='Отложена' then N'Доработка'
						WHEN fr.Задача = 'task:Отложена' and fr.[Состояние заявки] in('Отложена') then N'Отложена'
						ELSE fr.[Состояние заявки] 
					END
			END)) AS Статус_TTC
		, fr.[ПризнакИсключенияСотрудника] 
		, fr.IsSkipped
	FROM Reports.dbo.dm_FedorVerificationRequests_without_coll AS fr
		left join feodor.dbo.KDEmployees  kde on  fr.[ФИО сотрудника верификации/чекер] =  kde.Employee
		left join feodor.dbo.VEmployees  vke on  fr.[ФИО сотрудника верификации/чекер] =  vke.Employee
		left join #date_of_issue_of_the_loan loan on loan.[Номер заявки выдан] = fr.[Номер заявки]
		left join #date_of_signing_the_loan_agreement loan2 on loan2.[Номер заявки подписан] = fr.[Номер заявки]
	WHERE 1=1
		--AND (fr.[Номер заявки] = @RequestNumber OR @RequestNumber IS NULL)
		AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1 FROM #t_Request AS R WHERE R.RequestNumber = fr.[Номер заявки]))


	--IsSkipped
	DROP TABLE IF EXISTS #t_Autoapprove
	CREATE TABLE #t_Autoapprove(
		[Номер заявки] nvarchar(255),
		Статус nvarchar(260),
		[Дата статуса] datetime2(7)
	)

	INSERT #t_Autoapprove
	(
		[Номер заявки],
		Статус,
		[Дата статуса]
	)
	SELECT 
		R.[Номер заявки], 
		R.Статус,
		[Дата статуса] = min(R.[Дата статуса])
	FROM #t_dm_FedorVerificationRequests_ALL AS R
	WHERE R.isSkipped = 1
	GROUP BY R.[Номер заявки], R.Статус

	CREATE CLUSTERED INDEX clix1 ON #t_Autoapprove([Номер заявки])

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Autoapprove
		SELECT * INTO ##t_Autoapprove FROM #t_Autoapprove
	END


	DROP TABLE IF EXISTS #t_final_approved
	CREATE TABLE #t_final_approved([Номер заявки] nvarchar(255), [Дата статуса] datetime2(7))

	--финальное одобрение
	INSERT #t_final_approved([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = max(R.[Дата след.статуса])
	FROM #t_dm_FedorVerificationRequests_ALL AS R
	WHERE R.[Статус следующий] = 'Одобрено' 
		-- есть заявки, у кот. нет записи Статус = 'Одобрено', но есть [Статус следующий] = 'Одобрено'
		--напр. '23121221532517','23121921568650','23121521547100'
	GROUP BY R.[Номер заявки]

	CREATE UNIQUE CLUSTERED INDEX clix1 ON #t_final_approved([Номер заявки])

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_final_approved
		SELECT * INTO ##t_final_approved FROM #t_final_approved
	END


	--заявки autoapprove КД, получившие финальное одобрение
	--заявки, по которым только на статусе КД был флаг skipped И которые получили финальное одобрение
	DROP TABLE IF EXISTS #t_Autoapprove_KD_fin_appr
	CREATE TABLE #Autoapprove_KD_fin_appr([Номер заявки] nvarchar(255))

	INSERT #Autoapprove_KD_fin_appr([Номер заявки])
	SELECT DISTINCT A.[Номер заявки]
	FROM #t_Autoapprove AS A
		INNER JOIN #t_final_approved AS F
			ON A.[Номер заявки] = F.[Номер заявки]
	WHERE 1=1
		AND A.Статус = 'Контроль данных'
		AND NOT EXISTS(
			SELECT TOP(1) 1 FROM #t_Autoapprove AS X
			WHERE X.[Номер заявки] = A.[Номер заявки]
				AND X.Статус = 'Верификация клиента'
		)

	CREATE UNIQUE CLUSTERED INDEX clix1 ON #Autoapprove_KD_fin_appr([Номер заявки])

	--заявки autoapprove ВК, получившие финальное одобрение
	--заявки, по которым только на статусе ВК был флаг skipped И которые получили финальное одобрение
	DROP TABLE IF EXISTS #t_Autoapprove_VK_fin_appr
	CREATE TABLE #t_Autoapprove_VK_fin_appr([Номер заявки] nvarchar(255))

	INSERT #t_Autoapprove_VK_fin_appr([Номер заявки])
	SELECT DISTINCT A.[Номер заявки]
	FROM #t_Autoapprove AS A
		INNER JOIN #t_final_approved AS F
			ON A.[Номер заявки] = F.[Номер заявки]
	WHERE 1=1
		AND A.Статус = 'Верификация клиента'
		AND NOT EXISTS(
			SELECT TOP(1) 1 FROM #t_Autoapprove AS X
			WHERE X.[Номер заявки] = A.[Номер заявки]
				AND X.Статус = 'Контроль данных'
		)

	CREATE UNIQUE CLUSTERED INDEX clix1 ON #t_Autoapprove_VK_fin_appr([Номер заявки])


	--заявки autoapprove КД + ВК, получившие финальное одобрение
	--заявки, по которым и на статусе КД, и на статусе ВК был флаг skipped И которые получили финальное одобрение
	DROP TABLE IF EXISTS #t_Autoapprove_KD_VK_fin_appr
	CREATE TABLE #t_Autoapprove_KD_VK_fin_appr([Номер заявки] nvarchar(255))

	INSERT #t_Autoapprove_KD_VK_fin_appr([Номер заявки])
	SELECT DISTINCT A.[Номер заявки]
	FROM #t_Autoapprove AS A
		INNER JOIN #t_Autoapprove AS B
			ON B.[Номер заявки] = A.[Номер заявки]
			AND B.Статус = 'Верификация клиента'
		INNER JOIN #t_final_approved AS F
			ON A.[Номер заявки] = F.[Номер заявки]
	WHERE A.Статус = 'Контроль данных'

	CREATE UNIQUE CLUSTERED INDEX clix1 ON #t_Autoapprove_KD_VK_fin_appr([Номер заявки])


	DROP TABLE IF EXISTS #vc_FedorVerificationRequests_Common

	SELECT 
		A.ProductType_Code,
		A.[Дата заведения заявки],
		A.[Время заведения],
		A.[Номер заявки],
		A.[ФИО клиента],
		A.Статус,
		A.Задача,
		A.[Состояние заявки],
		A.[Дата статуса],
		A.Дата_статусаТекущая,
		A.[Дата след.статуса],
		A.Дата_статуса_следующая,
		A.[ФИО сотрудника верификации/чекер],
		A.ВремяЗатрачено,
		A.[Время, час:мин:сек],
		A.[Статус следующий],
		A.[Задача следующая],
		A.[Состояние заявки следующая],
		A.ПричинаНаим_Исх,
		A.ПричинаНаим_След,
		A.[Последнее состояние заявки на дату по сотруднику],
		A.[Последний статус заявки на дату по сотруднику],
		A.[Последний статус заявки на дату],
		A.СотрудникПоследнегоСтатуса,
		A.ШагЗаявки,
		A.ПоследнийШаг,
		A.[Последний статус заявки],
		A.[Время в последнем статусе],
		A.[Время в последнем статусе, hh:mm:ss],
		A.ВремяЗатраченоОжиданиеВерификацииКлиента,
		A.СотрудникКД,
		A.СотрудникВК,
		A.ШагЗаявки_eq_ПоследнийШаг,
		A.ПризнакВыдан,
		A.ПризнакПодписан,
		A.ДатаВремяЗаведенияЗаявки,
		A.ДатаПодписан,
		A.ДатаВыдан,
		A.Статус_TTC,
		A.ПризнакИсключенияСотрудника

		,ДляОтчетаТТС = iif(nullif(trim(TC.Time_Code), '') IS NOT NULL, 'Для отчетаTTC', 'Не определен')
		,ПорядокTTC = isnull(TC.RN, -1)
		,РасчетВремени = 
			CASE TC.Time_Code
				WHEN 'Client' THEN 'клиентское время'
				WHEN 'Sys' THEN 'системное время'
				WHEN 'Ver' THEN 'верификационное время'
				ELSE 'Не определено'
			END
		,[Клиентское время] = iif(TC.Time_Code = 'Client', A.ВремяЗатрачено, 0)
		,[Системное время] = iif(TC.Time_Code = 'Sys', A.ВремяЗатрачено, 0) 
		,[Верификационное время] = iif(TC.Time_Code = 'Ver', A.ВремяЗатрачено, 0)

		,Показатель = isnull(I.Показатель, 'Не определен')

		,ДоработкаКД = iif(isnull(I.Показатель,'') = 'ДоработкаКД', 1, 0)
		,ДоработкаКДПоследнийШаг = iif(isnull(I.Показатель,'') = 'ДоработкаКДПоследнийШаг', 1, 0)
		,ОтложенаКД = iif(isnull(I.Показатель,'') = 'ОтложенаКД', 1, 0)
		,ОтложенаКДПоследнийШаг = iif(isnull(I.Показатель,'') = 'ОтложенаКДПоследнийШаг', 1, 0)
		,ОтказаноКД = iif(isnull(I.Показатель,'') = 'ОтказаноКД', 1, 0)
		,ВК_КД = iif(isnull(I.Показатель,'') = 'ВК_КД', 1, 0)
		,НоваяКД = iif(isnull(I.Показатель,'') = 'НоваяКД', 1, 0)
		,В_работеКД = iif(isnull(I.Показатель,'') = 'В_работеКД', 1, 0)

		,Автоодобрение = cast(
			CASE 
				WHEN A_KD.[Номер заявки] IS NOT NULL THEN 'Автоодобрение КД'
				WHEN A_VK.[Номер заявки] IS NOT NULL THEN 'Автоодобрение ВК'
				WHEN A_KD_VK.[Номер заявки] IS NOT NULL THEN 'Автоодобрение КД+ВК'
				ELSE NULL
			END AS varchar(30))

	INTO #vc_FedorVerificationRequests_Common

	FROM #t_dm_FedorVerificationRequests_ALL AS A
		LEFT JOIN Dictionary.StatusTTC_TimeCode AS TC
			ON TC.ProductType_Code = A.ProductType_Code
			AND TC.StatusTTS_Name = A.Статус_TTC
		LEFT JOIN Dictionary.TTC_Indicator AS I
			ON 	isnull(I.Статус, isnull(A.Статус, '*')) = isnull(A.Статус, '*')
			AND isnull(I.[Состояние заявки], isnull(A.[Состояние заявки], '*')) = isnull(A.[Состояние заявки], '*')
			AND isnull(I.Задача, isnull(A.Задача, '*')) = isnull(A.Задача, '*')
			AND isnull(I.[Статус следующий], isnull(A.[Статус следующий], '*')) = isnull(A.[Статус следующий], '*')
			AND isnull(I.[Состояние заявки следующая], isnull(A.[Состояние заявки следующая], '*')) = isnull(A.[Состояние заявки следующая], '*')
			AND isnull(I.[Задача следующая], isnull(A.[Задача следующая], '*')) = isnull(A.[Задача следующая], '*')
			AND isnull(I.[ШагЗаявки_eq_ПоследнийШаг], isnull(A.[ШагЗаявки_eq_ПоследнийШаг], 0)) = isnull(A.[ШагЗаявки_eq_ПоследнийШаг], 0)
		LEFT JOIN #Autoapprove_KD_fin_appr AS A_KD
			ON A_KD.[Номер заявки] = A.[Номер заявки]
		LEFT JOIN #t_Autoapprove_VK_fin_appr AS A_VK
			ON A_VK.[Номер заявки] = A.[Номер заявки]
		LEFT JOIN #t_Autoapprove_KD_VK_fin_appr AS A_KD_VK
			ON A_KD_VK.[Номер заявки] = A.[Номер заявки]



	-- OLD
	/*
	select *,
	[Клиентское время] = iif(РасчетВремени = 'клиентское время', ВремяЗатрачено,0) 
	,
	[Системное время] = iif(РасчетВремени = 'системное время', ВремяЗатрачено,0) 
	,
	[Верификационное время] = iif(РасчетВремени = 'верификационное время', ВремяЗатрачено,0)
	into #vc_FedorVerificationRequests_Common
	from
	(
	select m1.*,  iif(st.Статус is not null, 'Для отчетаTTC','Не определен') ДляОтчетаТТС
	 ,isnull(rn,-1) as ПорядокTTC
	  ,РасчетВремени = case when Статус_TTC in(	
							 'Предварительное одобрение' ,                
								  'Контроль данных Отложена'  ,                
								  'Контроль данных Доработка'  , 
								  'Ожидание подписи документов EDO' ,          
								  'Одобрен клиент',                            
								  'Верификация ТС Отложена',
								  'Верификация ТС Доработка',
								  'Одобрено',                                  
								  'Договор зарегистрирован',
								  'Договор подписан',        
								  ---разделили
								  'Верификация клиента Отложена'  ,                          
								  'Верификация клиента Доработка' )             
								  then 'клиентское время' 
			when Статус_TTC in(
							   'Верификация Call 3',                        
								  'Верификация клиента Выполнена',             
								  'Верификация Call 2',                        
								  'Верификация Call 1.5',                      
								  'Контроль данных Выполнена',                 
								  'Верификация КЦ')                            
								  then 'системное время'
			when Статус_TTC in(				  
							 'Черновик',                                  
								  'Контроль данных В работе',                  
								  'Контроль данных Ожидание',                  
								  'Верификация клиента Ожидание',              
								  'Верификация клиента В работе',              
								  'Верификация ТС Ожидание',
								  'Верификация ТС В работе')
								  then 'верификационное время'
			else 'Не определено'
		end
						
	from
	(
	SELECT   [Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], Статус, Задача, [Состояние заявки], cast([Дата статуса] as datetime2(0)) as [Дата статуса], cast([Дата статуса] as date) [Дата_статусаТекущая], cast([Дата след.статуса] as datetime2(0)) as [Дата след.статуса],  cast([Дата след.статуса] as date) as  [Дата_статуса_следующая] ,
							 [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], ПричинаНаим_Исх, 
							 ПричинаНаим_След, [Последнее состояние заявки на дату по сотруднику], [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], 
							 СотрудникПоследнегоСтатуса, ШагЗаявки, ПоследнийШаг, [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss], 
							 ВремяЗатраченоОжиданиеВерификацииКлиента
							 , iif(Задача='task:Требуется доработка' and [Состояние заявки]='Отложена' and Статус in('Контроль данных') , 1,0) ДоработкаКД
							 , iif([Задача следующая]='task:Требуется доработка' and [Состояние заявки следующая]='Отложена' and Статус in('Контроль данных') and ШагЗаявки= ПоследнийШаг , 1,0) ДоработкаКДПоследнийШаг
							 , iif(Задача='task:Отложена' and [Состояние заявки] in('Отложена') and Статус in('Контроль данных') , 1,0) ОтложенаКД
							 , iif([Задача следующая]='task:Отложена' and [Состояние заявки следующая] in('Отложена') and Статус in('Контроль данных') and ШагЗаявки= ПоследнийШаг , 1,0) ОтложенаКДПоследнийШаг						 
							 , iif([Статус следующий]='Отказано' and Статус in('Верификация Call 1.5') , 1,0) ОтказаноКД						 
							 , iif([Статус следующий]='Ожидание подписи документов EDO' and Статус in('Верификация Call 1.5') , 1,0) ВК_КД
							 , iif(Задача='task:Новая' and Статус in('Контроль данных') , 1,0) НоваяКД
							 , iif(Задача='task:В работе'  and Статус in('Контроль данных') , 1,0) В_работеКД
							 , iif( kde.Employee is null, 0,1) СотрудникКД
							 , iif( vke.Employee is null, 0,1) СотрудникВК
							 , case 
								when Задача='task:Требуется доработка' and [Состояние заявки]='Отложена' and Статус in('Контроль данных') then 'ДоработкаКД'
								 when [Задача следующая]='task:Требуется доработка' and [Состояние заявки следующая]='Отложена' and Статус in('Контроль данных') and ШагЗаявки= ПоследнийШаг then 'ДоработкаКДПоследнийШаг'
							 when Задача='task:Отложена' and [Состояние заявки] in('Отложена') and Статус in('Контроль данных') then 'ОтложенаКД'
							 when [Задача следующая]='task:Отложена' and [Состояние заявки следующая] in('Отложена') and Статус in('Контроль данных') and ШагЗаявки= ПоследнийШаг then 'ОтложенаКДПоследнийШаг'
							 when [Статус следующий]='Отказано' and Статус in('Верификация Call 1.5') then 'ОтказаноКД'					 
							 when [Статус следующий]='Ожидание подписи документов EDO' and Статус in('Верификация Call 1.5')then 'ВК_КД'
							 when Задача='task:Новая' and Статус in('Контроль данных') then 'НоваяКД'
							 when Задача='task:В работе'  and Статус in('Контроль данных') then 'В_работеКД'
							 -- vk
							 when Задача='task:Требуется доработка' and [Состояние заявки]='Отложена' and Статус in('Верификация клиента') then 'ДоработкаВК'
							 when [Задача следующая]='task:Требуется доработка' and [Состояние заявки следующая]='Отложена' and Статус in('Верификация клиента') and ШагЗаявки= ПоследнийШаг then 'ДоработкаВКПоследнийШаг'
							 when Задача='task:Отложена' and [Состояние заявки] in('Отложена') and Статус in('Верификация клиента') then 'ОтложенаВК'
							 when [Задача следующая]='task:Отложена' and [Состояние заявки следующая] in('Отложена') and Статус in('Верификация клиента') and ШагЗаявки= ПоследнийШаг then 'ОтложенаВКПоследнийШаг'
							 when [Статус следующий]='Отказано' and Статус in('Верификация Call 3') then 'ОтказаноВК'					 
							 when [Статус следующий]='Одобрен клиент' and Статус in('Верификация Call 3')then 'ВК_ВК'
							 when Задача='task:Новая' and Статус in('Верификация клиента') then 'НоваяВК'
							 when Задача='task:В работе'  and Статус in('Верификация клиента') then 'В_работеВК'
						   
							  -- vts
								when Задача='task:Требуется доработка' and [Состояние заявки]='Отложена' and Статус in('Верификация ТС') then 'ДоработкаВТС'                   
								 when [Задача следующая]='task:Требуется доработка' and [Состояние заявки следующая]='Отложена' and Статус in('Верификация ТС') and ШагЗаявки= ПоследнийШаг then 'ДоработкаВТСПоследнийШаг'
							 when Задача='task:Отложена' and [Состояние заявки] in('Отложена') and Статус in('Верификация ТС') then 'ОтложенаВТС'
							 when [Задача следующая]='task:Отложена' and [Состояние заявки следующая] in('Отложена') and Статус in('Верификация ТС') and ШагЗаявки= ПоследнийШаг then 'ОтложенаВТСПоследнийШаг'
							 --when [Статус следующий]='Отказано' and Статус in('Верификация Call 1.5') then 'ОтказаноВТС'					 
							 --when [Статус следующий]='Ожидание подписи документов EDO' and Статус in('Верификация Call 1.5')then 'ВК_ВТС'
							 when Задача='task:Новая' and Статус in('Верификация ТС') then 'НоваяВТС'
							 when Задача='task:В работе'  and Статус in('Верификация ТС') then 'В_работеВТС'
							 else 'Не определен'
							   end Показатель
							 --, Статус+N' '+case when [Состояние заявки] in ('Статус изменен') then '' else [Состояние заявки] end  Статус_TTC
							 , iif(loan.[Дата статуса выдан] is not null,1,0) as ПризнакВыдан
							 , iif(loan2.[Дата статуса выдан] is not null,1,0) as ПризнакПодписан
							 , ДатаВремяЗаведенияЗаявки = cast(DATETIMEFROMPARTS(year([Дата заведения заявки]) , month([Дата заведения заявки]), day([Дата заведения заявки]), 
							 DATEPART(hour, [Время заведения]), DATEPART(minute,[Время заведения]), 	DATEPART(second, [Время заведения]), DATEPART(millisecond, [Время заведения]))  as datetime2(0))
							 , loan2.[Дата статуса выдан]  as ДатаПодписан
							 , loan.[Дата статуса выдан] as ДатаВыдан
							 , Статус+N' '
								+ case 							     
									 when [Состояние заявки] in ('Статус изменен') then '' 
									 else 
										case 
										  when Задача='task:Требуется доработка' and [Состояние заявки]='Отложена'  then N'Доработка'
										  when Задача='task:Отложена' and [Состояние заявки] in('Отложена') then N'Отложена'
										  else
											[Состояние заявки] 
										end
								  end  Статус_TTC
							 , [ПризнакИсключенияСотрудника] 
		
						 
	FROM         Reports.dbo.dm_FedorVerificationRequests_Installment fr
	left join feodor.dbo.KDEmployees  kde on  fr.[ФИО сотрудника верификации/чекер] =  kde.Employee
	left join feodor.dbo.VEmployees  vke on  fr.[ФИО сотрудника верификации/чекер] =  vke.Employee
	left join #date_of_issue_of_the_loan loan on loan.[Номер заявки выдан] = fr.[Номер заявки]
	left join #date_of_signing_the_loan_agreement loan2 on loan2.[Номер заявки подписан] = fr.[Номер заявки]
	WHERE 1=1
		AND (fr.[Номер заявки] = @RequestNumber OR @RequestNumber IS NULL)
	) m1
	left join #s as st on st.Статус = m1.Статус_TTC and st.ttc = 1
	) m2
	*/

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##vc_FedorVerificationRequests_Common
		SELECT * INTO ##vc_FedorVerificationRequests_Common FROM #vc_FedorVerificationRequests_Common
	END



	--drop table if exists [dwh2].[cubes].[dm_FedorVerificationRequests_report_TTC_Common]

	--DWH-1764

	--IF @RequestNumber IS NULL
	IF @mode = 0
	BEGIN
		TRUNCATE TABLE cubes.dm_FedorVerificationRequests_report_TTC_Common
	END
	ELSE BEGIN
		DELETE D
		FROM cubes.dm_FedorVerificationRequests_report_TTC_Common AS D
		WHERE 1=1 
			--AND D.[Номер заявки] = @RequestNumber
			AND (EXISTS(SELECT TOP(1) 1 FROM #t_Request AS R WHERE R.RequestNumber = D.[Номер заявки]))
	END

	INSERT cubes.dm_FedorVerificationRequests_report_TTC_Common
	(
		ProductType_Code,
		[Дата заведения заявки],
		[Время заведения],
		[Номер заявки],
		[ФИО клиента],
		Статус,
		Задача,
		[Состояние заявки],
		[Дата статуса],
		Дата_статусаТекущая,
		[Дата след.статуса],
		Дата_статуса_следующая,
		[ФИО сотрудника верификации/чекер],
		ВремяЗатрачено,
		[Время, час:мин:сек],
		[Статус следующий],
		[Задача следующая],
		[Состояние заявки следующая],
		ПричинаНаим_Исх,
		ПричинаНаим_След,
		[Последнее состояние заявки на дату по сотруднику],
		[Последний статус заявки на дату по сотруднику],
		[Последний статус заявки на дату],
		СотрудникПоследнегоСтатуса,
		ШагЗаявки,
		ПоследнийШаг,
		[Последний статус заявки],
		[Время в последнем статусе],
		[Время в последнем статусе, hh:mm:ss],
		ВремяЗатраченоОжиданиеВерификацииКлиента,
		ДоработкаКД,
		ДоработкаКДПоследнийШаг,
		ОтложенаКД,
		ОтложенаКДПоследнийШаг,
		ОтказаноКД,
		ВК_КД,
		НоваяКД,
		В_работеКД,
		СотрудникКД,
		СотрудникВК,
		Показатель,
		Статус_TTC,
		ПризнакВыдан,
		ПризнакПодписан,
		ДатаВремяЗаведенияЗаявки,
		ДляОтчетаТТС,
		ПорядокTTC,
		РасчетВремени,
		[Клиентское время],
		[Системное время],
		[Верификационное время],
		[Канал от источника],
		[Группа каналов],
		[Вид займа],
		ИспытательныйСрок,
		Продукт,
		[Время суток],
		ДатаПодписан,
		ДатаВыдан,
		[Клиентское время hh mm ss],
		[Системное время hh mm ss],
		[Верификационное время hh mm ss],
		ПризнакИсключенияСотрудника,
		Автоодобрение
	)
	select 
		  ProductType_Code
		  ,[Дата заведения заявки]
		  ,[Время заведения]
		  ,[Номер заявки]
		  ,[ФИО клиента]
		  ,req.[Статус]
		  ,[Задача]
		  ,[Состояние заявки]
		  ,[Дата статуса]
		  ,[Дата_статусаТекущая]
		  ,[Дата след.статуса]
		  ,[Дата_статуса_следующая]
		  ,[ФИО сотрудника верификации/чекер]
		  ,[ВремяЗатрачено]
		  ,[Время, час:мин:сек]
		  ,[Статус следующий]
		  ,[Задача следующая]
		  ,[Состояние заявки следующая]
		  ,[ПричинаНаим_Исх]
		  ,[ПричинаНаим_След]
		  ,[Последнее состояние заявки на дату по сотруднику]
		  ,[Последний статус заявки на дату по сотруднику]
		  ,[Последний статус заявки на дату]
		  ,[СотрудникПоследнегоСтатуса]
		  ,[ШагЗаявки] = row_number() over ( partition by [Номер заявки] order by [Дата статуса])
		  ,[ПоследнийШаг] = count([Номер заявки]) over ( partition by [Номер заявки] order by [Дата статуса])
		  ,[Последний статус заявки]
		  ,[Время в последнем статусе]
		  ,[Время в последнем статусе, hh:mm:ss]
		  ,[ВремяЗатраченоОжиданиеВерификацииКлиента]
		  ,[ДоработкаКД]
		  ,[ДоработкаКДПоследнийШаг]
		  ,[ОтложенаКД]
		  ,[ОтложенаКДПоследнийШаг]
		  ,[ОтказаноКД]
		  ,[ВК_КД]
		  ,[НоваяКД]
		  ,[В_работеКД]
		  ,[СотрудникКД]
		  ,[СотрудникВК]
		  ,[Показатель]
		  ,[Статус_TTC]
		  ,[ПризнакВыдан]
		  ,[ПризнакПодписан]
		  ,[ДатаВремяЗаведенияЗаявки]
		  ,[ДляОтчетаТТС]
		  ,[ПорядокTTC]
		  ,[РасчетВремени]
		  ,[Клиентское время]
		  ,[Системное время]
		  ,[Верификационное время] 
		  , factor.[Канал от источника]
		  , factor.[Группа каналов]
		  --, factor.Продукт
		  , factor.[Вид займа]
		  , case when crm_r.ИспытательныйСрок = 0 then 0 else 1 end as ИспытательныйСрок

		  , case 
			when crm_r.ИспытательныйСрок=1 then 'ПТС31'
			when factor.[признак рефинансирование] =1 then 'Рефинансирование'
			else 'Основной'
			end Продукт
		  , iif((cast([Дата статуса] as time) > '22:00:00' and cast([Дата статуса] as time) <= '23:59:59') or  (cast([Дата статуса] as time) > '00:00:00' and cast([Дата статуса] as time) <= '07:00:00'), 'Ночное время','Дневное время') 'Время суток'
				,[ДатаПодписан]
		  , [ДатаВыдан]
		  , [Клиентское время hh mm ss] = sum([Клиентское время]) over (partition by req.[Номер заявки])
		  , [Системное время hh mm ss] = sum([Системное время]) over (partition by req.[Номер заявки])
		  , [Верификационное время hh mm ss] = sum([Верификационное время]) over (partition by req.[Номер заявки])
		  , [ПризнакИсключенияСотрудника]
		  , req.Автоодобрение

	--into [dwh2].[cubes].[dm_FedorVerificationRequests_report_TTC_Common]
	from #vc_FedorVerificationRequests_Common AS req
		LEFT join #Factor_Analysis_001 factor on factor.Номер collate Cyrillic_General_CI_AS =  req.[Номер заявки]
		LEFT join Stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS crm_r on crm_r.Номер collate Cyrillic_General_CI_AS =req.[Номер заявки]


-- интервалы

drop table if exists #t


select  [Номер заявки], ШагЗаявки, [Дата статуса], [Дата след.статуса] ,
beginInterval, endInterval,		flagBeginInterval , flagEndInterval
, День =  case 
when flagBeginInterval = 'День' and flagEndInterval = 'Ночь' then cast(dateadd(hour, 22, cast(cast(beginInterval as date) as datetime)) as decimal(15,10)) - cast(beginInterval as decimal(15,10))
when flagBeginInterval = 'День' and flagEndInterval = 'День'  then  cast(endInterval as decimal(15,10)) - cast(beginInterval as decimal(15,10))
when flagBeginInterval = 'Ночь' and flagEndInterval = 'День'  then cast(endInterval as decimal(15,10)) - cast(dateadd(hour, 7, cast(cast(endInterval as date) as datetime)) as decimal(15,10)) 
else 0
end
, Ночь =  case 
when flagBeginInterval = 'День' and flagEndInterval = 'Ночь' then cast(endInterval as decimal(15,10)) - cast(dateadd(hour, 22, cast(cast(endInterval as date) as datetime)) as decimal(15,10)) 
when flagBeginInterval = 'Ночь' and flagEndInterval = 'Ночь' then  cast(endInterval as decimal(15,10)) - cast(beginInterval as decimal(15,10))
when flagBeginInterval = 'Ночь' and flagEndInterval = 'День' then cast(dateadd(hour, 7, cast(cast(beginInterval as date) as datetime)) as decimal(15,10)) - cast(beginInterval as decimal(15,10))
else 0
end
, rn = row_number() over(partition by [Номер заявки], ШагЗаявки order by endInterval desc)
into #t
from cubes.dm_FedorVerificationRequests_report_TTC_Common
	CROSS apply times_from_interval2 ([Дата статуса], [Дата след.статуса], 60)
where
--flag <> -2
--and 
--([Дата заведения заявки] > dateadd(day, -10, getdate()) OR @RequestNumber IS NOT NULL)
([Дата заведения заявки] > dateadd(day, -10, getdate()) OR @mode <> 0)
----and [Номер заявки] = '21030600085767'
and 
beginInterval is not null
	--AND ([Номер заявки] = @RequestNumber OR @RequestNumber IS NULL)
	AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1  FROM #t_Request AS R WHERE R.RequestNumber = [Номер заявки]))


--insert into #t
--select * from #t

drop table if exists #t3

select [Номер заявки], ШагЗаявки, Sum(День) ЗатраченоДень, Sum(Ночь) ЗатраченоНочь, max(flagBeginInterval) flagBeginInterval, getdate() ДатаЗаписи 
--, max([Дата след.статуса]) [Дата след.статуса], max(endInterval) endInterval
into #t3
from #t
group by [Номер заявки], ШагЗаявки


delete f from [dwh2].[cubes].[dm_FedorVerificationRequests_DayInterval_Common] f
 join #t3 t on f.ШагЗаявки = t.ШагЗаявки and f.[Номер заявки] = t.[Номер заявки]

insert into [dwh2].[cubes].[dm_FedorVerificationRequests_DayInterval_Common] 
([Номер заявки], ШагЗаявки,ЗатраченоДень,  ЗатраченоНочь, flagBeginInterval, ДатаЗаписи)
select [Номер заявки], ШагЗаявки,ЗатраченоДень,  ЗатраченоНочь, flagBeginInterval, ДатаЗаписи
--into [dwh2].[cubes].[dm_FedorVerificationRequests_DayInterval_Common] 
 from #t3

 -- материализация детализации
 -- эта таблица используется в кубе
 --drop table if exists [dwh2].[cubes].[dm_FedorVerificationRequests_cube_TTC_Common]

--DWH-1764
--IF @RequestNumber IS NULL
IF @mode = 0
BEGIN
	TRUNCATE TABLE cubes.dm_FedorVerificationRequests_cube_TTC_Common
END
ELSE BEGIN
	DELETE D
	FROM cubes.dm_FedorVerificationRequests_cube_TTC_Common AS D
	--WHERE D.[Номер заявки] = @RequestNumber
	WHERE EXISTS(SELECT TOP(1) 1  FROM #t_Request AS R WHERE R.RequestNumber = D.[Номер заявки])
END


INSERT cubes.dm_FedorVerificationRequests_cube_TTC_Common
(
	ProductType_Code,
    [Дата заведения заявки],
    [Время заведения],
    [Номер заявки],
    [ФИО клиента],
    [Статус],
    [Задача],
    [Состояние заявки],
    [Дата статуса],
    [Дата_статусаТекущая],
    [Дата след.статуса],
    [Дата_статуса_следующая],
    [ФИО сотрудника верификации/чекер],
    [ВремяЗатрачено],
    [Время, час:мин:сек],
    [Статус следующий],
    [Задача следующая],
    [Состояние заявки следующая],
    [ПричинаНаим_Исх],
    [ПричинаНаим_След],
    [Последнее состояние заявки на дату по сотруднику],
    [Последний статус заявки на дату по сотруднику],
    [Последний статус заявки на дату],
    [СотрудникПоследнегоСтатуса],
    [ШагЗаявки],
    [ПоследнийШаг],
    [Последний статус заявки],
    [Время в последнем статусе],
    [Время в последнем статусе, hh:mm:ss],
    [ВремяЗатраченоОжиданиеВерификацииКлиента],
    [ДоработкаКД],
    [ДоработкаКДПоследнийШаг],
    [ОтложенаКД],
    [ОтложенаКДПоследнийШаг],
    [ОтказаноКД],
    [ВК_КД],
    [НоваяКД],
    [В_работеКД],
    [СотрудникКД],
    [СотрудникВК],
    [Показатель],
    [Статус_TTC],
    [ПризнакВыдан],
    [ПризнакПодписан],
    [ДатаВремяЗаведенияЗаявки],
    [ДляОтчетаТТС],
    [ПорядокTTC],
    [РасчетВремени],
    [Клиентское время],
    [Системное время],
    [Верификационное время],
    [Канал от источника],
    [Группа каналов],
    [Вид займа],
    [ИспытательныйСрок],
    [Продукт],
    [Время суток],
    [ДатаПодписан],
    [ДатаВыдан],
    [ПризнакВыданДеньЗаведения],
    [ЗатраченоДень],
    [ЗатраченоНочь],
    [ПризнакРаботыВремяСуток],
    [Клиентское время hh mm ss],
    [Системное время hh mm ss],
    [Верификационное время hh mm ss],
    [ПризнакИсключенияСотрудника],
	Автоодобрение,
	Статус_TTC_РасчетВремени
)
 SELECT
	f.ProductType_Code,
	[Дата заведения заявки], [Время заведения], f.[Номер заявки], [ФИО клиента]
, case when Статус  =N'Предварительное одобрение' then N'Предварительное одобрение (ожидание фото клиента)'
       when Статус  =N'Верификация КЦ' then N'Верификация КЦ (Сall 0, логином)'
	   else Статус
  end as Статус
, Задача, [Состояние заявки], [Дата статуса], Дата_статусаТекущая, [Дата след.статуса]
, Дата_статуса_следующая, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]
, case when [Статус следующий]  =N'Предварительное одобрение' then N'Предварительное одобрение (ожидание фото клиента)'
       when [Статус следующий]  =N'Верификация КЦ' then N'Верификация КЦ (Сall 0, логином)'
	   else [Статус следующий]
  end as [Статус следующий]
, [Задача следующая]
, [Состояние заявки следующая], ПричинаНаим_Исх, ПричинаНаим_След, [Последнее состояние заявки на дату по сотруднику]
, case when [Последний статус заявки на дату по сотруднику]  =N'Предварительное одобрение' then N'Предварительное одобрение (ожидание фото клиента)'
       when [Последний статус заявки на дату по сотруднику]  =N'Верификация КЦ' then N'Верификация КЦ (Сall 0, логином)'
	   else [Последний статус заявки на дату по сотруднику]
  end as [Последний статус заявки на дату по сотруднику]
, case when [Последний статус заявки на дату]  =N'Предварительное одобрение' then N'Предварительное одобрение (ожидание фото клиента)'
       when [Последний статус заявки на дату]  =N'Верификация КЦ' then N'Верификация КЦ (Сall 0, логином)'
	   else [Последний статус заявки на дату]
  end as [Последний статус заявки на дату], СотрудникПоследнегоСтатуса
 , f.ШагЗаявки
 , ПоследнийШаг
, case when [Последний статус заявки]  =N'Предварительное одобрение' then N'Предварительное одобрение (ожидание фото клиента)'
       when [Последний статус заявки]  =N'Верификация КЦ' then N'Верификация КЦ (Сall 0, логином)'
	   else [Последний статус заявки]
  end as  [Последний статус заявки], [Время в последнем статусе]
  ,  cast(
        (cast([Время в последнем статусе] as int) * 24) /* hours over 24 */
        + datepart(hh, [Время в последнем статусе]) /* hours */
        as varchar(10))
    + ':' + right('0' + cast(datepart(mi, [Время в последнем статусе]) as varchar(2)), 2) /* minutes */
    + ':' + right('0' + cast(datepart(ss, [Время в последнем статусе]) as varchar(2)), 2) /* seconds */ [Время в последнем статусе, hh:mm:ss], ВремяЗатраченоОжиданиеВерификацииКлиента, ДоработкаКД, 
                         ДоработкаКДПоследнийШаг, ОтложенаКД, ОтложенаКДПоследнийШаг, ОтказаноКД, ВК_КД, НоваяКД, В_работеКД, СотрудникКД, СотрудникВК, Показатель
, case when Статус_TTC  =N'Предварительное одобрение' then N'Предварительное одобрение (ожидание фото клиента)'
       when Статус_TTC  =N'Верификация КЦ' then N'Верификация КЦ (Сall 0, логином)'
	   else Статус_TTC
  end as Статус_TTC
,                        ПризнакВыдан, ПризнакПодписан, ДатаВремяЗаведенияЗаявки, ДляОтчетаТТС, ПорядокTTC, РасчетВремени, [Клиентское время], [Системное время], 
                         [Верификационное время], [Канал от источника], [Группа каналов], [Вид займа], ИспытательныйСрок, Продукт, [Время суток], ДатаПодписан, ДатаВыдан
, ПризнакВыданДеньЗаведения = iif([Дата заведения заявки] is not null, iif(cast(ДатаПодписан as date) = cast([Дата заведения заявки] as date),'Да','Нет'),'Не выдан')
, ЗатраченоДень
, ЗатраченоНочь
, ПризнакРаботыВремяСуток =
case 	
	when ЗатраченоДень = 0  and ЗатраченоНочь > 0 then 'Только ночь'
	when ЗатраченоДень > 0  and ЗатраченоНочь = 0 then 'Только день'
	when ЗатраченоДень = 0  and ЗатраченоНочь = 0  and flagBeginInterval = 'День' then 'Только день'
	when ЗатраченоДень = 0  and ЗатраченоНочь = 0  and flagBeginInterval = 'Ночь' then 'Только ночь'
	when ЗатраченоДень > 0  and ЗатраченоНочь > 0 then 'День и Ночь'
	else 'Не определено'
end
, cast(
        (cast([Клиентское время hh mm ss] as int) * 24) /* hours over 24 */
        + datepart(hh, [Клиентское время hh mm ss]) /* hours */
        as varchar(10))
    + ':' + right('0' + cast(datepart(mi, [Клиентское время hh mm ss]) as varchar(2)), 2) /* minutes */
    + ':' + right('0' + cast(datepart(ss, [Клиентское время hh mm ss]) as varchar(2)), 2) /* seconds */ [Клиентское время hh mm ss] 
, cast(
        (cast([Системное время hh mm ss] as int) * 24) /* hours over 24 */
        + datepart(hh, [Системное время hh mm ss]) /* hours */
        as varchar(10))
    + ':' + right('0' + cast(datepart(mi, [Системное время hh mm ss]) as varchar(2)), 2) /* minutes */
    + ':' + right('0' + cast(datepart(ss, [Системное время hh mm ss]) as varchar(2)), 2) /* seconds */ [Системное время hh mm ss] 
, cast(
        (cast([Верификационное время hh mm ss] as int) * 24) /* hours over 24 */
        + datepart(hh, [Верификационное время hh mm ss]) /* hours */
        as varchar(10))
    + ':' + right('0' + cast(datepart(mi, [Верификационное время hh mm ss]) as varchar(2)), 2) /* minutes */
    + ':' + right('0' + cast(datepart(ss, [Верификационное время hh mm ss]) as varchar(2)), 2) /* seconds */ [Верификационное время hh mm ss] 
	, [ПризнакИсключенияСотрудника]
	, f.Автоодобрение
	, Статус_TTC_РасчетВремени = concat(f.Статус_TTC, '.', f.РасчетВремени)
--into [dwh2].[cubes].[dm_FedorVerificationRequests_cube_TTC_Common]
--#vc_FedorVerificationRequests_tmp
FROM cubes.dm_FedorVerificationRequests_report_TTC_Common AS f
	LEFT join cubes.dm_FedorVerificationRequests_DayInterval_Common AS i
		ON i.[Номер заявки] = f.[Номер заявки] and i.ШагЗаявки = f.ШагЗаявки
WHERE 1=1
	--AND (f.[Номер заявки] = @RequestNumber OR @RequestNumber IS NULL)
	AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1  FROM #t_Request AS R WHERE R.RequestNumber = f.[Номер заявки]))


-- drop table if exists reports.dbo.dm_FedorVerificationRequestsDetail_Common

 --DWH-1764
--IF @RequestNumber IS NULL
IF @mode = 0
BEGIN
	TRUNCATE TABLE Reports.dbo.dm_FedorVerificationRequestsDetail_Common
END
ELSE BEGIN
	DELETE D
	FROM Reports.dbo.dm_FedorVerificationRequestsDetail_Common AS D
	--WHERE D.[Номер заявки] = @RequestNumber
	WHERE EXISTS(SELECT TOP(1) 1  FROM #t_Request AS R WHERE R.RequestNumber = D.[Номер заявки])
END

INSERT Reports.dbo.dm_FedorVerificationRequestsDetail_Common
 (
	 ProductType_Code,
     [Номер заявки],
     [ФИО клиента],
     [Дата заведения заявки],
     ПериодЗаведения,
     [Время заведения],
     [Последний статус заявки],
     [Время в последнем статусе, hh:mm:ss],
     [Канал от источника],
     [Вид займа],
     ИспытательныйСрок,
     Продукт,
     ДатаПодписан,
     ПериодВыдачи,
     ДатаВыдан,
     ПризнакВыданДеньЗаведения,
     [Клиентское время hh mm ss],
     [Системное время hh mm ss],
     [Верификационное время hh mm ss],
     Черновик,
     [Верификация КЦ (Сall 0, логином)],
     [Предварительное одобрение (ожидание фото клиента)],
     [Контроль данных Ожидание],
     [Контроль данных Отложена],
     [Контроль данных Доработка],
     [Контроль данных В работе],
     [Контроль данных Выполнена],
     [Верификация Call 1.5],
     [Ожидание подписи документов EDO],
     [Верификация Call 2],
     [Верификация клиента Ожидание],
     [Верификация клиента В работе],
     [Верификация клиента Выполнена],
     [Верификация клиента Доработка],
     [Верификация клиента Отложена],
     [Верификация Call 3],
     [Одобрен клиент],
     [Верификация ТС Ожидание],
     [Верификация ТС Доработка],
     [Верификация ТС Отложена],
     [Верификация ТС В работе],
     Одобрено,
     [Договор зарегистрирован],
     [Договор подписан],
     Итого,
	 Автоодобрение
 )
 SELECT 
	 ProductType_Code
	 , [Номер заявки]
	 , [ФИО клиента]
	 , [Дата заведения заявки]
	 , ПериодЗаведения= cast(Format([Дата заведения заявки],'yyyy-MM-01') as date)
	 , [Время заведения]
	 , [Последний статус заявки] 	  
	 , [Время в последнем статусе, hh:mm:ss]
	 ,[Канал от источника]
      --,[Группа каналов]
      ,[Вид займа]
      ,[ИспытательныйСрок]
      ,[Продукт]
      --,[Время суток]
      ,cast([ДатаПодписан] as date) as [ДатаПодписан]
	  
	  , ПериодВыдачи = cast(Format([ДатаПодписан],'yyyy-MM-01') as date)
      ,[ДатаВыдан]
      ,[ПризнакВыданДеньЗаведения]
	 , [Клиентское время hh mm ss]
     , [Системное время hh mm ss]
     , [Верификационное время hh mm ss],

		[Черновик],
		[Верификация КЦ (Сall 0, логином)],
		[Предварительное одобрение (ожидание фото клиента)],
		[Контроль данных Ожидание],
		[Контроль данных Отложена],
		[Контроль данных Доработка],
		[Контроль данных В работе],
		[Контроль данных Выполнена],
		[Верификация Call 1.5],
		[Ожидание подписи документов EDO],
		[Верификация Call 2],
		[Верификация клиента Ожидание],
		[Верификация клиента В работе],
		[Верификация клиента Выполнена],
		[Верификация клиента Доработка],
		[Верификация клиента Отложена],
		[Верификация Call 3],
		[Одобрен клиент],
		[Верификация ТС Ожидание],
		[Верификация ТС Доработка],
		[Верификация ТС Отложена],
		[Верификация ТС В работе],
		[Одобрено],
		[Договор зарегистрирован],
		[Договор подписан]
		, Итого                              =   isnull([Черновик]                  ,0)                     
                                           + isnull([Верификация КЦ (Сall 0, логином)]                 ,0)
                                           + isnull([Предварительное одобрение (ожидание фото клиента)]      ,0)
                                           + isnull([Контроль данных Ожидание]       ,0)
                                           + isnull([Контроль данных Отложена]       ,0)
										   + isnull([Контроль данных Доработка]       ,0)
                                           + isnull([Контроль данных В работе]       ,0)
                                           + isnull([Контроль данных Выполнена]      ,0)
                                           + isnull([Верификация Call 1.5]           ,0)
                                           + isnull([Ожидание подписи документов EDO],0)
                                           + isnull([Верификация Call 2]             ,0)
                                           + isnull([Верификация клиента Ожидание]   ,0)
                                           + isnull([Верификация клиента В работе]   ,0)
                                           + isnull([Верификация клиента Выполнена]  ,0)
                                           + isnull([Верификация клиента Отложена]   ,0)
										   + isnull([Верификация клиента Доработка]   ,0)
                                           + isnull([Верификация Call 3]             ,0)
                                           + isnull([Одобрен клиент]                 ,0)
                                           + isnull([Верификация ТС Ожидание]        ,0)
                                           + isnull([Верификация ТС Отложена]        ,0)
										   + isnull([Верификация ТС Доработка]        ,0)
                                           + isnull([Верификация ТС В работе]        ,0)
                                           + isnull(Одобрено                         ,0)
                                           + isnull([Договор зарегистрирован]        ,0)

	,Автоодобрение		
      --into reports.dbo.dm_FedorVerificationRequestsDetail_Common
		
 FROM (SELECT  
	  ProductType_Code
	  , [Номер заявки]
	  , Статус_TTC --[Статус]
      ,cast(Sum(ВремяЗатрачено) as decimal(38,12)) as ВремяЗатрачено , [Последний статус заявки]
      ,[Клиентское время hh mm ss]
      , [Системное время hh mm ss]
      , [Верификационное время hh mm ss]
	  , v.[Время заведения]
	  , v.[Дата заведения заявки]
	  , v.[Время в последнем статусе, hh:mm:ss]
	  , v.[ФИО клиента]
	  ,[Канал от источника]
      --,[Группа каналов]
      ,[Вид займа]
      ,[ИспытательныйСрок]
      ,[Продукт]
      --,[Время суток]
      ,[ДатаПодписан]
      ,[ДатаВыдан]
      ,[ПризнакВыданДеньЗаведения]
	  ,Автоодобрение
 FROM cubes.dm_FedorVerificationRequests_cube_TTC_Common AS v
 --[dwh2].[cubes].[vc_FedorVerificationRequests] v
 WHERE 1=1
	--AND (v.[Номер заявки] = @RequestNumber OR @RequestNumber IS NULL)
	AND (@mode = 0 OR EXISTS(SELECT TOP(1) 1  FROM #t_Request AS R WHERE R.RequestNumber = v.[Номер заявки]))
	
 group by 
	  ProductType_Code
	  , [Номер заявки]
      , Статус_TTC --[Статус] 
      , [Последний статус заявки]
      , [Клиентское время hh mm ss]
      , [Системное время hh mm ss]
      , [Верификационное время hh mm ss]
	  , [Время заведения]
	  , [Дата заведения заявки]
	  , [Время в последнем статусе, hh:mm:ss]
	  , [ФИО клиента]
	  , [Канал от источника]
      --,[Группа каналов]
      , [Вид займа]
      , [ИспытательныйСрок]
      , [Продукт]
      --,[Время суток]
      , [ДатаПодписан]
      , [ДатаВыдан]
      , [ПризнакВыданДеньЗаведения]
	  , Автоодобрение
	  --, A.[Номер заявки autoapprove_VK]
--where [Номер заявки] = '21030100084113'
 ) AS h
 PIVOT
 (avg(ВремяЗатрачено) 
 FOR Статус_TTC --[Статус]
 IN(
		[Черновик],
		[Верификация КЦ (Сall 0, логином)],
		[Предварительное одобрение (ожидание фото клиента)],
		[Контроль данных Ожидание],
		[Контроль данных Отложена],
		[Контроль данных Доработка],
		[Контроль данных В работе],
		[Контроль данных Выполнена],
		[Верификация Call 1.5],
		[Ожидание подписи документов EDO],
		[Верификация Call 2],
		[Верификация клиента Ожидание],
		[Верификация клиента В работе],
		[Верификация клиента Выполнена],
		[Верификация клиента Доработка],
		[Верификация клиента Отложена],
		[Верификация Call 3],
		[Одобрен клиент],
		[Верификация ТС Ожидание],
		[Верификация ТС Доработка],
		[Верификация ТС Отложена],
		[Верификация ТС В работе],
		[Одобрено],
		[Договор зарегистрирован],
		[Договор подписан]

)
 ) pvt;

END
