-- ============================================= 
-- Author: Andrey Shubkin 
-- Create date: 12.03.2019 
-- Description: add message into log and send email into 'airflow' email list 
-- exec [AirflowLogAndSendMail] 'procedure name','Error','Error execute procedure','awesome errors and descriptions' 
-- ============================================= 
CREATE PROCEDURE [dbo].[AirflowLogAndSendMail] 
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

    insert into _log   (  
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
       'Airflow' 
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
    from    Emails  
    where 
            [loggerName]        ='Airflow'    
          
   --select @recipients 
   

   set @body=cast( FORMAT (getdate(), 'dd.MM.yyyy HH:mm:ss ')   as nvarchar(22))+' ' + @eventName+' '+ @message+'<br>'+'<br>'+@description 
   set @subject=@eventType+' - '+ @eventName 


if ltrim(rtrim(@recipients)) <>'' 
begin 

			EXEC msdb.dbo.sp_send_dbmail
					@recipients = @recipients,  
					@body = @body,  
					@body_format='HTML', 
					@subject = @subject
; 

end 



END 