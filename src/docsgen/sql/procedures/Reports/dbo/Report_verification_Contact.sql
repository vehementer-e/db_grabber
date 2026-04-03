/*
--Контактность.Детализация
exec dbo.Report_verification_Contact 'Contact.Detail'

--Контактность. Детализ. по сотр.
exec dbo.Report_verification_Contact 'Contact.DetailByEmployee'

-----------------------------------------------------------------------------
Общие данные месяц
-----------------------------------------------------------------------------
--БЕЗЗАЛОГ Общая информация:
exec dbo.Report_verification_Contact 'Contact.Monthly'

--Installment контактность:
--exec dbo.Report_verification_Contact 'Contact.Monthly.Installment'

--PDL контактность:
--exec dbo.Report_verification_Contact 'Contact.Monthly.PDL'

--bigInstallment контактность:
--exec dbo.Report_verification_Contact 'Contact.Monthly.bigInstallment'

--Контактность по всем группам продуктом:
exec dbo.Report_verification_Contact 'Contact.Monthly.ALL'


--БЕЗЗАЛОГ Информация по проверке "Звонок На Мобильный Телефон Клиента" 
exec dbo.Report_verification_Contact 'Contact.Monthly.Mobile'


БЕЗЗАЛОГ Данные по сотрудникам:

--БЕЗЗАЛОГ Контактность общая, % (мес)
exec dbo.Report_verification_Contact 'Contact.Monthly.Employee'

--БЕЗЗАЛОГ Контактность "Звонок На Мобильный Телефон Клиента", % (мес)
exec dbo.Report_verification_Contact 'Contact.Monthly.EmployeeMobile'

--БЕЗЗАЛОГ Контактность "Звонок На Мобильный Телефон Клиента", % (мес) по одобренным
exec dbo.Report_verification_Contact 'Contact.Monthly.EmployeeMobile.Approved'

--БЕЗЗАЛОГ Контактность "Звонок На Мобильный Телефон Клиента", % (мес) по отказным
exec dbo.Report_verification_Contact 'Contact.Monthly.EmployeeMobile.Denied'

-----------------------------------------------------------------------------
Общие данные по дням
-----------------------------------------------------------------------------

--БЕЗЗАЛОГ Общая информация:
exec dbo.Report_verification_Contact 'Contact.Daily'

--Installment контактность:
--exec dbo.Report_verification_Contact 'Contact.Daily.Installment'

--PDL контактность:
--exec dbo.Report_verification_Contact 'Contact.Daily.PDL'

--bigInstallment контактность:
--exec dbo.Report_verification_Contact 'Contact.Daily.bigInstallment'

--Контактность по всем группам продуктов
exec dbo.Report_verification_Contact 'Contact.Daily.ALL'


--БЕЗЗАЛОГ Информация по проверке  "Звонок На Мобильный Телефон Клиента" 
exec dbo.Report_verification_Contact 'Contact.Daily.Mobile'

----------
БЕЗЗАЛОГ Данные по сотрудникам:
----------

--БЕЗЗАЛОГ Контактность общая, % (дн)
exec dbo.Report_verification_Contact 'Contact.Daily.Employee'

--БЕЗЗАЛОГ Контактность "Звонок На Мобильный Телефон Клиента", % (дн)
exec dbo.Report_verification_Contact 'Contact.Daily.EmployeeMobile'

--БЕЗЗАЛОГ Контактность "Звонок На Мобильный Телефон Клиента", % (дн) по одобренным
exec dbo.Report_verification_Contact 'Contact.Daily.EmployeeMobile.Approved'

*/

CREATE PROC dbo.Report_verification_Contact
	@Page nvarchar(100) = 'Contact.Detail'
	,@dtFrom date = null -- '2021-04-01'
	,@dtTo date =  null --'2021-04-26'
	,@ProcessGUID varchar(36) = NULL -- guid процесса
	,@isDebug int = 0
AS
BEGIN

	SET NOCOUNT ON;

