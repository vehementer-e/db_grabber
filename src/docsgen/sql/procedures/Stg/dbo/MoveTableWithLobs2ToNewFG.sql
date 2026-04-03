
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[MoveTableWithLobs2ToNewFG]
--      @table_name = <value>,
--      @key_column = NULL,
--      @filegroup = <value>,
--      @online = 0,
--      @batch_size = 50000;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROCEDURE [dbo].[MoveTableWithLobs2ToNewFG]
(
    @table_name SYSNAME,              -- schema.table
    @key_column NVARCHAR(MAX) = NULL, -- 'col1' или 'col1,col2'
    @filegroup SYSNAME,
    @online BIT = 0,
    @batch_size INT = 50000
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @schema SYSNAME = PARSENAME(@table_name, 2),
        @table SYSNAME = PARSENAME(@table_name, 1),
        @object_id INT,
        @new_table SYSNAME,
        @new_table_full NVARCHAR(520),
        @src_table_full NVARCHAR(520),
        @sql NVARCHAR(MAX),
        @col_defs NVARCHAR(MAX),
        @insert_cols NVARCHAR(MAX),
        @select_cols NVARCHAR(MAX),
        @has_identity BIT = 0,
        @identity_col SYSNAME = NULL,
        @key_order NVARCHAR(MAX),
        @key_match NVARCHAR(MAX),
        @rows INT = 1,
        @src_count BIGINT,
        @dst_count BIGINT,
        @suffix CHAR(8),
        @old_renamed SYSNAME,
        @candidate SYSNAME,
        @rename_objname NVARCHAR(520),
        @n INT = 0,
        @utc_date DATE = CONVERT(date, SYSUTCDATETIME());

    IF @schema IS NULL OR @table IS NULL
        THROW 50000, 'Use schema.table format', 1;

    SET @object_id = OBJECT_ID(@table_name);
    IF @object_id IS NULL
        THROW 50000, 'Table not found', 1;

    IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = @filegroup)
        THROW 50000, 'Filegroup not found', 1;

    IF @batch_size IS NULL OR @batch_size <= 0
        THROW 50000, '@batch_size must be > 0', 1;

    SET @new_table = @table + '_new';
    SET @src_table_full = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
    SET @new_table_full = QUOTENAME(@schema) + N'.' + QUOTENAME(@new_table);

    ------------------------------------------------------------
    -- Определяем ключ для батчевого копирования и идемпотентности
    ------------------------------------------------------------
    IF @key_column IS NULL
    BEGIN
        ;WITH key_candidates AS (
            SELECT TOP (1)
                i.index_id,
                i.is_primary_key,
                i.is_unique,
                priority = CASE WHEN i.is_primary_key = 1 THEN 1 ELSE 2 END
            FROM sys.indexes i
            WHERE i.object_id = @object_id
              AND i.is_hypothetical = 0
              AND i.is_disabled = 0
              AND (i.is_primary_key = 1 OR i.is_unique = 1)
            ORDER BY CASE WHEN i.is_primary_key = 1 THEN 1 ELSE 2 END, i.index_id
        )
        SELECT @key_column = STRING_AGG(QUOTENAME(c.name), ',') WITHIN GROUP (ORDER BY ic.key_ordinal)
        FROM key_candidates k
        JOIN sys.index_columns ic
          ON ic.object_id = @object_id
         AND ic.index_id = k.index_id
         AND ic.key_ordinal > 0
        JOIN sys.columns c
          ON c.object_id = ic.object_id
         AND c.column_id = ic.column_id;
    END

    IF @key_column IS NULL
        THROW 50000, 'For LOB move key column(s) required. Pass @key_column or add PK/UNIQUE index.', 1;

    DECLARE @keys TABLE
    (
        key_ordinal INT IDENTITY(1,1) PRIMARY KEY,
        key_name SYSNAME NOT NULL
    );

    DECLARE @key_xml XML = CAST('<i>' + REPLACE(REPLACE(REPLACE(@key_column, '[', ''), ']', ''), ',', '</i><i>') + '</i>' AS XML);

    INSERT INTO @keys(key_name)
    SELECT LTRIM(RTRIM(x.i.value('.', 'sysname')))
    FROM @key_xml.nodes('/i/text()') AS x(i)
    WHERE LTRIM(RTRIM(x.i.value('.', 'nvarchar(256)'))) <> '';

    IF NOT EXISTS (SELECT 1 FROM @keys)
        THROW 50000, 'Unable to parse @key_column.', 1;

    IF EXISTS (
        SELECT 1
        FROM @keys k
        LEFT JOIN sys.columns c
          ON c.object_id = @object_id
         AND c.name = k.key_name
        WHERE c.column_id IS NULL
    )
        THROW 50000, 'Some key columns do not exist in source table.', 1;

    SELECT
        @key_order = STRING_AGG('s.' + QUOTENAME(key_name), ', ') WITHIN GROUP (ORDER BY key_ordinal),
        @key_match = STRING_AGG('t.' + QUOTENAME(key_name) + ' = s.' + QUOTENAME(key_name), ' AND ') WITHIN GROUP (ORDER BY key_ordinal)
    FROM @keys;

    ------------------------------------------------------------
    -- Создание <table>_new (если еще не создана)
    -- Важно: не используем SELECT TOP(0) INTO, т.к. он не переносит
    -- default-constraints, computed columns и collations, а также
    -- не задает TEXTIMAGE_ON для LOB. Здесь схема собирается явно.
    ------------------------------------------------------------
    IF OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@new_table), 'U') IS NULL
    BEGIN
        SELECT
            @col_defs = STRING_AGG(
                CASE
                    WHEN c.is_computed = 1
                        THEN QUOTENAME(c.name) + N' AS ' + cc.definition
                    ELSE
                        QUOTENAME(c.name) + N' ' +
                        CASE
                            WHEN t.name IN ('varchar','char','varbinary','binary')
                                THEN t.name + N'(' + CASE WHEN c.max_length = -1 THEN 'max' ELSE CAST(c.max_length AS NVARCHAR(10)) END + N')'
                            WHEN t.name IN ('nvarchar','nchar')
                                THEN t.name + N'(' + CASE WHEN c.max_length = -1 THEN 'max' ELSE CAST(c.max_length / 2 AS NVARCHAR(10)) END + N')'
                            WHEN t.name IN ('decimal','numeric')
                                THEN t.name + N'(' + CAST(c.precision AS NVARCHAR(10)) + N',' + CAST(c.scale AS NVARCHAR(10)) + N')'
                            WHEN t.name IN ('datetime2','datetimeoffset','time')
                                THEN t.name + N'(' + CAST(c.scale AS NVARCHAR(10)) + N')'
                            ELSE t.name
                        END +
                        CASE
                            WHEN c.collation_name IS NOT NULL AND t.name LIKE '%char%'
                                THEN N' COLLATE ' + c.collation_name
                            ELSE N''
                        END +
                        CASE
                            WHEN c.is_identity = 1
                                THEN N' IDENTITY(' + CAST(ISNULL(ic.seed_value, 1) AS NVARCHAR(50)) + N',' + CAST(ISNULL(ic.increment_value, 1) AS NVARCHAR(50)) + N')'
                            ELSE N''
                        END +
                        CASE
                            WHEN dc.object_id IS NOT NULL
                                THEN N' DEFAULT ' + dc.definition
                            ELSE N''
                        END +
                        CASE WHEN c.is_nullable = 1 THEN N' NULL' ELSE N' NOT NULL' END
                END,
                N', ' + CHAR(10)
            ) WITHIN GROUP (ORDER BY c.column_id),
            @insert_cols = STRING_AGG(
                CASE WHEN c.is_computed = 0 AND c.system_type_id <> 189 THEN QUOTENAME(c.name) END,
                N', '
            ) WITHIN GROUP (ORDER BY c.column_id),
            @select_cols = STRING_AGG(
                CASE WHEN c.is_computed = 0 AND c.system_type_id <> 189 THEN N's.' + QUOTENAME(c.name) END,
                N', '
            ) WITHIN GROUP (ORDER BY c.column_id),
            @identity_col = MAX(CASE WHEN c.is_identity = 1 THEN c.name END),
            @has_identity = MAX(CASE WHEN c.is_identity = 1 THEN 1 ELSE 0 END)
        FROM sys.columns c
        JOIN sys.types t
          ON t.user_type_id = c.user_type_id
        LEFT JOIN sys.computed_columns cc
          ON cc.object_id = c.object_id
         AND cc.column_id = c.column_id
        LEFT JOIN sys.default_constraints dc
          ON dc.parent_object_id = c.object_id
         AND dc.parent_column_id = c.column_id
        LEFT JOIN sys.identity_columns ic
          ON ic.object_id = c.object_id
         AND ic.column_id = c.column_id
        WHERE c.object_id = @object_id;

        SET @sql = N'CREATE TABLE ' + @new_table_full + N'(' + CHAR(10) + @col_defs + CHAR(10) + N') ON ' + QUOTENAME(@filegroup) + N' TEXTIMAGE_ON ' + QUOTENAME(@filegroup) + N';';
        EXEC(@sql);

        SET @sql = N'CREATE UNIQUE INDEX ' + QUOTENAME('UX_Move_' + @new_table + '_Key') +
                   N' ON ' + @new_table_full + N'(' +
                   (SELECT STRING_AGG(QUOTENAME(key_name), ', ') WITHIN GROUP (ORDER BY key_ordinal) FROM @keys) + N')' +
                   CASE WHEN @online = 1 THEN N' WITH (ONLINE = ON)' ELSE N'' END +
                   N' ON ' + QUOTENAME(@filegroup) + N';';
        EXEC(@sql);
    END
    ELSE
    BEGIN
        -- если таблица уже была создана ранее, просто соберем списки колонок
        SELECT
            @insert_cols = STRING_AGG(
                CASE WHEN c.is_computed = 0 AND c.system_type_id <> 189 THEN QUOTENAME(c.name) END,
                N', '
            ) WITHIN GROUP (ORDER BY c.column_id),
            @select_cols = STRING_AGG(
                CASE WHEN c.is_computed = 0 AND c.system_type_id <> 189 THEN N's.' + QUOTENAME(c.name) END,
                N', '
            ) WITHIN GROUP (ORDER BY c.column_id),
            @has_identity = MAX(CASE WHEN c.is_identity = 1 THEN 1 ELSE 0 END)
        FROM sys.columns c
        WHERE c.object_id = @object_id;
    END

    ------------------------------------------------------------
    -- Копирование данных батчами, идемпотентно (NOT EXISTS по ключу)
    ------------------------------------------------------------
    IF @has_identity = 1
    BEGIN
        SET @sql = N'SET IDENTITY_INSERT ' + @new_table_full + N' ON;';
        EXEC(@sql);
    END

    WHILE @rows > 0
    BEGIN
        SET @sql = N'
            ;WITH to_copy AS (
                SELECT TOP (@p_batch_size) ' + @select_cols + N'
                FROM ' + @src_table_full + N' s
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM ' + @new_table_full + N' t
                    WHERE ' + @key_match + N'
                )
                ORDER BY ' + @key_order + N'
            )
            INSERT INTO ' + @new_table_full + N'(' + @insert_cols + N')
            SELECT * FROM to_copy;
            SELECT @p_rows = @@ROWCOUNT;';

        EXEC sp_executesql
            @sql,
            N'@p_batch_size INT, @p_rows INT OUTPUT',
            @p_batch_size = @batch_size,
            @p_rows = @rows OUTPUT;
    END

    IF @has_identity = 1
    BEGIN
        SET @sql = N'SET IDENTITY_INSERT ' + @new_table_full + N' OFF;';
        EXEC(@sql);
    END

    ------------------------------------------------------------
    -- Проверка количества строк перед переименованием
    ------------------------------------------------------------
    SET @sql = N'SELECT @p_cnt = COUNT_BIG(1) FROM ' + @src_table_full + N';';
    EXEC sp_executesql @sql, N'@p_cnt BIGINT OUTPUT', @p_cnt = @src_count OUTPUT;

    SET @sql = N'SELECT @p_cnt = COUNT_BIG(1) FROM ' + @new_table_full + N';';
    EXEC sp_executesql @sql, N'@p_cnt BIGINT OUTPUT', @p_cnt = @dst_count OUTPUT;

    IF @src_count <> @dst_count
        THROW 50000, 'Row count mismatch between source and _new table. Rename is aborted.', 1;

    ------------------------------------------------------------
    -- Ротация имен:
    --   <table> -> <table>_delete_after_yyyymmdd
    --   <table>_new -> <table>
    ------------------------------------------------------------
    SET @suffix = CONVERT(CHAR(8), DATEADD(DAY, 30, @utc_date), 112);
    SET @old_renamed = @table + '_delete_after_' + @suffix;
    SET @candidate = @old_renamed;

    WHILE OBJECT_ID(QUOTENAME(@schema) + N'.' + QUOTENAME(@candidate), 'U') IS NOT NULL
    BEGIN
        SET @n += 1;
        SET @candidate = @old_renamed + '_' + CAST(@n AS NVARCHAR(10));
    END

    SET @old_renamed = @candidate;

    BEGIN TRAN;
    BEGIN TRY
        EXEC sys.sp_rename @objname = @table_name, @newname = @old_renamed, @objtype = 'OBJECT';
        SET @rename_objname = QUOTENAME(@schema) + N'.' + QUOTENAME(@new_table);
        EXEC sys.sp_rename @objname = @rename_objname, @newname = @table, @objtype = 'OBJECT';
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;
        THROW;
    END CATCH
END
