CREATE   procedure [marketing].[fill_povt_inst_envelope]
as
begin
	declare @sp_name nvarchar(255) = OBJECT_NAME(@@PROCID)
		,@text nvarchar(max)=N''
		,@new_line nvarchar(255) = char(10)+char(13)
  		,@subject nvarchar(255) = concat_ws(' '
		, 'Формирование витрины для повторники инстолмент - marketing.povt_inst'
		, format(getdate(), 'dd.MM.yyyy HH:mm'))
		,@error_description nvarchar(4000)=N''
		set @text=Concat_ws(' '
			,'Маркетинговые предложения. Старт начано формирование витрины для повторники инстолмент - marketing.povt_inst '
			,format(getdate(),'dd.MM.yyyy HH:mm:ss')
			)
	begin try

		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
				@text = @text
				,@threadKey = @subject
		exec logdb.dbo.[LogAndSendMailToAdmin] 'trying start [marketing].[fill_povt_inst]','Info',' started', ''
	

       
		exec [marketing].[fill_povt_inst]
		if not exists(select top(1) 1 from marketing.povt_inst t
		where t.cdate = cast(getdate() as date))
		begin
			SET @text = 'При формирование маркетинговые предложения повторники инстолмент произошла ошибка, данных в таблице povt_inst нет.'
			;throw 51000, @text, 1
		end
			
		exec logdb.dbo.[LogAndSendMailToAdmin] 'exec [marketing].[fill_povt_inst] - completed successfully','Info','Done', ''
		set @text=CONCAT_WS(' ',
			':heavy_check_mark: Маркетинговые предложения. Формирование витрины для повторники инстолмент - marketing.povt_inst завершен. ' 
			,format(getdate(),'dd.MM.yyyy HH:mm:ss')
			)
		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
				@text = @text
				,@threadKey = @subject
    
        
	end try
	begin catch
		set @error_description =concat('ErrorNumber: ',cast(format(ERROR_NUMBER(),'0') as nvarchar(50)),	
			@new_line,
			' ErrorSEVERITY: ', cast(format(ERROR_SEVERITY(),'0') as nvarchar(50)),
			@new_line,
			' ErrorState: ', cast(format(ERROR_State(),'0') as nvarchar(50)),
			@new_line,
			' ErrorProcedure: ', isnull( ERROR_PROCEDURE() ,''),
			@new_line,
			' Error_line: ', cast(format(ERROR_LINE(),'0') as nvarchar(50)),
			@new_line,
			' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
			)
      
		set @text=CONCAT_WS(' '
			, ':exclamation: Маркетинговые предложения. Формирование витрины для повторники инстолмент - marketing.povt_inst с ошибкой. '
				,format(getdate(),'dd.MM.yyyy HH:mm:ss')
				)
		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
				@text = @text
      
		exec logdb.dbo.[LogAndSendMailToAdmin] 'catching error [marketing].[fill_povt_inst]','Error','Error',@error_description
      
		;throw 51000, @error_description, 1
	end catch
end