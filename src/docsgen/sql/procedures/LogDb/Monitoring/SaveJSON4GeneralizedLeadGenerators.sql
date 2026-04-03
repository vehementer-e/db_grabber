-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 07.08.2025
-- Description:	Процедура для десереализации JSON-пакета
--				и сохранения данных	по источникам лидгенов
--				в таблицу. Исходный пакет так же сохраняется.
--				== DWH-209 ==
-- =============================================
CREATE PROCEDURE [Monitoring].[SaveJSON4GeneralizedLeadGenerators]
	@json nvarchar(max)
AS
BEGIN
	-- Собираем данные для логирования пакета
	declare @packageGuid uniqueidentifier = cast(JSON_VALUE(@json, '$.meta.guid') as uniqueidentifier)
	declare @FromHost nvarchar(50)				= N'rmq.cm.carmoney.ru'
			, @FromHostVirtualHost nvarchar(50)	= N'/'
			, @FromExchange nvarchar(50)		= N'cmr.contractDebt.1'
			, @FromQueue	nvarchar(50)		= N'dwh.cmr.ContractDebt.1'
			, @FromQueueRoutingKey nvarchar(50)	= N'#'
	drop table if exists #t_generalizedLeadGenerators
	SELECT
		id 			,
		createdAt	,	
		updatedAt	,	
		orderNumber	,
		description	,
		code		,	
		name		,	
		isActive
	INTO #t_generalizedLeadGenerators
	FROM OPENJSON(@json, '$.data')
	WITH (
			id            uniqueidentifier '$.id',
			createdAt     datetime2(0)     '$.attributes.createdAt',
			updatedAt     datetime2(0)     '$.attributes.updatedAt',
			orderNumber   int              '$.attributes.orderNumber',
			[description] nvarchar(150)    '$.attributes.description',
			[code]        nvarchar(9)      '$.attributes.code',
			[name]        nvarchar(150)    '$.attributes.name',
			isActive      bit              '$.attributes.isActive'
	)	--      N'#'
	BEGIN TRY
	-- BEGIN TRAN;
		MERGE LogDb.Monitoring.generalizedLeadGenerators	tgt
		USING #t_generalizedLeadGenerators					src
		ON tgt.id = src.id
		WHEN MATCHED THEN
		UPDATE SET
			tgt.createdAt		= src.createdAt		,
			tgt.updatedAt		= src.updatedAt    	,
			tgt.orderNumber		= src.orderNumber  	,
			tgt.[description]	= src.[description]	,
			tgt.[code]			= src.[code]       	,
			tgt.[name]			= src.[name]       	,
			tgt.isActive		= src.isActive    	
		WHEN NOT MATCHED BY TARGET					
		THEN INSERT(
			id, createdAt, updatedAt, orderNumber, [description],
			[code], [name], isActive)
			VALUES (
			src.id, src.createdAt, src.updatedAt, src.orderNumber,
			src.[description], src.[code], src.[name], src.isActive
		);
		-- Логируем пакет
		exec LogDb.Monitoring.Save_recievedMessage	@FromHost,
													@FromHostVirtualHost,
													@FromExchange,
													@FromQueue,
													@FromQueueRoutingKey,
													@json,
													@packageGuid
	-- COMMIT;
	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0 ROLLBACK;
		DECLARE @msg nvarchar(2048) = ERROR_MESSAGE();
		DECLARE @messageGuid uniqueidentifier
		SELECT  @messageGuid = id FROM #t_generalizedLeadGenerators
		DECLARE @err nvarchar(max) = concat_ws(' | ',
										'Ошибка при обработке пакета',
										concat('packageGuid=', @packageGuid),
										concat('dataId=', @messageGuid),
										@packageGuid)
		; THROW 51000, @err, 1
	END CATCH
END
