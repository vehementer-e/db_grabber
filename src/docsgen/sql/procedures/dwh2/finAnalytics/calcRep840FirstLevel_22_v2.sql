



CREATE PROCEDURE [finAnalytics].[calcRep840FirstLevel_22_v2]
	@repmonth date,
    @repdate date
    --,    @sumRang int
AS
BEGIN

Create table #ID_LIST2(
[ID] [int] NOT NULL)

INSERT INTO #ID_LIST2
select id
from finAnalytics.PBR_MONTHLY a
where a.REPMONTH=@repmonth
--and a.REPDATE=@repdate

BEGIN TRY

delete from finAnalytics.rep840_firstLevel
where REPMONTH=@repmonth and REPDATE=@repdate and razdel='2.2'

insert into finAnalytics.rep840_firstLevel
(REPMONTH, REPDATE, razdel, punkt, pokazatel, value, comment, rownum)
---Заполняем нижний уровень

--2.11.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.11.1'
,[Показатель] = '    индивидуальным предпринимателям, в том числе:'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0)  as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ИП; "Состояние"= действует; "Способ выдачи займа"=Онлайн; Счета учета = 494; Сумма по полю "Задолженность ОД"'
,2
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '494'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.11.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.11.1.1'
,[Показатель] = '        являющимся субъектами малого и среднего предпринимательства'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0)  as money),3)
,[Примечание] = 'к 2.11.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,3
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '494'  --v2
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.11.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.11.2'
,[Показатель] = '    юридическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0)  as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; "Состояние"= действует; "Способ выдачи займа"= Онлайн;Счет учета = 487. Сумма по полю "Задолженность ОД"'
,4
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '487'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.11.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.11.2.1'
,[Показатель] = '        являющимся субъектами малого и среднего предпринимательства'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0)  as money),3)
,[Примечание] = 'к 2.11.2 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,5
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '487'  --v2
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.11.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.11.3'
,[Показатель] = '    физическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0)  as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"= Онлайн; Счет учета = 488 Сумма по полю "Задолженность ОД"'
,6
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '488'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.11.3.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.11.3.1'
,[Показатель] = '        по микрозаймам, отвечающим требованиям статьи 6 Федерального закона от 21 декабря 2013 года № 353-ФЗ «О потребительском кредите (займе)»'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,7

union all

--2.11.3.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.11.3.2'
,[Показатель] = '        в сумме не более 30 тысяч рублей на срок не более 30 дней'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0)  as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"= Онлайн; Счет учета = 488; Займ выдан на сумму меньше или равен 30 т.р. и меньше или равен 30 дней; Сумма по полю "Задолженность ОД"'
,8
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '488'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.11.3.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.11.3.3'
,[Показатель] = '        по POS-микрозаймам'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,9

union all

--2.11.3.4
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.11.3.4'
,[Показатель] = '        физическим лицам, применяющим специальный налоговый режим «Налог на профессиональный доход» и не являющимся индивидуальными предпринимателями, в том числе:'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,10

union all

