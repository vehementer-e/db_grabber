
-- Usage: запуск процедуры с параметрами
-- EXEC dbo.CreateMonthlyFG_PF_PS_ByMonths @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   PROCEDURE dbo.CreateMonthlyFG_PF_PS_ByMonths
(
    @TableAlias    sysname,           
    @PathToFile    nvarchar(4000),     -- например D:\data\Stg\SZD
    @MonthsBack    int = 12,
    @MonthsForward int = 12
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @db sysname = DB_NAME();

    -- первый день текущего месяца
    DECLARE @BaseMonth date = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);

    -- стартовый месяц и "последняя граница" (на +1 месяц дальше, чтобы последний месяц целиком накрывался)
    DECLARE @StartMonth date = DATEADD(month, -@MonthsBack, @BaseMonth);
    DECLARE @EndBoundary date = DATEADD(month, @MonthsForward + 1, @BaseMonth);

    -- список границ месяцев (включая @EndBoundary)
    ;WITH c AS
    (
        SELECT @StartMonth AS d
        UNION ALL
        SELECT DATEADD(month, 1, d)
        FROM c
        WHERE d < @EndBoundary
    )
    SELECT d INTO #Months
    FROM c
    OPTION (MAXRECURSION 0);

    -- имена PF/PS/FG
    DECLARE @PF sysname = N'pfn_range_right_date_part_' + @TableAlias;
    DECLARE @PS sysname = N'pschema_' + @PF;
    DECLARE @BaseFG sysname = N'fg_' + @db + N'_' + @TableAlias;

    -- собрать VALUES('YYYY-MM-DD',...)
    DECLARE @Periods nvarchar(max) =
    (
        SELECT STRING_AGG(QUOTENAME(CONVERT(varchar(10), d, 120), ''''), N',')
        WITHIN GROUP (ORDER BY d)
        FROM #Months
    );

    -- PF
    IF NOT EXISTS (SELECT 1 FROM sys.partition_functions WHERE name = @PF)
    BEGIN
        DECLARE @sql nvarchar(max) =
            N'CREATE PARTITION FUNCTION ' + QUOTENAME(@PF) +
            N' (date) AS RANGE RIGHT FOR VALUES (' + @Periods + N');';
        print(@sql)
		--EXEC(@sql);
    END

    -- базовая FG
    IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = @BaseFG)
    BEGIN
        DECLARE @sql_fg nvarchar(max) =
            N'ALTER DATABASE ' + QUOTENAME(@db) + N' ADD FILEGROUP ' + QUOTENAME(@BaseFG) + N';';
        print(@sql_fg)
		--EXEC(@sql_fg);
    END

    -- базовый файл (в базовую FG)
    DECLARE @BaseFile sysname = N'Stg_SZD_LoanMetrics_01'  -- временно так ))
    IF NOT EXISTS (SELECT 1 FROM sys.database_files WHERE name = @BaseFile)
    BEGIN
        DECLARE @BasePath nvarchar(4000) = @PathToFile + N'\' + @BaseFile + N'.ndf';

        DECLARE @sql_basefile nvarchar(max) =
            N'ALTER DATABASE ' + QUOTENAME(@db) + N' ADD FILE (' +
            N' NAME = ' + QUOTENAME(@BaseFile, '''') +
            N', FILENAME = ' + QUOTENAME(@BasePath, '''') +
            N', SIZE = 1024MB, FILEGROWTH = 1024MB) TO FILEGROUP ' + QUOTENAME(@BaseFG) + N';';

        --EXEC(@sql_basefile);
		print(@sql_basefile);
    END

    -- месячные FG + файлы
    drop table if exists #Plan;
	;WITH plann AS
    (
        SELECT
            d,
            FG = CONVERT(sysname, N'fg_' + @db + N'_' + @TableAlias + N'_' + FORMAT(d, 'yyyyMMdd')),
            FileName = CONVERT(sysname, N'file_' + @db + N'_' + @TableAlias + N'_' + FORMAT(d, 'yyyyMMdd')),
            FilePath = CONVERT(nvarchar(4000), @PathToFile + N'\file_' + @db + N'_' + @TableAlias + N'_' + FORMAT(d, 'yyyyMMdd') + N'.ndf')
        FROM #Months
    )
    SELECT * INTO #Plan FROM plann;

    DECLARE @fg sysname, @fn sysname, @fp nvarchar(4000);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT FG, FileName, FilePath
        FROM #Plan
        ORDER BY d;

    OPEN cur;
    FETCH NEXT FROM cur INTO @fg, @fn, @fp;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE name = @fg)
        BEGIN
            DECLARE @sql_addfg nvarchar(max) =
                N'ALTER DATABASE ' + QUOTENAME(@db) + N' ADD FILEGROUP ' + QUOTENAME(@fg) + N';';
            --EXEC(@sql_addfg);
			print(@sql_addfg)
        END

        IF NOT EXISTS (SELECT 1 FROM sys.database_files WHERE name = @fn)
        BEGIN
            DECLARE @sql_addfile nvarchar(max) =
                N'ALTER DATABASE ' + QUOTENAME(@db) + N' ADD FILE (' +
                N' NAME = ' + QUOTENAME(@fn, '''') +
                N', FILENAME = ' + QUOTENAME(@fp, '''') +
                N', SIZE = 10GB, FILEGROWTH = 1024MB) TO FILEGROUP ' + QUOTENAME(@fg) + N';';
            --EXEC(@sql_addfile);
			print(@sql_addfile)
        END

        FETCH NEXT FROM cur INTO @fg, @fn, @fp;
    END

    CLOSE cur;
    DEALLOCATE cur;

    -- PS: base FG + все месячные FG
    IF NOT EXISTS (SELECT 1 FROM sys.partition_schemes WHERE name = @PS)
    BEGIN
        DECLARE @FGList nvarchar(max) =
            (SELECT STRING_AGG(QUOTENAME(FG), N',') WITHIN GROUP (ORDER BY d) FROM #Plan);

        DECLARE @sql_ps nvarchar(max) =
            N'CREATE PARTITION SCHEME ' + QUOTENAME(@PS) +
            N' AS PARTITION ' + QUOTENAME(@PF) +
            N' TO (' + QUOTENAME(@BaseFG) + N',' + @FGList + N');';

        --EXEC(@sql_ps);
		print(@sql_ps);
    END
END
