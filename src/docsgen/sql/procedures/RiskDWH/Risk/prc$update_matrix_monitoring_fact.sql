

/**************************************************************************
Процедура для обновления фактического среза для мониторинга матриц миграций

Для расчета требуются обновленные на дату @rdt таблицы с префиксом risk.stg_fcst_*
процедура [Risk].[prc$update_umfo_fact_for_model]

Revisions:
dt			user				version		description
14/06/22	datsyplakov			v1.0		Создание процедуры
16/06/22	datsyplakov			v1.1		Корректировка разметки SEGMENT_RBP: до 2022 на основе таблицы FIX, после по таблице dwh2.risk.credits
05/04/23	datsyplakov			v1.2		Добавлен сегмент "ПТС31" (ИспСрок)
13/04/23	datsyplakov			v1.3		Добавлен сегмент "ПТС31-РБП4" (ИспСрок без пролонгаций)
10/11/23	datsyplakov			v1.4		Удалены лишние временные таблицы и блок 2.5. Добавлена сегментация L1/L2/... для Installment
											Оптимизация: 
											- переработка #base_for_stg3_agg
											- убрано условие EXISTS в cmrstatbalance для #cred_reestr




*************************************************************************/


CREATE procedure [Risk].[prc$update_matrix_monitoring_fact]
@rdt date
as


declare @vinfo varchar(1000);
declare @srcname varchar(100) = 'UPDATE Migration Matrix monitoring fact';

set @rdt = eomonth(@rdt);

--------------------------------------------------------------------------------------------------------
-- PART 1 - формирование реестра договоров, расчет баланса на даты 
--------------------------------------------------------------------------------------------------------


