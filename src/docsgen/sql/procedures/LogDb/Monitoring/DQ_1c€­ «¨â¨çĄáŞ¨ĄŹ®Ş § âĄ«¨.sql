
-- ============================================= 
-- Author: А. Никитин
-- Create date: 15.02.2023
-- Description: DWH-1945 DQ данных АналитическихПоказателей
-- ============================================= 
create     PROC Monitoring.[DQ_1cАналитическиеПоказатели]
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@SendEmail int = 0
AS
BEGIN
SET NOCOUNT ON;
	DECLARE @html_table nvarchar(max)
	DECLARE @eventName nvarchar(1024),
		@eventType nvarchar(1024), @message nvarchar(1024), @description nvarchar(1024),
		@eventMessageText nvarchar(max) -- большое сообщение для расширенного логирования
	DECLARE @deal_count int
	DECLARE @max_create_at datetime
	DECLARE @table_name varchar(256) = 'Stg.dbo._1cАналитическиеПоказатели'

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @SendEmail = isnull(@SendEmail, 0)

	SELECT @eventName = 'Monitoring_DQ_1cАналитическиеПоказатели'

	DROP TABLE IF EXISTS #t_monitoring
	CREATE TABLE #t_monitoring(
		КодДоговора nvarchar(20),
		ДоговорСсылка binary(16),
		ДатаДоговора datetime2(0),
		ДатаПоследнегоСтатуса datetime2(0),
		ПоследнийСтатус nvarchar(100),
		ДатаПоследнейЗаписи_АП datetime
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
		--договора, по которым есть расчет на сегодня
		LEFT JOIN (
			SELECT DISTINCT Ссылка = AP.Договор
			FROM Stg.dbo._1cАналитическиеПоказатели AS AP (NOLOCK)
			WHERE convert(date, AP.Период) = convert(date, getdate())
		) AS A
		ON D.Ссылка = A.Ссылка
	WHERE 1=1
		AND A.Ссылка IS NULL
	--ORDER BY D.Код

	--также нужна дата на которую есть последняя запись
	--в _1cАналитическиеПоказатели по указанному договору
	UPDATE TM
	SET TM.ДатаПоследнейЗаписи_АП = X.ДатаПоследнейЗаписи_АП
	FROM #t_monitoring AS TM
		INNER JOIN (
			SELECT 
				M.ДоговорСсылка, 
				ДатаПоследнейЗаписи_АП = max(A.Период)
			FROM #t_monitoring AS M
				INNER JOIN Stg.dbo._1cАналитическиеПоказатели AS A
					ON A.Договор = M.ДоговорСсылка
			GROUP BY M.ДоговорСсылка
		) AS X
		ON X.ДоговорСсылка = TM.ДоговорСсылка

	SELECT @deal_count = count(*)
	FROM #t_monitoring AS M

	SELECT @max_create_at = max(A.create_at)
	FROM Stg.dbo._1cАналитическиеПоказатели AS A

	IF @deal_count > 0
	BEGIN
		SELECT @eventType = 'warning'

		SELECT @message = concat('Таблица ', @table_name, '. ',
			'Нет действующих договоров. ',
			' (всего: ', convert(varchar(10), @deal_count), '). ',
			'Дата последней записи: ',
			format(@max_create_at, 'dd.MM.yyyy HH:mm:ss')
			)

		SELECT @description = 
			(SELECT
				'TableName' = @table_name,
				'Message' = 'Количество отсутствующих действующих договоров: ' + convert(varchar(10), @deal_count),
				'max_create_at' = format(@max_create_at, 'dd.MM.yyyy HH:mm:ss')
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)

		SELECT @html_table = (
			SELECT concat(
					'<tr>',
						'<td>', M.КодДоговора, '</td>',
						'<td>', convert(varchar(19), M.ДатаДоговора, 120), '</td>',
						'<td>', convert(varchar(19), M.ДатаПоследнегоСтатуса, 120), '</td>',
						'<td>', M.ПоследнийСтатус, '</td>',
						'<td>', isnull(convert(varchar(19), M.ДатаПоследнейЗаписи_АП, 120),''), '</td>',
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
		--SELECT @html_table
		--SELECT * FROM #t_monitoring AS TM ORDER BY TM.КодДоговора
		--RETURN 0

		SELECT @html_table = 
			concat('<table cellspacing="0" border="1" cellpadding="5">',
					'<tr>',
						'<td><b>Код Договора</b></td>',
						'<td><b>Дата Договора</b></td>',
						'<td><b>Дата Последнего Статуса</b></td>',
						'<td><b>Последний Статус</b></td>',
						'<td><b>Дата Последней Записи в _1cАналитическиеПоказатели</b></td>',
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
			'Действующие договора, которых нет в Stg.dbo._1cАналитическиеПоказатели на ',
			format(getdate(), 'dd.MM.yyyy HH:mm:ss'),
			' (всего: ', convert(varchar(10), @deal_count), '). ',
			'Дата последней записи в _1cАналитическиеПоказатели: ',
			format(@max_create_at, 'dd.MM.yyyy HH:mm:ss')
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

