

CREATE     proc [_monitoring].[overpayment_by_clients]

as

begin

drop table if exists #dm_CMRExpectedRepayments

select * into #dm_CMRExpectedRepayments from (
select row_number() over(partition BY Код ORDER BY ДатаПлатежа desc) num,
Код, ДатаПлатежа, СуммаПлатежа

from dwh2.dm.CMRExpectedRepayments
where ДатаПлатежа <= cast(getdate() as date) and ИспытательныйСрок = 0 and СуммаПлатежа>0
) x where num <=2


drop table if exists #date_table


select Код, max(ДатаПлатежа) ДатаПлатежа
into #date_table 
from #dm_CMRExpectedRepayments
where ДатаПлатежа <> cast(getdate() as date)
group by Код



drop table if exists #ЧДП_table


select t1.код,
max(case
    when t1.[Дата заявления на ЧДП день] between dateadd(day, 1, t2.ДатаПлатежа) and cast(getdate()+1 as date) or t2.ДатаПлатежа is null then 1
end) date_sign
into #ЧДП_table
from [Analytics].[dbo].[v_Документ_ЗаявлениеНаЧДП] t1
left join #date_table t2 on t1.код = t2.Код
group by t1.код

drop table if exists #payment_table


select Код, СуммаПлатежа
into #payment_table
from #dm_CMRExpectedRepayments t
where t.num = 1


drop table if exists #preparatory


select t1.Код, ABS(t1.overdue) [Размер переплаты],
case
    when t2.СуммаПлатежа is not null then t2.СуммаПлатежа
	else t3.[Размер платежа первоначальный]  end [Ежемесячный платеж]
into #preparatory
from v_balance t1
left join #payment_table t2 on t1.Код = t2.Код
left join mv_loans t3 on t1.Код = t3.код
left join #ЧДП_table t4 on t1.Код = t4.код 
where d = cast(getdate() as date) 
and t1.overdue < 0 
and t4.date_sign is null


select Код, [Размер переплаты], [Ежемесячный платеж], format([Размер переплаты]/[Ежемесячный платеж],'0%' ) [Переплата]
from #preparatory
where [Размер переплаты] > [Ежемесячный платеж]
order by 2 desc

end
