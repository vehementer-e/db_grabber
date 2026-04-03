-- exec [etl].[GetMarketProposal_docredy_pts_RMQ_JSON] @isDebug=1
CREATE PROC [etl].[GetMarketProposal_docredy_pts_RMQ_JSON]
	@env nvarchar(255) = 'uat'
	,@CMRClientGUIDs  nvarchar(max) = null
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
	set @isSendAll = 1
END
if  cast(getdate() as date ) in ('2024-10-17', '2025-03-19')
	set  @isSendAll = 1
DECLARE @type nvarchar(255) = 'marketProposals', @marketProposals etl.utt_marketProposal
declare @today  date =getdate()
declare @dtTo date =  dateadd(dd,-1,@today)
declare @dtFrom date  =dateadd(dd,-1,  @dtTo)
if not exists(select top(1) 1 from  marketing.docredy_pts
where cdate = @dtTo)
begin
	set    @dtFrom = dateadd(dd,-6,@dtTo) 
end

if @env in('uat', 'hf')
begin
	insert into @marketProposals
		(
			id
			,[sum]
			,rate_mp
			,passportNotValid
			,lastName
			,firstName
			,middleName
			,CRMClientGUID
			,cmrContractGUID
			,mobilePhone
			,marketProposalCategorieId
			,marketProposalTypeId
			,car_id
			,car_description
			,car_vin
			,car_year
			,car_gosNumber
			,car_ptsBrand_id
			,car_ptsBrand
			,car_ptsModel_id
			,car_ptsModel
			,car_ptsSeries
			,car_ptsNumber
			,market_proposal_message_guid
			,lead_Id
			,productTypeId
			,[isActive]
		)
		select top(25)
			 id = M.marketProposal_ID --M.CRMClientGUID
			,[sum] = M.main_limit
			,rate_mp = M.[Ставка %]
			,M.passportNotValid
			,lastName = M.last_name
			,firstName = M.first_name
			,middleName  = M.patronymic
			,M.CRMClientGUID
			,cmrContractGUID = M.RequestGUID
			,mobilePhone = M.phone
			,marketProposalCategorieId = M.market_proposal_category_id
			,marketProposalTypeId = M.market_proposal_type_id
			,car_id = M.ТранспортноеСредствоGuid
			,car_description = M.ТранспортноеСредствоНаименование
			,car_vin = M.vin
			,car_year = M.ТранспортноеСредствоГод
			,car_gosNumber = M.РегистрационныйНомер

			,car_ptsBrand_id = M.МаркаGuid
			,car_ptsBrand = M.МаркаПТС

			,car_ptsModel_id = M.МодельGuid
			,car_ptsModel = M.МодельПТС

			,car_ptsSeries = M.СерияПТС
			,car_ptsNumber = M.НомерПТС
			,market_proposal_message_guid = newid()
			,lead_Id
			,productTypeId	 = m.product_type_id
			,[isActive] = 1
		--SELECT *
		from marketing.docredy_pts_uat AS M
		where 1=1
		
			--AND M.market_proposal_category_name NOT IN ('Красный') -- M.category NOT IN ('Красный')
			--AND M.cdate =cast(getdate() as date)
		--	and M.phoneInBlackList = 0 #по согласованию с Кузиной Ю.В
		--	and (M.CRMClientGUID =  @CMRClientGUID or @CMRClientGUID is null)
			--and M.market_proposal_message_guid is null
			and  M.ТранспортноеСредствоGuid is not null
	/*
	union all
		select top(10)
			 id = M.marketProposal_ID --M.CRMClientGUID
			,[sum] = M.main_limit
			,rate_mp = M.[Ставка %]
			,M.passportNotValid
			,lastName = M.last_name
			,firstName = M.first_name
			,middleName  = M.patronymic
			,M.CRMClientGUID
			,cmrContractGUID = M.RequestGUID
			,mobilePhone = M.phone
			,marketProposalCategorieId = M.market_proposal_category_id
			,marketProposalTypeId = M.market_proposal_type_id
			,car_id = M.ТранспортноеСредствоGuid
			,car_description = M.ТранспортноеСредствоНаименование
			,car_vin = M.vin
			,car_year = M.ТранспортноеСредствоГод
			,car_gosNumber = M.РегистрационныйНомер

			,car_ptsBrand_id = M.МаркаGuid
			,car_ptsBrand = M.МаркаПТС

			,car_ptsModel_id = M.МодельGuid
			,car_ptsModel = M.МодельПТС

			,car_ptsSeries = M.СерияПТС
			,car_ptsNumber = M.НомерПТС
			,market_proposal_message_guid = newid()
			,lead_Id
			,productTypeId	 = m.product_type_id
		--SELECT TOP 100 *
		from marketing.docredy_pts_uat AS M
		where 1=1
		
			AND M.market_proposal_category_name IN ('Красный') -- M.category NOT IN ('Красный')
			--AND M.cdate =cast(getdate() as date)
		--	and M.phoneInBlackList = 0 #по согласованию с Кузиной Ю.В
			and (M.CRMClientGUID =  @CMRClientGUID or @CMRClientGUID is null)
			and M.market_proposal_message_guid is null
			and  M.ТранспортноеСредствоGuid is not null
			*/
