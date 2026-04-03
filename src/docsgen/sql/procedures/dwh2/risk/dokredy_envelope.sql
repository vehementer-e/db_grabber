CREATE procedure [risk].[dokredy_envelope]
as
begin
	declare @sp_name nvarchar(255) = OBJECT_NAME(@@PROCID)
		,@text nvarchar(max)=N''
		,@new_line nvarchar(255) = char(10)+char(13)
		,@subject nvarchar(255) =concat_ws(' '
			, 'Формирование витрины витрины по докредитованию и повторникам pts risk'
			, format(getdate(), 'dd.MM.yyyy HH:mm'))

		,@error_description nvarchar(4000)=N''
		set @text=concat(':information_source: '
			,'Маркетинговые предложения. Старт начано формирование витрины по докредитованию и повторникам pts '
			, format(getdate(),'dd.MM.yyyy HH:mm:ss')
			)
		begin try
		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
						@text = @text
						,@threadKey = @subject
		exec logdb.dbo.[LogAndSendMailToAdmin] 'trying start risk.etl_docredy_buffer','Info',' started', ''
	
	
       
		exec [risk].[etl_docredy_buffer]
			
		exec logdb.dbo.[LogAndSendMailToAdmin] 'exec risk.etl_docredy_buffer - completed successfully','Info','Done', ''
		set @text=concat(':heavy_check_mark: '
			,'Маркетинговые предложения. Формирование витрины по докредитованию и повторникам pts завершен. '
			, format(getdate(),'dd.MM.yyyy HH:mm:ss')
				)
	EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
					@text = @text
					,@threadKey = @subject
    
        
	end try
	begin catch
		set @error_description =concat_Ws(' '
			,'ErrorNumber: ',cast(format(ERROR_NUMBER(),'0') as nvarchar(50))
			,@new_line 
			,'ErrorSEVERITY: ', cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
			,@new_line
			,'ErrorState: ', cast(format(ERROR_State(),'0') as nvarchar(50))
			,@new_line
			,'ErrorProcedure: ', isnull( ERROR_PROCEDURE() ,'')
			,@new_line
			,'Error_line: ', cast(format(ERROR_LINE(),'0') as nvarchar(50))
			,@new_line
			,'Error_Message: ', isnull(ERROR_MESSAGE(),'')
      )
      
		set @text=concat(':exclamation: '
			,'Маркетинговые предложения. Формирование витрины по докредитованию и повторникам pts с ошибкой. '
			,format(getdate(),'dd.MM.yyyy HH:mm:ss')
			)
		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
					@text = @text
					
      
		exec logdb.dbo.[LogAndSendMailToAdmin] 'catching error risk.etl_docredy_buffer','Error','Error',@error_description
      
		;throw 51000, @error_description, 1
	end catch
end
