


--exec [dbo].[prc$update_rep_coll_weekly_part1]

CREATE procedure [dbo].[prc$update_rep_coll_weekly_part1] 
-- 0 - бакеты просрочки as-is из ЦМР, 1 - фиксируем бакет просрочки на момент начала КК только в месяц начала КК
@excludecredholid bit = 0,
-- 0 - бакеты просрочки as-is из ЦМР, 1 - исключаем полностью кредиты, которые когда-либо были на КК
@flag_kk_total bit = 0
as 


set datefirst 1;


declare @src_name nvarchar(100) = 'Recovery, activation for weekly coll report';


--declare @rdt date = dateadd(dd,-1,cast(getdate() as date));
declare @rdt date = dateadd(dd,-1, cast(RiskDWH.dbo.date_trunc('wk', cast(getdate() as date)) as date));

declare @lysd_dt_from date = dateadd(dd,1,EOMONTH(@rdt, -13));
declare @lysd_dt_to date = dateadd(yy,-1,@rdt);

declare @lm_dt_from date = dateadd(dd,1,EOMONTH(@rdt,-2));
declare @lmsd_dt_to date = dateadd(MM,-1,@rdt);
declare @lm_dt_to date = eomonth(@rdt,-1);

declare @cm_dt_from date = dateadd(dd,1,eomonth(@rdt,-1));


declare @cw_dt_from date = RiskDWH.dbo.date_trunc('wk',@rdt);

declare @lw_dt_from date = dateadd(dd,-7,RiskDWH.dbo.date_trunc('wk',@rdt));
declare @lw_dt_to date = dateadd(dd,-1,RiskDWH.dbo.date_trunc('wk',@rdt));

declare @march2020_from date = cast('2020-03-01' as date);
declare @march2020_to date = cast('2020-03-31' as date);

/*******************************************************************************/

----LYSD = last year same day, LMSD = last month same day,
----LM = last month, CM = current month
----LW = last week, CW = current week
----MAR20 - март 2020 г.

