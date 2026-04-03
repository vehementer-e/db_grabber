
CREATE       PROCEDURE dbo.[RequestHttpWebService]
       @url nvarchar(1024),
       @httpMethod varchar(10),
       @paramsValues nvarchar(max),    -- param1=value&param2=value
	   @authHeader NVARCHAR(64) = null ,
	   @UserName NVARCHAR(64) = null, 
	   @Password NVARCHAR(64) = null,
	   @soapAction varchar(1024) = null,
	   @contentType NVARCHAR(64) = 'application/json',
	   @status  int = 200 out,
	   @statusText nvarchar(1024)  = ''out,
	   @errorSource nvarchar(255) = '' out,
	   @errorDesc nvarchar(255) = '' out,
	   @IsResponseOutputResult bit = 0,
	   @responseResult nvarchar(max) = null out,
	   @IsSaveResult2Table bit = 0,
	   @outGuidResultId uniqueidentifier = null out 
AS
BEGIN
	 declare @token int
	 set @IsSaveResult2Table = 1
begin try	
	
	  declare @ResponseErrorCode int
	  declare @errorMsg nvarchar(255)
       SET NOCOUNT ON;
	   SET TEXTSIZE  2147483647	;

       declare @response varchar(8000)
           ,@responseXml xml
           ,@method varchar(10) = IIF( UPPER(@HttpMethod) in ('SOAP'),'POST',@HttpMethod)
		
		IF UPPER(@HttpMethod) in ('GET') and len(@ParamsValues) > 0
		BEGIN
			set @Url = concat(@Url, '?', @ParamsValues)
			print @url
		END
        
		exec @ResponseErrorCode = sp_OACreate 'MSXML2.ServerXMLHttp', @token out
		IF @ResponseErrorCode <> 0 
		BEGIN
			EXEC sp_OAGetErrorInfo @token, @errorSource OUT, @errorDesc OUT
			set @errorMsg =concat('Ошибка создания токена.'
				, '@ResponseErrorCode = ', @ResponseErrorCode, ';'
				, '@errorSource  =', @errorSource, ';'
				, '@errorDesc  =', @errorDesc,';')
			;throw 51000, @errorMsg, 16
		END


		--set the timeout, receive timeout to 5 minutes
	
	/*
	EXEC sp_OASetProperty obj, 'setTimeouts',resolveTimeout,connectTimeout,sendTimeout,receiveTimeout
	EXEC @ResponseErrorCode = sp_OASetProperty obj, 'setTimeouts','120000','120000','120000','120000'
	*/
																 --resolveTimeout, connectTimeout, sendTimeout, receiveTimeout
		
		EXEC @ResponseErrorCode = sp_OAMethod @token, 'setTimeouts', null,  600000, 600000, 600000, 600000
		IF @ResponseErrorCode <> 0
		BEGIN
			EXEC sp_OAGetErrorInfo @token, @errorSource OUT, @errorDesc OUT
			set @errorMsg =concat('Ошибка установки значения setTimeouts.'
				, '@ResponseErrorCode = ', @ResponseErrorCode, ';'
				, '@errorSource  =', @errorSource, ';'
				, '@errorDesc  =', @errorDesc,';')
			;throw 51001, @errorMsg, 16
		END
		if nullif(@UserName, '') is not null 
			and  nullif(@Password, '') is not null
		begin
			EXEC @ResponseErrorCode = sp_OAMethod 
				@token, 
				'open', 
				NULL, 
				@method, 
				@Url, 
				'false', 
				@UserName, 
				@Password;
			--exec @ResponseErrorCode =sp_OAMethod @token, 'Open', null, @method, @Url, false
		end
		else
		begin
			exec @ResponseErrorCode =sp_OAMethod @token, 'Open', null, @method, @Url, 'false'
		end
		IF @ResponseErrorCode <> 0 
		BEGIN
			EXEC sp_OAGetErrorInfo @token, @errorSource OUT, @errorDesc OUT
			set @errorMsg =concat('Ошибка установки открытия соединения.'
				, '@ResponseErrorCode = ', @ResponseErrorCode, ';'
				, '@errorSource  =', @errorSource, ';'
				, '@errorDesc  =', @errorDesc,';')
			;throw 51001, @errorMsg, 16
		END
		
		IF NULLIF(@authHeader, '') is not null
		BEGIN
			EXEC @ResponseErrorCode = sp_OAMethod @token, 'setRequestHeader', NULL, 'Authorization', @authHeader;
			IF @ResponseErrorCode <> 0 
			BEGIN
				EXEC sp_OAGetErrorInfo @token, @errorSource OUT, @errorDesc OUT
				set @errorMsg =concat('Ошибка установки свойства  setRequestHeader - Authorization.'
				, '@ResponseErrorCode = ', @ResponseErrorCode, ';'
				, '@errorSource  =', @errorSource, ';'
				, '@errorDesc  =', @errorDesc,';')
				;throw 51002, @errorMsg, 16
				
			END
		END

		exec @ResponseErrorCode =sp_OAMethod @token, 'setRequestHeader', null, 'Content-Type', @contentType
		IF @ResponseErrorCode <> 0 
		BEGIN
			EXEC sp_OAGetErrorInfo @token, @errorSource OUT, @errorDesc OUT
			set @errorMsg =concat('Ошибка установки свойства  setRequestHeader - Content-Type.'
				, '@ResponseErrorCode = ', @ResponseErrorCode, ';'
				, '@errorSource  =', @errorSource, ';'
				, '@errorDesc  =', @errorDesc,';')
				;throw 51004, @errorMsg, 16
		END
	  
		IF UPPER(@HttpMethod) in ('GET')
		begin
			exec @ResponseErrorCode = sp_OAMethod @token, 'send'
			IF @ResponseErrorCode <> 0 
			BEGIN
				EXEC sp_OAGetErrorInfo @token, @errorSource OUT, @errorDesc OUT
				set @errorMsg =concat('Ошибка выполнения метода get-send.'
				, '@ResponseErrorCode = ', @ResponseErrorCode, ';'
				, '@errorSource  =', @errorSource, ';'
				, '@errorDesc  =', @errorDesc,';')
				;throw 51004, @errorMsg, 16
			END
		end
		ELSE IF UPPER(@HttpMethod) in ('POST')
		begin
		 --   exec sp_OAMethod @token, 'setRequestHeader', null, 'Content-Type', @contentType
			--IF @ResponseErrorCode <> 0 
			--BEGIN
			--	EXEC sp_OAGetErrorInfo @token, @errorSource OUT, @errorDesc OUT
			--END

		   exec @ResponseErrorCode = sp_OAMethod @token, 'send', null, @ParamsValues
		   IF @ResponseErrorCode <> 0 
			BEGIN
				EXEC sp_OAGetErrorInfo @token, @errorSource OUT, @errorDesc OUT
				set @errorMsg =concat('Ошибка выполнения метода post-send.'
					, '@ResponseErrorCode = ', @ResponseErrorCode, ';'
					, '@errorSource  =', @errorSource, ';'
					, '@errorDesc  =', @errorDesc,';')
				;throw 51005, @errorMsg, 16
			END
			
       end 
	   ELSE IF UPPER(@HttpMethod) IN ('SOAP')
       begin
           if @SoapAction is null
               raiserror('@SoapAction is null', 10, 1)

           declare @host varchar(1024) = @Url
           if @host like 'http://%'
               set @host = right(@host, len(@host) - 7)
           else if @host like 'https://%'
               set @host = right(@host, len(@host) - 8)

           if charindex(':', @host) > 0 and charindex(':', @host) < charindex('/', @host)
               set @host = left(@host, charindex(':', @host) - 1)
           else 
               set @host = left(@host, charindex('/', @host) - 1)

           declare @envelope varchar(8000) = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><{action} xmlns="http://tempuri.org/">{params}</{action}></soap:Body></soap:Envelope>'
           declare @params varchar(8000) = '' 

           WHILE LEN(@ParamsValues) > 0
           BEGIN
               declare @param varchar(256),
                       @value varchar(256)

               IF charindex('&', @ParamsValues) > 0
               BEGIN

                   SET @param = left(@ParamsValues, charindex('&', @ParamsValues) - 1)
                   set @value = RIGHT(@param, len(@param) - charindex('=', @param))
                   set @param = left(@param, charindex('=', @param) - 1)
                   set @params = @params + '<' + @param + '>' + @value + '</'+ @param + '>'
                   SET @ParamsValues = right(@ParamsValues, LEN(@ParamsValues) - LEN(@param + '=' + @value + '&'))
               END
               ELSE
               BEGIN
                   set @value = RIGHT(@ParamsValues, len(@ParamsValues) - charindex('=', @ParamsValues))
                   set @param = left(@ParamsValues, charindex('=', @ParamsValues) - 1)

                   set @params = @params + '<' + @param + '>' + @value + '</'+ @param + '>'
                   SET @ParamsValues = NULL
               END
           END

           set @envelope = replace(@envelope, '{action}', @SoapAction)
           set @envelope = replace(@envelope, '{params}', @params)

           set @SoapAction = 'http://tempuri.org/' + @SoapAction

           print @host
           print @SoapAction
           print @envelope

        exec @ResponseErrorCode = sp_OAMethod @token, 'setRequestHeader', null, 'Content-Type', 'text/xml; charset=utf-8'
		IF @ResponseErrorCode <> 0
		BEGIN
			EXEC sp_OAGetErrorInfo @token, @errorSource OUT, @errorDesc OUT
		END
        exec @ResponseErrorCode = sp_OAMethod @token, 'setRequestHeader', null, 'Host', @host
		  IF @ResponseErrorCode <> 0
		BEGIN
			EXEC sp_OAGetErrorInfo @token,@errorSource OUT, @errorDesc OUT
		END
        exec @ResponseErrorCode = sp_OAMethod @token, 'setRequestHeader', null, 'SOAPAction', @SoapAction
		 IF @ResponseErrorCode <> 0
		BEGIN
			EXEC sp_OAGetErrorInfo @token, @errorSource OUT, @errorDesc OUT
		END
           exec @ResponseErrorCode = sp_OAMethod @token, 'send', null, @envelope
		  IF @ResponseErrorCode <> 0
		BEGIN
				EXEC sp_OAGetErrorInfo @token, @errorSource OUT, @errorDesc OUT
		   END
       end

	 --  IF @ResponseErrorCode <> 0
		--BEGIN
		--	EXEC sp_OAGetErrorInfo @token,@errorSource OUT, @errorDesc OUT
		--END
		
		declare @tResult table(Result nVARCHAR(MAX))
		if(@IsResponseOutputResult=1 or @IsSaveResult2Table = 1)
		BEGIN
			
			insert into @tResult
			exec @ResponseErrorCode = sp_OAGetProperty @token, 'responseText'
			if @IsResponseOutputResult= 1
			begin
				set @responseResult = (select top(1)  Result from @tResult)
			end
		END
		ELSE
			exec @ResponseErrorCode = sp_OAGetProperty @token, 'responseText', @responseResult out
		
		IF @ResponseErrorCode <> 0
		BEGIN
				EXEC sp_OAGetErrorInfo @token, @errorSource OUT, @errorDesc OUT
				set @errorMsg =concat('Ошибка получения значения св-ва responseText.'
					, '@ResponseErrorCode = ', @ResponseErrorCode, ';'
					, '@errorSource  =', @errorSource, ';'
					, '@errorDesc  =', @errorDesc,';')
				;throw 51006, @errorMsg, 16
		END
		 
