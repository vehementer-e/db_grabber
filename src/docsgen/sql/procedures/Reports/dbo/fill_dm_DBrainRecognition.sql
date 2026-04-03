-- =============================================
-- Author:		А.Никитин
-- Create date: 2023-12-09
-- Description:	DWH-2306 Результаты распознавания Инстолмент
-- =============================================
/*
EXEC dbo.fill_dm_DBrainRecognition
	@ProductType = 'Installment'
	,@days = 1000

EXEC dbo.fill_dm_DBrainRecognition
	@ProductType = 'PDL'
	,@days = 1000

EXEC dbo.fill_dm_DBrainRecognition
	@ProductType = 'Installment'
	,@RequestNumber = '23113021483941'
*/
CREATE PROC [dbo].[fill_dm_DBrainRecognition]
	@ProductType varchar(20) = 'installment',
	@days int=25, --кол-во дней для пересчета
	@RequestNumber varchar(20) = NULL, -- расчет по одной заявке
	@isDebug int = 0
AS
BEGIN
	SET XACT_ABORT ON
	--SET NOCOUNT ON

	SELECT @isDebug = isnull(@isDebug, 0)
	SELECT @ProductType = isnull(@ProductType, 'Installment')

	IF @ProductType NOT IN ('installment', 'pdl')
	BEGIN
		;throw 51000, 'Допустимые значения параметра @ProductType: installment, pdl', 1
	END

	BEGIN TRY
		DROP TABLE IF EXISTS #t_Request
		CREATE TABLE #t_Request(RequestNumber nvarchar(255))

		IF @RequestNumber IS NOT NULL BEGIN
			INSERT #t_Request(RequestNumber)
			SELECT CR.Number COLLATE Cyrillic_General_CI_AS
			FROM Stg._fedor.core_ClientRequest AS CR
				INNER JOIN Stg._fedor.dictionary_ProductType AS T
					ON CR.ProductTypeId = T.Id
			WHERE T.Code = @ProductType
				AND CR.Number = @RequestNumber COLLATE SQL_Latin1_General_CP1_CI_AS
		END
		ELSE BEGIN
			INSERT #t_Request(RequestNumber)
			SELECT CR.Number COLLATE Cyrillic_General_CI_AS
			FROM Stg._fedor.core_ClientRequest AS CR
				INNER JOIN Stg._fedor.dictionary_ProductType AS T
					ON CR.ProductTypeId = T.Id
			WHERE T.Code = @ProductType
				AND dateadd(hour,3,CR.CreatedOn) >= dateadd(day,-@days,cast(getdate() as date))
		END

		DROP TABLE IF EXISTS #t_dm_DBrainRecognition
		CREATE TABLE #t_dm_DBrainRecognition
		(
			created_at datetime NOT NULL,
			ProductType varchar(20) NOT NULL,
			RequestGuid uniqueidentifier NOT NULL,
			RequestNumber nvarchar(255) NOT NULL,
			RequestDateTime datetime2(7) NOT NULL,
			RequestClientFIO nvarchar(1024) NULL,
			FileType_Code nvarchar(255) NULL,
			FileType_Name nvarchar(255) NULL,
			AttachmentDoc_Code nvarchar(1024) NULL,
			AttachmentDoc_Name nvarchar(255) NULL,
			FieldInfo_Code nvarchar(255) NULL,
			FieldInfo_Name nvarchar(255) NULL,
			FieldType_Code nvarchar(255) NULL,
			FieldType_Name nvarchar(255) NULL,
			RecogDateTime datetime2(7) NULL,
			RecogFieldResult_Id int NULL,
			Equal int NULL,
			LoginomCheck int NULL,
			EqualAfterDataControl int NULL
		)

		INSERT #t_dm_DBrainRecognition
		(
			created_at,
			ProductType,
			RequestGuid,
			RequestNumber,
			RequestDateTime,
			RequestClientFIO,
			FileType_Code,
			FileType_Name,
			AttachmentDoc_Code,
			AttachmentDoc_Name,
			FieldInfo_Code,
			FieldInfo_Name,
			FieldType_Code,
			FieldType_Name,
			RecogDateTime,
			RecogFieldResult_Id,
			Equal,
			LoginomCheck,
			EqualAfterDataControl
		)

		SELECT
			created_at = getdate()
			,ProductType = @ProductType
			,RequestGuid = CR.Id
			,RequestNumber = CR.Number COLLATE Cyrillic_General_CI_AS
			
			--,RequestDateTime = cast(CR.CreatedRequestDate AS datetime2(0))
			,RequestDateTime = dateadd(HOUR, 3, CR.CreatedOn) -- CreatedOn - в PROC dbo.Create_dm_FedorVerificationRequests_%

			,RequestClientFIO = concat_ws(' '
									,isnull(CR.ClientLastName, cr_ci.LastName)
									,isnull(CR.ClientFirstName, cr_ci.FirstName)
									,isnull(CR.ClientMiddleName, cr_ci.MiddleName) 
									)COLLATE Cyrillic_General_CI_AS

			--,FileType_Code = DBrainFileType.Id
			,FileType_Code = DBrainFileType.Code COLLATE Cyrillic_General_CI_AS
			,FileType_Name = DBrainFileType.Name COLLATE Cyrillic_General_CI_AS

			--,AttachmentDoc_Id = AttachmentDoc.Id
			,AttachmentDoc_Code = AttachmentDoc.Code COLLATE Cyrillic_General_CI_AS
			,AttachmentDoc_Name = AttachmentDoc.Name COLLATE Cyrillic_General_CI_AS

			,FieldInfo_Code = FieldInfo.Code COLLATE Cyrillic_General_CI_AS
			,FieldInfo_Name = FieldInfo.Name COLLATE Cyrillic_General_CI_AS
			--,DBrain_rr.*

			,FieldType_Code = DBrainFieldType.Code COLLATE Cyrillic_General_CI_AS
			,FieldType_Name = DBrainFieldType.Name COLLATE Cyrillic_General_CI_AS

			--Дата/Время ответа сервиса
			--Анна Бибиксарова 14 дек 2023 14:45
			--С вкладки "Детализация" исключаем поля "Дата ответа сервиса", "Время ответа сервиса"
			--т.к. у нас в системах нет точной информации о дате/времени ответа сервиса, только дата время отправки заявки на Call1.2 
			--и дата /время перехода заявки на статус "КД"
			,RecogDateTime = NULL

			,RecogFieldResult_Id = RecogFieldResult.Id
			--RecogFieldResult.DBrainRecognitionResultId,
			--RecogFieldResult.DBrainFieldTypeId,
			--RecogFieldResult.RecognitionFieldValue,
			--RecogFieldResult.Confidence,
			--RecogFieldResult.ConvertedValue,
			,Equal = isnull(cast(RecogFieldResult.Equal AS int), 0)
			--RecogFieldResult.IsDeleted,
			--RecogFieldResult.FieldId,
			,LoginomCheck = isnull(cast(RecogFieldResult.LoginomCheck AS int), 0)
			--RecogFieldResult.SourceClientRequestFieldValue,
			--RecogFieldResult.ClientRequestFieldInfoId,
			,EqualAfterDataControl = isnull(cast(RecogFieldResult.EqualAfterDataControl AS int), 0)
			--RecogFieldResult.SourceClientRequestFieldValueAfterDataControl,
			--RecogFieldResult.IsCheckedByOperator,
			--RecogFieldResult.DWHInsertedDate,
			--RecogFieldResult.ProcessGUID
		FROM #t_Request AS R
			INNER JOIN Stg._fedor.core_ClientRequest AS CR
				ON CR.Number = R.RequestNumber COLLATE SQL_Latin1_General_CP1_CI_AS
			INNER JOIN Stg._fedor.core_DBrainRecognitionResult AS DBrain_rr
				ON DBrain_rr.ClientRequestId = CR.Id
			LEFT JOIN stg._fedor.core_ClientRequestClientInfo cr_ci
				on cr_ci.Id = cr.Id
			LEFT JOIN Stg._fedor.dictionary_DBrainFileType AS DBrainFileType
				ON DBrainFileType.Id = DBrain_rr.DBrainFileTypeId

			left join stg._fedor.dictionary_AttachmentType AS AttachmentDoc
				on AttachmentDoc.id = DBrain_rr.AttachmentTypeId

			left join Stg._fedor.core_DBrainRecognitionFieldResult AS RecogFieldResult
				on RecogFieldResult.DBrainRecognitionResultId = DBrain_rr.id

			left join Stg._fedor.dictionary_ClientRequestFieldInfo AS FieldInfo
				on FieldInfo.id = RecogFieldResult.ClientRequestFieldInfoId

			LEFT JOIN Stg._fedor.dictionary_DBrainFieldType AS DBrainFieldType
				ON DBrainFieldType.Id = RecogFieldResult.DBrainFieldTypeId
		WHERE 1=1
		--ORDER BY CR.Number, DBrainFileType.Id, FieldInfo.Id


		if OBJECT_ID('dbo.dm_DBrainRecognition') is null
		BEGIN
			SELECT TOP 0 *
			INTO dbo.dm_DBrainRecognition
			FROM #t_dm_DBrainRecognition AS D
        END

						
		if exists(select top(1) 1 from #t_dm_DBrainRecognition)
		BEGIN
			BEGIN TRAN
				DELETE D
				FROM dbo.dm_DBrainRecognition D
					INNER JOIN #t_Request AS R
						ON R.RequestNumber = D.RequestNumber

				INSERT dbo.dm_DBrainRecognition
				SELECT D.*
				FROM #t_dm_DBrainRecognition AS D
			COMMIT
		END
        

	end try
	begin catch
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		;throw 
	end catch
END
