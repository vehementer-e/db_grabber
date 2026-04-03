---------------------------------------------------------------------------------------------------
create   procedure dbo.create_say_deals_all_for_jp_for_vintag
as
begin
	--сбор платежей для винтажа
	drop table if exists #sum_pay_for_vint;
	select 
			bcmr.external_id
			,devdb.dbo.dt_st_month(bcmr.cdate) mn_pay
			,sum(bcmr.total_CF) sum_pay -- cash
	into #sum_pay_for_vint
	from dwh_new.dbo.stat_v_balance2				bcmr
	left join dbo.say_deals_all_for_jp				aa on aa.Number = bcmr.external_id
	where 1 = 1
			and bcmr.total_CF > 0
			and bcmr.cdate >= aa.dt_payment_StateDuty
	group by 
			bcmr.external_id
			,devdb.dbo.dt_st_month(bcmr.cdate)
	;

---------------------------------------------------------------------------------------------------
	drop table if exists #base_vintage_analysis;
	select djp.number
			,djp.dt_payment_StateDuty --dt_st_Judicial_Proceeding
			,djp.mn_payment_StateDuty mn_rp_for_vintag --mn_rp_Judicial_Proceeding
			,1 mob
			,djp.debt_all debt
			,djp.type_credit
	into #base_vintage_analysis
	from dbo.say_deals_all_for_jp	 djp
	;
	
	DECLARE @i int = 1;
	WHILE (select max(mn_rp_for_vintag) 
			from #base_vintage_analysis 
			where dt_payment_StateDuty = (select min(dt_payment_StateDuty) from #base_vintage_analysis)
			) < devdb.dbo.dt_st_month(getdate())
		BEGIN
			insert #base_vintage_analysis (number,dt_payment_StateDuty,mn_rp_for_vintag,mob,debt,type_credit)
			select  number
					,dt_payment_StateDuty
					,dateadd(mm,1,mn_rp_for_vintag)
					,mob + 1
					,debt
					,type_credit
			from #base_vintage_analysis
			where mob = @i
		SET @i = @i + 1
		END
	;

	drop table if exists #say_deals_all_for_jp_for_vintag

	select distinct
			bva.number
			,devdb.dbo.dt_st_month(bva.dt_payment_StateDuty) mn_payment_StateDuty
			,bva.mn_rp_for_vintag
			,bva.mob
			,bva.debt
			,coalesce(sum(bp.sum_pay) over (partition by bva.number, bva.mob) ,0)  sum_pay
			,coalesce(sum(bp.sum_pay) over (partition by bva.number order by bva.mob 
											 rows between unbounded preceding and current row) ,0) as sum_pay_cumulatively
			,case when coalesce(sum(bp.sum_pay) over (partition by bva.number order by bva.mob 
											 rows between unbounded preceding and current row) ,0) / bva.debt > 1
				  then 1
				  else coalesce(sum(bp.sum_pay) over (partition by bva.number order by bva.mob 
											 rows between unbounded preceding and current row) ,0) / bva.debt
				  end percent_recovery
			,datepart(yy,devdb.dbo.dt_st_month(bva.dt_payment_StateDuty)) yr_payment_StateDuty
			,bva.type_credit
	into #say_deals_all_for_jp_for_vintag
	from #base_vintage_analysis			bva
	left join #sum_pay_for_vint			bp on bp.external_id = bva.number
											  and bp.mn_pay = bva.mn_rp_for_vintag
	;

	if OBJECT_ID('dbo.say_deals_all_for_jp_for_vintag') is null
	begin
		select top(0)
		* 
		into dbo.say_deals_all_for_jp_for_vintag
		from #say_deals_all_for_jp_for_vintag

	end
	begin
		delete from dbo.say_deals_all_for_jp_for_vintag
	
		insert into dbo.say_deals_all_for_jp_for_vintag
		select 
		* 
		from #say_deals_all_for_jp_for_vintag
	end 
end
