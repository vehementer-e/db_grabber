CREATE        procedure [marketing].[set_naumenInteractionTypeCode_povt_pts]
	@CMRClientGUID nvarchar(36) = null,
	@CMRClientGUIDs nvarchar(max) = null
as
--установка параметров для стратегии обзвона и отправки уведомлений - 

begin
	set @CMRClientGUIDs = nullif(CONCAT_WS(',',@CMRClientGUID, @CMRClientGUIDs), '')
begin try

	
	drop table if exists #last_action
	--Стоим таблицу с последними событиями
	select marketProposal_ID
		,lastActionName
		,lastDateAction
		,lastNaumen_AttemptResult
	--	,lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиНаименование
		,lastCRMЗаявка_СтатусНаименование
	into #last_action
	from (
		select marketProposal_ID
			,lastCRMЗаявка_Дата
			/*
				Если дата звонка = дата заявки 
				и  время звонка> время заявки
				то береме время звонка как время заявки
			*/
				=iif( cast(lastCRMЗаявка_Дата  as date) =  cast(lastNaumen_AttemptDate as date)
					and lastNaumen_AttemptDate>lastCRMЗаявка_Дата, dateadd(ss,1, lastNaumen_AttemptDate)					
						, lastCRMЗаявка_Дата)
			,lastCRMЗаявка_СтатусНаименование
			,lastNaumen_AttemptDate
			,lastNaumen_AttemptResult = iif(lastNaumen_IsPhoned = 0, 'Не дозвонились', lastNaumen_AttemptResult)
	--		,lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиНаименование
			
			from marketing.povt_pts t
				where cdate = cast(getdate() as date)
				and t.market_proposal_category_code not in ('red')
				and coalesce(lastNaumen_AttemptDate, lastCRMЗаявка_Дата) is not null
				and t.phoneInBlackList = 0
				and (t.CRMClientGUID  in (select trim(value) from string_split(@CMRClientGUIDs, ',')) or @CMRClientGUIDs  is null)
			) t
			UNPIVOT  
			   (lastDateAction FOR lastActionName IN   
				  (lastNaumen_AttemptDate, lastCRMЗаявка_Дата)  
			)AS unpvt
	
	drop table if exists #last_action_result	
	select 
		t.marketProposal_ID
		,t.lastActionName
		,t.lastDateAction
		,lastActionResult =  case t.lastActionName
				 when 'lastNaumen_AttemptDate' then t.lastNaumen_AttemptResult
				-- when 'lastЗаявкаНаЗаймПодПТС_Дата' then t.lastЗаявкаНаЗаймПодПТС_СтатусыЗаявкиНаименование
				 when 'lastCRMЗаявка_Дата' then t.lastCRMЗаявка_СтатусНаименование
			end
	into #last_action_result 
	from #last_action t
	inner join (
		select lastDateAction = max(lastDateAction)
		,marketProposal_ID
		from #last_action
		group by marketProposal_ID
	) lastAction on lastAction.marketProposal_ID = t.marketProposal_ID
		and lastAction.lastDateAction = t.lastDateAction
	
	drop table if exists #Result
	select 
		t.marketProposal_ID
		,naumenInteractionTypeCode
		= case 
				when t.phoneInBlackList = 1 then 'UNKNOWN'
				when lastActionResult is null then 'isNew'
				when lastActionResult in ('Не дозвонились'
					
					, 'consultation' -- если последние завершилось как consultation то это равно = Не дозвонились
					, 'Заявка' -- если последние завершилось как Заявка то это равно = Не дозвонились
					, 'Предварительный' -- если последние завершилось как Предварительный то это равно = Не дозвонились
				)
					
					 then 
						case 
							--первые 5 звонков звоним каждые 5дней (без результата) и от даты прошло звонка прошло больше 5 дней, то звоним
							when isnull(t.totalIsNotPhoned,0)<=5 and  datediff(dd, lastDateAction, getdate()) >=5 
									then 'isNotCall2Client less 5'
							--между 6 и 7 звонок делаем через 14дней
							when isnull(t.totalIsNotPhoned,0) between 6 and 7 and datediff(dd, lastDateAction, getdate()) >=14
									then 'isNotCall2Client between 6 and 7' 
							--. Все последующие звонки - раз в 30 дней 
							when isnull(t.totalIsNotPhoned,0)>7 and  datediff(dd, lastDateAction, getdate()) >=30
								then 'isNotCall2Client  more 7'
						end
				when lastActionResult in('Отказ клиента', 'Клиент передумал') 
					then 
						case 
						--После отказа 1 звонок на 17 день
						when isnull(t.totalIsCustomerRejection,0) = 1 and datediff(dd, lastDateAction, getdate())>=17
							then 'isCustomerRejection 1'
						--После каждые 30 дней,
						 when isnull(t.totalIsCustomerRejection,0) > 1 and datediff(dd, lastDateAction, getdate()) >30
							then 'isCustomerRejection more 1'
						end
				when lastActionResult in ('Отказано', 'Забраковано')
					and datediff(dd, lastDateAction, getdate()) >=60  then 'isCompanyRejection'
				when lastActionResult in ('Заявка')
					and datediff(mm, lastDateAction, getdate())>=3 then 'isCustomerRejection 1'
				else 'UNKNOWN'
			end,
			t.naumenPriority
	into #Result
	
	from (
	select 
		marketProposal_ID,
		phoneInBlackList,
		totalIsNotPhoned,
		totalIsCustomerRejection,
		naumenPriority = case 
							when main_limit >=800000					then 50
							when main_limit between 600000 and 800000-1	then 40
							when main_limit between 400000 and 600000-1 then 30
							when main_limit between 200000 and 400000-1 then 20
							when main_limit <200000-1					then 10
							else 10 end
						-- в зависимости отставки
						+ 
						case 
							when [Ставка %] < 60	then 10
							when [Ставка %] < 70	then 20
							when [Ставка %] < 80	then 30
							when [Ставка %] < 90	then 40
							when [Ставка %] < 100	then 50
							when [Ставка %] > 100	then 60
							else 10 end
		,nRow = ROW_NUMBER() over(partition by CRMClientGUID, phone order by 
			case 
						when main_limit >=800000					then 50
						when main_limit between 600000 and 800000-1	then 40
						when main_limit between 400000 and 600000-1 then 30
						when main_limit between 200000 and 400000-1 then 20
						when main_limit <200000-1					then 10
						else 10 end
					-- в зависимости отставки
					+ 
					case 
						when [Ставка %] < 60	then 10
						when [Ставка %] < 70	then 20
						when [Ставка %] < 80	then 30
						when [Ставка %] < 90	then 40
						when [Ставка %] < 100	then 50
						when [Ставка %] > 100	then 60
						else 10 end
					desc
					)
			
		from 
	marketing.povt_pts t
	where cdate = cast(getdate() as date)
		and t.market_proposal_category_code not in ('red')
		and len(t.phone)=10
		and t.phoneInBlackList  = 0
		and t.was_closed_ago >=3 --Стратегия стартует на 3-ий день
		and dm.f_ПолныйВозраст(t.birth_date, getdate()) <66 --до 66лет
		and (t.CRMClientGUID  in (select trim(value) from string_split(@CMRClientGUIDs, ',')) or @CMRClientGUIDs  is null)
	) t
	left join #last_action_result la 
		on la.marketProposal_ID = t.marketProposal_ID 
	where t.nRow = 1
	begin tran
		update t
			set [naumenInteractionTypeCode] = isnull(s.naumenInteractionTypeCode, 'UNKNOWN')
			,naumenPriority = s.naumenPriority
		from marketing.povt_pts t
		left join #Result  s
			on s.marketProposal_ID = t.marketProposal_ID
		where cdate = cast(getdate() as date)

	commit tran
			
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end
