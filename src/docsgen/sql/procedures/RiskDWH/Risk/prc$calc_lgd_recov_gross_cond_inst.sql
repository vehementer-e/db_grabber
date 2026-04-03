
/**************************************************************************
Расчет условных LGD и RecoveryRate - обычные и дисконтированные 
Условные - значит, что база - гросс-остаток - на конкретный месяц в дефолте

Revisions:
dt			user				version		description
09/06/23	datsyplakov			v1.0		Создание процедуры


*************************************************************************/


create procedure [Risk].[prc$calc_lgd_recov_gross_cond_inst]
--нижняя граница расчета
@dt_lower_bound date = null,
--верхняя граница расчета
@dt_upper_bound date,
--Продукт: PTS or INSTALLMENT
@product varchar(100) = 'INSTALLMENT',
--источник данных MFO или CMR или комбинация
@data_src varchar(10) = 'CMR+MFO'



as

--дата, с которой брать ЦМР
declare @cmr_point date = cast('2018-01-01' as date);

begin try

	if @dt_lower_bound is null set @dt_lower_bound = cast('2018-01-01' as date);

	declare @srcname varchar(100) = 'Calc LGD and RecoveryRates (COND GROSS)';

	declare @vinfo varchar(1000) = 'START dt_from = ' + convert(varchar(10),@dt_lower_bound,104) +
									' , dt_to = ' + convert(varchar(10),@dt_upper_bound,104) +
									' , src = ' + @data_src +
									' , product = ' + @product						
									;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#con_base';

	drop table if exists #con_base_mfo;
	with base as (
		select external_id, r_date, overdue_days from Risk.portf_mfo
	)
	select a.external_id, min(a.r_date) as npl_dt_from
	into #con_base_mfo
	from base a
	where a.overdue_days > 90
	and a.overdue_days <= 150
	and a.r_date = eomonth(a.r_date)
	and a.external_id not in ('18033014090002','18042819380005') --выбросы по процентам на 12 MOB
	group by a.external_id;

	drop table if exists #con_base_cmr;
	with base as (
		select a.external_id, a.d as r_date, a.dpd as overdue_days from dwh2.dbo.dm_cmrstatbalance a (nolock)
	)
	select a.external_id, min(a.r_date) as npl_dt_from
	into #con_base_cmr
	from base a
	where a.overdue_days > 90
	and a.overdue_days <= 150
	and a.r_date = eomonth(a.r_date)
	and a.external_id not in ('18033014090002','18042819380005') --выбросы по процентам на 12 MOB
	group by a.external_id;



	drop table if exists #con_base;
	create table #con_base (
	external_id nvarchar(100),
	npl_dt_from date
	);

	--база договоров с первым выходом в 90+
	if @data_src <> 'CMR+MFO'

	begin

		with base as (
			select external_id, r_date, overdue_days from Risk.portf_mfo
			where @data_src = 'MFO'
		union all
			select a.external_id, a.d as r_date, a.dpd as overdue_days from dwh2.dbo.dm_CMRStatBalance a (nolock)
			where @data_src = 'CMR'
		)
		insert into #con_base
		select a.external_id, min(a.r_date) as npl_dt_from		
		from base a
		where a.overdue_days > 90
		and a.overdue_days <= 150
		and a.r_date = eomonth(a.r_date)
		and a.external_id not in ('18033014090002','18042819380005') --выбросы по процентам на 12 MOB
		group by a.external_id;

	end

	ELSE

	begin
	
	--v 1.2
	insert into #con_base
	select d.external_id, d.npl_dt_from
	from (	
		select a.external_id, a.npl_dt_from
		from #con_base_cmr a
		where a.npl_dt_from >= @cmr_point
		union all
		select * from #con_base_mfo b
		where b.npl_dt_from < @cmr_point 
		and not exists (
			select 1 from #con_base_cmr c
			where c.npl_dt_from >= @cmr_point
			and b.external_id = c.external_id
		)
	) d
	;

	end;

	--удаляем или оставляем Installment
	if @product = 'PTS' 
	begin
		with a as (select * from #con_base) 
		delete from a where exists (select 1 from dwh2.risk.credits b where a.external_id = b.external_id and b.IsInstallment = 1)
	end 
	
	if @product = 'INSTALLMENT' 
	begin
		with a as (select * from #con_base) 
		delete from a where NOT exists (select 1 from dwh2.risk.credits b where a.external_id = b.external_id and b.IsInstallment = 1)
	end 


	--оставляем только тех, кто пробыл в дефолте хотя бы 1 месяц
	delete from #con_base where npl_dt_from >= @dt_upper_bound


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#stg_con_rate';

	-- эффективная ставка (для тех, по кому есть)
	drop table if exists #stg_con_rate;
	select distinct  c.external_id, 
						c.npl_dt_from as generation, 
						max(cast(r.эффективнаяставкапроцента as float)/100) as eff_rate 
	into #stg_con_rate
	from #con_base c
	inner join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный d --[prodsql01].[UMFO].[dbo].[Документ_АЭ_ЗаймПредоставленный]  d 
	on c.external_id = d.НомерДоговора
	inner join stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ r --[prodsql01].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ] r
	on r.Займ=d.ссылка
	where cast(r.эффективнаяставкапроцента as float) > 0
	group by c.external_id, 
				c.npl_dt_from
	;

	exec dbo.prc$set_debug_info @src = @srcname, @info = '#con_rate';


	--по тем, у кого нет ЭПС, средняя по поколению или средняя по всем
	drop table if exists #con_rate;

	with avg_generation as 
	(
		select a.generation, avg(a.eff_rate) as eff_rate
		from #stg_con_rate a
		group by a.generation
	),
	avg_total as (
		select avg(aa.eff_rate) as eff_rate
		from #stg_con_rate aa
	)
	select a.external_id, 
	coalesce( b.eff_rate, ag.eff_rate, t.eff_rate) as eff_rate

	into #con_rate

	from #con_base a
	left join #stg_con_rate b
	on a.external_id = b.external_id
	left join avg_generation ag
	on a.npl_dt_from = ag.generation
	left join avg_total t
	on 1=1;




	exec dbo.prc$set_debug_info @src = @srcname, @info = '#payments';




	drop table if exists #payments;
	select a.external_id, a.npl_dt_from,
	eomonth(b.cdate) as r_date, 
	datediff(MM,a.npl_dt_from,b.cdate) as months_in_default,
	sum(
		cast(isnull(b.principal_cnl,    0) as float) +
		cast(isnull(b.percents_cnl,     0) as float) +
		cast(isnull(b.fines_cnl,        0) as float) +
		cast(isnull(b.otherpayments_cnl,0) as float) +
		cast(isnull(b.overpayments_cnl, 0) as float) - cast(isnull(b.overpayments_acc, 0) as float) 
	)as pay_gross

	into #payments
	from #con_base a
	left join dwh_new.dbo.stat_v_balance2 b
	on a.external_id = b.external_id
	and b.cdate > a.npl_dt_from
	and b.cdate <= @dt_upper_bound

	group by a.external_id,a.npl_dt_from,
	eomonth(b.cdate),
	datediff(MM,a.npl_dt_from,b.cdate)
	;


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#default_balance';

	--declare @dt_upper_bound date = '2023-04-30';declare @cmr_point date = cast('2018-01-01' as date);


	drop table if exists #default_balance;
	with mods as (
		select 1 as months_in_default
		union all
		select months_in_default + 1
		from mods 
		where months_in_default < 48
	)
	select a.external_id, a.npl_dt_from, 
	EOMONTH(a.npl_dt_from,m.months_in_default) as r_date,
	m.months_in_default,
	coalesce(b.total_rest, c.[остаток всего], 0) as gross

	into #default_balance
	from #con_base a
	left join mods m
	on EOMONTH(a.npl_dt_from,m.months_in_default) <= @dt_upper_bound
	left join dwh_new.dbo.stat_v_balance2 b
	on a.external_id = b.external_id
	and b.cdate = EOMONTH(a.npl_dt_from,m.months_in_default)
	and b.cdate < @cmr_point 
	left join dwh2.dbo.dm_CMRStatBalance c (nolock)
	on a.external_id = c.external_id
	and c.d = EOMONTH(a.npl_dt_from,m.months_in_default)
	and c.d >= @cmr_point
	;



	exec dbo.prc$set_debug_info @src = @srcname, @info = 'LGD';

	


	begin transaction;

		delete from risk.lgd_gross_cond where r_date = @dt_upper_bound and product = @product;



		with base as (
			select 
			a.external_id,
			a.months_in_default, 
			a.gross,
			sum(isnull(
			case when b.months_in_default > 48 then 0 else b.pay_gross end 
			,0)) as pay_gross,
	
			sum(isnull(
			case when b.months_in_default > 48 then 0 else b.pay_gross end 
			,0) / power(1.0 + c.eff_rate, (b.months_in_default - a.months_in_default)/12.0 )) as pay_gross_disc	

			--a.pay_od / power( 1 + b.eff_rate , cast(a.mod_num as float) / 12.0) as pay_od_disc,
	

			from #default_balance a
			left join #payments b
			on a.external_id = b.external_id
			and a.months_in_default < b.months_in_default

			left join #con_rate c
			on a.external_id = c.external_id

			--where a.external_id = '19121700004282'
			group by a.external_id,
			a.months_in_default, 
			a.gross
		)
		insert into risk.lgd_gross_cond

		select 
		@dt_upper_bound as r_date,
		cast(getdate() as datetime) as dt_dml,
		@product as product,
	
		a.months_in_default, 
		sum(a.pay_gross) / sum(a.gross) as recovery_rate,
		1.0 - sum(a.pay_gross) / sum(a.gross) as LGD,

		sum(a.pay_gross_disc) / sum(a.gross) as recovery_rate_disc,
		1.0 - sum(a.pay_gross_disc) / sum(a.gross) as LGD_disc

		from base a
		group by a.months_in_default
	;


	commit transaction;


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'DROP TMP (#) TABLES';


	drop table #con_base;
	drop table #con_base_cmr;
	drop table #con_base_mfo;
	drop table #con_rate;
	drop table #default_balance;
	drop table #payments;
	drop table #stg_con_rate;


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';



end try

begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch