/*﻿

--[etl].[GetMarketProposal_email_povt_PDL_JSON] 'prod'
--[etl].[GetMarketProposal_email_povt_PDL_JSON] 'uat'
*/
CREATE     procedure  [etl].[GetMarketProposal_email_povt_PDL_JSON]
	@env  nvarchar(255)= 'prod'
	WITH EXECUTE AS OWNER
as

begin
	set nocount on;
	declare @batchSize int = iif(@env = 'prod', 100, 1) 

begin try
drop table if exists #data2rmq
select top(0)
	emailProfile2Send,
	email_communicationId,
	approved_limit,
	client_email,
	first_name,
	marketProposal_ID
into #data2rmq
from marketing.povt_PDL povt_PDL


if @env = 'prod'
begin
	insert into #data2rmq(emailProfile2Send,
		email_communicationId,
		approved_limit,
		client_email,
		first_name,
		marketProposal_ID
		)
	select 
		emailProfile2Send,
		email_communicationId = NEWID(),
		approved_limit,
		client_email,
		first_name,
		marketProposal_ID
	from marketing.povt_PDL povt_PDL
	where cdate = cast(getdate() as date)
		and povt_PDL.phoneInBlackList = 0
			and povt_PDL.Date2SendEmail =  cast(getdate() as date)
			and povt_PDL.client_email is not null
			and povt_PDL.email_communicationId is null

end
else
begin
	declare @rowCount int = 28
	insert into #data2rmq(emailProfile2Send,
	email_communicationId,
	approved_limit,
	client_email,
	first_name,
	marketProposal_ID
	)
	select 
	emailProfile2Send = 
	case nRow
			when 1 then 'EMAIL_ID_RE-LOAN_JANUARY1_3270'
			when 2 then 'EMAIL_ID_RE-LOAN_JANUARY2_3270'
			when 3 then 'EMAIL_ID_RE-LOAN_FEBRUARY1_3270'
			when 4 then 'EMAIL_ID_RE-LOAN_FEBRUARY2_3270'
			when 5 then 'EMAIL_ID_RE-LOAN_MARCH1_3270'
			when 6 then 'EMAIL_ID_RE-LOAN_MARCH2_3270'
			when 7 then 'EMAIL_ID_RE-LOAN_APRIL1_3270'
			when 8 then 'EMAIL_ID_RE-LOAN_APRIL2_3270'
			when 9 then 'EMAIL_ID_RE-LOAN_MAY1_3270'
			when 10 then 'EMAIL_ID_RE-LOAN_MAY2_3270'
			when 11 then 'EMAIL_ID_RE-LOAN_JUNE1_3270'
			when 12 then 'EMAIL_ID_RE-LOAN_JUNE2_3270'
			when 13 then 'EMAIL_ID_RE-LOAN_JULY1_3270'
			when 14 then 'EMAIL_ID_RE-LOAN_JULY2_3270'
			when 15 then 'EMAIL_ID_RE-LOAN_AUGUST1_3270'
			when 16 then 'EMAIL_ID_RE-LOAN_AUGUST2_3270'
			when 17 then 'EMAIL_ID_RE-LOAN_SEPTEMBER1_3270'
			when 18 then 'EMAIL_ID_RE-LOAN_SEPTEMBER2_3270'
			when 19 then 'EMAIL_ID_RE-LOAN_OCTOBER1_3270'
			when 20 then 'EMAIL_ID_RE-LOAN_OCTOBER2_3270'
			when 21 then 'EMAIL_ID_RE-LOAN_NOVEMBER1_3270'
			when 22 then 'EMAIL_ID_RE-LOAN_NOVEMBER2_3270'
			when 23 then 'EMAIL_ID_RE-LOAN_DECEMBER1_3270'
			when 24 then 'EMAIL_ID_RE-LOAN_DECEMBER2_3270'
			when 25 then 'EMAIL_ID_1_DAY_3449'
			when 26 then 'EMAIL_ID_3_DAY_3449'
			when 27 then 'EMAIL_ID_7_DAY_3449'
			when 28 then 'EMAIL_ID_11_DAY_3449'
			else 	t.emailProfile2Send end,
	email_communicationId = newid(),
	t.approved_limit,
	t.client_email,
	t.first_name,
	marketProposal_ID
	from 
	(
		select  top(@rowCount)
			povt_PDL.emailProfile2Send,
			approved_limit,
			client_email,
			first_name,
			external_id,
			nRow = ROW_NUMBER() over(order by getdate()),
			marketProposal_ID
		from marketing.povt_PDL_uat povt_PDL
		where cdate = cast(getdate() as date)
		and povt_PDL.phoneInBlackList = 0
		and povt_PDL.client_email is not null
		and email_communicationId is null
	
		order by povt_PDL.external_id desc
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
	from #data2rmq;
	-- fix: ?
	declare @timeStart datetime = '8:30'
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
		
if exists (select top(1) 1 from #data2rmq)
begin
	if @env = 'uat'
	begin 
		begin tran
			update t
				set t.email_communicationId = s.email_communicationId
			from marketing.povt_PDL_uat t
				inner join #data2rmq s on s.marketProposal_ID = t.marketProposal_ID
			where t.cdate = cast(getdate() as date)
		commit tran
	end 
	if @env = 'prod'
	begin 
		begin tran
			update t
				set t.email_communicationId = s.email_communicationId
			from [marketing].[povt_PDL] t
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