declare @vinfo varchar(1000) = concat('START rep_dt = ', format(@rdt, 'dd.MM.yyyy'),
									', excludecredholid = ', cast(@excludecredholid as varchar(1)), 
									', flag_kk_total = ', cast(@flag_kk_total as varchar(1))
									);

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = @vinfo;



	
	
	drop table if exists #CMR;

	select a.d as r_date, 
	a.external_id, 
	a.r_day, a.r_month, a.r_year,
	a.dpd_coll as overdue_days, 
	a.dpd_p_coll as overdue_days_p, 
	a.dpd_last_coll as last_dpd,
	a.bucket_coll as dpd_bucket, 
	a.bucket_p_coll as dpd_bucket_p, 
	a.bucket_last_coll as dpd_bucket_last,
	cast(isnull(a.[остаток од],0) as float) as principal_rest,
	a.prev_dpd_coll, 
	a.prev_dpd_p_coll,
	a.prev_od,
	cast(isnull(principal_cnl,    0) as float) +
	cast(isnull(percents_cnl,     0) as float) +
	cast(isnull(fines_cnl,        0) as float) +
	cast(isnull(otherpayments_cnl,0) as float) +
	cast(isnull(overpayments_cnl, 0) as float) - 
	cast(isnull(overpayments_acc, 0) as float) as pay_total,
	isnull([сумма поступлений], 0) as pay_total_calc
	into #CMR
	from dwh2.dbo.dm_CMRStatBalance a
	where a.d >= '2019-01-01' and a.d <= @rdt;
	

	--Бизнес-займы
	insert into #CMR
	select  a.r_date, 
	a.external_id, 
	a.r_day, a.r_month, a.r_year,
	a.overdue_days,
	a.overdue_days_p,
	a.last_dpd,
	a.dpd_bucket,
	a.dpd_bucket_p,
	a.dpd_bucket_last,
	a.principal_rest,
	a.overdue_days as prev_dpd_coll, 
	a.overdue_days_p as prev_dpd_p_coll,
	a.last_principal_rest as prev_od,
	a.pay_total,
	a.pay_total
	from RiskDWH.dbo.det_business_loans a;


	drop index if exists tmp_cmr_idx on #CMR;
	create clustered index tmp_cmr_idx on #CMR (external_id, r_date);


	


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_product';


	drop table if exists #stg_product;
	select a.Код as external_id, 
		case when cmr_ПодтипыПродуктов.Наименование = 'Pdl' THEN 'INSTALLMENT'
			 when a.IsInstallment = 1 then 'INSTALLMENT'
		else 'PTS' end as product
	into #stg_product
	from stg._1cCMR.Справочник_Договоры a
	LEFT JOIN Stg._1cCMR.Справочник_Заявка cmr_Заявка ON cmr_Заявка.Ссылка = a.Заявка
	LEFT JOIN stg._1cCMR.Справочник_ПодтипыПродуктов cmr_ПодтипыПродуктов ON cmr_Заявка.ПодтипПродукта = cmr_ПодтипыПродуктов.ссылка;

	

	drop table if exists #total_kk;
	create table #total_kk (external_id varchar(100), dt_from date, dt_to date);

	if @excludecredholid = 1 

	begin

		exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'CredVacations';

		--30/10/2020 платежи в период КК по бакету, с которого был переход на каникулы 
		insert into #total_kk
		select external_id, dt_from, dt_to
		from RiskDWH.dbo.det_kk_cmr_and_space
		;			
			
	end;

	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#base_cmr_mfo';

	drop table if exists #base_cmr_mfo;
	select a.r_date, a.external_id, a.dpd_bucket_p, a.overdue_days_p, a.pay_total, a.principal_rest, coalesce(pr.product, 'PTS') as product
	into #base_cmr_mfo
	from #CMR a
	
	left join #stg_product pr --15.02.2022
	on a.external_id = pr.external_id

	where 1=1
	and (a.r_date between @lysd_dt_from and @lysd_dt_to
		or a.r_date between @march2020_from and @march2020_to
		or a.r_date between @lm_dt_from and @rdt);


	merge into #base_cmr_mfo dst
	using (
		select b.r_date, b.external_id, c.dpd_bucket_p, c.overdue_days_p
		from #total_kk a
		inner join #base_cmr_mfo b
		on a.external_id = b.external_id
		and b.r_date between a.dt_from and a.dt_to
		and eomonth(b.r_date) = eomonth(dateadd(dd,1,a.dt_from))
		left join #CMR c
		on a.external_id = c.external_id
		and a.dt_from = c.r_date
	) src 
	on (dst.r_date = src.r_date and dst.external_id = src.external_id)
	when matched then update set 
	dst.dpd_bucket_p = src.dpd_bucket_p,
	dst.overdue_days_p = src.overdue_days_p
	;

	--09/03/21 Полное исключение каникул
	if @flag_kk_total = 1
	begin

	with a as (select * from #base_cmr_mfo)
	delete from a 
	where exists (select 1 from RiskDWH.dbo.det_kk_cmr_and_space b
					where a.external_id = b.external_id)


	delete from #base_cmr_mfo where product in ('INSTALLMENT', 'PDL'); --15.02.2022

	end;


	--27/11/20 Для учета платежей на стадии СБ (служба безопасности) в бакетах до 90+, которые в работе у Hard/Legal
	--14/12/20 Платежи из стадии Closed, перед закрытием была стадия СБ
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_sb_0_90';


	drop table if exists #stg_sb_0_90;
	
	select a.external_id, a.r_date
	into #stg_sb_0_90
	from #base_cmr_mfo a
	inner join RiskDWH.dbo.stg_client_stage b
	on a.external_id = b.external_id
	and a.r_date = b.cdate
	left join RiskDWH.dbo.stg_client_stage bb
	on a.external_id = bb.external_id
	and a.r_date = dateadd(dd,1,bb.cdate)
	inner join Stg._Collection.Deals_history c
	on a.external_id = c.Number
	and a.r_date = c.r_date
	inner join stg._Collection.DealStatus d
	on c.IdStatus = d.Id
	where 1=1
	--стадия СБ
	and (b.CRMClientStage = 'СБ' or /*10/12/2020*/ bb.CRMClientStage = 'СБ' and b.CRMClientStage = 'Closed')
	--был платеж
	and a.pay_total > 0
	--кроме бакетов, которые и так учитываются в 91+ 
	and a.dpd_bucket_p not in ('(5)_91_360','(6)_361+')
	--статус договора на момент платежа Legal
	and d.[Name] = 'Legal'
	--была просрочка более 90 дней (соответственно стадия Legal)
	and exists (select 1 from #CMR e 
		where a.external_id = e.external_id
		and a.r_date > e.r_date
		and e.overdue_days_p > 90)
	--в день платежа не был у агента
	and not exists (select 2 from dwh_new.dbo.v_agent_credits f
		where a.external_id = f.external_id
		and a.r_date between f.st_date and f.end_date)
		;

	merge into #base_cmr_mfo dst
	using #stg_sb_0_90 src
	on (dst.external_id = src.external_id and dst.r_date = src.r_date)
	when matched then update set 
	dst.dpd_bucket_p = '(0-90)Hard'
	;


	--отсечение 0-90 Hard
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#reestr_0_90_hard';


	drop table if exists #reestr_0_90_hard;
	select a.external_id, a.r_date, a.dpd_bucket_p, a.pay_total,
	b.CRMClientStage, 
	case when isnull(c.agent_name,'CarMoney') <> 'CarMoney' then 'KA'
	else 'CarMoney' end as agent_gr

	into #reestr_0_90_hard

	from #base_cmr_mfo a
	left join RiskDWH.dbo.stg_client_stage b
	on a.external_id = b.external_id
	and a.r_date = b.cdate
	left join dwh_new.dbo.v_agent_credits c
	on a.external_id = c.external_id
	and a.r_date between c.st_date and c.end_date
	where a.pay_total > 0
	and a.dpd_bucket_p in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')
	and (
		b.CRMClientStage = 'Legal' and a.dpd_bucket_p in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')
		or b.CRMClientStage = 'Hard' and a.dpd_bucket_p in ('(2)_1_30','(3)_31_60','(4)_61_90')
		or isnull(c.agent_name,'CarMoney') not in ('CarMoney','ACB') /*in ('Povoljie','Alfa','Prime Collection','Ilma','MBA') */
				and a.dpd_bucket_p in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')
	)
	;


	merge into #base_cmr_mfo dst
	using #reestr_0_90_hard src
	on (dst.external_id = src.external_id and dst.r_date = src.r_date)
	when matched then update set dst.dpd_bucket_p = '(0-90)Hard';


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#portf_base';
	

	drop table if exists #portf_base;
	--база для среднего портфеля и платежей
	select c.seg_high, c.external_id, c.r_date, 
	
	case when c.con_status = 'Legal' and c.dpd_bucket_p in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')
		then '(0-90) Hard'
		when c.con_status = 'Hard' and c.dpd_bucket_p in ('(2)_1_30','(3)_31_60','(4)_61_90')
		then '(0-90) Hard'
		else 
	c.dpd_bucket_p end as dpd_buck, 

	case when c.dpd_bucket_p in ('(2)_1_30','(3)_31_60','(4)_61_90') then '(4#)_1_90'
		 when c.dpd_bucket_p in ('(5)_91_360', '(6)_361+') then '(6#)_91+' end as dpd_buck_agg,

	replace(c.dpd_bucket_new,')','##)') as dpd_buck_new,


	case when c.dpd_bucket_new in ('(2)_1_30','(3)_31_60','(4)_61_90') then '(4###)_1_90'
		 when c.dpd_bucket_new in ('(5)_91_120', '(6)_121_150', '(7)_151_180', '(8)_181_360', '(9)_361+') then '(9###)_91+'
			end as dpd_buck_new_agg,

	c.pay_total, c.principal_rest
	, c.product --15.02.2022

	into #portf_base 
	from (
		select 'LYSD' as seg_high,
		a.external_id, a.r_date, RiskDWH.dbo.get_bucket_coll_2(a.overdue_days_p) as dpd_bucket_new, a.dpd_bucket_p, a.pay_total, a.principal_rest,
		cst.CRMClientStage as con_status
		, a.product --15.02.2022
		from #base_cmr_mfo a
			left join RiskDWH.dbo.stg_client_stage cst 
			on a.external_id=cst.external_id 
			and a.r_date= cst.cdate
		where a.r_date between @lysd_dt_from and @lysd_dt_to
		and a.dpd_bucket_p <> '(1)_0'

			union all

		select 'LMSD' as seg_high,
		a.external_id, a.r_date, RiskDWH.dbo.get_bucket_coll_2(a.overdue_days_p) as dpd_bucket_new, a.dpd_bucket_p, a.pay_total, a.principal_rest,
		cst.CRMClientStage as con_status
		, a.product --15.02.2022
		from #base_cmr_mfo a
			left join RiskDWH.dbo.stg_client_stage cst 
			on a.external_id=cst.external_id 
			and a.r_date= cst.cdate
		where a.r_date between @lm_dt_from and @lmsd_dt_to
		and a.dpd_bucket_p <> '(1)_0'

			union all

		select 'LM' as seg_high, 
		a.external_id, a.r_date, RiskDWH.dbo.get_bucket_coll_2(a.overdue_days_p) as dpd_bucket_new, a.dpd_bucket_p, a.pay_total, a.principal_rest,
		cst.CRMClientStage as con_status
		, a.product --15.02.2022
		from #base_cmr_mfo a
			left join RiskDWH.dbo.stg_client_stage cst 
			on a.external_id=cst.external_id 
			and a.r_date= cst.cdate
		where a.r_date between @lm_dt_from and @lm_dt_to
		and a.dpd_bucket_p <> '(1)_0'

			union all

		select 'CM' as seg_high, 
		a.external_id, a.r_date, RiskDWH.dbo.get_bucket_coll_2(a.overdue_days_p) as dpd_bucket_new, a.dpd_bucket_p, a.pay_total, a.principal_rest,
		cst.CRMClientStage as con_status
		, a.product --15.02.2022
		from #base_cmr_mfo a
			left join RiskDWH.dbo.stg_client_stage cst 
			on a.external_id=cst.external_id 
			and a.r_date= cst.cdate
		where a.r_date between @cm_dt_from and @rdt
		and a.dpd_bucket_p <> '(1)_0'

			union all

		select 'CW' as seg_high,
		a.external_id, a.r_date, RiskDWH.dbo.get_bucket_coll_2(a.overdue_days_p) as dpd_bucket_new, a.dpd_bucket_p, a.pay_total, a.principal_rest,
		cst.CRMClientStage as con_status
		, a.product --15.02.2022
		from #base_cmr_mfo a
			left join RiskDWH.dbo.stg_client_stage cst 
			on a.external_id=cst.external_id 
			and a.r_date= cst.cdate
		where a.r_date between @cw_dt_from and @rdt
		and a.dpd_bucket_p <> '(1)_0'

			union all

		select 'LW' as seg_high,
		a.external_id, a.r_date, RiskDWH.dbo.get_bucket_coll_2(a.overdue_days_p) as dpd_bucket_new, a.dpd_bucket_p, a.pay_total, a.principal_rest,
		cst.CRMClientStage as con_status
		, a.product --15.02.2022
		from #base_cmr_mfo a	
			left join RiskDWH.dbo.stg_client_stage cst 
			on a.external_id=cst.external_id 
			and a.r_date= cst.cdate
		where a.r_date between @lw_dt_from and @lw_dt_to
		and a.dpd_bucket_p <> '(1)_0'

			union all

		select 'MAR20' as seg_high,
		a.external_id, a.r_date, RiskDWH.dbo.get_bucket_coll_2(a.overdue_days_p) as dpd_bucket_new, a.dpd_bucket_p, a.pay_total, a.principal_rest,
		cst.CRMClientStage as con_status
		, a.product --15.02.2022
		from #base_cmr_mfo a
			left join RiskDWH.dbo.stg_client_stage cst 
			on a.external_id=cst.external_id 
			and a.r_date= cst.cdate
		where a.r_date between @march2020_from and @march2020_to
		and a.dpd_bucket_p <> '(1)_0'
	) c
	;
	

	--recovery, avg_check, activation - BASE
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_rep';
	   
	----старые бакеты
	drop table if exists #stg_rep;

	with daily_portf as (
		select a.seg_high, a.r_date, a.dpd_buck, a.product,
			sum(a.principal_rest) as total_od
		from #portf_base a
		group by a.seg_high, a.r_date, a.dpd_buck, a.product /*15.02.2022*/
	),
	avg_portf as (
		select d.seg_high, d.dpd_buck, d.product,
			avg(d.total_od) as total_od
		from daily_portf d
		group by d.seg_high, d.dpd_buck, d.product /*15.02.2022*/
	),
	pmt_base as (
		select a.seg_high, a.r_date, a.dpd_buck, a.external_id, a.product,
			sum(a.pay_total) as pay_total,
			count(*) as cnt_pmt
		from #portf_base a
		where a.pay_total > 0
		group by a.seg_high, a.r_date, a.dpd_buck, a.external_id, a.product /*15.02.2022*/
	),
	pmt as (
		select dd.seg_high, dd.dpd_buck, dd.product,
				sum(dd.pay_total) as pay_total, 
				count(distinct dd.external_id) as total_dist_pmt,
				sum(cnt_pmt) as total_pmt
		from pmt_base dd
		group by dd.seg_high, dd.dpd_buck, dd.product /*15.02.2022*/
	),
	creds as (
	select bs.seg_high, 
			bs.dpd_buck, 
			bs.product,
			count(distinct bs.external_id) as cnt_cred
	from #portf_base bs
	group by bs.seg_high, bs.dpd_buck, bs.product /*15.02.2022*/
	)
	select 
	ap.product, --15.02.2022
	ap.seg_high,
	ap.dpd_buck, 
	ap.total_od,
	p.pay_total,
	case when ap.total_od = 0 then 0 else p.pay_total / ap.total_od end as recov,
	p.total_dist_pmt,
	p.total_pmt,

	case when p.total_pmt = 0 then 0 else p.pay_total / cast(p.total_pmt as float) end as avg_check,
	cr.cnt_cred,
	case when cr.cnt_cred = 0 then 0 else cast(p.total_dist_pmt as float) / cast(cr.cnt_cred as float) end as activ

	into #stg_rep

	from avg_portf ap
	left join pmt p
	on ap.dpd_buck = p.dpd_buck
	and ap.seg_high = p.seg_high
	and ap.product = p.product
	left join creds cr
	on ap.dpd_buck = cr.dpd_buck
	and ap.seg_high = cr.seg_high
	and ap.product = cr.product
	;


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_rep_agg';
	----старые бакеты, агрегат 1-90 и 91+
	drop table if exists #stg_rep_agg;

	with daily_portf as (
		select a.seg_high, a.r_date, a.dpd_buck_agg, a.product,
			sum(a.principal_rest) as total_od
		from #portf_base a
		group by a.seg_high, a.r_date, a.dpd_buck_agg, a.product /*15.02.2022*/
	),
	avg_portf as (
		select d.seg_high, d.dpd_buck_agg, d.product,
			avg(d.total_od) as total_od
		from daily_portf d
		group by d.seg_high, d.dpd_buck_agg, d.product /*15.02.2022*/
	),
	pmt_base as (
		select a.seg_high, a.r_date, a.dpd_buck_agg, a.external_id, a.product,
			sum(a.pay_total) as pay_total,
			count(*) as cnt_pmt
		from #portf_base a
		where a.pay_total > 0
		group by a.seg_high, a.r_date, a.dpd_buck_agg, a.external_id, a.product /*15.02.2022*/
	),
	pmt as (
		select dd.seg_high, dd.dpd_buck_agg, dd.product,
				sum(dd.pay_total) as pay_total, 
				count(distinct dd.external_id) as total_dist_pmt,
				sum(cnt_pmt) as total_pmt
		from pmt_base dd
		group by dd.seg_high, dd.dpd_buck_agg, dd.product /*15.02.2022*/
	),
	creds as (
	select bs.seg_high, 
			bs.dpd_buck_agg, 
			bs.product,
			count(distinct bs.external_id) as cnt_cred
	from #portf_base bs
	group by bs.seg_high, bs.dpd_buck_agg, bs.product /*15.02.2022*/
	)
	select 
	ap.product, /*15.02.2022*/
	ap.seg_high,
	ap.dpd_buck_agg, 
	ap.total_od,
	p.pay_total,
	case when ap.total_od = 0 then 0 else p.pay_total / ap.total_od end as recov,
	p.total_dist_pmt,
	p.total_pmt,

	case when p.total_pmt = 0 then 0 else p.pay_total / cast(p.total_pmt as float) end as avg_check,
	cr.cnt_cred,
	case when cr.cnt_cred = 0 then 0 else cast(p.total_dist_pmt as float) / cast(cr.cnt_cred as float) end as activ

	into #stg_rep_agg

	from avg_portf ap
	left join pmt p
	on ap.dpd_buck_agg = p.dpd_buck_agg
	and ap.seg_high = p.seg_high
	and ap.product = p.product
	left join creds cr
	on ap.dpd_buck_agg = cr.dpd_buck_agg
	and ap.seg_high = cr.seg_high
	and ap.product = cr.product
	;


	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_rep_new';
	----новые бакеты
	drop table if exists #stg_rep_new;

	with daily_portf as (
		select a.seg_high, a.r_date, a.dpd_buck_new, a.product,
			sum(a.principal_rest) as total_od
		from #portf_base a
		group by a.seg_high, a.r_date, a.dpd_buck_new, a.product /*15.02.2022*/
	),
	avg_portf as (
		select d.seg_high, d.dpd_buck_new, d.product,
			avg(d.total_od) as total_od
		from daily_portf d
		group by d.seg_high, d.dpd_buck_new, d.product /*15.02.2022*/
	),
	pmt_base as (
		select a.seg_high, a.r_date, a.dpd_buck_new, a.external_id, a.product,
			sum(a.pay_total) as pay_total,
			count(*) as cnt_pmt
		from #portf_base a
		where a.pay_total > 0
		group by a.seg_high, a.r_date, a.dpd_buck_new, a.external_id, a.product /*15.02.2022*/
	),
	pmt as (
		select dd.seg_high, dd.dpd_buck_new, dd.product,
				sum(dd.pay_total) as pay_total, 
				count(distinct dd.external_id) as total_dist_pmt,
				sum(cnt_pmt) as total_pmt
		from pmt_base dd
		group by dd.seg_high, dd.dpd_buck_new, dd.product /*15.02.2022*/
	),
	creds as (
	select bs.seg_high, 
			bs.dpd_buck_new, 
			bs.product,
			count(distinct bs.external_id) as cnt_cred
	from #portf_base bs
	group by bs.seg_high, bs.dpd_buck_new, bs.product /*15.02.2022*/
	)
	select 
	ap.product, /*15.02.2022*/
	ap.seg_high,
	ap.dpd_buck_new, 
	ap.total_od,
	p.pay_total,
	case when ap.total_od = 0 then 0 else p.pay_total / ap.total_od end as recov,
	p.total_dist_pmt,
	p.total_pmt,

	case when p.total_pmt = 0 then 0 else p.pay_total / cast(p.total_pmt as float) end as avg_check,
	cr.cnt_cred,
	case when cr.cnt_cred = 0 then 0 else cast(p.total_dist_pmt as float) / cast(cr.cnt_cred as float) end as activ

	into #stg_rep_new

	from avg_portf ap
	left join pmt p
	on ap.dpd_buck_new = p.dpd_buck_new
	and ap.seg_high = p.seg_high
	and ap.product = p.product

	left join creds cr
	on ap.dpd_buck_new = cr.dpd_buck_new
	and ap.seg_high = cr.seg_high
	and ap.product = cr.product
	;



	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_rep_new_agg';
	----новые бакеты
	drop table if exists #stg_rep_new_agg;

	with daily_portf as (
		select a.seg_high, a.r_date, a.dpd_buck_new_agg, a.product, 
			sum(a.principal_rest) as total_od
		from #portf_base a
		group by a.seg_high, a.r_date, a.dpd_buck_new_agg, a.product /*15.02.2022*/
	),
	avg_portf as (
		select d.seg_high, d.dpd_buck_new_agg, d.product,
			avg(d.total_od) as total_od
		from daily_portf d
		group by d.seg_high, d.dpd_buck_new_agg, d.product /*15.02.2022*/
	),
	pmt_base as (
		select a.seg_high, a.r_date, a.dpd_buck_new_agg, a.external_id, a.product,
			sum(a.pay_total) as pay_total,
			count(*) as cnt_pmt
		from #portf_base a
		where a.pay_total > 0
		group by a.seg_high, a.r_date, a.dpd_buck_new_agg, a.external_id, a.product /*15.02.2022*/
	),
	pmt as (
		select dd.seg_high, dd.dpd_buck_new_agg, dd.product,
				sum(dd.pay_total) as pay_total, 
				count(distinct dd.external_id) as total_dist_pmt,
				sum(cnt_pmt) as total_pmt
		from pmt_base dd
		group by dd.seg_high, dd.dpd_buck_new_agg, dd.product /*15.02.2022*/
	),
	creds as (
	select bs.seg_high, 
			bs.dpd_buck_new_agg, 
			bs.product,
			count(distinct bs.external_id) as cnt_cred
	from #portf_base bs
	group by bs.seg_high, bs.dpd_buck_new_agg, bs.product /*15.02.2022*/
	)
	select 
	ap.product, /*15.02.2022*/
	ap.seg_high,
	ap.dpd_buck_new_agg, 
	ap.total_od,
	p.pay_total,
	case when ap.total_od = 0 then 0 else p.pay_total / ap.total_od end as recov,
	p.total_dist_pmt,
	p.total_pmt,

	case when p.total_pmt = 0 then 0 else p.pay_total / cast(p.total_pmt as float) end as avg_check,
	cr.cnt_cred,
	case when cr.cnt_cred = 0 then 0 else cast(p.total_dist_pmt as float) / cast(cr.cnt_cred as float) end as activ

	into #stg_rep_new_agg

	from avg_portf ap
	left join pmt p
	on ap.dpd_buck_new_agg = p.dpd_buck_new_agg
	and ap.seg_high = p.seg_high
	and ap.product = p.product
	left join creds cr
	on ap.dpd_buck_new_agg = cr.dpd_buck_new_agg
	and ap.seg_high = cr.seg_high
	and ap.product = cr.product
	;

/*************************************************************************/
--FINAL REP
exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#final_rep';


drop table if exists #final_rep;

select  t.seg_high, 
		t.dpd_buck, 
		t.total_od, 
		t.pay_total,
		t.recov,
		t.total_dist_pmt, 
		t.total_pmt,
		t.avg_check,
		t.cnt_cred,
		t.activ,
		t.product /*15.02.2022*/

into #final_rep

from (
select * from #stg_rep
union all
select * from #stg_rep_agg
union all
select * from #stg_rep_new
union all 
select * from #stg_rep_new_agg
) t
;


--declare @rdt date = dateadd(dd,-1, cast(RiskDWH.dbo.date_trunc('wk', cast(getdate() as date)) as date));

exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'rep_coll_weekly_recov';


--финальный селект для Excel (activation, recovery, avgportf, avgcheck, cash)
delete from dbo.rep_coll_weekly_recov
where rep_dt = @rdt
and flag_exclude_kk = @flag_kk_total
;

if @flag_kk_total = 0 
begin
	delete from dbo.rep_coll_weekly_recov
	where rep_dt = @rdt
	and flag_exclude_kk = 2
end;



insert into dbo.rep_coll_weekly_recov
select 
@rdt as rep_dt, cast(SYSDATETIME() as datetime) as dt_dml,
a.seg_high+'#'+a.dpd_buck as metric, 
a.seg_high,
a.dpd_buck,
a.total_od,
a.pay_total,
a.recov,
a.total_dist_pmt,
a.total_pmt,
a.avg_check,
a.cnt_cred,
a.activ,
case when a.product in ('INSTALLMENT', 'PDL') then 2 else @flag_kk_total end as flag_exclude_kk --15.02.2022

from #final_rep  a
order by 2,3,4;


--сверка с мотивационным отчетом
--with t1 as (
--select a.r_date, a.external_id, a.pay_total from #portf_base a
--where a.seg_high = 'CM'
--and a.dpd_bucket_p = '(4)_61_90'
--and a.pay_total > 0 
--),
--t2 as (
--select a.r_date, a.external_id, a.pay_total
--from Reports.Risk.dm_ReportCollectionPlanMFOCred a
--where a.seg = '(3)_CM'
--and a.dpd_bucket_from = '(4)_61_90'
--and a.rep_dt = '2020-06-18'
--and a.pay_total > 0
--)
--select t1.*, t2.*, ''''+t1.external_id+''',' as id_char
--from t1
--full join t2 
--on t1.external_id = t2.external_id
--and t1.r_date = t2.r_date
--where t1.external_id is null or t2.external_id is null;



exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = '#stg_0_90_hard';
--Платежи 0-90 Hard

	drop table if exists #pre_0_90_hard;
	
	select b.external_id, b.r_date, b.pay_total,
	isnull(c.dpd_bucket_p,b.dpd_bucket_p) as dpd_bucket_p,
	coalesce(pr.product,'PTS') as product --15.02.2022

	into #pre_0_90_hard
	
	from #CMR b
	
	left join #total_kk k
	on b.external_id = k.external_id
	and b.r_date between k.dt_from and k.dt_to
	and EOMONTH(b.r_date) = EOMONTH(dateadd(dd,1,k.dt_from))
	
	left join #CMR c
	on k.external_id = c.external_id
	and k.dt_from = c.r_date

	left join #stg_product pr --15.02.2022
	on b.external_id = pr.external_id
	
	where 1=1
	and (
	(b.r_date between @lm_dt_from and @rdt)
	or (b.r_date between @march2020_from and @march2020_to)
	or (b.r_date between @lysd_dt_from and @lysd_dt_to 
	--статусы договора доступны только с 25/07/19
	and b.r_date >= cast('2019-08-01' as date)) 
		)
	and b.pay_total > 0
	;
	   
	--09/03/21 Полное исключение каникул
	if @flag_kk_total = 1
	begin

	with a as (select * from #pre_0_90_hard)
	delete from a 
	where exists (select 1 from RiskDWH.dbo.det_kk_cmr_and_space b
					where a.external_id = b.external_id)


	delete from #pre_0_90_hard where product in ('INSTALLMENT', 'PDL')

	end;


	drop table if exists #stg_0_90_hard;

	select a.external_id, a.r_date, a.dpd_bucket_p, a.pay_total, 
	case when vag.agent_name is not null then 'Агент'
		when sb.external_id is not null then 'Хард'
	else 'Хард' end as CRMClientStage
	--iif(vag.agent_name is not null, 'Агент', 'Хард') as CRMClientStage
	--cst.CRMClientStage
	, a.product --15.02.2022
	into #stg_0_90_hard
	
	from #pre_0_90_hard a
	
	left join RiskDWH.dbo.stg_client_stage cst 
	on a.external_id=cst.external_id 
	and a.r_date= cst.cdate

	left join dwh_new.dbo.v_agent_credits vag
	on a.external_id = vag.external_id
	and a.r_date between vag.st_date and vag.end_date

	left join #stg_sb_0_90 sb
	on a.external_id = sb.external_id
	and a.r_date = sb.r_date

	where 1=1
	and ((cst.CRMClientStage = 'Hard' and a.dpd_bucket_p in ('(2)_1_30','(3)_31_60','(4)_61_90'))
		or (cst.CRMClientStage = 'Legal' and a.dpd_bucket_p in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90'))
		or isnull(vag.agent_name ,'Carmoney') not in ('Carmoney','ACB') and a.dpd_bucket_p in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')
		or sb.external_id is not null
		)
	;

exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'rep_coll_weekly_0_90_hard';


	delete from RiskDWH.dbo.rep_coll_weekly_0_90_hard
	where rep_dt = @rdt
	and flag_exclude_kk = @flag_kk_total	
	;

	if @flag_kk_total = 0
	begin
		delete from RiskDWH.dbo.rep_coll_weekly_0_90_hard
		where rep_dt = @rdt
		and flag_exclude_kk = 2
	end;


	insert into RiskDWH.dbo.rep_coll_weekly_0_90_hard
	select @rdt as rep_dt, cast(sysdatetime() as datetime) as dt_dml, aa.seg_high, aa.pmt_0_90_hard, aa.CRMClientStage as seg_agent_hard, 
	case when aa.product in ('INSTALLMENT', 'PDL') then 2 else @flag_kk_total end as flag_exclude_kk

	from (
		select 'LYSD' as seg_high, a.CRMClientStage, sum(pay_total) as pmt_0_90_hard, a.product /*15.02.2022*/
		from #stg_0_90_hard a
		where a.r_date between @lysd_dt_from and @lysd_dt_to
		group by a.CRMClientStage, a.product /*15.02.2022*/
	union all
		select 'LMSD' as seg_high, a.CRMClientStage, sum(pay_total) as pmt_0_90_hard, a.product /*15.02.2022*/
		from #stg_0_90_hard a
		where a.r_date between @lm_dt_from and @lmsd_dt_to
		group by a.CRMClientStage, a.product /*15.02.2022*/
	union all
		select 'LM' as seg_high, a.CRMClientStage, sum(pay_total) as pmt_0_90_hard, a.product /*15.02.2022*/
		from #stg_0_90_hard a
		where a.r_date between @lm_dt_from and @lm_dt_to
		group by a.CRMClientStage, a.product /*15.02.2022*/
	union all
		select 'LW' as seg_high, a.CRMClientStage, sum(pay_total) as pmt_0_90_hard, a.product /*15.02.2022*/
		from #stg_0_90_hard a
		where a.r_date between @lw_dt_from and @lw_dt_to
		group by a.CRMClientStage, a.product /*15.02.2022*/
	union all
		select 'CM' as seg_high, a.CRMClientStage, sum(pay_total) as pmt_0_90_hard, a.product /*15.02.2022*/
		from #stg_0_90_hard a
		where a.r_date between @cm_dt_from and @rdt
		group by a.CRMClientStage, a.product /*15.02.2022*/
	union all
		select 'CW' as seg_high, a.CRMClientStage, sum(pay_total) as pmt_0_90_hard, a.product /*15.02.2022*/
		from #stg_0_90_hard a
		where a.r_date between @cw_dt_from and @rdt
		group by a.CRMClientStage, a.product /*15.02.2022*/
	union all
		select 'MAR20' as seg_high, a.CRMClientStage, sum(pay_total) as pmt_0_90_hard, a.product /*15.02.2022*/
		from #stg_0_90_hard a
		where a.r_date between @march2020_from and @march2020_to
		group by a.CRMClientStage, a.product /*15.02.2022*/
	) aa
	where aa.pmt_0_90_hard is not null
	;


exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'drop temp (#) tables';

	drop table #portf_base;
	drop table #stg_rep;
	drop table #stg_rep_agg;
	drop table #stg_rep_new;
	drop table #stg_rep_new_agg;
	drop table #final_rep;
	drop table #stg_0_90_hard;
	drop table #pre_0_90_hard;
	drop table #total_kk;
	drop table #stg_sb_0_90;
	drop table #base_cmr_mfo;
	drop table #reestr_0_90_hard;
	drop table #stg_product;
	drop table #CMR;

exec RiskDWH.dbo.prc$set_debug_info @src = @src_name, @info = 'FINISH';
