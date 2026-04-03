

--exec [Risk].[Create_dm_CollectionUpdateDailyPlan]

CREATE procedure [Risk].[Create_dm_CollectionUpdateDailyPlan]
WITH RECOMPILE 
as

declare @rdt date = cast(getdate() as date);
declare @srcname varchar(100) = 'UPDATE_COLL_DAILY_PLAN';
declare @flag_has_holid bit = 1;


SET DATEFIRST 1	  

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'START';

if (select count(*) from RiskDWH.dbo.det_coll_plan_basis a
where a.plan_month = EOMONTH(@rdt)) > 0 

begin 
             
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#a11';

	drop table if exists #a11;

	with stg_coll_bal as 
		(select d as r_date,
			r_year,
			r_month,
    		r_day,
    		external_id,
    		isnull(dpd_coll,0)                     as overdue_days,
    		isnull(dpd_p_coll,0)                   as overdue_days_p,
    		cast(isnull([остаток од],   0) as float) as principal_rest,
    		cast(isnull([остаток од],   0) as float) +
    		cast(isnull([остаток %],    0) as float) as principal_percents_rest,
    		cast(isnull(principal_cnl,    0) as float) +
    		cast(isnull(percents_cnl,     0) as float) +
    		cast(isnull(fines_cnl,        0) as float) +
    		cast(isnull(otherpayments_cnl,0) as float) +
    		cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) as pay_total,
			isnull([сумма поступлений], 0) as pay_total_calc,
    		prev_dpd_coll as lag_overdue_days,
    		prev_od as lag_principal_rest,
    		bucket_coll as bucket_coll,
    		bucket_p_coll as bucket_p_coll,
			case when [Тип Продукта] = 'PDL' then 'INSTALLMENT' 
				 when [Тип Продукта] in ('ПТС',  'ПТС31') then 'PTS' 
				 when [Тип Продукта] = 'Инстоллмент' then 'INSTALLMENT' 
				 end as product
		from [dwh2].[dbo].[dm_CMRStatBalance]
		)
	/*Выводим исторический факт за день*/
	select a.product, a.r_year, a.r_month, a.r_day, a.r_date,     
			case
			when h.r_date is not null
			then 0 
			else DATEPART(dw,a.r_date) 
			end as dw,
		   --c.dpd_bucket,
		   a.bucket_coll as dpd_bucket,
		  a.pay_total
	into #a11
	from stg_coll_bal a --RiskDWH.dbo.stg_coll_bal_mfo a
	inner join RiskDWH.dbo.det_coll_plan_basis b
	on a.r_year = b.r_year
	and a.r_month = b.r_month
	and b.plan_month = eomonth(@rdt)
	--inner join RiskDWH.dbo.stg_coll_bal_cmr c
	--inner join #CMR_bal_bal c
	--on a.external_id = c.external_id
	--and a.r_date = c.r_date
	left join RiskDWH.dbo.det_holidays h --30/12/20 - добавлен справочник с праздничными днями
	on a.r_date = h.r_date
	--left join #stg_product pr --2022-02-09
	--on a.external_id = pr.external_id
	where a.pay_total>0 
	and a.bucket_coll <> '(1)_0'
	and a.r_date >= '2019-01-01'
	; 

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#a15_alt';


	--доля сбора для дня недели (от 0 до 7) внутри каждого бакета 
	drop table if exists #a15_alt;

	with product_base as (
		select cast('PTS' as varchar(100)) as product
		union all
		select cast('INSTALLMENT' as varchar(100)) as product
	), bucket_base as 
	(
		select cast('(2)_1_30' as varchar(50)) as dpd_bucket 
		union all
		select cast('(3)_31_60' as varchar(50)) as dpd_bucket 
		union all
		select cast('(4)_61_90' as varchar(50)) as dpd_bucket 
		union all
		select cast('(5)_91_360' as varchar(50)) as dpd_bucket 
		union all
		select cast('(6)_361+' as varchar(50)) as dpd_bucket 
	),
	weekday_base as (
		select cast(0 as smallint) as dw 
		union all 
		select cast(1 as smallint) as dw 
		union all 
		select cast(2 as smallint) as dw 
		union all 
		select cast(3 as smallint) as dw 
		union all 
		select cast(4 as smallint) as dw 
		union all 
		select cast(5 as smallint) as dw 
		union all 
		select cast(6 as smallint) as dw 
		union all 
		select cast(7 as smallint) as dw 
	),
	sum_buck as (
		select a.product, a.dpd_bucket, sum(a.pay_total) as pmt
		from #a11 a
		group by a.product, a.dpd_bucket
	),
	sum_dw as (
		select a.product, a.dpd_bucket, a.dw, sum(a.pay_total) as pmt
		from #a11 a
		group by a.product, a.dpd_bucket, a.dw
	), 
	total as (
		select d.product, d.dpd_bucket, d.dw, d.pmt / b.pmt as dolya
		from sum_dw d
		left join sum_buck b
		on d.dpd_bucket = b.dpd_bucket
		and d.product = b.product
	)
	select bb.product, bb.dpd_bucket, bb.dw, isnull(t.dolya,0) as dolya

		into #a15_alt

	from (select product, dpd_bucket, dw from bucket_base 
					cross join weekday_base
					cross join product_base
					) bb
	left join total t
	on t.dpd_bucket = bb.dpd_bucket
	and t.dw = bb.dw
	and t.product = bb.product
	;


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#a16';


	--маркировка дней недели для собираемого месяца ( 0 - праздник )

	drop table if exists #a16;

	with prod as (
		select cast('PTS' as varchar(100)) as product
		union all
		select cast('INSTALLMENT' as varchar(100)) as product
 	), cal as (
		select dateadd(dd,1,eomonth(@rdt,-1)) as r_date
		union all
		select dateadd(dd,1,r_date) from cal
		where r_date < eomonth(@rdt)
	)
	select 
	p.product,
	cal.r_date,
	case 
	--Праздники
	when h.r_date is not null
	then 0 
	else DATEPART(dw,cal.r_date) 
	end as dw
	into #a16
	
	from cal
	left join RiskDWH.dbo.det_holidays h --30/12/20 - добавлен справочник с праздничными днями
	on cal.r_date = h.r_date
	left join prod as p
	on 1=1

	order by 1,2,3;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'check for holidays';


	--проверяем, есть ли праздничные дни в месяце
	set @flag_has_holid = 
	(select case when count(*) > 0 then 1 else 0 end
	from #a16 a
	where a.dw = 0);

	if @flag_has_holid = 0 
		begin

			merge into #a15_alt dst
			using (
				select  a.product, a.dpd_bucket, a.dw, a.dolya,
				case 
				when sum(a.dolya) over (partition by a.product, a.dpd_bucket) = 0
				then 0
				else a.dolya / sum(a.dolya) over (partition by a.product, a.dpd_bucket) end as new_dolya
				from #a15_alt a
				where a.dw <> 0
			) src 
			on (dst.product = src.product and dst.dpd_bucket = src.dpd_bucket and dst.dw = src.dw)
			when matched then update set dst.dolya = src.new_dolya;

		end


	if @rdt <= '2022-05-31' --пока нет статистики по INSTALLMENT используем доли для ПТС
	begin

		update a set a.dolya = b.dolya
		from #a15_alt a
		inner join #a15_alt b
		on a.dpd_bucket = b.dpd_bucket
		and a.dw = b.dw
		and b.product = 'PTS'
		where a.product = 'INSTALLMENT'
	
	end



	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#a18';

	--факт приведенный баланс (1-90)

	drop table if exists #a18;
	with factbal as (
		select 
			a.product,
			DATEFROMPARTS(a.r_year, a.r_month, a.r_end_day) as rdt, 
			a.dpd_bucket, a.dpd_bucket_end, 
			sum(a.total_balance) as total_balance
		from [Risk].[dm_ReportCollectionPlanRollBalance] a --RiskDWH.dbo.rep_coll_plan_galina a
		--отчетная дата (не путать с r_date!) - в таблице хранятся сразу несколько отчетных дат, каждая из которых представлена несколькими срезами (r_date)
		--то есть отчет по состоянию на rep_dt
		where a.rep_dt = dateadd(dd, -1, cast(getdate() as date)) 
			--даты срезов
			and a.r_year = year(@rdt)
			and a.r_month = month(@rdt)
			--только переходы в низшие бакеты
			and (
			(a.dpd_bucket = '(2)_1_30' and a.dpd_bucket_end = '(1)_0')
			or (a.dpd_bucket = '(3)_31_60' and a.dpd_bucket_end in ('(1)_0','(2)_1_30') )
			or (a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end in ('(1)_0','(2)_1_30','(3)_31_60') )		
			)
		group by a.product,
			DATEFROMPARTS(a.r_year, a.r_month, a.r_end_day), 
			a.dpd_bucket, a.dpd_bucket_end
	)
	select f.product, f.rdt, f.dpd_bucket, 
		sum(f.total_balance * (isnull(cc.k1,1)-isnull(cc.k2,0)) / isnull(cc.k1,1)) as total_bal_priv

		into #a18

	from factbal f
	left join RiskDWH.dbo.det_coll_bucket_migr_adj_coef cc
		on f.dpd_bucket = cc.bucket_from
		and f.dpd_bucket_end = cc.bucket_to
		--and '2020-06-01' between cc.dt_from and cc.dt_to
	group by f.product, f.rdt, f.dpd_bucket;





	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#fact_90_over';

	--факт 90+ cash
	drop table if exists #fact_90_over;

	with stg_coll_bal as 
		(select d as r_date,
			r_year,
			r_month,
    		r_day,
    		external_id,
    		isnull(dpd_coll,0)                     as overdue_days,
    		isnull(dpd_p_coll,0)                   as overdue_days_p,
    		cast(isnull([остаток од],   0) as float) as principal_rest,
    		cast(isnull([остаток од],   0) as float) +
    		cast(isnull([остаток %],    0) as float) as principal_percents_rest,
    		cast(isnull(principal_cnl,    0) as float) +
    		cast(isnull(percents_cnl,     0) as float) +
    		cast(isnull(fines_cnl,        0) as float) +
    		cast(isnull(otherpayments_cnl,0) as float) +
    		cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) as pay_total,
			isnull([сумма поступлений], 0) as pay_total_calc,
    		prev_dpd_coll as lag_overdue_days,
    		prev_od as lag_principal_rest,
    		bucket_coll as bucket_coll,
    		bucket_p_coll as bucket_p_coll,
			case when [Тип Продукта] = 'PDL' then 'PDL' 
				 when [Тип Продукта] in ('ПТС',  'ПТС31') then 'PTS' 
				 when [Тип Продукта] = 'Инстоллмент' then 'INSTALLMENT' 
				 end as product
		from [dwh2].[dbo].[dm_CMRStatBalance]
		)
	select a.r_date, 
	a.bucket_p_coll as dpd_bucket_p_, 
	sum(a.pay_total) as sum_pay_total,
	a.product

	into #fact_90_over

	from stg_coll_bal a --RiskDWH.dbo.stg_coll_bal_mfo a
	--inner join #CMR_bal_bal b
	--on a.external_id = b.external_id 
	--and a.r_date = b.r_date
	--left join #stg_product pr --2022-02-09
	--on a.external_id = pr.external_id
	where a.r_date between dateadd(dd,1,EOMONTH(@rdt,-1)) and dateadd(dd,-1,@rdt)
	and a.bucket_p_coll in ('(5)_91_360','(6)_361+')
	and a.r_date >= '2019-01-01'
	group by a.r_date, a.bucket_p_coll, a.product;


	
	/*Здесь ввести значения планов*/
	drop table if exists #plan;
	with last_vers as 
	(select a.rep_month, max(a.plan_version) as mx_vers
	from RiskDWH.dbo.det_coll_plan a
	where a.rep_month = eomonth( @rdt )
	group by a.rep_month),
	base as (
		select 
		b.product,
		b.rep_month, 
		b.bucket_from,
		sum( b.total_balance * ((isnull(m.k1, 1) - isnull(m.k2, 0)) / isnull(m.k1, 1)) ) as total_bal_adj
		from RiskDWH.dbo.det_coll_plan b
		inner join last_vers l
		on b.rep_month = l.rep_month
		and b.plan_version = l.mx_vers
		left join RiskDWH.dbo.det_coll_bucket_migr_adj_coef m
		on b.bucket_from = m.bucket_from
		and b.bucket_to = m.bucket_to
		group by b.product, b.rep_month, b.bucket_from
		)
	select 
	bs.product,
	bs.rep_month,
	bs.bucket_from,
	bs.total_bal_adj
	into #plan
	from base bs;


	
	
	
	
	
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = '#a17';

	--Таблица с предварительным планом по дням
	drop table if exists #a17

	select a.product, a.r_date, a.dw, b.dpd_bucket, b.dolya, c.d_wk, 
	
	isnull(f.coefficient, b.dolya/d_wk) as dolya_mnth, 
	
	isnull(f.coefficient, b.dolya/d_wk) * p.total_bal_adj as plan_sb,

	case 
	when b.dpd_bucket in ('(2)_1_30','(3)_31_60','(4)_61_90')
	 then e.total_bal_priv
	when b.dpd_bucket in ('(5)_91_360','(6)_361+')
	 then d.sum_pay_total
	else 0 end fact_sb
				--coalesce(d.sum_pay_total, e.total_bal_priv, 0) as fact_sb
	into #a17
	from #a16 a
	left join #a15_alt b
	on a.dw = b.dw
	and a.product = b.product
	left join (select product, dw,count(*) as d_wk from #a16 group by product, dw) as c 
	on a.dw = c.dw 
	and a.product = c.product

	left join #fact_90_over d
	on a.r_date = d.r_date
	and b.dpd_bucket = d.dpd_bucket_p_
	and a.product = d.product

	left join #a18 e
	on a.r_date = e.rdt
	and b.dpd_bucket = e.dpd_bucket
	and a.product = e.product

	left join RiskDWH.dbo.det_coll_daily_plan f
	on a.r_date = f.rep_dt
	and b.dpd_bucket = f.bucket_from
	and a.product = f.product

	left join #plan p
	on b.dpd_bucket = p.bucket_from
	and a.product = p.product

	order by 1,2,3




	--09/08/2021 - обновляем строки с долей, равной нулю, чтобы избежать ошибки Divide by zero
	;with a as (select * from #a17)
	update a set a.dolya_mnth = 10e-20
	where a.dolya_mnth = 0
	;


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'stg_calc_coll_daily_plan';


	/******************* Таблица с планом *************************/
	delete from RiskDWH.dbo.stg_calc_coll_daily_plan
	where date_on = @rdt;


	insert into RiskDWH.dbo.stg_calc_coll_daily_plan
	select 
	@rdt as date_on,
	cast(sysdatetime() as datetime) as dt_dml,
	a.r_date, a.dpd_bucket, a.dolya_mnth, a.plan_sb, a.fact_sb, 
	--накопленный план
	sum(a.plan_sb) over (partition by a.product, a.dpd_bucket order by a.r_date
						rows between unbounded preceding and current row) as plan_acc,
	--накопленный факт
	sum(a.fact_sb) over (partition by a.product, a.dpd_bucket order by a.r_date
						rows between unbounded preceding and current row) as fact_acc,
	--накопленная дельта
	sum(a.plan_sb) over (partition by a.product, a.dpd_bucket order by a.r_date
						rows between unbounded preceding and current row) -
	sum(a.fact_sb) over (partition by a.product, a.dpd_bucket order by a.r_date
						rows between unbounded preceding and current row) as delta_acc,
	--для промежуточных вычислений
	case when day(a.r_date) <= day(dateadd(dd,-1,cast(getdate() as date))) /*9*/ /*= 1*/ then
	sum(a.plan_sb) over (partition by a.product, a.dpd_bucket order by a.r_date
						rows between unbounded preceding and current row) 
		end as tmp_plan_acc,

	case when day(a.r_date) <= day(dateadd(dd,-1,cast(getdate() as date))) /*9*/ /*= 1*/ then
	sum(a.plan_sb) over (partition by a.product, a.dpd_bucket order by a.r_date
						rows between unbounded preceding and current row) -
	sum(a.fact_sb) over (partition by a.product, a.dpd_bucket order by a.r_date
						rows between unbounded preceding and current row)
		end as tmp_delta_acc,

	cast(null as float) as tmp_dolya,

	--пересчитанный план
	case when day(a.r_date) <= day(dateadd(dd,-1,cast(getdate() as date))) /*9*/ /*= 1*/ then a.plan_sb else null end as plan_new,

	a.product

	from #a17 a
	--where a.dpd_bucket = '(2)_1_30'
	order by a.r_date;


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'stg_calc_coll_daily_plan MERGE 1';


	--пересчет долей сегодняшнего дня до конца месяца пропорционально базовой
	merge into RiskDWH.dbo.stg_calc_coll_daily_plan dst
	using (
		select a.product, a.r_date, a.dpd_bucket, 
		a.dolya_mnth / sum(a.dolya_mnth) over (partition by a.product, a.dpd_bucket) as tmp_dolya,
		date_on
		from RiskDWH.dbo.stg_calc_coll_daily_plan a
		where a.r_date >= @rdt
		and a.date_on = @rdt
	) src 
	on (dst.r_date = src.r_date and dst.dpd_bucket = src.dpd_bucket and dst.date_on = src.date_on and dst.product = src.product)
	when matched then update set dst.tmp_dolya = src.tmp_dolya;




	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'stg_calc_coll_daily_plan MERGE 2';

	--пересчет нового плана
	---v1: если накопленная дельта (план - факт) за прошедший день > 0, то старый план + дельта пропорц-но распределенная по дням
	---v2: всегда пересчитываем план на оставшиеся дни, чтобы (сумма плана за оставшиеся дни + накопленный факт) = начальный план на месяц
	---v3: если накопленный план перевыполнен, то оставляем базовый
	merge into RiskDWH.dbo.stg_calc_coll_daily_plan dst
	using (
		select a.product, a.r_date, a.dpd_bucket, 
		--case when b.tmp_delta_acc > 0 then a.plan_sb + b.tmp_delta_acc * a.tmp_dolya
		--else a.plan_sb end as plan_new,
		---a.plan_sb + b.tmp_delta_acc * a.tmp_dolya as plan_new,
		case when b.fact_acc >	p.total_bal_adj
			then a.plan_sb
			else a.plan_sb + b.tmp_delta_acc * a.tmp_dolya 
		end as plan_new,
		a.date_on
		from RiskDWH.dbo.stg_calc_coll_daily_plan a
		left join RiskDWH.dbo.stg_calc_coll_daily_plan b
		on b.r_date = dateadd(dd, -1, @rdt)
		and a.dpd_bucket = b.dpd_bucket
		and a.product = b.product
		and b.date_on = @rdt
		left join #plan p
		on a.dpd_bucket = p.bucket_from
		and a.product = p.product

		where a.r_date >= @rdt
		and a.date_on = @rdt
	) src
	on (dst.r_date = src.r_date and dst.dpd_bucket = src.dpd_bucket and dst.date_on = src.date_on and dst.product = src.product)
	when matched then update set 
	dst.plan_new = src.plan_new;






	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'stg_calc_coll_daily_plan MERGE 3';

	--Расчет новой накопленной дельты с учетом нового плана 
	merge into RiskDWH.dbo.stg_calc_coll_daily_plan dst
	using (
		select product, r_date, dpd_bucket, tmp_plan_acc, tmp_delta_acc, date_on
		from (
			select  a.r_date, a.product, a.dpd_bucket, 
			sum(a.plan_new) over (partition by a.product, a.dpd_bucket order by a.r_date
								rows between unbounded preceding  and current row) as tmp_plan_acc,
			sum(a.plan_new) over (partition by a.product, a.dpd_bucket order by a.r_date
								rows between unbounded preceding  and current row) - a.fact_acc as tmp_delta_acc,
			a.date_on						
			from RiskDWH.dbo.stg_calc_coll_daily_plan a
			where a.r_date <= @rdt
			and a.date_on = @rdt
		) b
		where r_date = @rdt
	) src 
	on (dst.r_date = src.r_date and dst.dpd_bucket = src.dpd_bucket and dst.date_on = src.date_on and dst.product = src.product)
	when matched then update set
	dst.tmp_plan_acc = src.tmp_plan_acc,
	dst.tmp_delta_acc = src.tmp_delta_acc;


	/*************************** FINAL ************************************/

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'coll_daily_plan_dashboard';


	--сорректированные планы для Dashboard
	delete from RiskDWH.dbo.coll_daily_plan_dashboard
	where date_on = @rdt;

	insert into RiskDWH.dbo.coll_daily_plan_dashboard
	select @rdt as date_on, 
	cast(sysdatetime() as datetime) as dt_dml,
	a.r_date, a.dpd_bucket, 

	sum(case when dd.fact_acc > dd.plan_month_base then a.plan_sb /1000000
	else 
		case when a.r_date < cast(getdate() as date) then a.fact_sb/1000000
			 when a.r_date >= cast(getdate() as date) then a.plan_new/1000000
		end
	end) as sum1,
	sum(case when dd.fact_acc > dd.plan_month_base then a.plan_sb /1000000
	else 
		case when a.r_date < cast(getdate() as date) then a.fact_sb/1000000
			 when a.r_date >= cast(getdate() as date) then a.plan_new/1000000
		end
	end) as sum2,
	sum(case when dd.fact_acc > dd.plan_month_base then a.plan_sb /1000000
	else 
		case when a.r_date < cast(getdate() as date) then a.fact_sb/1000000
			 when a.r_date >= cast(getdate() as date) then a.plan_new/1000000
		end
	end) as sum3
	
	from RiskDWH.dbo.stg_calc_coll_daily_plan a

	left join (
		select d.dpd_bucket, d.fact_acc, p.total_bal_adj as plan_month_base, d.product
		from RiskDWH.dbo.stg_calc_coll_daily_plan d
		left join #plan p
		on d.dpd_bucket = p.bucket_from
		and d.product = p.product
		where d.date_on = @rdt
		and d.r_date = dateadd(dd,-1,@rdt)
	) dd
	on a.dpd_bucket = dd.dpd_bucket
	and a.product = dd.product

	where a.date_on = @rdt
	and exists (select 1 from RiskDWH.dbo.det_coll_plan dpl  --17.02.2022
				where eomonth(a.r_date) = dpl.rep_month 
						and a.product = dpl.product
						and a.dpd_bucket = dpl.bucket_from)
	group by a.r_date, a.dpd_bucket

	order by 2,1;


	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'stg_coll_daily_plan_dolya';


	delete from RiskDWH.dbo.stg_coll_daily_plan_dolya
	where date_on = @rdt;

	insert into RiskDWH.dbo.stg_coll_daily_plan_dolya
	select @rdt as date_on,
		cast(sysdatetime() as datetime) as dt_dml,
		a.r_date, a.dpd_bucket, 
		a.dolya_mnth as dolya_base,
		(case when dd.fact_acc > dd.plan_month_base then 
		a.plan_sb
		else	
			(case when a.r_date < cast(getdate() as date) then 
			a.fact_sb
			else
			a.plan_new 
			end) 
		end)		/ bb.month_plan  as dolya_adj,
		a.product
	from RiskDWH.dbo.stg_calc_coll_daily_plan a
	left join (
		select b.product, b.dpd_bucket, sum(b.plan_sb) as month_plan 
		from RiskDWH.dbo.stg_calc_coll_daily_plan b
		where b.date_on = @rdt
		and b.dpd_bucket in ('(2)_1_30','(3)_31_60','(4)_61_90')
		and b.r_date between dateadd(dd,1,EOMONTH(@rdt,-1)) and EOMONTH(@rdt)
		group by b.product, b.dpd_bucket
	) bb
	on a.dpd_bucket = bb.dpd_bucket
	and a.product = bb.product
	left join (
		select d.product, d.dpd_bucket, d.fact_acc, p.total_bal_adj as plan_month_base
		from RiskDWH.dbo.stg_calc_coll_daily_plan d
		left join #plan p
		on d.dpd_bucket = p.bucket_from
		and d.product = p.product
		where d.date_on = @rdt
		and d.r_date = dateadd(dd,-1,@rdt)
		and d.dpd_bucket in ('(2)_1_30','(3)_31_60','(4)_61_90')
	) dd
	on a.dpd_bucket = dd.dpd_bucket
	and a.product = dd.product

	where a.date_on = @rdt
	and a.dpd_bucket in ('(2)_1_30','(3)_31_60','(4)_61_90')
	and a.r_date between dateadd(dd,1,EOMONTH(@rdt,-1)) and EOMONTH(@rdt);






	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'merge into RiskDWH.dbo.det_coll_daily_plan';


	merge into RiskDWH.dbo.det_coll_daily_plan dst
	using (
		select a.product, a.r_date, a.dpd_bucket, a.dolya_adj
		from RiskDWH.dbo.stg_coll_daily_plan_dolya a
		where a.date_on = @rdt 
		and a.r_date between dateadd(dd,1,EOMONTH(@rdt,-1)) and EOMONTH(@rdt)
	) src
	on (dst.rep_dt = src.r_date and dst.bucket_from = src.dpd_bucket and dst.product = src.product)
	when matched then update set 
	dst.coefficient_adj = src.dolya_adj;




	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'drop temp (#) tables';

	drop table #a11;
	drop table #a15_alt;
	drop table #a16;
	drop table #a17;
	drop table #a18;
	drop table #fact_90_over;
	drop table #plan;
	--drop table #stg_product;

end

else 
begin

	declare @vinfo varchar(500);
	set @vinfo = concat('There is not data in RiskDWH.dbo.det_coll_plan_basis for ', convert(varchar, eomonth(@rdt), 120) ); 

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

end

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';

