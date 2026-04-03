/*
exec dbo.Report_pravoRuBankruptcy
*/
CREATE PROC dbo.Report_pravoRuBankruptcy
	@Page nvarchar(100) = 'Detail'
	--,@dtFrom date = null
	--,@dtTo date =  null
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
	SELECT @eventType = 'info', @eventName = 'dbo.Report_pravoRuBankruptcy'

	/*
	if @dtFrom is not null
		set @dt_from=@dtFrom
	else 
		SET @dt_from=format(getdate(),'yyyyMM01')

	if @dtTo is not null
		set @dt_to=dateadd(day,1,@dtTo)
	else 
		SET @dt_to=dateadd(day,1,cast(getdate() as date))
	*/

	drop table if exists #t_dm_pravoRuBankruptcy

	SELECT TOP(0) R.*
	INTO #t_dm_pravoRuBankruptcy
	FROM dwh2.collection.pravoRuBankruptcy AS R

	INSERT #t_dm_pravoRuBankruptcy
	SELECT R.*
	FROM dwh2.collection.pravoRuBankruptcy AS R
	WHERE 1=1

	--0. Деталиация
	IF @Page = 'Detail' BEGIN
		SELECT 
			[Номер договора] = R.dealNumber,
			--[ID клиента] = R.CMRClientGUID,
			[ФИО Клиента] = concat_ws(' ', R.clientLastName, R.clientFirstName, R.clientMiddleName),
			--[Фамилия] = R.clientLastName,
			--[Имя] = R.clientFirstName,
			--[Отчество] = R.clientMiddleName,
			[Дата рождения] = R.clientBirthDate,
			[ИНН] = R.clientInn,
			--[ИД дела] = R.caseId,
			[Номер дела] = R.caseNumber,
			[Дата регистрации дела] = R.caseRegistrationDate,
			--[Состояние дела] = R.caseState,
			--[Тип решения по делу] = R.caseDecisionType,
			[Решение по делу] = R.caseDecision,
			[Стадия дела] = R.bankruptcyCaseStage,
			[Статус клиента] = R.collectionCustomerStatus,
			[Дата получения информации] = R.request_date,
			--[ИД ответа] = R.response_Id,
			[Дубли] = R.duplicates,
			[Стадия коллектинга] = R.collectingStage,
			[Продукт]	= R.productType
		FROM #t_dm_pravoRuBankruptcy AS R
		ORDER BY R.request_date, R.response_Id

		RETURN 0
	END

	--по каждому клиенту выбрать последнее дело по Дате регистрации
	drop table if exists #t_LastRegistration

	SELECT TOP(0) R.*, rn = cast(NULL AS int)
	INTO #t_LastRegistration
	FROM #t_dm_pravoRuBankruptcy AS R

	CREATE INDEX ix1
	ON #t_dm_pravoRuBankruptcy(CMRClientGUID, caseRegistrationDate)

	INSERT #t_LastRegistration
	SELECT A.* 
	FROM (
		SELECT 
			R.*,
			rn = row_number() OVER(PARTITION BY R.CMRClientGUID ORDER BY R.caseRegistrationDate DESC)
		FROM #t_dm_pravoRuBankruptcy AS R
		) AS A
	WHERE A.rn = 1

	--1. Вкладка "Неподтвержденные"
	IF @Page = 'Unconfirmed' BEGIN
		SELECT 
			[Номер договора] = R.dealNumber,
			--[ID клиента] = R.CMRClientGUID,
			[ФИО Клиента] = concat_ws(' ', R.clientLastName, R.clientFirstName, R.clientMiddleName),
			--[Фамилия] = R.clientLastName,
			--[Имя] = R.clientFirstName,
			--[Отчество] = R.clientMiddleName,
			[Дата рождения] = R.clientBirthDate,
			[ИНН] = R.clientInn,
			--[ИД дела] = R.caseId,
			[Номер дела] = R.caseNumber,
			[Дата регистрации дела] = R.caseRegistrationDate,
			--[Состояние дела] = R.caseState,
			--[Тип решения по делу] = R.caseDecisionType,
			[Решение по делу] = R.caseDecision,
			[Стадия дела] = R.bankruptcyCaseStage,
			[Статус клиента] = R.collectionCustomerStatus,
			[Дата получения информации] = R.request_date,
			--[ИД ответа] = R.response_Id,
			[Дубли] = R.duplicates,
			[Стадия коллектинга] = R.collectingStage,
			[Продукт]	= R.productType
		FROM #t_LastRegistration AS R
		WHERE R.bankruptcyCaseStage IN (
			'Подано заявление о банкротстве',
			'Заявление принято'
		)
		ORDER BY R.request_date, R.response_Id

		RETURN 0
	END

	--2. Вкладка "Подтвержденные"
	IF @Page = 'Confirmed' BEGIN
		SELECT 
			[Номер договора] = R.dealNumber,
			--[ID клиента] = R.CMRClientGUID,
			[ФИО Клиента] = concat_ws(' ', R.clientLastName, R.clientFirstName, R.clientMiddleName),
			--[Фамилия] = R.clientLastName,
			--[Имя] = R.clientFirstName,
			--[Отчество] = R.clientMiddleName,
			[Дата рождения] = R.clientBirthDate,
			[ИНН] = R.clientInn,
			--[ИД дела] = R.caseId,
			[Номер дела] = R.caseNumber,
			[Дата регистрации дела] = R.caseRegistrationDate,
			--[Состояние дела] = R.caseState,
			--[Тип решения по делу] = R.caseDecisionType,
			[Решение по делу] = R.caseDecision,
			[Стадия дела] = R.bankruptcyCaseStage,
			[Статус клиента] = R.collectionCustomerStatus,
			[Дата получения информации] = R.request_date,
			--[ИД ответа] = R.response_Id,
			[Дубли] = R.duplicates,
			[Стадия коллектинга] = R.collectingStage,
			[Продукт]	= R.productType
		FROM #t_LastRegistration AS R
		WHERE R.bankruptcyCaseStage IN (
			'Реализация имущества гражданина',
			'Реструктуризация долгов гражданина',
			'Конкурсное производство'
		)
		ORDER BY R.request_date, R.response_Id

		RETURN 0
	END

	--3. Вкладка "Завершенные"
	IF @Page = 'Completed' BEGIN
		SELECT 
			[Номер договора] = R.dealNumber,
			--[ID клиента] = R.CMRClientGUID,
			[ФИО Клиента] = concat_ws(' ', R.clientLastName, R.clientFirstName, R.clientMiddleName),
			--[Фамилия] = R.clientLastName,
			--[Имя] = R.clientFirstName,
			--[Отчество] = R.clientMiddleName,
			[Дата рождения] = R.clientBirthDate,
			[ИНН] = R.clientInn,
			--[ИД дела] = R.caseId,
			[Номер дела] = R.caseNumber,
			[Дата регистрации дела] = R.caseRegistrationDate,
			--[Состояние дела] = R.caseState,
			--[Тип решения по делу] = R.caseDecisionType,
			[Решение по делу] = R.caseDecision,
			[Стадия дела] = R.bankruptcyCaseStage,
			[Статус клиента] = R.collectionCustomerStatus,
			[Дата получения информации] = R.request_date,
			--[ИД ответа] = R.response_Id,
			[Дубли] = R.duplicates,
			[Стадия коллектинга] = R.collectingStage,
			[Продукт]	= R.productType
		FROM #t_LastRegistration AS R
		WHERE R.bankruptcyCaseStage IN (
			'Производство прекращено. Должник не признан банкротом',
			'Производство прекращено. Должник признан банкротом'
		)
		ORDER BY R.request_date, R.response_Id

		RETURN 0
	END


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
		'EXEC dbo.Report_pravoRuBankruptcy ',''
		--'@Page=''', @Page, ''', ',
		--'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		--'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+'''')
		--, ', ',
		--'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		--'@isDebug=', convert(varchar(10), @isDebug)
	)

	--SELECT @eventType = concat(@Page, ' error')
	SELECT @eventType = 'error'

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
