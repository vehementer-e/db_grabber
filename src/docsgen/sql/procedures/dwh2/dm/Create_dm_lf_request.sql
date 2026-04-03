-- =======================================================
-- Create: 28.10.2024. А.Никитин
-- Description:	
-- =======================================================
CREATE   PROC dm.Create_dm_lf_request
	@mode int = 1, -- 1-increment, 0-full
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isDebug int = 0
as
begin
	SET NOCOUNT ON 
	SET XACT_ABORT ON

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)     

	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024) --, @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)

	DECLARE @DurationSec int, @StartDate datetime = getdate()
	DECLARE @DeleteRows int, @InsertRows int

	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	SELECT @eventName = concat('exec ', @spName), @eventType = 'info', @SendEmail = 0

	BEGIN TRY
		if OBJECT_ID('dm.lf_request') is null
		BEGIN
		    SELECT TOP(0) *
			INTO dm.lf_request
			FROM dm.v_lf_request

			alter table dm.lf_request
				alter COLUMN СсылкаЗаявки binary(16) not null

			--alter table dm.lf_request
			--	alter column НомерЗаявки nvarchar(14) not null

			alter table dm.lf_request
				alter column GuidЗаявки uniqueidentifier not null

			ALTER TABLE dm.lf_request
				ADD CONSTRAINT PK_dm_lf_request PRIMARY KEY CLUSTERED (GuidЗаявки)

			CREATE NONCLUSTERED INDEX ix_НомерЗаявки 
				ON dm.lf_request(НомерЗаявки, GuidЗаявки)
		END

		DROP TABLE IF EXISTS #t_change

		SELECT C.id, C.GuidЗаявки 
		INTO #t_change
		FROM link.lf_request_change AS C

		DROP TABLE IF EXISTS #t_lf_request

		SELECT TOP(0) *
		INTO #t_lf_request
		FROM dm.v_lf_request

		IF @mode = 0
		BEGIN
			INSERT #t_lf_request
			SELECT R.* 
			FROM dm.v_lf_request AS R
		END

		IF @mode = 1
		BEGIN
			INSERT #t_lf_request
			SELECT R.* --distinct R.* 
			FROM dm.v_lf_request AS R
				INNER JOIN (
						SELECT DISTINCT T.GuidЗаявки FROM #t_change AS T
					) AS C
					ON R.GuidЗаявки = C.GuidЗаявки
		END


		BEGIN TRAN
			DELETE R 
			FROM dm.lf_request AS R
				INNER JOIN #t_lf_request AS T
					ON T.GuidЗаявки = R.GuidЗаявки

			SELECT @DeleteRows = @@ROWCOUNT

			INSERT dm.lf_request
			(
				created_at,
				СсылкаЗаявки,
				НомерЗаявки,
				GuidЗаявки,
				request_created_at_time,
				request_updated_at_time,
				request_phone,
				request_origin,
				request_created_date,
				request_product_type,
				lead_id,
				lead_created_at_time,
				lead_updated_at_time,
				lead_source,
				lead_name,
				lead_product_type,
				lead_required_sum,
				lead_client_id,
				lead_entrypoint,
				lead_partner_id,
				lead_channel,
				lead_channel_group,
				visit_id,
				visit_stat_system,
				visit_stat_type,
				visit_stat_campaign,
				visit_stat_info,
				visit_stat_term,
				visit_stat_source,
				visit_created_at_time,
				visit_source,
				visit_page,
				visit_referer,
				visit_userAgent,
				visit_platform,
				visit_appmetrica,
				visit_appmetrica_id,
				visit_appmetrica_updated_at_time,
				original_lead_region,
				original_lead_id,
				original_lead_created_at_time,
				original_lead_updated_at_time
			)
			SELECT --distinct 
				created_at,
				СсылкаЗаявки,
				НомерЗаявки,
				GuidЗаявки,
				request_created_at_time,
				request_updated_at_time,
				request_phone,
				request_origin,
				request_created_date,
				request_product_type,
				lead_id,
				lead_created_at_time,
				lead_updated_at_time,
				lead_source,
				lead_name,
				lead_product_type,
				lead_required_sum,
				lead_client_id,
				lead_entrypoint,
				lead_partner_id,
				lead_channel,
				lead_channel_group,
				visit_id,
				visit_stat_system,
				visit_stat_type,
				visit_stat_campaign,
				visit_stat_info,
				visit_stat_term,
				visit_stat_source,
				visit_created_at_time,
				visit_source,
				visit_page,
				visit_referer,
				visit_userAgent,
				visit_platform,
				visit_appmetrica,
				visit_appmetrica_id,
				visit_appmetrica_updated_at_time,
				original_lead_region,
				original_lead_id,
				original_lead_created_at_time,
				original_lead_updated_at_time
			FROM #t_lf_request AS T

			SELECT @InsertRows = @@ROWCOUNT

			DELETE C
			FROM link.lf_request_change AS C
				INNER JOIN #t_change AS T
				--INNER JOIN #t_lf_request AS T
					--ON T.GuidЗаявки = C.GuidЗаявки
					ON T.id = C.id
		COMMIT

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @message = 
			concat(
				'Заполнение dwh2.dm.lf_request. ',
				'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
				'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
				'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
			)

		IF @isDebug = 1 BEGIN
			SELECT @message
			EXEC LogDb.dbo.LogAndSendMailToAdmin 
				@eventName = @eventName, 
				@eventType = @eventType, 
				@message = @message, 
				@SendEmail = @SendEmail, 
				@ProcessGUID = @ProcessGUID
		END
	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		SELECT @message = 
			concat(
				'Ошибка заполнения dwh2.dm.lf_request. ',
				'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
				'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
				'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
			)

		--SELECT @message = concat('exec ', @spName)

		SELECT @eventType = 'Data Valut ERROR'

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = @eventName,
			@eventType = @eventType,
			@message = @message,
			@description = @error_description,
			@SendEmail = @SendEmail,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH
END
