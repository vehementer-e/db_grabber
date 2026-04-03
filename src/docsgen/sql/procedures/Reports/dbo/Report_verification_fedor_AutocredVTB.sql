--select  newid()
/*
exec Reports.dbo.Report_verification_fedor_AutocredVTB @Page = 'KD.Daily.Common' , @ProcessGUID = '3567EEDA-9021-4BFE-93C9-C1E512F338EC', @isDebug = 1
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Daily.PostponeUnique'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Monthly.PostponeUnique'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Daily.PostponeUnique'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Monthly.PostponeUnique'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Daily.PostponeUnique'

--exec Reports.dbo.Report_verification_fedor_AutocredVTB 'ReportByEmployee'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'ReportByEmployeeAgg'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'ReportByEmployeeAgg_LastHour'

--exec Reports.dbo.Report_verification_fedor_AutocredVTB 'ReportByEmployee_VK'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'ReportByEmployeeAgg_VK'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'ReportByEmployeeAgg_VK_LastHour'

exec Reports.dbo.Report_verification_fedor_AutocredVTB 'ReportByEmployee_TS'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'ReportByEmployeeAgg_TS'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'ReportByEmployeeAgg_TS_LastHour'

exec Reports.dbo.Report_verification_fedor_AutocredVTB 'Detail'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'Contact.Detail'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'Contact.DetailByEmployee'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Detail'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Detail'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VTC.Detail'

exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Daily.Total'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Daily.Unic'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Daily.AvgTime'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Daily.Approved'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Daily.Postpone'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Daily.Rework'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Daily.AR'

exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Daily.Total'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Daily.Unic'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Daily.AvgTime'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Daily.Approved' 
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Daily.Postpone'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Daily.Rework'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Daily.AR'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Daily.Contact'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Daily.Contact.Approved'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Daily.Contact.Denied'

exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Daily.Total'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Daily.Unic'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Daily.AvgTime'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Daily.Approved' 
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Daily.Postpone'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Daily.Rework'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Daily.AR'

exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Monthly.Total'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Monthly.Unic'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Monthly.AvgTime'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Monthly.Approved'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Monthly.Postpone'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Monthly.Rework'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Monthly.AR'

exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Monthly.Total'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Monthly.Unic'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Monthly.AvgTime'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Monthly.Approved'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Monthly.AR'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Monthly.Contact'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Monthly.Contact.Approved'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Monthly.Contact.Denied'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Monthly.Postpone'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.Monthly.Rework'



exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Monthly.Total'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Monthly.Unic'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Monthly.AvgTime'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Monthly.Approved' 
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Monthly.AR'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Monthly.Postpone'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Monthly.PostponeUnique'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.Monthly.Rework'


exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Daily.Common'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'V.Daily.Common' 

exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Monthly.Common', '2021-03-01', '2021-03-29'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'V.Monthly.Common'


exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Daily.Common', '2021-03-28', '2021-03-29'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Daily.Total'

exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Daily.Approved'

exec Reports.dbo.Report_verification_fedor_AutocredVTB 'DetailHours'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.DetailHours'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.DetailHours'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VTC.DetailHours'

exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.HoursGroupMonth'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.HoursGroupMonthUnique'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.HoursGroupDays'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.HoursGroupDaysUnique'

exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.HoursGroupMonth'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.HoursGroupMonthUnique'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.HoursGroupDays'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'VK.HoursGroupDaysUnique'

exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.HoursGroupMonth'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.HoursGroupMonthUnique'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'TS.HoursGroupDays'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'Clear_All_Tables'


*/

CREATE PROC dbo.Report_verification_fedor_AutocredVTB
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
			FROM LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB AS F
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

				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
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
			FROM LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB AS F
			WHERE F.ReportPage = @Page
				AND F.ProcessGUID = @ProcessGUID
			)
		BEGIN
			--таблица для @Page НЕ заполнена
			--вызвать заполнение всех таблиц и ждать

			SELECT @delay = '00:00:00.' + convert(varchar(3), round(1000 * rand(), 0))
			WAITFOR DELAY @delay


		    EXEC dbo.Report_verification_fedor_AutocredVTB
				@Page = 'Fill_All_Tables', 
				@dtFrom = @dtFrom,
				@dtTo = @dtTo,
				@ProcessGUID = @ProcessGUID


			SELECT @EventDateTime = getdate()

			WHILE 
				-- НЕ появились данные для @Page
				NOT EXISTS(
					SELECT TOP 1 1
					FROM LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB AS F
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
		'EXEC dbo.Report_verification_fedor_AutocredVTB ',
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
		@eventName = 'Report_verification_fedor_AutocredVTB',
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
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	
	IF @Page = 'KD.Daily.Common' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'V.Monthly.Common' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_V_Monthly_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'Detail' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID
		ORDER BY T.[ФИО сотрудника верификации/чекер], T.[Дата статуса] desc, T.[Номер заявки] desc
	END

	IF @Page = 'Contact.Detail' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID
		ORDER BY T.[ФИО сотрудника верификации/чекер], T.[Дата статуса] desc, T.[Номер заявки] desc
	END

	IF @Page = 'Contact.DetailByEmployee' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_DetailByEmployee AS T
		WHERE T.ProcessGUID = @ProcessGUID
		ORDER BY T.[Номер заявки] DESC, T.ПорядковыйНомерЗвонка
	END

	IF @Page = 'KD.Monthly.Total' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Monthly.AvgTime' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Monthly.Approved' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Monthly.AR' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Monthly.Postpone' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Monthly.Rework' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Daily.Total' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Daily.AvgTime' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Daily.Approved' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Daily.AR' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Daily.Postpone' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Daily.Rework' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'KD.Detail' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID
		ORDER BY T.[ФИО сотрудника верификации/чекер] asc, T.[Дата заведения заявки] desc, T.[Время заведения] desc
	END

	IF @Page = 'VK.Detail' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID
		--ORDER BY T.[ФИО сотрудника верификации/чекер], T.[Дата статуса] DESC, T.[Номер заявки] DESC
		ORDER BY T.[Номер заявки] DESC, T.[Дата статуса] DESC
	END
	IF @Page = 'KD.Daily.Unic' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Daily.PostponeUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.Monthly.PostponeUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'DetailHours' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_DetailHours AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END

	IF @Page = 'KD.DetailHours' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_DetailHours AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.DetailHours' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_DetailHours AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VTC.DetailHours' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VTC_DetailHours AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END



	IF @Page = 'VK.Monthly.Total' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.AvgTime' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.Approved' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.AR' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.Contact' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.Contact.Approved' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.Contact.Denied' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact_Denied AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.Postpone' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.Rework' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.Total' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.AvgTime' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.Approved' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.AR' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.Contact' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Contact AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.Contact.Approved' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Contact_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.Contact.Denied' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Contact_Denied AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.Postpone' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.Rework' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.Unic' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.Unic' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Daily.PostponeUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.Monthly.PostponeUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.HoursGroupMonth' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupMonth AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.HoursGroupMonthUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupMonthUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.HoursGroupDaysUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupDaysUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VK.HoursGroupDays' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupDays AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END



	IF @Page = 'V.Daily.Common' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_V_Daily_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Monthly.Total' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Monthly.AvgTime' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Monthly.Approved' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Monthly.AR' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Monthly.Postpone' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Monthly.Rework' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Daily.Total' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Daily.AvgTime' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Daily.Approved' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Daily.AR' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Daily.Postpone' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Daily.Rework' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'VTC.Detail' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VTC_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID
		ORDER BY T.[Номер заявки] DESC, T.[Дата статуса] DESC
	END
	IF @Page = 'KD.Monthly.Unic' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Monthly.Unic' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Daily.Unic' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'ReportByEmployee' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_ReportByEmployee AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Daily.PostponeUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.Monthly.PostponeUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.HoursGroupDays' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupDays AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.HoursGroupMonth' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupMonth AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.HoursGroupDaysUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupDaysUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'KD.HoursGroupMonthUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupMonthUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.HoursGroupMonthUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupMonthUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.HoursGroupMonth' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupMonth AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.HoursGroupDaysUnique' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupDaysUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END
	IF @Page = 'TS.HoursGroupDays' BEGIN
		SELECT T.*
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupDays AS T
		WHERE T.ProcessGUID = @ProcessGUID
	END


	IF @Page NOT IN ('Fill_All_Tables', 'Clear_All_Tables')
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1
			FROM LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB AS F
			WHERE F.ReportPage = @Page
				AND F.ProcessGUID = @ProcessGUID
			)
		BEGIN
			--таблица для @Page заполнена
			--почистить Fill
			--BEGIN TRAN

			DELETE F
			FROM LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB AS F 
			WHERE F.ReportPage = @Page AND F.ProcessGUID = @ProcessGUID

			-- если это последний вызов (нет больше записей, кроме 'Fill_All_Tables'),
			-- удалить запись 'Fill_All_Tables'
			IF NOT EXISTS(
				SELECT TOP 1 1
				FROM LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB AS F
				WHERE F.ReportPage <> 'Fill_All_Tables'
					AND F.ProcessGUID = @ProcessGUID
			)
			AND EXISTS(
				SELECT TOP 1 1
				FROM LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB AS F
				WHERE F.ReportPage = 'Fill_All_Tables'
					AND F.ProcessGUID = @ProcessGUID
					AND F.EndDateTime IS NOT NULL
			)
			--EndDateTime
			BEGIN
				DELETE F
				FROM LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB AS F 
				WHERE F.ReportPage = 'Fill_All_Tables' AND F.ProcessGUID = @ProcessGUID

				--очистить все таблицы
				EXEC dbo.Report_verification_fedor_AutocredVTB
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
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_V_Monthly_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID


		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_DetailByEmployee AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact_Denied AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Contact AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Contact_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Contact_Denied AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_DetailHours AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_DetailHours AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_DetailHours AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VTC_DetailHours AS T
		WHERE T.ProcessGUID = @ProcessGUID
		--

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupMonth AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupMonthUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupDaysUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupDays AS T
		WHERE T.ProcessGUID = @ProcessGUID




		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_V_Daily_Common AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Total AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_AvgTime AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Approved AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_AR AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Postpone AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Rework AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VTC_Detail AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Unic AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_ReportByEmployee AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_PostponeUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupDays AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupMonth AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupDaysUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupMonthUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupMonthUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupMonth AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupDaysUnique AS T
		WHERE T.ProcessGUID = @ProcessGUID

		DELETE T
		FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupDays AS T
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
	'Detail',
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
	'DetailHours',
	'KD.DetailHours',
	'VK.DetailHours',
	'VTC.DetailHours',
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
	'TS.Monthly.Total',
	'TS.Monthly.AvgTime',
	'TS.Monthly.Approved',
	'TS.Monthly.AR',
	'TS.Monthly.Postpone',
	'TS.Monthly.Rework',
	'TS.Daily.Total',
	'TS.Daily.AvgTime',
	'TS.Daily.Approved',
	'TS.Daily.AR',
	'TS.Daily.Postpone',
	'TS.Daily.Rework',
	'VTC.Detail',
	'KD.Monthly.Unic',
	'TS.Monthly.Unic',
	'TS.Daily.Unic',
	'ReportByEmployee',
	'TS.Daily.PostponeUnique',
	'TS.Monthly.PostponeUnique',
	'KD.HoursGroupDays',
	'KD.HoursGroupMonth',
	'KD.HoursGroupDaysUnique',
	'KD.HoursGroupMonthUnique',
	'TS.HoursGroupMonthUnique',
	'TS.HoursGroupMonth',
	'TS.HoursGroupDaysUnique',
	'TS.HoursGroupDays'
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

	drop table if exists #t_IdClientRequest
	select distinct
		IdClientRequest = CR.Id,
		[Номер заявки] = R.[Номер заявки] COLLATE Cyrillic_General_CI_AS
	INTO #t_IdClientRequest
	FROM Reports.dbo.dm_FedorVerificationRequests AS R (NOLOCK)
		INNER JOIN Stg._fedor.core_ClientRequest AS CR
			ON CR.Number COLLATE Cyrillic_General_CI_AS = R.[Номер заявки]
	WHERE 1=1
		AND R.[Дата статуса] > @dt_from
		AND R.[Дата статуса] < @dt_to

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
				WHEN 'Звонок работодателю по телефонам из Контур Фокус' THEN 1
				WHEN 'Звонок работодателю по телефонам из Интернет' THEN 2
				WHEN 'Звонок работодателю по телефону из Анкеты' THEN 3
				WHEN 'Звонок контактному лицу' THEN 4
				ELSE 99
			END,
		call_type_name = CheckListItemType.Name COLLATE Cyrillic_General_CI_AS,
		result_name = CheckListItemStatus.Name COLLATE Cyrillic_General_CI_AS,
		isSuccess = 
			CASE CheckListItemType.Name
				--1
				WHEN 'Звонок работодателю по телефонам из Контур Фокус'
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
				WHEN 'Звонок работодателю по телефону из Анкеты'
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
							'КЛ не знает клиента/номер не существует, клиент подтвердил номер',
							'КЛ не знает клиента/номер не существует, не удалось подтвердить номер',
							'Негатив от КЛ (должник, алкоголик, наркоман)'
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
			'Звонок работодателю по телефонам из Контур Фокус',
			'Звонок работодателю по телефонам из Интернет',
			'Звонок работодателю по телефону из Анкеты',
			'Звонок контактному лицу'
		)
	-- звонок назначен, но еще не выполнен
	UNION SELECT 1, 'Звонок работодателю по телефонам из Контур Фокус','назначен', 0
	UNION SELECT 2, 'Звонок работодателю по телефонам из Интернет','назначен', 0
	UNION SELECT 3, 'Звонок работодателю по телефону из Анкеты','назначен', 0
	UNION SELECT 4, 'Звонок контактному лицу','назначен', 0


	--Дата рассмотрения заявки = Дата, когда был выбран результат в чек-листе
	DROP TABLE IF EXISTS #t_checklists

	;with loginom_checklists AS (
		SELECT 
			max_CreatedOn = max(cli.CreatedOn),
			cli.IdClientRequest
		FROM #t_IdClientRequest as id
			inner join Stg._fedor.core_CheckListItem AS cli
				on cli.IdClientRequest = id.IdClientRequest
			INNER JOIN Stg._fedor.dictionary_CheckListItemStatus AS cis
				ON cis.id = cli.IdStatus
			--при расчете контактности учитываются только результаты "звонковых" проверок, то есть в рамках которых был осуществлен звонок
			--в изначальном документе, по которому создавался данный отчет в разделе ПТС и Инстолмент 
			--в пунктах 4 прописаны звонковые проверки и результаты (во вложении отчет по контактности)
			INNER JOIN #t_Contact_Call AS C
				ON cis.Name COLLATE Cyrillic_General_CI_AS = C.result_name
		WHERE 1=1
			--AND cli.CreatedOn >= dateadd(HOUR, -3, cast(@dt_from AS datetime2))
			--AND cli.CreatedOn <= dateadd(HOUR, -3, cast(@dt_to AS datetime2))
			AND cli.CreatedOn >= dateadd(day, -10, cast(@dt_from AS datetime2))
			AND cli.CreatedOn <= cast(@dt_to AS datetime2)
		GROUP BY cli.IdClientRequest
	)
	SELECT 
		cli.IdClientRequest,
		Number = CR.Number, --COLLATE Cyrillic_General_CI_AS,
		rl.max_CreatedOn,
		CheckListItemTypeName = cit.[Name],
		CheckListItemStatusName = cis.[Name]
	into #t_checklists
	FROM Stg._fedor.core_CheckListItem AS cli
		JOIN Stg._fedor.dictionary_CheckListItemType AS cit ON cit.id = cli.IdType
		JOIN Stg._fedor.dictionary_CheckListItemStatus AS cis ON cis.id = cli.IdStatus
		JOIN loginom_checklists AS rl 
			ON rl.IdClientRequest = cli.IdClientRequest 
			--AND try_cast(replace(cis.LoginomNumber,'.','') AS bigint) = rl.logn
			AND rl.max_CreatedOn = cli.CreatedOn
		INNER JOIN Stg._fedor.core_ClientRequest AS CR
			ON CR.Id = cli.IdClientRequest

	CREATE INDEX ix1 ON #t_checklists(IdClientRequest)
	CREATE INDEX ix2 ON #t_checklists(Number)




	drop table if exists #t_dm_FedorVerificationRequests_AutocredVTB
	CREATE TABLE #t_dm_FedorVerificationRequests_AutocredVTB
	(
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
		[Офис заведения заявки] [nvarchar](250) NULL,
		[ЗвонокРаботодателюПоТелефонамИзКонтурФокус] int NULL,
		[ЗвонокРаботодателюПоТелефонамИзИнтернет] int NULL,
		[ЗвонокРаботодателюПоТелефонуИзАнкеты] int NULL,
		[ЗвонокКонтактномуЛицу] int NULL,
		ТипКлиента varchar(30) NULL,
		[Дата рассмотрения заявки] datetime2,
		Партнер varchar(50)
	)

	INSERT #t_dm_FedorVerificationRequests_AutocredVTB
	(
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
		[Офис заведения заявки],
		ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
		ЗвонокРаботодателюПоТелефонамИзИнтернет,
		ЗвонокРаботодателюПоТелефонуИзАнкеты,
		ЗвонокКонтактномуЛицу,
		ТипКлиента,
		[Дата рассмотрения заявки],
		Партнер
	)
	SELECT 
		IdClientRequest = CR.Id,
		R.[Дата заведения заявки],
        R.[Время заведения],
        R.[Номер заявки] COLLATE Cyrillic_General_CI_AS,
        R.[ФИО клиента] COLLATE Cyrillic_General_CI_AS,
        R.Статус COLLATE Cyrillic_General_CI_AS,
        R.Задача COLLATE Cyrillic_General_CI_AS,
        R.[Состояние заявки] COLLATE Cyrillic_General_CI_AS,
        R.[Дата статуса],
        R.[Дата след.статуса],
        R.[ФИО сотрудника верификации/чекер] COLLATE Cyrillic_General_CI_AS,
        R.ВремяЗатрачено,
        R.[Время, час:мин:сек],
        R.[Статус следующий] COLLATE Cyrillic_General_CI_AS,
        R.[Задача следующая] COLLATE Cyrillic_General_CI_AS,
        R.[Состояние заявки следующая] COLLATE Cyrillic_General_CI_AS,
        R.ПричинаНаим_Исх,
        R.ПричинаНаим_След,
        R.[Последнее состояние заявки на дату по сотруднику] COLLATE Cyrillic_General_CI_AS,
        R.[Последний статус заявки на дату по сотруднику] COLLATE Cyrillic_General_CI_AS,
        R.[Последний статус заявки на дату] COLLATE Cyrillic_General_CI_AS,
        R.СотрудникПоследнегоСтатуса COLLATE Cyrillic_General_CI_AS,
        R.ШагЗаявки,
        R.ПоследнийШаг,
        R.[Последний статус заявки] COLLATE Cyrillic_General_CI_AS,
        R.[Время в последнем статусе],
        R.[Время в последнем статусе, hh:mm:ss] COLLATE Cyrillic_General_CI_AS,
        R.ВремяЗатраченоОжиданиеВерификацииКлиента,
        R.ПризнакИсключенияСотрудника,
        R.Работник COLLATE Cyrillic_General_CI_AS,
        R.Назначен COLLATE Cyrillic_General_CI_AS,
        R.Работник_Пред COLLATE Cyrillic_General_CI_AS,
        R.Назначен_Пред COLLATE Cyrillic_General_CI_AS,
        R.Работник_След COLLATE Cyrillic_General_CI_AS,
        R.Назначен_След COLLATE Cyrillic_General_CI_AS,
		R.[Офис заведения заявки] COLLATE Cyrillic_General_CI_AS,
		ЗвонокРаботодателюПоТелефонамИзКонтурФокус = C1.isSuccess,
		ЗвонокРаботодателюПоТелефонамИзИнтернет = C2.isSuccess,
		ЗвонокРаботодателюПоТелефонуИзАнкеты = C3.isSuccess,
		ЗвонокКонтактномуЛицу = C4.isSuccess,
		R.ТипКлиента,
		[Дата рассмотрения заявки] = N.max_CreatedOn,
		R.Партнер
	--INTO #t_dm_FedorVerificationRequests_AutocredVTB
	--FROM Reports.dbo.dm_FedorVerificationRequests_AutocredVTB AS R (NOLOCK)
	FROM Reports.dbo.dm_FedorVerificationRequests AS R --DWH-310
		INNER JOIN Stg._fedor.core_ClientRequest AS CR
			ON CR.Number COLLATE Cyrillic_General_CI_AS = R.[Номер заявки]
		LEFT JOIN #t_Contact_Call AS C1
			ON C1.call_type_name = 'Звонок работодателю по телефонам из Контур Фокус'
			AND C1.result_name = R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус
		LEFT JOIN #t_Contact_Call AS C2
			ON C2.call_type_name = 'Звонок работодателю по телефонам из Интернет'
			AND C2.result_name = R.ЗвонокРаботодателюПоТелефонамИзИнтернет
		LEFT JOIN #t_Contact_Call AS C3
			ON C3.call_type_name = 'Звонок работодателю по телефону из Анкеты'
			AND C3.result_name = R.ЗвонокРаботодателюПоТелефонуИзАнкеты
		LEFT JOIN #t_Contact_Call AS C4
			ON C4.call_type_name = 'Звонок контактному лицу'
			AND C4.result_name = R.ЗвонокКонтактномуЛицу
		LEFT JOIN #t_checklists AS N
			ON R.[Номер заявки] = N.Number
	WHERE 1=1
		AND R.[Дата статуса] > @dt_from
		AND R.[Дата статуса] < @dt_to
		and isnull(R.КодТипКредитногоПродукта, 'pts') = 'autoCredit'


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
	FROM #t_dm_FedorVerificationRequests_AutocredVTB AS T

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_dm_FedorVerificationRequests_AutocredVTB
		SELECT * INTO ##t_dm_FedorVerificationRequests_AutocredVTB FROM #t_dm_FedorVerificationRequests_AutocredVTB
	END


drop table if exists #curr_employee_test
create table #curr_employee_test([Employee] nvarchar(255))

INSERT #curr_employee_test(Employee)
--select *
--select substring(trim(U.DisplayName), 1, 255)
--FROM [dwh-ex].bot.dbo.[vw_ActiveDirectoryUsers] AS U
--where U.Department ='Отдел тестирования'
--and u.DomainAccount !='r.mekshinev' -- перешел в отдел тестирование из отдела верификации
--UNION
SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
FROM Stg._fedor.core_user AS U
WHERE U.IsQAUser = 1

DELETE R
FROM #t_dm_FedorVerificationRequests_AutocredVTB AS R
WHERE 1=1
	AND R.Работник IN (SELECT Employee FROM #curr_employee_test)


DELETE R
FROM #t_dm_FedorVerificationRequests_AutocredVTB AS R
WHERE 1=1
	AND R.[ФИО сотрудника верификации/чекер] IN (SELECT Employee FROM #curr_employee_test)


	CREATE CLUSTERED INDEX clix1 
	ON #t_dm_FedorVerificationRequests_AutocredVTB([Номер заявки], [Дата статуса])

	CREATE INDEX ix2
	ON #t_dm_FedorVerificationRequests_AutocredVTB([Статус], [Дата статуса])
	include([Номер заявки], IdClientRequest, [Статус следующий])

	CREATE INDEX ix3
	ON #t_dm_FedorVerificationRequests_AutocredVTB(Работник)
	
	CREATE INDEX ix4
	ON #t_dm_FedorVerificationRequests_AutocredVTB([Дата заведения заявки], [Номер заявки])



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


--select * from #HoursDays
-- статические справочники
  --select  distinct [ФИО сотрудника верификации/чекер] from #t_dm_FedorVerificationRequests_AutocredVTB
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
	FROM Stg._fedor.core_user AS U
		INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
			and (
				(isnull(UR.deleted_at, '2100-01-01') >= @dt_from and UR.IsDeleted = 1)
				or isnull(UR.IsDeleted, 0) = 0
			)
		INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
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
				when '6FE99E14-F925-4F62-BC3B-D8FFD8D82B98' then '2024-04-23'
			end
		from Stg._fedor.core_user u
		where Id in(
			'244F6B46-49D8-4E11-B68D-05C5D7A9C8BC', --Жарких Марина Павловна
			'6FE99E14-F925-4F62-BC3B-D8FFD8D82B98' --Короткова Евгения Игоревна --обращение #prod 25 апреля 2024 г. a.zaharov 11:22
			)
	) u
	where U.DeleteDate >= @dt_from
	

   
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
	FROM Stg._fedor.core_user AS U
		INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
			and (
				(isnull(UR.deleted_at, '2100-01-01') >= @dt_from and UR.IsDeleted = 1)
				or isnull(UR.IsDeleted, 0) = 0
			)
		INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
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
					when '6FE99E14-F925-4F62-BC3B-D8FFD8D82B98' then '2024-04-23'
					ELSE u.DeleteDate
				end
			from Stg._fedor.core_user u
			where Id in(
				'89EAED68-E616-415C-BE92-0C2D4C084899', --Столица Вероника Игоревна
				'6FE99E14-F925-4F62-BC3B-D8FFD8D82B98' --Короткова Евгения Игоревна --обращение #prod 25 апреля 2024 г. a.zaharov 11:22
				)
		) u
		where U.DeleteDate >= @dt_from


DROP TABLE IF EXISTS #t_request_number
CREATE TABLE #t_request_number
(
	IdClientRequest uniqueidentifier, 
	[Номер заявки] nvarchar(255) --COLLATE SQL_Latin1_General_CP1_CI_AS
)

DROP TABLE IF EXISTS #t_approved
CREATE TABLE #t_approved
(
	[Номер заявки] nvarchar(255), --COLLATE SQL_Latin1_General_CP1_CI_AS,
	[Дата статуса] datetime2(7)
)

DROP TABLE IF EXISTS #t_denied
CREATE TABLE #t_denied(
	[Номер заявки] nvarchar(255), --COLLATE SQL_Latin1_General_CP1_CI_AS,
	[Дата статуса] datetime2(7)
)

DROP TABLE IF EXISTS #t_canceled
CREATE TABLE #t_canceled
(
	[Номер заявки] nvarchar(255), --COLLATE SQL_Latin1_General_CP1_CI_AS,
	[Дата статуса] datetime2(7),
	isAuto int,
	isPostpone int
)

DROP TABLE IF EXISTS #t_customer_rejection
CREATE TABLE #t_customer_rejection(
	[Номер заявки] nvarchar(255), --COLLATE SQL_Latin1_General_CP1_CI_AS,
	[Дата статуса] datetime2(7)
)

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
FROM #t_dm_FedorVerificationRequests_AutocredVTB AS R
WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
	--AND R.[Дата статуса] > @dt_from
	--AND R.[Дата статуса] < @dt_to

--одобрено
INSERT #t_approved([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	--AND R.[Дата статуса] > @dt_from
	--AND R.[Дата статуса] < @dt_to
	AND (
		   (R.Статус IN ('Верификация Call 1.5') AND R.[Статус следующий] IN ('Ожидание подписи документов EDO', 'Переподписание первого пакета', 'Верификация Call 2'))
		OR (R.Статус IN ('Верификация ТС','Верификация Call 4') AND R.[Статус следующий] IN ('Одобрено'))
		OR (R.Статус IN ('Верификация Call 3') AND R.[Статус следующий] IN ('Одобрен клиент'))
	)
GROUP BY R.[Номер заявки]

--отказано
INSERT #t_denied([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	--AND R.[Дата статуса] > @dt_from
	--AND R.[Дата статуса] < @dt_to
	AND R.Статус IN ('Верификация Call 1.5','Верификация ТС','Верификация Call 3','Верификация Call 4')
	AND R.[Статус следующий] IN ('Отказано')
GROUP BY R.[Номер заявки]

--анулировано
INSERT #t_canceled([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	--AND R.[Дата статуса] > @dt_from
	--AND R.[Дата статуса] < @dt_to
	AND R.Статус IN ('Контроль данных','Верификация клиента','Верификация ТС','Верификация Call 3','Верификация Call 4') 
	AND R.[Статус следующий] IN ('Аннулировано')
GROUP BY R.[Номер заявки]

--Отказ клиента
INSERT #t_customer_rejection([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	--AND R.[Дата статуса] > @dt_from
	--AND R.[Дата статуса] < @dt_to
	AND R.Статус IN ('Верификация Call 1.5')
	AND R.[Статус следующий] IN ('Отказ клиента')
GROUP BY R.[Номер заявки]





  --Лист "Общий (детализация)"
IF @Page = 'Detail' OR @isFill_All_Tables = 1
BEGIN

	IF @isFill_All_Tables = 1
	BEGIN
		--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_Detail
		DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_Detail AS T WHERE T.ProcessGUID = @ProcessGUID

		INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_Detail
		SELECT
			ProcessGUID = @ProcessGUID,
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
			 , R.[Офис заведения заявки]
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
			END,
			R.ТипКлиента,
			R.[Дата рассмотрения заявки],
			R.Партнер
		--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_Detail
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
				ON R.[Номер заявки] = N.[Номер заявки]
			--одобрено
			LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
			--отказано
			LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
			--анулировано
			LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
			--Отказ клиента
			LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
		WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
			--AND R.[Дата статуса] > @dt_from 
			--AND R.[Дата статуса] < @dt_to
		order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc

		INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
		SELECT getdate(), 'Detail', @ProcessGUID

	END
	ELSE BEGIN
	SELECT R.[Дата заведения заявки]
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
		 , R.[Офис заведения заявки]
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
		END,
		R.ТипКлиента,
		R.[Дата рассмотрения заявки],
		R.Партнер
	FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
			ON R.[Номер заявки] = N.[Номер заявки]
		--одобрено
		LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
		--отказано
		LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
		--анулировано
		LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
		--Отказ клиента
		LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
	WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
		--AND R.[Дата статуса] > @dt_from 
		--AND R.[Дата статуса] < @dt_to
	order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc

		RETURN 0
	END
END
--// 'Detail'






IF @Page = 'DetailHours' OR @isFill_All_Tables = 1
BEGIN
	IF @isFill_All_Tables = 1
	BEGIN
		--Датасет не используется
		/*
		--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_DetailHours
		DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_DetailHours AS T WHERE T.ProcessGUID = @ProcessGUID

		INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_DetailHours
		select --top 100
			ProcessGUID = @ProcessGUID,
			fv.[Дата заведения заявки]
			, fv.[Время заведения]
			, fv.[Номер заявки]
			, fv.[ФИО клиента]
			, fv.[Статус]
			, fv.[Задача]
			, fv.[Состояние заявки]
			, fv.[Дата статуса]
			-- 20210326
			, [ФИО сотрудника верификации/чекер] = fv.Работник
			, fv.[ВремяЗатрачено]
			, fv.[Время, час:мин:сек]
			, fv.[Статус следующий]
			, fv.[Задача следующая]
			, fv.[Состояние заявки следующая]
			, fv.Назначен
			, hourInterval 'Интервал'
			, beginInterval 'Начало интервала'
			, endInterval 'Конец интервала'
			, cast(endInterval as decimal(15,10)) -  cast(beginInterval as decimal(15,10))  ЗатраченоВИнтервале
			--, hr.flagBeginInterval
			--, hr.rn ШагЧасаСтатуса
			, ШагЧасаСтатуса = row_number() over(partition by fv.[Номер заявки], fv.ШагЗаявки order by endInterval )
			, КоличествоЗаявокВЧасе = count(fv.[Номер заявки]) over(partition by hourInterval)
		--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_DetailHours
		from #t_dm_FedorVerificationRequests_AutocredVTB fv--#details
		cross apply dwh2.[dbo].[times_from_interval_hours] ([Дата статуса], [Дата след.статуса],60) hr 
		where [Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС') and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
		and beginInterval is not null
		--order by  Работник ,[Дата статуса] desc ,[Номер заявки] desc
		*/
		INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
		SELECT getdate(), 'DetailHours', @ProcessGUID
	END
	ELSE BEGIN
  select --top 100
  fv.[Дата заведения заявки]
	     , fv.[Время заведения]
	     , fv.[Номер заявки]
	     , fv.[ФИО клиента]
	     , fv.[Статус]
	     , fv.[Задача]
	     , fv.[Состояние заявки]
	     , fv.[Дата статуса]
	      -- 20210326
	     , [ФИО сотрудника верификации/чекер] = fv.Работник
	     , fv.[ВремяЗатрачено]
       , fv.[Время, час:мин:сек]
	     , fv.[Статус следующий]
	     , fv.[Задача следующая]
	     , fv.[Состояние заявки следующая]
		 , fv.Назначен
		 , hourInterval 'Интервал'
		 , beginInterval 'Начало интервала'
		 , endInterval 'Конец интервала'
		 , cast(endInterval as decimal(15,10)) -  cast(beginInterval as decimal(15,10))  ЗатраченоВИнтервале
		 --, hr.flagBeginInterval
		 --, hr.rn ШагЧасаСтатуса
		 , ШагЧасаСтатуса = row_number() over(partition by fv.[Номер заявки], fv.ШагЗаявки order by endInterval )
		 , КоличествоЗаявокВЧасе = count(fv.[Номер заявки]) over(partition by hourInterval)

		 
		from #t_dm_FedorVerificationRequests_AutocredVTB fv--#details
	cross apply dwh2.[dbo].[times_from_interval_hours] ([Дата статуса], [Дата след.статуса],60) hr 
   where [Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС') 
   --and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
   and beginInterval is not null
   --order by  Работник ,[Дата статуса] desc ,[Номер заявки] desc

		RETURN 0    
	END
END
--// 'DetailHours'

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
	FROM #t_dm_FedorVerificationRequests_AutocredVTB AS R
	WHERE R.[Статус] in ('Контроль данных')
		--AND R.[Дата статуса] > @dt_from
		--AND R.[Дата статуса] < @dt_to

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

	--IF @isDebug = 1 BEGIN
	--	DROP TABLE IF EXISTS ##t_checklists_rejects
	--	SELECT * INTO ##t_checklists_rejects FROM #t_checklists_rejects
	--END

	--одобрено
	INSERT #t_approved([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		--AND R.[Дата статуса] > @dt_from
		--AND R.[Дата статуса] < @dt_to
		AND ((R.Статус IN ('Верификация Call 1.5') 
			AND R.[Статус следующий] IN ('Ожидание подписи документов EDO', 'Переподписание первого пакета', 'Верификация Call 2'))
			)
	GROUP BY R.[Номер заявки]

	--2 одобрено сотрудником, но отказано автоматически
	INSERT #t_approved([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		--AND R.[Дата статуса] > @dt_from
		--AND R.[Дата статуса] < @dt_to
		AND R.Статус IN ('Верификация Call 1.5')
		AND R.[Статус следующий] IN ('Отказано')
		AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
	GROUP BY R.[Номер заявки]

	--отказано сотрудником
	INSERT #t_denied([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		--AND R.[Дата статуса] > @dt_from
		--AND R.[Дата статуса] < @dt_to
		AND R.Статус IN ('Верификация Call 1.5')
		AND R.[Статус следующий] IN ('Отказано')
		AND EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
	GROUP BY R.[Номер заявки]

	--анулировано
	INSERT #t_canceled([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		--AND R.[Дата статуса] > @dt_from
		--AND R.[Дата статуса] < @dt_to
		AND R.Статус IN ('Контроль данных')
		AND R.[Статус следующий] IN ('Аннулировано')
	GROUP BY R.[Номер заявки]

	--Отказ клиента
	INSERT #t_customer_rejection([Номер заявки],[Дата статуса])
	SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
	FROM #t_request_number AS N
		INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
			ON R.[Номер заявки] = N.[Номер заявки]
	WHERE 1=1
		--AND R.[Дата статуса] > @dt_from
		--AND R.[Дата статуса] < @dt_to
		AND R.Статус IN ('Верификация Call 1.5')
		AND R.[Статус следующий] IN ('Отказ клиента')
	GROUP BY R.[Номер заявки]


	IF @isFill_All_Tables = 1
	BEGIN
		--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Detail
		DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Detail AS T WHERE T.ProcessGUID = @ProcessGUID

		INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Detail
		SELECT 
			ProcessGUID = @ProcessGUID,
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
			 , R.[Офис заведения заявки]
			 --DWH-1720
			 , [Решение по заявке] = trim(
					concat(
						iif(approved.[Номер заявки] IS NOT NULL,'Одобрено',''),' ',
						iif(denied.[Номер заявки] IS NOT NULL,'Отказано',''),' ',
						iif(canceled.[Номер заявки] IS NOT NULL,'Аннулировано',''), ' ',
						iif(customer_rejection.[Номер заявки] IS NOT NULL,'Отказ клиента','')
						)
				),
			R.ТипКлиента,
			R.[Дата рассмотрения заявки],
			R.Партнер
		--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Detail
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
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
			--AND R.[Дата статуса] > @dt_from 
			--AND R.[Дата статуса] < @dt_to
		ORDER BY R.Работник asc, R.[Дата заведения заявки] desc, R.[Время заведения] desc

		INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
		SELECT getdate(), 'KD.Detail', @ProcessGUID
	END
	ELSE BEGIN
		SELECT R.[Дата заведения заявки]
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
			 , R.[Офис заведения заявки]
			 --DWH-1720
			 , [Решение по заявке] = trim(
					concat(
						iif(approved.[Номер заявки] IS NOT NULL,'Одобрено',''),' ',
						iif(denied.[Номер заявки] IS NOT NULL,'Отказано',''),' ',
						iif(canceled.[Номер заявки] IS NOT NULL,'Аннулировано',''), ' ',
						iif(customer_rejection.[Номер заявки] IS NOT NULL,'Отказ клиента','')
						)
				),
			R.ТипКлиента,
			R.[Дата рассмотрения заявки],
			R.Партнер
		FROM #t_request_number AS N
				INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
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
			--AND R.[Дата статуса] > @dt_from 
			--AND R.[Дата статуса] < @dt_to
		ORDER BY R.Работник asc, R.[Дата заведения заявки] desc, R.[Время заведения] desc
      
		RETURN 0
	END
  END
--// 'KD.Detail'


   -- Лист "КД. Детализация"
IF @Page = 'KD.DetailHours' OR @isFill_All_Tables = 1 --241
BEGIN
	IF @isFill_All_Tables = 1
	BEGIN
		--Датасет не используется
		/*
		--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_DetailHours
		DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_DetailHours AS T WHERE T.ProcessGUID = @ProcessGUID

		INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_DetailHours
		SELECT 
				ProcessGUID = @ProcessGUID,
				fv.[Дата заведения заявки]
				, fv.[Время заведения]
				, fv.[Номер заявки]
				, fv.[ФИО клиента]
				, fv.[Статус]
				, fv.[Задача]
				, fv.[Состояние заявки]
				, fv.[Дата статуса]
				-- 20210326
				, [ФИО сотрудника верификации/чекер] = fv.Работник
				, fv.[ВремяЗатрачено]
			, fv.[Время, час:мин:сек]
				, fv.[Статус следующий]
				, fv.[Задача следующая]
				, fv.[Состояние заявки следующая]
				, fv.Назначен
				, hourInterval 'Интервал'
				, beginInterval 'Начало интервала'
				, endInterval 'Конец интервала'
				, cast(endInterval as decimal(15,10)) -  cast(beginInterval as decimal(15,10))  ЗатраченоВИнтервале
				--, hr.flagBeginInterval
				--, hr.rn ШагЧасаСтатуса
				, ШагЧасаСтатуса = row_number() over(partition by fv.[Номер заявки], fv.ШагЗаявки order by endInterval )
				, КоличествоЗаявокВЧасе = count(fv.[Номер заявки]) over(partition by hourInterval)
		--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_DetailHours
		from #t_dm_FedorVerificationRequests_AutocredVTB fv--#details
		cross apply dwh2.[dbo].[times_from_interval_hours] ([Дата статуса], [Дата след.статуса],60) hr 
		where [Статус] in ('Контроль данных') 
		--and fv.[Номер заявки] = '21040100093442'
		and fv.[Дата статуса]>@dt_from and  fv.[Дата статуса]<@dt_to
		and beginInterval is not null
		--order by Работник asc ,[Дата заведения заявки] desc ,[Время заведения] desc
		*/
		INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
		SELECT getdate(), 'KD.DetailHours', @ProcessGUID
	END
	ELSE BEGIN
 select --top 100
  fv.[Дата заведения заявки]
	     , fv.[Время заведения]
	     , fv.[Номер заявки]
	     , fv.[ФИО клиента]
	     , fv.[Статус]
	     , fv.[Задача]
	     , fv.[Состояние заявки]
	     , fv.[Дата статуса]
	      -- 20210326
	     , [ФИО сотрудника верификации/чекер] = fv.Работник
	     , fv.[ВремяЗатрачено]
       , fv.[Время, час:мин:сек]
	     , fv.[Статус следующий]
	     , fv.[Задача следующая]
	     , fv.[Состояние заявки следующая]
		 , fv.Назначен
		 , hourInterval 'Интервал'
		 , beginInterval 'Начало интервала'
		 , endInterval 'Конец интервала'
		 , cast(endInterval as decimal(15,10)) -  cast(beginInterval as decimal(15,10))  ЗатраченоВИнтервале
		 --, hr.flagBeginInterval
		 --, hr.rn ШагЧасаСтатуса
		 , ШагЧасаСтатуса = row_number() over(partition by fv.[Номер заявки], fv.ШагЗаявки order by endInterval )
		 , КоличествоЗаявокВЧасе = count(fv.[Номер заявки]) over(partition by hourInterval)
		from #t_dm_FedorVerificationRequests_AutocredVTB fv--#details
	cross apply dwh2.[dbo].[times_from_interval_hours] ([Дата статуса], [Дата след.статуса],60) hr 
   where [Статус] in ('Контроль данных') 
   --and fv.[Номер заявки] = '21040100093442'
   --and fv.[Дата статуса]>@dt_from and  fv.[Дата статуса]<@dt_to
   and beginInterval is not null
   --order by Работник asc ,[Дата заведения заявки] desc ,[Время заведения] desc

		RETURN 0
	END
END
--// 'KD.DetailHours'


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
FROM #t_dm_FedorVerificationRequests_AutocredVTB AS R
WHERE R.[Статус] in ('Верификация клиента')
	--AND R.[Дата статуса] > @dt_from
	--AND R.[Дата статуса] < @dt_to

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

--IF @isDebug = 1 BEGIN
--	DROP TABLE IF EXISTS ##t_checklists_rejects
--	SELECT * INTO ##t_checklists_rejects FROM #t_checklists_rejects
--END

--одобрено
INSERT #t_approved([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	--AND R.[Дата статуса] > @dt_from
	--AND R.[Дата статуса] < @dt_to
	AND (R.Статус IN ('Верификация Call 3') AND R.[Статус следующий] IN ('Одобрен клиент'))
GROUP BY R.[Номер заявки]

--2 одобрено сотрудником, но отказано автоматически
INSERT #t_approved([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	--AND R.[Дата статуса] > @dt_from
	--AND R.[Дата статуса] < @dt_to
	AND R.Статус IN ('Верификация Call 3')
	AND R.[Статус следующий] IN ('Отказано')
	AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
GROUP BY R.[Номер заявки]

--отказано
INSERT #t_denied([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	--AND R.[Дата статуса] > @dt_from
	--AND R.[Дата статуса] < @dt_to
	AND R.Статус IN ('Верификация Call 3')
	AND R.[Статус следующий] IN ('Отказано')
	AND EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
GROUP BY R.[Номер заявки]

--анулировано
INSERT #t_canceled([Номер заявки],[Дата статуса], isAuto, isPostpone)
SELECT 
	R.[Номер заявки], 
	[Дата статуса] = min(R.[Дата статуса]),
	isAuto = 
		CASE 
			WHEN R.[ФИО сотрудника верификации/чекер] LIKE '%Системный%' THEN 1
			ELSE 0
		END,
	isPostpone = 
		CASE 
			WHEN V.[Номер заявки] IS NOT NULL THEN 1
			ELSE 0
		END
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
		ON R.[Номер заявки] = N.[Номер заявки]
	LEFT JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS V
		ON V.[Номер заявки] = R.[Номер заявки]
		AND V.ШагЗаявки = R.ШагЗаявки - 2
		AND V.Задача='task:Отложена' 
		AND V.[Состояние заявки] IN ('Отложена')
		AND V.Статус in('Верификация клиента')
WHERE 1=1
	--AND R.[Дата статуса] > @dt_from
	--AND R.[Дата статуса] < @dt_to
	--AND R.Статус IN ('Верификация клиента','Верификация ТС','Верификация Call 3','Верификация Call 4')
	AND R.Статус IN ('Верификация клиента','Верификация Call 3','Верификация Call 4')
	AND R.[Статус следующий] IN ('Аннулировано')
GROUP BY R.[Номер заявки], R.[ФИО сотрудника верификации/чекер], V.[Номер заявки]

--Отказ клиента
INSERT #t_customer_rejection([Номер заявки],[Дата статуса])
SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
FROM #t_request_number AS N
	INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
		ON R.[Номер заявки] = N.[Номер заявки]
WHERE 1=1
	--AND R.[Дата статуса] > @dt_from
	--AND R.[Дата статуса] < @dt_to
	AND R.Статус IN ('Верификация Call 1.5')
	AND R.[Статус следующий] IN ('Отказ клиента')
GROUP BY R.[Номер заявки]


--Лист "ВК. Детализация"
IF @Page = 'VK.Detail' OR @isFill_All_Tables = 1 --301
  BEGIN
	IF @isFill_All_Tables = 1
	BEGIN
		--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Detail
		DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Detail AS T WHERE T.ProcessGUID = @ProcessGUID

		INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Detail
		SELECT 
			ProcessGUID = @ProcessGUID,
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
			 , R.[Офис заведения заявки]
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
				WHEN canceled.[Номер заявки] IS NOT NULL 
					THEN concat(
						'Аннулировано',
						CASE 
							WHEN canceled.isAuto = 1 THEN '  автоматически'
							ELSE ' вручную'
						END
						)
				WHEN denied.[Номер заявки] IS NOT NULL THEN 'Отказано'
				WHEN approved.[Номер заявки] IS NOT NULL THEN 'Одобрено'
				WHEN customer_rejection.[Номер заявки] IS NOT NULL THEN 'Отказ клиента'
				ELSE ''
			END,
			R.ТипКлиента,
			R.[Дата рассмотрения заявки],
			Комментарий = 
			CASE 
				WHEN canceled.isAuto = 1 AND canceled.isPostpone = 1 THEN 'Не вернулась из отложенных'
				ELSE NULL
			END,
			R.Партнер
		--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Detail
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
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
			--AND R.[Дата статуса] > @dt_from 
			--AND R.[Дата статуса] < @dt_to
		order by Работник ,[Дата статуса] desc ,[Номер заявки] desc

		INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
		SELECT getdate(), 'VK.Detail', @ProcessGUID
	END
	ELSE BEGIN
		SELECT R.[Дата заведения заявки]
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
			 , R.[Офис заведения заявки]
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
				WHEN canceled.[Номер заявки] IS NOT NULL 
					THEN concat(
						'Аннулировано',
						CASE 
							WHEN canceled.isAuto = 1 THEN '  автоматически'
							ELSE ' вручную'
						END
						)
				WHEN denied.[Номер заявки] IS NOT NULL THEN 'Отказано'
				WHEN approved.[Номер заявки] IS NOT NULL THEN 'Одобрено'
				WHEN customer_rejection.[Номер заявки] IS NOT NULL THEN 'Отказ клиента'
				ELSE ''
			END,
			R.ТипКлиента,
			R.[Дата рассмотрения заявки],
			Комментарий = 
			CASE 
				WHEN canceled.isAuto = 1 AND canceled.isPostpone = 1 THEN 'Не вернулась из отложенных'
				ELSE NULL
			END,
			R.Партнер
		FROM #t_request_number AS N
				INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
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
			--AND R.[Дата статуса] > @dt_from 
			--AND R.[Дата статуса] < @dt_to
		order by Работник ,[Дата статуса] desc ,[Номер заявки] desc

		RETURN 0
  END
END
--// 'VK.Detail'




--DWH-2067
--Лист "Контактность. Детализация"
IF @Page = 'Contact.Detail' OR @isFill_All_Tables = 1
BEGIN
	IF @isFill_All_Tables = 1
	BEGIN
		--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_Detail
		DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_Detail AS T WHERE T.ProcessGUID = @ProcessGUID

		INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_Detail
		(
		    ProcessGUID,
		    [Дата заведения заявки],
		    [Время заведения],
		    [Номер заявки],
		    [ФИО клиента],
		    --Статус,
		    --Задача,
		    --[Состояние заявки],
		    --[Дата статуса],
		    --[ФИО сотрудника верификации/чекер],
		    --Назначен,
		    --ВремяЗатрачено,
		    --[Время, час:мин:сек],
		    --[Статус следующий],
		    --[Задача следующая],
		    --[Состояние заявки следующая],
		    [Офис заведения заявки],
		    [Решение по заявке],
		    ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
		    ЗвонокРаботодателюПоТелефонамИзИнтернет,
		    ЗвонокРаботодателюПоТелефонуИзАнкеты,
		    ЗвонокКонтактномуЛицу,
		    ИтогоКонтактность,
			[Дата рассмотрения заявки]
		)
		SELECT DISTINCT
			C.ProcessGUID,
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
			C.[Офис заведения заявки],
			C.[Решение по заявке],
			C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
			C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
			C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
			C.ЗвонокКонтактномуЛицу,
			C.ИтогоКонтактность,
			C.[Дата рассмотрения заявки]
		FROM (
			SELECT
				ProcessGUID = @ProcessGUID,
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
				 , R.[Офис заведения заявки]
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
				, ИтогоКонтактность = 
					isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
					isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
					isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
					isnull(R.ЗвонокКонтактномуЛицу, 0),
				R.[Дата рассмотрения заявки]
			--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_Detail
			FROM #t_request_number AS N
				INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
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
			WHERE R.[Статус] in ('Верификация клиента')
				--AND R.[Дата статуса] > @dt_from 
				--AND R.[Дата статуса] < @dt_to
			--order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc
		) AS C
		WHERE C.[Решение по заявке] IN ('Отказано', 'Одобрено')
		--ORDER BY C.[ФИО сотрудника верификации/чекер], C.[Дата статуса] desc, C.[Номер заявки] desc
		ORDER BY C.[Номер заявки] DESC

		INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
		SELECT getdate(), 'Contact.Detail', @ProcessGUID

	END
	ELSE BEGIN
		SELECT DISTINCT
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
			C.[Офис заведения заявки],
			C.[Решение по заявке],
			C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
			C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
			C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
			C.ЗвонокКонтактномуЛицу,
			C.ИтогоКонтактность,
			C.[Дата рассмотрения заявки]
		FROM (
			SELECT R.[Дата заведения заявки]
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
				 , R.[Офис заведения заявки]
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
					--WHEN canceled.[Номер заявки] IS NOT NULL THEN 'Аннулировано'
					WHEN denied.[Номер заявки] IS NOT NULL THEN 'Отказано'
					WHEN approved.[Номер заявки] IS NOT NULL THEN 'Одобрено'
					--WHEN customer_rejection.[Номер заявки] IS NOT NULL THEN 'Отказ клиента'
					ELSE ''
				END,
				R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
				R.ЗвонокРаботодателюПоТелефонамИзИнтернет,
				R.ЗвонокРаботодателюПоТелефонуИзАнкеты,
				R.ЗвонокКонтактномуЛицу,
				ИтогоКонтактность = 
					isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
					isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
					isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
					isnull(R.ЗвонокКонтактномуЛицу, 0),
				R.[Дата рассмотрения заявки]
			FROM #t_request_number AS N
					INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
					ON R.[Номер заявки] = N.[Номер заявки]
				--одобрено
				LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
				--отказано
				LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
				--анулировано
				--LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
				--Отказ клиента
				--LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
			--WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
			WHERE R.[Статус] in ('Верификация клиента')
				--AND R.[Дата статуса] > @dt_from 
				--AND R.[Дата статуса] < @dt_to
			--order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc
		) AS C
		WHERE C.[Решение по заявке] IN ('Отказано', 'Одобрено')
		--ORDER BY C.[ФИО сотрудника верификации/чекер], C.[Дата статуса] desc, C.[Номер заявки] desc
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
		--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_DetailByEmployee
		DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_DetailByEmployee AS T WHERE T.ProcessGUID = @ProcessGUID

		INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_DetailByEmployee
		(
		    ProcessGUID,
		    [Дата заведения заявки],
		    [Время заведения],
		    [Номер заявки],
		    [ФИО клиента],
		    [ФИО сотрудника верификации/чекер],
		    [Офис заведения заявки],
		    [Решение по заявке],
		    ПорядковыйНомерЗвонка,
		    ТипЗвонка,
		    РезультатЗвонка,
		    Дозвон,
		    ИтогоКонтактность,
			[Дата рассмотрения заявки]
		)
		SELECT DISTINCT
		    ProcessGUID = Request.ProcessGUID,
		    Request.[Дата заведения заявки],
		    Request.[Время заведения],
		    Request.[Номер заявки],
		    Request.[ФИО клиента],
		    [ФИО сотрудника верификации/чекер] = concat(Users.LastName, ' ', Users.FirstName, ' ', Users.MiddleName),
		    Request.[Офис заведения заявки],
		    Request.[Решение по заявке],
		    ПорядковыйНомерЗвонка = call_type.SortOrder,
		    ТипЗвонка = CheckListItemType.Name COLLATE Cyrillic_General_CI_AS,
		    РезультатЗвонка = CheckListItemStatus.Name COLLATE Cyrillic_General_CI_AS,
		    Дозвон = Contact_Call.isSuccess,
		    Request.ИтогоКонтактность,
			Request.[Дата рассмотрения заявки]
		FROM 
			(
				SELECT DISTINCT
					C.ProcessGUID,
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
					C.[Офис заведения заявки],
					C.[Решение по заявке],
					--C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
					--C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
					--C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
					--C.ЗвонокКонтактномуЛицу,
					C.ИтогоКонтактность,
					C.[Дата рассмотрения заявки]
				FROM (
					SELECT
						ProcessGUID = @ProcessGUID,
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
						 , R.[Офис заведения заявки]
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
						, ИтогоКонтактность = 
							isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
							isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
							isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
							isnull(R.ЗвонокКонтактномуЛицу, 0)
						, R.[Дата рассмотрения заявки]
					--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_Detail
					FROM #t_request_number AS N
						INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
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
					WHERE R.[Статус] in ('Верификация клиента')
						--AND R.[Дата статуса] > @dt_from 
						--AND R.[Дата статуса] < @dt_to
					--order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc
				) AS C
				WHERE C.[Решение по заявке] IN ('Отказано', 'Одобрено')
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
		--		'Звонок работодателю по телефонам из Контур Фокус',
		--		'Звонок работодателю по телефонам из Интернет',
		--		'Звонок работодателю по телефону из Анкеты',
		--		'Звонок контактному лицу'
		--		--'Звонок на мобильный телефон клиента'
		--	)
		--ORDER BY [Номер заявки] DESC, ПорядковыйНомерЗвонка

		INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
		SELECT getdate(), 'Contact.DetailByEmployee', @ProcessGUID

	END
	ELSE BEGIN
		SELECT DISTINCT
		    --ProcessGUID = Request.ProcessGUID,
		    Request.[Дата заведения заявки],
		    Request.[Время заведения],
		    Request.[Номер заявки],
		    Request.[ФИО клиента],
		    [ФИО сотрудника верификации/чекер] = concat(Users.LastName, ' ', Users.FirstName, ' ', Users.MiddleName),
		    Request.[Офис заведения заявки],
		    Request.[Решение по заявке],
		    ПорядковыйНомерЗвонка = call_type.SortOrder,
		    ТипЗвонка = CheckListItemType.Name,
		    РезультатЗвонка = CheckListItemStatus.Name,
		    Дозвон = Contact_Call.isSuccess,
		    Request.ИтогоКонтактность,
			Request.[Дата рассмотрения заявки]
		FROM 
			(
				SELECT DISTINCT
					C.ProcessGUID,
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
					C.[Офис заведения заявки],
					C.[Решение по заявке],
					--C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
					--C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
					--C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
					--C.ЗвонокКонтактномуЛицу,
					C.ИтогоКонтактность,
					C.[Дата рассмотрения заявки]
				FROM (
					SELECT
						ProcessGUID = @ProcessGUID,
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
						 , R.[Офис заведения заявки]
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
						, ИтогоКонтактность = 
							isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
							isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
							isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
							isnull(R.ЗвонокКонтактномуЛицу, 0)
						, R.[Дата рассмотрения заявки]
					--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_Detail
					FROM #t_request_number AS N
						INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
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
					WHERE R.[Статус] in ('Верификация клиента')
						--AND R.[Дата статуса] > @dt_from 
						--AND R.[Дата статуса] < @dt_to
					--order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc
				) AS C
				WHERE C.[Решение по заявке] IN ('Отказано', 'Одобрено')
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
		--		'Звонок работодателю по телефонам из Контур Фокус',
		--		'Звонок работодателю по телефонам из Интернет',
		--		'Звонок работодателю по телефону из Анкеты',
		--		'Звонок контактному лицу'
		--		--'Звонок на мобильный телефон клиента'
		--	)
		ORDER BY [Номер заявки] DESC, ПорядковыйНомерЗвонка

		RETURN 0
	END
END
--// 'Contact.DetailByEmployee'



DROP TABLE IF EXISTS #t_Contact_Month

CREATE TABLE #t_Contact_Month(
	[Дата статуса] date,
	[Контактность общая] nvarchar(50),
	[Контактность по одобренным] nvarchar(50),
	[Контактность по отказным] nvarchar(50)
)


IF @Page = 'V.Monthly.Common' OR @isFill_All_Tables = 1
BEGIN
	INSERT #t_Contact_Month
	(
		[Дата статуса],
		[Контактность общая],
		[Контактность по одобренным],
		[Контактность по отказным]
	)
	SELECT 
		B.[Дата статуса],
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
			A.[Дата статуса],
			КоличествоЗаявок = count(*),
			КоличествоДозвон = sum(A.Дозвон),

			КоличествоОдобрено = sum(iif(A.[Решение по заявке]='Одобрено',1,0)),
			КоличествоОдобреноДозвон = sum(iif(A.[Решение по заявке]='Одобрено',1,0) * A.Дозвон),

			КоличествоОтказано = sum(iif(A.[Решение по заявке]='Отказано',1,0)),
			КоличествоОтказаноДозвон = sum(iif(A.[Решение по заявке]='Отказано',1,0) * A.Дозвон)
		FROM (
			SELECT DISTINCT
				[Дата статуса] = cast(format(R.[Дата статуса],'yyyyMM01') as date),
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
						isnull(R.ЗвонокКонтактномуЛицу, 0) > 0,
						1, 0
					)
			FROM #t_request_number AS N
					INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
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
			WHERE R.[Статус] in ('Верификация клиента')
				--AND R.[Дата статуса] > @dt_from 
				--AND R.[Дата статуса] < @dt_to
		) AS A
		WHERE A.[Решение по заявке] IN ('Отказано', 'Одобрено')
		GROUP BY A.[Дата статуса]
	) AS B
END


DROP TABLE IF EXISTS #t_Contact_Day

CREATE TABLE #t_Contact_Day(
	[Дата статуса] date,
	[Контактность общая] nvarchar(50),
	[Контактность по одобренным] nvarchar(50),
	[Контактность по отказным] nvarchar(50)
)

IF @page= 'V.Daily.Common' OR @isFill_All_Tables = 1 
BEGIN
	INSERT #t_Contact_Day
	(
		[Дата статуса],
		[Контактность общая],
		[Контактность по одобренным],
		[Контактность по отказным]
	)
	SELECT 
		B.[Дата статуса],
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
			A.[Дата статуса],
			КоличествоЗаявок = count(*),
			КоличествоДозвон = sum(A.Дозвон),

			КоличествоОдобрено = sum(iif(A.[Решение по заявке]='Одобрено',1,0)),
			КоличествоОдобреноДозвон = sum(iif(A.[Решение по заявке]='Одобрено',1,0) * A.Дозвон),

			КоличествоОтказано = sum(iif(A.[Решение по заявке]='Отказано',1,0)),
			КоличествоОтказаноДозвон = sum(iif(A.[Решение по заявке]='Отказано',1,0) * A.Дозвон)
		FROM (
			SELECT DISTINCT
				[Дата статуса] = cast(R.[Дата статуса] as date),
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
						isnull(R.ЗвонокКонтактномуЛицу, 0) > 0,
						1, 0
					)
			FROM #t_request_number AS N
					INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
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
			WHERE R.[Статус] in ('Верификация клиента')
				--AND R.[Дата статуса] > @dt_from 
				--AND R.[Дата статуса] < @dt_to
		) AS A
		WHERE A.[Решение по заявке] IN ('Отказано', 'Одобрено')
		GROUP BY A.[Дата статуса]
	) AS B
END


DROP TABLE IF EXISTS #t_Contact_Employee_Month

CREATE TABLE #t_Contact_Employee_Month(
	[Дата] date,
	[Сотрудник] nvarchar(255),
	[УникальныхЗаявок] int,
	[Контактность] int
)

IF @Page = 'VK.Monthly.Contact' OR @isFill_All_Tables = 1
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
			[Дата] = A.[Дата рассмотрения заявки], --A.[Дата статуса],
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
			FROM tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_DetailByEmployee AS T
			WHERE T.ProcessGUID = @ProcessGUID
			GROUP BY
				--cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
				cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		GROUP BY 
			A.[Дата рассмотрения заявки], --A.[Дата статуса],
			A.[ФИО сотрудника верификации/чекер]
	END
	ELSE BEGIN
		INSERT #t_Contact_Employee_Month(
			[Дата],
			[Сотрудник],
			[УникальныхЗаявок],
			[Контактность]
		)
		SELECT 
			[Дата] = A.[Дата рассмотрения заявки], -- A.[Дата статуса],
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
					Request.[Дата рассмотрения заявки], --[Дата заведения заявки],
					Request.[Время заведения],
					Request.[Номер заявки],
					Request.[ФИО клиента],
					[ФИО сотрудника верификации/чекер] = concat(Users.LastName, ' ', Users.FirstName, ' ', Users.MiddleName),
					Request.[Офис заведения заявки],
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
							C.[Дата рассмотрения заявки], --[Дата заведения заявки],
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
							C.[Офис заведения заявки],
							C.[Решение по заявке],
							--C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
							--C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
							--C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
							--C.ЗвонокКонтактномуЛицу,
							C.ИтогоКонтактность	
						FROM (
							SELECT
								ProcessGUID = @ProcessGUID,
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
								 , R.[Офис заведения заявки]
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
								, ИтогоКонтактность = 
									isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
									isnull(R.ЗвонокКонтактномуЛицу, 0)
								, R.[Дата рассмотрения заявки]
							--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_Detail
							FROM #t_request_number AS N
								INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
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
							WHERE R.[Статус] in ('Верификация клиента')
								--AND R.[Дата статуса] > @dt_from 
								--AND R.[Дата статуса] < @dt_to
								AND R.[Дата рассмотрения заявки] > @dt_from 
								AND R.[Дата рассмотрения заявки] < @dt_to
							--order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc
						) AS C
						WHERE C.[Решение по заявке] IN ('Отказано', 'Одобрено')
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
			GROUP BY
				--cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
				cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		GROUP BY 
			A.[Дата рассмотрения заявки], -- A.[Дата статуса], 
			A.[ФИО сотрудника верификации/чекер]
	END
END
--//'VK.Monthly.Contact'


DROP TABLE IF EXISTS #t_Contact_Employee_Month_Approved

CREATE TABLE #t_Contact_Employee_Month_Approved(
	[Дата] date,
	[Сотрудник] nvarchar(255),
	[УникальныхЗаявок] int,
	[Контактность] int
)

IF @Page = 'VK.Monthly.Contact.Approved' OR @isFill_All_Tables = 1
BEGIN
	IF @isFill_All_Tables = 1
	BEGIN
		INSERT #t_Contact_Employee_Month_Approved(
			[Дата],
			[Сотрудник],
			[УникальныхЗаявок],
			[Контактность]
		)
		SELECT 
			[Дата] = A.[Дата рассмотрения заявки], --A.[Дата статуса],
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
			FROM tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_DetailByEmployee AS T
				--одобрено
				--! "Контактность по одобренным" !
				INNER JOIN #t_approved AS approved ON approved.[Номер заявки] = T.[Номер заявки]
			WHERE T.ProcessGUID = @ProcessGUID
			GROUP BY
				--cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
				cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		GROUP BY 
			A.[Дата рассмотрения заявки], --A.[Дата статуса],
			A.[ФИО сотрудника верификации/чекер]
	END
	ELSE BEGIN
		INSERT #t_Contact_Employee_Month_Approved(
			[Дата],
			[Сотрудник],
			[УникальныхЗаявок],
			[Контактность]
		)
		SELECT 
			[Дата] = A.[Дата рассмотрения заявки], -- A.[Дата статуса],
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
					Request.[Дата рассмотрения заявки], --[Дата заведения заявки],
					Request.[Время заведения],
					Request.[Номер заявки],
					Request.[ФИО клиента],
					[ФИО сотрудника верификации/чекер] = concat(Users.LastName, ' ', Users.FirstName, ' ', Users.MiddleName),
					Request.[Офис заведения заявки],
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
							C.[Дата рассмотрения заявки], --[Дата заведения заявки],
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
							C.[Офис заведения заявки],
							C.[Решение по заявке],
							--C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
							--C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
							--C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
							--C.ЗвонокКонтактномуЛицу,
							C.ИтогоКонтактность	
						FROM (
							SELECT
								ProcessGUID = @ProcessGUID,
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
								 , R.[Офис заведения заявки]
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
								, ИтогоКонтактность = 
									isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
									isnull(R.ЗвонокКонтактномуЛицу, 0)
								, R.[Дата рассмотрения заявки]
							--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_Detail
							FROM #t_request_number AS N
								INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
									ON R.[Номер заявки] = N.[Номер заявки]
								--одобрено
								--! "Контактность по одобренным" !
								INNER JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
								--отказано
								LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
								--анулировано
								LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
								--Отказ клиента
								LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
							--WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
							WHERE R.[Статус] in ('Верификация клиента')
								--AND R.[Дата статуса] > @dt_from 
								--AND R.[Дата статуса] < @dt_to
								AND R.[Дата рассмотрения заявки] > @dt_from 
								AND R.[Дата рассмотрения заявки] < @dt_to
							--order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc
						) AS C
						WHERE C.[Решение по заявке] IN ('Отказано', 'Одобрено')
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
			GROUP BY
				--cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
				cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		GROUP BY 
			A.[Дата рассмотрения заявки], -- A.[Дата статуса], 
			A.[ФИО сотрудника верификации/чекер]
	END
END
--//'VK.Monthly.Contact.Approved'



DROP TABLE IF EXISTS #t_Contact_Employee_Month_Denied

CREATE TABLE #t_Contact_Employee_Month_Denied(
	[Дата] date,
	[Сотрудник] nvarchar(255),
	[УникальныхЗаявок] int,
	[Контактность] int
)

IF @Page = 'VK.Monthly.Contact.Denied' OR @isFill_All_Tables = 1
BEGIN
	IF @isFill_All_Tables = 1
	BEGIN
		INSERT #t_Contact_Employee_Month_Denied(
			[Дата],
			[Сотрудник],
			[УникальныхЗаявок],
			[Контактность]
		)
		SELECT 
			[Дата] = A.[Дата рассмотрения заявки], --A.[Дата статуса],
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
			FROM tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_DetailByEmployee AS T
				--отказано
				--! "Контактность по отказным" !
				INNER JOIN #t_denied AS denied ON denied.[Номер заявки] = T.[Номер заявки]
			WHERE T.ProcessGUID = @ProcessGUID
			GROUP BY
				--cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
				cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		GROUP BY 
			A.[Дата рассмотрения заявки], --A.[Дата статуса],
			A.[ФИО сотрудника верификации/чекер]
	END
	ELSE BEGIN
		INSERT #t_Contact_Employee_Month_Denied(
			[Дата],
			[Сотрудник],
			[УникальныхЗаявок],
			[Контактность]
		)
		SELECT 
			[Дата] = A.[Дата рассмотрения заявки], -- A.[Дата статуса],
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
					Request.[Дата рассмотрения заявки], --[Дата заведения заявки],
					Request.[Время заведения],
					Request.[Номер заявки],
					Request.[ФИО клиента],
					[ФИО сотрудника верификации/чекер] = concat(Users.LastName, ' ', Users.FirstName, ' ', Users.MiddleName),
					Request.[Офис заведения заявки],
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
							C.[Дата рассмотрения заявки], --[Дата заведения заявки],
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
							C.[Офис заведения заявки],
							C.[Решение по заявке],
							--C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
							--C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
							--C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
							--C.ЗвонокКонтактномуЛицу,
							C.ИтогоКонтактность	
						FROM (
							SELECT
								ProcessGUID = @ProcessGUID,
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
								 , R.[Офис заведения заявки]
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
								, ИтогоКонтактность = 
									isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
									isnull(R.ЗвонокКонтактномуЛицу, 0)
								, R.[Дата рассмотрения заявки]
							--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_Detail
							FROM #t_request_number AS N
								INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
									ON R.[Номер заявки] = N.[Номер заявки]
								--одобрено
								LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
								--отказано
								--! "Контактность по отказным" !
								INNER JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
								--анулировано
								LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
								--Отказ клиента
								LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
							--WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
							WHERE R.[Статус] in ('Верификация клиента')
								--AND R.[Дата статуса] > @dt_from 
								--AND R.[Дата статуса] < @dt_to
								AND R.[Дата рассмотрения заявки] > @dt_from 
								AND R.[Дата рассмотрения заявки] < @dt_to
							--order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc
						) AS C
						WHERE C.[Решение по заявке] IN ('Отказано', 'Одобрено')
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
			GROUP BY
				--cast(format(T.[Дата заведения заявки], 'yyyyMM01') as date),
				cast(format(T.[Дата рассмотрения заявки], 'yyyyMM01') as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		GROUP BY 
			A.[Дата рассмотрения заявки], -- A.[Дата статуса], 
			A.[ФИО сотрудника верификации/чекер]
	END
END
--//'VK.Monthly.Contact.Denied'


DROP TABLE IF EXISTS #t_Contact_Employee_Day

CREATE TABLE #t_Contact_Employee_Day(
	[Дата] date,
	[Сотрудник] nvarchar(255),
	[УникальныхЗаявок] int,
	[Контактность] int
)

