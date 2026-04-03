-- =============================================
-- Author:		А.Никитин
-- Create date: 2024-01-16
-- Description:	DWH-2411 Реализовать отчет по авто отказам от сервиса Кобальт
-- =============================================
/*
EXEC dbo.fill_dm_CobaltData
	--@mode = 1, -- 1 - increment, 0 - full
	--@days = 25, --кол-во дней для пересчета если @mode = 0 - full
	@RequestNumber = '24011721671281', -- расчет по одной заявке
	@isDebug = 1

EXEC dbo.fill_dm_CobaltData
	@mode = 0, -- 1 - increment, 0 - full
	@days = 1000 --кол-во дней для пересчета если @mode = 0 - full

--increment
EXEC dbo.fill_dm_CobaltData

*/
CREATE PROC [dbo].[fill_dm_CobaltData]
	--@ProductType varchar(20) = 'installment',
	@mode int = 1, -- 1 - increment, 0 - full
	@days int = 25, --кол-во дней для пересчета если @mode = 0 - full
	@RequestNumber varchar(20) = NULL, -- расчет по одной заявке
	@isDebug int = 0
AS
BEGIN
	SET XACT_ABORT ON
	--SET NOCOUNT ON

	SELECT @isDebug = isnull(@isDebug, 0)
	SELECT @mode = isnull(@mode, 1)
	--SELECT @ProductType = isnull(@ProductType, 'installment')

	--IF @ProductType NOT IN ('installment', 'pdl')
	--BEGIN
	--	;throw 51000, 'Допустимые значения параметра @ProductType: installment, pdl', 1
	--END

	DECLARE @CobaltStatus_DateTime datetime = '1900-01-01'

	BEGIN TRY

		if OBJECT_ID ('dbo.dm_CobaltData') is not NULL
			AND @mode = 1
		BEGIN
			SELECT @CobaltStatus_DateTime = isnull(dateadd(HOUR, -2, max(D.CobaltStatus_DateTime)), '1900-01-01')
			FROM dbo.dm_CobaltData AS D
		end
		

		DROP TABLE IF EXISTS #t_Request
		CREATE TABLE #t_Request(
			RequestGuid uniqueidentifier,
			RequestNumber nvarchar(255)
		)

		IF @RequestNumber IS NOT NULL BEGIN
			INSERT #t_Request(RequestGuid, RequestNumber)
			SELECT CR.Id, CR.Number COLLATE Cyrillic_General_CI_AS
			FROM Stg._fedor.core_ClientRequest AS CR
				--INNER JOIN Stg._fedor.dictionary_ProductType AS T
				--	ON CR.ProductTypeId = T.Id
			WHERE 1=1 --T.Code = @ProductType
				AND CR.Number = @RequestNumber COLLATE SQL_Latin1_General_CP1_CI_AS
		END
		ELSE BEGIN
			INSERT #t_Request(RequestGuid, RequestNumber)
			SELECT DISTINCT CR.Id, CR.Number COLLATE Cyrillic_General_CI_AS
			FROM Stg._fedor.core_ClientRequest AS CR
				INNER JOIN Stg._fedor.core_CobaltAnswer AS A
					ON A.Id = CR.Id
				--INNER JOIN Stg._fedor.dictionary_ProductType AS T
				--	ON CR.ProductTypeId = T.Id
			WHERE 1=1 --T.Code = @ProductType
				AND dateadd(hour,3,CR.CreatedOn) >= dateadd(day,-@days,cast(getdate() as date))
				AND dateadd(hour,3,A.CreatedOn) >= @CobaltStatus_DateTime
		END

		CREATE INDEX ix_RequestGuid ON #t_Request(RequestGuid)


		--последний ответ-отказ по заявке
		DROP TABLE IF EXISTS #t_CobaltData_Answer
		SELECT 
			Q.RequestGuid,
			Q.CobaltStatus_DateTime,
            Q.PercentCobalt,
            Q.IsBankFraud,
            Q.IsMicrofinanceFraud,
            Q.IsMoneyLaundering,
            Q.IsShopThief,
            Q.IsInsuranceFraud,
            Q.IsCargoThief,
			Q.IsFraud
		INTO #t_CobaltData_Answer
		FROM (
			SELECT 
				R.RequestGuid,
				CobaltStatus_DateTime = dateadd(hour,3,A.CreatedOn),
				D.PercentCobalt,
				D.IsBankFraud,
				D.IsMicrofinanceFraud,
				D.IsMoneyLaundering,
				D.IsShopThief,
				D.IsInsuranceFraud,
				D.IsCargoThief,
				IsFraud = isnull(D.IsFraud, 0),
				rn = row_number() OVER(PARTITION BY D.Id ORDER BY A.CreatedOn DESC)
			FROM #t_Request AS R
				INNER JOIN Stg._fedor.core_CobaltData AS D
					ON D.Id = R.RequestGuid
				INNER JOIN Stg._fedor.core_CobaltAnswer AS A
					ON A.Id = D.Id
			WHERE 1=1
				AND D.IsDeleted = 0
				AND A.IsDeleted = 0
				AND A.IsError = 0
				AND (
					D.IsBankFraud = 1
					OR D.IsMicrofinanceFraud = 1
					OR D.IsMoneyLaundering = 1
					OR D.IsShopThief = 1
					OR D.IsInsuranceFraud = 1
					OR D.IsCargoThief = 1
					OR isnull(D.IsFraud, 0) = 1
				)
			) AS Q
		WHERE 1=1
			AND Q.rn = 1


		--Тип клиента
		DROP TABLE IF EXISTS #t_return_type
		CREATE TABLE #t_return_type(request_number varchar(50) NOT NULL, return_type varchar(255) NULL)

		INSERT #t_return_type(request_number, return_type)
		SELECT A.request_number, A.return_type
		FROM (
			SELECT 
				T.request_number, 
				T.return_type,
				rn = row_number() OVER(PARTITION BY T.request_number ORDER BY T.call_date)
			FROM #t_Request AS R
				INNER JOIN Stg._loginom.return_type AS T
					ON R.RequestNumber = T.request_number
			) AS A
		WHERE A.rn = 1

		CREATE INDEX ix ON #t_return_type(request_number)



		drop table if exists #t_checklists_rejects
		;with loginom_checklists_rejects AS(
			SELECT 
				min(try_cast(replace(cis.LoginomNumber,'.','') AS bigint))  logn,
				cli.IdClientRequest
			FROM
				[Stg].[_fedor].[core_CheckListItem] cli 
				inner JOIN [Stg].[_fedor].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
					--and cis.[IdBehavior] =2 --	Статус - хард-код, по которому откажет логином
					and cis.[IdBehavior] IN (2, 3) -- 3. В информацию по Check* выводим информацию если по заявке был отказа, не важно кем системой или верификатором
			WHERE EXISTS(SELECT TOP(1) 1 FROM #t_Request AS R WHERE R.RequestGuid = cli.IdClientRequest)
			GROUP BY cli.IdClientRequest
		)
		SELECT 
		cli.IdClientRequest,
		cit.[Name] CheckListItemTypeName,
		cis.[Name] CheckListItemStatusName
		into #t_checklists_rejects
		FROM [Stg].[_fedor].[core_CheckListItem] cli
			JOIN [Stg].[_fedor].[dictionary_CheckListItemType] cit ON  cit.id = cli.IdType
			JOIN [Stg].[_fedor].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
			JOIN loginom_checklists_rejects rl ON rl.IdClientRequest = cli.IdClientRequest 
				AND try_cast(replace(cis.LoginomNumber,'.','') AS bigint) = rl.logn
		WHERE EXISTS(SELECT TOP(1) 1 FROM #t_Request AS R WHERE R.RequestGuid = cli.IdClientRequest)

		create clustered index ix on #t_checklists_rejects(IdClientRequest)




		DROP TABLE IF EXISTS #t_dm_CobaltData
		CREATE TABLE #t_dm_CobaltData
		(
			created_at datetime NOT NULL, --момент заполнения витрины
			ProductType_Code nvarchar(50) NOT NULL, --Код Типа продукта
			ProductType_Name nvarchar(255) NOT NULL, --Тип продукта
			RequestGuid uniqueidentifier NOT NULL, --Id заявки
			RequestNumber nvarchar(255) NOT NULL, --номер заявки
			RequestDateTime datetime2(7) NOT NULL, --дата заведения заявки
			RequestClientFIO nvarchar(1024) NULL, --ФИО Клиента

			--Дата статуса -- дд.мм.гггг  последнего статуса из Феди, только дата
			RequestStatus_DateTime datetime,
			RequestStatus_Date date,

			--Статус -- Всегда "Отказано" передаем один из Феди 
			RequestStatus_Name nvarchar(255),

			--Момент Статуса - дд.мм.гггг чч.мм появления отказного статуса от Кобальт, 
			--момент статуса это более детализированное время получения отказа
			CobaltStatus_DateTime datetime,

			--Продукт --Данные из Федор (поле продукт), 
			--варианты : Все просто (с указанием %) , ПДЛ, (данные аналогичны из отчета по статусам)
			CreditProductName nvarchar(255),

			--Тип Клиента --аналогичен отчеты по верификации (новый, повторный)
			ClientType nvarchar(255),

			-- Причина отказа  -- поле из Феди, автоматический отказ, указываем одну причину
			CheckListItemTypeName nvarchar(255),
			CheckListItemStatusName nvarchar(255),

			--Ответ от Кобальт
			--поле в Феде, поле "Совпадение с базой мошенников" ответ от Кобальта, м.б несколько признаков отказа, 
			--здесь и в других вкладках заявку передавать и считать с первым признаком true, 
			--из ответа  Кобальт, согласно указанной приоритетности:
			--1. Банковское мошенничество
			--2. Микрофинансовое мошенничество
			--3. Страховое мошенничество
			--4. Отмывание денег
			--5. Мошенничество с грузами
			--6. Магазинный вор
			/*
			--DWH-2462 Доработка в Отчет Кобальт автоотказы_добавление флага IsFraud
			1. Банковское мошенничество
			2. Микрофинансовое мошенничество
			3. Мошенник
			4. Страховое мошенничество
			5. Отмывание денег
			6. Мошенничество с грузами
			7. Магазинный вор
			*/
			--не дублируя уникальную заявку в несколько полей
			--одна уникальная заявка не должна попадать в несколько строк
			CobaltStatus_Code nvarchar(255),
			CobaltStatus_Name nvarchar(255),

			--Запрошенная сумма -- запрошенная клиентом при заведении заявки
			RequestedAmount money,

			--поля из Stg._fedor.core_CobaltData
			IsBankFraud int,
			IsMicrofinanceFraud int,
			IsMoneyLaundering int,
			IsShopThief int,
			IsInsuranceFraud int,
			IsCargoThief int,
			IsFraud int
		)

		
		INSERT #t_dm_CobaltData
		(
		    created_at,
			ProductType_Code,
			ProductType_Name,
		    RequestGuid,
		    RequestNumber,
		    RequestDateTime,
		    RequestClientFIO,
		    RequestStatus_DateTime,
		    RequestStatus_Date,
		    RequestStatus_Name,
		    CobaltStatus_DateTime,
		    CreditProductName,
		    ClientType,
		    CheckListItemTypeName,
		    CheckListItemStatusName,
			CobaltStatus_Code,
		    CobaltStatus_Name,
		    RequestedAmount,
		    IsBankFraud,
		    IsMicrofinanceFraud,
		    IsMoneyLaundering,
		    IsShopThief,
		    IsInsuranceFraud,
		    IsCargoThief,
			IsFraud
		)
		SELECT
			created_at = getdate()
			,ProductType_Code = T.Code
			,ProductType_Name = T.Name

			,R.RequestGuid
			,R.RequestNumber
			
			--,RequestDateTime = cast(CR.CreatedRequestDate AS datetime2(0))
			,RequestDateTime = dateadd(HOUR, 3, CR.CreatedOn) -- CreatedOn - в PROC dbo.Create_dm_FedorVerificationRequests_...

			,RequestClientFIO = concat_ws(' '
									,isnull(CR.ClientLastName ,  cr_ci.LastName)
									,isnull(CR.ClientFirstName,  cr_ci.FirstName)
									,isnull(CR.ClientMiddleName, cr_ci.MiddleName) 
									) COLLATE Cyrillic_General_CI_AS

			--Дата статуса -- дд.мм.гггг  последнего статуса из Феди, только дата
			,RequestStatus_DateTime = dateadd(HOUR, 3, H.CreatedOn)
			,RequestStatus_Date = cast(dateadd(HOUR, 3, H.CreatedOn) AS date)
			--Статус -- Всегда "Отказано" передаем один из Феди 
			,RequestStatus_Name = CRS.Name COLLATE Cyrillic_General_CI_AS

			--Момент Статуса - дд.мм.гггг чч.мм появления отказного статуса от Кобальт
			,C.CobaltStatus_DateTime

			--Продукт --Данные из Федор (поле продукт), 
			,CreditProductName = DIC_CP.Name COLLATE Cyrillic_General_CI_AS

			--Тип Клиента --аналогичен отчеты по верификации (новый, повторный)
			,ClientType = RT.return_type

			-- Причина отказа  -- поле из Феди, автоматический отказ, указываем одну причину
			,CheckListItemTypeName = J.CheckListItemTypeName --[Check List]
			,CheckListItemStatusName = J.CheckListItemStatusName --[Check List Status]

			--Ответ от Кобальт, согласно указанной приоритетности:
			--1. Банковское мошенничество
			--2. Микрофинансовое мошенничество
			--3. Страховое мошенничество
			--4. Отмывание денег
			--5. Мошенничество с грузами
			--6. Магазинный вор
			/*
			--DWH-2462 Доработка в Отчет Кобальт автоотказы_добавление флага IsFraud
			1. Банковское мошенничество
			2. Микрофинансовое мошенничество
			3. Мошенник
			4. Страховое мошенничество
			5. Отмывание денег
			6. Мошенничество с грузами
			7. Магазинный вор
			*/
			,CobaltStatus_Code = 
			CASE 
				WHEN C.IsBankFraud = 1 THEN 'BankFraud'
				WHEN C.IsMicrofinanceFraud = 1 THEN 'MicrofinanceFraud'
				WHEN C.IsFraud = 1 THEN 'Fraud'
				WHEN C.IsInsuranceFraud = 1 THEN 'InsuranceFraud'
				WHEN C.IsMoneyLaundering = 1 THEN 'MoneyLaundering'
				WHEN C.IsCargoThief = 1 THEN 'CargoThief'
				WHEN C.IsShopThief = 1 THEN 'ShopThief'
				ELSE ''
			END

			,CobaltStatus_Name = 
			CASE 
				WHEN C.IsBankFraud = 1 THEN 'Банковское мошенничество'
				WHEN C.IsMicrofinanceFraud = 1 THEN 'Микрофинансовое мошенничество'
				WHEN C.IsFraud = 1 THEN 'Мошенник'
				WHEN C.IsInsuranceFraud = 1 THEN 'Страховое мошенничество'
				WHEN C.IsMoneyLaundering = 1 THEN 'Отмывание денег'
				WHEN C.IsCargoThief = 1 THEN 'Мошенничество с грузами'
				WHEN C.IsShopThief = 1 THEN 'Магазинный вор'
				ELSE ''
			END

			--Запрошенная сумма -- запрошенная клиентом при заведении заявки
			,RequestedAmount = CR.RequestedSum

			,C.IsBankFraud
			,C.IsMicrofinanceFraud
			,C.IsMoneyLaundering
			,C.IsShopThief
			,C.IsInsuranceFraud
			,C.IsCargoThief
			,C.IsFraud
		FROM #t_Request AS R
			INNER JOIN Stg._fedor.core_ClientRequest AS CR
				ON CR.Id = R.RequestGuid
			LEFT JOIN stg._fedor.core_ClientRequestClientInfo cr_ci
				on cr_ci.Id = cr.Id
			LEFT JOIN Stg._fedor.dictionary_ProductType AS T
				ON CR.ProductTypeId = T.Id
			INNER JOIN #t_CobaltData_Answer AS C
				ON C.RequestGuid = R.RequestGuid
			LEFT JOIN (
					SELECT 
						R1.RequestGuid, 
						CreatedOn = max(H1.CreatedOn)
					FROM #t_Request AS R1
						INNER JOIN Stg._fedor.core_ClientRequestHistory AS H1
							ON H1.IdClientRequest = R1.RequestGuid
					GROUP BY R1.RequestGuid
				) AS M
				ON M.RequestGuid = R.RequestGuid
			LEFT JOIN Stg._fedor.core_ClientRequestHistory AS H
				ON H.IdClientRequest = M.RequestGuid
				AND H.CreatedOn = M.CreatedOn
			LEFT JOIN Stg._fedor.dictionary_ClientRequestStatus AS CRS
				ON CRS.Id = H.IdClientRequestStatus
			LEFT JOIN Stg._fedor.dictionary_CreditProduct AS DIC_CP
				ON DIC_CP.Id = CR.IdCreditProduct

			LEFT JOIN #t_return_type AS RT
				ON RT.request_number = R.RequestNumber

			LEFT JOIN #t_checklists_rejects AS J
				ON J.IdClientRequest = R.RequestGuid

		--WHERE 1=1
		--ORDER BY CR.Number, DBrainFileType.Id, FieldInfo.Id




		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_dm_CobaltData
			SELECT * INTO ##t_dm_CobaltData FROM #t_dm_CobaltData AS D

			--RETURN 0
		END


		if OBJECT_ID('dbo.dm_CobaltData') is null
		BEGIN
			SELECT TOP 0 *
			INTO dbo.dm_CobaltData
			FROM #t_dm_CobaltData AS D

			CREATE INDEX ix_RequestGuid ON dbo.dm_CobaltData(RequestGuid)
        END

						
		if exists(select top(1) 1 from #t_dm_CobaltData)
		BEGIN
			BEGIN TRAN
				DELETE D
				FROM dbo.dm_CobaltData D
					INNER JOIN #t_Request AS R
						ON R.RequestGuid = D.RequestGuid

				INSERT dbo.dm_CobaltData(
					created_at,
					ProductType_Code,
					ProductType_Name,
					RequestGuid,
					RequestNumber,
					RequestDateTime,
					RequestClientFIO,
					RequestStatus_DateTime,
					RequestStatus_Date,
					RequestStatus_Name,
					CobaltStatus_DateTime,
					CreditProductName,
					ClientType,
					CheckListItemTypeName,
					CheckListItemStatusName,
					CobaltStatus_Code,
					CobaltStatus_Name,
					RequestedAmount,
					IsBankFraud,
					IsMicrofinanceFraud,
					IsMoneyLaundering,
					IsShopThief,
					IsInsuranceFraud,
					IsCargoThief,
					IsFraud
				)
				SELECT 
					D.created_at,
					D.ProductType_Code,
					D.ProductType_Name,
					D.RequestGuid,
					D.RequestNumber,
					D.RequestDateTime,
					D.RequestClientFIO,
					D.RequestStatus_DateTime,
					D.RequestStatus_Date,
					D.RequestStatus_Name,
					D.CobaltStatus_DateTime,
					D.CreditProductName,
					D.ClientType,
					D.CheckListItemTypeName,
					D.CheckListItemStatusName,
					D.CobaltStatus_Code,
					D.CobaltStatus_Name,
					D.RequestedAmount,
					D.IsBankFraud,
					D.IsMicrofinanceFraud,
					D.IsMoneyLaundering,
					D.IsShopThief,
					D.IsInsuranceFraud,
					D.IsCargoThief,
					D.IsFraud
				FROM #t_dm_CobaltData AS D
			COMMIT
		END
	end try
	begin catch
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		;throw 
	end catch
END
