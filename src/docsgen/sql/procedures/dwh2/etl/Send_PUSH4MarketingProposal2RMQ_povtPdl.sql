


 --[etl].[Send_PUSHForMarkingProposal2RMQ_povtPdl] @env = 'uat', @CMRClientGUID = 'C6DCA609-08F9-11E8-A814-00155D941900'
CREATE       procedure [etl].[Send_PUSH4MarketingProposal2RMQ_povtPdl]
	@env nvarchar(255) = 'uat',
	@CMRClientGUID nvarchar(36) = null,
	@CMRClientGUIDs nvarchar(max) = null,
	@isDebug bit = 0
as
begin
	set @CMRClientGUIDs = nullif(CONCAT_WS(',',@CMRClientGUID, @CMRClientGUIDs), '')
	declare @spName nvarchar(255) =  concat('etl', '.', OBJECT_NAME(@@PROCID))
	,@rmqSenderUrl  nvarchar(255) = 'https://dwhex.carm.corp'
	
	declare @ServiceUrl varchar(1024) = concat_ws('/', @rmqSenderUrl, @env, 'RMQProducer/api/ToComc') -- is this correct?  .. or this - @ServiceUrl varchar(1024) =   concat('https://dwhex.carm.corp/', @env, '/COMCEmail.php')
	
	 ,@httpMethod varchar(10) = 'POST',
       @paramsValues varchar(max) = '',    -- param1=value&param2=value
	   @authHeader NVARCHAR(64) = '',
	   @soapAction varchar(1024) = null,
	   @contentType NVARCHAR(64) = 'application/json',
	   @status  int = -1 ,
	   @statusText varchar(1024)  = '',
	   @errorSource varchar(255) = '' ,
	   @errorDesc varchar(255) = '',
	   @responseTextResult nvarchar(4000) = '',
	   @resultDesc nvarchar(4000) = '',
	   @GuidResultId nvarchar(36) = newID()
	--if @env = 'uat'

	declare @procParams etl.[utt_rmqProcParams]
	insert into @procParams(Name, value)
	select  Name, Value from (values
	
			('env', 'prod')
			,('CMRClientGUIDs', @CMRClientGUIDs)
	)t( Name, Value)

	declare @exchangeName nvarchar(255)  = 'COMC.Message.1.1'
	,@routingKey nvarchar(255) = 'push' --'dwh.marketProposal.1'
	,@procedureName  nvarchar(255) = 'dwh2.[etl].[GetMarketProposal_push_povtPdl_JSON]'  -- was GetMarketProposal_push_povtPdl_JSON


	select @paramsValues = etl.GetJson4RMQProducer(
		@exchangeName
		,@routingKey 
		,@procedureName
		,@procParams
	)
	if @isDebug = 1
	begin
		select  @ServiceUrl, @paramsValues
	end

		
	declare @sp_name nvarchar(255) = OBJECT_NAME(@@PROCID)
	declare @text nvarchar(max)=N''
	declare @error_description nvarchar(4000)=N''
		set @text=Concat('Маркетинговые предложения pdl.'
		,' Старт PUSH рассылки по маркениговым предложениям'
		, ' CMRClientGUID: ', isnull(@CMRClientGUID, '-')
		,' env: ', @env
		, ' ', format(getdate(),'dd.MM.yyyy HH:mm:ss'))
	EXEC [LogDb].dbo.SendToSlack_dwhNotification  @text
	exec logdb.dbo.[LogAndSendMailToAdmin] 'trying start [etl].[Send_PUSHForMarkingProposal2RMQ_povtpdl]','Info',' started', ''
	declare @responseResult nvarchar(4000)  
	begin try
		
		exec CommonDb.[dbo].[RequestHttpWebService]
			@url = @ServiceUrl, 
			@httpMethod = @httpMethod, 
			@paramsValues = @paramsValues, 
			@authHeader = @authHeader, 
			@soapAction = @soapAction, 
			@contentType =@contentType, 
			@status			= @status out, 
			@statusText		= @statusText out,
			@errorSource	= @errorSource out, 
			@errorDesc		= @errorDesc out, 
			@responseResult = @responseTextResult out,
			@IsResponseOutputResult = 0, 
			@IsSaveResult2Table		= 1,
			@outGuidResultId		= @GuidResultId out
				
			if @status not between 200 and 300
			begin
				declare @errorCode int = 51000+ @status
				declare @responseError nvarchar(1024)=concat(':interrobang: '
					,'Ошибка вызыва сервиса по отправке в RMQ.' 
					,' statusCode ' , @status
					,' statusText = ', @statusText
					,ISNULL(' errorSource = ' + @errorSource + ';', '')
					,ISNULL(' errorDesc = ' + @errorDesc + ';', '')
					,ISNULL(' responseTextResult = ' +@responseTextResult + ';','')
					)
				;throw @errorCode, @responseError, 16
				
			end
			else
			begin
				declare @TotalSendPackages int
				if  ISJSON(@responseTextResult) = 1
				begin
					set @TotalSendPackages =JSON_VALUE(@responseTextResult, '$.result.totalSendPackages')
					
				end
				print @TotalSendPackages
				declare @msg nvarchar(255)= Concat('Данные для PUSH рассылки по проекту повторники pdl загружены в RMQ', 
					', CMRClientGUID: ', isnull(@CMRClientGUID, '-')
					, isnull(' Отправлено: ' + cast(@TotalSendPackages as nvarchar(10)), '')
					)
				EXEC  [LogDb].dbo.SendToSlack_dwhNotification  @msg
				exec logdb.dbo.[LogAndSendMailToAdmin] 'exec [etl].[Send_PUSHForMarkingProposal2RMQ_povtpdl]','Info','Done',''
			end
			
	end try
	begin catch
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		set @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
      
      
		set @text=':exclamation: Ошибка загрузки  данных PUSH для рассылки по проекту повторники pdl в RMQ'+format(getdate(),'dd.MM.yyyy HH:mm:ss')
		EXEC  [LogDb].dbo.SendToSlack_dwhNotification  @text
      
		exec logdb.dbo.[LogAndSendMailToAdmin] 'catching error [etl].[Send_PUSHForMarkingProposal2RMQ_povtpdl]','Error','Error',@error_description
      
		;throw 51000, @error_description, 1
		
	end catch
end

