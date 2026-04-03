


--exec [dbo].[prc$rep_coll_agents_portf] 
CREATE PROC collection.etl_rep_coll_agents_portf 

as 

SET DATEFIRST 1

declare @rdt date = dateadd(dd,-1, cast([collection].date_trunc('WK', cast(getdate() as date)) as date) ) ;--change RiskDWH.dbo.date_trunc
declare @srcname varchar(100) = 'UPDATE REP COLL AGENTS PORTFOLIO';

declare @vinfo varchar(500) = 'START rep_dt = ' + convert(varchar, @rdt, 104);



exec collection.set_debug_info @src = @srcname, @info = @vinfo;


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
	a.prev_dpd_coll as lag_overdue_days, 
	a.prev_dpd_p_coll as lag_overdue_days_p,
	a.prev_od as last_principal_rest,
	cast(isnull(principal_cnl,    0) as float) +
	cast(isnull(percents_cnl,     0) as float) +
	cast(isnull(fines_cnl,        0) as float) +
	cast(isnull(otherpayments_cnl,0) as float) +
	cast(isnull(overpayments_cnl, 0) as float) - cast(isnull(overpayments_acc, 0) as float) as pay_total,
	isnull([сумма поступлений], 0) as pay_total_calc
	into #CMR
	from dbo.dm_CMRStatBalance a
	where a.d >= '2023-01-01' and a.d <= @rdt;
	

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
	a.overdue_days,
	a.overdue_days_p,
	a.last_principal_rest,
	a.pay_total,
	a.pay_total
	from RiskDWH.dbo.det_business_loans a;


	drop index if exists tmp_cmr_idx on #CMR;
	create clustered index tmp_cmr_idx on #CMR (external_id, r_date);




----регион + фио + дата рождения

exec collection.set_debug_info @src = @srcname, @info = '#pre_application';

drop table if exists #pre_application;

select 
	z.Номер as external_id,
	concat( trim(' ' from z.Фамилия), ' ',
			trim(' ' from z.Имя), ' ',
			trim(' ' from z.Отчество), ' ',
			isnull(cast(z.ДатаРождения as date), cast('1900-01-01' as date))) as person_id,
	z.Регион as region,
	z.Дата,
	convert(nvarchar(max),z.АдресРегистрации) as АдресРегистрации,
	convert(nvarchar(max),z.АдресПроживания	) as АдресПроживания
	into #pre_application

	from stg._1cmfo.документ_ГП_заявка z with (nolock)
	where exists (select 1 from dbo.dm_overdueindicators t -- dwh_new.dbo.tmp_v_credits t
				where z.Номер = t.Number)
;


exec [collection].set_debug_info @src = @srcname, @info = '#stg_application';


drop table if exists #stg_application;

select zz.external_id, zz.person_id, zz.region, zz.АдресПроживания, zz.АдресРегистрации
into #stg_application
from (
	select a.external_id, a.person_id, a.region, a.АдресПроживания, a.АдресРегистрации, a.Дата,
	row_number() over (partition by a.external_id order by a.Дата desc) as rown	
	from #pre_application a
) zz
where zz.rown = 1;


exec collection.set_debug_info @src = @srcname, @info = '#credreg1';


drop table if exists #credreg1;

select a.external_id, 
a.АдресРегистрации as regis, 
a.АдресПроживания as living, 

CHARINDEX(',',a.АдресРегистрации, CHARINDEX(',',a.АдресРегистрации)+1)+1 as regis_region_from,

CHARINDEX(',',a.АдресРегистрации, CHARINDEX(',',a.АдресРегистрации, CHARINDEX(',',a.АдресРегистрации)+1)+1) 
 - CHARINDEX(',',a.АдресРегистрации, CHARINDEX(',',a.АдресРегистрации)+1) as regis_region_length,

CHARINDEX(',',a.АдресПроживания, CHARINDEX(',',a.АдресПроживания)+1)+1 as living_region_from,

CHARINDEX(',',a.АдресПроживания, CHARINDEX(',',a.АдресПроживания, CHARINDEX(',',a.АдресПроживания)+1)+1) 
 - CHARINDEX(',',a.АдресПроживания, CHARINDEX(',',a.АдресПроживания)+1)  as living_region_length,
b.region,
a.person_id

into #credreg1

