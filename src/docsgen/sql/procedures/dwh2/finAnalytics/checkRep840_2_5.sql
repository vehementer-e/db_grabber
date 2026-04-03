


CREATE PROCEDURE [finAnalytics].[checkRep840_2_5]
	@repMonth date
AS
BEGIN

begin try


--Тригеры ЦБ 
merge into [dwh2].[finAnalytics].[rep840_2_5] t1
using (
select
repmonth = l2.repmonth
,repDate = eomonth(l2.repmonth)
,[Что проверяем] = concat(
						'Значение, указанное в строке '
						,l2.punkt
						,', представленного за отчетный период, должно быть больше или равно значению, указанному в строке '
						,l2.punkt
						,', представленного за предыдущий отчетный период'
						)
,punkt = l2.punkt
,[Результат] = case when l2.tekVal>=l2.prevVal then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from(
select
repmonth = l1.repmonth
,punkt = l1.punkt
,prevVal = case when month(@repmonth) = 1 then sum(l1.tekVal) else sum(l1.prevVal) end
,tekVal = sum(l1.tekVal)
from(
Select
repmonth = @repmonth
,punkt = a.punkt
,prevVal = case when a.REPMONTH = DATEADD(month,-1,@repmonth) then value else 0 end
,tekVal = case when a.REPMONTH = @repmonth then value else 0 end

from dwh2.[finAnalytics].[rep840_2_5] a
where a.REPMONTH between DATEADD(month,-1,@repmonth) and @repmonth
and (a.punkt in ('2.33','2.33.1','2.33.1.1 ','2.33.1.2','2.33.1.2.1','2.33.2','2.33.2.1','2.33.3','2.33.3.1','2.33.3.2','2.33.3.2.1'
				,'2.33.3.3','2.33.3.3.1','2.33.3.4','2.33.3.4.1','2.34','2.34.1','2.34.1.1','2.34.1.2','2.34.1.2.1','2.34.2','2.34.2.1'
				,'2.34.3','2.34.3.1','2.34.3.2','2.34.3.2.1','2.34.3.3','2.34.3.3.1','2.34.3.4','2.34.3.4.1','2.38','2.38.1','2.38.2'
				,'2.38.3','2.49','2.49.1','2.51','2.51.1')
	)
) l1

group by
l1.repmonth
,l1.punkt
) l2

) t2 on (t1.repmonth = @repmonth and t1.punkt = t2.punkt)
when matched then update
set t1.checkMethod3=t2.[Что проверяем],
    t1.chekResult3=t2.[Результат];


--Тригеры 2.40
merge into [dwh2].[finAnalytics].[rep840_2_5] t1
using (
select
repmonth = l2.repmonth
,repDate = eomonth(l2.repmonth)
,[Что проверяем] = 'Значение, указанное в строке 2.40 должно быть равно значению, указанному в строке 61 ф. 843 за соответствующий отчетный период в тыс.руб. (три знака после запятой) '
,punkt = '2.40'
,[Результат] = case when round(l2.tekVal,0) = round(l2.checkVal,0) then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from(
select
repmonth = l1.repmonth
,punkt = l1.punkt
,tekVal = l1.tekVal
,checkVal = l1.checkVal
from(
Select
repmonth = @repmonth
,punkt = a.punkt
,tekVal = value
,checkVal = b.sumAmount
from dwh2.[finAnalytics].[rep840_2_5] a
left join (select
			sumAmount
			from dwh2.[finAnalytics].[repPLf843]
			where repmonth = @repMonth
			and rowName = '61') b on 1=1
where a.REPMONTH = @repmonth
and (a.punkt in ('2.40'))
) l1
) l2

) t2 on (t1.repmonth = @repmonth and t1.punkt = t2.punkt)
when matched then update
set t1.checkMethod3=t2.[Что проверяем],
    t1.chekResult3=t2.[Результат];

--Тригеры 2.42
merge into [dwh2].[finAnalytics].[rep840_2_5] t1
using (
select
repmonth = l2.repmonth
,repDate = eomonth(l2.repmonth)
,[Что проверяем] = 'Значение, указанное в строке 2.42 должно быть равно значению, указанному по строке 30 ф. 842 за соответствующий отчетный период в тыс.руб. (три знака после запятой)'
,punkt = '2.42'
,[Результат] = case when round(l2.tekVal,0) = round(l2.checkVal,0) then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from(
select
repmonth = l1.repmonth
,punkt = l1.punkt
,tekVal = l1.tekVal
,checkVal = l1.checkVal
from(
Select
repmonth = @repmonth
,punkt = a.punkt
,tekVal = value
,checkVal = b.sumAmount
from dwh2.[finAnalytics].[rep840_2_5] a
left join (select
			sumAmount = restOut
			from dwh2.[finAnalytics].[rep842]
			where repmonth = @repmonth
			and rowName = '30') b on 1=1
where a.REPMONTH = @repmonth
and (a.punkt in ('2.42'))
) l1
) l2

) t2 on (t1.repmonth = @repmonth and t1.punkt = t2.punkt)
when matched then update
set t1.checkMethod3=t2.[Что проверяем],
    t1.chekResult3=t2.[Результат];

--Тригеры 2.43
merge into [dwh2].[finAnalytics].[rep840_2_5] t1
using (
select
repmonth = l2.repmonth
,repDate = eomonth(l2.repmonth)
,[Что проверяем] = 'Значение, указанное в строке 2.43 должно быть равно значению, указанному по строке 31 ф. 842 за соответствующий отчетный период в тыс.руб. (три знака после запятой)'
,punkt = '2.43'
,[Результат] = case when round(l2.tekVal,0) = round(l2.checkVal,0) then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from(
select
repmonth = l1.repmonth
,punkt = l1.punkt
,tekVal = l1.tekVal
,checkVal = l1.checkVal
from(
Select
repmonth = @repmonth
,punkt = a.punkt
,tekVal = value
,checkVal = b.sumAmount
from dwh2.[finAnalytics].[rep840_2_5] a
left join (select
			sumAmount = restOut
			from dwh2.[finAnalytics].[rep842]
			where repmonth = @repmonth
			and rowName = '31') b on 1=1
where a.REPMONTH = @repmonth
and (a.punkt in ('2.43'))
) l1
) l2

) t2 on (t1.repmonth = @repmonth and t1.punkt = t2.punkt)
when matched then update
set t1.checkMethod3=t2.[Что проверяем],
    t1.chekResult3=t2.[Результат];

end try

BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
       ,ERROR_MESSAGE() AS ErrorMessage;  
END CATCH


end
