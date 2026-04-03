-- Usage: запуск процедуры с параметрами
-- EXEC dbo.CreateMonthlyFG_PF_PS1 @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   PROCEDURE dbo.CreateMonthlyFG_PF_PS1
(
    @SchemaName      sysname,
    @TableName       sysname,
    @TableAlias      sysname,   -- SZD_LoanMetrics
    @PartitionColumn sysname,   -- ОтчетнаяДата
    @PathToFile      nvarchar(4000), -- существующая папка!
    @FutureMonths    int = 12,
    @PastMonths      int = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @db sysname = DB_NAME();

    -- 0) Базовые проверки
    IF NULLIF(LTRIM(RTRIM(@PathToFile)), N'') IS NULL
        THROW 51000, 'PathToFile is empty. Provide an existing directory path.', 1;

    -- папка должна существовать (SQL Server не создаёт директории)
    DECLARE @dirExists int;
    EXEC master.dbo.xp_fileexist @PathToFile, @dirExists OUTPUT;
    IF ISNULL(@dirExists, 0) = 0
        THROW 51001, 'PathToFile directory does not exist (SQL Server cannot create folders).', 1;

    IF OBJECT_ID(QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName), 'U') IS NULL
        THROW 51002, 'Target table does not exist.', 1;

    -- 1) MIN/MAX по колонке партиции
    DECLARE @MinDate date, @MaxDate date;
    DECLARE @sql nvarchar(max) =
