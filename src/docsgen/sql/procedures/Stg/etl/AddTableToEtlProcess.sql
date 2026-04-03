-- ============================================= 
-- Author: А. Никитин
-- Create date: 30.05.2022
-- Description: добавить настройку репликации таблицы
-- ============================================= 

 /*
select * from etl.v_activeEtlProcess
where  etlProcessName  like '%Loginom2dwhLoader_dict%'
select * from etl.v_EtlProcess
where TargetDataBase like '%umfo%'
and etlProcessName = 'NaumendbIntoDWHLoader_mv_custom_form'
select * from etl.replicationDataBase

exec[etl].[AddTableToEtlProcess]
	@Mode ='full', --'full', 'increment'
	@EtlProcessName = 'Loginom2dwhLoader_dict',
	--.
	@SourceDataBase ='LoginomDB',
	@SourceShemeTableName = 'dbo', 
	@SourceTable = 'OriginationCreditPolicyLimitCapBIM',
	@SourceLogin = 'DWHSSISUser_LoginomDB',
	--
	@TargetDataBase = 'stg',
	--@TargetLogin = NULL,
	@TargetScheme = '_loginom',
	@TargetTable = 'OriginationCreditPolicyLimitCapBIM',
	@increment_field  ='ВерсияДанных',
	@increment_field_type  = 'time',    /*timestamp*/
	@indentity_field  = 'Ссылка',
	@AdditionalColumns = null,
	@ExcludeColumns	=	 null,
	--
	@SelectColumns  = NULL,
	@isDebug = 1
	--select etl.GetPredicateValue('_LCRM.carmoney_light_crm_launch_control_upd')
*/

-- ============================================= 
CREATE PROC [etl].[AddTableToEtlProcess]
	@Mode varchar(127), -- 'full', 'increment'
	@EtlProcessName varchar(127),
	--
	@SourceServer varchar(127) = NULL,
	@SourceDataBase varchar(127),
	@SourceLogin varchar(127) = NULL,
	@SourceShemeTableName varchar(127) = '', 
	@SourceTable varchar(max),
	--
	@TargetServer varchar(127) = NULL,
	@TargetDataBase varchar(127),
	@TargetLogin varchar(127) = NULL,
	@TargetScheme varchar(127),
	@TargetTable varchar(127),

	@increment_field varchar(127) = null,
	@increment_field_for_source varchar(127) = null,
	@increment_field_if_null varchar(127) = null,
	@increment_field_type varchar(127) = null,
	@indentity_field varchar(127) = 'id',
	--
	@ExcludeColumns varchar(127) = null,
	@AdditionalColumns varchar(127) = null,
	--
	@SelectColumns varchar(4000) = NULL,
	@isDebug bit = 0

