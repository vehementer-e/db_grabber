
CREATE PROCEDURE [finAnalytics].[checkRep840_4]
	@repMonth date,
    @repDate date,
    @checkMethod varchar(10)
AS
BEGIN

-----------------------------------Сверка с УМФО
if (upper(@checkMethod)='ALL' or upper(@checkMethod)='UMFO')

DROP TABLE IF  EXISTS  [finAnalytics].#ID_LIST
Create table [finAnalytics].#ID_LIST(
    [ID] bigint NOT NULL
    )

insert into #ID_LIST
select
a.ID
from finAnalytics.PBR_MONTHLY a
where a.REPMONTH=@REPMONTH --and a.REPDATE=@REPDATE

DROP TABLE IF  EXISTS  [finAnalytics].#PBR
Create table [finAnalytics].#PBR(
    [restOD] float NOT NULL,
    [restPRC] float NOT NULL,
    [restPenia] float NOT NULL,
    [reservOD] float NOT NULL,
    [reservPRC] float NOT NULL,
    [reservProchSumNU] float NOT NULL,
    [prosDaysTotal] int null,
    [prosDaysTotalinReserv] int null,
    [prosCategory] int not null, 
    [isZaemshik] nvarchar(10) not null,
    [dogSum] float NOT NULL,
    [dogPeriodDays] int null, 
    [isRestruk] nvarchar(10) not null,
    [isObespechZaym] nvarchar(10) not null,
    [isMSPbyRepDate] nvarchar(10) null,
    [isMSPbyDogDate] nvarchar(10) null,
    [isMSP] nvarchar(10) null,
    [PSK_prc] float null,
	[nomenkGroup] nvarchar(300) null
    )

insert into #PBR
select
--l1.dogNum
l2.zadolgOD
,l2.zadolgPrc
,l2.penyaSum
,l2.reservOD
,l2.reservPRC
,l2.reservProchSumNU
/*
@prosCategory:
1 -"Итого дней просрочки"(18) равно "0"
2 - "Итого дней просрочки"(18) больше или равно 1 и меньше или равно 7
3 - "Итого дней просрочки"(18) больше или равно 8 и меньше или равно 30
4 - "Итого дней просрочки"(18) больше или равно 31 и меньше или равно 60
5 - "Итого дней просрочки"(18) больше или равно 61 и меньше или равно 90
6 - "Итого дней просрочки"(18) больше или равно 91 и меньше или равно 120
7 - "Итого дней просрочки"(18) больше или равно 121 и меньше или равно 180
8 - "Итого дней просрочки"(18) больше или равно 181 и меньше или равно 270
9 - "Итого дней просрочки"(18) больше или равно 271 и меньше или равно 360
10 - "Итого дней просрочки"(18) больше или равно 361
*/
,l2.prosDaysTotal
,l2.allPros
,case when l2.prosCategory=0 then 1
      when l2.prosCategory between 1 and 7 then 2
      when l2.prosCategory between 8 and 30 then 3
      when l2.prosCategory between 31 and 60 then 4
      when l2.prosCategory between 61 and 90 then 5
      when l2.prosCategory between 91 and 120 then 6
      when l2.prosCategory between 121 and 180 then 7
      when l2.prosCategory between 181 and 270 then 8
      when l2.prosCategory between 271 and 360 then 9
      when l2.prosCategory >360 then 10
      end
,l2.isZaemshik
,l2.dogSum
,l2.dogPeriodDays
,l2.isRestruk
,l2.isObespechZaym
,isMSPbyRepDate = isnull(l2.isMSPbyRepDate,'Нет')
,isMSPbyDogDate = isnull(l2.isMSPbyDogDate,'Нет')
,l2.isMSP
,l2.PSK_prc 
,l2.nomenkGroup
from(

select
a.dogNum
,a.[zadolgOD]
,a.[zadolgPrc]
,a.[penyaSum]
,a.[reservOD]
,a.[reservPRC]
,a.[reservProchSumNU]
,a.prosDaysTotal
,c.allPros
,a.[isZaemshik]
,a.[dogSum]
,a.[dogPeriodDays]
,a.[isRestruk]
,a.[isObespechZaym]
,a.[isMSPbyRepDate]
,a.[isMSPbyDogDate]
,a.[isMSP]
,[prosCategory] = case when a.[zadolgOD]=0 and a.[zadolgPrc]=0 and a.[penyaSum] !=0 then isnull(c.[allPros],a.prosDaysTotal) else a.prosDaysTotal end
,a.PSK_prc 
,a.nomenkGroup
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.id=b.ID
left join finAnalytics.Reserv_NU c on a.dogNum=c.dogNum and a.REPMONTH=c.REPMONTH
) l2


begin try

update finAnalytics.rep840_4
set checkMethod2 = null,
    chekResult2=null
where REPMONTH=@repMonth and REPDATE=@repDate


--Проверка 4.1 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" равно "0". Сумма по полю "Задолженность ОД", по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=1)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=1
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =1)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.1_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" равно "0". Сумма по полю "Резерв ОД",по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=2)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=1
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =2)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.1.1 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" равно "0". Сумма по полю "Задолженность ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=3)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)) as money)
                    from #PBR
                    where prosCategory=1
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =3)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.1.1_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" равно "0". Сумма по полю "Резерв ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=4)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)) as money)
                    from #PBR
                    where prosCategory=1
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =4)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.1.2 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" равно "0". Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=5)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=1
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =5)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.1.2_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" равно "0". Сумма по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=6)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=1
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =6)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.2 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 1 и меньше или равно 7. Сумма по полю "Задолженность ОД",по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=7)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=2
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =7)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.2_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 1 и меньше или равно 7. Сумма по полю "Резерв ОД",по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=8)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=2
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =8)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.2.1 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 1 и меньше или равно 7. Сумма по полю "Задолженность ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=9)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)/*+isnull(restPRC,0)+isnull(restPenia,0)*/) as money)
                    from #PBR
                    where prosCategory=2
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =9)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.2.1_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 1 и меньше или равно 7. Сумма по полю "Резерв ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=10)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)/*+isnull(reservPRC,0)+isnull(reservProchSumNU,0)*/) as money)
                    from #PBR
                    where prosCategory=2
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =10)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.2.2 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 1 и меньше или равно 7. Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=11)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(restOD,0)+*/isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=2
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =11)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.2.2_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 1 и меньше или равно 7. Сумма по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=12)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(reservOD,0)+*/isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=2
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =12)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.3 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 8 и меньше или равно 30. Сумма по полю "Задолженность ОД",по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=13)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=3
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =13)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.3_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 8 и меньше или равно 30. Сумма по полю "Резерв ОД",по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=14)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=3
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =14)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.3.1 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 8 и меньше или равно 30. Сумма по полю "Задолженность ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=15)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)/*+isnull(restPRC,0)+isnull(restPenia,0)*/) as money)
                    from #PBR
                    where prosCategory=3
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =15)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.3.1_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 8 и меньше или равно 30. Сумма по полю "Резерв ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=16)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)/*+isnull(reservPRC,0)+isnull(reservProchSumNU,0)*/) as money)
                    from #PBR
                    where prosCategory=3
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =16)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];


--Проверка 4.3.2 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 8 и меньше или равно 30. Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=17)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(restOD,0)+*/isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=3
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =17)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.3.2_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 8 и меньше или равно 30. Сумма по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=18)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(reservOD,0)+*/isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=3
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =18)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.4 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 31 и меньше или равно 60. Сумма по полю "Задолженность ОД", по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=19)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=4
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =19)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.4_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 31 и меньше или равно 60. Сумма по полю "Резерв ОД",по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=20)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=4
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =20)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.4.1 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 31 и меньше или равно 60. Сумма по полю "Задолженность ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=21)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)/*+isnull(restPRC,0)+isnull(restPenia,0)*/) as money)
                    from #PBR
                    where prosCategory=4
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =21)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.4.1_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 31 и меньше или равно 60. Сумма по полю "Резерв ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=22)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)/*+isnull(reservPRC,0)+isnull(reservProchSumNU,0)*/) as money)
                    from #PBR
                    where prosCategory=4
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =22)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];


--Проверка 4.4.2 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 31 и меньше или равно 60. Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=23)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(restOD,0)+*/isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=4
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =23)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.4.2_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 31 и меньше или равно 60. Сумма по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=24)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(reservOD,0)+*/isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=4
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =24)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.5 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 61 и меньше или равно 90. Сумма по полю "Задолженность ОД",по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=25)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=5
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =25)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.5_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 61 и меньше или равно 90. Сумма по полю "Резерв ОД", по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=26)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=5
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =26)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.5.1 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 61 и меньше или равно 90. Сумма по полю "Задолженность ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=27)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)/*+isnull(restPRC,0)+isnull(restPenia,0)*/) as money)
                    from #PBR
                    where prosCategory=5
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =27)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.5.1_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 61 и меньше или равно 90. Сумма по полю "Резерв ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=28)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)/*+isnull(reservPRC,0)+isnull(reservProchSumNU,0)*/) as money)
                    from #PBR
                    where prosCategory=5
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =28)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.5.2 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 61 и меньше или равно 90. Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=29)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(restOD,0)+*/isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=5
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =29)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.5.2_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 61 и меньше или равно90. Сумма по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=30)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(reservOD,0)+*/isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=5
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =30)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.6 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 91 и меньше или равно 120. Сумма по полю "Задолженность ОД",по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=31)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=6
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =31)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.6_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 91 и меньше или равно 120. Сумма по полю "Резерв ОД", по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=32)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=6
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =32)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.6.1 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 91 и меньше или равно 120. Сумма по полю "Задолженность ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=33)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)/*+isnull(restPRC,0)+isnull(restPenia,0)*/) as money)
                    from #PBR
                    where prosCategory=6
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =33)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.6.1_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 91 и меньше или равно 120. Сумма по полю "Резерв ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=34)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)/*+isnull(reservPRC,0)+isnull(reservProchSumNU,0)*/) as money)
                    from #PBR
                    where prosCategory=6
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =34)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.6.2 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 91 и меньше или равно 120. Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=35)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(restOD,0)+*/isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=6
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =35)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.6.2_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 91 и меньше или равно 120. Сумма по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=36)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(reservOD,0)+*/isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=6
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =36)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.7 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 121 и меньше или равно 180. Сумма по полю "Задолженность ОД",по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=37)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=7
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =37)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.7_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 121 и меньше или равно 180. Сумма по полю "Резерв ОД", по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=38)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=7
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =38)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.7.1 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 121 и меньше или равно 180. Сумма по полю "Задолженность ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=39)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)/*+isnull(restPRC,0)+isnull(restPenia,0)*/) as money)
                    from #PBR
                    where prosCategory=7
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =39)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.7.1_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 121 и меньше или равно 180. Сумма по полю "Резерв ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=40)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)/*+isnull(reservPRC,0)+isnull(reservProchSumNU,0)*/) as money)
                    from #PBR
                    where prosCategory=7
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =40)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.7.2 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 121 и меньше или равно 180. Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=41)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(restOD,0)+*/isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=7
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =41)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.7.2_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 121 и меньше или равно 180. Сумма по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=42)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(reservOD,0)+*/isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=7
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =42)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.8 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 181 и меньше или равно 270. Сумма по полю "Задолженность ОД", по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=43)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=8
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =43)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.8_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 181 и меньше или равно 270. Сумма по полю "Резерв ОД", Сумма по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=44)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=8
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =44)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.8.1 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 181 и меньше или равно 270. Сумма по полю "Задолженность ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=45)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)/*+isnull(restPRC,0)+isnull(restPenia,0)*/) as money)
                    from #PBR
                    where prosCategory=8
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =45)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.8.1_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 181 и меньше или равно 270. Сумма по полю "Резерв ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=46)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)/*+isnull(reservPRC,0)+isnull(reservProchSumNU,0)*/) as money)
                    from #PBR
                    where prosCategory=8
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =46)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.8.2 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 181 и меньше или равно 270. Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=47)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(restOD,0)+*/isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=8
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =47)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.8.2_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 181 и меньше или равно 270. Сумма по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=48)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(reservOD,0)+*/isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=8
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =48)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.9 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 271 и меньше или равно 360. Сумма по полю "Задолженность ОД", по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=49)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=9
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =49)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.9_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 271 и меньше или равно 360. Сумма по полю "Резерв ОД", Сумма по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=50)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=9
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =50)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.9.1 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 271 и меньше или равно 360. Сумма по полю "Задолженность ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=51)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)/*+isnull(restPRC,0)+isnull(restPenia,0)*/) as money)
                    from #PBR
                    where prosCategory=9
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =51)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.9.1_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 271 и меньше или равно 360. Сумма по полю "Резерв ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=52)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)/*+isnull(reservPRC,0)+isnull(reservProchSumNU,0)*/) as money)
                    from #PBR
                    where prosCategory=9
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =52)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.9.2 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 271 и меньше или равно 360. Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=53)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(restOD,0)+*/isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=9
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =53)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.9.2_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 271 и меньше или равно 360. Сумма по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=54)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(reservOD,0)+*/isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=9
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =54)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.10 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 361. Сумма по полю "Задолженность ОД", по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=55)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=10
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =55)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.10_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 361. Сумма по полю "Резерв ОД", по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=56)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=10
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =56)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.10.1 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 361. Сумма по полю "Задолженность ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=57)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(restOD,0)/*+isnull(restPRC,0)+isnull(restPenia,0)*/) as money)
                    from #PBR
                    where prosCategory=10
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =57)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.10.1_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 361. Сумма по полю "Резерв ОД"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=58)
,[Данные УМФО] = (
                    select  
                    cast(SUM(isnull(reservOD,0)/*+isnull(reservPRC,0)+isnull(reservProchSumNU,0)*/) as money)
                    from #PBR
                    where prosCategory=10
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =58)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.10.2 с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 361. Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=59)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(restOD,0)+*/isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where prosCategory=10
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =59)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];

--Проверка 4.10.2_РВП с УМФО
merge into finAnalytics.rep840_4 t1
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
[Что проверяем] = 'Берем из отчета "ПБР" строки, где "Итого дней просрочки общая" больше или равно 361. Сумма по полю "Резерв проценты" и полю "Сумма резерв прочие НУ"'
,[Данные отчета] = (select sum(col3+col4+col5+col6+col7+col8+col9+col10+col11+col12+col13+col14+col15+col16+col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate and ROWNUM=60)
,[Данные УМФО] = (
                    select  
                    cast(SUM(/*isnull(reservOD,0)+*/isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where prosCategory=10
                )
) l1

) t2 on (t1.Repmonth=t2.repmonth and t1.repdate=t2.repdate and t1.rownum =60)
when matched then update
set t1.checkMethod2=t2.[Что проверяем],
    t1.chekResult2=t2.[Результат];



----Проверка по столбцам

Delete from finAnalytics.rep840_4_columnCheck
where REPMONTH=@repMonth and REPDATE=@repDate

---Строка 1
insert into finAnalytics.rep840_4_columnCheck

select
l1.repmonth
,l1.repdate
,l1.[Номер строки]
,l1.Показатель
,l1.[Алгоритм проверки колонка 3]
,[Результат проверки колонка 3] = case when cast(abs(l1.[Данные отчета колонка 3]-l1.[Данные УМФО колонка 3]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 3]-l1.[Данные УМФО колонка 3] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 4]
,[Результат проверки колонка 4] = case when cast(abs(l1.[Данные отчета колонка 4]-l1.[Данные УМФО колонка 4]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 4]-l1.[Данные УМФО колонка 4] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 6]
,[Результат проверки колонка 6] = case when cast(abs(l1.[Данные отчета колонка 6]-l1.[Данные УМФО колонка 6]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 6]-l1.[Данные УМФО колонка 6] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 8]
,[Результат проверки колонка 8] = case when cast(abs(l1.[Данные отчета колонка 8]-l1.[Данные УМФО колонка 8]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 8]-l1.[Данные УМФО колонка 8] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 10]
,[Результат проверки колонка 10] = case when cast(abs(l1.[Данные отчета колонка 10]-l1.[Данные УМФО колонка 10]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 10]-l1.[Данные УМФО колонка 10] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 11]
,[Результат проверки колонка 11] = case when cast(abs(l1.[Данные отчета колонка 11]-l1.[Данные УМФО колонка 11]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 11]-l1.[Данные УМФО колонка 11] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 13]
,[Результат проверки колонка 13] = case when cast(abs(l1.[Данные отчета колонка 13]-l1.[Данные УМФО колонка 13]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 13]-l1.[Данные УМФО колонка 13] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 14]
,[Результат проверки колонка 14] = case when cast(abs(l1.[Данные отчета колонка 14]-l1.[Данные УМФО колонка 14]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 14]-l1.[Данные УМФО колонка 14] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 15]
,[Результат проверки колонка 15] = case when cast(abs(l1.[Данные отчета колонка 15]-l1.[Данные УМФО колонка 15]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 15]-l1.[Данные УМФО колонка 15] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 17]
,[Результат проверки колонка 17] = case when cast(abs(l1.[Данные отчета колонка 17]-l1.[Данные УМФО колонка 17]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 17]-l1.[Данные УМФО колонка 17] as money) as varchar)) end 
from(

select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Номер строки] = 1
,[Показатель] = 'Задолженность ОД + Задолженность проценты + Сумма пени счета'
--3
,[Алгоритм проверки колонка 3] = 'Тип клиента=ФЛ,  Отнесение к МСП= пусто; ПСК больше или равно 250%; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 3] = (select sum(col3) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        or
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 3] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      --and (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and PSK_prc >= 250 --v2
                      and upper(isObespechZaym) = upper('Нет') --v2
                )
