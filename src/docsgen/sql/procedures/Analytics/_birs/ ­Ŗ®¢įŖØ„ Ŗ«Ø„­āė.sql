create   proc [_birs].[Банковские клиенты]
as
begin



drop table if exists #marketing_attribution


;

		  with v as (
select *, ROW_NUMBER() over(partition by phonenumber , [Канал от источника], cast(dt as date)  order by dt) rn from marketing_attribution	
)
 select * into #marketing_attribution from v
 where rn=1

drop table if exists #t3


;
SELECT b.id
 	, b.dt
 	, b.phonenumber
 	, b.[Канал от источника]
 	, b.type
	, a.UF_PHONE
--	, b.uf_name
	, a.UF_LOGINOM_STATUS
	, a.UF_LOGINOM_DECLINE
	, a.uf_registered_at
	, a.[ВРемяПервойПопытки]
	,a.[ВРемяПервогоДозвона]
	,a.[ЧислоПопыток]
	,a.attempt_result

	,статуслидафедор
	,причинанепрофильности
	,isinstallment
	into #t3
FROM #marketing_attribution b
LEFT JOIN feodor.dbo.dm_leads_history a ON a.id = b.id


select 
  a.*
, ROW_NUMBER() over(partition by phonenumber , a.[Канал от источника], dt order by [Верификация КЦ]) [Номер строки]
, b.Номер
, b.[product]
, b.[Выданная сумма]
, b.[Текущий Статус] 
, b.[Канал от источника] 
, b.[Вид займа] 
, b.[Верификация КЦ] 					 
from #t3 a 
left join reports.dbo.dm_factor_analysis_001 b on a.phonenumber=b.Телефон and b.[Верификация КЦ] between a.dt  	 and dateadd(day, 90, a.dt   )

--order by 2


end