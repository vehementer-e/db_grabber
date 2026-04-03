  
 
 CREATE PROCEDURE [collection].[create_say_jp_sym_pay_jp_stage] 

   AS

  BEGIN

  DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)

  begin try








drop table if exists #calendar;
	select convert(date,'01.01.2022',104) Month_Value into #calendar

	WHILE (select max(Month_Value) from #calendar) <dateadd(dd,1, EOMONTH(cast(getdate() as date), -1))-- [collection].dt_st_month(cast(getdate() as date))--reports.dbo.dt_st_month во всех местах
		BEGIN
			insert #calendar (Month_Value)
			select 
					dateadd(mm,1,max(Month_Value))
			from
					#calendar
		END
	;


	EXEC [collection].set_debug_info @sp_name
			,'1';


	drop table if exists #v_balance_cmr;
	select
			balance_cmr.external_id
			,balance_cmr.d cdate
			,cast(coalesce(balance_cmr.[сумма поступлений],0) as int) total_CF --pay_total on [сумма поступлений] --balance_mfo на balance_cmr
			,balance_cmr.overdue
			,lag(balance_cmr.[остаток од],1,0) over (partition by balance_cmr.external_id order by balance_cmr.d) principal_rest
			,case when balance_cmr.[dpd day-1] = 0 
					and balance_cmr.[сумма поступлений] > 0 
					and lag(balance_cmr.overdue,1,0) over (partition by balance_cmr.external_id order by balance_cmr.d) > 0
					and balance_cmr.[сумма поступлений] > lag(balance_cmr.overdue,1,0) over (partition by balance_cmr.external_id order by balance_cmr.d)
					then balance_cmr.[dpd day-1] + 1
					else balance_cmr.[dpd day-1]
					end overdue_days_p_corr
					,r_month  =datefromparts(balance_cmr.r_year, balance_cmr.r_month, 1) --добавленно поле
	into #v_balance_cmr
	from dbo.dm_cmrstatbalance				balance_cmr ---reports.dbo.dm_CMRStatBalance_2
	/*left join dbo.dm_cmrstatbalance				balance_mfo	on balance_mfo.external_id = balance_cmr.external_id
																	and balance_mfo.d = balance_cmr.d  --mfo.r_date on d*/
	where 1=1
			and balance_cmr.d >= (select dateadd(dd,-1,min(Month_Value)) from #calendar)
	;



	EXEC [collection].set_debug_info @sp_name
			,'2';

	drop table if exists #base_dt_closed; 
	select 
			IdCustomer
			,Number
			,ChangeDate dt_closed
	into #base_dt_closed
	from
	(
			select
					d.Number
					,d.IdCustomer
					,cast(dh.ChangeDate as date) ChangeDate
					,ROW_NUMBER() over (partition by d.Number order by dh.ChangeDate desc) rn
			from
					stg._Collection.DealHistory					dh
					join stg._Collection.Deals					d on d.id = dh.ObjectId
			where 1=1
					and dh.field = 'Стадия коллектинга договора'
					and dh.NewValue = 9
	)base_deal_closed
	where 1=1
			and rn = 1
	;

	drop table if exists #portf_cash_all;
	select
			Month_Value
			,portf.principal_rest
			,pay.sum_pay_1_90
			,pay.sum_pay_91
			,portf.count_deals
			,portf.count_closed_deals
			
	into #portf_cash_all
	from
			#calendar												ca
			left join 
					  (
						select 
								bc.cdate
								,sum(bc.principal_rest) principal_rest
								,sum(1) count_deals
								,count(bdc.number) count_closed_deals
						from
								#v_balance_cmr						bc
								left join #base_dt_closed			bdc on bdc.number = bc.external_id
																		and [collection].dt_st_month(bdc.dt_closed) = bc.cdate
						where 1=1
								and datepart(dd,bc.cdate) = 1
								and bc.overdue_days_p_corr >= 1
						group by
								cdate
					  )													portf on portf.cdate = ca.Month_Value
			left join 
					  (
						select 
								r_month cdate--[collection].dt_st_month(cdate) cdate
								,sum(case when overdue_days_p_corr < 91 then total_CF else 0 end) sum_pay_1_90
								,sum(case when overdue_days_p_corr >= 91 then total_CF else 0 end) sum_pay_91
						from
								#v_balance_cmr
						where 1=1
								and overdue_days_p_corr >= 1
						group by
								r_month --[collection].dt_st_month(cdate)
					  )													pay on pay.cdate = ca.Month_Value
	;



	EXEC [collection].set_debug_info @sp_name
			,'3';

	drop table if exists #Judicial_Proceeding;
	select *
	into #Judicial_Proceeding
	from
	(
		select distinct
				DealId
				,number
				,jp.id
				,amountclaim
				,cast(coalesce(SubmissionClaimDate,jp.createdate) as date) dt_max_submission_claim
				,ROW_NUMBER() over (partition by DealId order by SubmissionClaimDate desc) rn
		from stg._Collection.JudicialProceeding		jp
		join stg._Collection.deals					d on d.id = jp.DealId
		where 1 = 1
				and isfake != 1
				and coalesce(jp.TotalRequirement,0) in (0,1,2,3)
	)aa
	where rn = 1 and aa.dt_max_submission_claim >'2021-01-01' -- срезал период
	;


	drop table if exists #Judicial_Claims;
	select id
			,cast(CourtClaimSendingDate as date) dt_Court_Claim_Sending
			,JudicialProceedingId
			,PrincipalDebtOnClaim
			,PercentageOnClaim
			,PenaltiesOnClaim
			,StateDutyOnClaim
			,AmountRequirements
			,PrincipalDebtOnJudgment
			,PercentageOnJudgment
			,PenaltiesOnJudgment
			,StateDutyOnJudgment
			,AmountJudgment
	into #Judicial_Claims
	from Stg._Collection.JudicialClaims
	;

	EXEC [collection].set_debug_info @sp_name
			,'4';

	drop table if exists #base_Result_Courts; 
	select 
			number
			,ReceiptOfJudgmentDate dt_Receipt_Judgment
	into #base_Result_Courts
	from
	(
	select 
			d.number
			,cast(jc.ReceiptOfJudgmentDate as date) ReceiptOfJudgmentDate
			,ROW_NUMBER() over (partition by d.number order by jc.ReceiptOfJudgmentDate desc) rn
	from Stg._Collection.JudicialClaims			jc
	join stg._Collection.JudicialProceeding		jp on jp.id = jc.JudicialProceedingId
	join stg._Collection.Deals					d on d.id = jp.DealId
	where 1 = 1
			and jc.ReceiptOfJudgmentDate is not null
			and coalesce(jc.ResultOfCourtsDecision,0) != 3
	)aa
	where rn = 1
	;


	drop table if exists #Enforcement_Orders;
	select DealId
			,id id_IL
			,dt_Receipt_IL
			,amount sum_IL
	into #Enforcement_Orders
	from
	(
		select eo.id
				,jp.DealId
				,eo.amount
				,cast(eo.ReceiptDate as date) dt_Receipt_IL
				,ROW_NUMBER() over (partition by jp.DealId order by eo.ReceiptDate desc) rn
		from Stg._Collection.EnforcementOrders			eo
		join  Stg._Collection.JudicialClaims			jc on jc.id = eo.JudicialClaimId
		join Stg._Collection.JudicialProceeding			jp on jp.Id = jc.JudicialProceedingId
		where eo.[Type] != 1
	)aa
	where rn = 1
	;

	drop table if exists #Enforcement_Proceeding;
	select
			*
	into #Enforcement_Proceeding
	from
	(	
		select
				jp.DealId
				,cast(epe.ExcitationDate as date) dt_excitation_ep
				,epe.Id id_excitation_ep
				,ROW_NUMBER() over (partition by jp.DealId order by epe.ExcitationDate desc) rn
		from 
				Stg._Collection.JudicialProceeding							jp
				join Stg._Collection.JudicialClaims							jc on jc.JudicialProceedingId = jp.Id
				join Stg._Collection.EnforcementOrders						eo on eo.JudicialClaimId = jc.Id
				join Stg._Collection.EnforcementProceeding					ep on ep.EnforcementOrderId = eo.Id
				join Stg._Collection.EnforcementProceedingExcitation		epe on epe.EnforcementProceedingId = ep.Id
		where 1=1
				and epe.ExcitationDate is not null
				and eo.[Type] != 1
	)aa
	where 1=1
			and rn = 1
	;
	EXEC [collection].set_debug_info @sp_name
			,'5';


	drop table if exists #base_problematic_status;
	select distinct 
				CustomerId
				,number
	into #base_problematic_status
	from
	(
		SELECT
				[CustomerId]
			,d.Number
			,[CustomerStateId]									
			,t2.[Name]									
			,ROW_NUMBER() over (partition by [CustomerId] order by t2.[order] desc) rn									
			,coalesce(cast(t1.createdate as date),'2000-01-01') dt_st_State									
		FROM stg._collection.[CustomerStatus]		t1										
		join stg._collection.[CustomerState]		t2 on t2.[Id] = t1.[CustomerStateId]
		join stg._Collection.Deals					d on d.IdCustomer = t1.CustomerId
		where 1 = 1 												
				and t1.[IsActive] = 1 										
				and t2.[Name] in 										
								(						
								'Смерть подтвержденная'					
								,'Банкрот подтверждённый'
								,'Банкрот неподтверждённый'
								)
	)aa
	where rn = 1
	;

	drop table if exists #base_deal_closed; 
	select distinct
			d.IdCustomer
			,d.Number
	into #base_deal_closed
	from stg._Collection.Deals				d
	join stg._Collection.collectingStage	cs on cs.id = d.StageId
	where 1 = 1 
			and ((cs.name = 'Closed' and d.[DebtSum] = 0)
				or (cs.Name != 'Closed' and d.fulldebt <= 0))
			and cast(SUBSTRING(d.Number, 1, 1) as int) != 0
	;



	drop table if exists #base_deal_denied; 
	select distinct
			d.number
	into #base_deal_denied
	from Stg._Collection.JudicialClaims			jc
	join stg._Collection.JudicialProceeding		jp on jp.id = jc.JudicialProceedingId
	join stg._Collection.Deals					d on d.id = jp.DealId
	where 1 = 1
			and jc.ResultOfCourtsDecision = 3
	;



	EXEC [collection].set_debug_info @sp_name
			,'6';



	drop table if exists #base_principal_rest;
	select external_id
			,d --r_date on d
			,[остаток од]  --principal_rest 
			,r_month  =datefromparts(r_year, r_month, 1) --добавленно поле
	into #base_principal_rest
	from
	(
		select *
		from dbo.dm_cmrstatbalance
		where 1 = 1
			--and d >= '2018-08-01'  --change r_date --поставил фильтр во внутрь
		/*union all
		select *
		from RiskDWH.dbo.stg_coll_bal_cmr
		where r_date < '2020-04-01' or r_date > '2020-06-30'*/
	)aa
	where 1 = 1
			and d >= '2018-08-01'  --change r_date
	;


	drop table if exists #base_pay_all;
	select 
			bcmr.external_id
			,bcmr.d --r_date on d 
			,cast(bcmr.[сумма поступлений] as int) 'сумма поступлений' --pay_total on [сумма поступлений]
			,r_month  =datefromparts(bcmr.r_year, bcmr.r_month, 1) --добавленно поле
	into #base_pay_all
	from dbo.dm_cmrstatbalance			bcmr  --RiskDWH.dbo.stg_coll_bal_mfo
	where 1 = 1
			and bcmr.[сумма поступлений] > 0  --pay_total on [сумма поступлений]
	;



	EXEC [collection].set_debug_info @sp_name
			,'7';


	drop table if exists #base_dt_jp;
	select 
			jp.number
			,jp.dt_max_submission_claim
			,case when jc.dt_Court_Claim_Sending is not null
				  then jc.dt_Court_Claim_Sending
				  when brc.dt_Receipt_Judgment is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,brc.dt_Receipt_Judgment) * 0.5),jp.dt_max_submission_claim)
				  when eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,eo.dt_Receipt_IL) * 0.33),jp.dt_max_submission_claim)
				  when ep.dt_excitation_ep is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,ep.dt_excitation_ep) * 0.25),jp.dt_max_submission_claim)
				  end dt_Court_Claim_Sending -- дата отправки иска в суд
			,case when brc.dt_Receipt_Judgment is not null
				  then brc.dt_Receipt_Judgment
				  when jc.dt_Court_Claim_Sending is not null and eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jc.dt_Court_Claim_Sending,eo.dt_Receipt_IL) * 0.5),jc.dt_Court_Claim_Sending)
				  when jc.dt_Court_Claim_Sending is not null and ep.dt_excitation_ep is not null
				  then dateadd(dd,(datediff(dd,jc.dt_Court_Claim_Sending,ep.dt_excitation_ep) * 0.33),jc.dt_Court_Claim_Sending)
				  when eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,eo.dt_Receipt_IL) * 0.67),jp.dt_max_submission_claim)
				  when ep.dt_excitation_ep is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,ep.dt_excitation_ep) * 0.5),jp.dt_max_submission_claim)
				  end dt_max_Receipt_Judgment
			,case when eo.dt_Receipt_IL is not null
				  then eo.dt_Receipt_IL
				  when ep.dt_excitation_ep is not null and brc.dt_Receipt_Judgment is not null
				  then dateadd(dd,(datediff(dd,brc.dt_Receipt_Judgment,ep.dt_excitation_ep) * 0.5),brc.dt_Receipt_Judgment)
				  when ep.dt_excitation_ep is not null and jc.dt_Court_Claim_Sending is not null
				  then dateadd(dd,(datediff(dd,jc.dt_Court_Claim_Sending,ep.dt_excitation_ep) * 0.67),jc.dt_Court_Claim_Sending)
				  when ep.dt_excitation_ep is not null and jp.dt_max_submission_claim is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,ep.dt_excitation_ep) * 0.75),jp.dt_max_submission_claim)
				  end dt_max_Receipt_IL
			,ep.dt_excitation_ep
	into #base_dt_jp
	from #Judicial_Proceeding					jp
	left join #Judicial_Claims					jc on jc.JudicialProceedingId = jp.id
	left join #base_Result_Courts				brc on brc.Number = jp.Number
	left join #Enforcement_Orders				eo on eo.DealId = jp.DealId
	left join #Enforcement_Proceeding			ep on ep.DealId = jp.DealId
	where 1=1

			and jp.dt_max_submission_claim is not null
			------------------------------------
			and (case when coalesce(jc.dt_Court_Claim_Sending,jp.dt_max_submission_claim) >= jp.dt_max_submission_claim
					  then 1 else 0 end) = 1
			and (case when coalesce(brc.dt_Receipt_Judgment,coalesce(jc.dt_Court_Claim_Sending,jp.dt_max_submission_claim)) >= coalesce(jc.dt_Court_Claim_Sending,jp.dt_max_submission_claim)
					  then 1 else 0 end) = 1
			and (case when coalesce(eo.dt_Receipt_IL,coalesce(brc.dt_Receipt_Judgment,coalesce(jc.dt_Court_Claim_Sending,jp.dt_max_submission_claim))) >= coalesce(brc.dt_Receipt_Judgment,coalesce(jc.dt_Court_Claim_Sending,jp.dt_max_submission_claim))
					  then 1 else 0 end) = 1
			and (case when coalesce(ep.dt_excitation_ep,coalesce(eo.dt_Receipt_IL,coalesce(brc.dt_Receipt_Judgment,coalesce(jc.dt_Court_Claim_Sending,jp.dt_max_submission_claim)))) >= coalesce(eo.dt_Receipt_IL,coalesce(brc.dt_Receipt_Judgment,coalesce(jc.dt_Court_Claim_Sending,jp.dt_max_submission_claim)))
					  then 1 else 0 end) = 1
	;



	EXEC [collection].set_debug_info @sp_name
			,'8';

	drop table if exists #base_pay_jp_month;
	with base_pay_all as
	(
	select bdj.*
			,bpa.*
	from #base_dt_jp				bdj
	join #base_pay_all				bpa on bpa.external_id = bdj.Number
	)
	select distinct
			b1.number 
			,b1.r_month--[collection].dt_st_month(b1.d) r_month
			,coalesce(b2.sum_pay_jp_all,0) sum_pay_jp_all
			,coalesce(b3.sum_pay_submission_claim,0) sum_pay_submission_claim
			,coalesce(b4.sum_pay_Court_Claim_Sending,0) sum_pay_Court_Claim_Sending
			,coalesce(b5.sum_pay_Receipt_Judgment,0) sum_pay_Receipt_Judgment
			,coalesce(b6.sum_pay_Receipt_IL,0) sum_pay_Receipt_IL
			,coalesce(b7.sum_pay_excitation_ep,0) sum_pay_excitation_ep
	into #base_pay_jp_month
	from base_pay_all															b1
	left join (select number
						,r_month--[collection].dt_st_month(d) r_month
						,sum(coalesce([сумма поступлений],0)) sum_pay_jp_all
				from base_pay_all
				where d >= dt_max_submission_claim
				group by number
						,r_month--[collection].dt_st_month(d)
				)																b2 on b2.Number = b1.Number
																					and b2.r_month =b1.r_month--- [collection].dt_st_month(b1.d)
	left join (select number
						,r_month--[collection].dt_st_month(d) r_month
						,sum(coalesce([сумма поступлений],0)) sum_pay_submission_claim
				from base_pay_all
				where d between dt_max_submission_claim and coalesce(dateadd(dd,-1,dt_Court_Claim_Sending),getdate())
				group by number
							,r_month--[collection].dt_st_month(d)
				)																b3 on b3.Number = b1.Number
																					and b3.r_month = b1.r_month--[collection].dt_st_month(b1.d)
	left join (select number
						,r_month--[collection].dt_st_month(d) r_month
						,sum(coalesce([сумма поступлений],0)) sum_pay_Court_Claim_Sending
				from base_pay_all
				where d between dt_Court_Claim_Sending and coalesce(dateadd(dd,-1,dt_max_Receipt_Judgment),getdate())
				group by number
							,r_month--[collection].dt_st_month(d)
				)																b4 on b4.Number = b1.Number
																					and b4.r_month =b1.r_month-- [collection].dt_st_month(b1.d)
	left join (select number
						,r_month--[collection].dt_st_month(d) r_month
						,sum(coalesce([сумма поступлений],0)) sum_pay_Receipt_Judgment
				from base_pay_all
				where d between dt_max_Receipt_Judgment and coalesce(dateadd(dd,-1,dt_max_Receipt_IL),getdate())
				group by number
							,r_month--[collection].dt_st_month(d)
				)																b5 on b5.Number = b1.Number
																					and b5.r_month =b1.r_month-- [collection].dt_st_month(b1.d)
	left join (select number
						,r_month--[collection].dt_st_month(d) r_month
						,sum(coalesce([сумма поступлений],0)) sum_pay_Receipt_IL
				from base_pay_all
				where d between dt_max_Receipt_IL and coalesce(dateadd(dd,-1,dt_excitation_ep),getdate())
				group by number
							,r_month--[collection].dt_st_month(d)
				)																b6 on b6.Number = b1.Number
																					and b6.r_month = b1.r_month--[collection].dt_st_month(b1.d)
	left join (select number
						,r_month--[collection].dt_st_month(d) r_month
						,sum(coalesce([сумма поступлений],0)) sum_pay_excitation_ep
				from base_pay_all
				where d between dt_excitation_ep and getdate()
				group by number
							,r_month--[collection].dt_st_month(d)
				)																b7 on b7.Number = b1.Number
																					and b7.r_month = b1.r_month--[collection].dt_st_month(b1.d)
	where 1 = 1
			and coalesce(b2.sum_pay_jp_all,0) > 0
	;



	EXEC [collection].set_debug_info @sp_name
			,'9';


