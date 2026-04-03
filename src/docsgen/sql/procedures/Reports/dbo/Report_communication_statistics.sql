/*
EXEC dbo.Report_communication_statistics
	@Page = 'Detail' -- Детализация
	,@method_guid = '9bb0d5cc-2624-4fea-bfef-1d8b40ee6c21'
	,@templates = '2c7a8fc8-3552-11eb-b566-0242ac130006,ac1397a2-84e8-11ec-ae9f-0242ac140006,b13f51bc-f3a6-11ec-8dae-0242ac100003,e4f49078-4085-11ec-b967-0242ac130005,f97df31c-33d5-11eb-bbf6-0242ac130006'
	,@dtFrom = '2024-09-22'
	,@dtTo =  '2024-09-23'
	,@isDebug = 1

EXEC dbo.Report_communication_statistics
	@Page = 'Contacts_gt_threshold' -- контакты, по которым превышен порог
	,@method_guid = '9bb0d5cc-2624-4fea-bfef-1d8b40ee6c21'
	,@templates = '2c7a8fc8-3552-11eb-b566-0242ac130006,ac1397a2-84e8-11ec-ae9f-0242ac140006,b13f51bc-f3a6-11ec-8dae-0242ac100003,e4f49078-4085-11ec-b967-0242ac130005,f97df31c-33d5-11eb-bbf6-0242ac130006'
	,@dtFrom = '2024-09-22'
	,@dtTo =  '2024-09-23'
	,@isDebug = 1

EXEC dbo.Report_communication_statistics
	@Page = 'Statistics' -- Сводная таблица
	,@method_guid = '9bb0d5cc-2624-4fea-bfef-1d8b40ee6c21'
	,@templates = '2c7a8fc8-3552-11eb-b566-0242ac130006,ac1397a2-84e8-11ec-ae9f-0242ac140006,b13f51bc-f3a6-11ec-8dae-0242ac100003,e4f49078-4085-11ec-b967-0242ac130005,f97df31c-33d5-11eb-bbf6-0242ac130006'
	,@dtFrom = '2024-09-22'
	,@dtTo =  '2024-09-23'
	,@isDebug = 1
*/
-- =============================================
-- Author:		А.Никитин
-- Create date: 2024-09-20
-- Description:	DWH-2710 Отчет по кол. отправленных SMS клиенту
-- =============================================
CREATE   PROC dbo.Report_communication_statistics
--declare
	@Page nvarchar(100) = 'Statistics'
	,@method_guid nvarchar(36) 
	,@templates nvarchar(max)
	,@dtFrom date = null -- '2021-04-01'
	,@dtTo date =  null --'2021-04-26'

	--@ProductType_Code varchar(20) = NULL --'installment',
	--,@ProcessGUID varchar(36) = NULL -- guid процесса
	,@isDebug int = 0
AS
BEGIN

	SET NOCOUNT ON;

