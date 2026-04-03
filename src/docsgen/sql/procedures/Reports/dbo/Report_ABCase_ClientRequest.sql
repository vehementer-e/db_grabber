-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 12.05.25
-- Description:	dataset for отчет по AB Case заявкам
-- Example: EXEC Reports.dbo.Report_ABCase_ClientRequest 
-- =============================================
CREATE PROCEDURE [dbo].[Report_ABCase_ClientRequest]
   @dateFrom           DATE            = NULL,
   @dateTo             DATE            = NULL,
   @testBranch         NVARCHAR(MAX)   = NULL,  
   @hasPhotoRequest    NVARCHAR(50)    = NULL  
AS
BEGIN
    SET NOCOUNT ON;
	SET @testBranch = CASE
						WHEN @testBranch IN ('1','-1') THEN N''
						ELSE @testBranch
					END
    SELECT
		@dateFrom = ISNULL(@dateFrom, '2000-01-01'),
		@dateTo   = ISNULL(@dateTo,   CAST(GETDATE() AS DATE))

	 SELECT
        ds.[Дата создания заявки],
        ds.[Номер заявки],
        ds.[Название А/В теста],
        ds.[id A/B теста],
        ds.[Ветка, по которой пришла заявка],
        ds.[Запрос фото],
        ds.[Уникальный идентификатор заявки]
	FROM (
		SELECT
				[Дата создания заявки]				= dateadd(HOUR, 3, request.CreatedOn)
			,	[Номер заявки]						= request.Number
			,	[Название А/В теста]				= dictionary.Name
			,	[id A/B теста]						= dictionary.id
			,	[Ветка, по которой пришла заявка]	= concat_ws(' ', 'Ветка', ISNULL(cast(branch_code.BranchValue as nvarchar(255)), N'не определена'))
			,	BranchValue							= branch_code.BranchValue
			,	[Запрос фото]						= CASE WHEN CluentRequests_with_passport_photo.ClientRequestId is NULL THEN 'Нет' ELSE 'Да' END
			,	[Уникальный идентификатор заявки]	= request.id
		FROM		stg.[_fedor].[core_ClientRequest]			request
		LEFT JOIN	stg.[_fedor].core_ClientRequestRealAbCase	link_request_case	ON request.id	 = link_request_case.ClientRequestId
		LEFT JOIN	stg.[_fedor].dictionary_AbCase				dictionary			ON dictionary.id = link_request_case.AbCaseId
		LEFT JOIN	(
			SELECT DISTINCT additional_photo.ClientRequestId
			FROM		stg.[_fedor].core_ClientRequestAdditionalPhoto	additional_photo
			INNER JOIN stg.[_fedor].dictionary_AttachmentType			dictionary_attachment ON additional_photo.AttachmentTypeId = dictionary_attachment.id
			WHERE dictionary_attachment.code IN ('pass2_3', 'clientPhoto')	)	CluentRequests_with_passport_photo ON CluentRequests_with_passport_photo.ClientRequestId = request.id
		OUTER APPLY dbo.tvf_getBranchByCode(dictionary.code) as branch_code
		WHERE
			CAST( dateadd(HOUR, 3, request.CreatedOn) AS DATE) BETWEEN @dateFrom AND @dateTo
	) as ds
	WHERE
		(
			(
				@testBranch = '' AND
				ds.[Ветка, по которой пришла заявка] = 'Ветка не определена'
			) OR
			(
				nullif(@testBranch, '') IS NOT NULL AND
				ds.BranchValue IN (SELECT TRIM(value) FROM string_split(@testBranch,','))
			)
		)
		AND
		(
			nullif(@hasPhotoRequest, '') IS NULL OR
			ds.[Запрос фото] IN (
				SELECT TRIM(value)
				FROM STRING_SPLIT(@hasPhotoRequest, ',')
			)
		)
	ORDER BY
		ds.[Дата создания заявки]
		, ds.[Номер заявки]
END
