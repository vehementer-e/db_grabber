-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[deleteOldDraftCommunications];
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROCEDURE [dbo].[deleteOldDraftCommunications]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET DEADLOCK_PRIORITY LOW;

    DECLARE 
        @BatchSize       INT = 5000,
        @RowsDeleted     INT = 1,
        @CutoffDate      DATETIME2(0) = DATEADD(DAY, -3, SYSUTCDATETIME());

    WHILE (@RowsDeleted > 0)
    BEGIN
        ;WITH cte AS
        (
            SELECT TOP (@BatchSize)
                   c.guid
            FROM stg._COMCENTER.communications c WITH (READPAST)
            WHERE c.communication_status_guid = 'b62c74b4-5921-11eb-bd83-0242ac130006'
              AND c.created_at < @CutoffDate
        )
        DELETE c
        FROM 
			stg._COMCENTER.communications c WITH (READPAST)
		where exists(select 1 from cte x where c.guid = x.guid)

        SET @RowsDeleted = @@ROWCOUNT;

        IF (@RowsDeleted > 0)
        BEGIN
            WAITFOR DELAY '00:00:01';
        END
    END
END
