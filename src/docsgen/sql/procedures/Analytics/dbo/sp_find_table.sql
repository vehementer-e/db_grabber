CREATE     PROC [dbo].[sp_find_table] 
    @table NVARCHAR(MAX), 
    @db_search NVARCHAR(MAX) = 'analytics'
AS
 
declare @details bigint = case when right(@table, 1) = ' '   then 1 else 0 end 
select @details

set @db_search = (select db_name())
    DECLARE @q NVARCHAR(MAX) = @table
    DECLARE @SQL1 NVARCHAR(MAX);
    DECLARE @db NVARCHAR(MAX);
    DECLARE @table_name NVARCHAR(MAX);

    -- Убираем скобки, если они есть
    SET @table = REPLACE(REPLACE(@table, '[', ''), ']', '');

    -- Если это временная таблица (с решеткой), используем tempdb
    IF LEFT(@table, 1) = '#'
    BEGIN
        SET @db = 'tempdb';
        SET @table_name = @table; -- Для временной таблицы имя остается полным (например, #temp)
    END
    ELSE
    BEGIN
        -- Если таблица с указанием базы данных (например, dbname.schema.table), извлекаем базу данных
        IF CHARINDEX('.', @table) > 0
        BEGIN
            SET @db = LEFT(@table, CHARINDEX('.', @table) - 1);
            SET @table_name = +'['+@table+']'; -- Используем полное имя объекта (например, dbname.schema.table)
        END
        ELSE
        BEGIN
            -- Если база данных не указана, используем значение по умолчанию (@db_search)
            SET @db = @db_search;
            SET @table_name = @db + '.dbo.[' + @table+']'; -- По умолчанию считаем, что схема dbo
        END
    END

    -- Формируем SQL-запрос для получения списка столбцов
    SET @SQL1 = '
        USE ' + @db + '

        SELECT ''SELECT 
        '' + STRING_AGG(CAST('''' + ''   a.['' + name + ''] '' AS VARCHAR(MAX)), ''
,'')
        + ''

        FROM 

        '' + ''' + @table_name + ''' + '' a'' , ''SELECT 
        '' + STRING_AGG(CAST('''' + ''   a.['' + name + ''] '' AS VARCHAR(MAX)), '','')
        + ''FROM '' + ''' + @table_name + ''' + '' a'' 

        FROM sys.columns c
        WHERE [object_id] = OBJECT_ID(''' + @table_name + ''')
    ';

	--declare @id  bigint =  OBJECT_ID(@table_name )
    -- Выполняем запрос и выводим отладочную информацию
    --PRINT @SQL1;

	 

    -- Проверяем существование временной таблицы и создаем её
    DROP TABLE IF EXISTS #t3282392397346378383646;
    CREATE TABLE #t3282392397346378383646 (text NVARCHAR(MAX) , text_no_new_lines NVARCHAR(MAX)  );

    -- Вставляем результат динамического SQL-запроса в таблицу
    BEGIN TRY
        INSERT INTO #t3282392397346378383646 
        EXEC sp_executesql @SQL1;

		  
if @details=1
select * from     dwh    WHERE table_full_name LIKE '%' + @table + '%' 
order by table_full_name2



    END TRY
    BEGIN CATCH
        -- Обработка ошибок, если что-то пошло не так при выполнении динамического SQL-запроса
        SELECT ERROR_MESSAGE() AS ErrorMessage;
        RETURN;
    END CATCH;

    -- Проверяем результат
    IF EXISTS (SELECT * FROM #t3282392397346378383646 WHERE text IS NOT NULL)
    BEGIN
        SELECT 'ok', * FROM #t3282392397346378383646;
		
		 

	--declare @sql_sample    varchar(max) =    'select top 100 * from '+@table
	--exec (@sql_sample)


    END
 
    BEGIN
        -- Если не найдены столбцы, пытаемся найти таблицу в dwh
        SELECT 
            table_full_name2 table_full_name , 
            'SELECT 
            ' + STRING_AGG(CAST('' + '   a.[' + column_name + '] ' AS VARCHAR(MAX)), '
,') WITHIN GROUP (ORDER BY ORDINAL_POSITION)
            + '

            FROM 

            ' + MAX(table_full_name2) + ' a'

        FROM  analytics.dbo.dwh c
        WHERE table_full_name LIKE '%' + @table + '%' 
      --  AND source = ISNULL(@db_search, source)
        GROUP BY table_full_name2
        ORDER BY table_full_name2;

		SELECT  'analytics' i ,  a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_analytics] a  with(nolock) where name like '%' + @table + '%' 
		order by 1
		SELECT  'feodor' i, a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_feodor] a  with(nolock) where name like '%' + @table + '%' 
		order by 1

		SELECT 'stg' i,   a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_stg] a  with(nolock) where name like '%' + @table + '%' 
		order by 1

		SELECT 'dwh2' i,   a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_dwh2] a  with(nolock) where name like '%' + @table + '%' 
		order by 1

		--SELECT  'naumen' i,  a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_naumendbreport] a  with(nolock) where name like '%' + @table + '%'   order by 1
		SELECT 'dwh_new' i,   a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_dwh_new] a  with(nolock) where name like '%' + @table + '%' order by 1
		SELECT  'reports' i,  a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_reports] a  with(nolock) where name like '%' + @table + '%' order by 1
	
	
		SELECT 'analytics*' i,  a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_analytics] a  with(nolock) where definition like '%' + @table + '%' order by 1 
		SELECT 'feodor*' i,  a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_feodor] a  with(nolock) where definition like '%' + @table + '%' order by 1
		select 'stg*' i,    a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_stg] a  with(nolock) where definition like '%' + @table + '%' order by 1
		select 'dwh2*' i,    a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_dwh2] a  with(nolock) where definition like '%' + @table + '%' order by 1
		--select 'naumen*' i,    a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_naumendbreport] a  with(nolock) where definition like '%' + @table + '%' order by 1
		select 'dwh_new*' i,    a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_dwh_new] a  with(nolock) where definition like '%' + @table + '%' order by 1
		select 'reports*' i,    a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_reports] a  with(nolock) where definition like '%' + @table + '%' order by 1
	
	
	
	
	--SELECT   a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_analytics] a  with(nolock) where name like '%' + @table + '%' 
		--SELECT   a.[name],  a.[alterSql] ,   a.[type],   a.[id],   a.[created],   a.[updated],    a.[definition] FROM  Analytics.dbo.[dwh_objects_analytics] a  with(nolock) where name like '%' + @table + '%' 
 



    END 



