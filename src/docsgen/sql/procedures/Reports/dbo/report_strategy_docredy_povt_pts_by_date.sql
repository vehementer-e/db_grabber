

CREATE       procedure [dbo].[report_strategy_docredy_povt_pts_by_date]
	@reportDate date = null
with recompile
as 
	--declare @reportDate date = null

declare @dd date = isnull(@reportDate, getdate())
	--информация по sms
	drop table if exists #t_povt_last_sms_send
	
	select
			t.marketProposal_ID
			,t.CRMClientGUID
			,last_Profile2Send	= t.SMSProfile2Send
			,last_send_date		= t.cdate
	into #t_povt_last_sms_send
	from 
		(select 
			marketProposal_ID,
			last_date  = max(cdate)
		from dwh2.marketing.povt_pts  t
		where  1=1
			and t.cdate<=@dd
			and [SMS_communicationId] is not null
		group by marketProposal_ID
	)  last_data
	inner join dwh2.marketing.povt_pts  t
		on	 t.marketProposal_ID = last_data.marketProposal_ID
			and t.cdate = last_data.last_date
	
	create clustered index ix_CRMClientGUID on #t_povt_last_sms_send (CRMClientGUID)
	
	drop table if exists #t_docredy_last_sms_send
	select
			t.marketProposal_ID
			,t.CRMClientGUID
			,last_Profile2Send	 = t.SMSProfile2Send
			,last_send_date		  = t.cdate
	into #t_docredy_last_sms_send
	from 
		(select 
			marketProposal_ID,
			last_date  = max(cdate)
		from dwh2.marketing.docredy_pts  t
		where [SMS_communicationId] is not null
			and t.cdate<=@dd
		group by marketProposal_ID
	)  last_data
	inner join dwh2.marketing.docredy_pts  t
		on	 t.marketProposal_ID = last_data.marketProposal_ID
			and t.cdate = last_data.last_date
	create clustered index ix_CRMClientGUID on #t_docredy_last_sms_send (CRMClientGUID)

	--информация по email
	drop table if exists #t_povt_last_email_send
	select 
		t.marketProposal_ID
		,t.CRMClientGUID
		,last_Profile2Send	= t.emailProfile2Send
		,last_send_date		= t.cdate
	into #t_povt_last_email_send
	from (
		select 
			marketProposal_ID
			,last_date = max(cdate)
		from dwh2.marketing.povt_pts t
			where email_communicationId is not null
			and t.cdate<=@dd
		group by marketProposal_ID
	) last_Data
	inner join dwh2.marketing.povt_pts  t
		on	 t.marketProposal_ID = last_data.marketProposal_ID
			and t.cdate = last_data.last_date
	create clustered index ix_CRMClientGUID on #t_povt_last_email_send (CRMClientGUID)
	

	drop table if exists #t_docredy_last_email_send
	select 
		t.marketProposal_ID
		,t.CRMClientGUID
		,last_Profile2Send	= t.emailProfile2Send
		,last_send_date		= t.cdate
	into #t_docredy_last_email_send
	from (
		select 
			marketProposal_ID
			,last_date = max(cdate)
		from dwh2.marketing.docredy_pts t
			where email_communicationId is not null
			and t.cdate<=@dd
		group by marketProposal_ID
	) last_Data
	inner join dwh2.marketing.docredy_pts  t
		on	 t.marketProposal_ID = last_data.marketProposal_ID
			and t.cdate = last_data.last_date
	
	create clustered index ix_CRMClientGUID on #t_docredy_last_email_send (CRMClientGUID)



	drop table if exists #t_docredy_last_push_send
	select 
		t.marketProposal_ID
		,t.CRMClientGUID
		,last_Profile2Send = t.pushProfile2Send
		,last_send_date		= t.cdate
	into #t_docredy_last_push_send
	from (
		select 
			marketProposal_ID
			,last_date = max(cdate)
		from dwh2.marketing.docredy_pts t
			where Push_communicationId is not null
			and t.cdate<=@dd
		group by marketProposal_ID
	) last_Data
	inner join dwh2.marketing.docredy_pts  t
		on	 t.marketProposal_ID = last_data.marketProposal_ID
			and t.cdate = last_data.last_date
	create clustered index ix_CRMClientGUID on #t_docredy_last_push_send (CRMClientGUID)


	drop table if exists #t_povt_last_push_send
	select 
		t.marketProposal_ID
		,t.CRMClientGUID
		,last_Profile2Send = t.pushProfile2Send
		,last_send_date		= t.cdate
	into #t_povt_last_push_send
	from (
		select 
			marketProposal_ID
			,last_date = max(cdate)
		from dwh2.marketing.povt_pts t
			where Push_communicationId is not null
			and t.cdate<=@dd
		group by marketProposal_ID
	) last_Data
	inner join dwh2.marketing.povt_pts  t
		on	 t.marketProposal_ID = last_data.marketProposal_ID
			and t.cdate = last_data.last_date
	create clustered index ix_CRMClientGUID on #t_povt_last_push_send (CRMClientGUID)
	

	drop table if exists #t_povt_pts_Last30Call
	select 
		CRMClientGUID
		,TotalCall = count(1)
	into #t_povt_pts_Last30Call
	from dwh2.marketing.povt_pts  t
		where 1=1
			--t.cdate between dateadd(dd,-30, @dd) and @dd
		and t.naumenCaseUUID is not null
		group by CRMClientGUID
	create clustered index ix_CRMClientGUID on  #t_povt_pts_Last30Call (CRMClientGUID)
	
	drop table if exists #t_docredy_pts_Last30Call
	select 
		CRMClientGUID
		,TotalCall = count(1)
	into #t_docredy_pts_Last30Call
	from dwh2.marketing.docredy_pts  t
		where 1=1
			--t.cdate between dateadd(dd,-30, @dd) and @dd
		and t.naumenCaseUUID is not null
		group by CRMClientGUID
	create clustered index ix_CRMClientGUID on  #t_docredy_pts_Last30Call (CRMClientGUID)

