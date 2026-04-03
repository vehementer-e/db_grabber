/*
exec Monitoring.DQ_dm_CMRStatBalance4_Move2Archive
	@isDebug = 1,
	@SendEmail = 1
*/
-- ============================================= 
-- Author: А. Никитин
-- Create date: 02.10.2025
-- Description: T_DWH-286 Реализовать мониторинг по договорам, перенесенным в архив
-- ============================================= 
CREATE   PROC [Monitoring].[DQ_dm_CMRStatBalance4_Move2Archive]
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
	DECLARE @processType nvarchar(255) = 'contractMove2Archive'

	DECLARE @table_name varchar(256) = 'dwh2.dbo.dm_CMRStatBalance'

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @SendEmail = isnull(@SendEmail, 0)

	SELECT @eventName = 'Monitoring_DQ_dm_CMRStatBalance4_Move2Archive'
	--SELECT @event_name = concat('Мониторинг качества данных ', @table_name)
	--SELECT @eventName = 'В балансе есть данные с остатком для аннулированных договоров'

	DROP TABLE IF EXISTS #t_Monitoring

	CREATE TABLE #t_Monitoring
	(
		rn int,

		ДатаЗакрытияДоговора date,
		КодДоговораЗайма nvarchar(30),
		GuidДоговораЗайма uniqueidentifier,
		СсылкаДоговораЗайма binary(16),

		СуммаПоступленийНарастающимИтогом money,
		ИтогоУплачено money,
		ИтогоНачислено money,
		pay_total money
	)


	;with cte as(
	select 
		д.ДатаЗакрытияДоговора
		,д.КодДоговораЗайма
		,д.GuidДоговораЗайма
		,д.СсылкаДоговораЗайма
		,СуммаПоступленийНарастающимИтогом = b.[сумма поступлений  нарастающим итогом]
		,ИтогоУплачено = ([основной долг уплачено нарастающим итогом]
				+[Проценты уплачено  нарастающим итогом]
				+[ПениУплачено  нарастающим итогом]
				+[ГосПошлинаУплачено  нарастающим итогом]
				)
		,ИтогоНачислено = ([основной долг начислено нарастающим итогом]
				+[Проценты начислено  нарастающим итогом]
				+[ПениНачислено  нарастающим итогом]
				+[ГосПошлинаНачислено  нарастающим итогом]
				)
		,pay_total
	from dwh2.hub.ДоговорЗайма д
		inner join dwh2.[dbo].[dm_CMRStatBalance] b  
			on b.external_id =д.КодДоговораЗайма
			and b.d = д.ДатаЗакрытияДоговора
			and [сумма поступлений  нарастающим итогом]>
				([основной долг уплачено нарастающим итогом]
				+[Проценты уплачено  нарастающим итогом]
				+[ПениУплачено  нарастающим итогом]
				+[ГосПошлинаУплачено  нарастающим итогом]
				)
		left join dwh2.[sat].[ДоговорЗайма_ТекущийСтатус] ТекущийСтатус
			on ТекущийСтатус.[GuidДоговораЗайма] =  д.GuidДоговораЗайма
	where ДатаЗакрытияДоговора between '2024-01-01' and '2025-09-01'
		and ТекущийСтатусДоговора = 'Погашен'
	)
	INSERT #t_Monitoring
	(
		rn,

		ДатаЗакрытияДоговора,
		КодДоговораЗайма,
		GuidДоговораЗайма,
		СсылкаДоговораЗайма,

		СуммаПоступленийНарастающимИтогом,
		ИтогоУплачено,
		ИтогоНачислено,
		pay_total
	)
	select 
		rn = row_number() OVER(ORDER BY c.КодДоговораЗайма),

		c.ДатаЗакрытияДоговора,
		c.КодДоговораЗайма,
		c.GuidДоговораЗайма,
		c.СсылкаДоговораЗайма,

		c.СуммаПоступленийНарастающимИтогом,
		c.ИтогоУплачено,
		c.ИтогоНачислено,
		c.pay_total
	--into #t
	from cte as c
	where (c.ИтогоУплачено = 0
		or c.ИтогоНачислено = 0)

	CREATE CLUSTERED INDEX ix1 ON #t_Monitoring(КодДоговораЗайма)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Monitoring
		SELECT * INTO ##t_Monitoring FROM #t_Monitoring
	END

	DROP TABLE IF EXISTS #t_contract
	CREATE TABLE #t_contract(contractGuid nvarchar(36))

	SELECT @count_rows = count(*)
	FROM #t_Monitoring AS M

	IF @count_rows > 0
	BEGIN
		SELECT @eventType = 'warning'
		SELECT @message = concat(
				'В ', @table_name, 
				' есть неактуальные данные по договорам, перенесенным в архив.',
				cast(@count_rows as varchar(5))
			)

		SELECT @eventName = concat(
				'В балансе есть неактуальные данные по договорам (',
				cast(@count_rows as varchar(5)),
				'), перенесенным в архив'
			)

		INSERT #t_contract(contractGuid)
		SELECT DISTINCT top(100) M.GuidДоговораЗайма
		FROM #t_Monitoring AS M
		where 1=1
			and not exists(
				select top(1) 1
				from Stg.etl.ReloadData4Contract as t
				where t.external_id = M.КодДоговораЗайма
					and cast(t.CreatedAt as date) = cast(getdate() as date)
					and t.ProcessType = @processType
			)

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_contract
			SELECT * INTO ##t_contract FROM #t_contract
		END

		SELECT @description = 
			(SELECT
				'TableName' = @table_name,
				'Message' = 'Найдены неактуальные данные по договорам, перенесенным в архив. Количество договоров: ' + convert(varchar(10), @count_rows)
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)

		--var.2 html
		SELECT @eventMessageText = concat(
			'<table cellspacing="0" border="1" cellpadding="5">',
			--'<tr><td><b>Договор</b></td><td><b>Количество дублей</b></td></tr>', 
			'<tr>',
			'<td><b>#</b></td>',
			'<td><b>Договор</b></td>',
			'<td><b>Дата закрытия</b></td>',
			'<td><b>Сумма поступлений нарастающим итогом</b></td>',
			'<td><b>Итого Уплачено</b></td>',
			'<td><b>Итого Начислено</b></td>',
			'</tr>', 
			(
				SELECT string_agg(
					cast(
						concat(
							'<tr>',
							'<td>',convert(varchar(5), t.rn),'</td>',
							'<td>',t.КодДоговораЗайма,'</td>',
							'<td>',format(t.ДатаЗакрытияДоговора,'dd.MM.yyyy'),'</td>',
							'<td>',convert(varchar(10), t.СуммаПоступленийНарастающимИтогом),'</td>',
							'<td>',convert(varchar(10), t.ИтогоУплачено),'</td>',
							'<td>',convert(varchar(10), t.ИтогоНачислено),'</td>',
							'</tr>'
						)
						as nvarchar(max)
					), ' '
				) WITHIN GROUP (ORDER BY t.rn)
				FROM #t_Monitoring AS t
			),
			'</table>'
		)
	END
	ELSE BEGIN
		SELECT @eventType = 'info'
		SET @message = concat('Таблица ', @table_name, '. ',
			'Не найдены неактуальные данные по договорам, перенесенным в архив.'
			)
		SELECT @description = 
			(SELECT
				'TableName' = @table_name,
				'Message' = 'Не найдены неактуальные данные по договорам, перенесенным в архив.'
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		SELECT @eventMessageText = NULL, @SendEmail = 0
	END

	--Перегрузить данные если сработал мониторинг
	IF EXISTS(SELECT TOP 1 1 FROM #t_contract)
		AND @isDebug = 0
		--пока не перегружать
		--AND 1=2
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
				--@processType = 'ReloadData4StrategyDatamartByContract'
				@processType = @processType

			FETCH NEXT FROM cur_contract INTO @contractGuid
		END

		CLOSE cur_contract
		DEALLOCATE cur_contract
	END

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
