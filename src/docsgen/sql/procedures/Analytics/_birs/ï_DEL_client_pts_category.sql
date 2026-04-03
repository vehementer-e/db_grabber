
CREATE  proc [_birs].client_pts_category

as

begin


drop table if exists #t1

SELECT mobile_fin phone
	,fio
	,crmclientguid client_id
	, Type type
	, main_limit main_limit
	into #t1
FROM dwh_new.dbo.CRM_loyals_buffer_for_sales
WHERE category <> 'Красный'	and main_limit>0


--select * FROM dwh_new.dbo.CRM_loyals_buffer_for_sales


			    
drop table if exists  #bl


select phone phone_blacklist into #bl 
from v_blacklist
--select * from #bl 


drop table if exists #cont_90_d
select '8'+right(client_number  , 10) phone8 into #cont_90_d from reports.dbo.dm_report_DIP_detail_outbound_sessions
where login is not null and attempt_start>=getdate()-90
  group by client_number
  --order by 

  drop table if exists #mv_loans

  select crmclientguid, [Дата выдачи], [Текущая процентная ставка]  into #mv_loans from 	 mv_loans where ispts=0
 

drop table if exists 	   #t3
select  a.phone,a.Type, [Текущая процентная ставка], [Дата выдачи], case when b.phone_blacklist is not null then 1 else 0 end [КЛИЕНТ В ЧС] , case when c.phone8 is not null then 1 else 0 end [контактный_90_дней] into #t3 from #t1 a
left join #bl b on a.phone=b.phone_blacklist
 left join #cont_90_d c on '8'+a.phone=c.phone8
left join #mv_loans l on l.crmclientguid=a.client_id   
--where b.UF_PHONE is null


;with v  as (select *, row_number() over(partition by phone order by [Дата выдачи] desc) rn from #t3 ) delete from v where rn>1 -- or UF_PHONE is not null


select 	  phone , Type ,   [Текущая процентная ставка] [Последняя процентная ставка], [КЛИЕНТ В ЧС], [контактный_90_дней] from  #t3

end