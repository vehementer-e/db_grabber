-- =============================================
-- Author:		Aleksandr Shubkin
-- Create date: 2026-01-28
-- Description:	Процедура для реализвации мониторинга: 
--				Остаток ОД!=Сумме Выдачи - на момент выдачи договора
--				В случае наличия 
-- =============================================

create     PROCEDURE [Monitoring].[DQ_dm_CMRStatBalance_Compare_remainOD_N_Amount] 
	   @recipients    nvarchar(max) =null
    , @emailSubject  nvarchar(255) = N'Остаток ОД!=Сумме Выдачи - на момент выдачи договора'
	, @isDebug		 bit = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE
		--   @recipients    nvarchar(max) = N'a.shubkin@smarthorizon.ru'
		-- , @emailSubject  nvarchar(255) = N'Продажа договоров'
		  @tableTitle    nvarchar(255) = N'Остаток ОД!=Сумме Выдачи - на момент выдачи договора'
		, @tableSubject  nvarchar(255) = CAST(GETDATE() as date)
		, @html_result   nvarchar(max)
		, @SQLQuery      nvarchar(3000)

	IF @recipients is null SET 	@recipients = N'dwh112@carmoney.ru'
	BEGIN TRY
		DROP TABLE IF EXISTS #t_base
		SELECT
			  [остаток од]
			, [Сумма Займа]		= Сумма
			, diff				= [остаток од] -Сумма
			,	b.d
			,	b.ContractEndDate
			,	b.external_id
			,	b.CMRContractsGUID
		INTO #t_base
		FROM dwh2.dbo.dm_cmrstatbalance b
		INNER JOIN (
			SELECT 
				  first_day = min(d)
				, external_id
			FROM  dwh2.dbo.dm_cmrstatbalance b
			where [остаток од]>Сумма
			GROUP BY external_id
		) b1 ON b1.external_id = b.external_id 
			and b1.first_day   = b.d
		if exists (select top(1) 1 from #t_base)
		begin
		DECLARE
			@sql4query nvarchar(max),
			@table_name sysname

		SET @table_name = concat(N'##t_contrats_w_nonmatched_sumNsleft_', replace(cast(newid() as nvarchar(36)), '-', '_'))
		SET @sql4query = 
			concat_ws(' ',
				N'SELECT
					  [#]					    = ROW_NUMBER() OVER(Order by tb.d, tb.external_id)
					, [Договор]					= tb.external_id
					, [Сумма займа]
					, [Остаток ОД]
					, [Разница]					= diff
					, [Дата договора]			= tb.d
					, [Дата закрытия договора]	= tb.ContractEndDate
				  INTO', QUOTENAME(@table_name)
			   , 'FROM #t_base tb');
		
		EXEC sys.sp_executesql @sql4query;
		SET @SQLQuery = CONCAT_WS(' ', 
									 N'SELECT f.* FROM'
								   , QUOTENAME(@table_name), 'f'
								   , 'ORDER BY [#]'
							);
		EXEC LogDb.dbo.ConvertQuery2HTMLTable
			     @SQLQuery      = @SQLQuery
			    ,@title         = @tableTitle
			    ,@tableSubject  = @tableSubject
			    ,@isDebug       = @isDebug
			    ,@html_result   = @html_result OUT;
		
		EXEC msdb.dbo.sp_send_dbmail
				 @recipients   = @recipients
				,@body         = @html_result
				,@body_format  = 'HTML'
				,@subject      = @emailSubject;

		--Перегрузить данные если сработал мониторинг
	IF @isDebug = 0
		--пока не перегружать
		--AND 1=2
	BEGIN
		declare @contractGuid nvarchar(36)
			, @processType nvarchar(36)= 'ReloadData4StrategyDatamartByContract'
		DECLARE cur_contract CURSOR FOR
		
		select top(100) 
		contractGuid = CMRContractsGUID 
		  , processType = CASE
                  WHEN t.ContractEndDate IS NOT NULL THEN N'contractMove2Archive'
													  ELSE N'ReloadData4StrategyDatamartByContract'
              END 
		from (SELECT DISTINCT CMRContractsGUID, ContractEndDate
		FROM #t_base AS C
		) t
		

		OPEN cur_contract
		FETCH NEXT FROM cur_contract INTO @contractGuid, @processType
		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC Stg.etl.runProcessContractUpdate 
				@contractGuid = @contractGuid,
				--@processType = 'ReloadData4StrategyDatamartByContract'
				@processType = @processType

			FETCH NEXT FROM cur_contract INTO @contractGuid, @processType
		END

		CLOSE cur_contract
		DEALLOCATE cur_contract
	END

		end
		IF @isDebug = 1
		BEGIN
		    SELECT @SQLQuery     AS Debug_SQLQuery;
		    SELECT @emailSubject AS Debug_Subject;
		    SELECT @recipients   AS Debug_Recipients;
			SELECT @html_result  AS Debug_html_result;
		END
	END TRY
	BEGIN CATCH
	    ;THROW;
	END CATCH
END
