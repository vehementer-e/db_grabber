



CREATE procedure [dbo].[prc$check_rep_coll]
@dt1 date = null,
@dt2 date = null

as 

declare @srcname varchar(100) = 'COLLECTION DAILY REPs CHECK';

if @dt1 is null set @dt1 = dateadd(dd,-2,cast(getdate() as date));
if @dt2 is null set @dt2 = dateadd(dd,-1,cast(getdate() as date));


declare @vinfo varchar(1000) = concat('START, repdate1 = ', format(@dt1,'dd.MM.yyyy'), ' repdate2 = ', format(@dt2,'dd.MM.yyyy') );

exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;



--проивзодить проверку только если отчетные даты в одном месяце
if DATEDIFF(MM, @dt1, @dt2 ) = 0

begin

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'DO CHECKS';

	--переменные для проверки (0 - проверка прошла, 1 - ошибки)
	declare @check1 bit; --сумма платежей по сравнению с предыдущим днем НЕ уменьшается
	declare @check2 bit; --0-90 hard по сравнению с предыдущим днем НЕ уменьшается
	declare @check3 bit; --сохраненный баланс по сравнению с предыдущим днем НЕ уменьшается
	declare @check4 bit; --сумма платежей Агенты по сравнению с предыдущим днем НЕ уменьшается
	declare @check5 bit; --сверка отчета по движениям по бакетам с мотивационным отчетом
	declare @check6 bit; --сумма перехода из [0] -> [1-30] в мотив отчете НЕ уменьшается
	declare @check7 bit; --платежи ФССП НЕ уменьшаются
	declare @check8 bit; --платежи по банкротам и принятым на балан авто НЕ уменьшаются
	declare @check9 bit; --кол-во по бакетам (в работе) мотивационый отчет <-> движение по бакетам
	declare @check10 bit; --кол-во по бакетам (в работе) "движение по бакетам" НЕ уменьшается



	--проверка сумм платежей по бакетам (1+)
	drop table if exists #check_pmt_1_plus;

	with ytd as (
	select a.rep_dt, a.seg, a.dpd_bucket_p_, sum(a.pay_total) as pay_total
	from Reports.Risk.dm_ReportCollectionPlanMFOPmtAll a
	where a.rep_dt = @dt2
	and a.seg = '(3)_CM'
	--and a.dpd_bucket_p_ <> '(1)_0'
	and a.dpd_bucket_p_ <> '[09] 0-90 hard'
	group by a.rep_dt, a.seg, a.dpd_bucket_p_
	),
	ytd_minus_1 as (
	select a.rep_dt, a.seg, a.dpd_bucket_p_, sum(a.pay_total) as pay_total
	from Reports.Risk.dm_ReportCollectionPlanMFOPmtAll a
	where a.rep_dt = @dt1
	and a.seg = '(3)_CM'
	--and a.dpd_bucket_p_ <> '(1)_0'
	and a.dpd_bucket_p_ <> '[09] 0-90 hard'
	group by a.rep_dt, a.seg, a.dpd_bucket_p_
	)
	select y.rep_dt as ytd_rep_dt, m.rep_dt as ytd_m_1_rep_dt,
	y.dpd_bucket_p_, y.pay_total as ytd_pmt,  m.pay_total as ytd_m_1_pmt,
	round(y.pay_total - isnull(m.pay_total,0) ,0) as delta_pmt

	into #check_pmt_1_plus

	from ytd y
	left join ytd_minus_1 m
	on y.dpd_bucket_p_ = m.dpd_bucket_p_;


	set @check1 = (select case when count(*)>0 then 1 else 0 end from #check_pmt_1_plus a where a.delta_pmt < 0);

	--0-90 hard
	drop table if exists #check_0_90_hard;

	with ytd as (
	select a.rep_dt, iif(a.CRMClientStage = 'КА', 'Agent', 'Hard') as seg_hard_agent,
	sum(a.pay_total) as pay_total from Reports.Risk.dm_ReportCollectionPlanMFOPmtAll a
	where a.rep_dt = @dt2
	and a.seg = '(3)_CM'
	and ( a.CRMClientStage = 'Hard' and a.dpd_bucket_p_ in ('[09] 0-90 hard', '(2)_1_30', '(3)_31_60', '(4)_61_90') 
		or a.CRMClientStage = 'Legal' and a.dpd_bucket_p_ in ('[09] 0-90 hard', '(1)_0', '(2)_1_30', '(3)_31_60', '(4)_61_90')
		or a.CRMClientStage = 'КА' and a.dpd_bucket_p_ in ('[09] 0-90 hard', '(1)_0', '(2)_1_30', '(3)_31_60', '(4)_61_90')
		)
	group by a.rep_dt, iif(a.CRMClientStage = 'КА', 'Agent', 'Hard')
	),
	ytd_minus_1 as (
	select a.rep_dt, iif(a.CRMClientStage = 'КА', 'Agent', 'Hard') as seg_hard_agent,
	sum(a.pay_total) as pay_total from Reports.Risk.dm_ReportCollectionPlanMFOPmtAll a
	where a.rep_dt = @dt1
	and a.seg = '(3)_CM'
	and ( a.CRMClientStage = 'Hard' and a.dpd_bucket_p_ in ('[09] 0-90 hard', '(2)_1_30', '(3)_31_60', '(4)_61_90') 
		or a.CRMClientStage = 'Legal' and a.dpd_bucket_p_ in ('[09] 0-90 hard', '(1)_0', '(2)_1_30', '(3)_31_60', '(4)_61_90')
		or a.CRMClientStage = 'КА' and a.dpd_bucket_p_ in ('[09] 0-90 hard', '(1)_0', '(2)_1_30', '(3)_31_60', '(4)_61_90')
		)
	group by a.rep_dt, iif(a.CRMClientStage = 'КА', 'Agent', 'Hard')
	)
	select y.rep_dt as ytd_rep_dt, m.rep_dt as ytd_m_1_rep_dt, 
	y.seg_hard_agent as ytd_seg, m.seg_hard_agent as ytd_m_1_seg,
	y.pay_total as ytd_090hard, m.pay_total as ytd_m_1_090hard,
	round(y.pay_total - isnull(m.pay_total,0) ,0) as delta
	into #check_0_90_hard
	from ytd y
	left join ytd_minus_1 m
	on y.seg_hard_agent = m.seg_hard_agent ;
	
	set @check2 =  (select sum(case when delta < 0 then 1 else 0 end) from #check_0_90_hard a);

	
	--сохр баланс
	drop table if exists #check_saved_balance;

	with ytd as (
		select a.rep_dt, a.dpd_bucket, a.dpd_bucket_end, sum(a.total_balance) as total_bal
		from Reports.Risk.dm_ReportCollectionPlanRollBalance a
		where a.rep_dt = @dt2
		and a.r_year = year(  @dt2 )
		and a.r_month = month(  @dt2 )
		and (a.dpd_bucket = '(2)_1_30' and a.dpd_bucket_end = '(1)_0'
		 or a.dpd_bucket = '(3)_31_60' and a.dpd_bucket_end = '(1)_0'
		 or a.dpd_bucket = '(3)_31_60' and a.dpd_bucket_end = '(2)_1_30'
		 or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(1)_0'
		 or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(2)_1_30'
		 or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(3)_31_60')
		group by a.rep_dt, a.dpd_bucket, a.dpd_bucket_end
	),
	ytd_minus_1 as (
		select a.rep_dt, a.dpd_bucket, a.dpd_bucket_end, sum(a.total_balance) as total_bal
		from Reports.Risk.dm_ReportCollectionPlanRollBalance a
		where a.rep_dt = @dt1
		and a.r_year = year(  @dt1 )
		and a.r_month = month(  @dt1 )
		and (a.dpd_bucket = '(2)_1_30' and a.dpd_bucket_end = '(1)_0'
		 or a.dpd_bucket = '(3)_31_60' and a.dpd_bucket_end = '(1)_0'
		 or a.dpd_bucket = '(3)_31_60' and a.dpd_bucket_end = '(2)_1_30'
		 or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(1)_0'
		 or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(2)_1_30'
		 or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(3)_31_60')
		group by a.rep_dt, a.dpd_bucket, a.dpd_bucket_end
	)
	select y.rep_dt as ytd_rep_dt, m.rep_dt as ytd_m_1_rep_dt,
	y.dpd_bucket, y.dpd_bucket_end,
	y.total_bal as ytd_total_bal, m.total_bal as ytd_m_1_total_bal,
	round(y.total_bal - isnull(m.total_bal,0),0) as delta
	
	into #check_saved_balance

	from ytd y
	left join ytd_minus_1 m
	on y.dpd_bucket = m.dpd_bucket
	and y.dpd_bucket_end = m.dpd_bucket_end;

	set @check3 = (select case when count(*)>0 then 1 else 0 end from #check_saved_balance a where a.delta < 0);

	
	--платежи агенты
	drop table if exists #check_agent_pays;

	with ytd as (
		select a.rep_dt, a.agent_name, a.stage, sum(a.pay_total) as pay_total
		from Reports.Risk.dm_ReportCollectionPlanAgentsPays a
		where a.rep_dt = @dt2
		and a.seg  = 'other'
		group by a.rep_dt, a.agent_name, a.stage
	),
	ytd_minus_1 as (
		select a.rep_dt, a.agent_name, a.stage, sum(a.pay_total) as pay_total
		from Reports.Risk.dm_ReportCollectionPlanAgentsPays a
		where a.rep_dt = @dt1
		and a.seg  = 'other'
		group by a.rep_dt, a.agent_name, a.stage
	)
	select y.rep_dt as ytd_rep_dt, m.rep_dt as ytd_m_1_rep_dt,
	y.agent_name, y.stage,
	y.pay_total as ytd_pmt, m.pay_total as ytd_m_1_pmt,
	round(y.pay_total - isnull(m.pay_total,0),0) as delta

	into #check_agent_pays

	from ytd y
	left join ytd_minus_1 m
	on y.agent_name = m.agent_name
	and y.stage = m.stage;

	set @check4 = (select case when count(*) > 0 then 1 else 0 end from #check_agent_pays a where a.delta < 0 );

	
	--отчет по движению по бакетам <-> мотивационный отчет
	drop table if exists #check_bucket_moves;

	with bucket_moves as (
	select a.product, a.rep_dt, '(2)_1_30' as dpd_bucket, '(1)_0' as dpd_bucket_end,
	a.[Improve 1-30 -> 0 abs] as total_bal 
	from Reports.Risk.dm_ReportCollectionRollRates a 
	where a.rep_dt = @dt2
	and a.seg3 = 'CM'
		
		union all
	select a.product, a.rep_dt, '(1)_0' as dpd_bucket, '(2)_1_30' as dpd_bucket_end,
	a.[Worse 0 -> 1-30 abs] as total_bal 
	from Reports.Risk.dm_ReportCollectionRollRates a 
	where a.rep_dt = @dt2
	and a.seg3 = 'CM'
		
		union all
	select a.product, a.rep_dt, '(3)_31_60' as dpd_bucket, '(1)_0' as dpd_bucket_end,
	a.[Improve 31-60 -> 0 abs] as total_bal 
	from Reports.Risk.dm_ReportCollectionRollRates a 
	where a.rep_dt = @dt2
	and a.seg3 = 'CM'
		union all
	select a.product, a.rep_dt, '(3)_31_60' as dpd_bucket, '(2)_1_30' as dpd_bucket_end,
	a.[Improve 31-60 -> 1-30 abs] as total_bal 
	from Reports.Risk.dm_ReportCollectionRollRates a 
	where a.rep_dt = @dt2
	and a.seg3 = 'CM'
		
		union all
	select a.product, a.rep_dt, '(4)_61_90' as dpd_bucket, '(1)_0' as dpd_bucket_end,
	a.[Improve 61-90 -> 0 abs] as total_bal 
	from Reports.Risk.dm_ReportCollectionRollRates a 
	where a.rep_dt = @dt2
	and a.seg3 = 'CM'
		union all
	select a.product, a.rep_dt, '(4)_61_90' as dpd_bucket, '(2)_1_30' as dpd_bucket_end,
	a.[Improve 61-90 -> 1-30 abs] as total_bal 
	from Reports.Risk.dm_ReportCollectionRollRates a 
	where a.rep_dt = @dt2
	and a.seg3 = 'CM'
		union all
	select a.product, a.rep_dt, '(4)_61_90' as dpd_bucket, '(3)_31_60' as dpd_bucket_end,
	a.[Improve 61-90 -> 31-60 abs] as total_bal 
	from Reports.Risk.dm_ReportCollectionRollRates a 
	where a.rep_dt = @dt2
	and a.seg3 = 'CM'
	),
	motiv as (
		select a.rep_dt, a.product, a.dpd_bucket, a.dpd_bucket_end, sum(a.total_balance) as total_bal
	from Reports.Risk.dm_ReportCollectionPlanRollBalance a
	where a.rep_dt = @dt2
	and a.r_year = year(  @dt2 )
	and a.r_month = month(  @dt2 )
	and (a.dpd_bucket = '(2)_1_30' and a.dpd_bucket_end = '(1)_0'
		or a.dpd_bucket = '(3)_31_60' and a.dpd_bucket_end = '(1)_0'
		or a.dpd_bucket = '(3)_31_60' and a.dpd_bucket_end = '(2)_1_30'
		or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(1)_0'
		or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(2)_1_30'
		or a.dpd_bucket = '(4)_61_90' and a.dpd_bucket_end = '(3)_31_60')
	group by a.rep_dt, a.product, a.dpd_bucket, a.dpd_bucket_end

	union all

	--PreDel -> Soft
	select a.rep_dt,
	a.product,
	'(1)_0' as dpd_bucket,
	'(2)_1_30' as dpd_bucket_end,
	sum(a.principal_rest) as motiv_balance	
	from Reports.Risk.dm_ReportCollectionPlanPredelSoft a
	where a.rep_dt = @dt2
	and a.seg3 = 'CM'
	group by a.rep_dt, a.product
	)
	select b.rep_dt, b.product, b.dpd_bucket, b.dpd_bucket_end,
	b.total_bal as buck_moves_balance, m.total_bal as motiv_balance,
	round(abs(b.total_bal - isnull(m.total_bal,0)),0) as delta

	into #check_bucket_moves

	from bucket_moves b
	left join motiv m
	on b.dpd_bucket = m.dpd_bucket
	and b.dpd_bucket_end = m.dpd_bucket_end
	and b.product = m.product
	;

	set @check5 = (select case when count(*) > 0 then 1 else 0 end from #check_bucket_moves a where a.delta > 10);



	--Predel->Soft (мотив отчет)
	drop table if exists #check_predel_soft;

	with cd as (
		select a.rep_dt, a.seg3,
		sum(a.principal_rest) as principal_rest
		from Reports.Risk.dm_ReportCollectionPlanPredelSoft a
		where a.rep_dt = @dt2
		and a.seg3 = 'CM'
		group by a.rep_dt, a.seg3
	), 
	ld as (
		select a.rep_dt, a.seg3,
		sum(a.principal_rest) as principal_rest	
		from Reports.Risk.dm_ReportCollectionPlanPredelSoft a
		where a.rep_dt = @dt1
		and a.seg3 = 'CM'
		group by a.rep_dt, a.seg3
	)
	select cd.rep_dt as cd_dt, ld.rep_dt as ld_dt, cd.seg3, 
	cd.principal_rest as bal_cd,  
	ld.principal_rest as bal_ld,
	round(cd.principal_rest - isnull(ld.principal_rest,0),2) as delta
	into #check_predel_soft
	from cd
	left join ld 
	on cd.seg3 = ld.seg3;

	set @check6 = (select case when count(*)>0 then 1 else 0 end from #check_predel_soft a	where a.delta < 0);



	--Платежи ФССП

	drop table if exists #check_fssp;

	with cd as (
	select a.rep_dt, a.seg, sum(a.pay_total) as pmt
	from Reports.Risk.dm_ReportCollectionPlanFSSPPmt a
	where a.rep_dt = @dt2
	group by a.rep_dt, a.seg
	),
	ld as (
	select a.rep_dt, a.seg, sum(a.pay_total) as pmt
	from Reports.Risk.dm_ReportCollectionPlanFSSPPmt a
	where a.rep_dt = @dt1
	group by a.rep_dt, a.seg
	)
	select cd.rep_dt as cd_dt, 
	ld.rep_dt as ld_dt,
	cd.seg,
	cd.pmt as cd_pmt,
	ld.pmt as lf_pmt,
	round(cd.pmt - isnull(ld.pmt,0),2) as delta
	into #check_fssp
	from cd
	left join ld
	on cd.seg = ld.seg
	;


	set @check7 = (select case when count(*)>0 then 1 else 0 end from #check_fssp a	where a.delta < 0);


	--Платежи по банкротам и принятым на баланс авто
	drop table if exists #bankrupt_balance;

	with cd as (
	select a.rep_dt, a.seg, a.stage2, sum(a.pay_total) as pmt
	from reports.Risk.dm_ReportCollectionPlanAgentsPays a
	where a.rep_dt = @dt2
	and a.stage2 in ('Банкрот','Баланс')
	group by a.rep_dt, a.seg, a.stage2
	),
	ld as (
	select a.rep_dt, a.seg, a.stage2, sum(a.pay_total) as pmt
	from reports.Risk.dm_ReportCollectionPlanAgentsPays a
	where a.rep_dt = @dt1
	and a.stage2 in ('Банкрот','Баланс')
	group by a.rep_dt, a.seg, a.stage2
	)
	select cd.rep_dt as cd_dt,
	ld.rep_dt as ld_dt,
	cd.seg,
	cd.stage2,
	cd.pmt as cd_pmt,
	ld.pmt as ld_pmt,
	round(cd.pmt - isnull(ld.pmt,0),0) as delta

	into #bankrupt_balance
	from cd
	left join ld
	on cd.seg = ld.seg
	and cd.stage2 = ld.stage2
	order by 3,4;


	set @check8 = (select case when count(*) > 0 then 1 else 0 end from #bankrupt_balance a	where a.delta < 0)
	   	 



	--кол-во по бакетам (в работе) мотивационый отчет <-> движение по бакетам

	drop table if exists #cnt_in_bucket_motiv_migr;
	
	with migr_rep_base as (
		select * from Reports.Risk.dm_ReportCollectionRollRates a
		where a.rep_dt = @dt2
		and a.seg3 in ('CM')
	), migr_rep as (
			  select a.product, '(1)_0' as dpd_bucket,'(1)_0' as dpd_bucket_end, a.[Same 0 pcs] as cnt from migr_rep_base a
		union select a.product, '(1)_0' as dpd_bucket,'(2)_1_30' as dpd_bucket_end, a.[Worse 0 -> 1-30 pcs] from migr_rep_base a
		union select a.product, '(2)_1_30' as dpd_bucket,'(1)_0' as dpd_bucket_end, a.[Improve 1-30 -> 0 pcs] from migr_rep_base a
		union select a.product, '(2)_1_30' as dpd_bucket,'(2)_1_30' as dpd_bucket_end, a.[Same 1-30 pcs] from migr_rep_base a
		union select a.product, '(3)_31_60' as dpd_bucket,'(1)_0' as dpd_bucket_end, a.[Improve 31-60 -> 0 pcs] from migr_rep_base a
		union select a.product, '(3)_31_60' as dpd_bucket,'(2)_1_30' as dpd_bucket_end, a.[Improve 31-60 -> 1-30 pcs] from migr_rep_base a
		union select a.product, '(3)_31_60' as dpd_bucket,'(3)_31_60' as dpd_bucket_end, a.[Same 31-60 pcs] from migr_rep_base a
		union select a.product, '(4)_61_90' as dpd_bucket,'(1)_0' as dpd_bucket_end, a.[Improve 61-90 -> 0 pcs] from migr_rep_base a
		union select a.product, '(4)_61_90' as dpd_bucket,'(2)_1_30' as dpd_bucket_end, a.[Improve 61-90 -> 1-30 pcs] from migr_rep_base a
		union select a.product, '(4)_61_90' as dpd_bucket,'(3)_31_60' as dpd_bucket_end, a.[Improve 61-90 -> 31-60 pcs] from migr_rep_base a
		union select a.product, '(4)_61_90' as dpd_bucket,'(4)_61_90' as dpd_bucket_end, a.[Same 61-90 pcs] from migr_rep_base a
		union select a.product, '(5)_91_360' as dpd_bucket,'improve' as dpd_bucket_end, a.[Improve 91_360 pcs] from migr_rep_base a
		union select a.product, '(5)_91_360' as dpd_bucket,'(5)_91_360' as dpd_bucket_end, a.[Same 91-360 pcs] from migr_rep_base a
		union select a.product, '(6)_361+' as dpd_bucket,'improve' as dpd_bucket_end, a.[Improve 361+ pcs] from migr_rep_base a
	), motiv_rep as (
		select 
		a.product,
		a.dpd_bucket, 
		case when a.dpd_bucket in ('(5)_91_360','(6)_361+') and 
		cast(SUBSTRING(a.dpd_bucket, 2, 1) as int) > cast(SUBSTRING(a.dpd_bucket_end, 2, 1) as int)
		then 'improve' else a.dpd_bucket_end end as dpd_bucket_end, 
		count(*) as cnt
		from Reports.Risk.dm_ReportCollectionPlanCMRCred a
		where a.rep_dt = @dt2
		and cast(SUBSTRING(a.dpd_bucket, 2, 1) as int) >= cast(SUBSTRING(a.dpd_bucket_end, 2, 1) as int)
		group by a.product, a.dpd_bucket, case when a.dpd_bucket in ('(5)_91_360','(6)_361+') and 
		cast(SUBSTRING(a.dpd_bucket, 2, 1) as int) > cast(SUBSTRING(a.dpd_bucket_end, 2, 1) as int)
		then 'improve' else a.dpd_bucket_end end
	union 
		select 
		a.product,
		N'(1)_0' as dpd_bucket,
		N'(2)_1_30' as dpd_bucket_end,
		sum(a.cnt_credit) as cnt
		from Reports.risk.dm_ReportCollectionPlanPredelSoft a
		where a.rep_dt = @dt2
		and a.seg3 = 'CM'
		group by a.product
	)
	select 
	a.product, a.dpd_bucket, a.dpd_bucket_end, a.cnt as cnt_migr_rep, b.cnt as cnt_motiv_rep,
	case when isnull(a.cnt,0) <> isnull(b.cnt,0) then 1 else 0 end as flag_different

	into #cnt_in_bucket_motiv_migr

	from migr_rep a
	left join motiv_rep b
	on a.dpd_bucket = b.dpd_bucket
	and a.dpd_bucket_end = b.dpd_bucket_end
	and a.product = b.product
	;

	set @check9 = (select case when sum(flag_different) > 0 then 1 else 0 end from #cnt_in_bucket_motiv_migr);


	--кол-во по бакетам (в работе) "движение по бакетам" НЕ уменьшается

	drop table if exists #migr_pieces;

	with ytd as (
	select * from Reports.Risk.dm_ReportCollectionRollRates a
	where a.rep_dt = @dt2
	and a.seg3 in ('CM','LMSD','LYSD')
	), ytd_m_1 as (
	select * from Reports.Risk.dm_ReportCollectionRollRates a
	where a.rep_dt = @dt1
	and a.seg3 in ('CM','LMSD','LYSD')
	)
	select 
	a.product,
	a.seg3,
	a.rep_dt as rdt_ytd,
	b.rep_dt as rdt_ytd_m_1,
	a.[Improve 1-30 -> 0 pcs] - b.[Improve 1-30 -> 0 pcs] as delta_impr_1_30_0,
	a.[Improve 31-60 -> 0 pcs] - b.[Improve 31-60 -> 0 pcs] as delta_impr_31_60_0,
	a.[Improve 31-60 -> 1-30 pcs] - b.[Improve 31-60 -> 1-30 pcs] as delta_impr_31_60_1_30,
	a.[Improve 61-90 -> 0 pcs] - b.[Improve 61-90 -> 0 pcs] as delta_impr_61_91_0,
	a.[Improve 61-90 -> 1-30 pcs] - b.[Improve 61-90 -> 1-30 pcs] as delta_impr_61_90_1_30,
	a.[Improve 61-90 -> 31-60 pcs] - b.[Improve 61-90 -> 31-60 pcs] as delta_impr_61_90_31_60,
	a.[Improve 91_360 pcs] - b.[Improve 91_360 pcs] as delta_impr_91_360,
	a.[Improve 361+ pcs] - b.[Improve 361+ pcs] as delta_impr_361,

	a.[Worse 0 -> 1-30 pcs] - b.[Worse 0 -> 1-30 pcs] as delta_worse_0,
	a.[Worse 1-30 -> 31-60 pcs] - b.[Worse 1-30 -> 31-60 pcs] as delta_worse_1_30,
	a.[Worse 31-60 -> 61-90 pcs] - b.[Worse 31-60 -> 61-90 pcs] as delta_worse_31_60,
	a.[Worse 61-90 -> 91-360 pcs] - b.[Worse 61-90 -> 91-360 pcs] as delta_worse_61_90,
	a.[Worse 91-360 pcs] - b.[Worse 91-360 pcs] as delta_worse_91_360

	into #migr_pieces

	from ytd a
	left join ytd_m_1 b
	on a.seg3 = b.seg3
	and a.product = b.product
	;

	set @check10 = (select 
	sum(
	case when a.delta_impr_1_30_0	   <= -3 then 1 else 0 end +
	case when a.delta_impr_31_60_0	   <= -3 then 1 else 0 end +
	case when a.delta_impr_31_60_1_30  <= -3 then 1 else 0 end +
	case when a.delta_impr_61_90_1_30  <= -3 then 1 else 0 end +
	case when a.delta_impr_61_90_31_60 <= -3 then 1 else 0 end +
	case when a.delta_impr_61_91_0	   <= -3 then 1 else 0 end +
	case when a.delta_impr_91_360	   <= -3 then 1 else 0 end +
	case when a.delta_impr_361		   <= -3 then 1 else 0 end +
	case when a.delta_worse_0		   <= -3 then 1 else 0 end +
	case when a.delta_worse_1_30	   <= -3 then 1 else 0 end +
	case when a.delta_worse_31_60	   <= -3 then 1 else 0 end +
	case when a.delta_worse_61_90	   <= -3 then 1 else 0 end +
	case when a.delta_worse_91_360	   <= -3 then 1 else 0 end 
	)
	from #migr_pieces a);


	--запись в журнал логгирования
	declare @v_tmp_info  varchar(500);

	set @v_tmp_info = concat('1. BUCKET PMT - ', case @check1 when 1 then 'ERROR' when 0 then 'OK' end);
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @v_tmp_info;

	set @v_tmp_info = concat('2. 0-90 HARD - ', case @check2 when 1 then 'ERROR' when 0 then 'OK' end);
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @v_tmp_info;

	set @v_tmp_info = concat('3. SAVED BALANCE - ', case @check3 when 1 then 'ERROR' when 0 then 'OK' end);
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @v_tmp_info;

	set @v_tmp_info = concat('4. AGENT PAYS - ', case @check4 when 1 then 'ERROR' when 0 then 'OK' end);
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @v_tmp_info;
	
	set @v_tmp_info = concat('5. BUCKET MOVEMENTS - ', case @check5 when 1 then 'ERROR' when 0 then 'OK' end);
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @v_tmp_info;

	set @v_tmp_info = concat('6. PREDEL -> SOFT - ', case @check6 when 1 then 'ERROR' when 0 then 'OK' end);
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @v_tmp_info;

	set @v_tmp_info = concat('7. FSSP PAYMENTS - ', case @check7 when 1 then 'ERROR' when 0 then 'OK' end);
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @v_tmp_info;

	set @v_tmp_info = concat('8. BANKR. and BAL.ADOPT PMTs - ', case @check8 when 1 then 'ERROR' when 0 then 'OK' end);
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @v_tmp_info;

	set @v_tmp_info = concat('9. MOTIV <-> MIGR cnt - ', case @check9 when 1 then 'ERROR' when 0 then 'OK' end);
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @v_tmp_info;

	set @v_tmp_info = concat('10. MIGR PIECES - ', case @check10 when 1 then 'ERROR' when 0 then 'OK' end);
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = @v_tmp_info;

	--drop временных таблиц

	drop table #check_0_90_hard;
	drop table #check_agent_pays;
	drop table #check_bucket_moves;
	drop table #check_pmt_1_plus;
	drop table #check_saved_balance;
	drop table #check_predel_soft;
	drop table #check_fssp;
	drop table #bankrupt_balance;

end;

else 

begin

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'DIFFERENT MONTHS, NOTHING TO CHECK';

end;

	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';
