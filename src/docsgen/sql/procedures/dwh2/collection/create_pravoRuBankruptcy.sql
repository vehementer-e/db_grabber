-- =======================================================
-- Create: 09.04.2024. А.Никитин
-- Description:	DWH-2501 Реализовать отчет с ответами по право.ру
-- truncate table collection.pravoRuBankruptcy
-- [collection].[create_pravoRuBankruptcy]  @mode = 0
-- =======================================================
CREATE PROC collection.create_pravoRuBankruptcy
	--@days int = 20, -- актуализация витрины за последние @days дней
	@mode int = 1, -- 
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isDebug int = 0,
	@response_Id bigint = NULL
AS 
BEGIN
	SET NOCOUNT ON 
	SET XACT_ABORT ON
	
	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)
	SELECT @mode = isnull(@mode, 1)

	DECLARE @rowVersion binary(8) = 0x0
	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024), @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)
	DECLARE @InsertRows int = 0, @DeleteRows int = 0
	DECLARE @maxBalanceDate date

	SELECT @eventName = 'collection.create_pravoRuBankruptcy', @eventType = 'info', @SendEmail = 0

	BEGIN TRY
		if OBJECT_ID ('collection.pravoRuBankruptcy') is not null
			AND @mode = 1
		begin
			set @rowVersion = isnull((select max(rowVersion) from collection.pravoRuBankruptcy), 0x0)
		end

		DROP TABLE IF EXISTS #t_pravoRuBankruptcy
		CREATE TABLE #t_pravoRuBankruptcy
		(
			created_at datetime,
			updated_at datetime,
			rowVersion binary(8),
			response_Id bigint,
			CMRClientGUID nvarchar(50),
			request_date datetime,
			clientLastName nvarchar(255),
			clientFirstName nvarchar(255),
			clientMiddleName nvarchar(255),
			clientBirthDate date,
			clientInn nvarchar(50),
			caseId nvarchar(255),
			caseNumber nvarchar(255),
			caseRegistrationDate date,
			caseCategory nvarchar(2000),
			caseState nvarchar(255),
			bankruptcyCaseStage nvarchar(255),
			courtTag nvarchar(255),
			caseDecisionType nvarchar(255),
			caseDecision nvarchar(255),
			bankruptcyDebtorInn nvarchar(50),
			nRow int,
			dealNumber nvarchar(1000),
			duplicates int,
			collectionCustomerStatus nvarchar(2000),
 			collectingStage nvarchar(255), --[Стадия коллектинга]
			productType nvarchar(255) --[Наименование Продукта]
		)

		INSERT #t_pravoRuBankruptcy
		(
			created_at,
			updated_at,
			rowVersion,
			response_Id,
		    CMRClientGUID,
		    request_date,
		    clientLastName,
		    clientFirstName,
		    clientMiddleName,
		    clientBirthDate,
		    clientInn,
		    caseId,
		    caseNumber,
		    caseRegistrationDate,
		    caseCategory,
		    caseState,
		    bankruptcyCaseStage,
		    courtTag,
		    caseDecisionType,
		    caseDecision,
		    bankruptcyDebtorInn,
			nRow

		)
		select --top(5) 
			created_at = getdate(),
			updated_at = getdate(),
			rowVersion = Original_response.rowver,
			response_Id = Original_response.Id,
		    Original_response.CMRClientGUID,
		    request_date = [Original_response].request_date,
		    t_requests.clientLastName,
		    t_requests.clientFirstName,
		    t_requests.clientMiddleName,
		    t_requests.clientBirthDate,
		    t_requests.clientInn,
		    t_siResults.caseId,
		    t_siResults.caseNumber,
		    t_siResults.caseRegistrationDate,
		    t_siResults.caseCategory,
		    t_siResults.caseState,
		    t_siResults.bankruptcyCaseStage,
		    t_siResults.courtTag,
		    t_siResults.caseDecisionType,
		    t_siResults.caseDecision,
		    t_siResults.bankruptcyDebtorInn
			--,t_requests.*
			--,t_siResults.*
			,nRow = ROW_NUMBER() over(partition by Original_response.CMRClientGUID
				 ,t_requests.clientInn,  t_siResults.caseId
				 order by Original_response.rowver desc)
		FROM Stg._loginom.Original_response AS Original_response with (nolock)
			OUTER apply (
			select 
				clientLastName		
				,clientFirstName	
				,clientMiddleName	
				,clientInn			
				,clientBirthDate	
			from OPENJSON(JSON, '$.included')
			with (	[type]  nvarchar(255)			'$.type'
					,clientLastName		nvarchar(255)	'$.attributes.clientLastName' 
					,clientFirstName	nvarchar(255)	'$.attributes.clientFirstName' 
					,clientMiddleName	nvarchar(255)	'$.attributes.clientMiddleName' 
					,clientInn			nvarchar(12)	'$.attributes.inn' 
					,clientBirthDate	date			'$.attributes.clientBirthDate' 
				) t_requests
			WHERE t_requests.[type] = 'requests'
			) AS t_requests
			OUTER apply (
				SELECT
					t_siResults.siServiceRawResult
					,t_siServiceRawResult.*
					,t_ServiceRawResult_case.*
				from OPENJSON(JSON, '$.included')
				WITH (	[type]  nvarchar(255) '$.type'
					,siServiceRawResult nvarchar(max)	 '$.attributes.siServiceRawResult' 
				) t_siResults
				outer apply openjson(t_siResults.siServiceRawResult, '$')
				with(
					totalItems int '$.total'
					--,items nvarchar(max) '$.items' as json
					) AS t_siServiceRawResult
				outer  apply openjson(t_siResults.siServiceRawResult, '$.items') 
				with (
					caseId				nvarchar(36)	'$.case.id'
					,caseNumber			nvarchar(255)	'$.case.number'	
					,caseRegistrationDate	date		'$.case.registrationDate'
					,caseCategory		nvarchar(max)	'$.case.caseCategory'
					,caseState			nvarchar(255)	'$.case.caseState'
					,bankruptcyCaseStage nvarchar(255)	'$.case.bankruptcy.caseStage'
					,courtTag			nvarchar(255)	'$.case.courtTag'
					,caseDecision		nvarchar(255)	'$.case.decision'
					,caseDecisionType	nvarchar(255)	'$.case.decisionType'
					,bankruptcyDebtorInn nvarchar(12)	'$.case.bankruptcy.debtor.inn'
					,items				nvarchar(max)	'$' as json
				) AS t_ServiceRawResult_case
				where t_siResults.[type] = 'siResults'
				and t_siServiceRawResult.totalItems>0
			) t_siResults
		where 1=1
			AND Original_response.[source] in ('PravoRu')
			and Original_response.process='Monitoring_Collection'
			AND Original_response.rowver > @rowVersion
			--and userName = 'service'
			--AND (@response_Id IS NULL OR Original_response.Id IN (@response_Id)) --13639989
			AND t_requests.clientInn  = t_siResults.bankruptcyDebtorInn
		--order by request_date desc
		
		CREATE clustered INDEX ix_response_Id ON #t_pravoRuBankruptcy(CMRClientGUID
			,clientInn
			,caseId)

		delete from #t_pravoRuBankruptcy
		where nRow>1

		--CREATE INDEX ix_number ON #t_pravoRuBankruptcy(number)
			
		IF object_id('collection.pravoRuBankruptcy') IS NULL
		BEGIN
			SELECT TOP(0)
				created_at,
				updated_at,
				rowVersion,
				response_Id,
				CMRClientGUID,
				request_date,
				clientLastName,
				clientFirstName,
				clientMiddleName,
				clientBirthDate,
				clientInn,
				caseId,
				caseNumber,
				caseRegistrationDate,
				caseCategory,
				caseState,
				bankruptcyCaseStage,
				courtTag,
				caseDecisionType,
				caseDecision,
				bankruptcyDebtorInn
				dealNumber,
				duplicates,
				collectionCustomerStatus,
 				collectingStage,
				productType
			INTO collection.pravoRuBankruptcy
			FROM #t_pravoRuBankruptcy

			--alter table collection.pravoRuBankruptcy
			--	alter column response_Id bigint not null

			--ALTER TABLE collection.pravoRuBankruptcy
			--	ADD CONSTRAINT PK_dm_pravoRuBankruptcy PRIMARY KEY CLUSTERED (GuidЗаявки, Этап)

			CREATE INDEX ix_response_Id ON collection.pravoRuBankruptcy(response_Id)
			CREATE INDEX ix_rowVersion ON collection.pravoRuBankruptcy(rowVersion)
			CREATE INDEX ix_CMRClientGUID ON collection.pravoRuBankruptcy(CMRClientGUID)
		END

		--UPDATE R
		--SET R.created_at = C.created_at
		--FROM #t_pravoRuBankruptcy AS R
		--	INNER JOIN collection.pravoRuBankruptcy AS C
		--		ON C.response_Id = R.response_Id

		SELECT @maxBalanceDate = max(B.d) 
		FROM dbo.dm_CMRStatBalance AS B (NOLOCK)

		BEGIN TRAN

			merge collection.pravoRuBankruptcy as T
			using #t_pravoRuBankruptcy s
			ON s.CMRClientGUID = t.CMRClientGUID
				and s.clientInn = t.clientInn
				and s.caseId = t.caseId
				
			when not matched then insert
			(
				created_at,
				updated_at,
				rowVersion,
				response_Id,
				CMRClientGUID,
				request_date,
				clientLastName,
				clientFirstName,
				clientMiddleName,
				clientBirthDate,
				clientInn,
				caseId,
				caseNumber,
				caseRegistrationDate,
				caseCategory,
				caseState,
				bankruptcyCaseStage,
				courtTag,
				caseDecisionType,
				caseDecision,
				bankruptcyDebtorInn,
				dealNumber,
				duplicates,
				collectionCustomerStatus
			)
			values
			(
				s.created_at,
				s.updated_at,
				s.rowVersion,
				s.response_Id,
				s.CMRClientGUID,
				s.request_date,
				s.clientLastName,
				s.clientFirstName,
				s.clientMiddleName,
				s.clientBirthDate,
				s.clientInn,
				s.caseId,
				s.caseNumber,
				s.caseRegistrationDate,
				s.caseCategory,
				s.caseState,
				s.bankruptcyCaseStage,
				s.courtTag,
				s.caseDecisionType,
				s.caseDecision,
				s.bankruptcyDebtorInn,
				s.dealNumber,
				s.duplicates,
				s.collectionCustomerStatus
			)
			when matched and s.rowVersion>t.rowVersion
			then update
				set
				created_at			= s.created_at,
				updated_at			= s.updated_at,
				rowVersion			= s.rowVersion,
				response_Id			= s.response_Id,
				request_date		= s.request_date,
				clientLastName		= s.clientLastName,
				clientFirstName		= s.clientFirstName,
				clientMiddleName	= s.clientMiddleName,
				clientBirthDate		= s.clientBirthDate,
				caseNumber			= s.caseNumber,
				caseRegistrationDate= s.caseRegistrationDate,
				caseCategory		= s.caseCategory,
				caseState			= s.caseState,
				bankruptcyCaseStage = s.bankruptcyCaseStage,
				courtTag			= s.courtTag,
				caseDecisionType	= s.caseDecisionType,
				caseDecision		= s.caseDecision,
				bankruptcyDebtorInn	= s.bankruptcyDebtorInn,
				dealNumber			= s.dealNumber,
				duplicates			= s.duplicates,
				collectionCustomerStatus = s.collectionCustomerStatus
			;

			/*
			DELETE C
			FROM collection.pravoRuBankruptcy AS C
			WHERE EXISTS(
					SELECT TOP(1) 1
					FROM #t_pravoRuBankruptcy AS R
					WHERE R.response_Id = C.response_Id
				)

			INSERT collection.pravoRuBankruptcy
			(
				created_at,
				updated_at,
				rowVersion,
				response_Id,
				CMRClientGUID,
				request_date,
				clientLastName,
				clientFirstName,
				clientMiddleName,
				clientBirthDate,
				clientInn,
				caseId,
				caseNumber,
				caseRegistrationDate,
				caseCategory,
				caseState,
				bankruptcyCaseStage,
				courtTag,
				caseDecisionType,
				caseDecision,
				bankruptcyDebtorInn
			)
			SELECT
				created_at,
				updated_at,
				rowVersion,
				response_Id,
				CMRClientGUID,
				request_date,
				clientLastName,
				clientFirstName,
				clientMiddleName,
				clientBirthDate,
				clientInn,
				caseId,
				caseNumber,
				caseRegistrationDate,
				caseCategory,
				caseState,
				bankruptcyCaseStage,
				courtTag,
				caseDecisionType,
				caseDecision,
				bankruptcyDebtorInn
			FROM #t_pravoRuBankruptcy
			*/

			--DWH-2804
			--1. Номер договор. Если у клиента несколько незакрытых договоров, 
			--то указать их в одной ячейке через запятую.
			--только непогашенные договоры.

			DROP TABLE IF EXISTS #t_Active_Deal

			SELECT --TOP 100
				P.CMRClientGUID,
				Deal_Id = Deal.Id,
				Deal_Number = D.КодДоговораЗайма,
				--Deal_Date = Deal.Date,
				Deal_StageId = Deal.StageId,
				rn = row_number() OVER(PARTITION BY P.CMRClientGUID ORDER BY D.КодДоговораЗайма DESC)
			INTO #t_Active_Deal
			FROM collection.pravoRuBankruptcy AS P
				INNER JOIN link.Клиент_ДоговорЗайма AS D
					ON D.GuidКлиент = P.CMRClientGUID
				INNER JOIN dbo.dm_CMRStatBalance AS B (NOLOCK)
					ON B.d = @maxBalanceDate --cast(getdate() AS date)
					AND B.external_id = D.КодДоговораЗайма
				LEFT JOIN Stg._Collection.Deals AS Deal
					ON Deal.Number = D.КодДоговораЗайма

			--SELECT * FROM #t_Active_Deal AS D

			--Продукт и Стадия коллектинга (по последнему договору)
			UPDATE P
			SET collectingStage = cst_deals.Name, --[Стадия коллектинга]
				--[Наименование Продукта]
				productType = 
					CASE OI.ProductType
						when 'Инстоллмент' then 'Installment'
						else OI.ProductType 
					END
			FROM #t_Active_Deal AS D
				LEFT JOIN Stg._Collection.collectingStage AS cst_deals 
					ON cst_deals.Id = D.Deal_StageId
				LEFT JOIN dbo.dm_OverdueIndicators AS OI (NOLOCK)
					ON OI.Number = D.Deal_Number
				INNER JOIN collection.pravoRuBankruptcy AS P
					ON P.CMRClientGUID = D.CMRClientGUID
			WHERE D.rn = 1

			/*
			UPDATE B 
			SET dealNumber = A.dealNumber
			FROM collection.pravoRuBankruptcy AS B
				INNER JOIN (
					SELECT 
						R.CMRClientGUID,
						dealNumber = string_agg(D.КодДоговораЗайма, ',') WITHIN GROUP(ORDER BY D.КодДоговораЗайма)
					FROM collection.pravoRuBankruptcy AS R
						INNER JOIN link.Клиент_ДоговорЗайма AS D
							ON D.GuidКлиент = R.CMRClientGUID
					GROUP BY R.CMRClientGUID
					) AS A
					ON A.CMRClientGUID = B.CMRClientGUID
			*/

			UPDATE B 
			SET dealNumber = A.dealNumber
			FROM collection.pravoRuBankruptcy AS B
				LEFT JOIN (
					SELECT 
						D.CMRClientGUID,
						dealNumber = string_agg(D.Deal_Number, ',') WITHIN GROUP(ORDER BY D.Deal_Number)
					FROM #t_Active_Deal AS D
					GROUP BY D.CMRClientGUID
					) AS A
					ON A.CMRClientGUID = B.CMRClientGUID


			--2 duplicates int,
			UPDATE B
			SET	duplicates = A.duplicates
			FROM collection.pravoRuBankruptcy AS B
				INNER JOIN (
					SELECT 
						R.CMRClientGUID,
						duplicates = count(*)
					FROM collection.pravoRuBankruptcy AS R
					GROUP BY R.CMRClientGUID
					) AS A
					ON A.CMRClientGUID = B.CMRClientGUID

			--3
			/*
			Информация о статусе клиента из Спейс. Возможны следующие виды статусов:
			1.	нулевой или статус, не связанный с банкротством, 
			(т.е. по клиенту ранее в Спейсе не было информации о банкротстве),

			2.	банкрот неподтвержденный - по клиенту есть информация о подаче заявления 
			о банкротстве либо заявление принято арбитражным судом, но нет решения о банкротстве,

			3.	банкрот подтвержденный - арбитражным судом принято решение 
			о признании клиента банкротом и введена одна из стадий банкротства 
			(реализация имущества, реструктуризация долгов, конкурсное производство и т.п.)
			*/
			UPDATE B 
			SET collectionCustomerStatus = F.collectionCustomerStatus
			FROM collection.pravoRuBankruptcy AS B
				INNER JOIN (
					SELECT
						A.CMRClientGUID,
						collectionCustomerStatus = string_agg(A.customerStatus, ', ') WITHIN GROUP(ORDER BY A.customerStatusOrder)
					FROM (
						SELECT DISTINCT
							R.CMRClientGUID,
							customerStatusOrder =  CST.[Order],
							customerStatus = CST.Name
						FROM collection.pravoRuBankruptcy AS R
							INNER JOIN link.Клиент_ДоговорЗайма AS D
								ON D.GuidКлиент = R.CMRClientGUID
							INNER JOIN Stg._collection.deals AS CD
								ON CD.number = D.КодДоговораЗайма
							INNER JOIN Stg._Collection.CustomerStatus AS CS
								ON CS.CustomerId = CD.IdCustomer
								AND CS.IsActive=1  
							INNER JOIN Stg._Collection.CustomerState AS CST
								ON CS.CustomerStateId = CST.Id 
						) AS A
					GROUP BY A.CMRClientGUID
					) AS F
					ON F.CMRClientGUID = B.CMRClientGUID

		COMMIT


		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = @eventName, 
			@eventType = @eventType, 
			@message = @message, 
			@SendEmail = @SendEmail, 
			@ProcessGUID = @ProcessGUID

	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @message = 'Ошибка заполнения collection.pravoRuBankruptcy'

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = @eventName,
			@eventType = 'Error',
			@message = @message,
			@description = @error_description,
			@SendEmail = @SendEmail,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH

END
