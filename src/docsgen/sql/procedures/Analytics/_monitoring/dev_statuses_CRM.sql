

CREATE     proc [_monitoring].[statuses_CRM]
 as

begin
--
return
		--select * from stg._1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС
if datepart(hour, getdate())<8 return

declare @datenow datetime =  getdate() 

declare @date  datetime = (select dateadd(year, -2000, max(Период) ) from stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС with(nolock) where Статус=0xA81400155D94190011E80784923C60A2 ) /* cast( getdate() as date)*/
declare @minutes_diff int  = datediff(minute, @date, @datenow)
declare @text nvarchar(max)  = 'Отсутствие статусов Верификация КЦ в stg._1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС последний статус - '+format(@date, 'dd-MMM HH:mm')
select @minutes_diff
if @minutes_diff > 30
begin
	  
exec log_email @text 
 
end


	 --select max([Верификация КЦ]) from reports.dbo.dm_Factor_Analysis

end
--exec  [dbo].[Проверка наличия заявок по RBP]
