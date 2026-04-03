
CREATE   proc [dbo].[create_dm_report_call0]
as
begin

--set datefirst 1
--drop table if exists #t1
--select  try_cast([id lcrm] as numeric(10, 0))   [id lcrm] into #t1 from [Feodor].[dbo].[dm_LeadAndSurvey] ls
--;with v  as (select *, row_number() over(partition by [id lcrm] order by (select null) )rn from #t1 ) delete from v where rn>1 or [id lcrm] is null;

drop table if exists #t2

select try_cast([id lcrm] as numeric(10, 0))   id                                        
,      Question                                         
,      max( case when answer like '%denial%' then 1 else 0 end) refuse 

into #t2
from [Feodor].[dbo].[dm_LeadAndSurvey] ls
where Question
	in
	(
	'GET_CAR_PLEDGIES_STATUS'
	,'GET_DEBTS_STATUS'
	,'PASSPORT_VALIDATION_STATUS'
	)
group by try_cast([id lcrm] as numeric(10, 0)), Question
  
  drop table if exists #f
  select Результат, ДеньЛида, МесяцЛида,НеделяЛида, [СТатус лида],  count(*) Количество into #f from 
  (
select l.id
, cast(l.[Дата лида] as date) ДеньЛида
, cast(format(l.[Дата лида] , 'yyyy-MM-01') as date) МесяцЛида
, cast(dateadd(day, datediff(day, '1900-01-01', l.[Дата лида] ) / 7 * 7, '1900-01-01') as date) as НеделяЛида
, l.[СТатус лида],
case 
when v_debts.refuse=1 then 'Отказ GET_DEBTS_STATUS'
when v_pasp_valid.refuse=1 then 'Отказ PASSPORT_VALIDATION_STATUS'
when v_car.refuse=1 then 'Отказ GET_CAR_PLEDGIES_STATUS'
when v_car.refuse=0 or v_debts.refuse=0 or v_pasp_valid.refuse=0 then 'Без отказов, с проверкой'
when v_car.refuse is null or v_debts.refuse is null or v_pasp_valid.refuse is null  then 'Без отказов, без проверок'
else 'Иначе' end Результат

from Analytics.dbo.v_feodor_leads l
left join #t2 v_debts on v_debts.id=l.id and v_debts.Question = 'GET_DEBTS_STATUS'
left join #t2 v_pasp_valid on v_pasp_valid.id=l.id and v_pasp_valid.Question = 'PASSPORT_VALIDATION_STATUS'
left join #t2 v_car on v_car.id=l.id and v_car.Question = 'GET_CAR_PLEDGIES_STATUS'
--join  on l.id  =a.[ID LCRM] 
--where [Статус лида]='Заявка'
--order by 1 desc 
) x
group by Результат, ДеньЛида, МесяцЛида, [СТатус лида], НеделяЛида
order by МесяцЛида, Результат, НеделяЛида

begin tran
--drop table if exists feodor.dbo.dm_report_call0
--DWH-1764
TRUNCATE TABLE dbo.dm_report_call0

INSERT feodor.dbo.dm_report_call0
(
    Результат,
    ДеньЛида,
    МесяцЛида,
    НеделяЛида,
    [СТатус лида],
    Количество
)
SELECT 
	Результат,
    ДеньЛида,
    МесяцЛида,
    НеделяЛида,
    [СТатус лида],
    Количество
--INTO feodor.dbo.dm_report_call0 
FROM #f

commit tran

end