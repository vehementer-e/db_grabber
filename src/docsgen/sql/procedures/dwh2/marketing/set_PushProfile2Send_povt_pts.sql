


/*
select * from marketing.povt_pts
where cdate = cast(getdate() as date)
and povt_pts.phoneInBlackList = 0
and povt_pts.market_proposal_category_code not in ('red')
and Date2SendPush is  null



	
	*/
CREATE        procedure [marketing].[set_PushProfile2Send_povt_pts]
as
begin
--проставление профилей для отправки email
begin try
	declare @today date = getdate()
		,@dateStart date = '2024-03-15' --дата запуска новой стратегии
	declare @PushProfile Table
	(
		PushProfile nvarchar(255),
		daysAgo int
	
	)
	insert into @PushProfile(PushProfile, daysAgo)
	select PushProfile, daysAgo
	
	from (values
		('PUSH_ID_1343_ADDITIONAL_4', 1 ) --пуш - в первый день после закрытия займа
		,('PUSH_ID_1343_ADDITIONAL_4', 7)--пуш - через 7 дней после предыдущего
		,('PUSH_ID_1343_ADDITIONAL_2', 40)-- все последующие - через 40 дней после предыдущего


	) t(PushProfile, daysAgo)

	drop table if exists #PushProfile2Send
	create table #PushProfile2Send
	(
		marketProposal_ID nvarchar(36),
		PushProfile2Send nvarchar(255),
	)
	drop table if exists #t
	select 
		povt_pts.marketProposal_ID
		,povt_pts.CRMClientGUID
		,povt_pts.market_proposal_type_code
		,was_closed_ago
		,lastSendPushPushProfile
		,lastDateSendPush
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

	--последний PUSH
	left join (
		select 
			povt_pts.marketProposal_ID
			,lastSendPushPushProfile= povt_pts.PushProfile2Send
			,lastDateSendPush = povt_pts.cdate
		from marketing.povt_pts povt_pts
			
		inner join (select marketProposal_ID
			,maxcdate =max(cdate)
		from marketing.povt_pts povt_pts
		where cdate<@today
			and Push_communicationId is not null
		group by marketProposal_ID
		) last_data
		on last_data.marketProposal_ID = povt_pts.marketProposal_ID
			and last_data.maxcdate =povt_pts.cdate
	) last_push
		on last_push.marketProposal_ID =povt_pts.marketProposal_ID
	where cdate = @today
		and povt_pts.market_proposal_category_code not in ('red')
	


	insert into #PushProfile2Send(marketProposal_ID, PushProfile2Send)
		--пуш - в первый день после закрытия займа
		select 
			marketProposal_ID
			,PushProfile
			from (select
			marketProposal_ID
			,PushProfile
			,nRow = ROW_NUMBER() over(partition by CRMClientGUID order by 
				 cast(market_proposal_type_code as int)
				 )
			from (select 
				 povt_pts.marketProposal_ID
				,ep.PushProfile
				,povt_pts.CRMClientGUID
				,povt_pts.market_proposal_type_code
			from #t povt_pts
				inner join @PushProfile ep 
					on datediff(dd, povt_pts.was_closed_ago , @today)>= ep.daysAgo
					and ep.PushProfile = 'PUSH_ID_1343_ADDITIONAL_4'
				where 1=1 and povt_pts.lastSendPushPushProfile is null
				
			--пуш - через 7 дней после предыдущего
			union
			select 
				 povt_pts.marketProposal_ID
				,ep.PushProfile
				,povt_pts.CRMClientGUID
				,povt_pts.market_proposal_type_code
			from #t povt_pts
				inner join @PushProfile ep 
					on datediff(dd, povt_pts.lastDateSendPush, @today)>= ep.daysAgo
					and ep.PushProfile = 'PUSH_ID_1343_ADDITIONAL_4'
				where povt_pts.lastSendPushPushProfile = 'PUSH_ID_1343_ADDITIONAL_4'
				--и небыло отправки 
				and not exists(select top(1) 1
					from  marketing.povt_pts t
					where t.cdate< @today
						and t.pushProfile2Send = ep.PushProfile
						and t.Push_communicationId is not null)
			-- все последующие - через 40 дней после предыдущего
			union
			select 
				 povt_pts.marketProposal_ID
				,ep.PushProfile
				,povt_pts.CRMClientGUID
				,povt_pts.market_proposal_type_code
			from #t povt_pts
				inner join @PushProfile ep 
					on datediff(dd, povt_pts.lastDateSendPush, @today)>= ep.daysAgo
					and ep.PushProfile = 'PUSH_ID_1343_ADDITIONAL_2'
				where povt_pts.lastSendPushPushProfile in('PUSH_ID_1343_ADDITIONAL_4', 'PUSH_ID_1343_ADDITIONAL_2')
			)	 t
		) t


		where nRow=1
		
		
		
	begin tran
		update  povt_pts
			set PushProfile2Send = iif(t.marketProposal_ID is not null, t.PushProfile2Send, null)
		from marketing.povt_pts povt_pts
		left join #PushProfile2Send t  on 
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

