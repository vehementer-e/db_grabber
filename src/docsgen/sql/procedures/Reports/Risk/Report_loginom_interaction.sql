-- =============================================
-- Author:		А.Никитин
-- Create date: 2024-12-11
-- Description:	DWH-2863 Реализовать отчет по назначенным взаимодествиям
-- =============================================
/*
EXEC Reports.Risk.Report_loginom_interaction
	@Page = 'Detail'
	,@dtFrom = '2024-11-01'
	,@dtTo = '2024-12-10'

*/
CREATE   PROC Risk.Report_loginom_interaction
--declare
	@Page nvarchar(100) = 'Detail'
	,@PeriodDay varchar(1000) = NULL
	--,@dtFrom date = null -- '2021-04-01'
	--,@dtTo date =  null --'2021-04-26'
	,@CommunicationTypeName varchar(8000) = NULL
	,@ProductType varchar(8000) = NULL
	,@ProcessGUID varchar(36) = NULL -- guid процесса
	,@isDebug int = 0
AS
BEGIN
	SET NOCOUNT ON;
BEGIN TRY

	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50)
	DECLARE @description nvarchar(1024), @message nvarchar(1024), @error_number int
	--DECLARE @dt_from date, @dt_to date

	/*
	IF @dtFrom is not NULL BEGIN
		SET @dt_from = @dtFrom
	END 
	ELSE BEGIN
		--SET @dt_from = cast(format(getdate(),'yyyyMM01') AS date)	         
		SET @dt_from = cast(dateadd(DAY, -7, getdate()) AS date)
	END

	IF @dtTo is not NULL BEGIN
		IF @dtTo > cast(getdate() AS date) BEGIN
			SELECT @dtTo = cast(getdate() AS date)
		END

		--SET @dt_to = dateadd(day,1,@dtTo)
		SET @dt_to = @dtTo
	END
	ELSE BEGIN
		--SET @dt_to = dateadd(day,1,cast(getdate() as date))
		SET @dt_to = cast(getdate() as date)
	END 
	*/

	DECLARE @t_PeriodDay table(PeriodDay date)
	IF @PeriodDay IS NOT NULL BEGIN
		INSERT @t_PeriodDay(PeriodDay)
		select PeriodDay = try_cast(trim(value) AS date)
		FROM string_split(@PeriodDay, ',')
		WHERE try_cast(trim(value) AS date) IS NOT NULL
	END
	ELSE BEGIN
		INSERT @t_PeriodDay(PeriodDay)
		SELECT PeriodDay = C.DT
		FROM dwh2.Dictionary.calendar AS C
		WHERE C.DT BETWEEN cast(dateadd(DAY, -7, getdate()) AS date) AND cast(getdate() AS date)
	END

	--IF @isDebug = 1 BEGIN
	--	SELECT * FROM @t_PeriodDay
	--END

	DECLARE @t_CommunicationTypeName table(CommunicationTypeName varchar(255))
	IF @CommunicationTypeName IS NOT NULL BEGIN
		INSERT @t_CommunicationTypeName(CommunicationTypeName)
		select CommunicationTypeName = trim(value) 
		FROM string_split(@CommunicationTypeName, ',')
	END

	DECLARE @t_ProductType table(ProductType varchar(255))
	IF @ProductType IS NOT NULL BEGIN
		INSERT @t_ProductType(ProductType)
		select CommunicationTypeName = trim(value) 
		FROM string_split(@ProductType, ',')
	END

	DROP TABLE IF EXISTS #t_dm_loginom_interaction

	SELECT TOP 0 D.* 
	INTO #t_dm_loginom_interaction
	FROM Risk.dm_loginom_interaction AS D

	IF @Page IN ('Detail') BEGIN
		--INSERT #t_dm_loginom_interaction
		--SELECT D.* 
		--FROM Risk.dm_loginom_interaction AS D
		--WHERE D.call_date BETWEEN @dt_from AND @dt_to

		INSERT #t_dm_loginom_interaction
		SELECT D.* 
		FROM Risk.dm_loginom_interaction AS D
			INNER JOIN @t_PeriodDay AS C ON C.PeriodDay = D.call_date
	END

	IF @Page IN ('Statistics') BEGIN
		--INSERT #t_dm_loginom_interaction
		--SELECT D.* 
		--FROM Risk.dm_loginom_interaction AS D
		--WHERE D.call_date BETWEEN @dt_from AND @dt_to
		--	AND (D.CommunicationTypeName IN (SELECT CommunicationTypeName FROM @t_CommunicationTypeName)
		--		OR @CommunicationTypeName is null)
		--	AND (D.ProductType IN (SELECT ProductType FROM @t_ProductType)
		--		OR @ProductType is null)

		INSERT #t_dm_loginom_interaction
		SELECT D.* 
		FROM Risk.dm_loginom_interaction AS D
			INNER JOIN @t_PeriodDay AS C ON C.PeriodDay = D.call_date
		WHERE 1=1
			AND (D.CommunicationTypeName IN (SELECT CommunicationTypeName FROM @t_CommunicationTypeName)
				OR @CommunicationTypeName is null)
			AND (D.ProductType IN (SELECT ProductType FROM @t_ProductType)
				OR @ProductType is null)
	END

	IF @isDebug IS NOT NULL BEGIN
		DROP TABLE IF EXISTS ##t_dm_loginom_interaction
		SELECT * INTO ##t_dm_loginom_interaction FROM #t_dm_loginom_interaction
	END

	IF @Page = 'Detail' BEGIN
		/*
		d	Дата
		external_id	external_id
		ActionId	Название шаблона	Как назначенные из Логином, так и отправленые из Спейс
		CommunicationType	смс, push etc	
		FromLoginom	1 - если было назначение Логином, 0 - если нет	
		SpaceResult	Результат обработки Спейс (1 - передано дальше, 0 - нет)	
		DeclineReason	Причина, почему Спейс не передал дальше	
		Commentary	Отправленое сообщение	select Commentary from stg._collection.mv_Communications
		NumAttempts	Количество попыток	для исходящих звонков?
		CommunicationResult	Результат воздействия	последнего результативного на этот день для исходящих звонков
		*/
		SELECT 
			--T.created_at,
			T.row_id,
			--T.userName,
			Дата = T.call_date,
			--T.call_date_time,
			--T.CRMClientGUID,
			ФИО = T.fio,
			Номер_Договора = T.external_id,
			--СтадияПоДоговору = T.Stage,
			--Код_Шаблона = T.ActionID,
			Код_Шаблона = isnull(T.ActionID, 'Не назначеные Логином'),
			--T.packageName,
			--T.CommunicationTemplateId,
			Тема_Шаблона = T.CommunicationTemplateTheme,
			Описание_Шаблона = T.CommunicationTemplateName,
			Количество_Попыток = T.Communication_count,
			T.CommunicationId,
			Дата_Время_Коммуникации = cast(T.CommunicationDateTime AS datetime2(0)),
			Тип_Коммуникации = T.CommunicationTypeName,
			Телефон = T.PhoneNumber,
			Комментарий = T.CommunicationCommentary,
			Результат = T.CommunicationResultName,
			Результат_из_справочника = T.CR_Name,

			FromLoginom	= iif(T.row_id IS NULL, 0, 1), -- 1 если было назначение Логином, 0 - если нет	
			--SpaceResult	= cast(1 AS int), --Результат обработки Спейс (1 - передано дальше, 0 - нет)	
			SpaceResult	= cast(iif(isnull(T.Communication_count,0)>0,1,0) AS int),
			DeclineReason = cast(NULL AS nvarchar(255)), --Причина, почему Спейс не передал дальше
			--T.CR_Name,
			--T.CR_Naumen,
			--T.CustomerFIO,
			T.external_communication_id,
			T.NaumenCaseUuid,
			T.SessionId,
			Стадия_по_договору = T.External_Stage,
			Продукт = T.ProductType,
			Сотрудник = T.EmployeeName,
			Кампания_Naumen = T.NaumenCampaignName,
			Контакт = T.isContact
		FROM #t_dm_loginom_interaction AS T
		ORDER BY T.call_date, T.external_id

		RETURN 0
	END
	--// 'Detail'



	DROP TABLE IF EXISTS #t_Action
	CREATE TABLE #t_Action(
		id int NOT NULL IDENTITY(1,1),
		call_date date NOT NULL,
		ActionCode nvarchar(100) NOT NULL,
		CommunicationTypeName nvarchar(100) NOT NULL,
		LoginomNum int NOT NULL DEFAULT(0), --количество записей с этим ActionId, назначеных Логином
		NotFromLoginomNum int NOT NULL DEFAULT(0), --количество записей с этим ActionId, не назначеных Логином
		SentNum int NOT NULL DEFAULT(0), --количество записей с ненулевым NumAttempts
		LoginomNotSentNum int NOT NULL DEFAULT(0), --LoginomNum - NotFromLoginomNum - SentNum
		Contacts int NOT NULL DEFAULT(0) --количество записей с этим ActionId, по которым есть результат с типом "Контакт"
	)
	CREATE UNIQUE INDEX ix1 ON #t_Action(call_date, ActionCode, CommunicationTypeName)


	IF @Page = 'Statistics' BEGIN

		-- 1 ActionID
		INSERT #t_Action(call_date, ActionCode, CommunicationTypeName, LoginomNum)
		SELECT 
			D.call_date, 
			ActionCode = D.ActionID, 
			D.CommunicationTypeName,
			--количество записей с этим ActionId, назначеных Логином
			LoginomNum = count(*)
		FROM #t_dm_loginom_interaction AS D
		WHERE D.ActionID IS NOT NULL
		GROUP BY D.call_date, D.ActionID, D.CommunicationTypeName

		-- 2 если нет ActionId, то  пишем сюда NaumenCampaignName (для звонков)
		INSERT #t_Action(call_date, ActionCode, CommunicationTypeName)
		SELECT DISTINCT
			D.call_date, 
			ActionCode = D.NaumenCampaignName, 
			D.CommunicationTypeName 
		FROM #t_dm_loginom_interaction AS D
		WHERE D.ActionID IS NULL
			AND D.NaumenCampaignName IS NOT NULL
			AND NOT EXISTS(
				SELECT TOP(1) 1
				FROM #t_Action AS X
				WHERE X.call_date = D.call_date
					AND X.ActionCode = D.NaumenCampaignName
					AND X.CommunicationTypeName = D.CommunicationTypeName
				)

		--3 если нет ActionId, то пишем сюда CommunicationTemplateTheme (для остальных)
		INSERT #t_Action(call_date, ActionCode, CommunicationTypeName)
		SELECT DISTINCT
			D.call_date, 
			ActionCode = D.CommunicationTemplateTheme,
			D.CommunicationTypeName 
		FROM #t_dm_loginom_interaction AS D
		WHERE D.ActionID IS NULL
			AND D.NaumenCampaignName IS NULL
			AND D.CommunicationTemplateTheme IS NOT NULL
			AND NOT EXISTS(
				SELECT TOP(1) 1
				FROM #t_Action AS X
				WHERE X.call_date = D.call_date
					AND X.ActionCode = D.NaumenCampaignName
					AND X.CommunicationTypeName = D.CommunicationTypeName
				)

		--NotFromLoginomNum --количество записей с этим ActionId, не назначеных Логином
		UPDATE T
		SET NotFromLoginomNum = isnull(B.NotFromLoginomNum, 0) + isnull(C.NotFromLoginomNum, 0)
		FROM #t_Action AS T
			--2
			LEFT JOIN (
				SELECT
					D.call_date, 
					ActionCode = D.NaumenCampaignName, 
					D.CommunicationTypeName,
					NotFromLoginomNum = count(*)
				FROM #t_dm_loginom_interaction AS D
				WHERE D.ActionID IS NULL
					AND D.NaumenCampaignName IS NOT NULL
				GROUP BY D.call_date, D.NaumenCampaignName, D.CommunicationTypeName
			) AS B
			ON B.call_date = T.call_date
			AND B.ActionCode = T.ActionCode
			AND B.CommunicationTypeName = T.CommunicationTypeName
			--3
			LEFT JOIN (
				SELECT
					D.call_date, 
					ActionCode = D.CommunicationTemplateTheme, 
					D.CommunicationTypeName,
					NotFromLoginomNum = count(*)
				FROM #t_dm_loginom_interaction AS D
				WHERE D.ActionID IS NULL
					AND D.NaumenCampaignName IS NULL
					AND D.CommunicationTemplateTheme IS NOT NULL
				GROUP BY D.call_date, D.CommunicationTemplateTheme, D.CommunicationTypeName
			) AS C
			ON C.call_date = T.call_date
			AND C.ActionCode = T.ActionCode
			AND C.CommunicationTypeName = T.CommunicationTypeName


		--SentNum --количество записей с ненулевым NumAttempts
		UPDATE T
		SET SentNum = isnull(A.SentNum, 0) + isnull(B.SentNum, 0) + isnull(C.SentNum, 0)
		FROM #t_Action AS T
			--1
			LEFT JOIN (
				SELECT
					D.call_date, 
					ActionCode = D.ActionID, 
					D.CommunicationTypeName,
					SentNum = count(*)
				FROM #t_dm_loginom_interaction AS D
				WHERE D.ActionID IS NOT NULL
					AND isnull(D.Communication_count, 0) <> 0
				GROUP BY D.call_date, D.ActionID, D.CommunicationTypeName
			) AS A
			ON A.call_date = T.call_date
			AND A.ActionCode = T.ActionCode
			AND A.CommunicationTypeName = T.CommunicationTypeName

			--2
			LEFT JOIN (
				SELECT
					D.call_date, 
					ActionCode = D.NaumenCampaignName, 
					D.CommunicationTypeName,
					SentNum = count(*)
				FROM #t_dm_loginom_interaction AS D
				WHERE D.ActionID IS NULL
					AND D.NaumenCampaignName IS NOT NULL
					AND isnull(D.Communication_count, 0) <> 0
				GROUP BY D.call_date, D.NaumenCampaignName, D.CommunicationTypeName
			) AS B
			ON B.call_date = T.call_date
			AND B.ActionCode = T.ActionCode
			AND B.CommunicationTypeName = T.CommunicationTypeName
			--3
			LEFT JOIN (
				SELECT
					D.call_date, 
					ActionCode = D.CommunicationTemplateTheme, 
					D.CommunicationTypeName,
					SentNum = count(*)
				FROM #t_dm_loginom_interaction AS D
				WHERE D.ActionID IS NULL
					AND D.NaumenCampaignName IS NULL
					AND D.CommunicationTemplateTheme IS NOT NULL
					AND isnull(D.Communication_count, 0) <> 0
				GROUP BY D.call_date, D.CommunicationTemplateTheme, D.CommunicationTypeName
			) AS C
			ON C.call_date = T.call_date
			AND C.ActionCode = T.ActionCode
			AND C.CommunicationTypeName = T.CommunicationTypeName

		--LoginomNotSentNum  = LoginomNum - NotFromLoginomNum - SentNum
		--UPDATE T SET LoginomNotSentNum = 0 FROM #t_Action AS T
		UPDATE T
		SET LoginomNotSentNum  = T.LoginomNum - T.NotFromLoginomNum - T.SentNum
		FROM #t_Action AS T
		WHERE T.LoginomNum <> 0


		--Contacts --количество записей с этим ActionId, по которым есть результат с типом "Контакт"
		UPDATE T
		SET Contacts = isnull(A.Contacts, 0) + isnull(B.Contacts, 0) + isnull(C.Contacts, 0)
		FROM #t_Action AS T
			--1
			LEFT JOIN (
				SELECT
					D.call_date, 
					ActionCode = D.ActionID, 
					D.CommunicationTypeName,
					Contacts = count(*)
				FROM #t_dm_loginom_interaction AS D
				WHERE D.ActionID IS NOT NULL
					AND isnull(D.isContact, 0) <> 0
				GROUP BY D.call_date, D.ActionID, D.CommunicationTypeName
			) AS A
			ON A.call_date = T.call_date
			AND A.ActionCode = T.ActionCode
			AND A.CommunicationTypeName = T.CommunicationTypeName

			--2
			LEFT JOIN (
				SELECT
					D.call_date, 
					ActionCode = D.NaumenCampaignName, 
					D.CommunicationTypeName,
					Contacts = count(*)
				FROM #t_dm_loginom_interaction AS D
				WHERE D.ActionID IS NULL
					AND D.NaumenCampaignName IS NOT NULL
					AND isnull(D.isContact, 0) <> 0
				GROUP BY D.call_date, D.NaumenCampaignName, D.CommunicationTypeName
			) AS B
			ON B.call_date = T.call_date
			AND B.ActionCode = T.ActionCode
			AND B.CommunicationTypeName = T.CommunicationTypeName
			--3
			LEFT JOIN (
				SELECT
					D.call_date, 
					ActionCode = D.CommunicationTemplateTheme, 
					D.CommunicationTypeName,
					Contacts = count(*)
				FROM #t_dm_loginom_interaction AS D
				WHERE D.ActionID IS NULL
					AND D.NaumenCampaignName IS NULL
					AND D.CommunicationTemplateTheme IS NOT NULL
					AND isnull(D.isContact, 0) <> 0
				GROUP BY D.call_date, D.CommunicationTemplateTheme, D.CommunicationTypeName
			) AS C
			ON C.call_date = T.call_date
			AND C.ActionCode = T.ActionCode
			AND C.CommunicationTypeName = T.CommunicationTypeName





		SELECT 
			T.id,
			T.call_date,
			T.ActionCode,
			T.CommunicationTypeName,
			T.LoginomNum,
			T.NotFromLoginomNum,
			T.SentNum,
			T.LoginomNotSentNum,
			T.Contacts 
		FROM #t_Action AS T
		ORDER BY T.call_date, T.CommunicationTypeName, T.ActionCode

		RETURN 0
	END
	--// 'Statistics'

END TRY
BEGIN CATCH
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
			ROLLBACK;

	SELECT @message = concat(
		'EXEC dbo.Report_loginom_interaction ',
		'@Page=''', @Page, ''', ',
		--'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		--'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@isDebug=', convert(varchar(10), @isDebug)
	)

	SELECT @eventType = concat(@Page, ' ERROR')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Report_loginom_interaction',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END
