--DWH-940

CREATE   procedure [dbo].[povt_envelope]
as 
begin

	
	declare @text nvarchar(max)=N''
  
	declare @error_description nvarchar(4000)=N''
		set @text='Маркетинговые предложения. Старт формирование витрины - повторные клиенты - povt' +format(getdate(),'dd.MM.yyyy HH:mm:ss')
	EXEC [LogDb].dbo.SendToSlack_dwhNotification  @text
	exec logdb.dbo.[LogAndSendMailToAdmin] 'trying start dbo.povt','Info',' started', ''
	
	begin try
       
		 exec dbo.povt
	
		exec logdb.dbo.[LogAndSendMailToAdmin] 'exec dbo.pov - completed successfully','Info','Done', ''
		set @text=':heavy_check_mark: Маркетинговые предложения. Формирование витрины - повторные клиенты - povt завершено.' +format(getdate(),'dd.MM.yyyy HH:mm:ss')
		EXEC logdb.dbo.SendToSlack_dwhNotification  @text
    
        
	end try
	begin catch
		set @error_description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
      
      
		set @text=':exclamation:  Маркетинговые предложения. Формирование витрины - повторные клиенты - povt завершено с ошибкой. '+format(getdate(),'dd.MM.yyyy HH:mm:ss')
		EXEC  [LogDb].dbo.[SendToSlack_DwhAlarm]  @text
      
		exec logdb.dbo.[LogAndSendMailToAdmin] 'catching error dbo.povt','Error','Error',@error_description
      
		;throw 51000, @error_description, 1
	end catch

end