--4
,[Алгоритм проверки колонка 4] = 'Тип клиента=ФЛ, Обеспеченный займ = да;   Отнесение к МСП= нет; ПСК меньше 250%; Реструктуризирован = нет;'
,[Данные отчета колонка 4] = (select sum(col4) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        or
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 4] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      --and not (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and PSK_prc < 250 --v2
                      and upper(isObespechZaym) = upper('Да')
					  and upper(nomenkGroup) not like upper('%Самозанят%')
                )

--6
,[Алгоритм проверки колонка 6] = 'Тип клиента=ФЛ, Обеспеченный займ = нет; Отнесение к МСП= нет; ПСК меньше 250%; Реструктуризирован = нет;'
,[Данные отчета колонка 6] = (select sum(col6) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        or
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 6] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      -- and not (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and PSK_prc < 250 --v2
                      and upper(isObespechZaym) = upper('Нет')
					  and upper(nomenkGroup) not like upper('%Самозанят%')
                )

--8
,[Алгоритм проверки колонка 8] = 'Тип клиента=ЮЛ и ИП,   Отнесение к МСП=на дату отчета ЗАЕМЩИК входит в реестр;  Обеспеченный займ = да; Реструктуризирован = нет;'
,[Данные отчета колонка 8] = (select sum(col8) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        or
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 8] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where 
                          --isZaemshik!='ФЛ' --v1
							(	(upper(isZaemshik) in ('ЮЛ','ИП') and upper(isMSPbyRepDate) = upper('Да'))--v2
								or
								(upper(isZaemshik) in ('ФЛ') --v3
									and upper(nomenkGroup) like upper('%Самозанят%') --v3
								))
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Да')
                )

--10
,[Алгоритм проверки колонка 10] = 'Тип клиента=ЮЛ и ИП, Отнесение к МСП=на дату отчета ЗАЕМЩИК входит в реестр МСП; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 10] = (select sum(col10) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        or
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 10] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where 
							(	(upper(isZaemshik) in ('ЮЛ','ИП') and upper(isMSPbyRepDate) = upper('Да'))--v2
								or
								(upper(isZaemshik) in ('ФЛ') --v3
									and upper(nomenkGroup) like upper('%Самозанят%') --v3
								))
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                )

--11
,[Алгоритм проверки колонка 11] = 'Тип клиента=ЮЛ и ИП, Отнесение к МСП=на дату отчета ЗАЕМЩИК не входит в реестр МСП; Обеспеченный займ = да; Реструктуризирован = нет;'
,[Данные отчета колонка 11] = (select sum(col11) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        or
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 11] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where 1=1
                      --and isZaemshik !='ФЛ'  --v1
                      and isZaemshik in ('ЮЛ','ИП') --v2
                      and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Да')
                )

--13
,[Алгоритм проверки колонка 13] = 'Тип клиента=ИП и ЮЛ, Отнесение к МСП=на дату отчета ЗАЕМЩИК не входит в реестр МСП; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 13] = (select sum(col13) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        or
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 13] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where 1=1
                      --and isZaemshik !='ФЛ'  --v1
                      and isZaemshik in ('ЮЛ','ИП') --v2
                      and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                )

--14
,[Алгоритм проверки колонка 14] = 'Реструктуризирован = да; Отнесение к МСП=; ПСК больше или равно 250%; Обеспеченный займ = нет'
,[Данные отчета колонка 14] = (select sum(col14) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        or
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 14] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where 1=1
                      -- and isZaemshik='ФЛ' --v1
                      -- and  (dogSum<=30000 and dogPeriodDays <=30) --v1
                      --and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет') --v2
                      and PSK_prc >= 250 --v2
                )

--15
,[Алгоритм проверки колонка 15] = 'Реструктуризирован = да;   Обеспеченный займ = да;   Отнесение к МСП=; ПСК меньше 250%'
,[Данные отчета колонка 15] = (select sum(col15) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        or
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 15] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where 
                      /*
                      (
                      isZaemshik='ФЛ'
                      and not (dogSum<=30000 and dogPeriodDays <=30)
                      --and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Да')
                      )
                      or
                      (
                      isZaemshik != 'ФЛ'
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Да')
                      )*/ --v1
                      upper(isRestruk) = upper('Да') --v2
                      and upper(isObespechZaym) = upper('Да') --v2
                      --and PSK_prc < 250 --v2
                      and not (upper(isZaemshik) = 'ФЛ' and PSK_prc >= 250)    --v2
                      

                )

--17
,[Алгоритм проверки колонка 17] = 'Реструктуризирован = да;   Обеспеченный займ = нет;     Отнесение к МСП=; ПСК меньше 250%'
,[Данные отчета колонка 17] = (select sum(col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        or
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 17] = (
                    select  
                    cast(SUM(isnull(restOD,0)+isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where 
                    /*
                      (
                      isZaemshik='ФЛ'
                      and not (dogSum<=30000 and dogPeriodDays <=30)
                      --and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет')
                      )
                      or
                      (
                      isZaemshik != 'ФЛ'
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет')
                      )
                      */
                      upper(isRestruk) = upper('Да') --v2
                      and upper(isObespechZaym) = upper('Нет') --v2
                      --and PSK_prc < 250 --v2
                      and not (upper(isZaemshik) = 'ФЛ' and PSK_prc >= 250)    --v2
                )


) l1


---Строка 2
insert into finAnalytics.rep840_4_columnCheck

select
l1.repmonth
,l1.repdate
,l1.[Номер строки]
,l1.Показатель
,l1.[Алгоритм проверки колонка 3]
,[Результат проверки колонка 3] = case when cast(abs(l1.[Данные отчета колонка 3]-l1.[Данные УМФО колонка 3]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 3]-l1.[Данные УМФО колонка 3] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 4]
,[Результат проверки колонка 4] = case when cast(abs(l1.[Данные отчета колонка 4]-l1.[Данные УМФО колонка 4]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 4]-l1.[Данные УМФО колонка 4] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 6]
,[Результат проверки колонка 6] = case when cast(abs(l1.[Данные отчета колонка 6]-l1.[Данные УМФО колонка 6]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 6]-l1.[Данные УМФО колонка 6] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 8]
,[Результат проверки колонка 8] = case when cast(abs(l1.[Данные отчета колонка 8]-l1.[Данные УМФО колонка 8]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 8]-l1.[Данные УМФО колонка 8] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 10]
,[Результат проверки колонка 10] = case when cast(abs(l1.[Данные отчета колонка 10]-l1.[Данные УМФО колонка 10]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 10]-l1.[Данные УМФО колонка 10] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 11]
,[Результат проверки колонка 11] = case when cast(abs(l1.[Данные отчета колонка 11]-l1.[Данные УМФО колонка 11]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 11]-l1.[Данные УМФО колонка 11] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 13]
,[Результат проверки колонка 13] = case when cast(abs(l1.[Данные отчета колонка 13]-l1.[Данные УМФО колонка 13]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 13]-l1.[Данные УМФО колонка 13] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 14]
,[Результат проверки колонка 14] = case when cast(abs(l1.[Данные отчета колонка 14]-l1.[Данные УМФО колонка 14]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 14]-l1.[Данные УМФО колонка 14] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 15]
,[Результат проверки колонка 15] = case when cast(abs(l1.[Данные отчета колонка 15]-l1.[Данные УМФО колонка 15]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 15]-l1.[Данные УМФО колонка 15] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 17]
,[Результат проверки колонка 17] = case when cast(abs(l1.[Данные отчета колонка 17]-l1.[Данные УМФО колонка 17]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 17]-l1.[Данные УМФО колонка 17] as money) as varchar)) end 
from(

select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Номер строки] = 2
,[Показатель] = 'Резерв ОД + Резерв проценты + Сумма резерв прочие НУ'
--3
,[Алгоритм проверки колонка 3] = 'Тип клиента=ФЛ,  Отнесение к МСП= пусто; ПСК больше или равно 250%; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 3] = (select sum(col3) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        or
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 3] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      -- and (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and PSK_prc >= 250 --v2
                      and upper(isObespechZaym) = upper('Нет') --v2
                      
                )
