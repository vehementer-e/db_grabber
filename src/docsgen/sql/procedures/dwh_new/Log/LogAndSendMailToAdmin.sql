-- ============================================= 
-- Author: Andrey Shubkin 
-- Create date: 25.02.2019 
-- Description: add message into log and send email into 'adminlog' email list 
-- exec [log].[LogAndSendMailToAdmin] 'procedure name','Error','Error execute procedure','awesome errors and descriptions' 
-- ============================================= 
create PROCEDURE [log].[LogAndSendMailToAdmin] 
       @eventName nvarchar(50) 
      ,@eventType nvarchar(50) 
      ,@message nvarchar(1024)='' 
      ,@description nvarchar(1024)='' 
AS 
BEGIN 
SET NOCOUNT ON; 
    declare @tsql nvarchar(4000) 
    ,@subject nvarchar(1024) 
    ,@body nvarchar(1024) 
    


SET NOCOUNT ON; 

    insert into [log]._log   (  
       [loggerName] 
      ,[logDateTime] 
      ,[logDate] 
      ,[logDtStarted] 
      ,[logDtEnded] 
      ,[logEventName] 
      ,[logEventType] 
      ,[logEventParams] 
      ,[logEventStatus] 
      ,[logEventDescription]) 
    select 
       'adminlog' 
       ,getdate() 
       ,getdate() 
       ,getdate() 
       ,getdate() 
       ,@eventName 
       ,@eventType 
       ,@message 
       ,'log' 
       ,null 



    declare @recipients nvarchar(1024)=''   
    select  @recipients=[emails] 
    from    [log].Emails  
    where 
            [loggerName]        ='adminlog'    
          
   --select @recipients 


   set @body=cast( FORMAT (getdate(), 'dd.MM.yyyy hh:mm:ss ')   as nvarchar(22))+' ' + @eventName+' '+ @message+'<br>'+'<br>'+@description 
   set @subject=@eventType+' - '+ @eventName 


if ltrim(rtrim(@recipients)) <>'' 
begin 
SET @tsql = '     
			EXEC msdb.dbo.sp_send_dbmail  
										@profile_name = ''Default'',  
										@recipients = ''' + @recipients + ''',  
										@body = '''+ @body+''',  
										@body_format=''HTML'', 
										@subject = '''+@subject+''' 
   '; 
          -- select @tsql 
  EXEC (@tsql) 
end 



END 