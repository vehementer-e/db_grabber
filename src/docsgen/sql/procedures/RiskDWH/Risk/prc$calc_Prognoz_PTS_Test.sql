


/**************************************************************************
Скрипт в агент SQL для расчёта прогноза

Revisions:
dt			user				version		description
31/10/2025	golicyn				v1.0		Создание процедуры


*************************************************************************/

CREATE procedure [Risk].[prc$calc_Prognoz_PTS_Test]

@rdt date = null,
@repeat_share float = 0.62,
@bu_disc_bz float = 0.054,
@bu_disc float = 5.4,


--Распределение ПДН для новых выдач
@MPL_PDN_R1 float = 0.8,	-- для ПДН 0-50%
@MPL_PDN_R2 float = 0.15,	-- для ПДН 51-80%

---------------- МЕНЯТЬ: У каждого прогноза продукта-канала своя версия
@vers int = 681,
---------------- МЕНЯТЬ: У каждого продукта-канала своя ставка
@avg_rate float = 80.0,
---------------- МЕНЯТЬ: Ставим нужную версию LGD
@LGD_vers int = 2,
-- Дальний горизонт прогноза. Обычно ставим на 6 лет
@for_finance_dt_to date = '2031-12-31',
-- Информационные логи
@vinfo_start varchar(256) = 'PTS Test Start',
@vinfo_finish varchar(256) = 'PTS Test Finish'

AS

begin try

	declare @srcname varchar(100) = 'SQL Agent. Risk Forecast';

	declare @vinfo varchar(1000) = @vinfo_start
									;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;


	--------------------------------------------------------------------------------------------------------
	--	isnull(adj.coef * case when year(a.mob_date_to) = 2025 then 0.9 else 1 end, 1)
	--	ставки и дисконты для БУ в 2025 году
		--set provision rates
		/*
		case when a.dpd_bucket = '[01] 0' then 0.0203
			when a.dpd_bucket = '[02] 1-30' then 0.0476
			when a.dpd_bucket = '[03] 31-60' then 0.1233
			when a.dpd_bucket = '[04] 61-90' then 0.1359 else 0 end
		*/
	--	подбираем ставки
	--	Ставки для виртуальных поколений (берем по файлу от коммблока. Цифра всегда похожа на ближайший факт)
	--	виртуальные поколения для плановых выдач

	--------------------------------------------------------------------------------------------------------

	declare @dt_back_test_from date = eomonth(@rdt, 1);
	declare @horizon int = 0;
	set @horizon = datediff(MM, @rdt,@for_finance_dt_to) + 1;

	------------------------------------------------------------------------------------------------------------
	------ PART 0 - Справочник для разделения на каналы ПСБ, Infoseti
	------------------------------------------------------------------------------------------------------------


	drop table if exists Temp_PTS_Test_Channel

	;

	select --
		Номер as external_id
		, case when productType='PTS' and source like 'psb%' then 'PTS_PSB'
				when productType='PTS' and source like 'infoseti%' then 'PTS_Infoseti'
				when productType='PTS' and source like 'tpokupki%' then 'PTS_TBank' 
				when productType='AUTOCREDIT' and source like 'tpokupki%' then 'AC_TBank'
				when productType='AUTOCREDIT' and source not like 'tpokupki%' then 'AC_CM' end
		as Product_Channel
		, count(*) as cnt
	into Temp_PTS_Test_Channel--select top 100 *
	from analytics.dbo.v_fa f where 1 = 1
		and ПризнакЗайм = 1
		and YEAR(issuedMonth) >= 2025
		and productType='PTS'
	group by
		Номер
		, case when productType='PTS' and source like 'psb%' then 'PTS_PSB'
				when productType='PTS' and source like 'infoseti%' then 'PTS_Infoseti'
				when productType='PTS' and source like 'tpokupki%' then 'PTS_TBank' 
				when productType='AUTOCREDIT' and source like 'tpokupki%' then 'AC_TBank'
				when productType='AUTOCREDIT' and source not like 'tpokupki%' then 'AC_CM' end
	order by cnt desc
	;

	--select Product_Channel, count(*) as cnt
	--from Temp_PTS_Test_Channel
	--group by Product_Channel

	--;

	--------------------------------------------------------------------------------------------------------
	-- PART 1 - формирование реестра договоров, расчет баланса на даты 
	--------------------------------------------------------------------------------------------------------


	print ('timing, start ' + format(getdate(), 'HH:mm:ss'));


	--слепок ЦМР для ускорения и сокращения кол-ва обращений к таблице


	drop table if exists Temp_PTS_Test_CMR_M;
	select a.external_id, a.d, a.[остаток од], a.dpd 
	into Temp_PTS_Test_CMR_M
	--from dwh2.dbo.dm_cmrstatbalance a (nolock)
	from risk.stg_fcst_CMR_lite a
	where a.d = eomonth(a.d)
	and a.d <= @rdt
	and a.d >= '2016-01-01'
	;





	update a set a.[остаток од] = 0
	--select *
	from Temp_PTS_Test_CMR_M a
	where a.[остаток од] < 0
	;

	--итоговый список списаний
	drop table if exists Temp_PTS_Test_stg_write_off;

	select b.external_id, b.r_date, b.od_wo, b.int_wo
	into Temp_PTS_Test_stg_write_off
	from RiskDWH.Risk.stg_fcst_writeoff b
	where b.r_date <= @rdt
	;



	print ('timing, Temp_PTS_Test_stg_write_off ' + format(getdate(), 'HH:mm:ss'));


	--Актуальные ставка и дата окончания
	----declare @rdt date = '2024-10-31';



	drop table if exists Temp_PTS_Test_det_current_params;
	with base as (
		select a.external_id, 
		a.[Ставка на дату формирования отчета] as cur_rate,
		convert(date,a.[Дата погашения с учетом ДС],104) as cur_plan_end_date,
		ROW_NUMBER() over (partition by a.external_id order by a.r_date desc) as rn
		from dwh2.risk.REG_REPORT_KP_FOR_CBR a
		where a.r_date <= @rdt
	
	)
	select a.external_id, a.cur_rate, a.cur_plan_end_date
	into Temp_PTS_Test_det_current_params
	from base a
	where a.rn = 1
	;



	with base as (
		select 
		cast(b.Код as varchar(100)) as external_id,
		dateadd(yy,-2000,cast(ДатаОкончания as date)) as cur_plan_end_date,  
		cast(a.ПроцентнаяСтавка as float) as cur_rate,
		ROW_NUMBER() over (partition by a.Договор order by a.Период desc) as rn
		from stg._1cCMR.РегистрСведений_ПараметрыДоговора a
		inner join stg._1cCMR.Справочник_Договоры b
		on a.Договор = b.Ссылка
		where dateadd(yy,-2000,cast(a.Период as date)) <= @rdt
		and a.Активность = 1
		and a.ПроцентнаяСтавка > 0
		and not exists (select 1 from Temp_PTS_Test_det_current_params c where b.Код = c.external_id)
	)
	insert into Temp_PTS_Test_det_current_params
	select a.external_id, a.cur_rate, a.cur_plan_end_date
	from base a
	where a.rn = 1
	;





	--Справочники для правки "перескоков" через бакет
	drop table if exists Temp_PTS_Test_det_bucket_360;
	select * 
	into Temp_PTS_Test_det_bucket_360
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


	drop table if exists Temp_PTS_Test_det_bucket_90;
	select *  
	into Temp_PTS_Test_det_bucket_90
	from (values
	('[01] 0', 1),
	('[02] 1-30', 2),
	('[03] 31-60', 3),
	('[04] 61-90', 4),
	('[05] 90+', 5)) a (dpd_bucket_90, dpd_num);



	--Дата окончания договора



	drop table if exists Temp_PTS_Test_cred_end_date;
	select d.Код as external_id,
		   cast(dateadd(year,-2000,max(sd.Период)) as date) as end_date
	into Temp_PTS_Test_cred_end_date
	from stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
	inner join stg._1ccmr.Справочник_Договоры d on d.Ссылка=sd.договор
	inner join stg._1ccmr.Справочник_СтатусыДоговоров  ssd on ssd.Ссылка=sd.Статус
	where ssd.Наименование in ('Погашен','Продан')
	group by d.Код;



	print ('timing, Temp_PTS_Test_cred_end_date ' + format(getdate(), 'HH:mm:ss'));





	--Статусы договоров из ЦМР
	drop table if exists Temp_PTS_Test_cred_CMR_status;
	select b.Код as external_id, 
	b.Клиент as client_cmr_id,
	b.IsInstallment,
	dateadd(yy,-2000,a.Период) as dt_status,  
	c.Наименование as cred_status,
	ROW_NUMBER() over (partition by b.Код order by a.Период desc) as rown
	into Temp_PTS_Test_cred_CMR_status
	from stg._1cCMR.РегистрСведений_СтатусыДоговоров a
	inner join stg._1cCMR.Справочник_Договоры b
	on a.Договор = b.Ссылка
	inner join stg._1cCMR.Справочник_СтатусыДоговоров c
	on a.Статус = c.Ссылка
	;

	delete from Temp_PTS_Test_cred_CMR_status where rown <> 1;


	print ('timing, Temp_PTS_Test_cred_CMR_status ' + format(getdate(), 'HH:mm:ss'));





	---Заморозки

	drop table if exists Temp_PTS_Test_stg1_zamorozka;
	select a.Договор as Договор, a.Дата as Дата 
	into Temp_PTS_Test_stg1_zamorozka
	from stg._1cCMR.РегистрСведений_Реструктуризация a
	--from prodsql02.cmr.dbo.[РегистрСведений_Реструктуризация] a
	where Активность = 0x01
	and Заявление != 0x00000000000000000000000000000000
	and ВидРеструктуризации =  0xA2CC005056839FE911EBAEEEA6BD272F --Заморозка 1.0
	and a.Дата <= dateadd(yy,2000,@rdt)
	;


	drop table if exists Temp_PTS_Test_stg2_zamorozka;
	select b.Код as external_id, eomonth(dateadd(yy,-2000,cast(a.Дата as date))) as freeze_dt
	into Temp_PTS_Test_stg2_zamorozka
	from Temp_PTS_Test_stg1_zamorozka a
	left join stg._1cCMR.Справочник_Договоры b
	on a.Договор = b.Ссылка
	;

	drop table if exists Temp_PTS_Test_zamorozka;
	select a.external_id, 
	min(a.freeze_dt) as freeze_from,
	eomonth(max(a.freeze_dt),3) as freeze_to
	into Temp_PTS_Test_zamorozka
	from Temp_PTS_Test_stg2_zamorozka a
	where a.external_id not in ('21063000118279') --тест заморозки
	group by a.external_id
	having min(a.freeze_dt) < '2022-01-01' --единичные кейсы, они не должны попадать в костыли на проценты
	;





	--Банкроты

	drop table if exists Temp_PTS_Test_stg_bankrupt;
	select a.Контрагент as contragent,
	min(cast(dateadd(yy,-2000,a.дата) as date)) as dt
	into Temp_PTS_Test_stg_bankrupt
	--from [c2-vsr-sql04].[UMFO].[dbo].[Документ_АЭ_БанкротствоЗаемщика] a
	from stg._1cUMFO.Документ_АЭ_БанкротствоЗаемщика a
	group by a.Контрагент;


	drop table if exists Temp_PTS_Test_bankrupt;

	with base as (
		select distinct a.НомерДоговора as external_id, b.dt
		from stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный a
		inner join Temp_PTS_Test_stg_bankrupt b
		on a.Контрагент = b.contragent
		where a.НомерДоговора <> '1'
	union all
		select 
		cast(b.Number as varchar(100)) as external_id, 
		cast(a.DateResultOfCourtsDecisionBankrupt as date) as dt
		from stg._Collection.CustomerBankruptcy a
		left join stg._Collection.Deals b
		on a.CustomerId = b.IdCustomer
		where a.DateResultOfCourtsDecisionBankrupt is not null
	)
	select a.external_id, min(a.dt) as dt
	into Temp_PTS_Test_bankrupt
	from base a
	group by a.external_id
	;





	--очищаем реестр заморозки от банкротов (отдельный бакет)
	with a as (select * from Temp_PTS_Test_zamorozka a)
	delete from a
	where exists (select 1 from Temp_PTS_Test_bankrupt b where a.external_id = b.external_id and b.dt <= @rdt)
	;

	print ('timing, Temp_PTS_Test_zamorozka ' + format(getdate(), 'HH:mm:ss'));



	--ЭПС из УМФО

	drop table if exists Temp_PTS_Test_stg2_eps;

	select b.НомерДоговора as external_id, 
			c.период as период, 
			--c.активность as активность, 
			c.эффективнаяставкапроцента as эффективнаяставкапроцента,
			eomonth(dateadd(yy,-2000,cast(b.ДатаНачала as date))) as generation,
			b.СуммаЗайма as amount
	into Temp_PTS_Test_stg2_eps
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
						,row_number() OVER (PARTITION BY a.код ORDER BY p.Период ASC) AS rn--select top 100 *
					FROM stg._1ccmr.Справочник_Договоры a
					LEFT JOIN STG._1Ccmr.РегистрСведений_ПараметрыДоговора p ON a.ССылка = p.Договор
					) t
				WHERE rn = 1
				) c
	on b.Ссылка = c.Ссылка
	where b.ПометкаУдаления = 0
	;



	drop table if exists Temp_PTS_Test_eps;
	with base as (
	select a.*, ROW_NUMBER() over (partition by a.external_id order by a.Период desc) as rown
	from Temp_PTS_Test_stg2_eps a
	where a.эффективнаяставкапроцента > 0
	and dateadd(yy,-2000,cast(a.период as date)) <= @rdt 
	)
	select a.external_id, a.эффективнаяставкапроцента / 100.0 as eps
	into Temp_PTS_Test_eps
	from base a
	where a.rown = 1
	;


	--Перечень договоров
	drop table if exists Temp_PTS_Test_cred_reestr;

	select DISTINCT 
		a.external_id, 
		eomonth(cast(a.startdate as date)) as generation, 
		cast(a.startdate as date) as credit_date,
		case when eomonth(cast(a.startdate as date)) = EOMONTH(b.end_date) then 1 else 0 end as flag_closed_in_month,

		--15.06.2022 - новый алгоритм: до 2022г - FIX, с 2022г по таблице dwh2.risk.credits
		--05.04.2023 - + испытательный срок
		--13.04.2023 - + испытательный срок (rbp4)
		 coalesce(
				case 
					when a.credit_type_init = 'PTS_31' and a.startdate >= '2023-06-19' then 'PTS31_RBP4'
					when a.credit_type_init = 'PTS_31' and a.rbp_gr = 'RBP 4' then 'PTS31_RBP4'
					when a.credit_type_init = 'PTS_31' then 'PTS31'	
				end,
				fr.segment_rbp , 
				case
					when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 1' then 'RBP 1'
					when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 2' then 'RBP 2'
					when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 3' then 'RBP 3'
					when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 4' then 'RBP 4'
				end,
				'other'
			)
		as segment_rbp,
		isnull(b.end_date, cast('4444-01-01' as date)) as end_date,
		cast(a.amount as float) as amount,
		cast(a.term as float) as term,
		cast(a.InitialRate as float) as int_rate,
		cast(
			case 
				when rz.external_id is not null then concat('CESS ', format(eomonth(rz.action_date),'yyyy-MM-dd'))
				when cmr.IsInstallment = 1 then 'INSTALLMENT'
				when bkr.external_id is not null then 'BANKRUPT'	
				when d.external_id is not null then 'KK'

				--Новый кусок для деления на каналы -- 2025-07-26
				when a.credit_type_init = 'AUTOCREDIT' then 'AUTOCREDIT'
				when ch.Product_Channel in ('PTS_PSB', 'PTS_Infoseti', 'PTS_TBank') then ch.Product_Channel

				else 'USUAL'
			end as varchar(100)
			)
		as flag_kk,

		--coalesce(zz.eps / 100.0, ee.eps, 0) as eps
		case 
			when isnull(ee.eps,0) > 0 then ee.eps
			when isnull(ffep.eps,0) > 0 then ffep.eps 
		else 0.0 end
		as eps

	into Temp_PTS_Test_cred_reestr
	from dwh2.risk.credits a
	left join Temp_PTS_Test_cred_end_date b
	on a.external_id = b.external_id
	
	--left join RiskDWH.dbo.det_kk_cmr_and_space d
	--on a.external_id = d.external_id
	
	left join (
				select number as external_id
					, min(period_start) as dt_from
					, max(period_end) as dt_to--select *
				from dwh2.dbo.dm_restructurings where isapproved = 1 and operation_type = 'Кредитные каникулы'
				group by number
				) d
	on a.external_id = d.external_id

	--select * from dwh2.risk.REG_CRM_REDZONE rz
	--left join dwh2.risk.REG_CRM_REDZONE rz
	--on a.external_id = rz.external_id
	--and rz.action_type like '%Цессия%'
	--and rz.external_id <> '18061925070001' --в итоге не продали

	left join (select dt_cess as action_date, * from RiskDWH.Risk.Cess_Reestr_UMFO) rz
	on a.external_id = rz.external_id

	left join Temp_PTS_Test_bankrupt bkr
	on a.external_id = bkr.external_id
	and bkr.dt <= @rdt

	left join stg._1cCMR.Справочник_Договоры cmr
	on a.external_id = cmr.Код
	--15.06.2022 
	left join risk.stg_fcst_fix_rbp_2 fr
	on a.external_id = fr.external_id

	left join Temp_PTS_Test_eps ee
	on a.external_id = ee.external_id

	left join RiskDWH.risk.stg_fcst_fix_eps ffep
	on a.external_id = ffep.external_id

	left join RiskDWH.risk.Temp_PTS_Test_Channel ch
	on a.external_id = ch.external_id

	where cast(a.startdate as date) between cast('2016-01-01' as date) and @rdt
		and not exists (select 1 from Temp_PTS_Test_cred_CMR_status sts where a.external_id = sts.external_id and sts.cred_status = 'Внебаланс')
		and not (a.IsInstallment = 1) --убираем беззалоги
		and a.credit_type in ('PTS', 'PTS_31', 'PTS_REFIN')
		--and not exists (select 1 from risk.stg_fcst_PDL_cred pcr where a.external_id = pcr.external_id) --убираем PDL + повторные INST
		--and not (a.IsInstallment = 1 and a.generation >= '2022-11-01')
	;



	--31/08/2021 - Бизнес-займы
	insert into Temp_PTS_Test_cred_reestr 
	(external_id, generation, credit_date, flag_closed_in_month, segment_rbp, end_date, amount, term, int_rate, flag_kk, eps)
	select a.external_id, generation, credit_date, flag_closed_in_month, segment_rbp, end_date, amount, term, int_rate, flag_kk, 
	case 
	when isnull(ee.eps,0) > 0 then ee.eps
	when isnull(ffep.eps,0) > 0 then ffep.eps 
	else 0.0 end as eps

	--from Temp_PTS_Test_bus_cred_reestr a
	from RiskDWH.Risk.stg_fcst_bus_cred a
	left join Temp_PTS_Test_eps ee
	on a.external_id = ee.external_id
	left join RiskDWH.risk.stg_fcst_fix_eps ffep
	on a.external_id = ffep.external_id
	where a.generation <= @rdt
	--техмани и IOT (закрыт в феврале 2023) - вручную!
	and a.zaim not in (select zaim from riskdwh.risk.stg_fcst_handle_bus_cred)
	and a.external_id not in ('И-02/25', 'И-05/25')

	;


	--27.05.2024 - ПТС31, по которым останавливается начисление процентов. Маркируем кол-во месяцев до достижения предела начисления
	with base as (
		select a.external_id, 
		a.int_rate / 100 as int_rate,
		round(isnull(b.[Проценты начислено  нарастающим итогом],0),2) / a.amount as fact_int_charged,
		iif(a.generation < '2023-07-01', 1.5, 1.3) as charge_limit,
		a.amount,
		cast(isnull(b.[остаток од],0) as float) as od
		from Temp_PTS_Test_cred_reestr a
		--left join dwh2.dbo.dm_CMRStatBalance b
		left join risk.stg_fcst_CMR_lite b
		on a.external_id = b.external_id
		and b.d = @rdt
		where a.segment_rbp = 'PTS31'
		and a.flag_kk in ('USUAL','KK')
		--and b.[остаток од] > 0
	)
	update b set b.flag_kk = case 
		when isnull(a.od,0) <= 0 then 'STOP_CHARGE_00000'
		when a.fact_int_charged >= a.charge_limit then 'STOP_CHARGE_00000'
		--else concat ('STOP_CHARGE_', right(concat('00000',cast( round( (a.charge_limit - a.fact_int_charged) / (a.od * a.int_rate / 12 / a.amount), 0) as varchar(10))),5))
		else concat ('STOP_CHARGE_', right(concat('00000',cast( floor( (a.charge_limit - a.fact_int_charged) / (a.od * a.int_rate / 12 / a.amount) ) as varchar(10))),5))
	end
	from Temp_PTS_Test_cred_reestr b
	inner join base a
	on a.external_id = b.external_id

	;


	--28.05.2024 - КК, по которым смещается срок, по истечении которого останавливается начисление. Маркируем кол-во месяцев до конца новой даты погашения и соответственно остановки начислений
	update aa set aa.flag_kk = case 
	when b.cur_plan_end_date <= @rdt then 'KK00000'
	else concat('KK', right( concat('00000', floor( DATEDIFF(dd,@rdt,b.cur_plan_end_date) / 30 )), 5))
	end 
	from Temp_PTS_Test_cred_reestr aa
	left join Temp_PTS_Test_det_current_params b
	on aa.external_id = b.external_id
	where aa.flag_kk = 'KK'
	and aa.segment_rbp <> 'PTS31'
	;





	update Temp_PTS_Test_cred_reestr set eps = 0 where eps is null;


	drop index if exists idx_cred_reestr on Temp_PTS_Test_cred_reestr;
	create clustered index idx_cred_reestr on Temp_PTS_Test_cred_reestr (external_id);



	print ('timing, Temp_PTS_Test_cred_reestr ' + format(getdate(), 'HH:mm:ss'));


	--Историческая просрочка
	drop table if exists Temp_PTS_Test_det_historical_dpd;

	select a.r_date, a.external_id, a.dpd_final
	into Temp_PTS_Test_det_historical_dpd
	from RiskDWH.risk.stg_fcst_hist_dpd a
	where a.r_date <= @rdt
	and a.dpd_final is not null;




	--exec dbo.prc$set_debug_info @src = @srcname, @info = 'Temp_PTS_Test_stg_bal';

	--Остатки на различные MOB-ы
	drop table if exists Temp_PTS_Test_stg_bal;

	select
	a.external_id, 
	a.generation,
	a.term,
	a.segment_rbp,
	a.flag_kk,
	b.d as mob_date,
	DATEDIFF(MM, a.generation, b.d) as mob,

	RiskDWH.dbo.get_bucket_360_m( isnull(h.dpd_final, b.dpd) ) as dpd_bucket_360,

	cast(SUBSTRING(RiskDWH.dbo.get_bucket_360_m( isnull(h.dpd_final, b.dpd) ),2,2) as int) as dpd_bucket_num_360,

	RiskDWH.dbo.get_bucket_90( isnull(h.dpd_final, b.dpd) ) as dpd_bucket_90,

	cast(SUBSTRING(RiskDWH.dbo.get_bucket_90( isnull(h.dpd_final, b.dpd) ),2,2) as int) as dpd_bucket_num_90,

	isnull(h.dpd_final, b.dpd) as overdue_days,

	cast(isnull(b.[остаток од],0) as float) as principal_rest,
	a.end_date

	into Temp_PTS_Test_stg_bal
	from Temp_PTS_Test_cred_reestr a
	inner join Temp_PTS_Test_CMR_M b
	on a.external_id = b.external_id

	left join Temp_PTS_Test_det_historical_dpd h
	on a.external_id = h.external_id
	and b.d = h.r_date

	where a.flag_kk <> 'BUSINESS'
	;




	--31/08/2021 - Бизнес-займы
	insert into Temp_PTS_Test_stg_bal 
	(external_id, generation, term, segment_rbp, flag_kk, mob_date, mob, 
	dpd_bucket_360, dpd_bucket_num_360, dpd_bucket_90, dpd_bucket_num_90,
	overdue_days, principal_rest, end_date)
	select external_id, generation, term, segment_rbp, flag_kk, mob_date, mob, 
	dpd_bucket_360, dpd_bucket_num_360, dpd_bucket_90, dpd_bucket_num_90,
	overdue_days, principal_rest, end_date 
	from RiskDWH.risk.stg_fcst_bus_bal a
	where a.mob_date <= @rdt
	and a.zaim not in (select zaim from riskdwh.risk.stg_fcst_handle_bus_cred)
	and external_id not in ('И-05/25', 'И-02/25')
	;


	--23/12/2021 - берем последний факт из УМФО
	drop table if exists Temp_PTS_Test_umfo_last_fact;
	select 
	a.external_id, 
	a.r_date,
	a.total_od as od
	into Temp_PTS_Test_umfo_last_fact
	from RiskDWH.Risk.stg_fcst_umfo a
	where a.r_date = @rdt
	and a.zaim not in (select zaim from riskdwh.risk.stg_fcst_handle_bus_cred)
	;



	update a 
	set a.principal_rest = case when b.external_id is null then 0 else b.od end
	from Temp_PTS_Test_stg_bal a
	left join Temp_PTS_Test_umfo_last_fact b
	on a.external_id = b.external_id
	and a.mob_date = b.r_date
	where a.mob_date = @rdt
	;


	drop table Temp_PTS_Test_umfo_last_fact;


	--для учета погашенных в нулевом MoB-е

	 merge into Temp_PTS_Test_stg_bal dst
	 using Temp_PTS_Test_cred_reestr src 
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
	from Temp_PTS_Test_stg_bal a
	inner join Temp_PTS_Test_zamorozka b
	on a.external_id = b.external_id
	and a.mob_date between b.freeze_from and b.freeze_to
	where left(a.flag_kk,2) = 'KK'
	;



	print ('timing, Temp_PTS_Test_stg_bal ' + format(getdate(), 'HH:mm:ss'));



	--exec dbo.prc$set_debug_info @src = @srcname, @info = 'Temp_PTS_Test_stg_matrix_detail';

	--сборка переходов подоговорно (присоединение t+1 MOB к t)
	drop table if exists Temp_PTS_Test_stg_matrix_detail; 

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

	into Temp_PTS_Test_stg_matrix_detail

	from Temp_PTS_Test_stg_bal a
	left join Temp_PTS_Test_stg_bal b
	on a.external_id = b.external_id
	and a.mob = b.mob - 1
	left join Temp_PTS_Test_cred_reestr c
	on a.external_id = c.external_id
	left join risk.stg_fcst_umfo d
	on a.external_id = d.external_id
	and b.mob_date = d.r_date

	where 1=1
	and a.mob_date <= eomonth(@rdt,-1) --'2020-07-31'
	and (a.principal_rest > 0 or a.principal_rest = 0 and d.total_int > 0)


	drop index if exists idx1_stg_matrix_detail on Temp_PTS_Test_stg_matrix_detail;
	create clustered index idx1_stg_matrix_detail on Temp_PTS_Test_stg_matrix_detail (external_id, mob_date_to, generation, term, segment_rbp, flag_kk, mob_from, bucket_90_from, bucket_90_to);

	----------------------------------------------------

	--проверяем переходы на корректность (например, из 0 может перейти в 0 или в 1-30) и учет КК

	--exec dbo.prc$set_debug_info @src = @srcname, @info = 'CORRECTIONS Temp_PTS_Test_stg_matrix_detail';

	--обновление по закрытым договорам
	update Temp_PTS_Test_stg_matrix_detail
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
	--update Temp_PTS_Test_stg_matrix_detail
	--set 
	--bucket_360_to = '[10] Pay-off',
	--bucket_90_to = '[06] Pay-off',
	--bucket_num_360_to = 10,
	--bucket_num_90_to = 6,
	--dpd_to = 0,
	--flag_wrong_migration = 0
	--where principal_rest_to = 0 and flag_closed <> 1
	--;

	update a set 
	--select * 
	a.bucket_360_to = '[10] Pay-off',
	a.bucket_90_to = '[06] Pay-off',
	a.bucket_num_360_to = 10,
	a.bucket_num_90_to = 6,
	a.dpd_to = 0,
	flag_wrong_migration = 0
	from Temp_PTS_Test_stg_matrix_detail a
	left join risk.stg_fcst_umfo b
	on a.external_id = b.external_id
	and a.mob_date_to = b.r_date
	where a.principal_rest_to = 0 and a.flag_closed <> 1
	and not (a.principal_rest_to = 0 and isnull(b.total_int,0) > 0)
	;


	--очищаем некорректные переходы
	--15.05.2023 - закомментировано - оставляем как есть
	--delete from Temp_PTS_Test_stg_matrix_detail 
	--where flag_wrong_migration = 1;



	--15.05.2023 - удалил разметку WRONG_MIGR

	--сохраняем в отдельную таблицу 
	drop table if exists Temp_PTS_Test_wrong_migrations1;
	select * 
	into Temp_PTS_Test_wrong_migrations1
	from Temp_PTS_Test_stg_matrix_detail a
	where exists (select 1 from Temp_PTS_Test_stg_matrix_detail b
					where a.external_id = b.external_id
					and b.flag_wrong_migration = 1
					)
	;	



	--Исправление: ОД будущий > ОД Текущий
	update Temp_PTS_Test_stg_matrix_detail 
	set principal_rest_to = principal_rest
	where principal_rest_to > principal_rest
	;


	--Удаляем кривые/недозревшие переходы
	--сохраняем в отдельную таблицу 
	drop table if exists Temp_PTS_Test_wrong_migrations2;
	select * 
	into Temp_PTS_Test_wrong_migrations2
	from Temp_PTS_Test_stg_matrix_detail a
	where a.mob_date_to is null
	;


	delete from Temp_PTS_Test_stg_matrix_detail 
	where mob_date_to is null;



	--11.07.2023 - добавляем срез для цессий, чтобы учесть выручку от продажи




	print ('timing, Temp_PTS_Test_stg_matrix_detail ' + format(getdate(), 'HH:mm:ss'));



	--drop table Temp_PTS_Test_bus_stg_bal;
	drop table Temp_PTS_Test_cred_end_date;
	--drop table Temp_PTS_Test_stg_bal;




	/************************************************************************************************/
	/************************************************************************************************/
	/************************************************************************************************/


	--------------------------------------------------------------------------------------------------------
	-- PART 2 - расчет агрегатов
	--------------------------------------------------------------------------------------------------------




	--Агрегат
	drop table if exists Temp_PTS_Test_stg1_agg;
	select 
	a.generation, a.term, a.segment_rbp, a.flag_kk,
	a.mob_date_from, a.mob_date_to, a.mob_from, a.mob_to,
	--a.bucket_360_from, a.bucket_360_to, --a.bucket_num_360_from, a.bucket_num_360_to,
	a.bucket_90_from, a.bucket_90_to --, a.bucket_num_90_from, a.bucket_num_90_to

	, round(sum(a.principal_rest),2) as od_from
	, round(sum(a.principal_rest_to),2) as od_to
	, sum( case when a.principal_rest > 0 then 1 else 0 end) as cnt_from
	, sum( case when a.principal_rest_to > 0 then 1 else 0 end) as cnt_to

	into Temp_PTS_Test_stg1_agg
	from Temp_PTS_Test_stg_matrix_detail a
	group by a.generation, a.term, a.segment_rbp, a.flag_kk,
	a.mob_date_from, a.mob_date_to, a.mob_from, a.mob_to,
	--a.bucket_360_from, a.bucket_360_to, --a.bucket_num_360_from, a.bucket_num_360_to,
	a.bucket_90_from, a.bucket_90_to --, a.bucket_num_90_from, a.bucket_num_90_to
	;



	print ('timing, Temp_PTS_Test_stg1_agg ' + format(getdate(), 'HH:mm:ss'));



	--Для учета гашений по графику в группе Pay-off
	drop table if exists Temp_PTS_Test_standart_payoff;
	select a.generation, a.term, a.segment_rbp, a.flag_kk,
	a.mob_date_from, a.mob_date_to, a.mob_from, a.mob_to,
	a.bucket_90_from,
	'[06] Pay-off' as bucket_90_to,
	round(sum(a.od_from - a.od_to),2) as od_from,
	0 as od_to,
	sum(a.cnt_from) as cnt_from,
	sum(a.cnt_to) as cnt_to

	into Temp_PTS_Test_standart_payoff
	from Temp_PTS_Test_stg1_agg a
	where a.bucket_90_to <> '[06] Pay-off'
	group by a.generation, a.term, a.segment_rbp, a.flag_kk,
	a.mob_date_from, a.mob_date_to, a.mob_from, a.mob_to,
	a.bucket_90_from
	having sum(a.od_from - a.od_to) <> 0
	;


	print ('timing, Temp_PTS_Test_standart_payoff ' + format(getdate(), 'HH:mm:ss'));


	drop table if exists Temp_PTS_Test_stg2_agg;
	select a.generation, a.term, a.segment_rbp, a.flag_kk,
	a.mob_date_from, a.mob_date_to,
	a.mob_from, a.mob_to, a.bucket_90_from, a.bucket_90_to,
	a.od_from + isnull(b.od_from,0) as od_from,
	case when a.bucket_90_to = '[06] Pay-off' then a.od_from + isnull(b.od_from,0) else a.od_to end as od_to,
	sum(a.od_from) over (partition by a.generation, a.term, a.segment_rbp, a.flag_kk, a.mob_from, a.bucket_90_from) as total_od_from,
	isnull(a.cnt_from,0) + isnull(b.cnt_from,0) as cnt_from,
	isnull(a.cnt_to,0) + isnull(b.cnt_to,0) as cnt_to

	into Temp_PTS_Test_stg2_agg
	from Temp_PTS_Test_stg1_agg a
	left join Temp_PTS_Test_standart_payoff b
	on a.generation = b.generation
	and a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	and a.mob_from = b.mob_from
	and a.bucket_90_from = b.bucket_90_from
	and a.bucket_90_to = b.bucket_90_to
	;


	insert into Temp_PTS_Test_stg2_agg

	select a.generation, a.term, a.segment_rbp, a.flag_kk,
	a.mob_date_from, a.mob_date_to, a.mob_from, a.mob_to,
	a.bucket_90_from, a.bucket_90_to, 
	a.od_from, a.od_from as od_to,
	cc.total_od_from,
	isnull(a.cnt_from,0) as cnt_from,
	isnull(a.cnt_to,0) as cnt_to

	from Temp_PTS_Test_standart_payoff a
	left join (
		select c.generation, c.term, c.segment_rbp, c.flag_kk, c.mob_from, c.bucket_90_from, sum(c.od_from) as total_od_from
		from Temp_PTS_Test_stg1_agg c
		group by c.generation, c.term, c.segment_rbp, c.flag_kk, c.mob_from, c.bucket_90_from
	) cc
	on a.generation = cc.generation
	and a.term = cc.term
	and a.segment_rbp = cc.segment_rbp
	and a.flag_kk = cc.flag_kk
	and a.mob_from = cc.mob_from
	and a.bucket_90_from = cc.bucket_90_from
	where not exists (select 1 from Temp_PTS_Test_stg1_agg b
					where a.generation = b.generation
					and a.term = b.term
					and a.segment_rbp = b.segment_rbp
					and a.flag_kk = b.flag_kk
					and a.mob_from = b.mob_from
					and a.bucket_90_from = b.bucket_90_from
					and a.bucket_90_to = b.bucket_90_to
					);





	print ('timing, Temp_PTS_Test_stg2_agg ' + format(getdate(), 'HH:mm:ss'));




	drop table if exists Temp_PTS_Test_base_for_stg3_agg;

	with base as (
		select distinct a.generation, a.term, a.segment_rbp, a.flag_kk from Temp_PTS_Test_cred_reestr a	
	), dt as (
		select cast(a.dt as date) as mob_date 
		from dwh2.risk.calendar a
		where cast(a.dt as date) = eomonth(cast(a.dt as date))
		and cast(a.dt as date) between '2016-03-31' and eomonth(@rdt,-1)
	), buck as (
		select d.dpd_bucket_90 from Temp_PTS_Test_det_bucket_90 d
		union all
		select '[06] Pay-off' as dpd_bucket_90
		union all
		select '[07] Freeze' as dpd_bucket_90
	)
	select 
	a.generation, 
	a.term, 
	a.segment_rbp, 
	a.flag_kk, 
	dt.mob_date as mob_date_from, 
	EOMONTH(dt.mob_date,1) as mob_date_to,
	DATEDIFF(MM,a.generation,dt.mob_date) as mob_from,
	DATEDIFF(MM,a.generation,dt.mob_date) + 1 as mob_to,
	b1.dpd_bucket_90 as bucket_90_from,
	b2.dpd_bucket_90 as bucket_90_to
	into Temp_PTS_Test_base_for_stg3_agg
	from base a
	left join dt 
	on a.generation <= dt.mob_date
	left join buck b1
	on 1=1
	left join buck b2
	on 1=1

	where 1=1
	and not (left(a.flag_kk,2) <> 'KK' and b1.dpd_bucket_90 = '[07] Freeze')
	and not (left(a.flag_kk,2) <> 'KK' and b2.dpd_bucket_90 = '[07] Freeze')
	;



	print ('timing, Temp_PTS_Test_base_for_stg3_agg ' + format(getdate(), 'HH:mm:ss'));



	--полная матрица групп и дат для корректного построени средних значений в Excel
	drop table if exists Temp_PTS_Test_stg3_agg;


	select b.generation, b.term, b.segment_rbp, b.flag_kk,
	b.mob_date_from, b.mob_date_to, b.mob_from, b.mob_to, b.bucket_90_from, b.bucket_90_to,
	isnull(s.od_from,0) as  od_from,
	isnull(s.od_to,  0) as od_to,
	coalesce(s.total_od_from, cc.total_od_from, 0) as total_od_from,
	coalesce(s.cnt_from , 0) as cnt_from,
	coalesce(s.cnt_to	, 0) as cnt_to

	into Temp_PTS_Test_stg3_agg
	from Temp_PTS_Test_base_for_stg3_agg b
	left join Temp_PTS_Test_stg2_agg s
	on b.generation = s.generation
	and b.term = s.term
	and b.segment_rbp = s.segment_rbp
	and b.flag_kk = s.flag_kk
	and b.mob_from = s.mob_from
	and b.bucket_90_from = s.bucket_90_from
	and b.bucket_90_to = s.bucket_90_to
	left join (
		select c.generation, c.term, c.segment_rbp, c.flag_kk, c.mob_from, c.bucket_90_from, sum(c.od_from) as total_od_from 
		from Temp_PTS_Test_stg1_agg c
		group by c.generation, c.term, c.segment_rbp, c.flag_kk, c.mob_from, c.bucket_90_from
	) cc
	on b.generation = cc.generation
	and b.term = cc.term
	and b.segment_rbp = cc.segment_rbp
	and b.flag_kk = cc.flag_kk
	and b.mob_from = cc.mob_from
	and b.bucket_90_from = cc.bucket_90_from
	;




	--drop table Temp_PTS_Test_base_for_stg3_agg;



	--удаляем лишние срезы
	drop table if exists Temp_PTS_Test_for_delete;
	select a.generation, a.term, a.segment_rbp, a.flag_kk
	into Temp_PTS_Test_for_delete
	from Temp_PTS_Test_stg3_agg a
	group by a.generation, a.term, a.segment_rbp, a.flag_kk
	having sum(a.od_from) = 0
	;


	with a as (select * from Temp_PTS_Test_stg3_agg)
	delete from a
	where exists (select 1 from Temp_PTS_Test_for_delete b
				where a.generation = b.generation
				and a.term = b.term
				and a.segment_rbp = b.segment_rbp
				and a.flag_kk = b.flag_kk
				);




	print ('timing, Temp_PTS_Test_stg3_agg ' + format(getdate(), 'HH:mm:ss'));







	drop table if exists Temp_PTS_Test_rest_model;

	select 
	cast('PTS' as varchar(100)) as product,
	a.bucket_90_from, a.bucket_90_to, 
	case when sum(a.total_od_from) = 0 then 0 else sum(a.od_to) / sum(a.total_od_from) end as coef

	into Temp_PTS_Test_rest_model
	from Temp_PTS_Test_stg3_agg a
	where a.generation >= '2018-01-01'
	and a.mob_date_to <= @dt_back_test_from 
	and year(a.mob_date_to) = 2022
	and left(a.flag_kk,11) in ('USUAL','STOP_CHARGE') and a.segment_rbp <> 'PTS31'
	and a.bucket_90_from not in ('[05] 90+', '[06] Pay-off', '[07] Freeze')
	and not (cast(substring(a.bucket_90_from,2,2) as int) = cast(substring(a.bucket_90_to,2,2) as int) - 1)
	and not (a.bucket_90_from = '[01] 0' and a.bucket_90_to = '[06] Pay-off')
	and a.mob_to <= a.term --15/06/2021
	group by a.bucket_90_from, a.bucket_90_to
	;

	--ПТС31
	insert into Temp_PTS_Test_rest_model

	select 
	cast('PTS31' as varchar(100)) as product,
	a.bucket_90_from, a.bucket_90_to, 
	case when sum(a.total_od_from) = 0 then 0 else sum(a.od_to) / sum(a.total_od_from) end as coef

	from Temp_PTS_Test_stg3_agg a
	where a.generation >= '2018-01-01'
	and a.mob_date_to <= @dt_back_test_from
	and year(a.mob_date_to) = 2022
	and left(a.flag_kk,11) in ('USUAL','STOP_CHARGE')
	and a.segment_rbp in ('RBP 3','RBP 4')
	and a.bucket_90_from not in ('[05] 90+', '[06] Pay-off', '[07] Freeze')
	and not (cast(substring(a.bucket_90_from,2,2) as int) = cast(substring(a.bucket_90_to,2,2) as int) - 1)
	and not (a.bucket_90_from = '[01] 0' and a.bucket_90_to = '[06] Pay-off')
	and a.mob_to <= a.term --15/06/2021
	group by a.bucket_90_from, a.bucket_90_to
	;


	--ПТС31 без пролонгаций 
	insert into Temp_PTS_Test_rest_model

	select 
	cast('PTS31_RBP4' as varchar(100)) as product,
	a.bucket_90_from, a.bucket_90_to, 
	case when sum(a.total_od_from) = 0 then 0 else sum(a.od_to) / sum(a.total_od_from) end as coef

	from Temp_PTS_Test_stg3_agg a
	where a.generation >= '2018-01-01'
	and a.mob_date_to <= @dt_back_test_from
	and year(a.mob_date_to) = 2022
	and left(a.flag_kk,11) in ('USUAL','STOP_CHARGE')
	and a.segment_rbp in ('RBP 3','RBP 4')
	and a.bucket_90_from not in ('[05] 90+', '[06] Pay-off', '[07] Freeze')
	and not (cast(substring(a.bucket_90_from,2,2) as int) = cast(substring(a.bucket_90_to,2,2) as int) - 1)
	and not (a.bucket_90_from = '[01] 0' and a.bucket_90_to = '[06] Pay-off')
	and a.mob_to <= a.term --15/06/2021
	group by a.bucket_90_from, a.bucket_90_to
	;



	--installment
	with base as (
		select 
		cast('Installment' as varchar(100)) as product,
		a.bucket_90_from, a.bucket_90_to, 
		case when sum(a.total_od_from) = 0 then 0 else sum(a.od_to) / sum(a.total_od_from) end as coef
		from Temp_PTS_Test_stg3_agg a
		where a.generation >= '2018-01-01'
		and a.mob_date_to <= @dt_back_test_from
		and year(a.mob_date_to) = 2022
		and left(a.flag_kk,11) in ('USUAL','STOP_CHARGE')
		and a.bucket_90_from not in ('[05] 90+', '[06] Pay-off', '[07] Freeze')
		and not (cast(substring(a.bucket_90_from,2,2) as int) = cast(substring(a.bucket_90_to,2,2) as int) - 1)
		and not (a.bucket_90_from = '[01] 0' and a.bucket_90_to = '[06] Pay-off')
		and a.mob_to <= a.term --15/06/2021
		group by a.bucket_90_from, a.bucket_90_to
	)
	insert into Temp_PTS_Test_rest_model

	select b.product, b.bucket_90_from, b.bucket_90_to, b.coef
	from base b
	;

	--Business
	with base as (
		select 
		cast('BUSINESS' as varchar(100)) as product,
		a.bucket_90_from, a.bucket_90_to, 
		case when sum(a.total_od_from) = 0 then 0 else sum(a.od_to) / sum(a.total_od_from) end as coef
		from Temp_PTS_Test_stg3_agg a
		where a.generation >= '2018-01-01'
		and a.mob_date_to <= @dt_back_test_from
		and left(a.flag_kk,11) in ('USUAL','STOP_CHARGE')
		and year(a.mob_date_to) = 2022
		and a.bucket_90_from not in ('[05] 90+', '[06] Pay-off', '[07] Freeze')
		and not (cast(substring(a.bucket_90_from,2,2) as int) = cast(substring(a.bucket_90_to,2,2) as int) - 1)
		and not (a.bucket_90_from = '[01] 0' and a.bucket_90_to = '[06] Pay-off')
		and a.mob_to <= a.term --15/06/2021
		group by a.bucket_90_from, a.bucket_90_to
	)
	insert into Temp_PTS_Test_rest_model

	select b.product, b.bucket_90_from, b.bucket_90_to, b.coef
	from base b
	;












	--удаляем лишние временные таблицы
	--drop table Temp_PTS_Test_stg1_agg;
	--drop table Temp_PTS_Test_stg2_agg;
	--drop table Temp_PTS_Test_for_delete;
	--drop table Temp_PTS_Test_standart_payoff;
	--drop table Temp_PTS_Test_det_bucket_360;
	--drop table Temp_PTS_Test_det_bucket_90;




	-------------------------------------------------------------------------------------------------------------------------

	--Для вычисления доли каждого срока 
	/*
	drop table if exists Temp_PTS_Test_term_generation_cnt;
	select a.term, a.generation, a.segment_rbp, count(*) as cnt, sum(a.amount) as amount
	into Temp_PTS_Test_term_generation_cnt
	from Temp_PTS_Test_cred_reestr a
	group by a.term, a.generation, a.segment_rbp;


	select * from Temp_PTS_Test_term_generation_cnt a
	where a.generation >= '2019-10-01'
	and a.term <> 60;
	*/

	-------------------------------------------------------------------------------------------------------------------------

	--для анализа функции созревания


	/*
	select a.term, a.segment_rbp, a.generation, a.flag_kk,
	a.mob_to, a.mob_date_to, a.bucket_90_from, a.bucket_90_to, a.od_to as chisl, a.total_od_from as znam
	,case when a.cnt_from < 5 then '[01] 1-4' 
	when a.cnt_from < 100 then '[02] 5-99'
	else '[03] 100+' end as flag_cnt
	,case
	when a.bucket_90_from = '[01] 0'		and a.bucket_90_to = '[02] 1-30'	then 'Worse'
	when a.bucket_90_from = '[02] 1-30'		and a.bucket_90_to = '[03] 31-60'	then 'Worse'
	when a.bucket_90_from = '[03] 31-60'	and a.bucket_90_to = '[04] 61-90'	then 'Worse'
	when a.bucket_90_from = '[04] 61-90'	and a.bucket_90_to = '[05] 90+'		then 'Worse'

	when a.bucket_90_from = '[02] 1-30'		and a.bucket_90_to = '[01] 0'		then 'Improve (1 bucket)'
	when a.bucket_90_from = '[03] 31-60'	and a.bucket_90_to = '[02] 1-30'	then 'Improve (1 bucket)'
	when a.bucket_90_from = '[04] 61-90'	and a.bucket_90_to = '[03] 31-60'	then 'Improve (1 bucket)'

	when cast(substring(a.bucket_90_from,2,2) as int) = cast(substring(a.bucket_90_to,2,2) as int) - 2 
		and a.bucket_90_from not in ('[04] 61-90','[05] 90+','[06] Pay-off') then 'Through 1 bucket'

	when a.bucket_90_to = '[06] Pay-off' and a.bucket_90_from in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90') then 'Pay down'
	else 'Rest migration' end as migr_descr

	--from stg_migr_matrix_fact a 
	from Temp_PTS_Test_stg3_agg a --Temp_PTS_Test_stg4_agg a
	--order by a.term, a.segment_rbp, a.generation, a.mob_to, a.bucket_90_from, a.bucket_90_to
	*/
	;

	--Распределение выдач по сроку, группе RBP
	/*
	select a.generation, a.segment_rbp, a.term, count(*) as cnt, sum(a.amount) as volume, sum(a.int_rate * a.amount) / sum(a.amount) as int_rate_avg
	from Temp_PTS_Test_cred_reestr a
	group by a.generation, a.segment_rbp, a.term
	;

	select * from Temp_PTS_Test_stg_matrix_detail a
	where a.bucket_90_from = '[02] 1-30' and a.bucket_360_to = '[04] 61-90';
	*/

	--!!!--перескок через бакет влияет на размер резерва:

	/*
	select a.НомерДоговора, a.ДатаОтчета, a.ДнейПросрочки, 
	a.ОстатокОДвсего, a.ОстатокПроцентовВсего, 
	a.РезервБУОД, a.РезервБУПроценты, a.РезервБУПрочие,
	a.РезервНУОД, a.РезервНУПроценты, a.РезервНУПрочие
	from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a
	where a.НомерДоговора = '19112510000181'
	and cast(a.ДатаОтчета as date) = eomonth(cast(a.ДатаОтчета as date))
	order by a.ДатаОтчета asc
	*/





	--------------------------------------------------------------------------------------------------------
	-- PART 2.5 - Фактические данные (УМФО)
	--------------------------------------------------------------------------------------------------------



	--Просрочка на последний до заморозки месяц - чтобы сформировать корзины для резервов
	drop table if exists Temp_PTS_Test_stg_freeze_mod;
	select a.external_id, 
	--b.mob_date_to, 
	eomonth(@dt_back_test_from,-1) as mob_date_to,
	b.dpd_to,
	--DATEDIFF(dd, b.mob_date_to, '2021-06-30'),
	--b.dpd_to + DATEDIFF(dd, b.mob_date_to, '2021-06-30'),
	--b.dpd_to + DATEDIFF(dd, b.mob_date_to, '2021-06-30') - 90,
	--(cast(b.dpd_to as float) + cast(DATEDIFF(dd, b.mob_date_to, '2021-06-30') as float) - 90.0) / 30.0,
	--floor((cast(b.dpd_to as float) + cast(DATEDIFF(dd, b.mob_date_to, eomonth(@dt_back_test_from,-1)) as float) - 90.0) / 30.0) as mod_num 
	floor( (cast(b.dpd_to as float) --dpd за месяц до начала заморозки
			+ cast(DATEDIFF(dd, b.mob_date_to, a.freeze_from) as float) - 91.0) / 30.0) -- +1 месяц = историческая просрочка (на дату заморозки dpd = 0)
			+ DATEDIFF(MM, a.freeze_to, eomonth(@dt_back_test_from,-1)) - 1  -- + разница между датой выхода из заморозки и датой последнего факта
	as mod_num

	into Temp_PTS_Test_stg_freeze_mod
	from Temp_PTS_Test_zamorozka a
	inner join Temp_PTS_Test_stg_matrix_detail b
	on a.external_id = b.external_id
	and a.freeze_from = eomonth(b.mob_date_to, 1)
	where b.mob_date_to <= eomonth(@dt_back_test_from,-1)
	and a.freeze_from <= eomonth(@dt_back_test_from,-1)
	;







	----сборка MOD (month on default) для продления по факту
	drop table if exists Temp_PTS_Test_stg_start_default;

	select a.external_id, 
	min(b.d) as dt_default_from, eomonth(min(b.d)) as month_default_from
	into Temp_PTS_Test_stg_start_default
	from Temp_PTS_Test_cred_reestr a
	--inner join dwh2.dbo.dm_CMRStatBalance b (nolock)
	inner join risk.stg_fcst_CMR_lite b
	on a.external_id = b.external_id
	where b.dpd = 91 --between 91 and 101
	and b.d <= eomonth(@dt_back_test_from,-1) --'2020-12-31'
	and not exists (select 1 from Temp_PTS_Test_zamorozka z where a.external_id = z.external_id and eomonth(@dt_back_test_from,-1) between z.freeze_from and z.freeze_to) --заморозка
	and a.flag_kk <> 'BUSINESS'

	group by a.external_id ;


	--19/08/2021 - дата дефолта для тех, у кого нет 91dpd в ЦМР (кривые данные)
	drop table if exists Temp_PTS_Test_npl_cred_with_broken_dpd;

	with base as (
		select a.external_id, min(a.d) as dd
		--from dwh2.dbo.dm_CMRStatBalance a (nolock)
		from risk.stg_fcst_CMR_lite a
		where a.dpd > 90
		and not exists (select 1 from risk.stg_fcst_CMR_lite b --dwh2.dbo.dm_CMRStatBalance b (nolock)
						where a.external_id = b.external_id
						and b.dpd = 91)
		and not exists (select 1 from Temp_PTS_Test_zamorozka z where a.external_id = z.external_id and eomonth(@dt_back_test_from,-1) between z.freeze_from and z.freeze_to) --заморозка
		and not exists (select 1 from Temp_PTS_Test_cred_reestr cr where a.external_id = cr.external_id and cr.flag_kk = 'BUSINESS')
		group by a.external_id
	)
	select b.external_id, c.dpd, c.d,
	dateadd(dd, 91 - c.dpd, c.d) as dt_default_from, eomonth(dateadd(dd, 91 - c.dpd, c.d)) as month_default_from

	into Temp_PTS_Test_npl_cred_with_broken_dpd
	from base b
	--left join dwh2.dbo.dm_CMRStatBalance c (nolock)
	left join risk.stg_fcst_CMR_lite c
	on b.external_id = c.external_id
	and b.dd = c.d
	;





	insert into Temp_PTS_Test_stg_start_default 
	(external_id, dt_default_from, month_default_from)
	select a.external_id, a.dt_default_from, a.month_default_from
	from Temp_PTS_Test_npl_cred_with_broken_dpd a
	where not exists (select 1 from Temp_PTS_Test_stg_start_default b
					where a.external_id = b.external_id)
	;


	--31/08/2021 - бизнес-займы
	insert into Temp_PTS_Test_stg_start_default
	(external_id, dt_default_from, month_default_from)
	select a.external_id, 
	a.dt_default_from, eomonth(a.dt_default_from)
	--from Temp_PTS_Test_bus_default_from a
	from RiskDWH.Risk.stg_fcst_bus_default a
	where a.dt_default_from <= @rdt
	and a.zaim not in (select zaim from riskdwh.risk.stg_fcst_handle_bus_cred)
	;





	--Виртуальная дата дефолта для вышедших из заморозки (историческая просрочка)

	insert into Temp_PTS_Test_stg_start_default

	select a.external_id, 
	EOMONTH(a.mob_date_to, -1 * a.mod_num) as dt_default_from,
	EOMONTH(a.mob_date_to, -1 * a.mod_num) as month_default_from
	from Temp_PTS_Test_stg_freeze_mod a
	where exists (select 1 from Temp_PTS_Test_stg_matrix_detail s 
				  where a.external_id = s.external_id
				  and s.bucket_90_from = '[07] Freeze' and s.bucket_90_to not in ('[07] Freeze', '[06] Pay-off'))
	and not exists (select 1 from Temp_PTS_Test_stg_start_default d where a.external_id = d.external_id)
	;



	--банкроты, которые были в заморозке

	insert into Temp_PTS_Test_stg_start_default

	select distinct 
	a.external_id, 
	--c.mob_date_to, c.dpd_to,
	dateadd(dd,91 - c.dpd_to, c.mob_date_to) as dt_default_from,
	eomonth(dateadd(dd,91 - c.dpd_to, c.mob_date_to)) as month_default_from

	from Temp_PTS_Test_stg_matrix_detail a
	left join Temp_PTS_Test_stg_start_default b
	on a.external_id = b.external_id
	inner join (select a.external_id, min(eomonth(a.freeze_dt)) as freeze_dt from Temp_PTS_Test_stg2_zamorozka a group by a.external_id) z
	on a.external_id = z.external_id
	inner join Temp_PTS_Test_stg_matrix_detail c
	on a.external_id = c.external_id
	and z.freeze_dt = eomonth(c.mob_date_to,1)
	where a.mob_date_to = eomonth(@dt_back_test_from,-1)
	and a.bucket_90_to = '[05] 90+'
	and b.external_id is null;



	--в ЦМР нет даты дефолта из-за исторической просрочки

	insert into Temp_PTS_Test_stg_start_default

	select a.external_id, 
	dateadd(dd,91 - a.dpd_to, a.mob_date_to) as dt_default_from,
	eomonth(dateadd(dd,91 - a.dpd_to, a.mob_date_to)) as month_default_from
	from Temp_PTS_Test_stg_matrix_detail a
	where a.mob_date_to = @rdt
	and a.dpd_to > 90
	and not exists (select 1 from Temp_PTS_Test_stg_start_default b where a.external_id = b.external_id)

	print ('CNT without default dt = ' + format(@@rowcount,'Temp_PTS_Test_0'));


	print ('timing, Temp_PTS_Test_stg_start_default' + format(getdate(), 'HH:mm:ss'))








	--факт начисленные проценты (УМФО)

	drop table if exists Temp_PTS_Test_fact_due_int;

	select 
	b.term, 
	b.segment_rbp,
	b.flag_kk,
	b.generation,
	a.r_date,
	case 
	when fm.external_id is not null then fm.mod_num  
	when coalesce(hd.dpd_final, md.dpd_to, a.dpd) > 90 
	then datediff(MM, d.month_default_from, a.r_date ) end as mod_num,

	case 
	when a.r_date between z.freeze_from and z.freeze_to and fm.external_id is not null then fm.mod_num
	when a.r_date >= z.freeze_to and z.freeze_to is not null
		and coalesce(hd.dpd_final, md.dpd_to, a.dpd) = 0 and fm.external_id is not null then fm.mod_num --12/11/2021
	when coalesce(hd.dpd_final, md.dpd_to, a.dpd) > 90 
	then floor((coalesce(hd.dpd_final, md.dpd_to, a.dpd) - 91.0) / 30.0) end as last_MOD,

	case when a.r_date between z.freeze_from and z.freeze_to then '[07] Freeze'
	else RiskDWH.dbo.get_bucket_90(coalesce(hd.dpd_final, md.dpd_to, a.dpd)) end as bucket,

	z.freeze_from,

	cast(sum(b.amount * b.int_rate) as float) as chisl_avg_int_rate,
	cast(sum(b.amount) as float) as znam_avg_int_rate,
	sum(a.total_int) as total_int,
	sum(a.total_od ) as total_od

	into Temp_PTS_Test_fact_due_int
	from RiskDWH.Risk.stg_fcst_umfo a
	inner join Temp_PTS_Test_cred_reestr b
	on a.external_id = b.external_id

	left join Temp_PTS_Test_zamorozka z
	on a.external_id = z.external_id
	and a.r_date >= z.freeze_from --between z.freeze_from and z.freeze_to
	left join Temp_PTS_Test_stg_start_default d
	on a.external_id = d.external_id
	and d.month_default_from <= a.r_date
	left join Temp_PTS_Test_det_historical_dpd hd
	on a.external_id = hd.external_id
	and a.r_date = hd.r_date
	left join Temp_PTS_Test_stg_freeze_mod fm
	on a.external_id = fm.external_id
	and a.r_date = fm.mob_date_to
	left join Temp_PTS_Test_stg_matrix_detail md
	on a.external_id = md.external_id
	and a.r_date = md.mob_date_to

	where a.r_date <= @rdt
	--and dateadd(yyyy,-2000, cast(a.ДатаОтчета as date)) >= '2021-01-01'

	group by 
	b.term, 
	b.segment_rbp,
	b.flag_kk,
	b.generation,
	a.r_date,
	case 
	when fm.external_id is not null then fm.mod_num  
	when coalesce(hd.dpd_final, md.dpd_to, a.dpd) > 90 
	then datediff(MM, d.month_default_from, a.r_date ) end,
	case 
	when a.r_date between z.freeze_from and z.freeze_to and fm.external_id is not null then fm.mod_num
	when a.r_date >= z.freeze_to and z.freeze_to is not null
		and coalesce(hd.dpd_final, md.dpd_to, a.dpd) = 0 and fm.external_id is not null then fm.mod_num --12/11/2021
	when coalesce(hd.dpd_final, md.dpd_to, a.dpd) > 90 
	then floor((coalesce(hd.dpd_final, md.dpd_to, a.dpd) - 91.0) / 30.0) end,
	case when a.r_date between z.freeze_from and z.freeze_to then '[07] Freeze'
	else RiskDWH.dbo.get_bucket_90(coalesce(hd.dpd_final, md.dpd_to, a.dpd)) end,
	z.freeze_from
	;


	print ('timing, Temp_PTS_Test_fact_due_int ' + format(getdate(), 'HH:mm:ss'))




	drop table if exists Temp_PTS_Test_stg_payment;

	select a.external_id, 
	a.cdate, 
	a.principal_cnl,
	a.percents_cnl,
	a.fines_cnl,
	a.other_cnl
	into Temp_PTS_Test_stg_payment
	from risk.stg_fcst_payment a
	where not exists (select 1 from RiskDWH.dbo.det_cession_aug2021 b where a.external_id = b.external_id and eomonth(a.cdate) = '2021-08-31')
	union all
	select a.external_id,
	a.cdate,
	0,
	a.cession_revenue,
	0,
	0
	from risk.fix_cession_aug2021 a
	;





	---фактические платежи по %%
	----подоговорно за отчетные даты

	--declare @rdt date = '2024-10-31';declare @dt_back_test_from date = '2024-11-30';


	drop table if exists Temp_PTS_Test_stg_fact_od_int_pmt;

	select a.term,
	a.segment_rbp,
	a.flag_kk,
	a.generation,
	a.bucket_90_from as dpd_bucket, 
	eomonth(b.cdate) as r_date,
	sum(b.percents_cnl) as percents_cnl,
	sum(b.principal_cnl) as principal_cnl,
	sum(b.fines_cnl) as fines_cnl,
	sum(b.other_cnl) as other_cnl

	into Temp_PTS_Test_stg_fact_od_int_pmt

	from Temp_PTS_Test_stg_matrix_detail a
	inner join Temp_PTS_Test_stg_payment b
	on a.external_id = b.external_id 
	and a.mob_date_to = eomonth(b.cdate)

	where b.cdate <= @rdt

	group by a.term,
	a.segment_rbp,
	a.flag_kk,
	a.generation,
	a.bucket_90_from,
	eomonth(b.cdate)
	;


	insert into Temp_PTS_Test_stg_fact_od_int_pmt

	select a.term,
	a.segment_rbp,
	a.flag_kk,
	a.generation,
	a.bucket_90_from as dpd_bucket, 
	eomonth(b.cdate) as r_date,
	sum(b.percents_cnl) as percents_cnl,
	sum(b.principal_cnl) as principal_cnl,
	sum(b.fines_cnl) as fines_cnl,
	sum(b.other_cnl) as other_cnl
	from Temp_PTS_Test_stg_payment b
	inner join Temp_PTS_Test_stg_matrix_detail a
	on a.external_id = b.external_id
	and eomonth(b.cdate) = a.mob_date_from
	where not exists (select 1 from Temp_PTS_Test_stg_matrix_detail c where b.external_id = c.external_id and eomonth(b.cdate) = c.mob_date_to)
	and b.cdate <= @rdt --'2021-10-31' 
	group by a.term,
	a.segment_rbp,
	a.flag_kk,
	a.generation,
	a.bucket_90_from,
	eomonth(b.cdate)
	;


	insert into Temp_PTS_Test_stg_fact_od_int_pmt

	select a.term,
	a.segment_rbp,
	a.flag_kk,
	a.generation,
	'[01] 0' as dpd_bucket, 
	eomonth(b.cdate) as r_date,
	sum(b.percents_cnl) as percents_cnl,
	sum(b.principal_cnl) as principal_cnl,
	sum(b.fines_cnl) as fines_cnl,
	sum(b.other_cnl) as other_cnl
	from Temp_PTS_Test_stg_payment b
	inner join Temp_PTS_Test_cred_reestr a
	on a.external_id = b.external_id

	where not exists (select 1 from Temp_PTS_Test_stg_matrix_detail c where b.external_id = c.external_id /*and eomonth(b.cdate) = c.mob_date_to*/)
	--and b.cdate between dateadd(dd,1,eomonth(@rdt,-1)) and eomonth(@dt_back_test_from,-1)
	and b.cdate <= @rdt
	group by a.term,
	a.segment_rbp,
	a.flag_kk,
	a.generation,
	eomonth(b.cdate)
	;



	print ('timing, Temp_PTS_Test_stg_fact_od_int_pmt ' + format(getdate(), 'HH:mm:ss'))



	-----------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------








	--declare @dt_back_test_from date = '2024-09-30'
	--Распределение по сегментам НУ (последний факт)

	drop table if exists Temp_PTS_Test_stg1_NU_segment_distrib;

	with base as (
		select 
		a.external_id, a.generation, a.segment_rbp, a.term, a.flag_kk, a.mob_to, a.mob_date_to, a.bucket_90_to, 
		a.principal_rest_to,
		coalesce(hd.dpd_final, z.dpd, a.dpd_to) as dpd,
		--!!!--z.total_gross as gross,
		isnull(z.total_od,0) + isnull(z.total_int,0) as gross,

		--case when a.mob_date_to = '2023-02-28' then isnull(fff.prov_od_NU,0) + isnull(fff.prov_int_NU,0) + isnull(fff.prov_fee_NU,0)
		--else z.prov_NU_gross end as prov_gross_NU,	
		case when a.mob_date_to = '2023-02-28' then isnull(fff.prov_od_NU,0) + isnull(fff.prov_int_NU,0)
		else z.prov_NU_od + z.prov_NU_int end as prov_gross_NU,
	
		case 
		when z.NU_segment like 'P%' and ppp.pdn > 0.5 and ppp.pdn <= 0.8 and a.mob_date_to < '2022-03-31' then replace(z.NU_segment, 'P', 'P1')
		when z.NU_segment like 'P%' and ppp.pdn > 0.8 and a.mob_date_to < '2022-03-31' then replace(z.NU_segment, 'P', 'P2')
		--26.09.2022 - банкроты
		when z.NU_segment = 'BANKRUPT' and ppp.pdn > 0.5 and ppp.pdn <= 0.8 then 'BANKRUPT_P1'	
		when z.NU_segment = 'BANKRUPT' and ppp.pdn > 0.8 then 'BANKRUPT_P2'	
		else z.NU_segment end as NU_segment

		from Temp_PTS_Test_stg_matrix_detail a
		left join RiskDWH.Risk.stg_fcst_umfo z
		on a.external_id = z.external_id
		and a.mob_date_to = z.r_date
		left join Temp_PTS_Test_det_historical_dpd hd
		on a.external_id = hd.external_id 
		and a.mob_date_to = hd.r_date
		--13.04.2022 - выделение пдн > 80%
		left join dwh2.risk.pdn_calculation_2gen ppp
		on a.external_id = cast(ppp.Number as varchar)
		left join risk.fix_NU_feb_2023 fff
		on a.external_id = fff.external_id
		and a.mob_date_to = '2023-02-28'

		where 1=1
		and a.mob_date_to between eomonth(@dt_back_test_from,-3) /*'2021-01-31'*/ and eomonth(@dt_back_test_from,-1) --'2020-12-31'
		and a.bucket_90_to <> '[06] Pay-off'
	)
	select 
	a.external_id, a.generation, a.segment_rbp, a.term, a.flag_kk, a.mob_to, a.mob_date_to, a.bucket_90_to, 
	a.principal_rest_to,
	a.dpd,
	a.gross,
	a.prov_gross_NU,
	a.NU_segment

	into Temp_PTS_Test_stg1_NU_segment_distrib
	from base a

	;





	---последнее фактическое поколение, т.к. в Temp_PTS_Test_stg_matrix_detail нет записей, где mob_date_to = generation
	with base as (
		select 
		cr.external_id, cr.generation, cr.segment_rbp, cr.term, cr.flag_kk, 
		0 as mob_to, 
		z.r_date as mob_date_to, 
		cast('[01] 0' as varchar(100)) as bucket_90_to, 
		z.amount as principal_rest_to,
		coalesce(hd.dpd_final, z.dpd, 0) as dpd,
		--!!!--z.total_gross as gross,
		isnull(z.total_od,0) + isnull(z.total_int,0) as gross,
	
	
		--case when z.r_date = '2023-02-28' then isnull(fff.prov_od_NU,0) + isnull(fff.prov_int_NU,0) + isnull(fff.prov_fee_NU,0)
		--else z.prov_NU_gross end as prov_gross_NU,
		case when z.r_date = '2023-02-28' then isnull(fff.prov_od_NU,0) + isnull(fff.prov_int_NU,0)
		else z.prov_NU_od + z.prov_NU_int end as prov_gross_NU,

		case 
		when z.NU_segment like 'P%' and ppp.pdn > 0.5 and ppp.pdn <= 0.8 and z.r_date < '2022-03-31' then replace(z.NU_segment, 'P', 'P1')
		when z.NU_segment like 'P%' and ppp.pdn > 0.8 and z.r_date < '2022-03-31' then replace(z.NU_segment, 'P', 'P2')
		--26.09.2022 - банкроты
		when z.NU_segment = 'BANKRUPT' and ppp.pdn > 0.5 and ppp.pdn <= 0.8 then 'BANKRUPT_P1'	
		when z.NU_segment = 'BANKRUPT' and ppp.pdn > 0.8 then 'BANKRUPT_P2'	
		else z.NU_segment end as NU_segment

		from RiskDWH.Risk.stg_fcst_umfo z
		left join Temp_PTS_Test_det_historical_dpd hd
		on z.external_id = hd.external_id 
		and z.r_date = hd.r_date
		inner join Temp_PTS_Test_cred_reestr cr
		on z.external_id = cr.external_id
		--13.04.2022 - выделение пдн > 80%
		left join dwh2.risk.pdn_calculation_2gen ppp
		on z.external_id = cast(ppp.Number as varchar)
		left join risk.fix_NU_feb_2023 fff
		on z.external_id = fff.external_id
		and z.r_date = '2023-02-28'


		where 1=1
		and z.r_date = eomonth(@dt_back_test_from,-1) --'2020-12-31'
		and cr.generation = eomonth(@dt_back_test_from,-1)
		and z.zaim not in (select zaim from riskdwh.risk.stg_fcst_handle_bus_cred)
	)
	insert into Temp_PTS_Test_stg1_NU_segment_distrib


	select 
	a.external_id, a.generation, a.segment_rbp, a.term, a.flag_kk, a.mob_to, a.mob_date_to, a.bucket_90_to, 
	a.principal_rest_to,
	a.dpd,
	a.gross,
	a.prov_gross_NU,
	a.NU_segment

	from base a
	;



	



	---Распределение ОД по поколению, сегменту РБП, сроку, субпортфелю (кк, обычные, бизнес), бакету90, сегменту НУ (пдн, рестр, обесп) за последний месяц факта
	drop table if exists Temp_PTS_Test_stg2_NU_segment_distrib;
	select a.generation, a.segment_rbp, a.term, a.flag_kk, a.bucket_90_to, a.NU_segment,
	sum(a.principal_rest_to) as principal_rest_to,
	cast(count(*) as float) as cnt
	into Temp_PTS_Test_stg2_NU_segment_distrib
	from Temp_PTS_Test_stg1_NU_segment_distrib a
	--where a.mob_date_to between eomonth(@dt_back_test_from,-3) and eomonth(@dt_back_test_from,-1)
	where a.mob_date_to = eomonth(@dt_back_test_from, -1)

	group by a.generation, a.segment_rbp, a.term, a.flag_kk, a.bucket_90_to, a.NU_segment
	;




	drop table if exists Temp_PTS_Test_NU_segment_distrib
	select a.generation, a.segment_rbp, a.term, a.flag_kk, a.bucket_90_to, a.NU_segment,
	a.principal_rest_to,
	sum(a.principal_rest_to) over (partition by a.generation, a.segment_rbp, a.term, a.flag_kk, a.bucket_90_to) as total_od_to,
	case when sum(a.principal_rest_to) over (partition by a.generation, a.segment_rbp, a.term, a.flag_kk, a.bucket_90_to) = 0
	then 0
	else a.principal_rest_to / sum(a.principal_rest_to) over (partition by a.generation, a.segment_rbp, a.term, a.flag_kk, a.bucket_90_to) 
	end as share,

	a.cnt,
	case when sum(a.cnt) over (partition by a.generation, a.segment_rbp, a.term, a.flag_kk, a.bucket_90_to) = 0
	then 0
	else a.cnt / sum(a.cnt) over (partition by a.generation, a.segment_rbp, a.term, a.flag_kk, a.bucket_90_to) 
	end as cnt_share

	into Temp_PTS_Test_NU_segment_distrib
	from Temp_PTS_Test_stg2_NU_segment_distrib a

	;




	--Добавляем распреление сегментов НУ для остутствующих на последний факт бакетов, например, для поздних поколений нет 90+ или для ранних есть только 90+
	---ищем ближайший бакет ниже, т.к. вероятнее всего переход вверх
	with buck as (
	select * from (values ('[01] 0'),('[02] 1-30'),('[03] 31-60'),('[04] 61-90'),('[05] 90+')) a (dpd_bucket_90)
	), subportfs as (
	select b.*, a.dpd_bucket_90 from buck a
	left join (select distinct b.term, b.segment_rbp, b.flag_kk, b.generation from Temp_PTS_Test_NU_segment_distrib b) b
	on 1=1
	), distbucks as (
	select distinct a.term, a.segment_rbp, a.flag_kk, a.generation, a.bucket_90_to from Temp_PTS_Test_NU_segment_distrib a
	), base as (
	select a.generation, a.segment_rbp, a.term, a.flag_kk, a.dpd_bucket_90, c.bucket_90_to as bucket_for_join,
	ROW_NUMBER() over (partition by a.generation, a.segment_rbp, a.term, a.flag_kk, a.dpd_bucket_90 order by c.bucket_90_to desc) as rown
	from subportfs a
	left join Temp_PTS_Test_NU_segment_distrib b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	and a.generation = b.generation
	and a.dpd_bucket_90 = b.bucket_90_to
	inner join distbucks c
	on a.term = c.term
	and a.segment_rbp = c.segment_rbp
	and a.flag_kk = c.flag_kk
	and a.generation = c.generation
	and cast(substring(a.dpd_bucket_90,2,2) as int) > cast(substring(c.bucket_90_to,2,2) as int)

	where b.NU_segment is null
	)
	insert into Temp_PTS_Test_NU_segment_distrib
	select a.generation, a.segment_rbp, a.term, a.flag_kk, a.dpd_bucket_90, b.NU_segment, null, null, b.share, null, b.cnt_share 
	from base a
	left join Temp_PTS_Test_NU_segment_distrib b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.generation = b.generation
	and a.flag_kk = b.flag_kk
	and a.bucket_for_join = b.bucket_90_to
	where a.rown = 1
	;



	---Если не нашли ближайший бакет ниже, то ищем ближайший бакет сверху (скорее всего для субпортфеля есть только 90+)
	with buck as (
	select * from (values ('[01] 0'),('[02] 1-30'),('[03] 31-60'),('[04] 61-90'),('[05] 90+')) a (dpd_bucket_90)
	), subportfs as (
	select b.*, a.dpd_bucket_90 from buck a
	left join (select distinct b.term, b.segment_rbp, b.flag_kk, b.generation from Temp_PTS_Test_NU_segment_distrib b) b
	on 1=1
	), distbucks as (
	select distinct a.term, a.segment_rbp, a.flag_kk, a.generation, a.bucket_90_to from Temp_PTS_Test_NU_segment_distrib a
	), base as (
	select a.generation, a.segment_rbp, a.term, a.flag_kk, a.dpd_bucket_90, c.bucket_90_to as bucket_for_join,
	case when left(a.flag_kk,2) = 'KK' 
	then ROW_NUMBER() over (partition by a.generation, a.segment_rbp, a.term, a.flag_kk, a.dpd_bucket_90 order by c.bucket_90_to desc) 
	else ROW_NUMBER() over (partition by a.generation, a.segment_rbp, a.term, a.flag_kk, a.dpd_bucket_90 order by c.bucket_90_to asc) end as rown 
	from subportfs a
	left join Temp_PTS_Test_NU_segment_distrib b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	and a.generation = b.generation
	and a.dpd_bucket_90 = b.bucket_90_to
	left join distbucks c
	on a.term = c.term
	and a.segment_rbp = c.segment_rbp
	and a.flag_kk = c.flag_kk
	and a.generation = c.generation
	and cast(substring(a.dpd_bucket_90,2,2) as int) < cast(substring(c.bucket_90_to,2,2) as int)
	where b.NU_segment is null
	)
	insert into Temp_PTS_Test_NU_segment_distrib
	select a.generation, a.segment_rbp, a.term, a.flag_kk, a.dpd_bucket_90, b.NU_segment, null, null, b.share, null, b.cnt_share 
	from base a
	left join Temp_PTS_Test_NU_segment_distrib b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.generation = b.generation
	and a.flag_kk = b.flag_kk
	and a.bucket_for_join = b.bucket_90_to
	where a.rown = 1
	;


	--07.05.2024 - FIX для сегментов, по которым сумма = 0
	update a set a.share = case when b.term is not null then a.cnt_share else a.share end
	--select a.*, case when b.term is not null then a.cnt_share else a.share end as share_alt
	from Temp_PTS_Test_NU_segment_distrib a
	left join (
		select a.term, a.segment_rbp, a.generation, a.flag_kk, a.bucket_90_to, sum(a.share) as s
		from Temp_PTS_Test_NU_segment_distrib a
		group by a.term, a.segment_rbp, a.generation, a.flag_kk, a.bucket_90_to
		having sum(a.share) <= 0 
	) b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.generation = b.generation
	and a.flag_kk = b.flag_kk
	and a.bucket_90_to = b.bucket_90_to;




	--Проверки
	/*
	----сумма долей по сегментам равна 1
	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.bucket_90_to, sum(a.share)
	from Temp_PTS_Test_NU_segment_distrib a
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.bucket_90_to
	having round(sum(share),2) <> 1
	*/




	print ('timing, NU SEGMENTS ' + format(getdate(), 'HH:mm:ss'))
	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------




	drop table if exists Temp_PTS_Test_UMFO_NU_segment;

	select 
	a.external_id,
	a.r_date,
	case 
	when a.NU_segment like 'P%' and ppp.pdn > 0.5 and ppp.pdn <= 0.8 and a.r_date < '2022-03-31' then replace(a.NU_segment, 'P', 'P1')
	when a.NU_segment like 'P%' and ppp.pdn > 0.8 and a.r_date < '2022-03-31' then replace(a.NU_segment, 'P', 'P2')
	--26.09.2022
	when a.NU_segment = 'BANKRUPT' and ppp.pdn > 0.5 and ppp.pdn <= 0.8 then 'BANKRUPT_P1'
	when a.NU_segment = 'BANKRUPT' and ppp.pdn > 0.8 then 'BANKRUPT_P2'

	else a.NU_segment end as NU_segment

	into Temp_PTS_Test_UMFO_NU_segment
	from RiskDWH.Risk.stg_fcst_umfo a
	--13.04.2022 - учитываем пдн > 80%
	left join dwh2.risk.pdn_calculation_2gen ppp
	on a.external_id = cast(ppp.Number as varchar)

	where a.r_date between '2018-12-31' and eomonth(@dt_back_test_from,-1)
	and a.zaim not in (select zaim from riskdwh.risk.stg_fcst_handle_bus_cred)
	;



	--протягиваем на отстутвующие даты NU_segment
	drop table if exists Temp_PTS_Test_stg_UMFO_NU_segment;
	with base as (
		select a.external_id, cast(b.dt as date) as rdt
		from (select distinct a.external_id from Temp_PTS_Test_UMFO_NU_segment a) a
		left join dwh2.risk.calendar b
		on cast(b.dt as date) between '2018-12-01' and eomonth(@dt_back_test_from,-1)
		and cast(b.dt as date) = eomonth(cast(b.dt as date))
	), base2 as (
		select 
		a.external_id, a.rdt as r_date, 
		min(isnull(b.r_date,'4444-01-01')) over (partition by a.external_id order by a.rdt rows between current row and unbounded following) as mark1,
		max(isnull(b.r_date,'1111-01-01')) over (partition by a.external_id order by a.rdt rows between unbounded preceding and current row) as mark2
		from base a
		left join Temp_PTS_Test_UMFO_NU_segment b
		on a.external_id = b.external_id
		and a.rdt = b.r_date
	)
	select a.external_id, a.r_date, b.NU_segment
	into Temp_PTS_Test_stg_UMFO_NU_segment
	from base2 a
	left join Temp_PTS_Test_UMFO_NU_segment b
	on a.external_id = b.external_id
	and case when a.mark1 = '4444-01-01' then a.mark2 else a.mark1 end = b.r_date
	;


	merge into Temp_PTS_Test_UMFO_NU_segment dst
	using Temp_PTS_Test_stg_UMFO_NU_segment src
	on (dst.external_id = src.external_id and dst.r_date = src.r_date)
	when not matched then insert 
	(external_id, r_date, NU_segment)
	values
	(src.external_id, src.r_date, src.NU_segment)
	;




	--Нет сегмента ПДН - рассчитываем аналитически
	insert into Temp_PTS_Test_UMFO_NU_segment
	select a.external_id, cast(d.dt as date) as r_date,
	case 
	--26.09.2022
	when b.dt >= cast(d.dt as date) and c.pdn > 0.5 and c.pdn <= 0.8 then 'BANKRUPT_P1'
	when b.dt >= cast(d.dt as date) and c.pdn > 0.8 then 'BANKRUPT_P2'
	when b.dt >= cast(d.dt as date) then 'BANKRUPT'

	when a.flag_kk = 'BUSINESS' then 'UL'
	when c.pdn <= 0.5 then 'NP_NR_C'
	when c.pdn <= 0.8 then 'P1_NR_C'
	when c.pdn > 0.8 then 'P2_NR_C'
	else 'NP_NR_C'
	end as NU_segment

	from Temp_PTS_Test_cred_reestr a
	left join Temp_PTS_Test_bankrupt b
	on a.external_id = b.external_id
	left join dwh2.risk.pdn_calculation_2gen c
	on a.external_id = cast(c.Number as varchar)
	left join dwh2.risk.calendar d
	on cast(d.dt as date) between eomonth(a.generation,-1) and eomonth(@dt_back_test_from,-1)
	and cast(d.dt as date) = eomonth(cast(d.dt as date))
	where not exists (select 1 from Temp_PTS_Test_UMFO_NU_segment b where a.external_id = b.external_id)
	;



	print ('timing, Temp_PTS_Test_UMFO_NU_segment ' + format(getdate(), 'HH:mm:ss'))




	drop table if exists Temp_PTS_Test_umfo_fact;
	select 
	a.r_date,
	a.external_id, 
	isnull(d.dpd_final, a.dpd) as dpd,
	a.total_od as due_od,
	a.total_int as due_int,
	a.total_fee as due_fee,
	a.prov_BU_od as prov_od,
	a.prov_BU_int as prov_int,
	a.prov_BU_fee as prov_fee,

	isnull(fnu.prov_od_NU,a.prov_NU_od) as prov_od_NU,
	isnull(fnu.prov_int_NU,a.prov_NU_int) as prov_int_NU,
	isnull(fnu.prov_fee_NU,a.prov_NU_fee) as prov_fee_NU,

	isnull(case when i.gross = 0 then 0 else i.prov_IFRS_TTC / i.gross end,0) * a.total_od as IFRS9_od,
	isnull(case when i.gross = 0 then 0 else i.prov_IFRS_TTC / i.gross end,0) * a.total_int as IFRS9_int,
	isnull(case when i.gross = 0 then 0 else i.prov_IFRS_TTC / i.gross end,0) * a.total_fee as IFRS9_fee

	into Temp_PTS_Test_umfo_fact
	from RiskDWH.Risk.stg_fcst_umfo a
	inner join Temp_PTS_Test_cred_reestr b
	on a.external_id = b.external_id
	left join Temp_PTS_Test_det_historical_dpd d
	on a.external_id = d.external_id
	and a.r_date = d.r_date
	left join (
		select a.* 
		from RiskDWH.risk.IFRS9_vitr a 
		inner join RiskDWH.risk.det_IFRS_proper_vers b
		on a.r_date = b.r_date
		and a.vers = b.vers
	) i
	on a.external_id = i.external_id
	and a.r_date = i.r_date

	left join risk.fix_NU_feb_2023 fnu
	on a.external_id = fnu.external_id
	and a.r_date = '2023-02-28'

	where a.r_date between '2018-12-31' and @rdt
	and a.zaim not in (select zaim from riskdwh.risk.stg_fcst_handle_bus_cred)
	and a.external_id not in ('И-02/25', 'И-05/25')
	;



	print ('timing, Temp_PTS_Test_umfo_fact ' + format(getdate(), 'HH:mm:ss'))


	--Штуки (кол-во договоров)
	;
	drop table if exists Temp_PTS_Test_det_pieces_L1;
	select 
	RiskDWH.dbo.get_bucket_360_m( a.dpd ) as bucket_360_m, 
	sum(a.due_od) / cast(count(*) as float) as avg_od
	into Temp_PTS_Test_det_pieces_L1
	from Temp_PTS_Test_umfo_fact a
	inner join Temp_PTS_Test_cred_reestr b
	on a.external_id = b.external_id
	where a.r_date = @rdt 
	and a.due_od + a.due_int + a.due_fee > 0
	group by RiskDWH.dbo.get_bucket_360_m( a.dpd )
	;


	print ('timing, Temp_PTS_Test_det_pieces_L1 ' + format(getdate(), 'HH:mm:ss'))



	drop table if exists Temp_PTS_Test_det_pieces_L2;
	select 
	iif(b.segment_rbp = 'RBP 1', 'RBP 1', 'rest') as segment_rbp_2 ,
	RiskDWH.dbo.get_bucket_360_m( a.dpd ) as bucket_360_m, 
	sum(a.due_od ) / cast(count(*) as float) as avg_od
	into Temp_PTS_Test_det_pieces_L2
	from Temp_PTS_Test_umfo_fact a
	inner join Temp_PTS_Test_cred_reestr b
	on a.external_id = b.external_id
	where a.r_date = @rdt 
	and a.due_od + a.due_int + a.due_fee > 0
	group by 
	iif(b.segment_rbp = 'RBP 1', 'RBP 1', 'rest'), 
	RiskDWH.dbo.get_bucket_360_m( a.dpd )
	;


	print ('timing, Temp_PTS_Test_det_pieces_L2 ' + format(getdate(), 'HH:mm:ss'))



	print ('timing, Temp_PTS_Test_umfo_fact ' + format(getdate(), 'HH:mm:ss'))





	--/* P 1-2 */
	--drop table Temp_PTS_Test_bankrupt;
	----drop table Temp_PTS_Test_CMR_M;
	--drop table Temp_PTS_Test_cred_CMR_status;
	----drop table Temp_PTS_Test_cred_reestr;
	----drop table Temp_PTS_Test_det_current_params;
	--drop table Temp_PTS_Test_det_historical_dpd;
	----drop table Temp_PTS_Test_det_pieces_L1;
	----drop table Temp_PTS_Test_det_pieces_L2;
	----drop table Temp_PTS_Test_eps;
	----drop table Temp_PTS_Test_fact_due_int;
	--drop table Temp_PTS_Test_npl_cred_with_broken_dpd;
	----drop table Temp_PTS_Test_NU_segment_distrib;
	----drop table Temp_PTS_Test_rest_model;
	--drop table Temp_PTS_Test_stg_bal;
	--drop table Temp_PTS_Test_stg_bankrupt;
	----drop table Temp_PTS_Test_stg_fact_od_int_pmt;
	----drop table Temp_PTS_Test_stg_freeze_mod;
	----drop table Temp_PTS_Test_stg_matrix_detail;
	----drop table Temp_PTS_Test_stg_payment;
	----drop table Temp_PTS_Test_stg_start_default;
	--drop table Temp_PTS_Test_stg_UMFO_NU_segment;
	----drop table Temp_PTS_Test_stg_write_off;
	----drop table Temp_PTS_Test_stg1_NU_segment_distrib;
	--drop table Temp_PTS_Test_stg1_zamorozka;
	--drop table Temp_PTS_Test_stg2_eps;
	--drop table Temp_PTS_Test_stg2_NU_segment_distrib;
	--drop table Temp_PTS_Test_stg2_zamorozka;
	----drop table Temp_PTS_Test_stg3_agg;
	----drop table Temp_PTS_Test_umfo_fact;
	----drop table Temp_PTS_Test_UMFO_NU_segment;
	--drop table Temp_PTS_Test_wrong_migrations1;
	--drop table Temp_PTS_Test_wrong_migrations2;
	----drop table Temp_PTS_Test_zamorozka;







	----------------------------------------------------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------------------------------------------



	--BACKUP для пересчета - требуется, если из прогноза удаляются какие-либо группы: продукты/поколения/сегменты

	---залить 1 раз после PART 1-2



	drop table if exists Temp_PTS_Test_bkp_cred_reestr;
	drop table if exists Temp_PTS_Test_bkp_stg3_agg;
	drop table if exists Temp_PTS_Test_bkp_stg_matrix_detail;
	drop table if exists Temp_PTS_Test_bkp_fact_due_int;
	drop table if exists Temp_PTS_Test_bkp_stg_fact_od_int_pmt;

	select * into Temp_PTS_Test_bkp_cred_reestr from Temp_PTS_Test_cred_reestr;
	select * into Temp_PTS_Test_bkp_stg3_agg from Temp_PTS_Test_stg3_agg;
	select * into Temp_PTS_Test_bkp_stg_matrix_detail from Temp_PTS_Test_stg_matrix_detail a
	select * into Temp_PTS_Test_bkp_fact_due_int from Temp_PTS_Test_fact_due_int a
	select * into Temp_PTS_Test_bkp_stg_fact_od_int_pmt from Temp_PTS_Test_stg_fact_od_int_pmt a




	---выполнять при каждом запуске PART3 и дальше (первый раз можно не делать)
	/*

	delete from Temp_PTS_Test_cred_reestr; insert into Temp_PTS_Test_cred_reestr select * from Temp_PTS_Test_bkp_cred_reestr;
	delete from Temp_PTS_Test_stg3_agg; insert into Temp_PTS_Test_stg3_agg select * from Temp_PTS_Test_bkp_stg3_agg;
	delete from Temp_PTS_Test_stg_matrix_detail; insert into Temp_PTS_Test_stg_matrix_detail select * from Temp_PTS_Test_bkp_stg_matrix_detail;
	delete from Temp_PTS_Test_fact_due_int; insert into Temp_PTS_Test_fact_due_int select * from Temp_PTS_Test_bkp_fact_due_int;
	delete from Temp_PTS_Test_stg_fact_od_int_pmt; insert into Temp_PTS_Test_stg_fact_od_int_pmt select * from Temp_PTS_Test_bkp_stg_fact_od_int_pmt;

	*/


	------------------------------------------------------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------------------------------------------


	--------------------------------------------------------------------------------------------------------
	-- PART 3 - Модель Матриц Миграций
	--------------------------------------------------------------------------------------------------------


	print ('timing, start ' + format(getdate(), 'HH:mm:ss'))


	-- Оставляем моделируемые сегменты
	delete from Temp_PTS_Test_cred_reestr where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	delete from Temp_PTS_Test_stg3_agg where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	delete from Temp_PTS_Test_stg_matrix_detail where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	delete from Temp_PTS_Test_fact_due_int where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	delete from Temp_PTS_Test_stg_fact_od_int_pmt where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	delete from Temp_PTS_Test_stg_bal where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	delete from Temp_PTS_Test_wrong_migrations1 where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	delete from Temp_PTS_Test_wrong_migrations2 where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	delete from Temp_PTS_Test_stg1_agg where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	delete from Temp_PTS_Test_standart_payoff where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	delete from Temp_PTS_Test_stg2_agg where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	delete from Temp_PTS_Test_base_for_stg3_agg where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	delete from Temp_PTS_Test_for_delete where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	delete from Temp_PTS_Test_stg1_NU_segment_distrib where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	delete from Temp_PTS_Test_stg2_NU_segment_distrib where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	delete from Temp_PTS_Test_NU_segment_distrib where flag_kk in ('INSTALLMENT', 'PTS_PSB', 'AUTOCREDIT', 'PTS_Infoseti');
	--------------------------------------------------------------------------------------------------------



	drop table if exists Temp_PTS_Test_det_pdp_coef;

	select 
	cast(a.segment_rbp as varchar(100)) as segment_rbp,
	cast(a.coef as float) as coef
	into Temp_PTS_Test_det_pdp_coef
	from (values

	--('RBP 1',		0.9261076015		),
	--('RBP 2',		0.9496565303		),
	--('RBP 3',		0.9186476902		),
	--('RBP 4',		0.9533072014		),
	--('other',		0.9556120746		),
	--('PTS31',		0.9640297883		),
	--('PTS31_RBP4',	0.9755301842	)

	-- средний уровень ОД(MoB = 0). Досрочное погашение в 0-м бакете
				('RBP 1',		0.9204),
				('RBP 2',		0.9240),
				('RBP 3',		0.9118),
				('RBP 4',		0.9676),
				('other',		0.9448),
				('PTS31',		0.9484),
				('PTS31_RBP4',	0.9484)

	) a (segment_rbp, coef)
	;



	print ('timing, pdp_coef ' + format(getdate(), 'HH:mm:ss'))
	
	--select sum(vl_rub_fact) from Temp_PTS_Test_virt_gens
	--select * from Temp_PTS_Test_virt_gens
	--select generation, sum(vl_rub_fact) from Temp_PTS_Test_virt_gens group by generation order by 1 desc

	-------виртуальные поколения для плановых выдач
	drop table if exists Temp_PTS_Test_virt_gens;

	select a.segment_rbp, 
	cast(a.generation  as date) as generation,
	cast(a.term as int) as term,
	a.flag_kk,
	cast(a.vl_rub_fact as float) as vl_rub_fact

	into Temp_PTS_Test_virt_gens
	from (values 

	('RBP 1', '2025-12-31', 48, 'USUAL', 100000000)

	) a (segment_rbp, generation, term, flag_kk, vl_rub_fact)
	;



	delete from Temp_PTS_Test_virt_gens where generation <= @rdt;
	--delete from Temp_PTS_Test_virt_gens where flag_kk in ('Installment')
	--delete from Temp_PTS_Test_virt_gens where flag_kk = 'BUSINESS' and generation > '2021-12-31';
	delete from Temp_PTS_Test_virt_gens where generation > '2030-12-31';
	delete from Temp_PTS_Test_virt_gens where generation > eomonth(@dt_back_test_from,@horizon);
	delete from Temp_PTS_Test_virt_gens where vl_rub_fact <= 0;
	delete from Temp_PTS_Test_virt_gens where flag_kk = 'INSTALLMENT' and generation >= '2022-04-30';
	delete from Temp_PTS_Test_virt_gens where flag_kk = 'BUSINESS' and generation >= '2022-08-31';

	--delete from Temp_PTS_Test_virt_gens where generation > '2022-12-31';



	--15.05.2023 если вызрел факт, но в таблицах risk.stg_fcst_* его еще нет



	--drop table if exists Temp_PTS_Test_fact_volumes;
	--select 
	--case 
	--when a.credit_type_init = 'PTS_31' and a.rbp_gr = 'NotRBP_PROBATION' then 'PTS31'
	--when a.credit_type_init = 'PTS_31' then 'PTS31_RBP4'
	--else coalesce(
	--	fr.segment_rbp, 
	--	case
	--	when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 1' then 'RBP 1'
	--	when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 2' then 'RBP 2'
	--	when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 3' then 'RBP 3'
	--	when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 4' then 'RBP 4'
	--	end,
	--	'other'
	--) end as segment_rbp,
	--eomonth(a.generation) as generation,
	--a.term,
	--'USUAL' as flag_kk,
	--sum(cast(a.amount as float)) as volume,
	--sum(a.InitialRate * a.amount) / sum(a.amount) as int_rate


	--into Temp_PTS_Test_fact_volumes
	--from dwh2.risk.credits a
	--left join risk.stg_fcst_fix_rbp_2 fr
	--on a.external_id = fr.external_id
	--where a.generation between '2023-04-01' and '2023-04-30'
	--and a.IsInstallment = 0

	--group by case
	--when a.credit_type_init = 'PTS_31' and a.rbp_gr = 'NotRBP_PROBATION' then 'PTS31'
	--when a.credit_type_init = 'PTS_31' then 'PTS31_RBP4'
	--else coalesce(
	--	fr.segment_rbp, 
	--	case
	--	when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 1' then 'RBP 1'
	--	when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 2' then 'RBP 2'
	--	when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 3' then 'RBP 3'
	--	when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 4' then 'RBP 4'
	--	end,
	--	'other'
	--) end,
	--eomonth(a.generation),
	--a.term
	--;


	--insert into Temp_PTS_Test_virt_gens 
	--select a.segment_rbp, a.generation, a.term, a.flag_kk, a.volume 
	--from Temp_PTS_Test_fact_volumes a
	--where a.generation = '2023-04-30'
	--;




	print ('timing, Temp_PTS_Test_virt_gens ' + format(getdate(), 'HH:mm:ss'))





	----переход из [0] в [pay-off]
	------модельное значение по формуле: [(1+r)^(mob) - (1+r)^(mob-1)] / [(1+r)^(term) - (1+r)^(mob-1)]
	------затем скорректируется для учета досрочных гашений


	drop table if exists Temp_PTS_Test_nodpd_payoff_model;
	with base as (
		select 
		case 
		when a.segment_rbp = 'PTS31' then 'PTS31' 
		when a.segment_rbp = 'PTS31_RBP4' then 'PTS31_RBP4'
		else 'PTS' end as product,
		a.generation,
		a.term, 
		sum(a.int_rate * a.amount) / sum(a.amount) as avg_w_int_rate, 
		1.0 + sum(a.int_rate * a.amount) / sum(a.amount) / 100.0 / 12.0 as one_plus_r
		from Temp_PTS_Test_cred_reestr a
		where 1=1
		and left(a.flag_kk,11) in ('USUAL','STOP_CHARGE')
		group by a.generation, a.term, case 
		when a.segment_rbp = 'PTS31' then 'PTS31' 
		when a.segment_rbp = 'PTS31_RBP4' then 'PTS31_RBP4'
		else 'PTS' end
	), mm as (
		select cast(1 as float) as mob
		union all
		select cast(mob + 1 as float)
		from mm
		where mob < 100
	)
	select 
	--cast('1111-01-01' as date) as gen_from,
	--cast('2022-03-31' as date) as gen_to,
	--@rdt as gen_to,
	b.generation as gen_from,
	b.generation as gen_to,

	--cast('PTS' as varchar(100)) as product,
	cast(b.product as varchar(100)) as product,
	b.term, 
	mm.mob, 
	'[01] 0' as bucket_from, 
	'[06] Pay-off' as bucket_to,
	( power(b.one_plus_r, mm.mob) - power(b.one_plus_r, mm.mob - 1) ) / ( power(b.one_plus_r, b.term) - power(b.one_plus_r, mm.mob - 1) ) as coef

	into Temp_PTS_Test_nodpd_payoff_model
	from base b
	left join mm
	on mm.mob <= b.term
	;

	--подбираем ставки до конца текущего года
	/*
	select term, sum(cast(amount as float) * cast(eps as float))/sum(cast(amount as float)) as EIR
	from Temp_PTS_Test_cred_reestr
	where eomonth(generation, 0) >= eomonth('2025-08-01', 0)
		and segment_rbp != 'PTS31_RBP4'
	group by term

	union all
	
	select 100, sum(cast(amount as float) * cast(eps as float))/sum(cast(amount as float)) as EIR
	from Temp_PTS_Test_cred_reestr
	where eomonth(generation, 0) >= eomonth('2025-08-01', 0)
		and segment_rbp != 'PTS31_RBP4'
	order by 1
	*/

	with base as (
		select cast(24 as int) as term, cast((@avg_rate + 0.0) as float) as avg_w_int_rate, 1.0 + cast((@avg_rate + 0.0) as float) / 100.0 / 12.0 as one_plus_r	union all
		select cast(36 as int) as term, cast((@avg_rate - 3.0) as float) as avg_w_int_rate, 1.0 + cast((@avg_rate - 3.0) as float) / 100.0 / 12.0 as one_plus_r	union all
		select cast(48 as int) as term, cast((@avg_rate - 5.0) as float) as avg_w_int_rate, 1.0 + cast((@avg_rate - 5.0) as float) / 100.0 / 12.0 as one_plus_r
	), mm as (
		select cast(1 as float) as mob
		union all
		select cast(mob + 1 as float)
		from mm
		where mob < 100
	)
	insert into Temp_PTS_Test_nodpd_payoff_model

	select 
	
	eomonth(@rdt, 1) as gen_from,
	eomonth(@rdt, 12 - month(@rdt)) as gen_to,

	cast('PTS' as varchar(100)) as product,
	b.term, mm.mob, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to,
	( power(b.one_plus_r, mm.mob) - power(b.one_plus_r, mm.mob - 1) ) / ( power(b.one_plus_r, b.term) - power(b.one_plus_r, mm.mob - 1) ) as coef

	from base b
	left join mm
	on mm.mob <= b.term
	;

	
	--подбираем ставки со следующего года
	with base as (	
		select cast(24 as int) as term, cast((@avg_rate + 0.0) as float) as avg_w_int_rate, 1.0 + cast((@avg_rate + 0.0) as float) / 100.0 / 12.0 as one_plus_r	union all
		select cast(36 as int) as term, cast((@avg_rate - 3.0) as float) as avg_w_int_rate, 1.0 + cast((@avg_rate - 3.0) as float) / 100.0 / 12.0 as one_plus_r	union all
		select cast(48 as int) as term, cast((@avg_rate - 5.0) as float) as avg_w_int_rate, 1.0 + cast((@avg_rate - 5.0) as float) / 100.0 / 12.0 as one_plus_r
	), mm as (
		select cast(1 as float) as mob
		union all
		select cast(mob + 1 as float)
		from mm
		where mob < 100
	)
	insert into Temp_PTS_Test_nodpd_payoff_model

	select 

	dateadd(DD, 1, eomonth(@rdt, 12 - month(@rdt))) as gen_from,
	cast('4444-12-31' as date) as gen_to,

	cast('PTS' as varchar(100)) as product,
	b.term, mm.mob, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to,
	( power(b.one_plus_r, mm.mob) - power(b.one_plus_r, mm.mob - 1) ) / ( power(b.one_plus_r, b.term) - power(b.one_plus_r, mm.mob - 1) ) as coef

	from base b
	left join mm
	on mm.mob <= b.term
	;




	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	--подбираем ставки на текущий год

	;
	--ПТС31 RBP 4 - текущий год
	/*
	select term, sum(cast(amount as float) * cast(eps as float))/sum(cast(amount as float)) as EIR
	from Temp_PTS_Test_cred_reestr
	where eomonth(generation, 0) >= eomonth('2025-08-01', 0)
		and segment_rbp = 'PTS31_RBP4'
	group by term

	union all
	
	select 100, sum(cast(amount as float) * cast(eps as float))/sum(cast(amount as float)) as EIR
	from Temp_PTS_Test_cred_reestr
	where eomonth(generation, 0) >= eomonth('2025-08-01', 0)
		and segment_rbp = 'PTS31_RBP4'
	order by 1
	*/
	with base as (

		select cast(24 as int) as term, cast((@avg_rate + 30) as float) as avg_w_int_rate, 1.0 + cast((@avg_rate + 30) as float) / 100.0 / 12.0 as one_plus_r	union all
		select cast(36 as int) as term, cast((@avg_rate + 30) as float) as avg_w_int_rate, 1.0 + cast((@avg_rate + 30) as float) / 100.0 / 12.0 as one_plus_r	union all
		select cast(48 as int) as term, cast((@avg_rate + 20) as float) as avg_w_int_rate, 1.0 + cast((@avg_rate + 20) as float) / 100.0 / 12.0 as one_plus_r

	), mm as (
		select cast(1 as float) as mob
		union all
		select cast(mob + 1 as float)
		from mm
		where mob < 100
	)
	insert into Temp_PTS_Test_nodpd_payoff_model
	select 
	eomonth(@rdt, 1) as gen_from,
	eomonth(@rdt, 12 - month(@rdt)) as gen_to,

	cast('PTS31_RBP4' as varchar(100)) as product,
	b.term, mm.mob, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to,
	( power(b.one_plus_r, mm.mob) - power(b.one_plus_r, mm.mob - 1) ) / ( power(b.one_plus_r, b.term) - power(b.one_plus_r, mm.mob - 1) ) as coef
	from base b
	left join mm
	on mm.mob <= b.term

	;
	
	--подбираем ставки на следующий год

	with base as (
	
		select cast(24 as int) as term, cast((@avg_rate + 30) as float) as avg_w_int_rate, 1.0 + cast((@avg_rate + 30) as float) / 100.0 / 12.0 as one_plus_r	union all
		select cast(36 as int) as term, cast((@avg_rate + 30) as float) as avg_w_int_rate, 1.0 + cast((@avg_rate + 30) as float) / 100.0 / 12.0 as one_plus_r	union all
		select cast(48 as int) as term, cast((@avg_rate + 20) as float) as avg_w_int_rate, 1.0 + cast((@avg_rate + 20) as float) / 100.0 / 12.0 as one_plus_r

	), mm as (
		select cast(1 as float) as mob
		union all
		select cast(mob + 1 as float)
		from mm
		where mob < 100
	)
	insert into Temp_PTS_Test_nodpd_payoff_model
	select

	dateadd(DD, 1, eomonth(@rdt, 12 - month(@rdt))) as gen_from,
	cast('4444-12-31' as date) as gen_to,

	cast('PTS31_RBP4' as varchar(100)) as product,
	b.term, mm.mob, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to,
	( power(b.one_plus_r, mm.mob) - power(b.one_plus_r, mm.mob - 1) ) / ( power(b.one_plus_r, b.term) - power(b.one_plus_r, mm.mob - 1) ) as coef
	from base b
	left join mm
	on mm.mob <= b.term;



	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	--07/12/2021 для Installment --начисление процентов 2 раза в месяц!!!
	with base as (
		select cast(3 as int) as term, cast(292.0 as float) as avg_w_int_rate, 1.0 + cast(292.0 as float) / 100.0 / 24.0 as one_plus_r
		union all
		select cast(6 as int) as term, cast(292.0 as float) as avg_w_int_rate, 1.0 + cast(292.0 as float) / 100.0 / 24.0 as one_plus_r
		union all
		select cast(9 as int) as term, cast(145.0 as float) as avg_w_int_rate, 1.0 + cast(145.0 as float) / 100.0 / 24.0 as one_plus_r
		union all
		select cast(12 as int) as term, cast(145.0 as float) as avg_w_int_rate, 1.0 + cast(145.0 as float) / 100.0 / 24.0 as one_plus_r
	), mm as (
		select cast(1 as float) as mob
		union all
		select cast(mob + 1 as float)
		from mm
		where mob < 100
	)
	insert into Temp_PTS_Test_nodpd_payoff_model

	select 

	cast('1111-01-01' as date) as gen_from,
	cast('4444-01-01' as date) as gen_to,
	cast('Installment' as varchar(100)) as product,
	b.term, mm.mob, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to,
	( power(b.one_plus_r, mm.mob * 2) - power(b.one_plus_r, mm.mob * 2 - 1) ) / ( power(b.one_plus_r, b.term * 2) - power(b.one_plus_r, mm.mob * 2 - 1) ) as coef

	from base b
	left join mm
	on mm.mob <= b.term
	;



	--09/12/2021 для Бизнес-займов
	with base as (	
		select cast(3 as int) as term, cast(30.0 as float) as avg_w_int_rate, 1.0 + cast(30.0 as float) / 100.0 / 12.0 as one_plus_r
		union all	
		select cast(6 as int) as term, cast(30.0 as float) as avg_w_int_rate, 1.0 + cast(30.0 as float) / 100.0 / 12.0 as one_plus_r
		union all
		select cast(12 as int) as term, cast(30.0 as float) as avg_w_int_rate, 1.0 + cast(30.0 as float) / 100.0 / 12.0 as one_plus_r
		union all
		select cast(24 as int) as term, cast(30.0 as float) as avg_w_int_rate, 1.0 + cast(30.0 as float) / 100.0 / 12.0 as one_plus_r
		union all
		select cast(36 as int) as term, cast(30.0 as float) as avg_w_int_rate, 1.0 + cast(30.0 as float) / 100.0 / 12.0 as one_plus_r
		union all
		select cast(48 as int) as term, cast(30.0 as float) as avg_w_int_rate, 1.0 + cast(30.0 as float) / 100.0 / 12.0 as one_plus_r
	), mm as (
		select cast(1 as float) as mob
		union all
		select cast(mob + 1 as float)
		from mm
		where mob < 100
	)
	insert into Temp_PTS_Test_nodpd_payoff_model

	select 

	cast('1111-01-01' as date) as gen_from,
	cast('4444-01-01' as date) as gen_to,
	cast('BUSINESS' as varchar(100)) as product,
	b.term, mm.mob, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to,
	( power(b.one_plus_r, mm.mob) - power(b.one_plus_r, mm.mob - 1) ) / ( power(b.one_plus_r, b.term) - power(b.one_plus_r, mm.mob - 1) ) as coef

	from base b
	left join mm
	on mm.mob <= b.term
	;






	print ('timing, Temp_PTS_Test_nodpd_payoff_model' + format(getdate(), 'HH:mm:ss'))




	--28.02.2022 - стресс-тест
	----снижение Cash-in
	---март - май снижение
	---июнь - сентябрь - воостановление

	drop table if exists Temp_PTS_Test_det_stress;
	select 
	cast(a.dt_from as date) as dt_from, 
	cast(a.dt_to as date) as dt_to,
	cast(a.koef_po as float) as koef_po,
	cast(a.koef_worse as float) as koef_worse
	into Temp_PTS_Test_det_stress
	from (values
	--('2022-03-31','2022-05-31',0.35, 1.15),
	--('2022-06-30','2022-06-30',0.44, 1.13),
	--('2022-07-31','2022-07-31',0.54, 1.11),
	--('2022-08-31','2022-08-31',0.63, 1.09),
	--('2022-09-30','2022-09-30',0.72, 1.06),
	--('2022-10-31','2022-10-31',0.81, 1.04),
	--('2022-11-30','2022-11-30',0.91, 1.02),
	--('2022-12-31','2022-12-31',0.98, 1.01)

	--('2022-03-31','2022-05-31',0.45, 1.15),
	--('2022-06-30','2022-06-30',0.53, 1.13),
	--('2022-07-31','2022-07-31',0.61, 1.11),
	--('2022-08-31','2022-08-31',0.69, 1.09),
	--('2022-09-30','2022-09-30',0.76, 1.06),
	--('2022-10-31','2022-10-31',0.84, 1.04),
	--('2022-11-30','2022-11-30',0.92, 1.02),
	--('2022-12-31','2022-12-31',0.98, 1.01)

	--('2022-03-31','2022-05-31', 1.0, 1.15),
	--('2022-06-30','2022-06-30', 1.0, 1.13),
	--('2022-07-31','2022-07-31', 1.0, 1.11),
	--('2022-08-31','2022-08-31', 1.0, 1.09),
	--('2022-09-30','2022-09-30', 1.0, 1.06),
	--('2022-10-31','2022-10-31', 1.0, 1.04),
	--('2022-11-30','2022-11-30', 1.0, 1.02),
	--('2022-12-31','2022-12-31', 1.0, 1.01)

	---13.04.2022
	--('2022-03-31','2022-05-31',0.80, 1.10),
	--('2022-06-30','2022-06-30',0.83, 1.09),
	--('2022-07-31','2022-07-31',0.85, 1.07),
	--('2022-08-31','2022-08-31',0.88, 1.06),
	--('2022-09-30','2022-09-30',0.90, 1.05),
	--('2022-10-31','2022-10-31',0.93, 1.04),
	--('2022-11-30','2022-11-30',0.95, 1.02),
	--('2022-12-31','2022-12-31',0.98, 1.01)

	---14.04.2022
	--('2022-03-31','2022-05-31', 1.0, 1.10),
	--('2022-06-30','2022-06-30', 1.0, 1.09),
	--('2022-07-31','2022-07-31', 1.0, 1.07),
	--('2022-08-31','2022-08-31', 1.0, 1.06),
	--('2022-09-30','2022-09-30', 1.0, 1.05),
	--('2022-10-31','2022-10-31', 1.0, 1.04),
	--('2022-11-30','2022-11-30', 1.0, 1.02),
	--('2022-12-31','2022-12-31', 1.0, 1.01)

	---18.04.2022
	--('2022-03-31','2022-04-30', 1.0, 1.10),
	--('2022-05-31','2022-05-31', 1.0 * 0.75, 1.10),
	--('2022-06-30','2022-06-30', 1.0, 1.09),
	--('2022-07-31','2022-07-31', 1.0, 1.07),
	--('2022-08-31','2022-08-31', 1.0, 1.06),
	--('2022-09-30','2022-09-30', 1.0, 1.05),
	--('2022-10-31','2022-10-31', 1.0, 1.04),
	--('2022-11-30','2022-11-30', 1.0, 1.02),
	--('2022-12-31','2022-12-31', 1.0, 1.01)

	---11.07.2022
	--('2022-03-31','2022-04-30', 1.0, 1.10),
	--('2022-05-31','2022-05-31', 1.0 * 0.75, 1.10),
	--('2022-06-30','2022-06-30', 1.0, 1.09),
	--('2022-07-31','2022-07-31', 1.0 * 0.9, 1.07),
	--('2022-08-31','2022-08-31', 1.0 * 0.9, 1.06),
	--('2022-09-30','2022-09-30', 1.0, 1.05),
	--('2022-10-31','2022-10-31', 1.0, 1.04),
	--('2022-11-30','2022-11-30', 1.0, 1.02),
	--('2022-12-31','2022-12-31', 1.0, 1.01)

	---12.08.2022
	--('2022-03-31','2022-04-30', 1.0, 1.10),
	--('2022-05-31','2022-05-31', 1.0 * 0.75, 1.10),
	--('2022-06-30','2022-06-30', 1.0, 1.09),
	--('2022-07-31','2022-07-31', 1.0 * 0.9, 1.07),
	--('2022-08-31','2022-08-31', 1.0 * 0.95, 1.06), --!!!
	--('2022-09-30','2022-09-30', 1.0, 1.05),
	--('2022-10-31','2022-10-31', 1.0, 1.04),
	--('2022-11-30','2022-11-30', 1.0, 1.02),
	--('2022-12-31','2022-12-31', 1.0, 1.01)

	--('2023-09-30','4444-01-01', 0.9, 1.0)

	('1111-01-01','1111-01-01', 1.0, 1.0)

	) a (dt_from, dt_to, koef_po, koef_worse)
	;




	print ('timing, Temp_PTS_Test_rest_model' + format(getdate(), 'HH:mm:ss'))



	------------------------------------------------------------------------------
	---коэффициенты для корректировки pay-down в зависимости от сегмента RBP и срока (term)
	drop table if exists Temp_PTS_Test_model_adjust;

	select 
	cast('PTS' as varchar(100)) as product,
	cast(a.segment_rbp as varchar(100)) as segment_rbp,
	cast(a.term as int) as term,
	cast(a.bucket_from as varchar(100)) as bucket_from,
	cast(a.bucket_to as varchar(100)) as bucket_to,
	cast(a.coef as float) as coef
	into Temp_PTS_Test_model_adjust
	from (
	--pay-off
	select 'GR 30/40' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 24 as term, 1.0 as coef union all
	select 'GR 30/40' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 36 as term, 1.0 as coef union all
	select 'GR 30/40' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 1' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 24 as term, 0.99 as coef union all
	select 'RBP 1' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 36 as term, 0.99 as coef union all
	select 'RBP 1' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 48 as term, 0.99 as coef union all

	select 'RBP 2' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 2' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 2' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 3' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 3' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 3' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 4' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 4' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 4' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 48 as term, 1.0 as coef union all

	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 24 as term, 1.0 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 36 as term, 1.0 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 48 as term, 1.0 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 60 as term, 1.0 as coef union all

	--worsening
	select 'GR 30/40' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 24 as term, 1.0 as coef union all
	select 'GR 30/40' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 36 as term, 1.0 as coef union all
	select 'GR 30/40' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 1' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 1' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 1' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 2' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 2' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 2' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 3' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 3' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 3' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 4' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 4' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 4' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 48 as term, 1.0 as coef union all

	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 24 as term, 1.0 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 36 as term, 1.0 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 48 as term, 1.0 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 60 as term, 1.0 as coef union all


	select 'GR 30/40' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 24 as term, 1.0 as coef union all
	select 'GR 30/40' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 36 as term, 1.0 as coef union all
	select 'GR 30/40' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 1' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 1' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 1' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 2' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 24 as term, 1.02 as coef union all
	select 'RBP 2' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 36 as term, 1.02 as coef union all
	select 'RBP 2' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 48 as term, 1.02 as coef union all

	select 'RBP 3' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 3' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 3' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 4' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 4' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 4' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 48 as term, 1.0 as coef union all

	select 'other' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 24 as term, 1.0 as coef union all
	select 'other' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 36 as term, 1.0 as coef union all
	select 'other' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 48 as term, 1.0 as coef union all
	select 'other' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 60 as term, 1.0 as coef union all


	select 'GR 30/40' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 24 as term, 1.0 as coef union all
	select 'GR 30/40' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 36 as term, 1.0 as coef union all
	select 'GR 30/40' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 1' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 1' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 1' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 2' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 2' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 2' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 3' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 3' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 3' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 4' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 4' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 4' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 48 as term, 1.0 as coef union all

	select 'other' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 24 as term, 0.97 as coef union all
	select 'other' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 36 as term, 0.97 as coef union all
	select 'other' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 48 as term, 0.97 as coef union all
	select 'other' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 60 as term, 0.97 as coef union all


	select 'GR 30/40' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 24 as term, 1.0 as coef union all
	select 'GR 30/40' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 36 as term, 1.0 as coef union all
	select 'GR 30/40' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 1' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 24 as term, 0.95 as coef union all
	select 'RBP 1' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 36 as term, 0.95 as coef union all
	select 'RBP 1' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 48 as term, 0.95 as coef union all

	select 'RBP 2' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 24 as term, 0.97 as coef union all
	select 'RBP 2' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 36 as term, 0.97 as coef union all
	select 'RBP 2' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 48 as term, 0.97 as coef union all

	select 'RBP 3' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 3' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 3' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 48 as term, 1.0 as coef union all

	select 'RBP 4' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 24 as term, 1.0 as coef union all
	select 'RBP 4' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 36 as term, 1.0 as coef union all
	select 'RBP 4' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 48 as term, 1.0 as coef union all

	select 'other' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 24 as term, 0.95 as coef union all
	select 'other' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 36 as term, 0.95 as coef union all
	select 'other' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 48 as term, 0.95 as coef union all
	select 'other' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 60 as term, 0.95 as coef union all




	select 'PTS31' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 24 as term, 1.0 as coef union all
	select 'PTS31' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 36 as term, 1.0 as coef union all
	select 'PTS31' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 48 as term, 1.0 as coef union all

	select 'PTS31' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 24 as term, 1.0 as coef union all
	select 'PTS31' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 36 as term, 1.0 as coef union all
	select 'PTS31' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 48 as term, 1.0 as coef union all

	select 'PTS31' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 24 as term, 1.0 as coef union all
	select 'PTS31' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 36 as term, 1.0 as coef union all
	select 'PTS31' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 48 as term, 1.0 as coef union all

	select 'PTS31' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 24 as term, 1.0 as coef union all
	select 'PTS31' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 36 as term, 1.0 as coef union all
	select 'PTS31' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 48 as term, 1.0 as coef union all

	select 'PTS31' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 24 as term, 1.05 as coef union all
	select 'PTS31' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 36 as term, 1.05 as coef union all
	select 'PTS31' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 48 as term, 1.05 as coef union all



	select 'PTS31_RBP4' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 24 as term, 1.0 as coef union all
	select 'PTS31_RBP4' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 36 as term, 1.0 as coef union all
	select 'PTS31_RBP4' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 48 as term, 1.0 as coef union all

	select 'PTS31_RBP4' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 24 as term, 1.5 as coef union all
	select 'PTS31_RBP4' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 36 as term, 1.5 as coef union all
	select 'PTS31_RBP4' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 48 as term, 1.5 as coef union all

	select 'PTS31_RBP4' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 24 as term, 1.0 as coef union all
	select 'PTS31_RBP4' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 36 as term, 1.0 as coef union all
	select 'PTS31_RBP4' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 48 as term, 1.0 as coef union all

	select 'PTS31_RBP4' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 24 as term, 1.0 as coef union all
	select 'PTS31_RBP4' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 36 as term, 1.0 as coef union all
	select 'PTS31_RBP4' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 48 as term, 1.0 as coef union all

	select 'PTS31_RBP4' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 24 as term, 1.0 as coef union all
	select 'PTS31_RBP4' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 36 as term, 1.0 as coef union all
	select 'PTS31_RBP4' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 48 as term, 1.0 as coef

	) a
	;


	--07/12/2021 installm
	insert into Temp_PTS_Test_model_adjust

	select 
	cast('Installment' as varchar(100)) as product,
	cast(a.segment_rbp as varchar(100)) as segment_rbp,
	cast(a.term as int) as term,
	cast(a.bucket_from as varchar(100)) as bucket_from,
	cast(a.bucket_to as varchar(100)) as bucket_to,
	cast(a.coef as float) as coef
	from (
	--pay-off
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 3 as term,  1.0 /*0.4375*/ as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 6 as term,  1.0 /*0.4375*/ as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 9 as term,  1.0 /*0.4375*/ as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 12 as term, 1.0 /*0.4375*/ as coef union all
	--worsening
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 3 as term,  1.3712 * 1.5 * 1.5 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 6 as term,  1.3712 * 1.5 * 1.2 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 9 as term,  1.3712 * 1.5 * 1.05 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 12 as term, 1.3712 * 1.45 as coef union all

	select 'other' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 3 as term,  1.3590 * 1.5 * 1.5 as coef union all
	select 'other' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 6 as term,  1.3590 * 1.5 * 1.2 as coef union all
	select 'other' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 9 as term,  1.3590 * 1.5 * 1.05 as coef union all
	select 'other' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 12 as term, 1.3590 * 1.45 as coef union all

	select 'other' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 3 as term,  1.1967 * 1.5 * 1.5 as coef union all
	select 'other' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 6 as term,  1.1967 * 1.5 * 1.2 as coef union all
	select 'other' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 9 as term,  1.1967 * 1.5 * 1.05 as coef union all
	select 'other' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 12 as term, 1.1967 * 1.45 as coef union all

	select 'other' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 3 as term,  0.7421 * 1.5 * 1.5 as coef union all
	select 'other' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 6 as term,  0.7421 * 1.5 * 1.2 as coef union all
	select 'other' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 9 as term,  0.7421 * 1.5 * 1.05 as coef union all
	select 'other' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 12 as term, 0.7421 * 1.45 as coef

	) a
	;

	--07/12/2021 business
	insert into Temp_PTS_Test_model_adjust

	select 
	cast('BUSINESS' as varchar(100)) as product,
	cast(a.segment_rbp as varchar(100)) as segment_rbp,
	cast(a.term as int) as term,
	cast(a.bucket_from as varchar(100)) as bucket_from,
	cast(a.bucket_to as varchar(100)) as bucket_to,
	cast(a.coef as float) as coef
	from (
	--pay-off
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 3 as term, 0 as coef union all --13.12.2021 - без ПДП
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 6 as term, 0 as coef union all --13.12.2021 - без ПДП
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 12 as term, 0.8 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 24 as term, 0.8 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 36 as term, 0.8 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[06] Pay-off' as bucket_to, 48 as term, 0.8 as coef union all

	--worsening
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 3 as term, 0.61 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 6 as term, 0.61 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 12 as term, 0.35 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 24 as term, 0.25 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 36 as term, 0.2 as coef union all
	select 'other' as segment_rbp, '[01] 0' as bucket_from, '[02] 1-30' as bucket_to, 48 as term, 0.2 as coef union all

	select 'other' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 3 as term, 0.61 as coef union all
	select 'other' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 6 as term, 0.61 as coef union all
	select 'other' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 12 as term, 0.35 as coef union all
	select 'other' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 24 as term, 0.25 as coef union all
	select 'other' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 36 as term, 0.2 as coef union all
	select 'other' as segment_rbp, '[02] 1-30' as bucket_from, '[03] 31-60' as bucket_to, 48 as term, 0.2 as coef union all

	select 'other' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 3 as term, 0.61 as coef union all
	select 'other' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 6 as term, 0.61 as coef union all
	select 'other' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 12 as term, 0.35 as coef union all
	select 'other' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 24 as term, 0.25 as coef union all
	select 'other' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 36 as term, 0.2 as coef union all
	select 'other' as segment_rbp, '[03] 31-60' as bucket_from, '[04] 61-90' as bucket_to, 48 as term, 0.2 as coef union all

	select 'other' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 3 as term, 0.61 as coef union all
	select 'other' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 6 as term, 0.61 as coef union all
	select 'other' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 12 as term, 0.35 as coef union all
	select 'other' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 24 as term, 0.25 as coef union all
	select 'other' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 36 as term, 0.2 as coef union all
	select 'other' as segment_rbp, '[04] 61-90' as bucket_from, '[05] 90+' as bucket_to, 48 as term, 0.2 as coef

	) a
	;




	--проверка справочника на дубли
	/*
	select a.product, a.term, a.segment_rbp, a.bucket_from, a.bucket_to
	from Temp_PTS_Test_model_adjust a
	group by a.product, a.term, a.segment_rbp, a.bucket_from, a.bucket_to
	having count(*)>1
	*/



	print ('timing, Temp_PTS_Test_model_adjust' + format(getdate(), 'HH:mm:ss'))

	drop table if exists Temp_PTS_Test_repdates;

	with months as (
	select 1 as m union all select m + 1 from months where m < 12
	), years as (
	select 1 as y union all select y + 1 from years where y < 100
	), increment as (
	select a.m + (b.y - 1) * 12 as incr from months as a, years as b
	)
	select EOMONTH(@rdt, i.incr) as mob_date_to
	into Temp_PTS_Test_repdates
	from increment i
	where EOMONTH(@rdt, i.incr) <= eomonth(@dt_back_test_from, @horizon + 2)
	;






	--продлеваем факт для прогноза 
	drop table if exists Temp_PTS_Test_stg_back_base;

	with base as (
		select distinct a.term, a.segment_rbp, a.generation, a.flag_kk from Temp_PTS_Test_stg3_agg a
	union
		select distinct b.term, b.segment_rbp, b.generation, b.flag_kk from Temp_PTS_Test_cred_reestr b 
		where b.generation >= @rdt
	union 
		select distinct v.term, v.segment_rbp, v.generation, v.flag_kk from Temp_PTS_Test_virt_gens v 

	), buck as (
		select '[01] 0' as bucket union all
		select '[02] 1-30' as bucket union all
		select '[03] 31-60' as bucket union all
		select '[04] 61-90' as bucket union all
		select '[05] 90+' as bucket union all
		select '[06] Pay-off' as bucket
	), src as (
		select b.term, b.segment_rbp, b.generation, b.flag_kk, d.mob_date_to, DATEDIFF(MM, b.generation, d.mob_date_to) as mob_to, 
		d1.bucket as bucket_90_from,
		d2.bucket as bucket_90_to
		from base b
		left join Temp_PTS_Test_repdates d
		on b.generation < d.mob_date_to
		left join buck d1
		on 1 = 1
		left join buck d2
		on 1 = 1
	)
	select * 
	into Temp_PTS_Test_stg_back_base
	from (
		select * from Temp_PTS_Test_stg3_agg a
	union all
		select s.generation, s.term, s.segment_rbp, s.flag_kk, EOMONTH(s.mob_date_to,-1) as mob_date_from, s.mob_date_to, 
		s.mob_to - 1 as mob_from, s.mob_to, s.bucket_90_from, s.bucket_90_to,
		cast(null as float) as od_from,
		cast(null as float) as od_to,
		cast(null as float) as total_od_from,
		cast(null as int) as cnt_from,
		cast(null as int) as cnt_to
		from src s
	) aa
	;





	print ('timing, Temp_PTS_Test_stg_back_base' + format(getdate(), 'HH:mm:ss'))

	--версии кривых для разных продуктов/сегментов


	drop table if exists Temp_PTS_Test_det_curve_version;

	select 
	cast(a.product as varchar(100)) as product,
	cast(a.segment_rbp as varchar(100)) as segment_rbp,
	cast(a.bucket_from as varchar(100)) as bucket_from,
	cast(a.bucket_to as varchar(100)) as bucket_to,
	a.vers

	into Temp_PTS_Test_det_curve_version
	from (values 
	--бизнес: кривая от other + корр коэф-ты
	('BUSINESS', 'other', '[01] 0',			'[06] Pay-off', /*13*/ 18),
	('BUSINESS', 'other', '[01] 0',			'[02] 1-30',	12),
	('BUSINESS', 'other', '[02] 1-30',		'[03] 31-60',	11),
	('BUSINESS', 'other', '[03] 31-60',		'[04] 61-90',	8 ),
	('BUSINESS', 'other', '[04] 61-90',		'[05] 90+',		8 ),
	--старый инстолмент: кривая от other + корр коэф-ты
	('INSTALLMENT', 'other', '[01] 0',			'[06] Pay-off', /*13*/ 18),
	('INSTALLMENT', 'other', '[01] 0',			'[02] 1-30',	12),
	('INSTALLMENT', 'other', '[02] 1-30',		'[03] 31-60',	11),
	('INSTALLMENT', 'other', '[03] 31-60',		'[04] 61-90',	8 ),
	('INSTALLMENT', 'other', '[04] 61-90',		'[05] 90+',		8 ),

	--ПТС: новые матрицы с выделением ПТС31
	('REST', 'RBP 1', '[01] 0',			'[06] Pay-off', /*10*/ /*15*/ 29),
	('REST', 'RBP 1', '[01] 0',			'[02] 1-30',	/*9*/ 22 ),
	('REST', 'RBP 1', '[02] 1-30',		'[03] 31-60',	8 ),
	('REST', 'RBP 1', '[03] 31-60',		'[04] 61-90',	8 ),
	('REST', 'RBP 1', '[04] 61-90',		'[05] 90+',		8 ),

	('REST', 'RBP 2', '[01] 0',			'[06] Pay-off', /*11*/ /*16*/ 30),
	('REST', 'RBP 2', '[01] 0',			'[02] 1-30',	10),
	('REST', 'RBP 2', '[02] 1-30',		'[03] 31-60',	9 ),
	('REST', 'RBP 2', '[03] 31-60',		'[04] 61-90',	8 ),
	('REST', 'RBP 2', '[04] 61-90',		'[05] 90+',		8 ),

	('REST', 'RBP 3', '[01] 0',			'[06] Pay-off', /*12*/ /*17*/ 31),
	('REST', 'RBP 3', '[01] 0',			'[02] 1-30',	11),
	('REST', 'RBP 3', '[02] 1-30',		'[03] 31-60',	10),
	('REST', 'RBP 3', '[03] 31-60',		'[04] 61-90',	8 ),
	('REST', 'RBP 3', '[04] 61-90',		'[05] 90+',		8 ),

	('REST', 'RBP 4', '[01] 0',			'[06] Pay-off', /*12*/ /*17*/ 31),
	('REST', 'RBP 4', '[01] 0',			'[02] 1-30',	11),
	('REST', 'RBP 4', '[02] 1-30',		'[03] 31-60',	10),
	('REST', 'RBP 4', '[03] 31-60',		'[04] 61-90',	8 ),
	('REST', 'RBP 4', '[04] 61-90',		'[05] 90+',		8 ),

	('REST', 'other', '[01] 0',			'[06] Pay-off', /*13*/ /*18*/ 32),
	('REST', 'other', '[01] 0',			'[02] 1-30',	12),
	('REST', 'other', '[02] 1-30',		'[03] 31-60',	11),
	('REST', 'other', '[03] 31-60',		'[04] 61-90',	8 ),
	('REST', 'other', '[04] 61-90',		'[05] 90+',		8 ),

	('REST', 'PTS31', '[01] 0',			'[06] Pay-off', /*14*/ 19),
	('REST', 'PTS31', '[01] 0',			'[02] 1-30',	/*13*/ /*14*/ 15),
	('REST', 'PTS31', '[02] 1-30',		'[03] 31-60',	/*12*/ 13),
	('REST', 'PTS31', '[03] 31-60',		'[04] 61-90',	/*8*/ /*9*/ 10 ),
	('REST', 'PTS31', '[04] 61-90',		'[05] 90+',		/*8*/ /*9*/ 10 ),

	('REST', 'PTS31_RBP4', '[01] 0',			'[06] Pay-off', /*12*/ 17),
	('REST', 'PTS31_RBP4', '[01] 0',			'[02] 1-30',	11),
	('REST', 'PTS31_RBP4', '[02] 1-30',			'[03] 31-60',	10),
	('REST', 'PTS31_RBP4', '[03] 31-60',		'[04] 61-90',	8 ),
	('REST', 'PTS31_RBP4', '[04] 61-90',		'[05] 90+',		8 )

	) a (product, segment_rbp, bucket_from, bucket_to, vers)



	--нормализация модельных значений + back-тест
	drop table if exists Temp_PTS_Test_for_back_test;

	with base as (
		select a.generation, a.term, a.segment_rbp, a.flag_kk,
		a.mob_date_to, a.mob_to, a.bucket_90_from, a.bucket_90_to,

		case 
		when a.bucket_90_from = '[06] Pay-off' and a.bucket_90_to = '[06] Pay-off' then 1
		else iif(a.total_od_from = 0, 0, a.od_to / a.total_od_from) end as fact_coef,

		case 
		---Переходы за горизонтом срока 
		-----в нулевой бакет
		when a.mob_to >= a.term and a.bucket_90_to = '[01] 0' then 0
		-----из нулевого бакета
		when a.mob_to > a.term and a.bucket_90_from = '[01] 0' and a.bucket_90_to <> '[02] 1-30' then 0
		when a.mob_to > a.term and a.bucket_90_from = '[01] 0' and a.bucket_90_to = '[02] 1-30' then 1

		-----в [1-30]
		when a.mob_to > a.term and a.bucket_90_to = '[02] 1-30' then 0
		-----из [1-30]
		when a.mob_to > a.term /*+ 1*/ and a.bucket_90_from = '[02] 1-30' and a.bucket_90_to <> '[03] 31-60' then 0
		when a.mob_to > a.term /*+ 1*/ and a.bucket_90_from = '[02] 1-30' and a.bucket_90_to = '[03] 31-60' then 1

		-----в [31-60]
		when a.mob_to > a.term /*+ 1*/ and a.bucket_90_to = '[03] 31-60' then 0
		-----из [31-60]
		when a.mob_to > a.term /*+ 2*/ and a.bucket_90_from = '[03] 31-60' and a.bucket_90_to <> '[04] 61-90' then 0
		when a.mob_to > a.term /*+ 2*/ and a.bucket_90_from = '[03] 31-60' and a.bucket_90_to = '[04] 61-90' then 1

		-----в [61-90]
		when a.mob_to > a.term /*+ 2*/ and a.bucket_90_to = '[04] 61-90' then 0
		-----из [61-90]
		when a.mob_to > a.term /*+ 3*/ and a.bucket_90_from = '[04] 61-90' and a.bucket_90_to <> '[05] 90+' then 0
		when a.mob_to > a.term /*+ 3*/ and a.bucket_90_from = '[04] 61-90' and a.bucket_90_to = '[05] 90+' then 1


		---[0]->paydown
		when a.bucket_90_from = '[01] 0' and a.bucket_90_to = '[06] Pay-off' and a.mob_to = a.term then 1.0 --28.02.2022
		when a.bucket_90_from = '[01] 0' and a.bucket_90_to = '[06] Pay-off' then 
		coalesce(
				iif(
					(n.coef + RiskDWH.Risk.func$migr_matr_payoff_0(a.mob_to, cv.vers)
							* isnull(adj.coef * case when year(a.mob_date_to) = 2025 then 0.9 else 1 end, 1)
					) * isnull(sts.koef_po,1) > 1
					, 1 
					, (n.coef + RiskDWH.Risk.func$migr_matr_payoff_0(a.mob_to, cv.vers)
							* isnull(adj.coef * case when year(a.mob_date_to) = 2025 then 0.9 else 1 end, 1)
						) * isnull(sts.koef_po,1)
					)
				, 0)
		---90+ и pay-down - поглощающие бакеты
		when a.bucket_90_from = '[05] 90+' and a.bucket_90_to = '[05] 90+' then 1
		when a.bucket_90_from = '[06] Pay-off' and a.bucket_90_to = '[06] Pay-off' then 1
		when a.bucket_90_from in ('[05] 90+','[06] Pay-off') then 0
		---перескоки через бакеты
		when cast(substring(a.bucket_90_from,2,2) as int) - cast(substring(a.bucket_90_to,2,2) as int) between -4 and -2 and a.bucket_90_to <> '[06] Pay-off' then 0
		---"недозревшие инстолменты", которые по факту дозревают 20.04.2022
		when a.flag_kk = 'INSTALLMENT' and a.bucket_90_from = '[02] 1-30'	and a.bucket_90_to = '[03] 31-60'	and a.mob_from between 0 and 0 
			then RiskDWH.[CM\A.Borisov].func$least( 0.569356717307052, 1.0)
		when a.flag_kk = 'INSTALLMENT' and a.bucket_90_from = '[03] 31-60'	and a.bucket_90_to = '[04] 61-90'	and a.mob_from between 0 and 1 
			then RiskDWH.[CM\A.Borisov].func$least( 0.872100203727674, 1.0)
		when a.flag_kk = 'INSTALLMENT' and a.bucket_90_from = '[04] 61-90'	and a.bucket_90_to = '[05] 90+'		and a.mob_from between 0 and 2 
			then RiskDWH.[CM\A.Borisov].func$least( 0.91828149902979, 1.0)
	
		---только для дозревших
		when cast(substring(a.bucket_90_from,2,2) as int) > a.mob_to and a.flag_kk <> 'INSTALLMENT' /*20.04.2022*/ then 0

		---worsening
		when a.bucket_90_from = '[01] 0' and a.bucket_90_to = '[02] 1-30'
		then iif( RiskDWH.Risk.func$migr_matr_worse_0(a.mob_to, cv.vers) * isnull(adj.coef,1) * isnull(sts.koef_worse,1) > 1, --28.02.2022
				1,
				RiskDWH.Risk.func$migr_matr_worse_0(a.mob_to, cv.vers) * isnull(adj.coef,1) * isnull(sts.koef_worse,1) --28.02.2022
				)

		when a.bucket_90_from = '[02] 1-30' and a.bucket_90_to = '[03] 31-60'
		then iif(RiskDWH.Risk.func$migr_matr_worse_1_30(a.mob_to, cv.vers) * isnull(adj.coef,1) * isnull(sts.koef_worse,1) > 1, --28.02.2022
				1,
				RiskDWH.Risk.func$migr_matr_worse_1_30(a.mob_to, cv.vers) * isnull(adj.coef,1) * isnull(sts.koef_worse,1) --28.02.2022
				)

		when a.bucket_90_from = '[03] 31-60' and a.bucket_90_to = '[04] 61-90'
		then iif( RiskDWH.Risk.func$migr_matr_worse_31_60(a.mob_to, cv.vers) * isnull(adj.coef,1) * isnull(sts.koef_worse,1) > 1, --28.02.2022
				1,
				RiskDWH.Risk.func$migr_matr_worse_31_60(a.mob_to, cv.vers) * isnull(adj.coef,1) * isnull(sts.koef_worse,1) --28.02.2022
				)

		when a.bucket_90_from = '[04] 61-90' and a.bucket_90_to = '[05] 90+'
		then iif( RiskDWH.Risk.func$migr_matr_worse_61_90(a.mob_to, cv.vers) * isnull(adj.coef,1) * isnull(sts.koef_worse,1) > 1, --28.02.2022
				1,
				RiskDWH.Risk.func$migr_matr_worse_61_90(a.mob_to, cv.vers) * isnull(adj.coef,1) * isnull(sts.koef_worse,1) --28.02.2022
				)

		--ПТС31 первые 4 доступных моб-а (пролонгации)
		when a.segment_rbp = 'PTS31' and a.bucket_90_from = '[01] 0' and a.bucket_90_to = '[01] 0' and a.mob_to <= 4 then 0.78
		when a.segment_rbp = 'PTS31' and a.bucket_90_from = '[02] 1-30' and a.bucket_90_to = '[01] 0' and a.mob_to between 1 and 5 then 0.143
		when a.segment_rbp = 'PTS31' and a.bucket_90_from = '[02] 1-30' and a.bucket_90_to = '[02] 1-30' and a.mob_to between 1 and 5 then 0.021
		when a.segment_rbp = 'PTS31' and a.bucket_90_from = '[02] 1-30' and a.bucket_90_to = '[06] Pay-off' and a.mob_to between 1 and 5 then 0.177
		when a.segment_rbp = 'PTS31' and a.bucket_90_from = '[03] 31-60' and a.bucket_90_to = '[06] Pay-off' and a.mob_to between 2 and 6 then 0.264
		when a.segment_rbp = 'PTS31' and a.bucket_90_from = '[04] 61-90' and a.bucket_90_to = '[06] Pay-off' and a.mob_to between 3 and 7 then 0.09

		else coalesce(n.coef,
					r.coef,
					--* case 
					--	when a.bucket_90_to = '[06] Pay-off' then isnull(sts.koef_po,1.0) else 1.0
					--	--when a.bucket_90_from = a.bucket_90_to then isnull(sts.koef_po,1) 
					--  end, --28.02.2022
					 0) 
				
		end as model_coef,

		case 
			when cast(substring(a.bucket_90_from,2,2) as int) - cast(substring(a.bucket_90_to,2,2) as int) = -1 
				and a.bucket_90_from in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90') then 1
			when n.coef is not null then 1 else 0 end
		as flag_static

		from Temp_PTS_Test_stg_back_base a

		left join Temp_PTS_Test_nodpd_payoff_model n
		on a.term = n.term
		and a.bucket_90_from = n.bucket_from
		and a.bucket_90_to = n.bucket_to
		and a.mob_to = n.mob
		--and case when a.flag_kk in ('Installment','BUSINESS') then a.flag_kk else 'PTS' end = n.product
		and case when a.segment_rbp = 'PTS31' then 'PTS31'
				when a.segment_rbp = 'PTS31_RBP4' then 'PTS31_RBP4'
				when a.flag_kk in ('Installment','BUSINESS') then a.flag_kk else 'PTS' end = n.product
		and a.generation between n.gen_from and n.gen_to --28.02.2022

		left join Temp_PTS_Test_rest_model r
		on 1=1
		--and a.term = r.term
		and a.bucket_90_from = r.bucket_90_from
		and a.bucket_90_to = r.bucket_90_to
		--and a.mob_to = r.mob_to
		--and case when a.flag_kk in ('Installment','BUSINESS') then a.flag_kk else 'PTS' end = r.product
		and case when a.segment_rbp = 'PTS31' then 'PTS31' 
				when a.segment_rbp = 'PTS31_RBP4' then 'PTS31_RBP4'
				when a.flag_kk in ('Installment','BUSINESS') then a.flag_kk else 'PTS' end = r.product



		left join Temp_PTS_Test_model_adjust adj
		on a.segment_rbp = adj.segment_rbp
		and a.term = adj.term
		and a.bucket_90_from = adj.bucket_from
		and a.bucket_90_to = adj.bucket_to
		and case 
		when a.flag_kk in ('Installment','BUSINESS') then a.flag_kk else 'PTS' end = adj.product

		left join Temp_PTS_Test_det_stress sts
		on a.mob_date_to between sts.dt_from and sts.dt_to

		left join Temp_PTS_Test_det_curve_version cv
		on case 
		when a.flag_kk in ('Installment','BUSINESS') then a.flag_kk else 'REST' end = cv.product
		and a.segment_rbp = cv.segment_rbp
		and a.bucket_90_from = cv.bucket_from
		and a.bucket_90_to = cv.bucket_to

		where 1=1

	), znam as (
		select b.generation, b.term, b.segment_rbp, b.flag_kk, b.mob_to, b.bucket_90_from, 
		sum(b.model_coef) - sum(b.model_coef * b.flag_static) as corr1,
		1.0 - sum(b.model_coef * b.flag_static) as corr2
		from base b
		group by b.generation, b.term, b.segment_rbp, b.flag_kk, b.mob_to, b.bucket_90_from

	)
	select 
		hashbytes('MD2',concat(b.term, b.segment_rbp, b.generation, b.flag_kk)) as id1,
		b.term, b.segment_rbp, b.flag_kk, b.generation, b.mob_date_to, b.mob_to, b.bucket_90_from, b.bucket_90_to, 
		b.fact_coef, b.model_coef, b.flag_static,
		z.corr1, z.corr2,

		case 
			when cast(substring(b.bucket_90_from,2,2) as int) > b.mob_to and b.flag_kk <> 'INSTALLMENT' /*20.04.2022*/ then b.model_coef
			when b.flag_static = 1 and z.corr2 >= 0 then b.model_coef
			when b.flag_static = 1 and z.corr2 < 0 then b.model_coef / (1.0 + (-1.0) * z.corr2)
			when z.corr2 < 0 then 0

			when z.corr1 = 0 and b.bucket_90_to = '[06] Pay-off' then z.corr2
			when z.corr1 = 0 then 0
			else b.model_coef / z.corr1 * z.corr2 end
		as model_coef_adj


	into Temp_PTS_Test_for_back_test
	from base b
	left join znam z
	on b.term = z.term
		and b.generation = z.generation
		and b.flag_kk = z.flag_kk
		and b.mob_to = z.mob_to
		and b.bucket_90_from = z.bucket_90_from
		and b.segment_rbp = z.segment_rbp
	;



	--02/09/2021 - сезонность
	---1) В декабре повышается Recovery => переход в Pay-off
	drop table if exists Temp_PTS_Test_season_rr_corr;
	with base as (
		select distinct 
			a.id1,
			--a.term, a.segment_rbp, a.flag_kk, a.generation, 
			a.mob_date_to, a.bucket_90_from
		from Temp_PTS_Test_for_back_test a
		where 1=1
			and a.bucket_90_from not in ('[05] 90+','[06] Pay-off')
			and month(a.mob_date_to) = 12
			and cast(SUBSTRING(a.bucket_90_from,2,2) as int) = cast(SUBSTRING(a.bucket_90_to,2,2) as int) - 1 --worse
			and a.mob_to <= a.term
			and a.model_coef_adj > 0.0301 --worse не менее 3%, чтобы небыло отрицательных коэф-ов матрицы
	)
	select 
		a.id1,
		--a.term, a.segment_rbp, a.flag_kk, a.generation, 
		a.mob_date_to, a.bucket_90_from, a.bucket_90_to,
		a.model_coef_adj,
		case 
			--корректировка worse на 3% 
			when cast(SUBSTRING(a.bucket_90_from,2,2) as int) = cast(SUBSTRING(a.bucket_90_to,2,2) as int) - 1 then a.model_coef_adj - 0.03
			--переходы вниз поровну - всего 3%, чтобы общая сумма была 1 (условие матрицы миграции)
			when cast(SUBSTRING(a.bucket_90_from,2,2) as int) >= cast(SUBSTRING(a.bucket_90_to,2,2) as int) 
				then a.model_coef_adj + 0.03 / (cast(SUBSTRING(a.bucket_90_from,2,2) as float) + 1)
			--переход в pay-off
			when a.bucket_90_to = '[06] Pay-off' then a.model_coef_adj + 0.03 / (cast(SUBSTRING(a.bucket_90_from,2,2) as float) + 1)

			else a.model_coef_adj end
		as new_model_coef_adj

	into Temp_PTS_Test_season_rr_corr
	from Temp_PTS_Test_for_back_test a
	inner join base b
	on 1=1
	and a.id1 = b.id1
	--and a.term = b.term
	--and a.segment_rbp = b.segment_rbp
	--and a.flag_kk = b.flag_kk
	--and a.generation = b.generation
	and a.mob_date_to = b.mob_date_to
	and a.bucket_90_from = b.bucket_90_from
	;


	---2) в январе обратный эффект
	with base as (
		select 
			a.id1,
			--a.term, a.segment_rbp, a.flag_kk, a.generation, 
			a.mob_date_to, a.bucket_90_from
		from Temp_PTS_Test_for_back_test a
		where 1=1
			and a.bucket_90_from not in ('[05] 90+','[06] Pay-off')
			and month(a.mob_date_to) = 1
			 --Improve or Same or Pay-off
			and (cast(SUBSTRING(a.bucket_90_from,2,2) as int) >= cast(SUBSTRING(a.bucket_90_to,2,2) as int) or a.bucket_90_to = '[06] Pay-off')
			and a.mob_to <= a.term	
		group by
			a.id1,
			--a.term, a.segment_rbp, a.flag_kk, a.generation, 
			a.mob_date_to, a.bucket_90_from
			 --min(pay-off + improve) не менее 3%/(кол-во возможных переходов) , чтобы небыло отрицательных коэф-ов матрицы
		having min(a.model_coef_adj) > 0.0301 / (cast(SUBSTRING(a.bucket_90_from,2,2) as float) + 1) 
	)
	insert into Temp_PTS_Test_season_rr_corr

	select 
		a.id1,
		--a.term, a.segment_rbp, a.flag_kk, a.generation, 
		a.mob_date_to, a.bucket_90_from, a.bucket_90_to,
		a.model_coef_adj,
		case 
			--корректировка worse на 3% 
			when cast(SUBSTRING(a.bucket_90_from,2,2) as int) = cast(SUBSTRING(a.bucket_90_to,2,2) as int) - 1 then a.model_coef_adj + 0.03
			--переходы вниз поровну - всего 3%, чтобы общая сумма была 1 (условие матрицы миграции)
			when cast(SUBSTRING(a.bucket_90_from,2,2) as int) >= cast(SUBSTRING(a.bucket_90_to,2,2) as int) 
				then a.model_coef_adj - 0.03 / (cast(SUBSTRING(a.bucket_90_from,2,2) as float) + 1)
			--переход в pay-off
			when a.bucket_90_to = '[06] Pay-off' then a.model_coef_adj - 0.03 / (cast(SUBSTRING(a.bucket_90_from,2,2) as float) + 1)

			else a.model_coef_adj
		end
		as new_model_coef_adj

	from Temp_PTS_Test_for_back_test a
	inner join base b
	on 1=1
		and a.id1 = b.id1
		--and a.term = b.term
		--and a.segment_rbp = b.segment_rbp
		--and a.flag_kk = b.flag_kk
		--and a.generation = b.generation
		and a.mob_date_to = b.mob_date_to
		and a.bucket_90_from = b.bucket_90_from

	;

	merge into Temp_PTS_Test_for_back_test a
	using Temp_PTS_Test_season_rr_corr b
	on (1=1
		--and a.term = b.term
		--and a.segment_rbp = b.segment_rbp
		--and a.flag_kk = b.flag_kk
		--and a.generation = b.generation
		and a.id1 = b.id1
		and a.mob_date_to = b.mob_date_to
		and a.bucket_90_from = b.bucket_90_from
		and a.bucket_90_to = b.bucket_90_to)
	when matched then update set a.model_coef_adj = b.new_model_coef_adj;


	--бакет "Заморозка"

	update Temp_PTS_Test_for_back_test set model_coef_adj = 0 where bucket_90_from = '[07] Freeze' or bucket_90_to = '[07] Freeze';

	--Цессии, на конец месяца продажи обнуляются все бакеты по FLAG_KK = "CESS YYYY-MM-DD"

	update a 
	set a.model_coef_adj = 0
	from Temp_PTS_Test_for_back_test a
	where a.flag_kk like 'CESS%'
	and a.mob_date_to >= cast(substring(a.flag_kk,6,10) as date)
	;

	--Банкроты 
	update a
	set a.model_coef_adj = 1
	from Temp_PTS_Test_for_back_test a
	where a.flag_kk in ('BANKRUPT')
	and cast(substring(a.bucket_90_from,2,2) as int) = cast(substring(a.bucket_90_to,2,2) as int) - 1
	and a.bucket_90_from not in ('[05] 90+','[06] Pay-off')
	;


	update a
	set a.model_coef_adj = 0
	from Temp_PTS_Test_for_back_test a
	where a.flag_kk in ('BANKRUPT')
	and not (cast(substring(a.bucket_90_from,2,2) as int) = cast(substring(a.bucket_90_to,2,2) as int) - 1)
	and a.bucket_90_from not in ('[05] 90+','[06] Pay-off')
	;




	--Корректировка для платежей последнего фактического поколения:
	---модель рассчитывает платеж за 0-ой и 1-моб сразу, а для этого поколения уже есть фактические платежи в 0-м МоБе


	drop table if exists Temp_PTS_Test_pmt_last_gen_0_MoB;
	select 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, a.segment_rbp, a.generation, a.flag_kk, 
	--sum(cast(isnull(b.principal_cnl,0) as float)) as od_pmt
	sum(isnull(b.principal_cnl,0)) as od_pmt 
	into Temp_PTS_Test_pmt_last_gen_0_MoB
	from Temp_PTS_Test_cred_reestr a
	--left join dwh_new.dbo.stat_v_balance2 b
	left join Temp_PTS_Test_stg_payment b
	on a.external_id = b.external_id
	and b.cdate between dateadd(dd,1,eomonth(a.generation,-1)) and a.generation
	where a.generation = @rdt
	group by hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.segment_rbp, a.generation, a.flag_kk
	;



	drop table if exists Temp_PTS_Test_fix_matrix;
	with volume as (
		select 
		hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
		a.term, a.segment_rbp, a.generation, a.flag_kk, 
		sum(a.amount) as amount
		from Temp_PTS_Test_cred_reestr a
		where a.generation = @rdt
		group by hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
		a.term, a.segment_rbp, a.generation, a.flag_kk
	)
	select a.id1,
		a.mob_date_to,
		a.bucket_90_from,
		a.bucket_90_to,
		case 
			when c.amount * a.model_coef_adj - b.od_pmt < 0 
			then -1.0 * a.model_coef_adj
			else -1.0 * b.od_pmt / c.amount end
		as corr
	into Temp_PTS_Test_fix_matrix
	from Temp_PTS_Test_for_back_test a
	left join Temp_PTS_Test_pmt_last_gen_0_MoB b
	on a.id1 = b.id1
	left join volume c
	on a.id1 = c.id1
	where a.generation = @rdt
	and a.mob_to = 1
	and a.bucket_90_from = '[01] 0'
	and a.bucket_90_to = '[06] Pay-off'
	;


	--если реальный платеж превысил модельный платеж за 0-ой и 1-ый MoB, сокращаем остаток на сумму превышения
	with volume as (
		select 
			hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
			a.term, a.segment_rbp, a.generation, a.flag_kk, 
			sum(a.amount) as amount
		from Temp_PTS_Test_cred_reestr a
		where a.generation = @rdt
		group by hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
			a.term, a.segment_rbp, a.generation, a.flag_kk
	)
	insert into Temp_PTS_Test_fix_matrix

	select a.id1,
		a.mob_date_to,
		a.bucket_90_from,
		'[01] 0' as bucket_90_to,
		case 
			when c.amount * a.model_coef_adj - b.od_pmt < 0 
			then (c.amount * a.model_coef_adj - b.od_pmt) / c.amount 
			--else b.od_pmt / c.amount 
			else 0 end
		as corr
	from Temp_PTS_Test_for_back_test a
	left join Temp_PTS_Test_pmt_last_gen_0_MoB b
	on a.id1 = b.id1
	left join volume c
	on a.id1 = c.id1
	where a.generation = @rdt
	and a.mob_to = 1
	and a.bucket_90_from = '[01] 0'
	and a.bucket_90_to = '[06] Pay-off'
	;


	update a set a.model_coef_adj = a.model_coef_adj + b.corr
	from Temp_PTS_Test_for_back_test a
	inner join Temp_PTS_Test_fix_matrix b
	on a.id1 = b.id1
	and a.bucket_90_from = b.bucket_90_from
	and a.bucket_90_to = b.bucket_90_to
	and a.mob_date_to = b.mob_date_to
	;



	drop table Temp_PTS_Test_pmt_last_gen_0_MoB;

	--проверка 
	/*
	--сумма по строке матрицы равна 1?
	select a.segment_rbp, a.term, a.flag_kk, a.generation, a.mob_to, a.bucket_90_from, round(sum(a.model_coef_adj),2)
	from Temp_PTS_Test_for_back_test a
	where cast(substring(a.bucket_90_from,2,2) as int) <= a.mob_to
	group by a.segment_rbp, a.term, a.flag_kk, a.generation, a.mob_to, a.bucket_90_from
	having round(sum(a.model_coef_adj),6) <> 1
	order by 1,2,3

	--есть ли отрицательные элементы матрицы?
	select * from Temp_PTS_Test_for_back_test a
	where a.model_coef_adj < 0
	;
	*/

	/*
	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_from, sum(a.new_model_coef_adj)
	from Temp_PTS_Test_season_rr_corr a
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_from
	having round(sum(a.new_model_coef_adj),2) <> 1
	*/




	print ('timing, Temp_PTS_Test_for_back_test' + format(getdate(), 'HH:mm:ss'))


	------------------------------




	drop table if exists Temp_PTS_Test_back_test_acc_matr;
	create table Temp_PTS_Test_back_test_acc_matr (
	id1 int,
	generation date,
	term int,
	segment_rbp varchar(100),
	flag_kk varchar(100),
	mob_date_to date,
	mob_to int,
	bucket_90_from varchar(100),
	bucket_90_to varchar(100),
	fact_coef float,
	model_coef_adj float
	);




	--цикл - шаг 0
	insert into Temp_PTS_Test_back_test_acc_matr
	select 
	a.id1,
	a.generation, a.term, a.segment_rbp, a.flag_kk, 
	a.mob_date_to, a.mob_to, a.bucket_90_from, a.bucket_90_to, a.fact_coef, a.model_coef_adj
	from Temp_PTS_Test_for_back_test a 
	where a.mob_date_to = @dt_back_test_from
	;




	drop table if exists Temp_PTS_Test_temp1_back_test_acc_matr;
	select top 0 
	a.id1,
	a.generation, a.term, a.segment_rbp, a.flag_kk, 
	a.mob_to, a.bucket_90_from, a.bucket_90_to, a.fact_coef, a.model_coef_adj
	into Temp_PTS_Test_temp1_back_test_acc_matr
	from Temp_PTS_Test_back_test_acc_matr a;

	drop table if exists Temp_PTS_Test_temp2_back_test_acc_matr;
	select *
	into Temp_PTS_Test_temp2_back_test_acc_matr--select top 5 *
	from Temp_PTS_Test_back_test_acc_matr a;





	print ('timing, Temp_PTS_Test_back_test_acc_matr iter 0 ' + format(getdate(), 'HH:mm:ss'));



	declare @k date = @dt_back_test_from ;

	while @k < EOMONTH(@dt_back_test_from, @horizon) 
	begin


		truncate table Temp_PTS_Test_temp1_back_test_acc_matr
		insert into Temp_PTS_Test_temp1_back_test_acc_matr
		select 
		a.id1,
		a.generation, a.term, a.segment_rbp, a.flag_kk, 
		a.mob_to, a.bucket_90_from, a.bucket_90_to, a.fact_coef, a.model_coef_adj
		from Temp_PTS_Test_temp2_back_test_acc_matr a
		--where a.mob_date_to = @k;


		--умножение на следующую матрицу
		truncate table Temp_PTS_Test_temp2_back_test_acc_matr;
		insert into Temp_PTS_Test_temp2_back_test_acc_matr
		select 
		a.id1,
		a.generation, a.term, a.segment_rbp, a.flag_kk, b.mob_date_to, b.mob_to, a.bucket_90_from, b.bucket_90_to,
		sum(a.fact_coef * b.fact_coef) as fact_coef,
		sum(a.model_coef_adj * b.model_coef_adj) as model_coef_adj
		from Temp_PTS_Test_temp1_back_test_acc_matr a
		left join Temp_PTS_Test_for_back_test b
		on 1 = 1
		and a.id1 = b.id1
		--and a.term = b.term
		--and a.generation = b.generation
		--and a.segment_rbp = b.segment_rbp
		--and a.flag_kk = b.flag_kk
		and a.bucket_90_to = b.bucket_90_from
		--and a.mob_date_to = eomonth(b.mob_date_to,-1)
		and a.mob_to = b.mob_to - 1		
		group by a.id1, a.generation, a.term, a.segment_rbp, a.flag_kk, b.mob_date_to, b.mob_to, a.bucket_90_from, b.bucket_90_to
		;


		insert into Temp_PTS_Test_temp2_back_test_acc_matr
		select a.id1,
		a.generation, a.term, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mob_to, a.bucket_90_from, a.bucket_90_to, a.fact_coef, a.model_coef_adj
		from Temp_PTS_Test_for_back_test a 
		where 1=1
		and a.mob_date_to > @dt_back_test_from
		and a.mob_date_to = eomonth(a.generation,1)
		and a.mob_date_to = @k
		;


		insert into Temp_PTS_Test_back_test_acc_matr
		select * from Temp_PTS_Test_temp2_back_test_acc_matr;



		print ('timing, Temp_PTS_Test_back_test_acc_matr @k = ' + format(@k, 'dd.MM.yyyy') + ' ' + format(getdate(), 'HH:mm:ss'));

		set @k = EOMONTH(@k,1)

	end;

	drop table Temp_PTS_Test_temp1_back_test_acc_matr;
	drop table Temp_PTS_Test_temp2_back_test_acc_matr;



	print ('timing, Temp_PTS_Test_back_test_acc_matr' + format(getdate(), 'HH:mm:ss'))




	--16/06/2021 - new vers of Temp_PTS_Test_last_fact by mob_date_to



	drop table if exists Temp_PTS_Test_last_fact;

	select 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mob_to, 
	a.bucket_90_to as bucket_90_from, 
	sum(a.od_to) as total_od_from

	into Temp_PTS_Test_last_fact
	from Temp_PTS_Test_stg3_agg a
	where a.mob_date_to = eomonth(@dt_back_test_from,-1)
	and a.generation <= eomonth(@rdt,-1)
	group by 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mob_to, a.bucket_90_to
	;


	;
	--новые выдачи для back-теста
	with base as (
	select distinct a.term, a.segment_rbp, a.flag_kk, a.generation, a.total_od_from 
	from Temp_PTS_Test_stg3_agg a
	where 1=1
	and a.mob_from = 0
	and a.bucket_90_from = '[01] 0'
	and a.generation > (select max(generation) from Temp_PTS_Test_last_fact)
	and a.generation <= EOMONTH(@rdt, -1)
	), buck as (
	select '[01] 0' as bucket union all
	select '[02] 1-30' as bucket union all
	select '[03] 31-60' as bucket union all
	select '[04] 61-90' as bucket union all
	select '[05] 90+' as bucket union all
	select '[06] Pay-off' as bucket
	)
	insert into Temp_PTS_Test_last_fact

	select 
	hashbytes('MD2',concat(s.term, s.segment_rbp, s.generation, s.flag_kk)) as id1,
	s.term,  s.generation, s.segment_rbp, s.flag_kk, eomonth(s.generation,1) as mob_date_to, 1 as mob_to, b.bucket as bucket_90_to,
	iif(b.bucket = '[01] 0', s.total_od_from, 0) as total_od_from

	from buck b
	left join base s
	on 1 = 1



	;
	--выдачи последнего доступного месяца для прогноза 


	--XXX--выдачи последнего доступного месяца для прогноза v.2 - остаток ОД на 0 MoB
	--выдачи последнего доступного месяца для прогноза v.3 - сумма выдачи
	with buck as (
	select '[01] 0' as bucket union all
	select '[02] 1-30' as bucket union all
	select '[03] 31-60' as bucket union all
	select '[04] 61-90' as bucket union all
	select '[05] 90+' as bucket union all
	select '[06] Pay-off' as bucket
	)
	insert into Temp_PTS_Test_last_fact

	select 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, a.generation, a.segment_rbp, a.flag_kk, a.generation as mob_date_to, 0 as mob_to, c.bucket as bucket_to,
	--sum(iif(c.bucket = '[01] 0', cast(coalesce(b.[остаток од],a.amount, 0) as float), 0)) as total_od_from
	--sum(iif(c.bucket = '[01] 0', cast(coalesce(b.[остаток од],0) as float), 0)) as total_od_from
	sum(iif(c.bucket = '[01] 0', a.amount, 0)) as total_od_from
	from Temp_PTS_Test_cred_reestr a
	cross join buck c
	where a.generation >= @rdt
	group by 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.generation, a.segment_rbp, a.flag_kk, c.bucket
	;





	--выдачи виртуальных поколений
	with buck as (
	select '[01] 0' as bucket union all
	select '[02] 1-30' as bucket union all
	select '[03] 31-60' as bucket union all
	select '[04] 61-90' as bucket union all
	select '[05] 90+' as bucket union all
	select '[06] Pay-off' as bucket
	)
	insert into Temp_PTS_Test_last_fact

	select 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, a.generation, a.segment_rbp, a.flag_kk, a.generation as mob_date_to, 0 as mob_to, b.bucket as bucket_to,
	sum(iif(b.bucket = '[01] 0', a.vl_rub_fact, 0)) as total_od_from
	from Temp_PTS_Test_virt_gens a
	left join buck b
	on 1=1
	group by 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.generation, a.segment_rbp, a.flag_kk, b.bucket
	;




	print ('timing, Temp_PTS_Test_last_fact' + format(getdate(), 'HH:mm:ss'))



	--comparison (back-test fact<->model)
	drop table if exists Temp_PTS_Test_back_test;
	select a.term, a.segment_rbp, a.flag_kk, a.generation, b.mob_date_to, b.mob_to, b.bucket_90_to, 
	sum(a.total_od_from * b.fact_coef) as fact_od,
	sum(a.total_od_from * b.model_coef_adj) as model_od

	into Temp_PTS_Test_back_test
	from Temp_PTS_Test_last_fact a
	left join Temp_PTS_Test_back_test_acc_matr b
	on a.id1 = b.id1
	--and a.generation = b.generation
	--and a.term = b.term
	--and a.segment_rbp = b.segment_rbp
	--and a.flag_kk = b.flag_kk
	and a.bucket_90_from = b.bucket_90_from

	where a.generation is not null --17/06/2021 чтобы не тянуть пустые строки

	group by a.term, a.segment_rbp, a.flag_kk, a.generation, b.mob_date_to, b.mob_to, b.bucket_90_to
	;



	print ('timing, Temp_PTS_Test_back_test' + format(getdate(), 'HH:mm:ss'))

	-----------------------------------------------------





	/***************  Расчет для Заморозки и Кредитных каникул  ***************/





	----Цикл, шаг 0 - первая прогнозная дата

	---послений факт с датами заморозки

	drop table if exists Temp_PTS_Test_freeze_last_fact;
	select 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mob_to, a.bucket_90_to as bucket_90_from,
	sum(a.principal_rest_to) as total_od_from, b.freeze_from, 
	case 
	when f.mod_num is not null then f.mod_num
	when a.bucket_90_to = '[05] 90+' then DATEDIFF(MM, dd.month_default_from, a.mob_date_to) 
	end as mod_num,

	cast(case 
	when a.bucket_90_to = '[07] Freeze' and f.mod_num is not null then f.mod_num
	when a.bucket_90_to = '[01] 0' and a.mob_date_to >= b.freeze_to and f.mod_num is not null then f.mod_num --12/11/2021
	when a.bucket_90_to = '[05] 90+' then floor((cast(a.dpd_to as float) - 91.0) / 30.0) --DATEDIFF(MM, dd.month_last_default_from, a.mob_date_to) 
	end as int) as last_MOD

	into Temp_PTS_Test_freeze_last_fact
	from Temp_PTS_Test_stg_matrix_detail a
	left join Temp_PTS_Test_zamorozka b
	on a.external_id = b.external_id
	and a.mob_date_to >= b.freeze_from
	left join Temp_PTS_Test_stg_start_default dd
	on a.external_id = dd.external_id
	and a.mob_date_to >= dd.month_default_from
	left join Temp_PTS_Test_stg_freeze_mod f
	on a.external_id = f.external_id

	where a.mob_date_to = eomonth(@dt_back_test_from,-1)
	and a.bucket_90_to <> '[06] Pay-off'
	and left(a.flag_kk,2) = 'KK'
	group by 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mob_to, a.bucket_90_to, b.freeze_from,
	case 
	when f.mod_num is not null then f.mod_num
	when a.bucket_90_to = '[05] 90+' then DATEDIFF(MM, dd.month_default_from, a.mob_date_to) 
	end,
	cast(case 
	when a.bucket_90_to = '[07] Freeze' and f.mod_num is not null then f.mod_num
	when a.bucket_90_to = '[01] 0' and a.mob_date_to >= b.freeze_to and f.mod_num is not null then f.mod_num --12/11/2021
	when a.bucket_90_to = '[05] 90+' then floor((cast(a.dpd_to as float) - 91.0) / 30.0) --DATEDIFF(MM, dd.month_last_default_from, a.mob_date_to) 
	end as int)
	;


	-- + payoff
	insert into Temp_PTS_Test_freeze_last_fact
	select 
	a.id1,
	a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mob_to, a.bucket_90_from as bucket_90_to, 
	a.total_od_from as od, cast(null as date) as freeze_from, cast(null as int) as mod_num, cast(null as int) as last_MOD
	from Temp_PTS_Test_last_fact a
	where a.mob_date_to = eomonth(@dt_back_test_from,-1)
	and a.bucket_90_from = '[06] Pay-off'
	and left(a.flag_kk,2) = 'KK'
	;




	-- + последнее фактическое поколение
	insert into Temp_PTS_Test_freeze_last_fact
	select hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, a.generation, a.segment_rbp, a.flag_kk, a.generation as mob_date_to, 
	0 as mob_to, 
	'[01] 0' as bucket_90_from,
	sum(a.amount) as total_od_from, 
	b.freeze_from,
	0 as mod_num,
	0 as last_MOD
	from Temp_PTS_Test_cred_reestr a
	left join Temp_PTS_Test_zamorozka b
	on a.external_id = b.external_id
	and a.generation >= b.freeze_from
	where left(a.flag_kk,2) = 'KK'
	and a.generation = eomonth(@dt_back_test_from,-1)
	group by hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.generation, a.segment_rbp, a.flag_kk,
	b.freeze_from
	;




	print ('timing, Temp_PTS_Test_freeze_last_fact ' + format(getdate(), 'HH:mm:ss'))




	drop table if exists Temp_PTS_Test_stg_freeze_model;

	create table Temp_PTS_Test_stg_freeze_model (
	id1 int,
	term int,
	segment_rbp varchar(100),
	flag_kk varchar(100),
	generation date, 
	mob_date_to date,
	mob_to int,
	bucket_90_from varchar(100),
	bucket_90_to varchar(100),
	model_od float,
	freeze_from date,
	mod_num int,
	last_MOD int
	)
	;




	---новая заморозка: [31-60] - 70%, [61-90] - 10%

	insert into Temp_PTS_Test_stg_freeze_model
	select 
	a.id1,
	a.term, 
	a.segment_rbp,
	a.flag_kk,
	a.generation, 
	eomonth(a.mob_date_to,1) as mob_date_to,
	a.mob_to + 1 as mob_to,
	a.bucket_90_from, 
	cast('[07] Freeze' as varchar(100)) as bucket_90_to,
	sum( a.total_od_from * 
	case 
	when a.bucket_90_from = '[03] 31-60' then 0.75 
	when a.bucket_90_from = '[04] 61-90' then 0.15 
	else 0.0
	end ) as model_od,
	eomonth(a.mob_date_to,1) as freeze_from,
	--cast(null as int) as mod_num
	case
	when a.bucket_90_from = '[03] 31-60' then 10000
	when a.bucket_90_from = '[04] 61-90' then 20000
	end as mod_num,

	case
	when a.bucket_90_from = '[03] 31-60' then 10000
	when a.bucket_90_from = '[04] 61-90' then 20000
	end as last_MOD

	from Temp_PTS_Test_freeze_last_fact a
	where left(a.flag_kk,2) = 'KK'
	and a.bucket_90_from in ('[03] 31-60','[04] 61-90')
	and a.mob_date_to = eomonth(@dt_back_test_from,-1)
	--and a.total_od_from > 0
	and a.freeze_from is null --без повторных, только продление
	--and a.mob_date_to < '2021-12-31' --последняя заморозка в декабре
	and a.mob_date_to < '2021-10-31' --последняя заморозка в Октябре --06/12/2021 
	group by 
	a.id1,
	a.term, 
	a.segment_rbp,
	a.flag_kk,
	a.generation, 
	eomonth(a.mob_date_to,1),
	a.mob_to + 1,
	a.bucket_90_from, 
	eomonth(a.mob_date_to,1),
	case when a.bucket_90_from = '[03] 31-60' then 10000 when a.bucket_90_from = '[04] 61-90' then 20000 end

	;





	---заморозка продолжается в течение 3 месяцев
	---если срок прошел, то выход в 90+, определенный процент, с учетом наличия решения (примерная оценка)
	--- ИЛИ продление заморозки - 30% (примерная оценка по итогам августа)
	---если нет, то дальше в заморозку
	with base as (
		select 
		a.id1,
		a.term, 
		a.segment_rbp,
		a.flag_kk,
		a.generation, 
		eomonth(a.mob_date_to,1) as mob_date_to,
		a.mob_to + 1 as mob_to,
		a.bucket_90_from,
		a.total_od_from as od,
		a.freeze_from,
		eomonth(a.freeze_from,4) as freeze_to,
		a.mod_num,
		a.last_MOD
		from Temp_PTS_Test_freeze_last_fact a	
		where left(a.flag_kk,2) = 'KK'
		and a.bucket_90_from = '[07] Freeze'
		and a.mob_date_to = eomonth(@dt_back_test_from,-1)
	), un as (
	--продолжение первой заморозки
		select a.id1,
		a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
		a.bucket_90_from,
		cast('[07] Freeze' as varchar(100)) as bucket_90_to,
		a.od as model_od,
		a.freeze_from,
		a.mod_num + 1 as mod_num,
		a.last_MOD + 1 as last_MOD
		from base a
		where (a.mob_date_to < eomonth(a.freeze_from,4) or a.mob_date_to between eomonth(a.freeze_from,5) and eomonth(a.freeze_from,7) )

	union all

	--выход из заморозки в 90+ (историческая просрочка)
		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
		a.bucket_90_from,
		RiskDWH.dbo.get_bucket_90((case when a.mod_num between 10000 and 19999 then 0
		when a.mod_num between 20000 and 29999 then 1
		else a.mod_num + 1 end) * 30 + 91) as bucket_90_to, 
	
		a.od * /*0.65*/ 0.85 * iif(a.mob_date_to <= '2021-10-31', 1.0 - @repeat_share , 1.0) as model_od, --11.02.2022
		a.freeze_from,
		case when a.mod_num between 10000 and 19999 then 0
		when a.mod_num between 20000 and 29999 then 1
		else iif(a.mod_num + 1 >= 0, a.mod_num + 1, null) end as mod_num,

		case when a.last_MOD between 10000 and 19999 then 0
		when a.last_MOD between 20000 and 29999 then 1
		else iif(a.last_MOD + 1 >= 0, a.last_MOD + 1, null) end as last_MOD

		from base a
		where a.mob_date_to = eomonth(a.freeze_from,4)

	union all

	--выход из заморозки в 0
		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
		a.bucket_90_from,
		cast('[01] 0' as varchar(100)) as bucket_90_to,
		a.od * /*0.35*/ 0.15 * iif(a.mob_date_to <= '2021-10-31', 1.0 - @repeat_share , 1.0) as model_od,  --11.02.2022
		a.freeze_from,
		--cast(null as int) as mod_num, --11/11/2021
		--cast(null as int) as last_MOD --11/11/2021
		case when a.mod_num between 10000 and 19999 then 0
		when a.mod_num between 20000 and 29999 then 1
		else a.mod_num + 1 end as mod_num,
		case when a.last_MOD between 10000 and 19999 then 0
		when a.last_MOD between 20000 and 29999 then 1
		else a.last_MOD + 1 end as last_MOD
		from base a
		where a.mob_date_to = eomonth(a.freeze_from,4)

	union all
	--продление заморозки 
		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
		a.bucket_90_from,
		cast('[07] Freeze' as varchar(100)) as bucket_90_to,
		a.od * @repeat_share as model_od,
		a.freeze_from,
		a.mod_num + 1 - iif(a.mod_num >= 10000,0, 4) as mod_num, --вычитаем 4 месяца, т.к. MOD, который прибавляется, рассчитывается для окончания первичной заморозки
		a.last_MOD + 1 - iif(a.mod_num >= 10000,0, 4) as last_MOD --вычитаем 4 месяца, т.к. MOD, который прибавляется, рассчитывается для окончания первичной заморозки
		from base a
		where a.mob_date_to = eomonth(a.freeze_from,4)
		and a.mob_date_to <= '2021-10-31'

	union all
	--выход из заморозки продлений в 90+
		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
		a.bucket_90_from,
		RiskDWH.dbo.get_bucket_90((case when a.mod_num between 10000 and 19999 then 0
		when a.mod_num between 20000 and 29999 then 1
		else a.mod_num + 1 end) * 30 + 91) as bucket_90_to,  --cast('[05] 90+' as varchar(100)) as bucket_90_to,
		a.od * /*0.65*/ 0.85 as model_od,  --11.02.2022
		a.freeze_from,
		case when a.mod_num between 10000 and 19999 then 0
		when a.mod_num between 20000 and 29999 then 1
		else iif(a.mod_num + 1 >= 0, a.mod_num + 1, null) end as mod_num,

		case when a.last_MOD between 10000 and 19999 then 0
		when a.last_MOD between 20000 and 29999 then 1
		else iif(a.last_MOD + 1 >= 0, a.last_MOD + 1, null) end as last_MOD

		from base a
		where a.mob_date_to >= eomonth(a.freeze_from,8)

	union all
	--выход из заморозки продлений в 0
		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
		a.bucket_90_from,
		cast('[01] 0' as varchar(100)) as bucket_90_to,
		a.od * /*0.35*/ 0.15 as model_od,  --11.02.2022
		a.freeze_from,
		--cast(null as int) as mod_num, --11/11/2021
		--cast(null as int) as last_MOD --11/11/2021
		case when a.mod_num between 10000 and 19999 then 0
		when a.mod_num between 20000 and 29999 then 1
		else a.mod_num + 1 end as mod_num,
		case when a.last_MOD between 10000 and 19999 then 0
		when a.last_MOD between 20000 and 29999 then 1
		else a.last_MOD + 1 end as last_MOD
		from base a
		where a.mob_date_to >= eomonth(a.freeze_from,8)

	)
	insert into Temp_PTS_Test_stg_freeze_model

	select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
	a.bucket_90_from, a.bucket_90_to, a.model_od, a.freeze_from, a.mod_num, a.last_MOD
	from un as a
	;





	---остальные бакеты
	insert into Temp_PTS_Test_stg_freeze_model
	select 
	a.id1,
	a.term, 
	a.segment_rbp,
	a.flag_kk,
	a.generation, 
	eomonth(a.mob_date_to,1) as mob_date_to,
	a.mob_to + 1 as mob_to,
	a.bucket_90_from,
	case 
	when a.mob_date_to >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30' and a.last_MOD between 10000 and 29999
	then '[05] 90+' --11/11/2021
	when a.mob_date_to >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30'
	then RiskDWH.dbo.get_bucket_90((a.last_MOD + 1) * 30 + 91) --11/11/2021
	else b.bucket_90_to end as bucket_90_to, 

	sum(a.total_od_from * b.model_coef_adj * 
	case 
	when a.bucket_90_from = '[03] 31-60' and a.freeze_from is null and a.mob_date_to < '2021-10-31' then 0.25
	when a.bucket_90_from = '[04] 61-90' and a.freeze_from is null and a.mob_date_to < '2021-10-31' then 0.85
	else 1.0 
	end) as model_od,
	a.freeze_from,
	case 
	when a.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0 
	when a.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' and a.mod_num is not null then a.mod_num + 1
	when a.mob_date_to >= eomonth(a.freeze_from,4) then a.mod_num + 1 --11/11/2021
	end as mod_num,

	case 
	when a.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0 
	when a.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' and a.last_MOD is not null then a.last_MOD + 1
	when a.mob_date_to >= eomonth(a.freeze_from,4) then a.last_MOD + 1 --11/11/2021

	end as last_MOD

	from Temp_PTS_Test_freeze_last_fact a
	left join Temp_PTS_Test_for_back_test b
	--on a.term = b.term
	--and a.generation = b.generation
	--and a.segment_rbp = b.segment_rbp
	--and a.flag_kk = b.flag_kk
	on a.id1 = b.id1
	and a.bucket_90_from = b.bucket_90_from
	and a.mob_date_to = eomonth(b.mob_date_to,-1)
	and b.bucket_90_to <> '[07] Freeze'

	where left(a.flag_kk,2) = 'KK'
	and a.bucket_90_from not in ('[07] Freeze')
	and a.mob_date_to = eomonth(@dt_back_test_from,-1)

	group by 
	a.id1,
	a.term, 
	a.segment_rbp,
	a.flag_kk,
	a.generation, 
	a.mob_date_to,
	a.mob_to + 1,
	a.bucket_90_from,
	case 
	when a.mob_date_to >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30' and a.last_MOD between 10000 and 29999
	then '[05] 90+' --11/11/2021
	when a.mob_date_to >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30'
	then RiskDWH.dbo.get_bucket_90((a.last_MOD + 1) * 30 + 91) --11/11/2021
	else b.bucket_90_to end,
	a.freeze_from,
	case 
	when a.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0 
	when a.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' and a.mod_num is not null then a.mod_num + 1
	when a.mob_date_to >= eomonth(a.freeze_from,4) then a.mod_num + 1 --11/11/2021
	end,
	case 
	when a.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0 
	when a.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' and a.last_MOD is not null then a.last_MOD + 1
	when a.mob_date_to >= eomonth(a.freeze_from,4) then a.last_MOD + 1 --11/11/2021

	end


	;





	print ('timing, Temp_PTS_Test_stg_freeze_model cycle start' + format(getdate(), 'HH:mm:ss'));





	--Цикл - перебор прогнозных дат

	declare @ii date = @dt_back_test_from;

	while @ii < EOMONTH(@dt_back_test_from, @horizon) 

	begin


	drop table if exists Temp_PTS_Test_tmp1_freeze_model;
	select * 
	into Temp_PTS_Test_tmp1_freeze_model
	from Temp_PTS_Test_stg_freeze_model a
	where a.mob_date_to = @ii
	--and a.model_od > 1
	;


	---новые заморозки - последняя заморозка 31.10.2021 (октябрь 2021)
	if @ii < '2021-10-31' begin 

		insert into Temp_PTS_Test_stg_freeze_model
		select 
		a.id1,
		a.term, 
		a.segment_rbp,
		a.flag_kk,
		a.generation, 
		eomonth(a.mob_date_to,1) as mob_date_to,
		a.mob_to + 1 as mob_to,
		a.bucket_90_to as bucket_90_from,
		cast('[07] Freeze' as varchar(100)) as bucket_90_to,
		sum( a.model_od 
		* case a.bucket_90_to when '[03] 31-60' then 0.75 when '[04] 61-90' then 0.15 end 
		) as model_od,
		eomonth(a.mob_date_to,1) as freeze_from,
		--cast(null as int) as mod_num
		case
		when a.bucket_90_to = '[03] 31-60' then 10000
		when a.bucket_90_to = '[04] 61-90' then 20000
		end as mod_num,

		case
		when a.bucket_90_to = '[03] 31-60' then 10000
		when a.bucket_90_to = '[04] 61-90' then 20000
		end as last_MOD


		--from Temp_PTS_Test_stg_freeze_model a
		from Temp_PTS_Test_tmp1_freeze_model a
		where left(a.flag_kk,2) = 'KK'
		and a.bucket_90_to in ('[03] 31-60','[04] 61-90')
		--and a.mob_date_to = @ii 
		--and a.model_od > 0
		and a.freeze_from is null --без повторных, только продление
		and a.mob_date_to < '2021-10-31'
		group by 
		a.id1,
		a.term, 
		a.segment_rbp,
		a.flag_kk,
		a.generation, 
		eomonth(a.mob_date_to,1),
		a.mob_to + 1,
		a.bucket_90_to,
		case when a.bucket_90_to = '[03] 31-60' then 10000 when a.bucket_90_to = '[04] 61-90' then 20000 end
		;


	end


	--выход и продолжение заморозки - заморозка с продлениями заканчиваются 31.10.2021 (октябрь 2021), последний выход 31.03.2022
	--if @ii <= '2022-04-30' begin
	if @ii <= '2023-01-31' begin --23.05.2022 - незначительное кол-во заморозок (каникул) с марта 2022 по май 2022

		with base as (
			select 
			a.id1,
			a.term, 
			a.segment_rbp,
			a.flag_kk,
			a.generation, 
			eomonth(a.mob_date_to,1) as mob_date_to,
			a.mob_to + 1 as mob_to,
			a.bucket_90_to as bucket_90_from,
			a.model_od as od,
			a.freeze_from,
			eomonth(a.freeze_from,4) as freeze_to,
			a.mod_num,
			a.last_MOD

			--from Temp_PTS_Test_stg_freeze_model a	
			from Temp_PTS_Test_tmp1_freeze_model a
			where left(a.flag_kk,2) = 'KK'
			and a.bucket_90_to = '[07] Freeze'
			--and a.mob_date_to = @ii
		), un as (
		--продолжение первой заморозки
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
			a.bucket_90_from,
			cast('[07] Freeze' as varchar(100)) as bucket_90_to,
			a.od as model_od,
			a.freeze_from,
			a.mod_num + 1 as mod_num,
			a.last_MOD + 1 as last_MOD
			from base a
			where (a.mob_date_to < eomonth(a.freeze_from,4) or a.mob_date_to between eomonth(a.freeze_from,5) and eomonth(a.freeze_from,7) )

		union all

		--выход из заморозки в 90+
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
			a.bucket_90_from,
			RiskDWH.dbo.get_bucket_90((case when a.mod_num between 10000 and 19999 then 0
			when a.mod_num between 20000 and 29999 then 1
			else a.mod_num + 1 end) * 30 + 91) as bucket_90_to,  --cast('[05] 90+' as varchar(100)) as bucket_90_to,
	
			a.od * /*0.65*/ 0.85 * iif(a.mob_date_to <= '2021-10-31', 1.0 - @repeat_share , 1.0) as model_od,  --11.02.2022
			a.freeze_from,
			case when a.mod_num between 10000 and 19999 then 0
			when a.mod_num between 20000 and 29999 then 1
			else iif(a.mod_num + 1 >= 0, a.mod_num + 1, null) end as mod_num,

			case when a.last_MOD between 10000 and 19999 then 0
			when a.last_MOD between 20000 and 29999 then 1
			else iif(a.last_MOD + 1 >= 0, a.last_MOD + 1, null) end as last_MOD

			from base a
			where a.mob_date_to = eomonth(a.freeze_from,4)

		union all

		--выход из заморозки в 0
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
			a.bucket_90_from,
			cast('[01] 0' as varchar(100)) as bucket_90_to,
			a.od * /*0.35*/ 0.15 * iif(a.mob_date_to <= '2021-10-31', 1.0 - @repeat_share , 1.0) as model_od,  --11.02.2022
			a.freeze_from,
			--cast(null as int) as mod_num, --11/11/2021
			--cast(null as int) as last_MOD --11/11/2021
			case when a.mod_num between 10000 and 19999 then 0
			when a.mod_num between 20000 and 29999 then 1
			else a.mod_num + 1 end as mod_num,
			case when a.last_MOD between 10000 and 19999 then 0
			when a.last_MOD between 20000 and 29999 then 1
			else a.last_MOD + 1 end as last_MOD
			from base a
			where a.mob_date_to = eomonth(a.freeze_from,4)

		union all
		--продление заморозки 
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
			a.bucket_90_from,
			cast('[07] Freeze' as varchar(100)) as bucket_90_to,
			a.od * @repeat_share as model_od,
			a.freeze_from,
			a.mod_num + 1 - iif(a.mod_num >= 10000,0, 4) as mod_num, --вычитаем 4 месяца, т.к. MOD, который прибавляется, рассчитывается для окончания первичной заморозки
			a.last_MOD + 1 - iif(a.mod_num >= 10000,0, 4) as last_MOD --вычитаем 4 месяца, т.к. MOD, который прибавляется, рассчитывается для окончания первичной заморозки
			from base a
			where a.mob_date_to = eomonth(a.freeze_from,4)
			and a.mob_date_to <= '2021-10-31'

		union all
		--выход из заморозки продлений в 90+
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
			a.bucket_90_from,
			RiskDWH.dbo.get_bucket_90((case when a.mod_num between 10000 and 19999 then 0
			when a.mod_num between 20000 and 29999 then 1
			else a.mod_num + 1 end) * 30 + 91) as bucket_90_to,  --cast('[05] 90+' as varchar(100)) as bucket_90_to,
			a.od * /*0.65*/ 0.85 as model_od,  --11.02.2022
			a.freeze_from,

			case when a.mod_num between 10000 and 19999 then 0
			when a.mod_num between 20000 and 29999 then 1
			else iif(a.mod_num + 1 >= 0, a.mod_num + 1, null) end as mod_num,

			case when a.last_MOD between 10000 and 19999 then 0
			when a.last_MOD between 20000 and 29999 then 1
			else iif(a.last_MOD + 1 >= 0, a.last_MOD + 1, null) end as last_MOD
			from base a
			where a.mob_date_to >= eomonth(a.freeze_from,8)

		union all
		--выход из заморозки продлений в 0
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
			a.bucket_90_from,
			cast('[01] 0' as varchar(100)) as bucket_90_to,
			a.od * /*0.35*/ 0.15 as model_od,  --11.02.2022
			a.freeze_from,
			--cast(null as int) as mod_num, --11/11/2021
			--cast(null as int) as last_MOD --11/11/2021
			case when a.mod_num between 10000 and 19999 then 0
			when a.mod_num between 20000 and 29999 then 1
			else a.mod_num + 1 end as mod_num,
			case when a.last_MOD between 10000 and 19999 then 0
			when a.last_MOD between 20000 and 29999 then 1
			else a.last_MOD + 1 end as last_MOD
			from base a
			where a.mob_date_to >= eomonth(a.freeze_from,8)
		)
		insert into Temp_PTS_Test_stg_freeze_model

		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
		a.bucket_90_from, a.bucket_90_to, a.model_od, a.freeze_from, a.mod_num, a.last_MOD
		from un as a
		;

	end


	drop table if exists Temp_PTS_Test_tmp2_freeze_model;
	select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.bucket_90_to,
	a.freeze_from, a.mod_num, a.last_MOD, sum(a.model_od) as model_od
	into Temp_PTS_Test_tmp2_freeze_model
	from Temp_PTS_Test_stg_freeze_model a
	where left(a.flag_kk,2) = 'KK'
	and a.bucket_90_to not in ('[07] Freeze')
	and a.mob_date_to = @ii
	--and a.model_od > 1
	group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.bucket_90_to,
	a.freeze_from, a.mod_num, a.last_MOD ;






	---остальные бакеты
	insert into Temp_PTS_Test_stg_freeze_model

	select 
	a.id1, 
	a.term, 
	a.segment_rbp,
	a.flag_kk,
	a.generation, 
	eomonth(a.mob_date_to,1) as mob_date_to,
	a.mob_to + 1 as mob_to,
	b.bucket_90_from,

	case 
	when a.mob_date_to >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30' and a.last_MOD between 10000 and 29999
	then '[05] 90+' --11/11/2021
	when a.mob_date_to >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30'
	then RiskDWH.dbo.get_bucket_90((a.last_MOD + 1) * 30 + 91) --11/11/2021
	else b.bucket_90_to end as bucket_90_to, 

	sum(a.model_od * b.model_coef_adj 
	* case when b.bucket_90_from = '[03] 31-60' and a.freeze_from is null and a.mob_date_to < '2021-10-31' then 0.25
		   when b.bucket_90_from = '[04] 61-90' and a.freeze_from is null and a.mob_date_to < '2021-10-31' then 0.85
	else 1.0 end
	) as model_od,
	a.freeze_from,
	case when a.mod_num is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.mod_num + 1
		when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
		 when a.mob_date_to >= eomonth(a.freeze_from,4) then a.mod_num + 1 --11/11/2021
	end as mod_num,

	case when a.last_MOD is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.last_MOD + 1
		when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
		when a.mob_date_to >= eomonth(a.freeze_from,4) then a.last_MOD + 1 --11/11/2021
	end as last_MOD

	from Temp_PTS_Test_tmp2_freeze_model a
	inner join Temp_PTS_Test_for_back_test b
	on a.id1 = b.id1
	--and a.term = b.term
	--and a.generation = b.generation
	--and a.segment_rbp = b.segment_rbp
	--and a.flag_kk = b.flag_kk
	and a.bucket_90_to = b.bucket_90_from
	--and a.mob_date_to = eomonth(b.mob_date_to,-1)
	and a.mob_to = b.mob_to - 1
	and b.bucket_90_to <> '[07] Freeze'
	--where left(a.flag_kk,2) = 'KK'
	--and a.bucket_90_to not in ('[07] Freeze')
	--and a.mob_date_to = @ii
	group by 
	a.id1,
	a.term, 
	a.segment_rbp,
	a.flag_kk,
	a.generation, 
	a.mob_date_to,
	a.mob_to + 1,
	b.bucket_90_from,
	case 
	when a.mob_date_to >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30' and a.last_MOD between 10000 and 29999
	then '[05] 90+' --11/11/2021
	when a.mob_date_to >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30'
	then RiskDWH.dbo.get_bucket_90((a.last_MOD + 1) * 30 + 91) --11/11/2021
	else b.bucket_90_to end,
	a.freeze_from,
	case when a.mod_num is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.mod_num + 1
		when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
		 when a.mob_date_to >= eomonth(a.freeze_from,4) then a.mod_num + 1 --11/11/2021
	end,
	case when a.last_MOD is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.last_MOD + 1
		when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
		when a.mob_date_to >= eomonth(a.freeze_from,4) then a.last_MOD + 1 --11/11/2021
	end
	;



	print ('timing, Temp_PTS_Test_stg_freeze_model cycle @ii= ' + format(@ii,'dd.MM.yyyy')+ ' , ' + format(getdate(), 'HH:mm:ss'))

	set @ii = eomonth(@ii, 1);

	end;


	drop table Temp_PTS_Test_tmp1_freeze_model;
	drop table Temp_PTS_Test_tmp2_freeze_model;

	print ('timing, Temp_PTS_Test_stg_freeze_model ' + format(getdate(), 'HH:mm:ss'))





	--объединяем модельные значения с фактом
	drop table if exists Temp_PTS_Test_stg2_freeze_model;

	with M as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation,
		a.mob_date_to, a.mob_to,
		a.bucket_90_to,
		sum(a.model_od) as model_od
		from Temp_PTS_Test_stg_freeze_model a
		group by a.term, a.segment_rbp, a.flag_kk, a.generation,
		a.mob_date_to, a.mob_to,
		a.bucket_90_to
	), F as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation,
		a.mob_date_to, a.mob_to,
		a.bucket_90_to, a.fact_od 
		from Temp_PTS_Test_back_test a 
		where left(a.flag_kk,2) = 'KK'
	)
	select m.term, m.segment_rbp, m.flag_kk, m.generation,
		m.mob_date_to, m.mob_to,
		m.bucket_90_to,
		f.fact_od,
		m.model_od
	into Temp_PTS_Test_stg2_freeze_model
	from M
	left join F
	on m.term = f.term
	and m.segment_rbp = f.segment_rbp
	and m.flag_kk = f.flag_kk
	and m.generation = f.generation
	and m.mob_date_to = f.mob_date_to
	and m.bucket_90_to = f.bucket_90_to
	;


	print ('timing, Temp_PTS_Test_stg2_freeze_model ' + format(getdate(), 'HH:mm:ss'));




	----------------------------------------------------------------------------------------------

	--сборка back-теста с фактом от даты начала back-теста




	drop table if exists Temp_PTS_Test_stg1_back_test_results;

	with new_volume as (
		select a.term, 	a.segment_rbp, a.flag_kk, 	a.generation, 	a.generation as mob_date_to, 0 as mob_to, 
		'[01] 0' as bucket_to,	a.total_od_from as fact_od, a.total_od_from as model_od
		from Temp_PTS_Test_stg3_agg a
		where a.mob_from = 0
		and a.bucket_90_from = '[01] 0'
		and a.bucket_90_to = '[01] 0'
		and exists (select 1 from Temp_PTS_Test_back_test t
					where t.mob_date_to = a.generation)
		and left(a.flag_kk,2) <> 'KK'
	), last_volume as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.generation as mob_date_to, 0 as mob_to, 
		'[01] 0' as bucket_to, 
		sum(a.amount) as fact_od, 
		sum(a.amount) as model_od
		from Temp_PTS_Test_cred_reestr a
		where a.generation = @rdt
		and left(a.flag_kk,2) <> 'KK'
		group by a.term, a.segment_rbp, a.flag_kk, a.generation
	), virt_volume as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.generation as mob_date_to, 0 as mob_to,
		'[01] 0' as bucket_to, 0 as fact_od, sum(a.vl_rub_fact) as model_od
		from Temp_PTS_Test_virt_gens a
		where left(a.flag_kk,2) <> 'KK'
		group by a.term, a.segment_rbp, a.flag_kk, a.generation
	), u as (
		select a.term, 
		a.segment_rbp,
		a.flag_kk,
		a.generation as generation, 
		a.mob_date_to as mob_date_to, 
		a.mob_to, 
		a.bucket_90_to, 
		a.fact_od as fact_od,
		a.model_od as model_od
		from Temp_PTS_Test_back_test a
		where left(a.flag_kk,2) <> 'KK'
	 union all
		select * from new_volume
	 union all
		select * from last_volume
	 union all
		select * from virt_volume
	 union all --кредитные каникулы (заморозка)
		select * from Temp_PTS_Test_stg2_freeze_model a	
	)
	select u.term, u.segment_rbp, u.flag_kk, u.generation, u.mob_date_to, u.mob_to, u.bucket_90_to, 
	case when u.mob_date_to > @rdt then null else u.fact_od end as fact_od,
	case when u.mob_date_to < @dt_back_test_from then null else u.model_od end as model_od,

	case when u.mob_date_to < @dt_back_test_from then '[01] FACT'
	when u.mob_date_to <= @rdt then '[02] BACK-TEST'
	else '[03] FORECAST' end as flag
	into Temp_PTS_Test_stg1_back_test_results
	from u
	;


	--добавление факта ДО дата начала back-теста
	with new_volume as (
		select a.term, 	a.segment_rbp, a.flag_kk, 	a.generation, 	a.generation as mob_date_to, 0 as mob_to, 
		'[01] 0' as bucket_to,	a.total_od_from as fact_od, null as model_od
		from Temp_PTS_Test_stg3_agg a
		where a.mob_from = 0
		and a.bucket_90_from = '[01] 0'
		and a.bucket_90_to = '[01] 0'
		and a.generation <= eomonth(@dt_back_test_from,-1)
	), u as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.bucket_90_to,
		sum(a.od_to) as fact_od, null as model_od
		from Temp_PTS_Test_stg3_agg a
		where 1=1
		and a.mob_date_to <=  eomonth(@dt_back_test_from,-1) 
		group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.bucket_90_to

		union all
		select n.term, n.segment_rbp, n.flag_kk, n.generation, n.mob_date_to, n.mob_to, n.bucket_to,
		n.fact_od, n.model_od
		from new_volume n
	)
	insert into Temp_PTS_Test_stg1_back_test_results
	select u.*, '[01] FACT' as flag 
	from u
	;



	print ('timing, Temp_PTS_Test_stg1_back_test_results' + format(getdate(), 'HH:mm:ss'))

	--добавляем сумму выдачи для расчета GL90
	drop table if exists Temp_PTS_Test_new_volume;

	select * 
	into Temp_PTS_Test_new_volume
	from (
		select a.term, 	a.segment_rbp, a.flag_kk, a.generation, sum(a.total_od_from) as vl_rub_fact
		from Temp_PTS_Test_stg3_agg a
		where a.mob_from = 0
		and (a.bucket_90_from = '[01] 0' or a.flag_kk = 'INSTALLMENT' and a.bucket_90_from in ('[01] 0','[02] 1-30','[03] 31-60'))
		and a.bucket_90_to = '[01] 0'	
		group by a.term, a.segment_rbp, a.flag_kk, a.generation
	union all
		select a.term, a.segment_rbp, a.flag_kk, a.generation, sum(a.amount) as vl_rub_fact
		from Temp_PTS_Test_cred_reestr a
		where a.generation = @rdt
		group by a.term, a.segment_rbp, a.flag_kk, a.generation
	union all
		select a.term, a.segment_rbp, a.flag_kk, a.generation, sum(a.vl_rub_fact) as vl_rub_fact
		from Temp_PTS_Test_virt_gens a
		group by a.term, a.segment_rbp, a.flag_kk, a.generation

	) aa
	;




	print ('timing, Temp_PTS_Test_new_volume' + format(getdate(), 'HH:mm:ss'))


	drop table if exists Temp_PTS_Test_stg2_back_test_results;


	select a.term, a.segment_rbp, a.flag_kk, a.generation, 
	a.mob_date_to, a.mob_to, a.bucket_90_to,
	round(a.fact_od,2) as fact_od,
	round(a.model_od,2) as model_od,
	a.flag,
	b.vl_rub_fact,
	round(isnull(a.fact_od, a.model_od),2) as fact_model_od

	into Temp_PTS_Test_stg2_back_test_results

	from Temp_PTS_Test_stg1_back_test_results a
	left join Temp_PTS_Test_new_volume b
	on a.term = b.term
	and a.generation = b.generation
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	;


	print ('timing, Temp_PTS_Test_stg2_back_test_results' + format(getdate(), 'HH:mm:ss'))

	----------------------------------------------------------------------------------------------------------------------------------------------------
	----------------------- применение Recovery к 90+ ------------------------------------------------------------------------------------------------



	drop table if exists Temp_PTS_Test_conditional_rec_ALL;
	with base as (
		select a.mod_num, 
		--recovery rates
		a.recov_w, 
		isnull(sum(a.recov_w) over (order by a.mod_num rows between unbounded preceding and 1 preceding), 0) as recov_acc,

		a.recov_w * case when a.mod_num <= 3 then 2.0 when a.mod_num <= 7 then 1.5 else 1.0 end as recov_w_31,
		isnull(sum(a.recov_w * case when a.mod_num <= 3 then 2.0 when a.mod_num <= 7 then 1.5 else 1.0 end) over (order by a.mod_num rows between unbounded preceding and 1 preceding), 0) as recov_acc_31,

		a.recov_percents_w,
		isnull(sum(a.recov_percents_w) over (order by a.mod_num rows between unbounded preceding and 1 preceding), 0) as recov_int_acc,
		a.recov_fines,
		isnull(sum(a.recov_fines) over (order by a.mod_num rows between unbounded preceding and 1 preceding), 0) as recov_fines_acc,
		a.recov_straf,
		isnull(sum(a.recov_straf) over (order by a.mod_num rows between unbounded preceding and 1 preceding), 0) as recov_straf_acc,
		--writeoff rates
		----01.09.2022 - добавлена корректировка PIT (расчет с r_date = [06.2021; 07.2022])
		a.writeoff_od * 0.7552 * 1.6 as writeoff_od,
		isnull(sum(a.writeoff_od * 0.7552 * 1.6) over (order by a.mod_num rows between unbounded preceding and 1 preceding), 0) as writeoff_od_acc,	
		a.writeoff_percents * /*1.0189*/ 0.7552 * 1.7 as writeoff_percents,
		isnull(sum(a.writeoff_percents * /*1.0189*/ 0.7552 * 1.7) over (order by a.mod_num rows between unbounded preceding and 1 preceding), 0) as writeoff_int_acc,
		--recovery rates for installment (discounted)
		a.recov_disc_w,
		isnull(sum(a.recov_disc_w) over (order by a.mod_num rows between unbounded preceding and 1 preceding), 0) as recov_disc_w_acc,
		a.recov_percents_disc,
		isnull(sum(a.recov_percents_disc) over (order by a.mod_num rows between unbounded preceding and 1 preceding), 0) as recov_percents_disc_acc,
		a.recov_fines_disc,
		isnull(sum(a.recov_fines_disc) over (order by a.mod_num rows between unbounded preceding and 1 preceding), 0) as recov_fines_disc_acc,
		a.recov_straf_disc,
		isnull(sum(a.recov_straf_disc) over (order by a.mod_num rows between unbounded preceding and 1 preceding), 0) as recov_straf_disc_acc

		from risk.lgd_vint_method a
		where a.dt_to = (select max(dt_to) from risk.lgd_vint_method where src_data = 'CMR+MFO' 
			--and dt_from = '2022-10-01' 
			and dt_from = '2023-08-01' 
			and dt_to < @dt_back_test_from
		) --!!!--дата LGD
		and a.src_data = 'CMR+MFO'
		--and a.dt_from = '2022-10-01'
		and a.dt_from = '2023-08-01'
	), un as (
		select 
		cast('PTS' as varchar(100)) as product,
		b.mod_num, 
		b.recov_w / (1.0 - b.recov_acc) as recov_rate,
		b.recov_percents_w / (1.0 - b.recov_int_acc) as recov_int_rate,
		b.recov_fines / (1.0 - b.recov_fines_acc) as fee_rec_rate,
		b.recov_straf / (1.0 - b.recov_straf_acc) as straf_recovery_rate,
		b.writeoff_od / (1.0 - b.writeoff_od_acc) * 1.46 as wo_rate,
		b.writeoff_percents / (1.0 - b.writeoff_int_acc) * 1.39 as wo_int_rate
		from base b
	union all
		select 
		cast('INSTALLMENT' as varchar(100)) as product,
		b.mod_num, 
		b.recov_disc_w / (1.0 - b.recov_disc_w_acc) as recov_rate,
		b.recov_percents_disc / (1.0 - b.recov_percents_disc_acc) as recov_int_rate,
		b.recov_fines_disc / (1.0 - b.recov_fines_disc_acc) as fee_rec_rate,
		b.recov_straf_disc / (1.0 - b.recov_straf_disc_acc) as straf_recovery_rate,
		--b.writeoff_od / (1.0 - b.writeoff_od_acc) as wo_rate,
		--b.writeoff_percents / (1.0 - b.writeoff_int_acc) as wo_int_rate
		0 as wo_rate,
		0 as wo_int_rate

		from base b
	union all
		select 
		cast('PTS31' as varchar(100)) as product,
		b.mod_num, 
		b.recov_w_31 / (1.0 - b.recov_acc_31) as recov_rate,
		b.recov_percents_w / (1.0 - b.recov_int_acc) as recov_int_rate,
		b.recov_fines / (1.0 - b.recov_fines_acc) as fee_rec_rate,
		b.recov_straf / (1.0 - b.recov_straf_acc) as straf_recovery_rate,
		b.writeoff_od / (1.0 - b.writeoff_od_acc) * 1.46 as wo_rate,
		b.writeoff_percents / (1.0 - b.writeoff_int_acc) * 1.39 as wo_int_rate
		from base b
	union all
		select 
		cast('BUSINESS' as varchar(100)) as product,
		b.mod_num, 
		b.recov_w / (1.0 - b.recov_acc) as recov_rate,
		b.recov_percents_w / (1.0 - b.recov_int_acc) as recov_int_rate,
		b.recov_fines / (1.0 - b.recov_fines_acc) as fee_rec_rate,
		b.recov_straf / (1.0 - b.recov_straf_acc) as straf_recovery_rate,
		0 as wo_rate,
		0 as wo_int_rate
		from base b
	)
	select 
	cast('1111-01-01' as date) as dt_from,
	cast('2023-07-31' as date) as dt_to,
	a.* 
	into Temp_PTS_Test_conditional_rec_ALL 
	from un as a
	;


	update Temp_PTS_Test_conditional_rec_ALL set recov_int_rate = recov_int_rate * 1.4;
	update Temp_PTS_Test_conditional_rec_ALL set fee_rec_rate = fee_rec_rate * 1.7;
	update Temp_PTS_Test_conditional_rec_ALL set straf_recovery_rate = straf_recovery_rate * 2.4;


	insert into Temp_PTS_Test_conditional_rec_ALL
	select 
	'2023-08-31' as dt_from,
	'4444-01-01' as dt_to,
	a.product,
	a.mod_num,
	a.recov_rate,
	a.recov_int_rate,
	a.fee_rec_rate,
	a.straf_recovery_rate,
	a.wo_rate,
	a.wo_int_rate
	from Temp_PTS_Test_conditional_rec_ALL a
	;




	--Для другой версии (скрипт 2.5)
	--update a set 
	--a.recov_rate = a.recov_rate + a.wo_rate * 0.225,
	--a.recov_int_rate = a.recov_int_rate + a.wo_int_rate * 0.225,
	--a.wo_rate = a.wo_rate * 0.775,
	--a.wo_int_rate = a.wo_int_rate * 0.775
	----select * 
	--from Temp_PTS_Test_conditional_rec_ALL a
	--where a.dt_from = '2023-08-31' and a.product = 'PTS'




	print ('timing, Temp_PTS_Test_conditional-s' + format(getdate(), 'HH:mm:ss'))


	--промежуточный расчет накопленных Recovery (для фактических дефолтов - до прогнозной даты)

	drop table if exists Temp_PTS_Test_stg0_default_recovery_fact;

	select a.term, a.generation, a.segment_rbp, a.flag_kk,
	a.mob_date_to, 
	--a.principal_rest_to * case when left(a.flag_kk,2) = 'KK' and a.mob_date_to < '2021-12-31' then 0.85 /*15% на заморозку*/ else 1.0 end as principal_rest_to,
	a.principal_rest_to,
	b.month_default_from,
	DATEDIFF(MM, b.month_default_from, a.mob_date_to) as months_in_default,
	--DATEDIFF(MM, b.month_last_default_from, a.mob_date_to) as last_MOD
	floor((cast(a.dpd_to as float) - 91.0) / 30.0) as last_MOD,
	91 + 30 * DATEDIFF(MM, b.month_default_from, a.mob_date_to) as dpd_calc

	into Temp_PTS_Test_stg0_default_recovery_fact
	from Temp_PTS_Test_stg_matrix_detail a
	inner join Temp_PTS_Test_stg_start_default b
	on a.external_id = b.external_id
	where 1=1
	and a.mob_date_to = eomonth(@dt_back_test_from,-1)
	and a.bucket_90_to <> '[06] Pay-off'
	and a.bucket_90_to = '[05] 90+' --25/06/2021
	and left(a.flag_kk,2) <> 'KK'
	;


	--28/12/2021 - корректировка RecoveryRate в 2022 г: с марта по ноябрь

	drop table if exists Temp_PTS_Test_det_recovery_corr;

	--03.03.2023
	--select 
	--cast(a.r_date as date) as r_date,
	--cast(a.coef as float) as coef,
	--cast(a.WOcoef as float) as WOcoef
	--into Temp_PTS_Test_det_recovery_corr
	--from (values
	-- ('2023-03-31' , 1.21309447 , 1.21309447), 
	-- ('2023-04-30' , 1.20991545 , 1.20991545), 
	-- ('2023-05-31' , 1.22357592 , 1.22357592), 
	-- ('2023-06-30' , 1.27202854 , 1.27202854), 
	-- ('2023-07-31' , 1.27516409 , 1.27516409), 
	-- ('2023-08-31' , 1.27641484 , 1.27641484), 
	-- ('2023-09-30' , 1.28497409 , 1.28497409), 
	-- ('2023-10-31' , 1.28029204 , 1.28029204), 
	-- ('2023-11-30' , 1.29048154 , 1.29048154), 
	-- ('2023-12-31' , 1.29 , 1.54918732)

	--) a (r_date, coef, WOcoef)
	--;

	--17.03.2023 - возвращаем на место
	select 
	cast(a.r_date as date) as r_date,
	cast(a.coef as float) as coef,
	cast(a.WOcoef as float) as WOcoef
	into Temp_PTS_Test_det_recovery_corr
	from (values
	('2023-11-30' , 0.93, 1.0),
	('2023-12-31' , 0.93, 1.0),
	('2024-01-31' , 0.93, 1.0),('2024-02-29' , 0.93, 1.0),('2024-03-31' , 0.93, 1.0),('2024-04-30' , 0.93, 1.0),
	('2024-05-31' , 0.93, 1.0),('2024-06-30' , 0.93, 1.0),('2024-07-31' , 0.93, 1.0),('2024-08-31' , 0.93, 1.0),
	('2024-09-30' , 0.93, 1.0),('2024-10-31' , 0.93, 1.0),('2024-11-30' , 0.93, 1.0),('2024-12-31' , 0.93, 1.0),
	('2025-01-31' , 0.93, 1.0),('2025-02-28' , 0.93, 1.0),('2025-03-31' , 0.93, 1.0),('2025-04-30' , 0.93, 1.0),
	('2025-05-31' , 0.93, 1.0),('2025-06-30' , 0.93, 1.0),('2025-07-31' , 0.93, 1.0),('2025-08-31' , 0.93, 1.0),
	('2025-09-30' , 0.93, 1.0),('2025-10-31' , 0.93, 1.0),('2025-11-30' , 0.93, 1.0),('2025-12-31' , 0.93, 1.0),
	('2026-01-31' , 0.93, 1.0),('2026-02-28' , 0.93, 1.0),('2026-03-31' , 0.93, 1.0),('2026-04-30' , 0.93, 1.0),
	('2026-05-31' , 0.93, 1.0),('2026-06-30' , 0.93, 1.0),('2026-07-31' , 0.93, 1.0),('2026-08-31' , 0.93, 1.0),
	('2026-09-30' , 0.93, 1.0),('2026-10-31' , 0.93, 1.0),('2026-11-30' , 0.93, 1.0),('2026-12-31' , 0.93, 1.0),
	('2027-01-31' , 0.93, 1.0),('2027-02-28' , 0.93, 1.0),('2027-03-31' , 0.93, 1.0),('2027-04-30' , 0.93, 1.0),
	('2027-05-31' , 0.93, 1.0),('2027-06-30' , 0.93, 1.0),('2027-07-31' , 0.93, 1.0),('2027-08-31' , 0.93, 1.0),
	('2027-09-30' , 0.93, 1.0),('2027-10-31' , 0.93, 1.0),('2027-11-30' , 0.93, 1.0),('2027-12-31' , 0.93, 1.0),
	('2028-01-31' , 0.93, 1.0),('2028-02-29' , 0.93, 1.0),('2028-03-31' , 0.93, 1.0),('2028-04-30' , 0.93, 1.0),
	('2028-05-31' , 0.93, 1.0),('2028-06-30' , 0.93, 1.0),('2028-07-31' , 0.93, 1.0),('2028-08-31' , 0.93, 1.0),
	('2028-09-30' , 0.93, 1.0),('2028-10-31' , 0.93, 1.0),('2028-11-30' , 0.93, 1.0),('2028-12-31' , 0.93, 1.0),
	('2029-01-31' , 0.93, 1.0),('2029-02-28' , 0.93, 1.0),('2029-03-31' , 0.93, 1.0),('2029-04-30' , 0.93, 1.0),
	('2029-05-31' , 0.93, 1.0),('2029-06-30' , 0.93, 1.0),('2029-07-31' , 0.93, 1.0),('2029-08-31' , 0.93, 1.0),
	('2029-09-30' , 0.93, 1.0),('2029-10-31' , 0.93, 1.0),('2029-11-30' , 0.93, 1.0),('2029-12-31' , 0.93, 1.0),
	('2030-01-31' , 0.93, 1.0),('2030-02-28' , 0.93, 1.0),('2030-03-31' , 0.93, 1.0),('2030-04-30' , 0.93, 1.0),
	('2030-05-31' , 0.93, 1.0),('2030-06-30' , 0.93, 1.0),('2030-07-31' , 0.93, 1.0),('2030-08-31' , 0.93, 1.0),
	('2030-09-30' , 0.93, 1.0),('2030-10-31' , 0.93, 1.0),('2030-11-30' , 0.93, 1.0),('2030-12-31' , 0.93, 1.0)
	) a (r_date, coef, WOcoef)
	;

	--select 
	--cast(a.r_date as date) as r_date,
	--cast(a.coef as float) as coef
	--into Temp_PTS_Test_det_recovery_corr
	--from (values
	--('2022-03-31',1.122),
	--('2022-04-30',1.112),
	----('2022-05-31',1.102), --14.04.2022
	--('2022-05-31',1.102 * 0.75), --18.04.2022
	--('2022-06-30',1.092 * 0.9), --20.05.2022
	--('2022-07-31',1.082),
	--('2022-08-31',1.072),
	--('2022-09-30',1.062),
	--('2022-10-31',1.052),
	--('2022-11-30',1.042)
	--) a (r_date, coef)
	--;

	--28.02.2022
	--select 
	--cast(a.r_date as date) as r_date,
	--cast(a.coef as float) as coef
	--into Temp_PTS_Test_det_recovery_corr
	--from (values
	--('2022-03-31',0.6),
	--('2022-04-30',0.6),
	--('2022-05-31',0.6),
	--('2022-06-30',0.66),
	--('2022-07-31',0.71),
	--('2022-08-31',0.77),
	--('2022-09-30',0.83),
	--('2022-10-31',0.89),
	--('2022-11-30',0.94),
	--('2022-12-31',0.98)

	----('2022-03-31',0.5),
	----('2022-04-30',0.5),
	----('2022-05-31',0.5),
	----('2022-06-30',0.57),
	----('2022-07-31',0.64),
	----('2022-08-31',0.71),
	----('2022-09-30',0.79),
	----('2022-10-31',0.86),
	----('2022-11-30',0.93),
	----('2022-12-31',0.98)
	--) a (r_date, coef)
	--;




	print ('timing, Temp_PTS_Test_stg0_default_recovery_fact' + format(getdate(), 'HH:mm:ss'))


	--declare @rdt date = '2024-10-31';declare @dt_back_test_from date = '2024-11-30';declare @horizon int = datediff(MM,@rdt,'2030-12-31') + 1;declare @repeat_share float = 0.62;declare @vers int = 369;



	drop table if exists Temp_PTS_Test_stg1_default_recovery_fact;
	create table Temp_PTS_Test_stg1_default_recovery_fact (
		mob_date_to date,
		term int,
		generation date,
		segment_rbp varchar(100),
		flag_kk varchar(100),
		principal_rest_to float,
		mod_last_fact float,
		mod_num float,
		last_MOD float,
		coef float,
		calc_od_default float,
		calc_od_payoff float,
		wo_coef float,
		wo_calc_od_default float,
		wo_calc_od_payoff float,
		recov_int_coef float,
		calc_int_default float,
		calc_int_payoff float,
		int_wo_coef float,
		int_wo_calc_od_default float,
		int_wo_calc_od_payoff float,
		fee_coef float,
		fee_calc_od_default float,
		fee_calc_od_payoff float,
		straf_coef float,
		straf_calc_od_default float,
		straf_calc_od_payoff float
	);



	print ('timing, Temp_PTS_Test_stg1_default_recovery_fact iter0' + format(getdate(), 'HH:mm:ss'))





	declare @cycle_dt date = @dt_back_test_from;

	while @cycle_dt <= EOMONTH(@dt_back_test_from, /*12*6*/ @horizon) begin



		with agg as (
			select b.mob_date_to, b.term, b.generation, b.segment_rbp, b.flag_kk, b.months_in_default, b.last_MOD,
			sum(b.principal_rest_to	) as principal_rest_to, 
			count(*) as cnt
			from Temp_PTS_Test_stg0_default_recovery_fact b
			where 1=1
			group by b.mob_date_to, b.term, b.generation, b.segment_rbp, b.flag_kk, b.months_in_default, b.last_MOD
		)
		insert into Temp_PTS_Test_stg1_default_recovery_fact
		select 
		--a.*, b.*, a.months_in_default + DATEDIFF(MM, a.mob_date_to, b.mob_date_to) as mod_num, c.mod_num, c.recov_rate,

		@cycle_dt as mob_date_to, a.term, a.generation, a.segment_rbp, a.flag_kk, a.principal_rest_to,
		a.months_in_default as mod_last_fact, 
		a.months_in_default + DATEDIFF(MM, a.mob_date_to, @cycle_dt) as mod_num,
		a.last_MOD + DATEDIFF(MM, a.mob_date_to, @cycle_dt) as last_MOD,

		exp(sum(log(1.0 - isnull( c.recov_rate * 
		case month(eomonth(a.mob_date_to, c.mod_num - a.months_in_default)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) ,0)))) as coef,
		a.principal_rest_to * exp(sum(log(1.0 - isnull( c.recov_rate * 
		case month(eomonth(a.mob_date_to, c.mod_num - a.months_in_default)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) ,0)))) as calc_od_default,
		a.principal_rest_to * (1 - exp(sum(log(1.0 - isnull( c.recov_rate * 
		case month(eomonth(a.mob_date_to, c.mod_num - a.months_in_default)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) ,0)))) ) as calc_od_payoff,

		exp(sum(log(1.0 - isnull(c.wo_rate,0) * isnull(d.WOcoef,1.0) ))) as wo_coef,
		a.principal_rest_to * exp(sum(log(1.0 - isnull(c.wo_rate,0) * isnull(d.WOcoef,1.0) ))) as wo_calc_od_default,
		a.principal_rest_to * (1 - exp(sum(log(1.0 - isnull(c.wo_rate,0) * isnull(d.WOcoef,1.0) ))) ) as wo_calc_od_payoff,

		exp(sum(log(1.0 - isnull(c.recov_int_rate * 
		case month(eomonth(a.mob_date_to, c.mod_num - a.months_in_default)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) ,0)))) as recov_int_coef,
		a.principal_rest_to * exp(sum(log(1.0 - isnull(c.recov_int_rate * 
		case month(eomonth(a.mob_date_to, c.mod_num - a.months_in_default)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) ,0)))) as calc_int_default,
		a.principal_rest_to * (1 - exp(sum(log(1.0 - isnull(c.recov_int_rate * 
		case month(eomonth(a.mob_date_to, c.mod_num - a.months_in_default)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) ,0)))) ) as calc_int_payoff,

		exp(sum(log(1.0 - isnull(c.wo_int_rate,0) * isnull(d.WOcoef,1.0) ))) as int_wo_coef,
		a.principal_rest_to * exp(sum(log(1.0 - isnull(c.wo_int_rate,0) * isnull(d.WOcoef,1.0) ))) as int_wo_calc_od_default,
		a.principal_rest_to * (1 - exp(sum(log(1.0 - isnull(c.wo_int_rate,0) * isnull(d.WOcoef,1.0) ))) ) as int_wo_calc_od_payoff,


		exp(sum(log(1.0 - isnull(c.fee_rec_rate * 
		case month(eomonth(a.mob_date_to, c.mod_num - a.months_in_default)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) ,0)))) as fee_coef,
		a.principal_rest_to * exp(sum(log(1.0 - isnull(c.fee_rec_rate * 
		case month(eomonth(a.mob_date_to, c.mod_num - a.months_in_default)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) ,0)))) as fee_calc_od_default,
		a.principal_rest_to * (1 - exp(sum(log(1.0 - isnull(c.fee_rec_rate * 
		case month(eomonth(a.mob_date_to, c.mod_num - a.months_in_default)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) ,0)))) ) as fee_calc_od_payoff,

		exp(sum(log(1.0 - isnull(c.straf_recovery_rate * 
		case month(eomonth(a.mob_date_to, c.mod_num - a.months_in_default)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) ,0)))) as straf_coef,
		a.principal_rest_to * exp(sum(log(1.0 - isnull(c.straf_recovery_rate * 
		case month(eomonth(a.mob_date_to, c.mod_num - a.months_in_default)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) ,0)))) as straf_calc_od_default,
		a.principal_rest_to * (1 - exp(sum(log(1.0 - isnull(c.straf_recovery_rate * 
		case month(eomonth(a.mob_date_to, c.mod_num - a.months_in_default)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) ,0)))) ) as straf_calc_od_payoff

		from agg a

		left join Temp_PTS_Test_conditional_rec_ALL c
		on c.mod_num between a.months_in_default + 1 and a.months_in_default + DATEDIFF(MM, a.mob_date_to, @cycle_dt)
		--and iif(a.flag_kk <> 'Installment', 'PTS', 'Installment') = c.product
		and case 
		when a.segment_rbp = 'PTS31' and DATEDIFF(MM, a.generation, EOMONTH(a.mob_date_to, -1 * a.months_in_default)) >= 8 then 'PTS'
		when a.segment_rbp = 'PTS31' then 'PTS31'
		when a.flag_kk = 'Installment' then 'Installment'
		when a.flag_kk = 'BUSINESS' then 'BUSINESS'
		else 'PTS' end = c.product
		and eomonth(a.mob_date_to, c.mod_num - a.months_in_default) between c.dt_from and c.dt_to

		left join Temp_PTS_Test_det_recovery_corr d
		on eomonth(a.mob_date_to, c.mod_num - a.months_in_default) = d.r_date

		group by a.term, a.generation, a.segment_rbp, a.flag_kk, a.principal_rest_to, a.months_in_default, a.mob_date_to, a.last_MOD

		;


		print ('timing, Temp_PTS_Test_stg1_default_recovery_fact @cycle_dt = ' + format(@cycle_dt, 'dd.MM.yyyy') + ' ' + format(getdate(), 'HH:mm:ss'));



		set @cycle_dt = eomonth(@cycle_dt,1)

	end;





	--Цессия - обнуляем с момента продажи
	delete from Temp_PTS_Test_stg1_default_recovery_fact where flag_kk like 'CESS%' and mob_date_to >= cast(substring(flag_kk,6,10) as date);
	--Банкроты - не рекаверятся
	--upd 21.10.2021 - все-таки рекаверятся
	/*
	update a set a.coef = 1, 
	a.calc_od_default = a.principal_rest_to,
	a.calc_od_payoff = 0,
	a.wo_coef = 1,
	a.wo_calc_od_default = a.principal_rest_to,
	a.wo_calc_od_payoff = 0,
	a.recov_int_coef = 1,
	a.calc_int_default = a.principal_rest_to,
	a.calc_int_payoff = 0,
	a.int_wo_coef = 1,
	a.int_wo_calc_od_default = a.principal_rest_to,
	a.int_wo_calc_od_payoff = 0

	from Temp_PTS_Test_stg1_default_recovery_fact a
	where a.flag_kk = 'BANKRUPT';
	*/



	print ('timing, Temp_PTS_Test_stg1_default_recovery_fact' + format(getdate(), 'HH:mm:ss'))



	--накопленные Recovery (для фактических дефолтов - до прогнозной даты)
	drop table if exists Temp_PTS_Test_default_recovery_fact

	select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, 
	sum(a.calc_od_default) as calc_od_default,
	sum(a.calc_od_payoff ) as calc_od_payoff,

	sum(a.wo_calc_od_default) as wo_calc_od_default,
	sum(a.wo_calc_od_payoff ) as wo_calc_od_payoff,

	sum(a.calc_int_default) as calc_int_default,
	sum(a.calc_int_payoff ) as calc_int_payoff,

	sum(a.int_wo_calc_od_default) as int_wo_calc_od_default,
	sum(a.int_wo_calc_od_payoff	) as int_wo_calc_od_payoff,

	sum(a.fee_calc_od_default) as fee_calc_od_default,
	sum(a.fee_calc_od_payoff) as fee_calc_od_payoff,

	sum(a.straf_calc_od_default) as straf_calc_od_default,
	sum(a.straf_calc_od_payoff) as straf_calc_od_payoff

	into Temp_PTS_Test_default_recovery_fact
	from Temp_PTS_Test_stg1_default_recovery_fact a
	group by a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to
	;





	print ('timing, Temp_PTS_Test_default_recovery_fact' + format(getdate(), 'HH:mm:ss'))

	------------------------------------------------------------------------
	----сборка MOD (month on default) для продления модельных (поколения есть в факте)



	--declare @dt_back_test_from date = '2024-11-30';declare @rdt date = '2024-10-31';declare @horizon int = datediff(MM,@rdt,'2024-12-31') + 1;
	--1-ая итерация для цикла


	drop table if exists Temp_PTS_Test_stg1_default_recovery_model;
	select 
	--a.*, b.*
	a.id1,
	a.term, a.segment_rbp, a.flag_kk, a.generation, b.mob_date_to, b.mob_to, 
	cast(null as varchar(100)) as bucket_90_past, a.bucket_90_from, b.bucket_90_to, 
	sum(isnull(a.total_od_from,0) * isnull(b.model_coef_adj,0)
	) as model_od,

	case when a.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0 end as mod_num,
	case when a.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0 end as last_MOD

	into Temp_PTS_Test_stg1_default_recovery_model
	from Temp_PTS_Test_last_fact a
	left join Temp_PTS_Test_for_back_test b
	on a.id1 = b.id1
	--and a.generation = b.generation
	--and a.term = b.term
	--and a.segment_rbp = b.segment_rbp
	--and a.flag_kk = b.flag_kk
	and a.bucket_90_from = b.bucket_90_from
	where 1=1
	and b.mob_date_to = @dt_back_test_from 
	and (cast(substring(b.bucket_90_to,2,2) as int) - cast(substring(a.bucket_90_from,2,2) as int) <= 1)
	and b.bucket_90_to <> '[06] Pay-off'
	and a.bucket_90_from <> '[06] Pay-off'
	and left(a.flag_kk,2) <> 'KK'
	group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, b.mob_date_to, b.mob_to, a.bucket_90_from, b.bucket_90_to
	;



	---- + виртуальные поколения
	insert into Temp_PTS_Test_stg1_default_recovery_model
	select 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, a.segment_rbp, a.flag_kk, a.generation, a.generation as mob_date_to, 0 as mob_to,
	null as bucket_90_past, null as bucket_90_from, '[01] 0' as bucket_90_to, a.vl_rub_fact as model_od, null as mod_num, null as last_MOD
	from Temp_PTS_Test_virt_gens a
	where left(a.flag_kk,2) <> 'KK'
	and a.generation = @dt_back_test_from
	;




	drop table if exists Temp_PTS_Test_tmp1_default_recovery_model;
	select top 0 
	a.id1,
	a.term, a.segment_rbp, a.flag_kk, a.generation,
	a.mob_to, a.bucket_90_from, a.bucket_90_to, a.mod_num, a.last_MOD, a.model_od
	into Temp_PTS_Test_tmp1_default_recovery_model
	from Temp_PTS_Test_stg1_default_recovery_model a;

	drop table if exists Temp_PTS_Test_tmp2_default_recovery_model;
	select *
	into Temp_PTS_Test_tmp2_default_recovery_model
	from Temp_PTS_Test_stg1_default_recovery_model;





	print ('timing, Temp_PTS_Test_stg1_default_recovery_model' + format(getdate(), 'HH:mm:ss'))

	--цикл


	declare @d date = eomonth(@dt_back_test_from,1)

	while @d <= EOMONTH(@dt_back_test_from, @horizon + 2)
	begin


		truncate table Temp_PTS_Test_tmp1_default_recovery_model;
		insert into Temp_PTS_Test_tmp1_default_recovery_model
		select 
		a.id1,
		a.term, a.segment_rbp, a.flag_kk, a.generation,
		a.mob_to, a.bucket_90_from, a.bucket_90_to, a.mod_num, a.last_MOD, sum(a.model_od) as model_od
		from Temp_PTS_Test_tmp2_default_recovery_model a
		where 1=1
		and a.bucket_90_to <> '[06] Pay-off'
		--and a.model_od > 1
		group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation,
		a.mob_to, a.bucket_90_from, a.bucket_90_to, a.mod_num, a.last_MOD
		;


		truncate table Temp_PTS_Test_tmp2_default_recovery_model;
		insert into Temp_PTS_Test_tmp2_default_recovery_model	
		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, 
		b.mob_date_to, b.mob_to, 
		a.bucket_90_from as bucket_90_past,
		b.bucket_90_from,
		b.bucket_90_to,

		sum(a.model_od * isnull(b.model_coef_adj,0)) as model_od,

		case when a.mod_num is not null and b.bucket_90_to = '[05] 90+' then a.mod_num + 1
		when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
		end as mod_num,

		case when a.mod_num is not null and b.bucket_90_to = '[05] 90+' then a.mod_num + 1
		when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
		end as last_MOD

		from Temp_PTS_Test_tmp1_default_recovery_model a
		inner join Temp_PTS_Test_for_back_test b
		on a.id1 = b.id1
		--and a.term = b.term
		--and a.segment_rbp = b.segment_rbp
		--and a.flag_kk = b.flag_kk
		--and a.generation = b.generation
		and a.mob_to = b.mob_to - 1
		and a.bucket_90_to = b.bucket_90_from
		where 1=1
		and (cast(substring(b.bucket_90_to,2,2) as int) - cast(substring(a.bucket_90_to,2,2) as int) <= 1)
		and b.bucket_90_to <> '[06] Pay-off'
		group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, 
		b.mob_date_to, b.mob_to, 
		a.bucket_90_from,
		b.bucket_90_from,
		b.bucket_90_to,
		a.mod_num
		--order by a.bucket_90_from, b.bucket_90_to, b.bucket_90_from
		;


		insert into Temp_PTS_Test_tmp2_default_recovery_model
		select 
		hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
		a.term, a.segment_rbp, a.flag_kk, a.generation, a.generation as mob_date_to, 0 as mob_to,
		null as bucket_90_past, null as bucket_90_from, '[01] 0' as bucket_90_to, a.vl_rub_fact as model_od, null as mod_num, null as last_MOD
		from Temp_PTS_Test_virt_gens a
		where left(a.flag_kk,2) <> 'KK'
		and a.generation = @d
		;


		insert into Temp_PTS_Test_stg1_default_recovery_model
		select * from Temp_PTS_Test_tmp2_default_recovery_model
		;


		print ('timing, Temp_PTS_Test_stg1_default_recovery_model cycle @d = ' + format(@d,'dd.MM.yyyy') + ' , ' + format(getdate(), 'HH:mm:ss'));

	
		set @d = eomonth(@d,1)

	end 
	;



	drop table Temp_PTS_Test_tmp1_default_recovery_model;
	drop table Temp_PTS_Test_tmp2_default_recovery_model;



	print ('timing, Temp_PTS_Test_stg1_default_recovery_model cycle' + format(getdate(), 'HH:mm:ss'))




	drop table if exists Temp_PTS_Test_stg2_default_recovery_model;

	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.mod_num, a.last_MOD, cast(null as date) as freeze_from, 
	eomonth(a.mob_date_to, -1 * a.mod_num) as default_dt,
	sum(a.model_od) as model_od
	into Temp_PTS_Test_stg2_default_recovery_model
	from Temp_PTS_Test_stg1_default_recovery_model a
	where a.bucket_90_to = '[05] 90+'
	and a.mod_num is not null
	and a.mod_num >= 0
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.mod_num, a.last_MOD
	;


	--Кредитные каникулы (заморозка)


	insert into Temp_PTS_Test_stg2_default_recovery_model
	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.mod_num, a.last_MOD, a.freeze_from,
	eomonth(a.mob_date_to, -1 * a.mod_num) as default_dt,
	sum(a.model_od) as model_od
	from Temp_PTS_Test_stg_freeze_model a
	where a.bucket_90_to = '[05] 90+'
	and a.mod_num is not null
	and a.mod_num >= 0
	--and (eomonth(a.mob_date_to, -1 * a.mod_num) >= eomonth(@dt_back_test_from) --только новые модельные дефолты
	-- or a.freeze_from is not null and --или выход из заморозки
	-- not exists (select 1 from Temp_PTS_Test_ni_kk b
	--	where a.segment_rbp = b.segment_rbp
	--	and a.flag_kk = b.flag_kk
	--	and a.term = b.term
	--	and a.generation = b.generation
	--	and a.freeze_from = b.freeze_from
	--	and a.bucket_90_from = b.bucket_90_from
	--	and a.bucket_90_to = b.bucket_90_to
	--	and eomonth(a.mob_date_to, -1 * a.mod_num) = b.default_dt)
	-- )
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.mod_num, a.last_MOD, a.freeze_from
	;




	--Цессия - обнуляем с момента продажи
	delete from Temp_PTS_Test_stg2_default_recovery_model where flag_kk like 'CESS%' and mob_date_to >= cast(substring(flag_kk,6,10) as date);

	delete from Temp_PTS_Test_stg2_default_recovery_model where isnull(mod_num,-999) < 0;

	print ('timing, Temp_PTS_Test_stg2_default_recovery_model' + format(getdate(), 'HH:mm:ss'))








	drop table if exists Temp_PTS_Test_stg3_default_recovery_model;
	create table Temp_PTS_Test_stg3_default_recovery_model (
		term int,
		segment_rbp varchar(100),
		flag_kk varchar(100),
		generation date,
		mob_date_to date,
		mob_to float,
		mod_num float,
		last_MOD float,
		freeze_from date,
		model_od float,
		coef float,
		calc_od_default float,
		calc_od_payoff float,
		wo_coef float,
		wo_calc_od_default float,
		wo_calc_od_payoff float,
		recov_int_coef float,
		calc_int_default float,
		calc_int_payoff float,
		int_wo_coef float,
		int_wo_calc_od_default float,
		int_wo_calc_od_payoff float,
		fee_coef float,
		fee_calc_od_default float,
		fee_calc_od_payoff float,
		straf_coef float,
		straf_calc_od_default float,
		straf_calc_od_payoff float,
	);




	declare @cycle_dt5 date = @dt_back_test_from;

	while @cycle_dt5 <= eomonth(@dt_back_test_from, @horizon) begin




		insert into Temp_PTS_Test_stg3_default_recovery_model
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.mod_num, a.last_MOD, a.freeze_from,
		a.model_od,
		exp(sum(log( 1.0 - isnull(b.recov_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) as coef,
		exp(sum(log( 1.0 - isnull(b.recov_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) * a.model_od as calc_od_default,
		(1 - exp(sum(log( 1.0 - isnull(b.recov_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0	end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) ) * a.model_od as calc_od_payoff,


		exp(sum(log( 1.0 - isnull(b.wo_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) as wo_coef,
		exp(sum(log( 1.0 - isnull(b.wo_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) * a.model_od as wo_calc_od_default,
		(1 - exp(sum(log( 1.0 - isnull(b.wo_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) ) * a.model_od as wo_calc_od_payoff,


		exp(sum(log( 1.0 - isnull(b.recov_int_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) as recov_int_coef,
		exp(sum(log( 1.0 - isnull(b.recov_int_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) * a.model_od as calc_int_default,
		(1 - exp(sum(log( 1.0 - isnull(b.recov_int_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) ) * a.model_od as calc_int_payoff,


		exp(sum(log( 1.0 - isnull(b.wo_int_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) as int_wo_coef,
		exp(sum(log( 1.0 - isnull(b.wo_int_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) * a.model_od as int_wo_calc_od_default,
		(1 - exp(sum(log( 1.0 - isnull(b.wo_int_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) ) * a.model_od as int_wo_calc_od_payoff,

		exp(sum(log( 1.0 - isnull(b.fee_rec_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) as fee_coef,
		exp(sum(log( 1.0 - isnull(b.fee_rec_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) * a.model_od as fee_calc_od_default,
		(1 - exp(sum(log( 1.0 - isnull(b.fee_rec_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) ) * a.model_od as fee_calc_od_payoff,


		exp(sum(log( 1.0 - isnull(b.straf_recovery_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) as straf_coef,
		exp(sum(log( 1.0 - isnull(b.straf_recovery_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) * a.model_od as straf_calc_od_default,
		(1 - exp(sum(log( 1.0 - isnull(b.straf_recovery_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) ) * a.model_od as straf_calc_od_payoff




		from Temp_PTS_Test_stg2_default_recovery_model a
		left join Temp_PTS_Test_conditional_rec_ALL b
		--on a.mod_num >= b.mod_num
		on b.mod_num between a.mod_num - DATEDIFF(MM, @dt_back_test_from, a.mob_date_to) and a.mod_num
		--and iif(a.flag_kk <> 'Installment', 'PTS', 'Installment') = b.product
		and case
		when a.segment_rbp = 'PTS31' and DATEDIFF(MM, a.generation, EOMONTH(a.mob_date_to, -1 * a.mod_num)) >= 8 then 'PTS'
		when a.segment_rbp = 'PTS31' then 'PTS31' 
		when a.flag_kk = 'Installment' then 'Installment' 
		when a.flag_kk = 'BUSINESS' then 'BUSINESS'
		else 'PTS' end = b.product
		and eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num) between b.dt_from and b.dt_to

		left join Temp_PTS_Test_det_recovery_corr d
		on eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num) = d.r_date


		--where a.mod_num >= 0
		where a.mob_date_to = @cycle_dt5

		group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.mod_num, a.model_od, a.last_MOD, a.freeze_from
		;

		print ('timing, Temp_PTS_Test_stg3_default_recovery_model @k = ' + format(@cycle_dt5, 'dd.MM.yyyy') + ' ' + format(getdate(), 'HH:mm:ss'));


		set @cycle_dt5 = EOMONTH(@cycle_dt5,1);

	end;

	print ('timing, Temp_PTS_Test_stg3_default_recovery_model' + format(getdate(), 'HH:mm:ss'))



	--Цессия - обнуляем с момента продажи
	delete from Temp_PTS_Test_stg3_default_recovery_model where flag_kk like 'CESS%' and mob_date_to >= cast(substring(flag_kk,6,10) as date);


	--Банкроты - не рекаверятся
	--upd 21.10.2021 все-таки рекаверятся
	/*
	update a set a.coef = 1, 
	a.calc_od_default = a.model_od,
	a.calc_od_payoff = 0,
	a.wo_coef = 1,
	a.wo_calc_od_default = a.model_od,
	a.wo_calc_od_payoff = 0,
	a.recov_int_coef = 1,
	a.calc_int_default = a.model_od,
	a.calc_int_payoff = 0,
	a.int_wo_coef = 1,
	a.int_wo_calc_od_default = a.model_od,
	a.int_wo_calc_od_payoff = 0

	from Temp_PTS_Test_stg3_default_recovery_model a
	where a.flag_kk = 'BANKRUPT';
	*/




	--присоединяем Recovery и WriteOff
	---!!!---при этом посчитанная сумма MODEL_OD не меняется по MOD (MonthOnDefault), поэтому нужно рассчитать произведение (1 - RecovRate)

	drop table if exists Temp_PTS_Test_default_recovery_model;

	select b.term, b.segment_rbp, b.flag_kk, b.generation, b.mob_date_to, b.mob_to, 
	sum(b.calc_od_default) as calc_od_default,
	sum(b.calc_od_payoff ) as calc_od_payoff,

	sum(b.wo_calc_od_default) as wo_calc_od_default,
	sum(b.wo_calc_od_payoff	) as wo_calc_od_payoff,

	sum(b.calc_int_default) as calc_int_default,
	sum(b.calc_int_payoff) as calc_int_payoff,

	sum(b.int_wo_calc_od_default) as int_wo_calc_od_default,
	sum(b.int_wo_calc_od_payoff) as int_wo_calc_od_payoff,

	sum(b.fee_calc_od_default) as fee_calc_od_default,
	sum(b.fee_calc_od_payoff) as fee_calc_od_payoff,

	sum(b.straf_calc_od_default) as straf_calc_od_default,
	sum(b.straf_calc_od_payoff) as straf_calc_od_payoff

	into Temp_PTS_Test_default_recovery_model
	from Temp_PTS_Test_stg3_default_recovery_model b
	group by b.term, b.segment_rbp, b.flag_kk, b.generation, b.mob_date_to, b.mob_to
	;




	print ('timing, Temp_PTS_Test_default_recovery_model' + format(getdate(), 'HH:mm:ss'))


	/******************************************************************************************/
	--корректировка Pay-off и 90+ и добавление списаний и рекавери 90+

	drop table if exists Temp_PTS_Test_stg3_back_test_results;

	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
	a.bucket_90_to, a.fact_od, 

	case
	when a.bucket_90_to = '[05] 90+' then a.model_od - isnull(b.calc_od_payoff,0) - isnull(c.calc_od_payoff,0)
											   - isnull(b.wo_calc_od_payoff,0) - ISNULL(c.wo_calc_od_payoff,0)
	when a.bucket_90_to = '[06] Pay-off' then a.model_od + isnull(b.calc_od_payoff,0) + isnull(c.calc_od_payoff,0)
	else a.model_od 
	end as model_od,

	a.flag, a.vl_rub_fact, 

	coalesce( a.fact_od, 
				case 
				when a.bucket_90_to = '[05] 90+' then a.model_od - isnull(b.calc_od_payoff,0) - isnull(c.calc_od_payoff,0) 
														   - isnull(b.wo_calc_od_payoff,0) - isnull(c.wo_calc_od_payoff,0)
					when a.bucket_90_to = '[06] Pay-off' then a.model_od + isnull(b.calc_od_payoff,0) + isnull(c.calc_od_payoff,0)
					else a.model_od 
					end,
					0) as fact_model_od,

	coalesce( case 
					when a.bucket_90_to = '[05] 90+' then a.model_od - isnull(b.calc_od_payoff,0) - isnull(c.calc_od_payoff,0) 
														   - isnull(b.wo_calc_od_payoff,0) - isnull(c.wo_calc_od_payoff,0)
					when a.bucket_90_to = '[06] Pay-off' then a.model_od + isnull(b.calc_od_payoff,0) + isnull(c.calc_od_payoff,0)
					else a.model_od 
					end,
					 a.fact_od, 
					0) as model_fact_od

	--a.fact_model_od

	into Temp_PTS_Test_stg3_back_test_results

	from Temp_PTS_Test_stg2_back_test_results a

	left join Temp_PTS_Test_default_recovery_fact b
	on a.term = b.term
	and a.generation = b.generation
	and a.segment_rbp = b.segment_rbp
	and a.mob_date_to = b.mob_date_to
	and a.flag_kk = b.flag_kk

	left join Temp_PTS_Test_default_recovery_model c
	on a.term = c.term
	and a.generation = c.generation
	and a.segment_rbp = c.segment_rbp
	and a.mob_date_to = c.mob_date_to
	and a.flag_kk = c.flag_kk

	;


	print ('timing, Temp_PTS_Test_stg3_back_test_results' + format(getdate(), 'HH:mm:ss'))


	--фактические списания (до прогнозной матрицы)
	drop table if exists Temp_PTS_Test_write_offs_fact;

	select a.term, a.generation, a.segment_rbp, a.flag_kk,
	eomonth(b.r_date) as mob_date_to,
	sum(isnull(b.od_wo,0)) as od_wo
	into Temp_PTS_Test_write_offs_fact
	from Temp_PTS_Test_cred_reestr a
	inner join Temp_PTS_Test_stg_write_off b
	on a.external_id = b.external_id
	where 1=1
	and b.r_date <= eomonth(@dt_back_test_from,-1)
	group by a.term, a.generation, a.segment_rbp, a.flag_kk, eomonth(b.r_date)
	;



	--фактические Recovery
	drop table if exists Temp_PTS_Test_npl_recovery_fact;
	with w as (
		select b.term, b.segment_rbp, b.generation, b.flag_kk,
		eomonth(a.r_date) as mob_date_to,
		sum(a.od_wo) as od_wo
		from Temp_PTS_Test_stg_write_off a
		inner join Temp_PTS_Test_cred_reestr b
		on a.external_id = b.external_id
		group by b.term, b.segment_rbp, b.generation, b.flag_kk,
		eomonth(a.r_date)
	)
	select a.term, a.generation, a.segment_rbp, a.flag_kk,
	a.mob_date_to, 
	a.od_to - isnull(w.od_wo,0) as npl_recovery
	into Temp_PTS_Test_npl_recovery_fact
	from Temp_PTS_Test_stg3_agg a
	left join w
	on a.term = w.term
	and a.segment_rbp = w.segment_rbp
	and a.generation = w.generation
	and a.flag_kk = w.flag_kk
	and a.mob_date_to = w.mob_date_to
	where 1=1
	and a.bucket_90_from = '[05] 90+' 
	and a.bucket_90_to = '[06] Pay-off'
	--12.07.2023 цессии не идут в cash-on
	and case when (a.flag_kk like 'CESS%' and a.mob_date_to = DATEFROMPARTS(substring(a.flag_kk,6,4), SUBSTRING(a.flag_kk,11,2), SUBSTRING(a.flag_kk,14,2))) then 1 else 0 end = 0
	;




	---все списания и рекавери для 90+: факт и модель
	drop table if exists Temp_PTS_Test_npl_wo_and_recovery;
	with base as (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to,
		a.wo_calc_od_payoff - lag(a.wo_calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to) as od_wo,
		a.calc_od_payoff - lag(a.calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to) as npl_recovery
		from Temp_PTS_Test_default_recovery_fact a
	union all
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to,
		a.wo_calc_od_payoff - lag(a.wo_calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to) as od_wo,
		a.calc_od_payoff - lag(a.calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to) as npl_recovery
		from Temp_PTS_Test_default_recovery_model a
	union all
		select distinct a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, isnull(b.od_wo,0) as od_wo, isnull(c.npl_recovery,0) as npl_recovery
		from Temp_PTS_Test_stg3_back_test_results a
		left join Temp_PTS_Test_write_offs_fact b
		on a.mob_date_to = b.mob_date_to
		and a.term = b.term
		and a.generation = b.generation
		and a.segment_rbp = b.segment_rbp
		and a.flag_kk = b.flag_kk

		left join Temp_PTS_Test_npl_recovery_fact c
		on a.mob_date_to = c.mob_date_to
		and a.term = c.term
		and a.generation = c.generation
		and a.segment_rbp = c.segment_rbp
		and a.flag_kk = c.flag_kk

		where a.flag = '[01] FACT'
		--30/08/2021 - 90+ не подтянулся на дату @dt_back_test_from по ветке моделирования факта (Temp_PTS_Test_default_recovery_fact)
		----из-за закрытия на MoB, когда был 90+ или из-за отсутствия договоров в 90+ (40/50 по большей части)
		union 	
		select distinct a.term, a.generation, a.segment_rbp, a.flag_kk, /*a.mob_date_to*/ c.mob_date_to, cast(0 as float) as od_wo, cast(0 as float) as npl_recovery
		from Temp_PTS_Test_stg3_back_test_results a
		left join Temp_PTS_Test_repdates c
		on c.mob_date_to >= @dt_back_test_from
		where not exists (select 1 from Temp_PTS_Test_default_recovery_fact b
							where a.generation = b.generation
							and a.segment_rbp = b.segment_rbp
							and a.term = b.term
							and a.flag_kk = b.flag_kk
							and a.mob_date_to = b.mob_date_to
							)
		and a.bucket_90_to = '[05] 90+'
		and a.mob_date_to = @dt_back_test_from 
		and a.mob_to >= 5

	), total as (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, sum(a.od_wo) as od_wo, sum(a.npl_recovery) as npl_recovery
		from base a
		group by a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to
	)
	select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to,
	sum(a.od_wo) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to rows between unbounded preceding and current row) as od_wo,
	sum(a.npl_recovery) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to rows between unbounded preceding and current row) as npl_recovery
	into Temp_PTS_Test_npl_wo_and_recovery
	from total a
	;



	insert into Temp_PTS_Test_npl_wo_and_recovery
	select a.term, a.generation, a.segment_rbp, a.flag_kk, c.mob_date_to, a.od_wo, a.npl_recovery
	from Temp_PTS_Test_npl_wo_and_recovery a
	inner join (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, max(a.mob_date_to) as mx_dt
		from Temp_PTS_Test_npl_wo_and_recovery a
		group by a.term, a.generation, a.segment_rbp, a.flag_kk
		having max(a.mob_date_to) <= @rdt
	) b 
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.generation = b.generation
	and a.flag_kk = b.flag_kk
	and a.mob_date_to = b.mx_dt
	left join (
		select a.mob_date_to from Temp_PTS_Test_repdates a
		union 
		select cast(a.dt as date) as mob_date_to
		from dwh2.risk.calendar a
		where a.dt = eomonth(a.dt)
		and a.dt between '2016-01-01' and @rdt	
	)
	c
	on b.mx_dt < c.mob_date_to
	;





	print ('timing, Temp_PTS_Test_npl_wo_and_recovery' + format(getdate(), 'HH:mm:ss'))


	--добавляем списания и recovery, дельты NL, GL в общую витрину
	drop table if exists Temp_PTS_Test_stg4_back_test_results;

	with base as (
		select 
		a.term, a.segment_rbp, a.flag_kk, a.generation, 
		a.mob_date_to, a.mob_to, 
		a.bucket_90_to, 
		a.fact_od, a.model_od, a.flag, a.vl_rub_fact, a.fact_model_od, a.model_fact_od,
		isnull(b.od_wo,0) as od_wo,
		isnull(b.npl_recovery,0) as npl_recovery,

		--a.fact_model_od + isnull(b.od_wo,0) as portf_wo,
		--a.fact_model_od + isnull(b.od_wo,0) + isnull(b.npl_recovery,0) as portf_wo_recov
		a.model_fact_od + isnull(b.od_wo,0) as portf_wo,
		a.model_fact_od + isnull(b.od_wo,0) + isnull(b.npl_recovery,0) as portf_wo_recov

		from Temp_PTS_Test_stg3_back_test_results a
		left join Temp_PTS_Test_npl_wo_and_recovery b
		on a.term = b.term
		and a.generation = b.generation
		and a.segment_rbp = b.segment_rbp
		and a.flag_kk = b.flag_kk
		and a.mob_date_to = b.mob_date_to
		and a.bucket_90_to = '[05] 90+'
	)

	select a.term, a.segment_rbp, a.flag_kk, a.generation, 
		a.mob_date_to, a.mob_to, 
		a.bucket_90_to, 
		a.fact_od, a.model_od, a.flag, a.vl_rub_fact, a.fact_model_od, a.model_fact_od,
		a.od_wo, a.npl_recovery, a.portf_wo, a.portf_wo_recov,

		case when a.bucket_90_to = '[05] 90+' then
		--a.fact_model_od - lag(a.fact_model_od,1,0) over (partition by a.term, a.segment_rbp, a.flag_kk, a.generation, a.bucket_90_to order by a.mob_to) end as delta_portf,
		a.model_fact_od - lag(a.model_fact_od,1,0) over (partition by a.term, a.segment_rbp, a.flag_kk, a.generation, a.bucket_90_to order by a.mob_to) end as delta_portf,
	
		case when a.bucket_90_to = '[05] 90+' then
		a.portf_wo - lag(a.portf_wo,1,0) over (partition by a.term, a.segment_rbp, a.flag_kk, a.generation, a.bucket_90_to order by a.mob_to) end as delta_portf_wo,
	
		case when a.bucket_90_to = '[05] 90+' then
		a.portf_wo_recov - lag(a.portf_wo_recov,1,0) over (partition by a.term,a.segment_rbp, a.flag_kk, a.generation, a.bucket_90_to order by a.mob_to) end as delta_portf_wo_recov,

		case 
		when a.bucket_90_to = '[06] Pay-off' and a.flag_kk like 'CESS%' and a.mob_date_to >= cast(substring(a.flag_kk,6,10) as date) --цессия
		then 0	
		when a.bucket_90_to = '[06] Pay-off' and a.mob_date_to = @dt_back_test_from
		then round(a.model_fact_od - lag(a.fact_od,1,0) over (partition by a.term,a.segment_rbp, a.flag_kk, a.generation, a.bucket_90_to order by a.mob_to) ,2)
		when a.bucket_90_to = '[06] Pay-off' and a.mob_date_to > @dt_back_test_from  
		then round(a.model_fact_od - lag(a.model_od,1,0) over (partition by a.term,a.segment_rbp, a.flag_kk, a.generation, a.bucket_90_to order by a.mob_to) ,2)

		else a.fact_model_od end as od_point_in_time

	into Temp_PTS_Test_stg4_back_test_results

	from base a
	;




	--возвращаем остаток ОД вместо суммы выдачи на 0 MoB
	with base as (
		select a.term, a.segment_rbp, a.generation, a.flag_kk, sum(cast(isnull(b.[остаток од],0) as float)) as od
		from Temp_PTS_Test_cred_reestr a
		left join Temp_PTS_Test_CMR_M b
		on a.external_id = b.external_id
		and a.generation = b.d
		where a.flag_kk <> 'BUSINESS'
		group by a.term, a.segment_rbp, a.generation, a.flag_kk
	union all -- + бизнес-займы
		select a.term, a.segment_rbp, a.generation, a.flag_kk, sum(b.principal_rest) as od
		from Temp_PTS_Test_cred_reestr a
		--left join Temp_PTS_Test_bus_stg_bal b
		left join RiskDWH.Risk.stg_fcst_bus_bal b
		on a.external_id = b.external_id
		and a.generation = b.mob_date
		where a.flag_kk = 'BUSINESS'
		group by a.term, a.segment_rbp, a.generation, a.flag_kk
	)
	update a set 
	a.fact_od = isnull(b.od,a.fact_od), 
	a.model_od = case when a.mob_date_to between @dt_back_test_from and @rdt then b.od 
				when a.mob_date_to > @rdt then a.model_od * (1.0 - (1.0 - isnull(p.coef,1.0)) * isnull(sts.koef_po,1)) --28.02.2022
				else a.model_od end,

	a.model_fact_od = isnull(case when a.mob_date_to between @dt_back_test_from and @rdt then b.od 
				when a.mob_date_to > @rdt then a.model_od * (1.0 - (1.0 - isnull(p.coef,1.0)) * isnull(sts.koef_po,1)) --28.02.2022
				else a.model_od end, b.od) ,

	a.fact_model_od = isnull(b.od, case when a.mob_date_to between @dt_back_test_from and @rdt then b.od 
				when a.mob_date_to > @rdt then a.model_od * (1.0 - (1.0 - isnull(p.coef,1.0)) * isnull(sts.koef_po,1)) --28.02.2022
				else a.model_od end),

	a.od_point_in_time = isnull(b.od, case when a.mob_date_to between @dt_back_test_from and @rdt then b.od 
				when a.mob_date_to > @rdt then a.model_od * (1.0 - (1.0 - isnull(p.coef,1.0)) * isnull(sts.koef_po,1)) --28.02.2022
				else a.model_od end)

	--select a.term, a.segment_rbp, a.generation, a.flag_kk, a.fact_od, b.od
	from Temp_PTS_Test_stg4_back_test_results a
	left join base b
	on a.term = b.term
	and a.generation = b.generation
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk

	left join Temp_PTS_Test_det_stress sts
	on a.mob_date_to between sts.dt_from and sts.dt_to

	left join Temp_PTS_Test_det_pdp_coef p
	on a.segment_rbp = p.segment_rbp

	where a.mob_to = 0
	;

	print ('timing, Temp_PTS_Test_stg4_back_test_results' + format(getdate(), 'HH:mm:ss'))




	--Вовращаем ОД для проданных, чтобы учесть в EL

	drop table if exists Temp_PTS_Test_cessed_od;
	select a.term, a.segment_rbp, a.generation, a.flag_kk, a.mob_date_to, a.bucket_90_to, 
	-1.0 * a.delta_portf_wo as portf_wo,
	-1.0 * a.delta_portf_wo_recov as portf_wo_recov

	into Temp_PTS_Test_cessed_od
	from Temp_PTS_Test_stg4_back_test_results a
	where a.flag_kk like 'CESS %'
	and a.mob_date_to = DATEFROMPARTS(substring(a.flag_kk,6,4), SUBSTRING(a.flag_kk,11,2), SUBSTRING(a.flag_kk,14,2))
	and a.bucket_90_to = '[05] 90+';



	update a set a.portf_wo = b.portf_wo, a.portf_wo_recov = b.portf_wo_recov
	from Temp_PTS_Test_stg4_back_test_results a
	inner join Temp_PTS_Test_cessed_od b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp 
	and a.generation = b.generation
	and a.flag_kk = b.flag_kk
	and a.bucket_90_to = b.bucket_90_to
	and a.mob_date_to >= b.mob_date_to
	;

	print ('timing, Temp_PTS_Test_cessed_od' + format(getdate(), 'HH:mm:ss'))







	--------------------------------------------------------------------------------------------------------
	-- PART 4 - Проверки
	--------------------------------------------------------------------------------------------------------



	/*
	select a.bucket_90_from, a.bucket_90_to, format(sum(a.model_od),'Temp_PTS_Test_Temp_PTS_Test_Temp_PTS_Test_ Temp_PTS_Test_Temp_PTS_Test_Temp_PTS_Test_ Temp_PTS_Test_Temp_PTS_Test_Temp_PTS_Test_')
	from Temp_PTS_Test_stg_freeze_model a
	where a.mob_date_to = '2022-01-31'
	and a.bucket_90_from = '[07] Freeze'
	group by a.bucket_90_from, a.bucket_90_to
	order by 1,2
	*/



	--отличие в портфеле модельном и для резервов
	--нет даты начала NPL (90+) из-за кривой ретро-просрочки!!!! --исправлено
	/*

	select a.*, sum(a.principal_rest_to) over ()
	from Temp_PTS_Test_stg_matrix_detail a
	left join Temp_PTS_Test_stg_start_default b
	on a.external_id = b.external_id
	where a.mob_date_to = '2023-11-30'
	and a.bucket_90_to = '[05] 90+'
	and b.external_id is null
	--and a.bucket_90_from in ('[03] 31-60','[01] 0')
	;
	*/


	--проверка факта - сумма коэффициентов по строке равна 1 ?
	/*

	with base as (
	select a.generation, a.term, a.segment_rbp, a.flag_kk, a.mob_to, a.bucket_90_from, a.bucket_90_to, 
	a.od_to / a.total_od_from as coef
	from Temp_PTS_Test_stg3_agg a
	where a.total_od_from <> 0
	)
	select b.generation, b.term, b.segment_rbp, b.flag_kk, b.mob_to, b.bucket_90_from, sum(b.coef)
	from base b
	group by b.generation, b.term, b.segment_rbp, b.flag_kk, b.mob_to, b.bucket_90_from
	having round(sum(b.coef),2) <> 1
	;
	*/


	--проверка смоделированной матрицы миграций

	/*
	--сумма по строке матрицы равна 1?
	select a.segment_rbp, a.flag_kk, a.term, a.generation, a.mob_to, a.bucket_90_from, round(sum(a.model_coef_adj),2)
	from Temp_PTS_Test_for_back_test a
	where cast(substring(a.bucket_90_from,2,2) as int) <= a.mob_to
	group by a.segment_rbp, a.flag_kk, a.term, a.generation, a.mob_to, a.bucket_90_from
	having round(sum(a.model_coef_adj),6) not in (0,1)
	--order by 1,2,3

	--есть ли отрицательные элементы матрицы?
	select * from Temp_PTS_Test_for_back_test a
	where a.model_coef_adj < 0
	;
	*/



	--проверка дублей
	/*

	select a.generation, a.term, a.segment_rbp , a.flag_kk, a.mob_to, a.bucket_90_to
	from Temp_PTS_Test_stg4_back_test_results a
	group by a.generation, a.term, a.segment_rbp ,a.flag_kk, a.mob_to, a.bucket_90_to
	having count(*)>1
	;
	*/





	--Отрицательные значения по суммам 
	/*

	select 
	sum(iif(a.fact_model_od < 0, 1, 0)) as cnt_neg_fact_model_od,
	sum(iif(a.fact_od < 0, 1, 0)) as cnt_neg_fact_od,
	sum(iif(a.model_od < 0, 1, 0)) as cnt_neg_model_od,
	sum(iif(a.od_point_in_time < 0, 1, 0)) as cnt_neg_od_point_in_time,
	sum(iif(a.npl_recovery < 0, 1, 0)) as cnt_neg_npl_recovery,
	sum(iif(round(a.delta_portf_wo_recov,2) < 0, 1, 0)) as cnt_neg_delta_portf_wo_recov
	from Temp_PTS_Test_stg4_back_test_results a
	where a.mob_date_to > '2024-03-31'
	;


	select *
	from Temp_PTS_Test_stg4_back_test_results a
	where a.mob_date_to > '2022-10-31'
	and round(a.delta_portf_wo_recov,2) < 0



	select * --distinct a.bucket_90_to
	from Temp_PTS_Test_stg4_back_test_results a
	where a.fact_model_od < 0 or a.model_od < 0
	order by mob_date_to;

	select * 
	from Temp_PTS_Test_stg4_back_test_results a
	where round(a.delta_portf_wo_recov,2) < 0

	select * from Temp_PTS_Test_stg4_back_test_results a
	where a.term = 12 and a.segment_rbp = 'other' and a.flag_kk = 'CESS 2021-08-31' and a.bucket_90_to = '[05] 90+' and a.generation = '2016-04-30'
	order by a.mob_to

	select distinct a.flag_kk, a.bucket_90_to
	from Temp_PTS_Test_stg4_back_test_results a
	where round(a.od_point_in_time,2) < 0;



	*/
	;

	--сравнение план-факт
	/*

	with base as (
	select a.term, a.segment_rbp,
		a.mob_date_to, 
		a.bucket_90_to, 
		sum(a.fact_od) as fact_od, 
		sum(a.model_od) as model_od, 
		sum(a.model_od - a.fact_od) as delta_od

	from Temp_PTS_Test_stg4_back_test_results a
	where a.mob_date_to in ('2024-05-31')
	and a.flag_kk = 'USUAL'
	and a.term = 48

	group by a.term, a.segment_rbp, a.mob_date_to, a.bucket_90_to
	--where a.mob_date_to >= '2021-01-01'
	)
	select a.term, a.segment_rbp,
		a.mob_date_to, 
		a.bucket_90_to, 
		a.fact_od, 
		a.model_od, 
		a.delta_od,
	
		round(case when a.fact_od = 0 then 0 else a.delta_od / a.fact_od end,4) * 100 as delta_prc,
		format(sum(a.delta_od) over (),'### ### ###') as total_delta

	from base a
	--order by delta_prc_abs desc
	order by abs(a.delta_od) desc

	*/

	;

	--Проверка EL
	/*

	with base as (
		select isnull(a.segment_rbp,'TOTAL') as segment_rbp, a.mob_to, 
		sum(a.delta_portf_wo) as chisl,
		sum(a.vl_rub_fact) as znam
		from Temp_PTS_Test_stg4_back_test_results a
		where a.bucket_90_to = '[05] 90+'
		and a.flag_kk = 'USUAL'
		--and a.term = 48
		--and a.generation = '2022-01-31'
		and a.mob_to <= 48
		and year(a.generation) >= 2022
		group by rollup(a.segment_rbp), a.mob_to
	), base2 as (
		select a.segment_rbp, a.mob_to,
		sum(a.chisl) over (partition by a.segment_rbp order by a.mob_to rows between unbounded preceding and current row) / a.znam as nl
		from base a
	)
	select * from base2 
	where mob_to = 48
	order by 3

	*/
	;

	/*


	select a.mob_date_to, format(sum(a.model_od),'Temp_PTS_Test_ Temp_PTS_Test_Temp_PTS_Test_Temp_PTS_Test_ Temp_PTS_Test_Temp_PTS_Test_Temp_PTS_Test_ Temp_PTS_Test_Temp_PTS_Test_Temp_PTS_Test_')
	from Temp_PTS_Test_stg4_back_test_results a
	where a.bucket_90_to = '[05] 90+'
	and a.mob_date_to between '2021-07-31' and '2021-12-31'
	and a.flag_kk = 'USUAL'
	group by a.mob_date_to
	order by 1;


	select aa.mob_date_to, format(sum(aa.model_od),'Temp_PTS_Test_ Temp_PTS_Test_Temp_PTS_Test_Temp_PTS_Test_ Temp_PTS_Test_Temp_PTS_Test_Temp_PTS_Test_ Temp_PTS_Test_Temp_PTS_Test_Temp_PTS_Test_')
	from (
		select a.mob_date_to, sum(a.calc_od_default - a.wo_calc_od_payoff) as model_od
		from Temp_PTS_Test_default_recovery_fact a
		where a.mob_date_to between '2021-07-31' and '2021-12-31' and a.flag_kk = 'USUAL'
		group by a.mob_date_to
		union all
		select a.mob_date_to, sum(a.calc_od_default - a.wo_calc_od_payoff) as model_od
		from Temp_PTS_Test_default_recovery_model a
		where a.mob_date_to between '2021-07-31' and '2021-12-31' and a.flag_kk = 'USUAL'
		group by a.mob_date_to
	) aa
	group by aa.mob_date_to
	order by 1

	--банкроты

	select a.mob_date_to, a.bucket_90_to, 
	sum(a.fact_od) as fact_od, 
	sum(a.model_od) as model_od
	from Temp_PTS_Test_stg4_back_test_results a
	where a.flag_kk = 'BANKRUPT'
	and a.mob_date_to <= '2022-12-31'
	and a.bucket_90_to <> '[06] Pay-off'
	group by a.mob_date_to, rollup(a.bucket_90_to)
	order by 2,1;




	with base as (
		select isnull(a.segment_rbp,'TOTAL') as segment_rbp, a.mob_to, 
		sum(a.delta_portf_wo) as chisl,
		sum(a.vl_rub_fact) as znam
		from Temp_PTS_Test_stg4_back_test_results a
		where a.bucket_90_to = '[05] 90+'
		and a.flag_kk = 'USUAL'
		--and a.term <> 48
		--and a.generation = '2022-01-31'
		and a.mob_to <= 48
		and a.mob_date_to <= eomonth('2022-12-31',48)
		and a.mob_date_to >= '2021-01-01'
		group by rollup(a.segment_rbp), a.mob_to
	), base2 as (
		select a.segment_rbp, a.mob_to,
		sum(a.chisl) over (partition by a.segment_rbp order by a.mob_to rows between unbounded preceding and current row) / a.znam as nl
		from base a
	)
	select * from base2 
	where mob_to = 48
	order by 3;



	--risk base
	select a.term, a.segment_rbp , a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.delta_portf_wo, a.vl_rub_fact
	from Temp_PTS_Test_stg4_back_test_results a
	where 1=1
	--and a.flag_kk = 'USUAL'
	and a.mob_to <= 48
	and a.bucket_90_to = '[05] 90+'
	and a.mob_date_to <= eomonth('2022-12-31',48)
	and a.mob_date_to >= '2018-01-01'


	--all base
	select * from Temp_PTS_Test_stg4_back_test_results a
	where a.mob_date_to between '2021-07-31' and '2021-12-31'
	;

	--volume
	select *
	from Temp_PTS_Test_stg4_back_test_results a
	where a.mob_to = 0 and a.bucket_90_to = '[01] 0'
	;

	select * from Temp_PTS_Test_stg4_back_test_results a
	where a.generation = '2021-10-31'
	order by a.mob_date_to
	;





	select * --distinct a.bucket_90_to
	from Temp_PTS_Test_stg4_back_test_results a
	where a.fact_model_od < 0 or a.model_od < 0
	order by mob_date_to;

	select * 
	from Temp_PTS_Test_stg4_back_test_results a
	where round(a.delta_portf_wo_recov,2) < 0
	and a.flag_kk not like 'CESS%'
	and a.mob_date_to <> '2025-11-30'
	order by a.mob_date_to desc


	select * from Temp_PTS_Test_stg4_back_test_results a
	where a.term = 24 and a.segment_rbp = 'other' and a.flag_kk = 'WRONG MIGR' and a.generation = '2016-06-30' and a.bucket_90_to = '[05] 90+'
	order by a.mob_date_to


	*/



	/*
	select a.term, a.segment_rbp, a.generation, a.flag_kk, a.mob_date_to, a.mob_to,
	a.portf_wo as chisl, a.vl_rub_fact as znam 
	from Temp_PTS_Test_stg4_back_test_results a
	where a.bucket_90_to = '[05] 90+'
	*/



	--/* P 1-2 */
	----drop table Temp_PTS_Test_CMR_M;
	----drop table Temp_PTS_Test_cred_reestr;
	----drop table Temp_PTS_Test_det_current_params;
	----drop table Temp_PTS_Test_det_pieces_L1;
	----drop table Temp_PTS_Test_det_pieces_L2;
	----drop table Temp_PTS_Test_eps;
	----drop table Temp_PTS_Test_fact_due_int;
	----drop table Temp_PTS_Test_NU_segment_distrib;
	----drop table Temp_PTS_Test_rest_model;
	----drop table Temp_PTS_Test_stg_fact_od_int_pmt;
	----drop table Temp_PTS_Test_stg_freeze_mod;
	----drop table Temp_PTS_Test_stg_matrix_detail;
	----drop table Temp_PTS_Test_stg_payment;
	----drop table Temp_PTS_Test_stg_start_default;
	----drop table Temp_PTS_Test_stg_write_off;
	----drop table Temp_PTS_Test_stg1_NU_segment_distrib;
	----drop table Temp_PTS_Test_stg3_agg;
	----drop table Temp_PTS_Test_umfo_fact;
	----drop table Temp_PTS_Test_UMFO_NU_segment;
	----drop table Temp_PTS_Test_zamorozka;
	--/* P 3 */
	--drop table Temp_PTS_Test_back_test;
	--drop table Temp_PTS_Test_back_test_acc_matr;
	--drop table Temp_PTS_Test_cessed_od;
	----drop table Temp_PTS_Test_conditional_rec_ALL;
	----drop table Temp_PTS_Test_default_recovery_fact;
	----drop table Temp_PTS_Test_default_recovery_model;
	--drop table Temp_PTS_Test_det_curve_version;
	----drop table Temp_PTS_Test_det_pdp_coef;
	----drop table Temp_PTS_Test_det_recovery_corr;
	----drop table Temp_PTS_Test_det_stress;
	----drop table Temp_PTS_Test_fix_matrix;
	----drop table Temp_PTS_Test_for_back_test;
	----drop table Temp_PTS_Test_freeze_last_fact;
	----drop table Temp_PTS_Test_last_fact;
	--drop table Temp_PTS_Test_model_adjust;
	----drop table Temp_PTS_Test_new_volume;
	--drop table Temp_PTS_Test_nodpd_payoff_model;
	--drop table Temp_PTS_Test_npl_recovery_fact;
	----drop table Temp_PTS_Test_npl_wo_and_recovery;
	--drop table Temp_PTS_Test_repdates;
	--drop table Temp_PTS_Test_season_rr_corr;
	--drop table Temp_PTS_Test_stg_back_base;
	----drop table Temp_PTS_Test_stg_freeze_model;
	--drop table Temp_PTS_Test_stg0_default_recovery_fact;
	--drop table Temp_PTS_Test_stg1_back_test_results;
	----drop table Temp_PTS_Test_stg1_default_recovery_fact;
	--drop table Temp_PTS_Test_stg1_default_recovery_model;
	--drop table Temp_PTS_Test_stg2_back_test_results;
	--drop table Temp_PTS_Test_stg2_default_recovery_model;
	--drop table Temp_PTS_Test_stg2_freeze_model;
	--drop table Temp_PTS_Test_stg3_back_test_results;
	----drop table Temp_PTS_Test_stg3_default_recovery_model;
	----drop table Temp_PTS_Test_stg4_back_test_results;
	----drop table Temp_PTS_Test_virt_gens;
	--drop table Temp_PTS_Test_write_offs_fact;




	--------------------------------------------------------------------------------------------------------
	-- PART 5 - моделирование начисленных процентов и процентных платежей
	--------------------------------------------------------------------------------------------------------



	--declare @rdt date = '2024-10-31';declare @dt_back_test_from date = '2024-11-30';declare @horizon int = datediff(MM,@rdt,'2024-07-31') + 1declare @repeat_share float = 0.62;declare @vers int = -999;


	print ('timing, start ' + format(getdate(), 'HH:mm:ss'))







	---вспомогательная таблица 1 - индексы K и L

	drop table if exists Temp_PTS_Test_stg1_interest;
	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to
		, a.bucket_90_from, a.bucket_90_to, a.fact_coef, a.model_coef_adj
		, cast(iif(a.bucket_90_from = '[06] Pay-off', 100, cast(substring(a.bucket_90_from,2,2) as int) - 1) as float) as k_idx
		, cast(iif(a.bucket_90_to = '[06] Pay-off', 100, cast(substring(a.bucket_90_to,2,2) as int) - 1) as float) as l_idx

	into Temp_PTS_Test_stg1_interest--select top 100 *
	from Temp_PTS_Test_for_back_test a
	where 1=1

	;


	print ('timing, Temp_PTS_Test_stg1_interest ' + format(getdate(), 'HH:mm:ss'))





	---вспомогательная таблица 2 - расчет коэффициентов beta (%% платежи) и d (начисленные просроченные проценты)

	drop table if exists Temp_PTS_Test_stg2_interest;

	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to
		, a.bucket_90_from, a.bucket_90_to, a.model_coef_adj,  a.k_idx, a.l_idx,
	
	case 
		--Остановка начисления по КК (увеличенный срок)
		when left(a.flag_kk,2) = 'KK' and datediff(MM,@dt_back_test_from,a.mob_date_to) >= cast(right(a.flag_kk,5) as int) and a.l_idx = 0 and a.k_idx < 100 and a.l_idx < 100
			then RiskDWH.[CM\A.Borisov].func$greatest(0, a.k_idx - a.l_idx + 1.0 - datediff(MM,@rdt,a.mob_date_to) + cast(right(a.flag_kk,5) as int) ) * (a.model_coef_adj)
		when left(a.flag_kk,2) = 'KK' and datediff(MM,@dt_back_test_from,a.mob_date_to) >= cast(right(a.flag_kk,5) as int) and a.k_idx - a.l_idx + 1 >= 0 and a.l_idx <> 0 and a.k_idx < 100 and a.l_idx < 100 and a.k_idx not in (4,6) --90+ и заморозка
			then RiskDWH.[CM\A.Borisov].func$greatest(0, a.k_idx - a.l_idx + 1.0 - datediff(MM,@rdt,a.mob_date_to) + cast(right(a.flag_kk,5) as int) ) * (a.model_coef_adj)
		when left(a.flag_kk,2) = 'KK' and datediff(MM,@dt_back_test_from,a.mob_date_to) >= cast(right(a.flag_kk,5) as int) and a.l_idx = 100 
			then RiskDWH.[CM\A.Borisov].func$greatest(0, a.k_idx + 1.0 - datediff(MM,@rdt,a.mob_date_to) + cast(right(a.flag_kk,5) as int) ) * (a.model_coef_adj)

		--Остановка начисления по достижению 1.5х (1.3х) для ПТС31 
		when left(a.flag_kk,11) = 'STOP_CHARGE' and datediff(MM,@dt_back_test_from,a.mob_date_to) >= cast(right(a.flag_kk,5) as int) and a.l_idx = 0 and a.k_idx < 100 and a.l_idx < 100
			then RiskDWH.[CM\A.Borisov].func$greatest(0, a.k_idx - a.l_idx + 1.0 - datediff(MM,@rdt,a.mob_date_to) + cast(right(a.flag_kk,5) as int) ) * (a.model_coef_adj)
		when left(a.flag_kk,11) = 'STOP_CHARGE' and datediff(MM,@dt_back_test_from,a.mob_date_to) >= cast(right(a.flag_kk,5) as int) and a.k_idx - a.l_idx + 1 >= 0 and a.l_idx <> 0 and a.k_idx < 100 and a.l_idx < 100 and a.k_idx not in (4,6) --90+ и заморозка
			then RiskDWH.[CM\A.Borisov].func$greatest(0, a.k_idx - a.l_idx + 1.0 - datediff(MM,@rdt,a.mob_date_to) + cast(right(a.flag_kk,5) as int) ) * (a.model_coef_adj)
		when left(a.flag_kk,11) = 'STOP_CHARGE' and datediff(MM,@dt_back_test_from,a.mob_date_to) >= cast(right(a.flag_kk,5) as int) and a.l_idx = 100 
			then RiskDWH.[CM\A.Borisov].func$greatest(0, a.k_idx + 1.0 - datediff(MM,@rdt,a.mob_date_to) + cast(right(a.flag_kk,5) as int) ) * (a.model_coef_adj)

		when a.l_idx = 0 and a.k_idx < 100 and a.l_idx < 100
			then (a.k_idx - a.l_idx + 1.0) * (a.model_coef_adj)
		when a.k_idx - a.l_idx + 1 >= 0 and a.l_idx <> 0 and a.k_idx < 100 and a.l_idx < 100 and a.k_idx not in (4,6) --90+ и заморозка
			then (a.k_idx - a.l_idx + 1.0) * (a.model_coef_adj)
		when a.l_idx = 100 
			then (a.k_idx + 1.0) * (a.model_coef_adj)
		else 0 end 
	--* case when a.bucket_90_from = '[01] 0' and a.bucket_90_to = '[01] 0' then isnull(sts.koef_po,1) else 1.0 end --28.02.2022
	as int_pmt_coef,

	case 
		when left(a.flag_kk,2) = 'KK' and datediff(MM,@dt_back_test_from,a.mob_date_to) >= cast(right(a.flag_kk,5) as int) --конец графика для КК
			then 0
		when a.mob_to > a.term and left(a.flag_kk,11) <> 'STOP_CHARGE' --после окончания графика прекращаем начисления
			then 0
		when left(a.flag_kk,11) = 'STOP_CHARGE' and datediff(MM,@dt_back_test_from,a.mob_date_to) >= cast(right(a.flag_kk,5) as int) --Остановка начисления по достижению 1.5х (1.3х) для ПТС31 
			then 0
		when a.l_idx = 0 and a.k_idx < 100 and a.l_idx < 100
			then (a.l_idx - a.k_idx) * (a.model_coef_adj)
		when a.k_idx - a.l_idx + 1 >= 0 and a.l_idx <> 0 and a.k_idx < 100 and a.l_idx < 100 and a.k_idx not in (4,6) --90+ и заморозка
			then (a.l_idx - a.k_idx) * (a.model_coef_adj)
		when a.l_idx = 100
			then (-1.0 * a.k_idx) * (a.model_coef_adj)
		when a.l_idx = 4 and a.k_idx = 4 and a.mob_to > a.term --90+ --> 90+, после окончания графика прекращаем начисления
			then 0
		when a.l_idx = 4 and a.k_idx = 4 --90+ --> 90+
			then a.model_coef_adj
		when a.l_idx = 6 and a.k_idx = 6 --Freeze --> Freeze
			then 1
		else 0 end 
	as int_ovr_coef

	into Temp_PTS_Test_stg2_interest

	from Temp_PTS_Test_stg1_interest a
	left join Temp_PTS_Test_det_stress sts --28.02.2022
	on a.mob_date_to between sts.dt_from and sts.dt_to

	;




	drop table if exists Temp_PTS_Test_upd_stg2_interest;
	with base as (
		select hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
		a.* 
		from Temp_PTS_Test_stg2_interest a
		where a.bucket_90_from <> '[06] Pay-off'
	), base2 as (
	select * from base a
	where a.bucket_90_to = '[06] Pay-off'
	)
	select a.id1, a.bucket_90_from, a.bucket_90_to, a.mob_date_to, 
	a.int_ovr_coef + b.int_ovr_coef as int_ovr_coef,
	a.int_pmt_coef + b.int_pmt_coef as int_pmt_coef
	into Temp_PTS_Test_upd_stg2_interest
	from base a
	left join base2 b
	on a.id1 = b.id1
	and a.bucket_90_from = b.bucket_90_from
	and a.mob_date_to = b.mob_date_to
	where a.bucket_90_to = '[01] 0'
	;

	update a set a.int_ovr_coef = b.int_ovr_coef, a.int_pmt_coef = b.int_pmt_coef 
	from Temp_PTS_Test_stg2_interest a
	inner join Temp_PTS_Test_upd_stg2_interest b
	on hashbytes('MD2',concat(a.term,a.segment_rbp,a.generation,a.flag_kk)) = b.id1
	and a.mob_date_to = b.mob_date_to
	and a.bucket_90_from = b.bucket_90_from
	and a.bucket_90_to = b.bucket_90_to
	;


	print ('timing, Temp_PTS_Test_stg2_interest ' + format(getdate(), 'HH:mm:ss'))






	


	--Контрактные процентные ставки (месячные), средневзвешенные. Для новых виртуальных поколений берем по последнему доступному факту
	drop table if exists Temp_PTS_Test_stg_int_rates;
	with rates as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, 
		sum(isnull(b.cur_rate,a.int_rate) * a.amount) / sum(a.amount) / 100.0 / 12.0 as avg_int_rate,
		sum(a.int_rate * a.amount) / sum(a.amount) / 100.0 / 12.0 as iss_avg_int_rate	
		from Temp_PTS_Test_cred_reestr a
		left join Temp_PTS_Test_det_current_params b
		on a.external_id = b.external_id
		where a.generation <= @rdt
		group by a.term, a.segment_rbp, a.flag_kk, a.generation
	), current_groups as (
		select distinct a.term, a.segment_rbp, a.flag_kk, a.generation from Temp_PTS_Test_stg4_back_test_results a
	), base as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, b.avg_int_rate, b.generation as additional_gen,
		ROW_NUMBER() over (partition by a.term, a.segment_rbp, a.flag_kk, a.generation order by b.generation desc) as rown 
		from current_groups a
		left join rates b
		on a.term = b.term
		and a.segment_rbp = b.segment_rbp
		and a.flag_kk = b.flag_kk
		and a.generation >= b.generation
	)
	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.avg_int_rate as avg_month_int_rate 
	into Temp_PTS_Test_stg_int_rates
	from base a
	where a.rown = 1
	;


	--	Ставки для виртуальных поколений

	/*
	select segment_rbp, flag_kk
		, count(*) as cnt, round(sum(amount * int_rate)/sum(amount), 2) as avg_w_int_rate--select top 100 *
	from Temp_PTS_Test_cred_reestr where year(generation) = 2025 and flag_kk = 'USUAL'
	group by segment_rbp, flag_kk
	
	union

	select 'Total', 'Total'
		, count(*) as cnt, round(sum(amount * int_rate)/sum(amount), 2) as avg_w_int_rate--select top 100 *
	from Temp_PTS_Test_cred_reestr where year(generation) = 2025 and flag_kk = 'USUAL'
	order by 1, 2
	*/


	update Temp_PTS_Test_stg_int_rates set avg_month_int_rate = (select round(sum(amount * int_rate)/sum(amount), 0) - 2.49 from Temp_PTS_Test_cred_reestr where year(generation) = 2025 and flag_kk = 'USUAL' and segment_rbp = 'other' group by segment_rbp, flag_kk) / 100.0 / 12.0	where segment_rbp = 'other'		and flag_kk = 'USUAL' and eomonth(generation, 0) >= @dt_back_test_from;
	update Temp_PTS_Test_stg_int_rates set avg_month_int_rate = (select round(sum(amount * int_rate)/sum(amount), 0) - 2.49 from Temp_PTS_Test_cred_reestr where year(generation) = 2025 and flag_kk = 'USUAL' and segment_rbp = 'PTS31_RBP4' group by segment_rbp, flag_kk) / 100.0 / 12.0	where segment_rbp = 'PTS31_RBP4'	and flag_kk = 'USUAL' and eomonth(generation, 0) >= @dt_back_test_from;
	update Temp_PTS_Test_stg_int_rates set avg_month_int_rate = (select round(sum(amount * int_rate)/sum(amount), 0) - 2.49 from Temp_PTS_Test_cred_reestr where year(generation) = 2025 and flag_kk = 'USUAL' and segment_rbp = 'RBP 1' group by segment_rbp, flag_kk) / 100.0 / 12.0	where segment_rbp = 'RBP 1'				and flag_kk = 'USUAL' and eomonth(generation, 0) >= @dt_back_test_from;
	update Temp_PTS_Test_stg_int_rates set avg_month_int_rate = (select round(sum(amount * int_rate)/sum(amount), 0) - 2.49 from Temp_PTS_Test_cred_reestr where year(generation) = 2025 and flag_kk = 'USUAL' and segment_rbp = 'RBP 2' group by segment_rbp, flag_kk) / 100.0 / 12.0	where segment_rbp = 'RBP 2'				and flag_kk = 'USUAL' and eomonth(generation, 0) >= @dt_back_test_from;
	update Temp_PTS_Test_stg_int_rates set avg_month_int_rate = (select round(sum(amount * int_rate)/sum(amount), 0) - 2.49 from Temp_PTS_Test_cred_reestr where year(generation) = 2025 and flag_kk = 'USUAL' and segment_rbp = 'RBP 3' group by segment_rbp, flag_kk) / 100.0 / 12.0	where segment_rbp = 'RBP 3'				and flag_kk = 'USUAL' and eomonth(generation, 0) >= @dt_back_test_from;
	update Temp_PTS_Test_stg_int_rates set avg_month_int_rate = (select round(sum(amount * int_rate)/sum(amount), 0) - 2.49 from Temp_PTS_Test_cred_reestr where year(generation) = 2025 and flag_kk = 'USUAL' and segment_rbp = 'RBP 4' group by segment_rbp, flag_kk) / 100.0 / 12.0	where segment_rbp = 'RBP 4'				and flag_kk = 'USUAL' and eomonth(generation, 0) >= @dt_back_test_from;

	--;


	print ('timing, Temp_PTS_Test_stg_int_rates ' + format(getdate(), 'HH:mm:ss'))



	---вспомогательная таблица 5 - финальные коэффициенты для матриц процентов (платежи и начисленные просроченные)
	--declare @dt_back_test_from date = '2021-07-31';
	drop table if exists Temp_PTS_Test_stg5_interest;

	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.bucket_90_from, a.bucket_90_to, 
	isnull(a.int_pmt_coef,0) * isnull(c.avg_month_int_rate,0) as B_coef,
	isnull(a.int_ovr_coef,0) * isnull(c.avg_month_int_rate,0) as D_coef

	into Temp_PTS_Test_stg5_interest--select *
	from Temp_PTS_Test_stg2_interest a
	left join Temp_PTS_Test_stg_int_rates c
	on a.term = c.term
	and a.segment_rbp = c.segment_rbp
	and a.flag_kk = c.flag_kk
	and a.generation = c.generation
	--where a.mob_date_to = '2025-06-30' and year(a.generation) = 2025
	;

	--По банкротам нет начислений и выплат по процентам

	update a set a.B_coef = 0, a.D_coef = 0
	from Temp_PTS_Test_stg5_interest a
	where a.flag_kk in ('BANKRUPT');


	print ('timing, Temp_PTS_Test_stg5_interest ' + format(getdate(), 'HH:mm:ss'))






	--модель процентных платежей + начисленных просроченных процентов (по матрицам миграций)
	----бакеты 0-90
	drop table if exists Temp_PTS_Test_stg_interest_model;

	select 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, a.segment_rbp, a.flag_kk, a.generation, /*a.vl_rub_fact,*/ b.mob_date_to, b.mob_to, 
	iif(b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+', 0, null) as mod_num,
	iif(b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+', 0, null) as last_MOD,
	b.bucket_90_from, b.bucket_90_to,
	--case when b.bucket_90_from <> '[01] 0' and b.bucket_90_to = '[01] 0' then b.bucket_90_from else b.bucket_90_to end as bucket_90_to,
	--sum(a.fact_model_od * b.B_coef) as int_pmt,
	--sum(a.fact_model_od * b.D_coef) as ovr_int_balance
	cast(null as date) as freeze_from,
	--sum(a.model_fact_od * b.B_coef * 12.0 * day(b.mob_date_to) / 365.0 ) as int_pmt, --07/12/2021 учитываем кол-во дней в месяце
	--sum(a.model_fact_od * b.D_coef * 12.0 * day(b.mob_date_to) / 365.0 ) as ovr_int_balance --07/12/2021 учитываем кол-во дней в месяце
	-----27.05.2024 вместо ОД для 1 MoB берем VOLUME - по такой логике моделировался ОД
	sum(case when a.mob_to = 0 then a.vl_rub_fact else a.model_fact_od end * b.B_coef * 12.0 * day(b.mob_date_to) / 365.0 ) as int_pmt, 
	sum(case when a.mob_to = 0 then a.vl_rub_fact else a.model_fact_od end * b.D_coef * 12.0 * day(b.mob_date_to) / 365.0 ) as ovr_int_balance 

	into Temp_PTS_Test_stg_interest_model

	from Temp_PTS_Test_stg4_back_test_results a
	left join Temp_PTS_Test_stg5_interest b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	and a.generation = b.generation
	and a.mob_to = b.mob_to - 1
	and a.bucket_90_to = b.bucket_90_from

	where 1=1
	and a.bucket_90_to <> '[05] 90+'
	and left(a.flag_kk,2) <> 'KK'
	and b.bucket_90_to <> '[05] 90+'

	group by 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.segment_rbp, a.flag_kk, a.generation, b.mob_date_to, b.mob_to, b.bucket_90_from, b.bucket_90_to
	;


	print ('timing, Temp_PTS_Test_stg_interest_model USUAL 0-90 ' + format(getdate(), 'HH:mm:ss'));




	--средний портфель в качестве базы начисления %% на NPL
	drop table if exists Temp_PTS_Test_NPL_avg_portf;

	with un as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, 
		cast('[05] 90+' as varchar(100)) as bucket_90_to, 
		a.mod_num, a.last_MOD, 
		eomonth(a.mob_date_to, -1 * isnull(a.mod_num,-999)) as default_dt1,
		eomonth(a.mob_date_to, -1 * isnull(a.last_MOD,-999)) as default_dt2,
		a.calc_od_default - a.wo_calc_od_payoff as model_od 
		from Temp_PTS_Test_stg3_default_recovery_model a
		where a.model_od > 0
		and left(a.flag_kk,2) <> 'KK'
	union all
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, DATEDIFF(MM, a.generation, a.mob_date_to) as mob_to, 
		cast('[05] 90+' as varchar(100)) as bucket_90_to, 
		a.mod_num, a.last_MOD, 
		eomonth(a.mob_date_to, -1 * isnull(a.mod_num,-999)) as default_dt1,
		eomonth(a.mob_date_to, -1 * isnull(a.last_MOD,-999)) as default_dt2,
		a.calc_od_default - a.wo_calc_od_payoff as model_od 
		from Temp_PTS_Test_stg1_default_recovery_fact a
		where a.calc_od_default > 0
		and left(a.flag_kk,2) <> 'KK'
	union all --факт
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.bucket_90_to, 
		--case when a.dpd_to > 90 then floor((cast(a.dpd_to as float) - 90.0)/ 30.0) end as mod_num,
		case when a.dpd_to > 90 then DATEDIFF(MM, d.month_default_from, a.mob_date_to) end as mod_num,
		case when a.dpd_to > 90 then floor((cast(a.dpd_to as float) - 91.0) / 30.0) end as last_MOD,
		case when a.dpd_to > 90 then d.month_default_from end as default_dt1,
		case when a.dpd_to > 90 then eomonth(a.mob_date_to, -1 * floor((cast(a.dpd_to as float) - 91.0) / 30.0)) end as default_dt2,
		sum(a.principal_rest_to) as od
		from Temp_PTS_Test_stg_matrix_detail a
		left join Temp_PTS_Test_stg_start_default d
		on a.external_id = d.external_id
		and d.month_default_from <= a.mob_date_to
		where a.bucket_90_to = '[05] 90+'
		and left(a.flag_kk,2) <> 'KK'
		and a.mob_date_to < @dt_back_test_from
		group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.bucket_90_to, 
		--case when a.dpd_to > 90 then floor((cast(a.dpd_to as float) - 90.0)/ 30.0) end
		case when a.dpd_to > 90 then DATEDIFF(MM, d.month_default_from, a.mob_date_to) end,
		case when a.dpd_to > 90 then floor((cast(a.dpd_to as float) - 91.0) / 30.0) end,
		case when a.dpd_to > 90 then d.month_default_from end,
		case when a.dpd_to > 90 then eomonth(a.mob_date_to, -1 * floor((cast(a.dpd_to as float) - 91.0) / 30.0)) end
	)
	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mod_num, a.last_MOD, 
	a.mob_to, a.bucket_90_to,
	(a.model_od + isnull(b.model_od,a.model_od)) / 2.0 as model_od

	into Temp_PTS_Test_NPL_avg_portf
	from un a
	left join un b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	and a.generation = b.generation
	and a.default_dt1 = b.default_dt1 
	and a.default_dt2 = b.default_dt2
	and a.mob_date_to = eomonth(b.mob_date_to,1)
	--where a.last_MOD > 0

	;




	print ('timing, Temp_PTS_Test_NPL_avg_portf' + format(getdate(), 'HH:mm:ss'));


	--бакеты 90+ - через MOD_NUM - кол-во месяцев в дефолте

	insert into Temp_PTS_Test_stg_interest_model

	--select 
	--hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	--a.term, a.segment_rbp, a.flag_kk, a.generation, b.mob_date_to, b.mob_to, 
	--iif(b.bucket_90_to = '[05] 90+', a.mod_num + 1, null) as mod_num,
	--iif(b.bucket_90_to = '[05] 90+', a.last_MOD + 1, null) as last_MOD,

	--b.bucket_90_from, b.bucket_90_to,
	--cast(null as date) as freeze_from,
	--sum(a.model_od * b.B_coef * 12.0 / 365.0 * day(b.mob_date_to) ) as int_pmt, --07/12/2021 учитываем кол-во дней в месяце
	--sum(a.model_od * b.D_coef * 12.0 / 365.0 * day(b.mob_date_to) ) as ovr_int_balance
	--from Temp_PTS_Test_NPL_avg_portf a
	--left join Temp_PTS_Test_stg5_interest b
	--on a.term = b.term
	--and a.segment_rbp = b.segment_rbp
	--and a.flag_kk = b.flag_kk
	--and a.generation = b.generation
	--and a.mob_to = b.mob_to - 1
	--and a.bucket_90_to = b.bucket_90_from
	--where a.bucket_90_to = '[05] 90+' and left(a.flag_kk,2) <> 'KK'
	--group by 
	--hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	--a.term, a.segment_rbp, a.flag_kk, a.generation, b.mob_date_to, b.mob_to, iif(b.bucket_90_to = '[05] 90+', a.mod_num + 1, null), b.bucket_90_from, b.bucket_90_to,
	--iif(b.bucket_90_to = '[05] 90+', a.last_MOD + 1, null)
	--;

	select 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, a.segment_rbp, a.flag_kk, a.generation, 
	a.mob_date_to, 
	a.mob_to, 
	a.mod_num,
	a.last_MOD,
	b.bucket_90_from, b.bucket_90_to,
	cast(null as date) as freeze_from,
	sum(a.model_od * b.B_coef * 12.0 / 365.0 * day(a.mob_date_to) ) as int_pmt, --07/12/2021 учитываем кол-во дней в месяце
	sum(a.model_od * b.D_coef * 12.0 / 365.0 * day(a.mob_date_to) ) as ovr_int_balance
	from Temp_PTS_Test_NPL_avg_portf a
	left join Temp_PTS_Test_stg5_interest b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	and a.generation = b.generation
	and a.mob_to = b.mob_to
	and a.bucket_90_to = b.bucket_90_to
	and b.bucket_90_from = '[05] 90+'

	where a.bucket_90_to = '[05] 90+' and left(a.flag_kk,2) <> 'KK' 
	group by 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.segment_rbp, a.flag_kk, a.generation, 
	a.mob_date_to, 
	a.mob_to, 
	a.mod_num,
	a.last_MOD,
	b.bucket_90_from, b.bucket_90_to
	;




	print ('timing, Temp_PTS_Test_stg_interest_model USUAL 90+ ' + format(getdate(), 'HH:mm:ss'));



	------------------------------------------------------


	drop table if exists Temp_PTS_Test_stg_freeze_int_last_fact;
	with base as (
		select a.r_date, a.term, a.segment_rbp, a.flag_kk, a.generation, 
		sum(a.chisl_avg_int_rate) / sum(a.znam_avg_int_rate) as avg_int_rate,
		sum(a.total_od) as total_od,
		sum(a.total_int) as total_int
		from Temp_PTS_Test_fact_due_int a
		where a.r_date = eomonth(@dt_back_test_from,-1) and left(a.flag_kk,2) = 'KK'
		group by a.r_date, a.term, a.segment_rbp, a.flag_kk, a.generation
	)
	select a.r_date, a.term, a.segment_rbp, a.flag_kk, a.generation, a.total_od, a.total_int, a.avg_int_rate,
	case when a.total_od = 0 then null
	else eomonth(a.r_date, -1 * CEILING(a.total_int / a.total_od / (a.avg_int_rate / 12.0 / 100.0)))
	end as dt_int_from
	into Temp_PTS_Test_stg_freeze_int_last_fact
	from base a
	;




	--ОД для 90+ по каникулам с учетом исходящего бакета

	drop table if exists Temp_PTS_Test_stg22_default_recovery_model;
	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.mod_num, a.last_MOD, a.freeze_from, a.bucket_90_from,
	eomonth(a.mob_date_to, -1 * a.mod_num) as default_dt,
	sum(a.model_od) as model_od
	into Temp_PTS_Test_stg22_default_recovery_model
	from Temp_PTS_Test_stg_freeze_model a
	where a.bucket_90_to = '[05] 90+'
	and a.mod_num is not null
	and a.mod_num >= 0
	--and a.model_od > 0
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.mod_num, a.last_MOD, a.freeze_from, a.bucket_90_from
	;

	print ('timing, Temp_PTS_Test_stg22_default_recovery_model' + format(getdate(), 'HH:mm:ss'))



	--declare @rdt date = '2024-10-31';declare @dt_back_test_from date = '2024-11-30';declare @horizon int = datediff(MM,@rdt,'2030-12-31') + 1;declare @repeat_share float = 0.62;declare @vers int = 369;


		drop table if exists Temp_PTS_Test_stg33_default_recovery_model;

		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.mod_num, a.last_MOD, a.freeze_from, a.bucket_90_from,
		a.model_od,
		exp(sum(log( 1.0 - isnull(b.recov_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) as coef,
		exp(sum(log( 1.0 - isnull(b.recov_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) * a.model_od as calc_od_default,
		(1 - exp(sum(log( 1.0 - isnull(b.recov_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0	end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) ) * a.model_od as calc_od_payoff,


		exp(sum(log( 1.0 - isnull(b.wo_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) as wo_coef,
		exp(sum(log( 1.0 - isnull(b.wo_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) * a.model_od as wo_calc_od_default,
		(1 - exp(sum(log( 1.0 - isnull(b.wo_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) ) * a.model_od as wo_calc_od_payoff,


		exp(sum(log( 1.0 - isnull(b.recov_int_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) as recov_int_coef,
		exp(sum(log( 1.0 - isnull(b.recov_int_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) * a.model_od as calc_int_default,
		(1 - exp(sum(log( 1.0 - isnull(b.recov_int_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) ) * a.model_od as calc_int_payoff,


		exp(sum(log( 1.0 - isnull(b.wo_int_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) as int_wo_coef,
		exp(sum(log( 1.0 - isnull(b.wo_int_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) * a.model_od as int_wo_calc_od_default,
		(1 - exp(sum(log( 1.0 - isnull(b.wo_int_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) ) * a.model_od as int_wo_calc_od_payoff,

		exp(sum(log( 1.0 - isnull(b.fee_rec_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) as fee_coef,
		exp(sum(log( 1.0 - isnull(b.fee_rec_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) * a.model_od as fee_calc_od_default,
		(1 - exp(sum(log( 1.0 - isnull(b.fee_rec_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) ) * a.model_od as fee_calc_od_payoff,


		exp(sum(log( 1.0 - isnull(b.straf_recovery_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) as straf_coef,
		exp(sum(log( 1.0 - isnull(b.straf_recovery_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) * a.model_od as straf_calc_od_default,
		(1 - exp(sum(log( 1.0 - isnull(b.straf_recovery_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) ) * a.model_od as straf_calc_od_payoff


		into Temp_PTS_Test_stg33_default_recovery_model

		from Temp_PTS_Test_stg22_default_recovery_model a
		left join Temp_PTS_Test_conditional_rec_ALL b
		--on a.mod_num >= b.mod_num
		on b.mod_num between a.mod_num - DATEDIFF(MM, @dt_back_test_from, a.mob_date_to) and a.mod_num
		--and iif(a.flag_kk <> 'Installment', 'PTS', 'Installment') = b.product
		and case
		when a.segment_rbp = 'PTS31' and DATEDIFF(MM, a.generation, EOMONTH(a.mob_date_to, -1 * a.mod_num)) >= 8 then 'PTS'
		when a.segment_rbp = 'PTS31' then 'PTS31' 
		when a.flag_kk = 'Installment' then 'Installment'
		when a.flag_kk = 'BUSINESS' then 'BUSINESS'
		else 'PTS' end = b.product
		and eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num) between b.dt_from and b.dt_to

		left join Temp_PTS_Test_det_recovery_corr d
		on eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num) = d.r_date


		where a.mod_num >= 0
		and a.mob_date_to = @dt_back_test_from

		group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.mod_num, a.model_od, a.last_MOD, a.freeze_from, a.bucket_90_from;










	declare @cycle_dt3 date = eomonth(@dt_back_test_from,1);


	while @cycle_dt3 <= EOMONTH(@dt_back_test_from, @horizon)  begin

		insert into Temp_PTS_Test_stg33_default_recovery_model

		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.mod_num, a.last_MOD, a.freeze_from, a.bucket_90_from,
		a.model_od,
		exp(sum(log( 1.0 - isnull(b.recov_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) as coef,
		exp(sum(log( 1.0 - isnull(b.recov_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) * a.model_od as calc_od_default,
		(1 - exp(sum(log( 1.0 - isnull(b.recov_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0	end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) ) * a.model_od as calc_od_payoff,


		exp(sum(log( 1.0 - isnull(b.wo_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) as wo_coef,
		exp(sum(log( 1.0 - isnull(b.wo_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) * a.model_od as wo_calc_od_default,
		(1 - exp(sum(log( 1.0 - isnull(b.wo_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) ) * a.model_od as wo_calc_od_payoff,


		exp(sum(log( 1.0 - isnull(b.recov_int_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) as recov_int_coef,
		exp(sum(log( 1.0 - isnull(b.recov_int_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) * a.model_od as calc_int_default,
		(1 - exp(sum(log( 1.0 - isnull(b.recov_int_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) ) * a.model_od as calc_int_payoff,


		exp(sum(log( 1.0 - isnull(b.wo_int_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) as int_wo_coef,
		exp(sum(log( 1.0 - isnull(b.wo_int_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) * a.model_od as int_wo_calc_od_default,
		(1 - exp(sum(log( 1.0 - isnull(b.wo_int_rate * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0) * isnull(d.WOcoef,1.0) ,0) ))) ) * a.model_od as int_wo_calc_od_payoff,

		exp(sum(log( 1.0 - isnull(b.fee_rec_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) as fee_coef,
		exp(sum(log( 1.0 - isnull(b.fee_rec_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) * a.model_od as fee_calc_od_default,
		(1 - exp(sum(log( 1.0 - isnull(b.fee_rec_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) ) * a.model_od as fee_calc_od_payoff,


		exp(sum(log( 1.0 - isnull(b.straf_recovery_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) as straf_coef,
		exp(sum(log( 1.0 - isnull(b.straf_recovery_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) * a.model_od as straf_calc_od_default,
		(1 - exp(sum(log( 1.0 - isnull(b.straf_recovery_rate * 
		case month(eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num)) when 12 then 1.2 when 1 then 0.8 else 1.0 end * isnull(d.coef,1.0) * iif(left(a.flag_kk,2) = 'KK', 0.5, 1.0)
		,0) ))) ) * a.model_od as straf_calc_od_payoff	

		from Temp_PTS_Test_stg22_default_recovery_model a
		left join Temp_PTS_Test_conditional_rec_ALL b
		--on a.mod_num >= b.mod_num
		on b.mod_num between a.mod_num - DATEDIFF(MM, @dt_back_test_from, a.mob_date_to) and a.mod_num
		--and iif(a.flag_kk <> 'Installment', 'PTS', 'Installment') = b.product
		and case
		when a.segment_rbp = 'PTS31' and DATEDIFF(MM, a.generation, EOMONTH(a.mob_date_to, -1 * a.mod_num)) >= 8 then 'PTS'
		when a.segment_rbp = 'PTS31' then 'PTS31' 
		when a.flag_kk = 'Installment' then 'Installment'
		when a.flag_kk = 'BUSINESS' then 'BUSINESS'
		else 'PTS' end = b.product
		and eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num) between b.dt_from and b.dt_to

		left join Temp_PTS_Test_det_recovery_corr d
		on eomonth(a.mob_date_to, b.mod_num - 1 * a.mod_num) = d.r_date


		where a.mod_num >= 0
		and a.mob_date_to = @cycle_dt3

		group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.mod_num, a.model_od, a.last_MOD, a.freeze_from, a.bucket_90_from;


		print ('timing, Temp_PTS_Test_stg33_default_recovery_model @cycle_dt3 = ' + format(@cycle_dt3, 'dd.MM.yyyy') + ' ' + format(getdate(), 'HH:mm:ss'));

	set @cycle_dt3 = eomonth(@cycle_dt3,1);
	end 


	print ('timing, Temp_PTS_Test_stg33_default_recovery_model' + format(getdate(), 'HH:mm:ss'));



	---средний портфель в качестве базы начисления %% на NPL - Кредитные каникулы и заморозка
	drop table if exists Temp_PTS_Test_NPL2_avg_portf;
	with base as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, 
		a.bucket_90_from,
		cast('[05] 90+' as varchar(100)) as bucket_90_to, 
		a.calc_od_default - a.wo_calc_od_payoff as model_od,
		a.freeze_from,
		a.mod_num, 
		a.last_MOD,
		EOMONTH(a.mob_date_to, -1 * a.mod_num) as dt_default1,
		EOMONTH(a.mob_date_to, -1 * a.last_MOD) as dt_default2
		from Temp_PTS_Test_stg33_default_recovery_model a
		where a.model_od > 0
		and left(a.flag_kk,2) = 'KK'
	), agg as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
		a.freeze_from, a.dt_default1, a.dt_default2, sum(a.model_od) as model_od
		from base a 
		where a.bucket_90_from = '[05] 90+'
		group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
		a.freeze_from, a.dt_default1, a.dt_default2
	)
	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to,
	a.freeze_from, a.mod_num, a.last_MOD, a.bucket_90_from,
	case 
	when a.bucket_90_from = '[05] 90+' and b.model_od > a.model_od then (a.model_od + isnull(b.model_od, a.model_od)) / 2.0 
	else a.model_od
	end as model_od

	--, a.model_od, b.model_od

	into Temp_PTS_Test_NPL2_avg_portf
	from base a
	left join agg b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp 
	and a.flag_kk = b.flag_kk
	and a.generation = b.generation
	and isnull(a.freeze_from,'1111-01-01') = isnull(b.freeze_from,'1111-01-01')
	and a.dt_default1 = b.dt_default1
	and a.dt_default2 = b.dt_default2
	and a.mob_date_to = eomonth(b.mob_date_to,1)
	--where a.last_MOD > 0 --не требуется, т.к. есть bucket_from и переход 61-90 -- 91+ в следующей таблице исключается из 0-90
	;






	--Кредитные каникулы (заморозка)
	with base as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, 
		a.bucket_90_from, a.bucket_90_to,
		a.model_od,
		a.freeze_from,
		a.mod_num,	
		a.last_MOD,
		b.avg_month_int_rate * 12.0 as int_rate, --b.virt_int_rate,
		--c.dt_int_from,	
		cast(substring(a.bucket_90_from,2,2) as int) as K,
		cast(substring(a.bucket_90_to,2,2) as int) as L,
		case 
		when a.bucket_90_to = '[06] Pay-off' then cast(substring(a.bucket_90_from,2,2) as int) - 1 + 1
		else cast(substring(a.bucket_90_from,2,2) as int) - cast(substring(a.bucket_90_to,2,2) as int) + 1 end as [K-L+1],

		case 
		when a.bucket_90_to = '[06] Pay-off' then 1 - cast(substring(a.bucket_90_from,2,2) as int)
		else cast(substring(a.bucket_90_to,2,2) as int) - cast(substring(a.bucket_90_from,2,2) as int) end as [L-K]

		from Temp_PTS_Test_stg_freeze_model a
		left join Temp_PTS_Test_stg_int_rates b--Temp_PTS_Test_stg4_interest b
		on a.term = b.term
		and a.segment_rbp = b.segment_rbp
		and a.flag_kk = b.flag_kk 
		and a.generation = b.generation

		where a.bucket_90_to <> '[05] 90+'
	union all
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, 
		a.bucket_90_from,
		cast('[05] 90+' as varchar(100)) as bucket_90_to, 
		--a.calc_od_default - a.wo_calc_od_payoff as model_od,
		a.model_od,
		a.freeze_from,
		a.mod_num, 
		a.last_MOD,
		b.avg_month_int_rate * 12.0 as int_rate, --b.virt_int_rate,
		cast(substring(a.bucket_90_from,2,2) as int) as K,
		5 as L,
		cast(substring(a.bucket_90_from,2,2) as int) - 5 + 1 as [K-L+1],
		5 - cast(substring(a.bucket_90_from,2,2) as int) as [L-K]
		from Temp_PTS_Test_NPL2_avg_portf a --Temp_PTS_Test_stg33_default_recovery_model a
		left join Temp_PTS_Test_stg_int_rates b--Temp_PTS_Test_stg4_interest b
		on a.term = b.term
		and a.segment_rbp = b.segment_rbp
		and a.flag_kk = b.flag_kk 
		and a.generation = b.generation
		where a.model_od > 0
		and left(a.flag_kk,2) = 'KK'
	)
	insert into Temp_PTS_Test_stg_interest_model

	select 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, 
	a.mod_num, a.last_MOD, a.bucket_90_from, a.bucket_90_to, a.freeze_from,
	--a.model_od, a.freeze_from,  a.virt_int_rate,
	--a.K, a.L, a.[K-L+1], a.[L-K],
	sum(case 
		when a.[K-L+1] < 0 then 0 
		when a.K = 6 then 0 --FROM pay-off
		when a.K = 5 then 0 --90+
		when a.K = 7 and a.L in (5,7) then 0 /*остается в заморозке или переходит в 90+*/ --freeze
		when a.K = 7 and a.L = 1 then 1 /*переход в [0]*/ --freeze
		when a.K = 7 then 0 --rest freeze
		when a.L <> 6 and datediff(MM,@dt_back_test_from,a.mob_date_to) >= cast(right(a.flag_kk,5) as int) 
			then RiskDWH.[CM\A.Borisov].func$greatest(0, a.[K-L+1] - datediff(MM,@rdt,a.mob_date_to) + cast(right(a.flag_kk,5) as int) ) 
		when a.L = 6 and datediff(MM,@dt_back_test_from,a.mob_date_to) >= cast(right(a.flag_kk,5) as int) 
			then RiskDWH.[CM\A.Borisov].func$greatest(0, a.K + 1 - datediff(MM,@rdt,a.mob_date_to) + cast(right(a.flag_kk,5) as int) ) 
		when a.L = 6 then a.K + 1 --TO pay-off
		else a.[K-L+1] end
		* a.int_rate * day(a.mob_date_to) / 365.0 * a.model_od 
		--* case when a.bucket_90_from = '[01] 0' and a.bucket_90_to = '[01] 0' then isnull(sts.koef_po,1.0) else 1.0 end --28.02.2022
		--* case when a.bucket_90_to <> '[06] Pay-off' and a.bucket_90_from = a.bucket_90_to then isnull(sts.koef_po,1) else 1.0 end --28.02.2022
	) as int_pmt,

	sum(case 
		when datediff(MM,@dt_back_test_from,a.mob_date_to) >= cast(right(a.flag_kk,5) as int) then 0 --остановка начисления с учетом нового срока по КК
		when a.K = 4 and a.L = 5 then 0 --61-90--91+ уже учтено в AVG_PORTF
		--when a.K in (3,4) and a.L = 7 then /*1*/ DATEDIFF(MM, a.dt_int_from, a.mob_date_to) /*+ 3*/ /*%% до заморозки*/ + 1 /*новая заморозка*/ --freeze
		when a.K = 1 and a.L - a.K > 1 and a.L < 6 and a.freeze_from is not null then 1 --переходы из [0] в историческую просрочку
		when a.K in (3,4) and a.L = 7 then 1
		when a.[K-L+1] < 0 then 0 
		when a.K = 6 then 0 --pay-off
		--when a.K = 5 and a.L = 5 and a.mob_to <= a.term + 19 /*среднее увеличение срока для КК*/ then 1 --начисление %% до конца графика
		when a.K = 5 and a.L = 5 then 1 --24/12/2021 - убираем ограничение на начисление после окончания графика
		when a.K = 5 and a.L <> 5 then 0 --90+
		when a.K = 7 and a.L = 7 then 1 /*остается в заморзке*/ --freeze
		--when a.K = 7 and a.L = 5 then DATEDIFF(MM, a.dt_int_from, a.mob_date_to) /*+ 3*/ /*%% до заморозки*/ + 1 /*переходит в 90+*/ --freeze
		--when a.K = 7 and a.L = 1 then DATEDIFF(MM, a.dt_int_from, a.mob_date_to) /*+ 3*/ /*%% до заморозки*/ + 0 /*Переход в [0]*/ --freeze
		when a.K = 7 and a.L in (2,3,4,5) then 1
		--when a.K = 7 and a.L = 1 then 0
		when a.K = 7 and a.L = 1 then 1 --26/12/2021 - переход из заморозки в [0] 
		when a.K = 7 then 0 --rest freeze
		else a.[L-K] end 
		* a.int_rate * day(a.mob_date_to) / 365.0 * a.model_od 
	) as ovr_int_balance

	from base a
	left join Temp_PTS_Test_det_stress sts 
	on a.mob_date_to between sts.dt_from and sts.dt_to --28.02.2022

	group by 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, 
	a.mod_num, a.last_MOD, a.bucket_90_from, a.bucket_90_to, a.freeze_from
	;





	update a set 
	a.int_pmt = isnull(a.int_pmt,0) + isnull(b.int_pmt,0), 
	a.ovr_int_balance = isnull(a.ovr_int_balance,0) + isnull(b.ovr_int_balance,0)
	from Temp_PTS_Test_stg_interest_model a
	left join Temp_PTS_Test_stg_interest_model b
	on 1=1
	--and a.term = b.term
	--and a.segment_rbp = b.segment_rbp
	--and a.generation = b.generation
	--and a.flag_kk = b.flag_kk
	and a.id1 = b.id1
	and a.bucket_90_from = b.bucket_90_from
	and b.bucket_90_to = '[06] Pay-off'
	and a.mob_date_to = b.mob_date_to
	and isnull(a.mod_num,-999) = isnull(b.mod_num,-999)
	and isnull(a.last_MOD,-999) = isnull(b.last_MOD,-999)
	and isnull(a.freeze_from,'4444-01-01') = isnull(b.freeze_from,'4444-01-01')
	where left(a.flag_kk,2) = 'KK'
	and a.bucket_90_to = '[01] 0'
	and a.bucket_90_from <> '[06] Pay-off'
	;



	print ('timing, Temp_PTS_Test_stg_interest_model ' + format(getdate(), 'HH:mm:ss'))


	/********************************************************************************/
	--Начисленные + просроченные проценты версия 3


	--Списания и recovery для процентов в 90+
	drop table if exists Temp_PTS_Test_stg_int_rec_wo;
	with aa as (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, cast(null as date) as freeze_from,
		cast('[05] 90+' as varchar(100)) as bucket_90_to, 	
		sum(isnull(a.int_recov,0)) as int_recov, 
		sum(isnull(a.int_writeoff,0)) as int_wo
		from (
			select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD,
			eomonth(a.mob_date_to, -1 * a.mod_num) as fixed_mod1, 
			eomonth(a.mob_date_to, -1 * a.last_MOD) as fixed_mod2,
			isnull(round(a.calc_int_payoff - lag(a.calc_int_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, 
			eomonth(a.mob_date_to, -1 * a.mod_num), eomonth(a.mob_date_to, -1 * a.last_MOD)
			order by a.mob_date_to),2) ,0) as int_recov,
		
			isnull(round(a.int_wo_calc_od_payoff - lag(a.int_wo_calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, 
			eomonth(a.mob_date_to, -1 * a.mod_num), eomonth(a.mob_date_to, -1 * a.last_MOD)
			order by a.mob_date_to),2), 0) as int_writeoff
		
			from Temp_PTS_Test_stg1_default_recovery_fact a --Temp_PTS_Test_default_recovery_fact a
		) a
		group by a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD
	), bb as (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, a.freeze_from,
		cast('[05] 90+' as varchar(100)) as bucket_90_to, 
		sum(isnull(a.int_recov,0)) as int_recov, 
		sum(isnull(a.int_writeoff,0)) as int_wo
		from (
			select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, a.freeze_from,
			eomonth(a.mob_date_to, -1 * a.mod_num) as default_dt,
			eomonth(a.mob_date_to, -1 * a.last_MOD) as default_dt2,

			isnull(round(a.calc_int_payoff - lag(a.calc_int_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, a.freeze_from,
			eomonth(a.mob_date_to, -1 * isnull(a.mod_num,-999)), eomonth(a.mob_date_to, -1 * isnull(a.last_MOD,-999))
			order by a.mob_date_to),2) ,0) as int_recov,
		
			isnull(round(a.int_wo_calc_od_payoff - lag(a.int_wo_calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, a.freeze_from, 
			eomonth(a.mob_date_to, -1 * isnull(a.mod_num,-999)), eomonth(a.mob_date_to, -1 * isnull(a.last_MOD,-999))
			order by a.mob_date_to),2) ,0) as int_writeoff
		
			from Temp_PTS_Test_stg3_default_recovery_model a --Temp_PTS_Test_default_recovery_model a
		) a
		group by a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, a.freeze_from
	)
	select 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, a.freeze_from,
	sum(a.int_recov) as int_recov,
	sum(a.int_wo) as int_wo

	into Temp_PTS_Test_stg_int_rec_wo
	from (select * from aa union all select * from bb) a
	group by 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, a.freeze_from
	;

	print ('timing, Temp_PTS_Test_stg_int_rec_wo ' + format(getdate(), 'HH:mm:ss'))




	--то же самое для КК с исходящим бакетом
	drop table if exists Temp_PTS_Test_stg2_int_rec_wo;

	with base as (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, a.freeze_from, a.bucket_90_from,
		eomonth(a.mob_date_to, -1 * a.mod_num) as default_dt,
		eomonth(a.mob_date_to, -1 * a.last_MOD) as default_dt2,
		a.calc_int_payoff,
		a.int_wo_calc_od_payoff		
		from Temp_PTS_Test_stg33_default_recovery_model a --Temp_PTS_Test_default_recovery_model a
	), agg as (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.default_dt, a.default_dt2, a.freeze_from,
		sum(a.calc_int_payoff) as calc_int_payoff,
		sum(a.int_wo_calc_od_payoff) as int_wo_calc_od_payoff
		from base a
		group by a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.default_dt, a.default_dt2, a.freeze_from
	)
	select
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, a.freeze_from, a.bucket_90_from,
	sum(case when a.bucket_90_from = '[05] 90+' then a.calc_int_payoff - isnull(b.calc_int_payoff,0) else a.calc_int_payoff end) as int_recov,
	sum(case when a.bucket_90_from = '[05] 90+' then isnull(a.int_wo_calc_od_payoff,0) - isnull(b.int_wo_calc_od_payoff,0) else isnull(a.int_wo_calc_od_payoff,0) end) as int_wo

	into Temp_PTS_Test_stg2_int_rec_wo
	from base a
	left join agg b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	and a.generation = b.generation
	and a.mob_date_to = eomonth(b.mob_date_to,1)
	and a.default_dt = b.default_dt
	and a.default_dt2 = b.default_dt2
	and isnull(a.freeze_from,'1111-01-01') = isnull(b.freeze_from,'1111-01-01')
	group by hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, a.freeze_from, a.bucket_90_from



	print ('timing, Temp_PTS_Test_stg_int_rec_wo ' + format(getdate(), 'HH:mm:ss'))
	-----------------------------------------------------------------------



	--Подготовка данных для цикла

	drop table if exists Temp_PTS_Test_interest_model;
	with base as ( --Последний факт
		select 
		hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
		a.term, a.segment_rbp, a.flag_kk, a.generation, b.mob_date_to, 
		b.bucket_90_to,
		case 
		when a.mod_num >= 0 and a.mod_num is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.mod_num + 1
		when a.bucket = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
		else null end as mod_num,	

		case 
		when a.last_MOD >= 0 and a.last_MOD is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.last_MOD + 1
		when a.bucket = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
		else null end as last_MOD,

		sum((a.total_int) * b.model_coef_adj )  as total_int	

		from Temp_PTS_Test_fact_due_int a
		left join Temp_PTS_Test_for_back_test b
		on a.term = b.term
		and a.segment_rbp = b.segment_rbp 
		and a.flag_kk = b.flag_kk
		and a.generation = b.generation
		and a.r_date = eomonth(b.mob_date_to,-1)
		and a.bucket = b.bucket_90_from

		where a.r_date = eomonth(@dt_back_test_from,-1)
		and a.generation <= eomonth(@dt_back_test_from,-1)
		and left(a.flag_kk,2) <> 'KK' and a.bucket <> '[07] Freeze'
		group by
		hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
		a.term, a.segment_rbp, a.flag_kk, a.generation, b.mob_date_to, b.bucket_90_to,
		case when a.mod_num >= 0 and a.mod_num is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.mod_num + 1
		when a.bucket = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
		else null end,
		case when a.last_MOD >= 0 and a.last_MOD is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.last_MOD + 1
		when a.bucket = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
		else null end

	), ovr as ( --начисленная просроченная задолженность (бабиков)
		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to, sum(a.ovr_int_balance) as ovr_int_balance
		from Temp_PTS_Test_stg_interest_model a
		where a.mob_date_to = @dt_back_test_from
		and left(a.flag_kk,2) <> 'KK'
		group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to
	)
	select 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_to, a.mod_num, a.last_MOD,
	--case 
	--when a.total_int + iif(isnull(a.last_MOD,0) < 33, isnull(b.ovr_int_balance,0), 0) - isnull(c.int_recov_wroff,0) < 0 then 0
	--else a.total_int + iif(isnull(a.last_MOD,0) < 33, isnull(b.ovr_int_balance,0), 0) - isnull(c.int_recov_wroff,0)
	--end as total_int
	--RiskDWH.[CM\A.Borisov].func$greatest(0, a.total_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov_wroff,0)) as total_int
	RiskDWH.[CM\A.Borisov].func$greatest(0, a.total_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) - isnull(c.int_wo,0) ) as total_int

	into Temp_PTS_Test_interest_model
	from base a
	left join ovr b
	on 1=1
	--and a.term = b.term
	--and a.segment_rbp = b.segment_rbp 
	--and a.flag_kk = b.flag_kk
	--and a.generation = b.generation
	and a.id1 = b.id1
	and a.mob_date_to = b.mob_date_to
	and a.bucket_90_to = b.bucket_90_to
	and isnull(a.mod_num,-999) = isnull(b.mod_num,-999)
	and isnull(a.last_MOD,-999) = isnull(b.last_MOD,-999)

	left join Temp_PTS_Test_stg_int_rec_wo c --рекавери и списания 90+
	on 1=1
	--and a.term = c.term
	--and a.segment_rbp = c.segment_rbp 
	--and a.flag_kk = c.flag_kk
	--and a.generation = c.generation
	and a.id1 = c.id1
	and a.mob_date_to = c.mob_date_to
	and a.bucket_90_to = '[05] 90+'
	and isnull(a.mod_num,-999) = isnull(c.mod_num,-999)
	and isnull(a.last_MOD,-999) = isnull(c.last_MOD,-999)
	;


	--Обновление Recovery и списаний
	----declare @dt_back_test_from date = '2024-11-30';
	with base as ( --Последний факт
		select 
		hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
		a.term, a.segment_rbp, a.flag_kk, a.generation, b.mob_date_to, 
		b.bucket_90_to,
		case 
		when a.mod_num >= 0 and a.mod_num is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.mod_num + 1
		when a.bucket = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
		else null end as mod_num,	

		case 
		when a.last_MOD >= 0 and a.last_MOD is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.last_MOD + 1
		when a.bucket = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
		else null end as last_MOD,

		sum((a.total_int) * b.model_coef_adj )  as total_int	

		from Temp_PTS_Test_fact_due_int a
		left join Temp_PTS_Test_for_back_test b
		on a.term = b.term
		and a.segment_rbp = b.segment_rbp 
		and a.flag_kk = b.flag_kk
		and a.generation = b.generation
		and a.r_date = eomonth(b.mob_date_to,-1)
		and a.bucket = b.bucket_90_from

		where a.r_date = eomonth(@dt_back_test_from,-1)
		and a.generation <= eomonth(@dt_back_test_from,-1)
		and left(a.flag_kk,2) <> 'KK' and a.bucket <> '[07] Freeze'
		group by
		hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
		a.term, a.segment_rbp, a.flag_kk, a.generation, b.mob_date_to, b.bucket_90_to,
		case when a.mod_num >= 0 and a.mod_num is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.mod_num + 1
		when a.bucket = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
		else null end,
		case when a.last_MOD >= 0 and a.last_MOD is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.last_MOD + 1
		when a.bucket = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
		else null end

	), ovr as ( --начисленная просроченная задолженность (бабиков)
		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to, sum(a.ovr_int_balance) as ovr_int_balance
		from Temp_PTS_Test_stg_interest_model a
		where a.mob_date_to = @dt_back_test_from
		and left(a.flag_kk,2) <> 'KK'
		group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to
	)
	update c set 
	c.int_recov = case 
		when a.total_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) - isnull(c.int_wo,0) >= 0 then isnull(c.int_recov,0)
		when a.total_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) >= 0 then isnull(c.int_recov,0)
		when a.total_int + isnull(b.ovr_int_balance,0) >= 0 then a.total_int + isnull(b.ovr_int_balance,0)
		else 0 end, 
	c.int_wo = case 
		when a.total_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) - isnull(c.int_wo,0) >= 0 then isnull(c.int_wo,0)
		when a.total_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) >= 0 then a.total_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0)
		when a.total_int + isnull(b.ovr_int_balance,0) >= 0 then 0
		else 0 end
	from Temp_PTS_Test_stg_int_rec_wo c
	left join base a 
	on 1=1
	--and a.term = c.term
	--and a.segment_rbp = c.segment_rbp 
	--and a.flag_kk = c.flag_kk
	--and a.generation = c.generation
	and a.id1 = c.id1
	and a.mob_date_to = c.mob_date_to
	and a.bucket_90_to = '[05] 90+'
	and isnull(a.mod_num,-999) = isnull(c.mod_num,-999)
	and isnull(a.last_MOD,-999) = isnull(c.last_MOD,-999)

	left join ovr b
	on 1=1
	--and a.term = b.term
	--and a.segment_rbp = b.segment_rbp 
	--and a.flag_kk = b.flag_kk
	--and a.generation = b.generation
	and a.id1 = b.id1
	and a.mob_date_to = b.mob_date_to
	and a.bucket_90_to = b.bucket_90_to
	and isnull(a.mod_num,-999) = isnull(b.mod_num,-999)
	and isnull(a.last_MOD,-999) = isnull(b.last_MOD,-999)

	where left(c.flag_kk,2) <> 'KK'
	and c.mob_date_to = @dt_back_test_from

	;




	--Расчет для КК
	drop table if exists Temp_PTS_Test_kk_interest;


	---новая заморозка: [31-60] - 70%, [61-90] - 10%

	select 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, 
	a.segment_rbp,
	a.flag_kk,
	a.generation, 
	eomonth(a.r_date,1) as mob_date_to,
	a.bucket as bucket_90_from, 
	cast('[07] Freeze' as varchar(100)) as bucket_90_to,
	sum( (a.total_int) * 
	case 
	when a.bucket = '[03] 31-60' then 0.75 
	when a.bucket = '[04] 61-90' then 0.15 
	else 0.0
	end ) as model_int,
	eomonth(a.r_date,1) as freeze_from,
	--cast(null as int) as mod_num
	case
	when a.bucket = '[03] 31-60' then 10000
	when a.bucket = '[04] 61-90' then 20000
	end as mod_num,

	case
	when a.bucket = '[03] 31-60' then 10000
	when a.bucket = '[04] 61-90' then 20000
	end as last_MOD

	into Temp_PTS_Test_kk_interest
	from Temp_PTS_Test_fact_due_int a --Temp_PTS_Test_freeze_last_fact a
	where left(a.flag_kk,2) = 'KK'
	and a.bucket in ('[03] 31-60','[04] 61-90')
	and a.r_date = eomonth(@dt_back_test_from,-1)
	and a.total_int > 0
	and a.freeze_from is null --без повторных, только продление
	and a.r_date < '2021-10-31' --последняя заморозка в октябре 06/12/2021
	group by 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, 
	a.segment_rbp,
	a.flag_kk,
	a.generation, 
	eomonth(a.r_date,1),
	a.bucket, 
	eomonth(a.r_date,1),
	case when a.bucket = '[03] 31-60' then 10000 when a.bucket = '[04] 61-90' then 20000 end

	;


	---заморозка продолжается в течение 3 месяцев
	---если срок прошел, то выход в 90+, определенный процент, с учетом наличия решения (примерная оценка)
	--- ИЛИ продление заморозки - 30% (примерная оценка по итогам августа)
	---если нет, то дальше в заморозку
	with base as (
		select 
		hashbytes('MD2',CONCAT(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
		a.term, 
		a.segment_rbp,
		a.flag_kk,
		a.generation, 
		eomonth(a.r_date,1) as mob_date_to,
		a.bucket as bucket_90_from,
		a.total_int as total_int,
		a.freeze_from,
		eomonth(a.freeze_from,4) as freeze_to,
		a.mod_num,
		a.last_MOD
		from Temp_PTS_Test_fact_due_int a	
		where left(a.flag_kk,2) = 'KK'
		and a.bucket = '[07] Freeze'
		and a.r_date = eomonth(@dt_back_test_from,-1)
	), un as (
	--продолжение первой заморозки
		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, 
		a.bucket_90_from,
		cast('[07] Freeze' as varchar(100)) as bucket_90_to,
		a.total_int as model_int,
		a.freeze_from,
		a.mod_num + 1 as mod_num,
		a.last_MOD + 1 as last_MOD
		from base a
		where (a.mob_date_to < eomonth(a.freeze_from,4) or a.mob_date_to between eomonth(a.freeze_from,5) and eomonth(a.freeze_from,7) )

	union all

	--выход из заморозки в 90+ (историческая просрочка)
		select a.id1,  a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to,
		a.bucket_90_from,
		RiskDWH.dbo.get_bucket_90((case when a.mod_num between 10000 and 19999 then 0
		when a.mod_num between 20000 and 29999 then 1
		else a.mod_num + 1 end) * 30 + 91) as bucket_90_to,  --cast('[05] 90+' as varchar(100)) as bucket_90_to,
	 
		a.total_int * /*0.65*/ 0.85 * iif(a.mob_date_to <= '2021-10-31', 1.0 - @repeat_share , 1.0) as model_int,  --11.02.2022
		a.freeze_from,
		case when a.mod_num between 10000 and 19999 then 0
		when a.mod_num between 20000 and 29999 then 1
		else iif(a.mod_num + 1 >= 0, a.mod_num + 1, null) end as mod_num,

		case when a.last_MOD between 10000 and 19999 then 0
		when a.last_MOD between 20000 and 29999 then 1
		else iif(a.last_MOD + 1 >= 0, a.last_MOD + 1, null) end as last_MOD

		from base a
		where a.mob_date_to = eomonth(a.freeze_from,4)

	union all

	--выход из заморозки в 0
		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, 
		a.bucket_90_from,
		cast('[01] 0' as varchar(100)) as bucket_90_to,
		a.total_int * /*0.35*/ 0.15 * iif(a.mob_date_to <= '2021-10-31', 1.0 - @repeat_share , 1.0) as model_int,  --11.02.2022
		a.freeze_from,
		--cast(null as int) as mod_num, --11/11/2021
		--cast(null as int) as last_MOD --11/11/2021
		case when a.mod_num between 10000 and 19999 then 0
		when a.mod_num between 20000 and 29999 then 1
		else a.mod_num + 1 end as mod_num,
		case when a.last_MOD between 10000 and 19999 then 0
		when a.last_MOD between 20000 and 29999 then 1
		else a.last_MOD + 1 end as last_MOD
		from base a
		where a.mob_date_to = eomonth(a.freeze_from,4)

	union all
	--продление заморозки 
		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, 
		a.bucket_90_from,
		cast('[07] Freeze' as varchar(100)) as bucket_90_to,
		a.total_int * @repeat_share as model_int,
		a.freeze_from,
		a.mod_num + 1 - iif(a.mod_num >= 10000,0, 4) as mod_num, --вычитаем 4 месяца, т.к. MOD, который прибавляется, рассчитывается для окончания первичной заморозки
		a.last_MOD + 1 - iif(a.mod_num >= 10000,0, 4) as last_MOD --вычитаем 4 месяца, т.к. MOD, который прибавляется, рассчитывается для окончания первичной заморозки
		from base a
		where a.mob_date_to = eomonth(a.freeze_from,4)
		and a.mob_date_to <= '2021-10-31'

	union all
	--выход из заморозки продлений в 90+
		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to,
		a.bucket_90_from,
		RiskDWH.dbo.get_bucket_90((case when a.mod_num between 10000 and 19999 then 0
		when a.mod_num between 20000 and 29999 then 1
		else a.mod_num + 1 end) * 30 + 91) as bucket_90_to,  --cast('[05] 90+' as varchar(100)) as bucket_90_to,
		a.total_int * /*0.65*/ 0.85 as model_int,  --11.02.2022
		a.freeze_from,
		case when a.mod_num between 10000 and 19999 then 0
		when a.mod_num between 20000 and 29999 then 1
		else iif(a.mod_num + 1 >= 0, a.mod_num + 1, null) end as mod_num,

		case when a.last_MOD between 10000 and 19999 then 0
		when a.last_MOD between 20000 and 29999 then 1
		else iif(a.last_MOD + 1 >= 0, a.last_MOD + 1, null) end as last_MOD

		from base a
		where a.mob_date_to >= eomonth(a.freeze_from,8)

	union all
	--выход из заморозки продлений в 0
		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, 
		a.bucket_90_from,
		cast('[01] 0' as varchar(100)) as bucket_90_to,
		a.total_int * /*0.35*/ 0.15 as model_int,  --11.02.2022
		a.freeze_from,
		--cast(null as int) as mod_num, --11/11/2021
		--cast(null as int) as last_MOD --11/11/2021
		case when a.mod_num between 10000 and 19999 then 0
		when a.mod_num between 20000 and 29999 then 1
		else a.mod_num + 1 end as mod_num,
		case when a.last_MOD between 10000 and 19999 then 0
		when a.last_MOD between 20000 and 29999 then 1
		else a.last_MOD + 1 end as last_MOD
		from base a
		where a.mob_date_to >= eomonth(a.freeze_from,8)

	)
	insert into Temp_PTS_Test_kk_interest

	select a.id1,
	a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, 
	a.bucket_90_from, a.bucket_90_to, a.model_int, a.freeze_from, a.mod_num, a.last_MOD
	from un as a
	;





	---остальные бакеты
	insert into Temp_PTS_Test_kk_interest
	select 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, 
	a.segment_rbp,
	a.flag_kk,
	a.generation, 
	eomonth(a.r_date,1) as mob_date_to,
	a.bucket as bucket_90_from,
	case 
	when a.r_date >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30' and a.last_MOD between 10000 and 29999
	then '[05] 90+' --11/11/2021
	when a.r_date >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30'
	then RiskDWH.dbo.get_bucket_90((a.last_MOD + 1) * 30 + 91) --11/11/2021
	else b.bucket_90_to end as bucket_90_to, 

	sum((a.total_int) * b.model_coef_adj * 
	case 
	when a.bucket = '[03] 31-60' and a.freeze_from is null and a.r_date < '2021-10-31' then 0.25
	when a.bucket = '[04] 61-90' and a.freeze_from is null and a.r_date < '2021-10-31' then 0.85
	else 1.0 
	end) as model_int,
	a.freeze_from,
	case 
	when a.bucket = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0 
	when a.bucket = '[05] 90+' and b.bucket_90_to = '[05] 90+' and a.mod_num is not null then a.mod_num + 1
	when a.r_date >= eomonth(a.freeze_from,4) then a.mod_num + 1 --11/11/2021
	end as mod_num,

	case 
	when a.bucket = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0 
	when a.bucket = '[05] 90+' and b.bucket_90_to = '[05] 90+' and a.last_MOD is not null then a.last_MOD + 1
	when a.r_date >= eomonth(a.freeze_from,4) then a.last_MOD + 1 --11/11/2021

	end as last_MOD

	from Temp_PTS_Test_fact_due_int a
	left hash join Temp_PTS_Test_for_back_test b
	on a.term = b.term
	and a.generation = b.generation
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	and a.bucket = b.bucket_90_from
	and a.r_date = eomonth(b.mob_date_to,-1)
	and b.bucket_90_to <> '[07] Freeze'

	where left(a.flag_kk,2) = 'KK'
	and a.bucket not in ('[07] Freeze')
	and a.r_date = eomonth(@dt_back_test_from,-1)

	group by 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, 
	a.segment_rbp,
	a.flag_kk,
	a.generation, 
	a.r_date,
	a.bucket,
	case 
	when a.r_date >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30' and a.last_MOD between 10000 and 29999
	then '[05] 90+' --11/11/2021
	when a.r_date >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30'
	then RiskDWH.dbo.get_bucket_90((a.last_MOD + 1) * 30 + 91) --11/11/2021
	else b.bucket_90_to end,
	a.freeze_from,
	case 
	when a.bucket = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0 
	when a.bucket = '[05] 90+' and b.bucket_90_to = '[05] 90+' and a.mod_num is not null then a.mod_num + 1
	when a.r_date >= eomonth(a.freeze_from,4) then a.mod_num + 1 --11/11/2021
	end,
	case 
	when a.bucket = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0 
	when a.bucket = '[05] 90+' and b.bucket_90_to = '[05] 90+' and a.last_MOD is not null then a.last_MOD + 1
	when a.r_date >= eomonth(a.freeze_from,4) then a.last_MOD + 1 --11/11/2021

	end
	;





	--declare @dt_back_test_from date = '2024-11-30';
	with ovr as ( --начисленная просроченная задолженность (бабиков)
		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to, a.freeze_from, a.bucket_90_from,
		sum(a.ovr_int_balance) as ovr_int_balance
		from Temp_PTS_Test_stg_interest_model a
		where a.mob_date_to = @dt_back_test_from
		and left(a.flag_kk,2) = 'KK'
		group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to, a.freeze_from, a.bucket_90_from
	)
	update c set 
	c.int_recov = case 
		when a.model_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) - isnull(c.int_wo,0) >= 0 then isnull(c.int_recov,0)
		when a.model_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) >= 0 then isnull(c.int_recov,0)
		when a.model_int + isnull(b.ovr_int_balance,0) >= 0 then a.model_int + isnull(b.ovr_int_balance,0)
		else 0 end, 
	c.int_wo = case 
		when a.model_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) - isnull(c.int_wo,0) >= 0 then isnull(c.int_wo,0)
		when a.model_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) >= 0 then a.model_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0)
		when a.model_int + isnull(b.ovr_int_balance,0) >= 0 then 0
		else 0 end
	from Temp_PTS_Test_stg2_int_rec_wo c
	left join Temp_PTS_Test_kk_interest a --рекавери и списания 90+
	on 1 = 1
	--and a.term = c.term
	--and a.segment_rbp = c.segment_rbp 
	--and a.flag_kk = c.flag_kk
	--and a.generation = c.generation
	and a.id1 = c.id1
	and a.mob_date_to = c.mob_date_to
	and a.bucket_90_from = c.bucket_90_from
	and a.bucket_90_to = '[05] 90+'
	and isnull(a.freeze_from,'1111-01-01') = isnull(c.freeze_from,'1111-01-01')
	and isnull(a.mod_num,-999) = isnull(c.mod_num,-999)
	and isnull(a.last_MOD,-999) = isnull(c.last_MOD,-999)
	left join ovr b
	on 1 = 1
	--and a.term = b.term
	--and a.segment_rbp = b.segment_rbp 
	--and a.flag_kk = b.flag_kk
	--and a.generation = b.generation
	and a.id1 = b.id1
	and a.mob_date_to = b.mob_date_to
	and a.bucket_90_from = b.bucket_90_from
	and a.bucket_90_to = b.bucket_90_to
	and isnull(a.freeze_from,'1111-01-01') = isnull(b.freeze_from,'1111-01-01')
	and isnull(a.mod_num,-999) = isnull(b.mod_num,-999)
	and isnull(a.last_MOD,-999) = isnull(b.last_MOD,-999)
	where c.mob_date_to = @dt_back_test_from

	;




	with ovr as ( --начисленная просроченная задолженность (бабиков)
		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to, a.freeze_from, a.bucket_90_from,
		sum(a.ovr_int_balance) as ovr_int_balance
		from Temp_PTS_Test_stg_interest_model a
		where a.mob_date_to = @dt_back_test_from
		and left(a.flag_kk,2) = 'KK'
		group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to, a.freeze_from, a.bucket_90_from
	)
	update a set 
	--a.model_int = case when a.model_int + iif(isnull(a.last_MOD,0) < 33, isnull(b.ovr_int_balance,0), 0) - isnull(c.int_recov_wroff,0) < 0 then 0
	--								else a.model_int + iif(isnull(a.last_MOD,0) < 33, isnull(b.ovr_int_balance,0), 0) - isnull(c.int_recov_wroff,0) end,
	--a.model_int = RiskDWH.[CM\A.Borisov].func$greatest(0, a.model_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov_wroff,0))
	a.model_int = RiskDWH.[CM\A.Borisov].func$greatest(0, a.model_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) - isnull(c.int_wo,0) )
	from Temp_PTS_Test_kk_interest a
	left join ovr b
	on 1 = 1
	--and a.term = b.term
	--and a.segment_rbp = b.segment_rbp 
	--and a.flag_kk = b.flag_kk
	--and a.generation = b.generation
	and a.id1 = b.id1
	and a.mob_date_to = b.mob_date_to
	and a.bucket_90_from = b.bucket_90_from
	and a.bucket_90_to = b.bucket_90_to
	and isnull(a.freeze_from,'1111-01-01') = isnull(b.freeze_from,'1111-01-01')
	and isnull(a.mod_num,-999) = isnull(b.mod_num,-999)
	and isnull(a.last_MOD,-999) = isnull(b.last_MOD,-999)
	left join Temp_PTS_Test_stg2_int_rec_wo c --рекавери и списания 90+
	on 1 = 1
	--and a.term = c.term
	--and a.segment_rbp = c.segment_rbp 
	--and a.flag_kk = c.flag_kk
	--and a.generation = c.generation
	and a.id1 = c.id1
	and a.mob_date_to = c.mob_date_to
	and a.bucket_90_from = c.bucket_90_from
	and a.bucket_90_to = '[05] 90+'
	and isnull(a.freeze_from,'1111-01-01') = isnull(c.freeze_from,'1111-01-01')
	and isnull(a.mod_num,-999) = isnull(c.mod_num,-999)
	and isnull(a.last_MOD,-999) = isnull(c.last_MOD,-999)
	;


	insert into Temp_PTS_Test_interest_model

	select 
	a.id1,
	a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_to, 
	a.mod_num, a.last_MOD,
	sum(a.model_int) as total_int
	from Temp_PTS_Test_kk_interest a
	group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_to, 
	a.mod_num, a.last_MOD
	;



	--Добавляем новые выдачи


	insert into Temp_PTS_Test_interest_model

	select 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_to, 
	cast(null as int) as mod_num,cast(null as int) as last_MOD,
	a.fact_model_od * b.avg_month_int_rate * 0.47 as total_int

	from Temp_PTS_Test_stg4_back_test_results a
	left join Temp_PTS_Test_stg_int_rates b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	and a.generation = b.generation

	where a.mob_date_to >= @dt_back_test_from
	and a.mob_to = 0
	and a.bucket_90_to = '[01] 0'
	and left(a.flag_kk,2) <> 'KK'
	;




	print ('timing, Temp_PTS_Test_interest_model ' + format(getdate(), 'HH:mm:ss'))




	--Цикл для умножения процентов на матрицу миграций (по ОД)


	declare @jj date = @dt_back_test_from;

	while @jj < EOMONTH(@dt_back_test_from, @horizon )

	begin

		drop table if exists Temp_PTS_Test_tmp_interest_model;
		select * 
		into Temp_PTS_Test_tmp_interest_model
		from Temp_PTS_Test_interest_model a
		where a.mob_date_to = @jj
		--and a.total_int > 1
		;


		drop table if exists Temp_PTS_Test_tmp_kk_interest;
		select * 
		into Temp_PTS_Test_tmp_kk_interest
		from Temp_PTS_Test_kk_interest a
		where a.mob_date_to = @jj
		--and a.model_int > 1
		;

		with base as ( --Последний факт
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, b.mob_date_to, b.bucket_90_to, 
			case 
			when a.mod_num >= 0 and a.mod_num is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.mod_num + 1
			when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
			end as mod_num, 

			case 
			when a.last_MOD >= 0 and a.last_MOD is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.last_MOD + 1
			when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
			end as last_MOD, 

			sum(a.total_int * b.model_coef_adj) as total_int
			from Temp_PTS_Test_tmp_interest_model a
			left join Temp_PTS_Test_for_back_test b
			on 1 = 1
			--and a.term = b.term
			--and a.segment_rbp = b.segment_rbp
			--and a.flag_kk = b.flag_kk
			--and a.generation = b.generation
			and a.id1 = b.id1
			and a.bucket_90_to = b.bucket_90_from
			and a.mob_date_to = EOMONTH(b.mob_date_to,-1)
			where left(a.flag_kk,2) <> 'KK'
			group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, b.mob_date_to, b.bucket_90_to, 
			case 
			when a.mod_num >= 0 and a.mod_num is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.mod_num + 1
			when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
			end,
			case 
			when a.last_MOD >= 0 and a.last_MOD is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.last_MOD + 1
			when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
			end
		), ovr as ( --начисленная просроченная задолженность (бабиков)
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to, sum(a.ovr_int_balance) as ovr_int_balance
			from Temp_PTS_Test_stg_interest_model a
			where a.mob_date_to = eomonth(@jj,1)
			and left(a.flag_kk,2) <> 'KK'
			group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to
		)
		insert into Temp_PTS_Test_interest_model

		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_to, a.mod_num, a.last_MOD,
		--case 
		--when a.total_int + iif(isnull(a.last_MOD,0) < 33, isnull(b.ovr_int_balance,0), 0) - isnull(c.int_recov_wroff,0) < 0 then 0
		--else a.total_int + iif(isnull(a.last_MOD,0) < 33, isnull(b.ovr_int_balance,0), 0) - isnull(c.int_recov_wroff,0) 
		--end as total_int
		RiskDWH.[CM\A.Borisov].func$greatest(0, a.total_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) - isnull(c.int_wo,0) ) as total_int
 

		from base a
		left join ovr b
		on 1=1
		--and a.term = b.term
		--and a.segment_rbp = b.segment_rbp 
		--and a.flag_kk = b.flag_kk
		--and a.generation = b.generation
		and a.id1 = b.id1
		and a.mob_date_to = b.mob_date_to
		and a.bucket_90_to = b.bucket_90_to
		and isnull(a.mod_num,-999) = isnull(b.mod_num,-999)
		and isnull(a.last_MOD,-999) = isnull(b.last_MOD,-999)

		left join Temp_PTS_Test_stg_int_rec_wo c --рекавери и списания 90+
		on 1=1
		--and a.term = c.term
		--and a.segment_rbp = c.segment_rbp 
		--and a.flag_kk = c.flag_kk
		--and a.generation = c.generation
		and a.id1 = c.id1
		and a.mob_date_to = c.mob_date_to
		and a.bucket_90_to = '[05] 90+'
		and isnull(a.mod_num,-1) = isnull(c.mod_num,-1)
		and isnull(a.last_MOD,-1) = isnull(c.last_MOD,-1)

		;


		--обновляем Recovery и Writeoff 90+ с учетом входящего остатка %
		with base as ( --Последний факт
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, b.mob_date_to, b.bucket_90_to, 
			case 
			when a.mod_num >= 0 and a.mod_num is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.mod_num + 1
			when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
			end as mod_num, 

			case 
			when a.last_MOD >= 0 and a.last_MOD is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.last_MOD + 1
			when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
			end as last_MOD, 

			sum(a.total_int * b.model_coef_adj) as total_int
			from Temp_PTS_Test_tmp_interest_model a
			left join Temp_PTS_Test_for_back_test b
			on 1 = 1
			--and a.term = b.term
			--and a.segment_rbp = b.segment_rbp
			--and a.flag_kk = b.flag_kk
			--and a.generation = b.generation
			and a.id1 = b.id1
			and a.bucket_90_to = b.bucket_90_from
			and a.mob_date_to = EOMONTH(b.mob_date_to,-1)
			where left(a.flag_kk,2) <> 'KK'
			group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, b.mob_date_to, b.bucket_90_to, 
			case 
			when a.mod_num >= 0 and a.mod_num is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.mod_num + 1
			when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
			end,
			case 
			when a.last_MOD >= 0 and a.last_MOD is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.last_MOD + 1
			when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
			end
		), ovr as ( --начисленная просроченная задолженность (бабиков)
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to, sum(a.ovr_int_balance) as ovr_int_balance
			from Temp_PTS_Test_stg_interest_model a
			where a.mob_date_to = eomonth(@jj,1)
			and left(a.flag_kk,2) <> 'KK'
			group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to
		)
		update c set 
		c.int_recov = case 
			when a.total_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) - isnull(c.int_wo,0) >= 0 then isnull(c.int_recov,0)
			when a.total_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) >= 0 then isnull(c.int_recov,0)
			when a.total_int + isnull(b.ovr_int_balance,0) >= 0 then a.total_int + isnull(b.ovr_int_balance,0)
			else 0 end, 
		c.int_wo = case 
			when a.total_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) - isnull(c.int_wo,0) >= 0 then isnull(c.int_wo,0)
			when a.total_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) >= 0 then a.total_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0)
			when a.total_int + isnull(b.ovr_int_balance,0) >= 0 then 0
			else 0 end
		from Temp_PTS_Test_stg_int_rec_wo c --рекавери и списания 90+
		left join base a
		on 1=1
		--and a.term = c.term
		--and a.segment_rbp = c.segment_rbp 
		--and a.flag_kk = c.flag_kk
		--and a.generation = c.generation
		and a.id1 = c.id1
		and a.mob_date_to = c.mob_date_to
		and a.bucket_90_to = '[05] 90+'
		and isnull(a.mod_num,-1) = isnull(c.mod_num,-1)
		and isnull(a.last_MOD,-1) = isnull(c.last_MOD,-1)
		left join ovr b
		on 1=1
		--and a.term = b.term
		--and a.segment_rbp = b.segment_rbp 
		--and a.flag_kk = b.flag_kk
		--and a.generation = b.generation
		and a.id1 = b.id1
		and a.mob_date_to = b.mob_date_to
		and a.bucket_90_to = b.bucket_90_to
		and isnull(a.mod_num,-999) = isnull(b.mod_num,-999)
		and isnull(a.last_MOD,-999) = isnull(b.last_MOD,-999)

		where c.mob_date_to = eomonth(@jj,1)
		and left(c.flag_kk,2) <> 'KK'
		;








		--KK


		---новые заморозки
		insert into Temp_PTS_Test_kk_interest
		select 
		a.id1,
		a.term, 
		a.segment_rbp,
		a.flag_kk,
		a.generation, 
		eomonth(a.mob_date_to,1) as mob_date_to,
		a.bucket_90_to as bucket_90_from,
		cast('[07] Freeze' as varchar(100)) as bucket_90_to,
		sum( a.model_int 
		* case a.bucket_90_to when '[03] 31-60' then 0.75 when '[04] 61-90' then 0.15 end 
		) as model_int,
		eomonth(a.mob_date_to,1) as freeze_from,
		--cast(null as int) as mod_num
		case
		when a.bucket_90_to = '[03] 31-60' then 10000
		when a.bucket_90_to = '[04] 61-90' then 20000
		end as mod_num,

		case
		when a.bucket_90_to = '[03] 31-60' then 10000
		when a.bucket_90_to = '[04] 61-90' then 20000
		end as last_MOD


		from Temp_PTS_Test_tmp_kk_interest a
		where left(a.flag_kk,2) = 'KK'
		and a.bucket_90_to in ('[03] 31-60','[04] 61-90')
		--and a.model_int > 0
		and a.freeze_from is null --без повторных, только продление
		and a.mob_date_to < '2021-10-31'
		group by 
		a.id1,
		a.term, 
		a.segment_rbp,
		a.flag_kk,
		a.generation, 
		eomonth(a.mob_date_to,1),
		a.bucket_90_to,
		case when a.bucket_90_to = '[03] 31-60' then 10000 when a.bucket_90_to = '[04] 61-90' then 20000 end
		;


		--выход и продолжение заморозки
		with base as (
			select 
			a.id1,
			a.term, 
			a.segment_rbp,
			a.flag_kk,
			a.generation, 
			eomonth(a.mob_date_to,1) as mob_date_to,
			a.bucket_90_to as bucket_90_from,
			a.model_int as total_int,
			a.freeze_from,
			eomonth(a.freeze_from,4) as freeze_to,
			a.mod_num,
			a.last_MOD

			from Temp_PTS_Test_tmp_kk_interest a	
			where left(a.flag_kk,2) = 'KK'
			and a.bucket_90_to = '[07] Freeze'
		), un as (
		--продолжение первой заморозки
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, 
			a.bucket_90_from,
			cast('[07] Freeze' as varchar(100)) as bucket_90_to,
			a.total_int as model_int,
			a.freeze_from,
			a.mod_num + 1 as mod_num,
			a.last_MOD + 1 as last_MOD
			from base a
			where (a.mob_date_to < eomonth(a.freeze_from,4) or a.mob_date_to between eomonth(a.freeze_from,5) and eomonth(a.freeze_from,7) )

		union all

		--выход из заморозки в 90+
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, 
			a.bucket_90_from,
			RiskDWH.dbo.get_bucket_90((case when a.mod_num between 10000 and 19999 then 0
			when a.mod_num between 20000 and 29999 then 1
			else a.mod_num + 1 end) * 30 + 91) as bucket_90_to,  --cast('[05] 90+' as varchar(100)) as bucket_90_to,
	
			a.total_int * /*0.65*/ 0.85 * iif(a.mob_date_to <= '2021-10-31', 1.0 - @repeat_share , 1.0) as model_int,  --11.02.2022
			a.freeze_from,
			case when a.mod_num between 10000 and 19999 then 0
			when a.mod_num between 20000 and 29999 then 1
			else iif(a.mod_num + 1 >= 0, a.mod_num + 1, null) end as mod_num,

			case when a.last_MOD between 10000 and 19999 then 0
			when a.last_MOD between 20000 and 29999 then 1
			else iif(a.last_MOD + 1 >= 0, a.last_MOD + 1, null) end as last_MOD

			from base a
			where a.mob_date_to = eomonth(a.freeze_from,4)

		union all

		--выход из заморозки в 0
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to,
			a.bucket_90_from,
			cast('[01] 0' as varchar(100)) as bucket_90_to,
			a.total_int * /*0.35*/ 0.15 * iif(a.mob_date_to <= '2021-10-31', 1.0 - @repeat_share , 1.0) as model_int,  --11.02.2022
			a.freeze_from,
			--cast(null as int) as mod_num, --11/11/2021
			--cast(null as int) as last_MOD --11/11/2021
			case when a.mod_num between 10000 and 19999 then 0
			when a.mod_num between 20000 and 29999 then 1
			else a.mod_num + 1 end as mod_num,
			case when a.last_MOD between 10000 and 19999 then 0
			when a.last_MOD between 20000 and 29999 then 1
			else a.last_MOD + 1 end as last_MOD
			from base a
			where a.mob_date_to = eomonth(a.freeze_from,4)

		union all
		--продление заморозки 
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to,
			a.bucket_90_from,
			cast('[07] Freeze' as varchar(100)) as bucket_90_to,
			a.total_int * @repeat_share as model_int,
			a.freeze_from,
			a.mod_num + 1 - iif(a.mod_num >= 10000,0, 4) as mod_num, --вычитаем 4 месяца, т.к. MOD, который прибавляется, рассчитывается для окончания первичной заморозки
			a.last_MOD + 1 - iif(a.mod_num >= 10000,0, 4) as last_MOD --вычитаем 4 месяца, т.к. MOD, который прибавляется, рассчитывается для окончания первичной заморозки
			from base a
			where a.mob_date_to = eomonth(a.freeze_from,4)
			and a.mob_date_to <= '2021-10-31'

		union all
		--выход из заморозки продлений в 90+
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, 
			a.bucket_90_from,
			RiskDWH.dbo.get_bucket_90((case when a.mod_num between 10000 and 19999 then 0
			when a.mod_num between 20000 and 29999 then 1
			else a.mod_num + 1 end) * 30 + 91) as bucket_90_to,  --cast('[05] 90+' as varchar(100)) as bucket_90_to,
			a.total_int * /*0.65*/ 0.85 as model_int,  --11.02.2022
			a.freeze_from,

			case when a.mod_num between 10000 and 19999 then 0
			when a.mod_num between 20000 and 29999 then 1
			else iif(a.mod_num + 1 >= 0, a.mod_num + 1, null) end as mod_num,

			case when a.last_MOD between 10000 and 19999 then 0
			when a.last_MOD between 20000 and 29999 then 1
			else iif(a.last_MOD + 1 >= 0, a.last_MOD + 1, null) end as last_MOD
			from base a
			where a.mob_date_to >= eomonth(a.freeze_from,8)

		union all
		--выход из заморозки продлений в 0
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, 
			a.bucket_90_from,
			cast('[01] 0' as varchar(100)) as bucket_90_to,
			a.total_int * /*0.35*/ 0.15 as model_int,  --11.02.2022
			a.freeze_from,
			--cast(null as int) as mod_num, --11/11/2021
			--cast(null as int) as last_MOD --11/11/2021
			case when a.mod_num between 10000 and 19999 then 0
			when a.mod_num between 20000 and 29999 then 1
			else a.mod_num + 1 end as mod_num,
			case when a.last_MOD between 10000 and 19999 then 0
			when a.last_MOD between 20000 and 29999 then 1
			else a.last_MOD + 1 end as last_MOD
			from base a
			where a.mob_date_to >= eomonth(a.freeze_from,8)
		)
		insert into Temp_PTS_Test_kk_interest

		select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to,
		a.bucket_90_from, a.bucket_90_to, a.model_int, a.freeze_from, a.mod_num, a.last_MOD
		from un as a
		;



		---остальные бакеты
		insert into Temp_PTS_Test_kk_interest

		select 
		a.id1,
		a.term, 
		a.segment_rbp,
		a.flag_kk,
		a.generation, 
		eomonth(a.mob_date_to,1) as mob_date_to,
		b.bucket_90_from,

		case 
		when a.mob_date_to >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30' and a.last_MOD between 10000 and 29999
		then '[05] 90+' --11/11/2021
		when a.mob_date_to >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30'
		then RiskDWH.dbo.get_bucket_90((a.last_MOD + 1) * 30 + 91) --11/11/2021
		else b.bucket_90_to end as bucket_90_to, 

		sum(a.model_int * b.model_coef_adj 
		* case when b.bucket_90_from = '[03] 31-60' and a.freeze_from is null and a.mob_date_to < '2021-10-31' then 0.25
			   when b.bucket_90_from = '[04] 61-90' and a.freeze_from is null and a.mob_date_to < '2021-10-31' then 0.85
		else 1.0 end
		) as model_int,
		a.freeze_from,
		case when a.mod_num is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.mod_num + 1
			when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
			 when a.mob_date_to >= eomonth(a.freeze_from,4) then a.mod_num + 1 --11/11/2021
		end as mod_num,

		case when a.last_MOD is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.last_MOD + 1
			when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
			when a.mob_date_to >= eomonth(a.freeze_from,4) then a.last_MOD + 1 --11/11/2021
		end as last_MOD

		from Temp_PTS_Test_tmp_kk_interest a
		inner join Temp_PTS_Test_for_back_test b
		on 1=1
		--and a.term = b.term
		--and a.generation = b.generation
		--and a.segment_rbp = b.segment_rbp
		--and a.flag_kk = b.flag_kk
		and a.id1 = b.id1
		and a.bucket_90_to = b.bucket_90_from
		and a.mob_date_to = eomonth(b.mob_date_to,-1)
		and b.bucket_90_to <> '[07] Freeze'
		--where left(a.flag_kk,2) = 'KK'
		--and a.bucket_90_to not in ('[07] Freeze')
		--and a.mob_date_to = @ii
		group by 
		a.id1,
		a.term, 
		a.segment_rbp,
		a.flag_kk,
		a.generation, 
		a.mob_date_to,
		b.bucket_90_from,
		case 
		when a.mob_date_to >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30' and a.last_MOD between 10000 and 29999
		then '[05] 90+' --11/11/2021
		when a.mob_date_to >= eomonth(a.freeze_from,4) and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[02] 1-30'
		then RiskDWH.dbo.get_bucket_90((a.last_MOD + 1) * 30 + 91) --11/11/2021
		else b.bucket_90_to end,
		a.freeze_from,
		case when a.mod_num is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.mod_num + 1
			when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
			 when a.mob_date_to >= eomonth(a.freeze_from,4) then a.mod_num + 1 --11/11/2021
		end,
		case when a.last_MOD is not null and b.bucket_90_from = '[05] 90+' and b.bucket_90_to = '[05] 90+' then a.last_MOD + 1
			when b.bucket_90_from = '[04] 61-90' and b.bucket_90_to = '[05] 90+' then 0
			when a.mob_date_to >= eomonth(a.freeze_from,4) then a.last_MOD + 1 --11/11/2021
		end
		;



		--обновляем Recovery и Writeoff 90+ с учетом входящего остатка %
		with ovr as ( --начисленная просроченная задолженность (бабиков)
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to, a.freeze_from, a.bucket_90_from,
			sum(a.ovr_int_balance) as ovr_int_balance
			from Temp_PTS_Test_stg_interest_model a
			where a.mob_date_to = eomonth(@jj,1)
			and left(a.flag_kk,2) = 'KK'
			group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to, a.freeze_from, a.bucket_90_from
		)
		update c set 
		c.int_recov = case 
			when a.model_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) - isnull(c.int_wo,0) >= 0 then isnull(c.int_recov,0)
			when a.model_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) >= 0 then isnull(c.int_recov,0)
			when a.model_int + isnull(b.ovr_int_balance,0) >= 0 then a.model_int + isnull(b.ovr_int_balance,0)
			else 0 end, 
		c.int_wo = case 
			when a.model_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) - isnull(c.int_wo,0) >= 0 then isnull(c.int_wo,0)
			when a.model_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) >= 0 then a.model_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0)
			when a.model_int + isnull(b.ovr_int_balance,0) >= 0 then 0
			else 0 end
		from Temp_PTS_Test_stg2_int_rec_wo c --рекавери и списания 90+

		left join Temp_PTS_Test_kk_interest a
		on 1=1
		--and a.term = c.term
		--and a.segment_rbp = c.segment_rbp 
		--and a.flag_kk = c.flag_kk
		--and a.generation = c.generation
		and a.id1 = c.id1
		and a.mob_date_to = c.mob_date_to
		and a.bucket_90_from = c.bucket_90_from
		and a.bucket_90_to = '[05] 90+'
		and isnull(a.freeze_from,'1111-01-01') = isnull(c.freeze_from,'1111-01-01')
		and isnull(a.mod_num,-999) = isnull(c.mod_num,-999)
		and isnull(a.last_MOD,-999) = isnull(c.last_MOD,-999)

		left join ovr b
		on 1=1
		--and a.term = b.term
		--and a.segment_rbp = b.segment_rbp 
		--and a.flag_kk = b.flag_kk
		--and a.generation = b.generation
		and a.id1 = b.id1
		and a.mob_date_to = b.mob_date_to
		and a.bucket_90_from = b.bucket_90_from
		and a.bucket_90_to = b.bucket_90_to
		and isnull(a.freeze_from,'1111-01-01') = isnull(b.freeze_from,'1111-01-01')
		and isnull(a.mod_num,-999) = isnull(b.mod_num,-999)
		and isnull(a.last_MOD,-999) = isnull(b.last_MOD,-999)

		where c.mob_date_to = eomonth(@jj,1)
		;






		with ovr as ( --начисленная просроченная задолженность (бабиков)
			select a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to
				, a.freeze_from, a.bucket_90_from,
			sum(a.ovr_int_balance) as ovr_int_balance
			from Temp_PTS_Test_stg_interest_model a
			where a.mob_date_to = eomonth(@jj,1)
			and left(a.flag_kk,2) = 'KK'
			group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mod_num, a.last_MOD, a.mob_date_to, a.bucket_90_to
				, a.freeze_from, a.bucket_90_from
		)
		update a set 
		--a.model_int = case when a.model_int + iif(isnull(a.last_MOD,0) < 33, isnull(b.ovr_int_balance,0), 0) - isnull(c.int_recov_wroff,0) < 0 then 0
		--								else a.model_int + iif(isnull(a.last_MOD,0) < 33, isnull(b.ovr_int_balance,0), 0) - isnull(c.int_recov_wroff,0) end,
		a.model_int = RiskDWH.[CM\A.Borisov].func$greatest(0, a.model_int + isnull(b.ovr_int_balance,0) - isnull(c.int_recov,0) - isnull(c.int_wo,0) )
		from Temp_PTS_Test_kk_interest a
		left join ovr b
		on 1=1
		--and a.term = b.term
		--and a.segment_rbp = b.segment_rbp 
		--and a.flag_kk = b.flag_kk
		--and a.generation = b.generation
		and a.id1 = b.id1
		and a.mob_date_to = b.mob_date_to
		and a.bucket_90_from = b.bucket_90_from
		and a.bucket_90_to = b.bucket_90_to
		and isnull(a.freeze_from,'1111-01-01') = isnull(b.freeze_from,'1111-01-01')
		and isnull(a.mod_num,-999) = isnull(b.mod_num,-999)
		and isnull(a.last_MOD,-999) = isnull(b.last_MOD,-999)
		left join Temp_PTS_Test_stg2_int_rec_wo c --рекавери и списания 90+
		on 1=1
		--and a.term = c.term
		--and a.segment_rbp = c.segment_rbp 
		--and a.flag_kk = c.flag_kk
		--and a.generation = c.generation
		and a.id1 = c.id1
		and a.mob_date_to = c.mob_date_to
		and a.bucket_90_from = c.bucket_90_from
		and a.bucket_90_to = '[05] 90+'
		and isnull(a.freeze_from,'1111-01-01') = isnull(c.freeze_from,'1111-01-01')
		and isnull(a.mod_num,-999) = isnull(c.mod_num,-999)
		and isnull(a.last_MOD,-999) = isnull(c.last_MOD,-999)
		where a.mob_date_to = eomonth(@jj,1)
		;


		insert into Temp_PTS_Test_interest_model

		select 
		a.id1,
		a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_to, 
		a.mod_num, a.last_MOD,
		sum(a.model_int) as total_int
		from Temp_PTS_Test_kk_interest a
		where a.mob_date_to = eomonth(@jj,1)
		group by a.id1, a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_to, 
		a.mod_num, a.last_MOD
		;




	print ('timing, Temp_PTS_Test_interest_model cycle, @jj = ' + format(@jj,'dd.MM.yyyy') + ' ' + format(getdate(), 'HH:mm:ss'));

	set @jj = eomonth(@jj,1)


	end;

	drop table Temp_PTS_Test_tmp_interest_model;
	drop table Temp_PTS_Test_tmp_kk_interest;





	/*******************************************************************************************************************/

	---проверки
	--дубли
	/*
	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_to, a.mod_num, a.last_MOD
	from Temp_PTS_Test_interest_model a
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_to, a.mod_num, a.last_MOD
	having count(*)>1
	*/




	/*
	--начисленные проценты по кк - модель
	select a.mob_date_to, a.bucket_90_to, a.flag_kk, sum( a.total_int) as total_int
	from Temp_PTS_Test_interest_model a
	where a.mob_date_to between '2021-07-31' and '2022-09-30'
	and left(a.flag_kk,2) = 'KK'
	and a.bucket_90_to <> '[06] Pay-off'
	group by a.mob_date_to, a.bucket_90_to, a.flag_kk
	;

	--од - модель и факт
	select * from Temp_PTS_Test_stg4_back_test_results a
	where left(a.flag_kk,2) = 'KK' and a.mob_date_to between '2021-06-30' and '2021-12-31'


	----модель
	select a.mob_date_to, a.bucket_90_to, a.flag_kk, sum( a.total_int) as total_int
	from Temp_PTS_Test_interest_model a
	where a.mob_date_to between '2021-07-31' and '2021-09-30'
	and a.bucket_90_to <> '[06] Pay-off'
	group by a.mob_date_to, a.bucket_90_to, a.flag_kk
	;



	----факт
	select dateadd(yy,-2000,cast(a.ДатаОтчета as date)) as r_date,
	iif(z.external_id is not null, '[07] Freeze', RiskDWH.dbo.get_bucket_90(isnull(hd.dpd_final,a.ДнейПросрочки))) as dpd_bucket,
	b.flag_kk,
	sum(cast(isnull(a.СрочныеПроценты,0) as float) + cast(isnull(a.ПросроченныеПроценты,0) as float)) as total_int
	from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a
	inner join Temp_PTS_Test_cred_reestr b
	on a.НомерДоговора = b.external_id
	left join Temp_PTS_Test_zamorozka z
	on a.НомерДоговора = z.external_id
	and dateadd(yy,-2000,cast(a.ДатаОтчета as date)) between z.freeze_from and z.freeze_to
	left join Temp_PTS_Test_det_historical_dpd hd
	on a.НомерДоговора = hd.external_id 
	and dateadd(yy,-2000,cast(a.ДатаОтчета as date)) = hd.r_date
	where 1=1
	--and left(b.flag_kk,2) <> 'KK'
	and dateadd(yy,-2000,cast(a.ДатаОтчета as date)) in ('2021-07-31','2021-08-31','2021-09-30')
	group by dateadd(yy,-2000,cast(a.ДатаОтчета as date)), 
	iif(z.external_id is not null, '[07] Freeze', RiskDWH.dbo.get_bucket_90(isnull(hd.dpd_final,a.ДнейПросрочки))),
	b.flag_kk;

	----факт без КК
	select dateadd(yy,-2000,cast(a.ДатаОтчета as date)) as r_date,
	RiskDWH.dbo.get_bucket_90(a.ДнейПросрочки) as dpd_bucket,
	b.flag_kk,
	sum(cast(isnull(a.СрочныеПроценты,0) as float) + cast(isnull(a.ПросроченныеПроценты,0) as float)) as total_int
	from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a
	inner join Temp_PTS_Test_cred_reestr b
	on a.НомерДоговора = b.external_id
	where 1=1
	and left(b.flag_kk,2) <> 'KK'
	and dateadd(yy,-2000,cast(a.ДатаОтчета as date)) in ('2021-07-31','2021-08-31','2021-09-30')
	group by dateadd(yy,-2000,cast(a.ДатаОтчета as date)), 
	RiskDWH.dbo.get_bucket_90(a.ДнейПросрочки),
	b.flag_kk;



	select * from Temp_PTS_Test_stg4_back_test_results a
	where a.mob_date_to between '2021-06-30' and '2021-09-30';

	*/

	/*******************************************************************************************************************/


	--выборка с процентными платежами

	drop table if exists Temp_PTS_Test_model_payment_interest
	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.bucket_90_from, 
		sum(isnull(a.int_pmt,0)) as int_pmt, 
		cast(0 as float) as int_wo
	into Temp_PTS_Test_model_payment_interest
	from Temp_PTS_Test_stg_interest_model a
	where a.bucket_90_from not in ('[05] 90+','[06] Pay-off')
		and a.bucket_90_to <> '[06] Pay-off'
		--and year(a.mob_date_to) = 2025
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.mob_to, a.bucket_90_from

		union all

	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, 
		datediff(MM,a.generation, a.mob_date_to) as mob_to,
		cast('[05] 90+' as varchar(100)) as bucket_90_from, 
		sum(isnull(a.int_recov,0)) as int_pmt,
		sum(isnull(a.int_wo,0)) as int_wo
	from Temp_PTS_Test_stg_int_rec_wo a
	where left(a.flag_kk,2) <> 'KK'-- and year(a.mob_date_to) = 2025
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to

		union all

	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, 
		datediff(MM,a.generation, a.mob_date_to) as mob_to,
		cast('[05] 90+' as varchar(100)) as bucket_90_from, 
		sum(isnull(a.int_recov,0)) as int_pmt,
		sum(isnull(a.int_wo,0)) as int_wo
	from Temp_PTS_Test_stg2_int_rec_wo a
	where left(a.flag_kk,2) = 'KK'
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to
	;



	--7.05.2024 - fix для КК, по которым балансовые проценты не соответствуют бакету просрочки
	drop table if exists Temp_PTS_Test_for_update_pmt_int;
	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, 
	datediff(MM,a.generation,a.mob_date_to) as mob_to, a.bucket_90_from, 
	sum([CM\A.Borisov].func$greatest(0, isnull(a.model_int,0) - isnull(b.int_pmt,0))) as int_pmt
	into Temp_PTS_Test_for_update_pmt_int
	from Temp_PTS_Test_kk_interest a
	left join Temp_PTS_Test_stg_interest_model b
	on a.id1 = b.id1
	and a.mob_date_to = b.mob_date_to
	and a.bucket_90_from = b.bucket_90_from
	and a.bucket_90_to = b.bucket_90_to
	and isnull(a.mod_num,-999) = isnull(b.mod_num,-999)
	and isnull(a.last_MOD,-999) = isnull(b.last_MOD,-999)
	and isnull(a.freeze_from,'4444-01-01') = isnull(b.freeze_from,'4444-01-01')
	where a.bucket_90_to = '[06] Pay-off'
	and a.bucket_90_from not in ('[05] 90+','[06] Pay-off')
	and left(a.flag_kk,2) = 'KK'
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, datediff(MM,a.generation,a.mob_date_to), a.bucket_90_from
	;



	merge into Temp_PTS_Test_model_payment_interest a
	using Temp_PTS_Test_for_update_pmt_int b
	on (a.term = b.term
		and a.segment_rbp = b.segment_rbp
		and a.generation = b.generation
		and a.flag_kk = b.flag_kk
		and a.mob_to = b.mob_to
		and a.bucket_90_from = b.bucket_90_from
	)
	when matched then update set 
	a.int_pmt = isnull(a.int_pmt,0) + isnull(b.int_pmt,0)
	when not matched then insert (
	term,segment_rbp,flag_kk,generation,mob_date_to,mob_to,bucket_90_from,int_pmt
	) values (
	b.term,b.segment_rbp,b.flag_kk,b.generation,b.mob_date_to,b.mob_to,b.bucket_90_from,b.int_pmt
	)
	;
 




	--обновляем процентный платеж за нулевой MoB (ПДП)
	----вычитаем из первого MoB
	with volume as (
	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.vl_rub_fact * (1.0 - isnull(p.coef,1.0)) as pdp_od
	from Temp_PTS_Test_stg4_back_test_results a
	left join Temp_PTS_Test_det_pdp_coef p
	on a.segment_rbp = p.segment_rbp
	where a.mob_to = 0 and a.bucket_90_to = '[01] 0' and a.generation >= @dt_back_test_from --'2021-12-31'
	)
	update a set a.int_pmt = a.int_pmt - b.pdp_od * c.avg_month_int_rate * 12.0 / 365.0 * day(a.generation) / 2.0
	from Temp_PTS_Test_model_payment_interest a
	left join volume b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	and a.generation = b.generation
	left join Temp_PTS_Test_stg_int_rates c
	on a.term = c.term
	and a.segment_rbp = c.segment_rbp
	and a.flag_kk = c.flag_kk
	and a.generation = c.generation
	where a.mob_to = 1 
	and a.generation >= @dt_back_test_from
	and a.bucket_90_from = '[01] 0'
	;

	----добавляем в нулевой
	with volume as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, 
		a.vl_rub_fact * (1.0 - isnull(p.coef,1.0)) * isnull(sts.koef_po,1) as pdp_od
		from Temp_PTS_Test_stg4_back_test_results a
		left join Temp_PTS_Test_det_stress sts --28.02.2022
		on a.mob_date_to between sts.dt_from and sts.dt_to
		left join Temp_PTS_Test_det_pdp_coef p
		on a.segment_rbp = p.segment_rbp
		where a.mob_to = 0 and a.bucket_90_to = '[01] 0' and a.generation >= @dt_back_test_from
	)
	insert into Temp_PTS_Test_model_payment_interest

	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.generation as mob_date_to, 0 as mob_to, '[01] 0' as bucket_90_from, 
	a.pdp_od * b.avg_month_int_rate * 12.0 / 365.0 * day(a.generation) / 2.0 as int_pmt,
	cast(0 as float) as int_wo

	from volume a
	left join Temp_PTS_Test_stg_int_rates b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	and a.generation = b.generation


	print ('timing, Temp_PTS_Test_model_payment_interest ' + format(getdate(), 'HH:mm:ss'))
	;



	--/* P 1-2 */
	----drop table Temp_PTS_Test_CMR_M;
	----drop table Temp_PTS_Test_cred_reestr;
	----drop table Temp_PTS_Test_det_current_params;
	----drop table Temp_PTS_Test_det_pieces_L1;
	----drop table Temp_PTS_Test_det_pieces_L2;
	----drop table Temp_PTS_Test_eps;
	----drop table Temp_PTS_Test_fact_due_int;
	----drop table Temp_PTS_Test_NU_segment_distrib;
	----drop table Temp_PTS_Test_rest_model;
	----drop table Temp_PTS_Test_stg_fact_od_int_pmt;
	----drop table Temp_PTS_Test_stg_freeze_mod;
	----drop table Temp_PTS_Test_stg_matrix_detail;
	----drop table Temp_PTS_Test_stg_payment;
	----drop table Temp_PTS_Test_stg_start_default;
	----drop table Temp_PTS_Test_stg_write_off;
	----drop table Temp_PTS_Test_stg1_NU_segment_distrib;
	----drop table Temp_PTS_Test_stg3_agg;
	----drop table Temp_PTS_Test_umfo_fact;
	----drop table Temp_PTS_Test_UMFO_NU_segment;
	----drop table Temp_PTS_Test_zamorozka;
	--/* P 3 */
	--drop table Temp_PTS_Test_conditional_rec_ALL;
	----drop table Temp_PTS_Test_default_recovery_fact;
	----drop table Temp_PTS_Test_default_recovery_model;
	----drop table Temp_PTS_Test_det_pdp_coef;
	--drop table Temp_PTS_Test_det_recovery_corr;
	----drop table Temp_PTS_Test_det_stress;
	----drop table Temp_PTS_Test_fix_matrix;
	----drop table Temp_PTS_Test_for_back_test;
	--drop table Temp_PTS_Test_freeze_last_fact;
	----drop table Temp_PTS_Test_last_fact;
	----drop table Temp_PTS_Test_new_volume;
	----drop table Temp_PTS_Test_npl_wo_and_recovery;
	----drop table Temp_PTS_Test_stg_freeze_model;
	----drop table Temp_PTS_Test_stg1_default_recovery_fact;
	----drop table Temp_PTS_Test_stg3_default_recovery_model;
	----drop table Temp_PTS_Test_stg4_back_test_results;
	----drop table Temp_PTS_Test_virt_gens;
	--/* P 5 */
	--drop table Temp_PTS_Test_for_update_pmt_int;
	----drop table Temp_PTS_Test_interest_model;
	--drop table Temp_PTS_Test_kk_interest;
	----drop table Temp_PTS_Test_model_payment_interest;
	--drop table Temp_PTS_Test_NPL_avg_portf;
	--drop table Temp_PTS_Test_NPL2_avg_portf;
	--drop table Temp_PTS_Test_stg_freeze_int_last_fact;
	----drop table Temp_PTS_Test_stg_int_rates;
	----drop table Temp_PTS_Test_stg_int_rec_wo;
	--drop table Temp_PTS_Test_stg_interest_model;
	--drop table Temp_PTS_Test_stg1_interest;
	----drop table Temp_PTS_Test_stg2_int_rec_wo;
	--drop table Temp_PTS_Test_stg2_interest;
	--drop table Temp_PTS_Test_stg22_default_recovery_model;
	--drop table Temp_PTS_Test_stg33_default_recovery_model;
	--drop table Temp_PTS_Test_stg5_interest;
	--drop table Temp_PTS_Test_upd_stg2_interest;



	--------------------------------------------------------------------------------------------------------
	-- PART 6 - справочники для БУ
	--------------------------------------------------------------------------------------------------------


	print ('timing, start ' + format(getdate(), 'HH:mm:ss'))






	--ЭПС (месячные), средневзвешенные. Для новых виртуальных поколений берем по последнему доступному факту

	--declare @rdt date = '2024-10-31';

	drop table if exists Temp_PTS_Test_stg_eps_rates;
	with rates as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, 
		--case when sum(b.due_od) = 0 then 0 else sum(a.eps * b.due_od) / sum(b.due_od) end as avg_eps_rate_od,
		--case when sum(b.due_int) = 0 then 0 else sum(a.eps * b.due_int) / sum(b.due_int) end as avg_eps_rate_int
		case when sum(u.total_od) = 0 then 0 else sum(a.eps * u.total_od) / sum(u.total_od) end as avg_eps_rate_od,
		case when sum(u.total_int) = 0 then 0 else sum(a.eps * u.total_int) / sum(u.total_int) end as avg_eps_rate_int
		from Temp_PTS_Test_cred_reestr a
		--inner join risk.portf_umfo b
		--on a.external_id = b.external_id
		--and b.r_date = @rdt
		inner join Temp_PTS_Test_eps b
		on a.external_id = b.external_id
		left join RiskDWH.risk.stg_fcst_umfo u
		on a.external_id = u.external_id
		and u.r_date = @rdt
		where a.generation <= @rdt
		and a.eps is not null
		and a.eps > 0 --!!!!!!
		group by a.term, a.segment_rbp, a.flag_kk, a.generation
	), current_groups as (
		select distinct a.term, a.segment_rbp, a.flag_kk, a.generation from Temp_PTS_Test_stg4_back_test_results a
	), base as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, 
		b.avg_eps_rate_od,
		b.avg_eps_rate_int,	
		b.generation as additional_gen,
		ROW_NUMBER() over (partition by a.term, a.segment_rbp, a.flag_kk, a.generation order by b.generation desc) as rown 
		from current_groups a
		left join rates b
		on a.term = b.term
		and a.segment_rbp = b.segment_rbp
		and a.flag_kk = b.flag_kk
		and a.generation >= b.generation
	)
	select a.term, a.segment_rbp, a.flag_kk, a.generation, 
	isnull( a.avg_eps_rate_od, /*0.0*/ 0.7 ) as avg_eps_rate_od,
	isnull( a.avg_eps_rate_int, /*0.0*/ 0.7 ) as avg_eps_rate_int
	into Temp_PTS_Test_stg_eps_rates
	from base a
	where a.rown = 1;


	--with upd as (
	--	select a.term,
	--	case 
	--	when a.credit_type_init = 'PTS_31' and a.rbp_gr = 'NotRBP_PROBATION' then 'PTS31'
	--	when a.credit_type_init = 'PTS_31' then 'PTS31_RBP4'
	--	else coalesce(
	--		fr.segment_rbp, 
	--		case
	--		when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 1' then 'RBP 1'
	--		when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 2' then 'RBP 2'
	--		when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 3' then 'RBP 3'
	--		when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 4' then 'RBP 4'
	--		end,
	--		'other'
	--	) end as segment_rbp,
	--	eomonth(a.generation) as generation,
	--	'USUAL' as flag_kk,
	--	sum(b.eps * a.amount) / sum(a.amount) as avg_eps
	--	from dwh2.risk.credits a
	--	left join Temp_PTS_Test_eps b
	--	on a.external_id = b.external_id
	--	left join risk.stg_fcst_fix_rbp_2 fr
	--	on a.external_id = fr.external_id
	--	where a.generation between '2023-04-01' and '2023-04-30'
	--	and a.IsInstallment = 0
	--	group by a.term,
	--	case 
	--	when a.credit_type_init = 'PTS_31' and a.rbp_gr = 'NotRBP_PROBATION' then 'PTS31'
	--	when a.credit_type_init = 'PTS_31' then 'PTS31_RBP4'
	--	else coalesce(
	--		fr.segment_rbp, 
	--		case
	--		when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 1' then 'RBP 1'
	--		when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 2' then 'RBP 2'
	--		when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 3' then 'RBP 3'
	--		when a.credit_type_init = 'PTS' and a.rbp_gr = 'RBP 4' then 'RBP 4'
	--		end,
	--		'other'
	--	) end,
	--	eomonth(a.generation)
	--)
	--update a set a.avg_eps_rate_od = b.avg_eps, a.avg_eps_rate_int = b.avg_eps
	--from Temp_PTS_Test_stg_eps_rates a
	--inner join upd b
	--on a.term = b.term
	--and a.segment_rbp = b.segment_rbp
	--and a.generation = b.generation
	--and a.flag_kk = b.flag_kk
	--;




	print ('timing, Temp_PTS_Test_stg_eps_rates ' + format(getdate(), 'HH:mm:ss'))


	--коэффициент залогового покрытия
	drop table if exists Temp_PTS_Test_pledgecover;
	select a.rep_dt, a.vers,
		max((rr_90_plus_pldg - rr_90_plus) / (1 - rr_90_plus)) as koef
	into Temp_PTS_Test_pledgecover
	from risk.prov_stg_prov_rates_0_90 a
	where 1=1
	group by a.rep_dt, a.vers
	;

	print ('timing, Temp_PTS_Test_pledgecover ' + format(getdate(), 'HH:mm:ss'))



	--ставки БУ+ коэф залогового покрытия (ставки для 0-90 и рекавери рейты для 91+)
	-- Эти ставки в финал не идут, т.к. применяем новую методику БУ для ПТС и Бизнес-займов: a.provision_od_BU = a.provision_od_BU_alt
	select rep_dt, vers, dt_dml, count(*) from risk.prov_rep_rates a group by rep_dt, vers, dt_dml order by 1 desc, 2, 3 desc

	drop table if exists Temp_PTS_Test_det_BU_prov_rates;
	with base as (
		select cast('PTS' as varchar(100)) as product
			--применяем разные ставки для учето Макро-корректировки из-за ЭПС с июня 22 по декабрь 22
			, case when a.rep_dt = '2023-11-30' and a.vers = 2 then cast('2023-08-31' as date) end
			as dt_from
			, case when a.rep_dt = '2023-11-30' and a.vers = 2 then cast('4444-01-01' as date) end
			as dt_to
			, a.bucket
			, a.prov_rate
			, case when a.bucket = '[26] 721+' then 0 else a.recovery_rate end
			as recovery_rate
			, b.koef as pledge_cover--select top 10 *
		from risk.prov_rep_rates a
		left join Temp_PTS_Test_pledgecover b
		on a.rep_dt = b.rep_dt
			and a.vers = b.vers
		where a.rep_dt = '2023-11-30' and a.vers = 2
	union all
		select 
			cast('INSTALLMENT' as varchar(100))
			as product,
			case when a.rep_dt = '2023-11-30' and a.vers = 1 then cast('2023-08-31' as date) end
			as dt_from,
			case when a.rep_dt = '2023-11-30' and a.vers = 1 then cast('4444-01-01' as date) end as dt_to,
			a.bucket,
			a.prov_rate,
			case when a.bucket = '[26] 721+' then 0 else a.recovery_rate end as recovery_rate,
			null as pledge_cover
		from risk.prov_rep_rates a
		where a.rep_dt = '2023-11-30' and a.vers = 1
	)
	select 
		a.product
		, a.dt_from
		, a.dt_to
		, a.bucket
		, a.prov_rate
		, a.recovery_rate
		, case when a.product = 'INSTALLMENT' then 0.0 else a.pledge_cover end
		as pledge_cover
	into Temp_PTS_Test_det_BU_prov_rates
	from base a 
	;




	print ('timing, Temp_PTS_Test_det_BU_prov_rates ' + format(getdate(), 'HH:mm:ss'))


	--ставки НУ
	drop table if exists Temp_PTS_Test_det_NU_prov_rates;

	with base as (
		select 
		RiskDWH.dbo.get_bucket_360_m(a.DPD_MAX) as bucket,
		'UL' as NU_segment,
		a.RATE_RAS_UL_C as prov_rate_nu
		from riskdwh.dbo.[spr_ras_prov_rates_360_m_7_p_r_c_ul] a
		where a.BUCKET <> '[02] 1-7'
	union all
		select 
		RiskDWH.dbo.get_bucket_360_m(a.DPD_MAX) as bucket,
		'NP_NR_C' as NU_segment,
		a.RATE_RAS_NP_NR_C as prov_rate_nu
		from riskdwh.dbo.[spr_ras_prov_rates_360_m_7_p_r_c_ul] a
		where a.BUCKET <> '[02] 1-7'
	union all
		select 
		RiskDWH.dbo.get_bucket_360_m(a.DPD_MAX) as bucket,
		'NP_NR_NC' as NU_segment,
		a.RATE_RAS_NP_NR_NC as prov_rate_nu
		from riskdwh.dbo.[spr_ras_prov_rates_360_m_7_p_r_c_ul] a
		where a.BUCKET <> '[02] 1-7'
	union all
		select 
		RiskDWH.dbo.get_bucket_360_m(a.DPD_MAX) as bucket,
		'NP_R_C' as NU_segment,
		a.RATE_RAS_NP_R_C as prov_rate_nu
		from riskdwh.dbo.[spr_ras_prov_rates_360_m_7_p_r_c_ul] a
		where a.BUCKET <> '[02] 1-7'
	union all
		select 
		RiskDWH.dbo.get_bucket_360_m(a.DPD_MAX) as bucket,
		'NP_R_NC' as NU_segment,
		a.RATE_RAS_NP_R_NC as prov_rate_nu
		from riskdwh.dbo.[spr_ras_prov_rates_360_m_7_p_r_c_ul] a
		where a.BUCKET <> '[02] 1-7'
	union all
		select 
		RiskDWH.dbo.get_bucket_360_m(a.DPD_MAX) as bucket,
		'P_NR_C' as NU_segment,
		a.RATE_RAS_P_NR_C as prov_rate_nu
		from riskdwh.dbo.[spr_ras_prov_rates_360_m_7_p_r_c_ul] a
		where a.BUCKET <> '[02] 1-7'
	union all
		select 
		RiskDWH.dbo.get_bucket_360_m(a.DPD_MAX) as bucket,
		'P_NR_NC' as NU_segment,
		a.RATE_RAS_P_NR_NC as prov_rate_nu
		from riskdwh.dbo.[spr_ras_prov_rates_360_m_7_p_r_c_ul] a
		where a.BUCKET <> '[02] 1-7'
	union all
		select 
		RiskDWH.dbo.get_bucket_360_m(a.DPD_MAX) as bucket,
		'P_R_C' as NU_segment,
		a.RATE_RAS_P_R_C as prov_rate_nu
		from riskdwh.dbo.[spr_ras_prov_rates_360_m_7_p_r_c_ul] a
		where a.BUCKET <> '[02] 1-7'
	union all
		select 
		RiskDWH.dbo.get_bucket_360_m(a.DPD_MAX) as bucket,
		'P_R_NC' as NU_segment,
		a.RATE_RAS_P_R_NC as prov_rate_nu
		from riskdwh.dbo.[spr_ras_prov_rates_360_m_7_p_r_c_ul] a
		where a.BUCKET <> '[02] 1-7'
	union all
		select 
		RiskDWH.dbo.get_bucket_360_m(a.DPD_MAX) as bucket,
		'BANKRUPT' as NU_segment,
		cast(0.99 as float) as prov_rate_nu
		from riskdwh.dbo.[spr_ras_prov_rates_360_m_7_p_r_c_ul] a
		where a.BUCKET <> '[02] 1-7'
	)
	select a.bucket, a.NU_segment, a.prov_rate_nu
	into Temp_PTS_Test_det_NU_prov_rates
	from base a
	;




	drop table if exists Temp_PTS_Test_det_NU_prov_rates_PDL;
	--0 - 0, 1-7 - 0, 8-30 - 50, 31-60 80, 61-90 — 90, остальные 99%
	with base as (
		select 
		a.dpd_from,
		a.dpd_to,
		cast(a.koef as float) as koef
		from (values
		(0 ,	0,				0.0),
		(1 ,	7,				0.0),
		(8 ,	30,				0.50),
		(31 ,	60,				0.80),
		(61 ,	90,				0.90),
		(91 ,	100000000,		0.99)
		) a (dpd_from, dpd_to, koef)
	)
	select riskdwh.dbo.get_bucket_90(a.dpd_from) as dpd_bucket_90, max(a.koef) as koef
	into Temp_PTS_Test_det_NU_prov_rates_PDL
	from base a
	group by riskdwh.dbo.get_bucket_90(a.dpd_from)
	;






	------------------------------------------------------------------------------------------------









	--Распределение ПДН для новых выдач
	drop table if exists Temp_PTS_Test_pdn_distrib;

	select 
	cast(a.pdn_group as varchar(100)) as pdn_group,
	cast(a.segment_rbp as varchar(100)) as segment_rbp,
	cast(a.frac as float) as frac
	into Temp_PTS_Test_pdn_distrib
	from (values

	('NP_NR_C' , 'other' ,  @MPL_PDN_R1),
	('NP_NR_C' , 'PTS31_RBP4' ,  @MPL_PDN_R1),
	('NP_NR_C' , 'RBP 1' ,  @MPL_PDN_R1),
	('NP_NR_C' , 'RBP 2' ,  @MPL_PDN_R1),
	('NP_NR_C' , 'RBP 3' ,  @MPL_PDN_R1),
	('NP_NR_C' , 'RBP 4' ,  @MPL_PDN_R1),

	('P1_NR_C' , 'other' ,  @MPL_PDN_R2),
	('P1_NR_C' , 'PTS31_RBP4' ,  @MPL_PDN_R2),
	('P1_NR_C' , 'RBP 1' ,  @MPL_PDN_R2),
	('P1_NR_C' , 'RBP 2' ,  @MPL_PDN_R2),
	('P1_NR_C' , 'RBP 3' ,  @MPL_PDN_R2),
	('P1_NR_C' , 'RBP 4' ,  @MPL_PDN_R2),

	('P2_NR_C' , 'other' ,  (1 - @MPL_PDN_R1 - @MPL_PDN_R2)),
	('P2_NR_C' , 'PTS31_RBP4' ,  (1 - @MPL_PDN_R1 - @MPL_PDN_R2)),
	('P2_NR_C' , 'RBP 1' ,  (1 - @MPL_PDN_R1 - @MPL_PDN_R2)),
	('P2_NR_C' , 'RBP 2' ,  (1 - @MPL_PDN_R1 - @MPL_PDN_R2)),
	('P2_NR_C' , 'RBP 3' ,  (1 - @MPL_PDN_R1 - @MPL_PDN_R2)),
	('P2_NR_C' , 'RBP 4' ,  (1 - @MPL_PDN_R1 - @MPL_PDN_R2))

	) a (pdn_group, segment_rbp, frac)
	;


	/*

	select a.generation, a.flag_kk, a.amount, 
	case 
	when b.pdn is null then '[04] NULL'
	when b.pdn < 0.5 then '[01] 0-50'
	when b.pdn < 0.8 then '[02] 51-80' 
	else '[03] 80+' end as pdn_group,
	a.segment_rbp

	from Temp_PTS_Test_cred_reestr a
	left join dwh2.risk.pdn_calculation_2gen b
	on a.external_id = cast(b.Number as varchar(100))
	where a.generation >= '2023-09-30'

	*/



	print ('timing, Temp_PTS_Test_pdn_distrib ' + format(getdate(), 'HH:mm:ss'))



	--аналитические ставки НУ - обратным расчетом
	drop table if exists Temp_PTS_Test_analyt_prov_NU_rates;

	select a.NU_segment
			, RiskDWH.dbo.get_bucket_360_m(a.dpd) as bucket
			, case when sum(a.gross) = 0 then 0 else sum(a.prov_gross_NU) / sum(a.gross) end as prov_rate
	into Temp_PTS_Test_analyt_prov_NU_rates
	from Temp_PTS_Test_stg1_NU_segment_distrib a
	where a.mob_date_to = eomonth(@dt_back_test_from,-1)
	group by a.NU_segment, RiskDWH.dbo.get_bucket_360_m(a.dpd)
	;

	update Temp_PTS_Test_analyt_prov_NU_rates set prov_rate = 1 where prov_rate > 1;








	/*******************************************************************************************************************************************************************/


	--------------------------------------------------------------------------------------------------------
	-- PART 7 - финальная выборка с модельными и фактическими ОД, %%, платежами и списаниями
	--------------------------------------------------------------------------------------------------------



	--платежи ОД по бакетам

	drop table if exists Temp_PTS_Test_model_od_payment;
	select a.term, a.segment_rbp, a.flag_kk, a.generation, 
	--a.mob_to, 
	--a.mob_date_to,
	b.mob_to, 
	b.mob_date_to,
	a.bucket_90_to as bucket_90_from,
	b.bucket_90_to,
	--a.model_od, 
	--b.model_coef_adj,
	case 
	when a.mob_to = 0 then a.vl_rub_fact
	when a.flag = '[01] FACT' then a.fact_od else a.model_od 
	end * b.model_coef_adj as model_pmt
	into Temp_PTS_Test_model_od_payment
	from Temp_PTS_Test_stg4_back_test_results a
	left join Temp_PTS_Test_for_back_test b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	and a.generation = b.generation
	and a.mob_to = b.mob_to - 1
	and a.bucket_90_to = b.bucket_90_from
	where a.bucket_90_to not in ('[05] 90+','[06] Pay-off')
	and b.bucket_90_to = '[06] Pay-off'
	and a.mob_date_to >= eomonth(@dt_back_test_from,-1) 
	and left(a.flag_kk,2) <> 'KK'
	;


	--08/12/2021 - платежи в нулевом MoB
	with volume as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.vl_rub_fact * (1.0 - isnull(p.coef,1.0)) * isnull(sts.koef_po,1.0) as pdp_od
		from Temp_PTS_Test_stg4_back_test_results a
		left join Temp_PTS_Test_det_stress sts --28.02.2022
		on a.mob_date_to between sts.dt_from and sts.dt_to
		left join Temp_PTS_Test_det_pdp_coef p
		on a.segment_rbp = p.segment_rbp
		where a.mob_to = 0 and a.bucket_90_to = '[01] 0' and a.generation >= @dt_back_test_from
	)
	--select a.*, a.model_pmt - b.pdp_od
	update a set a.model_pmt = a.model_pmt - b.pdp_od
	from Temp_PTS_Test_model_od_payment a
	left join volume b
	on a.term = b.term 
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	and a.generation = b.generation
	where a.generation >= @dt_back_test_from
	and a.mob_to = 1
	and a.bucket_90_from = '[01] 0'
	;

	insert into Temp_PTS_Test_model_od_payment
	select a.term, a.segment_rbp, a.flag_kk, a.generation,
	0 as mob_to,
	a.generation as mob_date_to,
	'[01] 0' as bucket_90_from,
	'[06] Pay-off' as bucket_90_to,
	a.vl_rub_fact * (1.0 - isnull(p.coef,1.0)) * isnull(sts.koef_po,1) as model_pmt
	from Temp_PTS_Test_stg4_back_test_results a
	left join Temp_PTS_Test_det_stress sts --28.02.2022
	on a.mob_date_to between sts.dt_from and sts.dt_to
	left join Temp_PTS_Test_det_pdp_coef p
	on a.segment_rbp = p.segment_rbp 
	where a.mob_to = 0 and a.bucket_90_to = '[01] 0' and a.generation >= @dt_back_test_from
	;



	--Платежи ОД, Кредитные каникулы и заморозка
	insert into Temp_PTS_Test_model_od_payment
	select 
	a.term, a.segment_rbp, a.flag_kk, a.generation, 
	a.mob_to, 
	a.mob_date_to,
	a.bucket_90_from,
	a.bucket_90_to,
	sum(a.model_od) as model_pmt
	from Temp_PTS_Test_stg_freeze_model a
	where a.bucket_90_to = '[06] Pay-off'
	and a.bucket_90_from not in ('[05] 90+','[06] Pay-off')
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, 
	a.mob_to, 
	a.mob_date_to,
	a.bucket_90_from,
	a.bucket_90_to


	print ('timing, Temp_PTS_Test_model_od_payment ' + format(getdate(), 'HH:mm:ss'))




	--платежи ОД и %% по бакетам
	drop table if exists Temp_PTS_Test_model_all_payment;
	with default_pmt as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.bucket_90_from, a.mob_date_to, a.mob_to, 
		case 
		when a.npl_recovery - lag(a.npl_recovery,1,0) over (partition by a.term, a.segment_rbp, a.flag_kk, a.generation, a.bucket_90_from order by a.mob_date_to) < 0
		then 0
		else a.npl_recovery - lag(a.npl_recovery,1,0) over (partition by a.term, a.segment_rbp, a.flag_kk, a.generation, a.bucket_90_from order by a.mob_date_to) 
		end as model_pmt
		from (
			select a.mob_date_to, a.mob_to, a.term, a.segment_rbp, a.flag_kk, a.generation, '[05] 90+' as bucket_90_from, 
			sum(a.npl_recovery) as npl_recovery
			from Temp_PTS_Test_stg4_back_test_results a		
			group by a.mob_date_to, a.mob_to, a.term, a.segment_rbp, a.flag_kk, a.generation
			--having sum(fact_model_od) > 0
			--having sum(model_fact_od) > 0
		) a
	), u as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_to, a.mob_date_to, a.bucket_90_from, a.bucket_90_to, a.model_pmt
		from Temp_PTS_Test_model_od_payment a
		union all
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_to, a.mob_date_to, a.bucket_90_from, '[06] Pay-off' as bucket_90_to, a.model_pmt
		from default_pmt a 
		where a.mob_date_to >= @dt_back_test_from --'2021-06-30'
	), fines_straf as (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to,
		cast('[05] 90+' as varchar(100)) as bucket_90_from,
		cast('[06] Pay-off' as varchar(100)) as bucket_90_to,
		sum(a.fee_pmt) as fee_pmt,
		sum(a.straf_pmt) as straf_pmt
		from (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to,
			round(a.calc_od_payoff - lag(a.calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to),2) as od_pmt,
			round(a.calc_int_payoff - lag(a.calc_int_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to),2) as int_pmt,
			round(a.wo_calc_od_payoff - lag(a.wo_calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to),2) as od_wo,
			round(a.int_wo_calc_od_payoff - lag(a.int_wo_calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to),2) as int_wo,
			round(a.fee_calc_od_payoff - lag(a.fee_calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to),2) as fee_pmt,
			round(a.straf_calc_od_payoff - lag(a.straf_calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to),2) as straf_pmt
			from Temp_PTS_Test_default_recovery_fact a
		union all
			select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to,
			round(a.calc_od_payoff - lag(a.calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to),2) as od_pmt,
			round(a.calc_int_payoff - lag(a.calc_int_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to),2) as int_pmt,
			round(a.wo_calc_od_payoff - lag(a.wo_calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to),2) as od_wo,
			round(a.int_wo_calc_od_payoff - lag(a.int_wo_calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to),2) as int_wo,
			round(a.fee_calc_od_payoff - lag(a.fee_calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to),2) as fee_pmt,
			round(a.straf_calc_od_payoff - lag(a.straf_calc_od_payoff,1,0) over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk order by a.mob_date_to),2) as straf_pmt
			from Temp_PTS_Test_default_recovery_model a
		) a
		group by a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to
	)

	select u.term, u.segment_rbp, u.flag_kk, u.generation, u.mob_date_to, u.bucket_90_from, u.bucket_90_to,
	u.model_pmt as model_od_pmt, 
	m.int_pmt as model_int_pmt, 
	isnull(m.int_wo,0) as model_int_wo,
	f.fee_pmt,
	f.straf_pmt

	into Temp_PTS_Test_model_all_payment
	from u
	left join Temp_PTS_Test_model_payment_interest m
	on u.term = m.term
	and u.segment_rbp = m.segment_rbp
	and u.flag_kk = m.flag_kk
	and u.generation = m.generation
	and u.mob_date_to = m.mob_date_to
	and u.bucket_90_from = m.bucket_90_from

	left join fines_straf f
	on u.term = f.term
	and u.segment_rbp = f.segment_rbp
	and u.generation = f.generation
	and u.flag_kk = f.flag_kk
	and u.mob_date_to = f.mob_date_to
	and u.bucket_90_from = f.bucket_90_from
	;



	print ('timing, Temp_PTS_Test_model_all_payment ' + format(getdate(), 'HH:mm:ss'))




	--проверка на дубли

	/*
	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_to
	from Temp_PTS_Test_stg4_back_test_results a
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_to
	having count(*)>1
	;

	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.r_date, a.bucket, a.mod_num, a.last_MOD, a.freeze_from
	from Temp_PTS_Test_fact_due_int a
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.r_date, a.bucket, a.mod_num, a.last_MOD, a.freeze_from
	having count(*)>1
	;


	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_from
	from Temp_PTS_Test_model_payment_interest a
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_from
	having count(*)>1
	;


	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_from
	from Temp_PTS_Test_model_od_payment a
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_from
	having count(*)>1
	;

	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_from
	from Temp_PTS_Test_model_all_payment a
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_from
	having count(*)>1
	;
	*/





	--финальная сборка 
	drop table if exists Temp_PTS_Test_final_model;

	with fact_od_payment as (
		select a.generation, a.term, a.segment_rbp, a.flag_kk, a.mob_date_to, a.bucket_90_from, a.od_to
		from Temp_PTS_Test_stg3_agg a
		where a.bucket_90_to = '[06] Pay-off'
		and a.bucket_90_from <> '[06] Pay-off'
	), fact_interest_payment as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.r_date, a.dpd_bucket, 
		sum(a.principal_cnl) as principal_cnl,
		sum(a.percents_cnl) as percents_cnl,
		sum(a.fines_cnl) as fines_cnl,
		sum(a.other_cnl) as other_cnl
		from Temp_PTS_Test_stg_fact_od_int_pmt a
		group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.r_date, a.dpd_bucket
	), interest_model as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_to, sum(a.total_int) as total_int
		from Temp_PTS_Test_interest_model a
		group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_to
	), interest_fact as (
		select a.term, a.segment_rbp, a.flag_kk, a.generation, a.r_date, a.bucket, sum(a.total_int) as total_int
		from Temp_PTS_Test_fact_due_int a
		group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.r_date, a.bucket
	)
	select a.term, a.segment_rbp, a.flag_kk, a.flag, 
	a.generation, a.mob_date_to, a.mob_to,
	a.vl_rub_fact,

	a.bucket_90_to,
	a.fact_od,
	a.model_od,
	a.fact_model_od,
	a.model_fact_od,
	a.od_point_in_time,
	a.od_wo,
	a.portf_wo,
	a.portf_wo_recov,
	a.npl_recovery,
	a.delta_portf,
	a.delta_portf_wo,
	a.delta_portf_wo_recov,

	ifc.total_int as fact_int, --b.fact_int, 
	imd.total_int as model_int, --b.model_int,

	cast(null as float) as fact_prov_od,
	cast(null as float) as fact_prov_NU_od,
	cast(null as float) as fact_prov_int,
	cast(null as float) as fact_prov_NU_int,

	cast(null as float) as model_prov_od,
	cast(null as float) as model_prov_NU_od,
	cast(null as float) as model_prov_int,
	cast(null as float) as model_prov_NU_int,

	--d.fact_int_pmt,
	--d.model_int_pmt,
	--g.od_to as fact_od_pmt,

	h.principal_cnl as fact_od_pmt,
	f.model_od_pmt,
	h.percents_cnl as fact_int_pmt,
	f.model_int_pmt,

	isnull(f.fee_pmt,0) as model_fee_pmt,
	isnull(f.straf_pmt,0) as model_straf_pmt,

	isnull(f.model_int_wo,0) as int_wo,

	irts.avg_month_int_rate * 12.0 as avg_int_rate,

	h.fines_cnl as fact_fee_pmt,
	h.other_cnl as fact_straf_pmt

	into Temp_PTS_Test_final_model

	from Temp_PTS_Test_stg4_back_test_results a

	left join Temp_PTS_Test_model_all_payment f
	on a.term = f.term
	and a.segment_rbp = f.segment_rbp
	and a.flag_kk = f.flag_kk
	and a.generation = f.generation
	and a.mob_date_to = f.mob_date_to
	and a.bucket_90_to = f.bucket_90_from

	left join fact_od_payment g
	on a.term = g.term
	and a.segment_rbp = g.segment_rbp
	and a.flag_kk = g.flag_kk
	and a.generation = g.generation
	and a.mob_date_to = g.mob_date_to
	and a.bucket_90_to = g.bucket_90_from

	left join fact_interest_payment h
	on a.term = h.term
	and a.segment_rbp = h.segment_rbp
	and a.flag_kk = h.flag_kk
	and a.generation = h.generation
	and a.mob_date_to = h.r_date
	and a.bucket_90_to = h.dpd_bucket

	left join interest_model imd
	on a.term = imd.term
	and a.segment_rbp = imd.segment_rbp
	and a.flag_kk = imd.flag_kk
	and a.generation = imd.generation
	and a.mob_date_to = imd.mob_date_to
	and a.bucket_90_to = imd.bucket_90_to

	left join interest_fact ifc
	on a.term = ifc.term
	and a.segment_rbp = ifc.segment_rbp
	and a.flag_kk = ifc.flag_kk
	and a.generation = ifc.generation
	and a.mob_date_to = ifc.r_date
	and a.bucket_90_to = ifc.bucket

	left join Temp_PTS_Test_stg_int_rates irts
	on a.term = irts.term
	and a.segment_rbp = irts.segment_rbp
	and a.flag_kk = irts.flag_kk
	and a.generation = irts.generation

	;



	print ('timing, Temp_PTS_Test_final_model ' + format(getdate(), 'HH:mm:ss'))



	---------------------------------------------------------------------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------------------------------------------------------------------

	--declare @rdt date = '2024-10-31';declare @dt_back_test_from date = '2024-11-30';declare @vers int = 332;



	---Заливка в статичную таблицу
	delete from RiskDWH.Risk.budget_model 
	where vers = @vers
	;


	insert into RiskDWH.Risk.budget_model
	select 
	@rdt as rep_dt,
	@dt_back_test_from as model_dt_from,
	@vers as vers,
	cast(getdate() as datetime) as dt_dml,
	a.*
	from Temp_PTS_Test_final_model a 
	;


	--select max(a.vers) from risk.budget_model a

 
	/*


	select a.rep_dt, a.model_dt_from, a.dt_dml, a.vers, count(*)
	from RiskDWH.Risk.budget_model a
	group by a.rep_dt, a.model_dt_from, a.dt_dml, a.vers
	order by 4,1,2,3;



	select a.vers, count(*)
	from RiskDWH.Risk.budget_model a
	group by a.vers
	order by 1;


	*/

	print ('timing, insert into RiskDWH.Risk.budget_model ' + format(getdate(), 'HH:mm:ss'))







	--/* P 1-2 */
	----drop table Temp_PTS_Test_CMR_M;
	----drop table Temp_PTS_Test_cred_reestr;
	----drop table Temp_PTS_Test_det_current_params;
	----drop table Temp_PTS_Test_det_pieces_L1;
	----drop table Temp_PTS_Test_det_pieces_L2;
	----drop table Temp_PTS_Test_eps;
	----drop table Temp_PTS_Test_fact_due_int;
	----drop table Temp_PTS_Test_NU_segment_distrib;
	----drop table Temp_PTS_Test_rest_model;
	----drop table Temp_PTS_Test_stg_fact_od_int_pmt;
	----drop table Temp_PTS_Test_stg_freeze_mod;
	----drop table Temp_PTS_Test_stg_matrix_detail;
	----drop table Temp_PTS_Test_stg_payment;
	----drop table Temp_PTS_Test_stg_start_default;
	----drop table Temp_PTS_Test_stg_write_off;
	----drop table Temp_PTS_Test_stg1_NU_segment_distrib;
	----drop table Temp_PTS_Test_stg3_agg;
	----drop table Temp_PTS_Test_umfo_fact;
	----drop table Temp_PTS_Test_UMFO_NU_segment;
	----drop table Temp_PTS_Test_zamorozka;
	--/* P 3 */
	--drop table Temp_PTS_Test_default_recovery_fact;
	--drop table Temp_PTS_Test_default_recovery_model;
	----drop table Temp_PTS_Test_det_pdp_coef;
	----drop table Temp_PTS_Test_det_stress;
	----drop table Temp_PTS_Test_fix_matrix;
	----drop table Temp_PTS_Test_for_back_test;
	----drop table Temp_PTS_Test_last_fact;
	----drop table Temp_PTS_Test_new_volume;
	----drop table Temp_PTS_Test_npl_wo_and_recovery;
	----drop table Temp_PTS_Test_stg_freeze_model;
	----drop table Temp_PTS_Test_stg1_default_recovery_fact;
	----drop table Temp_PTS_Test_stg3_default_recovery_model;
	----drop table Temp_PTS_Test_stg4_back_test_results;
	----drop table Temp_PTS_Test_virt_gens;
	--/* P 5 */
	----drop table Temp_PTS_Test_interest_model;
	--drop table Temp_PTS_Test_model_payment_interest;
	----drop table Temp_PTS_Test_stg_int_rates;
	----drop table Temp_PTS_Test_stg_int_rec_wo;
	----drop table Temp_PTS_Test_stg2_int_rec_wo;
	--/* P 6-7 */
	----drop table Temp_PTS_Test_analyt_prov_NU_rates;
	----drop table Temp_PTS_Test_det_BU_prov_rates;
	----drop table Temp_PTS_Test_det_NU_prov_rates;
	----drop table Temp_PTS_Test_det_NU_prov_rates_PDL;
	----drop table Temp_PTS_Test_final_model;
	--drop table Temp_PTS_Test_model_all_payment;
	--drop table Temp_PTS_Test_model_od_payment;
	----drop table Temp_PTS_Test_pdn_distrib;
	--drop table Temp_PTS_Test_pledgecover;
	----drop table Temp_PTS_Test_stg_eps_rates;




	---------------------------------------------------------------------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------------------------------------------------------------------


	--часть 8




	--declare @rdt date = '2024-10-31';declare @dt_back_test_from date = '2024-11-30';declare @horizon int = datediff(MM,@rdt,'2024-12-31') + 1;declare @repeat_share float = 0.62;declare @vers int = -9999;





	print ('timing, PART 8 start ' + format(getdate(), 'HH:mm:ss'));





	drop table if exists Temp_PTS_Test_base;

	with aa as ( --дефолт, который идет из 90+ по факту
		select a.mob_date_to,
		a.term,
		a.segment_rbp,
		a.flag_kk,
		a.generation,
		RiskDWH.dbo.get_bucket_720(a.dpd_calc_alt) as bucket_720,
		RiskDWH.dbo.get_bucket_720_m(a.dpd_calc_alt) as bucket_720_m,
		RiskDWH.dbo.get_bucket_360_m(a.dpd_calc_alt) as bucket_360,
		RiskDWH.dbo.get_bucket_90(a.dpd_calc_alt) as bucket_90,
		RiskDWH.dbo.get_bucket_360(a.dpd_calc_alt) as dpd_bucket,
		cast((a.dpd_calc_alt - 91) / 30 as float) as months_in_default,
		sum(a.principal_rest_to - a.calc_od_payoff - a.wo_calc_od_payoff) as portf,
		cast(0 as float) as vl_rub_fact
		from (
			select a.*, 
			a.dpd_calc_src + DATEDIFF(MM, eomonth(@dt_back_test_from,-1), a.mob_date_to) * 30 as dpd_calc,
			91.0 + 30.0 * a.last_MOD as dpd_calc_alt
			from (
				select a.*,
				(91 + 30 * a.mod_last_fact) as dpd_calc_src
				from Temp_PTS_Test_stg1_default_recovery_fact a
			) a
		) a	
		group by a.term,
		a.segment_rbp,
		a.flag_kk,
		a.generation,
		a.mob_date_to, 
		RiskDWH.dbo.get_bucket_720(a.dpd_calc_alt), 
		RiskDWH.dbo.get_bucket_720_m(a.dpd_calc_alt),
		RiskDWH.dbo.get_bucket_90(a.dpd_calc_alt), 
		RiskDWH.dbo.get_bucket_360_m(a.dpd_calc_alt),
		RiskDWH.dbo.get_bucket_360(a.dpd_calc_alt),
		cast((a.dpd_calc_alt - 91) / 30 as float)
	), bb as ( --прогнозный дефолт
		select a.mob_date_to, 
		a.term,
		a.segment_rbp,
		a.flag_kk,
		a.generation,
		RiskDWH.dbo.get_bucket_720(a.dpd_calc_alt) as bucket_720,
		RiskDWH.dbo.get_bucket_720_m(a.dpd_calc_alt) as bucket_720_m,
		RiskDWH.dbo.get_bucket_360_m(a.dpd_calc_alt) as bucket_360,
		RiskDWH.dbo.get_bucket_90(a.dpd_calc_alt) as bucket_90,
		RiskDWH.dbo.get_bucket_360(a.dpd_calc_alt) as dpd_bucket,
		cast((a.dpd_calc_alt - 91) / 30 as float) as months_in_default,
		sum(a.calc_od_default - a.wo_calc_od_payoff) as portf,
		cast(0 as float) as vl_rub_fact
		from (
			select 
			b.generation, b.segment_rbp, b.flag_kk, b.term,
			b.mob_date_to, 
			91 + b.mod_num * 30 as dpd_calc,
			91 + b.last_MOD * 30 as dpd_calc_alt,
			sum(b.model_od) as model_od,
			sum(b.calc_od_default) as calc_od_default,
			sum(b.calc_od_payoff ) as calc_od_payoff,
			sum(b.wo_calc_od_default) as wo_calc_od_default,
			sum(b.wo_calc_od_payoff	) as wo_calc_od_payoff,
			sum(b.int_wo_calc_od_default) as int_wo_calc_od_default,
			sum(b.int_wo_calc_od_payoff	) as int_wo_calc_od_payoff
			from Temp_PTS_Test_stg3_default_recovery_model b
			group by b.generation, b.segment_rbp, b.flag_kk, b.term, b.mob_date_to, b.mod_num, b.last_MOD
		) a	
		group by a.term,
		a.segment_rbp,
		a.flag_kk,
		a.generation,
		a.mob_date_to, 
		RiskDWH.dbo.get_bucket_720(a.dpd_calc_alt), 
		RiskDWH.dbo.get_bucket_720_m(a.dpd_calc_alt), 
		RiskDWH.dbo.get_bucket_90(a.dpd_calc_alt), 
		RiskDWH.dbo.get_bucket_360_m(a.dpd_calc_alt),
		RiskDWH.dbo.get_bucket_360(a.dpd_calc_alt),
		cast((a.dpd_calc_alt - 91) / 30 as float)
	), cc as ( --бакет "заморозка" - преобразуем солгасно аналитическому DPD
		select a.mob_date_to, 
		a.term,
		a.segment_rbp,
		'FREEZE' as flag_kk, --a.flag_kk,
		a.generation,
			--RiskDWH.dbo.get_bucket_720( 91 + a.mod_num * 30 ) as bucket_720,
			RiskDWH.dbo.get_bucket_720( 0 ) as bucket_720,
			RiskDWH.dbo.get_bucket_720_m( 0 ) as bucket_720_m,
			RiskDWH.dbo.get_bucket_360_m( 0 ) as bucket_360,
			RiskDWH.dbo.get_bucket_90( 0 ) as bucket_90,
			RiskDWH.dbo.get_bucket_360( 0 ) as dpd_bucket,
		cast(0 as float) as months_in_default,
		sum(a.model_od) as portf,
		cast(0 as float) as vl_rub_fact
		from Temp_PTS_Test_stg_freeze_model a
		where a.bucket_90_to = '[07] Freeze'
		group by a.term, a.segment_rbp,
		--a.flag_kk,
		a.generation, a.mob_date_to
	), un as (
		select * from aa
		union all
		select * from bb
		union all
		select * from cc
		union all
		select a.mob_date_to, 
		a.term,
		a.segment_rbp,
		a.flag_kk,
		a.generation,
		a.bucket_90_to as bucket_720, 
		a.bucket_90_to as bucket_720_m, 
		a.bucket_90_to as bucket_360, 
		a.bucket_90_to as bucket_90,
		a.bucket_90_to as dpd_bucket,
		cast(0 as float) as months_in_default,
		sum(a.model_od) as portf,
		sum(case when a.bucket_90_to = '[01] 0' then a.vl_rub_fact else 0 end) as vl_rub_fact
		from Temp_PTS_Test_stg4_back_test_results a	
		where a.flag in ('[02] BACK-TEST', '[03] FORECAST')
		and a.bucket_90_to in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90')
		group by a.term,
		a.segment_rbp,
		a.flag_kk,
		a.generation,
		a.mob_date_to, a.bucket_90_to
	), interest as (
		select a.mob_date_to, 
		a.term,
		a.segment_rbp,
		iif(a.bucket_90_to = '[07] Freeze', 'FREEZE', a.flag_kk) as flag_kk,
		--a.flag_kk,
		a.generation,
		RiskDWH.dbo.get_bucket_720( case when a.bucket_90_to = '[07] Freeze' then 0
		else iif(a.last_MOD is null, (cast(SUBSTRING(a.bucket_90_to,2,2) as int) - 1) * 30,  91 + 30 * a.last_MOD) end) as bucket_720,
		RiskDWH.dbo.get_bucket_720_m( case when a.bucket_90_to = '[07] Freeze' then 0
		else iif(a.last_MOD is null, (cast(SUBSTRING(a.bucket_90_to,2,2) as int) - 1) * 30,  91 + 30 * a.last_MOD) end) as bucket_720_m,
		RiskDWH.dbo.get_bucket_360_m( case when a.bucket_90_to = '[07] Freeze' then 0
		else iif(a.last_MOD is null, (cast(SUBSTRING(a.bucket_90_to,2,2) as int) - 1) * 30,  91 + 30 * a.last_MOD) end) as bucket_360,	
		RiskDWH.dbo.get_bucket_90( case when a.bucket_90_to = '[07] Freeze' then 0
		else iif(a.last_MOD is null, (cast(SUBSTRING(a.bucket_90_to,2,2) as int) - 1) * 30,  91 + 30 * a.last_MOD) end) as bucket_90,
		RiskDWH.dbo.get_bucket_360( case when a.bucket_90_to = '[07] Freeze' then 0
		else iif(a.last_MOD is null, (cast(SUBSTRING(a.bucket_90_to,2,2) as int) - 1) * 30,  91 + 30 * a.last_MOD) end) as dpd_bucket,
		isnull(a.last_MOD,0) as months_in_default,
		sum(a.total_int) as interest
		--iif(a.mod_num is null, (cast(SUBSTRING(a.bucket_90_to,2,2) as int) - 1) * 30,  91 + 30 * a.mod_num) as dpd_analyt
		from Temp_PTS_Test_interest_model a
		where a.bucket_90_to <> '[06] Pay-off'
		and not (a.bucket_90_to = '[05] 90+' and a.last_MOD is null)
		group by 
		a.term,
		a.segment_rbp,
		iif(a.bucket_90_to = '[07] Freeze', 'FREEZE', a.flag_kk), --a.flag_kk,
		a.generation,
		a.mob_date_to, 
		RiskDWH.dbo.get_bucket_720( case when a.bucket_90_to = '[07] Freeze' then 0
		else iif(a.last_MOD is null, (cast(SUBSTRING(a.bucket_90_to,2,2) as int) - 1) * 30,  91 + 30 * a.last_MOD) end),
		RiskDWH.dbo.get_bucket_720_m( case when a.bucket_90_to = '[07] Freeze' then 0
		else iif(a.last_MOD is null, (cast(SUBSTRING(a.bucket_90_to,2,2) as int) - 1) * 30,  91 + 30 * a.last_MOD) end),
		RiskDWH.dbo.get_bucket_360_m( case when a.bucket_90_to = '[07] Freeze' then 0
		else iif(a.last_MOD is null, (cast(SUBSTRING(a.bucket_90_to,2,2) as int) - 1) * 30,  91 + 30 * a.last_MOD) end),
		RiskDWH.dbo.get_bucket_90( case when a.bucket_90_to = '[07] Freeze' then 0
		else iif(a.last_MOD is null, (cast(SUBSTRING(a.bucket_90_to,2,2) as int) - 1) * 30,  91 + 30 * a.last_MOD) end),
		RiskDWH.dbo.get_bucket_360( case when a.bucket_90_to = '[07] Freeze' then 0
		else iif(a.last_MOD is null, (cast(SUBSTRING(a.bucket_90_to,2,2) as int) - 1) * 30,  91 + 30 * a.last_MOD) end),
		isnull(a.last_MOD,0)
	), base as (
		select un.mob_date_to, 
		un.term,
		un.segment_rbp,
		un.flag_kk,
		un.generation,
		un.bucket_720, un.bucket_720_m, un.bucket_360, un.bucket_90, un.dpd_bucket, un.months_in_default,
		concat(DATEPART(YYYY, eomonth(un.mob_date_to,1)), '-', DATEPART(QQ, eomonth(un.mob_date_to,1))) as quart_prov,
		sum(un.portf) as portf,
		sum(un.vl_rub_fact) as vl_rub_fact
		from un 
		group by 
		un.term,
		un.segment_rbp,
		un.flag_kk,
		un.generation,
		un.mob_date_to, un.bucket_720, un.bucket_720_m, un.bucket_360, un.bucket_90, un.dpd_bucket, un.months_in_default
	), total as (
		select a.mob_date_to, 
		a.term,
		a.segment_rbp,
		a.flag_kk,
		a.generation,
		a.bucket_720, a.bucket_720_m, a.bucket_360, a.bucket_90, a.dpd_bucket, 
		a.months_in_default,
		a.quart_prov,
		a.portf,
		b.interest,
		a.vl_rub_fact
		from base a
		left join interest b
		on a.mob_date_to = b.mob_date_to
		and a.bucket_720 = b.bucket_720
		and a.bucket_720_m = b.bucket_720_m
		and a.bucket_360 = b.bucket_360
		and a.bucket_90 = b.bucket_90
		and a.dpd_bucket = b.dpd_bucket
		and a.term = b.term
		and a.segment_rbp = b.segment_rbp
		and a.generation = b.generation
		and a.flag_kk = b.flag_kk
		and a.months_in_default = b.months_in_default
	)

	select a.mob_date_to, 
		a.term,
		a.segment_rbp,
		a.flag_kk,
		a.generation,
		a.bucket_720, a.bucket_720_m, a.bucket_360, a.bucket_90, a.dpd_bucket, a.months_in_default,
		a.quart_prov,
		b.NU_segment as NU_segment,
		a.portf * coalesce(b.share,1.0) as portf,
		a.interest * coalesce(b.share,1.0) as interest,
		a.vl_rub_fact * coalesce(b.share,1.0) as vl_rub_fact

	into Temp_PTS_Test_base
	from total a
	left join Temp_PTS_Test_NU_segment_distrib b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp 
	and a.generation = b.generation
	and iif(a.flag_kk = 'FREEZE', 'KK', a.flag_kk) = b.flag_kk
	and a.bucket_90 = b.bucket_90_to
	where a.generation < @dt_back_test_from

	union all
	--новые выдачи
	select a.mob_date_to, 
		a.term,
		a.segment_rbp,
		a.flag_kk,
		a.generation,
		a.bucket_720, a.bucket_720_m, a.bucket_360, a.bucket_90, a.dpd_bucket, a.months_in_default,
		a.quart_prov,
		b.pdn_group as NU_segment,
		a.portf * isnull(b.frac,1.0) as portf,	
		a.interest * isnull(b.frac,1.0) as interest,
		a.vl_rub_fact * isnull(b.frac,1.0) as vl_rub_fact

	from total a
	left join Temp_PTS_Test_pdn_distrib b
	on a.segment_rbp = b.segment_rbp
	where a.generation >= @dt_back_test_from
	and a.flag_kk <> 'BUSINESS'


	union all
	--новые выдачи, бизнес-займы
	select a.mob_date_to, 
		a.term,
		a.segment_rbp,
		a.flag_kk,
		a.generation,
		a.bucket_720, a.bucket_720_m, a.bucket_360, a.bucket_90, a.dpd_bucket, a.months_in_default,
		a.quart_prov,
		'UL' as NU_segment,
		a.portf as portf,
		a.interest as interest,
		a.vl_rub_fact

	from total a
	where a.generation >= @dt_back_test_from
	and a.flag_kk = 'BUSINESS'

	;








	;

	print ('timing, Temp_PTS_Test_base ' + format(getdate(), 'HH:mm:ss'));



	------------------------------------------------------------------------------------------------------------


	drop table if exists Temp_PTS_Test_virt_IFRS_rates_0_90;


	select 
		cast('PTS' as varchar(100)) as product,
		a.dpd_bucket, 
		sum(a.prov_IFRS_TTC) / sum(a.gross) as prov_rate
	into Temp_PTS_Test_virt_IFRS_rates_0_90
	from risk.IFRS9_vitr a
	inner join risk.det_IFRS_proper_vers b
	on a.r_date = b.r_date
	and a.vers = b.vers
	where a.r_date = '2024-03-31'
	and a.dpd_bucket in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90')
	and a.product = 'PTS'
	group by a.dpd_bucket
	;


	insert into Temp_PTS_Test_virt_IFRS_rates_0_90
	select 
	cast('INSTALLMENT' as varchar(100)) as product,
	a.dpd_bucket, 
	sum(a.prov_IFRS_TTC) / sum(a.gross) as prov_rate
	from risk.IFRS9_vitr a
	inner join risk.det_IFRS_proper_vers b
	on a.r_date = b.r_date
	and a.vers = b.vers
	where a.r_date = '2024-03-31'
	and a.dpd_bucket in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90')
	and a.product = 'INSTALLMENT'
	group by a.dpd_bucket
	;




	drop table if exists Temp_PTS_Test_virt_IFRS_rates_91_plus;

	create table Temp_PTS_Test_virt_IFRS_rates_91_plus (product varchar(100),months_in_default int, prov_rate float);

	declare @mm int = 0;

	while @mm < 400 begin

	insert into Temp_PTS_Test_virt_IFRS_rates_91_plus (product,months_in_default, prov_rate) values ('PTS',@mm, 1.0);
	insert into Temp_PTS_Test_virt_IFRS_rates_91_plus (product,months_in_default, prov_rate) values ('INSTALLMENT',@mm, 1.0);

	set @mm = @mm + 1;

	end;


	merge into Temp_PTS_Test_virt_IFRS_rates_91_plus dst
	using (select months_in_default as mod_num, LGD_disc from risk.lgd_gross_cond where r_date = '2024-03-31' and product = 'PTS') src
	on (dst.months_in_default = src.mod_num and dst.product = 'PTS')
	when matched then update set dst.prov_rate = src.LGD_disc
	;



	drop table if exists Temp_PTS_Test_det_LGD_IL;
	select 
	cast(a.mod_num as int) as mod_num, 
	cast(a.lgd as float) as lgd
	into Temp_PTS_Test_det_LGD_IL
	from (values
	(0 , 0.85663078),(1 , 0.87151745),(2 , 0.88523768),(3 , 0.89765175),(4 , 0.90913646),(5 , 0.91653834),(6 , 0.92538083),(7 , 0.93410882),(8 , 0.94140201),(9 , 0.94800825),(10 , 0.95324631),
	(11 , 0.95745696),(12 , 0.96114468),(13 , 0.96519033),(14 , 0.97161338),(15 , 0.97727505),(16 , 0.98156973),(17 , 0.98539585),(18 , 0.9927769),(19 , 0.99574202),(20 , 1)
	) a (mod_num, lgd)
	;


	merge into Temp_PTS_Test_virt_IFRS_rates_91_plus dst
	using (select * from Temp_PTS_Test_det_LGD_IL) src
	on (dst.months_in_default = src.mod_num and dst.product = 'INSTALLMENT')
	when matched then update set dst.prov_rate = src.lgd
	;




	------------------------------------------------------------------------------------------------------------
	--Новая методика для INSTALLMENT - свой LGD и PD, дисконт 7.2
	------------------------------------------------------------------------------------------------------------


	drop table if exists Temp_PTS_Test_det_BU_IL_DEC23_REC;
	select 
	a.mod_n-1 as mod_n,
	cast(a.recovery_rate as float) as recovery_rate
	into Temp_PTS_Test_det_BU_IL_DEC23_REC
	from (values
	(1 , 0.007951563),
	(2 , 0.0037317878),
	(3 , 0.00506509),
	(4 , 0.0049566557),
	(5 , 0.0025567747),
	(6 , 0.0027313392),
	(7 , 0.005163983),
	(8 , 0.0095257192),
	(9 , 0.0055326142),
	(10 , 0.0119783095),
	(11 , 0.0211942292),
	(12 , 0.0122570888)
	) a (mod_n, recovery_rate)
	;

	declare @cycle_int1 int;
	select @cycle_int1 = max(mod_n)+1 from Temp_PTS_Test_det_BU_IL_DEC23_REC;
	while @cycle_int1 < 500 begin
	insert into Temp_PTS_Test_det_BU_IL_DEC23_REC (mod_n, recovery_rate) values (@cycle_int1, 0)
	set @cycle_int1 = @cycle_int1 + 1;
	end;




	drop table if exists Temp_PTS_Test_det_BU_IL_DEC23_PD;
	select 
	cast(a.dpd_bucket_90 as varchar(100)) as dpd_bucket_90,
	cast(a.koef as float) as koef
	into Temp_PTS_Test_det_BU_IL_DEC23_PD
	from (values
	--('[01] 0' , 0.2851823049),('[02] 1-30' , 0.7085613228),('[03] 31-60' , 0.9218715461),('[04] 61-90' , 0.9676759942)
	--('[01] 0' , 0.1878793238),('[02] 1-30' , 0.5026836865),('[03] 31-60' , 0.7822920362),('[04] 61-90' , 0.8595192129)
	--('[01] 0' , 0.1829612511),('[02] 1-30' , 0.6741461912),('[03] 31-60' , 0.9092205666),('[04] 61-90' , 0.9701193039)
	('[01] 0' , 0.2022403363),	('[02] 1-30' , 0.6759341424),	('[03] 31-60' , 0.9170313061),	('[04] 61-90' , 0.9708468186)

	) a (dpd_bucket_90, koef)
	;

	


	drop table if exists Temp_PTS_Test_det_BU_IL_DEC23_LGD;
	with discrec as (
		select a.mod_n, a.recovery_rate, 
		a.recovery_rate * power(1.0 + /*0.072*/ @bu_disc_bz, -a.mod_n / 12.0) as d_recovery_rate
		from Temp_PTS_Test_det_BU_IL_DEC23_REC a
	), acc as (
		select a.mod_n,
		a.recovery_rate,
		a.d_recovery_rate,
		isnull(sum(isnull(a.d_recovery_rate,0)) over (order by a.mod_n rows between unbounded preceding and 1 preceding),0) as d_rec_rate_acc1,
		isnull(sum(isnull(a.d_recovery_rate,0)) over (order by a.mod_n rows between current row and unbounded following),0) as d_rec_rate_acc2
		from discrec a
	)
	select 
	a.mod_n, a.recovery_rate, a.d_recovery_rate, a.d_rec_rate_acc1, a.d_rec_rate_acc2, 
	1.0 - a.d_rec_rate_acc2 / (1.0 - a.d_rec_rate_acc1) - 0.20 as lgd
	into Temp_PTS_Test_det_BU_IL_DEC23_LGD
	from acc a
	order by 1
	;


	drop table if exists Temp_PTS_Test_det_BU_IL_DEC23_0_90;
	select 
	a.dpd_bucket_90, 
	a.koef as PD, 
	a.koef * b.lgd as prov_rate
	into Temp_PTS_Test_det_BU_IL_DEC23_0_90
	from Temp_PTS_Test_det_BU_IL_DEC23_PD a
	left join Temp_PTS_Test_det_BU_IL_DEC23_LGD b
	on b.mod_n = 0
	;





	------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- FIX2 для ПТС - БУ-резерв - сценарий по ставкам
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------


	--ставки и дисконты для БУ в 2025 году
	drop table if exists Temp_PTS_Test_virt_BU_PTS_2024_rates;
	with base as (
		select 
		cast(a.dt_from as date) as dt_from, 
		cast(a.dt_to as date) as dt_to, 
		cast(a.disc as float) as disc,
		cast(a.korr as float) as korr
		from (values


	('2025-10-31' , '2025-10-31' , @bu_disc	, 1.00),
	('2025-11-30' , '2025-11-30' , @bu_disc	, 1.00),
	('2025-12-31' , '2025-12-31' , @bu_disc	, 1.00),
	('2026-01-31' , '2026-01-31' , @bu_disc	, 1.00),
	('2026-02-28' , '2026-02-28' , @bu_disc	, 1.00),
	('2026-03-31' , '2026-03-31' , @bu_disc	, 1.00),
	('2026-04-30' , '2026-04-30' , @bu_disc	, 1.00),
	('2026-05-31' , '2026-05-31' , @bu_disc	, 1.00),
	('2026-06-30' , '2026-06-30' , @bu_disc	, 1.00),
	('2026-07-31' , '2026-07-31' , @bu_disc	, 1.00),
	('2026-08-31' , '2026-08-31' , @bu_disc	, 1.00),
	('2026-09-30' , '2026-09-30' , @bu_disc	, 1.00),
	('2026-10-31' , '2026-10-31' , @bu_disc	, 1.00),
	('2026-11-30' , '2026-11-30' , @bu_disc	, 1.00),
	('2026-12-31' , '2026-12-31' , @bu_disc	, 1.00),
	('2027-01-31' , '2027-01-31' , @bu_disc	, 1.00),
	('2027-02-28' , '2027-02-28' , @bu_disc	, 1.00),
	('2027-03-31' , '2027-03-31' , @bu_disc	, 1.00),
	('2027-04-30' , '2027-04-30' , @bu_disc	, 1.00),
	('2027-05-31' , '2027-05-31' , @bu_disc	, 1.00),
	('2027-06-30' , '2027-06-30' , @bu_disc	, 1.00),
	('2027-07-31' , '2027-07-31' , @bu_disc	, 1.00),
	('2027-08-31' , '2027-08-31' , @bu_disc	, 1.00),
	('2027-09-30' , '2027-09-30' , @bu_disc	, 1.00),
	('2027-10-31' , '2027-10-31' , @bu_disc	, 1.00),
	('2027-11-30' , '2027-11-30' , @bu_disc	, 1.00),
	('2027-12-31' , '2027-12-31' , @bu_disc	, 1.00),
	('2028-01-31' , '2028-01-31' , @bu_disc	, 1.00),
	('2028-02-29' , '2028-02-29' , @bu_disc	, 1.00),
	('2028-03-31' , '2028-03-31' , @bu_disc	, 1.00),
	('2028-04-30' , '2028-04-30' , @bu_disc	, 1.00),
	('2028-05-31' , '2028-05-31' , @bu_disc	, 1.00),
	('2028-06-30' , '2028-06-30' , @bu_disc	, 1.00),
	('2028-07-31' , '2028-07-31' , @bu_disc	, 1.00),
	('2028-08-31' , '2028-08-31' , @bu_disc	, 1.00),
	('2028-09-30' , '2028-09-30' , @bu_disc	, 1.00),
	('2028-10-31' , '2028-10-31' , @bu_disc	, 1.00),
	('2028-11-30' , '2028-11-30' , @bu_disc	, 1.00),
	('2028-12-31' , '2028-12-31' , @bu_disc	, 1.00),
							   
	('2029-01-31' , '2029-01-31' , @bu_disc	, 1.00),
	('2029-02-28' , '2029-02-28' , @bu_disc	, 1.00),
	('2029-03-31' , '2029-03-31' , @bu_disc	, 1.00),
	('2029-04-30' , '2029-04-30' , @bu_disc	, 1.00),
	('2029-05-31' , '2029-05-31' , @bu_disc	, 1.00),
	('2029-06-30' , '2029-06-30' , @bu_disc	, 1.00),
	('2029-07-31' , '2029-07-31' , @bu_disc	, 1.00),
	('2029-08-31' , '2029-08-31' , @bu_disc	, 1.00),
	('2029-09-30' , '2029-09-30' , @bu_disc	, 1.00),
	('2029-10-31' , '2029-10-31' , @bu_disc	, 1.00),
	('2029-11-30' , '2029-11-30' , @bu_disc	, 1.00),
	('2029-12-31' , '2029-12-31' , @bu_disc	, 1.00),
	('2030-01-31' , '2030-01-31' , @bu_disc	, 1.00),
	('2030-02-28' , '2030-02-28' , @bu_disc	, 1.00),
	('2030-03-31' , '2030-03-31' , @bu_disc	, 1.00),
	('2030-04-30' , '2030-04-30' , @bu_disc	, 1.00),
	('2030-05-31' , '2030-05-31' , @bu_disc	, 1.00),
	('2030-06-30' , '2030-06-30' , @bu_disc	, 1.00),
	('2030-07-31' , '2030-07-31' , @bu_disc	, 1.00),
	('2030-08-31' , '2030-08-31' , @bu_disc	, 1.00),
	('2030-09-30' , '2030-09-30' , @bu_disc	, 1.00),
	('2030-10-31' , '2030-10-31' , @bu_disc	, 1.00),
	('2030-11-30' , '2030-11-30' , @bu_disc	, 1.00),
	('2030-12-31' , '2030-12-31' , @bu_disc	, 1.00)


		) a (dt_from, dt_to, disc, korr)
	), rates as (

	/*
	Bucket_DPD_3000	Rate
	[001] 0 	2,03%
	[002] 1-30	4,76%
	[003] 31-60	12,33%
	[004] 61-90	13,59%
	[002] 1-30	15,81%
	[003] 31-60	15,81%
	[004] 61-90	15,81%
	[005] 91-120	16,05%
	[006] 121-150	24,83%
	*/

	select b.discount
		, a.dpd_bucket as bucket
		, null as mod_num
		, --a.PD_EAD * b.LGD_WO
		--set provision rates
		case when a.dpd_bucket = '[01] 0' then 0.0203
			when a.dpd_bucket = '[02] 1-30' then 0.0476
			when a.dpd_bucket = '[03] 31-60' then 0.1233
			when a.dpd_bucket = '[04] 61-90' then 0.1359 else 0 end
		as prov_rate				
		from (	
			select a.dpd_bucket, 
				--sum(a.prov_IFRS_PIT / a.LGD) / sum(a.gross) as PD_EAD
				sum(a.prov_IFRS_PIT) / sum(a.gross * a.LGD) as PD_EAD--select max(r_date)
			from risk.IFRS9_vitr a
			where a.r_date = '2024-08-31' and a.vers = 1
				and a.product = 'PTS'		
				and a.dpd_bucket <> '[05] 90+'
			group by a.dpd_bucket
		) a			
		left join risk.prov2_lgd b			
		on b.rep_dt = @rdt and b.vers = @LGD_vers
		and b.mod_num = 1

	union all

		select a.discount, '[05] 90+' as bucket, a.mod_num - 1 as mod_num, a.LGD_WO as prov_rate			
		from risk.prov2_lgd a			
		where a.rep_dt = @rdt and a.vers = @LGD_vers

	)
	select a.dt_from, a.dt_to, a.disc, b.bucket, b.mod_num, 
	b.prov_rate * a.korr as prov_rate
	into Temp_PTS_Test_virt_BU_PTS_2024_rates
	from base a
	left join rates b
	on a.disc = b.discount
	;



	------------------------------------------------------------------------------------------------------------


	drop table if exists Temp_PTS_Test_BU_rates_BUSINESS;
	select 
	cast(a.dpd_bucket as varchar(100)) as dpd_bucket, 
	cast(a.rate as float) as rate
	into Temp_PTS_Test_BU_rates_BUSINESS
	from (values
	('[01] 0' , 0.015),
	('[02] 1-30' , 0.05),
	('[03] 31-60' , 0.3),
	('[04] 61-90' , 0.5),
	('[05] 91-120' , 0.7),
	('[06] 121-150' , 0.9),
	('[07] 151-180' , 0.9),
	('[08] 181-210' , 0.99),
	('[09] 211-240' , 0.99),
	('[10] 241-270' , 0.99),
	('[11] 271-300' , 0.99),
	('[12] 301-330' , 0.99),
	('[13] 331-360' , 0.99),
	('[14] 360+' , 0.99)
	) a (dpd_bucket, rate)
	;


	------------------------------------------------------------------------------------------------------------




	drop table if exists Temp_PTS_Test_for_finance;

	with model as (
		select a.mob_date_to, 
		a.term,
		a.segment_rbp,
		a.flag_kk,
		a.generation,
		--a.bucket_720,
		a.dpd_bucket,
		a.NU_segment,
	
		sum(a.portf) as portf,
		--13.07.2022
		sum(a.portf * case 
			--0-90
			when cast(substring(a.bucket_720,2,2) as int) <= 4 then round(b.prov_rate,4)
			--91+
			when cast(substring(a.bucket_720,2,2) as int) > 4 then 
			(1.0 - round( 1.0 / power(1.0 + ep.avg_eps_rate_od, (720.0 - 
				case when a.bucket_720 = '[26] 721+' then 720.0 else (cast(substring(a.bucket_720,2,2) as int) - 1.0) * 30.0 end
				) / 365.0), 5) * b.pledge_cover) * 
			 ( 1.0 - round(b.recovery_rate,8) / round( power(1.0 + ep.avg_eps_rate_od, 30.0 / 365.0), 5) )
			end
		) as provisions_od,

		--8.09.2022
		sum(a.portf * case 
		when a.flag_kk = 'BUSINESS' then bus_bu.rate
		when a.flag_kk = 'INSTALLMENT' and a.bucket_90 in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90') then buil090.prov_rate
		when a.flag_kk = 'INSTALLMENT' then buillgd.lgd
		when year(a.mob_date_to) >= 2024 then bu24.prov_rate
		end) as provisions_od_alt,

		--3.10.2022
		sum(a.portf * case 
		when a.bucket_90 in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90') then ifrs1.prov_rate
		else ifrs2.prov_rate end) as provisions_od_IFRS,


		sum(a.portf * case
		when a.flag_kk = 'BUSINESS' then bus_bu.rate
		else iif(a.NU_segment like 'BANKRUPT%' and a.mob_date_to >= '2021-08-31', 0.99, coalesce(nupdl.koef,e.prov_rate, d.prov_rate_nu)) end
		) as provisions_od_NU,



		sum(a.interest) as interest,
		--13.07.2022
		sum(a.interest *  case 
			--0-90
			when cast(substring(a.bucket_720,2,2) as int) <= 4 then round(b.prov_rate,4)
			--91+
			when cast(substring(a.bucket_720,2,2) as int) > 4 then 
			(1.0 - round( 1.0 / power(1.0 + ep.avg_eps_rate_int, (720.0 - 
				case when a.bucket_720 = '[26] 721+' then 720.0 else (cast(substring(a.bucket_720,2,2) as int) - 1.0) * 30.0 end
				) / 365.0), 5) * b.pledge_cover) * 
			( 1.0 - round(b.recovery_rate,8) / round( power(1.0 + ep.avg_eps_rate_int, 30.0 / 365.0), 5) )
			end
		) as provisions_int,
		--8.09.2022
		sum(a.interest * case 
		when a.flag_kk = 'BUSINESS' then bus_bu.rate
		when a.flag_kk = 'INSTALLMENT' and a.bucket_90 in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90') then buil090.prov_rate
		when a.flag_kk = 'INSTALLMENT' then buillgd.lgd
		when year(a.mob_date_to) >= 2024 then bu24.prov_rate
		end) as provisions_int_alt,

		--3.10.2022
		sum(a.interest * case 
		when a.bucket_90 in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90') then ifrs1.prov_rate
		else ifrs2.prov_rate end) as provisions_int_IFRS,

		sum(a.interest * case
		when a.flag_kk = 'BUSINESS' then bus_bu.rate
		else iif(a.NU_segment like 'BANKRUPT%' and a.mob_date_to >= '2021-08-31', 0.99, coalesce(nupdl.koef,e.prov_rate, d.prov_rate_nu)) end	
		) as provisions_int_NU,


		--ceiling(sum(a.portf / coalesce(d2.avg_od, d1.avg_od) ) ) as pieces
		sum(a.portf / coalesce(d2.avg_od, d1.avg_od) )  as pieces

		from Temp_PTS_Test_base a

		--13.07.2022
		left join Temp_PTS_Test_det_BU_prov_rates b
		on iif(a.flag_kk = 'INSTALLMENT', 'INSTALLMENT', 'PTS') = b.product
		and a.bucket_720 = b.bucket
		and a.mob_date_to between b.dt_from and b.dt_to

		left join Temp_PTS_Test_stg_eps_rates ep
		on a.term = ep.term
		and a.segment_rbp = ep.segment_rbp
		and a.generation = ep.generation
		and a.flag_kk = ep.flag_kk

		left join Temp_PTS_Test_det_NU_prov_rates d
		on a.bucket_360 = d.bucket
		--and a.NU_segment = d.NU_segment
		----13.04.2022 Послабление 10 % для пдн > 50% с апреля 2022
		and case 
		when a.mob_date_to < '2022-04-30' and a.NU_segment like 'P1%' then replace(a.NU_segment,'P1','P')
		when a.mob_date_to < '2022-04-30' and a.NU_segment like 'P2%' then replace(a.NU_segment,'P2','P')
		when a.mob_date_to >= '2022-04-30' and a.NU_segment like 'P1%' then replace(a.NU_segment,'P1','NP')
		when a.mob_date_to >= '2022-04-30' and a.NU_segment like 'P2%' then replace(a.NU_segment,'P2','NP')
		when a.NU_segment like 'BANKRUPT%' then 'BANKRUPT'
		else a.NU_segment end = d.NU_segment

		left join Temp_PTS_Test_analyt_prov_NU_rates e
		on a.bucket_360 = e.bucket
		--and a.NU_segment = e.NU_segment
		----13.04.2022 Послабление 10 % для пдн > 50% с апреля 2022
		--and case 
		--when a.mob_date_to < '2022-04-30' and a.NU_segment like 'P1%' then replace(a.NU_segment,'P1','P')
		--when a.mob_date_to < '2022-04-30' and a.NU_segment like 'P2%' then replace(a.NU_segment,'P2','P')
		--when a.mob_date_to >= '2022-04-30' and a.NU_segment like 'P1%' then replace(a.NU_segment,'P1','NP')
		--when a.mob_date_to >= '2022-04-30' and a.NU_segment like 'P2%' then replace(a.NU_segment,'P2','NP')
		--else a.NU_segment end = e.NU_segment
		and a.NU_segment = e.NU_segment

		left join Temp_PTS_Test_det_NU_prov_rates_PDL nupdl --с октября 2024 по кредитам со ставкой от 250% применяются коэф-ты PDL
		on a.bucket_90 = nupdl.dpd_bucket_90
		and a.flag_kk = 'INSTALLMENT'
		and a.mob_date_to >= '2024-10-01'
		and a.term in (3,6)

		left join Temp_PTS_Test_det_pieces_L1 d1
		on a.bucket_360 = d1.bucket_360_m

		left join Temp_PTS_Test_det_pieces_L2 d2
		on a.bucket_360 = d2.bucket_360_m
		and iif(a.segment_rbp = 'RBP 1','RBP 1','rest') = d2.segment_rbp_2

		--3.10.2022
		left join Temp_PTS_Test_virt_IFRS_rates_0_90 ifrs1
		on a.bucket_360 = ifrs1.dpd_bucket
		and iif(a.flag_kk = 'INSTALLMENT', 'INSTALLMENT', 'PTS') = ifrs1.product

		left join Temp_PTS_Test_virt_IFRS_rates_91_plus ifrs2
		on a.months_in_default = ifrs2.months_in_default
		and iif(a.flag_kk = 'INSTALLMENT', 'INSTALLMENT', 'PTS') = ifrs2.product

		--23.11.2023
		left join Temp_PTS_Test_det_BU_IL_DEC23_0_90 buil090
		on a.bucket_90 = buil090.dpd_bucket_90
		left join Temp_PTS_Test_det_BU_IL_DEC23_LGD buillgd
		on a.months_in_default = buillgd.mod_n

		--27.12.2023
		left join Temp_PTS_Test_virt_BU_PTS_2024_rates bu24
		on a.mob_date_to between bu24.dt_from and bu24.dt_to
		and a.bucket_90 = bu24.bucket
		and isnull(a.months_in_default,0) = isnull(bu24.mod_num,0)

		left join Temp_PTS_Test_BU_rates_BUSINESS bus_bu
		on a.flag_kk = 'BUSINESS'
		and a.dpd_bucket = bus_bu.dpd_bucket

		where a.NU_segment is not null
		and a.mob_date_to between @dt_back_test_from and @for_finance_dt_to

		group by a.mob_date_to, 
		a.term,
		a.segment_rbp,
		a.flag_kk,
		a.generation,
		--a.bucket_720
		a.dpd_bucket,
		a.NU_segment

	), fact as (
		select a.r_date as mob_date_to, 	
		b.term,
		b.segment_rbp,
		iif(z.external_id is not null, 'FREEZE', b.flag_kk) as flag_kk,
		b.generation,
	
		--RiskDWH.dbo.get_bucket_720(a.dpd) as bucket_720,
		RiskDWH.dbo.get_bucket_360(a.dpd) as dpd_bucket,
		--RiskDWH.dbo.get_bucket_360_m(a.dpd) as bucket_360m,
		d.NU_segment,
		sum(isnull(a.due_od,0)) as portf,
		sum(isnull(a.prov_od,0)) as provisions_od,
		sum(isnull(a.prov_od_NU,0)) as provisions_od_NU,

		sum(isnull(a.due_int,0)) as interest,
		sum(isnull(a.prov_int,0)) as provisions_int,
		sum(isnull(a.prov_int_NU,0)) as provisions_int_NU,
		sum(case when a.due_od + a.due_int + a.due_fee > 0 then 1 else 0 end) as pieces,

		sum(isnull(a.IFRS9_od,0)) as IFRS9_od,
		sum(isnull(a.IFRS9_int,0)) as IFRS9_int

		from Temp_PTS_Test_umfo_fact a
		inner join Temp_PTS_Test_cred_reestr b
		on a.external_id = b.external_id
		--where a.cli_type = 'ФЛ'
		inner join Temp_PTS_Test_UMFO_NU_segment d
		on a.external_id = d.external_id
		and a.r_date = d.r_date
		left join Temp_PTS_Test_zamorozka z
		on a.external_id = z.external_id
		and a.r_date between z.freeze_from and z.freeze_to
		where a.r_date between '2018-12-31' and @rdt
		group by a.r_date, 
		b.term,
		b.segment_rbp,
		iif(z.external_id is not null, 'FREEZE', b.flag_kk),
		b.generation,
		RiskDWH.dbo.get_bucket_360(a.dpd),
		d.NU_segment
	)
	select 
	isnull(a.mob_date_to, b.mob_date_to) as mob_date_to,
	isnull(a.term,		  b.term) as term,
	isnull(a.segment_rbp, b.segment_rbp) as segment_rbp,
	isnull(a.flag_kk,	  b.flag_kk) as flag_kk,
	isnull(a.generation,  b.generation) as generation,
	isnull(a.dpd_bucket,  b.dpd_bucket) as dpd_bucket,
	isnull(a.NU_segment, b.NU_segment) as NU_segment,

	b.portf as fact_od, 
	b.provisions_od as fact_prov_od,
	b.provisions_od_NU as fact_prov_NU_od,
	b.IFRS9_od as fact_prov_IFRS_od,

	b.interest as fact_int, 
	b.provisions_int as fact_prov_int, 
	b.provisions_int_NU as fact_prov_NU_int,
	b.IFRS9_int as fact_prov_IFRS_int,

	b.pieces as fact_pieces,

	a.portf as model_od, 
	a.provisions_od as model_prov_od,
	a.provisions_od_alt as model_prov_od_alt,
	a.provisions_od_IFRS as model_prov_od_IFRS9, 
	a.provisions_od_NU as model_prov_NU_od,

	a.interest as model_int, 
	a.provisions_int as model_prov_int,
	a.provisions_int_alt as model_prov_int_alt,
	a.provisions_int_IFRS as model_prov_int_IFRS9,
	a.provisions_int_NU as model_prov_NU_int,

	a.pieces as model_pieces

	into Temp_PTS_Test_for_finance

	from model a
	full join fact b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk
	and a.generation = b.generation
	and a.dpd_bucket = b.dpd_bucket
	and a.mob_date_to = b.mob_date_to
	and a.NU_segment = b.NU_segment

	where isnull(a.mob_date_to, b.mob_date_to) between '2018-12-31' and @for_finance_dt_to
	;


	print ('timing, Temp_PTS_Test_for_finance ' + format(getdate(), 'HH:mm:ss'));








	--Cash 90+ по сегментам и бакетам по 30 до 360
	drop table if exists Temp_PTS_Test_pmt_base;

	with t1 as (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, 
		eomonth(a.mob_date_to, -1*a.mod_num) as default_dt,
		eomonth(a.mob_date_to, -1*a.last_MOD) as default_dt2,
	
		a.calc_od_payoff - lag(a.calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, 
		eomonth(a.mob_date_to, -1*a.mod_num), eomonth(a.mob_date_to, -1*a.last_MOD) order by a.mob_date_to) as od_pmt,
		cast(0 as float) as int_pmt,
		a.fee_calc_od_payoff - lag(a.fee_calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, 
		eomonth(a.mob_date_to, -1*a.mod_num), eomonth(a.mob_date_to, -1*a.last_MOD) order by a.mob_date_to) as fee_pmt,
		a.straf_calc_od_payoff - lag(a.straf_calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, 
		eomonth(a.mob_date_to, -1*a.mod_num), eomonth(a.mob_date_to, -1*a.last_MOD) order by a.mob_date_to) as straf_pmt,
		a.wo_calc_od_payoff - lag(a.wo_calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, 
		eomonth(a.mob_date_to, -1*a.mod_num), eomonth(a.mob_date_to, -1*a.last_MOD) order by a.mob_date_to) as od_wo,
		cast(0 as float) as int_wo

		from Temp_PTS_Test_stg1_default_recovery_fact a
		where a.mob_date_to between @dt_back_test_from and @for_finance_dt_to
	), t2 as (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, 
		eomonth(a.mob_date_to, -1*a.mod_num) as default_dt,
		eomonth(a.mob_date_to, -1*a.last_MOD) as default_dt2,
	
		a.calc_od_payoff - lag(a.calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, a.freeze_from, 
		eomonth(a.mob_date_to, -1*isnull(a.mod_num,-999)), eomonth(a.mob_date_to, -1*isnull(a.last_MOD,-999)) order by a.mob_date_to) as od_pmt,
		cast(0 as float) as int_pmt,
		a.fee_calc_od_payoff - lag(a.fee_calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, a.freeze_from,
		eomonth(a.mob_date_to, -1*isnull(a.mod_num,-999)), eomonth(a.mob_date_to, -1*isnull(a.last_MOD,-999)) order by a.mob_date_to) as fee_pmt,
		a.straf_calc_od_payoff - lag(a.straf_calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, a.freeze_from,
		eomonth(a.mob_date_to, -1*isnull(a.mod_num,-999)), eomonth(a.mob_date_to, -1*isnull(a.last_MOD,-999)) order by a.mob_date_to) as straf_pmt,	
		a.wo_calc_od_payoff - lag(a.wo_calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, a.freeze_from,
		eomonth(a.mob_date_to, -1*isnull(a.mod_num,-999)), eomonth(a.mob_date_to, -1*isnull(a.last_MOD,-999)) order by a.mob_date_to) as od_wo,
		cast(0 as float) as int_wo
		from Temp_PTS_Test_stg3_default_recovery_model a
		where a.mob_date_to between @dt_back_test_from and @for_finance_dt_to
	), t3 as (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, 
		eomonth(a.mob_date_to, -1*a.mod_num) as default_dt,
		eomonth(a.mob_date_to, -1*a.last_MOD) as default_dt2,
		cast(0 as float) as od_pmt,
		sum(isnull(a.int_recov,0)) as int_pmt,
		cast(0 as float) as fee_pmt,
		cast(0 as float) as straf_pmt,
		cast(0 as float) as od_wo,
		sum(isnull(a.int_wo,0)) as int_wo
		from Temp_PTS_Test_stg_int_rec_wo a
		where a.mob_date_to between @dt_back_test_from and @for_finance_dt_to
		and left(a.flag_kk,2) <> 'KK'
		group by a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, 
		eomonth(a.mob_date_to, -1*a.mod_num),
		eomonth(a.mob_date_to, -1*a.last_MOD)
	), t4 as (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, 
		eomonth(a.mob_date_to, -1*a.mod_num) as default_dt,
		eomonth(a.mob_date_to, -1*a.last_MOD) as default_dt2,
		cast(0 as float) as od_pmt,
		sum(isnull(a.int_recov,0)) as int_pmt,
		cast(0 as float) as fee_pmt,
		cast(0 as float) as straf_pmt,
		cast(0 as float) as od_wo,
		sum(isnull(a.int_wo,0)) as int_wo
		from Temp_PTS_Test_stg2_int_rec_wo a	
		where a.mob_date_to between @dt_back_test_from and @for_finance_dt_to
		and left(a.flag_kk,2) = 'KK' 
		group by a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, 
		eomonth(a.mob_date_to, -1*a.mod_num),
		eomonth(a.mob_date_to, -1*a.last_MOD)
	), u as (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, 
		RiskDWH.dbo.get_bucket_360(91 + (a.last_MOD - 1) * 30) as dpd_bucket,
		RiskDWH.dbo.get_bucket_90(91 + a.last_MOD * 30) as bucket_90,
		sum(a.od_pmt) as od_pmt,
		sum(a.int_pmt) as int_pmt,
		sum(a.fee_pmt) as fee_pmt,
		sum(a.straf_pmt) as straf_pmt,
		sum(a.od_wo) as od_wo,
		sum(a.int_wo) as int_wo
		from (select * from t1 
			union all select * from t2 
			union all select * from t3 
			union all select * from t4) a
		where a.last_MOD <> 0
		group by a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, 
		RiskDWH.dbo.get_bucket_360(91 + (a.last_MOD - 1) * 30), 
		RiskDWH.dbo.get_bucket_90(91 + a.last_MOD * 30)
	union all	
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, 
		a.bucket_90_to as dpd_bucket,  
		a.bucket_90_to as bucket_90, 	
		a.model_od_pmt as od_pmt, 
		a.model_int_pmt as int_pmt,
		cast(0 as float) as fee_pmt,
		cast(0 as float) as straf_pmt,
		cast(0 as float) as od_wo,
		cast(0 as float) as int_wo
		from Temp_PTS_Test_final_model a
		where a.mob_date_to between @dt_back_test_from and @for_finance_dt_to
		and a.bucket_90_to in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90')

	)
	--select u.mob_date_to, sum(u.od_pmt + u.int_pmt + u.fee_pmt + u.straf_pmt) from u group by u.mob_date_to order by 1 --проверка общей суммы по датам
	--select distinct u.bucket_90, u.dpd_bucket from u where u.mob_date_to = '2022-12-31' order by 1,2

	select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, 
	a.dpd_bucket,
	a.bucket_90,
	b.NU_segment,
	a.od_pmt * b.share as od_pmt,
	a.int_pmt * b.share as int_pmt,
	a.fee_pmt * b.share as fee_pmt,
	a.straf_pmt * b.share as straf_pmt,
	a.od_wo * b.share as od_wo,
	a.int_wo * b.share as int_wo

	into Temp_PTS_Test_pmt_base

	from u as a
	inner join Temp_PTS_Test_NU_segment_distrib b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.generation = b.generation
	and a.flag_kk = b.flag_kk
	and a.bucket_90 = b.bucket_90_to
	where a.generation < @dt_back_test_from 
	--and b.NU_segment is null and a.od_pmt + a.int_pmt + a.fee_pmt + a.straf_pmt > 0 --ok

	--13.04.2022 новый портфель
	union all

	select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, 
	a.dpd_bucket,
	a.bucket_90,
	b.pdn_group as NU_segment,
	a.od_pmt *	isnull(b.frac,0) as od_pmt,
	a.int_pmt *	isnull(b.frac,0) as int_pmt,
	a.fee_pmt *	isnull(b.frac,0) as fee_pmt,
	a.straf_pmt * isnull(b.frac,0) as straf_pmt,
	a.od_wo * isnull(b.frac,0) as od_wo,
	a.int_wo * isnull(b.frac,0) as int_wo

	from u as a
	left join Temp_PTS_Test_pdn_distrib b
	on a.segment_rbp = b.segment_rbp
	where a.generation >= @dt_back_test_from 
	and a.flag_kk <> 'BUSINESS'

	--13.04.2022 Бизнес-займы
	union all

	select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, 
	a.dpd_bucket,
	a.bucket_90,
	cast('UL' as varchar(100)) as NU_segment,
	a.od_pmt,
	a.int_pmt,
	a.fee_pmt,
	a.straf_pmt,
	a.od_wo,
	a.int_wo

	from u as a
	where a.generation >= @dt_back_test_from
	and a.flag_kk = 'BUSINESS'

	;


	print ('timing, Temp_PTS_Test_pmt_base (model) ' + format(getdate(), 'HH:mm:ss'));



	---+FACT


	with pmt_and_writeoff as (
		select a.external_id, a.cdate, 
		sum(a.principal_cnl) as principal_cnl, 
		sum(a.percents_cnl) as percents_cnl, 
		sum(a.fines_cnl) as fines_cnl, 
		sum(a.other_cnl) as other_cnl,
		sum(a.od_wo) as od_wo,
		sum(a.int_wo) as int_wo
		from (
			select a.external_id, a.cdate, 
			a.principal_cnl, 
			a.percents_cnl, 
			a.fines_cnl, 
			a.other_cnl, 
			cast(0 as float) as od_wo, 
			cast(0 as float) as int_wo
			from Temp_PTS_Test_stg_payment a
			where not exists (select 1 from RiskDWH.risk.stg_fcst_bus_bal b where a.external_id = b.external_id
				and b.zaim in (select zaim from riskdwh.risk.stg_fcst_handle_bus_cred))
		union all
			select a.external_id, a.r_date as cdate,
			cast(0 as float) as principal_cnl, 
			cast(0 as float) as percents_cnl, 
			cast(0 as float) as fines_cnl, 
			cast(0 as float) as other_cnl, 
			a.od_wo, 
			a.int_wo
			from RiskDWH.risk.stg_fcst_writeoff a
		) a
		group by a.external_id, a.cdate
	)
	insert into Temp_PTS_Test_pmt_base

	select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to,
	RiskDWH.dbo.get_bucket_360(a.dpd_from) as dpd_bucket,
	RiskDWH.dbo.get_bucket_90(a.dpd_from) as bucket_90,
	c.NU_segment,
	sum(isnull(b.principal_cnl,0)) as od_pmt,
	sum(isnull(b.percents_cnl,0)) as int_pmt,
	sum(isnull(b.fines_cnl,0)) as fee_pmt,
	sum(isnull(b.other_cnl,0)) as straf_pmt,
	sum(isnull(b.od_wo,0)) as od_wo,
	sum(isnull(b.int_wo,0)) as int_wo


	from Temp_PTS_Test_stg_matrix_detail a
	inner join pmt_and_writeoff b
	on a.external_id = b.external_id 
	and a.mob_date_to = eomonth(b.cdate)
	inner join Temp_PTS_Test_UMFO_NU_segment c
	on a.external_id = c.external_id
	and a.mob_date_to = c.r_date
	where a.mob_date_to between '2018-12-31' and @rdt
	group by a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to,
	RiskDWH.dbo.get_bucket_360(a.dpd_from),
	RiskDWH.dbo.get_bucket_90(a.dpd_from),
	c.NU_segment

	;



	---+FACT 0 MoB



	with pmt_and_writeoff as (
		select a.external_id, a.cdate, 
		sum(a.principal_cnl) as principal_cnl, 
		sum(a.percents_cnl) as percents_cnl, 
		sum(a.fines_cnl) as fines_cnl, 
		sum(a.other_cnl) as other_cnl,
		sum(a.od_wo) as od_wo,
		sum(a.int_wo) as int_wo
		from (
			select a.external_id, a.cdate, 
			a.principal_cnl, 
			a.percents_cnl, 
			a.fines_cnl, 
			a.other_cnl, 
			cast(0 as float) as od_wo, 
			cast(0 as float) as int_wo
			from Temp_PTS_Test_stg_payment a
			where not exists (select 1 from RiskDWH.risk.stg_fcst_bus_bal b where a.external_id = b.external_id
				and b.zaim in (select zaim from riskdwh.risk.stg_fcst_handle_bus_cred))
		union all
			select a.external_id, a.r_date as cdate,
			cast(0 as float) as principal_cnl, 
			cast(0 as float) as percents_cnl, 
			cast(0 as float) as fines_cnl, 
			cast(0 as float) as other_cnl, 
			a.od_wo, 
			a.int_wo
			from RiskDWH.risk.stg_fcst_writeoff a
		) a
		group by a.external_id, a.cdate
	)
	insert into Temp_PTS_Test_pmt_base

	select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_from as mob_date_to,
	RiskDWH.dbo.get_bucket_360(a.dpd_from) as dpd_bucket,
	RiskDWH.dbo.get_bucket_90(a.dpd_from) as bucket_90,
	c.NU_segment,
	sum(isnull(b.principal_cnl,0)) as od_pmt,
	sum(isnull(b.percents_cnl,0)) as int_pmt,
	sum(isnull(b.fines_cnl,0)) as fee_pmt,
	sum(isnull(b.other_cnl,0)) as straf_pmt,
	sum(isnull(b.od_wo,0)) as od_wo,
	sum(isnull(b.int_wo,0)) as int_wo


	from Temp_PTS_Test_stg_matrix_detail a
	inner join pmt_and_writeoff b
	on a.external_id = b.external_id 
	and a.mob_date_from = eomonth(b.cdate)
	inner join Temp_PTS_Test_UMFO_NU_segment c
	on a.external_id = c.external_id
	and a.mob_date_from = c.r_date
	where a.mob_date_from between '2018-12-31' and @rdt
	and a.mob_from = 0
	group by a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_from,
	RiskDWH.dbo.get_bucket_360(a.dpd_from),
	RiskDWH.dbo.get_bucket_90(a.dpd_from),
	c.NU_segment
	;


	with pmt_and_writeoff as (
		select a.external_id, a.cdate, 
		sum(a.principal_cnl) as principal_cnl, 
		sum(a.percents_cnl) as percents_cnl, 
		sum(a.fines_cnl) as fines_cnl, 
		sum(a.other_cnl) as other_cnl,
		sum(a.od_wo) as od_wo,
		sum(a.int_wo) as int_wo
		from (
			select a.external_id, a.cdate, 
			a.principal_cnl, 
			a.percents_cnl, 
			a.fines_cnl, 
			a.other_cnl, 
			cast(0 as float) as od_wo, 
			cast(0 as float) as int_wo
			from Temp_PTS_Test_stg_payment a
		union all
			select a.external_id, a.r_date as cdate,
			cast(0 as float) as principal_cnl, 
			cast(0 as float) as percents_cnl, 
			cast(0 as float) as fines_cnl, 
			cast(0 as float) as other_cnl, 
			a.od_wo, 
			a.int_wo
			from RiskDWH.risk.stg_fcst_writeoff a
		) a
		group by a.external_id, a.cdate
	)
	merge into Temp_PTS_Test_pmt_base dst

	using (
	select a.term, a.generation, a.segment_rbp, a.flag_kk, a.generation as mob_date_to,
	'[01] 0' as dpd_bucket,
	'[01] 0' as bucket_90,
	c.NU_segment,
	sum(isnull(b.principal_cnl,0)) as od_pmt,
	sum(isnull(b.percents_cnl,0)) as int_pmt,
	sum(isnull(b.fines_cnl,0)) as fee_pmt,
	sum(isnull(b.other_cnl,0)) as straf_pmt,
	sum(isnull(b.od_wo,0)) as od_wo,
	sum(isnull(b.int_wo,0)) as int_wo


	from Temp_PTS_Test_cred_reestr a
	inner join pmt_and_writeoff b
	on a.external_id = b.external_id 
	and a.generation = eomonth(b.cdate)
	inner join Temp_PTS_Test_UMFO_NU_segment c
	on a.external_id = c.external_id
	and a.generation = c.r_date
	where a.generation = @rdt or 
	(not exists (select 1 from Temp_PTS_Test_stg_matrix_detail md where a.external_id = md.external_id) and a.flag_closed_in_month = 1)
	group by a.term, a.generation, a.segment_rbp, a.flag_kk,
	c.NU_segment
	) src
	on (dst.term = src.term and dst.generation = src.generation and dst.segment_rbp = src.segment_rbp and dst.flag_kk = src.flag_kk
	and dst.mob_date_to = src.mob_date_to and dst.dpd_bucket = src.dpd_bucket and dst.bucket_90 = src.bucket_90 and dst.NU_segment = src.NU_segment)
	when matched then update set 
	dst.od_pmt = dst.od_pmt + src.od_pmt,
	dst.int_pmt = dst.int_pmt + src.int_pmt,
	dst.fee_pmt = dst.fee_pmt + src.fee_pmt,
	dst.straf_pmt = dst.straf_pmt + src.straf_pmt,
	dst.od_wo = dst.od_wo + src.od_wo,
	dst.int_wo = dst.int_wo + src.int_wo
	when not matched then insert 
	(term, generation, segment_rbp, flag_kk, mob_date_to,
	dpd_bucket,bucket_90,NU_segment,
	od_pmt,int_pmt,fee_pmt,straf_pmt,od_wo,int_wo)
	values
	(src.term, src.generation, src.segment_rbp, src.flag_kk, src.mob_date_to,
	src.dpd_bucket,src.bucket_90,src.NU_segment,
	src.od_pmt,src.int_pmt,src.fee_pmt,src.straf_pmt,src.od_wo,src.int_wo)

	;




	print ('timing, Temp_PTS_Test_pmt_base (fact) ' + format(getdate(), 'HH:mm:ss'));



	/*


	select a.rep_dt, a.model_dt_from, a.dt_dml, a.vers, count(*)
	from RiskDWH.Risk.forecast_for_finance_3 a
	group by a.rep_dt, a.model_dt_from, a.dt_dml, a.vers
	order by 4,1,2,3;


	select max(a.vers) from RiskDWH.Risk.forecast_for_finance_3 a


	*/



	--declare @rdt date = '2024-10-31';declare @dt_back_test_from date = '2024-11-30';declare @vers int = 332;declare @for_finance_dt_to date = '2030-12-31';


	delete from risk.forecast_for_finance_3 where vers = @vers;


	insert into risk.forecast_for_finance_3 

	select 

		@rdt as rep_dt,
		@dt_back_test_from as model_dt_from,
		@vers as vers,
		cast(getdate() as datetime) as dt_dml,

		--группировки
		isnull(a.mob_date_to,b.mob_date_to) as r_date, 
		isnull(a.segment_rbp, b.segment_rbp) as segment_rbp,

		case
		when isnull(a.flag_kk,b.flag_kk) = 'Installment' then 'Installment'
		when isnull(a.flag_kk,b.flag_kk) = 'BUSINESS' then 'Бизнес-займы'
		else 'ПТС' 
		end as product,

		case 
		when isnull(a.flag_kk,b.flag_kk) = 'Installment' then 'other'
		when isnull(a.flag_kk,b.flag_kk) = 'BUSINESS' then 'other'
		when isnull(a.flag_kk,b.flag_kk) like 'CESS%' then 'К продаже'
		when isnull(a.flag_kk,b.flag_kk) in ('KK','FREEZE') then 'КК'
		when left(isnull(a.flag_kk,b.flag_kk),2) = 'KK' then 'KK'
		when left(isnull(a.flag_kk,b.flag_kk),11) = 'STOP_CHARGE' and isnull(a.segment_rbp, b.segment_rbp) = 'PTS31' then 'other'
		when isnull(a.flag_kk,b.flag_kk) = 'BANKRUPT' then 'Банкроты'
		else 'other'
		end as subportf,

		case 
		when isnull(a.NU_segment,b.NU_segment) like 'P1%' then '50% <= ПДН < 80%'
		when isnull(a.NU_segment,b.NU_segment) like 'P2%' then 'ПДН >= 80%'
		--26.09.2022
		when isnull(a.NU_segment,b.NU_segment) = 'BANKRUPT_P1' then '50% <= ПДН < 80%'
		when isnull(a.NU_segment,b.NU_segment) = 'BANKRUPT_P2' then 'ПДН >= 80%'
		else 'ПДН < 50% или нет'
		end as pdn_group,

		case 
		when isnull(a.generation,b.generation) <= '2022-02-28' then 'по февр 2022'
		when isnull(a.generation,b.generation) between '2022-03-31' and '2022-09-30' then 'март 2022 - сент 2022'
		else 'с окт 2022'
		end as capit_gen,

		isnull(a.dpd_bucket,b.dpd_bucket) as dpd_bucket,

		case 
		when isnull(a.generation,b.generation) < '2020-01-01' then '2016-2019'
		else cast(year(isnull(a.generation,b.generation)) as varchar)
		end as gen_year,

		case when isnull(a.generation,b.generation) >= @dt_back_test_from then 'новый' else 'текущий' end as new_portf,

		---агрегаты
		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then a.fact_od else a.model_od end) as od,
		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then a.fact_int else a.model_int end) as interest,
		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then a.fact_prov_od else a.model_prov_od end) as provision_od_BU,
		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then a.fact_prov_int else a.model_prov_int end) as provision_int_BU,
		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_prov_od,0) + isnull(a.fact_prov_int,0) 
			else isnull(a.model_prov_od,0) + isnull(a.model_prov_int,0) end) as provision_od_int_BU,
		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then a.fact_prov_NU_od else a.model_prov_NU_od end) as provision_od_NU,
		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then a.fact_prov_NU_int else a.model_prov_NU_int end) as provision_int_NU,
		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_prov_NU_od,0) + isnull(a.fact_prov_NU_int,0) 
			else isnull(a.model_prov_NU_od,0) + isnull(a.model_prov_NU_int,0) end) as provision_od_int_NU,

		sum(isnull(b.od_pmt,   0)) as od_pmt,
		sum(isnull(b.int_pmt,  0)) as int_pmt,
		sum(isnull(b.fee_pmt,  0)) as fee_pmt,
		sum(isnull(b.straf_pmt,0)) as straf_pmt,

		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then a.fact_pieces else a.model_pieces end) as pieces,

		sum(isnull(b.od_wo,0)) as od_writeoff,
		sum(isnull(b.int_wo,0)) as int_writeoff,

		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then a.fact_od else a.model_od end 
			* c.avg_month_int_rate * 12.0
		) as chisl_portf_int_rate,


		--3.10.2022 +2 методики БУ: новая и МСФО9
		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then a.fact_prov_od else a.model_prov_od_alt end) as provision_od_BU_alt,
		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then a.fact_prov_int else a.model_prov_int_alt end) as provision_int_BU_alt,
		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_prov_od,0) + isnull(a.fact_prov_int,0) 
			else isnull(a.model_prov_od_alt,0) + isnull(a.model_prov_int_alt,0) end) as provision_od_int_BU_alt,

		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then a.fact_prov_IFRS_od else a.model_prov_od_IFRS9 end) as provision_od_BU_IFRS9,
		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then a.fact_prov_IFRS_int else a.model_prov_int_IFRS9 end) as provision_int_BU_IFRS9,
		sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_prov_IFRS_od,0) + isnull(a.fact_prov_IFRS_int,0) 
			else isnull(a.model_prov_od_IFRS9,0) + isnull(a.model_prov_int_IFRS9,0) end) as provision_od_int_BU_IFRS9
		
		--select distinct flag_kk from Temp_PTS_Test_for_finance order by 1
		--select distinct flag_kk from Temp_PTS_Test_pmt_base order by 1
		--select distinct flag_kk from Temp_PTS_Test_stg_int_rates order by 1

	from Temp_PTS_Test_for_finance a
	full join Temp_PTS_Test_pmt_base b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk 
	and a.generation = b.generation
	and a.dpd_bucket = b.dpd_bucket
	and a.NU_segment = b.NU_segment
	and a.mob_date_to = b.mob_date_to

	left join Temp_PTS_Test_stg_int_rates c
	on isnull(a.term,b.term) = c.term
	and isnull(a.segment_rbp,b.segment_rbp) = c.segment_rbp
	and isnull(a.generation,b.generation) = c.generation
	and iif(isnull(a.flag_kk,b.flag_kk)='FREEZE','KK',isnull(a.flag_kk,b.flag_kk)) = c.flag_kk

	where isnull(a.mob_date_to,b.mob_date_to) <= @for_finance_dt_to

	group by 
		isnull(a.mob_date_to,b.mob_date_to),
		isnull(a.segment_rbp, b.segment_rbp),

		case
		when isnull(a.flag_kk,b.flag_kk) = 'Installment' then 'Installment'
		when isnull(a.flag_kk,b.flag_kk) = 'BUSINESS' then 'Бизнес-займы'
		else 'ПТС' 
		end,

		case 
		when isnull(a.flag_kk,b.flag_kk) = 'Installment' then 'other'
		when isnull(a.flag_kk,b.flag_kk) = 'BUSINESS' then 'other'
		when isnull(a.flag_kk,b.flag_kk) like 'CESS%' then 'К продаже'
		when isnull(a.flag_kk,b.flag_kk) in ('KK','FREEZE') then 'КК'
		when left(isnull(a.flag_kk,b.flag_kk),2) = 'KK' then 'KK'
		when left(isnull(a.flag_kk,b.flag_kk),11) = 'STOP_CHARGE' and isnull(a.segment_rbp, b.segment_rbp) = 'PTS31' then 'other'
		when isnull(a.flag_kk,b.flag_kk) = 'BANKRUPT' then 'Банкроты'
		else 'other'
		end,

		case 

		when isnull(a.NU_segment,b.NU_segment) like 'P1%' then '50% <= ПДН < 80%'
		when isnull(a.NU_segment,b.NU_segment) like 'P2%' then 'ПДН >= 80%'
		--26.09.2022
		when isnull(a.NU_segment,b.NU_segment) = 'BANKRUPT_P1' then '50% <= ПДН < 80%'
		when isnull(a.NU_segment,b.NU_segment) = 'BANKRUPT_P2' then 'ПДН >= 80%'
		else 'ПДН < 50% или нет'
		end,

		case 
		when isnull(a.generation,b.generation) <= '2022-02-28' then 'по февр 2022'
		when isnull(a.generation,b.generation) between '2022-03-31' and '2022-09-30' then 'март 2022 - сент 2022'
		else 'с окт 2022'
		end,
		isnull(a.dpd_bucket,b.dpd_bucket),
		case 
		when isnull(a.generation,b.generation) < '2020-01-01' then '2016-2019'
		else cast(year(isnull(a.generation,b.generation)) as varchar)
		end,
		case when isnull(a.generation,b.generation) >= @dt_back_test_from then 'новый' else 'текущий' end
	;




	--применяем новую методику БУ для ПТС и Бизнес-займов

	update a set
	a.provision_od_BU = a.provision_od_BU_alt,
	a.provision_int_BU = a.provision_int_BU_alt,
	a.provision_od_int_BU = a.provision_od_int_BU_alt
	from risk.forecast_for_finance_3 a
	where a.vers = @vers
	and a.r_date >= @dt_back_test_from
	and a.product <> 'Installment'
	;

	--перекидываем списания в кэш
	update a set 
	a.od_pmt = case 
	--when a.r_date between '2024-04-30' and '2024-12-31' then a.od_pmt + a.od_writeoff * (1.0 - 0.75)
	--when a.r_date = '2025-01-31' then a.od_pmt + a.od_writeoff *  (1.0 - 0.75)
	--when a.r_date = '2025-02-28' then a.od_pmt + a.od_writeoff *  (1.0 - 0.75)
	--when a.r_date = '2025-03-31' then a.od_pmt + a.od_writeoff *  (1.0 - 0.75)
	--when a.r_date = '2025-04-30' then a.od_pmt + a.od_writeoff *  (1.0 - 0.75)
	when a.r_date >= eomonth(@rdt, 1) then a.od_pmt + a.od_writeoff * (1.0 - 0.75)

	else a.od_pmt end,	

	a.int_pmt = case
	--when a.r_date between '2024-04-30' and '2024-12-31' then a.int_pmt + a.int_writeoff * (1.0 - 0.75)
	--when a.r_date = '2025-01-31' then a.int_pmt + a.int_writeoff *  (1.0 - 0.75)
	--when a.r_date = '2025-02-28' then a.int_pmt + a.int_writeoff *  (1.0 - 0.75)
	--when a.r_date = '2025-03-31' then a.int_pmt + a.int_writeoff *  (1.0 - 0.75)
	--when a.r_date = '2025-04-30' then a.int_pmt + a.int_writeoff *  (1.0 - 0.75)
	when a.r_date >= eomonth(@rdt, 1) then a.int_pmt + a.int_writeoff * (1.0 - 0.75)
	else a.int_pmt end,

	a.od_writeoff = case 
	--when a.r_date between '2024-04-30' and '2024-12-31' then a.od_writeoff * 0.75
	--when a.r_date = '2025-01-31' then a.od_writeoff *  0.75
	--when a.r_date = '2025-02-28' then a.od_writeoff *  0.75
	--when a.r_date = '2025-03-31' then a.od_writeoff *  0.75
	--when a.r_date = '2025-04-30' then a.od_writeoff *  0.75
	when a.r_date >= eomonth(@rdt, 1) then a.od_writeoff * 0.75
	else a.od_writeoff end,
		
	a.int_writeoff = case 
	--when a.r_date between '2024-04-30' and '2024-12-31' then a.int_writeoff * 0.75
	--when a.r_date = '2025-01-31' then a.int_writeoff *  0.75
	--when a.r_date = '2025-02-28' then a.int_writeoff *  0.75
	--when a.r_date = '2025-03-31' then a.int_writeoff *  0.75
	--when a.r_date = '2025-04-30' then a.int_writeoff *  0.75
	when a.r_date >= eomonth(@rdt, 1) then a.int_writeoff * 0.75
	else a.int_writeoff end
	from risk.forecast_for_finance_3 a
	where a.r_date between '2024-01-31' and '2030-12-31'
	and a.vers = @vers
	and a.product = 'ПТС'
	and a.r_date >= @dt_back_test_from
	;






	------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- FIX для INSTALLMENT - цессии
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------


	----обнуляем все остатки с мая 2024
	--update a set 
	--a.od = 0,
	--a.interest = 0,
	--a.provision_od_BU = 0,
	--a.provision_int_BU = 0,
	--a.provision_od_int_BU = 0,
	--a.provision_od_NU = 0,
	--a.provision_int_NU = 0,
	--a.provision_od_int_NU = 0,
	--a.od_pmt = 0,
	--a.int_pmt = 0,
	--a.fee_pmt = 0,
	--a.straf_pmt = 0,
	--a.pieces = 0,
	--a.od_writeoff = 0,
	--a.int_writeoff = 0,
	--a.chisl_portf_int_rate = 0,
	--a.provision_od_BU_alt = 0,
	--a.provision_int_BU_alt = 0,
	--a.provision_od_int_BU_alt = 0,
	--a.provision_od_BU_IFRS9 = 0,
	--a.provision_int_BU_IFRS9 = 0,
	--a.provision_od_int_BU_IFRS9 = 0
	----select * 
	--from risk.forecast_for_finance_3 a
	--where a.vers = @vers
	--and a.product = 'INSTALLMENT'
	--and a.r_date >= '2024-05-31'
	--;



	--update a set
	--a.od = 0,
	--a.interest = 0,
	--a.provision_od_BU = 0,
	--a.provision_int_BU = 0,
	--a.provision_od_int_BU = 0,
	--a.provision_od_NU = 0,
	--a.provision_int_NU = 0,
	--a.provision_od_int_NU = 0,

	--a.od_pmt = b.od - b.provision_od_BU_alt,
	--a.int_pmt = b.interest - b.provision_int_BU_alt,
	--a.fee_pmt = 0,
	--a.straf_pmt = 0,

	--a.pieces = 0,

	--a.od_writeoff = b.provision_od_BU_alt,
	--a.int_writeoff = b.provision_int_BU_alt,

	--a.chisl_portf_int_rate = 0,
	--a.provision_od_BU_alt = 0,
	--a.provision_int_BU_alt = 0,
	--a.provision_od_int_BU_alt = 0,
	--a.provision_od_BU_IFRS9 = 0,
	--a.provision_int_BU_IFRS9 = 0,
	--a.provision_od_int_BU_IFRS9 = 0
	----select * 
	--from risk.forecast_for_finance_3 a
	--left join risk.forecast_for_finance_3 b
	--on a.vers = b.vers
	--and b.r_date = '2024-03-31'
	--and a.segment_rbp = b.segment_rbp
	--and a.product = b.product
	--and a.subportf = b.subportf
	--and a.pdn_group = b.pdn_group
	--and a.capit_gen = b.capit_gen
	--and a.dpd_bucket = b.dpd_bucket
	--and a.gen_year = b.gen_year
	--and a.new_portf = b.new_portf
	--where a.vers = @vers
	--and a.product = 'INSTALLMENT'
	--and a.r_date = '2024-04-30'
	--;


	/*
	update a set a.provision_od_BU = a.provision_od_BU_alt,
	a.provision_int_BU = a.provision_int_BU_alt,
	a.provision_od_int_BU = a.provision_od_int_BU_alt
	--select * 
	from risk.forecast_for_finance_3 a
	where a.flag_kk = 'INSTALLMENT'
	and a.r_date >= '2024-01-01'
	and a.vers = @vers
	;
	*/








	print ('timing, risk.forecast_for_finance_3 ' + format(getdate(), 'HH:mm:ss'));




	--/* P 1-2 */
	----drop table Temp_PTS_Test_CMR_M;
	----drop table Temp_PTS_Test_cred_reestr;
	----drop table Temp_PTS_Test_det_current_params;
	----drop table Temp_PTS_Test_det_pieces_L1;
	----drop table Temp_PTS_Test_det_pieces_L2;
	----drop table Temp_PTS_Test_eps;
	----drop table Temp_PTS_Test_fact_due_int;
	----drop table Temp_PTS_Test_NU_segment_distrib;
	----drop table Temp_PTS_Test_rest_model;
	----drop table Temp_PTS_Test_stg_fact_od_int_pmt;
	----drop table Temp_PTS_Test_stg_freeze_mod;
	----drop table Temp_PTS_Test_stg_matrix_detail;
	----drop table Temp_PTS_Test_stg_payment;
	----drop table Temp_PTS_Test_stg_start_default;
	----drop table Temp_PTS_Test_stg_write_off;
	----drop table Temp_PTS_Test_stg1_NU_segment_distrib;
	----drop table Temp_PTS_Test_stg3_agg;
	----drop table Temp_PTS_Test_umfo_fact;
	----drop table Temp_PTS_Test_UMFO_NU_segment;
	----drop table Temp_PTS_Test_zamorozka;
	--/* P 3 */
	----drop table Temp_PTS_Test_det_pdp_coef;
	----drop table Temp_PTS_Test_det_stress;
	----drop table Temp_PTS_Test_fix_matrix;
	----drop table Temp_PTS_Test_for_back_test;
	----drop table Temp_PTS_Test_last_fact;
	----drop table Temp_PTS_Test_new_volume;
	----drop table Temp_PTS_Test_npl_wo_and_recovery;
	----drop table Temp_PTS_Test_stg_freeze_model;
	----drop table Temp_PTS_Test_stg1_default_recovery_fact;
	----drop table Temp_PTS_Test_stg3_default_recovery_model;
	----drop table Temp_PTS_Test_stg4_back_test_results;
	----drop table Temp_PTS_Test_virt_gens;
	--/* P 5 */
	--drop table Temp_PTS_Test_interest_model;
	----drop table Temp_PTS_Test_stg_int_rates;
	--drop table Temp_PTS_Test_stg_int_rec_wo;
	--drop table Temp_PTS_Test_stg2_int_rec_wo;
	--/* P 6-7 */
	----drop table Temp_PTS_Test_analyt_prov_NU_rates;
	--drop table Temp_PTS_Test_det_BU_prov_rates;
	--drop table Temp_PTS_Test_det_NU_prov_rates;
	--drop table Temp_PTS_Test_det_NU_prov_rates_PDL;
	----drop table Temp_PTS_Test_final_model;
	--drop table Temp_PTS_Test_pdn_distrib;
	----drop table Temp_PTS_Test_stg_eps_rates;
	--/* P 8 */
	----drop table Temp_PTS_Test_base;
	--drop table Temp_PTS_Test_det_BU_IL_DEC23_0_90;
	--drop table Temp_PTS_Test_det_BU_IL_DEC23_LGD;
	--drop table Temp_PTS_Test_det_BU_IL_DEC23_PD;
	--drop table Temp_PTS_Test_det_BU_IL_DEC23_REC;
	--drop table Temp_PTS_Test_det_LGD_IL;
	----drop table Temp_PTS_Test_for_finance;
	----drop table Temp_PTS_Test_pmt_base;
	--drop table Temp_PTS_Test_virt_BU_PTS_2024_rates;
	--drop table Temp_PTS_Test_virt_IFRS_rates_0_90;
	--drop table Temp_PTS_Test_virt_IFRS_rates_91_plus;



	---------------------------------------------------------------------------------------------------------------------------------------------------------
	-- Вспомогательные таблицы для быстрого пересчета некоторых компонентов, например, резервов
	---------------------------------------------------------------------------------------------------------------------------------------------------------

	--declare @rdt date = '2022-07-31'




	delete from risk.core_fcst_pmt_base where vers = @vers;
	insert into risk.core_fcst_pmt_base select a.*, @vers from Temp_PTS_Test_pmt_base a;

	delete from risk.core_fcst_npl_wo_and_recovery where vers = @vers;
	insert into risk.core_fcst_npl_wo_and_recovery select a.*, @vers from Temp_PTS_Test_npl_wo_and_recovery a;

	delete from risk.core_fcst_int_rates where vers = @vers;
	insert into risk.core_fcst_int_rates select a.*, @vers from Temp_PTS_Test_stg_int_rates a;

	----------------------------------------------------------------

	delete from risk.core_fcst_p8_base where vers = @vers;
	insert into risk.core_fcst_p8_base select a.*, @vers from Temp_PTS_Test_base a;

	delete from risk.core_fcst_eps_rates where vers = @vers;
	insert into risk.core_fcst_eps_rates select a.*, @vers from Temp_PTS_Test_stg_eps_rates a;

	delete from risk.core_fcst_analyt_prov_NU_rates where vers = @vers;
	insert into risk.core_fcst_analyt_prov_NU_rates select a.*, @vers from Temp_PTS_Test_analyt_prov_NU_rates a;

	delete from risk.core_fcst_det_pieces_L1 where vers = @vers;
	insert into risk.core_fcst_det_pieces_L1 select a.*, @vers from Temp_PTS_Test_det_pieces_L1 a;

	delete from risk.core_fcst_det_pieces_L2 where vers = @vers;
	insert into risk.core_fcst_det_pieces_L2 select a.*, @vers from Temp_PTS_Test_det_pieces_L2 a;

	delete from risk.core_fcst_fact_for_finance where vers = @vers;
	insert into risk.core_fcst_fact_for_finance 
	select a.r_date as mob_date_to, 	
	b.term,
	b.segment_rbp,
	iif(z.external_id is not null, 'FREEZE', b.flag_kk) as flag_kk,
	b.generation,
	
	--RiskDWH.dbo.get_bucket_720(a.dpd) as bucket_720,
	RiskDWH.dbo.get_bucket_360(a.dpd) as dpd_bucket,
	--RiskDWH.dbo.get_bucket_360_m(a.dpd) as bucket_360m,
	d.NU_segment,
	sum(isnull(a.due_od,0)) as portf,
	sum(isnull(a.prov_od,0)) as provisions_od,
	sum(isnull(a.prov_od_NU,0)) as provisions_od_NU,

	sum(isnull(a.due_int,0)) as interest,
	sum(isnull(a.prov_int,0)) as provisions_int,
	sum(isnull(a.prov_int_NU,0)) as provisions_int_NU,
	sum(case when a.due_od + a.due_int + a.due_fee > 0 then 1 else 0 end) as pieces,

	sum(isnull(a.IFRS9_od,0)) as IFRS9_od,
	sum(isnull(a.IFRS9_int,0)) as IFRS9_int,
	sum(isnull(a.IFRS9_fee,0)) as IFRS9_fee,

	@vers

	from Temp_PTS_Test_umfo_fact a
	inner join Temp_PTS_Test_cred_reestr b
	on a.external_id = b.external_id
	--where a.cli_type = 'ФЛ'
	inner join Temp_PTS_Test_UMFO_NU_segment d
	on a.external_id = d.external_id
	and a.r_date = d.r_date
	left join Temp_PTS_Test_zamorozka z
	on a.external_id = z.external_id
	and a.r_date between z.freeze_from and z.freeze_to
	where a.r_date between '2018-12-31' and @rdt
	group by a.r_date, 
	b.term,
	b.segment_rbp,
	iif(z.external_id is not null, 'FREEZE', b.flag_kk),
	b.generation,
	RiskDWH.dbo.get_bucket_360(a.dpd),
	d.NU_segment
	;


	delete from risk.core_fcst_NU_segment_distrib where vers = @vers;
	insert into risk.core_fcst_NU_segment_distrib select a.*, @vers from Temp_PTS_Test_NU_segment_distrib a;



	print ('timing, CORE ' + format(getdate(), 'HH:mm:ss'));





	---------------------------------------------------------------------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------------------------------------------------------------------




	---------------------------------------------------
	--дубли?
	select a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_to
	from Temp_PTS_Test_final_model a
	group by a.term, a.segment_rbp, a.flag_kk, a.generation, a.mob_date_to, a.bucket_90_to
	having count(*)>1
	;








	/**********************************************************************************/


	--простыня для прикидки IFRS9
	select 
	a.mob_date_to, 
	case when a.flag_kk in ('BANKRUPT','BUSINESS','INSTALLMENT') then a.flag_kk else 'PTS' end as subportf, 
	a.bucket_90 as dpd_bucket, 
	isnull(a.months_in_default,0) as months_in_default,
	sum(isnull(a.portf,0)) as portf, 
	sum(isnull(a.interest,0)) as interest 
	from Temp_PTS_Test_base	a
	where a.mob_date_to between '2022-08-31' and '2030-12-31'
	group by a.mob_date_to, 
	case when a.flag_kk in ('BANKRUPT','BUSINESS','INSTALLMENT') then a.flag_kk else 'PTS' end,
	a.bucket_90,
	isnull(a.months_in_default,0)
	order by 1,2,3,4
	;


	
	--проверка 

	;

	/*
	select * from Temp_PTS_Test_cred_reestr a
	where not exists (select 1 from Temp_PTS_Test_UMFO_NU_segment b where a.external_id = b.external_id)
	;

	*/

	/*

	select *
	from (select * from Temp_PTS_Test_for_finance a where a.mob_date_to between '2021-12-31' and '2027-04-30') a
	full join Temp_PTS_Test_pmt_base b
	on a.term = b.term
	and a.segment_rbp = b.segment_rbp
	and a.flag_kk = b.flag_kk 
	and a.generation = b.generation
	and a.dpd_bucket = b.dpd_bucket
	and a.NU_segment = b.NU_segment
	and a.mob_date_to = b.mob_date_to
	where 1=1
	and (a.term is null or b.term is null)
	--and isnull(a.flag_kk,'n') <> 'FREEZE'
	and isnull(a.mob_date_to, b.mob_date_to) = '2021-12-31'

	;
	*/


	/*

	select a.mob_date_to, a.term, a.segment_rbp, a.flag_kk, a.generation, a.NU_segment, a.dpd_bucket
	from Temp_PTS_Test_for_finance a
	group by a.mob_date_to, a.term, a.segment_rbp, a.flag_kk, a.generation, a.NU_segment, a.dpd_bucket
	having count(*)>1;

	select a.mob_date_to, a.term, a.segment_rbp, a.flag_kk, a.generation, a.NU_segment, a.dpd_bucket
	from Temp_PTS_Test_pmt_base a
	group by a.mob_date_to, a.term, a.segment_rbp, a.flag_kk, a.generation, a.NU_segment, a.dpd_bucket
	having count(*)>1;



	select min(mob_date_to), max(mob_date_to) from Temp_PTS_Test_for_finance;
	select min(mob_date_to), max(mob_date_to) from Temp_PTS_Test_pmt_base;


	select * from Temp_PTS_Test_for_finance a where a.fact_od = 0 and a.fact_pieces > 0;
	select * from Temp_PTS_Test_for_finance a where a.fact_od > 0 and a.fact_pieces = 0;

	select * from Temp_PTS_Test_for_finance a where a.model_od = 0 and a.model_pieces > 0;
	select * from Temp_PTS_Test_for_finance a where a.model_od > 0 and a.model_pieces = 0;

	*/




	------------------------------------------------------------------------------------------------------------------------------
	--PART 8.1 для демонстрации
	------------------------------------------------------------------------------------------------------------------------------
	;

	/*
	with base as (
		select a.term, a.segment_rbp, a.generation, a.flag_kk, a.vl_rub_fact 
		from Temp_PTS_Test_final_model a
		where a.mob_to = 0
		and a.bucket_90_to = '[01] 0'
	)
	select a.term, a.segment_rbp, a.generation, a.flag_kk
	from base a
	group by a.term, a.segment_rbp, a.generation, a.flag_kk
	having count(*)>1
	*/



	--выдачи
	drop table if exists Temp_PTS_Test_stg_volumes;

	select 
		--a.term, 
		--a.segment_rbp, 
		--a.generation, 
		--a.flag_kk, 
		--a.vl_rub_fact
		1 as term,
		a.segment_rbp,
		a.generation,
		case 
			when a.flag_kk in ('USUAL','WRONG MIGR','BANKRUPT','CESS 2021-08-31','KK','FREEZE')
				or a.flag_kk like 'STOP_CHARGE%'
				or a.flag_kk like 'KK00%' then 'PTS'
			when a.flag_kk = 'BUSINESS' then 'BUSINESS'
			when a.flag_kk in ('INSTALLMENT') then 'INSTALLMENT' end
		as subportf,
		sum(a.vl_rub_fact) as vl_rub_fact
	into Temp_PTS_Test_stg_volumes
	from Temp_PTS_Test_final_model a
	where a.mob_to = 0
		and a.bucket_90_to = '[01] 0'
	group by a.segment_rbp,
		a.generation,
		case 
			when a.flag_kk in ('USUAL','WRONG MIGR','BANKRUPT','CESS 2021-08-31','KK','FREEZE')
				or a.flag_kk like 'STOP_CHARGE%'
				or a.flag_kk like 'KK00%' then 'PTS'
			when a.flag_kk = 'BUSINESS' then 'BUSINESS'
			when a.flag_kk in ('INSTALLMENT') then 'INSTALLMENT' end
	;

	--процентная ставка
	drop table if exists Temp_PTS_Test_stg_interest_rates;


	select 1 as term,
		a.segment_rbp,
		a.generation,
		case 
			when a.flag_kk in ('USUAL','WRONG MIGR','BANKRUPT','CESS 2021-08-31','KK','FREEZE')
				or a.flag_kk like 'STOP_CHARGE%'
				or a.flag_kk like 'KK00%' then 'PTS'
			when a.flag_kk = 'BUSINESS' then 'BUSINESS'
			when a.flag_kk in ('INSTALLMENT') then 'INSTALLMENT'
		end as subportf,
		sum(a.avg_int_rate * a.vl_rub_fact) / sum(a.vl_rub_fact) as avg_int_rate

	into Temp_PTS_Test_stg_interest_rates
	from Temp_PTS_Test_final_model a
	where a.mob_to = 0
	and a.bucket_90_to = '[01] 0'
	group by a.segment_rbp,
		a.generation,
		case 
			when a.flag_kk in ('USUAL','WRONG MIGR','BANKRUPT','CESS 2021-08-31','KK','FREEZE')
				or a.flag_kk like 'STOP_CHARGE%'
				or a.flag_kk like 'KK00%' then 'PTS'
			when a.flag_kk = 'BUSINESS' then 'BUSINESS'
			when a.flag_kk in ('INSTALLMENT') then 'INSTALLMENT'
		end
	;


	--Для NL и GL

	drop table if exists Temp_PTS_Test_pmt_wo_for_nl;
	select  
		1 as term,
		a.segment_rbp,
		a.generation,
		case 
			when a.flag_kk in ('USUAL','WRONG MIGR','BANKRUPT','CESS 2021-08-31','KK','FREEZE')
				or a.flag_kk like 'STOP_CHARGE%'
				or a.flag_kk like 'KK00%' then 'PTS'
			when a.flag_kk = 'BUSINESS' then 'BUSINESS'
			when a.flag_kk in ('INSTALLMENT') then 'INSTALLMENT'
		end as subportf,
		a.mob_date_to,
		sum(a.npl_recovery) as npl_recovery ,
		sum(a.od_wo) as od_wo

	into Temp_PTS_Test_pmt_wo_for_nl
	from Temp_PTS_Test_npl_wo_and_recovery a
	group by a.segment_rbp,
		a.generation,
		case 
			when a.flag_kk in ('USUAL','WRONG MIGR','BANKRUPT','CESS 2021-08-31','KK','FREEZE')
				or a.flag_kk like 'STOP_CHARGE%'
				or a.flag_kk like 'KK00%' then 'PTS'
			when a.flag_kk = 'BUSINESS' then 'BUSINESS'
			when a.flag_kk in ('INSTALLMENT') then 'INSTALLMENT'
		end,
		a.mob_date_to
	;





	--для GL по проданным (цессия)
	drop table if exists Temp_PTS_Test_for_cessed_GL;
	select a.term, a.segment_rbp, a.generation, a.flag_kk, a.NU_segment, a.dpd_bucket, sum(isnull(a.fact_od,0)) as GL_chisl
	into Temp_PTS_Test_for_cessed_GL
	from Temp_PTS_Test_for_finance a
	full join Temp_PTS_Test_pmt_base b
	on a.term = b.term
		and a.segment_rbp = b.segment_rbp
		and a.flag_kk = b.flag_kk 
		and a.generation = b.generation
		and a.dpd_bucket = b.dpd_bucket
		and a.NU_segment = b.NU_segment
		and a.mob_date_to = b.mob_date_to 
	where isnull(a.mob_date_to,b.mob_date_to) = '2021-07-31'
		and isnull(a.flag_kk,b.flag_kk) = 'CESS 2021-08-31'
		and cast(substring(isnull(a.dpd_bucket,b.dpd_bucket),2,2) as int) > 4
	group by a.term, a.segment_rbp, a.generation, a.flag_kk, a.NU_segment, a.dpd_bucket
	;





	--выборка "для демонстрации"

	drop table if exists Temp_PTS_Test_for_demonstration;

	with base as (
		select 
			'[01] Regular' as scenario,
			1 as term,
			isnull(a.segment_rbp, b.segment_rbp) as segment_rbp,
			isnull(a.generation, b.generation) as generation,

			case 
				when isnull(a.flag_kk,b.flag_kk) in ('USUAL','WRONG MIGR','BANKRUPT','CESS 2021-08-31','KK','FREEZE')
					or isnull(a.flag_kk,b.flag_kk) like 'STOP_CHARGE%'
					or isnull(a.flag_kk,b.flag_kk) like 'KK00%' then 'PTS'

				when isnull(a.flag_kk,b.flag_kk) = 'BUSINESS' then 'BUSINESS'
				when isnull(a.flag_kk,b.flag_kk) in ('INSTALLMENT') then 'INSTALLMENT'
			end as subportf,

			isnull(a.mob_date_to,b.mob_date_to) as r_date,
			isnull(datediff(MM,a.generation,a.mob_date_to), datediff(MM,b.generation,b.mob_date_to)) as MoB,
			case 
				when isnull(a.dpd_bucket,b.dpd_bucket) in ('[01] 0') then '[01] 0'
				when isnull(a.dpd_bucket,b.dpd_bucket) in ('[02] 1-30','[03] 31-60','[04] 61-90') then '[02] 1-90'
				when cast(substring(isnull(a.dpd_bucket,b.dpd_bucket),2,2) as int) between 5 and 13 then '[03] 91-360'
				when isnull(a.dpd_bucket,b.dpd_bucket) = '[14] 360+' then '[04] 361+'
			end as dpd_bucket_90,

			--лист Баланс
			sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_od,0) else isnull(a.model_od,0) end) as principal,
			sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_int,0) else isnull(a.model_int,0) end) as interest,

			sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_od,0) else isnull(a.model_od,0) end +
			case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_int,0) else isnull(a.model_int,0) end) as gross,


			sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_prov_od,0) else isnull(a.model_prov_od,0) end) as prov_IFRS_principal,
			sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_prov_int,0) else isnull(a.model_prov_int,0)  end) as prov_IFRS_interest,
			sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_prov_od,0) + isnull(a.fact_prov_int,0) 
				else isnull(a.model_prov_od,0) + isnull(a.model_prov_int,0) end) as prov_IFRS_gross,


			sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_prov_NU_od,0) else isnull(a.model_prov_NU_od,0) end) as prov_RAS_principal,
			sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_prov_NU_int,0) else isnull(a.model_prov_NU_int,0) end) as prov_RAS_interest,
			sum(case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_prov_NU_od,0) + isnull(a.fact_prov_NU_int,0) 
				else isnull(a.model_prov_NU_od,0) + isnull(a.model_prov_NU_int,0) end) as prov_RAS_gross,

			sum(isnull(b.od_wo,0)) as writeoff_principal,
			sum(isnull(b.int_wo,0)) as writeoff_interest,

			--лист EL
			sum(
				case when cast(substring(isnull(a.dpd_bucket,b.dpd_bucket),2,2) as int) > 4 then
						case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_od,0) else isnull(a.model_od,0) end
				else 0 end
				)
			as NL_chisl,

			sum(
				case 
					when c.GL_chisl is not null then c.GL_chisl
					when cast(substring(isnull(a.dpd_bucket,b.dpd_bucket),2,2) as int) > 4 then 
					case when isnull(a.mob_date_to,b.mob_date_to) < @dt_back_test_from then isnull(a.fact_od,0) else isnull(a.model_od,0) end
				else 0 end
				)
			as GL_chisl, 

			--sum(case when a.bucket_90_to = '[05] 90+' then isnull(a.vl_rub_fact,0) else 0 end) as volume, --!!!!!!!---


			--лист CF (cashflow)
			sum(isnull(b.od_pmt,   0)) as cash_od,
			sum(isnull(b.int_pmt,  0)) as cash_interest,
			sum(isnull(b.fee_pmt,  0)) as cash_fee,
			sum(isnull(b.straf_pmt,0)) as cash_rest,

			sum( 
				isnull(b.od_pmt,   0)+
				isnull(b.int_pmt,  0)+
				isnull(b.fee_pmt,  0)+
				isnull(b.straf_pmt,0)
			) as cash_total

		--sum(a.avg_int_rate * a.vl_rub_fact) / sum(a.vl_rub_fact) as avg_int_rate


		from Temp_PTS_Test_for_finance a
		full join Temp_PTS_Test_pmt_base b
		on a.term = b.term
			and a.segment_rbp = b.segment_rbp
			and a.flag_kk = b.flag_kk 
			and a.generation = b.generation
			and a.dpd_bucket = b.dpd_bucket
			and a.NU_segment = b.NU_segment
			and a.mob_date_to = b.mob_date_to
	
		left join Temp_PTS_Test_for_cessed_GL c
		on a.term = c.term
			and a.segment_rbp = c.segment_rbp
			and a.generation = c.generation
			and a.flag_kk = c.flag_kk
			and a.NU_segment = c.NU_segment
			and a.mob_date_to >= '2021-08-31'
			and a.dpd_bucket = c.dpd_bucket

		group by 
		isnull(a.segment_rbp, b.segment_rbp),
		isnull(a.generation, b.generation),

		case 
			when isnull(a.flag_kk,b.flag_kk) in ('USUAL','WRONG MIGR','BANKRUPT','CESS 2021-08-31','KK','FREEZE')
					or isnull(a.flag_kk,b.flag_kk) like 'STOP_CHARGE%'
					or isnull(a.flag_kk,b.flag_kk) like 'KK00%' then 'PTS'
			when isnull(a.flag_kk,b.flag_kk) = 'BUSINESS' then 'BUSINESS'
			when isnull(a.flag_kk,b.flag_kk) in ('INSTALLMENT') then 'INSTALLMENT'
		end,

		isnull(a.mob_date_to,b.mob_date_to),
		isnull(datediff(MM,a.generation,a.mob_date_to), datediff(MM,b.generation,b.mob_date_to)),
		case 
			when isnull(a.dpd_bucket,b.dpd_bucket) in ('[01] 0') then '[01] 0'
			when isnull(a.dpd_bucket,b.dpd_bucket) in ('[02] 1-30','[03] 31-60','[04] 61-90') then '[02] 1-90'
			when cast(substring(isnull(a.dpd_bucket,b.dpd_bucket),2,2) as int) between 5 and 13 then '[03] 91-360'
			when isnull(a.dpd_bucket,b.dpd_bucket) = '[14] 360+' then '[04] 361+'
		end

	)

	select a.*, case when a.dpd_bucket_90 = '[03] 91-360' then b.vl_rub_fact else 0 end as volume, c.avg_int_rate

	into Temp_PTS_Test_for_demonstration
	from base a
	left join Temp_PTS_Test_stg_volumes b
	on a.term = b.term
		and a.segment_rbp = b.segment_rbp
		and a.generation = b.generation
		and a.subportf = b.subportf

	left join Temp_PTS_Test_stg_interest_rates c
	on a.term = c.term
		and a.segment_rbp = c.segment_rbp
		and a.generation = c.generation
		and a.subportf = c.subportf
	;





	--добавляем сумму выдачи в бакет 91-360 для NL и GL
	insert into Temp_PTS_Test_for_demonstration
	select DISTINCT
		a.scenario,
		a.term,
		a.segment_rbp,
		a.generation,
		a.subportf,
		a.r_date,
		a.MoB,
		'[03] 91-360' as dpd_bucket_90,
		0 as principal,
		0 as interest,
		0 as gross,
		0 as prov_IFRS_principal,
		0 as prov_IFRS_interest,
		0 as prov_IFRS_gross,
		0 as prov_RAS_principal,
		0 as prov_RAS_interest,
		0 as prov_RAS_gross,
		0 as writeoff_principal,
		0 as writeoff_interest,
		0 as NL_chisl,
		0 as GL_chisl,
		0 as cash_od,
		0 as cash_interest,
		0 as cash_fee,
		0 as cash_rest,
		0 as cash_total,
		b.vl_rub_fact as volume,
		a.avg_int_rate
	from Temp_PTS_Test_for_demonstration a
	left join Temp_PTS_Test_stg_volumes b
	on a.segment_rbp = b.segment_rbp
	and a.generation = b.generation
	and a.subportf = b.subportf
	where 1=1
	--and a.MoB = 1
	--and not exists (select 1 from Temp_PTS_Test_for_demonstration b where a.segment_rbp = b.segment_rbp and a.generation = b.generation and b.MoB = 1 and b.dpd_bucket_90 = '[03] 91-360')
	and not exists (select 1 from Temp_PTS_Test_for_demonstration b 
		where a.segment_rbp = b.segment_rbp
		and a.generation = b.generation 
		and a.subportf = b.subportf
		and a.MoB = b.MoB
		and b.dpd_bucket_90 = '[03] 91-360'
		)
	--and a.dpd_bucket_90 = '[01] 0';




	--суммируем числитель NL и GL в бакет 91-360
	drop table if exists Temp_PTS_Test_for_update_NLGL;
	with a as (
		select a.term, a.segment_rbp, a.generation, a.subportf, a.r_date, 
		sum(a.NL_chisl) as NL_chisl,
		sum(a.GL_chisl) as GL_chisl
		from Temp_PTS_Test_for_demonstration a
		where a.dpd_bucket_90 in ('[03] 91-360','[04] 361+')
		group by a.term, a.segment_rbp, a.generation, a.subportf, a.r_date
	)
	select a.term, a.segment_rbp, a.generation, a.subportf, a.r_date, 
		'[03] 91-360' as dpd_bucket,
		a.NL_chisl + isnull(b.od_wo,0) as NL_chisl,
		a.GL_chisl + isnull(b.od_wo,0) + isnull(b.npl_recovery,0) as GL_chisl
	into Temp_PTS_Test_for_update_NLGL
	from a
	left join Temp_PTS_Test_pmt_wo_for_nl b
		on a.term = b.term
		and a.segment_rbp = b.segment_rbp
		and a.generation = b.generation
		and a.subportf = b.subportf
		and a.r_date = b.mob_date_to
	;



	update a set a.NL_chisl = b.NL_chisl, a.GL_chisl = b.GL_chisl
	from Temp_PTS_Test_for_demonstration a
	left join Temp_PTS_Test_for_update_NLGL b
		on a.term = b.term
		and a.segment_rbp = b.segment_rbp
		and a.generation = b.generation
		and a.subportf = b.subportf
		and a.r_date = b.r_date
	where a.dpd_bucket_90 = '[03] 91-360';

	update a set a.NL_chisl = 0, a.GL_chisl = 0
	from Temp_PTS_Test_for_demonstration a
	where a.dpd_bucket_90 = '[04] 361+'
	;

	delete from Temp_PTS_Test_for_demonstration where MoB < 0;


	--doubles?
	select a.term, a.segment_rbp, a.generation, a.subportf, a.r_date, a.dpd_bucket_90, mob, count(*) as cnt--select top 100 *
	from Temp_PTS_Test_for_demonstration a
	group by a.term, a.segment_rbp, a.generation, a.subportf, a.r_date, a.dpd_bucket_90, mob
	having count(*)>1
					


	------------------------------------------------------------------------------------------------------------------------


	--полотно для Excel

	delete from risk.UE_EXCEL_BASE_DATA where vers = @vers
	;
	insert into Risk.UE_EXCEL_BASE_DATA
	select
		cast(getdate() as datetime) as dt_dml,
		@vers as vers,
		scenario,
		term,
		segment_rbp,
		generation,
		subportf,
		r_date,
		MoB,
		volume * avg_int_rate as RATE_VOL,
		dpd_bucket_90,
		principal,
		interest,
		gross,
		prov_IFRS_principal,
		prov_IFRS_interest,
		prov_IFRS_gross,
		prov_RAS_principal,
		prov_RAS_interest,
		prov_RAS_gross,
		writeoff_principal,
		writeoff_interest,
		NL_chisl,
		GL_chisl,
		volume,
		cash_od,
		cash_interest,
		cash_fee,
		cash_rest,
		cash_total,
		avg_int_rate
	from Temp_PTS_Test_for_demonstration
	;



	---------------------------------------------------------------------------------------------------------------------------------------------------
	---PART 11 - Основа для расчета виртуальных ставок МСФО
	---------------------------------------------------------------------------------------------------------------------------------------------------

	delete from risk.prov_stg_virt_portf;


	--Портфель: на конец месяца и средний

	with base as (
		--последний факт	
		select a.r_date as date_on, 
		RiskDWH.dbo.get_bucket_720(a.dpd) as bucket,
		sum(a.due_od) as portf
		from Temp_PTS_Test_umfo_fact a
		inner join Temp_PTS_Test_cred_reestr b
		on a.external_id = b.external_id
		where a.r_date = @rdt
		and b.flag_kk not in ('Installment','KK','Business','FREEZE')
		and b.segment_rbp <> 'GR 30/40'
		group by a.r_date, RiskDWH.dbo.get_bucket_720(a.dpd)	
	union all	
		--модель
		select a.mob_date_to as date_on, a.bucket_720 as bucket, sum(a.portf) as portf--select top 100 *
		from Temp_PTS_Test_base a
		where a.mob_date_to between '2024-12-31' and '2025-12-31'
		and a.flag_kk not in ('Installment','KK','Business','FREEZE')
		and a.segment_rbp <> 'GR 30/40'
		group by a.mob_date_to, a.bucket_720
	), average as (
		select a.date_on, a.bucket, (a.portf + b.portf) / 2.0 as avg_portf
		from base a
		left join base b
		on a.bucket = b.bucket
		and a.date_on = eomonth(b.date_on,1)
	)

	insert into risk.prov_stg_virt_portf
	select a.date_on, a.bucket, a.portf, b.avg_portf 
	from base a
	left join average b
	on a.date_on = b.date_on
	and a.bucket = b.bucket
	where a.date_on >= '2021-12-31'
	;





	--Платежи по ОД
	--declare @dt_back_test_from date = '2021-12-31';


	delete from risk.prov_stg_virt_payment;

	with t1 as (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, 
		eomonth(a.mob_date_to, -1*a.mod_num) as default_dt,
		eomonth(a.mob_date_to, -1*a.last_MOD) as default_dt2,
	
		a.calc_od_payoff - lag(a.calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, 
		eomonth(a.mob_date_to, -1*a.mod_num), eomonth(a.mob_date_to, -1*a.last_MOD) order by a.mob_date_to) as od_pmt,
		a.calc_int_payoff - lag(a.calc_int_payoff,1,0)
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, 
		eomonth(a.mob_date_to, -1*a.mod_num), eomonth(a.mob_date_to, -1*a.last_MOD) order by a.mob_date_to) as int_pmt,
		a.fee_calc_od_payoff - lag(a.fee_calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, 
		eomonth(a.mob_date_to, -1*a.mod_num), eomonth(a.mob_date_to, -1*a.last_MOD) order by a.mob_date_to) as fee_pmt,
		a.straf_calc_od_payoff - lag(a.straf_calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, 
		eomonth(a.mob_date_to, -1*a.mod_num), eomonth(a.mob_date_to, -1*a.last_MOD) order by a.mob_date_to) as straf_pmt,
		a.wo_calc_od_payoff - lag(a.wo_calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, 
		eomonth(a.mob_date_to, -1*a.mod_num), eomonth(a.mob_date_to, -1*a.last_MOD) order by a.mob_date_to) as od_wo,
		a.int_wo_calc_od_payoff - lag(a.int_wo_calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, 
		eomonth(a.mob_date_to, -1*a.mod_num), eomonth(a.mob_date_to, -1*a.last_MOD) order by a.mob_date_to) as int_wo

		from Temp_PTS_Test_stg1_default_recovery_fact a
		where a.mob_date_to between @dt_back_test_from /*'2021-10-31'*/ and EOMONTH(@dt_back_test_from, 12)
	), t2 as (
	select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, a.mod_num, a.last_MOD, 
		eomonth(a.mob_date_to, -1*a.mod_num) as default_dt,
		eomonth(a.mob_date_to, -1*a.last_MOD) as default_dt2,
	
		a.calc_od_payoff - lag(a.calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, a.freeze_from, 
		eomonth(a.mob_date_to, -1*isnull(a.mod_num,-999)), eomonth(a.mob_date_to, -1*isnull(a.last_MOD,-999)) order by a.mob_date_to) as od_pmt,
		a.calc_int_payoff - lag(a.calc_int_payoff,1,0)
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, a.freeze_from,
		eomonth(a.mob_date_to, -1*isnull(a.mod_num,-999)), eomonth(a.mob_date_to, -1*isnull(a.last_MOD,-999)) order by a.mob_date_to) as int_pmt,
		a.fee_calc_od_payoff - lag(a.fee_calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, a.freeze_from,
		eomonth(a.mob_date_to, -1*isnull(a.mod_num,-999)), eomonth(a.mob_date_to, -1*isnull(a.last_MOD,-999)) order by a.mob_date_to) as fee_pmt,
		a.straf_calc_od_payoff - lag(a.straf_calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, a.freeze_from,
		eomonth(a.mob_date_to, -1*isnull(a.mod_num,-999)), eomonth(a.mob_date_to, -1*isnull(a.last_MOD,-999)) order by a.mob_date_to) as straf_pmt,	
		a.wo_calc_od_payoff - lag(a.wo_calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, a.freeze_from,
		eomonth(a.mob_date_to, -1*isnull(a.mod_num,-999)), eomonth(a.mob_date_to, -1*isnull(a.last_MOD,-999)) order by a.mob_date_to) as od_wo,
		a.int_wo_calc_od_payoff - lag(a.int_wo_calc_od_payoff,1,0) 
		over (partition by a.term, a.generation, a.segment_rbp, a.flag_kk, a.freeze_from,
		eomonth(a.mob_date_to, -1*isnull(a.mod_num,-999)), eomonth(a.mob_date_to, -1*isnull(a.last_MOD,-999)) order by a.mob_date_to) as int_wo
		from Temp_PTS_Test_stg3_default_recovery_model a
		where a.mob_date_to between @dt_back_test_from /*'2021-10-31'*/ and EOMONTH(@dt_back_test_from, 12)--'2022-12-31'
	), u as (
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, 
		RiskDWH.dbo.get_bucket_720(91 + (a.last_MOD - 1) * 30) as bucket,
		sum(a.od_pmt) as od_pmt,
		sum(a.int_pmt) as int_pmt,
		sum(a.fee_pmt) as fee_pmt,
		sum(a.straf_pmt) as straf_pmt,
		sum(a.od_wo) as od_wo,
		sum(a.int_wo) as int_wo
		from (select * from t1 union all select * from t2) a
		where a.last_MOD <> 0
		group by a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, 
		RiskDWH.dbo.get_bucket_720(91 + (a.last_MOD - 1) * 30)
	union all	
		select a.term, a.generation, a.segment_rbp, a.flag_kk, a.mob_date_to, 
		a.bucket_90_to as bucket, 	
		a.model_od_pmt as od_pmt, 
		a.model_int_pmt as int_pmt,
		cast(0 as float) as fee_pmt,
		cast(0 as float) as straf_pmt,
		cast(0 as float) as od_wo,
		cast(0 as float) as int_wo
		from Temp_PTS_Test_final_model a
		where a.mob_date_to between @dt_back_test_from /*'2021-10-31'*/ and EOMONTH(@dt_back_test_from, 12)--'2022-12-31'
		and a.bucket_90_to in ('[01] 0','[02] 1-30','[03] 31-60','[04] 61-90')

	)
	insert into risk.prov_stg_virt_payment

	select a.mob_date_to as date_on, a.bucket, 
	sum(isnull(a.od_pmt,0)) as pmt, 
	sum(isnull(a.od_pmt,0) + isnull(a.int_pmt,0) + isnull(a.fee_pmt,0) + isnull(a.straf_pmt,0)) as pmt_all
	from u as a
	where a.flag_kk not in ('Installment','KK','Business','FREEZE')
	and a.segment_rbp <> 'GR 30/40'
	group by a.mob_date_to, a.bucket

	;






	---------------------------------------------------------------------------------------------------------------------------------------
	-- МОНИТОРИНГ
	---------------------------------------------------------------------------------------------------------------------------------------


	--МОДЕЛЬ


	declare @model_date date = eomonth(@rdt, 1); --первая прогнозная точка
	declare @horizon2 int = 12 * 1;


	--select max(vers) from RiskDWH.risk.migr_matrix_monitoring 

	--delete from RiskDWH.risk.migr_matrix_monitoring where kind = 'MODEL' and r_date = @model_date and vers = @vers;
	delete from RiskDWH.risk.migr_matrix_monitoring where kind = 'MODEL' and date_on = eomonth(@model_date,-1) and vers = @vers;

	---обычные кредиты

	with paydown as (
	--Возращаем фактические платежи в нулевом MoB для последнего поколения (чтобы входящая сумма была равна сумме выдачи)
		select a.mob_date_to, a.id1, a.bucket_90_from, a.bucket_90_to, sum(b.vl_rub_fact * -1 * a.corr) as od
		from Temp_PTS_Test_fix_matrix a
		inner join Temp_PTS_Test_new_volume b
		on a.id1 = hashbytes('MD2',concat(b.term,b.segment_rbp,b.generation,b.flag_kk))
		where a.bucket_90_from = '[01] 0' and a.bucket_90_to = '[06] Pay-off'
		group by a.mob_date_to, a.id1, a.bucket_90_from, a.bucket_90_to
	)
	insert into riskdwh.risk.migr_matrix_monitoring

	select @vers as vers,
	eomonth(@model_date,-1) as date_on,
	cast(getdate() as datetime) as dt_dml,
	cast('MODEL' as varchar(100)) as kind,
	a.id1, a.term, a.segment_rbp, a.generation, a.flag_kk, 
	b.mob_date_to as r_date,
	b.mob_to as MoB,
	a.bucket_90_from as bucket_from,
	b.bucket_90_to as bucket_to,
	sum(isnull(a.total_od_from * b.model_coef_adj, 0)) + sum(isnull(c.od,0)) as od

	from Temp_PTS_Test_last_fact a
	left join Temp_PTS_Test_for_back_test b
	on a.id1 = b.id1
	and a.mob_to = b.mob_to - 1
	and a.bucket_90_from = b.bucket_90_from

	left join paydown c
	on a.id1 = c.id1
	and b.bucket_90_from = c.bucket_90_from
	and b.bucket_90_to = c.bucket_90_to
	and b.mob_date_to = c.mob_date_to

	where a.mob_date_to = eomonth(@model_date,-1)
	and a.flag_kk not like 'KK%'
	group by a.id1, a.term, a.segment_rbp, a.generation, a.flag_kk, 
	b.mob_date_to,
	b.mob_to,
	a.bucket_90_from,
	b.bucket_90_to

	;



	---кредитные каникулы
	insert into riskdwh.risk.migr_matrix_monitoring

	select @vers as vers,
	eomonth(@model_date,-1) as date_on,
	cast(getdate() as datetime) as dt_dml,
	cast('MODEL' as varchar(100)) as kind,
	a.id1, a.term, a.segment_rbp, a.generation, a.flag_kk, 
	a.mob_date_to as r_date,
	a.mob_to as MoB,
	a.bucket_90_from as bucket_from,
	a.bucket_90_to as bucket_to,
	sum(isnull(a.model_od, 0)) as od
	from Temp_PTS_Test_stg_freeze_model a
	where a.mob_date_to = @model_date
	group by a.id1, a.term, a.segment_rbp, a.generation, a.flag_kk, 
	a.mob_date_to,
	a.mob_to,
	a.bucket_90_from,
	a.bucket_90_to


	--нулевой MoB

	insert into riskdwh.risk.migr_matrix_monitoring

	select @vers as vers,
	eomonth(@model_date,-1) as date_on,
	cast(getdate() as datetime) as dt_dml,
	cast('MODEL' as varchar(100)) as kind, 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1, 
	a.term, a.segment_rbp, a.generation, a.flag_kk,
	a.generation as r_date,
	0 as MoB,
	'[00] New_volume' as bucket_from,
	'[01] 0' as bucket_to,
	sum(a.vl_rub_fact * (1.0 - ((1.0 - isnull(p.coef,1.0)) * isnull(st.koef_po,1.0))) ) as od

	from Temp_PTS_Test_virt_gens a
	left join Temp_PTS_Test_det_stress st
	on a.generation between st.dt_from and st.dt_to
	left join Temp_PTS_Test_det_pdp_coef p
	on a.segment_rbp = p.segment_rbp
	where a.generation = @model_date
	group by hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.segment_rbp, a.generation, a.flag_kk


	insert into riskdwh.risk.migr_matrix_monitoring

	select @vers as vers,
	eomonth(@model_date,-1) as date_on,
	cast(getdate() as datetime) as dt_dml,
	cast('MODEL' as varchar(100)) as kind, 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1, 
	a.term, a.segment_rbp, a.generation, a.flag_kk,
	a.generation as r_date,
	0 as MoB,
	'[00] New_volume' as bucket_from,
	'[06] Pay-off' as bucket_to,
	isnull(sum(a.vl_rub_fact * ((1.0 - isnull(p.coef,1.0)) * isnull(st.koef_po,1.0))), 0) as od
	from Temp_PTS_Test_virt_gens a
	left join Temp_PTS_Test_det_stress st
	on a.generation between st.dt_from and st.dt_to
	left join Temp_PTS_Test_det_pdp_coef p
	on a.segment_rbp = p.segment_rbp
	where a.generation = @model_date
	group by hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.segment_rbp, a.generation, a.flag_kk
	;





	--цикл на полгода вперед

	declare @incr_dt date = @model_date;

	while @incr_dt < eomonth(@model_date,@horizon2-1)
	begin



	--НЕ КК и НЕ новые выдачи
	insert into riskdwh.risk.migr_matrix_monitoring

	select 
	@vers as vers,
	eomonth(@model_date,-1) as date_on,
	cast(getdate() as datetime) as dt_dml,
	cast('MODEL' as varchar(100)) as kind, 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1,
	a.term, a.segment_rbp, a.generation, a.flag_kk,
	b.mob_date_to as r_date,
	b.mob_to as MoB,
	a.bucket_90_to as bucket_from,
	b.bucket_90_to as bucket_to,

	sum(
	isnull(a.model_fact_od, 0)
	* case 
		when b.mob_to = 1 and b.bucket_90_from = '[01] 0' and b.bucket_90_to = '[06] Pay-off' 
		then (b.model_coef_adj - (1.0 - isnull(p.coef,1.0)) * isnull(st.koef_po,1.0)) / (1.0 - (1.0 - isnull(p.coef,1.0)) * isnull(st.koef_po,1.0))

		when b.mob_to = 1 and b.bucket_90_from = '[01] 0' and b.bucket_90_to <> '[06] Pay-off'
		then b.model_coef_adj / (1.0 - (1.0 - isnull(p.coef,1.0)) * isnull(st.koef_po,1.0))
	
	else b.model_coef_adj end
	) as od
	from Temp_PTS_Test_stg4_back_test_results a
	left join Temp_PTS_Test_for_back_test b
	on hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) = b.id1
	and a.mob_to = b.mob_to - 1
	and a.bucket_90_to = b.bucket_90_from

	left join Temp_PTS_Test_det_stress st
	--on b.mob_date_to between st.dt_from and st.dt_to
	on a.mob_date_to between st.dt_from and st.dt_to

	left join Temp_PTS_Test_det_pdp_coef p
	on a.segment_rbp = p.segment_rbp

	where a.mob_date_to = @incr_dt
	and a.flag_kk not like 'KK%'
	group by hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.segment_rbp, a.generation, a.flag_kk,
	b.mob_date_to,
	b.mob_to,
	a.bucket_90_to,
	b.bucket_90_to
	;



	---кредитные каникулы
	insert into riskdwh.risk.migr_matrix_monitoring

	select @vers as vers,
	eomonth(@model_date,-1) as date_on,
	cast(getdate() as datetime) as dt_dml,
	cast('MODEL' as varchar(100)) as kind,
	a.id1, a.term, a.segment_rbp, a.generation, a.flag_kk, 
	a.mob_date_to as r_date,
	a.mob_to as MoB,
	a.bucket_90_from as bucket_from,
	a.bucket_90_to as bucket_to,
	sum(isnull(a.model_od, 0)) as od
	from Temp_PTS_Test_stg_freeze_model a
	where a.mob_date_to = eomonth(@incr_dt,1)
	group by a.id1, a.term, a.segment_rbp, a.generation, a.flag_kk, 
	a.mob_date_to,
	a.mob_to,
	a.bucket_90_from,
	a.bucket_90_to
	;


	--нулевой MoB

	insert into riskdwh.risk.migr_matrix_monitoring

	select @vers as vers,
	eomonth(@model_date,-1) as date_on,
	cast(getdate() as datetime) as dt_dml,
	cast('MODEL' as varchar(100)) as kind, 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1, 
	a.term, a.segment_rbp, a.generation, a.flag_kk,
	a.generation as r_date,
	0 as MoB,
	'[00] New_volume' as bucket_from,
	'[01] 0' as bucket_to,
	isnull(sum(a.vl_rub_fact * (1.0 - ((1.0 - isnull(p.coef,1.0)) * isnull(st.koef_po,1.0)))), 0) as od
	from Temp_PTS_Test_virt_gens a
	left join Temp_PTS_Test_det_stress st
	on a.generation between st.dt_from and st.dt_to
	left join Temp_PTS_Test_det_pdp_coef p
	on a.segment_rbp = p.segment_rbp
	where a.generation = eomonth(@incr_dt,1)
	group by hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.segment_rbp, a.generation, a.flag_kk


	insert into riskdwh.risk.migr_matrix_monitoring

	select @vers as vers,
	eomonth(@model_date,-1) as date_on,
	cast(getdate() as datetime) as dt_dml,
	cast('MODEL' as varchar(100)) as kind, 
	hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)) as id1, 
	a.term, a.segment_rbp, a.generation, a.flag_kk,
	a.generation as r_date,
	0 as MoB,
	'[00] New_volume' as bucket_from,
	'[06] Pay-off' as bucket_to,
	isnull(sum(a.vl_rub_fact * ((1.0 - isnull(p.coef,1.0)) * isnull(st.koef_po,1.0))), 0) as od
	from Temp_PTS_Test_virt_gens a
	left join Temp_PTS_Test_det_stress st
	on a.generation between st.dt_from and st.dt_to
	left join Temp_PTS_Test_det_pdp_coef p
	on a.segment_rbp = p.segment_rbp
	where a.generation = eomonth(@incr_dt,1)
	group by hashbytes('MD2',concat(a.term, a.segment_rbp, a.generation, a.flag_kk)),
	a.term, a.segment_rbp, a.generation, a.flag_kk
	;




	set @incr_dt = eomonth(@incr_dt,1);


	end;

	set @vinfo = @vinfo_finish
									;
	exec dbo.prc$set_debug_info @src = @srcname, @info = @vinfo;



	----------------------------------------------------------------------------------------------------------------------------------

end try

begin catch

	if @@TRANCOUNT > 0 ROLLBACK TRANSACTION
	DECLARE @errmsg nvarchar(2048) = '*** ERROR '+ltrim(str(error_number()))+': '+error_message()+' line:'+ltrim(str(error_line()))
	exec RiskDWH.dbo.prc$set_debug_info @src = @srcname ,@info = @errmsg;
	RAISERROR (@errmsg, 16, 1)
	RETURN 55555

end catch
