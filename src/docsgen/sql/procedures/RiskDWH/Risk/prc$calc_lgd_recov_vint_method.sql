
/**************************************************************************
Расчет LGD и RecoveryRate - обычные и дисконтированные 
+ сборка базы для слайда "среднемесячный Recovery" (Risk.rep_avg_recovery)

Revisions:
dt			user				version		description
24/08/20	datsyplakov			v1.0		Создание процедуры
10/09/20	datsyplakov			v1.1		Добавлен Recovery по %%
22/09/20	datsyplakov			v1.2		Добавлен источник "комбинация МФО и ЦМР"
08/06/21	datsyplakov			v1.3		Считаем LGD за последние 36 месяцев
22/11/21	datsyplakov			v1.4		Исключаем выручку от продажи (цессия)
19/05/21	datsyplakov			v1.5		Добавлены поля и соответствующие расчеты:
											recov_percents_disc - рекавери по процентам дисконтированные (для installment)
											recov_fines	- рекавери по пеням	
											recov_fines_disc - рекавери по пеням дисконтированные (для installment)
											recov_straf - рекавери штрафов и прочих
											recov_straf_disc - рекавери штрафов и прочих дисконтированные (для installment)
											writeoff_od - списания по ОД
											writeoff_percents - списания по процентам
16/06/22	datsyplakov			v1.6		Скорректированы списания в части УМФО
12/07/22	datsyplakov			v1.7		Добавлены списания ОД из ЦМР с момента начала действия дисконтного калькулятора
22/07/22	datsyplakov			v1.8		Исключены Installment из расчета 
09/09/22	datsyplakov			v1.9		risk.portf_cmr заменен на соответствующий объект в DWH2
											дата, с которой можно брать данные из ЦМР, равна началу 2018 года
13/02/22	datsyplakov			v2.0		Добавлены таблицы risk.lgd_payments_agg и risk.lgd_od_before_npl_agg для 
											хранения промежуточных данных, участвующих в расчете по новой методике БУ
17/08/23	datsyplakov			v2.1		Изменена логика @dt_lower_bound - ограничение на срезы (отчетные даты), 
											а не на поколения выхода в дефолт. Поколения всегда берем с 2018 года
											Ограничение на количество MoD-ов - параметр процедуры - @MODcnt
											Убран множитель 1.7 для списаний по процентам
08/12/23	datsplakov			v2.2		Добавлен дополнительный источник для списаний - вручную выгружается из отчета 1С
											"Отчеты - дополнительные отчеты - Формирование показателей"
16/04/2025	agolicyn			v3.0		Новый источник в сборке #payments - dwh2.dbo.dm_CMRStatBalance	
12/12/2025	agolicyn			v3.0		Новый источник цессий - RiskDWH.Risk.Cess_Reestr_UMFO

*************************************************************************/

CREATE procedure [Risk].[prc$calc_lgd_recov_vint_method]
--нижняя граница расчета
@dt_lower_bound date = null,
--верхняя граница расчета
@dt_upper_bound date,
--источник данных MFO или CMR или комбинация
@data_src varchar(10) = 'CMR+MFO',
--кол-во MoB-ов
@MODcnt int = 36

AS

--дата, с которой брать ЦМР
declare @cmr_point date = cast('2018-01-01' as date);

