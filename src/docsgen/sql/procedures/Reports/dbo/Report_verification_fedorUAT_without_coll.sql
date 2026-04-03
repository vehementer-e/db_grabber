/*
exec dbo.Report_verification_fedorUAT_without_coll 'KD.Monthly.PostponeUnique'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.Daily.PostponeUnique'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.Monthly.PostponeUnique'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.Daily.PostponeUnique'

exec dbo.Report_verification_fedorUAT_without_coll 'ReportByEmployeeAgg'
exec dbo.Report_verification_fedorUAT_without_coll 'ReportByEmployeeAgg_LastHour'

--exec dbo.Report_verification_fedorUAT_without_coll 'ReportByEmployee_VK'
exec dbo.Report_verification_fedorUAT_without_coll 'ReportByEmployeeAgg_VK'
exec dbo.Report_verification_fedorUAT_without_coll 'ReportByEmployeeAgg_VK_LastHour'

exec dbo.Report_verification_fedorUAT_without_coll 'ReportByEmployee_TS'
exec dbo.Report_verification_fedorUAT_without_coll 'ReportByEmployeeAgg_TS'
exec dbo.Report_verification_fedorUAT_without_coll 'ReportByEmployeeAgg_TS_LastHour'

exec dbo.Report_verification_fedorUAT_without_coll 'KD.Detail'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.Detail'

exec dbo.Report_verification_fedorUAT_without_coll 'KD.Daily.Total'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.Daily.Unic'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.Daily.AvgTime'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.Daily.Approved'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.Daily.Postpone'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.Daily.Rework'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.Daily.AR'

exec dbo.Report_verification_fedorUAT_without_coll 'VK.Daily.Total'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.Daily.Unic'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.Daily.AvgTime'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.Daily.Approved' 
exec dbo.Report_verification_fedorUAT_without_coll 'VK.Daily.Postpone'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.Daily.Rework'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.Daily.AR'

exec dbo.Report_verification_fedorUAT_without_coll 'KD.Monthly.Total'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.Monthly.Unic'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.Monthly.AvgTime'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.Monthly.Approved'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.Monthly.Postpone'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.Monthly.Rework'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.Monthly.AR'

exec dbo.Report_verification_fedorUAT_without_coll 'VK.Monthly.Total'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.Monthly.Unic'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.Monthly.AvgTime'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.Monthly.Approved'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.Monthly.AR'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.Monthly.Postpone'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.Monthly.Rework'


exec dbo.Report_verification_fedorUAT_without_coll 'KD.Daily.Common'
exec dbo.Report_verification_fedorUAT_without_coll 'V.Daily.Common' 

exec dbo.Report_verification_fedorUAT_without_coll 'KD.Monthly.Common', '2021-03-01', '2021-03-29'
exec dbo.Report_verification_fedorUAT_without_coll 'V.Monthly.Common'


exec dbo.Report_verification_fedorUAT_without_coll 'KD.Daily.Common', '2021-03-28', '2021-03-29'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.Daily.Total'

exec dbo.Report_verification_fedorUAT_without_coll 'KD.Daily.Approved'

exec dbo.Report_verification_fedorUAT_without_coll 'KD.HoursGroupMonth'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.HoursGroupMonthUnique'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.HoursGroupDays'
exec dbo.Report_verification_fedorUAT_without_coll 'KD.HoursGroupDaysUnique'

exec dbo.Report_verification_fedorUAT_without_coll 'VK.HoursGroupMonth'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.HoursGroupMonthUnique'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.HoursGroupDays'
exec dbo.Report_verification_fedorUAT_without_coll 'VK.HoursGroupDaysUnique'


*/

CREATE   PROC dbo.Report_verification_fedorUAT_without_coll
--declare
  @Page nvarchar(100) = 'V.Monthly.Common'
  ,@dtFrom date = null -- '2021-04-01'
  ,@dtTo date =  null --'2021-04-26'
  ,@ProcessGUID varchar(36) = NULL -- guid процесса
  ,@isDebug int = 0
AS
BEGIN

	SET NOCOUNT ON;

BEGIN TRY

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
			FROM LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll AS F
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

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
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
			FROM LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll AS F
			WHERE F.ReportPage = @Page
				AND F.ProcessGUID = @ProcessGUID
			)
		BEGIN
			--таблица для @Page НЕ заполнена
			--вызвать заполнение всех таблиц и ждать

			SELECT @delay = '00:00:00.' + convert(varchar(3), round(1000 * rand(), 0))
			WAITFOR DELAY @delay


		    EXEC dbo.Report_verification_fedorUAT_without_coll
				@Page = 'Fill_All_Tables', 
				@dtFrom = @dtFrom,
				@dtTo = @dtTo,
				@ProcessGUID = @ProcessGUID


			SELECT @EventDateTime = getdate()

			WHILE 
				-- НЕ появились данные для @Page
				NOT EXISTS(
					SELECT TOP 1 1
					FROM LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll AS F
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
		'EXEC dbo.Report_verification_fedorUAT_without_coll ',
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
		@eventName = 'Report_verification_fedorUAT_without_coll',
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

	IF @Page = 'KD.Monthly.Common' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	
	IF @Page = 'KD.Monthly.Autoapprove' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Autoapprove AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'KD.Daily.Common' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'KD.Daily.Autoapprove' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Autoapprove AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'V.Monthly.Common' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_V_Monthly_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END


	IF @Page = 'KD.Monthly.Total' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Monthly.AvgTime' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Monthly.Approved' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Monthly.AR' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Monthly.Postpone' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Monthly.Rework' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Daily.Total' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Daily.AvgTime' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Daily.Approved' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Daily.AR' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Daily.Postpone' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Daily.Rework' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'KD.Detail' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID
		ORDER BY T.[ФИО сотрудника верификации/чекер] asc, T.[Дата заведения заявки] desc, T.[Время заведения] desc
	END

	IF @Page = 'VK.Detail' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID
		ORDER BY T.[ФИО сотрудника верификации/чекер], T.[Дата статуса] DESC, T.[Номер заявки] DESC
	END
	IF @Page = 'KD.Daily.Unic' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Daily.PostponeUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Monthly.PostponeUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END


	IF @Page = 'VK.Monthly.Total' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.AvgTime' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.Approved' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.AR' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.Postpone' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.Rework' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.Total' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.AvgTime' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.Approved' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.AR' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.Postpone' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.Rework' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.Unic' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.Unic' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.PostponeUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.PostponeUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.HoursGroupMonth' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonth AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.HoursGroupMonthUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonthUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.HoursGroupDaysUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDaysUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.HoursGroupDays' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDays AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END



	IF @Page = 'V.Daily.Common' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_V_Daily_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'KD.Monthly.Unic' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.HoursGroupDays' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupDays AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.HoursGroupMonth' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupMonth AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.HoursGroupDaysUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupDaysUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.HoursGroupMonthUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupMonthUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'V.Monthly.TTY' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_V_Monthly_TTY AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'V.Daily.TTY' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_V_Daily_TTY AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END


	IF @Page NOT IN ('Fill_All_Tables', 'Clear_All_Tables')
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1
			FROM LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll AS F
			WHERE F.ReportPage = @Page
				AND F.ProcessGUID = @ProcessGUID
			)
		BEGIN
			--таблица для @Page заполнена
			--почистить Fill
			--BEGIN TRAN

			DELETE F
			FROM LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll AS F 
			WHERE F.ReportPage = @Page AND F.ProcessGUID = @ProcessGUID

			-- если это последний вызов (нет больше записей, кроме 'Fill_All_Tables'),
			-- удалить запись 'Fill_All_Tables'
			IF NOT EXISTS(
				SELECT TOP 1 1
				FROM LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll AS F
				WHERE F.ReportPage <> 'Fill_All_Tables'
					AND F.ProcessGUID = @ProcessGUID
			)
			AND EXISTS(
				SELECT TOP 1 1
				FROM LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll AS F
				WHERE F.ReportPage = 'Fill_All_Tables'
					AND F.ProcessGUID = @ProcessGUID
					AND F.EndDateTime IS NOT NULL
			)
			--EndDateTime
			BEGIN
				DELETE F
				FROM LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll AS F 
				WHERE F.ReportPage = 'Fill_All_Tables' AND F.ProcessGUID = @ProcessGUID

				--очистить все таблицы
				EXEC dbo.Report_verification_fedorUAT_without_coll
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
		-- очистить все таблицы
		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Autoapprove AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Autoapprove AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_V_Monthly_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID


		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID



		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonth AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonthUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDaysUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDays AS T
		WHERE T.ProcessGUID = @ProcessGUID




		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_V_Daily_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID


		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID


		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupDays AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupMonth AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupDaysUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupMonthUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_V_Monthly_TTY AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_V_Daily_TTY AS T
		WHERE T.ProcessGUID = @ProcessGUID

		--
		--SELECT ProcessGUID = @ProcessGUID

		RETURN 0
	END
END


--test
/*
IF @Page NOT IN (
	'Fill_All_Tables',
	--
	'KD.Monthly.Common',
	'KD.Daily.Common',
	'V.Monthly.Common',
	
	'KD.Monthly.Total',
	'KD.Monthly.AvgTime',
	'KD.Monthly.Approved',
	'KD.Monthly.AR',
	'KD.Monthly.Postpone',
	'KD.Monthly.Rework',
	'KD.Daily.Total',
	'KD.Daily.AvgTime',
	'KD.Daily.Approved',
	'KD.Daily.AR',
	'KD.Daily.Postpone',
	'KD.Daily.Rework',
	'KD.Detail',
	'VK.Detail',
	'KD.Daily.Unic',
	'KD.Daily.PostponeUnique',
	'KD.Monthly.PostponeUnique',
	--
	'VK.Monthly.Total',
	'VK.Monthly.AvgTime',
	'VK.Monthly.Approved',
	'VK.Monthly.AR',
	'VK.Monthly.Postpone',
	'VK.Monthly.Rework',
	'VK.Daily.Total',
	'VK.Daily.AvgTime',
	'VK.Daily.Approved',
	'VK.Daily.AR',
	'VK.Daily.Postpone',
	'VK.Daily.Rework',
	'VK.Monthly.Unic',
	'VK.Daily.Unic',
	'VK.Daily.PostponeUnique',
	'VK.Monthly.PostponeUnique',
	'VK.HoursGroupMonth',
	'VK.HoursGroupMonthUnique',
	'VK.HoursGroupDaysUnique',
	'VK.HoursGroupDays',
	--
	'V.Daily.Common',
	'KD.Monthly.Unic',
	'KD.HoursGroupDays',
	'KD.HoursGroupMonth',
	'KD.HoursGroupDaysUnique',
	'KD.HoursGroupMonthUnique',
)
BEGIN
    RETURN 0
END
*/



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

	DROP TABLE IF EXISTS #t_ProductType
	CREATE TABLE #t_ProductType(
		ProductType_Code varchar(30),
		ProductType_Name varchar(30),
		ProductType_Order int
	)
	INSERT #t_ProductType
	(
	    ProductType_Code,
	    ProductType_Name,
	    ProductType_Order
	)
	VALUES 
		('ALL', 'БЕЗЗАЛОГ', 1),
		('installment', 'ИНСТОЛМЕНТ', 2),
		('pdl', 'PDL', 3)


	drop table if exists #t_dm_FedorVerificationRequests_without_coll
	CREATE TABLE #t_dm_FedorVerificationRequests_without_coll
	(
		[ProductType_Code] [varchar](30) NULL,
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
		ТипКлиента varchar(30) NULL,
		isSkipped bit NULL
	)

	--1 installment
	INSERT #t_dm_FedorVerificationRequests_without_coll
	(
		[ProductType_Code],
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
		ТипКлиента,
		isSkipped
	)
	SELECT 
		ProductType_Code = 'installment',
		IdClientRequest = CR.Id,
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
		R.ТипКлиента,
		R.isSkipped
	--INTO #t_dm_FedorVerificationRequests_without_coll
	FROM dbo.dm_FedorVerificationRequestsUAT_Installment AS R (NOLOCK)
		INNER JOIN Stg._fedorUAT.core_ClientRequest AS CR
			ON CR.Number COLLATE Cyrillic_General_CI_AS = R.[Номер заявки]
	WHERE 1=1
		AND R.[Дата статуса] > @dt_from
		AND R.[Дата статуса] < @dt_to


	--2 pdl
	INSERT #t_dm_FedorVerificationRequests_without_coll
	(
		[ProductType_Code],
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
		ТипКлиента,
		isSkipped
	)
	SELECT 
		ProductType_Code = 'pdl',
		IdClientRequest = CR.Id,
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
		R.ТипКлиента,
		R.isSkipped
	--INTO #t_dm_FedorVerificationRequests_without_coll
	FROM dbo.dm_FedorVerificationRequestsUAT_PDL AS R (NOLOCK)
		INNER JOIN Stg._fedorUAT.core_ClientRequest AS CR
			ON CR.Number COLLATE Cyrillic_General_CI_AS = R.[Номер заявки]
	WHERE 1=1
		AND R.[Дата статуса] > @dt_from
		AND R.[Дата статуса] < @dt_to

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
	FROM #t_dm_FedorVerificationRequests_without_coll AS T

	CREATE INDEX ix1 ON #t_dm_FedorVerificationRequests_without_coll([Номер заявки], [Дата статуса]) INCLUDE([Статус следующий], ProductType_Code)
	CREATE INDEX ix2 ON #t_dm_FedorVerificationRequests_without_coll(ProductType_Code, [Номер заявки])

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_dm_FedorVerificationRequests_without_coll
		SELECT * INTO ##t_dm_FedorVerificationRequests_without_coll FROM #t_dm_FedorVerificationRequests_without_coll
	END

	--Все типы продуктов
	SELECT * 
	INTO #t_dm_FedorVerificationRequests_without_coll_ALL
	FROM #t_dm_FedorVerificationRequests_without_coll

	UPDATE D
	SET D.ProductType_Code = 'ALL'
	FROM #t_dm_FedorVerificationRequests_without_coll_ALL AS D

	INSERT #t_dm_FedorVerificationRequests_without_coll_ALL
	SELECT * 
	FROM #t_dm_FedorVerificationRequests_without_coll

	CREATE INDEX ix1 ON #t_dm_FedorVerificationRequests_without_coll_ALL([Номер заявки], [Дата статуса]) INCLUDE([Статус следующий], ProductType_Code)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_dm_FedorVerificationRequests_without_coll_ALL
		SELECT * INTO ##t_dm_FedorVerificationRequests_without_coll_ALL FROM #t_dm_FedorVerificationRequests_without_coll_ALL
	END
	--//Все типы продуктов


drop table if exists #curr_employee_test
create table #curr_employee_test([Employee] nvarchar(255))

/*
--комментарю для UAT
INSERT #curr_employee_test(Employee)
--select *
select substring(trim(U.DisplayName), 1, 255)
FROM [dwh-ex].bot.dbo.[vw_ActiveDirectoryUsers] AS U
where U.Department ='Отдел тестирования'
UNION
SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
FROM Stg._fedorUAT.core_user AS U
WHERE U.IsQAUser = 1
*/

DELETE R
FROM #t_dm_FedorVerificationRequests_without_coll AS R
WHERE 1=1
	AND R.Работник IN (SELECT Employee FROM #curr_employee_test)


DELETE R
FROM #t_dm_FedorVerificationRequests_without_coll AS R
WHERE 1=1
	AND R.[ФИО сотрудника верификации/чекер] IN (SELECT Employee FROM #curr_employee_test)


	CREATE CLUSTERED INDEX clix1 
	ON #t_dm_FedorVerificationRequests_without_coll([Номер заявки], [Дата статуса], ProductType_Code)

  -- получим список часов и дней в интревале
  drop table if exists #HoursDays
  ;WITH cte
AS (select @dt_from_hours AS Today

    UNION ALL

    SELECT dateadd(hour, 1, Today) AS Today
    FROM cte
    WHERE dateadd(hour, 1,Today) < @dt_to_hours 
    )
SELECT datepart(hour,Today ) Интервал, cast(Today  as date) Дата, datepart(hour,dateadd(hour, 1,Today )) ИнтервалPlus, '00:00 - 01:               ' ИнтервалСтрока
into #HoursDays
FROM cte
--OPTION (MAXRECURSION 2210)
OPTION (MAXRECURSION 0)

update #HoursDays Set ИнтервалСтрока = Format(Интервал ,'00') + ':00 - ' + Format(ИнтервалPlus,'00')  + ':00'

insert into #HoursDays
select 25 as Интервал,  Дата, '' as Интервал,  'Итого:' ИнтервалСтрока
from #HoursDays 
group by Дата


IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##HoursDays
	SELECT * INTO ##HoursDays FROM #HoursDays
END

-- статические справочники
  --select  distinct [ФИО сотрудника верификации/чекер] from #t_dm_FedorVerificationRequests_without_coll
  --insert into  feodor.dbo.KDEmployees select 'Силаева Татьяна Владимировна',getdate()
-- сотрудники КД
  drop table if exists #curr_employee_cd
  create table #curr_employee_cd([Employee] nvarchar(255))
  
	--комментарю по DWH-1988
	/*  
	INSERT 
    into #curr_employee_cd
    select employee from feodor.dbo.KDEmployees
	--2021-06-15
	where 
	
	--2021_09_27
	--fired >= @dtFrom 
	fired >= @dt_from
	or fired is null
  --insert into feodor.dbo.KDEmployees  select 'Ставцева Ольга Алексеевна',getdate() 
	*/
	--DWH-1988
	INSERT #curr_employee_cd(Employee)
	SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedorUAT.core_user AS U
		INNER JOIN Stg._fedorUAT.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
		INNER JOIN Stg._fedorUAT.core_UserRoleDictionary AS R
			ON R.Id = UR.IdUserRole
	WHERE 1=1
	--AND UR.IsDeleted = 0
		AND R.Name IN ('Чекер')
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
		from Stg._fedorUAT.core_user u
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

	--комментарю по DWH-1988
	/*
	-- delete from #curr_employee_vr
	insert into #curr_employee_vr select employee from feodor.dbo.VEmployees
   --2021-06-15
   	where 
	--2021_09_27
	--fired >= @dtFrom 
	fired >= @dt_from
	or fired is null
	*/
	--DWH-1988
	INSERT #curr_employee_vr(Employee)
	SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedorUAT.core_user AS U
		INNER JOIN Stg._fedorUAT.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
		INNER JOIN Stg._fedorUAT.core_UserRoleDictionary AS R
			ON R.Id = UR.IdUserRole
	WHERE 1=1
		AND R.Name IN ('Верификатор')
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
		from Stg._fedorUAT.core_user u
		where Id in('89EAED68-E616-415C-BE92-0C2D4C084899') --Столица Вероника Игоревна
	) u
	where U.DeleteDate >= @dt_from


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##curr_employee_vr
		SELECT * INTO ##curr_employee_vr FROM #curr_employee_vr
	END

  
DROP TABLE IF EXISTS #t_request_number
CREATE TABLE #t_request_number(IdClientRequest uniqueidentifier, [Номер заявки] nvarchar(255))
CREATE INDEX ix1 ON #t_request_number(IdClientRequest)
CREATE INDEX ix2 ON #t_request_number([Номер заявки])

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
CREATE INDEX ix_IdClientRequest ON #t_checklists_rejects(IdClientRequest)

--DELETE #t_request_number
--DELETE #t_approved
--DELETE #t_denied
--DELETE #t_canceled
--DELETE #t_customer_rejection

--request numbers
INSERT #t_request_number(IdClientRequest, [Номер заявки])
SELECT DISTINCT R.IdClientRequest, R.[Номер заявки]
FROM #t_dm_FedorVerificationRequests_without_coll AS R
WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
	AND R.[Дата статуса] > @dt_from
	AND R.[Дата статуса] < @dt_to

--одобрено
INSERT #t_approved([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	AND R.[Дата статуса] > @dt_from
	AND R.[Дата статуса] < @dt_to
	AND (
		R.Статус IN ('Верификация Call 1.5', 'Переподписание первого пакета') AND R.[Статус следующий] IN ('Верификация Call 2')
		OR R.Статус IN ('Верификация ТС','Верификация Call 4') AND R.[Статус следующий] IN ('Одобрено')
		--OR R.Статус IN ('Верификация Call 3') AND R.[Статус следующий] IN ('Одобрено')
		--DWH-2361
		OR (R.Статус IN ('Верификация Call 3') 
			AND EXISTS(
					SELECT TOP(1) 1
					FROM #t_dm_FedorVerificationRequests_without_coll AS N
					WHERE R.[Номер заявки] = N.[Номер заявки]
						AND N.[Дата статуса] >= R.[Дата статуса]
						AND N.[Статус следующий] IN ('Одобрено', 'Предодобр перед Call 5')
				)
		)
	)
GROUP BY R.[Номер заявки]

--финальное одобрение
INSERT #t_final_approved([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата след.статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	AND R.[Статус следующий] = 'Одобрено' 
	-- есть заявки, у кот. нет записи Статус = 'Одобрено', но есть [Статус следующий] = 'Одобрено'
	--напр. '23121221532517','23121921568650','23121521547100'
GROUP BY R.[Номер заявки]

IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##t_final_approved
	SELECT * INTO ##t_final_approved FROM #t_final_approved
END

--отказано
INSERT #t_denied([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	AND R.[Дата статуса] > @dt_from
	AND R.[Дата статуса] < @dt_to
	AND R.Статус IN ('Верификация Call 1.5','Верификация ТС','Верификация Call 3','Верификация Call 4')
	AND R.[Статус следующий] IN ('Отказано')
GROUP BY R.[Номер заявки]

--анулировано
INSERT #t_canceled([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	AND R.[Дата статуса] > @dt_from
	AND R.[Дата статуса] < @dt_to
	AND R.Статус IN ('Контроль данных','Верификация клиента','Верификация ТС','Верификация Call 3','Верификация Call 4') 
	AND R.[Статус следующий] IN ('Аннулировано')
GROUP BY R.[Номер заявки]

--Отказ клиента
INSERT #t_customer_rejection([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	AND R.[Дата статуса] > @dt_from
	AND R.[Дата статуса] < @dt_to
	AND R.Статус IN ('Верификация Call 1.5')
	AND R.[Статус следующий] IN ('Отказ клиента')
GROUP BY R.[Номер заявки]




DROP TABLE IF EXISTS #t_Autoapprove
CREATE TABLE #t_Autoapprove(
	[Номер заявки] nvarchar(255),
	Статус nvarchar(260),
	[Дата статуса] datetime2(7)
)

INSERT #t_Autoapprove
(
    [Номер заявки],
    Статус,
	[Дата статуса]
)
SELECT 
	R.[Номер заявки], 
	R.Статус,
	[Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	AND R.isSkipped = 1
GROUP BY R.[Номер заявки], R.Статус

CREATE CLUSTERED INDEX clix1 ON #t_Autoapprove([Номер заявки])

IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##t_Autoapprove
	SELECT * INTO ##t_Autoapprove FROM #t_Autoapprove
END







-- Лист "КД. Детализация"
IF @Page = 'KD.Detail' OR @isFill_All_Tables = 1 --241
BEGIN
	DELETE #t_request_number
	DELETE #t_approved
	DELETE #t_denied
	DELETE #t_canceled
	DELETE #t_customer_rejection
	DELETE #t_checklists_rejects

	--request numbers
	INSERT #t_request_number(IdClientRequest, [Номер заявки])
	SELECT DISTINCT R.IdClientRequest, R.[Номер заявки]
	FROM #t_dm_FedorVerificationRequests_without_coll AS R
	WHERE R.[Статус] in ('Контроль данных')
		AND R.[Дата статуса] > @dt_from
		AND R.[Дата статуса] < @dt_to

	--Отказы Логинома --DWH-2429
	;with loginom_checklists_rejects AS(
		SELECT 
			min(try_cast(replace(cis.LoginomNumber,'.','') AS bigint))  logn,
			cli.IdClientRequest
		FROM
			[Stg].[_fedorUAT].[core_CheckListItem] cli 
			inner JOIN [Stg].[_fedorUAT].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
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
	FROM [Stg].[_fedorUAT].[core_CheckListItem] cli
		JOIN [Stg].[_fedorUAT].[dictionary_CheckListItemType] cit ON  cit.id = cli.IdType
		JOIN [Stg].[_fedorUAT].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
		JOIN loginom_checklists_rejects rl ON rl.IdClientRequest = cli.IdClientRequest 
			AND try_cast(replace(cis.LoginomNumber,'.','') AS bigint) = rl.logn
		INNER JOIN Stg._fedorUAT.core_ClientRequest AS CR
			ON CR.Id = cli.IdClientRequest
	WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number AS R WHERE R.IdClientRequest = cli.IdClientRequest)

	--IF @isDebug = 1 BEGIN
	--	DROP TABLE IF EXISTS ##t_checklists_rejects
	--	SELECT * INTO ##t_checklists_rejects FROM #t_checklists_rejects
	--END

	--одобрено
	INSERT #t_approved([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		AND R.[Дата статуса] > @dt_from
		AND R.[Дата статуса] < @dt_to
		AND R.Статус IN ('Верификация Call 1.5', 'Переподписание первого пакета')
		AND R.[Статус следующий] IN ('Верификация Call 2')
	GROUP BY R.[Номер заявки]

	--2 одобрено сотрудником, но отказано автоматически
	INSERT #t_approved([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		AND R.[Дата статуса] > @dt_from
		AND R.[Дата статуса] < @dt_to
		AND R.Статус IN ('Верификация Call 1.5')
		AND R.[Статус следующий] IN ('Отказано')
		AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
	GROUP BY R.[Номер заявки]

	--отказано сотрудником
	INSERT #t_denied([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		AND R.[Дата статуса] > @dt_from
		AND R.[Дата статуса] < @dt_to
		AND R.Статус IN ('Верификация Call 1.5')
		AND R.[Статус следующий] IN ('Отказано')
		AND EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
	GROUP BY R.[Номер заявки]

	--анулировано
	INSERT #t_canceled([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		AND R.[Дата статуса] > @dt_from
		AND R.[Дата статуса] < @dt_to
		AND R.Статус IN ('Контроль данных')
		AND R.[Статус следующий] IN ('Аннулировано')
	GROUP BY R.[Номер заявки]

	--Отказ клиента
	INSERT #t_customer_rejection([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		AND R.[Дата статуса] > @dt_from
		AND R.[Дата статуса] < @dt_to
		AND R.Статус IN ('Верификация Call 1.5')
		AND R.[Статус следующий] IN ('Отказ клиента')
	GROUP BY R.[Номер заявки]


	IF @isFill_All_Tables = 1
	BEGIN
		--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Detail
		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID

		INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Detail
		SELECT 
			ProcessGUID = @ProcessGUID
			, R.[ProductType_Code]
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
			 --, R.[Офис заведения заявки]
			 --DWH-1720
			 , [Решение по заявке] = trim(
					concat(
						iif(approved.[Номер заявки] IS NOT NULL,'Одобрено',''),' ',
						iif(denied.[Номер заявки] IS NOT NULL,'Отказано',''),' ',
						iif(canceled.[Номер заявки] IS NOT NULL,'Аннулировано',''), ' ',
						iif(customer_rejection.[Номер заявки] IS NOT NULL,'Отказ клиента','')
						)
				)
			, R.ТипКлиента
			, IsSkipped = cast(R.IsSkipped AS int)
		--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Detail
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
				ON R.[Номер заявки] = N.[Номер заявки]
			--одобрено
			LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
			--отказано
			LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
			--анулировано
			LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
			--Отказ клиента
			LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
		WHERE R.[Статус] in ('Контроль данных')
			AND R.[Дата статуса] > @dt_from 
			AND R.[Дата статуса] < @dt_to
		ORDER BY R.Работник asc, R.[Дата заведения заявки] desc, R.[Время заведения] desc

		INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
		SELECT getdate(), 'KD.Detail', @ProcessGUID
	END
	ELSE BEGIN
		SELECT 
			R.[ProductType_Code]
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
			 --, R.[Офис заведения заявки]
			 --DWH-1720
			 , [Решение по заявке] = trim(
					concat(
						iif(approved.[Номер заявки] IS NOT NULL,'Одобрено',''),' ',
						iif(denied.[Номер заявки] IS NOT NULL,'Отказано',''),' ',
						iif(canceled.[Номер заявки] IS NOT NULL,'Аннулировано',''), ' ',
						iif(customer_rejection.[Номер заявки] IS NOT NULL,'Отказ клиента','')
						)
				)
			, R.ТипКлиента
			, IsSkipped = cast(R.IsSkipped AS int)
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
				ON R.[Номер заявки] = N.[Номер заявки]
			--одобрено
			LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
			--отказано
			LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
			--анулировано
			LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
			--Отказ клиента
			LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
		WHERE R.[Статус] in ('Контроль данных')
			AND R.[Дата статуса] > @dt_from 
			AND R.[Дата статуса] < @dt_to
		ORDER BY R.Работник asc, R.[Дата заведения заявки] desc, R.[Время заведения] desc

		RETURN 0
	END
END
--// 'KD.Detail'


	-- HoursGroupDays
	-- Лист "КД. Детализация по дням"
 

--Листы "ВК.%"
--подготовка данных
DELETE #t_request_number
DELETE #t_approved
DELETE #t_denied
DELETE #t_canceled
DELETE #t_customer_rejection
DELETE #t_checklists_rejects

--request numbers
INSERT #t_request_number(IdClientRequest, [Номер заявки])
SELECT DISTINCT R.IdClientRequest, R.[Номер заявки]
FROM #t_dm_FedorVerificationRequests_without_coll AS R
WHERE R.[Статус] in ('Верификация клиента')
	AND R.[Дата статуса] > @dt_from
	AND R.[Дата статуса] < @dt_to

--Отказы Логинома --DWH-2429
;with loginom_checklists_rejects AS(
	SELECT 
		min(try_cast(replace(cis.LoginomNumber,'.','') AS bigint))  logn,
		cli.IdClientRequest
	FROM
		[Stg].[_fedorUAT].[core_CheckListItem] cli 
		inner JOIN [Stg].[_fedorUAT].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
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
FROM [Stg].[_fedorUAT].[core_CheckListItem] cli
	JOIN [Stg].[_fedorUAT].[dictionary_CheckListItemType] cit ON  cit.id = cli.IdType
	JOIN [Stg].[_fedorUAT].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
	JOIN loginom_checklists_rejects rl ON rl.IdClientRequest = cli.IdClientRequest 
		AND try_cast(replace(cis.LoginomNumber,'.','') AS bigint) = rl.logn
	INNER JOIN Stg._fedorUAT.core_ClientRequest AS CR
		ON CR.Id = cli.IdClientRequest
WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number AS R WHERE R.IdClientRequest = cli.IdClientRequest)

--IF @isDebug = 1 BEGIN
--	DROP TABLE IF EXISTS ##t_checklists_rejects
--	SELECT * INTO ##t_checklists_rejects FROM #t_checklists_rejects
--END

--одобрено
INSERT #t_approved([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	AND R.[Дата статуса] > @dt_from
	AND R.[Дата статуса] < @dt_to
	AND (
		--R.Статус IN ('Верификация Call 3') AND R.[Статус следующий] IN ('Одобрено')
		--DWH-2361
		R.Статус IN ('Верификация Call 3') 
		AND EXISTS(
				SELECT TOP(1) 1
				FROM #t_dm_FedorVerificationRequests_without_coll AS N
				WHERE R.[Номер заявки] = N.[Номер заявки]
					AND N.[Дата статуса] >= R.[Дата статуса]
					AND N.[Статус следующий] IN ('Одобрено', 'Предодобр перед Call 5')
			)
	)
GROUP BY R.[Номер заявки]

--2 одобрено сотрудником, но отказано автоматически
INSERT #t_approved([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	AND R.[Дата статуса] > @dt_from
	AND R.[Дата статуса] < @dt_to
	AND R.Статус IN ('Верификация Call 3')
	AND R.[Статус следующий] IN ('Отказано')
	AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
GROUP BY R.[Номер заявки]

--отказано
INSERT #t_denied([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	AND R.[Дата статуса] > @dt_from
	AND R.[Дата статуса] < @dt_to
	AND R.Статус IN ('Верификация Call 3')
	AND R.[Статус следующий] IN ('Отказано')
	AND EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
GROUP BY R.[Номер заявки]

--анулировано
INSERT #t_canceled([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	AND R.[Дата статуса] > @dt_from
	AND R.[Дата статуса] < @dt_to
	AND R.Статус IN ('Верификация Call 3') 
	AND R.[Статус следующий] IN ('Аннулировано')
GROUP BY R.[Номер заявки]

--Отказ клиента
INSERT #t_customer_rejection([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	AND R.[Дата статуса] > @dt_from
	AND R.[Дата статуса] < @dt_to
	AND R.Статус IN ('Верификация Call 1.5')
	AND R.[Статус следующий] IN ('Отказ клиента')
GROUP BY R.[Номер заявки]


--Лист "ВК. Детализация"
IF @Page = 'VK.Detail' OR @isFill_All_Tables = 1 --301
BEGIN
	IF @isFill_All_Tables = 1
	BEGIN
		--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Detail
		DELETE T
		FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID

		INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Detail
		SELECT 
			ProcessGUID = @ProcessGUID
			, R.[ProductType_Code]
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
			 --, R.[Офис заведения заявки]
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
			, R.ТипКлиента
			, IsSkipped = cast(R.IsSkipped AS int)
		--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Detail
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
				ON R.[Номер заявки] = N.[Номер заявки]
			--одобрено
			LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
			--отказано
			LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
			--анулировано
			LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
			--Отказ клиента
			LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
		WHERE R.[Статус] in ('Верификация клиента')
			AND R.[Дата статуса] > @dt_from 
			AND R.[Дата статуса] < @dt_to
		order by Работник ,[Дата статуса] desc ,[Номер заявки] desc

		INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
		SELECT getdate(), 'VK.Detail', @ProcessGUID
	END
	ELSE BEGIN
		SELECT 
			R.[ProductType_Code]
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
			 --, R.[Офис заведения заявки]
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
			, R.ТипКлиента
			, IsSkipped = cast(R.IsSkipped AS int)
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_without_coll AS R
				ON R.[Номер заявки] = N.[Номер заявки]
			--одобрено
			LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
			--отказано
			LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
			--анулировано
			LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
			--Отказ клиента
			LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
		WHERE R.[Статус] in ('Верификация клиента')
			AND R.[Дата статуса] > @dt_from 
			AND R.[Дата статуса] < @dt_to
		order by Работник ,[Дата статуса] desc ,[Номер заявки] desc

		RETURN 0
	END
END
--// 'VK.Detail'






---------------------------------------------
--- общие таблицы для аггрегации по дням
---------------------------------------------
 
          drop table if exists #calendar
          select cast(created as date) as dt_day
        	     , cast(dateadd(month,datediff(month,0,created),0) as date) as dt_month
          into #calendar
          from dwh_new.[dbo].calendar
         where created >=@dt_from and created<@dt_to
        
        
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
            from (select distinct Работник Employee from #t_dm_FedorVerificationRequests_without_coll) e
        
        
        
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
         /*   where c.dt_day >= case when datepart(dd,getdate()) between 1 and 10 
        						               then dateadd(month,-1,dateadd(month,datediff(month,0,Getdate()),0)) 
        					                 else dateadd(month,datediff(month,0,Getdate()),0) 
        				               end
        
        -- select * from #employee_rows_d
        */
			CREATE NONCLUSTERED INDEX ix_status on #employee_rows_d([Status])
			INCLUDE ([acc_period],[empl_id],[Employee])


          drop table if exists #employee_rows_m
          select c.dt_month as acc_period
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





-- KD.%
IF @Page IN (
	'KD.Daily.Total'
	,'KD.Daily.Unic'
	,'KD.Daily.AvgTime'
	,'KD.Daily.Approved'
	,'KD.Daily.Postpone'
	,'KD.Daily.PostponeUnique'
	,'KD.Daily.Rework'
	,'KD.Daily.AR'
 
	,'ReportByEmployeeAgg'
	,'ReportByEmployeeAgg_LastHour'
	, 'fedor_verificator_report'

	,'KD.Daily.Common'

	,'KD.Monthly.Total'
	,'KD.Monthly.Unic'
	,'KD.Monthly.AvgTime'
	,'KD.Monthly.Approved'
	,'KD.Monthly.Postpone'
	,'KD.Monthly.PostponeUnique'
	,'KD.Monthly.Rework'
	,'KD.Monthly.AR'

	,'KD.Monthly.Common'
	,'KD.HoursGroupMonth'
	, 'KD.HoursGroupMonthUnique'
	, 'KD.HoursGroupDays'
	, 'KD.HoursGroupDaysUnique'

	,'KD.Monthly.Autoapprove'
	,'KD.Daily.Autoapprove'

	,'V.Monthly.Common'
	,'V.Monthly.TTY'
	,'V.Daily.Common'
	,'V.Daily.TTY'
) OR @isFill_All_Tables = 1
BEGIN

        drop table if exists #fedor_verificator_report
        
        drop table if exists #details_KD
        
        select * 
          into #details_KD 
          from #t_dm_FedorVerificationRequests_without_coll  --where [Номер заявки]='20092400036174'
         where 1=1
			AND (Работник not in (select * from #curr_employee_vr) 
				OR Работник IN (select Employee from #curr_employee_cd) --DWH-1787
				)
			--AND Работник IN (select Employee from #curr_employee_cd) --DWH-1988
           and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
         
		 create INDEX ix_Статус_Задача
			ON #details_KD([Статус] ,[Статус следующий], [Задача],[Задача следующая],[Состояние заявки], [Состояние заявки следующая])
			INCLUDE ([Номер заявки],[ФИО клиента],[Дата статуса],[ВремяЗатрачено],[ШагЗаявки],[ПоследнийШаг], [Работник],[Работник_Пред],[Работник_След])
		
		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##details_KD
			SELECT * INTO ##details_KD FROM #details_KD
		END

		--Отказы Логинома --DWH-2429
		DELETE #t_request_number
		DELETE #t_checklists_rejects

		INSERT #t_request_number(IdClientRequest, [Номер заявки])
		SELECT DISTINCT R.IdClientRequest, R.[Номер заявки]
		FROM #details_KD AS R

		;with loginom_checklists_rejects AS(
			SELECT 
				min(try_cast(replace(cis.LoginomNumber,'.','') AS bigint))  logn,
				cli.IdClientRequest
			FROM
				[Stg].[_fedorUAT].[core_CheckListItem] cli 
				inner JOIN [Stg].[_fedorUAT].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
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
		FROM [Stg].[_fedorUAT].[core_CheckListItem] cli
			JOIN [Stg].[_fedorUAT].[dictionary_CheckListItemType] cit ON  cit.id = cli.IdType
			JOIN [Stg].[_fedorUAT].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
			JOIN loginom_checklists_rejects rl ON rl.IdClientRequest = cli.IdClientRequest 
				AND try_cast(replace(cis.LoginomNumber,'.','') AS bigint) = rl.logn
			INNER JOIN Stg._fedorUAT.core_ClientRequest AS CR
				ON CR.Id = cli.IdClientRequest
		WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number AS R WHERE R.IdClientRequest = cli.IdClientRequest)



		 ;
         with 
          rework as (
          
          select 'Доработка' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса]
               , [ФИО клиента]
               , [Номер заявки] 
              --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
				,ТипКлиента
            from #details_KD
           where Задача='task:Требуется доработка' and [Состояние заявки]='Отложена' and Статус in('Контроль данных') 
          
          )
          ,rework1 as 
          (
          
          select 'Доработка' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса]
               , [ФИО клиента]
               , [Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_След -- Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
				,ТипКлиента
            from #details_KD
           where [Задача следующая]='task:Требуется доработка' and [Состояние заявки следующая]='Отложена' and Статус in('Контроль данных') and ШагЗаявки= ПоследнийШаг
          
          )
          ,postpone as (
        select 'Отложена' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки]  
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
				,ТипКлиента
            from #details_KD
           where Задача='task:Отложена' and [Состояние заявки] in('Отложена') and Статус in('Контроль данных')
           )
           ,postpone1 as (
        select 'Отложена' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки]  
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_След --Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
				,ТипКлиента
            from #details_KD
           where [Задача следующая]='task:Отложена' and [Состояние заявки следующая] in('Отложена') and Статус in('Контроль данных') and ШагЗаявки= ПоследнийШаг
           )

        
        
		--отказано сотрудником
         select 'Отказано' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки]  
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
				,ТипКлиента
            into #fedor_verificator_report
            from #details_KD AS N
           where [Статус следующий]='Отказано' and Статус in('Верификация Call 1.5')
				AND EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
           -- 
           union all
           select * from postpone
           union all 
           select * from postpone1

           
           union 
           -- доработка
           select * from rework
           union all 
           select * from rework1
           /*
          select 'Доработка' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса]
               , [ФИО клиента]
               , [Номер заявки] 
               , Сотрудник=СотрудникПоследнегоСтатуса
               , [ФИО сотрудника верификации/чекер]
               , ВремяЗатрачено
            from details_KD
           where Задача='task:Требуется доработка' and [Состояние заявки]='Отложена' and Статус in('Контроль данных')
          */
           union 
         
          select 'ВК' [status]
               , cast(A.[Дата статуса] as date) Дата
               , A.[Дата статуса] ДатаИВремяСтатуса
               , A.[ФИО клиента]
               , A.[Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=A.Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = A.Работник
               , A.ВремяЗатрачено 
				,A.ТипКлиента
            from #details_KD AS A
				LEFT JOIN #details_KD AS B --следующая заявка
					ON A.[Номер заявки] = B.[Номер заявки]
					AND A.ШагЗаявки = B.ШагЗаявки - 1
           where (
					A.Статус IN ('Верификация Call 1.5') 
					--[Статус следующий]='Ожидание подписи документов EDO' 
					AND A.[Статус следующий] = 'Верификация Call 2' --согласовано с Промётовым 22.12.2021
				)
				OR (
					B.Статус IN ('Переподписание первого пакета')
					AND B.[Статус следующий] = 'Верификация Call 2'
				)
				--DWH-2429 --одобрено сотрудником, но отказано автоматически
				OR (
					A.[Статус следующий]='Отказано' and A.Статус in('Верификация Call 1.5')
					AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = A.IdClientRequest)
				)

        union
          select 'Новая' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено 
				,ТипКлиента
            from #details_KD
           where Задача='task:Новая' and Статус in('Контроль данных')

        UNION
			--DWH-2021
          select 'Новая_Уникальная' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено 
				,ТипКлиента
            from #details_KD
           where Задача='task:Новая' and Статус in('Контроль данных')
				AND [Задача следующая] <> 'task:Автоматически отложено'
           union 
         
          select 'task:В работе' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки] 
              --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]

			   --, Сотрудник=Работник_Пред --Работник_След
			   -- исправлено DWH-2457
			   , Сотрудник=Работник

               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
				,ТипКлиента
            from #details_KD
             where Задача='task:В работе'  and Статус in('Контроль данных')
        
			UNION ALL
			SELECT 
				'Не вернувшиеся с доработки' AS [status]
				, Дата = cast(A.[Дата статуса] as date)
				, ДатаИВремяСтатуса = A.[Дата статуса]
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				, Сотрудник = A.Работник_Пред --A.Работник_След
				, [ФИО сотрудника верификации/чекер] = A.Работник
				, A.ВремяЗатрачено
				, A.ТипКлиента
			FROM (
					SELECT 
						K.[Дата статуса]
						,K.[ФИО клиента]
						,K.[Номер заявки] 
						,K.Работник_Пред --K.Работник_След
						,K.Работник
						,K.ВремяЗатрачено
						,[След Дата статуса] = lead(K.[Дата статуса],1,'2100-01-01') OVER(PARTITION BY K.[Номер заявки] ORDER BY K.[Дата статуса])
						,K.ТипКлиента
					from #details_KD AS K
					where K.Задача = 'task:Требуется доработка' 
				) AS A
				INNER JOIN 
				(
					SELECT 
						L.[Дата статуса]
						,L.[Номер заявки] 
					from #details_KD AS L
					where L.[Задача следующая] = 'task:Отменена'
				) AS B
				ON B.[Номер заявки] = A.[Номер заявки]
				AND A.[Дата статуса] < B.[Дата статуса] AND B.[Дата статуса] < A.[След Дата статуса]

			--UNION 
			--DWH-2209
			--SELECT 'Autoapprove' [status]
			--	, cast(A.[Дата статуса] as date) Дата
			--	, A.[Дата статуса] ДатаИВремяСтатуса
			--	, A.[ФИО клиента]
			--	, A.[Номер заявки] 
			--	--, Сотрудник=СотрудникПоследнегоСтатуса
			--	--, [ФИО сотрудника верификации/чекер]
			--	, Сотрудник=A.Работник_Пред --Работник_След
			--	, [ФИО сотрудника верификации/чекер] = A.Работник
			--	, A.ВремяЗатрачено 
			--	,A.ТипКлиента
			--FROM #details_KD AS A
			--WHERE (A.Статус IN ('Верификация Call 2') AND A.[Статус следующий] = 'Одобрено')

			--DWH-2374
			UNION 
			--Уникальное количество заявок autoapprove КД
			--заявки, по которым только на статусе КД был флаг skipped
			SELECT 
				[status] = 'Autoapprove_KD' 
				, Дата = cast(U.[Дата статуса] as date) 
				, ДатаИВремяСтатуса = U.[Дата статуса] 
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				, Сотрудник = max(A.Работник_Пред) --Работник_След
				, [ФИО сотрудника верификации/чекер] = max(A.Работник)
				, ВремяЗатрачено = max(A.ВремяЗатрачено)
				,A.ТипКлиента
			FROM #details_KD AS A
				INNER JOIN #t_Autoapprove AS U
					ON U.[Номер заявки] = A.[Номер заявки]
					AND U.Статус = 'Контроль данных'
			WHERE 1=1
				AND NOT EXISTS(
					SELECT TOP(1) 1 FROM #t_Autoapprove AS U
					WHERE U.[Номер заявки] = A.[Номер заявки]
						AND U.Статус = 'Верификация клиента'
				)
			GROUP BY
				cast(U.[Дата статуса] as date)
				, U.[Дата статуса]
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				,A.ТипКлиента

			UNION 
			--Уникальное количество заявок autoapprove КД, получивших финальное одобрение
			--заявки, по которым только на статусе КД был флаг skipped И которые получили финальное одобрение
			SELECT 
				[status] = 'Autoapprove_KD_fin_appr' 
				, Дата = cast(U.[Дата статуса] as date) 
				, ДатаИВремяСтатуса = U.[Дата статуса] 
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				, Сотрудник = max(A.Работник_Пред) --Работник_След
				, [ФИО сотрудника верификации/чекер] = max(A.Работник)
				, ВремяЗатрачено = max(A.ВремяЗатрачено)
				,A.ТипКлиента
			FROM #details_KD AS A
				--финальное одобрение
				INNER JOIN #t_final_approved AS Y ON Y.[Номер заявки] = A.[Номер заявки]
				--
				INNER JOIN #t_Autoapprove AS U
					ON U.[Номер заявки] = A.[Номер заявки]
					AND U.Статус = 'Контроль данных'
			WHERE 1=1
				AND NOT EXISTS(
					SELECT TOP(1) 1 FROM #t_Autoapprove AS U
					WHERE U.[Номер заявки] = A.[Номер заявки]
						AND U.Статус = 'Верификация клиента'
				)
			GROUP BY
				cast(U.[Дата статуса] as date)
				, U.[Дата статуса]
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				,A.ТипКлиента


			UNION 
			--Уникальное количество заявок autoapprove ВК
			--заявки, по которым только на статусе ВК был флаг skipped
			SELECT 
				[status] = 'Autoapprove_VK' 
				, Дата = cast(U.[Дата статуса] as date) 
				, ДатаИВремяСтатуса = U.[Дата статуса] 
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				, Сотрудник = max(A.Работник_Пред) --Работник_След
				, [ФИО сотрудника верификации/чекер] = max(A.Работник)
				, ВремяЗатрачено = max(A.ВремяЗатрачено)
				,A.ТипКлиента
			FROM #details_KD AS A
				INNER JOIN #t_Autoapprove AS U
					ON U.[Номер заявки] = A.[Номер заявки]
					AND U.Статус = 'Верификация клиента'
			WHERE 1=1
				AND NOT EXISTS(
					SELECT TOP(1) 1 FROM #t_Autoapprove AS U
					WHERE U.[Номер заявки] = A.[Номер заявки]
						AND U.Статус = 'Контроль данных'
				)
			GROUP BY
				cast(U.[Дата статуса] as date)
				, U.[Дата статуса]
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				,A.ТипКлиента

			UNION 
			--Уникальное количество заявок autoapprove ВК, получивших финальное одобрение
			--заявки, по которым только на статусе ВК был флаг skipped И которые получили финальное одобрение
			SELECT 
				[status] = 'Autoapprove_VK_fin_appr' 
				, Дата = cast(U.[Дата статуса] as date) 
				, ДатаИВремяСтатуса = U.[Дата статуса] 
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				, Сотрудник = max(A.Работник_Пред) --Работник_След
				, [ФИО сотрудника верификации/чекер] = max(A.Работник)
				, ВремяЗатрачено = max(A.ВремяЗатрачено)
				,A.ТипКлиента
			FROM #details_KD AS A
				--финальное одобрение
				INNER JOIN #t_final_approved AS Y ON Y.[Номер заявки] = A.[Номер заявки]
				--
				INNER JOIN #t_Autoapprove AS U
					ON U.[Номер заявки] = A.[Номер заявки]
					AND U.Статус = 'Верификация клиента'
			WHERE 1=1
				AND NOT EXISTS(
					SELECT TOP(1) 1 FROM #t_Autoapprove AS U
					WHERE U.[Номер заявки] = A.[Номер заявки]
						AND U.Статус = 'Контроль данных'
				)
			GROUP BY
				cast(U.[Дата статуса] as date)
				, U.[Дата статуса]
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				,A.ТипКлиента


			UNION 
			--Уникальное количество заявок autoapprove КД + ВК
			--заявки, по которым и на статусе КД, и на статусе ВК был флаг skipped
			SELECT 
				[status] = 'Autoapprove_KD_VK' 
				, Дата = cast(U.[Дата статуса] as date) 
				, ДатаИВремяСтатуса = U.[Дата статуса] 
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				, Сотрудник = max(A.Работник_Пред) --Работник_След
				, [ФИО сотрудника верификации/чекер] = max(A.Работник)
				, ВремяЗатрачено = max(A.ВремяЗатрачено)
				,A.ТипКлиента
			FROM #details_KD AS A
				INNER JOIN #t_Autoapprove AS U
					ON U.[Номер заявки] = A.[Номер заявки]
					AND U.Статус = 'Контроль данных'
				--
				INNER JOIN #t_Autoapprove AS U2
					ON U2.[Номер заявки] = A.[Номер заявки]
					AND U2.Статус = 'Верификация клиента'
			WHERE 1=1
			GROUP BY
				cast(U.[Дата статуса] as date)
				, U.[Дата статуса]
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				,A.ТипКлиента

			UNION 
			--Уникальное количество заявок autoapprove КД + ВК, получивших финальное одобрение
			--заявки, по которым и на статусе КД, и на статусе ВК был флаг skipped И которые получили финальное одобрение
			SELECT 
				[status] = 'Autoapprove_KD_VK_fin_appr' 
				, Дата = cast(U.[Дата статуса] as date) 
				, ДатаИВремяСтатуса = U.[Дата статуса] 
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				, Сотрудник = max(A.Работник_Пред) --Работник_След
				, [ФИО сотрудника верификации/чекер] = max(A.Работник)
				, ВремяЗатрачено = max(A.ВремяЗатрачено)
				,A.ТипКлиента
			FROM #details_KD AS A
				--финальное одобрение
				INNER JOIN #t_final_approved AS Y ON Y.[Номер заявки] = A.[Номер заявки]
				--
				INNER JOIN #t_Autoapprove AS U
					ON U.[Номер заявки] = A.[Номер заявки]
					AND U.Статус = 'Контроль данных'
				--
				INNER JOIN #t_Autoapprove AS U2
					ON U2.[Номер заявки] = A.[Номер заявки]
					AND U2.Статус = 'Верификация клиента'
			WHERE 1=1
			GROUP BY
				cast(U.[Дата статуса] as date)
				, U.[Дата статуса]
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				,A.ТипКлиента



			UNION 
			--Уникальное количество заявок autoapprove (всего)
			--= (Уникальное количество заявок autoapprove КД + Уникальное количество заявок autoapprove ВК + Уникальное количество заявок autoapprove КД + ВК). 
			SELECT 
				[status] = 'Autoapprove_KD_VK_total' 
				, Дата = cast(isnull(U.[Дата статуса], U2.[Дата статуса]) as date) 
				, ДатаИВремяСтатуса = isnull(U.[Дата статуса], U2.[Дата статуса])
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				, Сотрудник = max(A.Работник_Пред) --Работник_След
				, [ФИО сотрудника верификации/чекер] = max(A.Работник)
				, ВремяЗатрачено = max(A.ВремяЗатрачено)
				,A.ТипКлиента
			FROM #details_KD AS A
				LEFT JOIN #t_Autoapprove AS U
					ON U.[Номер заявки] = A.[Номер заявки]
					AND U.Статус = 'Контроль данных'
				--
				LEFT JOIN #t_Autoapprove AS U2
					ON U2.[Номер заявки] = A.[Номер заявки]
					AND U2.Статус = 'Верификация клиента'
			WHERE 1=1
				AND isnull(U.[Номер заявки], U2.[Номер заявки]) IS NOT NULL
			GROUP BY
				cast(isnull(U.[Дата статуса], U2.[Дата статуса]) as date) 
				, isnull(U.[Дата статуса], U2.[Дата статуса])
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				,A.ТипКлиента

			UNION 
			--Уникальное количество заявок autoapprove (всего), получивших финальное одобрение
			--= (Уникальное количество заявок autoapprove КД + Уникальное количество заявок autoapprove ВК + Уникальное количество заявок autoapprove КД + ВК). Считать только заявки, получившие финальное одобрение
			SELECT 
				[status] = 'Autoapprove_KD_VK_total_fin_appr' 
				, Дата = cast(isnull(U.[Дата статуса], U2.[Дата статуса]) as date) 
				, ДатаИВремяСтатуса = isnull(U.[Дата статуса], U2.[Дата статуса])
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				, Сотрудник = max(A.Работник_Пред) --Работник_След
				, [ФИО сотрудника верификации/чекер] = max(A.Работник)
				, ВремяЗатрачено = max(A.ВремяЗатрачено)
				,A.ТипКлиента
			FROM #details_KD AS A
				--финальное одобрение
				INNER JOIN #t_final_approved AS Y ON Y.[Номер заявки] = A.[Номер заявки]
				--
				LEFT JOIN #t_Autoapprove AS U
					ON U.[Номер заявки] = A.[Номер заявки]
					AND U.Статус = 'Контроль данных'
				--
				LEFT JOIN #t_Autoapprove AS U2
					ON U2.[Номер заявки] = A.[Номер заявки]
					AND U2.Статус = 'Верификация клиента'
			WHERE 1=1
				AND isnull(U.[Номер заявки], U2.[Номер заявки]) IS NOT NULL
			GROUP BY
				cast(isnull(U.[Дата статуса], U2.[Дата статуса]) as date) 
				, isnull(U.[Дата статуса], U2.[Дата статуса])
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				,A.ТипКлиента
			------
			------
			UNION 
			--Уникальное количество заявок, поступивших на КД
			SELECT 
				[status] = 'KD_IN'
				, Дата = min(cast(A.[Дата статуса] as date))
				, ДатаИВремяСтатуса = min(A.[Дата статуса])
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				, Сотрудник = max(A.Работник_Пред) --Работник_След
				, [ФИО сотрудника верификации/чекер] = max(A.Работник)
				, ВремяЗатрачено = max(A.ВремяЗатрачено)
				,A.ТипКлиента
			FROM #details_KD AS A
			WHERE 1=1
				AND A.Статус = 'Контроль данных'
			GROUP BY
				A.[ФИО клиента]
				, A.[Номер заявки] 
				,A.ТипКлиента

			UNION 
			--Уникальное количество заявок, поступивших на КД, получивших финальное одобрение
			SELECT 
				[status] = 'KD_IN_fin_appr'
				, Дата = min(cast(A.[Дата статуса] as date))
				, ДатаИВремяСтатуса = min(A.[Дата статуса])
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				, Сотрудник = max(A.Работник_Пред) --Работник_След
				, [ФИО сотрудника верификации/чекер] = max(A.Работник)
				, ВремяЗатрачено = max(A.ВремяЗатрачено)
				,A.ТипКлиента
			FROM #details_KD AS A
				--финальное одобрение
				INNER JOIN #t_final_approved AS Y ON Y.[Номер заявки] = A.[Номер заявки]
			WHERE 1=1
				AND A.Статус = 'Контроль данных'
			GROUP BY
				A.[ФИО клиента]
				, A.[Номер заявки] 
				,A.ТипКлиента
			-----

			UNION 
			--Уникальное количество заявок, поступивших на ВК
			SELECT 
				[status] = 'VK_IN'
				, Дата = min(cast(A.[Дата статуса] as date))
				, ДатаИВремяСтатуса = min(A.[Дата статуса])
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				, Сотрудник = max(A.Работник_Пред) --Работник_След
				, [ФИО сотрудника верификации/чекер] = max(A.Работник)
				, ВремяЗатрачено = max(A.ВремяЗатрачено)
				,A.ТипКлиента
			FROM #details_KD AS A
			WHERE 1=1
				AND A.Статус = 'Верификация клиента'
			GROUP BY
				A.[ФИО клиента]
				, A.[Номер заявки] 
				,A.ТипКлиента

			UNION 
			--Уникальное количество заявок, поступивших на ВК, получивших финальное одобрение
			SELECT 
				[status] = 'VK_IN_fin_appr'
				, Дата = min(cast(A.[Дата статуса] as date))
				, ДатаИВремяСтатуса = min(A.[Дата статуса])
				, A.[ФИО клиента]
				, A.[Номер заявки] 
				, Сотрудник = max(A.Работник_Пред) --Работник_След
				, [ФИО сотрудника верификации/чекер] = max(A.Работник)
				, ВремяЗатрачено = max(A.ВремяЗатрачено)
				,A.ТипКлиента
			FROM #details_KD AS A
				--финальное одобрение
				INNER JOIN #t_final_approved AS Y ON Y.[Номер заявки] = A.[Номер заявки]
			WHERE 1=1
				AND A.Статус = 'Верификация клиента'
			GROUP BY
				A.[ФИО клиента]
				, A.[Номер заявки] 
				,A.ТипКлиента

	ALTER TABLE #fedor_verificator_report
	ADD ProductType_Code varchar(30) NULL

	UPDATE F
	SET ProductType_Code = R.ProductType_Code
	FROM #fedor_verificator_report AS F
		INNER JOIN (
				SELECT DISTINCT D.ProductType_Code, D.[Номер заявки] 
				FROM #t_dm_FedorVerificationRequests_without_coll AS D
			) AS R
			ON R.[Номер заявки] = F.[Номер заявки]

	--!?
	--сумма по всем Типам продукта
	INSERT #fedor_verificator_report(
		status,
		Дата,
		ДатаИВремяСтатуса,
		[ФИО клиента],
		[Номер заявки],
		Сотрудник,
		[ФИО сотрудника верификации/чекер],
		ВремяЗатрачено,
		ТипКлиента,
		ProductType_Code
	)
	SELECT 
		F.status,
		F.Дата,
		F.ДатаИВремяСтатуса,
		F.[ФИО клиента],
		F.[Номер заявки],
		F.Сотрудник,
		F.[ФИО сотрудника верификации/чекер],
		F.ВремяЗатрачено,
		F.ТипКлиента,
		ProductType_Code = 'ALL'
	FROM #fedor_verificator_report AS F

        
        --select * from  #fedor_verificator_report where дата='20200922' and status like 'до%'
    CREATE NONCLUSTERED INDEX ix_ДатаИВремяСтатуса
		ON #fedor_verificator_report([ДатаИВремяСтатуса])
	INCLUDE ([status],[Дата],[Номер заявки],[Сотрудник], ProductType_Code)

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##fedor_verificator_report
			SELECT * INTO ##fedor_verificator_report FROM #fedor_verificator_report
		END



        drop table if exists #ReportByEmployeeAgg
        ;
        with c1 as (
          select 
				ProductType_Code
				, Дата
               , Сотрудник
               , isnull(sum(case when status in ('Новая_Уникальная') then 1 else 0 end),0) Новая_Уникальная --DWH-2021

				--DWH-2286
               , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Первичный' then 1 else 0 end),0) [Новая_Уникальная Первичный]
               , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Повторный' then 1 else 0 end),0) [Новая_Уникальная Повторный]
               , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Докредитование' then 1 else 0 end),0) [Новая_Уникальная Докредитование]
               , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента IS NULL then 1 else 0 end),0) [Новая_Уникальная Не определен]

               , isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая

               , isnull(sum(case when status in ('ВК','Отказано','Не вернувшиеся с доработки') then 1 else 0 end),0) [ИтогоПоСотруднику]

               , isnull(sum(case when status='ВК' then 1 else 0 end),0) [ВК]

               , isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]

               , isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]

               , isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
               , isnull(count( distinct case when status='Отложена' then  [Номер заявки] end), 0) [Отложено уникальных]
               , isnull(count( distinct case when status='Доработка' then [Номер заявки] end), 0) [Доработка уникальных]

               , isnull(sum(case when status='Не вернувшиеся с доработки' then 1 else 0 end ),0) [Не вернувшиеся с доработки]
			   --DWH-2209
               --, isnull(sum(case when status='Autoapprove' then 1 else 0 end),0) AS Autoapprove
			   --DWH-2374
               , isnull(sum(case when status='Autoapprove_KD' then 1 else 0 end),0) AS Autoapprove_KD
               , isnull(sum(case when status='Autoapprove_KD_fin_appr' then 1 else 0 end),0) AS Autoapprove_KD_fin_appr

               , isnull(sum(case when status='Autoapprove_VK' then 1 else 0 end),0) AS Autoapprove_VK
               , isnull(sum(case when status='Autoapprove_VK_fin_appr' then 1 else 0 end),0) AS Autoapprove_VK_fin_appr

               , isnull(sum(case when status='Autoapprove_KD_VK' then 1 else 0 end),0) AS Autoapprove_KD_VK
               , isnull(sum(case when status='Autoapprove_KD_VK_fin_appr' then 1 else 0 end),0) AS Autoapprove_KD_VK_fin_appr

               , isnull(sum(case when status='Autoapprove_KD_VK_total' then 1 else 0 end),0) AS Autoapprove_KD_VK_total
               , isnull(sum(case when status='Autoapprove_KD_VK_total_fin_appr' then 1 else 0 end),0) AS Autoapprove_KD_VK_total_fin_appr

               , isnull(sum(case when status='KD_IN' then 1 else 0 end),0) AS KD_IN
               , isnull(sum(case when status='KD_IN_fin_appr' then 1 else 0 end),0) AS KD_IN_fin_appr

               , isnull(sum(case when status='VK_IN' then 1 else 0 end),0) AS VK_IN
               , isnull(sum(case when status='VK_IN_fin_appr' then 1 else 0 end),0) AS VK_IN_fin_appr

            from #fedor_verificator_report
           group by ProductType_Code, Дата, Сотрудник
        )
        ,c2 as (
           
           select 
				ProductType_Code
				, [ФИО сотрудника верификации/чекер]
                , дата
                , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 

                , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end) ВремяЗатрачено 
                , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end) avgВремяЗатрачено 
           from  #fedor_verificator_report
           group by ProductType_Code, [ФИО сотрудника верификации/чекер], дата
        )
          select c1.*
               , isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
               , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
               , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
            into #ReportByEmployeeAgg
            from c1 
            left join c2 
				ON c1.ProductType_Code = c2.ProductType_Code
				AND c1.Дата=c2.Дата 
				AND c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##ReportByEmployeeAgg
			SELECT * INTO ##ReportByEmployeeAgg FROM #ReportByEmployeeAgg
		END

		/*
			--для последнего часа
        drop table if exists #ReportByEmployeeAgg_LastHour
        ;
        with c1 as (
          select Дата
               , Сотрудник
               , isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
               , isnull(sum(case when status in ('ВК','Отказано','Не вернувшиеся с доработки') then 1 else 0 end),0) ИтогоПоСотруднику
               , isnull(sum(case when status='ВК' then 1 else 0 end),0) [ВК]
               , isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]
               , isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]
               , isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
               , isnull(count( distinct case when status='Отложена' then  [Номер заявки] end),0) [Отложено уникальных]
               , isnull(count( distinct case when status='Доработка' then [Номер заявки] end ),0) [Доработка уникальных]
            from #fedor_verificator_report
			where ДатаИВремяСтатуса>=dateadd(hh ,-1 ,getdate()) 
           group by Дата
               , Сотрудник
        )
        ,c2 as (
           
           select [ФИО сотрудника верификации/чекер]
                , дата
                , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
                , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
                , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
           from  #fedor_verificator_report
		   where ДатаИВремяСтатуса>=dateadd(hh ,-1 ,getdate()) 
           group by  [ФИО сотрудника верификации/чекер],дата
        )
          select c1.*
               , isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
               , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
               , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
            into #ReportByEmployeeAgg_LastHour
            from c1 
            left join c2 on c1.Дата=c2.Дата and c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]
        */

		-- аггрегация за месяц       
		drop table if exists #ReportByEmployeeAgg_m

        ;
        with c1 as (
          select 
				ProductType_Code
				, format(Дата,'yyyyMM01') Дата
               , Сотрудник
               , isnull(sum(case when status in ('ВК','Отказано','Не вернувшиеся с доработки') then 1 else 0 end),0) ИтогоПоСотруднику
               , isnull(sum(case when status='ВК' then 1 else 0 end),0) [ВК]
               , isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]
               , isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]
               , isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
               , isnull(count( distinct case when status='Отложена' then  [Номер заявки] end),0) [Отложено уникальных]
               , isnull(count( distinct case when status='Доработка' then [Номер заявки] end ),0) [Доработка уникальных]
            from #fedor_verificator_report
           group by ProductType_Code, format(Дата,'yyyyMM01'), Сотрудник
        )
        ,c2 as (
           
           select ProductType_Code
				, [ФИО сотрудника верификации/чекер]
                , format(Дата,'yyyyMM01') дата
                , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
                , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
                , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
           from  #fedor_verificator_report
           group by ProductType_Code, [ФИО сотрудника верификации/чекер],format(Дата,'yyyyMM01')
        )
          select c1.*
               , isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
               , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
               , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
            into #ReportByEmployeeAgg_m
            from c1 
				LEFT JOIN c2 
					ON c1.ProductType_Code = c2.ProductType_Code
					AND c1.Дата=c2.Дата 
					AND c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]
        
		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##ReportByEmployeeAgg_m
			SELECT * INTO ##ReportByEmployeeAgg_m FROM #ReportByEmployeeAgg_m
		END
                

		/*	  
	    if @Page = 'fedor_verificator_report'
        begin
			select 'KD' stage, stage_status='All',*,[Время, час:мин:сек] = '2000-01-01 00:22:35.000'   from #fedor_verificator_report

			RETURN 0
        end
		*/

        /*
        if @Page = 'ReportByEmployeeAgg'
        begin
          select 
		         StageName = 'KD'
		       , Дата		       
               , Сотрудник
               , Новая
			   , ИтогоПоСотруднику
               , [Special] = ВК
               , Доработка
               , Отказано
               , Отложена
               , КоличествоЗаявок
               , ВремяЗатрачено
               , AvgВремяЗатрачено
               , [Отложено уникальных]
               , [Доработка уникальных]
			  -- into devdb.dbo.ReportByEmployeeAgg_KD
          from #ReportByEmployeeAgg
         order by 1,2

			RETURN 0
        
        end
		*/
      

	  --#ReportByEmployeeAgg_LastHour
		/*
	    if @Page = 'ReportByEmployeeAgg_LastHour'
        begin
          select  StageName = 'KD_LastHour'
		       , Дата		       
               , Сотрудник
               , Новая
			   , ИтогоПоСотруднику
               , [Special] = ВК
               , Доработка
               , Отказано
               , Отложена
               , КоличествоЗаявок
               , ВремяЗатрачено
               , AvgВремяЗатрачено
               , [Отложено уникальных]
               , [Доработка уникальных]
			  -- into devdb.dbo.ReportByEmployeeAgg_KD
          from #ReportByEmployeeAgg_LastHour
         order by 1,2
        
			RETURN 0
        end
        */
        
        
        
        --
        -- Аггрегированные данные
        --
          
        
        --select * from #employee_rows_d
        
        
-- подневная аггрегация        
         drop table if exists #KDEmployees

		/*
		--var 1
          select distinct acc_period 
               , empl_id 
               , Employee 
               , [Status] 
            into #KDEmployees
            from #employee_rows_d 
           where [Status] in ('Контроль данных') 
             and Employee in (select * from #curr_employee_cd)
		*/
			--var 2
			select distinct 
				PT.ProductType_Code
				, acc_period 
				, empl_id 
				, Employee 
				, [Status] 
			into #KDEmployees
			from #employee_rows_d AS E
				INNER JOIN #t_ProductType AS PT
					ON 1=1
			where [Status] in ('Контроль данных') 
			and Employee in (select * from #curr_employee_cd)

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##KDEmployees
				SELECT * INTO ##KDEmployees FROM #KDEmployees
			END

--помесячная аггрегация             
         drop table if exists #KDEmployees_m
		/*
		--var 1         
          select distinct acc_period 
               , empl_id 
               , Employee 
               , [Status] 
            into #KDEmployees_m
            from #employee_rows_m
           where [Status] in ('Контроль данных') 
             and Employee in (select * from #curr_employee_cd)
        */
			--var 2
			select DISTINCT
				PT.ProductType_Code	
				, acc_period 
				, empl_id 
				, Employee 
				, [Status] 
			into #KDEmployees_m
			from #employee_rows_m
				INNER JOIN #t_ProductType AS PT
					ON 1=1
			where [Status] in ('Контроль данных') 
				and Employee in (select * from #curr_employee_cd)

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##KDEmployees_m
				SELECT * INTO ##KDEmployees_m FROM #KDEmployees_m
			END


        --- КД. Общее кол-во по дням 
        
		IF @Page = 'KD.Daily.Total' OR @isFill_All_Tables = 1 --19
        BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Total
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Total AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на этапе' Indicator
						, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Total
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
						, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Total
				from agg
				UNION all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator
						, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на этапе' Indicator
					, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #KDEmployees e
				left join #ReportByEmployeeAgg a ON e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Total
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, isnull(A.КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Total
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				UNION all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.КоличествоЗаявок ),0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.Total', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на этапе' Indicator
						, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				from agg
				UNION all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator
						, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на этапе' Indicator
					, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #KDEmployees e
				left join #ReportByEmployeeAgg a ON e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, isnull(A.КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Total
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				UNION all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.КоличествоЗаявок ),0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
        --// 'KD.Daily.Total'

		IF @Page = 'KD.Monthly.Total' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Total
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Total AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select 
					empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на этапе' Indicator
						, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Total
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Total
				from agg
				UNION ALL
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator
					, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на этапе' Indicator
					, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #KDEmployees_m AS e
				left join #ReportByEmployeeAgg_m AS a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Total
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма = isnull(A.КоличествоЗаявок,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, Сумма = isnull(sum(A.КоличествоЗаявок ) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.Total', @ProcessGUID
			END
			ELSE BEGIN
				/*
				-- var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на этапе' Indicator
						, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator
						, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на этапе' Indicator
					, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #KDEmployees_m AS e
				left join #ReportByEmployeeAgg_m AS a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма = isnull(A.КоличествоЗаявок,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, Сумма = isnull(sum(A.КоличествоЗаявок ) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
         --// 'KD.Monthly.Total'         
        
        
        --Уникальное кол-во заявок на этапе
		IF @Page = 'KD.Daily.Unic' OR @isFill_All_Tables = 1 --2403
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Unic
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Unic AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во заявок на этапе' Indicator
						, isnull(ИтогоПоСотруднику ,0) ИтогоПоСотруднику 
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Unic
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(ИтогоПоСотруднику,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Unic
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(ИтогоПоСотруднику ),0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во заявок на этапе' Indicator
					, isnull(ИтогоПоСотруднику ,0) ИтогоПоСотруднику 
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Unic
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, isnull(A.ИтогоПоСотруднику,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Unic
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, Сумма = isnull(sum(A.ИтогоПоСотруднику ),0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.Unic', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во заявок на этапе' Indicator
						, isnull(ИтогоПоСотруднику ,0) ИтогоПоСотруднику 
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, isnull(ИтогоПоСотруднику,0) Сумма
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(ИтогоПоСотруднику ),0)
				from agg
				group by dt, indicator
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во заявок на этапе' Indicator
					, isnull(ИтогоПоСотруднику ,0) ИтогоПоСотруднику 
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, isnull(A.ИтогоПоСотруднику,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Unic
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, Сумма = isnull(sum(A.ИтогоПоСотруднику ),0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'KD.Daily.Unic'

		-- monthly        
		IF @Page = 'KD.Monthly.Unic' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Unic
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Unic AS T
				WHERE T.ProcessGUID = @ProcessGUID

				;with agg as (
				SELECT
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во заявок на этапе' Indicator
					, isnull(ИтогоПоСотруднику ,0) ИтогоПоСотруднику 
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Unic
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, isnull(A.ИтогоПоСотруднику,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Unic
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee		='ИТОГО' 
					, A.dt 
					, A.indicator 
					, isnull(sum(A.ИтогоПоСотруднику ),0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.Unic', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во заявок на этапе' Indicator
						, isnull(ИтогоПоСотруднику ,0) ИтогоПоСотруднику 
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, isnull(ИтогоПоСотруднику,0) Сумма
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(ИтогоПоСотруднику ),0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				SELECT
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во заявок на этапе' Indicator
					, isnull(ИтогоПоСотруднику ,0) ИтогоПоСотруднику 
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, isnull(A.ИтогоПоСотруднику,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Unic
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee		='ИТОГО' 
					, A.dt 
					, A.indicator 
					, isnull(sum(A.ИтогоПоСотруднику ),0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'KD.Monthly.Unic'        
        
          
		IF @Page = 'KD.Daily.AvgTime' OR @isFill_All_Tables = 1 --2403
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AvgTime
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AvgTime AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
						, 'Среднее время по заявке (общие)' Indicator
						, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AvgTime
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					,  Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AvgTime
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					,  isnull(convert(nvarchar,cast((case when sum(КоличествоЗаявок)<> 0 then sum(ВремяЗатрачено)/sum(КоличествоЗаявок) else 0 end) as datetime),8)  ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
						, 'Среднее время по заявке (общие)' Indicator
						, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AvgTime
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					,  Сумма=isnull(convert(nvarchar, cast(A.Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AvgTime
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(convert(nvarchar,cast((case when sum(A.КоличествоЗаявок)<> 0 then sum(A.ВремяЗатрачено)/sum(A.КоличествоЗаявок) else 0 end) as datetime),8)  ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.AvgTime', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
						, 'Среднее время по заявке (общие)' Indicator
						, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					,  Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						,  isnull(convert(nvarchar,cast((case when sum(КоличествоЗаявок)<> 0 then sum(ВремяЗатрачено)/sum(КоличествоЗаявок) else 0 end) as datetime),8)  ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
						, 'Среднее время по заявке (общие)' Indicator
						, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					,  Сумма=isnull(convert(nvarchar, cast(A.Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AvgTime
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(convert(nvarchar,cast((case when sum(A.КоличествоЗаявок)<> 0 then sum(A.ВремяЗатрачено)/sum(A.КоличествоЗаявок) else 0 end) as datetime),8)  ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'KD.Daily.AvgTime'

		-- monthly
		IF @Page = 'KD.Monthly.AvgTime' OR @isFill_All_Tables = 1 --2403
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AvgTime
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AvgTime AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
						, 'Среднее время по заявке (общие)' Indicator
						, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AvgTime
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					,  Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AvgTime
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, CASE WHEN sum(КоличествоЗаявок) <> 0
						THEN cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
						ELSE '0'
					  END
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
						, 'Среднее время по заявке (общие)' Indicator
						, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #KDEmployees_m AS e
				left join #ReportByEmployeeAgg_m AS a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AvgTime
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					,  Сумма=isnull(convert(nvarchar(50), cast(A.Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AvgTime
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee		='ИТОГО' 
					, A.dt 
					, A.indicator 
					, CASE WHEN sum(A.КоличествоЗаявок) <> 0
						THEN cast(isnull(convert(nvarchar(50),cast((sum(A.ВремяЗатрачено)/sum(A.КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
						ELSE '0'
					  END
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.AvgTime', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
						, 'Среднее время по заявке (общие)' Indicator
						, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					,  Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, CASE WHEN sum(КоличествоЗаявок) <> 0
							THEN cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
							ELSE '0'
						  END
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
						, 'Среднее время по заявке (общие)' Indicator
						, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #KDEmployees_m AS e
				left join #ReportByEmployeeAgg_m AS a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					,  Сумма=isnull(convert(nvarchar(50), cast(A.Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AvgTime
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee		='ИТОГО' 
					, A.dt 
					, A.indicator 
					, CASE WHEN sum(A.КоличествоЗаявок) <> 0
						THEN cast(isnull(convert(nvarchar(50),cast((sum(A.ВремяЗатрачено)/sum(A.КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
						ELSE '0'
					  END
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
        --// 'KD.Monthly.AvgTime'
           
		IF @Page = 'KD.Daily.Approved' OR @isFill_All_Tables = 1 --21
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Approved
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Approved AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Кол-во одобренных заявок после этапа' Indicator
						, [ВК]  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Approved
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Approved
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Кол-во одобренных заявок после этапа' Indicator
					, [ВК]  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Approved
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Approved
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, Сумма = isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.Approved', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Кол-во одобренных заявок после этапа' Indicator
						, [ВК]  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Кол-во одобренных заявок после этапа' Indicator
					, [ВК]  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, Сумма = isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'KD.Daily.Approved'

		--Monthly
		IF @Page = 'KD.Monthly.Approved' OR @isFill_All_Tables = 1 --21
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Approved
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Approved AS T
				WHERE T.ProcessGUID = @ProcessGUID
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Кол-во одобренных заявок после этапа' Indicator
						, [ВК]  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Approved
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Approved
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Кол-во одобренных заявок после этапа' Indicator
					, [ВК]  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Approved
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма = isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Approved
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, Сумма = isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.Approved', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Кол-во одобренных заявок после этапа' Indicator
						, [ВК]  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Кол-во одобренных заявок после этапа' Indicator
					, [ВК]  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма = isnull(A.Сумма,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, Сумма = isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'KD.Monthly.Approved'
        
		-- 'Общее кол-во отложенных заявок на этапе'
		IF @Page = 'KD.Daily.Postpone' OR @isFill_All_Tables = 1 --2401
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Postpone
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Postpone AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Postpone
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Postpone
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во отложенных заявок на этапе' Indicator
					, Отложена  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Postpone
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Postpone
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.Postpone', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во отложенных заявок на этапе' Indicator
					, Отложена  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Postpone
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'KD.Daily.Postpone'


		-- 'Уникальное кол-во отложенных заявок на этапе'
		IF @Page = 'KD.Daily.PostponeUnique' OR @isFill_All_Tables = 1 --2401
		BEGIN

			DROP table if exists #fedor_verificator_report_KD_Unique

			SELECT
				ProductType_Code
				, Дата
               , Сотрудник              
               , isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальные]
            into #fedor_verificator_report_KD_Unique
            from #fedor_verificator_report
			GROUP BY ProductType_Code, Дата, Сотрудник


			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_PostponeUnique
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_PostponeUnique AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во отложенных заявок на этапе' Indicator
						, [ОтложенаУникальные]  Сумма
				from #KDEmployees e
				left join #fedor_verificator_report_KD_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_PostponeUnique
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_PostponeUnique
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во отложенных заявок на этапе' Indicator
					, [ОтложенаУникальные]  Сумма
				from #KDEmployees e
				left join #fedor_verificator_report_KD_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_PostponeUnique
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_PostponeUnique
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.PostponeUnique', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во отложенных заявок на этапе' Indicator
						, [ОтложенаУникальные]  Сумма
				from #KDEmployees e
				left join #fedor_verificator_report_KD_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во отложенных заявок на этапе' Indicator
					, [ОтложенаУникальные]  Сумма
				from #KDEmployees e
				left join #fedor_verificator_report_KD_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_PostponeUnique
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'KD.Daily.PostponeUnique'

		--monthly       
		IF @Page = 'KD.Monthly.Postpone' OR @isFill_All_Tables = 1 --2401
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Postpone
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Postpone AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Postpone
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Postpone
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во отложенных заявок на этапе' Indicator
					, Отложена  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Postpone
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Postpone
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.Postpone', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во отложенных заявок на этапе' Indicator
					, Отложена  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Postpone
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'KD.Monthly.Postpone'
		
		--Monthly Unique
		IF @Page = 'KD.Monthly.PostponeUnique' OR @isFill_All_Tables = 1 --2401
		BEGIN

			DROP table if exists #ReportByEmployeeAgg_KD_m_Unique
			;
			with c1 as (
			  select 
					ProductType_Code
					, cast(format(Дата,'yyyyMM01') as date) Дата
				   , Сотрудник             
				   , isnull(count( distinct case when status='Отложена' then [Номер заявки]  end),0) [Отложена]               
				from #fedor_verificator_report
			   group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date), Сотрудник
			)
			select c1.*
               --, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
               --, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
               --, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
            into #ReportByEmployeeAgg_KD_m_Unique
            from c1 
            --left join c2 on c1.Дата=c2.Дата and c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]

        
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_PostponeUnique
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_PostponeUnique AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_KD_m_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_PostponeUnique
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_PostponeUnique
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во отложенных заявок на этапе' Indicator
					, Отложена  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_KD_m_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_PostponeUnique
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_PostponeUnique
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.PostponeUnique', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_KD_m_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во отложенных заявок на этапе' Indicator
					, Отложена  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_KD_m_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_PostponeUnique
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'KD.Monthly.PostponeUnique'
        
        
        -- Кол-во заявок на доработку
		IF @Page = 'KD.Daily.Rework' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Rework
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Rework AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на доработку на этапе' Indicator
						, Доработка  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Rework
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Rework
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на доработку на этапе' Indicator
					, Доработка  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Rework
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Rework
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, Сумма = isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.Rework', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на доработку на этапе' Indicator
						, Доработка  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на доработку на этапе' Indicator
					, Доработка  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, Сумма = isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'KD.Daily.Rework'
        
        
		IF @Page = 'KD.Monthly.Rework' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Rework
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Rework AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на доработку на этапе' Indicator
						, Доработка  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Rework
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Rework
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на доработку на этапе' Indicator
					, Доработка  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Rework
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Rework
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, Сумма = isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.Rework', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на доработку на этапе' Indicator
						, Доработка  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на доработку на этапе' Indicator
					, Доработка  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Rework
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, Сумма = isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'KD.Monthly.Rework'

        
		--- КД. Конвертация (одобренные / уникальные) по дням  Approval rate
		IF @Page = 'KD.Daily.AR' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AR
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AR AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select 
					empl_id
						, Employee		
						, acc_period  dt
						, 'AR на этапе' Indicator
					, ВК
					, ИтогоПоСотруднику
						, case when ИтогоПоСотруднику<>0 then ВК*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AR
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) *100
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AR
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(
						case when sum(  ИтогоПоСотруднику) <>0 then sum(ВК*1.0)/ sum(  ИтогоПоСотруднику) else 0 end 
						,0)  *100 Сумма
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'AR на этапе' Indicator
					, ВК
					, ИтогоПоСотруднику
					, case when ИтогоПоСотруднику<>0 then ВК*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AR
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0) *100
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_AR
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(
						case when sum(A.ИтогоПоСотруднику) <>0 then sum(A.ВК*1.0)/ sum(A.ИтогоПоСотруднику) else 0 end 
						,0)  *100 Сумма
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.AR', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'AR на этапе' Indicator
					, ВК
					, ИтогоПоСотруднику
						, case when ИтогоПоСотруднику<>0 then ВК*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) *100
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(
							case when sum(  ИтогоПоСотруднику) <>0 then sum(ВК*1.0)/ sum(  ИтогоПоСотруднику) else 0 end 
							,0)  *100 Сумма
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'AR на этапе' Indicator
					, ВК
					, ИтогоПоСотруднику
					, case when ИтогоПоСотруднику<>0 then ВК*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0) *100
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(
						case when sum(A.ИтогоПоСотруднику) <>0 then sum(A.ВК*1.0)/ sum(A.ИтогоПоСотруднику) else 0 end 
						,0)  *100 Сумма
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'KD.Daily.AR'

		IF @Page = 'KD.Monthly.AR' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AR
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AR AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'AR на этапе' Indicator
					, ВК
					, ИтогоПоСотруднику
						, case when ИтогоПоСотруднику<>0 then ВК*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AR
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) *100
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AR
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(
						case when sum(  ИтогоПоСотруднику) <>0 then sum(ВК*1.0)/ sum(  ИтогоПоСотруднику) else 0 end 
						,0)  *100 Сумма
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'AR на этапе' Indicator
					, ВК
					, ИтогоПоСотруднику
					, case when ИтогоПоСотруднику<>0 then ВК*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AR
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0) *100
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_AR
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(
						case when sum(A.ИтогоПоСотруднику) <>0 then sum(A.ВК*1.0)/ sum(A.ИтогоПоСотруднику) else 0 end 
						,0)  *100 Сумма
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.AR', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'AR на этапе' Indicator
					, ВК
					, ИтогоПоСотруднику
						, case when ИтогоПоСотруднику<>0 then ВК*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) *100
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(
							case when sum(  ИтогоПоСотруднику) <>0 then sum(ВК*1.0)/ sum(  ИтогоПоСотруднику) else 0 end 
							,0)  *100 Сумма
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'AR на этапе' Indicator
					, ВК
					, ИтогоПоСотруднику
					, case when ИтогоПоСотруднику<>0 then ВК*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0) *100
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(
						case when sum(A.ИтогоПоСотруднику) <>0 then sum(A.ВК*1.0)/ sum(A.ИтогоПоСотруднику) else 0 end 
						,0)  *100 Сумма
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'KD.Monthly.AR'

END
--// KD.%






------------------------------
--- Верификация клиента
------------------------------
-- VK.%
IF @Page IN (
	'VK.Daily.Total'
	,'VK.Daily.Unic'
	,'VK.Daily.AvgTime'
	,'VK.Daily.Approved'
	,'VK.Daily.Postpone'
	,'VK.Daily.PostponeUnique'
	,'VK.Daily.Rework'
	,'VK.Daily.AR'

	,'VK.Monthly.Total'
	,'VK.Monthly.Unic'
	,'VK.Monthly.AvgTime'
	,'VK.Monthly.Approved'
	,'VK.Monthly.Postpone'
	,'VK.Monthly.PostponeUnique'
	,'VK.Monthly.Rework'
	,'VK.Monthly.AR'

	,'V.Daily.Common'
	,'V.Monthly.Common'

	,'VK.HoursGroupMonth'
	, 'VK.HoursGroupMonthUnique'
	, 'VK.HoursGroupDays'
	, 'VK.HoursGroupDaysUnique'
	,'ReportByEmployee_VK'
	,'ReportByEmployeeAgg_VK'
	,'ReportByEmployeeAgg_VK_LastHour'
	, 'fedor_verificator_report_VK'

	,'V.Monthly.TTY'
	,'V.Daily.TTY'
) OR @isFill_All_Tables = 1
BEGIN

	DROP table if exists #VKEmployees

	/*
	--var 1
    select distinct acc_period 
        , empl_id 
        , Employee 
        , [Status] 
    into #VKEmployees
    from #employee_rows_d 
    where [Status] in ('Верификация клиента') 
        and Employee in (select * from #curr_employee_vr)
    */
	--var 2
    select distinct 
		PT.ProductType_Code
		, acc_period 
        , empl_id 
        , Employee 
        , [Status] 
    into #VKEmployees
    from #employee_rows_d 
		INNER JOIN #t_ProductType AS PT
			ON 1=1
    where [Status] in ('Верификация клиента') 
        and Employee in (select * from #curr_employee_vr)
	
	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##VKEmployees
		SELECT * INTO ##VKEmployees FROM #VKEmployees
	END

	drop table if exists #VKEmployees_m
	/*
	--var 1
    select distinct acc_period 
        , empl_id 
        , Employee 
        , [Status] 
    into #VKEmployees_m
    from #employee_rows_m 
    where [Status] in ('Верификация клиента') 
        and Employee in (select * from #curr_employee_vr)    
	*/
	--var 2
    select distinct 
		PT.ProductType_Code
		, acc_period 
        , empl_id 
        , Employee 
        , [Status] 
    into #VKEmployees_m
    from #employee_rows_m 
		INNER JOIN #t_ProductType AS PT
			ON 1=1
    where [Status] in ('Верификация клиента') 
        and Employee in (select * from #curr_employee_vr)    

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##VKEmployees_m
		SELECT * INTO ##VKEmployees_m FROM #VKEmployees_m
	END

        
        drop table if exists #fedor_verificator_report_VK
        
        drop table if exists #details_VK

         select * 
         into #details_VK
         from #t_dm_FedorVerificationRequests_without_coll /*#details*/
		 WHERE  1=1
		 AND (Работник not in (select * from #curr_employee_cd) --and  Статус in ('Верификация клиента') 
			OR Работник IN (select Employee from #curr_employee_vr) --DWH-1787
			)
		 --AND Работник IN (select Employee from #curr_employee_vr) --DWH-1988
         and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to

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
				[Stg].[_fedorUAT].[core_CheckListItem] cli 
				inner JOIN [Stg].[_fedorUAT].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
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
		FROM [Stg].[_fedorUAT].[core_CheckListItem] cli
			JOIN [Stg].[_fedorUAT].[dictionary_CheckListItemType] cit ON  cit.id = cli.IdType
			JOIN [Stg].[_fedorUAT].[dictionary_CheckListItemStatus] cis ON cis.id = cli.IdStatus
			JOIN loginom_checklists_rejects rl ON rl.IdClientRequest = cli.IdClientRequest 
				AND try_cast(replace(cis.LoginomNumber,'.','') AS bigint) = rl.logn
			INNER JOIN Stg._fedorUAT.core_ClientRequest AS CR
				ON CR.Id = cli.IdClientRequest
		WHERE EXISTS(SELECT TOP(1) 1 FROM #t_request_number AS R WHERE R.IdClientRequest = cli.IdClientRequest)



         ;
         with 
          rework as (
          
          select 'Доработка' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] 
               , [ФИО клиента]
               , [Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
				,ТипКлиента
            from #details_VK
           where Задача='task:Требуется доработка' and [Состояние заявки]='Отложена' and Статус in('Верификация клиента') 
          
          )
          ,rework1 as 
          (
          
          select 'Доработка' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса]
               , [ФИО клиента]
               , [Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_След -- Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
				,ТипКлиента
            from #details_VK
           where [Задача следующая]='task:Требуется доработка' and [Состояние заявки следующая]='Отложена' and Статус in('Верификация клиента') and ШагЗаявки= ПоследнийШаг
          
          )
        ,postpone1 as (
        
           select 'Отложена' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки]  
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
				,ТипКлиента
            from #details_VK
           where Задача='task:Отложена' and [Состояние заявки] in('Отложена') and Статус in('Верификация клиента') 
        )
              ,postpone as (
        
           select 'Отложена' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки]  
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
				,ТипКлиента
            from #details_VK
           where  [Задача следующая]='task:Отложена' and [Состояние заявки следующая] in('Отложена') and Статус in('Верификация клиента') and ШагЗаявки= ПоследнийШаг
        )
           -- доработка
          select [status]
               ,  Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки]  
               , Сотрудник
               , [ФИО сотрудника верификации/чекер]
               , ВремяЗатрачено 
				,ТипКлиента
            into #fedor_verificator_report_VK
            from rework
           union all 
          select [status]
               , Дата
               , [Дата статуса]
               , [ФИО клиента]
               , [Номер заявки]  
               , Сотрудник
               , [ФИО сотрудника верификации/чекер]
               , ВремяЗатрачено 
				,ТипКлиента
            from rework1
           union 
     select * from postpone
     union 
     select * from postpone1
        --select * from  #fedor_verificator_report_VK where  Дата='20200916'  order by 2 
           union 
        
		--отказано сотрудником
         select 'Отказано' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки]  
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
				,ТипКлиента
            from #details_VK AS N
           where [Статус следующий]='Отказано' and Статус in('Верификация Call 3')
				AND EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
            /*
         union
         select Статус 
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки]  
               , Сотрудник=СотрудникПоследнегоСтатуса
               , [ФИО сотрудника верификации/чекер]
               , ВремяЗатрачено
            from details_VK
          where  [Номер заявки]='20091600033895' 
            */
        
           -- select * from #t_dm_FedorVerificationRequests_without_coll where [Номер заявки]='20091600033794'  
        
           -- select * from  #fedor_verificator_report_VK where  status='Отказано' and  Дата='20200916' --[Номер заявки]='20091500033541' order by 3
          
           union 
         
          select 'VTS' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено 
				,ТипКлиента
            from #details_VK AS D
           --where [Статус следующий]='Одобрен клиент' and Статус in('Верификация Call 3')
		   --where [Статус следующий]='Одобрено' and Статус in('Верификация Call 3')
		   --DWH-2361
		   where (
				D.Статус in('Верификация Call 3')
			AND EXISTS(
					SELECT TOP(1) 1
					FROM #details_VK AS N
					WHERE D.[Номер заявки] = N.[Номер заявки]
						AND N.[Дата статуса] >= D.[Дата статуса]
						AND N.[Статус следующий] IN ('Одобрено', 'Предодобр перед Call 5')
				)
			)
			--DWH-2429 --одобрено сотрудником, но отказано автоматически
			OR (
				D.[Статус следующий]='Отказано' and D.Статус IN ('Верификация Call 3')
				AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = D.IdClientRequest)
			)
          
           union 
         
          select 'task:В работе' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]

			   --, Сотрудник=Работник_Пред --Работник_След
			   -- исправлено DWH-2457
			   , Сотрудник=Работник

               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
				,ТипКлиента
            from #details_VK
             where Задача='task:В работе'  and Статус in('Верификация клиента')
           union
          select 'Новая' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено 
				,ТипКлиента
            from #details_VK
           where Задача='task:Новая' and Статус in('Верификация клиента')

		   UNION
			select 'Заем выдан' [status]
				, cast([Дата статуса] as date) Дата
				, [Дата статуса] ДатаИВремяСтатуса
				, [ФИО клиента]
				, [Номер заявки] 
				--, Сотрудник=СотрудникПоследнегоСтатуса
				--, [ФИО сотрудника верификации/чекер]
				, Сотрудник=Работник_Пред --Работник_След
				, [ФИО сотрудника верификации/чекер] = Работник
				, ВремяЗатрачено 
				,ТипКлиента
			from #details_VK
			where [Статус следующий]='Заем выдан'

			--DWH-2021
		   UNION
          select 'Новая_Уникальная' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено 
				,ТипКлиента
            from #details_VK
           where Задача='task:Новая' and Статус in(
					'Верификация клиента',
					'Переподписание первого пакета' --DWH-2101
				)
				AND [Задача следующая] <> 'task:Автоматически отложено'

	ALTER TABLE #fedor_verificator_report_VK
	ADD ProductType_Code varchar(30) NULL

	UPDATE F
	SET ProductType_Code = R.ProductType_Code
	FROM #fedor_verificator_report_VK AS F
		INNER JOIN (
				SELECT DISTINCT D.ProductType_Code, D.[Номер заявки] 
				FROM #t_dm_FedorVerificationRequests_without_coll AS D
			) AS R
			ON R.[Номер заявки] = F.[Номер заявки]

	--!?
	--сумма по всем Типам продукта
	INSERT #fedor_verificator_report_VK(
		status,
		Дата,
		ДатаИВремяСтатуса,
		[ФИО клиента],
		[Номер заявки],
		Сотрудник,
		[ФИО сотрудника верификации/чекер],
		ВремяЗатрачено,
		ТипКлиента,
		ProductType_Code
	)
	SELECT 
		F.status,
		F.Дата,
		F.ДатаИВремяСтатуса,
		F.[ФИО клиента],
		F.[Номер заявки],
		F.Сотрудник,
		F.[ФИО сотрудника верификации/чекер],
		F.ВремяЗатрачено,
		F.ТипКлиента,
		ProductType_Code = 'ALL'
	FROM #fedor_verificator_report_VK AS F

    CREATE NONCLUSTERED INDEX ix_ДатаИВремяСтатуса
		ON #fedor_verificator_report_VK([ДатаИВремяСтатуса])
	INCLUDE ([status],[Дата],[Номер заявки],[Сотрудник], ProductType_Code)

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##fedor_verificator_report_VK
			SELECT * INTO ##fedor_verificator_report_VK FROM #fedor_verificator_report_VK
		END


            
        drop table if exists #ReportByEmployeeAgg_VK
        ;
        with c1 as (
          select ProductType_Code
				, Дата
               , Сотрудник
               , isnull(sum(case when status in ('VTS','Отказано') then 1 else 0 end),0) ИтогоПоСотруднику

               , isnull(sum(case when status='VTS' then 1 else 0 end),0) VTS

               , isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]

               , isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]

               , isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]

               , isnull(sum(case when status='Новая' then 1 else 0 end),0) Новая

               , isnull(sum(case when status in ('Новая_Уникальная') then 1 else 0 end),0) Новая_Уникальная --DWH-2021

				--DWH-2286
               , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Первичный' then 1 else 0 end),0) [Новая_Уникальная Первичный]
               , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Повторный' then 1 else 0 end),0) [Новая_Уникальная Повторный]
               , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Докредитование' then 1 else 0 end),0) [Новая_Уникальная Докредитование]
               , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента IS NULL then 1 else 0 end),0) [Новая_Уникальная Не определен]

			   --'Заем выдан'
               , isnull(sum(case when status='Заем выдан' then 1 else 0 end),0) [Заем выдан]

			   , isnull(count( distinct case when status='Отложена' then  [Номер заявки] end),0) [Отложено уникальных]
               , isnull(count( distinct case when status='Доработка' then [Номер заявки] end ),0) [Доработка уникальных]
            from #fedor_verificator_report_VK
           group by ProductType_Code, Дата, Сотрудник
        )
        ,c2 as (
           
           select 
				ProductType_Code
				, [ФИО сотрудника верификации/чекер]
                , дата
                , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
                , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
                , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
           from  #fedor_verificator_report_VK
           group by ProductType_Code, [ФИО сотрудника верификации/чекер], дата
        )
          select c1.*
               , isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
               , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
               , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
            into #ReportByEmployeeAgg_VK
            from c1 
            left join c2 
				ON c1.ProductType_Code = c2.ProductType_Code
				AND c1.Дата=c2.Дата 
				AND c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]

		--#ReportByEmployeeAgg_VK
		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##ReportByEmployeeAgg_VK
			SELECT * INTO ##ReportByEmployeeAgg_VK FROM #ReportByEmployeeAgg_VK
		END


		/*
        drop table if exists #ReportByEmployeeAgg_LastHour_VK
        ;
        with c1 as (
          select Дата
               , Сотрудник
               , isnull(sum(case when status in ('VTS','Отказано') then 1 else 0 end),0) ИтогоПоСотруднику
               , isnull(sum(case when status='VTS' then 1 else 0 end),0) VTS
               , isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]
               , isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]
               , isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
               , isnull(sum(case when status='Новая' then 1 else 0 end),0) Новая
			   , isnull(count( distinct case when status='Отложена' then  [Номер заявки] end),0) [Отложено уникальных]
               , isnull(count( distinct case when status='Доработка' then [Номер заявки] end ),0) [Доработка уникальных]
            from #fedor_verificator_report_VK
			where ДатаИВремяСтатуса>=dateadd(hh ,-1 ,getdate()) 
           group by Дата
               , Сотрудник
        )
        ,c2 as (
           
           select [ФИО сотрудника верификации/чекер]
                , дата
                , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
                , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
                , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
           from  #fedor_verificator_report_VK
		   where ДатаИВремяСтатуса>=dateadd(hh ,-1 ,getdate()) 
           group by  [ФИО сотрудника верификации/чекер],дата
        )
          select c1.*
               , isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
               , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
               , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
            into #ReportByEmployeeAgg_LastHour_VK
            from c1 
            left join c2 on c1.Дата=c2.Дата and c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]
		*/        
        
--monthly            
        drop table if exists #ReportByEmployeeAgg_VK_m
        ;
        with c1 as (
          select 
				ProductType_Code
				, cast(format(Дата,'yyyyMM01') as date) Дата
               , Сотрудник
               , isnull(sum(case when status in ('VTS','Отказано') then 1 else 0 end),0) ИтогоПоСотруднику
               , isnull(sum(case when status='VTS' then 1 else 0 end),0) VTS
               , isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]
               , isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]
               , isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
               , isnull(sum(case when status='Новая' then 1 else 0 end),0) Новая
            from #fedor_verificator_report_VK
           group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date), Сотрудник
        )
        ,c2 as (
           
           select ProductType_Code
				, [ФИО сотрудника верификации/чекер]
                , cast(format(Дата,'yyyyMM01') as date) дата
                , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
                , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
                , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
           from  #fedor_verificator_report_VK
           group by ProductType_Code, [ФИО сотрудника верификации/чекер],cast(format(Дата,'yyyyMM01') as date)
        )
          select c1.*
               , isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
               , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
               , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
            into #ReportByEmployeeAgg_VK_m
            from c1 
				LEFT JOIN c2 
					ON c1.ProductType_Code = c2.ProductType_Code
					AND c1.Дата=c2.Дата 
					AND c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##ReportByEmployeeAgg_VK_m
			SELECT * INTO ##ReportByEmployeeAgg_VK_m FROM #ReportByEmployeeAgg_VK_m
		END

-- считаем уникальных отложенных по верификации
        drop table if exists #ReportByEmployeeAgg_VK_UniquePostone
        ;
        with c1 as (
          select 
				ProductType_Code
				, Дата
              -- , Сотрудник   
               --, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
			    , isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальныеVK]
               
            from #fedor_verificator_report_VK
           group by ProductType_Code, Дата
              -- , Сотрудник
        )        
          select c1.*              
            into #ReportByEmployeeAgg_VK_UniquePostone
            from c1 
            

		/*
            --select * from #ReportByEmployeeAgg_VK
        if @Page = 'fedor_verificator_report_VK'
        begin                
         select 'VK' stage, stage_status='All',*,[Время, час:мин:сек] = '2000-01-01 00:22:35.000'   from #fedor_verificator_report_VK            
        end
		*/
        
		/*
		if @Page = 'ReportByEmployee_VK'
        begin
        
         
         select Дата
               , Сотрудник
               , ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки]
               , status 
            from #fedor_verificator_report_VK
            where  status <>'task:В работе'
           order by Дата, Сотрудник,ДатаИВремяСтатуса, [Номер заявки]
        end
		*/
        
		/*
		if @Page = 'ReportByEmployeeAgg_VK'
        begin
          select 
			    StageName = 'VK'
		       , Дата		       
               , Сотрудник
               , Новая
			   , ИтогоПоСотруднику
               , [Special] = VTS
               , Доработка
               , Отказано
               , Отложена
               , КоличествоЗаявок
               , ВремяЗатрачено
               , AvgВремяЗатрачено
               , [Отложено уникальных] --= [ОтложенаУникальныеVK]
               , [Доработка уникальных]
          from #ReportByEmployeeAgg_VK
         order by 1,2
        
        end
		*/

		/*
		if @Page = 'ReportByEmployeeAgg_VK_LastHour'
        begin
          select  StageName = 'VK_LastHour'
		       , Дата		       
               , Сотрудник
               , Новая
			   , ИтогоПоСотруднику
               , [Special] = VTS
               , Доработка
               , Отказано
               , Отложена
               , КоличествоЗаявок
               , ВремяЗатрачено
               , AvgВремяЗатрачено
               , [Отложено уникальных]
               , [Доработка уникальных]
          from #ReportByEmployeeAgg_LastHour_VK
         order by 1,2
        
        end
		*/
      
        
		-- По часам VK
		IF @Page = 'VK.HoursGroupDaysUnique' OR @isFill_All_Tables = 1 --241
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDaysUnique
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDaysUnique AS T
				WHERE T.ProcessGUID = @ProcessGUID
				/*
				--var 1
				;with c2 as (
					select null as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(Дата as date)  as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report_VK
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(Дата as date)  
					),
				c3 as (
					select null as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(Дата as date) as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report_VK
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDaysUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDaysUnique
				from (select distinct Интервал, cast(Дата as date) Дата, ИнтервалСтрока from #HoursDays)  hd
					LEFT join (
						select c2.Интервал
						   , дата
						   , isnull(c2.Новая,0) КоличествоЗаявок 
						   , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						   , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						-- into #ReportByEmployeeAgg
						from c2 
						union all
						select c3.Интервал
						   , дата
						   , isnull(c3.Новая,0) КоличествоЗаявок 
						   , isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						   , isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						-- into #ReportByEmployeeAgg
						from c3 
					) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
				*/

				--var 2
				;with c2 as (
					SELECT
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(Дата as date)  as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from #fedor_verificator_report_VK
					group by ProductType_Code, cast(Дата as date)  
					),
				c3 as (
					SELECT
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(Дата as date) as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from #fedor_verificator_report_VK
					group by ProductType_Code, cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDaysUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDaysUnique
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(Дата as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
					select 
						c2.ProductType_Code
						--, c2.Интервал
						, Интервал = c2.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c2.Новая,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c2 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c2.ProductType_Code
					union all
					select 
						c3.ProductType_Code
						--, c3.Интервал
						, Интервал = c3.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c3.Новая,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c3 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c3.ProductType_Code
				) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
				UNION ALL
				SELECT DISTINCT 
					ProcessGUID = @ProcessGUID,
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(Дата as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.HoursGroupDaysUnique', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with c2 as (
					select null as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(Дата as date)  as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report_VK
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(Дата as date)  
					),
				c3 as (
					select null as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(Дата as date) as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report_VK
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT  isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				from (select distinct Интервал, cast(Дата as date) Дата, ИнтервалСтрока from #HoursDays)  hd
					LEFT join (
						select c2.Интервал
						   , дата
						   , isnull(c2.Новая,0) КоличествоЗаявок 
						   , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						   , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						-- into #ReportByEmployeeAgg
						from c2 
						union all
						select c3.Интервал
						   , дата
						   , isnull(c3.Новая,0) КоличествоЗаявок 
						   , isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						   , isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
						-- into #ReportByEmployeeAgg
						from c3 
					) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
				*/

				--var 2
				;with c2 as (
					SELECT
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(Дата as date)  as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from #fedor_verificator_report_VK
					group by ProductType_Code, cast(Дата as date)  
					),
				c3 as (
					SELECT
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(Дата as date) as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from #fedor_verificator_report_VK
					group by ProductType_Code, cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(Дата as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
					select 
						c2.ProductType_Code
						--, c2.Интервал
						, Интервал = c2.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c2.Новая,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c2 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c2.ProductType_Code
					union all
					select 
						c3.ProductType_Code
						--, c3.Интервал
						, Интервал = c3.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c3.Новая,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c3 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c3.ProductType_Code
				) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
				UNION ALL
				SELECT DISTINCT 
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(Дата as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				RETURN 0
			END
		END
		--// 'VK.HoursGroupDaysUnique'


		IF @Page = 'VK.HoursGroupDays' OR @isFill_All_Tables = 1 --241
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDays
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDays AS T
				WHERE T.ProcessGUID = @ProcessGUID
				/*
				--var 1
				;with c2 as (
				select null as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(Дата as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(Дата as date)  
				),
				c3 as (
				select null as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(Дата as date) as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDays
				SELECT 
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDays
				from (select distinct Интервал, cast(Дата as date) Дата, ИнтервалСтрока from #HoursDays)  hd
				LEFT join (
				select c2.Интервал
					, дата
					, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c2 
				union all
				select c3.Интервал
					, дата
					, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c3 
				) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
				*/

				--var 2
				;with c2 as (
				select 
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(Дата as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from #fedor_verificator_report_VK
				group by ProductType_Code, cast(Дата as date)  
				),
				c3 as (
				SELECT
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(Дата as date) as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from #fedor_verificator_report_VK
				group by ProductType_Code, cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDays
				SELECT 
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupDays
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(Дата as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
					select 
						c2.ProductType_Code
						--, c2.Интервал
						, Интервал = c2.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c2 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c2.ProductType_Code
					union all
					select 
						c3.ProductType_Code
						--, c3.Интервал
						, Интервал = c3.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c3 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c3.ProductType_Code
					) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
				UNION ALL
				SELECT DISTINCT 
					ProcessGUID = @ProcessGUID,
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(Дата as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.HoursGroupDays', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with c2 as (
				select null as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(Дата as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(Дата as date)  
				),
				c3 as (
				select null as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(Дата as date) as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT  isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				from (select distinct Интервал, cast(Дата as date) Дата, ИнтервалСтрока from #HoursDays)  hd
				LEFT join (
				select c2.Интервал
					, дата
					, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c2 
				union all
				select c3.Интервал
					, дата
					, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c3 
				) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
				*/

				--var 2
				;with c2 as (
				select 
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(Дата as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from #fedor_verificator_report_VK
				group by ProductType_Code, cast(Дата as date)  
				),
				c3 as (
				SELECT
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(Дата as date) as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from #fedor_verificator_report_VK
				group by ProductType_Code, cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT 
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(Дата as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
					select 
						c2.ProductType_Code
						--, c2.Интервал
						, Интервал = c2.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c2 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c2.ProductType_Code
					union all
					select 
						c3.ProductType_Code
						--, c3.Интервал
						, Интервал = c3.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c3 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c3.ProductType_Code
					) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
				UNION ALL
				SELECT DISTINCT 
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(Дата as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				RETURN 0
			END
		END
		--// 'VK.HoursGroupDays'


		IF @Page = 'VK.HoursGroupMonthUnique' OR @isFill_All_Tables = 1 --241
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonthUnique
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonthUnique AS T
				WHERE T.ProcessGUID = @ProcessGUID
				/*
				--var 1
				;with c2 as (
				select null as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
				select null as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonthUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonthUnique
				from (select distinct Интервал, cast(format(Дата,'yyyyMM01') as date) Дата, ИнтервалСтрока from #HoursDays)  hd
				LEFT join (
				select c2.Интервал
					, дата
					, isnull(c2.Новая,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c2 
				union all
				select c3.Интервал
					, дата
					, isnull(c3.Новая,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c3 
				) mm on mm.Интервал = hd.Интервал
				*/

				--var 2
				;with c2 as (
				select 
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
				SELECT
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonthUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonthUnique
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(format(Дата,'yyyyMM01') as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
				select 
					c2.ProductType_Code
					--, c2.Интервал
					, Интервал = c2.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c2.Новая,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				from c2 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c2.ProductType_Code
				union all
				select 
					c3.ProductType_Code
					--, c3.Интервал
					, Интервал = c3.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c3.Новая,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c3 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c3.ProductType_Code
				) mm on mm.Интервал = hd.Интервал
				UNION ALL
				SELECT DISTINCT 
					ProcessGUID = @ProcessGUID,
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(format(Дата,'yyyyMM01') as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.HoursGroupMonthUnique', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with c2 as (
				select null as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
				select null as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT  isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				from (select distinct Интервал, cast(format(Дата,'yyyyMM01') as date) Дата, ИнтервалСтрока from #HoursDays)  hd
				LEFT join (
				select c2.Интервал
					, дата
					, isnull(c2.Новая,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c2 
				union all
				select c3.Интервал
					, дата
					, isnull(c3.Новая,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c3 
				) mm on mm.Интервал = hd.Интервал
				*/

				--var 2
				;with c2 as (
				select 
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
				SELECT
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(format(Дата,'yyyyMM01') as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
				select 
					c2.ProductType_Code
					--, c2.Интервал
					, Интервал = c2.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c2.Новая,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				from c2 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c2.ProductType_Code
				union all
				select 
					c3.ProductType_Code
					--, c3.Интервал
					, Интервал = c3.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c3.Новая,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c3 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c3.ProductType_Code
				) mm on mm.Интервал = hd.Интервал
				UNION ALL
				SELECT DISTINCT 
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(format(Дата,'yyyyMM01') as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				RETURN 0
			END
		END
		--// 'VK.HoursGroupMonthUnique'


		-- Лист "VK. Общее количество по часам"
		IF @Page = 'VK.HoursGroupMonth' OR @isFill_All_Tables = 1 --241
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonth
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonth AS T
				WHERE T.ProcessGUID = @ProcessGUID
				/*
				--var 1
				;with c2 as (
				select null as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
				select null as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonth
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonth
				from (select distinct Интервал, cast(format(Дата,'yyyyMM01') as date) Дата, ИнтервалСтрока from #HoursDays)  hd
				LEFT join (
				select c2.Интервал
					, дата
					, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c2 
				union all
				select c3.Интервал
					, дата
					, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c3 
				) mm on mm.Интервал = hd.Интервал
				*/

				--var 2
				;with c2 as (
				select 
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
				SELECT
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonth
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_HoursGroupMonth
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(format(Дата,'yyyyMM01') as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
				select 
					c2.ProductType_Code
					--, c2.Интервал
					, Интервал = c2.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				from c2 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c2.ProductType_Code
				union all
				select 
					c3.ProductType_Code
					--, c3.Интервал
					, Интервал = c3.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				from c3 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c3.ProductType_Code
				) mm on mm.Интервал = hd.Интервал
				UNION ALL
				SELECT DISTINCT 
					ProcessGUID = @ProcessGUID,
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(format(Дата,'yyyyMM01') as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.HoursGroupMonth', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with c2 as (
				select null as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
				select null as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT  isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				from (select distinct Интервал, cast(format(Дата,'yyyyMM01') as date) Дата, ИнтервалСтрока from #HoursDays)  hd
				LEFT join (
				select c2.Интервал
					, дата
					, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c2 
				union all
				select c3.Интервал
					, дата
					, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c3 
				) mm on mm.Интервал = hd.Интервал
				*/

				--var 2
				;with c2 as (
				select 
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) 
				),
				c3 as (
				SELECT
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_VK
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(format(Дата,'yyyyMM01') as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
				select 
					c2.ProductType_Code
					--, c2.Интервал
					, Интервал = c2.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				from c2 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c2.ProductType_Code
				union all
				select 
					c3.ProductType_Code
					--, c3.Интервал
					, Интервал = c3.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				from c3 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c3.ProductType_Code
				) mm on mm.Интервал = hd.Интервал
				UNION ALL
				SELECT DISTINCT 
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(format(Дата,'yyyyMM01') as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				RETURN 0
			END
		END
		--// 'VK.HoursGroupMonth'

        
		--- Общее кол-во по дням 
		IF @Page = 'VK.Daily.Total' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Total
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Total AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на этапе' Indicator
						, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Total
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Total
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator
					, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на этапе' Indicator
					, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Total
				SELECT
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, isnull(A.КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Total
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.КоличествоЗаявок ),0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.Total', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на этапе' Indicator
						, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator
						, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на этапе' Indicator
					, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, isnull(A.КоличествоЗаявок,0) Сумма
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.КоличествоЗаявок ),0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Daily.Total'

		--Monthly        
		IF @Page = 'VK.Monthly.Total' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Total
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Total AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на этапе' Indicator
						, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Total
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Total
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator
					, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на этапе' Indicator
					, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Total
				SELECT
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, isnull(A.КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Total
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.КоличествоЗаявок ),0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.Total', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на этапе' Indicator
						, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator
						, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на этапе' Indicator
					, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, isnull(A.КоличествоЗаявок,0) Сумма
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.КоличествоЗаявок ),0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Monthly.Total'

          
		IF @Page = 'VK.Daily.Unic' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Unic
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Unic AS T
				WHERE T.ProcessGUID = @ProcessGUID
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во заявок на этапе' Indicator
						, isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Unic
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Unic
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator
					, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во заявок на этапе' Indicator
					, isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Unic
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, isnull(A.КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Unic
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.КоличествоЗаявок ),0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.Unic', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во заявок на этапе' Indicator
						, isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator
						, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во заявок на этапе' Indicator
					, isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, isnull(A.КоличествоЗаявок,0) Сумма
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.КоличествоЗаявок ),0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Daily.Unic'
        
		--Monthly 
		IF @Page = 'VK.Monthly.Unic' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Unic
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Unic AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во заявок на этапе' Indicator
						, isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Unic
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Unic
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator
					, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во заявок на этапе' Indicator
					, isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Unic
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, isnull(A.КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Unic
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.КоличествоЗаявок ),0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.Unic', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во заявок на этапе' Indicator
						, isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator
						, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во заявок на этапе' Indicator
					, isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, isnull(A.КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Unic
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.КоличествоЗаявок ),0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Monthly.Unic'


		IF @Page = 'VK.Daily.AvgTime' OR @isFill_All_Tables = 1 --2403
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AvgTime
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AvgTime AS T
				WHERE T.ProcessGUID = @ProcessGUID
				/*
				--var 1
				;with agg as ( select empl_id
						, Employee		
						, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
						, 'Среднее время по заявке (общие)' Indicator
						, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AvgTime
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					,  Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AvgTime
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, CASE WHEN sum(КоличествоЗаявок) <> 0
						THEN cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
						ELSE '0'
					  END
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				SELECT 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
					, 'Среднее время по заявке (общие)' Indicator
					, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AvgTime
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма = cast(isnull(convert(nvarchar(50), cast(A.Сумма as datetime),8), 0) as nvarchar(50))
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AvgTime
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, CASE WHEN sum(A.КоличествоЗаявок) <> 0
						THEN cast(isnull(convert(nvarchar(50),cast((sum(A.ВремяЗатрачено)/sum(A.КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
						ELSE '0'
					  END
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.AvgTime', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as ( select empl_id
						, Employee		
						, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
						, 'Среднее время по заявке (общие)' Indicator
						, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					,  Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, CASE WHEN sum(КоличествоЗаявок) <> 0
							THEN cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
							ELSE '0'
						  END
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				SELECT 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
					, 'Среднее время по заявке (общие)' Indicator
					, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма = cast(isnull(convert(nvarchar(50), cast(A.Сумма as datetime),8), 0) as nvarchar(50))
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, CASE WHEN sum(A.КоличествоЗаявок) <> 0
						THEN cast(isnull(convert(nvarchar(50),cast((sum(A.ВремяЗатрачено)/sum(A.КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
						ELSE '0'
					  END
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Daily.AvgTime'
        
		--Monthly
		IF @Page = 'VK.Monthly.AvgTime' OR @isFill_All_Tables = 1 --2403
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AvgTime
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AvgTime AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as ( select empl_id
					, Employee		
					, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
					, 'Среднее время по заявке (общие)' Indicator
					, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AvgTime
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AvgTime
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, CASE WHEN sum(КоличествоЗаявок) <> 0
						THEN cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
						ELSE '0'
					  END
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				SELECT 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
					, 'Среднее время по заявке (общие)' Indicator
					, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AvgTime
				SELECT
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(convert(nvarchar, cast(A.Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AvgTime
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, CASE WHEN sum(A.КоличествоЗаявок) <> 0
						THEN cast(isnull(convert(nvarchar(50),cast((sum(A.ВремяЗатрачено)/sum(A.КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
						ELSE '0'
					  END
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.AvgTime', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as ( select empl_id
					, Employee		
					, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
					, 'Среднее время по заявке (общие)' Indicator
					, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
				from agg
				union all
				select 
					empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, CASE WHEN sum(КоличествоЗаявок) <> 0
						THEN cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
						ELSE '0'
					  END
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				SELECT 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
					, 'Среднее время по заявке (общие)' Indicator
					, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(convert(nvarchar, cast(A.Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AvgTime
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, CASE WHEN sum(A.КоличествоЗаявок) <> 0
						THEN cast(isnull(convert(nvarchar(50),cast((sum(A.ВремяЗатрачено)/sum(A.КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
						ELSE '0'
					  END
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Monthly.AvgTime'
        
		IF @Page = 'VK.Daily.Approved' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Approved
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Approved AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
					, Employee		
					, acc_period  dt
					, 'Кол-во одобренных заявок после этапа' Indicator
					, [VTS]  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Approved
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Approved
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Кол-во одобренных заявок после этапа' Indicator
					, [VTS]  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Approved
				SELECT
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Approved
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.Approved', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
					, Employee		
					, acc_period  dt
					, 'Кол-во одобренных заявок после этапа' Indicator
					, [VTS]  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				SELECT
					empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Кол-во одобренных заявок после этапа' Indicator
					, [VTS]  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Daily.Approved'


		--Monthly
		IF @Page = 'VK.Monthly.Approved' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Approved
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Approved AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Кол-во одобренных заявок после этапа' Indicator
						, [VTS]  Сумма
					from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Approved
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Approved
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Кол-во одобренных заявок после этапа' Indicator
					, [VTS]  Сумма
					from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Approved
				SELECT
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Approved
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.Approved', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Кол-во одобренных заявок после этапа' Indicator
						, [VTS]  Сумма
					from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				SELECT
					empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Кол-во одобренных заявок после этапа' Indicator
					, [VTS]  Сумма
					from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Approved
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Monthly.Approved'

        
		-- 'Общее кол-во отложенных заявок на этапе'
		IF @Page = 'VK.Daily.Postpone' OR @isFill_All_Tables = 1 --2401
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Postpone
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Postpone AS T
				WHERE T.ProcessGUID = @ProcessGUID
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Postpone
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Postpone
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во отложенных заявок на этапе' Indicator
					, Отложена  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Postpone
				select 
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Postpone
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.Postpone', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во отложенных заявок на этапе' Indicator
					, Отложена  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select 
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				select 
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Daily.Postpone'
        

		-- 'Уникальное кол-во отложенных заявок на этапе'
		IF @Page = 'VK.Daily.PostponeUnique' OR @isFill_All_Tables = 1 --2401
		BEGIN
			DROP table if exists #fedor_verificator_report_VK_Unique
			SELECT
				ProductType_Code
				, Дата
				, Сотрудник              
				, isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальные]
            into #fedor_verificator_report_VK_Unique
            from #fedor_verificator_report_VK
			group BY ProductType_Code, Дата, Сотрудник

			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_PostponeUnique
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_PostponeUnique AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во отложенных заявок на этапе' Indicator
						, [ОтложенаУникальные]  Сумма
				from #VKEmployees e
				left join #fedor_verificator_report_VK_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_PostponeUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_PostponeUnique
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во отложенных заявок на этапе' Indicator
					, [ОтложенаУникальные]  Сумма
				from #VKEmployees e
				left join #fedor_verificator_report_VK_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_PostponeUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_PostponeUnique
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.PostponeUnique', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во отложенных заявок на этапе' Indicator
						, [ОтложенаУникальные]  Сумма
				from #VKEmployees e
				left join #fedor_verificator_report_VK_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во отложенных заявок на этапе' Indicator
					, [ОтложенаУникальные]  Сумма
				from #VKEmployees e
				left join #fedor_verificator_report_VK_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_PostponeUnique
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Daily.PostponeUnique'
        

		--Monthly
		IF @Page = 'VK.Monthly.Postpone' OR @isFill_All_Tables = 1 --2401
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Postpone
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Postpone AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Postpone
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Postpone
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во отложенных заявок на этапе' Indicator
					, Отложена  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Postpone
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Postpone
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.Postpone', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во отложенных заявок на этапе' Indicator
					, Отложена  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Monthly.Postpone'

		--Monthly Unique
		IF @Page = 'VK.Monthly.PostponeUnique' OR @isFill_All_Tables = 1 --2401
		BEGIN

			DROP table if exists #ReportByEmployeeAgg_VK_m_Unique

			;with c1 as (
			select 
				ProductType_Code
				, cast(format(Дата,'yyyyMM01') as date) Дата
				, Сотрудник             
				, isnull(count( distinct case when status='Отложена' then [Номер заявки]  end),0) [Отложена]               
			from #fedor_verificator_report_VK
			group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date), Сотрудник
			)
			--,c2 as (
           
			--   select [ФИО сотрудника верификации/чекер]
			--        , cast(format(Дата,'yyyyMM01') as date) дата
			--        , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
			--        , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
			--        , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
			--   from  #fedor_verificator_report_VK
			--   group by  [ФИО сотрудника верификации/чекер],cast(format(Дата,'yyyyMM01') as date)
			--)
			select c1.*
				--, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
				--, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
				--, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
			into #ReportByEmployeeAgg_VK_m_Unique
			from c1 
			--left join c2 on c1.Дата=c2.Дата and c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]

			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_PostponeUnique
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_PostponeUnique AS T
				WHERE T.ProcessGUID = @ProcessGUID
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_PostponeUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_PostponeUnique
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во отложенных заявок на этапе' Indicator
					, Отложена  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_PostponeUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_PostponeUnique
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.PostponeUnique', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Уникальное кол-во отложенных заявок на этапе' Indicator
					, Отложена  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m_Unique a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Monthly.PostponeUnique'
        

        
		IF @Page = 'VK.Daily.Rework' OR @isFill_All_Tables = 1 --2402
		BEGIN

			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Rework
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Rework AS T
				WHERE T.ProcessGUID = @ProcessGUID
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на доработку на этапе' Indicator
						, Доработка  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Rework
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Rework
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на доработку на этапе' Indicator
					, Доработка  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Rework
				SELECT
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_Rework
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.Rework', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на доработку на этапе' Indicator
						, Доработка  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на доработку на этапе' Indicator
					, Доработка  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Daily.Rework'
        
		--Monthly

		IF @Page = 'VK.Monthly.Rework' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Rework
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Rework AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на доработку на этапе' Indicator
						, Доработка  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Rework
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Rework
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на доработку на этапе' Indicator
					, Доработка  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Rework
				SELECT
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_Rework
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.Rework', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на доработку на этапе' Indicator
						, Доработка  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'Общее кол-во заявок на доработку на этапе' Indicator
					, Доработка  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(sum(A.Сумма) ,0)
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Monthly.Rework'
        

		IF @Page = 'VK.Daily.AR' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AR
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AR AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'AR на этапе' Indicator
					, VTS
					, ИтогоПоСотруднику
						, case when ИтогоПоСотруднику<>0 then VTS*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AR
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) *100
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AR
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(
						case when sum(ИтогоПоСотруднику) <>0 then sum(VTS*1.0)/ sum(ИтогоПоСотруднику) else 0 end 
						,0)  *100 Сумма
				from agg
				group by dt, indicator
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'AR на этапе' Indicator
					, VTS
					, ИтогоПоСотруднику
					, case when ИтогоПоСотруднику<>0 then VTS*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AR
				SELECT
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0) *100
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AR
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(
						case when sum(A.ИтогоПоСотруднику) <>0 then sum(A.VTS*1.0)/ sum(A.ИтогоПоСотруднику) else 0 end 
						,0)  *100 Сумма
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.AR', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'AR на этапе' Indicator
					, VTS
					, ИтогоПоСотруднику
						, case when ИтогоПоСотруднику<>0 then VTS*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) *100
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(
							case when sum(ИтогоПоСотруднику) <>0 then sum(VTS*1.0)/ sum(ИтогоПоСотруднику) else 0 end 
							,0)  *100 Сумма
				from agg
				group by dt, indicator
				*/

				--var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'AR на этапе' Indicator
					, VTS
					, ИтогоПоСотруднику
					, case when ИтогоПоСотруднику<>0 then VTS*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0) *100
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Daily_AR
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(
						case when sum(A.ИтогоПоСотруднику) <>0 then sum(A.VTS*1.0)/ sum(A.ИтогоПоСотруднику) else 0 end 
						,0)  *100 Сумма
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Daily.AR'



		IF @Page = 'VK.Monthly.AR' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AR
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AR AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				-- var 1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'AR на этапе' Indicator
					, VTS
					, ИтогоПоСотруднику
						, case when ИтогоПоСотруднику<>0 then VTS*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AR
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) *100
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AR
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(
						case when sum(ИтогоПоСотруднику) <>0 then sum(VTS*1.0)/ sum(ИтогоПоСотруднику) else 0 end 
						,0)  *100 Сумма
				from agg
				group by dt, indicator
				*/

				-- var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'AR на этапе' Indicator
					, VTS
					, ИтогоПоСотруднику
					, case when ИтогоПоСотруднику<>0 then VTS*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AR
				SELECT
					ProcessGUID = @ProcessGUID,
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0) *100
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_VK_Monthly_AR
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(
						case when sum(A.ИтогоПоСотруднику) <>0 then sum(A.VTS*1.0)/ sum(A.ИтогоПоСотруднику) else 0 end 
						,0)  *100 Сумма
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.AR', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--1
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'AR на этапе' Indicator
					, VTS
					, ИтогоПоСотруднику
						, case when ИтогоПоСотруднику<>0 then VTS*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				select empl_id
						, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) *100
				from agg
				union all
				select empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
						, dt 
						, indicator 
						, isnull(
							case when sum(ИтогоПоСотруднику) <>0 then sum(VTS*1.0)/ sum(ИтогоПоСотруднику) else 0 end 
							,0)  *100 Сумма
				from agg
				group by dt, indicator
				*/

				-- var 2
				;with agg as (
				select 
					e.ProductType_Code
					, empl_id
					, Employee		
					, acc_period  dt
					, 'AR на этапе' Indicator
					, VTS
					, ИтогоПоСотруднику
					, case when ИтогоПоСотруднику<>0 then VTS*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.ProductType_Code = a.ProductType_Code AND e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				SELECT
					--, A.empl_id
					empl_id = A.empl_id + 100 * PT.ProductType_Order
					, A.Employee
					, A.dt
					, A.Indicator
					, Сумма=isnull(A.Сумма,0) *100
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				union all
				SELECT
					empl_id = isnull(max(A.empl_id + 100 * PT.ProductType_Order), 0) + 1
					, Employee ='ИТОГО' 
					, A.dt 
					, A.indicator
					, isnull(
						case when sum(A.ИтогоПоСотруднику) <>0 then sum(A.VTS*1.0)/ sum(A.ИтогоПоСотруднику) else 0 end 
						,0)  *100 Сумма
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code
				group by A.ProductType_Code, A.dt, A.indicator
				UNION ALL
				SELECT DISTINCT
					empl_id = 100 * PT.ProductType_Order
					, Employee = PT.ProductType_Name
					, A.dt 
					, A.indicator
					, Сумма = NULL
				from agg AS A
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = A.ProductType_Code

				RETURN 0
			END
		END
		--// 'VK.Monthly.AR'


END
--// VK.%



/*
------------------------------
--- Верификация ТС
------------------------------
-- TS.%
IF @Page IN (
	,'V.Daily.Common'
	,'V.Monthly.Common'

	,'ReportByEmployee_TS'
	,'ReportByEmployeeAgg_TS'
	,'ReportByEmployeeAgg_TS_LastHour'
	,'fedor_verificator_report_TS'
) OR @isFill_All_Tables = 1
BEGIN
	drop table if exists    #TSEmployees
         ;
         
          select distinct acc_period 
               , empl_id 
               , Employee 
               , [Status] 
            into #TSEmployees
            from #employee_rows_d 
           where [Status] in ('Верификация ТС') 
             and Employee in (select * from #curr_employee_vr)
        
       drop table if exists    #TSEmployees_m
         ;
         
          select distinct acc_period 
               , empl_id 
               , Employee 
               , [Status] 
            into #TSEmployees_m
            from #employee_rows_m 
           where [Status] in ('Верификация ТС') 
             and Employee in (select * from #curr_employee_vr)   
        
        drop table if exists #fedor_verificator_report_TS
        
         ;
         with details_TS as (
          select * from #t_dm_FedorVerificationRequests_without_coll/*#details*/ 
          where 1=1
			AND (Работник not in (select * from #curr_employee_cd)  
				OR Работник IN (select Employee from #curr_employee_vr) --DWH-1787
			)
			--AND Работник IN (select Employee from #curr_employee_vr) --DWH-1988
			AND [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
          --and  Статус in ('Верификация клиента') 
          )
           ,
          rework as (
          
          select 'Доработка' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] 
               , [ФИО клиента]
               , [Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
            from details_TS
           where Задача='task:Требуется доработка' and [Состояние заявки]='Отложена' and Статус in('Верификация ТС') 
          
          )
          ,rework1 as 
          (
          
          select 'Доработка' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса]
               , [ФИО клиента]
               , [Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_След --Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
            from details_TS
           where [Задача следующая]='task:Требуется доработка' and [Состояние заявки следующая]='Отложена' and Статус in('Верификация ТС') and ШагЗаявки= ПоследнийШаг
          
          )
            ,postpone1 as (
        
           select 'Отложена' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки]  
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
            from details_TS
           where Задача='task:Отложена' and [Состояние заявки] in('Отложена')  and Статус in('Верификация ТС') 
        )
              ,postpone as (
        
           select 'Отложена' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки]  
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
            from details_TS
           where  [Задача следующая]='task:Отложена' and [Состояние заявки следующая] in('Отложена') and Статус in('Верификация ТС') and ШагЗаявки= ПоследнийШаг
        )
        
           -- доработка
          select [status]
               ,  Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки]  
               , Сотрудник
               , [ФИО сотрудника верификации/чекер]
               , ВремяЗатрачено 
            into #fedor_verificator_report_TS
            from rework
           union all 
          select [status]
               , Дата
               , [Дата статуса]
               , [ФИО клиента]
               , [Номер заявки]  
               , Сотрудник
               , [ФИО сотрудника верификации/чекер]
               , ВремяЗатрачено 
            from rework1
           union 
       select * from postpone
       union
       select * from postpone1

        --select * from  #fedor_verificator_report_TS where  Дата='20200916'  order by 2 
           union 
        
         
         select 'Отказано' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки]  
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
            from details_TS
           where [Статус следующий]='Отказано' and (Статус in('Верификация ТС') or Статус in('Верификация Call 4'))
              
               union

                --
            /*    
                select * from #t_dm_FedorVerificationRequests_without_coll where [Номер заявки] in (
                select distinct [Номер заявки] from #t_dm_FedorVerificationRequests_without_coll where   Статус in('Верификация ТС')
                )
                order by [Номер заявки], [Дата статуса]
                */
          select 'Новая' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено 
            from details_TS
           where Задача='task:Новая'  and Статус in('Верификация ТС')

			UNION
			--DWH-2021
          select 'Новая_Уникальная' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено 
            from details_TS
           where Задача='task:Новая'  and Статус in('Верификация ТС')
				AND [Задача следующая] <> 'task:Автоматически отложено'

           union 
         
          select 'Одобрено' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено 
            from details_TS
           where [Статус следующий]='Одобрено' and (Статус in('Верификация ТС') or Статус in('Верификация Call 4'))
        
          
           union 
         
          select 'task:В работе' [status]
               , cast([Дата статуса] as date) Дата
               , [Дата статуса] ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки] 
               --, Сотрудник=СотрудникПоследнегоСтатуса
               --, [ФИО сотрудника верификации/чекер]
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
            from details_TS
             where Задача='task:В работе'  and Статус in('Верификация ТС')
        
            
        drop table if exists #ReportByEmployeeAgg_TS
        ;
        with c1 as (
          select Дата
               , Сотрудник
               , isnull(sum(case when status in ('Одобрено','Отказано') then 1 else 0 end),0) ИтогоПоСотруднику
			    , isnull(sum(case when status='xpen' then 1 else 0 end),0) VTS
               , isnull(sum(case when status='Одобрено' then 1 else 0 end),0) Одобрено
               , isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]
               , isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]
               , isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
               , isnull(sum(case when status='Новая' then 1 else 0 end),0) Новая 
               , isnull(sum(case when status in ('Новая_Уникальная') then 1 else 0 end),0) Новая_Уникальная --DWH-2021
		       , isnull(count( distinct case when status='Отложена' then  [Номер заявки] end),0) [Отложено уникальных]
               , isnull(count( distinct case when status='Доработка' then [Номер заявки] end ),0) [Доработка уникальных]
            from #fedor_verificator_report_TS
           group by Дата
               , Сотрудник
        )
        ,c2 as (
           
           select [ФИО сотрудника верификации/чекер]
                , дата
                , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
                , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
                , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
           from  #fedor_verificator_report_TS
           group by  [ФИО сотрудника верификации/чекер],дата
        )
          select c1.*
               , isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
               , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
               , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
            into #ReportByEmployeeAgg_TS
            from c1 
            left join c2 on c1.Дата=c2.Дата and c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]

	    drop table if exists #ReportByEmployeeAgg_TS_unique_postpone
        ;
        with c1 as (
          select Дата
               --, Сотрудник
               --, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
			    , isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальныеTS]

            from #fedor_verificator_report_TS
           group by Дата
               --, Сотрудник
        )
        
          select c1.*
            into #ReportByEmployeeAgg_TS_unique_postpone
            from c1 
           

		drop table if exists #ReportByEmployeeAgg_LastHour_TS
        ;
        with c1 as (
          select Дата
               , Сотрудник
               , isnull(sum(case when status in ('Одобрено','Отказано') then 1 else 0 end),0) ИтогоПоСотруднику
               , isnull(sum(case when status='xpen' then 1 else 0 end),0) VTS
               , isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]
               , isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]
               , isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
               , isnull(sum(case when status='Новая' then 1 else 0 end),0) Новая
			   , isnull(count( distinct case when status='Отложена' then  [Номер заявки] end),0) [Отложено уникальных]
               , isnull(count( distinct case when status='Доработка' then [Номер заявки] end ),0) [Доработка уникальных]
            from #fedor_verificator_report_TS
			where ДатаИВремяСтатуса>=dateadd(hh ,-1 ,getdate()) 
           group by Дата
               , Сотрудник
        )
        ,c2 as (
           
           select [ФИО сотрудника верификации/чекер]
                , дата
                , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
                , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
                , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
           from  #fedor_verificator_report_TS
		   where ДатаИВремяСтатуса>=dateadd(hh ,-1 ,getdate()) 
           group by  [ФИО сотрудника верификации/чекер],дата
        )
          select c1.*
               , isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
               , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
               , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
            into #ReportByEmployeeAgg_LastHour_TS
            from c1 
            left join c2 on c1.Дата=c2.Дата and c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]
        
        
        
--Monthly

        drop table if exists #ReportByEmployeeAgg_TS_m
        ;
        with c1 as (
          select format(Дата,'yyyyMM01') Дата
               , Сотрудник
               , isnull(sum(case when status in ('Одобрено','Отказано') then 1 else 0 end),0) ИтогоПоСотруднику
               , isnull(sum(case when status='Одобрено' then 1 else 0 end),0) Одобрено
               , isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]
               , isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]
               , isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
               , isnull(sum(case when status='Новая' then 1 else 0 end),0) Новая 
            from #fedor_verificator_report_TS
           group by format(Дата,'yyyyMM01')
               , Сотрудник
        )
        ,c2 as (
           
           select [ФИО сотрудника верификации/чекер]
                , format(Дата,'yyyyMM01') дата
                , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
                , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
                , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
           from  #fedor_verificator_report_TS
           group by  [ФИО сотрудника верификации/чекер],format(Дата,'yyyyMM01')
        )
          select c1.*
               , isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
               , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
               , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
            into #ReportByEmployeeAgg_TS_m
            from c1 
            left join c2 on c1.Дата=c2.Дата and c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]
        

		
		if @Page = 'fedor_verificator_report_TS'
        begin                
         select 'TS' stage, stage_status='All',*,[Время, час:мин:сек] = '2000-01-01 00:22:35.000'  from #fedor_verificator_report_TS            
        end


		 if @Page = 'ReportByEmployee_TS'
        begin
         select Дата
               , Сотрудник
               , ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки]
               , status 
            from #fedor_verificator_report_TS
            where  status <>'task:В работе'
           order by Дата, Сотрудник,ДатаИВремяСтатуса, [Номер заявки]
        end


        
		if @Page = 'ReportByEmployeeAgg_TS'
        begin
          select 
			    StageName = 'TS'
		       , Дата		       
               , Сотрудник
               , Новая
			   , ИтогоПоСотруднику
               , [Special] = null
               , Доработка
               , Отказано
               , Отложена
               , КоличествоЗаявок
               , ВремяЗатрачено
               , AvgВремяЗатрачено
               , [Отложено уникальных] --= [ОтложенаУникальныеVK]
               , [Доработка уникальных]
          from #ReportByEmployeeAgg_TS
         order by 1,2
        
        end

		if @Page = 'ReportByEmployeeAgg_TS_LastHour'
        begin
          select  StageName = 'TS_LastHour'
		       , Дата		       
               , Сотрудник
               , Новая
			   , ИтогоПоСотруднику
               , [Special] = null
               , Доработка
               , Отказано
               , Отложена
               , КоличествоЗаявок
               , ВремяЗатрачено
               , AvgВремяЗатрачено
               , [Отложено уникальных]
               , [Доработка уникальных]
          from #ReportByEmployeeAgg_LastHour_TS
         order by 1,2
        
        end
      
END
--// TS.%
*/



------------------------------
-- Общий отчет
------------------------------
IF @Page IN (
	'KD.Monthly.Common'
	,'V.Monthly.Common'
	,'KD.Daily.Common'
	,'V.Daily.Common'
	,'KD.HoursGroupMonth'
	,'KD.HoursGroupMonthUnique'
	,'KD.HoursGroupDays'
	,'KD.HoursGroupDaysUnique'
	,'KD.Monthly.Autoapprove'
	,'KD.Daily.Autoapprove'
	,'V.Monthly.TTY'
	,'V.Daily.TTY'
) OR @isFill_All_Tables = 1
BEGIN
	drop table if exists #indicator_for_controldata
	create table #indicator_for_controldata(
			[num_rows] numeric(6,2) --int null 
		, [name_indicator] nvarchar(250) null
	)
	insert into #indicator_for_controldata([num_rows] ,[name_indicator])
	values
         (1 ,'Общее кол-во заведенных заявок')
       , (2 ,'Кол-во автоматических отказов Логином')
       , (3 ,'%  автоматических отказов Логином')

       , (4 ,'Общее кол-во уникальных заявок на этапе')
       , (4.01 ,'Первичный')
       , (4.02 ,'Повторный')
       , (4.03 ,'Докредитование')
       , (4.04 ,'Не определен')


       , (5 ,'Общее кол-во заявок на этапе')

       , (6, 'TTY  - количество заявок рассмотренных в течение 2 минут на этапе')
       , (7 ,'TTY  - % заявок рассмотренных в течение 2 минут на этапе')
       , (10 ,'Среднее время заявки в ожидании очереди на этапе')
       , (12 ,'Средний Processing time на этапе (время обработки заявки)')

       , (15 ,'Кол-во одобренных заявок после этапа')

       , (18 ,'Кол-во отказов со стороны сотрудников')

       , (21 ,'Approval rate - % одобренных после этапа')

       , (25 ,'Общее кол-во отложенных заявок на этапе')
	   , (26 ,'Уникальное кол-во отложенных заявок на этапе')

       , (28 ,'Кол-во заявок на этапе, отправленных на доработку')
        
       , (31 ,'Кол-во заявок, не вернувшихся с доработки')

       , (33 ,'% заявок, не вернувшихся с доработки')



	drop table if exists #indicator_for_Autoapprove
	create table #indicator_for_Autoapprove(
		[num_rows] numeric(5,1) --int null 
		, [name_indicator] nvarchar(250) null
	)
	insert into #indicator_for_Autoapprove([num_rows] ,[name_indicator])
	values
       --  (1 ,'Уникальное количество заявок autoapprove')
       --, (2 ,'% заявок autoapprove от одобренных КД')
		  (1 ,'Уникальное количество заявок autoapprove КД')
		, (2 ,'Уникальное количество заявок autoapprove КД, финальное одобрение')

		, (3 ,'Уникальное количество заявок autoapprove ВК')
		, (4 ,'Уникальное количество заявок autoapprove ВК, финальное одобрение')

		, (5 ,'Уникальное количество заявок autoapprove КД + ВК')
		, (6 ,'Уникальное количество заявок autoapprove КД + ВК, финальное одобрение')

		, (7 ,'Уникальное количество заявок autoapprove (всего)')
		, (8 ,'Уникальное количество заявок autoapprove (всего), финальное одобрение')

		, (9 ,'% заявок autoapprove пропустивших этап КД (не назначался КД)')
		, (10 ,'% заявок autoapprove пропустивших этап КД (не назначался КД), финальное одобрение')

		, (11 ,'% заявок autoapprove от поступивших ВК (не назначался ВК)')
		, (12 ,'% заявок autoapprove от поступивших ВК (не назначался ВК), финальное одобрение')

		, (13 ,'% заявок autoapprove КД + ВК (от поступивших на КД)')
		, (14 ,'% заявок autoapprove КД + ВК (от поступивших на КД), финальное одобрение')

	------- всп.таблица показатели для статусов (Общий лист)
    drop table if exists #indicator_for_vc_va
    create table #indicator_for_vc_va (
           [num_rows] numeric(6,2) --int null 
         , [name_indicator] nvarchar(250) null
         )
	--OLD
	/*
	insert into #indicator_for_vc_va([num_rows] ,[name_indicator])
	values (1 ,'Общее кол-во заведенных заявок Call2')
		, (2 ,'Кол-во автоматических отказов Call2')
		, (3 ,'%  автоматических отказов Call2')
		, (4 ,'Общее кол-во уникальных заявок на этапе')
		, (5 ,'Общее кол-во заявок на этапе')
		, (8 ,'TTY  - % заявок рассмотренных в течение 30 минут на этапе')
		, (9 ,'TTY  - % заявок рассмотренных в течение 3-х минут на этапе')
		, (10 ,'Среднее время заявки в ожидании очереди на этапе')
		, (12 ,'Средний Processing time на этапе (время обработки заявки)')
		, (15 ,'Кол-во одобренных заявок после этапа')
		, (18 ,'Кол-во отказов со стороны сотрудников')
		, (21 ,'Approval rate - % одобренных после этапа')
		, (24 ,'Approval rate % Логином')

       , (25 ,'Контактность общая')
       , (26 ,'Контактность по одобренным')
       , (27 ,'Контактность по отказным')

       , (28 ,'Общее кол-во отложенных заявок на этапе')
	   , (29 ,'Уникальное кол-во отложенных заявок на этапе')
       , (30 ,'Кол-во заявок на этапе, отправленных на доработку')
		, (31 ,'Take rate Уровень выдачи, выраженный через одобрения')
		, (32 ,'Кол-во заявок в статусе "Займ выдан",шт.')
	*/

	--NEW
	insert into #indicator_for_vc_va([num_rows] ,[name_indicator])
	values (1 ,'Общее кол-во заведенных заявок Call2')
	, (2 ,'Кол-во автоматических отказов Call2')
	, (3 ,'%  автоматических отказов Call2')
	, (4 ,'Общее кол-во уникальных заявок на этапе ВК')
    , (4.01 ,'Первичный')
    , (4.02 ,'Повторный')
    , (4.03 ,'Докредитование')
    , (4.04 ,'Не определен')

	, (5 ,'Общее кол-во заявок на этапе ВК')

	-- только БЕЗЗАЛОГ
	, (7.01, 'TTY - количество заявок рассмотренных в течение 8 минут на этапе ВК')
	, (7.02, 'TTY - % заявок рассмотренных в течение 8 минут на этапе ВК')

	-- только ИНСТОЛМЕНТ
	, (9.01, 'TTY - количество заявок рассмотренных в течение 9 минут на этапе ВК')
	, (9.02, 'TTY - % заявок рассмотренных в течение 9 минут на этапе ВК')

	-- только PDL
	, (11.01 ,'TTY - количество заявок рассмотренных в течение 6 минут на этапе ВК')
	, (11.02 ,'TTY - % заявок рассмотренных в течение 6 минут на этапе ВК')

	--, (9 ,'TTY  - % заявок рассмотренных в течение 3-х минут на этапе')

	, (17 ,'Среднее время заявки в ожидании очереди на этапе ВК')
	, (18 ,'Средний Processing time на этапе (время обработки заявки) ВК')
	, (19 ,'Кол-во одобренных заявок после этапа ВК')
	, (20 ,'Кол-во отказов со стороны сотрудников ВК')
	, (21 ,'Approval rate - % одобренных после этапа ВК')
	--, (24 ,'Approval rate % Логином')

    --, (22 ,'Контактность общая')
    --, (23 ,'Контактность по одобренным')
    --, (24 ,'Контактность по отказным')

	, (25 ,'Общее кол-во отложенных заявок на этапе ВК')
	, (26 ,'Уникальное кол-во отложенных заявок на этапе ВК')
	, (28 ,'Кол-во заявок на этапе, отправленных на доработку ВК')
	--, (31 ,'Take rate Уровень выдачи, выраженный через одобрения')
	, (31 ,'Take up Количество выданных заявок')
	--, (32 ,'Кол-во заявок в статусе "Займ выдан",шт.')
	, (33 ,'Take up % выданных заявок от одобренных на Call3')
	--DWH-2309
	, (35, 'Кол-во уникальных заявок в статусе Договор подписан')

	-- только БЕЗЗАЛОГ
	, (41.01, 'TTY - количество заявок рассмотренных в течение 10 минут на этапах КД+ВК')
	, (41.02 ,'TTY - % заявок рассмотренных в течение 10 минут на этапах КД+ВК')

	-- только ИНСТОЛМЕНТ
	, (43.01 ,'TTY - количество заявок рассмотренных в течение 11 минут на этапах КД+ВК')
	, (43.02 ,'TTY - % заявок рассмотренных в течение 11 минут на этапах КД+ВК')

	-- только PDL
	, (45.01, 'TTY - количество заявок рассмотренных в течение 8 минут на этапах КД+ВК')
	, (45.02, 'TTY - % заявок рассмотренных в течение 8 минут на этапах КД+ВК')



	IF @Page = 'KD.HoursGroupDaysUnique' OR @isFill_All_Tables = 1 --241
	BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupDaysUnique
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupDaysUnique AS T
				WHERE T.ProcessGUID = @ProcessGUID

				;with c2 as (
					SELECT
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(Дата as date)  as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					group by ProductType_Code, cast(Дата as date)  
				),
				c3 as (
					SELECT
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(Дата as date) as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					group by ProductType_Code, cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupDaysUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupDaysUnique
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(Дата as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
					select 
						c2.ProductType_Code
						--, c2.Интервал
						, Интервал = c2.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c2.Новая,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c2 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c2.ProductType_Code
					union all
					select 
						c3.ProductType_Code
						--, c3.Интервал
						, Интервал = c3.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c3.Новая,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c3 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c3.ProductType_Code
					) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
				UNION ALL
				SELECT DISTINCT 
					ProcessGUID = @ProcessGUID,
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(Дата as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.HoursGroupDaysUnique', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with c2 as (
           
					select null as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(Дата as date)  as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(Дата as date)  
				),
				c3 as (
           
					select null as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(Дата as date) as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT  isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				FROM (select distinct Интервал, cast(Дата as date) Дата, ИнтервалСтрока from #HoursDays)  hd
				LEFT join (
					select c2.Интервал
						, дата
						, isnull(c2.Новая,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c2 
					union all
					select c3.Интервал
						, дата
						, isnull(c3.Новая,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c3 
					) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
				*/

				;with c2 as (
					SELECT
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(Дата as date)  as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					group by ProductType_Code, cast(Дата as date)  
				),
				c3 as (
					SELECT
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(Дата as date) as дата
						, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					group by ProductType_Code, cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(Дата as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
					select 
						c2.ProductType_Code
						--, c2.Интервал
						, Интервал = c2.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c2.Новая,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c2 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c2.ProductType_Code
					union all
					select 
						c3.ProductType_Code
						--, c3.Интервал
						, Интервал = c3.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c3.Новая,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c3 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c3.ProductType_Code
					) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
				UNION ALL
				SELECT DISTINCT 
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(Дата as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				RETURN 0
			END
	END
	--// 'KD.HoursGroupDaysUnique'

	IF @Page = 'KD.HoursGroupDays' OR @isFill_All_Tables = 1 --241
	BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupDays
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupDays AS T
				WHERE T.ProcessGUID = @ProcessGUID
				/*
				--var 1
				;with c2 as (
					select null as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(Дата as date)  as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(Дата as date)  
				),
				c3 as (
					select null as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(Дата as date) as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupDays
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupDays
				FROM (select distinct Интервал, cast(Дата as date) Дата, ИнтервалСтрока from #HoursDays)  hd
				LEFT join (
					select c2.Интервал
						, дата
						, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c2 
					union all
					select c3.Интервал
						, дата
						, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c3 
					) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
				*/

				--var 2
				;with c2 as (
					SELECT
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(Дата as date)  as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from #fedor_verificator_report
					group by ProductType_Code, cast(Дата as date)  
				),
				c3 as (
					SELECT
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(Дата as date) as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from #fedor_verificator_report
					group by ProductType_Code, cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupDays
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupDays
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(Дата as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
					select 
						c2.ProductType_Code
						--, c2.Интервал
						, Интервал = c2.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c2 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c2.ProductType_Code
					union all
					select 
						c3.ProductType_Code
						--, c3.Интервал
						, Интервал = c3.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c3 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c3.ProductType_Code
					) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
				UNION ALL
				SELECT DISTINCT 
					ProcessGUID = @ProcessGUID,
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(Дата as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.HoursGroupDays', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				;with c2 as (
					select null as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(Дата as date)  as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(Дата as date)  
				),
				c3 as (
           
					select null as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(Дата as date) as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				FROM (select distinct Интервал, cast(Дата as date) Дата, ИнтервалСтрока from #HoursDays)  hd
				LEFT join (
					select c2.Интервал
						, дата
						, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c2 
					union all
					select c3.Интервал
						, дата
						, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					-- into #ReportByEmployeeAgg
					from c3 
					) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
				*/

				--var 2
				;with c2 as (
					SELECT
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(Дата as date)  as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from #fedor_verificator_report
					group by ProductType_Code, cast(Дата as date)  
				),
				c3 as (
					SELECT
						ProductType_Code
						, NULL as [ФИО сотрудника верификации/чекер]
						, datepart(hour, ДатаИВремяСтатуса) Интервал
						, cast(Дата as date) as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from #fedor_verificator_report
					group by ProductType_Code, cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				SELECT
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				FROM (
					SELECT DISTINCT 
						--Интервал,
						Интервал = Интервал + 100 * PT.ProductType_Order,
						cast(Дата as date) Дата,
						ИнтервалСтрока 
					FROM #HoursDays
						INNER JOIN #t_ProductType AS PT
							ON 1=1
				) AS hd
				LEFT join (
					select 
						c2.ProductType_Code
						--, c2.Интервал
						, Интервал = c2.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c2 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c2.ProductType_Code
					union all
					select 
						c3.ProductType_Code
						--, c3.Интервал
						, Интервал = c3.Интервал + 100 * PT.ProductType_Order
						, дата
						, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
						, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
						, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
					from c3 
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = c3.ProductType_Code
					) mm on mm.Интервал = hd.Интервал and mm.дата = hd.Дата
				UNION ALL
				SELECT DISTINCT 
					КоличествоЗаявок = NULL,
					Интервал = 100 * PT.ProductType_Order - 1,
					Дата = cast(Дата as date),
					ИнтервалСтрока = PT.ProductType_Name
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1

				RETURN 0
			END
	END
	--// 'KD.HoursGroupDays'


	IF @Page = 'KD.HoursGroupMonthUnique' OR @isFill_All_Tables = 1 --241
	BEGIN
		IF @isFill_All_Tables = 1
		BEGIN
			--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupMonthUnique
			DELETE T
			FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupMonthUnique AS T
			WHERE T.ProcessGUID = @ProcessGUID

			/*
			--var 1
			;with c2 as (
				select null as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
			
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) 
			),
			c3 as (
				select null as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
			)
			INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupMonthUnique
			SELECT
				ProcessGUID = @ProcessGUID,
				isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, hd.ИнтервалСтрока
			--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupMonthUnique
			FROM (select distinct Интервал, cast(format(Дата,'yyyyMM01') as date) Дата, ИнтервалСтрока from #HoursDays)  hd
			LEFT join (
				select c2.Интервал
					, дата
					, isnull(c2.Новая,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c2 
				union all
				select c3.Интервал
					, дата
					, isnull(c3.Новая,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c3 
				) mm on mm.Интервал = hd.Интервал
			*/

			--var 2
			;with c2 as (
				select 
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) 
			),
			c3 as (
				select 
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
			)
			INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupMonthUnique
			SELECT
				ProcessGUID = @ProcessGUID,
				isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, hd.ИнтервалСтрока
			FROM (
				SELECT DISTINCT 
					--Интервал,
					Интервал = Интервал + 100 * PT.ProductType_Order,
					cast(format(Дата,'yyyyMM01') as date) Дата,
					ИнтервалСтрока 
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1
			) AS hd
			LEFT join (
				select 
					c2.ProductType_Code
					--, c2.Интервал
					, Интервал = c2.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c2.Новая,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				from c2 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c2.ProductType_Code
				union all
				select 
					c3.ProductType_Code
					--, c3.Интервал
					, Интервал = c3.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c3.Новая,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				from c3 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c3.ProductType_Code
				) mm on mm.Интервал = hd.Интервал
			UNION ALL
			SELECT DISTINCT 
				ProcessGUID = @ProcessGUID,
				КоличествоЗаявок = NULL,
				Интервал = 100 * PT.ProductType_Order - 1,
				Дата = cast(format(Дата,'yyyyMM01') as date),
				ИнтервалСтрока = PT.ProductType_Name
			FROM #HoursDays
				INNER JOIN #t_ProductType AS PT
					ON 1=1

			INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'KD.HoursGroupMonthUnique', @ProcessGUID
		END
		ELSE BEGIN
			/*
			--var 1
			;with c2 as (
				select null as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
				
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) 
			),
			c3 as (
				select null as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
			)
			SELECT
				isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, hd.ИнтервалСтрока
			FROM (select distinct Интервал, cast(format(Дата,'yyyyMM01') as date) Дата, ИнтервалСтрока from #HoursDays)  hd
			LEFT join (
				select c2.Интервал
					, дата
					, isnull(c2.Новая,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c2 
				union all
				select c3.Интервал
					, дата
					, isnull(c3.Новая,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c3 
				) mm on mm.Интервал = hd.Интервал
			*/

			--var 2
			;with c2 as (
				select 
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
				
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) 
			),
			c3 as (
				select 
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
			)
			SELECT
				isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, hd.ИнтервалСтрока
			FROM (
				SELECT DISTINCT 
					--Интервал,
					Интервал = Интервал + 100 * PT.ProductType_Order,
					cast(format(Дата,'yyyyMM01') as date) Дата,
					ИнтервалСтрока 
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1
			) AS hd
			LEFT join (
				select 
					c2.ProductType_Code
					--, c2.Интервал
					, Интервал = c2.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c2.Новая,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				from c2 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c2.ProductType_Code
				union all
				select 
					c3.ProductType_Code
					--, c3.Интервал
					, Интервал = c3.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c3.Новая,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				from c3 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c3.ProductType_Code
				) mm on mm.Интервал = hd.Интервал
			UNION ALL
			SELECT DISTINCT 
				КоличествоЗаявок = NULL,
				Интервал = 100 * PT.ProductType_Order - 1,
				Дата = cast(format(Дата,'yyyyMM01') as date),
				ИнтервалСтрока = PT.ProductType_Name
			FROM #HoursDays
				INNER JOIN #t_ProductType AS PT
					ON 1=1

			RETURN 0
		END
	END
	--// 'KD.HoursGroupMonthUnique'


	-- Лист "КД. Общее количество по часам"
	IF @Page = 'KD.HoursGroupMonth' OR @isFill_All_Tables = 1 --241
	BEGIN
		IF @isFill_All_Tables = 1
		BEGIN
			--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupMonth
			DELETE T
			FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupMonth AS T
			WHERE T.ProcessGUID = @ProcessGUID
			/*
			--var 1
			;with c2 as (
				select null as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) 
			),
			c3 as (
				select null as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
			)
			INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupMonth
			SELECT
				ProcessGUID = @ProcessGUID,
				isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
			--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupMonth
			FROM (select distinct Интервал, cast(format(Дата,'yyyyMM01') as date) Дата, ИнтервалСтрока from #HoursDays)  hd
			LEFT join (
				select c2.Интервал
					, дата
					, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c2 
				union all
				select c3.Интервал
					, дата
					, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c3 
				) mm on mm.Интервал = hd.Интервал
			*/

			--var 2
			;with c2 as (
				select 
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) 
			),
			c3 as (
				SELECT
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
			)
			INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupMonth
			SELECT
				ProcessGUID = @ProcessGUID,
				isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
			--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_HoursGroupMonth
			FROM (
				SELECT DISTINCT 
					--Интервал,
					Интервал = Интервал + 100 * PT.ProductType_Order,
					cast(format(Дата,'yyyyMM01') as date) Дата,
					ИнтервалСтрока 
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1
			) AS hd
			LEFT join (
				select 
					c2.ProductType_Code
					--, c2.Интервал
					, Интервал = c2.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c2 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c2.ProductType_Code
				union all
				select 
					c3.ProductType_Code
					--, c3.Интервал
					, Интервал = c3.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				from c3 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c3.ProductType_Code
				) mm on mm.Интервал = hd.Интервал
			UNION ALL
			SELECT DISTINCT 
				ProcessGUID = @ProcessGUID,
				КоличествоЗаявок = NULL,
				Интервал = 100 * PT.ProductType_Order - 1,
				Дата = cast(format(Дата,'yyyyMM01') as date),
				ИнтервалСтрока = PT.ProductType_Name
			FROM #HoursDays
				INNER JOIN #t_ProductType AS PT
					ON 1=1

			INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'KD.HoursGroupMonth', @ProcessGUID
		END
		ELSE BEGIN
			/*
			--var 1
			;with c2 as (
				select null as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) 
			),
			c3 as (
				select null as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
			)
			SELECT
				isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
			FROM (select distinct Интервал, cast(format(Дата,'yyyyMM01') as date) Дата, ИнтервалСтрока from #HoursDays)  hd
			LEFT join (
				select c2.Интервал
					, дата
					, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c2 
				union all
				select c3.Интервал
					, дата
					, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c3 
				) mm on mm.Интервал = hd.Интервал
			*/

			--var 2
			;with c2 as (
				select 
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) 
			),
			c3 as (
				SELECT
					ProductType_Code
					, NULL as [ФИО сотрудника верификации/чекер]
					, datepart(hour, ДатаИВремяСтатуса) Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report
				group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
			)
			SELECT
				isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
			FROM (
				SELECT DISTINCT 
					--Интервал,
					Интервал = Интервал + 100 * PT.ProductType_Order,
					cast(format(Дата,'yyyyMM01') as date) Дата,
					ИнтервалСтрока 
				FROM #HoursDays
					INNER JOIN #t_ProductType AS PT
						ON 1=1
			) AS hd
			LEFT join (
				select 
					c2.ProductType_Code
					--, c2.Интервал
					, Интервал = c2.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				-- into #ReportByEmployeeAgg
				from c2 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c2.ProductType_Code
				union all
				select 
					c3.ProductType_Code
					--, c3.Интервал
					, Интервал = c3.Интервал + 100 * PT.ProductType_Order
					, дата
					, isnull(c3.КоличествоЗаявок,0) КоличествоЗаявок 
					, isnull(c3.ВремяЗатрачено,0) ВремяЗатрачено
					, isnull(c3.AvgВремяЗатрачено,0) AvgВремяЗатрачено
				from c3 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = c3.ProductType_Code
				) mm on mm.Интервал = hd.Интервал
			UNION ALL
			SELECT DISTINCT 
				КоличествоЗаявок = NULL,
				Интервал = 100 * PT.ProductType_Order - 1,
				Дата = cast(format(Дата,'yyyyMM01') as date),
				ИнтервалСтрока = PT.ProductType_Name
			FROM #HoursDays
				INNER JOIN #t_ProductType AS PT
					ON 1=1

			RETURN 0
		END
	END
	--// 'KD.HoursGroupMonth'

	IF @Page IN ('KD.Daily.Common', 'KD.Daily.Autoapprove') OR @isFill_All_Tables = 1
	BEGIN

		DROP table if exists #waitTime

		;with r AS (
			select 
			r.ProductType_Code
			, [Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
			, [Дата статуса]
			, [Дата след.статуса]
			,Работник [ФИО сотрудника верификации/чекер]
			, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику],  [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]

			from #t_dm_FedorVerificationRequests_without_coll_ALL AS r
			where [Состояние заявки]='Ожидание'
			and r.Статус='Контроль данных'
			--DWH-2019
			AND NOT (
				r.Задача='task:Новая'
				AND r.[Задача следующая] = 'task:Автоматически отложено'
			)

			and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to 
			and 
			(Работник in (select e.Employee from #KDEmployees e)
			-- для учета, когда ожидание назначено на сотрудника
			or Назначен in (select e.Employee from #KDEmployees e)
			)
		)
		select 
			r.ProductType_Code
			, [Дата статуса]=cast([Дата статуса] as date) 
			,  avg( datediff(second,[Дата статуса], [Дата след.статуса]))   duration
		into #waitTime
		from r
		where  datediff(second,[Дата статуса], [Дата след.статуса])>0
		group by r.ProductType_Code, cast([Дата статуса] as date)
 

		DROP table if exists #verif_KC

		select 
			r.ProductType_Code
			, [Дата статуса]=cast([Дата статуса] as date) 
			, count(distinct [Номер заявки]) cnt
		into #verif_KC
		from #t_dm_FedorVerificationRequests_without_coll_ALL AS r
		WHERE [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
			AND  Статус='Верификация КЦ' and [Статус следующий]='Отказано'
		group by r.ProductType_Code, cast([Дата статуса] as date) 
 

		-- считаем уникальных отложенных по КД
        drop table if exists #ReportByEmployeeAgg_KD_UniquePostone

        ;with c1 as (
          select ProductType_Code
				, Дата
              -- , Сотрудник   
               --, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
			    , isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальныеKD]
               
            from #fedor_verificator_report
           group by ProductType_Code, Дата
              -- , Сотрудник
        )        
          select c1.*              
            into #ReportByEmployeeAgg_KD_UniquePostone
            from c1 
            

		-- посчитаем количество уникальных отложенных КД теперь и по дням
		DROP table if exists #postpone_unique_kd_daily
 
		SELECT 
			ProductType_Code,
			[Дата статуса]=cast(([Дата]) as date),
			sum(p.ОтложенаУникальныеKD) ОтложенаУникальныеKD 
		into #postpone_unique_kd_daily
		from #ReportByEmployeeAgg_KD_UniquePostone p
		GROUP by ProductType_Code, cast(([Дата]) as date)



		DROP table if exists #all_requests
  
		SELECT 
			D.ProductType_Code
			, D.[Дата заведения заявки] 
			, count(distinct D.[Номер заявки]) Qty 
		into #all_requests
		from #t_dm_FedorVerificationRequests_without_coll_ALL AS D
		join #calendar c on c.dt_day=D.[Дата заведения заявки]
		where  D.[Дата статуса]>@dt_from and  D.[Дата статуса]<@dt_to
		group by D.ProductType_Code, D.[Дата заведения заявки] 

		--IF @isDebug = 1 BEGIN
		--	DROP TABLE IF EXISTS ##all_requests
		--	SELECT * INTO ##all_requests FROM #all_requests

		--	DROP TABLE IF EXISTS ##calendar
		--	SELECT * INTO ##calendar FROM #calendar
		--END
   
		-- TTY
		DROP table if exists #tty_kd
		/*
		--var 1
		select ProductType_Code
			, Дата
			, [Номер заявки]
			, Сотрудник
			, [ФИО сотрудника верификации/чекер]
			--, ВремяЗатрачено
			, cast(cast(ВремяЗатрачено as datetime) as time) ВремяЗатрачено
			--, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:07:00' then '-' else 'tty' end tty_flag
			, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:02:00' then '-' else 'tty' end tty_flag
		into #tty_kd
		from #fedor_verificator_report where status='task:В работе'
		*/
		--var 2
		select 
			A.ProductType_Code
			, A.Дата
			, A.[Номер заявки]
			, ВремяЗатрачено = cast(cast(A.ВремяЗатрачено as datetime) as time)
			, tty_flag = CASE when cast(cast(A.ВремяЗатрачено as datetime) as time)>'00:02:00' then '-' else 'tty' end
		into #tty_kd
		FROM #fedor_verificator_report AS A
		WHERE A.status='task:В работе'
		--FROM (
		--		SELECT 
		--			R.ProductType_Code,
		--			R.[Номер заявки],
		--			Дата = max(R.Дата),
		--			ВремяЗатрачено = sum(R.ВремяЗатрачено)
		--		FROM #fedor_verificator_report AS R
		--		WHERE R.status='task:В работе'
		--		GROUP BY R.ProductType_Code, R.[Номер заявки]
		--	) AS A


		DROP table if exists #p 

		select d.*
			, cast(format(r.Qty,'0') as nvarchar(50))[Общее кол-во заведенных заявок]
			, cast(
			format(w.duration/60/60 ,'00')+N':'+format( (duration/60 -  60* (duration/60/60)),'00') +N':'+format((w.duration - 60 * (duration/60)),'00')
			as nvarchar(50)) [Среднее время заявки в ожидании очереди на этапе]
			, new.[Общее кол-во уникальных заявок на этапе]

			, new.[Первичный]
			, new.[Повторный]
			, new.[Докредитование]
			, new.[Не определен]

			, cast(tty.cnt as nvarchar(50)) [TTY  - количество заявок рассмотренных в течение 2 минут на этапе]
			, cast(format(case when [Общее кол-во заявок на этапе]<>0 then 100*tty.cnt*1.0/[Общее кол-во заявок на этапе] else 0 end,'0')+N'%' as nvarchar(50))[TTY  - % заявок рассмотренных в течение 2 минут на этапе]
  
					, cast(kc.cnt as nvarchar(50))[Кол-во автоматических отказов Логином]
					, cast(case when r.Qty<>0 then  format(100.0*kc.cnt/r.Qty,'0') else '0' end +N'%' as nvarchar(50))[%  автоматических отказов Логином]
			, [Уникальное кол-во отложенных заявок на этапе]                       = cast(format((u.ОтложенаУникальныеKD),'0') as nvarchar(50))     
         
			, cast(case when r.Qty<>0 then format(100.0*d.[Кол-во заявок, не вернувшихся с доработки]/r.Qty,'0.0') else '0' end +N'%' as nvarchar(50))
				AS [% заявок, не вернувшихся с доработки]

			, cast(format(Autoappr.Autoapprove_KD,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД]
			, cast(format(Autoappr.Autoapprove_KD_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД, финальное одобрение]

			, cast(format(Autoappr.Autoapprove_VK,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove ВК]
			, cast(format(Autoappr.Autoapprove_VK_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove ВК, финальное одобрение]

			, cast(format(Autoappr.Autoapprove_KD_VK,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД + ВК]
			, cast(format(Autoappr.Autoapprove_KD_VK_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД + ВК, финальное одобрение]

			, cast(format(Autoappr.Autoapprove_KD_VK_total,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove (всего)]
			, cast(format(Autoappr.Autoapprove_KD_VK_total_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove (всего), финальное одобрение]
			--
			, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
				AS [% заявок autoapprove пропустивших этап КД (не назначался КД)]
			, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD_fin_appr / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
				AS [% заявок autoapprove пропустивших этап КД (не назначался КД), финальное одобрение]

			, cast(case when Autoappr.VK_IN <> 0 then format(100.0 * Autoappr.Autoapprove_VK / Autoappr.VK_IN,'0.0') else '0' end +N'%' as nvarchar(50))
				AS [% заявок autoapprove от поступивших ВК (не назначался ВК)]
			, cast(case when Autoappr.VK_IN <> 0 then format(100.0 * Autoappr.Autoapprove_VK_fin_appr / Autoappr.VK_IN,'0.0') else '0' end +N'%' as nvarchar(50))
				AS [% заявок autoapprove от поступивших ВК (не назначался ВК), финальное одобрение]

			, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD_VK / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
				AS [% заявок autoapprove КД + ВК (от поступивших на КД)]
			, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD_VK_fin_appr / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
				AS [% заявок autoapprove КД + ВК (от поступивших на КД), финальное одобрение]
		INTO #p
		from (
			SELECT
				a.ProductType_Code
				, Дата
				 , cast(format(sum(a.КоличествоЗаявок),'0') as nvarchar(50)) [Общее кол-во заявок на этапе]

				 , cast(format(sum([ВК]),'0')as nvarchar(50)) [Кол-во одобренных заявок после этапа] 

				 , cast(format(sum(Отложена),'0') as nvarchar(50)) [Общее кол-во отложенных заявок на этапе]

				 , cast(format(sum(Доработка),'0') as nvarchar(50)) [Кол-во заявок на этапе, отправленных на доработку]

				 , cast(format(isnull(case when sum(ИтогоПоСотруднику) <>0 then sum(ВК*1.0)/ sum(  ИтогоПоСотруднику) else 0 end ,0)  *100,'0')+N'%' as nvarchar(50)) [Approval rate - % одобренных после этапа]

				 , cast(format(sum([Отказано]),'0')as nvarchar(50)) [Кол-во отказов со стороны сотрудников]

			  --   , cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))[Средний Processing time на этапе (время обработки заявки)]
			   , cast(isnull(convert(nvarchar,cast((case when sum(КоличествоЗаявок)<>0 then  sum(ВремяЗатрачено)/sum(КоличествоЗаявок) else 0 end) as datetime),8)  ,0) as nvarchar(50))[Средний Processing time на этапе (время обработки заявки)]

				, cast(format(sum([Не вернувшиеся с доработки]),'0') as nvarchar(50)) AS [Кол-во заявок, не вернувшихся с доработки]
      
			  from #ReportByEmployeeAgg a
			  where Сотрудник in (select * from #curr_employee_cd)
			 group by a.ProductType_Code, Дата
		) d

		LEFT JOIN (
			SELECT a.ProductType_Code
				, Дата
				 , cast(format(sum(Новая_Уникальная),'0')as nvarchar(50)) [Общее кол-во уникальных заявок на этапе]
				 --DWH-2286
				 , cast(format(sum([Новая_Уникальная Первичный]),'0')as nvarchar(50)) [Первичный]
				 , cast(format(sum([Новая_Уникальная Повторный]),'0')as nvarchar(50)) [Повторный]
				 , cast(format(sum([Новая_Уникальная Докредитование]),'0')as nvarchar(50)) [Докредитование]
				 , cast(format(sum([Новая_Уникальная Не определен]),'0')as nvarchar(50)) [Не определен]

			  from #ReportByEmployeeAgg a
			  GROUP BY a.ProductType_Code, Дата

			--DWH-1884 закомментарил
			--SELECT Дата
			--	 , cast(format(sum([ИтогоПоСотруднику]),'0')as nvarchar(50)) [Общее кол-во уникальных заявок на этапе]
			--  from #ReportByEmployeeAgg a
			--  --Только по сотрудникам, иначе в отчете будут учитываться данные от системых пользователей.
			--  WHERE a.Сотрудник in (select * from #curr_employee_cd)
			--  GROUP BY Дата
		) new 
		ON new.ProductType_Code = d.ProductType_Code 
		AND new.Дата=d.Дата

		join #all_requests r on r.ProductType_Code = d.ProductType_Code AND r.[Дата заведения заявки]=d.Дата
		left join #waitTime w on w.ProductType_Code = d.ProductType_Code AND w.[Дата статуса]=d.Дата
		left join #postpone_unique_kd_daily AS u on u.ProductType_Code = d.ProductType_Code AND u.[Дата статуса] = d.Дата
		left join (
			SELECT
				ProductType_Code
				, дата
				, count([Номер заявки]) cnt
			  -- , ВремяЗатрачено 
			  from #tty_kd
			where tty_flag='tty'
			group by ProductType_Code, дата 

		) tty on tty.ProductType_Code = d.ProductType_Code AND tty.Дата=d.Дата
		left join #verif_KC kc on kc.ProductType_Code = d.ProductType_Code AND kc.[Дата статуса]=d.Дата
		--select * from #p

		--DWH-2374
		LEFT JOIN (
			SELECT
				a.ProductType_Code
				, Дата
				, sum(Autoapprove_KD) AS Autoapprove_KD
				, sum(Autoapprove_KD_fin_appr) AS Autoapprove_KD_fin_appr

				, sum(Autoapprove_VK) AS Autoapprove_VK
				, sum(Autoapprove_VK_fin_appr) AS Autoapprove_VK_fin_appr

				, sum(Autoapprove_KD_VK) AS Autoapprove_KD_VK
				, sum(Autoapprove_KD_VK_fin_appr) AS Autoapprove_KD_VK_fin_appr

				, sum(Autoapprove_KD_VK_total) AS Autoapprove_KD_VK_total
				, sum(Autoapprove_KD_VK_total_fin_appr) AS Autoapprove_KD_VK_total_fin_appr

				, sum(KD_IN) AS KD_IN
				, sum(KD_IN_fin_appr) AS KD_IN_fin_appr

				, sum(VK_IN) AS VK_IN
				, sum(VK_IN_fin_appr) AS VK_IN_fin_appr
			  from #ReportByEmployeeAgg AS a
			  --01.01 не рабочий день, данные за этот день не учитываем
			  WHERE Дата != DATEFROMPARTS(year(Дата), 1,1)
			  GROUP BY a.ProductType_Code, Дата
		) Autoappr on Autoappr.ProductType_Code = d.ProductType_Code AND Autoappr.Дата = d.Дата


		DROP table if exists #unp

		IF @Page IN ('KD.Daily.Common') OR @isFill_All_Tables = 1
		BEGIN
			SELECT ProductType_Code, Дата, indicator, Qty 
			into #unp
			from 
			(
			select
				ProductType_Code
				, Дата
				 , [Общее кол-во заведенных заявок]
				 , [Кол-во автоматических отказов Логином]
				 , [%  автоматических отказов Логином]
				 , [Общее кол-во уникальных заявок на этапе]

				, [Первичный]
				, [Повторный]
				, [Докредитование]
				, [Не определен]

				 , [Общее кол-во заявок на этапе]
				 , [TTY  - количество заявок рассмотренных в течение 2 минут на этапе]
				 , [TTY  - % заявок рассмотренных в течение 2 минут на этапе]
				 , [Среднее время заявки в ожидании очереди на этапе]
				 , [Средний Processing time на этапе (время обработки заявки)]
				 , [Кол-во одобренных заявок после этапа]
				 , [Кол-во отказов со стороны сотрудников]
				 , [Approval rate - % одобренных после этапа]
				 , [Общее кол-во отложенных заявок на этапе]		  
				 , [Уникальное кол-во отложенных заявок на этапе]
				 , [Кол-во заявок на этапе, отправленных на доработку]
				 , [Кол-во заявок, не вернувшихся с доработки]
				 , [% заявок, не вернувшихся с доработки]
			  from #p
     
			) p
			UNPIVOT
			(Qty for indicator in (
								  [Общее кол-во заведенных заявок]
								 ,[Кол-во автоматических отказов Логином]
								 ,[%  автоматических отказов Логином]
								 ,[Общее кол-во уникальных заявок на этапе]
								, [Первичный]
								, [Повторный]
								, [Докредитование]
								, [Не определен]
								 ,[Общее кол-во заявок на этапе]
								 ,[TTY  - количество заявок рассмотренных в течение 2 минут на этапе]
								 ,[TTY  - % заявок рассмотренных в течение 2 минут на этапе]
								 ,[Среднее время заявки в ожидании очереди на этапе]
								 ,[Средний Processing time на этапе (время обработки заявки)]
								 ,[Кол-во одобренных заявок после этапа]
								 ,[Кол-во отказов со стороны сотрудников]
								 ,[Approval rate - % одобренных после этапа]
								 ,[Общее кол-во отложенных заявок на этапе]
								 ,[Уникальное кол-во отложенных заявок на этапе]
								 ,[Кол-во заявок на этапе, отправленных на доработку]
								 ,[Кол-во заявок, не вернувшихся с доработки]
								 ,[% заявок, не вернувшихся с доработки]
								)
		   ) as unpvt

			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Common
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Common AS T
				WHERE T.ProcessGUID = @ProcessGUID

				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Common
				SELECT
					ProcessGUID = @ProcessGUID,
					--i.num_rows 
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					, empl_id =null
					, Employee =null
					, acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					, [Сумма] =null
					, Qty
					, Qty_dist=null
					, Tm_Qty =null--isnull(Tm_Qty,0.00)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Common
				from #unp u 
					JOIN #indicator_for_controldata i on u.indicator=i.name_indicator
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
				--ORDER BY i.num_rows

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.Common', @ProcessGUID

			END
			ELSE BEGIN
				SELECT
					--i.num_rows 
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					, empl_id =null
					, Employee =null
					, acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					, [Сумма] =null
					, Qty
					, Qty_dist=null
					, Tm_Qty =null--isnull(Tm_Qty,0.00)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Common
				from #unp u 
					JOIN #indicator_for_controldata i on u.indicator=i.name_indicator
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
				--ORDER BY i.num_rows

				RETURN 0
			END
		END --'KD.Daily.Common'

		DROP table if exists #Autoapprove_unp

		IF @Page IN ('KD.Daily.Autoapprove') OR @isFill_All_Tables = 1
		BEGIN
			SELECT ProductType_Code, Дата, indicator, Qty 
			into #Autoapprove_unp
			from 
			(
				SELECT
					ProductType_Code
					, Дата
					 --, [Уникальное количество заявок autoapprove]
					 --, [% заявок autoapprove от одобренных КД]
					, [Уникальное количество заявок autoapprove КД]
					, [Уникальное количество заявок autoapprove КД, финальное одобрение]

					, [Уникальное количество заявок autoapprove ВК]
					, [Уникальное количество заявок autoapprove ВК, финальное одобрение]

					, [Уникальное количество заявок autoapprove КД + ВК]
					, [Уникальное количество заявок autoapprove КД + ВК, финальное одобрение]

					, [Уникальное количество заявок autoapprove (всего)]
					, [Уникальное количество заявок autoapprove (всего), финальное одобрение]

					, [% заявок autoapprove пропустивших этап КД (не назначался КД)]
					, [% заявок autoapprove пропустивших этап КД (не назначался КД), финальное одобрение]

					, [% заявок autoapprove от поступивших ВК (не назначался ВК)]
					, [% заявок autoapprove от поступивших ВК (не назначался ВК), финальное одобрение]

					, [% заявок autoapprove КД + ВК (от поступивших на КД)]
					, [% заявок autoapprove КД + ВК (от поступивших на КД), финальное одобрение]
			  from #p
     
			) p
			UNPIVOT
			(Qty for indicator in (
					 --[Уникальное количество заявок autoapprove]
					 --, [% заявок autoapprove от одобренных КД]
					[Уникальное количество заявок autoapprove КД]
					, [Уникальное количество заявок autoapprove КД, финальное одобрение]

					, [Уникальное количество заявок autoapprove ВК]
					, [Уникальное количество заявок autoapprove ВК, финальное одобрение]

					, [Уникальное количество заявок autoapprove КД + ВК]
					, [Уникальное количество заявок autoapprove КД + ВК, финальное одобрение]

					, [Уникальное количество заявок autoapprove (всего)]
					, [Уникальное количество заявок autoapprove (всего), финальное одобрение]

					, [% заявок autoapprove пропустивших этап КД (не назначался КД)]
					, [% заявок autoapprove пропустивших этап КД (не назначался КД), финальное одобрение]

					, [% заявок autoapprove от поступивших ВК (не назначался ВК)]
					, [% заявок autoapprove от поступивших ВК (не назначался ВК), финальное одобрение]

					, [% заявок autoapprove КД + ВК (от поступивших на КД)]
					, [% заявок autoapprove КД + ВК (от поступивших на КД), финальное одобрение]
					)
		   ) as unpvt

			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Autoapprove
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Autoapprove AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Autoapprove
				SELECT
					ProcessGUID = @ProcessGUID,
					--i.num_rows
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					, empl_id =null
					, Employee =null
					, acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					, [Сумма] =null
					, Qty
					, Qty_dist=null
					, Tm_Qty =null--isnull(Tm_Qty,0.00)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Common
				from #Autoapprove_unp AS u
					join #indicator_for_Autoapprove AS i
						ON u.indicator=i.name_indicator
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
				--ORDER BY i.num_rows
				*/

				--var 2
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Autoapprove
				SELECT
					ProcessGUID = @ProcessGUID,
					--i.num_rows
					num_rows = i.num_rows + 100 * PT.ProductType_Order
					, empl_id =null
					, Employee =null
					, acc_period =Дата
					,indicator = name_indicator
					, [Сумма] =null
					, Qty
					, Qty_dist=null
					, Tm_Qty =null--isnull(Tm_Qty,0.00)
				from #Autoapprove_unp AS u
					join #indicator_for_Autoapprove AS i
						ON u.indicator=i.name_indicator
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
				UNION
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					num_rows = 100 * PT.ProductType_Order
					,empl_id =null
					,Employee =null
					,acc_period = u.Дата
					,indicator = PT.ProductType_Name
					,[Сумма] =null
					,Qty = NULL
					,Qty_dist=null
					,Tm_Qty =null
				from #Autoapprove_unp AS u
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.Autoapprove', @ProcessGUID

			END
			ELSE BEGIN
				/*
				--var 1
				SELECT
					--i.num_rows
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					, empl_id =null
					, Employee =null
					, acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					, [Сумма] =null
					, Qty
					, Qty_dist=null
					, Tm_Qty =null--isnull(Tm_Qty,0.00)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Daily_Common
				from #Autoapprove_unp AS u
					join #indicator_for_Autoapprove AS i
						ON u.indicator=i.name_indicator
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
				--ORDER BY i.num_rows
				*/

				--var 2
				SELECT
					--i.num_rows
					num_rows = i.num_rows + 100 * PT.ProductType_Order
					, empl_id =null
					, Employee =null
					, acc_period =Дата
					,indicator = name_indicator
					, [Сумма] =null
					, Qty
					, Qty_dist=null
					, Tm_Qty =null--isnull(Tm_Qty,0.00)
				from #Autoapprove_unp AS u
					join #indicator_for_Autoapprove AS i
						ON u.indicator=i.name_indicator
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
				UNION
				SELECT DISTINCT
					num_rows = 100 * PT.ProductType_Order
					,empl_id =null
					,Employee =null
					,acc_period = u.Дата
					,indicator = PT.ProductType_Name
					,[Сумма] =null
					,Qty = NULL
					,Qty_dist=null
					,Tm_Qty =null
				from #Autoapprove_unp AS u
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code

				RETURN 0
			END
		END --'KD.Daily.Autoapprove'

	END
	--// 'KD.Daily.Common', 'KD.Daily.Autoapprove'



	IF @page IN ('V.Daily.Common', 'V.Daily.TTY') OR @isFill_All_Tables = 1 
	BEGIN
		drop table if exists #tty_vk
		/*
		--var 1
		select ProductType_Code
			, Дата
			, [Номер заявки]
			, Сотрудник
			, [ФИО сотрудника верификации/чекер]
			, cast(cast(ВремяЗатрачено as datetime) as time) ВремяЗатрачено
			, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:09:00' then '-' else 'tty' end tty9_flag
			, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:08:00' then '-' else 'tty' end tty8_flag
			, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:06:00' then '-' else 'tty' end tty6_flag
		into #tty_vk
		from #fedor_verificator_report_vk where status='task:В работе'
		*/
		--var 2
		select 
			A.ProductType_Code
			, A.Дата
			, A.[Номер заявки]
			, ВремяЗатрачено = cast(cast(A.ВремяЗатрачено as datetime) as time)
			, tty9_flag = CASE when cast(cast(ВремяЗатрачено as datetime) as time)>'00:09:00' then '-' else 'tty' end
			, tty8_flag = CASE when cast(cast(ВремяЗатрачено as datetime) as time)>'00:08:00' then '-' else 'tty' end 
			, tty6_flag = CASE when cast(cast(ВремяЗатрачено as datetime) as time)>'00:06:00' then '-' else 'tty' end 
		into #tty_vk
		FROM #fedor_verificator_report_vk AS A
		WHERE A.status='task:В работе'
		--FROM (
		--		SELECT 
		--			R.ProductType_Code,
		--			R.[Номер заявки],
		--			Дата = max(R.Дата),
		--			ВремяЗатрачено = sum(R.ВремяЗатрачено)
		--		FROM #fedor_verificator_report_vk AS R
		--		WHERE R.status='task:В работе'
		--		GROUP BY R.ProductType_Code, R.[Номер заявки]
		--	) AS A


		DROP TABLE IF EXISTS #tty_kd_vk
		SELECT
			A.ProductType_Code
			, A.Дата
			, A.[Номер заявки]
			, ВремяЗатрачено = cast(cast(A.ВремяЗатрачено as datetime) as time)
			, tty11_flag = CASE when cast(cast(ВремяЗатрачено as datetime) as time)>'00:11:00' then '-' else 'tty' end
			, tty10_flag = CASE when cast(cast(ВремяЗатрачено as datetime) as time)>'00:10:00' then '-' else 'tty' end
			, tty8_flag = CASE when cast(cast(ВремяЗатрачено as datetime) as time)>'00:08:00' then '-' else 'tty' end 
		into #tty_kd_vk
		FROM (
				SELECT K.ProductType_Code, K.[Номер заявки], K.Дата, K.ВремяЗатрачено
				FROM #fedor_verificator_report AS K
				WHERE K.status='task:В работе'
				UNION ALL
				SELECT V.ProductType_Code, V.[Номер заявки], V.Дата, V.ВремяЗатрачено
				FROM #fedor_verificator_report_vk AS V
				WHERE V.status='task:В работе'
			) AS A
		--FROM (
		--		SELECT 
		--			R.ProductType_Code,
		--			R.[Номер заявки],
		--			Дата = max(R.Дата),
		--			ВремяЗатрачено = sum(R.ВремяЗатрачено)
		--		FROM (
		--				SELECT K.ProductType_Code, K.[Номер заявки], K.Дата, K.ВремяЗатрачено
		--				FROM #fedor_verificator_report AS K
		--				WHERE K.status='task:В работе'
		--				UNION ALL
		--				SELECT V.ProductType_Code, V.[Номер заявки], V.Дата, V.ВремяЗатрачено
		--				FROM #fedor_verificator_report_vk AS V
		--				WHERE V.status='task:В работе'
		--			) AS R
		--		GROUP BY R.ProductType_Code, R.[Номер заявки]
		--	) AS A




		-- Пришло на call2
		drop table if exists #call2
		select 
			ProductType_Code
			, [Дата статуса]=cast([Дата статуса] as date)
			, count(distinct [Номер заявки]) Qty
			, sum(case when [Статус следующий]='Отказано' then 1 else 0 end) Qty_rejected
		into #call2
		from #t_dm_FedorVerificationRequests_without_coll_ALL AS r 
		WHERE Статус ='Верификация Call 2'  and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
		group by ProductType_Code, cast([Дата статуса] as date)


		DROP table if exists #waitTime_v

		 ;with r as
		(
		select 
		r.ProductType_Code
		, [Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
		, [Дата статуса]
		, [Дата след.статуса]
		, Работник [ФИО сотрудника верификации/чекер]
		, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику], [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]
		 from #t_dm_FedorVerificationRequests_without_coll_ALL AS r
		  where [Состояние заявки]='Ожидание' 
			and r.Статус='Верификация клиента' 
			--DWH-2019
			AND NOT (
				r.Задача='task:Новая'
				AND r.[Задача следующая] = 'task:Автоматически отложено'
			)

			and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
		  and (Работник in (select e.Employee from #VKEmployees e)
		   -- для учета, когда ожидание назначено на сотрудника
		 or Назначен in (select e.Employee from #VKEmployees e))
		)
		SELECT
			r.ProductType_Code
			, [Дата статуса]=cast([Дата статуса] as date) 
		   --  , [Номер заявки]
			   , avg( datediff(second,[Дата статуса], [Дата след.статуса]))  duration
		into #waitTime_v
		from  r
		where  datediff(second,[Дата статуса], [Дата след.статуса])>0
		group by r.ProductType_Code, cast([Дата статуса] as date)-- ,[Номер заявки]
 
		-- посчитаем количество уникальных отложенных VK теперь и по дням
		drop table if exists #postpone_unique_vk_daily
		select 
			ProductType_Code
			, [Дата статуса]=cast(([Дата]) as date),
			sum(p.ОтложенаУникальныеVK) ОтложенаУникальныеVK 
		into #postpone_unique_vk_daily
		from #ReportByEmployeeAgg_VK_UniquePostone p
		group by ProductType_Code, cast(([Дата]) as date)
   
		--select * from #waitTime_v
		drop table if exists #p_VK 


		--NEW
		select d.* 
			, new.[Общее кол-во уникальных заявок на этапе ВК]

			, new.[Первичный]
			, new.[Повторный]
			, new.[Докредитование]
			, new.[Не определен]

			, new.[Take up Количество выданных заявок]
			, [Среднее время заявки в ожидании очереди на этапе ВК]              = cast(
				format(w.duration/60/60 ,'00')+N':'+format( (w.duration/60 -  60* (w.duration/60/60)),'00') +N':'+format((w.duration - 60 * (duration/60)),'00')
				AS nvarchar(50))
			, [Общее кол-во заведенных заявок Call2]                                        = cast(format(call2.Qty,'0') as nvarchar(50))
			, [Кол-во автоматических отказов Call2]                                         = cast(format(call2.Qty_rejected,'0') as nvarchar(50))
			, [%  автоматических отказов Call2]                                             = cast(format(case when call2.Qty<>0 then 100.0*call2.Qty_rejected/call2.Qty else 0 end,'0.0')+N'%' as nvarchar(50))

			, [TTY - количество заявок рассмотренных в течение 9 минут на этапе ВК] = cast(format(tty9.cnt,'0') as nvarchar(50))
			, [TTY - % заявок рассмотренных в течение 9 минут на этапе ВК]  = cast(format(case when [Общее кол-во заявок на этапе ВК]<>0 then 100.0*tty9.cnt/ [Общее кол-во заявок на этапе ВК] else 0 end,'0')+N'%' as nvarchar(50))

			, [TTY - количество заявок рассмотренных в течение 8 минут на этапе ВК] = cast(format(tty8.cnt,'0') as nvarchar(50))
			, [TTY - % заявок рассмотренных в течение 8 минут на этапе ВК]  = cast(format(case when [Общее кол-во заявок на этапе ВК]<>0 then 100.0*tty8.cnt/ [Общее кол-во заявок на этапе ВК] else 0 end,'0')+N'%' as nvarchar(50))

			, [TTY - количество заявок рассмотренных в течение 6 минут на этапе ВК] = cast(format(tty6.cnt,'0') as nvarchar(50))
			, [TTY - % заявок рассмотренных в течение 6 минут на этапе ВК]  = cast(format(case when [Общее кол-во заявок на этапе ВК]<>0 then 100.0*tty6.cnt/ [Общее кол-во заявок на этапе ВК] else 0 end,'0')+N'%' as nvarchar(50))
			--
			, [TTY - количество заявок рассмотренных в течение 11 минут на этапах КД+ВК] = cast(format(tty_kd_vk11.cnt,'0') as nvarchar(50))
			, [TTY - % заявок рассмотренных в течение 11 минут на этапах КД+ВК]  = cast(format(case when tty_kd_vk_cnt.cnt<>0 then 100.0*tty_kd_vk11.cnt/ tty_kd_vk_cnt.cnt else 0 end,'0')+N'%' as nvarchar(50))

			, [TTY - количество заявок рассмотренных в течение 10 минут на этапах КД+ВК] = cast(format(tty_kd_vk10.cnt,'0') as nvarchar(50))
			, [TTY - % заявок рассмотренных в течение 10 минут на этапах КД+ВК]  = cast(format(case when tty_kd_vk_cnt.cnt<>0 then 100.0*tty_kd_vk10.cnt/ tty_kd_vk_cnt.cnt else 0 end,'0')+N'%' as nvarchar(50))

			, [TTY - количество заявок рассмотренных в течение 8 минут на этапах КД+ВК] = cast(format(tty_kd_vk8.cnt,'0') as nvarchar(50))
			, [TTY - % заявок рассмотренных в течение 8 минут на этапах КД+ВК]  = cast(format(case when tty_kd_vk_cnt.cnt<>0 then 100.0*tty_kd_vk8.cnt/ tty_kd_vk_cnt.cnt else 0 end,'0')+N'%' as nvarchar(50))

			, [Уникальное кол-во отложенных заявок на этапе ВК]                       = cast(format((u.ОтложенаУникальныеVK),'0') as nvarchar(50))

			--, [Take up % выданных заявок от одобренных на Call3] = case when isnull(d.[VTS],0)<>0 then cast(format(isnull(new.[Заем выдан]*1.0, 0) / d.[VTS] * 100,'0')+N'%' as nvarchar(50)) else '0%' END
			, [Take up % выданных заявок от одобренных на Call3] = case when isnull(new.[VTS],0)<>0 then cast(format(isnull(new.[Заем выдан]*1.0, 0) / new.[VTS] * 100,'0')+N'%' as nvarchar(50)) else '0%' END

			,[Кол-во уникальных заявок в статусе Договор подписан] = cast(format(isnull(ДоговорПодписан.cnt, 0),'0') as nvarchar(50))

		into #p_VK 
		from(
		SELECT
			ProductType_Code
			, Дата
			--, [Общее кол-во заявок на этапе Вериф.клиента]                                  = cast(format(sum(КоличествоЗаявок),'0') as nvarchar(50))
			, [Общее кол-во заявок на этапе ВК] = cast(format(sum(КоличествоЗаявок),'0') as nvarchar(50))

			--, [TTY  - % заявок рассмотренных в течение 3-х минут на этапе Вериф.ТС]         = cast('' as nvarchar(50))

			, [Средний Processing time на этапе (время обработки заявки) ВК]     = case when sum(КоличествоЗаявок)<>0 then cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
																								else '0' end
			--, [Кол-во одобренных заявок после этапа Вериф.клиента]                          = cast(format(sum([VTS]),'0')as nvarchar(50))
			, [Кол-во одобренных заявок после этапа ВК] = cast(format(sum([VTS]),'0')as nvarchar(50))

			, [VTS] = sum([VTS])

			--, [Кол-во отказов со стороны сотрудников Вериф.клиента]                         = cast(format(sum([Отказано]),'0')as nvarchar(50)) 
			, [Кол-во отказов со стороны сотрудников ВК] = cast(format(sum([Отказано]),'0')as nvarchar(50)) 

			--, [Approval rate - % одобренных после этапа Вериф.клиента] = case when sum(  ИтогоПоСотруднику)<>0 then cast(format(isnull(case when sum(ИтогоПоСотруднику) <>0 then sum(VTS*1.0)/ sum(  ИтогоПоСотруднику) else 0 end ,0)  *100,'0')+N'%' as nvarchar(50)) else '0' END
			, [Approval rate - % одобренных после этапа ВК] = case when sum(ИтогоПоСотруднику)<>0 then cast(format(isnull(case when sum(ИтогоПоСотруднику) <>0 then sum(VTS*1.0)/ sum(  ИтогоПоСотруднику) else 0 end ,0)  *100,'0')+N'%' as nvarchar(50)) else '0' END

			--, [Approval rate % Логином]                                                     = cast('' as nvarchar(50))
			--, [Общее кол-во отложенных заявок на этапе Вериф.клиента]                       = cast(format(sum(Отложена),'0') as nvarchar(50))
			, [Общее кол-во отложенных заявок на этапе ВК] = cast(format(sum(Отложена),'0') as nvarchar(50))

			--, [Кол-во заявок на этапе, отправленных на доработку Вериф.клиента]             = cast(format(sum(Доработка),'0') as nvarchar(50))
			, [Кол-во заявок на этапе, отправленных на доработку ВК] = cast(format(sum(Доработка),'0') as nvarchar(50))

			--, [Take rate Уровень выдачи, выраженный через одобрения]                        = cast('' as nvarchar(50))
			--, [Кол-во заявок в статусе "Займ выдан",шт.]                                    = cast('' as nvarchar(50))

			--, [Take up % выданных заявок от одобренных на Call3] = case when sum([VTS])<>0 then cast(format(isnull(case when sum([VTS]) <>0 then sum([Заем выдан]*1.0)/ sum([VTS]) else 0 end ,0)  *100,'0')+N'%' as nvarchar(50)) else '0' END
    
		from #ReportByEmployeeAgg_VK 
		where Сотрудник in (select * from #curr_employee_vr)
		group by ProductType_Code, Дата
		) AS d
		join ( 
			SELECT 
				ProductType_Code
				, Дата
				--,[Общее кол-во уникальных заявок на этапе Вериф.клиента]                       = cast(format(sum(Новая),'0')as nvarchar(50))  
				,[Общее кол-во уникальных заявок на этапе ВК] = cast(format(sum(Новая_Уникальная),'0') AS nvarchar(50)) --DWH-2021

				--DWH-2286
				, [Первичный] = cast(format(sum([Новая_Уникальная Первичный]),'0')as nvarchar(50))
				, [Повторный] = cast(format(sum([Новая_Уникальная Повторный]),'0')as nvarchar(50))
				, [Докредитование] = cast(format(sum([Новая_Уникальная Докредитование]),'0')as nvarchar(50))
				, [Не определен] = cast(format(sum([Новая_Уникальная Не определен]),'0')as nvarchar(50))

				,[Take up Количество выданных заявок] = cast(format(sum([Заем выдан]),'0') as nvarchar(50))
				,[Заем выдан] = sum([Заем выдан])
				,[VTS] = sum([VTS])
			from #ReportByEmployeeAgg_VK
			group by ProductType_Code, Дата
		) new 
		ON new.ProductType_Code = d.ProductType_Code 
		AND new.Дата=d.Дата
		left join #waitTime_v AS w on w.ProductType_Code = d.ProductType_Code AND w.[Дата статуса]=d.Дата
		left join #postpone_unique_vk_daily AS u on u.ProductType_Code = d.ProductType_Code AND u.[Дата статуса] = d.Дата
		left join #call2 AS call2 on call2.ProductType_Code = d.ProductType_Code AND call2.[Дата статуса]=d.Дата
		left join (
			select 
				ProductType_Code
				, дата
				, count([Номер заявки]) cnt
			from #tty_vk
			where tty9_flag='tty'
			group by ProductType_Code, дата
		) tty9 on tty9.ProductType_Code = d.ProductType_Code AND tty9.Дата=d.Дата
		left join (
			select 
				ProductType_Code
				, дата
				, count([Номер заявки]) cnt
			from #tty_vk
			where tty8_flag='tty'
			group by ProductType_Code, дата
		) tty8 on tty8.ProductType_Code = d.ProductType_Code AND tty8.Дата=d.Дата
		left join (
			select 
				ProductType_Code
				, дата
				, count([Номер заявки]) cnt
			from #tty_vk
			where tty6_flag='tty'
			group by ProductType_Code, дата
		) tty6 on tty6.ProductType_Code = d.ProductType_Code AND tty6.Дата=d.Дата
		--
		left join (
			SELECT
				ProductType_Code
				, дата
				, count([Номер заявки]) cnt
			  from #tty_kd_vk
			where tty11_flag='tty'
			group by ProductType_Code, дата
		) tty_kd_vk11 on tty_kd_vk11.ProductType_Code = d.ProductType_Code AND tty_kd_vk11.Дата=d.Дата
		left join (
			SELECT
				ProductType_Code
				, дата
				, count([Номер заявки]) cnt
			  from #tty_kd_vk
			where tty10_flag='tty'
			group by ProductType_Code, дата
		) tty_kd_vk10 on tty_kd_vk10.ProductType_Code = d.ProductType_Code AND tty_kd_vk10.Дата=d.Дата
		left join (
			SELECT
				ProductType_Code
				, дата
				, count([Номер заявки]) cnt
			  from #tty_kd_vk
			where tty8_flag='tty'
			group by ProductType_Code, дата
		) tty_kd_vk8 on tty_kd_vk8.ProductType_Code = d.ProductType_Code AND tty_kd_vk8.Дата=d.Дата
		left join (
			SELECT
				ProductType_Code
				, дата
				, count([Номер заявки]) cnt
			from #tty_kd_vk
			group by ProductType_Code, дата
		) tty_kd_vk_cnt on tty_kd_vk_cnt.ProductType_Code = d.ProductType_Code AND tty_kd_vk_cnt.Дата=d.Дата

		--DWH-2309
		LEFT JOIN (
			SELECT 
				D.ProductType_Code,
				ДатаСтатуса = cast(D.[Дата статуса] AS date),
				cnt = count(DISTINCT D.[Номер заявки])
			from #t_dm_FedorVerificationRequests_without_coll_ALL AS D
			WHERE 1=1
				AND D.[Дата статуса] > @dt_from AND  D.[Дата статуса] < @dt_to
				AND D.Статус IN ('Договор подписан')
			GROUP BY D.ProductType_Code, cast(D.[Дата статуса] AS date)
		) AS ДоговорПодписан
		ON ДоговорПодписан.ProductType_Code = d.ProductType_Code 
		AND ДоговорПодписан.ДатаСтатуса = d.Дата


		IF @Page IN ('V.Daily.Common') OR @isFill_All_Tables = 1
		BEGIN
			DROP table if exists #unp_VK_TS_Daily

			select ProductType_Code, Дата, indicator, Qty 
			into #unp_VK_TS_Daily
			from 
			(
			SELECT
				v.ProductType_Code
				, v.Дата
				 , v.[Общее кол-во заведенных заявок Call2]
				 , v.[Кол-во автоматических отказов Call2]
				 , v.[%  автоматических отказов Call2]

				 , v.[Общее кол-во уникальных заявок на этапе ВК]

				, v.[Первичный]
				, v.[Повторный]
				, v.[Докредитование]
				, v.[Не определен]


				 , v.[Общее кол-во заявок на этапе ВК]

				 , v.[TTY - количество заявок рассмотренных в течение 9 минут на этапе ВК]
				 , v.[TTY - % заявок рассмотренных в течение 9 минут на этапе ВК]

				 , v.[TTY - количество заявок рассмотренных в течение 8 минут на этапе ВК]
				 , v.[TTY - % заявок рассмотренных в течение 8 минут на этапе ВК]

				 , v.[TTY - количество заявок рассмотренных в течение 6 минут на этапе ВК]
				 , v.[TTY - % заявок рассмотренных в течение 6 минут на этапе ВК]

				--, v.[TTY - количество заявок рассмотренных в течение 11 минут на этапах КД+ВК]
				--, v.[TTY - % заявок рассмотренных в течение 11 минут на этапах КД+ВК]

				--, v.[TTY - количество заявок рассмотренных в течение 10 минут на этапах КД+ВК]
				--, v.[TTY - % заявок рассмотренных в течение 10 минут на этапах КД+ВК]

				--, v.[TTY - количество заявок рассмотренных в течение 8 минут на этапах КД+ВК]
				--, v.[TTY - % заявок рассмотренных в течение 8 минут на этапах КД+ВК]

				 , v.[Среднее время заявки в ожидании очереди на этапе ВК]
				 , v.[Средний Processing time на этапе (время обработки заявки) ВК]

				 , v.[Кол-во одобренных заявок после этапа ВК]

				 , v.[Кол-во отказов со стороны сотрудников ВК]

				 , v.[Approval rate - % одобренных после этапа ВК]

				 --, v.[Approval rate % Логином]

				 --, v.[Контактность общая]
				 --, v.[Контактность по одобренным]
				 --, v.[Контактность по отказным]

				 , v.[Общее кол-во отложенных заявок на этапе ВК]
				 , v.[Уникальное кол-во отложенных заявок на этапе ВК]

				 , v.[Кол-во заявок на этапе, отправленных на доработку ВК]

				 --, v.[Take rate Уровень выдачи, выраженный через одобрения]
				 --, v.[Кол-во заявок в статусе "Займ выдан",шт.]
				 , v.[Take up Количество выданных заявок]

				 , v.[Take up % выданных заявок от одобренных на Call3]

				 , v.[Кол-во уникальных заявок в статусе Договор подписан]
         
				 --, t.[Общее кол-во уникальных заявок на этапе Вериф.ТС]                        
				 --, t.[Общее кол-во заявок на этапе Вериф.ТС]                                   
				 --, t.[TTY  - % заявок рассмотренных в течение 3-х минут на этапе Вериф.ТС]     
				 --, t.[Среднее время заявки в ожидании очереди на этапе Вериф.ТС]               
				 --, t.[Средний Processing time на этапе (время обработки заявки) Вериф.ТС]      
				 --, t.[Кол-во одобренных заявок после этапа Вериф.ТС]                           
				 --, t.[Кол-во отказов со стороны сотрудников Вериф.ТС]                          
				 --, t.[Approval rate - % одобренных после этапа Вериф.ТС]                       
				 --, t.[Общее кол-во отложенных заявок на этапе Вериф.ТС] 
				 --, t.[Уникальное кол-во отложенных заявок на этапе Вериф.ТС]
				 --, t.[Кол-во заявок на этапе, отправленных на доработку Вериф.ТС]              

			  from #p_VK AS v 
				--LEFT  join #p_TS  t on t.Дата=v.Дата
			) p
		unpivot
		  (Qty for indicator in (
				   [Общее кол-во заведенных заявок Call2]
				 , [Кол-во автоматических отказов Call2]
				 , [%  автоматических отказов Call2]

				 , [Общее кол-во уникальных заявок на этапе ВК]
				, [Первичный]
				, [Повторный]
				, [Докредитование]
				, [Не определен]

				 , [Общее кол-во заявок на этапе ВК]

				 , [TTY - количество заявок рассмотренных в течение 9 минут на этапе ВК]
				 , [TTY - % заявок рассмотренных в течение 9 минут на этапе ВК]

				 , [TTY - количество заявок рассмотренных в течение 8 минут на этапе ВК]
				 , [TTY - % заявок рассмотренных в течение 8 минут на этапе ВК]

				 , [TTY - количество заявок рассмотренных в течение 6 минут на этапе ВК]
				 , [TTY - % заявок рассмотренных в течение 6 минут на этапе ВК]
				--, [TTY - количество заявок рассмотренных в течение 11 минут на этапах КД+ВК]
				--, [TTY - % заявок рассмотренных в течение 11 минут на этапах КД+ВК]

				--, [TTY - количество заявок рассмотренных в течение 10 минут на этапах КД+ВК]
				--, [TTY - % заявок рассмотренных в течение 10 минут на этапах КД+ВК]

				--, [TTY - количество заявок рассмотренных в течение 8 минут на этапах КД+ВК]
				--, [TTY - % заявок рассмотренных в течение 8 минут на этапах КД+ВК]

				 , [Среднее время заявки в ожидании очереди на этапе ВК]
				 , [Средний Processing time на этапе (время обработки заявки) ВК]

				 , [Кол-во одобренных заявок после этапа ВК]

				 , [Кол-во отказов со стороны сотрудников ВК]

				 , [Approval rate - % одобренных после этапа ВК]

				 --, [Контактность общая]
				 --, [Контактность по одобренным]
				 --, [Контактность по отказным]

				 , [Общее кол-во отложенных заявок на этапе ВК]
				 , [Уникальное кол-во отложенных заявок на этапе ВК]

				 , [Кол-во заявок на этапе, отправленных на доработку ВК]

				 , [Take up Количество выданных заявок]

				 , [Take up % выданных заявок от одобренных на Call3]

				 , [Кол-во уникальных заявок в статусе Договор подписан]

				 --, [Общее кол-во уникальных заявок на этапе Вериф.ТС]                        
				 --, [Уникальное кол-во отложенных заявок на этапе Вериф.ТС]
				 --, [Общее кол-во заявок на этапе Вериф.ТС]
				 --, [TTY  - % заявок рассмотренных в течение 3-х минут на этапе Вериф.ТС]     
				 --, [Среднее время заявки в ожидании очереди на этапе Вериф.ТС]               
				 --, [Средний Processing time на этапе (время обработки заявки) Вериф.ТС]      
				 --, [Кол-во одобренных заявок после этапа Вериф.ТС]                           
				 --, [Кол-во отказов со стороны сотрудников Вериф.ТС]                          
				 --, [Approval rate - % одобренных после этапа Вериф.ТС]                 
				 --, [Общее кол-во отложенных заявок на этапе Вериф.ТС]   
				 --, [Кол-во заявок на этапе, отправленных на доработку Вериф.ТС]  
         
								)
		   ) as unpvt

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##unp_VK_TS_Daily
				SELECT * INTO ##unp_VK_TS_Daily FROM #unp_VK_TS_Daily

				DROP TABLE IF EXISTS ##indicator_for_vc_va
				SELECT * INTO ##indicator_for_vc_va FROM #indicator_for_vc_va
			END

			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_V_Daily_Common
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_V_Daily_Common AS T
				WHERE T.ProcessGUID = @ProcessGUID


				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_V_Daily_Common
				SELECT
					ProcessGUID = @ProcessGUID,
					--i.num_rows 
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					, empl_id =null
					, Employee =null
					, acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					, [Сумма] =null
					, Qty
					, Qty_dist=null
					, Tm_Qty =null--isnull(Tm_Qty,0.00)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_V_Daily_Common
				from #unp_VK_TS_Daily u 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
					join #indicator_for_vc_va i
						ON u.indicator = i.name_indicator
						--запрещенные "комбинации" типа продукта и индикатора
						AND NOT (
							   (i.num_rows IN (7.01, 7.02) AND PT.ProductType_Code IN ('installment', 'pdl'))
							OR (i.num_rows IN (9.01, 9.02) AND PT.ProductType_Code IN ('ALL', 'pdl'))
							OR (i.num_rows IN (11.01, 11.02) AND PT.ProductType_Code IN ('ALL', 'installment'))
						)

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'V.Daily.Common', @ProcessGUID

			END
			ELSE BEGIN
				SELECT
					--i.num_rows 
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					, empl_id =null
					, Employee =null
					, acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					, [Сумма] =null
					, Qty
					, Qty_dist=null
					, Tm_Qty =null--isnull(Tm_Qty,0.00)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_V_Daily_Common
				from #unp_VK_TS_Daily u 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
					join #indicator_for_vc_va i
						ON u.indicator = i.name_indicator
						--запрещенные "комбинации" типа продукта и индикатора
						AND NOT (
							   (i.num_rows IN (7.01, 7.02) AND PT.ProductType_Code IN ('installment', 'pdl'))
							OR (i.num_rows IN (9.01, 9.02) AND PT.ProductType_Code IN ('ALL', 'pdl'))
							OR (i.num_rows IN (11.01, 11.02) AND PT.ProductType_Code IN ('ALL', 'installment'))
						)

				RETURN 0
			END
		END 
		--// 'V.Daily.Common'


		IF @Page IN ('V.Daily.TTY') OR @isFill_All_Tables = 1
		BEGIN
			DROP table if exists #unp_KD_VK_TTY

			SELECT ProductType_Code, Дата, indicator, Qty 
			into #unp_KD_VK_TTY
			from 
			(
			SELECT
				v.ProductType_Code
				, v.Дата
				, v.[TTY - количество заявок рассмотренных в течение 11 минут на этапах КД+ВК]
				, v.[TTY - % заявок рассмотренных в течение 11 минут на этапах КД+ВК]

				, v.[TTY - количество заявок рассмотренных в течение 10 минут на этапах КД+ВК]
				, v.[TTY - % заявок рассмотренных в течение 10 минут на этапах КД+ВК]

				, v.[TTY - количество заявок рассмотренных в течение 8 минут на этапах КД+ВК]
				, v.[TTY - % заявок рассмотренных в течение 8 минут на этапах КД+ВК]
			  from #p_VK AS v 
			) p
			UNPIVOT
			(Qty for indicator in (
				[TTY - количество заявок рассмотренных в течение 11 минут на этапах КД+ВК]
				, [TTY - % заявок рассмотренных в течение 11 минут на этапах КД+ВК]

				, [TTY - количество заявок рассмотренных в течение 10 минут на этапах КД+ВК]
				, [TTY - % заявок рассмотренных в течение 10 минут на этапах КД+ВК]

				, [TTY - количество заявок рассмотренных в течение 8 минут на этапах КД+ВК]
				, [TTY - % заявок рассмотренных в течение 8 минут на этапах КД+ВК]
				)
		   ) as unpvt

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##unp_KD_VK_TTY
				SELECT * INTO ##unp_KD_VK_TTY FROM #unp_KD_VK_TTY
			END

			IF @isFill_All_Tables = 1
			BEGIN
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_V_Daily_TTY AS T
				WHERE T.ProcessGUID = @ProcessGUID

				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_V_Daily_TTY
				SELECT
					ProcessGUID = @ProcessGUID,
					--i.num_rows 
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					, empl_id =null
					  , Employee =null
					, acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					, [Сумма] =null
					  , Qty
					  , Qty_dist=null
					  , Tm_Qty =null--isnull(Tm_Qty,0.00)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_V_Daily_TTY
				from #unp_KD_VK_TTY u 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
					join #indicator_for_vc_va i
						ON u.indicator = i.name_indicator
						--запрещенные "комбинации" типа продукта и индикатора
						AND NOT (
							   (i.num_rows IN (41.01, 41.02) AND PT.ProductType_Code IN ('installment', 'pdl'))
							OR (i.num_rows IN (43.01, 43.02) AND PT.ProductType_Code IN ('ALL', 'pdl'))
							OR (i.num_rows IN (45.01, 45.02) AND PT.ProductType_Code IN ('ALL', 'installment'))
						)
				--ORDER BY i.num_rows

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'V.Daily.TTY', @ProcessGUID
			END
			ELSE BEGIN
				SELECT
					--i.num_rows 
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					, empl_id =null
					  , Employee =null
					, acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					, [Сумма] =null
					  , Qty
					  , Qty_dist=null
					  , Tm_Qty =null--isnull(Tm_Qty,0.00)
				from #unp_KD_VK_TTY AS u 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
					join #indicator_for_vc_va i
						ON u.indicator = i.name_indicator
						--запрещенные "комбинации" типа продукта и индикатора
						AND NOT (
							   (i.num_rows IN (41.01, 41.02) AND PT.ProductType_Code IN ('installment', 'pdl'))
							OR (i.num_rows IN (43.01, 43.02) AND PT.ProductType_Code IN ('ALL', 'pdl'))
							OR (i.num_rows IN (45.01, 45.02) AND PT.ProductType_Code IN ('ALL', 'installment'))
						)
				--ORDER BY i.num_rows

				RETURN 0
			END
		END
		--// 'V.Daily.TTY'

	END
	--// 'V.Daily.Common', 'V.Daily.TTY'


	IF @Page IN ('KD.Monthly.Common', 'KD.Monthly.Autoapprove') OR @isFill_All_Tables = 1
	BEGIN
 
		DROP table if exists #verif_KC_m

		SELECT
			r.ProductType_Code
			, [Дата статуса] = cast(format([Дата статуса],'yyyyMM01') as date)
			, cnt = count(distinct [Номер заявки])
		into #verif_KC_m
		from #t_dm_FedorVerificationRequests_without_coll_ALL AS r 
		WHERE [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
			AND  Статус='Верификация КЦ' and [Статус следующий]='Отказано'
		group by r.ProductType_Code, cast(format([Дата статуса],'yyyyMM01') as date) 
 

		-- TTY
   
		drop table if exists #tty_kd_m
		/*
		--var 1
		select ProductType_Code
			, Дата
			, [Номер заявки]
			, Сотрудник
			, [ФИО сотрудника верификации/чекер]
			--, ВремяЗатрачено
			, cast(cast(ВремяЗатрачено as datetime) as time) ВремяЗатрачено
			--, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:07:00' then '-' else 'tty' end tty_flag
			, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:02:00' then '-' else 'tty' end tty_flag
		into #tty_kd_m
		from #fedor_verificator_report where status='task:В работе'
		*/
		--var 2
		select 
			A.ProductType_Code
			, A.Дата
			, A.[Номер заявки]
			, ВремяЗатрачено = cast(cast(A.ВремяЗатрачено as datetime) as time)
			, tty_flag = CASE when cast(cast(A.ВремяЗатрачено as datetime) as time)>'00:02:00' then '-' else 'tty' end
		into #tty_kd_m
		FROM #fedor_verificator_report AS A
		WHERE A.status='task:В работе'
		--FROM (
		--		SELECT 
		--			R.ProductType_Code,
		--			R.[Номер заявки],
		--			Дата = max(R.Дата),
		--			ВремяЗатрачено = sum(R.ВремяЗатрачено)
		--		FROM #fedor_verificator_report AS R
		--		WHERE R.status='task:В работе'
		--		GROUP BY R.ProductType_Code, R.[Номер заявки]
		--	) AS A

		DROP table if exists #waitTime_m

		;with r as
		(
		select 
		r.ProductType_Code
		, [Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
		, [Дата статуса]
		, [Дата след.статуса]
		, Работник [ФИО сотрудника верификации/чекер]
		, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику], [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]
		 from #t_dm_FedorVerificationRequests_without_coll_ALL AS r
		 where [Состояние заявки]='Ожидание' 
			and r.Статус='Контроль данных' 
			--DWH-2019
			AND NOT (
				r.Задача='task:Новая'
				AND r.[Задача следующая] = 'task:Автоматически отложено'
			)

			and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
		 and (Работник in (select e.Employee from #KDEmployees e)
		 or Назначен in (select e.Employee from #KDEmployees e))
		)

		select 
			r.ProductType_Code
			, [Дата статуса]=cast(format([Дата статуса],'yyyyMM01') as date) 
			 , duration = avg( datediff(second,[Дата статуса], [Дата след.статуса]))
		  into #waitTime_m
		from  r
		where  datediff(second,[Дата статуса], [Дата след.статуса])>0
		group by r.ProductType_Code, cast(format([Дата статуса],'yyyyMM01') as date) 
 

		DROP table if exists #all_requests_m
  
		select 
			D.ProductType_Code
			,[Дата заведения заявки] =format(D.[Дата заведения заявки] ,'yyyyMM01')
			,Qty = count(distinct D.[Номер заявки])
		into #all_requests_m
		from #t_dm_FedorVerificationRequests_without_coll_ALL AS D
		join #calendar c on c.dt_day=D.[Дата заведения заявки]
		where  D.[Дата статуса]>@dt_from and  D.[Дата статуса]<@dt_to
		group by D.ProductType_Code, format(D.[Дата заведения заявки] ,'yyyyMM01')

		--#all_requests_m
		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##all_requests_m
			SELECT * INTO ##all_requests_m FROM #all_requests_m

			DROP TABLE IF EXISTS ##calendar
			SELECT * INTO ##calendar FROM #calendar
		END

		---
		-- посчитаем количество уникальных отложенных КД
		-- считаем уникальных отложенных по КД
        drop table if exists #ReportByEmployeeAgg_KD_UniquePostone_m

        ;with c1 as (
          select 
				ProductType_Code
				, Дата = cast(format([Дата],'yyyyMM01') as date)
              -- , Сотрудник   
               --, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
			    , isnull(count(distinct case when status='Отложена' then [Номер заявки] end), 0) [ОтложенаУникальныеKD]
               
            from #fedor_verificator_report
			--DWH-1806
			where Сотрудник in (select * from #curr_employee_cd)
			--01.01 не рабочий день, данные за этот день не учитываем
			and Дата != datefromparts(year(Дата), 1,1)
           group by ProductType_Code, cast(format([Дата],'yyyyMM01') as date) --Дата
              -- , Сотрудник
        )        
          select c1.*              
            into #ReportByEmployeeAgg_KD_UniquePostone_m
            from c1 

		drop table if exists #postpone_unique_kd_m
		select 
			ProductType_Code,
			[Дата статуса]=cast(format([Дата],'yyyyMM01') as date),
			sum(p.ОтложенаУникальныеKD) ОтложенаУникальныеKD 
		into #postpone_unique_kd_m
		from #ReportByEmployeeAgg_KD_UniquePostone_m p
		group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date)


		DROP table if exists #p_m 

		SELECT d.* , cast(format(r.Qty,'0') as nvarchar(50))[Общее кол-во заведенных заявок] 
		,  cast(
			  format(w.duration/60/60 ,'00')+N':'+format( (w.duration/60 -  60* (w.duration/60/60)),'00') +N':'+format((w.duration - 60 * (duration/60)),'00')
		  as nvarchar(50)) [Среднее время заявки в ожидании очереди на этапе]
		  , new.[Общее кол-во уникальных заявок на этапе]

			, new.[Первичный]
			, new.[Повторный]
			, new.[Докредитование]
			, new.[Не определен]

			, cast(tty.cnt as nvarchar(50)) AS [TTY  - количество заявок рассмотренных в течение 2 минут на этапе]
		  , cast(format(case when [Общее кол-во заявок на этапе]<>0 then 100*tty.cnt*1.0/[Общее кол-во заявок на этапе] else 0 end,'0')+N'%' as nvarchar(50)) AS [TTY  - % заявок рассмотренных в течение 2 минут на этапе]
				, cast(kc.cnt as nvarchar(50)) AS [Кол-во автоматических отказов Логином]
				 , cast(case when r.Qty<>0 then  format(100.0*kc.cnt/r.Qty,'0') else '0' end +N'%' as nvarchar(50)) AS [%  автоматических отказов Логином]
				 , [Уникальное кол-во отложенных заявок на этапе] = cast(format((u.ОтложенаУникальныеKD),'0') as nvarchar(50))

			, cast(case when r.Qty<>0 then format(100.0*d.[Кол-во заявок, не вернувшихся с доработки]/r.Qty,'0.0') else '0' end +N'%' as nvarchar(50))
				AS [% заявок, не вернувшихся с доработки]

			, cast(format(Autoappr.Autoapprove_KD,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД]
			, cast(format(Autoappr.Autoapprove_KD_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД, финальное одобрение]

			, cast(format(Autoappr.Autoapprove_VK,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove ВК]
			, cast(format(Autoappr.Autoapprove_VK_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove ВК, финальное одобрение]

			, cast(format(Autoappr.Autoapprove_KD_VK,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД + ВК]
			, cast(format(Autoappr.Autoapprove_KD_VK_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove КД + ВК, финальное одобрение]

			, cast(format(Autoappr.Autoapprove_KD_VK_total,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove (всего)]
			, cast(format(Autoappr.Autoapprove_KD_VK_total_fin_appr,'0') as nvarchar(50)) AS [Уникальное количество заявок autoapprove (всего), финальное одобрение]
			--
			, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
				AS [% заявок autoapprove пропустивших этап КД (не назначался КД)]
			, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD_fin_appr / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
				AS [% заявок autoapprove пропустивших этап КД (не назначался КД), финальное одобрение]

			, cast(case when Autoappr.VK_IN <> 0 then format(100.0 * Autoappr.Autoapprove_VK / Autoappr.VK_IN,'0.0') else '0' end +N'%' as nvarchar(50))
				AS [% заявок autoapprove от поступивших ВК (не назначался ВК)]
			, cast(case when Autoappr.VK_IN <> 0 then format(100.0 * Autoappr.Autoapprove_VK_fin_appr / Autoappr.VK_IN,'0.0') else '0' end +N'%' as nvarchar(50))
				AS [% заявок autoapprove от поступивших ВК (не назначался ВК), финальное одобрение]

			, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD_VK / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
				AS [% заявок autoapprove КД + ВК (от поступивших на КД)]
			, cast(case when Autoappr.KD_IN <> 0 then format(100.0 * Autoappr.Autoapprove_KD_VK_fin_appr / Autoappr.KD_IN,'0.0') else '0' end +N'%' as nvarchar(50))
				AS [% заявок autoapprove КД + ВК (от поступивших на КД), финальное одобрение]
		into #p_m 
		from (
			select 
				a.ProductType_Code
				, Дата=cast(format(Дата,'yyyyMM01') as date)
				 , cast(format(sum(КоличествоЗаявок),'0') as nvarchar(50)) [Общее кол-во заявок на этапе]
         
				 , cast(format(sum([ВК]),'0')as nvarchar(50)) [Кол-во одобренных заявок после этапа] 

				 , cast(format(sum(Отложена),'0') as nvarchar(50)) [Общее кол-во отложенных заявок на этапе]

				 , cast(format(sum(Доработка),'0') as nvarchar(50))[Кол-во заявок на этапе, отправленных на доработку]

				 , case when  sum(  ИтогоПоСотруднику)<>0 then 
					cast(format(isnull(case when sum(ИтогоПоСотруднику) <>0 then sum(ВК*1.0)/ sum(  ИтогоПоСотруднику) else 0 end ,0)  *100,'0')+N'%' as nvarchar(50)) 
					else '0'
				   end
					[Approval rate - % одобренных после этапа]

				 , cast(format(sum([Отказано]),'0')as nvarchar(50)) [Кол-во отказов со стороны сотрудников]      
      
				 , case when sum(КоличествоЗаявок)<>0 then 
					cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
				  else '0' end
				   [Средний Processing time на этапе (время обработки заявки)]
         
				, cast(format(sum([Не вернувшиеся с доработки]),'0') as nvarchar(50)) AS [Кол-во заявок, не вернувшихся с доработки]

			  from #ReportByEmployeeAgg a 
			  where сотрудник in (select * from #curr_employee_cd)
			 --01.01 не рабочий день, данные за этот день не учитываем
				and Дата != DATEFROMPARTS(year(Дата), 1,1)
			 group by a.ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
		) AS d  

		LEFT JOIN (
			SELECT
				a.ProductType_Code
				, Дата=cast(format(Дата,'yyyyMM01') as date)
				 , cast(format(sum(Новая_Уникальная),'0')as nvarchar(50)) [Общее кол-во уникальных заявок на этапе] --DWH-2021
				 --DWH-2286
				 , cast(format(sum([Новая_Уникальная Первичный]),'0')as nvarchar(50)) [Первичный]
				 , cast(format(sum([Новая_Уникальная Повторный]),'0')as nvarchar(50)) [Повторный]
				 , cast(format(sum([Новая_Уникальная Докредитование]),'0')as nvarchar(50)) [Докредитование]
				 , cast(format(sum([Новая_Уникальная Не определен]),'0')as nvarchar(50)) [Не определен]

			  from #ReportByEmployeeAgg a
			  --01.01 не рабочий день, данные за этот день не учитываем
			  WHERE Дата != DATEFROMPARTS(year(Дата), 1,1)
			  GROUP BY a.ProductType_Code, cast(format(Дата,'yyyyMM01') as date)

			--DWH-1884 закомментарил
			--SELECT Дата=cast(format(Дата,'yyyyMM01') as date)
			--	 , cast(format(sum([ИтогоПоСотруднику]),'0')as nvarchar(50)) [Общее кол-во уникальных заявок на этапе]
			--  from #ReportByEmployeeAgg a
			--  --01.01 не рабочий день, данные за этот день не учитываем
			--  WHERE Дата != DATEFROMPARTS(year(Дата), 1,1)
			--	--Только по сотрудникам, иначе в отчете будут учитываться данные от системых пользователей.
			--	AND a.Сотрудник in (select * from #curr_employee_cd)
			--  GROUP BY cast(format(Дата,'yyyyMM01') as date)

		) new 
		ON new.ProductType_Code = d.ProductType_Code 
		AND new.Дата=d.Дата

		join #all_requests_m AS r on r.ProductType_Code = d.ProductType_Code AND r.[Дата заведения заявки]=d.Дата
		left join #waitTime_m AS w on w.ProductType_Code = d.ProductType_Code AND w.[Дата статуса]=d.Дата
		left join #postpone_unique_kd_m AS u on u.ProductType_Code = d.ProductType_Code AND u.[Дата статуса] = d.Дата
		left join (
			select 
				ProductType_Code
				, дата=cast(format(Дата,'yyyyMM01') as date)
				, count([Номер заявки]) cnt
			  -- , ВремяЗатрачено 
			  from #tty_kd_m
			where tty_flag='tty'
			group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date) 

		) tty on tty.ProductType_Code = d.ProductType_Code AND tty.Дата=d.Дата

		LEFT join #verif_KC_m AS kc on kc.ProductType_Code = d.ProductType_Code AND kc.[Дата статуса]=d.Дата


		--DWH-2374
		LEFT JOIN (
			select 
				a.ProductType_Code
				, Дата=cast(format(Дата,'yyyyMM01') as date)
				, sum(Autoapprove_KD) AS Autoapprove_KD
				, sum(Autoapprove_KD_fin_appr) AS Autoapprove_KD_fin_appr

				, sum(Autoapprove_VK) AS Autoapprove_VK
				, sum(Autoapprove_VK_fin_appr) AS Autoapprove_VK_fin_appr

				, sum(Autoapprove_KD_VK) AS Autoapprove_KD_VK
				, sum(Autoapprove_KD_VK_fin_appr) AS Autoapprove_KD_VK_fin_appr

				, sum(Autoapprove_KD_VK_total) AS Autoapprove_KD_VK_total
				, sum(Autoapprove_KD_VK_total_fin_appr) AS Autoapprove_KD_VK_total_fin_appr

				, sum(KD_IN) AS KD_IN
				, sum(KD_IN_fin_appr) AS KD_IN_fin_appr

				, sum(VK_IN) AS VK_IN
				, sum(VK_IN_fin_appr) AS VK_IN_fin_appr
			  from #ReportByEmployeeAgg AS a
			  --01.01 не рабочий день, данные за этот день не учитываем
			  WHERE Дата != DATEFROMPARTS(year(Дата), 1,1)
			  GROUP BY a.ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
		) Autoappr on Autoappr.ProductType_Code = d.ProductType_Code AND Autoappr.Дата = d.Дата

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##p_m
			SELECT * INTO ##p_m FROM #p_m
		END

		 /*
		 use devdb
		 go
		 drop table if exists devdb.dbo.p_
		 select * into devdb.dbo.p_ from #p 
		 */
		DROP table if exists #unp_m

		IF @Page IN ('KD.Monthly.Common') OR @isFill_All_Tables = 1
		BEGIN
			select ProductType_Code, Дата, indicator, Qty 
			into #unp_m
			from 
			(
				select 
					ProductType_Code
					, Дата
					 , [Общее кол-во заведенных заявок]
					 , [Кол-во автоматических отказов Логином]
					 , [%  автоматических отказов Логином]
					 , [Общее кол-во уникальных заявок на этапе]

					, [Первичный]
					, [Повторный]
					, [Докредитование]
					, [Не определен]

					 , [Общее кол-во заявок на этапе]
					 , [TTY  - количество заявок рассмотренных в течение 2 минут на этапе]
					 , [TTY  - % заявок рассмотренных в течение 2 минут на этапе]
					 , [Среднее время заявки в ожидании очереди на этапе]
					 , [Средний Processing time на этапе (время обработки заявки)]
					 , [Кол-во одобренных заявок после этапа]
					 , [Кол-во отказов со стороны сотрудников]
					 , [Approval rate - % одобренных после этапа]
					 , [Общее кол-во отложенных заявок на этапе]
					 , [Уникальное кол-во отложенных заявок на этапе]
					 , [Кол-во заявок на этапе, отправленных на доработку]
					 , [Кол-во заявок, не вернувшихся с доработки]
					 , [% заявок, не вернувшихся с доработки]
				  from #p_m
     
				) p
			unpivot
			  (Qty for indicator in (
									  [Общее кол-во заведенных заявок]
									 ,[Кол-во автоматических отказов Логином]
									 ,[%  автоматических отказов Логином]
									 ,[Общее кол-во уникальных заявок на этапе]
									, [Первичный]
									, [Повторный]
									, [Докредитование]
									, [Не определен]
									 ,[Общее кол-во заявок на этапе]
									 ,[TTY  - количество заявок рассмотренных в течение 2 минут на этапе]
									 ,[TTY  - % заявок рассмотренных в течение 2 минут на этапе]
									 ,[Среднее время заявки в ожидании очереди на этапе]
									 ,[Средний Processing time на этапе (время обработки заявки)]
									 ,[Кол-во одобренных заявок после этапа]
									 ,[Кол-во отказов со стороны сотрудников]
									 ,[Approval rate - % одобренных после этапа]
									 ,[Общее кол-во отложенных заявок на этапе]
									 ,[Уникальное кол-во отложенных заявок на этапе]
									 ,[Кол-во заявок на этапе, отправленных на доработку]
									 ,[Кол-во заявок, не вернувшихся с доработки]
									 ,[% заявок, не вернувшихся с доработки]
									)
			   ) as unpvt

				IF @isFill_All_Tables = 1
				BEGIN
					--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Common
					DELETE T
					FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Common AS T
					WHERE T.ProcessGUID = @ProcessGUID

					INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Common
					SELECT
						ProcessGUID = @ProcessGUID,
						--i.num_rows 
						num_rows = i.num_rows + 0.1 * PT.ProductType_Order
						--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
						,empl_id =null
						,Employee =null
						,acc_period =Дата
						--,indicator =name_indicator
						,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
						,[Сумма] =null
						,Qty
						,Qty_dist=null
						,Tm_Qty =null--isnull(Tm_Qty,0.00)
					--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Common
					FROM #unp_m u join #indicator_for_controldata i on u.indicator=i.name_indicator
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = u.ProductType_Code
					--ORDER BY i.num_rows

					INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
					SELECT getdate(), 'KD.Monthly.Common', @ProcessGUID

				END
				ELSE BEGIN
				   select 
					--i.num_rows 
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					,empl_id =null
					   ,Employee =null
					 ,acc_period =Дата
					  --,indicator =name_indicator
					  ,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					 ,[Сумма] =null
					   , Qty
					   ,Qty_dist=null
					   , Tm_Qty =null--isnull(Tm_Qty,0.00)
					from #unp_m AS u join #indicator_for_controldata AS i on u.indicator=i.name_indicator
						INNER JOIN #t_ProductType AS PT
							ON PT.ProductType_Code = u.ProductType_Code
					--ORDER BY i.num_rows

					RETURN 0
				END
		END --'KD.Monthly.Common'


		DROP table if exists #Autoapprove_unp_m

		IF @Page IN ('KD.Monthly.Autoapprove') OR @isFill_All_Tables = 1
		BEGIN
			select ProductType_Code, Дата, indicator, Qty 
			into #Autoapprove_unp_m
			from 
			(
				SELECT
					ProductType_Code
					, Дата
					 --, [Уникальное количество заявок autoapprove]
					 --, [% заявок autoapprove от одобренных КД]
					, [Уникальное количество заявок autoapprove КД]
					, [Уникальное количество заявок autoapprove КД, финальное одобрение]

					, [Уникальное количество заявок autoapprove ВК]
					, [Уникальное количество заявок autoapprove ВК, финальное одобрение]

					, [Уникальное количество заявок autoapprove КД + ВК]
					, [Уникальное количество заявок autoapprove КД + ВК, финальное одобрение]

					, [Уникальное количество заявок autoapprove (всего)]
					, [Уникальное количество заявок autoapprove (всего), финальное одобрение]

					, [% заявок autoapprove пропустивших этап КД (не назначался КД)]
					, [% заявок autoapprove пропустивших этап КД (не назначался КД), финальное одобрение]

					, [% заявок autoapprove от поступивших ВК (не назначался ВК)]
					, [% заявок autoapprove от поступивших ВК (не назначался ВК), финальное одобрение]

					, [% заявок autoapprove КД + ВК (от поступивших на КД)]
					, [% заявок autoapprove КД + ВК (от поступивших на КД), финальное одобрение]
				  from #p_m
			) AS p
			unpivot
			  (Qty for indicator in (
					 --[Уникальное количество заявок autoapprove]
					 --, [% заявок autoapprove от одобренных КД]
					  [Уникальное количество заявок autoapprove КД]
					, [Уникальное количество заявок autoapprove КД, финальное одобрение]

					, [Уникальное количество заявок autoapprove ВК]
					, [Уникальное количество заявок autoapprove ВК, финальное одобрение]

					, [Уникальное количество заявок autoapprove КД + ВК]
					, [Уникальное количество заявок autoapprove КД + ВК, финальное одобрение]

					, [Уникальное количество заявок autoapprove (всего)]
					, [Уникальное количество заявок autoapprove (всего), финальное одобрение]

					, [% заявок autoapprove пропустивших этап КД (не назначался КД)]
					, [% заявок autoapprove пропустивших этап КД (не назначался КД), финальное одобрение]

					, [% заявок autoapprove от поступивших ВК (не назначался ВК)]
					, [% заявок autoapprove от поступивших ВК (не назначался ВК), финальное одобрение]

					, [% заявок autoapprove КД + ВК (от поступивших на КД)]
					, [% заявок autoapprove КД + ВК (от поступивших на КД), финальное одобрение]
					)
			   ) as unpvt

			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Autoapprove
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Autoapprove AS T
				WHERE T.ProcessGUID = @ProcessGUID

				/*
				--var 1
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Autoapprove
				SELECT
					ProcessGUID = @ProcessGUID,
					--i.num_rows 
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					,empl_id =null
					,Employee =null
					,acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					,[Сумма] =null
					,Qty
					,Qty_dist=null
					,Tm_Qty =null--isnull(Tm_Qty,0.00)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Autoapprove
				FROM #Autoapprove_unp_m AS u 
					INNER JOIN #indicator_for_Autoapprove AS i
						ON u.indicator=i.name_indicator
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
				--ORDER BY i.num_rows
				*/

				--var 2
				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Autoapprove
				SELECT
					ProcessGUID = @ProcessGUID,
					--i.num_rows 
					num_rows = i.num_rows + 100 * PT.ProductType_Order
					,empl_id =null
					,Employee =null
					,acc_period =Дата
					,indicator =name_indicator
					,[Сумма] =null
					,Qty
					,Qty_dist=null
					,Tm_Qty =null
				FROM #Autoapprove_unp_m AS u 
					INNER JOIN #indicator_for_Autoapprove AS i
						ON u.indicator=i.name_indicator
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
				UNION
				SELECT DISTINCT
					ProcessGUID = @ProcessGUID,
					num_rows = 100 * PT.ProductType_Order
					,empl_id =null
					,Employee =null
					,acc_period = u.Дата
					,indicator = PT.ProductType_Name
					,[Сумма] =null
					,Qty = NULL
					,Qty_dist=null
					,Tm_Qty =null
				FROM #Autoapprove_unp_m AS u 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code


				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.Autoapprove', @ProcessGUID
			END
			ELSE BEGIN
				/*
				--var 1
				SELECT
					--i.num_rows 
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					,empl_id =null
					,Employee =null
					,acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					,[Сумма] =null
					,Qty
					,Qty_dist=null
					,Tm_Qty =null--isnull(Tm_Qty,0.00)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_KD_Monthly_Autoapprove
				FROM #Autoapprove_unp_m AS u 
					INNER JOIN #indicator_for_Autoapprove AS i
						ON u.indicator=i.name_indicator
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
				--ORDER BY i.num_rows
				*/

				--var 2
				SELECT
					--i.num_rows 
					num_rows = i.num_rows + 100 * PT.ProductType_Order
					,empl_id =null
					,Employee =null
					,acc_period =Дата
					,indicator =name_indicator
					,[Сумма] =null
					,Qty
					,Qty_dist=null
					,Tm_Qty =null
				FROM #Autoapprove_unp_m AS u 
					INNER JOIN #indicator_for_Autoapprove AS i
						ON u.indicator=i.name_indicator
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
				UNION
				SELECT DISTINCT
					num_rows = 100 * PT.ProductType_Order
					,empl_id =null
					,Employee =null
					,acc_period = u.Дата
					,indicator = PT.ProductType_Name
					,[Сумма] =null
					,Qty = NULL
					,Qty_dist=null
					,Tm_Qty =null
				FROM #Autoapprove_unp_m AS u 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code

				RETURN 0
			END
		END --'KD.Monthly.Autoapprove'

	END
	--// 'KD.Monthly.Common', 'KD.Monthly.Autoapprove'





	IF @page IN ('V.Monthly.Common', 'V.Monthly.TTY') OR @isFill_All_Tables = 1
	BEGIN

		drop table if exists #tty_vk_m
		/*
		--var 1
		select ProductType_Code
			, Дата
			, [Номер заявки]
			, Сотрудник
			, [ФИО сотрудника верификации/чекер]
			, cast(cast(ВремяЗатрачено as datetime) as time) ВремяЗатрачено
			, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:09:00' then '-' else 'tty' end tty9_flag
			, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:08:00' then '-' else 'tty' end tty8_flag
			, case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:06:00' then '-' else 'tty' end tty6_flag
		into #tty_vk_m
		from #fedor_verificator_report_VK where status='task:В работе'
		*/
		--var 2
		select 
			A.ProductType_Code
			, A.Дата
			, A.[Номер заявки]
			, ВремяЗатрачено = cast(cast(A.ВремяЗатрачено as datetime) as time)
			, tty9_flag = CASE when cast(cast(ВремяЗатрачено as datetime) as time)>'00:09:00' then '-' else 'tty' end
			, tty8_flag = CASE when cast(cast(ВремяЗатрачено as datetime) as time)>'00:08:00' then '-' else 'tty' end 
			, tty6_flag = CASE when cast(cast(ВремяЗатрачено as datetime) as time)>'00:06:00' then '-' else 'tty' end 
		into #tty_vk_m
		FROM #fedor_verificator_report_vk AS A
		WHERE A.status='task:В работе'
		--FROM (
		--		SELECT 
		--			R.ProductType_Code,
		--			R.[Номер заявки],
		--			Дата = max(R.Дата),
		--			ВремяЗатрачено = sum(R.ВремяЗатрачено)
		--		FROM #fedor_verificator_report_vk AS R
		--		WHERE R.status='task:В работе'
		--		GROUP BY R.ProductType_Code, R.[Номер заявки]
		--	) AS A


		DROP TABLE IF EXISTS #tty_kd_vk_m
		SELECT
			A.ProductType_Code
			, A.Дата
			, A.[Номер заявки]
			, ВремяЗатрачено = cast(cast(A.ВремяЗатрачено as datetime) as time)
			, tty11_flag = CASE when cast(cast(ВремяЗатрачено as datetime) as time)>'00:11:00' then '-' else 'tty' end
			, tty10_flag = CASE when cast(cast(ВремяЗатрачено as datetime) as time)>'00:10:00' then '-' else 'tty' end
			, tty8_flag = CASE when cast(cast(ВремяЗатрачено as datetime) as time)>'00:08:00' then '-' else 'tty' end 
		into #tty_kd_vk_m
		FROM (
				SELECT K.ProductType_Code, K.[Номер заявки], K.Дата, K.ВремяЗатрачено
				FROM #fedor_verificator_report AS K
				WHERE K.status='task:В работе'
				UNION ALL
				SELECT V.ProductType_Code, V.[Номер заявки], V.Дата, V.ВремяЗатрачено
				FROM #fedor_verificator_report_vk AS V
				WHERE V.status='task:В работе'
			) AS A
		--FROM (
		--		SELECT 
		--			R.ProductType_Code,
		--			R.[Номер заявки],
		--			Дата = max(R.Дата),
		--			ВремяЗатрачено = sum(R.ВремяЗатрачено)
		--		FROM (
		--				SELECT K.ProductType_Code, K.[Номер заявки], K.Дата, K.ВремяЗатрачено
		--				FROM #fedor_verificator_report AS K
		--				WHERE K.status='task:В работе'
		--				UNION ALL
		--				SELECT V.ProductType_Code, V.[Номер заявки], V.Дата, V.ВремяЗатрачено
		--				FROM #fedor_verificator_report_vk AS V
		--				WHERE V.status='task:В работе'
		--			) AS R
		--		GROUP BY R.ProductType_Code, R.[Номер заявки]
		--	) AS A


		-- Пришло на call2
		DROP table if exists #call2_m


		select ProductType_Code
			, [Дата статуса]=cast(format([Дата статуса],'yyyyMM01') as date)
			, count(distinct [Номер заявки]) Qty
			, sum(case when [Статус следующий]='Отказано' then 1 else 0 end) Qty_rejected
		into #call2_m
		from #t_dm_FedorVerificationRequests_without_coll_ALL AS r
		WHERE Статус ='Верификация Call 2'  and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
		group by ProductType_Code, cast(format([Дата статуса],'yyyyMM01') as date)

		--select * from #call2

		DROP table if exists #waitTime_v_m

		;with r as
		(
		select 
		r.ProductType_Code
		, [Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
		, [Дата статуса]
		, [Дата след.статуса]
		, Работник [ФИО сотрудника верификации/чекер]
		, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику], [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату],Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]
		from #t_dm_FedorVerificationRequests_without_coll_ALL AS r
		where [Состояние заявки]='Ожидание' 
			and r.Статус='Верификация клиента' 
			--DWH-2019
			AND NOT (
				r.Задача='task:Новая'
				AND r.[Задача следующая] = 'task:Автоматически отложено'
			)

			and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to

		and (Работник in (select e.Employee from #VKEmployees e)
		or Назначен in (select e.Employee from #VKEmployees e))
		)
		select r.ProductType_Code
			, [Дата статуса]=cast(format([Дата статуса],'yyyyMM01') as date) 
			, duration = avg( datediff(second,[Дата статуса], [Дата след.статуса]))
		into #waitTime_v_m
		from  r
		where  datediff(second,[Дата статуса], [Дата след.статуса])>0
		group by r.ProductType_Code, cast(format([Дата статуса],'yyyyMM01') as date) 
 

		-- посчитаем количество уникальных отложенных VK
		DROP table if exists #postpone_unique_vk

		--2023-11-20. Исправление ошибки
		--select 
		--	[Дата статуса]=cast(format([Дата],'yyyyMM01') as date),
		--	sum(p.ОтложенаУникальныеVK) ОтложенаУникальныеVK 
		--into #postpone_unique_vk
		--from #ReportByEmployeeAgg_VK_UniquePostone p
		--group by cast(format(Дата,'yyyyMM01') as date)

		select 
			ProductType_Code
			, [Дата статуса] = cast(format(p.Дата,'yyyyMM01') as date)
			, ОтложенаУникальныеVK = sum(p.ОтложенаУникальныеVK) 
		into #postpone_unique_vk
		from --#ReportByEmployeeAgg_VK_UniquePostone p
			(
				select c1.*              
				from (
					SELECT
						ProductType_Code
						, Дата = cast(format([Дата],'yyyyMM01') as date)
						-- , Сотрудник   
						--, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
						, [ОтложенаУникальныеVK] = isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) 
					from #fedor_verificator_report_VK
					group by ProductType_Code, cast(format([Дата],'yyyyMM01') as date) --Дата
				) AS c1 
			) AS p
		group by ProductType_Code, cast(format(p.Дата,'yyyyMM01') as date)

		DROP table if exists #p_VK_m

		SELECT d.* 
		 , uniqie_vk_month.[Общее кол-во уникальных заявок на этапе ВК]

		, uniqie_vk_month.[Первичный]
		, uniqie_vk_month.[Повторный]
		, uniqie_vk_month.[Докредитование]
		, uniqie_vk_month.[Не определен]

		 , uniqie_vk_month.[Take up Количество выданных заявок]
		 , [Среднее время заявки в ожидании очереди на этапе ВК] =  cast(
			  format(w.duration/60/60 ,'00')+N':'+format( (w.duration/60 -  60* (w.duration/60/60)),'00') +N':'+format((w.duration - 60 * (duration/60)),'00')
		  as nvarchar(50)) 
		 , [Общее кол-во заведенных заявок Call2]                                        = cast(format(call2.Qty,'0') as nvarchar(50))
			   , [Кол-во автоматических отказов Call2]                                         = cast(format(call2.Qty_rejected,'0') as nvarchar(50))
			   , [%  автоматических отказов Call2]                                             = cast(format(case when call2.Qty<>0 then 100.0*call2.Qty_rejected/call2.Qty else 0 end,'0.0')+N'%' as nvarchar(50))

		, [TTY - количество заявок рассмотренных в течение 9 минут на этапе ВК] = cast(format(tty9.cnt,'0') as nvarchar(50))
		, [TTY - % заявок рассмотренных в течение 9 минут на этапе ВК]  = cast(format(case when [Общее кол-во заявок на этапе ВК]<>0 then 100.0*tty9.cnt/ [Общее кол-во заявок на этапе ВК] else 0 end,'0')+N'%' as nvarchar(50))
	  
		, [TTY - количество заявок рассмотренных в течение 8 минут на этапе ВК] = cast(format(tty8.cnt,'0') as nvarchar(50))
		, [TTY - % заявок рассмотренных в течение 8 минут на этапе ВК]  = cast(format(case when [Общее кол-во заявок на этапе ВК]<>0 then 100.0*tty8.cnt/ [Общее кол-во заявок на этапе ВК] else 0 end,'0')+N'%' as nvarchar(50))

		, [TTY - количество заявок рассмотренных в течение 6 минут на этапе ВК] = cast(format(tty6.cnt,'0') as nvarchar(50))
		, [TTY - % заявок рассмотренных в течение 6 минут на этапе ВК]  = cast(format(case when [Общее кол-во заявок на этапе ВК]<>0 then 100.0*tty6.cnt/ [Общее кол-во заявок на этапе ВК] else 0 end,'0')+N'%' as nvarchar(50))
		--
		, [TTY - количество заявок рассмотренных в течение 11 минут на этапах КД+ВК] = cast(format(tty_kd_vk11.cnt,'0') as nvarchar(50))
		, [TTY - % заявок рассмотренных в течение 11 минут на этапах КД+ВК]  = cast(format(case when tty_kd_vk_cnt.cnt<>0 then 100.0*tty_kd_vk11.cnt/ tty_kd_vk_cnt.cnt else 0 end,'0')+N'%' as nvarchar(50))

		, [TTY - количество заявок рассмотренных в течение 10 минут на этапах КД+ВК] = cast(format(tty_kd_vk10.cnt,'0') as nvarchar(50))
		, [TTY - % заявок рассмотренных в течение 10 минут на этапах КД+ВК]  = cast(format(case when tty_kd_vk_cnt.cnt<>0 then 100.0*tty_kd_vk10.cnt/ tty_kd_vk_cnt.cnt else 0 end,'0')+N'%' as nvarchar(50))

		, [TTY - количество заявок рассмотренных в течение 8 минут на этапах КД+ВК] = cast(format(tty_kd_vk8.cnt,'0') as nvarchar(50))
		, [TTY - % заявок рассмотренных в течение 8 минут на этапах КД+ВК]  = cast(format(case when tty_kd_vk_cnt.cnt<>0 then 100.0*tty_kd_vk8.cnt/ tty_kd_vk_cnt.cnt else 0 end,'0')+N'%' as nvarchar(50))

			   , [Уникальное кол-во отложенных заявок на этапе ВК]                       = cast(format((u.ОтложенаУникальныеVK),'0') as nvarchar(50))

			--, [Take up % выданных заявок от одобренных на Call3] = case when isnull(d.[VTS],0)<>0 then cast(format(isnull(uniqie_vk_month.[Заем выдан]*1.0, 0) / d.[VTS] * 100,'0')+N'%' as nvarchar(50)) else '0%' END
			, [Take up % выданных заявок от одобренных на Call3] = case when isnull(uniqie_vk_month.[VTS],0)<>0 then cast(format(isnull(uniqie_vk_month.[Заем выдан]*1.0, 0) / uniqie_vk_month.[VTS] * 100,'0')+N'%' as nvarchar(50)) else '0%' END
    
			,[Кол-во уникальных заявок в статусе Договор подписан] = cast(format(isnull(ДоговорПодписан.cnt, 0),'0') as nvarchar(50))
		into #p_VK_m
		from (
		  select 
				ProductType_Code
				, Дата=cast(format(Дата,'yyyyMM01') as date)
      
			   --, [Общее кол-во заявок на этапе Вериф.клиента]                                  = cast(format(sum(КоличествоЗаявок),'0') as nvarchar(50))
			   , [Общее кол-во заявок на этапе ВК] = cast(format(sum(КоличествоЗаявок),'0') as nvarchar(50))
      
			   --, [TTY  - % заявок рассмотренных в течение 3-х минут на этапе Вериф.ТС]                  = cast('' as nvarchar(50))
      
			   , [Средний Processing time на этапе (время обработки заявки) ВК]     = case when sum(КоличествоЗаявок)<>0 then cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
																								  else '0' end
			   --, [Кол-во одобренных заявок после этапа Вериф.клиента]                          = cast(format(sum([VTS]),'0')as nvarchar(50))
			   , [Кол-во одобренных заявок после этапа ВК] = cast(format(sum([VTS]),'0')as nvarchar(50))

			   , [VTS] = sum([VTS])

			   --, [Кол-во отказов со стороны сотрудников Вериф.клиента]                         = cast(format(sum([Отказано]),'0')as nvarchar(50)) 
			   , [Кол-во отказов со стороны сотрудников ВК] = cast(format(sum([Отказано]),'0')as nvarchar(50)) 

			   --, [Approval rate - % одобренных после этапа Вериф.клиента] = case when sum(  ИтогоПоСотруднику)<>0 then cast(format(isnull(case when sum(ИтогоПоСотруднику) <>0 then sum(VTS*1.0)/ sum(  ИтогоПоСотруднику) else 0 end ,0)  *100,'0')+N'%' as nvarchar(50)) else '0' END
			   , [Approval rate - % одобренных после этапа ВК] = case when sum(ИтогоПоСотруднику)<>0 then cast(format(isnull(case when sum(ИтогоПоСотруднику) <>0 then sum(VTS*1.0)/ sum(  ИтогоПоСотруднику) else 0 end ,0)  *100,'0')+N'%' as nvarchar(50)) else '0' END
       
			   --, [Approval rate % Логином]                                                     = cast('' as nvarchar(50))
			   --, [Общее кол-во отложенных заявок на этапе Вериф.клиента]                       = cast(format(sum(Отложена),'0') as nvarchar(50))
			   , [Общее кол-во отложенных заявок на этапе ВК] = cast(format(sum(Отложена),'0') as nvarchar(50))

			   --, [Кол-во заявок на этапе, отправленных на доработку Вериф.клиента]             = cast(format(sum(Доработка),'0') as nvarchar(50))
			   , [Кол-во заявок на этапе, отправленных на доработку ВК] = cast(format(sum(Доработка),'0') as nvarchar(50))

			   --, [Take rate Уровень выдачи, выраженный через одобрения]                        = cast('' as nvarchar(50))
			   --, [Кол-во заявок в статусе "Займ выдан",шт.]                                    = cast('' as nvarchar(50))

			   --, [Take up % выданных заявок от одобренных на Call3] = case when sum([VTS])<>0 then cast(format(isnull(case when sum([VTS]) <>0 then sum([Заем выдан]*1.0)/ sum([VTS]) else 0 end ,0)  *100,'0')+N'%' as nvarchar(50)) else '0' END
    
			from #ReportByEmployeeAgg_VK
			WHERE Сотрудник in (select * from #curr_employee_vr)
		   group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
		) AS d
		left join
		(
		select 
				ProductType_Code
				, Дата=cast(format(Дата,'yyyyMM01') as date)
				--,[Общее кол-во уникальных заявок на этапе Вериф.клиента]                       = cast(format(sum(Новая),'0')as nvarchar(50))  
				,[Общее кол-во уникальных заявок на этапе ВК] = cast(format(sum(Новая_Уникальная),'0') AS nvarchar(50))

				 --DWH-2286
				 , [Первичный] = cast(format(sum([Новая_Уникальная Первичный]),'0')as nvarchar(50))
				 , [Повторный] = cast(format(sum([Новая_Уникальная Повторный]),'0')as nvarchar(50))
				 , [Докредитование] = cast(format(sum([Новая_Уникальная Докредитование]),'0')as nvarchar(50))
				 , [Не определен] = cast(format(sum([Новая_Уникальная Не определен]),'0')as nvarchar(50))

				,[Take up Количество выданных заявок] = cast(format(sum([Заем выдан]),'0') as nvarchar(50))
				,[Заем выдан] = sum([Заем выдан])
				,[VTS] = sum([VTS])
			from #ReportByEmployeeAgg_VK 
			group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
		) uniqie_vk_month on uniqie_vk_month.ProductType_Code = d.ProductType_Code AND uniqie_vk_month.Дата = d.Дата
		left join #waitTime_v_m AS w on w.ProductType_Code = d.ProductType_Code AND w.[Дата статуса]=d.Дата
		left join #postpone_unique_vk AS u on u.ProductType_Code = d.ProductType_Code AND u.[Дата статуса] = d.Дата
		left join #call2_m call2 on call2.ProductType_Code = d.ProductType_Code AND call2.[Дата статуса]=d.Дата
		left join (
			SELECT
				ProductType_Code
				, дата=cast(format(Дата,'yyyyMM01') as date)
				, count([Номер заявки]) cnt
			  from #tty_vk_m
			where tty9_flag='tty'
			group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
		) tty9 on tty9.ProductType_Code = d.ProductType_Code AND tty9.Дата=d.Дата
		left join (
			SELECT
				ProductType_Code
				, дата=cast(format(Дата,'yyyyMM01') as date)
				, count([Номер заявки]) cnt
			  from #tty_vk_m
			where tty8_flag='tty'
			group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
		) tty8 on tty8.ProductType_Code = d.ProductType_Code AND tty8.Дата=d.Дата
		left join (
			SELECT
				ProductType_Code
				, дата=cast(format(Дата,'yyyyMM01') as date)
				, count([Номер заявки]) cnt
			  from #tty_vk_m
			where tty6_flag='tty'
			group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
		) tty6 on tty6.ProductType_Code = d.ProductType_Code AND tty6.Дата=d.Дата
		--
		left join (
			SELECT
				ProductType_Code
				, дата=cast(format(Дата,'yyyyMM01') as date)
				, count([Номер заявки]) cnt
			  from #tty_kd_vk_m
			where tty11_flag='tty'
			group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
		) tty_kd_vk11 on tty_kd_vk11.ProductType_Code = d.ProductType_Code AND tty_kd_vk11.Дата=d.Дата
		left join (
			SELECT
				ProductType_Code
				, дата=cast(format(Дата,'yyyyMM01') as date)
				, count([Номер заявки]) cnt
			  from #tty_kd_vk_m
			where tty10_flag='tty'
			group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
		) tty_kd_vk10 on tty_kd_vk10.ProductType_Code = d.ProductType_Code AND tty_kd_vk10.Дата=d.Дата
		left join (
			SELECT
				ProductType_Code
				, дата=cast(format(Дата,'yyyyMM01') as date)
				, count([Номер заявки]) cnt
			  from #tty_kd_vk_m
			where tty8_flag='tty'
			group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
		) tty_kd_vk8 on tty_kd_vk8.ProductType_Code = d.ProductType_Code AND tty_kd_vk8.Дата=d.Дата
		left join (
			SELECT
				ProductType_Code
				, дата=cast(format(Дата,'yyyyMM01') as date)
				, count([Номер заявки]) cnt
			from #tty_kd_vk_m
			group by ProductType_Code, cast(format(Дата,'yyyyMM01') as date)
		) tty_kd_vk_cnt on tty_kd_vk_cnt.ProductType_Code = d.ProductType_Code AND tty_kd_vk_cnt.Дата=d.Дата

		--DWH-2309
		LEFT JOIN (
			SELECT 
				D.ProductType_Code,
				ДатаСтатуса = cast(format(D.[Дата статуса],'yyyyMM01') as date),
				cnt = count(DISTINCT D.[Номер заявки])
			from #t_dm_FedorVerificationRequests_without_coll_ALL AS D
			WHERE 1=1
				AND D.[Дата статуса] > @dt_from AND  D.[Дата статуса] < @dt_to
				AND D.Статус IN ('Договор подписан')
			GROUP BY D.ProductType_Code,cast(format(D.[Дата статуса],'yyyyMM01') as date)
		) AS ДоговорПодписан
		ON ДоговорПодписан.ProductType_Code = d.ProductType_Code AND ДоговорПодписан.ДатаСтатуса = d.Дата


		IF @Page IN ('V.Monthly.Common') OR @isFill_All_Tables = 1
		BEGIN
			DROP table if exists #unp_VK_TS_Daily_m

			SELECT ProductType_Code, Дата, indicator, Qty 
			into #unp_VK_TS_Daily_m
			from 
			(
			SELECT
				v.ProductType_Code
				, v.Дата
				 , v.[Общее кол-во заведенных заявок Call2]
				 , v.[Кол-во автоматических отказов Call2]
				 , v.[%  автоматических отказов Call2]

				 , v.[Общее кол-во уникальных заявок на этапе ВК]

				, v.[Первичный]
				, v.[Повторный]
				, v.[Докредитование]
				, v.[Не определен]

				 , v.[Общее кол-во заявок на этапе ВК]

				 , v.[TTY - количество заявок рассмотренных в течение 9 минут на этапе ВК]
				 , v.[TTY - % заявок рассмотренных в течение 9 минут на этапе ВК]

				 , v.[TTY - количество заявок рассмотренных в течение 8 минут на этапе ВК]
				 , v.[TTY - % заявок рассмотренных в течение 8 минут на этапе ВК]

				 , v.[TTY - количество заявок рассмотренных в течение 6 минут на этапе ВК]
				 , v.[TTY - % заявок рассмотренных в течение 6 минут на этапе ВК]

				--, v.[TTY - количество заявок рассмотренных в течение 11 минут на этапах КД+ВК]
				--, v.[TTY - % заявок рассмотренных в течение 11 минут на этапах КД+ВК]

				--, v.[TTY - количество заявок рассмотренных в течение 10 минут на этапах КД+ВК]
				--, v.[TTY - % заявок рассмотренных в течение 10 минут на этапах КД+ВК]

				--, v.[TTY - количество заявок рассмотренных в течение 8 минут на этапах КД+ВК]
				--, v.[TTY - % заявок рассмотренных в течение 8 минут на этапах КД+ВК]

				 , v.[Среднее время заявки в ожидании очереди на этапе ВК]
				 , v.[Средний Processing time на этапе (время обработки заявки) ВК]

				 , v.[Кол-во одобренных заявок после этапа ВК]

				 , v.[Кол-во отказов со стороны сотрудников ВК]

				 , v.[Approval rate - % одобренных после этапа ВК]

				 --, v.[Approval rate % Логином]
				 --, v.[Контактность общая]
				 --, v.[Контактность по одобренным]
				 --, v.[Контактность по отказным]

				 , v.[Общее кол-во отложенных заявок на этапе ВК]
				 , v.[Уникальное кол-во отложенных заявок на этапе ВК]

				 , v.[Кол-во заявок на этапе, отправленных на доработку ВК]

				 --, v.[Take rate Уровень выдачи, выраженный через одобрения]
				 --, v.[Кол-во заявок в статусе "Займ выдан",шт.]
				 , v.[Take up Количество выданных заявок]

				 , v.[Take up % выданных заявок от одобренных на Call3]

				 , v.[Кол-во уникальных заявок в статусе Договор подписан]
         
				 --, t.[Общее кол-во уникальных заявок на этапе Вериф.ТС]
				 --, t.[Общее кол-во заявок на этапе Вериф.ТС]
				 --, t.[TTY  - % заявок рассмотренных в течение 3-х минут на этапе Вериф.ТС]
				 --, t.[Среднее время заявки в ожидании очереди на этапе Вериф.ТС]
				 --, t.[Средний Processing time на этапе (время обработки заявки) Вериф.ТС]
				 --, t.[Кол-во одобренных заявок после этапа Вериф.ТС]
				 --, t.[Кол-во отказов со стороны сотрудников Вериф.ТС]
				 --, t.[Approval rate - % одобренных после этапа Вериф.ТС]
				 --, t.[Общее кол-во отложенных заявок на этапе Вериф.ТС]
				 --, t.[Уникальное кол-во отложенных заявок на этапе Вериф.ТС]
				 --, t.[Кол-во заявок на этапе, отправленных на доработку Вериф.ТС]

			  from #p_VK_m AS v 
				--LEFT  join #p_TS_m  t on t.Дата=v.Дата

			) p
			UNPIVOT
			(Qty for indicator in (
				   [Общее кол-во заведенных заявок Call2]                          
				 , [Кол-во автоматических отказов Call2]                           
				 , [%  автоматических отказов Call2]                               

				 , [Общее кол-во уникальных заявок на этапе ВК]
				, [Первичный]
				, [Повторный]
				, [Докредитование]
				, [Не определен]

				 , [Общее кол-во заявок на этапе ВК]

				 , [TTY - количество заявок рассмотренных в течение 9 минут на этапе ВК]
				 , [TTY - % заявок рассмотренных в течение 9 минут на этапе ВК]

				 , [TTY - количество заявок рассмотренных в течение 8 минут на этапе ВК]
				 , [TTY - % заявок рассмотренных в течение 8 минут на этапе ВК]

				 , [TTY - количество заявок рассмотренных в течение 6 минут на этапе ВК]
				 , [TTY - % заявок рассмотренных в течение 6 минут на этапе ВК]

				--, [TTY - количество заявок рассмотренных в течение 11 минут на этапах КД+ВК]
				--, [TTY - % заявок рассмотренных в течение 11 минут на этапах КД+ВК]

				--, [TTY - количество заявок рассмотренных в течение 10 минут на этапах КД+ВК]
				--, [TTY - % заявок рассмотренных в течение 10 минут на этапах КД+ВК]

				--, [TTY - количество заявок рассмотренных в течение 8 минут на этапах КД+ВК]
				--, [TTY - % заявок рассмотренных в течение 8 минут на этапах КД+ВК]

				 , [Среднее время заявки в ожидании очереди на этапе ВК]
				 , [Средний Processing time на этапе (время обработки заявки) ВК]

				 , [Кол-во одобренных заявок после этапа ВК]

				 , [Кол-во отказов со стороны сотрудников ВК]

				 , [Approval rate - % одобренных после этапа ВК]

				 --, [Контактность общая]
				 --, [Контактность по одобренным]
				 --, [Контактность по отказным]

				 , [Общее кол-во отложенных заявок на этапе ВК]
				 , [Уникальное кол-во отложенных заявок на этапе ВК]

				 , [Кол-во заявок на этапе, отправленных на доработку ВК]

				 , [Take up Количество выданных заявок]

				 , [Take up % выданных заявок от одобренных на Call3]

				 , [Кол-во уникальных заявок в статусе Договор подписан]

				 --, [Общее кол-во уникальных заявок на этапе Вериф.ТС]   
				 --, [Уникальное кол-во отложенных заявок на этапе Вериф.ТС]
				 --, [Общее кол-во заявок на этапе Вериф.ТС]
				 --, [TTY  - % заявок рассмотренных в течение 3-х минут на этапе Вериф.ТС]     
				 --, [Среднее время заявки в ожидании очереди на этапе Вериф.ТС]               
				 --, [Средний Processing time на этапе (время обработки заявки) Вериф.ТС]      
				 --, [Кол-во одобренных заявок после этапа Вериф.ТС]                           
				 --, [Кол-во отказов со стороны сотрудников Вериф.ТС]                          
				 --, [Approval rate - % одобренных после этапа Вериф.ТС]                 
				 --, [Общее кол-во отложенных заявок на этапе Вериф.ТС]                        
				 --, [Кол-во заявок на этапе, отправленных на доработку Вериф.ТС]  
         
								)
		   ) as unpvt

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##unp_VK_TS_Daily_m
				SELECT * INTO ##unp_VK_TS_Daily_m FROM #unp_VK_TS_Daily_m
			END

			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_V_Monthly_Common
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_V_Monthly_Common AS T
				WHERE T.ProcessGUID = @ProcessGUID

				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_V_Monthly_Common
				SELECT
					ProcessGUID = @ProcessGUID,
					--i.num_rows 
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					, empl_id =null
					  , Employee =null
					, acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					, [Сумма] =null
					  , Qty
					  , Qty_dist=null
					  , Tm_Qty =null--isnull(Tm_Qty,0.00)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_V_Monthly_Common
				from #unp_VK_TS_Daily_m u 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
					join #indicator_for_vc_va i
						ON u.indicator = i.name_indicator
						--запрещенные "комбинации" типа продукта и индикатора
						AND NOT (
							   (i.num_rows IN (7.01, 7.02) AND PT.ProductType_Code IN ('installment', 'pdl'))
							OR (i.num_rows IN (9.01, 9.02) AND PT.ProductType_Code IN ('ALL', 'pdl'))
							OR (i.num_rows IN (11.01, 11.02) AND PT.ProductType_Code IN ('ALL', 'installment'))
						)
				--ORDER BY i.num_rows

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'V.Monthly.Common', @ProcessGUID
			END
			ELSE BEGIN
				SELECT
					--i.num_rows 
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					, empl_id =null
					  , Employee =null
					, acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					, [Сумма] =null
					  , Qty
					  , Qty_dist=null
					  , Tm_Qty =null--isnull(Tm_Qty,0.00)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_V_Monthly_Common
				from #unp_VK_TS_Daily_m u 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
					join #indicator_for_vc_va i
						ON u.indicator = i.name_indicator
						--запрещенные "комбинации" типа продукта и индикатора
						AND NOT (
							   (i.num_rows IN (7.01, 7.02) AND PT.ProductType_Code IN ('installment', 'pdl'))
							OR (i.num_rows IN (9.01, 9.02) AND PT.ProductType_Code IN ('ALL', 'pdl'))
							OR (i.num_rows IN (11.01, 11.02) AND PT.ProductType_Code IN ('ALL', 'installment'))
						)
				--ORDER BY i.num_rows

				RETURN 0
			END
		END
		--// 'V.Monthly.Common'


		IF @Page IN ('V.Monthly.TTY') OR @isFill_All_Tables = 1
		BEGIN
			DROP table if exists #unp_KD_VK_TTY_m

			SELECT ProductType_Code, Дата, indicator, Qty 
			into #unp_KD_VK_TTY_m
			from 
			(
			SELECT
				v.ProductType_Code
				, v.Дата
				, v.[TTY - количество заявок рассмотренных в течение 11 минут на этапах КД+ВК]
				, v.[TTY - % заявок рассмотренных в течение 11 минут на этапах КД+ВК]

				, v.[TTY - количество заявок рассмотренных в течение 10 минут на этапах КД+ВК]
				, v.[TTY - % заявок рассмотренных в течение 10 минут на этапах КД+ВК]

				, v.[TTY - количество заявок рассмотренных в течение 8 минут на этапах КД+ВК]
				, v.[TTY - % заявок рассмотренных в течение 8 минут на этапах КД+ВК]
			  from #p_VK_m AS v 
			) p
			UNPIVOT
			(Qty for indicator in (
				[TTY - количество заявок рассмотренных в течение 11 минут на этапах КД+ВК]
				, [TTY - % заявок рассмотренных в течение 11 минут на этапах КД+ВК]

				, [TTY - количество заявок рассмотренных в течение 10 минут на этапах КД+ВК]
				, [TTY - % заявок рассмотренных в течение 10 минут на этапах КД+ВК]

				, [TTY - количество заявок рассмотренных в течение 8 минут на этапах КД+ВК]
				, [TTY - % заявок рассмотренных в течение 8 минут на этапах КД+ВК]
				)
		   ) as unpvt

			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##unp_KD_VK_TTY_m
				SELECT * INTO ##unp_KD_VK_TTY_m FROM #unp_KD_VK_TTY_m
			END

			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedorUAT_without_coll_V_Monthly_Common
				DELETE T
				FROM tmp.TMP_Report_verification_fedorUAT_without_coll_V_Monthly_TTY AS T
				WHERE T.ProcessGUID = @ProcessGUID

				INSERT tmp.TMP_Report_verification_fedorUAT_without_coll_V_Monthly_TTY
				SELECT
					ProcessGUID = @ProcessGUID,
					--i.num_rows 
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					, empl_id =null
					  , Employee =null
					, acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					, [Сумма] =null
					  , Qty
					  , Qty_dist=null
					  , Tm_Qty =null--isnull(Tm_Qty,0.00)
				--INTO tmp.TMP_Report_verification_fedorUAT_without_coll_V_Monthly_TTY
				from #unp_KD_VK_TTY_m u 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
					join #indicator_for_vc_va i
						ON u.indicator = i.name_indicator
						--запрещенные "комбинации" типа продукта и индикатора
						AND NOT (
							   (i.num_rows IN (41.01, 41.02) AND PT.ProductType_Code IN ('installment', 'pdl'))
							OR (i.num_rows IN (43.01, 43.02) AND PT.ProductType_Code IN ('ALL', 'pdl'))
							OR (i.num_rows IN (45.01, 45.02) AND PT.ProductType_Code IN ('ALL', 'installment'))
						)
				--ORDER BY i.num_rows

				INSERT LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'V.Monthly.TTY', @ProcessGUID
			END
			ELSE BEGIN
				SELECT
					--i.num_rows 
					num_rows = i.num_rows + 0.1 * PT.ProductType_Order
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					, empl_id =null
					  , Employee =null
					, acc_period =Дата
					--,indicator =name_indicator
					,indicator = concat(PT.ProductType_Name, ' ', i.name_indicator)
					, [Сумма] =null
					  , Qty
					  , Qty_dist=null
					  , Tm_Qty =null--isnull(Tm_Qty,0.00)
				from #unp_KD_VK_TTY_m u 
					INNER JOIN #t_ProductType AS PT
						ON PT.ProductType_Code = u.ProductType_Code
					join #indicator_for_vc_va i
						ON u.indicator = i.name_indicator
						--запрещенные "комбинации" типа продукта и индикатора
						AND NOT (
							   (i.num_rows IN (41.01, 41.02) AND PT.ProductType_Code IN ('installment', 'pdl'))
							OR (i.num_rows IN (43.01, 43.02) AND PT.ProductType_Code IN ('ALL', 'pdl'))
							OR (i.num_rows IN (45.01, 45.02) AND PT.ProductType_Code IN ('ALL', 'installment'))
						)
				--ORDER BY i.num_rows

				RETURN 0
			END
		END
		--//'V.Monthly.TTY'


END
--// 'V.Monthly.Common', 'V.Monthly.TTY'


END -- общий лист по  дням
--// Общий отчет


IF @Page = 'Fill_All_Tables' BEGIN
	SELECT @eventType = concat(@Page, ' FINISH')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Report_verification_fedorUAT_without_coll',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID

	--BEGIN TRAN

	UPDATE F
	SET EndDateTime = getdate()
	FROM LogDb.dbo.Fill_Report_verification_fedorUAT_without_coll AS F
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
		'EXEC dbo.Report_verification_fedorUAT_without_coll ',
		'@Page=''', @Page, ''', ',
		'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@isDebug=', convert(varchar(10), @isDebug)
	)

	SELECT @eventType = concat(@Page, ' ERROR')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Report_verification_fedorUAT_without_coll',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END
