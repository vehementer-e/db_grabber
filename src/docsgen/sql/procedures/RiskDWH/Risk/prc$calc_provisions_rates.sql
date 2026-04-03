



/**************************************************************************
Процедура для расчета ставок резервов по бакетам

Revisions:
dt			user				version		description
24/08/20	datsyplakov			v1.0		Создание процедуры
13/10/20	datsyplakov			v1.1		В качестве источника кред.каникул
											добавлена таблица reports.dbo.DWH_694_credit_vacation_cmr
15/01/21	datsyplakov			v1.2		Исправлен коэф залогового покрытия - 0,462
15/02/21	datsyplakov			v1.3		Добавлен расчет Коэффициена залогового покрытия 
											добавлен реестр каникул из Space (веб-форма для collection)
19/02/21	datsyplakov			v1.4		Расчет коэффициента залогового покрытия вынесен в отдельную процудуру
01/07/21	datsyplakov			v1.5		Вместо среднего из recoveryRate (AVG) расчитывается общий средний - SUM(pmt)/SUM(portf)
06/07/21	datsyplakov			v1.6		Добавлен параметр @window_months - размер окна в месяцах для среднего портфеля и платежей
											Добавлен параметр @avg_type - тип расчета Recovery:
												'OLD' - среднее по всем Recovery (усреднение)
												'NEW' - средневзвешенное (SUM(pmt)/SUM(portf))
07/02/23	datsyplakov			v1.7		Если @add_info like '%installment%' то залоговое покрытие = 0
											portf_cmr заменен на dwh2.dbo.dm_cmrstatbalance
											исключаем installment

*************************************************************************/

CREATE procedure [Risk].[prc$calc_provisions_rates]
--дата резервов
@repdate date,

--флаг для вида платежей:
----0: ОД + %% + пени + госпошлины - переплаты
----1: ОД - переплаты
@flagpmt smallint = null,

--флаг для среднего портфеля (91+)
----0: од (principal_rest)
----1: гросс (total_rest)
@flaggross smallint = null,

--реестр кредитных каникул
----0: НЕ исключаем кк
----1: исключаем по реестру от 14/07/2020 (dbo.det_cred_hol_140720_v3)
----2: исключаем по реестру от 19/08/2020 (dbo.det_cred_hol_190820)
----3: исключаем по реестру от 18/09/2020 (dbo.det_cred_holid_180920)
----4: исключаем по реестру reports.dbo.DWH_694_credit_vacation_cmr
----5: исключаем по реестру из Space + reports.dbo.DWH_694_credit_vacation_cmr
@flagkk smallint = null,

--размер окна для среднего портфеля и платежей (по умолчанию - 20)
@window_months int = null,

--тип расчета Recovery (по умолчанию - NEW):
----'OLD' - среднее по всем Recovery (усреднение)
----'NEW' - средневзвешенное (SUM(pmt)/SUM(portf))
@avg_type varchar(10) = null,

--дополнительая информация
@addinfo varchar(100) = null

as

