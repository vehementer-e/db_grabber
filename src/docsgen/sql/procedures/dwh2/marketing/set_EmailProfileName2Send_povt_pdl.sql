

/*
select * from marketing.povt_pdl
where cdate = cast(getdate() as date)
and povt_pdl.phoneInBlackList = 0
		and povt_pdl.client_email is not null
	and Date2SendEmail is not null
	*/
CREATE       procedure [marketing].[set_EmailProfileName2Send_povt_pdl]
as
begin
--проставление профилей для отправки email
begin try
	declare @EmailProfile Table
	(
		emailProfileName nvarchar(255)
		,fromDate date
		,toDate date
	
	
	)
	insert into @EmailProfile(emailProfileName, fromDate, toDate)
	select emailProfileName,  
		DATEFROMPARTS(year(getdate()), t.Month, t.Day),
		case t.Day 
			when 1 then DATEFROMPARTS(year(getdate()), t.Month, t.Day+12)
			when 14 then EOMONTH(DATEFROMPARTS(year(getdate()), t.Month, t.Day))
		end
	from (values
		('EMAIL_ID_RE-LOAN_JANUARY1_3270', 1, 1)
		,('EMAIL_ID_RE-LOAN_JANUARY2_3270', 1, 14)
		,('EMAIL_ID_RE-LOAN_FEBRUARY1_3270', 2,1)
		,('EMAIL_ID_RE-LOAN_FEBRUARY2_3270', 2,14)
		,('EMAIL_ID_RE-LOAN_MARCH1_3270',3,1)
		,('EMAIL_ID_RE-LOAN_MARCH2_3270',3,14)
		,('EMAIL_ID_RE-LOAN_APRIL1_3270',4,1)
		,('EMAIL_ID_RE-LOAN_APRIL2_3270',4,14)
		,('EMAIL_ID_RE-LOAN_MAY1_3270',5,1)
		,('EMAIL_ID_RE-LOAN_MAY2_3270',5,14)
		,('EMAIL_ID_RE-LOAN_JUNE1_3270',6,1)
		,('EMAIL_ID_RE-LOAN_JUNE2_3270',6,14)
		,('EMAIL_ID_RE-LOAN_JULY1_3270',7,1)
		,('EMAIL_ID_RE-LOAN_JULY2_3270',7,14)
		,('EMAIL_ID_RE-LOAN_AUGUST1_3270',8,1)
		,('EMAIL_ID_RE-LOAN_AUGUST2_3270',8,14)
		,('EMAIL_ID_RE-LOAN_SEPTEMBER1_3270',9,1)
		,('EMAIL_ID_RE-LOAN_SEPTEMBER2_3270',9,14)
		,('EMAIL_ID_RE-LOAN_OCTOBER1_3270',10,1)
		,('EMAIL_ID_RE-LOAN_OCTOBER2_3270',10,14)
		,('EMAIL_ID_RE-LOAN_NOVEMBER1_3270',11,1)
		,('EMAIL_ID_RE-LOAN_NOVEMBER2_3270',11,14)
		,('EMAIL_ID_RE-LOAN_DECEMBER1_3270',12,1)
		,('EMAIL_ID_RE-LOAN_DECEMBER2_3270',12,14)

	) t(emailProfileName, Month, Day)


	declare @EmailProfile_after_loan_repaid table (emailProfileName nvarchar(255), interactionTypeCode nvarchar(255))
	insert into @EmailProfile_after_loan_repaid(emailProfileName, interactionTypeCode)
	select t.emailProfileName, interactionTypeCode from (values 
		('EMAIL_ID_1_DAY_3449', '1_days_after_loan_repaid' )
		,('EMAIL_ID_3_DAY_3449', '3_days_after_loan_repaid' )
		,('EMAIL_ID_7_DAY_3449', '7_days_after_loan_repaid')
		,('EMAIL_ID_11_DAY_3449', '8_days_after_loan_repaid')
		) t(emailProfileName, interactionTypeCode)


	drop table if exists #tEmailProfileName2Send
	create table #tEmailProfileName2Send
	(
		CMRClientGUID nvarchar(36),
		EmailProfile2Send nvarchar(255),
		Date2SendEmail date
	)
	insert into #tEmailProfileName2Send(CMRClientGUID, EmailProfile2Send, Date2SendEmail)
	select 
		povt_pdl.CMRClientGUID
		,EmailProfile2Send =  ep.EmailProfileName
		,Date2SendEmail = iif(datediff(dd, isnull(last_emailSend.last_Date2SendEmail, '2000-01-01'), cdate)>=14, cdate, null)
	
	from marketing.povt_pdl povt_pdl
		inner join @EmailProfile ep on
			povt_pdl.cdate between ep.fromDate and ep.toDate
		left  join (
			select last_Date2SendEmail = max(isnull(Date2SendEmail,'2000-01-01')),  
				CMRClientGUID
			from marketing.povt_pdl povt_pdl
			where cdate < cast(getdate() as date)
			and povt_pdl.EmailProfile2Send in (select ep.emailProfileName from @EmailProfile ep)
			group by CMRClientGUID
		) last_emailSend on last_emailSend.CMRClientGUID = povt_pdl.CMRClientGUID
		where cdate = cast(getdate() as date)
			and povt_pdl.phoneInBlackList = 0
			and povt_pdl.client_email is not null
			and povt_pdl.market_proposal_category_code not in ('red')

	union
	select 
		povt_pdl.CMRClientGUID,
		EmailProfile2Send =  ep.EmailProfileName,
		Date2SendEmail = povt_pdl.cdate
	from marketing.povt_pdl povt_pdl 
	inner join @EmailProfile_after_loan_repaid ep on ep.interactionTypeCode = povt_pdl.interactionTypeCode
	where  povt_pdl.cdate = cast(getdate() as date)
			and povt_pdl.phoneInBlackList = 0
			and povt_pdl.client_email is not null
			and povt_pdl.market_proposal_category_code not in ('red')

	begin tran
		update  povt_pdl
			set EmailProfile2Send = iif(t.Date2SendEmail is not null, t.EmailProfile2Send, null)
				,Date2SendEmail = t.Date2SendEmail
				
		from marketing.povt_pdl povt_pdl 
		left join #tEmailProfileName2Send t  on 
			t.CMRClientGUID = povt_pdl.CMRClientGUID
		where cdate = cast(getdate() as date)
	commit tran
end try
begin catch
	if @@TRANCOUNT>0
			rollback tran
		;throw
end catch
end
