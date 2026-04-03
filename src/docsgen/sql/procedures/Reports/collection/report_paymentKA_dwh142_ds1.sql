CREATE   PROCEDURE [collection].[report_paymentKA_dwh142_ds1]
AS
BEGIN

WITH payments_by_contracts as (
    SELECT 
        [Дата передачи в КА] as dt,
		[Наименование КА],
    	[№ реестра передачи в работу КА],
		[Номер договора],
		max([Сумма долга, переданная в КА]) as [Сумма долга, переданная в КА],
		count(dt) as num_payments,
		sum([Сумма платежа]) as sum_payments
    FROM 
		[Collection].[paymentKA_dwh142_heap]
	GROUP BY
		[Наименование КА], [Дата передачи в КА], [№ реестра передачи в работу КА], [Номер договора]
	)
	SELECT
		dt,
		[Наименование КА],
    	[№ реестра передачи в работу КА] as [№ реестра передачи],
		count(1) as [Кол-во договоров, переданных в КА],
		sum([Сумма долга, переданная в КА]) as [Сумма долга, переданная в КА],
		sum(num_payments) as [Количество платежей],
		sum(isnull(sum_payments, 0)) as [Сумма платежей]
	FROM
		payments_by_contracts
	group by
		[Наименование КА], dt, [№ реестра передачи в работу КА]
	order by
		dt desc

END