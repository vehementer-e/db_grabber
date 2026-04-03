CREATE   procedure [risk].[base_etl_person_envelope]
as
begin
	declare @sp_name nvarchar(255) = OBJECT_NAME(@@PROCID)
		,@text nvarchar(max)=N''
		,@new_line nvarchar(255) = char(10)+char(13)
	,@subject nvarchar(255) =concat_ws(' '
			, 'Формирование risk.person'
			, format(getdate(), 'dd.MM.yyyy HH:mm'))

	declare @error_description nvarchar(4000)=N''
		set @text=Concat(':information_source:  ',
			'Старт формирование risk.person ',
			format(getdate(),'dd.MM.yyyy HH:mm:ss')
			)
	begin try

		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
					@text = @text
					,@threadKey = @subject
		exec logdb.dbo.[LogAndSendMailToAdmin] 'trying start risk.base_etl_person','Info',' started', ''

		
		exec [risk].[base_etl_person]

		exec logdb.dbo.[LogAndSendMailToAdmin] 'exec risk.base_etl_person - completed successfully','Info','Done', ''
		
		set @text=concat(':heavy_check_mark: ', 
			'Формирование  risk.person завершено успешно.',
			format(getdate(),'dd.MM.yyyy HH:mm:ss')
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
      
      
		set @text=concat(':exclamation: ', 
			'Формирование  risk.person завершено с ошибкой!',
			format(getdate(),'dd.MM.yyyy HH:mm:ss'))
		EXEC [CommonDb].[SendNotification].[Send2GChat_dwhNotification]
					@text = @text
      
		exec logdb.dbo.[LogAndSendMailToAdmin] 'catching error risk.base_etl_person','Error','Error',@error_description
      
		;throw 51000, @error_description, 1
	end catch
end