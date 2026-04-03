
CREATE procedure [finAnalytics].[calcRep840FirstLevel_4Detail]
    @repmonth date,
    @repdate date
AS
BEGIN

DROP TABLE IF  EXISTS[finAnalytics].#ID_LIST
Create table [finAnalytics].#ID_LIST(
    [ID] bigint NOT NULL
    )

insert into #ID_LIST
select
a.ID
from finAnalytics.PBR_MONTHLY a
where a.REPMONTH=@REPMONTH --and a.REPDATE=@REPDATE

DROP TABLE IF  EXISTS[finAnalytics].#PBR
Create table [finAnalytics].#PBR(
   [dogNum] nvarchar(50) not null,
   [restOD] float not null,
   [restPrc] float not null,
   [restPenia] float not null,
   [reservOD] float not null,
   [reservPRC] float not null,
   [reservPenia] float not null,
   [prosDaysTotal] int not null,
   [nomenkGroup] nvarchar(300) null
   )

insert into #PBR
select
a.[dogNum]
,a.[zadolgOD]
,a.[zadolgPrc]
,a.[penyaSum]
,a.[reservOD]
,a.[reservPRC]
,a.[reservProchSumNU]
,a.[prosDaysTotal]
,a.[nomenkGroup]

from finAnalytics.PBR_MONTHLY a
inner join #id_list b on a.id=b.id

DROP TABLE IF  EXISTS[finAnalytics].#ID_LIST

--select * from #PBR

DROP TABLE IF  EXISTS[finAnalytics].#RESERV
Create table [finAnalytics].#RESERV(
   [dogNum] nvarchar(50) not null,
   [restOD] float not null,
   [restPrc] float not null,
   [restPenia] float not null,
   [reservOD] float not null,
   [reservPRC] float not null,
   [reservPenia] float not null,
   [prosDaysTotal] int not null
   )

insert into #RESERV
select
a.[dogNum]
,a.[restOD]
,a.[restPRC]
,a.[restPenia]
,a.[sumOD]
,a.[sumPRC]
,a.[sumPenia]
,a.[allPros]

from finAnalytics.Reserv_NU a
where a.repmonth=@repmonth

delete from finAnalytics.rep840_4_errorDetail
where repmonth=@repmonth and repdate=@repdate

--select * from #RESERV
declare @calcData int
declare @prosDaysFrom int
declare @prosDaysTo int