begin try

	--exec dbo.prc$set_debug_info @src = 'BU Rates', @info = 'Start begin try';
	if @dt_lower_bound is null set @dt_lower_bound = cast('2018-01-01' as date);
	
	exec dbo.prc$set_debug_info @src = 'BU Rates', @info = '@dt_lower_bound is set';
	declare @srcname varchar(100) = 'Calc LGD and RecoveryRates (VINTAGE METHOD)';

	declare @vinfo varchar(1000) = 'START dt_from = ' + convert(varchar(10),@dt_lower_bound,104) +
									' , dt_to = ' + convert(varchar(10),@dt_upper_bound,104) +
									' , src = ' + @data_src +
									' , MODcnt = ' + cast(@MODcnt as varchar(3))
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
		select a.external_id, a.d as r_date, a.dpd as overdue_days from dwh2.dbo.dm_cmrstatbalance a
	)
	select a.external_id, min(a.r_date) as npl_dt_from
	into #con_base_cmr
	from base a
	where a.overdue_days > 90
	and a.overdue_days <= 150
	and a.r_date = eomonth(a.r_date)
	and a.external_id not in ('18033014090002','18042819380005') --выбросы по процентам на 12 MOB
	group by a.external_id;

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
			select a.external_id, a.d as r_date, a.dpd as overdue_days from dwh2.dbo.dm_CMRStatBalance a
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

	--22.07.2022 исключаем Installment
	with a as (select * from #con_base) 
	delete from a where exists (select 1 from dwh2.risk.credits b where a.external_id = b.external_id and b.IsInstallment = 1)

	


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


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#od_before_npl';

	--ОД на (дату поколения - конец месяца выхода в 90+)
	drop table if exists #od_before_npl;

	with base as (
	select external_id, r_date, principal_rest, total_rest from Risk.portf_mfo
	where @data_src = 'MFO'
	union all
	select a.external_id, 
	a.d as r_date, 
	isnull(a.[остаток од],0) as principal_rest,
	isnull(a.[остаток всего],0) as total_rest
	from dwh2.dbo.dm_CMRStatBalance a
	where @data_src = 'CMR'
	union all

	select src.external_id, src.r_date, src.principal_rest, src.total_rest
	from (
		select a.external_id,
		a.d as r_date,
		isnull(a.[остаток од],0) as principal_rest,
		isnull(a.[остаток всего],0) as total_rest
		from dwh2.dbo.dm_CMRStatBalance a
		where a.d >= @cmr_point
		union all
		select external_id, r_date, principal_rest, total_rest from Risk.portf_mfo
		where r_date < @cmr_point 
		) src
	where @data_src = 'CMR+MFO'

	)
	select c.external_id, 
		   npl_dt_from as generation,
		   z.principal_rest, 
		   z.total_rest
	into #od_before_npl
	from #con_base c

	left join base z
	on c.external_id = z.external_id
	and c.npl_dt_from = z.r_date
	----поколения, начиная с @dt_lower_bound, заканчивая @dt_upper_bound - 1 месяц, чтобы был хотя бы один MOB
	--where npl_dt_from between @dt_lower_bound and eomonth(@dt_upper_bound,-1)
	where npl_dt_from between '2018-01-01' and eomonth(@dt_upper_bound,-1)
	;



	--Списания	
	--списания и прощения из УМФО

	exec dbo.prc$set_debug_info @src = @srcname, @info = '#write_off_umfo';

	
	--собираем все списания (прощения)
	drop table if exists #stg1_umfo_writeoff;
	select 
	a.НомерДоговора as external_id, 
	dateadd(yy,-2000, cast(a.ДатаОтчета as date)) as r_date,
	a.ПричинаЗакрытияНаименование as close_reason,
	СуммаСписанияПроцениты as int_wo,
	СуммаСписанияПени as fee_wo,
	СуммаПрощенияОсновнойДолг as od_forgive,
	СуммаПрощенияПроценты as int_forgive,
	СуммаПрощенияПени as fee_forgive

	into #stg1_umfo_writeoff
	from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a (nolock)
	inner join dwh_new.dbo.tmp_v_credits b
	on a.НомерДоговора = b.external_id
	where isnull(a.ПричинаЗакрытияНаименование,'') <> ''
	and a.ПричинаЗакрытияНаименование not in ('Закрытие долга залоговым имуществом','Признание задолженности безнадежной к взысканию','Служебная записка')
	and ( СуммаСписанияПроцениты > 0
	or СуммаСписанияПени > 0
	or СуммаПрощенияОсновнойДолг > 0
	or СуммаПрощенияПроценты > 0
	or СуммаПрощенияПени > 0
	)	
	--and a.ДатаОтчета <= '4023-10-31' --с ноября заливаем вручную из нового отчета
	;

	--вычисляем разность: текущая строка - предыдущая: так как сумма накапливается
	drop table if exists #stg2_umfo_writeoff;
	select a.external_id, a.r_date, a.close_reason,
	a.int_wo - lag(a.int_wo,1,0) over (partition by a.external_id order by a.r_date) as int_wo,
	a.fee_wo - lag(a.fee_wo,1,0) over (partition by a.external_id order by a.r_date) as fee_wo,
	a.od_forgive - lag(a.od_forgive,1,0) over (partition by a.external_id order by a.r_date) as od_forgive,
	a.int_forgive - lag(a.int_forgive,1,0) over (partition by a.external_id order by a.r_date) as int_forgive,
	a.fee_forgive - lag(a.fee_forgive,1,0) over (partition by a.external_id order by a.r_date) as fee_forgive
	into #stg2_umfo_writeoff
	from #stg1_umfo_writeoff a
	where 1=1
	--and a.external_id = '20080310000118'
	and a.r_date < cast(getdate() as date)
	;


	--причесываем: избавляемся от отрицательных и оставляем только значимые (> 0)
	drop table if exists #write_off_umfo;
	with base as (
		select a.external_id, a.r_date, a.close_reason,
		case when a.int_wo < 0 then 0 else a.int_wo end as int_wo,
		case when a.fee_wo < 0 then 0 else a.fee_wo end as fee_wo,
		case when a.od_forgive < 0 then 0 else a.od_forgive end as od_forgive,
		case when a.int_forgive < 0 then 0 else a.int_forgive end as int_forgive,
		case when a.fee_forgive < 0 then 0 else a.fee_forgive end as fee_forgive
		from #stg2_umfo_writeoff a
	)
	select * 
	into #write_off_umfo
	from base a
	where a.int_wo > 0 or a.fee_wo > 0 or a.od_forgive > 0 or a.int_forgive > 0 or a.fee_forgive > 0
	;

/*
	--08.12.2023 - новый источник - вручную из 1С
	;with base as (
		select 
		a.[Номер договора] as external_id, 
		a.Дата as r_date,
		a.[Причина закрытия наименование] as close_reason,
		[Сумма списания процениты] as int_wo,
		[Сумма списания пени] as fee_wo,
		[Сумма прощения основной долг] as od_forgive,
		[Сумма прощения проценты] as int_forgive,
		[Сумма прощения пени] as fee_forgive
		from risk.stg_raw_umfo_pmt_wo_91dpd a
		inner join dwh_new.dbo.tmp_v_credits b
		on a.[Номер договора] = b.external_id
		where isnull(a.[Причина закрытия наименование],'') <> ''
		and a.[Причина закрытия наименование] not in ('Закрытие долга залоговым имуществом','Признание задолженности безнадежной к взысканию','Служебная записка')
		and ( [Сумма списания процениты] > 0
			or [Сумма списания пени] > 0
			or [Сумма прощения основной долг] > 0
			or [Сумма прощения проценты] > 0
			or [Сумма прощения пени] > 0)
		and a.Дата >= '2023-11-01'
	)
	insert into	#write_off_umfo
	select a.external_id, a.r_date, a.close_reason,
	case when a.int_wo < 0 then 0 else a.int_wo end as int_wo,
	case when a.fee_wo < 0 then 0 else a.fee_wo end as fee_wo,
	case when a.od_forgive < 0 then 0 else a.od_forgive end as od_forgive,
	case when a.int_forgive < 0 then 0 else a.int_forgive end as int_forgive,
	case when a.fee_forgive < 0 then 0 else a.fee_forgive end as fee_forgive
	from base a
	;
*/



	
	exec dbo.prc$set_debug_info @src = @srcname, @info = '#write_off__mfo_with_offer';


	drop table if exists #write_off__mfo_with_offer;

	with base as (
	select distinct 
	cast(a.moment as date) as r_date, 
	a.external_id, 
	max(d.Наименование) over (partition by a.external_id, cast(a.moment as date)) as offer_name,
	cast(isnull(-1 * a.principal		, 0) as float) as od_writeoff,
	cast(isnull(-1 * a.percents			, 0) as float) as int_writeoff,
	cast(isnull(-1 * a.fines			, 0) as float) as fee_writeoff,
	cast(isnull(-1 * a.overpayment		, 0) as float) as over_writeoff,
	cast(isnull(-1 * a.other_payments	, 0) as float) as other_writeoff,

	cast(isnull(-1 * a.principal		, 0) as float) +
	cast(isnull(-1 * a.percents			, 0) as float) +
	cast(isnull(-1 * a.fines			, 0) as float) +
	cast(isnull(-1 * a.overpayment		, 0) as float) +
	cast(isnull(-1 * a.other_payments	, 0) as float) as total_writeoff

	from dwh_new.dbo.balance_wtiteoff a
	inner join stg._1cCMR.Справочник_Договоры b
	on a.external_id = b.Код
	inner join [Stg].[_1cCMR].[РегистрНакопления_АктивныеАкции] c
	on c.Договор = b.Ссылка
	and dateadd(year,-2000,cast(c.Период as date)) = cast(a.moment as date)
	inner join [Stg].[_1cCMR].[Справочник_Акции] d
	on c.Акция = d.Ссылка
	inner join dwh_new.dbo.tmp_v_credits t
	on a.external_id = t.external_id
	where not exists (select 1 from #write_off_umfo w
						where a.external_id = w.external_id)
	)
	select b.external_id, b.r_date, b.offer_name, 
	sum(b.od_writeoff		) as od_writeoff	, 
	sum(b.int_writeoff		) as int_writeoff	, 
	sum(b.fee_writeoff		) as fee_writeoff	, 
	sum(b.other_writeoff	) as other_writeoff, 
	sum(b.over_writeoff		) as over_writeoff	, 
	sum(b.total_writeoff	) as total_writeoff
	into #write_off__mfo_with_offer
	from base b
	group by b.external_id, b.r_date, b.offer_name
	having sum(b.od_writeoff) > 0  or sum(b.int_writeoff) > 0
	;




	exec dbo.prc$set_debug_info @src = @srcname, @info = '#pre_write_off';


	--итоговый список списаний
	drop table if exists #pre_write_off;
	with base as (
		select a.external_id , a.r_date, 
		isnull(a.od_forgive,0) as od_wo, 
		isnull(a.int_forgive,0) + isnull(a.int_wo,0) as int_wo
		from #write_off_umfo a
	union 
		select b.external_id, b.r_date, 
		b.od_writeoff as od_wo,
		b.int_writeoff as int_wo
		from #write_off__mfo_with_offer b
	)
	select a.external_id, 
	a.r_date, 
	sum(isnull(a.od_wo,0)) as od_wo,
	sum(isnull(a.int_wo,0)) as int_wo
	into #pre_write_off
	from base a
	group by a.external_id, a.r_date
	;


	--забираем списания ОД из ЦМР (сторно)
	drop table if exists #cmr_writeoff;
	with base as (
		select a.external_id, a.d, 
		a.[основной долг уплачено] - a.[ОД уплачено без Сторно по акции] as od_wo
		from dwh2.dbo.dm_CMRStatBalance a
	)
	select a.*
	into #cmr_writeoff
	from base a
	where a.od_wo > 0
	;


	--проверяем на дубли
	select @vinfo = concat('Doubles in CMR od writeoffs = ', count(*)) 
	from (
		select a.external_id
		from #cmr_writeoff a
		group by a.external_id
		having count(*)>1
	) a

	exec dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;

	


	--соединяем списания УМФО и ЦМР
	drop table if exists #stg_write_off;


	select 
	a.external_id, 
	a.r_date,
	
	case 
	when a.r_date < '2020-12-01' then a.od_wo --до диск калькулятора
	when a.od_wo = 0 then isnull(b.od_wo,0) --в умфо нет списания по ОД
	else a.od_wo end as od_wo,
	
	case 
	when a.r_date < '2020-12-01' then a.int_wo --до диск калькулятора
	when a.od_wo = 0 and a.int_wo - isnull(b.od_wo,0) < 0 then a.int_wo --в умфо нет списания по ОД и дельта %%-ОД < 0
	when a.od_wo = 0 then a.int_wo - isnull(b.od_wo,0) --в умфо нет списания по ОД
	else a.int_wo end as int_wo
	
	into #stg_write_off
	from #pre_write_off a
	left join #cmr_writeoff b
	on a.external_id = b.external_id
	--отличие дат не более 15 дней назад и 1 день вперед
	and b.d between dateadd(dd,-15,a.r_date) and dateadd(dd,1,a.r_date)
	;

	   	  
	exec dbo.prc$set_debug_info @src = @srcname, @info = '#payments';


	--платежи после выхода в npl, группировка по месяцам

	drop table if exists #payments;

	with cte as (
		select 0 as num
		union all
		select num + 1 
		from cte 
		where num < DATEDIFF(MM,@dt_lower_bound,@dt_upper_bound) 
	),
	repdates as (
		select eomonth(@dt_upper_bound,-num) as rdt from cte
	)
	select a.external_id, a.generation, r.rdt as mod_dt, 
	DATEDIFF(MM, a.generation, r.rdt) as mod_num,
	sum( iif( m.r_date >= dateadd(dd,-3,z.action_date), 0, m.pay_total_alt ) ) as pay_od,
	sum( iif( m.r_date >= dateadd(dd,-3,z.action_date), 0, m.pay_total ) ) as pay_total,
	sum( iif( m.r_date >= dateadd(dd,-3,z.action_date), 0, cast(isnull(b.percents_cnl, 0) as float)) ) as pay_percents,
	sum( iif( m.r_date >= dateadd(dd,-3,z.action_date), 0, cast(isnull(b.fines_cnl, 0) as float)) ) as pay_fines,
	sum( iif( m.r_date >= dateadd(dd,-3,z.action_date), 0, cast(isnull(b.otherpayments_cnl, 0) as float)) ) as pay_straf,
	sum( iif( m.r_date >= dateadd(dd,-3,z.action_date), 0, isnull(w_o.od_wo,0) ) ) as writeoff_od,
	sum( iif( m.r_date >= dateadd(dd,-3,z.action_date), 0, isnull(w_o.int_wo,0) ) ) as writeoff_int

	into #payments

	from #od_before_npl a
	left join repdates r
	--on a.mod_0 <= r.rdt
	on a.generation < r.rdt

	left join Risk.portf_mfo m
	on a.external_id = m.external_id
	and m.r_date > a.generation
	and EOMONTH(m.r_date) = r.rdt

	left join dwh2.dbo.dm_CMRStatBalance b
	on a.external_id = b.external_id
	and b.d = m.r_date

	left join #stg_write_off w_o
	on a.external_id = w_o.external_id 
	and b.d = w_o.r_date
	
	--left join RiskDWH.dbo.det_crm_redzone z --22/11/2021
	--left join dwh2.risk.[REG_CRM_REDZONE] z
	--on a.external_id = z.external_id
	--and z.action_type like 'Цес%'
	
    left join (select dt_cess as action_date, * from RiskDWH.Risk.Cess_Reestr_UMFO) z
    on a.external_id = z.external_id

	group by a.external_id, r.rdt, a.generation;


	update #payments set pay_od = 0  where isnull(pay_od,0) <= 0.01;
	update #payments set pay_total = 0  where isnull(pay_total,0) <= 0.01;
	update #payments set pay_percents = 0 where isnull(pay_percents,0) <= 0.01;
	update #payments set pay_fines = 0 where isnull(pay_fines,0) <= 0.01;
	update #payments set pay_straf = 0 where isnull(pay_straf,0) <= 0.01;
	update #payments set writeoff_od = 0 where isnull(writeoff_od,0) <= 0.01;
	update #payments set writeoff_int = 0 where isnull(writeoff_int,0) <= 0.01;




	exec dbo.prc$set_debug_info @src = @srcname, @info = '#payments_discount';

	--дисконтированные платежи
	drop table if exists #payments_discount;

	select a.external_id, 
		a.generation, 
		a.mod_dt, 
		a.mod_num, 
		a.pay_od,
		b.eff_rate,
		a.pay_od / power( 1+b.eff_rate , cast(a.mod_num as float) / 12.0) as pay_od_disc,
		
		a.pay_percents,
		a.pay_percents / power( 1+b.eff_rate , cast(a.mod_num as float) / 12.0) as pay_percents_disc,

		a.pay_fines,
		a.pay_fines / power( 1+b.eff_rate , cast(a.mod_num as float) / 12.0) as pay_fines_disc,

		a.pay_straf,
		a.pay_straf / power( 1+b.eff_rate , cast(a.mod_num as float) / 12.0) as pay_straf_disc,

		a.writeoff_od,
		a.writeoff_int

	into #payments_discount

	from #payments a
	left join #con_rate b
	on a.external_id = b.external_id;


	/********************************************************/

	exec dbo.prc$set_debug_info @src = @srcname, @info = 'insert into risk.lgd_payments_agg';

	
	begin transaction;

		delete from risk.lgd_payments_agg 
		where dt_from = @dt_lower_bound 
		and dt_to = @dt_upper_bound 
		and src_data = @data_src
		;

		insert into risk.lgd_payments_agg 
		select 
		@dt_lower_bound as dt_from,
		@dt_upper_bound as dt_to,
		@data_src as src_data,
		cast(getdate() as datetime) as dt_dml,
		a.generation,
		a.mod_dt,
		a.mod_num,
		sum(a.pay_od) as pay_od,
		sum(a.pay_od_disc) as pay_od_disc,
		sum(a.pay_percents) as pay_percents,
		sum(a.pay_percents_disc) as pay_percents_disc,
		sum(a.pay_fines) as pay_fines,
		sum(a.pay_fines_disc) as pay_fines_disc,
		sum(a.pay_straf) as pay_straf,
		sum(a.pay_straf_disc) as pay_straf_disc,
		sum(a.writeoff_od) as writeoff_od,
		sum(a.writeoff_int) as writeoff_int
	
		from #payments_discount a
		group by a.generation, a.mod_dt, a.mod_num
		;

	commit transaction;


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'insert into risk.lgd_od_before_npl_agg';


	begin transaction;

		delete from risk.lgd_od_before_npl_agg
		where dt_from = @dt_lower_bound
		and dt_to = @dt_upper_bound
		and src_data = @data_src
		;

		insert into risk.lgd_od_before_npl_agg
		select 
		@dt_lower_bound as dt_from,
		@dt_upper_bound as dt_to,
		@data_src as src_data,
		cast(getdate() as datetime) as dt_dml,
		a.generation, 
		sum(a.principal_rest) as principal_rest
		from #od_before_npl a
		group by a.generation
		;


	commit transaction;
	


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#recovery_stage1';

	--обычный рекавери,  generation - MOB
	drop table if exists #recovery_stage1;
	select a.generation, 
		a.mod_num, 
		sum(a.pay_od) / sum(b.principal_rest) as recov,
		sum(a.pay_od_disc) / sum(b.principal_rest) as recov_disc,
		
		sum(a.pay_percents) / sum(b.principal_rest) as recov_percents,
		sum(a.pay_percents_disc) / sum(b.principal_rest) as recov_percents_disc,

		sum(a.pay_fines) / sum(b.principal_rest) as recov_fines,
		sum(a.pay_fines_disc) / sum(b.principal_rest) as recov_fines_disc,

		sum(a.pay_straf) / sum(b.principal_rest) as recov_straf,
		sum(a.pay_straf_disc) / sum(b.principal_rest) as recov_straf_disc,

		sum(a.writeoff_od) / sum(b.principal_rest) as writeoff_rate_od,
		sum(a.writeoff_int) / sum(b.principal_rest) as writeoff_rate_int

		
	into #recovery_stage1	
	from risk.lgd_payments_agg a
	left join risk.lgd_od_before_npl_agg b
	on a.dt_from = b.dt_from
	and a.dt_to = b.dt_to
	and a.src_data = b.src_data
	and a.generation = b.generation
	where a.dt_from = @dt_lower_bound
	and a.dt_to = @dt_upper_bound
	and a.src_data = @data_src

	group by a.generation, a.mod_num
	;
	   	  

	exec dbo.prc$set_debug_info @src = @srcname, @info = '#recovery_stage2';

	--средневзвешенный рекавери, группировка по MOB
	drop table if exists #recovery_stage2;
	with portf as (
		select a.generation, a.principal_rest
		from risk.lgd_od_before_npl_agg a
		where a.dt_from = @dt_lower_bound
		and a.dt_to = @dt_upper_bound
		and a.src_data = @data_src
	)
	select r.mod_num, 
	sum(r.recov * p.principal_rest)/sum(p.principal_rest) as recov_w,
	sum(r.recov_disc * p.principal_rest)/sum(p.principal_rest) as recov_disc_w,
	
	sum(r.recov_percents * p.principal_rest)/sum(p.principal_rest) as recov_percents_w,
	sum(r.recov_percents_disc * p.principal_rest)/sum(p.principal_rest) as recov_percents_disc_w,

	sum(r.recov_fines * p.principal_rest)/sum(p.principal_rest) as recov_fines_w,
	sum(r.recov_fines_disc * p.principal_rest)/sum(p.principal_rest) as recov_fines_disc_w,

	sum(r.recov_straf * p.principal_rest)/sum(p.principal_rest) as recov_straf_w,
	sum(r.recov_straf_disc * p.principal_rest)/sum(p.principal_rest) as recov_straf_disc_w,

	sum(r.writeoff_rate_od * p.principal_rest)/sum(p.principal_rest) as writeoff_rate_od_w,
	sum(r.writeoff_rate_int * p.principal_rest)/sum(p.principal_rest) as writeoff_rate_int_w

	into #recovery_stage2

	from #recovery_stage1 r
	left join portf p
	on r.generation = p.generation
	group by r.mod_num;
	   	

	exec dbo.prc$set_debug_info @src = @srcname, @info = 'Until 36 MoB';

	--ограничиваем выборку по кол-ву месяцев в дефолте
	with a as (select * from #recovery_stage2)
	delete from a
	where a.mod_num > @MODcnt
	;


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#recovery_stage3';

	--накопленные (следующие МОБы и предыдущие МОБы)
	drop table if exists #recovery_stage3;

	with base as (
		select a.mod_num, 
		a.recov_w, 
		case when a.mod_num = 1 then 0 else lag(a.recov_w) over (order by a.mod_num) end as lag_recov_w,
	
		a.recov_disc_w, 
		case when a.mod_num = 1 then 0 else lag(a.recov_disc_w) over (order by a.mod_num) end as lag_recov_disc_w,
	
		a.recov_percents_w,
		a.recov_percents_disc_w,

		a.recov_fines_w,
		a.recov_fines_disc_w,

		a.recov_straf_w,
		a.recov_straf_disc_w,

		a.writeoff_rate_od_w,
		a.writeoff_rate_int_w

		from #recovery_stage2 a
	)
	select a.mod_num, 
	a.recov_w, 
	sum(a.recov_w) over (order by a.mod_num rows between current row and unbounded following) as recov_w_acc1,
	sum(a.lag_recov_w) over (order by a.mod_num rows between unbounded preceding and current row) as recov_w_acc2,

	a.recov_disc_w,
	sum(a.recov_disc_w) over (order by a.mod_num rows between current row and unbounded following) as recov_disc_w_acc1,
	sum(a.lag_recov_disc_w) over (order by a.mod_num rows between unbounded preceding and current row) as recov_disc_w_acc2,

	a.recov_percents_w,
	a.recov_percents_disc_w,

	a.recov_fines_w,
	a.recov_fines_disc_w,

	a.recov_straf_w,
	a.recov_straf_disc_w,

	a.writeoff_rate_od_w,
	a.writeoff_rate_int_w

	into #recovery_stage3

	from base a;


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'LGD';

	begin transaction 

		delete from risk.lgd_vint_method
		where dt_from = @dt_lower_bound
		and dt_to = @dt_upper_bound
		and src_data = @data_src;

		insert into risk.lgd_vint_method
		select 
		@dt_lower_bound as dt_from,
		@dt_upper_bound as dt_to,
		@data_src as src_data,
		cast(sysdatetime() as datetime) as dt_dml,
		acc.mod_num,
		1 - acc.recov_w_acc1 / ( 1 - acc.recov_w_acc2 ) as lgd,
		1 - acc.recov_disc_w_acc1 / ( 1 - acc.recov_disc_w_acc2 ) as lgd_disc,
		
		acc.recov_w,
		acc.recov_disc_w,
		
		acc.recov_percents_w,
		acc.recov_percents_disc_w,

		acc.recov_fines_w,
		acc.recov_fines_disc_w,

		acc.recov_straf_w,
		acc.recov_straf_disc_w,

		acc.writeoff_rate_od_w,
		acc.writeoff_rate_int_w  -- !!! * 1.7 /*!!!*/

		from #recovery_stage3 acc;	

	commit transaction;
	   


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'rep_avg_recovery';



	--простыня для построения среднемесячных Recovery
	begin transaction 

		delete from risk.rep_avg_recovery
		where dt_from = @dt_lower_bound
		and dt_to = @dt_upper_bound
		and src_data = @data_src;

		insert into risk.rep_avg_recovery

		select 
		@dt_lower_bound as dt_from,
		@dt_upper_bound as dt_to,
		@data_src as src_data,
		a.generation,
		a.mod_dt,
		a.mod_num,
		sum(a.pay_od) as pay_od,
		sum(a.pay_od_disc) as pay_od_disc,
		sum(b.principal_rest) as principal_rest

		from risk.lgd_payments_agg a
		left join risk.lgd_od_before_npl_agg b
		on a.dt_from = b.dt_from
		and a.dt_to = b.dt_to
		and a.src_data = b.src_data
		and a.generation = b.generation
		where a.dt_from = @dt_lower_bound
		and a.dt_to = @dt_upper_bound
		and a.src_data = @data_src

		group by a.generation,
				 a.mod_dt,
				 a.mod_num

		order by 1,2;

	commit transaction;


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'drop temp (#) tables';
	

	drop table #od_before_npl
	drop table #payments_discount;
	drop table #cmr_writeoff;
	drop table #con_base;
	drop table #con_base_cmr;
	drop table #con_base_mfo;
	drop table #con_rate;
	drop table #payments;
	drop table #pre_write_off;
	drop table #stg_con_rate;
	drop table #stg_write_off;
	drop table #stg1_umfo_writeoff;
	drop table #stg2_umfo_writeoff;
	drop table #write_off__mfo_with_offer;
	drop table #write_off_umfo;
	drop table #recovery_stage1;
	drop table #recovery_stage2;
	drop table #recovery_stage3;


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';

end try

begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch