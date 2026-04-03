-- =======================================================
-- Create: 31.03.2023. А.Никитин
-- Description:	DWH-2008 Оперативная витрина по лидам за последние 5 дней
-- =======================================================
CREATE   PROC _LCRM.create_dm_lead_in_recent_days_for_ivr
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	--@mode int = 1, -- 0 - full, 1 - increment
	@isDebug int = 0
AS 
BEGIN
	SET NOCOUNT ON 
	SET XACT_ABORT ON

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)     

	DECLARE @dt_from datetime
	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024) --, @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)
	DECLARE @InsertRows int = 0, @UpdateRows int = 0 --, @DeleteRows int = 0

	SELECT @eventName = '_LCRM.create_dm_lead_in_recent_days_for_ivr', @eventType = 'info', @SendEmail = 0

	DROP TABLE IF EXISTS #t_calculated
	CREATE TABLE #t_calculated
	(
		[ID] [numeric] (10, 0) NOT NULL, --id лида последнего с таким телефоном (по UF_UPDATED_AT)
		[PhoneNumber] [varchar] (20) NOT NULL, --primary key
		[UF_ROW_ID] [varchar] (128) NULL, --Номер заявки
		[Канал от источника] [nvarchar] (255) NULL, --Канал лида
		[UF_REGISTERED_AT] [datetime2] NULL, --Дата регистрации лида
		[UF_UPDATED_AT] [datetime2] NULL --Дата обновления лида
	)

	DROP TABLE IF EXISTS #t_dm_lead_in_recent_days_for_ivr
	CREATE TABLE #t_dm_lead_in_recent_days_for_ivr
	(
		[ID] [numeric] (10, 0) NOT NULL, --id лида последнего с таким телефоном (по UF_UPDATED_AT)
		[PhoneNumber] [varchar] (20) NOT NULL, --primary key
		[UF_ROW_ID] [varchar] (128) NULL, --Номер заявки
		[Канал от источника] [nvarchar] (255) NULL, --Канал лида
		[UF_REGISTERED_AT] [datetime2] NULL, --Дата регистрации лида
		[UF_UPDATED_AT] [datetime2] NULL --Дата обновления лида
	)

	BEGIN TRY

		SELECT @dt_from = cast(dateadd(DAY, -5, getdate()) AS date)

		INSERT #t_calculated
		(
		    ID,
		    PhoneNumber,
		    UF_ROW_ID,
		    [Канал от источника],
		    UF_REGISTERED_AT,
		    UF_UPDATED_AT
		)
		SELECT
			C.ID,
			C.PhoneNumber,
			C.UF_ROW_ID,
			C.[Канал от источника],
			C.UF_REGISTERED_AT,
			C.UF_UPDATED_AT
		FROM _LCRM.lcrm_leads_full_calculated AS C --(NOLOCK)
		WHERE 1=1
			AND C.UF_REGISTERED_AT >= @dt_from
			AND C.[Канал от источника] IN (
				'CPA полуцелевой', -- = semi-target
				'CPA целевой', -- = target
				'CPC Бренд', -- = CPC brand
				'CPC Платный', --  = CPC paid
				'Сайт орган.трафик' --  = organic traffic
			)

		CREATE CLUSTERED INDEX clix1 ON #t_calculated(PhoneNumber, UF_UPDATED_AT DESC)

		INSERT #t_dm_lead_in_recent_days_for_ivr
		(
		    ID,
		    PhoneNumber,
		    UF_ROW_ID,
		    [Канал от источника],
		    UF_REGISTERED_AT,
		    UF_UPDATED_AT
		)
		SELECT 
			A.ID,
            A.PhoneNumber,
            A.UF_ROW_ID,
            A.[Канал от источника],
            A.UF_REGISTERED_AT,
            A.UF_UPDATED_AT
		FROM (
			SELECT 
				C.ID,
				C.PhoneNumber,
				C.UF_ROW_ID,
				C.[Канал от источника],
				C.UF_REGISTERED_AT,
				C.UF_UPDATED_AT,
				rn = row_number() OVER(PARTITION BY C.PhoneNumber ORDER BY C.UF_UPDATED_AT DESC)
			FROM #t_calculated AS C
			) AS A
		WHERE A.rn = 1

		CREATE UNIQUE CLUSTERED INDEX clix1 ON #t_dm_lead_in_recent_days_for_ivr(PhoneNumber)

		DELETE T
		FROM _LCRM.dm_lead_in_recent_days_for_ivr AS A
			INNER JOIN #t_dm_lead_in_recent_days_for_ivr AS T
				ON A.PhoneNumber = T.PhoneNumber
				AND A.UF_UPDATED_AT = T.UF_UPDATED_AT

		UPDATE A
		SET ID = T.ID,
			UF_ROW_ID = T.UF_ROW_ID,
			[Канал от источника] = T.[Канал от источника],
			UF_REGISTERED_AT = T.UF_REGISTERED_AT,
			UF_UPDATED_AT = T.UF_UPDATED_AT,
			DWHUpdatedDate = getdate()
		FROM _LCRM.dm_lead_in_recent_days_for_ivr AS A
			INNER JOIN #t_dm_lead_in_recent_days_for_ivr AS T
				ON A.PhoneNumber = T.PhoneNumber
				AND A.UF_UPDATED_AT < T.UF_UPDATED_AT

		SELECT @UpdateRows = @@ROWCOUNT

		DELETE T
		FROM _LCRM.dm_lead_in_recent_days_for_ivr AS A
			INNER JOIN #t_dm_lead_in_recent_days_for_ivr AS T
				ON A.PhoneNumber = T.PhoneNumber

		INSERT _LCRM.dm_lead_in_recent_days_for_ivr
		(
		    ID,
		    PhoneNumber,
		    UF_ROW_ID,
		    [Канал от источника],
		    UF_REGISTERED_AT,
		    UF_UPDATED_AT,
			DWHInsertedDate,
			DWHUpdatedDate
		)
		SELECT 
		    T.ID,
		    T.PhoneNumber,
		    T.UF_ROW_ID,
		    T.[Канал от источника],
		    T.UF_REGISTERED_AT,
		    T.UF_UPDATED_AT,
			DWHInsertedDate = getdate(),
			DWHUpdatedDate = getdate()
		FROM #t_dm_lead_in_recent_days_for_ivr AS T

		SELECT @InsertRows = @@ROWCOUNT

		SELECT @message = concat(
				'Обновление и Добавление.',
				' @dt_from: ', format(@dt_from, 'yyyy-MM-dd'),
				', @UpdateRows = ', convert(varchar(10), @UpdateRows),
				', @InsertRows = ', convert(varchar(10), @InsertRows)
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
		SET @error_description = 'ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @message = 'Ошибка заполнения _LCRM.dm_lead_in_recent_days_for_ivr'

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = @eventName, 
			@eventType = 'Error',
			@message = @message,
			@description = @error_description,
			@SendEmail = @SendEmail,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH
END
