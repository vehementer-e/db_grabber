-- ============================================= 
-- Author: А. Никитин
-- Create date: 23.11.2023
-- Description: DWH-2340 Проверка валидности объектов Find invalid objects
-- ============================================= 
CREATE   PROC dbo.Report_invalid_objects
	--@isDebug int = 0,
	--@ProcessGUID varchar(36) = NULL -- guid процесса
AS
BEGIN
SET NOCOUNT ON;
	--SELECT @isDebug = isnull(@isDebug, 0)
	--SELECT @ProcessGUID = isnull(@ProcessGUID, newid())

	SELECT
		created_at = convert(varchar(19), L.created_at, 120),
		L.db_name,
		L.obj_type,
		L.obj_id,
		L.obj_name,
		L.err_message
	FROM LogDb.dbo.Invalid_objects_log AS L
	ORDER BY L.db_name, L.obj_type, L.obj_name

END 

