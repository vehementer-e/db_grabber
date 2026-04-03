

CREATE   procedure [dbo].[create_say_deals_all_for_jp]

as
begin
---------------------------------------------------------------------------------------------------
	--госпошлина оплачена
	drop table if exists #sum_dt_StateDuty;
	select 
			d.number
			,dbo.customer_fio(d.IdCustomer) fio_customer
			,max(cast(coalesce(jc.ClaimInCourtDate,jc.CourtClaimSendingDate) as date)) dt_payment_StateDuty
			,max(devdb.dbo.dt_st_month(cast(coalesce(jc.ClaimInCourtDate,jc.CourtClaimSendingDate) as date))) mn_payment_StateDuty
			--,cast(coalesce(jc.StateDutyOnJudgment,jc.StateDutyOnClaim) as numeric) sum_StateDuty
			--,row_number() over (partition by d.number order by cast(coalesce(jc.ClaimInCourtDate,jc.CourtClaimSendingDate) as date) desc) rn
	into #sum_dt_StateDuty
	from Stg._Collection.JudicialClaims							jc
	join Stg._Collection.JudicialProceeding						jp on jp.Id = jc.JudicialProceedingId
	join stg._Collection.Deals									d on d.id = jp.dealid
	where 1 = 1
			and cast(coalesce(jc.ClaimInCourtDate,jc.CourtClaimSendingDate) as date) is not null
			and  exists  (select top(1) 1 
							from stg._Collection.[JudicialClaimHistory]
							where ObjectId =jc.id 
							) -- отсекаются иски, которые создаются системой в момент направления ЗТ. то есть сущность иск создается, но фактически иск в суд еще не отправлялся. у такой сущности нет истории изменений/заполнений, поэттому в таблице истории по ней нет данных.
			and cast(coalesce(jc.StateDutyOnJudgment,jc.StateDutyOnClaim) as numeric) > 0
			and datepart(yy,cast(coalesce(jc.ClaimInCourtDate,jc.CourtClaimSendingDate) as date)) <= datepart(yy,getdate())
	group by d.number
			,dbo.customer_fio(d.IdCustomer)
	;

---------------------------------------------------------------------------------------------------
	-- база договоров с оплаченной гп
	drop table if exists #say_deals_all_for_jp;
	select distinct
			d.id id_deal_space
			,d.number
			,devdb.dbo.dt_st_month(d.date) mn_st_credit
			--,d.interestrate rate_in_space
			--,vc.[percent] rate_in_v_credits
			,case when coalesce(d.interestrate,0) < 20 then coalesce(vc.[percent],0) else coalesce(d.interestrate,0) end rate_agg
			,case when md.return_type = 'Параллельный'
				  then 'Докредитование'
				  else md.return_type
				  end type_credit
			,case when sdsd.number is not null then 1 else 0 end fl_payment_StateDuty
			,sdsd.dt_payment_StateDuty
			,sdsd.mn_payment_StateDuty
			,datepart(yy,sdsd.mn_payment_StateDuty) yr_payment_StateDuty
			,cmr.[остаток всего] debt_all
			--,bp.sum_pay
			--,datediff(mm,sdsd.mn_payment_StateDuty,devdb.dbo.dt_st_month(bp.dt_pay)) period_pay
	into #say_deals_all_for_jp
	from stg._collection.deals					d
	left join dwh_new.dbo.tmp_v_credits			vc on vc.external_id = d.number
	left join #sum_dt_StateDuty					sdsd on sdsd.number = d.number
	join dbo.dm_CMRStatBalance_2		cmr on cmr.external_id = d.number -- несколько договоров с оплатой гп в нужную дату не ищутся в этой таблице, поэтому я использовал это соединение, чтобы исключить эти договора из выборки, а не указывать им нулевой долг
													and cmr.d = sdsd.dt_payment_StateDuty
													and cmr.[остаток всего] > 0 --Добавление 28.09 согласованос с Николаем.
	join dbo.dm_maindata				md on md.external_id = d.number
	where 1 = 1
			and (case when coalesce(d.interestrate,0) < 20 then coalesce(vc.[percent],0) else coalesce(d.interestrate,0) end) > 0
			and (case when sdsd.number is not null then 1 else 0 end) = 1
	;
	if OBJECT_ID('dbo.say_deals_all_for_jp') is null
	begin
		select top(0) 
		*
		into dbo.say_deals_all_for_jp
		from #say_deals_all_for_jp
	end
	begin
		delete from dbo.say_deals_all_for_jp
		insert into dbo.say_deals_all_for_jp
		select * from #say_deals_all_for_jp
	end
end
