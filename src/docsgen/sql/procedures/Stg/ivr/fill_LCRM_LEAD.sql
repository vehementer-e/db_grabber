-- =======================================================
-- Create: 4.04.2023. А.Никитин
-- Description:	DWH-1921 Доработка IVR сервиса
-- =======================================================
CREATE   PROC [ivr].[fill_LCRM_LEAD]
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
	DECLARE @InsertRows int = 0 --, @UpdateRows int = 0
	DECLARE @DeleteRows int = 0
	DECLARE @partitionName nvarchar(255), @partitionID int

	SELECT @partitionName = 'LCRM_LEAD'
	SELECT @partitionID = $PARTITION.[pfn_range_right_Type_part_IVR_Data](@partitionName)

	SELECT @eventName = 'ivr.fill_LCRM_LEAD', @eventType = 'info', @SendEmail = 0

	DROP TABLE IF EXISTS #t_IVR_Data
	CREATE TABLE #t_IVR_Data
	(
		[Caller] [nvarchar] (11) NOT NULL,
		[МобильныйТелефон] [nvarchar] (50) NULL,
		[created] [datetime] NOT NULL,
		[updated] [datetime] NOT NULL,
		[isHistory] [int] NOT NULL,
		[isActive] [bit] NULL,
		[Type] [nvarchar] (255) NOT NULL,
		channellid varchar(50) NULL,
		--
		[Cmclient] [int] NOT NULL,
		[Legal] [int] NOT NULL,
		[ExecutionOrder] [int] NOT NULL,
		[RequestType] [varchar] (7) NOT NULL
	)


	BEGIN TRY
		/*
		1. channellid будет заполнятся след образом:
		CPA нецелевой = non-target
		CPA полуцелевой = semi-target
		CPA целевой = target
		CPC Бренд = CPC brand
		CPC Платный = CPC paid
		Сайт орган.трафик = organic traffic

		2.	в поле
		1.	Caller писать данные из PhoneNumber в формате 8 + PhoneNumber 
		2.	МобильныйТелефон - PhoneNumber 
		3.	created - UF_REGISTERED_AT
		4.	isActive = 1
		5.	Type = LCRM_LEAD
		*/
		INSERT #t_IVR_Data
		(
		    Caller,
		    МобильныйТелефон,
		    created,
		    updated,
			isHistory,
		    isActive,
		    [Type],
		    channellid,
			Cmclient,
			Legal,
			ExecutionOrder,
			RequestType
		)
		SELECT 
		    Caller = concat('8', I.PhoneNumber),
		    МобильныйТелефон = I.PhoneNumber,
		    created = I.UF_REGISTERED_AT,
		    updated = I.UF_UPDATED_AT,
			isHistory = 0,
		    isActive = 1,
		    [Type] = @partitionName,
		    channellid = 
				CASE I.[Канал от источника]
					WHEN 'CPA полуцелевой' THEN 'semi-target'
					WHEN 'CPA целевой' THEN 'target'
					WHEN 'CPC Бренд' THEN 'CPC brand'
					WHEN 'CPC Платный' THEN 'CPC paid'
					WHEN 'Сайт орган.трафик' then 'organic traffic'
					ELSE ''
				END,
			Cmclient = 0,
			Legal = 0,
			ExecutionOrder = 0,
			RequestType = 'Unknown'
		FROM _LCRM.dm_lead_in_recent_days_for_ivr AS I

		--IF @isDebug = 1 BEGIN
		--	DROP TABLE IF EXISTS ##t_IVR_Data
		--	SELECT * INTO ##t_IVR_Data FROM #t_IVR_Data
		--	RETURN 0
		--END

		BEGIN TRAN

			--DELETE D
			--FROM ivr.IVR_Data AS D
			--WHERE D.Type = 'LCRM_LEAD'

			--SELECT @DeleteRows = @@ROWCOUNT

			--TRUNCATE TABLE ivr.IVR_Data WITH (PARTITIONS(@partitionID));
			
			delete top(10000) 
				from  ivr.IVR_Data 
			where  Type = 'LCRM_LEAD'
			
			while @@ROWCOUNT>0
			begin
				delete top(10000)  
					from  ivr.IVR_Data 
				where  Type = 'LCRM_LEAD'	
			end
			INSERT ivr.IVR_Data
			(
				Caller,
				МобильныйТелефон,
				created,
				updated,
				isHistory,
				isActive,
				Type,
				channellid,
				Cmclient,
				Legal,
				ExecutionOrder,
				RequestType
			)
			SELECT 
				I.Caller,
                I.МобильныйТелефон,
                I.created,
                I.updated,
				I.isHistory,
                I.isActive,
                I.Type,
                I.channellid,
				I.Cmclient,
				I.Legal,
				I.ExecutionOrder,
				I.RequestType
			FROM #t_IVR_Data AS I

			SELECT @InsertRows = @@ROWCOUNT

		COMMIT


		SELECT @message = concat(
				'Удаление и добавление в ivr.IVR_Data.',
				--' @DeleteRows = ', convert(varchar(10), @DeleteRows),
				' Type = ', @partitionName,
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

		SELECT @message = 'Ошибка выполнения ivr.fill_LCRM_LEAD'

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