IF @Page = 'VK.Daily.Contact' OR @isFill_All_Tables = 1
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
			[Дата] = A.[Дата рассмотрения заявки], --A.[Дата статуса],
			[Сотрудник] = A.[ФИО сотрудника верификации/чекер],
			[УникальныхЗаявок] = count(*),
			[Контактность] = sum(A.Дозвон)
		FROM (
			SELECT 
				--[Дата статуса] = cast(T.[Дата заведения заявки] as date),
				[Дата рассмотрения заявки] = cast(T.[Дата рассмотрения заявки] as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки],
				Дозвон = CASE 
							WHEN sum(T.Дозвон) >= 1 then 1
							ELSE 0
						END
			FROM tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_DetailByEmployee AS T
			WHERE T.ProcessGUID = @ProcessGUID
			GROUP BY
				--cast(T.[Дата заведения заявки] as date),
				cast(T.[Дата рассмотрения заявки] as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		GROUP BY 
			A.[Дата рассмотрения заявки], --A.[Дата статуса]
			A.[ФИО сотрудника верификации/чекер]
	END
	ELSE BEGIN
		INSERT #t_Contact_Employee_Day(
			[Дата],
			[Сотрудник],
			[УникальныхЗаявок],
			[Контактность]
		)
		SELECT 
			[Дата] = A.[Дата рассмотрения заявки], -- A.[Дата статуса],
			[Сотрудник] = A.[ФИО сотрудника верификации/чекер],
			[УникальныхЗаявок] = count(*),
			[Контактность] = sum(A.Дозвон)
		FROM (
			SELECT 
				--[Дата статуса] = cast(T.[Дата заведения заявки] as date),
				[Дата рассмотрения заявки] = cast(T.[Дата рассмотрения заявки] as date),
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
					Request.[Дата рассмотрения заявки], --[Дата заведения заявки],
					Request.[Время заведения],
					Request.[Номер заявки],
					Request.[ФИО клиента],
					[ФИО сотрудника верификации/чекер] = concat(Users.LastName, ' ', Users.FirstName, ' ', Users.MiddleName),
					Request.[Офис заведения заявки],
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
							C.[Дата рассмотрения заявки], --[Дата заведения заявки],
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
							C.[Офис заведения заявки],
							C.[Решение по заявке],
							--C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
							--C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
							--C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
							--C.ЗвонокКонтактномуЛицу,
							C.ИтогоКонтактность	
						FROM (
							SELECT
								ProcessGUID = @ProcessGUID,
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
								 , R.[Офис заведения заявки]
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
								, ИтогоКонтактность = 
									isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
									isnull(R.ЗвонокКонтактномуЛицу, 0)
								, R.[Дата рассмотрения заявки]
							--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_Detail
							FROM #t_request_number AS N
								INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
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
							WHERE R.[Статус] in ('Верификация клиента')
								--AND R.[Дата статуса] > @dt_from 
								--AND R.[Дата статуса] < @dt_to
								AND R.[Дата рассмотрения заявки] > @dt_from 
								AND R.[Дата рассмотрения заявки] < @dt_to
							--order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc
						) AS C
						WHERE C.[Решение по заявке] IN ('Отказано', 'Одобрено')
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
			GROUP BY
				--cast(T.[Дата заведения заявки] as date),
				cast(T.[Дата рассмотрения заявки] as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		GROUP BY 
			A.[Дата рассмотрения заявки], -- A.[Дата статуса], 
			A.[ФИО сотрудника верификации/чекер]
	END
END
--//'VK.Daily.Contact' OR @isFill_All_Tables = 1
--// DWH-2067





DROP TABLE IF EXISTS #t_Contact_Employee_Day_Approved

CREATE TABLE #t_Contact_Employee_Day_Approved(
	[Дата] date,
	[Сотрудник] nvarchar(255),
	[УникальныхЗаявок] int,
	[Контактность] int
)

IF @Page = 'VK.Daily.Contact.Approved' OR @isFill_All_Tables = 1
BEGIN
	IF @isFill_All_Tables = 1
	BEGIN
		INSERT #t_Contact_Employee_Day_Approved(
			[Дата],
			[Сотрудник],
			[УникальныхЗаявок],
			[Контактность]
		)
		SELECT 
			[Дата] = A.[Дата рассмотрения заявки], --A.[Дата статуса],
			[Сотрудник] = A.[ФИО сотрудника верификации/чекер],
			[УникальныхЗаявок] = count(*),
			[Контактность] = sum(A.Дозвон)
		FROM (
			SELECT 
				--[Дата статуса] = cast(T.[Дата заведения заявки] as date),
				[Дата рассмотрения заявки] = cast(T.[Дата рассмотрения заявки] as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки],
				Дозвон = CASE 
							WHEN sum(T.Дозвон) >= 1 then 1
							ELSE 0
						END
			FROM tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_DetailByEmployee AS T
				--одобрено
				--! "Контактность по одобренным" !
				INNER JOIN #t_approved AS approved ON approved.[Номер заявки] = T.[Номер заявки]
			WHERE T.ProcessGUID = @ProcessGUID
			GROUP BY
				--cast(T.[Дата заведения заявки] as date),
				cast(T.[Дата рассмотрения заявки] as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		GROUP BY 
			A.[Дата рассмотрения заявки], --A.[Дата статуса]
			A.[ФИО сотрудника верификации/чекер]
	END
	ELSE BEGIN
		INSERT #t_Contact_Employee_Day_Approved(
			[Дата],
			[Сотрудник],
			[УникальныхЗаявок],
			[Контактность]
		)
		SELECT 
			[Дата] = A.[Дата рассмотрения заявки], -- A.[Дата статуса],
			[Сотрудник] = A.[ФИО сотрудника верификации/чекер],
			[УникальныхЗаявок] = count(*),
			[Контактность] = sum(A.Дозвон)
		FROM (
			SELECT 
				--[Дата статуса] = cast(T.[Дата заведения заявки] as date),
				[Дата рассмотрения заявки] = cast(T.[Дата рассмотрения заявки] as date),
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
					Request.[Дата рассмотрения заявки], --[Дата заведения заявки],
					Request.[Время заведения],
					Request.[Номер заявки],
					Request.[ФИО клиента],
					[ФИО сотрудника верификации/чекер] = concat(Users.LastName, ' ', Users.FirstName, ' ', Users.MiddleName),
					Request.[Офис заведения заявки],
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
							C.[Дата рассмотрения заявки], --[Дата заведения заявки],
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
							C.[Офис заведения заявки],
							C.[Решение по заявке],
							--C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
							--C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
							--C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
							--C.ЗвонокКонтактномуЛицу,
							C.ИтогоКонтактность	
						FROM (
							SELECT
								ProcessGUID = @ProcessGUID,
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
								 , R.[Офис заведения заявки]
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
								, ИтогоКонтактность = 
									isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
									isnull(R.ЗвонокКонтактномуЛицу, 0)
								, R.[Дата рассмотрения заявки]
							--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_Detail
							FROM #t_request_number AS N
								INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
									ON R.[Номер заявки] = N.[Номер заявки]
								--одобрено
								--! "Контактность по одобренным" !
								INNER JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
								--отказано
								LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
								--анулировано
								LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
								--Отказ клиента
								LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
							--WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
							WHERE R.[Статус] in ('Верификация клиента')
								--AND R.[Дата статуса] > @dt_from 
								--AND R.[Дата статуса] < @dt_to
								AND R.[Дата рассмотрения заявки] > @dt_from 
								AND R.[Дата рассмотрения заявки] < @dt_to
							--order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc
						) AS C
						WHERE C.[Решение по заявке] IN ('Отказано', 'Одобрено')
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
			GROUP BY
				--cast(T.[Дата заведения заявки] as date),
				cast(T.[Дата рассмотрения заявки] as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		GROUP BY 
			A.[Дата рассмотрения заявки], -- A.[Дата статуса], 
			A.[ФИО сотрудника верификации/чекер]
	END
END
--//'VK.Daily.Contact.Approved' OR @isFill_All_Tables = 1






DROP TABLE IF EXISTS #t_Contact_Employee_Day_Denied

CREATE TABLE #t_Contact_Employee_Day_Denied(
	[Дата] date,
	[Сотрудник] nvarchar(255),
	[УникальныхЗаявок] int,
	[Контактность] int
)

IF @Page = 'VK.Daily.Contact.Denied' OR @isFill_All_Tables = 1
BEGIN
	IF @isFill_All_Tables = 1
	BEGIN
		INSERT #t_Contact_Employee_Day_Denied(
			[Дата],
			[Сотрудник],
			[УникальныхЗаявок],
			[Контактность]
		)
		SELECT 
			[Дата] = A.[Дата рассмотрения заявки], --A.[Дата статуса],
			[Сотрудник] = A.[ФИО сотрудника верификации/чекер],
			[УникальныхЗаявок] = count(*),
			[Контактность] = sum(A.Дозвон)
		FROM (
			SELECT 
				--[Дата статуса] = cast(T.[Дата заведения заявки] as date),
				[Дата рассмотрения заявки] = cast(T.[Дата рассмотрения заявки] as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки],
				Дозвон = CASE 
							WHEN sum(T.Дозвон) >= 1 then 1
							ELSE 0
						END
			FROM tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_DetailByEmployee AS T
				--отказано
				--! "Контактность по отказным" !
				INNER JOIN #t_denied AS denied ON denied.[Номер заявки] = T.[Номер заявки]
			WHERE T.ProcessGUID = @ProcessGUID
			GROUP BY
				--cast(T.[Дата заведения заявки] as date),
				cast(T.[Дата рассмотрения заявки] as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		GROUP BY 
			A.[Дата рассмотрения заявки], --A.[Дата статуса]
			A.[ФИО сотрудника верификации/чекер]
	END
	ELSE BEGIN
		INSERT #t_Contact_Employee_Day_Denied(
			[Дата],
			[Сотрудник],
			[УникальныхЗаявок],
			[Контактность]
		)
		SELECT 
			[Дата] = A.[Дата рассмотрения заявки], -- A.[Дата статуса],
			[Сотрудник] = A.[ФИО сотрудника верификации/чекер],
			[УникальныхЗаявок] = count(*),
			[Контактность] = sum(A.Дозвон)
		FROM (
			SELECT 
				--[Дата статуса] = cast(T.[Дата заведения заявки] as date),
				[Дата рассмотрения заявки] = cast(T.[Дата рассмотрения заявки] as date),
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
					Request.[Дата рассмотрения заявки], --[Дата заведения заявки],
					Request.[Время заведения],
					Request.[Номер заявки],
					Request.[ФИО клиента],
					[ФИО сотрудника верификации/чекер] = concat(Users.LastName, ' ', Users.FirstName, ' ', Users.MiddleName),
					Request.[Офис заведения заявки],
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
							C.[Дата рассмотрения заявки], --[Дата заведения заявки],
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
							C.[Офис заведения заявки],
							C.[Решение по заявке],
							--C.ЗвонокРаботодателюПоТелефонамИзКонтурФокус,
							--C.ЗвонокРаботодателюПоТелефонамИзИнтернет,
							--C.ЗвонокРаботодателюПоТелефонуИзАнкеты,
							--C.ЗвонокКонтактномуЛицу,
							C.ИтогоКонтактность	
						FROM (
							SELECT
								ProcessGUID = @ProcessGUID,
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
								 , R.[Офис заведения заявки]
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
								, ИтогоКонтактность = 
									isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
									isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
									isnull(R.ЗвонокКонтактномуЛицу, 0)
								, R.[Дата рассмотрения заявки]
							--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_Contact_Detail
							FROM #t_request_number AS N
								INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
									ON R.[Номер заявки] = N.[Номер заявки]
								--одобрено
								LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
								--отказано
								--! "Контактность по отказным" !
								INNER JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
								--анулировано
								LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
								--Отказ клиента
								LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
							--WHERE R.[Статус] in ('Контроль данных' ,'Верификация клиента' ,'Верификация ТС')
							WHERE R.[Статус] in ('Верификация клиента')
								--AND R.[Дата статуса] > @dt_from 
								--AND R.[Дата статуса] < @dt_to
								AND R.[Дата рассмотрения заявки] > @dt_from 
								AND R.[Дата рассмотрения заявки] < @dt_to
							--order by R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc
						) AS C
						WHERE C.[Решение по заявке] IN ('Отказано', 'Одобрено')
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
			GROUP BY
				--cast(T.[Дата заведения заявки] as date),
				cast(T.[Дата рассмотрения заявки] as date),
				T.[ФИО сотрудника верификации/чекер],
				T.[Номер заявки]
		) AS A
		WHERE 1=1
		GROUP BY 
			A.[Дата рассмотрения заявки], -- A.[Дата статуса], 
			A.[ФИО сотрудника верификации/чекер]
	END
END
--//'VK.Daily.Contact.Denied' OR @isFill_All_Tables = 1





IF @Page = 'VK.DetailHours' OR @isFill_All_Tables = 1 --241
BEGIN
	IF @isFill_All_Tables = 1
	BEGIN
		--Датасет не используется
		/*
		--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_DetailHours
		DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_DetailHours AS T WHERE T.ProcessGUID = @ProcessGUID

		INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_DetailHours
		SELECT
			ProcessGUID = @ProcessGUID,
			fv.[Дата заведения заявки]
				, fv.[Время заведения]
				, fv.[Номер заявки]
				, fv.[ФИО клиента]
				, fv.[Статус]
				, fv.[Задача]
				, fv.[Состояние заявки]
				, fv.[Дата статуса]
				-- 20210326
				, [ФИО сотрудника верификации/чекер] = fv.Работник
				, fv.[ВремяЗатрачено]
			, fv.[Время, час:мин:сек]
				, fv.[Статус следующий]
				, fv.[Задача следующая]
				, fv.[Состояние заявки следующая]
				, fv.Назначен
				, hourInterval 'Интервал'
				, beginInterval 'Начало интервала'
				, endInterval 'Конец интервала'
				, cast(endInterval as decimal(15,10)) -  cast(beginInterval as decimal(15,10))  ЗатраченоВИнтервале
				--, hr.flagBeginInterval
				--, hr.rn ШагЧасаСтатуса
				, ШагЧасаСтатуса = row_number() over(partition by fv.[Номер заявки], fv.ШагЗаявки order by endInterval )
				, КоличествоЗаявокВЧасе = count(fv.[Номер заявки]) over(partition by hourInterval)
		--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_DetailHours
		from #t_dm_FedorVerificationRequests_AutocredVTB fv--#details
		cross apply dwh2.[dbo].[times_from_interval_hours] ([Дата статуса], [Дата след.статуса],60) hr 
		where [Статус] in ('Верификация клиента')
		--and fv.[Номер заявки] = '21040100093442'
		and fv.[Дата статуса]>@dt_from and  fv.[Дата статуса]<@dt_to
		and beginInterval is not null
		--order by Работник asc ,[Дата заведения заявки] desc ,[Время заведения] desc
		*/
		INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
		SELECT getdate(), 'VK.DetailHours', @ProcessGUID
	END
	ELSE BEGIN
 select --top 100
  fv.[Дата заведения заявки]
	     , fv.[Время заведения]
	     , fv.[Номер заявки]
	     , fv.[ФИО клиента]
	     , fv.[Статус]
	     , fv.[Задача]
	     , fv.[Состояние заявки]
	     , fv.[Дата статуса]
	      -- 20210326
	     , [ФИО сотрудника верификации/чекер] = fv.Работник
	     , fv.[ВремяЗатрачено]
       , fv.[Время, час:мин:сек]
	     , fv.[Статус следующий]
	     , fv.[Задача следующая]
	     , fv.[Состояние заявки следующая]
		 , fv.Назначен
		 , hourInterval 'Интервал'
		 , beginInterval 'Начало интервала'
		 , endInterval 'Конец интервала'
		 , cast(endInterval as decimal(15,10)) -  cast(beginInterval as decimal(15,10))  ЗатраченоВИнтервале
		 --, hr.flagBeginInterval
		 --, hr.rn ШагЧасаСтатуса
		 , ШагЧасаСтатуса = row_number() over(partition by fv.[Номер заявки], fv.ШагЗаявки order by endInterval )
		 , КоличествоЗаявокВЧасе = count(fv.[Номер заявки]) over(partition by hourInterval)
		 
		from #t_dm_FedorVerificationRequests_AutocredVTB fv--#details
	cross apply dwh2.[dbo].[times_from_interval_hours] ([Дата статуса], [Дата след.статуса],60) hr 
   where [Статус] in ('Верификация клиента')
   --and fv.[Номер заявки] = '21040100093442'
   --and fv.[Дата статуса]>@dt_from and  fv.[Дата статуса]<@dt_to
   and beginInterval is not null
   --order by Работник asc ,[Дата заведения заявки] desc ,[Время заведения] desc

		RETURN 0
	END
END


--- Лист "ВТС. Детализация"
IF @Page = 'VTC.Detail' OR @isFill_All_Tables = 1 --361
BEGIN

	--IF @isFill_All_Tables <> 1
	--BEGIN
		DELETE #t_request_number
		DELETE #t_approved
		DELETE #t_denied
		DELETE #t_canceled
		DELETE #t_customer_rejection
		DELETE #t_checklists_rejects

		--request numbers
		INSERT #t_request_number(R.IdClientRequest, [Номер заявки])
		SELECT DISTINCT R.IdClientRequest, R.[Номер заявки]
		FROM #t_dm_FedorVerificationRequests_AutocredVTB AS R
		WHERE R.[Статус] in ('Верификация ТС')
		--AND R.[Дата статуса] > @dt_from
		--AND R.[Дата статуса] < @dt_to

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

		--одобрено
		INSERT #t_approved([Номер заявки],[Дата статуса])
		SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
			ON R.[Номер заявки] = N.[Номер заявки]
		WHERE 1=1
		--AND R.[Дата статуса] > @dt_from
		--AND R.[Дата статуса] < @dt_to
		AND (
			R.Статус IN ('Верификация ТС','Верификация Call 4') AND R.[Статус следующий] IN ('Одобрено')
		)
		GROUP BY R.[Номер заявки]

		--2 одобрено сотрудником, но отказано автоматически
		INSERT #t_approved([Номер заявки],[Дата статуса])
		SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
			ON R.[Номер заявки] = N.[Номер заявки]
		WHERE 1=1
			--AND R.[Дата статуса] > @dt_from
			--AND R.[Дата статуса] < @dt_to
			AND R.Статус IN ('Верификация ТС','Верификация Call 4')
			AND R.[Статус следующий] IN ('Отказано')
			AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
		GROUP BY R.[Номер заявки]

		--отказано сотрудником
		INSERT #t_denied([Номер заявки],[Дата статуса])
		SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
			ON R.[Номер заявки] = N.[Номер заявки]
		WHERE 1=1
			--AND R.[Дата статуса] > @dt_from
			--AND R.[Дата статуса] < @dt_to
			AND R.Статус IN ('Верификация ТС','Верификация Call 4')
			AND R.[Статус следующий] IN ('Отказано')
			AND EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
		GROUP BY R.[Номер заявки]

		--анулировано
		INSERT #t_canceled([Номер заявки],[Дата статуса], isAuto, isPostpone)
		SELECT 
			R.[Номер заявки], 
			[Дата статуса] = min(R.[Дата статуса]),
			isAuto = 
				CASE 
					WHEN R.[ФИО сотрудника верификации/чекер] LIKE '%Системный%' THEN 1
					ELSE 0
				END,
			isPostpone = 
				CASE 
					WHEN V.[Номер заявки] IS NOT NULL THEN 1
					ELSE 0
				END
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
				ON R.[Номер заявки] = N.[Номер заявки]
			LEFT JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS V
				ON V.[Номер заявки] = R.[Номер заявки]
				AND V.ШагЗаявки = R.ШагЗаявки - 2
				AND V.Задача='task:Отложена' 
				AND V.[Состояние заявки] IN ('Отложена')
				AND V.Статус in('Верификация ТС')
		WHERE 1=1
		--AND R.[Дата статуса] > @dt_from
		--AND R.[Дата статуса] < @dt_to
		AND R.Статус IN ('Верификация ТС','Верификация Call 4')
		AND R.[Статус следующий] IN ('Аннулировано')
		GROUP BY R.[Номер заявки], R.[ФИО сотрудника верификации/чекер], V.[Номер заявки]

		--Отказ клиента
		INSERT #t_customer_rejection([Номер заявки],[Дата статуса])
		SELECT R.[Номер заявки], [Дата статуса] = min(R.[Дата статуса])
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
			ON R.[Номер заявки] = N.[Номер заявки]
		WHERE 1=1
		--AND R.[Дата статуса] > @dt_from
		--AND R.[Дата статуса] < @dt_to
		AND R.Статус IN ('Верификация Call 1.5')
		AND R.[Статус следующий] IN ('Отказ клиента')
		GROUP BY R.[Номер заявки]
	--END
	--// @isFill_All_Tables <> 1

	IF @isFill_All_Tables = 1
	BEGIN
		--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VTC_Detail
		DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VTC_Detail AS T WHERE T.ProcessGUID = @ProcessGUID

		INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VTC_Detail
		SELECT
			ProcessGUID = @ProcessGUID,
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
			 , R.[Офис заведения заявки]
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
				WHEN canceled.[Номер заявки] IS NOT NULL 
					THEN concat(
						'Аннулировано',
						CASE 
							WHEN canceled.isAuto = 1 THEN '  автоматически'
							ELSE ' вручную'
						END
						)
				WHEN denied.[Номер заявки] IS NOT NULL THEN 'Отказано'
				WHEN approved.[Номер заявки] IS NOT NULL THEN 'Одобрено'
				WHEN customer_rejection.[Номер заявки] IS NOT NULL THEN 'Отказ клиента'
				ELSE ''
			END,
			R.ТипКлиента,
			R.[Дата рассмотрения заявки],
			Комментарий = 
			CASE 
				WHEN canceled.isAuto = 1 AND canceled.isPostpone = 1 THEN 'Не вернулась из отложенных'
				ELSE NULL
			END,
			R.Партнер
		--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VTC_Detail
		FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
				ON R.[Номер заявки] = N.[Номер заявки]
			--одобрено
			LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
			--отказано
			LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
			--анулировано
			LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
			--Отказ клиента
			LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
		WHERE R.[Статус] in ('Верификация ТС')
			--AND R.[Дата статуса] > @dt_from 
			--AND R.[Дата статуса] < @dt_to
		ORDER BY R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc

		INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
		SELECT getdate(), 'VTC.Detail', @ProcessGUID
	END
	ELSE BEGIN
	SELECT R.[Дата заведения заявки]
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
		 , R.[Офис заведения заявки]
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
			WHEN canceled.[Номер заявки] IS NOT NULL 
				THEN concat(
					'Аннулировано',
					CASE 
						WHEN canceled.isAuto = 1 THEN '  автоматически'
						ELSE ' вручную'
					END
					)
			WHEN denied.[Номер заявки] IS NOT NULL THEN 'Отказано'
			WHEN approved.[Номер заявки] IS NOT NULL THEN 'Одобрено'
			WHEN customer_rejection.[Номер заявки] IS NOT NULL THEN 'Отказ клиента'
			ELSE ''
		END,
		R.ТипКлиента,
		R.[Дата рассмотрения заявки],
		Комментарий = 
		CASE 
			WHEN canceled.isAuto = 1 AND canceled.isPostpone = 1 THEN 'Не вернулась из отложенных'
			ELSE NULL
		END,
		R.Партнер
	FROM #t_request_number AS N
			INNER JOIN #t_dm_FedorVerificationRequests_AutocredVTB AS R
			ON R.[Номер заявки] = N.[Номер заявки]
		--одобрено
		LEFT JOIN #t_approved AS approved ON approved.[Номер заявки] = R.[Номер заявки]
		--отказано
		LEFT JOIN #t_denied AS denied ON denied.[Номер заявки] = R.[Номер заявки]
		--анулировано
		LEFT JOIN #t_canceled AS canceled ON canceled.[Номер заявки] = R.[Номер заявки]
		--Отказ клиента
		LEFT JOIN #t_customer_rejection AS customer_rejection ON customer_rejection.[Номер заявки] = R.[Номер заявки]
	WHERE R.[Статус] in ('Верификация ТС')
		--AND R.[Дата статуса] > @dt_from 
		--AND R.[Дата статуса] < @dt_to
	ORDER BY R.Работник, R.[Дата статуса] desc, R.[Номер заявки] desc

		RETURN 0
  END
END
-- 'VTC.Detail'

IF @Page = 'VTC.DetailHours' OR @isFill_All_Tables = 1 --241
BEGIN
	IF @isFill_All_Tables = 1
	BEGIN
		--Датасет не используется
		/*
		--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VTC_DetailHours
		DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VTC_DetailHours AS T WHERE T.ProcessGUID = @ProcessGUID

		INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VTC_DetailHours
		SELECT
			ProcessGUID = @ProcessGUID,
			fv.[Дата заведения заявки]
				, fv.[Время заведения]
				, fv.[Номер заявки]
				, fv.[ФИО клиента]
				, fv.[Статус]
				, fv.[Задача]
				, fv.[Состояние заявки]
				, fv.[Дата статуса]
				-- 20210326
				, [ФИО сотрудника верификации/чекер] = fv.Работник
				, fv.[ВремяЗатрачено]
			, fv.[Время, час:мин:сек]
				, fv.[Статус следующий]
				, fv.[Задача следующая]
				, fv.[Состояние заявки следующая]
				, fv.Назначен
				, hourInterval 'Интервал'
				, beginInterval 'Начало интервала'
				, endInterval 'Конец интервала'
				, cast(endInterval as decimal(15,10)) -  cast(beginInterval as decimal(15,10))  ЗатраченоВИнтервале
				--, hr.flagBeginInterval
				--, hr.rn ШагЧасаСтатуса
				, ШагЧасаСтатуса = row_number() over(partition by fv.[Номер заявки], fv.ШагЗаявки order by endInterval )
				, КоличествоЗаявокВЧасе = count(fv.[Номер заявки]) over(partition by hourInterval)
		--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VTC_DetailHours
		from #t_dm_FedorVerificationRequests_AutocredVTB fv--#details
		cross apply dwh2.[dbo].[times_from_interval_hours] ([Дата статуса], [Дата след.статуса],60) hr 
		--full outer join [dwh2].[cubes].[dm_FedorVerificationRequests_DayInterval_By_Hours] hr on fv.[Номер заявки] = hr.[Номер заявки] and fv.ШагЗаявки = hr.ШагЗаявки
		where [Статус] in ('Верификация ТС')
		--and fv.[Номер заявки] = '21040100093519'
		and fv.[Дата статуса]>@dt_from and  fv.[Дата статуса]<@dt_to
		and beginInterval is not null
		--order by Работник asc ,[Дата заведения заявки] desc ,[Время заведения] desc
		*/
		INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
		SELECT getdate(), 'VTC.DetailHours', @ProcessGUID
	END
	ELSE BEGIN
  select --top 100
  fv.[Дата заведения заявки]
	     , fv.[Время заведения]
	     , fv.[Номер заявки]
	     , fv.[ФИО клиента]
	     , fv.[Статус]
	     , fv.[Задача]
	     , fv.[Состояние заявки]
	     , fv.[Дата статуса]
	      -- 20210326
	     , [ФИО сотрудника верификации/чекер] = fv.Работник
	     , fv.[ВремяЗатрачено]
       , fv.[Время, час:мин:сек]
	     , fv.[Статус следующий]
	     , fv.[Задача следующая]
	     , fv.[Состояние заявки следующая]
		 , fv.Назначен
		 , hourInterval 'Интервал'
		 , beginInterval 'Начало интервала'
		 , endInterval 'Конец интервала'
		 , cast(endInterval as decimal(15,10)) -  cast(beginInterval as decimal(15,10))  ЗатраченоВИнтервале
		 --, hr.flagBeginInterval
		 --, hr.rn ШагЧасаСтатуса
		 , ШагЧасаСтатуса = row_number() over(partition by fv.[Номер заявки], fv.ШагЗаявки order by endInterval )
		 , КоличествоЗаявокВЧасе = count(fv.[Номер заявки]) over(partition by hourInterval)
		from #t_dm_FedorVerificationRequests_AutocredVTB fv--#details
	cross apply dwh2.[dbo].[times_from_interval_hours] ([Дата статуса], [Дата след.статуса],60) hr 
	--full outer join [dwh2].[cubes].[dm_FedorVerificationRequests_DayInterval_By_Hours] hr on fv.[Номер заявки] = hr.[Номер заявки] and fv.ШагЗаявки = hr.ШагЗаявки
   where [Статус] in ('Верификация ТС')
   --and fv.[Номер заявки] = '21040100093519'
   --and fv.[Дата статуса]>@dt_from and  fv.[Дата статуса]<@dt_to
   and beginInterval is not null
   --order by Работник asc ,[Дата заведения заявки] desc ,[Время заведения] desc

		RETURN 0
	END
END
--// 'VTC.DetailHours'



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
               , (7             ,'TTY  - % заявок рассмотренных в течение 6 минут на этапе')
               , (8             ,'TTY  - % заявок рассмотренных в течение 21 минут на этапе')
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
               , (29            ,'Уникальное количество доработок на этапе')
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
            from (select distinct Работник Employee from #t_dm_FedorVerificationRequests_AutocredVTB) e
        
        
        
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
 if @page in (
 'KD.Daily.Total'
 ,'KD.Daily.Unic'
 ,'KD.Daily.AvgTime'
 ,'KD.Daily.Approved'
 ,'KD.Daily.Postpone'
 ,'KD.Daily.PostponeUnique'
 ,'KD.Daily.Rework'
 ,'KD.Daily.AR'
 
 ,'ReportByEmployee'
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
  ,'V.Daily.Common'
  ,'V.Monthly.Common'
) OR @isFill_All_Tables = 1
 begin

        drop table if exists #fedor_verificator_report
        
        drop table if exists #details_KD
        
        select * 
          into #details_KD 
          from #t_dm_FedorVerificationRequests_AutocredVTB  --where [Номер заявки]='20092400036174'
         where 1=1
			AND (Работник not in (select * from #curr_employee_vr) 
				OR Работник IN (select Employee from #curr_employee_cd) --DWH-1620. 2022-04-06
				)
			--AND Работник IN (select Employee from #curr_employee_cd) --DWH-1988
           --and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
         
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
			   , Сотрудник=Работник_Пред --Работник_След --2023-11-20
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
            from #details_KD AS R
           where  (R.Статус IN ('Верификация Call 1.5') 
					AND R.[Статус следующий] IN ('Ожидание подписи документов EDO', 'Переподписание первого пакета', 'Верификация Call 2'))
				--DWH-2429 --одобрено сотрудником, но отказано автоматически
				OR (
					R.[Статус следующий]='Отказано' and R.Статус in('Верификация Call 1.5')
					AND NOT EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = R.IdClientRequest)
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
			--DWH-2020
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
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
				,ТипКлиента
            from #details_KD
             where Задача='task:В работе'  and Статус in('Контроль данных')
        
        
        --select * from  #fedor_verificator_report where дата='20200922' and status like 'до%'
		CREATE NONCLUSTERED INDEX ix_ДатаИВремяСтатуса
		ON #fedor_verificator_report([ДатаИВремяСтатуса])
		INCLUDE ([status],[Дата],[Номер заявки],[Сотрудник])

		CREATE NONCLUSTERED INDEX ix_Дата_Сотрудник
		ON #fedor_verificator_report(Дата, Сотрудник)
		INCLUDE ([status],[ФИО сотрудника верификации/чекер],[Номер заявки])

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##fedor_verificator_report
			SELECT * INTO ##fedor_verificator_report FROM #fedor_verificator_report
		END



        drop table if exists #ReportByEmployeeAgg
        ;
        with c1 as (
          select Дата
               , Сотрудник
               , isnull(sum(case when status in ('Новая_Уникальная') then 1 else 0 end),0) Новая_Уникальная --DWH-2020

				--DWH-2286
               , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Первичный' then 1 else 0 end),0) [Новая_Уникальная Первичный]
               , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Повторный' then 1 else 0 end),0) [Новая_Уникальная Повторный]
               , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Докредитование' then 1 else 0 end),0) [Новая_Уникальная Докредитование]
               , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Параллельный' then 1 else 0 end),0) [Новая_Уникальная Параллельный]
               , isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента IS NULL then 1 else 0 end),0) [Новая_Уникальная Не определен]

               , isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
               , isnull(sum(case when status in ('ВК','Отказано') then 1 else 0 end),0) ИтогоПоСотруднику
               , isnull(sum(case when status='ВК' then 1 else 0 end),0) [ВК]
               , isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]
               , isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]
               , isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
               , isnull(count( distinct case when status='Отложена' then  [Номер заявки] end),0) [Отложено уникальных]
               , isnull(count( distinct case when status='Доработка' then [Номер заявки] end ),0) [Доработка уникальных]
            from #fedor_verificator_report
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
           group by  [ФИО сотрудника верификации/чекер],дата
        )
          select c1.*
               , isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
               , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
               , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
            into #ReportByEmployeeAgg
            from c1 
            left join c2 on c1.Дата=c2.Дата and c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]


		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##ReportByEmployeeAgg
			SELECT * INTO ##ReportByEmployeeAgg FROM #ReportByEmployeeAgg
		END

			--для последнего часа
        drop table if exists #ReportByEmployeeAgg_LastHour
        ;
        with c1 as (
          select Дата
               , Сотрудник
               , isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
               , isnull(sum(case when status in ('ВК','Отказано') then 1 else 0 end),0) ИтогоПоСотруднику
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
        
 -- аггрегация за месяц       
 drop table if exists #ReportByEmployeeAgg_m

        ;
        with c1 as (
          select format(Дата,'yyyyMM01') Дата
               , Сотрудник
               , isnull(sum(case when status in ('ВК','Отказано') then 1 else 0 end),0) ИтогоПоСотруднику
               , isnull(sum(case when status='ВК' then 1 else 0 end),0) [ВК]
               , isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]
               , isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]
               , isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
               , isnull(count( distinct case when status='Отложена' then  [Номер заявки] end),0) [Отложено уникальных]
               , isnull(count( distinct case when status='Доработка' then [Номер заявки] end ),0) [Доработка уникальных]
            from #fedor_verificator_report
           group by format(Дата,'yyyyMM01')
               , Сотрудник
        )
        ,c2 as (
           
           select [ФИО сотрудника верификации/чекер]
                , format(Дата,'yyyyMM01') дата
                , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
                , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
                , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
           from  #fedor_verificator_report
           group by  [ФИО сотрудника верификации/чекер],format(Дата,'yyyyMM01')
        )
          select c1.*
               , isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
               , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
               , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
            into #ReportByEmployeeAgg_m
            from c1 
            left join c2 on c1.Дата=c2.Дата and c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]
        
        --select * from #ReportByEmployeeAgg_m
                
        --select * from #fedor_verificator_report
      
	  
	    if @Page = 'fedor_verificator_report'
        begin
			select 'KD' stage, stage_status='All',*,[Время, час:мин:сек] = '2000-01-01 00:22:35.000'   from #fedor_verificator_report

			RETURN 0
        end

        if @Page = 'ReportByEmployee' OR @isFill_All_Tables = 1
        begin
			IF @isFill_All_Tables = 1
			BEGIN
				--Датасет не используется
				/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_ReportByEmployee
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_ReportByEmployee AS T WHERE T.ProcessGUID = @ProcessGUID
        
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_ReportByEmployee
				select 
					ProcessGUID = @ProcessGUID,
					Дата
					, Сотрудник
					, ДатаИВремяСтатуса
					, [ФИО клиента]
					, [Номер заявки]
					, status 
					-- into devdb.dbo.ReportByEmployee_KD
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_ReportByEmployee
				from #fedor_verificator_report
				where  status <>'task:В работе'
				order by Дата, Сотрудник,ДатаИВремяСтатуса, [Номер заявки]
				*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'ReportByEmployee', @ProcessGUID
			END
			ELSE BEGIN
         select Дата
               , Сотрудник
               , ДатаИВремяСтатуса
               , [ФИО клиента]
               , [Номер заявки]
               , status 
			  -- into devdb.dbo.ReportByEmployee_KD
            from #fedor_verificator_report
            where  status <>'task:В работе'
           order by Дата, Сотрудник,ДатаИВремяСтатуса, [Номер заявки]

				RETURN 0
			END
        end
       --// 'ReportByEmployee'
        
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
      

	  --#ReportByEmployeeAgg_LastHour

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
        
        
        
        
        --
        -- Аггрегированные данные
        --
          
        
        --select * from #employee_rows_d
        
        
