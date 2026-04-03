create   proc partner_considerManualChanges
as
--exec _gs 'get_sql '

declare @dt  datetime2 = getdate()

exec _gs 'Кейсы партнеров', 0
exec python 'consider_partner_changes()', 1
--declare @dt  datetime2 = getdate()

 ; while @dt is not null
 begin
  
 WAITFOR delay '00:01:00'; 

 --select * from jobh where command ='exec Reports.[dbo].[report_Factor_Analysis_001]
 --'

 if exists ( select * from jobh where command ='exec Reports.[dbo].[report_Factor_Analysis_001]
 '
 and
 created>= @dt and Succeeded is not null )set @dt = null


 end

exec _gs 'кейсы партнеров to gs', 0
exec log_email 'consider_partner_changes done' 



