
CREATE PROCEDURE [collection].[set_debug_info] @src NVARCHAR(100)
	,@info NVARCHAR(500)
AS
SET NOCOUNT ON
SET XACT_ABORT ON

BEGIN TRANSACTION;

INSERT INTO collection.debug_log (
	source_name
	,event_time
	,usr_name
	,event_info
	)
VALUES (
	@src
	,SYSDATETIME()
	,CONCAT (
		DB_NAME()
		,'.'
		,CURRENT_USER
		)
	,@info
	);

COMMIT TRANSACTION;
