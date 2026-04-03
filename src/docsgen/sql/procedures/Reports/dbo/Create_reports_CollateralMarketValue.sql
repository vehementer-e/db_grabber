--DWH-1920 Создание отчета по рыночной стоимости залогов
CREATE   PROC dbo.Create_reports_CollateralMarketValue
	@parMonth varchar(20) = NULL,
	@parQuarter varchar(20) = NULL,
	@parYear varchar(20) = NULL,
	@dtFrom date = NULL,
	@dtTo date = NULL
AS
BEGIN
	DECLARE @FirstMonthQuarter varchar(2)

	IF @parMonth IS NOT NULL BEGIN
		SELECT @dtFrom = convert(date, concat(@parMonth, '-01'), 120)
		SELECT @dtTo = eomonth(@dtFrom)
	END
	ELSE BEGIN
		IF @parQuarter IS NOT NULL BEGIN
			SELECT @FirstMonthQuarter = 
				CASE substring(replace(@parQuarter,' ',''), 6, 1)
					WHEN '1' THEN '01'
					WHEN '2' THEN '04'
					WHEN '3' THEN '07'
					WHEN '4' THEN '10'
					ELSE '01'
				END
                
			SELECT @dtFrom = convert(date, concat(substring(@parQuarter, 1, 4), '-', @FirstMonthQuarter,'-01'), 120)
			SELECT @dtTo = eomonth(dateadd(MONTH, 2, @dtFrom))
		END
		ELSE BEGIN
			IF @parYear IS NOT NULL BEGIN
				SELECT @dtFrom = convert(date, concat(@parYear, '-01-01'))
				SELECT @dtTo = convert(date, concat(@parYear, '-12-31'))
			END
			ELSE BEGIN
					SELECT @dtFrom = isnull(@dtFrom, cast(dateadd(MONTH, -2, dateadd(DAY, 1, eomonth(getdate()))) AS date))
					SELECT @dtTo = isnull(@dtTo, cast(getdate() AS date))
			END
		END
	END

	SELECT 
		--D.DWHInsertedDate,
		--D.ProcessGUID,
		D.report_date,
		D.НомерДоговора,
		D.ДатаДоговора,
		D.ДатаВыдачи,
		D.СуммаВыдачи,
		--D.Фамилия,
		--D.Имя,
		--D.Отчество,
		--Рыночная стоимость залога (руб.)
		[Рыночная стоимость залога (руб)] = D.[Федор.Рыночная стоимость на момент оценки],
		--Тип клиента (Первичный, Докредитование, Повторный, Параллельный)
		[Тип клиента] = D.return_type,
		dtFrom = @dtFrom,
		dtTo = @dtTo
	FROM dbo.dm_CollateralValue_MonthlyIncome AS D
	WHERE 1=1
		AND D.ДатаДоговора BETWEEN @dtFrom AND @dtTo
	--ORDER BY D.НомерДоговора
	--ORDER BY D.ДатаВыдачи desc, D.ДатаДоговора desc, D.НомерДоговора
	ORDER BY D.ДатаДоговора, D.НомерДоговора
END   
