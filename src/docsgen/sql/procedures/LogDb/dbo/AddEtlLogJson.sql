CREATE   procedure [dbo].[AddEtlLogJson]
	@LoaderProcessName	nvarchar(255)	, --Название загрузчика, например SSISCRMLoader
	@LoaderProcessGUID	uniqueidentifier,  --uniqueidentifier Генерируется для каждого старта загрузчика
	@ProcessTableName	nvarchar(255) = null	,-- Наименование таблицы
	@ProcessGUID		uniqueidentifier = null,-- Гуид процесса загрузки таблицы - генерируется для каждого процесса загрузки таблицы
	@SSISId				bigint = null, --Id ssis процесса
	@JsonArgs			nvarchar(max)
as
begin

	begin try
		insert into dbo.etlLog(
			EventDateTime,
			EventDate,
			LoaderProcessName, --Название загрузчика, например SSISCRMLoader
			LoaderProcessGUID,  -- Генерируется для каждого старта загрузчика
			ProcessTableName,-- Наименование таблицы
			ProcessGUID, -- Гуид процесса загрузки таблицы - генерируется для каждого процесса загрузки таблицы
			SSISId, --Id ssis процесса
			SessionId, --Id t-sql процесса
			Event, -- started/interrupted/finished
			EventType, -- info/warning/error
			EventDescription, -- детальное сообщение об ошибке/успехе
			ProcessRowsInSrcTableBeforeStart,-- Количество строк в исходной таблице до момента начала загрузки
			ProcessRowsInDstTableBeforeStart,-- Количество строк в таблице приемнике до момента начала загрузки
			ProcessRowsInDstTableAfterFinish,-- Количество строк в таблице приемнике после загрузки
			ProcessAffectedRowsInDstTableDeleted, -- @@RowCount Удаленных строк по предикату
			ProcessAffectedRowsInDstTableInserted, --- @@RowCount добавленных строк по предикату
			ProcessCPUUsed, -- Количество затраченного CPU
			ProcessSqlText,
			ProcessReads  ,
			ProcessWrites ,
			ProcessPhysicalReads ,
			ProcessUsedMemory-- Параметры, которые можно вытащить из свойств запроса, нужны для логирования параметров быстродействия вычисления витрин.
		)

		select 
		EventDateTime = getdate(),
		EventDate = cast(getdate() as date),
		@LoaderProcessName, --Название загрузчика, например SSISCRMLoader
		cast(@LoaderProcessGUID as uniqueidentifier),  -- Генерируется для каждого старта загрузчика
		coalesce(@ProcessTableName, t.ProcessTableName, ''),-- Наименование таблицы
		cast(@ProcessGUID as uniqueidentifier), -- Гуид процесса загрузки таблицы - генерируется для каждого процесса загрузки таблицы
		@SSISId, --Id ssis процесса
		t.SessionId, --Id t-sql процесса
		t.Event, -- started/interrupted/finished
		t.EventType, -- info/warning/error
		t.EventDescription, -- детальное сообщение об ошибке/успехе
		t.ProcessRowsInSrcTableBeforeStart,-- Количество строк в исходной таблице до момента начала загрузки
		t.ProcessRowsInDstTableBeforeStart,-- Количество строк в таблице приемнике до момента начала загрузки
		t.ProcessRowsInDstTableAfterFinish,-- Количество строк в таблице приемнике после загрузки
		t.ProcessAffectedRowsInDstTableDeleted, -- @@RowCount Удаленных строк по предикату
		t.ProcessAffectedRowsInDstTableInserted, --- @@RowCount добавленных строк по предикату
		t.ProcessCPUUsed, -- Количество затраченного CPU
		t.ProcessSqlText,
		t.ProcessReads  ,
		t.ProcessWrites ,
		t.ProcessPhysicalReads ,
		t.ProcessUsedMemory-- Параметры, которые можно вытащить из свойств запроса, нужны для логирования параметров быстродействия вычисления витрин.



	from OPENJSON(@JsonArgs)
		WITH(
			ProcessTableName nvarchar(255)	'$.ProcessTableName',
			SessionId		int				'$.SessionId',							--Id t-sql процесса
			Event			nvarchar(255)	'$.Event',									-- started/interrupted/finished
			EventType		nvarchar(255)	'$.EventType',							-- info/warning/error
			EventDescription nvarchar(max) '$.EventDescription',							-- детальное сообщение об ошибке/успехе
			ProcessRowsInSrcTableBeforeStart bigint '$.ProcessRowsInSrcTableBeforeStart',			-- Количество строк в исходной таблице до момента начала загрузки
			ProcessRowsInDstTableBeforeStart bigint '$.ProcessRowsInDstTableBeforeStart',			-- Количество строк в таблице приемнике до момента начала загрузки
			ProcessRowsInDstTableAfterFinish bigint '$.ProcessRowsInDstTableAfterFinish',			-- Количество строк в таблице приемнике после загрузки
			ProcessAffectedRowsInDstTableDeleted  bigint '$.ProcessAffectedRowsInDstTableDeleted',		-- @@RowCount Удаленных строк по предикату
			ProcessAffectedRowsInDstTableInserted bigint '$.ProcessAffectedRowsInDstTableInserted',	-- @@RowCount добавленных строк по предикату
			ProcessCPUUsed int '$.ProcessCPUUsed',							-- Количество затраченного CPU
			ProcessSqlText nvarchar(max) '$.ProcessSqlText',
			ProcessReads  int '$.ProcessReads',
			ProcessWrites int '$.ProcessWrites',
			ProcessPhysicalReads int'$.ProcessPhysicalReads',
			ProcessUsedMemory	 bigint '$.ProcessUsedMemory'		-- Параметры, которые можно вытащить из свойств запроса, нужны для логирования параметров быстродействия вычисления витрин.
		) t
		

	end try
	begin catch
		;throw
	end catch
end