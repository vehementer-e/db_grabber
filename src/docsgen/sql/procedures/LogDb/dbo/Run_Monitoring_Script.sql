-- ============================================= 
-- Author: А. Никитин
-- Create date: 21.07.2023
-- Description: DWH-2144 Мониторинг производительность DWH время выполнения скрипта
-- ============================================= 
CREATE   PROC [dbo].[Run_Monitoring_Script]
	@script_name varchar(255) ='num_active_days'
	--@isDebug int = 0,
	--@ProcessGUID varchar(36) = NULL, -- guid процесса
	--@SendEmail int = 1
WITH RECOMPILE  
AS

BEGIN
SET NOCOUNT ON;
SET XACT_ABORT ON;

	DECLARE @session_id int = @@SPID,
		@start_dt datetime = getdate(),
		@end_dt datetime,
		@duration_ms bigint,
		@status varchar(30) = '',
		@message varchar(1024)
	DECLARE @error_description nvarchar(1024)
	DECLARE @test_count int

	BEGIN TRY
		IF @script_name = 'num_active_days'
		BEGIN
		    DROP TABLE IF EXISTS #num_active_days

			SELECT DISTINCT 
				p.person_id2
				,count(DISTINCT cal.dt) AS num_active_days
			INTO #num_active_days
			FROM dwh2.risk.credits c
				INNER JOIN dwh2.risk.person p 
					ON p.person_id = c.person_id
				INNER JOIN dwh2.risk.calendar cal 
					ON cal.dt BETWEEN dateadd(dd, 1, c.startdate)
					AND isnull(cast(c.factenddate AS DATE), getdate())
			GROUP BY p.person_id2;
		END

		IF @script_name = 'test_1'
		BEGIN
			SELECT @test_count = count(*) FROM dwh2.risk.credits c
		END
		IF @script_name = 'test_2'
		BEGIN
			SELECT @test_count = (SELECT count(*) FROM dwh2.risk.credits c) 
				/ 
				(SELECT count(*) FROM dwh2.risk.credits AS c WHERE c.external_id = '*')
		END


		SELECT @end_dt =getdate()
		SELECT @duration_ms = datediff(MILLISECOND, @start_dt, @end_dt)
		SELECT @status = 'succeeded'

		INSERT dbo.Script_Duration_Log(script_name, session_id, start_dt, end_dt, duration_ms, status, message)
		SELECT @script_name, @session_id, @start_dt, @end_dt, @duration_ms, @status, @message

	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @end_dt =getdate()
		SELECT @duration_ms = datediff(MILLISECOND, @start_dt, @end_dt)
		SELECT @message = concat('Ошибка выполнения скрипта ', @script_name, '. ', @error_description)
		SELECT @status = 'failed'

		INSERT dbo.Script_Duration_Log(script_name, session_id, start_dt, end_dt, duration_ms, status, message)
		SELECT @script_name, @session_id, @start_dt, @end_dt, @duration_ms, @status, @message

		;THROW 51000, @error_description, 1
	END CATCH

END 

