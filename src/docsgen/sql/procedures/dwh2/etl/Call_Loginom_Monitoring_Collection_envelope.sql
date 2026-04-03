--DWH-2132
CREATE   procedure [etl].[Call_Loginom_Monitoring_Collection_envelope]
as
begin

declare @text nvarchar(max)=N''
  ,@msg nvarchar(4000)=N''
  ,@subject nvarchar(255) = 'Вызов логином Monitoring_Collection'
  ,@StartDate datetime
  , @FinishDate datetime
  declare 
	@url varchar(1024) = 'https://c3-logi-integr0.carm.corp/lgi/Service.svc/Rest/Monitoring_Collection/Monitoring_Collection',
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
		{"MonitoringCollection_request": { 
				"Rows": [
					{                  
						"Request_source": "DWH"
				   }
				] 
			} 
		}')

-- set @url = 'https://c2-vsr-linteg.cm.carmoney.ru/lgi/Service.svc/Rest/CollectionCMRHealthCheck/CollectionCMRHealthCheck'
    begin try
	  	
		set @text=Concat('Вызов логином'
			, ' Monitoring_Collection '
			, format(getdate(),'dd.MM.yyyy HH:mm:ss'))


		EXEC logdb.dbo.SendToSlack_dwhNotification  @text = @text
		,@subject  = @subject
		exec logdb.dbo.[LogAndSendMailToAdmin] 'trying call Loginom Monitoring_Collection','Info',' started', ''
		set @StartDate = getdate()
		exec CommonDb.dbo.[RequestHttpWebService]	
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
			   @IsSaveResult2Table		= 1,
			   @responseResult = @responseTextResult out
		set @FinishDate = getdate()
	if(@status!=200)
	begin
		set @msg = Concat('Вызов логином,'
			, 'Monitoring_Collection'
			, 'завершился неудачно Return code: ' , cast(@status as nvarchar(255))
			,  ' Status text: ', @statusText)
		;THROW 51000, @msg, 1
	end
	else
		set @resultDesc = (SELECT
			'StartDate' = format(t.StartDate, 'dd.MM.yyyy HH:mm:ss'),
			'FinishDate' = format(t.FinishDate, 'dd.MM.yyyy HH:mm:ss'),
			'ReturnCode' = t.ReturnCode,
			'Ответ логинома ФСПП' = r.fssp_result,
			'Количество клиентов, отобранных для запроса' = r.fssp_cnt_requests,
			'Ответ логинома ПравоРу' = r.pravoRu_result,
			'Количество клиентов, отобранных для запроса в ПравоРу' = r.pravoRu_cnt_requests
		from 
			(select StartDate = @StartDate,
				FinishDate = @FinishDate,
				ReturnCode = @status
				)  t
		left join 
		(
		select 
			 fssp_cnt_requests				
			,fssp_result					
			,pravoRu_result					
			,pravoRu_cnt_requests_success	
			,pravoRu_cnt_requests			

		from	OpenJson(@responseTextResult, '$.MonitoringCollection_result.Rows')
			WITH (  
				 fssp_cnt_requests				decimal(10,2) '$.fssp_cnt_requests'
				,fssp_result					nvarchar(255) '$.fssp_result'
				,pravoRu_result					nvarchar(255) '$.pravoRu_result'
				,pravoRu_cnt_requests_success	decimal(10,2) '$.pravoRu_cnt_requests_success'
				,pravoRu_cnt_requests			decimal(10,2) '$.pravoRu_cnt_requests'
				) as Result
			 WHERE ISJSON( @responseTextResult ) = 1
		) r on 1=1
		FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
		)
		
		set @msg = concat(':heavy_check_mark:'
			,' Вызов Loginom - Monitoring_Collection звершился удачно. '
			, 'Детализация ответа ', REPLACE(REPLACE(@resultDesc, '}',''), '{', '')
			)
		exec logdb.dbo.SendToSlack_dwhNotification 
		@text = @msg
		,@subject  = @subject
			exec logdb.dbo.[LogAndSendMailToAdmin] 
				@eventName = 'trying RequestHttp', 
				@eventType = 'Info', 
				@message = ' Loginom call status', 
				@description = @status	
        
      end try
    begin catch
     declare @errorMsg nvarchar(4000) = ERROR_MESSAGE()

      EXEC LogDb.dbo.SendToSlack_dwhNotification  
	  @text = @errorMsg
		,@subject  = @subject
		
      
      exec logdb.dbo.[LogAndSendMailToAdmin] 
		@eventName = 'trying call Loginom - Monitoring_Collection', 
				@eventType = 'Error', 
				@message = ' Loginom call - Monitoring_Collection Error', 
				@description = @errorMsg
      -- задержка в одну минуту
      ;throw 51000, @errorMsg, 1
    end catch
  
end

