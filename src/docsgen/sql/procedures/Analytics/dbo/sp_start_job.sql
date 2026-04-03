create   proc dbo.start_job
@query nvarchar(max) = null
as

begin

if exists (select top 1   * from jobs where ''+ cast(job_id as nvarchar(100)) like '%'+@query+'%'  
union all
select top 1   * from jobs where Job_Name like '%'+@query+'%'  
)
  select  distinct  Job_Name  into #jobs from jobs where ''+cast(job_id as nvarchar(100)) like '%'+@query+'%'  
union   
select   distinct  Job_Name from jobs where Job_Name like '%'+@query+'%'
  declare @rc bigint = 	@@ROWCOUNT
  if @rc>1
  select * from  #jobs
   if @rc=1 
  begin
  set @query = ( select top 1 * from 	#jobs)
  exec msdb.dbo.sp_start_job @query
	end

   if @rc=0
	   return




end