BEGIN TRY
	--test
	--select @ProcessGUID = '12187d89-dbc8-4f17-b58d-d152f020c8d6'
	--select @ProcessGUID = null
	--//test

	SELECT @isDebug = isnull(@isDebug, 0)

	IF @Page = 'empty' BEGIN
		--SELECT ProcessGUID = @ProcessGUID
		RETURN 0
	END

	DECLARE @EventDateTime datetime
	DECLARE @delay varchar(12)
	DECLARE @eventType nvarchar(50)
	DECLARE @description nvarchar(1024), @message nvarchar(1024), @error_number int
	DECLARE @isFill_All_Tables bit = 0

	IF @ProcessGUID IS NOT NULL
		AND @Page = 'Fill_All_Tables'
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1
			FROM LogDb.dbo.Fill_Report_verification_Contact AS F
			WHERE F.ReportPage = @Page
				AND F.ProcessGUID = @ProcessGUID
			)
		BEGIN
			--идет процесс заполнения или выборки таблиц
			RETURN 0
		END
		ELSE BEGIN
			BEGIN TRY
				--BEGIN TRAN

				INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), @Page, @ProcessGUID

				--COMMIT
			END TRY
			BEGIN CATCH
				SELECT @error_number = ERROR_NUMBER()
				SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
					+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
					+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')

				IF @error_number = 2601 --Cannot insert duplicate key row in object
				BEGIN
					-- параллельный процесс уже начал заполнение
					RETURN 0
				END
				ELSE BEGIN
					;THROW 51000, @description, 1
				END
			END CATCH
		END
	END


	IF @ProcessGUID IS NOT NULL
		AND @Page NOT IN ('Fill_All_Tables', 'Clear_All_Tables')
	BEGIN
		IF NOT EXISTS(
			SELECT TOP 1 1
			FROM LogDb.dbo.Fill_Report_verification_Contact AS F
			WHERE F.ReportPage = @Page
				AND F.ProcessGUID = @ProcessGUID
			)
		BEGIN
			--таблица для @Page НЕ заполнена
			--вызвать заполнение всех таблиц и ждать

			SELECT @delay = '00:00:00.' + convert(varchar(3), round(1000 * rand(), 0))
			WAITFOR DELAY @delay


		    EXEC dbo.Report_verification_Contact
				@Page = 'Fill_All_Tables', 
				@dtFrom = @dtFrom,
				@dtTo = @dtTo,
				@ProcessGUID = @ProcessGUID


			SELECT @EventDateTime = getdate()

			WHILE 
				-- НЕ появились данные для @Page
				NOT EXISTS(
					SELECT TOP 1 1
					FROM LogDb.dbo.Fill_Report_verification_Contact AS F
					WHERE F.ReportPage = @Page
						AND F.ProcessGUID = @ProcessGUID
				)
				-- И не превышено время ожидания
				AND datediff(SECOND, @EventDateTime, getdate()) < 1800 --600 30min
			BEGIN
				WAITFOR DELAY '00:00:10'
			END

			-- превышено время ожидания
			IF datediff(SECOND, @EventDateTime, getdate()) >= 1800 --600 30min
			BEGIN
				--вернуть ошибку
				;THROW 51000, 'Превышено время ожидания заполнения всех таблиц (30 минут).', 1
			END
		END

		--вернуть данные
	END


	SELECT @message = concat(
		'EXEC dbo.Report_verification_Contact ',
		'@Page=''', @Page, ''', ',
		'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@isDebug=', convert(varchar(10), @isDebug)
	)

	SELECT @description =
		(
		SELECT
			'@Page' = @Page,
			'@dtFrom' = @dtFrom,
			'@dtTo' = @dtTo,
			'@ProcessGUID' = @ProcessGUID
			--'@isDebug' = @isDebug,
			--'suser_sname' = suser_sname(),
			--'app_name' = app_name()
		FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
		)

	SELECT @eventType = concat(@Page, ' START') 

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Report_verification_Contact',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID

IF @ProcessGUID IS NULL BEGIN
	IF @Page = 'Fill_All_Tables' BEGIN
		--SELECT ProcessGUID = @ProcessGUID
		RETURN 0
	END

	IF @Page = 'Clear_All_Tables' BEGIN
		--SELECT ProcessGUID = @ProcessGUID
		RETURN 0
	END
END
-- @ProcessGUID IS NOT NULL 
ELSE BEGIN

	IF @Page = 'Fill_All_Tables' BEGIN
		SELECT @isFill_All_Tables = 1
	END

	IF @Page = 'Contact.Detail' BEGIN
		--WAITFOR DELAY '00:00:02'

		SELECT T.*
		FROM tmp.TMP_Report_verification_Contact_Contact_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID
		ORDER BY T.[ФИО сотрудника верификации/чекер], T.[Дата рассмотрения заявки] desc, T.[Номер заявки] desc
	END
	IF @Page = 'Contact.DetailByEmployee' BEGIN
		--WAITFOR DELAY '00:00:02'

		SELECT T.*
		FROM tmp.TMP_Report_verification_Contact_Contact_DetailByEmployee AS T
		WHERE T.ProcessGUID = @ProcessGUID
		ORDER BY T.[Номер заявки] DESC, T.ПорядковыйНомерЗвонка
	END

	IF @Page = 'Contact.Monthly' BEGIN
		--WAITFOR DELAY '00:00:02'

		SELECT T.*
		FROM tmp.TMP_Report_verification_Contact_Contact_Monthly AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'Contact.Monthly.ALL' BEGIN
		--WAITFOR DELAY '00:00:02'
		SELECT T.*
		FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_ALL AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'Contact.Monthly.Mobile' BEGIN
		--WAITFOR DELAY '00:00:02'

		SELECT T.*
		FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_Mobile AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END


	IF @Page = 'Contact.Monthly.Employee' BEGIN
		--WAITFOR DELAY '00:00:02'

		SELECT T.*
		FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_Employee AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'Contact.Monthly.EmployeeMobile' BEGIN
		--WAITFOR DELAY '00:00:02'

		SELECT T.*
		FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_EmployeeMobile AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'Contact.Monthly.EmployeeMobile.Approved' BEGIN
		--WAITFOR DELAY '00:00:02'

		SELECT T.*
		FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_EmployeeMobile_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'Contact.Monthly.EmployeeMobile.Denied' BEGIN
		--WAITFOR DELAY '00:00:02'

		SELECT T.*
		FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_EmployeeMobile_Denied AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'Contact.Daily' BEGIN
		--WAITFOR DELAY '00:00:02'

		SELECT T.*
		FROM tmp.TMP_Report_verification_Contact_Contact_Daily AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'Contact.Daily.ALL' BEGIN
		--WAITFOR DELAY '00:00:02'
		SELECT T.*
		FROM tmp.TMP_Report_verification_Contact_Contact_Daily_ALL AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'Contact.Daily.Mobile' BEGIN
		--WAITFOR DELAY '00:00:02'

		SELECT T.*
		FROM tmp.TMP_Report_verification_Contact_Contact_Daily_Mobile AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END


	IF @Page = 'Contact.Daily.Employee' BEGIN
		--WAITFOR DELAY '00:00:02'

		SELECT T.*
		FROM tmp.TMP_Report_verification_Contact_Contact_Daily_Employee AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'Contact.Daily.EmployeeMobile' BEGIN
		--WAITFOR DELAY '00:00:02'

		SELECT T.*
		FROM tmp.TMP_Report_verification_Contact_Contact_Daily_EmployeeMobile AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'Contact.Daily.EmployeeMobile.Approved' BEGIN
		--WAITFOR DELAY '00:00:02'

		SELECT T.*
		FROM tmp.TMP_Report_verification_Contact_Contact_Daily_EmployeeMobile_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	--TO DO
	--...
	----------------

	IF @Page NOT IN ('Fill_All_Tables', 'Clear_All_Tables')
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1
			FROM LogDb.dbo.Fill_Report_verification_Contact AS F
			WHERE F.ReportPage = @Page
				AND F.ProcessGUID = @ProcessGUID
			)
		BEGIN
			--таблица для @Page заполнена
			--почистить Fill
			--BEGIN TRAN

			--test
			--/*
			DELETE F
			FROM LogDb.dbo.Fill_Report_verification_Contact AS F 
			WHERE F.ReportPage = @Page AND F.ProcessGUID = @ProcessGUID
			--*/

			-- если это последний вызов (нет больше записей, кроме 'Fill_All_Tables'),
			-- удалить запись 'Fill_All_Tables'
			IF NOT EXISTS(
				SELECT TOP 1 1
				FROM LogDb.dbo.Fill_Report_verification_Contact AS F
				WHERE F.ReportPage <> 'Fill_All_Tables'
					AND F.ProcessGUID = @ProcessGUID
			)
			AND EXISTS(
				SELECT TOP 1 1
				FROM LogDb.dbo.Fill_Report_verification_Contact AS F
				WHERE F.ReportPage = 'Fill_All_Tables'
					AND F.ProcessGUID = @ProcessGUID
					AND F.EndDateTime IS NOT NULL
			)
			--EndDateTime
			BEGIN
				--test
				--/*
				DELETE F
				FROM LogDb.dbo.Fill_Report_verification_Contact AS F 
				WHERE F.ReportPage = 'Fill_All_Tables' AND F.ProcessGUID = @ProcessGUID
				--*/

				--очистить все таблицы
				EXEC dbo.Report_verification_Contact
					@Page = 'Clear_All_Tables', 
					@dtFrom = @dtFrom,
					@dtTo = @dtTo,
					@ProcessGUID = @ProcessGUID
			END

			--COMMIT
		END

		RETURN 0
	END


	--------------------------------------------------------------
	IF @Page = 'Clear_All_Tables' BEGIN
		--test
		--RETURN 0

		--waitfor DELAY '00:01:00'

		-- очистить все таблицы
		DELETE T
		FROM tmp.TMP_Report_verification_Contact_Contact_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_Contact_Contact_DetailByEmployee AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_Contact_Contact_Monthly AS T
		WHERE T.ProcessGUID = @ProcessGUID


		DELETE T
		FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_ALL AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_Mobile AS T
		WHERE T.ProcessGUID = @ProcessGUID


		DELETE T
		FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_Employee AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_EmployeeMobile AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_EmployeeMobile_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_EmployeeMobile_Denied AS T
		WHERE T.ProcessGUID = @ProcessGUID


		DELETE T
		FROM tmp.TMP_Report_verification_Contact_Contact_Daily AS T
		WHERE T.ProcessGUID = @ProcessGUID


		DELETE T
		FROM tmp.TMP_Report_verification_Contact_Contact_Daily_ALL AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_Contact_Contact_Daily_Mobile AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_Contact_Contact_Daily_Employee AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_Contact_Contact_Daily_EmployeeMobile AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_Contact_Contact_Daily_EmployeeMobile_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID

		--TO DO
		--...
		----------------

		RETURN 0
	END
END


DROP TABLE IF EXISTS #t_ProductType
CREATE TABLE #t_ProductType(
	ProductType_Code varchar(100),
	ProductType_Name varchar(100),
	ProductType_Order int
)
INSERT #t_ProductType
(
	ProductType_Code,
	ProductType_Name,
	ProductType_Order
)
select 
	ProductType_Code = t.code,
	ProductType_Name = t.name,
	ProductType_Order = t.ord
from (
	values
		('installment', 'Installment', 1)
		,('pdl', 'PDL', 2)
		,('bigInstallment', 'Big Installment', 3)
		,('bigInstallmentMarket', 'Big Installment Рыночный', 4)
		,('bigInstallmentMarketSelfEmployed', 'Big Installment Рыночный для Самозанятых', 5)
) t (code, name, ord)

IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##t_ProductType
	SELECT * INTO ##t_ProductType FROM #t_ProductType
END

--test
IF @Page NOT IN (
	'Fill_All_Tables',
	--
	'Contact.Detail',
	'Contact.DetailByEmployee',

	'Contact.Monthly', -- copy from 'V.Monthly.Common'
	'Contact.Monthly.Employee', -- copy from 'VK.Monthly.Contact'
	'Contact.Daily', -- copy from 'V.Daily.Common'
	'Contact.Daily.Employee', -- copy from 'VK.Daily.Contact'

	--'Contact.Monthly.Installment',
	--'Contact.Monthly.PDL',
	--'Contact.Monthly.bigInstallment',
	'Contact.Monthly.ALL',

	'Contact.Monthly.Mobile',
	'Contact.Monthly.EmployeeMobile',
	'Contact.Monthly.EmployeeMobile.Approved',
	'Contact.Monthly.EmployeeMobile.Denied',

	--'Contact.Daily.Installment',
	--'Contact.Daily.PDL',
	--'Contact.Daily.bigInstallment',
	'Contact.Daily.ALL',

	'Contact.Daily.Mobile',
	'Contact.Daily.EmployeeMobile',
	'Contact.Daily.EmployeeMobile.Approved'
)
BEGIN
    RETURN 0
END




declare @dt_from date
if @dtFrom is not null
    set @dt_from=@dtFrom
else set @dt_from=format(getdate(),'yyyyMM01')

declare @dt_to date
if @dtTo is not null
    set @dt_to=dateadd(day,1,@dtTo)
else set @dt_to=dateadd(day,1,cast(getdate() as date))

declare @dt_from_hours datetime = @dt_from
declare @dt_to_hours datetime = @dt_to

--DWH-2067
DROP TABLE IF EXISTS #t_Contact_Call
CREATE TABLE #t_Contact_Call
(
	SortOrder int,
	call_type_name varchar(255),
	result_name varchar(255),
	isSuccess int
)

INSERT #t_Contact_Call
(
	SortOrder,
	call_type_name,
	result_name,
	isSuccess
)
SELECT DISTINCT
	SortOrder = 
		CASE CheckListItemType.Name
			WHEN 'Звонок работодателю по телефонам из Контур Фокуса' THEN 1
			WHEN 'Звонок работодателю по телефонам из Интернет' THEN 2
			WHEN 'Звонок работодателю по телефонам из Анкеты' THEN 3
			WHEN 'Звонок контактному лицу' THEN 4
			WHEN 'Звонок на мобильный телефон клиента' THEN 5
			ELSE 99
		END,
	call_type_name = CheckListItemType.Name COLLATE Cyrillic_General_CI_AS,
	result_name = CheckListItemStatus.Name COLLATE Cyrillic_General_CI_AS,
	isSuccess = 
		CASE CheckListItemType.Name
			--1
			WHEN 'Звонок работодателю по телефонам из Контур Фокуса'
			THEN 
				CASE
					WHEN CheckListItemStatus.Name IN (
						'Занятость подтверждена',
						'Подтверждают только по письменному запросу',
						'Телефон не актуален/принадлежит другой компании',
						'Декрет',
						'Негативная информация от работодателя',
						'Занятость опровергли /не работает / уволили'
					)
					THEN 1
					ELSE 0
				END

			--2
			WHEN 'Звонок работодателю по телефонам из Интернет'
			THEN 
				CASE 
					WHEN CheckListItemStatus.Name IN (
						'Занятость подтверждена',
						'Занятость подтверждена самим клиентом',
						'Подтверждают только по письменному запросу',
						'Телефон не актуален/принадлежит другой компании',
						'Декрет',
						'Негативная информация от работодателя',
						'Занятость опровергли /не работает / уволили'
					)
					THEN 1
					ELSE 0
				END

			--3
			WHEN 'Звонок работодателю по телефонам из Анкеты'
			THEN 
				CASE 
					WHEN CheckListItemStatus.Name IN (
						'Занятость подтверждена',
						'Занятость подтверждена самим клиентом',
						'Подтверждают только по письменному запросу',
						'Телефон принадлежит другой компании',
						'Декрет',
						'Негативная информация от работодателя',
						'Занятость опровергли /не работает / уволили'
					)
					THEN 1
					ELSE 0
				END
						
			--4
			WHEN 'Звонок контактному лицу'
			THEN 
				CASE 
					WHEN CheckListItemStatus.Name IN (
						'КЛ знает клиента, положительная хар-ка',
						'Контактное лицо не знает клиента/номер не существует, клиент подтвердил корректность номера',
						'КЛ не знает клиента/номер не существует, клиент подтвердил номер',
						'КЛ не знает клиента/номер не существует, не удалось подтвердить номер',
						'Негатив от КЛ (должник, алкоголик, наркоман)'
					)
					THEN 1
					ELSE 0
				END

			--5
			WHEN 'Звонок на мобильный телефон клиента'
			THEN 
				CASE 
					WHEN CheckListItemStatus.Name IN (
						'Клиент идентифицирован, моб тел принадлежит клиенту',
						'Клиенту не удобно разговаривать, просит перезвонить',
						'Клиент идентифицирован, cбросил звонок, далее не отвечает',
						'Отказ клиента',
						'Декрет',
						'Мобильный телефон клиента принадлежит 3-му лицу (близкому родственнику)',
						'Идентификация не пройдена (не может назвать свое ФИО, дату рождения)',
						'Отказ клиента , клиент не оформлял займ',
						'Кредит для 3-х лиц',
						'Клиент дает противоречивую инф-ю',
						'Клиент "Олень" (приведен 3-ми лицами)',
						'Клиент подтвердил, что обратился за кредитом под влиянием 3х лиц',
						'Мобильный телефон клиента принадлежит 3-му лицу. Подозрение в мошенничестве',
						'Клиент пьян',
						'Отвечает 3-е лицо',
						'Отказ клиента, клиент не оформлял займ'
					)
					THEN 1
					ELSE 0
				END

			--
			ELSE 0
		END
FROM Stg._fedor.dictionary_CheckListItemType AS CheckListItemType
	INNER JOIN Stg._fedor.core_CheckListItemTypeAndCheckListItemStatus AS CH_IT_IS
		ON CH_IT_IS.IdType = CheckListItemType.Id
	INNER JOIN Stg._fedor.dictionary_CheckListItemStatus AS CheckListItemStatus
		ON CheckListItemStatus.Id = CH_IT_IS.IdCheckListItemStatus
WHERE 1=1
	AND CheckListItemType.Name IN (
		'Звонок работодателю по телефонам из Контур Фокуса',
		'Звонок работодателю по телефонам из Интернет',
		'Звонок работодателю по телефонам из Анкеты',
		'Звонок контактному лицу',
		'Звонок на мобильный телефон клиента'
	)
-- звонок назначен, но еще не выполнен
UNION SELECT 1, 'Звонок работодателю по телефонам из Контур Фокуса','назначен', 0
UNION SELECT 2, 'Звонок работодателю по телефонам из Интернет','назначен', 0
UNION SELECT 3, 'Звонок работодателю по телефонам из Анкеты','назначен', 0
UNION SELECT 4, 'Звонок контактному лицу','назначен', 0
UNION SELECT 5, 'Звонок на мобильный телефон клиента','назначен', 0



--Дата рассмотрения заявки = Дата, когда был выбран результат в чек-листе
DROP TABLE IF EXISTS #t_checklists

;with loginom_checklists AS (
	SELECT 
		max_CheckList_CreatedOn = max(cli.CreatedOn),
		max_Comment_CreatedOn = max(CC.CreatedOn),
		cli.IdClientRequest
	FROM Stg._fedor.core_CheckListItem AS cli
		INNER JOIN Stg._fedor.dictionary_CheckListItemStatus AS cis
			ON cis.id = cli.IdStatus
		--при расчете контактности учитываются только результаты "звонковых" проверок, то есть в рамках которых был осуществлен звонок
		--в изначальном документе, по которому создавался данный отчет в разделе ПТС и Инстолмент 
		--в пунктах 4 прописаны звонковые проверки и результаты (во вложении отчет по контактности)
		INNER JOIN #t_Contact_Call AS C
			ON cis.Name COLLATE Cyrillic_General_CI_AS = C.result_name
		--DWH-2679
		LEFT JOIN Stg._fedor.core_Comment AS CC
			ON CC.IdEntityParent = cli.IdClientRequest
			AND CC.[IdEntity] = cli.Id
	WHERE 1=1
		AND cli.CreatedOn >= dateadd(HOUR, -3, cast(@dt_from AS datetime2))
		AND cli.CreatedOn <= dateadd(HOUR, -3, cast(@dt_to AS datetime2))
	GROUP BY cli.IdClientRequest
)
SELECT 
	cli.IdClientRequest,
	Number = CR.Number COLLATE Cyrillic_General_CI_AS,
	max_CheckList_CreatedOn = dateadd(HOUR, 3, rl.max_CheckList_CreatedOn),
	--max_Comment_CreatedOn = dateadd(HOUR, 3, rl.max_Comment_CreatedOn),
	max_Comment_CreatedOn = dateadd(HOUR, 3, isnull(rl.max_Comment_CreatedOn, max_CheckList_CreatedOn)),
	CheckListItemTypeName = cit.[Name],
	CheckListItemStatusName = cis.[Name]
into #t_checklists
FROM Stg._fedor.core_CheckListItem AS cli
	JOIN Stg._fedor.dictionary_CheckListItemType AS cit ON cit.id = cli.IdType
	JOIN Stg._fedor.dictionary_CheckListItemStatus AS cis ON cis.id = cli.IdStatus
	JOIN loginom_checklists AS rl 
		ON rl.IdClientRequest = cli.IdClientRequest 
		--AND try_cast(replace(cis.LoginomNumber,'.','') AS bigint) = rl.logn
		AND rl.max_CheckList_CreatedOn = cli.CreatedOn
	INNER JOIN Stg._fedor.core_ClientRequest AS CR
		ON CR.Id = cli.IdClientRequest

CREATE INDEX ix1 ON #t_checklists(IdClientRequest)
CREATE INDEX ix2 ON #t_checklists(Number)

  



DROP TABLE IF EXISTS #t_dm_FedorVerificationRequests_Contact
CREATE TABLE #t_dm_FedorVerificationRequests_Contact
(
	[Тип продукта] varchar(100) NULL,
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
	[ФИО сотрудника верификации/чекер] [nvarchar](255) NOT NULL,
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
	[ПризнакИсключенияСотрудника] [int] NOT NULL,
	[Работник] [nvarchar](100) NOT NULL,
	[Назначен] [nvarchar](100) NOT NULL,
	[Работник_Пред] [nvarchar](100) NULL,
	[Назначен_Пред] [nvarchar](100) NULL,
	[Работник_След] [nvarchar](100) NULL,
	[Назначен_След] [nvarchar](100) NULL,
	[ЗвонокРаботодателюПоТелефонамИзКонтурФокус] int NULL,
	[ЗвонокРаботодателюПоТелефонамИзИнтернет] int NULL,
	[ЗвонокРаботодателюПоТелефонуИзАнкеты] int NULL,
	[ЗвонокКонтактномуЛицу] int NULL,
	[ЗвонокНаМобильныйТелефонКлиента] int NULL,
	ТипКлиента varchar(30) NULL,
	isSkipped bit NULL,
	[Дата рассмотрения заявки] datetime2
)


-- v.2 общая витрина для беззалога
INSERT #t_dm_FedorVerificationRequests_Contact
(
	[Тип продукта],
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
	ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
	ЗвонокРаботодателюПоТелефонамИзИнтернет,
	ЗвонокРаботодателюПоТелефонуИзАнкеты,
	ЗвонокКонтактномуЛицу,
	ЗвонокНаМобильныйТелефонКлиента,
	ТипКлиента,
	isSkipped,
	[Дата рассмотрения заявки]
)
SELECT 
	--[Тип продукта] = R.ProductType_Code,
	--DWH-411
	[Тип продукта] = isnull(R.КодПодТипКредитногоПродукта, R.КодТипКредитногоПродукта),
	N.IdClientRequest,
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
	ЗвонокРаботодателюПоТелефонамИзКонтурФокус = C1.isSuccess,
	ЗвонокРаботодателюПоТелефонамИзИнтернет = C2.isSuccess,
	ЗвонокРаботодателюПоТелефонуИзАнкеты = C3.isSuccess,
	ЗвонокКонтактномуЛицу = C4.isSuccess,
	ЗвонокНаМобильныйТелефонКлиента = C5.isSuccess,
	R.ТипКлиента,
	R.isSkipped,
	[Дата рассмотрения заявки] = N.max_Comment_CreatedOn
FROM #t_checklists AS N
	INNER JOIN dbo.dm_FedorVerificationRequests_without_coll AS R --(NOLOCK)
		ON R.[Номер заявки] = N.Number
	LEFT JOIN #t_Contact_Call AS C1
		ON C1.call_type_name = 'Звонок работодателю по телефонам из Контур Фокуса'
		AND C1.result_name = R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус
	LEFT JOIN #t_Contact_Call AS C2
		ON C2.call_type_name = 'Звонок работодателю по телефонам из Интернет'
		AND C2.result_name = R.ЗвонокРаботодателюПоТелефонамИзИнтернет
	LEFT JOIN #t_Contact_Call AS C3
		ON C3.call_type_name = 'Звонок работодателю по телефонам из Анкеты'
		AND C3.result_name = R.ЗвонокРаботодателюПоТелефонуИзАнкеты
	LEFT JOIN #t_Contact_Call AS C4
		ON C4.call_type_name = 'Звонок контактному лицу'
		AND C4.result_name = R.ЗвонокКонтактномуЛицу
	LEFT JOIN #t_Contact_Call AS C5
		ON C5.call_type_name = 'Звонок на мобильный телефон клиента'
		AND C5.result_name = R.ЗвонокНаМобильныйТелефонКлиента
WHERE 1=1
--	AND R.[Дата статуса] > @dt_from
--	AND R.[Дата статуса] < @dt_to
	AND N.max_Comment_CreatedOn >= @dt_from
	AND N.max_Comment_CreatedOn <= @dt_to




/*
Корнеева Вероника Игоревна
сменила фамилию на
Столица Вероника Игоревна
*/
UPDATE T
SET 
	[ФИО сотрудника верификации/чекер] = replace([ФИО сотрудника верификации/чекер], 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна'),
	СотрудникПоследнегоСтатуса = replace(СотрудникПоследнегоСтатуса, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна'),
	Работник = replace(Работник, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна'),
	Назначен = replace(Назначен, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна'),
	Работник_Пред = replace(Работник_Пред, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна'),
	Назначен_Пред = replace(Назначен_Пред, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна'),
	Работник_След = replace(Работник_След, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна'),
	Назначен_След = replace(Назначен_След, 'Корнеева Вероника Игоревна', 'Столица Вероника Игоревна')
FROM #t_dm_FedorVerificationRequests_Contact AS T


CREATE INDEX ix1 ON #t_dm_FedorVerificationRequests_Contact([Номер заявки], [Дата статуса]) INCLUDE([Статус следующий])

IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##t_dm_FedorVerificationRequests_Contact
	SELECT * INTO ##t_dm_FedorVerificationRequests_Contact FROM #t_dm_FedorVerificationRequests_Contact
END


drop table if exists #curr_employee_test
create table #curr_employee_test([Employee] nvarchar(255))

INSERT #curr_employee_test(Employee)
/*
--select *
select substring(trim(U.DisplayName), 1, 255)
FROM [dwh-ex].bot.dbo.[vw_ActiveDirectoryUsers] AS U
where U.Department ='Отдел тестирования'
UNION */
SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
FROM Stg._fedor.core_user AS U
WHERE U.IsQAUser = 1

DELETE R
FROM #t_dm_FedorVerificationRequests_Contact AS R
WHERE 1=1
	AND R.Работник IN (SELECT Employee FROM #curr_employee_test)


DELETE R
FROM #t_dm_FedorVerificationRequests_Contact AS R
WHERE 1=1
	AND R.[ФИО сотрудника верификации/чекер] IN (SELECT Employee FROM #curr_employee_test)

CREATE CLUSTERED INDEX clix1 
--ON #t_dm_FedorVerificationRequests_Contact([Номер заявки], [Дата статуса])
ON #t_dm_FedorVerificationRequests_Contact([Номер заявки], [Дата рассмотрения заявки])


-- статические справочники
--select  distinct [ФИО сотрудника верификации/чекер] from #t_dm_FedorVerificationRequests_Contact
--insert into  feodor.dbo.KDEmployees select 'Силаева Татьяна Владимировна',getdate()
-- сотрудники КД
drop table if exists #curr_employee_cd
create table #curr_employee_cd([Employee] nvarchar(255))
  
--DWH-1988
INSERT #curr_employee_cd(Employee)
SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
FROM Stg._fedor.core_user AS U
	INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
		ON UR.IdUser = U.Id
	INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
		ON R.Id = UR.IdUserRole
WHERE 1=1
--AND UR.IsDeleted = 0
	AND R.Name IN ('Чекер','Чекер аутсорс','Супервизор аутсорс')
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


IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##curr_employee_cd
	SELECT * INTO ##curr_employee_cd FROM #curr_employee_cd
END
   
---- Верификаторы
drop table if exists #curr_employee_vr
create table #curr_employee_vr([Employee] nvarchar(255))

--DWH-1988
INSERT #curr_employee_vr(Employee)
SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
FROM Stg._fedor.core_user AS U
	INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
		ON UR.IdUser = U.Id
	INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
		ON R.Id = UR.IdUserRole
WHERE 1=1
	AND R.Name IN ('Верификатор'
			,'Чекер','Чекер аутсорс','Супервизор аутсорс'
	)
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







 
DROP TABLE IF EXISTS #t_request_number
CREATE TABLE #t_request_number(
	IdClientRequest uniqueidentifier, 
	[Номер заявки] nvarchar(255),
	[Дата рассмотрения заявки] datetime2
)

DROP TABLE IF EXISTS #t_approved
CREATE TABLE #t_approved([Номер заявки] nvarchar(255), [Дата статуса] datetime2(7))

DROP TABLE IF EXISTS #t_denied
CREATE TABLE #t_denied([Номер заявки] nvarchar(255), [Дата статуса] datetime2(7))

DROP TABLE IF EXISTS #t_canceled
CREATE TABLE #t_canceled([Номер заявки] nvarchar(255), [Дата статуса] datetime2(7))

DROP TABLE IF EXISTS #t_customer_rejection
CREATE TABLE #t_customer_rejection([Номер заявки] nvarchar(255), [Дата статуса] datetime2(7))

DROP TABLE IF EXISTS #t_final_approved
CREATE TABLE #t_final_approved([Номер заявки] nvarchar(255), [Дата статуса] datetime2(7))

DROP TABLE IF EXISTS #t_checklists_rejects
CREATE TABLE #t_checklists_rejects
(
	IdClientRequest uniqueidentifier,
	Number nvarchar(255),
	CheckListItemTypeName nvarchar(255),
	CheckListItemStatusName nvarchar(255)
)




--подготовка данных
--DELETE #t_request_number
--DELETE #t_approved
--DELETE #t_denied
--DELETE #t_canceled
--DELETE #t_customer_rejection
--DELETE #t_checklists_rejects

--request numbers
INSERT #t_request_number(IdClientRequest, [Номер заявки])
SELECT DISTINCT R.IdClientRequest, R.[Номер заявки]
FROM #t_dm_FedorVerificationRequests_Contact AS R
--WHERE R.[Статус] in ('Верификация клиента') --теперь Отказные заявки не доходят до статуса 'Верификация Call 3'

CREATE INDEX ix1 ON #t_request_number(IdClientRequest)
CREATE INDEX ix2 ON #t_request_number([Номер заявки])

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
	WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number AS R WHERE R.IdClientRequest = cli.IdClientRequest)
	GROUP BY cli.IdClientRequest
)
INSERT #t_checklists_rejects
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
WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number AS R WHERE R.IdClientRequest = cli.IdClientRequest)

CREATE INDEX ix_IdClientRequest ON #t_checklists_rejects(IdClientRequest)

--одобрено
INSERT #t_approved([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_Contact AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 
	(
		--R.Статус IN ('Верификация Call 3') AND R.[Статус следующий] IN ('Одобрено')
		--DWH-2361
		R.Статус IN ('Верификация Call 3')
		AND EXISTS(
				SELECT TOP(1) 1
				FROM #t_dm_FedorVerificationRequests_Contact AS N
				WHERE R.[Номер заявки] = N.[Номер заявки]
					AND N.[Дата статуса] >= R.[Дата статуса]
					AND N.[Статус следующий] in (
						'Одобрено',
						'Предодобр перед Call 5'
					)
			)
	)
	OR 
	(
		--DWH-2683
		R.Статус IN ('Верификация Call 1.5')
		AND EXISTS(
				SELECT TOP(1) 1
				FROM #t_dm_FedorVerificationRequests_Contact AS N
				WHERE R.[Номер заявки] = N.[Номер заявки]
					AND N.[Дата статуса] >= R.[Дата статуса]
					AND N.[Статус следующий] in (
						'Переподписание первого пакета'
					)
			)
	)
GROUP BY R.[Номер заявки]

--2 одобрено сотрудником, но отказано автоматически
INSERT #t_approved([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_Contact AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	--AND R.Статус IN ('Верификация Call 3')
	--Отказные заявки не доходят до статуса 'Верификация Call 3', 
	--отказ сотрудником происходит на статусе 'Верификация Call 1.5'
	AND R.Статус IN ('Верификация Call 1.5')
	--AND R.[Статус следующий] IN ('Отказано')
	--DWH-2683
	AND EXISTS(
			SELECT TOP(1) 1
			FROM #t_dm_FedorVerificationRequests_Contact AS N
			WHERE R.[Номер заявки] = N.[Номер заявки]
				AND N.[Дата статуса] >= R.[Дата статуса]
				AND N.[Статус следующий] in ('Отказано')
		)
	AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
GROUP BY R.[Номер заявки]

CREATE INDEX ix1 ON #t_approved([Номер заявки])

--отказано
INSERT #t_denied([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_Contact AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	--AND R.Статус IN ('Верификация Call 3')
	--Отказные заявки не доходят до статуса 'Верификация Call 3', 
	--отказ сотрудником происходит на статусе 'Верификация Call 1.5'
	AND R.Статус IN ('Верификация Call 1.5')
	--AND R.[Статус следующий] IN ('Отказано')
	--DWH-2683
	AND EXISTS(
			SELECT TOP(1) 1
			FROM #t_dm_FedorVerificationRequests_Contact AS N
			WHERE R.[Номер заявки] = N.[Номер заявки]
				AND N.[Дата статуса] >= R.[Дата статуса]
				AND N.[Статус следующий] in ('Отказано')
		)
	AND EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
GROUP BY R.[Номер заявки]

CREATE INDEX ix1 ON #t_denied([Номер заявки])

--анулировано
INSERT #t_canceled([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_Contact AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	--AND R.Статус IN ('Верификация Call 3') 
	--Отказные заявки не доходят до статуса 'Верификация Call 3', 
	--отказ сотрудником происходит на статусе 'Верификация Call 1.5'
	AND R.Статус IN ('Верификация Call 1.5')
	--AND R.[Статус следующий] IN ('Аннулировано')
	--DWH-2683
	AND EXISTS(
			SELECT TOP(1) 1
			FROM #t_dm_FedorVerificationRequests_Contact AS N
			WHERE R.[Номер заявки] = N.[Номер заявки]
				AND N.[Дата статуса] >= R.[Дата статуса]
				AND N.[Статус следующий] in ('Аннулировано')
		)
	AND NOT EXISTS(
			SELECT TOP(1) 1
			FROM #t_approved AS A
			WHERE R.[Номер заявки] = A.[Номер заявки]
		)
GROUP BY R.[Номер заявки]

CREATE INDEX ix1 ON #t_canceled([Номер заявки])

--Отказ клиента
INSERT #t_customer_rejection([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_Contact AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	AND R.Статус IN ('Верификация Call 1.5')
	--AND R.[Статус следующий] IN ('Отказ клиента')
	--DWH-2683
	AND EXISTS(
			SELECT TOP(1) 1
			FROM #t_dm_FedorVerificationRequests_Contact AS N
			WHERE R.[Номер заявки] = N.[Номер заявки]
				AND N.[Дата статуса] >= R.[Дата статуса]
				AND N.[Статус следующий] in ('Отказ клиента')
		)
	AND NOT EXISTS(
			SELECT TOP(1) 1
			FROM #t_approved AS A
			WHERE R.[Номер заявки] = A.[Номер заявки]
		)
GROUP BY R.[Номер заявки]

CREATE INDEX ix1 ON #t_customer_rejection([Номер заявки])


IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##t_request_number
	SELECT * INTO ##t_request_number FROM #t_request_number

	DROP TABLE IF EXISTS ##t_approved
	SELECT * INTO ##t_approved FROM #t_approved

	DROP TABLE IF EXISTS ##t_denied
	SELECT * INTO ##t_denied FROM #t_denied

	DROP TABLE IF EXISTS ##t_canceled
	SELECT * INTO ##t_canceled FROM #t_canceled

	DROP TABLE IF EXISTS ##t_customer_rejection
	SELECT * INTO ##t_customer_rejection FROM #t_customer_rejection

	DROP TABLE IF EXISTS ##t_checklists_rejects
	SELECT * INTO ##t_checklists_rejects FROM #t_checklists_rejects
END





DROP TABLE IF EXISTS #t_Report_verification_Contact_Contact_DetailByEmployee
CREATE TABLE #t_Report_verification_Contact_Contact_DetailByEmployee
(
	[ProcessGUID] [varchar] (36) NULL,
	[Тип продукта] [varchar] (100) NULL,
	[Дата рассмотрения заявки] [date] NULL,
	[Дата заведения заявки] [date] NULL,
	[Время заведения] [time] NULL,
	[Номер заявки] [nvarchar] (255) NULL,
	[ФИО клиента] [nvarchar] (767) NULL,
	[ФИО сотрудника верификации/чекер] [nvarchar] (100) NULL,
	[Решение по заявке] [varchar] (13) NOT NULL,
	[ПорядковыйНомерЗвонка] [int] NULL,
	[ТипЗвонка] [varchar] (255) NULL,
	[РезультатЗвонка] [varchar] (255) NULL,
	[Дозвон] [int] NULL,
	[ИтогоКонтактность] [int] NULL
)


--IF @Page IN (
--		'Contact.DetailByEmployee',
--		'Contact.Monthly.Mobile',
--		'Contact.Daily.Mobile',
--		'Contact.Monthly.EmployeeMobile'
--	)
--	OR @isFill_All_Tables = 1
--BEGIN

INSERT #t_Report_verification_Contact_Contact_DetailByEmployee
(
	ProcessGUID,
	[Тип продукта],
	[Дата рассмотрения заявки],
	[Дата заведения заявки],
	[Время заведения],
	[Номер заявки],
	[ФИО клиента],
	[ФИО сотрудника верификации/чекер],
	[Решение по заявке],
	ПорядковыйНомерЗвонка,
	ТипЗвонка,
	РезультатЗвонка,
	Дозвон,
	ИтогоКонтактность
)
SELECT DISTINCT
	ProcessGUID = Request.ProcessGUID,
	Request.[Тип продукта],
	Request.[Дата рассмотрения заявки],
	Request.[Дата заведения заявки],
	Request.[Время заведения],
	Request.[Номер заявки],
	Request.[ФИО клиента],
	[ФИО сотрудника верификации/чекер] = trim(concat(Users.LastName, ' ', Users.FirstName, ' ', Users.MiddleName)),
	Request.[Решение по заявке],
	ПорядковыйНомерЗвонка = call_type.SortOrder,
	ТипЗвонка = CheckListItemType.Name COLLATE Cyrillic_General_CI_AS,
	РезультатЗвонка = CheckListItemStatus.Name COLLATE Cyrillic_General_CI_AS,
	--Дозвон = Contact_Call.isSuccess,
	--DWH-2683
	Дозвон = iif(trim(concat(Users.LastName, ' ', Users.FirstName, ' ', Users.MiddleName))<>'', Contact_Call.isSuccess, NULL),
	Request.ИтогоКонтактность
FROM 
	(
		SELECT DISTINCT
			C.ProcessGUID,
			C.[Тип продукта],
			C.[Дата рассмотрения заявки],
			C.[Дата заведения заявки],
			C.[Время заведения],
			C.[Номер заявки],
			C.[ФИО клиента],
			--C.Статус,
			--C.Задача,
			--C.[Состояние заявки],
			--C.[Дата статуса],
			--C.[ФИО сотрудника верификации/чекер],
			--C.Назначен,
			--C.ВремяЗатрачено,
			--C.[Время, час:мин:сек],
			--C.[Статус следующий],
			--C.[Задача следующая],
			--C.[Состояние заявки следующая],
			C.[Решение по заявке],
			C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
			C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
			C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
			C.ЗвонокКонтактномуЛицу,
			C.ЗвонокНаМобильныйТелефонКлиента,
			C.ИтогоКонтактность	
		FROM (
			SELECT
				ProcessGUID = @ProcessGUID,
				R.[Тип продукта],
				[Дата рассмотрения заявки] = cast(R.[Дата рассмотрения заявки] AS date),
				R.[Дата заведения заявки]
					, R.[Время заведения]
					, R.[Номер заявки]
					, R.[ФИО клиента]
					, R.[Статус]
					, R.[Задача]
					, R.[Состояние заявки]
					, R.[Дата статуса]
					-- 20210326
					, [ФИО сотрудника верификации/чекер] = R.Работник
					, R.Назначен
					, R.[ВремяЗатрачено]
				, R.[Время, час:мин:сек]
					, R.[Статус следующий]
					, R.[Задача следующая]
					, R.[Состояние заявки следующая]
					--DWH-1720
				--, [Решение по заявке] = trim(
				--	concat(
				--		iif(approved.[Номер заявки] IS NOT NULL,'Одобрено',''),' ',
				--		iif(denied.[Номер заявки] IS NOT NULL,'Отказано',''),' ',
				--		iif(canceled.[Номер заявки] IS NOT NULL,'Аннулировано',''), ' ',
				--		iif(customer_rejection.[Номер заявки] IS NOT NULL,'Отказ клиента','')
				--		)
				--)
				, [Решение по заявке] = 
				CASE 
					WHEN canceled.[Номер заявки] IS NOT NULL THEN 'Аннулировано'
					WHEN denied.[Номер заявки] IS NOT NULL THEN 'Отказано'
					WHEN approved.[Номер заявки] IS NOT NULL THEN 'Одобрено'
					WHEN customer_rejection.[Номер заявки] IS NOT NULL THEN 'Отказ клиента'
					ELSE ''
				END
				, R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус
				, R.ЗвонокРаботодателюПоТелефонамИзИнтернет
				, R.ЗвонокРаботодателюПоТелефонуИзАнкеты
				, R.ЗвонокКонтактномуЛицу
				, R.ЗвонокНаМобильныйТелефонКлиента
				, ИтогоКонтактность = 
					isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
					isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
					isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
					isnull(R.ЗвонокКонтактномуЛицу, 0) +
					isnull(R.ЗвонокНаМобильныйТелефонКлиента, 0)
			--INTO tmp.TMP_Report_verification_Contact_Contact_Detail
			FROM #t_request_number AS N
				INNER JOIN #t_dm_FedorVerificationRequests_Contact AS R
					ON R.[Номер заявки] = N.[Номер заявки]
				--одобрено
				LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
				--отказано
				LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
				--анулировано
				LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
				--Отказ клиента
				LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
			--WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
			WHERE 1=1
				--AND R.[Статус] in ('Верификация клиента') --теперь Отказные заявки не доходят до статуса 'Верификация Call 3'
				--DWH-2430 Убрать автоодобренные на ВК заявки из расчета контактности
				--комментарю после объединения КД и ВК
				--AND isnull(R.isSkipped, 0) = 0
			--order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc
		) AS C
		WHERE 1=1
			--AND C.[Решение по заявке] IN ('Отказано', 'Одобрено')
	) AS Request
	INNER JOIN Stg._fedor.core_ClientRequest AS ClientRequest
		ON ClientRequest.Number COLLATE Cyrillic_General_CI_AS = Request.[Номер заявки]
	INNER JOIN Stg._fedor.core_CheckListItem AS CheckListItem
		ON ClientRequest.Id = CheckListItem.IdClientRequest
	INNER JOIN Stg._fedor.dictionary_CheckListItemType AS CheckListItemType
		ON CheckListItemType.Id = CheckListItem.IdType

	-- типы звонков
	INNER JOIN (
		SELECT DISTINCT 
			CC.SortOrder,
			call_type_name = CC.call_type_name
		FROM #t_Contact_Call AS CC
		) AS call_type
		ON call_type.call_type_name = CheckListItemType.Name COLLATE Cyrillic_General_CI_AS

	LEFT JOIN Stg._fedor.core_CheckListItemTypeAndCheckListItemStatus AS CH_IT_IS
		ON CH_IT_IS.IdType = CheckListItem.IdType
		AND CH_IT_IS.IdCheckListItemStatus = CheckListItem.IdStatus
	LEFT JOIN Stg._fedor.dictionary_CheckListItemStatus AS CheckListItemStatus
		ON CheckListItemStatus.Id = CheckListItem.IdStatus
	LEFT JOIN Stg._fedor.core_Comment AS Comment
		ON Comment.[IdEntity] = CheckListItem.Id
	LEFT JOIN Stg._fedor.core_user AS Users
		ON Users.Id = Comment.IdOwner

	LEFT JOIN #t_Contact_Call AS Contact_Call
		ON Contact_Call.call_type_name = CheckListItemType.Name COLLATE Cyrillic_General_CI_AS
		AND Contact_Call.result_name = CheckListItemStatus.Name COLLATE Cyrillic_General_CI_AS
--WHERE 1=1
--	AND CheckListItemType.Name IN (
--		'Звонок работодателю по телефонам из Контур Фокуса',
--		'Звонок работодателю по телефонам из Интернет',
--		'Звонок работодателю по телефонам из Анкеты',
--		'Звонок контактному лицу',
--		'Звонок на мобильный телефон клиента'
--	)
--ORDER BY [Номер заявки] DESC, ПорядковыйНомерЗвонка


CREATE INDEX ix1
ON #t_Report_verification_Contact_Contact_DetailByEmployee([Номер заявки])
INCLUDE (ТипЗвонка, РезультатЗвонка, [ФИО сотрудника верификации/чекер])

IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##t_Report_verification_Contact_Contact_DetailByEmployee
	SELECT * INTO ##t_Report_verification_Contact_Contact_DetailByEmployee FROM #t_Report_verification_Contact_Contact_DetailByEmployee
END

--END


--DWH-2067
--Лист "Контактность. Детализация"
IF @Page = 'Contact.Detail' OR @isFill_All_Tables = 1
BEGIN
	DROP TABLE IF EXISTS #t_Contact_Detail

	SELECT DISTINCT
		C.ProcessGUID,
		C.[Тип продукта],
		C.[Дата рассмотрения заявки],
		C.[Дата заведения заявки],
		C.[Время заведения],
		C.[Номер заявки],
		C.[ФИО клиента],
		--C.Статус,
		--C.Задача,
		--C.[Состояние заявки],
		--C.[Дата статуса],
		--C.[ФИО сотрудника верификации/чекер],
		--C.Назначен,
		--C.ВремяЗатрачено,
		--C.[Время, час:мин:сек],
		--C.[Статус следующий],
		--C.[Задача следующая],
		--C.[Состояние заявки следующая],
		C.[Решение по заявке],
		C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
		C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
		C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
		C.ЗвонокКонтактномуЛицу,
		C.ЗвонокНаМобильныйТелефонКлиента,
		C.ИтогоКонтактность	
	INTO #t_Contact_Detail
	FROM (
		SELECT
			ProcessGUID = @ProcessGUID,
			R.[Тип продукта],
			[Дата рассмотрения заявки] = cast(R.[Дата рассмотрения заявки] AS date),
			R.[Дата заведения заявки]
				, R.[Время заведения]
				, R.[Номер заявки]
				, R.[ФИО клиента]
				, R.[Статус]
				, R.[Задача]
				, R.[Состояние заявки]
				, R.[Дата статуса]
				-- 20210326
				, [ФИО сотрудника верификации/чекер] = R.Работник
				, R.Назначен
				, R.[ВремяЗатрачено]
			, R.[Время, час:мин:сек]
				, R.[Статус следующий]
				, R.[Задача следующая]
				, R.[Состояние заявки следующая]
				--DWH-1720
			--, [Решение по заявке] = trim(
			--	concat(
			--		iif(approved.[Номер заявки] IS NOT NULL,'Одобрено',''),' ',
			--		iif(denied.[Номер заявки] IS NOT NULL,'Отказано',''),' ',
			--		iif(canceled.[Номер заявки] IS NOT NULL,'Аннулировано',''), ' ',
			--		iif(customer_rejection.[Номер заявки] IS NOT NULL,'Отказ клиента','')
			--		)
			--)
			, [Решение по заявке] = 
			CASE 
				WHEN canceled.[Номер заявки] IS NOT NULL THEN 'Аннулировано'
				WHEN denied.[Номер заявки] IS NOT NULL THEN 'Отказано'
				WHEN approved.[Номер заявки] IS NOT NULL THEN 'Одобрено'
				WHEN customer_rejection.[Номер заявки] IS NOT NULL THEN 'Отказ клиента'
				ELSE ''
			END
			, R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус
			, R.ЗвонокРаботодателюПоТелефонамИзИнтернет
			, R.ЗвонокРаботодателюПоТелефонуИзАнкеты
			, R.ЗвонокКонтактномуЛицу
			, R.ЗвонокНаМобильныйТелефонКлиента
			--DWH-2683
			--, ЗвонокРаботодателюПоТелефонамИзКонтурФокус =iif(trim(isnull(R.Работник, '')) <> '', R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, NULL)
			--, ЗвонокРаботодателюПоТелефонамИзИнтернет = iif(trim(isnull(R.Работник, '')) <> '', R.ЗвонокРаботодателюПоТелефонамИзИнтернет, NULL)
			--, ЗвонокРаботодателюПоТелефонуИзАнкеты = iif(trim(isnull(R.Работник, '')) <> '', R.ЗвонокРаботодателюПоТелефонуИзАнкеты, NULL)
			--, ЗвонокКонтактномуЛицу = iif(trim(isnull(R.Работник, '')) <> '', R.ЗвонокКонтактномуЛицу, NULL)
			--, ЗвонокНаМобильныйТелефонКлиента = iif(trim(isnull(R.Работник, '')) <> '', R.ЗвонокНаМобильныйТелефонКлиента, NULL)

			, ИтогоКонтактность = 
				isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
				isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
				isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
				isnull(R.ЗвонокКонтактномуЛицу, 0) +
				isnull(R.ЗвонокНаМобильныйТелефонКлиента, 0)
		--INTO tmp.TMP_Report_verification_Contact_Contact_Detail
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_Contact AS R
				ON R.[Номер заявки] = N.[Номер заявки]
			--одобрено
			LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
			--отказано
			LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
			--анулировано
			LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
			--Отказ клиента
			LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
		--WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
		WHERE 1=1
			--AND R.[Статус] in ('Верификация клиента') --теперь Отказные заявки не доходят до статуса 'Верификация Call 3'
			--DWH-2430 Убрать автоодобренные на ВК заявки из расчета контактности
			--комментарю после объединения КД и ВК
			--AND isnull(R.isSkipped, 0) = 0
		--order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc
	) AS C
	WHERE 1=1
		--AND C.[Решение по заявке] IN ('Отказано', 'Одобрено')
	--ORDER BY C.[ФИО сотрудника верификации/чекер], C.[Дата статуса] desc, C.[Номер заявки] desc
	--ORDER BY C.[Номер заявки] DESC

	CREATE INDEX ix_НомерЗаявки ON #t_Contact_Detail([Номер заявки])

	-- исключить заявки, по которым "Проверка не проводилась (системная)"
	-- для таких заявок в "детализации по сотрудникам" не указан [ФИО сотрудника верификации/чекер]
	UPDATE C
	SET 
		C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус = iif(D1.[Номер заявки] IS NULL, NULL, C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус),
		C.ЗвонокРаботодателюПоТелефонамИзИнтернет = iif(D2.[Номер заявки] IS NULL, NULL, C.ЗвонокРаботодателюПоТелефонамИзИнтернет),
		C.ЗвонокРаботодателюПоТелефонуИзАнкеты = iif(D3.[Номер заявки] IS NULL, NULL, C.ЗвонокРаботодателюПоТелефонуИзАнкеты),
		C.ЗвонокКонтактномуЛицу = iif(D4.[Номер заявки] IS NULL, NULL, C.ЗвонокКонтактномуЛицу),
		C.ЗвонокНаМобильныйТелефонКлиента = iif(D5.[Номер заявки] IS NULL, NULL, C.ЗвонокНаМобильныйТелефонКлиента)
	FROM #t_Contact_Detail AS C
		LEFT JOIN #t_Report_verification_Contact_Contact_DetailByEmployee AS D1
			ON D1.[Номер заявки] = C.[Номер заявки]
			AND D1.ТипЗвонка = 'Звонок работодателю по телефонам из Контур Фокуса'
			AND D1.[ФИО сотрудника верификации/чекер] <> ''
		LEFT JOIN #t_Report_verification_Contact_Contact_DetailByEmployee AS D2
			ON D2.[Номер заявки] = C.[Номер заявки]
			AND D2.ТипЗвонка = 'Звонок работодателю по телефонам из Интернет'
			AND D2.[ФИО сотрудника верификации/чекер] <> ''
		LEFT JOIN #t_Report_verification_Contact_Contact_DetailByEmployee AS D3
			ON D3.[Номер заявки] = C.[Номер заявки]
			AND D3.ТипЗвонка = 'Звонок работодателю по телефонам из Анкеты'
			AND D3.[ФИО сотрудника верификации/чекер] <> ''
		LEFT JOIN #t_Report_verification_Contact_Contact_DetailByEmployee AS D4
			ON D4.[Номер заявки] = C.[Номер заявки]
			AND D4.ТипЗвонка = 'Звонок контактному лицу'
			AND D4.[ФИО сотрудника верификации/чекер] <> ''
		LEFT JOIN #t_Report_verification_Contact_Contact_DetailByEmployee AS D5
			ON D5.[Номер заявки] = C.[Номер заявки]
			AND D5.ТипЗвонка = 'Звонок на мобильный телефон клиента'
			AND D5.[ФИО сотрудника верификации/чекер] <> ''


	IF @isFill_All_Tables = 1
	BEGIN
		DELETE T FROM tmp.TMP_Report_verification_Contact_Contact_Detail AS T WHERE T.ProcessGUID = @ProcessGUID

		INSERT tmp.TMP_Report_verification_Contact_Contact_Detail
		(
		    ProcessGUID,
			[Тип продукта],
			[Дата рассмотрения заявки],
		    [Дата заведения заявки],
		    [Время заведения],
		    [Номер заявки],
		    [ФИО клиента],
		    [Решение по заявке],
		    ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
		    ЗвонокРаботодателюПоТелефонамИзИнтернет,
		    ЗвонокРаботодателюПоТелефонуИзАнкеты,
		    ЗвонокКонтактномуЛицу,
		    ЗвонокНаМобильныйТелефонКлиента,
		    ИтогоКонтактность
		)
		SELECT 
			C.ProcessGUID,
			--C.[Тип продукта],
			[Тип продукта] = isnull(pt.ProductType_Name, C.[Тип продукта]),
			C.[Дата рассмотрения заявки],
			C.[Дата заведения заявки],
			C.[Время заведения],
			C.[Номер заявки],
			C.[ФИО клиента],
			C.[Решение по заявке],
			C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
			C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
			C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
			C.ЗвонокКонтактномуЛицу,
			C.ЗвонокНаМобильныйТелефонКлиента,
			C.ИтогоКонтактность
		FROM #t_Contact_Detail AS C
			left join #t_ProductType as pt
				on pt.ProductType_Code = C.[Тип продукта]
		ORDER BY C.[Номер заявки] DESC

		--WAITFOR DELAY '00:00:01'

		INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
		SELECT getdate(), 'Contact.Detail', @ProcessGUID
	END
	ELSE BEGIN
		SELECT 
			C.ProcessGUID,
			--C.[Тип продукта],
			[Тип продукта] = isnull(pt.ProductType_Name, C.[Тип продукта]),
			C.[Дата рассмотрения заявки],
			C.[Дата заведения заявки],
			C.[Время заведения],
			C.[Номер заявки],
			C.[ФИО клиента],
			C.[Решение по заявке],
			C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
			C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
			C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
			C.ЗвонокКонтактномуЛицу,
			C.ЗвонокНаМобильныйТелефонКлиента,
			C.ИтогоКонтактность
		FROM #t_Contact_Detail AS C
			left join #t_ProductType as pt
				on pt.ProductType_Code = C.[Тип продукта]
		ORDER BY C.[Номер заявки] DESC

		RETURN 0
	END
END
--// 'Contact.Detail'



--Лист "Контактность. Детализация по сотрудникам"
IF @Page = 'Contact.DetailByEmployee' OR @isFill_All_Tables = 1
BEGIN
	IF @isFill_All_Tables = 1
	BEGIN
		DELETE T FROM tmp.TMP_Report_verification_Contact_Contact_DetailByEmployee AS T WHERE T.ProcessGUID = @ProcessGUID

		INSERT tmp.TMP_Report_verification_Contact_Contact_DetailByEmployee
		(
		    ProcessGUID,
			[Тип продукта],
			[Дата рассмотрения заявки],
		    [Дата заведения заявки],
		    [Время заведения],
		    [Номер заявки],
		    [ФИО клиента],
		    [ФИО сотрудника верификации/чекер],
		    [Решение по заявке],
		    ПорядковыйНомерЗвонка,
		    ТипЗвонка,
		    РезультатЗвонка,
		    Дозвон,
		    ИтогоКонтактность
		)
		SELECT
		    d.ProcessGUID,
			--[Тип продукта],
			[Тип продукта] = isnull(pt.ProductType_Name, d.[Тип продукта]),
			d.[Дата рассмотрения заявки],
		    d.[Дата заведения заявки],
		    d.[Время заведения],
		    d.[Номер заявки],
		    d.[ФИО клиента],
		    d.[ФИО сотрудника верификации/чекер],
		    d.[Решение по заявке],
		    d.ПорядковыйНомерЗвонка,
		    d.ТипЗвонка,
		    d.РезультатЗвонка,
		    d.Дозвон,
		    d.ИтогоКонтактность
		FROM #t_Report_verification_Contact_Contact_DetailByEmployee as d
			left join #t_ProductType as pt
				on pt.ProductType_Code = d.[Тип продукта]

		--WAITFOR DELAY '00:00:01'

		INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
		SELECT getdate(), 'Contact.DetailByEmployee', @ProcessGUID
	END
	ELSE BEGIN
		SELECT
		    --ProcessGUID,
			--[Тип продукта],
			[Тип продукта] = isnull(pt.ProductType_Name, d.[Тип продукта]),
			d.[Дата рассмотрения заявки],
		    d.[Дата заведения заявки],
		    d.[Время заведения],
		    d.[Номер заявки],
		    d.[ФИО клиента],
		    d.[ФИО сотрудника верификации/чекер],
		    d.[Решение по заявке],
		    d.ПорядковыйНомерЗвонка,
		    d.ТипЗвонка,
		    d.РезультатЗвонка,
		    d.Дозвон,
		    d.ИтогоКонтактность
		FROM #t_Report_verification_Contact_Contact_DetailByEmployee as d
			left join #t_ProductType as pt
				on pt.ProductType_Code = d.[Тип продукта]
		ORDER BY [Номер заявки] DESC, ПорядковыйНомерЗвонка

		RETURN 0
	END
END
--// 'Contact.DetailByEmployee'







DROP TABLE IF EXISTS #t_Contact_Month

CREATE TABLE #t_Contact_Month(
	--[Дата статуса] date,
	[Дата рассмотрения заявки] date,
	[Контактность общая] nvarchar(50),
	[Контактность по одобренным] nvarchar(50),
	[Контактность по отказным] nvarchar(50)
)

--IF @Page = 'V.Monthly.Common' OR @isFill_All_Tables = 1
IF @Page IN (
		'Contact.Monthly',
		'Contact.Monthly.Employee'
	)
	OR @isFill_All_Tables = 1
BEGIN
	INSERT #t_Contact_Month
	(
		--[Дата статуса],
		[Дата рассмотрения заявки],
		[Контактность общая],
		[Контактность по одобренным],
		[Контактность по отказным]
	)
	SELECT 
		--B.[Дата статуса],
		B.[Дата рассмотрения заявки],
		[Контактность общая] =
			cast(
				format(
					CASE 
						WHEN B.КоличествоЗаявок <> 0
						THEN 100.0 * B.КоличествоДозвон / B.КоличествоЗаявок
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50)),
		[Контактность по одобренным] = 
			cast(
				format(
					CASE 
						WHEN B.КоличествоОдобрено <> 0
						THEN 100.0 * B.КоличествоОдобреноДозвон / B.КоличествоОдобрено
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50)),
		[Контактность по отказным] = 
			cast(
				format(
					CASE 
						WHEN B.КоличествоОтказано <> 0
						THEN 100.0 * B.КоличествоОтказаноДозвон / B.КоличествоОтказано
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50))
	FROM (
		SELECT 
			--A.[Дата статуса],
			A.[Дата рассмотрения заявки],
			КоличествоЗаявок = count(*),
			КоличествоДозвон = sum(A.Дозвон),

			КоличествоОдобрено = sum(iif(A.[Решение по заявке]='Одобрено',1,0)),
			КоличествоОдобреноДозвон = sum(iif(A.[Решение по заявке]='Одобрено',1,0) * A.Дозвон),

			КоличествоОтказано = sum(iif(A.[Решение по заявке]='Отказано',1,0)),
			КоличествоОтказаноДозвон = sum(iif(A.[Решение по заявке]='Отказано',1,0) * A.Дозвон)
		FROM (
			SELECT DISTINCT
				--[Дата статуса] = cast(format(R.[Дата статуса],'yyyyMM01') as date),
				[Дата рассмотрения заявки] = cast(format(R.[Дата рассмотрения заявки],'yyyyMM01') as date),
				R.[Номер заявки],
				[Решение по заявке] = 
					CASE 
						WHEN canceled.[Номер заявки] IS NOT NULL THEN 'Аннулировано'
						WHEN denied.[Номер заявки] IS NOT NULL THEN 'Отказано'
						WHEN approved.[Номер заявки] IS NOT NULL THEN 'Одобрено'
						WHEN customer_rejection.[Номер заявки] IS NOT NULL THEN 'Отказ клиента'
						ELSE ''
					END,
				--Одобрено = iif(approved.[Номер заявки] IS NOT NULL, 1, 0),
				--Отказано = iif(denied.[Номер заявки] IS NOT NULL, 1, 0),
				Дозвон = 
					iif(
						isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
						isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
						isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
						isnull(R.ЗвонокКонтактномуЛицу, 0) +
						isnull(R.ЗвонокНаМобильныйТелефонКлиента, 0) > 0,
						1, 0
					)
			FROM #t_request_number AS N
					INNER JOIN #t_dm_FedorVerificationRequests_Contact AS R
					ON R.[Номер заявки] = N.[Номер заявки]
				--одобрено
				LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
				--отказано
				LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
				--анулировано
				LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
				--Отказ клиента
				LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
			--WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
			WHERE 1=1
				--AND R.[Статус] in ('Верификация клиента') --теперь Отказные заявки не доходят до статуса 'Верификация Call 3'
				--DWH-2430 Убрать автоодобренные на ВК заявки из расчета контактности
				--комментарю после объединения КД и ВК
				--AND isnull(R.isSkipped, 0) = 0
		) AS A
		--WHERE A.[Решение по заявке] IN ('Отказано', 'Одобрено')
		--GROUP BY A.[Дата статуса]
		GROUP BY A.[Дата рассмотрения заявки]
	) AS B
END


--Контактность по всем группам продуктов
DROP TABLE IF EXISTS #t_Contact_Month_ALL

CREATE TABLE #t_Contact_Month_ALL(
	[Тип продукта] varchar(100),
	--[Дата статуса] date,
	[Дата рассмотрения заявки] date,
	[Контактность общая] nvarchar(50),
	[Контактность по одобренным] nvarchar(50),
	[Контактность по отказным] nvarchar(50)
)

IF @Page = 'Contact.Monthly.ALL' OR @isFill_All_Tables = 1
BEGIN
	INSERT #t_Contact_Month_ALL
	(
		[Тип продукта],
		--[Дата статуса],
		[Дата рассмотрения заявки],
		[Контактность общая],
		[Контактность по одобренным],
		[Контактность по отказным]
	)
	SELECT 
		B.[Тип продукта],
		--B.[Дата статуса],
		B.[Дата рассмотрения заявки],
		[Контактность общая] =
			cast(
				format(
					CASE 
						WHEN B.КоличествоЗаявок <> 0
						THEN 100.0 * B.КоличествоДозвон / B.КоличествоЗаявок
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50)),
		[Контактность по одобренным] = 
			cast(
				format(
					CASE 
						WHEN B.КоличествоОдобрено <> 0
						THEN 100.0 * B.КоличествоОдобреноДозвон / B.КоличествоОдобрено
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50)),
		[Контактность по отказным] = 
			cast(
				format(
					CASE 
						WHEN B.КоличествоОтказано <> 0
						THEN 100.0 * B.КоличествоОтказаноДозвон / B.КоличествоОтказано
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50))
	FROM (
		SELECT 
			A.[Тип продукта],
			--A.[Дата статуса],
			A.[Дата рассмотрения заявки],
			КоличествоЗаявок = count(*),
			КоличествоДозвон = sum(A.Дозвон),

			КоличествоОдобрено = sum(iif(A.[Решение по заявке]='Одобрено',1,0)),
			КоличествоОдобреноДозвон = sum(iif(A.[Решение по заявке]='Одобрено',1,0) * A.Дозвон),

			КоличествоОтказано = sum(iif(A.[Решение по заявке]='Отказано',1,0)),
			КоличествоОтказаноДозвон = sum(iif(A.[Решение по заявке]='Отказано',1,0) * A.Дозвон)
		FROM (
			SELECT DISTINCT
				R.[Тип продукта],
				--[Дата статуса] = cast(format(R.[Дата статуса],'yyyyMM01') as date),
				[Дата рассмотрения заявки] = cast(format(R.[Дата рассмотрения заявки],'yyyyMM01') as date),
				R.[Номер заявки],
				[Решение по заявке] = 
					CASE 
						WHEN canceled.[Номер заявки] IS NOT NULL THEN 'Аннулировано'
						WHEN denied.[Номер заявки] IS NOT NULL THEN 'Отказано'
						WHEN approved.[Номер заявки] IS NOT NULL THEN 'Одобрено'
						WHEN customer_rejection.[Номер заявки] IS NOT NULL THEN 'Отказ клиента'
						ELSE ''
					END,
				--Одобрено = iif(approved.[Номер заявки] IS NOT NULL, 1, 0),
				--Отказано = iif(denied.[Номер заявки] IS NOT NULL, 1, 0),
				Дозвон = 
					iif(
						isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
						isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
						isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
						isnull(R.ЗвонокКонтактномуЛицу, 0) +
						isnull(R.ЗвонокНаМобильныйТелефонКлиента, 0) > 0,
						1, 0
					)
			FROM #t_request_number AS N
					INNER JOIN #t_dm_FedorVerificationRequests_Contact AS R
					ON R.[Номер заявки] = N.[Номер заявки]
				--одобрено
				LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
				--отказано
				LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
				--анулировано
				LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
				--Отказ клиента
				LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
			--WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
			WHERE 1=1
				--AND R.[Статус] in ('Верификация клиента') --теперь Отказные заявки не доходят до статуса 'Верификация Call 3'
				--DWH-2430 Убрать автоодобренные на ВК заявки из расчета контактности
				--комментарю после объединения КД и ВК
				--AND isnull(R.isSkipped, 0) = 0
				--AND R.[Тип продукта] = 'installment'
		) AS A
		--WHERE A.[Решение по заявке] IN ('Отказано', 'Одобрено')
		--GROUP BY A.[Дата статуса]
		GROUP BY A.[Тип продукта], A.[Дата рассмотрения заявки]
	) AS B
END




-- Mobile
DROP TABLE IF EXISTS #t_Contact_Month_Mobile

CREATE TABLE #t_Contact_Month_Mobile(
	--[Дата статуса] date,
	[Дата рассмотрения заявки] date,
	[Контактность общая] nvarchar(50),
	[Контактность по одобренным] nvarchar(50),
	[Контактность по отказным] nvarchar(50)
)

IF @Page IN (
		'Contact.Monthly.Mobile', 
		'Contact.Monthly.EmployeeMobile',
		'Contact.Monthly.EmployeeMobile.Approved',
		'Contact.Monthly.EmployeeMobile.Denied'
	)
	OR @isFill_All_Tables = 1
BEGIN
	INSERT #t_Contact_Month_Mobile
	(
		--[Дата статуса],
		[Дата рассмотрения заявки],
		[Контактность общая],
		[Контактность по одобренным],
		[Контактность по отказным]
	)
	SELECT 
		--B.[Дата статуса],
		B.[Дата рассмотрения заявки],
		[Контактность общая] =
			cast(
				format(
					CASE 
						WHEN B.КоличествоЗаявок <> 0
						THEN 100.0 * B.КоличествоДозвон / B.КоличествоЗаявок
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50)),
		[Контактность по одобренным] = 
			cast(
				format(
					CASE 
						WHEN B.КоличествоОдобрено <> 0
						THEN 100.0 * B.КоличествоОдобреноДозвон / B.КоличествоОдобрено
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50)),
		[Контактность по отказным] = 
			cast(
				format(
					CASE 
						WHEN B.КоличествоОтказано <> 0
						THEN 100.0 * B.КоличествоОтказаноДозвон / B.КоличествоОтказано
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50))
	FROM (
		SELECT 
			--A.[Дата статуса],
			A.[Дата рассмотрения заявки],
			КоличествоЗаявок = count(*),
			КоличествоДозвон = sum(A.Дозвон),

			КоличествоОдобрено = sum(iif(A.[Решение по заявке]='Одобрено',1,0)),
			КоличествоОдобреноДозвон = sum(iif(A.[Решение по заявке]='Одобрено',1,0) * A.Дозвон),

			КоличествоОтказано = sum(iif(A.[Решение по заявке]='Отказано',1,0)),
			КоличествоОтказаноДозвон = sum(iif(A.[Решение по заявке]='Отказано',1,0) * A.Дозвон)
		FROM (
			SELECT DISTINCT
				--[Дата статуса] = cast(format(R.[Дата статуса],'yyyyMM01') as date),
				[Дата рассмотрения заявки] = cast(format(R.[Дата рассмотрения заявки],'yyyyMM01') as date),
				R.[Номер заявки],
				[Решение по заявке] = 
					CASE 
						WHEN canceled.[Номер заявки] IS NOT NULL THEN 'Аннулировано'
						WHEN denied.[Номер заявки] IS NOT NULL THEN 'Отказано'
						WHEN approved.[Номер заявки] IS NOT NULL THEN 'Одобрено'
						WHEN customer_rejection.[Номер заявки] IS NOT NULL THEN 'Отказ клиента'
						ELSE ''
					END,
				--Mobile
				--БЕЗЗАЛОГ Информация по проверке  "Звонок На Мобильный Телефон Клиента" 
				Дозвон = 
					iif(
						--isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
						--isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
						--isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
						--isnull(R.ЗвонокКонтактномуЛицу, 0) +
						isnull(R.ЗвонокНаМобильныйТелефонКлиента, 0) > 0,
						1, 0
					)
			FROM #t_request_number AS N
					INNER JOIN #t_dm_FedorVerificationRequests_Contact AS R
					ON R.[Номер заявки] = N.[Номер заявки]
				--одобрено
				LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
				--отказано
				LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
				--анулировано
				LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
				--Отказ клиента
				LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
			--WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
			WHERE 1=1
				--AND R.[Статус] in ('Верификация клиента') --теперь Отказные заявки не доходят до статуса 'Верификация Call 3'
				--DWH-2430 Убрать автоодобренные на ВК заявки из расчета контактности
				--комментарю после объединения КД и ВК
				--AND isnull(R.isSkipped, 0) = 0

				--evseenkova: исключить заявки, у которых "Звонок на мобильный телефон клиента" не проводился
				--AND NOT EXISTS (
				--	SELECT TOP(1) 1 
				--	FROM #t_Report_verification_Contact_Contact_DetailByEmployee AS Contact
				--	WHERE Contact.[Номер заявки] = R.[Номер заявки]
				--		AND Contact.ТипЗвонка = 'Звонок на мобильный телефон клиента'
				--		AND Contact.РезультатЗвонка = 'Проверка не проводилась (системная)'
				--		--trim(Contact.[ФИО сотрудника верификации/чекер]) <> ''
				--)

				--DWH-2683
				AND EXISTS (
					SELECT TOP(1) 1 
					FROM #t_Report_verification_Contact_Contact_DetailByEmployee AS T
					WHERE T.[Номер заявки] = R.[Номер заявки]
						AND T.ТипЗвонка = 'Звонок на мобильный телефон клиента'
						AND trim(T.[ФИО сотрудника верификации/чекер]) <> ''
				)

		) AS A
		--WHERE A.[Решение по заявке] IN ('Отказано', 'Одобрено')
		--GROUP BY A.[Дата статуса]
		GROUP BY A.[Дата рассмотрения заявки]
	) AS B
END
--//Mobile



DROP TABLE IF EXISTS #t_Contact_Day

CREATE TABLE #t_Contact_Day(
	--[Дата статуса] date,
	[Дата рассмотрения заявки] date,
	[Контактность общая] nvarchar(50),
	[Контактность по одобренным] nvarchar(50),
	[Контактность по отказным] nvarchar(50)
)

IF @Page IN (
		'Contact.Daily',
		'Contact.Daily.Employee'
	)
	OR @isFill_All_Tables = 1 
--IF @page= 'V.Daily.Common' OR @isFill_All_Tables = 1 
BEGIN
	INSERT #t_Contact_Day
	(
		--[Дата статуса],
		[Дата рассмотрения заявки],
		[Контактность общая],
		[Контактность по одобренным],
		[Контактность по отказным]
	)
	SELECT 
		--B.[Дата статуса],
		B.[Дата рассмотрения заявки],
		[Контактность общая] =
			cast(
				format(
					CASE 
						WHEN B.КоличествоЗаявок <> 0
						THEN 100.0 * B.КоличествоДозвон / B.КоличествоЗаявок
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50)),
		[Контактность по одобренным] = 
			cast(
				format(
					CASE 
						WHEN B.КоличествоОдобрено <> 0
						THEN 100.0 * B.КоличествоОдобреноДозвон / B.КоличествоОдобрено
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50)),
		[Контактность по отказным] = 
			cast(
				format(
					CASE 
						WHEN B.КоличествоОтказано <> 0
						THEN 100.0 * B.КоличествоОтказаноДозвон / B.КоличествоОтказано
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50))
	FROM (
		SELECT 
			--A.[Дата статуса],
			A.[Дата рассмотрения заявки],
			КоличествоЗаявок = count(*),
			КоличествоДозвон = sum(A.Дозвон),

			КоличествоОдобрено = sum(iif(A.[Решение по заявке]='Одобрено',1,0)),
			КоличествоОдобреноДозвон = sum(iif(A.[Решение по заявке]='Одобрено',1,0) * A.Дозвон),

			КоличествоОтказано = sum(iif(A.[Решение по заявке]='Отказано',1,0)),
			КоличествоОтказаноДозвон = sum(iif(A.[Решение по заявке]='Отказано',1,0) * A.Дозвон)
		FROM (
			SELECT DISTINCT
				--[Дата статуса] = cast(R.[Дата статуса] as date),
				[Дата рассмотрения заявки] = cast(R.[Дата рассмотрения заявки] as date),
				R.[Номер заявки],
				[Решение по заявке] = 
					CASE 
						WHEN canceled.[Номер заявки] IS NOT NULL THEN 'Аннулировано'
						WHEN denied.[Номер заявки] IS NOT NULL THEN 'Отказано'
						WHEN approved.[Номер заявки] IS NOT NULL THEN 'Одобрено'
						WHEN customer_rejection.[Номер заявки] IS NOT NULL THEN 'Отказ клиента'
						ELSE ''
					END,
				--Одобрено = iif(approved.[Номер заявки] IS NOT NULL, 1, 0),
				--Отказано = iif(denied.[Номер заявки] IS NOT NULL, 1, 0),
				Дозвон = 
					iif(
						isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
						isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
						isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
						isnull(R.ЗвонокКонтактномуЛицу, 0) +
						isnull(R.ЗвонокНаМобильныйТелефонКлиента, 0) > 0,
						1, 0
					)
			FROM #t_request_number AS N
					INNER JOIN #t_dm_FedorVerificationRequests_Contact AS R
					ON R.[Номер заявки] = N.[Номер заявки]
				--одобрено
				LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
				--отказано
				LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
				--анулировано
				LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
				--Отказ клиента
				LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
			--WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
			WHERE 1=1
				--AND R.[Статус] in ('Верификация клиента') --теперь Отказные заявки не доходят до статуса 'Верификация Call 3'
				--DWH-2430 Убрать автоодобренные на ВК заявки из расчета контактности
				--комментарю после объединения КД и ВК
				--AND isnull(R.isSkipped, 0) = 0
		) AS A
		--WHERE A.[Решение по заявке] IN ('Отказано', 'Одобрено')
		--GROUP BY A.[Дата статуса]
		GROUP BY A.[Дата рассмотрения заявки]
	) AS B
END

IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##t_Contact_Day
	SELECT * INTO ##t_Contact_Day FROM #t_Contact_Day
END

--Контактность по всем группам продуктов
DROP TABLE IF EXISTS #t_Contact_Day_ALL

CREATE TABLE #t_Contact_Day_ALL(
	[Тип продукта] varchar(100),
	--[Дата статуса] date,
	[Дата рассмотрения заявки] date,
	[Контактность общая] nvarchar(50),
	[Контактность по одобренным] nvarchar(50),
	[Контактность по отказным] nvarchar(50)
)

IF @page= 'Contact.Daily.ALL' OR @isFill_All_Tables = 1 
BEGIN
	INSERT #t_Contact_Day_ALL
	(
		[Тип продукта],
		--[Дата статуса],
		[Дата рассмотрения заявки],
		[Контактность общая],
		[Контактность по одобренным],
		[Контактность по отказным]
	)
	SELECT 
		B.[Тип продукта],
		--B.[Дата статуса],
		B.[Дата рассмотрения заявки],
		[Контактность общая] =
			cast(
				format(
					CASE 
						WHEN B.КоличествоЗаявок <> 0
						THEN 100.0 * B.КоличествоДозвон / B.КоличествоЗаявок
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50)),
		[Контактность по одобренным] = 
			cast(
				format(
					CASE 
						WHEN B.КоличествоОдобрено <> 0
						THEN 100.0 * B.КоличествоОдобреноДозвон / B.КоличествоОдобрено
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50)),
		[Контактность по отказным] = 
			cast(
				format(
					CASE 
						WHEN B.КоличествоОтказано <> 0
						THEN 100.0 * B.КоличествоОтказаноДозвон / B.КоличествоОтказано
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50))
	FROM (
		SELECT 
			A.[Тип продукта],
			--A.[Дата статуса],
			A.[Дата рассмотрения заявки],
			КоличествоЗаявок = count(*),
			КоличествоДозвон = sum(A.Дозвон),

			КоличествоОдобрено = sum(iif(A.[Решение по заявке]='Одобрено',1,0)),
			КоличествоОдобреноДозвон = sum(iif(A.[Решение по заявке]='Одобрено',1,0) * A.Дозвон),

			КоличествоОтказано = sum(iif(A.[Решение по заявке]='Отказано',1,0)),
			КоличествоОтказаноДозвон = sum(iif(A.[Решение по заявке]='Отказано',1,0) * A.Дозвон)
		FROM (
			SELECT DISTINCT
				R.[Тип продукта],
				--[Дата статуса] = cast(R.[Дата статуса] as date),
				[Дата рассмотрения заявки] = cast(R.[Дата рассмотрения заявки] as date),
				R.[Номер заявки],
				[Решение по заявке] = 
					CASE 
						WHEN canceled.[Номер заявки] IS NOT NULL THEN 'Аннулировано'
						WHEN denied.[Номер заявки] IS NOT NULL THEN 'Отказано'
						WHEN approved.[Номер заявки] IS NOT NULL THEN 'Одобрено'
						WHEN customer_rejection.[Номер заявки] IS NOT NULL THEN 'Отказ клиента'
						ELSE ''
					END,
				--Одобрено = iif(approved.[Номер заявки] IS NOT NULL, 1, 0),
				--Отказано = iif(denied.[Номер заявки] IS NOT NULL, 1, 0),
				Дозвон = 
					iif(
						isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
						isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
						isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
						isnull(R.ЗвонокКонтактномуЛицу, 0) +
						isnull(R.ЗвонокНаМобильныйТелефонКлиента, 0) > 0,
						1, 0
					)
			FROM #t_request_number AS N
					INNER JOIN #t_dm_FedorVerificationRequests_Contact AS R
					ON R.[Номер заявки] = N.[Номер заявки]
				--одобрено
				LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
				--отказано
				LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
				--анулировано
				LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
				--Отказ клиента
				LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
			--WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
			WHERE 1=1
				--AND R.[Статус] in ('Верификация клиента') --теперь Отказные заявки не доходят до статуса 'Верификация Call 3'
				--DWH-2430 Убрать автоодобренные на ВК заявки из расчета контактности
				--комментарю после объединения КД и ВК
				--AND isnull(R.isSkipped, 0) = 0
				--AND R.[Тип продукта] = 'installment'
		) AS A
		--WHERE A.[Решение по заявке] IN ('Отказано', 'Одобрено')
		--GROUP BY A.[Дата статуса]
		GROUP BY A.[Тип продукта], A.[Дата рассмотрения заявки]
	) AS B
END



DROP TABLE IF EXISTS #t_Contact_Day_Mobile
CREATE TABLE #t_Contact_Day_Mobile(
	--[Дата статуса] date,
	[Дата рассмотрения заявки] date,
	[Контактность общая] nvarchar(50),
	[Контактность по одобренным] nvarchar(50),
	[Контактность по отказным] nvarchar(50)
)

IF @Page IN (
		'Contact.Daily.Mobile',
		'Contact.Daily.EmployeeMobile',
		'Contact.Daily.EmployeeMobile.Approved'
	)
	OR @isFill_All_Tables = 1 
BEGIN
	INSERT #t_Contact_Day_Mobile
	(
		--[Дата статуса],
		[Дата рассмотрения заявки],
		[Контактность общая],
		[Контактность по одобренным],
		[Контактность по отказным]
	)
	SELECT 
		--B.[Дата статуса],
		B.[Дата рассмотрения заявки],
		[Контактность общая] =
			cast(
				format(
					CASE 
						WHEN B.КоличествоЗаявок <> 0
						THEN 100.0 * B.КоличествоДозвон / B.КоличествоЗаявок
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50)),
		[Контактность по одобренным] = 
			cast(
				format(
					CASE 
						WHEN B.КоличествоОдобрено <> 0
						THEN 100.0 * B.КоличествоОдобреноДозвон / B.КоличествоОдобрено
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50)),
		[Контактность по отказным] = 
			cast(
				format(
					CASE 
						WHEN B.КоличествоОтказано <> 0
						THEN 100.0 * B.КоличествоОтказаноДозвон / B.КоличествоОтказано
						ELSE 0
					END,
					'0.0'
				)+N'%' as nvarchar(50))
	FROM (
		SELECT 
			--A.[Дата статуса],
			A.[Дата рассмотрения заявки],
			КоличествоЗаявок = count(*),
			КоличествоДозвон = sum(A.Дозвон),

			КоличествоОдобрено = sum(iif(A.[Решение по заявке]='Одобрено',1,0)),
			КоличествоОдобреноДозвон = sum(iif(A.[Решение по заявке]='Одобрено',1,0) * A.Дозвон),

			КоличествоОтказано = sum(iif(A.[Решение по заявке]='Отказано',1,0)),
			КоличествоОтказаноДозвон = sum(iif(A.[Решение по заявке]='Отказано',1,0) * A.Дозвон)
		FROM (
			SELECT DISTINCT
				--[Дата статуса] = cast(R.[Дата статуса] as date),
				[Дата рассмотрения заявки] = cast(R.[Дата рассмотрения заявки] as date),
				R.[Номер заявки],
				[Решение по заявке] = 
					CASE 
						WHEN canceled.[Номер заявки] IS NOT NULL THEN 'Аннулировано'
						WHEN denied.[Номер заявки] IS NOT NULL THEN 'Отказано'
						WHEN approved.[Номер заявки] IS NOT NULL THEN 'Одобрено'
						WHEN customer_rejection.[Номер заявки] IS NOT NULL THEN 'Отказ клиента'
						ELSE ''
					END,
				--Mobile
				--БЕЗЗАЛОГ Информация по проверке  "Звонок На Мобильный Телефон Клиента" 
				Дозвон = 
					iif(
						--isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
						--isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
						--isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
						--isnull(R.ЗвонокКонтактномуЛицу, 0) +
						isnull(R.ЗвонокНаМобильныйТелефонКлиента, 0) > 0,
						1, 0
					)
			FROM #t_request_number AS N
					INNER JOIN #t_dm_FedorVerificationRequests_Contact AS R
					ON R.[Номер заявки] = N.[Номер заявки]
				--одобрено
				LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
				--отказано
				LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
				--анулировано
				LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
				--Отказ клиента
				LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
			--WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
			WHERE 1=1
				--AND R.[Статус] in ('Верификация клиента') --теперь Отказные заявки не доходят до статуса 'Верификация Call 3'
				--DWH-2430 Убрать автоодобренные на ВК заявки из расчета контактности
				--комментарю после объединения КД и ВК
				--AND isnull(R.isSkipped, 0) = 0
				--evseenkova: исключить заявки, у которых "Звонок на мобильный телефон клиента" не проводился
				--AND NOT EXISTS (
				--	SELECT TOP(1) 1 
				--	FROM #t_Report_verification_Contact_Contact_DetailByEmployee AS Contact
				--	WHERE Contact.[Номер заявки] = R.[Номер заявки]
				--		AND Contact.ТипЗвонка = 'Звонок на мобильный телефон клиента'
				--		AND Contact.РезультатЗвонка = 'Проверка не проводилась (системная)'
				--		--trim(Contact.[ФИО сотрудника верификации/чекер]) <> ''
				--)

				--DWH-2683
				AND EXISTS (
					SELECT TOP(1) 1 
					FROM #t_Report_verification_Contact_Contact_DetailByEmployee AS T
					WHERE T.[Номер заявки] = R.[Номер заявки]
						AND T.ТипЗвонка = 'Звонок на мобильный телефон клиента'
						AND trim(T.[ФИО сотрудника верификации/чекер]) <> ''
				)
		) AS A
		--WHERE A.[Решение по заявке] IN ('Отказано', 'Одобрено')
		--GROUP BY A.[Дата статуса]
		GROUP BY A.[Дата рассмотрения заявки]
	) AS B
END


DROP TABLE IF EXISTS #t_Contact_Employee_Month

CREATE TABLE #t_Contact_Employee_Month(
	[Дата] date,
	[Сотрудник] nvarchar(255),
	[УникальныхЗаявок] int,
	[Контактность] int
)

IF @Page = 'Contact.Monthly.Employee' OR @isFill_All_Tables = 1
--IF @Page = 'VK.Monthly.Contact' OR @isFill_All_Tables = 1
BEGIN
	IF @isFill_All_Tables = 1
	BEGIN
		INSERT #t_Contact_Employee_Month(
			[Дата],
			[Сотрудник],
			[УникальныхЗаявок],
			[Контактность]
		)
		SELECT 
			--[Дата] = A.[Дата статуса],
			[Дата] = A.[Дата рассмотрения заявки],
			[Сотрудник] = A.[ФИО сотрудника верификации/чекер],
			[УникальныхЗаявок] = count(*),
			[Контактность] = sum(A.Дозвон)
		FROM (
			SELECT 
				--[Дата статуса] = cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
				[Дата рассмотрения заявки] = cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки],
				Дозвон = CASE 
							WHEN sum(T.Дозвон) >= 1 then 1
							ELSE 0
						END
			FROM tmp.TMP_Report_verification_Contact_Contact_DetailByEmployee AS T
			WHERE T.ProcessGUID = @ProcessGUID
				--не учитывать заявки, без сотрудника, т.е.
				--"Звонок на мобильный телефон клиента" с результатом звонка "Проверка не проводилась (системная)"
				AND trim(T.[ФИО сотрудника верификации/чекер]) <> ''
			GROUP BY
				--cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
				cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		--GROUP BY A.[Дата статуса], A.[ФИО сотрудника верификации/чекер]
		GROUP BY A.[Дата рассмотрения заявки], A.[ФИО сотрудника верификации/чекер]
	END
	ELSE BEGIN
		INSERT #t_Contact_Employee_Month(
			[Дата],
			[Сотрудник],
			[УникальныхЗаявок],
			[Контактность]
		)
		SELECT 
			--[Дата] = A.[Дата статуса],
			[Дата] = A.[Дата рассмотрения заявки],
			[Сотрудник] = A.[ФИО сотрудника верификации/чекер],
			[УникальныхЗаявок] = count(*),
			[Контактность] = sum(A.Дозвон)
		FROM (
			SELECT 
				--[Дата статуса] = cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
				[Дата рассмотрения заявки] = cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки],
				Дозвон = CASE 
							WHEN sum(T.Дозвон) >= 1 then 1
							ELSE 0
						END
			FROM 
			(

				SELECT DISTINCT
					--ProcessGUID = Request.ProcessGUID,
					Request.[Дата рассмотрения заявки],
					Request.[Дата заведения заявки],
					Request.[Время заведения],
					Request.[Номер заявки],
					Request.[ФИО клиента],
					[ФИО сотрудника верификации/чекер] = concat(Users.LastName, ' ', Users.FirstName, ' ', Users.MiddleName),
					Request.[Решение по заявке],
					ПорядковыйНомерЗвонка = call_type.SortOrder,
					ТипЗвонка = CheckListItemType.Name,
					РезультатЗвонка = CheckListItemStatus.Name,
					Дозвон = Contact_Call.isSuccess,
					Request.ИтогоКонтактность
				FROM 
					(
						SELECT DISTINCT
							C.ProcessGUID,
							C.[Дата рассмотрения заявки],
							C.[Дата заведения заявки],
							C.[Время заведения],
							C.[Номер заявки],
							C.[ФИО клиента],
							--C.Статус,
							--C.Задача,
							--C.[Состояние заявки],
							--C.[Дата статуса],
							--C.[ФИО сотрудника верификации/чекер],
							--C.Назначен,
							--C.ВремяЗатрачено,
							--C.[Время, час:мин:сек],
							--C.[Статус следующий],
							--C.[Задача следующая],
							--C.[Состояние заявки следующая],
							C.[Решение по заявке],
							C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
							C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
							C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
							C.ЗвонокКонтактномуЛицу,
							C.ЗвонокНаМобильныйТелефонКлиента,
							C.ИтогоКонтактность	
						FROM (
							SELECT
								ProcessGUID = @ProcessGUID
								 , R.[Дата рассмотрения заявки]
								 , R.[Дата заведения заявки]
								 , R.[Время заведения]
								 , R.[Номер заявки]
								 , R.[ФИО клиента]
								 , R.[Статус]
								 , R.[Задача]
								 , R.[Состояние заявки]
								 , R.[Дата статуса]
								  -- 20210326
								 , [ФИО сотрудника верификации/чекер] = R.Работник
								 , R.Назначен
								 , R.[ВремяЗатрачено]
							   , R.[Время, час:мин:сек]
								 , R.[Статус следующий]
								 , R.[Задача следующая]
								 , R.[Состояние заявки следующая]
								 --DWH-1720
								--, [Решение по заявке] = trim(
								--	concat(
								--		iif(approved.[Номер заявки] IS NOT NULL,'Одобрено',''),' ',
								--		iif(denied.[Номер заявки] IS NOT NULL,'Отказано',''),' ',
								--		iif(canceled.[Номер заявки] IS NOT NULL,'Аннулировано',''), ' ',
								--		iif(customer_rejection.[Номер заявки] IS NOT NULL,'Отказ клиента','')
								--		)
								--)
								, [Решение по заявке] = 
								CASE 
									WHEN canceled.[Номер заявки] IS NOT NULL THEN 'Аннулировано'
									WHEN denied.[Номер заявки] IS NOT NULL THEN 'Отказано'
									WHEN approved.[Номер заявки] IS NOT NULL THEN 'Одобрено'
									WHEN customer_rejection.[Номер заявки] IS NOT NULL THEN 'Отказ клиента'
									ELSE ''
								END
								, R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус
								, R.ЗвонокРаботодателюПоТелефонамИзИнтернет
								, R.ЗвонокРаботодателюПоТелефонуИзАнкеты
								, R.ЗвонокКонтактномуЛицу
								, R.ЗвонокНаМобильныйТелефонКлиента
								, ИтогоКонтактность = 
									isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
									isnull(R.ЗвонокКонтактномуЛицу, 0) +
									isnull(R.ЗвонокНаМобильныйТелефонКлиента, 0)
							--INTO tmp.TMP_Report_verification_Contact_Contact_Detail
							FROM #t_request_number AS N
								INNER JOIN #t_dm_FedorVerificationRequests_Contact AS R
									ON R.[Номер заявки] = N.[Номер заявки]
								--одобрено
								LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
								--отказано
								LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
								--анулировано
								LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
								--Отказ клиента
								LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
							--WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
							WHERE 1=1
								--AND R.[Статус] in ('Верификация клиента') --теперь Отказные заявки не доходят до статуса 'Верификация Call 3'
								--DWH-2430 Убрать автоодобренные на ВК заявки из расчета контактности
								--комментарю после объединения КД и ВК
								--AND isnull(R.isSkipped, 0) = 0
							--order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc
						) AS C
						--WHERE C.[Решение по заявке] IN ('Отказано', 'Одобрено')
					) AS Request
					INNER JOIN Stg._fedor.core_ClientRequest AS ClientRequest
						ON ClientRequest.Number COLLATE Cyrillic_General_CI_AS = Request.[Номер заявки]
					INNER JOIN Stg._fedor.core_CheckListItem AS CheckListItem
						ON ClientRequest.Id = CheckListItem.IdClientRequest
					INNER JOIN Stg._fedor.dictionary_CheckListItemType AS CheckListItemType
						ON CheckListItemType.Id = CheckListItem.IdType

					-- типы звонков
					INNER JOIN (
						SELECT DISTINCT 
							CC.SortOrder,
							call_type_name = CC.call_type_name
						FROM #t_Contact_Call AS CC
						) AS call_type
						ON call_type.call_type_name = CheckListItemType.Name COLLATE Cyrillic_General_CI_AS

					LEFT JOIN Stg._fedor.core_CheckListItemTypeAndCheckListItemStatus AS CH_IT_IS
						ON CH_IT_IS.IdType = CheckListItem.IdType
						AND CH_IT_IS.IdCheckListItemStatus = CheckListItem.IdStatus
					LEFT JOIN Stg._fedor.dictionary_CheckListItemStatus AS CheckListItemStatus
						ON CheckListItemStatus.Id = CheckListItem.IdStatus
					LEFT JOIN Stg._fedor.core_Comment AS Comment
						ON Comment.[IdEntity] = CheckListItem.Id
					LEFT JOIN Stg._fedor.core_user AS Users
						ON Users.Id = Comment.IdOwner

					LEFT JOIN #t_Contact_Call AS Contact_Call
						ON Contact_Call.call_type_name = CheckListItemType.Name COLLATE Cyrillic_General_CI_AS
						AND Contact_Call.result_name = CheckListItemStatus.Name COLLATE Cyrillic_General_CI_AS


			) AS T
			WHERE 1=1
				--не учитывать заявки, без сотрудника, т.е.
				--"Звонок на мобильный телефон клиента" с результатом звонка "Проверка не проводилась (системная)"
				AND trim(T.[ФИО сотрудника верификации/чекер]) <> ''
			GROUP BY
				--cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
				cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		--GROUP BY A.[Дата статуса], A.[ФИО сотрудника верификации/чекер]
		GROUP BY A.[Дата рассмотрения заявки], A.[ФИО сотрудника верификации/чекер]
		
	END
END



DROP TABLE IF EXISTS #t_Contact_Employee_Month_Mobile_Detail
CREATE TABLE #t_Contact_Employee_Month_Mobile_Detail(
	[Дата рассмотрения заявки] date,
	[ФИО сотрудника верификации/чекер] nvarchar(255),
	[Номер заявки] nvarchar(25),
	Дозвон int
)

DROP TABLE IF EXISTS #t_Contact_Employee_Month_Mobile
CREATE TABLE #t_Contact_Employee_Month_Mobile(
	[Дата] date,
	[Сотрудник] nvarchar(255),
	[УникальныхЗаявок] int,
	[Контактность] int
)

IF @Page = 'Contact.Monthly.EmployeeMobile' OR @isFill_All_Tables = 1
BEGIN
	INSERT #t_Contact_Employee_Month_Mobile_Detail
	(
	    [Дата рассмотрения заявки],
	    [ФИО сотрудника верификации/чекер],
	    [Номер заявки],
	    Дозвон
	)
	SELECT 
		--[Дата статуса] = cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
		[Дата рассмотрения заявки] = cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
		T.[ФИО сотрудника верификации/чекер],
		T.[Номер заявки],
		Дозвон = CASE 
					--WHEN sum(T.Дозвон) >= 1 then 1
					--БЕЗЗАЛОГ Контактность "Звонок На Мобильный Телефон Клиента", % (мес)
					WHEN sum(iif(T.ТипЗвонка = 'Звонок на мобильный телефон клиента', T.Дозвон, 0)) >= 1 then 1
					ELSE 0
				END
	FROM #t_Report_verification_Contact_Contact_DetailByEmployee AS T
	WHERE 1=1 --T.ProcessGUID = @ProcessGUID
		AND T.ТипЗвонка = 'Звонок на мобильный телефон клиента'
		--не учитывать заявки, без сотрудника, т.е.
		--"Звонок на мобильный телефон клиента" с результатом звонка "Проверка не проводилась (системная)"
		AND trim(T.[ФИО сотрудника верификации/чекер]) <> ''
	GROUP BY
		--cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
		cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
		T.[ФИО сотрудника верификации/чекер],
		T.[Номер заявки]


	INSERT #t_Contact_Employee_Month_Mobile(
		[Дата],
		[Сотрудник],
		[УникальныхЗаявок],
		[Контактность]
	)
	SELECT 
		--[Дата] = A.[Дата статуса],
		[Дата] = A.[Дата рассмотрения заявки],
		[Сотрудник] = A.[ФИО сотрудника верификации/чекер],
		[УникальныхЗаявок] = count(DISTINCT A.[Номер заявки]),
		[Контактность] = sum(A.Дозвон)
	FROM #t_Contact_Employee_Month_Mobile_Detail AS A
	WHERE 1=1
	--GROUP BY A.[Дата статуса], A.[ФИО сотрудника верификации/чекер]
	GROUP BY A.[Дата рассмотрения заявки], A.[ФИО сотрудника верификации/чекер]
END
--//'Contact.Monthly.EmployeeMobile'



--"БЕЗЗАЛОГ Контактность "Звонок На Мобильный Телефон Клиента", % (мес) по одобренным"

DROP TABLE IF EXISTS #t_Contact_Employee_Month_Mobile_Approved_Detail
CREATE TABLE #t_Contact_Employee_Month_Mobile_Approved_Detail
(
	[Дата рассмотрения заявки] date,
	[ФИО сотрудника верификации/чекер] nvarchar(255),
	[Номер заявки] nvarchar(25),
	Дозвон int
)

DROP TABLE IF EXISTS #t_Contact_Employee_Month_Mobile_Approved
CREATE TABLE #t_Contact_Employee_Month_Mobile_Approved(
	[Дата] date,
	[Сотрудник] nvarchar(255),
	[УникальныхЗаявок] int,
	[Контактность] int
)

IF @Page = 'Contact.Monthly.EmployeeMobile.Approved' OR @isFill_All_Tables = 1
BEGIN
	INSERT #t_Contact_Employee_Month_Mobile_Approved_Detail
	(
	    [Дата рассмотрения заявки],
	    [ФИО сотрудника верификации/чекер],
	    [Номер заявки],
	    Дозвон
	)
	SELECT 
		--[Дата статуса] = cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
		[Дата рассмотрения заявки] = cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
		T.[ФИО сотрудника верификации/чекер],
		T.[Номер заявки],
		Дозвон = CASE 
					--WHEN sum(T.Дозвон) >= 1 then 1
					--БЕЗЗАЛОГ Контактность "Звонок На Мобильный Телефон Клиента", % (мес)
					WHEN sum(iif(T.ТипЗвонка = 'Звонок на мобильный телефон клиента', T.Дозвон, 0)) >= 1 then 1
					ELSE 0
				END
	FROM #t_Report_verification_Contact_Contact_DetailByEmployee AS T
		--одобрено
		INNER JOIN #t_approved AS approved ON approved.[Номер заявки] = T.[Номер заявки]
	WHERE T.ProcessGUID = @ProcessGUID
		AND T.ТипЗвонка = 'Звонок на мобильный телефон клиента'
		--не учитывать заявки, без сотрудника, т.е.
		--"Звонок на мобильный телефон клиента" с результатом звонка "Проверка не проводилась (системная)"
		AND trim(T.[ФИО сотрудника верификации/чекер]) <> ''
	GROUP BY
		--cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
		cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
		T.[ФИО сотрудника верификации/чекер],
		T.[Номер заявки]


	INSERT #t_Contact_Employee_Month_Mobile_Approved(
		[Дата],
		[Сотрудник],
		[УникальныхЗаявок],
		[Контактность]
	)
	SELECT 
		--[Дата] = A.[Дата статуса],
		[Дата] = A.[Дата рассмотрения заявки],
		[Сотрудник] = A.[ФИО сотрудника верификации/чекер],
		[УникальныхЗаявок] = count(DISTINCT A.[Номер заявки]),
		[Контактность] = sum(A.Дозвон)
	FROM #t_Contact_Employee_Month_Mobile_Approved_Detail AS A
	WHERE 1=1
	--GROUP BY A.[Дата статуса], A.[ФИО сотрудника верификации/чекер]
	GROUP BY A.[Дата рассмотрения заявки], A.[ФИО сотрудника верификации/чекер]
END
--//'Contact.Monthly.EmployeeMobile.Approved'





--"БЕЗЗАЛОГ Контактность "Звонок На Мобильный Телефон Клиента", % (мес) по отказным"

DROP TABLE IF EXISTS #t_Contact_Employee_Month_Mobile_Denied_Detail
CREATE TABLE #t_Contact_Employee_Month_Mobile_Denied_Detail
(
	[Дата рассмотрения заявки] date,
	[ФИО сотрудника верификации/чекер] nvarchar(255),
	[Номер заявки] nvarchar(25),
	Дозвон int
)

DROP TABLE IF EXISTS #t_Contact_Employee_Month_Mobile_Denied
CREATE TABLE #t_Contact_Employee_Month_Mobile_Denied(
	[Дата] date,
	[Сотрудник] nvarchar(255),
	[УникальныхЗаявок] int,
	[Контактность] int
)

IF @Page = 'Contact.Monthly.EmployeeMobile.Denied' OR @isFill_All_Tables = 1
BEGIN
	INSERT #t_Contact_Employee_Month_Mobile_Denied_Detail
	(
	    [Дата рассмотрения заявки],
	    [ФИО сотрудника верификации/чекер],
	    [Номер заявки],
	    Дозвон
	)
	SELECT 
		--[Дата статуса] = cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
		[Дата рассмотрения заявки] = cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
		T.[ФИО сотрудника верификации/чекер],
		T.[Номер заявки],
		Дозвон = CASE 
					--WHEN sum(T.Дозвон) >= 1 then 1
					--БЕЗЗАЛОГ Контактность "Звонок На Мобильный Телефон Клиента", % (мес)
					WHEN sum(iif(T.ТипЗвонка = 'Звонок на мобильный телефон клиента', T.Дозвон, 0)) >= 1 then 1
					ELSE 0
				END
	FROM tmp.TMP_Report_verification_Contact_Contact_DetailByEmployee AS T
		--отказано
		INNER JOIN #t_denied AS denied ON denied.[Номер заявки] = T.[Номер заявки]
	WHERE T.ProcessGUID = @ProcessGUID
		AND T.ТипЗвонка = 'Звонок на мобильный телефон клиента'
		--не учитывать заявки, без сотрудника, т.е.
		--"Звонок на мобильный телефон клиента" с результатом звонка "Проверка не проводилась (системная)"
		AND trim(T.[ФИО сотрудника верификации/чекер]) <> ''
	GROUP BY
		--cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
		cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
		T.[ФИО сотрудника верификации/чекер],
		T.[Номер заявки]


	INSERT #t_Contact_Employee_Month_Mobile_Denied(
		[Дата],
		[Сотрудник],
		[УникальныхЗаявок],
		[Контактность]
	)
	SELECT 
		--[Дата] = A.[Дата статуса],
		[Дата] = A.[Дата рассмотрения заявки],
		[Сотрудник] = A.[ФИО сотрудника верификации/чекер],
		[УникальныхЗаявок] = count(DISTINCT A.[Номер заявки]),
		[Контактность] = sum(A.Дозвон)
	FROM #t_Contact_Employee_Month_Mobile_Denied_Detail AS A
	WHERE 1=1
	--GROUP BY A.[Дата статуса], A.[ФИО сотрудника верификации/чекер]
	GROUP BY A.[Дата рассмотрения заявки], A.[ФИО сотрудника верификации/чекер]
END
--//'Contact.Monthly.EmployeeMobile.Denied'






DROP TABLE IF EXISTS #t_Contact_Employee_Day
CREATE TABLE #t_Contact_Employee_Day(
	[Дата] date,
	[Сотрудник] nvarchar(255),
	[УникальныхЗаявок] int,
	[Контактность] int
)

IF @Page = 'Contact.Daily.Employee' OR @isFill_All_Tables = 1
--IF @Page = 'VK.Daily.Contact' OR @isFill_All_Tables = 1
BEGIN
	IF @isFill_All_Tables = 1
	BEGIN
		INSERT #t_Contact_Employee_Day(
			[Дата],
			[Сотрудник],
			[УникальныхЗаявок],
			[Контактность]
		)
		SELECT 
			--[Дата] = A.[Дата статуса],
			[Дата] = A.[Дата рассмотрения заявки],
			[Сотрудник] = A.[ФИО сотрудника верификации/чекер],
			[УникальныхЗаявок] = count(*),
			[Контактность] = sum(A.Дозвон)
		FROM (
			SELECT 
				--[Дата статуса] = cast(format(T.[Дата заведения заявки], 'yyyyMMdd') as date),
				[Дата рассмотрения заявки] = cast(format(T.[Дата рассмотрения заявки], 'yyyyMMdd') as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки],
				Дозвон = CASE 
							WHEN sum(T.Дозвон) >= 1 then 1
							ELSE 0
						END
			FROM tmp.TMP_Report_verification_Contact_Contact_DetailByEmployee AS T
			WHERE T.ProcessGUID = @ProcessGUID
				--не учитывать заявки, без сотрудника, т.е.
				--"Звонок на мобильный телефон клиента" с результатом звонка "Проверка не проводилась (системная)"
				AND trim(T.[ФИО сотрудника верификации/чекер]) <> ''
			GROUP BY
				--cast(format(T.[Дата заведения заявки], 'yyyyMMdd') as date),
				cast(format(T.[Дата рассмотрения заявки], 'yyyyMMdd') as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		--GROUP BY A.[Дата статуса], A.[ФИО сотрудника верификации/чекер]
		GROUP BY A.[Дата рассмотрения заявки], A.[ФИО сотрудника верификации/чекер]
	END
	ELSE BEGIN
		INSERT #t_Contact_Employee_Day(
			[Дата],
			[Сотрудник],
			[УникальныхЗаявок],
			[Контактность]
		)
		SELECT 
			--[Дата] = A.[Дата статуса],
			[Дата] = A.[Дата рассмотрения заявки],
			[Сотрудник] = A.[ФИО сотрудника верификации/чекер],
			[УникальныхЗаявок] = count(*),
			[Контактность] = sum(A.Дозвон)
		FROM (
			SELECT 
				--[Дата статуса] = cast(T.[Дата заведения заявки] as date),
				[Дата рассмотрения заявки] = cast(T.[Дата рассмотрения заявки] AS date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки],
				Дозвон = CASE 
							WHEN sum(T.Дозвон) >= 1 then 1
							ELSE 0
						END
			FROM 
			(

				SELECT DISTINCT
					--ProcessGUID = Request.ProcessGUID,
					Request.[Дата рассмотрения заявки],
					Request.[Дата заведения заявки],
					Request.[Время заведения],
					Request.[Номер заявки],
					Request.[ФИО клиента],
					[ФИО сотрудника верификации/чекер] = concat(Users.LastName, ' ', Users.FirstName, ' ', Users.MiddleName),
					Request.[Решение по заявке],
					ПорядковыйНомерЗвонка = call_type.SortOrder,
					ТипЗвонка = CheckListItemType.Name,
					РезультатЗвонка = CheckListItemStatus.Name,
					Дозвон = Contact_Call.isSuccess,
					Request.ИтогоКонтактность
				FROM 
					(
						SELECT DISTINCT
							C.ProcessGUID,
							C.[Дата рассмотрения заявки],
							C.[Дата заведения заявки],
							C.[Время заведения],
							C.[Номер заявки],
							C.[ФИО клиента],
							--C.Статус,
							--C.Задача,
							--C.[Состояние заявки],
							--C.[Дата статуса],
							--C.[ФИО сотрудника верификации/чекер],
							--C.Назначен,
							--C.ВремяЗатрачено,
							--C.[Время, час:мин:сек],
							--C.[Статус следующий],
							--C.[Задача следующая],
							--C.[Состояние заявки следующая],
							C.[Решение по заявке],
							C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
							C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
							C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
							C.ЗвонокКонтактномуЛицу,
							C.ЗвонокНаМобильныйТелефонКлиента,
							C.ИтогоКонтактность	
						FROM (
							SELECT
								ProcessGUID = @ProcessGUID
								, R.[Дата рассмотрения заявки]
								, R.[Дата заведения заявки]
								 , R.[Время заведения]
								 , R.[Номер заявки]
								 , R.[ФИО клиента]
								 , R.[Статус]
								 , R.[Задача]
								 , R.[Состояние заявки]
								 , R.[Дата статуса]
								  -- 20210326
								 , [ФИО сотрудника верификации/чекер] = R.Работник
								 , R.Назначен
								 , R.[ВремяЗатрачено]
							   , R.[Время, час:мин:сек]
								 , R.[Статус следующий]
								 , R.[Задача следующая]
								 , R.[Состояние заявки следующая]
								 --DWH-1720
								--, [Решение по заявке] = trim(
								--	concat(
								--		iif(approved.[Номер заявки] IS NOT NULL,'Одобрено',''),' ',
								--		iif(denied.[Номер заявки] IS NOT NULL,'Отказано',''),' ',
								--		iif(canceled.[Номер заявки] IS NOT NULL,'Аннулировано',''), ' ',
								--		iif(customer_rejection.[Номер заявки] IS NOT NULL,'Отказ клиента','')
								--		)
								--)
								, [Решение по заявке] = 
								CASE 
									WHEN canceled.[Номер заявки] IS NOT NULL THEN 'Аннулировано'
									WHEN denied.[Номер заявки] IS NOT NULL THEN 'Отказано'
									WHEN approved.[Номер заявки] IS NOT NULL THEN 'Одобрено'
									WHEN customer_rejection.[Номер заявки] IS NOT NULL THEN 'Отказ клиента'
									ELSE ''
								END
								, R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус
								, R.ЗвонокРаботодателюПоТелефонамИзИнтернет
								, R.ЗвонокРаботодателюПоТелефонуИзАнкеты
								, R.ЗвонокКонтактномуЛицу
								, R.ЗвонокНаМобильныйТелефонКлиента
								, ИтогоКонтактность = 
									isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
									isnull(R.ЗвонокКонтактномуЛицу, 0) +
									isnull(R.ЗвонокНаМобильныйТелефонКлиента, 0)
							--INTO tmp.TMP_Report_verification_Contact_Contact_Detail
							FROM #t_request_number AS N
								INNER JOIN #t_dm_FedorVerificationRequests_Contact AS R
									ON R.[Номер заявки] = N.[Номер заявки]
								--одобрено
								LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
								--отказано
								LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
								--анулировано
								LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
								--Отказ клиента
								LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
							--WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
							WHERE 1=1
								--AND R.[Статус] in ('Верификация клиента') --теперь Отказные заявки не доходят до статуса 'Верификация Call 3'
								--DWH-2430 Убрать автоодобренные на ВК заявки из расчета контактности
								--комментарю после объединения КД и ВК
								--AND isnull(R.isSkipped, 0) = 0
							--order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc
						) AS C
						--WHERE C.[Решение по заявке] IN ('Отказано', 'Одобрено')
					) AS Request
					INNER JOIN Stg._fedor.core_ClientRequest AS ClientRequest
						ON ClientRequest.Number COLLATE Cyrillic_General_CI_AS = Request.[Номер заявки]
					INNER JOIN Stg._fedor.core_CheckListItem AS CheckListItem
						ON ClientRequest.Id = CheckListItem.IdClientRequest
					INNER JOIN Stg._fedor.dictionary_CheckListItemType AS CheckListItemType
						ON CheckListItemType.Id = CheckListItem.IdType

					-- типы звонков
					INNER JOIN (
						SELECT DISTINCT 
							CC.SortOrder,
							call_type_name = CC.call_type_name
						FROM #t_Contact_Call AS CC
						) AS call_type
						ON call_type.call_type_name = CheckListItemType.Name COLLATE Cyrillic_General_CI_AS

					LEFT JOIN Stg._fedor.core_CheckListItemTypeAndCheckListItemStatus AS CH_IT_IS
						ON CH_IT_IS.IdType = CheckListItem.IdType
						AND CH_IT_IS.IdCheckListItemStatus = CheckListItem.IdStatus
					LEFT JOIN Stg._fedor.dictionary_CheckListItemStatus AS CheckListItemStatus
						ON CheckListItemStatus.Id = CheckListItem.IdStatus
					LEFT JOIN Stg._fedor.core_Comment AS Comment
						ON Comment.[IdEntity] = CheckListItem.Id
					LEFT JOIN Stg._fedor.core_user AS Users
						ON Users.Id = Comment.IdOwner

					LEFT JOIN #t_Contact_Call AS Contact_Call
						ON Contact_Call.call_type_name = CheckListItemType.Name COLLATE Cyrillic_General_CI_AS
						AND Contact_Call.result_name = CheckListItemStatus.Name COLLATE Cyrillic_General_CI_AS
			) AS T
			WHERE 1=1
				--не учитывать заявки, без сотрудника, т.е.
				--"Звонок на мобильный телефон клиента" с результатом звонка "Проверка не проводилась (системная)"
				AND trim(T.[ФИО сотрудника верификации/чекер]) <> ''
			GROUP BY
				--cast(T.[Дата заведения заявки] as date),
				cast(T.[Дата рассмотрения заявки] as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		--GROUP BY A.[Дата статуса], A.[ФИО сотрудника верификации/чекер]
		GROUP BY A.[Дата рассмотрения заявки], A.[ФИО сотрудника верификации/чекер]
	END
END
--// DWH-2067

IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##t_Contact_Employee_Day
	SELECT * INTO ##t_Contact_Employee_Day FROM #t_Contact_Employee_Day
END


DROP TABLE IF EXISTS #t_Contact_Employee_Day_Mobile_Detail
CREATE TABLE #t_Contact_Employee_Day_Mobile_Detail
(
	[Дата рассмотрения заявки] date,
	[ФИО сотрудника верификации/чекер] nvarchar(255),
	[Номер заявки] nvarchar(25),
	Дозвон int
)

DROP TABLE IF EXISTS #t_Contact_Employee_Day_Mobile
CREATE TABLE #t_Contact_Employee_Day_Mobile(
	[Дата] date,
	[Сотрудник] nvarchar(255),
	[УникальныхЗаявок] int,
	[Контактность] int
)

IF @Page = 'Contact.Daily.EmployeeMobile' OR @isFill_All_Tables = 1
BEGIN
	INSERT #t_Contact_Employee_Day_Mobile_Detail
	(
	    [Дата рассмотрения заявки],
	    [ФИО сотрудника верификации/чекер],
	    [Номер заявки],
	    Дозвон
	)
	SELECT 
		--[Дата статуса] = cast(format(T.[Дата заведения заявки], 'yyyyMMdd') as date),
		[Дата рассмотрения заявки] = cast(format(T.[Дата рассмотрения заявки], 'yyyyMMdd') as date),
		T.[ФИО сотрудника верификации/чекер],
		T.[Номер заявки],
		Дозвон = CASE 
					--WHEN sum(T.Дозвон) >= 1 then 1
					--БЕЗЗАЛОГ Контактность "Звонок На Мобильный Телефон Клиента"
					WHEN sum(iif(T.ТипЗвонка = 'Звонок на мобильный телефон клиента', T.Дозвон, 0)) >= 1 then 1
					ELSE 0
				END
	FROM tmp.TMP_Report_verification_Contact_Contact_DetailByEmployee AS T
	WHERE T.ProcessGUID = @ProcessGUID
		AND T.ТипЗвонка = 'Звонок на мобильный телефон клиента'
		--не учитывать заявки, без сотрудника, т.е.
		--"Звонок на мобильный телефон клиента" с результатом звонка "Проверка не проводилась (системная)"
		AND trim(T.[ФИО сотрудника верификации/чекер]) <> ''
	GROUP BY
		--cast(format(T.[Дата заведения заявки], 'yyyyMMdd') as date),
		cast(format(T.[Дата рассмотрения заявки], 'yyyyMMdd') as date),
		T.[ФИО сотрудника верификации/чекер],
		T.[Номер заявки]


	INSERT #t_Contact_Employee_Day_Mobile(
		[Дата],
		[Сотрудник],
		[УникальныхЗаявок],
		[Контактность]
	)
	SELECT 
		--[Дата] = A.[Дата статуса],
		[Дата] = A.[Дата рассмотрения заявки],
		[Сотрудник] = A.[ФИО сотрудника верификации/чекер],
		[УникальныхЗаявок] = count(DISTINCT A.[Номер заявки]),
		[Контактность] = sum(A.Дозвон)
	FROM #t_Contact_Employee_Day_Mobile_Detail AS A
	WHERE 1=1
	--GROUP BY A.[Дата статуса], A.[ФИО сотрудника верификации/чекер]
	GROUP BY A.[Дата рассмотрения заявки], A.[ФИО сотрудника верификации/чекер]
END
--//'Contact.Daily.EmployeeMobile'



--"БЕЗЗАЛОГ Контактность "Звонок На Мобильный Телефон Клиента", % (дн) по одобренным"
--'Contact.Daily.EmployeeMobile.Approved'
DROP TABLE IF EXISTS #t_Contact_Employee_Day_Mobile_Approved_Detail
CREATE TABLE #t_Contact_Employee_Day_Mobile_Approved_Detail
(
	[Дата рассмотрения заявки] date,
	[ФИО сотрудника верификации/чекер] nvarchar(255),
	[Номер заявки] nvarchar(25),
	Дозвон int
)

DROP TABLE IF EXISTS #t_Contact_Employee_Day_Mobile_Approved
CREATE TABLE #t_Contact_Employee_Day_Mobile_Approved(
	[Дата] date,
	[Сотрудник] nvarchar(255),
	[УникальныхЗаявок] int,
	[Контактность] int
)

IF @Page = 'Contact.Daily.EmployeeMobile.Approved' OR @isFill_All_Tables = 1
BEGIN
	INSERT #t_Contact_Employee_Day_Mobile_Approved_Detail
	(
	    [Дата рассмотрения заявки],
	    [ФИО сотрудника верификации/чекер],
	    [Номер заявки],
	    Дозвон
	)
	SELECT 
		--[Дата статуса] = cast(format(T.[Дата заведения заявки], 'yyyyMMdd') as date),
		[Дата рассмотрения заявки] = cast(format(T.[Дата рассмотрения заявки], 'yyyyMMdd') as date),
		T.[ФИО сотрудника верификации/чекер],
		T.[Номер заявки],
		Дозвон = CASE 
					--WHEN sum(T.Дозвон) >= 1 then 1
					--БЕЗЗАЛОГ Контактность "Звонок На Мобильный Телефон Клиента"
					WHEN sum(iif(T.ТипЗвонка = 'Звонок на мобильный телефон клиента', T.Дозвон, 0)) >= 1 then 1
					ELSE 0
				END
	FROM tmp.TMP_Report_verification_Contact_Contact_DetailByEmployee AS T
		--одобрено
		INNER JOIN #t_approved AS approved ON approved.[Номер заявки] = T.[Номер заявки]
	WHERE T.ProcessGUID = @ProcessGUID
		AND T.ТипЗвонка = 'Звонок на мобильный телефон клиента'
		--не учитывать заявки, без сотрудника, т.е.
		--"Звонок на мобильный телефон клиента" с результатом звонка "Проверка не проводилась (системная)"
		AND trim(T.[ФИО сотрудника верификации/чекер]) <> ''
	GROUP BY
		--cast(format(T.[Дата заведения заявки], 'yyyyMMdd') as date),
		cast(format(T.[Дата рассмотрения заявки], 'yyyyMMdd') as date),
		T.[ФИО сотрудника верификации/чекер],
		T.[Номер заявки]


	INSERT #t_Contact_Employee_Day_Mobile_Approved(
		[Дата],
		[Сотрудник],
		[УникальныхЗаявок],
		[Контактность]
	)
	SELECT 
		--[Дата] = A.[Дата статуса],
		[Дата] = A.[Дата рассмотрения заявки],
		[Сотрудник] = A.[ФИО сотрудника верификации/чекер],
		[УникальныхЗаявок] = count(DISTINCT A.[Номер заявки]),
		[Контактность] = sum(A.Дозвон)
	FROM #t_Contact_Employee_Day_Mobile_Approved_Detail AS A
	WHERE 1=1
	--GROUP BY A.[Дата статуса], A.[ФИО сотрудника верификации/чекер]
	GROUP BY A.[Дата рассмотрения заявки], A.[ФИО сотрудника верификации/чекер]
END
--//'Contact.Daily.EmployeeMobile.Approved'






---------------------------------------------
--- общие таблицы для аггрегации по дням
---------------------------------------------
 
drop table if exists #calendar
select 
	dt_day = c.DT,
	dt_month = c.Month_Value
into #calendar
from dwh2.Dictionary.calendar as c
where c.DT >= @dt_from and c.DT < @dt_to

IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##calendar
	SELECT * INTO ##calendar FROM #calendar
END

------- всп.таблица список выводимых статусов
drop table if exists #table_status
        
select distinct Status='Верификация КЦ' 
into #table_status
union all select 'Контроль данных' 
union all select 'Верификация Call 2' 
union all select 'Верификация клиента' 
union all select 'Верификация ТС'
union all select 'Верификация'
        
          
        
        
drop table if exists #structure_firstTable
create table #structure_firstTable (
	[num_rows] int null 
	, [name_indicator] nvarchar(250) null
)

insert into #structure_firstTable([num_rows] ,[name_indicator])
values (1             ,'Общее кол-во заведенных заявок')
    , (1             ,'Общее кол-во заведенных заявок Call2')
    , (2             ,'Кол-во автоматических отказов Логином')
    , (2             ,'Кол-во автоматических отказов Call2')
    , (3             ,'%  автоматических отказов Логином')
    , (3             ,'%  автоматических отказов Call2')
    , (4             ,'Общее кол-во уникальных заявок на этапе')
    , (5             ,'Общее кол-во заявок на этапе')
    , (7             ,'TTY  - % заявок рассмотренных в течение 7 минут на этапе')
    , (8             ,'TTY  - % заявок рассмотренных в течение 30 минут на этапе')
    , (9             ,'TTY  - % заявок рассмотренных в течение 3-х минут на этапе')
    , (10            ,'Среднее время заявки в ожидании очереди на этапе')
    , (12            ,'Средний Processing time на этапе (время обработки заявки)')
    , (15            ,'Кол-во одобренных заявок после этапа')
    , (18            ,'Кол-во отказов со стороны сотрудников')
    , (21            ,'Approval rate - % одобренных после этапа')
    , (24            ,'Approval rate % Логином')
    , (25            ,'Общее кол-во отложенных заявок на этапе')
	, (26            ,'Уникальное кол-во отложенных заявок на этапе')
    , (28            ,'Кол-во заявок на этапе, отправленных на доработку')
    , (31            ,'Take rate Уровень выдачи, выраженный через одобрения')
    , (32            ,'Кол-во заявок в статусе "Займ выдан",шт.')
    , (48            , 'Среднее время по заявке (общие)')
    , (49            ,'Кол-во заявок на доработку')
    , (51            ,'Кол-во заявок в работе')
    , (52            ,'Кол-во заявок в ожидании на этапе')
    , (53            ,'Кол-во заявок на перерыве на этапе')
        
        
        
          
-- сотрудники
drop table if exists #employee_rows
select row_number() over ( order by Employee) as [empl_id]
	, Employee
into #employee_rows
from (select distinct Работник Employee from #t_dm_FedorVerificationRequests_Contact) e
        
        
        
drop table if exists #employee_rows_d
select c.dt_day as acc_period 
        , s.[num_rows] 
    , [name_indicator]
        , e.empl_id
        , e.Employee
        , t.[Status]
into #employee_rows_d
from (select dt_day from #calendar) c 
cross join #employee_rows e
cross join #structure_firstTable s
cross join #table_status t

CREATE NONCLUSTERED INDEX ix_status on #employee_rows_d([Status])
INCLUDE ([acc_period],[empl_id],[Employee])


IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##employee_rows_d
	SELECT * INTO ##employee_rows_d FROM #employee_rows_d
END

drop table if exists #employee_rows_m

SELECT c.dt_month as acc_period
    ,s.*
    ,e.empl_id 
    ,e.Employee
    ,t.[Status]
into #employee_rows_m
from (select distinct dt_month from #calendar) c 
cross join #employee_rows e
cross join #structure_firstTable s
cross join #table_status t

--select * from #employee_rows_m
CREATE NONCLUSTERED INDEX ix_Status
ON [#employee_rows_m]([Status])
INCLUDE ([acc_period],[empl_id],[Employee])


IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##employee_rows_m
	SELECT * INTO ##employee_rows_m FROM #employee_rows_m
END

----------------------------
-- Контактность
------------------------------
-- Contact.%
IF @Page IN (
	'Contact.Monthly.Employee', -- copy from 'VK.Monthly.Contact'
	'Contact.Daily.Employee', -- copy from 'VK.Daily.Contact'
	'Contact.Monthly.EmployeeMobile',
	'Contact.Monthly.EmployeeMobile.Approved',
	'Contact.Monthly.EmployeeMobile.Denied',
	'Contact.Daily.EmployeeMobile',
	'Contact.Daily.EmployeeMobile.Approved'
) OR @isFill_All_Tables = 1
BEGIN

	DROP table if exists #VKEmployees
         
	select distinct acc_period 
		, empl_id 
		, Employee 
		, [Status] 
	into #VKEmployees
	from #employee_rows_d
	where [Status] in ('Верификация клиента') 
		and Employee in (select * from #curr_employee_vr)

	
	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##VKEmployees
		SELECT * INTO ##VKEmployees FROM #VKEmployees
	END

	drop table if exists #VKEmployees_m
         
    select distinct acc_period 
        , empl_id 
        , Employee 
        , [Status] 
    into #VKEmployees_m
    from #employee_rows_m 
    where [Status] in ('Верификация клиента') 
        and Employee in (select * from #curr_employee_vr)    
        
	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##VKEmployees_m
		SELECT * INTO ##VKEmployees_m FROM #VKEmployees_m
	END

	drop table if exists #details_VK

    select * 
    into #details_VK
    from #t_dm_FedorVerificationRequests_Contact
	WHERE  1=1
		AND (Работник not in (select * from #curr_employee_cd)
			OR Работник IN (select Employee from #curr_employee_vr)
		)
		--and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to

	 CREATE INDEX ix1 ON #details_VK([Номер заявки],[Дата статуса]) INCLUDE([Статус следующий])

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##details_VK
		SELECT * INTO ##details_VK FROM #details_VK
	END


	--Отказы Логинома --DWH-2429
	DELETE #t_request_number
	DELETE #t_checklists_rejects

	INSERT #t_request_number(IdClientRequest, [Номер заявки])
	SELECT DISTINCT R.IdClientRequest, R.[Номер заявки]
	FROM #details_VK AS R

	;with loginom_checklists_rejects AS(
		SELECT 
			min(try_cast(replace(cis.LoginomNumber,'.','') AS bigint))  logn,
			cli.IdClientRequest
		FROM
			[Stg].[_fedor].[core_CheckListItem] cli 
			inner JOIN [Stg].[_fedor].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
				--and cis.[IdBehavior] =2 --	Статус - хард-код, по которому откажет логином
				and cis.[IdBehavior] IN (2, 3) -- 3. В информацию по Check* выводим информацию если по заявке был отказа, не важно кем системой или верификатором
		WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number AS R WHERE R.IdClientRequest = cli.IdClientRequest)
		GROUP BY cli.IdClientRequest
	)
	INSERT #t_checklists_rejects
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
	WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number AS R WHERE R.IdClientRequest = cli.IdClientRequest)

       
	--IF @Page = 'VK.Monthly.Contact' OR @isFill_All_Tables = 1
	IF @Page = 'Contact.Monthly.Employee' OR @isFill_All_Tables = 1
	BEGIN
		IF @isFill_All_Tables = 1
		BEGIN
			DELETE T FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_Employee AS T WHERE T.ProcessGUID = @ProcessGUID
        
			;with agg as (
			select empl_id
				, Employee		
				, acc_period  dt
				, 'Contact' Indicator
				, Контактность
				--, КоличествоЗаявок
				--, ИтогоПоСотруднику
				, УникальныхЗаявок
				--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
				--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
				, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
			FROM #VKEmployees_m AS e
				LEFT JOIN #t_Contact_Employee_Month AS a
					ON e.acc_period = a.Дата 
					AND e.Employee = a.Сотрудник
			)
			INSERT tmp.TMP_Report_verification_Contact_Contact_Monthly_Employee
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id
				, Employee
				, dt
				, Indicator
				, Сумма=isnull(Сумма,0) * 100
			--INTO tmp.TMP_Report_verification_Contact_VK_Monthly_Contact
			from agg
			/*
			union all
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id = 1000 --isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
				, Employee		='ИТОГО' 
				, dt 
				, indicator 
				, isnull(
					--case when sum(КоличествоЗаявок) <>0 then sum(Контактность * 1.0)/ sum(КоличествоЗаявок) else 0 end 
					--,0) * 100 AS Сумма
					--case when sum(ИтогоПоСотруднику) <>0 then sum(Контактность * 1.0)/ sum(ИтогоПоСотруднику) else 0 end 
					--,0) * 100 AS Сумма
					case when sum(УникальныхЗаявок) <> 0 then sum(Контактность * 1.0)/ sum(УникальныхЗаявок) else 0 end 
					,0) * 100 AS Сумма
			from agg
			group by dt, indicator
			*/
			--DWH-2683
			union ALL
			SELECT 
				ProcessGUID = @ProcessGUID,
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = try_cast(replace(a.[Контактность общая], '%', '') AS numeric(15, 3))
			from #t_Contact_Month AS a

			--WAITFOR DELAY '00:00:01'

			INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'Contact.Monthly.Employee', @ProcessGUID
		END
		ELSE BEGIN
			;with agg as (
			select empl_id
				, Employee		
				, acc_period  dt
				, 'Contact' Indicator
				, Контактность
				--, КоличествоЗаявок
				--, ИтогоПоСотруднику
				, УникальныхЗаявок
				--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
				--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
				, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
			FROM #VKEmployees_m AS e
				LEFT JOIN #t_Contact_Employee_Month AS a
					ON e.acc_period = a.Дата 
					AND e.Employee = a.Сотрудник
			)
			SELECT
				empl_id
				, Employee
				, dt
				, Indicator
				, Сумма=isnull(Сумма,0) * 100
			from agg
			/*
			union all
			SELECT
				empl_id = 1000 --isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
				, Employee		='ИТОГО' 
				, dt 
				, indicator 
				, isnull(
					--case when sum(КоличествоЗаявок) <>0 then sum(Контактность * 1.0)/ sum(КоличествоЗаявок) else 0 end 
					--,0) * 100 AS Сумма
					--case when sum(ИтогоПоСотруднику) <>0 then sum(Контактность * 1.0)/ sum(ИтогоПоСотруднику) else 0 end 
					--,0) * 100 AS Сумма
					case when sum(УникальныхЗаявок) <> 0 then sum(Контактность * 1.0)/ sum(УникальныхЗаявок) else 0 end 
					,0) * 100 AS Сумма
			from agg
			group by dt, indicator
			*/
			--DWH-2683
			union ALL
			SELECT 
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = try_cast(replace(a.[Контактность общая], '%', '') AS numeric(15, 3))
			from #t_Contact_Month AS a
          
			RETURN 0
		END
	END
	--// 'Contact.Monthly.Employee'

	IF @Page = 'Contact.Monthly.EmployeeMobile' OR @isFill_All_Tables = 1
	BEGIN
		IF @isFill_All_Tables = 1
		BEGIN
			DELETE T FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_EmployeeMobile AS T WHERE T.ProcessGUID = @ProcessGUID
        
			;with agg as (
			select empl_id
				, Employee		
				, acc_period  dt
				, 'Contact' Indicator
				, Контактность
				--, КоличествоЗаявок
				--, ИтогоПоСотруднику
				, УникальныхЗаявок
				--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
				--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
				, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
			FROM #VKEmployees_m AS e
				LEFT JOIN #t_Contact_Employee_Month_Mobile AS a
					ON e.acc_period = a.Дата 
					AND e.Employee = a.Сотрудник
			)
			INSERT tmp.TMP_Report_verification_Contact_Contact_Monthly_EmployeeMobile
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id
				, Employee
				, dt
				, Indicator
				, Сумма=isnull(Сумма,0) * 100
			--INTO tmp.TMP_Report_verification_Contact_VK_Monthly_Contact
			from agg
            /*
			union ALL
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id = 1000 --isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
				, Employee		='ИТОГО' 
				, dt 
				, indicator 
				, isnull(
					--case when sum(КоличествоЗаявок) <>0 then sum(Контактность * 1.0)/ sum(КоличествоЗаявок) else 0 end 
					--,0) * 100 AS Сумма
					--case when sum(ИтогоПоСотруднику) <>0 then sum(Контактность * 1.0)/ sum(ИтогоПоСотруднику) else 0 end 
					--,0) * 100 AS Сумма
					case when sum(УникальныхЗаявок) <> 0 then sum(Контактность * 1.0)/ sum(УникальныхЗаявок) else 0 end 
					,0) * 100 AS Сумма
			from agg
			group by dt, indicator
			*/

			/*
			union ALL
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = 
				CASE
					WHEN count(DISTINCT a.[Номер заявки]) <> 0 
					THEN sum(1.0 * A.Дозвон) / count(DISTINCT a.[Номер заявки]) * 100.0
					ELSE 0 
				END
			FROM #t_Contact_Employee_Month_Mobile_Detail AS a
			GROUP BY [Дата рассмотрения заявки]
			*/

			--DWH-2683
			union ALL
			SELECT 
				ProcessGUID = @ProcessGUID,
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = try_cast(replace(a.[Контактность общая], '%', '') AS numeric(15, 3))
			from #t_Contact_Month_Mobile AS a

			--WAITFOR DELAY '00:00:01'
        
			INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'Contact.Monthly.EmployeeMobile', @ProcessGUID
		END
		ELSE BEGIN
			;with agg as (
			select empl_id
				, Employee		
				, acc_period  dt
				, 'Contact' Indicator
				, Контактность
				--, КоличествоЗаявок
				--, ИтогоПоСотруднику
				, УникальныхЗаявок
				--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
				--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
				, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
			FROM #VKEmployees_m AS e
				LEFT JOIN #t_Contact_Employee_Month_Mobile AS a
					ON e.acc_period = a.Дата 
					AND e.Employee = a.Сотрудник
			)
			SELECT
				empl_id
				, Employee
				, dt
				, Indicator
				, Сумма=isnull(Сумма,0) * 100
			from agg
            /*
			union ALL
			SELECT
				empl_id = 1000 --isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
				, Employee		='ИТОГО' 
				, dt 
				, indicator 
				, isnull(
					--case when sum(КоличествоЗаявок) <>0 then sum(Контактность * 1.0)/ sum(КоличествоЗаявок) else 0 end 
					--,0) * 100 AS Сумма
					--case when sum(ИтогоПоСотруднику) <>0 then sum(Контактность * 1.0)/ sum(ИтогоПоСотруднику) else 0 end 
					--,0) * 100 AS Сумма
					case when sum(УникальныхЗаявок) <> 0 then sum(Контактность * 1.0)/ sum(УникальныхЗаявок) else 0 end 
					,0) * 100 AS Сумма
			from agg
			group by dt, indicator
			*/

			/*
			union ALL
			SELECT
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = 
				CASE
					WHEN count(DISTINCT a.[Номер заявки]) <> 0 
					THEN sum(1.0 * A.Дозвон) / count(DISTINCT a.[Номер заявки]) * 100.0
					ELSE 0 
				END
			FROM #t_Contact_Employee_Month_Mobile_Detail AS a
			GROUP BY [Дата рассмотрения заявки]
			*/

			--DWH-2683
			union ALL
			SELECT 
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = try_cast(replace(a.[Контактность общая], '%', '') AS numeric(15, 3))
			from #t_Contact_Month_Mobile AS a

			RETURN 0
		END
	END
	--// 'Contact.Monthly.EmployeeMobile'


	--"БЕЗЗАЛОГ Контактность "Звонок На Мобильный Телефон Клиента", % (мес) по одобренным"
	IF @Page = 'Contact.Monthly.EmployeeMobile.Approved' OR @isFill_All_Tables = 1
	BEGIN
		IF @isFill_All_Tables = 1
		BEGIN
			DELETE T FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_EmployeeMobile_Approved AS T WHERE T.ProcessGUID = @ProcessGUID
        
			;with agg as (
			select empl_id
				, Employee		
				, acc_period  dt
				, 'Contact' Indicator
				, Контактность
				--, КоличествоЗаявок
				--, ИтогоПоСотруднику
				, УникальныхЗаявок
				--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
				--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
				, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
			FROM #VKEmployees_m AS e
				LEFT JOIN #t_Contact_Employee_Month_Mobile_Approved AS a
					ON e.acc_period = a.Дата 
					AND e.Employee = a.Сотрудник
			)
			INSERT tmp.TMP_Report_verification_Contact_Contact_Monthly_EmployeeMobile_Approved
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id
				, Employee
				, dt
				, Indicator
				, Сумма=isnull(Сумма,0) * 100
			from agg
            /*
			union ALL
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id = 1000 --isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
				, Employee		='ИТОГО' 
				, dt 
				, indicator 
				, isnull(
					--case when sum(КоличествоЗаявок) <>0 then sum(Контактность * 1.0)/ sum(КоличествоЗаявок) else 0 end 
					--,0) * 100 AS Сумма
					--case when sum(ИтогоПоСотруднику) <>0 then sum(Контактность * 1.0)/ sum(ИтогоПоСотруднику) else 0 end 
					--,0) * 100 AS Сумма
					case when sum(УникальныхЗаявок) <> 0 then sum(Контактность * 1.0)/ sum(УникальныхЗаявок) else 0 end 
					,0) * 100 AS Сумма
			from agg
			group by dt, indicator
			*/
			/*
			union ALL
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = 
				CASE
					WHEN count(DISTINCT a.[Номер заявки]) <> 0 
					THEN sum(1.0 * A.Дозвон) / count(DISTINCT a.[Номер заявки]) * 100.0
					ELSE 0 
				END
			FROM #t_Contact_Employee_Month_Mobile_Approved_Detail AS a
			GROUP BY [Дата рассмотрения заявки]
			*/
			--DWH-2683
			union ALL
			SELECT 
				ProcessGUID = @ProcessGUID,
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = try_cast(replace(a.[Контактность по одобренным], '%', '') AS numeric(15, 3))
			from #t_Contact_Month_Mobile AS a

			--WAITFOR DELAY '00:00:01'

			INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'Contact.Monthly.EmployeeMobile.Approved', @ProcessGUID
		END
		ELSE BEGIN
			;with agg as (
			select empl_id
				, Employee		
				, acc_period  dt
				, 'Contact' Indicator
				, Контактность
				--, КоличествоЗаявок
				--, ИтогоПоСотруднику
				, УникальныхЗаявок
				--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
				--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
				, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
			FROM #VKEmployees_m AS e
				LEFT JOIN #t_Contact_Employee_Month_Mobile_Approved AS a
					ON e.acc_period = a.Дата 
					AND e.Employee = a.Сотрудник
			)
			SELECT
				empl_id
				, Employee
				, dt
				, Indicator
				, Сумма=isnull(Сумма,0) * 100
			from agg
            /*
			union ALL
			SELECT
				empl_id = 1000 --isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
				, Employee		='ИТОГО' 
				, dt 
				, indicator 
				, isnull(
					--case when sum(КоличествоЗаявок) <>0 then sum(Контактность * 1.0)/ sum(КоличествоЗаявок) else 0 end 
					--,0) * 100 AS Сумма
					--case when sum(ИтогоПоСотруднику) <>0 then sum(Контактность * 1.0)/ sum(ИтогоПоСотруднику) else 0 end 
					--,0) * 100 AS Сумма
					case when sum(УникальныхЗаявок) <> 0 then sum(Контактность * 1.0)/ sum(УникальныхЗаявок) else 0 end 
					,0) * 100 AS Сумма
			from agg
			group by dt, indicator
			*/
			/*
			union ALL
			SELECT
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = 
				CASE
					WHEN count(DISTINCT a.[Номер заявки]) <> 0 
					THEN sum(1.0 * A.Дозвон) / count(DISTINCT a.[Номер заявки]) * 100.0
					ELSE 0 
				END
			FROM #t_Contact_Employee_Month_Mobile_Approved_Detail AS a
			GROUP BY [Дата рассмотрения заявки]
			*/
			--DWH-2683
			union ALL
			SELECT 
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = try_cast(replace(a.[Контактность по одобренным], '%', '') AS numeric(15, 3))
			from #t_Contact_Month_Mobile AS a

			RETURN 0
		END
	END
	--// 'Contact.Monthly.EmployeeMobile.Approved'




	--"БЕЗЗАЛОГ Контактность "Звонок На Мобильный Телефон Клиента", % (мес) по отказным"
	IF @Page = 'Contact.Monthly.EmployeeMobile.Denied' OR @isFill_All_Tables = 1
	BEGIN
		IF @isFill_All_Tables = 1
		BEGIN
			DELETE T FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_EmployeeMobile_Denied AS T WHERE T.ProcessGUID = @ProcessGUID
        
			;with agg as (
			select empl_id
				, Employee		
				, acc_period  dt
				, 'Contact' Indicator
				, Контактность
				--, КоличествоЗаявок
				--, ИтогоПоСотруднику
				, УникальныхЗаявок
				--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
				--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
				, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
			FROM #VKEmployees_m AS e
				LEFT JOIN #t_Contact_Employee_Month_Mobile_Denied AS a
					ON e.acc_period = a.Дата 
					AND e.Employee = a.Сотрудник
			)
			INSERT tmp.TMP_Report_verification_Contact_Contact_Monthly_EmployeeMobile_Denied
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id
				, Employee
				, dt
				, Indicator
				, Сумма=isnull(Сумма,0) * 100
			from agg
            /*
			union ALL
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id = 1000 --isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
				, Employee		='ИТОГО' 
				, dt 
				, indicator 
				, isnull(
					--case when sum(КоличествоЗаявок) <>0 then sum(Контактность * 1.0)/ sum(КоличествоЗаявок) else 0 end 
					--,0) * 100 AS Сумма
					--case when sum(ИтогоПоСотруднику) <>0 then sum(Контактность * 1.0)/ sum(ИтогоПоСотруднику) else 0 end 
					--,0) * 100 AS Сумма
					case when sum(УникальныхЗаявок) <> 0 then sum(Контактность * 1.0)/ sum(УникальныхЗаявок) else 0 end 
					,0) * 100 AS Сумма
			from agg
			group by dt, indicator
			*/
			/*
			union ALL
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = 
				CASE
					WHEN count(DISTINCT a.[Номер заявки]) <> 0 
					THEN sum(1.0 * A.Дозвон) / count(DISTINCT a.[Номер заявки]) * 100.0
					ELSE 0 
				END
			FROM #t_Contact_Employee_Month_Mobile_Denied_Detail AS a
			GROUP BY [Дата рассмотрения заявки]
			*/
			--DWH-2683
			union ALL
			SELECT 
				ProcessGUID = @ProcessGUID,
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = try_cast(replace(a.[Контактность по отказным], '%', '') AS numeric(15, 3))
			from #t_Contact_Month_Mobile AS a

			--WAITFOR DELAY '00:00:01'
        
			INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'Contact.Monthly.EmployeeMobile.Denied', @ProcessGUID
		END
		ELSE BEGIN
			;with agg as (
			select empl_id
				, Employee		
				, acc_period  dt
				, 'Contact' Indicator
				, Контактность
				--, КоличествоЗаявок
				--, ИтогоПоСотруднику
				, УникальныхЗаявок
				--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
				--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
				, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
			FROM #VKEmployees_m AS e
				LEFT JOIN #t_Contact_Employee_Month_Mobile_Denied AS a
					ON e.acc_period = a.Дата 
					AND e.Employee = a.Сотрудник
			)
			SELECT
				empl_id
				, Employee
				, dt
				, Indicator
				, Сумма=isnull(Сумма,0) * 100
			from agg
            /*
			union ALL
			SELECT
				empl_id = 1000 --isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
				, Employee		='ИТОГО' 
				, dt 
				, indicator 
				, isnull(
					--case when sum(КоличествоЗаявок) <>0 then sum(Контактность * 1.0)/ sum(КоличествоЗаявок) else 0 end 
					--,0) * 100 AS Сумма
					--case when sum(ИтогоПоСотруднику) <>0 then sum(Контактность * 1.0)/ sum(ИтогоПоСотруднику) else 0 end 
					--,0) * 100 AS Сумма
					case when sum(УникальныхЗаявок) <> 0 then sum(Контактность * 1.0)/ sum(УникальныхЗаявок) else 0 end 
					,0) * 100 AS Сумма
			from agg
			group by dt, indicator
			*/
			/*
			union ALL
			SELECT
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = 
				CASE
					WHEN count(DISTINCT a.[Номер заявки]) <> 0 
					THEN sum(1.0 * A.Дозвон) / count(DISTINCT a.[Номер заявки]) * 100.0
					ELSE 0 
				END
			FROM #t_Contact_Employee_Month_Mobile_Denied_Detail AS a
			GROUP BY [Дата рассмотрения заявки]
			*/
			--DWH-2683
			union ALL
			SELECT 
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = try_cast(replace(a.[Контактность по отказным], '%', '') AS numeric(15, 3))
			from #t_Contact_Month_Mobile AS a
          
			RETURN 0
		END
	END
	--// 'Contact.Monthly.EmployeeMobile.Denied'




	--IF @Page = 'VK.Daily.Contact' OR @isFill_All_Tables = 1
	IF @Page = 'Contact.Daily.Employee' OR @isFill_All_Tables = 1
	BEGIN
		IF @isFill_All_Tables = 1
		BEGIN
			DELETE T FROM tmp.TMP_Report_verification_Contact_Contact_Daily_Employee AS T WHERE T.ProcessGUID = @ProcessGUID
        
			;with agg as (
			select empl_id
				, Employee		
				, acc_period  dt
				, 'Contact' Indicator
				, Контактность
				--, КоличествоЗаявок
				--, ИтогоПоСотруднику
				, УникальныхЗаявок
				--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
				--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
				, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
			FROM #VKEmployees AS e
				LEFT JOIN #t_Contact_Employee_Day AS a
					ON e.acc_period = a.Дата 
					AND e.Employee = a.Сотрудник
			)
			INSERT tmp.TMP_Report_verification_Contact_Contact_Daily_Employee
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id
				, Employee
				, dt
				, Indicator
				, Сумма=isnull(Сумма,0) * 100
			--INTO tmp.TMP_Report_verification_Contact_VK_Daily_Contact
			from agg
			/*
			union all
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id = 1000 --isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
				, Employee		='ИТОГО' 
				, dt 
				, indicator 
				, isnull(
					--case when sum(КоличествоЗаявок) <>0 then sum(Контактность * 1.0)/ sum(КоличествоЗаявок) else 0 end 
					--,0) * 100 AS Сумма
					--case when sum(ИтогоПоСотруднику) <>0 then sum(Контактность * 1.0)/ sum(ИтогоПоСотруднику) else 0 end 
					--,0) * 100 AS Сумма
					case when sum(УникальныхЗаявок) <> 0 then sum(Контактность * 1.0)/ sum(УникальныхЗаявок) else 0 end 
					,0) * 100 AS Сумма
			from agg
			group by dt, indicator
			*/
			--DWH-2683
			union ALL
			SELECT 
				ProcessGUID = @ProcessGUID,
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = try_cast(replace(a.[Контактность общая], '%', '') AS numeric(15, 3))
			from #t_Contact_Day AS a

			--WAITFOR DELAY '00:00:01'
        
			INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'Contact.Daily.Employee', @ProcessGUID
		END
		ELSE BEGIN
			;with agg as (
			select empl_id
				, Employee		
				, acc_period  dt
				, 'Contact' Indicator
				, Контактность
				--, КоличествоЗаявок
				--, ИтогоПоСотруднику
				, УникальныхЗаявок
				--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
				--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
				, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
			FROM #VKEmployees AS e
				LEFT JOIN #t_Contact_Employee_Day AS a
					ON e.acc_period = a.Дата 
					AND e.Employee = a.Сотрудник
			)
			SELECT
				empl_id
				, Employee
				, dt
				, Indicator
				, Сумма=isnull(Сумма,0) * 100
			from agg
			/*
			union all
			SELECT
				empl_id = 1000 --isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
				, Employee		='ИТОГО' 
				, dt 
				, indicator 
				, isnull(
					--case when sum(КоличествоЗаявок) <>0 then sum(Контактность * 1.0)/ sum(КоличествоЗаявок) else 0 end 
					--,0) * 100 AS Сумма
					--case when sum(ИтогоПоСотруднику) <>0 then sum(Контактность * 1.0)/ sum(ИтогоПоСотруднику) else 0 end 
					--,0) * 100 AS Сумма
					case when sum(УникальныхЗаявок) <> 0 then sum(Контактность * 1.0)/ sum(УникальныхЗаявок) else 0 end 
					,0) * 100 AS Сумма
			from agg
			group by dt, indicator
			*/
			--DWH-2683
			union ALL
			SELECT 
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = try_cast(replace(a.[Контактность общая], '%', '') AS numeric(15, 3))
			from #t_Contact_Day AS a

			RETURN 0
		END
	END
	--// 'Contact.Daily.Employee'

	IF @Page = 'Contact.Daily.EmployeeMobile' OR @isFill_All_Tables = 1
	BEGIN
		IF @isFill_All_Tables = 1
		BEGIN
			DELETE T FROM tmp.TMP_Report_verification_Contact_Contact_Daily_EmployeeMobile AS T WHERE T.ProcessGUID = @ProcessGUID
        
			;with agg as (
			select empl_id
				, Employee		
				, acc_period  dt
				, 'Contact' Indicator
				, Контактность
				--, КоличествоЗаявок
				--, ИтогоПоСотруднику
				, УникальныхЗаявок
				--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
				--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
				, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
			FROM #VKEmployees AS e
				LEFT JOIN #t_Contact_Employee_Day_Mobile AS a
					ON e.acc_period = a.Дата 
					AND e.Employee = a.Сотрудник
			)
			INSERT tmp.TMP_Report_verification_Contact_Contact_Daily_EmployeeMobile
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id
				, Employee
				, dt
				, Indicator
				, Сумма=isnull(Сумма,0) * 100
			from agg
            /*
			union ALL
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id = 1000 --isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
				, Employee		='ИТОГО' 
				, dt 
				, indicator 
				, isnull(
					--case when sum(КоличествоЗаявок) <>0 then sum(Контактность * 1.0)/ sum(КоличествоЗаявок) else 0 end 
					--,0) * 100 AS Сумма
					--case when sum(ИтогоПоСотруднику) <>0 then sum(Контактность * 1.0)/ sum(ИтогоПоСотруднику) else 0 end 
					--,0) * 100 AS Сумма
					case when sum(УникальныхЗаявок) <> 0 then sum(Контактность * 1.0)/ sum(УникальныхЗаявок) else 0 end 
					,0) * 100 AS Сумма
			from agg
			group by dt, indicator
			*/
			/*
			union ALL
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = 
				CASE
					WHEN count(DISTINCT a.[Номер заявки]) <> 0 
					THEN sum(1.0 * A.Дозвон) / count(DISTINCT a.[Номер заявки]) * 100.0
					ELSE 0 
				END
			FROM #t_Contact_Employee_Day_Mobile_Detail AS a
			GROUP BY [Дата рассмотрения заявки]
			*/
			--DWH-2683
			union ALL
			SELECT 
				ProcessGUID = @ProcessGUID,
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = try_cast(replace(a.[Контактность общая], '%', '') AS numeric(15, 3))
			from #t_Contact_Day_Mobile AS a

			--WAITFOR DELAY '00:00:01'
        
			INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'Contact.Daily.EmployeeMobile', @ProcessGUID
		END
		ELSE BEGIN
			;with agg as (
			select empl_id
				, Employee		
				, acc_period  dt
				, 'Contact' Indicator
				, Контактность
				--, КоличествоЗаявок
				--, ИтогоПоСотруднику
				, УникальныхЗаявок
				--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
				--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
				, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
			FROM #VKEmployees AS e
				LEFT JOIN #t_Contact_Employee_Day_Mobile AS a
					ON e.acc_period = a.Дата 
					AND e.Employee = a.Сотрудник
			)
			SELECT
				empl_id
				, Employee
				, dt
				, Indicator
				, Сумма=isnull(Сумма,0) * 100
			from agg
            /*
			union ALL
			SELECT
				empl_id = 1000 --isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
				, Employee		='ИТОГО' 
				, dt 
				, indicator 
				, isnull(
					--case when sum(КоличествоЗаявок) <>0 then sum(Контактность * 1.0)/ sum(КоличествоЗаявок) else 0 end 
					--,0) * 100 AS Сумма
					--case when sum(ИтогоПоСотруднику) <>0 then sum(Контактность * 1.0)/ sum(ИтогоПоСотруднику) else 0 end 
					--,0) * 100 AS Сумма
					case when sum(УникальныхЗаявок) <> 0 then sum(Контактность * 1.0)/ sum(УникальныхЗаявок) else 0 end 
					,0) * 100 AS Сумма
			from agg
			group by dt, indicator
			*/
			/*
			union ALL
			SELECT
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = 
				CASE
					WHEN count(DISTINCT a.[Номер заявки]) <> 0 
					THEN sum(1.0 * A.Дозвон) / count(DISTINCT a.[Номер заявки]) * 100.0
					ELSE 0 
				END
			FROM #t_Contact_Employee_Day_Mobile_Detail AS a
			GROUP BY [Дата рассмотрения заявки]
			*/
			--DWH-2683
			union ALL
			SELECT 
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = try_cast(replace(a.[Контактность общая], '%', '') AS numeric(15, 3))
			from #t_Contact_Day_Mobile AS a

			RETURN 0
		END
	END
	--// 'Contact.Daily.EmployeeMobile'


	IF @Page = 'Contact.Daily.EmployeeMobile.Approved' OR @isFill_All_Tables = 1
	BEGIN
		IF @isFill_All_Tables = 1
		BEGIN
			DELETE T FROM tmp.TMP_Report_verification_Contact_Contact_Daily_EmployeeMobile_Approved AS T WHERE T.ProcessGUID = @ProcessGUID
        
			;with agg as (
			select empl_id
				, Employee		
				, acc_period  dt
				, 'Contact' Indicator
				, Контактность
				--, КоличествоЗаявок
				--, ИтогоПоСотруднику
				, УникальныхЗаявок
				--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
				--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
				, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
			FROM #VKEmployees AS e
				LEFT JOIN #t_Contact_Employee_Day_Mobile_Approved AS a
					ON e.acc_period = a.Дата 
					AND e.Employee = a.Сотрудник
			)
			INSERT tmp.TMP_Report_verification_Contact_Contact_Daily_EmployeeMobile_Approved
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id
				, Employee
				, dt
				, Indicator
				, Сумма=isnull(Сумма,0) * 100
			from agg
			/*
			union ALL
			SELECT
				ProcessGUID = @ProcessGUID,
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = 
				CASE
					WHEN count(DISTINCT a.[Номер заявки]) <> 0 
					THEN sum(1.0 * A.Дозвон) / count(DISTINCT a.[Номер заявки]) * 100.0
					ELSE 0 
				END
			FROM #t_Contact_Employee_Day_Mobile_Approved_Detail AS a
			GROUP BY [Дата рассмотрения заявки]
			*/
			--DWH-2683
			union ALL
			SELECT 
				ProcessGUID = @ProcessGUID,
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = try_cast(replace(a.[Контактность по одобренным], '%', '') AS numeric(15, 3))
			from #t_Contact_Day_Mobile AS a

			--WAITFOR DELAY '00:00:01'

			INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'Contact.Daily.EmployeeMobile.Approved', @ProcessGUID
		END
		ELSE BEGIN
			;with agg as (
			select empl_id
				, Employee		
				, acc_period  dt
				, 'Contact' Indicator
				, Контактность
				--, КоличествоЗаявок
				--, ИтогоПоСотруднику
				, УникальныхЗаявок
				--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
				--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
				, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
			FROM #VKEmployees AS e
				LEFT JOIN #t_Contact_Employee_Day_Mobile_Approved AS a
					ON e.acc_period = a.Дата 
					AND e.Employee = a.Сотрудник
			)
			SELECT
				empl_id
				, Employee
				, dt
				, Indicator
				, Сумма=isnull(Сумма,0) * 100
			from agg
			/*
			union ALL
			SELECT
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = 
				CASE
					WHEN count(DISTINCT a.[Номер заявки]) <> 0 
					THEN sum(1.0 * A.Дозвон) / count(DISTINCT a.[Номер заявки]) * 100.0
					ELSE 0 
				END
			FROM #t_Contact_Employee_Day_Mobile_Approved_Detail AS a
			GROUP BY [Дата рассмотрения заявки]
			*/
			--DWH-2683
			union ALL
			SELECT 
				empl_id = 1000
				, Employee ='ИТОГО' 
				, dt = a.[Дата рассмотрения заявки]
				, indicator = 'Contact'
				, Сумма = try_cast(replace(a.[Контактность по одобренным], '%', '') AS numeric(15, 3))
			from #t_Contact_Day_Mobile AS a

			RETURN 0
		END
	END
	--// 'Contact.Daily.EmployeeMobile.Approved'

END
--// -- Contact.%





------------------------------
-- Общий отчет
------------------------------
IF @Page IN (
	'Contact.Monthly', --copy from 'V.Monthly.Common'

	--'Contact.Monthly.Installment',
	--'Contact.Monthly.PDL',
	--'Contact.Monthly.bigInstallment',
	'Contact.Monthly.ALL',

	'Contact.Monthly.Mobile',

	'Contact.Daily', --copy from 'V.Daily.Common'

	--'Contact.Daily.Installment',
	--'Contact.Daily.PDL',
	--'Contact.Daily.bigInstallment',
	'Contact.Daily.ALL',

	'Contact.Daily.Mobile'
) OR @isFill_All_Tables = 1
BEGIN

	------- всп.таблица показатели для статусов (Общий лист)
    drop table if exists #indicator_for_vc_va
    create table #indicator_for_vc_va (
		[num_rows] numeric(6,2) --int null 
        , [name_indicator] nvarchar(250) null
	)
	insert into #indicator_for_vc_va([num_rows] ,[name_indicator])
	values 
	--	(1 ,'Общее кол-во заведенных заявок Call2')
	--, (2 ,'Кол-во автоматических отказов Call2')
	--, (3 ,'%  автоматических отказов Call2')
	--, (4 ,'Общее кол-во уникальных заявок на этапе ВК')
	--, (4.01 ,'Первичный')
	--, (4.02 ,'Повторный')
	--, (4.03 ,'Докредитование')
	--, (4.04 ,'Не определен')

	--, (5 ,'Общее кол-во заявок на этапе ВК')
	--, (8 ,'TTY  - % заявок рассмотренных в течение 30 минут на этапе')
	--, (9 ,'TTY  - % заявок рассмотренных в течение 3-х минут на этапе')
	--, (10 ,'Среднее время заявки в ожидании очереди на этапе ВК')
	--, (12 ,'Средний Processing time на этапе (время обработки заявки) ВК')
	--, (15 ,'Кол-во одобренных заявок после этапа ВК')
	--, (18 ,'Кол-во отказов со стороны сотрудников ВК')
	--, (21 ,'Approval rate - % одобренных после этапа ВК')

    (22 ,'Контактность общая')
    , (23 ,'Контактность по одобренным')
    , (24 ,'Контактность по отказным')

	--, (25 ,'Общее кол-во отложенных заявок на этапе ВК')
	--, (26 ,'Уникальное кол-во отложенных заявок на этапе ВК')
	--, (28 ,'Кол-во заявок на этапе, отправленных на доработку ВК')
	----, (31 ,'Take rate Уровень выдачи, выраженный через одобрения')
	--, (31 ,'Take up Количество выданных заявок')
	----, (32 ,'Кол-во заявок в статусе "Займ выдан",шт.')
	--, (33 ,'Take up % выданных заявок от одобренных на Call3')
	----DWH-2309
	--, (35, 'Кол-во уникальных заявок в статусе Договор подписан')


	--IF @page= 'V.Daily.Common' OR @isFill_All_Tables = 1 
	IF @page= 'Contact.Daily' OR @isFill_All_Tables = 1 
	BEGIN
		drop table if exists #p_VK 

		select Дата = Contact.[Дата рассмотрения заявки]
			, Contact.[Контактность общая]
			, Contact.[Контактность по одобренным]
			, Contact.[Контактность по отказным]
		into #p_VK 
		FROM #t_Contact_Day AS Contact

		DROP table if exists #unp_VK_TS_Daily

		select Дата, indicator, Qty 
		into #unp_VK_TS_Daily
		from 
		(
		select v.Дата
			 , v.[Контактность общая]
			 , v.[Контактность по одобренным]
			 , v.[Контактность по отказным]
		  from #p_VK AS v

		) p
		UNPIVOT
		(Qty for indicator in (
			 [Контактность общая]
			 , [Контактность по одобренным]
			 , [Контактность по отказным]
			)
		) as unpvt


		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##unp_VK_TS_Daily
			SELECT * INTO ##unp_VK_TS_Daily FROM #unp_VK_TS_Daily

			--DROP TABLE IF EXISTS ##indicator_for_vc_va
			--SELECT * INTO ##indicator_for_vc_va FROM #indicator_for_vc_va
		END

		IF @isFill_All_Tables = 1
		BEGIN
			DELETE T
			FROM tmp.TMP_Report_verification_Contact_Contact_Daily AS T
			WHERE T.ProcessGUID = @ProcessGUID


			INSERT tmp.TMP_Report_verification_Contact_Contact_Daily
			SELECT
				ProcessGUID = @ProcessGUID,
				i.num_rows 
				--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
				, empl_id =null
				, Employee =null
				, acc_period =Дата
				, indicator =u.indicator
				, [Сумма] =null
				, Qty
				, Qty_dist=null
				, Tm_Qty =null--isnull(Tm_Qty,0.00)
			from #unp_VK_TS_Daily u 
				JOIN #indicator_for_vc_va i
					--ON u.indicator like i.name_indicator+'%'
					ON u.indicator = i.name_indicator

			--WAITFOR DELAY '00:00:01'

			INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'Contact.Daily', @ProcessGUID
		END
		ELSE BEGIN
			SELECT
				i.num_rows 
				--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
				, empl_id =null
					, Employee =null
				, acc_period =Дата
				, indicator =u.indicator
				, [Сумма] =null
					, Qty
					, Qty_dist=null
					, Tm_Qty =null--isnull(Tm_Qty,0.00)
			from #unp_VK_TS_Daily u 
			join #indicator_for_vc_va i
				--ON u.indicator like i.name_indicator+'%'
				ON u.indicator = i.name_indicator
			RETURN 0
		END

	END
	--// 'Contact.Daily'


	IF @page= 'Contact.Daily.ALL' OR @isFill_All_Tables = 1 
	BEGIN
		drop table if exists #p_VK_ALL

		select
			[Тип продукта]
			, Дата = Contact.[Дата рассмотрения заявки]
			, Contact.[Контактность общая]
			, Contact.[Контактность по одобренным]
			, Contact.[Контактность по отказным]
		into #p_VK_ALL
		FROM #t_Contact_Day_ALL AS Contact

		DROP table if exists #unp_VK_TS_Daily_ALL

		select [Тип продукта], Дата, indicator, Qty 
		into #unp_VK_TS_Daily_ALL
		from 
		(
		select
			--[Тип продукта] = pt.ProductType_Code
			[Тип продукта] = concat(cast(pt.ProductType_Order as varchar(3)), '. ', pt.ProductType_Name)
			, c.Дата
			 , [Контактность общая] = isnull(v.[Контактность общая], '0%')
			 , [Контактность по одобренным] = isnull(v.[Контактность по одобренным], '0%')
			 , [Контактность по отказным] = isnull(v.[Контактность по отказным], '0%')
		  --from #p_VK_ALL AS v
		  from #t_ProductType as pt
			inner join (
				select Дата = dt_day
				from #calendar 
			) c 
				on 1=1
			left join #p_VK_ALL AS v
				on v.[Тип продукта] = pt.ProductType_Code
				and v.Дата = c.Дата
		) p
		UNPIVOT
		(Qty for indicator in (
			 [Контактность общая]
			 , [Контактность по одобренным]
			 , [Контактность по отказным]
			)
		) as unpvt


		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##unp_VK_TS_Daily_ALL
			SELECT * INTO ##unp_VK_TS_Daily_ALL FROM #unp_VK_TS_Daily_ALL
		END

		IF @isFill_All_Tables = 1
		BEGIN
			DELETE T
			FROM tmp.TMP_Report_verification_Contact_Contact_Daily_ALL AS T
			WHERE T.ProcessGUID = @ProcessGUID


			INSERT tmp.TMP_Report_verification_Contact_Contact_Daily_ALL
			SELECT
				ProcessGUID = @ProcessGUID
				, [Тип продукта]
				, i.num_rows 
				--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
				, empl_id =null
				, Employee =null
				, acc_period =Дата
				, indicator =u.indicator
				, [Сумма] =null
				, Qty
				, Qty_dist=null
				, Tm_Qty =null--isnull(Tm_Qty,0.00)
			from #unp_VK_TS_Daily_ALL u 
				JOIN #indicator_for_vc_va i
					--ON u.indicator like i.name_indicator+'%'
					ON u.indicator = i.name_indicator

			--WAITFOR DELAY '00:00:01'

			INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'Contact.Daily.ALL', @ProcessGUID
		END
		ELSE BEGIN
			SELECT
				[Тип продукта]
				, i.num_rows 
				--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
				, empl_id =null
					, Employee =null
				, acc_period =Дата
				, indicator =u.indicator
				, [Сумма] =null
					, Qty
					, Qty_dist=null
					, Tm_Qty =null--isnull(Tm_Qty,0.00)
			from #unp_VK_TS_Daily_ALL u 
			join #indicator_for_vc_va i
				--ON u.indicator like i.name_indicator+'%'
				ON u.indicator = i.name_indicator
			RETURN 0
		END
	END
	--// 'Contact.Daily.ALL'



	IF @page= 'Contact.Daily.Mobile' OR @isFill_All_Tables = 1 
	BEGIN
		drop table if exists #p_VK_Mobile

		select Дата = Contact.[Дата рассмотрения заявки]
			, Contact.[Контактность общая]
			, Contact.[Контактность по одобренным]
			, Contact.[Контактность по отказным]
		into #p_VK_Mobile
		FROM #t_Contact_Day_Mobile AS Contact

		DROP table if exists #unp_VK_TS_Daily_Mobile

		select Дата, indicator, Qty 
		into #unp_VK_TS_Daily_Mobile
		from 
		(
		select v.Дата
			 , v.[Контактность общая]
			 , v.[Контактность по одобренным]
			 , v.[Контактность по отказным]
		  from #p_VK_Mobile AS v

		) p
		UNPIVOT
		(Qty for indicator in (
			 [Контактность общая]
			 , [Контактность по одобренным]
			 , [Контактность по отказным]
			)
		) as unpvt


		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##unp_VK_TS_Daily_Mobile
			SELECT * INTO ##unp_VK_TS_Daily_Mobile FROM #unp_VK_TS_Daily_Mobile
		END

		IF @isFill_All_Tables = 1
		BEGIN
			DELETE T
			FROM tmp.TMP_Report_verification_Contact_Contact_Daily_Mobile AS T
			WHERE T.ProcessGUID = @ProcessGUID

			INSERT tmp.TMP_Report_verification_Contact_Contact_Daily_Mobile
			SELECT
				ProcessGUID = @ProcessGUID,
				i.num_rows 
				--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
				, empl_id =null
				, Employee =null
				, acc_period =Дата
				, indicator =u.indicator
				, [Сумма] =null
				, Qty
				, Qty_dist=null
				, Tm_Qty =null--isnull(Tm_Qty,0.00)
			from #unp_VK_TS_Daily_Mobile u 
				JOIN #indicator_for_vc_va i
					--ON u.indicator like i.name_indicator+'%'
					ON u.indicator = i.name_indicator

			--WAITFOR DELAY '00:00:01'

			INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'Contact.Daily.Mobile', @ProcessGUID
		END
		ELSE BEGIN
			SELECT
				i.num_rows 
				--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
				, empl_id =null
					, Employee =null
				, acc_period =Дата
				, indicator =u.indicator
				, [Сумма] =null
					, Qty
					, Qty_dist=null
					, Tm_Qty =null--isnull(Tm_Qty,0.00)
			from #unp_VK_TS_Daily_Mobile u 
			join #indicator_for_vc_va i
				--ON u.indicator like i.name_indicator+'%'
				ON u.indicator = i.name_indicator
			RETURN 0
		END
	END
	--// 'Contact.Daily.Mobile'




	--IF @page= 'V.Monthly.Common' OR @isFill_All_Tables = 1
	IF @page= 'Contact.Monthly' OR @isFill_All_Tables = 1
	BEGIN

		DROP table if exists #p_VK_m

		SELECT 
			Дата = Contact.[Дата рассмотрения заявки]
			, Contact.[Контактность общая]
			, Contact.[Контактность по одобренным]
			, Contact.[Контактность по отказным]
		into #p_VK_m
		from #t_Contact_Month AS Contact


		DROP table if exists #unp_VK_TS_Daily_m

		SELECT Дата, indicator, Qty 
		into #unp_VK_TS_Daily_m
		from 
		(
		select v.Дата
			 , v.[Контактность общая]
			 , v.[Контактность по одобренным]
			 , v.[Контактность по отказным]
		  from #p_VK_m AS v

		) p
		UNPIVOT
		(Qty for indicator in (
			 [Контактность общая]
			 , [Контактность по одобренным]
			 , [Контактность по отказным]
			)
		) as unpvt

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##unp_VK_TS_Daily_m
			SELECT * INTO ##unp_VK_TS_Daily_m FROM #unp_VK_TS_Daily_m
		END

		IF @isFill_All_Tables = 1
		BEGIN
			--'Contact.Monthly' copy from 'V.Monthly.Common'
			DELETE T
			FROM tmp.TMP_Report_verification_Contact_Contact_Monthly AS T
			WHERE T.ProcessGUID = @ProcessGUID

			INSERT tmp.TMP_Report_verification_Contact_Contact_Monthly
			SELECT
				ProcessGUID = @ProcessGUID,
				i.num_rows 
				--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
				, empl_id =null
				  , Employee =null
				, acc_period =Дата
				, indicator =u.indicator
				, [Сумма] =null
				  , Qty
				  , Qty_dist=null
				  , Tm_Qty =null--isnull(Tm_Qty,0.00)
			--INTO tmp.TMP_Report_verification_Contact_V_Monthly_Common
			from #unp_VK_TS_Daily_m u 
			join #indicator_for_vc_va i 
				--ON u.indicator like i.name_indicator+'%'
				ON u.indicator = i.name_indicator
			--ORDER BY i.num_rows

			--WAITFOR DELAY '00:00:01'

			INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'Contact.Monthly', @ProcessGUID
		END
		ELSE BEGIN
			SELECT
				i.num_rows 
				--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
				, empl_id =null
				  , Employee =null
				, acc_period =Дата
				, indicator =u.indicator
				, [Сумма] =null
				  , Qty
				  , Qty_dist=null
				  , Tm_Qty =null--isnull(Tm_Qty,0.00)
			from #unp_VK_TS_Daily_m u 
			join #indicator_for_vc_va i 
				--ON u.indicator like i.name_indicator+'%'
				ON u.indicator = i.name_indicator
			--ORDER BY i.num_rows

			RETURN 0
		END
	END
	--// 'Contact.Monthly'


	IF @page= 'Contact.Monthly.ALL' OR @isFill_All_Tables = 1
	BEGIN

		DROP table if exists #p_VK_m_ALL

		SELECT 
			[Тип продукта],
			Дата = Contact.[Дата рассмотрения заявки]
			, Contact.[Контактность общая]
			, Contact.[Контактность по одобренным]
			, Contact.[Контактность по отказным]
		into #p_VK_m_ALL
		from #t_Contact_Month_ALL AS Contact


		DROP table if exists #unp_VK_TS_Daily_m_ALL

		SELECT [Тип продукта], Дата, indicator, Qty 
		into #unp_VK_TS_Daily_m_ALL
		from 
		(
		select 
			--[Тип продукта] = pt.ProductType_Code
			[Тип продукта] = concat(cast(pt.ProductType_Order as varchar(3)), '. ', pt.ProductType_Name)
			, c.Дата
			 , [Контактность общая] = isnull(v.[Контактность общая], '0%')
			 , [Контактность по одобренным] = isnull(v.[Контактность по одобренным], '0%')
			 , [Контактность по отказным] = isnull(v.[Контактность по отказным], '0%')
		  --from #p_VK_m_ALL AS v
		  from #t_ProductType as pt
			inner join (
				select distinct Дата = dt_month
				from #calendar 
			) c 
				on 1=1
			left join #p_VK_m_ALL AS v
				on v.[Тип продукта] = pt.ProductType_Code
				and v.Дата = c.Дата
		) p
		UNPIVOT
		(Qty for indicator in (
			 [Контактность общая]
			 , [Контактность по одобренным]
			 , [Контактность по отказным]
			)
		) as unpvt

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##unp_VK_TS_Daily_m_ALL
			SELECT * INTO ##unp_VK_TS_Daily_m_ALL FROM #unp_VK_TS_Daily_m_ALL
		END

		IF @isFill_All_Tables = 1
		BEGIN
			DELETE T
			FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_ALL AS T
			WHERE T.ProcessGUID = @ProcessGUID

			INSERT tmp.TMP_Report_verification_Contact_Contact_Monthly_ALL
			SELECT
				ProcessGUID = @ProcessGUID,
				[Тип продукта],
				i.num_rows 
				--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
				, empl_id =null
				, Employee =null
				, acc_period =Дата
				, indicator =u.indicator
				, [Сумма] =null
				, Qty
				, Qty_dist=null
				, Tm_Qty =null --isnull(Tm_Qty,0.00)
			from #unp_VK_TS_Daily_m_ALL u 
			join #indicator_for_vc_va i 
				--ON u.indicator like i.name_indicator+'%'
				ON u.indicator = i.name_indicator
			--ORDER BY i.num_rows

			--WAITFOR DELAY '00:00:01'

			INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'Contact.Monthly.ALL', @ProcessGUID
		END
		ELSE BEGIN
			SELECT
				[Тип продукта],
				i.num_rows 
				--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
				, empl_id =null
				  , Employee =null
				, acc_period =Дата
				, indicator =u.indicator
				, [Сумма] =null
				  , Qty
				  , Qty_dist=null
				  , Tm_Qty =null--isnull(Tm_Qty,0.00)
			from #unp_VK_TS_Daily_m_ALL u 
			join #indicator_for_vc_va i 
				--ON u.indicator like i.name_indicator+'%'
				ON u.indicator = i.name_indicator
			--ORDER BY i.num_rows

			RETURN 0
		END
	END
	--// 'Contact.Monthly.ALL'



	IF @page= 'Contact.Monthly.Mobile' OR @isFill_All_Tables = 1
	BEGIN

		DROP table if exists #p_VK_m_Mobile

		SELECT 
			Дата = Contact.[Дата рассмотрения заявки]
			, Contact.[Контактность общая]
			, Contact.[Контактность по одобренным]
			, Contact.[Контактность по отказным]
		into #p_VK_m_Mobile
		from #t_Contact_Month_Mobile AS Contact


		DROP table if exists #unp_VK_TS_Daily_m_Mobile

		SELECT Дата, indicator, Qty 
		into #unp_VK_TS_Daily_m_Mobile
		from 
		(
		select v.Дата
			 , v.[Контактность общая]
			 , v.[Контактность по одобренным]
			 , v.[Контактность по отказным]
		  from #p_VK_m_Mobile AS v

		) p
		UNPIVOT
		(Qty for indicator in (
			 [Контактность общая]
			 , [Контактность по одобренным]
			 , [Контактность по отказным]
			)
		) as unpvt

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##unp_VK_TS_Daily_m_Mobile
			SELECT * INTO ##unp_VK_TS_Daily_m_Mobile FROM #unp_VK_TS_Daily_m_Mobile
		END

		IF @isFill_All_Tables = 1
		BEGIN
			DELETE T
			FROM tmp.TMP_Report_verification_Contact_Contact_Monthly_Mobile AS T
			WHERE T.ProcessGUID = @ProcessGUID

			INSERT tmp.TMP_Report_verification_Contact_Contact_Monthly_Mobile
			SELECT
				ProcessGUID = @ProcessGUID,
				i.num_rows 
				--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
				, empl_id =null
				  , Employee =null
				, acc_period =Дата
				, indicator =u.indicator
				, [Сумма] =null
				  , Qty
				  , Qty_dist=null
				  , Tm_Qty =null--isnull(Tm_Qty,0.00)
			from #unp_VK_TS_Daily_m_Mobile u 
			join #indicator_for_vc_va i 
				--ON u.indicator like i.name_indicator+'%'
				ON u.indicator = i.name_indicator
			--ORDER BY i.num_rows

			--WAITFOR DELAY '00:00:01'

			INSERT LogDb.dbo.Fill_Report_verification_Contact(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'Contact.Monthly.Mobile', @ProcessGUID
		END
		ELSE BEGIN
			SELECT
				i.num_rows 
				--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
				, empl_id =null
				  , Employee =null
				, acc_period =Дата
				, indicator =u.indicator
				, [Сумма] =null
				  , Qty
				  , Qty_dist=null
				  , Tm_Qty =null--isnull(Tm_Qty,0.00)
			from #unp_VK_TS_Daily_m_Mobile u 
			join #indicator_for_vc_va i 
				--ON u.indicator like i.name_indicator+'%'
				ON u.indicator = i.name_indicator
			--ORDER BY i.num_rows

			RETURN 0
		END
	END
	--// 'Contact.Monthly.Mobile'

END -- общий лист по  дням
--// Общий отчет


IF @Page = 'Fill_All_Tables' BEGIN
	SELECT @eventType = concat(@Page, ' FINISH')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Report_verification_Contact',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID

	--BEGIN TRAN

	UPDATE F
	SET EndDateTime = getdate()
	FROM LogDb.dbo.Fill_Report_verification_Contact AS F
	WHERE F.ReportPage = @Page AND F.ProcessGUID = @ProcessGUID

	--COMMIT

	--SELECT ProcessGUID = @ProcessGUID
	RETURN 0
END

END TRY
BEGIN CATCH
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
			ROLLBACK;

	SELECT @message = concat(
		'EXEC dbo.Report_verification_Contact ',
		'@Page=''', @Page, ''', ',
		'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@isDebug=', convert(varchar(10), @isDebug)
	)

	SELECT @eventType = concat(@Page, ' ERROR')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Report_verification_Contact',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END
