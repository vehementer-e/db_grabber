-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 2.10.2025
-- Description:	Процедура для десереализации JSON-пакета
--				и сохранения данных	в таблицу-справочник по 
--				СПБ банкам. Исходный пакет так же сохраняется.
--				== DWH-279 ==
-- =============================================
CREATE   PROCEDURE [Monitoring].[SaveJSON4SbpBanks] 
	@json nvarchar(max)
AS
BEGIN
	SET NOCOUNT ON;
	-- Собираем данные для логирования пакета
	declare @packageGuid uniqueidentifier = cast(JSON_VALUE(@json, '$.meta.guid') as uniqueidentifier)
	declare @FromHost nvarchar(50)				= N'rmq.cm.carmoney.ru'
			, @FromHostVirtualHost nvarchar(50)	= N'/'
			, @FromExchange nvarchar(50)		= N'cmr.contractDebt.1'
			, @FromQueue	nvarchar(50)		= N'dwh.cmr.ContractDebt.1'
			, @FromQueueRoutingKey nvarchar(50)	= N'#'
	-- Десериализация джейсона
	DROP TABLE IF EXISTS #t_SbpBanks
    SELECT
          id
        , abbr
        , [name]
        , [code]
        , nativeName
        , orderNumber
        , isActive
        , fileId
    INTO #t_SbpBanks
    FROM OPENJSON(@json,'$.data')
    WITH(
          id          uniqueidentifier  '$.id'
        , abbr        nvarchar(50)      '$.attributes.abbr'
        , [name]      nvarchar(150)     '$.attributes.name'
        , [code]      nvarchar(50)      '$.attributes.code'
        , nativeName  nvarchar(150)     '$.attributes.nativeName'
        , orderNumber int               '$.attributes.orderNumber'
        , isActive    bit               '$.attributes.isActive'
        , fileId      uniqueidentifier  '$.relationships.file.data.id'
    );
	-- 
	BEGIN TRY
	BEGIN TRAN;
		MERGE LogDb.Monitoring.sbpBanks	AS tgt
        USING #t_SbpBanks					AS src
           ON tgt.id = src.id
        WHEN MATCHED THEN
          UPDATE SET
                tgt.abbr        = src.abbr
              , tgt.[name]      = src.[name]
              , tgt.[code]      = src.[code]
              , tgt.nativeName  = src.nativeName
              , tgt.orderNumber = src.orderNumber
              , tgt.isActive    = src.isActive
              , tgt.fileId      = src.fileId
        WHEN NOT MATCHED BY TARGET
		THEN INSERT (id,abbr,[name],[code],nativeName,orderNumber,isActive,fileId)
			 VALUES (src.id,src.abbr,src.[name],src.[code],src.nativeName,src.orderNumber,src.isActive,src.fileId);
        COMMIT;
		-- Логируем пакет
		exec LogDb.Monitoring.Save_recievedMessage	 @FromHost,
													 @FromHostVirtualHost,
													 @FromExchange,
													 @FromQueue,
													 @FromQueueRoutingKey,
													 @json,
													 @packageGuid
	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0 ROLLBACK;
		DECLARE @msg nvarchar(2048) = ERROR_MESSAGE();
		DECLARE @messageGuid uniqueidentifier
		SELECT  @messageGuid = id FROM #t_SbpBanks
		DECLARE @err nvarchar(max) = concat_ws(' | ',
										'Ошибка при обработке пакета',
										concat('packageGuid=', @packageGuid),
										concat('dataId=', @messageGuid),
										@packageGuid, @msg)
		; THROW 51000, @err, 1
	END CATCH
END