drop table if exists #base_pay_jp_stage;
	with base_pay_all as
	(
	select bdj.*
			,bpa.*
	from #base_dt_jp				bdj
	join #base_pay_all				bpa on bpa.external_id = bdj.Number
	)
	select distinct
			b1.number 
			,coalesce(b2.sum_pay_jp_all,0) sum_pay_jp_all
			,coalesce(b3.sum_pay_submission_claim,0) sum_pay_submission_claim
			,coalesce(b4.sum_pay_Court_Claim_Sending,0) sum_pay_Court_Claim_Sending
			,coalesce(b5.sum_pay_Receipt_Judgment,0) sum_pay_Receipt_Judgment
			,coalesce(b6.sum_pay_Receipt_IL,0) sum_pay_Receipt_IL
			,coalesce(b7.sum_pay_excitation_ep,0) sum_pay_excitation_ep
	into #base_pay_jp_stage
	from base_pay_all															b1
	left join (select number
						,sum(coalesce([сумма поступлений],0)) sum_pay_jp_all
				from base_pay_all
				where d >= dt_max_submission_claim
				group by number
				)																b2 on b2.Number = b1.Number
	left join (select number
						,sum(coalesce([сумма поступлений],0)) sum_pay_submission_claim
				from base_pay_all
				where d between dt_max_submission_claim and coalesce(dateadd(dd,-1,dt_Court_Claim_Sending),getdate())
				group by number
				)																b3 on b3.Number = b1.Number
	left join (select number
						,sum(coalesce([сумма поступлений],0)) sum_pay_Court_Claim_Sending
				from base_pay_all
				where d between dt_Court_Claim_Sending and coalesce(dateadd(dd,-1,dt_max_Receipt_Judgment),getdate())
				group by number
				)																b4 on b4.Number = b1.Number
	left join (select number
						,sum(coalesce([сумма поступлений],0)) sum_pay_Receipt_Judgment
				from base_pay_all
				where d between dt_max_Receipt_Judgment and coalesce(dateadd(dd,-1,dt_max_Receipt_IL),getdate())
				group by number
				)																b5 on b5.Number = b1.Number
	left join (select number
						,sum(coalesce([сумма поступлений],0)) sum_pay_Receipt_IL
				from base_pay_all
				where d between dt_max_Receipt_IL and coalesce(dateadd(dd,-1,dt_excitation_ep),getdate())
				group by number
				)																b6 on b6.Number = b1.Number
	left join (select number
						,sum(coalesce([сумма поступлений],0)) sum_pay_excitation_ep
				from base_pay_all
				where d between dt_excitation_ep and getdate()
				group by number
				)																b7 on b7.Number = b1.Number
	where 1 = 1
			and coalesce(b2.sum_pay_jp_all,0) > 0
	;

	drop table if exists #base_bucket_dpd_max_;
	select Number
			,dpd_61_hs
			,dt_fir_dpd_61_hs
	into #base_bucket_dpd_max_
	from
	(
		select d.Number
				,cast(dh.newvalue as int) dpd_61_hs
				,cast(dh.changedate as date) dt_fir_dpd_61_hs
				,ROW_NUMBER() over (partition by dh.ObjectId order by cast(dh.newvalue as int), dh.changedate) rn
		from stg._Collection.dealhistory dh
		join stg._Collection.deals d on d.Id = dh.ObjectId 
		where 1 = 1
				and dh.field = 'Количество дней просрочки'
				and cast(dh.newvalue as int) between 61 and 65 
				and cast(dh.changedate as date) >= cast(d.CreditVacationDateEnd as date)
	)bb
	where rn = 1
	;


	EXEC [collection].set_debug_info @sp_name
			,'10';


	drop table if exists #jp_sum_pay_jp_stage;
	select distinct
			d.number
			,1 cnt
			,case when bdc.Number is not null
				  then '10.договор закрыт'
				  when bdjp.dt_excitation_ep is not null
				  then '06.испол.производство возбуждено'
				  when bdjp.dt_max_Receipt_IL is not null 
				  then '05.получен ИЛ'
				  when bdjp.dt_max_Receipt_Judgment is not null
				  then '04.получено решение суда'
				  when bdjp.dt_Court_Claim_Sending is not null
				  then '03.иск направлен в суд'
				  when bdjp.dt_max_submission_claim is not null
				  then '02.требование направлено должнику'
				  end 'Стадия СП'
			,bdjp.dt_max_submission_claim 'Дата начала СП'
			,[collection].dt_st_month(bdjp.dt_max_submission_claim) 'Месяц начала СП'
			,datepart(mm,bdjp.dt_max_submission_claim) 'Порядковый номер месяца начала СП'
			,datepart(yy,bdjp.dt_max_submission_claim) 'Год начала СП' 
			,case when bdjp.dt_max_submission_claim is null then 0 else 1 end 'Флаг отправки ЗТ'
			,bdjp.dt_max_submission_claim 'Дата отправки ЗТ'
			,case when bdjp.dt_Court_Claim_Sending is null then 0 else 1 end 'Флаг подачи иска'
			,bdjp.dt_Court_Claim_Sending 'Дата подачи иска'
			,case when bdjp.dt_max_Receipt_Judgment is null then 0 else 1 end 'Флаг получения решения'
			,bdjp.dt_max_Receipt_Judgment 'Дата получения решения'
			,case when bdjp.dt_max_Receipt_IL is null then 0 else 1 end 'Флаг получения ИЛ'
			,bdjp.dt_max_Receipt_IL 'Дата получения ИЛ'
			,case when bdjp.dt_excitation_ep is null then 0 else 1 end 'Флаг возбуждения ИП'
			,bdjp.dt_excitation_ep 'Дата возбуждения ИП'
			,'Долг на старте СП' = 
										cast((select max(debt) from (VALUES (coalesce(jc.AmountJudgment,0))
																			, (coalesce(jp.amountclaim,0))
																			, (coalesce(bpr_1.[остаток од],bpr_2.[остаток од])))  AS value(debt)) as int)
			,coalesce(bpjp.sum_pay_jp_all,0) 'Cash за время СП' -- sum_pay_jp_all
			,coalesce(bpjp.sum_pay_submission_claim,0) 'Cash стадии Отправка требования'
			,coalesce(bpjp.sum_pay_Court_Claim_Sending,0) 'Cash стадии Подача иска'
			,coalesce(bpjp.sum_pay_Receipt_Judgment,0) 'Cash стадии Получено решение'
			,coalesce(bpjp.sum_pay_Receipt_IL,0) 'Cash стадии Получен ИЛ'
			,coalesce(bpjp.sum_pay_excitation_ep,0) 'Cash стадии Возбуждено ИП'

	INTO  #jp_sum_pay_jp_stage
	from stg._Collection.Deals							d
	left join #Judicial_Proceeding						jp on jp.DealId = d.Id
	left join #Judicial_Claims							jc on jc.JudicialProceedingId = jp.Id
	left join #base_Result_Courts						brc on brc.Number = d.Number
	left join #Enforcement_Orders						eo on eo.DealId = d.Id
	left join #base_problematic_status					bps on bps.Number = d.Number
	left join #base_deal_closed							bdc on bdc.Number = d.Number
	left join #base_deal_denied							bdd on bdd.Number = d.Number
	left join #base_bucket_dpd_max_						bbd on bbd.Number = d.Number
	left join #base_principal_rest						bpr_1 on bpr_1.external_id = d.Number
																and bpr_1.d = coalesce(jp.dt_max_submission_claim,bbd.dt_fir_dpd_61_hs) --change r_date on d
	left join #base_principal_rest						bpr_2 on bpr_2.external_id = d.Number
																and bpr_2.d = (select max(d) from #base_principal_rest) --change r_date on d
	left join #base_dt_closed							bdtc on bdtc.number = d.number 
	left join #base_dt_jp								bdjp on bdjp.Number = d.Number
	left join #base_pay_jp_stage						bpjp on bpjp.Number = d.Number


	where 1 = 1
			and bdjp.dt_max_submission_claim is not null -- дата отправки ЗТ не является null
			and (case when bdd.Number is not null
					  then 0
					  when bps.Number is not null
						   and bdc.Number is null
					  then 0
					  when jp.dt_max_submission_claim >= bdtc.dt_closed
					  then 0
					  when jp.id is not null 
					  then 1
					  else 0 end) = 1 
	;



	EXEC [collection].set_debug_info @sp_name
			,'11';



			BEGIN TRANSACTION

	delete from [collection].[say_jp_sym_pay_jp_stage];
	insert [collection].[say_jp_sym_pay_jp_stage] (

	 [Год начала СП]
      ,[Долг на старте СП]
      ,[Cash за время СП]
      ,[Cash стадии Отправка требования]
      ,[Cash стадии Подача иска]
      ,[Cash стадии Получено решение]
      ,[Cash стадии Получен ИЛ]
      ,[Cash стадии Возбуждено ИП]
      ,[Доля Cash СП от портфеля СП]
      ,[Доля Cash стадии Отправка требования от портфеля СП]
      ,[Доля Cash стадии Подача иска от портфеля СП]
      ,[Доля Cash стадии Получено решение от портфеля СП]
      ,[Доля Cash стадии Получен ИЛ от портфеля СП]
      ,[Доля Cash стадии Возбуждено ИП от портфеля СП]
      ,[Доля Cash стадии Отправка требования от Cash СП]
      ,[Доля Cash стадии Подача иска от Cash СП]
      ,[Доля Cash стадии Получено решение от Cash СП]
      ,[Доля Cash стадии Получен ИЛ от Cash СП]
      ,[Доля Cash стадии Возбуждено ИП от Cash СП]

	  )

	select
			[Год начала СП]
			,sum([Долг на старте СП]) 'Долг на старте СП'
			,sum([Cash за время СП]) 'Cash за время СП'
			,sum([Cash стадии Отправка требования]) 'Cash стадии Отправка требования'
			,sum([Cash стадии Подача иска]) 'Cash стадии Подача иска'
			,sum([Cash стадии Получено решение]) 'Cash стадии Получено решение'
			,sum([Cash стадии Получен ИЛ]) 'Cash стадии Получен ИЛ'
			,sum([Cash стадии Возбуждено ИП]) 'Cash стадии Возбуждено ИП'
			,isnull(cast(sum([Cash стадии Возбуждено ИП]) as float) / nullif(cast(sum([Долг на старте СП]) as float),0),0) 'Доля Cash СП от портфеля СП'
			,isnull(cast(sum([Cash стадии Отправка требования]) as float) / nullif(cast(sum([Долг на старте СП]) as float),0),0) 'Доля Cash стадии Отправка требования от портфеля СП'
			,isnull(cast(sum([Cash стадии Подача иска]) as float) / nullif(cast(sum([Долг на старте СП]) as float),0),0) 'Доля Cash стадии Подача иска от портфеля СП'
			,isnull(cast(sum([Cash стадии Получено решение]) as float) / nullif(cast(sum([Долг на старте СП]) as float),0),0) 'Доля Cash стадии Получено решение от портфеля СП'
			,isnull(cast(sum([Cash стадии Получен ИЛ]) as float) / nullif(cast(sum([Долг на старте СП]) as float),0),0) 'Доля Cash стадии Получен ИЛ от портфеля СП'
			,isnull(cast(sum([Cash стадии Возбуждено ИП]) as float) / nullif(cast(sum([Долг на старте СП]) as float),0),0) 'Доля Cash стадии Возбуждено ИП от портфеля СП'
			,isnull(cast(sum([Cash стадии Отправка требования]) as float) / nullif(cast(sum([Cash за время СП]) as float),0),0) 'Доля Cash стадии Отправка требования от Cash СП'
			,isnull(cast(sum([Cash стадии Подача иска]) as float) / nullif(cast(sum([Cash за время СП]) as float),0),0) 'Доля Cash стадии Подача иска от Cash СП'
			,isnull(cast(sum([Cash стадии Получено решение]) as float) / nullif(cast(sum([Cash за время СП]) as float),0),0) 'Доля Cash стадии Получено решение от Cash СП'
			,isnull(cast(sum([Cash стадии Получен ИЛ]) as float) / nullif(cast(sum([Cash за время СП]) as float),0),0) 'Доля Cash стадии Получен ИЛ от Cash СП'
			,isnull(cast(sum([Cash стадии Возбуждено ИП]) as float) / nullif(cast(sum([Cash за время СП]) as float),0),0) 'Доля Cash стадии Возбуждено ИП от Cash СП'


			/*,cast(sum([Cash стадии Возбуждено ИП]) as float) / cast(sum([Долг на старте СП]) as float) 'Доля Cash СП от портфеля СП'
			,cast(sum([Cash стадии Отправка требования]) as float) / cast(sum([Долг на старте СП]) as float) 'Доля Cash стадии Отправка требования от портфеля СП'
			,cast(sum([Cash стадии Подача иска]) as float) / cast(sum([Долг на старте СП]) as float) 'Доля Cash стадии Подача иска от портфеля СП'
			,cast(sum([Cash стадии Получено решение]) as float) / cast(sum([Долг на старте СП]) as float) 'Доля Cash стадии Получено решение от портфеля СП'
			,cast(sum([Cash стадии Получен ИЛ]) as float) / cast(sum([Долг на старте СП]) as float) 'Доля Cash стадии Получен ИЛ от портфеля СП'
			,cast(sum([Cash стадии Возбуждено ИП]) as float) / cast(sum([Долг на старте СП]) as float) 'Доля Cash стадии Возбуждено ИП от портфеля СП'
			,cast(sum([Cash стадии Отправка требования]) as float) / cast(sum([Cash за время СП]) as float) 'Доля Cash стадии Отправка требования от Cash СП'
			,cast(sum([Cash стадии Подача иска]) as float) / cast(sum([Cash за время СП]) as float) 'Доля Cash стадии Подача иска от Cash СП'
			,cast(sum([Cash стадии Получено решение]) as float) / cast(sum([Cash за время СП]) as float) 'Доля Cash стадии Получено решение от Cash СП'
			,cast(sum([Cash стадии Получен ИЛ]) as float) / cast(sum([Cash за время СП]) as float) 'Доля Cash стадии Получен ИЛ от Cash СП'
			,cast(sum([Cash стадии Возбуждено ИП]) as float) / cast(sum([Cash за время СП]) as float) 'Доля Cash стадии Возбуждено ИП от Cash СП'*/
	from
			#jp_sum_pay_jp_stage
	group by 
			[Год начала СП]


	
     COMMIT TRANSACTION


  EXEC [collection].set_debug_info @sp_name
			,'Finish';


		
	end try
begin catch
	SET @msg = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		SET @subject = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
/* отправка на почту уведомления есть требуется доп уведомление об ошибке.*/
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 's.pischaev@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
end catch
END
