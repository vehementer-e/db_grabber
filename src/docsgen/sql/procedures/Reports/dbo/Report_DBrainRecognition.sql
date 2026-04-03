-- =============================================
-- Author:		А.Никитин
-- Create date: 2023-12-09
-- Description:	DWH-2306 Результаты распознавания Инстолмент, DWH-2307 PDL
-- =============================================
/*
EXEC dbo.Report_DBrainRecognition
	@ProductType = 'Installment'
	,@Page = 'Detail'
	,@dtFrom = '2023-11-01'
	,@dtTo = '2023-12-10'

EXEC dbo.Report_DBrainRecognition
	@ProductType = 'Installment'
	,@Page = 'Detail'
	,@dtFrom = '2023-11-01'
	,@dtTo = '2023-12-10'

*/
CREATE PROC dbo.Report_DBrainRecognition
--declare
	@ProductType varchar(20) = 'Installment'
	,@Page nvarchar(100) = 'Detail'
	,@dtFrom date = null -- '2021-04-01'
	,@dtTo date =  null --'2021-04-26'
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

	IF @ProductType NOT IN ('Installment', 'PDL')
	BEGIN
		;throw 51000, 'Допустимые значения параметра @ProductType: Installment, PDL', 1
	END

	DROP TABLE IF EXISTS #t_DBrainRecognition

	SELECT D.* 
	INTO #t_DBrainRecognition
	FROM dbo.dm_DBrainRecognition AS D
	WHERE 1=1
		AND D.ProductType = @ProductType
		--AND @dt_from <= D.RecogDateTime AND D.RecogDateTime < @dt_to
		AND @dt_from <= D.RequestDateTime AND D.RequestDateTime < @dt_to

	--DWH-39
	/*
	Исключение заявок, прошедших по ветке B тест-кейса без запроса фото 
	бывают случаи когда заявка пошла по этой ветке, но фото паспорта также запросили
	Это можно понять по наличию данных в таблице core.ClientRequestAdditionalPhoto
	*/
	delete d
	from #t_DBrainRecognition as d
		inner join Stg._fedor.core_ClientRequestRealAbCase as c
			on c.ClientRequestId = d.RequestGuid
		inner join Stg._fedor.dictionary_AbCase as b
			on b.Id = c.AbCaseId
			and b.Code = 'bp4557_b' --Исключение фото паспорта и клиента на чеках до 15к при успешном УПРИД (ИНСТ/ПДЛ)
		left join Stg._fedor.core_ClientRequestAdditionalPhoto as p
			on p.ClientRequestId = d.RequestGuid
	where 1=1
		and d.FileType_Code in (
			'passport_main', --Паспорт гражданина РФ: главный разворот, печатный образец
			'passport_registration' --Паспорт гражданина РФ: страница "Место жительства"
		)
		and p.ClientRequestId is null


	DROP TABLE IF EXISTS #t_Detail_Main

	SELECT 
		A.RequestGuid,
		A.RequestNumber,
		A.RequestDateTime,
		RequestDate = cast(A.RequestDateTime AS date),
		RequestTime = cast(A.RequestDateTime AS time(7)),
		A.RequestClientFIO,
		A.RecogDateTime,
		RecogDate = cast(A.RecogDateTime AS date),
		RecogTime = cast(A.RecogDateTime AS time(7)),
		Recog_Total = iif(A.EqualAfterDataControl_Total = A.Count_Fields, cast(1 AS int),  cast(0 AS int)),
		--A.EqualAfterDataControl_Total,
		--A.Count_Fields 
		Loginom_Result = cast(NULL AS varchar(100)) --решение Логином по итогам Call 1.5
	INTO #t_Detail_Main
	FROM (
		SELECT 
			D.RequestGuid,
			D.RequestNumber,
			D.RequestDateTime,
			D.RequestClientFIO,
			D.RecogDateTime,
			EqualAfterDataControl_Total = sum(D.EqualAfterDataControl ),
			Count_Fields = count(*)
		FROM #t_DBrainRecognition AS D
		GROUP BY 
			D.RequestGuid,
			D.RequestNumber,
			D.RequestDateTime,
			D.RequestClientFIO,
			D.RecogDateTime
		) AS A

	CREATE INDEX ix_RequestGuid ON #t_Detail_Main(RequestGuid)


	DROP TABLE IF EXISTS #t_Fields_List
	CREATE TABLE #t_Fields_List(
		sort_order int,
		FieldInfo_Code nvarchar(255),
		FieldInfo_Name nvarchar(255)
	)

	INSERT #t_Fields_List
	(
	    sort_order,
	    FieldInfo_Code,
		FieldInfo_Name
	)
	VALUES
		(1, 'lastName', 'Фамилия'),
		(2, 'firstName', 'Имя'),
		(3, 'secondName', 'Отчество'),
		(4, 'dateOfBirth', 'Дата рождения'),
		(5, 'sex', 'Пол'),
		(6, 'placeOfBirth', 'Место рождения'),
		(7, 'placeOfIssue', 'Кем выдан'),
		(8, 'passportSerialNumber', 'Серия паспорта'),
		(9, 'passportNumber', '№ паспорта'),
		(10, 'dateOfIssue', 'Дата выдачи'),
		(11, 'departmentCode', 'Код подразделения'),
		(12, 'registrationAddress', 'Адрес регистрации'),
		(13, 'dateOfRegistration', 'Дата регистрации')

	--UPDATE F
	--SET F.FieldInfo_Name = FieldInfo.Name
	--FROM #t_Fields_List AS F
	--	INNER JOIN Stg._fedor.dictionary_ClientRequestFieldInfo AS FieldInfo
	--		ON F.FieldInfo_Code = FieldInfo.Code COLLATE Cyrillic_General_CI_AS



	IF @Page = 'Detail' BEGIN

		DROP TABLE IF EXISTS #t_Detail_Recog

		SELECT 
			PivotTable.RequestNumber,
			PivotTable.lastName,
			PivotTable.firstName,
			PivotTable.secondName,
			PivotTable.dateOfBirth,
			PivotTable.sex,
			PivotTable.placeOfBirth,
			PivotTable.placeOfIssue,
			PivotTable.passportSerialNumber,
			PivotTable.passportNumber,
			PivotTable.dateOfIssue,
			PivotTable.departmentCode,
			PivotTable.registrationAddress,
			PivotTable.dateOfRegistration
		INTO #t_Detail_Recog
		FROM  
		(
			SELECT 
				D.RequestNumber,
				D.FieldInfo_Code,
				EqualAfterDataControl = D.EqualAfterDataControl
			FROM #t_DBrainRecognition AS D
		) AS SourceTable  
		PIVOT  
		(  
			max(EqualAfterDataControl)
			FOR FieldInfo_Code IN (
				lastName,
				firstName,
				secondName,
				dateOfBirth,
				sex,
				placeOfBirth,
				placeOfIssue,
				passportSerialNumber,
				passportNumber,
				dateOfIssue,
				departmentCode,
				registrationAddress,
				dateOfRegistration
			)
		) AS PivotTable


		--На call 1,5 возможно только 2 варианта - отказ или одобрение
		UPDATE M1
		SET M1.Loginom_Result = 
			CASE SN.Name
				WHEN 'Отказано' THEN 'Отказ'
				ELSE 'Одобрение'
			END
		FROM (
				SELECT 
					M.RequestGuid,
					CreatedOn_next = min(NX.CreatedOn)
				FROM #t_Detail_Main AS M
					INNER JOIN Stg._fedor.core_ClientRequestHistory AS H
						ON H.IdClientRequest = M.RequestGuid
					INNER JOIN Stg._fedor.dictionary_ClientRequestStatus AS S
						ON S.Id = H.IdClientRequestStatus
					INNER JOIN Stg._fedor.core_ClientRequestHistory AS NX
						ON NX.IdClientRequest = M.RequestGuid
						AND NX.CreatedOn > H.CreatedOn
				WHERE S.Name = 'Верификация Call 1.5'
				GROUP BY M.RequestGuid
			) AS N
			INNER JOIN Stg._fedor.core_ClientRequestHistory AS HN
				ON HN.IdClientRequest = N.RequestGuid
				AND HN.CreatedOn = N.CreatedOn_next
			INNER JOIN Stg._fedor.dictionary_ClientRequestStatus AS SN
				ON SN.Id = HN.IdClientRequestStatus
			INNER JOIN #t_Detail_Main AS M1
				ON M1.RequestGuid = N.RequestGuid



		SELECT 
			M.RequestDateTime,
			M.RequestDate,
			M.RequestTime,
			--
			M.RecogDateTime,
			M.RecogDate,
			M.RecogTime,
			--M.RequestGuid,
			M.RequestNumber,
			M.RequestClientFIO,
			----
			R.lastName,
			R.firstName,
			R.secondName,
			R.dateOfBirth,
			R.sex,
			R.placeOfBirth,
			R.placeOfIssue,
			R.passportSerialNumber,
			R.passportNumber,
			R.dateOfIssue,
			R.departmentCode,
			R.registrationAddress,
			R.dateOfRegistration,
			---
			M.Recog_Total,
			M.Loginom_Result
		FROM #t_Detail_Main AS M
			LEFT JOIN #t_Detail_Recog AS R
				ON R.RequestNumber = M.RequestNumber
		ORDER BY M.RecogDateTime

		RETURN 0
	END
	--// 'Detail'



	--КД. % распознавания по полям за месяц
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
				FROM #t_DBrainRecognition AS R
				GROUP BY
					cast(format(R.RecogDateTime, 'yyyyMM01') AS date),
					R.FieldInfo_Code
			) AS A
				ON A.FieldInfo_Code = L.FieldInfo_Code
		ORDER BY A.RecogMonth, L.sort_order
		
	END
	--// 'Fields'


	DROP TABLE IF EXISTS #t_Indicator
	CREATE TABLE #t_Indicator
	(
		ind_id int,
		ind_num varchar(10),
		ind_code varchar(100),
		ind_name varchar(100),
		PRIMARY KEY(ind_code)
	)

	INSERT #t_Indicator(ind_id, ind_num, ind_code, ind_name)
	VALUES 
	(1, '1', 'total', 'Общее количество заведенных заявок'),
	(2, '2', 'call1', 'Общее количество заявок, одобренных на Call1'),
	(3, '3', 'call1_recog', 'Общее количество заявок, отправленных на распознавание, из них:'),
	(4, '3.1.', 'call1_recog_yes', 'Распознано'),
	(5, '3.2.', 'call1_recog_no', 'Не распознано'),
	(6, '4', 'kd_recog', 'Общее количество заявок, поступивших на КД, из них:'),
	(7, '4.1.', 'kd_recog_yes', 'Распознано'),
	(8, '4.2.', 'kd_recog_no', 'Не распознано')


	DROP TABLE IF EXISTS #t_Report_Daily
	CREATE TABLE #t_Report_Daily
	(
		ind_code varchar(100) NOT NULL,
		rep_date date NOT NULL,
		rep_value int NOT NULL
	)

	INSERT #t_Report_Daily
	(
	    ind_code,
	    rep_date,
	    rep_value
	)
	SELECT 
		I.ind_code,
	    rep_date = C.DT,
	    rep_value = 0
	FROM #t_Indicator AS I
		INNER JOIN dwh2.Dictionary.calendar AS C
			ON @dt_from <= C.DT AND C.DT < @dt_to


	DROP TABLE IF EXISTS #t_calendar_month
	SELECT DISTINCT 
		C.Month_Value,
		C.month_name,
		C.year_name
	INTO #t_calendar_month
	FROM dwh2.Dictionary.calendar AS C
	WHERE @dt_from <= C.DT AND C.DT < @dt_to


	DROP TABLE IF EXISTS #t_Report_Monthly
	CREATE TABLE #t_Report_Monthly
	(
		ind_code varchar(100) NOT NULL,
		rep_date date NOT NULL,
		rep_value int NOT NULL,
		rep_value_perc varchar(20) NOT NULL
	)

	INSERT #t_Report_Monthly
	(
	    ind_code,
	    rep_date,
	    rep_value,
		rep_value_perc
	)
	SELECT 
		I.ind_code,
	    rep_date = M.Month_Value,
	    rep_value = 0,
		rep_value_perc = '0.0%'
	FROM #t_Indicator AS I
		INNER JOIN #t_calendar_month AS M
			ON 1=1


	DROP TABLE IF EXISTS #t_ClientRequest
	CREATE TABLE #t_ClientRequest(
		Id uniqueidentifier,
		RequestDateTime datetime2(7),
		RequestDate date,
		Number nvarchar(255)
	)

	DROP TABLE IF EXISTS #t_ClientRequest_Approve_Call1
	CREATE TABLE #t_ClientRequest_Approve_Call1(
		Id uniqueidentifier,
		RequestDateTime datetime2(7),
		RequestDate date,
		Number nvarchar(255)
	)

	DROP TABLE IF EXISTS #t_ClientRequest_Approve_ControlData
	CREATE TABLE #t_ClientRequest_ControlData(
		Id uniqueidentifier,
		RequestDateTime datetime2(7),
		RequestDate date,
		Number nvarchar(255),
		Recog_Total int
	)

	IF @Page IN ('Daily', 'Monthly') BEGIN

		INSERT #t_ClientRequest(Id, RequestDateTime, RequestDate, Number)
		SELECT 
			CR.Id,
			RequestDateTime = dateadd(HOUR, 3, CR.CreatedOn),
			RequestDate = cast(dateadd(HOUR, 3, CR.CreatedOn) AS date),
			CR.Number
		FROM Stg._fedor.core_ClientRequest AS CR
			INNER JOIN Stg._fedor.dictionary_ProductType AS T
				ON CR.ProductTypeId = T.Id
		WHERE 1=1
			AND @dt_from <= dateadd(HOUR, 3, CR.CreatedOn) AND dateadd(HOUR, 3, CR.CreatedOn) < @dt_to
			AND T.Code = @ProductType

		CREATE INDEX ix_Id ON #t_ClientRequest(Id)


		--1	Общее количество заведенных заявок
		--Расчетное, число, кол-во заведенных заявок по продукту за текущий месяц
		UPDATE D
		SET D.rep_value = T.total
		FROM #t_Report_Daily AS D
			INNER JOIN (
				SELECT 
					R.RequestDate,
					total = count(DISTINCT R.Number)
				FROM #t_ClientRequest AS R
				GROUP BY R.RequestDate
			) AS T
			ON D.ind_code = 'total' --'Общее количество заведенных заявок'
			AND D.rep_date = T.RequestDate

		--2. Общее количество заявок, одобренных на Call1
		/*
		статус "Верификация КЦ" и следующий статус = "Предварительное одобрение"
		*/
		INSERT #t_ClientRequest_Approve_Call1(Id, RequestDateTime, RequestDate, Number)
		SELECT 
			R1.Id,
			R1.RequestDateTime,
			R1.RequestDate,
			R1.Number
		FROM (
				SELECT 
					R.Id,
					CreatedOn_prev = max(PRE.CreatedOn)
				FROM #t_ClientRequest AS R
					INNER JOIN Stg._fedor.core_ClientRequestHistory AS H
						ON H.IdClientRequest = R.Id
					INNER JOIN Stg._fedor.dictionary_ClientRequestStatus AS S
						ON S.Id = H.IdClientRequestStatus
					INNER JOIN Stg._fedor.core_ClientRequestHistory AS PRE
						ON PRE.IdClientRequest = R.Id
						AND PRE.CreatedOn < H.CreatedOn
				WHERE S.Code = 'PreliminaryApprove' --Предварительное одобрение
				GROUP BY R.Id
			) AS P
			INNER JOIN Stg._fedor.core_ClientRequestHistory AS HP
				ON HP.IdClientRequest = P.Id
				AND HP.CreatedOn = P.CreatedOn_prev
			INNER JOIN Stg._fedor.dictionary_ClientRequestStatus AS SP
				ON SP.Id = HP.IdClientRequestStatus
			INNER JOIN #t_ClientRequest AS R1
				ON R1.Id = P.Id
		--WHERE SP.Code = 'WaitDocumentSigned' --Ожидание подписи документов EDO
		WHERE SP.Code = 'VerificationCallCenter' --Верификация КЦ

		CREATE INDEX ix_Id ON #t_ClientRequest_Approve_Call1(Id)

		UPDATE D
		SET D.rep_value = T.total
		FROM #t_Report_Daily AS D
			INNER JOIN (
				SELECT 
					R.RequestDate,
					total = count(DISTINCT R.Number)
				FROM #t_ClientRequest_Approve_Call1 AS R
				GROUP BY R.RequestDate
			) AS T
			ON D.ind_code = 'call1' -- Общее количество заявок, одобренных на Call1
			AND D.rep_date = T.RequestDate

		UPDATE D
		SET D.rep_value = T.total
		FROM #t_Report_Daily AS D
			INNER JOIN (
				SELECT 
					R.RequestDate,
					total = count(DISTINCT R.Number)
				FROM #t_ClientRequest_Approve_Call1 AS R
					--отправленные на распознавание
					INNER JOIN #t_Detail_Main AS M
						ON M.RequestGuid = R.Id
				GROUP BY R.RequestDate
			) AS T
			ON D.ind_code = 'call1_recog' -- Общее количество заявок, одобренных на Call1, отправленных на распознавание
			AND D.rep_date = T.RequestDate

		UPDATE D
		SET D.rep_value = T.total
		FROM #t_Report_Daily AS D
			INNER JOIN (
				SELECT 
					R.RequestDate,
					total = count(DISTINCT R.Number)
				FROM #t_ClientRequest_Approve_Call1 AS R
					--отправленные на распознавание
					INNER JOIN #t_Detail_Main AS M
						ON M.RequestGuid = R.Id
				WHERE M.Recog_Total = 1
				GROUP BY R.RequestDate
			) AS T
			-- Общее количество заявок, одобренных на Call1, отправленных на распознавание, Распознано
			ON D.ind_code = 'call1_recog_yes'
			AND D.rep_date = T.RequestDate

		UPDATE D
		SET D.rep_value = T.total
		FROM #t_Report_Daily AS D
			INNER JOIN (
				SELECT 
					R.RequestDate,
					total = count(DISTINCT R.Number)
				FROM #t_ClientRequest_Approve_Call1 AS R
					--отправленные на распознавание
					INNER JOIN #t_Detail_Main AS M
						ON M.RequestGuid = R.Id
				WHERE M.Recog_Total = 0
				GROUP BY R.RequestDate
			) AS T
			-- Общее количество заявок, одобренных на Call1, отправленных на распознавание, Не распознано
			ON D.ind_code = 'call1_recog_no'
			AND D.rep_date = T.RequestDate

		--4. Общее количество заявок, поступивших на КД, из них:
		/*
		расчетное, число, кол-во заявок по продукту Инстолмент, 
		получивших одобрение на Доп. Call Логином по проверке результатов распознавания, 
		которые были отправлены на распознавание
		*/
		--Общее кол. заявок со статусом - "Контроль данных"
		INSERT #t_ClientRequest_ControlData(Id, RequestDateTime, RequestDate, Number, Recog_Total)
		SELECT 
			R.Id,
			R.RequestDateTime,
			R.RequestDate,
			R.Number,
			M.Recog_Total
		FROM #t_ClientRequest AS R
			INNER JOIN Stg._fedor.core_ClientRequestHistory AS H
				ON H.IdClientRequest = R.Id
			INNER JOIN Stg._fedor.dictionary_ClientRequestStatus AS S
				ON S.Id = H.IdClientRequestStatus
			--отправленные на распознавание
			INNER JOIN #t_Detail_Main AS M
				ON M.RequestGuid = R.Id
		WHERE S.Code = 'ControlData' --Контроль данных

		--CREATE INDEX ix_Id ON #t_ClientRequest_ControlData(Id)

		--IF @isDebug = 1 BEGIN
		--	SELECT TOP 100 *
		--	FROM #t_ClientRequest_ControlData AS A 
		--	ORDER BY A.Number

		--	RETURN 0
		--END

		UPDATE D
		SET D.rep_value = T.total
		FROM #t_Report_Daily AS D
			INNER JOIN (
				SELECT 
					R.RequestDate,
					total = count(DISTINCT R.Number)
				FROM #t_ClientRequest_ControlData AS R
				GROUP BY R.RequestDate
			) AS T
			ON D.ind_code = 'kd_recog' --Общее количество заявок, поступивших на КД
			AND D.rep_date = T.RequestDate
		
		UPDATE D
		SET D.rep_value = T.total
		FROM #t_Report_Daily AS D
			INNER JOIN (
				SELECT 
					R.RequestDate,
					total = count(DISTINCT R.Number)
				FROM #t_ClientRequest_ControlData AS R
				WHERE R.Recog_Total = 1
				GROUP BY R.RequestDate
			) AS T
			ON D.ind_code = 'kd_recog_yes' --Общее количество заявок, поступивших на КД, Распознано
			AND D.rep_date = T.RequestDate

		UPDATE D
		SET D.rep_value = T.total
		FROM #t_Report_Daily AS D
			INNER JOIN (
				SELECT 
					R.RequestDate,
					total = count(DISTINCT R.Number)
				FROM #t_ClientRequest_ControlData AS R
				WHERE R.Recog_Total = 0
				GROUP BY R.RequestDate
			) AS T
			ON D.ind_code = 'kd_recog_no' --Общее количество заявок, поступивших на КД, Не распознано
			AND D.rep_date = T.RequestDate

	END


	--КД. Общий отчет в разбивке по дням тек.месяца
	IF @Page = 'Daily' BEGIN



		SELECT 
			I.ind_id,
			I.ind_num,
			R.ind_code,
			I.ind_name,
            R.rep_date,
			rep_date_month = concat(C.id_day_of_month, ' ', C.month_name1),
            R.rep_value 
		FROM #t_Report_Daily AS R
			INNER JOIN #t_Indicator AS I
				ON I.ind_code = R.ind_code
			INNER JOIN dwh2.Dictionary.calendar AS C
				ON C.DT = R.rep_date
		ORDER BY R.rep_date, I.ind_id
	END
    --// Daily


	-- КД. Общий отчет в разбивке по месяцам
	IF @Page = 'Monthly' BEGIN

		UPDATE M
		SET M.rep_value = T.rep_value_1
		FROM #t_Report_Monthly AS M
			INNER JOIN (
				SELECT 
					rep_date_1 = cast(format(D.rep_date, 'yyyyMM01') AS date),
					D.ind_code,
					rep_value_1 = sum(D.rep_value)
				FROM #t_Report_Daily AS D
				--WHERE D.ind_code IN (
				--	'total', --'Общее количество заведенных заявок'
				--	'call1', -- Общее количество заявок, одобренных на Call1
				--	'kd_recog' --Общее количество заявок, поступивших на КД
				--)
				GROUP BY 
					cast(format(D.rep_date, 'yyyyMM01') AS date),
					D.ind_code
			) AS T
			ON T.ind_code = M.ind_code
			AND T.rep_date_1 = M.rep_date

		--расчет %%
		UPDATE M
		SET M.rep_value_perc = ''
		FROM #t_Report_Monthly AS M
		WHERE M.ind_code = 'total'

		--call1	Общее количество заявок, одобренных на Call1
		--% = Общее количество заявок, одобренных на Call1 / Общее количество заведенных заявок*100%
		UPDATE M
		SET M.rep_value_perc = 
			format(CASE WHEN A.rep_value <> 0 THEN  1.0*M.rep_value / A.rep_value ELSE 0 END,'P2')
		FROM #t_Report_Monthly AS M
			INNER JOIN #t_Report_Monthly AS A
				ON A.rep_date = M.rep_date
				AND A.ind_code = 'total'
		WHERE M.ind_code = 'call1' --Общее количество заявок, одобренных на Call1

		--call1_recog	Общее количество заявок, отправленных на распознавание, из них:
		--% = Общее количество заявок, отправленных на распознавание / Общее количество заявок, одобренных на Call1*100%
		UPDATE M
		SET M.rep_value_perc = 
			format(CASE WHEN A.rep_value <> 0 THEN 1.0* M.rep_value / A.rep_value ELSE 0 END,'P2')
		FROM #t_Report_Monthly AS M
			INNER JOIN #t_Report_Monthly AS A
				ON A.rep_date = M.rep_date
				AND A.ind_code = 'call1'
		WHERE M.ind_code = 'call1_recog' --Общее количество заявок, одобренных на Call1, отправленных на распознавание

		--call1_recog_yes	Распознано
		--% = Кол-во распознанных / Общее количество заявок, отправленных на распознавание*100%
		UPDATE M
		SET M.rep_value_perc = 
			format(CASE WHEN A.rep_value <> 0 THEN  1.0*M.rep_value / A.rep_value ELSE 0 END,'P2')
		FROM #t_Report_Monthly AS M
			INNER JOIN #t_Report_Monthly AS A
				ON A.rep_date = M.rep_date
				AND A.ind_code = 'call1_recog'
		WHERE M.ind_code = 'call1_recog_yes' --Общее количество заявок, одобренных на Call1, отправленных на распознавание, Распознано

		--call1_recog_no	Не распознано
		--% = Кол-во НЕраспознанных / Общее количество заявок, отправленных на распознавание*100%
		UPDATE M
		SET M.rep_value_perc = 
			format(CASE WHEN A.rep_value <> 0 THEN  1.0*M.rep_value / A.rep_value ELSE 0 END,'P2')
		FROM #t_Report_Monthly AS M
			INNER JOIN #t_Report_Monthly AS A
				ON A.rep_date = M.rep_date
				AND A.ind_code = 'call1_recog'
		WHERE M.ind_code = 'call1_recog_no' --Общее количество заявок, одобренных на Call1, отправленных на распознавание, Не распознано

		--kd_recog	Общее количество заявок, поступивших на КД, из них:
		--% = Общее количество заявок, поступивших на КД / Общее количество заявок, отправленных на распознавание*100%
		UPDATE M
		SET M.rep_value_perc = 
			format(CASE WHEN A.rep_value <> 0 THEN  1.0*M.rep_value / A.rep_value ELSE 0 END,'P2')
		FROM #t_Report_Monthly AS M
			INNER JOIN #t_Report_Monthly AS A
				ON A.rep_date = M.rep_date
				AND A.ind_code = 'call1_recog'
		WHERE M.ind_code = 'kd_recog' --Общее количество заявок, поступивших на КД, отправленных на распознавание
		
		--kd_recog_yes	Распознано
		--% = Кол-во распознанных / Общее количество заявок, поступивших на КД*100%
		UPDATE M
		SET M.rep_value_perc = 
			format(CASE WHEN A.rep_value <> 0 THEN 1.0* M.rep_value / A.rep_value ELSE 0 END,'P2')
		FROM #t_Report_Monthly AS M
			INNER JOIN #t_Report_Monthly AS A
				ON A.rep_date = M.rep_date
				AND A.ind_code = 'kd_recog'
		WHERE M.ind_code = 'kd_recog_yes' --Общее количество заявок, поступивших на КД, отправленных на распознавание, Распознано

		--kd_recog_no	Не распознано
		--% = Кол-во НЕраспознанных / Общее количество заявок, поступивших на КД*100%
		UPDATE M
		SET M.rep_value_perc = 
			format(CASE WHEN A.rep_value <> 0 THEN  1.0* M.rep_value / A.rep_value ELSE 0 END,'P2')
		FROM #t_Report_Monthly AS M
			INNER JOIN #t_Report_Monthly AS A
				ON A.rep_date = M.rep_date
				AND A.ind_code = 'kd_recog'
		WHERE M.ind_code = 'kd_recog_no' --Общее количество заявок, поступивших на КД, отправленных на распознавание, Не распознано


		SELECT 
			I.ind_id,
			I.ind_num,
			R.ind_code,
			I.ind_name,
            R.rep_date,
			rep_date_month = concat(M.month_name, ' ', M.year_name),
            R.rep_value,
			R.rep_value_perc
		FROM #t_Report_Monthly AS R
			INNER JOIN #t_Indicator AS I
				ON I.ind_code = R.ind_code
			INNER JOIN #t_calendar_month AS M
				ON M.Month_Value = R.rep_date
		ORDER BY R.rep_date, I.ind_id
	END
    --// Monthly

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Detail_Main
		SELECT * INTO ##t_Detail_Main FROM #t_Detail_Main

		DROP TABLE IF EXISTS ##t_ClientRequest_Approve_Call1
		SELECT * INTO ##t_ClientRequest_Approve_Call1 FROM #t_ClientRequest_Approve_Call1
	END

END TRY
BEGIN CATCH
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
			ROLLBACK;

	SELECT @message = concat(
		'EXEC dbo.Report_DBrainRecognition ',
		'@Page=''', @Page, ''', ',
		'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@isDebug=', convert(varchar(10), @isDebug)
	)

	SELECT @eventType = concat(@Page, ' ERROR')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Report_DBrainRecognition',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END