--Строка 3
set @calcData = 1
set @prosDaysFrom  = 0
set @prosDaysTo = 0

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 3
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 4
set @calcData = 2
set @prosDaysFrom  = 0
set @prosDaysTo = 0

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 4
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 5
set @calcData = 3
set @prosDaysFrom  = 0
set @prosDaysTo = 0

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 5
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 6
set @calcData = 4
set @prosDaysFrom  = 0
set @prosDaysTo = 0

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 6
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 9
set @calcData = 1
set @prosDaysFrom  = 1
set @prosDaysTo = 7

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 9
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 10
set @calcData = 2
set @prosDaysFrom  = 1
set @prosDaysTo = 7

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 10
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 11
set @calcData = 3
set @prosDaysFrom  = 1
set @prosDaysTo = 7

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 11
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 12
set @calcData = 4
set @prosDaysFrom  = 1
set @prosDaysTo = 7

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 12
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 15
set @calcData = 1
set @prosDaysFrom  = 8
set @prosDaysTo = 30

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 15
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 16
set @calcData = 2
set @prosDaysFrom  = 8
set @prosDaysTo = 30

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 16
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 17
set @calcData = 3
set @prosDaysFrom  = 8
set @prosDaysTo = 30

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 17
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 18
set @calcData = 4
set @prosDaysFrom  = 8
set @prosDaysTo = 30

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 18
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 21
set @calcData = 1
set @prosDaysFrom  = 31
set @prosDaysTo = 60

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 21
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 22
set @calcData = 2
set @prosDaysFrom  = 31
set @prosDaysTo = 60

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 22
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 23
set @calcData = 3
set @prosDaysFrom  = 31
set @prosDaysTo = 60

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 23
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 24
set @calcData = 4
set @prosDaysFrom  = 31
set @prosDaysTo = 60

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 24
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 27
set @calcData = 1
set @prosDaysFrom  = 61
set @prosDaysTo = 90

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 27
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 28
set @calcData = 2
set @prosDaysFrom  = 61
set @prosDaysTo = 90

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 28
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 29
set @calcData = 3
set @prosDaysFrom  = 61
set @prosDaysTo = 90

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 29
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 30
set @calcData = 4
set @prosDaysFrom  = 61
set @prosDaysTo = 90

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 30
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 33
set @calcData = 1
set @prosDaysFrom  = 91
set @prosDaysTo = 120

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 33
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 34
set @calcData = 2
set @prosDaysFrom  = 91
set @prosDaysTo = 120

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 34
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 35
set @calcData = 3
set @prosDaysFrom  = 91
set @prosDaysTo = 120

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 35
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 36
set @calcData = 4
set @prosDaysFrom  = 91
set @prosDaysTo = 120

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 36
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 39
set @calcData = 1
set @prosDaysFrom  = 121
set @prosDaysTo = 180

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 39
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 40
set @calcData = 2
set @prosDaysFrom  = 121
set @prosDaysTo = 180

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 40
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 41
set @calcData = 3
set @prosDaysFrom  = 121
set @prosDaysTo = 180

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 41
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 42
set @calcData = 4
set @prosDaysFrom  = 121
set @prosDaysTo = 180

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 42
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 45
set @calcData = 1
set @prosDaysFrom  = 181
set @prosDaysTo = 270

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 45
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 46
set @calcData = 2
set @prosDaysFrom  = 181
set @prosDaysTo = 270

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 46
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 47
set @calcData = 3
set @prosDaysFrom  = 181
set @prosDaysTo = 270

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 47
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 48
set @calcData = 4
set @prosDaysFrom  = 181
set @prosDaysTo = 270

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 48
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 51
set @calcData = 1
set @prosDaysFrom  = 271
set @prosDaysTo = 360

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 51
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 52
set @calcData = 2
set @prosDaysFrom  = 271
set @prosDaysTo = 360

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 52
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 53
set @calcData = 3
set @prosDaysFrom  = 271
set @prosDaysTo = 360

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 53
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 54
set @calcData = 4
set @prosDaysFrom  = 271
set @prosDaysTo = 360

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 54
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 57
set @calcData = 1
set @prosDaysFrom  = 361
set @prosDaysTo = 999999

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 57
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 58
set @calcData = 2
set @prosDaysFrom  = 361
set @prosDaysTo = 999999

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 58
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 59
set @calcData = 3
set @prosDaysFrom  = 361
set @prosDaysTo = 999999

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 59
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01

--Строка 60
set @calcData = 4
set @prosDaysFrom  = 361
set @prosDaysTo = 999999

INSERT INTO finAnalytics.rep840_4_errorDetail
(REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta)
select
@REPMONTH
,@REPDATE
,[Строка отчета] = 60
,[Показатель проверки] = case when @calcData = 1 then 'Остаток ОД'
                              when @calcData = 2 then 'Резерв ОД'
                              when @calcData = 3 then 'Остаток Проценты+Пеня'
                              when @calcData = 4 then 'Резерв Проценты+Пеня'
                         end
,[Период просрочки] = concat('Дней просрочки от ',@prosDaysFrom,' до ',@prosDaysTo)
,l1.[Номер договора]
,l1.[Сумма отстатков по резервам НУ]
,l1.[Сумма отстатков по ПБР]
,[Разница] = l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]
from(
select
[Номер договора] = a.dogNum
,[Сумма отстатков по резервам НУ] = case when @calcData = 1 then a.restOD
      when @calcData = 3 then a.restPRC+a.restPenia
      when @calcData = 2 then a.reservOD
      when @calcData = 4 then a.reservPRC+a.reservPenia
      end
,[Сумма отстатков по ПБР] = case when @calcData = 1 then b.restOD
      when @calcData = 3 then b.restPrc+b.restPenia
      when @calcData = 2 then b.[reservOD]
      when @calcData = 4 then b.[reservPRC]+b.reservPenia
      end

from #RESERV a
left join #PBR b on a.dogNum=b.dogNum

where 1=1
and a.prosDaysTotal between @prosDaysFrom and @prosDaysTo
) l1

where abs(l1.[Сумма отстатков по резервам НУ]-l1.[Сумма отстатков по ПБР]) >=0.01


END
