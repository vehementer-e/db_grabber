CREATE   proc [_birs].[cost_of_calls_creation]	@mode nvarchar(max) = 'update'
as
begin


if @mode = 'update'

begin

--declare @update_dt date = '20230901'
declare @update_dt date = getdate()-3

drop table if exists #dos
select cast(dos.attempt_start as date) attempt_start_date
, dos.project_id
, sum(datediff(second, cl.connected , dos.attempt_end)) seconds_to_pay
, m.title
, sum(datediff(second, cl.connected , dos.attempt_end))/60.0*2 Стоимость
into #dos
from [NaumenDbReport].[dbo].[detail_outbound_sessions] dos with(index=[ix_project_id_attempt_start])
LEFT JOIN NaumenDbReport.dbo.call_legs AS cl --WITH(INDEX=idx_session_id)
ON cl.created >= dateadd(DAY, -1, @update_dt)
AND cl.session_id = dos.session_id
AND cl.leg_id = 1
LEFT JOIN naumendbreport.[dbo].[mv_outcoming_call_project] m
ON m.uuid = dos.project_id
where dos.attempt_start >= cast(@update_dt as datetime2)
group by 
cast(dos.attempt_start as date) , dos.project_id, m.title


delete from _birs.cost_of_calls
where attempt_start_date>=cast(@update_dt as date)


insert into _birs.cost_of_calls
select*from #dos

--select*from _birs.cost_of_calls
--order by attempt_start_date desc


exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  'B5BE1608-35B3-4E7F-AF6B-0904914ED0EA',1



end
if @mode = 'select'											   
select 
a.attempt_start_date,
a.project_id,
a.seconds_to_pay,
m.title,
a.Стоимость,
case when b.projectuuid is not null then 'Докреды и повторники'  else '' end    'Докреды и повторники'

from _birs.cost_of_calls	a
left join [Stg].[_mds].[NaumenProjects_DokrNPovt_prod] b on a.project_id=b.projectuuid
left join naumendbreport.[dbo].[mv_outcoming_call_project] m on a.project_id=m.uuid

end