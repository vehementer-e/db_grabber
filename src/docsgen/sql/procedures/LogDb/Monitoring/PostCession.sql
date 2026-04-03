-- =============================================
-- Author:		Aleksandr Shubkin
-- Create date: 2026-01-27
-- Description:	Мониторинг по договорам после цесси
-- =============================================
CREATE   PROCEDURE [Monitoring].[PostCession] 
      @recipients    nvarchar(max) =null
    , @emailSubject  nvarchar(255) = N'Сверка Документ_ПродажаДоговоров vs dm_CMRStatBalance'
	, @isDebug		 bit = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE
		--   @recipients    nvarchar(max) = N'a.shubkin@smarthorizon.ru'
		-- , @emailSubject  nvarchar(255) = N'Продажа договоров'
		  @tableTitle    nvarchar(255) = N'Продажа договоров'
		, @tableSubject  nvarchar(255) = CAST(GETDATE() as date)
		, @html_result   nvarchar(max)
		, @SQLQuery      nvarchar(3000)

	IF @recipients is null SET 	@recipients = N'dwh112@carmoney.ru'

BEGIN TRY
	DROP TABLE IF EXISTS #typeshit
	SELECT
		[ДоговорGUID]		=  stg.dbo.getGUIDFrom1C_IDRREF(l.Договор) 
	  , [Дата продажи]		=  cast(dateadd(year, -2000, d.Дата) as date)
	  , [Цена продажи]		=  CAST(l.СуммаПродажи AS money)
	  , [Цена продажи ОД]   = CAST(l.СуммаОД      AS money)
	INTO #typeshit
	FROM stg._1cCMR.Документ_ПродажаДоговоров d
	LEFT JOIN stg._1cCMR.Документ_ПродажаДоговоров_Договоры l ON l.Ссылка = d.Ссылка;
	
	DROP TABLE IF EXISTS #t_final
	SELECT 
	   [#]      = ROW_NUMBER() OVER (order by tpsh.[Дата продажи], sb.external_id)
	 , [Договор]		= sb.external_id
	 , tpsh.[Дата продажи]
	 , tpsh.[Цена продажи]
	 , [Значение в pay_total] = sb.pay_total
	 , tpsh.[Цена продажи ОД]
	 , [ОплаченоОД]    = cast(sb.[Основной долг уплачено] as money)
	 , [Оплачено %]    = cast(sb.[Проценты уплачено] as money)
	INTO #t_final
	FROM #typeshit tpsh
	inner  JOIN dwh2.dbo.dm_CMRStatBalance sb
		ON	sb.CMRContractsGUID = tpsh.ДоговорGUID 
		and sb.d				= tpsh.[Дата продажи]
	WHERE sb.pay_total <> tpsh.[Цена продажи];

	DECLARE 
		@table_name sysname,
		@sql4final nvarchar(max)
	SET @table_name = concat(N'##t_final_', cast(newid() as nvarchar(36)))
	SET @sql4final = concat_ws(' ', N'select f.* INTO', QUOTENAME(@table_name), 'from #t_final f')
	EXEC sys.sp_executesql @sql4final;
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
