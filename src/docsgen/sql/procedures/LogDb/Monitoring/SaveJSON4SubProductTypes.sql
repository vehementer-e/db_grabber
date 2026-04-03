-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 2.10.2025
-- Description:	Процедура для десереализации JSON-пакета
--				и сохранения данных	в таблицу-справочник по 
--				Подтипам продуктов. Исходный пакет так же сохраняется.
--				== DWH-219 ==
-- =============================================
CREATE PROCEDURE  [Monitoring].[SaveJSON4SubProductTypes]
	@json nvarchar(max)
AS
BEGIN
	-- Собираем данные для логирования пакета
	DECLARE @packageGuid uniqueidentifier = CAST(JSON_VALUE(@json,'$.meta.guid') AS uniqueidentifier)
	declare @FromHost nvarchar(50)				= N'rmq.cm.carmoney.ru'
			, @FromHostVirtualHost nvarchar(50)	= N'/'
			, @FromExchange nvarchar(50)		= N'cmr.contractDebt.1'
			, @FromQueue	nvarchar(50)		= N'dwh.cmr.ContractDebt.1'
			, @FromQueueRoutingKey nvarchar(50)	= N'#'
	-- Десериализация джейсона
    DROP TABLE IF EXISTS #t_productSubTypes
    SELECT
          id
        , [name]
        , [code]
        , isActive
        , productTypeId
    INTO #t_productSubTypes
    FROM OPENJSON(@json,'$.data')
    WITH(
          id              uniqueidentifier  '$.id'
        , [name]          nvarchar(150)     '$.attributes.name'
        , [code]          nvarchar(50)      '$.attributes.code'
        , isActive        bit               '$.attributes.isActive'
        , productTypeId   uniqueidentifier  '$.relationships.productType.data.id'
    )

    BEGIN TRY
    BEGIN TRAN;
        MERGE LogDb.Monitoring.productSubTypes	AS tgt
        USING #t_productSubTypes				AS src
        ON tgt.id = src.id
        WHEN MATCHED THEN
          UPDATE SET
                tgt.[name]        = src.[name]
              , tgt.[code]        = src.[code]
              , tgt.isActive      = src.isActive
              , tgt.productTypeId = src.productTypeId
        WHEN NOT MATCHED BY TARGET
		THEN INSERT (id,[name],[code],isActive,productTypeId)
			 VALUES (src.id,src.[name],src.[code],src.isActive,src.productTypeId);
		-- Логируем пакет
        COMMIT;
        EXEC Monitoring.Save_recievedMessage	@FromHost,
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
		SELECT  @messageGuid = id FROM #t_productSubTypes
		DECLARE @err nvarchar(max) = concat_ws(' | ',
										'Ошибка при обработке пакета',
										concat('packageGuid=', @packageGuid),
										concat('dataId=', @messageGuid),
										@packageGuid, @msg)
		; THROW 51000, @err, 1
	END CATCH
END
