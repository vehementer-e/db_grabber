

/*
select * from marketing.docredy_pts
where cdate = cast(getdate() as date)
and docredy_pts.phoneInBlackList = 0
and docredy_pts.market_proposal_category_code not in ('red')
and Date2SendPush is  null



	
	*/
CREATE           procedure [marketing].[set_PushProfile2Send_docredy_pts]
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
		('PUSH_ID_1343_ADDITIONAL_5', 2 ) --пуш - на второй день после возникновения марк предложения
		,('PUSH_ID_1343_ADDITIONAL_4', 21)--пуш - через 21 день после предыдущего
		,('PUSH_ID_1343_ADDITIONAL_2', 30)--пуш и все последующие - через 30 дней после предыдущего


	) t(PushProfile, daysAgo)

	drop table if exists #PushProfile2Send
	create table #PushProfile2Send
	(
		marketProposal_ID nvarchar(36),
		PushProfile2Send nvarchar(255),
	)
	drop table if exists #t
	select 
			docredy_pts.marketProposal_ID
		,docredy_pts.CRMClientGUID
		,docredy_pts.market_proposal_type_code
		,market_proposalfirst_Date = t_first_Data.mincdate
		,lastSendPushPushProfile
		,lastDateSendPush
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
	--последний PUSH
	left join (
		select 
			docredy_pts.marketProposal_ID
			,lastSendPushPushProfile= docredy_pts.PushProfile2Send
			,lastDateSendPush = docredy_pts.cdate
		from marketing.docredy_pts docredy_pts
			
		inner join (select marketProposal_ID
			,maxcdate =max(cdate)
		from marketing.docredy_pts docredy_pts
		where cdate<@today
			and Push_communicationId is not null
		group by marketProposal_ID
		) last_data
		on last_data.marketProposal_ID = docredy_pts.marketProposal_ID
			and last_data.maxcdate =docredy_pts.cdate
	) last_push
		on last_push.marketProposal_ID =docredy_pts.marketProposal_ID
	where cdate = @today
		and docredy_pts.market_proposal_category_code not in ('red')
	


	insert into #PushProfile2Send(marketProposal_ID, PushProfile2Send)
		--пуш - на второй день после возникновения марк предложения
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
				docredy_pts.marketProposal_ID
			,ep.PushProfile
			,docredy_pts.CRMClientGUID
			,docredy_pts.market_proposal_type_code
		from #t docredy_pts
			inner join @PushProfile ep 
				on datediff(dd, docredy_pts.market_proposalfirst_Date , @today)>= ep.daysAgo
				and ep.PushProfile = 'PUSH_ID_1343_ADDITIONAL_4'
			where 1=1 and docredy_pts.lastSendPushPushProfile is null
				
		--пуш - через 21 день после предыдущего
		union
		select 
				docredy_pts.marketProposal_ID
			,ep.PushProfile
			,docredy_pts.CRMClientGUID
			,docredy_pts.market_proposal_type_code
		from #t docredy_pts
			inner join @PushProfile ep 
				on datediff(dd, docredy_pts.lastDateSendPush, @today)>= ep.daysAgo
				and ep.PushProfile = 'PUSH_ID_1343_ADDITIONAL_5'
			where docredy_pts.lastSendPushPushProfile = 'PUSH_ID_1343_ADDITIONAL_4'
			
		--пуш и все последующие - через 30 дней после предыдущего
		union
		select 
				docredy_pts.marketProposal_ID
			,ep.PushProfile
			,docredy_pts.CRMClientGUID
			,docredy_pts.market_proposal_type_code
		from #t docredy_pts
			inner join @PushProfile ep 
				on datediff(dd, docredy_pts.lastDateSendPush, @today)>= ep.daysAgo
				and ep.PushProfile = 'PUSH_ID_1343_ADDITIONAL_2'
			where docredy_pts.lastSendPushPushProfile in('PUSH_ID_1343_ADDITIONAL_5', 'PUSH_ID_1343_ADDITIONAL_2')
		)	 t
	) t


	where nRow=1
		
		
		
	begin tran
		update  docredy_pts
			set PushProfile2Send = iif(t.marketProposal_ID is not null, t.PushProfile2Send, null)
		from marketing.docredy_pts docredy_pts
		left join #PushProfile2Send t  on 
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