from #stg_application a --stg._1cmfo.документ_ГП_заявка a
left join [collection].[det_region_pattern] b -- RiskDWH.dbo.det_region_pattern b
on upper(trim(a.region)) like b.pattern;


exec collection.set_debug_info @src = @srcname, @info = '#credreg2';

drop table if exists #credreg2;

select bs.external_id, bs.region, 
case 
when bs.regis_region_from > 0 and bs.regis_region_length > 0 
and SUBSTRING(bs.regis, bs.regis_region_from, bs.regis_region_length-1) <> ''
then SUBSTRING(bs.regis, bs.regis_region_from, bs.regis_region_length-1)

when bs.living_region_from > 0 and bs.living_region_length > 0 
and SUBSTRING(bs.living, bs.living_region_from, bs.living_region_length-1) <> ''
then SUBSTRING(bs.living, bs.living_region_from, bs.living_region_length-1)

else 'EMPTY' end as region_alt_base,

bs.regis,
bs.living,
bs.person_id

into #credreg2

from #credreg1 bs
where bs.region is null;


exec collection.set_debug_info @src = @srcname, @info = '#stg_final_app';

drop table if exists #stg_final_app;

select distinct  b.external_id,
isnull(b.region, z.region) as region,
b.person_id

into #stg_final_app

from #credreg1 b
left join #credreg2 bs2
on b.external_id = bs2.external_id
left join [collection].[det_region_pattern] z -- RiskDWH.dbo.det_region_pattern z
on upper(bs2.region_alt_base) like z.pattern

;


----для разметки 0-90 hard
	--1) отбираем входы и выходы в 91+
	exec collection.set_debug_info @src = @srcname, @info = '#stg_hard90_1';

	drop table if exists #stg_hard90_1;

	select aa.external_id, aa.r_date , aa.stage
	into #stg_hard90_1
	from (
		select b.external_id, b.r_date, 'OUT_91+' as stage
		from #CMR b
		where b.overdue_days_p >= 91 and b.overdue_days < 91 
		and b.r_date <= @rdt

		union all

		select b.external_id, b.r_date, 'IN_91+' as stage
		from #CMR b
		where b.overdue_days >= 91 and b.last_dpd < 91
		and b.r_date <= @rdt
	) aa
;


exec collection.set_debug_info @src = @srcname, @info = '#stg_hard90_2';

drop table if exists #stg_hard90_2;

	with base as (
	select a.external_id, a.r_date, a.stage,
	case when a.stage = 'OUT_91+' and lead(a.stage) over (partition by a.external_id order by a.r_date) = 'IN_91+' 
	then dateadd(dd,1,a.r_date)
	when a.stage = 'OUT_91+' and lead(a.stage) over (partition by a.external_id order by a.r_date) is null 
	then dateadd(dd,1,a.r_date)
	end as dt_from,

	case when a.stage = 'OUT_91+' and lead(a.stage) over (partition by a.external_id order by a.r_date) = 'IN_91+' 
	then dateadd(dd,-1,lead(a.r_date) over (partition by a.external_id order by a.r_date))
	when a.stage = 'OUT_91+' and lead(a.stage) over (partition by a.external_id order by a.r_date) is null 
	then @rdt
	end as dt_to

	from #stg_hard90_1 a
	)

	select bs.external_id, bs.dt_from, bs.dt_to 

	into #stg_hard90_2

	from base bs
	where bs.stage = 'OUT_91+'
	and bs.dt_from is not null
	and bs.dt_to is not null;


--3) проверяем, что во время периодов между 91+ не было выхода в нулевой бакет
	----3.1) находим периоды, кодга был нулевой бакет
	exec collection.set_debug_info @src = @srcname, @info = '#stg_hard90_31';

	drop table if exists #stg_hard90_31;

	select distinct a.external_id, a.dt_from, a.dt_to

	into #stg_hard90_31

	from #stg_hard90_2 a
	left join #CMR b
	on a.external_id = b.external_id
	and b.r_date between a.dt_from and a.dt_to
	where b.overdue_days = 0;

	----3.2) исключаем периоды с нулевым бакетом

	exec collection.set_debug_info @src = @srcname, @info = '#stg_hard90_32';

	drop table if exists #stg_hard90_32;

	select a.external_id, a.dt_from, a.dt_to

	into #stg_hard90_32

	from #stg_hard90_2 a
	where not exists (
	select 1 from #stg_hard90_31 b
	where a.external_id = b.external_id
	and a.dt_from = b.dt_from
	and a.dt_to = b.dt_to
	)


