/*
﻿--[etl].[GetMarketProposal_push_pov_pdl_JSON] 'prod'
*/
CREATE      procedure  [etl].[GetMarketProposal_push_povtPdl_JSON]
	@env  nvarchar(255)= 'prod',
	@CMRClientGUID nvarchar(36) = null
	WITH EXECUTE AS OWNER
as

begin
	set nocount on;

begin try
	set @CMRClientGUID = nullif(@CMRClientGUID,'')
	drop table if exists #data2rmq
	select top(0)
		pushProfile2Send,
		approved_limit,
		phone,
		push_communicationId,
		[marketProposal_ID]
	into #data2rmq
	from marketing.povt_pdl


if @env = 'prod'
begin
	insert into #data2rmq(
		pushProfile2Send
		, approved_limit
		, phone
		, push_communicationId
		, [marketProposal_ID])

	select pushProfile2Send
		, approved_limit
		, phone
		, push_communicationId = newid()
		, [marketProposal_ID]
	from marketing.povt_pdl t
	where t.phoneInBlackList = 0
		and t.date2SendPush =  cast(getdate() as date)
		and t.cdate = cast(getdate() as date)
		and (t.CMRClientGUID = @CMRClientGUID or @CMRClientGUID is null)
		and phone is not null
		and push_communicationId is null
end
else
begin
	declare @rowCount int = 12
	insert into #data2rmq(pushProfile2Send, approved_limit,phone,  push_communicationId, [marketProposal_ID])
	select 
	pushProfile2Send = case nRow
				when 1 then 'PUSH_ID_0_DAY_3449'
				when 2 then 'PUSH_ID_1_DAY_3449'
				when 3 then 'PUSH_ID_2_DAY_3449'
				when 4 then 'PUSH_ID_5_DAY_3449'
				when 5 then 'PUSH_ID_8_DAY_3449'
				when 6 then 'PUSH_ID_11_DAY_3449'
				when 7 then 'PUSH_ID_NEW_RE-LOAN_3270'
				when 8 then 'PUSH_ID_REFUSAL_CLIENT_RE-LOAN_3270'
				when 9 then 'PUSH_ID_NO_ANSWER_3270'
				when 10 then 'PUSH_ID_APPLICATION_PROCESSING_3270'
				when 11 then 'PUSH_ID_REFUSED_3270'
				when 12 then 'PUSH_ID_SPECIAL_OFFER_3270'
			
				else  t.pushProfile2Send
				end
	,t.approved_limit  
	,t.phone
	,push_communicationId = newid()
	,[marketProposal_ID]
	from (
		select  top(@rowCount)
		t.pushProfile2Send,
		t.approved_limit,
		t.phone,
		external_id,
		[marketProposal_ID],
		nRow = ROW_NUMBER() over(order by getdate())
		
		from marketing.povt_pdl_uat t
		where cdate = cast(getdate() as date)
		and t.phoneInBlackList = 0
		and (t.CMRClientGUID = @CMRClientGUID or @CMRClientGUID is null)
		--and povt_pdl.date2SendPush =  cast(getdate() as date)
		and phone is not null
		and t.push_communicationId is null
		order by t.external_id desc
	) t
	
end

begin
	declare @params [etl].[utt_ComcMessageParams]
	insert into @params([communicationId], [name], [value])
	select push_communicationId
		,'key'
		,phone
	from #data2rmq; 
	insert into @params([communicationId], [name], [value])
	select push_communicationId
		,'name'
		,phone
	from #data2rmq;
	--fix: 9:30
	declare @timeStart datetime = '9:30'
	declare @today date = getdate()
	declare @planned_at datetime = (cast(@today as datetime) + cast(@timeStart as datetime))
	insert into @params([communicationId], [name], [value])
	SELECT push_communicationId
		, 'plannedAt'
		, format(@planned_at, 'yyyy-MM-dd hh:mm:ss')
	FROM #data2rmq;
	
	select p.json
	from #data2rmq t
	outer apply (
		select json =  etl.GetComcMessage_Json(t.pushProfile2Send, t.push_communicationId, @params)
		) p
end

if exists(select top(1) 1 from #data2rmq)
begin
	if @env = 'uat'
	begin 
		begin tran
			update t
				set t.push_communicationId = s.push_communicationId
			from marketing.povt_pdl_uat t
				inner join #data2rmq s on s.[marketProposal_ID] = t.[marketProposal_ID]
			where t.cdate = cast(getdate() as date)
		commit tran
	end 
	if @env = 'prod'
	begin 
		begin tran
			update t
				set  push_communicationId = s.push_communicationId
			from [marketing].[povt_pdl] t
				inner join #data2rmq s on s.[marketProposal_ID] = t.[marketProposal_ID]
			where t.cdate =cast(getdate() as date)
		commit tran
	end
end

end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	
	;throw
end catch
end