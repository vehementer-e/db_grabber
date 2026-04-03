create   proc [_birs].[bank_clients_creation]
	  @mode nvarchar(max) = 'update'
as


begin
if @mode = 'update'

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

drop table if exists #t4

select 
  a.*
, ROW_NUMBER() over(partition by phonenumber , a.[Канал от источника], dt order by [Верификация КЦ]) [Номер строки]
, b.Номер
, b.[product]
, b.[Выданная сумма]
, b.[Текущий Статус] 
, b.[Канал от источника]  [Канал от источника Заявка]
, b.[Вид займа] 
, b.[Верификация КЦ] 
into #t4
from #t3 a 
left join reports.dbo.dm_factor_analysis_001 b on a.phonenumber=b.Телефон and b.[Верификация КЦ] between a.dt  	 and dateadd(day, 90, a.dt   )

--order by 2
 											  
--drop table if exists _birs.[bank_clients]
--select * into _birs.[bank_clients] 
--from #t4



  delete from _birs.[bank_clients]
  insert into _birs.[bank_clients]
  select * from #t4


  	
exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '167AE9C3-3B97-4713-A1F8-19EF22B775A9', 1

end
if @mode = 'select'

begin

 select * from  _birs.[bank_clients]

end 


end