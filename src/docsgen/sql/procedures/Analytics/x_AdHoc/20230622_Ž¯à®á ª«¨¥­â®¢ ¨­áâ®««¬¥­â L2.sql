
create  

proc x_AdHoc.[20230622_Опрос клиентов инстоллмент L2]
@mode nvarchar(max) = 'update'
as

begin



drop table if exists #clients

select CRMClientGUID                                       
,      count(case when isInstallment=1 then 1 end)          count_inst
,      count(case when [Дата погашения] is null then 1 end) [Открытые]
 
into #clients
from mv_loans
group by CRMClientGUID
having count(case when isInstallment=1 then 1 end)=2
and   count(case when isInstallment=0 then 1 end)=0
--order by


drop table if exists  #bl


select cast(Phone  as nvarchar(10)) UF_PHONE into #bl 
from stg._1ccrm.BlackPhoneList
--select * from #bl 




SELECT   [Основной телефон клиента CRM]
	,max([Максимальная просрочка]) [Максимальная просрочка]
	,cast(max([Дата выдачи последнего займа]) as date) [Дата выдачи последнего займа]
FROM mv_loans a
JOIN #clients b ON a.CRMClientGUID = b.CRMClientGUID
	AND Открытые = 0
	AND [Дата выдачи последнего займа] = [Дата выдачи]
	left join #bl c on c.UF_PHONE=a.[Основной телефон клиента CRM]
	where c.UF_PHONE is null
group by [Основной телефон клиента CRM]
order by  3 desc
	 






end

