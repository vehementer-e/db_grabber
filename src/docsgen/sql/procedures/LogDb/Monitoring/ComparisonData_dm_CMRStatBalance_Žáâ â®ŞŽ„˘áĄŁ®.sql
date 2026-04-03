-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROC Monitoring.ComparisonData_dm_CMRStatBalance_ОстатокОДвсего
	 @isDebug bit = 0
AS
BEGIN
	SELECT @isDebug = isnull(@isDebug, 0)
	declare
		@sourceTable NVARCHAR(255) = 'Stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных',
		 @targetTable NVARCHAR(255) ='dwh2.dbo.dm_CMRStatBalance',
		 @sourceColumns NVARCHAR(MAX) = 'НомерДоговора, ОстатокОДвсего',
		 @targetColumns NVARCHAR(MAX) = 'external_id, [остаток од]',
		 @periodColumns NVARCHAR(MAX) = 'DWHInsertedDate',
		 @isSendToEmail bit = 1,
		 @selectComparisonResult bit = 0,
		 @whereCondition nvarchar(1024),
		 @targetWhereCondition nvarchar(1024),
		 @joinCondition NVARCHAR(MAX),
		@t_table_name nvarchar(255)

	DECLARE @SQL nvarchar(MAX), @contractGuid nvarchar(36)
	DECLARE @s_comp_date varchar(10) = format(eomonth(getdate(),-1), 'yyyy-MM-dd')

	SELECT @whereCondition = concat('ДатаОтчета = cast(dateadd(year,2000,''', @s_comp_date, ''') as datetime2(0))')
	SELECT @targetWhereCondition = concat('d = ''', @s_comp_date, '''')
	SELECT @joinCondition = concat(
		'stg.ДатаОтчета = cast(dateadd(year,2000,''', @s_comp_date, ''') as datetime2(0))',
		' AND stg.НомерДоговора = subQuery.НомерДоговора'
		)

	declare
		@emailList nvarchar(max) =(select top(1) emails from LogDb.dbo.Emails where loggerName = 'adminlog'),
		 @tableTitle nvarchar(255) = concat_ws(' ', 'Сравнение', @sourceTable,'vs', @targetTable),
		 @emailSubject nvarchar(255) = concat_ws(' ',  'DQ dm_CMRStatBalance', 'Сравнение', @sourceTable,'vs', @targetTable,
			'за', @s_comp_date),
		 @rowsInEmail int = 200

	DECLARE 
		@targetJoinCondition nvarchar(2048),
		@columnsList nvarchar(2048),
		@columnsWithAlias nvarchar(2048),
		@columnsWithTypes nvarchar(2048)

	SELECT @targetJoinCondition = concat('trg.d = ''',@s_comp_date,''' and trg.external_id = subQuery.НомерДоговора')

	SELECT @columnsList = concat_ws(',',
		'Договор',
		'Остаток_ОД_ЦМР',
		'Остаток_ОД_УМФО',
		'Разница_ОстатокОД'
		)
	SELECT @columnsWithAlias = concat_ws(',',
		'stg.НомерДоговора',
		'trg.[остаток од]',
		'stg.ОстатокОДвсего',
		'Разница_ОстатокОД = trg.[остаток од] - stg.ОстатокОДвсего'
		)

	SELECT @columnsWithTypes = concat_ws(',', 
		'Договор nvarchar(255)',
		'Остаток_ОД_ЦМР nvarchar(100)',
		'Остаток_ОД_УМФО nvarchar(100)',
		'Разница_ОстатокОД nvarchar(100)'
		)

	exec  LogDb.Monitoring.ComparisonDataSets_v2
		@sourceTable				=	@sourceTable				
		,@targetTable				=	@targetTable				
		,@sourceColumns				=	@sourceColumns				
		,@targetColumns				=	@targetColumns
		,@periodColumns				=	@periodColumns
		,@isSendToEmail				=	@isSendToEmail				
		,@selectComparisonResult	=	@selectComparisonResult	
		,@emailList					=	@emailList					
		,@tableTitle				=	@tableTitle				
		,@emailSubject				=	@emailSubject				
		,@rowsInEmail				=	@rowsInEmail				
		,@isDebug					=	@isDebug
		,@whereCondition			=	@whereCondition
		,@targetWhereCondition		=	@targetWhereCondition
		,@joinCondition				=	@joinCondition
		,@targetJoinCondition		=	@targetJoinCondition
		,@columnsList				=	@columnsList
		,@columnsWithAlias			=	@columnsWithAlias
		,@columnsWithTypes			=	@columnsWithTypes  
		,@isDropTable				=	0
		,@t_table_name				=	@t_table_name OUT

	IF @isDebug = 1 BEGIN
		SELECT @t_table_name
	END

	DROP TABLE IF EXISTS #t_Deal
	CREATE TABLE #t_Deal(Договор nvarchar(30))

	SELECT @SQL = concat('INSERT #t_Deal(Договор) SELECT DISTINCT Договор FROM ', @t_table_name)

	EXEC sp_executesql @SQL

	DROP TABLE IF EXISTS #t_contract
	CREATE TABLE #t_contract(contractGuid nvarchar(36))

	INSERT #t_contract(contractGuid)
	SELECT contractGuid = H.GuidДоговораЗайма 
	FROM #t_Deal AS D
		INNER JOIN dwh2.hub.ДоговорЗайма AS H
			ON H.КодДоговораЗайма = D.Договор
	WHERE NOT EXISTS (
		SELECT TOP(1) 1
		FROM Stg.etl.ReloadData4Contract AS R
		WHERE R.CreatedAt >= cast(dateadd(MONTH, -1, getdate()) AS date)
			AND R.external_id = D.Договор
			AND R.StatusCode = 'Finished'
		)

	--DWH-2850
	IF EXISTS(SELECT TOP 1 1 FROM #t_contract)
		AND datepart(DAY, getdate()) >= 15 --DWH-2909
		--отключить процесс добавления данных на перезагрузку
		AND 1=0
	BEGIN
		DECLARE cur_contract CURSOR FOR
		SELECT DISTINCT TOP 100 C.contractGuid
		FROM #t_contract AS C
		ORDER BY C.contractGuid

		OPEN cur_contract
		FETCH NEXT FROM cur_contract INTO @contractGuid
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @isDebug = 1 BEGIN
				SELECT @contractGuid
			END
			ELSE BEGIN
				EXEC Stg.etl.runProcessContractUpdate 
					@contractGuid = @contractGuid,
					@processType = 'ReloadData4StrategyDatamartByContract'
		     END

			FETCH NEXT FROM cur_contract INTO @contractGuid
		END

		CLOSE cur_contract
		DEALLOCATE cur_contract
	END
	DECLARE @cmdDropTable nvarchar(1024) = concat_ws(' ', 'DROP TABLE IF EXISTS', @t_table_name)
	EXEC(@cmdDropTable)
	
END
