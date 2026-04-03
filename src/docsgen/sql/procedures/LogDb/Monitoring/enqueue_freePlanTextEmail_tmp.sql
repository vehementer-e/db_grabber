-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 23.05.2025
-- Description:	temporary procedure Inserts a new free-text email request into the outbox table etl.t_2_sendEmail 
-- and returns its generated CommunicationId.
-- =============================================
CREATE PROCEDURE Monitoring.enqueue_freePlanTextEmail_tmp
	 @Emails        NVARCHAR(MAX)         -- 1) список через «,» или «;»
     , @mailSubject	NVARCHAR(255)         -- 2) тема письма
     , @mailText	NVARCHAR(MAX)         -- 3) произвольный текст
AS
BEGIN
	/* ----------------------- валидация ------------------------*/
    IF NULLIF(LTRIM(RTRIM(@Emails)), '') IS NULL
        THROW 50001, N'Параметр @Emails не заполнен.', 1

    IF NULLIF(LTRIM(RTRIM(@mailSubject)), '') IS NULL
        THROW 50002, N'Параметр @FreePlaneSubject не заполнен.', 1

    /* ---------------------- нормализация ----------------------*/
    SET @Emails = REPLACE(@Emails, ',', ';')

    /* ------------------- заполнение таблицы -------------------*/
    DECLARE @CommunicationId UNIQUEIDENTIFIER = NEWID()

    INSERT INTO ##t_2_sendEmail_0xE26FBE7F1C15B2B32702AAD27A55BF0E06198C0E96C0BB6076877D239E66D513
	(CommunicationId, Emails, mailSubject, mailText)
    VALUES (@CommunicationId, @Emails, @mailSubject, @mailText)
END
