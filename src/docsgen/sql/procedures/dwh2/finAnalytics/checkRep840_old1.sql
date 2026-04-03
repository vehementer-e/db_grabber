
CREATE PROCEDURE [finAnalytics].[checkRep840]
	@repMonth date,
    @repDate date,
    @checkMethod varchar(10)
AS
BEGIN

-----------------------------------Сверка с УМФО
if (upper(@checkMethod)='ALL' or upper(@checkMethod)='UMFO')

begin try

update finAnalytics.rep840
set checkMethod2 = null,
    chekResult2=null
where REPMONTH=@repMonth and REPDATE=@repDate


--Проверка 2.1.1 + 2.11.1 с УМФО
merge into finAnalytics.rep840 t1
using (

select
[repmonth] = @repmonth
,[repdate] = @repdate
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Сверка остатка ОД по ИП. Отчет 2.1.1 + 2.11.1 с УМФО счет 49401'
,[Данные отчета] = (select sum(value) from finAnalytics.rep840 where REPMONTH=@repMonth and REPDATE=@repDate and punkt in ('2.1.1','2.11.1'))
,[Данные УМФО] = (
                    select  
                    cast(SUM(ОстатокОДвсего) as money)
                    from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных
                    where 
                    ДатаОтчета=dateadd(year,2000,EOMONTH(@repMonth))
                    and substring(СчетОД,1,5) in ('49401')
                )
) l1
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.1.1','2.11.1'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];


--Проверка 2.1.2 + 2.11.2 с УМФО
merge into finAnalytics.rep840 t1
using (

select
[repmonth] = @repmonth
,[repdate] = @repdate
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Сверка остатка ОД по ЮЛ. Отчет 2.1.2 + 2.11.2 с УМФО счет 48701'
,[Данные отчета] = (select sum(value) from finAnalytics.rep840 where REPMONTH=@repMonth and REPDATE=@repDate and punkt in ('2.1.2','2.11.2'))
,[Данные УМФО] = (
                    select  
                    cast(SUM(ОстатокОДвсего) as money)
                    from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных
                    where 
                    ДатаОтчета=dateadd(year,2000,EOMONTH(@repMonth))
                    and substring(СчетОД,1,5) in ('48701')
                )
) l1
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.1.2','2.11.2'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];


--Проверка 2.1.3 + 2.11.3 с УМФО
merge into finAnalytics.rep840 t1
using (

select
[repmonth] = @repmonth
,[repdate] = @repdate
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Сверка остатка ОД по ФЛ. Отчет 2.1.3 + 2.11.3 с УМФО счет 48801'
,[Данные отчета] = (select sum(value) from finAnalytics.rep840 where REPMONTH=@repMonth and REPDATE=@repDate and punkt in ('2.1.3','2.11.3'))
,[Данные УМФО] = (
                    select  
                    cast(SUM(ОстатокОДвсего) as money)
                    from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных
                    where 
                    ДатаОтчета=dateadd(year,2000,EOMONTH(@repMonth))
                    and substring(СчетОД,1,5) in ('48801')
                )
) l1
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.1.3','2.11.3'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];



--Проверка 2.1 + 2.11 с УМФО
merge into finAnalytics.rep840 t1
using (

select
[repmonth] = @repmonth
,[repdate] = @repdate
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Сверка остатка ОД. Отчет 2.1 + 2.11 с УМФО счета 49401,48701,48801'
,[Данные отчета] = (select sum(value) from finAnalytics.rep840 where REPMONTH=@repMonth and REPDATE=@repDate and punkt in ('2.1','2.11'))
,[Данные УМФО] = (
                    select  
                    cast(SUM(ОстатокОДвсего) as money)
                    from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных
                    where 
                    ДатаОтчета=dateadd(year,2000,EOMONTH(@repMonth))
                    and substring(СчетОД,1,5) in ('49401','48701','48801')
                )
) l1
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.1','2.11'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];


