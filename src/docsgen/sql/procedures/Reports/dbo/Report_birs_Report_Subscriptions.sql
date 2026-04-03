/*
exec dbo.Report_birs_Report_Subscriptions
*/
--DWH-2201 Мониторинг выполнения рассылок отчетов birs
CREATE PROC dbo.Report_birs_Report_Subscriptions
	--,@ProcessGUID varchar(36) = NULL -- guid процесса
	--,@isDebug int = 0
AS
BEGIN

SET NOCOUNT ON;

BEGIN TRY
	DECLARE @ProcessGUID varchar(36) = NULL -- guid процесса
	DECLARE @eventType nvarchar(1024), @eventName nvarchar(1024)
	DECLARE @description nvarchar(1024), @message nvarchar(1024)

	--SELECT @isDebug = isnull(@isDebug, 0)

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @eventType = 'info', @eventName = 'Reports.dbo.Report_birs_Report_Subscriptions'


	--Email получателей
	DROP TABLE IF EXISTS #t_email_addresses

	SELECT 
		X.SubscriptionID,
		SubscriberType = PseudoTable.TheseNodes.value('(./Name)[1]', 'varchar(100)'), 
		SubscriberList = PseudoTable.TheseNodes.value('(./Value)[1]', 'varchar(8000)')
		--X.*
	INTO #t_email_addresses
	FROM (
		SELECT 
			SB.SubscriptionID,
			CAST(SB.ExtensionSettings AS xml) AS Subscribers
		FROM [C2-VSR-BIRS].ReportServer.dbo.Catalog AS C
			INNER JOIN [C2-VSR-BIRS].ReportServer.dbo.Subscriptions AS SB
				ON C.ItemID = SB.Report_OID
		WHERE 1=1
			AND SB.InactiveFlags = 0
			--AND C.Name IN (
			--	N'TEST Отчет по Верификации FEDOR Installment'
			--	--N'Отчет по Верификации FEDOR Installment'
			--)
			AND SB.EventType IN ('TimedSubscription')
			AND SB.DeliveryExtension IN ('Report Server Email')
			--test
			--AND SB.SubscriptionID = '7618B67B-0A16-4943-BF97-1F395DE753B6'
		) AS X
		CROSS APPLY X.Subscribers.nodes('/ParameterValues/ParameterValue') AS PseudoTable(TheseNodes)
	WHERE PseudoTable.TheseNodes.value('(./Name)[1]', 'varchar(100)') IN ('TO','CC','BCC')


	--Расписание запуска рассылки
	DROP TABLE IF EXISTS #t_rep, #t_type_shed

	--these CTEs are used to match the bitmask fields in the schedule to determine which days & months the schedule is triggered on
	;WITH wkdays AS (
		SELECT 'Sunday' AS label, 1 AS daybit
		UNION ALL
		SELECT 'Monday', 2
		UNION ALL
		SELECT 'Tuesday', 4
		UNION ALL
		SELECT 'Wednesday', 8
		UNION ALL
		SELECT 'Thursday', 16
		UNION ALL
		SELECT 'Friday', 32
		UNION ALL
		SELECT 'Saturday', 64
	),
	monthdays AS (
		SELECT CAST(number AS VARCHAR(2)) AS label,
			POWER(CAST(2 AS BIGINT),number-1) AS daybit
		FROM master.dbo.spt_values
		WHERE type='P' AND number BETWEEN 1 AND 31
	),
	months AS (
		SELECT DATENAME(MM,DATEADD(MM,number-1,0)) AS label,
			POWER(CAST(2 AS BIGINT),number-1) AS mnthbit
		FROM master.dbo.spt_values
		WHERE type='P' AND number BETWEEN 1 AND 12
	)
	SELECT 
		cat.ItemID,
		cat.path,
		cat.name,
		cat.creationdate,
		cat.modifieddate,
		subs.SubscriptionID,
		subs.Description,
		subs.LastStatus,
		subs.LastRunTime,
		subs.InactiveFlags,
		CASE RecurrenceType
			WHEN 1 THEN 'Once'
			WHEN 2 THEN 'Hourly'
			WHEN 3 THEN 'Daily' --by interval
			WHEN 4 THEN
				CASE
					WHEN WeeksInterval>1 THEN 'Weekly'
					ELSE 'Daily' --by day of week
				END
			WHEN 5 THEN 'Monthly' --by calendar day
			WHEN 6 THEN 'Monthly' --by day of week
		END AS sched_type,
		sched.StartDate,
		sched.MinutesInterval,
		sched.RecurrenceType,
		sched.DaysInterval,
		sched.WeeksInterval,
		sched.MonthlyWeek,
		wkdays.label AS wkday,wkdays.daybit AS wkdaybit,
		monthdays.label AS mnthday,monthdays.daybit AS mnthdaybit,
		months.label AS mnth, months.mnthbit
	INTO #t_rep
	FROM [C2-VSR-BIRS].ReportServer.dbo.Catalog AS cat
		LEFT JOIN [C2-VSR-BIRS].ReportServer.dbo.ReportSchedule AS repsched ON repsched.ReportID=cat.ItemID
		LEFT JOIN [C2-VSR-BIRS].ReportServer.dbo.Subscriptions AS subs ON subs.SubscriptionID=repsched.SubscriptionID
		LEFT JOIN [C2-VSR-BIRS].ReportServer.dbo.Schedule AS sched ON sched.ScheduleID=repsched.ScheduleID
		LEFT JOIN wkdays ON wkdays.daybit & sched.DaysOfWeek > 0
		LEFT JOIN monthdays ON monthdays.daybit & sched.DaysOfMonth > 0
		LEFT JOIN months ON months.mnthbit & sched.[Month] > 0
	WHERE cat.ParentID IS NOT NULL --all reports have a ParentID
		AND subs.InactiveFlags = 0
		AND subs.EventType IN ('TimedSubscription')
		AND subs.DeliveryExtension IN ('Report Server Email')
		--test
		--AND cat.ItemID = '27072E5A-8CED-4515-9032-F10F16089C28'

	/* THE PREVIOUS QUERY LEAVES MULTIPLE ROWS FOR SUBSCRIPTIONS THAT HAVE MULTIPLE BITMASK MATCHES      *
	 * THIS QUERY WILL CONCAT ALL OF THOSE FIELDS TOGETHER AND ACCUMULATE THEM IN A TABLE FOR USE LATER. */

	CREATE TABLE #t_type_shed (
		type VARCHAR(16) COLLATE Latin1_General_100_CI_AS_KS_WS, -- COLLATE Latin1_General_CI_AS_KS_WS,
		name VARCHAR(255) COLLATE Latin1_General_100_CI_AS_KS_WS, -- COLLATE Latin1_General_CI_AS_KS_WS,
		path VARCHAR(255) COLLATE Latin1_General_100_CI_AS_KS_WS, -- COLLATE Latin1_General_CI_AS_KS_WS,
		concatStr VARCHAR(2000) COLLATE Latin1_General_100_CI_AS_KS_WS -- COLLATE Latin1_General_CI_AS_KS_WS
	)

	;WITH d AS (
		SELECT DISTINCT path,
			name,
			mnthday AS lbl,
			mnthdaybit AS bm
		FROM #t_rep
	)
	INSERT INTO #t_type_shed (type,path,name,concatStr)
	SELECT 'monthday' AS type,
		t1.path,t1.name,
		STUFF((
			SELECT ', ' + CAST(lbl AS VARCHAR(MAX))
			FROM d AS t2
			WHERE t2.path=t1.path AND t2.name=t1.name
			ORDER BY bm
			FOR XML PATH(''),TYPE
		).value('.','VARCHAR(MAX)'),1,2,'') AS concatStr
	FROM d AS t1
	GROUP BY t1.path,t1.name

	;WITH d AS (
		SELECT DISTINCT path,
			name,
			wkday AS lbl,
			wkdaybit AS bm
		FROM #t_rep
	)
	INSERT INTO #t_type_shed (type,path,name,concatStr)
	SELECT 'weekday' AS type,
		t1.path,t1.name,
		STUFF((
			SELECT ', ' + CAST(lbl AS VARCHAR(MAX))
			FROM d AS t2
			WHERE t2.path=t1.path AND t2.name=t1.name
			ORDER BY bm
			FOR XML PATH(''),TYPE
		).value('.','VARCHAR(MAX)'),1,2,'') AS concatStr
	FROM d AS t1
	GROUP BY t1.path,t1.name

	;WITH d AS (
		SELECT DISTINCT path,
			name,
			mnth AS lbl,
			mnthbit AS bm
		FROM #t_rep
	)
	INSERT INTO #t_type_shed (type,path,name,concatStr)
	SELECT 'month' AS type,
		t1.path,t1.name,
		STUFF((
			SELECT ', ' + CAST(lbl AS VARCHAR(MAX))
			FROM d AS t2
			WHERE t2.path=t1.path AND t2.name=t1.name
			ORDER BY bm
			FOR XML PATH(''),TYPE
		).value('.','VARCHAR(MAX)'),1,2,'') AS concatStr
	FROM d AS t1
	GROUP BY t1.path,t1.name


	/* PUT EVERYTHING TOGETHER FOR THE REPORT */
	DROP TABLE IF EXISTS #t_sched

	SELECT 
		a.ItemID,
		a.SubscriptionID,
		a.path,a.name,a.sched_type,
		a.creationdate,a.modifieddate,
		a.description AS sched_desc,
		a.laststatus AS sched_laststatus,
		a.lastruntime AS sched_lastrun,
		a.inactiveflags AS sched_inactive,
		CASE RecurrenceType
			WHEN 1 THEN 'Run once on '
			ELSE 'Starting on '
		--END + CAST(StartDate AS VARCHAR(32)) + ' ' +
	    END + format(StartDate, 'dd.MM.yyyy hh:mm') + ' ' +
		CASE RecurrenceType
			WHEN 1 THEN ''
			WHEN 2 THEN 'repeat every ' + CAST(MinutesInterval AS VARCHAR(255)) + ' minutes.'
			WHEN 3 THEN 'repeat every ' + CAST(DaysInterval AS VARCHAR(255)) + ' days.'
			WHEN 4 THEN 
				CASE
					WHEN WeeksInterval>1 THEN 'repeat every ' + CAST(WeeksInterval AS VARCHAR(255)) + ' on ' + COALESCE(wkdays.concatStr,'')
					ELSE 'repeat every ' + COALESCE(wkdays.concatStr,'')
				END
			WHEN 5 THEN 'repeat every ' + COALESCE(mnths.concatStr,'') + ' on calendar day(s) '  + COALESCE(mnthdays.concatStr,'')
			WHEN 6 THEN 'run on the ' + CASE MonthlyWeek WHEN 1 THEN '1st' WHEN 2 THEN '2nd' WHEN 3 THEN '3rd' WHEN 4 THEN '4th' WHEN 5 THEN 'Last' END + ' week of ' + COALESCE(mnths.concatStr,'') + ' on ' + COALESCE(wkdays.concatStr,'')
		END AS sched_pattern
	INTO #t_sched
	FROM (
		SELECT DISTINCT 
			ItemID,
			path,
			name,
			creationdate,
			modifieddate,
			SubscriptionID,
			description,
			laststatus,
			lastruntime,
			inactiveflags,
			sched_type,
			recurrencetype,
			startdate,
			minutesinterval,
			daysinterval,
			weeksinterval,
			monthlyweek
		FROM #t_rep
	) AS a
	LEFT JOIN #t_type_shed AS mnthdays ON mnthdays.path=a.path AND mnthdays.name=a.name AND mnthdays.type='monthday'
	LEFT JOIN #t_type_shed AS wkdays ON wkdays.path=a.path AND wkdays.name=a.name AND wkdays.type='weekday'
	LEFT JOIN #t_type_shed AS mnths ON mnths.path=a.path AND mnths.name=a.name AND mnths.type='month'





	DROP TABLE IF EXISTS #t_Report_Subscriptions

	SELECT TOP 0
		GuidОтчета = C.ItemID,
		[Название отчета] = C.Name,
		[Путь к отчету] = C.Path,
		[Название подписки] = SB.Description,
		[Тип расписания] = SB.EventType,
		[Тип] = iif(SB.DataSettings IS NULL, N'Стандартный', N'Управляется данными'),
		[Доставка] = SB.DeliveryExtension,
		[Последний запуск] = SB.LastRunTime,
		[Результат] = SB.LastStatus,
		Кому = cast(NULL AS varchar(8000)),
		Копия = cast(NULL AS varchar(8000)),
		СкрытаяКопия = cast(NULL AS varchar(8000)),
		Расписание = cast(NULL AS nvarchar(4000))
	INTO #t_Report_Subscriptions
	FROM [C2-VSR-BIRS].ReportServer.dbo.Catalog AS C
		LEFT JOIN [C2-VSR-BIRS].ReportServer.dbo.Subscriptions AS SB
			ON C.ItemID = SB.Report_OID
	WHERE 1=1

	INSERT #t_Report_Subscriptions
	SELECT 
		GuidОтчета = C.ItemID,
		[Название отчета] = C.Name,
		[Путь к отчету] = C.Path,
		[Название подписки] = SB.Description,
		[Тип расписания] = SB.EventType,
		[Тип] = iif(SB.DataSettings IS NULL, N'Стандартный', N'Управляется данными'),
		[Доставка] = SB.DeliveryExtension,
		[Последний запуск] = SB.LastRunTime,
		[Результат] = SB.LastStatus,
		Кому = e_TO.SubscriberList,
		Копия = e_CC.SubscriberList,
		СкрытаяКопия = e_BCC.SubscriberList,
		Расписание = SCH.sched_pattern COLLATE Cyrillic_General_CI_AS
	FROM [C2-VSR-BIRS].ReportServer.dbo.Catalog AS C
		INNER JOIN [C2-VSR-BIRS].ReportServer.dbo.Subscriptions AS SB
			ON C.ItemID = SB.Report_OID
		LEFT JOIN #t_email_addresses AS e_TO
			ON e_TO.SubscriptionID = SB.SubscriptionID
			AND e_TO.SubscriberType = 'TO'
		LEFT JOIN #t_email_addresses AS e_CC
			ON e_CC.SubscriptionID = SB.SubscriptionID
			AND e_CC.SubscriberType = 'CC'
		LEFT JOIN #t_email_addresses AS e_BCC
			ON e_BCC.SubscriptionID = SB.SubscriptionID
			AND e_BCC.SubscriberType = 'BCC'
		LEFT JOIN #t_sched AS SCH
			ON SCH.SubscriptionID = SB.SubscriptionID
	WHERE 1=1
		AND SB.InactiveFlags = 0
		--AND C.Name IN (
		--	N'TEST Отчет по Верификации FEDOR Installment'
		--	--N'Отчет по Верификации FEDOR Installment'
		--)
		AND SB.EventType IN ('TimedSubscription')
		AND SB.DeliveryExtension IN ('Report Server Email')

	SELECT DISTINCT
		R.GuidОтчета,
		R.[Название отчета],
		R.[Путь к отчету],
		R.[Название подписки],
		R.[Тип расписания],
		R.Тип,
		R.Доставка,
		R.[Последний запуск],
		R.Результат,
		R.Кому,
		R.Копия,
		R.СкрытаяКопия,
		R.Расписание
	FROM #t_Report_Subscriptions AS R
	ORDER BY R.[Путь к отчету], R.[Название отчета]

	RETURN 0

END TRY
BEGIN CATCH
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(13)+char(10)
		+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))+char(13)+char(10)
		+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(13)+char(10)
		+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')+char(13)+char(10)
		+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(13)+char(10)
		+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
			ROLLBACK;

	SELECT @message = 'EXEC dbo.Report_birs_Report_Subscriptions'

	SELECT @eventType = 'error'

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @eventName ,
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END