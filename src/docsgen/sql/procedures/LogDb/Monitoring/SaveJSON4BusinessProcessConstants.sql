-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 6.08.25
-- Description:	Процедура для десереализации JSON-пакета
--				и сохранения данных	по константам бизнес
--				процессовв таблицу. Исходный пакет
--				так же сохраняется. DWH-218
-- =============================================
CREATE PROCEDURE Monitoring.SaveJSON4BusinessProcessConstants	@json nvarchar(max)
AS
BEGIN
	-- Собираем данные для логирования пакета
	declare @packageGuid uniqueidentifier = cast(JSON_VALUE(@json, '$.meta.guid') as uniqueidentifier)
	declare @FromHost nvarchar(50)				= N'rmq.cm.carmoney.ru'
			, @FromHostVirtualHost nvarchar(50)	= N'/'
			, @FromExchange nvarchar(50)		= N'cmr.contractDebt.1'
			, @FromQueue	nvarchar(50)		= N'dwh.cmr.ContractDebt.1'
			, @FromQueueRoutingKey nvarchar(50)	= N'#'
	-- Десериализация джейсона
	drop table if exists #t_businessProcessConstants
	select
			id            
		,	createdAt     
		,	updatedAt     
		,	orderNumber   
		,	[description] 
		,	[code]        
		,	[name]        
		,	isActive      
		,	value
	INTO #t_businessProcessConstants
	FROM OPENJSON(@json, '$.data')
	WITH (
		  id            uniqueidentifier	'$.id',
	      createdAt     datetime2(0)		'$.attributes.createdAt',
	      updatedAt     datetime2(0)		'$.attributes.updatedAt',
	      orderNumber   int					'$.attributes.orderNumber',
	      [description] nvarchar(150)		'$.attributes.description',
	      [code]        nvarchar(9)			'$.attributes.code',
	      [name]        nvarchar(150)		'$.attributes.name',
	      isActive      bit					'$.attributes.isActive',
		  value			bit					'$.attributes.value'
	)
	BEGIN TRY
	BEGIN TRAN;
		MERGE LogDb.Monitoring.businessProcessConstants	tgt
		USING #t_businessProcessConstants				src
		ON tgt.id = src.id
		WHEN MATCHED THEN
		UPDATE SET
			tgt.id             = src.id           	 ,
			tgt.createdAt      = src.createdAt    	 ,
			tgt.updatedAt      = src.updatedAt    	 ,
			tgt.orderNumber    = src.orderNumber  	 ,
			tgt.[description]  = src.[description]	 ,
			tgt.[code]         = src.[code]       	 ,
			tgt.[name]         = src.[name]       	 ,
			tgt.isActive       = src.isActive     	 ,
			tgt.value		   = src.value
		WHEN NOT MATCHED BY TARGET
		THEN INSERT(
			id, createdAt, updatedAt,
			orderNumber, [description],
			[code], [name],isActive, value
		) Values(
			src.id           	,
			src.createdAt    	,
			src.updatedAt    	,
			src.orderNumber  	,
			src.[description]	,
			src.[code]       	,
			src.[name]       	,
			src.isActive     	,
			src.value
		);
		-- Логируем пакет
		exec LogDb.Monitoring.Save_recievedMessage	@FromHost,
													@FromHostVirtualHost,
													@FromExchange,
													@FromQueue,
													@FromQueueRoutingKey,
													@json,
													@packageGuid
	COMMIT;
	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0 ROLLBACK;
		DECLARE @msg nvarchar(2048) = ERROR_MESSAGE();
		DECLARE @messageGuid uniqueidentifier
		SELECT  @messageGuid = id FROM #t_businessProcessConstants
		DECLARE @err nvarchar(max) = concat_ws(' | ',
										'Ошибка при обработке пакета',
										concat('packageGuid=', @packageGuid),
										concat('dataId=', @messageGuid),
										@packageGuid)
		; THROW 51000, @err, 1
	END CATCH
END