--Проверка 2.2.1 + 2.12.1 с УМФО
merge into finAnalytics.rep840 t1
using (

select
[repmonth] = @repmonth
,[repdate] = @repdate
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Сверка остатка Проценты+Пени по ИП. Отчет 2.2.1 + 2.12.1 с УМФО счет 49401'
,[Данные отчета] = (select sum(value) from finAnalytics.rep840 where REPMONTH=@repMonth and REPDATE=@repDate and punkt in ('2.2.1','2.12.1'))
,[Данные УМФО] = (
                    select  
                    cast(SUM(ОстатокПроцентовВсего) as money) +cast(SUM(ОстатокПени) as money)
                    from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных
                    where 
                    ДатаОтчета=dateadd(year,2000,EOMONTH(@repMonth))
                    and substring(СчетОД,1,5) in ('49401')
                )
) l1
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.2.1','2.12.1'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 2.2.2 + 2.12.2 с УМФО
merge into finAnalytics.rep840 t1
using (

select
[repmonth] = @repmonth
,[repdate] = @repdate
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Сверка остатка Проценты+Пени по ЮЛ. Отчет 2.2.2 + 2.12.2 с УМФО счет 48701'
,[Данные отчета] = (select sum(value) from finAnalytics.rep840 where REPMONTH=@repMonth and REPDATE=@repDate and punkt in ('2.2.2','2.12.2'))
,[Данные УМФО] = (
                    select  
                    cast(SUM(ОстатокПроцентовВсего) as money) +cast(SUM(ОстатокПени) as money)
                    from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных
                    where 
                    ДатаОтчета=dateadd(year,2000,EOMONTH(@repMonth))
                    and substring(СчетОД,1,5) in ('48701')
                )
) l1
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.2.2','2.12.2'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 2.2.3 + 2.12.3 с УМФО
merge into finAnalytics.rep840 t1
using (

select
[repmonth] = @repmonth
,[repdate] = @repdate
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Сверка остатка Проценты+Пени по ФЛ. Отчет 2.2.3 + 2.12.3 с УМФО счет 48801'
,[Данные отчета] = (select sum(value) from finAnalytics.rep840 where REPMONTH=@repMonth and REPDATE=@repDate and punkt in ('2.2.3','2.12.3'))
,[Данные УМФО] = (
                    select  
                    cast(SUM(ОстатокПроцентовВсего) as money) +cast(SUM(ОстатокПени) as money)
                    from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных
                    where 
                    ДатаОтчета=dateadd(year,2000,EOMONTH(@repMonth))
                    and substring(СчетОД,1,5) in ('48801')
                )
) l1
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.2.3','2.12.3'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];


--Проверка 2.2 + 2.12 с УМФО
merge into finAnalytics.rep840 t1
using (

select
[repmonth] = @repmonth
,[repdate] = @repdate
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Сверка остатка Проценты+Пени. Отчет 2.2 + 2.12 с УМФО счета 49401,48701,48801'
,[Данные отчета] = (select sum(value) from finAnalytics.rep840 where REPMONTH=@repMonth and REPDATE=@repDate and punkt in ('2.2','2.12'))
,[Данные УМФО] = (
                    select  
                    cast(SUM(ОстатокПроцентовВсего) as money) +cast(SUM(ОстатокПени) as money)
                    from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных
                    where 
                    ДатаОтчета=dateadd(year,2000,EOMONTH(@repMonth))
                    and substring(СчетОД,1,5) in ('49401','48701','48801')
                )
) l1
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.2','2.12'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

