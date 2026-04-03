
CREATE   procedure [SendNotification].[Send2GChat]
	 @channelName	nvarchar(255)
	,@textValue		nvarchar(1024)
	,@threadKey		nvarchar(255) = null out
as
begin
	declare @errorMsg nvarchar(1024)
begin  try	

	declare @status					int = 200 ,
	   @statusText				nvarchar(1024)  ,
	   @errorSource				nvarchar(255) ,
	   @errorDesc				nvarchar(255) ,
	   @IsResponseOutputResult	bit = 1,
	   @responseResult			nvarchar(max) ,
	   @IsSaveResult2Table		bit =1,
	   @outGuidResultId			uniqueidentifier = newid(),
	   @paramsValues			nvarchar(max),
	   @spaceCode				nvarchar(50),
	   @url						nvarchar(255)
	if nullif(trim(@textValue),'') is null
	begin
		set @errorMsg = 'сообещние не может быть пустым'
		;throw 50001, @errorMsg, 16
	end
	select top(1) @url  =url
		,@spaceCode	 = spaceCode
		from [SendNotification].[GetConfigOfChannelNotification](@channelName)
	
	if nullif(@spaceCode, '') is not null and nullif(@threadKey,'') is null
	begin
		set @threadKey= CONCAT_WS('/'
			, 'spaces'
			, @spaceCode
			, 'threads'
			, right(cast(NEWID() as nvarchar(36)), 12)
			)
			
	end

	declare @jsonMessage nvarchar(max) = (
	select 
		'text' = @textValue 
	,	'thread.threadKey' = @threadKey
	FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	)
	if nullif(@url,'') is null
	begin
		set @errorMsg = concat_ws(' '
		, 'Для'
		, @channelName
		,'не определен webhook url'
		)
		;throw 50000, @errorMsg, 16
	end

	else if nullif(@threadKey,'') is not null
	begin
		set @url = CONCAT_WS('&'
		, @url
		,'messageReplyOption=REPLY_MESSAGE_FALLBACK_TO_NEW_THREAD'
		)
	end
	
	set @paramsValues =  @jsonMessage

	exec dbo.[RequestHttpWebService]
       @url  = @url,
       @httpMethod = 'POST',
       @paramsValues = @paramsValues,
	   @contentType = 'application/json',
	   @status					= @status out,
	   @statusText				= @statusText out,
	   @errorSource				= @errorSource out,
	   @errorDesc				= @errorDesc out,
	   @IsResponseOutputResult	= @IsResponseOutputResult,
	   @responseResult			= @responseResult out,
	   @IsSaveResult2Table		= @IsSaveResult2Table,
	   @outGuidResultId			= @outGuidResultId out 

		IF @status NOT BETWEEN 200 AND 299
        BEGIN
            DECLARE @errorCode INT = 51000 + @status;
			IF ISJSON(@responseResult) = 1
			begin
				declare @responceError nvarchar(max)
				select @responceError = errorMessage
				from OPENJSON(@responseResult,'$')
				 WITH (errorMessage nvarchar(255) '$.error.message')
				 where nullif(errorMessage,'') is not null
				set @errorDesc = CONCAT_WS(' ',@errorDesc ,@responceError)
			end
            DECLARE @responseError NVARCHAR(1024) = CONCAT(
                N':interrobang: Ошибка вызова сервиса GCHAT.',
                N' statusCode = ', @status,
                N' statusText = ', @statusText,
                ISNULL(N' errorSource = ' + @errorSource, N''),
                ISNULL(N' errorDesc = '   + @errorDesc,   N''));

			
           ;THROW @errorCode, @responseError, 16;
        END	
		ELSE IF ISJSON(@responseResult) = 1
		begin
		/*
		{   "name": "spaces/AAQAmddlhtE/messages/RZAsbPeABFk.RZAsbPeABFk",   "text": "Hello from a Python script!",   "thread": {     "name": "spaces/AAQAmddlhtE/threads/RZAsbPeABFk"   },   "space": {     "name": "spaces/AAQAmddlhtE"   } } 
		*/
			select @threadKey = isnull(threadKey, threadName)
			from OPENJSON(@responseResult,'$')
			 WITH (threadName nvarchar(255) '$.thread."name"'
			 ,	threadKey nvarchar(255) '$.thread.threadKey')
			 --where nullif(threadName,'') is not null
		end
		

end try
begin catch
	declare @error_description  nvarchar(max)
	IF @@TRANCOUNT > 0 ROLLBACK;
	declare @ERROR_NUMBER int = ERROR_NUMBER()
    SET @error_description = CONCAT(
        N'ErrorNumber: ', @ERROR_NUMBER, CHAR(13)+CHAR(10),
        N'ErrorSeverity: ', ERROR_SEVERITY(), CHAR(13)+CHAR(10),
        N'ErrorState: ', ERROR_STATE(), CHAR(13)+CHAR(10),
        N'ErrorProcedure: ', ISNULL(ERROR_PROCEDURE(), N''), CHAR(13)+CHAR(10),
        N'ErrorLine: ', ERROR_LINE(), CHAR(13)+CHAR(10),
        N'ErrorMessage: ', ERROR_MESSAGE());
	if @ERROR_NUMBER>=50000
		THROW @ERROR_NUMBER, @error_description, 1;
	ELSE 
		THROW;


end catch
end
