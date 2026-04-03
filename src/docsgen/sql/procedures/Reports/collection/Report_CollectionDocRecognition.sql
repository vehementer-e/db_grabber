-- =============================================
-- Author:		А.Никитин
-- Create date: 2024-11-26
-- Description:	DWH-2827 Реализовать отчет по распознаванию документов
-- =============================================
/*
EXEC collection.Report_CollectionDocRecognition
	@Page = 'Detail'
	,@dtFrom = '2024-11-01'
	,@dtTo = '2024-12-10'

*/
CREATE PROC collection.Report_CollectionDocRecognition
--declare
	@Page nvarchar(100) = 'Detail'
	,@dtFrom date = null -- '2021-04-01'
	,@dtTo date =  null --'2021-04-26'
	,@DocumentType nvarchar(1000) = NULL
	,@ProcessGUID varchar(36) = NULL -- guid процесса
	,@isDebug int = 0
AS
BEGIN
	SET NOCOUNT ON;
BEGIN TRY

	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50)
	DECLARE @description nvarchar(1024), @message nvarchar(1024), @error_number int
	DECLARE @dt_from date, @dt_to date

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


	DROP TABLE IF EXISTS #t_DocumentType_List
	CREATE TABLE #t_DocumentType_List(
		sort_order int NOT NULL,
		DocumentType_Code nvarchar(255) NOT NULL,
		DocumentType_Name nvarchar(255) NOT NULL
	)
	INSERT #t_DocumentType_List
	(
	    sort_order,
	    DocumentType_Code,
	    DocumentType_Name
	)
	VALUES
		(1,'CourtDecision','Решение суда'),
		(2,'CourtOrder','Судебный приказ'),
		(3,'UseSheet','Исполнительный лист')


	DROP TABLE IF EXISTS #t_Fields_List
	CREATE TABLE #t_Fields_List(
		sort_order int NOT NULL,
		FieldInfo_Code nvarchar(255) NOT NULL,
		FieldInfo_Name nvarchar(255) NOT NULL
	)

	INSERT #t_Fields_List
	(
	    sort_order,
	    FieldInfo_Code,
		FieldInfo_Name
	)
	VALUES
		(1,'ContractNumber','№ договора'),
		(2,'CourtName','Наименование суда'),

		(3,'ClientFIO','ФИО (ответчика) Заемщика'),
		(4,'Passport','Серия / № паспорта клиента'),

		(5,'NewOwnerFIO','ФИО (ответчика) нового собственника'),
		(6,'Birthdate','дата рождения нового собственника'),
		--(7,'','адрес нового собственника'),

		(8,'ClaimantName','Наименование истца'),

		(9,'DecisionAmount','Сумма по решению (Реш.)'),
		(10,'MainDebtAmount','ОД Реш.'),
		(11,'ProcentAmount','%% Реш.'),
		(12,'FineAmount','пени Реш.'),
		(13,'StateDutyAmount','госпошлина Реш.'),
		--(14,'','иные расходы (кроме ОД,%, пени, госпошлины)'),

		(15,'DealNumber','№ дела'),
		(16,'Decision','Вид решения суда'),
		(17,'DecisionDate','Дата решения'),
		(18,'CourtDecision','Решение суда'),
		(19,'NumberIL','№ ИЛ'),
		(20,'SubjectIL','Тип ИЛ'),
		(21,'DateIL','Дата ИЛ'),
		--(22,'','Сумма ИЛ'),
		(23,'CourtDecisionEffectiveDate','Дата вступления в силу решения суда')


	DROP TABLE IF EXISTS #t_DocumentType_X_FieldInfo
	CREATE TABLE #t_DocumentType_X_FieldInfo(
		DocumentType_Code nvarchar(255) NOT NULL,
		FieldInfo_Code nvarchar(255) NOT NULL,
		isCount int NOT NULL
	)

	INSERT #t_DocumentType_X_FieldInfo
	(
	    DocumentType_Code,
	    FieldInfo_Code,
	    isCount
	)
	SELECT D.DocumentType_Code, F.FieldInfo_Code, isCount = 1
	FROM #t_DocumentType_List AS D
		INNER JOIN #t_Fields_List AS F
			ON 1=1
	WHERE 
		(D.DocumentType_Code = 'CourtDecision' --Решение суда
			AND F.FieldInfo_Code  IN (
				'ContractNumber', --'№ договора'
				'CourtName', --'Наименование суда'
				'ClientFIO', --'ФИО (ответчика) Заемщика'
				'DecisionAmount', --'Сумма по решению (Реш.)'
				'MainDebtAmount', --'ОД Реш.'
				'ProcentAmount', --'%% Реш.'
				'FineAmount', --'пени Реш.'
				'StateDutyAmount', --'госпошлина Реш.'
				--'','иные расходы (кроме ОД,%, пени, госпошлины)'
				'DealNumber', --'№ дела'
				'Decision', --'Вид решения суда'
				'DecisionDate', --'Дата решения'
				'CourtDecision' --'Решение суда'),
				--(19,'NumberIL','№ ИЛ'),
				--(20,'SubjectIL','Тип ИЛ'),
				--(21,'DateIL','Дата ИЛ'),
				----(22,'','Сумма ИЛ'),
				--(23,'CourtDecisionEffectiveDate','Дата вступления в силу решения суда')
			)
		)
		OR 
		(D.DocumentType_Code = 'CourtOrder' --'Судебный приказ'
			AND F.FieldInfo_Code  IN (
				'ContractNumber', --'№ договора'
				'CourtName', --'Наименование суда'
				'ClientFIO', --'ФИО (ответчика) Заемщика'
				'DecisionAmount', --'Сумма по решению (Реш.)'
				'MainDebtAmount', --'ОД Реш.'
				'ProcentAmount', --'%% Реш.'
				'FineAmount', --'пени Реш.'
				'StateDutyAmount', --'госпошлина Реш.'

				'DealNumber', --'№ дела'
				'Decision', --'Вид решения суда'
				'DecisionDate', --'Дата решения'
				'CourtDecision' --'Решение суда'),
				--(19,'NumberIL','№ ИЛ'),
				--(20,'SubjectIL','Тип ИЛ'),
				--(21,'DateIL','Дата ИЛ'),
				----(22,'','Сумма ИЛ'),
				--(23,'CourtDecisionEffectiveDate','Дата вступления в силу решения суда')
			)
        )
		OR 
		(D.DocumentType_Code = 'UseSheet' --'Исполнительный лист'
			AND F.FieldInfo_Code  IN (
				'ContractNumber', --'№ договора'
				'CourtName', --'Наименование суда'
				'ClientFIO', --'ФИО (ответчика) Заемщика'



				'DealNumber', --'№ дела'
				'NumberIL', --'№ ИЛ'
				'SubjectIL', --'Тип ИЛ'
				'DateIL', --'Дата ИЛ'
				--'','Сумма ИЛ'),
				'CourtDecisionEffectiveDate' --,'Дата вступления в силу решения суда'
			)
        )




	DROP TABLE IF EXISTS #t_CollectionDocRecognition

	SELECT D.* 
	INTO #t_CollectionDocRecognition
	FROM collection.dm_CollectionDocRecognition AS D
	WHERE 1=1
		AND @dt_from <= D.CreateDate AND D.CreateDate < @dt_to
		--AND (D.DocumentTypeCode IN (select trim(value) from string_split(@DocumentType, ','))
		--	OR @DocumentType is null)

	DROP TABLE IF EXISTS #t_Detail_Main

	SELECT 
		A.EdoDocumentId,
		A.DocumentTypeId,
		A.DocumentTypeCode,
		A.DocumentTypeName,
		A.RecogDateTime,
		RecogDate = cast(A.RecogDateTime AS date),
		RecogTime = cast(A.RecogDateTime AS time(0)),
		Recog_Total = iif(A.Equal_Total = A.Count_Fields, cast(1 AS int),  cast(0 AS int))
	INTO #t_Detail_Main
	FROM (
		SELECT 
			D.EdoDocumentId,
			D.DocumentTypeId,
			D.DocumentTypeCode,
			D.DocumentTypeName,
			RecogDateTime = cast(max(D.CreateDate) AS datetime2(0)),
			--Equal_Total = sum(D.Equal),
			--Count_Fields = count(*)
			Equal_Total = sum(D.Equal * isnull(X.isCount, 0)),
			Count_Fields = count(1 * isnull(X.isCount, 0))
		--select *
		FROM #t_CollectionDocRecognition AS D
			LEFT JOIN #t_DocumentType_X_FieldInfo AS X
				ON X.DocumentType_Code = D.DocumentTypeCode
				AND X.FieldInfo_Code = D.DocumentFieldCode

		--FROM collection.dm_CollectionDocRecognition AS D
		WHERE 1=1
			--Не выводим, т.к. не реализовали
			AND D.DocumentFieldCode NOT IN (
				'Decision', -- 'Вид решения суда'
				'Birthdate', -- 'дата рождения нового собственника' не выводим
				'Passport' -- 'Серия / № паспорта клиента'
			)
		GROUP BY 
			D.EdoDocumentId,
			D.DocumentTypeId,
			D.DocumentTypeCode,
			D.DocumentTypeName
		) AS A

	CREATE INDEX ix_EdoDocumentId ON #t_Detail_Main(EdoDocumentId)





	--UPDATE F SET F.FieldInfo_Name = FieldInfo.Name
	----SELECT *
	--FROM #t_Fields_List AS F
	--	INNER JOIN Stg._collection_uat.DocumentFields AS FieldInfo
	--		ON F.FieldInfo_Code = FieldInfo.Code

	DROP TABLE IF EXISTS #t_Detail_Recog

	SELECT 
		PivotTable.EdoDocumentId,
		--
		PivotTable.CourtName,
		PivotTable.DealNumber,
		PivotTable.ContractNumber,
		PivotTable.DecisionDate,
		PivotTable.ClientFIO,
		--PivotTable.Passport,
		PivotTable.ClaimantName,
		PivotTable.CourtDecision,
		PivotTable.DecisionAmount,
		PivotTable.MainDebtAmount,
		PivotTable.ProcentAmount,
		PivotTable.FineAmount,
		PivotTable.StateDutyAmount,
		--PivotTable.Decision,
		--PivotTable.Birthdate,
		PivotTable.NewOwnerFIO,
		PivotTable.SubjectIL,
		PivotTable.NumberIL,
		PivotTable.DateIL,
		PivotTable.CourtDecisionEffectiveDate
	INTO #t_Detail_Recog
	FROM  
	(
		SELECT 
			D.EdoDocumentId,
			D.DocumentFieldCode,
			Equal = D.Equal
		FROM #t_CollectionDocRecognition AS D
	) AS SourceTable  
	PIVOT  
	(  
		max(Equal)
		FOR DocumentFieldCode IN (
			CourtName,
			DealNumber,
			ContractNumber,
			DecisionDate,
			ClientFIO,
			--Passport,
			ClaimantName,
			CourtDecision,
			DecisionAmount,
			MainDebtAmount,
			ProcentAmount,
			FineAmount,
			StateDutyAmount,
			--Decision,
			--Birthdate,
			NewOwnerFIO,
			SubjectIL,
			NumberIL,
			DateIL,
			CourtDecisionEffectiveDate
		)
	) AS PivotTable

	--SELECT * FROM #t_Detail_Recog

	IF @Page = 'Detail' BEGIN


		SELECT 
			M.EdoDocumentId,
			M.DocumentTypeId,
			M.DocumentTypeCode,
			M.DocumentTypeName,
			RecogDateTime = cast(M.RecogDateTime AS datetime2(0)),
			M.RecogDate,
			M.RecogTime,
			--
			--R.CourtName,
			--R.DealNumber,
			--R.ContractNumber,
			--R.DecisionDate,
			--R.ClientFIO,
			--R.Passport,
			--R.ClaimantName,
			--R.CourtDecision,
			--R.DecisionAmount,
			--R.MainDebtAmount,
			--R.ProcentAmount,
			--R.FineAmount,
			--R.StateDutyAmount,
			--R.Decision,
			--R.Birthdate,
			--R.NewOwnerFIO,
			--R.SubjectIL,
			--R.NumberIL,
			--R.DateIL,
			--R.CourtDecisionEffectiveDate,
			--
			--[Наименование суда] = iif(R.CourtName = 1, 'да', iif(R.CourtName = 0, 'нет', '')),
			--[№ дела] = iif(R.DealNumber = 1, 'да', iif(R.DealNumber = 0, 'нет', '')),
			--[№ договора] = iif(R.ContractNumber = 1, 'да', iif(R.ContractNumber = 0, 'нет', '')),
			--[Дата решения] = iif(R.DecisionDate = 1, 'да', iif(R.DecisionDate = 0, 'нет', '')),
			--[ФИО клиента] = iif(R.ClientFIO = 1, 'да', iif(R.ClientFIO = 0, 'нет', '')),
			--[Серия / № паспорта клиента] = iif(R.Passport = 1, 'да', iif(R.Passport = 0, 'нет', '')),
			--[Наименование истца] = iif(R.ClaimantName = 1, 'да', iif(R.ClaimantName = 0, 'нет', '')),
			--[Решение суда] = iif(R.CourtDecision = 1, 'да', iif(R.CourtDecision = 0, 'нет', '')),
			--[Сумма решения] = iif(R.DecisionAmount = 1, 'да', iif(R.DecisionAmount = 0, 'нет', '')),
			--[Сумма основного долга] = iif(R.MainDebtAmount = 1, 'да', iif(R.MainDebtAmount = 0, 'нет', '')),
			--[Сумма процентов] = iif(R.ProcentAmount = 1, 'да', iif(R.ProcentAmount = 0, 'нет', '')),
			--[Сумма пени (неустоек)] = iif(R.FineAmount = 1, 'да', iif(R.FineAmount = 0, 'нет', '')),
			--[Сумма госпошлины] = iif(R.StateDutyAmount = 1, 'да', iif(R.StateDutyAmount = 0, 'нет', '')),
			--[Решил] = iif(R.Decision = 1, 'да', iif(R.Decision = 0, 'нет', '')),
			--[Дата рождения] = iif(R.Birthdate = 1, 'да', iif(R.Birthdate = 0, 'нет', '')),
			--[ФИО нового собственника] = iif(R.NewOwnerFIO = 1, 'да', iif(R.NewOwnerFIO = 0, 'нет', '')),
			--[Предмет ИЛ] = iif(R.SubjectIL = 1, 'да', iif(R.SubjectIL = 0, 'нет', '')),
			--[Серия / № ИЛ] = iif(R.NumberIL = 1, 'да', iif(R.NumberIL = 0, 'нет', '')),
			--[Дата ИЛ] = iif(R.DateIL = 1, 'да', iif(R.DateIL = 0, 'нет', '')),
			--[Дата вступления в силу решения суда] = iif(R.CourtDecisionEffectiveDate = 1, 'да', iif(R.CourtDecisionEffectiveDate = 0, 'нет', '')),
			--
			[№ договора] = iif(R.ContractNumber = 1, 'да', iif(R.ContractNumber = 0, 'нет', '')),
			[Наименование суда] = iif(R.CourtName = 1, 'да', iif(R.CourtName = 0, 'нет', '')),
			[ФИО (ответчика) Заемщика] = iif(R.ClientFIO = 1, 'да', iif(R.ClientFIO = 0, 'нет', '')),
			--[Серия / № паспорта клиента] = iif(R.Passport = 1, 'да', iif(R.Passport = 0, 'нет', '')),
			[ФИО (ответчика) нового собственника] = iif(R.NewOwnerFIO = 1, 'да', iif(R.NewOwnerFIO = 0, 'нет', '')),
			--[дата рождения нового собственника] = iif(R.Birthdate = 1, 'да', iif(R.Birthdate = 0, 'нет', '')),
			[Наименование истца] = iif(R.ClaimantName = 1, 'да', iif(R.ClaimantName = 0, 'нет', '')),
			[Сумма по решению (Реш.)] = iif(R.DecisionAmount = 1, 'да', iif(R.DecisionAmount = 0, 'нет', '')),
			[ОД Реш.] = iif(R.MainDebtAmount = 1, 'да', iif(R.MainDebtAmount = 0, 'нет', '')),
			[%% Реш.] = iif(R.ProcentAmount = 1, 'да', iif(R.ProcentAmount = 0, 'нет', '')),
			[пени Реш.] = iif(R.FineAmount = 1, 'да', iif(R.FineAmount = 0, 'нет', '')),
			[госпошлина Реш.] = iif(R.StateDutyAmount = 1, 'да', iif(R.StateDutyAmount = 0, 'нет', '')),
			[№ дела] = iif(R.DealNumber = 1, 'да', iif(R.DealNumber = 0, 'нет', '')),
			--[Вид решения суда] = iif(R.Decision = 1, 'да', iif(R.Decision = 0, 'нет', '')),
			[Дата решения] = iif(R.DecisionDate = 1, 'да', iif(R.DecisionDate = 0, 'нет', '')),
			[Решение суда] = iif(R.CourtDecision = 1, 'да', iif(R.CourtDecision = 0, 'нет', '')),
			[№ ИЛ] = iif(R.NumberIL = 1, 'да', iif(R.NumberIL = 0, 'нет', '')),
			[Тип ИЛ] = iif(R.SubjectIL = 1, 'да', iif(R.SubjectIL = 0, 'нет', '')),
			[Дата ИЛ] = iif(R.DateIL = 1, 'да', iif(R.DateIL = 0, 'нет', '')),
			[Дата вступления в силу решения суда] = iif(R.CourtDecisionEffectiveDate = 1, 'да', iif(R.CourtDecisionEffectiveDate = 0, 'нет', '')),
			--
			--M.Recog_Total
			[Результат распознавания документа] = iif(M.Recog_Total = 1, 'да', 'нет')
		FROM #t_Detail_Main AS M
			INNER JOIN #t_Detail_Recog AS R
				ON R.EdoDocumentId = M.EdoDocumentId
		WHERE 1=1
			AND (M.DocumentTypeCode IN (select trim(value) from string_split(@DocumentType, ','))
				OR @DocumentType is null)
		ORDER BY M.RecogDateTime

		--RETURN 0
	END
	--// 'Detail'


	/*
	--% распознавания по полям за месяц
	IF @Page = 'Fields' BEGIN

		SELECT 
			A.RecogMonth,
			L.sort_order,
			--A.FieldInfo_Code,
			L.FieldInfo_Name,
			A.EqualAfterDataControl_Total,
			A.Count_Recog,
			--cast(format(case when call2.Qty<>0 then 100.0*call2.Qty_rejected/call2.Qty else 0 end,'0.0')+N'%' as nvarchar(50))
			--Perc_Recog = iif(isnull(A.Count_Recog,0) <> 0, 100.0 * A.EqualAfterDataControl_Total / A.Count_Recog, 0)
			Perc_Recog = format(iif(isnull(A.Count_Recog,0) <> 0,  1.0* A.EqualAfterDataControl_Total / A.Count_Recog, 0),'P2')
		FROM #t_Fields_List AS L
			LEFT JOIN (
				SELECT 
					RecogMonth = cast(format(R.RecogDateTime, 'yyyyMM01') AS date),
					R.FieldInfo_Code,
					EqualAfterDataControl_Total = sum(R.EqualAfterDataControl),
					Count_Recog = count(*)
				FROM #t_CollectionDocRecognition AS R
				GROUP BY
					cast(format(R.RecogDateTime, 'yyyyMM01') AS date),
					R.FieldInfo_Code
			) AS A
				ON A.FieldInfo_Code = L.FieldInfo_Code
		ORDER BY A.RecogMonth, L.sort_order
		
	END
	--// 'Fields'
	*/

	--статистика не зависит от параметра @DocumentType
	DROP TABLE IF EXISTS #t_Indicator
	CREATE TABLE #t_Indicator
	(
		ind_id int,
		ind_num varchar(10),
		ind_code varchar(100),
		ind_name varchar(100),
		is_visible int,
		category varchar(100)
		PRIMARY KEY(ind_code)
	)

	INSERT #t_Indicator(ind_id, ind_num, ind_code, ind_name, is_visible, category)
	VALUES 
	(1, '1', 'total', 'Общее количество документов на распознавание', 1, '*'),
	(2, '1.1.', 'CourtDecision_total', 'Решение суда', 1, '1. Всего документов'),
	(3, '1.2.', 'CourtOrder_total', 'Судебный приказ', 1, '1. Всего документов'),
	(4, '1.3.', 'UseSheet_total', 'Исполнительный лист', 1, '1. Всего документов'),

	(5, '2', 'recog_total', 'Распознано', 1, '*'),
	(6, '2.1.', 'CourtDecision_recog', 'Решение суда', 1, '2. Распознанные'),
	(7, '2.2.', 'CourtOrder_recog', 'Судебный приказ', 1, '2. Распознанные'),
	(8, '2.3.', 'UseSheet_recog', 'Исполнительный лист', 1, '2. Распознанные'),

	(9, '3', 'norec_total', 'Не распознано', 1, '*'),
	(10, '3.1.', 'CourtDecision_norec', 'Решение суда', 1, '3. Нераспознаные'),
	(11, '3.2.', 'CourtOrder_norec', 'Судебный приказ', 1, '3. Нераспознаные'),
	(12, '3.3.', 'UseSheet_norec', 'Исполнительный лист', 1, '3. Нераспознаные')

	--SELECT * FROM #t_Indicator ORDER BY ind_id

	DROP TABLE IF EXISTS #t_Report_Statistics
	CREATE TABLE #t_Report_Statistics
	(
		ind_code varchar(100) NOT NULL,
		rep_date date NOT NULL,
		rep_value int NOT NULL,
		rep_value_perc varchar(20) NOT NULL,
		rep_value_num_perc numeric(7,2) NOT NULL
	)

	INSERT #t_Report_Statistics
	(
		ind_code,
		rep_date,
		rep_value,
		rep_value_perc,
		rep_value_num_perc
	)
	SELECT 
		I.ind_code,
		rep_date = cast(getdate() AS date), --@dt_to,
	    rep_value = 0,
		rep_value_perc = '0.0%',
		rep_value_num_perc = 0
	FROM #t_Indicator AS I

	IF @Page IN ('Statistics') BEGIN

		--Общее количество документов на распознавание
		UPDATE S 
		SET rep_value = T.rep_value
		--SELECT S.*, T.*
		FROM #t_Report_Statistics AS S
			INNER JOIN (
				SELECT 
					ind_code = 'total',
					rep_value = count(DISTINCT M.EdoDocumentId) 
				FROM #t_Detail_Main AS M
				UNION
				SELECT 
					ind_code = concat(M.DocumentTypeCode,'_', 'total'),
					rep_value = count(DISTINCT M.EdoDocumentId) 
				FROM #t_Detail_Main AS M
				GROUP BY M.DocumentTypeCode
			) AS T
			ON T.ind_code = S.ind_code

		--Распознано
		UPDATE S 
		SET rep_value = T.rep_value
		--SELECT S.*, T.*
		FROM #t_Report_Statistics AS S
			INNER JOIN (
				SELECT 
					ind_code = 'recog_total',
					rep_value = count(DISTINCT M.EdoDocumentId) 
				FROM #t_Detail_Main AS M
				WHERE M.Recog_Total = 1
				UNION
				SELECT 
					ind_code = concat(M.DocumentTypeCode,'_', 'recog'),
					rep_value = count(DISTINCT M.EdoDocumentId) 
				FROM #t_Detail_Main AS M
				WHERE M.Recog_Total = 1
				GROUP BY M.DocumentTypeCode
			) AS T
			ON T.ind_code = S.ind_code

		--Не распознано
		UPDATE S 
		SET rep_value = T.rep_value
		--SELECT S.*, T.*
		FROM #t_Report_Statistics AS S
			INNER JOIN (
				SELECT 
					ind_code = 'norec_total',
					rep_value = count(DISTINCT M.EdoDocumentId) 
				FROM #t_Detail_Main AS M
				WHERE M.Recog_Total = 0
				UNION
				SELECT 
					ind_code = concat(M.DocumentTypeCode,'_', 'norec'),
					rep_value = count(DISTINCT M.EdoDocumentId) 
				FROM #t_Detail_Main AS M
				WHERE M.Recog_Total = 0
				GROUP BY M.DocumentTypeCode
			) AS T
			ON T.ind_code = S.ind_code

		--расчет %%
		--total
		UPDATE S
		SET rep_value_perc = ''
		FROM #t_Report_Statistics AS S
		WHERE S.ind_code = 'total'

		UPDATE S
		SET rep_value_perc = 
				format(CASE WHEN A.rep_value <> 0 THEN 1.0 * S.rep_value / A.rep_value ELSE 0 END,'P2'),
			rep_value_num_perc = CASE WHEN A.rep_value <> 0 THEN 100.0 * S.rep_value / A.rep_value ELSE 0 END
		--SELECT S.*, A.*, format(CASE WHEN A.rep_value <> 0 THEN 1.0 * S.rep_value / A.rep_value ELSE 0 END,'P2')
		FROM #t_Report_Statistics AS S
			INNER JOIN #t_Report_Statistics AS A
				ON A.ind_code = 'total'
		WHERE S.ind_code LIKE '%total'
			AND S.ind_code <> 'total'

		--Распознано
		UPDATE S
		SET rep_value_perc = 
			format(CASE WHEN A.rep_value <> 0 THEN 1.0 * S.rep_value / A.rep_value ELSE 0 END,'P2'),
			rep_value_num_perc = CASE WHEN A.rep_value <> 0 THEN 100.0 * S.rep_value / A.rep_value ELSE 0 END
		--SELECT S.*, A.*, format(CASE WHEN A.rep_value <> 0 THEN 1.0 * S.rep_value / A.rep_value ELSE 0 END,'P2')
		FROM #t_Report_Statistics AS S
			INNER JOIN #t_Report_Statistics AS A
				ON A.ind_code = 'recog_total'
		WHERE S.ind_code LIKE '%recog%'
			AND S.ind_code <> 'recog_total'

		--Не распознано
		UPDATE S
		SET rep_value_perc = 
			format(CASE WHEN A.rep_value <> 0 THEN 1.0 * S.rep_value / A.rep_value ELSE 0 END,'P2'),
			rep_value_num_perc = CASE WHEN A.rep_value <> 0 THEN 100.0 * S.rep_value / A.rep_value ELSE 0 END
		--SELECT S.*, A.*, format(CASE WHEN A.rep_value <> 0 THEN 1.0 * S.rep_value / A.rep_value ELSE 0 END,'P2')
		FROM #t_Report_Statistics AS S
			INNER JOIN #t_Report_Statistics AS A
				ON A.ind_code = 'norec_total'
		WHERE S.ind_code LIKE '%norec%'
			AND S.ind_code <> 'norec_total'


		--SELECT S.* FROM #t_Report_Statistics AS S
		SELECT 
			I.ind_id,
			I.ind_num,
			I.ind_code,
			I.ind_name,
			I.category,
            S.rep_value,
			S.rep_value_perc,
			S.rep_value_num_perc
		FROM #t_Report_Statistics AS S
			INNER JOIN #t_Indicator AS I
				ON I.ind_code = S.ind_code
		ORDER BY I.ind_id

	END
	--// @Page IN ('Statistics')


	DROP TABLE IF EXISTS #t_Statistics_Fields

	SELECT 
		--A.EdoDocumentId,
		A.DocumentTypeId,
		A.DocumentTypeCode,
		A.DocumentTypeName,
		A.FieldInfo_Code,
		--A.RecogDateTime,
		--RecogDate = cast(A.RecogDateTime AS date),
		--RecogTime = cast(A.RecogDateTime AS time(0)),
		--Recog_Total = iif(A.Equal_Total = A.Count_Fields, cast(1 AS int),  cast(0 AS int))
		Total_Count = A.Count_Fields,
		Recog_Count = A.Equal_Total,
		NoRecog_Count = A.Count_Fields - A.Equal_Total,
		Recog_Percent = A.Equal_Total * 1.0 / A.Count_Fields,
		NoRecog_Percent = (A.Count_Fields - A.Equal_Total) * 1.0 / A.Count_Fields
	INTO #t_Statistics_Fields
	FROM (
		SELECT 
			--D.EdoDocumentId,
			D.DocumentTypeId,
			D.DocumentTypeCode,
			D.DocumentTypeName,
			X.FieldInfo_Code,
			--RecogDateTime = cast(max(D.CreateDate) AS datetime2(0)),
			--Equal_Total = sum(D.Equal),
			--Count_Fields = count(*)
			Equal_Total = sum(D.Equal), --sum(D.Equal * isnull(X.isCount, 0)),
			Count_Fields = count(1) --count(1 * isnull(X.isCount, 0)),
		--select *
		FROM #t_CollectionDocRecognition AS D
			INNER JOIN #t_DocumentType_X_FieldInfo AS X
				ON X.DocumentType_Code = D.DocumentTypeCode
				AND X.FieldInfo_Code = D.DocumentFieldCode
		WHERE 1=1
			--Не выводим, т.к. не реализовали
			AND D.DocumentFieldCode NOT IN (
				'Decision', -- 'Вид решения суда'
				'Birthdate', -- 'дата рождения нового собственника' не выводим
				'Passport' -- 'Серия / № паспорта клиента'
			)
		GROUP BY 
			--D.EdoDocumentId,
			D.DocumentTypeId,
			D.DocumentTypeCode,
			D.DocumentTypeName,
			X.FieldInfo_Code
		) AS A

	--CREATE INDEX ix_DocumentTypeCode ON #t_Statistics_Fields(DocumentTypeCode)

	IF @Page IN ('Statistics_Fields') BEGIN
		SELECT 
			--SF.DocumentTypeId,
			Document_sort_order = D.sort_order,
			SF.DocumentTypeCode,
			[Тип документа] = SF.DocumentTypeName,
			Field_sort_order = F.sort_order,
			SF.FieldInfo_Code,
			[Наименование поля] = F.FieldInfo_Name,
			[Всего, шт.] = SF.Total_Count,
			[Распознано, шт.] = SF.Recog_Count,
			[Не распознано, шт.] = SF.NoRecog_Count,
			[Распознано, %] = SF.Recog_Percent,
			[Не распознано, %] = SF.NoRecog_Percent
		FROM #t_Statistics_Fields AS SF
			INNER JOIN #t_DocumentType_List AS D
				ON D.DocumentType_Code = SF.DocumentTypeCode
			INNER JOIN #t_Fields_List AS F
				ON F.FieldInfo_Code = SF.FieldInfo_Code
		ORDER BY D.sort_order, F.sort_order
	END 
	-- //Statistics_Fields







	IF @isDebug = 1 BEGIN

		DROP TABLE IF EXISTS ##t_DocumentType_List
		SELECT * INTO ##t_DocumentType_List FROM #t_DocumentType_List

		DROP TABLE IF EXISTS ##t_Fields_List
		SELECT * INTO ##t_Fields_List FROM #t_Fields_List

		DROP TABLE IF EXISTS ##t_DocumentType_X_FieldInfo
		SELECT * INTO ##t_DocumentType_X_FieldInfo FROM #t_DocumentType_X_FieldInfo

		DROP TABLE IF EXISTS ##t_Detail_Main
		SELECT * INTO ##t_Detail_Main FROM #t_Detail_Main

		DROP TABLE IF EXISTS ##t_Detail_Recog
		SELECT * INTO ##t_Detail_Recog FROM #t_Detail_Recog

		DROP TABLE IF EXISTS ##t_Statistics_Fields
		SELECT * INTO ##t_Statistics_Fields FROM #t_Statistics_Fields
	END

END TRY
BEGIN CATCH
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
			ROLLBACK;

	SELECT @message = concat(
		'EXEC dbo.Report_CollectionDocRecognition ',
		'@Page=''', @Page, ''', ',
		'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@isDebug=', convert(varchar(10), @isDebug)
	)

	SELECT @eventType = concat(@Page, ' ERROR')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Report_CollectionDocRecognition',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END