--4
,[Алгоритм проверки колонка 4] = 'Тип клиента=ФЛ, Обеспеченный займ = да;   Отнесение к МСП= нет; ПСК меньше 250%; Реструктуризирован = нет;Номенклатурная группа" не равно "ПТС Займ для самозанятых"'
,[Данные отчета колонка 4] = (select sum(col4) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        or
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 4] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      -- and not (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and PSK_prc < 250 --v2
                      and upper(isObespechZaym) = upper('Да')
					  and upper([nomenkGroup]) not like upper('%Самозанят%') --v3
                )

--6
,[Алгоритм проверки колонка 6] = 'Тип клиента=ФЛ, Обеспеченный займ = нет; Отнесение к МСП= нет; ПСК меньше 250%; Реструктуризирован = нет;"Номенклатурная группа" не равно "ПТС Займ для самозанятых"'
,[Данные отчета колонка 6] = (select sum(col6) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        or
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 6] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      -- and not (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and PSK_prc < 250 --v2
                      and upper(isObespechZaym) = upper('Нет')
					  and upper([nomenkGroup]) not like upper('%Самозанят%') --v3
                )

--8
,[Алгоритм проверки колонка 8] = 'Тип клиента=ЮЛ и ИП,   Отнесение к МСП=на дату отчета ЗАЕМЩИК входит в реестр;  Обеспеченный займ = да; Реструктуризирован = нет;Признак заемщика" равно "ФЛ", "Номенклатурная группа" равно "ПТС Займ для самозанятых"'
,[Данные отчета колонка 8] = (select sum(col8) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        or
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 8] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where 
                        --isZaemshik!='ФЛ' --v1
							(	(upper(isZaemshik) in ('ЮЛ','ИП') and upper(isMSPbyRepDate) = upper('Да'))--v2
								or
								(upper(isZaemshik) in ('ФЛ') --v3
									and upper(nomenkGroup) like upper('%Самозанят%') --v3
								))
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Да')
                )

--10
,[Алгоритм проверки колонка 10] = 'Тип клиента=ЮЛ и ИП, Отнесение к МСП=на дату отчета ЗАЕМЩИК входит в реестр МСП; Обеспеченный займ = нет; Реструктуризирован = нет; Признак заемщика" равно "ФЛ", "Номенклатурная группа" равно "ПТС Займ для самозанятых"'
,[Данные отчета колонка 10] = (select sum(col10) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        or
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 10] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where --isZaemshik!='ФЛ' --v1
							(	(upper(isZaemshik) in ('ЮЛ','ИП') and upper(isMSPbyRepDate) = upper('Да'))--v2
								or
								(upper(isZaemshik) in ('ФЛ') --v3
									and upper(nomenkGroup) like upper('%Самозанят%') --v3
								))
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                )

--11
,[Алгоритм проверки колонка 11] = 'Тип клиента=ЮЛ и ИП, Отнесение к МСП=на дату отчета ЗАЕМЩИК не входит в реестр МСП; Обеспеченный займ = да; Реструктуризирован = нет;'
,[Данные отчета колонка 11] = (select sum(col11) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        or
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 11] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where --isZaemshik!='ФЛ' --v1
                        upper(isZaemshik) in ('ЮЛ','ИП') --v2
                      and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Да')
                )

--13
,[Алгоритм проверки колонка 13] = 'Тип клиента=ИП и ЮЛ, Отнесение к МСП=на дату отчета ЗАЕМЩИК не входит в реестр МСП; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 13] = (select sum(col13) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        or
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 13] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where --isZaemshik!='ФЛ' --v1
                        upper(isZaemshik) in ('ЮЛ','ИП') --v2
                      and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                )

--14
,[Алгоритм проверки колонка 14] = 'Реструктуризирован = да; Отнесение к МСП=; ПСК больше или равно 250%; Обеспеченный займ = нет'
,[Данные отчета колонка 14] = (select sum(col14) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                     and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        or
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 14] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where 1=1
                      --isZaemshik='ФЛ' --v1
                      -- and  (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isMSPbyRepDate) = upper('Нет') --v2
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет') --v2
                      and PSK_prc >= 250 --v2
                )

--15
,[Алгоритм проверки колонка 15] = 'Реструктуризирован = да;   Обеспеченный займ = да;   Отнесение к МСП=; ПСК меньше 250%'
,[Данные отчета колонка 15] = (select sum(col15) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        or
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 15] = (
                    select  
                    cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where 
                    /*
                      (
                      isZaemshik='ФЛ'
                      and not (dogSum<=30000 and dogPeriodDays <=30)
                      --and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Да')
                      )
                      or
                      (
                      isZaemshik != 'ФЛ'
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Да')
                      )
                      */
                      upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Да') --v2
                      --and PSK_prc < 250 --v2
                      and not (upper(isZaemshik) = 'ФЛ' and PSK_prc >= 250)    --v2
                )