AS
BEGIN

	SET NOCOUNT ON
	SET XACT_ABORT ON

	IF isnull(@Mode, '') NOT IN ('full','increment')
	BEGIN
		;throw 51000, 'Параметр @Mode должен иметь одно из значений: ''full'', ''increment''', 1
		RETURN
	END
	if @Mode  in ('increment')
		and (isnull(@increment_field, '') is null
			or isnull(@increment_field_type,'') is null
			or isnull(@indentity_field, '') is null)
	begin
		;throw 51000, 'Параметр @Mode = increment: но не задан один из доп. параметров @increment_field, @increment_field_type или @indentity_field', 1
		RETURN
	end
	SELECT @isDebug = isnull(@isDebug, 0)
	
	DECLARE @TargetTable_upd varchar(127)
	DECLARE @SourceDataBase_ID int, @SourceDBMSType varchar(255)
	DECLARE @TargetDataBase_ID int

	IF (
		SELECT count(*) 
		FROM etl.replicationDataBase AS D 
		WHERE D.Name = @SourceDataBase
			AND D.Server = iif(isnull(@SourceServer, '')='', D.Server, @SourceServer)
			AND D.Login = iif(isnull(@SourceLogin, '')='', D.Login, @SourceLogin)
		) <> 1
	BEGIN
		;throw 51000, 'Не определяется однозначно @SourceDataBase_ID, необходим доп. параметры @SourceServer, @SourceLogin', 1
		RETURN 1
	END

	IF (
		SELECT count(*) 
		FROM etl.replicationDataBase AS D 
		WHERE D.Name = @TargetDataBase
			AND D.Server = iif(isnull(@TargetServer, '')='', D.Server, @TargetServer)
			AND D.Login = iif(isnull(@TargetLogin, '')='', D.Login, @TargetLogin)
		) <> 1
	BEGIN
		;throw 51000, 'Не определяется однозначно @TargetDataBase_ID, необходим доп. параметры @TargetServer, @TargetDataBase', 1
		RETURN 1
	END

	SELECT @SourceDataBase_ID = D.Id, @SourceDBMSType = D.DBMSType
	FROM etl.replicationDataBase AS D 
	WHERE D.Name = @SourceDataBase
		AND D.Server = iif(isnull(@SourceServer, '')='', D.Server, @SourceServer)
		AND D.Login = iif(isnull(@SourceLogin, '')='', D.Login, @SourceLogin)

	--
	IF @isDebug = 1 BEGIN
		SELECT concat('@SourceDBMSType=',@SourceDBMSType)
	END


	SELECT @TargetDataBase_ID = D.Id
	FROM etl.replicationDataBase AS D 
	WHERE D.Name = @TargetDataBase
		AND D.Server = iif(isnull(@TargetServer, '')='', D.Server, @TargetServer)
		AND D.Login = iif(isnull(@TargetLogin, '')='', D.Login, @TargetLogin)

	--IF nullif(@increment_field_for_source,'') IS NULL
	--BEGIN
	--    SELECT @increment_field_for_source = @increment_field
	--END

	-- 1 INSERT @SourceTable
	INSERT INTO etl.replicationTable(DataBaseID, Name)
	SELECT d.id AS DataBaseID,  t.TableName
	FROM etl.replicationDataBase AS d
		outer apply( 
		SELECT TableName FROM (
			VALUES  (isnull(@SourceShemeTableName + '.', '') + @SourceTable) --('collecting_stage')
		) t (TableName)
		) t
	WHERE 1=1
		--AND d.Name = @SourceDataBase --'espocrm'
		AND d.Id = @SourceDataBase_ID
		AND not EXISTS (SELECT 1 FROM etl.replicationTable AS t1 WHERE t1.DataBaseID = d.Id
		AND t.TableName = t1.Name);


	-- 2
	IF @Mode like 'increment%'
	BEGIN
		-- 2a INSERT @TargetTable_upd
	    SELECT @TargetTable_upd = Concat(@TargetTable, '_upd')

		INSERT INTO etl.replicationTable(DataBaseID, Name)
		SELECT d.id AS databaseID,  t.TableName FROM etl.replicationDataBase AS d
			OUTER APPLY (
			SELECT TableName FROM (
				VALUES (Concat(isnull(@TargetScheme +'.', ''),  @TargetTable_upd))
			) t (TableName)
			) t
		WHERE 1=1
			--d.Name = @TargetDataBase --'stg'
			AND d.Id = @TargetDataBase_ID
			AND not EXISTS (SELECT 1 FROM etl.replicationTable AS t1 WHERE t1.DataBaseID = d.id
			AND t.TableName = t1.Name);
	END

	-- 2b INSERT @TargetTable
	INSERT INTO etl.replicationTable(DataBaseID, Name)
	SELECT d.id AS databaseID,  t.TableName FROM etl.replicationDataBase AS d
		OUTER APPLY (
		SELECT TableName FROM (
			VALUES (concat(isnull(@TargetScheme + '.', ''), @TargetTable))
		) t (TableName)
		) t
	WHERE 1=1
		--d.Name = @TargetDataBase --'stg'
		AND d.Id = @TargetDataBase_ID
		AND not EXISTS (SELECT 1 FROM etl.replicationTable AS t1 WHERE t1.DataBaseID = d.Id
		AND t.TableName = t1.Name);

	create table #tmp_InsertedProcess
	(
		Id int
	)

	-- 3 INSERT etl.etlProcess
	IF @Mode = 'full'
	BEGIN
		INSERT INTO etl.etlProcess
		(
			Name,
			SourceTableID,
			TargetTableID,
			Sort,
			isActive,
			SelectColumns,
			SelectPredicate,
			cmdGetValueOfSelectPredicate,
			deletePredicate,
			cmdGetValueOfDeletePredicate,
			ExcludeColumns,
			AdditionalColumns
		)
		OUTPUT Inserted.Id INTO #tmp_InsertedProcess
		SELECT  
			Name = @EtlProcessName, --'loadFromEspocrm',
			SourceTableID = SRC.SourceTableId,
			TargetTableId = TRG.TargetTableId,
			Sort = (SELECT max(Sort) FROM etl.etlProcess) + row_number() OVER(ORDER BY getdate()),
			isActive = 1,
			SelectColumns = isnull(@SelectColumns, '*'),
			SelectPredicate = '1=1',
			cmdGetValueOfSelectPredicate = NULL,
			deletePredicate = '1=1',
			cmdGetValueOfDeletePredicate = NULL,
			ExcludeColumns = @ExcludeColumns,
			AdditionalColumns = @AdditionalColumns
		FROM (
			SELECT 
				S.id AS SourceTableId,
				S.name AS SourceTableName 
			FROM etl.replicationTable AS S
			WHERE 1=1
				--AND S.DataBaseID IN (SELECT id FROM etl.replicationDataBase AS d WHERE d.name = @SourceDataBase) --'espocrm'
				AND S.DataBaseID = @SourceDataBase_ID
				and S.Name = concat(isnull(@SourceShemeTableName + '.', ''), @SourceTable)
				AND NOT EXISTS(
					SELECT * 
					FROM etl.etlProcess AS X 
					WHERE X.SourceTableID = S.Id 
						AND X.Name = @EtlProcessName --'loadFromEspocrm'
						and x.isActive = 1
				)
			) AS SRC

			INNER JOIN (
				SELECT 
					T.id AS TargetTableId,
					T.name AS TargetTableName
				FROM etl.replicationTable AS T
				WHERE 1=1
					--AND T.DataBaseID IN (SELECT id FROM etl.replicationDataBase d WHERE d.name = @TargetDataBase) --'stg')
					AND T.DataBaseID = @TargetDataBase_ID
					and T.Name = concat(isnull(@TargetScheme + '.', ''), @TargetTable)
					AND NOT EXISTS(
						SELECT * 
						FROM etl.etlProcess AS X 
						WHERE X.TargetTableID = T.Id 
							AND X.Name = @EtlProcessName --'loadFromEspocrm'
							and x.isActive = 1
					)
			) AS TRG 
			--ON TRG.TargetTableName = concat('_espocrm.', replace(replace(SRC.SourceTableName, '.','_'), '"',''))
			ON 1=1
				
				
	END --// IF @Mode = 'full'


	IF @Mode like 'increment%'
	BEGIN
		merge etl.PredicateValue t
		using (
			select 
				TableName = concat_ws('.', @TargetDataBase, @TargetScheme, @TargetTable_upd)
				,Value = case
					when @increment_field_type like '%date%' then '2000-01-01 00:00:00'
					when @increment_field_type like '%timestamp%' then '0'
					end
				,ValueType = case 
					when @increment_field_type like '%timestamp%' then 'bigint'
					when @increment_field_type like '%date%' then @increment_field_type
				end
				,ColumnName = 
						CASE WHEN @increment_field_if_null IS NULL
							THEN @increment_field
							ELSE concat('isnull(',@increment_field,',',@increment_field_if_null,')')
						END
				,updated_at = getdate()
		) s
		on t.TableName = s.TableName
		when not matched then insert
		(
					TableName,
					Value,
					ValueType,
					ColumnName,
					updated_at
				)
		values
		(
			TableName,
			Value,
			ValueType,
			ColumnName,
			updated_at
		)
		when matched then  update set
			Value		 = s.Value
			,ValueType	 = s.ValueType
			,ColumnName	 = s.ColumnName
			,updated_at	 = s.updated_at
			,ProcessGUID = null
			;
		/*
		
		--INSERT etl.PredicateValue
		IF NOT EXISTS(
				SELECT * 
				FROM etl.PredicateValue AS P 
				WHERE TableName = concat(@TargetDataBase, '.', @TargetScheme, '.', @TargetTable_upd)
			)
		BEGIN
			IF @increment_field_type like '%timestamp%'
				
			BEGIN
				INSERT etl.PredicateValue
				(
					TableName,
					Value,
					ValueType,
					ColumnName,
					updated_at,
					ProcessGUID
				)
				SELECT 
					TableName = concat(@TargetDataBase, '.', @TargetScheme, '.', @TargetTable_upd),
					Value = '0',
					ValueType = 'bigint',
					ColumnName = @increment_field,
					updated_at = getdate(),
					ProcessGUID = NULL
			END

			IF @increment_field_type like '%date%'
			BEGIN
				INSERT etl.PredicateValue
				(
					TableName,
					Value,
					ValueType,
					ColumnName,
					updated_at,
					ProcessGUID
				)
				SELECT 
					TableName = concat(@TargetDataBase, '.', @TargetScheme, '.', @TargetTable_upd),
					Value = '2000-01-01 00:00:00',
					ValueType = @increment_field_type,
					--ColumnName = @increment_field,
					ColumnName = 
						CASE WHEN @increment_field_if_null IS NULL
							THEN @increment_field
							ELSE concat('isnull(',@increment_field,',',@increment_field_if_null,')')
						END,
					updated_at = getdate(),
					ProcessGUID = NULL
			END
		END
		*/

		--1. src -> _upd
		INSERT INTO etl.etlProcess
		(
			Name,
			SourceTableID,
			TargetTableID,
			Sort,
			isActive,
			SelectColumns,
			SelectPredicate,
			cmdGetValueOfSelectPredicate,
			deletePredicate,
			cmdGetValueOfDeletePredicate,
			ExcludeColumns,
			AdditionalColumns
		)
		OUTPUT Inserted.Id INTO #tmp_InsertedProcess
		SELECT  
			/*
			SelectPredicate='modified_at>STR_TO_DATE(''@PredicateValue'',''%Y-%m-%d %H:%i:%s'')'
			cmdGetValueOfSelectPredicate='select format(isnull((select max(modified_at) from _espocrm.account), ''2000-01-01'') ,''yyyy-MM-dd HH:mm:ss'')'
			*/
			Name = @EtlProcessName, --'loadFromEspocrm',
			SourceTableID = SRC.SourceTableId,
			TargetTableId = TRG.TargetTableId,
			Sort = 1,
			isActive = 1,
			SelectColumns = isnull(@SelectColumns, '*'),
			SelectPredicate = 
			case 
				--@increment_field_for_source
				--when @increment_field_type like '%date%' then  concat(@increment_field, ' >STR_TO_DATE(''@PredicateValue'',''%Y-%m-%d %H:%i:%s'')')
				--when @increment_field_type like '%date%' then  concat(isnull(@increment_field_for_source,@increment_field), '>STR_TO_DATE(''@PredicateValue'',''%Y-%m-%d %H:%i:%s'')')

				-- IFNULL(updated_at, created_at)>STR_TO_DATE('@PredicateValue','%Y-%m-%d %H:%i:%s')
				when @increment_field_type like '%date%' 

				THEN
					CASE 
					--MySql
					WHEN @SourceDBMSType IN ('MySql')
					THEN concat(isnull(@increment_field_for_source,@increment_field),
						'>STR_TO_DATE(''@PredicateValue'',''%Y-%m-%d %H:%i:%s'')'
						)
					--MsSQL
					WHEN @SourceDBMSType IN ('MsSQL')
					THEN 
						CASE WHEN @increment_field_if_null IS NULL
						THEN 
							concat(
								isnull(@increment_field_for_source,@increment_field),
								' >= cast(''@PredicateValue'' as date)'
							)
						ELSE 
							concat(
								'isnull(',
								isnull(@increment_field_for_source,@increment_field),
								', ', @increment_field_if_null, ')',
								' >= cast(''@PredicateValue'' as date)'
							)
						END
					--PostgreSQL
					WHEN @SourceDBMSType IN ('PostgreSQL')
					THEN concat(isnull(@increment_field_for_source,@increment_field),
						'>=TO_TIMESTAMP(''@PredicateValue'', ''yyyy-MM-dd HH24:MI:SS'')'
						)
					--other SourceDBMSType
					ELSE concat(@increment_field, ' > @PredicateValue')
					END

					--THEN concat(
					--	'IFNULL(',
					--	isnull(@increment_field_for_source,@increment_field),
					--	', created_at)',
					--	'>STR_TO_DATE(''@PredicateValue'',''%Y-%m-%d %H:%i:%s'')'
					--	)

					--MySql
					--THEN concat(isnull(@increment_field_for_source,@increment_field),
					--	'>STR_TO_DATE(''@PredicateValue'',''%Y-%m-%d %H:%i:%s'')'
					--	)

					--THEN concat(
					--	'isnull(',
					--	isnull(@increment_field_for_source,@increment_field),
					--	', cast(''2010-01-01'' as date))',
					--	' >= cast(''@PredicateValue'' as date)'
					--	)

					--MsSql
					--THEN
					--	CASE WHEN @increment_field_if_null IS NULL
					--	THEN 
					--		concat(
					--			isnull(@increment_field_for_source,@increment_field),
					--			' >= cast(''@PredicateValue'' as date)'
					--		)
					--	ELSE 
					--		concat(
					--			'isnull(',
					--			isnull(@increment_field_for_source,@increment_field),
					--			', ', @increment_field_if_null, ')',
					--			' >= cast(''@PredicateValue'' as date)'
					--		)
					--	END

				when @increment_field_type like '%mysql_timestamp%' 
					THEN concat(@increment_field, ' > @PredicateValue - 100')

				when @increment_field_type like '%timestamp%' then  concat('cast(', @increment_field, ' as bigint)>cast(''@PredicateValue'' as bigint)-100')
				when @increment_field_type like '%int' AND @increment_field = 'xmin'
					THEN concat(@increment_field, '::text::int >= cast(''@PredicateValue'' as integer)-100')
				when  @increment_field_type like '%int' and @increment_field not in('xmin')
					then  concat('', @increment_field, '>cast(''@PredicateValue'' as bigint)-100')
				end ,
			cmdGetValueOfSelectPredicate = case

				--when @increment_field_type like '%date%' then  concat('select format(isnull((select max(',@increment_field,') from ', @TargetScheme, '.', @TargetTable, '), ''2000-01-01'') ,''yyyy-MM-dd HH:mm:ss'')')
				--select format(isnull((select max(isnull(updated_at, created_at)) from _LK.requests_events), '2000-01-01') ,'yyyy-MM-dd HH:mm:ss')

				--when @increment_field_type like '%date%' THEN
				--	concat(
				--		'select format(isnull((select max(isnull(', @increment_field, ', created_at)',
				--		') from ',
				--		@TargetScheme, '.', @TargetTable, '), ''2000-01-01'') ,''yyyy-MM-dd HH:mm:ss'')'
				--	)

				--when @increment_field_type like '%timestamp%' then  concat('select isnull(max(cast(', @increment_field, ' as bigint)),0) from ', @TargetScheme, '.', @TargetTable)
				--пример: 'select etl.GetPredicateValue(''_loginom.bki_income_exp_pdn_upd'')'
				WHEN @increment_field_type LIKE '%timestamp%' 
					OR @increment_field_type LIKE '%date%'
					THEN concat('SELECT stg.etl.GetPredicateValue(''', 
							@TargetDataBase, '.', @TargetScheme, '.', @TargetTable_upd, 
							''')'
						)

				when @increment_field_type like 'int' AND @increment_field = 'xmin'
					THEN concat('(select isnull(max(', @increment_field, '),0) from ', @TargetScheme, '.', @TargetTable, ')')
				end,
			deletePredicate = '1=1',
			cmdGetValueOfDeletePredicate = NULL,
			ExcludeColumns = @ExcludeColumns,
			AdditionalColumns = @AdditionalColumns
		FROM (
			SELECT 
				S.id AS SourceTableId,
				S.name AS SourceTableName 
			FROM etl.replicationTable AS S
			WHERE 1=1
				--AND S.DataBaseID IN (SELECT id FROM etl.replicationDataBase AS d WHERE d.name = @SourceDataBase) --'espocrm'
				AND S.DataBaseID = @SourceDataBase_ID
				and S.Name = Concat(isnull(@SourceShemeTableName + '.', ''), @SourceTable)
				AND NOT EXISTS(
					SELECT * 
					FROM etl.etlProcess AS X 
					WHERE X.SourceTableID = S.Id 
						AND X.Name = @EtlProcessName --'loadFromEspocrm'
						and x.isActive = 1
				)
			) AS SRC

			INNER JOIN (
				SELECT 
					T.id AS TargetTableId,
					T.name AS TargetTableName
				FROM etl.replicationTable AS T
				WHERE 1=1
					--and T.databaseid IN (SELECT id FROM etl.replicationDataBase d WHERE d.name = @TargetDataBase) --'stg')
					and T.DataBaseID = @TargetDataBase_ID
					and T.Name =Concat(isnull(@TargetScheme + '.', ''),  @TargetTable_upd)
					AND NOT EXISTS(
						SELECT * 
						FROM etl.etlProcess AS X 
						WHERE X.TargetTableID = T.Id 
							AND X.Name = @EtlProcessName --'loadFromEspocrm'
						and x.isActive = 1
					)
			) AS TRG 
				--правило сопоставления таблиц _upd и 
			ON 1=1
			

		IF @isDebug = 1
		BEGIN
			SELECT 
				S.id AS SourceTableId,
				S.name AS SourceTableName 
			FROM etl.replicationTable AS S
			WHERE 1=1
				--AND S.DataBaseID IN (SELECT id FROM etl.replicationDataBase AS d WHERE d.name = @SourceDataBase) --'espocrm'
				AND S.DataBaseID = @SourceDataBase_ID
				and S.Name = concat(isnull(@SourceShemeTableName + '.', ''), @SourceTable)
				AND NOT EXISTS(
					SELECT * 
					FROM etl.etlProcess AS X 
					WHERE X.SourceTableID = S.Id 
						AND X.Name = @EtlProcessName --'loadFromEspocrm'
						and x.isActive = 1
				)
		    
				SELECT 
					T.id AS TargetTableId,
					T.name AS TargetTableName
				FROM etl.replicationTable AS T
				WHERE 1=1
					--and T.databaseid IN (SELECT id FROM etl.replicationDataBase d WHERE d.name = @TargetDataBase) --'stg')
					and T.DataBaseID = @TargetDataBase_ID
					and T.Name = concat(isnull(@TargetScheme + '.', ''), @TargetTable_upd)
					AND NOT EXISTS(
						SELECT * 
						FROM etl.etlProcess AS X 
						WHERE X.TargetTableID = T.Id 
							AND X.Name = @EtlProcessName --'loadFromEspocrm'
							and x.isActive = 1
					)
		END



		--2. _upd -> trg
		INSERT INTO etl.etlProcess
		(
			Name,
			SourceTableID,
			TargetTableID,
			Sort,
			isActive,
			SelectColumns,
			SelectPredicate,
			cmdGetValueOfSelectPredicate,
			deletePredicate,
			cmdGetValueOfDeletePredicate,
			ExcludeColumns,
			AdditionalColumns
		)
		OUTPUT Inserted.Id INTO #tmp_InsertedProcess
		SELECT  
			/*
			deletePredicate = 'id in (select id from _espocrm.account_upd)'
			*/
			Name = @EtlProcessName, --'loadFromEspocrm',
			SourceTableID = SRC.SourceTableId,
			TargetTableId = TRG.TargetTableId,
			Sort = 2,
			isActive = 1,
			SelectColumns = '*',
			SelectPredicate = '1=1',
			cmdGetValueOfSelectPredicate = NULL,
			deletePredicate = concat(@indentity_field, ' in (select ',@indentity_field,' from ' + @TargetScheme + '.' + @TargetTable_upd + ')'),
			cmdGetValueOfDeletePredicate = NULL,
			ExcludeColumns = NULL,
			AdditionalColumns = NULL
		FROM (
				SELECT 
					S.id AS SourceTableId,
					S.name AS SourceTableName 
				FROM etl.replicationTable AS S
				WHERE 1=1
					--and S.DataBaseID IN (SELECT id FROM etl.replicationDataBase d WHERE d.name = @TargetDataBase) --'stg')
					and S.DataBaseID = @TargetDataBase_ID
					and S.Name = concat(isnull(@TargetScheme + '.', ''), @TargetTable_upd) --_espocrm.account_upd
					AND NOT EXISTS(
						SELECT * 
						FROM etl.etlProcess AS X 
						WHERE X.SourceTableID = S.Id
							AND X.isActive = 1
							AND X.Name = @EtlProcessName --'loadFromEspocrm'
							and x.isActive = 1
					)
			) AS SRC

			INNER JOIN (
				SELECT 
					T.id AS TargetTableId,
					T.name AS TargetTableName
				FROM etl.replicationTable AS T
				WHERE 1=1
					--and T.databaseid IN (SELECT id FROM etl.replicationDataBase d WHERE d.name = @TargetDataBase) --'stg')
					and T.DataBaseID = @TargetDataBase_ID
					and T.Name = concat(isnull(@TargetScheme + '.', ''), @TargetTable)
					AND NOT EXISTS(
						SELECT * 
						FROM etl.etlProcess AS X 
						WHERE X.TargetTableID = T.Id 
							AND X.isActive = 1
							AND X.Name = @EtlProcessName --'loadFromEspocrm'
							and x.isActive = 1
					)
			) AS TRG 
				--правило сопоставления таблиц _upd и trg
			ON  1=1
			--ON substring(SRC.SourceTableName,1,len(SRC.SourceTableName) - 4) = TRG.TargetTableName

	END --// IF @SourceDataBase = 'sara' AND @Mode = 'increment_modified_at'


	




	IF @isDebug = 1 BEGIN
		SELECT E.* 
		FROM #tmp_InsertedProcess AS I
			INNER JOIN etl.v_EtlProcess AS E
				ON E.etlProcessId = I.Id
		ORDER BY E.sort
	END

END
