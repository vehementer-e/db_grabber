
-- ============================================= 
-- Author: А. Никитин
-- Create date: 15.02.2023
-- Description: DWH-1946 DQ данных РегистрНакопления_РасчетыПоЗаймам
-- ============================================= 
CREATE   PROC Monitoring.DQ_РегистрНакопления_РасчетыПоЗаймам
	@isDebug int = 0,
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@SendEmail int = 0
AS
BEGIN
SET NOCOUNT ON;
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @html_table nvarchar(max)
	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024), @description nvarchar(1024)
	DECLARE @eventMessageText nvarchar(max) -- большое сообщение для расширенного логирования
	DECLARE @deal_count int
	DECLARE @table_name varchar(256) = 'Stg._1cCMR.РегистрНакопления_РасчетыПоЗаймам'

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @SendEmail = isnull(@SendEmail, 0)

	SELECT @eventName = 'Monitoring_DQ_РегистрНакопления_РасчетыПоЗаймам'

	DROP TABLE IF EXISTS #t_deal
	CREATE TABLE #t_deal(
		КодДоговора nvarchar(20),
		ДоговорСсылка binary(16),
		ДатаДоговора datetime2(0),
		ДатаПоследнегоСтатуса datetime2(0),
		ПоследнийСтатус nvarchar(100)
	)

	INSERT #t_deal
	(
	    КодДоговора,
		ДоговорСсылка,
		ДатаДоговора,
	    ДатаПоследнегоСтатуса,
	    ПоследнийСтатус
	)
	SELECT 
		КодДоговора = D.Код,
		ДоговорСсылка = D.Ссылка,
		ДатаДоговора = dateadd(YEAR, -2000, D.Дата),
		ДатаПоследнегоСтатуса = dateadd(YEAR, -2000, RS.Период),
		ПоследнийСтатус = S.Наименование
	FROM (
			SELECT 
				R.Договор,
				max_Период = max(R.Период)
			FROM Stg._1cCMR.РегистрСведений_СтатусыДоговоров AS R (NOLOCK)
			GROUP BY R.Договор
		) AS M
		INNER JOIN Stg._1cCMR.РегистрСведений_СтатусыДоговоров AS RS (NOLOCK)
			ON RS.Договор = M.Договор
			AND RS.Период = M.max_Период
		INNER JOIN Stg._1ccmr.Справочник_СтатусыДоговоров AS S (NOLOCK)
			ON S.Ссылка=RS.Статус
			AND S.Код IN (
				--'000000001', --	Зарегистрирован	registered
				'000000002', --	Действует	valid

				--'000000003', --	Погашен	repaid
				'000000004', --	Legal	legal
				--'000000005', --	Аннулирован	cancelled
				'000000006', --	Решение суда	judgement
				--'000000007', --	Приостановка начислений	delayCalculate
				--'000000008', --	Продан	soldOut
				
				'000000009', --	Проблемный	problem
				'000000010', --	Платеж опаздывает	latePayment
				'000000011', --	Просрочен	expired
				'000000012' --	Внебаланс	offBalance
			)
		INNER JOIN Stg._1cCMR.Справочник_Договоры AS D (NOLOCK)
			ON D.Ссылка = RS.Договор
	--ORDER BY D.Код

	CREATE INDEX ix1 ON #t_deal(ДоговорСсылка)


	DROP TABLE IF EXISTS #t_РасчетыПоЗаймам
	CREATE TABLE #t_РасчетыПоЗаймам(
		ДоговорСсылка binary(16),
		max_Период datetime2(0)
	)

	INSERT #t_РасчетыПоЗаймам
	(
	    ДоговорСсылка,
	    max_Период
	)
	SELECT 
		D.ДоговорСсылка,
		max_Период = max(dateadd(YEAR, -2000, Z.Период))
	FROM #t_deal AS D
		INNER JOIN Stg._1cCMR.РегистрНакопления_РасчетыПоЗаймам AS Z (NOLOCK)
			ON Z.Договор = D.ДоговорСсылка
	GROUP BY D.ДоговорСсылка

	CREATE INDEX ix1 ON #t_РасчетыПоЗаймам(ДоговорСсылка)


	DROP TABLE IF EXISTS #t_monitoring
	CREATE TABLE #t_monitoring(
		КодДоговора nvarchar(20),
		ДоговорСсылка binary(16),
		ДатаДоговора datetime2(0),
		ДатаПоследнегоСтатуса datetime2(0),
		ПоследнийСтатус nvarchar(100),
		ДатаПоследнейЗаписи_РасчетыПоЗаймам datetime
	)

	INSERT #t_monitoring
	(
	    КодДоговора,
	    ДоговорСсылка,
	    ДатаДоговора,
	    ДатаПоследнегоСтатуса,
	    ПоследнийСтатус
	)
	SELECT 
	    D.КодДоговора,
	    D.ДоговорСсылка,
	    D.ДатаДоговора,
	    D.ДатаПоследнегоСтатуса,
	    D.ПоследнийСтатус
	FROM #t_deal AS D
		LEFT JOIN #t_РасчетыПоЗаймам AS Z
			ON Z.ДоговорСсылка = D.ДоговорСсылка
			AND convert(date, Z.max_Период) = convert(date, getdate())
	WHERE Z.ДоговорСсылка IS NULL -- нет данных за сегодня

	--ДатаПоследнейЗаписи_РасчетыПоЗаймам
	UPDATE M
	SET ДатаПоследнейЗаписи_РасчетыПоЗаймам = Z.max_Период
	FROM #t_monitoring AS M
		INNER JOIN #t_РасчетыПоЗаймам AS Z
			ON Z.ДоговорСсылка = M.ДоговорСсылка


	SELECT @deal_count = count(*)
	FROM #t_monitoring AS M
	select * from #t_monitoring
	IF @deal_count > 0
	BEGIN
		SELECT @eventType = 'warning'

		SELECT @message = concat('Таблица ', @table_name, '. ',
			'Нет действующих договоров. ',
			' (всего: ', convert(varchar(10), @deal_count), ')'
			)

		SELECT @description = 
			(SELECT
				'TableName' = @table_name,
				'Message' = 'Количество отсутствующих действующих договоров: ' + convert(varchar(10), @deal_count)
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)

		SELECT @html_table = (
			SELECT concat(
					'<tr>',
						'<td>', M.КодДоговора, '</td>',
						'<td>', convert(varchar(19), M.ДатаДоговора, 120), '</td>',
						'<td>', convert(varchar(19), M.ДатаПоследнегоСтатуса, 120), '</td>',
						'<td>', M.ПоследнийСтатус, '</td>',
						'<td>', isnull(convert(varchar(19), M.ДатаПоследнейЗаписи_РасчетыПоЗаймам, 120),''), '</td>',
					'</tr>'
				)
			FROM #t_monitoring AS M
			--ORDER BY M.КодДоговора
			ORDER BY M.ДатаПоследнегоСтатуса
			FOR XML PATH('')
		)
		SELECT @html_table = replace(@html_table, '&lt;', '<')
		SELECT @html_table = replace(@html_table, '&gt;', '>')

		--test
		IF @isDebug = 1 BEGIN
			--SELECT @html_table
			--SELECT * FROM #t_monitoring AS TM ORDER BY TM.КодДоговора
			DROP TABLE IF EXISTS ##t_monitoring
			SELECT * INTO ##t_monitoring FROM #t_monitoring AS TM

			SELECT @deal_count
			RETURN 0
		END

		SELECT @html_table = 
			concat('<table cellspacing="0" border="1" cellpadding="5">',
					'<tr>',
						'<td><b>Код договора</b></td>',
						'<td><b>Дата договора</b></td>',
						'<td><b>Дата последнего статуса</b></td>',
						'<td><b>Последний статус</b></td>',
						'<td><b>Дата последней записи в РасчетыПоЗаймам</b></td>',
					'</tr>',
					@html_table,
					'</table>'
			)

		SELECT @eventMessageText = @html_table


		/*
		-- OLD
		declare @recipients nvarchar(1024)=''   
		select  @recipients=[emails] 
		from    LogDb.dbo.Emails
		where 	[loggerName]        ='adminlog'    

		declare @tsql nvarchar(max) 
			,@subject nvarchar(1024) 
			,@body nvarchar(max) 

		set @subject = concat(
			'Действующие договора, которых нет в Stg._1cCMR.РегистрНакопления_РасчетыПоЗаймам на ',
			format(getdate(), 'dd.MM.yyyy HH:mm:ss'),
			' (всего: ', convert(varchar(10), @deal_count), ')'
		)

		set @body = concat(
			'<H1>', @subject, '</H1><br><br>', @html_table
		)
	
		if ltrim(rtrim(@recipients)) <>'' 
		begin 
		SET @tsql = '     
			EXEC msdb.dbo.sp_send_dbmail  
				@profile_name = ''Default'',  
				@recipients = ''' + @recipients + ''',  
				@body = '''+ @body+''',  
				@body_format=''HTML'', 
				@subject = '''+@subject+''' 
			'; 
			--SELECT @tsql 
			EXEC (@tsql)
		end 

		--test
		--SELECT @html_table
		--SELECT @subject
		*/
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

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @eventName,
		@eventType = @eventType,
		@message = @message,
		@description = @description,
		@SendEmail = @SendEmail,
		@ProcessGUID = @ProcessGUID,
		@eventMessageText = @eventMessageText
END 

