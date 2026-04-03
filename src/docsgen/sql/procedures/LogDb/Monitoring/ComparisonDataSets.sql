
CREATE   PROCEDURE [Monitoring].[ComparisonDataSets]
     @sourceTable				nvarchar(255)
	 ,@targetTable				nvarchar(255)
	 ,@sourceColumns			nvarchar(MAX)
	 ,@targetColumns			nvarchar(MAX)
	 ,@periodColumns			nvarchar(MAX) = NULL
	 ,@isSendToEmail			bit = 0
	 ,@selectComparisonResult	bit = 1
	 ,@emailList				nvarchar(max) = ''
	 ,@tableTitle				nvarchar(255) = ''
	 ,@emailSubject				nvarchar(255) = ''
	 ,@rowsInEmail				int  = 100
	 ,@isDebug					bit = 0
	 ,@sourceWhereCondition		nvarchar(max) = ''
	 ,@targetWhereCondition		nvarchar(max) = ''
	 ,@joinCondition		nvarchar(max) = ''

	 ,@columnsToSelect			nvarchar(max) = ''

AS
BEGIN
    BEGIN TRY
		
if isnull(len(@joinCondition),0) = 0 
begin
	;throw 51001, 'Условие соединения таблиц не было задано!', 16
end
if isnull(len(@periodColumns),0) = 0 
begin
	;throw 51002, 'Колонки для отслеживания периода не были заданы!', 16
end

DECLARE @sourceQuery nvarchar(1024)
	IF @sourceWhereCondition IS NOT NULL AND LEN(@sourceWhereCondition) > 0
		BEGIN
			SET @sourceQuery = concat_ws(' ', 'SELECT', @sourceColumns, 'FROM', @sourceTable,'WHERE',@sourceWhereCondition)
		END
	ELSE
		BEGIN
			SET @sourceQuery = concat_ws(' ', 'SELECT', @sourceColumns, 'FROM', @sourceTable)
		END

DECLARE @targetQuery nvarchar(1024)
	IF @targetWhereCondition IS NOT NULL AND LEN(@targetWhereCondition) > 0
		BEGIN
			SET @targetQuery = concat_ws(' ', 'SELECT', @targetColumns, 'FROM', @targetTable,'WHERE',@targetWhereCondition)
		END
	ELSE
		BEGIN
			SET @targetQuery = concat_ws(' ', 'SELECT', @targetColumns, 'FROM', @targetTable)
		END

DECLARE @sourceErrorMessage NVARCHAR(1024)
DECLARE @targetErrorMessage NVARCHAR(1024)
SELECT @sourceErrorMessage = STRING_AGG(error_message, ' ') FROM sys.dm_exec_describe_first_result_set( @sourceQuery , NULL, 0)
SELECT @targetErrorMessage = STRING_AGG(error_message, ' ') FROM sys.dm_exec_describe_first_result_set ( @targetQuery , NULL, 0)
IF @isDebug = 1
begin
	select @sourceQuery as sourceQuery
	select @targetQuery as targetQuery
	select @sourceErrorMessage as sourceErrorMessage
	select @targetErrorMessage as targetErrorMessage
end
IF @sourceErrorMessage IS NOT NULL
	 BEGIN
		 ; THROW 50000, @sourceErrorMessage, 1
	 END
 
IF @targetErrorMessage IS NOT NULL
	BEGIN
		; THROW 50001, @targetErrorMessage, 1
	END

if isnull(len(@columnsToSelect),0) = 0
begin
	SELECT @columnsToSelect =  STRING_AGG(NAME, ', ') FROM sys.dm_exec_describe_first_result_set(@sourceQuery, NULL, 0)
	SELECT @columnsToSelect = string_agg(stg.column_value, ', ')
		FROM (
			SELECT concat('subQuery.', trim(value)) AS column_value
			FROM STRING_SPLIT(@columnsToSelect, ',')
		) AS stg
	
	SELECT @columnsToSelect = CONCAT( @columnsToSelect
		, ', '
		, (
		SELECT string_agg(frmt.column_value, ', ')
		FROM (
			SELECT concat('format(stg.', trim(value),', ''dd.MM.yyyy hh:mm:ss'')') AS column_value
			FROM string_split(@periodColumns, ',')
			) as frmt
		)
	)
