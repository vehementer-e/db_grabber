
CREATE   proc [dbo].[sale_calling_ANALYTICS_91]
as
--sp_create_job 'Analytics._sale_calling_ANALYTICS_91 at 1150', 'sale_calling_ANALYTICS_91' , '1', '115000'


drop table if exists #t1 

select --top 1000 
  
  a.feodorReason федор_Причина
, a.feodorStatus федор_Cтатус
, a.feodorResult федор_Результат 
, a.attemptedCnt колво_попыток
, a.attemptedResult наумен_результат
--, a.caseId 
, b.statetitle кейс_состояние
, a.created Дата_Создания_лида
, a.attemptedLast последняя_попытка
, case
when b. statetitle = 'Недозвон' then 'Недозвон'	
when a.feodorResult = 'Автоответчик' and  a.attemptedCnt = 5 then 'Автоответчик'
when a.feodorResult = 'Обрыв звонка' and  a.attemptedCnt = 5 then 'Обрыв звонка'
when a.feodorReason = 'Отказ от разговора' and  a.feodorStatus = 'Непрофильный' then 'Отказ от разговора'
when a.feodorStatus in ('Отказ клиента с РСВ', 'Отказ клиента без РСВ') then 'Отказ клиента'
else 'Другие' end   статус , 
a.phone 
into #t1
from v_lead2 a
join NaumenDbReport.dbo.mv_call_case b on a.caseId=b.uuid

where cast( attemptedLast as date) = cast(getdate()-1 as date)
and source = 'psb-deepapi'
order by attemptedLast

delete from #t1 where статус = 'Другие'

;with v as (select *, row_number() over(partition by phone order by (select 1 ) ) rnDelete  from #t1)
delete from v where rnDelete>1

 
drop table if exists [##ANALYTICS-91]

select * into [##ANALYTICS-91] from #t1

exec python 'dt = run_sql("select format(getdate()  , ''yyyy-MM-dd'' )").iloc[0,0]
sql2gs("select * from [##ANALYTICS-91]", "1GedCJKPl_selLmyJzPmzuomVFF2HOQQJTrdum3DZGk0", make_sheet_name = dt )', 1

exec log_email 'ANALYTICS-91 Выгрузка готова' , 'rgkc@carmoney.ru; k.peretyatko@carmoney.ru', 'https://docs.google.com/spreadsheets/d/1GedCJKPl_selLmyJzPmzuomVFF2HOQQJTrdum3DZGk0/edit?gid=0#gid=0'