--17
,[Алгоритм проверки колонка 17] = 'Реструктуризирован = да;   Обеспеченный займ = нет;     Отнесение к МСП=; ПСК меньше 250%'
,[Данные отчета колонка 17] = (select sum(col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        or
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 17] = (
                    select  
                     cast(SUM(isnull(reservOD,0)+isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where 
                    /*
                      (
                      isZaemshik='ФЛ'
                      and not (dogSum<=30000 and dogPeriodDays <=30)
                      --and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет')
                      )
                      or
                      (
                      isZaemshik != 'ФЛ'
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет')
                      )
                    */
                        upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет') --v2
                      --and PSK_prc < 250 --v2
                      and not (upper(isZaemshik) = 'ФЛ' and PSK_prc >= 250)    --v2
                )


) l1


---Строка 3
insert into finAnalytics.rep840_4_columnCheck

select
l1.repmonth
,l1.repdate
,l1.[Номер строки]
,l1.Показатель
,l1.[Алгоритм проверки колонка 3]
,[Результат проверки колонка 3] = case when cast(abs(l1.[Данные отчета колонка 3]-l1.[Данные УМФО колонка 3]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 3]-l1.[Данные УМФО колонка 3] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 4]
,[Результат проверки колонка 4] = case when cast(abs(l1.[Данные отчета колонка 4]-l1.[Данные УМФО колонка 4]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 4]-l1.[Данные УМФО колонка 4] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 6]
,[Результат проверки колонка 6] = case when cast(abs(l1.[Данные отчета колонка 6]-l1.[Данные УМФО колонка 6]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 6]-l1.[Данные УМФО колонка 6] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 8]
,[Результат проверки колонка 8] = case when cast(abs(l1.[Данные отчета колонка 8]-l1.[Данные УМФО колонка 8]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 8]-l1.[Данные УМФО колонка 8] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 10]
,[Результат проверки колонка 10] = case when cast(abs(l1.[Данные отчета колонка 10]-l1.[Данные УМФО колонка 10]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 10]-l1.[Данные УМФО колонка 10] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 11]
,[Результат проверки колонка 11] = case when cast(abs(l1.[Данные отчета колонка 11]-l1.[Данные УМФО колонка 11]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 11]-l1.[Данные УМФО колонка 11] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 13]
,[Результат проверки колонка 13] = case when cast(abs(l1.[Данные отчета колонка 13]-l1.[Данные УМФО колонка 13]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 13]-l1.[Данные УМФО колонка 13] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 14]
,[Результат проверки колонка 14] = case when cast(abs(l1.[Данные отчета колонка 14]-l1.[Данные УМФО колонка 14]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 14]-l1.[Данные УМФО колонка 14] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 15]
,[Результат проверки колонка 15] = case when cast(abs(l1.[Данные отчета колонка 15]-l1.[Данные УМФО колонка 15]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 15]-l1.[Данные УМФО колонка 15] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 17]
,[Результат проверки колонка 17] = case when cast(abs(l1.[Данные отчета колонка 17]-l1.[Данные УМФО колонка 17]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 17]-l1.[Данные УМФО колонка 17] as money) as varchar)) end 
from(

select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Номер строки] = 3
,[Показатель] = 'Задолженность ОД'
--3
,[Алгоритм проверки колонка 3] = 'Тип клиента=ФЛ,  Отнесение к МСП= пусто; ПСК больше или равно 250%; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 3] = (select sum(col3) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        ))
,[Данные УМФО колонка 3] = (
                    select  
                    cast(SUM(isnull(restOD,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      -- and (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and PSK_prc >= 250 --v2
                      and upper(isObespechZaym) = upper('Нет') --v2

                )
--4
,[Алгоритм проверки колонка 4] = 'Тип клиента=ФЛ, Обеспеченный займ = да;   Отнесение к МСП= нет; ПСК меньше 250%; Реструктуризирован = нет;'
,[Данные отчета колонка 4] = (select sum(col4) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        ))
,[Данные УМФО колонка 4] = (
                    select  
                    cast(SUM(isnull(restOD,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      -- and not (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Да')
                      and PSK_prc < 250 --v2
					  and upper([nomenkGroup]) not like upper('%Самозанят%') --v3
                )

--6
,[Алгоритм проверки колонка 6] = 'Тип клиента=ФЛ, Обеспеченный займ = нет; Отнесение к МСП= нет; ПСК меньше 250%; Реструктуризирован = нет;'
,[Данные отчета колонка 6] = (select sum(col6) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        ))
,[Данные УМФО колонка 6] = (
                    select  
                    cast(SUM(isnull(restOD,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      --and not (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                      and PSK_prc < 250 --v2
					  and upper([nomenkGroup]) not like upper('%Самозанят%') --v3
                )

--8
,[Алгоритм проверки колонка 8] = 'Тип клиента=ЮЛ и ИП,   Отнесение к МСП=на дату отчета ЗАЕМЩИК входит в реестр;  Обеспеченный займ = да; Реструктуризирован = нет;'
,[Данные отчета колонка 8] = (select sum(col8) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        ))
,[Данные УМФО колонка 8] = (
                    select  
                    cast(SUM(isnull(restOD,0)) as money)
                    from #PBR
                    where --isZaemshik!='ФЛ' --v1
							(	(upper(isZaemshik) in ('ЮЛ','ИП') and upper(isMSPbyRepDate) = upper('Да'))--v2
								or
								(upper(isZaemshik) in ('ФЛ') --v3
									and upper(nomenkGroup) like upper('%Самозанят%') --v3
								))
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Да')
                )

--10
,[Алгоритм проверки колонка 10] = 'Тип клиента=ЮЛ и ИП, Отнесение к МСП=на дату отчета ЗАЕМЩИК входит в реестр МСП; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 10] = (select sum(col10) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        ))
,[Данные УМФО колонка 10] = (
                    select  
                    cast(SUM(isnull(restOD,0)) as money)
                    from #PBR
                    where --isZaemshik!='ФЛ' --v1
							(	(upper(isZaemshik) in ('ЮЛ','ИП') and upper(isMSPbyRepDate) = upper('Да'))--v2
								or
								(upper(isZaemshik) in ('ФЛ') --v3
									and upper(nomenkGroup) like upper('%Самозанят%') --v3
								))
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                )

--11
,[Алгоритм проверки колонка 11] = 'Тип клиента=ЮЛ и ИП, Отнесение к МСП=на дату отчета ЗАЕМЩИК не входит в реестр МСП; Обеспеченный займ = да; Реструктуризирован = нет;'
,[Данные отчета колонка 11] = (select sum(col11) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        ))
,[Данные УМФО колонка 11] = (
                    select  
                    cast(SUM(isnull(restOD,0)) as money)
                    from #PBR
                    where --isZaemshik!='ФЛ' --v1
                      upper(isZaemshik) in ('ЮЛ','ИП') --v2
                      and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Да')
                )

--13
,[Алгоритм проверки колонка 13] = 'Тип клиента=ИП и ЮЛ, Отнесение к МСП=на дату отчета ЗАЕМЩИК не входит в реестр МСП; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 13] = (select sum(col13) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        ))
,[Данные УМФО колонка 13] = (
                    select  
                    cast(SUM(isnull(restOD,0)) as money)
                    from #PBR
                    where --isZaemshik!='ФЛ' --v1
                      upper(isZaemshik) in ('ЮЛ','ИП') --v2
                      and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                )

--14
,[Алгоритм проверки колонка 14] = 'Реструктуризирован = да; Отнесение к МСП=; ПСК больше или равно 250%; Обеспеченный займ = нет'
,[Данные отчета колонка 14] = (select sum(col14) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        ))
,[Данные УМФО колонка 14] = (
                    select  
                    cast(SUM(isnull(restOD,0)) as money)
                    from #PBR
                    where 1=1
                      --and isZaemshik='ФЛ' --v1
                      --and  (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isMSPbyRepDate) = upper('Нет') --v2
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет') --v2
                      and PSK_prc >= 250 --v2
                )

--15
,[Алгоритм проверки колонка 15] = 'Реструктуризирован = да;   Обеспеченный займ = да;   Отнесение к МСП=; ПСК меньше 250%'
,[Данные отчета колонка 15] = (select sum(col15) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        ))
,[Данные УМФО колонка 15] = (
                    select  
                    cast(SUM(isnull(restOD,0)) as money)
                    from #PBR
                    where 
                    /*
                      (
                      isZaemshik='ФЛ'
                      and not (dogSum<=30000 and dogPeriodDays <=30)
                      --and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Да')
                      )
                      or
                      (
                      isZaemshik != 'ФЛ'
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Да')
                      )
                      */ --v1
                      upper(isRestruk) = upper('Да') --v2
                      and upper(isObespechZaym) = upper('Да') --v2
                      --and PSK_prc < 250 --v2
                      and not (upper(isZaemshik) = 'ФЛ' and PSK_prc >= 250)    --v2

                )

--17
,[Алгоритм проверки колонка 17] = 'Реструктуризирован = да;   Обеспеченный займ = нет;     Отнесение к МСП=; ПСК меньше 250%'
,[Данные отчета колонка 17] = (select sum(col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (3,9,15,21,27,33,39,45,51,57)
                                        ))
,[Данные УМФО колонка 17] = (
                    select  
                    cast(SUM(isnull(restOD,0)) as money)
                    from #PBR
                    where 
                    /*
                      (
                      isZaemshik='ФЛ'
                      and not (dogSum<=30000 and dogPeriodDays <=30)
                      --and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет')
                      )
                      or
                      (
                      isZaemshik != 'ФЛ'
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет')
                      )
                    */ --v1
                      upper(isRestruk) = upper('Да') --v2
                      and upper(isObespechZaym) = upper('Нет') --v2
                      --and PSK_prc < 250 --v2
                      and not (upper(isZaemshik) = 'ФЛ' and PSK_prc >= 250)    --v2
                )


) l1


---Строка 4
insert into finAnalytics.rep840_4_columnCheck

select
l1.repmonth
,l1.repdate
,l1.[Номер строки]
,l1.Показатель
,l1.[Алгоритм проверки колонка 3]
,[Результат проверки колонка 3] = case when cast(abs(l1.[Данные отчета колонка 3]-l1.[Данные УМФО колонка 3]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 3]-l1.[Данные УМФО колонка 3] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 4]
,[Результат проверки колонка 4] = case when cast(abs(l1.[Данные отчета колонка 4]-l1.[Данные УМФО колонка 4]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 4]-l1.[Данные УМФО колонка 4] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 6]
,[Результат проверки колонка 6] = case when cast(abs(l1.[Данные отчета колонка 6]-l1.[Данные УМФО колонка 6]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 6]-l1.[Данные УМФО колонка 6] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 8]
,[Результат проверки колонка 8] = case when cast(abs(l1.[Данные отчета колонка 8]-l1.[Данные УМФО колонка 8]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 8]-l1.[Данные УМФО колонка 8] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 10]
,[Результат проверки колонка 10] = case when cast(abs(l1.[Данные отчета колонка 10]-l1.[Данные УМФО колонка 10]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 10]-l1.[Данные УМФО колонка 10] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 11]
,[Результат проверки колонка 11] = case when cast(abs(l1.[Данные отчета колонка 11]-l1.[Данные УМФО колонка 11]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 11]-l1.[Данные УМФО колонка 11] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 13]
,[Результат проверки колонка 13] = case when cast(abs(l1.[Данные отчета колонка 13]-l1.[Данные УМФО колонка 13]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 13]-l1.[Данные УМФО колонка 13] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 14]
,[Результат проверки колонка 14] = case when cast(abs(l1.[Данные отчета колонка 14]-l1.[Данные УМФО колонка 14]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 14]-l1.[Данные УМФО колонка 14] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 15]
,[Результат проверки колонка 15] = case when cast(abs(l1.[Данные отчета колонка 15]-l1.[Данные УМФО колонка 15]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 15]-l1.[Данные УМФО колонка 15] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 17]
,[Результат проверки колонка 17] = case when cast(abs(l1.[Данные отчета колонка 17]-l1.[Данные УМФО колонка 17]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 17]-l1.[Данные УМФО колонка 17] as money) as varchar)) end 
from(

select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Номер строки] = 4
,[Показатель] = 'Резерв ОД'
--3
,[Алгоритм проверки колонка 3] = 'Тип клиента=ФЛ,  Отнесение к МСП= пусто; ПСК больше или равно 250%; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 3] = (select sum(col3) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        ))
,[Данные УМФО колонка 3] = (
                    select  
                    cast(SUM(isnull(reservOD,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      -- and (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет') --v2
                      and PSK_prc >= 250 --v2
                )
--4
,[Алгоритм проверки колонка 4] = 'Тип клиента=ФЛ, Обеспеченный займ = да;   Отнесение к МСП= нет; ПСК меньше 250%; Реструктуризирован = нет;'
,[Данные отчета колонка 4] = (select sum(col4) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        ))
,[Данные УМФО колонка 4] = (
                    select  
                    cast(SUM(isnull(reservOD,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      -- and not (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Да')
                      and PSK_prc < 250 --v2
					  and upper([nomenkGroup]) not like upper('%Самозанят%') --v3
                )

--6
,[Алгоритм проверки колонка 6] = 'Тип клиента=ФЛ, Обеспеченный займ = нет; Отнесение к МСП= нет; ПСК меньше 250%; Реструктуризирован = нет;'
,[Данные отчета колонка 6] = (select sum(col6) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        ))
,[Данные УМФО колонка 6] = (
                    select  
                    cast(SUM(isnull(reservOD,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      -- and not (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                      and PSK_prc < 250 --v2
					  and upper([nomenkGroup]) not like upper('%Самозанят%') --v3
                )

--8
,[Алгоритм проверки колонка 8] = 'Тип клиента=ЮЛ и ИП,   Отнесение к МСП=на дату отчета ЗАЕМЩИК входит в реестр;  Обеспеченный займ = да; Реструктуризирован = нет;'
,[Данные отчета колонка 8] = (select sum(col8) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        ))
,[Данные УМФО колонка 8] = (
                    select  
                    cast(SUM(isnull(reservOD,0)) as money)
                    from #PBR
                    where --isZaemshik!='ФЛ' --v1
							(	(upper(isZaemshik) in ('ЮЛ','ИП') and upper(isMSPbyRepDate) = upper('Да'))--v2
								or
								(upper(isZaemshik) in ('ФЛ') --v3
									and upper(nomenkGroup) like upper('%Самозанят%') --v3
								))
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Да')
                )

--10
,[Алгоритм проверки колонка 10] = 'Тип клиента=ЮЛ и ИП, Отнесение к МСП=на дату отчета ЗАЕМЩИК входит в реестр МСП; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 10] = (select sum(col10) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        ))
,[Данные УМФО колонка 10] = (
                    select  
                    cast(SUM(isnull(reservOD,0)) as money)
                    from #PBR
                    where --isZaemshik!='ФЛ' --v1
							(	(upper(isZaemshik) in ('ЮЛ','ИП') and upper(isMSPbyRepDate) = upper('Да'))--v2
								or
								(upper(isZaemshik) in ('ФЛ') --v3
									and upper(nomenkGroup) like upper('%Самозанят%') --v3
								))
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                )

--11
,[Алгоритм проверки колонка 11] = 'Тип клиента=ЮЛ и ИП, Отнесение к МСП=на дату отчета ЗАЕМЩИК не входит в реестр МСП; Обеспеченный займ = да; Реструктуризирован = нет;'
,[Данные отчета колонка 11] = (select sum(col11) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        ))
,[Данные УМФО колонка 11] = (
                    select  
                    cast(SUM(isnull(reservOD,0)) as money)
                    from #PBR
                    where 1=1
                        --and isZaemshik!='ФЛ' --v1
                      and upper(isZaemshik) in ('ЮЛ','ИП') --v2
                      and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Да')
                )

--13
,[Алгоритм проверки колонка 13] = 'Тип клиента=ИП и ЮЛ, Отнесение к МСП=на дату отчета ЗАЕМЩИК не входит в реестр МСП; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 13] = (select sum(col13) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        ))
,[Данные УМФО колонка 13] = (
                    select  
                    cast(SUM(isnull(reservOD,0)) as money)
                    from #PBR
                    where 1=1
                        --and isZaemshik!='ФЛ' --v1
                      and upper(isZaemshik) in ('ЮЛ','ИП') --v2
                      and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                )

--14
,[Алгоритм проверки колонка 14] = 'Реструктуризирован = да; Отнесение к МСП=; ПСК больше или равно 250%; Обеспеченный займ = нет'
,[Данные отчета колонка 14] = (select sum(col14) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                     and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        ))
,[Данные УМФО колонка 14] = (
                    select  
                    cast(SUM(isnull(reservOD,0)) as money)
                    from #PBR
                    where 1=1
                    -- and isZaemshik='ФЛ' --v1
                      -- and  (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет') --v2
                      and PSK_prc >= 250 --v2
                )

--15
,[Алгоритм проверки колонка 15] = 'Реструктуризирован = да;   Обеспеченный займ = да;   Отнесение к МСП=; ПСК меньше 250%'
,[Данные отчета колонка 15] = (select sum(col15) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        ))
,[Данные УМФО колонка 15] = (
                    select  
                    cast(SUM(isnull(reservOD,0)) as money)
                    from #PBR
                    where 
                    /*
                      (
                      isZaemshik='ФЛ'
                      and not (dogSum<=30000 and dogPeriodDays <=30)
                      --and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Да')
                      )
                      or
                      (
                      isZaemshik != 'ФЛ'
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Да')
                      )
                    */ --v1
                      upper(isRestruk) = upper('Да') --v2
                      and upper(isObespechZaym) = upper('Да') --v2
                      --and PSK_prc < 250 --v2
                      and not (upper(isZaemshik) = 'ФЛ' and PSK_prc >= 250)    --v2
                )

--17
,[Алгоритм проверки колонка 17] = 'Реструктуризирован = да;   Обеспеченный займ = нет;     Отнесение к МСП=; ПСК меньше 250%'
,[Данные отчета колонка 17] = (select sum(col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (4,10,16,22,28,34,40,46,52,58)
                                        ))
,[Данные УМФО колонка 17] = (
                    select  
                     cast(SUM(isnull(reservOD,0)) as money)
                    from #PBR
                    where 
                    /*
                      (
                      isZaemshik='ФЛ'
                      and not (dogSum<=30000 and dogPeriodDays <=30)
                      --and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет')
                      )
                      or
                      (
                      isZaemshik != 'ФЛ'
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет')
                      )
                      */ -- v1
                      upper(isRestruk) = upper('Да') --v2
                      and upper(isObespechZaym) = upper('Нет') --v2
                      --and PSK_prc < 250 --v2
                      and not (upper(isZaemshik) = 'ФЛ' and PSK_prc >= 250)    --v2
                )


) l1



---Строка 5
insert into finAnalytics.rep840_4_columnCheck

select
l1.repmonth
,l1.repdate
,l1.[Номер строки]
,l1.Показатель
,l1.[Алгоритм проверки колонка 3]
,[Результат проверки колонка 3] = case when cast(abs(l1.[Данные отчета колонка 3]-l1.[Данные УМФО колонка 3]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 3]-l1.[Данные УМФО колонка 3] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 4]
,[Результат проверки колонка 4] = case when cast(abs(l1.[Данные отчета колонка 4]-l1.[Данные УМФО колонка 4]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 4]-l1.[Данные УМФО колонка 4] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 6]
,[Результат проверки колонка 6] = case when cast(abs(l1.[Данные отчета колонка 6]-l1.[Данные УМФО колонка 6]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 6]-l1.[Данные УМФО колонка 6] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 8]
,[Результат проверки колонка 8] = case when cast(abs(l1.[Данные отчета колонка 8]-l1.[Данные УМФО колонка 8]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 8]-l1.[Данные УМФО колонка 8] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 10]
,[Результат проверки колонка 10] = case when cast(abs(l1.[Данные отчета колонка 10]-l1.[Данные УМФО колонка 10]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 10]-l1.[Данные УМФО колонка 10] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 11]
,[Результат проверки колонка 11] = case when cast(abs(l1.[Данные отчета колонка 11]-l1.[Данные УМФО колонка 11]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 11]-l1.[Данные УМФО колонка 11] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 13]
,[Результат проверки колонка 13] = case when cast(abs(l1.[Данные отчета колонка 13]-l1.[Данные УМФО колонка 13]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 13]-l1.[Данные УМФО колонка 13] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 14]
,[Результат проверки колонка 14] = case when cast(abs(l1.[Данные отчета колонка 14]-l1.[Данные УМФО колонка 14]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 14]-l1.[Данные УМФО колонка 14] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 15]
,[Результат проверки колонка 15] = case when cast(abs(l1.[Данные отчета колонка 15]-l1.[Данные УМФО колонка 15]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 15]-l1.[Данные УМФО колонка 15] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 17]
,[Результат проверки колонка 17] = case when cast(abs(l1.[Данные отчета колонка 17]-l1.[Данные УМФО колонка 17]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 17]-l1.[Данные УМФО колонка 17] as money) as varchar)) end 
from(

select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Номер строки] = 5
,[Показатель] = 'Задолженность проценты + Сумма пени счета'
--3
,[Алгоритм проверки колонка 3] = 'Тип клиента=ФЛ,  Отнесение к МСП= пусто; ПСК больше или равно 250%; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 3] = (select sum(col3) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 3] = (
                    select  
                    cast(SUM(isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      -- and (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and PSK_prc >= 250 --v2
                      and upper(isObespechZaym) = upper('Нет') --v2

                )
--4
,[Алгоритм проверки колонка 4] = 'Тип клиента=ФЛ, Обеспеченный займ = да;   Отнесение к МСП= нет; ПСК меньше 250%; Реструктуризирован = нет;'
,[Данные отчета колонка 4] = (select sum(col4) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 4] = (
                    select  
                    cast(SUM(isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      -- and not (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Да')
                      and PSK_prc < 250 --v2
					  and upper([nomenkGroup]) not like upper('%Самозанят%') --v3
                )

--6
,[Алгоритм проверки колонка 6] = 'Тип клиента=ФЛ, Обеспеченный займ = нет; Отнесение к МСП= нет; ПСК меньше 250%; Реструктуризирован = нет;'
,[Данные отчета колонка 6] = (select sum(col6) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 6] = (
                    select  
                    cast(SUM(isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      -- and not (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                      and PSK_prc < 250 --v2
					  and upper([nomenkGroup]) not like upper('%Самозанят%') --v3
                )

--8
,[Алгоритм проверки колонка 8] = 'Тип клиента=ЮЛ и ИП,   Отнесение к МСП=на дату отчета ЗАЕМЩИК входит в реестр;  Обеспеченный займ = да; Реструктуризирован = нет;'
,[Данные отчета колонка 8] = (select sum(col8) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 8] = (
                    select  
                    cast(SUM(isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where --isZaemshik!='ФЛ' --v1
							(	(upper(isZaemshik) in ('ЮЛ','ИП') and upper(isMSPbyRepDate) = upper('Да'))--v2
								or
								(upper(isZaemshik) in ('ФЛ') --v3
									and upper(nomenkGroup) like upper('%Самозанят%') --v3
								))
                      and upper(isRestruk) = upper('Нет') -- v2
                      and upper(isObespechZaym) = upper('Да')
                )

--10
,[Алгоритм проверки колонка 10] = 'Тип клиента=ЮЛ и ИП, Отнесение к МСП=на дату отчета ЗАЕМЩИК входит в реестр МСП; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 10] = (select sum(col10) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 10] = (
                    select  
                    cast(SUM(isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where --isZaemshik!='ФЛ' --v1
							(	(upper(isZaemshik) in ('ЮЛ','ИП') and upper(isMSPbyRepDate) = upper('Да'))--v2
								or
								(upper(isZaemshik) in ('ФЛ') --v3
									and upper(nomenkGroup) like upper('%Самозанят%') --v3
								))
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                )

--11
,[Алгоритм проверки колонка 11] = 'Тип клиента=ЮЛ и ИП, Отнесение к МСП=на дату отчета ЗАЕМЩИК не входит в реестр МСП; Обеспеченный займ = да; Реструктуризирован = нет;'
,[Данные отчета колонка 11] = (select sum(col11) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 11] = (
                    select  
                    cast(SUM(isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where 1=1
                      --and isZaemshik!='ФЛ' --v1
                      and upper(isZaemshik) in ('ЮЛ','ИП') --v2
                      and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Да')
                )

--13
,[Алгоритм проверки колонка 13] = 'Тип клиента=ИП и ЮЛ, Отнесение к МСП=на дату отчета ЗАЕМЩИК не входит в реестр МСП; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 13] = (select sum(col13) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 13] = (
                    select  
                    cast(SUM(isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where 1=1
                      --and isZaemshik!='ФЛ' --v1
                      and upper(isZaemshik) in ('ЮЛ','ИП') --v2
                      and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                )

--14
,[Алгоритм проверки колонка 14] = 'Реструктуризирован = да; Отнесение к МСП=; ПСК больше или равно 250%; Обеспеченный займ = нет'
,[Данные отчета колонка 14] = (select sum(col14) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 14] = (
                    select  
                    cast(SUM(isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where  1=1
                      -- isZaemshik='ФЛ' --v1
                      -- and  (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isMSPbyRepDate) = upper('Нет') --v2
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет') --v2
                      and PSK_prc >= 250 --v2
                )

--15
,[Алгоритм проверки колонка 15] = 'Реструктуризирован = да;   Обеспеченный займ = да;   Отнесение к МСП=; ПСК меньше 250%'
,[Данные отчета колонка 15] = (select sum(col15) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 15] = (
                    select  
                    cast(SUM(isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where 
                    /*
                      (
                      isZaemshik='ФЛ'
                      and not (dogSum<=30000 and dogPeriodDays <=30)
                      --and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Да')
                      )
                      or
                      (
                      isZaemshik != 'ФЛ'
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Да')
                      )
                      */ --v1
                      upper(isRestruk) = upper('Да') --v2
                      and upper(isObespechZaym) = upper('Да') --v2
                      --and PSK_prc < 250 --v2
                      and not (upper(isZaemshik) = 'ФЛ' and PSK_prc >= 250)    --v2
                )

--17
,[Алгоритм проверки колонка 17] = 'Реструктуризирован = да;   Обеспеченный займ = нет;     Отнесение к МСП=; ПСК меньше 250%'
,[Данные отчета колонка 17] = (select sum(col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (5,11,17,23,29,35,41,47,53,59)
                                        ))
,[Данные УМФО колонка 17] = (
                    select  
                    cast(SUM(isnull(restPRC,0)+isnull(restPenia,0)) as money)
                    from #PBR
                    where 
                    /*
                      (
                      isZaemshik='ФЛ'
                      and not (dogSum<=30000 and dogPeriodDays <=30)
                      --and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет')
                      )
                      or
                      (
                      isZaemshik != 'ФЛ'
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет')
                      )
                      */ -- v1
                      upper(isRestruk) = upper('Да') --v2
                      and upper(isObespechZaym) = upper('Нет') --v2
                      --and PSK_prc < 250 --v2
                      and not (upper(isZaemshik) = 'ФЛ' and PSK_prc >= 250)    --v2
                )


) l1


---Строка 6
insert into finAnalytics.rep840_4_columnCheck

select
l1.repmonth
,l1.repdate
,l1.[Номер строки]
,l1.Показатель
,l1.[Алгоритм проверки колонка 3]
,[Результат проверки колонка 3] = case when cast(abs(l1.[Данные отчета колонка 3]-l1.[Данные УМФО колонка 3]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 3]-l1.[Данные УМФО колонка 3] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 4]
,[Результат проверки колонка 4] = case when cast(abs(l1.[Данные отчета колонка 4]-l1.[Данные УМФО колонка 4]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 4]-l1.[Данные УМФО колонка 4] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 6]
,[Результат проверки колонка 6] = case when cast(abs(l1.[Данные отчета колонка 6]-l1.[Данные УМФО колонка 6]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 6]-l1.[Данные УМФО колонка 6] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 8]
,[Результат проверки колонка 8] = case when cast(abs(l1.[Данные отчета колонка 8]-l1.[Данные УМФО колонка 8]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 8]-l1.[Данные УМФО колонка 8] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 10]
,[Результат проверки колонка 10] = case when cast(abs(l1.[Данные отчета колонка 10]-l1.[Данные УМФО колонка 10]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 10]-l1.[Данные УМФО колонка 10] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 11]
,[Результат проверки колонка 11] = case when cast(abs(l1.[Данные отчета колонка 11]-l1.[Данные УМФО колонка 11]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 11]-l1.[Данные УМФО колонка 11] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 13]
,[Результат проверки колонка 13] = case when cast(abs(l1.[Данные отчета колонка 13]-l1.[Данные УМФО колонка 13]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 13]-l1.[Данные УМФО колонка 13] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 14]
,[Результат проверки колонка 14] = case when cast(abs(l1.[Данные отчета колонка 14]-l1.[Данные УМФО колонка 14]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 14]-l1.[Данные УМФО колонка 14] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 15]
,[Результат проверки колонка 15] = case when cast(abs(l1.[Данные отчета колонка 15]-l1.[Данные УМФО колонка 15]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 15]-l1.[Данные УМФО колонка 15] as money) as varchar)) end 
,l1.[Алгоритм проверки колонка 17]
,[Результат проверки колонка 17] = case when cast(abs(l1.[Данные отчета колонка 17]-l1.[Данные УМФО колонка 17]) as money) <= 0.99/*<= 0.01*/ then 'OK' else concat('Ошибка: остатки не совпадают ',cast(cast(l1.[Данные отчета колонка 17]-l1.[Данные УМФО колонка 17] as money) as varchar)) end 
from(

select
[repmonth] = @repmonth
,[repdate] = @repdate
,[Номер строки] = 6
,[Показатель] = 'Резерв проценты + Сумма резерв прочие НУ'
--3
,[Алгоритм проверки колонка 3] = 'Тип клиента=ФЛ,  Отнесение к МСП= пусто; ПСК больше или равно 250%; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 3] = (select sum(col3) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 3] = (
                    select  
                    cast(SUM(isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      -- and (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет') --v2
                      and PSK_prc >= 250 --v2
                )
--4
,[Алгоритм проверки колонка 4] = 'Тип клиента=ФЛ, Обеспеченный займ = да;   Отнесение к МСП= нет; ПСК меньше 250%; Реструктуризирован = нет;'
,[Данные отчета колонка 4] = (select sum(col4) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 4] = (
                    select  
                    cast(SUM(isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      -- and not (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Да')
                      and PSK_prc < 250 -- v2
					  and upper([nomenkGroup]) not like upper('%Самозанят%') --v3
                )

--6
,[Алгоритм проверки колонка 6] = 'Тип клиента=ФЛ, Обеспеченный займ = нет; Отнесение к МСП= нет; ПСК меньше 250%; Реструктуризирован = нет;'
,[Данные отчета колонка 6] = (select sum(col6) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 6] = (
                    select  
                    cast(SUM(isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where isZaemshik='ФЛ'
                      -- and not (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                      and PSK_prc < 250 --v2
					  and upper([nomenkGroup]) not like upper('%Самозанят%') --v3
                )

--8
,[Алгоритм проверки колонка 8] = 'Тип клиента=ЮЛ и ИП,   Отнесение к МСП=на дату отчета ЗАЕМЩИК входит в реестр;  Обеспеченный займ = да; Реструктуризирован = нет;'
,[Данные отчета колонка 8] = (select sum(col8) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 8] = (
                    select  
                    cast(SUM(isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where --isZaemshik!='ФЛ' --v1
							(	(upper(isZaemshik) in ('ЮЛ','ИП') and upper(isMSPbyRepDate) = upper('Да'))--v2
								or
								(upper(isZaemshik) in ('ФЛ') --v3
									and upper(nomenkGroup) like upper('%Самозанят%') --v3
								))
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Да')
                )

--10
,[Алгоритм проверки колонка 10] = 'Тип клиента=ЮЛ и ИП, Отнесение к МСП=на дату отчета ЗАЕМЩИК входит в реестр МСП; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 10] = (select sum(col10) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 10] = (
                    select  
                    cast(SUM(isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where --isZaemshik!='ФЛ' --v1
							(	(upper(isZaemshik) in ('ЮЛ','ИП') and upper(isMSPbyRepDate) = upper('Да'))--v2
								or
								(upper(isZaemshik) in ('ФЛ') --v3
									and upper(nomenkGroup) like upper('%Самозанят%') --v3
								))
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                )

--11
,[Алгоритм проверки колонка 11] = 'Тип клиента=ЮЛ и ИП, Отнесение к МСП=на дату отчета ЗАЕМЩИК не входит в реестр МСП; Обеспеченный займ = да; Реструктуризирован = нет;'
,[Данные отчета колонка 11] = (select sum(col11) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 11] = (
                    select  
                    cast(SUM(isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where 1=1
                      --and isZaemshik!='ФЛ' --v1
                      and upper(isZaemshik) in ('ЮЛ','ИП') --v2
                      and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Да')
                )

--13
,[Алгоритм проверки колонка 13] = 'Тип клиента=ИП и ЮЛ, Отнесение к МСП=на дату отчета ЗАЕМЩИК не входит в реестр МСП; Обеспеченный займ = нет; Реструктуризирован = нет;'
,[Данные отчета колонка 13] = (select sum(col13) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 13] = (
                    select  
                    cast(SUM(isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where 1=1
                      --and isZaemshik!='ФЛ' --v1
                      and upper(isZaemshik) in ('ЮЛ','ИП') --v2
                      and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Нет') --v2
                      and upper(isObespechZaym) = upper('Нет')
                )

--14
,[Алгоритм проверки колонка 14] = 'Реструктуризирован = да; Отнесение к МСП=; ПСК больше или равно 250%; Обеспеченный займ = нет'
,[Данные отчета колонка 14] = (select sum(col14) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                     and (
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 14] = (
                    select  
                    cast(SUM(isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where 1=1
                      -- and isZaemshik='ФЛ' --v1
                      -- and  (dogSum<=30000 and dogPeriodDays <=30) --v1
                      and upper(isMSPbyRepDate) = upper('Нет') --v2
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет') -- v2
                      and PSK_prc >= 250 --v2
                )

--15
,[Алгоритм проверки колонка 15] = 'Реструктуризирован = да;   Обеспеченный займ = да;   Отнесение к МСП=; ПСК меньше 250%'
,[Данные отчета колонка 15] = (select sum(col15) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 15] = (
                    select  
                    cast(SUM(isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where 
                    /*
                      (
                      isZaemshik='ФЛ'
                      and not (dogSum<=30000 and dogPeriodDays <=30)
                      --and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Да')
                      )
                      or
                      (
                      isZaemshik != 'ФЛ'
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Да')
                      )
                      */ --v1
                      upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Да') -- v2
                      --and PSK_prc < 250 --v2
                      and not (upper(isZaemshik) = 'ФЛ' and PSK_prc >= 250)    --v2

                )

--17
,[Алгоритм проверки колонка 17] = 'Реструктуризирован = да;   Обеспеченный займ = нет;     Отнесение к МСП=; ПСК меньше 250%'
,[Данные отчета колонка 17] = (select sum(col17) 
                    from finAnalytics.rep840_4 where REPMONTH=@repMonth and REPDATE=@repDate 
                                    and (
                                        ROWNUM in (6,12,18,24,30,36,42,48,54,60)
                                        ))
,[Данные УМФО колонка 17] = (
                    select  
                     cast(SUM(isnull(reservPRC,0)+isnull(reservProchSumNU,0)) as money)
                    from #PBR
                    where
                    /*
                      (
                      isZaemshik='ФЛ'
                      and not (dogSum<=30000 and dogPeriodDays <=30)
                      --and upper(isMSPbyRepDate) = upper('Нет')
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет')
                      )
                      or
                      (
                      isZaemshik != 'ФЛ'
                      and upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет')
                      )
                      */ --v1
                      upper(isRestruk) = upper('Да')
                      and upper(isObespechZaym) = upper('Нет') -- v2
                      --and PSK_prc < 250 --v2
                      and not (upper(isZaemshik) = 'ФЛ' and PSK_prc >= 250)    --v2

                )


) l1
end try

BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
       ,ERROR_MESSAGE() AS ErrorMessage;  
END CATCH



end
