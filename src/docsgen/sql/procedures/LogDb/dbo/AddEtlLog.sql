
create    procedure [dbo].[AddEtlLog] 
	@LoaderProcessName	nvarchar(255)	, --Название загрузчика, например SSISCRMLoader
	@LoaderProcessGUID	uniqueidentifier,  --uniqueidentifier Генерируется для каждого старта загрузчика
	@ProcessTableName	nvarchar(255) = null	,-- Наименование таблицы
	@ProcessGUID		uniqueidentifier = null,-- Гуид процесса загрузки таблицы - генерируется для каждого процесса загрузки таблицы
	@SessionId			int = null, --Id t-sql процесса
	@SSISId				bigint = null, --Id ssis процесса
	@Event				nvarchar(255), -- started/interrupted/finished
	@EventType			nvarchar(255), -- info/warning/error
	@EventDescription	nvarchar(max) = null, -- детальное сообщение об ошибке/успехе
	@ProcessRowsInSrcTableBeforeStart		bigint = null,-- Количество строк в исходной таблице до момента начала загрузки
	@ProcessRowsInDstTableBeforeStart		bigint = null,-- Количество строк в таблице приемнике до момента начала загрузки
	@ProcessRowsInDstTableAfterFinish		bigint = null,-- Количество строк в таблице приемнике после загрузки
	@ProcessAffectedRowsInDstTableDeleted	bigint = null, -- @@RowCount Удаленных строк по предикату
	@ProcessAffectedRowsInDstTableInserted	bigint = null, --- @@RowCount добавленных строк по предикату
	@ProcessCPUUsed		bigint = null, -- Количество затраченного CPU
	@ProcessSqlText		nvarchar(max) = '',
	@ProcessReads		bigint = null,
	@ProcessWrites		bigint = null,
	@ProcessPhysicalReads bigint = null,
	@ProcessUsedMemory	bigint  = null -- Параметры, которые можно вытащить из свойств запроса, нужны для логирования параметров быстродействия вычисления витрин.
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
			SessionId, --Id t-sql процесса
			SSISId, --Id ssis процесса
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
		@ProcessTableName,-- Наименование таблицы
		cast(@ProcessGUID as uniqueidentifier), -- Гуид процесса загрузки таблицы - генерируется для каждого процесса загрузки таблицы
		@SessionId, --Id t-sql процесса
		@SSISId, --Id ssis процесса
		@Event, -- started/interrupted/finished
		@EventType, -- info/warning/error
		@EventDescription, -- детальное сообщение об ошибке/успехе
		@ProcessRowsInSrcTableBeforeStart,-- Количество строк в исходной таблице до момента начала загрузки
		@ProcessRowsInDstTableBeforeStart,-- Количество строк в таблице приемнике до момента начала загрузки
		@ProcessRowsInDstTableAfterFinish,-- Количество строк в таблице приемнике после загрузки
		@ProcessAffectedRowsInDstTableDeleted, -- @@RowCount Удаленных строк по предикату
		@ProcessAffectedRowsInDstTableInserted, --- @@RowCount добавленных строк по предикату
		@ProcessCPUUsed, -- Количество затраченного CPU
		@ProcessSqlText,
		@ProcessReads  ,
		@ProcessWrites ,
		@ProcessPhysicalReads ,
		@ProcessUsedMemory-- Параметры, которые можно вытащить из свойств запроса, нужны для логирования параметров быстродействия вычисления витрин.


	end try
	begin catch
		;throw
	end catch
end
