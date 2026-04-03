CREATE PROCEDURE dbo.sp_select_except

    @TempTable NVARCHAR(MAX),   -- Оригинальное имя временной таблицы (например, #t1)
    @MainTable NVARCHAR(MAX),   -- Название основной таблицы
    @IDColumn NVARCHAR(MAX) ,    -- Название колонки с ключом (ID)
    @from NVARCHAR(MAX)    -- Название основной таблицы
AS
BEGIN
     DECLARE @SQL NVARCHAR(MAX);
    DECLARE @Columns NVARCHAR(MAX);
    DECLARE @RealTempTable NVARCHAR(MAX);

    -- Получаем реальное имя временной таблицы, включая суффикс из tempdb.sys.tables
    SELECT TOP 1 @RealTempTable = name
    FROM tempdb.sys.tables with(nolock)
    WHERE name LIKE @TempTable + '%' AND type = 'U'  -- U - это пользовательские таблицы
	order by case when name = @TempTable then 1 end desc
    -- Отладочный вывод для проверки имени таблицы
    PRINT 'Real Temp Table: ' + ISNULL(@RealTempTable, 'NULL');

    IF @RealTempTable IS NULL
    BEGIN
        PRINT 'Временная таблица не найдена';
        RETURN;
    END


	 SELECT @Columns = STRING_AGG(QUOTENAME(name), ', ')
    FROM tempdb.sys.columns
    WHERE object_id = (SELECT object_id FROM tempdb.sys.tables WHERE name = @RealTempTable);

    -- Отладочный вывод для проверки колонок
    PRINT 'Columns: ' + ISNULL(@Columns, 'NULL');
 SET @SQL = '
    INSERT INTO ' + @TempTable + ' (' + @Columns + ')
    SELECT ' + @Columns + '
    FROM  ' + @from + '
    EXCEPT
    SELECT ' + @Columns + '
    FROM ' + @MainTable + '
    WHERE ' + @MainTable + '.' + @IDColumn + ' IN (
        SELECT ' + @IDColumn + '
        FROM   ' + @from + '
    );';

    -- Возвращаем сгенерированный SQL запрос
select @SQL;
END