begin try


	set @vinfo = concat('START rdt = ', format(@rdt,'dd.MM.yyyy'))
	exec dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;




	exec dbo.prc$set_debug_info @src = @srcname, @info = '#stg_write_off';



	--Справочники для правки "перескоков" через бакет
	drop table if exists #det_bucket_360;
	select * 
	into #det_bucket_360
	from (values
	('[01] 0', 1),
	('[02] 1-30', 2),
	('[03] 31-60', 3),
	('[04] 61-90', 4),
	('[05] 91-120', 5),
	('[06] 121-180', 6),
	('[07] 181-270', 7),
	('[08] 271-360', 8),
	('[09] 360+', 9)
	) a (dpd_bucket_360, dpd_num);


	drop table if exists #det_bucket_90;
	select *  
	into #det_bucket_90
	from (values
	('[01] 0', 1),
	('[02] 1-30', 2),
	('[03] 31-60', 3),
	('[04] 61-90', 4),
	('[05] 90+', 5)) a (dpd_bucket_90, dpd_num);



	exec dbo.prc$set_debug_info @src = @srcname, @info = '#det_bucket';



	drop table if exists #cred_end_date;
	select d.Код as external_id,
		   cast(dateadd(year,-2000,max(sd.Период)) as date) as end_date
	into #cred_end_date
	from stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
	inner join stg._1ccmr.Справочник_Договоры d on d.Ссылка=sd.договор
	inner join stg._1ccmr.Справочник_СтатусыДоговоров  ssd on ssd.Ссылка=sd.Статус
	where ssd.Наименование='Погашен'
	group by d.Код;



	exec dbo.prc$set_debug_info @src = @srcname, @info = '#cred_end_date';




	--Статусы договоров из ЦМР
	drop table if exists #cred_CMR_status;
	select b.Код as external_id, 
	b.Клиент as client_cmr_id,
	b.IsInstallment,
	dateadd(yy,-2000,a.Период) as dt_status,  
	c.Наименование as cred_status,
	ROW_NUMBER() over (partition by b.Код order by a.Период desc) as rown
	into #cred_CMR_status
	from stg._1cCMR.РегистрСведений_СтатусыДоговоров a
	inner join stg._1cCMR.Справочник_Договоры b
	on a.Договор = b.Ссылка
	inner join stg._1cCMR.Справочник_СтатусыДоговоров c
	on a.Статус = c.Ссылка
	;

	delete from #cred_CMR_status where rown <> 1;


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#cred_CMR_status';


	---Заморозки

	drop table if exists #stg1_zamorozka;
	select a.Договор as Договор, a.Дата as Дата 
	into #stg1_zamorozka
	from stg._1cCMR.РегистрСведений_Реструктуризация a
	--from prodsql02.cmr.dbo.[РегистрСведений_Реструктуризация] a
	where Активность = 0x01
	and Заявление != 0x00000000000000000000000000000000
	and ВидРеструктуризации =  0xA2CC005056839FE911EBAEEEA6BD272F --Заморозка 1.0
	and a.Дата <= dateadd(yy,2000,@rdt)
	;


	drop table if exists #stg2_zamorozka;
	select b.Код as external_id, eomonth(dateadd(yy,-2000,cast(a.Дата as date))) as freeze_dt
	into #stg2_zamorozka
	from #stg1_zamorozka a
	left join stg._1cCMR.Справочник_Договоры b
	on a.Договор = b.Ссылка
	;

	drop table if exists #zamorozka;
	select a.external_id, 
	min(a.freeze_dt) as freeze_from,
	eomonth(max(a.freeze_dt),3) as freeze_to
	into #zamorozka
	from #stg2_zamorozka a
	where a.external_id not in ('21063000118279') --тест заморозки
	group by a.external_id
	;


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#zamorozka';


	--Банкроты

	drop table if exists #stg_bankrupt;
	select a.Контрагент as contragent,
	min(cast(dateadd(yy,-2000,a.дата) as date)) as dt
	into #stg_bankrupt
	--from [c2-vsr-sql04].[UMFO].[dbo].[Документ_АЭ_БанкротствоЗаемщика] a
	from stg._1cUMFO.Документ_АЭ_БанкротствоЗаемщика a
	group by a.Контрагент;


	drop table if exists #bankrupt;
	select distinct a.Ссылка as ssylka, b.dt, a.НомерДоговора as external_id
	into #bankrupt
	from stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный a
	inner join #stg_bankrupt b
	on a.Контрагент = b.contragent
	where a.НомерДоговора <> '1'
	;


	--очищаем реестр заморозки от банкротов (отдельный бакет)
	with a as (select * from #zamorozka a)
	delete from a
	where exists (select 1 from #bankrupt b where a.external_id = b.external_id and b.dt <= @rdt)
	;



	exec dbo.prc$set_debug_info @src = @srcname, @info = '#bankrupt';





	
	--Выделяем повторники в фактических выдачах Installment


	drop table if exists #det_repeat_cred;
	with base as (
		select a.external_id, 
		a.person_id, 
		ROW_NUMBER() over (partition by a.person_id order by a.startdate) as L,
		a.generation
		from dwh2.risk.credits a
		where a.IsInstallment = 1
		and a.generation >= '2022-11-01'
	)
	select a.external_id, 
	case
	when a.L = 1 then cast('other' as varchar(100))
	when datediff(MM, b.generation, a.generation) < 6 then 'L2'
	when datediff(MM, b.generation, a.generation) < 12 then 'L3'
	when datediff(MM, b.generation, a.generation) < 18 then 'L4'
	when datediff(MM, b.generation, a.generation) >= 18 then 'L5'
	end as segment_rbp
	into #det_repeat_cred
	from base a
	left join base b
	on a.person_id = b.person_id
	and b.L = 1

	;

	exec dbo.prc$set_debug_info @src = @srcname, @info = '#det_repeat_cred';



	--Перечень договоров
	drop table if exists #cred_reestr;

	select DISTINCT 
	a.external_id, 
	eomonth(cast(a.startdate as date)) as generation, 
	cast(a.startdate as date) as credit_date,
	case when eomonth(cast(a.startdate as date)) = EOMONTH(b.end_date) then 1 else 0 end as flag_closed_in_month,
	

	--15.06.2022 - новый алгоритм: до 2022г - FIX, с 2022г по таблице dwh2.risk.credits
	case 
	when a.credit_type_init = 'PTS_31' and a.rbp_gr = 'NotRBP_PROBATION' then 'PTS31'
	when a.credit_type_init = 'PTS_31' then 'PTS31_RBP4'
	else coalesce(
		fr.segment_rbp, 
		case
		when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 1' then 'GR 40/50'
		when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 2' then 'GR 56/66'
		when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 3' then 'GR 86/96'
		when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 4' then 'GR 86/96'
		end,
		rp.segment_rbp,
		'other'
	) end as segment_rbp,

	isnull(b.end_date, cast('4444-01-01' as date)) as end_date,
	a.amount,
	a.term,
	cast(a.InitialRate as float) as int_rate,
	cast(
		case 
		when rz.external_id is not null then concat('CESS ', format(eomonth(rz.action_date),'yyyy-MM-dd'))
		when bkr.external_id is not null then 'BANKRUPT'
		when d.external_id is not null then 'KK'
		when cmr.IsInstallment = 1 then 'INSTALLMENT'
		else 'USUAL'
		end 
	as varchar(100)) as flag_kk

	into #cred_reestr

	from dwh2.risk.credits a
	left join #cred_end_date b
	on a.external_id = b.external_id
	left join RiskDWH.[CM\N.Vlasova].rbp_segments c
	on a.external_id = c.number

	left join RiskDWH.dbo.det_kk_cmr_and_space d
	on a.external_id = d.external_id

	left join dwh2.risk.REG_CRM_REDZONE rz
	on a.external_id = rz.external_id
	and rz.action_type like '%Цессия%'

	left join (select distinct external_id, dt from #bankrupt) bkr
	on a.external_id = bkr.external_id
	and bkr.dt <= @rdt

	left join stg._1cCMR.Справочник_Договоры cmr
	on a.external_id = cmr.Код
	
	--15.06.2022 
	left join risk.stg_fcst_fix_rbp fr
	on a.external_id = fr.external_id

	left join #det_repeat_cred rp
	on a.external_id = rp.external_id

	where cast(a.startdate as date) between cast('2016-01-01' as date) and @rdt
	and not exists (select 1 from #cred_CMR_status sts where a.external_id = sts.external_id and sts.cred_status = 'Внебаланс')
	;



	--31/08/2021 - Бизнес-займы
	insert into #cred_reestr 
	(external_id, generation, credit_date, flag_closed_in_month, segment_rbp, end_date, amount, term, int_rate, flag_kk)
	select external_id, generation, credit_date, flag_closed_in_month, segment_rbp, end_date, amount, term, int_rate, flag_kk
	--from #bus_cred_reestr a
	from RiskDWH.Risk.stg_fcst_bus_cred a
	where a.generation <= @rdt
	;



	drop index if exists idx_cred_reestr on #cred_reestr;
	create clustered index idx_cred_reestr on #cred_reestr (external_id);


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#cred_reestr';


	--Историческая просрочка
	drop table if exists #det_historical_dpd;

	select a.r_date, a.external_id, a.dpd_final
	into #det_historical_dpd
	from RiskDWH.risk.stg_fcst_hist_dpd a
	where a.r_date <= @rdt
	and a.dpd_final is not null;


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#det_historical_dpd';



	--Остатки на различные MOB-ы
	drop table if exists #stg_bal;

	select
	a.external_id, 
	a.generation,
	a.term,
	a.segment_rbp,
	a.flag_kk,
	b.d as mob_date,
	DATEDIFF(MM, a.generation, b.d) as mob,
	--b.dpd_bucket_360, 
	--cast(SUBSTRING(b.dpd_bucket_360,2,2) as int) as dpd_bucket_num_360,

	RiskDWH.dbo.get_bucket_360_m( isnull(h.dpd_final, b.dpd) ) as dpd_bucket_360,

	cast(SUBSTRING(RiskDWH.dbo.get_bucket_360_m( isnull(h.dpd_final, b.dpd) ),2,2) as int) as dpd_bucket_num_360,

	RiskDWH.dbo.get_bucket_90( isnull(h.dpd_final, b.dpd) ) as dpd_bucket_90,

	cast(SUBSTRING(RiskDWH.dbo.get_bucket_90( isnull(h.dpd_final, b.dpd) ),2,2) as int) as dpd_bucket_num_90,

	isnull(h.dpd_final, b.dpd) as overdue_days,

	cast(isnull(b.[остаток од],0) as float) as principal_rest,
	a.end_date

	into #stg_bal
	from #cred_reestr a
	inner join dwh2.dbo.dm_CMRStatBalance b (nolock)

	--inner join Risk.portf_cmr b
	--left join Risk.portf_mfo b
	on a.external_id = b.external_id
	and b.d >= '2016-01-01'
	and b.d = EOMONTH(b.d)
	and b.d <= @rdt --'2020-08-31'

	left join #det_historical_dpd h
	on a.external_id = h.external_id
	and b.d = h.r_date





	--31/08/2021 - Бизнес-займы
	insert into #stg_bal 
	(external_id, generation, term, segment_rbp, flag_kk, mob_date, mob, 
	dpd_bucket_360, dpd_bucket_num_360, dpd_bucket_90, dpd_bucket_num_90,
	overdue_days, principal_rest, end_date)
	select external_id, generation, term, segment_rbp, flag_kk, mob_date, mob, 
	dpd_bucket_360, dpd_bucket_num_360, dpd_bucket_90, dpd_bucket_num_90,
	overdue_days, principal_rest, end_date 
	from RiskDWH.risk.stg_fcst_bus_bal a
	where a.mob_date <= @rdt
	;


	--23/12/2021 - берем последний факт из УМФО
	drop table if exists #umfo_last_fact;
	select 
	a.external_id, 
	a.r_date,
	a.total_od as od
	into #umfo_last_fact
	from RiskDWH.Risk.stg_fcst_umfo a
	--where a.r_date = @rdt
	where a.r_date between '2021-12-31' and @rdt
	;



	update a 
	set a.principal_rest = case when b.external_id is null then 0 else b.od end
	from #stg_bal a
	left join #umfo_last_fact b
	on a.external_id = b.external_id
	and a.mob_date = b.r_date
	--where a.mob_date = @rdt
	where a.mob_date between '2021-12-31' and @rdt;
	;


	drop table #umfo_last_fact;


	--для учета погашенных в нулевом MoB-е

	 merge into #stg_bal dst
	 using #cred_reestr src 
	 on (dst.mob_date = src.generation and dst.external_id = src.external_id)
	 when not matched then insert (
	 external_id, generation, term, segment_rbp, flag_kk, mob_date, mob, 
	 dpd_bucket_360, dpd_bucket_num_360, dpd_bucket_90, dpd_bucket_num_90, overdue_days, principal_rest, end_date
	 )
	 values (
	 src.external_id, src.generation, src.term, src.segment_rbp, src.flag_kk, src.generation, 0, '[01] 0', 1, '[01] 0', 1, 0, src.amount, src.end_date
	 )
	 when matched then update set 
	 dst.principal_rest = src.amount
	 ;




	--23/09/2021 - Заморозка

	update a set a.dpd_bucket_90 = '[07] Freeze', a.dpd_bucket_360 = '[11] Freeze' 
	from #stg_bal a
	inner join #zamorozka b
	on a.external_id = b.external_id
	and a.mob_date between b.freeze_from and b.freeze_to
	where a.flag_kk = 'KK'
	;


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#stg_bal';


	--сборка переходов подоговорно (присоединение t+1 MOB к t)
	drop table if exists #stg_matrix_detail; 

	select 
	a.external_id, 
	a.generation, 
	a.term,
	a.segment_rbp,
	a.flag_kk,

	a.mob_date as mob_date_from,
	b.mob_date as mob_date_to,
	a.mob as mob_from,
	b.mob as mob_to,
	a.principal_rest,
	b.principal_rest as principal_rest_to,

	a.dpd_bucket_360 as bucket_360_from,
	b.dpd_bucket_360 as bucket_360_to,
	a.dpd_bucket_num_360 as bucket_num_360_from,
	b.dpd_bucket_num_360 as bucket_num_360_to,

	a.dpd_bucket_90 as bucket_90_from,
	b.dpd_bucket_90 as bucket_90_to,
	a.dpd_bucket_num_90 as bucket_num_90_from,
	b.dpd_bucket_num_90 as bucket_num_90_to,

	a.overdue_days as dpd_from,
	b.overdue_days as dpd_to,

	----флаг некорректных переходов
	case when b.dpd_bucket_num_360 - a.dpd_bucket_num_360 > 2 
		then 1
		when b.dpd_bucket_num_360 - a.dpd_bucket_num_360 = 2
		and b.overdue_days - a.overdue_days > 32
		then 1 
		else 0 end as flag_wrong_migration,

	----флаг закрытия
	case when isnull(b.mob_date, eomonth(a.mob_date,1)) >= a.end_date then 1
		 else 0
	end as flag_closed

	into #stg_matrix_detail

	from #stg_bal a
	left join #stg_bal b
	on a.external_id = b.external_id
	and a.mob = b.mob - 1
	left join #cred_reestr c
	on a.external_id = c.external_id

	where 1=1
	and a.mob_date <= eomonth(@rdt,-1) --'2020-07-31'
	and a.principal_rest > 0
	--and (
	--  (b.principal_rest > 0 and b.mob_date < c.end_date)
	-- or 
	--  (isnull(b.principal_rest,0) = 0 
	--  and isnull(b.overdue_days,0) = 0 
	--  and isnull(b.mob_date, eomonth(a.mob_date,1)) >= c.end_date)
	--  )
	--and b.principal_rest > 0
	--and a.generation >= '2018-01-01'


	drop index if exists idx1_stg_matrix_detail on #stg_matrix_detail;
	create clustered index idx1_stg_matrix_detail on #stg_matrix_detail (external_id, mob_date_to, generation, term, segment_rbp, flag_kk, mob_from, bucket_90_from, bucket_90_to);

	----------------------------------------------------

	--проверяем переходы на корректность (например, из 0 может перейти в 0 или в 1-30) и учет КК


	--обновление по закрытым договорам
	update #stg_matrix_detail
	set mob_date_to = EOMONTH(mob_date_from,1),
	mob_to = mob_from + 1,
	principal_rest_to = 0,
	bucket_360_to = '[10] Pay-off',
	bucket_90_to = '[06] Pay-off',
	bucket_num_360_to = 10,
	bucket_num_90_to = 6,
	dpd_to = 0,
	flag_wrong_migration = 0
	where flag_closed = 1;

	--для ПДП, ЧДП
	update #stg_matrix_detail
	set 
	bucket_360_to = '[10] Pay-off',
	bucket_90_to = '[06] Pay-off',
	bucket_num_360_to = 10,
	bucket_num_90_to = 6,
	dpd_to = 0,
	flag_wrong_migration = 0
	where principal_rest_to = 0 and flag_closed <> 1
	;



	--очищаем некорректные переходы v2 
	--сохраняем в отдельную таблицу 
	drop table if exists #wrong_migrations1;
	select * 
	into #wrong_migrations1
	from #stg_matrix_detail a
	where exists (select 1 from #stg_matrix_detail b
					where a.external_id = b.external_id
					and b.flag_wrong_migration = 1
					)
	;	




	with a as (
	select * from #stg_matrix_detail
	)
	update a
	set a.flag_kk = 'WRONG MIGR'
	where exists (select 1 
	from #stg_matrix_detail b
	where a.external_id = b.external_id
	and b.flag_wrong_migration = 1
	)
	and a.flag_kk <> 'KK' and a.flag_kk not like 'CESS%' and a.flag_kk <> 'BANKRUPT'
	;



	with a as (
	select * from #cred_reestr
	)
	update a
	set a.flag_kk = 'WRONG MIGR'
	where exists (select 1 
	from #stg_matrix_detail b
	where a.external_id = b.external_id
	and b.flag_wrong_migration = 1
	)
	and a.flag_kk <> 'KK' and a.flag_kk not like 'CESS%' and a.flag_kk <> 'BANKRUPT'
	;



	--Исправление: ОД будущий > ОД Текущий
	update #stg_matrix_detail 
	set principal_rest_to = principal_rest
	where principal_rest_to > principal_rest
	;


	--Удаляем кривые/недозревшие переходы
	--сохраняем в отдельную таблицу 
	drop table if exists #wrong_migrations2;
	select * 
	into #wrong_migrations2
	from #stg_matrix_detail a
	where a.mob_date_to is null
	;


	delete from #stg_matrix_detail 
	where mob_date_to is null;


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#stg_matrix_detail';


	--drop table #bus_stg_bal;
	drop table #cred_end_date;
	drop table #stg_bal;



	/************************************************************************************************/
	/************************************************************************************************/
	/************************************************************************************************/



	--------------------------------------------------------------------------------------------------------
	-- PART 2 - расчет агрегатов
	--------------------------------------------------------------------------------------------------------




	--Агрегат
	drop table if exists #stg1_agg;
	select 
	a.generation, a.term, a.segment_rbp, a.flag_kk,
	a.mob_date_from, a.mob_date_to, a.mob_from, a.mob_to,
	--a.bucket_360_from, a.bucket_360_to, --a.bucket_num_360_from, a.bucket_num_360_to,
	a.bucket_90_from, a.bucket_90_to --, a.bucket_num_90_from, a.bucket_num_90_to

	, round(sum(a.principal_rest),2) as od_from
	, round(sum(a.principal_rest_to),2) as od_to
	, sum( case when a.principal_rest > 0 then 1 else 0 end) as cnt_from
	, sum( case when a.principal_rest_to > 0 then 1 else 0 end) as cnt_to

	into #stg1_agg
	from #stg_matrix_detail a
	group by a.generation, a.term, a.segment_rbp, a.flag_kk,
	a.mob_date_from, a.mob_date_to, a.mob_from, a.mob_to,
	--a.bucket_360_from, a.bucket_360_to, --a.bucket_num_360_from, a.bucket_num_360_to,
	a.bucket_90_from, a.bucket_90_to --, a.bucket_num_90_from, a.bucket_num_90_to
	;


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#stg1_agg';



	--Для учета гашений по графику в группе Pay-off
	drop table if exists #standart_payoff;
	select a.generation, a.term, a.segment_rbp, a.flag_kk,
	a.mob_date_from, a.mob_date_to, a.mob_from, a.mob_to,
	a.bucket_90_from,
	'[06] Pay-off' as bucket_90_to,
	round(sum(a.od_from - a.od_to),2) as od_from,
	0 as od_to,
	sum(a.cnt_from) as cnt_from,
	sum(a.cnt_to) as cnt_to

	into #standart_payoff
	from #stg1_agg a
	where a.bucket_90_to <> '[06] Pay-off'
	group by a.generation, a.term, a.segment_rbp, a.flag_kk,
	a.mob_date_from, a.mob_date_to, a.mob_from, a.mob_to,
	a.bucket_90_from
	having sum(a.od_from - a.od_to) <> 0
	;


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#standart_payoff';



	drop table if exists #stg2_agg;
	select a.generation, a.term, a.segment_rbp, a.flag_kk,
	a.mob_date_from, a.mob_date_to,
	a.mob_from, a.mob_to, a.bucket_90_from, a.bucket_90_to,
	a.od_from + isnull(b.od_from,0) as od_from,
	case when a.bucket_90_to = '[06] Pay-off' then a.od_from + isnull(b.od_from,0) else a.od_to end as od_to,
	sum(a.od_from) over (partition by a.generation, a.term, a.segment_rbp, a.flag_kk, a.mob_from, a.bucket_90_from) as total_od_from,
	isnull(a.cnt_from,0) + isnull(b.cnt_from,0) as cnt_from,
	isnull(a.cnt_to,0) + isnull(b.cnt_to,0) as cnt_to

	into #stg2_agg
	from #stg1_agg a
	left join #standart_payoff b
	on a.generation = b.generation
	and a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	and a.mob_from = b.mob_from
	and a.bucket_90_from = b.bucket_90_from
	and a.bucket_90_to = b.bucket_90_to
	;


	insert into #stg2_agg

	select a.generation, a.term, a.segment_rbp, a.flag_kk,
	a.mob_date_from, a.mob_date_to, a.mob_from, a.mob_to,
	a.bucket_90_from, a.bucket_90_to, 
	a.od_from, a.od_from as od_to,
	cc.total_od_from,
	isnull(a.cnt_from,0) as cnt_from,
	isnull(a.cnt_to,0) as cnt_to

	from #standart_payoff a
	left join (
		select c.generation, c.term, c.segment_rbp, c.flag_kk, c.mob_from, c.bucket_90_from, sum(c.od_from) as total_od_from
		from #stg1_agg c
		group by c.generation, c.term, c.segment_rbp, c.flag_kk, c.mob_from, c.bucket_90_from
	) cc
	on a.generation = cc.generation
	and a.term = cc.term
	and a.segment_rbp = cc.segment_rbp
	and a.flag_kk = cc.flag_kk
	and a.mob_from = cc.mob_from
	and a.bucket_90_from = cc.bucket_90_from
	where not exists (select 1 from #stg1_agg b
					where a.generation = b.generation
					and a.term = b.term
					and a.segment_rbp = b.segment_rbp
					and a.flag_kk = b.flag_kk
					and a.mob_from = b.mob_from
					and a.bucket_90_from = b.bucket_90_from
					and a.bucket_90_to = b.bucket_90_to
					);


	drop index if exists idx_stg2_agg on #stg2_agg;
	create clustered index idx_stg2_agg on #stg2_agg (generation, term, segment_rbp, flag_kk, mob_from, bucket_90_from, bucket_90_to);


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#stg2_agg';



	drop table if exists #base_for_stg3_agg;

	
	;with base as (
		select distinct a.generation, a.term, a.segment_rbp, a.flag_kk from #cred_reestr a
	), dt as (
		select cast('2016-03-31' as date) as mob_date
		union all
		select eomonth(mob_date,1) as mob_date
		from dt
		where mob_date < EOMONTH(@rdt, -1) --cast('2021-03-31' as date)
	), buck as (
	select d.dpd_bucket_90 from #det_bucket_90 d
	union all
	select '[06] Pay-off' as dpd_bucket_90
	--union all
	--select '[07] Freeze' as dpd_bucket_90
	)
	select
	a.generation, a.term, a.segment_rbp, a.flag_kk, 
	dt.mob_date as mob_date_from, 
	EOMONTH(dt.mob_date,1) as mob_date_to,
	DATEDIFF(MM,a.generation,dt.mob_date) as mob_from,
	DATEDIFF(MM,a.generation,dt.mob_date) + 1 as mob_to,
	b1.dpd_bucket_90 as bucket_90_from,
	b2.dpd_bucket_90 as bucket_90_to

	into #base_for_stg3_agg
	from base a
	left join dt 
	on a.generation <= dt.mob_date
	left join buck b1
	on 1=1
	left join buck b2
	on 1=1
	where 1=1
	and not (a.flag_kk <> 'KK' and b1.dpd_bucket_90 = '[07] Freeze')
	and not (a.flag_kk <> 'KK' and b2.dpd_bucket_90 = '[07] Freeze')
	;

	




	exec dbo.prc$set_debug_info @src = @srcname, @info = '#base_for_stg3_agg';



	
	drop table if exists #for_cnt;
	select a.generation, a.term, a.segment_rbp, a.flag_kk, a.mob_to, a.bucket_90_from, count(*) as cnt_from
	into #for_cnt
	from #stg_matrix_detail a
	group by a.generation, a.term, a.segment_rbp, a.flag_kk, a.mob_to, a.bucket_90_from





	--полная матрица групп и дат для корректного построени средних значений в Excel
	drop table if exists #stg3_agg;


	select b.generation, b.term, b.segment_rbp, b.flag_kk,
	b.mob_date_from, b.mob_date_to, b.mob_from, b.mob_to, b.bucket_90_from, b.bucket_90_to,
	isnull(s.od_from,0) as  od_from,
	isnull(s.od_to,  0) as od_to,
	coalesce(s.total_od_from, cc.total_od_from, 0) as total_od_from,
	--coalesce(s.cnt_from , 0) as cnt_from,
	coalesce(d.cnt_from , 0) as cnt_from,
	coalesce(s.cnt_to	, 0) as cnt_to

	into #stg3_agg
	from #base_for_stg3_agg b
	left join #stg2_agg s
	on b.generation = s.generation
	and b.term = s.term
	and b.segment_rbp = s.segment_rbp
	and b.flag_kk = s.flag_kk
	and b.mob_from = s.mob_from
	and b.bucket_90_from = s.bucket_90_from
	and b.bucket_90_to = s.bucket_90_to
	
	left join (
		select c.generation, c.term, c.segment_rbp, c.flag_kk, c.mob_from, c.bucket_90_from, sum(c.od_from) as total_od_from 
		from #stg1_agg c
		group by c.generation, c.term, c.segment_rbp, c.flag_kk, c.mob_from, c.bucket_90_from
	) cc
	on b.generation = cc.generation
	and b.term = cc.term
	and b.segment_rbp = cc.segment_rbp
	and b.flag_kk = cc.flag_kk
	and b.mob_from = cc.mob_from
	and b.bucket_90_from = cc.bucket_90_from
	
	left join #for_cnt d
	on b.generation = d.generation
	and b.term = d.term
	and b.segment_rbp = d.segment_rbp
	and b.flag_kk = d.flag_kk
	and b.mob_to = d.mob_to
	and b.bucket_90_from = d.bucket_90_from
	;





	drop table #base_for_stg3_agg;



	--удаляем лишние срезы
	drop table if exists #for_delete;
	select a.generation, a.term, a.segment_rbp, a.flag_kk
	into #for_delete
	from #stg3_agg a
	group by a.generation, a.term, a.segment_rbp, a.flag_kk
	having sum(a.od_from) = 0
	;


	with a as (select * from #stg3_agg)
	delete from a
	where exists (select 1 from #for_delete b
				where a.generation = b.generation
				and a.term = b.term
				and a.segment_rbp = b.segment_rbp
				and a.flag_kk = b.flag_kk
				);



	exec dbo.prc$set_debug_info @src = @srcname, @info = '#stg3_agg';




	--удаляем лишние временные таблицы
	drop table #stg1_agg;
	drop table #stg2_agg;
	drop table #for_delete;
	drop table #standart_payoff;
	drop table #det_bucket_360;
	drop table #det_bucket_90;
	drop table #stg_bankrupt;
	drop table #stg1_zamorozka;
	drop table #wrong_migrations1;
	drop table #wrong_migrations2;



--------------------------------------------------------------------------------------------------------
-- PART 5 - МОНИТОРИНГ МАТРИЦ (ФАКТ-ПРОГНОЗ)
--------------------------------------------------------------------------------------------------------



	begin tran;

	--Заливка в таблицу-источник для мониторинга матричных переходов 
	delete from risk.migr_matrix_monitoring where kind = 'FACT' and r_date = @rdt;

	set @vinfo = concat('deleted rows = ',@@ROWCOUNT)

	exec dbo.prc$set_debug_info @src = @srcname, @info = 'delete from risk.migr_matrix_monitoring';
	exec dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

	--ФАКТ

	with base1 as (
	----переходы с 1 месяца жизни
		select 
		a.term, a.segment_rbp, a.generation, a.flag_kk,
		a.mob_date_to as r_date,
		a.mob_to as MoB,
		a.bucket_90_from as bucket_from,
		a.bucket_90_to as bucket_to,
		a.od_to as od
		from #stg3_agg a
		where a.mob_date_to = @rdt
	), base2 as (
	----переходы в 0 месяце в текущие бакеты
		select 
		a.term, a.segment_rbp, a.generation, a.flag_kk,
		a.generation as r_date,
		0 as MoB,
		cast('[00] New_volume' as varchar(100)) as bucket_from,
		RiskDWH.dbo.get_bucket_90(b.dpd) as bucket_to,
		sum(b.total_od) as od
		from #cred_reestr a
		left join RiskDWH.risk.stg_fcst_umfo b
		on a.external_id = b.external_id
		and a.generation = b.r_date
		where a.generation = @rdt
		group by a.term, a.segment_rbp, a.generation, a.flag_kk,
		a.generation,
		RiskDWH.dbo.get_bucket_90(b.dpd)
	), base3 as (
	----переходы в 0 месяце в PayOff
		select 
		a.term, a.segment_rbp, a.generation, a.flag_kk,
		a.generation as r_date,
		0 as MoB,
		cast('[00] New_volume' as varchar(100)) as bucket_from,
		cast('[06] Pay-off' as varchar(100)) as bucket_to,
		sum(a.amount - b.total_od) as od
		from #cred_reestr a
		left join RiskDWH.risk.stg_fcst_umfo b
		on a.external_id = b.external_id
		and a.generation = b.r_date
		where a.generation = @rdt
		group by a.term, a.segment_rbp, a.generation, a.flag_kk,
		a.generation
	), U as (
		select * from base1
		union all
		select * from base2
		union all
		select * from base3
	)
	insert into risk.migr_matrix_monitoring

	select 
	0 as vers,
	@rdt as date_on,
	cast(getdate() as datetime) as dt_dml,
	cast('FACT' as varchar(100)) as kind,
	checksum(concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1, 
	a.term, a.segment_rbp, a.generation, a.flag_kk,
	a.r_date, a.MoB,
	a.bucket_from, a.bucket_to,
	isnull(a.od,0) as od
	from U as a
	;


	set @vinfo = concat('inserted rows = ', @@ROWCOUNT)


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'insert into risk.migr_matrix_monitoring';
	exec dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

	commit tran;


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';



end try

begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch
