-- =======================================================
-- Created: 9.06.2023. А.Никитин
-- Description:	DWH-2098 Витрина "Исполнительные листы"
-- =======================================================
CREATE PROC [dm].[fill_Collection_EnforcementOrders]
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isDebug int = 0
AS
BEGIN

	SET NOCOUNT ON
	SET XACT_ABORT ON

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)     

	DECLARE @eventName nvarchar(255), @eventType nvarchar(50), @message nvarchar(1024) --, @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)
	DECLARE @LastPartitionID int
	DECLARE @Rowversion_Lead binary(8), @Rowversion_LeadAndSurvey binary(8)
	DECLARE @DeleteRows int = 0, @InsertRows int = 0, @CountRows int = 0
	DECLARE @DurationSec int, @StartDate_1 datetime = getdate(), @StartDate datetime = getdate()

	SELECT @eventName = 'dm.fill_Collection_EnforcementOrders', @eventType = 'info', @SendEmail = 0

	BEGIN TRY



		DROP TABLE IF EXISTS #t_Collection_EnforcementOrders

		CREATE TABLE #t_Collection_EnforcementOrders
		(
			DWHInsertedDate							datetime NOT NULL,
			collectionDeal_Id						int not null,
			external_id								varchar(20) not null,
			product_typeName								nvarchar(255),
			enforcementOrder_Id						int,
			enforcementOrder_Number					nvarchar(255),
			enforcementOrder_Date					date,
			enforcementOrder_TypeId					int,
			enforcementOrder_TypeName				varchar(255),
			enforcementProceeding_Id				int,
			enforcementProceeding_StartDate			date,
			enforcementProceeding_EndDate			date,
			enforcementProceeding_CaseNumberInFSSP	nvarchar(255),
			enforcementOrder_ReceiptDate			date, --Дата получения ИЛ
			judicialClaim_MonitoringResultId		int, --Результат мониторинга судебного заявления
			enforcementOrder_AcceptedId				int, --Флаг "ИЛ принят"



		)

		INSERT #t_Collection_EnforcementOrders
		(
			DWHInsertedDate							
			,collectionDeal_Id						
			,external_id		
			,product_typeName
			,enforcementOrder_Id						
			,enforcementOrder_Number					
			,enforcementOrder_Date					
			,enforcementOrder_TypeId					
			,enforcementOrder_TypeName				
			,enforcementProceeding_Id				
			,enforcementProceeding_StartDate			
			,enforcementProceeding_EndDate			
			,enforcementProceeding_CaseNumberInFSSP	
			,enforcementOrder_ReceiptDate			
			,judicialClaim_MonitoringResultId		
			,enforcementOrder_AcceptedId				

		)
		SELECT 
			DWHInsertedDate = getdate()
			,collectionOrder_Id = D.Id
			,external_id = D.Number
			,product_typeName = 
				CASE upper(ДоговорЗайма.ТипПродукта)
						when upper('ПТС')			then 'ПТС'
						when upper('PDL')			then 'PDL'
						when upper('ПТС31')			then 'ПТС31'
						when upper('Смарт-инстоллмент')	then 'Смарт-инстоллмент'
						when lower('Инстоллмент')		then 'Инстоллмент'
						else upper('ПТС')
				end
			,enforcementOrder_Id = eo.id
			,enforcementOrder_Number =eo.Number
			,enforcementOrder_Date = cast(EO.Date AS date)
			,enforcementOrderType_Id = EO.Type --Тип ИЛ
			--(там enum: 1 - Обеспечительные меры, 2 - Денежное требование, 3 - Обращение взыскания, 4 - Взыскани ,би обращение взыскания)
			,enforcementOrder_TypeName = EOT.enforcementOrder_TypeName
			,enforcementProceeding_Id = EP.ID
			,enforcementProceeding_StartDate = cast(EPE.ExcitationDate AS date)
			,enforcementProceeding_EndDate = cast(EPE.EndDate AS date)
			,enforcementProceeding_CaseNumberInFSSP = EPE.CaseNumberInFSSP
			,enforcementOrder_ReceiptDate			= EO.ReceiptDate  --Дата получения ИЛ
			,judicialClaim_MonitoringResultId		= JC.MonitoringResult --
			,enforcementOrder_AcceptedId			= EO.Accepted  
			--D.* 
		
		FROM Stg._Collection.Deals AS D
		left join [hub].[ДоговорЗайма] ДоговорЗайма
			on ДоговорЗайма.КодДоговораЗайма = d.Number
			LEFT JOIN Stg._Collection.JudicialProceeding AS JP
				ON D.Id = JP.DealId 
			LEFT JOIN Stg._Collection.JudicialClaims AS JC
				ON JP.Id = JC.JudicialProceedingId
			LEFT JOIN Stg._Collection.EnforcementOrders AS EO
				ON JC.Id = EO.JudicialClaimId
			LEFT JOIN Stg._Collection.EnforcementProceeding AS EP
				ON EO.Id = EP.EnforcementOrderId 
			LEFT JOIN Stg._Collection.EnforcementProceedingExcitation AS EPE
				ON EPE.EnforcementProceedingId = EP.Id
			LEFT JOIN Stg._Collection.tvf_EnforcementOrderType() AS EOT
				ON EOT.enforcementOrderType_Id = EO.Type


		IF object_id('dm.Collection_EnforcementOrders') IS NULL
		BEGIN
		--drop table  dm.Collection_EnforcementOrders
			SELECT TOP 0 *
			INTO dm.Collection_EnforcementOrders
			FROM #t_Collection_EnforcementOrders AS T
		END
	

		BEGIN TRAN
			TRUNCATE TABLE dm.Collection_EnforcementOrders
			
			INSERT dm.Collection_EnforcementOrders
			(
				DWHInsertedDate							
				,collectionDeal_Id						
				,external_id
				,product_typeName
				,enforcementOrder_Id						
				,enforcementOrder_Number					
				,enforcementOrder_Date					
				,enforcementOrder_TypeId					
				,enforcementOrder_TypeName				
				,enforcementProceeding_Id				
				,enforcementProceeding_StartDate			
				,enforcementProceeding_EndDate			
				,enforcementProceeding_CaseNumberInFSSP	
				,enforcementOrder_ReceiptDate			
				,judicialClaim_MonitoringResultId		
				,enforcementOrder_AcceptedId
			)
			SELECT
			 t.DWHInsertedDate							
			,t.collectionDeal_Id						
			,t.external_id		
			,product_typeName
			,t.enforcementOrder_Id						
			,t.enforcementOrder_Number					
			,t.enforcementOrder_Date					
			,t.enforcementOrder_TypeId					
			,t.enforcementOrder_TypeName				
			,t.enforcementProceeding_Id				
			,t.enforcementProceeding_StartDate			
			,t.enforcementProceeding_EndDate			
			,t.enforcementProceeding_CaseNumberInFSSP	
			,t.enforcementOrder_ReceiptDate			
			,t.judicialClaim_MonitoringResultId		
			,t.enforcementOrder_AcceptedId
			FROM #t_Collection_EnforcementOrders AS T

			SELECT @InsertRows = @@ROWCOUNT
			SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())
		COMMIT

		IF @isDebug = 1 BEGIN
			SELECT 'INSERT dm.Collection_EnforcementOrders', @InsertRows, @DurationSec
		END

		SELECT @message = 
			concat(
				'Заполнение dm.Collection_EnforcementOrders. ',
				--'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
				'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
				'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
			)

		IF @isDebug = 1 BEGIN
			SELECT @message
		END

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = @eventName, 
			@eventType = @eventType, 
			@message = @message, 
			@SendEmail = @SendEmail, 
			@ProcessGUID = @ProcessGUID

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
				'Ошибка заполнения dm.Collection_EnforcementOrders. ',
				--'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
				'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
				'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
			)

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
