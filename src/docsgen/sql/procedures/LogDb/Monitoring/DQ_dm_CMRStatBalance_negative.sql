-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	DWH-2867 DQ dwh2.dbo.dm_CMRStatBalance проверять есть ли отрицательные данные в dm_CMRStatBalance
-- =============================================
--DROP PROC Monitoring.ComparisonData_dm_CMRStatBalance_negative
CREATE   PROC [Monitoring].[DQ_dm_CMRStatBalance_negative]
	 @isDebug bit = 0
AS
BEGIN
	SELECT @isDebug = isnull(@isDebug, 0)
	declare
		@sourceTable NVARCHAR(255) = 'dwh2.dbo.dm_CMRStatBalance',
		@targetTable NVARCHAR(255) ='dwh2.dbo.dm_CMRStatBalance',

		@sourceColumns NVARCHAR(MAX) = 'd,external_id,[остаток од],[остаток %],[Остаток % расчетный],[остаток иное (комиссии, пошлины и тд)],[остаток пени],[Остаток пени расчетный],[остаток всего],[Расчетный остаток всего]',
		--@sourceColumns NVARCHAR(MAX) = 'd,external_id,остаток_од=[остаток од],остаток_проц=[остаток %],Остаток_проц_расчетный=[Остаток % расчетный],остаток_иное=[остаток иное (комиссии, пошлины и тд)],остаток_пени=[остаток пени],Остаток_пени_расчетный=[Остаток пени расчетный],остаток_всего=[остаток всего],Расчетный_остаток_всего=[Расчетный остаток всего]',

		@targetColumns NVARCHAR(MAX) = 'd,external_id,abs([остаток од]),abs([остаток %]),abs([Остаток % расчетный]),abs([остаток иное (комиссии, пошлины и тд)]),abs([остаток пени]),abs([Остаток пени расчетный]),abs([остаток всего]),abs([Расчетный остаток всего])',
		--@targetColumns NVARCHAR(MAX) = 'd,external_id,остаток_од=abs([остаток од]),остаток_проц=abs([остаток %]),Остаток_проц_расчетный=abs([Остаток % расчетный]),остаток_иное=abs([остаток иное (комиссии, пошлины и тд)]),остаток_пени=abs([остаток пени]),Остаток_пени_расчетный=abs([Остаток пени расчетный]),остаток_всего=abs([остаток всего]),Расчетный_остаток_всего=abs([Расчетный остаток всего])',

		@periodColumns NVARCHAR(MAX) = 'DWHInsertedDate',
		@isSendToEmail bit = 1,
		@selectComparisonResult bit = 0,
		@whereCondition nvarchar(1024),
		@targetWhereCondition nvarchar(1024),
		@joinCondition NVARCHAR(MAX),
		@t_table_name nvarchar(255)

	DECLARE @SQL nvarchar(MAX), @contractGuid nvarchar(36)
	--DECLARE @s_comp_date varchar(10) = format(eomonth(getdate(),-1), 'yyyy-MM-dd')
	--DECLARE @s_comp_date varchar(10) = format(dateadd(DAY,-1,getdate()), 'yyyy-MM-dd')
	DECLARE @s_comp_date varchar(10) = format(getdate(), 'yyyy-MM-dd')

	--SELECT @whereCondition = concat('ДатаОтчета = cast(dateadd(year,2000,''', @s_comp_date, ''') as datetime2(0))')
	SELECT @whereCondition = concat('d = ''', @s_comp_date, '''')
	SELECT @targetWhereCondition = concat('d = ''', @s_comp_date, '''')
	SELECT @joinCondition = concat(
		'stg.d = subQuery.d',
		' AND stg.external_id = subQuery.external_id'
		)

	declare
		@emailList nvarchar(max) =(select top(1) emails from LogDb.dbo.Emails where loggerName = 'adminlog'),
		 --@tableTitle nvarchar(255) = concat_ws(' ', 'Сравнение', @sourceTable,'vs', @targetTable),
		 @tableTitle nvarchar(255) = concat_ws(' ', 'Отрицательные показатели в', @sourceTable),
		 --@emailSubject nvarchar(255) = concat_ws(' ',  'DQ dm_CMRStatBalance', 'Сравнение', @sourceTable,'vs', @targetTable,
			--'за', @s_comp_date),
		 @emailSubject nvarchar(255) = concat_ws(' ',  'DQ dm_CMRStatBalance', 'Отрицательные показатели', 
			'за', @s_comp_date),
		 @rowsInEmail int = 200

	DECLARE 
		@targetJoinCondition nvarchar(2048),
		@columnsList nvarchar(2048),
		@columnsWithAlias nvarchar(2048),
		@columnsWithTypes nvarchar(2048)

	--SELECT @targetJoinCondition = concat('trg.d = ''',@s_comp_date,''' and trg.external_id = subQuery.external_id')

	SELECT @columnsList = concat_ws(',',
		'external_id',
		'остаток_од',
		'остаток_проц',
		'Остаток_проц_расчетный',
		'остаток_иное',
		'остаток_пени',
		'Остаток_пени_расчетный',
		'остаток_всего',
		'Расчетный_остаток_всего'
		)
	SELECT @columnsWithAlias = concat_ws(',',
		'stg.external_id',
		'stg.[остаток од]',
		'stg.[остаток %]',
		'stg.[Остаток % расчетный]',
		'stg.[остаток иное (комиссии, пошлины и тд)]',
		'stg.[остаток пени]',
		'stg.[Остаток пени расчетный]',
		'stg.[остаток всего]',
		'stg.[Расчетный остаток всего]'
		)

	SELECT @columnsWithTypes = concat_ws(',', 
		'external_id nvarchar(100)',
		'остаток_од nvarchar(100)',
		'остаток_проц nvarchar(100)',
		'Остаток_проц_расчетный nvarchar(100)',
		'остаток_иное nvarchar(100)',
		'остаток_пени nvarchar(100)',
		'Остаток_пени_расчетный nvarchar(100)',
		'остаток_всего nvarchar(100)',
		'Расчетный_остаток_всего nvarchar(100)'
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
		--test
		--RETURN
	END

	DROP TABLE IF EXISTS #t_Deal
	CREATE TABLE #t_Deal(Договор nvarchar(30))

	SELECT @SQL = concat('INSERT #t_Deal(Договор) SELECT DISTINCT external_id FROM ', @t_table_name)

	EXEC sp_executesql @SQL

	DROP TABLE IF EXISTS #t_contract
	CREATE TABLE #t_contract(contractGuid nvarchar(36))

	INSERT #t_contract(contractGuid)
	SELECT top(20) contractGuid = H.GuidДоговораЗайма 
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

	IF EXISTS(SELECT TOP 1 1 FROM #t_contract)
		--временно
		
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
			begin try
				EXEC Stg.etl.runProcessContractUpdate 
					@contractGuid = @contractGuid,
					@processType = 'ReloadData4StrategyDatamartByContract'
			end try
			begin catch
				print ERROR_MESSAGE()
			end catch
		     END

			FETCH NEXT FROM cur_contract INTO @contractGuid
		END

		CLOSE cur_contract
		DEALLOCATE cur_contract
	END

END
