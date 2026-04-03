
--exec [risk].[fill_pdn_calculation_gen2]
CREATE PROCEDURE [risk].[fill_pdn_calculation_gen2]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	EXEC risk.set_debug_info @sp_name
		,'START';

	BEGIN TRY

		-- изменение от 2021-08-06 соединение новой и старой таблицы по ПДН не по request date а по start_date
		-- изменение по start date некоторые кредиты не имеют его
		-- изменение от 2021-09-08 - источник договоров - ЦМР (Справочник_Договоры)
		-- изменение от 2021-09-08 - источник аннуитетного платежа - ЦМР (Документ_ГрафикПлатежей)
		-- изменение от 2021-09-08 - инкрементальное обновление, добавляются договоры с датой T-10, т.к зарегистированные могут в течение 5 дней выдаваться 
		-- изменение от 2022-12-28 - ограничение на нерасчет по сумме выдач менее 10к
		-- реестр договоров из ЦМР
		-- изменение от 2023-10-13 - изменение логики расчета платежа по своему кредиту выделил /*изменение от 2023-10-13 *//*конец изменение от 2023-10-13 */
		-- изменение от 2023-10-31 - изменение логики расчета платежа по своему кредиту (формула ЦБ) выделил /*изменение от 2023-10-31 *//*конец изменение от 2023-10-31 */
		-- округление ПДН в конце
		-- изменение от 2023-12-22 - Убрали фльтр cmr_cred на 10к, туда же, флаг сумма больше 10к, фильтр таблицы #final на то чтоб до 2024-01-01 туда не попадали кредиты менее 10к; новая таблица riskdwh.dbo.pdn_calculation_2gen_10k_plus
		-- изменение от 2023-12-28 - с 2024 средний доход больше 50к выдачи - минросстатанкета - меньше - 0.9*заявленный доход
		-- изменение от 2024-01-23 - Платеж по нашему PDL = платеж по ОД если он выдается с грейс периодом. изменения помечены /*изменение от 2024-01-24*/
		-- изменение от 2024-03-19 - по разъяснению от ЦБ - новинка от 2024.03.19  -- 2024.03.19
		-- изменение от 2024-12-05 - коэфф 095 к доходу на декабрь
		-- изменение от 2024-12-17 - коэфф 099 к доходу на декабрь
		-- изменение от 2025-07-08 - Добавлена модель дохода для Автокреда; убран кейс, когда берется БКИ доход (регуляторка); Добавлен признак сегмента без БКИ; Добавлен расход, указанный клиентом в анкете (для сегмента без БКИ) -- Кириченко Никита


		DROP TABLE

		IF EXISTS #cmr_cred;
			SELECT d.Ссылка
				,d.код AS external_id
				,dateadd(yy, - 2000, cast(d.Дата AS DATE)) AS credit_date
				,ssd.Наименование AS cred_status
				,[dbo].[getGUIDFrom1C_IDRREF]((d.Клиент)) AS CRMClientGuid
				,CASE 
					WHEN d.Сумма >= 10000
						THEN 1
					ELSE 0
					END AS flag_10k_plus
				,CASE 
					WHEN d.Сумма >= 50000
						THEN 1
					ELSE 0
					END AS flag_50k_plus
			INTO #cmr_cred
			FROM stg._1cCMR.Справочник_Договоры d
			LEFT JOIN (
				SELECT Договор
					,Статус
					,row_number() OVER (
						PARTITION BY Договор ORDER BY Период DESC
						) AS rn
				FROM stg._1cCMR.РегистрСведений_СтатусыДоговоров
				) sd ON sd.Договор = d.Ссылка
				AND sd.rn = 1
			LEFT JOIN stg._1cCMR.Справочник_СтатусыДоговоров ssd ON ssd.Ссылка = sd.Статус
			WHERE 1 = 1
				AND dateadd(yy, - 2000, cast(d.Дата AS DATE)) >= '2024-06-20' --дата начала расчета ПДН
				AND dateadd(yy, - 2000, cast(d.Дата AS DATE)) < cast(getdate() AS DATE)
				AND d.ПометкаУдаления = 0x00
				--зарегистрированы, но не выданы. В течение 5 дней могут (или нет) выдаваться; также исключаем аннулированные
				AND (isnull(ssd.Наименование, 'n') NOT IN ('Зарегистрирован', 'Аннулирован', 'n') or d.код in ('25051523340087', '25051023319147'))
				--Тестовые
				AND d.Ссылка NOT IN (0xA2C6005056839FE911EA6BF3E2A122E7, 0xA2CD005056839FE911EC0C382C953C8D)
				;


