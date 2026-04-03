


 --[etl].[Send_dwh2interaction_3202_2RMQ]
CREATE       procedure [etl].[Send_dwh2interaction_3202_2RMQ_delete_10_04_2026]
	@env nvarchar(255) = 'uat'
as
begin
	declare 
	@ServiceUrl varchar(1024) =   concat('http://dwh-ex.cm.carmoney.ru/rmqSender/', @env, '/send2interactions_dwh_interaction_3202.php')
	 ,@httpMethod varchar(10) = 'GET',
       @paramsValues varchar(1024) =concat('spForGetData', '=', 'etl.Get_CallResult_AnsweringMachine_JSON'),
	   @authHeader NVARCHAR(64) = '',
	   @soapAction varchar(1024) = null,
	   @contentType NVARCHAR(64) = 'application/json',
	   @status  int = -1 ,
	   @statusText varchar(1024)  = '',
	   @errorSource varchar(255) = '' ,
	   @errorDesc varchar(255) = '',
	   @responseTextResult nvarchar(4000) = '',
	   @resultDesc nvarchar(4000) = ''

	declare @sp_name nvarchar(255) = OBJECT_NAME(@@PROCID)
	exec logdb.dbo.[LogAndSendMailToAdmin] 'trying start [etl].[Send_dwh2interaction_3202_2RMQ]','Info',' started', ''
	declare @responseResult nvarchar(4000)  
	begin try
		
		exec LogDb.etl.[RequestHttpWebService]
			@url = @ServiceUrl, 
			@httpMethod = 'GET', 
			@paramsValues = @paramsValues, 
			@authHeader = @authHeader, 
			@soapAction = @soapAction, 
			@contentType =@contentType, 
			@status			= @status out, 
			@statusText		= @statusText out,
			@errorSource	= @errorSource out, 
			@errorDesc		= @errorDesc out, 
			@responseResult = @responseTextResult out,
			@IsResponseOutputResult = 1, 
			@IsSaveResult2Table		= 0
				
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
				declare @print_msg nvarchar(255) = concat('Total Send Packages',':', @TotalSendPackages)
				print @print_msg
				select @TotalSendPackages
				exec logdb.dbo.[LogAndSendMailToAdmin] 'exec [etl].[Send_dwh2interaction_3202_2RMQ]','Info','Done',''
			end
			
	end try
	begin catch
		declare @error_description nvarchar(max)
		set @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
      
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		
		exec logdb.dbo.[LogAndSendMailToAdmin] 'catching error [etl].[Send_dwh2interaction_3202_2RMQ]','Error','Error',@error_description
      
		;throw 51000, @error_description, 1
		
	end catch
end

