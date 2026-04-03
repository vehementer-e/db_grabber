--DWH-69
-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 23.05.2025
-- Description:	temporary procedure Inserts a new free-text email request into the outbox table etl.t_2_sendEmail 
-- and returns its generated CommunicationId.
/*
	declare @CommunicationId nvarchar(36) 
	exec [etl].[Add_Email2Send]
		@recipients = 'dwh112@carmoney.ru'
		,@subject = 'test2'
		,@body = 'test2'
		,@CommunicationId = @CommunicationId out
		select @CommunicationId
		select * from etl.Email2Send
*/

-- =============================================
CREATE     PROCEDURE [etl].[Add_Email2Send]
	 @recipients        NVARCHAR(MAX)  -- 1) список через «,» или «;»
     , @subject	NVARCHAR(255)         -- 2) тема письма
     , @body	NVARCHAR(MAX)         -- 3) произвольный текст
	 , @CommunicationId UNIQUEIDENTIFIER = null OUTPUT -- Выходной параметр
AS
BEGIN
	/* ----------------------- валидация ------------------------*/
    IF NULLIF(LTRIM(RTRIM(@recipients)), '') IS NULL
        THROW 50001, N'Параметр @recipients не заполнен.', 1

    IF NULLIF(LTRIM(RTRIM(@subject)), '') IS NULL
        THROW 50002, N'Параметр @subject не заполнен.', 1

    /* ---------------------- нормализация ----------------------*/
    SET @recipients = REPLACE(@recipients, ',', ';')
	--SET @recipients = REPLACE(@recipients, ';', ';')

    /* ------------------- заполнение таблицы -------------------*/
	BEGIN TRY
		BEGIN TRANSACTION
			DECLARE @OutIds TABLE (CommunicationId UNIQUEIDENTIFIER);
			INSERT INTO etl.Email2Send (recipients , subject, body)
			OUTPUT inserted.CommunicationId INTO @OutIds
			VALUES (@recipients, @subject, @body)
		COMMIT TRANSACTION
		select @CommunicationId = CommunicationId
		FROM @OutIds
		
	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0
			ROLLBACK TRANSACTION
		THROW;
	END CATCH

	/* ----------------- Вернем вставленный uid -----------------*/

	
END