--2.12.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.12.1'
,[Показатель] = '    индивидуальным предпринимателям, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(zadolgPrc),0)  as money),3)
              +
              ROUND(cast(isnull(sum(penyaSum),0)  as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ИП; "Состояние"= действует; "Способ выдачи займа"=Онлайн; Счет учета = 494; Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,12
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '494'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.12.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.12.1.1'
,[Показатель] = '        являющимся субъектами малого и среднего предпринимательства'
,[Значение] = ROUND(cast(isnull(sum(zadolgPrc),0)  as money),3)
              +
              ROUND(cast(isnull(sum(penyaSum),0)  as money),3)
,[Примечание] = 'к 2.12.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,13
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '494'  --v2
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.12.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.12.2'
,[Показатель] = '    юридическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(zadolgPrc),0)  as money),3)
              +
              ROUND(cast(isnull(sum(penyaSum),0)  as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; "Состояние"= действует; "Способ выдачи займа"=Онлайн; Счет учета = 487; Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,14
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '487'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.12.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.12.2.1'
,[Показатель] = '        являющимся субъектами малого и среднего предпринимательства'
,[Значение] = ROUND(cast(isnull(sum(zadolgPrc),0)  as money),3)
              +
              ROUND(cast(isnull(sum(penyaSum),0)  as money),3)
,[Примечание] = 'к 2.12.2 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,15
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '487'  --v2
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.12.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.12.3'
,[Показатель] = '    физическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(zadolgPrc),0)  as money),3)
              +
              ROUND(cast(isnull(sum(penyaSum),0)  as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"=Онлайн; Счет учета = 488; Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,16
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '488'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.12.3.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.12.3.1'
,[Показатель] = '        по микрозаймам, отвечающим требованиям статьи 6 Федерального закона от 21 декабря 2013 года № 353-ФЗ «О потребительском кредите (займе)»'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,17

union all

--2.12.3.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.12.3.2'
,[Показатель] = '        в сумме не более 30 тысяч рублей на срок не более 30 дней'
,[Значение] = ROUND(cast(isnull(sum(zadolgPrc),0)  as money),3)
              +
              ROUND(cast(isnull(sum(penyaSum),0)  as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"=Онлайн; Счет учета = 488; Займ выдан на сумму меньше или равен 30 т.р. и меньше или равен 30 дней; Сумма по полю "Задолженность ОД"'
,18
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '488'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.12.3.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.12.3.3'
,[Показатель] = '        по POS-микрозаймам'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,19

union all

--2.12.3.4
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.12.3.4'
,[Показатель] = '        физическим лицам, применяющим специальный налоговый режим «Налог на профессиональный доход» и не являющимся индивидуальными предпринимателями, в том числе:'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,20

union all

--2.13.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.13.1'
,[Показатель] = '    индивидуальными предпринимателями, в том числе:'
,[Значение] = isnull(count(distinct 
                        case when ( --v1
                                  a.repmonth < cast('2024-07-01' as date)
                                   and
                                   (
                                   a.[zadolgOD]!=0
                                   or
                                   a.[zadolgPrc]!=0
                                   or
                                   a.[penyaSum]!=0
                                   or
                                   a.[gosposhlSum]!=0
                                   )
                                   ) then a.dogNum
                              when a.repmonth >= cast('2024-07-01' as date) then a.dogNum --v2
                              end),0)
,[Примечание] = 'Схема действует после 01.07.2024 года Берем строки где "Состояние"= действует; "Способ выдачи займа"=Онлайн; Счет учета = 494. "Признак заемщика" = ИП; Дата выдачи займа не может быть больше отчетного периода; считаем договора, у одного заещика может быть несколько договоров'
,22
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '494'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.13.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.13.1.1'
,[Показатель] = '        являющимися субъектами малого и среднего предпринимательства'
,[Значение] = isnull(count(distinct 
                        case when ( --v1
                                  a.repmonth < cast('2024-07-01' as date)
                                   and
                                   (
                                   a.[zadolgOD]!=0
                                   or
                                   a.[zadolgPrc]!=0
                                   or
                                   a.[penyaSum]!=0
                                   or
                                   a.[gosposhlSum]!=0
                                   )
                                   ) then a.dogNum
                              when a.repmonth >= cast('2024-07-01' as date) then a.dogNum --v2
                              end),0)
,[Примечание] = 'к 2.13.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,23
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '494'  --v2
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.13.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.13.2'
,[Показатель] = '    юридическими лицами, в том числе:'
,[Значение] = isnull(count(distinct 
                        case when ( --v1
                                  a.repmonth < cast('2024-07-01' as date)
                                   and
                                   (
                                   a.[zadolgOD]!=0
                                   or
                                   a.[zadolgPrc]!=0
                                   or
                                   a.[penyaSum]!=0
                                   or
                                   a.[gosposhlSum]!=0
                                   )
                                   ) then a.dogNum
                              when a.repmonth >= cast('2024-07-01' as date) then a.dogNum --v2
                              end),0)
,[Примечание] = 'Схема действует после 01.07.2024 года Берем строки где "Состояние"= действует; "Способ выдачи займа"=Онлайн; Счет учета = 487.  "Признак заемщика" = ЮЛ;Дата выдачи займа не может быть больше отчетного периода; считаем договора, у одного заещика может быть несколько договоров'
,24
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '487'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.13.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.13.2.1'
,[Показатель] = '        являющимися субъектами малого и среднего предпринимательства'
,[Значение] = isnull(count(distinct 
                        case when ( --v1
                                  a.repmonth < cast('2024-07-01' as date)
                                   and
                                   (
                                   a.[zadolgOD]!=0
                                   or
                                   a.[zadolgPrc]!=0
                                   or
                                   a.[penyaSum]!=0
                                   or
                                   a.[gosposhlSum]!=0
                                   )
                                   ) then a.dogNum
                              when a.repmonth >= cast('2024-07-01' as date) then a.dogNum --v2
                              end),0)
,[Примечание] = 'к 2.13.2 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,25
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '487'  --v2
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.13.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.13.3'
,[Показатель] = '    физическими лицами, в том числе:'
,[Значение] = isnull(count(distinct 
                        case when ( --v1
                                  a.repmonth < cast('2024-07-01' as date)
                                   and
                                   (
                                   a.[zadolgOD]!=0
                                   or
                                   a.[zadolgPrc]!=0
                                   or
                                   a.[penyaSum]!=0
                                   or
                                   a.[gosposhlSum]!=0
                                   )
                                   ) then a.dogNum
                              when a.repmonth >= cast('2024-07-01' as date) then a.dogNum --v2
                              end),0)
,[Примечание] = 'Схема действует после 01.07.2024 года; Берем строки где "Состояние"= действует; "Способ выдачи займа"=Онлайн; Счет учета = 488.  "Признак заемщика" = ФЛ; Дата выдачи займа не может быть больше отчетного периода; считаем договора, у одного заещика может быть несколько договоров'
,26
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '488'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.13.3.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.13.3.1'
,[Показатель] = '        микрозаймов, отвечающих требованиям статьи 6 Федерального закона от 21 декабря 2013 года№ 353-ФЗ «О потребительском кредите (займе)»'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,27

union all

--2.13.3.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.13.3.2'
,[Показатель] = '        в сумме не более 30 тысяч рублей на срок не более 30 дней'
,[Значение] = isnull(count(distinct 
                        case when ( --v1
                                  a.repmonth < cast('2024-07-01' as date)
                                   and
                                   (
                                   a.[zadolgOD]!=0
                                   or
                                   a.[zadolgPrc]!=0
                                   or
                                   a.[penyaSum]!=0
                                   or
                                   a.[gosposhlSum]!=0
                                   )
                                   ) then a.dogNum
                              when a.repmonth >= cast('2024-07-01' as date) then a.dogNum --v2
                              end),0)
,[Примечание] = 'Схема действует после 01.07.2024 года; Берем строки где "Состояние Договора"= действует; "Способ выдачи займа"=Онлайн; "Сумма займа" меньше или равна 30 000; "Срок договора в днях" меньше или равен 30; "Признак заемщика" = ФЛ; Счет учета =488; Считаем договора, у одного заемщика может быть несколько договоров.Дата выдачи займа не может быть больше отчетного периода;'
,28
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '488'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.13.3.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.13.3.3'
,[Показатель] = '        POS-микрозаймов'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,29

union all

--2.13.3.4
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.13.3.4'
,[Показатель] = '        физическими лицами, применяющими специальный налоговый режим «Налог на профессиональный доход» и не являющимися индивидуальными предпринимателями, в том числе:'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,30

union all

--2.14.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.14.1'
,[Показатель] = '    индивидуальных предпринимателей, единиц, в том числе:'
,[Значение] = isnull(count(distinct 
                        case when ( --v1
                                  a.repmonth < cast('2024-07-01' as date)
                                   and
                                   (
                                   a.[zadolgOD]!=0
                                   or
                                   a.[zadolgPrc]!=0
                                   or
                                   a.[penyaSum]!=0
                                   or
                                   a.[gosposhlSum]!=0
                                   )
                                   ) then a.ClientID
                              when a.repmonth >= cast('2024-07-01' as date) then a.ClientID --v2
                              end),0)
,[Примечание] = 'Берем строки где "Состояние"= действует; "Способ выдачи займа"=Онлайн;Счет учета = 494. Признак заемщика = ИП; Считаем контрагентов, они не должны повторятся, лучше сверять ИНН. Дата выдачи займа (действующего договора) не может быть больше отчетного периода;'
,32
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '494'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.14.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.14.1.1'
,[Показатель] = '        являющихся субъектами малого и среднего предпринимательства'
,[Значение] = isnull(count(distinct 
                        case when ( --v1
                                  a.repmonth < cast('2024-07-01' as date)
                                   and
                                   (
                                   a.[zadolgOD]!=0
                                   or
                                   a.[zadolgPrc]!=0
                                   or
                                   a.[penyaSum]!=0
                                   or
                                   a.[gosposhlSum]!=0
                                   )
                                   ) then a.ClientID
                              when a.repmonth >= cast('2024-07-01' as date) then a.ClientID --v2
                              end),0)
,[Примечание] = 'к 2.14.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,33
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '494'  --v2
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.14.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.14.2'
,[Показатель] = '    юридических лиц, единиц, в том числе:'
,[Значение] = isnull(count(distinct 
                        case when ( --v1
                                  a.repmonth < cast('2024-07-01' as date)
                                   and
                                   (
                                   a.[zadolgOD]!=0
                                   or
                                   a.[zadolgPrc]!=0
                                   or
                                   a.[penyaSum]!=0
                                   or
                                   a.[gosposhlSum]!=0
                                   )
                                   ) then a.ClientID
                              when a.repmonth >= cast('2024-07-01' as date) then a.ClientID --v2
                              end),0)
,[Примечание] = 'Берем строки где "Состояние"= действует; "Способ выдачи займа"=Онлайн;Счет учета = 487. Признак заемщика = ЮЛ; Считаем контрагентов, они не должны повторятся, лучше сверять ИНН. Дата выдачи займа(действующего договора) не может быть больше отчетного периода;'
,34
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '487'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.14.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.14.2.1'
,[Показатель] = '        являющихся субъектами малого и среднего предпринимательства'
,[Значение] = isnull(count(distinct 
                        case when ( --v1
                                  a.repmonth < cast('2024-07-01' as date)
                                   and
                                   (
                                   a.[zadolgOD]!=0
                                   or
                                   a.[zadolgPrc]!=0
                                   or
                                   a.[penyaSum]!=0
                                   or
                                   a.[gosposhlSum]!=0
                                   )
                                   ) then a.ClientID
                              when a.repmonth >= cast('2024-07-01' as date) then a.ClientID --v2
                              end),0)
,[Примечание] = 'к 2.14.2 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,35
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '487'  --v2
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.14.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.14.3'
,[Показатель] = '    физических лиц, человек, в том числе:'
,[Значение] = isnull(count(distinct 
                        case when ( --v1
                                  a.repmonth < cast('2024-07-01' as date)
                                   and
                                   (
                                   a.[zadolgOD]!=0
                                   or
                                   a.[zadolgPrc]!=0
                                   or
                                   a.[penyaSum]!=0
                                   or
                                   a.[gosposhlSum]!=0
                                   )
                                   ) then a.ClientID
                              when a.repmonth >= cast('2024-07-01' as date) then a.ClientID --v2
                              end),0)
,[Примечание] = 'Берем строки где "Состояние"= действует; "Способ выдачи займа"=Онлайн;Счет учета = 488. Признак заемщика = ФЛ; Считаем контрагентов, они не должны повторятся, лучше сверять ИНН. Дата выдачи займа(действующего договора) не может быть больше отчетного периода;'
,36
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '488'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.14.3.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.14.3.1'
,[Показатель] = '        получивших микрозаем (микрозаймы), отвечающий (отвечающие) требованиям статьи 6 Федерального закона от 21 декабря 2013 года № 353-ФЗ «О потребительском кредите (займе)»'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,37

union all

--2.14.3.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.14.3.2'
,[Показатель] = '        получивших микрозаем (микрозаймы) в сумме не более 30 тысяч рублей на срок не более 30 дней'
,[Значение] = isnull(count(distinct 
                        case when ( --v1
                                  a.repmonth < cast('2024-07-01' as date)
                                   and
                                   (
                                   a.[zadolgOD]!=0
                                   or
                                   a.[zadolgPrc]!=0
                                   or
                                   a.[penyaSum]!=0
                                   or
                                   a.[gosposhlSum]!=0
                                   )
                                   ) then a.ClientID
                              when a.repmonth >= cast('2024-07-01' as date) then a.ClientID --v2
                              end),0)
,[Примечание] = 'Берем строки где "Состояние"= действует; "Способ выдачи займа"=Онлайн; "Сумма займа" меньше или равна 30 000; "Срок договора в днях" меньше или равен 30; Счет учета =488;  "Признак заемщика" = ФЛ; Дата выдачи займа (действующего договора) не может быть больше отчетного периода; Считаем контрагентов, они не должны повторятся, лучше сверять ИНН.'
,38
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '488'  --v2
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.14.3.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.14.3.3'
,[Показатель] = '        по POS-микрозаймам'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,39

union all

--2.14.3.4
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.14.3.4'
,[Показатель] = '        физических лиц, применяющих специальный налоговый режим «Налог на профессиональный доход» и не являющихся индивидуальными предпринимателями, в том числе:'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,40

union all

--2.15.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.15.1'
,[Показатель] = '    индивидуальными предпринимателями, в том числе:'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ИП; Счет учета = 494; "Способ выдачи займа"=Онлайн; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Считаем количество договоров, у одного заемщика может быть больше одного договора. '
,42
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '494'  --v2
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    
union all

--2.15.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.15.1.1'
,[Показатель] = '        являющимися субъектами малого и среднего предпринимательства'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'к 2.15.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,43
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '494'  --v2
and upper(a.isMSPbyDogDate) = upper('Да')
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    
union all

--2.15.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.15.2'
,[Показатель] = '    юридическими лицами, в том числе:'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; Счет учета = 487; "Способ выдачи займа"=Онлайн; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Считаем количество договоров, у одного заемщика может быть больше одного договора. '
,44
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '487'  --v2
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    
union all

--2.15.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.15.2.1'
,[Показатель] = '        являющимися субъектами малого и среднего предпринимательства'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'к 2.15.2 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,45
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '487'  --v2
and upper(a.isMSPbyDogDate) = upper('Да')
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    
union all

--2.15.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.15.3'
,[Показатель] = '    физическими лицами, в том числе:'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; Счет учета = 488; "Способ выдачи займа"=Онлайн; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Считаем количество договоров, у одного заемщика может быть больше одного договора. '
,46
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '488'  --v2
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    

union all

--2.15.3.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.15.3.1'
,[Показатель] = '        микрозаймов, отвечающих требованиям статьи 6 Федерального закона от 21 декабря 2013 года № 353-ФЗ «О потребительском кредите (займе)»'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,47

union all

--2.15.3.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.15.3.2'
,[Показатель] = '        в сумме не более 30 тысяч рублей на срок не более 30 дней'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; Счет учета = 488; "Способ выдачи займа"=Онлайн; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Сумма займа меньше или равна 30 000 р, срок договора в днях меньше или равен 30. Считаем количество договоров, у одного заемщика может быть больше одного договора. '
,48
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)!=upper('Отменен')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '488'  --v2
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.15.3.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.15.3.3'
,[Показатель] = '        POS-микрозаймов'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,49

union all

--2.15.3.4
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.15.3.4'
,[Показатель] = '        физическими лицами, применяющими специальный налоговый режим «Налог на профессиональный доход» и не являющимися индивидуальными предпринимателями, в том числе:'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,50

union all

--2.16.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.16.1'
,[Показатель] = '    индивидуальным предпринимателям, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0)  as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ИП; Счет учета = 494; "Способ выдачи займа"=Онлайн; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Сумма по полю "Сумма займа"'
,52
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '494'  --v2
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    
union all

--2.16.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.16.1.1'
,[Показатель] = '        являющимся субъектами малого и среднего предпринимательства'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0)  as money),3)
,[Примечание] = 'к 2.16.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,53
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '494'  --v2
and upper(a.isMSPbyDogDate) = upper('Да')
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    
union all

--2.16.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.16.2'
,[Показатель] = '    юридическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0)  as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; Счет учета = 487; "Способ выдачи займа"=Онлайн; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Сумма по полю "Сумма займа"'
,54
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '487'  --v2
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    
union all

--2.16.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.16.2.1'
,[Показатель] = '        являющимся субъектами малого и среднего предпринимательства'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0)  as money),3)
,[Примечание] = 'к 2.16.2 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,55
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '487'  --v2
and upper(a.isMSPbyDogDate) = upper('Да')
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    

union all

--2.16.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.16.3'
,[Показатель] = '    физическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0)  as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; Счет учета = 488; "Способ выдачи займа"=Онлайн; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Сумма по полю "Сумма займа"'
,56
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '488'  --v2
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.16.3.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.16.3.1'
,[Показатель] = '        микрозаймов, отвечающих требованиям статьи 6 Федерального закона от 21 декабря 2013 года№ 353-ФЗ «О потребительском кредите (займе)»'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,57    

union all

--2.16.3.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.16.3.2'
,[Показатель] = '        в сумме не более 30 тысяч рублей на срок не более 30 дней'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0)  as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; Счет учета = 488; "Способ выдачи займа"=Онлайн; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Сумма займа меньше или равна 30 000 р, срок договора в днях меньше или равен 30. Сумма по полю "Сумма займа"'
,58
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST2 b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)!=upper('Отменен')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Онлайн')
/*
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
*/ --v1
and substring(a.AccODNum,1,3) = '488'  --v2
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.16.3.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.16.3.3'
,[Показатель] = '        POS-микрозаймов'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,59    