select 
	 t.marketProposal_ID
	, t.CRMClientGUID
	,[Клиент ФИО]											= t.FIO
	,[Номер телефона]										= t.phone
	,[phone In Black List]									= iif(t.phoneInBlackList = 1, 'Да', 'Нет')
	,[признак докред/повторник]								= t.[признак докред/повторник]	
	
	,[дата открытия последнего договора]					= cast(null as date)
	,[дата закрытия последнего договора]					= cast(null as date)
	,[дней после закрытия последнего договора]				= t.[was_closed_ago]
	,[маркетинговое предложение]							= t.market_proposal_category_name
	,[признак залога]										= t.market_proposal_type_name
	,[лимит]												= t.main_limit
	,[дата отправки последнего пуша]						= t.last_push_send_date
	,[код пуша]												= t.last_push_Profile2Send
	,[дата отправки последней смс]							= t.last_sms_send_date
	,[код смс]												= t.last_sms_Profile2Send
	,[дата отправки последнего email]						= t.last_email_send_date
	,[код email]											= t.last_email_Profile2Send
	,[дата последнего звонка по стратегии]					= t.lastNaumen_AttemptDate
	,[Дозвон]												= case [lastNaumen_IsPhoned]  
																	when 1 then 'Да'
																	when 0 then 'Нет'
																	end 

	,[результат звонка (на который смотрит стратегия)]		= lastNaumen_AttemptResult
	,[причина отказа/непрофильности]						= lastCRMЗаявка_СтатусНаименование

	,[признак впервые в обзвоне]							= iif(naumenInteractionTypeCode ='isNew', 'Да', 'Нет')
	,[попыток дозвона за последние 30 дней]					= TotalCallLast30Days
	,[стратегия (формулировка правила, которое сработало)]	= case naumenInteractionTypeCode 
				when 'isNew' then 'Новый'
				when 'isNotCall2Client less 5' then 'Не дозвонились до 5 раз'
				when 'isNotCall2Client between 6 and 7' then 'Не дозвонились 6 или 7'
				when 'isNotCall2Client more 7' then 'Не дозвонились 8 и больше'
				when 'isCustomerRejection 1' then 'Отказ клиента/Клиент передумал 1 раз'
				when 'isCustomerRejection more 1' then 'Отказ клиента/Клиент передумал более 1 раза'
				when 'isCompanyRejection' then 'Отказано'
				when 'UNKNOWN' then 'Не определено - не звоним'
				else naumenInteractionTypeCode
			end


	,[GUID последнего лида]				= [lastCRMЗаявка_Guid]
	,[Номер последнего лида]			= lastCRMЗаявка_Номер
	,[Дата последнего лида]				= lastCRMЗаявка_Дата
	,[Статус заявки]					= [lastCRMЗаявка_СтатусНаименование]
	,[Статус заявки ПричиныОтказов]		= lastCRMЗаявка_ПричиныОтказовНаименование
	,[Назначенный pushProfile]			= t.pushProfile2Send
	,[Назначенный SMSProfile]			= t.SMSProfile2Send
	,[Назначенный emailProfile]			= t.emailProfile2Send
	,[66+ лет]							= iif(t.ПолныйВозраст>=66,'Да','Нет')
	,titleNaumen = concat_ws(' '
						,t.Fio
						,iif(t.hasPEP =1, 'ПЭП', null )		
						,isnull([hasCommissionProducts], 'Без кп')
						,iif(t.lastRate>0, format(lastRate/100, 'p1'), null)
					)
	from (
	select 
		 t.marketProposal_ID
		,t.CRMClientGUID
		,FIO
		,phone
		,phoneInBlackList
		,[was_closed_ago] = null
		,market_proposal_category_name
		,main_limit
		,last_push_send_date		= last_push_send.last_send_date
		,last_push_Profile2Send		= last_push_send.last_Profile2Send
		
		,last_sms_send_date			= last_sms_send.last_send_date
		,last_sms_Profile2Send		= last_sms_send.last_Profile2Send
		
		,last_email_send_date		= last_email_send.last_send_date		
		,last_email_Profile2Send	= last_email_send.last_Profile2Send


		,lastNaumen_AttemptDate
		,lastNaumen_AttemptResult
		,[lastNaumen_IsPhoned]
		,[признак докред/повторник]	 = 'докред'
		,[lastCRMЗаявка_Guid]
		,lastCRMЗаявка_Номер
		,lastCRMЗаявка_Дата
		,[lastCRMЗаявка_СтатусНаименование]
		,lastCRMЗаявка_ПричиныОтказовНаименование
		,TotalCallLast30Days = Last30Call.TotalCall
		,naumenInteractionTypeCode
		,market_proposal_type_name
		,t.pushProfile2Send
		,t.SMSProfile2Send
		,t.emailProfile2Send
		,ПолныйВозраст = dwh2.dm.f_ПолныйВозраст(t.birth_date, getdate())
		,hasPEP
		,[hasCommissionProducts]
		,lastRate  = [CurrRate]
	from dwh2.marketing.docredy_pts t
	left join #t_docredy_last_sms_send last_sms_send 
		on last_sms_send.CRMClientGUID = t.CRMClientGUID
		and last_sms_send.marketProposal_ID = t.marketProposal_ID
	left join #t_docredy_last_email_send last_email_send
		on last_email_send.CRMClientGUID = t.CRMClientGUID
		and last_email_send.marketProposal_ID = t.marketProposal_ID
	left join #t_docredy_last_push_send last_push_send 
		on last_push_send.CRMClientGUID = t.CRMClientGUID
		and last_push_send.marketProposal_ID = t.marketProposal_ID
	left join #t_docredy_pts_Last30Call Last30Call 
		on Last30Call.CRMClientGUID = t.CRMClientGUID
	where cdate = @dd
	union
	select 
		 t.marketProposal_ID
		,t.CRMClientGUID
		,FIO
		,phone
		,phoneInBlackList
		,t.[was_closed_ago] 
		,market_proposal_category_name
		,main_limit
		,last_push_send_date		= last_push_send.last_send_date
		,last_push_Profile2Send		= last_push_send.last_Profile2Send
		
		,last_sms_send_date			= last_sms_send.last_send_date
		,last_sms_Profile2Send		= last_sms_send.last_Profile2Send
		
		,last_email_send_date		= last_email_send.last_send_date		
		,last_email_Profile2Send	= last_email_send.last_Profile2Send

		,lastNaumen_AttemptDate
		,lastNaumen_AttemptResult
		,[lastNaumen_IsPhoned]
		,[признак докред/повторник]	 = 'повторник'
		,[lastCRMЗаявка_Guid]
		,lastCRMЗаявка_Номер
		,lastCRMЗаявка_Дата
		,[lastCRMЗаявка_СтатусНаименование]
		,lastCRMЗаявка_ПричиныОтказовНаименование
		,TotalCallLast30Days = Last30Call.TotalCall
		,naumenInteractionTypeCode
		,market_proposal_type_name
		,t.pushProfile2Send
		,t.SMSProfile2Send
		,t.emailProfile2Send
		,ПолныйВозраст = dwh2.dm.f_ПолныйВозраст(t.birth_date, getdate())
		,hasPEP
		,[hasCommissionProducts]
		,lastRate
	from dwh2.marketing.povt_pts t
	left join #t_povt_last_sms_send last_sms_send 
		on last_sms_send.CRMClientGUID = t.CRMClientGUID
		and last_sms_send.marketProposal_ID = t.marketProposal_ID
	left join #t_povt_last_email_send last_email_send
		on last_email_send.CRMClientGUID = t.CRMClientGUID
		and last_email_send.marketProposal_ID = t.marketProposal_ID
	left join #t_povt_last_push_send last_push_send 
		on last_push_send.CRMClientGUID = t.CRMClientGUID
		and last_push_send.marketProposal_ID = t.marketProposal_ID
	left join #t_povt_pts_Last30Call Last30Call 
		on Last30Call.CRMClientGUID = t.CRMClientGUID

	where cdate = @dd
	) t
	
	

