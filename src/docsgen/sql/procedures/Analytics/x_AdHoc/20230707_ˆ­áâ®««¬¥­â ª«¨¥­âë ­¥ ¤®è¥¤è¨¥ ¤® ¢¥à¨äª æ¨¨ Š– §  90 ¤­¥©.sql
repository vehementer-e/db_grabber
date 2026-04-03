CREATE proc 	[x_AdHoc].[20230707_Инстоллмент клиенты не дошедшие до верифкации КЦ за 90 дней]
as
begin
drop table if exists  #bl


select cast(Phone  as nvarchar(10)) UF_PHONE into #bl 
from stg._1ccrm.BlackPhoneList
--select * from #bl 

drop table if exists  #verif_cc

select Телефон, [Верификация кц] into #verif_cc  from reports.dbo.dm_factor_analysis_001
--where isinstallment=1


SELECT --a.id
	   --,a.client_mobile_phone
	   --,u.username
	   --,a.created_at
	   --,a.requests_origin_id
	  a.id, a.created_at,  isnull(a.client_mobile_phone, u.username) client_mobile_phone
	  into #t2
FROM stg._lk.requests a
left join stg._lk.users u on u.id=a.client_id
left join #verif_cc b on a.client_mobile_phone=b.Телефон
left join #verif_cc b1 on u.username=b1.Телефон
left join #bl bl  on bl.UF_PHONE=a.client_mobile_phone
left join #bl bl1 on bl1.UF_PHONE= u.username
WHERE is_installment = 1	and a.created_at between cast(getdate()-90 as date)		 and cast( getdate()-1 as date)
and b.Телефон is null
and b1.Телефон is null
and bl1.UF_PHONE is null
and bl.UF_PHONE is null

drop table if exists #requests_events
select a.request_id, a.created_at, b.name into #requests_events from 
stg._lk.requests_events a join 
stg._lk.events b on a.event_id=b.id


;with v  as (select *, row_number() over(partition by request_id order by created_at desc) rn from #requests_events ) delete from v where rn>1

	 select a.created_at [дата], a.client_mobile_phone, b.created_at [Дата события], name что_произошло into #t3 from #t2 a 
	 left join #requests_events b on a.id=b.request_id

;with v  as (select *, row_number() over(partition by client_mobile_phone order by [дата] desc) rn from #t3 ) delete from v where rn>1

select * from 	#t3
order by [дата]

end