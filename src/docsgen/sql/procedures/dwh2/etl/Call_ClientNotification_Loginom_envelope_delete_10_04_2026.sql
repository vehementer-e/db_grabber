--DWH-939
--DWH-942 Client_notification
CREATE   procedure [etl].[Call_ClientNotification_Loginom_envelope_10_04_2026]
as
begin
declare @text nvarchar(max)=N''
	, @subject nvarchar(255)= concat_ws(' '
		, 'Вызов логином Client_notification'
		, format(getdate(), 'dd.MM.yyyy HH:mm'))
	, @msg nvarchar(4000)=N''
	, @StartDate datetime
	, @FinishDate datetime
  declare 
  --https://c3-vsr-linteg.cm.carmoney.ru/lgi/Service.svc/Rest/Client_notification/ClientNotification
	@url varchar(1024) = 'https://c3-logi-integr0.carm.corp/lgi/Service.svc/Rest/Client_notification/ClientNotification',
       @httpMethod varchar(10) = 'POST',
       @paramsValues varchar(1024) = '',    -- param1=value&param2=value
	   @authHeader NVARCHAR(64) = '',
	   @soapAction varchar(1024) = null,
	   @contentType NVARCHAR(64) = 'application/json',
	   @status  int = -1 ,
	   @statusText varchar(1024)  = '',
	   @errorSource varchar(255) = '' ,
	   @errorDesc varchar(255) = '',
	   @responseTextResult nvarchar(4000) = '',
	   @resultDesc nvarchar(4000) = ''
	   Set @paramsValues = JSON_QUERY('
		{"Client_Notification_Request": { 
				"Rows": [
					{                  
						"request_source": "DWH"
				   }
				] 
			} 
		}')
	  --To debug use following url
-- set @url = 'https://c2-vsr-linteg.cm.carmoney.ru/lgi/Service.svc/Rest/Collection_CMR_test/CollectionCMRtest'
    begin try
	  	
		set @text=concat_ws(' ', 'Вызов логином Client_notification'
			,format(getdate(),'dd.MM.yyyy HH:mm:ss')
			)


		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
			@text = @text
			,@threadKey = @subject


		exec logdb.dbo.[LogAndSendMailToAdmin] 'trying call Loginom Client_notification','Info',' started', ''

		set @StartDate = getdate()
		exec LogDb.etl.RequestHttpWebService
			 @url 	=@url,
			   @httpMethod = @httpMethod ,
			   @paramsValues = @paramsValues ,    -- param1=value&param2=value
			   @authHeader = @authHeader ,
			   @soapAction = @soapAction,
			   @contentType =@contentType,
			   @status  = @status out ,
			   @statusText = @statusText out ,
			   @errorSource = @errorSource out,
			   @errorDesc = @errorDesc  out,
			   @IsResponseOutputResult = 1,
			   @responseResult = @responseTextResult out
		set @FinishDate = getdate()

	if(@status!=200)
	begin
		set @msg = 'Вызов логином Client_notification завершился неудачно Return code: ' +cast(@status as nvarchar(255)) + 'Status text: ' + @statusText;
		;THROW 51000, @msg, 1
	end
	else
		set @msg = ':heavy_check_mark: Вызов Loginom Client_notification звершился удачно. Return code: ' +cast(@status as nvarchar(255)) +'. Все готово для загрузки кейсов в Naumen';

		set @resultDesc = (SELECT
			'StartDate' = format(t.StartDate, 'dd.MM.yyyy HH:mm:ss'),
			'FinishDate' = format(t.FinishDate, 'dd.MM.yyyy HH:mm:ss'),
			'ReturnCode' = t.ReturnCode,
			'количество назначенных экшнов' = r.output_uniqActions,
			'количество договоров по которым назначены экшны' = r.output_uniqAccountsWithActions,
			'Ответ логинома' = r.Result
		from 
			(select StartDate = @StartDate,
				FinishDate = @FinishDate,
				ReturnCode = @status
				)  t
		left join 
		(
		select 
			output_uniqActions,
			output_uniqAccountsWithActions,
			Result
		from	OpenJson(@responseTextResult, '$.Client_Notification_Result.Rows')
			WITH (output_uniqActions int '$.output_uniqActions',
				output_uniqAccountsWithActions int '$.output_uniqAccountsWithActions',
				Result nvarchar(255) '$.Result'
				) as Result
			 WHERE ISJSON( @responseTextResult ) = 1
		) r on 1=1
		FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
		)
		
		set @msg = concat(':heavy_check_mark:'
			,' Вызов Loginom звершился удачно. '
			, 'Детализация ответа ', REPLACE(REPLACE(@resultDesc, '}',''), '{', '')
			)


		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
			@text = @text
			,@threadKey = @subject
	
		exec logdb.dbo.[LogAndSendMailToAdmin] 
			@eventName = 'trying RequestHttp', 
			@eventType = 'Info', 
			@message = ' Loginom Client_notification call status', 
			@description = @status	
        

		


      end try
    begin catch
		declare @errorMsg nvarchar(4000) = ERROR_MESSAGE()

     	EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
			@text = @errorMsg
			,@threadKey  = @subject
		EXEC logdb.dbo.[LogAndSendMailToAdmin] 
			@eventName = 'trying call Loginom Client_notification', 
					@eventType = 'Error', 
					@message = ' Loginom Client_notification call Error', 
					@description = @errorMsg
      -- задержка в одну минуту
      ;throw 51000, @errorMsg, 1
    end catch
  
end

