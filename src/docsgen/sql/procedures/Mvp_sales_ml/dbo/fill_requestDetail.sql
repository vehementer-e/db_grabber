CREATE   procedure [dbo].[fill_requestDetail]
	@monthAgo smallint = 3
	,@dayAfter smallint= 0
as
begin
begin try
	declare @lk_PTS_product smallint =1
	declare @lk_inst_product smallint = 2
	declare @lk_PDL_product smallint = 3
drop table if exists #lkRequestsDetail
	select 
		l.leadId
		,totalPtsRequests	= COUNT(distinct iif(r.product_types_id = 1, id, null)) --кол. заявок по птс
		,lastPtsRequestDate = max(iif(r.product_types_id = 1, r.created_at, null)) -- дата последней заявки по птс
		,totalWitOutDepositRequests = COUNT(iif(r.product_types_id in (2,3) or is_installment = 1, id, null))  --кол. заявок по без залогу
		,lastWitOutDepositDate = max(iif(r.product_types_id in (2,3) or is_installment = 1, r.created_at, null)) --дата последней заявки по без залогу
	into #lkRequestsDetail
	from [dbo].[dm_lead_ml] l
	inner join stg._LK.requests r on r.client_mobile_phone = l.leadPhone
		and r.created_at between DATEADD(mm,-@monthAgo, l.leadCreated_at_time) and dateadd(dd, @dayAfter, l.leadCreated_at_time)
	group by l.leadId
	option (recompile)	


	
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalPtsRequests') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add totalPtsRequests int
	END
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastPtsRequestDate') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add lastPtsRequestDate datetime
	END
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalWitOutDepositRequests') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add totalWitOutDepositRequests int
	END
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastWitOutDepositDate') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add lastWitOutDepositDate datetime
	END
	begin tran
		update t
			set totalPtsRequests			= rd.totalPtsRequests
				,lastPtsRequestDate			= rd.lastPtsRequestDate
				,totalWitOutDepositRequests = rd.totalWitOutDepositRequests
				,lastWitOutDepositDate		= rd.lastWitOutDepositDate
		from [dbo].[dm_lead_ml]  t
		left join #lkRequestsDetail rd on rd.leadId = t.leadId
	commit tran
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch

end