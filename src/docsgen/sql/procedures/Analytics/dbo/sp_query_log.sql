CREATE proc [dbo].[sp_query_log] 
@mode nvarchar(max) = ''	   , @login
nvarchar(max) = ''	   , @days int = 0

as
begin


drop table if exists #_v_sysjobs

 select distinct job_id_hexstr job_id_hexstr, step_id, Job_Name +' -> '+step_name job_step_name, job_name, step_name into #_v_sysjobs from jobs
--select top 100 * from #_v_sysjobs where job_step_name like '%temp %'
if @mode=''
begin

drop table if exists #max_log_datetime
  select max(log_datetime)  log_datetime into #max_log_datetime
  FROM query_log_view



drop table if exists #t1



SELECT TOP (1000) query_log_view.[log_datetime]
      ,[dd hh:mm:ss.mss]
      ,[session_id]
      ,[blocking_session_id]
      ,[sql_text]
      ,[sql_command]
      ,[status]
      ,[login_name]
      ,[wait_info]
      ,[database_name]
      ,[host_name]
      ,[percent_complete]
      ,[program_name]
      ,[additional_info]
      ,job_id_hexstr job_id_hexstr
      ,step_id step_id
      ,sql sql
	  --, Job_Name Job_Name
	  into #t1
  FROM query_log_view
  join #max_log_datetime log_datetime on log_datetime.log_datetime=query_log_view.log_datetime
  ;

  with v as (

    select
       a.[log_datetime]
      ,a.[dd hh:mm:ss.mss]
	  ,j.job_step_name
      ,a.[session_id] 
       ,a.[sql_text]
      ,a.[blocking_session_id]
      ,a.[sql_command]
      ,a.[status]
      ,a.[login_name]
      ,a.[wait_info]
      ,a.[database_name]
      ,a.[host_name]
      ,a.[percent_complete]
      ,a.[program_name]
      ,a.[additional_info] 
      ,a.sql 
	  , 'exec msdb.dbo.sp_stop_job @job_name = '''+j.job_name +''' 
--exec msdb.dbo.sp_start_job @job_name =''' +j.job_name +''', @step_name ='''+ REPLACE( step_name, '''', '''''') +'''' sql_stop
, 'exec sp_query_log '''+j.Job_Name+'''' sql_job_log
	  from #t1 a 
	  left join #_v_sysjobs j on j.job_id_hexstr=a.job_id_hexstr and a.step_id=j.step_id
  )


  select
       a.[log_datetime]
      ,a.[dd hh:mm:ss.mss]
	  ,a.job_step_name
      ,a.[session_id]
    --  ,a.[blocking_session_id] [blocking_session_id1]
       , [blocking_session_id] = case when b.job_step_name is not null then '!!! '+ b.job_step_name when b.login_name is not null then ' @'+b.login_name  else '' end+ try_cast(a.[blocking_session_id] as nvarchar(max)) +case when b.[sql_command] <>'' then '   ---'+b.[sql_command] else '' end  +case when b.sql_text <>'' then '   ---'+b.sql_text else '' end 
      ,[blocking_job_step_name] = b.job_step_name
      ,a.[sql_text]
      ,a.[sql_command]
      ,a.[status]
      ,a.[login_name]
      ,a.[wait_info]
      ,a.[database_name]
      ,a.[host_name]
      ,a.[percent_complete]
      ,a.[program_name]
      ,a.[additional_info]
      ,a.sql
      ,a.sql_stop
	  ,  a.sql_job_log
	  into #t2
	  from v a
	  left join v b on a.blocking_session_id=b.session_id 
  --order by 2
  select * from #t2
  where [login_name] like '%'+@login+'%'

  order by 2
  --where login_name ='CM\P.Ilin'
--where blocking_session_id is not null
  select * from #t2
  where [login_name] like '%'+@login+'%'

  --order by 2
  order by [session_id]


  return

--    SELECT
--    ja.job_id,
--    j.name AS job_name,
--    ja.start_execution_date,      
--    ISNULL(last_executed_step_id,0)+1 AS current_executed_step_id,
--    Js.step_name
--FROM msdb.dbo.sysjobactivity ja 
--LEFT JOIN msdb.dbo.sysjobhistory jh ON ja.job_history_id = jh.instance_id
--JOIN msdb.dbo.sysjobs j ON ja.job_id = j.job_id
--JOIN msdb.dbo.sysjobsteps js
--    ON ja.job_id = js.job_id
--    AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
--WHERE
--  ja.session_id = (
--    SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY agent_start_date DESC
--  )
--AND start_execution_date is not null
--AND stop_execution_date is null
----and j.name='REPORTS. Factor_Analysis, every 16 min from 7:30 till 23:59'
--order by 3 desc

end 


--select  * into #t1 from [история запросов]
--where log_datetime>getdate()-10
--
--
--select b.sql_command, b.blocking_session_id,a.* from #t1 a
--left join #t1 b on a.log_datetime=b.log_datetime and b.session_id=a.blocking_session_id
--where a.sql_command like '%povt_envelope%'
--order by a.log_datetime

----------------------------------------------------------
--/*

declare @job_id nvarchar(36)
declare @job_id_hexstr nvarchar(36)
declare @job_name nvarchar(36)

if (select count(distinct Job_Name) from jobs  where Job_Name = @mode   or  try_cast(Job_id as nvarchar(100))= @mode		 

)=1
begin
select @job_id = job_id , @job_id_hexstr = job_id_hexstr, @job_name = Job_Name
from jobs where Job_Name = @mode		  or try_cast(Job_id as nvarchar(100))= @mode

print('ok')
print(@job_id)
print(@job_id_hexstr)
print(@job_name)


end
else 
begin
		if (select count(distinct Job_Name) from jobs  where Job_Name like '%'+@mode+'%'  )=0
		 begin
		print('Джоб не найден')

		 select * from #t2
		 where login_name =@mode
  order by 2
  
--where blocking_session_id is not null
  select * from #t2
		 where login_name =@mode
  --order by 2
  order by [session_id]
			 end


		else
		begin
		select distinct Job_Name from jobs  where Job_Name like '%'+@mode+'%' order by 1
		select distinct Job_Name, command from jobs  where command like '%'+@mode+'%' order by 1

		end
return
end





drop table if exists [#query_log_view]
select  * into [#query_log_view] from query_log_view
where log_datetime>cast(getdate()-@days  as date)


;

with v as(
 
    select
       a.[log_datetime]
      ,a.[dd hh:mm:ss.mss]
	  ,j.job_step_name
      ,a.[session_id] 
      ,a.[sql_text]
      ,a.[blocking_session_id]
      ,a.[sql_command]
      ,a.[status]
      ,a.[login_name]
      ,a.[wait_info]
      ,a.[database_name]
      ,a.[host_name]
      ,a.[percent_complete]
      ,a.[program_name]
      ,a.[additional_info] 
      ,a.job_id_hexstr 
  
	  from [#query_log_view] a 
	  left join #_v_sysjobs j on j.job_id_hexstr=a.job_id_hexstr and a.step_id=j.step_id

	  )

select b.job_step_name blocking_job_step_name , b.sql_command, b.blocking_session_id,a.log_datetime, a.[dd hh:mm:ss.mss], a.session_id, a.sql_text, a.sql_command, a.status, a.program_name,a.wait_info from v a
left join v b on a.log_datetime=b.log_datetime and b.session_id=a.blocking_session_id
where a.job_id_hexstr  =@job_id_hexstr --and a.program_name  like '%step 1%' 
union
select null, null, null, Run_DateAndTime, '', null, 'start '+ command, command, null, Job_Name, null from jobh where job_id=@job_id and Run_DateAndTime>cast(getdate()-@days  as date)
union
select null, null, null, dateadd(second, 1, Finish_DateAndTime), '', null, Run_Status+' '+ command, case when is_Succeeded=0 then  cast(message as nvarchar(max)) else '' end , Run_Status, Job_Name , null from jobh where job_id=@job_id and   Run_DateAndTime>cast(getdate()-@days  as date)
union
select null, null, null, getdate(),                              '', null, 'Running '+ command    , ''                          , null       , Job_Name , null from [v_Запущенные джобы] where job_id=@job_id
order by 4





return



--*/
----------------------------------------------------------
----------------------------------------------------------
/*

drop table if exists #t1
select  * into #t1 from [история запросов]
where log_datetime>getdate()-1


select b.sql_command, b.blocking_session_id,a.* from #t1 a
left join #t1 b on a.log_datetime=b.log_datetime and b.session_id=a.blocking_session_id
where a.program_name  like '%0x87a9dbd92b266b4a8095dfa5bb2580d9%' -- '%REPORTS. ETL Docredy to Naumen Work days%'
or a.program_name  like '%0x7324ddf2a8fcc74eb09599a44d9ff2c4%' -- '%ETL. Docredy Work days%'
or a.program_name  like '%0x404533b40293a44a8a9c74e4c35fba54%' -- '%Etl. Load Docredy and povt2Loginom%'
--where a.program_name  like '%________%' -- '%________%' select  master.dbo.fn_VarbinToHexStr(Job_ID) from _v_sysjobs where Job_Name like '%REPORTS. ETL Docredy to Naumen Work days%'
order by a.log_datetime
--select Job_Name, master.dbo.fn_VarbinToHexStr(Job_ID) from _v_sysjobs where Job_Name like '%Doc%'
--where Job_Name like '%ETL. Docredy Work days%'----0x7324ddf2a8fcc74eb09599a44d9ff2c4

*/
----------------------------------------------------------



  --where sql_command like '%v_leads%' or sql_text like '%v_leads%' 
  --order by 2
  end