begin try

	declare @srcname varchar(100) = 'Provision rates calculation';


	if @flagpmt is null set @flagpmt = 1;
	if @flaggross is null set @flaggross = 0;
	if @flagkk is null set @flagkk = 5;
	if @window_months is null set @window_months = 20;
	if @avg_type is null set @avg_type = 'NEW';


	/******************* ОПЦИИ *******************/

	--дата, с которой брать ЦМР
	declare @cmr_point date = cast('2020-02-01' as date);

	--коэффициент залогового покрытия
	declare @pledge_cover float;

	

	declare @v smallint;

	set @v = isnull((select max(vers) + 1 from risk.calc_versions --risk.prov_rep_rates 
					where rep_dt = @repdate
					and vers > 0
					and section = 'PROVISIONS'
					) , 1);


	--для логирования



	declare @vinfo varchar(500) = 'START REPDT = ' 
								  + convert(varchar(10),@repdate, 120) 
								  + ', VERS = ' + cast(@v as varchar(2))
								  + ', FLAGPMT = ' + cast(@flagpmt as varchar(1))
								  + ', FLAGGROSS(91+) = ' + cast(@flaggross as varchar(1))
								  + ', FLAGKK = ' + cast(@flagkk as varchar(1))
								  + ', WINDOW MONTHS = ' + cast(@window_months as varchar(2))
								  + ', AVG TYPE = ' + @avg_type
								  + case when @addinfo is not null then ', ADDINFO = ' + @addinfo else '' end;

	exec dbo.prc$set_debug_info @src = @srcname, 
								@info = @vinfo;


	/*** PART 0 (credit holidays) ***/

	exec dbo.prc$set_debug_info @src = @srcname, 
								@info = 'PART 0 Credit Holidays';

	--кредитные каникулы

	drop table if exists #stg_kk;

	create table #stg_kk (external_id varchar(255));

	if @flagkk = 1 
	begin 
		insert into #stg_kk
		select a.external_id
		from dbo.det_cred_hol_140720_v3 a
	end

	if @flagkk = 2
	begin
		insert into #stg_kk
		select a.external_id
		from dbo.det_cred_hol_190820 a
	end

	if @flagkk = 3
	begin 
		insert into #stg_kk
		select a.Договор
		from dbo.det_cred_holid_180920 a
		where @repdate between a.Период and a.ДатаОкончания
	end 

	if @flagkk = 4
	begin
		insert into #stg_kk
		select a.Договор
		from reports.dbo.DWH_694_credit_vacation_cmr a
		where @repdate between a.Период and a.ДатаОкончания
	end

	if @flagkk = 5
	begin

	with kk_space as (
	select a.Number as external_id, 
	isnull(cast(a.CreditVacationDateBegin as date), cast(b.Период as date)) as dt_from, 
	cast(a.CreditVacationDateEnd	  as date) as dt_to
	from stg._Collection.Deals a
	left join Reports.dbo.DWH_694_credit_vacation_cmr b
	on a.Number = b.Договор
	where 1=1
	and a.CreditVacationDateEnd is not null
	), base as (
	select k.external_id, k.dt_from, k.dt_to
	from kk_space k
		union all
	select c.Договор as external_id, c.Период as dt_from, c.ДатаОкончания as dt_to
	from Reports.dbo.DWH_694_credit_vacation_cmr c
	where not exists (select 1 from kk_space kk
					where c.Договор = kk.external_id)
	) 
	insert into #stg_kk 
	select b.external_id
	from base b
	where @repdate between b.dt_from and b.dt_to

	end





	/*** PART 0 коэффициент залогового покрытия ***/
	exec dbo.prc$set_debug_info @src = @srcname, 
								@info = 'PART 0 PLEDGE COVER COEFF';


	--exec RiskDWH.Risk.prc$calc_pledge_cover @repdate;


	select @pledge_cover = ceiling(sum(a.cf_est_price) / sum(a.gross_due)*1000)/1000
	from RiskDWH.risk.prov_stg_pledge_cover a
	where a.rep_dt = @repdate
	;


	--Для Installment залоговое покрытие = 0
	if @addinfo like '%installment%'
	begin
	set @pledge_cover = 0.0;
	end


	set @vinfo = concat('PLEDGE_COVER = ', cast(@pledge_cover as varchar(5)) );

	exec dbo.prc$set_debug_info @src = @srcname, 
								@info = @vinfo;

	/*** PART 1 (91+)***/

	exec dbo.prc$set_debug_info @src = @srcname, 
								@info = 'PART 1 (91+) RECOVERY RATES';


	/****************** подневной портфель, бакеты 720, последние 20 месяцев ******************/
	begin transaction;

	with base as (
		select a.r_date as date_on, a.dpd_bucket_720 as bucket, 
		sum(
		case when @flaggross = 1 then a.total_rest
		 when @flaggross = 0 then a.principal_rest end
		 ) as portf 
		from Risk.portf_mfo a 
		where a.r_date < @cmr_point	
		and a.r_date <= @repdate
		and a.dpd_bucket_720 not in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90')
		--удаляем кредитные каникулы
		and not exists (select 1 from #stg_kk kk where a.external_id = kk.external_id)
		--удаляем Installment
		and not exists (select 1 from dwh2.risk.credits cr where a.external_id = cr.external_id and cr.IsInstallment = 1)

		group by a.r_date, a.dpd_bucket_720
	union all
		select a.d as date_on, RiskDWH.dbo.get_bucket_720(a.dpd) as bucket, 
		sum(
		case when @flaggross = 1 then isnull(a.[остаток всего],0)
		 when @flaggross = 0 then isnull(a.[остаток од],0) end
		 ) as portf 
		from dwh2.dbo.dm_cmrstatbalance a
		where a.d >= @cmr_point	
		and a.d <= @repdate
		and RiskDWH.dbo.get_bucket_720(a.dpd) not in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90')
		--удаляем кредитные каникулы
		and not exists (select 1 from #stg_kk kk where a.external_id = kk.external_id)
		--удаляем Installment
		and not exists (select 1 from dwh2.risk.credits cr where a.external_id = cr.external_id and cr.IsInstallment = 1)

		group by a.d, RiskDWH.dbo.get_bucket_720(a.dpd)


	)
	insert into risk.prov_stg_portf_agg_720_daily 
	select @repdate as rep_dt, @v as vers, cast(sysdatetime() as datetime) as dt_dml, 
	b.date_on, b.bucket, b.portf
	from base b
	where b.date_on >= dateadd(dd,1,eomonth(@repdate,/*-20*/ -1 * @window_months));

	commit transaction;

	/****************** средний портфель за месяц ******************/
	begin transaction

	insert into risk.prov_stg_portf_avg_720

	select a.rep_dt, a.vers, cast(sysdatetime() as datetime) as dt_dml,
	EOMONTH(a.date_on) as date_on, a.bucket, avg(a.portf) as portf
	from risk.prov_stg_portf_agg_720_daily a
	where a.rep_dt = @repdate
	and a.vers = @v
	group by a.rep_dt, a.vers, EOMONTH(a.date_on), a.bucket;

	commit transaction;

	/****************** сумма платежей за месяц ******************/
	begin transaction;

	with base as (
		select EOMONTH(a.r_date) as date_on, a.dpd_bucket_720_p as bucket, 
		sum(
		case when @flagpmt = 0 then a.pay_total
		 when @flagpmt = 1 then a.pay_total_alt end
		) as pmt
	
		from Risk.portf_mfo a
		where a.r_date <= @repdate
		and a.dpd_bucket_720_p not in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90')
		--удаляем кредитные каникулы
		and not exists (select 1 from #stg_kk kk where a.external_id = kk.external_id)
		--удаляем Installment
		and not exists (select 1 from dwh2.risk.credits cr where a.external_id = cr.external_id and cr.IsInstallment = 1)

		group by EOMONTH(a.r_date), a.dpd_bucket_720_p
	)
	insert into risk.prov_stg_payments_agg_720

	select 
	@repdate as rep_dt, @v as vers, cast(sysdatetime() as datetime) as dt_dml,
	b.date_on, b.bucket, b.pmt
	from base b
	where b.date_on >= eomonth(@repdate,/*-19*/ -1 * (@window_months - 1) );

	commit transaction;

	/****************** Recovery rate (средние за последние 20 месяцев) ******************/

	begin transaction

	insert into risk.prov_stg_recovery_rates

	select @repdate as rep_dt, @v as vers, cast(SYSDATETIME() as datetime) as dt_dml,
	a.bucket,
	
	case @avg_type 
	when 'OLD' 
	then 
		avg(
		case when a.portf = 0 or b.pmt is null then 0
		else 
		cast(b.pmt / a.portf as float)
		end
		) 

	when 'NEW'
	then sum(cast(b.pmt as float)) / sum(cast(a.portf as float))
	
	end as recovery_rate

	--sum(cast(b.pmt as float)) / sum(cast(a.portf as float)) as recovery_rate

	from risk.prov_stg_portf_avg_720 a
	left join risk.prov_stg_payments_agg_720 b
	on a.date_on = b.date_on
	and a.bucket = b.bucket
	and b.rep_dt = @repdate
	and b.vers = @v

	where a.rep_dt = @repdate
	and a.vers = @v
	group by a.bucket;

	commit transaction;


	/****************** МНК для расчета модельных recovery rate (логарифмический тренд) ******************/
	begin transaction;
	
	with base as (
		select a.bucket, a.recovery_rate, a.recovery_rate as y,
		ROW_NUMBER() over (order by bucket) as x
		from risk.prov_stg_recovery_rates a
		where a.rep_dt = @repdate
		and a.vers = @v
	),
	stage1 as (
	select 
	cast(sum(log(b.x) * b.y) as float) as sum_xy, 
	cast(sum(log(b.x)) as float) as sum_x, 
	cast(sum(b.y) as float) as sum_y, 
	cast(sum(power(log(b.x),2)) as float) as sum_x_sq, 
	cast(power( sum(log(b.x)), 2) as float) as sq_sum_x,
	count(*) as n
	from base b
	),
	stage2 as (
	select (s.n * s.sum_xy - s.sum_x * s.sum_y) / (s.n * s.sum_x_sq - s.sq_sum_x) as koef_a
	from stage1 s
	),
	koefs as (
	select ss.koef_a, (s.sum_y - ss.koef_a * s.sum_x) / s.n as koef_b from stage1 s
	left join stage2 ss
	on 1=1),
	model_values as (
	select bs.bucket, bs.recovery_rate, bs.y, bs.x, k.koef_a, k.koef_b, k.koef_a * log(bs.x) + k.koef_b as y_model
	from base bs
	left join koefs k
	on 1=1
	)
	insert into risk.prov_stg_model_recovery_rates

	select 
	@repdate as rep_dt, @v as vers, cast(sysdatetime() as datetime) as dt_dml,
	mv.bucket, mv.recovery_rate, mv.x, mv.koef_a, mv.koef_b, mv.y_model,
	sum(mv.y_model) over (order by x rows between current row and unbounded following) as y_model_acc

	from model_values mv
	order by mv.x;

	commit transaction;


	/*** PART 2 (0-90)***/

	exec dbo.prc$set_debug_info @src = @srcname, 
								@info = 'PART 2 (0-90) ROLL RATES';

	/****************** портфели на конец месяца ******************/
	begin transaction;

	with base as (
		select a.r_date as date_on, a.dpd_bucket_360 as bucket, sum(a.principal_rest) as portf 
		from Risk.portf_mfo a
		where a.r_date < @cmr_point
		and a.r_date = EOMONTH(a.r_date)
		and a.r_date <= @repdate
		and a.dpd_bucket_360 in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90','[05] 91-120')
		--удаляем кредитные каникулы
		and not exists (select 1 from #stg_kk kk where a.external_id = kk.external_id)
		--удаляем Installment
		and not exists (select 1 from dwh2.risk.credits cr where a.external_id = cr.external_id and cr.IsInstallment = 1)

		group by a.r_date, a.dpd_bucket_360
	union all	
		select a.d as date_on, RiskDWH.dbo.get_bucket_360(a.dpd) as bucket, sum(a.[остаток од]) as portf 
		from dwh2.dbo.dm_cmrstatbalance a
		where a.d >= @cmr_point
		and a.d = EOMONTH(a.d)
		and a.d <= @repdate
		and RiskDWH.dbo.get_bucket_360(a.dpd) in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90','[05] 91-120')
		--удаляем кредитные каникулы
		and not exists (select 1 from #stg_kk kk where a.external_id = kk.external_id)
		--удаляем Installment
		and not exists (select 1 from dwh2.risk.credits cr where a.external_id = cr.external_id and cr.IsInstallment = 1)

		group by a.d, RiskDWH.dbo.get_bucket_360(a.dpd)
	)
	insert into risk.prov_stg_portf_agg_360
	select @repdate as rep_dt, @v as vers, cast(sysdatetime() as datetime) as dt_dml, b.date_on, b.bucket, b.portf
	from base b
	where date_on >= EOMONTH(@repdate,-12);

	commit transaction;

	/****************** коэффициенты миграции ******************/

	begin transaction;

	with base as (
		select a.date_on, a.bucket, a.portf from risk.prov_stg_portf_agg_360 a
		where a.vers = @v
		and a.rep_dt = @repdate
	)
	insert into risk.prov_stg_roll_rates

	select 
	@repdate as rep_dt,
	@v as vers,
	cast(sysdatetime() as datetime) as dt_dml,
	c.date_on, 
	b.bucket as bucket_from,
	c.bucket as bucket_to,
	cast(case 
		when b.portf = 0 then 0
		when c.portf / b.portf > 1 then 1
		else c.portf / b.portf
	end as float) as roll_rate

	from base b
	inner join base c
	on b.date_on = EOMONTH(c.date_on,-1)
	and cast(substring(b.bucket,2,2) as int) = cast(substring(c.bucket,2,2) as int) - 1;

	commit transaction;

	/****************** Средневзвешенные коэф-ты миграции ******************/

	begin transaction

	insert into risk.prov_stg_roll_rates_weighted

	select 
	@repdate as rep_dt,
	@v as vers,
	cast(sysdatetime() as datetime) as dt_dml,

	a.bucket_from, a.bucket_to, 
	sum(a.roll_rate * b.portf) / sum(b.portf) as roll_rate_weighted

	from risk.prov_stg_roll_rates a

	left join risk.prov_stg_portf_agg_360 b
	on a.date_on = EOMONTH(b.date_on,1)
	and a.bucket_from = b.bucket
	and b.vers = @v
	and b.rep_dt = @repdate

	where a.vers = @v
	and a.rep_dt = @repdate
	and a.date_on between EOMONTH(@repdate,-11) and @repdate
	group by a.bucket_from, a.bucket_to;

	commit transaction;

	/*** PART 3 (final provisions rates) ***/

	exec dbo.prc$set_debug_info @src = @srcname, 
								@info = 'PART 3 LGD, PROV RATES';

	/****************** расчет LGD (старый алгоритм + поправка на коэффициент залогового покрытия) ******************/
	begin transaction;

	with base as (
	select a.rep_dt, a.vers,
	a.bucket_from,
	a.roll_rate_weighted,
	1 - round(b.y_model_acc,3) as lgd ,
	round(b.y_model_acc,3) as rr_90_plus,
	exp(sum(log(a.roll_rate_weighted)) over (order by a.bucket_from rows between current row and unbounded following))  
	as roll_rate_weighted_acc
	
	from risk.prov_stg_roll_rates_weighted a
	left join risk.prov_stg_model_recovery_rates b
		on b.bucket = '[05] 91-120'
		and a.rep_dt = b.rep_dt
		and a.vers = b.vers

	where a.rep_dt = @repdate
	and a.vers = @v
	),
	src as (
	select b.rep_dt, b.vers, b.bucket_from, b.roll_rate_weighted,  b.roll_rate_weighted_acc, b.rr_90_plus, b.lgd,
	b.rr_90_plus + (1 - b.rr_90_plus) * @pledge_cover as rr_90_plus_pldg,
	1 - ( b.rr_90_plus + (1 - b.rr_90_plus) * @pledge_cover ) as lgd_pldg
	from base b
	)
	insert into risk.prov_stg_prov_rates_0_90

	select s.rep_dt, s.vers, cast(SYSDATETIME() as datetime) as dt_dml,  s.bucket_from as bucket, 
	s.roll_rate_weighted, s.roll_rate_weighted_acc,
	s.rr_90_plus, s.lgd,
	s.rr_90_plus_pldg, s.lgd_pldg,

	round(s.roll_rate_weighted_acc * s.lgd, 5) as prov_rate,
	round(s.roll_rate_weighted_acc * s.lgd_pldg, 5) as prov_rate_pldg

	from src s; 

	commit transaction;

	/****************** Ставки резерва и recovery rate ******************/
	begin transaction;

	with base as (
	select a.rep_dt, a.vers, a.bucket, a.prov_rate_pldg as prov_rate, null as recovery_rate
	from risk.prov_stg_prov_rates_0_90 a
	where a.rep_dt = @repdate
	and a.vers = @v
	union all
	select a.rep_dt, a.vers, a.bucket, 
	--1 - iif(a.y_model_acc >= 0, a.y_model_acc, 0)  as prov_rate, 
	null as prov_rate,
	a.y_model_acc as recovery_rate 
	from risk.prov_stg_model_recovery_rates a
	where a.rep_dt = @repdate
	and a.vers = @v
	)
	insert into risk.prov_rep_rates
	select b.rep_dt, b.vers, cast(sysdatetime() as datetime) as dt_dml, b.bucket, b.prov_rate, b.recovery_rate
	from base b
	order by b.bucket;

	commit transaction;

	exec dbo.prc$set_debug_info @src = @srcname, 
								@info = 'FINISH';

end try

begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch
