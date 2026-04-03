-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 23.05.2025
-- Description:	Builds an JSON payload for the specified CommunicationId.
-- exec Monitoring.GetFreePlaneTextEmail_JSON_tmp '1DF6A413-0199-49FA-9D94-793A5AD4F0B8', 1
-- =============================================
CREATE   PROCEDURE [etl].[GetFreePlaneTextEmail_JSON]
	@CommunicationId nvarchar(36)
	, @isDebug bit = 0
	WITH EXECUTE AS OWNER
AS
BEGIN
	SET NOCOUNT ON;

	-- 1. Валидация
	IF NOT EXISTS (
		SELECT 1
		FROM etl.Email2Send
		WHERE CommunicationId   = @CommunicationId
	)	
		THROW 50010, N'Запись с указанным CommunicationId не найдена.', 1;

	-- 2. Временная таблица получателей и текст письма
	DROP TABLE IF EXISTS #t_recipients
	SELECT
		communicationId = NEWID()
		, email = TRIM(v.value)
		, name	= TRIM(v.value)
	INTO		#t_recipients
	FROM		etl.Email2Send s
	CROSS APPLY string_split(s.recipients, ';') as v
	WHERE	s.CommunicationId   = @CommunicationId AND
			TRIM(v.value) <> ''

	DECLARE
        @FreePlaneSubject NVARCHAR(255),
        @FreePlaneText    NVARCHAR(MAX)

    SELECT  @FreePlaneSubject = subject,
            @FreePlaneText    = body
    FROM    etl.Email2Send
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
	                                                        communicationId  = r.communicationId,
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
