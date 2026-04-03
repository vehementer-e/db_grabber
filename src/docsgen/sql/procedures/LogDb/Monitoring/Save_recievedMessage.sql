-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 01.08.25
-- Description:	Процедура для сохранения JSON пакетов
-- =============================================
CREATE PROCEDURE monitoring.Save_recievedMessage 
	  @FromHost nvarchar(50)
	, @FromHostVirtualHost nvarchar(50)
	, @FromExchange nvarchar(50)
	, @FromQueue	nvarchar(50)
	, @FromQueueRoutingKey nvarchar(50)
	, @ReceivedMessage nvarchar(max)
	, @guid_id uniqueidentifier
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN;
	INSERT INTO LogDb.Monitoring.Recieved_Json_for_directories (
		FromHost,
		FromHostVirtualHost,
		FromExchange,
		FromQueue,
		FromQueueRoutingKey,
		ReceivedMessage,
		guid_id
	) VALUES (
		@FromHost,
		@FromHostVirtualHost,
		@FromExchange,
		@FromQueue,
		@FromQueueRoutingKey,
		@ReceivedMessage,
		@guid_id
	)
	COMMIT;
	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0 ROLLBACK;
		DECLARE @msg nvarchar(2048) = ERROR_MESSAGE();
		DECLARE @err nvarchar(max) = concat_ws(' | ',
										'Ошибка при логировании пакета',
										concat('packageGuid=', @guid_id), @msg)
		; THROW 51000, @err, 1
	END CATCH
END
