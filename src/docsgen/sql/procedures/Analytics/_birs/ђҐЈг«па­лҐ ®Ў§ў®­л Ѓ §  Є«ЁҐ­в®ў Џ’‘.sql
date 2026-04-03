

CREATE   proc [_birs].[Регулярные обзвоны База клиентов ПТС]

@report_date_ssrs date = null
as


begin

return

drop table if exists  #bl


select cast(Phone  as nvarchar(10)) UF_PHONE into #bl 
from stg._1ccrm.BlackPhoneList
--select * from #bl 



--declare @report_date_ssrs date = '20230301'
 declare @report_date date = @report_date_ssrs

  select  a.* from reports.dbo.dm_Report_DIP_to_Naumen_history	  a
  left join 	 #bl b on a.mobile_fin = b.UF_PHONE
  where [Дата Среза]=@report_date	  and b.UF_PHONE is null



  end