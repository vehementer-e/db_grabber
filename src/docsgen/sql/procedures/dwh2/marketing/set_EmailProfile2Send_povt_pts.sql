



/*
select * from marketing.povt_pts
where cdate = cast(getdate() as date)
and povt_pts.phoneInBlackList = 0
and povt_pts.market_proposal_category_code not in ('red')
and Date2SendEmail is  null



	
	*/
CREATE         procedure [marketing].[set_EmailProfile2Send_povt_pts]
as
begin
--проставление профилей для отправки email
begin try
	declare @today date = getdate()
		,@dateStart date = '2024-03-15' --дата запуска новой стратегии
	declare @EmailProfile Table
	(
		EmailProfile nvarchar(255),
		dayAfter int
	
	)
	insert into @EmailProfile(EmailProfile, dayAfter)
	select EmailProfile, dayAfter
	
	from (values
		('EMAIL_ID_RE-LOAN_AUGUST2_3270', 4 ) --на 4й  день после закрытия займа
		,('EMAIL_ID_RE-LOAN_AUGUST2_3270', 50)-- и все последуюшие - через 50 дней после предыдущего
	) t(EmailProfile, dayAfter)

	drop table if exists #EmailProfile2Send
	create table #EmailProfile2Send
	(
		marketProposal_ID nvarchar(36),
		EmailProfile2Send nvarchar(255),
	)
	drop table if exists #t
	select 
		povt_pts.marketProposal_ID
		,povt_pts.CRMClientGUID
		,povt_pts.market_proposal_type_code
		,was_closed_ago
		,lastSendEmailEmailProfile
		,lastDateSendEmail
	into #t
	from marketing.povt_pts povt_pts
	inner join (
		select 
			marketProposal_ID
			,mincdate = min(cdate)
		from marketing.povt_pts povt_pts
		group by marketProposal_ID
	) t_first_Data on t_first_Data.marketProposal_ID = povt_pts.marketProposal_ID
		and t_first_Data.mincdate>=@dateStart 	
	--последний Email
	left join (
		select 
			povt_pts.marketProposal_ID
			,lastSendEmailEmailProfile= povt_pts.EmailProfile2Send
			,lastDateSendEmail = povt_pts.cdate
		from marketing.povt_pts povt_pts
			
		inner join (select marketProposal_ID
			,maxcdate =max(cdate)
		from marketing.povt_pts povt_pts
		where cdate<@today
			and Email_communicationId is not null
		group by marketProposal_ID
		) last_data
		on last_data.marketProposal_ID = povt_pts.marketProposal_ID
			and last_data.maxcdate =povt_pts.cdate
	) last_Email
		on last_Email.marketProposal_ID =povt_pts.marketProposal_ID
	where cdate = @today
		and povt_pts.market_proposal_category_code not in ('red')
		and phoneInBlackList = 0
		and nullif(client_email,'') is not null
	

	insert into #EmailProfile2Send(marketProposal_ID, EmailProfile2Send)
		--на 4й  день после закрытия займа
		select 
			marketProposal_ID
			,EmailProfile
			from (select
			marketProposal_ID
			,EmailProfile
			,nRow = ROW_NUMBER() over(partition by CRMClientGUID order by 
				 cast(market_proposal_type_code as int)
				 )
			from (select 
				 povt_pts.marketProposal_ID
				,ep.EmailProfile
				,povt_pts.CRMClientGUID
				,povt_pts.market_proposal_type_code
			from #t povt_pts
				inner join @EmailProfile ep 
					on datediff(dd, povt_pts.was_closed_ago , @today)>= ep.dayAfter
					and ep.EmailProfile = 'EMAIL_ID_RE-LOAN_AUGUST2_3270'
				where 1=1 and povt_pts.lastSendEmailEmailProfile is null
				
			-- и все последуюшие - через 50 дней после предыдущего
			union
			select 
				 povt_pts.marketProposal_ID
				,ep.EmailProfile
				,povt_pts.CRMClientGUID
				,povt_pts.market_proposal_type_code
			from #t povt_pts
				inner join @EmailProfile ep 
					on datediff(dd, povt_pts.lastDateSendEmail, @today)>= ep.dayAfter
				where povt_pts.lastSendEmailEmailProfile = 'EMAIL_ID_RE-LOAN_AUGUST2_3270'
			)	 t
		) t


		where nRow=1
		
		
		
	begin tran
		update  povt_pts
			set EmailProfile2Send = iif(t.marketProposal_ID is not null, t.EmailProfile2Send, null)
		from marketing.povt_pts povt_pts
		left join #EmailProfile2Send t  on 
			t.marketProposal_ID = povt_pts.marketProposal_ID
		where povt_pts.cdate = @today
	commit tran
	
end try
begin catch
	if @@TRANCOUNT>0
			rollback tran
		;throw
end catch
end

