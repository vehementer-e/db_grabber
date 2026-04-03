-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 23.05.2025
-- Description:	Builds an JSON payload for the specified CommunicationId.
-- exec Monitoring.GetFreePlaneTextEmail_JSON_tmp '1DF6A413-0199-49FA-9D94-793A5AD4F0B8', 1
-- =============================================
CREATE PROCEDURE [Monitoring].[GetFreePlaneTextEmail_JSON_tmp]
	@CommunicationId UNIQUEIDENTIFIER
	, @isDebug bit = 0
AS
BEGIN
	SET NOCOUNT ON;

	-- 1. Валидация
	IF NOT EXISTS (
		SELECT 1
		FROM ##t_2_sendEmail_0xE26FBE7F1C15B2B32702AAD27A55BF0E06198C0E96C0BB6076877D239E66D513
		WHERE CommunicationId   = @CommunicationId
	)	
		THROW 50010, N'Запись с указанным CommunicationId не найдена.', 1;

	-- 2. Временная таблица получателей и текст письма
	DROP TABLE IF EXISTS #t_recipients
	SELECT
		communicationId = s.CommunicationId
		, email = rtrim(ltrim(v.value))
		, name	= rtrim(ltrim(v.value))
	INTO		#t_recipients
	FROM		##t_2_sendEmail_0xE26FBE7F1C15B2B32702AAD27A55BF0E06198C0E96C0BB6076877D239E66D513 as s
	CROSS APPLY string_split(s.Emails, ';') as v
	WHERE	s.CommunicationId   = @CommunicationId AND
			rtrim(ltrim(v.value)) <> ''

	DECLARE
        @FreePlaneSubject NVARCHAR(255),
        @FreePlaneText    NVARCHAR(MAX)

    SELECT  @FreePlaneSubject = mailSubject,
            @FreePlaneText    = mailText
    FROM    ##t_2_sendEmail_0xE26FBE7F1C15B2B32702AAD27A55BF0E06198C0E96C0BB6076877D239E66D513
    WHERE   CommunicationId   = @CommunicationId

	if @isDebug = 1
	begin
		select * from #t_recipients
	end

	-- 3. Конструируем итоговый JSON
	DECLARE @result NVARCHAR(MAX)
	
	SELECT @result =
	(
	    SELECT  publishTime = DATEDIFF(SECOND, '1970-01-01', SYSUTCDATETIME()),
	            publisher   = 'dwh',
	            guid        = NEWID(),
	            docUrl      = 'https://wiki.carmoney.ru/x/pQo6Ag',
	            data        = JSON_QUERY(
	                            (SELECT  template = 'FREE_PLANE_TEXT',
	                                     params   = JSON_QUERY(
	                                                 (SELECT
	                                                        communicationId  = CONVERT(NVARCHAR(36), r.communicationId),
	                                                        email            = r.email,
	                                                        name             = r.name,
	                                                        freePlaneSubject = @FreePlaneSubject,
	                                                        freePlaneText    = @FreePlaneText
	                                                  FROM   #t_recipients AS r
	                                                  FOR JSON PATH)
	                                               )
	                             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
	                          )
	    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	)
	
	SELECT json = @result
END
