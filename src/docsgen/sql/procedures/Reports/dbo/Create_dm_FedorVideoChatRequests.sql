-- =======================================================
-- Create: 11.08.2023. А.Никитин
-- Description:	DWH-2183 Заполнение витрины по Видеочату
-- =======================================================
CREATE   PROC [dbo].[Create_dm_FedorVideoChatRequests]
	@days int = 20, -- актуализация витрины за последние @days дней
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isDebug int = 0
AS 
BEGIN
	SET NOCOUNT ON 
	SET XACT_ABORT ON

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)     

	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024), @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)
	DECLARE @InsertRows int = 0, @DeleteRows int = 0

	SELECT @eventName = 'dbo.Create_dm_FedorVideoChatRequests', @eventType = 'info', @SendEmail = 0

	BEGIN TRY

		DROP TABLE IF EXISTS #t_Contact_Call
		CREATE TABLE #t_Contact_Call
		(
			call_type_name varchar(255),
			result_name varchar(255),
			IdCheckType int,
			SortOrder int
		)
		INSERT #t_Contact_Call
		(
			call_type_name,
			result_name,
			IdCheckType,
			SortOrder
		)
		SELECT DISTINCT
			call_type_name = CheckListItemType.Name COLLATE Cyrillic_General_CI_AS,
			result_name = CheckListItemStatus.Name COLLATE Cyrillic_General_CI_AS,
			--CheckListItemType.IsDeleted,
			--CheckListItemType.Name,
			--CheckListItemType.SortOrder,
			CheckListItemType.IdCheckType,
			--CheckListItemType.LoginomPropertyNumber,
			--CheckListItemStatus.LoginomNumber,
			CheckListItemStatus.SortOrder
		FROM Stg._fedor.dictionary_CheckListItemType AS CheckListItemType
			INNER JOIN Stg._fedor.core_CheckListItemTypeAndCheckListItemStatus AS CH_IT_IS
				ON CH_IT_IS.IdType = CheckListItemType.Id
			INNER JOIN Stg._fedor.dictionary_CheckListItemStatus AS CheckListItemStatus
				ON CheckListItemStatus.Id = CH_IT_IS.IdCheckListItemStatus
		WHERE 1=1
			AND CheckListItemType.Name = 'Видеочат'  -- LIKE '%видео%'
		ORDER BY 
			--CheckListItemType.SortOrder, 
			CheckListItemType.IdCheckType,
			CheckListItemStatus.SortOrder,
			result_name


		DROP TABLE IF EXISTS #core_ClientRequest

		SELECT cr.* 
			,ФИО_Клиента =concat_ws(' '
				, isnull(cr.ClientLastName  , cr_ci.LastName)
				, isnull(cr.ClientFirstName , cr_ci.FirstName)
				, isnull(cr.ClientMiddleName, cr_ci.MiddleName)
				) COLLATE Cyrillic_General_CI_AS
		INTO #core_ClientRequest
		FROM Stg._fedor.core_ClientRequest AS cr
		left join stg._fedor.core_ClientRequestClientInfo cr_ci
			on cr_ci.id = cr.id
			WHERE cr.CreatedOn > '20200902' -- дата старта ФЕДОР в проде
				AND dateadd(hour,3,cr.[CreatedOn]) > dateadd(day,-@days,cast(getdate() as date))
				--NOT Installment
				AND isnull(cr.IsInstallment,0) <>1 
				AND isnull(cr.Type, 0) = 0 -- 'ПТС'

		DROP TABLE IF EXISTS #t_dm_VideoChat

		SELECT DISTINCT
            created_at = getdate(),
            updated_at = getdate(),
			GuidЗаявки = ClientRequest.Id,
			НомерЗаявки = ClientRequest.Number COLLATE Cyrillic_General_CI_AS,
			ДатаВремяЗаведенияЗаявки = cast(ClientRequest.CreatedOn AS datetime2(0)),
			ДатаЗаведенияЗаявки = cast(ClientRequest.CreatedOn AS date),
			ВремяЗаведенияЗаявки = cast(ClientRequest.CreatedOn AS time(0)),
			ФИО_Клиента = ClientRequest.ФИО_Клиента,
			ФИО_Верификатора = concat_ws(' '
				, Users.LastName
				, Users.FirstName
				, Users.MiddleName) COLLATE Cyrillic_General_CI_AS,
			[Этап] = 
				CASE CheckListItemType.IdCheckType
					WHEN 2 THEN 'Верификация клиента'
					WHEN 3 THEN 'Верификация ТС'
					ELSE 'не определен'
				END,
			ДатаВремяЗвонка = cast(CheckListItem.CreatedOn AS datetime2(0)),
			ТипЗвонка = CheckListItemType.Name COLLATE Cyrillic_General_CI_AS,
			РезультатЗвонка = CheckListItemStatus.Name COLLATE Cyrillic_General_CI_AS,
			--CheckListItemId = CheckListItem.Id,
			ДатаВремяКомментария = cast(Comment.CreatedOn AS datetime2(0)),
			КомментарийИзЧекЛиста = substring(Comment.Message, 1, 1024) COLLATE Cyrillic_General_CI_AS
			--КомментарийИзЧекЛиста = cast(NULL AS nvarchar(2048))
		INTO #t_dm_VideoChat
		FROM #core_ClientRequest AS ClientRequest
			INNER JOIN Stg._fedor.core_CheckListItem AS CheckListItem
				ON ClientRequest.Id = CheckListItem.IdClientRequest
			INNER JOIN Stg._fedor.dictionary_CheckListItemType AS CheckListItemType
				ON CheckListItemType.Id = CheckListItem.IdType

			-- типы звонков
			INNER JOIN (
				SELECT DISTINCT call_type_name = CC.call_type_name
				FROM #t_Contact_Call AS CC
				) AS call_type
				ON call_type.call_type_name = CheckListItemType.Name COLLATE Cyrillic_General_CI_AS

			LEFT JOIN Stg._fedor.core_CheckListItemTypeAndCheckListItemStatus AS CH_IT_IS
				ON CH_IT_IS.IdType = CheckListItem.IdType
				AND CH_IT_IS.IdCheckListItemStatus = CheckListItem.IdStatus
			LEFT JOIN Stg._fedor.dictionary_CheckListItemStatus AS CheckListItemStatus
				ON CheckListItemStatus.Id = CheckListItem.IdStatus
			LEFT JOIN Stg._fedor.core_Comment AS Comment
				ON Comment.[IdEntity] = CheckListItem.Id
			LEFT JOIN Stg._fedor.core_user AS Users
				ON Users.Id = Comment.IdOwner



		DROP TABLE IF EXISTS #t_dm_FedorVideoChatRequests


		SELECT DISTINCT
			A.created_at,
			A.updated_at,
			A.GuidЗаявки,
			A.НомерЗаявки,
			A.ДатаВремяЗаведенияЗаявки,
			A.ДатаЗаведенияЗаявки,
			A.ВремяЗаведенияЗаявки,
			A.ФИО_Клиента,
			A.ФИО_Верификатора,
			A.Этап,
			A.ДатаВремяЗвонка,
			A.ТипЗвонка,
			A.РезультатЗвонка,
			A.КомментарийИзЧекЛиста 
		INTO #t_dm_FedorVideoChatRequests
		FROM (
			SELECT 
				V.created_at,
				V.updated_at,
				V.GuidЗаявки,
				V.НомерЗаявки,
				V.ДатаВремяЗаведенияЗаявки,
				V.ДатаЗаведенияЗаявки,
				V.ВремяЗаведенияЗаявки,
				V.ФИО_Клиента,
				--V.ФИО_Верификатора,
				ФИО_Верификатора = 
					first_value(V.ФИО_Верификатора) 
						OVER(PARTITION BY 
								V.created_at,
								V.updated_at,
								V.GuidЗаявки,
								V.НомерЗаявки,
								V.ДатаВремяЗаведенияЗаявки,
								V.ДатаЗаведенияЗаявки,
								V.ВремяЗаведенияЗаявки,
								V.ФИО_Клиента,
								V.Этап,
								V.ДатаВремяЗвонка,
								V.ТипЗвонка,
								V.РезультатЗвонка
							ORDER BY V.ДатаВремяКомментария DESC
						),
				V.Этап,
				V.ДатаВремяЗвонка,
				V.ТипЗвонка,
				V.РезультатЗвонка,
				--КомментарийИзЧекЛиста = substring(string_agg(V.КомментарийИзЧекЛиста , ', ') WITHIN GROUP (ORDER BY V.ДатаВремяКомментария), 1, 2048)
				КомментарийИзЧекЛиста = 
					first_value(V.КомментарийИзЧекЛиста) 
						OVER(PARTITION BY 
								V.created_at,
								V.updated_at,
								V.GuidЗаявки,
								V.НомерЗаявки,
								V.ДатаВремяЗаведенияЗаявки,
								V.ДатаЗаведенияЗаявки,
								V.ВремяЗаведенияЗаявки,
								V.ФИО_Клиента,
								V.Этап,
								V.ДатаВремяЗвонка,
								V.ТипЗвонка,
								V.РезультатЗвонка
							ORDER BY V.ДатаВремяКомментария DESC
						)
			FROM #t_dm_VideoChat AS V
			) AS A

		--CREATE CLUSTERED INDEX clix_GuidЗаявки ON #t_dm_FedorVideoChatRequests(GuidЗаявки, Этап, ДатаВремяЗвонка)
		--CREATE INDEX ix_GuidЗаявки ON #t_dm_FedorVideoChatRequests(GuidЗаявки)
		CREATE INDEX ix_GuidЗаявки
		ON #t_dm_FedorVideoChatRequests(GuidЗаявки, Этап, ДатаВремяЗвонка)


		--IF @isDebug = 1 BEGIN
		--	SELECT TOP 100 *
		--	FROM #t_dm_FedorVideoChatRequests
		--	ORDER BY НомерЗаявки, Этап, ДатаВремяЗвонка
		--	--test
		--	--RETURN 0
		--END

	IF object_id('dbo.dm_FedorVideoChatRequests') IS NULL
	BEGIN
		SELECT TOP(0)
			created_at,
			updated_at,
			GuidЗаявки,
			НомерЗаявки,
			ДатаВремяЗаведенияЗаявки,
			ДатаЗаведенияЗаявки,
			ВремяЗаведенияЗаявки,
			ФИО_Клиента,
			ФИО_Верификатора,
			Этап,
			ДатаВремяЗвонка,
			ТипЗвонка,
			РезультатЗвонка,
			КомментарийИзЧекЛиста
		INTO dbo.dm_FedorVideoChatRequests
		FROM #t_dm_FedorVideoChatRequests

		alter table dbo.dm_FedorVideoChatRequests
			alter column GuidЗаявки uniqueidentifier not null

		--ALTER TABLE dbo.dm_FedorVideoChatRequests
		--	ADD CONSTRAINT PK_dm_FedorVideoChatRequests PRIMARY KEY CLUSTERED (GuidЗаявки, Этап)

		CREATE CLUSTERED INDEX clix_GuidЗаявки_Этап ON dbo.dm_FedorVideoChatRequests(GuidЗаявки, Этап, ДатаВремяЗвонка)
		--CREATE INDEX ix_GuidЗаявки ON dbo.dm_FedorVideoChatRequests(GuidЗаявки)
	END

	UPDATE R
	SET R.created_at = C.created_at
	FROM #t_dm_FedorVideoChatRequests AS R
		INNER JOIN dbo.dm_FedorVideoChatRequests AS C
			ON C.GuidЗаявки = R.GuidЗаявки
			AND C.Этап = R.Этап
			AND C.ДатаВремяЗвонка = R.ДатаВремяЗвонка

	BEGIN TRAN

		DELETE C
		FROM dbo.dm_FedorVideoChatRequests AS C
		WHERE EXISTS(
			SELECT TOP(1) 1
			FROM #t_dm_FedorVideoChatRequests AS R
			WHERE R.GuidЗаявки = C.GuidЗаявки
			)

		INSERT dbo.dm_FedorVideoChatRequests
		(
			created_at,
			updated_at,
			GuidЗаявки,
			НомерЗаявки,
			ДатаВремяЗаведенияЗаявки,
			ДатаЗаведенияЗаявки,
			ВремяЗаведенияЗаявки,
			ФИО_Клиента,
			ФИО_Верификатора,
			Этап,
			ДатаВремяЗвонка,
			ТипЗвонка,
			РезультатЗвонка,
			КомментарийИзЧекЛиста
		)
		SELECT
			created_at,
			updated_at,
			GuidЗаявки,
			НомерЗаявки,
			ДатаВремяЗаведенияЗаявки,
			ДатаЗаведенияЗаявки,
			ВремяЗаведенияЗаявки,
			ФИО_Клиента,
			ФИО_Верификатора,
			Этап,
			ДатаВремяЗвонка,
			ТипЗвонка,
			РезультатЗвонка,
			КомментарийИзЧекЛиста
		FROM #t_dm_FedorVideoChatRequests
	COMMIT


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

		SELECT @message = 'Ошибка заполнения dbo.dm_FedorVideoChatRequests'

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