--4) проверяем, чтобы были платежи во время периодов между 91+
	--собираем все платежи в данные периоды
	exec collection.set_debug_info @src = @srcname, @info = '#stg_hard90_4';

	drop table if exists #stg_hard90_4;

	select a.external_id, a.dt_from, a.dt_to, b.r_date, b.pay_total
	into #stg_hard90_4
	from #stg_hard90_32 a
	left join #CMR b
	on a.external_id = b.external_id
	and b.r_date between a.dt_from and a.dt_to
	and b.pay_total > 0
	;


--5) финальный реестр 0-90 hard
exec collection.set_debug_info @src = @srcname, @info = '#stg_hard90_5';

	drop table if exists #stg_hard90_5;

	select a.external_id, a.dt_from, a.dt_to

	into #stg_hard90_5

	from #stg_hard90_32 a
	where exists (select 1 
	from #stg_hard90_4 b
	where a.external_id = b.external_id
	and a.dt_from = b.dt_from
	and a.dt_to = b.dt_to
	and b.pay_total > 0);


--основа для построения отчетов
exec collection.set_debug_info @src = @srcname, @info = '#mfo_base';

	drop table if exists #mfo_base;

		select aa.external_id, aa.r_date, 
		aa.dpd_bucket_p_alt as dpd_bucket_p_,
		aa.dpd_bucket_alt as dpd_bucket_to_,
		aa.pay_total, aa.dpd_bucket_p_cmr,
		aa.r_day, aa.r_month, aa.r_year, aa.overdue_days_p as overdue_days_p_cmr,
		aa.dpd_bucket_cmr,
		aa.person_id,
		aa.region,
		aa.total_wo,
		aa.principal_rest

		into #mfo_base
		from (

		select b.external_id, b.r_date, b.pay_total, 

		case when c.external_id is not null and b.overdue_days_p <= 90
		then '[09] 0-90 hard' 
		else b.dpd_bucket_p end as dpd_bucket_p_alt,

		case when c.external_id is not null and b.overdue_days <= 90 		
		then '[09] 0-90 hard' 
		else b.dpd_bucket end as dpd_bucket_alt,
		
		isnull(b.overdue_days_p,0) as overdue_days_p,
		b.dpd_bucket_p as dpd_bucket_p_cmr,
		b.dpd_bucket as dpd_bucket_cmr,
		b.r_day, b.r_month, b.r_year,
		b.principal_rest,
		app.person_id,
		app.region,
		cast(null as float) as total_wo

		from #CMR b
		
		left join #stg_hard90_5 c
		on b.external_id = c.external_id
		and b.r_date between dateadd(dd,-1,c.dt_from) and c.dt_to

		left join #stg_final_app app
		on b.external_id = app.external_id

		where b.r_date between  cast('2023-01-01' as date) and @rdt  ---'2019-12-01'заменил

		
		)  aa

		;


--учет каникул с октября 2020

exec collection.set_debug_info @src = @srcname, @info = 'merge1 into #mfo_base (kk)';


	merge into #mfo_base dst 
	using (
		select a.external_id, a.r_date, c.dpd_bucket_p as dpd_bucket, c.overdue_days_p as dpd
		from #mfo_base a
		inner join RiskDWH.dbo.det_kk_cmr_and_space b
		on a.external_id = b.external_id
		and a.r_date between b.dt_from and b.dt_to
		left join #CMR c
		on a.external_id = c.external_id
		and b.dt_from = c.r_date
		where 1=1
		--and a.r_date between '2020-10-01' and '2020-10-31'
		and EOMONTH(a.r_date) = EOMONTH(dateadd(dd,1,b.dt_from))		
		and a.pay_total > 0
	) src
	on (dst.external_id = src.external_id and dst.r_date = src.r_date)
	when matched then update set 
		dst.dpd_bucket_p_ = src.dpd_bucket,
		dst.dpd_bucket_to_ = src.dpd_bucket,
		dst.dpd_bucket_p_cmr = src.dpd_bucket,
		dst.dpd_bucket_cmr = src.dpd_bucket,
		dst.overdue_days_p_cmr = src.dpd
		;


	--26/11/20 Для учета платежей на стадии СБ (служба безопасности) в бакетах до 90+, которые в работе у Hard/Legal
	--10/12/20 Платежи из стадии Closed, перед закрытием была стадия СБ