drop table if exists #reestr_autocred
select a.код as number, case when upper(cmr_ПодтипыПродуктов.ИдентификаторMDS) ='ACVTB' then 1 else 0 end as flag_autocred
into #reestr_autocred
from stg._1ccmr.Справочник_Договоры a 
LEFT JOIN Stg._1cCMR.Справочник_Заявка as cmr_Заявка ON cmr_Заявка.Ссылка = a.Заявка
LEFT JOIN stg._1cCMR.Справочник_ПодтипыПродуктов as cmr_ПодтипыПродуктов ON cmr_Заявка.ПодтипПродукта = cmr_ПодтипыПродуктов.ссылка	
where upper(cmr_ПодтипыПродуктов.ИдентификаторMDS) ='ACVTB'-- THEN 'AUTOCREDIT'
;

		--реестр Испытательный срок
		DROP TABLE

		IF EXISTS #isp_srok;
			SELECT DISTINCT cast(a.Number AS VARCHAR) AS external_id
			INTO #isp_srok
			FROM stg._loginom.Originationlog a
			WHERE a.probation = 1;

delete from #isp_srok where external_id --ошибка. Поиск в risk_team: "У 6 pdl на call 2 высвечивается probation = 1"
in 
('25102223808428',
'25102223809444',
'25101723796523',
'25102223808732',
'25102323810819',
'25102223808762')
;

		-- [X] Доход= МАКС ([A] Подтвержденный_доход; [B] Доход_БКИ; МИН ( [C] Росстат;  [D] Анкетный доход))
		-- ПДН = ([Е] Расход БКИ + [F] Текущий аннуитет)/  [X] Доход
		-- сбор исходных параметров из логином

				

	DROP TABLE IF EXISTS #no_bki;
			SELECT DISTINCT cast(a.Number AS VARCHAR) AS external_id
			INTO #no_bki
			FROM stg._loginom.Originationlog a
			WHERE 1=1
			and stage = 'Call 2'
			and needbki = 0;
		
		
drop table if exists #stg_pdn2_bki_i;

with q1 as
(
select 
a.number
, eqxAverageMonthlyIncomePdn as bki_income
, ROW_NUMBER() over (partition by a.number order by a.call_date desc) rown

from
stg._loginom.Origination_equifax_aggregates_4 as a
inner join #cmr_cred as b on a.number = b.external_id
where  eqxAverageMonthlyIncomePdn >0
)

select q1.number, q1.bki_income
into 
#stg_pdn2_bki_i
from q1
where q1.rown =1

;

drop table if exists #stg_pdn2_rsst;

with q1 as (

select a.number, rosstat_income, ROW_NUMBER() over (partition by a.number order by a.call_date desc) rown
from
stg._loginom.Originationlog as a
inner join #cmr_cred as b on a.number = b.external_id
where rosstat_income >0
)

select q1.number, q1.rosstat_income 
into #stg_pdn2_rsst
from 
q1
where q1.rown = 1



;

drop table if exists #stg_pdn2_inc_am;

with q1 as (
select a.number, a.application_income, a.income_amount, application_fact_region  
,  ROW_NUMBER() over (partition by a.number order by a.stage_date desc) rown
--select *
from 
stg._loginom.Application as a
inner join #cmr_cred as b on a.number = b.external_id
where (a.application_income>0 or a.income_amount  >0) and a.number is not null
)
select q1.number, q1.application_income, q1.income_amount, q1.application_fact_region  
into #stg_pdn2_inc_am
from
q1
where q1.rown = 1
;




drop table if exists #stg_pdn2_app_exp;

with q1 as (
select a.number, a.monthly_credit_payments 
,  ROW_NUMBER() over (partition by a.number order by a.stage_date desc) rown
from stg._loginom.[Application] as a
inner join #cmr_cred as b on a.number = b.external_id
where a.number is not null and a.monthly_credit_payments is not null
)
select q1.number, q1.monthly_credit_payments
into #stg_pdn2_app_exp
from
q1
where q1.rown = 1
;


