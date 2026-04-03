-- =============================================
-- Author:		А.Никитин
-- Create date: 2024-01-17
-- Description:	DWH-2411 Реализовать отчет по авто отказам от сервиса Кобальт
-- =============================================
/*

*/
CREATE   PROC dbo.Report_CobaltData
--declare
	@ProductType_Code varchar(20) = NULL --'installment',
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

	--IF @ProductType NOT IN ('Installment', 'PDL')
	--BEGIN
	--	;throw 51000, 'Допустимые значения параметра @ProductType: Installment, PDL', 1
	--END

	DROP TABLE IF EXISTS #t_CobaltData

	SELECT D.* 
	INTO #t_CobaltData
	FROM dbo.dm_CobaltData AS D
	WHERE 1=1
		AND @dt_from <= D.RequestDateTime AND D.RequestDateTime < @dt_to


	IF @Page = 'Detail' BEGIN

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
			D.CobaltStatus_Name,
			D.RequestedAmount
			--D.IsBankFraud,
			--D.IsMicrofinanceFraud,
			--D.IsMoneyLaundering,
			--D.IsShopThief,
			--D.IsInsuranceFraud,
			--D.IsCargoThief
		FROM #t_CobaltData AS D
		ORDER BY D.RequestDateTime
		--ORDER BY D.CobaltStatus_DateTime

		RETURN 0
	END
	--// 'Detail'



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
		(1, '1', 'BankFraud', 'Банковское мошенничество', 1),
		(2, '2', 'MicrofinanceFraud', 'Микрофинансовое мошенничество', 1),
		(3, '3', 'Fraud', 'Мошенник', 1),
		(4, '4', 'InsuranceFraud', 'Страховое мошенничество', 1),
		(5, '5', 'MoneyLaundering', 'Отмывание денег', 1),
		(6, '6', 'CargoThief', 'Мошенничество с грузами', 1),
		(7, '7', 'ShopThief', 'Магазинный вор', 1),

		(8, '7.1', 'TotalReject', 'всего автоматических отказов', 0),
		(9, '7.2', 'ControlData', 'всего уникальных поступивших на КД заявок', 0),
		(10, '8', 'RejectPercent_ControlData', '% автоматических отказов от всего уникальных поступивших на КД заявок', 1)


	DROP TABLE IF EXISTS #t_Report_Daily
	CREATE TABLE #t_Report_Daily
	(
		product_type_code nvarchar(50) NOT NULL, --Код Типа продукта
		ind_code varchar(100) NOT NULL,
		rep_date date NOT NULL,
		ind_value numeric(12, 2) NOT NULL,
		rep_value varchar(20) NOT NULL
	)
	
	INSERT #t_Report_Daily
	(
		product_type_code,
	    ind_code,
	    rep_date,
		ind_value,
	    rep_value
	)
	SELECT 
		product_type_code = T.Code,
		I.ind_code,
	    rep_date = C.DT,
		ind_value = 0,
	    rep_value = '0'
	FROM #t_Indicator AS I
		INNER JOIN dwh2.Dictionary.calendar AS C
			ON @dt_from <= C.DT AND C.DT < @dt_to
		INNER JOIN Stg._fedor.dictionary_ProductType AS T
			ON 1=1


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
		product_type_code nvarchar(50) NOT NULL, --Код Типа продукта
		ind_code varchar(100) NOT NULL,
		rep_date date NOT NULL,
		ind_value numeric(12, 2) NOT NULL,
		rep_value varchar(20) NOT NULL
		--rep_value_perc varchar(20) NULL
	)

	INSERT #t_Report_Monthly
	(
		product_type_code,
	    ind_code,
	    rep_date,
		ind_value,
	    rep_value
	)
	SELECT 
		product_type_code = T.Code,
		I.ind_code,
	    rep_date = M.Month_Value,
		ind_value = 0,
	    rep_value = '0'
	FROM #t_Indicator AS I
		INNER JOIN #t_calendar_month AS M
			ON 1=1
		INNER JOIN Stg._fedor.dictionary_ProductType AS T
			ON 1=1


	DROP TABLE IF EXISTS #t_ClientRequest_Approve_ControlData
	CREATE TABLE #t_ClientRequest_ControlData(
		ProductType_Code nvarchar(50),
		RequestGuid uniqueidentifier,
		RequestNumber nvarchar(255),
		RequestStatus_DateTime datetime2(7),
		RequestStatus_Date date
	)

	IF @Page IN ('Daily', 'Monthly') BEGIN
		--Общее количество заявок, поступивших на КД

		--Общее кол. заявок со статусом - "Контроль данных"
		INSERT #t_ClientRequest_ControlData(
			ProductType_Code,
			RequestGuid, 
			RequestNumber,
			RequestStatus_DateTime,
			RequestStatus_Date
		)
		SELECT 
			ProductType_Code = T.Code,
			RequestGuid = CR.Id,
			RequestNumber = CR.Number,
			RequestStatus_DateTime = min(dateadd(HOUR, 3, H.CreatedOn)),
			RequestStatus_Date = min(cast(dateadd(HOUR, 3, H.CreatedOn) AS date))
		FROM Stg._fedor.core_ClientRequest AS CR
			INNER JOIN Stg._fedor.dictionary_ProductType AS T
				ON CR.ProductTypeId = T.Id
			INNER JOIN Stg._fedor.core_ClientRequestHistory AS H
				ON H.IdClientRequest = CR.Id
			INNER JOIN Stg._fedor.dictionary_ClientRequestStatus AS S
				ON S.Id = H.IdClientRequestStatus
		WHERE S.Code = 'ControlData' --Контроль данных
			AND @dt_from <= dateadd(HOUR, 3, H.CreatedOn) AND dateadd(HOUR, 3, H.CreatedOn) < @dt_to
		GROUP BY T.Code, CR.Id, CR.Number

		CREATE INDEX ix_Id ON #t_ClientRequest_ControlData(RequestGuid)

		--IF @isDebug = 1 BEGIN
		--	SELECT TOP 100 *
		--	FROM #t_ClientRequest_ControlData AS A 
		--	ORDER BY A.RequestNumber

		--	--RETURN 0
		--END

		--всего уникальных поступивших на КД заявок
		UPDATE D
		SET D.ind_value = T.total,
			D.rep_value = format(T.total,'0')
		FROM #t_Report_Daily AS D
			INNER JOIN (
				SELECT 
					R.ProductType_Code,
					R.RequestStatus_Date,
					total = count(DISTINCT R.RequestNumber)
				FROM #t_ClientRequest_ControlData AS R
				GROUP BY R.ProductType_Code, R.RequestStatus_Date
			) AS T
			ON D.ind_code = 'ControlData' --всего уникальных поступивших на КД заявок
			AND D.product_type_code = T.ProductType_Code
			AND D.rep_date = T.RequestStatus_Date

		-- отказы
		UPDATE D
		SET D.ind_value = T.total,
			D.rep_value = format(T.total,'0')
		FROM #t_Report_Daily AS D
			INNER JOIN (
				SELECT 
					C.ProductType_Code,
					CobaltStatus_Date = cast(C.CobaltStatus_DateTime AS date),
					C.CobaltStatus_Code,
					total = count(DISTINCT C.RequestNumber)
				FROM #t_CobaltData AS C
				GROUP BY 
					C.ProductType_Code,
					cast(C.CobaltStatus_DateTime AS date),
					C.CobaltStatus_Code
			) AS T
			ON D.ind_code = T.CobaltStatus_Code --
			AND D.product_type_code = T.ProductType_Code
			AND D.rep_date = T.CobaltStatus_Date

		-- всего автоматических отказов
		UPDATE D
		SET D.ind_value = T.total,
			D.rep_value = format(T.total,'0')
		FROM #t_Report_Daily AS D
			INNER JOIN (
				SELECT 
					C.ProductType_Code,
					CobaltStatus_Date = cast(C.CobaltStatus_DateTime AS date),
					total = count(DISTINCT C.RequestNumber)
				FROM #t_CobaltData AS C
				GROUP BY 
					C.ProductType_Code,
					cast(C.CobaltStatus_DateTime AS date)
			) AS T
			ON D.ind_code = 'TotalReject' -- всего автоматических отказов
			AND D.product_type_code = T.ProductType_Code
			AND D.rep_date = T.CobaltStatus_Date
	END
	--// 'Daily', 'Monthly'


	IF @Page = 'Daily' BEGIN
		--% автоматических отказов от всего уникальных поступивших на КД заявок
		UPDATE M
		SET M.ind_value = iif(B.ind_value <> 0, A.ind_value / B.ind_value, 0),
			M.rep_value = format(iif(B.ind_value <> 0, A.ind_value / B.ind_value, 0), 'P1')
		FROM #t_Report_Daily AS M
			INNER JOIN #t_Report_Daily AS A
				ON A.product_type_code = M.product_type_code
				AND A.rep_date = M.rep_date
				AND A.ind_code = 'TotalReject' --всего автоматических отказов
			INNER JOIN #t_Report_Daily AS B
				ON B.product_type_code = M.product_type_code
				AND B.rep_date = M.rep_date
				AND B.ind_code = 'ControlData' --всего уникальных поступивших на КД заявок
		WHERE M.ind_code = 'RejectPercent_ControlData' --% автоматических отказов от всего уникальных поступивших на КД заявок

		SELECT 
			R.product_type_code,
			I.ind_id,
			I.ind_num,
			R.ind_code,
			I.ind_name,
            R.rep_date,
			rep_date_month = concat(C.id_day_of_month, ' ', C.month_name1),
			R.ind_value,
            R.rep_value 
		FROM #t_Report_Daily AS R
			INNER JOIN #t_Indicator AS I
				ON I.ind_code = R.ind_code
				AND (I.is_visible = 1 OR @isDebug = 1)
			INNER JOIN dwh2.Dictionary.calendar AS C
				ON C.DT = R.rep_date
		WHERE 1=1
			AND R.product_type_code = @ProductType_Code
		ORDER BY R.rep_date, I.ind_id
	END
    --// Daily

	IF @Page = 'Monthly' BEGIN

		-- суммирование показателей за месяц
		UPDATE M
		SET M.ind_value = T.ind_value_1,
			M.rep_value = format(T.ind_value_1, '0')
		FROM #t_Report_Monthly AS M
			INNER JOIN (
				SELECT 
					D.product_type_code,
					rep_date_1 = cast(format(D.rep_date, 'yyyyMM01') AS date),
					D.ind_code,
					ind_value_1 = sum(D.ind_value)
				FROM #t_Report_Daily AS D
				WHERE D.ind_code NOT IN (
						'RejectPercent_ControlData' --% автоматических отказов от всего уникальных поступивших на КД заявок
					)
				GROUP BY 
					D.product_type_code,
					cast(format(D.rep_date, 'yyyyMM01') AS date),
					D.ind_code
			) AS T
			ON T.product_type_code = M.product_type_code
			AND T.rep_date_1 = M.rep_date
			AND T.ind_code = M.ind_code


		--% автоматических отказов от всего уникальных поступивших на КД заявок
		UPDATE M
		SET M.ind_value = iif(B.ind_value <> 0, A.ind_value / B.ind_value, 0),
			M.rep_value = format(iif(B.ind_value <> 0, A.ind_value / B.ind_value, 0), 'P1')
		FROM #t_Report_Monthly AS M
			INNER JOIN #t_Report_Monthly AS A
				ON A.product_type_code = M.product_type_code
				AND A.rep_date = M.rep_date
				AND A.ind_code = 'TotalReject' --всего автоматических отказов
			INNER JOIN #t_Report_Monthly AS B
				ON B.product_type_code = M.product_type_code
				AND B.rep_date = M.rep_date
				AND B.ind_code = 'ControlData' --всего уникальных поступивших на КД заявок
		WHERE M.ind_code = 'RejectPercent_ControlData' --% автоматических отказов от всего уникальных поступивших на КД заявок


		SELECT 
			R.product_type_code,
			I.ind_id,
			I.ind_num,
			R.ind_code,
			I.ind_name,
            R.rep_date,
			rep_date_month = concat(M.month_name, ' ', M.year_name),
			R.ind_value,
            R.rep_value
			--R.rep_value_perc
		FROM #t_Report_Monthly AS R
			INNER JOIN #t_Indicator AS I
				ON I.ind_code = R.ind_code
				AND (I.is_visible = 1 OR @isDebug = 1)
			INNER JOIN #t_calendar_month AS M
				ON M.Month_Value = R.rep_date
		WHERE 1=1
			AND R.product_type_code = @ProductType_Code
		ORDER BY R.rep_date, I.ind_id
	END
    --// Monthly

END TRY
BEGIN CATCH
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
			ROLLBACK;

	SELECT @message = concat(
		'EXEC dbo.Report_CobaltData ',
		'@Page=''', @Page, ''', ',
		'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@isDebug=', convert(varchar(10), @isDebug)
	)

	SELECT @eventType = concat(@Page, ' ERROR')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Report_CobaltData',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END