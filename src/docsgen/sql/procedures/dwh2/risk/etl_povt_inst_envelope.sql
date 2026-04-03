
CREATE procedure [risk].[etl_povt_inst_envelope]
as
begin
	declare @sp_name nvarchar(255) = OBJECT_NAME(@@PROCID)
	,@text nvarchar(max)=N''
	,@new_line nvarchar(255) = char(10)+char(13)
	,@subject nvarchar(255) =concat_ws(' '
			, 'Формирование витрины витрины для повторники инстолмент risk'
			, format(getdate(), 'dd.MM.yyyy HH:mm'))

	,@error_description nvarchar(4000)=N''
		set @text=CONCAT_WS(' '
				, 'Маркетинговые предложения. Старт начано формирование витрины для повторники инстолмент - povt_inst'
				,format(getdate(),'dd.MM.yyyy HH:mm:ss')
				)
	begin try

		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
						@text = @text
						,@threadKey = @subject
		exec logdb.dbo.[LogAndSendMailToAdmin] 'trying start risk.etl_povt_inst_pdl_buffer','Info',' started', ''
	
	
       
		exec risk.[etl_povt_inst_pdl_buffer]
			
		exec logdb.dbo.[LogAndSendMailToAdmin] 'exec risk.etl_povt_inst_pdl_buffer - completed successfully','Info','Done', ''
		set @text=':heavy_check_mark: Маркетинговые предложения. Формирование витрины пдля повторники инстолмент - povt_inst завершен.' +format(getdate(),'dd.MM.yyyy HH:mm:ss')
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
      
      
		set @text=':exclamation: Маркетинговые предложения. Формирование витрины пдля повторники инстолмент - povt_inst с ошибкой. '+format(getdate(),'dd.MM.yyyy HH:mm:ss')
		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
						@text = @text
						
      
		exec logdb.dbo.[LogAndSendMailToAdmin] 'catching error risk.etl_povt_inst_pdl_buffer','Error','Error',@error_description
      
		;throw 51000, @error_description, 1
	end catch
end
