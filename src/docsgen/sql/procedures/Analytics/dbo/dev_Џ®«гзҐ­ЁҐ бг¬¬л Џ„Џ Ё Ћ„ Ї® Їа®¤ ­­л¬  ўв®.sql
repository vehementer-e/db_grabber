CREATE  
proc
--exec
[dbo].[dev_Получение суммы ПДП и ОД по проданным авто]
as

begin

declare @sql nvarchar(max) =
'
select 1 номер, ''21121600164322'' external_id, '''' vin, cast(''2024-08-26'' as date) date union all
select 2 номер, ''22061400421496'' external_id, '''' vin, cast(''2024-08-27'' as date) date union all
select 3 номер, ''20111700052258/21012800074010/21040600095160'' external_id, '''' vin, cast(''2024-08-19'' as date) date union all
select 4 номер, ''22091200519297'' external_id, '''' vin, cast(''2024-08-30'' as date) date union all
select 5 номер, ''21052100107846'' external_id, '''' vin, cast(''2024-08-29'' as date) date union all
select 6 номер, ''23091201184991'' external_id, '''' vin, cast(''2024-08-31'' as date) date union all
select 7 номер, ''23082301138631'' external_id, '''' vin, cast(''2024-08-20'' as date) date union all
select 8 номер, ''23013100688287'' external_id, '''' vin, cast(''2024-08-22'' as date) date union all
select 9 номер, ''20121600062190/21031300087736/21090700134674'' external_id, '''' vin, cast(''2024-08-29'' as date) date union all
select 10 номер, ''22103000561298/23072001065847'' external_id, '''' vin, cast(''2024-08-23'' as date) date union all
select 11 номер, ''23092101207252'' external_id, '''' vin, cast(''2024-08-30'' as date) date union all
select 12 номер, ''23123101620316'' external_id, '''' vin, cast(''2024-08-28'' as date) date --union all



'

set @sql = 'drop table if exists analytics.dbo.__tmp_sales_of_cars select * into analytics.dbo.__tmp_sales_of_cars from (' + @sql +' ) x'
exec ( @sql)

--select * from analytics.dbo.__tmp_sales_of_cars
--where cast(format(date, 'yyyy-MM-01') as date)='20210901'

				drop table if exists #vins
select d.Number, isnull(pi.Vin, mfo_z.VIN)  vin into #vins from				
stg._Collection.Deals d 				
left join stg._Collection.DealPledgeItem dpi on dpi.DealId=d.id 				
left join stg._Collection.PledgeItem pi on dpi.PledgeItemId=pi.id				
left join stg._1cMFO.Документ_ГП_Заявка mfo_z on mfo_z.Номер=d.Number				
;				
				
--select * from #vins				
				
				
				drop table if exists #cr_ap;
				
with v as (				
select 				
номер,				
case when external_id like 'Бизнес займ%' then external_id				
else 				
nullif(replace(				
replace(				
replace(				
replace(				
replace(				
replace(				
replace(				
external_id				
, ',1', '')				
, ' ', '')				
, ';', '/')				
, '\', '/')				
, ':', '/')				
, 'и', '/')				
, ',', '/'), '') end external_id,				
vin,				
date				
from  analytics.dbo.__tmp_sales_of_cars				
				
),				
v_v as				
(				
select-- top 100000				
номер, isnull(external_id, x.numbers) dogovor , a.vin, date, x.numbers 	, a.external_id				
from v a 				
outer apply (select STRING_AGG(v.Number, '/') numbers from #vins v where v.vin=a.vin and a.external_id is null and a.vin <>'' ) x				
)				
				
--select *  from v_v	
--order by 1
select * into #cr_ap from v_v				
cross apply string_split(dogovor, '/')          x  				

			select * from #cr_ap
			order by 1

drop table if exists #final;
				
select a.Номер			
				
--,      cast( cmr.[остаток од] as bigint)                               [ОД]				

,      cast(sum(cmr.[остаток од]) over(partition by a.dogovor) as bigint) [ОД сумма]		
,      cast(sum(cmr.[остаток всего]) over(partition by a.dogovor) as bigint) [ПДП сумма]
,      cast(sum(cmr.[остаток пени]) over(partition by a.dogovor) as bigint) [остаток пени]
,      cast(sum(cmr.[остаток %]) over(partition by a.dogovor) as bigint) [остаток %]
,      cast(sum(cmr.[остаток иное (комиссии, пошлины и тд)]) over(partition by a.dogovor) as bigint) [остаток иное (комиссии, пошлины и тд)]
 

--,      cast( mfo.principal_rest as bigint)                               [ОД_мфо]			
--,      cast(sum(mfo.principal_rest) over(partition by a.dogovor) as bigint) [ОД сумма мфо]	
--,      cast(sum(mfo.total_rest) over(partition by a.dogovor) as bigint) [ПДП сумма мфо]	
--,      case when cast(sum(mfo.total_rest) over(partition by a.dogovor) as bigint)>0 and isnull(cast(sum(cmr.[остаток всего]) over(partition by a.dogovor) as bigint) , 0) =0 then cast(sum(mfo.total_rest) over(partition by a.dogovor) as bigint) 				
--        else  cast(sum(cmr.[остаток всего]) over(partition by a.dogovor) as bigint) end  [ПДП сумма итог]				
--,      case when cast(sum(mfo.principal_rest) over(partition by a.dogovor) as bigint)>0 and isnull(cast(sum(cmr.[остаток од]) over(partition by a.dogovor) as bigint) , 0) =0 then  cast(sum(mfo.principal_rest) over(partition by a.dogovor) as bigint)				
--        else  cast(sum(cmr.[остаток од]) over(partition by a.dogovor) as bigint) end  [ОД сумма итог]				
--, max(cmr.dpd)  over(partition by a.dogovor)  ПросрочкаПоКЛиентуЗаДеньДоПродажи

into #final				
from #cr_ap a				
left join   reports.dbo.dm_CMRStatBalance_2 cmr on cmr.external_id=a.value				 and cmr.d=dateadd(day, -1, a.date)
--left join   [dwh_new].[dbo].[stat_v_balance2] mfo on  mfo.external_id=a.value				 and mfo.cdate=dateadd(day, -1, a.date)
				
	
	
if exists (

select * from #cr_ap  a
left join #vins b on a.value=b.Number
where b.Number is null
--order by 1
)
begin

select 'Ошибка в номере договора'
select 1/0

end
				
				--select  * from #final
				select distinct * from #final
				order by 1





end