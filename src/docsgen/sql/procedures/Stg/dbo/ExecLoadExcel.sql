/*
DECLARE @ReturnCode int, @ReturnMessage varchar(8000)
EXEC dbo.ExecLoadExcel
	@PathName = '\\10.196.41.14\DWHFiles\Test\',
	@FileName = 'TestFile1.xlsx',
	@SheetName = 'Лист1$',
	@TableName = '##t1', --'files.TestFile1', 
	@isMoveFile = 0, -- 0 - не перемещать исходный файл, 1 - перемещение исходного файла, значение по умолчанию 1
	@ReturnCode = @ReturnCode OUTPUT,
	@ReturnMessage = @ReturnMessage OUTPUT
SELECT 'ReturnCode' = @ReturnCode, 'ReturnMessage' = @ReturnMessage
*/
-- =============================================
-- Author:		А.Никитин
-- Create date: 21.03.2022
-- Description:	DWH-1564 Загрузка Excel файла в таблицу
-- =============================================
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[ExecLoadExcel] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROC [dbo].[ExecLoadExcel]
	@PathName nvarchar(1000),
	@FileName nvarchar(1000),
	@SheetName nvarchar(1000),
	@TableName nvarchar(1000),
	@isMoveFile bit = 'true',
	@ReturnCode int = NULL OUTPUT, -- возвращаемый код, 0 - без ошибок
	@ReturnMessage varchar(8000) = NULL OUTPUT -- возвращаемое сообщение
WITH EXECUTE AS 'dbo'
AS						  
SET NOCOUNT ON;
SET XACT_ABORT ON
BEGIN
	 SELECT USER_NAME();  
