-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 12.08.2025
-- Description:	Процедура для десереализации JSON-пакета
--				и сохранения данных	по источникам трафиков
--				в таблицу. Исходный пакет так же сохраняется.
--				== DWH-217 ==
-- =============================================
CREATE   PROCEDURE Monitoring.SaveJSON4LeadGenerators 
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

drop table if exists #t_leadGenerators
select
	  id            
	, codeName		
	, created		
	, updated		
	, syncAt		
	, isActive      
	, authToken		
	, authTarget	
	, isOwn			
INTO #t_leadGenerators
FROM openjson(@json, '$.data')
with (
  id            uniqueidentifier	'$.id'
, codeName		nvarchar(9)			'$.attributes.codeName	'
, created		datetime2(0)    	'$.attributes.created	'
, updated		datetime2(0)		'$.attributes.updated	'
, syncAt		datetime2(0)		'$.attributes.syncAt	'
, isActive      bit					'$.attributes.isActive  '
, authToken		nvarchar(255)		'$.attributes.authToken	'
, authTarget	nvarchar(9)			'$.attributes.authTarget'
, isOwn			bit					'$.attributes.isOwn		'
)

BEGIN TRY
	BEGIN TRAN;
		MERGE LogDb.Monitoring.leadGenerators 	tgt
		USING #t_leadGenerators								src
		ON tgt.id = src.id
		WHEN MATCHED THEN
		UPDATE SET
			tgt.codeName	= src.codeName	,
			tgt.created		= src.created	,
			tgt.updated		= src.updated	,
			tgt.syncAt		= src.syncAt	,
			tgt.isActive	= src.isActive	,
			tgt.authToken	= src.authToken ,
			tgt.authTarget	= src.authTarget,
			tgt.isOwn		= src.isOwn
		WHEN NOT MATCHED BY TARGET					
		THEN INSERT(
			id, codeName, created, updated, syncAt,
			isActive, authToken, authTarget, isOwn		
		) VALUES (
			src.id, src.codeName, src.created, src.updated, src.syncAt,
			src.isActive, src.authToken, src.authTarget, src.isOwn
		);
	COMMIT;
	-- Логируем пакет
	exec LogDb.Monitoring.Save_recievedMessage	@FromHost,
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
		SELECT  @messageGuid = id FROM #t_leadGenerators
		DECLARE @err nvarchar(max) = concat_ws(' | ',
										'Ошибка при обработке пакета',
										concat('packageGuid=', @packageGuid),
										concat('dataId=', @messageGuid),
										@packageGuid)
		; THROW 51000, @err, 1
	END CATCH
END
