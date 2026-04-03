-- =============================================
-- Author:		Shubkin Aleksandr
-- Create date: 30.05.2025
-- Description:	датасет для отчета по переплатам
-- Example: exec service.report_overdue_ds '2025-05-30', null
-- =============================================
CREATE   PROCEDURE [service].[report_overdue_ds]
	-- Add the parameters for the stored procedure here
	@dtFrom date = null,
	@dtTo	date = null
AS
BEGIN
	IF @dtFrom IS NULL SET @dtFrom = cast(getdate() as date)
	IF @dtTo IS NULL SET @dtTo  = cast(dateadd(dd, 7, @dtFrom) as date)
	-- Набор полей
	;with cte as 
	(SELECT 
		  [ФИО клиента]				= Клиенты.ФИО
		, [Номер договора]			= Договор.КодДоговораЗайма
		, [Телефон клиента]			= Телефон.НомерТелефонаБезКодов
		, [Дата ЕП]					= ep.ДатаПлатежа
		, [Сумма ЕП]				= ep.СуммаПлатежа
		, [Сумма поступлений]		= sum_pay.[Сумма поступлений]
		, [Сумма переплаты]			= abs(b1.overdue)
		, [% переплаты]       = cast(iif(ep.СуммаПлатежа > 0 
               ,ROUND(ABS(b1.overdue) * 100.0 / ep.СуммаПлатежа, 2)
				,0
           ) as smallmoney)
		, [Информация по звонку]	= 'Будет реализовано позже'
		, [Статус звонка]			= 'Будет реализовано позже'
		, prev_date_payment			= prev_pay.prev_date_payment
	FROM		dwh2.hub.Клиенты					Клиенты
	-- клиент → link → договор
	inner JOIN	dwh2.link.Клиент_ДоговорЗайма		Линк_Клиент_Договор ON Линк_Клиент_Договор.GuidКлиент	= Клиенты.GuidКлиент
	inner JOIN	dwh2.hub.ДоговорЗайма				Договор				ON Договор.КодДоговораЗайма			= Линк_Клиент_Договор.КодДоговораЗайма
	-- клиент → телефон
	LEFT JOIN	dwh2.sat.Клиент_Телефон				Телефон				ON Телефон.GuidКлиент				= Клиенты.GuidКлиент 
	-- ежемесячный платеж
	INNER JOIN  dwh2.[dm].[CMRExpectedRepayments]	ep					ON ep.Код							= Договор.КодДоговораЗайма
	-- предыдущая дата платежа
	OUTER APPLY (
		SELECT prev_date_payment = max(ДатаПлатежа)
		FROM dwh2.[dm].[CMRExpectedRepayments] prev
		WHERE	prev.Код = ep.код					AND
				prev.ДатаПлатежа < ep.ДатаПлатежа	AND
				prev.СуммаПлатежа > 0
	) prev_pay
	-- получаем последние данные по балансу между предыдущей датой платежа и ближайшей по графику
	LEFT JOIN (
		SELECT
			external_id,
			last_d = MAX(d)
		FROM dwh2.dbo.dm_CMRStatBalance
		GROUP BY external_id
	) b_last
		ON b_last.external_id = ep.Код
	   AND b_last.last_d BETWEEN
			ISNULL(dateadd(dd, 1, prev_pay.prev_date_payment), Договор.ДатаДоговораЗайма)
			AND ep.ДатаПлатежа
	-- dpd = 0 | рассчет переплаты
	INNER JOIN dwh2.dbo.dm_CMRStatBalance b1 ON	b1.external_id	= b_last.external_id AND 
												b1.d			= b_last.last_d		 AND
												b1.dpd			= 0					 and
												b1.overdue < =0
												
	-- считаем сумму поступлений между предыдущей датой платежа и ближайшей по графику 
	OUTER APPLY (
		SELECT [Сумма поступлений] = SUM(b2.[сумма поступлений])
		FROM dwh2.dbo.dm_CMRStatBalance b2
		WHERE	b2.external_id = ep.Код
		  AND b2.d >= ISNULL(dateadd(dd, 1, prev_pay.prev_date_payment), Договор.ДатаДоговораЗайма)
		  AND b2.d <= CASE
						 WHEN ep.ДатаПлатежа > GETDATE()
						 THEN b_last.last_d
						 ELSE ep.ДатаПлатежа
						END
		  AND b2.dpd = 0
	) sum_pay
	WHERE ep.ДатаПлатежа BETWEEN CAST(@dtFrom AS DATE) and CAST(@dtTo AS DATE)
	  AND ep.СуммаПлатежа > 0
	  AND not exists(select top(1) 1 from dwh2.sat.ДоговорЗайма_ТекущийСтатус ТекущийСтатус
	  where ТекущийСтатус.GuidДоговораЗайма = Договор.GuidДоговораЗайма
		and ТекущийСтатус.ТекущийСтатусДоговора not in ('Решение суда')
		)
	  --Нет заявления на ЧДП/ПДП на дату платежа
	  and not exists(select top(1) 1 from stg._1cCMR.Документ_ЗаявлениеНаЧДП  ЗаявлениеНаЧДП
		where ЗаявлениеНаЧДП.Договор = Договор.СсылкаДоговораЗайма
		and dateadd(year, -2000 ,ЗаявлениеНаЧДП.Дата) between ISNULL(dateadd(dd, 1, prev_pay.prev_date_payment), Договор.ДатаДоговораЗайма)
			and ep.ДатаПлатежа
		and ЗаявлениеНаЧДП.Проведен = 0x01
		)
	)
	select * from cte
	where (([% переплаты] >=  70 and [% переплаты]<100)
			or ([% переплаты] >=  170
		)
		)
	order by [Дата ЕП], [% переплаты] desc
END
