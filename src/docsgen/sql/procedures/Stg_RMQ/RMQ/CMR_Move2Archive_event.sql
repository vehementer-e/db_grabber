CREATE   PROC [RMQ].CMR_Move2Archive_event
	@FromHost				nvarchar(255) = null
  , @FromHostVirtualHost	nvarchar(100) = null
  , @FromExchange			nvarchar(255) = null
  , @FromQueue				nvarchar(255) = null
  , @FromQueueRoutingKey	nvarchar(100) = null
  , @ReceivedMessage		nvarchar(max)
  , @isDebug				int = 0
 WITH EXECUTE AS OWNER
as
BEGIN

SET XACT_ABORT ON

	DECLARE
        @contractGuid UNIQUEIDENTIFIER,
        @contractNumber NVARCHAR(100),
        @eventCode INT,
        @processType NVARCHAR(50);

begin try
	SELECT @isDebug = isnull(@isDebug, 0)

    ---------------------------------------------------------------------
    -- 1) Сохранить исходное сообщение
    ---------------------------------------------------------------------
    INSERT INTO RMQ.ReceivedMessages_CMR_Move2Archive_event (
				ReceiveDate,
				FromHost,
				FromHostVirtualHost,
				FromExchange,
				FromQueue,
				FromQueueRoutingKey,
				ReceivedMessage,
				guid_id,
				isDeleted
	)
    VALUES (
			getdate(),
			@FromHost,
			@FromHostVirtualHost,
			@FromExchange,
			@FromQueue,
			@FromQueueRoutingKey,
			@ReceivedMessage, 
			newid(),
			0
	);

	SELECT @contractGuid = TRY_CONVERT(UNIQUEIDENTIFIER,
                              JSON_VALUE(@ReceivedMessage, '$.data.relationships.contract.data.id')
                            );
	SELECT TOP (1)
            @eventCode = TRY_CONVERT(INT, JSON_VALUE(j.[value], '$.attributes.code'))
        FROM OPENJSON(@ReceivedMessage, '$.included') j
        WHERE JSON_VALUE(j.[value], '$.type') = 'events';

	SELECT
            @processType =
                CASE @eventCode
                    WHEN 3135 THEN N'contractMove2Archive'
                    WHEN 3136 THEN N'ReloadData4StrategyDatamartByContract'
                    ELSE NULL
                END;

	EXEC Stg.etl.runProcessContractUpdate
             @contractGuid = @contractGuid,
             @processType  = @processType;

end try
begin catch
end catch
END
