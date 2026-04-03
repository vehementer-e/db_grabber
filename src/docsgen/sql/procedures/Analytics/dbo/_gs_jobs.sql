CREATE proc [dbo].[_gs_jobs] as   
--declare @res    varchar(max) =   ''
--exec python 'result = gs2df( gs_id = "1u5xOTXiR1Br2wmVhqCePxmSC_lhZafmcpLCGQN1x6tQ", range = "джобы!K1:2").iloc[0,0]', 1, @res output
--select @res
--if @res='"stop"' return
--if @res='"run"'   
--exec python 'result = gs2df( gs_id = "1u5xOTXiR1Br2wmVhqCePxmSC_lhZafmcpLCGQN1x6tQ", range = "changes!D1:2").iloc[0,0]', 1, @res output
----select @res


exec python 'sql2gs(sql= """
select job_id id, replace(job_name, '''''''', '''''''''''' )  job_name ,replace(job_name, '''''''', '''''''''''' )   job_name_to_be, step_id,step_id step_id_to_be
, job_enabled , job_enabled job_enabled_to_be	
, replace(command, '''''''', '''''''''''' )  command  , replace(command, '''''''', '''''''''''' )   command_to_be, getdate() created
from jobs
where owner_sid = 0x0105000000000005150000005C4CFCF833317E29EC2F9A25903E0000
order by job_name, step_id

""", gs_id = "1u5xOTXiR1Br2wmVhqCePxmSC_lhZafmcpLCGQN1x6tQ", sheet_name = "джобы")', 1