union all

--2.16.3.4
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.16.3.4'
,[Показатель] = '        физическим лицам, применяющим специальный налоговый режим «Налог на профессиональный доход» и не являющимся индивидуальными предпринимателями, в том числе:'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,60    

union all

--2.17
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.17'
,[Показатель] = 'Сумма денежных средств и (или) стоимость иного имущества, поступивших в счет погашения задолженности по основному долгу по договорам онлайн-микрозайма за отчетный период, тысяч рублей, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'Дт 612, 47422, Кт 48801, 49401,48701, признак : Онлайн;  Для проводок Дт 612 Кт 48801,49401, 48701  - Признак: Полное досрочное погашение, Частичное списание;'
,61
from (
SELECT 
/*
[Сумма БУ] = case when upper(ces.Представление) like upper('%передача прав требований%') then 0 --Убирается Цессия 
                  else a.Сумма 
                  end
*/ --v1
[Сумма БУ] = a.Сумма --v2
,[Способ выдачи займа КТ] = 
    case when sposobKT.Имя = 'Дистанционный' then 'Онлайн'
         when sposobKT.Имя = 'Посреднический' then 'Дистанционный'
         when sposobKT.Имя = 'Прямой' then 'Дистанционный'
         end

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка  --v1
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
and (
(Kt.Код in ('48801','48701','49401') and Dt.Код='47422')
or
(Kt.Код in ('48801','48701','49401') and substring(Dt.Код,1,3) ='612'
and a.СубконтоDt3_Ссылка in (
0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
) 
)
)--v2
) l1

