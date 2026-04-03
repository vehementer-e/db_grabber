
create proc _birs.[Регулярные обзвоны Докреды и повторники ПТС некрасные контактные 90 дней]

as

begin


drop table if exists #t1

SELECT mobile_fin
	,fio
	,crmclientguid
	into #t1
FROM dwh_new.dbo.CRM_loyals_buffer_for_sales
WHERE category <> 'Красный'	and main_limit>0

			    
drop table if exists  #bl


select cast(Phone  as nvarchar(10)) UF_PHONE into #bl 
from stg._1ccrm.BlackPhoneList
--select * from #bl 


drop table if exists #cont_90_d
select client_number into #cont_90_d from reports.dbo.dm_report_DIP_detail_outbound_sessions
where login is not null and attempt_start>=getdate()-90
  group by client_number
  --order by 

  drop table if exists #mv_loans

  select crmclientguid, [Дата выдачи], [Текущая процентная ставка]  into #mv_loans from 	 mv_loans where isinstallment=0
 

drop table if exists 	   #t3
select  a.mobile_fin, [Текущая процентная ставка], [Дата выдачи], b.UF_PHONE into #t3 from #t1 a
left join #bl b on a.mobile_fin=b.UF_PHONE
  join #cont_90_d c on '8'+a.mobile_fin=c.client_number
left join #mv_loans l on l.crmclientguid=a.crmclientguid   
--where b.UF_PHONE is null


;with v  as (select *, row_number() over(partition by mobile_fin order by [Дата выдачи] desc) rn from #t3 ) delete from v where rn>1  or UF_PHONE is not null


select 	mobile_fin,  [Текущая процентная ставка] [Последняя процентная ставка] from  #t3

end