-- =============================================
-- Author:		shubkin aleksandr
-- Create date: 12.12.2025
-- Description:	Процедура для заполнения таблицы dwh2.[sat].[ЗаявкаНаЗаймПодПТС_eqxScoreGroup]
-- =============================================
CREATE    PROCEDURE [sat].[fill_ЗаявкаНаЗаймПодПТС_eqxScoreGroup] 
	 @mode int = 1
AS
BEGIN
	--set nocount on;
	BEGIN TRY
	DECLARE
		@spName        NVARCHAR(255) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','') + OBJECT_NAME(@@PROCID)
      , @rowVersion  binary(8) = 0x0;

	IF OBJECT_ID('sat.Заявка_eqxScoreGroupUnsecured') IS NOT NULL
		AND @mode = 1
	BEGIN
	    SELECT @rowVersion =max([ВерсияДанных]-10)
	    FROM   dwh2.sat.ЗаявкаНаЗаймПодПТС_eqxScoreGroup
	end
	SELECT @rowVersion = isnull(@rowVersion, 0x0);

	DROP TABLE IF EXISTS #t_changes;

    SELECT
          Заявка.СсылкаЗаявки
        , Заявка.GuidЗаявки
        , loginom.eqxScoreGroupUnsecured
        , loginom.Call_date      AS [date]
		, rowVersion = loginom.rowver
        , ROW_NUMBER() OVER (
                PARTITION BY loginom.guid
                ORDER BY loginom.Call_date DESC
          ) AS rn
    INTO #t_changes
    FROM dwh2.hub.Заявка AS Заявка
    INNER JOIN stg._loginom.Originationlog AS loginom
        ON Заявка.GuidЗаявки = loginom.guid
       AND loginom.eqxScoreGroupUnsecured IS NOT NULL
	   and loginom.rowver >= @rowVersion
	   and  (isnull(loginom.number,-1) not in (19061300000088) )

	CREATE CLUSTERED INDEX IX_t_changes_GuidDate ON #t_changes (GuidЗаявки);

	DELETE FROM #t_changes
	WHERE rn>1;

  --  DROP TABLE IF EXISTS #t_Заявка_eqxScoreGroupUnsecured;
  --  SELECT DISTINCT
 
  --  INTO #t_Заявка_eqxScoreGroupUnsecured
  --  FROM #t_changes tc; 
   
	  BEGIN TRAN;
		  if @mode =0
		  begin
			truncate table 	 [sat].[ЗаявкаНаЗаймПодПТС_eqxScoreGroup]
		  end
            ;MERGE [sat].[ЗаявкаНаЗаймПодПТС_eqxScoreGroup]   AS T
            USING 
			(
				select 
					  [СсылкаЗаявки]				= tc.СсылкаЗаявки
					, [eqxScoreGroupUnsecured]		= tc.eqxScoreGroupUnsecured
					, [GuidЗаявки]					= tc.GuidЗаявки
					, [date]						= tc.[date]
					, [created_at]					= GETDATE()
					, [updated_at]					= GETDATE()
					, [spFillName]					= @spName
					, [ВерсияДанных]				= tc.rowVersion
				from #t_changes	   tc
			)	AS S
               ON  T.GuidЗаявки = S.GuidЗаявки
            WHEN NOT MATCHED BY TARGET THEN
                INSERT
                (
                      СсылкаЗаявки
                    , GuidЗаявки
                    , eqxScoreGroupUnsecured
                    , [date]
                    , created_at
                    , updated_at
                    , spFillName
					, [ВерсияДанных]
                )
                VALUES
                (
                      S.СсылкаЗаявки
                    , S.GuidЗаявки
                    , S.eqxScoreGroupUnsecured
                    , S.[date]
                    , S.created_at
                    , S.updated_at
                    , S.spFillName
					, s.[ВерсияДанных]
                )
            WHEN MATCHED
				AND (
					ISNULL(T.[ВерсияДанных], 0x0)	<> ISNULL(S.[ВерсияДанных], 0x0)
			)
			THEN UPDATE SET
                  T.СсылкаЗаявки            = S.СсылкаЗаявки
                , T.eqxScoreGroupUnsecured  = S.eqxScoreGroupUnsecured
                , T.[date]                  = S.[date]
                , T.updated_at              = S.updated_at
                , T.spFillName              = S.spFillName
                , T.[ВерсияДанных]          = S.[ВерсияДанных];

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        DECLARE 
              @description NVARCHAR(1024)
            , @message     NVARCHAR(1024)
            , @eventType   NVARCHAR(50);
		SET @description = CONCAT(
              'ErrorNumber: '   , CAST(ERROR_NUMBER()   AS NVARCHAR(50)), CHAR(13)
            , 'ErrorSeverity: ' , CAST(ERROR_SEVERITY() AS NVARCHAR(50)), CHAR(13)
            , 'ErrorState: '    , CAST(ERROR_STATE()    AS NVARCHAR(50)), CHAR(13)
            , 'Procedure: '     , ISNULL(ERROR_PROCEDURE(), ''),          CHAR(13)
            , 'Message: '       , ISNULL(ERROR_MESSAGE(), '')
        );

        SET @message   = 'EXEC ' + @spName;
        SET @eventType = 'Data Vault ERROR';

        EXEC LogDb.dbo.LogAndSendMailToAdmin
              @eventName   = @spName
            , @eventType   = @eventType
            , @message     = @message
            , @description = @description
            , @SendEmail   = 1
            , @SendToSlack = 1;

        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        THROW;
    END CATCH
END
