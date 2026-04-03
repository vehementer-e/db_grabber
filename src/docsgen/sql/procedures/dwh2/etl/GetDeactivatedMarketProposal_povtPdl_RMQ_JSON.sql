
/*
EXEC etl.[GetDeactivatedMarketProposal_povtPdl_RMQ_JSON]
	@env = 'prod',
	@CMRClientGUID = '544AB041-08FE-11E8-A814-00155D941900'

EXEC etl.[GetDeactivatedMarketProposal_povtPdl_RMQ_JSON]
	@env = 'hf',
	@CMRClientGUID = '54C95706-30D4-11E8-814E-00155D01BF07'
*/
-- =======================================================
-- Create: 
-- Description:	DWH-2604 Реализовать процедуру для формирование пакета по Деактивации Маркетинговым предложениям
-- =======================================================
CREATE        PROC [etl].[GetDeactivatedMarketProposal_povtPdl_RMQ_JSON]
	@env nvarchar(255) = 'uat',
	@day smallint  = 5
	WITH EXECUTE AS OWNER
as
begin
set nocount on;
begin try
declare
	@CMRClientGUID nvarchar(36) = null
	,@today date =getdate() 
	set @CMRClientGUID = nullif(@CMRClientGUID,'')

	declare @type nvarchar(255) = 'marketProposals'

	
	declare @marketProposals etl.utt_marketProposal

if @env in('uat', 'hf')
begin
	insert into @marketProposals
		(
			id
			,marketProposalTypeId
			,market_proposal_message_guid
			,[isActive]
		)
		select 
			 id = M.marketProposal_ID --M.CRMClientGUID
			,marketProposalTypeId = M.market_proposal_type_id
			,market_proposal_message_guid = newid()
			,[isActive] = 0
		--SELECT *
		from marketing.povt_pdl_uat AS M
		where 1=1
		
			
end	
if @env = 'prod'
begin
	insert into @marketProposals
		(
			id
			,marketProposalTypeId
			,market_proposal_message_guid
			,[isActive]
		)
	select 
			id
			,marketProposalTypeId
			,market_proposal_message_guid = NEWID()
			,[isActive] = 0
	from (
		select 
			id
			,marketProposalTypeId
			,nRow = ROW_NUMBER() Over(partition by Id order by getdate())
			from (
				select 
					 id = M.marketProposal_ID 
					,marketProposalTypeId = M.market_proposal_type_id
				from marketing.povt_pdl AS M
				where 1=1
				and cdate between DATEADD(dd, -@day, @today) and @today
			--	and market_proposal_message_guid is not null
				except
				select 
					id = M.marketProposal_ID 
					,marketProposalTypeId = M.market_proposal_type_id
				from marketing.povt_pdl AS M
				where 1=1
				and cdate = @today
				--and market_proposal_message_guid is not null
			
			) t
		) t
		where nRow =1 
		
end
	drop table if exists #t_data2rmq
	select 
		 Id
		,market_proposal_message_guid
		,json
	into #t_data2rmq
	from etl.tvf_DeactivatedGetMarketProposal_JSON
	(
		@marketProposals
		,@type
	)

	select
		json
	from #t_data2rmq
	/*
if @env = 'uat'
begin
	begin tran
		update t
		set market_proposal_message_guid = s.market_proposal_message_guid
			,market_proposal_message_send_date = getdate()
		from marketing.docredy_pts_uat AS t
			inner join #t_data2rmq AS s
				ON s.CRMClientGUID = t.CRMClientGUID
				and s.Id= t.marketProposal_ID
		where t.cdate =cast(getdate() as date)
	commit tran
end
if @env = 'prod'
begin
	begin tran
		update t
		set market_proposal_message_guid = s.market_proposal_message_guid
			,market_proposal_message_send_date = getdate()
		from marketing.docredy_pts AS t
			inner join #t_data2rmq AS s
				ON s.CRMClientGUID = t.CRMClientGUID
				and s.Id= t.marketProposal_ID
		where t.cdate =cast(getdate() as date)
	commit tran
end
	*/


end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end
