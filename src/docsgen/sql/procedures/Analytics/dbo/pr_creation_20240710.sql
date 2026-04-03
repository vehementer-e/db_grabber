create proc pr_creation_20240710
as


begin





drop table if exists #t1

select 
[Заем выдан день]
,Должность
,case when  [Группа каналов]='cpa' then  [Канал от источника] else [Группа каналов] end Канал
,  [Первичная сумма]      [Первичная сумма]
,  [Сумма одобренная]     [Сумма одобренная]
,  [Выданная сумма]       [Выданная сумма]
,  [Стоимость ТС]         [Стоимость ТС]
, ПолКлиента 
, case when a.[Вид займа] ='Первичный' then a.[Вид займа] else 'Повторный' end [Повторность займа]
, case when dateadd(year, 3, try_cast(cast( [Год тс] as varchar(4))+'-07-01' as date))>=[Заем выдан день] then 'Авто до 3 лет' else 'Старое авто' end [Новое авто]
, [Год тс]
, [Марка тс аналитическая]
, [Марка модель ТС]
, [Цель займа аналитическая]
, ВозрастНаДатуЗаявки
, case when [Марка тс аналитическая] in (
'LADA'
,'КАМАЗ'
,'ВАЗ'
,'УАЗ'
,'ТАГАЗ'
,'UAZ'
,'МАЗ'
,'ГАЗ'
,'ПАЗ'
,'ГАЗ-3302'
) then 0 else 1 end [Признак иномарка]
,case when try_cast(СуммарныйМесячныйДоход_CRM as bigint)>100 then try_cast(СуммарныйМесячныйДоход_CRM as bigint) end СуммарныйМесячныйДоход_тыс_CRM
,a.Срок
,a.Номер
,b.[Вид займа]
,a.РегионПроживания
, b.[Размер платежа первоначальный]

--,СуммарныйМесячныйДоход_CRM
into #t1
from mv_dm_Factor_Analysis a
left join mv_loans b on a.Номер=b.код
left join [Отчет ПДН] pdn on pdn.Number=a.Номер		and 1=0
where 
a.ispts=1
--and [Заем выдан день] between '20210101' and '20221231'


drop table if exists  #t2

select * into #t2 from (

--select T = '01) 2021 ГОД 1 кв.'       ,*  from #t1 where YEAR([Заем выдан день]  )=2021 and month([Заем выдан день]) between 1 and 3 UNION ALL
--select T = '02) 2022 ГОД 1 кв.'       ,* from #t1 where YEAR([Заем выдан день]  )=2022 and month([Заем выдан день]) between 1 and 3 UNION ALL
--select T = '03) 2023 ГОД 1 кв.'       ,* from #t1 where YEAR([Заем выдан день]  )=2023 and month([Заем выдан день]) between 1 and 3 UNION ALL
--select T = '13) 2021 ГОД 2 кв.'       ,* from #t1 where YEAR([Заем выдан день]  )=2021 and month([Заем выдан день]) between 4 and 6 UNION ALL
--select T = '14) 2022 ГОД 2 кв.'       ,* from #t1 where YEAR([Заем выдан день]  )=2022 and month([Заем выдан день]) between 4 and 6 UNION ALL
--select T = '15) 2023 ГОД 2 кв.'       ,* from #t1 where YEAR([Заем выдан день]  )=2023 and month([Заем выдан день]) between 4 and 6 UNION ALL 
--select T = '25) 2021 ГОД 1 полугодие' ,* from #t1 where YEAR([Заем выдан день]  )=2021 and month([Заем выдан день]) between 1 and 6 UNION ALL
--select T = '26) 2022 ГОД 1 - 4 кв' ,* from #t1 where YEAR([Заем выдан день]  )=2022 and month([Заем выдан день]) between 1 and 12 --UNION ALL
--select T = '27) 2023 ГОД 1 - 4 кв' ,* from #t1 where YEAR([Заем выдан день]  )=2023 and month([Заем выдан день]) between 1 and 12 --UNION ALL
--select T = '27) 2023 ГОД 1 - 4 кв' ,* from #t1 where YEAR([Заем выдан день]  )=2023 and month([Заем выдан день]) between 1 and 12 --UNION ALL
select T = '27) 2023 ГОД 1 - 2 кв' ,* from #t1 where YEAR([Заем выдан день]  )=2023 and month([Заем выдан день]) between 1 and 6 UNION ALL
select T = '28) 2024 ГОД 1 - 2 кв' ,* from #t1 where YEAR([Заем выдан день]  )=2024 and month([Заем выдан день]) between 1 and 6 --UNION ALL

)ч

select * into pr_20240710 from #t2




select rn  [Марка модель ТС]
, max(case when    '27) 2023 ГОД 1 - 2 кв'       =T then Сегмент end)  '27) 2023 ГОД 1 - 2 кв'
, max(case when    '28) 2024 ГОД 1 - 2 кв'       =T then Сегмент end)  '28) 2024 ГОД 1 - 2 кв'




from (
select *, ROW_NUMBER() over(partition by  T order by cnt desc) rn 
from (SELECT [Марка модель ТС] Сегмент
	   , T
	,count(*) cnt
 
FROM #t2
--WHERE [Вид займа] = 'Первичный'
GROUP BY [Марка модель ТС]
	,t

  		  )	    x
) x
where rn<=10
 group by rn
order by 1

select rn	 [Марка тс]		   														 
, max(case when    '27) 2023 ГОД 1 - 2 кв'       =T then Сегмент end)   '27) 2023 ГОД 1 - 2 кв'
, max(case when    '28) 2024 ГОД 1 - 2 кв'       =T then Сегмент end)   '28) 2024 ГОД 1 - 2 кв'
      

  



from (
select *, ROW_NUMBER() over(partition by  T order by cnt desc) rn 
from (SELECT [Марка тс аналитическая] Сегмент
	   , T
	,count(*) cnt
 
FROM #t2
--WHERE [Вид займа] = 'Первичный'
GROUP BY [Марка тс аналитическая]
	,t

  		  )	    x
) x
where rn<=5

group by rn
order by 1

--order by 
--order by

select rn  РегионПроживания 									   			
, max(case when   '27) 2023 ГОД 1 - 2 кв'       =T then Сегмент end)  '27) 2023 ГОД 1 - 2 кв'
, max(case when   '28) 2024 ГОД 1 - 2 кв'       =T then Сегмент end)  '28) 2024 ГОД 1 - 2 кв'





from (
select *, ROW_NUMBER() over(partition by  T order by cnt desc) rn 
from (SELECT РегионПроживания Сегмент
	   , T
	,count(*) cnt
 
FROM #t2
--WHERE [Вид займа] = 'Первичный'
GROUP BY РегионПроживания
	,t

  		  )	    x
) x
where rn<=10

group by rn
order by 1

--order by 
--order by 



end