drop table if exists #stg_pdn2_bki_e;

with q1 as (
select a.number, a.kbkiEqxAverageMonthlyPaymentTotalAmtPdn as bki_exp_amount, ROW_NUMBER() over (partition by a.number order by a.call_date desc) rown
from 
stg._loginom.Origination_kbkiEqxAggregates a
inner join #cmr_cred as b on a.number = b.external_id
where a.kbkiEqxAverageMonthlyPaymentTotalAmtPdn  >0
)

select q1.number, q1.bki_exp_amount
INTO #stg_pdn2_bki_e
from q1
where q1.rown = 1

-- 

			/*изменение от 2024-01-24*/
			-- определение PDL  с грейс периодом
			drop table if exists #stg_grace;

				select  
				a.код as external_id
				, 1 as flag_grace_period
				into #stg_grace
				from 
				stg._1cCMR.СПравочник_Договоры  as a
				where a.ПериодЛьготногоПогашения>0 and a.pdlсрок>0
				;

		-- Ожидаемый платеж по нашему кредиту [F] Текущий аннуитет
		--Примечания от Новикова Алексея:
		--Есть документ ГрафикПлатежей и связанный с ним регистр сведений ДанныеГрафикаПлатежей. 
		--Нужно из всех документов ГрафикПлатежей для конкретного договора взять тот, у которого Основанием будет документ ВыдачаДС. 
		--И уже из регистра взять строки связанные именно с этим графиком. Это и будет первичный график
		DROP TABLE

		IF EXISTS #stg1_pmt_graf;
			SELECT c.Ссылка AS cred_link
				,c.external_id
				,a.Ссылка AS graf_link
				,dateadd(yy, - 2000, cast(a.Дата AS DATETIME)) AS graf_date
				,ROW_NUMBER() OVER (
					PARTITION BY c.Ссылка ORDER BY a.Дата
					) AS rown_gr
			INTO #stg1_pmt_graf
			FROM stg._1cCMR.Документ_ГрафикПлатежей a
			INNER JOIN stg._1cCMR.Документ_ВыдачаДенежныхСредств b --основание "Выдача денежных средств" - основой график 
				ON a.Основание_Ссылка = b.ссылка
			INNER JOIN #cmr_cred c ON a.Договор = c.Ссылка
			WHERE 1 = 1
				AND a.ПометкаУдаления = 0x00
				AND a.Проведен = 0x01;

		DROP TABLE

		IF EXISTS #stg2_pmt_graf;
			SELECT a.cred_link
				,a.external_id
				,a.graf_link
				,a.graf_date
				,gr.Договор AS monthly_graf_cred_link
				,dateadd(yy, - 2000, cast(gr.ДатаПлатежа AS DATE)) AS pmt_date
				,gr.НомерСтроки AS nomer_stroki
				,cast(isnull(gr.ОД, 0) AS FLOAT) AS od
				,cast(isnull(gr.Процент, 0) AS FLOAT) AS interest
				,cast(isnull(gr.СуммаПлатежа, 0) AS FLOAT) AS payment
				,ROW_NUMBER() OVER (
					PARTITION BY a.cred_link ORDER BY gr.НомерСтроки
					) AS rown
			INTO #stg2_pmt_graf
			FROM #stg1_pmt_graf a
			INNER JOIN stg._1cCMR.РегистрСведений_ДанныеГрафикаПлатежей gr ON a.graf_link = gr.регистратор_ссылка
			WHERE a.rown_gr = 1 --выбираем первый график
				AND gr.Действует = 0x01 --действующие 
				;

		/*изменение от 2023-10-13 */
		DROP TABLE

		IF EXISTS #cred_cmr_startdate
			SELECT a.Договор AS credit_id
				,cast(dateadd(year, - 2000, min(ДатаВыдачи)) AS DATE) AS startdate
			INTO #cred_cmr_startdate
			FROM stg._1ccmr.Документ_ВыдачаДенежныхСредств a
			WHERE a.Проведен = 0x01
				AND a.ПометкаУдаления = 0x00
				--Выдано prodsql02.cmr.dbo.Перечисление_СтатусыВыдачиДенежныхСредств
				AND a.Статус = 0xBB0F3EC282AA989A421CBFE2808BEB5F
			GROUP BY a.Договор

		DROP TABLE

		--применение формулы ЦБ для расчета срока
		IF EXISTS #cred_cmr_payments
			SELECT a2.external_id
				,CASE 
					WHEN MAX(a2.pmt_date) > stdt.startdate
						THEN MAX(a2.pmt_date)
					ELSE stdt.startdate
					END AS latest_payment
				,SUM(a2.payment) AS payment_sum
				,stdt.startdate AS startdate
			INTO #cred_cmr_payments
			FROM #stg2_pmt_graf AS a2
			LEFT JOIN #cred_cmr_startdate AS stdt ON a2.cred_link = stdt.credit_id
			GROUP BY a2.external_id
				,stdt.startdate

		DROP TABLE

		IF EXISTS #cred2_cmr_payments
			SELECT ccp.external_id
				/*изменение от 2023-10-31 */
				,[payment_quantity] = CASE 
					WHEN DAY(ccp.latest_payment) > DAY(ccp.startdate)
						THEN MONTH(ccp.latest_payment) - MONTH(ccp.startdate) + 12 * YEAR(ccp.latest_payment) - 12 * YEAR(ccp.startdate) + 1
					ELSE MONTH(ccp.latest_payment) - MONTH(ccp.startdate) + 12 * YEAR(ccp.latest_payment) - 12 * YEAR(ccp.startdate)
					END
				/*конец изменение от 2023-10-31 */
				,ccp.payment_sum
			INTO #cred2_cmr_payments
			FROM #cred_cmr_payments AS ccp
				--GROUP BY ccp.external_id, ccp.payment_sum
				;

		--Итоговая таблица с аннуитетным платежом
		DROP TABLE

		IF EXISTS #stg_pdn_ann;
			WITH
				
			/*изменение от 2024-01-24*/
			pdl --платеж по ОД по которым активен грейс период 
			AS (
				SELECT a.external_id
					, a.od AS payment
				FROM #stg2_pmt_graf a
				inner join #stg_grace as g on g.external_id = a.external_id
				WHERE 
					a.rown =1
				)
			
			, regular --обычные договора (не исп.срок)
			AS (
				SELECT a.external_id
					,round(cast(a.payment_sum / a.payment_quantity AS FLOAT), 2) AS payment
				FROM #cred2_cmr_payments a
				WHERE NOT EXISTS (
						SELECT 1
						FROM #isp_srok b
						WHERE a.external_id = b.external_id
						)
						AND NOT EXISTS (
						SELECT 1
						FROM pdl b
						WHERE a.external_id = b.external_id
						)
				)
				,
				/*конец изменение от 2023-10-13 */
				--испытательный срок - график перестраивается каждый месяц, в зависимости от того, внес клиент платеж или нет
			ispsrok
			AS (
				SELECT a.external_id
					,max(a.payment) AS payment
				FROM #stg2_pmt_graf a
				WHERE EXISTS (
						SELECT 1
						FROM #isp_srok b
						WHERE a.external_id = b.external_id
						)
					AND a.rown <= 2
				GROUP BY a.external_id
				)
				,un
			AS (
				
				SELECT a.external_id
					,a.payment
				FROM pdl a
				
				UNION ALL

				SELECT a.external_id
					,a.payment
				FROM regular a
				
				UNION ALL
				
				SELECT a.external_id
					,a.payment
				FROM ispsrok a
				)
			SELECT un.external_id
				,un.payment
			INTO #stg_pdn_ann
			FROM un;
			
			
		-- собираем все вместе
		DROP TABLE

		IF EXISTS #stg_pdn3;
			SELECT DISTINCT a.external_id as number
				,a.credit_date AS request_date
				,inc_am.[application_fact_region]
				,cast(null as date) [reg_date_TS]
				,cast(null as varchar(50)) [position]
				,a.CRMClientGuid
				,isnull( case 
							when inc_am.Number = 24122422899002 then 540000 --костыль для человека, указавшего доход в 1 млрд руб 2025-03-26 Никита К
							when inc_am.Number = 24122422899304 then 540000 --костыль для человека, указавшего доход в 1 млрд руб 2025-03-26 Никита К
							else inc_am.[income_amount]
							end
							, 0) income_amount -- Доход со слов 
				,isnull(rsst.[rosstat_income], 0) rosstat_income --Доход по росстату
				,isnull(case
							when inc_am.Number = 25031103133500 then 176914.4 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133646 then 1416.61 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133762 then 79452.1 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133773 then 52910 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133808 then 262319.2 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133849 then 2200945.5 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133861 then 332944.3 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133870 then 8860.8 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133895 then 259682.8 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133924 then 316449.9 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133950 then 336306.1 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133955 then 727697.1 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134021 then 216733.4 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134022 then 67518.1 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134054 then 138612.5 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134060 then 380980.6 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134099 then 384332 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134101 then 132566.2 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134167 then 143384.8 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134354 then 43810 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134269 then 251382.3 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134196 then 30495.4 --костыль для ошибок в БКИ 2025-05-26 Никита К
				else bki_i.[bki_income] end
				, 0) bki_income --Доход по КИ
				,isnull( case 
							/*		
							when a.Number = 24020701748120 then 250000 --костыль для залог не транспорт 2024.03.19
							when a.Number = 24022201797450 then 200000 --костыль для залог не транспорт 2024.03.19
							*/
							--Ошибка в коде нет таблицы в алиасом a, скорее всего речь идет об  таблице app_i 
							--Котелевец А.В. 20.03
							when inc_am.Number = 24020701748120 then 250000 --костыль для залог не транспорт 2024.03.19
							when inc_am.Number = 24022201797450 then 200000 --костыль для залог не транспорт 2024.03.19
							when inc_am.Number = 24121802875443 then 250000 --костыль для самоходки 2025-03-26 Никита К
							when inc_am.Number = 24122302893441 then 250000 --костыль для самоходки 2025-03-26 Никита К
							when inc_am.Number = 25101403787337 then 163694.67 --Не пришел доход с источника
							else inc_am.[application_income]
							end
							, 0) application_income -- Подтвержденный доход по документам
				,isnull(case
							when inc_am.Number = 25031103133500 then 136088 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133646 then 10897 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133762 then 61117 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133773 then 40700 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133808 then 201784 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133849 then 1693035 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133861 then 256111 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133870 then 6816 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133895 then 199756 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133924 then 243423 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133950 then 258697 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203133955 then 559767 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134021 then 166718 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134022 then 51937 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134054 then 106625 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134060 then 293062 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134099 then 295640 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134101 then 101974 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134167 then 110296 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134354 then 33700 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134269 then 193371 --костыль для ошибок в БКИ 2025-05-26 Никита К
							when inc_am.Number = 25031203134196 then 23458 --костыль для ошибок в БКИ 2025-05-26 Никита К
				else bki_e.[bki_exp_amount] end
				, 0) bki_exp_amount -- затраты бки
				,isnull(ann.payment, 0) credit_exp -- средний аннуитет по выданному нами кредиту
				,[min_rosstat_anketa] = CASE 
					WHEN isnull(rsst.[rosstat_income], 0) < isnull(inc_am.[income_amount], 0)
						THEN isnull(rsst.[rosstat_income], 0)
					ELSE isnull(inc_am.[income_amount], 0)
					END -- Минимум 
				,[call_verified_income] = cast(NULL AS FLOAT) --z.[ДоходПодтвержденныйПоТелефону] --Подтвержденный доход по звонку работодателю -- не используется после 31.07.2021 предписания ЦБ 
				,[reg_income] = cast(NULL AS FLOAT) --z.[ДоходРаботаЯндекс] --Подтвержденный доход по оценке из региона проживания и должности -- не используется после 31.07.2021 предписания ЦБ 
				,isnull(reestr_autocred.flag_autocred, 0) as flag_autocred
				,isnull(app_exp.monthly_credit_payments , 0) app_exp --затраты, указанные в анкете для сегмента без БКИ
				, case when no_bki.external_id is not null then 1 else 0 end as no_bki_flag
			INTO #stg_pdn3
			FROM #cmr_cred a
			-- компоненты расчета
			LEFT JOIN #stg_pdn_ann AS ann ON ann.external_id = a.external_id
			LEFT JOIN #stg_pdn2_rsst AS rsst ON rsst.Number = a.external_id
			LEFT JOIN #stg_pdn2_bki_i AS bki_i ON bki_i.Number = a.external_id
			LEFT JOIN #stg_pdn2_bki_e AS bki_e ON bki_e.Number = a.external_id
			LEFT JOIN #stg_pdn2_inc_am AS inc_am ON inc_am.Number = a.external_id
			LEFT JOIN #stg_pdn2_app_exp AS app_exp ON app_exp.Number = a.external_id
			Left join #reestr_autocred as reestr_autocred on a.external_id = reestr_autocred.number
			left join #no_bki as no_bki on a.external_id = no_bki.external_id
			;
			


