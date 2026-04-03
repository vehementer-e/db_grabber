-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 2.10.2025
-- Description:	Процедура для десереализации JSON-пакета
--				и сохранения данных	в таблицу-справочник по 
--				Типам продуктов. Исходный пакет так же сохраняется.
--				== DWH-281 ==
-- =============================================
CREATE    PROCEDURE [Monitoring].[SaveJSON4ProductTypes] 
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
	DROP TABLE IF EXISTS #t_ProductTypes
SELECT
          id
        , [name]
        , [code]
        , isNeedPts
        , minSum
        , maxSum
    INTO #t_ProductTypes
    FROM OPENJSON(@json,'$.data')
    WITH(
          id          uniqueidentifier  '$.id'
        , [name]      nvarchar(150)     '$.attributes.name'
        , [code]      nvarchar(50)      '$.attributes.code'
        , isNeedPts   bit               '$.attributes.isNeedPts'
        , minSum      int               '$.attributes.minSum'
        , maxSum      int               '$.attributes.maxSum'
    )
	-- 
	BEGIN TRY
	BEGIN TRAN;
		MERGE Monitoring.productTypes	AS tgt
        USING #t_ProductTypes			AS src
           ON tgt.id = src.id
        WHEN MATCHED THEN
          UPDATE SET
                tgt.[name]    = src.[name]
              , tgt.[code]    = src.[code]
              , tgt.isNeedPts = src.isNeedPts
              , tgt.minSum    = src.minSum
              , tgt.maxSum    = src.maxSum
        WHEN NOT MATCHED BY TARGET THEN
          INSERT (id,[name],[code],isNeedPts,minSum,maxSum)
          VALUES (src.id,src.[name],src.[code],src.isNeedPts,src.minSum,src.maxSum);

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
		SELECT  @messageGuid = id FROM #t_ProductTypes
		DECLARE @err nvarchar(max) = concat_ws(' | ',
										'Ошибка при обработке пакета',
										concat('packageGuid=', @packageGuid),
										concat('dataId=', @messageGuid),
										@packageGuid, @msg)
		; THROW 51000, @err, 1
	END CATCH
END

