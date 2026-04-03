CREATE PROC _birs.flocktory
@start_date_ssrs date = null,
@end_date_ssrs date = null

as

begin


select
Телефон,
[Текущий статус],
cast([ДатаЗаявкиПолная] as nvarchar(50)) [ДатаЗаявкиПолная],
Источник
from v_fa
where Источник = 'flocktory-installment-ref' or Источник = 'flocktory-ref'
order by [ДатаЗаявкиПолная] desc

end