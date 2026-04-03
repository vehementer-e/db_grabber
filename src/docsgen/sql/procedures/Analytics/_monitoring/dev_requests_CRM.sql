
CREATE   proc [_monitoring].[requests_CRM]
 as

begin
--
return
if datepart(hour, getdate())<8 return

declare @datenow datetime =  getdate() 

declare @date  datetime = (select dateadd(year, -2000, max(Дата) ) from stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС) /* cast( getdate() as date)*/
declare @minutes_diff int  = datediff(minute, @date, @datenow)
declare @text nvarchar(max)  = 'Отсутствие заявок в stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС последняя заявка - '+format(@date, 'dd-MMM HH:mm')
select @minutes_diff
if @minutes_diff > 30
begin
	  
exec log_email @text 
 
end




end
--exec  [dbo].[Проверка наличия заявок по RBP]