where l1.[Способ выдачи займа КТ]='Онлайн'--'Дистанционный' --'Онлайн'

union all

--2.17.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.17.1'
,[Показатель] = '    сумма денежных средств'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'Дт 61217, 47422,  Кт 48801, 49401,48701, признак : Онлайн;  Для проводок Дт 61217 Кт 48801,49401, 48701  - Признак: Полное досрочное погашение'
,62
from (
SELECT 
/*
[Сумма БУ] = case when upper(ces.Представление) like upper('%передача прав требований%') then 0 --Убирается Цессия 
                  else a.Сумма 
                  end
*/ --v1
[Сумма БУ] = a.Сумма --v2
,[Способ выдачи займа КТ] = 
    case when sposobKT.Имя = 'Дистанционный' then 'Онлайн'
         when sposobKT.Имя = 'Посреднический' then 'Дистанционный'
         when sposobKT.Имя = 'Прямой' then 'Дистанционный'
         end

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
and (
(Kt.Код in ('48801','48701','49401') and Dt.Код='47422')
or
(Kt.Код in ('48801','48701','49401') and Dt.Код ='61217'
and a.СубконтоDt3_Ссылка in (
0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
) 
)
)--v2
) l1

where l1.[Способ выдачи займа КТ]='Онлайн'--'Дистанционный' --'Онлайн'
    

union all

--2.18
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.18'
,[Показатель] = 'Сумма денежных средств и (или) стоимость иного имущества, поступивших в счет погашения задолженности по процентам по договорам онлайн-микрозайма за отчетный период, тысяч рублей, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'Дт 48809, 49409, 48709 612 Кт 48802, 49402, 48702, признак : Онлайн;  Для проводок Дт 612 Кт 48802,49402, 48702  - Признак: Полное досрочное погашение, Частичное списание;'
,63
from (
SELECT 
/*
[Сумма БУ] = case when upper(ces.Представление) like upper('%передача прав требований%') then 0 --Убирается Цессия 
                  else a.Сумма 
                  end
*/ --v1
[Сумма БУ] = a.Сумма --v2
,[Способ выдачи займа КТ] = 
    case when sposobKT.Имя = 'Дистанционный' then 'Онлайн'
         when sposobKT.Имя = 'Посреднический' then 'Дистанционный'
         when sposobKT.Имя = 'Прямой' then 'Дистанционный'
         end

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
--and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','61215','49409')) --v1
and (
    (Kt.Код in ('48802','48702','49402') and Dt.Код in ('48809','49409','48709'))
    or
    (Kt.Код in ('48802','48702','49402') and substring(Dt.Код,1,3) = '612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
                                )
    )
    )
) l1

