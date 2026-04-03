CREATE procedure [etl].[etl_reports_ready_notification]
as
begin

 set nocount on

 declare @text nvarchar(max)=N''

if (select count(*) from [Reports].[dbo].[report_kpi] where cast(cast([ДатаЧислом]-2 as datetime) as date)=cast(dateadd(day,-1,getdate()) as date) ) is not null 
 
begin  
     set @text='Витрина Отчет KPI - Результат: Витрина готова. ' +format(getdate(),'dd.MM.yyyy HH:mm:ss')

     EXEC dwh_new.[Log].SendToSlack_dwhNotification  @text
	   exec dwh_new.[Log].[LogAndSendMailToServiceDesc] 'Витрина Отчет KPI','Info','Результат: ','Витрина готова' ;
	end  
else    
	begin 
    set @text='Витрина Отчет KPI - Результат: Витрина не готова. ' +format(getdate(),'dd.MM.yyyy HH:mm:ss')

     EXEC dwh_new.[Log].SendToSlack_dwhNotification  @text
		exec dwh_new.[Log].[LogAndSendMailToServiceDesc] 'Витрина Отчет KPI','Info','Результат: ','Витрина не готова' ;  
	end 

end
