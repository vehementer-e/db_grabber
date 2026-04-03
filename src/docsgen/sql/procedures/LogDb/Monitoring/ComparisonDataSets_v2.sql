
CREATE PROC Monitoring.ComparisonDataSets_v2
     @sourceTable				NVARCHAR(255),
	 @targetTable				NVARCHAR(255),
	 @sourceColumns				NVARCHAR(MAX),
	 @targetColumns				NVARCHAR(MAX),
	 @periodColumns				NVARCHAR(MAX),
	 @isSendToEmail				bit =0,
	 @selectComparisonResult	bit = 1,
	 @emailList					nvarchar(max) = '',
	 @tableTitle				nvarchar(255) = '',
	 @emailSubject				nvarchar(255) = '',
	 @rowsInEmail				int  = 100,
	 @isDebug					bit = 0,
	 @whereCondition			nvarchar(max) = '',
	 @targetWhereCondition		nvarchar(max) = '',
	 @joinCondition				nvarchar(max) = '',

	 @targetJoinCondition		nvarchar(2048) = NULL,
	 @columnsList				nvarchar(2048) = NULL,
	 @columnsWithAlias			nvarchar(2048) = NULL,
	 @columnsWithTypes			nvarchar(2048) = NULL,
	 @isDropTable				bit = 1,
	 @t_table_name				nvarchar(255) = NULL OUT
	 