/*
--Проверка 2.3 + 2.13 с УМФО
merge into finAnalytics.rep840 t1
using (

select
[repmonth] = @repmonth
,[repdate] = @repdate
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: Количество не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Сверка: Количество действующих договоров. Отчет 2.3 + 2.13 с УМФО счета 49401,48701,48801'
,[Данные отчета] = (select sum(value) from finAnalytics.rep840 where REPMONTH=@repMonth and REPDATE=@repDate and punkt in ('2.3','2.13'))
,[Данные УМФО] = (
                    select  
                    cast(count(a.НомерДоговора) as int)
                    from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a
                    where 
                    a.ДатаОтчета=dateadd(year,2000,EOMONTH(@repMonth))
                    and substring(a.СчетОД,1,5) in ('49401','48701','48801')
                    and (a.Статус='Действует' or isnull(a.ДатаЗакрытия,getdate()) >=EOMONTH(@repMonth))
                    and (
                    upper(a.НаименованиеЗаемщика) not like upper('%Техмани%')
                    and
                    upper(a.НаименованиеЗаемщика) not like upper('%АйОТи%')
                    )
                    and (
                        a.ОстатокОДвсего!=0
                        or
                        a.ОстатокПроцентовВсего!=0
                        or
                        a.ОстатокПени!=0
                        or 
                        a.ОстатокРезерв!=0
                        )
                    )

) l1
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.3','2.13'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];
*/
--Проверка 2.3.1 + 2.13.1 с УМФО
merge into finAnalytics.rep840 t1
using (

select
[repmonth] = @repmonth
,[repdate] = @repdate
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: Количество не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Сверка: Количество действующих договоров ИП. Отчет 2.3.1 + 2.13.1 с УМФО счета 49401'
,[Данные отчета] = (select sum(value) from finAnalytics.rep840 where REPMONTH=@repMonth and REPDATE=@repDate and punkt in ('2.3.1','2.13.1'))
,[Данные УМФО] = (
                    select  
                    cast(count(a.НомерДоговора) as int)
                    from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a
                    where 
                    a.ДатаОтчета=dateadd(year,2000,EOMONTH(@repMonth))
                    and substring(a.СчетОД,1,5) in ('49401')
                    and (a.Статус='Действует' or isnull(a.ДатаЗакрытия,getdate()) >=EOMONTH(dateadd(year,2000,@repMonth)))
                    and (
                    upper(a.НаименованиеЗаемщика) not like upper('%Техмани%')
                    and
                    upper(a.НаименованиеЗаемщика) not like upper('%АйОТи%')
                    )
                    and (
                        a.ОстатокОДвсего!=0
                        or
                        a.ОстатокПроцентовВсего!=0
                        or
                        a.ОстатокПени!=0
                        or 
                        a.ОстатокРезерв!=0
                        )
                    )

) l1
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.3.1','2.13.1'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];


--Проверка 2.3.2 + 2.13.2 с УМФО
merge into finAnalytics.rep840 t1
using (

select
[repmonth] = @repmonth
,[repdate] = @repdate
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: Количество не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Сверка: Количество действующих договоров ИП. Отчет 2.3.2 + 2.13.2 с УМФО счета 48701'
,[Данные отчета] = (select sum(value) from finAnalytics.rep840 where REPMONTH=@repMonth and REPDATE=@repDate and punkt in ('2.3.2','2.13.2'))
,[Данные УМФО] = (
                    select  
                    cast(count(a.НомерДоговора) as int)
                    from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a
                    where 
                    a.ДатаОтчета=dateadd(year,2000,EOMONTH(@repMonth))
                    and substring(a.СчетОД,1,5) in ('48701')
                    and (a.Статус='Действует' or isnull(a.ДатаЗакрытия,getdate()) >=EOMONTH(dateadd(year,2000,@repMonth)))
                    and (
                    upper(a.НаименованиеЗаемщика) not like upper('%Техмани%')
                    and
                    upper(a.НаименованиеЗаемщика) not like upper('%АйОТи%')
                    )
                    and (
                        a.ОстатокОДвсего!=0
                        or
                        a.ОстатокПроцентовВсего!=0
                        or
                        a.ОстатокПени!=0
                        or 
                        a.ОстатокРезерв!=0
                        )
                    )

) l1
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.3.2','2.13.2'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];
/*
--Проверка 2.3.3 + 2.13.3 с УМФО
merge into finAnalytics.rep840 t1
using (

select
[repmonth] = @repmonth
,[repdate] = @repdate
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: Количество не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = 'Сверка: Количество действующих договоров ФЛ. Отчет 2.3.3 + 2.13.3 с УМФО счета 48801'
,[Данные отчета] = (select sum(value) from finAnalytics.rep840 where REPMONTH=@repMonth and REPDATE=@repDate and punkt in ('2.3.3','2.13.3'))
,[Данные УМФО] = (
                    select  
                    cast(count(a.НомерДоговора) as int)
                    from stg._1cUMFO.РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных a
                    where 
                    a.ДатаОтчета=dateadd(year,2000,EOMONTH(@repMonth))
                    and substring(a.СчетОД,1,5) in ('48801')
                    and (a.Статус='Действует' or isnull(a.ДатаЗакрытия,getdate()) >=EOMONTH(@repMonth))
                    and (
                    upper(a.НаименованиеЗаемщика) not like upper('%Техмани%')
                    and
                    upper(a.НаименованиеЗаемщика) not like upper('%АйОТи%')
                    )
                    and (
                        a.ОстатокОДвсего!=0
                        or
                        a.ОстатокПроцентовВсего!=0
                        or
                        a.ОстатокПени!=0
                        or 
                        a.ОстатокРезерв!=0
                        )
                    )

) l1
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.3.3','2.13.3'))
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];
*/


