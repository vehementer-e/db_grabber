-- ============================================= 
-- Author: А. Никитин
-- Create date: 22.11.2023
-- Description: DWH-2340 Проверка валидности объектов Find invalid objects
-- ============================================= 
CREATE   PROC dbo.Monitoring_invalid_objects
	@isDebug int = 0,
	@ProcessGUID varchar(36) = NULL -- guid процесса
	--@SendEmail int = 0
AS
BEGIN
SET NOCOUNT ON;
	SELECT @isDebug = isnull(@isDebug, 0)
	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	--SELECT @SendEmail = isnull(@SendEmail, 0)

	DECLARE @db_name nvarchar(255) = db_name()

	DROP TABLE IF EXISTS #t_objects
	CREATE TABLE #t_objects(
		created_at datetime not null default getdate(),
		db_name nvarchar(255) NOT NULL,
		obj_type varchar(2) NOT NULL,
		obj_id int NOT NULL, -- PRIMARY KEY
		obj_name nvarchar(300) NOT NULL,
		err_message nvarchar(2048) NOT NULL
	)

	

	INSERT INTO #t_objects ([db_name], obj_type, obj_id, obj_name, err_message)
	SELECT 
		[db_name] = @db_name
		, o.[type]
		, t.referencing_id
		, obj_name = QUOTENAME(SCHEMA_NAME(o.[schema_id])) + '.' + QUOTENAME(o.name)
		, 'Invalid object name ''' + t.obj_name + ''''
	FROM (
		SELECT
			  d.referencing_id
			--, obj_name = MAX(COALESCE(d.referenced_database_name + '.', '') 
			--        + COALESCE(d.referenced_schema_name + '.', '') 
			--        + d.referenced_entity_name)
			, obj_name = COALESCE(d.referenced_database_name + '.', '') 
					+ COALESCE(d.referenced_schema_name + '.', '') 
					+ d.referenced_entity_name
		FROM sys.sql_expression_dependencies d
		WHERE 1=1
			AND d.is_ambiguous = 0
			AND d.referenced_id IS NULL -- если не можем определить от какого объекта зависимость
			AND d.referenced_server_name IS NULL -- игнорируем объекты с Linked server
			AND CASE d.referenced_class -- если не существует
				WHEN 1 -- объекта
					THEN OBJECT_ID(
						ISNULL(QUOTENAME(d.referenced_database_name), DB_NAME()) + '.' + 
						ISNULL(QUOTENAME(d.referenced_schema_name), SCHEMA_NAME()) + '.' + 
						QUOTENAME(d.referenced_entity_name))
				WHEN 6 -- или типа данных
					THEN TYPE_ID(
						ISNULL(d.referenced_schema_name, SCHEMA_NAME()) + '.' + d.referenced_entity_name) 
				WHEN 10 -- или XML схемы
					THEN (
						SELECT 1 FROM sys.xml_schema_collections x 
						WHERE x.name = d.referenced_entity_name
							AND x.[schema_id] = ISNULL(SCHEMA_ID(d.referenced_schema_name), SCHEMA_ID())
						)
				END IS NULL
			--отсечь рарезервированные Deleted, Inserted (напр. в триггерах)
			AND d.referenced_entity_name NOT IN ('Deleted', 'Inserted')
		--GROUP BY d.referencing_id
	) t
	JOIN sys.objects o ON t.referencing_id = o.[object_id]
	WHERE 1=1
		AND len(t.obj_name) >= 3 --4 -- 12 -- 4 -- чтобы не показывать валидные алиасы, как невалидные объекты


	DECLARE
		  @obj_id INT
		, @obj_name NVARCHAR(300)
		, @obj_type CHAR(2)

	DECLARE cur CURSOR FAST_FORWARD READ_ONLY LOCAL FOR
		SELECT
			  sm.[object_id]
			, QUOTENAME(SCHEMA_NAME(o.[schema_id])) + '.' + QUOTENAME(o.name)
			, o.[type]
		FROM sys.sql_modules sm
		JOIN sys.objects o ON sm.[object_id] = o.[object_id]
		LEFT JOIN (
			SELECT s.referenced_id
			FROM sys.sql_expression_dependencies s
			JOIN sys.objects o ON o.object_id = s.referencing_id
			WHERE s.is_ambiguous = 0
				AND s.referenced_server_name IS NULL
				AND o.[type] IN ('C', 'D', 'U')
			GROUP BY s.referenced_id
		) sed ON sed.referenced_id = sm.[object_id]
		WHERE sm.is_schema_bound = 0 -- объект создан без опции WITH SCHEMABINDING
			AND sm.[object_id] NOT IN (SELECT o2.obj_id FROM #t_objects o2) -- чтобы повторно не определять невалидные объекты
			AND OBJECTPROPERTY(sm.[object_id], 'IsEncrypted') = 0
			AND (
				  o.[type] IN ('IF', 'TF', 'V', 'TR')
				-- в редких случаях, sp_refreshsqlmodule может портить метаданные хранимых процедур (Bug #656863)
				--OR o.[type] = 'P' 
				OR (
					   o.[type] = 'FN'
					AND
					   -- игнорируем скалярные функции, которые используются в DEFAULT/CHECK констрейнтах и в COMPUTED столбцах
					   sed.referenced_id IS NULL
				)
		   )

	OPEN cur

	FETCH NEXT FROM cur INTO @obj_id, @obj_name, @obj_type

	WHILE @@FETCH_STATUS = 0 BEGIN

		BEGIN TRY

			BEGIN TRANSACTION
				EXEC sys.sp_refreshsqlmodule @name = @obj_name, @namespace = N'OBJECT' 
			COMMIT TRANSACTION

		END TRY
		BEGIN CATCH

			IF XACT_STATE() <> 0
				ROLLBACK TRANSACTION

			INSERT INTO #t_objects(db_name, obj_type, obj_id, obj_name, err_message)
			SELECT @db_name, @obj_type, @obj_id, @obj_name, ERROR_MESSAGE()

		END CATCH

		FETCH NEXT FROM cur INTO @obj_id, @obj_name, @obj_type

	END

	CLOSE cur
	DEALLOCATE cur

	/*
	--убрать из списка объекты, которые попали из-за алиасов
	DROP TABLE IF EXISTS #t_dm_sql_referenced_entities
	CREATE TABLE #t_dm_sql_referenced_entities(
		[referencing_minor_id] [int] NULL,
		[referenced_server_name] [nvarchar](128) NULL,
		[referenced_database_name] [nvarchar](128) NULL,
		[referenced_schema_name] [nvarchar](128) NULL,
		[referenced_entity_name] [nvarchar](128) NULL,
		[referenced_minor_name] [nvarchar](128) NULL,
		[referenced_id] [int] NULL,
		[referenced_minor_id] [int] NULL,
		[referenced_class] [tinyint] NULL,
		[referenced_class_desc] [nvarchar](60) NULL,
		[is_caller_dependent] [bit] NOT NULL,
		[is_ambiguous] [bit] NOT NULL,
		[is_selected] [bit] NOT NULL,
		[is_updated] [bit] NOT NULL,
		[is_select_all] [bit] NOT NULL,
		[is_all_columns_found] [bit] NOT NULL,
		[is_insert_all] [bit] NOT NULL,
		[is_incomplete] [bit] NOT NULL
	)

	DROP TABLE IF EXISTS #t_valid_objects
	CREATE TABLE #t_valid_objects(
		obj_id int NOT NULL PRIMARY KEY,
		obj_name nvarchar(300) NOT NULL
	)

	DECLARE cur2 CURSOR FAST_FORWARD READ_ONLY LOCAL FOR
		SELECT DISTINCT T.obj_id, T.obj_name 
		FROM #t_objects AS T
		ORDER BY T.obj_id

	OPEN cur2

	FETCH NEXT FROM cur2 INTO @obj_id, @obj_name

	WHILE @@FETCH_STATUS = 0 BEGIN
		TRUNCATE TABLE #t_dm_sql_referenced_entities

		--BEGIN TRY
			INSERT #t_dm_sql_referenced_entities
			SELECT 
				F.referencing_minor_id,
				F.referenced_server_name,
				F.referenced_database_name,
				F.referenced_schema_name,
				F.referenced_entity_name,
				F.referenced_minor_name,
				F.referenced_id,
				F.referenced_minor_id,
				F.referenced_class,
				F.referenced_class_desc,
				F.is_caller_dependent,
				F.is_ambiguous,
				F.is_selected,
				F.is_updated,
				F.is_select_all,
				F.is_all_columns_found,
				F.is_insert_all,
				F.is_incomplete 
			FROM sys.dm_sql_referenced_entities(@obj_name, 'object') AS F

			INSERT #t_valid_objects(obj_id, obj_name)
			SELECT @obj_id, @obj_name
		--END TRY
		--BEGIN CATCH

		--END CATCH

		FETCH NEXT FROM cur2 INTO @obj_id, @obj_name
	END

	CLOSE cur2
	DEALLOCATE cur2


	--DELETE T
	--FROM #t_objects AS T
	--	INNER JOIN #t_valid_objects AS V
	--		ON V.obj_id = T.obj_id

	--test
	--SELECT * 
	--FROM #t_valid_objects AS V
	*/


	--created_at			datetime not null default getdate()
	IF object_id('LogDb.dbo.Invalid_objects_log') is null
	BEGIN
		SELECT TOP(0) 
			T.created_at,
            T.db_name,
            T.obj_type,
            T.obj_id,
            T.obj_name,
            T.err_message
		INTO LogDb.dbo.Invalid_objects_log
		FROM #t_objects AS T
	END

	/*
	исключить процедуры
	[dbo].[DatabaseBackup]
	[dbo].[DatabaseIntegrityCheck]
	объекты схемы tmp
	*/

	DELETE T
	FROM #t_objects AS T
	WHERE 
		T.obj_name IN (
				'[dbo].[DatabaseBackup]',
				'[dbo].[DatabaseIntegrityCheck]'
			)
		OR 
		left(T.obj_name, 6) = '[tmp].'


	BEGIN TRAN
		DELETE L
		FROM LogDb.dbo.Invalid_objects_log AS L
		WHERE L.db_name = @db_name

		INSERT LogDb.dbo.Invalid_objects_log
		SELECT 
			T.created_at,
			T.db_name,
			T.obj_type,
			T.obj_id,
			T.obj_name,
			T.err_message
		FROM #t_objects AS T
		ORDER BY T.db_name, T.obj_type, T.obj_name
	COMMIT TRAN

	/*
	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @eventName,
		@eventType = @eventType,
		@message = @message,
		@description = @description,
		@SendEmail = @SendEmail,
		@ProcessGUID = @ProcessGUID,
		@eventMessageText = @eventMessageText,
		@loggerName = 'admin_test'
	*/
END 