end
DECLARE @columnsList nvarchar(2048)
SELECT @columnsList = STRING_AGG(NAME, ', ') FROM sys.dm_exec_describe_first_result_set(@sourceQuery,NULL,0)
SET @columnsList = CONCAT_WS(', ', @columnsList, @periodColumns)
DECLARE @columnsWithTypes nvarchar(2048)
SELECT @columnsWithTypes = STRING_AGG(CONCAT(column_value,  ' NVARCHAR(MAX)'), ', ')
	FROM (
		SELECT value AS column_value
		FROM STRING_SPLIT(@columnsList, ',')
	) AS Columns


DECLARE @t_table_name NVARCHAR(255) = QUOTENAME(CONCAT(
	'##t_missing_rows',
		cast(
			HASHBYTES('SHA2_256',
				CONCAT(@sourceTable, '|', @targetTable)
			) AS UNIQUEIDENTIFIER)
	 ))

DECLARE @createTableSQL NVARCHAR(MAX) = CONCAT_WS(' '
	, 'CREATE TABLE'
	, @t_table_name
	, '('
	)

DECLARE @cmdDropTable nvarchar(1024) = concat_ws(' ', 'DROP TABLE IF EXISTS', @t_table_name)
EXEC(@cmdDropTable)

SET @createTableSQL =CONCAT_WS(' ', @createTableSQL, @columnsWithTypes, ')')
	 -- select @createTableSQL
if @isDebug = 1
	begin
		select @createTableSQL as createTableSQL
	end
	
EXEC sp_executesql @createTableSQL

DECLARE @insertDataSQL NVARCHAR(MAX) = CONCAT_WS (' '
	, 'INSERT INTO', @t_table_name, '(', @columnsList, ')'
	, 'SELECT'
	, @columnsToSelect
	, 'FROM ('
	, @sourceQuery
	, 'EXCEPT'
	, @targetQuery
	, ') subQuery'
	, 'JOIN'
	, @sourceTable
	, 'stg ON'
	, @joinCondition
	, 'SET @insertedRowsCount = @@ROWCOUNT'
)

if @isDebug = 1
	begin
		select @sourceQuery		as sourceQuery
		select @targetQuery		as targetQuery
		select @insertDataSQL	as insertDataSQL
	end
		
		DECLARE @insertedRowsCount bigint
		EXEC sp_executesql @insertDataSQL, N'@insertedRowsCount bigint out', @insertedRowsCount output
		declare @cmdselectComparisonResult NVARCHAR(3000) =  CONCAT_WS(' ', 'SELECT * FROM', @t_table_name)
		
		if @insertedRowsCount>0
			begin
				declare @html_result NVARCHAR(max)
				set @cmdselectComparisonResult= CONCAT_WS(' ', 'SELECT TOP(',@rowsInEmail,')* FROM', @t_table_name)
		
				if @isSendToEmail = 1 and isnull(len(@emailList),0)>0
				begin
					declare @tableSubject nvarchar(255) = CONCAT_WS(' '
					, 'Записи в таблице'
					, @sourceTable
					, 'отсутствующие в таблице'
					, @targetTable
					, '.'
					, '<br />'
					, 'Всего строк:'
					, @insertedRowsCount)
					if @insertedRowsCount >= @rowsInEmail
					begin
					    set @tableSubject = concat_ws(' '
					        , @tableSubject
					        , '<br />'
					        , 'Выведено:'
					        , @rowsInEmail)
					end
					else
					begin
					    set @tableSubject = concat_ws(' '
					        , @tableSubject
					        , '<br />'
					        , 'Выведено:'
					        , @insertedRowsCount)
					end
					if @sourceWhereCondition IS NOT NULL AND LEN(@sourceWhereCondition) > 0
					begin
						set @tableSubject = concat_ws(' '
							, @tableSubject
							, '.'
							, '<br />'
							, 'Применено условие:'
							, @sourceWhereCondition)
					end
		
					EXEC logDb.dbo.ConvertQuery2HTMLTable  
						@SQLQuery = @cmdselectComparisonResult
						,@title = @tableTitle
						,@tableSubject = @tableSubject
						,@isDebug = @isDebug
						,@html_result = @html_result out
					
					EXEC msdb.dbo.sp_send_dbmail  
						@recipients = @emailList,  
						@body = @html_result,  
						@body_format='HTML', 
						@subject = @emailSubject 
				end
			end
		if @selectComparisonResult = 1
		begin
			exec (@cmdselectComparisonResult)
		end
 END try
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END