-- подневная аггрегация        
         drop table if exists    #KDEmployees
         ;
         
          select distinct acc_period 
               , empl_id 
               , Employee 
               , [Status] 
            into #KDEmployees
            from #employee_rows_d 
           where [Status] in ('Контроль данных') 
             and Employee in (select * from #curr_employee_cd)


--помесячная аггрегация             
         drop table if exists    #KDEmployees_m
         ;
         
          select distinct acc_period 
               , empl_id 
               , Employee 
               , [Status] 
            into #KDEmployees_m
            from #employee_rows_m
           where [Status] in ('Контроль данных') 
             and Employee in (select * from #curr_employee_cd)
        
        --- КД. Общее кол-во по дням 
        
		IF @Page = 'KD.Daily.Total' OR @isFill_All_Tables = 1 --19
        BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Total
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Total AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на этапе' Indicator
						, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Total
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
						, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Total
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.Total', @ProcessGUID
			END
			ELSE BEGIN
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
        union all
          select empl_id    = isnull((select max(empl_id) from #KDEmployees  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator
        		   , isnull(sum(КоличествоЗаявок ),0)
           from agg
          group by dt , indicator 

				RETURN 0
			END
          end
        --// 'KD.Daily.Total'
        
		IF @Page = 'KD.Monthly.Total' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Total
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Total AS T WHERE T.ProcessGUID = @ProcessGUID
        
        
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
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Total
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Total
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

				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.Total', @ProcessGUID
			END
			ELSE BEGIN
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

				RETURN 0
			END
          end
         --// 'KD.Monthly.Total'         
        
        
        --Уникальное кол-во заявок на этапе
		IF @Page = 'KD.Daily.Unic' OR @isFill_All_Tables = 1 --2403
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Unic
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Unic AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во заявок на этапе' Indicator
						, isnull(ИтогоПоСотруднику ,0) ИтогоПоСотруднику 
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Unic
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(ИтогоПоСотруднику,0) Сумма
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Unic
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.Unic', @ProcessGUID
			END
			ELSE BEGIN
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

				RETURN 0
          end
		END
		--// 'KD.Daily.Unic'

-- monthly        
		IF @Page = 'KD.Monthly.Unic' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Unic
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Unic AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во заявок на этапе' Indicator
						, isnull(ИтогоПоСотруднику ,0) ИтогоПоСотруднику 
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Unic
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(ИтогоПоСотруднику,0) Сумма
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Unic
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(ИтогоПоСотруднику ),0)
				from agg
				group by dt, indicator  
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.Unic', @ProcessGUID
			END
			ELSE BEGIN
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

				RETURN 0
          end
		END
		--// 'KD.Monthly.Unic'        
                
        
		IF @Page = 'KD.Daily.AvgTime' OR @isFill_All_Tables = 1 --2403
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_AvgTime
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_AvgTime AS T WHERE T.ProcessGUID = @ProcessGUID
          
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
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_AvgTime
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					,  Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_AvgTime
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.AvgTime', @ProcessGUID
			END
			ELSE BEGIN
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

				RETURN 0
          end
		END
		--// 'KD.Daily.AvgTime'

-- monthly
		IF @Page = 'KD.Monthly.AvgTime' OR @isFill_All_Tables = 1 --2403
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_AvgTime
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_AvgTime AS T WHERE T.ProcessGUID = @ProcessGUID

        
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
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_AvgTime
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					,  Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_AvgTime
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #KDEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, CASE WHEN sum(КоличествоЗаявок) <> 0
						THEN isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0)
						ELSE '0'
					  END
				from agg
				group by dt , indicator 
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.AvgTime', @ProcessGUID
			END
			ELSE BEGIN
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
						THEN isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0)
						ELSE '0'
					  END
           from agg
          group by dt , indicator 

				RETURN 0
			END
          end        
        --// 'KD.Monthly.AvgTime'
        
		IF @Page = 'KD.Daily.Approved' OR @isFill_All_Tables = 1 --21
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Approved
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Approved AS T WHERE T.ProcessGUID = @ProcessGUID
           
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Кол-во одобренных заявок после этапа' Indicator
						, [ВК]  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Approved
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Approved
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.Approved', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Кол-во одобренных заявок после этапа' Indicator
        		   , [ВК]  Сумма
            from #KDEmployees e
           left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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
        
				RETURN 0
        end
		END
		--// 'KD.Daily.Approved'

--Monthly
		IF @Page = 'KD.Monthly.Approved' OR @isFill_All_Tables = 1 --21
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Approved
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Approved AS T WHERE T.ProcessGUID = @ProcessGUID

        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Кол-во одобренных заявок после этапа' Indicator
						, [ВК]  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Approved
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Approved
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.Approved', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Кол-во одобренных заявок после этапа' Indicator
        		   , [ВК]  Сумма
            from #KDEmployees_m e
           left join #ReportByEmployeeAgg_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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
        
				RETURN 0
        end
		END
		--// 'KD.Monthly.Approved'
        
          -- 'Общее кол-во отложенных заявок на этапе'
		IF @Page = 'KD.Daily.Postpone' OR @isFill_All_Tables = 1 --2401
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Postpone
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Postpone AS T WHERE T.ProcessGUID = @ProcessGUID
        
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Postpone
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Postpone
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.Postpone', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во отложенных заявок на этапе' Indicator
        		   , Отложена  Сумма
            from #KDEmployees e
           left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
			END
        end
		--// 'KD.Daily.Postpone'


		 -- 'Уникальное кол-во отложенных заявок на этапе'
		IF @Page = 'KD.Daily.PostponeUnique' OR @isFill_All_Tables = 1 --2401
          begin
        
			DROP table if exists #fedor_verificator_report_KD_Unique

		   select Дата
               , Сотрудник              
               , isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальные]
            into #fedor_verificator_report_KD_Unique
            from #fedor_verificator_report
           group by Дата, Сотрудник


			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_PostponeUnique
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_PostponeUnique AS T WHERE T.ProcessGUID = @ProcessGUID

				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во отложенных заявок на этапе' Indicator
						, [ОтложенаУникальные]  Сумма
				from #KDEmployees e
				left join #fedor_verificator_report_KD_Unique a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_PostponeUnique
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_PostponeUnique
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

				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.PostponeUnique', @ProcessGUID
			END
			ELSE BEGIN
          ;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Уникальное кол-во отложенных заявок на этапе' Indicator
        		   , [ОтложенаУникальные]  Сумма
            from #KDEmployees e
           left join #fedor_verificator_report_KD_Unique a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
			END
        end
		--// 'KD.Daily.PostponeUnique'

 --monthly       
		IF @Page = 'KD.Monthly.Postpone' OR @isFill_All_Tables = 1 --2401
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Postpone
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Postpone AS T WHERE T.ProcessGUID = @ProcessGUID
        
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Postpone
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Postpone
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

				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.Postpone', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во отложенных заявок на этапе' Indicator
        		   , Отложена  Сумма
            from #KDEmployees_m e
           left join #ReportByEmployeeAgg_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
			END
        end       
		--// 'KD.Monthly.Postpone'
		
		--Monthly Unique
		IF @Page = 'KD.Monthly.PostponeUnique' OR @isFill_All_Tables = 1 --2401
          begin

		       drop table if exists #ReportByEmployeeAgg_KD_m_Unique
        ;
        with c1 as (
          select cast(format(Дата,'yyyyMM01') as date) Дата
               , Сотрудник             
               , isnull(count( distinct case when status='Отложена' then [Номер заявки]  end),0) [Отложена]               
            from #fedor_verificator_report
           group by cast(format(Дата,'yyyyMM01') as date)
               , Сотрудник
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
            into #ReportByEmployeeAgg_KD_m_Unique
            from c1 
            --left join c2 on c1.Дата=c2.Дата and c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]

        
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_PostponeUnique
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_PostponeUnique AS T WHERE T.ProcessGUID = @ProcessGUID

				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_KD_m_Unique a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_PostponeUnique
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_PostponeUnique
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

				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.PostponeUnique', @ProcessGUID
			END
			ELSE BEGIN
          ;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Уникальное кол-во отложенных заявок на этапе' Indicator
        		   , Отложена  Сумма
            from #KDEmployees_m e
           left join #ReportByEmployeeAgg_KD_m_Unique a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
        end
		END
		--// 'KD.Monthly.PostponeUnique'
        
        
        -- Кол-во заявок на доработку
		IF @Page = 'KD.Daily.Rework' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Rework
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Rework AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на доработку на этапе' Indicator
						, Доработка  Сумма
				from #KDEmployees e
				left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Rework
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Rework
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.Rework', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во заявок на доработку на этапе' Indicator
        		   , Доработка  Сумма
            from #KDEmployees e
           left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
        end
		END
		--// 'KD.Daily.Rework'
        
        
		IF @Page = 'KD.Monthly.Rework' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Rework
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Rework AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на доработку на этапе' Indicator
						, Доработка  Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Rework
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Rework
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.Rework', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во заявок на доработку на этапе' Indicator
        		   , Доработка  Сумма
            from #KDEmployees_m e
           left join #ReportByEmployeeAgg_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
        end
		END
		--// 'KD.Monthly.Rework'

        
        --- КД. Конвертация (одобренные / уникальные) по дням  Approval rate
		IF @Page = 'KD.Daily.AR' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_AR
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_AR AS T WHERE T.ProcessGUID = @ProcessGUID
        
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
				left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_AR
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) *100
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_AR
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
       
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Daily.AR', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'AR на этапе' Indicator
               , ВК
               , ИтогоПоСотруднику
        		   , case when ИтогоПоСотруднику<>0 then ВК*1.0/ИтогоПоСотруднику else 0 end Сумма
            from #KDEmployees e
           left join #ReportByEmployeeAgg a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
			END
        end
		--// 'KD.Daily.AR'

		IF @Page = 'KD.Monthly.AR' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_AR
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_AR AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'AR на этапе' Indicator
					, ВК
					, ИтогоПоСотруднику
						, case when ИтогоПоСотруднику<>0 then ВК*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #KDEmployees_m e
				left join #ReportByEmployeeAgg_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_AR
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) *100
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_AR
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.AR', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'AR на этапе' Indicator
               , ВК
               , ИтогоПоСотруднику
        		   , case when ИтогоПоСотруднику<>0 then ВК*1.0/ИтогоПоСотруднику else 0 end Сумма
            from #KDEmployees_m e
           left join #ReportByEmployeeAgg_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
			END
		END
		--// 'KD.Monthly.AR'

        end
--// KD.%






------------------------------
--- Верификация клиента
------------------------------
-- VK.%
if @page in (
 'VK.Daily.Total'
,'VK.Daily.Unic'
,'VK.Daily.AvgTime'
,'VK.Daily.Approved'
,'VK.Daily.Postpone'
,'VK.Daily.PostponeUnique'
,'VK.Daily.Rework'
,'VK.Daily.AR'

,'VK.Daily.Contact'
,'VK.Daily.Contact.Approved'
,'VK.Daily.Contact.Denied'

,'VK.Monthly.Total'
,'VK.Monthly.Unic'
,'VK.Monthly.AvgTime'
,'VK.Monthly.Approved'
,'VK.Monthly.Postpone'
,'VK.Monthly.PostponeUnique'
,'VK.Monthly.Rework'
,'VK.Monthly.AR'

,'VK.Monthly.Contact'
,'VK.Monthly.Contact.Approved'
,'VK.Monthly.Contact.Denied'

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
) OR @isFill_All_Tables = 1
 begin

         drop table if exists    #VKEmployees
         ;
         
          select distinct acc_period 
               , empl_id 
               , Employee 
               , [Status] 
            into #VKEmployees
            from #employee_rows_d 
           where [Status] in ('Верификация клиента') 
             and Employee in (select * from #curr_employee_vr)
        
     drop table if exists    #VKEmployees_m
         ;
         
          select distinct acc_period 
               , empl_id 
               , Employee 
               , [Status] 
            into #VKEmployees_m
            from #employee_rows_m 
           where [Status] in ('Верификация клиента') 
             and Employee in (select * from #curr_employee_vr)    
        
        drop table if exists #fedor_verificator_report_VK
        
        drop table if exists #details_VK

         select 
			R.* 
			--DWH-2067
			, Контактность = 
				iif(
					isnull(R.ЗвонокРаботодателюПоТелефонамИзКонтурФокус, 0) +
					isnull(R.ЗвонокРаботодателюПоТелефонамИзИнтернет, 0) +
					isnull(R.ЗвонокРаботодателюПоТелефонуИзАнкеты, 0) +
					isnull(R.ЗвонокКонтактномуЛицу, 0) > 0,
					1, 0)
         into #details_VK
         from #t_dm_FedorVerificationRequests_AutocredVTB AS R /*#details*/
		 WHERE 1=1
			--AND Работник not in (select * from #curr_employee_cd) --and  Статус in ('Верификация клиента') 
			AND (R.Работник not in (select * from #curr_employee_cd)
				OR R.Работник IN (select Employee from #curr_employee_vr) --DWH-1620. 2022-04-06
				)
			--AND Работник IN (select Employee from #curr_employee_vr) --DWH-1988
         --and R.[Дата статуса]>@dt_from and  R.[Дата статуса]<@dt_to

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
        
           -- select * from #t_dm_FedorVerificationRequests_AutocredVTB where [Номер заявки]='20091600033794'  
        
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
           where ([Статус следующий]='Одобрен клиент' and Статус in('Верификация Call 3'))
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
			   , Сотрудник=Работник_Пред --Работник_След
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
			--DWH-2020
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
           where Задача='task:Новая' and Статус IN (
					'Верификация клиента',
					'Переподписание первого пакета' --DWH-2101
				)
				AND [Задача следующая] <> 'task:Автоматически отложено'

			--DWH-2067
			UNION
			SELECT 'Контактность' [status]
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
			where Контактность = 1

			--DWH-2879
			UNION
			select 'НеВернувшиесяИзОтложенных' [status]
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
			where D.[Статус следующий] IN ('Аннулировано')
				AND D.Работник LIKE '%Системный%' --('Системный пользователь для FEDOR')
				--ранее была отложена на 'Верификация клиента'
				AND EXISTS(
					SELECT TOP(1) 1
					FROM #details_VK AS P
					WHERE P.[Номер заявки] = D.[Номер заявки]
						AND P.ШагЗаявки = D.ШагЗаявки - 2
						AND P.[Дата статуса] < D.[Дата статуса]
						--AND P.[Дата статуса] <= dateadd(DAY, -4, D.[Дата статуса])
						AND P.Задача='task:Отложена' 
						AND P.[Состояние заявки] IN ('Отложена')
						AND P.Статус in('Верификация клиента')
				)
				--ранее НЕ была отложена на 'Верификация ТС'
				--AND NOT EXISTS(
				--	SELECT TOP(1) 1
				--	FROM #details_VK AS P
				--	WHERE P.[Номер заявки] = D.[Номер заявки]
				--		AND P.[Дата статуса] < D.[Дата статуса]
				--		AND P.Задача='task:Отложена' 
				--		AND P.[Состояние заявки] IN ('Отложена')
				--		AND P.Статус in('Верификация ТС')
				--)
			


			IF @isDebug = 1 BEGIN
				DROP TABLE IF EXISTS ##fedor_verificator_report_VK
				SELECT * INTO ##fedor_verificator_report_VK FROM #fedor_verificator_report_VK
			END

				
            
        drop table if exists #ReportByEmployeeAgg_VK
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
               , isnull(sum(case when status in ('Новая_Уникальная') then 1 else 0 end),0) Новая_Уникальная --DWH-2020

				--DWH-2286
				, isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Первичный' then 1 else 0 end),0) [Новая_Уникальная Первичный]
				, isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Повторный' then 1 else 0 end),0) [Новая_Уникальная Повторный]
				, isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Докредитование' then 1 else 0 end),0) [Новая_Уникальная Докредитование]
				, isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Параллельный' then 1 else 0 end),0) [Новая_Уникальная Параллельный]
				, isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента IS NULL then 1 else 0 end),0) [Новая_Уникальная Не определен]

			   , isnull(count( distinct case when status='Отложена' then  [Номер заявки] end),0) [Отложено уникальных]
               , isnull(count( distinct case when status='Доработка' then [Номер заявки] end ),0) [Доработка уникальных]

               , isnull(count( distinct case when status='Контактность' then [Номер заявки] end ),0) AS Контактность
               --, isnull(sum(case when status='Контактность' then 1 else 0 end),0) AS Контактность
               , isnull(count( distinct [Номер заявки]),0) AS УникальныхЗаявок
            from #fedor_verificator_report_VK
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
           group by  [ФИО сотрудника верификации/чекер],дата
        )
          select c1.*
               , isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
               , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
               , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
            into #ReportByEmployeeAgg_VK
            from c1 
            left join c2 on c1.Дата=c2.Дата and c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]

		--#ReportByEmployeeAgg_VK
		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##ReportByEmployeeAgg_VK
			SELECT * INTO ##ReportByEmployeeAgg_VK FROM #ReportByEmployeeAgg_VK
		END


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
        
        
--monthly            
        drop table if exists #ReportByEmployeeAgg_VK_m
        ;
        with c1 as (
          select cast(format(Дата,'yyyyMM01') as date) Дата
               , Сотрудник
               , isnull(sum(case when status in ('VTS','Отказано') then 1 else 0 end),0) ИтогоПоСотруднику
               , isnull(sum(case when status='VTS' then 1 else 0 end),0) VTS
               , isnull(sum(case when status='Доработка' then 1 else 0 end ),0) [Доработка]
               , isnull(sum(case when status='Отказано' then 1 else 0 end),0) [Отказано]
               , isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
               , isnull(sum(case when status='Новая' then 1 else 0 end),0) Новая

               , isnull(count( distinct case when status='Контактность' then [Номер заявки] end ),0) AS Контактность
               --, isnull(sum(case when status='Контактность' then 1 else 0 end),0) AS Контактность
               , isnull(count( distinct [Номер заявки]),0) AS УникальныхЗаявок
            from #fedor_verificator_report_VK
           group by cast(format(Дата,'yyyyMM01') as date)
               , Сотрудник
        )
        ,c2 as (
           
           select [ФИО сотрудника верификации/чекер]
                , cast(format(Дата,'yyyyMM01') as date) дата
                , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
                , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
                , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
           from  #fedor_verificator_report_VK
           group by  [ФИО сотрудника верификации/чекер],cast(format(Дата,'yyyyMM01') as date)
        )
          select c1.*
               , isnull(c2.КоличествоЗаявок,0) КоличествоЗаявок 
               , isnull(c2.ВремяЗатрачено,0) ВремяЗатрачено
               , isnull(c2.AvgВремяЗатрачено,0) AvgВремяЗатрачено
            into #ReportByEmployeeAgg_VK_m
            from c1 
            left join c2 on c1.Дата=c2.Дата and c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]


-- считаем уникальных отложенных по верификации
        drop table if exists #ReportByEmployeeAgg_VK_UniquePostone
        ;
        with c1 as (
          select Дата
              -- , Сотрудник   
               --, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
			    , isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальныеVK]
               
            from #fedor_verificator_report_VK
           group by Дата
              -- , Сотрудник
        )        
          select c1.*              
            into #ReportByEmployeeAgg_VK_UniquePostone
            from c1 
            




            --select * from #ReportByEmployeeAgg_VK
        if @Page = 'fedor_verificator_report_VK'
        begin                
         select 'VK' stage, stage_status='All',*,[Время, час:мин:сек] = '2000-01-01 00:22:35.000'   from #fedor_verificator_report_VK            
        end
        
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
      
        
		-- По часам VK
		IF @Page = 'VK.HoursGroupDaysUnique' OR @isFill_All_Tables = 1 --241
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupDaysUnique
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupDaysUnique AS T WHERE T.ProcessGUID = @ProcessGUID

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
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupDaysUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupDaysUnique
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
		
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.HoursGroupDaysUnique', @ProcessGUID
			END
			ELSE BEGIN
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

				RETURN 0
			END
		END
		--// 'VK.HoursGroupDaysUnique'

           
		IF @Page = 'VK.HoursGroupDays' OR @isFill_All_Tables = 1 --241
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupDays
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupDays AS T WHERE T.ProcessGUID = @ProcessGUID

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
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupDays
				SELECT 
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupDays
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
           
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.HoursGroupDays', @ProcessGUID
			END
			ELSE BEGIN
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

				RETURN 0
			END
		END
		--// 'VK.HoursGroupDays'


		IF @Page = 'VK.HoursGroupMonthUnique' OR @isFill_All_Tables = 1 --241
  begin
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupMonthUnique
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupMonthUnique AS T WHERE T.ProcessGUID = @ProcessGUID

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
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupMonthUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupMonthUnique
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
           
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.HoursGroupMonthUnique', @ProcessGUID
			END
			ELSE BEGIN
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

				RETURN 0
			END
		end
		--// 'VK.HoursGroupMonthUnique'


    -- Лист "VK. Общее количество по часам"
		IF @Page = 'VK.HoursGroupMonth' OR @isFill_All_Tables = 1 --241
		BEGIN
			IF @isFill_All_Tables = 1
  begin
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupMonth
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupMonth AS T WHERE T.ProcessGUID = @ProcessGUID

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
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupMonth
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_HoursGroupMonth
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
           
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.HoursGroupMonth', @ProcessGUID
			END
			ELSE BEGIN
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

				RETURN 0
			END
   end
		--// 'VK.HoursGroupMonth'

        
        --- Общее кол-во по дням 
		IF @Page = 'VK.Daily.Total' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Total
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Total AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на этапе' Indicator
						, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Total
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Total
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.Total', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во заявок на этапе' Indicator
        		   , isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
            from #VKEmployees e
           left join #ReportByEmployeeAgg_VK a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
			END
          end
		--// 'VK.Daily.Total'

--Monthly        
		IF @Page = 'VK.Monthly.Total' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Total
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Total AS T WHERE T.ProcessGUID = @ProcessGUID
        
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на этапе' Indicator
						, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Total
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Total
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

				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.Total', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во заявок на этапе' Indicator
        		   , isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
            from #VKEmployees_m e
           left join #ReportByEmployeeAgg_VK_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
          end          
		END
		--// 'VK.Monthly.Total'
          
        
		IF @Page = 'VK.Daily.Unic' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
         begin
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Unic
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Unic AS T WHERE T.ProcessGUID = @ProcessGUID

				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во заявок на этапе' Indicator
						, isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Unic
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Unic
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.Unic', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Уникальное кол-во заявок на этапе' Indicator
        		   , isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
            from #VKEmployees e
           left join #ReportByEmployeeAgg_VK a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
			END
          end
		--// 'VK.Daily.Unic'
        
--Monthly 
		IF @Page = 'VK.Monthly.Unic' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Unic
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Unic AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во заявок на этапе' Indicator
						, isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Unic
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Unic
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.Unic', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Уникальное кол-во заявок на этапе' Indicator
        		   , isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
            from #VKEmployees_m e
           left join #ReportByEmployeeAgg_VK_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
			END
          end
		--// 'VK.Monthly.Unic'

        
		IF @Page = 'VK.Daily.AvgTime' OR @isFill_All_Tables = 1 --2403
          begin
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_AvgTime
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_AvgTime AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as ( select empl_id
        		   , Employee		
        		   , acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
						, 'Среднее время по заявке (общие)' Indicator
						, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_AvgTime
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					,  Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_AvgTime
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, iif (sum(КоличествоЗаявок)<>0, isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0), '0' )
				from agg
				group by dt , indicator 
         
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.AvgTime', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as ( select empl_id
						, Employee		
						, acc_period  dt
               , ВремяЗатрачено
               , КоличествоЗаявок
        		   , 'Среднее время по заявке (общие)' Indicator
        		   , case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
            from #VKEmployees e
           left join #ReportByEmployeeAgg_VK a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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
				   ,iif(sum(КоличествоЗаявок)<>0,   isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0),'0')
           from agg
          group by dt , indicator 

				RETURN 0
			END
          end
		--// 'VK.Daily.AvgTime'
        
 --Monthly
		IF @Page = 'VK.Monthly.AvgTime' OR @isFill_All_Tables = 1 --2403
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_AvgTime
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_AvgTime AS T WHERE T.ProcessGUID = @ProcessGUID
        
        
				;with agg as ( select empl_id
        		   , Employee		
        		   , acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
					, 'Среднее время по заявке (общие)' Indicator
					, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_AvgTime
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_AvgTime
				from agg
				union all
				select 
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, CASE WHEN sum(КоличествоЗаявок) <> 0
						THEN isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0)
						ELSE '0'
					  END
				from agg
				group by dt , indicator 
         
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.AvgTime', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as ( select empl_id
					, Employee		
					, acc_period  dt
               , ВремяЗатрачено
               , КоличествоЗаявок
        		   , 'Среднее время по заявке (общие)' Indicator
        		   , case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
            from #VKEmployees_m e
           left join #ReportByEmployeeAgg_VK_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           )
				SELECT
					empl_id
        	     , Employee
               , dt
               , Indicator
               ,  Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
            from agg
        union all
				select 
					empl_id    = isnull((select max(empl_id) from #VKEmployees_m  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator 
					, CASE WHEN sum(КоличествоЗаявок) <> 0
						THEN isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0)
						ELSE '0'
					  END
           from agg
          group by dt , indicator 

				RETURN 0
			END
          end        
		--// 'VK.Monthly.AvgTime'
        
		IF @Page = 'VK.Daily.Approved' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
          begin
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Approved
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Approved AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Кол-во одобренных заявок после этапа' Indicator
        		   , [VTS]  Сумма
             from #VKEmployees e
           left join #ReportByEmployeeAgg_VK a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Approved
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Approved
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
           
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.Approved', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
				select empl_id
					, Employee		
					, acc_period  dt
					, 'Кол-во одобренных заявок после этапа' Indicator
					, [VTS]  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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
        
				RETURN 0
			END
        end
		--// 'VK.Daily.Approved'


--Monthly
		IF @Page = 'VK.Monthly.Approved' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
          begin
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Approved
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Approved AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Кол-во одобренных заявок после этапа' Indicator
        		   , [VTS]  Сумма
             from #VKEmployees_m e
           left join #ReportByEmployeeAgg_VK_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Approved
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Approved
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
           
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.Approved', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Кол-во одобренных заявок после этапа' Indicator
						, [VTS]  Сумма
					from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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
        
				RETURN 0
        end
		END
		--// 'VK.Monthly.Approved'

        
         -- 'Общее кол-во отложенных заявок на этапе'
		IF @Page = 'VK.Daily.Postpone' OR @isFill_All_Tables = 1 --2401
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Postpone
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Postpone AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Postpone
				select 
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Postpone
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.Postpone', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во отложенных заявок на этапе' Indicator
        		   , Отложена  Сумма
            from #VKEmployees e
           left join #ReportByEmployeeAgg_VK a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
        end
		END
		--// 'VK.Daily.Postpone'
        

        -- 'Уникальное кол-во отложенных заявок на этапе'
		IF @Page = 'VK.Daily.PostponeUnique' OR @isFill_All_Tables = 1 --2401
          begin
		drop table if exists #fedor_verificator_report_VK_Unique
		   select Дата
               , Сотрудник              
               , isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальные]
            into #fedor_verificator_report_VK_Unique
            from #fedor_verificator_report_VK
           group by Дата, Сотрудник

			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_PostponeUnique
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_PostponeUnique AS T WHERE T.ProcessGUID = @ProcessGUID

				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во отложенных заявок на этапе' Indicator
						, [ОтложенаУникальные]  Сумма
				from #VKEmployees e
				left join #fedor_verificator_report_VK_Unique a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_PostponeUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_PostponeUnique
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

				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.PostponeUnique', @ProcessGUID
			END
			ELSE BEGIN
          ;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Уникальное кол-во отложенных заявок на этапе' Indicator
        		   , [ОтложенаУникальные]  Сумма
            from #VKEmployees e
           left join #fedor_verificator_report_VK_Unique a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
			END
        end
		--// 'VK.Daily.PostponeUnique'
        

--Monthly
		IF @Page = 'VK.Monthly.Postpone' OR @isFill_All_Tables = 1 --2401
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Postpone
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Postpone AS T WHERE T.ProcessGUID = @ProcessGUID

        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Postpone
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Postpone
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.Postpone', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во отложенных заявок на этапе' Indicator
        		   , Отложена  Сумма
            from #VKEmployees_m e
           left join #ReportByEmployeeAgg_VK_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
        end
		END
		--// 'VK.Monthly.Postpone'

--Monthly Unique
		IF @Page = 'VK.Monthly.PostponeUnique' OR @isFill_All_Tables = 1 --2401
          begin

		       drop table if exists #ReportByEmployeeAgg_VK_m_Unique

			;with c1 as (
          select cast(format(Дата,'yyyyMM01') as date) Дата
               , Сотрудник             
               , isnull(count( distinct case when status='Отложена' then [Номер заявки]  end),0) [Отложена]               
            from #fedor_verificator_report_VK
           group by cast(format(Дата,'yyyyMM01') as date)
               , Сотрудник
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
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_PostponeUnique
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_PostponeUnique AS T WHERE T.ProcessGUID = @ProcessGUID

				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m_Unique a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_PostponeUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_PostponeUnique
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.PostponeUnique', @ProcessGUID
			END
			ELSE BEGIN
          ;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Уникальное кол-во отложенных заявок на этапе' Indicator
        		   , Отложена  Сумма
            from #VKEmployees_m e
           left join #ReportByEmployeeAgg_VK_m_Unique a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
			END
        end
		--// 'VK.Monthly.PostponeUnique'
        

        
		IF @Page = 'VK.Daily.Rework' OR @isFill_All_Tables = 1 --2402
		BEGIN
        
			IF @isFill_All_Tables = 1
          begin
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Rework
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Rework AS T WHERE T.ProcessGUID = @ProcessGUID

				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на доработку на этапе' Indicator
						, Доработка  Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Rework
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Rework
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.Rework', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во заявок на доработку на этапе' Indicator
        		   , Доработка  Сумма
            from #VKEmployees e
           left join #ReportByEmployeeAgg_VK a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
        end
		END
		--// 'VK.Daily.Rework'
        
--Monthly

		IF @Page = 'VK.Monthly.Rework' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Rework
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Rework AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на доработку на этапе' Indicator
						, Доработка  Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Rework
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Rework
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.Rework', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во заявок на доработку на этапе' Indicator
        		   , Доработка  Сумма
            from #VKEmployees_m e
           left join #ReportByEmployeeAgg_VK_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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

				RETURN 0
        end
		END
		--// 'VK.Monthly.Rework'
        

		IF @Page = 'VK.Daily.AR' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_AR
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_AR AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'AR на этапе' Indicator
					, VTS
					, ИтогоПоСотруднику
						, case when ИтогоПоСотруднику<>0 then VTS*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #VKEmployees e
				left join #ReportByEmployeeAgg_VK a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_AR
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) *100
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_AR
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.AR', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'AR на этапе' Indicator
               , VTS
               , ИтогоПоСотруднику
        		   , case when ИтогоПоСотруднику<>0 then VTS*1.0/ИтогоПоСотруднику else 0 end Сумма
            from #VKEmployees e
           left join #ReportByEmployeeAgg_VK a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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
          
				RETURN 0
			END
        end
		--// 'VK.Daily.AR'



		IF @Page = 'VK.Monthly.AR' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_AR
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_AR AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'AR на этапе' Indicator
					, VTS
					, ИтогоПоСотруднику
						, case when ИтогоПоСотруднику<>0 then VTS*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #VKEmployees_m e
				left join #ReportByEmployeeAgg_VK_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_AR
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) *100
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_AR
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.AR', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'AR на этапе' Indicator
               , VTS
               , ИтогоПоСотруднику
        		   , case when ИтогоПоСотруднику<>0 then VTS*1.0/ИтогоПоСотруднику else 0 end Сумма
            from #VKEmployees_m e
           left join #ReportByEmployeeAgg_VK_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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
          
				RETURN 0
			END
		END
		--// 'VK.Monthly.AR'

		IF @Page = 'VK.Monthly.Contact' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact AS T WHERE T.ProcessGUID = @ProcessGUID
        
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
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) * 100
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact
				from agg
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.Contact', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
				select empl_id
					, Employee		
					, acc_period  dt
					, 'Контактность' Indicator
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
          
				RETURN 0
			END
		END
		--// 'VK.Monthly.Contact'

		IF @Page = 'VK.Monthly.Contact.Approved' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact_Approved
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact_Approved AS T WHERE T.ProcessGUID = @ProcessGUID
        
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
					LEFT JOIN #t_Contact_Employee_Month_Approved AS a
						ON e.acc_period = a.Дата 
						AND e.Employee = a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact_Approved
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) * 100
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact_Approved
				from agg
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.Contact.Approved', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
				select empl_id
					, Employee		
					, acc_period  dt
					, 'Контактность' Indicator
					, Контактность
					--, КоличествоЗаявок
					--, ИтогоПоСотруднику
					, УникальныхЗаявок
					--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
					--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
					, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
				FROM #VKEmployees_m AS e
					LEFT JOIN #t_Contact_Employee_Month_Approved AS a
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
          
				RETURN 0
			END
		END
		--// 'VK.Monthly.Contact.Approved'

		IF @Page = 'VK.Monthly.Contact.Denied' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact_Denied
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact_Denied AS T WHERE T.ProcessGUID = @ProcessGUID
        
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
					LEFT JOIN #t_Contact_Employee_Month_Denied AS a
						ON e.acc_period = a.Дата 
						AND e.Employee = a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact_Denied
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) * 100
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact_Denied
				from agg
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Monthly.Contact.Denied', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
				select empl_id
					, Employee		
					, acc_period  dt
					, 'Контактность' Indicator
					, Контактность
					--, КоличествоЗаявок
					--, ИтогоПоСотруднику
					, УникальныхЗаявок
					--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
					--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
					, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
				FROM #VKEmployees_m AS e
					LEFT JOIN #t_Contact_Employee_Month_Denied AS a
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
          
				RETURN 0
			END
		END
		--// 'VK.Monthly.Contact.Denied'


		IF @Page = 'VK.Daily.Contact' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Contact
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Contact AS T WHERE T.ProcessGUID = @ProcessGUID
        
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
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Contact
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) * 100
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact
				from agg
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.Contact', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
				select empl_id
					, Employee		
					, acc_period  dt
					, 'Контактность' Indicator
					, Контактность
					--, КоличествоЗаявок
					--, ИтогоПоСотруднику
					, УникальныхЗаявок
					--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
					--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
					, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
				FROM #VKEmployees_m AS e
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
          
				RETURN 0
			END
		END
		--// 'VK.Daily.Contact'


		IF @Page = 'VK.Daily.Contact.Approved' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Contact_Approved
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Contact_Approved AS T WHERE T.ProcessGUID = @ProcessGUID
        
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
					LEFT JOIN #t_Contact_Employee_Day_Approved AS a
						ON e.acc_period = a.Дата 
						AND e.Employee = a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Contact_Approved
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) * 100
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact_Approved
				from agg
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.Contact.Approved', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
				select empl_id
					, Employee		
					, acc_period  dt
					, 'Контактность' Indicator
					, Контактность
					--, КоличествоЗаявок
					--, ИтогоПоСотруднику
					, УникальныхЗаявок
					--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
					--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
					, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
				FROM #VKEmployees_m AS e
					LEFT JOIN #t_Contact_Employee_Day_Approved AS a
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
          
				RETURN 0
			END
		END
		--// 'VK.Daily.Contact.Approved'


		IF @Page = 'VK.Daily.Contact.Denied' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Contact_Denied
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Contact_Denied AS T WHERE T.ProcessGUID = @ProcessGUID
        
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
					LEFT JOIN #t_Contact_Employee_Day_Denied AS a
						ON e.acc_period = a.Дата 
						AND e.Employee = a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Daily_Contact_Denied
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) * 100
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_VK_Monthly_Contact_Denied
				from agg
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
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'VK.Daily.Contact.Denied', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
				select empl_id
					, Employee		
					, acc_period  dt
					, 'Контактность' Indicator
					, Контактность
					--, КоличествоЗаявок
					--, ИтогоПоСотруднику
					, УникальныхЗаявок
					--, case when КоличествоЗаявок <> 0 then Контактность * 1.0 / КоличествоЗаявок else 0 end AS Сумма
					--, case when ИтогоПоСотруднику <> 0 then Контактность * 1.0 / ИтогоПоСотруднику else 0 end AS Сумма
					, case when УникальныхЗаявок <> 0 then Контактность * 1.0 / УникальныхЗаявок else 0 end AS Сумма
				FROM #VKEmployees_m AS e
					LEFT JOIN #t_Contact_Employee_Day_Denied AS a
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
          
				RETURN 0
			END
		END
		--// 'VK.Daily.Contact.Denied'
