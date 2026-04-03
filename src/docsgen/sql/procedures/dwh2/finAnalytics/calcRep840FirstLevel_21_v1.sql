


CREATE PROCEDURE [finAnalytics].[calcRep840FirstLevel_21_v1]
	@repmonth date,
    @repdate date
    --,    @sumRang int
AS
BEGIN

Create table #ID_LIST(
[ID] [int] NOT NULL)

INSERT INTO #ID_LIST
select id
from finAnalytics.PBR_MONTHLY a
where a.REPMONTH=@repmonth
--and a.REPDATE=@repdate

BEGIN TRY

delete from finAnalytics.rep840_firstLevel
where REPMONTH=@repmonth and REPDATE=@repdate and razdel='2.1'

insert into finAnalytics.rep840_firstLevel
(REPMONTH, REPDATE, razdel, punkt, pokazatel, value, comment, rownum)
---Заполняем нижний уровень

--2.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.1.1'
,[Показатель] = '    индивидуальным предпринимателям, в том числе:'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ИП; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; "Контрагент" не равен Техмани или АйОТи. Сумма по полю "Задолженность ОД"'
,2
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.1.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.1.1.1'
,[Показатель] = '        являющимся субъектами малого и среднего предпринимательства'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0) as money),3)
,[Примечание] = 'к 2.1.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,3
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.1.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.1.2'
,[Показатель] = '    юридическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; "Контрагент" не равен Техмани или АйОТи. Сумма по полю "Задолженность ОД"'
,4
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.1.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.1.2.1'
,[Показатель] = '        являющимся субъектами малого и среднего предпринимательства'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0) as money),3)
,[Примечание] = 'к 2.1.1 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,5
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.1.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.1.3'
,[Показатель] = '    физическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; "Контрагент" не равен Техмани или АйОТи. Сумма по полю "Задолженность ОД"'
,6
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.1.3.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.1.3.1'
,[Показатель] = '        по микрозаймам, отвечающим требованиям статьи 6 Федерального закона от 21 декабря 2013 года № 353-ФЗ «О потребительском кредите (займе)»'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,7

union all

--2.1.3.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.1.3.2'
,[Показатель] = '        в сумме не более 30 тысяч рублей на срок не более 30 дней'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционно; "Финансовый продукт"=PDL; "Контрагент" не равен Техмани или АйОТи. Сумма по полю "Задолженность ОД"'
,8
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
--and UPPER(a.finProd) = UPPER('PDL')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.1.3.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.1.3.3'
,[Показатель] = '        обеспеченным ипотекой'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,9

union all

--2.1.3.4
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.1.3.4'
,[Показатель] = '        по POS-микрозаймам'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,10

union all

--2.1.3.5
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.1.3.5'
,[Показатель] = '        физическим лицам, применяющим специальный налоговый режим «Налог на профессиональный доход» и не являющимся индивидуальными предпринимателями, в том числе:'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,11

union all

--2.1.3.5.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.1.3.5.1'
,[Показатель] = '        по микрозаймам, обязательства по которым обеспечены ипотекой'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,12

union all

