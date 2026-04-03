/******************************************************************************************************
Расчет резервов МСФО9 для PDL

Временно, пока не вызреет хотя бы 1 год, нужны PD в таблице:
risk.stg_IFRS9_PDL_PD

Revisions:
dt			user				version		description
03/10/24	datsyplakov			v1.0		Создание процедуры

*****************************************************************************************************/

CREATE procedure [Risk].[prc$calc_IFRS9_PDL] @rdt date as 

declare @src_name varchar(100) = 'IFRS9 PDL'
declare @info varchar(1000);
declare @vers int;

begin try


	select @vers = isnull(max(a.vers),0) + 1 from risk.IFRS9_vitr a where a.r_date = @rdt;
	set @info = concat('START rdt ' ,format(@rdt,'dd.MM.yyyy'),' vers ',format(@vers,'###'));
	exec dbo.prc$set_debug_info @src = @src_name, @info = @info;


	declare @pd_check int = 0;
	select @pd_check = iif(count(*)=0,0,1) from risk.stg_IFRS9_PDL_PD a where a.r_date = @rdt;

	if @pd_check = 0 begin

	set @info = concat('THERE IS NO DATA IN stg_IFRS9_PDL_PD for ',format(@rdt,'dd.MM.yyyy') )
	exec dbo.prc$set_debug_info @src = @src_name, @info = @info;

	end

	if @pd_check = 1 begin 

		------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- PART 1 - Подготовка исходных данных
		------------------------------------------------------------------------------------------------------------------------------------------------------------------------


		exec dbo.prc$set_debug_info @src = @src_name, @info = '#credit_vacations';

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


		exec dbo.prc$set_debug_info @src = @src_name, @info = '#CMR';

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
		where a.d >= '2018-01-01'
		and a.d <= @rdt
		and b.IsInstallment = 1
		;


		drop index if exists idx_cmr on #CMR;
		create clustered index idx_cmr on #CMR (external_id, r_date);

		drop table #credit_vacations;





		exec dbo.prc$set_debug_info @src = @src_name, @info = '#THIN';


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
		;



		exec dbo.prc$set_debug_info @src = @src_name, @info = '#bankrupt';
		--Банкроты

		drop table if exists #stg_bankrupt;
		select a.Контрагент as contragent,
		min(cast(dateadd(yy,-2000,a.дата) as date)) as dt
		into #stg_bankrupt
		from [c2-vsr-sql04].[UMFO].[dbo].[Документ_АЭ_БанкротствоЗаемщика] a
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


		exec dbo.prc$set_debug_info @src = @src_name, @info = '#stg_default';

		--Дата последнего входа в дефолт и флаги дефолта за посл 6 и 12 мес
		---!!! поменять потом ЦМР на КП от финансов
		drop table if exists #stg_default;
		select a.external_id, 
		case when max(case when a.r_date between EOMONTH(b.r_date,-6) and b.r_date then a.dpd else 0 end) > 90 then 1 else 0 end as flag_default_6m,
		case when max(case when a.r_date between EOMONTH(b.r_date,-12) and b.r_date then a.dpd else 0 end) > 90 then 1 else 0 end as flag_default_12m,
		max(case when a.dpd = 91 then a.r_date end) as dt_last_default
		into #stg_default
		from #CMR a
		inner join dwh2.risk.REG_REPORT_KP_FOR_CBR b
		on a.external_id = b.external_id
		and b.r_date = @rdt
		where 1=1
		and a.r_date <= b.r_date
		group by a.external_id
		;



		exec dbo.prc$set_debug_info @src = @src_name, @info = 'EPS';

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


		select b.НомерДоговора as external_id, 
		c.период as период, 
		c.активность as активность, 
		c.эффективнаяставкапроцента as эффективнаяставкапроцента
		into #stg2_eps

		from stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный b
		left join [c2-vsr-sql04].[UMFO].[dbo].[РегистрСведений_АЭ_АктуальныеГрафикиПлатежейЗаймовПредоставленных] c
		on b.Ссылка = c.займ

		;



		drop table if exists #eps;
		with base as (
		select a.*, ROW_NUMBER() over (partition by a.external_id order by a.Период desc) as rown
		from #stg2_eps a
		where a.эффективнаяставкапроцента > 0
		and dateadd(yy,-2000,cast(a.период as date)) <= @rdt 
		)
		select a.external_id, a.эффективнаяставкапроцента / 100.0 as eps
		into #eps
		from base a
		where a.rown = 1
		;


		drop table if exists #avg_eps_gen;
		select 
		a.generation, 
		sum(a.amount * a.eps) / sum(a.amount) as eps
		into #avg_eps_gen
		from #stg_eps a
		group by a.generation
		;


		drop table if exists #avg_eps;
		select 
		sum(a.amount * a.eps) / sum(a.amount) as eps
		into #avg_eps
		from #stg_eps a
		;




		exec dbo.prc$set_debug_info @src = @src_name, @info = 'restruct';
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






		exec dbo.prc$set_debug_info @src = @src_name, @info = '#FAT';

		--Последний фактический срез - основа для EAD
		drop table if exists #FAT;
		with base as (
			select DISTINCT 
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
			--isnull(a.[Срок договора в месяцах],b.term) as term,
			b.PDLTerm as term,
			a.dpd_prov as dpd,
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
			case when b.kk_dt_from is not null then 1 else 0 end as flag_kk

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
	
			where a.r_date = @rdt
			--and isnull(a.product_group,'n') in ('Installment','Smartinstallment')
			and (
				--isnull(a.[Финансовый продукт],'n') like '%ПРО100%' --
				isnull(a.[Финансовый продукт],'n') = 'PDL' --pdl отдельно
				or a.external_id = '24082222363672'
				)
			--and a.principal_rest > 0
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
		when a.product = 'PDL' then 'PDL'
		else 'PTS' end as product,
		a.flag_restruct,
		a.dt_restruct,
		a.flag_default_6m,
		a.flag_default_12m,
		a.dt_last_default,
		a.flag_bankrupt,
		a.flag_kk,

		case 
		--3 корзина: dpd > 90 ИЛИ был дефолт за посл 6 месяцев ИЛИ была реструкт за посл 3 месяца ИЛИ Банкрот
		when a.dpd > 90 
			or a.flag_default_6m = 1
			or (a.flag_restruct = 1 and datediff(MM,a.dt_restruct,a.r_date) between 0 and 2) 
			or a.flag_bankrupt = 1
		then 3
		--2 корзина: 31 <= dpd < 90 ИЛИ был дефолт за посл 12 месяцев и не прошло больше 6 мес ИЛИ была реструкт за посл 6 месяцев и не прошло более 3 мес
		when a.dpd between 31 and 90
			or (a.flag_default_12m = 1 and a.flag_default_6m = 0)
			or (a.flag_restruct = 1 and datediff(MM,a.dt_restruct,a.r_date) between 3 and 5)
		then 2
		--1 корзина: dpd <= 30 ИЛИ была реструкт и прошло более 6 мес
		when a.dpd <= 30
			or (a.flag_restruct = 1 and datediff(MM,a.dt_restruct,a.r_date) >= 6)
		then 1
		end as stage

		into #FAT
		from base a
		left join #avg_eps_gen b
		on a.generation = b.generation
		left join #avg_eps c
		on 1 = 1
		left join #eps d
		on a.external_id = d.external_id
		;





		--select a.stage, count(*) from #FAT a group by a.stage order by 1;




		--Проверка: остаток ОД > сумма выдачи

		select @info = concat('P1 Проверка: остаток ОД > сумма выдачи (должно быть 0) ',count(*))
		from #FAT a
		where a.principal_rest > a.amount 
		;
		exec dbo.prc$set_debug_info @src = @src_name, @info = @info;

		--Проверка: дубли по договорам и отчетным датам
		select @info = concat('P1 Проверка: дубли по договорам и отчетным датам FAT (должно быть 0) ',count(*))
		from (
			select a.external_id, a.r_date
			from #FAT a
			group by a.external_id, a.r_date
			having count(*)>1
		) a
		;
		exec dbo.prc$set_debug_info @src = @src_name, @info = @info;


		--Проверка: дубли по договор-отчетная дата
		select @info = concat('P1 Проверка: дубли по договор-отчетная дата THIN (должно быть 0) ',count(*)) 
		from (
			select a.external_id, a.r_date
			from #THIN a
			group by a.external_id, a.r_date
			having count(*)>1
		) a
		;
		exec dbo.prc$set_debug_info @src = @src_name, @info = @info;

		--Проверка: ГРОСС = ОД+%%+прочее
		select @info = concat('P1 Проверка: ГРОСС = ОД+%%+прочее (должно быть 0) ',count(*))
		from #FAT a
		where a.principal_rest + a.percents_rest + a.others_rest <> a.gross_rest
		;
		exec dbo.prc$set_debug_info @src = @src_name, @info = @info;


		--Проверка: Пустой ЭПС
		select @info = concat('P1 Проверка: Пустой ЭПС (должно быть 0) ',count(*))
		from #FAT a
		where a.eps is null
		;
		exec dbo.prc$set_debug_info @src = @src_name, @info = @info;




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
		drop table #CMR;


		------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- PART 2 - Расчет PD (TTC & PIT) на основе матриц миграций
		------------------------------------------------------------------------------------------------------------------------------------------------------------------------


		exec dbo.prc$set_debug_info @src = @src_name, @info = '#Probability_of_Default';

		--!!! Пока не вызрел хотя бы 1 год, PD считаем по ролл-рейтам от инстоллментов
		drop table if exists #Probability_of_Default;
		select a.dpd_bucket_90, a.ECL_PD
		into #Probability_of_Default
		from risk.stg_IFRS9_PDL_PD a
		where a.r_date = @rdt
		;

		------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- PART 3 - Расчет EAD с помощью разворачивания аналитического графика
		------------------------------------------------------------------------------------------------------------------------------------------------------------------------


		exec dbo.prc$set_debug_info @src = @src_name, @info = '#CCF';

		--Для PDL EAD = OD, предполагается, что сначала начисляется 3 %% платежа, а потом дисконтируется на 3 месяца, то есть остается только ОД

		drop table if exists #CCF;

		create table #CCF (
		external_id varchar(100), 
		months_left int, 
		yr int,	
		od_MoB float, 
		principal_rest float, 
		int_rate float, 
		eff_int_rate float,  
		stg_EAD float, 
		pd_disc_month float, 
		stg2_EAD float
		)
		;


		insert into #CCF (external_id, stg2_EAD) 
		select a.external_id, 
		case 
		when a.stage in (1,2) then a.gross_rest --a.principal_rest
		when a.stage = 3 then a.gross_rest
		end as stg2_EAD
		from #FAT a

		;



		------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- PART 4 - Расчет LGD (собирается в отдельной процедуре)
		------------------------------------------------------------------------------------------------------------------------------------------------------------------------


		exec dbo.prc$set_debug_info @src = @src_name, @info = '#Loss_Given_Default';

		----для беззалога - экспертные значения
		drop table if exists #Loss_Given_Default;
		select 
		a.months_in_default - 1 as t,
		a.recovery_rate_disc as recov,
		0 as writeoff,
		a.LGD_disc as lgd
		into #Loss_Given_Default
		from risk.lgd_gross_cond a
		where a.r_date = '2023-10-31' -- Экспертно
		and a.product = 'INSTALLMENT'
		;
	
		--дополняем до 36 месяцев со значением LGD = 1

		declare @mx_lgd_mob int;

		select @mx_lgd_mob = max(t) from #Loss_Given_Default;


		while @mx_lgd_mob < 36
		begin 

		insert into #Loss_Given_Default (t, recov, writeoff, lgd) values(@mx_lgd_mob + 1, 0.0, 0.0, 1.0);

		set @mx_lgd_mob = @mx_lgd_mob + 1;

		end
		;



		------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- PART 5 - Резерв МСФО
		------------------------------------------------------------------------------------------------------------------------------------------------------------------------

		exec dbo.prc$set_debug_info @src = @src_name, @info = '#stg1_provisions';

		--база 1 для расчета резерва - данные для присоединения LGD,PD,EAD
		drop table if exists #stg1_provisions;
		select 
		a.external_id,
		a.stage,
		a.dpd_bucket,
		case 
		when a.principal_rest <= 0 then null
		when a.stage in (1,2) then 0
		when a.dpd > 1140 and a.dt_last_default is null then 36 
		else RiskDWH.[CM\A.Borisov].func$least( RiskDWH.[CM\A.Borisov].func$greatest( datediff(MM,a.dt_last_default,a.r_date), 0), 36)
		end as months_in_default

		into #stg1_provisions
		from #FAT a
		--where a.product not like '%бизнес%'
		;



		--Проверка 2: максимальное и минимальное кол-во месяцев в дефолте по корзинам
		select @info = concat('P5 Проверка 2: максимальное и минимальное кол-во месяцев в дефолте по корзинам, 1 ',
								a.stage, ' ',min(a.months_in_default),' ', max(a.months_in_default)) from #stg1_provisions a where a.stage = 1 group by a.stage;
		exec dbo.prc$set_debug_info @src = @src_name, @info = @info;
		select @info = concat('P5 Проверка 2: максимальное и минимальное кол-во месяцев в дефолте по корзинам, 2 ',
								a.stage, ' ',min(a.months_in_default),' ', max(a.months_in_default)) from #stg1_provisions a where a.stage = 2 group by a.stage;
		exec dbo.prc$set_debug_info @src = @src_name, @info = @info;
		select @info = concat('P5 Проверка 2: максимальное и минимальное кол-во месяцев в дефолте по корзинам, 3 ',
								a.stage, ' ',min(a.months_in_default),' ', max(a.months_in_default)) from #stg1_provisions a where a.stage = 3 group by a.stage;
		exec dbo.prc$set_debug_info @src = @src_name, @info = @info;



		exec dbo.prc$set_debug_info @src = @src_name, @info = '#stg2_provisions';

		--база 2 для расчета резерва - присоединение LGD,PD,EAD
		drop table if exists #stg2_provisions;
		select 
		a.external_id, 
		a.stage,
		b.months_left,
		isnull(b.yr,1) as yr,
		b.stg2_EAD,
		case when a.stage = 3 then cast(1.0 as float) else d.ECL_PD  end as PD_TTC,
		case when a.stage = 3 then cast(1.0 as float) else dd.ECL_PD end as PD_PIT,
		c.lgd as LGD

		into #stg2_provisions
		from #stg1_provisions a

		left join #CCF b
		on a.external_id = b.external_id

		left join #Loss_Given_Default c
		on a.months_in_default = c.t

		left join #Probability_of_Default d
		on a.dpd_bucket = d.dpd_bucket_90

		left join #Probability_of_Default dd
		on a.dpd_bucket = dd.dpd_bucket_90




		--Проверка 1: пустой год только в 3 корзине

		select @info = concat('P5 Проверка 1: пустой год только в 3 корзине (должно быть 0) ',count(*))
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
		exec dbo.prc$set_debug_info @src = @src_name, @info = @info;


		--Проверка 2: осутствие любого компонента
		select @info = concat('P5 Проверка 2: осутствие любого компонента (должно быть 0) ',count(*))
		from #stg2_provisions a
		left join #FAT b
		on a.external_id = b.external_id
		where (a.stg2_EAD is null or a.PD_PIT is null or a.PD_TTC is null or a.LGD is null)
		and b.principal_rest > 0
		and b.product <> 'BUSINESS'
		;
		exec dbo.prc$set_debug_info @src = @src_name, @info = @info;
	


		--Проверка 3: каждый компонент больше нуля
		select @info = concat('P5 Проверка 3: каждый компонент больше нуля (должно быть 0) ',count(*))
		from #stg2_provisions a
		left join #FAT b
		on a.external_id = b.external_id
		where (a.stg2_EAD <= 0 or a.PD_PIT <= 0 or a.PD_TTC <= 0 or a.LGD <= 0)
		and b.principal_rest > 0
		and b.product <> 'BUSINESS'
		;
		exec dbo.prc$set_debug_info @src = @src_name, @info = @info;


		--Проверка 4: дубли по договору, году жизни
		select @info = concat('P5 Проверка 4: дубли по договору, году жизни (должно быть 0) ',count(*))
		from (
			select a.external_id, a.yr
			from #stg2_provisions a
			group by a.external_id, a.yr
			having count(*)>1
		) a
		;
		exec dbo.prc$set_debug_info @src = @src_name, @info = @info;

		--Проверка 5: для 3-ей корзины должна быть только одна строка
		select @info = concat('P5 Проверка 5: для 3-ей корзины должна быть только одна строка (должно быть 0) ',count(*))
		from (
			select a.external_id
			from #stg2_provisions a
			where a.stage = 3
			group by a.external_id
			having count(*)>1
		) a
		;
		exec dbo.prc$set_debug_info @src = @src_name, @info = @info;



		exec dbo.prc$set_debug_info @src = @src_name, @info = '#stg31_provisions';

		--Резервы согласно корзине
		drop table if exists #stg31_provisions;
		select a.external_id, a.stage, a.months_left,
		sum(a.stg2_EAD) as EAD,
		sum(a.stg2_EAD * a.PD_TTC * a.LGD) as prov_TTC,
		sum(a.stg2_EAD * a.PD_PIT * a.LGD) as prov_PIT 
		into #stg31_provisions
		from #stg2_provisions a
		where not (a.stage = 1 and a.yr > 1)
		group by a.external_id, a.stage, a.months_left
		;


		exec dbo.prc$set_debug_info @src = @src_name, @info = '#stg32_provisions';

		--Резервы Lifetime (1 корзина = 2 корзина)
		drop table if exists #stg32_provisions;
		select a.external_id, a.stage, a.months_left,
		sum(a.stg2_EAD) as EAD,
		sum(a.stg2_EAD * a.PD_TTC * a.LGD) as prov_TTC,
		sum(a.stg2_EAD * a.PD_PIT * a.LGD) as prov_PIT 
		into #stg32_provisions
		from #stg2_provisions a
		group by a.external_id, a.stage, a.months_left
		;



		--------------------------------------------------------------------------------------------------------------------------------------------------------
		--------------------------------------------------------------------------------------------------------------------------------------------------------



		exec dbo.prc$set_debug_info @src = @src_name, @info = 'insert into VITR';

		begin transaction;


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
			c.lgd as LGD,
			d.EAD,

			case when c.lgd = 0 or d.EAD = 0 then null else d.prov_TTC / c.lgd / d.EAD end as PD_TTC,
			case when c.lgd = 0 or d.EAD = 0 then null else e.prov_TTC / c.lgd / d.EAD end as PD_TTC_LT,

			case when c.lgd = 0 or d.EAD = 0 then null else d.prov_PIT / c.lgd / d.EAD end as PD_PIT,
			case when c.lgd = 0 or d.EAD = 0 then null else e.prov_PIT / c.lgd / d.EAD end as PD_PIT_LT,

			case when a.principal_rest = 0 and a.gross_rest > 0 then a.gross_rest else d.prov_TTC end as prov_IFRS_TTC,
			case when a.principal_rest = 0 and a.gross_rest > 0 then a.gross_rest else e.prov_TTC end as prov_IFRS_TTC_LT,

			case when a.principal_rest = 0 and a.gross_rest > 0 then a.gross_rest else d.prov_PIT end as prov_IFRS_PIT,
			case when a.principal_rest = 0 and a.gross_rest > 0 then a.gross_rest else e.prov_PIT end as prov_IFRS_PIT_LT

			from #FAT a
			left join #stg1_provisions b
			on a.external_id = b.external_id
			left join #Loss_Given_Default c
			on b.months_in_default = c.t
			left join #stg31_provisions d
			on a.external_id = d.external_id
			left join #stg32_provisions e
			on a.external_id = e.external_id

			--where a.product not like '%Бизнес%'
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


			/*
			delete from risk.stg_IFRS9_TTC_matrix where r_date = @rdt and vers = @vers;
			insert into risk.stg_IFRS9_TTC_matrix
			select 
			@rdt as r_date,
			@vers as vers,
			cast(getdate() as datetime) as dt_dml,
			a.yr, a.dpd_bucket_from, a.dpd_bucket_to, a.koef 
			from #TTC_matrix a
			;
			*/

			/*
			delete from risk.stg_IFRS9_PIT_matrix where r_date = @rdt and vers = @vers;
			insert into risk.stg_IFRS9_PIT_matrix
			select 
			@rdt as r_date,
			@vers as vers,
			cast(getdate() as datetime) as dt_dml,
			a.yr, a.dpd_bucket_from, a.dpd_bucket_to, a.koef 
			from #PIT_matrix a
			;
			*/


			/*
			delete from risk.stg_IFRS9_pd_adjust where r_date = @rdt and vers = @vers;
			insert into risk.stg_IFRS9_pd_adjust
			select 
			@rdt as r_date,
			@vers as vers,
			cast(getdate() as datetime) as dt_dml,
			a.mark, a.val 
			from #pd_adjust a
			;
			*/


			/*
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
			*/


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
			;


			/*
			delete from risk.stg_IFRS9_virt_schedule where r_date = @rdt and vers = @vers;
			insert into risk.stg_IFRS9_virt_schedule
			select 
			@rdt as r_date,
			@vers as vers,
			cast(getdate() as datetime) as dt_dml,
			a.iteration, a.external_id, a.stage, a.int_rate, a.analyt_pmt, a.MoB, a.od_pmt, a.interest_pmt, a.principal_rest 
			from #virtual_schedule a
			;
			*/



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


		exec dbo.prc$set_debug_info @src = @src_name, @info = 'drop temp (#) tables';

		drop table #CCF;
		drop table #FAT;
		drop table #Loss_Given_Default;
		drop table #Probability_of_Default;
		drop table #stg1_provisions;
		drop table #stg2_provisions;
		drop table #stg31_provisions;
		drop table #stg32_provisions;
		drop table #THIN;			

	end

	exec dbo.prc$set_debug_info @src = @src_name, @info = 'FINISH';

end try



begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @src_name ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch