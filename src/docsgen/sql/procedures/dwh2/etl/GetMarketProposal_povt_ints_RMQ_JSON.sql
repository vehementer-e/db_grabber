-- exec [etl].[GetMarketProposal_povt_ints_RMQ_JSON]
CREATE PROC [etl].[GetMarketProposal_povt_ints_RMQ_JSON]
	@env nvarchar(255) = 'uat',
	@CMRClientGUID nvarchar(36) = null,
	@CMRClientGUIDs nvarchar(max) = null
	,@isDebug bit = 0
	WITH EXECUTE AS OWNER
as
begin
set nocount on;
begin try
	
	SELECT @isDebug = isnull(@isDebug, 0)
	DECLARE @isSendAll bit = 0

	-- полная отправка один раз в месяц, по 1-м числам
	IF datepart(DAY,getdate()) = 1 
		or cast(getdate() as date ) in('2024-10-17', '2025-04-04', '2025-04-03')
	BEGIN
		set @isSendAll = 1
	END

	declare @today  date =getdate()
	declare @dtTo date =  dateadd(dd,-1,@today)
	declare @dtFrom date  =dateadd(dd,-1,  @dtTo)
	if not exists(select top(1) 1 from  marketing.povt_inst
	where cdate = @dtTo)
	begin
		set    @dtFrom = dateadd(dd,-6,@dtTo) 
	end

	set @CMRClientGUID = nullif(@CMRClientGUID,'')
	set @CMRClientGUIDs  = nullif(CONCAT_WS(',', @CMRClientGUID, @CMRClientGUIDs),'')
	declare @type nvarchar(255) = 'marketProposals'

	
	declare @marketProposals etl.utt_marketProposal
	declare @batchSize tinyint = 100
		
if @env = 'uat'
begin
	set @batchSize = 1
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
		select 
			top(@batchSize)	 percent
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
		from (
		select 
			 id							= M.marketProposal_ID --M.CRMClientGUID
			,[sum]						= M.approved_limit
			,M.passportNotValid
			,lastName					= M.last_name
			,firstName					= M.first_name
			,middleName					= M.patronymic
			,CRMClientGUID				= M.CMRClientGUID
			
			,mobilePhone				= M.phone
			,marketProposalCategorieId	= M.market_proposal_category_id
			,marketProposalTypeId		= M.market_proposal_type_id
			
			,market_proposal_message_guid = newid()
			,lead_Id
			,productTypeId	= m.product_type_id
			,nRow			= ROW_NUMBER() over (partition by m.CMRClientGUID order by cdate)
		--SELECT TOP 100 *
		from marketing.povt_inst_uat AS M
		where 1=1
		
			--AND M.market_proposal_category_name NOT IN ('Красный') -- M.category NOT IN ('Красный')
			--AND M.cdate =cast(getdate() as date)
		--	and M.phoneInBlackList = 0 #по согласованию с Кузиной Ю.В
			and (CMRClientGUID in (select trim(value) from string_split(@CMRClientGUIDs, ','))
				or @CMRClientGUIDs is null)
			and M.market_proposal_message_guid is null
			
			) t
			where nRow = 1
end	

if @env = 'prod'
begin
	
	  SELECT  distinct 
		marketProposal_ID
		,row_hash
		
		into #t_povt_inst_prev 
	FROM marketing.povt_inst AS P
		WHERE P.cdate between @dtFrom and @dtTo

	create clustered index cix on #t_povt_inst_prev(marketProposal_ID,row_hash) 			
	

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
		select 	  top(100)	percent
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
			,productTypeId	 = M.product_type_id
			,M.row_hash
		--SELECT TOP 100 *
		from marketing.povt_inst AS M
		where 1=1
			--DWH-2755
			AND (
				--@isSendAll = 1
				--OR
				exists (
					select 1 
					from 
						etl.marketing_povt_inst_to_send to_send 
					where 
						to_send.marketProposal_ID = M.marketProposal_ID
				)
				or
				NOT EXISTS(
					SELECT TOP(1) 1
					FROM #t_povt_inst_prev AS P
					WHERE P.marketProposal_ID = M.marketProposal_ID
						AND P.row_hash = M.row_hash
				)
			)
		
			--AND M.market_proposal_category_name NOT IN ('Красный') -- M.category NOT IN ('Красный')
			AND M.cdate =@today
		--	and M.phoneInBlackList = 0 #по согласованию с Кузиной Ю.В
			--and (M.CMRClientGUID in (select trim(value) from string_split(@CMRClientGUIDs, ','))
			--	or @CMRClientGUIDs is null)
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
			from marketing.povt_inst_uat AS t
				inner join #t_data2rmq AS s
					ON s.CRMClientGUID = t.CMRClientGUID
					and s.Id= t.marketProposal_ID
			where t.cdate =@today
		commit tran
	end
	if @env = 'prod'
	begin
		begin tran
			update t
			set market_proposal_message_guid = s.market_proposal_message_guid
				,market_proposal_message_send_date = getdate()
			from marketing.povt_inst AS t
				inner join #t_data2rmq AS s
					ON s.CRMClientGUID = t.CMRClientGUID
					and s.Id= t.marketProposal_ID
			where t.cdate =@today
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
