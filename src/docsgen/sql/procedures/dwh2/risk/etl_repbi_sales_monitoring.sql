
--exec [risk].[etl_repbi_sales_monitoring];
CREATE PROCEDURE [risk].[etl_repbi_sales_monitoring]
AS
BEGIN
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)

	BEGIN TRY
		DROP TABLE

		IF EXISTS #issued;
			WITH src
			AS (
				SELECT o.number AS external_id
					,isnull(datediff(year, birth_date, call_date) -
					case
						when month(Birth_date) < month(call_date)
						then 0
						when month(Birth_date) > month(call_date)
						then 1
						when day(Birth_date) > day(call_date)
						then 1
						else 0
					end,years) as years
					,gender
					,region
					,ROW_NUMBER() OVER (
						PARTITION BY o.number ORDER BY call_date DESC
						) AS rn
				FROM [stg].[_loginom].[Originationlog] o
				WHERE stage = 'Call 2'
				)
			SELECT a.external_id
				,a.amount
				,a.startdate
				,a.initialrate
				,a.client_type
				,a.credit_type_init
				,a.rbp_gr
				,s.Years
				,s.gender
				,s.region
			INTO #issued
			FROM risk.credits a
			LEFT JOIN src s
				ON s.external_id = a.external_id
					AND s.rn = 1
			WHERE a.startdate >= dateadd(mm, - 1, cast(dateadd(m, datediff(m, 0, dateadd(dd,-1, getdate())), 0) AS DATE))
			    AND a.startdate < cast(getdate() as date)
				AND a.external_id NOT IN ('19061300000088', '20101300041806', '21011900071506', '21011900071507');



		DROP TABLE

		IF EXISTS #issued_group
			SELECT external_id
				,amount
				,startdate
				,initialrate
				,client_type
				,credit_type_init
				,RBP_GR
				,CASE 
					WHEN credit_type_init = 'INST'
						THEN '9. INSTALLMENT'
					WHEN credit_type_init = 'PTS_REFIN'
						THEN '7. ПТС_РЕФИН'
					WHEN credit_type_init = 'PTS_31'
						THEN '8. ПТС_Испытательный срок'
					WHEN client_type = 'Докредитование' AND credit_type_init <> 'PDL'
						THEN '5. ПТС_ДОКРЕДЫ'
					WHEN client_type = 'Повторный' AND credit_type_init <> 'PDL'
						THEN '6. ПТС_ПОВТОРНЫЕ'
					WHEN (
							client_type = 'Первичный'
							AND RBP_GR = 'RBP 1'
							AND credit_type_init <> 'PDL'
							)
						THEN '1. ПТС_НОВЫЕ_RBP_1'
					WHEN (
							client_type = 'Первичный'
							AND RBP_GR = 'RBP 2'
							AND credit_type_init <> 'PDL'
							)
						THEN '2. ПТС_НОВЫЕ_RBP_2'
					WHEN (
							client_type = 'Первичный'
							AND RBP_GR = 'RBP 3'
							AND credit_type_init <> 'PDL'
							)
						THEN '3. ПТС_НОВЫЕ_RBP_3'
					WHEN (
							client_type = 'Первичный'
							AND RBP_GR = 'RBP 4'
							AND credit_type_init <> 'PDL'
							)
						THEN '4. ПТС_НОВЫЕ_RBP_4'
					WHEN credit_type_init = 'PDL'
						THEN '10. PDL'
					END AS price_group
				,CASE 
					WHEN cast(startdate AS DATE) = dateadd(day, - 2, cast(current_timestamp AS DATE))
						THEN '03. LD'
					WHEN cast(startdate AS DATE) = dateadd(day, - 1, cast(current_timestamp AS DATE))
						THEN '04. CD'
					END AS period_d
				,CASE 
					WHEN (
							startdate >= dateadd(mm, - 1, cast(dateadd(m, datediff(m, 0, dateadd(dd,-1, getdate())), 0) AS DATE))
							AND startdate <= dateadd(dd, - 1, cast(dateadd(m, datediff(m, 0, dateadd(dd,-1, getdate())), 0) AS DATE))
							)
						THEN '01. LM'
					WHEN startdate > dateadd(dd, - 1, cast(dateadd(m, datediff(m, 0, dateadd(dd,-1, getdate())), 0) AS DATE))
						THEN '02. CM'
					END AS period_m
				,CASE 
					WHEN years < 25
						THEN 'До 25 лет'
					WHEN years BETWEEN 25
							AND 29
						THEN '25-30 лет'
					WHEN years BETWEEN 30
							AND 34
						THEN '30-35 лет'
					WHEN years BETWEEN 35
							AND 39
						THEN '35-40 лет'
					WHEN years BETWEEN 40
							AND 49
						THEN '40-50 лет'
					WHEN years BETWEEN 50
							AND 59
						THEN '50-60 лет'
					WHEN years >= 60
						THEN 'более 60 лет'
					END AS age_group
				,gender
				,region
			INTO #issued_group
			FROM #issued;

		--select distinct startdate, period_m, period_d from #issued_group order by 1 desc;

		IF object_id('risk.repbi_sales_monitoring') IS NOT NULL
			TRUNCATE TABLE risk.repbi_sales_monitoring;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT price_group
			,period_d AS period
			,count(external_id) AS value
			,'cnt' AS metric
		FROM #issued_group
		WHERE period_d IS NOT NULL
		GROUP BY price_group
			,period_d
		
		UNION
		
		SELECT price_group
			,period_m AS period
			,count(external_id) AS value
			,'cnt' AS metric
		FROM #issued_group
		WHERE period_m IS NOT NULL
		GROUP BY price_group
			,period_m;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT price_group
			,period_d AS period
			,sum(amount) AS value
			,'sum' AS metric
		FROM #issued_group
		WHERE period_d IS NOT NULL
		GROUP BY price_group
			,period_d
		
		UNION
		
		SELECT price_group
			,period_m AS period
			,sum(amount) AS value
			,'sum' AS metric
		FROM #issued_group
		GROUP BY price_group
			,period_m;

		--
		--ForWeigAvgRate
		INSERT INTO risk.repbi_sales_monitoring
		SELECT price_group
			,period_d AS period
			,sum(cast(isnull(replace(amount, ',', '.'), 0) AS FLOAT) * cast(isnull(replace(initialrate, ',', '.'), 0) AS FLOAT)) / sum(cast(isnull(replace(amount, ',', '.'), 0) AS FLOAT)) AS value
			,'AVGRATE_GROUP' AS metric
		FROM #issued_group
		WHERE period_d IS NOT NULL
		GROUP BY price_group
			,period_d
		
		UNION
		
		SELECT price_group
			,period_m AS period
			,sum(cast(isnull(replace(amount, ',', '.'), 0) AS FLOAT) * cast(isnull(replace(initialrate, ',', '.'), 0) AS FLOAT)) / sum(cast(isnull(replace(amount, ',', '.'), 0) AS FLOAT)) AS value
			,'AVGRATE_GROUP' AS metric
		FROM #issued_group
		GROUP BY price_group
			,period_m;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT 'ИТОГО:' AS price_group
			,period_d AS period
			,sum(cast(isnull(replace(amount, ',', '.'), 0) AS FLOAT) * cast(isnull(replace(initialrate, ',', '.'), 0) AS FLOAT)) / sum(cast(isnull(replace(amount, ',', '.'), 0) AS FLOAT)) AS value
			,'AVGRATE_GROUP' AS metric
		FROM #issued_group
		WHERE period_d IS NOT NULL
		GROUP BY period_d
		
		UNION
		
		SELECT 'ИТОГО:' AS price_group
			,period_m AS period
			,sum(cast(isnull(replace(amount, ',', '.'), 0) AS FLOAT) * cast(isnull(replace(initialrate, ',', '.'), 0) AS FLOAT)) / sum(cast(isnull(replace(amount, ',', '.'), 0) AS FLOAT)) AS value
			,'AVGRATE_GROUP' AS metric
		FROM #issued_group
		GROUP BY period_m;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT price_group
			,period_d AS period
			,sum(amount) / cast(count(external_id) AS FLOAT) AS value
			,'avg_amnt' AS metric
		FROM #issued_group
		WHERE period_d IS NOT NULL
		GROUP BY price_group
			,period_d
		
		UNION
		
		SELECT price_group
			,period_m AS period
			,sum(amount) / cast(count(external_id) AS FLOAT) AS value
			,'avg_amnt' AS metric
		FROM #issued_group
		GROUP BY price_group
			,period_m;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT 'ИТОГО:' AS price_group
			,period_d AS period
			,sum(amount) / cast(count(external_id) AS FLOAT) AS value
			,'avg_amnt' AS metric
		FROM #issued_group
		WHERE period_d IS NOT NULL
		GROUP BY period_d
		
		UNION
		
		SELECT 'ИТОГО:' AS price_group
			,period_m AS period
			,sum(amount) / cast(count(external_id) AS FLOAT) AS value
			,'avg_amnt' AS metric
		FROM #issued_group
		GROUP BY period_m;

		--Распределение по полу заемщика, %
		WITH src
		AS (
			SELECT period_d AS period
				,count(*) AS cnt_all
			FROM #issued_group
			WHERE gender IS NOT NULL
				AND period_d IS NOT NULL
			GROUP BY period_d
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_d AS period
			,count(external_id) / cast(avg(s.cnt_all) AS FLOAT) AS value
			,'gender' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_d
		WHERE gender IS NOT NULL
			AND period_d IS NOT NULL
		GROUP BY gender
			,period_d;

		WITH src
		AS (
			SELECT period_m AS period
				,count(*) AS cnt_all
			FROM #issued_group
			WHERE gender IS NOT NULL
			GROUP BY period_m
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_m AS period
			,count(external_id) / cast(avg(s.cnt_all) AS FLOAT) AS value
			,'gender' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_m
		WHERE gender IS NOT NULL
		GROUP BY gender
			,period_m;

		--Распределение по полу заемщика, шт
		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_d AS period
			,count(external_id) AS value
			,'gender_cnt' AS metric
		FROM #issued_group
		WHERE gender IS NOT NULL
			AND period_d IS NOT NULL
		GROUP BY gender
			,period_d;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_m AS period
			,count(external_id) AS value
			,'gender_cnt' AS metric
		FROM #issued_group
		WHERE gender IS NOT NULL
		GROUP BY gender
			,period_m;
	    
		INSERT INTO risk.repbi_sales_monitoring
		SELECT 'ИТОГО:'
			,period_d AS period
			,count(external_id) AS value
			,'gender_cnt' AS metric
		FROM #issued_group
		WHERE gender IS NOT NULL
			AND period_d IS NOT NULL
		GROUP BY period_d;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT 'ИТОГО:'
			,period_m AS period
			,count(external_id) AS value
			,'gender_cnt' AS metric
		FROM #issued_group
		WHERE gender IS NOT NULL
		GROUP BY period_m;

		--Распределение по полу заемщика, % руб
		WITH src
		AS (
			SELECT period_d AS period
				,sum(amount) AS amnt_all
			FROM #issued_group
			WHERE gender IS NOT NULL
				AND period_d IS NOT NULL
			GROUP BY period_d
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_d AS period
			,sum(amount) / cast(avg(s.amnt_all) AS FLOAT) AS value
			,'gender_amnt' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_d
		WHERE gender IS NOT NULL
			AND period_d IS NOT NULL
		GROUP BY gender
			,period_d;

		WITH src
		AS (
			SELECT period_m AS period
				,sum(amount) AS amnt_all
			FROM #issued_group
			WHERE gender IS NOT NULL
			GROUP BY period_m
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_m AS period
			,sum(amount) / cast(avg(s.amnt_all) AS FLOAT) AS value
			,'gender_amnt' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_m
		WHERE gender IS NOT NULL
		GROUP BY gender
			,period_m;

		--Распределение по возрасту заемщика, %
		WITH src
		AS (
			SELECT period_d AS period
				,count(*) AS cnt_all
			FROM #issued_group
			WHERE age_group IS NOT NULL
				AND period_d IS NOT NULL
			GROUP BY period_d
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_d AS period
			,count(external_id) / cast(avg(s.cnt_all) AS FLOAT) AS value
			,'age_group' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_d
		WHERE age_group IS NOT NULL
			AND period_d IS NOT NULL
		GROUP BY age_group
			,period_d;

		WITH src
		AS (
			SELECT period_m AS period
				,count(*) AS cnt_all
			FROM #issued_group
			WHERE age_group IS NOT NULL
			GROUP BY period_m
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_m AS period
			,count(external_id) / cast(avg(s.cnt_all) AS FLOAT) AS value
			,'age_group' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_m
		WHERE age_group IS NOT NULL
		GROUP BY age_group
			,period_m;

		--Распределение по возрасту заемщика, % руб
		WITH src
		AS (
			SELECT period_d AS period
				,sum(amount) AS amnt_all
			FROM #issued_group
			WHERE age_group IS NOT NULL
				AND period_d IS NOT NULL
			GROUP BY period_d
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_d AS period
			,sum(amount) / cast(avg(s.amnt_all) AS FLOAT) AS value
			,'age_group_amnt' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_d
		WHERE age_group IS NOT NULL
			AND period_d IS NOT NULL
		GROUP BY age_group
			,period_d;

		WITH src
		AS (
			SELECT period_m AS period
				,sum(amount) AS amnt_all
			FROM #issued_group
			WHERE age_group IS NOT NULL
			GROUP BY period_m
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_m AS period
			,sum(amount) / cast(avg(s.amnt_all) AS FLOAT) AS value
			,'age_group_amnt' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_m
		WHERE age_group IS NOT NULL
		GROUP BY age_group
			,period_m;

		--Распределение по возрасту заемщика, шт
		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_d AS period
			,count(external_id) AS value
			,'age_group_cnt' AS metric
		FROM #issued_group
		WHERE age_group IS NOT NULL
			AND period_d IS NOT NULL
		GROUP BY age_group
			,period_d;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_m AS period
			,count(external_id)  AS value
			,'age_group_cnt' AS metric
		FROM #issued_group
		WHERE age_group IS NOT NULL
		GROUP BY age_group
			,period_m;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT 'ИТОГО:'
			,period_d AS period
			,count(external_id)  AS value
			,'age_group_cnt' AS metric
		FROM #issued_group
		WHERE age_group IS NOT NULL
			AND period_d IS NOT NULL
		GROUP BY period_d;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT 'ИТОГО:'
			,period_m AS period
			,count(external_id) AS value
			,'age_group_cnt' AS metric
		FROM #issued_group
		WHERE age_group IS NOT NULL
		GROUP BY period_m;



		--Распределение по полу и возрасту, %
		--мужчины
		WITH src
		AS (
			SELECT period_d AS period
				,count(*) AS cnt_all
			FROM #issued_group
			WHERE gender IS NOT NULL
				AND period_d IS NOT NULL
			GROUP BY period_d
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_d AS period
			,count(external_id) / cast(avg(s.cnt_all) AS FLOAT) AS value
			,'gender_age_man' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_d
		WHERE gender = 'Мужской'
			AND period_d IS NOT NULL
		GROUP BY gender
			,period_d;

		WITH src
		AS (
			SELECT period_m AS period
				,count(*) AS cnt_all
			FROM #issued_group
			WHERE gender IS NOT NULL
			GROUP BY period_m
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_m AS period
			,count(external_id) / cast(avg(s.cnt_all) AS FLOAT) AS value
			,'gender_age_man' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_m
		WHERE gender = 'Мужской'
		GROUP BY gender
			,period_m;

		WITH src
		AS (
			SELECT period_d AS period
				,count(*) AS cnt_all
			FROM #issued_group
			WHERE age_group IS NOT NULL
				AND period_d IS NOT NULL
			GROUP BY period_d
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_d AS period
			,count(external_id) / cast(avg(s.cnt_all) AS FLOAT) AS value
			,'gender_age_man' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_d
		WHERE age_group IS NOT NULL
			AND Gender = 'Мужской'
			AND period_d IS NOT NULL
		GROUP BY age_group
			,period_d;

		WITH src
		AS (
			SELECT period_m AS period
				,count(*) AS cnt_all
			FROM #issued_group
			WHERE age_group IS NOT NULL
			GROUP BY period_m
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_m AS period
			,count(external_id) / cast(avg(s.cnt_all) AS FLOAT) AS value
			,'gender_age_man' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_m
		WHERE age_group IS NOT NULL
			AND Gender = 'Мужской'
		GROUP BY age_group
			,period_m;

		--Распределение по полу и возрасту, %
		--женщины
		WITH src
		AS (
			SELECT period_d AS period
				,count(*) AS cnt_all
			FROM #issued_group
			WHERE gender IS NOT NULL
				AND period_d IS NOT NULL
			GROUP BY period_d
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_d AS period
			,count(external_id) / cast(avg(s.cnt_all) AS FLOAT) AS value
			,'gender_age_woman' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_d
		WHERE gender = 'Женский'
			AND period_d IS NOT NULL
		GROUP BY gender
			,period_d;

		WITH src
		AS (
			SELECT period_m AS period
				,count(*) AS cnt_all
			FROM #issued_group
			WHERE gender IS NOT NULL
			GROUP BY period_m
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_m AS period
			,count(external_id) / cast(avg(s.cnt_all) AS FLOAT) AS value
			,'gender_age_woman' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_m
		WHERE gender = 'Женский'
		GROUP BY gender
			,period_m;

		WITH src
		AS (
			SELECT period_d AS period
				,count(*) AS cnt_all
			FROM #issued_group
			WHERE age_group IS NOT NULL
				AND period_d IS NOT NULL
			GROUP BY period_d
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_d AS period
			,count(external_id) / cast(avg(s.cnt_all) AS FLOAT) AS value
			,'gender_age_woman' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_d
		WHERE age_group IS NOT NULL
			AND Gender = 'Женский'
			AND period_d IS NOT NULL
		GROUP BY age_group
			,period_d;

		WITH src
		AS (
			SELECT period_m AS period
				,count(*) AS cnt_all
			FROM #issued_group
			WHERE age_group IS NOT NULL
			GROUP BY period_m
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_m AS period
			,count(external_id) / cast(avg(s.cnt_all) AS FLOAT) AS value
			,'gender_age_woman' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_m
		WHERE age_group IS NOT NULL
			AND Gender = 'Женский'
		GROUP BY age_group
			,period_m;

		--Распределение по полу и возрасту, % руб
		--мужчины
		WITH src
		AS (
			SELECT period_d AS period
				,sum(amount) AS amnt_all
			FROM #issued_group
			WHERE gender IS NOT NULL
				AND period_d IS NOT NULL
			GROUP BY period_d
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_d AS period
			,sum(amount) / cast(avg(s.amnt_all) AS FLOAT) AS value
			,'gender_age_man_amnt' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_d
		WHERE gender = 'Мужской'
			AND period_d IS NOT NULL
		GROUP BY gender
			,period_d;

		WITH src
		AS (
			SELECT period_m AS period
				,sum(amount) AS amnt_all
			FROM #issued_group
			WHERE gender IS NOT NULL
			GROUP BY period_m
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_m AS period
			,sum(amount) / cast(avg(s.amnt_all) AS FLOAT) AS value
			,'gender_age_man_amnt' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_m
		WHERE gender = 'Мужской'
		GROUP BY gender
			,period_m;

		WITH src
		AS (
			SELECT period_d AS period
				,sum(amount) AS amnt_all
			FROM #issued_group
			WHERE age_group IS NOT NULL
				AND period_d IS NOT NULL
			GROUP BY period_d
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_d AS period
			,sum(amount) / cast(avg(s.amnt_all) AS FLOAT) AS value
			,'gender_age_man_amnt' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_d
		WHERE age_group IS NOT NULL
			AND Gender = 'Мужской'
			AND period_d IS NOT NULL
		GROUP BY age_group
			,period_d;

		WITH src
		AS (
			SELECT period_m AS period
				,sum(amount) AS amnt_all
			FROM #issued_group
			WHERE age_group IS NOT NULL
			GROUP BY period_m
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_m AS period
			,sum(amount) / cast(avg(s.amnt_all) AS FLOAT) AS value
			,'gender_age_man_amnt' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_m
		WHERE age_group IS NOT NULL
			AND Gender = 'Мужской'
		GROUP BY age_group
			,period_m;

		--Распределение по полу и возрасту, % руб
		--женщины
		WITH src
		AS (
			SELECT period_d AS period
				,sum(amount) AS amnt_all
			FROM #issued_group
			WHERE gender IS NOT NULL
				AND period_d IS NOT NULL
			GROUP BY period_d
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_d AS period
			,sum(amount) / cast(avg(s.amnt_all) AS FLOAT) AS value
			,'gender_age_woman_amnt' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_d
		WHERE gender = 'Женский'
			AND period_d IS NOT NULL
		GROUP BY gender
			,period_d;

		WITH src
		AS (
			SELECT period_m AS period
				,sum(amount) AS amnt_all
			FROM #issued_group
			WHERE gender IS NOT NULL
			GROUP BY period_m
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_m AS period
			,sum(amount) / cast(avg(s.amnt_all) AS FLOAT) AS value
			,'gender_age_woman_amnt' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_m
		WHERE gender = 'Женский'
		GROUP BY gender
			,period_m;

		WITH src
		AS (
			SELECT period_d AS period
				,sum(amount) AS amnt_all
			FROM #issued_group
			WHERE age_group IS NOT NULL
				AND period_d IS NOT NULL
			GROUP BY period_d
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_d AS period
			,sum(amount) / cast(avg(s.amnt_all) AS FLOAT) AS value
			,'gender_age_woman_amnt' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_d
		WHERE age_group IS NOT NULL
			AND Gender = 'Женский'
			AND period_d IS NOT NULL
		GROUP BY age_group
			,period_d;

		WITH src
		AS (
			SELECT period_m AS period
				,sum(amount) AS amnt_all
			FROM #issued_group
			WHERE age_group IS NOT NULL
			GROUP BY period_m
			)
		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_m AS period
			,sum(amount) / cast(avg(s.amnt_all) AS FLOAT) AS value
			,'gender_age_woman_amnt' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_m
		WHERE age_group IS NOT NULL
			AND Gender = 'Женский'
		GROUP BY age_group
			,period_m;

		--Распределение по полу и возрасту, шт
		--мужчины
		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_d AS period
			,count(external_id) AS value
			,'gender_age_man_cnt' AS metric
		FROM #issued_group
		WHERE gender = 'Мужской'
			AND period_d IS NOT NULL
		GROUP BY gender
			,period_d;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_m AS period
			,count(external_id) AS value
			,'gender_age_man_cnt' AS metric
		FROM #issued_group
		WHERE gender = 'Мужской'
		GROUP BY gender
			,period_m;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_d AS period
			,count(external_id)  AS value
			,'gender_age_man_cnt' AS metric
		FROM #issued_group
		WHERE age_group IS NOT NULL
			AND Gender = 'Мужской'
			AND period_d IS NOT NULL
		GROUP BY age_group
			,period_d;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_m AS period
			,count(external_id)  AS value
			,'gender_age_man_cnt' AS metric
		FROM #issued_group
		WHERE age_group IS NOT NULL
			AND Gender = 'Мужской'
		GROUP BY age_group
			,period_m;

		--Распределение по полу и возрасту, шт
		--женщины
		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_d AS period
			,count(external_id) AS value
			,'gender_age_woman_cnt' AS metric
		FROM #issued_group
		WHERE gender = 'Женский'
			AND period_d IS NOT NULL
		GROUP BY gender
			,period_d;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT gender
			,period_m AS period
			,count(external_id) AS value
			,'gender_age_woman_cnt' AS metric
		FROM #issued_group
		WHERE gender = 'Женский'
		GROUP BY gender
			,period_m;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_d AS period
			,count(external_id) AS value
			,'gender_age_woman_cnt' AS metric
		FROM #issued_group
		WHERE age_group IS NOT NULL
			AND Gender = 'Женский'
			AND period_d IS NOT NULL
		GROUP BY age_group
			,period_d;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT age_group
			,period_m AS period
			,count(external_id) AS value
			,'gender_age_woman_cnt' AS metric
		FROM #issued_group
		WHERE age_group IS NOT NULL
			AND Gender = 'Женский'
		GROUP BY age_group
			,period_m;

		-------------------------------------------------------------
		--Распределение  по региону
		DROP TABLE

		IF EXISTS #region;
			WITH src
			AS (
				SELECT period_d AS period
					,count(*) AS cnt_all
					,sum(amount) as amnt_all
				FROM #issued_group
				WHERE region IS NOT NULL
					AND period_d IS NOT NULL
				GROUP BY period_d
				)
			SELECT region
				,period_d AS period
				,count(external_id) / cast(avg(s.cnt_all) AS FLOAT) AS value
				,count(external_id) as cnt
				,sum(amount)/cast(avg(s.amnt_all) AS FLOAT) as amnt
				,'region' AS metric
			INTO #region
			FROM #issued_group
			INNER JOIN src s
				ON s.period = period_d
			WHERE region IS NOT NULL
				AND period_d IS NOT NULL
			GROUP BY region
				,period_d;

		WITH src
		AS (
			SELECT period_m AS period
				,count(*) AS cnt_all
				,sum(amount) as amnt_all
			FROM #issued_group
			WHERE region IS NOT NULL
			GROUP BY period_m
			)
		INSERT INTO #region
		SELECT region
			,period_m AS period
			,count(external_id) / cast(avg(s.cnt_all) AS FLOAT) AS value
			,count(external_id) as cnt
			,sum(amount)/cast(avg(s.amnt_all) AS FLOAT) as amnt
			,'region' AS metric
		FROM #issued_group
		INNER JOIN src s
			ON s.period = period_m
		WHERE region IS NOT NULL
		GROUP BY region
			,period_m;

		DROP TABLE

		IF EXISTS #region_fin;
			SELECT DISTINCT region
				,CASE 
					WHEN value < 0.01
						AND Region NOT IN ('Белгородская область', 'Брянская область', 'Воронежская область', 'Курская область', 'Ростовская область', 'Краснодарский край')
						THEN 'Другое'
					ELSE Region
					END AS region_fin
				,CASE 
					WHEN amnt < 0.01
						AND Region NOT IN ('Белгородская область', 'Брянская область', 'Воронежская область', 'Курская область', 'Ростовская область', 'Краснодарский край')
						THEN 'Другое'
					ELSE Region
					END AS region_fin_amnt
			INTO #region_fin
			FROM #region
			WHERE period = '01. LM'

		INSERT INTO risk.repbi_sales_monitoring
		SELECT isnull(rf.region_fin, 'Другое') AS region
			,a.period
			,sum(a.value) AS value
			,a.metric
		FROM #region a
		LEFT JOIN #region_fin rf
			ON rf.region = a.Region
		GROUP BY isnull(rf.region_fin, 'Другое')
			,a.period
			,a.metric;

		INSERT INTO risk.repbi_sales_monitoring
		SELECT isnull(rf.region_fin, 'Другое') AS region
			,a.period
			,sum(a.cnt) AS value
			,'region_cnt'
		FROM #region a
		LEFT JOIN #region_fin rf
			ON rf.region = a.Region
		GROUP BY isnull(rf.region_fin, 'Другое')
			,a.period;
		
		INSERT INTO risk.repbi_sales_monitoring
		SELECT isnull(rf.region_fin_amnt, 'Другое') AS region
			,a.period
			,sum(a.amnt) AS value
			,'region_amnt'
		FROM #region a
		LEFT JOIN #region_fin rf
			ON rf.region = a.Region
		GROUP BY isnull(rf.region_fin_amnt, 'Другое')
			,a.period;
		



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
			,@recipients = 'a.kuznecov@techmoney.ru'
			,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;

		throw 51000
			,@msg
			,1
	END CATCH
END;
