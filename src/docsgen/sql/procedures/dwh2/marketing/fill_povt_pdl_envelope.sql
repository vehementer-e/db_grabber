
CREATE   procedure [marketing].[fill_povt_pdl_envelope]
as
begin
	declare @sp_name nvarchar(255) = OBJECT_NAME(@@PROCID)
		,@text nvarchar(max)=N''
		,@new_line nvarchar(255) = char(10)+char(13)
  		,@subject nvarchar(255) = concat_ws(' '
		, 'Формирование витрины для повторники PDL - marketing.povt_pdl'
		, format(getdate(), 'dd.MM.yyyy HH:mm'))
		
		
		,@error_description nvarchar(4000)=N''
		set @text=CONCAT_WS(' '
			,'Маркетинговые предложения. Старт начано формирование витрины для повторники PDL - marketing.povt_pdl'
			, format(getdate(),'dd.MM.yyyy HH:mm:ss')
			)
	begin try
	EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
				@text = @text
				,@threadKey = @subject
	exec logdb.dbo.[LogAndSendMailToAdmin] 'trying start [marketing].[fill_povt_pdl]','Info',' started', ''
	
	
       
		exec [marketing].[fill_povt_pdl]
		if not exists(select top(1) 1 from marketing.povt_pdl t
		where t.cdate = cast(getdate() as date))
		begin
			SET @text = 'При формирование маркетинговые предложения повторники PDL произошла ошибка, данных в таблице povt_pdl нет.'
			;throw 51000, @text, 1
		end	
		exec logdb.dbo.[LogAndSendMailToAdmin] 'exec [marketing].[fill_povt_pdl] - completed successfully','Info','Done', ''
		set @text=CONCAT_WS(' '
			, ':heavy_check_mark: Маркетинговые предложения. Формирование витрины для повторники PDL  - marketing.povt_PDl завершен.'
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
			, ':exclamation: Маркетинговые предложения. Формирование витрины для повторники инстолмент - marketing.povt_pdl с ошибкой. '
			,format(getdate(),'dd.MM.yyyy HH:mm:ss')
			)
		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
				@text = @text
				
      
		exec logdb.dbo.[LogAndSendMailToAdmin] 'catching error [marketing].[fill_povt_pdl]','Error','Error',@error_description
      
		;throw 51000, @error_description, 1
	end catch
end