exec collection.set_debug_info @src = @srcname, @info = '#stg_sb_0_90';

	drop table if exists #stg_sb_0_90;
	
	select a.external_id, a.r_date
	into #stg_sb_0_90
	from #mfo_base a
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
	--кроме бакетов, которые и так учитываются в 91+ или 0-90 Hard
	and a.dpd_bucket_p_ not in ('(5)_91_360','(6)_361+','[09] 0-90 hard')
	--статус договора на момент платежа Legal
	and d.[Name] = 'Legal'
	--была просрочка более 90 дней (соответственно стадия Legal)
	and exists (select 1 from #CMR e
		where a.external_id = e.external_id
		and a.r_date > e.r_date
		and e.overdue_days_p > 90)
	--в день платежа не был у агента
	and not exists (
		--DWH-257
		select top(1) 2 
		from (
			select 
				d.Number as External_id
				,cat.TransferDate as st_date 
				,cat.ReturnDate as fact_end_date
				,cat.PlannedReviewDate as plan_end_date
			from Stg._collection.CollectingAgencyTransfer as cat
				inner join Stg._collection.Deals as d
					on d.Id = cat.DealId
			) as f
		where a.external_id = f.external_id
			and a.r_date between f.st_date and f.fact_end_date
	) --end_date)
		;


exec collection.set_debug_info @src = @srcname, @info = 'merge2 into #mfo_base (SB)';

	merge into #mfo_base dst
	using #stg_sb_0_90 src 
	on (dst.external_id = src.external_id and dst.r_date = src.r_date)
	when matched then update set 
	dst.dpd_bucket_p_ = '[09] 0-90 hard';


--отсечение 0-90 Hard

exec collection.set_debug_info @src = @srcname, @info = '#reestr_0_90_hard';

	drop table if exists #reestr_0_90_hard;
	select a.external_id, a.r_date, a.dpd_bucket_p_cmr, a.pay_total,
	b.CRMClientStage, 
	case when isnull(c.agent_name,'CarMoney') <> 'CarMoney' then 'KA'
	else 'CarMoney' end as agent_gr

	into #reestr_0_90_hard

	from #mfo_base a
	left join RiskDWH.dbo.stg_client_stage b
	on a.external_id = b.external_id
	and a.r_date = b.cdate
	--DWH-257
	left join (
		select
			agent_name = a.AgentName
			,reestr = RegistryNumber
			,external_id = d.Number
			,st_date  = cat.TransferDate
			,fact_end_date = cat.ReturnDate
			,plan_end_date = cat.PlannedReviewDate
			,end_date = isnull(cat.ReturnDate, cat.PlannedReviewDate)
		from Stg._collection.CollectingAgencyTransfer as cat
			inner join Stg._collection.Deals as d
				on d.Id = cat.DealId
			inner join Stg._collection.CollectorAgencies as a
				on a.Id = cat.CollectorAgencyId
	) as c
	on a.external_id = c.external_id
	and a.r_date between c.st_date and c.fact_end_date --end_date
	where a.pay_total > 0
	and a.dpd_bucket_p_cmr in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')
	and (
		b.CRMClientStage = 'Legal' and a.dpd_bucket_p_cmr in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')
		or b.CRMClientStage = 'Hard' and a.dpd_bucket_p_cmr in ('(2)_1_30','(3)_31_60','(4)_61_90')
		or isnull(c.agent_name,'CarMoney') not in ('CarMoney','ACB') /*in ('Povoljie','Alfa','Prime Collection','Ilma','MBA') */
				and a.dpd_bucket_p_cmr in ('(1)_0','(2)_1_30','(3)_31_60','(4)_61_90')
	)
	;



exec collection.set_debug_info @src = @srcname, @info = 'merge3 into #mfo_base (0-90 hard)';

	merge into #mfo_base dst
	using #reestr_0_90_hard src
	on (dst.external_id = src.external_id and dst.r_date = src.r_date)
	when matched then update set dst.dpd_bucket_p_ = '[09] 0-90 hard';


	
	drop table #credreg1;
	drop table #credreg2;
	drop table #reestr_0_90_hard;
	drop table #stg_application;
	drop table #stg_final_app;
	drop table #stg_hard90_1;
	drop table #stg_hard90_2;
	drop table #stg_hard90_31;
	drop table #stg_hard90_32;
	drop table #stg_hard90_4;
	drop table #stg_hard90_5;
	drop table #stg_sb_0_90;

