-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 09.08.2025
-- Description:	Процедура для десереализации JSON-пакета
--				и сохранения данных	по регионам
--				в таблицу. Исходный пакет так же сохраняется.
--				== DWH-211 ==
-- =============================================
CREATE   PROCEDURE [Monitoring].[SaveJSON4Regions] 
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

	drop table if exists #t_regions
	select
		  id				
		, name			
		, isActive		
		, gmt				
		, regionCode		
		, fiascode		
		, isBusinessRegion
		, sortOrder
	into #t_regions
	from  OPENJSON(@json, '$.data')
	with (
		  id				uniqueidentifier  '$.id'
		, name				nvarchar(150)	  '$.attributes.name'
		, isActive			bit				  '$.attributes.isActive'
		, gmt				time(0)			  '$.attributes.gmt'
		, regionCode		smallint		  '$.attributes.regionCode'
		, fiascode			uniqueidentifier  '$.attributes.fiasCode'
		, isBusinessRegion	bit				  '$.attributes.isBusinessRegion'
		, sortOrder			smallint		  '$.attributes.sortOrder'
	)

	BEGIN TRY
	BEGIN TRAN;
		MERGE LogDb.Monitoring.regions	tgt
		USING #t_regions				src
		ON tgt.id = src.id
		WHEN MATCHED THEN
		UPDATE SET
			  tgt.[name]			= src.[name]       	
			, tgt.isActive			= src.isActive		
			, tgt.gmt				= src.gmt				
			, tgt.regionCode		= src.regionCode		
			, tgt.fiascode			= src.fiascode			
			, tgt.isBusinessRegion	= src.isBusinessRegion	
			, tgt.sortOrder			= src.sortOrder			  	
		WHEN NOT MATCHED BY TARGET					
		THEN INSERT(
			id, name, gmt, isActive,				
			regionCode, fiascode,			
			isBusinessRegion, sortOrder			
		)	VALUES (
			src.id, src.name, src.gmt, src.isActive, 			
			src.regionCode, src.fiascode,			
			src.isBusinessRegion, src.sortOrder
			
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
		SELECT  @messageGuid = id FROM #t_regions
		DECLARE @err nvarchar(max) = concat_ws(' | ',
										'Ошибка при обработке пакета',
										concat('packageGuid=', @packageGuid),
										concat('dataId=', @messageGuid),
										@packageGuid)
		; THROW 51000, @err, 1
	END CATCH

END
