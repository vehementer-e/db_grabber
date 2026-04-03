/*
exec etl.CompareReplicationMetaData_PROD
	--@sourceDbName = 'collection',
	@sourceDbName = 'Fedor.Core',
	@isDebug = 1 
	select * from etl.ConfigDataBaseForCompare
exec etl.CompareReplicationMetaData_PROD
	@sourceDBMSType		= 'MsSql'
	,@sourceDbName		= 'SmartHorizon'
	,@sourceTblName		= 'dbo.Справочник_Контрагенты'
	,@targetTableName	= '_1cSH.Справочник_Контрагенты'
	,@isScript			= 1
	,@isSendMail		= 	
	,@isDebug			= 
*/
CREATE PROC etl.CompareReplicationMetaData_PROD
	@sourceDBMSType		nvarchar(255) = NULL,
	@sourceDbName		nvarchar(255) = NULL,
	@sourceTblName		nvarchar(255) = NULL,
	@targetTableName	nvarchar(255) = NULL,
	@isScript			int = 1,
	@isSendMail			int = 0,
	@isDebug			int = 0 
as
begin
set nocount on
set @sourceTblName = TRIM(@sourceTblName)
set @targetTableName = TRIM(@targetTableName)
SELECT @isScript = isnull(@isScript, 1)
SELECT @isSendMail = isnull(@isSendMail, 0)
SELECT @isDebug = isnull(@isDebug, 0)

--DECLARE @SourceDataBase nvarchar(255), @SourceServer nvarchar(255)
DECLARE @SourceDataBase nvarchar(255), @SourceColumnsTable nvarchar(255)
declare @cmd nvarchar(max)
DECLARE @html_table nvarchar(max) = '', @html_table1 nvarchar(max) = '', 
	@html_table2 nvarchar(max) = '', @html_table3 nvarchar(max) = ''
declare @recipients nvarchar(1024)
declare @tsql nvarchar(max), @subject nvarchar(1024), @body nvarchar(max) 
DECLARE @description nvarchar(1024), @message nvarchar(1024), @error_number int
DECLARE @subject_error nvarchar(1024)
declare @script_add nvarchar(max), @script_alter nvarchar(max), @script_alter_upd nvarchar(max)
declare @script_min_row nvarchar(max), @script_search nvarchar(max), @script_upd_pv nvarchar(max)
declare @SourceTableName nvarchar(255)
declare @isCreateTable int = 0
declare @newLineChar AS CHAR(2) = CHAR(13) + CHAR(10)

BEGIN try

	SELECT  @recipients=isnull([emails],'')
	from    LogDb.dbo.Emails
	where 	[loggerName] ='adminlog'    

	DROP table if exists #t_etlTables

	create table  #t_etlTables (
		SourceDBMSType nvarchar(255), 
		SourceDataBase nvarchar(255), 
		SourceTableName nvarchar(255), 
		TargetTableScheme nvarchar(255),
		TargetTableName nvarchar(255),
		--SourceServer nvarchar(255),
		--SourceDataBaseForCompare nvarchar(255),
		--SourceServerForCompare nvarchar(255),
		SourceColumnsTable nvarchar(255),
		ExcludeColumns nvarchar(max)
	)

	INSERT into #t_etlTables
	(
		SourceDBMSType,
		SourceDataBase,
		SourceTableName,
		TargetTableScheme,
		TargetTableName,
		--SourceServer,
		--SourceDataBaseForCompare,
		--SourceServerForCompare,
		SourceColumnsTable,
		ExcludeColumns
	)
	select 
		SourceDBMSType,
		SourceDataBase,
		SourceTableName,
		TargetTableSchema = TRIM(SUBSTRING(TargetTableName, 0, CHARINDEX('.', TargetTableName))),
		TargetTableName,
		--SourceServer,
		--SourceDataBaseForCompare,
		--SourceServerForCompare,
		SourceColumnsTable,
		ExcludeColumns
	
	from (
		select distinct 
			T.SourceDBMSType,
			T.SourceDataBase 
			,T.SourceTableName
			,T.TargetTableName
			--,T.SourceServer 

			--,C.SourceDataBaseForCompare
			--,C.SourceServerForCompare
			,C.SourceColumnsTable
			--,T.ExcludeColumns
			,ExcludeColumns = replace(replace(T.ExcludeColumns,char(13),''),char(10),'')
			--select *
		from etl.V_TablesForReplication AS T
			INNER JOIN etl.ConfigDataBaseForCompare AS C
				ON C.SourceDataBase = T.SourceDataBase
				AND C.isActive = 1
		where 1=1
			--AND T.SourceDBMSType = 'MsSQL'
			AND (@sourceDbName IS NULL OR T.SourceDataBase = @sourceDbName)
			and (@targetTableName IS NULL OR T.TargetTableName = @targetTableName)
	) A
	WHERE A.SourceColumnsTable IS NOT NULL

	--новая таблица
	if @targetTableName IS not NULL
		and not exists(select * from #t_etlTables)
	begin
		INSERT into #t_etlTables
		(
			SourceDBMSType,
			SourceDataBase,
			SourceTableName,
			TargetTableScheme,
			TargetTableName,
			--SourceServer,
			--SourceDataBaseForCompare,
			--SourceServerForCompare,
			SourceColumnsTable,
			ExcludeColumns
		)
		select 
			SourceDBMSType,
			SourceDataBase,
			SourceTableName,
			TargetTableSchema = TRIM(SUBSTRING(TargetTableName, 0, CHARINDEX('.', TargetTableName))),
			TargetTableName,
			--SourceServer,
			--SourceDataBaseForCompare,
			--SourceServerForCompare,
			SourceColumnsTable,
			ExcludeColumns
	
		from (
			select distinct 
				T.SourceDBMSType,
				T.SourceDataBase 
				,T.SourceTableName
				,T.TargetTableName
				--,T.SourceServer 

				--,C.SourceDataBaseForCompare
				--,C.SourceServerForCompare
				,C.SourceColumnsTable
				--,T.ExcludeColumns
				,ExcludeColumns = replace(replace(T.ExcludeColumns,char(13),''),char(10),'')
				--select *
			from (
				select 
				SourceDBMSType = @sourceDBMSType
				,SourceDataBase = @sourceDbName 
				,SourceTableName = @sourceTblName
				,TargetTableName = @targetTableName
				,ExcludeColumns = cast(null as varchar(100))
				) AS T
				--etl.V_TablesForReplication 
				
				INNER JOIN etl.ConfigDataBaseForCompare AS C
					ON C.SourceDataBase = T.SourceDataBase
					AND C.isActive = 1
		) A
		WHERE A.SourceColumnsTable IS NOT NULL

		if exists(select * from #t_etlTables) begin
			select @isCreateTable = 1
		end
	end


	IF @isDebug = 1 BEGIN
		select concat('@isCreateTable=', @isCreateTable)

		DROP TABLE IF EXISTS ##t_etlTables
		SELECT * INTO ##t_etlTables FROM #t_etlTables
	END

	if @targetTableName is not null
	begin
		if exists(select * from #t_etlTables) 
		begin
			select @sourceDbName = (select top 1 T.SourceDataBase from #t_etlTables as T)
		end

		BEGIN TRAN
			delete c
			from etl.ColumnsForReplication as c
			where c.fullTableName = @targetTableName

			INSERT etl.ColumnsForReplication
			(
				fullTableName,
				ORDINAL_POSITION,
				COLUMN_NAME,
				DATA_TYPE,
				CHARACTER_MAXIMUM_LENGTH,
				NUMERIC_PRECISION,
				NUMERIC_PRECISION_RADIX,
				NUMERIC_SCALE,
				DATETIME_PRECISION,
				COLLATION_NAME
			)
			SELECT 
				fullTableName,
				ORDINAL_POSITION,
				COLUMN_NAME,
				DATA_TYPE,
				CHARACTER_MAXIMUM_LENGTH,
				NUMERIC_PRECISION,
				NUMERIC_PRECISION_RADIX,
				NUMERIC_SCALE,
				DATETIME_PRECISION,
				COLLATION_NAME
			FROM etl.v_ColumnsForReplication as v
			where v.fullTableName = @targetTableName
		COMMIT
	end
	/*
	else begin
		BEGIN TRAN
			TRUNCATE TABLE etl.ColumnsForReplication

			INSERT etl.ColumnsForReplication
			(
				fullTableName,
				ORDINAL_POSITION,
				COLUMN_NAME,
				DATA_TYPE,
				CHARACTER_MAXIMUM_LENGTH,
				NUMERIC_PRECISION,
				NUMERIC_PRECISION_RADIX,
				DATETIME_PRECISION,
				COLLATION_NAME
			)
			SELECT 
				fullTableName,
				ORDINAL_POSITION,
				COLUMN_NAME,
				DATA_TYPE,
				CHARACTER_MAXIMUM_LENGTH,
				NUMERIC_PRECISION,
				NUMERIC_PRECISION_RADIX,
				DATETIME_PRECISION,
				COLLATION_NAME
			FROM etl.v_ColumnsForReplication
		COMMIT
		--00:00:04
	end --/@targetTableName is null
	*/



	drop table if exists #t_targetInformation

	select
		C.fullTableName
		,C.ORDINAL_POSITION
		,C.COLUMN_NAME
		,C.DATA_TYPE
		,CHARACTER_MAXIMUM_LENGTH = cast(C.CHARACTER_MAXIMUM_LENGTH AS bigint)
		,C.NUMERIC_PRECISION	
		,C.NUMERIC_PRECISION_RADIX
		,C.NUMERIC_SCALE
		,C.DATETIME_PRECISION
		,C.COLLATION_NAME
	into #t_targetInformation
	--select top 100 *
	from etl.ColumnsForReplication AS C --Stg.INFORMATION_SCHEMA.COLUMNS
	where 1=1
		AND fullTableName in (Select DISTINCT TargetTableName from #t_etlTables)
		and COLUMN_NAME not in ('DWHInsertedDate', 'ProcessGUID')


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_targetInformation
		SELECT * INTO ##t_targetInformation FROM #t_targetInformation
	END

	set @subject = concat(
		'Сравнение структур загружаемых таблиц с PROD контурами. ',
		iif(@sourceDbName IS NOT NULL,concat('БД: ',@sourceDbName,'. '),''),
		iif(@targetTableName IS NOT NULL,concat('Таблица: ',@targetTableName,'. '),''),
		format(getdate(), 'dd.MM.yyyy HH:mm:ss')
	)

	drop table if exists #t_sourceInformation
	create table #t_sourceInformation
	(
		SourceDataBase nvarchar(255)
		,fullTableName nvarchar(255)
		,ORDINAL_POSITION int
		,COLUMN_NAME nvarchar(255)
		,DATA_TYPE	nvarchar(255)
		,CHARACTER_MAXIMUM_LENGTH bigint
		,NUMERIC_PRECISION int
		,NUMERIC_PRECISION_RADIX int
		,NUMERIC_SCALE int
		,DATETIME_PRECISION int
		,COLLATION_NAME nvarchar(255)
	)

	--1 MsSQL
	DECLARE cur_source CURSOR FOR
	SELECT DISTINCT
		--SourceServer = concat('[', SourceServerForCompare, ']'),
		--SourceDataBase = concat('[',T.SourceDataBaseForCompare, ']')
		T.SourceDataBase,
		T.SourceColumnsTable
	from #t_etlTables AS T
	WHERE T.SourceDBMSType = 'MsSQL'
	ORDER BY SourceColumnsTable --SourceServer, SourceDataBase

	OPEN cur_source
	FETCH NEXT FROM cur_source INTO @SourceDataBase, @SourceColumnsTable

	WHILE @@FETCH_STATUS = 0
	BEGIN

		SELECT @cmd = concat('
insert #t_sourceInformation
select 
	SourceDataBase = ''', @SourceDataBase, '''
	,fullTableName = concat(A.TABLE_SCHEMA, ''.'', A.TABLE_NAME)
	,A.ORDINAL_POSITION
	,A.COLUMN_NAME
	,A.DATA_TYPE	
	,A.CHARACTER_MAXIMUM_LENGTH
	,A.NUMERIC_PRECISION	
	,NUMERIC_PRECISION_RADIX = isnull(A.NUMERIC_PRECISION_RADIX, A.NUMERIC_SCALE)
	,A.NUMERIC_SCALE
	,A.DATETIME_PRECISION
	,A.COLLATION_NAME
from ', @SourceColumnsTable, ' AS A')

		--IF @isDebug = 1 BEGIN
		--	SELECT @cmd
		--END

		BEGIN TRY
			--insert into #t_sourceInformation
			EXEC (@cmd)
		END TRY 
		BEGIN CATCH
			SELECT @subject_error = concat('ERROR.', @subject)

			SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
				+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
				+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')

			set @body = concat(
				'<H1>', @subject_error, '</H1><br><br>', @description
			)

			if trim(@recipients) <>''
			begin 
		
				-- select @tsql 
				IF @isDebug = 1 BEGIN
					SELECT @subject_error
					SELECT @html_table
					SELECT @body
				END
				ELSE BEGIN
					EXEC msdb.dbo.sp_send_dbmail  
					@profile_name = 'Default',  
					@recipients = @recipients,  
					@body = @body,  
					@body_format='HTML', 
					@subject = @subject_error 
				; 
				 END
			end
		END CATCH

		FETCH NEXT FROM cur_source INTO @SourceDataBase, @SourceColumnsTable
	END

	CLOSE cur_source
	DEALLOCATE cur_source


	--2 MySQL
	DECLARE cur_source_MySQL CURSOR FOR
	SELECT DISTINCT
		--SourceServer = concat('[', SourceServerForCompare, ']'),
		--SourceDataBase = concat('[',T.SourceDataBaseForCompare, ']')
		T.SourceDataBase,
		T.SourceColumnsTable
	from #t_etlTables AS T
	WHERE T.SourceDBMSType = 'MySQL'
	ORDER BY T.SourceColumnsTable

	OPEN cur_source_MySQL
	FETCH NEXT FROM cur_source_MySQL INTO @SourceDataBase, @SourceColumnsTable

	WHILE @@FETCH_STATUS = 0
	BEGIN

		SELECT @cmd = concat('
insert #t_sourceInformation
select 
	SourceDataBase = ''', @SourceDataBase, '''
	,fullTableName = A.TABLE_NAME
	,ORDINAL_POSITION = A.ORDINAL_POSITION
	,COLUMN_NAME = A.COLUMN_NAME
	,DATA_TYPE = A.DATA_TYPE
	,CHARACTER_MAXIMUM_LENGTH = A.CHARACTER_MAXIMUM_LENGTH
	,NUMERIC_PRECISION = A.NUMERIC_PRECISION
	,NUMERIC_PRECISION_RADIX = A.NUMERIC_SCALE
	,NUMERIC_SCALE = A.NUMERIC_SCALE
	,DATETIME_PRECISION = NULL
	,COLLATION_NAME = NULL
from ', @SourceColumnsTable, ' AS A')

		--IF @isDebug = 1 BEGIN
		--	SELECT @cmd
		--	--RETURN 0
		--END

		BEGIN TRY
			--insert into #t_sourceInformation
			EXEC (@cmd)
		END TRY
		BEGIN CATCH
			SELECT @subject_error = concat('ERROR.', @subject)

			SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
				+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
				+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')

			set @body = concat(
				'<H1>', @subject_error, '</H1><br><br>', @description
			)

			if trim(@recipients) <>''
			begin 
				-- select @tsql 
				IF @isDebug = 1 BEGIN
					SELECT @subject_error
					SELECT @html_table
					SELECT @body
				END
				ELSE BEGIN
					EXEC msdb.dbo.sp_send_dbmail  
					@profile_name = 'Default',  
					@recipients = @recipients,  
					@body = @body,  
					@body_format='HTML', 
					@subject = @subject_error;
				 END
			end
		END CATCH

		FETCH NEXT FROM cur_source_MySQL INTO @SourceDataBase, @SourceColumnsTable
	END

	CLOSE cur_source_MySQL
	DEALLOCATE cur_source_MySQL


	--IF @isDebug = 1 BEGIN
	--	RETURN 0
	--END



	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_sourceInformation
		SELECT * INTO ##t_sourceInformation FROM #t_sourceInformation
	END

	DROP TABLE IF EXISTS #t_drop_column

	--1. в таблице на PROD удалили колонку, и этой  колонки нет в ExcludeColumns
	select distinct 
		et.TargetTableName,
		et.SourceTableName,
		Source_COLUMN_NAME = st.COLUMN_NAME,
		Target_COLUMN_NAME = tt.COLUMN_NAME,
		et.ExcludeColumns
	INTO #t_drop_column
	from #t_etlTables AS et
		LEFT join #t_targetInformation AS tt
			ON tt.fullTableName = et.TargetTableName COLLATE SQL_Latin1_General_CP1_CI_AS
		LEFT join #t_sourceInformation AS st 
			ON st.SourceDataBase = et.SourceDataBase
			AND st.fullTableName = et.SourceTableName COLLATE SQL_Latin1_General_CP1_CI_AS
			AND tt.COLUMN_NAME = st.COLUMN_NAME COLLATE SQL_Latin1_General_CP1_CI_AS
	where st.COLUMN_NAME is NULL
		and tt.COLUMN_NAME not in (
			SELECT val = trim(S.value)
			FROM string_split(et.ExcludeColumns,',') AS S
			--FROM string_split(replace(replace(et.ExcludeColumns,char(13),''),char(10),''),',') AS S
			)
		AND NOT (
			et.TargetTableName IN (
				'_fedor.core_UserAndUserRole',
				'_fedorPROD.core_UserAndUserRole',
				'_fedorUAT.core_UserAndUserRole')
			AND tt.COLUMN_NAME IN ('deleted_at')
			OR 
			et.TargetTableName IN ('_1cCMR.РегистрСведений_АктуальностьДанныхДляDWH')
			AND tt.COLUMN_NAME IN ('isArchive')
			OR 
			et.TargetTableName IN ('_cdr.call_obhod')
			AND tt.COLUMN_NAME IN ('CreatedAt')
		)
	ORDER BY et.TargetTableName, tt.COLUMN_NAME

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_drop_column
		SELECT * INTO ##t_drop_column FROM #t_drop_column
	END

	--Для Target_COLUMN_NAME использовать STRING_AGG так чтобы была одна строка = одна таблица
	DROP TABLE IF EXISTS #t_drop_column_group
	SELECT 
		D.TargetTableName,
		D.SourceTableName,
		D.Source_COLUMN_NAME,
		--D.Target_COLUMN_NAME,
		Target_COLUMN_NAME = 
		string_agg(cast(D.Target_COLUMN_NAME AS varchar(max)),',')
			WITHIN GROUP (ORDER BY D.Target_COLUMN_NAME),
		D.ExcludeColumns
	INTO #t_drop_column_group
	FROM #t_drop_column AS D
	GROUP BY
		D.TargetTableName,
		D.SourceTableName,
		D.Source_COLUMN_NAME,
		D.ExcludeColumns

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_drop_column_group
		SELECT * INTO ##t_drop_column_group FROM #t_drop_column_group
	END

	--2. Изменилась размерность поля на PROD
	--3. Изменился тип данных в поле таблицы
	DROP TABLE IF EXISTS #t_change_column

	select distinct 
		et.TargetTableName,
		et.SourceTableName,
		Source_COLUMN_NAME = st.COLUMN_NAME,
		Source_DATA_TYPE = st.DATA_TYPE,
		Source_CHARACTER_MAXIMUM_LENGTH = st.CHARACTER_MAXIMUM_LENGTH,
		Source_NUMERIC_PRECISION = st.NUMERIC_PRECISION,
		Source_NUMERIC_PRECISION_RADIX = st.NUMERIC_PRECISION_RADIX,
		Source_DATETIME_PRECISION = st.DATETIME_PRECISION,

		Target_COLUMN_NAME = tt.COLUMN_NAME,
		Target_DATA_TYPE = tt.DATA_TYPE,
		Target_CHARACTER_MAXIMUM_LENGTH = tt.CHARACTER_MAXIMUM_LENGTH,
		Target_NUMERIC_PRECISION = tt.NUMERIC_PRECISION,
		Target_NUMERIC_PRECISION_RADIX = tt.NUMERIC_PRECISION_RADIX,
		Target_DATETIME_PRECISION = tt.DATETIME_PRECISION
	INTO #t_change_column
	from #t_etlTables AS et
		LEFT join #t_targetInformation AS tt
			ON tt.fullTableName = et.TargetTableName COLLATE SQL_Latin1_General_CP1_CI_AS
		LEFT join #t_sourceInformation AS st 
			ON st.SourceDataBase = et.SourceDataBase
			AND st.fullTableName = et.SourceTableName COLLATE SQL_Latin1_General_CP1_CI_AS
			AND tt.COLUMN_NAME = st.COLUMN_NAME COLLATE SQL_Latin1_General_CP1_CI_AS
	where 1=1
		AND (
			--типы разные
			st.DATA_TYPE <> tt.DATA_TYPE

			OR (
				--символьные типы совпадают, и размер на источнике больше
				st.DATA_TYPE = tt.DATA_TYPE
				AND st.DATA_TYPE IN ('char','nchar','varchar','nvarchar')
				AND st.CHARACTER_MAXIMUM_LENGTH > tt.CHARACTER_MAXIMUM_LENGTH
				AND tt.CHARACTER_MAXIMUM_LENGTH <>-1
			)
			--OR (
			--	--насчет varchar и nvarchar лучше чтобы nvarchar был в 2 раза больше
			--	(st.DATA_TYPE = 'varchar' AND tt.DATA_TYPE = 'nvarchar')
			--	AND 2 * cast(st.CHARACTER_MAXIMUM_LENGTH AS bigint) > cast(tt.CHARACTER_MAXIMUM_LENGTH AS bigint)
			--	AND tt.CHARACTER_MAXIMUM_LENGTH <> -1
			--)
		)
		--исключения
		AND NOT st.COLUMN_NAME IN ('ВерсияДанных', 'RowVersion', 'fRowVersion')
		AND NOT (
				--насчет varchar и nvarchar лучше чтобы nvarchar был в 2 раза больше
				(st.DATA_TYPE = 'varchar' AND tt.DATA_TYPE = 'nvarchar')
				AND (
					2 * cast(st.CHARACTER_MAXIMUM_LENGTH AS bigint) < cast(tt.CHARACTER_MAXIMUM_LENGTH AS bigint)
					OR tt.CHARACTER_MAXIMUM_LENGTH <> -1
					)
		)
		AND NOT (
			st.DATA_TYPE IN ('ntext','varchar','text','mediumtext') 
				AND tt.DATA_TYPE IN ('varchar','nvarchar') AND tt.CHARACTER_MAXIMUM_LENGTH = -1
			OR st.DATA_TYPE IN ('image') AND tt.DATA_TYPE IN ('varbinary') AND tt.CHARACTER_MAXIMUM_LENGTH = -1
			OR st.DATA_TYPE IN ('varbinary')
				AND tt.DATA_TYPE IN ('varbinary','varchar','nvarchar') AND tt.CHARACTER_MAXIMUM_LENGTH = -1
		)
		AND NOT (
			st.DATA_TYPE IN ('int','tinyint','smallint') AND tt.DATA_TYPE IN ('bigint') 
			OR st.DATA_TYPE IN ('tinyint','smallint') AND tt.DATA_TYPE IN ('int') 
			OR st.DATA_TYPE IN ('timestamp') AND tt.DATA_TYPE IN ('binary') AND tt.CHARACTER_MAXIMUM_LENGTH >= 8
			
		)
		AND NOT (
			st.DATA_TYPE IN ('decimal', 'numeric') AND tt.DATA_TYPE IN ('decimal', 'numeric', 'money', 'smallmoney')
			AND st.NUMERIC_PRECISION <= tt.NUMERIC_PRECISION 
			AND st.NUMERIC_PRECISION_RADIX <= tt.NUMERIC_PRECISION_RADIX
		)
		AND NOT (
			st.DATA_TYPE IN ('double') AND tt.DATA_TYPE IN ('money')
		)
		AND NOT (
			st.DATA_TYPE = 'nchar' AND tt.DATA_TYPE = 'nvarchar' 
			AND st.CHARACTER_MAXIMUM_LENGTH <= tt.CHARACTER_MAXIMUM_LENGTH
		)
		AND NOT (
			st.DATA_TYPE IN ('varbinary', 'binary') AND tt.DATA_TYPE IN ('varbinary', 'binary')
			AND st.CHARACTER_MAXIMUM_LENGTH <= tt.CHARACTER_MAXIMUM_LENGTH
		)
		AND NOT (
			st.DATA_TYPE IN ('datetime2') AND tt.DATA_TYPE IN ('datetime')
			AND st.DATETIME_PRECISION = 0
		)
		--если у нас datetime2, а в источнике datetime такое игнорировать
		AND NOT (st.DATA_TYPE = 'datetime' AND tt.DATA_TYPE = 'datetime2')
		--если у нас varchar, а в источнике char такое игнорировать.
		AND NOT (st.DATA_TYPE = 'char' AND tt.DATA_TYPE = 'varchar'
			AND st.CHARACTER_MAXIMUM_LENGTH = tt.CHARACTER_MAXIMUM_LENGTH
		)
		AND NOT (
			st.COLUMN_NAME IN ('dpd')
			AND tt.DATA_TYPE IN ('smallint')
		)

		AND NOT (
			et.SourceDBMSType = 'MySQL'
			AND st.DATA_TYPE IN ('char','varchar','enum') AND tt.DATA_TYPE IN ('char', 'nchar', 'nvarchar')
			AND st.CHARACTER_MAXIMUM_LENGTH <= tt.CHARACTER_MAXIMUM_LENGTH
		)
		AND NOT (
			et.SourceDBMSType = 'MySQL'
			AND (
				st.DATA_TYPE IN ('tinyint') AND tt.DATA_TYPE IN ('int','smallint')
				OR st.DATA_TYPE IN ('int','tinyint','decimal') AND tt.DATA_TYPE IN ('numeric','real')
				OR st.DATA_TYPE IN ('timestamp') AND tt.DATA_TYPE IN ('datetime', 'datetime2')
				OR st.DATA_TYPE IN ('tinyint') AND tt.DATA_TYPE IN ('bit')
			)
		)
		AND NOT (
			et.SourceDBMSType = 'MySQL'
			AND (
				st.DATA_TYPE IN ('text','json','longtext') AND tt.DATA_TYPE IN ('varchar','nvarchar')
				AND tt.CHARACTER_MAXIMUM_LENGTH = -1
			)
		)
		AND NOT (
			et.SourceDBMSType = 'MySQL'
			AND (
				st.DATA_TYPE IN ('enum') AND tt.DATA_TYPE IN ('varchar','nvarchar')
				AND st.CHARACTER_MAXIMUM_LENGTH <= tt.CHARACTER_MAXIMUM_LENGTH
			)
		)
		AND NOT (
			et.SourceDBMSType = 'MySQL'
			AND (
				st.DATA_TYPE IN ('int','bigint') AND tt.DATA_TYPE IN ('varchar','nvarchar')
				AND tt.CHARACTER_MAXIMUM_LENGTH >= 20
			)
		)
	ORDER BY et.TargetTableName, tt.COLUMN_NAME


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_change_column
		SELECT * INTO ##t_change_column FROM #t_change_column
	END



	--4. Новые поля в источнике
	DROP TABLE IF EXISTS #t_new_column

	SELECT distinct 
		et.TargetTableName,
		et.SourceTableName,
		Source_ORDINAL_POSITION = st.ORDINAL_POSITION,
		Source_COLUMN_NAME = st.COLUMN_NAME,
		--Target_COLUMN_NAME = tt.COLUMN_NAME,
		st.DATA_TYPE,
		st.CHARACTER_MAXIMUM_LENGTH,
		st.NUMERIC_PRECISION,
		st.NUMERIC_PRECISION_RADIX,
		st.NUMERIC_SCALE,
		st.DATETIME_PRECISION,
		st.COLLATION_NAME
	INTO #t_new_column
	from #t_etlTables AS et
		LEFT join #t_sourceInformation AS st
			ON st.SourceDataBase = et.SourceDataBase
			AND st.fullTableName = et.SourceTableName COLLATE SQL_Latin1_General_CP1_CI_AS
		LEFT join #t_targetInformation AS tt
			ON tt.fullTableName = et.TargetTableName COLLATE SQL_Latin1_General_CP1_CI_AS
			AND tt.COLUMN_NAME = st.COLUMN_NAME COLLATE SQL_Latin1_General_CP1_CI_AS
	where tt.COLUMN_NAME is null
	and st.COLUMN_NAME is not null
	--and st.COLUMN_NAME like 'версия%'


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_new_column
		SELECT * INTO ##t_new_column FROM #t_new_column
	END



	--SELECT * 
	--FROM #t_drop_column AS T
	--ORDER BY T.TargetTableName, T.Target_COLUMN_NAME

	IF @isDebug = 1 BEGIN
		SELECT '1. В таблице на PROD удалили колонку, и этой  колонки нет в ExcludeColumns (#t_drop_column_group)'
		SELECT * 
		FROM #t_drop_column_group AS T
		ORDER BY T.TargetTableName, T.Target_COLUMN_NAME

		SELECT '2. В таблице на PROD изменился тип данных или размерность поля (#t_change_column)'
		SELECT * 
		FROM #t_change_column AS T
		ORDER BY T.TargetTableName, T.Target_COLUMN_NAME

		SELECT '3. Новые поля на PROD (#t_new_column)'
		SELECT * 
		FROM #t_new_column AS T
		ORDER BY T.TargetTableName, T.Source_ORDINAL_POSITION, T.Source_COLUMN_NAME
	END


	----------------------------------------
	--1 В таблице на PROD удалили колонку, и этой колонки нет в ExcludeColumns
	SELECT @html_table1 = (
		SELECT string_agg(
			cast(
				concat(
					'<tr>',
						'<td>', T.TargetTableName, '</td>',
						'<td>', T.SourceTableName, '</td>',
						'<td>', T.Source_COLUMN_NAME, '</td>',
						'<td>', T.Target_COLUMN_NAME, '</td>',
						--'<td>', left(T.ExcludeColumns,50), '</td>',
						'<td>', T.ExcludeColumns, '</td>',
					'</tr>'
				) AS varchar(max)
			), char(13)+char(10)
		)  WITHIN GROUP (ORDER BY T.TargetTableName, T.Target_COLUMN_NAME)
		FROM #t_drop_column_group AS T
	)

	SELECT @html_table1 = 
		concat(
			'<H2>', 'В таблице на PROD удалили колонку, и этой колонки нет в ExcludeColumns', '</H2>',
			'<table cellspacing="0" border="1" cellpadding="5">',
				'<tr>',
					'<td><b>TargetTableName</b></td>',
					'<td><b>SourceTableName</b></td>',
					'<td><b>Source_COLUMN_NAME</b></td>',
					'<td><b>Target_COLUMN_NAME</b></td>',
					'<td><b>ExcludeColumns</b></td>',
				'</tr>',
				@html_table1,
				'</table>'
		)



	----------------------------------------
	--2 В таблице на PROD изменился тип данных или размерность поля
	SELECT @html_table2 = (
		SELECT string_agg(
			cast(
				concat(
					'<tr>',
						'<td>', T.TargetTableName, '</td>',
						'<td>', T.SourceTableName, '</td>',

						'<td>', T.Source_COLUMN_NAME, '</td>',
						'<td>', T.Source_DATA_TYPE, '</td>',
						'<td>', T.Source_CHARACTER_MAXIMUM_LENGTH, '</td>',
						'<td>', T.Source_NUMERIC_PRECISION, '</td>',
						'<td>', T.Source_NUMERIC_PRECISION_RADIX, '</td>',
						'<td>', T.Source_DATETIME_PRECISION, '</td>',

						'<td>', T.Target_COLUMN_NAME, '</td>',
						'<td>', T.Target_DATA_TYPE, '</td>',
						'<td>', T.Target_CHARACTER_MAXIMUM_LENGTH, '</td>',
						'<td>', T.Target_NUMERIC_PRECISION, '</td>',
						'<td>', T.Target_NUMERIC_PRECISION_RADIX, '</td>',
						'<td>', T.Target_DATETIME_PRECISION, '</td>',

					'</tr>'
				)
			 AS varchar(MAX)
			 ), char(13)+char(10)
		)  WITHIN GROUP (ORDER BY T.TargetTableName, T.Target_COLUMN_NAME)
		
		FROM #t_change_column AS T
	)


	SELECT @html_table2 = 
		concat(
			'<br><br><H2>', 'В таблице на PROD изменился тип данных или размерность поля', '</H2>',
			'<table cellspacing="0" border="1" cellpadding="5">',
				'<tr>',
					'<td><b>TargetTableName</b></td>',
					'<td><b>SourceTableName</b></td>',

					'<td><b>Source_COLUMN_NAME</b></td>',
					'<td><b>Source_DATA_TYPE</b></td>',
					'<td><b>Source_CHARACTER_MAXIMUM_LENGTH</b></td>',
					'<td><b>Source_NUMERIC_PRECISION</b></td>',
					'<td><b>Source_NUMERIC_PRECISION_RADIX</b></td>',
					'<td><b>Source_DATETIME_PRECISION</b></td>',

					'<td><b>Target_COLUMN_NAME</b></td>',
					'<td><b>Target_DATA_TYPE</b></td>',
					'<td><b>Target_CHARACTER_MAXIMUM_LENGTH</b></td>',
					'<td><b>Target_NUMERIC_PRECISION</b></td>',
					'<td><b>Target_NUMERIC_PRECISION_RADIX</b></td>',
					'<td><b>Target_DATETIME_PRECISION</b></td>',

				'</tr>',
				@html_table2,
				'</table>'
		)


	----------------------------------------
	--3 Новые поля на PROD
	SELECT @html_table3 = (
		SELECT string_agg(
			cast(
				concat(
					'<tr>',
						'<td>', T.TargetTableName, '</td>',
						'<td>', T.SourceTableName, '</td>',

						'<td>', T.Source_ORDINAL_POSITION, '</td>',
						'<td>', T.Source_COLUMN_NAME, '</td>',
						'<td>', T.DATA_TYPE, '</td>',
						'<td>', T.CHARACTER_MAXIMUM_LENGTH, '</td>',
						'<td>', T.NUMERIC_PRECISION, '</td>',
						'<td>', T.NUMERIC_PRECISION_RADIX, '</td>',
						'<td>', T.DATETIME_PRECISION, '</td>',
						'<td>', T.COLLATION_NAME, '</td>',

					'</tr>'
				)
			 AS varchar(MAX)
			 ), char(13)+char(10)
		)  WITHIN GROUP (ORDER BY T.TargetTableName, T.Source_ORDINAL_POSITION, T.Source_COLUMN_NAME)
		
		FROM #t_new_column AS T
	)

	SELECT @html_table3 = 
		concat(
			'<br><br><H2>', 'Новые поля на PROD', '</H2>',
			'<table cellspacing="0" border="1" cellpadding="5">',
				'<tr>',
					'<td><b>TargetTableName</b></td>',
					'<td><b>SourceTableName</b></td>',

					'<td><b>T.Source_ORD</b></td>',
					'<td><b>Source_COLUMN_NAME</b></td>',
					'<td><b>DATA_TYPE</b></td>',
					'<td><b>CHARACTER_MAXIMUM_LENGTH</b></td>',
					'<td><b>NUMERIC_PRECISION</b></td>',
					'<td><b>NUMERIC_PRECISION_RADIX</b></td>',
					'<td><b>DATETIME_PRECISION</b></td>',
					'<td><b>COLLATION_NAME</b></td>',

				'</tr>',
				@html_table3,
				'</table>'
		)



	-- все таблицы
	SELECT @html_table = concat(@html_table1, @html_table2, @html_table3)

	set @body = concat(
		'<H1>', @subject, '</H1><br><br>', @html_table
	)

	if ltrim(rtrim(@recipients)) <>'' 
		and @isSendMail = 1
	begin 
	    
		--         select @tsql 
		IF @isDebug = 1 BEGIN
			SELECT @subject
			SELECT @html_table
			SELECT @body
		END
		ELSE BEGIN
			EXEC msdb.dbo.sp_send_dbmail  
			@profile_name = 'Default',  
			@recipients = @recipients,  
			@body = @body,  
			@body_format='HTML', 
			@subject = @subject; 
	     END
	end 

	--

	if @targetTableName IS not NULL
		and exists(select * from #t_new_column)
		and @isScript <> 0
	begin
		--1
		SELECT @script_add = (
			SELECT string_agg(
				cast(
					concat(
						T.Source_COLUMN_NAME, ' ',
						case 
							when T.DATA_TYPE in ('text') 
								then concat('nvarchar(max)',
									case 
										when T.COLLATION_NAME is not null
										then concat(' collate ', T.COLLATION_NAME)
										else ''
									end
								)
							
							when T.DATA_TYPE in ('timestamp') 
								then 'binary(8)'
								
							when T.DATA_TYPE in ('varchar','nvarchar') 
								and T.CHARACTER_MAXIMUM_LENGTH in (-1)
								then concat('nvarchar(max)',
									case 
										when T.COLLATION_NAME is not null
										then concat(' collate ', T.COLLATION_NAME)
										else ''
									end
								)

							when T.DATA_TYPE in ('numeric','decimal') 
								then concat(T.DATA_TYPE
									, '('
									, NUMERIC_PRECISION 
									,', '
									, NUMERIC_SCALE
									,')')
							else concat(
									T.DATA_TYPE, 
								case 
									when T.CHARACTER_MAXIMUM_LENGTH is not null
									then concat('(',T.CHARACTER_MAXIMUM_LENGTH,')')
									else ''
								end,
								--T.CHARACTER_MAXIMUM_LENGTH,
								--T.NUMERIC_PRECISION,
								--T.NUMERIC_PRECISION_RADIX,
								--T.DATETIME_PRECISION,
								--T.COLLATION_NAME,
								case 
									when T.COLLATION_NAME is not null
									then concat(' collate ', T.COLLATION_NAME)
									else ''
								end
							)
						end, ','
					)
				 AS varchar(MAX)
				 ), @newLineChar
			)  WITHIN GROUP (ORDER BY T.TargetTableName, T.Source_ORDINAL_POSITION, T.Source_COLUMN_NAME)
			FROM #t_new_column AS T
		)

		--убрать последнюю запятую
		SELECT @script_add = SUBSTRING(@script_add, 1, len(@script_add)-1)

		if @isCreateTable = 0 begin
			SELECT @script_alter = concat('ALTER TABLE ', @targetTableName, ' ADD ', @script_add)
			SELECT @script_alter_upd = concat('ALTER TABLE ', @targetTableName, '_upd ADD ', @script_add)
		end

		if @isCreateTable = 1 begin
			SELECT @script_alter = concat_WS(' ',
				'CREATE TABLE'
				, @targetTableName
				, '(', @script_add
				, ', DWHInsertedDate datetime, ProcessGUID nvarchar(36))'
				)
			SELECT @script_alter_upd =concat_WS(' ',
				'CREATE TABLE'
				, concat(@targetTableName, '_upd')
				, '('
				, @script_add
				,')')
		end

		--2
		--скрипт поиска записи, с которой надо делать перезагрузку
		SELECT @script_min_row = (
			SELECT string_agg(
				cast(concat(T.Source_COLUMN_NAME, ' is not null or') AS varchar(MAX)
				 ), char(13)+char(10)
			)  WITHIN GROUP (ORDER BY T.TargetTableName, T.Source_ORDINAL_POSITION, T.Source_COLUMN_NAME)
			FROM #t_new_column AS T
		)
		--убрать последний OR
		SELECT @script_min_row = SUBSTRING(@script_min_row, 1, len(@script_min_row)-3)

		select @SourceTableName = (select top 1 T.SourceTableName FROM #t_new_column AS T)

		--var 1
		/*
		SELECT @script_search = concat(
			'select ',
			--'min(cast(rowver as bigint)), ',
			'concat(''update PV set Value = '''''',min(cast(rowver as bigint)), '''''' from Stg.etl.PredicateValue as PV where PV.TableName = ''''Stg.', @targetTableName, '_upd'''''')',
			' from ',
			@SourceTableName,
			' where ', @script_min_row)
		*/

		--var 2
		SELECT @script_search = ';with min_rowver as (
	select min(cast(rowver as bigint)) min_id
	from ' + @SourceTableName + ' where ' + @script_min_row + '
),
count_row as (
	select count(*) cnt_row
	from ' + @SourceTableName + ' t
		join min_rowver m on 1=1
	where t.rowver >= m.min_id
)
select concat(
	''update PV set Value = '''''',
	m.min_id - 100, 
	'''''' from Stg.etl.PredicateValue as PV where PV.TableName = ''''Stg.' + @targetTableName + '_upd'''''',
	'' -- count row = '', c.cnt_row
	)
from min_rowver m
	join count_row c on 1=1
'


		--3
		--скрипт update Stg.etl.PredicateValue set Value = <>
		SELECT @script_upd_pv = concat(
			'update PV set Value = <> from Stg.etl.PredicateValue as PV where PV.TableName = ''Stg.',
			@targetTableName, '_upd''')

		if @isScript = 1 begin
			SELECT @script_alter
			SELECT @script_alter_upd
			--SELECT @script_search
			--SELECT @script_upd_pv 
		end
		if @isScript in (1,2) begin
			SELECT @script_search
		end
	end





END try
begin catch
	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch
	
end