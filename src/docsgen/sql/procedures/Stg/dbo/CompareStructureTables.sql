-- =============================================
-- Author:		Котелевец А.В.
-- Create date: 2020-11-03
-- Description:	Проверку на схожесть структур таблиц DWH-769
-- Добавил параметр *db для более корретной работы процедуры сравнение между таблиц в разных бд
-- exec  dbo.CompareStructureTables @sourceTable = 'tmp._1cMFO_Документ_DZ_ПредварительнаяЗаявка', @sourceDb = 'stg',  @targetTable = '_1cMFO.Документ_DZ_ПредварительнаяЗаявка', @targetDb = 'stg'

-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[CompareStructureTables]
--      @sourceTable = <value>,
--      @targetTable = <value>,
--      @sourceDb = null,
--      @targetDb = null,
--      @excludeColumns = '';
-- Параметры соответствуют объявлению процедуры ниже.
CREATE PROC [dbo].[CompareStructureTables]
	@sourceTable varchar(255)
	,@targetTable varchar(255)
	,@sourceDb varchar(255) = null
	,@targetDb varchar(255) = null
	,@excludeColumns varchar(max) = ''
	
as 
begin
	set nocount on;
	declare @msg nvarchar(max)
		,@sourceTableId int = OBJECT_ID(@sourceDb+'.'+@sourceTable)
		,@targetTableId int = OBJECT_ID(@targetDb+'.'+@targetTable)
		,@cmdGetTableColumns nvarchar(max) = '
	select name as columnName from @dbName.sys.all_columns
	where object_id = @tableId
		AND isnull(is_computed, 0) = 0
	'
	declare @sourceTableColumns table(ColumnName varchar(255))
	declare @targetTableColumns table(ColumnName varchar(255))

	declare @excludeTargetColumns table(name varchar(255))
	insert into @excludeTargetColumns(name)
	select ColumnName from (values
		('InsertToDwhDate'),
		('DWHInsertedDate'),
		('DWHInsertedDate1'),
		('ProcessGUID'),
		('ProcessGUID1'),
		('UPDATED_BY'),
		('UPDATED_DT'),
		('xmin')
		) t(ColumnName)
	union
	select 
	REPLACE(
		REPLACE(
			REPLACE(
				REPLACE(
					TRIM(Value)
						, ']','')
							, '[', '')
							,CHAR(13),'')
								,CHAR(10),'')
			
			from STRING_SPLIT(@excludeColumns, ',')
begin try
	
	
	--Проверка на существование таблиц.
	if @sourceTableId	is null
		Raiserror('Таблица (sourceTable) %s в %s не найдена. OBJECT_ID is null', 16,1, @sourceTable, @sourceDb)
	if @targetTableId	is null	
		Raiserror('Таблица (targetTable) %s в %s не найдена. OBJECT_ID is null', 16,1, @targetTable, @targetDb)
	--получаем список колонок для исходной таблицы
	set @cmdGetTableColumns = REPLACE(@cmdGetTableColumns, '@dbName', @sourceDb)
	
	insert into @sourceTableColumns
	EXECUTE sp_executesql  @cmdGetTableColumns, N'@tableId int', @tableId = @sourceTableId;
	set @cmdGetTableColumns = REPLACE(@cmdGetTableColumns, @sourceDb, '@dbName')
	
	if not exists(select top(1) 1 from @sourceTableColumns)
	begin
		Raiserror('Не удалось получить список колонок для (sourceTable) %s в бд %s', 16,1, @sourceTable, @sourceDb)
	end
	delete from @sourceTableColumns
		where  ColumnName in (select name from @excludeTargetColumns)

	
	--получаем список колонок для целевой таблицы
	set @cmdGetTableColumns = REPLACE(@cmdGetTableColumns, '@dbName', @targetDb)
	insert into @targetTableColumns
	EXECUTE sp_executesql  @cmdGetTableColumns, N'@tableId int', @tableId = @targetTableId;
	set @cmdGetTableColumns = REPLACE(@cmdGetTableColumns, @targetDb, '@dbName')
	
	if not exists(select top(1) 1 from @targetTableColumns)
	begin
		Raiserror('Не удалось получить список колонок для (targetTable) %s в бд %s', 16,1, @targetTable, @targetDb)
	end

	delete from @targetTableColumns
		where  ColumnName in (select name from @excludeTargetColumns)

	--Сравниваем стуктуру 2х таблиц
	--Если есть колонки в @targetTable, но нет в @sourceTable записываем их в @foundOnlyInTarget
	declare @foundOnlyInTarget varchar(1000) = (
		select trim(stuff(
			(select ', ' + columnName AS [text()]
			from (
				select ColumnName from @targetTableColumns
	
				except
				select ColumnName as columnName from @sourceTableColumns
			) t
		FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'),1,1,'')
	))
	--Сравниваем стуктуру 2х таблиц
	--Если есть колонки в @sourceTable, но нет в @targetTable записываем их в @foundOnlySourceTable
	declare @foundOnlySourceTable varchar(1000)  = (
		select trim(stuff(
			(select ', ' + columnName AS [text()]
			from (
				select columnName from @sourceTableColumns
				except
				select columnName from @targetTableColumns
			) t
		FOR XML PATH(''), TYPE).value('.', 'VARCHAR(MAX)'),1,1,'')
	))
	
	--
	if COALESCE (@foundOnlyInTarget, @foundOnlySourceTable) IS NOT NULL
	BEGIN
		 
		set @msg='Обнаружена разница в структурe таблиц ' + @sourceTable + ' и ' + @targetTable
			+ ISNULL(' В исходной  ' + @sourceTable + 'таблице отсутствуют следующие столбцы \"' + @foundOnlyInTarget + '\";', '')
			+ ISNULL(' В целевой ' + @targetTable + ' таблице отсутствуют следующие столбцы \"' + @foundOnlySourceTable + '\";', '')
		
	END
	select @foundOnlyInTarget as NotFoundInSourceTable, @foundOnlySourceTable as NotFoundInTargetTable, @msg as msg
	--Если разница есть, отправляем уведомление в Slack - канала DwhAlerts
	
	
end try

begin catch
	set @msg= ERROR_MESSAGE()
	--EXEC LogDb.dbo.[SendToSlack_DwhAlerts]
	--	@text = @msg
	;throw
end catch

end