end	
if @env = 'prod'
begin
		drop table if exists #t_prev_mp
		SELECT 	distinct marketProposal_ID, row_hash
		into #t_prev_mp
		FROM marketing.docredy_pts AS P
					WHERE P.cdate between @dtFrom  and @dtTo
		create clustered index  cix on #t_prev_mp(marketProposal_ID,row_hash)			


	insert into @marketProposals
		(
			id
			,[sum]
			,rate_mp
			,passportNotValid
			,lastName
			,firstName
			,middleName
			,CRMClientGUID
			,cmrContractGUID
			,mobilePhone
			,marketProposalCategorieId
			,marketProposalTypeId
			,car_id
			,car_description
			,car_vin
			,car_year
			,car_gosNumber
			,car_ptsBrand_id
			,car_ptsBrand
			,car_ptsModel_id
			,car_ptsModel
			,car_ptsSeries
			,car_ptsNumber
			,market_proposal_message_guid
			,lead_Id
			,productTypeId
			,[isActive]
			,row_hash
		)
	select 
			id
			,[sum]
			,rate_mp
			,passportNotValid
			,lastName
			,firstName
			,middleName
			,CRMClientGUID
			,cmrContractGUID
			,mobilePhone
			,marketProposalCategorieId
			,marketProposalTypeId
			,car_id
			,car_description
			,car_vin
			,car_year
			,car_gosNumber
			,car_ptsBrand_id
			,car_ptsBrand
			,car_ptsModel_id
			,car_ptsModel
			,car_ptsSeries
			,car_ptsNumber
			,market_proposal_message_guid
			,lead_Id
			,productTypeId
			,[isActive] = 1
			,row_hash
	from (
		select 
			 id = M.marketProposal_ID --M.CRMClientGUID
			,[sum] = M.main_limit
			,rate_mp = M.[Ставка %]
			,M.passportNotValid
			,lastName = M.last_name
			,firstName = M.first_name
			,middleName  = M.patronymic
			,M.CRMClientGUID
			,cmrContractGUID = M.RequestGUID
			,mobilePhone = M.phone
			,marketProposalCategorieId = M.market_proposal_category_id
			,marketProposalTypeId = M.market_proposal_type_id
			,car_id = M.ТранспортноеСредствоGuid
			,car_description = M.ТранспортноеСредствоНаименование
			,car_vin = M.vin
			,car_year = M.ТранспортноеСредствоГод
			,car_gosNumber = M.РегистрационныйНомер

			,car_ptsBrand_id = M.МаркаGuid
			,car_ptsBrand = M.МаркаПТС

			,car_ptsModel_id = M.МодельGuid
			,car_ptsModel = M.МодельПТС

			,car_ptsSeries = M.СерияПТС
			,car_ptsNumber = M.НомерПТС
			,market_proposal_message_guid = newid()
			,M.lead_Id
			,productTypeId = M.product_type_id
			,M.row_hash
			,nRow = ROW_NUMBER() over(partition by M.marketProposal_ID order by M.main_limit desc)
		--SELECT TOP 100 *
		from marketing.docredy_pts AS M
		where 1=1
			--DWH-2755
			AND (
				exists (
					select 1 
					from 
						etl.marketing_povt_pts_to_send to_send 
					where 
						to_send.marketProposal_ID = M.marketProposal_ID
				)
				--or
				--@isSendAll = 1
				OR
				NOT EXISTS(
					SELECT TOP(1) 1
					FROM #t_prev_mp p
					WHERE P.marketProposal_ID = M.marketProposal_ID
						AND P.row_hash = M.row_hash
				)
			)
		
			--AND M.market_proposal_category_name NOT IN ('Красный') -- M.category NOT IN ('Красный')
			AND M.cdate =@today
		--	and M.phoneInBlackList = 0 #по согласованию с Кузиной Ю.В
		--	and (M.CRMClientGUID =  @CMRClientGUID or @CMRClientGUID is null)
			and M.market_proposal_message_guid is null
			and  M.ТранспортноеСредствоGuid is not null
			) t
			where nRow = 1


END



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
			from marketing.docredy_pts_uat AS t
				inner join #t_data2rmq AS s
					ON s.CRMClientGUID = t.CRMClientGUID
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
			from marketing.docredy_pts AS t
				inner join #t_data2rmq AS s
					ON s.CRMClientGUID = t.CRMClientGUID
					and s.Id= t.marketProposal_ID
			where t.cdate = @today
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
