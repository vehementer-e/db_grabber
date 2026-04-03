-- =============================================
-- Author: Shubkin Aleksandr
-- Create date: 22.04.2025
-- =============================================
CREATE   PROCEDURE [sat].[fill_Клиент_Гражданство]
	@mode INT = 0
AS
BEGIN
BEGIN TRY
DECLARE
@spName NVARCHAR(255) = ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','') + OBJECT_NAME(@@PROCID),
@rowVersion BINARY(8) = 0x0;

    IF OBJECT_ID('sat.Клиент_Гражданство') IS NOT NULL
       OR @mode = 1
    BEGIN
        SET @rowVersion = ISNULL(
            (SELECT MAX(ВерсияДанных) - 1000 
             FROM sat.Клиент_Гражданство),
            0x0
        );
    END

    DROP TABLE IF EXISTS #t_Клиент_Гражданство;

    -- Собираем новые и изменённые записи из hub.Клиенты
    SELECT DISTINCT
        GuidКлиент    = К.GuidКлиент,
        СсылкаКлиент =  К.СсылкаКлиент,
        Гражданство   = c.Ссылка,
        Наименование  = C.Наименование,
        created_at    = CURRENT_TIMESTAMP,
        updated_at    = CURRENT_TIMESTAMP,
        spFillName    = @spName,
        ВерсияДанных  = CAST(Справочник_Партнеры.ВерсияДанных AS BINARY(8))
    INTO #t_Клиент_Гражданство
    FROM hub.Клиенты AS К
	inner join  stg._1cCRM.Справочник_Партнеры   Справочник_Партнеры 
		on Справочник_Партнеры.Ссылка= К.СсылкаКлиент
    INNER JOIN stg._1cCRM.Справочник_СтраныМира AS C
        ON c.Ссылка= Справочник_Партнеры.Гражданство
    WHERE К.ВерсияДанных >= @rowVersion
      AND NULLIF(C.Наименование, '') IS NOT NULL;  -- проверяем не пустую строку

    -- Если таблицы ещё нет, создаём её структуру
    IF OBJECT_ID('sat.Клиент_Гражданство') IS NULL
    BEGIN
        SELECT TOP(0)
            GuidКлиент,
            СсылкаКлиент,
            Гражданство,
            Наименование,
            created_at,
            updated_at,
            spFillName,
            ВерсияДанных
        INTO sat.Клиент_Гражданство
        FROM #t_Клиент_Гражданство;

        ALTER TABLE sat.Клиент_Гражданство
            ALTER COLUMN GuidКлиент UNIQUEIDENTIFIER NOT NULL;

        ALTER TABLE sat.Клиент_Гражданство
            ADD CONSTRAINT PK_Клиент_Гражданство 
                PRIMARY KEY CLUSTERED (GuidКлиент);
    END

    BEGIN TRAN;
        ;MERGE sat.Клиент_Гражданство AS T
        USING #t_Клиент_Гражданство      AS S
          ON T.GuidКлиент = S.GuidКлиент
        WHEN NOT MATCHED THEN
            INSERT 
            (
                GuidКлиент, СсылкаКлиент, Гражданство, Наименование,
                created_at, updated_at, spFillName, ВерсияДанных
            )
            VALUES
            (
                S.GuidКлиент, S.СсылкаКлиент, S.Гражданство, S.Наименование,
                S.created_at,  S.updated_at,  S.spFillName,  S.ВерсияДанных
            )
        WHEN MATCHED AND T.ВерсияДанных <> S.ВерсияДанных THEN
            UPDATE SET
                T.Гражданство  = S.Гражданство,
                T.Наименование = S.Наименование,
                T.updated_at   = S.updated_at,
                T.spFillName   = S.spFillName,
                T.ВерсияДанных = S.ВерсияДанных
        ;
    COMMIT TRAN;
END TRY
BEGIN CATCH
    ----------------------------------------------------
    -- 6) Обработка ошибок
    ----------------------------------------------------
    DECLARE 
        @description NVARCHAR(1024),
        @message     NVARCHAR(1024),
        @eventType   NVARCHAR(50);
		SET @description = 
          'ErrorNumber: '   + CAST(ERROR_NUMBER()   AS NVARCHAR(50)) + CHAR(13)
        + 'ErrorSeverity: ' + CAST(ERROR_SEVERITY() AS NVARCHAR(50)) + CHAR(13)
        + 'ErrorState: '    + CAST(ERROR_STATE()    AS NVARCHAR(50)) + CHAR(13)
        + 'Procedure: '     + ISNULL(ERROR_PROCEDURE(), '')          + CHAR(13)
        + 'Line: '          + CAST(ERROR_LINE()     AS NVARCHAR(50)) + CHAR(13)
        + 'Message: '       + ISNULL(ERROR_MESSAGE(), '');

    SET @message   = 'EXEC ' + @spName;
    SET @eventType = 'Data Vault ERROR';

    EXEC LogDb.dbo.LogAndSendMailToAdmin
        @eventName   = @spName,
        @eventType   = @eventType,
        @message     = @message,
        @description = @description,
        @SendEmail   = 1,
        @SendToSlack = 1;

    IF @@TRANCOUNT > 0
        ROLLBACK TRAN;

    THROW;
END CATCH

END
