

CREATE PROCEDURE [finAnalytics].[checkRep840_2_34]
	@repMonth date
AS
BEGIN

begin try

update [dwh2].[finAnalytics].[rep840_2_34]
set checkMethod2 = null,
    chekResult2=null
where REPMONTH=@repMonth

--Проверка 2.24 с портфелем привлечений
merge into [dwh2].[finAnalytics].[rep840_2_34] t1
using (

select
[repmonth] = @repmonth
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Портфель сбережений. Вид контрагента "ЮЛ", "КО". По сцепке "Номер основного договора" + "Наименование займодавца" суммируем остатки. Считаем колв-о уникальных сцепок с остатками >0 с датой выдачи в отчетном периоде'
,[Данные отчета] = (select sum(value) from [dwh2].[finAnalytics].[rep840_2_34] where REPMONTH=@repMonth and punkt in ('2.24'))
,[Данные УМФО] = (
                    select
					clientCount = count(*)
					from(
					select distinct
					client
					--,mainDogNum
					--,mainDogDate

					from dwh2.finAnalytics.DEPO_MONTHLY a
					where a.repmonth = @repmonth
					and upper(clientType) in ('ЮЛ', 'КО')
					and mainDogDate between datefromParts(year(@repmonth),1,1) and eomonth(@repmonth)
					) l1
                )
) l1
) t2 on (t1.repmonth = @repmonth and t1.punkt in ('2.24'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];


--Проверка 2.24.1 с портфелем привлечений
merge into [dwh2].[finAnalytics].[rep840_2_34] t1
using (

select
[repmonth] = @repmonth
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Портфель сбережений. Вид контрагента "КО". По сцепке "Номер основного договора" + "Наименование займодавца" суммируем остатки. Считаем колв-о уникальных сцепок с остатками >0 с датой выдачи в отчетном периоде'
,[Данные отчета] = (select sum(value) from [dwh2].[finAnalytics].[rep840_2_34] where REPMONTH=@repMonth and punkt in ('2.24.1'))
,[Данные УМФО] = (
                    select
					clientCount = count(*)
					from(
					select distinct
					client
					--,mainDogNum
					--,mainDogDate

					from dwh2.finAnalytics.DEPO_MONTHLY a
					where a.repmonth = @repmonth
					and upper(clientType) in ('КО')
					and mainDogDate between datefromParts(year(@repmonth),1,1) and eomonth(@repmonth)
					) l1
                )
) l1
) t2 on (t1.repmonth = @repmonth and t1.punkt in ('2.24.1'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];


--Проверка 2.29 с портфелем привлечений
merge into [dwh2].[finAnalytics].[rep840_2_34] t1
using (

select
[repmonth] = @repmonth
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Портфель сбережений. Вид контрагента "ИП", "ФЛ". По сцепке "Номер основного договора" + "Наименование займодавца" суммируем остатки. Считаем колв-о уникальных сцепок с остатками >0'
,[Данные отчета] = (select sum(value) from [dwh2].[finAnalytics].[rep840_2_34] where REPMONTH=@repMonth and punkt in ('2.29'))
,[Данные УМФО] = (
                    select
					clientCount = count(*)
					from(
					select 
					client
					,mainDogNum
					--,mainDogDate
					,restOD = sum(restOD)
					from dwh2.finAnalytics.DEPO_MONTHLY a
					where a.repmonth = @repmonth
					and upper(clientType) in ('ФЛ', 'ИП')
					and dogState != 'Закрыт'
					group by
					client
					,mainDogNum
					) l1

					where l1.restOD != 0
                )
) l1
) t2 on (t1.repmonth = @repmonth and t1.punkt in ('2.29'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];


--Проверка 2.29.1 с портфелем привлечений
merge into [dwh2].[finAnalytics].[rep840_2_34] t1
using (

select
[repmonth] = @repmonth
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Портфель сбережений. Вид контрагента "ИП", "ФЛ". По сцепке "Номер основного договора" + "Наименование займодавца" суммируем остатки. Считаем колв-о уникальных сцепок с остатками >0  Клиент не входит с справочник "Связанные лица".'
,[Данные отчета] = (select sum(value) from [dwh2].[finAnalytics].[rep840_2_34] where REPMONTH=@repMonth and punkt in ('2.29.1'))
,[Данные УМФО] = (
                    select
					clientCount = count(*)
					from(
					select 
					a.client
					,a.mainDogNum
					--,mainDogDate
					,restOD = sum(restOD)
					from dwh2.finAnalytics.DEPO_MONTHLY a
					left join [dwh2].[finAnalytics].[SPR_Affilage] b on a.inn=b.INN
					where a.repmonth = @repmonth
					and upper(a.clientType) in ('ФЛ', 'ИП')
					and b.INN is null
					--and mainDogDate between datefromParts(year(@repmonth),1,1) and eomonth(@repmonth)
					group by
					a.client
					,a.mainDogNum
					) l1

					where l1.restOD != 0
                )
) l1
) t2 on (t1.repmonth = @repmonth and t1.punkt in ('2.29.1'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];


--Проверка 2.30 с портфелем привлечений
merge into [dwh2].[finAnalytics].[rep840_2_34] t1
using (

select
[repmonth] = @repmonth
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Портфель сбережений. Вид контрагента "ИП", "ФЛ". По сцепке "Номер основного договора" + "Наименование займодавца" суммируем остатки. Считаем колв-о уникальных сцепок с остатками >0 с датой выдачи в отчетном периоде'
,[Данные отчета] = (select sum(value) from [dwh2].[finAnalytics].[rep840_2_34] where REPMONTH=@repMonth and punkt in ('2.30'))
,[Данные УМФО] = (
                   select
					clientCount = count(distinct cl_dog)
					from(
					select 
					a.client
					,a.mainDogNum
					,cl_dog = concat(a.mainDogNum,a.client)
					--,mainDogDate
					,restOD = sum(restOD)
					from dwh2.finAnalytics.DEPO_MONTHLY a
					left join [dwh2].[finAnalytics].[SPR_Affilage] b on a.inn=b.INN
					where a.repmonth = @repmonth
					and upper(a.clientType) in ('ФЛ', 'ИП')
					and b.INN is null
					and mainDogDate between datefromParts(year(@repmonth),1,1) and eomonth(@repmonth)
					group by
					a.client
					,a.mainDogNum
					,concat(a.mainDogNum,a.client)
					) l1
                )
) l1
) t2 on (t1.repmonth = @repmonth and t1.punkt in ('2.30'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];


--Проверка 2.30.1 с портфелем привлечений
merge into [dwh2].[finAnalytics].[rep840_2_34] t1
using (

select
[repmonth] = @repmonth
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Портфель сбережений. Вид контрагента "ИП", "ФЛ". По сцепке "Номер основного договора" + "Наименование займодавца" суммируем остатки. Считаем колв-о уникальных сцепок с остатками >0    с датой выдачи в отчетном периоде Клиент не входит с справочник "Связанные лица".'
,[Данные отчета] = (select sum(value) from [dwh2].[finAnalytics].[rep840_2_34] where REPMONTH=@repMonth and punkt in ('2.30.1'))
,[Данные УМФО] = (
                    select
					clientCount = count(distinct cl_dog)
					from(
					select 
					a.client
					,a.mainDogNum
					,cl_dog = concat(a.mainDogNum,a.client)
					--,mainDogDate
					,restOD = sum(restOD)
					from dwh2.finAnalytics.DEPO_MONTHLY a
					left join [dwh2].[finAnalytics].[SPR_Affilage] b on a.inn=b.INN
					where a.repmonth = @repmonth
					and upper(a.clientType) in ('ФЛ', 'ИП')
					and b.INN is null
					and mainDogDate between datefromParts(year(@repmonth),1,1) and eomonth(@repmonth)
					group by
					a.client
					,a.mainDogNum
					,concat(a.mainDogNum,a.client)
					) l1
                )
) l1
) t2 on (t1.repmonth = @repmonth and t1.punkt in ('2.30.1'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];


--Проверка 2.31 с портфелем привлечений
merge into [dwh2].[finAnalytics].[rep840_2_34] t1
using (

select
[repmonth] = @repmonth
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Портфель сбережений. Вид контрагента "ИП", "ФЛ". По сцепке "Номер основного договора" + "Наименование займодавца" суммируем остатки. Считаем колв-о уникальных Наименование займодавца  с датой выдачи в отчетном периоде'
,[Данные отчета] = (select sum(value) from [dwh2].[finAnalytics].[rep840_2_34] where REPMONTH=@repMonth and punkt in ('2.31'))
,[Данные УМФО] = (
                    select
					clientCount = count(*)
					from(
					select 
					client
					--,mainDogNum
					--,mainDogDate
					,restOD = sum(restOD)
					from dwh2.finAnalytics.DEPO_MONTHLY a
					where a.repmonth = @repmonth
					and upper(clientType) in ('ФЛ', 'ИП')
					and mainDogDate between datefromParts(year(@repmonth),1,1) and eomonth(@repmonth)
					group by
					client
					--,mainDogNum
					) l1

					--where l1.restOD != 0
                )
) l1
) t2 on (t1.repmonth = @repmonth and t1.punkt in ('2.31'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];


--Проверка 2.31.1 с портфелем привлечений
merge into [dwh2].[finAnalytics].[rep840_2_34] t1
using (

select
[repmonth] = @repmonth
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Портфель сбережений. Вид контрагента "ИП", "ФЛ". По сцепке "Номер основного договора" + "Наименование займодавца" суммируем остатки. Считаем колв-о уникальных Наименование займодавца с датой выдачи в отчетном периоде Клиент не входит с справочник "Связанные лица".'
,[Данные отчета] = (select sum(value) from [dwh2].[finAnalytics].[rep840_2_34] where REPMONTH=@repMonth and punkt in ('2.31.1'))
,[Данные УМФО] = (
                    select
					clientCount = count(*)
					from(
					select 
					a.client
					--,a.mainDogNum
					--,mainDogDate
					,restOD = sum(restOD)
					from dwh2.finAnalytics.DEPO_MONTHLY a
					left join [dwh2].[finAnalytics].[SPR_Affilage] b on a.inn=b.INN
					where a.repmonth = @repmonth
					and upper(a.clientType) in ('ФЛ', 'ИП')
					and b.INN is null
					and mainDogDate between datefromParts(year(@repmonth),1,1) and eomonth(@repmonth)
					group by
					a.client
					--,a.mainDogNum
					) l1

					--where l1.restOD != 0
                )
) l1
) t2 on (t1.repmonth = @repmonth and t1.punkt in ('2.31.1'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Тригеры ЦБ 2.23-2.25 + 2.30-2.32
merge into [dwh2].[finAnalytics].[rep840_2_34] t1
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

from dwh2.[finAnalytics].[rep840_2_34] a
where a.REPMONTH between DATEADD(month,-1,@repmonth) and @repmonth
and (a.punkt in ('2.23','2.23.1','2.24','2.24.1','2.25','2.25.1')
	or
	a.punkt in ('2.30','2.30.1','2.31','2.31.1','2.32','2.32.1')
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

end try

BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
       ,ERROR_MESSAGE() AS ErrorMessage;  
END CATCH


end