end try

BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
       ,ERROR_MESSAGE() AS ErrorMessage;  
END CATCH


-----------------------------------Указания ЦБ
if (upper(@checkMethod)='ALL' or upper(@checkMethod)='CB')

begin TRY

update finAnalytics.rep840
set checkMethod1 = null,
    chekResult1=null
where REPMONTH=@repMonth and REPDATE=@repDate

--Проверка 2.1 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.1 должна быть равна сумме данных по строкам 2.1.1, 2.1.2 и 2.1.3'
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.1') then value else 0 end res1
,case when punkt in ('2.1.1','2.1.2','2.1.3') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.1','2.1.1','2.1.2','2.1.3')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.1'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.1.1 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.1.1 должна быть больше суммы данных по строке 2.1.1.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.1.1') then value else 0 end res1
,case when punkt in ('2.1.1.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.1.1','2.1.1.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.1.1'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.1.2 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.1.2 должна быть больше суммы данных по строке 2.1.2.1 или равна ей.'
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.1.2') then value else 0 end res1
,case when punkt in ('2.1.2.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.1.2','2.1.2.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.1.2'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.1.3 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.1.3 должна быть больше суммы данных по строкам 2.1.3.1 - 2.1.3.5 или равна ей'
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.1.3') then value else 0 end res1
,case when punkt in ('2.1.3.1','2.1.3.2','2.1.3.3','2.1.3.4','2.1.3.5') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.1.3','2.1.3.1','2.1.3.2','2.1.3.3','2.1.3.4','2.1.3.5')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.1.3'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.1.3.5 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.1.3.5 должна быть больше суммы данных по строке 2.1.3.5.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.1.3.5') then value else 0 end res1
,case when punkt in ('2.1.3.5.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.1.3.5','2.1.3.5.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.1.3.5'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.2 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.2 должна быть равна сумме данных по строкам 2.2.1, 2.2.2 и 2.2.3'
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.2') then value else 0 end res1
,case when punkt in ('2.2.1','2.2.2','2.2.3') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.2','2.2.1','2.2.2','2.2.3')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.2'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.2.1 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.2.1 должна быть больше суммы данных по строке 2.2.1.1 или равна ей'
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.2.1') then value else 0 end res1
,case when punkt in ('2.2.1.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.2.1','2.2.1.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.2.1'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.2.2 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.2.2 должна быть больше суммы данных по строке 2.2.2.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.2.2') then value else 0 end res1
,case when punkt in ('2.2.2.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.2.2','2.2.2.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.2.2'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.2.3 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.2.3 должна быть больше суммы данных по строкам 2.2.3.1 - 2.2.3.5 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.2.3') then value else 0 end res1
,case when punkt in ('2.2.3.1','2.2.3.2','2.2.3.3','2.2.3.4','2.2.3.5') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.2.3','2.2.3.1','2.2.3.2','2.2.3.3','2.2.3.4','2.2.3.5')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.2.3'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.2.3.5 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.2.3.5 должна быть больше суммы данных по строке 2.2.3.5.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.2.3.5') then value else 0 end res1
,case when punkt in ('2.2.3.5.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.2.3.5','2.2.3.5.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.2.3.5'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.3 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.3 должно быть равно общему количеству договоров по строкам 2.3.1, 2.3.2 и 2.3.3'
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.3') then value else 0 end res1
,case when punkt in ('2.3.1','2.3.2','2.3.3') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.3','2.3.1','2.3.2','2.3.3')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.3'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.3.1 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.3.1 должно быть больше количества договоров по строке 2.3.1.1 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.3.1') then value else 0 end res1
,case when punkt in ('2.3.1.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.3.1','2.3.1.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.3.1'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.3.2 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.3.2 должно быть больше количества договоров по строке 2.3.2.1 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.3.2') then value else 0 end res1
,case when punkt in ('2.3.2.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.3.2','2.3.2.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.3.2'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.3.3 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.3.3 должно быть больше общего количества договоров по строкам 2.3.3.1 - 2.3.3.5 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.3.3') then value else 0 end res1
,case when punkt in ('2.3.3.1','2.3.3.2','2.3.3.3','2.3.3.4','2.3.3.5') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.3.3','2.3.3.1','2.3.3.2','2.3.3.3','2.3.3.4','2.3.3.5')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.3.3'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.3.3.5 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.3.3.5 должно быть больше количества договоров по строке 2.3.3.5.1 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.3.3.5') then value else 0 end res1
,case when punkt in ('2.3.3.5.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.3.3.5','2.3.3.5.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.3.3.5'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.4 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество заемщиков по строке 2.4 должно быть равно общему количеству заемщиков по строкам 2.4.1, 2.4.2 и 2.4.3'
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.4') then value else 0 end res1
,case when punkt in ('2.4.1','2.4.2','2.4.3') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.4','2.4.1','2.4.2','2.4.3')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.4'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.4.1 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество заемщиков по строке 2.4.1 должно быть больше количества заемщиков по строке 2.4.1.1 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.4.1') then value else 0 end res1
,case when punkt in ('2.4.1.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.4.1','2.4.1.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.4.1'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.4.2 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество заемщиков по строке 2.4.2 должно быть больше количества заемщиков по строке 2.4.2.1 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.4.2') then value else 0 end res1
,case when punkt in ('2.4.2.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.4.2','2.4.2.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.4.2'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.4.3 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество заемщиков по строке 2.4.3 должно быть больше количества заемщиков по строке 2.4.3.1, 
                    либо по строке 2.4.3.2, либо по строке 2.4.3.3, либо по строке 2.4.3.4, либо по строке 2.4.3.5 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.4.3') then value else 0 end res1
,case when punkt in ('2.4.3.1','2.4.3.2','2.4.3.3','2.4.3.4','2.4.3.5') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.4.3','2.4.3.1','2.4.3.2','2.4.3.3','2.4.3.4','2.4.3.5')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.4.3'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.4.3.5 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество заемщиков по строке 2.4.3.5 должно быть больше количества заемщиков по строке 2.4.3.5.1 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.4.3.5') then value else 0 end res1
,case when punkt in ('2.4.3.5.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.4.3.5','2.4.3.5.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.4.3.5'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.5 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.5 должно быть равно общему количеству договоров по строкам 2.5.1, 2.5.2 и 2.5.3'
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.5') then value else 0 end res1
,case when punkt in ('2.5.1','2.5.2','2.5.3') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.5','2.5.1','2.5.2','2.5.3')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.5'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.5.1 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.5.1 должно быть больше количества договоров по строке 2.5.1.1 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.5.1') then value else 0 end res1
,case when punkt in ('2.5.1.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.5.1','2.5.1.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.5.1'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.5.2 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.5.2 должно быть больше количества договоров по строке 2.5.2.1 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.5.2') then value else 0 end res1
,case when punkt in ('2.5.2.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.5.2','2.5.2.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.5.2'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.5.3 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.5.3 должно быть больше общего количества договоров по строкам 2.5.3.1 - 2.5.3.5 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.5.3') then value else 0 end res1
,case when punkt in ('2.5.3.1','2.5.3.2','2.5.3.3','2.5.3.4','2.5.3.5') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.5.3','2.5.3.1','2.5.3.2','2.5.3.3','2.5.3.4','2.5.3.5')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.5.3'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.5.3.5 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.5.3.5 должно быть больше количества договоров по строке 2.5.3.5.1 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.5.3.5') then value else 0 end res1
,case when punkt in ('2.5.3.5.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.5.3.5','2.5.3.5.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.5.3.5'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.6 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.6 должна быть равна сумме данных по строкам 2.6.1, 2.6.2 и 2.6.3 '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.6') then value else 0 end res1
,case when punkt in ('2.6.1','2.6.2','2.6.3') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.6','2.6.1','2.6.2','2.6.3')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.6'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.6.1 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.6.1 должна быть больше суммы данных по строке 2.6.1.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.6.1') then value else 0 end res1
,case when punkt in ('2.6.1.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.6.1','2.6.1.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.6.1'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.6.2 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.6.2 должна быть больше суммы данных по строке 2.6.2.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.6.2') then value else 0 end res1
,case when punkt in ('2.6.2.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.6.2','2.6.2.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.6.2'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.6.3 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.6.3 должна быть больше суммы данных по строкам 2.6.3.1 - 2.6.3.5 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.6.3') then value else 0 end res1
,case when punkt in ('2.6.3.1','2.6.3.2','2.6.3.3','2.6.3.4','2.6.3.5') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.6.3','2.6.3.1','2.6.3.2','2.6.3.3','2.6.3.4','2.6.3.5')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.6.3'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.6.3.5 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.6.3.5 должна быть больше суммы данных по строке 2.6.3.5.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.6.3.5') then value else 0 end res1
,case when punkt in ('2.6.3.5.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.6.3.5','2.6.3.5.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.6.3.5'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.7 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.7 должна быть больше суммы данных по строке 2.7.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.7') then value else 0 end res1
,case when punkt in ('2.7.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.7','2.7.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.7'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.8 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.8 должна быть больше суммы данных по строке 2.8.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.8') then value else 0 end res1
,case when punkt in ('2.8.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.8','2.8.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.8'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.9 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.9 должна быть больше суммы данных по строке 2.9.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.9') then value else 0 end res1
,case when punkt in ('2.9.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.9','2.9.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.9'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.10 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.10 должна быть больше суммы данных по строке 2.10.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.10') then value else 0 end res1
,case when punkt in ('2.10.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.10','2.10.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.10'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.11 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.11 должна быть равна сумме данных по строкам 2.11.1, 2.11.2 и 2.11.3 '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.11') then value else 0 end res1
,case when punkt in ('2.11.1','2.11.2','2.11.3') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.11','2.11.1','2.11.2','2.11.3')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.11'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.11.1 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.11.1 Отчета должна быть больше суммы данных по строке 2.11.1.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.11.1') then value else 0 end res1
,case when punkt in ('2.11.1.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.11.1','2.11.1.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.11.1'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.11.2 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.11.2 должна быть больше суммы данных по строке 2.11.2.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.11.2') then value else 0 end res1
,case when punkt in ('2.11.2.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.11.2','2.11.2.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.11.2'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.11.3 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.11.3 должна быть больше суммы данных по строкам 2.11.3.1 - 2.11.3.4 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.11.3') then value else 0 end res1
,case when punkt in ('2.11.3.1','2.11.3.2','2.11.3.3','2.11.3.4') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.11.3','2.11.3.1','2.11.3.2','2.11.3.3','2.11.3.4')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.11.3'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.12 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.12 должна быть равна сумме данных по строкам 2.12.1, 2.12.2 и 2.12.3. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.12') then value else 0 end res1
,case when punkt in ('2.12.1','2.12.2','2.12.3') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.12','2.12.1','2.12.2','2.12.3')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.12'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.12.1 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.12.1 должна быть больше суммы данных по строке 2.12.1.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.12.1') then value else 0 end res1
,case when punkt in ('2.12.1.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.12.1','2.12.1.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.12.1'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.12.2 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.12.2 должна быть больше суммы данных по строке 2.12.2.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.12.2') then value else 0 end res1
,case when punkt in ('2.12.2.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.12.2','2.12.2.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.12.2'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.12.3 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.12.3 должна быть больше суммы данных по строкам 2.12.3.1 - 2.12.3.4 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.12.3') then value else 0 end res1
,case when punkt in ('2.12.3.1','2.12.3.2','2.12.3.3','2.12.3.4') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.12.3','2.12.3.1','2.12.3.2','2.12.3.3','2.12.3.4')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.12.3'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.13 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.13 должно быть равно общему количеству договоров по строкам 2.13.1, 2.13.2 и 2.13.3 . '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.13') then value else 0 end res1
,case when punkt in ('2.13.1','2.13.2','2.13.3') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.13','2.13.1','2.13.2','2.13.3')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.13'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.13.1 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.13.1 должно быть больше количества договоров по строке 2.13.1.1 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.13.1') then value else 0 end res1
,case when punkt in ('2.13.1.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.13.1','2.13.1.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.13.1'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.13.2 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.13.2 должно быть больше количества договоров по строке 2.13.2.1 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.13.2') then value else 0 end res1
,case when punkt in ('2.13.2.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.13.2','2.13.2.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.13.2'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.13.3 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.13.3 должно быть больше общего количества договоров по строкам 2.13.3.1 - 2.13.3.4 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.13.3') then value else 0 end res1
,case when punkt in ('2.13.3.1','2.13.3.2','2.13.3.3','2.13.3.4') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.13.3','2.13.3.1','2.13.3.2','2.13.3.3','2.13.3.4')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.13.3'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.14.1 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество заемщиков по строке 2.14.1 должно быть больше количества заемщиков по строке 2.14.1.1 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.14.1') then value else 0 end res1
,case when punkt in ('2.14.1.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.14.1','2.14.1.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.14.1'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.14.2 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество заемщиков по строке 2.14.2 должно быть больше количества заемщиков по строке 2.14.2.1 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.14.2') then value else 0 end res1
,case when punkt in ('2.14.2.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.14.2','2.14.2.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.14.2'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.14.3 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество заемщиков по строке 2.14.3 должно быть больше количества заемщиков по строке 2.14.3.1, 
                    либо по строке 2.14.3.2, либо по строке 2.14.3.3, либо по строке 2.14.3.4 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.14.3') then value else 0 end res1
,case when punkt in ('2.14.2.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.14.3','2.14.3.1','2.14.3.2','2.14.3.3','2.14.3.4')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.14.3'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.15 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.15 должно быть равно общему количеству договоров по строкам 2.15.1, 2.15.2 и 2.15.3 .'
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.15') then value else 0 end res1
,case when punkt in ('2.15.1','2.15.2','2.15.3') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.15','2.15.1','2.15.2','2.15.3')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.15'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.15.1 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.15.1 должно быть больше количества договоров по строке 2.15.1.1 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.15.1') then value else 0 end res1
,case when punkt in ('2.15.1.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.15.1','2.15.1.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.15.1'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.15.2 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.15.2 должно быть больше количества договоров по строке 2.15.2.1 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.15.2') then value else 0 end res1
,case when punkt in ('2.15.2.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.15.2','2.15.2.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.15.2'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.15.3 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Количество договоров по строке 2.15.3 должно быть больше общего количества договоров по строкам 2.15.3.1 - 2.15.3.4 или равно ему. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.15.3') then value else 0 end res1
,case when punkt in ('2.15.2.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.15.3','2.15.3.1','2.15.3.2','2.15.3.3','2.15.3.4')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.15.3'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.16 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.16 должна быть равна сумме данных по строкам 2.16.1, 2.16.2 и 2.16.3 . '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.16') then value else 0 end res1
,case when punkt in ('2.16.1','2.16.2','2.16.3') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.16','2.16.1','2.16.2','2.16.3')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.16'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.16.1 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.16.1 должна быть больше суммы данных по строке 2.16.1.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.16.1') then value else 0 end res1
,case when punkt in ('2.16.1.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.16.1','2.16.1.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.16.1'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.16.2 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.16.2 должна быть больше суммы данных по строке 2.16.2.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.16.2') then value else 0 end res1
,case when punkt in ('2.16.2.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.16.2','2.16.2.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.16.2'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.16.3 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.16.3 должна быть больше суммы данных по строкам 2.16.3.1 - 2.16.3.4 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.16.3') then value else 0 end res1
,case when punkt in ('2.16.2.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.16.3','2.16.3.1','2.16.3.2','2.16.3.3','2.16.3.4')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.16.3'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.17 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.17 должна быть больше суммы данных по строке 2.17.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.17') then value else 0 end res1
,case when punkt in ('2.17.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.17','2.17.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.17'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.18 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.18 должна быть больше суммы данных по строке 2.18.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.18') then value else 0 end res1
,case when punkt in ('2.18.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.18','2.18.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.18'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.19 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.19 должна быть больше суммы данных по строке 2.19.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.19') then value else 0 end res1
,case when punkt in ('2.19.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.19','2.19.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.19'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

--Проверка 2.20 и подпункты
merge into finAnalytics.rep840 t1
using (
select
l2.repmonth
,l2.repdate
,l2.[Что проверяем]
,l2.Данные1
,l2.Данные2
,[Результат] = case when l2.Данные1>=l2.Данные2 then 'OK' else 'Ошибка: Сумма подстрок не совпадает ' end 
from (
select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Что проверяем] = 'Сумма данных по строке 2.20 должна быть больше суммы данных по строке 2.20.1 или равна ей. '
,[Данные1] = cast(sum(l1.res1) as money)
,[Данные2] = cast(sum(l1.res2) as money)
from(
select
case when punkt in ('2.20') then value else 0 end res1
,case when punkt in ('2.20.1') then value else 0 end res2
from finAnalytics.rep840
where REPMONTH=@repmonth and REPDATE=@repdate
and punkt in ('2.20','2.20.1')
) l1
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.20'))
when matched then update
set t1.checkMethod1=t2.[Что проверяем],
    t1.chekResult1=t2.[Результат];

end try

BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
       ,ERROR_MESSAGE() AS ErrorMessage;  
END CATCH



-----------------------------------Тригеры ЦБ
if (upper(@checkMethod)='ALL' or upper(@checkMethod)='TRIG')

begin try

update finAnalytics.rep840
set checkMethod3 = null,
    chekResult3=null
where REPMONTH=@repMonth and REPDATE=@repDate


--Проверка 2.1 + 2.11 с прошлым периодом
merge into finAnalytics.rep840 t1
using (

select
[repmonth] = @repmonth
,[repdate] = @repdate
,l1.[Что проверяем]
,l1.[Данные отчета]
,l1.[Данные УМФО]
,[Результат] = case when cast(abs(l1.[Данные отчета]-l1.[Данные УМФО]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета]-l1.[Данные УМФО] as money) as varchar)) end 
from(
select
[Что проверяем] = '2.1+2.11 за отчетный период должен быть равен 2.1+2.11 предыдущего периода (декабрь прошлого года) + 2.6 + 2.16 отчетного периода минус 2.7 минус 2.17 минус 2.10.1 минус 2.20.1 минус 2.50.1.1 отчетного периода. '
,[Данные отчета] = (select sum(value) from finAnalytics.rep840 where REPMONTH=@repMonth /*and REPDATE=@repDate*/ and punkt in ('2.1','2.11'))
,[Данные УМФО] = (select sum(value) from finAnalytics.rep840 where REPMONTH=datefromparts(year(dateadd(year,-1,@repMonth)),12,1) and punkt in ('2.1','2.11'))
                 +
                 (select sum(value) from finAnalytics.rep840 where REPMONTH=@repMonth /*and REPDATE=@repDate*/ and punkt in ('2.6','2.16'))
                 -
                 (select sum(value) from finAnalytics.rep840 where REPMONTH=@repMonth /*and REPDATE=@repDate*/ and punkt in ('2.7','2.17','2.10.1','2.20.1'/*,'2.50.1.1'*/))
				 -
                 (select sum(value) from finAnalytics.rep840_2_5 where REPMONTH=@repMonth /*and REPDATE=@repDate*/ and punkt in ('2.50.1.1'))

) l1
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt in ('2.1','2.11'))
when matched then update
set t1.checkMethod3=t2.[Что проверяем],
    t1.chekResult3=t2.[Результат];

--Проверка 2.5-2.10 + 2.15-2.20 с прошлым периодом
merge into finAnalytics.rep840 t1
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

from dwh2.[finAnalytics].[rep840] a
where a.REPMONTH between DATEADD(month,-1,@repmonth) and @repmonth
and (a.punkt in ('2.5','2.5.1','2.5.1.1','2.5.2','2.5.2.1','2.5.3','2.5.3.1','2.5.3.2','2.5.3.3','2.5.3.4','2.5.3.5','2.5.3.5.1','2.6'
				,'2.6.1','2.6.1.1','2.6.2','2.6.2.1','2.6.3','2.6.3.1','2.6.3.2','2.6.3.3','2.6.3.4','2.6.3.5','2.6.3.5.1','2.7'
				,'2.7.1','2.8','2.8.1','2.9','2.9.1','2.10','2.10.1')
	or
	a.punkt in ('2.15','2.15.1','2.15.1.1','2.15.2','2.15.2.1','2.15.3','2.15.3.1','2.15.3.2','2.15.3.3','2.15.3.4','2.16','2.16.1'
				,'2.16.1.1','2.16.2','2.16.2.1','2.16.3','2.16.3.1','2.16.3.2','2.16.3.3','2.16.3.4','2.17','2.17.1','2.18','2.18.1'
				,'2.19','2.19.1','2.20','2.20.1')
	)
) l1

group by
l1.repmonth
,l1.punkt
) l2
) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.punkt =t2.punkt)
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