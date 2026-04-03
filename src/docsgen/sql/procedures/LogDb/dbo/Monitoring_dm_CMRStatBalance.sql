-- ============================================= 
-- Author: А. Никитин
-- Create date: 25.05.2022 
-- Description: DWH-1645 Расширить мониторинг формирования dm_CMRStatBalance
-- ============================================= 
CREATE PROC [dbo].[Monitoring_dm_CMRStatBalance]
	@isDebug int = 0
AS 
BEGIN 
	SET NOCOUNT ON; 

	DECLARE @logStart_id int, @logFinish_id int
	DECLARE @ProcessGUID nvarchar(36)
	DECLARE @TotalActiveContractOnToday int
	DECLARE @TotalRowOnTodayInCMRStatBalance int -- кол строк за сегодня в dm_CMRStatBalance
	DECLARE @AllTotalRowInCMRStatBalance int -- кол строк всего в dm_CMRStatBalance
	DECLARE @Start_description nvarchar(1024), @Finish_description nvarchar(1024)
	DECLARE @StartTime datetime, @EndTime datetime
	DECLARE @durationTime time -- время расчета dm_CMRStatBalance time 00:00:00
	DECLARE @isOk bit -- (true/false) - показывает, что баланс сегодня рассчитался и все ок вычисляется как соотношение
	DECLARE @deviation float

	SELECT @isDebug = isnull(@isDebug, 0)
	SELECT @isOk = 0

	SELECT @logStart_id = max(L.id)
	
	FROM LogDb.dbo._log AS L
	WHERE 1=1
		AND L.logDate >= cast(getdate() AS date)
		AND L.logEventName LIKE '%Create_dm_CMRStatBalance%'
		AND L.logEventParams = 'Started'

	IF @isDebug = 1 BEGIN
		SELECT logStart_id = @logStart_id
	END

	IF @logStart_id IS NOT NULL
	BEGIN
		SELECT
			@ProcessGUID = L.ProcessGUID,
			@Start_description = L.logEventDescription,
			@StartTime = L.logDateTime
		FROM LogDb.dbo._log AS L
		WHERE L.id = @logStart_id

		-- кол-во активных договоров на сегодня
		SELECT @TotalActiveContractOnToday = try_convert(int, json_value(@Start_description, '$.TotalActiveContractOnToday'))

		SELECT @logFinish_id = min(L.id)

		FROM LogDb.dbo._log AS L
		WHERE 1=1
			AND L.id > @logStart_id
			AND L.logDate >= cast(getdate() AS date)
			AND L.logEventName LIKE '%Create_dm_CMRStatBalance%'
			AND L.logEventParams = 'Done'
			AND L.ProcessGUID = @ProcessGUID

		IF @isDebug = 1 BEGIN
			SELECT logFinish_id = @logFinish_id
		END

		IF @logFinish_id IS NOT NULL
		BEGIN
			SELECT 
				@Finish_description = L.logEventDescription,
				@EndTime = L.logDateTime
			FROM LogDb.dbo._log AS L
			WHERE L.id = @logFinish_id

			SELECT 
				-- кол строк за сегодня в dm_CMRStatBalance
				@TotalRowOnTodayInCMRStatBalance = try_convert(int, json_value(@Finish_description, '$.TotalRowOnTodayInCMRStatBalance')),
				-- кол строк всего в dm_CMRStatBalance
				@AllTotalRowInCMRStatBalance = try_convert(int, json_value(@Finish_description, '$.AllTotalRowInCMRStatBalance'))

			SELECT @durationTime = cast(@EndTime - @StartTime AS time)

			-- isOk (true/false) - показывает, что баланс сегодня рассчитался и все ок
			-- вычисляется как соотношение @TotalRowOnTodayInCMRStatBalance / @TotalActiveContractOnToday
			-- если есть отклонение более чем на 25% тогда false
			--SELECT @isOk = 1

			IF @TotalActiveContractOnToday > 0
			BEGIN
				SELECT @deviation = 100. * abs(convert(float, @TotalRowOnTodayInCMRStatBalance) - @TotalActiveContractOnToday) / @TotalActiveContractOnToday
				SELECT @isOk = iif(@deviation < 25., 1, 0) 
			END
			--set @isOk = 1
		END
	END

	SELECT
		StartTime = convert(datetime2(0), @StartTime),
		EndTime = convert(datetime2(0), @EndTime),
		durationTime = convert(time(0), @durationTime),
		TotalActiveContractOnToday = @TotalActiveContractOnToday,
		TotalRowOnTodayInCMRStatBalance = @TotalRowOnTodayInCMRStatBalance,
		AllTotalRowInCMRStatBalance = @AllTotalRowInCMRStatBalance,
		isOk = @isOk,
		JsonResult =
		(
		SELECT
			'StartTime' = convert(datetime2(0), @StartTime),
			'EndTime' = convert(datetime2(0), @EndTime),
			'durationTime' = convert(time(0), @durationTime),
			'TotalActiveContractOnToday' = @TotalActiveContractOnToday,
			'TotalRowOnTodayInCMRStatBalance' = @TotalRowOnTodayInCMRStatBalance,
			'AllTotalRowInCMRStatBalance' = @AllTotalRowInCMRStatBalance,
			'isOk' = @isOk
		FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
		)

END 