BEGIN TRY

	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50)
	DECLARE @description nvarchar(1024), @message nvarchar(1024), @error_number int
	DECLARE @ProcessGUID varchar(36) = newid() -- guid процесса

	DECLARE @dt_from date, @dt_to date
	DECLARE @threshold int = 10

	IF @dtFrom is not NULL BEGIN
		SET @dt_from = @dtFrom
	END 
	ELSE BEGIN
		SET @dt_from = cast(format(getdate(),'yyyyMM01') AS date)	         
	END

	IF @dtTo is not NULL BEGIN
		IF @dtTo > cast(getdate() AS date) BEGIN
			SELECT @dtTo = cast(getdate() AS date)
		END

		SET @dt_to = dateadd(day,1,@dtTo)
	END
	ELSE BEGIN
		SET @dt_to = dateadd(day,1,cast(getdate() as date))
	END 

	DROP TABLE IF EXISTS #t_template
	CREATE TABLE #t_template(
		template_guid nvarchar(36) PRIMARY KEY,
		template_code nvarchar(255),
		template_name nvarchar(512),
		template_name_code nvarchar(800) --= concat(C.template_name, ' (', C.template_code, ')'), -- шаблон
	)

	INSERT #t_template(
		template_guid,
		template_code,
		template_name,
		template_name_code
	)
	select DISTINCT
		template_guid = T.guid,
		template_code = T.code,
		template_name = T.name,
		template_name_code = concat(T.name, ' (', T.code, ')') -- шаблон
	FROM string_split(@templates, ',') AS S
		INNER JOIN Stg._COMCENTER.templates AS T
			ON T.guid = cast(S.value AS nvarchar(36))

	DROP TABLE IF EXISTS #t_Indicator
	CREATE TABLE #t_Indicator
	(
		ind_id int,
		ind_num varchar(10),
		ind_code varchar(100),
		ind_name varchar(100),
		is_visible int,
		PRIMARY KEY(ind_code)
	)

	INSERT #t_Indicator(ind_id, ind_num, ind_code, ind_name, is_visible)
	VALUES 
		(1, '1', 'com_count', 'Общее кол-во отправленных коммуникаций', 1),
		(2, '2', 'contact_count', 'Кол-во клиентов', 1),
		(3, '3', 'com_count_gt_threshold', concat('Кол. коммуникаций больше порога (',format(@threshold,'0'),')'), 1),
		(4, '4', 'contact_avg', 'Среднее кол-во коммуникаций, отправленных клиенту', 1)

	DROP TABLE IF EXISTS #t_Report_Weekly
	CREATE TABLE #t_Report_Weekly
	(
		template_name_code nvarchar(1000) NOT NULL, --Шаблон
		yearweek_id int NOT NULL,
		yearweek_code varchar(100) NOT NULL,
		ind_code varchar(100) NOT NULL,
		--rep_date date NOT NULL,
		ind_value numeric(12, 2) NOT NULL,
		rep_value varchar(20) NOT NULL
	)
	INSERT #t_Report_Weekly
	(
	    template_name_code,
	    yearweek_id,
	    yearweek_code,
	    ind_code,
	    ind_value,
	    rep_value
	)
	SELECT DISTINCT
	    T.template_name_code,
	    yearweek_id = C.id_yearweek,
		yearweek_code = 
			concat(
				format(C.id_First_Day_Of_Week, 'dd-MM'), ' ',
				format(dateadd(DAY, 6, C.id_First_Day_Of_Week), 'dd-MM')
			),
	    I.ind_code,
		ind_value = 0,
	    rep_value = '0'
	FROM #t_Indicator AS I
		INNER JOIN dwh2.Dictionary.calendar AS C
			ON @dt_from <= C.DT AND C.DT < @dt_to
		INNER JOIN #t_template AS T
			ON 1=1

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_template
		SELECT * INTO ##t_template FROM #t_template

		DROP TABLE IF EXISTS ##t_Indicator
		SELECT * INTO ##t_Indicator FROM #t_Indicator

		--DROP TABLE IF EXISTS ##t_Report_Weekly
		--SELECT * INTO ##t_Report_Weekly FROM #t_Report_Weekly

		--RETURN 0
	END




	DROP TABLE IF EXISTS #t_comm
	SELECT 
		C.guid --идентификатор коммуникаци
		,C.created_at --дата создания коммуникации
		,created_date = cast(C.created_at AS date) --дата создания коммуникации
		,C.contact_method_guid
		,C.method_guid
		,C.template_guid
		,C.communication_status_guid
		,C.system_code_guid
	INTO #t_comm
	from Stg._COMCENTER.communications AS C
	WHERE 1=1
		AND C.method_guid = @method_guid
		AND C.created_at between @dt_from and @dt_to
		and C.template_guid in (select template_guid from #t_template)

	CREATE INDEX ix3 ON #t_comm(template_guid)


	DROP TABLE IF EXISTS #t_communications

	select --top(1000)
		communication_guid = C.guid --идентификатор коммуникаци

		--,C.contact_method_guid -->contacts_methods.guid ->value с кем была коммуникация
		,contact_value = CM.value

		--,C.method_guid -->methods.guid - метод коммуникации
		--,method_code = M.code
		,method_name = M.name

		--,C.template_guid -->template.guid --шаблон коммуникации
		,template_code = T.code
		,template_name = T.name

		--,communication_status_guid -->текущий статус
		,status_code = CS.code
		,status_name = CS.name

		,C.created_at --дата создания коммуникации
		--,created_date = cast(C.created_at AS date) --дата создания коммуникации
		,C.created_date --дата создания коммуникации

		--,C.system_code_guid --> система инциатор коммуникации
		,system_code = SC.code
		--,system_name = SC.name
	INTO #t_communications
	from #t_comm AS C --Stg._COMCENTER.communications AS C
		LEFT JOIN Stg._COMCENTER.contacts_methods AS CM
			ON CM.guid = C.contact_method_guid
		LEFT JOIN Stg._COMCENTER.methods AS M
			ON M.guid = C.method_guid
		LEFT JOIN Stg._COMCENTER.templates AS T
			ON T.guid = C.template_guid
		LEFT JOIN Stg._COMCENTER.communication_statuses AS CS
			ON CS.guid = C.communication_status_guid
		LEFT JOIN Stg._COMCENTER.system_codes AS SC
			ON SC.guid = C.system_code_guid
	--WHERE 1=1
	--	AND C.method_guid = @method_guid
	--	AND C.created_at between @dt_from and @dt_to
	--	and C.template_guid in (select template_guid from #t_template)


	CREATE INDEX ix1 
	ON #t_communications(created_date)
	INCLUDE (template_name, template_code, contact_value)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_communications
		SELECT * INTO ##t_communications FROM #t_communications
	END

	IF @Page = 'Detail' BEGIN
		SELECT 
			C.communication_guid,
			C.contact_value,
			C.method_name,
			C.template_code,
			C.template_name,
			C.status_code,
			C.status_name,
			C.created_at,
			C.system_code 
		FROM #t_communications AS C
		ORDER BY C.created_at

		RETURN 0
	END
	--// 'Detail'

	DROP TABLE IF EXISTS #t_contact_communications


	IF @Page IN ('ALL', 'Statistics', 'Contacts_gt_threshold') BEGIN
		SELECT 
			A.yearweek_id,
			A.yearweek_code,
			A.template_name_code,
			A.contact_value, -- контакт
			A.com_to_contact,
			--кол-во коммункаций больше порога
			com_to_contact_gt_threshold = iif(A.com_to_contact > @threshold, A.com_to_contact - @threshold, 0)
		INTO #t_contact_communications
		FROM (
			SELECT
				yearweek_id = D.id_yearweek,
				yearweek_code = 
					concat(
						format(D.id_First_Day_Of_Week, 'dd-MM'), ' ',
						format(dateadd(DAY, 6, D.id_First_Day_Of_Week), 'dd-MM')
					),
				template_name_code = concat(C.template_name, ' (', C.template_code, ')'), -- шаблон
				C.contact_value, -- контакт
				com_to_contact = count(1) -- кол. отправленных коммуникаций контакту
			FROM #t_communications AS C
				INNER JOIN dwh2.Dictionary.calendar AS D
					ON C.created_date = D.DT
			GROUP BY 
				D.id_yearweek,
				concat(
					format(D.id_First_Day_Of_Week, 'dd-MM'), ' ',
					format(dateadd(DAY, 6, D.id_First_Day_Of_Week), 'dd-MM')
				),
				concat(C.template_name, ' (', C.template_code, ')'),
				C.contact_value
			) AS A

	END
	--//'Statistics', 'Contacts_gt_threshold'

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_contact_communications
		SELECT * INTO ##t_contact_communications FROM #t_contact_communications
	END


	IF @Page = 'Contacts_gt_threshold' BEGIN
		-- контакты, по которым превышен порог 
		SELECT DISTINCT
			C.contact_value
		FROM #t_contact_communications AS C
		WHERE C.com_to_contact_gt_threshold > 0
		ORDER BY C.contact_value

		RETURN 0
	END
	--// 'Contacts_gt_threshold'



	DROP TABLE IF EXISTS #t_statistics

	--Statistics
	IF @Page IN ('ALL', 'Statistics') BEGIN
		/*
		Шаблон 1
			Общее кол. отправленных коммуникаций
			В среднем по клиенту
			Кол. коммуникаций больше порога (значение порога)		
		*/
		SELECT 
			C.yearweek_id,
			C.yearweek_code,
			C.template_name_code,

			com_count = sum(C.com_to_contact), -- Общее кол. отправленных коммуникаций
			contact_count = count(1), -- кол. контактов
			--Кол. коммуникаций больше порога (значение порога)		
			com_count_gt_threshold = sum(C.com_to_contact_gt_threshold),

			--Среднее кол-во коммуникаций, отправленных контакту
			contact_avg = 
				iif(count(1) > 0,
					1.0 * sum(C.com_to_contact) / count(1),
					0
				)
		INTO #t_statistics
		FROM #t_contact_communications AS C
		GROUP BY
			C.yearweek_id,
			C.yearweek_code,
			C.template_name_code
	END
	--//Statistics

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_statistics
		SELECT * INTO ##t_statistics FROM #t_statistics
	END



	IF @Page = 'Statistics' BEGIN

		--'com_count' --'Общее кол-во отправленных коммуникаций'
		UPDATE R
		SET R.ind_value = S.com_count,
			R.rep_value = format(S.com_count, '0')
		FROM #t_Report_Weekly AS R
			INNER JOIN #t_statistics AS S
				ON S.template_name_code = R.template_name_code
				AND S.yearweek_id = R.yearweek_id
		WHERE R.ind_code = 'com_count' --'Общее кол-во отправленных коммуникаций'

		--'contact_count' -- 'Кол-во контактов'
		UPDATE R
		SET R.ind_value = S.contact_count,
			R.rep_value = format(S.contact_count, '0')
		FROM #t_Report_Weekly AS R
			INNER JOIN #t_statistics AS S
				ON S.template_name_code = R.template_name_code
				AND S.yearweek_id = R.yearweek_id
		WHERE R.ind_code = 'contact_count' -- 'Кол-во контактов'

		--'com_count_gt_threshold' -- 'Кол. коммуникаций больше порога'
		UPDATE R
		SET R.ind_value = S.com_count_gt_threshold,
			R.rep_value = format(S.com_count_gt_threshold, '0')
		FROM #t_Report_Weekly AS R
			INNER JOIN #t_statistics AS S
				ON S.template_name_code = R.template_name_code
				AND S.yearweek_id = R.yearweek_id
		WHERE R.ind_code = 'com_count_gt_threshold' -- 'Кол. коммуникаций больше порога'

		--'contact_avg' -- 'Среднее кол-во коммуникаций, отправленных контакту'
		UPDATE R
		SET R.ind_value = S.contact_avg,
			R.rep_value = format(S.contact_avg, '0.00')
		FROM #t_Report_Weekly AS R
			INNER JOIN #t_statistics AS S
				ON S.template_name_code = R.template_name_code
				AND S.yearweek_id = R.yearweek_id
		WHERE R.ind_code = 'contact_avg' -- 'Среднее кол-во коммуникаций, отправленных контакту'

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_Report_Weekly
			SELECT * INTO ##t_Report_Weekly FROM #t_Report_Weekly
		END

		--SELECT 
		--	S.yearweek_id,
		--	S.yearweek_code,
		--	S.template_name_code,
		--	S.com_count,
		--	S.contact_count,
		--	S.com_count_gt_threshold,
		--	S.contact_avg
		--FROM #t_statistics AS S
		--ORDER BY S.yearweek_id, S.template_name_code

		SELECT 
			R.template_name_code,
			R.yearweek_id,
			R.yearweek_code,
			I.ind_id,
			I.ind_num,
			R.ind_code,
			I.ind_name,
			R.ind_value,
			R.rep_value
		FROM #t_Report_Weekly AS R
			INNER JOIN #t_Indicator AS I
				ON I.ind_code = R.ind_code
				AND (I.is_visible = 1 OR @isDebug = 1)
		ORDER BY R.template_name_code, R.yearweek_id, I.ind_num

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
		'EXEC dbo.Report_communication_statistic ',
		'@Page=''', @Page, ''', ',
		'@method_guid=', iif(@method_guid IS NULL, 'NULL', ''''+@method_guid+''''), ', ',
		'@templates=', iif(@templates IS NULL, 'NULL', ''''+@templates+''''), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		--'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@isDebug=', convert(varchar(10), @isDebug)
	)

	SELECT @eventType = concat(@Page, ' ERROR')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Report_communication_statistic',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END