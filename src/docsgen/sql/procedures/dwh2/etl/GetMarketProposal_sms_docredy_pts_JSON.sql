/*﻿

--[etl].[GetMarketProposal_sms_docredy_pts_JSON] 'prod'
--[etl].[GetMarketProposal_sms_docredy_pts_JSON] 'uat'
*/
CREATE      procedure  [etl].[GetMarketProposal_sms_docredy_pts_JSON]
	@env  nvarchar(255)= 'uat',
	@CMRClientGUIDs  nvarchar(max) = null
	WITH EXECUTE AS OWNER
as

begin
	set nocount on;
	

begin try
drop table if exists #data2rmq
	select top(0)
		Template = SMSProfile2Send,
		communicationId = NEWID(),
		marketProposal_ID,
		phone,
		approvedSum = main_limit
	into #data2rmq
	from marketing.docredy_pts povt_PDL
if @env = 'prod'
begin
	insert into #data2rmq(Template,
		communicationId,
		marketProposal_ID,
		phone,
		approvedSum
		)
	select 
		Template = SMSProfile2Send,
		communicationId = NEWID(),
		marketProposal_ID,
		phone,
		approvedSum = main_limit
	from marketing.docredy_pts docredy_pts
	where cdate = cast(getdate() as date)
		and docredy_pts.phoneInBlackList = 0
			and docredy_pts.SMSProfile2Send  is not null
			and docredy_pts.SMS_communicationId is null
			and len(phone) = 10
	
end
else
begin
	declare @rowCount int = 25
	insert into #data2rmq(Template,
		communicationId,
		marketProposal_ID,
		phone,
		approvedSum
		)
	select top(@rowCount)
		Template = 'SMS_ID_1343_ADDITIONAL_LOAN_2',
		communicationId = NEWID(),
		marketProposal_ID,
		phone,
		approvedSum = main_limit
	from marketing.docredy_pts_uat
	where len(phone) = 10
		and market_proposal_category_code not in ('red')
		
end
	
BEGIN
  
   	declare @params [etl].[utt_ComcMessageParams]
	insert into @params([communicationId], [name], [value])
	select communicationId
		,'key'
		,phone
	from #data2rmq 
	insert into @params([communicationId], [name], [value])
	select communicationId
		,'name'
		,phone
	from #data2rmq;
	--fix: 8:30
	declare @timeStart datetime = '8:30'
	declare @today date = getdate()
	declare @planned_at datetime = (cast(@today as datetime) + cast(@timeStart as datetime))
	insert into @params([communicationId], [name], [value])
	SELECT [communicationId]
		, 'plannedAt'
		, format(@planned_at, 'yyyy-MM-dd hh:mm:ss')
	FROM #data2rmq;

	select p.json
	from #data2rmq t
	outer apply (
		select json =  etl.GetComcMessage_Json(t.Template, t.communicationId, @params)
		) p
END
		
if exists (select top(1) 1 from #data2rmq)
begin
	if @env = 'uat'
	begin 
		begin tran
			update t
				set t.SMS_communicationId = s.communicationId
			from marketing.docredy_pts_uat t
				inner join #data2rmq s on s.marketProposal_ID = t.marketProposal_ID
			where t.cdate = cast(getdate() as date)
		commit tran
	end 
	if @env = 'prod'
	begin 
		begin tran
			update t
				set t.SMS_communicationId = s.communicationId
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
