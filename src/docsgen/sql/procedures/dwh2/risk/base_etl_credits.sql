
--exec [risk].[base_etl_credits] @isDebug = 1; 
CREATE PROC [risk].[base_etl_credits]
	@isDebug bit = 0
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
		,@msg NVARCHAR(255)
		,@subject NVARCHAR(255)

	BEGIN TRY

		DROP TABLE

		IF EXISTS #cred_cmr_status
			SELECT external_id
				,dt_status
				,STATUS
			INTO #cred_cmr_status
			FROM (
				SELECT b.Код AS external_id
					,dateadd(yy, - 2000, a.Период) AS dt_status
					,c.Наименование AS STATUS
					,ROW_NUMBER() OVER (
						PARTITION BY b.Код ORDER BY a.Период DESC
						) AS rn
				FROM stg._1cCMR.РегистрСведений_СтатусыДоговоров a
				INNER JOIN stg._1cCMR.Справочник_Договоры b ON a.Договор = b.Ссылка
				INNER JOIN stg._1cCMR.Справочник_СтатусыДоговоров c ON a.Статус = c.Ссылка
				WHERE b.ПометкаУдаления = 0x00
				) t
			WHERE rn = 1


		CREATE CLUSTERED INDEX cix_external_id ON #cred_cmr_status (external_id)

		DROP TABLE

		IF EXISTS #cred_cmr_startdate
			SELECT a.Договор AS credit_id
				,cast(dateadd(year, - 2000, min(ДатаВыдачи)) AS DATE) AS startdate
			INTO #cred_cmr_startdate
			FROM stg._1ccmr.Документ_ВыдачаДенежныхСредств a
			WHERE (a.Проведен = 0x01
				AND a.ПометкаУдаления = 0x00
				--Выдано prodsql02.cmr.dbo.Перечисление_СтатусыВыдачиДенежныхСредств
				AND a.Статус = 0xBB0F3EC282AA989A421CBFE2808BEB5F) 
				or a.Договор in ('25051523340087', '25051023319147')
			GROUP BY a.Договор

		CREATE CLUSTERED INDEX cix_credit_id ON #cred_cmr_startdate (credit_id)

		DROP TABLE

		IF EXISTS #cred_cmr_enddate
			SELECT credit_id
				,factenddate
			INTO #cred_cmr_enddate
			FROM (
				SELECT sd.Договор AS credit_id
					,dateadd(year, - 2000, sd.Период) AS factenddate
					,row_number() OVER (
						PARTITION BY sd.Договор ORDER BY sd.Период DESC
						) AS rn
				FROM stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
				INNER JOIN stg._1ccmr.Справочник_СтатусыДоговоров ssd ON ssd.Ссылка = sd.Статус
					AND ssd.Наименование IN (
						'Погашен'
						,'Продан'
						)
				) t
			WHERE t.rn = 1

		CREATE CLUSTERED INDEX cix_credit_id ON #cred_cmr_enddate (credit_id)

		DROP TABLE

		IF EXISTS #Int_rate_initial
			SELECT external_id
				,InitialRate
			INTO #Int_rate_initial
			FROM (
				SELECT a.Код AS external_id
					,iif(cast(p.ПроцентнаяСтавка AS INT) = 0, p.НачисляемыеПроценты, p.ПроцентнаяСтавка) AS InitialRate
					,row_number() OVER (
						PARTITION BY a.код ORDER BY p.Период ASC
						) AS rn
				FROM stg._1ccmr.Справочник_Договоры a
				LEFT JOIN STG._1Ccmr.РегистрСведений_ПараметрыДоговора p ON a.ССылка = p.Договор
				) t
			WHERE rn = 1

		CREATE CLUSTERED INDEX cix_external_id ON #Int_rate_initial (external_id)

		DROP TABLE

		IF EXISTS #curr_rate
			SELECT external_id
				,CurrRate
			INTO #curr_rate
			FROM (
				SELECT a.Код AS external_id
					,iif(cast(p.ПроцентнаяСтавка AS INT) = 0, p.НачисляемыеПроценты, p.ПроцентнаяСтавка) AS CurrRate
					,row_number() OVER (
						PARTITION BY a.код ORDER BY p.Период DESC
						) AS rn
				FROM stg._1ccmr.Справочник_Договоры a
				LEFT JOIN STG._1Ccmr.РегистрСведений_ПараметрыДоговора p ON a.ССылка = p.Договор
				) t
			WHERE t.rn = 1

		CREATE CLUSTERED INDEX cix_external_id ON #curr_rate (external_id)

		DROP TABLE

		IF EXISTS #loginom_src
			SELECT DISTINCT external_id
				,call_date
				,client_type_1
				,client_type_2
				,client_type
				,probation
			INTO #loginom_src
			FROM (
				SELECT DISTINCT cast(number AS VARCHAR) AS external_id
					,call_date
					,client_type_1
					,client_type_2
					/*
					по письму: Николай Фомин 2024-07-04 16:35
					необходимо скорректировать алгоритм определения типа клиента (CLIENT_TYPE) в сущности risk.credits, 
					т.к. в настоящее время по части клиентов он определяется некорректно 
					из-за отсутствия по клиентам заполненного поля CLIENT_TYPE_2. Что оказывает влияние на отчетность.
					В алгоритм определения типа клиента (CLIENT_TYPE) добавить источник CLIENT_TYPE_1 
					(из той же самой таблицы (Originationlog), что и значение CLIENT_TYPE_2
					из которого необходимо брать значение типа клиента при отсутствии информации в поле CLIENT_TYPE2.
					*/
					,client_type = isnull(client_type_2, client_type_1)
					,probation
					,ROW_NUMBER() OVER (
						PARTITION BY number ORDER BY call_date DESC
						) rn
				FROM stg._loginom.Originationlog
				WHERE call_date >= '20190901'
					AND call_date < cast(current_timestamp AS DATE)
					AND stage IN (
						'Call 1'
						,'Call 2'
						)
				) t
			WHERE rn = 1

		CREATE CLUSTERED INDEX cix_external_id ON #loginom_src (external_id)

		DROP TABLE

		IF EXISTS #cli_type
			SELECT a.Код AS external_id
				,CASE 
					WHEN b.client_type IS NULL
						AND dt.return_type IS NOT NULL
						AND dt.return_type = 'Параллельный'
						THEN 'Докредитование'
					WHEN b.client_type IS NULL
						AND dt.return_type IS NOT NULL
						AND dt.return_type <> 'Параллельный'
						THEN dt.return_type
					WHEN b.client_type IS NOT NULL
						AND b.client_type IN (
							'repeat'
							,'repeated'
							)
						THEN 'Повторный'
					WHEN b.client_type IS NOT NULL
						AND b.client_type IN (
							'parallel'
							,'docred'
							)
						THEN 'Докредитование'
					WHEN b.client_type IS NOT NULL
						AND b.client_type IN ('new')
						THEN 'Первичный'
					ELSE 'Первичный'
					END AS CLIENT_TYPE
			INTO #cli_type
			FROM stg._1ccmr.Справочник_Договоры a
			LEFT JOIN #loginom_src b ON b.external_id = a.Код
			--AND b.rn = 1
			LEFT JOIN RISK.REG_RETRORETURN_TYPE dt ON cast(dt.external_id AS VARCHAR) = a.код

		CREATE CLUSTERED INDEX cix_external_id ON #cli_type (external_id)

		DROP TABLE

		IF EXISTS #collateral_price_loginom;
			WITH src
			AS (
				SELECT DISTINCT cast(a.number AS VARCHAR) AS external_id
					,a.K_disk --коэффициент дисконтирования предмета залога
					,a.K_licv --коэффициент ликвидности предмета залога
					,ROW_NUMBER() OVER (
						PARTITION BY a.number ORDER BY call_date DESC
						) AS rn
				FROM stg._loginom.Originationlog a
				WHERE call_date >= '20200623'
					AND stage = 'Call 2'
				)
			SELECT external_id
				,K_disk
				,K_licv
			INTO #collateral_price_loginom
			FROM src
			WHERE rn = 1;

		CREATE CLUSTERED INDEX cix_external_id ON #collateral_price_loginom (external_id)

		DROP TABLE

		IF EXISTS #Credit_Lim;
			WITH src
			AS (
				SELECT cast(a.number AS VARCHAR) AS external_id
					,a.car_appraisal_value
					,a.Credit_limit
					,ROW_NUMBER() OVER (
						PARTITION BY a.number ORDER BY call_date DESC
						) AS rn
				FROM stg._loginom.Originationlog a
				WHERE a.stage = 'Call 4'
				)
			SELECT DISTINCT external_id
				,car_appraisal_value
				,Credit_limit
			INTO #Credit_Lim
			FROM src
			WHERE rn = 1;

		CREATE CLUSTERED INDEX cix_external_id ON #Credit_Lim (external_id)

		DROP TABLE

		IF EXISTS #Creditlimit_client;
			WITH src
			AS (
				SELECT cast(a.number AS VARCHAR) AS external_id
					,a.Credit_limit
					,ROW_NUMBER() OVER (
						PARTITION BY a.number ORDER BY call_date DESC
						) AS rn
				FROM stg._loginom.Originationlog a
				WHERE a.stage = 'Call 2'
				)
			SELECT DISTINCT external_id
				,Credit_limit
			INTO #Creditlimit_client
			FROM src
			WHERE rn = 1;

		CREATE CLUSTERED INDEX cix_external_id2 ON #Creditlimit_client (external_id)

		DROP TABLE

		IF EXISTS #restructuring
			SELECT number AS external_id
				,operation_type
				,min(period_start) AS dt_from --
				,max(period_end) AS dt_to --
				,count(1) AS cnt -- количество кредитных каникул
				,isnull(datediff(dd, min(period_start), max(period_end)) + 1, 0) AS DAYS --суммарное количество дней кредитных каникул
			INTO #restructuring
			FROM dbo.dm_restructurings
			WHERE operation_type IN (
					'Кредитные каникулы'
					,'Заморозка 1.0'
					)
			GROUP BY number
				,operation_type

		CREATE CLUSTERED INDEX cix_external_id ON #restructuring (external_id)

		DROP TABLE

		IF EXISTS #max_dpd_src
			SELECT ap.Договор
				,max(КоличествоПолныхДнейПросрочки) AS max_dpd
			INTO #max_dpd_src
			FROM Stg.dbo._1cАналитическиеПоказатели ap
			GROUP BY ap.Договор

		CREATE CLUSTERED INDEX cix_Договор ON #max_dpd_src (Договор)

		DROP TABLE

		IF EXISTS #act_pmt_sched
			SELECT external_id = Код
				,Дата = max(ДатаПлатежа)
			INTO #act_pmt_sched
			FROM dm.[CMRExpectedRepayments]
			GROUP BY Код

		CREATE CLUSTERED INDEX cix_Договор ON #act_pmt_sched (external_id)

		DROP TABLE

		IF EXISTS #is_probation;
			SELECT external_id = Код
				,iif(t.ИспытательныйСрок = 0x01, 1, 0) AS isprobation
			INTO #is_probation
			FROM dm.[CMRExpectedRepayments] t
			INNER JOIN #act_pmt_sched act_pmt_sched ON act_pmt_sched.external_id = t.Код
				AND act_pmt_sched.Дата = t.ДатаПлатежа

		CREATE CLUSTERED INDEX cix_external_id ON #is_probation (external_id);

		DROP TABLE

		IF EXISTS #cash_withdrawal;
			SELECT l.Код AS external_id
				,min(cwd.ДатаВыдачи) AS cash_withdrawal_date
			INTO #cash_withdrawal
			FROM stg._1ccmr.Документ_ВыдачаДенежныхСредств cwd
			INNER JOIN stg._1ccmr.Справочник_Договоры l ON cwd.Договор = l.Ссылка
			WHERE (cwd.Проведен = 0x01
				AND cwd.ПометкаУдаления = 0x00 
				AND cwd.Статус = 0xBB0F3EC282AA989A421CBFE2808BEB5F) --Выдано prodsql02.cmr.dbo.Перечисление_СтатусыВыдачиДенежныхСредств
				or l.Код in ('25051523340087', '25051023319147') 
			GROUP BY l.Код;




		DROP TABLE

		IF EXISTS #IsSelfPropelledTs;
			SELECT DISTINCT number
				,IsSelfPropelledTs
			INTO #IsSelfPropelledTs
			FROM stg._fedor.core_ClientRequest b
			INNER JOIN [Stg].[_fedor].[core_ClientAssetTs] c ON b.IdAsset = c.Id
				AND c.IsSelfPropelledTs = 1;

