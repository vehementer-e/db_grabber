--DWH-939
create   procedure dialer.CreateClientContractStageFromLoginom_envelope
as
begin
	declare @text nvarchar(max)=N''
  
	  declare @error_description nvarchar(4000)=N''
		--set @text='Заливка данных в Loginom. '+format(getdate(),'dd.MM.yyyy HH:mm:ss')
	 --   EXEC dwh_new.[Log].SendToSlack_dwhNotification  @text
            
	exec logdb.dbo.[LogAndSendMailToAdmin] 'trying start  dwh_new.dialer.CreateClientContractStageFromLoginom','Info',' started', ''
	begin try
       
		 exec dialer.CreateClientContractStageFromLoginom

		exec logdb.dbo.[LogAndSendMailToAdmin] 'exec dwh_new.dialer.CreateClientContractStageFromLoginom - completed successfully','Info','Done', ''
		--set @text=':heavy_check_mark: Заливка данных в Loginom завершено успешно. '+format(getdate(),'dd.MM.yyyy HH:mm:ss')
		--EXEC dwh_new.[Log].SendToSlack_dwhNotification  @text
        
        
	end try
	begin catch
		set @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
      
      
		--set @text=':exclamation: Заливка данных в Loginom. завершена с ошибкой. '+format(getdate(),'dd.MM.yyyy HH:mm:ss')
		--EXEC dwh_new.[Log].SendToSlack_dwhNotification  @text
      
		exec logdb.dbo.[LogAndSendMailToAdmin] 'catching error  dwh_new.dialer.CreateClientContractStageFromLoginom','Error','Error',@error_description
      
		;throw 51000, @error_description, 1
	end catch
  
end