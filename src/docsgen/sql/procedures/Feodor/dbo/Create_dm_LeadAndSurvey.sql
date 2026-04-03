-- =======================================================
-- Modified: 26.05.2023. А.Никитин
-- Description:	DWH-2079 Оптимизировать процедуру Create_dm_LeadAndSurvey
-- =======================================================
--exec Create_dm_LeadAndSurvey
CREATE   PROC [dbo].[Create_dm_LeadAndSurvey]
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isDebug int = 0
AS
BEGIN

	SET NOCOUNT ON
	SET XACT_ABORT ON

	SELECT @ProcessGUID = isnull(@ProcessGUID, newid())
	SELECT @isDebug = isnull(@isDebug, 0)     

	DECLARE @eventName nvarchar(50), @eventType nvarchar(50), @message nvarchar(1024) --, @description nvarchar(1024)
	DECLARE @SendEmail int
	DECLARE @error_description nvarchar(1024)
	DECLARE @LastPartitionID int
	DECLARE @Rowversion_Lead binary(8), @Rowversion_LeadAndSurvey binary(8)
	DECLARE @DeleteRows int = 0, @InsertRows int = 0, @CountRows int = 0
	DECLARE @DurationSec int, @StartDate datetime = getdate()

	SELECT @eventName = 'Feodor.dbo.Create_dm_LeadAndSurvey', @eventType = 'info', @SendEmail = 0

	BEGIN TRY

		SELECT 
			@Rowversion_Lead = isnull(max(D.Rowversion_Lead), 0x00),
			@Rowversion_LeadAndSurvey = isnull(max(D.Rowversion_LeadAndSurvey), 0x00)
		FROM dbo.dm_LeadAndSurvey AS D

		IF @isDebug = 1 BEGIN
			SELECT Rowversion_Lead = @Rowversion_Lead, Rowversion_Lead = @Rowversion_LeadAndSurvey
		END

		--1
		DROP TABLE IF EXISTS #t_dm_SurveyData
		CREATE TABLE #t_dm_SurveyData
		(
			[ID лида Fedor] [uniqueidentifier] NOT NULL,
			[ID LCRM] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			[SurveyData] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			Rowversion_Lead binary (8) NULL,
			Rowversion_LeadAndSurvey binary (8) NULL	  ,
     [Дата лида] [DATETIME2](7)		NULL

		)

		INSERT #t_dm_SurveyData
		(
		    [ID лида Fedor],
		    [ID LCRM],
		    SurveyData,
		    Rowversion_Lead,
		    Rowversion_LeadAndSurvey  ,
			[Дата лида]
		)
		SELECT
			[ID лида Fedor] = L.Id,
			[ID LCRM] = L.IdExternal,
			LS.SurveyData,
			Rowversion_Lead = L.RowVersion,
			Rowversion_LeadAndSurvey = LS.Rowversion  ,
			[Дата лида] = dateadd(hour, 3, l.createdon	 )
		FROM Stg._fedor.core_Lead AS L --WITH(INDEX=ix_Rowversion)
			INNER JOIN Stg._fedor.core_LeadAndSurvey AS LS --WITH(INDEX=clix_IdLead)
				ON L.Id = LS.idlead
		WHERE L.RowVersion > @Rowversion_Lead

		UNION 

		SELECT
			[ID лида Fedor] = L.Id,
			[ID LCRM] = L.IdExternal,
			LS.SurveyData,
			Rowversion_Lead = L.RowVersion,
			Rowversion_LeadAndSurvey = LS.Rowversion	   ,
			[Дата лида] = dateadd(hour, 3, l.createdon	 )

		FROM Stg._fedor.core_Lead AS L --WITH(INDEX=ClusteredIndexID)
			INNER JOIN Stg._fedor.core_LeadAndSurvey AS LS --WITH(INDEX=ix_Rowversion)
				ON L.Id = LS.idlead
		WHERE LS.Rowversion > @Rowversion_LeadAndSurvey


		--2
		DROP TABLE IF EXISTS #t_dm_LeadAndSurvey
		CREATE TABLE #t_dm_LeadAndSurvey
		(
			[ID лида Fedor] [uniqueidentifier] NOT NULL,
			[ID LCRM] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			[Question] [nvarchar] (4000) COLLATE Latin1_General_BIN2 NULL,
			[Answer] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
			Rowversion_Lead binary (8) NULL,
			Rowversion_LeadAndSurvey binary (8) NULL ,
     [Дата лида] [DATETIME2](7)		NULL
		)

		INSERT #t_dm_LeadAndSurvey
		(
			[ID лида Fedor],
			[ID LCRM],
			Question,
			Answer,
			Rowversion_Lead,
			Rowversion_LeadAndSurvey,
			[Дата лида]
		)
		SELECT 
			T.[ID лида Fedor],
            T.[ID LCRM],
			Question = D.[Key],
			Answer = D.[Value],
            T.Rowversion_Lead,
            T.Rowversion_LeadAndSurvey 
			,t.[Дата лида]
		FROM #t_dm_SurveyData AS T
			OUTER APPLY OPENJSON(T.SurveyData, '$') AS D
		WHERE isjson(T.SurveyData) = 1


		SELECT @CountRows = count(*)
		FROM #t_dm_LeadAndSurvey

		IF @isDebug = 1 BEGIN
			SELECT @CountRows
			--RETURN 0
		END

		IF @CountRows > 0 BEGIN
			BEGIN TRAN
				CREATE INDEX ix1 ON #t_dm_LeadAndSurvey([ID лида Fedor])

				DELETE D
				FROM dbo.dm_LeadAndSurvey AS D
					INNER JOIN #t_dm_LeadAndSurvey AS T
						ON T.[ID лида Fedor] = D.[ID лида Fedor]

				SELECT @DeleteRows = @@ROWCOUNT
		 --alter table dm_LeadAndSurvey add 	  [Дата лида] datetime2(7)
				INSERT dbo.dm_LeadAndSurvey
				(
					[ID лида Fedor],
					[ID LCRM],
					Question,
					Answer,
					Rowversion_Lead,
					Rowversion_LeadAndSurvey  ,
					[Дата лида]
				)
				SELECT 
					T.[ID лида Fedor],
					T.[ID LCRM],
					T.Question,
					T.Answer,
					T.Rowversion_Lead,
					T.Rowversion_LeadAndSurvey 	,
					T.[Дата лида]
				FROM #t_dm_LeadAndSurvey AS T

				SELECT @InsertRows = @@ROWCOUNT
			COMMIT
		END

		SELECT @DurationSec = datediff(SECOND, @StartDate, getdate())

		SELECT @message = 
			concat(
				'Заполнение Feodor.dbo.dm_LeadAndSurvey. ',
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
				'Ошибка заполнения Feodor.dbo.dm_LeadAndSurvey. ',
				'Удалено: ', convert(varchar(10), @DeleteRows), '. ',
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
