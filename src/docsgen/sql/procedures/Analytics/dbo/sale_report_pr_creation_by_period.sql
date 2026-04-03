CREATE proc [dbo].[sale_report_pr_creation_by_period]
@first_period_name varchar(100), @first_period_year_num int,   @first_period_month_num_start int,   @first_period_month_num_end int ,
@second_period_name varchar(100), @second_period_year_num int,   @second_period_month_num_start int,   @second_period_month_num_end int  


as
 

-- sale_report_pr_creation_by_period
--'2024 4-4кв.', 2024,  10,   12,
--'2025 4-4кв.', 2025,  10,   12  


 --drop table if exists [pr_1) 2024 2кв. VS 2) 2025 2кв.]


drop table if exists #t1

select 
[Заем выдан день]
,Должность
,case when  [Группа каналов]='cpa' then  [Канал от источника] else [Группа каналов] end Канал
,  [Первичная сумма]      [Первичная сумма]
,  [Сумма одобренная]     [Сумма одобренная]
,  [Выданная сумма]       [Выданная сумма]
,  f.[Стоимость ТС]         [Стоимость ТС]
, ПолКлиента 
, case when a.[Вид займа] ='Первичный' then a.[Вид займа] else 'Повторный' end [Повторность займа]
, case when dateadd(year, 3, try_cast(cast( [Год тс] as varchar(4))+'-07-01' as date))>=[Заем выдан день] then 'Авто до 3 лет' else 'Старое авто' end [Новое авто]
, [Год тс]
, [Марка тс аналитическая]
, [Марка модель ТС]
, [Цель займа аналитическая]
, r.age ВозрастНаДатуЗаявки
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
,b.Срок
,a.Номер
,b.[Вид займа]
,a.РегионПроживания
, b.[Размер платежа первоначальный]

--,СуммарныйМесячныйДоход_CRM
into #t1
from mv_dm_Factor_Analysis a
left join mv_loans b on a.Номер=b.код
left join [Отчет ПДН] pdn on pdn.Number=a.Номер		and 1=0
left join (select Номер, max([Стоимость ТС]) [Стоимость ТС] from v_fa group by Номер )   f on f.Номер=a.Номер
left join (select number, max(age) age from _request group by number )   r on r.number=a.Номер

where 
a.productType='pts' and a.[Выданная сумма]>0
--and [Заем выдан день] between '20210101' and '20221231'


drop table if exists  #t2

select * into #t2 from (

select T = @first_period_name ,* from #t1 where YEAR([Заем выдан день]  )=@first_period_year_num and month([Заем выдан день]) between @first_period_month_num_start and @first_period_month_num_end UNION ALL
select T = @second_period_name ,* from #t1 where YEAR([Заем выдан день]  )=@second_period_year_num and month([Заем выдан день]) between @second_period_month_num_start and @second_period_month_num_end --UNION ALL

)ч


--select * from #t2
--order by Номер
declare @tbl_name varchar(max) = '[pr_'+@first_period_name+' VS '+@second_period_name+']'
declare @xlsx_name varchar(max) = 'pr_'+@first_period_name+' VS '+@second_period_name+''
declare @sql1 varchar(max) = 'select * into '+@tbl_name+' from #t2'
select 'select * from '+ @tbl_name
select @xlsx_name
print(@tbl_name)

exec (@sql1)

--select * into pr_20250523 from #t2

 
 --drop table pr_20250523

select rn  [Марка модель ТС]
, max(case when    @first_period_name       =T then Сегмент end)   'first period'
, max(case when    @second_period_name       =T then Сегмент end)  'second period'




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
, max(case when  @first_period_name        =T then Сегмент end)  'first period'
, max(case when  @second_period_name       =T then Сегмент end)  'second period'
      

  



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

--select * from #t2

select rn  РегионПроживания 									   			
, max(case when  @first_period_name          =T then Сегмент end)   'first period'
, max(case when  @second_period_name         =T then Сегмент end)   'second period'





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
 