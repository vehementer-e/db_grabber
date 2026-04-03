CREATE PROCEDURE [dbo].[sp_alter]
    @SearchString NVARCHAR(255),  -- Часть или полное имя искомой хранимой процедуры
    @ReplaceFrom NVARCHAR(255) = '',   -- Строка, которую нужно заменить
    @ReplaceTo NVARCHAR(255) = '',     -- Строка, на которую нужно заменить
    @debug INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    -- Лог для сохранения выполнения шагов
    DECLARE @Log TABLE (
        StepNumber INT IDENTITY(1,1),
        StepDescription NVARCHAR(4000),
        Status NVARCHAR(100),
        Details NVARCHAR(MAX)
    );

    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @ProcedureName NVARCHAR(255);
    DECLARE @ProcedureDefinition NVARCHAR(MAX);
    DECLARE @RowCount INT;

    -- Найти хранимую процедуру по имени
    INSERT INTO @Log (StepDescription, Status)
    VALUES ('Searching for procedure containing the search string', 'Started');

    SELECT 
        o.name AS ProcedureName,
        m.definition AS ProcedureDefinition
    INTO #ProceduresToAlter
    FROM sys.objects o
    JOIN sys.sql_modules m ON o.object_id = m.object_id
    WHERE 
        o.type in ('v',  'P')  -- Только хранимые процедуры
        AND o.name LIKE '%' + @SearchString + '%';

    -- Проверка количества найденных процедур
    SELECT @RowCount = COUNT(*) FROM #ProceduresToAlter;

    IF @RowCount = 1
    BEGIN
        INSERT INTO @Log (StepDescription, Status, details)
        select  'Procedure found successfully', 'Success' , ProcedureDefinition
		from #ProceduresToAlter;

        -- Получение имени и определения процедуры
        SELECT @ProcedureName = ProcedureName, @ProcedureDefinition = ProcedureDefinition
        FROM #ProceduresToAlter;

        -- Обработка текста процедуры: замена первого незакомментированного 'CREATE PROCEDURE' на 'ALTER PROCEDURE'
        DECLARE @Pattern NVARCHAR(100) = '%CREATE%PROC%'; -- Шаблон для поиска
        DECLARE @StartIndex INT = 1;
        DECLARE @CreateIndex INT;
        DECLARE @IsCommented BIT = 0;

        -- Функция для поиска незакомментированного 'CREATE PROCEDURE'
       
            -- Заменяем 'CREATE PROCEDURE' на 'ALTER PROCEDURE'
       

        -- Замена строки в теле процедуры
        SET @ProcedureDefinition = REPLACE(@ProcedureDefinition, @ReplaceFrom, @ReplaceTo);

DECLARE @Search NVARCHAR(255) = 'CREATE';
DECLARE @Replace NVARCHAR(255) = 'ALTER';

-- Находим позицию первого вхождения шаблона поиска
DECLARE @Pos INT = CHARINDEX(@Search, @ProcedureDefinition);

-- Проверяем, если вхождение найдено
IF @Pos > 0
BEGIN
    -- Замена первого вхождения
    SET @ProcedureDefinition = STUFF(
        @ProcedureDefinition, 
        @Pos, 
        LEN(@Search), 
        @Replace
    );
END


        -- Подготовка SQL для выполнения
        SET @SQL = @ProcedureDefinition;

        -- Лог изменения процедуры
        INSERT INTO @Log (StepDescription, Status, Details)
        VALUES ('Altering proc ' + @ProcedureName, 'Started', @SQL);

        -- Выполнение команды
        BEGIN TRY
            IF @debug = 1 
            BEGIN
                --SELECT @SQL AS [Generated SQL Script]; 
				declare @var_void    varchar(max) =   ''
				   INSERT INTO @Log (StepDescription, Status)
                VALUES ('@debug = 1 NOT altered', 'NOT altered');

            END
            ELSE 
            BEGIN
                EXEC sp_executesql @SQL;
                INSERT INTO @Log (StepDescription, Status)
                VALUES ('Procedure altered successfully', 'Success');
            END
        END TRY
        BEGIN CATCH
            INSERT INTO @Log (StepDescription, Status, Details)
            VALUES ('Error altering procedure', 'Failed', ERROR_MESSAGE());
        END CATCH;
    END
    ELSE IF @RowCount = 0
    BEGIN
        -- Лог если не найдена ни одна процедура
        INSERT INTO @Log (StepDescription, Status)
        VALUES ('No procedure found matching the criteria', 'Failed');
    END
    ELSE
    BEGIN
        -- Лог если найдено больше одной процедуры
        INSERT INTO @Log (StepDescription, Status)
        VALUES ('Multiple procedures found matching the criteria', 'Failed');

        -- Добавляем имена найденных процедур в лог
        INSERT INTO @Log (StepDescription, Status, Details)
        SELECT 'Found procedures: ' + STRING_AGG(ProcedureName, ', '), 'Failed', ''
        FROM #ProceduresToAlter;
    END

    -- Удаление временной таблицы
    DROP TABLE IF EXISTS #ProceduresToAlter;

    -- Возврат лога выполнения
    SELECT * FROM @Log;
END;
