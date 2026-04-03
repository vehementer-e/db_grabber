CREATE PROCEDURE [RMQ].[Purge_ReceivedMessages_ivr_crm_requests]
    @DaysToKeep int = 14,
    @BatchSize  int = 1000
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cutoff datetime2(3) = DATEADD(DAY, -@DaysToKeep, SYSUTCDATETIME()); 

    DECLARE @rows int = 1;

    WHILE (@rows > 0)
    BEGIN
        DELETE TOP (@BatchSize)
        FROM stg_rmq.rmq.[ReceivedMessages_ivr_crm_requests]
        WHERE ReceiveDate < @cutoff;

        SET @rows = @@ROWCOUNT;

        IF (@rows > 0) WAITFOR DELAY '00:00:01';
    END
END;
