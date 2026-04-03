

CREATE PROCedure [finAnalytics].[sys_log] 
		@prc nvarchar(255) --процедура для которой происходит логирование
		,@step bit -- если 0 то старт, 1 финиш
		,@mainPrc nvarchar(255)=''
		,@isError bit =0 -- если 0 то нет ошибок, 1 есть ошибка
		,@Mem nvarchar(2000)='Ok' -- сообщение 
		
AS
BEGIN
 declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
 declare @subject nvarchar(250)
  declare @message nvarchar(max)=''
 
 
 declare @reptime datetime=getdate()
 begin try	
	begin tran 
		insert into dwh2.[finAnalytics].[SYS_prcLog] (reptime, prc, step,mainPrc, isError, Mem)
			values(@reptime, @prc,@step,@mainPrc,@isError,@Mem)
	commit tran
 end try 
 begin catch
    ROLLBACK TRANSACTION
	set @message=CONCAT('Ошибка выполнения процедуры - ',@sp_name,'. Ошибка ',ERROR_MESSAGE()) 
	set @subject='Ошибка! '
	exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '99'
   ;throw 51000 
			,@message
			,1;    
  end catch
	


	
END