/*******************************************************************************/

--база для отчета - дополняем отметками дат: конец месяца и конец недели, и инфо по агентам

	drop table if exists #rep_base;
	select 
	a.external_id, a.r_date, a.r_year, a.r_month, 
	datepart(wk,a.r_date) as r_week, 
	max(a.r_date) over (partition by a.r_year, datepart(wk,a.r_date)) as dt_week_end,
	eomonth(a.r_date) as dt_month_end,
	a.dpd_bucket_p_, a.principal_rest, a.pay_total, a.total_wo,
	a.person_id, a.region, 
	case when isnull(b.agent_name,'Carmoney') in ('Carmoney','ACB') then 'Carmoney'
	when a.dpd_bucket_p_ = '[09] 0-90 hard' then 'Carmoney'
	else b.agent_name end as agent_name,
	case when isnull(b.agent_name,'Carmoney') in ('Carmoney','ACB') then 0
	when a.dpd_bucket_p_ = '[09] 0-90 hard' then 0
	else b.reestr end as agent_reestr
	
	into #rep_base
	from #mfo_base a
	--DWH-257
	left join (
		select
			agent_name = a.AgentName
			,reestr = RegistryNumber
			,external_id = d.Number
			,st_date  = cat.TransferDate
			,fact_end_date = cat.ReturnDate
			,plan_end_date = cat.PlannedReviewDate
			,end_date = isnull(cat.ReturnDate, cat.PlannedReviewDate)
		from Stg._collection.CollectingAgencyTransfer as cat
			inner join Stg._collection.Deals as d
				on d.Id = cat.DealId
			inner join Stg._collection.CollectorAgencies as a
				on a.Id = cat.CollectorAgencyId
		) as b
	on a.external_id = b.external_id
	and a.r_date between b.st_date and b.fact_end_date--end_date
	where a.dpd_bucket_p_ in ('(5)_91_360','(6)_361+','[09] 0-90 hard')
	;


   	  
exec collection.set_debug_info @src = @srcname, @info = 'REP WEEKLY';

begin transaction;

	delete from RiskDWH.dbo.rep_weekly_coll_agents_portf
	where rep_dt = @rdt;

	with pmt as (
		select a.r_year, a.r_week, a.agent_name, a.agent_reestr, a.region,
		count(distinct a.person_id) as cnt_payers,
		count(*) as cnt_payments,
		sum(a.pay_total) as cash_in,
		sum(a.total_wo) as total_wo
	
		from #rep_base a
		where a.pay_total > 0
		group by a.r_year, a.r_week, a.agent_name, a.agent_reestr, a.region
	), portf as (
		select a.r_year, a.r_week, a.agent_name, a.agent_reestr, a.region,
		sum(isnull(a.principal_rest,0)) as od,
		count(*) as cred_cnt
		from #rep_base a
		where a.r_date = a.dt_week_end
		group by a.r_year, a.r_week, a.agent_name, a.agent_reestr, a.region
		)
	insert into RiskDWH.dbo.rep_weekly_coll_agents_portf

		select 
		@rdt as rep_dt,
		cast(SYSDATETIME() as datetime) as dt_dml,
		a.r_year as [Отчетный Год],
		a.r_week as [Отчетная Неделя] ,
		a.agent_name as [Агент],
		a.agent_reestr as [Реестр Агента],
		a.region as [Регион],
		a.cred_cnt as [Кол-во Договоров],
		a.od / 1000000.0 as [Остаток ОД],
		isnull(b.cnt_payers		,0) as [Кол-во Плательщиков],		
		isnull(b.cnt_payments	,0) as [Кол-во Платежей]	,
		case 
		--бизнес-займы в декабре 2020 в харде
		when a.r_year = 2020 and a.r_week = 52 and a.region = 'Москва г' 
			and a.agent_name = 'carmoney' and a.agent_reestr = 0
		then isnull(b.cash_in,0) / 1000000.0 + (130000.0 + 216000.0 + 1400000.0 + 2004300.0 + 122280.0) / 1000000.0
		--бизнес-займы в январе 2021 в харде
		when a.r_year = 2021 and a.r_week = 5 and a.region = 'Москва г' 
			and a.agent_name = 'carmoney' and a.agent_reestr = 0
		then isnull(b.cash_in,0) / 1000000.0 + (252280.0 + 216000.0 + 108000.0) / 1000000.0


		else isnull(b.cash_in,0) / 1000000.0 end as [Сумма Recovery],
		
		isnull(b.total_wo		,0) / 1000000.0 as [Сумма Списаний]		
	
		from portf a
		left join pmt b 
		on a.r_year = b.r_year
		and a.r_week = b.r_week
		and a.agent_name = b.agent_name
		and a.agent_reestr = b.agent_reestr
		and isnull(a.region, 'n') = isnull(b.region, 'n')

		;

