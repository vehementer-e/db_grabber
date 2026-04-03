--DWH-939
CREATE PROC [dm].[fill_Collection_StrategyDataMart_envelope]
	@ProcessGUID varchar(36) = NULL, -- guid процесса
	@isLogger bit = 1
as
begin
  declare @text nvarchar(max)=N''
	,@error_description nvarchar(4000)=N''
	,@new_line nvarchar(255) = char(10)+char(13)
  	,@subject nvarchar(255) = concat_ws(' '
		, 'Формирование витрины для Loginom - Collection_StrategyDataMart'
		, format(getdate(), 'dd.MM.yyyy HH:mm'))
	  select @ProcessGUID = isnull(@ProcessGUID, newid())
		, @isLogger = isnull(@isLogger, 0)

	  set @text=CONCAT_WS(' '
		,  'Начато формирование витрины для Loginom - Collection_StrategyDataMart.'
		,format(getdate(),'dd.MM.yyyy HH:mm:ss')
		)

	EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
			@text	 = 	 @text
			,@threadKey = @subject
	exec logdb.dbo.[LogAndSendMailToAdmin] 'trying start dm.fill_Collection_StrategyDataMart','Info',' started', ''
    begin try
             
      exec dm.fill_Collection_StrategyDataMart
		@ProcessGUID = @ProcessGUID,
		@isLogger = @isLogger
                   
      exec logdb.dbo.[LogAndSendMailToAdmin] 'trying start dm.fill_Collection_StrategyDataMart - completed successfully','Info','Done', ''

      set @text=concat_ws(' ',
		':heavy_check_mark: Формирование витрины для Loginom - Collection_StrategyDataMart завершено успешно. '
		,format(getdate(),'dd.MM.yyyy HH:mm:ss')
		)
		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
			@text	 = 	 @text
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
      
    
      set @text=concat_ws(' ',
		':exclamation: Формирование витрины для Loginom - Collection_StrategyDataMart завершено с ошибкой. '
			,format(getdate(),'dd.MM.yyyy HH:mm:ss')
			)
	 EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
		@text	 = 	 @text

      exec logdb.dbo.[LogAndSendMailToAdmin] 'catching error starting  dm.fill_Collection_StrategyDataMart - error occursed','Error','Error',@error_description
	
	;throw 51000, @error_description, 1

    end catch

end
