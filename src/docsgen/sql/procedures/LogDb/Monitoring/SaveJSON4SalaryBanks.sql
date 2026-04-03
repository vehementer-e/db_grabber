-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 2.10.2025
-- Description:	Процедура для десереализации JSON-пакета
--				и сохранения данных	в таблицу-справочник по 
--				зарплатным Банкам. Исходный пакет так же сохраняется.
--				== DWH-280 ==
-- =============================================
CREATE   PROCEDURE [Monitoring].[SaveJSON4ExternalSalaryBanks] 
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
	DROP TABLE IF EXISTS #t_SalaryBanks
    SELECT
          id
        , createdAt
        , updatedAt
        , orderNumber
        , [description]
        , [code]
        , [name]
        , isActive
        , relevant
    INTO #tSalaryBanks
    FROM OPENJSON(@json,'$.data')
    WITH(
          id            uniqueidentifier  '$.id'
        , createdAt     datetime2(0)      '$.attributes.createdAt'
        , updatedAt     datetime2(0)      '$.attributes.updatedAt'
        , orderNumber   int               '$.attributes.orderNumber'
        , [description] nvarchar(150)     '$.attributes.description'
        , [code]        nvarchar(50)      '$.attributes.code'
        , [name]        nvarchar(150)     '$.attributes.name'
        , isActive      bit               '$.attributes.isActive'
        , relevant      bit               '$.attributes.relevant'
    )
	-- 
	BEGIN TRY
	BEGIN TRAN;
		MERGE Monitoring.salaryBanks AS tgt
        USING #tSalaryBanks			 AS src
           ON tgt.id = src.id
        WHEN MATCHED THEN
          UPDATE SET
                tgt.createdAt   = src.createdAt
              , tgt.updatedAt   = src.updatedAt
              , tgt.orderNumber = src.orderNumber
              , tgt.[description]=src.[description]
              , tgt.[code]      = src.[code]
              , tgt.[name]      = src.[name]
              , tgt.isActive    = src.isActive
              , tgt.relevant    = src.relevant
        WHEN NOT MATCHED BY TARGET
		THEN	INSERT (id,createdAt,updatedAt,orderNumber,[description],[code],[name],isActive,relevant)
				VALUES (src.id,src.createdAt,src.updatedAt,src.orderNumber,src.[description],src.[code],src.[name],src.isActive,src.relevant);

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
		SELECT  @messageGuid = id FROM #tSalaryBanks
		DECLARE @err nvarchar(max) = concat_ws(' | ',
										'Ошибка при обработке пакета',
										concat('packageGuid=', @packageGuid),
										concat('dataId=', @messageGuid),
										@packageGuid, @msg)
		; THROW 51000, @err, 1
	END CATCH
END

