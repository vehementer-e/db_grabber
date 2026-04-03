create proc sp_job_killer as 

if exists (
select * from jobs_running where job like '%_defect_catcher%' and minrunning >=20
)

exec msdb.dbo.sp_stop_job @job_name = 'Analytics._defect_catcher each 10 min at 7:00' 
