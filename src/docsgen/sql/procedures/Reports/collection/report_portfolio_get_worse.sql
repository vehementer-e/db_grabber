CREATE   PROCEDURE [collection].[report_portfolio_get_worse]
AS
-- exec [collection].[report_portfolio_get_worse]
BEGIN

--	drop table if exists #contracts;
--	SELECT DISTINCT
--       s.Код AS external_id
--    into #contracts
--	FROM dwh2.dm.CMRExpectedRepayments s
--   WHERE
--        s.Код > '24010100000000'
--        AND s.Код = '25122423965171'
--	;

	drop table if exists #bal_info;
	SELECT
        dog.КодДоговораЗайма as external_id,
		dog.ТипПродукта_Наименование as product,
		gp.ГруппаПродуктов_Наименование as product_group,
        dog.ДатаДоговораЗайма as ContractStartDate,
        ДатаЗакрытияДоговора as ContractEndDate
    into #bal_info
	-- select *
	from
	dwh2.hub.ДоговорЗайма dog
	INNER JOIN
	dwh2.sat.ДоговорЗайма_ТекущийСтатус dog_stat on dog_stat.СсылкаДоговораЗайма = dog.СсылкаДоговораЗайма
	LEFT JOIN
	dwh2.hub.v_hub_ГруппаПродуктов gp on gp.ПодтипПродуктd_Наименование = dog.ПодТипПродукта
    WHERE
		dog.КодДоговораЗайма > '24010100000000'
		and
        gp.ГруппаПродуктов_Наименование in ('ПТС', 'Big Installment')
		and
		dog_stat.ТекущийСтатусДоговора not in('Аннулирован', 'Выдача ДС', 'Период охлаждения', 'Пауза по желанию клиента', 'Зарегистрирован')
;

	drop table if exists #cal_months;
	SELECT
        bi.external_id,
		bi.product,
		bi.product_group,
        bi.ContractStartDate,
        bi.ContractEndDate,
        m.month_start
    into #cal_months
	FROM #bal_info bi
    JOIN (
        SELECT 
			DISTINCT Month_Value AS month_start --DATEFROMPARTS(YEAR(created), MONTH(created), 1) AS month_start
        FROM 
			dwh2.Dictionary.calendar
        WHERE 
			DT >= '2024-01-01'
			AND 
			DT <= GETDATE()
    ) m
      ON m.month_start >= DATEFROMPARTS(YEAR(bi.ContractStartDate), MONTH(bi.ContractStartDate), 1)
     AND m.month_start <= DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);

	drop table if exists #schedule_in_month;
	SELECT
        cm.*,
        sch.ДатаПлатежа
    into #schedule_in_month
	FROM #cal_months cm
    OUTER APPLY (
        SELECT MAX(s.ДатаПлатежа) AS ДатаПлатежа
        FROM dwh2.dm.CMRExpectedRepayments s
        WHERE s.Код = cm.external_id
          AND s.ДатаПлатежа >= cm.month_start
          AND s.ДатаПлатежа <  DATEADD(month, 1, cm.month_start)
          AND s.ДатаПлатежа <  EOMONTH(GETDATE())
          AND s.Код > '24010100000000'
	) sch;

select 
		t1.*,
		row_number() over (partition by t1.external_id order by t1.month_start) as rn
	from (
	SELECT
		x.external_id,
		x.product,
		x.product_group,
		isnull(bal.[остаток од], 0) as debt_body,
		CONVERT(char(7), x.ContractStartDate, 126) AS contract_start_month,
		CONVERT(char(7), x.month_start,      126) AS contract_live_month,

		DATEDIFF(
			month,
			DATEFROMPARTS(YEAR(x.ContractStartDate), MONTH(x.ContractStartDate), 1),
			x.month_start
		) AS month_of_life,

		/* dpd берём только если есть платежная дата в этом месяце и есть баланс на (платеж+1),
		   иначе — если месяц уже после последнего баланса, ставим 0 как "закрыт" */
		CASE
			WHEN bal.dpd IS NOT NULL THEN bal.dpd
			WHEN x.ContractEndDate IS NOT NULL THEN 0
			ELSE NULL
		END AS dpd,

		CASE
			WHEN bal.dpd IS NOT NULL THEN
				CASE
					WHEN bal.dpd = 0 THEN '0'
					WHEN bal.dpd BETWEEN 1 AND 30 THEN '1-30'
					WHEN bal.dpd BETWEEN 31 AND 60 THEN '31-60'
					WHEN bal.dpd BETWEEN 61 AND 90 THEN '61-90'
					WHEN bal.dpd > 90 THEN '91+'
				END
			WHEN x.ContractEndDate IS NOT NULL THEN '0'
			ELSE '0'
		END AS bucket,
		x.ContractEndDate,
		x.month_start,
		CASE
			WHEN x.ContractEndDate IS NOT NULL THEN 'да'
			ELSE 'нет'
		END AS contract_closed

	FROM #schedule_in_month x
	LEFT JOIN dwh2.dbo.dm_CMRStatBalance bal
	  ON bal.external_id = x.external_id
	 AND bal.d = DATEADD(day, 1, x.ДатаПлатежа)
	 AND bal.[Тип Продукта] in ('ПТС', 'ПТС Займ для Самозанятых', 'ПТС Лайт для самозанятых', 'ПТС31', 'ПТС (Автокред)', 'Big Installment', 'Big Installment Рыночный', 'Big Installment Рыночный - Самозанятый')
	--ORDER BY
	--	x.external_id,
	--	x.month_start
	) t1
	where 
		month_of_life>0; --and external_id='24080102277724';

END;