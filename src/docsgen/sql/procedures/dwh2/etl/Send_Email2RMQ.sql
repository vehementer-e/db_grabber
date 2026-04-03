-- dwh-69
-- =============================================
-- Author:        Shubkin Aleksandr
-- Create date: 26.05.2025
-- Description:    picks unsent e-mails from etl.Email2Send, wraps them for RMQ
--                and sends each package to COMC via HTTP.
/*
exec etl.Send_Email2RMQ
	@BatchSize = 1
	@isDebug = 1
	*/
-- SELECT * FROM etl.email2send
-- =============================================
CREATE    PROCEDURE [etl].[Send_Email2RMQ]
       @env              NVARCHAR(255)		= 'prod'          -- uat | prod
     , @CommunicationId  UNIQUEIDENTIFIER	= NULL         --  single GUID
     , @CommunicationIds NVARCHAR(MAX)		= NULL         --  CSV of GUIDs
     , @BatchSize		 smallint			= 100
	 , @isDebug          BIT				= 0
	
AS
BEGIN
	-- Переменные для retry
	DECLARE @attempt      INT  = 1
	DECLARE @maxAttempts  INT  = 2      -- 1 основная + 1 retry
    -- collecting ids
	SET @CommunicationIds  = nullif(CONCAT_WS(',', @CommunicationIds, @CommunicationId), '')

    DROP TABLE IF EXISTS #t_ids
    CREATE TABLE #t_ids (CommunicationId UNIQUEIDENTIFIER NOT NULL)
    IF @CommunicationIds IS NOT NULL
    BEGIN
        INSERT INTO #t_ids (CommunicationId)
        SELECT trim(value) as CommunicationId
        FROM STRING_SPLIT(@CommunicationIds, ',')
        WHERE TRY_CAST(trim(value) as UNIQUEIDENTIFIER) is not null
    END
    ELSE
    BEGIN
        INSERT INTO #t_ids (CommunicationId)
        SELECT top(@BatchSize)
			   CommunicationId
        FROM etl.Email2Send
        WHERE    SendDate is null
        order by isnull(UpdatedAt, CreatedAt) asc
    END
    -- params for http-request
    DECLARE
        -- for request
        @rmqSenderUrl  NVARCHAR(255) = 'https://dwhex.carm.corp'
    DEClARE
        @ServiceUrl    VARCHAR(1024) = CONCAT_WS('/', @rmqSenderUrl, @env,
                                                 'RMQProducer/api/ToComc'),
        @httpMethod        VARCHAR(10)   = 'POST',
        @contentType    NVARCHAR(64)  = 'application/json',
    
        -- for json
        @exchangeName  NVARCHAR(255) = 'COMC.Message.1.1',
        @routingKey    NVARCHAR(255) = 'email',
        @procedureName NVARCHAR(255) = 'dwh2.[etl].[GetFreePlaneTextEmail_JSON]'

    -- cursor part
    DECLARE IdCursor CURSOR FAST_FORWARD FOR
        SELECT CommunicationId FROM #t_Ids
    DECLARE @CurId UNIQUEIDENTIFIER
    OPEN IdCursor;
        FETCH NEXT FROM IdCursor INTO @CurId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
		SET @attempt = 0
        BEGIN TRY
			DECLARE
                @status      INT           = -1,
                @statusText  VARCHAR(1024) = '',
                @errorSource VARCHAR(255)  = '',
                @errorDesc   VARCHAR(255)  = '',
                @respText    NVARCHAR(MAX) = '',
                @guidResult  UNIQUEIDENTIFIER = NEWID()

            DECLARE @procParams etl.utt_rmqProcParams
            INSERT INTO @procParams (Name, Value)
            VALUES ('CommunicationId', CONVERT(NVARCHAR(36), @CurId))
    
            DECLARE @paramsValues NVARCHAR(MAX)

			WHILE (@attempt < @maxAttempts)
			BEGIN
				SET @attempt += 1

				SELECT	@paramsValues = etl.GetJson4RMQProducer(
					    @exchangeName
					    , @routingKey
					    , @procedureName
					    , @procParams
				)
				IF @isDebug = 1
				BEGIN select @paramsValues	as paramsValues, 
							 @attempt		as attempt		END

				EXEC CommonDb.dbo.RequestHttpWebService
					@url                    = @ServiceUrl,
					@httpMethod             = @httpMethod,
					@paramsValues           = @paramsValues,
					@contentType            = @contentType,
					@status                 = @status       OUTPUT,
					@statusText             = @statusText   OUTPUT,
					@errorSource            = @errorSource  OUTPUT,
					@errorDesc              = @errorDesc    OUTPUT,
					@responseResult         = @respText     OUTPUT,
					@IsResponseOutputResult = 0,
					@IsSaveResult2Table     = 1,
					@outGuidResultId        = @guidResult
				
				IF (@status BETWEEN 200 AND 299)
					BREAK;							-- успех → выходим
				IF (@status BETWEEN 500 AND 599)    
					CONTINUE;                       -- серверная 5xx → повторим

				BREAK								-- если 4хх или др. → выходим
			END
            -- финальная обработка
			IF @status BETWEEN 200 AND 299
			BEGIN
				UPDATE etl.Email2Send
					SET SendDate	= GETDATE()
					, StatusCode		= @status
					, ErrorMessage	= NULL
                    ,UpdatedAt      = GETDATE()
				WHERE CommunicationId = @CurId

				IF @isDebug = 1
				BEGIN
					SELECT CONCAT_WS(' ', 'Email', @CurId, 'sent. Status code =', @status)
				END
			END
			ELSE
			BEGIN
				UPDATE etl.Email2Send
					SET StatusCode	= @status
						, ErrorMessage	= CASE
											WHEN @status BETWEEN 400 AND 499
												THEN CONCAT_WS(' ', 'Клиентская ошибка', @status
                                                , 'смотрите детали в [dbo].[RequestHttpWebService] по id '
                                                , @guidResult )
											WHEN @status BETWEEN 500 AND 599
												THEN CONCAT_WS(' ', 'Серверная ошибка', @status)
											ELSE CONCAT_WS(' ', 'Неизвестная ошибка', @status
                                            , 'смотрите детали в [dbo].[RequestHttpWebService] по id '
                                            , @guidResult )
										   END
                    ,UpdatedAt  = GETDATE()
				WHERE CommunicationId = @CurId
				DECLARE @err NVARCHAR(4000) = CONCAT_WS(' '
                    , N':interrobang: Ошибка вызова сервиса по отправке в RMQ.  status='
                    , @status
                    , N'text=', @statusText
                    , ISNULL(N'src='  + @errorSource, N'')
                    , ISNULL(N'desc=' + @errorDesc,   N''))
                EXEC LogDb.dbo.SendToSlack_dwhNotification @err;
                EXEC LogDb.dbo.LogAndSendMailToAdmin
                     'Send_Email2RMQ', 'Error',
                     'HTTP error', @err;
                -- не апдейтим SendDate
			END     
        END TRY
        BEGIN CATCH
            DECLARE @errMsg NVARCHAR(MAX) = CONCAT_WS(' ',
                N'ErrorNumber:',  ERROR_NUMBER(), CHAR(13)+CHAR(10),
                N'Severity:',     ERROR_SEVERITY(),  CHAR(13)+CHAR(10),
                N'State:',        ERROR_STATE(),     CHAR(13)+CHAR(10),
                N'Line:',         ERROR_LINE(),      CHAR(13)+CHAR(10),
                N'Message:',      ERROR_MESSAGE())
            declare @slacknotification nvarchar(255)
            select @slacknotification = CONCAT_WS(' ', ':exclamation: Ошибка отправки email', @CurId)
            EXEC LogDb.dbo.SendToSlack_dwhNotification @slacknotification
            EXEC LogDb.dbo.LogAndSendMailToAdmin
                'Send_Email2RMQ', 'Error', 'Catch', @errMsg;
            -- оставляем SendDate = NULL
        END CATCH
         FETCH NEXT FROM IdCursor INTO @CurId;
    END
    CLOSE IdCursor;
    DEALLOCATE IdCursor;
END