END
--// VK.%
        
        


------------------------------
--- Верификация ТС
------------------------------
-- TS.%
if @page in (
'TS.Daily.Total'
,'TS.Daily.Unic'
,'TS.Daily.AvgTime'
,'TS.Daily.Approved' 
,'TS.Daily.Postpone'
,'TS.Daily.PostponeUnique'
,'TS.Daily.Rework'
,'TS.Daily.AR'

,'TS.Monthly.Total'
,'TS.Monthly.Unic'
,'TS.Monthly.AvgTime'
,'TS.Monthly.Approved' 
,'TS.Monthly.Postpone'
, 'TS.Monthly.PostponeUnique'
,'TS.Monthly.Rework'
,'TS.Monthly.AR'

,'V.Daily.Common'
,'V.Monthly.Common'

  ,'TS.HoursGroupMonth'
   , 'TS.HoursGroupMonthUnique'
  , 'TS.HoursGroupDays'
  , 'TS.HoursGroupDaysUnique'
  ,'ReportByEmployee_TS'
  ,'ReportByEmployeeAgg_TS'
  ,'ReportByEmployeeAgg_TS_LastHour'
  , 'fedor_verificator_report_TS'
) OR @isFill_All_Tables = 1
begin
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


        DROP TABLE IF EXISTS #details_TS
		SELECT *
		INTO #details_TS
		FROM #t_dm_FedorVerificationRequests_AutocredVTB
		where 1=1
			--AND Работник not in (select * from #curr_employee_cd)
			AND (Работник not in (select * from #curr_employee_cd)
				OR Работник IN (select Employee from #curr_employee_vr) --DWH-1620. 2022-04-06
			)
			--AND Работник IN (select Employee from #curr_employee_vr) --DWH-1988
			--AND [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
			--and  Статус in ('Верификация клиента') 

		--Отказы Логинома --DWH-2429
		DELETE #t_request_number
		DELETE #t_checklists_rejects

		INSERT #t_request_number(IdClientRequest, [Номер заявки])
		SELECT DISTINCT R.IdClientRequest, R.[Номер заявки]
		FROM #details_TS AS R

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

        
        drop table if exists #fedor_verificator_report_TS
        
         ;
         with 
			--details_TS as (
			--	SELECT * from #t_dm_FedorVerificationRequests_AutocredVTB/*#details*/ 
			--	WHERE 1=1
			--	--AND Работник not in (select * from #curr_employee_cd)
			--	AND (Работник not in (select * from #curr_employee_cd)
			--		OR Работник IN (select Employee from #curr_employee_vr) --DWH-1620. 2022-04-06
			--		)
			--	--AND Работник IN (select Employee from #curr_employee_vr) --DWH-1988

			--	AND [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
			--	--and  Статус in ('Верификация клиента') 
			--),
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
            from #details_TS
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
				,ТипКлиента
            from #details_TS
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
				,ТипКлиента
            from #details_TS
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
				,ТипКлиента
            from #details_TS
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
				,ТипКлиента
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
				,ТипКлиента
            from rework1
           union 
       select * from postpone
       union
       select * from postpone1

        --select * from  #fedor_verificator_report_TS where  Дата='20200916'  order by 2 
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
            from #details_TS AS N
           where [Статус следующий]='Отказано' and (Статус in('Верификация ТС') or Статус in('Верификация Call 4'))
				AND EXISTS(SELECT TOP(1) 1 FROM #t_checklists_rejects AS J WHERE J.IdClientRequest = N.IdClientRequest)
              
               union

                --
            /*    
                select * from #t_dm_FedorVerificationRequests_AutocredVTB where [Номер заявки] in (
                select distinct [Номер заявки] from #t_dm_FedorVerificationRequests_AutocredVTB where   Статус in('Верификация ТС')
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
				,ТипКлиента
            from #details_TS
           where Задача='task:Новая'  and Статус in('Верификация ТС')

			UNION
			--DWH-2020
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
            from #details_TS
           where Задача='task:Новая'  and Статус in('Верификация ТС')
				AND [Задача следующая] <> 'task:Автоматически отложено'

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
            from details_TS
          where  [Номер заявки]='20091600033895' 
            */
        
           -- select * from #t_dm_FedorVerificationRequests_AutocredVTB where Статус like 'Договор%'
          -- select * from #t_dm_FedorVerificationRequests_AutocredVTB where Статус like 'отк%'
        --select * from #t_dm_FedorVerificationRequests_AutocredVTB where [Номер заявки]='20090900032034'
           -- select * from  #fedor_verificator_report_TS where  status='Отказано' and  Дата='20200916' --[Номер заявки]='20091500033541' order by 3
          
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
				,ТипКлиента
            from #details_TS AS D
           where [Статус следующий]='Одобрено' and (Статус in('Верификация ТС') or Статус in('Верификация Call 4'))
				--DWH-2429 --одобрено сотрудником, но отказано автоматически
				OR (
					D.[Статус следующий]='Отказано' and (Статус in('Верификация ТС') or Статус in('Верификация Call 4'))
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
			   , Сотрудник=Работник_Пред --Работник_След
               , [ФИО сотрудника верификации/чекер] = Работник
               , ВремяЗатрачено
				,ТипКлиента
            from #details_TS
             where Задача='task:В работе'  and Статус in('Верификация ТС')

			--DWH-2879
			UNION
			select 'НеВернувшиесяИзОтложенных' [status]
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
            from #details_TS AS D
			where D.[Статус следующий] IN ('Аннулировано')
				AND D.Работник LIKE '%Системный%' --('Системный пользователь для FEDOR')
				--ранее была отложена на 'Верификация ТС'
				AND EXISTS(
					SELECT TOP(1) 1
					FROM #details_TS AS P
					WHERE P.[Номер заявки] = D.[Номер заявки]
						AND P.ШагЗаявки = D.ШагЗаявки - 2
						AND P.[Дата статуса] < D.[Дата статуса]
						--AND P.[Дата статуса] <= dateadd(DAY, -4, D.[Дата статуса])
						AND P.Задача='task:Отложена' 
						AND P.[Состояние заявки] IN ('Отложена')
						AND P.Статус in('Верификация ТС')
				)
				--ранее НЕ была отложена на 'Верификация клиента'
				--AND NOT EXISTS(
				--	SELECT TOP(1) 1
				--	FROM #details_VK AS P
				--	WHERE P.[Номер заявки] = D.[Номер заявки]
				--		AND P.[Дата статуса] < D.[Дата статуса]
				--		AND P.Задача='task:Отложена' 
				--		AND P.[Состояние заявки] IN ('Отложена')
				--		AND P.Статус in('Верификация клиента')
				--)

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##fedor_verificator_report_TS
			SELECT * INTO ##fedor_verificator_report_TS FROM #fedor_verificator_report_TS
		END
        
            
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
               , isnull(sum(case when status in ('Новая_Уникальная') then 1 else 0 end),0) Новая_Уникальная --DWH-2020
				--DWH-2286
				, isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Первичный' then 1 else 0 end),0) [Новая_Уникальная Первичный]
				, isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Повторный' then 1 else 0 end),0) [Новая_Уникальная Повторный]
				, isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Докредитование' then 1 else 0 end),0) [Новая_Уникальная Докредитование]
				, isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента='Параллельный' then 1 else 0 end),0) [Новая_Уникальная Параллельный]
				, isnull(sum(case when status in ('Новая_Уникальная') AND ТипКлиента IS NULL then 1 else 0 end),0) [Новая_Уникальная Не определен]

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
      
		--- Общее по часам для ТС
		IF @Page = 'TS.HoursGroupDaysUnique' OR @isFill_All_Tables = 1 --241
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupDaysUnique
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupDaysUnique AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with c2 as (
				select null as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(Дата as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_TS
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
				from  #fedor_verificator_report_TS
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupDaysUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupDaysUnique
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
           
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.HoursGroupDaysUnique', @ProcessGUID
			END
			ELSE BEGIN
				;with c2 as (
           select null as [ФИО сотрудника верификации/чекер]
		        , 25 as Интервал
                , cast(Дата as date)  as дата
				, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
                , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
                , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
                , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
           from  #fedor_verificator_report_TS
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
           from  #fedor_verificator_report_TS
           --group by  [ФИО сотрудника верификации/чекер],дата
		   group by cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
        )
				SELECT
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
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

				RETURN 0
			END
		END
		--// 'TS.HoursGroupDaysUnique'

		IF @Page = 'TS.HoursGroupDays' OR @isFill_All_Tables = 1 --241
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupDays
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupDays AS T WHERE T.ProcessGUID = @ProcessGUID
           
				;with c2 as (
           select null as [ФИО сотрудника верификации/чекер]
		        , 25 as Интервал
                , cast(Дата as date)  as дата
                , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
                , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
                , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
           from  #fedor_verificator_report_TS
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
				from  #fedor_verificator_report_TS
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupDays
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupDays
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
           
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.HoursGroupDays', @ProcessGUID
			END
			ELSE BEGIN
				;with c2 as (
				select null as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(Дата as date)  as дата
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_TS
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
           from  #fedor_verificator_report_TS
           --group by  [ФИО сотрудника верификации/чекер],дата
		   group by cast(Дата as date) , datepart(hour, ДатаИВремяСтатуса)
        )
				SELECT
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
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

				RETURN 0
			END
		END
		--// 'TS.HoursGroupDays'

		IF @Page = 'TS.HoursGroupMonthUnique' OR @isFill_All_Tables = 1 --241
		BEGIN
			IF @isFill_All_Tables = 1
  begin
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupMonthUnique
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupMonthUnique AS T WHERE T.ProcessGUID = @ProcessGUID

				;WITH c2 as (
				select null as [ФИО сотрудника верификации/чекер]
					, 25 as Интервал
					, cast(format(Дата,'yyyyMM01') as date)  as дата
					, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
					, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
					, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
					, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
				from  #fedor_verificator_report_TS
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
				from  #fedor_verificator_report_TS
				--group by  [ФИО сотрудника верификации/чекер],дата
				group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupMonthUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupMonthUnique
				from (select distinct Интервал, cast(format(Дата,'yyyyMM01') as date) Дата , ИнтервалСтрока from #HoursDays)  hd left join (
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
           
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.HoursGroupMonthUnique', @ProcessGUID
			END
			ELSE BEGIN
				;WITH c2 as (
           select null as [ФИО сотрудника верификации/чекер]
		        , 25 as Интервал
                , cast(format(Дата,'yyyyMM01') as date)  as дата
				, isnull(sum(case when status in ('Новая') then 1 else 0 end),0) Новая
                , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
                , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
                , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
           from  #fedor_verificator_report_TS
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
           from  #fedor_verificator_report_TS
           --group by  [ФИО сотрудника верификации/чекер],дата
		   group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
        )
				SELECT
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
			from (select distinct Интервал, cast(format(Дата,'yyyyMM01') as date) Дата , ИнтервалСтрока from #HoursDays)  hd left join (
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

				RETURN 0
		end
		END
		--// 'TS.HoursGroupMonthUnique'


    -- Лист "КД. Общее количество по часам"
		IF @Page = 'TS.HoursGroupMonth' OR @isFill_All_Tables = 1 --241
  begin
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupMonth
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupMonth AS T WHERE T.ProcessGUID = @ProcessGUID

				;with c2 as (
					select null as [ФИО сотрудника верификации/чекер]
						, 25 as Интервал
						, cast(format(Дата,'yyyyMM01') as date)  as дата
						, sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
						, sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
						, avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
					from  #fedor_verificator_report_TS
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
					from  #fedor_verificator_report_TS
					--group by  [ФИО сотрудника верификации/чекер],дата
					group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupMonth
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_HoursGroupMonth
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
           
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.HoursGroupMonth', @ProcessGUID
			END
			ELSE BEGIN
				;with c2 as (
           select null as [ФИО сотрудника верификации/чекер]
		        , 25 as Интервал
                , cast(format(Дата,'yyyyMM01') as date)  as дата
                , sum(case when status in ('task:В работе') then 1 else 0 end)  КоличествоЗаявок 
                , sum(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  ВремяЗатрачено 
                , avg(case when status in ('task:В работе') then ВремяЗатрачено else 0 end)  avgВремяЗатрачено 
           from  #fedor_verificator_report_TS
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
           from  #fedor_verificator_report_TS
           --group by  [ФИО сотрудника верификации/чекер],дата
		   group by cast(format(Дата,'yyyyMM01') as date) , datepart(hour, ДатаИВремяСтатуса)
        )
				SELECT
				isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
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

				RETURN 0
			END
   end
		--// 'TS.HoursGroupMonth'

  --- Общее кол-во по дням 
		IF @Page = 'TS.Daily.Total' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
         begin
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Total
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Total AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на этапе' Indicator
						, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #TSEmployees e
				left join #ReportByEmployeeAgg_TS a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Total
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Total
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator
					, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				--*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Daily.Total', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во заявок на этапе' Indicator
        		   , isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
            from #TSEmployees e
           left join #ReportByEmployeeAgg_TS a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           )
          select empl_id
        	     , Employee
               , dt
               , Indicator
               , isnull(КоличествоЗаявок,0) Сумма
            from agg
        union all
          select empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator
        		   , isnull(sum(КоличествоЗаявок ),0)
           from agg
          group by dt , indicator 

				RETURN 0
			END
          end
		--// 'TS.Daily.Total'

--Monthly        
		IF @Page = 'TS.Monthly.Total' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Total
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Total AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на этапе' Indicator
						, isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
				from #TSEmployees_m e
				left join #ReportByEmployeeAgg_TS_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Total
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Total
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator
					, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				--*/
        
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Monthly.Total', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во заявок на этапе' Indicator
        		   , isnull(КоличествоЗаявок ,0) КоличествоЗаявок 
            from #TSEmployees_m e
           left join #ReportByEmployeeAgg_TS_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           )
          select empl_id
        	     , Employee
               , dt
               , Indicator
               , isnull(КоличествоЗаявок,0) Сумма
            from agg
        union all
          select empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator
        		   , isnull(sum(КоличествоЗаявок ),0)
           from agg
          group by dt , indicator 

				RETURN 0
          end          
		END          
		--// 'TS.Monthly.Total'
          
		IF @Page = 'TS.Daily.Unic' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
         begin
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Unic
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Unic AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во заявок на этапе' Indicator
						, isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
				from #TSEmployees e
				left join #ReportByEmployeeAgg_TS a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Unic
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Unic
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator
					, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				--*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Daily.Unic', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Уникальное кол-во заявок на этапе' Indicator
        		   , isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
            from #TSEmployees e
           left join #ReportByEmployeeAgg_TS a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           )
          select empl_id
        	     , Employee
               , dt
               , Indicator
               , isnull(КоличествоЗаявок,0) Сумма
            from agg
        union all
          select empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator
        		   , isnull(sum(КоличествоЗаявок ),0)
           from agg
          group by dt , indicator 

				RETURN 0
			END
          end
		--// 'TS.Daily.Unic'
        
--Monthly
		IF @Page = 'TS.Monthly.Unic' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
         begin
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Unic
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Unic AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во заявок на этапе' Indicator
						, isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
				from #TSEmployees_m e
				left join #ReportByEmployeeAgg_TS_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Unic
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, isnull(КоличествоЗаявок,0) Сумма
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Unic
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator
					, isnull(sum(КоличествоЗаявок ),0)
				from agg
				group by dt , indicator 
				--*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Monthly.Unic', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Уникальное кол-во заявок на этапе' Indicator
        		   , isnull(ИтогоПоСотруднику ,0) КоличествоЗаявок 
            from #TSEmployees_m e
           left join #ReportByEmployeeAgg_TS_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           )
          select empl_id
        	     , Employee
               , dt
               , Indicator
               , isnull(КоличествоЗаявок,0) Сумма
            from agg
        union all
          select empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator
        		   , isnull(sum(КоличествоЗаявок ),0)
           from agg
          group by dt , indicator 

				RETURN 0
			END
          end
		--// 'TS.Monthly.Unic'

          
		IF @Page = 'TS.Daily.AvgTime' OR @isFill_All_Tables = 1 --2403
		BEGIN
			IF @isFill_All_Tables = 1
          begin
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_AvgTime
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_AvgTime AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as ( select empl_id
					, Employee		
					, acc_period  dt
					, ВремяЗатрачено
					, КоличествоЗаявок
					, 'Среднее время по заявке (общие)' Indicator
					, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #TSEmployees e
				left join #ReportByEmployeeAgg_TS a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_AvgTime
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					,  Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_AvgTime
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, CASE WHEN sum(КоличествоЗаявок) <> 0
						THEN isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0)
						ELSE '0'
					  END
				from agg
				group by dt , indicator 
				--*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Daily.AvgTime', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as ( select empl_id
        		   , Employee		
        		   , acc_period  dt
         
               , ВремяЗатрачено
               , КоличествоЗаявок
        		   , 'Среднее время по заявке (общие)' Indicator
        		   , case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
            from #TSEmployees e
           left join #ReportByEmployeeAgg_TS a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           
           )
          select empl_id
        	     , Employee
               , dt
               , Indicator
               ,  Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
            from agg
        union all
          select empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator 
					, CASE WHEN sum(КоличествоЗаявок) <> 0
						THEN isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0)
						ELSE '0'
					  END
           from agg
          group by dt , indicator 

				RETURN 0
			END
          end
		--// 'TS.Daily.AvgTime'

--Monthly        
		IF @Page = 'TS.Monthly.AvgTime' OR @isFill_All_Tables = 1 --2403
		BEGIN
			IF @isFill_All_Tables = 1
          begin
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_AvgTime
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_AvgTime AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as ( select empl_id
						, Employee		
						, acc_period  dt
						, ВремяЗатрачено
						, КоличествоЗаявок
						, 'Среднее время по заявке (общие)' Indicator
						, case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
				from #TSEmployees_m e
				left join #ReportByEmployeeAgg_TS_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_AvgTime
				SELECT	
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					,  Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_AvgTime
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, CASE WHEN sum(КоличествоЗаявок) <> 0
						THEN isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0)
						ELSE '0'
					  END
				from agg
				group by dt , indicator 
				--*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Monthly.AvgTime', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as ( select empl_id
        		   , Employee		
        		   , acc_period  dt
               , ВремяЗатрачено
               , КоличествоЗаявок
        		   , 'Среднее время по заявке (общие)' Indicator
        		   , case when КоличествоЗаявок<>0 then ВремяЗатрачено/КоличествоЗаявок else 0 end  Сумма
            from #TSEmployees_m e
           left join #ReportByEmployeeAgg_TS_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           
           )
				SELECT	
					empl_id
        	     , Employee
               , dt
               , Indicator
               ,  Сумма=isnull(convert(nvarchar, cast(Сумма as datetime),8)  ,0)
            from agg
        union all
				SELECT
					empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator 
					, CASE WHEN sum(КоличествоЗаявок) <> 0
						THEN isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0)
						ELSE '0'
					  END
           from agg
          group by dt , indicator 

				RETURN 0
          end        
		END
		--// TS.Monthly.AvgTime
        
		IF @Page = 'TS.Daily.Approved' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
          begin
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Approved
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Approved AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Кол-во одобренных заявок после этапа' Indicator
        		   , Одобрено  Сумма
             from #TSEmployees e
           left join #ReportByEmployeeAgg_TS a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           )
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Approved
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Approved
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				--*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Daily.Approved', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        	     , Employee
						, acc_period  dt
						, 'Кол-во одобренных заявок после этапа' Indicator
						, Одобрено  Сумма
					from #TSEmployees e
				left join #ReportByEmployeeAgg_TS a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
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
					empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator 
        		   , isnull(sum(Сумма) ,0)
           from agg
          group by dt, indicator  
        
				RETURN 0
			END
        end
        --// 'TS.Daily.Approved'

--Monthly
		IF @Page = 'TS.Monthly.Approved' OR @isFill_All_Tables = 1
		BEGIN
			IF @isFill_All_Tables = 1
          begin
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Approved
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Approved AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Кол-во одобренных заявок после этапа' Indicator
						, Одобрено  Сумма
					from #TSEmployees_m e
				left join #ReportByEmployeeAgg_TS_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Approved
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Approved
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				--*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Monthly.Approved', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Кол-во одобренных заявок после этапа' Indicator
        		   , Одобрено  Сумма
             from #TSEmployees_m e
           left join #ReportByEmployeeAgg_TS_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           
           )
          select empl_id
        	     , Employee
               , dt
               , Indicator
               , Сумма=isnull(Сумма,0)
            from agg
        union all
          select empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator 
        		   , isnull(sum(Сумма) ,0)
           from agg
          group by dt, indicator  
        
				RETURN 0
			END
        end
		--// 'TS.Monthly.Approved'

        
         -- 'Общее кол-во отложенных заявок на этапе'
		IF @Page = 'TS.Daily.Postpone' OR @isFill_All_Tables = 1 --2401
		BEGIN
			IF @isFill_All_Tables = 1
          begin
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Postpone
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Postpone AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #TSEmployees e
				left join #ReportByEmployeeAgg_TS a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Postpone
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Postpone
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				--*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Daily.Postpone', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во отложенных заявок на этапе' Indicator
        		   , Отложена  Сумма
            from #TSEmployees e
           left join #ReportByEmployeeAgg_TS a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           )
          select empl_id
        	     , Employee
               , dt
               , Indicator
               , Сумма=isnull(Сумма,0)
            from agg
        union all
          select empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator 
        		   , isnull(sum(Сумма) ,0)
           from agg
          group by dt , indicator 

				RETURN 0
			END
        end
		--// 'TS.Daily.Postpone'


		   -- 'Уникальное кол-во отложенных заявок на этапе'
		IF @Page = 'TS.Daily.PostponeUnique' OR @isFill_All_Tables = 1 --2401
		BEGIN
   
		--IF @isFill_All_Tables <> 1
		--BEGIN
			drop table if exists #fedor_verificator_report_TS_Unique
			select Дата
				, Сотрудник              
				, isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальные]
			into #fedor_verificator_report_TS_Unique
			from #fedor_verificator_report_TS
			group by Дата, Сотрудник
		--END

			IF @isFill_All_Tables = 1
			BEGIN
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_PostponeUnique
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_PostponeUnique AS T WHERE T.ProcessGUID = @ProcessGUID

          ;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Уникальное кол-во отложенных заявок на этапе' Indicator
        		   , [ОтложенаУникальные]  Сумма
            from #TSEmployees e
           left join #fedor_verificator_report_TS_Unique a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           )
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_PostponeUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_PostponeUnique
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				--*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Daily.PostponeUnique', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во отложенных заявок на этапе' Indicator
						, [ОтложенаУникальные]  Сумма
				from #TSEmployees e
				left join #fedor_verificator_report_TS_Unique a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
          select empl_id
        	     , Employee
               , dt
               , Indicator
               , Сумма=isnull(Сумма,0)
            from agg
        union all
          select empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator 
        		   , isnull(sum(Сумма) ,0)
           from agg
          group by dt , indicator 

				RETURN 0
			END
        end
		--// 'TS.Daily.PostponeUnique'

		
--Monthly Unique
		IF @Page = 'TS.Monthly.PostponeUnique' OR @isFill_All_Tables = 1 --2401
		BEGIN
        
		--IF @isFill_All_Tables <> 1
		--BEGIN
			DROP table if exists #ReportByEmployeeAgg_TS_m_Unique

			;with c1 as (
			select cast(format(Дата,'yyyyMM01') as date) Дата
			, Сотрудник             
			, isnull(count( distinct case when status='Отложена' then [Номер заявки]  end),0) [Отложена]               
			from #fedor_verificator_report_TS
			group by cast(format(Дата,'yyyyMM01') as date)
			, Сотрудник
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
			into #ReportByEmployeeAgg_TS_m_Unique
			from c1 
			--left join c2 on c1.Дата=c2.Дата and c1.Сотрудник=c2.[ФИО сотрудника верификации/чекер]
		--END
		--// @isFill_All_Tables <> 1

			IF @isFill_All_Tables = 1
			BEGIN
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_PostponeUnique
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_PostponeUnique AS T WHERE T.ProcessGUID = @ProcessGUID
        
          ;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Уникальное кол-во отложенных заявок на этапе' Indicator
        		   , Отложена  Сумма
            from #TSEmployees_m e
           left join #ReportByEmployeeAgg_TS_m_Unique a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           )
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_PostponeUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_PostponeUnique
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				--*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Monthly.PostponeUnique', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Уникальное кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #TSEmployees_m e
				left join #ReportByEmployeeAgg_TS_m_Unique a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
          select empl_id
        	     , Employee
               , dt
               , Indicator
               , Сумма=isnull(Сумма,0)
            from agg
        union all
          select empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator 
        		   , isnull(sum(Сумма) ,0)
           from agg
          group by dt , indicator 

				RETURN 0
        end
		END
		--// 'TS.Monthly.PostponeUnique'
        

--Monthly        
		IF @Page = 'TS.Monthly.Postpone' OR @isFill_All_Tables = 1 --2401
		BEGIN
			IF @isFill_All_Tables = 1
          begin
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Postpone
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Postpone AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во отложенных заявок на этапе' Indicator
						, Отложена  Сумма
				from #TSEmployees_m e
				left join #ReportByEmployeeAgg_TS_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Postpone
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Postpone
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt , indicator 
				--*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Monthly.Postpone', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во отложенных заявок на этапе' Indicator
        		   , Отложена  Сумма
            from #TSEmployees_m e
           left join #ReportByEmployeeAgg_TS_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           )
          select empl_id
        	     , Employee
               , dt
               , Indicator
               , Сумма=isnull(Сумма,0)
            from agg
        union all
          select empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator 
        		   , isnull(sum(Сумма) ,0)
           from agg
          group by dt , indicator 

				RETURN 0
			END
        end
		--// 'TS.Monthly.Postpone'
        
        
		IF @Page = 'TS.Daily.Rework' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
          begin
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Rework
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Rework AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на доработку на этапе' Indicator
						, Доработка  Сумма
				from #TSEmployees e
				left join #ReportByEmployeeAgg_TS a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Rework
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_Rework
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				--*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Daily.Rework', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во заявок на доработку на этапе' Indicator
        		   , Доработка  Сумма
            from #TSEmployees e
           left join #ReportByEmployeeAgg_TS a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           )
          select empl_id
        	     , Employee
               , dt
               , Indicator
               , Сумма=isnull(Сумма,0)
            from agg
        union all
          select empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator 
        		   , isnull(sum(Сумма) ,0)
           from agg
          group by dt, indicator  

				RETURN 0
			END
        end
		--// 'TS.Daily.Rework'
        
--Monthly
		IF @Page = 'TS.Monthly.Rework' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
          begin
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Rework
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Rework AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'Общее кол-во заявок на доработку на этапе' Indicator
						, Доработка  Сумма
				from #TSEmployees_m e
				left join #ReportByEmployeeAgg_TS_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Rework
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_Rework
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(sum(Сумма) ,0)
				from agg
				group by dt, indicator  
				--*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Monthly.Rework', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'Общее кол-во заявок на доработку на этапе' Indicator
        		   , Доработка  Сумма
            from #TSEmployees_m e
           left join #ReportByEmployeeAgg_TS_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           )
          select empl_id
        	     , Employee
               , dt
               , Indicator
               , Сумма=isnull(Сумма,0)
            from agg
        union all
          select empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator 
        		   , isnull(sum(Сумма) ,0)
           from agg
          group by dt, indicator  

				RETURN 0
			END
        end
		--// 'TS.Monthly.Rework'

        
		IF @Page = 'TS.Daily.AR' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
          begin
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_AR
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_AR AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'AR на этапе' Indicator
					, Одобрено
					, ИтогоПоСотруднику
						, case when ИтогоПоСотруднику<>0 then Одобрено*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #TSEmployees e
				left join #ReportByEmployeeAgg_TS a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_AR
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) *100
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Daily_AR
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(
						case when sum(ИтогоПоСотруднику) <>0 then sum(Одобрено*1.0)/ sum(ИтогоПоСотруднику) else 0 end 
						,0)  *100 Сумма
				from agg
				group by dt, indicator
				--*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Daily.AR', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'AR на этапе' Indicator
               , Одобрено
               , ИтогоПоСотруднику
        		   , case when ИтогоПоСотруднику<>0 then Одобрено*1.0/ИтогоПоСотруднику else 0 end Сумма
            from #TSEmployees e
           left join #ReportByEmployeeAgg_TS a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           )
          select empl_id
        	     , Employee
               , dt
               , Indicator
               , Сумма=isnull(Сумма,0) *100
            from agg
        union all
          select empl_id    = isnull((select max(empl_id) from #TSEmployees  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator 
        		   , isnull(
                        case when sum(ИтогоПоСотруднику) <>0 then sum(Одобрено*1.0)/ sum(ИтогоПоСотруднику) else 0 end 
                       ,0)  *100 Сумма
           from agg
          group by dt, indicator
          
				RETURN 0
			END
		END
		--// 'TS.Daily.AR'
        
--Monthly
		IF @Page = 'TS.Monthly.AR' OR @isFill_All_Tables = 1 --2402
		BEGIN
			IF @isFill_All_Tables = 1
          begin
				--Датасет не используется
				--/*
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_AR
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_AR AS T WHERE T.ProcessGUID = @ProcessGUID
        
				;with agg as (
				select empl_id
						, Employee		
						, acc_period  dt
						, 'AR на этапе' Indicator
					, Одобрено
					, ИтогоПоСотруднику
						, case when ИтогоПоСотруднику<>0 then Одобрено*1.0/ИтогоПоСотруднику else 0 end Сумма
				from #TSEmployees_m e
				left join #ReportByEmployeeAgg_TS_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
				)
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_AR
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id
					, Employee
					, dt
					, Indicator
					, Сумма=isnull(Сумма,0) *100
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_TS_Monthly_AR
				from agg
				union all
				SELECT
					ProcessGUID = @ProcessGUID,
					empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
					, Employee		='ИТОГО' 
					, dt 
					, indicator 
					, isnull(
						case when sum(ИтогоПоСотруднику) <>0 then sum(Одобрено*1.0)/ sum(ИтогоПоСотруднику) else 0 end 
						,0)  *100 Сумма
				from agg
				group by dt, indicator
				--*/
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'TS.Monthly.AR', @ProcessGUID
			END
			ELSE BEGIN
				;with agg as (
          select empl_id
        		   , Employee		
        		   , acc_period  dt
        		   , 'AR на этапе' Indicator
               , Одобрено
               , ИтогоПоСотруднику
        		   , case when ИтогоПоСотруднику<>0 then Одобрено*1.0/ИтогоПоСотруднику else 0 end Сумма
            from #TSEmployees_m e
           left join #ReportByEmployeeAgg_TS_m a on e.acc_period=a.Дата and e.Employee=a.Сотрудник
           )
          select empl_id
        	     , Employee
               , dt
               , Indicator
               , Сумма=isnull(Сумма,0) *100
            from agg
        union all
          select empl_id    = isnull((select max(empl_id) from #TSEmployees_m  ),0)+ 1
               , Employee		='ИТОГО' 
        		   , dt 
        		   , indicator 
        		   , isnull(
                        case when sum(ИтогоПоСотруднику) <>0 then sum(Одобрено*1.0)/ sum(ИтогоПоСотруднику) else 0 end 
                       ,0)  *100 Сумма
           from agg
          group by dt, indicator
          
				RETURN 0
			END
        END
        --// 'TS.Monthly.AR'
        
        end
--// TS.%




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
) OR @isFill_All_Tables = 1
begin
  drop table if exists #indicator_for_controldata
  create table #indicator_for_controldata(
         [num_rows] numeric(6,2) NULL --int null 
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
       , (4.04 ,'Параллельный')
       , (4.05 ,'Не определен')
     , (5 ,'Общее кол-во заявок на этапе')
       , (6, 'TTY  - количество заявок рассмотренных в течение 6 минут на этапе')
       , (7 ,'TTY  - % заявок рассмотренных в течение 6 минут на этапе')
       , (10 ,'Среднее время заявки в ожидании очереди на этапе')
       , (12 ,'Средний Processing time на этапе (время обработки заявки)')
       , (15 ,'Кол-во одобренных заявок после этапа')
       , (18 ,'Кол-во отказов со стороны сотрудников')
       , (21 ,'Approval rate - % одобренных после этапа')
       , (25 ,'Общее кол-во отложенных заявок на этапе')
	   , (26 ,'Уникальное кол-во отложенных заявок на этапе')
       , (28 ,'Кол-во заявок на этапе, отправленных на доработку')
       , (29 ,'Уникальное количество доработок на этапе')
        


------- всп.таблица показатели для статусов (Общий лист)
    drop table if exists #indicator_for_vc_va
    create table #indicator_for_vc_va (
           [num_rows] numeric(6,2) --null 
         , [name_indicator] nvarchar(250) null
         )
  insert into #indicator_for_vc_va([num_rows] ,[name_indicator])
  values (1 ,'Общее кол-во заведенных заявок Call2')
       , (2 ,'Кол-во автоматических отказов Call2')
       , (3 ,'%  автоматических отказов Call2')

       --, (4 ,'Общее кол-во уникальных заявок на этапе')
       --, (4.01 ,'Первичный')
       --, (4.02 ,'Повторный')
       --, (4.03 ,'Докредитование')
       --, (4.04 ,'Параллельный')
       --, (4.05 ,'Не определен')

       , (4.1 ,'Общее кол-во уникальных заявок на этапе Вериф.клиента')
       , (4.11 ,'Первичный ВК')
       , (4.12 ,'Повторный ВК')
       , (4.13 ,'Докредитование ВК')
       , (4.14 ,'Параллельный ВК')
       , (4.15 ,'Не определен ВК')

       , (4.2 ,'Общее кол-во уникальных заявок на этапе Вериф.ТС')
       , (4.21 ,'Первичный ВТС')
       , (4.22 ,'Повторный ВТС')
       , (4.23 ,'Докредитование ВТС')
       , (4.24 ,'Параллельный ВТС')
       , (4.25 ,'Не определен ВТС')

       , (4.3 ,'Общее кол-во уникальных заявок на этапе Верифик.')

       , (5 ,'Общее кол-во заявок на этапе')
       , (8 ,'TTY  - % заявок рассмотренных в течение 21 минут на этапе')
       , (9 ,'TTY  - % заявок рассмотренных в течение 3-х минут на этапе')
       , (10 ,'TTY  - количество заявок рассмотренных в течение 30 минут на этапах КД, ВК, ВТС')
       , (12 ,'TTY  - % заявок рассмотренных в течение 30 минут на этапах КД,ВК,ВТС')
       , (20 ,'Среднее время заявки в ожидании очереди на этапе')
       , (22 ,'Средний Processing time на этапе (время обработки заявки)')
       , (25 ,'Кол-во одобренных заявок после этапа')
       , (28 ,'Кол-во отказов со стороны сотрудников')
       , (31 ,'Approval rate - % одобренных после этапа')
       , (34 ,'Approval rate % Логином')

       , (35 ,'Контактность общая')
       , (36 ,'Контактность по одобренным')
       , (37 ,'Контактность по отказным')

       , (38 ,'Общее кол-во отложенных заявок на этапе')
	   , (39 ,'Уникальное кол-во отложенных заявок на этапе')
       , (40 ,'Кол-во заявок на этапе, отправленных на доработку')
       , (41 ,'Уникальное количество доработок на этапе')
       , (43 ,'Take rate Уровень выдачи, выраженный через одобрения')
       , (44 ,'Кол-во заявок в статусе "Займ выдан",шт.')
       --DWH-2309
       , (45, 'Кол-во уникальных заявок в статусе Договор подписан')

	   , (49 ,'Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.')
	   , (50, '% заявок, не вернувшихся из отложенных на этапе  Вериф.')

--
-- Общее количество заведенных заявок
--


/*

 select [Дата заведения заявки],count(distinct [Номер заявки]) 
 
	 from #t_dm_FedorVerificationRequests_AutocredVTB
 group by [Дата заведения заявки]
 order by  [Дата заведения заявки]

select *
from #employee_rows_d where status='Верификация клиента'

select distinct  name_indicator
from #employee_rows_d where status='Верификация клиента'

exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Daily.Common'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'V.Daily.Common' 

exec Reports.dbo.Report_verification_fedor_AutocredVTB 'KD.Monthly.Common'
exec Reports.dbo.Report_verification_fedor_AutocredVTB 'V.Monthly.Common'


*/


	IF @Page = 'KD.HoursGroupDaysUnique' OR @isFill_All_Tables = 1 --241
	BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupDaysUnique
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupDaysUnique AS T WHERE T.ProcessGUID = @ProcessGUID

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
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupDaysUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupDaysUnique
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

				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.HoursGroupDaysUnique', @ProcessGUID
			END
			ELSE BEGIN
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

				RETURN 0
			END
	END
	--// 'KD.HoursGroupDaysUnique'

	IF @Page = 'KD.HoursGroupDays' OR @isFill_All_Tables = 1 --241
	BEGIN
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupDays
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupDays AS T WHERE T.ProcessGUID = @ProcessGUID

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
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupDays
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupDays
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

				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.HoursGroupDays', @ProcessGUID
			END
			ELSE BEGIN
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

				RETURN 0
			END
	END
	--// 'KD.HoursGroupDays'


	IF @Page = 'KD.HoursGroupMonthUnique' OR @isFill_All_Tables = 1 --241
	BEGIN
			IF @isFill_All_Tables = 1
  begin
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupMonthUnique
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupMonthUnique AS T WHERE T.ProcessGUID = @ProcessGUID

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
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupMonthUnique
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, hd.ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupMonthUnique
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
           
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.HoursGroupMonthUnique', @ProcessGUID
			END
			ELSE BEGIN
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

				RETURN 0
		end
	END
	--// 'KD.HoursGroupMonthUnique'


    -- Лист "КД. Общее количество по часам"
	IF @Page = 'KD.HoursGroupMonth' OR @isFill_All_Tables = 1 --241
  begin
			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupMonth
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupMonth AS T WHERE T.ProcessGUID = @ProcessGUID

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
				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupMonth
				SELECT
					ProcessGUID = @ProcessGUID,
					isnull(КоличествоЗаявок,0) КоличествоЗаявок , hd.Интервал, hd.Дата, ИнтервалСтрока
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_HoursGroupMonth
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
           
				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.HoursGroupMonth', @ProcessGUID
			END
			ELSE BEGIN
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

				RETURN 0
			END
   end
	--// 'KD.HoursGroupMonth'

	IF @Page = 'KD.Daily.Common' OR @isFill_All_Tables = 1
begin

		DROP table if exists #waitTime

		;with r AS (
select 

[Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
--, [Дата статуса]=case when  cast([Дата статуса] as time)>'07:00' and cast([Дата статуса] as time)<='22:00' then [Дата статуса] 
--                 else 
--                      case when  cast([Дата статуса] as time)>'22:00' and cast([Дата статуса] as time)<='23:59:59' then
--                           cast(format(dateadd(day,1,cast([Дата статуса] as date)),'yyyyMMdd 07:00') as datetime) 
--                      else
--                           cast(format([Дата статуса] ,'yyyyMMdd 07:00') as datetime) 
--                      end
--                 end
--, [Дата след.статуса] =case when  cast([Дата след.статуса] as time)>'07:00' and cast([Дата след.статуса] as time)<='22:00' then [Дата след.статуса]
--                 else 
--                      case when  cast([Дата след.статуса] as time)>'22:00' and cast([Дата след.статуса] as time)<='23:59:59' then
--                           cast(format(dateadd(day,1,cast([Дата след.статуса] as date)),'yyyyMMdd 07:00') as datetime) 
--                      else
--                           cast(format([Дата след.статуса],'yyyyMMdd 07:00') as datetime) 
--                      end
--                 end
, [Дата статуса]
, [Дата след.статуса]


,Работник [ФИО сотрудника верификации/чекер]
, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику],  [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]

from #t_dm_FedorVerificationRequests_AutocredVTB r
where [Состояние заявки]='Ожидание' 
	AND r.Статус='Контроль данных' 
	--DWH-2019
	AND NOT (
		r.Задача='task:Новая'
		AND r.[Задача следующая] = 'task:Автоматически отложено'
	)

	--AND [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to 
	AND 
 (Работник in (select e.Employee from #KDEmployees e)
	-- для учета, когда ожидание назначено на сотрудника
	OR Назначен in (select e.Employee from #KDEmployees e)
 )
)
select [Дата статуса]=cast([Дата статуса] as date) 
   --  , [Номер заявки]
     ,  avg( datediff(second,[Дата статуса], [Дата след.статуса]))   duration
  into #waitTime
  from r
  where  datediff(second,[Дата статуса], [Дата след.статуса])>0
 group by cast([Дата статуса] as date)-- ,[Номер заявки]
 
 --select * from #waitTime

-- ;with r2 as
--(
--select 

--[Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
----, [Дата статуса]=case when  cast([Дата статуса] as time)>'07:00' and cast([Дата статуса] as time)<='22:00' then [Дата статуса] 
----                 else 
----                      case when  cast([Дата статуса] as time)>'22:00' and cast([Дата статуса] as time)<='23:59:59' then
----                           cast(format(dateadd(day,1,cast([Дата статуса] as date)),'yyyyMMdd 07:00') as datetime) 
----                      else
----                           cast(format([Дата статуса] ,'yyyyMMdd 07:00') as datetime) 
----                      end
----                 end
----, [Дата след.статуса] =case when  cast([Дата след.статуса] as time)>'07:00' and cast([Дата след.статуса] as time)<='22:00' then [Дата след.статуса]
----                 else 
----                      case when  cast([Дата след.статуса] as time)>'22:00' and cast([Дата след.статуса] as time)<='23:59:59' then
----                           cast(format(dateadd(day,1,cast([Дата след.статуса] as date)),'yyyyMMdd 07:00') as datetime) 
----                      else
----                           cast(format([Дата след.статуса],'yyyyMMdd 07:00') as datetime) 
----                      end
----                 end
--, [Дата статуса]
--, [Дата след.статуса]

--,Работник [ФИО сотрудника верификации/чекер]
--, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику],  [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]

		-- from #t_dm_FedorVerificationRequests_AutocredVTB r
-- where [Состояние заявки]='Ожидание' and r.Статус='Контроль данных' and cast([Дата статуса] as date) = '2021-03-20' -- >@dt_from and  [Дата статуса]<@dt_to 
-- and Работник in (select e.Employee from #KDEmployees e)
--)
-- select * from r2

 drop table if exists #verif_KC

 select [Дата статуса]=cast([Дата статуса] as date) 
      , count(distinct [Номер заявки]) cnt
 into #verif_KC
 from #t_dm_FedorVerificationRequests_AutocredVTB r 
 where 1=1
	--and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
  and  Статус='Верификация КЦ' and [Статус следующий]='Отказано'
group by cast([Дата статуса] as date) 
 

 -- считаем уникальных отложенных по КД
        drop table if exists #ReportByEmployeeAgg_KD_UniquePostone

        ;with c1 as (
          select Дата
              -- , Сотрудник   
               --, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
			    , isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальныеKD]
               
            from #fedor_verificator_report
			--DWH-1806
			where Сотрудник in (select * from #curr_employee_cd)
			--01.01 не рабочий день, данные за этот день не учитываем
			and Дата != datefromparts(year(Дата), 1,1)
           group by Дата
              -- , Сотрудник
        )        
          select c1.*              
            into #ReportByEmployeeAgg_KD_UniquePostone
            from c1 
            

			  -- посчитаем количество уникальных отложенных КД теперь и по дням
 drop table if exists #postpone_unique_kd_daily
 
 select 
	[Дата статуса]=cast(([Дата]) as date),
	sum(p.ОтложенаУникальныеKD) ОтложенаУникальныеKD 
 into #postpone_unique_kd_daily
from #ReportByEmployeeAgg_KD_UniquePostone p
 group by cast(([Дата]) as date)



  drop table if exists #all_requests
  
  select [Дата заведения заявки] 
       , count(distinct [Номер заявки]) Qty 
    into #all_requests
    from #t_dm_FedorVerificationRequests_AutocredVTB
    join #calendar c on c.dt_day=[Дата заведения заявки]
    where  1=1
		--and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
   group by [Дата заведения заявки] 

   --select * from #all_requests
   -- TTY
		--IF @isDebug = 1 BEGIN
		--	DROP TABLE IF EXISTS ##all_requests
		--	SELECT * INTO ##all_requests FROM #all_requests

		--	DROP TABLE IF EXISTS ##calendar
		--	SELECT * INTO ##calendar FROM #calendar
		--END
   
   drop table if exists #tty_kd

   select Дата
        , [Номер заявки]
        , Сотрудник
        , [ФИО сотрудника верификации/чекер]
        --, ВремяЗатрачено
        , cast(cast(ВремяЗатрачено as datetime) as time) ВремяЗатрачено
        , case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:06:00' then '-' else 'tty' end tty_flag
     into #tty_kd
     from #fedor_verificator_report where status='task:В работе'



    drop table if exists #p 
  
  select d.Дата
		, d.[Общее кол-во заявок на этапе]								
		, d.[Кол-во одобренных заявок после этапа]						
		, d.[Общее кол-во отложенных заявок на этапе]					
		, d.[Кол-во заявок на этапе, отправленных на доработку]			
		, d.[Уникальное количество доработок на этапе]
		, d.[Approval rate - % одобренных после этапа]					
		, d.[Кол-во отказов со стороны сотрудников]						
		, d.[Средний Processing time на этапе (время обработки заявки)]
       , [Общее кол-во заведенных заявок] = cast(format(r.Qty,'0') as nvarchar(50))
       , [Среднее время заявки в ожидании очереди на этапе] = cast(
      format(w.duration/60/60 ,'00')+N':'+format( (duration/60 -  60* (duration/60/60)),'00') +N':'+format((w.duration - 60 * (duration/60)),'00')
  as nvarchar(50)) 
	, new.[Общее кол-во уникальных заявок на этапе]
	, new.[Первичный]
	, new.[Повторный]
	, new.[Докредитование]
	, new.[Параллельный]
	, new.[Не определен]

  , [TTY  - количество заявок рассмотренных в течение 6 минут на этапе] = cast(tty.cnt as nvarchar(50))
  , [TTY  - % заявок рассмотренных в течение 6 минут на этапе] = cast(format(case when [Общее кол-во заявок на этапе]<>0 then 100*tty.cnt*1.0/[Общее кол-во заявок на этапе] else 0 end,'0')+N'%' as nvarchar(50))
  , [Кол-во автоматических отказов Логином] = cast(kc.cnt as nvarchar(50))
  , [%  автоматических отказов Логином] = cast(case when r.Qty<>0 then  format(100.0*kc.cnt/r.Qty,'0') else '0' end +N'%' as nvarchar(50))
  , [Уникальное кол-во отложенных заявок на этапе] = cast(format((u.ОтложенаУникальныеKD),'0') as nvarchar(50))
into #p
from (
    select Дата
         , [Общее кол-во заявок на этапе]								= cast(format(sum(a.КоличествоЗаявок),'0') as nvarchar(50))
         , [Кол-во одобренных заявок после этапа]						= cast(format(sum([ВК]),'0')as nvarchar(50))
         , [Общее кол-во отложенных заявок на этапе]					= cast(format(sum(Отложена),'0') as nvarchar(50))

         , [Кол-во заявок на этапе, отправленных на доработку]			= cast(format(sum(Доработка),'0') as nvarchar(50))
         , [Уникальное количество доработок на этапе] = cast(format(sum([Доработка уникальных]),'0') as nvarchar(50))
         , [Approval rate - % одобренных после этапа]					= cast(format(isnull(case when sum(ИтогоПоСотруднику) <>0 then sum(ВК*1.0)/ sum(  ИтогоПоСотруднику) else 0 end ,0)  *100,'0')+N'%' as nvarchar(50)) 
         , [Кол-во отказов со стороны сотрудников]						= cast(format(sum([Отказано]),'0')as nvarchar(50))       
		 , [Средний Processing time на этапе (время обработки заявки)] = cast(isnull(convert(nvarchar,cast((case when sum(КоличествоЗаявок)<>0 then  sum(ВремяЗатрачено)/sum(КоличествоЗаявок) else 0 end) as datetime),8)  ,0) as nvarchar(50))
      
      from #ReportByEmployeeAgg a
      where Сотрудник in (select * from #curr_employee_cd)
	  --01.01 не рабочий день, данные за этот день не учитываем
	  and Дата != DATEFROMPARTS(year(Дата), 1,1)
     group by Дата
) d 
left join (
    select Дата
         , cast(format(sum(Новая_Уникальная),'0')as nvarchar(50)) [Общее кол-во уникальных заявок на этапе] --DWH-2020
		--DWH-2286
		, cast(format(sum([Новая_Уникальная Первичный]),'0')as nvarchar(50)) [Первичный]
		, cast(format(sum([Новая_Уникальная Повторный]),'0')as nvarchar(50)) [Повторный]
		, cast(format(sum([Новая_Уникальная Докредитование]),'0')as nvarchar(50)) [Докредитование]
		, cast(format(sum([Новая_Уникальная Параллельный]),'0')as nvarchar(50)) [Параллельный]
		, cast(format(sum([Новая_Уникальная Не определен]),'0')as nvarchar(50)) [Не определен]
      from #ReportByEmployeeAgg a
	  --01.01 не рабочий день, данные за этот день не учитываем
	  where Дата != DATEFROMPARTS(year(Дата), 1,1)
     group by Дата

) new on new.Дата=d.Дата

join #all_requests r on r.[Дата заведения заявки] = d.Дата
left join #waitTime w on w.[Дата статуса]=d.Дата
left join #postpone_unique_kd_daily u on u.[Дата статуса] = d.Дата
left join (
    select дата
         , count([Номер заявки]) cnt
      -- , ВремяЗатрачено 
      from #tty_kd
    where tty_flag='tty'
    group by  дата 

) tty on tty.Дата=d.Дата
left join #verif_KC kc on kc.[Дата статуса]=d.Дата
--select * from #p

     drop table if exists #unp

  select Дата, indicator, Qty 
    into #unp
    from 
    (
    select Дата
         , [Общее кол-во заведенных заявок]
         , [Кол-во автоматических отказов Логином]
         , [%  автоматических отказов Логином]
         , [Общее кол-во уникальных заявок на этапе]
		, [Первичный]
		, [Повторный]
		, [Докредитование]
		, [Параллельный]
		, [Не определен]
         , [Общее кол-во заявок на этапе]
         , [TTY  - количество заявок рассмотренных в течение 6 минут на этапе]
         , [TTY  - % заявок рассмотренных в течение 6 минут на этапе]
         , [Среднее время заявки в ожидании очереди на этапе]
         , [Средний Processing time на этапе (время обработки заявки)]
         , [Кол-во одобренных заявок после этапа]
         , [Кол-во отказов со стороны сотрудников]
         , [Approval rate - % одобренных после этапа]
         , [Общее кол-во отложенных заявок на этапе]		  
         , [Кол-во заявок на этапе, отправленных на доработку]
		 , [Уникальное количество доработок на этапе]
		 , [Уникальное кол-во отложенных заявок на этапе]
      from #p
     
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
						, [Параллельный]
						, [Не определен]
                         ,[Общее кол-во заявок на этапе]
                         ,[TTY  - количество заявок рассмотренных в течение 6 минут на этапе]
                         ,[TTY  - % заявок рассмотренных в течение 6 минут на этапе]
                         ,[Среднее время заявки в ожидании очереди на этапе]
                         ,[Средний Processing time на этапе (время обработки заявки)]
                         ,[Кол-во одобренных заявок после этапа]
                         ,[Кол-во отказов со стороны сотрудников]
                         ,[Approval rate - % одобренных после этапа]
                         ,[Общее кол-во отложенных заявок на этапе]
                         ,[Кол-во заявок на этапе, отправленных на доработку]
						 ,[Уникальное количество доработок на этапе]
						 , [Уникальное кол-во отложенных заявок на этапе]
                        )
   ) as unpvt

		IF @isFill_All_Tables = 1
		BEGIN
			--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Common
			DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Common AS T WHERE T.ProcessGUID = @ProcessGUID

			INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Common
			SELECT
				ProcessGUID = @ProcessGUID,
				i.num_rows 
				--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
        , empl_id =null
	      , Employee =null
        , acc_period =Дата
        , indicator =name_indicator
        , [Сумма] =null
	      , Qty
	      , Qty_dist=null
	      , Tm_Qty =null--isnull(Tm_Qty,0.00)
			--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Daily_Common
    from #unp u 
    join #indicator_for_controldata i on u.indicator=i.name_indicator
			--ORDER BY i.num_rows

			INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'KD.Daily.Common', @ProcessGUID

end
		ELSE BEGIN
			SELECT
				i.num_rows 
				--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
				, empl_id =null
				  , Employee =null
				, acc_period =Дата
				, indicator =name_indicator
				, [Сумма] =null
				, Qty
				, Qty_dist=null
				, Tm_Qty =null--isnull(Tm_Qty,0.00)
			from #unp u 
			join #indicator_for_controldata i on u.indicator=i.name_indicator
			--ORDER BY i.num_rows

			RETURN 0
		END
	END
	--// 'KD.Daily.Common'


	IF @page= 'V.Daily.Common' OR @isFill_All_Tables = 1 
	BEGIN
   drop table if exists #tty_vk

   select Дата
        , [Номер заявки]
        , Сотрудник
        , [ФИО сотрудника верификации/чекер]
        --, ВремяЗатрачено
        , cast(cast(ВремяЗатрачено as datetime) as time) ВремяЗатрачено
        , case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:21:00' then '-' else 'tty' end tty_flag
     into #tty_vk
     from #fedor_verificator_report_vk where status='task:В работе'


-- Пришло на call2
 drop table if exists #call2


 select [Дата статуса]=cast([Дата статуса] as date)
      , count(distinct [Номер заявки]) Qty
      , sum(case when [Статус следующий]='Отказано' then 1 else 0 end) Qty_rejected
 into #call2
 from #t_dm_FedorVerificationRequests_AutocredVTB r 
 where Статус ='Верификация Call 2'  
	--and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
 group by cast([Дата статуса] as date)


  drop table if exists #waitTime_v

		 ;with r as
(
select 

[Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
--, [Дата статуса]=case when  cast([Дата статуса] as time)>'07:00' and cast([Дата статуса] as time)<='22:00' then [Дата статуса] 
--                 else 
--                      case when  cast([Дата статуса] as time)>'22:00' and cast([Дата статуса] as time)<='23:59:59' then
--                           cast(format(dateadd(day,1,cast([Дата статуса] as date)),'yyyyMMdd 07:00') as datetime) 
--                      else
--                           cast(format([Дата статуса] ,'yyyyMMdd 07:00') as datetime) 
--                      end
--                 end
--, [Дата след.статуса] =case when  cast([Дата след.статуса] as time)>'07:00' and cast([Дата след.статуса] as time)<='22:00' then [Дата след.статуса]
--                 else 
--                      case when  cast([Дата след.статуса] as time)>'22:00' and cast([Дата след.статуса] as time)<='23:59:59' then
--                           cast(format(dateadd(day,1,cast([Дата след.статуса] as date)),'yyyyMMdd 07:00') as datetime) 
--                      else
--                           cast(format([Дата след.статуса],'yyyyMMdd 07:00') as datetime) 
--                      end
--                 end
, [Дата статуса]
, [Дата след.статуса]


, Работник [ФИО сотрудника верификации/чекер]
, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику], [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]

		 from #t_dm_FedorVerificationRequests_AutocredVTB r
  where [Состояние заявки]='Ожидание'
	AND r.Статус='Верификация клиента' 
	--DWH-2019
	AND NOT (
		r.Задача='task:Новая'
		AND r.[Задача следующая] = 'task:Автоматически отложено'
	)

	--AND [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to

	AND (Работник in (select e.Employee from #VKEmployees e)
   -- для учета, когда ожидание назначено на сотрудника
 or Назначен in (select e.Employee from #VKEmployees e))
)
  select [Дата статуса]=cast([Дата статуса] as date) 
   --  , [Номер заявки]
       , avg( datediff(second,[Дата статуса], [Дата след.статуса]))  duration
    into #waitTime_v
    from  r
   where  datediff(second,[Дата статуса], [Дата след.статуса])>0
   group by cast([Дата статуса] as date)-- ,[Номер заявки]
 
  -- посчитаем количество уникальных отложенных VK теперь и по дням
 drop table if exists #postpone_unique_vk_daily
 select 
	[Дата статуса]=cast(([Дата]) as date),
	sum(p.ОтложенаУникальныеVK) ОтложенаУникальныеVK 
 into #postpone_unique_vk_daily
from #ReportByEmployeeAgg_VK_UniquePostone p
 group by cast(([Дата]) as date)


	drop table if exists #НеВернувшиесяИзОтложенных_vk_daily
	select 
		[Дата статуса] = cast([Дата] as date),
		НеВернувшиесяИзОтложенныхVK = isnull(count(distinct case when status='НеВернувшиесяИзОтложенных' then [Номер заявки]  end),0)
	into #НеВернувшиесяИзОтложенных_vk_daily
	from #fedor_verificator_report_VK
	group by cast([Дата] as date)

   
 --select * from #waitTime_v
drop table if exists #p_VK 
select d.* 
, [Среднее время заявки в ожидании очереди на этапе Вериф.клиента] =
	isnull(
		cast(
			format(w.duration/60/60 ,'00')+N':'+format( (w.duration/60 -  60* (w.duration/60/60)),'00') +N':'+format((w.duration - 60 * (duration/60)),'00')
			as nvarchar(50)
		),'00:00:00'
	)
      , new.[Общее кол-во уникальных заявок на этапе Вериф.клиента]  
	, new.[Первичный ВК]
	, new.[Повторный ВК]
	, new.[Докредитование ВК]
	, new.[Параллельный ВК]
	, new.[Не определен ВК]
       , [Общее кол-во заведенных заявок Call2]                                        = cast(format(call2.Qty,'0') as nvarchar(50))
       , [Кол-во автоматических отказов Call2]                                         = cast(format(call2.Qty_rejected,'0') as nvarchar(50))
       , [%  автоматических отказов Call2]                                             = cast(format(case when call2.Qty<>0 then 100.0*call2.Qty_rejected/call2.Qty else 0 end,'0.0')+N'%' as nvarchar(50))
       , [TTY  - % заявок рассмотренных в течение 21 минут на этапе Вериф.клиента]     =
       case when [Общее кол-во заявок на этапе Вериф.клиента]<>0 then 
       cast(format(case when  [Общее кол-во заявок на этапе Вериф.клиента]<>0 then 100.0*tty.cnt/ [Общее кол-во заявок на этапе Вериф.клиента] else 0 end,'0.0')+N'%' as nvarchar(50))
    else '0%' end
	, [Уникальное кол-во отложенных заявок на этапе Вериф.клиента]                       = cast(format((u.ОтложенаУникальныеVK),'0') as nvarchar(50))
	, [Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.клиента]               = cast(format((u2.НеВернувшиесяИзОтложенныхVK),'0') as nvarchar(50))
	, Contact.[Контактность общая]
	, Contact.[Контактность по одобренным]
	, Contact.[Контактность по отказным]
	,[Кол-во уникальных заявок в статусе Договор подписан] = cast(format(ДоговорПодписан.cnt,'0') as nvarchar(50))
into #p_VK 
from(
  select Дата
       , [Общее кол-во заявок на этапе Вериф.клиента]                                  = cast(format(sum(КоличествоЗаявок),'0') as nvarchar(50))
       , [TTY  - % заявок рассмотренных в течение 3-х минут на этапе Вериф.ТС]         = cast('' as nvarchar(50))
	  , [TTY  - количество заявок рассмотренных в течение 30 минут на этапах КД, ВК, ВТС] = cast('' as nvarchar(50))
	  , [TTY  - % заявок рассмотренных в течение 30 минут на этапах КД,ВК,ВТС]= cast('' as nvarchar(50))

       , [Средний Processing time на этапе (время обработки заявки) Вериф.клиента]     = case when sum(КоличествоЗаявок)<>0 then
                                                                                          cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
                                                                                          else '0'
                                                                                          end
       , [Кол-во одобренных заявок после этапа Вериф.клиента]                          = cast(format(sum([VTS]),'0')as nvarchar(50))
       , [Кол-во отказов со стороны сотрудников Вериф.клиента]                         = cast(format(sum([Отказано]),'0')as nvarchar(50)) 
       , [Approval rate - % одобренных после этапа Вериф.клиента]                      = case when sum(  ИтогоПоСотруднику)<>0 then 
                                                                                          cast(format(isnull(case when sum(ИтогоПоСотруднику) <>0 then sum(VTS*1.0)/ sum(  ИтогоПоСотруднику) else 0 end ,0)  *100,'0') +N'%' as nvarchar(50))
                                                                                         else '0'
                                                                                         end
       , [Approval rate % Логином]                                                     = cast('' as nvarchar(50))
       , [Общее кол-во отложенных заявок на этапе Вериф.клиента]                       = cast(format(sum(Отложена),'0') as nvarchar(50))
       , [Кол-во заявок на этапе, отправленных на доработку Вериф.клиента]             = cast(format(sum(Доработка),'0') as nvarchar(50))
       , [Уникальное количество доработок на этапе Вериф.клиента] = cast(format(sum([Доработка уникальных]),'0') as nvarchar(50))

       , [Take rate Уровень выдачи, выраженный через одобрения]                        = cast('' as nvarchar(50))
       , [Кол-во заявок в статусе "Займ выдан",шт.]                                    = cast('' as nvarchar(50))
    
    from #ReportByEmployeeAgg_VK where сотрудник in (select * from #curr_employee_vr)
   
   group by Дата
  )d
  join ( select Дата
       , [Общее кол-во уникальных заявок на этапе Вериф.клиента] = cast(format(sum(Новая_Уникальная),'0')as nvarchar(50)) --DWH-2020
		--DWH-2286
		, [Первичный ВК] = cast(format(sum([Новая_Уникальная Первичный]),'0')as nvarchar(50))
		, [Повторный ВК] = cast(format(sum([Новая_Уникальная Повторный]),'0')as nvarchar(50))
		, [Докредитование ВК] = cast(format(sum([Новая_Уникальная Докредитование]),'0')as nvarchar(50))
		, [Параллельный ВК] = cast(format(sum([Новая_Уникальная Параллельный]),'0')as nvarchar(50))
		, [Не определен ВК] = cast(format(sum([Новая_Уникальная Не определен]),'0')as nvarchar(50))
    from #ReportByEmployeeAgg_VK
   group by Дата
  ) new on new.Дата=d.Дата
 left join #waitTime_v w on w.[Дата статуса]=d.Дата
 left join #postpone_unique_vk_daily u on u.[Дата статуса] = d.Дата
 LEFT JOIN #НеВернувшиесяИзОтложенных_vk_daily AS u2 on u2.[Дата статуса] = d.Дата
 left join #call2 call2 on call2.[Дата статуса]=d.Дата
 left join (
    select дата
         , count([Номер заявки]) cnt
      -- , ВремяЗатрачено 
      from #tty_vk
    where tty_flag='tty'
    group by  дата 

) tty on tty.Дата=d.Дата

	LEFT JOIN #t_Contact_Day AS Contact
		ON Contact.[Дата статуса] = d.Дата

	--DWH-2309
	LEFT JOIN (
		SELECT ДатаСтатуса = cast(D.[Дата статуса] AS date),
				cnt = count(DISTINCT D.[Номер заявки])
		from #t_dm_FedorVerificationRequests_AutocredVTB AS D
		WHERE 1=1
			--AND D.[Дата статуса] > @dt_from AND  D.[Дата статуса] < @dt_to
			AND D.Статус IN ('Договор подписан')
		GROUP BY cast(D.[Дата статуса] AS date)
	) AS ДоговорПодписан
	ON ДоговорПодписан.ДатаСтатуса = d.Дата

drop table if exists #waitTime_v_tc
 
		;with r as
(
select 

[Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
--, [Дата статуса]=case when  cast([Дата статуса] as time)>'07:00' and cast([Дата статуса] as time)<='22:00' then [Дата статуса] 
--                 else 
--                      case when  cast([Дата статуса] as time)>'22:00' and cast([Дата статуса] as time)<='23:59:59' then
--                           cast(format(dateadd(day,1,cast([Дата статуса] as date)),'yyyyMMdd 07:00') as datetime) 
--                      else
--                           cast(format([Дата статуса] ,'yyyyMMdd 07:00') as datetime) 
--                      end
--                 end
--, [Дата след.статуса] =case when  cast([Дата след.статуса] as time)>'07:00' and cast([Дата след.статуса] as time)<='22:00' then [Дата след.статуса]
--                 else 
--                      case when  cast([Дата след.статуса] as time)>'22:00' and cast([Дата след.статуса] as time)<='23:59:59' then
--                           cast(format(dateadd(day,1,cast([Дата след.статуса] as date)),'yyyyMMdd 07:00') as datetime) 
--                      else
--                           cast(format([Дата след.статуса],'yyyyMMdd 07:00') as datetime) 
--                      end
--                 end
, [Дата статуса]
, [Дата след.статуса]


, Работник [ФИО сотрудника верификации/чекер]
, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику], [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]

		 from #t_dm_FedorVerificationRequests_AutocredVTB r
  where [Состояние заявки]='Ожидание' 
	AND r.Статус='Верификация ТС' 
	--DWH-2019
	AND NOT (
		r.Задача='task:Новая'
		AND r.[Задача следующая] = 'task:Автоматически отложено'
	)

	--AND [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to 

	AND (Работник in (select e.Employee from #TSEmployees e)
     -- для учета, когда ожидание назначено на сотрудника
 or Назначен in (select e.Employee from #TSEmployees e))
)

select [Дата статуса]=cast([Дата статуса] as date) 
   --  , [Номер заявки]
     , avg( datediff(second,[Дата статуса], [Дата след.статуса]))  duration
  into #waitTime_v_tc
   
  from  r
where  datediff(second,[Дата статуса], [Дата след.статуса])>0
 group by cast([Дата статуса] as date)-- ,[Номер заявки]
 
--ТС

 drop table if exists #tty_ts

   select Дата
        , [Номер заявки]
        , Сотрудник
        , [ФИО сотрудника верификации/чекер]
        --, ВремяЗатрачено
        , cast(cast(ВремяЗатрачено as datetime) as time) ВремяЗатрачено
        , case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:03:00' then '-' else 'tty' end tty_flag
     into #tty_ts
     from #fedor_verificator_report_ts where status='task:В работе'


	--DWH-2653
	DROP table if exists #tty_ts2
	select B.Дата
        , B.[Номер заявки]
        --, Сотрудник
        --, [ФИО сотрудника верификации/чекер]
        --, ВремяЗатрачено
        , cast(cast(B.ВремяЗатрачено as datetime) as time) AS ВремяЗатрачено
        , case when cast(cast(B.ВремяЗатрачено as datetime) as time)>'00:30:00' then '-' else 'tty' end AS tty_flag
	into #tty_ts2
	from (
		select 
			A.Дата
			, A.[Номер заявки]
			, ВремяЗатрачено = sum(A.ВремяЗатрачено)
		FROM (
			SELECT Дата, [Номер заявки], ВремяЗатрачено
			from #fedor_verificator_report AS KD
			WHERE status='task:В работе'
				AND EXISTS(
					SELECT TOP(1) 1 
					FROM #fedor_verificator_report_TS AS TS 
					WHERE TS.[Номер заявки] = KD.[Номер заявки]
				)

			UNION
			select Дата, [Номер заявки], ВремяЗатрачено
			from #fedor_verificator_report_VK AS VK
			WHERE VK.status='task:В работе'
				AND EXISTS(
					SELECT TOP(1) 1 
					FROM #fedor_verificator_report_TS AS TS 
					WHERE TS.[Номер заявки] = VK.[Номер заявки]
				)

			UNION
			select Дата, [Номер заявки], ВремяЗатрачено
			from #fedor_verificator_report_TS where status='task:В работе'
			) AS A
		GROUP BY A.Дата, A.[Номер заявки]
	) AS B



	 --- расчет уникальных отложенных за день по ТС
	   -- посчитаем количество уникальных отложенных TS
 drop table if exists #postpone_unique_ts_daily

 select 
	[Дата статуса]=cast(([Дата]) as date),
	sum(p.ОтложенаУникальныеTS) ОтложенаУникальныеTS 
 into #postpone_unique_ts_daily
from #ReportByEmployeeAgg_TS_unique_postpone p
 group by cast((Дата) as date)


	drop table if exists #НеВернувшиесяИзОтложенных_ts_daily
	select 
		[Дата статуса] = cast([Дата] as date),
		НеВернувшиесяИзОтложенныхTS = isnull(count(distinct case when status='НеВернувшиесяИзОтложенных' then [Номер заявки]  end),0)
	into #НеВернувшиесяИзОтложенных_ts_daily
	from #fedor_verificator_report_TS
	group by cast([Дата] as date)


drop table if exists #p_TS

select d.* , [Среднее время заявки в ожидании очереди на этапе Вериф.ТС]         = cast(
      format(w.duration/60/60 ,'00')+N':'+format( (w.duration/60 -  60* (w.duration/60/60)),'00') +N':'+format((w.duration - 60 * (duration/60)),'00')
  as nvarchar(50))
  , [TTY  - % заявок рассмотренных в течение 3-х минут на этапе Вериф.ТС] =cast(format(case when /*[Общее кол-во уникальных заявок на этапе Вериф.ТС] */ [Общее кол-во заявок на этапе Вериф.ТС]  <>0 then 100.0*tty.cnt/ /*[Общее кол-во уникальных заявок на этапе Вериф.ТС]  */ [Общее кол-во заявок на этапе Вериф.ТС]   else 0 end,'0') +N'%'as nvarchar(50))

  , [TTY  - количество заявок рассмотренных в течение 30 минут на этапах КД, ВК, ВТС] = cast(tty2.cnt as nvarchar(50))
  , [TTY  - % заявок рассмотренных в течение 30 минут на этапах КД,ВК,ВТС] = cast(format(case when [Общее кол-во заявок на этапе Вериф.ТС]<>0 then 100.0*tty2.cnt/ [Общее кол-во заявок на этапе Вериф.ТС] else 0 end,'0') +N'%'as nvarchar(50))

 , [Уникальное кол-во отложенных заявок на этапе Вериф.ТС] = cast(format((u.ОтложенаУникальныеTS),'0') as nvarchar(50))
	, [Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.ТС] = cast(format((u2.НеВернувшиесяИзОтложенныхTS),'0') as nvarchar(50))
  into #p_TS
from  (
  select Дата
       , [Общее кол-во заведенных заявок Call2]                                        = cast('' as nvarchar(50))
       , [Кол-во автоматических отказов Call2]                                         = cast('' as nvarchar(50))
       , [%  автоматических отказов Call2]                                             = cast('' as nvarchar(50))
       , [Общее кол-во уникальных заявок на этапе Вериф.ТС]                            = cast(format(isnull(sum(Новая_Уникальная),0),'0')as nvarchar(50)) --DWH-2020
		--DWH-2286
		, [Первичный ВТС] = cast(format(isnull(sum([Новая_Уникальная Первичный]),0),'0')as nvarchar(50))
		, [Повторный ВТС] = cast(format(isnull(sum([Новая_Уникальная Повторный]),0),'0')as nvarchar(50))
		, [Докредитование ВТС] = cast(format(isnull(sum([Новая_Уникальная Докредитование]),0),'0')as nvarchar(50))
		, [Параллельный ВТС] = cast(format(isnull(sum([Новая_Уникальная Параллельный]),0),'0')as nvarchar(50))
		, [Не определен ВТС] = cast(format(isnull(sum([Новая_Уникальная Не определен]),0),'0')as nvarchar(50))

       , [Общее кол-во заявок на этапе Вериф.ТС]                                       = cast(format(sum(КоличествоЗаявок),'0') as nvarchar(50))
       , [TTY  - % заявок рассмотренных в течение 21 минут на этапе Вериф.клиента]     = cast('' as nvarchar(50))
    
      
       , [Средний Processing time на этапе (время обработки заявки) Вериф.ТС] =
		isnull(
			case 
				when sum(КоличествоЗаявок)<>0 
					then cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8),0) as nvarchar(50))
				else '0'
			end,'00:00:00'
		)

       , [Кол-во одобренных заявок после этапа Вериф.ТС]                               = cast(format(sum(Одобрено),'0')as nvarchar(50))
       , [Кол-во отказов со стороны сотрудников Вериф.ТС]                              = cast(format(sum([Отказано]),'0')as nvarchar(50)) 
       , [Approval rate - % одобренных после этапа Вериф.ТС]                           = case when  sum(ИтогоПоСотруднику)<>0 then
                                                                                          cast(format(isnull(case when sum(ИтогоПоСотруднику) <>0 then sum(Одобрено*1.0)/ sum(ИтогоПоСотруднику) else 0 end ,0)  *100,'0') +N'%' as nvarchar(50))
                                                                                         else '0'
                                                                                         end
       , [Approval rate % Логином]                                                     = cast('' as nvarchar(50))
       , [Общее кол-во отложенных заявок на этапе Вериф.ТС]                            = cast(format(sum(Отложена),'0') as nvarchar(50))

       , [Кол-во заявок на этапе, отправленных на доработку Вериф.ТС]                  = cast(format(sum(Доработка),'0') as nvarchar(50))
       , [Уникальное количество доработок на этапе Вериф.ТС] = cast(format(sum([Доработка уникальных]),'0') as nvarchar(50))

       , [Take rate Уровень выдачи, выраженный через одобрения]                        = cast('' as nvarchar(50))
       , [Кол-во заявок в статусе "Займ выдан",шт.]                                    = cast('' as nvarchar(50))

  
    from #ReportByEmployeeAgg_TS
   group by Дата
)d
 left join #waitTime_v_tc w on w.[Дата статуса]=d.Дата
 left join #postpone_unique_ts_daily u  on u.[Дата статуса] = d.Дата
 LEFT JOIN #НеВернувшиесяИзОтложенных_ts_daily AS u2 on u2.[Дата статуса] = d.Дата
  left join (
    select дата
         , count([Номер заявки]) cnt
      -- , ВремяЗатрачено 
      from #tty_ts
    where tty_flag='tty'
    group by  дата 

) tty on tty.Дата=d.Дата

	--DWH-2653
	left join (
		select дата
				, count([Номер заявки]) cnt
			-- , ВремяЗатрачено 
			from #tty_ts2
		where tty_flag='tty'
		group by  дата 
	) tty2 on tty2.Дата=d.Дата


	
	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##p_TS
		SELECT * INTO ##p_TS FROM #p_TS
	END

     /*
     use devdb
     go
     drop table if exists devdb.dbo.p_
     select * into devdb.dbo.p_ from #p 
     */
     drop table if exists #unp_VK_TS_Daily
  select Дата, indicator, Qty 
    into #unp_VK_TS_Daily
    from 
    (
    select v.Дата
         , v.[Общее кол-во заведенных заявок Call2]                          
         , v.[Кол-во автоматических отказов Call2]                           
         , v.[%  автоматических отказов Call2]                               
         , v.[Общее кол-во уникальных заявок на этапе Вериф.клиента]                  
		, v.[Первичный ВК]
		, v.[Повторный ВК]
		, v.[Докредитование ВК]
		, v.[Параллельный ВК]
		, v.[Не определен ВК]

         , v.[Общее кол-во заявок на этапе Вериф.клиента]                             
         , [TTY  - % заявок рассмотренных в течение 21 минут на этапе Вериф.клиента] = isnull(v.[TTY  - % заявок рассмотренных в течение 21 минут на этапе Вериф.клиента],'0%')

         , v.[Среднее время заявки в ожидании очереди на этапе Вериф.клиента]         
         , v.[Средний Processing time на этапе (время обработки заявки) Вериф.клиента]
         , v.[Кол-во одобренных заявок после этапа Вериф.клиента]                     
         , v.[Кол-во отказов со стороны сотрудников Вериф.клиента]                    
         , v.[Approval rate - % одобренных после этапа Вериф.клиента]                 
         , v.[Approval rate % Логином]                                                

		, v.[Контактность общая]
		, v.[Контактность по одобренным]
		, v.[Контактность по отказным]

         , v.[Общее кол-во отложенных заявок на этапе Вериф.клиента]   
		 , v.[Уникальное кол-во отложенных заявок на этапе Вериф.клиента]
         , v.[Кол-во заявок на этапе, отправленных на доработку Вериф.клиента]        
		 , v.[Уникальное количество доработок на этапе Вериф.клиента]
         , v.[Take rate Уровень выдачи, выраженный через одобрения]                   
         , v.[Кол-во заявок в статусе "Займ выдан",шт.]                               

		 , [Кол-во уникальных заявок в статусе Договор подписан] = isnull(v.[Кол-во уникальных заявок в статусе Договор подписан],'0')
         
        , [Общее кол-во уникальных заявок на этапе Вериф.ТС] = isnull(t.[Общее кол-во уникальных заявок на этапе Вериф.ТС], '0')
		, [Первичный ВТС] = isnull(t.[Первичный ВТС], '0')
		, [Повторный ВТС] = isnull(t.[Повторный ВТС], '0')
		, [Докредитование ВТС] = isnull(t.[Докредитование ВТС], '0')
		, [Параллельный ВТС] = isnull(t.[Параллельный ВТС], '0')
		, [Не определен ВТС] = isnull(t.[Не определен ВТС], '0')

         , [Общее кол-во заявок на этапе Вериф.ТС] = isnull(t.[Общее кол-во заявок на этапе Вериф.ТС], '0')
         , [TTY  - % заявок рассмотренных в течение 3-х минут на этапе Вериф.ТС] = isnull(t.[TTY  - % заявок рассмотренных в течение 3-х минут на этапе Вериф.ТС], '0%')
         , [TTY  - количество заявок рассмотренных в течение 30 минут на этапах КД, ВК, ВТС] = isnull(t.[TTY  - количество заявок рассмотренных в течение 30 минут на этапах КД, ВК, ВТС],'0')
         , [TTY  - % заявок рассмотренных в течение 30 минут на этапах КД,ВК,ВТС] = isnull(t.[TTY  - % заявок рассмотренных в течение 30 минут на этапах КД,ВК,ВТС],'0%')
         , [Среднее время заявки в ожидании очереди на этапе Вериф.ТС] = isnull(t.[Среднее время заявки в ожидании очереди на этапе Вериф.ТС],'00:00:00')
         , [Средний Processing time на этапе (время обработки заявки) Вериф.ТС] = isnull(t.[Средний Processing time на этапе (время обработки заявки) Вериф.ТС],'00:00:00')
         , [Кол-во одобренных заявок после этапа Вериф.ТС] = isnull(t.[Кол-во одобренных заявок после этапа Вериф.ТС], '0')
         , [Кол-во отказов со стороны сотрудников Вериф.ТС] = isnull(t.[Кол-во отказов со стороны сотрудников Вериф.ТС], '0')
         , [Approval rate - % одобренных после этапа Вериф.ТС] = isnull(t.[Approval rate - % одобренных после этапа Вериф.ТС], '0%')
         , [Общее кол-во отложенных заявок на этапе Вериф.ТС] = isnull(t.[Общее кол-во отложенных заявок на этапе Вериф.ТС], '0')
		 , [Уникальное кол-во отложенных заявок на этапе Вериф.ТС] = isnull(t.[Уникальное кол-во отложенных заявок на этапе Вериф.ТС], '0')
		 
         , [Кол-во заявок на этапе, отправленных на доработку Вериф.ТС] = isnull(t.[Кол-во заявок на этапе, отправленных на доработку Вериф.ТС], '0')
         , [Уникальное количество доработок на этапе Вериф.ТС] = isnull(t.[Уникальное количество доработок на этапе Вериф.ТС], '0')
         , [Общее кол-во заявок на этапе Вериф.]                                    = cast(format(isnull(cast(t.[Общее кол-во заявок на этапе Вериф.ТС] as int),0)                      +isnull(cast(v.[Общее кол-во заявок на этапе Вериф.клиента]            as int),0)            ,'0') as nvarchar(50))
         , [Общее кол-во уникальных заявок на этапе Верифик.]                         = cast(format(isnull(cast(t.[Общее кол-во уникальных заявок на этапе Вериф.ТС] as int),0)           +isnull(cast(v.[Общее кол-во уникальных заявок на этапе Вериф.клиента] as int),0)            ,'0') as nvarchar(50))
         , [Кол-во одобренных заявок после этапа Вериф.]                            = cast(format(isnull(cast(t.[Кол-во одобренных заявок после этапа Вериф.ТС]    as int),0)                                                                                                        ,'0') as nvarchar(50))
         , [Кол-во отказов со стороны сотрудников Вериф.]                           = cast(format(isnull(cast(t.[Кол-во отказов со стороны сотрудников Вериф.ТС]   as int),0)           +isnull(cast(v.[Кол-во отказов со стороны сотрудников Вериф.клиента]               as int),0),'0') as nvarchar(50))
         , [Общее кол-во отложенных заявок на этапе Вериф.]                         = cast(format(isnull(cast(t.[Общее кол-во отложенных заявок на этапе Вериф.ТС] as int),0)           +isnull(cast(v.[Общее кол-во отложенных заявок на этапе Вериф.клиента]             as int),0),'0') as nvarchar(50))
         , [Кол-во заявок на этапе, отправленных на доработку Вериф.]               = cast(format(isnull(cast(t.[Кол-во заявок на этапе, отправленных на доработку Вериф.ТС] as int),0) +isnull(cast(v.[Кол-во заявок на этапе, отправленных на доработку Вериф.клиента]   as int),0),'0') as nvarchar(50))
		 , [Уникальное количество доработок на этапе Вериф.] = cast(format(isnull(cast(t.[Уникальное количество доработок на этапе Вериф.ТС] as int),0) +  isnull(cast(v.[Уникальное количество доработок на этапе Вериф.клиента] as int),0),'0') as nvarchar(50))

		 , [Уникальное кол-во отложенных заявок на этапе Вериф.]                         = cast(format(isnull(cast(t.[Уникальное кол-во отложенных заявок на этапе Вериф.ТС] as int),0)           +isnull(cast(v.[Уникальное кол-во отложенных заявок на этапе Вериф.клиента] as int),0)            ,'0') as nvarchar(50))

		 , [Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.] = 
			cast(format(
				isnull(cast(t.[Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.ТС] as int),0) +
				isnull(cast(v.[Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.клиента] as int),0),
				'0') as nvarchar(50))

		, [% заявок, не вернувшихся из отложенных на этапе  Вериф.] =
		CASE
			WHEN (isnull(cast(t.[Уникальное кол-во отложенных заявок на этапе Вериф.ТС] as int),0) +
				 isnull(cast(v.[Уникальное кол-во отложенных заявок на этапе Вериф.клиента] as int),0))
				 <> 0
			THEN 
				cast(format(
					(isnull(cast(t.[Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.ТС] as int),0) +
					isnull(cast(v.[Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.клиента] as int),0))
					* 1.0
					/
					(isnull(cast(t.[Уникальное кол-во отложенных заявок на этапе Вериф.ТС] as int),0) +
					isnull(cast(v.[Уникальное кол-во отложенных заявок на этапе Вериф.клиента] as int),0)),
					'p1') as nvarchar(50))
			ELSE '0%'
		END
      from #p_VK v left join #p_TS  t on t.Дата=v.Дата

    ) p
unpivot
  (Qty for indicator in (
           [Общее кол-во заведенных заявок Call2]                          
         , [Кол-во автоматических отказов Call2]                           
         , [%  автоматических отказов Call2]                               
         , [Общее кол-во уникальных заявок на этапе Вериф.клиента]                  
		, [Первичный ВК]
		, [Повторный ВК]
		, [Докредитование ВК]
		, [Параллельный ВК]
		, [Не определен ВК]

         , [Общее кол-во заявок на этапе Вериф.клиента]                             
         , [TTY  - % заявок рассмотренных в течение 21 минут на этапе Вериф.клиента]
                 
         , [Среднее время заявки в ожидании очереди на этапе Вериф.клиента]         
         , [Средний Processing time на этапе (время обработки заявки) Вериф.клиента]
         , [Кол-во одобренных заявок после этапа Вериф.клиента]                     
         , [Кол-во отказов со стороны сотрудников Вериф.клиента]                    
         , [Approval rate - % одобренных после этапа Вериф.клиента]                 
         , [Approval rate % Логином]     
		 
		, [Контактность общая]
		, [Контактность по одобренным]
		, [Контактность по отказным]

         , [Общее кол-во отложенных заявок на этапе Вериф.клиента]    
		 , [Уникальное кол-во отложенных заявок на этапе Вериф.клиента]

         , [Кол-во заявок на этапе, отправленных на доработку Вериф.клиента]        
         , [Уникальное количество доработок на этапе Вериф.клиента]

         , [Take rate Уровень выдачи, выраженный через одобрения]                   
         , [Кол-во заявок в статусе "Займ выдан",шт.]    

		 , [Кол-во уникальных заявок в статусе Договор подписан]

         , [Общее кол-во уникальных заявок на этапе Вериф.ТС]                        
		, [Первичный ВТС]
		, [Повторный ВТС]
		, [Докредитование ВТС]
		, [Параллельный ВТС]
		, [Не определен ВТС]

         , [Общее кол-во заявок на этапе Вериф.ТС]
         , [TTY  - % заявок рассмотренных в течение 3-х минут на этапе Вериф.ТС]     
         , [TTY  - количество заявок рассмотренных в течение 30 минут на этапах КД, ВК, ВТС]
         , [TTY  - % заявок рассмотренных в течение 30 минут на этапах КД,ВК,ВТС]
         , [Среднее время заявки в ожидании очереди на этапе Вериф.ТС]               
         , [Средний Processing time на этапе (время обработки заявки) Вериф.ТС]      
         , [Кол-во одобренных заявок после этапа Вериф.ТС]                           
         , [Кол-во отказов со стороны сотрудников Вериф.ТС]                          
         , [Approval rate - % одобренных после этапа Вериф.ТС]                 
         , [Общее кол-во отложенных заявок на этапе Вериф.ТС]   
		 , [Уникальное кол-во отложенных заявок на этапе Вериф.ТС]

         , [Кол-во заявок на этапе, отправленных на доработку Вериф.ТС]  
		 , [Уникальное количество доработок на этапе Вериф.ТС]
         
         , [Общее кол-во заявок на этапе Вериф.]                      
         , [Общее кол-во уникальных заявок на этапе Верифик.]
         , [Кол-во одобренных заявок после этапа Вериф.]              
         , [Кол-во отказов со стороны сотрудников Вериф.]             
         , [Общее кол-во отложенных заявок на этапе Вериф.]           
         , [Кол-во заявок на этапе, отправленных на доработку Вериф.] 
		 , [Уникальное количество доработок на этапе Вериф.]

		 , [Уникальное кол-во отложенных заявок на этапе Вериф.] 

		 , [Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.]
		 , [% заявок, не вернувшихся из отложенных на этапе  Вериф.]
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
			--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_V_Daily_Common
			DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_V_Daily_Common AS T WHERE T.ProcessGUID = @ProcessGUID

			INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_V_Daily_Common
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
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_V_Daily_Common
			from #unp_VK_TS_Daily u 
				JOIN #indicator_for_vc_va i 
					ON u.indicator like i.name_indicator+'%'

			INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'V.Daily.Common', @ProcessGUID

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
				ON u.indicator like i.name_indicator+'%'

			RETURN 0
		END

	END
	--// 'V.Daily.Common'


	IF @Page= 'KD.Monthly.Common' OR @isFill_All_Tables = 1
 begin

 drop table if exists #verif_KC_m

 select [Дата статуса]= cast(format([Дата статуса],'yyyyMM01') as date) 
      , count(distinct [Номер заявки]) cnt
 into #verif_KC_m
 from #t_dm_FedorVerificationRequests_AutocredVTB r 
 where 1=1
	--and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
	and  Статус='Верификация КЦ' and [Статус следующий]='Отказано'
 group by cast(format([Дата статуса],'yyyyMM01') as date) 
 

   -- TTY
   
   drop table if exists #tty_kd_m

   select Дата
        , [Номер заявки]
        , Сотрудник
        , [ФИО сотрудника верификации/чекер]
        --, ВремяЗатрачено
        , cast(cast(ВремяЗатрачено as datetime) as time) ВремяЗатрачено
        , case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:06:00' then '-' else 'tty' end tty_flag
     into #tty_kd_m
     from #fedor_verificator_report where status='task:В работе'

 

drop table if exists #waitTime_m

		;with r as
(
select 

[Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
--, [Дата статуса]=case when  cast([Дата статуса] as time)>'07:00' and cast([Дата статуса] as time)<='22:00' then [Дата статуса] 
--                 else 
--                      case when  cast([Дата статуса] as time)>'22:00' and cast([Дата статуса] as time)<='23:59:59' then
--                           cast(format(dateadd(day,1,cast([Дата статуса] as date)),'yyyyMMdd 07:00') as datetime) 
--                      else
--                           cast(format([Дата статуса] ,'yyyyMMdd 07:00') as datetime) 
--                      end
--                 end
--, [Дата след.статуса] =case when  cast([Дата след.статуса] as time)>'07:00' and cast([Дата след.статуса] as time)<='22:00' then [Дата след.статуса]
--                 else 
--                      case when  cast([Дата след.статуса] as time)>'22:00' and cast([Дата след.статуса] as time)<='23:59:59' then
--                           cast(format(dateadd(day,1,cast([Дата след.статуса] as date)),'yyyyMMdd 07:00') as datetime) 
--                      else
--                           cast(format([Дата след.статуса],'yyyyMMdd 07:00') as datetime) 
--                      end
--                 end
, [Дата статуса]
, [Дата след.статуса]


, Работник [ФИО сотрудника верификации/чекер]
, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику], [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату], Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]

		 from #t_dm_FedorVerificationRequests_AutocredVTB r
 where [Состояние заявки]='Ожидание'
	AND r.Статус='Контроль данных'
	--DWH-2019
	AND NOT (
		r.Задача='task:Новая'
		AND r.[Задача следующая] = 'task:Автоматически отложено'
	)

	--AND [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
 and (Работник in (select e.Employee from #KDEmployees e)
 or Назначен in (select e.Employee from #KDEmployees e))
)

select [Дата статуса]=cast(format([Дата статуса],'yyyyMM01') as date) 
   --  , [Номер заявки]
     , avg( datediff(second,[Дата статуса], [Дата след.статуса]))  duration
  into #waitTime_m
  from  r
  where  datediff(second,[Дата статуса], [Дата след.статуса])>0
 group by cast(format([Дата статуса],'yyyyMM01') as date) 
 

 drop table if exists #all_requests_m
  
  select [Дата заведения заявки] =format([Дата заведения заявки] ,'yyyyMM01')
       , count(distinct [Номер заявки]) Qty 
    into #all_requests_m
    from #t_dm_FedorVerificationRequests_AutocredVTB
    join #calendar c on c.dt_day=[Дата заведения заявки]
    where  1=1
		--and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
   group by format([Дата заведения заявки] ,'yyyyMM01')

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
          select Дата = cast(format([Дата],'yyyyMM01') as date)
              -- , Сотрудник   
               --, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
			    , isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальныеKD]
               
            from #fedor_verificator_report
			--DWH-1806
			where Сотрудник in (select * from #curr_employee_cd)
			--01.01 не рабочий день, данные за этот день не учитываем
			and Дата != datefromparts(year(Дата), 1,1)
           group by cast(format([Дата],'yyyyMM01') as date) --Дата
              -- , Сотрудник
        )
          select c1.*              
            into #ReportByEmployeeAgg_KD_UniquePostone_m
            from c1 

 drop table if exists #postpone_unique_kd_m
 select 
	[Дата статуса]=cast(format([Дата],'yyyyMM01') as date),
	sum(p.ОтложенаУникальныеKD) ОтложенаУникальныеKD 
 into #postpone_unique_kd_m
from #ReportByEmployeeAgg_KD_UniquePostone_m p
 group by cast(format(Дата,'yyyyMM01') as date)


drop table if exists #p_m 

select d.* , cast(format(r.Qty,'0') as nvarchar(50))[Общее кол-во заведенных заявок] 
,  cast(
      format(w.duration/60/60 ,'00')+N':'+format( (w.duration/60 -  60* (w.duration/60/60)),'00') +N':'+format((w.duration - 60 * (duration/60)),'00')
  as nvarchar(50)) [Среднее время заявки в ожидании очереди на этапе]
	, new.[Общее кол-во уникальных заявок на этапе]
	, new.[Первичный]
	, new.[Повторный]
	, new.[Докредитование]
	, new.[Параллельный]
	, new.[Не определен]

    , cast(tty.cnt as nvarchar(50))[TTY  - количество заявок рассмотренных в течение 6 минут на этапе]
  , cast(format(case when [Общее кол-во заявок на этапе]<>0 then 100*tty.cnt*1.0/[Общее кол-во заявок на этапе] else 0 end,'0')+N'%' as nvarchar(50))[TTY  - % заявок рассмотренных в течение 6 минут на этапе]
        , cast(kc.cnt as nvarchar(50))[Кол-во автоматических отказов Логином]
         , cast(case when r.Qty<>0 then  format(100.0*kc.cnt/r.Qty,'0') else '0' end +N'%' as nvarchar(50))[%  автоматических отказов Логином]
		 , [Уникальное кол-во отложенных заявок на этапе]                       = cast(format((u.ОтложенаУникальныеKD),'0') as nvarchar(50))
into #p_m 
from (
    select Дата=cast(format(Дата,'yyyyMM01') as date)
         , cast(format(sum(КоличествоЗаявок),'0') as nvarchar(50)) [Общее кол-во заявок на этапе]
         
         
         , cast(format(sum([ВК]),'0')as nvarchar(50)) [Кол-во одобренных заявок после этапа] 
         , cast(format(sum(Отложена),'0') as nvarchar(50)) [Общее кол-во отложенных заявок на этапе]

         , cast(format(sum(Доработка),'0') as nvarchar(50)) as [Кол-во заявок на этапе, отправленных на доработку]
         , cast(format(sum([Доработка уникальных]),'0') as nvarchar(50)) as [Уникальное количество доработок на этапе]

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
         
      from #ReportByEmployeeAgg a 
	  where сотрудник in (select * from #curr_employee_cd)
      --01.01 не рабочий день, данные за этот день не учитываем
		and Дата != DATEFROMPARTS(year(Дата), 1,1)
     group by cast(format(Дата,'yyyyMM01') as date)
)d  

join (
    select Дата=cast(format(Дата,'yyyyMM01') as date)
         , cast(format(sum(Новая_Уникальная),'0')as nvarchar(50)) [Общее кол-во уникальных заявок на этапе] --DWH-2020
		--DWH-2286
		, cast(format(sum([Новая_Уникальная Первичный]),'0')as nvarchar(50)) [Первичный]
		, cast(format(sum([Новая_Уникальная Повторный]),'0')as nvarchar(50)) [Повторный]
		, cast(format(sum([Новая_Уникальная Докредитование]),'0')as nvarchar(50)) [Докредитование]
		, cast(format(sum([Новая_Уникальная Параллельный]),'0')as nvarchar(50)) [Параллельный]
		, cast(format(sum([Новая_Уникальная Не определен]),'0')as nvarchar(50)) [Не определен]
      from #ReportByEmployeeAgg a
	    --01.01 не рабочий день, данные за этот день не учитываем
		where Дата != DATEFROMPARTS(year(Дата), 1,1)
     group by cast(format(Дата,'yyyyMM01') as date)


) new on new.Дата=d.Дата

join #all_requests_m r on r.[Дата заведения заявки]=d.Дата
left join #waitTime_m w on w.[Дата статуса]=d.Дата
left join #postpone_unique_kd_m u on u.[Дата статуса] = d.Дата
left join (
    select дата=cast(format(Дата,'yyyyMM01') as date)
         , count([Номер заявки]) cnt
      -- , ВремяЗатрачено 
      from #tty_kd_m
    where tty_flag='tty'
    group by  cast(format(Дата,'yyyyMM01') as date) 

) tty on tty.Дата=d.Дата

left join #verif_KC_m kc on kc.[Дата статуса]=d.Дата
     /*
     use devdb
     go
     drop table if exists devdb.dbo.p_
     select * into devdb.dbo.p_ from #p 
     */
     drop table if exists #unp_m
select Дата, indicator, Qty 
into #unp_m
from 
(
    select Дата
         , [Общее кол-во заведенных заявок]
         , [Кол-во автоматических отказов Логином]
         , [%  автоматических отказов Логином]
         , [Общее кол-во уникальных заявок на этапе]
		, [Первичный]
		, [Повторный]
		, [Докредитование]
		, [Параллельный]
		, [Не определен]
         , [Общее кол-во заявок на этапе]
         , [TTY  - количество заявок рассмотренных в течение 6 минут на этапе]
         , [TTY  - % заявок рассмотренных в течение 6 минут на этапе]
         , [Среднее время заявки в ожидании очереди на этапе]
         , [Средний Processing time на этапе (время обработки заявки)]
         , [Кол-во одобренных заявок после этапа]
         , [Кол-во отказов со стороны сотрудников]
         , [Approval rate - % одобренных после этапа]
         , [Общее кол-во отложенных заявок на этапе]
         , [Кол-во заявок на этапе, отправленных на доработку]
		 , [Уникальное количество доработок на этапе]
		 , [Уникальное кол-во отложенных заявок на этапе]
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
						, [Параллельный]
						, [Не определен]
                         ,[Общее кол-во заявок на этапе]
                         ,[TTY  - количество заявок рассмотренных в течение 6 минут на этапе]
                         ,[TTY  - % заявок рассмотренных в течение 6 минут на этапе]
                         ,[Среднее время заявки в ожидании очереди на этапе]
                         ,[Средний Processing time на этапе (время обработки заявки)]
                         ,[Кол-во одобренных заявок после этапа]
                         ,[Кол-во отказов со стороны сотрудников]
                         ,[Approval rate - % одобренных после этапа]
                         ,[Общее кол-во отложенных заявок на этапе]
                         ,[Кол-во заявок на этапе, отправленных на доработку]
						 ,[Уникальное количество доработок на этапе]
						 ,[Уникальное кол-во отложенных заявок на этапе]
                        )
   ) as unpvt

			IF @isFill_All_Tables = 1
			BEGIN
				--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Common
				DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Common AS T WHERE T.ProcessGUID = @ProcessGUID

				INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Common
				SELECT
					ProcessGUID = @ProcessGUID,
					i.num_rows 
					--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
					,empl_id =null
					,Employee =null
					,acc_period =Дата
					,indicator =name_indicator
					,[Сумма] =null
					,Qty
					,Qty_dist=null
					,Tm_Qty =null--isnull(Tm_Qty,0.00)
				--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_KD_Monthly_Common
				FROM #unp_m u join #indicator_for_controldata i on u.indicator=i.name_indicator
				--ORDER BY i.num_rows

				INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
				SELECT getdate(), 'KD.Monthly.Common', @ProcessGUID

			END
			ELSE BEGIN
			   select 
				i.num_rows 
				--num_rows = replace(convert(varchar(10), i.num_rows), '.0','')
    ,empl_id =null
	   ,Employee =null
     ,acc_period =Дата
      ,indicator =name_indicator
     ,[Сумма] =null
	   , Qty
	   ,Qty_dist=null
	   , Tm_Qty =null--isnull(Tm_Qty,0.00)
    from #unp_m u join #indicator_for_controldata i on u.indicator=i.name_indicator
				--ORDER BY i.num_rows

				RETURN 0
end
	END
	--// 'KD.Monthly.Common'





IF @page= 'V.Monthly.Common' OR @isFill_All_Tables = 1
begin

  drop table if exists #tty_vk_m

   select Дата
        , [Номер заявки]
        , Сотрудник
        , [ФИО сотрудника верификации/чекер]
        --, ВремяЗатрачено
        , cast(cast(ВремяЗатрачено as datetime) as time) ВремяЗатрачено
        , case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:21:00' then '-' else 'tty' end tty_flag
     into #tty_vk_m
     from #fedor_verificator_report_vk where status='task:В работе'



-- Пришло на call2
 drop table if exists #call2_m


 select [Дата статуса]=cast(format([Дата статуса],'yyyyMM01') as date)
      , count(distinct [Номер заявки]) Qty
      , sum(case when [Статус следующий]='Отказано' then 1 else 0 end) Qty_rejected
 into #call2_m
 from #t_dm_FedorVerificationRequests_AutocredVTB r 
 where Статус ='Верификация Call 2'  
	--and [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
 group by cast(format([Дата статуса],'yyyyMM01') as date)

   --select * from #call2

drop table if exists #waitTime_v_m

		;with r as
(
select 

[Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
--, [Дата статуса]=case when  cast([Дата статуса] as time)>'07:00' and cast([Дата статуса] as time)<='22:00' then [Дата статуса] 
--                 else 
--                      case when  cast([Дата статуса] as time)>'22:00' and cast([Дата статуса] as time)<='23:59:59' then
--                           cast(format(dateadd(day,1,cast([Дата статуса] as date)),'yyyyMMdd 07:00') as datetime) 
--                      else
--                           cast(format([Дата статуса] ,'yyyyMMdd 07:00') as datetime) 
--                      end
--                 end
--, [Дата след.статуса] =case when  cast([Дата след.статуса] as time)>'07:00' and cast([Дата след.статуса] as time)<='22:00' then [Дата след.статуса]
--                 else 
--                      case when  cast([Дата след.статуса] as time)>'22:00' and cast([Дата след.статуса] as time)<='23:59:59' then
--                           cast(format(dateadd(day,1,cast([Дата след.статуса] as date)),'yyyyMMdd 07:00') as datetime) 
--                      else
--                           cast(format([Дата след.статуса],'yyyyMMdd 07:00') as datetime) 
--                      end
--                 end
, [Дата статуса]
, [Дата след.статуса]


, Работник [ФИО сотрудника верификации/чекер]
, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику], [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату],Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]

		from #t_dm_FedorVerificationRequests_AutocredVTB r
 where [Состояние заявки]='Ожидание' 
	AND r.Статус='Верификация клиента' 
	--DWH-2019
	AND NOT (
		r.Задача='task:Новая'
		AND r.[Задача следующая] = 'task:Автоматически отложено'
	)

	--AND [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to

  and (Работник in (select e.Employee from #VKEmployees e)
 or Назначен in (select e.Employee from #VKEmployees e))
)
select [Дата статуса]=cast(format([Дата статуса],'yyyyMM01') as date) 
   --  , [Номер заявки]
     , avg( datediff(second,[Дата статуса], [Дата след.статуса]))  duration
  into #waitTime_v_m
  
  from  r
  where  datediff(second,[Дата статуса], [Дата след.статуса])>0
 group by cast(format([Дата статуса],'yyyyMM01') as date) 
 
 --select * from #waitTime_v_m

	-- посчитаем количество уникальных отложенных VK
	drop table if exists #postpone_unique_vk

	--2023-11-20. Исправление ошибки
	-- select 
	--	[Дата статуса]=cast(format([Дата],'yyyyMM01') as date),
	--	sum(p.ОтложенаУникальныеVK) ОтложенаУникальныеVK 
	-- into #postpone_unique_vk
	--from #ReportByEmployeeAgg_VK_UniquePostone p
	-- group by cast(format(Дата,'yyyyMM01') as date)

	select 
		[Дата статуса]=cast(format(p.Дата,'yyyyMM01') as date),
		sum(p.ОтложенаУникальныеVK) ОтложенаУникальныеVK 
	into #postpone_unique_vk
	from --#ReportByEmployeeAgg_VK_UniquePostone p
		(
			select c1.*              
			from (
				select Дата = cast(format([Дата],'yyyyMM01') as date)
					-- , Сотрудник   
					--, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
					, isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальныеVK]
				from #fedor_verificator_report_VK
				group by cast(format([Дата],'yyyyMM01') as date) --Дата
			) AS c1 
		) AS p
	group by cast(format(p.Дата,'yyyyMM01') as date)


	drop table if exists #НеВернувшиесяИзОтложенных_vk
	select 
		[Дата статуса] = cast(format([Дата],'yyyyMM01') as date),
		НеВернувшиесяИзОтложенныхVK = isnull(count(distinct case when status='НеВернувшиесяИзОтложенных' then [Номер заявки]  end),0)
	INTO #НеВернувшиесяИзОтложенных_vk
	from #fedor_verificator_report_VK
	group by cast(format([Дата],'yyyyMM01') as date) --Дата

	--select 
	--	[Дата статуса] = cast(format(p.Дата,'yyyyMM01') as date),
	--	НеВернувшиесяИзОтложенных = sum(p.НеВернувшиесяИзОтложенныхVK) 
	--into #НеВернувшиесяИзОтложенных_vk
	--from
	--	(
	--		select c1.*              
	--		from (
	--			select 
	--				Дата = cast(format([Дата],'yyyyMM01') as date),
	--				НеВернувшиесяИзОтложенныхVK = isnull(count(distinct case when status='НеВернувшиесяИзОтложенных' then [Номер заявки]  end),0)
	--			from #fedor_verificator_report_VK
	--			group by cast(format([Дата],'yyyyMM01') as date) --Дата
	--		) AS c1 
	--	) AS p
	--group by cast(format(p.Дата,'yyyyMM01') as date)


drop table if exists #p_VK_m

select d.* 
 , uniqie_vk_month.[Общее кол-во уникальных заявок на этапе Вериф.клиента]
	, uniqie_vk_month.[Первичный ВК]
	, uniqie_vk_month.[Повторный ВК]
	, uniqie_vk_month.[Докредитование ВК]
	, uniqie_vk_month.[Параллельный ВК]
	, uniqie_vk_month.[Не определен ВК]
 , [Среднее время заявки в ожидании очереди на этапе Вериф.клиента] =
	isnull(
		cast(
			format(w.duration/60/60 ,'00')+N':'+format( (w.duration/60 -  60* (w.duration/60/60)),'00') +N':'+format((w.duration - 60 * (duration/60)),'00')
			as nvarchar(50)
		),'00:00:00'
	)
 , [Общее кол-во заведенных заявок Call2]                                        = cast(format(call2.Qty,'0') as nvarchar(50))
       , [Кол-во автоматических отказов Call2]                                         = cast(format(call2.Qty_rejected,'0') as nvarchar(50))
       , [%  автоматических отказов Call2]                                             = cast(format(case when call2.Qty<>0 then 100.0*call2.Qty_rejected/call2.Qty else 0 end,'0.0')+N'%' as nvarchar(50))
       , [TTY  - % заявок рассмотренных в течение 21 минут на этапе Вериф.клиента]     = cast(format(case when  [Общее кол-во заявок на этапе Вериф.клиента]<>0 then 100.0*tty.cnt/ [Общее кол-во заявок на этапе Вериф.клиента] else 0 end,'0.0')+N'%' as nvarchar(50))
	  
   , [Уникальное кол-во отложенных заявок на этапе Вериф.клиента]                       = cast(format((u.ОтложенаУникальныеVK),'0') as nvarchar(50))
   , [Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.клиента]               = cast(format((u2.НеВернувшиесяИзОтложенныхVK),'0') as nvarchar(50))
	, Contact.[Контактность общая]
	, Contact.[Контактность по одобренным]
	, Contact.[Контактность по отказным]

	,[Кол-во уникальных заявок в статусе Договор подписан] = cast(format(ДоговорПодписан.cnt,'0') as nvarchar(50))
into #p_VK_m
from (
  select Дата=cast(format(Дата,'yyyyMM01') as date)
      
       --, [Общее кол-во уникальных заявок на этапе Вериф.клиента]                       = cast(format(sum(Новая),'0')as nvarchar(50))                 
       , [Общее кол-во заявок на этапе Вериф.клиента]                                  = cast(format(sum(КоличествоЗаявок),'0') as nvarchar(50))
      
       , [TTY  - % заявок рассмотренных в течение 3-х минут на этапе Вериф.ТС]                  = cast('' as nvarchar(50))
	  , [TTY  - количество заявок рассмотренных в течение 30 минут на этапах КД, ВК, ВТС] = cast('' as nvarchar(50))
	  , [TTY  - % заявок рассмотренных в течение 30 минут на этапах КД,ВК,ВТС]= cast('' as nvarchar(50))
      
       , [Средний Processing time на этапе (время обработки заявки) Вериф.клиента]     = case when sum(КоличествоЗаявок)<>0 then cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8)  ,0) as nvarchar(50))
                                                                                          else '0' end
       , [Кол-во одобренных заявок после этапа Вериф.клиента]                          = cast(format(sum([VTS]),'0')as nvarchar(50))
       , [Кол-во отказов со стороны сотрудников Вериф.клиента]                         = cast(format(sum([Отказано]),'0')as nvarchar(50)) 
       , [Approval rate - % одобренных после этапа Вериф.клиента]                      = case when sum(  ИтогоПоСотруднику)<>0 then cast(format(isnull(case when sum(ИтогоПоСотруднику) <>0 then sum(VTS*1.0)/ sum(  ИтогоПоСотруднику) else 0 end ,0)  *100,'0')+N'%' as nvarchar(50))
                                                                                           else '0' end
       , [Approval rate % Логином]                                                     = cast('' as nvarchar(50))
       , [Общее кол-во отложенных заявок на этапе Вериф.клиента]                       = cast(format(sum(Отложена),'0') as nvarchar(50))

       , [Кол-во заявок на этапе, отправленных на доработку Вериф.клиента]             = cast(format(sum(Доработка),'0') as nvarchar(50))
       , [Уникальное количество доработок на этапе Вериф.клиента] = cast(format(sum([Доработка уникальных]),'0') as nvarchar(50))

       , [Take rate Уровень выдачи, выраженный через одобрения]                        = cast('' as nvarchar(50))
       , [Кол-во заявок в статусе "Займ выдан",шт.]                                    = cast('' as nvarchar(50))
    
    from #ReportByEmployeeAgg_VK where сотрудник in (select * from #curr_employee_vr)
   group by cast(format(Дата,'yyyyMM01') as date)
)d
left join
(
select  Дата=cast(format(Дата,'yyyyMM01') as date)
		,[Общее кол-во уникальных заявок на этапе Вериф.клиента] = cast(format(sum(Новая_Уникальная),'0')as nvarchar(50)) --DWH-2020
		--DWH-2286
		, [Первичный ВК] = cast(format(sum([Новая_Уникальная Первичный]),'0')as nvarchar(50))
		, [Повторный ВК] = cast(format(sum([Новая_Уникальная Повторный]),'0')as nvarchar(50))
		, [Докредитование ВК] = cast(format(sum([Новая_Уникальная Докредитование]),'0')as nvarchar(50))
		, [Параллельный ВК] = cast(format(sum([Новая_Уникальная Параллельный]),'0')as nvarchar(50))
		, [Не определен ВК] = cast(format(sum([Новая_Уникальная Не определен]),'0')as nvarchar(50))
    from #ReportByEmployeeAgg_VK 
	group by cast(format(Дата,'yyyyMM01') as date)
) uniqie_vk_month on d.Дата = uniqie_vk_month.Дата
left join #waitTime_v_m w on w.[Дата статуса]=d.Дата
left join #postpone_unique_vk u on u.[Дата статуса] = d.Дата
LEFT JOIN #НеВернувшиесяИзОтложенных_vk AS u2 on u2.[Дата статуса] = d.Дата
 left join #call2_m call2 on call2.[Дата статуса]=d.Дата
 left join (
    select дата=cast(format(Дата,'yyyyMM01') as date)
         , count([Номер заявки]) cnt
      -- , ВремяЗатрачено 
      from #tty_vk_m
    where tty_flag='tty'
    group by  cast(format(Дата,'yyyyMM01') as date) 

) tty on tty.Дата=d.Дата

	LEFT JOIN #t_Contact_Month AS Contact
		ON Contact.[Дата статуса] = d.Дата

	--DWH-2309
	LEFT JOIN (
		SELECT ДатаСтатуса = cast(format(D.[Дата статуса],'yyyyMM01') as date),
				cnt = count(DISTINCT D.[Номер заявки])
		from #t_dm_FedorVerificationRequests_AutocredVTB AS D
		WHERE 1=1
			--AND D.[Дата статуса] > @dt_from AND  D.[Дата статуса] < @dt_to
			AND D.Статус IN ('Договор подписан')
		GROUP BY cast(format(D.[Дата статуса],'yyyyMM01') as date)
	) AS ДоговорПодписан
	ON ДоговорПодписан.ДатаСтатуса = d.Дата

--
--TC
--
 drop table if exists #tty_ts_m

   select Дата
        , [Номер заявки]
        , Сотрудник
        , [ФИО сотрудника верификации/чекер]
        --, ВремяЗатрачено
        , cast(cast(ВремяЗатрачено as datetime) as time) ВремяЗатрачено
        , case when cast(cast(ВремяЗатрачено as datetime) as time)>'00:03:00' then '-' else 'tty' end tty_flag
     into #tty_ts_m
     from #fedor_verificator_report_ts where status='task:В работе'


	--DWH-2653
	DROP table if exists #tty_ts2_m
	select B.Дата
        , B.[Номер заявки]
        --, Сотрудник
        --, [ФИО сотрудника верификации/чекер]
        --, ВремяЗатрачено
        , cast(cast(B.ВремяЗатрачено as datetime) as time) AS ВремяЗатрачено
        , case when cast(cast(B.ВремяЗатрачено as datetime) as time)>'00:30:00' then '-' else 'tty' end AS tty_flag
	into #tty_ts2_m
	from (
		select 
			A.Дата
			, A.[Номер заявки]
			, ВремяЗатрачено = sum(A.ВремяЗатрачено)
		FROM (
			SELECT Дата, [Номер заявки], ВремяЗатрачено
			from #fedor_verificator_report AS KD
			WHERE KD.status='task:В работе'
				AND EXISTS(
					SELECT TOP(1) 1 
					FROM #fedor_verificator_report_TS AS TS 
					WHERE TS.[Номер заявки] = KD.[Номер заявки]
				)

			UNION
			select Дата, [Номер заявки], ВремяЗатрачено
			from #fedor_verificator_report_VK AS VK
			WHERE VK.status='task:В работе'
				AND EXISTS(
					SELECT TOP(1) 1 
					FROM #fedor_verificator_report_TS AS TS 
					WHERE TS.[Номер заявки] = VK.[Номер заявки]
				)

			UNION
			select Дата, [Номер заявки], ВремяЗатрачено
			from #fedor_verificator_report_TS where status='task:В работе'
			) AS A
		GROUP BY A.Дата, A.[Номер заявки]
	) AS B


drop table if exists #waitTime_v_tc_m

		;with r as
(
select 

[Дата заведения заявки], [Время заведения], [Номер заявки], [ФИО клиента], [Статус], [Задача], [Состояние заявки]
--, [Дата статуса]=case when  cast([Дата статуса] as time)>'07:00' and cast([Дата статуса] as time)<='22:00' then [Дата статуса] 
--                 else 
--                      case when  cast([Дата статуса] as time)>'22:00' and cast([Дата статуса] as time)<='23:59:59' then
--                           cast(format(dateadd(day,1,cast([Дата статуса] as date)),'yyyyMMdd 07:00') as datetime) 
--                      else
--                           cast(format([Дата статуса] ,'yyyyMMdd 07:00') as datetime) 
--                      end
--                 end
--, [Дата след.статуса] =case when  cast([Дата след.статуса] as time)>'07:00' and cast([Дата след.статуса] as time)<='22:00' then [Дата след.статуса]
--                 else 
--                      case when  cast([Дата след.статуса] as time)>'22:00' and cast([Дата след.статуса] as time)<='23:59:59' then
--                           cast(format(dateadd(day,1,cast([Дата след.статуса] as date)),'yyyyMMdd 07:00') as datetime) 
--                      else
--                           cast(format([Дата след.статуса],'yyyyMMdd 07:00') as datetime) 
--                      end
--                 end
, [Дата статуса]
, [Дата след.статуса]


, Работник [ФИО сотрудника верификации/чекер]
, [ВремяЗатрачено], [Время, час:мин:сек], [Статус следующий], [Задача следующая], [Состояние заявки следующая], [ПричинаНаим_Исх], [ПричинаНаим_След], [Последнее состояние заявки на дату по сотруднику], [Последний статус заявки на дату по сотруднику], [Последний статус заявки на дату],Работник_След [СотрудникПоследнегоСтатуса], [ШагЗаявки], [ПоследнийШаг], [Последний статус заявки], [Время в последнем статусе], [Время в последнем статусе, hh:mm:ss]

		 from #t_dm_FedorVerificationRequests_AutocredVTB r
  where [Состояние заявки]='Ожидание' 
	AND r.Статус='Верификация ТС' 
	--DWH-2019
	AND NOT (
		r.Задача='task:Новая'
		AND r.[Задача следующая] = 'task:Автоматически отложено'
	)

	--AND [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
  and (Работник in (select e.Employee from #TSEmployees e)
  or Назначен in (select e.Employee from #TSEmployees e))
)
select [Дата статуса]=cast(format([Дата статуса],'yyyyMM01') as date) 
   --  , [Номер заявки]
     , avg( datediff(second,[Дата статуса], [Дата след.статуса]))  duration
  into #waitTime_v_tc_m
  -- select *
  from  r
 where  datediff(second,[Дата статуса], [Дата след.статуса])>0
 group by cast(format([Дата статуса],'yyyyMM01') as date) 
 

 ---
  -- посчитаем количество уникальных отложенных TS
 drop table if exists #postpone_unique_ts

 select 
	[Дата статуса]=cast(format([Дата],'yyyyMM01') as date),
	sum(p.ОтложенаУникальныеTS) ОтложенаУникальныеTS 
 into #postpone_unique_ts
from --#ReportByEmployeeAgg_TS_unique_postpone p
	(
		select Дата = cast(format([Дата],'yyyyMM01') as date)
			--, Сотрудник
			--, isnull(sum(case when status='Отложена' then 1 else 0 end),0) [Отложена]
			, isnull(count(distinct case when status='Отложена' then [Номер заявки]  end),0) [ОтложенаУникальныеTS]
		from #fedor_verificator_report_TS
		group by cast(format([Дата],'yyyyMM01') as date) --Дата
			--, Сотрудник
	) AS p
 group by cast(format(Дата,'yyyyMM01') as date)


	drop table if exists #НеВернувшиесяИзОтложенных_ts
	select 
		[Дата статуса] = cast(format([Дата],'yyyyMM01') as date),
		НеВернувшиесяИзОтложенныхTS = isnull(count(distinct case when status='НеВернувшиесяИзОтложенных' then [Номер заявки]  end),0)
	INTO #НеВернувшиесяИзОтложенных_ts
	from #fedor_verificator_report_TS
	group by cast(format([Дата],'yyyyMM01') as date) --Дата



drop table if exists #p_TS_m

select d.*
, [Среднее время заявки в ожидании очереди на этапе Вериф.ТС]                   = cast(
      format(w.duration/60/60 ,'00')+N':'+format( (w.duration/60 -  60* (w.duration/60/60)),'00') +N':'+format((w.duration - 60 * (duration/60)),'00')
  as nvarchar(50)) 
   , [TTY  - % заявок рассмотренных в течение 3-х минут на этапе Вериф.ТС] =cast(format(case when [Общее кол-во заявок на этапе Вериф.ТС] /* [Общее кол-во уникальных заявок на этапе Вериф.ТС]*/  <>0 then 100.0*tty.cnt/ [Общее кол-во заявок на этапе Вериф.ТС] /*[Общее кол-во уникальных заявок на этапе Вериф.ТС] */  else 0 end,'0')+N'%' as nvarchar(50))

  , [TTY  - количество заявок рассмотренных в течение 30 минут на этапах КД, ВК, ВТС] = cast(tty2.cnt as nvarchar(50))
  , [TTY  - % заявок рассмотренных в течение 30 минут на этапах КД,ВК,ВТС] = cast(format(case when [Общее кол-во заявок на этапе Вериф.ТС]<>0 then 100.0*tty2.cnt/ [Общее кол-во заявок на этапе Вериф.ТС] else 0 end,'0') +N'%'as nvarchar(50))

   , [Уникальное кол-во отложенных заявок на этапе Вериф.ТС] = cast(format((u.ОтложенаУникальныеTS),'0') as nvarchar(50))
    , [Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.ТС] = cast(format((u2.НеВернувшиесяИзОтложенныхTS),'0') as nvarchar(50))

into #p_TS_m
from (
  select Дата=cast(format(Дата,'yyyyMM01') as date)
       , [Общее кол-во заведенных заявок Call2]                                        = cast('' as nvarchar(50))
       , [Кол-во автоматических отказов Call2]                                         = cast('' as nvarchar(50))
       , [%  автоматических отказов Call2]                                             = cast('' as nvarchar(50))
       , [Общее кол-во уникальных заявок на этапе Вериф.ТС]                            = cast(format(sum(Новая_Уникальная),'0')as nvarchar(50)) --DWH-2020

		--DWH-2286
		, [Первичный ВТС] = cast(format(sum([Новая_Уникальная Первичный]),'0')as nvarchar(50))
		, [Повторный ВТС] = cast(format(sum([Новая_Уникальная Повторный]),'0')as nvarchar(50))
		, [Докредитование ВТС] = cast(format(sum([Новая_Уникальная Докредитование]),'0')as nvarchar(50))
		, [Параллельный ВТС] = cast(format(sum([Новая_Уникальная Параллельный]),'0')as nvarchar(50))
		, [Не определен ВТС] = cast(format(sum([Новая_Уникальная Не определен]),'0')as nvarchar(50))

       , [Общее кол-во заявок на этапе Вериф.ТС]                                       = cast(format(sum(КоличествоЗаявок),'0') as nvarchar(50))
       , [TTY  - % заявок рассмотренных в течение 21 минут на этапе Вериф.клиента]     = cast('' as nvarchar(50))
       
       
       , [Средний Processing time на этапе (время обработки заявки) Вериф.ТС] =
		isnull(
			case 
				when sum(КоличествоЗаявок)<>0 
					then cast(isnull(convert(nvarchar,cast((sum(ВремяЗатрачено)/sum(КоличествоЗаявок)) as datetime),8),0) as nvarchar(50))
				else '0'
			end,'00:00:00'
		)
       , [Кол-во одобренных заявок после этапа Вериф.ТС]                               = cast(format(sum(Одобрено),'0')as nvarchar(50))
       , [Кол-во отказов со стороны сотрудников Вериф.ТС]                              = cast(format(sum([Отказано]),'0')as nvarchar(50)) 
       , [Approval rate - % одобренных после этапа Вериф.ТС]                           = cast(format(isnull(case when sum(ИтогоПоСотруднику) <>0 then sum(Одобрено*1.0)/ sum(ИтогоПоСотруднику) else 0 end ,0)  *100,'0') +N'%' as nvarchar(50))
       , [Approval rate % Логином]                                                     = cast('' as nvarchar(50))
       , [Общее кол-во отложенных заявок на этапе Вериф.ТС]                            = cast(format(sum(Отложена),'0') as nvarchar(50))

       , [Кол-во заявок на этапе, отправленных на доработку Вериф.ТС]                  = cast(format(sum(Доработка),'0') as nvarchar(50))
       , [Уникальное количество доработок на этапе Вериф.ТС] = cast(format(sum([Доработка уникальных]),'0') as nvarchar(50))

       , [Take rate Уровень выдачи, выраженный через одобрения]                        = cast('' as nvarchar(50))
       , [Кол-во заявок в статусе "Займ выдан",шт.]                                    = cast('' as nvarchar(50))

   
    from #ReportByEmployeeAgg_TS
   group by cast(format(Дата,'yyyyMM01') as date)
 )d
 left join #waitTime_v_tc_m w on w.[Дата статуса]=d.Дата
 left join #postpone_unique_ts u on u.[Дата статуса] = d.Дата
 LEFT JOIN #НеВернувшиесяИзОтложенных_ts AS u2 on u2.[Дата статуса] = d.Дата
  left join (
    select дата=cast(format(Дата,'yyyyMM01') as date)
         , count([Номер заявки]) cnt
      -- , ВремяЗатрачено 
      from #tty_ts_m
    where tty_flag='tty'
    group by  cast(format(Дата,'yyyyMM01') as date)

) tty on tty.Дата=d.Дата

	left join (
		select дата=cast(format(Дата,'yyyyMM01') as date)
				, count([Номер заявки]) cnt
			-- , ВремяЗатрачено 
			from #tty_ts2_m
		where tty_flag='tty'
		group by  cast(format(Дата,'yyyyMM01') as date)
	) tty2 on tty.Дата=d.Дата

     /*
     use devdb
     go
     drop table if exists devdb.dbo.p_
     select * into devdb.dbo.p_ from #p 
     */

     drop table if exists #unp_VK_TS_Daily_m

  select Дата, indicator, Qty 
    into #unp_VK_TS_Daily_m
    from 
    (
    select v.Дата
         , v.[Общее кол-во заведенных заявок Call2]                          
         , v.[Кол-во автоматических отказов Call2]                           
         , v.[%  автоматических отказов Call2]                               
         , v.[Общее кол-во уникальных заявок на этапе Вериф.клиента]                  
		, v.[Первичный ВК]
		, v.[Повторный ВК]
		, v.[Докредитование ВК]
		, v.[Параллельный ВК]
		, v.[Не определен ВК]
         , v.[Общее кол-во заявок на этапе Вериф.клиента]                             
         , [TTY  - % заявок рассмотренных в течение 21 минут на этапе Вериф.клиента] = isnull(v.[TTY  - % заявок рассмотренных в течение 21 минут на этапе Вериф.клиента],'0%')

         , v.[Среднее время заявки в ожидании очереди на этапе Вериф.клиента]         
         , v.[Средний Processing time на этапе (время обработки заявки) Вериф.клиента]
         , v.[Кол-во одобренных заявок после этапа Вериф.клиента]                     
         , v.[Кол-во отказов со стороны сотрудников Вериф.клиента]                    
         , v.[Approval rate - % одобренных после этапа Вериф.клиента]                 
         , v.[Approval rate % Логином]                                                

		, v.[Контактность общая]
		, v.[Контактность по одобренным]
		, v.[Контактность по отказным]

         , v.[Общее кол-во отложенных заявок на этапе Вериф.клиента]      
		 , v.[Уникальное кол-во отложенных заявок на этапе Вериф.клиента]
         , v.[Кол-во заявок на этапе, отправленных на доработку Вериф.клиента]        
		 , v.[Уникальное количество доработок на этапе Вериф.клиента]

         , v.[Take rate Уровень выдачи, выраженный через одобрения]                   
         , v.[Кол-во заявок в статусе "Займ выдан",шт.]                               

		 , v.[Кол-во уникальных заявок в статусе Договор подписан]
         
         , t.[Общее кол-во уникальных заявок на этапе Вериф.ТС]
		, t.[Первичный ВТС]
		, t.[Повторный ВТС]
		, t.[Докредитование ВТС]
		, t.[Параллельный ВТС]
		, t.[Не определен ВТС]

         , t.[Общее кол-во заявок на этапе Вериф.ТС]                                   
         , t.[TTY  - % заявок рассмотренных в течение 3-х минут на этапе Вериф.ТС]     
         , [TTY  - количество заявок рассмотренных в течение 30 минут на этапах КД, ВК, ВТС] = isnull(t.[TTY  - количество заявок рассмотренных в течение 30 минут на этапах КД, ВК, ВТС],'0')
         , [TTY  - % заявок рассмотренных в течение 30 минут на этапах КД,ВК,ВТС] = isnull(t.[TTY  - % заявок рассмотренных в течение 30 минут на этапах КД,ВК,ВТС],'0%')
         , [Среднее время заявки в ожидании очереди на этапе Вериф.ТС] = isnull(t.[Среднее время заявки в ожидании очереди на этапе Вериф.ТС],'00:00:00')
         , [Средний Processing time на этапе (время обработки заявки) Вериф.ТС] = isnull(t.[Средний Processing time на этапе (время обработки заявки) Вериф.ТС],'00:00:00')
         , t.[Кол-во одобренных заявок после этапа Вериф.ТС]                           
         , t.[Кол-во отказов со стороны сотрудников Вериф.ТС]                          
         , t.[Approval rate - % одобренных после этапа Вериф.ТС]                       
         , t.[Общее кол-во отложенных заявок на этапе Вериф.ТС]  
		 , t.[Уникальное кол-во отложенных заявок на этапе Вериф.ТС]

         , t.[Кол-во заявок на этапе, отправленных на доработку Вериф.ТС]              
		 , t.[Уникальное количество доработок на этапе Вериф.ТС]

         , [Общее кол-во заявок на этапе Вериф.]                                    = cast(format(isnull(cast(t.[Общее кол-во заявок на этапе Вериф.ТС] as int),0)                      +isnull(cast(v.[Общее кол-во заявок на этапе Вериф.клиента]            as int),0)            ,'0') as nvarchar(50))
         , [Общее кол-во уникальных заявок на этапе Верифик.]                         = cast(format(isnull(cast(t.[Общее кол-во уникальных заявок на этапе Вериф.ТС] as int),0)           +isnull(cast(v.[Общее кол-во уникальных заявок на этапе Вериф.клиента] as int),0)            ,'0') as nvarchar(50))
         , [Кол-во одобренных заявок после этапа Вериф.]                            = cast(format(isnull(cast(t.[Кол-во одобренных заявок после этапа Вериф.ТС]    as int),0)                                                                                                        ,'0') as nvarchar(50))
         , [Кол-во отказов со стороны сотрудников Вериф.]                           = cast(format(isnull(cast(t.[Кол-во отказов со стороны сотрудников Вериф.ТС]   as int),0)           +isnull(cast(v.[Кол-во отказов со стороны сотрудников Вериф.клиента]               as int),0),'0') as nvarchar(50))
         , [Общее кол-во отложенных заявок на этапе Вериф.]                         = cast(format(isnull(cast(t.[Общее кол-во отложенных заявок на этапе Вериф.ТС] as int),0)           +isnull(cast(v.[Общее кол-во отложенных заявок на этапе Вериф.клиента]             as int),0),'0') as nvarchar(50))
		 , [Уникальное кол-во отложенных заявок на этапе Вериф.]                         = cast(format(isnull(cast(t.[Уникальное кол-во отложенных заявок на этапе Вериф.ТС] as int),0)           +isnull(cast(v.[Уникальное кол-во отложенных заявок на этапе Вериф.клиента]             as int),0),'0') as nvarchar(50))

         , [Кол-во заявок на этапе, отправленных на доработку Вериф.]               = cast(format(isnull(cast(t.[Кол-во заявок на этапе, отправленных на доработку Вериф.ТС] as int),0) +isnull(cast(v.[Кол-во заявок на этапе, отправленных на доработку Вериф.клиента]   as int),0),'0') as nvarchar(50))
		 , [Уникальное количество доработок на этапе Вериф.] = cast(format(isnull(cast(t.[Уникальное количество доработок на этапе Вериф.ТС] as int),0) +  isnull(cast(v.[Уникальное количество доработок на этапе Вериф.клиента] as int),0),'0') as nvarchar(50))

		 , [Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.] = 
			cast(format(
				isnull(cast(t.[Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.ТС] as int),0) +
				isnull(cast(v.[Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.клиента] as int),0),
				'0') as nvarchar(50))
		, [% заявок, не вернувшихся из отложенных на этапе  Вериф.] =
		CASE
			WHEN (isnull(cast(t.[Уникальное кол-во отложенных заявок на этапе Вериф.ТС] as int),0) +
				 isnull(cast(v.[Уникальное кол-во отложенных заявок на этапе Вериф.клиента] as int),0))
				 <> 0
			THEN 
				cast(format(
					(isnull(cast(t.[Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.ТС] as int),0) +
					isnull(cast(v.[Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.клиента] as int),0))
					* 1.0
					/
					(isnull(cast(t.[Уникальное кол-во отложенных заявок на этапе Вериф.ТС] as int),0) +
					isnull(cast(v.[Уникальное кол-во отложенных заявок на этапе Вериф.клиента] as int),0)),
					'p1') as nvarchar(50))
			ELSE '0%'
		END
      from #p_VK_m v left join #p_TS_m t on t.Дата=v.Дата

    ) p
unpivot
  (Qty for indicator in (
           [Общее кол-во заведенных заявок Call2]                          
         , [Кол-во автоматических отказов Call2]                           
         , [%  автоматических отказов Call2]                               
         , [Общее кол-во уникальных заявок на этапе Вериф.клиента]                  
		, [Первичный ВК]
		, [Повторный ВК]
		, [Докредитование ВК]
		, [Параллельный ВК]
		, [Не определен ВК]

         , [Общее кол-во заявок на этапе Вериф.клиента]                             
         , [TTY  - % заявок рассмотренных в течение 21 минут на этапе Вериф.клиента]
                 
         , [Среднее время заявки в ожидании очереди на этапе Вериф.клиента]         
         , [Средний Processing time на этапе (время обработки заявки) Вериф.клиента]
         , [Кол-во одобренных заявок после этапа Вериф.клиента]                     
         , [Кол-во отказов со стороны сотрудников Вериф.клиента]                    
         , [Approval rate - % одобренных после этапа Вериф.клиента]                 
         , [Approval rate % Логином]                                                

		, [Контактность общая]
		, [Контактность по одобренным]
		, [Контактность по отказным]

         , [Общее кол-во отложенных заявок на этапе Вериф.клиента]  
		 , [Уникальное кол-во отложенных заявок на этапе Вериф.клиента]

         , [Кол-во заявок на этапе, отправленных на доработку Вериф.клиента]        
		 , [Уникальное количество доработок на этапе Вериф.клиента]

         , [Take rate Уровень выдачи, выраженный через одобрения]                   
         , [Кол-во заявок в статусе "Займ выдан",шт.]    

		 , [Кол-во уникальных заявок в статусе Договор подписан]

         , [Общее кол-во уникальных заявок на этапе Вериф.ТС]
		, [Первичный ВТС]
		, [Повторный ВТС]
		, [Докредитование ВТС]
		, [Параллельный ВТС]
		, [Не определен ВТС]

		 , [Уникальное кол-во отложенных заявок на этапе Вериф.ТС]
         , [Общее кол-во заявок на этапе Вериф.ТС]
         , [TTY  - % заявок рассмотренных в течение 3-х минут на этапе Вериф.ТС]     
         , [TTY  - количество заявок рассмотренных в течение 30 минут на этапах КД, ВК, ВТС]
         , [TTY  - % заявок рассмотренных в течение 30 минут на этапах КД,ВК,ВТС]
         , [Среднее время заявки в ожидании очереди на этапе Вериф.ТС]               
         , [Средний Processing time на этапе (время обработки заявки) Вериф.ТС]      
         , [Кол-во одобренных заявок после этапа Вериф.ТС]                           
         , [Кол-во отказов со стороны сотрудников Вериф.ТС]                          
         , [Approval rate - % одобренных после этапа Вериф.ТС]                 
         , [Общее кол-во отложенных заявок на этапе Вериф.ТС]                        
         , [Кол-во заявок на этапе, отправленных на доработку Вериф.ТС]  
		 , [Уникальное количество доработок на этапе Вериф.ТС]
         
         , [Общее кол-во заявок на этапе Вериф.]                      
         , [Общее кол-во уникальных заявок на этапе Верифик.]
         , [Кол-во одобренных заявок после этапа Вериф.]              
         , [Кол-во отказов со стороны сотрудников Вериф.]             
         , [Общее кол-во отложенных заявок на этапе Вериф.] 
		 , [Уникальное кол-во отложенных заявок на этапе Вериф.]
         , [Кол-во заявок на этапе, отправленных на доработку Вериф.] 
		 , [Уникальное количество доработок на этапе Вериф.]

		 , [Кол-во заявок, не вернувшихся из отложенных на этапе Вериф.]
		 , [% заявок, не вернувшихся из отложенных на этапе  Вериф.]
		)
   ) as unpvt

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##unp_VK_TS_Daily_m
			SELECT * INTO ##unp_VK_TS_Daily_m FROM #unp_VK_TS_Daily_m
		END

		IF @isFill_All_Tables = 1
		BEGIN
			--DROP TABLE IF EXISTS tmp.TMP_Report_verification_fedor_AutocredVTB_V_Monthly_Common
			DELETE T FROM tmp.TMP_Report_verification_fedor_AutocredVTB_V_Monthly_Common AS T WHERE T.ProcessGUID = @ProcessGUID

			INSERT tmp.TMP_Report_verification_fedor_AutocredVTB_V_Monthly_Common
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
			--INTO tmp.TMP_Report_verification_fedor_AutocredVTB_V_Monthly_Common
			from #unp_VK_TS_Daily_m u 
			join #indicator_for_vc_va i ON u.indicator like i.name_indicator+'%'
			--ON u.indicator = i.name_indicator
			--ORDER BY i.num_rows

			INSERT LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB(StartDateTime, ReportPage, ProcessGUID)
			SELECT getdate(), 'V.Monthly.Common', @ProcessGUID
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
        on u.indicator like i.name_indicator+'%'

			RETURN 0
		END
END
--// 'V.Monthly.Common'


END -- общий лист по  дням
--// Общий отчет


IF @Page = 'Fill_All_Tables' BEGIN
	SELECT @eventType = concat(@Page, ' FINISH')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Report_verification_fedor_AutocredVTB',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID

	--BEGIN TRAN

	UPDATE F
	SET EndDateTime = getdate()
	FROM LogDb.dbo.Fill_Report_verification_fedor_AutocredVTB AS F
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
		'EXEC dbo.Report_verification_fedor_AutocredVTB ',
		'@Page=''', @Page, ''', ',
		'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@isDebug=', convert(varchar(10), @isDebug)
	)

	SELECT @eventType = concat(@Page, ' ERROR')

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'Report_verification_fedor_AutocredVTB',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END