-- exec [collection].[report_debitor_behaviour]
CREATE   PROCEDURE [collection].[report_debitor_behaviour]
AS
BEGIN
--select top(100) * from dwh2.dbo.dm_CMRStatBalance;
select --top(100) *
	d as action_date, 
	external_id,
	[Тип Продукта] as product_type,
	overdue_begin_day,
	overdue,
	pay_total,
	[остаток од],
	prev_od,
	dpd_begin_day, 
	dpd,
	case
		when dpd_begin_day BETWEEN 1 AND 30 then '1-30'
		when dpd_begin_day BETWEEN 31 AND 60 then '31-60'
		when dpd_begin_day BETWEEN 61 AND 90 then '61-90'
		when dpd_begin_day > 90 then '91+'
	end as bucket,	
	case
		when dpd_begin_day BETWEEN 91 AND 120 then '91-120'
		when dpd_begin_day BETWEEN 121 AND 150 then '121-150'
		when dpd_begin_day BETWEEN 151 AND 180 then '151-180'
		when dpd_begin_day > 180 then '181+'
	end as bucket2,
	case
		when dpd > 0 
			or 	overdue_begin_day> pay_total
		then 'Partial Payment'
		when dpd = 0 and  [остаток од] > 0 
			and overdue <= 0 --/*?*/
			
		then 'Возврат в график'
		--when dpd = 0 and overdue < 0 and [остаток од] > 0 then 'ЧДП'
		when dpd = 0 
			and overdue <= 0  --нет просрочки
			and [остаток од] > 0 --од не погасили
			and pay_total>=	overdue--платеж был больше чем сумма задолжности
			and [ЧДП Основной долг Уплачено]> 0 --часть платежа ушла на ЧДП ОД
			then 'ЧДП'
		when prev_od > 0 and [остаток од] = 0 then 'Полное закрытие' --and  d= ContractEndDate

		else 'Вопросы'
	end as action_type,
	[ЧДП Основной долг Уплачено],
	[ДП Основной долг Уплачено]

from 
	dwh2.dbo.dm_CMRStatBalance
where 
	d = cast(getdate()-1  as date)
	--and external_id = '23011300656757'
	and 
	dpd_begin_day>0
	and
	pay_total > 0
;

END;