AS
BEGIN
	SELECT @isDebug = isnull(@isDebug, 0)

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
			IF @whereCondition IS NOT NULL AND LEN(@whereCondition) > 0
				BEGIN
					SET @sourceQuery = concat_ws(' ', 'SELECT', @sourceColumns, 'FROM', @sourceTable, 'WHERE', @whereCondition)
				END
			ELSE
				BEGIN
					SET @sourceQuery = concat_ws(' ', 'SELECT', @sourceColumns, 'FROM', @sourceTable)
				END

		DECLARE @targetQuery nvarchar(1024)
			IF @targetWhereCondition IS NOT NULL AND LEN(@targetWhereCondition) > 0
				BEGIN
					SET @targetQuery = concat_ws(' ', 'SELECT', @targetColumns, 'FROM', @targetTable, 'WHERE', @targetWhereCondition)
				END
			ELSE
				BEGIN
					SET @targetQuery = concat_ws(' ', 'SELECT', @targetColumns, 'FROM', @targetTable)
				END
		
		--if @isDebug = 1
		--	begin
		--		select @sourceQuery as sourceQuery
		--		SELECT @targetQuery AS targetQuery
		--		--RETURN 0
		--	end

		DECLARE @sourceErrorMessage NVARCHAR(1024)
		DECLARE @targetErrorMessage NVARCHAR(1024)
		SELECT @sourceErrorMessage = STRING_AGG(error_message, ' ') FROM sys.dm_exec_describe_first_result_set( @sourceQuery , NULL, 0)
		SELECT @targetErrorMessage = STRING_AGG(error_message, ' ') FROM sys.dm_exec_describe_first_result_set( @targetQuery , NULL, 0)
		
		IF @sourceErrorMessage IS NOT NULL
			 BEGIN
				 ; THROW 50000, @targetErrorMessage, 1
			 END
		 
		IF @targetErrorMessage IS NOT NULL
			BEGIN
				; THROW 50001, @targetErrorMessage, 1
			END
		
			-- select @sourceErrorMessage
			-- select @targetErrorMessage
		
		
		--DECLARE @columnsList nvarchar(2048)
		-- не передан в параметре
		IF @columnsList IS NULL BEGIN
			SELECT @columnsList = STRING_AGG(NAME, ', ') FROM sys.dm_exec_describe_first_result_set(@sourceQuery, NULL, 0)
			SET @columnsList = concat_ws(', ', @columnsList, @periodColumns)
		END

		-- не передан в параметре
		IF @columnsWithAlias IS NULL BEGIN
			DECLARE @columnsList2 nvarchar(2048)
			SELECT @columnsList2 = STRING_AGG(NAME, ', ') FROM sys.dm_exec_describe_first_result_set(@sourceQuery, NULL, 0)

			SELECT @columnsWithAlias = string_agg(C.column_value, ', ')
				FROM (
					SELECT concat('stg.', trim(value)) AS column_value
					FROM STRING_SPLIT(@columnsList2, ',')
				) AS C

			SELECT @columnsWithAlias = concat(
				@columnsWithAlias, ',',
					(
						SELECT string_agg(C.column_value, ', ')
						FROM (
							SELECT concat('format(stg.', trim(value),', ''dd.MM.yyyy hh:mm:ss'')') AS column_value
							FROM string_split(@periodColumns, ',')
						) AS C
					)
				)
		END

		-- не передан в параметре
		IF @columnsWithTypes IS NULL BEGIN
			SELECT @columnsWithTypes = STRING_AGG(CONCAT(column_value,  ' NVARCHAR(MAX)'), ', ')
				FROM (
					SELECT value AS column_value
					FROM STRING_SPLIT(@columnsList, ',')
				) AS Columns
		END

		SELECT @t_table_name = QUOTENAME(CONCAT(
			'##t_missing_rows',
				cast(
					HASHBYTES('SHA2_256',
						CONCAT_WS('|',@sourceTable, '|', @targetTable, newid())
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
				--RETURN 0
			end
			
		EXEC sp_executesql @createTableSQL
		
		DECLARE @insertDataSQL nvarchar(MAX) 

		SELECT @insertDataSQL  = CONCAT_WS (' '
			, 'INSERT INTO', @t_table_name, '(', @columnsList, ')'
			, 'SELECT'
			--, @sourceColumns
			--, ','
			--, @periodColumns
			, @columnsWithAlias
			, 'FROM ('
			, @sourceQuery
			, 'EXCEPT'
			, @targetQuery
			, ') subQuery'
			, 'JOIN'
			, @sourceTable
			, 'stg ON'
			, @joinCondition
			--, 'SET @insertedRowsCount = @@ROWCOUNT'
		)

		-- передано условие соединения с @targetTable
		IF @targetJoinCondition IS NOT NULL BEGIN
			SELECT @insertDataSQL = concat_ws(' ',
				@insertDataSQL, 'JOIN', @targetTable, 'trg ON', @targetJoinCondition
			)
		END

		SELECT @insertDataSQL = concat_ws(' ', @insertDataSQL, 'SET @insertedRowsCount = @@ROWCOUNT')

		if @isDebug = 1
			begin
				select @sourceQuery		as sourceQuery
				select @targetQuery		as targetQuery
				select @insertDataSQL	as insertDataSQL
			end
		
		DECLARE @insertedRowsCount bigint
		EXEC sp_executesql @insertDataSQL, N'@insertedRowsCount bigint out', @insertedRowsCount output
		declare @cmdselectComparisonResult NVARCHAR(3000) =  CONCAT_WS(' ', 'SELECT * FROM', @t_table_name)
		
		if @isDebug = 1
			BEGIN
				SELECT @cmdselectComparisonResult
				--RETURN 0
			end

		if @insertedRowsCount>0
			begin
				declare @html_result NVARCHAR(max)
				set @cmdselectComparisonResult= CONCAT_WS(' ', 'SELECT TOP(',@rowsInEmail,')* FROM', @t_table_name)
		
				if @isSendToEmail = 1 and isnull(len(@emailList),0)>0
				begin
					declare @tableSubject nvarchar(255) = CONCAT_WS(' '
					, 'Записи в таблице'
					, @sourceTable
					--, 'отсутствующие в таблице', @targetTable
					, iif(@sourceTable<>@targetTable, concat('отсутствующие в таблице ', @targetTable), '')
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
					if @whereCondition IS NOT NULL AND LEN(@whereCondition) > 0
					begin
						set @tableSubject = concat_ws(' '
							, @tableSubject
							, '.'
							, '<br />'
							, 'Применено условие:'
							, @whereCondition)
					end
		
					EXEC logDb.dbo.ConvertQuery2HTMLTable  
						@SQLQuery = @cmdselectComparisonResult
						,@title = @tableTitle
						,@tableSubject = @tableSubject
						,@isDebug = @isDebug
						,@html_result = @html_result out
					
					EXEC msdb.dbo.sp_send_dbmail  
						@profile_name = 'Default',  
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
		if @isDropTable = 1
		begin
			EXEC(@cmdDropTable)
		end
 END try
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END



