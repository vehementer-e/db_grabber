CREATE proc [dbo].[sp_job_skipped]
as


select distinct  a.Job_Name  , a.startSql from jobs a 
left join jobh b on a.job_id=b.job_id and a.step_id=b.step_id and b.Succeeded >=getdate()-3
left join jobh b1 on a.job_id=b1.job_id and a.step_id=b1.step_id and b1.Succeeded >=cast(getdate() as date)
where b.id is not null and b1.id is null
order by 1, 2

 