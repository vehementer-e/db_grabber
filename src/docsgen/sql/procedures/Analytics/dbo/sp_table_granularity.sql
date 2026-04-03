CREATE   PROCEDURE [dbo].[sp_table_granularity]
    @table NVARCHAR(128)
AS 
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @column_name SYSNAME;
    DECLARE @unique_count INT;
    DECLARE @total_weight BIGINT;
    DECLARE @unique_weight BIGINT;
    DECLARE @count INT;
    DECLARE @weight BIGINT;
    DECLARE @uniqueWeight BIGINT;
    DECLARE @total_rows BIGINT;

    CREATE TABLE #results (
        columnName SYSNAME,
        uniqueValuesCount INT,
        totalWeight BIGINT,
        uniqueValuesWeight BIGINT,
        uniqueCountRatio FLOAT,
        totalWeightRatio FLOAT,
        uniqueWeightRatio FLOAT
    );

    -- Кол-во строк в таблице
    SET @sql = N'SELECT @rows = COUNT(*) FROM ' + QUOTENAME(@table) + ';';
    EXEC sp_executesql @sql, N'@rows BIGINT OUTPUT', @rows = @total_rows OUTPUT;

    DECLARE cursor_columns CURSOR FOR
    SELECT COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = @table;

    OPEN cursor_columns;
    FETCH NEXT FROM cursor_columns INTO @column_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @count = 0;
        SET @weight = 0;
        SET @uniqueWeight = 0;

        -- Общая статистика
        SET @sql = N'
            SELECT 
                @count = COUNT(DISTINCT ' + QUOTENAME(@column_name) + N'), 
                @weight = SUM(ISNULL(DATALENGTH(' + QUOTENAME(@column_name) + N'), 0)) 
            FROM ' + QUOTENAME(@table) + N';';

        EXEC sp_executesql 
            @sql, 
            N'@count INT OUTPUT, @weight BIGINT OUTPUT', 
            @count = @unique_count OUTPUT, 
            @weight = @total_weight OUTPUT;

        -- Вес только уникальных значений
        SET @sql = N'
            SELECT 
                @uniqueWeight = SUM(ISNULL(DATALENGTH(' + QUOTENAME(@column_name) + N'), 0)) 
            FROM (
                SELECT DISTINCT ' + QUOTENAME(@column_name) + N'
                FROM ' + QUOTENAME(@table) + N'
            ) AS unique_vals;';

        EXEC sp_executesql 
            @sql, 
            N'@uniqueWeight BIGINT OUTPUT', 
            @uniqueWeight = @unique_weight OUTPUT;

        -- Вставка, пока без расчета долей
        INSERT INTO #results (columnName, uniqueValuesCount, totalWeight, uniqueValuesWeight, uniqueCountRatio, totalWeightRatio, uniqueWeightRatio)
        VALUES (@column_name, @unique_count, @total_weight, @unique_weight, 0, 0, 0);

        FETCH NEXT FROM cursor_columns INTO @column_name;
    END;

    CLOSE cursor_columns;
    DEALLOCATE cursor_columns;

    -- Суммарные значения
    DECLARE @sum_table_weight BIGINT, @sum_unique_weight BIGINT;
    SELECT 
        @sum_table_weight = SUM(totalWeight),
        @sum_unique_weight = SUM(uniqueValuesWeight)
    FROM #results;

    -- Обновим доли
    UPDATE #results
    SET 
        uniqueCountRatio = CAST(uniqueValuesCount AS FLOAT) / NULLIF(@total_rows, 0),
        totalWeightRatio = CAST(totalWeight AS FLOAT) / NULLIF(@sum_table_weight, 0),
        uniqueWeightRatio = CAST(uniqueValuesWeight AS FLOAT) / NULLIF(@sum_unique_weight, 0);

    -- Результат
    SELECT * FROM #results
    ORDER BY uniqueValuesCount DESC;

    SELECT 
        SUM(uniqueValuesCount) AS totalUniqueValues,
        SUM(totalWeight) AS totalDataWeight,
        SUM(uniqueValuesWeight) AS totalUniqueDataWeight
    FROM #results; 