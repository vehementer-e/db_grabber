--exec dbo.Report_Количество_запросов_ИНН_в_Xneo
CREATE   PROC dbo.Report_Количество_запросов_ИНН_в_Xneo
	@dtFrom date=null,
	@dtTo date=NULL
	--@isDebug int = 0
as
begin
	--SELECT @isDebug = isnull(@isDebug, 0)

	SELECT @dtFrom = isnull(@dtFrom, dateadd(DAY, 1, cast(eomonth(getdate(), -1) AS date)))
	SELECT @dtTo = isnull(@dtTo , cast(getdate() AS date))
	SELECT @dtTo = dateadd(DAY, 1, @dtTo)

	DROP TABLE IF EXISTS #t_Result

SELECT 
	ДатаЗапроса = cast(R.[ResultData.RequestTime] AS date),
	КолЗапросов = count(*),

	--old
	--КолУспешныхОтветов = 
	--	sum(
	--		CASE 
	--			WHEN cast(isnull(R.[ResultData.IsSuccess], 0) AS int) = 1 THEN 1
	--			ELSE 0
	--		END),

	--1. Кол. полученных ИНН: IsSuccess=true
	КолПолученныхИНН = sum(
			CASE 
				WHEN cast(isnull(R.[ResultData.IsSuccess], 0) AS int) = 1
					THEN 1
				ELSE 0
			END),

	--2. Кол. успешных ответов, но без ИНН, т.е ответ был со статусом 200, но ИНН не получили
	-- IsSuccess=false и StatusCode равен 200
	КолУспешныхОтветовБезИНН = sum(
			CASE 
				WHEN cast(isnull(R.[ResultData.IsSuccess], 0) AS int) = 0
					AND R.[ResultData.StatusCode] = 200
					THEN 1
				ELSE 0
			END),

	--3. Кол-во Неуспешных Ответов, ИНН не получили и ответ был со статусом <> 200
	--	IsSuccess=false и StatusCode не равен 200
	КолНЕуспешныхОтветов = 
		sum(
			CASE 
				WHEN cast(isnull(R.[ResultData.IsSuccess], 0) AS int) = 0 
					AND isnull(R.[ResultData.StatusCode], 0) <> 200
					THEN 1
				ELSE 0
			END)

	INTO #t_Result
	FROM Stg._smartIntegration.InnRequest_ResultData AS R
	WHERE 1=1
		AND isnull(R.[ResultData.UsedCache], 0) = 0
		AND R.[ResultData.RequestTime] BETWEEN @dtFrom AND @dtTo
	GROUP BY cast(R.[ResultData.RequestTime] AS date)

	SELECT 
		R.ДатаЗапроса,
		R.КолЗапросов,
		R.КолПолученныхИНН,
		R.КолУспешныхОтветовБезИНН,
		R.КолНЕуспешныхОтветов 
	FROM #t_Result AS R
	ORDER BY R.ДатаЗапроса

	--IF @isDebug = 1 BEGIN
	--	DROP TABLE IF EXISTS ##t_Result
	--	SELECT * INTO ##t_Result FROM #t_Result
	--END

END