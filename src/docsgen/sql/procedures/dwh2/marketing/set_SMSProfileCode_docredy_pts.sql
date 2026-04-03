

/*
select * from marketing.docredy_pts
where cdate = cast(getdate() as date)
and docredy_pts.phoneInBlackList = 0
and docredy_pts.market_proposal_category_code not in ('red')
and Date2SendSMS is  null



	
	*/
CREATE         procedure [marketing].[set_SMSProfileCode_docredy_pts]
as
begin
--проставление профилей для отправки email
begin try
	declare @today date = getdate()
		,@dateStart date = '2024-03-15' --дата запуска новой стратегии
	declare @SmsProfile Table
	(
		SmsProfile nvarchar(255),
		daysAfterClosedAgo int
	
	)
	insert into @SmsProfile(SmsProfile, daysAfterClosedAgo)
	select SmsProfile, daysAfterClosedAgo
	
	from (values
		('SMS_ID_1343_ADDITIONAL_LOAN_2', 30 )
	) t(SmsProfile, daysAfterClosedAgo)

	drop table if exists #SmsProfile2Send
	create table #SmsProfile2Send
	(
		marketProposal_ID nvarchar(36),
		SMSProfile2Send nvarchar(255),
	)
	insert into #SmsProfile2Send(marketProposal_ID, SMSProfile2Send)
	
	select 
		marketProposal_ID
		,SMSProfile2Send
		from(select 
		docredy_pts.marketProposal_ID
		,SMSProfile2Send =  ep.SmsProfile
		,nRow = ROW_NUMBER() over(partition by CRMClientGUID order by 
			 cast(market_proposal_type_code as int)
			 )
			--market_proposal_type_name	market_proposal_type_code
			--Повторный заём с известным залогом	000000002
			--Повторный заём с новым залогом	000000003

	from marketing.docredy_pts docredy_pts
	inner join (
		select 
			marketProposal_ID
			,mincdate = min(cdate)
			
		from marketing.docredy_pts docredy_pts
		group by marketProposal_ID
	) t_first_Data 
	on t_first_Data.marketProposal_ID = docredy_pts.marketProposal_ID
		and t_first_Data.mincdate>=@dateStart 
		inner join @SmsProfile ep 
			on datediff(dd, t_first_Data.mincdate , @today)>= ep.daysAfterClosedAgo
	
		where cdate = @today
			and docredy_pts.phoneInBlackList = 0
			and docredy_pts.market_proposal_category_code not in ('red')
			--ранее небыло отправки sms с указанным профилем, данному клиенту
			and not exists(select top(1) 1 from marketing.docredy_pts  t1
				where t1.cdate<docredy_pts.cdate
				and t1.CRMClientGUID = docredy_pts.CRMClientGUID
				and t1.SMS_communicationId is not NULL
				and t1.SMSProfile2Send = ep.SmsProfile
				)
		)	 t	
		where nRow=1
		  
		
		
	begin tran
		update  docredy_pts
			set SMSProfile2Send = iif(t.marketProposal_ID is not null, t.SMSProfile2Send, null)
		from marketing.docredy_pts docredy_pts
		left join #SmsProfile2Send t  on 
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

