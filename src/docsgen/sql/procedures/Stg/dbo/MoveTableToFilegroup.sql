

-- exec dbo.MoveTableToFilegroup @table_name='_Collection.AspNetUsers', @filegroup='_Collection'

CREATE   PROCEDURE [dbo].[MoveTableToFilegroup]
(
    @table_name SYSNAME,          -- schema.table
    @key_column NVARCHAR(MAX) = NULL, -- 'col1' или 'col1,col2'
    @filegroup SYSNAME,
    @online BIT = 0               -- 1 = ONLINE = ON
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @schema SYSNAME = PARSENAME(@table_name, 2),
        @table  SYSNAME = PARSENAME(@table_name, 1),
        @object_id INT,
        @existing_index SYSNAME,
        @is_pk BIT = 0,
		@has_lob BIT =0,
        @existing_key NVARCHAR(MAX),
        @sql NVARCHAR(MAX),
        @index_name SYSNAME,
        @online_clause NVARCHAR(50) = '',
		@textimage_clause NVARCHAR(160) = '',
        -- LOB move temp-partitioning helpers
        @lob_part_col SYSNAME = NULL,
        @lob_part_type SYSNAME = NULL,
        @lob_part_precision INT = NULL,
        @lob_part_scale INT = NULL,
        @boundary_literal NVARCHAR(400) = NULL,
        @pf_name SYSNAME = NULL,
        @ps_name SYSNAME = NULL;

    IF @schema IS NULL OR @table IS NULL
        THROW 50000, 'Use schema.table format', 1;

    SET @object_id = OBJECT_ID(@table_name);
    IF @object_id IS NULL
        THROW 50000, 'Table not found', 1;

    IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = @filegroup)
        THROW 50000, 'Filegroup not found', 1;

    IF @online = 1
        SET @online_clause = ' WITH (ONLINE = ON)';

	-- если лобы в таблице 
	SELECT @has_lob =
        CASE WHEN EXISTS (
            SELECT 1
            FROM sys.columns c
            JOIN sys.types t
              ON c.user_type_id = t.user_type_id
            WHERE c.object_id = @object_id
              AND (
                    c.max_length = -1
                 OR t.name IN ('text','ntext','image','xml')
              )
        ) THEN 1 ELSE 0 END;
	/*-- если есть - способ с пересозданием CIX не работает - покидаем корабль
	IF EXISTS (SELECT 1 FROM sys.columns c
							JOIN sys.types t ON c.user_type_id = t.user_type_id
						WHERE c.object_id = @object_id
						AND (
							 c.max_length = -1              -- varchar(max), nvarchar(max), varbinary(max)
							OR t.name IN ('text','ntext','image','xml')
						)
	)
		THROW 50000, 'Таблица имеет лобы ', 1;
	*/
    ------------------------------------------------------------
    -- Получаем существующий clustered индекс
    ------------------------------------------------------------
    SELECT 
        @existing_index = i.name,
        @is_pk = i.is_primary_key
    FROM sys.indexes i
    WHERE i.object_id = @object_id
      AND i.type = 1;
   
    ------------------------------------------------------------
    -- ЕСЛИ ТАБЛИЦА HEAP
    ------------------------------------------------------------
    IF @existing_index IS NULL
    BEGIN
        IF @key_column IS NULL
        BEGIN
            SELECT TOP 1 @key_column = QUOTENAME(name)
            FROM sys.columns
            WHERE object_id = @object_id
            ORDER BY column_id;
        END

        SET @index_name = CONCAT('CIX_', @table, '_', @key_column);

        SET @sql = '
        CREATE CLUSTERED INDEX ' + QUOTENAME(@index_name) + ' ON ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + '(' + @key_column + ')
        ON ' + QUOTENAME(@filegroup) + @textimage_clause + ';';

		print @sql;
        begin try
			EXEC(@sql);
			print 'executed successfully on heap table';
		end try
		begin catch
			print 'failed on heap table ' + ERROR_MESSAGE();
		end catch

        -- возвращаем heap
        SET @sql = '
        DROP INDEX ' + QUOTENAME(@index_name) + ' ON ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + ';';
		print @sql;
		begin try
			EXEC(@sql);
			print 'executed successfully on heap table';
		end try
		begin catch
			print 'failed returning to heap ' + ERROR_MESSAGE();
		end catch

        RETURN;
    END

	------------------------------------------------------------
	-- Если таблица не HEAP и ключ не задан — используем существующий
	------------------------------------------------------------
	IF @key_column IS NULL
	BEGIN
		SELECT 
			@existing_key = STRING_AGG(QUOTENAME(c.name), ',') WITHIN GROUP (ORDER BY ic.key_ordinal)
		FROM 
			sys.index_columns ic
			JOIN 
			sys.columns c ON ic.object_id = c.object_id
			AND 
			ic.column_id = c.column_id
		WHERE 
			ic.object_id = @object_id
			AND 
			ic.index_id = 1;

		SET @key_column = @existing_key;
	END

	-- формируем суффикс из колонок без запятых и скобок
	DECLARE @index_suffix NVARCHAR(128);

	SET @index_suffix =
    REPLACE(
        REPLACE(
            REPLACE(@key_column, '[',''),
        ']',''),
    ',','_');

	SET @index_name = CONCAT('CIX_', @table, '_', @index_suffix);

	------------------------------------------------------------
	-- Если это PK
	------------------------------------------------------------
	IF @is_pk = 1
	BEGIN
		DECLARE @constraint SYSNAME;

		SELECT 
			@constraint = name
		FROM 
			sys.key_constraints
		WHERE 
			parent_object_id = @object_id
			AND 
			type = 'PK';

		SET @sql = '
		ALTER TABLE ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + '
		DROP CONSTRAINT ' + QUOTENAME(@constraint) + ';
		';
		
		print @sql
		begin try
			EXEC(@sql);
			print 'successfully dropped constratint';
		end try
		begin catch
			print 'failed dropping constraint ' + ERROR_MESSAGE();
		end catch

		SET @sql = '
		ALTER TABLE ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + '
		ADD CONSTRAINT ' + QUOTENAME(@constraint) + '
		PRIMARY KEY CLUSTERED (' + @key_column + ')
		ON ' + QUOTENAME(@filegroup) + ';
		';
		print @sql;
		begin try
			EXEC(@sql);
			print 'executed added constraint';
		end try
		begin catch
			print 'failed adding constraint ' + ERROR_MESSAGE();
		end catch

		RETURN;
	END

    ------------------------------------------------------------
    -- Обычный clustered index
    ------------------------------------------------------------

	IF @existing_index = @index_name
	BEGIN
		-- Имя совпадает → можно DROP_EXISTING
		SET @sql = '
		CREATE CLUSTERED INDEX ' + QUOTENAME(@existing_index) + '
		ON ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + '
		(' + @key_column + ')
		WITH (DROP_EXISTING = ON)' + 
		@online_clause + '
		ON ' + QUOTENAME(@filegroup) +  @textimage_clause + ';';
	END
	ELSE
	BEGIN
		-- Имя отличается → сначала удаляем старый
		SET @sql = '
		DROP INDEX ' + QUOTENAME(@existing_index) + '
		ON ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + ';
		';
		print @sql;
		begin try
			EXEC(@sql);
			print 'executed successfully';
		end try
		begin catch
			print 'failed............' + ERROR_MESSAGE();
		end catch

		-- создаём новый с правильным именем
		SET @sql = '
		CREATE CLUSTERED INDEX ' + QUOTENAME(@index_name) + '
		ON ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + '
		(' + @key_column + ')' +
		@online_clause +  @textimage_clause + ';';

	END

	print @sql;
	begin try
		EXEC(@sql);
		print 'executed successfully';
	end try
	begin catch
		print 'failed............' + ERROR_MESSAGE();
	end catch

	------------------------------------------------------------
	-- Если есть LOB: временное партиционирование для переноса LOB
	------------------------------------------------------------
	IF @has_lob = 1
	BEGIN
		-- Берём первый столбец кластерного ключа
		SELECT TOP (1)
			@lob_part_col       = c.name,
			@lob_part_type      = t.name,
			@lob_part_precision = c.precision,
			@lob_part_scale     = c.scale
		FROM sys.indexes i
		JOIN sys.index_columns ic
		  ON ic.object_id = i.object_id
		 AND ic.index_id  = i.index_id
		 AND ic.key_ordinal > 0
		JOIN sys.columns c
		  ON c.object_id = ic.object_id
		 AND c.column_id = ic.column_id
		JOIN sys.types t
		  ON t.user_type_id = c.user_type_id
		WHERE i.object_id = @object_id
		  AND i.type = 1
		ORDER BY ic.key_ordinal;

		IF @lob_part_col IS NULL
			THROW 50000, 'LOB move failed: could not determine clustered key column for temporary partitioning.', 1;

		--------------------------------------------------------
		-- Генерим boundary value, гарантированно меньше MIN(key)
		--------------------------------------------------------
		IF @lob_part_type IN ('tinyint','smallint','int','bigint')
		BEGIN
			SET @sql = N'
				SELECT @p = CONVERT(nvarchar(100),
					   CASE
						 WHEN MIN(' + QUOTENAME(@lob_part_col) + N') IS NULL THEN 0
						 ELSE CONVERT(bigint, MIN(' + QUOTENAME(@lob_part_col) + N')) - 1
					   END)
				FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N';';

			EXEC sp_executesql
				@sql,
				N'@p nvarchar(100) OUTPUT',
				@p = @boundary_literal OUTPUT;
		END
		ELSE IF @lob_part_type = 'date'
		BEGIN
			SET @sql = N'
				SELECT @p = QUOTENAME(CONVERT(nvarchar(30),
					   DATEADD(day, -1, ISNULL(MIN(' + QUOTENAME(@lob_part_col) + N'), ''20000101'')), 112), '''''')
				FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N';';

			EXEC sp_executesql
				@sql,
				N'@p nvarchar(100) OUTPUT',
				@p = @boundary_literal OUTPUT;
		END
		ELSE IF @lob_part_type IN ('datetime','smalldatetime','datetime2')
		BEGIN
			SET @sql = N'
				SELECT @p = QUOTENAME(CONVERT(nvarchar(30),
					   DATEADD(day, -1, ISNULL(MIN(' + QUOTENAME(@lob_part_col) + N'), ''2000-01-01'')), 126), '''''')
				FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N';';

			EXEC sp_executesql
				@sql,
				N'@p nvarchar(100) OUTPUT',
				@p = @boundary_literal OUTPUT;
		END
		ELSE IF @lob_part_type IN ('decimal','numeric')
		BEGIN
			DECLARE @step NVARCHAR(100) =
				CASE
					WHEN @lob_part_scale IS NULL OR @lob_part_scale = 0 THEN '1'
					ELSE '0.' + REPLICATE('0', @lob_part_scale - 1) + '1'
				END;

			SET @sql = N'
				SELECT @p = CONVERT(nvarchar(100),
					   CASE
						 WHEN MIN(' + QUOTENAME(@lob_part_col) + N') IS NULL
							  THEN CONVERT(decimal(' + CAST(@lob_part_precision AS varchar(10)) + ',' + CAST(@lob_part_scale AS varchar(10)) + N'), 0)
						 ELSE CONVERT(decimal(' + CAST(@lob_part_precision AS varchar(10)) + ',' + CAST(@lob_part_scale AS varchar(10)) + N'),
							  MIN(' + QUOTENAME(@lob_part_col) + N') - CONVERT(decimal(' + CAST(@lob_part_precision AS varchar(10)) + ',' + CAST(@lob_part_scale AS varchar(10)) + N'), ' + @step + N'))
					   END)
				FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N';';

			EXEC sp_executesql
				@sql,
				N'@p nvarchar(100) OUTPUT',
				@p = @boundary_literal OUTPUT;
		END
		ELSE
		BEGIN
			THROW 50000, 'LOB move via temporary partitioning is only auto-supported for numeric/date first clustered-key columns.', 1;
		END

		--------------------------------------------------------
		-- Имена временных partition objects
		------------------------------------------------
		SET @pf_name = CONCAT('pf_MoveLob_', @table, '_', @object_id);
		SET @ps_name = CONCAT('ps_MoveLob_', @table, '_', @object_id);

		-- На случай повтора после аварии: подчистим хвосты
		IF EXISTS (SELECT 1 FROM sys.partition_schemes WHERE name = @ps_name)
		BEGIN
			SET @sql = N'DROP PARTITION SCHEME ' + QUOTENAME(@ps_name) + N';';
			BEGIN TRY
				EXEC(@sql);
				PRINT 'Drop old partition scheme executed successfully.';
			END TRY
			BEGIN CATCH
				PRINT 'Drop old partition scheme failed.';
				PRINT ERROR_MESSAGE();
				THROW;
			END CATCH
		END

		IF EXISTS (SELECT 1 FROM sys.partition_functions WHERE name = @pf_name)
		BEGIN
			SET @sql = N'DROP PARTITION FUNCTION ' + QUOTENAME(@pf_name) + N';';
			BEGIN TRY
				EXEC(@sql);
				PRINT 'Drop old partition function executed successfully.';
			END TRY
			BEGIN CATCH
				PRINT 'Drop old partition function failed.';
				PRINT ERROR_MESSAGE();
				THROW;
			END CATCH
		END

		--------------------------------------------------------
		-- CREATE PARTITION FUNCTION
		--------------------------------------------------------
		SET @sql = N'CREATE PARTITION FUNCTION ' + QUOTENAME(@pf_name) + N' (' +
			CASE
				WHEN @lob_part_type IN ('decimal','numeric')
					THEN @lob_part_type + '(' + CAST(@lob_part_precision AS varchar(10)) + ',' + CAST(@lob_part_scale AS varchar(10)) + ')'
				WHEN @lob_part_type = 'datetime2'
					THEN 'datetime2(' + CAST(@lob_part_scale AS varchar(10)) + ')'
				ELSE @lob_part_type
			END +
			N') AS RANGE RIGHT FOR VALUES (' + @boundary_literal + N');';

		BEGIN TRY
			EXEC(@sql);
			PRINT 'Create partition function executed successfully.';
		END TRY
		BEGIN CATCH
			PRINT 'Create partition function failed.';
			PRINT ERROR_MESSAGE();
			THROW;
		END CATCH

		--------------------------------------------------------
		-- CREATE PARTITION SCHEME
		-- обе partition -> в ту же target FG, это и есть трюк
		--------------------------------------------------------
		SET @sql = N'CREATE PARTITION SCHEME ' + QUOTENAME(@ps_name) +
				   N' AS PARTITION ' + QUOTENAME(@pf_name) +
				   N' TO (' + QUOTENAME(@filegroup) + N', ' + QUOTENAME(@filegroup) + N');';

		BEGIN TRY
			EXEC(@sql);
			PRINT 'Create partition scheme executed successfully.';
		END TRY
		BEGIN CATCH
			PRINT 'Create partition scheme failed.';
			PRINT ERROR_MESSAGE();
			THROW;
		END CATCH

		--------------------------------------------------------
		-- Переводим таблицу в partitioned clustered index
		-- это заставляет SQL Server переразложить и LOB allocation units
		--------------------------------------------------------
		SET @sql = N'
		CREATE CLUSTERED INDEX ' + QUOTENAME(@index_name) + N'
		ON ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
		(' + @key_column + N')
		WITH (DROP_EXISTING = ON' + @online_clause + N')
		ON ' + QUOTENAME(@ps_name) + N'(' + QUOTENAME(@lob_part_col) + N');';

		BEGIN TRY
			EXEC(@sql);
			PRINT 'Temporary partitioned rebuild executed successfully.';
		END TRY
		BEGIN CATCH
			PRINT 'Temporary partitioned rebuild failed.';
			PRINT ERROR_MESSAGE();
			THROW;
		END CATCH

		--------------------------------------------------------
		-- Возвращаем обратно в обычную непартиционированную таблицу
		-- Kimberly прямо пишет: rebuild on a filegroup => object becomes non-partitioned again
		--------------------------------------------------------
		SET @sql = N'
		CREATE CLUSTERED INDEX ' + QUOTENAME(@index_name) + N'
		ON ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N'
		(' + @key_column + N')
		WITH (DROP_EXISTING = ON' + @online_clause + N')
		ON ' + QUOTENAME(@filegroup) + N';';

		BEGIN TRY
			EXEC(@sql);
			PRINT 'Final non-partitioned rebuild executed successfully.';
    END TRY
    BEGIN CATCH
        PRINT 'Final non-partitioned rebuild failed.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH

    --------------------------------------------------------
    -- Чистим временные partition objects
    --------------------------------------------------------
    SET @sql = N'DROP PARTITION SCHEME ' + QUOTENAME(@ps_name) + N';';
    BEGIN TRY
        EXEC(@sql);
        PRINT 'Drop partition scheme executed successfully.';
    END TRY
    BEGIN CATCH
        PRINT 'Drop partition scheme failed.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH

    SET @sql = N'DROP PARTITION FUNCTION ' + QUOTENAME(@pf_name) + N';';
    BEGIN TRY
        EXEC(@sql);
        PRINT 'Drop partition function executed successfully.';
    END TRY
    BEGIN CATCH
        PRINT 'Drop partition function failed.';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
END
END