--Выделяем Большой Инстолмент для типа продукта --Kirichenko 09.10.25
drop table if exists #biginst_list;
select distinct number
into #biginst_list
from stg._loginom.Application
where productTypeCode = 'bigInstallment'
;
/*23-10-2025 А.Котелевец т.к. есть дубликаты в таблице */
drop table if exists #pdn 
;with pdn as (select 
	Number = cast(pdn.Number AS NVARCHAR(14))
	,pdn.pdn
	,nRow = ROW_NUMBER() over(partition by pdn.Number order by request_date desc, credit_exp desc)

from risk.pdn_calculation_2gen  pdn
)
select * 
	into #pdn
from pdn
where nRow = 1
create clustered index cxi_Number on #pdn (Number)

		DROP TABLE IF EXISTS #result;
			SELECT DISTINCT a.Код AS external_id
				,a.Ссылка AS credit_id
				,a.Клиент AS person_id
				,a.Сумма AS amount
				,a.Срок AS term
				,cast(iif(year(a.ДатаЗаявки) > 3000, dateadd(year, - 2000, a.ДатаЗаявки), iif(cast(a.ДатаЗаявки AS DATE) = '2001-01-01', iif(year(a.Дата) > 3000, dateadd(year, - 2000, a.Дата), a.Дата), a.ДатаЗаявки)) AS DATE) AS app_dt
				,ir.InitialRate
				,crt.CurrRate
				,s.startdate
				,cast(dateadd(m, datediff(m, 0, s.startdate), 0) AS DATE) AS generation
				,e.factenddate
				,iif(e.factenddate IS NULL, datediff(d, s.startdate, getdate()), NULL) AS dob
				,coalesce(so.Наименование, pp.Наименование) AS POS --на данных CRM
				,coalesce(mmz.Представление, 'Nan') AS channel --на данных МФО
				,cast(coalesce(crq.vin Collate Cyrillic_General_CI_AS, mz.vin) AS VARCHAR(200)) AS vin
				,isnull((
						CASE 
							WHEN coalesce(so.Наименование, pp.Наименование) IN (
									'Мобильное приложение'
									,'Личный кабинет клиента'
									)
								THEN coalesce(so.Наименование, pp.Наименование)
							ELSE coalesce(srp.Наименование, ppr.Наименование)
							END
						), 'Nan') AS rp
				,ct.client_type
				,CASE 
					when inst.Number is not null then 'bigInstallment'--Kirichenko 09.10.25
					WHEN upper(cmr_ПодтипыПродуктов.ИдентификаторMDS) = 'PDL' THEN 'PDL'
					WHEN upper(cmr_ПодтипыПродуктов.ИдентификаторMDS) = 'ACVTB' THEN 'AUTOCREDIT' --inserted 2025.06.18 A.Golitsyn
					WHEN a.IsInstallment = 1
						THEN 'INST'
					WHEN ipr.isprobation = 1
						THEN 'PTS_31'
					WHEN coalesce(so.Наименование, pp.Наименование) LIKE '%Партнер%3645%Рефинансирование%'
						THEN 'PTS_REFIN'
					when hub_ПодтипыПродуктов.ТипПродукта_Code = 'ptsLite' then 'pts' --22/12/25 kurikalov
					ELSE coalesce(hub_ПодтипыПродуктов.ТипПродукта_Code, 'pts') --22/12/25 kurikalov
					END credit_type
				,CASE 
					when inst.Number is not null then 'bigInstallment' --Kirichenko 09.10.25
					WHEN upper(cmr_ПодтипыПродуктов.ИдентификаторMDS) = 'PDL' THEN 'PDL'
					--inserted 2025.06.18 A.Golitsyn
					WHEN upper(cmr_ПодтипыПродуктов.ИдентификаторMDS) = 'ACVTB' THEN 'AUTOCREDIT'
					WHEN a.IsInstallment = 1
						THEN 'INST'
					WHEN lsrc.probation = 1
						THEN 'PTS_31'
					WHEN coalesce(so.Наименование, pp.Наименование) LIKE '%Партнер%3645%Рефинансирование%'
						THEN 'PTS_REFIN'
					ELSE 'PTS'
					END AS credit_type_init
				,cast(NULL AS DATE) AS probation_enddate --дата окончания испытательного срока
				,iif(a.IsInstallment = 1, 1, 0) AS IsInstallment
				,isnull(cpl.k_disk, mz.ДисконтАвто) AS k_disk
				,isnull(cpl.k_licv, sl.Ликвидность) AS k_licv
				,isnull(crq.TsMarketPrice, mz.РыночнаяСтоимостьАвтоНаМоментОценки) AS ts_marketprice
				,coalesce(clf.Car_Appraisal_Value, crq.CarEstimationPrice, /* k_disk*k_licv*ts_marketprice */ isnull(cpl.k_disk, mz.ДисконтАвто) * isnull(cpl.k_licv, sl.Ликвидность) * isnull(crq.TsMarketPrice, mz.РыночнаяСтоимостьАвтоНаМоментОценки)) AS ts_creditlimit
				,clc.Credit_limit AS creditlimit_client
				,coalesce(clf.Credit_limit, crq.ApprovedSum, mz.ОдобреннаяСуммаВерификаторами) AS creditlimit_fin
				,kk.dt_from AS kk_dt_from
				,kk.dt_to AS kk_dt_to
				,fr.dt_from AS freezing_dt_from
				,fr.dt_to AS freezing_dt_to
				,max(dateadd(year, - 2000, kob.Дата)) OVER (PARTITION BY kob.договор) AS pmt_delay_dt
				,mdpd.max_dpd
				,app.c1_apr_segment
				,app.rbp_gr as rbp_gr
				,app.cha_cha_segment as cha_cha_segment
				,pdn.pdn
				,a.PdlСрок as PDLTerm
				,ispt.IsSelfPropelledTs
				,getdate() AS dt_dml
			INTO #result
			FROM stg._1ccmr.Справочник_Договоры a
			INNER JOIN #cash_withdrawal cw ON cw.external_id  = a.Код
			INNER JOIN #cred_cmr_status cs ON cs.external_id = a.Код
				AND (cs.STATUS NOT IN ('Аннулирован','Зарегистрирован') or cs.external_id in ('25051523340087', '25051023319147'))
			LEFT JOIN risk.applications app ON app.number = a.Код
			LEFT JOIN stg._1cCMR.Справочник_Клиенты cl ON a.Клиент = cl.Ссылка
			LEFT JOIN stg._1cMFO.Документ_ГП_Заявка mz ON mz.Номер = a.Код
			LEFT JOIN Stg._1cCMR.Справочник_Заявка cmr_Заявка ON cmr_Заявка.Ссылка = a.Заявка
			LEFT JOIN stg._1cCMR.Справочник_ПодтипыПродуктов cmr_ПодтипыПродуктов ON cmr_Заявка.ПодтипПродукта = cmr_ПодтипыПродуктов.ссылка
			left join hub.v_hub_ГруппаПродуктов hub_ПодтипыПродуктов
				on cmr_ПодтипыПродуктов.ВнешнийGuid = hub_ПодтипыПродуктов.ПодтипПродуктd_ВнешнийGUID
			LEFT JOIN stg._1cMFO.Справочник_ГП_ЛиквидностьТС sl ON sl.Ссылка = mz.ЛиквидностьТС
			LEFT JOIN #Int_rate_initial ir ON ir.external_id = a.Код
			LEFT JOIN #curr_rate crt ON crt.external_id = a.Код
			LEFT JOIN #cred_cmr_startdate s ON s.credit_id = a.Ссылка
			LEFT JOIN #cred_cmr_enddate e ON e.credit_id = a.Ссылка
			LEFT JOIN #cli_type ct ON ct.external_id = a.код
			LEFT JOIN stg._1cCRM.Документ_ЗаявкаНаЗаймПодПТС crm ON crm.Номер = a.Код
			LEFT JOIN Stg._1cCRM.Справочник_Офисы so ON so.Ссылка = crm.Офис
			LEFT JOIN Stg._1cCRM.Справочник_Офисы srp ON srp.Ссылка = so.Родитель
			LEFT JOIN stg._1cMFO.Справочник_ГП_Офисы pp ON pp.Ссылка = mz.Точка
			LEFT JOIN stg._1cMFO.Справочник_ГП_Офисы ppr ON ppr.Ссылка = pp.Родитель
			LEFT JOIN stg._1cMFO.Перечисление_ГП_МестаСозданияЗаявки mmz ON mmz.Ссылка = mz.МестоСозданияЗаявки
			LEFT JOIN Stg._fedor.core_ClientRequest crq ON a.Код = crq.number Collate Cyrillic_General_CI_AS
			LEFT JOIN #collateral_price_loginom cpl ON cpl.external_id = a.Код
			LEFT JOIN #Credit_Lim clf ON clf.external_id = a.Код
			LEFT JOIN #restructuring kk ON kk.external_id = a.код
				AND kk.operation_type = 'Кредитные Каникулы'
			LEFT JOIN #restructuring fr ON fr.external_id = a.код
				AND fr.operation_type = 'Заморозка 1.0'
			LEFT JOIN Stg.[_1cCMR].[Документ_ОбращениеКлиента] kob ON kob.договор = a.Ссылка
				AND kob.ПометкаУдаления <> 0x01
				AND kob.ВидОперации = 0x9CB79B770BF013014F3165845D8CE72C
				AND kob.СледующаяДатаПлатежа <> '2001-01-01 00:00:00'
			LEFT JOIN #max_dpd_src mdpd ON mdpd.Договор = a.Ссылка
			LEFT JOIN #is_probation ipr ON ipr.external_id = a.Код
			LEFT JOIN #loginom_src lsrc ON lsrc.external_id = a.Код
			LEFT JOIN #Creditlimit_client clc ON clc.external_id = a.Код
			LEFT JOIN #pdn pdn ON pdn.Number = a.Код
			LEFT JOIN riskdwh.risk.stg_fcst_bus_cred dbl ON cast(dbl.external_id AS NVARCHAR(14)) = a.Код
			LEFT JOIN #IsSelfPropelledTs ispt ON a.Код = ispt.number collate Cyrillic_General_CI_AS
			left join #biginst_list inst on a.Код = inst.Number --Kirichenko 09.10.25
			WHERE cast(dbl.external_id AS NVARCHAR(14)) IS NULL;

		--probation_enddate - дата окончания испытательного срока
		WITH cte_to_update
		AS (
			SELECT a.external_id
				,a.probation_enddate
			FROM #result a
			WHERE a.credit_type = 'PTS'
				AND a.credit_type_init = 'PTS_31'
			)
			,min_probation_enddate
		AS (
			SELECT c.Код AS external_id
				,min(c.ДатаСоставленияГрафикаПлатежей) AS probation_enddate_upd
			FROM dm.CMRExpectedRepayments c
			WHERE iif(c.ИспытательныйСрок = 0x01, 1, 0) = 0
			GROUP BY c.Код
			)
		UPDATE t
		SET t.probation_enddate = m.probation_enddate_upd
		FROM cte_to_update t
		INNER JOIN min_probation_enddate m ON m.external_id = t.external_id;

		IF object_id('risk.credits') IS NULL
		BEGIN
			SELECT TOP (0) *
			INTO risk.credits
			FROM #result;

			CREATE UNIQUE INDEX uix_credits ON risk.credits (external_id);
		END
		if @isDebug = 1
		begin
			drop table if exists ##t_result
			select * 
			into ##t_result
			from #result
		end
		IF EXISTS (
				SELECT TOP (1) 1
				FROM #result
				)
		BEGIN
			BEGIN TRANSACTION

			DELETE FROM risk.credits;

			INSERT INTO risk.credits (
				[external_id]
				,[credit_id]
				,[person_id]
				,[amount]
				,[term]
				,[app_dt]
				,[InitialRate]
				,[CurrRate]
				,[startdate]
				,[generation]
				,[factenddate]
				,[dob]
				,[POS]
				,[channel]
				,[vin]
				,[rp]
				,[client_type]
				,[credit_type]
				,[credit_type_init]
				,[probation_enddate]
				,[IsInstallment]
				,[k_disk]
				,[k_licv]
				,[ts_marketprice]
				,[ts_creditlimit]
				,[creditlimit_client]
				,[creditlimit_fin]
				,[kk_dt_from]
				,[kk_dt_to]
				,[freezing_dt_from]
				,[freezing_dt_to]
				,[pmt_delay_dt]
				,[max_dpd]
				,[c1_apr_segment]
				,[rbp_gr]
				,[cha_cha_segment]
				,[pdn]
				,[dt_dml]
				,[PDLTerm]
				,[IsSelfPropelledTs]
				)
			SELECT distinct [external_id]
				,[credit_id]
				,[person_id]
				,[amount]
				,[term]
				,[app_dt]
				,[InitialRate]
				,[CurrRate]
				,[startdate]
				,[generation]
				,[factenddate]
				,[dob]
				,[POS]
				,[channel]
				,[vin]
				,[rp]
				,[client_type]
				,[credit_type]
				,[credit_type_init]
				,[probation_enddate]
				,[IsInstallment]
				,[k_disk]
				,[k_licv]
				,[ts_marketprice]
				,[ts_creditlimit]
				,[creditlimit_client]
				,[creditlimit_fin]
				,[kk_dt_from]
				,[kk_dt_to]
				,[freezing_dt_from]
				,[freezing_dt_to]
				,[pmt_delay_dt]
				,[max_dpd]
				,[c1_apr_segment]
				,[rbp_gr]
				,[cha_cha_segment]
				,[pdn]
				,[dt_dml]
				,[PDLTerm]
				,[IsSelfPropelledTs]
			FROM #result
			;
			insert into risk.credits_history
			select 
			*
			, getdate() as insertdate
			from risk.credits
			;
			COMMIT TRANSACTION
		END

		EXEC risk.set_debug_info @sp_name
			,'FINISH';
	END TRY

	BEGIN CATCH
		SET @msg = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
		SET @subject = CONCAT (
				'Ошибка выполнение процедуры '
				,@sp_name
				)

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		EXEC msdb.dbo.sp_send_dbmail @recipients = 'risk_team@carmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;
