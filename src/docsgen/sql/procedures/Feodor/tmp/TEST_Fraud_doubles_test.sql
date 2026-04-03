-- =======================================================
-- Create: 18.08.2022. А.Никитин
-- Description:	нагрузочное тестирование новой версии поиска дублей заявок
-- dbo.Fraud_doubles_test
-- =======================================================
CREATE   PROC tmp.TEST_Fraud_doubles_test
	@Debug int = 1,
	@Count int = 10
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @ClientRequestId uniqueidentifier
	DECLARE @Start_Date datetime, @End_Date datetime, @Row_Count int
	DECLARE @Process_Start_Date datetime = getdate() -- начало процесса (играет роль id процесса)

	DROP TABLE IF EXISTS #t_ClientRequestId
	CREATE TABLE #t_ClientRequestId
	(
		ClientRequestId uniqueidentifier
		--Row_Count int,
		--Duration_Sec int,
		--Start_Date datetime,
		--End_Date datetime
	)

	DROP TABLE IF EXISTS #t_ResultTable
	CREATE TABLE #t_ResultTable( searchRule                    nvarchar(100)
	,                           ClientRequestId               uniqueidentifier
	,                           OriginalField                 nvarchar(150)
	,                           DuplicateField                nvarchar(150)
	,                           FieldValue                    nvarchar(4000)
	-- 11-08-2020
	,                           ClientName                    nvarchar(304)
	,                           ClientBirthDay                date
	,                           ClientRequestNumber           nvarchar(255)
	,                           ClientRequestCreatedOn        datetime
	--BP-1632
	,							StatusName nvarchar(255)
	)

	--var.1
	INSERT #t_ClientRequestId(ClientRequestId)
	SELECT TOP(@Count)
		A.ClientRequestId
	FROM dbo.dm_FeodorRequests AS A
		INNER JOIN dbo.dm_FeodorRequests_test AS B
			ON B.ClientRequestId = A.ClientRequestId
			AND B.TableSource = A.TableSource
	GROUP BY A.ClientRequestId
	ORDER BY hashbytes(
				'SHA2_256', 
				concat(
					convert(varchar(36), A.ClientRequestId),
					'|',
					convert(varchar(23),getdate(),121)
				)
			)

	--var.2
	--INSERT #t_ClientRequestId(ClientRequestId)
	--SELECT DISTINCT X.ClientRequestId
	--FROM (
	--	SELECT TOP(@Count) A.ClientRequestId
	--	--SELECT TOP(100) A.ClientRequestId
	--	FROM dbo.dm_FeodorRequests AS A
	--		INNER JOIN dbo.dm_FeodorRequests_test AS B
	--			ON B.ClientRequestId = A.ClientRequestId
	--			AND B.TableSource = A.TableSource
	--	ORDER BY B.LoadDate DESC
	--	) AS X
	--GROUP BY X.ClientRequestId


	DECLARE Cur_ClientRequestId CURSOR FOR
	SELECT R.ClientRequestId
	FROM #t_ClientRequestId AS R
	ORDER BY R.ClientRequestId

	OPEN Cur_ClientRequestId
	FETCH NEXT FROM Cur_ClientRequestId
	INTO @ClientRequestId

	WHILE @@FETCH_STATUS = 0  
	BEGIN  
		SELECT @Start_Date = getdate(), @Row_Count = 0
		TRUNCATE TABLE #t_ResultTable

		INSERT #t_ResultTable
		EXEC dbo.Fraud_doubles_test @ClientRequestId

		SELECT @End_Date = getdate()
		SELECT @Row_Count = (SELECT count(*) FROM #t_ResultTable AS T)

		--UPDATE R
		--SET R.Duration_Sec = datediff(SECOND, @Start_Date, @End_Date),
		--	R.Start_Date = @Start_Date, 
		--	R.End_Date = @End_Date, 
		--	R.Row_Count = @Row_Count
		--FROM #t_ClientRequestId AS R
		--WHERE R.ClientRequestId = @ClientRequestId

		INSERT tmp.Result_Fraud_doubles_test
		(
			Process_Start_Date,
		    ClientRequestId,
		    Row_Count,
		    Duration_Sec,
		    Start_Date,
		    End_Date
		)
		SELECT
			@Process_Start_Date,
		    @ClientRequestId,
		    @Row_Count,
			Duration_Sec = datediff(SECOND, @Start_Date, @End_Date),
			@Start_Date,
			@End_Date

		--WAITFOR DELAY '00:00:03'

		FETCH NEXT FROM Cur_ClientRequestId
		INTO @ClientRequestId
	END   
	CLOSE Cur_ClientRequestId
	DEALLOCATE Cur_ClientRequestId
END

