-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 09.08.2025
-- Description:	Процедура для десереализации JSON-пакета
--				и сохранения данных	по методам выдачи
--				в таблицу. Исходный пакет так же сохраняется.
--				== DWH-210 ==
-- =============================================
CREATE   PROCEDURE Monitoring.SaveJSON4IssuanceMethods 
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
	-- Десериализация джейсона
	drop table if exists #t_issuanceMethods
	select
		  id			
		, name			
		, description	
		, isActive		
		, code			
	into #t_issuanceMethods
	from openjson(@json, '$.data')
	WITH (
		id            uniqueidentifier '$.id',
		[name]        nvarchar(150)    '$.attributes.name',
		[description] nvarchar(150)    '$.attributes.description',
		isActive      bit              '$.attributes.isActive',
		[code]        nvarchar(50)      '$.attributes.code'
	)
	BEGIN TRY
	BEGIN TRAN;
		MERGE Monitoring.issuanceMethods	tgt
		USING #t_issuanceMethods			src
		ON tgt.id = src.id
		WHEN MATCHED THEN
		UPDATE SET
			tgt.[description]	= src.[description]	,
			tgt.[code]			= src.[code]       	,
			tgt.[name]			= src.[name]       	,
			tgt.isActive		= src.isActive    	
		WHEN NOT MATCHED BY TARGET					
		THEN INSERT(
			id, [description], [code], [name], isActive
		)	VALUES (
			src.id, src.[description], src.[code], src.[name], src.isActive
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
		SELECT  @messageGuid = id FROM #t_issuanceMethods
		DECLARE @err nvarchar(max) = concat_ws(' | ',
										'Ошибка при обработке пакета',
										concat('packageGuid=', @packageGuid),
										concat('dataId=', @messageGuid),
										@packageGuid)
		; THROW 51000, @err, 1
	END CATCH


END
