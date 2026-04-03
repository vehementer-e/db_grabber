
-- exec [etl].[Send_CollectionAgencyContracts2RMQ]

CREATE PROCEDURE [etl].[Send_CollectionAgencyContracts2RMQ_delete_10_04_2026]
    @env            NVARCHAR(255)    = 'prod',
    @isDebug        BIT              = 0,
    @crmClientGuid  UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --- Системные переменные —--
    DECLARE
        @spName            NVARCHAR(255)    = CONCAT('etl.', OBJECT_NAME(@@PROCID)),
        @rmqSenderUrl      NVARCHAR(255)    = 'https://dwhex.carm.corp',
        @ServiceUrl        VARCHAR(1024)    = CONCAT_WS('/', 'https://dwhex.carm.corp', @env, 'RMQProducer/api/Send2Rmq'),
        @httpMethod        VARCHAR(10)      = 'POST',
        @paramsValues      VARCHAR(MAX)     = '',
        @authHeader        NVARCHAR(64)     = '',
        @soapAction        VARCHAR(1024)    = NULL,
        @contentType       NVARCHAR(64)     = 'application/json',
        @status            INT              = -1,
        @statusText        VARCHAR(1024)    = '',
        @errorSource       VARCHAR(255)     = '',
        @errorDesc         VARCHAR(255)     = '',
        @responseResult    NVARCHAR(MAX)    = '',
        @GuidResultId      UNIQUEIDENTIFIER = NEWID(),
        
		--- для CATCH ------------------------------
        @error_description NVARCHAR(MAX)    = '',
        @text              NVARCHAR(400)    = '',
        @msg               NVARCHAR(255)    = '';

    ---- Параметры для JSON генератора —-----------
    DECLARE @procParams etl.utt_rmqProcParams;
    INSERT INTO @procParams (Name, Value)
    VALUES ('crmClientGuid', CONVERT(NVARCHAR(36), @crmClientGuid));

    ---- Настройки RMQ -------------------
    DECLARE
        @exchangeName  NVARCHAR(255) = 'interactions',
        @routingKey    NVARCHAR(255) = 'dwh.interaction.3203.1.1',
        @procedureName NVARCHAR(255) = 'dwh2.[etl].[GetCollectionAgenciesContracts_RMQ_JSON]';

    --------- Payload для продюсера —--------
    SELECT @paramsValues = etl.GetJson4RMQProducer
        (@exchangeName, @routingKey, @procedureName, @procParams);


    ------ вызов we-service --------------
    BEGIN TRY
        EXEC LogDb.etl.RequestHttpWebService
             @url                    = @ServiceUrl,
             @httpMethod             = @httpMethod,
             @paramsValues           = @paramsValues,
             @authHeader             = @authHeader,
             @soapAction             = @soapAction,
             @contentType            = @contentType,
             @status                 = @status           OUTPUT,
             @statusText             = @statusText       OUTPUT,
             @errorSource            = @errorSource      OUTPUT,
             @errorDesc              = @errorDesc        OUTPUT,
             @responseResult         = @responseResult   OUTPUT,
             @IsResponseOutputResult = 1,
             @IsSaveResult2Table     = 1,
             @outGuidResultId        = @GuidResultId     OUTPUT;

        
        IF @status NOT BETWEEN 200 AND 299
        BEGIN
            DECLARE @errorCode INT = 51000 + @status;
            DECLARE @responseError NVARCHAR(1024) = CONCAT(
                N':interrobang: Ошибка вызова сервиса RMQ.',
                N' statusCode = ', @status,
                N' statusText = ', @statusText,
                ISNULL(N' errorSource = ' + @errorSource, N''),
                ISNULL(N' errorDesc = '   + @errorDesc,   N''));
            THROW @errorCode, @responseError, 16;
        END
        ELSE
        BEGIN
            DECLARE @TotalSendPackages INT = NULL;
            IF ISJSON(@responseResult) = 1
                SET @TotalSendPackages =
                    JSON_VALUE(@responseResult, '$.data.attributes.totalSuccessfulResult');

            SET @msg = CONCAT(
                N'Данные о договорах коллекторских агентств загружены в RMQ.',
                CASE WHEN @TotalSendPackages IS NOT NULL
                     THEN CONCAT(N' Отправлено: ', @TotalSendPackages) ELSE N'' END);

            EXEC LogDb.dbo.SendToSlack_dwhNotification @msg;
            EXEC LogDb.dbo.LogAndSendMailToAdmin
                 'exec etl.Send_CollectionAgencyContracts2RMQ',
                 'Info', 'Done', '';
			/*-----------------------------------------------------------------
			   Получаем id отправленных сообщений
			-----------------------------------------------------------------*/
			DECLARE @MessageIds TABLE (id UNIQUEIDENTIFIER PRIMARY KEY);

			INSERT INTO @MessageIds (id)
			SELECT DISTINCT id
			FROM OPENJSON(@responseResult,
						  '$.data.relationships.messages.data')
				 WITH (id UNIQUEIDENTIFIER '$.id');

			/*-----------------------------------------------------------------
			  Обновляем учётную таблицу etl.rmq_sent_items
				 item_type = 'agent_credits'
			-----------------------------------------------------------------*/
			-- UPDATE существующих
			UPDATE rsi
			SET    rsi.last_sent  = GETDATE(),
				   rsi.force_send = 0,
				   rsi.ac_rowversion = ac.rowversion
			FROM   dwh2.etl.rmq_sent_items rsi
			JOIN   @MessageIds m ON m.id = rsi.item_id
			JOIN   dwh_new.[dbo].[agent_credits] ac on ac.row_id=rsi.item_id
			WHERE  rsi.item_type = 'agent_credits';

			-- INSERT новых
			INSERT INTO dwh2.etl.rmq_sent_items (item_id, item_type, last_sent, force_send, ac_rowversion)
			SELECT m.id, 'agent_credits', GETDATE(), 0, ac.rowversion
			FROM   @MessageIds m
			INNER  JOIN dwh_new.[dbo].[agent_credits] ac
				   ON  ac.row_id = m.id
			LEFT   JOIN dwh2.etl.rmq_sent_items rsi
				   ON  rsi.item_id   = m.id
				   AND rsi.item_type = 'agent_credits'
			WHERE  rsi.item_id IS NULL;
		END
	END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;

        SET @error_description = CONCAT(
            N'ErrorNumber: ', ERROR_NUMBER(), CHAR(13)+CHAR(10),
            N'ErrorSeverity: ', ERROR_SEVERITY(), CHAR(13)+CHAR(10),
            N'ErrorState: ', ERROR_STATE(), CHAR(13)+CHAR(10),
            N'ErrorProcedure: ', ISNULL(ERROR_PROCEDURE(), N''), CHAR(13)+CHAR(10),
            N'ErrorLine: ', ERROR_LINE(), CHAR(13)+CHAR(10),
            N'ErrorMessage: ', ERROR_MESSAGE());

        SET @text = CONCAT(
            N':exclamation: Ошибка загрузки договоров коллекторов в RMQ ',
            FORMAT(GETDATE(), 'dd.MM.yyyy HH:mm:ss'));

        EXEC LogDb.dbo.SendToSlack_dwhNotification @text;
        EXEC LogDb.dbo.LogAndSendMailToAdmin
             'catching error etl.Send_CollectionAgencyContracts2RMQ',
             'Error', 'Error', @error_description;

        THROW 51000, @error_description, 1;
    END CATCH;
END;
