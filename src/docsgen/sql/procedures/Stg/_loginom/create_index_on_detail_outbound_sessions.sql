--DWH-1877
--создание для таблицы NaumenDbReport.dbo.detail_outbound_sessions
--индексов с фильтром attempt_start >= <date>
-- Usage: запуск процедуры с параметрами
-- EXEC _loginom.create_index_on_detail_outbound_sessions
--      @index_name = '',
--      @isDebug = 0;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   PROC _loginom.create_index_on_detail_outbound_sessions
	@index_name varchar(255) = '',
	@isDebug int = 0
AS
BEGIN

	SET XACT_ABORT ON

	DECLARE @sql nvarchar(max) -- @date_2_day date, @date_6_month date
	DECLARE @date_8_month date

	SELECT @isDebug = isnull(@isDebug, 0)

	SELECT @date_8_month = cast(dateadd(MONTH, -8, getdate()) AS date)
	--SELECT @date_6_month = cast(dateadd(MONTH, -6, getdate()) AS date)
	--SELECT @date_2_day = cast(dateadd(DAY, -1, getdate()) AS date)

	/*
	--индекс по данным за 2 дня
	IF @index_name = 'ix_attempt_start_2_day'
	BEGIN
		SELECT @sql = 'DROP INDEX IF EXISTS ix_attempt_start_2_day ON dbo.detail_outbound_sessions'
		SELECT @sql
		--EXEC sp_executesql @sql

		SELECT @sql = concat(
'CREATE INDEX ix_attempt_start_2_day
ON dbo.detail_outbound_sessions(attempt_start)
INCLUDE (client_number)
WHERE attempt_start >= ''', convert(varchar(10), @date_2_day, 120), '''')
		SELECT @sql
		--EXEC sp_executesql @sql
	END
	*/

	--индекс по данным за 8 месяцев
	IF @index_name = 'ix_attempt_start_3'
	BEGIN
		SELECT @sql = 'DROP INDEX IF EXISTS ix_attempt_start_3 ON dbo.detail_outbound_sessions'
		--SELECT @sql
		EXEC sp_executesql @sql

		SELECT @sql = concat(
'CREATE INDEX ix_attempt_start_3
ON dbo.detail_outbound_sessions(client_number, attempt_end DESC, attempt_number DESC)
INCLUDE (attempt_start, project_id, attempt_result)
WHERE attempt_start >= ''', convert(varchar(10), @date_8_month, 120), '''')
		--SELECT @sql
		EXEC sp_executesql @sql
	END

	/*
	--индекс по данным за 6 месяцев
	IF @index_name = 'ix_client_number_6_month'
	BEGIN
		SELECT @sql = 'DROP INDEX IF EXISTS ix_client_number_6_month ON dbo.detail_outbound_sessions'
		SELECT @sql
		--EXEC sp_executesql @sql

		SELECT @sql = concat(
'CREATE INDEX ix_client_number_6_month
ON dbo.detail_outbound_sessions(client_number)
WHERE attempt_start >= ''', convert(varchar(10), @date_6_month, 120), '''')
		SELECT @sql
		--EXEC sp_executesql @sql
	END
	*/

END
