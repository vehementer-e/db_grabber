--exec [etl].[base_etl_finished]
CREATE procedure  [etl].[base_etl_finished]
as
begin

 set nocount on
 declare @tsql nvarchar(4000) 
       , @subject nvarchar(1024) 
       , @body nvarchar(1024) 
 declare @recipients nvarchar(1024)=N'dwh112@carmoney.ru;Servicedesk@carmoney.ru;'
   
  set @subject='Risk DWH ETL process finished.'
  set @body='<br>'+cast( FORMAT (getdate(), 'dd.MM.yyyy HH:mm:ss ')   as nvarchar(22))+' '+@subject

      
			EXEC msdb.dbo.sp_send_dbmail  
										@profile_name = 'Default',  
										@recipients = @recipients ,  
										@body = @body,  
										@body_format='HTML', 
										@subject = @subject 
  ; 
   /*
SET @tsql = '     
			EXEC msdb.dbo.sp_send_dbmail  
										@profile_name = ''Default'',  
										@recipients = ''' + @recipients + ''',  
										@body = '''+ @body+''',  
										@body_format=''HTML'', 
										@subject = '''+@subject+''' 
   '; 
   */
  --select @tsql 


  	exec [log].[LogAndSendMailToAdmin] 'Risk DWH ETL process finished.','Info','procedure finished','Risk DWH ETL process finished.'



end