commit transaction;



exec collection.set_debug_info @src = @srcname, @info = 'REP MONTHLY';

begin transaction;

	delete from RiskDWH.dbo.rep_monthly_coll_agents_portf
	where rep_dt = @rdt;

	with pmt as (
	select a.r_year, a.r_month, a.agent_name, a.agent_reestr, a.region,
	count(distinct a.person_id) as cnt_payers,
	count(*) as cnt_payments,
	sum(a.pay_total) as cash_in,
	sum(a.total_wo) as total_wo
	
	from #rep_base a
	where a.pay_total > 0
	group by a.r_year, a.r_month, a.agent_name, a.agent_reestr, a.region
   ), portf as (
	select a.r_year, a.r_month, a.agent_name, a.agent_reestr, a.region,
	sum(isnull(a.principal_rest,0)) as od,
	count(*) as cred_cnt
	from #rep_base a
	where a.r_date = a.dt_month_end
	group by a.r_year, a.r_month, a.agent_name, a.agent_reestr, a.region
	)
insert into RiskDWH.dbo.rep_monthly_coll_agents_portf


	select 
	@rdt as rep_dt,
	cast(SYSDATETIME() as datetime) as dt_dml,
	a.r_year as [Отчетный Год],
	a.r_month as [Отчетный Месяц],
	a.agent_name as [Агент],
	a.agent_reestr as [Реестр Агента],
	a.region as [Регион],
	a.cred_cnt as [Кол-во Договоров],
	a.od / 1000000.0 as [Остаток ОД],
	isnull(b.cnt_payers		,0) as [Кол-во Плательщиков],		
	isnull(b.cnt_payments	,0) as [Кол-во Платежей]	,
	case 
	--бизнес-займы в декабре 2020 в харде
	when a.r_year = 2020 and a.r_month = 12 and a.region = 'Москва г' 
		and a.agent_name = 'carmoney' and a.agent_reestr = 0
	then isnull(b.cash_in,0) / 1000000.0 + (130000.0 + 216000.0 + 1400000.0 + 2004300.0 + 122280.0) / 1000000.0
	--бизнес-займы в декабре 2020 в харде
	when a.r_year = 2021 and a.r_month = 1 and a.region = 'Москва г' 
		and a.agent_name = 'carmoney' and a.agent_reestr = 0
	then isnull(b.cash_in,0) / 1000000.0 + (252280.0 + 216000.0 + 108000.0) / 1000000.0
	else 
	isnull(b.cash_in,0) / 1000000.0 end as [Сумма Recovery],
	
	isnull(b.total_wo,0) / 1000000.0 as [Сумма Списаний]		
	from portf a
	left join pmt b 
	on a.r_year = b.r_year
	and a.r_month = b.r_month
	and a.agent_name = b.agent_name
	and a.agent_reestr = b.agent_reestr
	and isnull(a.region, 'n') = isnull(b.region, 'n')

	
--24/12/2020
--ООО Эдельйвейс 130000 руб
--ИП Петров -216000 руб
--ИП Ильясов - 1400000 руб.
--28/12/2020
--2004300
--122280 



commit transaction;



exec collection.set_debug_info @src = @srcname, @info = 'drop temp (#) tables';

--Финальный дроп временных таблиц:
drop table #mfo_base;
drop table #rep_base;
drop table #CMR;


exec collection.set_debug_info @src = @srcname, @info = 'FINISH';
