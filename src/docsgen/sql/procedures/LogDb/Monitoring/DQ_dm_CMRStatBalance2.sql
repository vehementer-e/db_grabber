
-- ============================================= 
-- Author: А. Никитин
-- Create date: 24.10.2023
-- Description: DWH-2272 Мониторинг погашения договора задним числом
-- ============================================= 
CREATE PROC [Monitoring].[DQ_dm_CMRStatBalance2]
	@isDebug int = 0,
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@SendEmail int = 0
AS
BEGIN
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @isWarning int = 0,
		@message nvarchar(1024) = '',
		@description nvarchar(1024), 
		@eventType varchar(1024), -- например: 'error', 'info', 'warning'
		@eventName varchar(1024), -- например: 'task_start', 'create_balance', 'create_indexes', 'data_quality_check'
		--@event_name varchar(256), -- например: 'Заполнение витрины ...', 'Расчет баланса'
		@eventMessageText nvarchar(max) -- большое сообщение для расширенного логирования
	DECLARE @count_rows int
	DECLARE @contractGuid nvarchar(36)

	DECLARE @table_name varchar(256) = 'dwh2.dbo.dm_CMRStatBalance'

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @SendEmail = isnull(@SendEmail, 0)

	SELECT @eventName = 'Monitoring_DQ_dm_CMRStatBalance2'
	--SELECT @event_name = concat('Мониторинг качества данных ', @table_name)

	drop table if  exists #balance_contact
	select t.external_id
		,d = max(t.d)
		,ContractStartDate =  min(t.ContractStartDate)
		,ContractEndDate = max(t.ContractEndDate)
	into #balance_contact
	from dwh2.dbo.dm_CMRStatBalance AS t
	
	group by t.external_id

	drop table if exists #t_last_status

	select 
		СтатусДоговораНаименование = СтатусДоговора.Наименование,
		ДоговорНомер = Договор.Код,
		ДоговорСсылка = Договор.Ссылка,
		ДоговорGuid = dwh2.dbo.getGUIDFrom1C_IDRREF(Договор.Ссылка),
		СтатусДоговораДата=dateadd(year,-2000,sd.Период)
		,bac.d
		,bac.ContractStartDate
		,bac.ContractEndDate
		,NeedCheck= iif(СтатусДоговора.Наименование not in (
			'Действует',
			'Просрочен',
			'Проблемный',
			'Платеж опаздывает',
			'Legal',
			'Решение суда',
			'Внебаланс'), 1, 0)
	into #t_last_status
	from (
		select 
			sd.Договор
			,Период = max(sd.Период)
		from stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
		group by  Договор
		) AS last_status
		inner join stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
			on sd.Договор =last_status.Договор
			and sd.Период = last_status.Период
		inner join stg._1ccmr.Справочник_СтатусыДоговоров AS СтатусДоговора 
			on СтатусДоговора.Ссылка = sd.Статус
		inner join stg._1cCMR.Справочник_Договоры AS Договор
			ON Договор.Ссылка = sd.Договор
		inner join #balance_contact AS bac
			ON bac.external_id = Договор.Код
	where СтатусДоговора.Наименование not in ('Аннулирован', 'Зарегистрирован')


	DROP TABLE IF EXISTS #t_contract
	CREATE TABLE #t_contract(contractGuid nvarchar(36))

	DROP TABLE IF EXISTS #t_Monitoring
	CREATE TABLE #t_Monitoring
	(
		rn int,
		[СтатусДоговораНаименование] nvarchar(100) NULL,
		[ДоговорНомер] nvarchar(30),
		ДоговорСсылка binary(16),
		ДоговорGuid nvarchar(36),
		[СтатусДоговораДата] datetime2(0),
		[d] datetime2(0),
		[ContractStartDate] datetime2(0),
		[ContractEndDate] datetime2(0),
		[NeedCheck] int,
		[diff] int
	)
	--test
	/*
	INSERT #t_Monitoring
	(
	    СтатусДоговораНаименование,
	    ДоговорНомер,
	    СтатусДоговораДата,
	    d,
	    ContractStartDate,
	    ContractEndDate,
	    NeedCheck,
	    diff
	)
	VALUES
	(   N'Test',           -- СтатусДоговораНаименование - nvarchar(100)
	    N'1234567890',           -- ДоговорНомер - nvarchar(30)
	    sysdatetime(), -- СтатусДоговораДата - datetime2(0)
	    sysdatetime(), -- d - datetime2(0)
	    sysdatetime(), -- ContractStartDate - datetime2(0)
	    sysdatetime(), -- ContractEndDate - datetime2(0)
	    1,             -- NeedCheck - int
	    10              -- diff - int
	    )
	*/

	INSERT #t_Monitoring
	(
		rn,
	    СтатусДоговораНаименование,
	    ДоговорНомер,
		ДоговорСсылка,
		ДоговорGuid,
	    СтатусДоговораДата,
	    d,
	    ContractStartDate,
	    ContractEndDate,
	    NeedCheck,
	    diff
	)
	SELECT
		rn = row_number() OVER(ORDER BY t.ДоговорНомер),
		t.СтатусДоговораНаименование,
        t.ДоговорНомер,
		t.ДоговорСсылка,
		t.ДоговорGuid,
        t.СтатусДоговораДата,
        t.d,
        t.ContractStartDate,
        t.ContractEndDate,
        t.NeedCheck
		,diff = datediff(dd, t.ContractEndDate, t.СтатусДоговораДата)
	from #t_last_status AS t
	where t.NeedCheck =1 
	and (cast(t.СтатусДоговораДата as date) <> t.ContractEndDate  or t.ContractEndDate is null)
	and cast(t.СтатусДоговораДата as date) <> cast(getdate() as date)

	
	SELECT @count_rows = count(*)
	FROM #t_Monitoring AS M

	IF @count_rows > 0
	BEGIN
		SELECT @eventType = 'warning'
		SELECT @message = concat('В ', @table_name, ' есть данные после погашения договора.')

		INSERT #t_contract(contractGuid)
		SELECT DISTINCT M.ДоговорGuid 
		FROM #t_monitoring AS M

		SELECT @description = 
			(SELECT
				'TableName' = @table_name,
				'Message' = 'Найдены данные после погашения договора. Количество записей: ' + convert(varchar(10), @count_rows)
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)

		--var.2 html
		SELECT @eventMessageText = concat(
			'<table cellspacing="0" border="1" cellpadding="5">',
			--'<tr><td><b>Договор</b></td><td><b>Количество дублей</b></td></tr>', 
			'<tr>',
			'<td><b>#</b></td>',
			'<td><b>Договор</b></td>',
			'<td><b>Статус договора</b></td>',
			'<td><b>Дата статуса</b></td>',
			'<td><b>Период</b></td>',
			'<td><b>Дата<br> начала<br> договора</b></td>',
			'<td><b>Дата<br> окончания<br> договора</b></td>',
			'<td><b>Кол-во дней между<br> Датой окончания договора<br> и Датой Статуса</b></td>',
			'</tr>', 
			(
				SELECT string_agg(
					concat(
						'<tr>',
						'<td>',convert(varchar(5), t.rn),'</td>',
						'<td>',t.ДоговорНомер,'</td>',
						'<td>',t.СтатусДоговораНаименование,'</td>',
						'<td>',format(t.СтатусДоговораДата,'dd.MM.yyyy HH:mm:ss'),'</td>',
						'<td>',format(t.d,'dd.MM.yyyy'),'</td>',
						'<td>',format(t.ContractStartDate,'dd.MM.yyyy'),'</td>',
						'<td>',format(t.ContractEndDate,'dd.MM.yyyy'),'</td>',
						--t.NeedCheck
						'<td>',convert(varchar(10), t.diff),'</td>',
						'</tr>'
					), ' '
				) WITHIN GROUP (ORDER BY t.ДоговорНомер)
				FROM #t_Monitoring AS t
			),
			'</table>'
		)
	END
	ELSE BEGIN
		SELECT @eventType = 'info'
		SET @message = concat('Таблица ', @table_name, '. ',
			'Ошибки не найдены.'
			)
		SELECT @description = 
			(SELECT
				'TableName' = @table_name,
				'Message' = 'Ошибки не найдены.'
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		SELECT @eventMessageText = NULL, @SendEmail = 0
	END

	--DWH-2316 Перегрузить данные если сработал мониторинг Monitoring_DQ_dm_CMRStatBalance2
	IF EXISTS(SELECT TOP 1 1 FROM #t_contract)
		AND @isDebug = 0
	BEGIN
		DECLARE cur_contract CURSOR FOR
		SELECT DISTINCT C.contractGuid
		FROM #t_contract AS C
		ORDER BY C.contractGuid

		OPEN cur_contract
		FETCH NEXT FROM cur_contract INTO @contractGuid
		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC Stg.etl.runProcessContractUpdate 
				@contractGuid = @contractGuid,
				@processType = 'ReloadData4StrategyDatamartByContract'

			FETCH NEXT FROM cur_contract INTO @contractGuid
		END

		CLOSE cur_contract
		DEALLOCATE cur_contract
	END

	/*
	--новая версия лога
	EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
	*/
	--SELECT * from dbo.Emails

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @eventName,
		@eventType = @eventType,
		@message = @message,
		@description = @description,
		@SendEmail = @SendEmail,
		@ProcessGUID = @ProcessGUID,
		@eventMessageText = @eventMessageText,
		@loggerName = 'admin_test'
END