where l1.[Способ выдачи займа КТ]='Онлайн'--'Дистанционный' --'Онлайн'

union all

--2.18.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.18.1'
,[Показатель] = '    сумма денежных средств'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'Дт 48809, 49409, 48709  Кт 48802, 49402, 48702, признак : Онлайн);'
,64
from (
SELECT 
/*
[Сумма БУ] = case when upper(ces.Представление) like upper('%передача прав требований%') then 0 --Убирается Цессия 
                  else a.Сумма 
                  end
*/ --v1
[Сумма БУ] = a.Сумма --v2
,[Способ выдачи займа КТ] = 
    case when sposobKT.Имя = 'Дистанционный' then 'Онлайн'
         when sposobKT.Имя = 'Посреднический' then 'Дистанционный'
         when sposobKT.Имя = 'Прямой' then 'Дистанционный'
         end

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
--and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','49409')) --v1
and (Kt.Код in ('48802','48702','49402') and Dt.Код in ('48809','49409','48709'))  --v2
) l1

where l1.[Способ выдачи займа КТ]='Онлайн'--'Дистанционный' --'Онлайн'
    

union all

--2.19
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.19'
,[Показатель] = 'Сумма денежных средств и (или) стоимость иного имущества, поступивших в счет погашения задолженности по неустойке (штрафу, пене) по договорам онлайн-микрозайма за отчетный период, тысяч рублей, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'Дт 47422 612  Кт 60323, признак : Онлайн;  Для проводок Дт 612 Кт 6023  - Признак: Полное досрочное погашение, Частичное списание; ВидыПлатежейПоЗаймам - не равен госпошлины, проценты, мошенники'
,65
from (

SELECT 
/*
[Сумма БУ] = case when 
                   (
                   upper(ces.Представление) like upper('%передача прав требований%')
                   or
                   upper(ces2.Представление) like upper('%передача прав требований%')
                   )
                   then 0 --Убирается Цессия
                   --when (Dt.Код in ('60323') and substring(kt.Код,1,3)='612') then -a.Сумма
                   else a.Сумма 
              end
*/  --v1
[Сумма БУ] = a.Сумма --v2
,[Способ выдачи займа КТ] = 
    case when isnull(sposobKTp.Имя,sposobkT2.Имя) = 'Дистанционный' then 'Онлайн'
         when isnull(sposobKTp.Имя,sposobkT2.Имя) = 'Посреднический' then 'Дистанционный'
         when isnull(sposobKTp.Имя,sposobkT2.Имя) = 'Прямой' then 'Дистанционный'
         end
--,[Вид выбытия] = isnull(ces.Представление,ces2.Представление)
--,[Признак Госпошлиы] = a.СубконтоCt3_Ссылка
from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKTp on a.СубконтоCt2_Ссылка=spKTp.ДоговорКонтрагента and spktp.ДополнительноеСоглашение=0x00
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKTp on spKTp.СпособПодачиЗаявления=sposobKTp.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces2 on a.СубконтоCt3_Ссылка=ces2.Ссылка

left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT2 on spKT.СпособПодачиЗаявления=sposobKT2.Ссылка
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)

