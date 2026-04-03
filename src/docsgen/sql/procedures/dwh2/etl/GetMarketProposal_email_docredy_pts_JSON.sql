/*
﻿--[etl].[GetMarketProposal_email_docredy_pts_JSON] 'uat'
*/
CREATE       procedure  [etl].[GetMarketProposal_email_docredy_pts_JSON]
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
		emailProfile2Send,
		main_limit,
		client_email,
		email_communicationId,
		marketProposal_ID,
		first_name
	into #data2rmq
	from marketing.docredy_pts


if @env = 'prod'
begin
	insert into #data2rmq(
		emailProfile2Send
		, main_limit
		, client_email
		, email_communicationId
		, marketProposal_ID
		, first_name)

	select emailProfile2Send
		, main_limit
		, client_email
		, email_communicationId = newid()
		, marketProposal_ID
		, t.first_name
	from marketing.docredy_pts t
	where t.phoneInBlackList = 0
		and t.cdate = cast(getdate() as date)
		and (t.CRMClientGUID in (select trim(value) from string_split(@CMRClientGUIDs, ','))
			or @CMRClientGUIDs is null)
		and client_email is not null
		and emailProfile2Send is not null
		and email_communicationId is null
end
else
begin
	declare @rowCount int = 3
	insert into #data2rmq(emailProfile2Send, main_limit,client_email,  email_communicationId, marketProposal_ID, first_name)
	select 
	emailProfile2Send = case nRow
				when 1 then 'EMAIL_ID_TAKE_MONEY_1343'
				when 2 then 'EMAIL_ID_NEW_LOAN_1343'
				when 3 then 'EMAIL_ID_NEW_LOAN_1343'
				else  t.emailProfile2Send
				end
	,t.main_limit  
	,t.client_email
	,email_communicationId = newid()
	,marketProposal_ID
	,first_name
	from (
		select  top(@rowCount)
		t.emailProfile2Send,
		t.main_limit,
		t.client_email,
		external_id,
		marketProposal_ID,
		first_name,
		nRow = ROW_NUMBER() over(order by getdate())
		
		from marketing.docredy_pts_uat t
		where cdate = cast(getdate() as date)
		and (t.CRMClientGUID in (select trim(value) from string_split(@CMRClientGUIDs, ','))
			or @CMRClientGUIDs is null)
		--and docredy_pts.date2Sendemail =  cast(getdate() as date)
		and client_email is not null
		and t.email_communicationId is null
		and t.main_limit>0
		order by t.external_id desc
	) t
	
end

begin
	declare @params [etl].[utt_ComcMessageParams]
	insert into @params([communicationId], [name], [value])
	select email_communicationId
		,'key'
		, client_email
	from #data2rmq; 
	insert into @params([communicationId], [name], [value])
	select email_communicationId
		,'name'
		,client_email
	from #data2rmq
	-- fix: 8:30
	declare @timeStart time = '8:30'
	declare @today date = getdate()
	declare @planned_at datetime = (cast(@today as datetime) + cast(@timeStart as datetime))
	insert into @params([communicationId], [name], [value])
	SELECT email_communicationId
		, 'plannedAt'
		, format(@planned_at, 'yyyy-MM-dd hh:mm:ss')
	FROM #data2rmq;
	
	select p.json		 
	from #data2rmq t
	outer apply (
		select json =  etl.GetComcMessage_Json(t.emailProfile2Send, t.email_communicationId, @params)
		) p
end

if exists(select top(1) 1 from #data2rmq)
begin
	if @env = 'uat'
	begin 
		begin tran
			update t
				set t.email_communicationId = s.email_communicationId
			from marketing.docredy_pts_uat t
				inner join #data2rmq s on s.marketProposal_ID = t.marketProposal_ID
			where t.cdate = cast(getdate() as date)
		commit tran
	end 
	if @env = 'prod'
	begin 
		begin tran
			update t
				set  email_communicationId = s.email_communicationId
			from [marketing].[docredy_pts] t
				inner join #data2rmq s on s.marketProposal_ID = t.marketProposal_ID
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