CREATE   PROCEDURE [dbo].[reportDifferenceOfAmounts_MFO_CMR] 
AS
BEGIN
	SET NOCOUNT ON;


declare @GetDate2000 datetime

set @GetDate2000=dateadd(year,2000,getdate());

SELECT cast(dateadd(year,-2000,t1.[Период]) as datetime) as [Период]
	  ,dateadd(year,-2000,cast(t3.[ДатаВыдачи] as datetime2)) as [ДатаВыдачи]      
	  ,t1.[Заявка]
	  ,t3.[Номер] as [ЗаявкаНомер]

	  ,t3.[Сумма] as [СуммаВыданная]
      ,t1.[Статус]
	  ,t2.[Наименование] as [СтатусНаим]
	  ,t4.[НаименованиеПараметра]
	  ,t4.[Сумма]
	  ,t4.[СуммаДопПродуктов]
	  ,(cast(t3.[Сумма] as decimal(15,2))-t4.[Сумма]) as [Отклонение]
	  ,t5.[_Fld27] as [НомерДоговора_ПШ]
	  ,t5.[_Fld30] as [Сумма_ПШ]
	  ,(cast(t3.[Сумма] as decimal(15,2))-t5.[_Fld30]) as [Отклонение_ПШ]
from (select max([Период]) as [Период] ,[Заявка] ,[Статус] 
	  from stg._1cCRM.[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС]
	  
	  where [Статус]=0xA81400155D94190011E80784923C6097  -- статус заем выдан
			and not [Заявка] in (select [Заявка] 
								 from stg._1cCRM.[РегистрСведений_СтатусыЗаявокНаЗаймПодПТС]
								 where [Статус]=0xA81400155D94190011E80784923C6096 --заем аннулирован
								 )
	  group by [Заявка] ,[Статус]
	 ) t1
 left join stg._1cCRM.[Справочник_СтатусыЗаявокПодЗалогПТС] t2
	on t1.[Статус]=t2.[Ссылка]
left join stg._1cCRM.[Документ_ЗаявкаНаЗаймПодПТС] t3
	on t1.[Заявка]=t3.[Ссылка]
left join
(
select [ДоговорНомер] as [НаименованиеПараметра] ,[СуммаДоговора] as [Сумма] 
		,[Год] as [Год] ,[Докредитование] as [Докредитование] 
		,datediff(day,0,dateadd(day,datediff(day,0,Getdate()),-1))+2 as [ДатаЧислом] 
		,datediff(day,0,dateadd(day,datediff(day,0,[ПериодУчета]),0))+2 as [ПериодУчета] 
		,[ПовторностьNew] as [ПовторностьNew],[Срок] as [Срок]
		,[КредитныйПродукт] as [КредитныйПродукт]
		,[Когорта] as [Когорта]
		,[СуммаДопПродуктов] as [СуммаДопПродуктов] ,[КолвоДопПродуктов] as [КолвоДопПродуктов] 

from [Stg].[dbo].[aux_LoanMFO_1c]
where not [ДатаВыдачиДоговора] is null and [ПериодУчета]>=dateadd(month,0,dateadd(MONTH,datediff(MONTH,0,Getdate()-1),0))
		and [ДатаОперации]<dateadd(day,datediff(day,0,Getdate()),0)
) t4
	on t3.[Номер]=t4.[НаименованиеПараметра]
left join 
(
select distinct [_Fld27] ,[_Fld30] from Stg.[_1cPG].PGPayments
) t5
	on t3.[Номер]=t5.[_Fld27]
where t3.[ДатаВыдачи] >= dateadd(MONTH,datediff(MONTH,0,@GetDate2000),0) and t3.[ДатаВыдачи] < dateadd(day,datediff(day,0,@GetDate2000),0)
and (cast(t3.[Сумма] as decimal(15,2))-t4.[Сумма])<>0 --or (cast(t3.[Сумма] as decimal(15,2))-t5.[_Fld30])<>0)
order by [ДатаВыдачи] desc

END
