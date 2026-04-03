-- exec [etl].[GetMarketProposal_povt_pdl_RMQ_JSON] @isDebug=1
CREATE PROC [etl].[GetMarketProposal_povt_pdl_RMQ_JSON]
	@env nvarchar(255) = 'uat'
	,@CMRClientGUIDs nvarchar(max) = null
	,@isDebug bit = 0
WITH EXECUTE AS OWNER
as
begin
set nocount on;
begin try

SELECT @isDebug = isnull(@isDebug, 0)
DECLARE @isSendAll bit = 0

-- полная отправка один раз в месяц, по 1-м числам
IF datepart(DAY,getdate()) = 1 BEGIN
	SELECT @isSendAll = 1
END
if  cast(getdate() as date ) ='2024-10-17'
	set  @isSendAll = 1
DECLARE
	@CMRClientGUID nvarchar(36) = null
	set @CMRClientGUID = nullif(@CMRClientGUID,'')

	declare @type nvarchar(255) = 'marketProposals'

	declare  @dayStart date =  dateadd(DAY, -5, cast(getdate() as date))
	declare  @dayEnd date = dateadd(DAY, -1, cast(getdate() as date))
	
	declare @marketProposals etl.utt_marketProposal

if @env = 'uat'
begin
	insert into @marketProposals
		(
			id
			,[sum]
			,passportNotValid
			,lastName
			,firstName
			,middleName
			,CRMClientGUID
			,mobilePhone
			,marketProposalCategorieId
			,marketProposalTypeId
			,market_proposal_message_guid
			,lead_Id
			,productTypeId
		)
		select top(25)
			 id				= M.marketProposal_ID --M.CRMClientGUID
			,[sum]			= M.approved_limit
			,M.passportNotValid
			,lastName		= M.last_name
			,firstName		= M.first_name
			,middleName		= M.patronymic
			,CRMClientGUID	= M.CMRClientGUID
			
			,mobilePhone = M.phone
			,marketProposalCategorieId = M.market_proposal_category_id
			,marketProposalTypeId = M.market_proposal_type_id
			
			,market_proposal_message_guid = newid()
			,lead_Id
			,productTypeId	 = m.product_type_id
		--SELECT TOP 100 *
		from marketing.povt_pdl_uat AS M
		where 1=1
		
			--AND M.market_proposal_category_name NOT IN ('Красный') -- M.category NOT IN ('Красный')
			--AND M.cdate =cast(getdate() as date)
		--	and M.phoneInBlackList = 0 #по согласованию с Кузиной Ю.В
			and (M.CMRClientGUID =  @CMRClientGUID or @CMRClientGUID is null)
			and M.market_proposal_message_guid is null
			

end	
if @env = 'prod'
begin
	insert into @marketProposals
		(
			id
			,[sum]
			,passportNotValid
			,lastName
			,firstName
			,middleName
			,CRMClientGUID
			,mobilePhone
			,marketProposalCategorieId
			,marketProposalTypeId
			,market_proposal_message_guid
			,lead_Id
			,productTypeId
			,row_hash
		)
		select 
			 id				= M.marketProposal_ID --M.CRMClientGUID
			,[sum]			= M.approved_limit
			,M.passportNotValid
			,lastName		= M.last_name
			,firstName		= M.first_name
			,middleName		= M.patronymic
			,CRMClientGUID	= M.CMRClientGUID
			
			,mobilePhone = M.phone
			,marketProposalCategorieId = M.market_proposal_category_id
			,marketProposalTypeId = M.market_proposal_type_id
			
			,market_proposal_message_guid = newid()
			,M.lead_Id
			,productTypeId = M.product_type_id
			,M.row_hash
		--SELECT TOP 100 *
		from marketing.povt_pdl AS M
		where 1=1
			--DWH-2755
			AND (
				--@isSendAll = 1
				--OR
				exists (
					select 1 
					from 
						etl.marketing_povt_pdl_to_send to_send 
					where 
						to_send.marketProposal_ID = M.marketProposal_ID
				)
				or
				NOT EXISTS(
					SELECT TOP(1) 1
					FROM marketing.povt_pdl AS P
					WHERE P.marketProposal_ID = M.marketProposal_ID
						AND P.cdate between @dayStart and @dayEnd
						AND P.row_hash = M.row_hash
				)
			)
		
			--AND M.market_proposal_category_name NOT IN ('Красный') -- M.category NOT IN ('Красный')
			AND M.cdate =cast(getdate() as date)
		--	and M.phoneInBlackList = 0 #по согласованию с Кузиной Ю.В
			and (M.CMRClientGUID =  @CMRClientGUID or @CMRClientGUID is null)
			and M.market_proposal_message_guid is null
		
end
	drop table if exists #t_data2rmq
	select 
		 Id
		,market_proposal_message_guid
		,CRMClientGUID
		,json
	into #t_data2rmq
	from etl.tvf_GetMarketProposal_JSON
	(
		@marketProposals
		,@type
	)

	select
		json
	from #t_data2rmq

IF @isDebug = 0 BEGIN
	if @env = 'uat'
	begin
		begin tran
			update t
			set market_proposal_message_guid = s.market_proposal_message_guid
				,market_proposal_message_send_date = getdate()
			from marketing.povt_pdl_uat AS t
				inner join #t_data2rmq AS s
					ON s.CRMClientGUID = t.CMRClientGUID
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
			from marketing.povt_pdl AS t
				inner join #t_data2rmq AS s
					ON s.CRMClientGUID = t.CMRClientGUID
					and s.Id= t.marketProposal_ID
			where t.cdate =cast(getdate() as date)
		commit tran
	end
END
--//IF @isDebug = 0



end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end
