create proc dbo.[Невыполненные джобы] 	 @n int = 8



as

begin

select a.step_id, a.Step_Name, a.Job_Name from  (
select distinct step_id, Step_Name, Job_Name from _v_sysjobhistory_stat
where Run_Date between getdate()-@n and getdate()-1	  and Run_Status= 'Succeeded'		   ) a
left join _v_sysjobhistory 
b 
on b.Job_Name=a.Job_Name and b.step_id=a.step_id and a.Step_Name=b.Step_Name	and b.Run_Status= 'Succeeded'	and b.is_Today_run=1
where											b.job_id is null --and a.ru
order by 3, 1



end