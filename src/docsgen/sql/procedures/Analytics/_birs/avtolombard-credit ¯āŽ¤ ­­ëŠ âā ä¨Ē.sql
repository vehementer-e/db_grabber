CREATE PROC [_birs].[avtolombard-credit проданный трафик]

as
begin

select row_id
      ,format(created,'yyyy-MM-dd HH:mm:ss') created
	  ,format(sold,'yyyy-MM-dd HH:mm:ss') sold
	  ,ID
	  ,PhoneNumber
	  ,format(UF_REGISTERED_AT,'yyyy-MM-dd HH:mm:ss') UF_REGISTERED_AT
	  ,UF_SOURCE
	  ,Номер 
	  ,format(Отказано,'yyyy-MM-dd HH:mm:ss') Отказано
	  ,isinstallment
	  ,[Вид займа]
	  ,[Регион]
	  ,partner_lead_id
from Analytics.dbo.[Продажа трафика avtolombard-credit_log]
order by format(created,'yyyy-MM-dd HH:mm:ss')	desc

end