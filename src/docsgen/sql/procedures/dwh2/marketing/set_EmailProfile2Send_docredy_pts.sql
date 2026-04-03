



/*
select * from marketing.docredy_pts
where cdate = cast(getdate() as date)
and docredy_pts.phoneInBlackList = 0
and docredy_pts.market_proposal_category_code not in ('red')
and Date2SendEmail is  null



	
	*/
CREATE         procedure [marketing].[set_EmailProfile2Send_docredy_pts]
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
		('EMAIL_ID_TAKE_MONEY_1343', 11 ) --на 11й  деньпосле возникновения марк предложения
		,('EMAIL_ID_NEW_LOAN_1343', 40)-- через 40 дней после предыдущего
		,('EMAIL_ID_NEW_LOAN_1343', 30)-- все последуюшие - через 30 дней после предыдущего



	) t(EmailProfile, dayAfter)

	drop table if exists #EmailProfile2Send
	create table #EmailProfile2Send
	(
		marketProposal_ID nvarchar(36),
		EmailProfile2Send nvarchar(255),
	)
	drop table if exists #t
	select 
		docredy_pts.marketProposal_ID
		,docredy_pts.CRMClientGUID
		,docredy_pts.market_proposal_type_code
		,market_proposalfirst_Date = t_first_Data.mincdate
		,lastSendEmailEmailProfile
		,lastDateSendEmail
	into #t
	from marketing.docredy_pts docredy_pts
	inner join (
		select 
			marketProposal_ID
			,mincdate = min(cdate)
		from marketing.docredy_pts docredy_pts
		group by marketProposal_ID
	) t_first_Data on t_first_Data.marketProposal_ID = docredy_pts.marketProposal_ID
		and t_first_Data.mincdate>=@dateStart 
	
	--последний Email
	left join (
		select 
			docredy_pts.marketProposal_ID
			,lastSendEmailEmailProfile= docredy_pts.EmailProfile2Send
			,lastDateSendEmail = docredy_pts.cdate
		from marketing.docredy_pts docredy_pts
			
		inner join (select marketProposal_ID
			,maxcdate =max(cdate)
		from marketing.docredy_pts docredy_pts
		where cdate<@today
			and Email_communicationId is not null
		group by marketProposal_ID
		) last_data
		on last_data.marketProposal_ID = docredy_pts.marketProposal_ID
			and last_data.maxcdate =docredy_pts.cdate
	) last_Email
		on last_Email.marketProposal_ID =docredy_pts.marketProposal_ID
	where cdate = @today
		and docredy_pts.market_proposal_category_code not in ('red')
		and phoneInBlackList = 0
		and nullif(client_email,'') is not null
		--только те МП у которые были с даты запуска новой стратегии
		

	insert into #EmailProfile2Send(marketProposal_ID, EmailProfile2Send)
		--на 11й  деньпосле возникновения марк предложения
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
				 docredy_pts.marketProposal_ID
				,ep.EmailProfile
				,docredy_pts.CRMClientGUID
				,docredy_pts.market_proposal_type_code
			from #t docredy_pts
				inner join @EmailProfile ep 
					on datediff(dd, docredy_pts.market_proposalfirst_Date , @today)>= ep.dayAfter
					and ep.EmailProfile = 'EMAIL_ID_TAKE_MONEY_1343'
				where 1=1 and docredy_pts.lastSendEmailEmailProfile is null
				
			--через 40 дней после предыдущего
			union
			select 
				 docredy_pts.marketProposal_ID
				,ep.EmailProfile
				,docredy_pts.CRMClientGUID
				,docredy_pts.market_proposal_type_code
			from #t docredy_pts
				inner join @EmailProfile ep 
					on datediff(dd, docredy_pts.lastDateSendEmail, @today)>= ep.dayAfter
					and ep.EmailProfile = 'EMAIL_ID_NEW_LOAN_1343'
				where docredy_pts.lastSendEmailEmailProfile = 'EMAIL_ID_TAKE_MONEY_1343'
				--и небыло отправки 
				and not exists(select top(1) 1
					from  marketing.docredy_pts t
					where t.cdate< @today
						and t.EmailProfile2Send = ep.EmailProfile
						and t.Email_communicationId is not null)
			-- все последуюшие - через 30 дней после предыдущего
			union
			select 
				 docredy_pts.marketProposal_ID
				,ep.EmailProfile
				,docredy_pts.CRMClientGUID
				,docredy_pts.market_proposal_type_code
			from #t docredy_pts
				inner join @EmailProfile ep 
					on datediff(dd, docredy_pts.lastDateSendEmail, @today)>= ep.dayAfter
					and ep.EmailProfile = 'EMAIL_ID_TAKE_MONEY_1343'
				where docredy_pts.lastSendEmailEmailProfile in('EMAIL_ID_NEW_LOAN_1343')
			)	 t
		) t


		where nRow=1
		
		
		
	begin tran
		update  docredy_pts
			set EmailProfile2Send = iif(t.marketProposal_ID is not null, t.EmailProfile2Send, null)
		from marketing.docredy_pts docredy_pts
		left join #EmailProfile2Send t  on 
			t.marketProposal_ID = docredy_pts.marketProposal_ID
		where docredy_pts.cdate = @today
	commit tran
	
end try
begin catch
	if @@TRANCOUNT>0
			rollback tran
		;throw
end catch
end

