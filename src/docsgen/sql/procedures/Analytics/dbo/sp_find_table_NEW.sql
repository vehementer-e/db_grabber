CREATE   PROCEDURE [dbo].[sp_selectTable]
    @table NVARCHAR(MAX), 
    @db_search NVARCHAR(MAX) = 'analytics'
AS
BEGIN
    SET NOCOUNT ON;

    -- Переменные
    DECLARE @schema NVARCHAR(MAX), 
            @table_name NVARCHAR(MAX), 
            @is_temp_table BIT = 0, 
            @full_table_name NVARCHAR(MAX),
            @columns_list NVARCHAR(MAX),
            @create_script NVARCHAR(MAX), 
            @drop_script NVARCHAR(MAX);

    -- Определение, временная таблица или нет
    IF LEFT(@table, 1) = '#'
    BEGIN
        SET @is_temp_table = 1;
        SET @full_table_name = 'tempdb.dbo.' + REPLACE(@table, '#', '##');
    END
    ELSE
    BEGIN
        SELECT TOP 1 
            @schema = s.name,
            @table_name = t.name
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE t.name LIKE '%' + @table + '%';

        IF @table_name IS NULL
        BEGIN
            SELECT 'Table not found!' AS Message;
            RETURN;
        END

        SET @full_table_name = QUOTENAME(@schema) + '.' + QUOTENAME(@table_name);
    END

    -- Получение списка столбцов
    IF @is_temp_table = 1
    BEGIN
        SELECT @columns_list = STRING_AGG(
            QUOTENAME(name) + ' ' +
            TYPE_NAME(system_type_id) +
            CASE 
                WHEN max_length > 0 AND TYPE_NAME(system_type_id) IN ('char', 'varchar', 'nchar', 'nvarchar') 
                THEN '(' + CASE WHEN max_length = -1 THEN 'MAX' ELSE CAST(max_length AS NVARCHAR) END + ')' 
                ELSE '' 
            END +
            CASE WHEN is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END,
            ', ' + CHAR(10)
        )
        FROM tempdb.sys.columns
        WHERE object_id = OBJECT_ID(@full_table_name);
    END
    ELSE
    BEGIN
        SELECT @columns_list = STRING_AGG(
            QUOTENAME(c.name) + ' ' +
            TYPE_NAME(c.system_type_id) +
            CASE 
                WHEN c.max_length > 0 AND TYPE_NAME(c.system_type_id) IN ('char', 'varchar', 'nchar', 'nvarchar') 
                THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS NVARCHAR) END + ')' 
                ELSE '' 
            END +
            CASE WHEN c.is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END,
            ', ' + CHAR(10)
        )
        FROM sys.columns c
        WHERE c.object_id = OBJECT_ID(@full_table_name);
    END

    -- Генерация скриптов
    SET @create_script = 'CREATE TABLE table1 AS a (' + CHAR(10) + @columns_list + CHAR(10) + ');';
    SET @drop_script = 'DROP TABLE table1;';

    -- Первая часть: CREATE и DROP TABLE
    SELECT 
        'CREATE TABLE Script' AS ScriptType,
        @create_script AS Script
    UNION ALL
    SELECT 
        'DROP TABLE Script',
        @drop_script;

    -- Вторая часть: Работа со столбцами
    SELECT 
        c.name AS ColumnName,
        'ALTER TABLE table1 DROP COLUMN ' + QUOTENAME(c.name) AS DropColumnScript,
        'ALTER TABLE table1 ALTER COLUMN ' + QUOTENAME(c.name) + ' NVARCHAR(MAX)' AS AlterColumnScript,
        'EXEC sp_rename ''table1.' + c.name + ''', ''new_' + c.name + ''', ''COLUMN''' AS RenameColumnScript
    FROM (
        SELECT name, column_id FROM tempdb.sys.columns WHERE object_id = OBJECT_ID(@full_table_name)
        UNION ALL
        SELECT name, column_id FROM sys.columns WHERE object_id = OBJECT_ID(@full_table_name)
    ) c
    ORDER BY c.column_id;
END;

 