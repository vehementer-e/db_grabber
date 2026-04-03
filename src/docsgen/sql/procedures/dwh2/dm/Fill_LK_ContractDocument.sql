-- ============================================= 
-- Author: А. Никитин
-- Create date: 27.12.2022
-- Description: DWH-1792 Общая витрина
-- заполнение витрины dm.LK_ContractDocument
-- ============================================= 
CREATE   PROC dm.Fill_LK_ContractDocument
	@ProcessGUID uniqueidentifier = NULL,
	@reLoadDay int = 3,
	@isDebug int = 0
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	SELECT @isDebug = isnull(@isDebug, 0)
	SET @ProcessGUID = isnull(@ProcessGUID, newid())

	DECLARE @InsertRows int, @DeleteRows int, @TempRows int
	DECLARE @StartDate datetime, @DurationSec int
	declare @error_description nvarchar(1024)
	DECLARE @max_updated_at datetime, @insert_updated_at datetime
	DECLARE @description nvarchar(1024), @message nvarchar(1024)

	BEGIN TRY
		SELECT @StartDate = getdate()

		SELECT @max_updated_at = isnull(max(E.doc_updated_at), '2000-01-01')
		FROM dm.LK_ContractDocument AS E

		SELECT @max_updated_at = dateadd(DAY, - @reLoadDay, @max_updated_at)

		IF @isDebug = 1 BEGIN
			SELECT @ProcessGUID, @max_updated_at
		END
		

		DROP TABLE IF EXISTS #t_LK_ContractDocument
		CREATE TABLE #t_LK_ContractDocument
		(
			DWHInsertedDate datetime NOT NULL,
			external_id nvarchar(255),

			doc_name nvarchar(255),
			is_pep smallint,

			doc_id int,
			doc_created_at datetime2,
			doc_updated_at datetime2,

			doc_type nvarchar(255),
			doc_type_name nvarchar(255),
	
			sms_send_date datetime2,
			sms_input_date datetime2,
			package_doc int,
			sub_package int
		)

		INSERT #t_LK_ContractDocument
		(
		    DWHInsertedDate,
		    external_id,
		    doc_name,
		    is_pep,
		    doc_id,
		    doc_created_at,
		    doc_updated_at,
		    doc_type,
		    doc_type_name,
		    sms_send_date,
		    sms_input_date,
			package_doc,
			sub_package
		)
		SELECT DISTINCT 
			DWHInsertedDate = getdate(),
			--C.id
			external_id = C.code

			--,CD.id
			,doc_name = CD.name
			,CD.is_pep

			--,LC.id

			,doc_id = UL.id
			,doc_created_at = dateadd(hh, 3, UL.created_at)
			,doc_updated_at = dateadd(hh, 3, UL.updated_at)

			,doc_type = ULT.type 
			,doc_type_name = ULT.full_description
	
			--,PEP.id
			,sms_send_date = dateadd(hh, 3, PEP.sms_send_date)
			,sms_input_date =  dateadd(hh, 3, PEP.sms_input_date)
			--,is_signed = iif( lk_pep_log.sms_input_date is not null, 1, 0)
			,PEP.package_doc
			,PEP.sub_package
		from Stg._LK.contracts AS C
			inner join Stg._LK.contract_documents AS CD 
				on CD.contract_id =  C.id
			inner join Stg._LK.user_link_contract AS LC
				on LC.contract_documents_id = CD.id
			inner join Stg._LK.user_link AS UL
				on UL.id = LC.user_link_id
			inner join stg._lk.user_link_types AS ULT
				on UL.user_link_type_id =ULT.id
				--and lk_ul.active = 1
 			left join stg._LK.pep_activity_log AS PEP
				ON PEP.id = UL.pep_activity_log_id
		WHERE 1=1
			AND dateadd(hh, 3, UL.updated_at) >= @max_updated_at


		SELECT @TempRows = @@ROWCOUNT

		IF @TempRows > 0
		BEGIN
			SELECT @insert_updated_at = min(E.doc_updated_at)
			FROM #t_LK_ContractDocument AS E

			BEGIN TRAN
				DELETE E
				FROM dm.LK_ContractDocument AS E
				WHERE E.doc_updated_at >= @insert_updated_at

				SELECT @DeleteRows = @@ROWCOUNT

				INSERT dm.LK_ContractDocument
				(
					DWHInsertedDate,
					external_id,
					doc_name,
					is_pep,
					doc_id,
					doc_created_at,
					doc_updated_at,
					doc_type,
					doc_type_name,
					sms_send_date,
					sms_input_date,
					package_doc,
					sub_package
				)
				SELECT 
					E.DWHInsertedDate,
                    E.external_id,
                    E.doc_name,
                    E.is_pep,
                    E.doc_id,
                    E.doc_created_at,
                    E.doc_updated_at,
                    E.doc_type,
                    E.doc_type_name,
                    E.sms_send_date,
                    E.sms_input_date,
					E.package_doc,
					E.sub_package
				FROM #t_LK_ContractDocument AS E

				SELECT @InsertRows = @@ROWCOUNT
			COMMIT
		END

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())


		IF @isDebug = 1 BEGIN
			SELECT concat('Удалено: ', convert(varchar(10), @DeleteRows), '. ',
				'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
				'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
			)
		END

		SELECT @message = concat(
			'Формирование витрины dm.LK_ContractDocument. ',
			'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
			'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
			'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
		)

		SELECT @description =
			(
			SELECT
				'DeleteRows' = @DeleteRows,
				'InsertRows' = @InsertRows,
				'DurationSec' = @DurationSec
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
			)

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = 'Fill_LK_ContractDocument',
			@eventType = 'Info',
			@message = @message,
			@description = @description, 
			@SendEmail = 0,
			@ProcessGUID = @ProcessGUID

	END TRY
	BEGIN CATCH
		SET @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
			+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
		IF @@TRANCOUNT > 0
			   ROLLBACK;

		SELECT @message = concat(
			'Ошибка формирования витрины dm.LK_ContractDocument. ',
			'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
			'Добавлено: ', convert(varchar(10), @InsertRows), '. ',
			'Время выполнения (сек): ', convert(varchar(10), @DurationSec)
		)

		SELECT @description =
			(
			SELECT
				'DeleteRows' = @DeleteRows,
				'InsertRows' = @InsertRows,
				'DurationSec' = @DurationSec
			FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
			)

		EXEC LogDb.dbo.LogAndSendMailToAdmin 
			@eventName = 'Error Fill_LK_ContractDocument',
			@eventType = 'Error',
			@message = @message,
			@description = @error_description, 
			@SendEmail = 0,
			@ProcessGUID = @ProcessGUID
	
		;THROW 51000, @error_description, 1
	END CATCH
END
