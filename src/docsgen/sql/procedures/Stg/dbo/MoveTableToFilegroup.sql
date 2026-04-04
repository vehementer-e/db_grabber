
-- exec dbo.MoveTableToFilegroup @table_name='_Collection.AspNetUsers', @filegroup='_Collection'

-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[MoveTableToFilegroup]
--      @table_name = <value>,
--      @key_column = NULL,
--      @filegroup = <value>,
--      @online = 0;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROCEDURE [dbo].[MoveTableToFilegroup]
(
    @table_name SYSNAME,              -- schema.table
    @key_column NVARCHAR(MAX) = NULL, -- 'col1' или 'col1,col2'
    @filegroup SYSNAME,
    @online BIT = 0                   -- 1 = ONLINE = ON
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @schema SYSNAME = PARSENAME(@table_name, 2),
        @table SYSNAME = PARSENAME(@table_name, 1),
        @object_id INT,
        @existing_index SYSNAME,
        @is_pk BIT = 0,
        @has_lob BIT = 0,
        @existing_key NVARCHAR(MAX),
        @sql NVARCHAR(MAX),
        @index_name SYSNAME,
        @online_clause NVARCHAR(50) = '';

    IF @schema IS NULL OR @table IS NULL
        THROW 50000, 'Use schema.table format', 1;

    SET @object_id = OBJECT_ID(@table_name);
    IF @object_id IS NULL
        THROW 50000, 'Table not found', 1;

    IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = @filegroup)
        THROW 50000, 'Filegroup not found', 1;

    IF @online = 1
        SET @online_clause = ' WITH (ONLINE = ON)';

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

    IF @has_lob = 1
    BEGIN
        EXEC dbo.MoveTableWithLobs2ToNewFG
            @table_name = @table_name,
            @key_column = @key_column,
            @filegroup = @filegroup,
            @online = @online;
        RETURN;
    END

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
        ON ' + QUOTENAME(@filegroup) + ';';

        PRINT @sql;
        BEGIN TRY
            EXEC(@sql);
            PRINT 'executed successfully on heap table';
        END TRY
        BEGIN CATCH
            PRINT 'failed on heap table ' + ERROR_MESSAGE();
        END CATCH

        -- возвращаем heap
        SET @sql = '
        DROP INDEX ' + QUOTENAME(@index_name) + ' ON ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + ';';
        PRINT @sql;
        BEGIN TRY
            EXEC(@sql);
            PRINT 'executed successfully on heap table';
        END TRY
        BEGIN CATCH
            PRINT 'failed returning to heap ' + ERROR_MESSAGE();
        END CATCH

        RETURN;
    END

    ------------------------------------------------------------
    -- Если таблица не HEAP и ключ не задан — используем существующий
    ------------------------------------------------------------
    IF @key_column IS NULL
    BEGIN
        SELECT
            @existing_key = STRING_AGG(QUOTENAME(c.name), ',') WITHIN GROUP (ORDER BY ic.key_ordinal)
        FROM sys.index_columns ic
        JOIN sys.columns c
          ON ic.object_id = c.object_id
         AND ic.column_id = c.column_id
        WHERE ic.object_id = @object_id
          AND ic.index_id = 1;

        SET @key_column = @existing_key;
    END

    DECLARE @index_suffix NVARCHAR(128);

    SET @index_suffix =
        REPLACE(
            REPLACE(
                REPLACE(@key_column, '[', ''),
            ']', ''),
        ',', '_');

    SET @index_name = CONCAT('CIX_', @table, '_', @index_suffix);

    ------------------------------------------------------------
    -- Если это PK
    ------------------------------------------------------------
    IF @is_pk = 1
    BEGIN
        DECLARE @constraint SYSNAME;

        SELECT
            @constraint = name
        FROM sys.key_constraints
        WHERE parent_object_id = @object_id
          AND type = 'PK';

        SET @sql = '
        ALTER TABLE ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + '
        DROP CONSTRAINT ' + QUOTENAME(@constraint) + ';
        ';

        PRINT @sql;
        BEGIN TRY
            EXEC(@sql);
            PRINT 'successfully dropped constraint';
        END TRY
        BEGIN CATCH
            PRINT 'failed dropping constraint ' + ERROR_MESSAGE();
        END CATCH

        SET @sql = '
        ALTER TABLE ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + '
        ADD CONSTRAINT ' + QUOTENAME(@constraint) + '
        PRIMARY KEY CLUSTERED (' + @key_column + ')
        ON ' + QUOTENAME(@filegroup) + ';
        ';
        PRINT @sql;
        BEGIN TRY
            EXEC(@sql);
            PRINT 'executed added constraint';
        END TRY
        BEGIN CATCH
            PRINT 'failed adding constraint ' + ERROR_MESSAGE();
        END CATCH

        RETURN;
    END

    ------------------------------------------------------------
    -- Обычный clustered index
    ------------------------------------------------------------
    IF @existing_index = @index_name
    BEGIN
        SET @sql = '
        CREATE CLUSTERED INDEX ' + QUOTENAME(@existing_index) + '
        ON ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + '
        (' + @key_column + ')
        WITH (DROP_EXISTING = ON)' +
        @online_clause + '
        ON ' + QUOTENAME(@filegroup) + ';';
    END
    ELSE
    BEGIN
        SET @sql = '
        DROP INDEX ' + QUOTENAME(@existing_index) + '
        ON ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + ';
        ';
        PRINT @sql;
        BEGIN TRY
            EXEC(@sql);
            PRINT 'executed successfully';
        END TRY
        BEGIN CATCH
            PRINT 'failed............' + ERROR_MESSAGE();
        END CATCH

        SET @sql = '
        CREATE CLUSTERED INDEX ' + QUOTENAME(@index_name) + '
        ON ' + QUOTENAME(@schema) + '.' + QUOTENAME(@table) + '
        (' + @key_column + ')' +
        @online_clause + '
        ON ' + QUOTENAME(@filegroup) + ';';
    END

    PRINT @sql;
    BEGIN TRY
        EXEC(@sql);
        PRINT 'executed successfully';
    END TRY
    BEGIN CATCH
        PRINT 'failed............' + ERROR_MESSAGE();
    END CATCH
END
