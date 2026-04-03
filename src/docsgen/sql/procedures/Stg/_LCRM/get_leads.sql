-- =======================================================
-- Created: 28.02.2022. А.Никитин
-- Description:	DWH-1567 Оптимизация хранения лидов. 
-- вернуть рекордсет с информацией о лидах
-- =======================================================
CREATE   PROC [_LCRM].[get_leads]
	@Debug int = 0, -- 0 - штатное выполнение, 1 - отладочный режим
	--@ID_List _LCRM.lead_id_list READONLY, -- таблица со списком ID
	@ID_Table_Name varchar(100) = NULL, -- название таблицы со списком ID (вместо параметра @ID_List)
	@Begin_Registered date = NULL, -- начальная дата (необязательный параметр, вместо списка id)
	@End_Registered date = NULL, -- конечная дата (необязательный параметр, вместо списка id)
	@Return_Table_Name varchar(100), -- название таблицы для возвращения записей. Обязательный параметр
	@Fields_List varchar(8000) = NULL, -- список возвращаемых полей, если NULL, то все поля
	@Return_Number int = NULL OUTPUT, -- возвращаемый код, 0 - без ошибок
	@Return_Message varchar(1000) = NULL OUTPUT, -- возвращаемое сообщение
	@where nvarchar(max) = NULL -- условие where
AS
BEGIN
	SET XACT_ABORT ON
	SET NOCOUNT ON

    DECLARE @StartDate datetime, @row_count int
	DECLARE @Sql varchar(MAX), @Sql2 varchar(MAX), @Sql3 varchar(MAX)
	DECLARE @Max_Ordinal_Position int = 0
	DECLARE @ErrorMessage  nvarchar(4000), @ErrorSeverity int, @ErrorState int, @ErrorNumber int
	DECLARE @Error_Procedure nvarchar(128), @Error_Line int
	DECLARE @get_from_calculated int = 0
	DECLARE @get_from_full int = 0
	DECLARE @c1310 varchar(2) = char(13)+char(10)

BEGIN TRY
	-- проверка входных параметров
	IF @ID_Table_Name IS NULL
		AND (@Begin_Registered IS NULL OR @End_Registered IS NULL)
	BEGIN
		SELECT @Return_Message = 'ОШИБКА: Должны быть заданы либо таблица со списком ID, либо интервал дат.' 
		SELECT @Return_Number = 1
		;THROW 51000, @Return_Message, 1
		RETURN @Return_Number
	END

	--@where nvarchar(max) = NULL -- условие where
	DECLARE @where_words table(word nvarchar(4000))

	IF @where IS NOT NULL
	BEGIN
		SELECT @where = replace(replace(replace(@where, char(13), ' '), char(10), ' '), char(9), ' ')

		INSERT @where_words(word)
		SELECT S.value
		FROM string_split(@where, ' ') AS S
		WHERE trim(S.value) <> ''

		IF EXISTS(SELECT TOP 1 1 
			FROM @where_words AS W
			WHERE W.word IN (
				'ALTER', 'CREATE', 'DROP', 'SELECT', 'INSERT',
				'DELETE', 'MERGE', 'TABLE', 'DISABLE', 'TRIGGER',
				'ENABLE', 'RENAME', 'TRUNCATE'
				)
			)
		BEGIN
			SELECT @Return_Message = 'ОШИБКА: параметр @where содержит инструкции DDL/DML.'
			SELECT @Return_Number = 1
			;THROW 51000, @Return_Message, 1
			RETURN @Return_Number
		END
	END


	-- проверка существования таблицы @Return_Table_Name
	SELECT @Sql = 
		'DECLARE @Count int'+@c1310+
		'SELECT @Count = count(*) FROM ' + @Return_Table_Name
	EXEC(@Sql)

	DECLARE @Fields_Table table(
		Ordinal_Position int NOT NULL,
		Field_Name varchar(1000) NOT NULL,
		Source_Fields_id int NULL
	)

	DECLARE @Source_Fields table(
		Source_Fields_id int IDENTITY,
		Priority int NOT NULL,
		TABLE_CATALOG nvarchar(128),
		TABLE_SCHEMA nvarchar(128),
		TABLE_NAME sysname,
		ORDINAL_POSITION int,
		COLUMN_NAME sysname
	)
	------------------------------------------------


	SELECT @Return_Number = 0


	-- Поля в таблицах-источниках
	-- Priority = 1
	INSERT @Source_Fields
	(
		Priority,
		TABLE_CATALOG,
		TABLE_SCHEMA,
		TABLE_NAME,
		ORDINAL_POSITION,
		COLUMN_NAME
	)
	SELECT 
		Priority = 1,
		C.TABLE_CATALOG,
		C.TABLE_SCHEMA,
		C.TABLE_NAME,
		C.ORDINAL_POSITION,
		C.COLUMN_NAME
		--C.DATA_TYPE,
		--C.IS_NULLABLE,
	FROM INFORMATION_SCHEMA.COLUMNS AS C
	WHERE 1=1
		AND C.TABLE_SCHEMA = '_LCRM'
		AND C.TABLE_NAME = 'lcrm_leads_full_calculated'
	ORDER BY C.ORDINAL_POSITION

	-- Priority = 2
	INSERT @Source_Fields
	(
		Priority,
		TABLE_CATALOG,
		TABLE_SCHEMA,
		TABLE_NAME,
		ORDINAL_POSITION,
		COLUMN_NAME
	)
	SELECT 
		Priority = 2,
		C.TABLE_CATALOG,
		C.TABLE_SCHEMA,
		C.TABLE_NAME,
		C.ORDINAL_POSITION,
		C.COLUMN_NAME
		--C.DATA_TYPE,
		--C.IS_NULLABLE,
	FROM INFORMATION_SCHEMA.COLUMNS AS C
	WHERE 1=1
		AND C.TABLE_SCHEMA = '_LCRM'
		AND C.TABLE_NAME = 'lcrm_leads_full'
	ORDER BY C.ORDINAL_POSITION


	DROP TABLE IF EXISTS #TMP_Column_Name_List
	CREATE TABLE #TMP_Column_Name_List(
			ORDINAL_POSITION int,
			COLUMN_NAME sysname
	)

	--если НЕ передан список полей
	IF trim(isnull(@Fields_List, '')) = ''
	BEGIN
		--построить список полей из таблицы @Return_Table_Name
		IF @Return_Table_Name LIKE '#%' OR @Return_Table_Name LIKE '%.#%'
		BEGIN
			SELECT @Sql = 'USE tempdb
			INSERT #TMP_Column_Name_List(ORDINAL_POSITION, COLUMN_NAME)
			SELECT C.column_id, C.name
			FROM sys.all_columns AS C
			WHERE C.object_id = object_id(''' + @Return_Table_Name + ''')'
		END
		ELSE BEGIN
			SELECT @Sql = 'INSERT #TMP_Column_Name_List(ORDINAL_POSITION, COLUMN_NAME)
			SELECT C.column_id, C.name
			FROM sys.all_columns AS C
			WHERE C.object_id = object_id(''' + @Return_Table_Name + ''')'
		END

		--check
		--SELECT @Sql

		EXEC(@Sql)
	    
		INSERT @Fields_Table(Ordinal_Position, Field_Name)
		SELECT L.ORDINAL_POSITION, L.COLUMN_NAME
		FROM #TMP_Column_Name_List AS L

		--check
		--SELECT * FROM @Fields_Table

		--check
		--SELECT  L.* FROM @Fields_Table AS L ORDER BY L.Ordinal_Position
		
		--SELECT @Fields_List = (
		--	SELECT L.COLUMN_NAME + ',' 
		--	FROM #TMP_Column_Name_List AS L
		--	ORDER BY L.ORDINAL_POSITION
		--	FOR XML PATH('')
		--)
		--SELECT @Fields_List = substring(@Fields_List, 1, len(@Fields_List) - 1)
	END
	ELSE BEGIN
		--если передан список полей
		INSERT @Fields_Table(Ordinal_Position, Field_Name)
		SELECT
			Ordinal_Position = row_number() OVER(ORDER BY getdate()),
			Field_Name = replace(replace(trim(S.value), ']', ''), '[', '')
		FROM string_split(@Fields_List, ',') AS S
		WHERE 1=1
			AND trim(isnull(S.value, '')) <> ''

	END

	--Добавить поле ID если его нет
	IF NOT EXISTS(SELECT 1 FROM @Fields_Table AS T WHERE T.Field_Name = 'ID')
	BEGIN
		INSERT @Fields_Table(Ordinal_Position, Field_Name)
		SELECT 0, 'ID'
	END

	-- проставить Source_Fields_id
	UPDATE F
	SET F.Source_Fields_id = S.Source_Fields_id
	FROM @Fields_Table AS F
		INNER JOIN @Source_Fields AS S
			ON S.Priority = 1
			AND S.COLUMN_NAME = F.Field_Name
	WHERE F.Source_Fields_id IS NULL -- не найденные на предыдущих шагах

	UPDATE F
	SET F.Source_Fields_id = S.Source_Fields_id
	FROM @Fields_Table AS F
		INNER JOIN @Source_Fields AS S
			ON S.Priority = 2
			AND S.COLUMN_NAME = F.Field_Name
	WHERE F.Source_Fields_id IS NULL -- не найденные на предыдущих шагах


	--ОШИБКА: В таблице @Return_Table_Name нет полей, имеющихся в таблицах-источниках
	--IF NOT EXISTS(SELECT * FROM @Fields_Table AS F WHERE F.Source_Fields_id IS NOT NULL)
	--BEGIN
	--	SELECT @Return_Message = (
	--			SELECT F.Field_Name + ', '
	--			FROM @Fields_Table AS F 
	--			WHERE F.Source_Fields_id IS NULL
	--			FOR XML
	--			PATH('')
	--		)

	--	SELECT @Return_Message = 'ОШИБКА: В таблице @Return_Table_Name нет полей, имеющихся в таблицах-источниках. Список полей: ' + 
	--		trim(substring(@Return_Message, 1, len(@Return_Message) - 1))
	--	SELECT @Return_Number = 1
	--	RETURN @Return_Number
	--END

	--check
	--SELECT * FROM @Fields_Table AS F ORDER BY F.Ordinal_Position
	--SELECT * FROM @Source_Fields AS S ORDER BY S.Priority, S.ORDINAL_POSITION
	--RETURN



	-- таблица-источник _LCRM.lcrm_leads_full_calculated
	DROP TABLE IF EXISTS #TMP_leads_full_calculated
	CREATE TABLE #TMP_leads_full_calculated
	(
		[ID] [numeric] (10, 0) NOT NULL,
		[DWHInsertedDate] [datetime] NOT NULL,
		[UF_PHONE] [varchar] (128) NULL,
		[PhoneNumber] [varchar] (20) NULL,
		[UF_ROW_ID] [varchar] (128) NULL,
		[UF_REGISTERED_AT_date] [date] NULL,
		[UF_UPDATED_AT_date] [date] NULL,
		[Тип-Источник] [nvarchar] (255) NULL,
		[CPA] [nvarchar] (255) NULL,
		[cpc] [nvarchar] (100) NULL,
		[Партнеры] [varchar] (31) NULL,
		[Органика] [nvarchar] (100) NULL,
		[Остальные1] [nvarchar] (35) NULL,
		[Представление] [varchar] (33) NULL,
		[Канал от источника] [nvarchar] (255) NULL,
		[Группа каналов] [nvarchar] (255) NULL,
		[DWH_HASH] [varbinary] (32) NOT NULL,
		UF_REGISTERED_AT datetime2 NULL,
		UF_TYPE varchar(128) NULL,
		UF_SOURCE varchar(128) NULL,
		UF_LOGINOM_STATUS varchar(128) NULL,
		UF_LOGINOM_PRIORITY int NULL,
		UF_LOGINOM_GROUP varchar(128) NULL,
		UF_LOGINOM_CHANNEL varchar(128) NULL,
		UF_UPDATED_AT datetime2 NULL,
		[DWHUpdatedDate] datetime
	)

	-- если надо брать данные из таблицы _LCRM.lcrm_leads_full_calculated
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM @Fields_Table AS F
			INNER JOIN @Source_Fields AS S
				ON S.Source_Fields_id = F.Source_Fields_id
		WHERE S.TABLE_SCHEMA = '_LCRM'
			AND S.TABLE_NAME = 'lcrm_leads_full_calculated'
			-- есть поля, кроме ID
			AND S.COLUMN_NAME <> 'ID'
	)
	BEGIN
		SELECT @get_from_calculated = 1

		IF EXISTS(
			SELECT S.COLUMN_NAME
			FROM @Source_Fields AS S
			WHERE S.TABLE_SCHEMA = '_LCRM'
				AND S.TABLE_NAME = 'lcrm_leads_full_calculated'
				AND NOT EXISTS(SELECT TOP(1) 1 FROM @Fields_Table AS F WHERE F.Source_Fields_id = S.Source_Fields_id)
				AND S.COLUMN_NAME <> 'ID'
		)
		BEGIN
			--удалить поля, которых нет в списке
			SELECT @Sql = (
				SELECT '[' + S.COLUMN_NAME + '],'
				FROM @Source_Fields AS S
				WHERE S.TABLE_SCHEMA = '_LCRM'
					AND S.TABLE_NAME = 'lcrm_leads_full_calculated'
					AND NOT EXISTS(SELECT TOP(1) 1 FROM @Fields_Table AS F WHERE F.Source_Fields_id = S.Source_Fields_id)
					AND S.COLUMN_NAME <> 'ID'
					
				ORDER BY S.ORDINAL_POSITION
				FOR XML PATH('')
			)

			SELECT @Sql = trim(substring(@Sql, 1, len(@Sql) - 1))
			SELECT @Sql = 'ALTER TABLE #TMP_leads_full_calculated DROP COLUMN IF EXISTS ' + @Sql
			if @Debug = 1
				print @Sql
			EXEC(@Sql)
		END
	    
		--check
		--SELECT @Sql
		--SELECT TOP(1) * FROM #TMP_leads_full_calculated AS D
		--RETURN
	END




	-- таблица-источник _LCRM.lcrm_leads_full
	DROP TABLE IF EXISTS #TMP_leads_full
	CREATE TABLE #TMP_leads_full
	(
		[ID] [numeric] (10, 0) NULL,
		[UF_NAME] [varchar] (512) NULL,
		[UF_PHONE] [varchar] (128) NULL,
		[UF_REGISTERED_AT] [datetime2] NULL,
		[UF_UPDATED_AT] [datetime2] NULL,
		[UF_ROW_ID] [varchar] (128) NULL,
		[UF_AGENT_NAME] [varchar] (128) NULL,
		[UF_STAT_CAMPAIGN] [varchar] (512) NULL,
		[UF_STAT_CLIENT_ID_YA] [varchar] (128) NULL,
		[UF_STAT_CLIENT_ID_GA] [varchar] (128) NULL,
		[UF_TYPE] [varchar] (128) NULL,
		[UF_SOURCE] [varchar] (128) NULL,
		[UF_STAT_AD_TYPE] [varchar] (128) NULL,
		[UF_ACTUALIZE_AT] [datetime2] NULL,
		[UF_CAR_MARK] [varchar] (128) NULL,
		[UF_CAR_MODEL] [varchar] (128) NULL,
		[UF_PHONE_ADD] [varchar] (128) NULL,
		[UF_PARENT_ID] [int] NULL,
		[UF_GROUP_ID] [varchar] (128) NULL,
		[UF_PRIORITY] [int] NULL,
		[UF_RC_REJECT_CM] [varchar] (512) NULL,
		[UF_APPMECA_TRACKER] [varchar] (128) NULL,
		[UF_LOGINOM_CHANNEL] [varchar] (128) NULL,
		[UF_LOGINOM_GROUP] [varchar] (128) NULL,
		[UF_LOGINOM_PRIORITY] [int] NULL,
		[UF_LOGINOM_STATUS] [varchar] (128) NULL,
		[UF_LOGINOM_DECLINE] [varchar] (128) NULL,
		[UF_STAT_SOURCE] [varchar] (128) NULL,
		[UF_FROM_SITE] [int] NULL,
		[UF_VIEWED] [int] NULL,
		[UF_PARTNER_ID] [nvarchar] (256) NULL,
		[UF_SUM_ACCEPTED] [float] NULL,
		[UF_SUM_LOAN] [float] NULL,
		[UF_REGIONS_COMPOSITE] [nvarchar] (128) NULL,
		[UF_ISSUED_AT] [datetime2] NULL,
		[UF_TARGET] [int] NULL,
		[UF_FULL_FORM_LEAD] [int] NULL,
		[UF_STEP] [int] NULL,
		[UF_SOURCE_SHADOW] [nvarchar] (128) NULL,
		[UF_TYPE_SHADOW] [nvarchar] (128) NULL,
		[UF_CLB_TYPE] [nvarchar] (128) NULL,
		[UF_CLID] [nvarchar] (72) NULL,
		[UF_MATCH_ALGORITHM] [nvarchar] (26) NULL,
		[UF_CLB_CHANNEL] [nvarchar] (50) NULL,
		[UF_LOAN_MONTH_COUNT] [int] NULL,
		[UF_STAT_SYSTEM] [nvarchar] (16) NULL,
		[UF_STAT_DETAIL_INFO] [nvarchar] (1236) NULL,
		[UF_STAT_TERM] [nvarchar] (1070) NULL,
		[UF_STAT_FIRST_PAGE] [nvarchar] (2032) NULL,
		[UF_STAT_INT_PAGE] [nvarchar] (1268) NULL,
		[UF_CLT_NAME_FIRST] [nvarchar] (128) NULL,
		[UF_CLT_BIRTH_DAY] [date] NULL,
		[UF_CLT_EMAIL] [nvarchar] (60) NULL,
		[UF_CLT_AVG_INCOME] [int] NULL,
		[UF_CAR_COST_RUB] [int] NULL,
		[UF_CAR_ISSUE_YEAR] [float] NULL,
		[UF_CLIENT_ID] [nvarchar] (255) NULL
	)

	-- если надо брать данные из таблицы-источника _LCRM.lcrm_leads_full
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM @Fields_Table AS F
			INNER JOIN @Source_Fields AS S
				ON S.Source_Fields_id = F.Source_Fields_id
		WHERE S.TABLE_SCHEMA = '_LCRM'
			AND S.TABLE_NAME = 'lcrm_leads_full'
	)
	BEGIN
		SELECT @get_from_full = 1

		IF EXISTS(
			SELECT S.COLUMN_NAME
			FROM @Source_Fields AS S
			WHERE S.TABLE_SCHEMA = '_LCRM'
				AND S.TABLE_NAME = 'lcrm_leads_full'
				AND NOT EXISTS(SELECT TOP(1) 1 FROM @Fields_Table AS F WHERE F.Source_Fields_id = S.Source_Fields_id)
				AND S.COLUMN_NAME <> 'ID'
		)
		BEGIN
			--удалить поля, которых нет в списке
			SELECT @Sql = (
				SELECT '[' + S.COLUMN_NAME + '],'
				FROM @Source_Fields AS S
				WHERE S.TABLE_SCHEMA = '_LCRM'
					AND S.TABLE_NAME = 'lcrm_leads_full'
					AND NOT EXISTS(SELECT TOP(1) 1 FROM @Fields_Table AS F WHERE F.Source_Fields_id = S.Source_Fields_id)
					AND S.COLUMN_NAME <> 'ID'
				ORDER BY S.ORDINAL_POSITION
				FOR XML PATH('')
			)

			SELECT @Sql = trim(substring(@Sql, 1, len(@Sql) - 1))
			SELECT @Sql = 'ALTER TABLE #TMP_leads_full DROP COLUMN IF EXISTS ' + @Sql

			--check
			--SELECT @Sql
			--SELECT TOP(1) * FROM #TMP_leads_full AS F
			--RETURN

			EXEC(@Sql)
		    
			--check
			--SELECT @Sql
			--SELECT TOP(1) * FROM #TMP_leads_full AS F
			--RETURN
		END
	END



	-- таблица со списком ID и номерами партиций
	-- заполнять только если @get_from_calculated = 1
	DROP TABLE IF EXISTS #lcrm_id
	--CREATE TABLE #lcrm_id(ID numeric(10,0), PartitionId int)
	--CREATE TABLE #lcrm_id(ID numeric(10,0), PartitionId int, UF_REGISTERED_AT datetime2)
	CREATE TABLE #lcrm_id(ID numeric(10,0), UF_REGISTERED_AT datetime2)

	DROP TABLE IF EXISTS #lcrm_id_Archive
	CREATE TABLE #lcrm_id_Archive(ID numeric(10,0), UF_REGISTERED_AT datetime2)


	-- таблица со списком ID и номерами партиций
	-- заполнять только если @get_from_calculated = 1
	--DROP TABLE IF EXISTS #lcrm_PartitionId
	--CREATE TABLE #lcrm_PartitionId(PartitionId int)


	------------------------------------------------------------------------------------------------------
	-- если надо брать данные из таблицы _LCRM.lcrm_leads_full_calculated
	------------------------------------------------------------------------------------------------------
	IF @get_from_calculated = 1
	BEGIN

		--IF @get_from_full = 1
		--BEGIN
		--	ALTER TABLE #TMP_leads_full_calculated
		--	ADD PartitionId int
		--END


		-- поля, которые есть в списке + поле ID
		SELECT @Sql2 = (
			SELECT '[' + S.COLUMN_NAME + '],'
			FROM @Source_Fields AS S
			WHERE S.TABLE_SCHEMA = '_LCRM'
				AND S.TABLE_NAME = 'lcrm_leads_full_calculated'
				AND (
					EXISTS(SELECT TOP(1) 1 FROM @Fields_Table AS F WHERE F.Source_Fields_id = S.Source_Fields_id)
					OR 
					S.COLUMN_NAME = 'ID'
				)
			ORDER BY S.ORDINAL_POSITION
			FOR XML PATH('')
		)
		SELECT @Sql2= trim(substring(@Sql2, 1, len(@Sql2) - 1))
		SELECT @Sql3 = replace(@Sql2, '[', 'D.[')
		SELECT @Sql = NULL

		IF @ID_Table_Name IS NOT NULL
		BEGIN
			--SELECT @Sql = 'INSERT #TMP_leads_full_calculated(' + @Sql2 + 
			--		iif(@get_from_full = 1,',PartitionId','') + ') ' + @c1310 +
			--	'SELECT ' + @Sql3 + 
			--		iif(@get_from_full = 1,',PartitionId = $PARTITION.pfn_range_right_date_part_lcrm_leads_full_calculated(D.UF_REGISTERED_AT_date)','') + @c1310 +
			--	'FROM _LCRM.lcrm_leads_full_calculated AS D (nolock)' + @c1310 +
			--	'WHERE EXISTS(SELECT TOP(1) 1 FROM ' + @ID_Table_Name + ' AS I WHERE I.ID = D.ID)' + @c1310 +
			--	'OPTION(USE HINT(''ENABLE_PARALLEL_PLAN_PREFERENCE''))'
			SELECT @Sql = 'INSERT #TMP_leads_full_calculated(' + @Sql2 + ') ' + @c1310 +
				'SELECT ' + @Sql3 + @c1310 +
				'FROM _LCRM.lcrm_leads_full_calculated AS D (nolock)' + @c1310 +
				'WHERE EXISTS(SELECT TOP(1) 1 FROM ' + @ID_Table_Name + ' AS I WHERE I.ID = D.ID)' + @c1310 +
				'OPTION(USE HINT(''ENABLE_PARALLEL_PLAN_PREFERENCE''))'
		END
		ELSE
		IF @Begin_Registered IS NOT NULL AND @End_Registered IS NOT NULL
		BEGIN
			--SELECT @Sql = 'INSERT #TMP_leads_full_calculated(' + @Sql2 + 
			--		iif(@get_from_full = 1,',PartitionId','') + ') ' + @c1310 +
			--	'SELECT ' + @Sql3 + 
			--		iif(@get_from_full = 1,',PartitionId = $PARTITION.pfn_range_right_date_part_lcrm_leads_full_calculated(D.UF_REGISTERED_AT_date)','') + @c1310 +
			--	'FROM _LCRM.lcrm_leads_full_calculated AS D (nolock)' + @c1310 +
			--	'WHERE D.UF_REGISTERED_AT BETWEEN ''' + 
			--		convert(varchar(10), @Begin_Registered, 120) + ''' AND ''' + 
			--		convert(varchar(10), @End_Registered, 120) + '''' + @c1310 +
			--	'OPTION(USE HINT(''ENABLE_PARALLEL_PLAN_PREFERENCE''))'
			SELECT @Sql = 'INSERT #TMP_leads_full_calculated(' + @Sql2 + ') ' + @c1310 +
				'SELECT ' + @Sql3 + @c1310 +
				'FROM _LCRM.lcrm_leads_full_calculated AS D (nolock)' + @c1310 +
				--'WHERE D.UF_REGISTERED_AT BETWEEN ''' + 
				--	convert(varchar(10), @Begin_Registered, 120) + ''' AND ''' + 
				--	convert(varchar(10), dateadd(DAY, 1, @End_Registered), 120) + '''' + @c1310 +
				'WHERE ''' + convert(varchar(10), @Begin_Registered, 120) +
					''' <= D.UF_REGISTERED_AT AND D.UF_REGISTERED_AT < ''' + 
					convert(varchar(10), dateadd(DAY, 1, @End_Registered), 120) + '''' + @c1310 +
				'OPTION(USE HINT(''ENABLE_PARALLEL_PLAN_PREFERENCE''))'
		END

		--check
		--SELECT @Sql2
		--SELECT @Sql
		--RETURN

		SELECT @StartDate = getdate(), @row_count = 0
		EXEC(@Sql)

		SELECT @row_count = @@ROWCOUNT
		IF @Debug = 1 BEGIN
			SELECT 'INSERT #TMP_leads_full_calculated', @row_count, datediff(SECOND, @StartDate, getdate())
		END

		--check
		--SELECT TOP(100) * FROM #TMP_leads_full_calculated

		IF @get_from_full = 1
		BEGIN
			SELECT @StartDate = getdate(), @row_count = 0

			--INSERT #lcrm_id(ID, PartitionId)
			--SELECT D.ID, D.PartitionId

			--INSERT #lcrm_id(ID, PartitionId, UF_REGISTERED_AT)
			--SELECT D.ID, D.PartitionId, D.UF_REGISTERED_AT
			--FROM #TMP_leads_full_calculated AS D

			INSERT #lcrm_id(ID, UF_REGISTERED_AT)
			SELECT D.ID, D.UF_REGISTERED_AT
			FROM #TMP_leads_full_calculated AS D

			SELECT @row_count = @@ROWCOUNT
			IF @Debug = 1 BEGIN
				SELECT 'INSERT #lcrm_id FROM #TMP_leads_full_calculated', @row_count, datediff(SECOND, @StartDate, getdate())
			END


			SELECT @StartDate = getdate(), @row_count = 0

			--INSERT #lcrm_PartitionId(PartitionId)
			--SELECT DISTINCT D.PartitionId
			--FROM #lcrm_id AS D

			--SELECT @row_count = @@ROWCOUNT
			--IF @Debug = 1 BEGIN
			--	SELECT 'INSERT #lcrm_PartitionId', @row_count, datediff(SECOND, @StartDate, getdate())
			--END
		END
	END
	--// если надо брать данные из таблицы _LCRM.lcrm_leads_full_calculated
	ELSE 
	IF @get_from_full = 1
	BEGIN
		--если надо брать данные из таблицы _LCRM.lcrm_leads_full
		------------------------------------------------------------------------------------------------------
		-- заполнить таблицу списком ID и номерами партиций
		------------------------------------------------------------------------------------------------------
		SELECT @StartDate = getdate(), @row_count = 0

		IF @ID_Table_Name IS NOT NULL
		BEGIN
			--SELECT @Sql = 
			--	'INSERT #lcrm_id(ID, PartitionId)' + @c1310 +
			--	'SELECT F.ID, PartitionId = $PARTITION.pfn_range_right_date_part_lcrm_leads_full_calculated(F.UF_REGISTERED_AT_date)' + @c1310 +
			--	'FROM _LCRM.lcrm_leads_full_calculated AS F (nolock)' + @c1310 +
			--	'WHERE EXISTS(SELECT TOP(1) 1 FROM ' + @ID_Table_Name + ' AS I WHERE I.ID = F.ID)'

			--SELECT @Sql = 
			--	'INSERT #lcrm_id(ID, PartitionId, UF_REGISTERED_AT)' + @c1310 +
			--	'SELECT F.ID, PartitionId = $PARTITION.pfn_range_right_date_part_lcrm_leads_full_calculated(F.UF_REGISTERED_AT_date), F.UF_REGISTERED_AT ' + @c1310 +
			--	'FROM _LCRM.lcrm_leads_full_calculated AS F (nolock)' + @c1310 +
			--	'WHERE EXISTS(SELECT TOP(1) 1 FROM ' + @ID_Table_Name + ' AS I WHERE I.ID = F.ID)'

			SELECT @Sql = 
				'INSERT #lcrm_id(ID, UF_REGISTERED_AT)' + @c1310 +
				'SELECT F.ID, F.UF_REGISTERED_AT ' + @c1310 +
				'FROM _LCRM.lcrm_leads_full_calculated AS F (nolock)' + @c1310 +
				'WHERE EXISTS(SELECT TOP(1) 1 FROM ' + @ID_Table_Name + ' AS I WHERE I.ID = F.ID)'
			EXEC(@Sql)
		END
		ELSE
		IF @Begin_Registered IS NOT NULL AND @End_Registered IS NOT NULL
		BEGIN
			--INSERT #lcrm_id(ID, PartitionId)
			--SELECT 
			--	F.ID,
			--	PartitionId = $PARTITION.pfn_range_right_date_part_lcrm_leads_full_calculated(F.UF_REGISTERED_AT_date)

			--INSERT #lcrm_id(ID, PartitionId, UF_REGISTERED_AT)
			--SELECT 
			--	F.ID,
			--	PartitionId = $PARTITION.pfn_range_right_date_part_lcrm_leads_full_calculated(F.UF_REGISTERED_AT_date),
			--	F.UF_REGISTERED_AT
			--FROM _LCRM.lcrm_leads_full_calculated AS F (nolock)
			--WHERE F.UF_REGISTERED_AT BETWEEN @Begin_Registered AND @End_Registered

			INSERT #lcrm_id(ID, UF_REGISTERED_AT)
			SELECT 
				F.ID,
				F.UF_REGISTERED_AT
			FROM _LCRM.lcrm_leads_full_calculated AS F (nolock)
			--WHERE F.UF_REGISTERED_AT BETWEEN @Begin_Registered AND dateadd(DAY, 1, @End_Registered)
			WHERE @Begin_Registered <= F.UF_REGISTERED_AT AND F.UF_REGISTERED_AT < dateadd(DAY, 1, @End_Registered)
		END

		SELECT @row_count = @@ROWCOUNT
		IF @Debug = 1 BEGIN
			SELECT 'INSERT #lcrm_id', @row_count, datediff(SECOND, @StartDate, getdate())
		END


		--SELECT @StartDate = getdate(), @row_count = 0

		--INSERT #lcrm_PartitionId(PartitionId)
		--SELECT DISTINCT D.PartitionId
		--FROM #lcrm_id AS D

		--SELECT @row_count = @@ROWCOUNT
		--IF @Debug = 1 BEGIN
		--	SELECT 'INSERT #lcrm_PartitionId', @row_count, datediff(SECOND, @StartDate, getdate())
		--END

		--check
		--SELECT TOP(100) T.* FROM #lcrm_id AS T
		--// заполнить таблицу списком ID и номерами партиций
	END


	------------------------------------------------------------------------------------------------------
	-- если надо брать данные из таблицы-источника _LCRM.lcrm_leads_full
	------------------------------------------------------------------------------------------------------
	IF @get_from_full = 1
	BEGIN
		--SELECT @StartDate = getdate(), @row_count = 0

		--CREATE INDEX IX_ID ON #lcrm_id(ID)
		CREATE INDEX IX_ID ON #lcrm_id(ID, UF_REGISTERED_AT)

		--SELECT @row_count = @@ROWCOUNT
		--IF @Debug = 1 BEGIN
		--	SELECT 'CREATE INDEX ON #lcrm_id', @row_count, datediff(SECOND, @StartDate, getdate())
		--END

		--check
		--SELECT TOP (100) * FROM #lcrm_id
		--SELECT TOP (100) * FROM #lcrm_PartitionId
		--RETURN

		-- поля, которые есть в списке + поле ID
		SELECT @Sql2 = (
			SELECT '[' + S.COLUMN_NAME + '],'
			FROM @Source_Fields AS S
			WHERE S.TABLE_SCHEMA = '_LCRM'
				AND S.TABLE_NAME = 'lcrm_leads_full'
				AND (
					EXISTS(SELECT TOP(1) 1 FROM @Fields_Table AS F WHERE F.Source_Fields_id = S.Source_Fields_id)
					OR 
					S.COLUMN_NAME = 'ID'
				)
			ORDER BY S.ORDINAL_POSITION
			FOR XML PATH('')
		)
		SELECT @Sql2= trim(substring(@Sql2, 1, len(@Sql2) - 1))
		SELECT @Sql3 = replace(@Sql2, '[', 'F.[')

		--SELECT @Sql = 'INSERT #TMP_leads_full(' + @Sql2 + ') ' + @c1310 +
		--	'SELECT ' + @Sql3 + @c1310 +
		--	'FROM _LCRM.lcrm_leads_full AS F (nolock)' + @c1310 +
		--	'WHERE EXISTS(' + @c1310 +
		--	'		SELECT TOP (1) 1' + @c1310 +
		--	'		FROM #lcrm_id AS b' + @c1310 +
		--	'		WHERE F.ID = b.id' + @c1310 +
		--	'			AND $PARTITION.pfn_range_right_date_part_lcrm_leads_full_calculated(F.UF_REGISTERED_AT) = b.PartitionId' + @c1310 +
		--	'	)' + @c1310 +
		--	'	AND $PARTITION.pfn_range_right_date_part_lcrm_leads_full_calculated(F.UF_REGISTERED_AT) IN (' + @c1310 +
		--	'		SELECT P.PartitionId ' + @c1310 +
		--	'		FROM #lcrm_PartitionId AS P' + @c1310 +
		--	'	)' + @c1310 +
		--	'OPTION(USE HINT(''ENABLE_PARALLEL_PLAN_PREFERENCE''))'

		SELECT @Sql = 'INSERT #TMP_leads_full(' + @Sql2 + ') ' + @c1310 +
			'SELECT ' + @Sql3 + @c1310 +
			'FROM _LCRM.lcrm_leads_full AS F (nolock)' + @c1310 +
			'WHERE EXISTS(' + @c1310 +
			'		SELECT TOP (1) 1' + @c1310 +
			'		FROM #lcrm_id AS b' + @c1310 +
			'		WHERE F.ID = b.id' + @c1310 +
			'			AND F.UF_REGISTERED_AT = b.UF_REGISTERED_AT' + @c1310 +
			'	)' + @c1310 +
			'OPTION(USE HINT(''ENABLE_PARALLEL_PLAN_PREFERENCE''))'

		--check
		--SELECT @Sql2
		--SELECT @Sql
		IF @Debug = 2 BEGIN
			DROP TABLE IF EXISTS ##TMP_leads_full
			SELECT * INTO ##TMP_leads_full FROM #TMP_leads_full

			DROP TABLE IF EXISTS ##lcrm_id
			SELECT * INTO ##lcrm_id FROM #lcrm_id
			
			--DROP TABLE IF EXISTS ##lcrm_PartitionId
			--SELECT * INTO ##lcrm_PartitionId FROM #lcrm_PartitionId

			SELECT @Sql
			--RETURN 0
		END

		SELECT @StartDate = getdate(), @row_count = 0

		EXEC(@Sql)

		SELECT @row_count = @@ROWCOUNT
		IF @Debug = 1 BEGIN
			SELECT 'INSERT #TMP_leads_full', @row_count, datediff(SECOND, @StartDate, getdate())
		END

		--данные из LcrmLeadArchive
		INSERT #lcrm_id_Archive(ID, UF_REGISTERED_AT)
		SELECT b.ID, b.UF_REGISTERED_AT 
		FROM #lcrm_id AS b
			LEFT JOIN #TMP_leads_full AS F
				ON F.ID = b.ID
		WHERE F.ID IS NULL

		CREATE INDEX IX_ID ON #lcrm_id_Archive(ID, UF_REGISTERED_AT)

		SELECT @Sql = 'INSERT #TMP_leads_full(' + @Sql2 + ') ' + @c1310 +
			'SELECT ' + @Sql3 + @c1310 +
			'FROM LcrmLeadArchive._LCRM.lcrm_leads_full AS F (nolock)' + @c1310 +
			'WHERE EXISTS(' + @c1310 +
			'		SELECT TOP (1) 1' + @c1310 +
			'		FROM #lcrm_id_Archive AS b' + @c1310 +
			'		WHERE F.ID = b.id' + @c1310 +
			'			AND F.UF_REGISTERED_AT = b.UF_REGISTERED_AT' + @c1310 +
			'	)' + @c1310 +
			'OPTION(USE HINT(''ENABLE_PARALLEL_PLAN_PREFERENCE''))'

		SELECT @StartDate = getdate(), @row_count = 0

		EXEC(@Sql)

		SELECT @row_count = @@ROWCOUNT
		IF @Debug = 1 BEGIN
			SELECT 'INSERT #TMP_leads_full from LcrmLeadArchive', @row_count, datediff(SECOND, @StartDate, getdate())
		END

	END
	--// если надо брать данные из таблицы-источника _LCRM.lcrm_leads_full



	------------------------------------------------------------------------------------------------------
	-- Выгрузка в таблицу @Return_Table_Name
	------------------------------------------------------------------------------------------------------
	-- Все поля из списка
	SELECT @Sql2 = (
		SELECT '[' + F.Field_Name + '],'
		FROM @Fields_Table AS F
		WHERE F.Source_Fields_id IS NOT NULL
		ORDER BY F.Ordinal_Position
		FOR XML PATH('')
	)
	SELECT @Sql2= trim(substring(@Sql2, 1, len(@Sql2) - 1))

	-- поля с алиасами
	SELECT @Sql3 = (
		SELECT 
			CASE 
				WHEN S.TABLE_SCHEMA = '_LCRM'
					AND S.TABLE_NAME = 'lcrm_leads_full_calculated'
					THEN 'D'
				WHEN S.TABLE_SCHEMA = '_LCRM'
					AND S.TABLE_NAME = 'lcrm_leads_full'
					THEN 'F'
				ELSE 'T' -- ??
			END
			+'.[' + F.Field_Name + '],'
		FROM @Fields_Table AS F
			INNER JOIN @Source_Fields AS S
				ON F.Source_Fields_id = S.Source_Fields_id
		ORDER BY F.Ordinal_Position
		FOR XML PATH('')
	)
	SELECT @Sql3= trim(substring(@Sql3, 1, len(@Sql3) - 1))
	--check
	--SELECT @Sql2, @Sql3

	CREATE INDEX IX_full_ID ON #TMP_leads_full(ID)
	CREATE INDEX IX_calculated_ID ON #TMP_leads_full_calculated(ID)

	-- данные из 2-х таблиц
	IF @get_from_full = 1 AND @get_from_calculated = 1
	BEGIN
		SELECT @Sql = 
			--'INSERT #TMP_leads_info(' + @Sql2 + ')' + @c1310 +
			'INSERT ' + @Return_Table_Name + '(' + @Sql2 + ')' + @c1310 +
			'SELECT ' + @Sql3 +  @c1310 +
			'FROM #TMP_leads_full AS F' + @c1310 +
			'	INNER JOIN #TMP_leads_full_calculated AS D' + @c1310 +
			'		ON F.ID = D.ID' + @c1310 +
			iif(@where IS NULL, '', 'WHERE '+ @where + @c1310) +
			'OPTION(USE HINT(''ENABLE_PARALLEL_PLAN_PREFERENCE''))'
		--check
		--SELECT @Sql

		SELECT @StartDate = getdate(), @row_count = 0

		EXEC(@Sql)

		SELECT @row_count = @@ROWCOUNT
		IF @Debug = 1 BEGIN
			--SELECT 'INSERT #TMP_leads_info', @row_count, datediff(SECOND, @StartDate, getdate())
			SELECT 'INSERT ' + @Return_Table_Name, @row_count, datediff(SECOND, @StartDate, getdate())
		END

		--check
		--SELECT TOP(100) A.* FROM #TMP_leads_info AS A

	END
	-- данные из 2-х таблиц


	-- данные только из таблицы full
	IF @get_from_full = 1 AND @get_from_calculated = 0
	BEGIN
		SELECT @Sql3 = replace(@Sql3, 'D.', 'F.')

		SELECT @Sql = 
			--'INSERT #TMP_leads_info(' + @Sql2 + ')' + @c1310 +
			'INSERT ' + @Return_Table_Name + '(' + @Sql2 + ')' + @c1310 +
			'SELECT ' + @Sql3 +  @c1310 +
			'FROM #TMP_leads_full AS F' + @c1310 +
			iif(@where IS NULL, '', 'WHERE '+ @where + @c1310) +
			'OPTION(USE HINT(''ENABLE_PARALLEL_PLAN_PREFERENCE''))'
		--check
		--SELECT @Sql

		SELECT @StartDate = getdate(), @row_count = 0

		EXEC(@Sql)

		SELECT @row_count = @@ROWCOUNT
		IF @Debug = 1 BEGIN
			--SELECT 'INSERT #TMP_leads_info', @row_count, datediff(SECOND, @StartDate, getdate())
			SELECT 'INSERT ' + @Return_Table_Name, @row_count, datediff(SECOND, @StartDate, getdate())
		END

		--check
		--SELECT TOP(100) A.* FROM #TMP_leads_info AS A

	END
	--// данные только из таблицы full


	-- данные только из таблицы calculated
	IF @get_from_full = 0 AND @get_from_calculated = 1
	BEGIN
		SELECT @Sql3 = replace(@Sql3, 'F.', 'D.')

		SELECT @Sql = 
			--'INSERT #TMP_leads_info(' + @Sql2 + ')' + @c1310 +
			'INSERT ' + @Return_Table_Name + '(' + @Sql2 + ')' + @c1310 +
			'SELECT ' + @Sql3 +  @c1310 +
			'FROM #TMP_leads_full_calculated AS D' + @c1310 +
			iif(@where IS NULL, '', 'WHERE '+ @where + @c1310) +
			'OPTION(USE HINT(''ENABLE_PARALLEL_PLAN_PREFERENCE''))'
		--check
		--SELECT @Sql

		SELECT @StartDate = getdate(), @row_count = 0

		EXEC(@Sql)

		SELECT @row_count = @@ROWCOUNT
		IF @Debug = 1 BEGIN
			--SELECT 'INSERT #TMP_leads_info', @row_count, datediff(SECOND, @StartDate, getdate())
			SELECT 'INSERT ' + @Return_Table_Name, @row_count, datediff(SECOND, @StartDate, getdate())
		END

		--check
		--SELECT TOP(100) A.* FROM #TMP_leads_info AS A

	END
	--// данные только из таблицы calculated

	SELECT @Return_Message = 'Заполнена таблица ' + @Return_Table_Name + '. Количество записей: ' + convert(varchar(10), @row_count)

	RETURN @Return_Number

END TRY
BEGIN CATCH
	IF xact_state() <> 0 BEGIN
		ROLLBACK TRANSACTION
	END
	
	SELECT @ErrorNumber = error_number(), @ErrorSeverity = error_severity(), @ErrorState  = error_state()
	SELECT @Error_Procedure = error_procedure(), @Error_Line = ERROR_LINE()
	SELECT @ErrorMessage = isnull(error_message(), 'Сообщение не определенно') + @c1310 +
		'[' + 'Процедура ' + isnull(@Error_Procedure, 'не определена') + 
		', Строка '+isnull(convert(varchar(20), @Error_Line), 'не определена') + ']'

	--SELECT @Return_Number = 2, @Return_Message = @ErrorMessage

	RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)

	--RETURN @Return_Number
END CATCH


END