--2.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.2.1'
,[Показатель] = '    индивидуальным предпринимателям, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(zadolgPrc),0) as money),3)
              +
              ROUND(cast(isnull(sum(penyaSum),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ИП; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; "Контрагент" не равен Техмани или АйОТи. Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,14
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.2.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.2.1.1'
,[Показатель] = '        являющимся субъектами малого и среднего предпринимательства'
,[Значение] = ROUND(cast(isnull(sum(zadolgPrc),0) as money),3)
              +
              ROUND(cast(isnull(sum(penyaSum),0) as money),3)
,[Примечание] = 'к 2.1.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,15
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.2.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.2.2'
,[Показатель] = '    юридическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(zadolgPrc),0) as money),3)
              +
              ROUND(cast(isnull(sum(penyaSum),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; "Контрагент" не равен Техмани или АйОТи. Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,16
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.2.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.2.2.1'
,[Показатель] = '        являющимся субъектами малого и среднего предпринимательства'
,[Значение] = ROUND(cast(isnull(sum(zadolgPrc),0) as money),3)
              +
              ROUND(cast(isnull(sum(penyaSum),0) as money),3)
,[Примечание] = 'к 2.1.1 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,17
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.2.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.2.3'
,[Показатель] = '    физическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(zadolgPrc),0) as money),3)
              +
              ROUND(cast(isnull(sum(penyaSum),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; "Контрагент" не равен Техмани или АйОТи. Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,18
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.2.3.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.2.3.1'
,[Показатель] = '        по микрозаймам, отвечающим требованиям статьи 6 Федерального закона от 21 декабря 2013 года № 353-ФЗ «О потребительском кредите (займе)»'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,19

union all

--2.2.3.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.2.3.2'
,[Показатель] = '        в сумме не более 30 тысяч рублей на срок не более 30 дней'
,[Значение] = ROUND(cast(isnull(sum(zadolgPrc),0) as money),3)
              +
              ROUND(cast(isnull(sum(penyaSum),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционно; "Финансовый продукт"=PDL; "Контрагент" не равен Техмани или АйОТи. Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,20
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
--and UPPER(a.finProd) = UPPER('PDL')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.2.3.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.2.3.3'
,[Показатель] = '        обеспеченным ипотекой'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,21

union all

--2.2.3.4
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.2.3.4'
,[Показатель] = '        по POS-микрозаймам'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,22

union all

--2.2.3.5
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.2.3.5'
,[Показатель] = '        физическим лицам, применяющим специальный налоговый режим «Налог на профессиональный доход» и не являющимся индивидуальными предпринимателями, в том числе:'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,23

union all

--2.2.3.5.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.2.3.5.1'
,[Показатель] = '        по микрозаймам, обязательства по которым обеспечены ипотекой'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,24

union all

--2.3.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.3.1'
,[Показатель] = '    индивидуальными предпринимателями, в том числе:'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ИП; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; "Контрагент" не равен Техмани или АйОТи. Количество строк, где сумма по полю "Задолженность ОД", "Задолженность проценты" и "Сумма пени счета" не равна нулю хотя бы в одно из полей'
,26
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
/*  ---Отменено в ТЗ от 03.09.2024
and (
    a.[zadolgOD]!=0
    or
    a.[zadolgPrc]!=0
    or
    a.[penyaSum]!=0
    )
*/
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.3.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.3.1.1'
,[Показатель] = '        являющимися субъектами малого и среднего предпринимательства'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'к 2.1.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,27
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
/*  ---Отменено в ТЗ от 03.09.2024
and (
    a.[zadolgOD]!=0
    or
    a.[zadolgPrc]!=0
    or
    a.[penyaSum]!=0
    )
*/
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.3.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.3.2'
,[Показатель] = '    юридическими лицами, в том числе:'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; "Контрагент" не равен Техмани или АйОТи. Количество строк, где сумма по полю "Задолженность ОД", "Задолженность проценты" и "Сумма пени счета" не равна нулю  хотя бы в одно из полей'
,28
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
/*  ---Отменено в ТЗ от 03.09.2024
and (
    a.[zadolgOD]!=0
    or
    a.[zadolgPrc]!=0
    or
    a.[penyaSum]!=0
    )
*/
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.3.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.3.2.1'
,[Показатель] = '        являющимися субъектами малого и среднего предпринимательства'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'к 2.1.1 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,29
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
/*  ---Отменено в ТЗ от 03.09.2024
and (
    a.[zadolgOD]!=0
    or
    a.[zadolgPrc]!=0
    or
    a.[penyaSum]!=0
    )
*/
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.3.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.3.3'
,[Показатель] = '    физическими лицами, в том числе:'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; "Контрагент" не равен Техмани или АйОТи. Количество строк, где сумма по полю "Задолженность ОД", "Задолженность проценты" и "Сумма пени счета" и "Сумма госпошлин счета" не равна нулю  хотя бы в одно из полей'
,30
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
/*  ---Отменено в ТЗ от 03.09.2024
and (
    a.[zadolgOD]!=0
    or
    a.[zadolgPrc]!=0
    or
    a.[penyaSum]!=0
    or
    a.[gosposhlSum]!=0
    )
*/
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.3.3.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.3.3.1'
,[Показатель] = '        микрозаймов, отвечающих требованиям статьи 6 Федерального закона от 21 декабря 2013 года№ 353-ФЗ «О потребительском кредите (займе)»'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,31

union all

--2.3.3.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.3.3.2'
,[Показатель] = '        в сумме не более 30 тысяч рублей на срок не более 30 дней'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный;"Финансовый продукт"=PDL; "Контрагент" не равен Техмани или АйОТи. Количество строк, где сумма по полю "Задолженность ОД", "Задолженность проценты" и "Сумма пени счета" не равна нулю  хотя бы в одно из полей'
,32
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
--and upper(a.finProd)=upper('PDL')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
/*  ---Отменено в ТЗ от 03.09.2024
and (
    a.[zadolgOD]!=0
    or
    a.[zadolgPrc]!=0
    or
    a.[penyaSum]!=0
    or
    a.[gosposhlSum]!=0
    )
*/
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.3.3.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.3.3.3'
,[Показатель] = '        обеспеченных ипотекой'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,33

union all

--2.3.3.4
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.3.3.4'
,[Показатель] = '        POS-микрозаймов'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,34

union all

--2.3.3.5
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.3.3.5'
,[Показатель] = '        физическими лицами, применяющими специальный налоговый режим «Налог на профессиональный доход» и не являющимися индивидуальными предпринимателями, в том числе:'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,35

union all

--2.3.3.5.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.3.3.5.1'
,[Показатель] = '        микрозаймов, обязательства по которым обеспечены ипотекой'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,36


union all

--2.4.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.4.1'
,[Показатель] = '    индивидуальных предпринимателей, единиц, в том числе:'
,[Значение] = isnull(count(distinct a.Client),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ИП; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; "Контрагент" не равен Техмани или АйОТи. Количество строк, где сумма по полю "Задолженность ОД", "Задолженность проценты" и "Сумма пени счета" не равна нулю и значение в поле  "Контрагент" не совпадает с другими'
,38
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
/*  ---Отменено в ТЗ от 03.09.2024
and (
    a.[zadolgOD]!=0
    or
    a.[zadolgPrc]!=0
    or
    a.[penyaSum]!=0
    )
*/
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.4.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.4.1.1'
,[Показатель] = '        являющихся субъектами малого и среднего предпринимательства'
,[Значение] = isnull(count(distinct a.Client),0)
,[Примечание] = 'к 2.1.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,39
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
/*  ---Отменено в ТЗ от 03.09.2024
and (
    a.[zadolgOD]!=0
    or
    a.[zadolgPrc]!=0
    or
    a.[penyaSum]!=0
    )
*/
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.4.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.4.2'
,[Показатель] = '    юридических лиц, единиц, в том числе:'
,[Значение] = isnull(count(distinct a.Client),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; "Контрагент" не равен Техмани или АйОТи. Количество строк, где сумма по полю "Задолженность ОД", "Задолженность проценты" и "Сумма пени счета" не равна нулю и значение в поле  "Контрагент" не совпадает с другими'
,40
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
/*  ---Отменено в ТЗ от 03.09.2024
and (
    a.[zadolgOD]!=0
    or
    a.[zadolgPrc]!=0
    or
    a.[penyaSum]!=0
    )
*/
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.4.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.4.2.1'
,[Показатель] = '        являющихся субъектами малого и среднего предпринимательства'
,[Значение] = isnull(count(distinct a.Client),0)
,[Примечание] = 'к 2.1.1 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,41
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
/*  ---Отменено в ТЗ от 03.09.2024
and (
    a.[zadolgOD]!=0
    or
    a.[zadolgPrc]!=0
    or
    a.[penyaSum]!=0
    )
*/
and upper(a.isMSPbyDogDate) = upper('Да')
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.4.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.4.3'
,[Показатель] = '    физических лиц, человек, в том числе:'
,[Значение] = isnull(count(distinct a.Client),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; "Контрагент" не равен Техмани или АйОТи. Количество строк, где сумма по полю "Задолженность ОД", "Задолженность проценты" и "Сумма пени счета" не равна нулю и значение в поле  "Контрагент" не совпадает с другими'
,42
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
/*  ---Отменено в ТЗ от 03.09.2024
and (
    a.[zadolgOD]!=0
    or
    a.[zadolgPrc]!=0
    or
    a.[penyaSum]!=0
    or
    a.[gosposhlSum]!=0
    )
*/
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.4.3.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.4.3.1'
,[Показатель] = '        получивших микрозаем (микрозаймы), отвечающий (отвечающие) требованиям статьи 6 Федерального закона от 21 декабря 2013 года № 353-ФЗ «О потребительском кредите (займе)»'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,43

union all

--2.4.3.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.4.3.2'
,[Показатель] = '        получивших микрозаем (микрозаймы) в сумме не более 30 тысяч рублей на срок не более 30 дней'
,[Значение] = isnull(count(distinct a.Client),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; "Финансовый продукт"=PDL;"Контрагент" не равен Техмани или АйОТи. Количество строк, где сумма по полю "Задолженность ОД", "Задолженность проценты" и "Сумма пени счета" не равна нулю и значение в поле  "Контрагент" не совпадает с другими'
,44
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
--and upper(a.finProd)=upper('PDL')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
/*  ---Отменено в ТЗ от 03.09.2024
and (
    a.[zadolgOD]!=0
    or
    a.[zadolgPrc]!=0
    or
    a.[penyaSum]!=0
    or
    a.[gosposhlSum]!=0
    )
*/
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.4.3.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.4.3.3'
,[Показатель] = '        получивших микрозаем (микрозаймы), обеспеченный (обеспеченные) ипотекой'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,45

union all

--2.4.3.4
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.4.3.4'
,[Показатель] = '        по POS-микрозаймам'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,46

union all

--2.4.3.5
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.4.3.5'
,[Показатель] = '        физических лиц, применяющих специальный налоговый режим «Налог на профессиональный доход» и не являющихся индивидуальными предпринимателями, в том числе:'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,47

union all

--2.4.3.5.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.4.3.5.1'
,[Показатель] = '        физических лиц, применяющих специальный налоговый режим «Налог на профессиональный доход» и не являющихся индивидуальными предпринимателями, в том числе:'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,48

union all

--2.5.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.5.1'
,[Показатель] = '    индивидуальными предпринимателями, в том числе:'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ИП; "Способ выдачи займа"=Дистанционный; "Состояние"<> "Отменен"; "Контрагент" не равен Техмани или АйОТи; год даты выдачи равен текущему году. Количество строк. Дата выдачи меньше или равно отчетному месяцу'
,50
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    
union all

--2.5.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.5.1.1'
,[Показатель] = '        являющимися субъектами малого и среднего предпринимательства'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'к 2.1.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,51
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and upper(a.isMSPbyDogDate) = upper('Да')
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    
union all

--2.5.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.5.2'
,[Показатель] = '    юридическими лицами, в том числе:'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; "Способ выдачи займа"=Дистанционный; "Состояние"<> "Отменен"; "Контрагент" не равен Техмани или АйОТи; год даты выдачи равен текущему году. Количество строк. Дата выдачи меньше или равно отчетному месяцу'
,52
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    
union all

--2.5.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.5.2.1'
,[Показатель] = '        являющимися субъектами малого и среднего предпринимательства'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'к 2.1.1 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,53
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and upper(a.isMSPbyDogDate) = upper('Да')
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    
union all

--2.5.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.5.3'
,[Показатель] = '    физическими лицами, в том числе:'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Способ выдачи займа"=Дистанционный; "Состояние"<> "Отменен"; "Контрагент" не равен Техмани или АйОТи; год даты выдачи равен текущему году. Количество строк. Дата выдачи меньше или равно отчетному месяцу'
,54
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    

union all

--2.5.3.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.5.3.1'
,[Показатель] = '        микрозаймов, отвечающих требованиям статьи 6 Федерального закона от 21 декабря 2013 года № 353-ФЗ «О потребительском кредите (займе)»'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,55

union all

--2.5.3.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.5.3.2'
,[Показатель] = '        в сумме не более 30 тысяч рублей на срок не более 30 дней'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Способ выдачи займа"=Дистанционный; "Состояние"<> "Отменен"; "Финансовый продукт"=PDL; "Контрагент" не равен Техмани или АйОТи; год даты выдачи равен текущему году. Количество строк. Дата выдачи меньше или равно отчетному месяцу'
,56
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)!=upper('Отменен')
--and upper(a.finProd)=upper('PDL')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.5.3.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.5.3.3'
,[Показатель] = '        обеспеченных ипотекой'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,57

union all

--2.5.3.4
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.5.3.4'
,[Показатель] = '        POS-микрозаймов'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,58

union all

--2.5.3.5
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.5.3.5'
,[Показатель] = '        физическими лицами, применяющими специальный налоговый режим «Налог на профессиональный доход» и не являющимися индивидуальными предпринимателями, в том числе:'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,59

union all

--2.5.3.5.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.5.3.5.1'
,[Показатель] = '        микрозаймов, обязательства по которым обеспечены ипотекой'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,60

union all


--2.6.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.6.1'
,[Показатель] = '    индивидуальным предпринимателям, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ИП; "Состояние"<> "Отменен"; "Способ выдачи займа"=Дистанционный; "Контрагент" не равен Техмани или АйОТи; год даты выдачи равен текущему году; дата выдачи меньше или равна отчетной дате. Сумма по полю "Сумма займа"'
,62
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    
union all

--2.6.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.6.1.1'
,[Показатель] = '        являющимся субъектами малого и среднего предпринимательства'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0) as money),3)
,[Примечание] = 'к 2.1.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,63
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and upper(a.isMSPbyDogDate) = upper('Да')
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    
union all

--2.6.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.6.2'
,[Показатель] = '    юридическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; "Состояние"<> "Отменен"; "Способ выдачи займа"=Дистанционный; "Контрагент" не равен Техмани или АйОТи; год даты выдачи равен текущему году; дата выдачи меньше или равна отчетной дате. Сумма по полю "Сумма займа"'
,64
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    
union all

--2.6.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.6.2.1'
,[Показатель] = '        являющимся субъектами малого и среднего предпринимательства'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0) as money),3)
,[Примечание] = 'к 2.1.1 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,65
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and upper(a.isMSPbyDogDate) = upper('Да')
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)
    

union all

--2.6.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.6.3'
,[Показатель] = '    физическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"<> "Отменен"; "Способ выдачи займа"=Дистанционный; "Контрагент" не равен Техмани или АйОТи; год даты выдачи равен текущему году; дата выдачи меньше или равна отчетной дате. Сумма по полю "Сумма займа"'
,66
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.6.3.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.6.3.1'
,[Показатель] = '        микрозаймов, отвечающих требованиям статьи 6 Федерального закона от 21 декабря 2013 года№ 353-ФЗ «О потребительском кредите (займе)»'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,67    

union all

--2.6.3.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.6.3.2'
,[Показатель] = '        в сумме не более 30 тысяч рублей на срок не более 30 дней'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"<> "Отменен"; "Способ выдачи займа"=Дистанционный; "Финансовый продукт"=PDL;"Контрагент" не равен Техмани или АйОТи; год даты выдачи равен текущему году; дата выдачи меньше или равна отчетной дате. Сумма по полю "Сумма займа"'
,68
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)!=upper('Отменен')
--and upper(a.finProd)=upper('PDL')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Дистанционный')
and (
    upper(a.[Client]) not like upper('%Техмани%')
    and
    upper(a.[Client]) not like upper('%АйОТи%')
    )
and YEAR(a.REPMONTH) = YEAR(a.saleDate)
and a.saleDate<=EOMONTH(a.REPMONTH)

union all

--2.6.3.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.6.3.3'
,[Показатель] = '        обеспеченных ипотекой'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,69    

union all

--2.6.3.4
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.6.3.4'
,[Показатель] = '        POS-микрозаймов'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,70    

union all

--2.6.3.5
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.6.3.5'
,[Показатель] = '        физическим лицам, применяющим специальный налоговый режим «Налог на профессиональный доход» и не являющимся индивидуальными предпринимателями, в том числе:'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,71    

union all

--2.6.3.5.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.6.3.5.1'
,[Показатель] = '        микрозаймов, обязательства по которым обеспечены ипотекой'
,[Значение] = 0
,[Примечание] = 'Не считаем'
,72    

union all

--2.7
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.7'
,[Показатель] = 'Сумма денежных средств и (или) стоимость иного имущества, поступивших в счет погашения задолженности по основному долгу по договорам микрозайма за отчетный период, тысяч рублей, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'сумма по ДЕБЕТУ счетов 47422 и 612 из отчета по счетам  Кредит 48801, 49401 и 48701, "Дистанс", Убрать Цессию'
,73
from (
SELECT 
[Сумма БУ] = case when upper(ces.Представление) like upper('%передача прав требований%') then 0 --Убирается Цессия
                  else a.Сумма 
                  end
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
left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
and (Kt.Код in ('48801','48701','49401') and (substring(Dt.Код,1,3) ='612' or  Dt.Код='47422')) -- +Погашения ОД
) l1

where l1.[Способ выдачи займа КТ]='Дистанционный'--'Дистанционный' --'Онлайн'

union all

--2.7.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.7.1'
,[Показатель] = '    сумма денежных средств'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'сумма по ДЕБЕТУ счетов 47422 и 61217 из отчета по счетам 48801, 49401 и 48701,"Дистанс", Убрать Цессию'
,74
from (
SELECT 
[Сумма БУ] = case when upper(ces.Представление) like upper('%передача прав требований%') then 0 --Убирается Цессия
                  else a.Сумма 
                  end
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
left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
and (Kt.Код in ('48801','48701','49401') and Dt.Код in ('61217','47422'))
) l1

where l1.[Способ выдачи займа КТ]='Дистанционный'--'Дистанционный' --'Онлайн'
    

union all

--2.8
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.8'
,[Показатель] = 'Сумма денежных средств и (или) стоимость иного имущества, поступивших в счет погашения задолженности по процентам по договорам микрозайма за отчетный период, тысяч рублей, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'сумма по ДЕБЕТУ счетов 48809,  61215 и 49409 из отчета по счетам 48802, 49402, "Дистанс", Убрать Цессию'
,75
from (
SELECT 
[Сумма БУ] = case when upper(ces.Представление) like upper('%передача прав требований%') then 0 --Убирается Цессия
                  else a.Сумма 
                  end
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
left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','61215','49409'))
) l1

where l1.[Способ выдачи займа КТ]='Дистанционный'--'Дистанционный' --'Онлайн'

union all

--2.8.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.8.1'
,[Показатель] = '    сумма денежных средств'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'сумма по ДЕБЕТУ счетов 48809 и 49409 из отчета по счетам 48802, 49402, "Дистанс", Убрать Цессию'
,76
from (
SELECT 
[Сумма БУ] = case when upper(ces.Представление) like upper('%передача прав требований%') then 0 --Убирается Цессия
                  else a.Сумма 
                  end
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
left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','49409'))
) l1

where l1.[Способ выдачи займа КТ]='Дистанционный'--'Дистанционный' --'Онлайн'
    

union all

--2.9
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.9'
,[Показатель] = 'Сумма денежных средств и (или) стоимость иного имущества, поступивших в счет погашения задолженности по неустойке (штрафу, пене) по договорам микрозайма за отчетный период, тысяч рублей, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'сумма по ДЕБЕТУ счетов 47422 и 612 из отчета по счету 60323 "Дистанс", Убрать Цессию, Госпошлину, минус ДТ60323 КТ61217'
,77
from (

SELECT 
--[KT] = Kt.Код
--,[DT] = Dt.Код
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
left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces2 on a.СубконтоCt3_Ссылка=ces2.Ссылка

left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT2 on spKT.СпособПодачиЗаявления=sposobKT2.Ссылка
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)

and (
    (Kt.Код in ('60323') and (Dt.Код ='47422' or substring(Dt.Код,1,3)='612') and a.СубконтоCt3_Ссылка=0x00000000000000000000000000000000)
    or
    (Dt.Код in ('60323') and substring(kt.Код,1,3)='612')
    )

) l1

where l1.[Способ выдачи займа КТ]='Дистанционный'--'Дистанционный' --'Онлайн'

union all

--2.9.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.9.1'
,[Показатель] = '    сумма денежных средств'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'сумма по ДЕБЕТУ счетов  47422 и 61217 из отчета по счету 60323 "Дистанс", Убрать Цессию, Госпошлину минус ДТ60323 КТ61217'
,78
from (

SELECT 
--[KT] = Kt.Код
--,[DT] = Dt.Код
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
left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces2 on a.СубконтоCt3_Ссылка=ces2.Ссылка

left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT2 on spKT.СпособПодачиЗаявления=sposobKT2.Ссылка
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)

and (
    (Kt.Код in ('60323') and Dt.Код  in ('47422','61217') and a.СубконтоCt3_Ссылка=0x00000000000000000000000000000000)
    or
    (Dt.Код in ('60323') and substring(kt.Код,1,3)='612')
    )

) l1

where l1.[Способ выдачи займа КТ]='Дистанционный'--'Дистанционный' --'Онлайн'

union all

--2.10
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.10'
,[Показатель] = 'Сумма задолженности по договорам микрозайма, списанной c баланса микрофинансовой компании за отчетный период, тысяч рублей, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'сумма по ДЕБЕТУ счетов 48810 и 71802 из отчета по счетам 48801, 49401 и 48701, + сумма по ДЕБЕТУ счетов 48810 и 71802 из отчета по счетам 48802, 49402, + сумма по ДЕБЕТУ счету 60324 из отчета по счету 60323 "Дистанс" Убрать Госпошлину'
,79
from (

SELECT 
[Сумма БУ] = case when upper(ces.Представление) like upper('%передача прав требований%') then 0 --Убирается Цессия
                  else a.Сумма 
                  end
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
left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка

left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKTp on a.СубконтоCt2_Ссылка=spKTp.ДоговорКонтрагента and spktp.ДополнительноеСоглашение=0x00
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKTp on spKTp.СпособПодачиЗаявления=sposobKTp.Ссылка
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)

and (
     (Kt.Код in ('48801','49401','48701') and Dt.Код in ('48810','71802','49410','48710')) 
     or
     (Kt.Код in ('48802','49402','48702') and Dt.Код in ('48810','71802','49410','48710')) 
     or
     (Kt.Код ='60323' and Dt.Код ='60324' and a.СубконтоCt3_Ссылка=0x00000000000000000000000000000000) 
     )
) l1

where l1.[Способ выдачи займа КТ]='Дистанционный'--'Дистанционный' --'Онлайн'

union all

--2.10.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.10.1'
,[Показатель] = '    по основному долгу'
,[Значение] = ROUND(cast(isnull(sum(l1.[Сумма БУ]),0) as money),3)
,[Примечание] = 'сумма по ДЕБЕТУ счетов 48810 и 71802 из отчета по счетам 48801, 49401 и 48701, "Дистанс"'
,80
from (

SELECT 
[Сумма БУ] = case when upper(ces.Представление) like upper('%передача прав требований%') then 0 --Убирается Цессия
                  else a.Сумма 
                  end
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
left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка

left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKTp on a.СубконтоCt2_Ссылка=spKTp.ДоговорКонтрагента and spktp.ДополнительноеСоглашение=0x00
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKTp on spKTp.СпособПодачиЗаявления=sposobKTp.Ссылка
where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)

and (
     (Kt.Код in ('48801','49401','48701') and Dt.Код in ('48810','71802','49410','48710')) 
     )
) l1

where l1.[Способ выдачи займа КТ]='Дистанционный'--'Дистанционный' --'Онлайн'
    

  --select @@ROWCOUNT

	end try

	BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
       ,ERROR_MESSAGE() AS ErrorMessage;  
	END CATCH  

END
