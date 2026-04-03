--DWH-2456 DashBoard по беззалогу
CREATE PROC dbo.CreateDasboardFedorVerification_without_coll
	@isDebug int = 0,
	@date date = NULL
as
begin
SET NOCOUNT ON

	SELECT @isDebug = isnull(@isDebug, 0)

  declare @dt_from date=--dateadd(day,-20,
                                cast(getdate() as date)
                          --      )
  declare @dt_to date
  set @dt_to=dateadd(day,1,cast(getdate() as date))

	IF @date IS NOT NULL BEGIN
		SELECT @dt_from = @date, @dt_to = dateadd(DAY, 1, @date)
	END

	DECLARE @ProductType_Group varchar(100)
	declare @t_ProductType_Group table (ProductType_Group varchar(100))
	insert @t_ProductType_Group (ProductType_Group)
	--values
	--	('pdl,installment'),
	--	('bigInstallment')
	--DWH-412
	values
		('Installment'),
		('bigInstallment')


	drop table if exists #curr_employee_test
	create table #curr_employee_test([Employee] nvarchar(255))
	INSERT #curr_employee_test(Employee)
	/*
	--select *
	select substring(trim(U.DisplayName), 1, 255)
	FROM [dwh-ex].bot.dbo.[vw_ActiveDirectoryUsers] AS U
	where U.Department ='Отдел тестирования'
	and u.DomainAccount !='r.mekshinev' -- перешел в отдел тестирование из отдела верификации
	UNION */
	SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedor.core_user AS U
	WHERE U.IsQAUser = 1


	-- сотрудники КД
	drop table if exists #curr_employee_cd
	create table #curr_employee_cd([Employee] nvarchar(255) )
	--комментарю по DWH-1988
	--insert into #curr_employee_cd select employee from feodor.dbo.KDEmployees

	/*
	--var 1
	--DWH-1988
	INSERT #curr_employee_cd(Employee)
	SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedor.core_user AS U
		INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
		INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
			ON R.Id = UR.IdUserRole
	WHERE 1=1
		AND U.IsDeleted = 0
		AND UR.IsDeleted = 0
		AND R.Name IN ('Чекер')
	*/

	--var 2
	INSERT #curr_employee_cd(Employee)
	SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedor.core_user AS U
		INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
		INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
			ON R.Id = UR.IdUserRole
	WHERE 1=1
	--AND UR.IsDeleted = 0
		AND R.Name IN ('Чекер')
		AND concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
			NOT IN (SELECT Employee FROM #curr_employee_test)
	and 
		(
			(U.DeleteDate >= @dt_from and U.IsDeleted = 1)
			or (u.DeleteDate is null and U.IsDeleted = 0)
		)
	union 
	select Employee 
	from (
		select Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
			,DeleteDate = case id
				when '244F6B46-49D8-4E11-B68D-05C5D7A9C8BC' then '2023-03-31'
			end
		from Stg._fedor.core_user u
		where Id in('244F6B46-49D8-4E11-B68D-05C5D7A9C8BC') --Жарких Марина Павловна
	) u
	where U.DeleteDate >= @dt_from



-- Верификаторы
  drop table if exists #curr_employee_vr
  create table #curr_employee_vr([Employee] nvarchar(255) )
	--комментарю по DWH-1988
	--insert into #curr_employee_vr select employee from feodor.dbo.VEmployees
	/*
	--var 1
	--DWH-1988
	INSERT #curr_employee_vr(Employee)
	SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedor.core_user AS U
		INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
		INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
			ON R.Id = UR.IdUserRole
	WHERE 1=1
		AND U.IsDeleted = 0
		AND UR.IsDeleted = 0
		AND R.Name IN ('Верификатор')
	*/

	--var 2
	INSERT #curr_employee_vr(Employee)
	SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedor.core_user AS U
		INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
		INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
			ON R.Id = UR.IdUserRole
	WHERE 1=1
		AND R.Name IN ('Верификатор')
		AND concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
			NOT IN (SELECT Employee FROM #curr_employee_test)
		and 
		(
			(U.DeleteDate >= @dt_from and U.IsDeleted = 1)
			or (u.DeleteDate is null and U.IsDeleted = 0)
		)
	--обращение #production Екатерина Панина @eka.panina 14:42
	union 
	select Employee 
	from (
		select Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
			,DeleteDate = case id
				when '89EAED68-E616-415C-BE92-0C2D4C084899' then '2023-12-31'
				ELSE u.DeleteDate
			end
		from Stg._fedor.core_user u
		where Id in('89EAED68-E616-415C-BE92-0C2D4C084899') --Столица Вероника Игоревна
	) u
	where U.DeleteDate >= @dt_from


	drop table if exists #fedor_verificator_report

	drop table if exists #details_KD
	CREATE TABLE #details_KD
	(
		ProductType_Group varchar(100),
		ProductType_Code varchar(30) NULL,
		IdClientRequest uniqueidentifier,
		[Дата заведения заявки] [date] NULL,
		[Время заведения] [time](7) NULL,
		[Номер заявки] [nvarchar](50) NULL,
		[ФИО клиента] [nvarchar](255) NULL,
		[Статус] [nvarchar](100) NULL,
		[Задача] [nvarchar](100) NULL,
		[Состояние заявки] [nvarchar](50) NULL,
		[Дата статуса] [datetime2](7) NULL,
		[Дата след.статуса] [datetime2](7) NULL,
		[ФИО сотрудника верификации/чекер] [nvarchar](255) NULL,
		[ВремяЗатрачено] [decimal](16, 10) NULL,
		[Время, час:мин:сек] [datetime] NULL,
		[Статус следующий] [nvarchar](100) NULL,
		[Задача следующая] [nvarchar](100) NULL,
		[Состояние заявки следующая] [nvarchar](50) NULL,
		[ПричинаНаим_Исх] [int] NULL,
		[ПричинаНаим_След] [int] NULL,
		[Последнее состояние заявки на дату по сотруднику] [nvarchar](50) NULL,
		[Последний статус заявки на дату по сотруднику] [nvarchar](100) NULL,
		[Последний статус заявки на дату] [nvarchar](100) NULL,
		[СотрудникПоследнегоСтатуса] [nvarchar](100) NULL,
		[ШагЗаявки] [bigint] NULL,
		[ПоследнийШаг] [bigint] NULL,
		[Последний статус заявки] [nvarchar](100) NULL,
		[Время в последнем статусе] [decimal](16, 10) NULL,
		[Время в последнем статусе, hh:mm:ss] [nvarchar](100) NULL,
		[ВремяЗатраченоОжиданиеВерификацииКлиента] [decimal](16, 10) NULL,
		[ПризнакИсключенияСотрудника] [int] NULL,
		[Работник] [nvarchar](100) NULL,
		[Назначен] [nvarchar](100) NULL,
		[Работник_Пред] [nvarchar](100) NULL,
		[Назначен_Пред] [nvarchar](100) NULL,
		[Работник_След] [nvarchar](100) NULL,
		[Назначен_След] [nvarchar](100) NULL,
		ТипКлиента varchar(30) NULL,
		isSkipped bit NULL
	)

	--var. 3 --DWH-2684 Объединить 2 таблицы в одну
	INSERT #details_KD
	(
		ProductType_Group,
		[ProductType_Code],
		IdClientRequest,
	    [Дата заведения заявки],
	    [Время заведения],
	    [Номер заявки],
	    [ФИО клиента],
	    Статус,
	    Задача,
	    [Состояние заявки],
	    [Дата статуса],
	    [Дата след.статуса],
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
	    ПризнакИсключенияСотрудника,
	    Работник,
	    Назначен,
	    Работник_Пред,
	    Назначен_Пред,
	    Работник_След,
	    Назначен_След,
		ТипКлиента,
		isSkipped
	)
	SELECT 
		--ProductType_Group = 
		--	case 
		--		when R.ProductType_Code in ('pdl','installment') then 'pdl,installment'
		--		when R.ProductType_Code in ('bigInstallment') then 'bigInstallment'
		--		else null
		--	end,
		--DWH-412
		ProductType_Group = v.ГруппаПродуктов_Code,
		R.ProductType_Code,
		R.IdClientRequest,
		R.[Дата заведения заявки],
        R.[Время заведения],
        R.[Номер заявки],
        R.[ФИО клиента],
        R.Статус,
        R.Задача,
        R.[Состояние заявки],
        R.[Дата статуса],
        R.[Дата след.статуса],
        R.[ФИО сотрудника верификации/чекер],
        R.ВремяЗатрачено,
        R.[Время, час:мин:сек],
        R.[Статус следующий],
        R.[Задача следующая],
        R.[Состояние заявки следующая],
        R.ПричинаНаим_Исх,
        R.ПричинаНаим_След,
        R.[Последнее состояние заявки на дату по сотруднику],
        R.[Последний статус заявки на дату по сотруднику],
        R.[Последний статус заявки на дату],
        R.СотрудникПоследнегоСтатуса,
        R.ШагЗаявки,
        R.ПоследнийШаг,
        R.[Последний статус заявки],
        R.[Время в последнем статусе],
        R.[Время в последнем статусе, hh:mm:ss],
        R.ВремяЗатраченоОжиданиеВерификацииКлиента,
        R.ПризнакИсключенияСотрудника,
        R.Работник,
        R.Назначен,
        R.Работник_Пред,
        R.Назначен_Пред,
        R.Работник_След,
        R.Назначен_След,
		R.ТипКлиента,
		R.isSkipped
	FROM dbo.dm_FedorVerificationRequests_without_coll AS R --(NOLOCK)
		--INNER JOIN Stg._fedor.core_ClientRequest AS CR
		--	ON CR.Number COLLATE Cyrillic_General_CI_AS = R.[Номер заявки]
		--DWH-412
		left join dwh2.hub.v_hub_ГруппаПродуктов as v
			on v.ПодтипПродуктd_Code = R.ProductType_Code
	WHERE 1=1
		AND ([ФИО сотрудника верификации/чекер] not in (select * from #curr_employee_vr) 
			OR [ФИО сотрудника верификации/чекер] in (select * from #curr_employee_cd)
		)
		AND([Дата статуса] > @dt_from AND [Дата статуса] < @dt_to)
		--and R.КодТипКредитногоПродукта in ('pdl','installment')

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##details_KD
		SELECT * INTO ##details_KD FROM #details_KD
	END



	--request numbers
	DROP TABLE IF EXISTS #t_request_number_KD
	CREATE TABLE #t_request_number_KD(IdClientRequest uniqueidentifier, [Номер заявки] nvarchar(255))

	INSERT #t_request_number_KD(IdClientRequest, [Номер заявки])
	SELECT DISTINCT R.IdClientRequest, R.[Номер заявки]
	FROM #details_KD AS R
	WHERE R.[Статус] in ('Контроль данных')
		--AND R.[Дата статуса] > @dt_from
		--AND R.[Дата статуса] < @dt_to

	DROP TABLE IF EXISTS #t_checklists_rejects_KD
	CREATE TABLE #t_checklists_rejects_KD
	(
		IdClientRequest uniqueidentifier,
		Number nvarchar(255),
		CheckListItemTypeName nvarchar(255),
		CheckListItemStatusName nvarchar(255)
	)
	CREATE INDEX ix_IdClientRequest ON #t_checklists_rejects_KD(IdClientRequest)

	--Отказы Логинома --DWH-2429
	;with loginom_checklists_rejects AS(
		SELECT 
			min(try_cast(replace(cis.LoginomNumber,'.','') AS bigint))  logn,
			cli.IdClientRequest
		FROM
			[Stg].[_fedor].[core_CheckListItem] cli 
			inner JOIN [Stg].[_fedor].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
				--and cis.[IdBehavior] =2 --	Статус - хард-код, по которому откажет логином
				and cis.[IdBehavior] IN (2, 3) -- 3. В информацию по Check* выводим информацию если по заявке был отказа, не важно кем системой или верификатором
		WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number_KD AS R WHERE R.IdClientRequest = cli.IdClientRequest)
		GROUP BY cli.IdClientRequest
	)
	INSERT #t_checklists_rejects_KD
	(
	    IdClientRequest,
	    Number,
	    CheckListItemTypeName,
	    CheckListItemStatusName
	)
	SELECT 
		cli.IdClientRequest,
		CR.Number COLLATE Cyrillic_General_CI_AS,
		cit.[Name] CheckListItemTypeName,
		cis.[Name] CheckListItemStatusName
	FROM [Stg].[_fedor].[core_CheckListItem] cli
		JOIN [Stg].[_fedor].[dictionary_CheckListItemType] cit ON  cit.id = cli.IdType
		JOIN [Stg].[_fedor].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
		JOIN loginom_checklists_rejects rl ON rl.IdClientRequest = cli.IdClientRequest 
			AND try_cast(replace(cis.LoginomNumber,'.','') AS bigint) = rl.logn
		INNER JOIN Stg._fedor.core_ClientRequest AS CR
			ON CR.Id = cli.IdClientRequest
	WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number_KD AS R WHERE R.IdClientRequest = cli.IdClientRequest)

	--- количество Доработка и Отложенно, отправленных сегодня LastStage=1


         ;with 
          rework as (
          select ProductType_Group, ProductType_Code, 'Доработка' [status], cast([Дата статуса] as date) Дата, [Дата статуса], [ФИО клиента], [Номер заявки] , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_KD
           where Задача='task:Требуется доработка' and [Состояние заявки]='Отложена' and Статус in('Контроль данных') 
          )
          ,rework1 as (
          select ProductType_Group, ProductType_Code, 'Доработка' [status], cast([Дата статуса] as date) Дата, [Дата статуса], [ФИО клиента], [Номер заявки] , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 1 LastStage
            from #details_KD
           where [Задача следующая]='task:Требуется доработка' and [Состояние заявки следующая]='Отложена' and Статус in('Контроль данных') and ШагЗаявки= ПоследнийШаг
          )
          ,postpone as (
          select ProductType_Group, ProductType_Code, 'Отложена' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_KD
           where Задача='task:Отложена' and [Состояние заявки] in('Отложена') and Статус in('Контроль данных')
           )
           ,postpone1 as (
			SELECT ProductType_Group, ProductType_Code, 'Отложена' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 1 LastStage
            from #details_KD
           where [Задача следующая]='task:Отложена' and [Состояние заявки следующая] in('Отложена') and Статус in('Контроль данных') and ШагЗаявки= ПоследнийШаг
           )
           select N.ProductType_Group, N.ProductType_Code, 'Отказано' [status], cast(N.[Дата статуса] as date) Дата, N.[Дата статуса] ДатаИВремяСтатуса, N.[ФИО клиента], N.[Номер заявки], Сотрудник = N.СотрудникПоследнегоСтатуса, N.[ФИО сотрудника верификации/чекер], N.ВремяЗатрачено, N.[Время, час:мин:сек], 0 LastStage
             into #fedor_verificator_report
             from #details_KD AS N
            where [Статус следующий]='Отказано' and Статус in('Верификация Call 1.5')
				AND EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects_KD AS J WHERE J.IdClientRequest = N.IdClientRequest)
           -- 
           union all
           select * from postpone union all  select * from postpone1
           union 
           -- доработка
           select * from rework union all  select * from rework1

		/*         
		--var 1
           union 
          select ProductType_Code, 'ВК' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]   , 0 LastStage
            from #details_KD
           --where [Статус следующий]='Ожидание подписи документов EDO' and Статус in('Верификация Call 1.5')
		   --2021_12_16
		   where [Статус следующий]='Верификация клиента' and Статус in('Верификация Call 2')
		*/

		--var 2
		UNION
		select A.ProductType_Group, A.ProductType_Code, 'ВК' [status], cast(A.[Дата статуса] as date) Дата, A.[Дата статуса] ДатаИВремяСтатуса, A.[ФИО клиента], A.[Номер заявки] , A.СотрудникПоследнегоСтатуса, A.[ФИО сотрудника верификации/чекер], A.ВремяЗатрачено, A.[Время, час:мин:сек], 0 LastStage
		from #details_KD AS A
			LEFT JOIN #details_KD AS B --следующая заявка
				ON A.[Номер заявки] = B.[Номер заявки]
				AND A.ШагЗаявки = B.ШагЗаявки - 1
		where (
				A.Статус IN ('Верификация Call 1.5') 
				--[Статус следующий]='Ожидание подписи документов EDO' 
				AND A.[Статус следующий] = 'Верификация Call 2' --согласовано с Промётовым 22.12.2021
			)
			OR (
				B.Статус IN ('Переподписание первого пакета')
				AND B.[Статус следующий] = 'Верификация Call 2'
			)
			--DWH-2429 --одобрено сотрудником, но отказано автоматически
			OR (
				A.[Статус следующий]='Отказано' and A.Статус in('Верификация Call 1.5')
				AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects_KD AS J WHERE J.IdClientRequest = A.IdClientRequest)
			)

           union
          select ProductType_Group, ProductType_Code, 'Новая' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage 
            from #details_KD
           where Задача='task:Новая' and Статус in('Контроль данных')
				AND [Задача следующая] <> 'task:Автоматически отложено'
           union 
          select ProductType_Group, ProductType_Code, 'task:В работе' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_KD
           where [Задача]='task:В работе'  and Статус in('Контроль данных')
           union 
           select ProductType_Group, ProductType_Code, 'Ожидание' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_KD
          where Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and Статус in('Контроль данных')
			--DWH-2209
			--UNION
			--SELECT 'autoapprove' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек], 0 LastStage
			--FROM #details_KD
			--WHERE [Статус следующий]='Одобрено' AND Статус IN ('Верификация Call 2')
			UNION
			SELECT ProductType_Group, ProductType_Code, 'autoapprove' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек], 0 LastStage
			FROM #details_KD
			WHERE 1=1
				AND [Статус] in ('Контроль данных')
				AND isSkipped = 1

			UNION
			SELECT A.ProductType_Group, A.ProductType_Code, 'Не вернувшиеся с доработки' [status], cast(A.[Дата статуса] as date) Дата, A.[Дата статуса] ДатаИВремяСтатуса, A.[ФИО клиента], A.[Номер заявки] , A.СотрудникПоследнегоСтатуса, A.[ФИО сотрудника верификации/чекер], A.ВремяЗатрачено, A.[Время, час:мин:сек], 0 LastStage
			FROM (
					SELECT 
						K.*,
						[След Дата статуса] = lead(K.[Дата статуса],1,'2100-01-01') OVER(PARTITION BY K.[Номер заявки] ORDER BY K.[Дата статуса])
					from #details_KD AS K
					where K.Задача = 'task:Требуется доработка' 
				) AS A
				INNER JOIN 
				(
					SELECT 
						L.[Дата статуса]
						,L.[Номер заявки] 
					from #details_KD AS L
					where L.[Задача следующая] = 'task:Отменена'
				) AS B
				ON B.[Номер заявки] = A.[Номер заявки]
				AND A.[Дата статуса] < B.[Дата статуса] AND B.[Дата статуса] < A.[След Дата статуса]


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##fedor_verificator_report
		SELECT * INTO ##fedor_verificator_report FROM #fedor_verificator_report
	END
       

	drop table if exists #fedor_verificator_report_VK

	DROP table if exists #details_VK
	CREATE TABLE #details_VK
	(
		ProductType_Group varchar(100),
		ProductType_Code varchar(30) NULL,
		IdClientRequest uniqueidentifier,
		[Дата заведения заявки] [date] NULL,
		[Время заведения] [time](7) NULL,
		[Номер заявки] [nvarchar](50) NULL,
		[ФИО клиента] [nvarchar](255) NULL,
		[Статус] [nvarchar](100) NULL,
		[Задача] [nvarchar](100) NULL,
		[Состояние заявки] [nvarchar](50) NULL,
		[Дата статуса] [datetime2](7) NULL,
		[Дата след.статуса] [datetime2](7) NULL,
		[ФИО сотрудника верификации/чекер] [nvarchar](255) NULL,
		[ВремяЗатрачено] [decimal](16, 10) NULL,
		[Время, час:мин:сек] [datetime] NULL,
		[Статус следующий] [nvarchar](100) NULL,
		[Задача следующая] [nvarchar](100) NULL,
		[Состояние заявки следующая] [nvarchar](50) NULL,
		[ПричинаНаим_Исх] [int] NULL,
		[ПричинаНаим_След] [int] NULL,
		[Последнее состояние заявки на дату по сотруднику] [nvarchar](50) NULL,
		[Последний статус заявки на дату по сотруднику] [nvarchar](100) NULL,
		[Последний статус заявки на дату] [nvarchar](100) NULL,
		[СотрудникПоследнегоСтатуса] [nvarchar](100) NULL,
		[ШагЗаявки] [bigint] NULL,
		[ПоследнийШаг] [bigint] NULL,
		[Последний статус заявки] [nvarchar](100) NULL,
		[Время в последнем статусе] [decimal](16, 10) NULL,
		[Время в последнем статусе, hh:mm:ss] [nvarchar](100) NULL,
		[ВремяЗатраченоОжиданиеВерификацииКлиента] [decimal](16, 10) NULL,
		[ПризнакИсключенияСотрудника] [int] NULL,
		[Работник] [nvarchar](100) NULL,
		[Назначен] [nvarchar](100) NULL,
		[Работник_Пред] [nvarchar](100) NULL,
		[Назначен_Пред] [nvarchar](100) NULL,
		[Работник_След] [nvarchar](100) NULL,
		[Назначен_След] [nvarchar](100) NULL,
		ТипКлиента varchar(30) NULL,
		isSkipped bit NULL
	)

	--var. 3
	--DWH-2684 Объединить 2 таблицы в одну
	INSERT #details_VK
	(
		ProductType_Group,
		ProductType_Code,
		IdClientRequest,
	    [Дата заведения заявки],
	    [Время заведения],
	    [Номер заявки],
	    [ФИО клиента],
	    Статус,
	    Задача,
	    [Состояние заявки],
	    [Дата статуса],
	    [Дата след.статуса],
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
	    ПризнакИсключенияСотрудника,
	    Работник,
	    Назначен,
	    Работник_Пред,
	    Назначен_Пред,
	    Работник_След,
	    Назначен_След,
		ТипКлиента,
		isSkipped
	)
	SELECT 
		--ProductType_Group = 
		--	case 
		--		when R.ProductType_Code in ('pdl','installment') then 'pdl,installment'
		--		when R.ProductType_Code in ('bigInstallment') then 'bigInstallment'
		--		else null
		--	end,
		--DWH-412
		ProductType_Group = v.ГруппаПродуктов_Code,
		R.ProductType_Code,
		R.IdClientRequest,
		R.[Дата заведения заявки],
        R.[Время заведения],
        R.[Номер заявки],
        R.[ФИО клиента],
        R.Статус,
        R.Задача,
        R.[Состояние заявки],
        R.[Дата статуса],
        R.[Дата след.статуса],
        R.[ФИО сотрудника верификации/чекер],
        R.ВремяЗатрачено,
        R.[Время, час:мин:сек],
        R.[Статус следующий],
        R.[Задача следующая],
        R.[Состояние заявки следующая],
        R.ПричинаНаим_Исх,
        R.ПричинаНаим_След,
        R.[Последнее состояние заявки на дату по сотруднику],
        R.[Последний статус заявки на дату по сотруднику],
        R.[Последний статус заявки на дату],
        R.СотрудникПоследнегоСтатуса,
        R.ШагЗаявки,
        R.ПоследнийШаг,
        R.[Последний статус заявки],
        R.[Время в последнем статусе],
        R.[Время в последнем статусе, hh:mm:ss],
        R.ВремяЗатраченоОжиданиеВерификацииКлиента,
        R.ПризнакИсключенияСотрудника,
        R.Работник,
        R.Назначен,
        R.Работник_Пред,
        R.Назначен_Пред,
        R.Работник_След,
        R.Назначен_След,
		R.ТипКлиента,
		R.isSkipped
	FROM dbo.dm_FedorVerificationRequests_without_coll AS R --(NOLOCK)
		--INNER JOIN Stg._fedor.core_ClientRequest AS CR
		--	ON CR.Number COLLATE Cyrillic_General_CI_AS = R.[Номер заявки]
		--DWH-412
		left join dwh2.hub.v_hub_ГруппаПродуктов as v
			on v.ПодтипПродуктd_Code = R.ProductType_Code
	WHERE 1=1
		AND ([ФИО сотрудника верификации/чекер] not in (select * from #curr_employee_cd)
			OR [ФИО сотрудника верификации/чекер] in (select * from #curr_employee_vr)
		)
		AND [Дата статуса] > @dt_from AND [Дата статуса] < @dt_to
		--and R.КодТипКредитногоПродукта in ('pdl','installment')

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##details_VK
		SELECT * INTO ##details_VK FROM #details_VK

		--RETURN 0
	END


	--request numbers
	DROP TABLE IF EXISTS #t_request_number_VK
	CREATE TABLE #t_request_number_VK(IdClientRequest uniqueidentifier, [Номер заявки] nvarchar(255))

	INSERT #t_request_number_VK(IdClientRequest, [Номер заявки])
	SELECT DISTINCT R.IdClientRequest, R.[Номер заявки]
	FROM #details_VK AS R

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_request_number_VK
		SELECT * INTO ##t_request_number_VK FROM #t_request_number_VK
	END

	DROP TABLE IF EXISTS #t_checklists_rejects_VK
	CREATE TABLE #t_checklists_rejects_VK
	(
		IdClientRequest uniqueidentifier,
		Number nvarchar(255),
		CheckListItemTypeName nvarchar(255),
		CheckListItemStatusName nvarchar(255)
	)
	CREATE INDEX ix_IdClientRequest ON #t_checklists_rejects_VK(IdClientRequest)

	--Отказы Логинома --DWH-2429
	;with loginom_checklists_rejects AS(
		SELECT 
			min(try_cast(replace(cis.LoginomNumber,'.','') AS bigint))  logn,
			cli.IdClientRequest
		FROM
			[Stg].[_fedor].[core_CheckListItem] cli 
			inner JOIN [Stg].[_fedor].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
				--and cis.[IdBehavior] =2 --	Статус - хард-код, по которому откажет логином
				and cis.[IdBehavior] IN (2, 3) -- 3. В информацию по Check* выводим информацию если по заявке был отказа, не важно кем системой или верификатором
		WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number_VK AS R WHERE R.IdClientRequest = cli.IdClientRequest)
		GROUP BY cli.IdClientRequest
	)
	INSERT #t_checklists_rejects_VK
	(
	    IdClientRequest,
	    Number,
	    CheckListItemTypeName,
	    CheckListItemStatusName
	)
	SELECT 
		cli.IdClientRequest,
		CR.Number COLLATE Cyrillic_General_CI_AS,
		cit.[Name] CheckListItemTypeName,
		cis.[Name] CheckListItemStatusName
	FROM [Stg].[_fedor].[core_CheckListItem] cli
		JOIN [Stg].[_fedor].[dictionary_CheckListItemType] cit ON  cit.id = cli.IdType
		JOIN [Stg].[_fedor].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
		JOIN loginom_checklists_rejects rl ON rl.IdClientRequest = cli.IdClientRequest 
			AND try_cast(replace(cis.LoginomNumber,'.','') AS bigint) = rl.logn
		INNER JOIN Stg._fedor.core_ClientRequest AS CR
			ON CR.Id = cli.IdClientRequest
	WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number_VK AS R WHERE R.IdClientRequest = cli.IdClientRequest)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_checklists_rejects_VK
		SELECT * INTO ##t_checklists_rejects_VK FROM #t_checklists_rejects_VK
	END



         ;with
          rework as (
          select ProductType_Group, ProductType_Code, 'Доработка' [status], cast([Дата статуса] as date) Дата, [Дата статуса] , [ФИО клиента], [Номер заявки] , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_VK 
           where Задача='task:Требуется доработка' and [Состояние заявки]='Отложена' and Статус in('Верификация клиента') 
          )
          ,rework1 as (
          select ProductType_Group, ProductType_Code, 'Доработка' [status], cast([Дата статуса] as date) Дата, [Дата статуса], [ФИО клиента], [Номер заявки] , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 1 LastStage
            from #details_VK
           where [Задача следующая]='task:Требуется доработка' and [Состояние заявки следующая]='Отложена' and Статус in('Верификация клиента') and ШагЗаявки= ПоследнийШаг
          
          )
        ,postpone1 as (
           select ProductType_Group, ProductType_Code, 'Отложена' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_VK
           where Задача='task:Отложена' and [Состояние заявки] in('Отложена') and Статус in('Верификация клиента') 
        )
       ,postpone as (
           select ProductType_Group, ProductType_Code, 'Отложена' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 1 LastStage
             from #details_VK
            where  [Задача следующая]='task:Отложена' and [Состояние заявки следующая] in('Отложена') and Статус in('Верификация клиента') and ШагЗаявки= ПоследнийШаг
        )
           -- доработка
          select ProductType_Group, ProductType_Code, [status],  Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек] , 0 LastStage  
            into #fedor_verificator_report_VK
            from rework
           union all 
          select ProductType_Group, ProductType_Code, [status], Дата, [Дата статуса], [ФИО клиента], [Номер заявки]  , Сотрудник, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек] , 1 LastStage   from rework1
           union 
          select * from postpone 
		  UNION
		  SELECT * from postpone1
           union 
          select N.ProductType_Group, N.ProductType_Code, 'Отказано' [status], cast(N.[Дата статуса] as date) Дата, N.[Дата статуса] ДатаИВремяСтатуса, N.[ФИО клиента], N.[Номер заявки], Сотрудник = N.СотрудникПоследнегоСтатуса, N.[ФИО сотрудника верификации/чекер], N.ВремяЗатрачено, N.[Время, час:мин:сек], 0 LastStage
            from #details_VK AS N
           where [Статус следующий]='Отказано' and Статус in('Верификация Call 3')
				AND EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects_VK AS J WHERE J.IdClientRequest = N.IdClientRequest)
				AND N.СотрудникПоследнегоСтатуса in (select * from #curr_employee_vr)
		   /*
		   --var 1
           union 
          select ProductType_Code, 'VTS' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]   , 0 LastStage
            from #details_VK AS D
           --where [Статус следующий]='Одобрен клиент' and Статус in('Верификация Call 3')
		   --2021_12_16
		   where 1=1
				--AND [Статус следующий]='Одобрено' and Статус in('Верификация Call 3')
				AND D.Статус IN ('Верификация Call 3')
	   			AND EXISTS(
					SELECT TOP(1) 1
					FROM #details_VK AS N
					WHERE D.[Номер заявки] = N.[Номер заявки]
						AND N.[Дата статуса] >= D.[Дата статуса]
						AND N.[Статус следующий] IN ('Одобрено', 'Предодобр перед Call 5')
				)
			*/
			--var 2
			union 
			select ProductType_Group, ProductType_Code, 'VTS' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]   , 0 LastStage
			from #details_VK AS D
			where 
			(
				(
				D.Статус in('Верификация Call 3')
				AND EXISTS(
						SELECT TOP(1) 1
						FROM #details_VK AS N
						WHERE D.[Номер заявки] = N.[Номер заявки]
							AND N.[Дата статуса] >= D.[Дата статуса]
							AND N.[Статус следующий] IN ('Одобрено', 'Предодобр перед Call 5')
					)
				)
				--DWH-2429 --одобрено сотрудником, но отказано автоматически
				OR (
					D.[Статус следующий]='Отказано' and D.Статус IN ('Верификация Call 3')
					AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects_VK AS J WHERE J.IdClientRequest = D.IdClientRequest)
				)
			)
			AND D.СотрудникПоследнегоСтатуса in (select * from #curr_employee_vr)

           union 
          select ProductType_Group, ProductType_Code, 'task:В работе' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_VK
             where [Задача]='task:В работе'  and Статус in('Верификация клиента')
           union
          select ProductType_Group, ProductType_Code, 'Новая' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]   , 0 LastStage
            from #details_VK
           where Задача='task:Новая' 
			AND Статус in(
					'Верификация клиента',
					'Переподписание первого пакета' --DWH-2101
				)
				AND [Задача следующая] <> 'task:Автоматически отложено'

           union all
           select ProductType_Group, ProductType_Code, 'Ожидание' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_VK
          where Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and Статус in('Верификация клиента')
			--DWH-2209
			--UNION ALL
			--SELECT 'autoapprove' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек], 0 LastStage
			--FROM #details_VK
			--WHERE [Статус следующий]='Одобрено' AND Статус IN ('Верификация Call 2')
			UNION ALL
			SELECT ProductType_Group, ProductType_Code, 'autoapprove' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек], 0 LastStage
			FROM #details_VK
			WHERE 1=1
				AND [Статус] in ('Верификация клиента')
				AND isSkipped = 1

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##fedor_verificator_report_VK
		SELECT * INTO ##fedor_verificator_report_VK FROM #fedor_verificator_report_VK
		--RETURN 0
	END

	--DWH-1764

	TRUNCATE TABLE dbo.dashboard_Verification_fedor_details_without_coll

	INSERT dbo.dashboard_Verification_fedor_details_without_coll
	(
		stage,
		stage_status,
		ProductType_Group,
		ProductType_Code, 
		status,
		Дата,
		ДатаИВремяСтатуса,
		[ФИО клиента],
		[Номер заявки],
		Сотрудник,
		[ФИО сотрудника верификации/чекер],
		ВремяЗатрачено,
		[Время, час:мин:сек],
		LastStage
	)
	select 'KD' stage, stage_status='All',*  FROM  #fedor_verificator_report r
	union all select 'KD' stage, stage_status='Отложена',*  from  #fedor_verificator_report r  where   status='Отложена' 
	union all select 'KD' stage, stage_status='Доработка',*  from  #fedor_verificator_report r  where   status='Доработка' 
	union all select 'KD' stage, stage_status='В работе',*  from  #fedor_verificator_report r  where   status='task:В работе' 
	union all select 'KD' stage, stage_status='Ожидание',*  from  #fedor_verificator_report r  where   status='Ожидание' 
 
	union all select 'VK' stage, stage_status='All',*  from  #fedor_verificator_report_VK  r
	union all select 'VK' stage, stage_status='Отложена',*  from  #fedor_verificator_report_VK r  where   status='Отложена' 
	union all select 'VK' stage, stage_status='Доработка',*  from  #fedor_verificator_report_VK r  where   status='Доработка' 
	union all select 'VK' stage, stage_status='В работе',*  from  #fedor_verificator_report_VK r  where   status='task:В работе' 
	union all select 'VK' stage, stage_status='Ожидание',*  from  #fedor_verificator_report_VK r  where   status='Ожидание' 



	DROP table if exists #waitTime

	;with r AS (
		select 
			r.ProductType_Group
			, r.ProductType_Code
			, [Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
			, [Дата статуса]
			, [Дата след.статуса]
			,Работник [ФИО сотрудника верификации/чекер]
			, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику],  [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]
		FROM #details_KD AS r
		where [Состояние заявки]='Ожидание'
		and r.Статус='Контроль данных'
		--DWH-2019
		AND NOT (
			r.Задача='task:Новая'
			AND r.[Задача следующая] = 'task:Автоматически отложено'
		)
		--and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to 
		AND (
			Работник in (select e.Employee FROM #curr_employee_cd AS e)
			-- для учета, когда ожидание назначено на сотрудника
			OR Назначен in (select e.Employee from #curr_employee_cd e)
		)
	)
	--select 
	--	r.ProductType_Code
	--	, [Дата статуса]=cast([Дата статуса] as date)
	--	, avg( datediff(second,[Дата статуса], [Дата след.статуса])) duration
	--into #waitTime
	--from r
	--where datediff(second,[Дата статуса], [Дата след.статуса])>0
	--group by r.ProductType_Code, cast([Дата статуса] as date)
	select 
		ProductType_Group,
		duration = avg(datediff(second,[Дата статуса], [Дата след.статуса]))
	into #waitTime
	from r
	where datediff(second,[Дата статуса], [Дата след.статуса]) > 0
	group by ProductType_Group



	DROP table if exists #waitTime_v

	;with r AS (
	select 
		r.ProductType_Group
		, r.ProductType_Code
		, [Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
		, [Дата статуса]
		, [Дата след.статуса]
		, Работник [ФИО сотрудника верификации/чекер]
		, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику], [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]
	FROM #details_VK AS r
	where r.[Состояние заявки]='Ожидание' 
		and r.Статус='Верификация клиента' 
		--DWH-2019
		AND NOT (
			r.Задача='task:Новая'
			AND r.[Задача следующая] = 'task:Автоматически отложено'
		)
		--and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
		and (Работник in (select e.Employee FROM #curr_employee_vr AS e)
		-- для учета, когда ожидание назначено на сотрудника
		or Назначен in (select e.Employee from #curr_employee_vr AS e))
	)
	--SELECT
	--r.ProductType_Code
	--, [Дата статуса]=cast([Дата статуса] as date) 
	----  , [Номер заявки]
	--, avg( datediff(second,[Дата статуса], [Дата след.статуса]))  duration
	--into #waitTime_v
	--from  r
	--where  datediff(second,[Дата статуса], [Дата след.статуса])>0
	--group by r.ProductType_Code, cast([Дата статуса] as date)-- ,[Номер заявки]
	SELECT 
		ProductType_Group,
		duration = avg( datediff(second,[Дата статуса], [Дата след.статуса]))  
	into #waitTime_v
	from r
	where datediff(second,[Дата статуса], [Дата след.статуса]) > 0
	group by ProductType_Group


	--#waitTime_KD_VK
	DROP table if exists #waitTime_KD_VK
	;with r AS (
		select 
			r.ProductType_Group
			, r.ProductType_Code
			, [Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
			, [Дата статуса]
			, [Дата след.статуса]
			,Работник [ФИО сотрудника верификации/чекер]
			, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику],  [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]
		FROM #details_KD AS r
		where [Состояние заявки]='Ожидание'
		and r.Статус='Контроль данных'
		--DWH-2019
		AND NOT (
			r.Задача='task:Новая'
			AND r.[Задача следующая] = 'task:Автоматически отложено'
		)
		--and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to 
		AND (
			Работник in (select e.Employee FROM #curr_employee_cd AS e)
			-- для учета, когда ожидание назначено на сотрудника
			OR Назначен in (select e.Employee from #curr_employee_cd e)
		)
		UNION ALL
		select 
			r.ProductType_Group
			, r.ProductType_Code
			, [Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
			, [Дата статуса]
			, [Дата след.статуса]
			, Работник [ФИО сотрудника верификации/чекер]
			, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику], [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]
		FROM #details_VK AS r
		where r.[Состояние заявки]='Ожидание' 
			and r.Статус='Верификация клиента' 
			--DWH-2019
			AND NOT (
				r.Задача='task:Новая'
				AND r.[Задача следующая] = 'task:Автоматически отложено'
			)
			--and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
			and (Работник in (select e.Employee FROM #curr_employee_vr AS e)
			-- для учета, когда ожидание назначено на сотрудника
			or Назначен in (select e.Employee from #curr_employee_vr AS e))
	)
	SELECT 
		ProductType_Group,
		duration = avg( datediff(second,[Дата статуса], [Дата след.статуса]))  
	into #waitTime_KD_VK
	from r
	where datediff(second,[Дата статуса], [Дата след.статуса]) > 0
	group by ProductType_Group


	TRUNCATE TABLE dbo.dashboard_Verification_fedor_without_coll

	--var 1
	/*
	insert into dbo.dashboard_Verification_fedor_without_coll
	(
		rdate,
		Уникальное_количество_заявок_КД,
		Отложено_количество_заявок_КД,
		Отправлено_в_доработку_количество_заявок_КД,
		Ср_время_рассмотрения_КД_день,
		Ср_время_Ожидания_КД_день,
		Ср_время_рассмотрения_КД_час,
		Ср_время_Ожидания_КД_час,
		Уровень_одобрения_КД,
		Уникальное_количество_заявок_ВК,
		Отложено_количество_заявок_ВК,
		Отправлено_в_доработку_количество_заявок_ВК,
		Ср_время_рассмотрения_ВК_день,
		Ср_время_Ожидания_ВК_день,
		Ср_время_рассмотрения_ВK_час,
		Ср_время_Ожидания_ВK_час,
		Уникальное_количество_заявок_ТС,
		Отложено_количество_заявок_ТС,
		Отправлено_в_доработку_количество_заявок_ТС,
		Ср_время_рассмотрения_ТС_день,
		Ср_время_Ожидания_ТС_день,
		Ср_время_рассмотрения_ТС_час,
		Ср_время_Ожидания_ТС_час,
		Ср_время_рассмотрения_ВК_ТС_день,
		Ср_время_рассмотрения_ВК_ТС_час,
		Уровень_одобрения_ВК_ТС,
		Ср_время_рассмотрения_КД_ВК_ТС_день,
		Ср_время_Ожидания_КД_ВК_ТС_день,
		--Уникальное_количество_autoapprove,
		--Заявки_autoapprove_perc
		Уникальное_количество_autoapprove_KD,
		Заявки_autoapprove_KD_perc,
		Уникальное_количество_autoapprove_VK,
		Заявки_autoapprove_VK_perc
	)
	select 
		[rdate]	= getdate()

		, [Уникальное_количество_заявок_КД] = cast(format( (
			SELECT count(distinct [Номер заявки])
			FROM #fedor_verificator_report 
			WHERE status ='Новая'
			) ,'0') as nvarchar(50))

        , [Отложено_количество_заявок_КД] = cast(
			format((
				select count(distinct [Номер заявки] )
				from #fedor_verificator_report
				where status='Отложена'  and LastStage=1
				)
			,'0') as nvarchar(50)
		)

        , [Отправлено_в_доработку_количество_заявок_КД] = cast(
			format((
				select count(distinct [Номер заявки] )
				from #fedor_verificator_report
				where status='Доработка' and LastStage=1
				) 
			,'0') as nvarchar(50)
		)

		, [Ср_время_рассмотрения_КД_день] =
			format(cast(
			CASE 
			WHEN (
				select count([Номер заявки]) 
				FROM #fedor_verificator_report 
				where status in ('task:В работе')
				)<>0
			THEN 
			( (
				select sum([ВремяЗатрачено]) 
				from #fedor_verificator_report 
				where status in ('task:В работе')
				)
			/ (
				select count([Номер заявки]) 
				FROM #fedor_verificator_report 
				where status in ('task:В работе')
				)
			)
			ELSE 0
			END as datetime), N'HH:mm:ss')

		, [Ср_время_Ожидания_КД_день] =
		cast(
			(
				SELECT
					format(W.duration/60/60 ,'00') + N':'+
					format((duration/60 - 60 * (duration/60/60)),'00') + N':'+
					format((w.duration - 60 * (duration/60)),'00')
				FROM #waitTime AS W
			)
			as nvarchar(50)
		)

        , [Ср_время_рассмотрения_КД_час] = format(cast(
			case when  
					(
						select count(distinct [Номер заявки])
						from #details_KD
						where [Статус] = 'Контроль данных' 
							and [Задача] = 'task:В работе'
							and [Дата статуса]>=dateadd(hh ,-1 ,getdate())
					)<>0
				then 
					(
						select sum([ВремяЗатрачено])
						from #details_KD
						where [Статус] = 'Контроль данных'
							and [Задача] = 'task:В работе'
							and [Дата статуса]>=dateadd(hh ,-1 ,getdate())
					)
					/
					(
						select count(distinct [Номер заявки])
						from #details_KD
						where [Статус] = 'Контроль данных'
							and [Задача] = 'task:В работе' and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
				else 0
			end
			as datetime), N'HH:mm:ss')

	   , [Ср_время_Ожидания_КД_час] = format(cast(
            case when  
                    (select count(distinct [Номер заявки])  from #details_KD  where [Статус] = 'Контроль данных' and  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
                then 
                    (select sum([ВремяЗатрачено]) from #details_KD  where [Статус] = 'Контроль данных' and  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                    /
                    (select count(distinct [Номер заявки])  from #details_KD  where [Статус] = 'Контроль данных' and  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                else 0
            end
            as datetime), N'HH:mm:ss')

		, [Уровень_одобрения_КД] = 
			CASE 
				WHEN (select count([Номер заявки]) FROM #fedor_verificator_report where status IN ('ВК','Отказано','Не вернувшиеся с доработки')) <> 0 
				THEN 1.0 * (select count([Номер заявки]) FROM #fedor_verificator_report where status='ВК' )
				/ (select count([Номер заявки]) FROM #fedor_verificator_report where status IN ('ВК','Отказано','Не вернувшиеся с доработки'))
				ELSE 0.0 
			END

        , [Уникальное_количество_заявок_ВК] = 
		cast(
			format(
				(select count([Номер заявки]) 
				FROM #fedor_verificator_report_VK 
				WHERE status = 'Новая'
				) ,'0'
			)
			AS nvarchar(50)
		)

        , [Отложено_количество_заявок_ВК]	= (
			select count(distinct [Номер заявки])
			from #fedor_verificator_report_vk
			where status='Отложена' and LastStage=1   
		)

        , [Отправлено_в_доработку_количество_заявок_ВК]	= (
			select count(distinct [Номер заявки])
			from #fedor_verificator_report_vk
			where status='Доработка'  and LastStage=1 
		)

        , [Ср_время_рассмотрения_ВК_день] = 
		format(cast(
			case when	
				(select count([Номер заявки]) FROM #fedor_verificator_report_VK where status in ('task:В работе')) <>0
				then
				((select sum([ВремяЗатрачено]) from  #fedor_verificator_report_vk where status in ('task:В работе'))
				/(select count([Номер заявки]) FROM #fedor_verificator_report_VK where status in ('task:В работе'))
				)
				else 0
			end
			as datetime), N'HH:mm:ss')

        , [Ср_время_Ожидания_ВК_день] =
		cast(
			(
				SELECT
					format(W.duration/60/60 ,'00') + N':'+
					format((W.duration/60 - 60 * (W.duration/60/60)),'00') + N':'+
					format((W.duration - 60 * (W.duration/60)),'00')
				FROM #waitTime_v AS W
			)
			as nvarchar(50)
		)

        , [Ср_время_рассмотрения_ВK_час] = format(cast(
            case when  
                (select count(distinct [Номер заявки])  from #details_VK  where   [Задача] = 'task:В работе' and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
                then 
                    (select sum([ВремяЗатрачено]) from #details_VK  where  [Задача] = 'task:В работе' and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                /
                (select count(distinct [Номер заявки])  from #details_VK  where  [Задача] = 'task:В работе' and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                else 0
            end
            as datetime), N'HH:mm:ss')

		, [Ср_время_Ожидания_ВK_час] = format(cast(
            case when  
                (select count(distinct [Номер заявки])  from #details_VK  where    Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
                then 
                    (select sum([ВремяЗатрачено]) from #details_VK  where   Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                /
                (select count(distinct [Номер заявки])  from #details_VK  where  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                else 0                                                                end
            as datetime), N'HH:mm:ss')

	    , [Уникальное_количество_заявок_ТС] = 0
        , [Отложено_количество_заявок_ТС] = 0
        , [Отправлено_в_доработку_количество_заявок_ТС] = 0
		, [Ср_время_рассмотрения_ТС_день] = 0
		, [Ср_время_Ожидания_ТС_день] = 0
		, [Ср_время_рассмотрения_ТС_час] = 0
		, [Ср_время_Ожидания_ТС_час] = 0

		, [Ср_время_рассмотрения_ВК_ТС_день] = format(cast(
            case when	
                    (select   count(distinct [Номер заявки])  from  ( select * from #fedor_verificator_report_VK) q)<>0
                then
                ( (select sum([ВремяЗатрачено]) from (select * from #fedor_verificator_report_VK) q where status in ('task:В работе'))
                /  (select   count(distinct [Номер заявки])  from  ( select * from #fedor_verificator_report_VK) q)
                )
                else 0
            end
            as datetime), N'HH:mm:ss')

		, [Ср_время_рассмотрения_ВК_ТС_час] = format(cast(
			case when  
				(select count(distinct [Номер заявки])  from  #details_VK   where   [Задача] = 'task:В работе'  and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
				then 
					(select sum([ВремяЗатрачено]) from #details_VK  where  [Задача] = 'task:В работе' and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
				/
				(select count(distinct [Номер заявки])  from #details_VK  where  [Задача] = 'task:В работе'  and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
				else 0
			end
			as datetime), N'HH:mm:ss')

        , [Уровень_одобрения_ВК_ТС] =
			CASE 
				WHEN (select count([Номер заявки]) FROM #fedor_verificator_report_VK where status in('VTS','Отказано')) <> 0 
				THEN 1.0*(select count([Номер заявки]) FROM #fedor_verificator_report_VK where status='VTS')
					/ (select count([Номер заявки]) FROM #fedor_verificator_report_VK where status in('VTS','Отказано'))
				ELSE 0.0 
			END

		, [Ср_время_рассмотрения_КД_ВК_ТС_день] =
		format(cast(
			case when	
					(select count([Номер заявки]) 
					FROM (
							  SELECT * from  #fedor_verificator_report where status in ('task:В работе') 
					UNION ALL select * from #fedor_verificator_report_VK where status in ('task:В работе')
					) AS q)<>0
				then
				( (select sum([ВремяЗатрачено])
					FROM (
								  SELECT * from  #fedor_verificator_report where status in ('task:В работе')
						UNION ALL select * from #fedor_verificator_report_VK where status in ('task:В работе')
					) AS q)
					/
					(select count([Номер заявки]) 
					FROM (
							  SELECT * from  #fedor_verificator_report where status in ('task:В работе') 
					UNION ALL select * from #fedor_verificator_report_VK where status in ('task:В работе')
					) AS q)
				)
				else 0
			end
			as datetime), N'HH:mm:ss')

		, [Ср_время_Ожидания_КД_ВК_ТС_день] =
		cast(
			(
				SELECT
					format(W.duration/60/60 ,'00') + N':'+
					format((duration/60 - 60 * (duration/60/60)),'00') + N':'+
					format((w.duration - 60 * (duration/60)),'00')
				FROM #waitTime_KD_VK AS W
			)
			as nvarchar(50)
		)

		--DWH-2209
		--KD
        , Уникальное_количество_autoapprove_KD = cast(format( (
			SELECT count(DISTINCT [Номер заявки]) FROM #fedor_verificator_report AS R WHERE R.status='autoapprove'
		),'0') as nvarchar(50))

		--[% заявок autoapprove_KD от Уникальное_количество_заявок_КД]
        , Заявки_autoapprove_KD_perc =
			CASE 
				WHEN (select count(distinct [Номер заявки]) FROM #fedor_verificator_report) <> 0 
				THEN 1.0* (SELECT count(DISTINCT [Номер заявки]) FROM #fedor_verificator_report AS R WHERE R.status='autoapprove')
					/ (select count(distinct [Номер заявки]) FROM #fedor_verificator_report) 
				ELSE 0.0 
			END

		  --VK
        , Уникальное_количество_autoapprove_VK = cast(format( (
			SELECT count(DISTINCT [Номер заявки]) FROM #fedor_verificator_report_VK AS R WHERE R.status='autoapprove'
		),'0') as nvarchar(50))

		--[% заявок autoapprove_VK от Уникальное_количество_заявок_ВК]
        , Заявки_autoapprove_VK_perc = 
			CASE 
				WHEN (select count(distinct [Номер заявки] )from #fedor_verificator_report_VK) <> 0 
				THEN 1.0* (SELECT count(DISTINCT [Номер заявки]) FROM #fedor_verificator_report_VK AS R WHERE R.status='autoapprove')
					/ (select count(distinct [Номер заявки] )from #fedor_verificator_report_VK)
				ELSE 0.0 
			  END
	*/
	--// var1

	--var 2
	--цикл по @t_ProductType_Group
	DECLARE cur_ProductType_Group CURSOR FOR
	SELECT C.ProductType_Group
	FROM @t_ProductType_Group AS C
	ORDER BY C.ProductType_Group

	OPEN cur_ProductType_Group
	FETCH NEXT FROM cur_ProductType_Group INTO @ProductType_Group
	WHILE @@FETCH_STATUS = 0
	BEGIN
		;with t_fedor_verificator_report as (
			select t.*
			from #fedor_verificator_report as t
			where t.ProductType_Group = @ProductType_Group
		),
		t_waitTime as (
			select t.*
			from #waitTime as t
			where t.ProductType_Group = @ProductType_Group
		),
		t_details_KD as (
			select t.*
			from #details_KD as t
			where t.ProductType_Group = @ProductType_Group
		),
		t_fedor_verificator_report_VK as (
			select t.*
			from #fedor_verificator_report_VK as t
			where t.ProductType_Group = @ProductType_Group
		),
		t_waitTime_v as (
			select t.*
			from #waitTime_v as t
			where t.ProductType_Group = @ProductType_Group
		),
		t_details_VK as (
			select t.*
			from #details_VK as t
			where t.ProductType_Group = @ProductType_Group
		),
		t_waitTime_KD_VK as (
			select t.*
			from #waitTime_KD_VK as t
			where t.ProductType_Group = @ProductType_Group
		)
		insert into dbo.dashboard_Verification_fedor_without_coll
		(
			rdate,
			Уникальное_количество_заявок_КД,
			Отложено_количество_заявок_КД,
			Отправлено_в_доработку_количество_заявок_КД,
			Ср_время_рассмотрения_КД_день,
			Ср_время_Ожидания_КД_день,
			Ср_время_рассмотрения_КД_час,
			Ср_время_Ожидания_КД_час,
			Уровень_одобрения_КД,
			Уникальное_количество_заявок_ВК,
			Отложено_количество_заявок_ВК,
			Отправлено_в_доработку_количество_заявок_ВК,
			Ср_время_рассмотрения_ВК_день,
			Ср_время_Ожидания_ВК_день,
			Ср_время_рассмотрения_ВK_час,
			Ср_время_Ожидания_ВK_час,
			Уникальное_количество_заявок_ТС,
			Отложено_количество_заявок_ТС,
			Отправлено_в_доработку_количество_заявок_ТС,
			Ср_время_рассмотрения_ТС_день,
			Ср_время_Ожидания_ТС_день,
			Ср_время_рассмотрения_ТС_час,
			Ср_время_Ожидания_ТС_час,
			Ср_время_рассмотрения_ВК_ТС_день,
			Ср_время_рассмотрения_ВК_ТС_час,
			Уровень_одобрения_ВК_ТС,
			Ср_время_рассмотрения_КД_ВК_ТС_день,
			Ср_время_Ожидания_КД_ВК_ТС_день,
			--Уникальное_количество_autoapprove,
			--Заявки_autoapprove_perc
			Уникальное_количество_autoapprove_KD,
			Заявки_autoapprove_KD_perc,
			Уникальное_количество_autoapprove_VK,
			Заявки_autoapprove_VK_perc,
			ProductType_Group
		)
		select 
			[rdate]	= getdate()

			, [Уникальное_количество_заявок_КД] = cast(format( (
				SELECT count(distinct [Номер заявки])
				FROM t_fedor_verificator_report
				WHERE status ='Новая'
				) ,'0') as nvarchar(50))

			, [Отложено_количество_заявок_КД] = cast(
				format((
					select count(distinct [Номер заявки] )
					from t_fedor_verificator_report
					where status='Отложена'  and LastStage=1
					)
				,'0') as nvarchar(50)
			)

			, [Отправлено_в_доработку_количество_заявок_КД] = cast(
				format((
					select count(distinct [Номер заявки] )
					from t_fedor_verificator_report
					where status='Доработка' and LastStage=1
					) 
				,'0') as nvarchar(50)
			)

			, [Ср_время_рассмотрения_КД_день] =
				format(cast(
				CASE 
				WHEN (
					select count([Номер заявки]) 
					FROM t_fedor_verificator_report 
					where status in ('task:В работе')
					)<>0
				THEN 
				( (
					select sum([ВремяЗатрачено]) 
					from t_fedor_verificator_report 
					where status in ('task:В работе')
					)
				/ (
					select count([Номер заявки]) 
					FROM t_fedor_verificator_report 
					where status in ('task:В работе')
					)
				)
				ELSE 0
				END as datetime), N'HH:mm:ss')

			, [Ср_время_Ожидания_КД_день] =
			isnull(cast(
				(
					SELECT
						format(W.duration/60/60 ,'00') + N':'+
						format((W.duration/60 - 60 * (W.duration/60/60)),'00') + N':'+
						format((W.duration - 60 * (W.duration/60)),'00')
					FROM t_waitTime AS W
				)
				as nvarchar(50)
			),'00:00:00')

			, [Ср_время_рассмотрения_КД_час] = format(cast(
				case when  
						(
							select count(distinct [Номер заявки])
							from t_details_KD
							where [Статус] = 'Контроль данных' 
								and [Задача] = 'task:В работе'
								and [Дата статуса]>=dateadd(hh ,-1 ,getdate())
						)<>0
					then 
						(
							select sum([ВремяЗатрачено])
							from t_details_KD
							where [Статус] = 'Контроль данных'
								and [Задача] = 'task:В работе'
								and [Дата статуса]>=dateadd(hh ,-1 ,getdate())
						)
						/
						(
							select count(distinct [Номер заявки])
							from t_details_KD
							where [Статус] = 'Контроль данных'
								and [Задача] = 'task:В работе' and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
					else 0
				end
				as datetime), N'HH:mm:ss')

		   , [Ср_время_Ожидания_КД_час] = format(cast(
				case when  
						(select count(distinct [Номер заявки])  from t_details_KD  where [Статус] = 'Контроль данных' and  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
					then 
						(select sum([ВремяЗатрачено]) from t_details_KD  where [Статус] = 'Контроль данных' and  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
						/
						(select count(distinct [Номер заявки])  from t_details_KD  where [Статус] = 'Контроль данных' and  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
					else 0
				end
				as datetime), N'HH:mm:ss')

			, [Уровень_одобрения_КД] = 
				CASE 
					WHEN (select count([Номер заявки]) FROM t_fedor_verificator_report where status IN ('ВК','Отказано','Не вернувшиеся с доработки')) <> 0 
					THEN 1.0 * (select count([Номер заявки]) FROM t_fedor_verificator_report where status='ВК' )
					/ (select count([Номер заявки]) FROM t_fedor_verificator_report where status IN ('ВК','Отказано','Не вернувшиеся с доработки'))
					ELSE 0.0 
				END

			, [Уникальное_количество_заявок_ВК] = 
			cast(
				format(
					(select count([Номер заявки]) 
					FROM t_fedor_verificator_report_VK 
					WHERE status = 'Новая'
					) ,'0'
				)
				AS nvarchar(50)
			)

			, [Отложено_количество_заявок_ВК]	= (
				select count(distinct [Номер заявки])
				from t_fedor_verificator_report_vk
				where status='Отложена' and LastStage=1   
			)

			, [Отправлено_в_доработку_количество_заявок_ВК]	= (
				select count(distinct [Номер заявки])
				from t_fedor_verificator_report_vk
				where status='Доработка'  and LastStage=1 
			)

			, [Ср_время_рассмотрения_ВК_день] = 
			format(cast(
				case when	
					(select count([Номер заявки]) FROM t_fedor_verificator_report_VK where status in ('task:В работе')) <>0
					then
					((select sum([ВремяЗатрачено]) from  t_fedor_verificator_report_vk where status in ('task:В работе'))
					/(select count([Номер заявки]) FROM t_fedor_verificator_report_VK where status in ('task:В работе'))
					)
					else 0
				end
				as datetime), N'HH:mm:ss')

			, [Ср_время_Ожидания_ВК_день] =
			isnull(cast(
				(
					SELECT
						format(W.duration/60/60 ,'00') + N':'+
						format((W.duration/60 - 60 * (W.duration/60/60)),'00') + N':'+
						format((W.duration - 60 * (W.duration/60)),'00')
					FROM t_waitTime_v AS W
				)
				as nvarchar(50)
			),'00:00:00')

			, [Ср_время_рассмотрения_ВK_час] = format(cast(
				case when  
					(select count(distinct [Номер заявки])  from t_details_VK  where   [Задача] = 'task:В работе' and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
					then 
						(select sum([ВремяЗатрачено]) from t_details_VK  where  [Задача] = 'task:В работе' and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
					/
					(select count(distinct [Номер заявки])  from t_details_VK  where  [Задача] = 'task:В работе' and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
					else 0
				end
				as datetime), N'HH:mm:ss')

			, [Ср_время_Ожидания_ВK_час] = format(cast(
				case when  
					(select count(distinct [Номер заявки])  from t_details_VK  where    Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
					then 
						(select sum([ВремяЗатрачено]) from t_details_VK  where   Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
					/
					(select count(distinct [Номер заявки])  from t_details_VK  where  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
					else 0                                                                end
				as datetime), N'HH:mm:ss')

			, [Уникальное_количество_заявок_ТС] = 0
			, [Отложено_количество_заявок_ТС] = 0
			, [Отправлено_в_доработку_количество_заявок_ТС] = 0
			, [Ср_время_рассмотрения_ТС_день] = 0
			, [Ср_время_Ожидания_ТС_день] = 0
			, [Ср_время_рассмотрения_ТС_час] = 0
			, [Ср_время_Ожидания_ТС_час] = 0

			, [Ср_время_рассмотрения_ВК_ТС_день] = isnull(format(cast(
				case when	
						(select   count(distinct [Номер заявки])  from  ( select * from t_fedor_verificator_report_VK) q)<>0
					then
					( (select sum([ВремяЗатрачено]) from (select * from t_fedor_verificator_report_VK) q where status in ('task:В работе'))
					/  (select   count(distinct [Номер заявки])  from  ( select * from t_fedor_verificator_report_VK) q)
					)
					else 0
				end
				as datetime), N'HH:mm:ss'),'00:00:00')

			, [Ср_время_рассмотрения_ВК_ТС_час] = format(cast(
				case when  
					(select count(distinct [Номер заявки])  from  t_details_VK   where   [Задача] = 'task:В работе'  and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
					then 
						(select sum([ВремяЗатрачено]) from t_details_VK  where  [Задача] = 'task:В работе' and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
					/
					(select count(distinct [Номер заявки])  from t_details_VK  where  [Задача] = 'task:В работе'  and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
					else 0
				end
				as datetime), N'HH:mm:ss')

			, [Уровень_одобрения_ВК_ТС] =
				CASE 
					WHEN (select count([Номер заявки]) FROM t_fedor_verificator_report_VK where status in('VTS','Отказано')) <> 0 
					THEN 1.0*(select count([Номер заявки]) FROM t_fedor_verificator_report_VK where status='VTS')
						/ (select count([Номер заявки]) FROM t_fedor_verificator_report_VK where status in('VTS','Отказано'))
					ELSE 0.0 
				END

			, [Ср_время_рассмотрения_КД_ВК_ТС_день] =
			format(cast(
				case when	
						(select count([Номер заявки]) 
						FROM (
								  SELECT * from  t_fedor_verificator_report where status in ('task:В работе') 
						UNION ALL select * from t_fedor_verificator_report_VK where status in ('task:В работе')
						) AS q)<>0
					then
					( (select sum([ВремяЗатрачено])
						FROM (
									  SELECT * from  t_fedor_verificator_report where status in ('task:В работе')
							UNION ALL select * from t_fedor_verificator_report_VK where status in ('task:В работе')
						) AS q)
						/
						(select count([Номер заявки]) 
						FROM (
								  SELECT * from  t_fedor_verificator_report where status in ('task:В работе') 
						UNION ALL select * from t_fedor_verificator_report_VK where status in ('task:В работе')
						) AS q)
					)
					else 0
				end
				as datetime), N'HH:mm:ss')

			, [Ср_время_Ожидания_КД_ВК_ТС_день] =
			isnull(cast(
				(
					SELECT
						format(W.duration/60/60 ,'00') + N':'+
						format((duration/60 - 60 * (duration/60/60)),'00') + N':'+
						format((w.duration - 60 * (duration/60)),'00')
					FROM t_waitTime_KD_VK AS W
				)
				as nvarchar(50)
			),'00:00:00')

			--DWH-2209
			--KD
			, Уникальное_количество_autoapprove_KD = cast(format( (
				SELECT count(DISTINCT [Номер заявки]) FROM t_fedor_verificator_report AS R WHERE R.status='autoapprove'
			),'0') as nvarchar(50))

			--[% заявок autoapprove_KD от Уникальное_количество_заявок_КД]
			, Заявки_autoapprove_KD_perc =
				CASE 
					WHEN (select count(distinct [Номер заявки]) FROM t_fedor_verificator_report) <> 0 
					THEN 1.0* (SELECT count(DISTINCT [Номер заявки]) FROM t_fedor_verificator_report AS R WHERE R.status='autoapprove')
						/ (select count(distinct [Номер заявки]) FROM t_fedor_verificator_report) 
					ELSE 0.0 
				END

			  --VK
			, Уникальное_количество_autoapprove_VK = cast(format( (
				SELECT count(DISTINCT [Номер заявки]) FROM t_fedor_verificator_report_VK AS R WHERE R.status='autoapprove'
			),'0') as nvarchar(50))

			--[% заявок autoapprove_VK от Уникальное_количество_заявок_ВК]
			, Заявки_autoapprove_VK_perc = 
				CASE 
					WHEN (select count(distinct [Номер заявки] )from t_fedor_verificator_report_VK) <> 0 
					THEN 1.0* (SELECT count(DISTINCT [Номер заявки]) FROM t_fedor_verificator_report_VK AS R WHERE R.status='autoapprove')
						/ (select count(distinct [Номер заявки] )from t_fedor_verificator_report_VK)
					ELSE 0.0 
				  END

			,ProductType_Group = @ProductType_Group

		FETCH NEXT FROM cur_ProductType_Group INTO @ProductType_Group
	END

	CLOSE cur_ProductType_Group
	DEALLOCATE cur_ProductType_Group

END
