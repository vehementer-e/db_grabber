

CREATE PROCEDURE [finAnalytics].[calcRep840FirstLevel_21]
	@repmonth date,
    @repdate date
    --,    @sumRang int
AS
BEGIN

BEGIN TRY

drop table if exists #ID_LIST
Create table #ID_LIST(
[ID] [int] NOT NULL)

INSERT INTO #ID_LIST
select id
from finAnalytics.PBR_MONTHLY a
where a.REPMONTH=@repmonth
--and a.REPDATE=@repdate

drop table if exists #pbr
select
a.*
into #pbr
from finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on a.ID=b.ID

drop table if exists #rep
create table #rep(
	[Отчетный месяц] date not null,
	[Дата расчета]  date not null,
	[Раздел] nvarchar(20) null,
	[Пункт]	nvarchar(20) null,
	[Показатель] nvarchar(255) null,	
	[Значение] float null,
	[Примечание] nvarchar(max) null,
	[rowNum] int not null
)

insert into #rep


--2.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.1.1'
,[Показатель] = '    индивидуальным предпринимателям, в том числе:'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ИП; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; Счета учета = 494; Сумма по полю "Задолженность ОД"'
,2
from #pbr a


where 1=1
and upper(a.isZaemshik)=upper('ИП') 
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')

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
from #pbr a

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.1.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.1.2'
,[Показатель] = '    юридическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный;Счет учета = 487. Сумма по полю "Задолженность ОД"'
,4
from #pbr a

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.1.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.1.2.1'
,[Показатель] = '        являющимся субъектами малого и среднего предпринимательства'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0) as money),3)
,[Примечание] = 'к 2.1.2 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,5
from #pbr a

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.1.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.1.3'
,[Показатель] = '    физическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; Счет учета = 488 Сумма по полю "Задолженность ОД"'
,6
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; Счет учета = 488; Займ выдан на сумму меньше или равен 30 т.р. и меньше или равен 30 дней; Сумма по полю "Задолженность ОД"'
,8
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
--and UPPER(a.finProd) = UPPER('PDL') --v1
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30) --v2
and upper(a.[saleType])=upper('Дистанционный')
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
,[Значение] = ROUND(cast(isnull(sum([zadolgOD]),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; "Номенклатурная группа" = %займ для Самозанятых%, Installment до 1 млн. Рыночный. Самозанятый; Счет учета = 488; Сумма по полю "Задолженность ОД"'
,11
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
--and upper(a.nomenkGroup) like upper('%займ для Самозанятых%')
and upper(a.nomenkGroup) like upper('%Самозанят%')
and upper(a.[saleType])=upper('Дистанционный')/*Дистанционный*/
and substring(a.AccODNum,1,3) = '488'
and a.saleDate<=EOMONTH(a.REPMONTH)


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
,[Примечание] = 'Берем строки где "Признак заемщика" = ИП; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; Счет учета = 494; Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,14
from #pbr a

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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
,[Примечание] = 'к 2.2.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,15
from #pbr a

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; Счет учета = 487; Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,16
from #pbr a

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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
,[Примечание] = 'к 2.2.2 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,17
from #pbr a

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; Счет учета = 488; Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,18
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние"= действует; "Способ выдачи займа"=Дистанционный; Счет учета = 488; Займ выдан на сумму меньше или равен 30 т.р. и меньше или равен 30 дней; Сумма по полю "Задолженность ОД"'
,20
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
--and UPPER(a.finProd) = UPPER('PDL')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Дистанционный')
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
,[Значение] = ROUND(cast(isnull(sum(zadolgPrc),0) as money) 
					+
					cast(isnull(sum(penyaSum),0) as money)
					,3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; "Состояние" = действует; "Способ выдачи займа" = Дистанционный; "Номенклатурная группа" = %займ для Самозанятых%, Installment до 1 млн. Рыночный. Самозанятый; Счет учета = 488; Сумма по полю "Задолженность проценты" и полю "Сумма пени счета"'
,23
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
--and upper(a.nomenkGroup) like upper('%займ для Самозанятых%')
and upper(a.nomenkGroup) like upper('%Самозанят%')
and upper(a.[saleType])=upper('Дистанционный')/*Дистанционный*/
and substring(a.AccODNum,1,3) = '488'
and a.saleDate<=EOMONTH(a.REPMONTH)


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
,[Примечание] = 'Схема действует после 01.07.2024 года Берем строки где "Состояние"= действует; "Способ выдачи займа"=Дистанционный; Счет учета = 494. "Признак заемщика" = ИП; Дата выдачи займа не может быть больше отчетного периода; считаем договора, у одного заещика может быть несколько договоров'
,26
from #pbr a

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.3.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.3.1.1'
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
,[Примечание] = 'к 2.3.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,27
from #pbr a

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.3.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.3.2'
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
,[Примечание] = 'Схема действует после 01.07.2024 года Берем строки где "Состояние"= действует; "Способ выдачи займа"=Дистанционный; Счет учета = 487.  "Признак заемщика" = ЮЛ;Дата выдачи займа не может быть больше отчетного периода; считаем договора, у одного заещика может быть несколько договоров'
,28
from #pbr a

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.3.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.3.2.1'
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
,[Примечание] = 'к 2.3.2 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,29
from #pbr a

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.3.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.3.3'
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
,[Примечание] = 'Схема действует после 01.07.2024 года; Берем строки где "Состояние"= действует; "Способ выдачи займа"=Дистанционный; Счет учета = 488.  "Признак заемщика" = ФЛ; Дата выдачи займа не может быть больше отчетного периода; считаем договора, у одного заещика может быть несколько договоров'
,30
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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
,[Примечание] = 'Схема действует после 01.07.2024 года; Берем строки где "Состояние Договора"= действует; "Способ выдачи займа"=Дистанционный; "Сумма займа" меньше или равна 30 000; "Срок договора в днях" меньше или равен 30; "Признак заемщика" = ФЛ; Счет учета =488; Считаем договора, у одного заемщика может быть несколько договоров.Дата выдачи займа не может быть больше отчетного периода;'
,32
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Дистанционный')
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
,[Показатель] = '        физическим лицам, применяющим специальный налоговый режим «Налог на профессиональный доход» и не являющимся индивидуальными предпринимателями, в том числе:'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Схема действует после 01.07.2024 года; Берем строки где "Состояние" = действует; "Способ выдачи займа" = Дистанционный; "Признак заемщика" = ФЛ; "Номенклатурная группа" = %займ для Самозанятых%, Installment до 1 млн. Рыночный. Самозанятый; Счет учета = 488.   Дата выдачи займа не может быть больше отчетного периода; считаем договора, у одного заещика может быть несколько договоров'
,35
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
--and upper(a.nomenkGroup) like upper('%займ для Самозанятых%')
and upper(a.nomenkGroup) like upper('%Самозанят%')
and upper(a.[saleType])=upper('Дистанционный')/*Дистанционный*/
and substring(a.AccODNum,1,3) = '488'
and a.saleDate<=EOMONTH(a.REPMONTH)


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
,[Примечание] = 'Берем строки где "Состояние"= действует; "Способ выдачи займа"=Дистанционный;Счет учета = 494. Признак заемщика = ИП; Считаем контрагентов, они не должны повторятся, лучше сверять по полю "Контрагент код". Дата выдачи займа (действующего договора) не может быть больше отчетного периода;'
,38
from #pbr a

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.4.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.4.1.1'
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
,[Примечание] = 'к 2.4.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,39
from #pbr a

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.4.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.4.2'
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
,[Примечание] = 'Берем строки где "Состояние"= действует; "Способ выдачи займа"=Дистанционный;Счет учета = 487. Признак заемщика = ЮЛ; Считаем контрагентов, они не должны повторятся, лучше сверять ИНН. Дата выдачи займа(действующего договора) не может быть больше отчетного периода;'
,40
from #pbr a

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.4.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.4.2.1'
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
,[Примечание] = 'к 2.4.2 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,41
from #pbr a

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.4.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.4.3'
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
,[Примечание] = 'Берем строки где "Состояние"= действует; "Способ выдачи займа"=Дистанционный;Счет учета = 488. Признак заемщика = ФЛ; Считаем контрагентов, они не должны повторятся. Дата выдачи займа(действующего договора) не может быть больше отчетного периода;'
,42
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and upper(a.[saleType])=upper('Дистанционный')
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
,[Примечание] = 'Берем строки где "Состояние"= действует; "Способ выдачи займа"=Дистанционный; "Сумма займа" меньше или равна 30 000; "Срок договора в днях" меньше или равен 30; Счет учета =488;  "Признак заемщика" = ФЛ; Дата выдачи займа(действующего договора) не может быть больше отчетного периода; Считаем контрагентов, они не должны повторятся, лучше сверять ИНН.'
,44
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Дистанционный')
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
,[Показатель] = '        физическим лицам, применяющим специальный налоговый режим «Налог на профессиональный доход» и не являющимся индивидуальными предпринимателями, в том числе:'
,[Значение] = isnull(count(distinct a.ClientID),0)
,[Примечание] = 'Берем строки где "Состояние" = действует; "Способ выдачи займа" = Дистанционный; Счет учета = 488. Признак заемщика = ФЛ; "Номенклатурная группа" = %займ для Самозанятых%, Installment до 1 млн. Рыночный. Самозанятый; Считаем контрагентов, они не должны повторятся. Дата выдачи займа(действующего договора) не может быть больше отчетного периода;'
,47
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)=upper('Действует')
--and upper(a.nomenkGroup) like upper('%займ для Самозанятых%')
and upper(a.nomenkGroup) like upper('%Самозанят%')
and upper(a.[saleType])=upper('Дистанционный')/*Дистанционный*/
and substring(a.AccODNum,1,3) = '488'
and a.saleDate<=EOMONTH(a.REPMONTH)


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
,[Примечание] = 'Берем строки где "Признак заемщика" = ИП; Счет учета = 494; "Способ выдачи займа"=Дистанционный; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Считаем количество договоров, у одного заемщика может быть больше одного договора. '
,50
from #pbr a

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.5.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.5.1.1'
,[Показатель] = '        являющимися субъектами малого и среднего предпринимательства'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'к 2.5.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,51
from #pbr a

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.5.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.5.2'
,[Показатель] = '    юридическими лицами, в том числе:'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; Счет учета = 487; "Способ выдачи займа"=Дистанционный; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Считаем количество договоров, у одного заемщика может быть больше одного договора. '
,52
from #pbr a

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.5.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.5.2.1'
,[Показатель] = '        являющимися субъектами малого и среднего предпринимательства'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'к 2.5.2 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,53
from #pbr a

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.5.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.5.3'
,[Показатель] = '    физическими лицами, в том числе:'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; Счет учета = 488; "Способ выдачи займа"=Дистанционный; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Считаем количество договоров, у одного заемщика может быть больше одного договора. '
,54
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
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
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; Счет учета = 488; "Способ выдачи займа"=Дистанционный; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Сумма займа меньше или равна 30 000 р, срок договора в днях меньше или равен 30. Считаем количество договоров, у одного заемщика может быть больше одного договора. '
,56
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)!=upper('Отменен')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Дистанционный')
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
,[Показатель] = '        физическим лицам, применяющим специальный налоговый режим «Налог на профессиональный доход» и не являющимся индивидуальными предпринимателями, в том числе:'
,[Значение] = isnull(count(distinct a.dogNum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; Счет учета = 488; "Способ выдачи займа"=Дистанционный; " Дата выдачи = текущему отчетному периоду; "Номенклатурная группа" = %займ для Самозанятых%, Installment до 1 млн. Рыночный. Самозанятый; "Состояние" не равно "Отменен"; Считаем количество договоров, у одного заемщика может быть больше одного договора. '
,59
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus) != upper('Отменен')
--and upper(a.nomenkGroup) like upper('%займ для Самозанятых%')
and upper(a.nomenkGroup) like upper('%Самозанят%')
and upper(a.[saleType])=upper('Дистанционный')/*Дистанционный*/
and substring(a.AccODNum,1,3) = '488'
and a.saleDate between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(a.REPMONTH)


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
,[Примечание] = 'Берем строки где "Признак заемщика" = ИП; Счет учета = 494; "Способ выдачи займа"=Дистанционный; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Сумма по полю "Сумма займа"'
,62
from #pbr a

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.6.1.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.6.1.1'
,[Показатель] = '        являющимся субъектами малого и среднего предпринимательства'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0) as money),3)
,[Примечание] = 'к 2.6.1 добавляем отбор по реестру МСП: ИП на момент выдачи микрозайма было включено в реестр МСП'
,63
from #pbr a

where upper(a.isZaemshik)=upper('ИП')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.6.2
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.6.2'
,[Показатель] = '    юридическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ЮЛ; Счет учета = 487; "Способ выдачи займа"=Дистанционный; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Сумма по полю "Сумма займа"'
,64
from #pbr a

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.6.2.1
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.6.2.1'
,[Показатель] = '        являющимся субъектами малого и среднего предпринимательства'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0) as money),3)
,[Примечание] = 'к 2.6.2 добавляем отбор по реестру МСП: ЮЛ на момент выдачи микрозайма было включено в реестр МСП'
,65
from #pbr a

where upper(a.isZaemshik)=upper('ЮЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
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

--2.6.3
select
[Отчетный месяц] = @repmonth
,[Дата расчета] = @repdate
,[Раздел] = '2.1'
,[Пункт] = '2.6.3'
,[Показатель] = '    физическим лицам, в том числе:'
,[Значение] = ROUND(cast(isnull(sum(a.dogSum),0) as money),3)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; Счет учета = 488; "Способ выдачи займа"=Дистанционный; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Сумма по полю "Сумма займа"'
,66
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)!=upper('Отменен')
and upper(a.[saleType])=upper('Дистанционный')
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
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; Счет учета = 488; "Способ выдачи займа"=Дистанционный; " Дата выдачи = текущему отчетному периоду; "Состояние" не равно "Отменен"; Сумма займа меньше или равна 30 000 р, срок договора в днях меньше или равен 30. Сумма по полю "Сумма займа"'
,68
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus)!=upper('Отменен')
and (a.dogSum <= 30000  and a.dogPeriodDays <= 30)
and upper(a.[saleType])=upper('Дистанционный')
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
,[Значение] = isnull(sum(a.dogSum),0)
,[Примечание] = 'Берем строки где "Признак заемщика" = ФЛ; Счет учета = 488; "Способ выдачи займа"=Дистанционный; " Дата выдачи" = текущему отчетному периоду; "Номенклатурная группа" =  %займ для Самозанятых%, Installment до 1 млн. Рыночный. Самозанятый; "Состояние" не равно "Отменен"; Сумма по полю "Сумма займа"'
,71    
from #pbr a

where upper(a.isZaemshik)=upper('ФЛ')
and upper(a.dogStatus) != upper('Отменен')
--and upper(a.nomenkGroup) like upper('%займ для Самозанятых%')
and upper(a.nomenkGroup) like upper('%Самозанят%')
and upper(a.[saleType])=upper('Дистанционный')/*Дистанционный*/
and substring(a.AccODNum,1,3) = '488'
and a.saleDate between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(a.REPMONTH)


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
,[Примечание] = 'Дт 612, 47422 Кт 48801, 49401,48701, признак : Дистанционный (с использованием средств телекоммуникаций);  Для проводок Дт 612 Кт 48801,49401, 48701  - Признак: Полное досрочное погашение, Частичное списание; Полное списание'
,73
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
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,DATEFROMPARTS(year(@repmonth),1,1)) and dateadd(year,2000,EOMONTH(@REPMONTH))
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
,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание с Января 2025
) 
)
)--v2
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
,[Примечание] = 'Дт 61217, 47422 Кт 48801, 49401,48701, признак : Дистанционный (с использованием средств телекоммуникаций);  Для проводок Дт 61217 Кт 48801,49401, 48701  - Признак: Полное досрочное погашение'
,74
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
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,DATEFROMPARTS(year(@repmonth),1,1)) and dateadd(year,2000,EOMONTH(@REPMONTH))
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
/*Убрал по https://tracker.yandex.ru/FINA-190*/
--or --с Января 2025
--(Kt.Код in ('48801','48701','49401') and Dt.Код ='61215'
--and a.СубконтоDt3_Ссылка in (
--0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
--							) 
--)
)--v2
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
,[Примечание] = 'Дт 48809, 49409, 48709 612 Кт 48802, 49402, 48702, признак : Дистанционный (с использованием средств телекоммуникаций);  Для проводок Дт 612 Кт 48802,49402, 48702  - Признак: Полное досрочное погашение, Частичное списание;Полное списание'
,75
from (
SELECT 
/*
[Сумма БУ] = case when upper(ces.Представление) like upper('%передача прав требований%') then 0 --Убирается Цессия 
                  else a.Сумма 
                  end
*/ --v1
[Сумма БУ] = case when Kt.Код = '61215' and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) then a.Сумма*-1 else  a.Сумма end --v3
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
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,DATEFROMPARTS(year(@repmonth),1,1)) and dateadd(year,2000,EOMONTH(@REPMONTH))
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
								,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание https://tracker.yandex.ru/FINA-150
                                )
    )
	or
	
    (Dt.Код in ('48802','48702','49402') and Kt.Код = '61215'
    and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
                                )
    )
    )
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
,[Примечание] = 'Дт 48809, 49409, 48709  Кт 48802, 49402, 48702, признак : Дистанционный (с использованием средств телекоммуникаций);'
,76
from (
SELECT 
/*
[Сумма БУ] = case when upper(ces.Представление) like upper('%передача прав требований%') then 0 --Убирается Цессия 
                  else a.Сумма 
                  end
*/ --v1
[Сумма БУ] = case when Kt.Код = '61215' and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) then a.Сумма*-1 else  a.Сумма end --v3
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
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,DATEFROMPARTS(year(@repmonth),1,1)) and dateadd(year,2000,EOMONTH(@REPMONTH))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
--and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','49409')) --v1
and 
((Kt.Код in ('48802','48702','49402') and Dt.Код in ('48809','49409','48709')) 
or
(Dt.Код in ('48802','48702','49402') and Kt.Код = '61215'
    and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) --Полное списание
    ))--v3
    
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
,[Примечание] = 'Дт 47422 612  Кт 60323, признак : Дистанционный (с использованием средств телекоммуникаций);  Для проводок Дт 612 Кт 6023  - Признак: Полное досрочное погашение, Частичное списание, Полное списание; ВидыПлатежейПоЗаймам - не равен госпошлины, проценты, мошенники'
,77
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
[Сумма БУ] = case when Dt.Код = '60323' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 then a.Сумма * -1 else a.Сумма end --v3
,[Способ выдачи займа КТ] = 
    case when isnull(sposobKTp.Имя,sposobkT2.Имя) = 'Дистанционный' then 'Онлайн'
         when isnull(sposobKTp.Имя,sposobkT2.Имя) = 'Посреднический' then 'Дистанционный'
         when isnull(sposobKTp.Имя,sposobkT2.Имя) = 'Прямой' then 'Дистанционный'
         end
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
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,DATEFROMPARTS(year(@repmonth),1,1)) and dateadd(year,2000,EOMONTH(@REPMONTH))
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
    (Kt.Код in ('60323') and Dt.Код ='47422' and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
    or
    (Kt.Код in ('60323') and substring(Dt.Код,1,3) ='612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
								,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
                                )
	and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
	or
	(Dt.Код = '60323' and Kt.Код = '47422' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 --Пени)
	) --v3
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
,[Примечание] = 'Дт 47422 61217 Кт 60323, признак : Дистанционный (с использованием средств телекоммуникаций);  Для проводок Дт 612 Кт 6023  - Признак: Полное досрочное погашение; ВидыПлатежейПоЗаймам - не равен госпошлины, проценты, мошенники'
,78
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
[Сумма БУ] = case when Dt.Код = '60323' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 then a.Сумма * -1 else a.Сумма end --v3
,[Способ выдачи займа КТ] = 
    case when isnull(sposobKTp.Имя,sposobkT2.Имя) = 'Дистанционный' then 'Онлайн'
         when isnull(sposobKTp.Имя,sposobkT2.Имя) = 'Посреднический' then 'Дистанционный'
         when isnull(sposobKTp.Имя,sposobkT2.Имя) = 'Прямой' then 'Дистанционный'
         end
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
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,DATEFROMPARTS(year(@repmonth),1,1)) and dateadd(year,2000,EOMONTH(@REPMONTH))
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
    (Kt.Код in ('60323') and Dt.Код ='47422' and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
    or
    (Kt.Код in ('60323') and substring(Dt.Код,1,5) ='61217'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
                                )
	and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
	or
	(Dt.Код = '60323' and Kt.Код = '47422' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 --Пени)
	) --v3
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
,[Примечание] = 'сумма по ДЕБЕТУ счетов 49410, 48710, 48810 и 71802 из отчета по счетам 48801, 49401 и 48701, 
+ сумма по ДЕБЕТУ счетов 49410, 48710,48810 и 71802 из отчета по счетам 48802, 49402, 48702 
+ сумма по ДЕБЕТУ счету 60324 из отчета по счету 60323 "Дистанс" ВидыПлатежейПоЗаймам - не равен госпошлины, проценты, мошенники'
,79
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
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,DATEFROMPARTS(year(@repmonth),1,1)) and dateadd(year,2000,EOMONTH(@REPMONTH))
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
     (Kt.Код in ('48801','49401','48701') and Dt.Код in ('48810','71802','49410','48710','47423')) 
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
		--a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 --Пени
     ) 
     or (Dt.Код = '60323' and Kt.Код = '48801'
	 and a.СубконтоDt3_Ссылка in
			(0xA3040050568397CF11EF3A45E64722DE --Проценты КК СВО
			,0xA3040050568397CF11EF543103C0F623 --Мошенники
			)
		)
	 or (Dt.Код = '60323' and Kt.Код = '48802'
	 and a.СубконтоDt3_Ссылка in
			(0xA3040050568397CF11EF3A45E64722DE --Проценты КК СВО
			,0xA3040050568397CF11EF543103C0F623 --Мошенники
			)
		) --v3
	 ) --v2
	 

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
,[Примечание] = 'сумма по ДЕБЕТУ счетов 49410, 48710, 48810 и 71802 из отчета по счетам 48801, 49401 и 48701, 
 "Дистанс" ВидыПлатежейПоЗаймам - не равен госпошлины, проценты, мошенники'
,80
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
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,DATEFROMPARTS(year(@repmonth),1,1)) and dateadd(year,2000,EOMONTH(@REPMONTH))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)

and (
     (Kt.Код in ('48801','49401','48701') and Dt.Код in ('48810','71802','49410','48710','47423')) 
     or (Dt.Код = '60323' and Kt.Код = '48801'
	 and a.СубконтоDt3_Ссылка in
			(0xA3040050568397CF11EF3A45E64722DE --Проценты КК СВО
			,0xA3040050568397CF11EF543103C0F623 --Мошенники
			)
		)
	 )
	 
) l1

where l1.[Способ выдачи займа КТ]='Дистанционный'--'Дистанционный' --'Онлайн'


delete from finAnalytics.rep840_firstLevel
where REPMONTH=@repmonth and REPDATE=@repdate and razdel='2.1'

insert into finAnalytics.rep840_firstLevel
(REPMONTH, REPDATE, razdel, punkt, pokazatel, value, comment, rownum)
---Заполняем нижний уровень

select * from #rep

   

  --select @@ROWCOUNT

	end try

	BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
       ,ERROR_MESSAGE() AS ErrorMessage;  
	END CATCH  

END
