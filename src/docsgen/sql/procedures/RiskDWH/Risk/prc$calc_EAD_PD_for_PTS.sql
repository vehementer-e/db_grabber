/**************************************************************************
Процедура для расчета EAD и PD по продукту ПТС, которые используются в резервах БУ

Необходимые объекты для процедуры:
срез на @rdt в dwh2.risk.REG_REPORT_KP_FOR_CBR

Revisions:
dt			user				version		description
19/09/24	datsyplakov			v1.0		Создание процедуры
06/12/24	datsyplakov			v1.1		Расчет MonthInDefault для всех договоров
											Для ОД=0 - третья корзина
16/04/2025	agolicyn			v2.0		Заменили источники [c2-vsr-sql04]
22/04/2025	agolicyn			v2.0		Убрали из фиксированную дату и заменили на параметр: PART 2.1 - Расчет матрицы TTC --> where a.r_date <= eomonth('2024-08-31',-3)
23/09/2025	agolicyn			v3.0		Деление на Stage: 0-30, 31-90, 90+
*************************************************************************/


CREATE procedure [Risk].[prc$calc_EAD_PD_for_PTS] @rdt date, @PD_dt date = null, @PD_vers int = null
as 

declare @srcname varchar(100) = 'EAD AND PD CALC FOR PTS BU PROVISIONS'
declare @info varchar(1000) = null;
declare @vers int = null;


begin try


	if @vers is null begin
	select @vers = isnull(max(a.vers),0) + 1 from risk.IFRS9_vitr a where a.r_date = @rdt;
	end

	set @info = concat('START rdt ', 
					format(@rdt,'dd.MM.yyyy') ,
					' vers ' , format(@vers,'#') ,
					' PD_dt = ' , format(isnull(@PD_dt,@rdt),'dd.MM.yyyy') , 
					' PD_vers = ' , format(isnull(@PD_vers,0),'##0')
					)
	
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;

	exec dbo.prc$set_debug_info @src = @srcname, @info = 'credit vacations';

	--Для восстановления dpd по кредитным каникулам
	drop table if exists #credit_vacations;
	select a.external_id, cast(a.kk_dt_from as date) as kk_from, b.dpd
	into #credit_vacations
	from dwh2.risk.credits a
	inner join dwh2.dbo.dm_CMRStatBalance b (nolock)
	on a.external_id = b.external_id
	and dateadd(dd,-1,cast(a.kk_dt_from as date)) = b.d
	;

	insert into #credit_vacations
	select a.external_id, cast(a.freezing_dt_from as date) as kk_from, b.dpd
	from dwh2.risk.credits a
	inner join dwh2.dbo.dm_CMRStatBalance b (nolock)
	on a.external_id = b.external_id
	and dateadd(dd,-1,cast(a.freezing_dt_from as date)) = b.d
	where a.kk_dt_from is null
	and a.freezing_dt_from is not null
	;


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'CMR lite';

	--просрочка ЦМР с учетом каникул
	drop table if exists #CMR;

	select a.external_id,
	a.d as r_date,
	a.dpd,
	case 
	when c.external_id is not null and a.d >= c.kk_from then DATEDIFF(dd,c.kk_from,a.d) + c.dpd
	else a.dpd
	end as dpd_analyt
	into #CMR
	from dwh2.dbo.dm_CMRStatBalance a (nolock)
	inner join dwh2.risk.credits b
	on a.external_id = b.external_id
	left join #credit_vacations c
	on a.external_id = c.external_id
	where a.d >= '2016-01-01'
	and a.d <= @rdt
	and b.IsInstallment = 0
	;


	drop index if exists idx_cmr on #CMR;
	create clustered index idx_cmr on #CMR (external_id, r_date);





	------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- PART 1 - Подготовка исходных данных
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'THIN';


	--База для расчета матриц: отчетная дата, договор, dpd, корзина dpd

	drop table if exists #THIN;
	select a.external_id, 
	a.r_date, 
	a.dpd, 
	a.dpd_analyt,
	RiskDWH.dbo.get_bucket_90(a.dpd) as dpd_bucket,
	RiskDWH.dbo.get_bucket_90(a.dpd_analyt) as dpd_bucket_analyt

	into #THIN
	from #CMR a
	where 1=1
	and a.r_date = EOMONTH(a.r_date)
	and a.r_date <= @rdt
	and a.r_date >= '2018-01-01'
	;


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'Bankrupts';

	--Банкроты

	drop table if exists #stg_bankrupt;
	select a.Контрагент as contragent,
	min(cast(dateadd(yy,-2000,a.дата) as date)) as dt
	into #stg_bankrupt
	from [stg].[_1cUMFO].[Документ_АЭ_БанкротствоЗаемщика] a
	group by a.Контрагент;


	drop table if exists #bankrupt;
	select 
	a.НомерДоговора as external_id,
	max(b.dt) as dt_bankrupt
	--distinct a.Ссылка as ssylka, b.dt, a.НомерДоговора as external_id
	into #bankrupt
	from stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный a
	inner join #stg_bankrupt b
	on a.Контрагент = b.contragent
	where a.НомерДоговора <> '1'
	group by a.НомерДоговора
	;


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'Default dates';

	drop table if exists #stg_default;
	select a.external_id, 
	case when max(case when a.r_date between EOMONTH(@rdt,-6) and @rdt then a.dpd else 0 end) > 90 then 1 else 0 end as flag_default_6m,
	case when max(case when a.r_date between EOMONTH(@rdt,-12) and @rdt then a.dpd else 0 end) > 90 then 1 else 0 end as flag_default_12m,
	max(case when a.dpd = 91 then a.r_date end) as dt_last_default
	into #stg_default
	from #CMR a

	where 1=1
	and a.r_date <= @rdt
	group by a.external_id
	;



	exec dbo.prc$set_debug_info @src = @srcname, @info = 'EPS';

	--ЭффПроцСтавка (ПСК)
	drop table if exists #stg_eps;
	select a.external_id, 
	eomonth(isnull(b.startdate,convert(date,a.[Дата выдачи],104))) as generation,
	case 
	when a.external_id = '19100700000136' then cast(159000 as float) --КОСТЫЛЬ!!! некорректная сумма выдачи
	else isnull(cast(b.amount as float),cast(a.[Сумма займа] as float)) 
	end as amount,
	cast(a.ПСК / 100.0 as float) as eps
	into #stg_eps
	from dwh2.risk.REG_REPORT_KP_FOR_CBR a
	left join dwh2.risk.credits b
	on a.external_id = b.external_id
	where a.r_date = @rdt
	and a.ПСК is not null
	;




	--ЭПС из УМФО


	drop table if exists #stg2_eps;

	------------------------------------------- OLD BEGIN  -------------------------------------------------------
	select b.НомерДоговора as external_id, 
	c.период as период, 
	--c.активность as активность, 
	c.эффективнаяставкапроцента as эффективнаяставкапроцента,
	eomonth(dateadd(yy,-2000,cast(b.ДатаНачала as date))) as generation,
	b.СуммаЗайма as amount
	into #stg2_eps
	--select *
	from stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный b
	--left join [c2-vsr-sql04].[UMFO].[dbo].[РегистрСведений_АЭ_АктуальныеГрафикиПлатежейЗаймовПредоставленных] c
	left join (
				SELECT external_id
					, период
					, InitialRate as эффективнаяставкапроцента
					, Ссылка
				FROM (
					SELECT a.Код AS external_id, a.Дата as период, Ссылка
						,iif(cast(p.ПроцентнаяСтавка AS INT) = 0, p.НачисляемыеПроценты, p.ПроцентнаяСтавка) AS InitialRate
						,row_number() OVER (PARTITION BY a.код ORDER BY p.Период ASC) AS rn--select *
					FROM stg._1ccmr.Справочник_Договоры a
					LEFT JOIN STG._1Ccmr.РегистрСведений_ПараметрыДоговора p ON a.ССылка = p.Договор
					) t
				WHERE rn = 1
				) c
	on b.Ссылка = c.Ссылка
	where b.ПометкаУдаления = 0

	;

	drop table if exists #eps;
	with base as (
	select a.*, ROW_NUMBER() over (partition by a.external_id order by a.Период desc) as rown
	from #stg2_eps a
	where a.эффективнаяставкапроцента > 0
	and dateadd(yy,-2000,cast(a.период as date)) <= @rdt
	)
	select a.external_id, a.generation, a.amount, a.эффективнаяставкапроцента / 100.0 as eps
	into #eps
	from base a
	where a.rown = 1
	;



	drop table if exists #avg_eps_gen;
	select 
	a.generation, 
	sum(a.amount * a.eps) / sum(a.amount) as eps
	into #avg_eps_gen
	from (
		select a.external_id, a.generation, a.amount, a.eps from #stg_eps a
		union all
		select a.external_id, a.generation, a.amount, a.eps from #eps a 
		where not exists (select 1 from #stg_eps b where a.external_id = b.external_id)
	) a
	group by a.generation
	;


	drop table if exists #avg_eps;
	select 
	sum(a.amount * a.eps) / sum(a.amount) as eps
	into #avg_eps
	from (
		select a.external_id, a.generation, a.amount, a.eps from #stg_eps a
		union all
		select a.external_id, a.generation, a.amount, a.eps from #eps a 
		where not exists (select 1 from #stg_eps b where a.external_id = b.external_id)
	) a
	;





	exec dbo.prc$set_debug_info @src = @srcname, @info = 'Restructs';
	--Флаг и дата реструктуризации для КК/Заморозок


	drop table if exists #pre_kk_restruct;
	with base as (
		select a.number as external_id, a.operation_type, 
		cast(a.period_start as date) as period_start, 
		cast(a.period_end as date) as period_end, 
		ROW_NUMBER() over (partition by a.number order by a.period_start desc) as rown
		from dwh2.dbo.dm_restructurings a
		where a.period_start <= @rdt
		and exists (select 1 from dwh2.dbo.dm_restructurings b where a.number = b.number and b.operation_type in ('Кредитные каникулы','Заморозка 1.0'))
	)
	select @rdt as r_date, a.external_id, a.operation_type, a.period_start, a.period_end 
	into #pre_kk_restruct
	from base a
	where a.rown = 1
	;

	drop table if exists #stg_kk_restruct
	select a.r_date, a.external_id, 
	a.operation_type,
	a.period_start,
	a.period_end,

	case 
	when a.operation_type in ('Кредитные каникулы','Заморозка 1.0') and a.r_date between a.period_start and a.period_end then a.r_date
	when a.operation_type in ('Кредитные каникулы','Заморозка 1.0') then a.period_end
	else a.period_start 
	end as dt_restruct

	into #stg_kk_restruct

	from #pre_kk_restruct a;



	--Реструктуризации из КП для ЦБ

	drop table if exists #stg_KP_restr;
	with d as (
		select cast(a.dt as date) as rdt
		from dwh2.risk.calendar a
		where a.dt between '2018-12-31' and '2021-04-30'
		and a.dt = EOMONTH(a.dt)
	), r as (
		select distinct a.external_id, 
		a.Реструктуризирован, 
		convert(date,a.[Реструктуризирован дата],104) as restr_dt
		from dwh2.risk.REG_REPORT_KP_FOR_CBR a	
		where 1=1
		and (Реструктуризирован = 'Да' or [Реструктуризирован дата] is not null)
	)
	select b.external_id, a.rdt, max(b.restr_dt) as restr_dt
	into #stg_KP_restr
	from d as a
	left join r as b
	on b.restr_dt <= a.rdt
	group by b.external_id, a.rdt;




	exec dbo.prc$set_debug_info @src = @srcname, @info = 'FAT';

	--Последний фактический срез - основа для EAD
	drop table if exists #FAT;
	with base as (
		select  
		a.r_date, 
		a.external_id, 	
		isnull(b.startdate,convert(date,a.[Дата выдачи],104)) as dt_open_fact,
		eomonth(isnull(b.startdate,convert(date,a.[Дата выдачи],104))) as generation,
		cast(a.ПСК / 100.0 as float) as eps,
		isnull(cast(b.InitialRate as float) / 100.0, a.int_rate_iss) as int_rate, 
		case 
		when a.external_id = '19100700000136' then cast(159000 as float) --КОСТЫЛЬ!!! некорректная сумма выдачи
		else isnull(cast(b.amount as float),cast(a.[Сумма займа] as float)) 
		end as amount,
		isnull(a.[Срок договора в месяцах],b.term) as term,	
		isnull(fd.dpd,a.dpd_prov) as dpd,
		a.principal_rest,
		a.percents_rest,
		a.others_rest,
		a.gross_rest,
		a.[Финансовый продукт] as product,
		case 
		when b.kk_dt_from is not null and kkr.external_id is not null then 1
		when b.kk_dt_from is null and a.Реструктуризирован = 'Да' then 1	
		else 0 end as flag_restruct,
	
		case when b.kk_dt_from is not null then kkr.dt_restruct
		else convert(date,a.[Реструктуризирован дата],104) 
		end as dt_restruct,
	
		df.flag_default_6m,
		df.flag_default_12m,
		df.dt_last_default,
		case when bkr.external_id is not null then 1 else 0 end as flag_bankrupt,
		case when b.kk_dt_from is not null then 1 else 0 end as flag_kk,

		row_number() over (partition by a.external_id order by a.principal_rest) as rown

		from dwh2.risk.REG_REPORT_KP_FOR_CBR a 
	

		left join dwh2.risk.credits b
		on a.external_id = b.external_id
		left join #stg_default df
		on a.external_id = df.external_id
		left join #bankrupt bkr
		on a.external_id = bkr.external_id
		and bkr.dt_bankrupt <= a.r_date
		left join #stg_kk_restruct kkr
		on a.external_id = kkr.external_id	
		left join risk.prov_stg_fix_dpd fd
		on a.external_id = fd.external_id
		and a.r_date = fd.r_date
	
		where a.r_date = @rdt
		and isnull(a.[Финансовый продукт],'n') not like '%ПРО100%'
		and isnull(a.[Финансовый продукт],'n') <> 'PDL'
		and isnull(a.[Финансовый продукт],'n') not like 'Бизнес%'

	)
	select  
	a.r_date,
	a.external_id,
	a.dt_open_fact,
	DATEDIFF(MM, a.dt_open_fact, a.r_date) as MoB,
	a.term,
	a.int_rate,
	coalesce(d.eps,a.eps,b.eps,c.eps) as eps,
	a.amount,
	a.principal_rest,
	a.percents_rest,
	a.others_rest,
	a.gross_rest,
	a.dpd,
	RiskDWH.dbo.get_bucket_90(a.dpd) as dpd_bucket,
	case 
	when a.product like '%бизнес%' then 'BUSINESS'
	when a.product like '%ПРО100%' then 'INSTALLMENT'
	else 'PTS' end as product,
	a.flag_restruct,
	a.dt_restruct,
	a.flag_default_6m,
	a.flag_default_12m,
	a.dt_last_default,
	a.flag_bankrupt,
	a.flag_kk,

	
	--case 
	--	--3 корзина: dpd > 90 ИЛИ был дефолт за посл 6 месяцев ИЛИ была реструкт за посл 3 месяца ИЛИ Банкрот ИЛИ ОД=0
	--	when a.dpd > 90 
	--		or a.flag_default_6m = 1
	--		or (a.flag_restruct = 1 and datediff(MM,a.dt_restruct,a.r_date) between 0 and 2) 
	--		or a.flag_bankrupt = 1
	--		or a.principal_rest = 0 
	--	then 3
	--	--2 корзина: 31 <= dpd < 90 ИЛИ был дефолт за посл 12 месяцев и не прошло больше 6 мес ИЛИ была реструкт за посл 6 месяцев и не прошло более 3 мес
	--	when a.dpd between 31 and 90
	--		or (a.flag_default_12m = 1 and a.flag_default_6m = 0)
	--		or (a.flag_restruct = 1 and datediff(MM,a.dt_restruct,a.r_date) between 3 and 5)
	--	then 2
	--	--1 корзина: dpd <= 30 ИЛИ была реструкт и прошло более 6 мес
	--	when a.dpd <= 30
	--		or (a.flag_restruct = 1 and datediff(MM,a.dt_restruct,a.r_date) >= 6)
	--	then 1
	--end
	

	--c 2025.10.31
	case 
		--3 корзина: dpd > 90 или Банкрот
		when a.dpd > 90 or a.flag_bankrupt = 1 or a.principal_rest = 0 then 3
		--2 корзина: 31 <= dpd < 90
		when a.dpd between 31 and 90 then 2
		--1 корзина: dpd <= 30 ИЛИ была реструкт и прошло более 6 мес
		when a.dpd <= 30 then 1 else -1
	end
	
	as stage

	into #FAT
	from base a
	left join #avg_eps_gen b
	on a.generation = b.generation
	left join #avg_eps c
	on 1 = 1
	left join #eps d
	on a.external_id = d.external_id
	where a.rown = 1
	;



	--Костыль выдача

	update #FAT set amount = 473333 where external_id = '22071600454288';
	update #FAT set term = 6 where external_id like '__-З';

	--Костыли для 2020-12-31 FAT

	delete from #FAT where external_id = '19090200000128' and eps < 1 and r_date = '2020-12-31';
	delete from #FAT where principal_rest < 0 and r_date = '2020-12-31';
	delete from #FAT where external_id = '1' and r_date = '2020-12-31';
	update #FAT set principal_rest = 154000, gross_rest = 154000+152964.73 where external_id = '19121310000042' and r_date = '2020-12-31';
	update #FAT set principal_rest = 700000, gross_rest = 700000+691345.1+29663.9  where external_id = '19121510000016' and r_date = '2020-12-31';
	update #FAT set amount = 338762 where external_id = '20072400026450' and r_date = '2020-12-31';
	update #FAT set principal_rest = 48459.8, percents_rest = 2425.1, gross_rest = 48459.8+2425.1  where external_id = '20101100041359' and r_date = '2020-12-31';
	update #FAT set principal_rest = 89637.22, percents_rest = 4485.78, gross_rest = 89637.22+4485.78  where external_id = '20101200041391' and r_date = '2020-12-31';
	update #FAT set principal_rest = 814643.13, percents_rest = 31784.44, gross_rest = 814643.13+31784.44  where external_id = '20101300041779' and r_date = '2020-12-31';
	update #FAT set principal_rest = 50000, gross_rest = 50000+47911.14 where external_id = '19122100004722' and r_date = '2020-12-31';
	update #FAT set principal_rest = 49798.68, gross_rest = 49798.68+2754.45  where external_id = '20100500039543' and r_date = '2020-12-31';
	update #FAT set amount = 139000 where external_id = '19112610000265' and r_date = '2020-12-31';

	--Разные костыли
	delete from #FAT where external_id = '19090200000128' and r_date = '2019-12-31' and isnull(eps,-999) <> 1.02756
	delete from #FAT where external_id = '19090200000128' and r_date = '2020-12-31' and isnull(eps,-999) <> 1.02756
	delete from #FAT where external_id = '2' and principal_rest < 0;
	delete from #FAT where external_id = '3' and principal_rest < 0;
	update #FAT set principal_rest = amount, gross_rest = amount + percents_rest + others_rest where principal_rest > amount




	--Проверка: остаток ОД > сумма выдачи

	select @info = count(*)
	from #FAT a
	where a.principal_rest > a.amount 
	;

	set @info = 'P1 Проверка: остаток ОД > сумма выдачи (должно быть 0) ' + @info;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;

	--Проверка: дубли по договорам и отчетным датам
	select @info = count(*) from (
		select a.external_id, a.r_date
		from #FAT a
		group by a.external_id, a.r_date
		having count(*)>1
	) a
	;


	set @info = 'P1 Проверка: дубли по договорам и отчетным датам FAT (должно быть 0) ' + @info;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;


	--Проверка: дубли по договор-отчетная дата
	select @info = count(*) from (
		select a.external_id, a.r_date
		from #THIN a
		group by a.external_id, a.r_date
		having count(*)>1
	) a
	;

	set @info = 'P1 Проверка: дубли по договор-отчетная дата THIN (должно быть 0) ' + @info
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;

	--Проверка: ГРОСС = ОД+%%+прочее
	select @info = count(*)
	from #FAT a
	where round(a.principal_rest, 2) + round(a.percents_rest, 2) + round(a.others_rest, 2) <> round(a.gross_rest, 2)


	set @info = 'P1 Проверка: ГРОСС = ОД+%%+прочее (должно быть 0) ' + @info;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;



	--Проверка: Пустой ЭПС
	select @info = count(*)
	from #FAT a
	where a.eps is null


	set @info = 'P1 Проверка: Пустой ЭПС (должно быть 0) ' + @info
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;




	drop table #stg_bankrupt;
	drop table #bankrupt;
	drop table #stg_default;
	drop table #stg_kk_restruct;
	drop table #pre_kk_restruct;
	drop table #stg_eps;
	drop table #avg_eps;
	drop table #avg_eps_gen;
	drop table #stg2_eps;
	drop table #eps;




	------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- PART 2 - Расчет PD (TTC & PIT) на основе матриц миграций
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------



	drop table if exists #Probability_of_Default
	create table #Probability_of_Default (
	pd_type varchar(100),
	yr int,
	mon int,
	month_number int,
	dpd_bucket varchar(100),
	cumul_PD float, 
	margin_PD float,
	ECL_PD float
	);





	if isnull(@PD_dt,@rdt) <> @rdt begin 

		set @info = concat('old PD dt = ' , format(@PD_dt,'dd.MM.yyyy') , ' vers = '  , format(@PD_vers,'####0'));
		exec dbo.prc$set_debug_info @src = @srcname, @info = @info;

	
		drop table if exists #stg22_pd;
		select a.pd_type,
		a.yr,
		a.mon,
		a.mon - (a.yr - 1) * 12 as month_number,
		a.dpd_bucket,
		sum(a.margin_PD) over (partition by a.pd_type, a.dpd_bucket order by a.mon rows between unbounded preceding and current row) as cumul_PD 
		into #stg22_pd
		from risk.stg_IFRS9_PD a
		where a.r_date = @PD_dt and a.vers = @PD_vers;


		--маржинальные PD и PD для вычисления суммы ожидаемых потерь
		insert into #Probability_of_Default
		select a.pd_type,
		a.yr,
		a.mon,
		a.month_number,
		a.dpd_bucket,
		a.cumul_PD, 
		a.cumul_PD - isnull(c.cumul_PD,0) as margin_PD,
		a.cumul_PD - isnull(b.cumul_PD,0) as ECL_PD

		from #stg22_pd a
		left join #stg22_pd b
		on a.pd_type = b.pd_type
		and a.dpd_bucket = b.dpd_bucket
		and a.yr = b.yr + 1
		and b.month_number = 12
		left join #stg22_pd c
		on a.pd_type = c.pd_type
		and a.dpd_bucket = c.dpd_bucket
		and a.mon = c.mon + 1
		;

		drop table #stg22_pd;


	end 


	if isnull(@PD_dt,@rdt) = @rdt begin 

		------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- PART 2.1 - Расчет матрицы TTC
		------------------------------------------------------------------------------------------------------------------------------------------------------------------------


		exec dbo.prc$set_debug_info @src = @srcname, @info = 'quart TTC matrix';


		--агрегат квартальных (переход через 3 месяца) данных
		drop table if exists #stg2_matrix;
		select 
		a.r_date as rdt_from, 
		b.r_date as rdt_to,
		a.dpd_bucket_analyt as dpd_bucket_from,
		isnull(b.dpd_bucket_analyt,'[01] 0') as dpd_bucket_to,
		count(*) as cnt
		into #stg2_matrix
		from #THIN a
		left join #THIN b
		on a.external_id = b.external_id
		and a.r_date = eomonth(b.r_date,-3)
		where a.r_date <= eomonth(@rdt,-3)
		group by 
		a.r_date,
		b.r_date,
		a.dpd_bucket_analyt,
		b.dpd_bucket_analyt
		;




		--сборка квартальных матриц
		drop table if exists #stg3_matrix;

		with denumerator as (
			select a.rdt_from, a.dpd_bucket_from, sum(a.cnt) as znam
			from #stg2_matrix a
			group by a.rdt_from, a.dpd_bucket_from
		)
		select a.rdt_from,
		a.rdt_to,
		a.dpd_bucket_from,
		a.dpd_bucket_to,
		cast(a.cnt as float) as chisl,
		cast(b.znam as float) as znam,
		cast(a.cnt as float) / cast(b.znam as float) as koef

		into #stg3_matrix

		from #stg2_matrix a
		left join denumerator b
		on a.rdt_from = b.rdt_from
		and a.dpd_bucket_from = b.dpd_bucket_from
		;




		--проверка: сумма по строке равна 1?

		select @info = count(*) 
		from (
			select a.rdt_from, a.dpd_bucket_from, sum(a.koef) as row_sum
			from #stg3_matrix a
			group by a.rdt_from, a.dpd_bucket_from
			having round(sum(a.koef),4) <> 1.0
		) a
		;

		set @info = 'P2 Проверка: квартальные матрицы, сумма по строке равна 1? (должно быть 0) ' + @info
		exec dbo.prc$set_debug_info @src = @srcname, @info = @info;




		--Усредненная квартальная матрица
 
 
		drop table if exists #quart_matrix;

		with denumerator as (
			select a.dpd_bucket_from, sum(a.chisl) as znam
			from #stg3_matrix a
			group by a.dpd_bucket_from
		), numerator as (
			select a.dpd_bucket_from, a.dpd_bucket_to, sum(a.chisl) as chisl
			from #stg3_matrix a
			group by a.dpd_bucket_from, a.dpd_bucket_to
		)
		select a.dpd_bucket_from, a.dpd_bucket_to, 
		a.chisl, 
		b.znam, 
		case 
		when a.dpd_bucket_from = '[05] 90+' and a.dpd_bucket_to = '[05] 90+' then 1
		when a.dpd_bucket_from = '[05] 90+' and a.dpd_bucket_to <> '[05] 90+' then 0
		else a.chisl / b.znam 
		end as koef

		into #quart_matrix
		from numerator a
		left join denumerator b
		on a.dpd_bucket_from = b.dpd_bucket_from
		order by 1,2;


		--сумма по строке равна 1?

		select @info = count(*) 
		from (
			select a.dpd_bucket_from, sum(a.koef) as skoef
			from #quart_matrix a
			group by a.dpd_bucket_from
			having round(sum(a.koef),6) <> 1
		) a
		;


		set @info = 'P2 Проверка: усредненная квартальная матрица, сумма по строке равна 1? (должно быть 0) ' + @info
		exec dbo.prc$set_debug_info @src = @srcname, @info = @info;



		exec dbo.prc$set_debug_info @src = @srcname, @info = 'year TTC matrix';
		--Годовая матрица

		--шаг 0
		drop table if exists #year_matrix;
		select a.dpd_bucket_from, b.dpd_bucket_to, sum(a.koef * b.koef) as koef 
		into #year_matrix
		from #quart_matrix a
		left join #quart_matrix b
		on a.dpd_bucket_to = b.dpd_bucket_from
		group by a.dpd_bucket_from, b.dpd_bucket_to
		;

		declare @i int = 1;

		while @i < 3
		begin

			set @info = 'year matrix, iter = ' + cast(@i as varchar(2));
			exec dbo.prc$set_debug_info @src = @srcname, @info = @info;


			drop table if exists #tmp_year_matrix;
			select * 
			into #tmp_year_matrix
			from #year_matrix
			;

			delete from #year_matrix;

			insert into #year_matrix
			select a.dpd_bucket_from, b.dpd_bucket_to, sum(a.koef * b.koef) as koef 
			from #tmp_year_matrix a
			left join #quart_matrix b
			on a.dpd_bucket_to = b.dpd_bucket_from
			group by a.dpd_bucket_from, b.dpd_bucket_to
			;

			set @i = @i + 1;


		end;



		exec dbo.prc$set_debug_info @src = @srcname, @info = 'TTC matrix';
		--Матрица на несколько лет
		drop table if exists #TTC_matrix;

		select 1 as yr, a.dpd_bucket_from, a.dpd_bucket_to, a.koef
		into #TTC_matrix
		from #year_matrix a
		;

		declare @j int = 2;

		while @j <= 20
		begin

		insert into #TTC_matrix
		select @j as yr, a.dpd_bucket_from, b.dpd_bucket_to, sum(a.koef * b.koef ) as koef
		from #TTC_matrix a
		left join #year_matrix b
		on a.dpd_bucket_to = b.dpd_bucket_from
		where a.yr = @j - 1
		group by a.dpd_bucket_from, b.dpd_bucket_to

		set @j = @j + 1

		end;


		--22.05.2023 - костыль на PD_TTC, дефолт второго года НЕ должен быть больше первого

		with base as (
			select RiskDWH.[CM\A.Borisov].func$greatest(b.koef - a.koef * 2, 0) as delta
			from #TTC_matrix a
			left join #TTC_matrix b
			on a.dpd_bucket_from = b.dpd_bucket_from
			and a.dpd_bucket_to = b.dpd_bucket_to
			and b.yr = 2
			where a.dpd_bucket_from = '[01] 0'
			and a.dpd_bucket_to = '[05] 90+'
			and a.yr = 1
		)
		update a set a.koef = a.koef - isnull(b.delta,0)
		--select *
		from #TTC_matrix a
		left join base b
		on a.yr > 1
		where a.dpd_bucket_from = '[01] 0'
		and a.dpd_bucket_to = '[05] 90+'
		;





		------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- PART 2.2 - Расчет матрицы PIT
		------------------------------------------------------------------------------------------------------------------------------------------------------------------------


		exec dbo.prc$set_debug_info @src = @srcname, @info = 'from TTC to PIT';

		--Калибровка модельного PD на PD PIT

		drop table if exists #pd_adjust;
		create table #pd_adjust (
		mark varchar(100),
		val float
		)
		;


		--pd PIT portfolio - годовая частота дефолта по портфелю за последние N лет
		with cred as (
			select datediff(yy,a.r_date,@rdt) as T, a.r_date, a.external_id, a.dpd
			from #THIN a
			where a.r_date <= eomonth(@rdt,-12) 
			and month(a.r_date) = month(eomonth(@rdt,-12)) 
			--and not exists (select 1 from dwh2.risk.credit_restructuring b where a.external_id = b.external_id and b.operation_type = 'Кредитные каникулы')
		), maximum_dpd as (
			select a.T, a.external_id, max(isnull(b.dpd,0)) as dpd
			from cred a
			left join #THIN b
			on a.external_id = b.external_id
			and b.r_date between eomonth(a.r_date,1) and eomonth(a.r_date,12)
			group by a.T, a.external_id
		), base as (
			select a.T, a.external_id, 
			cast(case when a.dpd < 91 and b.dpd > 90 then 1 else 0 end as float) as chisl,
			cast(case when a.dpd < 91 then 1 else 0 end as float) as znam
			from cred a
			left join maximum_dpd b
			on a.T = b.T
			and a.external_id = b.external_id
		)
		insert into #pd_adjust
		select 
		'PD_PIT_PORTFOLIO_'+cast(a.T as varchar(2)) as mark,
		sum(a.chisl) / sum(a.znam) as val
		from base a 
		group by a.T
		union all
		select 'chisl_'+cast(a.T as varchar(2)) as mark,
		sum(a.chisl) as val
		from base a
		group by a.T
		union all
		select 'znam_'+cast(a.T as varchar(2)) as mark,
		sum(a.znam) as val
		from base a
		group by a.T
		;

		--PD TTC

		insert into #pd_adjust
		select 
		'PD_TTC_PORTFOLIO' as mark,
		sum(case when a.mark like 'chisl%' then a.val else 0 end) / sum(case when a.mark like 'znam%' then a.val else 0 end) as val
		from #pd_adjust a
		;





		--велична шансов на основе вероятности дефолта: TTC и PIT
		insert into #pd_adjust
		select 
		'ODDS_PD_PIT_PORTFOLIO' as mark,
		a.val / (1.0 - a.val) as val
		from #pd_adjust a
		where a.mark like 'PD%1'


		insert into #pd_adjust
		select 
		'ODDS_PD_TTC_PORTFOLIO' as mark,
		a.val / (1.0 - a.val) as val
		from #pd_adjust a
		where a.mark = 'PD_TTC_PORTFOLIO'
		;


		--отношение шансов PIT к TTC
		insert into #pd_adjust
		select  
		'K' as mark,
		sum(case when a.mark = 'ODDS_PD_PIT_PORTFOLIO' then a.val else 0 end) / sum(case when a.mark = 'ODDS_PD_TTC_PORTFOLIO' then a.val else 0 end) as val
		from #pd_adjust a
		where a.mark in ('ODDS_PD_PIT_PORTFOLIO','ODDS_PD_TTC_PORTFOLIO')
		;


		--Шансы для групп просрочки TTC
		insert into #pd_adjust
		select 
		'ODDS_PD_TTC_'+a.dpd_bucket_from as mark,
		a.koef / (1.0 - a.koef) as val
		from #year_matrix a
		where a.dpd_bucket_from <> '[05] 90+' and a.dpd_bucket_to = '[05] 90+'
		;


		--Шансы для групп просрочки PIT

		insert into #pd_adjust
		select replace(a.mark,'TTC','PIT') as mark,
		a.val * b.val as val
		from #pd_adjust a
		left join #pd_adjust b
		on b.mark = 'K'
		where a.mark like 'ODDS_PD_TTC_%'
		and a.mark <> 'ODDS_PD_TTC_PORTFOLIO'
		;



		--PIT вероятность дефолта соответствующей группы просроченной задолженности
		insert into #pd_adjust
		select replace(a.mark,'ODDS_','') as mark, 
		a.val / (1.0 + a.val) as val

		from #pd_adjust a
		where a.mark like 'ODDS_PD_PIT%'
		and a.mark <> 'ODDS_PD_PIT_PORTFOLIO'
		;


		drop table if exists #stg_pd_PIT;
		select substring(a.mark,8,20) as dpd_bucket, a.val as prob
		into #stg_pd_PIT
		from #pd_adjust a
		where a.mark like 'PD_PIT%'
		and a.mark not like 'PD_PIT_PORTFOLIO%'
		order by 1





		--Подстановка полученных вероятностей PIT в матрицу и нормировка

		drop table if exists #PIT_year_matrix;
		with base as (
			select a.dpd_bucket_from, a.dpd_bucket_to,
			isnull(b.prob, a.koef) as koef
			from #year_matrix a
			left join #stg_pd_PIT b
			on a.dpd_bucket_from = b.dpd_bucket
			and a.dpd_bucket_to = '[05] 90+'
		), corr1 as (
			select a.dpd_bucket_from, sum(a.koef) as s
			from base a
			where a.dpd_bucket_from <> '[05] 90+' and a.dpd_bucket_to <> '[05] 90+'
			group by a.dpd_bucket_from
		), corr2 as (
			select a.dpd_bucket_from, (1.0 - b.koef) / a.s as alpha 
			from corr1 a
			left join base b
			on a.dpd_bucket_from = b.dpd_bucket_from
			and b.dpd_bucket_to = '[05] 90+'
		)
		select a.dpd_bucket_from, a.dpd_bucket_to, 
		--a.koef, 
		case 
		when a.dpd_bucket_from = '[05] 90+' then a.koef 
		when a.dpd_bucket_to = '[05] 90+' then a.koef
		else a.koef * b.alpha 
		end as koef

		into #PIT_year_matrix
		from base a
		left join corr2 b
		on a.dpd_bucket_from = b.dpd_bucket_from
		order by 1,2
		;



		--проверка: сумма строки равна 1?
		select @info = count(*) from (
			select a.dpd_bucket_from
			from #PIT_year_matrix a
			group by a.dpd_bucket_from
			having round(sum(a.koef),6) <> 1.0
		) a
		;

		set @info = 'P2 Проверка: годовая матрица PIT, сумма по строке равна 1? (должно быть 0) ' + @info;
		exec dbo.prc$set_debug_info @src = @srcname, @info = @info;



		--матрица на 20 лет
		drop table if exists #PIT_matrix;
		create table #PIT_matrix (
		yr int,
		dpd_bucket_from varchar(100),
		dpd_bucket_to varchar(100),
		koef float
		);


		declare @ii int = 1;

		while @ii <= 20
		begin

			if @ii = 1
			begin

				insert into #PIT_matrix
				select @ii, a.dpd_bucket_from, a.dpd_bucket_to, a.koef 
				from #PIT_year_matrix a	

			end

			else 

			begin

				insert into #PIT_matrix
				select @ii, a.dpd_bucket_from, b.dpd_bucket_to, sum(a.koef * b.koef) as koef 
				from #PIT_matrix a
				left join #PIT_year_matrix b
				on a.dpd_bucket_to = b.dpd_bucket_from
				where a.yr = @ii - 1
				group by a.dpd_bucket_from, b.dpd_bucket_to

			end

		set @ii = @ii + 1

		end;


		--проверка: сумма по строке равна 1?
		select @info = count(*)
		from (
			select a.yr, a.dpd_bucket_from, sum(a.koef) as k
			from #PIT_matrix a
			group by a.yr, a.dpd_bucket_from
			having round(sum(a.koef),6) <> 1
		) a
		;


		set @info = 'P2 Проверка: годовые матрицы PIT, сумма по строке равна 1? (должно быть 0) ' + @info;
		exec dbo.prc$set_debug_info @src = @srcname, @info = @info;



		drop table #stg2_matrix;
		drop table #stg3_matrix;
		drop table #PIT_year_matrix;
		drop table #year_matrix;
		drop table #quart_matrix;
		drop table #stg_pd_PIT;
		drop table #tmp_year_matrix;




		------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- PART 2.3 - Финальный PD
		------------------------------------------------------------------------------------------------------------------------------------------------------------------------


		exec dbo.prc$set_debug_info @src = @srcname, @info = 'from TTC to PIT';

		--собираем вероятности перехода в 90+ (кумулятивные) из матриц миграций
		drop table if exists #stg1_pd;
		with m as (
			select cast(1 as int) as month_number
			union all
			select m.month_number + 1 
			from m
			where m.month_number < 12
		)
		select 
		a.matr_type, 
		a.yr, 
		m.month_number + (a.yr - 1) * 12 as mon,
		m.month_number,
		a.dpd_bucket_from as dpd_bucket, 
		a.koef 
		into #stg1_pd
		from (
			select 'TTC' as matr_type, a.* from #TTC_matrix a
			union all
			select 'PIT' as matr_type, a.* from #PIT_matrix a
		) a, m as m
		where a.dpd_bucket_to = '[05] 90+' and a.dpd_bucket_from <> '[05] 90+'
		;


		--интерполяция кумулятивного PD по месяцам
		drop table if exists #stg2_pd;
		select a.matr_type as pd_type, a.yr, a.mon, a.month_number, a.dpd_bucket,
		isnull(b.koef,0.0) + (a.koef - isnull(b.koef,0.0)) * a.month_number / 12.0 as cumul_PD
		into #stg2_pd
		from #stg1_pd a
		left join #stg1_pd b
		on a.matr_type = b.matr_type
		and a.yr = b.yr + 1
		and a.month_number = b.month_number
		and a.dpd_bucket = b.dpd_bucket
		order by a.matr_type, a.dpd_bucket,  a.mon
		;



		exec dbo.prc$set_debug_info @src = @srcname, @info = 'Probabilty of Default';

		--маржинальные PD и PD для вычисления суммы ожидаемых потерь
		insert into #Probability_of_Default
		select
		a.pd_type,
		a.yr,
		a.mon,
		a.month_number,
		a.dpd_bucket,
		a.cumul_PD, 
		a.cumul_PD - isnull(c.cumul_PD,0) as margin_PD,
		a.cumul_PD - isnull(b.cumul_PD,0) as ECL_PD
		from #stg2_pd a
		left join #stg2_pd b
		on a.pd_type = b.pd_type
		and a.dpd_bucket = b.dpd_bucket
		and a.yr = b.yr + 1
		and b.month_number = 12
		left join #stg2_pd c
		on a.pd_type = c.pd_type
		and a.dpd_bucket = c.dpd_bucket
		and a.mon = c.mon + 1
		;




		drop table #stg1_pd;
		drop table #stg2_pd;

	end





	------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- PART 3 - Расчет EAD с помощью разворачивания аналитического графика
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'Annuity';

	--рассчитываем плановый и аналитический аннуитеты для 1 и 2 корзин
	drop table if exists #annuity;
	with base as (
		select a.r_date, a.external_id, 
		a.stage,
		a.dt_open_fact, 
		a.term, a.int_rate, a.eps, a.amount, a.MoB, a.principal_rest,
		RiskDWH.risk.func$annuity_pmt(a.amount, a.int_rate, a.term) as ann_pmt,
		power(1.0 + a.int_rate, 1.0 / 12.0) - 1.0 as eff_int_rate
		--a.int_rate / 12.0 as eff_int_rate
		from #FAT a
		where 1=1
		--and a.term in (3,6,9,12,24,36,48,60) 
		and a.product <> 'BUSINESS' --для отсечения ЮЛ
		and a.stage in (1,2)
		and a.principal_rest > 0
	)
	select a.r_date, a.external_id, a.stage,
	a.dt_open_fact, a.term, a.int_rate, a.eps, a.amount,
	a.MoB, a.principal_rest,
	a.ann_pmt,
	a.eff_int_rate,

	case when a.MoB = 0 then a.ann_pmt
	when (a.amount - a.principal_rest * power(1.0 + a.eff_int_rate, -1.0 * a.MoB)) *
	a.eff_int_rate * power(1.0 + a.eff_int_rate, a.MoB) / (POWER(1.0 + a.eff_int_rate, a.MoB) - 1.0) > a.ann_pmt
	then (a.amount - a.principal_rest * power(1.0 + a.eff_int_rate, -1.0 * a.MoB)) *
	a.eff_int_rate * power(1.0 + a.eff_int_rate, a.MoB) / (POWER(1.0 + a.eff_int_rate, a.MoB) - 1.0)
	else a.ann_pmt
	end as analyt_pmt

	into #annuity
	from base a
	;


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'Virt schedule';
	--разворачиваем график до полного погашения с учетом аналитического аннуитета

	drop table if exists #virtual_schedule;
	select
	0 as iteration,
	a.external_id, 
	a.stage,
	a.int_rate, /*a.eff_int_rate,*/
	a.analyt_pmt,
	a.MoB as MoB,
	cast(null as float) as od_pmt,
	cast(null as float) as interest_pmt,
	a.principal_rest

	into #virtual_schedule
	from #annuity a
	;


	drop index if exists idx_virt_sched on #virtual_schedule;
	create clustered index idx_virt_sched on #virtual_schedule (iteration);
	drop index if exists idx2_virt_sched on #virtual_schedule;
	create index idx2_virt_sched on #virtual_schedule (external_id, MoB);



	declare @iii int = 1;

	while @iii <= 100
	begin

	set @info = 'iter = '+cast(@iii as varchar(5));
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;

	insert into #virtual_schedule
	select  
	@iii as iteration,
	a.external_id, 
	a.stage,
	a.int_rate, /*a.eff_int_rate,*/
	a.analyt_pmt,
	a.MoB + 1 as MoB,
	a.analyt_pmt - a.principal_rest * a.int_rate /*a.eff_int_rate*/ / 12.0 as od_pmt,
	a.principal_rest * a.int_rate /*a.eff_int_rate*/ / 12.0 as interest_pmt,
	a.principal_rest - (a.analyt_pmt - a.principal_rest * a.int_rate /*a.eff_int_rate*/ / 12.0) as principal_rest
	from #virtual_schedule a
	where a.principal_rest > 0
	and a.iteration = @iii - 1
	;


	set @iii = @iii + 1;



	end;



	--Проверка 1: выплат по аналитическому аннуитету не хватило для погашения ОД
	select @info = count(*) 
	from #annuity a
	where not exists (select 1 from #virtual_schedule b where a.external_id = b.external_id and b.principal_rest <= 0)


	set @info = 'P3 Проверка 1: выплат по аналитическому аннуитету не хватило для погашения ОД (должно быть 0) ' + @info;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;

	--Проверка 2: платеж по ОД < 0
	select @info = count(distinct a.external_id) 
	from #virtual_schedule a
	where a.od_pmt < 0
	;

	set @info = 'P3 Проверка 2: платеж по ОД < 0 (должно быть 0) ' + @info;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;


	--Проверка 3: дубли по договорам и MoB
	select @info = count(*) from (
		select a.external_id, a.MoB
		from #virtual_schedule a
		group by a.external_id, a.MoB
		having count(*)>1
	) a 
	;


	set @info = 'P3 Проверка 3: дубли по договорам и MoB (должно быть 0) ' + @info
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;



	exec dbo.prc$set_debug_info @src = @srcname, @info = 'Year of default - months to go - month of od';

	--таблица соответствия месяц жизни - год для резерва
	drop table if exists #det_month_year;
	with a as (
		select 1 as MoB
		union all
		select MoB + 1
		from a
		where a.MoB < 100
	), b as (
		select a.MoB, floor( (cast(a.MoB as float) - 1.0) / 12.0) + 1.0 as yr
		from a
	), c as (
		select a.MoB, b.yr, max(b.MoB) - (b.yr-1) * 12 as stg_MoB
		from b as a
		left join b as b
		on a.MoB >= b.MoB
		group by a.MoB, b.yr
	)
	select a.MoB as leftover, a.yr, 
	case 
	when a.yr = 1 then RiskDWH.[CM\A.Borisov].func$greatest(RiskDWH.[CM\A.Borisov].func$least(a.stg_MoB - 3, 4), 1)
	else RiskDWH.[CM\A.Borisov].func$greatest(RiskDWH.[CM\A.Borisov].func$least(a.stg_MoB,3) + 12 * (a.yr - 1), 1)
	end as od_MoB
	into #det_month_year
	from c as a
	order by 1,2
	;



	exec dbo.prc$set_debug_info @src = @srcname, @info = 'EAD';
	--EAD
	drop table if exists #CCF;
	create table #CCF (
	external_id	varchar(100),
	months_left	int,
	yr int,
	od_MoB int,	
	principal_rest float,
	int_rate float,
	eff_int_rate float,
	eps float,
	stg_EAD	float,
	pd_disc_month int,
	stg2_EAD float
	);



	with base1 as (
		select a.external_id, min(a.iteration) as months_left
		from #virtual_schedule a
		where round(a.principal_rest,2) <= 0
		group by a.external_id
	), base2 as (
		select a.external_id, 
		a.months_left, 
		isnull(b.yr,1) as yr, --если остается 1 месяц по аналитическому графику, то ставим 1 год
		isnull(b.od_MoB,1) as od_MoB, --если остается 1 месяц по аналитическому графику, то ставим 0 MoB
		c.principal_rest, 
		c.int_rate,
		--c.principal_rest * power(1.0 + c.int_rate, 3.0 / 12.0) as stg_EAD,
		--c.principal_rest * power(1.0 + c.int_rate / 12.0, 3.0) as stg_EAD,
		c.principal_rest * (1.0 + c.int_rate / 12.0 * 3.0) as stg_EAD,
		RiskDWH.[CM\A.Borisov].func$least(b.yr * 12, a.months_left) as pd_disc_month,
		d.eps,
		d.eff_int_rate
		from base1 a
		left join #det_month_year b
		on a.months_left = b.leftover
		left join #virtual_schedule c
		on a.external_id = c.external_id
		and isnull(b.od_MoB,1) = c.iteration + 1
		left join #annuity d
		on a.external_id = d.external_id
	)
	insert into #CCF

	select a.external_id, a.months_left, a.yr, a.od_MoB,
	a.principal_rest, a.int_rate, a.eff_int_rate, a.eps,
	a.stg_EAD, a.pd_disc_month,
	--a.stg_EAD / power(1.0 + 0.15 / 12.0, a.pd_disc_month) as stg2_EAD --ставка дисконтирования = 15% (ставка привлечения)
	--a.stg_EAD / power(1.0 + a.eps / 12.0, a.pd_disc_month) as stg2_EAD --ставка дисконтирования = ЭПС
	a.stg_EAD / power(1.0 + a.eps, a.pd_disc_month / 12.0 ) as stg2_EAD --ставка дисконтирования = ЭПС, метод как в LGD
	from base2 a
	;





	--Проверка на дубли по договору и году 
	select @info = count(*) from (
		select a.external_id, a.yr
		from #CCF a
		group by a.external_id, a.yr
		having count(*)>1
	) a
	;


	set @info = 'P3 Проверка на дубли по договору и году (должно быть 0) ' + @info
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;


	--Проверка: EAD рассчитан по всем договорам
	select @info = count(*)
	from #FAT a
	where not exists (select 1 from #CCF b where a.external_id = b.external_id)
	and a.product <> 'BUSINESS'
	and a.stage <> 3
	and a.principal_rest > 0


	set @info = 'P3 Проверка: EAD рассчитан по всем договорам (должно быть 0) ' + @info;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;

	--Проверка: EAD > 0?

	select @info = count(*)
	from #CCF a
	left join #FAT b
	on a.external_id = b.external_id
	where round(a.stg2_EAD,6) <= 0.0
	and b.gross_rest > 0
	;

	set @info = 'P3 Проверка: EAD > 0? (должно быть 0) ' + @info;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;



	--EAD для 3 корзины = GROSS 

	insert into #CCF 
	(external_id, stg2_EAD)
	select a.external_id, a.gross_rest
	from #FAT a
	where a.stage = 3
	;


	--EAD для 2 корзины, 1-ый год = (GROSS + 2 месяца начисления процентов) * Дисконтирование

	update a set 
	a.stg2_EAD = ( b.gross_rest + b.principal_rest * (b.int_rate / 12.0 * 2.0)  ) / power (1.0 + b.eps, 2.0 / 12.0)
	from #CCF a
	left join #FAT b
	on a.external_id = b.external_id
	where b.stage = 2 and a.yr = 1
	; 



	------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- PART 5 - Резерв МСФО
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#stg1_provisions';

	--база 1 для расчета резерва - данные для присоединения LGD,PD,EAD
	drop table if exists #stg1_provisions;
	select 
	a.external_id,
	a.stage,
	a.dpd_bucket,
	case 
	--when a.principal_rest <= 0 and a.percents_rest <= 0 then null
	when a.stage in (1,2) then 0
	--when a.dpd > 1140 and a.dt_last_default is null then 36 
	when a.dpd > 3090 and a.dt_last_default is null then 100 
	else RiskDWH.[CM\A.Borisov].func$least( RiskDWH.[CM\A.Borisov].func$greatest( datediff(MM,a.dt_last_default,a.r_date), 0), 100)
	end as months_in_default

	into #stg1_provisions
	from #FAT a
	--where a.product not like '%бизнес%'
	;



	--Проверка 2: максимальное и минимальное кол-во месяцев в дефолте по корзинам
	select @info = concat(a.stage, ' ',min(a.months_in_default),' ', max(a.months_in_default)) from #stg1_provisions a where a.stage = 1 group by a.stage;
	set @info = 'P5 Проверка 2: максимальное и минимальное кол-во месяцев в дефолте по корзинам, 1 ' + @info
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;


	select @info = concat(a.stage, ' ',min(a.months_in_default),' ', max(a.months_in_default)) from #stg1_provisions a where a.stage = 2 group by a.stage;
	set @info = 'P5 Проверка 2: максимальное и минимальное кол-во месяцев в дефолте по корзинам, 2 ' + @info;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;


	select @info = concat(a.stage, ' ',min(a.months_in_default),' ', max(a.months_in_default)) from #stg1_provisions a where a.stage = 3 group by a.stage;
	set @info = 'P5 Проверка 2: максимальное и минимальное кол-во месяцев в дефолте по корзинам, 3 ' + @info;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;


	exec dbo.prc$set_debug_info @src = @srcname, @info = '#stg2_provisions';


	--база 2 для расчета резерва - присоединение LGD,PD,EAD
	drop table if exists #stg2_provisions;
	select 
	a.external_id, 
	a.stage,
	b.months_left,
	b.yr,
	b.stg2_EAD,
	case when a.stage = 3 then cast(1.0 as float) else d.ECL_PD  end as PD_TTC,
	case when a.stage = 3 then cast(1.0 as float) else dd.ECL_PD end as PD_PIT

	into #stg2_provisions
	from #stg1_provisions a

	left join #CCF b
	on a.external_id = b.external_id

	left join #Probability_of_Default d
	on b.pd_disc_month = d.mon
	and a.dpd_bucket = d.dpd_bucket
	and d.pd_type = 'TTC'

	left join #Probability_of_Default dd
	on b.pd_disc_month = dd.mon
	and a.dpd_bucket = dd.dpd_bucket
	and dd.pd_type = 'PIT'
	;




	--Проверка 1: пустой год только в 3 корзине

	select @info = count(*) 
	from (
		select
		distinct a.stage 
		from #stg2_provisions a
		left join #FAT b
		on a.external_id = b.external_id
		where a.yr is null
		and b.principal_rest > 0
		and b.product <> 'BUSINESS'
	) a
	where a.stage <> 3
	;

	set @info = 'P5 Проверка 1: пустой год только в 3 корзине (должно быть 0) ' + @info;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;



	--Проверка 2: осутствие любого компонента
	select @info = count(*)
	from #stg2_provisions a
	left join #FAT b
	on a.external_id = b.external_id
	where (a.stg2_EAD is null or a.PD_PIT is null or a.PD_TTC is null)
	and b.principal_rest > 0
	and b.product <> 'BUSINESS'
	;


	set @info = 'P5 Проверка 2: осутствие любого компонента (должно быть 0) ' + @info;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;


	--Проверка 3: каждый компонент больше нуля
	select @info = count(*) 
	from #stg2_provisions a
	left join #FAT b
	on a.external_id = b.external_id
	where (a.stg2_EAD <= 0 or a.PD_PIT <= 0 or a.PD_TTC <= 0)
	and b.principal_rest > 0
	and b.product <> 'BUSINESS'
	;


	set @info = 'P5 Проверка 3: каждый компонент больше нуля (должно быть 0) ' + @info;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;


	--Проверка 4: дубли по договору, году жизни
	select @info =count(*) from (
		select a.external_id, a.yr
		from #stg2_provisions a
		group by a.external_id, a.yr
		having count(*)>1
	) a
	;

	set @info = 'P5 Проверка 4: дубли по договору, году жизни (должно быть 0) ' + @info;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;

	--Проверка 5: для 3-ей корзины должна быть только одна строка
	select @info = count(*) from (
		select a.external_id
		from #stg2_provisions a
		where a.stage = 3
		group by a.external_id
		having count(*)>1
	) a
	;

	set @info = 'P5 Проверка 5: для 3-ей корзины должна быть только одна строка (должно быть 0) ' + @info;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @info;



	exec dbo.prc$set_debug_info @src = @srcname, @info = '#stg31_provisions';

	--Резервы согласно корзине
	drop table if exists #stg31_provisions;
	select a.external_id, a.stage, a.months_left,
	sum(a.stg2_EAD) as EAD,
	sum(a.stg2_EAD * a.PD_PIT) as EAD_PD
	into #stg31_provisions
	from #stg2_provisions a
	where not (a.stage = 1 and a.yr > 1)
	group by a.external_id, a.stage, a.months_left
	;





	exec dbo.prc$set_debug_info @src = @srcname, @info = 'insert into vitr';


	begin transaction

	delete from risk.IFRS9_vitr where r_date = @rdt and vers = @vers;
	insert into risk.IFRS9_vitr
	select 
	a.r_date,  
	@vers as vers,
	cast(getdate() as datetime) as dt_dml,
	a.external_id,

	a.dt_open_fact, --
	a.MoB, --
	a.term, --
	a.int_rate, --
	a.eps, --
	a.amount, --

	a.principal_rest,
	a.percents_rest,
	a.others_rest,
	a.gross_rest as gross,
	a.dpd,
	a.dpd_bucket,
	RiskDWH.dbo.get_bucket_720_m(a.dpd) as bucket_720,
	------------------------------
	a.product,
	a.dt_last_default,
	a.flag_default_6m,
	a.flag_default_12m,
	a.flag_bankrupt,
	a.flag_restruct,
	a.dt_restruct,
	a.flag_kk,
	------------------------------
	a.stage,
	d.months_left,
	b.months_in_default,
	null as LGD,
	d.EAD,

	null as PD_TTC,
	null as PD_TTC_LT,

	case when d.EAD = 0 then null else d.EAD_PD / d.EAD end as PD_PIT,
	null as PD_PIT_LT,

	null as prov_IFRS_TTC, 
	null as prov_IFRS_TTC_LT,
	null as prov_IFRS_PIT,
	null as prov_IFRS_PIT_LT

	from #FAT a
	left join #stg1_provisions b
	on a.external_id = b.external_id
	left join #stg31_provisions d
	on a.external_id = d.external_id

	;



	--Заливка промежуточных расчетов в таблицы


	delete from risk.stg_IFRS9_thin where r_date = @rdt and vers = @vers;
	insert into risk.stg_IFRS9_thin
	select 
	@rdt as r_date,
	@vers as vers,
	cast(getdate() as datetime) as dt_dml,
	a.r_date as date_on,
	a.external_id,
	a.dpd,
	a.dpd_bucket,
	a.dpd_analyt,
	a.dpd_bucket_analyt
	from #THIN a
	;


	if @rdt = @pd_dt begin

		delete from risk.stg_IFRS9_TTC_matrix where r_date = @rdt and vers = @vers;
		insert into risk.stg_IFRS9_TTC_matrix
		select 
		@rdt as r_date,
		@vers as vers,
		cast(getdate() as datetime) as dt_dml,
		a.yr, a.dpd_bucket_from, a.dpd_bucket_to, a.koef 
		from #TTC_matrix a
		;


		delete from risk.stg_IFRS9_PIT_matrix where r_date = @rdt and vers = @vers;
		insert into risk.stg_IFRS9_PIT_matrix
		select 
		@rdt as r_date,
		@vers as vers,
		cast(getdate() as datetime) as dt_dml,
		a.yr, a.dpd_bucket_from, a.dpd_bucket_to, a.koef 
		from #PIT_matrix a
		;

		delete from risk.stg_IFRS9_pd_adjust where r_date = @rdt and vers = @vers;
		insert into risk.stg_IFRS9_pd_adjust
		select 
		@rdt as r_date,
		@vers as vers,
		cast(getdate() as datetime) as dt_dml,
		a.mark, a.val 
		from #pd_adjust a
		;

	end


	delete from risk.stg_IFRS9_PD where r_date = @rdt and vers = @vers;
	insert into risk.stg_IFRS9_PD
	select 
	@rdt as r_date,
	@vers as vers,
	cast(getdate() as datetime) as dt_dml,
	a.pd_type,
	a.yr,
	a.mon,
	a.dpd_bucket,
	a.margin_PD
	from #Probability_of_Default a
	;


	/*
	delete from risk.stg_IFRS9_LGD where r_date = @rdt and vers = @vers;
	insert into risk.stg_IFRS9_LGD
	select
	@rdt as r_date,
	@vers as vers,
	cast(getdate() as datetime) as dt_dml,
	a.t,
	a.recov,
	a.lgd
	from #Loss_Given_Default a
	*/


	delete from risk.stg_IFRS9_virt_schedule where r_date = @rdt and vers = @vers;
	insert into risk.stg_IFRS9_virt_schedule
	select 
	@rdt as r_date,
	@vers as vers,
	cast(getdate() as datetime) as dt_dml,
	a.iteration, a.external_id, a.stage, a.int_rate, a.analyt_pmt, a.MoB, a.od_pmt, a.interest_pmt, a.principal_rest 
	from #virtual_schedule a
	;

	delete from risk.stg_IFRS9_CCF where r_date = @rdt and vers = @vers;
	insert into risk.stg_IFRS9_CCF
	select 
	@rdt as r_date,
	@vers as vers,
	cast(getdate() as datetime) as dt_dml,
	a.external_id, a.months_left, a.yr,	a.od_MoB, a.principal_rest, a.int_rate, a.eff_int_rate, a.stg_EAD, a.pd_disc_month, a.stg2_EAD
	from #CCF a
	;


	commit transaction;



	exec dbo.prc$set_debug_info @src = @srcname, @info = 'drop tmp (#) tables';


	drop table #annuity;
	drop table #CCF;
	drop table #CMR;
	drop table #credit_vacations;
	drop table #det_month_year;
	drop table #FAT;	
	drop table #Probability_of_Default;
	drop table #stg_KP_restr;
	drop table #stg1_provisions;
	drop table #stg2_provisions;
	drop table #stg31_provisions;
	drop table #THIN;	
	drop table #virtual_schedule;


	if @rdt = @pd_dt begin

		drop table #pd_adjust;
		drop table #TTC_matrix;
		drop table #PIT_matrix;

	end


	exec dbo.prc$set_debug_info @src = @srcname, @info = 'FINISH';

end try


begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch
