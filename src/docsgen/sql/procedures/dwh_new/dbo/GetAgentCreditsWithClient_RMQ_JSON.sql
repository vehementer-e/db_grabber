CREATE procedure [dbo].[GetAgentCreditsWithClient_RMQ_JSON]
as

begin
set nocount on;
	drop table if exists #t
	select distinct 
		 ac.crmClientGuid	
		,ac.external_id	
		,ac.stDate	
		,ac.endDate	
		,ac.agentName	
		,ac.agentFullName	
		,ac.agentPhone	
		,ac.agentContract
		,ac.DateDeal
	into #t
	from 
	(
		select 
			crmClientGuid,
			external_id,
			max(stDate) as last_stDate
		 from dbo.v_agent_credits_with_client
		 group by crmClientGuid, external_id
	) last
	inner join dbo.v_agent_credits_with_client ac 
		on ac.crmClientGuid = last.crmClientGuid
		and ac.external_id = last.external_id
		and ac.stDate = last.last_stDate
	
	
if exists (select top(1) 1 from #t)
begin
	


	select json = t_data /*REPLACE(REPLACE(t_data, '[{','{'),  '}]','}') as json*/
	from 
	(
	select 

	(
		select distinct
		/**/
			crmClientGuid = isnull(crmClientGuid, '00000000-0000-0000-0000-000000000000')
			,externalId = isnull(external_id, '')	
			,stDate = isnull(stDate,	'0001-01-01')
			,endDate = isnull(endDate,'0001-01-01')
			,agentName = isnull(agentName, '')
			,agentFullName = isnull(agentFullName, '')	
			,agentPhone = isnull(agentPhone, '')	
			,agentContract = isnull(agentContract, '')
			,agentDateContract = isnull(DateDeal, '0001-01-01')
		from #t d 
		where d.crmClientGuid = t.crmClientGuid
		FOR JSON AUTO
	)  t_data
	
	from (select distinct crmClientGuid from #t)	 t
	)	 t


	
end

end

