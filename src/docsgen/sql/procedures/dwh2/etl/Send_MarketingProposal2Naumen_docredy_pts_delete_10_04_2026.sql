
 --[etl].[Send_MarketingProposal2Naumen_docredy_pts_delete_10_04_2026] @env = 'prod', @isDebug = 1
 -- [etl].[Send_MarketingProposal2Naumen_docredy_pts_delete_10_04_2026] @env = 'uat',  @batchSizeToSendNaumen  = 1000,  @isDebug = 1,
-- set statistics io off
CREATE PROC [etl].[Send_MarketingProposal2Naumen_docredy_pts_delete_10_04_2026]
	@env nvarchar(255) = 'uat',
	@batchSizeToSendNaumen smallint = 500,
	@isDebug bit =0 

as
begin
	declare @newRows nvarchar(10) = char(10)+char(13)
		,@sp_name nvarchar(255) = OBJECT_NAME(@@PROCID)
		,@text nvarchar(max)=N''
		,@error_description nvarchar(4000)=N''
		,@subject nvarchar(255) 
	set @subject  =  concat_ws(' '
		, 'Старт загрузки данных в naumen для проекта докред pts'
		, format(getdate(), 'dd.MM.yyyy HH:mm'))
	
		set @text=Concat('Маркетинговые предложения.',
			'Старт загрузки данных в naumen для проекта докред pts ',
			'env: ', @env,
			format(getdate(),'dd.MM.yyyy HH:mm:ss'))
	
	begin try

	EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
				@text = @text
				,@threadKey = @subject
	exec logdb.dbo.[LogAndSendMailToAdmin] 'trying start [etl].[Send_MarketingProposal2Naumen_docredy_pts_delete_10_04_2026]','Info',' started', ''
	 declare 
			@status  int,
			@statusText varchar(1024),
			@errorSource varchar(255),
			@errorDesc varchar(255),
			@IsResponseOutputResult bit,
			@responseResult varchar(max),
			@authHeader nvarchar(255),
			@naumenProjectUUID nvarchar(255)
		if lower(@env)	= 'uat'
		begin
			select @authHeader = 'Basic ZHdoOjVMZCJedlYq' --'Basic ZHdoOlc5ZkJtMmo3TzVjeDhOSnIxVmRMMnJWNTNOZ3U='
			,@naumenProjectUUID = 'corebo00000000000pbgctcrq6c5s1i8'--'corebo00000000000mkl3peq1nd6diho'

		end
		
		if LOWER(@env) = 'prod'
		begin
			select @authHeader = 'Basic ZHdoOjVMZCJedlYq'
			,@naumenProjectUUID = 'corebo00000000000pallp7sskqdpifo'
			
		end
		if nullif(@naumenProjectUUID,'') is null
		begin
			;throw 51000, 'Id проекта - маркетинговые предложения докред pts для заливки case в naumen не определен', 16
		end
		declare @naumenServiceUrl nvarchar(255) = 
			case lower(@env)	
			--api/v2/projects/corebo00000000000ok9hh0mgi8ld1nk/cases
			--api/v2/projects/corebo00000000000olmvlq8r16noh2k/cases-batch/
				--when 'uat' then concat('https://ncc.uat.carmoney.ru', '/api/v2/projects/', @naumenProjectUUID, '/cases-batch/')
				when 'prod' then concat('https://pms.carm.corp', '/api/v2/projects/', @naumenProjectUUID, '/cases-batch/')
				when 'uat' then concat('https://pms.carm.corp', '/api/v2/projects/', @naumenProjectUUID, '/cases-batch/')
			end
		if nullif(@naumenServiceUrl,'') is null
		begin
			;throw 51000, 'url Naumen service не определен', 16
		end	
		--else 
		--	print @naumenServiceUrl

				

		declare @batchSize int = iif(lower(@env)='uat', 1, 100)
		drop table if exists #Send2Naumen
		create table #Send2Naumen
		(
			id							nvarchar(255),
			[phone]						nvarchar(255),
			title						nvarchar(1024),
			market_proposal_type_name	nvarchar(255),
			naumenPriority				int,
			clientTimeZone				int,
			lead_id						varchar(36),
			group_num					int 
		)
		if lower(@env)	= 'prod'
		begin
			insert into #Send2Naumen
			(
				id							
				,[phone]						
				,title							
				,market_proposal_type_name	
				,naumenPriority				
				,clientTimeZone				
				,lead_id						
				,group_num					
			)
			select 
			id
			,[phone] = CONCAT('8', right([phone],10))
			,title
			,market_proposal_type_name
			,naumenPriority
			,clientTimeZone
			,lead_id
			,group_num =row_number() over(order by getdate()) / @batchSizeToSendNaumen
	
			from (
				select 
					id = concat(t.marketProposal_ID,'|', t.cdate),
					[phone],
					title	=	
					concat_ws(' '
						,t.Fio
						,iif(t.hasPEP =1, 'ПЭП', null )		
						,isnull([hasCommissionProducts], 'Без кп')
						,iif(t.[CurrRate]>0, format([CurrRate]/100, 'p1'), null)
					),
					market_proposal_type_name,
					naumenPriority = 
					--если новый 
					case when naumenInteractionTypeCode = 'isNew' then 99
						else 0 end
					+ isnull(t.naumenPriority,10),
					clientTimeZone =  isnull(clientTimeZone, 3),
					lead_id
					,naumenInteractionTypeCode
				from [marketing].[docredy_pts] t
				where t.phoneInBlackList = 0
				and t.cdate = cast(getdate() as date)
				
				and nullif(t.naumenInteractionTypeCode,'UNKNOWN') is not null
				and t.naumenCaseUUID is null
					
				
			) t
		end
		if @env = 'uat'
		begin
			insert into #Send2Naumen
			(
				id							
				,[phone]						
				,title							
				,market_proposal_type_name	
				,naumenPriority				
				,clientTimeZone				
				,lead_id						
				,group_num					
			)
			select 
				id
				,[phone] = CONCAT('8', right([phone],10))
				,title
				,market_proposal_type_name
				,naumenPriority
				,clientTimeZone
				,lead_id
				,group_num =row_number() over(order by getdate()) / @batchSizeToSendNaumen
	
			from (
				select 
					top(200) --(@batchSizeToSendNaumen)
					id = concat_WS('|'
						, t.marketProposal_ID
						,t.cdate
						, LEFT(REPLACE(CAST(NEWID() AS varchar(36)), '-', ''), 10)
						),
					[phone],
					title	=	
					concat_ws(' '
						,t.Fio
						,iif(t.hasPEP =1, 'ПЭП', null )		
						,isnull([hasCommissionProducts], 'Без кп')
						,iif(t.[CurrRate]>0, format([CurrRate]/100, 'p1'), null)
					),
					market_proposal_type_name,
					naumenPriority= 100,
					clientTimeZone =  isnull(clientTimeZone, 3),
					lead_id
			
			from [marketing].[docredy_pts_uat] t
				where 1=1
				and market_proposal_category_code not in('red')
				and phone is not null
				--and market_proposal_message_guid is not null
				
				--and nullif(t.naumenInteractionTypeCode,'UNKNOWN') is not null
			) t
		end
		

			
		if not exists(select top(1) 1 from #Send2Naumen)
		begin
			;throw 51000, 'Нет данных, по маркетинговым предложения докред pts для отправки в наумен',16 
		end
		declare @group_num smallint
		declare cur_send2Naumen cursor for select distinct group_num from #Send2Naumen

		OPEN cur_send2Naumen  
		FETCH NEXT FROM cur_send2Naumen   INTO @group_num;
		WHILE @@FETCH_STATUS = 0  
		BEGIN  
			declare @reTry smallint = 3, @tryCount smallint = 0
			while @reTry>@tryCount 
			begin
				begin try
					
					declare @ParamValue nvarchar(max) 
					set @ParamValue = (select
						'id'			= id
						,'title'		= title 
						,'comment'		= 'Докреды'--market_proposal_type_name 
						,'priority'		= naumenPriority
						,'timeZone'		= concat('GMT', '+', format(dateadd(hh, clientTimeZone, '1900-01-01'),'hh\:mm'))
						,'phoneNumbers' = t_phoneNumber.json
						,'customForm.group001'	= t_customForm.json 
					from #Send2Naumen t
					outer apply
					(
						select json = (select 
							'number'		= t.[phone] ,
							'code'			= 'MOBILE' 
							FOR JSON PATH
							)
					) t_phoneNumber
					outer apply
					(
						select json = JSON_QUERY((select concat('{"lead_id":', '[',QUOTENAME(lead_id, '"'), ']}')))
					--	where @env = 'uat'
					) t_customForm
					where group_num = @group_num
					FOR JSON PATH
					)
			
					if ISJSON(@ParamValue) = 0
					begin
						;throw 51000, 'Ошибка подготовки данных для отправки в Naumen - невалидный json', 16
					end
					if @isDebug = 0
					begin
						declare @GuidResultId uniqueidentifier
						exec LogDb.etl.[RequestHttpWebService]
							@url = @naumenServiceUrl, 
							@httpMethod = 'POST', 
							@paramsValues = @ParamValue, 
							@authHeader = @authHeader, 
							--@UserName = @UserName, 
							--@Password = @Password,
							@soapAction = null, 
							@contentType = 'application/json', 
							@status			= @status out, 
							@statusText		= @statusText out,
							@errorSource	= @errorSource out, 
							@errorDesc		= @errorDesc out, 
							@IsResponseOutputResult = 0, 
							@IsSaveResult2Table		= 1,
							@outGuidResultId		= @GuidResultId out
				
						if @status not between 200 and 300
						begin
							declare @errorCode int = 51000+ @status
							declare @responseError nvarchar(1024)=concat(':interrobang: '
								,'Ошибка вызыва сервиса Naumen.' 
								,' statusCode ' , @status
								,' statusText = ', @statusText
								,ISNULL(' errorSource = ' + @errorSource, '')
								,ISNULL(' errorDesc = ' + @errorDesc, '')
								)
							;throw @errorCode, @responseError, 16
		
						end
				
						drop table if exists #tNaumenResult
						create table #tNaumenResult(
							naumenResultCode	NVARCHAR(255),
							Id					nvarchar(255),
							naumenResultValue	NVARCHAR(255),
							message				NVARCHAR(max)
						)
		
						drop table if exists #tResponseResult
						create table #tResponseResult([OUTRESPONSE] nvarchar(max))
						insert into #tResponseResult([OUTRESPONSE])
						select cast([OUTRESPONSE] as nvarchar(max))
						from logDb.etl.[ResponseData]
						where id = @GuidResultId

						
		
						
						--select 'ResponseDataGuidResultId'  = @GuidResultId
						
						if exists(Select top(1) 1 from #tResponseResult)
						begin
							--Оптравка информации, что намен ответил код 200
			
							insert into #tNaumenResult
							(
								naumenResultCode	
								,id		
								,naumenResultValue	
								,message
							)
							select 
								naumenResultCode	
								,id		
								,naumenResultValue	
								,message
								
							from #tResponseResult t
							cross apply OPENJSON (t.[OUTRESPONSE], '$')
								WITH (   
									
									naumenResultCode   NVARCHAR(255)  '$.result',  
									id    NVARCHAR(255)   '$.id',  
									naumenResultValue NVARCHAR(255)   '$.uuid',
									message nvarchar(max) '$.message'
							)
							where ISJSON(t.[OUTRESPONSE]) = 1
							if not exists(select top(1) 1 from #tNaumenResult)
							begin
								;throw 52000, 'Ответ от Naumen не содержит результата',16
							end
						declare @SendRows int = (select count(1) from #tNaumenResult)
						--select @SendRows 
						begin  tran
							if lower(@env)	= 'prod'
							begin
								update t
									set  naumenResultCode = s.naumenResultCode
										,[naumenCaseUUID] = case UPPER(s.naumenResultCode)
											when 'SUCCESS' then  s.naumenResultValue
											end
										, [naumenResultDesc] = iif(UPPER(s.naumenResultCode)!='SUCCESS', s.message, null)
										,naumenLoadDate = getdate()
								from [marketing].[docredy_pts] t
								inner join #tNaumenResult s
									on concat(t.marketProposal_ID,'|',t.cdate) = s.id
								where t.cdate = cast(getdate() as date)
							end
							if lower(@env)	= 'uat'
							begin
								update t
									set  naumenResultCode = s.naumenResultCode
										,[naumenCaseUUID] = case UPPER(s.naumenResultCode)
											when 'SUCCESS' then  s.naumenResultValue
											end
										, [naumenResultDesc] = iif(UPPER(s.naumenResultCode)!='SUCCESS', s.message, null)
										,naumenLoadDate = getdate()
								from [marketing].[docredy_pts_uat] t
								inner join #tNaumenResult s
									on concat(t.marketProposal_ID,'|',t.cdate) = s.id
								where t.cdate = cast(getdate() as date)
								
							end
							

						commit tran
						set @text=concat(':low_brightness: в naumen было загружено ', @SendRows, ' case для обзвона ', format(getdate(),'dd.MM.yyyy HH:mm:ss'))
							
						EXEC  [LogDb].dbo.SendToSlack_dwhNotification  @text

						set @tryCount += @reTry + 1
					end
					end
					if @isDebug =1
					begin
						select @ParamValue
						set @tryCount += @reTry + 1
					end
				end try
				begin catch
				if @@TRANCOUNT>0
					ROLLBACK TRAN
				declare @ERROR_NUMBER int =ERROR_NUMBER()  
				declare @ERROR_MESSAGE nvarchar(max)= ERROR_MESSAGE()

				if @ERROR_NUMBER > 51000 and @ERROR_NUMBER<52000
				begin
						
					--Отправить уведомление об проблеме warning
					
					set @error_description =concat_ws(' ',
						'ErrorNumber:', cast(format(ERROR_NUMBER(),'0') as nvarchar(50)),@newRows
						,'ErrorSEVERITY:', cast(format(ERROR_SEVERITY(),'0') as nvarchar(50)), @newRows
						,'ErrorState:',  cast(format(ERROR_State(),'0') as nvarchar(50)), @newRows
						,'ErrorProcedure:', isnull( ERROR_PROCEDURE() ,''), @newRows
						,'Error_line:',cast(format(ERROR_LINE(),'0') as nvarchar(50)), @newRows
						,'ErrorMessage:',  isnull(ERROR_MESSAGE(),''), @newRows
						)
      
      
					set @text=concat(':warning:  Загрузка данных в naumen завершилась с ошибкой - '
					, ' ', ERROR_MESSAGE(), '.'
					,' Попытка - ', @tryCount, ' '
					, format(getdate(),'dd.MM.yyyy HH:mm:ss')
						)
					EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
						@text = @text
						,@threadKey = @subject
      
					exec logdb.dbo.[LogAndSendMailToAdmin] 'catching error [etl].[Send_MarketingProposal2Naumen_docredy_pts_delete_10_04_2026]','Error','Error',@error_description
      
					set @tryCount+=1; 

					if @tryCount >=@reTry
					begin
						;throw @ERROR_NUMBER, @ERROR_MESSAGE, 16
					end
					else
						continue
				end
				if @ERROR_NUMBER in( 52000, 51000)
				begin

					set @error_description =concat_ws(' ',
						'ErrorNumber:', cast(format(ERROR_NUMBER(),'0') as nvarchar(50)),@newRows
						,'ErrorSEVERITY:', cast(format(ERROR_SEVERITY(),'0') as nvarchar(50)), @newRows
						,'ErrorState:',  cast(format(ERROR_State(),'0') as nvarchar(50)), @newRows
						,'ErrorProcedure:', isnull( ERROR_PROCEDURE() ,''), @newRows
						,'Error_line:',cast(format(ERROR_LINE(),'0') as nvarchar(50)), @newRows
						,'ErrorMessage:',  isnull(ERROR_MESSAGE(),''), @newRows
						)
					set @tryCount += @reTry + 1
					set @text=concat(':warning:  Загрузка данных в naumen завершилась с ошибкой - '
					, ' ', ERROR_MESSAGE(), '.'
					,' Попытка', @tryCount, ' '
					, format(getdate(),'dd.MM.yyyy HH:mm:ss')
						)
					EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
						@text = @text
						,@threadKey = @subject
      
					exec logdb.dbo.[LogAndSendMailToAdmin] 'catching error [etl].[Send_MarketingProposal2Naumen_docredy_pts_delete_10_04_2026]','Error','Error',@error_description
      
					break;
				end
				else
				begin
					;throw 51000, @ERROR_MESSAGE, 16
				end
				end catch
			end
		FETCH NEXT FROM cur_send2Naumen   
		INTO @group_num

		END   
		CLOSE cur_send2Naumen;  
		DEALLOCATE cur_send2Naumen;  
		
		declare @msg nvarchar(max)=concat(':white_check_mark: '
			, 'Загрузки данных по проекту докред pts в naumen завершена.',
			'env: ', @env
			)
	if  lower(@env) = 'prod'
	begin

		--DWH-2740
		INSERT Stg.ivr.PhoneSendToNaumen(phone)
		SELECT DISTINCT M.phone
		FROM marketing.docredy_pts AS M
		where M.cdate = cast(getdate() as date)
			AND M.naumenCaseUUID is not NULL
			AND M.phone IS NOT NULL
			AND NOT EXISTS(
				SELECT TOP(1) 1 
				FROM Stg.ivr.PhoneSendToNaumen AS X
				WHERE X.phone = M.phone
			)

	--select string_agg(concat('Загружно :', count(1), ' код результата', isnull(naumenResultCode, 'unknown')), ';')
	;with cte_result_prod as (select TotalRecord = count(1), 
			naumenResultCode = isnull(naumenResultCode, UPPER('unknown'))
		from [marketing].[docredy_pts] t
			where cdate = cast(getdate() as date)
			and phoneInBlackList = 0
		--	and t.interactionTypeCode in (select interactionTypeCode from @interactionTypeCode)
			group by isnull(naumenResultCode, UPPER('unknown'))
			)
		
		select @msg = concat(@msg, 
			'Результат: ', (select string_agg(concat(TotalRecord, ' c кодом результата - ', naumenResultCode), ';') from cte_result_prod)
			, ' ', format(getdate(),'dd.MM.yyyy HH:mm:ss'))
	end
	if  lower(@env) = 'uat'
	begin
	--select string_agg(concat('Загружно :', count(1), ' код результата', isnull(naumenResultCode, 'unknown')), ';')
	;with cte_result_uat as (select TotalRecord = count(1), 
			naumenResultCode = isnull(naumenResultCode, UPPER('unknown'))
		from [marketing].[docredy_pts_uat] t
			where cdate = cast(getdate() as date)
			and phoneInBlackList = 0
		
			group by isnull(naumenResultCode, UPPER('unknown'))
			)
			
		
		select @msg = concat(@msg, 
			'Результат: ', (select string_agg(concat(TotalRecord, ' c кодом результата - ', naumenResultCode), ';') from cte_result_uat)
			, ' ', format(getdate(),'dd.MM.yyyy HH:mm:ss'))
	end
			EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
				@text = @msg
				,@threadKey = @subject
			exec logdb.dbo.[LogAndSendMailToAdmin] 'exec [etl].[Send_MarketingProposal2Naumen_docredy_pts_delete_10_04_2026]','Info','Done',''
		
		
	end try
	begin catch
		if @@TRANCOUNT>0
			ROLLBACK TRAN
		
		IF CURSOR_STATUS('global','cur_send2Naumen') >-1
		 BEGIN
		  IF CURSOR_STATUS('global','cur_send2Naumen') > -1
		   BEGIN
			CLOSE cur_send2Naumen
		   END
		 DEALLOCATE cur_send2Naumen
		END

		set @error_description =concat_ws(' ',
						'ErrorNumber:', cast(format(ERROR_NUMBER(),'0') as nvarchar(50)),@newRows
						,'ErrorSEVERITY:', cast(format(ERROR_SEVERITY(),'0') as nvarchar(50)), @newRows
						,'ErrorState:',  cast(format(ERROR_State(),'0') as nvarchar(50)), @newRows
						,'ErrorProcedure:', isnull( ERROR_PROCEDURE() ,''), @newRows
						,'Error_line:',cast(format(ERROR_LINE(),'0') as nvarchar(50)), @newRows
						,'ErrorMessage:',  isnull(ERROR_MESSAGE(),''), @newRows
						)
      
		set @text=':exclamation: Ошибка загрузки данных по проекту докред pts в naumen'+format(getdate(),'dd.MM.yyyy HH:mm:ss')
		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
				@text = @text
      
		exec logdb.dbo.[LogAndSendMailToAdmin] 'catching error [etl].[Send_MarketingProposal2Naumen_docredy_pts_delete_10_04_2026]','Error','Error',@error_description
      
		;throw 51000, @error_description, 1
		
	end catch
end
