/*
﻿--[etl].[GetMarketProposal_push_docredy_pts_JSON] 'uat'
*/
CREATE     procedure  [etl].[GetMarketProposal_push_docredy_pts_JSON]
	@env  nvarchar(255)= 'uat',
	@CMRClientGUID nvarchar(36) = null,
	@CMRClientGUIDs nvarchar(max) = null
	WITH EXECUTE AS OWNER
as

begin
	set nocount on;

begin try
	
	set @CMRClientGUIDs =  nullif(CONCAT_WS(',', @CMRClientGUID, @CMRClientGUIDs), '')

	drop table if exists #data2rmq
	select top(0)
		pushProfile2Send,
		main_limit,
		phone,
		push_communicationId,
		CRMClientGUID
	into #data2rmq
	from marketing.docredy_pts


if @env = 'prod'
begin
	insert into #data2rmq(
		pushProfile2Send
		, main_limit
		, phone
		, push_communicationId
		, CRMClientGUID)

	select pushProfile2Send
		, main_limit
		, phone
		, push_communicationId = newid()
		, CRMClientGUID
	from marketing.docredy_pts t
	where t.phoneInBlackList = 0
		and t.cdate = cast(getdate() as date)
		and (t.CRMClientGUID in (select trim(value) from string_split(@CMRClientGUIDs, ','))
			or @CMRClientGUIDs is null)
		and phone is not null
		and pushProfile2Send is not null
		and push_communicationId is null
end
else
begin
	declare @rowCount int = 3
	insert into #data2rmq(pushProfile2Send, main_limit,phone,  push_communicationId, CRMClientGUID)
	select 
	pushProfile2Send = case nRow
				when 1 then 'PUSH_ID_1343_ADDITIONAL_5'
				when 2 then 'PUSH_ID_1343_ADDITIONAL_4'
				when 3 then 'PUSH_ID_1343_ADDITIONAL_2'
				else  t.pushProfile2Send
				end
	,t.main_limit  
	,t.phone
	,push_communicationId = newid()
	,CRMClientGUID
	from (
		select  top(@rowCount)
		t.pushProfile2Send,
		t.main_limit,
		t.phone,
		external_id,
		CRMClientGUID,
		nRow = ROW_NUMBER() over(order by getdate())
		
		from marketing.docredy_pts_uat t
		where cdate = cast(getdate() as date)
		and (t.CRMClientGUID in (select trim(value) from string_split(@CMRClientGUIDs, ','))
			or @CMRClientGUIDs is null)
		--and docredy_pts.date2SendPush =  cast(getdate() as date)
		and phone is not null
		and t.push_communicationId is null
		and t.main_limit>0
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
	--fix da
	declare @timeStart time = '8:30'
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
			from marketing.docredy_pts_uat t
				inner join #data2rmq s on s.CRMClientGUID = t.CRMClientGUID
			where t.cdate = cast(getdate() as date)
		commit tran
	end 
	if @env = 'prod'
	begin 
		begin tran
			update t
				set  push_communicationId = s.push_communicationId
			from [marketing].[docredy_pts] t
				inner join #data2rmq s on s.CRMClientGUID = t.CRMClientGUID
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