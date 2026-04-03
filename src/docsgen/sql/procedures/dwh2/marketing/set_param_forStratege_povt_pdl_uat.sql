
CREATE     procedure [marketing].[set_param_forStratege_povt_pdl_uat]
	@CMRClientGUID nvarchar(36) = null
as
--установка параметров для стратегии обзвона и отправки уведомлений - 

begin
begin try

	drop table if exists #Last_SendPush
	create table #Last_SendPush(
		CMRClientGUID nvarchar(36),
		Last_date2SendPush date
	)
	insert into #Last_SendPush(CMRClientGUID, Last_date2SendPush)
	select CMRClientGUID, 
		Last_date2SendPush = max(isnull(date2SendPush,'2000-01-01'))
	
	from marketing.povt_pdl_uat t
	where cdate < cast(getdate() as date)
	and (t.CMRClientGUID =  @CMRClientGUID or @CMRClientGUID  is null)
	group by CMRClientGUID
	create clustered index cix on #Last_SendPush( CMRClientGUID)

	drop table if exists #last_action
	--Стоим таблицу с последними событиями
	select CMRClientGUID
		,lastActionName
		,lastDateAction
		,lastNaumen_AttemptResult
		,lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиНаименование
		,lastCRMЗаявка_СтатусНаименование

		into #last_action
	from (
		select CMRClientGUID
			,lastCRMЗаявка_Дата
			,lastЗаявкаНаЗаймПодПТС_Дата
			,lastNaumen_AttemptDate
			,lastNaumen_AttemptResult = iif(lastNaumen_IsPhoned = 0, 'Не дозвонились', lastNaumen_AttemptResult)
			,lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиНаименование
			,lastCRMЗаявка_СтатусНаименование

			from marketing.povt_pdl_uat t
				where cdate = cast(getdate() as date)
				and (t.CMRClientGUID =  @CMRClientGUID or @CMRClientGUID  is null)
			and coalesce(lastNaumen_AttemptDate, lastЗаявкаНаЗаймПодПТС_Дата, lastCRMЗаявка_Дата) is not null
				and t.has_pts_market_proposal = 0 
				and t.phoneInBlackList = 0
			) t
			UNPIVOT  
			   (lastDateAction FOR lastActionName IN   
				  (lastNaumen_AttemptDate, lastЗаявкаНаЗаймПодПТС_Дата, lastCRMЗаявка_Дата)  
			)AS unpvt

	drop table if exists #last_action_result	
	select 
		t.CMRClientGUID
		,t.lastActionName
		,t.lastDateAction
		,lastActionResult =  case t.lastActionName
				 when 'lastNaumen_AttemptDate' then t.lastNaumen_AttemptResult
				 when 'lastЗаявкаНаЗаймПодПТС_Дата' then t.lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиНаименование
				 when 'lastCRMЗаявка_Дата' then t.lastCRMЗаявка_СтатусНаименование
			end
	into #last_action_result 
	from #last_action t
	inner join (
		select lastDateAction = max(lastDateAction)
		,CMRClientGUID
		from #last_action
		group by CMRClientGUID
	) lastAction on lastAction.CMRClientGUID = t.CMRClientGUID
		and lastAction.lastDateAction = t.lastDateAction
	
	drop table if exists #Result
	select 
		t.CMRClientGUID
		,interactionTypeCode
		= iif (days_after_close<13,
			case 
				when lastActionResult = 'Не дозвонились'	then concat(days_after_close,  '_days_after_loan_repaid')
				when lastActionResult = 'Отказ клиента'	then concat(days_after_close,  '_days_after_loan_repaid')
				when lastActionResult = 'Клиент передумал'	then concat(days_after_close,  '_days_after_loan_repaid')
				when lastActionResult is null  then concat(days_after_close,  '_days_after_loan_repaid')
			else 'UNKNOWN' end
			,
			case 
				when lastActionResult is null then 'isNew'
				when lastActionResult in('Отказ клиента', 'Клиент передумал')
					and datediff(dd, lastDateAction, getdate())>30 then 'isCustomerRejection'
				when lastActionResult in('Отказ клиента', 'Клиент передумал')
					and datediff(dd, lastDateAction, getdate())<=30 
					and datediff(dd, Last_SendPush.Last_date2SendPush, getdate())>=7
					then 'isCustomerRejectionPush'
				when lastActionResult in ('Не дозвонились')
					and DATEDIFF(dd, lastDateAction, getdate())>=7 then 'isNotCall2Client'
				when lastActionResult in ('Отказано')
					and DATEDIFF(dd, lastDateAction, getdate())>=7 then 'isCompanyRejection'
				when  DATEDIFF(dd, lastDateAction, getdate())>=7 then 'isOtherCases'
				else 'UNKNOWN'
			end
		 )
		, Last_SendPush.Last_date2SendPush
	into #Result
	from marketing.povt_pdl_uat t
	left join #Last_SendPush Last_SendPush 
		on Last_SendPush.CMRClientGUID =  t.CMRClientGUID
	left join #last_action_result la on la.CMRClientGUID = t.CMRClientGUID 
	where cdate = cast(getdate() as date)
		and t.has_pts_market_proposal = 0
		and t.phoneInBlackList = 0
		and (t.CMRClientGUID =  @CMRClientGUID or @CMRClientGUID  is null)
		

	create clustered  index cix on  #Result (CMRClientGUID)
	begin tran
		
		update t
			set t.interactionTypeCode = 
			case when t.has_pts_market_proposal  = 1
						then 'has_pts_market_proposal'
				when t.[has_inst_market_proposal] = 1
					then 'has_inst_market_proposal'
				when t.phoneInBlackList = 1 then 'UNKNOWN'
				else r.interactionTypeCode
				end
			,t.Last_date2SendPush = r.Last_date2SendPush
		from marketing.povt_pdl_uat  t
		left join #Result r 
			on r.CMRClientGUID = t.CMRClientGUID
		where t.cdate = cast(getdate() as date)
		and (t.CMRClientGUID =  @CMRClientGUID or @CMRClientGUID  is null)
	commit tran
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end