/*
		-- считаем средний доход
		DROP TABLE IF EXISTS #stg_pdn4;
			SELECT a.*
				,[avg_income] = -- ищем максимум из be.application_income  be.[bki_income]  be.min_rosstat_anketa  -- Доход= МАКС (Подтвержденный_доход; Доход_БКИ; МИН (Росстат; Анкетный доход))
				--новинка от 28.12.2023
				case 
				when cr.credit_date >'2023-12-31' 
				then
					case 
					when cr.flag_50k_plus = 1
					then -- новинка от 2024.03.19
						case 
							when a.application_income > 0 then a.application_income
							when a.bki_income > a.income_amount then a.income_amount
							when a.bki_income > a.rosstat_income then a.bki_income
							when a.bki_income <= a.rosstat_income then a.min_rosstat_anketa
						end
					else a.income_amount* 
					-- изменение от 2024-12-05
					--case when a.request_date >='2025-01-01' then 0.9
					--						when a.request_date >='2024-12-01' then 0.99
					--						else 0.9 end
					-- .изменение от 2024-12-05
					-- изменение от 2025-03-26
					case when a.request_date >='2025-01-01' then 0.9
						 else 0.9 end
					-- изменение от 2025-03-26
					end
				else
				--конец новинки

					CASE 
						WHEN a.application_income >= a.[bki_income]
							AND a.application_income >= a.min_rosstat_anketa
							THEN a.application_income
						WHEN a.[bki_income] >= a.application_income
							AND a.[bki_income] >= a.min_rosstat_anketa
							THEN a.[bki_income]
						WHEN a.min_rosstat_anketa >= a.application_income
							AND a.min_rosstat_anketa >= a.[bki_income]
							THEN a.min_rosstat_anketa
					END
				end
			INTO #stg_pdn4
			FROM #stg_pdn3 AS a
			LEFT JOIN #cmr_cred cr ON cr.external_id = a.Number
*/


-- считаем средний доход (регуляторка с 01.07.2025: нельзя брать БКИ доход + отдельная модель для автокреда)
		DROP TABLE IF EXISTS #stg_pdn4; 
			SELECT a.*
				,[avg_income] =
				case when cr.credit_date >'2023-12-31' then 
					case when a.flag_autocred = 1 then case when a.application_income > 0 then a.application_income when a.income_amount < case when a.rosstat_income > a.bki_income*10 then a.rosstat_income else a.bki_income*10 end then a.income_amount else case when a.rosstat_income > a.bki_income*10 then a.rosstat_income else a.bki_income*10 end end  --min(a.income_amount,max(a.rosstat_income,a.bki_income*10))
						else case when cr.flag_50k_plus = 1 then
							case when a.application_income > 0 then a.application_income
							else a.min_rosstat_anketa
							end
						else a.income_amount*0.9 
						end
					end
				else case	
						WHEN a.application_income >= a.[bki_income]
							AND a.application_income >= a.min_rosstat_anketa
							THEN a.application_income
						WHEN a.[bki_income] >= a.application_income
							AND a.[bki_income] >= a.min_rosstat_anketa
							THEN a.[bki_income]
						WHEN a.min_rosstat_anketa >= a.application_income
							AND a.min_rosstat_anketa >= a.[bki_income]
							THEN a.min_rosstat_anketa
					END
				end
			INTO #stg_pdn4
			FROM #stg_pdn3 AS a
			LEFT JOIN #cmr_cred cr ON cr.external_id = a.Number
			;
		

		-- Считаем итоговый ПДН, обходим статичные (ручные) ПДН, и придаем старый вид
		DROP TABLE

		IF EXISTS #stg_pdn5;
			SELECT s.[Number]
				,s.request_date
				,s.[application_fact_region]
				,s.[reg_date_TS]
				,s.[position]
				,s.[income_amount]
				,s.[rosstat_income]
				,s.[bki_income]
				,s.[application_income]
				,s.[call_verified_income]
				,s.[reg_income]
				,s.[avg_income]
				,s.[bki_exp_amount]
				,s.[credit_exp]
				,[pdn] = round(CASE 
						WHEN s.[avg_income] > 0
							THEN (case when s.[no_bki_flag] = 1 then s.[app_exp] else s.[bki_exp_amount] end + s.[credit_exp]) / s.[avg_income]
						ELSE NULL
						END, 3)
				,s.[CRMClientGuid]
				,[InsertedDate] = SYSDATETIME()
				, s.[app_exp] as exp_amount
				, case when s.no_bki_flag = 1 then 0 else 1 end as need_bki
				, case 
					when s.request_date >= '2025-07-01' then 
						case
						when reestr_autocred.number is not null then 
							case
							when s.[avg_income]  = s.[application_income] then 3 else 12 
							end
						else 
							case
							when s.[avg_income]  = s.[application_income] then 3
							when s.[avg_income]  = s.[rosstat_income] then 13
							else 12 
							end
						end
					else 
						case
						when reestr_autocred.number is not null then 
							case
							when s.[avg_income]  = s.[application_income] then 3 else 12 
							end
						else 
							case
							when s.[avg_income]  = s.[application_income] then 3
							when s.[avg_income]  = s.[rosstat_income] then 13
							when s.[avg_income]  = s.[bki_income] then 15
							else 12 
							end
						end
					end as inc_src_cbr
			INTO #stg_pdn5
			FROM #stg_pdn4 s
			Left join #reestr_autocred as reestr_autocred on s.[Number] = reestr_autocred.number
			;

			

		-- ручные ПДН -- тут предписания и прочие исправления
		--where 
		--[Number] not in (select number from dbo.pdn_static_values)
		-- конец всех рассчетов -- работает 60-70 сек, 1409 записей в исходной логином таблице 2021-07-28
		-- дольше всего работает график и фильтр на неаннулированные договора
		DROP TABLE

		IF EXISTS #final;
			SELECT a.*
			INTO #final
			FROM #stg_pdn5 AS a
			LEFT JOIN #cmr_cred AS c ON c.external_id = a.number
			WHERE --a.request_date BETWEEN dateadd(dd, - 10, cast(getdate() AS DATE)) AND dateadd(dd, - 1, cast(getdate() AS DATE)) --убираю логику чтобы долить недостающие сделки
						--в РегистраторСведений есть график 
				--AND 
				EXISTS (
					SELECT 1
					FROM #stg_pdn_ann b
					WHERE cast(a.number AS VARCHAR) = b.external_id
						AND b.payment > 0
					)
				AND (
					c.flag_10k_plus = 1
					OR c.credit_date >= '2024-01-01'
					) --готовимся что с НГ будут считаться все ПДН
				;


		--инкремент T-10
		MERGE INTO risk.pdn_calculation_2gen dst
		USING #final src
			ON (dst.Number = src.Number)
		WHEN NOT MATCHED
			THEN
				INSERT (
					Number
					,request_date
					,application_fact_region
					,reg_date_TS
					,position
					,income_amount
					,rosstat_income
					,bki_income
					,application_income
					,call_verified_income
					,reg_income
					,avg_income
					,bki_exp_amount
					,credit_exp
					,pdn
					,CRMClientGUID
					,InsertedDate
					,exp_amount
					,need_bki
					,inc_src_cbr
					)
				VALUES (
					src.Number
					,src.request_date
					,src.application_fact_region
					,src.reg_date_TS
					,src.position
					,src.income_amount
					,src.rosstat_income
					,bki_income
					,src.application_income
					,src.call_verified_income
					,src.reg_income
					,src.avg_income
					,src.bki_exp_amount
					,src.credit_exp
					,src.pdn
					,src.CRMClientGUID
					,src.InsertedDate
					,src.exp_amount
					,src.need_bki
					,src.inc_src_cbr
					);


		EXEC risk.set_debug_info @sp_name
			,'FINISH';
	END TRY

	BEGIN CATCH
		DECLARE @msg NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		DECLARE @subject NVARCHAR(255) = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =  'Тимур Сулейманов <t.sulejmanov@carmoney.ru>; Александр Голицын <a.golicyn@carmoney.ru>'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;


		throw 51000
			,@msg
			,1
	END CATCH
END
