-- =============================================
-- Author:		А.Никитин
-- Create date: 2024-11-26
-- Description:	DWH-2827 Реализовать отчет по распознаванию документов
-- =============================================
/*
EXEC collection.fill_dm_CollectionDocRecognition
	,@days = 1000
*/
CREATE   PROC [collection].[fill_dm_CollectionDocRecognition]
	@days int = 2, --кол-во дней для пересчета
	@mode int = 1, -- 
	@EdoDocumentId int = NULL, -- расчет по одному док-ту
	@isDebug int = 0
AS
BEGIN
	SET XACT_ABORT ON
	--SET NOCOUNT ON

	SELECT @isDebug = isnull(@isDebug, 0)
	DECLARE @CreateDate datetime2(7) = '2000-01-01'

	BEGIN TRY
		if OBJECT_ID ('collection.dm_CollectionDocRecognition') is not null
			AND @mode = 1
		begin
			SELECT @CreateDate = isnull(dateadd(DAY, -@days, max(D.CreateDate)), '2000-01-01')
			from collection.dm_CollectionDocRecognition AS D
		end
		
		DROP TABLE IF EXISTS #t_EdoDocument
		CREATE TABLE #t_EdoDocument(EdoDocumentId int)

		IF @EdoDocumentId IS NOT NULL BEGIN
			INSERT #t_EdoDocument(EdoDocumentId)
			VALUES(@EdoDocumentId)
		END
		ELSE BEGIN
			INSERT #t_EdoDocument(EdoDocumentId)
			SELECT DISTINCT V.EdoDocumentId
			FROM Stg._collection.DocumentFieldValues AS V
			WHERE V.CreateDate >= @CreateDate
		END

		CREATE INDEX ix_id ON #t_EdoDocument(EdoDocumentId)


		DROP TABLE IF EXISTS #t_dm_CollectionDocRecognition
		CREATE TABLE #t_dm_CollectionDocRecognition
		(
			created_at datetime,
			Id int,
			DocumentTypeDocumentFieldId int,
			EdoDocumentId int,
			RecognizedValue nvarchar(max),
			FinalValue nvarchar(max),
			Equal int,
			TaskCreationDisabled bit,
			CreateDate datetime2(7),
			UpdateDate datetime2(7),
			DocumentTypeId int,
			DocumentTypeName nvarchar(255),
			DocumentTypeCode nvarchar(255),
			DocumentFieldId int,
			DocumentFieldName nvarchar(255),
			DocumentFieldCode nvarchar(255)
		)

		INSERT #t_dm_CollectionDocRecognition
		(
			created_at,
		    Id,
		    DocumentTypeDocumentFieldId,
		    EdoDocumentId,
		    RecognizedValue,
		    FinalValue,
		    Equal,
		    TaskCreationDisabled,
		    CreateDate,
		    UpdateDate,
		    DocumentTypeId,
		    DocumentTypeName,
		    DocumentTypeCode,
		    DocumentFieldId,
		    DocumentFieldName,
		    DocumentFieldCode
		)
		SELECT 
			created_at = getdate(),
			V.Id,
			V.DocumentTypeDocumentFieldId,
			V.EdoDocumentId,
			V.RecognizedValue,
			V.FinalValue,
			V.Equal,
			V.TaskCreationDisabled,
			V.CreateDate,
			V.UpdateDate,

			X.DocumentTypeId,
			DocumentTypeName = DT.Name,
			DocumentTypeCode = DT.Code,
			--DocumentTypeGuid = DT.Guid,
			--IsActive_DocumentType = DT.IsActive,

			X.DocumentFieldId,
			--DocumentFieldGuid = DF.Guid,
			DocumentFieldName = DF.Name,
			DocumentFieldCode = DF.Code
			--IsActive_DocumentField = DF.IsActive
		FROM #t_EdoDocument AS I
			INNER JOIN Stg._collection.DocumentFieldValues AS V
				ON V.EdoDocumentId = I.EdoDocumentId
			INNER JOIN Stg._collection.DocumentTypeDocumentField AS X
				ON X.Id = V.DocumentTypeDocumentFieldId
			INNER JOIN Stg._collection.DocumentType AS DT
				ON DT.Id = X.DocumentTypeId
			INNER JOIN Stg._collection.DocumentFields AS DF
				ON DF.Id = X.DocumentFieldId

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##t_dm_CollectionDocRecognition
			SELECT * INTO ##t_dm_CollectionDocRecognition FROM #t_dm_CollectionDocRecognition
		END

		if OBJECT_ID('collection.dm_CollectionDocRecognition') is null
		BEGIN
			SELECT TOP 0 *
			INTO collection.dm_CollectionDocRecognition
			FROM #t_dm_CollectionDocRecognition AS D

			CREATE INDEX ix_EdoDocumentId
			ON collection.dm_CollectionDocRecognition(EdoDocumentId)

			CREATE INDEX ix_CreateDate
			ON collection.dm_CollectionDocRecognition(CreateDate)
        END

						
		if exists(select top(1) 1 from #t_dm_CollectionDocRecognition)
		BEGIN
			BEGIN TRAN
				DELETE D
				FROM collection.dm_CollectionDocRecognition D
					INNER JOIN #t_EdoDocument AS I
						ON I.EdoDocumentId = D.EdoDocumentId

				INSERT collection.dm_CollectionDocRecognition
				(
					created_at,
					Id,
					DocumentTypeDocumentFieldId,
					EdoDocumentId,
					RecognizedValue,
					FinalValue,
					Equal,
					TaskCreationDisabled,
					CreateDate,
					UpdateDate,
					DocumentTypeId,
					DocumentTypeName,
					DocumentTypeCode,
					DocumentFieldId,
					DocumentFieldName,
					DocumentFieldCode
				)
				SELECT 
					D.created_at,
					D.Id,
					D.DocumentTypeDocumentFieldId,
					D.EdoDocumentId,
					D.RecognizedValue,
					D.FinalValue,
					D.Equal,
					D.TaskCreationDisabled,
					D.CreateDate,
					D.UpdateDate,
					D.DocumentTypeId,
					D.DocumentTypeName,
					D.DocumentTypeCode,
					D.DocumentFieldId,
					D.DocumentFieldName,
					D.DocumentFieldCode
				FROM #t_dm_CollectionDocRecognition AS D
			COMMIT
		END
        

	end try
	begin catch
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		;throw 
	end catch
END
