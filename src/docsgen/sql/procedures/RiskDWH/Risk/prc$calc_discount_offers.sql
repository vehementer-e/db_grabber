/**************************************************************************
Процедура для расчета предложений по акции прощения для коллекшн

Зависимости:
требуется закрытый срез месяца, по резервам БУ в том числе


Revisions:
dt			user				version		description
07/10/24	datsyplakov			v1.0		Создание процедуры
16/05/24	aygolcyn			v1.1		Замена [c2-vsr-sql04].[UMFO].[dbo] ---> stg._1cUMFO 

*************************************************************************/

CREATE procedure [Risk].[prc$calc_discount_offers] @rdt date = null

as

begin try

	if @rdt is null begin set @rdt = dateadd(dd,-2,cast(getdate() as date)) end

	declare @umfodt date;
	set @umfodt = eomonth(@rdt,-1);
	declare @extid nvarchar(100) = null;
	declare @prov_korr float = 0.73;
	declare @src_name varchar(100) = 'CALC DISCOUNTS';
	declare @loginfo varchar(1000) = concat('START repdate = ', format(@rdt,'dd.MM.yyyy'),
											', umfo_date = ', format(@umfodt, 'dd.MM.yyyy')
										  );

	exec dbo.prc$set_debug_info @src = @src_name, @info = @loginfo;


	exec dbo.prc$set_debug_info @src = @src_name, @info = '#court_decisions';


	--решения суда
	drop table if exists #court_decisions;
	with base as (
	select Deal.number as external_id,
		cast(jc.JudgmentDate as date) as JudgmentDate,
		cast(isnull(jc.PrincipalDebtOnJudgment,0) as float) as PrincipalDebtOnJudgment,
		cast(isnull(jc.PercentageOnJudgment,   0) as float) as PercentageOnJudgment,
		cast(isnull(jc.PenaltiesOnJudgment,	   0) as float) as PenaltiesOnJudgment,
		ROW_NUMBER() over (partition by deal.number order by jc.id desc) as rown
	  from
		  Stg._Collection.Deals AS Deal 	  
		  INNER JOIN Stg._Collection.JudicialProceeding AS jp 
		  ON Deal.Id = jp.DealId 
		  INNER JOIN Stg._Collection.JudicialClaims AS jc	
		  ON jp.Id = jc.JudicialProceedingId
		  where jc.PenaltiesOnJudgment is not null	 
		  and jc.JudgmentDate is not null
	)
	select bs.external_id,
	bs.JudgmentDate,
	bs.PrincipalDebtOnJudgment,
	bs.PercentageOnJudgment,
	bs.PenaltiesOnJudgment
	into #court_decisions
	from base bs
	where rown = 1
	 ;




	--Обрабатываем дубли из УМФО
	exec dbo.prc$set_debug_info @src = @src_name, @info = 'UMFO Doubles';

	drop table if exists #checking_doubles;

	select hst.Number, 
	r.[СуммаОД] as due_od,
	r.[СуммаПроценты] as due_int,
	r.ДнейПросрочки as dpd,
	r.ЭффективнаяСтавкаПроцента as eps,
	r.КлючЗаписи as КлючЗаписи

	into #checking_doubles
	from stg._Collection.Deals_history hst
	inner join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный umfo
	on hst.number = umfo.НомерДоговора 
	inner join stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ r 
	on umfo.Ссылка = r.Займ
	--inner join [c2-vsr-sql04].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ] dr with (nolock)
	inner join stg._1cUMFO.[Документ_СЗД_ФормированиеРезервовБУ] dr with (nolock)
	on r.Ссылка = dr.Ссылка
	where 1=1
	and hst.r_date = @rdt
	and cast(dateadd(yy,-2000,dr.Дата) as date) = @umfodt
	and (hst.number = @extid or @extid is null)
	and substring(hst.number,1,1) <> '0'

	;

	drop table if exists #umfo_doubles;
	select b.Number, min(b.КлючЗаписи) as min_key
	into #umfo_doubles
	from #checking_doubles b
	where b.Number in (
		select a.Number
		from #checking_doubles a
		group by a.Number 
		having count(*)>1
	)
	group by b.Number
	;


	drop table #checking_doubles;


	exec dbo.prc$set_debug_info @src = @src_name, @info = '#cred_balance';


	drop table if exists #cred_balance;

	select 
	hst.r_date as rep_dt,
	cast(hst.number as nvarchar(100)) as external_id,
	cast(hst.[Sum] as float) as cred_amount,
	DATEFROMPARTS(2000+cast(substring(hst.number, 1,2) as int),
					   cast(substring(hst.number, 3,2) as int), 
					   cast(substring(hst.number, 5,2) as int)) as dt_open,

	cast(isnull(hst.debtsum, 	0) as float) as due_od,
	cast(isnull(hst.[percent],0) as float) as due_int,
	cast(isnull(hst.fine, 	0) as float) as due_fee,
	cast(isnull(hst.stateFee,	0) as float) as due_other,

	cast(isnull(hst.debtsum, 	0) as float) +
	cast(isnull(hst.[percent],0) as float) +
	cast(isnull(hst.fine, 	0) as float) +
	cast(isnull(hst.stateFee,	0) as float) as due_total,

	cast(isnull(hst.OverdueDays,0) as int) as dpd,

	cast(isnull(r.[СуммаОД],0)                as float)        as due_od_umfo,
	cast(isnull(r.[СуммаПроценты],0)          as float) +  (
		case when r.ДнейПросрочки > 365 then 0
		when dateadd(MM,isnull(hst.Term, t.term), DATEFROMPARTS(2000+ cast(substring(hst.number, 1,2) as int),
																	cast(substring(hst.number, 3,2) as int), 
																	cast(substring(hst.number, 5,2) as int)) ) <  @rdt then 0
		else
		cast( isnull(t.CurrRate,hst.InterestRate) / 100.0 as float) / 365.0 * datediff(dd,@umfodt,@rdt) * cast(isnull(r.[СуммаОД],0) as float)
		end
	) as due_int_umfo,

	cast(isnull(r.[СуммаОД],0)                as float)         +
	cast(isnull(r.[СуммаПроценты],0)          as float) +  (
		case when r.ДнейПросрочки > 365 then 0
		when dateadd(MM,isnull(hst.Term, t.term), DATEFROMPARTS(2000+ cast(substring(hst.number, 1,2) as int),
																	cast(substring(hst.number, 3,2) as int), 
																	cast(substring(hst.number, 5,2) as int)) ) <  @rdt then 0
		else
		cast( isnull(t.CurrRate,hst.InterestRate) / 100.0 as float) / 365.0 * datediff(dd,@umfodt,@rdt) * cast(isnull(r.[СуммаОД],0) as float)
		end
	)         as due_gross_umfo,
	/*r.ДнейПросрочки*/ cast(isnull(hst.OverdueDays,0) as int) as dpd_umfo,		  

	cast((case when r.суммаод > 0 then r.резервостатокодпо / r.суммаод when r.суммапроценты > 0 then r.резервостатокпроцентыпо / r.суммапроценты when r.суммапени > 0 then r.резервостатокпенипо / r.суммапени else 0 end 
		* @prov_korr 
		* iif(isnull(r.ДнейПросрочки,0) between 91 and 180,0.5,1.0) 
		- case 
			when isnull(r.ДнейПросрочки,0) between 181 and 360 then 0.1
			when isnull(r.ДнейПросрочки,0) > 360 then 0.05
		else 0.0 end)
	* r.суммаод as float) as prov_od,

	cast((case when r.суммаод > 0 then r.резервостатокодпо / r.суммаод when r.суммапроценты > 0 then r.резервостатокпроцентыпо / r.суммапроценты when r.суммапени > 0 then r.резервостатокпенипо / r.суммапени else 0 end 
		* @prov_korr 
		* iif(isnull(r.ДнейПросрочки,0) between 91 and 180,0.5,1.0) 
		- case 
			when isnull(r.ДнейПросрочки,0) between 181 and 360 then 0.1
			when isnull(r.ДнейПросрочки,0) > 360 then 0.05
		else 0.0 end)
	* r.суммапроценты as float) as prov_int,

	cast((case when r.суммаод > 0 then r.резервостатокодпо / r.суммаод when r.суммапроценты > 0 then r.резервостатокпроцентыпо / r.суммапроценты when r.суммапени > 0 then r.резервостатокпенипо / r.суммапени else 0 end 
		* @prov_korr 
		* iif(isnull(r.ДнейПросрочки,0) between 91 and 180,0.5,1.0) 
		- case 
			when isnull(r.ДнейПросрочки,0) between 181 and 360 then 0.1
			when isnull(r.ДнейПросрочки,0) > 360 then 0.05
		else 0.0 end)
	* r.суммапени as float) as prov_fee,

	cast((case when r.суммаод > 0 then r.резервостатокодпо / r.суммаод when r.суммапроценты > 0 then r.резервостатокпроцентыпо / r.суммапроценты when r.суммапени > 0 then r.резервостатокпенипо / r.суммапени else 0 end 
		* @prov_korr 
		* iif(isnull(r.ДнейПросрочки,0) between 91 and 180,0.5,1.0) 
		- case 
			when isnull(r.ДнейПросрочки,0) between 181 and 360 then 0.1
			when isnull(r.ДнейПросрочки,0) > 360 then 0.05
		else 0.0 end)
	* (r.суммаод + r.суммапроценты + r.суммапени) as float) as prov_gross,


	cast( isnull(t.CurrRate,hst.InterestRate) / 100.0 as float) as int_rate,
	cast(r.ЭффективнаяСтавкаПроцента/100.0 as float) as eps

	,case when r.ДнейПросрочки > 365 then 0
		when dateadd(MM,isnull(hst.Term, t.term), DATEFROMPARTS(2000+ cast(substring(hst.number, 1,2) as int),
																	cast(substring(hst.number, 3,2) as int), 
																	cast(substring(hst.number, 5,2) as int)) ) <  @rdt then 0
		else
		cast( isnull(t.CurrRate,hst.InterestRate) / 100.0 as float) / 365.0 * datediff(dd,@umfodt,@rdt) * cast(isnull(r.[СуммаОД],0) as float)
		end as int_umfo_bias,

	case when cast(isnull(r.[СуммаОД],0) as float) + cast(isnull(r.[СуммаПроценты],0) as float) > 0 then
			(cast(isnull(r.РезервОстатокОДПо,0) as float) + cast(isnull(r.РезервОстатокПроцентыПо,0) as float)) / 
			(cast(isnull(r.[СуммаОД],0) as float) + cast(isnull(r.[СуммаПроценты],0) as float))
		else 0 end as prov_rate_umfo,

	cdec.JudgmentDate,
	isnull(cdec.PrincipalDebtOnJudgment, 0) as PrincipalDebtOnJudgment,
	isnull(cdec.PercentageOnJudgment,	 0) as PercentageOnJudgment,
	isnull(cdec.PenaltiesOnJudgment,	 0) as PenaltiesOnJudgment,
	isnull(hst.Term, t.term) as term

	into #cred_balance
	from stg._Collection.Deals_history hst --Reports.dbo.dm_CMRStatBalance_2 cmr
	inner join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный umfo
	--inner join [prodsql01].[UMFO].[dbo].[Документ_АЭ_ЗаймПредоставленный] umfo
	--inner join [c2-vsr-sql04].[UMFO].[dbo].[Документ_АЭ_ЗаймПредоставленный] umfo
	on hst.number = umfo.НомерДоговора 
	inner join stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ r 
	--inner join [prodsql01].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ] r
	--inner join [c2-vsr-sql04].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ_РезервыБУ] r
	on umfo.Ссылка = r.Займ

	inner join stg._1cUMFO.Документ_СЗД_ФормированиеРезервовБУ dr
	----inner join [prodsql01].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ] dr
	--inner join [c2-vsr-sql04].[UMFO].[dbo].[Документ_СЗД_ФормированиеРезервовБУ] dr with (nolock)
	on r.Ссылка = dr.Ссылка

	left join dwh2.risk.credits t
	on hst.Number = t.external_id

	left join #court_decisions cdec
	on hst.number = cdec.external_id


	where 1=1
	--and cmr.d = @rdt
	and hst.r_date = @rdt
	and cast(dateadd(yy,-2000,dr.Дата) as date) = @umfodt
	and (hst.number = @extid or @extid is null)
	and substring(hst.number,1,1) <> '0'
	--and cmr.external_id = '18101890200002'
	and not exists (select 1 from #umfo_doubles dd
					where hst.Number = dd.Number
					and r.КлючЗаписи = dd.min_key)
	and not exists (select 1 from dwh2.risk.credits cr where hst.number = cr.external_id and cr.isinstallment = 1)
	and isnull(hst.ProductType,'nnn') not like '%ПРО100%'
	and isnull(hst.ProductType,'nnn') <> 'PDL'



	----20/01/21 - дубли в УМФО
	--and not (hst.number = '18041623320001' and r.КлючЗаписи = 0x0000075D)
	----12/03/21 - дубли в УМФО
	--and not (hst.Number = '18041623320001' and r.КлючЗаписи = 0x000006FD)

	;


	--Удаляем погашенные или аннулированные
	with src as (select * from #cred_balance)
	delete from src 
	where exists (
		select 1 from #cred_balance a
		inner join stg._collection.deals b
		on a.external_id = b.number
		inner join stg._collection.DealStatus c
		on b.idStatus = c.Id
		where src.external_id = a.external_id
		and c.[Name] = 'Погашен'
	)	
	;




	exec dbo.prc$set_debug_info @src = @src_name, @info = '#disconts_1';

	--Вариант дисконта 1
	drop table if exists #disconts_1;
	with base1 as (
	select a.rep_dt, a.external_id, 
	a.due_od + a.due_other + a.due_int_umfo + a.PenaltiesOnJudgment - a.prov_gross  as bal_before_pereobsl,
	a.due_od + a.due_int + a.due_fee + a.due_other as total_due_cmr
	from #cred_balance a
	)
	select b1.rep_dt, b1.external_id, 
	b1.bal_before_pereobsl,
	round(b1.bal_before_pereobsl + (b1.total_due_cmr - b1.bal_before_pereobsl) * 0.2 / 1.2 , 2) as pmts_for_bezubytochn,
	round((b1.bal_before_pereobsl + (b1.total_due_cmr - b1.bal_before_pereobsl) * 0.2 / 1.2) * 1.05 , 2) as discont_type1,
	case when b1.total_due_cmr - b1.bal_before_pereobsl < 0 then 'Вся задолженность < Баланс до переобсл'
	else '' end as flag_err_1
	into #disconts_1
	from base1 b1;

	/****************************************************************************************/
	----Вариант дисконта 4

	exec dbo.prc$set_debug_info @src = @src_name, @info = '#payments';


	--платежи
	drop table if exists #payments;
	--select a.external_id, a.dt_open, b.r_date, b.pay_total
	--into #payments
	--from #cred_balance a
	--inner join dbo.stg_coll_bal_mfo b
	--on a.external_id = b.external_id
	--where b.pay_total >= 0.01

	select a.external_id, a.dt_open, b.cdate as r_date, 
	cast(isnull(b.principal_cnl, 0) as float) +
	cast(isnull(b.percents_cnl,     0) as float) +
	cast(isnull(b.fines_cnl,        0) as float) +
	cast(isnull(b.otherpayments_cnl,0) as float) +
	cast(isnull(b.overpayments_cnl, 0) as float) - cast(isnull(b.overpayments_acc, 0) as float) as pay_total
	into #payments
	from #cred_balance a
	inner join dwh_new.dbo.stat_v_balance2 b
	on a.external_id = b.external_id
	where ( cast(isnull(b.principal_cnl, 0) as float) +
	cast(isnull(b.percents_cnl,     0) as float) +
	cast(isnull(b.fines_cnl,        0) as float) +
	cast(isnull(b.otherpayments_cnl,0) as float) +
	cast(isnull(b.overpayments_cnl, 0) as float) - cast(isnull(b.overpayments_acc, 0) as float) ) > 0
	;


	exec dbo.prc$set_debug_info @src = @src_name, @info = '#total_pmt';

	--суммы платежей 
	drop table if exists #total_pmt;
	select a.external_id, sum(a.pay_total) as pay_total
	into #total_pmt
	from #payments a
	group by a.external_id;


	exec dbo.prc$set_debug_info @src = @src_name, @info = '#pmt_schedule';

	--график платежей
	drop table if exists #pmt_schedule;
	select src.external_id, src.dt_open, src.r_date, src.pay_total, src.rown, cb.int_rate as issue_int_rate
	into #pmt_schedule
	from (
		select a.external_id, a.dt_open, a.dt_open as r_date, 
		cast(0 as float) as pay_total, cast(0 as int) as rown
		from #cred_balance a
		--where a.external_id = '20011410000069'
	union all
		select b.external_id, b.dt_open, b.r_date, 
		b.pay_total, ROW_NUMBER() over (partition by b.external_id order by b.r_date asc) as rown
		from #payments b
		--where b.external_id = '20011410000069'

	) src
	left join #cred_balance cb
	on src.external_id = cb.external_id
	--11 sec
	;

	exec dbo.prc$set_debug_info @src = @src_name, @info = 'insert into #pmt_schedule';

	--виртуальный срез на сегодня
	insert into #pmt_schedule
	select a.external_id, a.dt_open, cast(getdate() as date) as r_date, 
	cast(0 as float) as pay_total, b.rown as rown, a.int_rate as issue_int_rate
	from #cred_balance a
	left join (select a.external_id, max(a.rown) + 1 as rown 
		from #pmt_schedule a
		group by a.external_id) b
	on a.external_id = b.external_id;

	exec dbo.prc$set_debug_info @src = @src_name, @info = 'delete from#pmt_schedule';

	--оставляем НЕненулевую просрочку  
	with a as (select * from #pmt_schedule)
	delete from a
	where exists (select 1 from #cred_balance b
	where a.external_id = b.external_id
	and b.dpd_umfo = 0
	and b.dpd = 0
	);

	exec dbo.prc$set_debug_info @src = @src_name, @info = '#pmt_with_lag_schedule';

	drop table if exists #pmt_with_lag_schedule;

	select a.external_id, a.r_date, a.rown, b.r_date as lag_r_date,
	a.issue_int_rate, a.pay_total, cast(DATEDIFF(dd,b.r_date, a.r_date) as float) as date_difference
	into #pmt_with_lag_schedule
	from #pmt_schedule a
	inner join #pmt_schedule b
	on a.external_id = b.external_id
	and a.rown = b.rown + 1;

	exec dbo.prc$set_debug_info @src = @src_name, @info = 'Cycles';



	/************************************************************************************/
	--Цикл для перебора ставок от 6% до ставки выдачи.
	declare @vinfo nvarchar(1000);

	exec dbo.prc$set_debug_info @src = @src_name, @info = 'Cycle1 for Discounts START';

	drop table if exists #tmp_forgive_sum;
		create table #tmp_forgive_sum (
		external_id nvarchar(100),
		int_rate float,
		od_calc float,
		perc_calc_sum float,
		pereobsl_fee_other float,
		pereobsl_result float,
		pmts_for_bezubytochn float,
		forgive_sum float
		);

	declare @virt_int_rate float = 0.06; --0.890263848334921; --0.06;
	declare @step1 float = 0.025;

	while @virt_int_rate <=  (select max(int_rate) from #cred_balance)

	begin

		set @vinfo = 'Cycle1 for Discounts int_rate = ' + format(@virt_int_rate,'##0.0#%'); 
		exec dbo.prc$set_debug_info @src = @src_name, @info = @vinfo;


		--Цикл для расчета ОД, Начислений и Баланса начисленных - Шаг 0
		drop table if exists #tmp_calc_int_rate;
		select 
		a.external_id, @virt_int_rate as int_rate, a.r_date, a.rown, 
		a.date_difference / 365.0 * @virt_int_rate * c.cred_amount as perc_calc,
		iif(
		(a.date_difference / 365.0 * @virt_int_rate + 1) * c.cred_amount - a.pay_total < c.cred_amount,
		(a.date_difference / 365.0 * @virt_int_rate + 1) * c.cred_amount - a.pay_total,
		c.cred_amount
		) as od_calc
		into #tmp_calc_int_rate
		from #pmt_with_lag_schedule a
		left join #cred_balance c
		on a.external_id = c.external_id
		where 1=1
		--and a.external_id = '19111610000119'
		and a.rown = 1
		and c.int_rate > @virt_int_rate
		--and b.external_id is null;
		;



		--Цикл со второго шага
		declare @i int = 2;

		while @i <= (select max(rown) from #pmt_schedule /*where external_id = '20011410000069'*/)
		begin

			insert into #tmp_calc_int_rate
			select 
			a.external_id, @virt_int_rate as int_rate, a.r_date, a.rown, 
			a.date_difference / 365.0 * @virt_int_rate * c.od_calc as perc_calc,
			iif(
			(a.date_difference / 365.0 * @virt_int_rate + 1) * c.od_calc - a.pay_total < c.od_calc,
			(a.date_difference / 365.0 * @virt_int_rate + 1) * c.od_calc - a.pay_total,
			c.od_calc
			) as od_calc
			from #pmt_with_lag_schedule a
			left join #tmp_calc_int_rate c
			on a.external_id = c.external_id
			and a.rown = c.rown + 1

			where 1=1
			--and a.external_id = '19111610000119'
			and a.rown = @i
			and a.issue_int_rate > @virt_int_rate
			--and b.external_id is null;
			;

			set @i = @i + 1;

		end;

	
		drop table if exists #total_prc_calc;
		select a.external_id, sum(a.perc_calc) as perc_calc_sum
		into #total_prc_calc
		from #tmp_calc_int_rate a
		group by a.external_id;
	
		
		insert into #tmp_forgive_sum

		select a.external_id, a.int_rate, a.od_calc, agg.perc_calc_sum, 
		-1 * (cb.due_other + cb.PenaltiesOnJudgment ) as pereobls_fee_other,

		-1 * (cb.due_other + cb.PenaltiesOnJudgment ) - ( isnull(t.pay_total,0) + cb.due_od - cb.cred_amount ) - cb.due_int_umfo + agg.perc_calc_sum as pereobsl_result,

		cb.due_total - cb.prov_gross - (cb.due_fee - cb.PenaltiesOnJudgment) - (cb.due_int - cb.due_int_umfo) +
		0.2 * ( cb.prov_gross + 
		 -1 * (cb.due_other + cb.PenaltiesOnJudgment ) - ( isnull(t.pay_total,0) + cb.due_od - cb.cred_amount ) - cb.due_int_umfo + agg.perc_calc_sum --pereobsl_result
		) / 1.2 as pmts_for_bezubytochn,

		-1 * ( cb.due_total - (cb.due_fee - cb.PenaltiesOnJudgment) - (cb.due_int - cb.due_int_umfo) - (
			cb.due_total - cb.prov_gross - (cb.due_fee - cb.PenaltiesOnJudgment) - (cb.due_int - cb.due_int_umfo) +
			0.2 * ( cb.prov_gross + 
			 -1 * (cb.due_other + cb.PenaltiesOnJudgment ) - ( isnull(t.pay_total,0) + cb.due_od - cb.cred_amount ) - cb.due_int_umfo + agg.perc_calc_sum --pereobsl_result
			) / 1.2 --pmts_for_bezubytochn
		) + (
			-1 * (cb.due_other + cb.PenaltiesOnJudgment ) - ( isnull(t.pay_total,0) + cb.due_od - cb.cred_amount ) - cb.due_int_umfo + agg.perc_calc_sum --pereobsl_result
		)) as forgive_sum

		from #tmp_calc_int_rate a
		left join #total_prc_calc agg
		on a.external_id = agg.external_id
		left join #total_pmt t
		on a.external_id = t.external_id
		left join #cred_balance cb
		on a.external_id = cb.external_id
		where a.r_date = cast(getdate() as date);


		set @virt_int_rate = @virt_int_rate + @step1;

	end;


	exec dbo.prc$set_debug_info @src = @src_name, @info = 'Cycle1 for Discounts FINISH';


	--выборка наиболее близких к нулю функции
	drop table if exists #stg_forgive_sum;

	with base as (
	select a.external_id, a.int_rate, a.od_calc, a.perc_calc_sum, a.pereobsl_fee_other, a.pereobsl_result, a.pmts_for_bezubytochn, 
	a.forgive_sum, 
	ROW_NUMBER() over (partition by a.external_id order by abs(a.forgive_sum)) as rown
	from #tmp_forgive_sum a
	where 1=1
	and a.forgive_sum is not null
	--and a.external_id = '20011410000069'
	)
	select bs.external_id, bs.int_rate, 
	bs.od_calc, bs.perc_calc_sum, bs.pereobsl_fee_other, bs.pereobsl_result,
	bs.pmts_for_bezubytochn, bs.forgive_sum, bs.rown
	into #stg_forgive_sum
	from base bs
	where bs.rown = 1
	--and bs.external_id = '18011020580003'
	--order by abs(bs.forgive_sum) asc
	;



	drop table #tmp_calc_int_rate;
	drop table #tmp_forgive_sum;

	/****************************************************************************************/

	--Цикл для уточнения ставок (первый этап)
	declare @vinfo2 nvarchar(1000);
	exec dbo.prc$set_debug_info @src = @src_name, @info = 'Cycle2 for Discounts START';

	drop table if exists #tmp2_forgive_sum;
		create table #tmp2_forgive_sum (
		external_id nvarchar(100),
		int_rate float,
		od_calc float,
		perc_calc_sum float,
		pereobsl_fee_other float,
		pereobsl_result float,
		pmts_for_bezubytochn float,
		forgive_sum float
		);

	declare @step2 float = -0.01;

	while @step2 <= 0.01

	begin

		set @vinfo2 = 'Cycle2 for Discounts step2 = ' + format(@step2,'##0.0#%'); 
		exec dbo.prc$set_debug_info @src = @src_name, @info = @vinfo2;

		--Цикл для расчета ОД, Начислений и Баланса начисленных - Шаг 0
		drop table if exists #tmp2_calc_int_rate;
		select 
		a.external_id, s.int_rate + @step2 as int_rate, a.r_date, a.rown, 
		a.date_difference / 365.0 * (s.int_rate + @step2) * c.cred_amount as perc_calc,
		iif(
		(a.date_difference / 365.0 * (s.int_rate + @step2) + 1) * c.cred_amount - a.pay_total < c.cred_amount,
		(a.date_difference / 365.0 * (s.int_rate + @step2) + 1) * c.cred_amount - a.pay_total,
		c.cred_amount
		) as od_calc
		into #tmp2_calc_int_rate
		from #pmt_with_lag_schedule a
		left join #cred_balance c
		on a.external_id = c.external_id
	
		inner join #stg_forgive_sum s
		on a.external_id = s.external_id	

		where 1=1
		--and a.external_id = '20011410000069'
		and a.rown = 1
		--and c.int_rate > @virt_int_rate
		and s.int_rate <> 0.06
		and (s.int_rate + @step2) < c.int_rate
		--and b.external_id is null;
		;


		--Цикл со второго шага
		declare @ii int = 2;

		while @ii <= (select max(rown) from #pmt_schedule /*where external_id = '20011410000069'*/)
		begin

			insert into #tmp2_calc_int_rate
			select 
			a.external_id, s.int_rate + @step2 as int_rate, a.r_date, a.rown, 
			a.date_difference / 365.0 * (s.int_rate + @step2) * c.od_calc as perc_calc,
			iif(
			(a.date_difference / 365.0 * (s.int_rate + @step2) + 1) * c.od_calc - a.pay_total < c.od_calc,
			(a.date_difference / 365.0 * (s.int_rate + @step2) + 1) * c.od_calc - a.pay_total,
			c.od_calc
			) as od_calc
			from #pmt_with_lag_schedule a
			left join #tmp2_calc_int_rate c
			on a.external_id = c.external_id
			and a.rown = c.rown + 1
		
			inner join #stg_forgive_sum s
			on a.external_id = s.external_id

			where 1=1
			--and a.external_id = '20011410000069'
			and a.rown = @ii
			and s.int_rate <> 0.06
			and (s.int_rate + @step2) < a.issue_int_rate
			--and b.external_id is null;
			;

			set @ii = @ii + 1;

		end;


		drop table if exists #total2_prc_calc;
		select a.external_id, sum(a.perc_calc) as perc_calc_sum
		into #total2_prc_calc
		from #tmp2_calc_int_rate a
		group by a.external_id;
	
		
		insert into #tmp2_forgive_sum

		select a.external_id, a.int_rate, a.od_calc, agg.perc_calc_sum, 
		-1 * (cb.due_other + cb.PenaltiesOnJudgment ) as pereobls_fee_other,

		-1 * (cb.due_other + cb.PenaltiesOnJudgment ) - ( isnull(t.pay_total,0) + cb.due_od - cb.cred_amount ) - cb.due_int_umfo + agg.perc_calc_sum as pereobsl_result,

		cb.due_total - cb.prov_gross - (cb.due_fee - cb.PenaltiesOnJudgment) - (cb.due_int - cb.due_int_umfo) +
		0.2 * ( cb.prov_gross + 
		 -1 * (cb.due_other + cb.PenaltiesOnJudgment ) - ( isnull(t.pay_total,0) + cb.due_od - cb.cred_amount ) - cb.due_int_umfo + agg.perc_calc_sum --pereobsl_result
		) / 1.2 as pmts_for_bezubytochn,

		-1 * ( cb.due_total - (cb.due_fee - cb.PenaltiesOnJudgment) - (cb.due_int - cb.due_int_umfo) - (
			cb.due_total - cb.prov_gross - (cb.due_fee - cb.PenaltiesOnJudgment) - (cb.due_int - cb.due_int_umfo) +
			0.2 * ( cb.prov_gross + 
			 -1 * (cb.due_other + cb.PenaltiesOnJudgment ) - ( isnull(t.pay_total,0) + cb.due_od - cb.cred_amount ) - cb.due_int_umfo + agg.perc_calc_sum --pereobsl_result
			) / 1.2 --pmts_for_bezubytochn
		) + (
			-1 * (cb.due_other + cb.PenaltiesOnJudgment ) - ( isnull(t.pay_total,0) + cb.due_od - cb.cred_amount ) - cb.due_int_umfo + agg.perc_calc_sum --pereobsl_result
		)) as forgive_sum

		from #tmp2_calc_int_rate a
		left join #total2_prc_calc agg
		on a.external_id = agg.external_id
		left join #total_pmt t
		on a.external_id = t.external_id
		left join #cred_balance cb
		on a.external_id = cb.external_id
		where a.r_date = cast(getdate() as date);

		set @step2 = @step2 + 0.001;

	end;

	exec dbo.prc$set_debug_info @src = @src_name, @info = 'Cycle2 for Discounts FINISH';






	--выборка наиболее близких к нулю функции
	drop table if exists #stg2_forgive_sum;

	with base as (
	select a.external_id, a.int_rate, a.od_calc, a.perc_calc_sum, a.pereobsl_fee_other, a.pereobsl_result, a.pmts_for_bezubytochn, 
	a.forgive_sum, 
	ROW_NUMBER() over (partition by a.external_id order by abs(a.forgive_sum)) as rown
	from #tmp2_forgive_sum a
	where 1=1
	and a.forgive_sum is not null
	--and a.external_id = '20011410000069'
	)
	select bs.external_id, bs.int_rate, 
	bs.od_calc, bs.perc_calc_sum, bs.pereobsl_fee_other, bs.pereobsl_result,
	bs.pmts_for_bezubytochn, bs.forgive_sum, bs.rown
	into #stg2_forgive_sum
	from base bs
	where bs.rown = 1
	--and bs.external_id = '18011020580003'
	--order by abs(bs.forgive_sum) asc
	;



	drop table #tmp2_calc_int_rate;
	drop table #tmp2_forgive_sum;

	/****************************************************************************************/

	--Цикл для уточнения ставок (третий этап)
	declare @vinfo3 nvarchar(1000);
	exec dbo.prc$set_debug_info @src = @src_name, @info = 'Cycle3 for Discounts START';

	drop table if exists #tmp3_forgive_sum;
		create table #tmp3_forgive_sum (
		external_id nvarchar(100),
		int_rate float,
		od_calc float,
		perc_calc_sum float,
		pereobsl_fee_other float,
		pereobsl_result float,
		pmts_for_bezubytochn float,
		forgive_sum float
		);

	declare @step3 float = -0.001;

	while @step3 <= 0.001

	begin

		set @vinfo3 = 'Cycle3 for Discounts step3 = ' + format(@step3,'##0.0#%'); 
		exec dbo.prc$set_debug_info @src = @src_name, @info = @vinfo3;

		--Цикл для расчета ОД, Начислений и Баланса начисленных - Шаг 0
		drop table if exists #tmp3_calc_int_rate;
		select 
		a.external_id, s.int_rate + @step3 as int_rate, a.r_date, a.rown, 
		a.date_difference / 365.0 * (s.int_rate + @step3) * c.cred_amount as perc_calc,
		iif(
		(a.date_difference / 365.0 * (s.int_rate + @step3) + 1) * c.cred_amount - a.pay_total < c.cred_amount,
		(a.date_difference / 365.0 * (s.int_rate + @step3) + 1) * c.cred_amount - a.pay_total,
		c.cred_amount
		) as od_calc
		into #tmp3_calc_int_rate
		from #pmt_with_lag_schedule a
		left join #cred_balance c
		on a.external_id = c.external_id
	
		inner join #stg2_forgive_sum s
		on a.external_id = s.external_id	

		where 1=1
		--and a.external_id = '20011410000069'
		and a.rown = 1
		and (s.int_rate + @step3) < c.int_rate
		--and c.int_rate > @virt_int_rate
		--and b.external_id is null;
		;


		--Цикл со второго шага
		declare @iii int = 2;

		while @iii <= (select max(rown) from #pmt_schedule /*where external_id = '20011410000069'*/)
		begin

			insert into #tmp3_calc_int_rate
			select 
			a.external_id, s.int_rate + @step3 as int_rate, a.r_date, a.rown, 
			a.date_difference / 365.0 * (s.int_rate + @step3) * c.od_calc as perc_calc,
			iif(
			(a.date_difference / 365.0 * (s.int_rate + @step3) + 1) * c.od_calc - a.pay_total < c.od_calc,
			(a.date_difference / 365.0 * (s.int_rate + @step3) + 1) * c.od_calc - a.pay_total,
			c.od_calc
			) as od_calc
			from #pmt_with_lag_schedule a
			left join #tmp3_calc_int_rate c
			on a.external_id = c.external_id
			and a.rown = c.rown + 1
		
			inner join #stg2_forgive_sum s
			on a.external_id = s.external_id

			where 1=1
			--and a.external_id = '20011410000069'
			and a.rown = @iii
			and (s.int_rate + @step3) < a.issue_int_rate
			--and b.external_id is null;
			;

			set @iii = @iii + 1;

		end;


		drop table if exists #total3_prc_calc;
		select a.external_id, sum(a.perc_calc) as perc_calc_sum
		into #total3_prc_calc
		from #tmp3_calc_int_rate a
		group by a.external_id;
	
		
		insert into #tmp3_forgive_sum

		select a.external_id, a.int_rate, a.od_calc, agg.perc_calc_sum, 
		-1 * (cb.due_other + cb.PenaltiesOnJudgment ) as pereobls_fee_other,

		-1 * (cb.due_other + cb.PenaltiesOnJudgment ) - ( isnull(t.pay_total,0) + cb.due_od - cb.cred_amount ) - cb.due_int_umfo + agg.perc_calc_sum as pereobsl_result,

		cb.due_total - cb.prov_gross - (cb.due_fee - cb.PenaltiesOnJudgment) - (cb.due_int - cb.due_int_umfo) +
		0.2 * ( cb.prov_gross + 
		 -1 * (cb.due_other + cb.PenaltiesOnJudgment ) - ( isnull(t.pay_total,0) + cb.due_od - cb.cred_amount ) - cb.due_int_umfo + agg.perc_calc_sum --pereobsl_result
		) / 1.2 as pmts_for_bezubytochn,

		-1 * ( cb.due_total - (cb.due_fee - cb.PenaltiesOnJudgment) - (cb.due_int - cb.due_int_umfo) - (
			cb.due_total - cb.prov_gross - (cb.due_fee - cb.PenaltiesOnJudgment) - (cb.due_int - cb.due_int_umfo) +
			0.2 * ( cb.prov_gross + 
			 -1 * (cb.due_other + cb.PenaltiesOnJudgment ) - ( isnull(t.pay_total,0) + cb.due_od - cb.cred_amount ) - cb.due_int_umfo + agg.perc_calc_sum --pereobsl_result
			) / 1.2 --pmts_for_bezubytochn
		) + (
			-1 * (cb.due_other + cb.PenaltiesOnJudgment ) - ( isnull(t.pay_total,0) + cb.due_od - cb.cred_amount ) - cb.due_int_umfo + agg.perc_calc_sum --pereobsl_result
		)) as forgive_sum

		from #tmp3_calc_int_rate a
		left join #total3_prc_calc agg
		on a.external_id = agg.external_id
		left join #total_pmt t
		on a.external_id = t.external_id
		left join #cred_balance cb
		on a.external_id = cb.external_id
		where a.r_date = cast(getdate() as date);

		set @step3 = @step3 + 0.0002;

	end;

	exec dbo.prc$set_debug_info @src = @src_name, @info = 'Cycle3 for Discounts FINISH';



	--выборка наиболее близких к нулю функции
	drop table if exists #stg3_forgive_sum;

	with base as (
	select a.external_id, a.int_rate, a.od_calc, a.perc_calc_sum, a.pereobsl_fee_other, a.pereobsl_result, a.pmts_for_bezubytochn, 
	a.forgive_sum, 
	ROW_NUMBER() over (partition by a.external_id order by abs(a.forgive_sum)) as rown
	from #tmp3_forgive_sum a
	where 1=1
	and a.forgive_sum is not null
	--and a.external_id = '20011410000069'
	)
	select bs.external_id, bs.int_rate, 
	bs.od_calc, bs.perc_calc_sum, bs.pereobsl_fee_other, bs.pereobsl_result,
	bs.pmts_for_bezubytochn, bs.forgive_sum, bs.rown
	into #stg3_forgive_sum
	from base bs
	where bs.rown = 1
	--and bs.external_id = '18011020580003'
	--order by abs(bs.forgive_sum) asc
	;




	exec dbo.prc$set_debug_info @src = @src_name, @info = '#final_discounts';



	/*ФИНАЛЬНАЯ ВЫБОРКА*/

	drop table if exists #final_discounts;

	select a.external_id, a.dt_open, a.cred_amount, 
	a.int_rate as issue_int_rate,
	a.dpd, a.due_od, a.due_int, a.due_fee, a.due_other, a.due_total,
	a.prov_gross, a.due_total - a.prov_gross as due_total_net,
	a.due_int_umfo,
	a.JudgmentDate,
	a.PrincipalDebtOnJudgment,
	a.PercentageOnJudgment,
	a.PenaltiesOnJudgment,
	--вариант1
	d1.bal_before_pereobsl as bal_before_pereobsl_1,
	d1.pmts_for_bezubytochn as pmts_for_bezubytochn_1,
	d1.discont_type1 as discont_type_1,
	--вариант4
	round(coalesce(s3.int_rate, s.int_rate),5) as int_rate_4,
	coalesce(s3.od_calc			   , s.od_calc				  ) as od_calc_4,
	coalesce(s3.perc_calc_sum 	   , s.perc_calc_sum 		  ) as perc_calc_sum_4,
	coalesce(s3.pereobsl_fee_other   , s.pereobsl_fee_other	  ) as pereobsl_fee_other_4,
	coalesce(s3.pereobsl_result	   , s.pereobsl_result		  ) as pereobsl_result_4,
	coalesce(s3.pmts_for_bezubytochn , s.pmts_for_bezubytochn ) as pmts_for_bezubytochn_4,
	coalesce(s3.pmts_for_bezubytochn , s.pmts_for_bezubytochn ) * 1.05 as discont_type_4

	into #final_discounts

	from #cred_balance a
	left join #disconts_1 d1
	on a.external_id = d1.external_id
	left join #stg_forgive_sum s
	on a.external_id = s.external_id
	left join #stg3_forgive_sum s3
	on a.external_id = s3.external_id;


	--drop table #payments;
	drop table #pmt_schedule;
	drop table #pmt_with_lag_schedule;
	drop table #tmp3_calc_int_rate;
	drop table #tmp3_forgive_sum;




	exec dbo.prc$set_debug_info @src = @src_name, @info = 'insert into vitr_forgive_discounts';


	begin tran


		insert into RiskDWH.dbo.vitr_forgive_discounts
		select 
		cast(sysdatetime() as datetime) as dt_dml,
		@rdt as rep_date, 
		a.*
		from #final_discounts a
		;


	commit tran;


	exec dbo.prc$set_debug_info @src = @src_name, @info = 'FINISH';

end try 



begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch
