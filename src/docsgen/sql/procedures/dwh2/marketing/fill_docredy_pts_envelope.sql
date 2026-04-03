CREATE   PROC [marketing].[fill_docredy_pts_envelope]
as
begin
	declare @sp_name nvarchar(255) = object_name(@@PROCID)
		,@text nvarchar(max)=N''
		,@new_line nvarchar(255) = char(10)+char(13)
  		,@subject nvarchar(255) =  concat_ws(' '
		, 'Формирования витрины для докредов - marketing.docredy_pts'
		, format(getdate(), 'dd.MM.yyyy HH:mm'))
		,@error_description nvarchar(4000)=N''
		
	begin try
		set @text = CONCAT_WS(' ',
			'Маркетинговые предложения. Старт формирования витрины для докредов - marketing.docredy_pts' 
			,format(getdate(),'dd.MM.yyyy HH:mm:ss')
			)
		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
				@text = @text
				,@threadKey = @subject

		EXEC LogDb.dbo.LogAndSendMailToAdmin 'trying start marketing.fill_docredy_pts','Info','started', ''
	
	
      
		EXEC marketing.fill_docredy_pts
		
		if not exists(select top(1) 1 from marketing.docredy_pts t
		where t.cdate = cast(getdate() as date))
		begin
			SET @text = 'При формирование маркетинговые предложения докреды ПТС произошла ошибка, данных в таблице docredy_pts нет.'
			;throw 51000, @text, 1
		end

		EXEC LogDb.dbo.LogAndSendMailToAdmin 'exec marketing.fill_docredy_pts - completed successfully','Info','Done', ''
		SET @text = CONCAT_WS(' ',
			':heavy_check_mark: Маркетинговые предложения. Формирование витрины для докреды ПТС - marketing.docredy_pts завершен.' 
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
		set @text=CONCAT_WS(' ',
			':exclamation: Маркетинговые предложения. Формирование витрины для докредов ПТС - marketing.docredy_pts с ошибкой. '
				,format(getdate(),'dd.MM.yyyy HH:mm:ss')
				)
		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
				@text = @text

      
		EXEC LogDb.dbo.LogAndSendMailToAdmin 'catching error marketing.fill_docredy_pts','Error','Error',@error_description
      
		;throw 51000, @error_description, 1
	end catch
end