/*
and (
    (Kt.Код in ('60323') and (Dt.Код ='47422' or substring(Dt.Код,1,3)='612') and a.СубконтоCt3_Ссылка=0x00000000000000000000000000000000)
    or
    (Dt.Код in ('60323') and substring(kt.Код,1,3)='612')
    )
*/ --v1
and (
    (Kt.Код in ('60323') and Dt.Код ='47422')
    or
    (Kt.Код in ('60323') and substring(Dt.Код,1,3) ='612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
                                )
    ))
and a.СубконтоCt3_Ссылка not in (
                                0xA2EB0050568397CF11EDB7B4A7CAC846 --Госпошлина
                                ,0xA3000050568397CF11EEC6735BC498A2 --Проценты
                                ,0xA3040050568397CF11EF3A45E64722DE --Проценты
                                ,0xA3040050568397CF11EF543103C0F623 --Мошенники
                                )
    
     --v2
) l1

where l1.[Способ выдачи займа КТ]='Онлайн'--'Дистанционный' --'Онлайн'

union all

--2.19.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.19.1'
,[Показатель] = '    сумма денежных средств'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'Дт 47422 61217 Кт 60323, признак : Онлайн;  Для проводок Дт 612 Кт 6023  - Признак: Полное досрочное погашение; ВидыПлатежейПоЗаймам - не равен госпошлины, проценты, мошенники'
,66
from (

SELECT 
/*
[Сумма БУ] = case when 
                   (
                   upper(ces.Представление) like upper('%передача прав требований%')
                   or
                   upper(ces2.Представление) like upper('%передача прав требований%')
                   )
                   then 0 --Убирается Цессия
                   --when (Dt.Код in ('60323') and substring(kt.Код,1,3)='612') then -a.Сумма
                   else a.Сумма 
              end
*/
[Сумма БУ] = a.Сумма --v2
,[Способ выдачи займа КТ] = 
    case when isnull(sposobKTp.Имя,sposobkT2.Имя) = 'Дистанционный' then 'Онлайн'
         when isnull(sposobKTp.Имя,sposobkT2.Имя) = 'Посреднический' then 'Дистанционный'
         when isnull(sposobKTp.Имя,sposobkT2.Имя) = 'Прямой' then 'Дистанционный'
         end
--,[Вид выбытия] = isnull(ces.Представление,ces2.Представление)
--,[Признак Госпошлиы] = a.СубконтоCt3_Ссылка
from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKTp on a.СубконтоCt2_Ссылка=spKTp.ДоговорКонтрагента and spktp.ДополнительноеСоглашение=0x00
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKTp on spKTp.СпособПодачиЗаявления=sposobKTp.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces2 on a.СубконтоCt3_Ссылка=ces2.Ссылка

left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT2 on spKT.СпособПодачиЗаявления=sposobKT2.Ссылка
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)

/*
and (
    (Kt.Код in ('60323') and Dt.Код  in ('47422','61217') and a.СубконтоCt3_Ссылка=0x00000000000000000000000000000000)
    or
    (Dt.Код in ('60323') and substring(kt.Код,1,3)='612')
    )
*/ --v1
and (
    (Kt.Код in ('60323') and Dt.Код ='47422')
    or
    (Kt.Код in ('60323') and Dt.Код ='61217'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
                                )
    ))
and a.СубконтоCt3_Ссылка not in (
                                0xA2EB0050568397CF11EDB7B4A7CAC846 --Госпошлина
                                ,0xA3000050568397CF11EEC6735BC498A2 --Проценты
                                ,0xA3040050568397CF11EF3A45E64722DE --Проценты
                                ,0xA3040050568397CF11EF543103C0F623 --Мошенники
                                )
    
     --v2

) l1

where l1.[Способ выдачи займа КТ]='Онлайн'--'Дистанционный' --'Онлайн'

union all

--2.20
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.20'
,[Показатель] = 'Сумма задолженности по договорам онлайн-микрозайма, списанной с баланса микрофинансовой компании за отчетный период, тысяч рублей, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'Онлайн сумма по ДЕБЕТУ счетов 49410, 48710, 48810 и 71802 из отчета по счетам 48801, 49401 и 48701, 
+ сумма по ДЕБЕТУ счетов 49410, 48710,48810 и 71802 из отчета по счетам 48802, 49402, 48702 
+ сумма по ДЕБЕТУ счету 60324 из отчета по счету 60323 Онлайн ВидыПлатежейПоЗаймам - не равен госпошлины, проценты, мошенники'
,67
from (

SELECT 
/*
[Сумма БУ] = case when upper(ces.Представление) like upper('%передача прав требований%') then 0 --Убирается Цессия
                  else a.Сумма 
                  end
*/ -- v1
[Сумма БУ] = a.Сумма --v2
,[Способ выдачи займа КТ] = 
    case when isnull(sposobKT.Имя,sposobkTp.Имя) = 'Дистанционный' then 'Онлайн'
         when isnull(sposobKT.Имя,sposobkTp.Имя) = 'Посреднический' then 'Дистанционный'
         when isnull(sposobKT.Имя,sposobkTp.Имя) = 'Прямой' then 'Дистанционный'
         end

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1

left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKTp on a.СубконтоCt2_Ссылка=spKTp.ДоговорКонтрагента and spktp.ДополнительноеСоглашение=0x00
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKTp on spKTp.СпособПодачиЗаявления=sposobKTp.Ссылка
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)

/*
and (
     (Kt.Код in ('48801','49401','48701') and Dt.Код in ('48810','71802','49410','48710')) 
     or
     (Kt.Код in ('48802','49402','48702') and Dt.Код in ('48810','71802','49410','48710')) 
     or
     (Kt.Код ='60323' and Dt.Код ='60324' and a.СубконтоCt3_Ссылка=0x00000000000000000000000000000000) 
     )
*/ -- v1
and (
     (Kt.Код in ('48801','49401','48701') and Dt.Код in ('48810','71802','49410','48710')) 
     or
     (Kt.Код in ('48802','49402','48702') and Dt.Код in ('48810','71802','49410','48710')) 
     or
     (Kt.Код ='60323' and Dt.Код ='60324' 
     and a.СубконтоCt3_Ссылка not in (
                                0xA2EB0050568397CF11EDB7B4A7CAC846 --Госпошлина
                                ,0xA3000050568397CF11EEC6735BC498A2 --Проценты
                                ,0xA3040050568397CF11EF3A45E64722DE --Проценты
                                ,0xA3040050568397CF11EF543103C0F623 --Мошенники
                                )
     ) 
     ) --v2
) l1

where l1.[Способ выдачи займа КТ]='Онлайн'--'Дистанционный' --'Онлайн'

union all

--2.20.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.2'
,[Пункт] = '2.20.1'
,[Показатель] = '    по основному долгу'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'сумма по ДЕБЕТУ счетов 49410, 48710, 48810 и 71802 из отчета по счетам 48801, 49401 и 48701, 
 Онлайн ВидыПлатежейПоЗаймам - не равен госпошлины, проценты, мошенники'
,68
from (

SELECT 
/*
[Сумма БУ] = case when upper(ces.Представление) like upper('%передача прав требований%') then 0 --Убирается Цессия
                  else a.Сумма 
                  end
*/ --v1
[Сумма БУ] = a.Сумма --v2
,[Способ выдачи займа КТ] = 
    case when isnull(sposobKT.Имя,sposobkTp.Имя) = 'Дистанционный' then 'Онлайн'
         when isnull(sposobKT.Имя,sposobkTp.Имя) = 'Посреднический' then 'Дистанционный'
         when isnull(sposobKT.Имя,sposobkTp.Имя) = 'Прямой' then 'Дистанционный'
         end

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1

left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKTp on a.СубконтоCt2_Ссылка=spKTp.ДоговорКонтрагента and spktp.ДополнительноеСоглашение=0x00
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKTp on spKTp.СпособПодачиЗаявления=sposobKTp.Ссылка
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)

and (
     (Kt.Код in ('48801','49401','48701') and Dt.Код in ('48810','71802','49410','48710')) 
     )
) l1

where l1.[Способ выдачи займа КТ]='Онлайн'--'Дистанционный' --'Онлайн'
 

	end try

	BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
       ,ERROR_MESSAGE() AS ErrorMessage;  
	END CATCH  

END
