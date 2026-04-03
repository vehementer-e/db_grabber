CREATE   PROCEDURE dbo.CreateMonthlyFG_PF_PS
(
    @SchemaName      nvarchar(255),
    @TableName       nvarchar(255),
    @TableAlias      nvarchar(255),   -- например SZD_LoanMetrics
    @PartitionColumn nvarchar(255),   -- например ОтчетнаяДата
    @PathToFile      nvarchar(255) = NULL,
    @FutureMonths    int = 24,        -- сколько месяцев создать вперёд
    @PastMonths      int = 0          -- если хочешь расширить назад от min (обычно 0)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @dbName sysname = DB_NAME();

    -- Если путь не задан — берём папку, где лежит MDF
    IF @PathToFile IS NULL
    BEGIN
        SELECT TOP (1)
            @PathToFile = REVERSE(SUBSTRING(REVERSE(physical_name),
                              CHARINDEX('\', REVERSE(physical_name)) + 1,
                              260))
        FROM sys.database_files
        WHERE type_desc = 'ROWS'
          AND name = @dbName;
    END

    DROP TABLE IF EXISTS #t_range;

    -- Определяем диапазон по данным (по вычисляемой дате)
    DECLARE @MinDate date, @MaxDate date;
    DECLARE @sql nvarchar(max);

    SET @sql = N'
    SELECT
      @MinDate = DATEFROMPARTS(YEAR(MIN(' + QUOTENAME(@PartitionColumn) + N')), MONTH(MIN(' + QUOTENAME(@PartitionColumn) + N')), 1),
      @MaxDate = DATEFROMPARTS(YEAR(MAX(' + QUOTENAME(@PartitionColumn) + N')), MONTH(MAX(' + QUOTENAME(@PartitionColumn) + N')), 1)
    FROM ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N';';

    EXEC sys.sp_executesql
        @sql,
        N'@MinDate date OUTPUT, @MaxDate date OUTPUT',
        @MinDate = @MinDate OUTPUT,
        @MaxDate = @MaxDate OUTPUT;

    -- расширяем диапазон
    SET @MinDate = DATEADD(month, -@PastMonths, @MinDate);
    SET @MaxDate = DATEADD(month,  @FutureMonths, @MaxDate);

    ;WITH cte AS
    (
        SELECT @MinDate AS dd
        UNION ALL
        SELECT DATEADD(month, 1, dd)
        FROM cte
        WHERE dd < @MaxDate
    )
    SELECT
        range_name = CONVERT(varchar(10), dd, 120),               -- 'YYYY-MM-DD'
        fg_name = REPLACE(CONCAT('fg_', @dbName, '_', @TableAlias, '_', FORMAT(dd, 'yyyyMMdd')), '__', '_')
    INTO #t_range
    FROM cte
    OPTION (MAXRECURSION 0);

    -- PARTITION FUNCTION
    DECLARE @periods nvarchar(max) =
    (
        SELECT STRING_AGG(QUOTENAME(range_name, ''''), ',') WITHIN GROUP (ORDER BY range_name)
        FROM #t_range
    );

    DECLARE @fun_name sysname = REPLACE(CONCAT('pfn_range_right_date_part_', @TableAlias), '__', '_');
    DECLARE @cmd nvarchar(max) =
        CONCAT(N'CREATE PARTITION FUNCTION ', QUOTENAME(@fun_name),
               N' (date) AS RANGE RIGHT FOR VALUES (', @periods, N')');

    IF NOT EXISTS (SELECT 1 FROM sys.partition_functions WHERE name = @fun_name)
    BEGIN
        PRINT @cmd;
        EXEC (@cmd);
        PRINT 'PARTITION FUNCTION ' + @fun_name + ' is created';
    END
    ELSE
        PRINT 'PARTITION FUNCTION ' + @fun_name + ' already exists';

    -- FILEGROUPS + FILES
    DECLARE @table_fg sysname = REPLACE(CONCAT('fg_', @dbName, '_', @TableAlias), '__', '_');

    DECLARE @fg_name sysname;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT fg_name FROM #t_range
        UNION ALL
        SELECT @table_fg;

    OPEN cur;
    FETCH NEXT FROM cur INTO @fg_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @file_name sysname = @fg_name;

        DECLARE @full_name nvarchar(4000) =
            REPLACE(CONCAT(
                @PathToFile, '\', @dbName,
                '\fg_', @dbName, '_', @TableAlias,
                '\', @file_name, '.ndf'
            ), '__', '_');

        IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = @fg_name)
        BEGIN
            SET @cmd = N'ALTER DATABASE ' + QUOTENAME(@dbName) + N' ADD FILEGROUP ' + QUOTENAME(@fg_name) + N';';
            PRINT @cmd;
            EXEC (@cmd);
        END

        IF NOT EXISTS (SELECT 1 FROM sys.database_files WHERE name = @file_name)
        BEGIN
            SET @cmd = CONCAT(
                N'ALTER DATABASE ', QUOTENAME(@dbName),
                N' ADD FILE (NAME = ', QUOTENAME(@file_name, ''''),
                N', FILENAME = ', QUOTENAME(@full_name, ''''),
                N', SIZE = 8192KB, FILEGROWTH = 65536KB) TO FILEGROUP ',
                QUOTENAME(@fg_name), N';'
            );
            PRINT @cmd;
            EXEC (@cmd);
        END

        FETCH NEXT FROM cur INTO @fg_name;
    END

    CLOSE cur;
    DEALLOCATE cur;

    -- PARTITION SCHEME: base FG + monthly FG list
    DECLARE @scheme_name sysname = REPLACE(CONCAT('pschema_', @fun_name), '__', '_');

    DECLARE @all_fg nvarchar(max) =
    (
        SELECT STRING_AGG(QUOTENAME(fg_name), ',') WITHIN GROUP (ORDER BY range_name)
        FROM #t_range
    );

    SET @cmd = CONCAT(
        N'CREATE PARTITION SCHEME ', QUOTENAME(@scheme_name),
        N' AS PARTITION ', QUOTENAME(@fun_name),
        N' TO (', QUOTENAME(@table_fg), N',', @all_fg, N');'
    );

    IF NOT EXISTS (SELECT 1 FROM sys.partition_schemes WHERE name = @scheme_name)
    BEGIN
        PRINT @cmd;
        EXEC (@cmd);
        PRINT 'PARTITION SCHEME ' + @scheme_name + ' is created';
    END
    ELSE
        PRINT 'PARTITION SCHEME ' + @scheme_name + ' already exists';
END
