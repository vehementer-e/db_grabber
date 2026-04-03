create   proc notify_html
@subject nvarchar(max) = 'message',
@recepients nvarchar(max) = 'p.ilin@smarthorizon.ru',
@tableHTML nvarchar(max) = ''	 
as
 



set @subject = trim(REPLACE(REPLACE(@subject, CHAR(13), ''), CHAR(10), ''))


  EXEC msdb.dbo.sp_send_dbmail 
    @profile_name = 'Default',  
    --@recipients= 'analytics_kc@carmoney.ru',--'a.vdovin@carmoney.ru; A.Taov@carmoney.ru; analytics_kc@carmoney.ru',  --Zudin_S_D@carmoney.ru;; Krivotulov@carmoney.ru
    @recipients= @recepients , 
    @subject = @subject, 
    @body = @tableHTML,  
    @body_format = 'HTML' ;  
	
	 