-- Handle the response.	   
        EXEC @ResponseErrorCode = sp_OAGetProperty @token, 'status', @status OUT;
		IF @ResponseErrorCode <> 0
		BEGIN
			EXEC sp_OAGetErrorInfo @token, @errorSource OUT, @errorDesc OUT
			set @errorMsg =concat('Ошибка получения значения св-ва status.'
					, '@ResponseErrorCode = ', @ResponseErrorCode, ';'
					, '@errorSource  =', @errorSource, ';'
					, '@errorDesc  =', @errorDesc,';')
				;throw 51006, @errorMsg, 16
		END
		EXEC @ResponseErrorCode = sp_OAGetProperty @token, 'statusText', @statusText OUT;
		IF @ResponseErrorCode <> 0
		BEGIN
			EXEC sp_OAGetErrorInfo @token, @errorSource OUT, @errorDesc OUT
			set @errorMsg =concat('Ошибка получения значения св-ва statusText.'
					, '@ResponseErrorCode = ', @ResponseErrorCode, ';'
					, '@errorSource  =', @errorSource, ';'
					, '@errorDesc  =', @errorDesc,';')
			;throw 51006, @errorMsg, 16
		END

		if @IsSaveResult2Table = 1
		begin
			
			insert into @tResult
			exec @ResponseErrorCode = sp_OAGetProperty @token, 'responseText'
			set @outGuidResultId = newid()
		
	
			insert into dbo.[ResponseData](
				[id], 
				[web_url], 
				[OUTRESPONSE], 
				[status], 
				[statusText], 
				[errorSource], 
				[errorDesc],
				httpMethod,
				paramsValues,
				[created_at]
			)
			select top(1)
				@outGuidResultId,
				@url,
				Result,
				@status, 
				@statusText,
				@errorSource,
				@errorDesc,
				@httpMethod,
				@paramsValues,
				getdate()
			from @tResult
		end
       exec sp_OADestroy @token
end try
begin catch
if @token is not null
begin
	DECLARE @Exception TABLE
        (
                Error binary(4),
                Source varchar(8000),
                Description varchar(8000),
                HelpFile varchar(8000),
                HelpID varchar(8000)
        )
 
     INSERT INTO @Exception 
		EXEC sp_OAGetErrorInfo @token
	select * from @Exception
end

	;throw
end catch
END