BEGIN TRY
	DECLARE @ErrorMessage  nvarchar(4000), @ErrorSeverity int, @ErrorState int, @ErrorNumber int
	DECLARE @Error_Procedure nvarchar(128), @Error_Line int
	DECLARE @status_table table(status_code int, status_name varchar(30))
	DECLARE @scheme varchar(1000), @ParamTableName nvarchar(1000), @Mode varchar(30), @Sql nvarchar(4000)
	DECLARE @ParmDefinition nvarchar(1000)
	DECLARE @execution_id bigint

	INSERT @status_table(status_code, status_name)
	VALUES 
	(1, 'создана (1)'),
	(2, 'запущена (2)'),
	(3, 'отменена (3)'),
	(4, 'завершена неуспешно (4)'),
	(5, 'ожидает (5)'),
	(6, 'завершена непредвиденно (6)'),
	(7, 'выполнена успешно (7)'),
	(8, 'остановлена (8)'),
	(9, 'завершена (9)')

	--проверка параметров
	SELECT @ReturnCode = 0

	IF trim(isnull(@FileName, '')) = ''
	BEGIN
		SELECT @ReturnCode = 1, @ReturnMessage = 'Ошибка. Не задан обязательный параметр @FileName.'
		RETURN @ReturnCode
	END

	IF trim(isnull(@SheetName, '')) = ''
	BEGIN
		SELECT @ReturnCode = 1, @ReturnMessage = 'Ошибка. Не задан обязательный параметр @SheetName.'
		RETURN @ReturnCode
	END

	IF trim(isnull(@TableName, '')) = ''
	BEGIN
		SELECT @ReturnCode = 1, @ReturnMessage = 'Ошибка. Не задан обязательный параметр @TableName.'
		RETURN @ReturnCode
	END

	SELECT @TableName = trim(@TableName)

	IF left(@TableName, 2) = '##' BEGIN
		SELECT @Mode = 'temp'
	END
	ELSE BEGIN
		SELECT @Mode = 'permanent'
	END


	IF @Mode = 'temp' BEGIN
		SELECT @ParamTableName = 'files.TMP_' + left(convert(varchar(36), newid()), 8)
		SELECT @Sql = 'DROP TABLE IF EXISTS ' + @ParamTableName
		EXEC(@Sql)
	END

	IF @Mode = 'permanent' BEGIN
		SELECT @scheme = A.TableName_Part
		FROM (
			SELECT
				Ordinal_Position = row_number() OVER(ORDER BY getdate()),
				TableName_Part = trim(S.value)
			FROM string_split(@TableName, '.') AS S
			WHERE trim(isnull(S.value, '')) <> ''
			) AS A
		WHERE A.Ordinal_Position = 1

		IF lower(@scheme) <> 'files'
		BEGIN
			SELECT @ReturnCode = 1, @ReturnMessage = 'Ошибка. Таблица @TableName должна быть в схеме files.'
			RETURN @ReturnCode
		END

		SELECT @ParamTableName = @TableName
	END
	--//end проверка параметров

	SELECT @Sql = '
	USE SSISDB  		   
	EXECUTE AS LOGIN =''CARM\adm_antoshchuk''

	EXEC [SSISDB].[catalog].[create_execution] 
		@package_name=N''Load_Excel.dtsx'', 
		@execution_id=@execution_id OUTPUT, 
		@folder_name=N''ETL'', 
		@project_name=N''Load_Excel'', 
		@use32bitruntime=False, 
		@reference_id=NULL, 
		@runinscaleout=False

	DECLARE @var0 sql_variant = convert(sql_variant, concat_ws(''\'', @PathName, @FileName))
	EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id,  @object_type=30, @parameter_name=N''FileName'', @parameter_value=@var0

	DECLARE @var1 sql_variant = convert(sql_variant, @SheetName)
	EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id,  @object_type=30, @parameter_name=N''SheetName'', @parameter_value=@var1

	DECLARE @var2 sql_variant = convert(sql_variant, @ParamTableName)
	EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id,  @object_type=30, @parameter_name=N''TableName'', @parameter_value=@var2

	DECLARE @var3 sql_variant = convert(sql_variant, @isMoveFile)
	EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id,  @object_type=30, @parameter_name=N''isMoveFile'', @parameter_value=@var3

	DECLARE @var4 smallint = 1
	EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id,  @object_type=50, @parameter_name=N''LOGGING_LEVEL'', @parameter_value=@var4

	EXEC [SSISDB].[catalog].[start_execution] @execution_id'

	SELECT @ParmDefinition = '@execution_id bigint OUT, @PathName nvarchar(1000), @FileName nvarchar(1000), @SheetName nvarchar(1000), @ParamTableName nvarchar(1000), @isMoveFile bit'

	EXECUTE sp_executesql @Sql, @ParmDefinition, 
		@execution_id = @execution_id OUT,
		@PathName = @PathName, 
		@FileName = @FileName,
		@SheetName = @SheetName,
		@ParamTableName = @ParamTableName,
		@isMoveFile = @isMoveFile
	print @execution_id
	select @execution_id
	DECLARE @status int, @isError int

	WHILE 1=1
	BEGIN

		SELECT @status = O.status
		FROM SSISDB.catalog.operations AS O
		WHERE O.operation_id = @execution_id

		IF @status IS NULL BEGIN
			BREAK
		END

		/*
		status (Состояние операции) Возможными значениями являются: 
		создана (1), 
		запущена (2), 
		отменена (3), 
		завершена неуспешно (4), 
		ожидает (5), 
		завершена непредвиденно (6), 
		выполнена успешно (7), 
		остановлена (8) 
		завершена (9).
		*/

		IF @status IN (
			3, --отменена (3), 
			4, --завершена неуспешно (4), 
			6, --завершена непредвиденно (6), 
			8, --остановлена (8) 
			9, --завершена (9).
			7 --выполнена успешно (7)
		)
		BEGIN
			SELECT @isError = 1
			BREAK
		END

		--выполнена успешно (7), 
		IF @status IN (
			7 --выполнена успешно (7), 
		)
		BEGIN
			SELECT @isError = 0
			BREAK
		END

		--создана (1), 
		--запущена (2), 
		--ожидает (5), 
		--продолжаем циклиться
		WAITFOR DELAY '00:00:05'
	END

	IF @isError = 0
		AND EXISTS(
			SELECT TOP(1) 1
			FROM SSISDB.catalog.event_messages AS M
			WHERE M.operation_id = @execution_id
				AND M.message_type IN (
					120, --Error
					--110, --Предупреждение
					100, --QueryCancel
					130 --TaskFailed
				)
		)
	BEGIN
		SELECT @isError = 1
	END

	IF @isError = 1 BEGIN
		SELECT @ErrorMessage = (
			SELECT M.message + ' '
			FROM SSISDB.catalog.event_messages AS M
			WHERE M.operation_id = @execution_id
				AND M.message_type IN (
					120, --Error
					--110, --Предупреждение
					100, --QueryCancel
					130 --TaskFailed
				)
			ORDER BY M.event_message_id
			FOR XML PATH('')
		)

		SELECT @ReturnCode = 2
		SELECT @ReturnMessage = concat(
			'ИД операции: ' + convert(varchar(12), @execution_id) + '. ',
			'Статус: ', (SELECT S.status_name FROM @status_table AS S WHERE S.status_code = @status), '. ',
			'Ошибка: ', @ErrorMessage
			)

		RETURN @ReturnCode
	END


	IF @Mode = 'temp' BEGIN
		-- копировать во временную таблицу
		SELECT @Sql = 'DROP TABLE IF EXISTS ' + @TableName
		EXEC(@Sql)

		SELECT @Sql = 'SELECT * INTO ' + @TableName + ' FROM ' + @ParamTableName
		EXEC(@Sql)

		SELECT @Sql = 'DROP TABLE IF EXISTS ' + @ParamTableName
		EXEC(@Sql)
	END

	RETURN @ReturnCode
END TRY
BEGIN CATCH
	IF xact_state() <> 0 BEGIN
		ROLLBACK TRANSACTION
	END
	
	SELECT @ErrorNumber = error_number(), @ErrorSeverity = error_severity(), @ErrorState  = error_state()
	SELECT @Error_Procedure = error_procedure(), @Error_Line = ERROR_LINE()
	SELECT @ErrorMessage = isnull(error_message(), 'Сообщение не определенно') + 
		'[' + 'Процедура ' + isnull(@Error_Procedure, 'не определена') + 
		', Строка '+isnull(convert(varchar(20), @Error_Line), 'не определена') + ']'

	--RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)

	SELECT @ReturnCode = 3
	SELECT @ReturnMessage = concat_ws('; '
		,'ИД операции: ', isnull(convert(varchar(12), @execution_id), 'NULL')
		,'Статус: ', isnull((SELECT S.status_name FROM @status_table AS S WHERE S.status_code = @status),'не определен')
		,'Ошибка: ', substring(@ErrorMessage, 1, 3500)
		,'@Sql: ', substring(@Sql, 1, 4000)
		,'@ParmDefinition', substring(@ParmDefinition, 1, 4000)
		)

	RETURN @ReturnCode
END CATCH

END