N'SELECT
    @MinDate = CONVERT(date, MIN(' + QUOTENAME(@PartitionColumn) + N')),
    @MaxDate = CONVERT(date, MAX(' + QUOTENAME(@PartitionColumn) + N'))
  FROM ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N';';

    EXEC sys.sp_executesql
        @sql,
        N'@MinDate date OUTPUT, @MaxDate date OUTPUT',
        @MinDate = @MinDate OUTPUT, @MaxDate = @MaxDate OUTPUT;

    IF @MinDate IS NULL OR @MaxDate IS NULL
        THROW 51003, 'MIN/MAX of partition column is NULL. Table is empty or partition column not populated.', 1;

    -- округляем до первого дня месяца
    SET @MinDate = DATEFROMPARTS(YEAR(@MinDate), MONTH(@MinDate), 1);
    SET @MaxDate = DATEFROMPARTS(YEAR(@MaxDate), MONTH(@MaxDate), 1);

    SET @MinDate = DATEADD(month, -@PastMonths, @MinDate);
    SET @MaxDate = DATEADD(month,  @FutureMonths, @MaxDate);

    -- 2) Список границ месяцев
    ;WITH c AS (
        SELECT @MinDate AS d
        UNION ALL
        SELECT DATEADD(month, 1, d)
        FROM c
        WHERE d < @MaxDate
    )
    SELECT d
    INTO #Months
    FROM c
    OPTION (MAXRECURSION 0);

    IF NOT EXISTS (SELECT 1 FROM #Months)
        THROW 51004, 'Month boundaries list is empty (unexpected).', 1;

    DECLARE @Periods nvarchar(max) =
        (SELECT STRING_AGG(QUOTENAME(CONVERT(varchar(10), d, 120), ''''), N',')
         WITHIN GROUP (ORDER BY d)
         FROM #Months);

    -- 3) Имена
    DECLARE @PF sysname = N'pfn_range_right_date_part_' + @TableAlias;
    DECLARE @PS sysname = N'pschema_' + @PF;
    DECLARE @BaseFG sysname = N'fg_' + @db + N'_' + @TableAlias;

    -- 4) Partition Function (только если нет)
    IF NOT EXISTS (SELECT 1 FROM sys.partition_functions WHERE name = @PF)
    BEGIN
        SET @sql = N'CREATE PARTITION FUNCTION ' + QUOTENAME(@PF) +
                   N' (date) AS RANGE RIGHT FOR VALUES (' + @Periods + N');';
        EXEC(@sql);
    END

    -- 5) Создаём базовую FG если нет
    IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = @BaseFG)
    BEGIN
        SET @sql = N'ALTER DATABASE ' + QUOTENAME(@db) + N' ADD FILEGROUP ' + QUOTENAME(@BaseFG) + N';';
        EXEC(@sql);
    END

    -- 6) Создаём базовый файл (если в FG нет файлов)
    IF NOT EXISTS (
        SELECT 1
        FROM sys.database_files df
        JOIN sys.filegroups fg ON fg.data_space_id = df.data_space_id
        WHERE fg.name = @BaseFG AND df.type_desc = 'ROWS'
    )
    BEGIN
        DECLARE @BaseFile sysname = @BaseFG + N'_01';
        DECLARE @BasePath nvarchar(4000) = @PathToFile + N'\' + @BaseFile + N'.ndf';

        SET @sql =
            N'ALTER DATABASE ' + QUOTENAME(@db) + N' ADD FILE (' +
            N' NAME = ' + QUOTENAME(@BaseFile, '''') +
            N', FILENAME = ' + QUOTENAME(@BasePath, '''') +
            N', SIZE = 1024MB, FILEGROWTH = 1024MB) TO FILEGROUP ' + QUOTENAME(@BaseFG) + N';';

        EXEC(@sql);
    END

    -- 7) Месячные FG+файлы
    ;WITH x AS (
        SELECT
          d,
          FG = CONVERT(sysname, N'fg_' + @db + N'_' + @TableAlias + N'_' + FORMAT(d, 'yyyyMMdd')),
          FileName = CONVERT(sysname, N'file_' + @db + N'_' + @TableAlias + N'_' + FORMAT(d, 'yyyyMMdd')),
          FilePath = CONVERT(nvarchar(4000), @PathToFile + N'\file_' + @db + N'_' + @TableAlias + N'_' + FORMAT(d, 'yyyyMMdd') + N'.ndf')
        FROM #Months
    )
    SELECT * INTO #FGPlan FROM x;

    DECLARE @fg sysname, @fn sysname, @fp nvarchar(4000);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT FG, FileName, FilePath FROM #FGPlan ORDER BY d;

    OPEN cur;
    FETCH NEXT FROM cur INTO @fg, @fn, @fp;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = @fg)
        BEGIN
            SET @sql = N'ALTER DATABASE ' + QUOTENAME(@db) + N' ADD FILEGROUP ' + QUOTENAME(@fg) + N';';
            EXEC(@sql);
        END

        IF NOT EXISTS (SELECT 1 FROM sys.database_files WHERE name = @fn)
        BEGIN
            SET @sql =
                N'ALTER DATABASE ' + QUOTENAME(@db) + N' ADD FILE (' +
                N' NAME = ' + QUOTENAME(@fn, '''') +
                N', FILENAME = ' + QUOTENAME(@fp, '''') +
                N', SIZE = 1024MB, FILEGROWTH = 1024MB) TO FILEGROUP ' + QUOTENAME(@fg) + N';';
            EXEC(@sql);
        END

        FETCH NEXT FROM cur INTO @fg, @fn, @fp;
    END

    CLOSE cur;
    DEALLOCATE cur;

    -- 8) Partition Scheme (base FG + monthly FG list)
    IF NOT EXISTS (SELECT 1 FROM sys.partition_schemes WHERE name = @PS)
    BEGIN
        DECLARE @FGList nvarchar(max) =
            (SELECT STRING_AGG(QUOTENAME(FG), N',') WITHIN GROUP (ORDER BY d) FROM #FGPlan);

        SET @sql = N'CREATE PARTITION SCHEME ' + QUOTENAME(@PS) +
                   N' AS PARTITION ' + QUOTENAME(@PF) +
                   N' TO (' + QUOTENAME(@BaseFG) + N',' + @FGList + N');';

        EXEC(@sql);
    END
END
