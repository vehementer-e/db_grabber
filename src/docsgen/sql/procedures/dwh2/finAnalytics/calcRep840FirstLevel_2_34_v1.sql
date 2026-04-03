
CREATE PROCEDURE [finAnalytics].[calcRep840FirstLevel_2_34_v1]
	@repmonth date

AS
BEGIN

delete from finAnalytics.rep840_2_34 where REPMONTH = @repmonth

declare @dateFrom datetime = cast(DATEADD(year,2000,DatefromParts(year(@repmonth),1,1)) as datetime)
declare @dateToTMP datetime = dateadd(DAY,1,cast(DATEADD(year,2000,eomonth(@repmonth)) as datetime))
declare @dateTo datetime = dateadd(SECOND,-1,@dateToTMP)


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.21
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.3'
,[Пункт] = '2.21'
,[Показатель] = 'Сумма задолженности на конец отчетного периода по основному долгу по договорам кредита (займа), заключенным с юридическими лицами, тысяч рублей, в том числе:'
,[Значение] = ROUND(cast(isnull(abs(sum(restOUT_BU)),0) as money),3)
,[Примечание] = 'остатки по счетам 43708,43808 округление до 3 знака после запятой (по модулю)'
,isSumm = 1
,rowNum = 1
from finAnalytics.OSV_MONTHLY a

where 1=1
and a.repMonth = @repmonth
and a.acc2order in ('43708','43808')



INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.21.1
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.3'
,[Пункт] = '2.21.1'
,[Показатель] = 'с кредитными организациями'
,[Значение] = ROUND(cast(isnull(abs(sum(restOUT_BU)),0) as money),3)
,[Примечание] = 'остатки по счетам 43708, 43808 округление до 3 знака после запятой, если Тип клиента в карточке контрагента по счету - "Кредитная организация" (по модулю)'
,isSumm = 1
,rowNum = 2
from finAnalytics.OSV_MONTHLY a
left join stg._1cUMFO.Справочник_Контрагенты c on a.subconto1UID=c.Ссылка
left join Stg._1cUMFO.Перечисление_АЭ_ВидыЮридическихЛиц cSP on c.АЭ_ВидКонтрагента=cSP.Ссылка

where 1=1
and a.repMonth = @repmonth
and a.acc2order in ('43708','43808')
and cSP.Имя='КредитнаяОрганизация'


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.22
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.3'
,[Пункт] = '2.22'
,[Показатель] = 'Сумма задолженности на конец отчетного периода по процентам по договорам кредита (займа), заключенным с юридическими лицами, тысяч рублей, в том числе:'
,[Значение] = ROUND(cast(isnull(abs(sum(restOUT_BU)),0) as money),3)
,[Примечание] = 'остатки по счетам 43709, 43809 округление до 3 знака после запятой (по модулю)'
,isSumm = 1
,rowNum = 3
from finAnalytics.OSV_MONTHLY a

where 1=1
and a.repMonth = @repmonth
and a.acc2order in ('43709','43809')


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.22.1
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.3'
,[Пункт] = '2.22.1'
,[Показатель] = 'с кредитными организациями'
,[Значение] = ROUND(cast(isnull(abs(sum(restOUT_BU)),0) as money),3)
,[Примечание] = 'остатки по счетам 43709, 43809 округление до 3 знака после запятой, если Тип клиента в карточке контрагента по счету - "Кредитная организация" (по модулю)'
,isSumm = 1
,rowNum = 4
from finAnalytics.OSV_MONTHLY a
left join stg._1cUMFO.Справочник_Контрагенты c on a.subconto1UID=c.Ссылка
left join Stg._1cUMFO.Перечисление_АЭ_ВидыЮридическихЛиц cSP on c.АЭ_ВидКонтрагента=cSP.Ссылка

where 1=1
and a.repMonth = @repmonth
and a.acc2order in ('43709','43809')
and cSP.Имя='КредитнаяОрганизация'



INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.23
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.3'
,[Пункт] = '2.23'
,[Показатель] = 'Сумма фактически уплаченных процентов за отчетный период по обязательствам перед юридическими лицами, тысяч рублей, в том числе:'
,[Значение] = ROUND(cast(isnull(abs(sum(Сумма)),0) as money),3)
,[Примечание] = 'Сумма оборотов по счетам Дт 43709, 43809, Кт 20501, 43708,43808 нарастающим итогом с начала календарного года (по модулю)'
,isSumm = 1
,rowNum = 5
from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0

where 1=1
and a.Период between @dateFrom and @dateTo
and Dt.Код in ('43709','43809')
and Kt.Код in ('20501','43708','43808')
and a.Активность=0x01


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.23.1
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.3'
,[Пункт] = '2.23.1'
,[Показатель] = 'по договорам, заключенным с кредитными организациями'
,[Значение] = ROUND(cast(isnull(abs(sum(Сумма)),0) as money),3)
,[Примечание] = 'Сумма оборотов по счетам Дт 43709, 43809, Кт 20501, 43708,43808 нарастающим итогом с начала календарного года Тип клиента в карточке контрагента по счету (43709, 43809) - "Кредитная организация" (по модулю)'
,isSumm = 1
,rowNum = 6
from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_Контрагенты c on a.СубконтоDt1_Ссылка=c.Ссылка
left join Stg._1cUMFO.Перечисление_АЭ_ВидыЮридическихЛиц cSP on c.АЭ_ВидКонтрагента=cSP.Ссылка

where 1=1
and a.Период between @dateFrom and @dateTo
and Dt.Код in ('43709','43809')
and Kt.Код in ('20501','43708','43808')
and a.Активность=0x01
and cSP.Имя='КредитнаяОрганизация'


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.24
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.3'
,[Пункт] = '2.24'
,[Показатель] = 'Количество юридических лиц, предоставивших микрофинансовой компании денежные средства по договорам кредита (займа) за отчетный период, единиц, в том числе:'
,[Значение] = ROUND(cast(isnull(COUNT(distinct c.Наименование),0) as money),3)
,[Примечание] = 'Дт 20501 Кт 43808, 43708  с начала года по отчетную дату. Связываем со справочником договоров, Определяем дату договора и признак первичности, Считаем только договора с датой в отчетном периоде и признаком "Первичный". Считаем уникальных клиентов'
,isSumm = 0
,rowNum = 7
from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_Контрагенты c on a.СубконтоCt1_Ссылка=c.Ссылка
left join Stg._1cUMFO.Перечисление_АЭ_ВидыЮридическихЛиц cSP on c.АЭ_ВидКонтрагента=cSP.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0

where 1=1
and a.Период between @dateFrom and @dateTo
and Kt.Код in ('43808','43708')
and Dt.Код in ('20501')
and a.Активность=0x01
and crkt.Дата between @dateFrom and @dateTo
--and crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
and (crkt.Ссылка is not null
	 and 
		(crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
		 or
		 crkt.СЗД_ОсновнойЗайм_Ссылка is null
		)
	)
--and cSP.Имя='КредитнаяОрганизация'


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.24.1
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.3'
,[Пункт] = '2.24.1'
,[Показатель] = 'кредитных организаций, предоставивших кредиты (займы)'
,[Значение] = ROUND(cast(isnull(COUNT(distinct c.Наименование),0) as money),3)
,[Примечание] = 'Дт 20501 Кт 43808, 43708 с начала года по отчетную дату. Связываем со справочником договоров, Определяем дату договора и признак первичности, Считаем только договора с датой в отчетном периоде и признаком "Первичный". Считаем уникальных клиентов Тип клиента в карточке контрагента по счету - "Кредитная организация" (по модулю)'
,isSumm = 0
,rowNum = 8
from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_Контрагенты c on a.СубконтоCt1_Ссылка=c.Ссылка
left join Stg._1cUMFO.Перечисление_АЭ_ВидыЮридическихЛиц cSP on c.АЭ_ВидКонтрагента=cSP.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0

where 1=1
and a.Период between @dateFrom and @dateTo
and Kt.Код in ('43808','43708')
and Dt.Код in ('20501')
and a.Активность=0x01
and crkt.Дата between @dateFrom and @dateTo
--and crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
and (crkt.Ссылка is not null
	 and 
		(crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
		 or
		 crkt.СЗД_ОсновнойЗайм_Ссылка is null
		)
	)
and cSP.Имя='КредитнаяОрганизация'


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.25
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.3'
,[Пункт] = '2.25'
,[Показатель] = 'Сумма денежных средств, предоставленных микрофинансовой компании юридическими лицами по договорам кредита (займа) за отчетный период, тысяч рублей, в том числе:'
,[Значение] = ROUND(cast(isnull(SUM(a.Сумма),0) as money),3)
,[Примечание] = 'Дт 20501 Кт 43808, 43708 Считаем сумма денежных средств '
,isSumm = 1
,rowNum = 9
from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_Контрагенты c on a.СубконтоCt1_Ссылка=c.Ссылка
left join Stg._1cUMFO.Перечисление_АЭ_ВидыЮридическихЛиц cSP on c.АЭ_ВидКонтрагента=cSP.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0

where 1=1
and a.Период between @dateFrom and @dateTo
and Kt.Код in ('43808','43708')
and Dt.Код in ('20501')
and a.Активность=0x01
and crkt.Дата between @dateFrom and @dateTo
--and crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
and (crkt.Ссылка is not null
	 /*
	 and 
		(crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
		 or
		 crkt.СЗД_ОсновнойЗайм_Ссылка is null
		)
	*/
	)
--and cSP.Имя='КредитнаяОрганизация'



INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.25.1
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.3'
,[Пункт] = '2.25.1'
,[Показатель] = 'предоставленных кредитными организациями'
,[Значение] = ROUND(cast(isnull(SUM(a.Сумма),0) as money),3)
,[Примечание] = 'Дт 20501 Кт 43808, 43708 Считаем сумма денежных средств Тип клиента в карточке контрагента по счету - "Кредитная организация" (по модулю)'
,isSumm = 1
,rowNum = 10
from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_Контрагенты c on a.СубконтоCt1_Ссылка=c.Ссылка
left join Stg._1cUMFO.Перечисление_АЭ_ВидыЮридическихЛиц cSP on c.АЭ_ВидКонтрагента=cSP.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0

where 1=1
and a.Период between @dateFrom and @dateTo
and Kt.Код in ('43808','43708')
and Dt.Код in ('20501')
and a.Активность=0x01
and crkt.Дата between @dateFrom and @dateTo
--and crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
and (crkt.Ссылка is not null
	 /*
	 and 
		(crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
		 or
		 crkt.СЗД_ОсновнойЗайм_Ссылка is null
		)
	*/
	)
and cSP.Имя='КредитнаяОрганизация'


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.26
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.4'
,[Пункт] = '2.26'
,[Показатель] = 'Сумма задолженности на конец отчетного периода по основному долгу по договорам займа, заключенным с физическими лицами, в том числе индивидуальными предпринимателями, тысяч рублей, в том числе:'
,[Значение] = ROUND(cast(isnull(abs(sum(restOUT_BU)),0) as money),3)
,[Примечание] = 'остатки по счету 42316 округление до 3 знака после запятой (по модулю)'
,isSumm = 1
,rowNum = 1
from finAnalytics.OSV_MONTHLY a

where 1=1
and a.repMonth = @repmonth
and a.acc2order in ('42316')


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.26.1
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.4'
,[Пункт] = '2.26.1'
,[Показатель] = 'с физическими лицами, в том числе индивидуальными предпринимателями, не являющимися учредителями (членами, участниками, акционерами)'
,[Значение] = ROUND(cast(isnull(abs(sum(restOUT_BU)),0) as money),3)
,[Примечание] = 'остатки по счету 42316 округление до 3 знака после запятой (по модулю) если клиент по счету не входит в справочник "Связанные лица"'
,isSumm = 1
,rowNum = 2
from finAnalytics.OSV_MONTHLY a
left join stg._1cUMFO.Справочник_Контрагенты c on a.subconto1UID=c.Ссылка
left join finAnalytics.SPR_Affilage aff on c.Код=aff.affilName and aff.affilBeginDate <= @dateTo and isnull(aff.affilEndDate,@dateTo)>=@dateTo


where 1=1
and a.repMonth = @repmonth
and a.acc2order in ('42316')
and aff.client is null


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.27
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.4'
,[Пункт] = '2.27'
,[Показатель] = 'Сумма задолженности на конец отчетного периода по процентам по договорам займа, заключенным с физическими лицами, в том числе индивидуальными предпринимателями, тысяч рублей, в том числе:'
,[Значение] = ROUND(cast(isnull(abs(sum(restOUT_BU)),0) as money),3)
,[Примечание] = 'остатки по счету 42317 округление до 3 знака после запятой (по модулю)'
,isSumm = 1
,rowNum = 3
from finAnalytics.OSV_MONTHLY a
left join stg._1cUMFO.Справочник_Контрагенты c on a.subconto1UID=c.Ссылка
left join finAnalytics.SPR_Affilage aff on c.Код=aff.affilName and aff.affilBeginDate <= @dateTo and isnull(aff.affilEndDate,@dateTo)>=@dateTo


where 1=1
and a.repMonth = @repmonth
and a.acc2order in ('42317')
--and aff.client is null


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.27.1
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.4'
,[Пункт] = '2.27.1'
,[Показатель] = 'с физическими лицами, в том числе индивидуальными предпринимателями, не являющимися учредителями (членами, участниками, акционерами)'
,[Значение] = ROUND(cast(isnull(abs(sum(restOUT_BU)),0) as money),3)
,[Примечание] = 'остатки по счету 42317 округление до 3 знака после запятой (по модулю) если клиент по счету не входит в справочник "Связанные лица" Код клиента'
,isSumm = 1
,rowNum = 4
from finAnalytics.OSV_MONTHLY a
left join stg._1cUMFO.Справочник_Контрагенты c on a.subconto1UID=c.Ссылка
left join finAnalytics.SPR_Affilage aff on c.Код=aff.affilName and aff.affilBeginDate <= @dateTo and isnull(aff.affilEndDate,@dateTo)>=@dateTo


where 1=1
and a.repMonth = @repmonth
and a.acc2order in ('42317')
and aff.client is null



INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.28
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.4'
,[Пункт] = '2.28'
,[Показатель] = 'Сумма фактически уплаченных процентов за отчетный период по обязательствам перед физическими лицами (в том числе индивидуальными предпринимателями), тысяч рублей'
,[Значение] = ROUND(cast(isnull(abs(sum(case when kt.Код in ('42317') then a.Сумма*-1 else a.Сумма end)),0) as money),3)
,[Примечание] = 'Дт42317 Кт20501 минус Кт42317 Дт20501 + Дт42317 Кт42316 минус Кт42317 Дт42316 +  Дт42317 Кт60301 минус Кт42317 Дт60301'
,isSumm = 1
,rowNum = 5
from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
--left join stg._1cUMFO.Справочник_Контрагенты c on a.СубконтоCt1_Ссылка=c.Ссылка
--left join Stg._1cUMFO.Перечисление_АЭ_ВидыЮридическихЛиц cSP on c.АЭ_ВидКонтрагента=cSP.Ссылка
--left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0

where 1=1
and a.Период between @dateFrom and @dateTo
and 
(
	Dt.Код in ('42317') and kt.Код in ('20501')
	or
	Kt.Код in ('42317') and dt.Код in ('20501')
	or
	Dt.Код in ('42317') and kt.Код in ('42316')
	or
	Kt.Код in ('42317') and dt.Код in ('42316')
	or
	Dt.Код in ('42317') and kt.Код in ('60301')
	or
	Kt.Код in ('42317') and dt.Код in ('60301')
)
and a.Активность=0x01


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.29
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.4'
,[Пункт] = '2.29'
,[Показатель] = 'Количество действующих на конец отчетного периода договоров займа, заключенных с физическими лицами, в том числе индивидуальными предпринимателями, штук, в том числе:'
,[Значение] = (select
				isnull(COUNT(distinct subconto2),0)
				from(

				select
				subconto2
				,restAmount=SUM(restOUT_BU)
				--,crkt.*
				from finAnalytics.OSV_MONTHLY a
				left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.subconto2UID=crkt.Ссылка and crkt.ПометкаУдаления=0

				where 1=1
				and a.repMonth = @repmonth
				and a.acc2order in ('42316')
				--and crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
				and (crkt.Ссылка is not null
					 and 
						(crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
						 or
						 crkt.СЗД_ОсновнойЗайм_Ссылка is null
						)
					)

				group by subconto2
				) l1
				where l1.restAmount !=0
				)
,[Примечание] = 'ОСВ - кол-во уникальных договоров по счетам 42316 с остатком больше 0'
,isSumm = 0
,rowNum = 6



INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.29.1
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.4'
,[Пункт] = '2.29.1'
,[Показатель] = 'с физическими лицами, в том числе индивидуальными предпринимателями, не являющимися учредителями (членами, участниками, акционерами)'
,[Значение] = (select
				isnull(COUNT(distinct subconto2),0)
				from(

				select
				subconto2
				,restAmount=SUM(restOUT_BU)
				--,crkt.*
				from finAnalytics.OSV_MONTHLY a
				left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.subconto2UID=crkt.Ссылка and crkt.ПометкаУдаления=0
				left join stg._1cUMFO.Справочник_Контрагенты c on a.subconto1UID=c.Ссылка
				left join finAnalytics.SPR_Affilage aff on c.Код=aff.affilName and aff.affilBeginDate <= @dateTo and isnull(aff.affilEndDate,@dateTo)>=@dateTo

				where 1=1
				and a.repMonth = @repmonth
				and a.acc2order in ('42316')
				--and crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
				and (crkt.Ссылка is not null
					 and 
						(crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
						 or
						 crkt.СЗД_ОсновнойЗайм_Ссылка is null
						)
					)
				and aff.client is null

				group by subconto2
				) l1
				where l1.restAmount !=0
				)
,[Примечание] = 'ОСВ - кол-во уникальных договоров по счетам 42316 с остатком больше 0 если клиент по счету не входит в справочник "Связанные лица" Код клиента'
,isSumm = 0
,rowNum = 7



INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.30
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.4'
,[Пункт] = '2.30'
,[Показатель] = 'Количество договоров займа, заключенных с физическими лицами, в том числе индивидуальными предпринимателями, за отчетный период, штук, в том числе:'
,[Значение] = (select
				isnull(COUNT(distinct Номер),0)

				from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
				--left join stg._1cUMFO.Справочник_Контрагенты c on a.СубконтоCt1_Ссылка=c.Ссылка
				--left join Stg._1cUMFO.Перечисление_АЭ_ВидыЮридическихЛиц cSP on c.АЭ_ВидКонтрагента=cSP.Ссылка
				left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0

				where 1=1
				and a.Период between @dateFrom and @dateTo
				and 
				(
					Kt.Код in ('42316') and Dt.Код in ('20501','20202')
				)
				and a.Активность=0x01
				--and crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
				and (crkt.Ссылка is not null
					 and 
						(crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
						 or
						 crkt.СЗД_ОсновнойЗайм_Ссылка is null
						)
					)
				and crkt.Дата between @dateFrom and @dateTo
				)
,[Примечание] = 'Кт 42316  Дт 20501, 20202.Связываем с договорами, определяем признак "Первичный" Учитываем дату договора только за отчетный период и считаем количество договоров. '
,isSumm = 0
,rowNum = 8


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.30.1
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.4'
,[Пункт] = '2.30.1'
,[Показатель] = 'с физическими лицами, в том числе индивидуальными предпринимателями, не являющимися учредителями (членами, участниками, акционерами)'
,[Значение] = (select
				isnull(COUNT(distinct Номер),0)

				from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
				left join stg._1cUMFO.Справочник_Контрагенты c on a.СубконтоCt1_Ссылка=c.Ссылка
				left join finAnalytics.SPR_Affilage aff on c.Код=aff.affilName and aff.affilBeginDate <= @dateTo and isnull(aff.affilEndDate,@dateTo)>=@dateTo
				left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0

				where 1=1
				and a.Период between @dateFrom and @dateTo
				and 
				(
					Kt.Код in ('42316') and Dt.Код in ('20501','20202')
				)
				and a.Активность=0x01
				--and crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
				and (crkt.Ссылка is not null
					 and 
						(crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
						 or
						 crkt.СЗД_ОсновнойЗайм_Ссылка is null
						)
					)
				and crkt.Дата between @dateFrom and @dateTo
				and aff.client is null
				)
,[Примечание] = 'Кт 42316  Дт 20501, 20202.Связываем с договорами, определяем признак "Первичный" Учитываем дату договора только за отчетный период и считаем количество договоров. если клиент по счету не входит в справочник "Связанные лица" Код клиента'
,isSumm = 0
,rowNum = 9


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.31
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.4'
,[Пункт] = '2.31'
,[Показатель] = 'Количество физических лиц, в том числе индивидуальных предпринимателей, предоставивших микрофинансовой компании денежные средства по договорам займа за отчетный период, человек, в том числе:'
,[Значение] = (select
				isnull(COUNT(distinct c.Код),0)

				from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
				left join stg._1cUMFO.Справочник_Контрагенты c on a.СубконтоCt1_Ссылка=c.Ссылка
				--left join finAnalytics.SPR_Affilage aff on c.Код=aff.affilName and aff.affilBeginDate <= @dateTo and isnull(aff.affilEndDate,@dateTo)>=@dateTo
				left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0

				where 1=1
				and a.Период between @dateFrom and @dateTo
				and 
				(
					Kt.Код in ('42316') and Dt.Код in ('20501','20202')
				)
				and a.Активность=0x01
				--and crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
				and (crkt.Ссылка is not null
					 and 
						(crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
						 or
						 crkt.СЗД_ОсновнойЗайм_Ссылка is null
						)
					)
				and crkt.Дата between @dateFrom and @dateTo
				--and aff.client is null
				)
,[Примечание] = 'Кт 42316  Дт 20501, 20202.Связываем с договорами, определяем признак "Первичный" Учитываем дату договора только за отчетный период и считаем количество клиентов'
,isSumm = 0
,rowNum = 10


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.31.1
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.4'
,[Пункт] = '2.31.1'
,[Показатель] = 'физических лиц, в том числе индивидуальных предпринимателей, не являющихся учредителями (членами, участниками, акционерами)'
,[Значение] = (select
				isnull(COUNT(distinct c.Код),0)

				from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
				left join stg._1cUMFO.Справочник_Контрагенты c on a.СубконтоCt1_Ссылка=c.Ссылка
				left join finAnalytics.SPR_Affilage aff on c.Код=aff.affilName and aff.affilBeginDate <= @dateTo and isnull(aff.affilEndDate,@dateTo)>=@dateTo
				left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0

				where 1=1
				and a.Период between @dateFrom and @dateTo
				and 
				(
					Kt.Код in ('42316') and Dt.Код in ('20501','20202')
				)
				and a.Активность=0x01
				--and crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
				and (crkt.Ссылка is not null
					 and 
						(crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
						 or
						 crkt.СЗД_ОсновнойЗайм_Ссылка is null
						)
					)
				and crkt.Дата between @dateFrom and @dateTo
				and aff.client is null
				)
,[Примечание] = 'Кт 42316  Дт 20501, 20202.Связываем с договорами, определяем признак "Первичный" Учитываем дату договора только за отчетный период и считаем количество клиентов. если клиент по счету не входит в справочник "Связанные лица" Код клиента'
,isSumm = 0
,rowNum = 11


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.32
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.4'
,[Пункт] = '2.32'
,[Показатель] = 'Сумма денежных средств, предоставленных микрофинансовой компании физическими лицами, в том числе индивидуальными предпринимателями, по договорам займа за отчетный период, тысяч рублей, в том числе:'
,[Значение] = (select
				isnull(sum(a.Сумма),0)

				from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
				--left join stg._1cUMFO.Справочник_Контрагенты c on a.СубконтоCt1_Ссылка=c.Ссылка
				--left join finAnalytics.SPR_Affilage aff on c.Код=aff.affilName and aff.affilBeginDate <= @dateTo and isnull(aff.affilEndDate,@dateTo)>=@dateTo
				--left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0

				where 1=1
				and a.Период between @dateFrom and @dateTo
				and 
				(
					Kt.Код in ('42316') and Dt.Код in ('20501','20202','42317')
				)
				and a.Активность=0x01
				--and crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
				--and crkt.Дата between @dateFrom and @dateTo
				--and aff.client is null
				)
,[Примечание] = 'Кт 42316  Дт 20501, 20202, 42317. Посчитатьсумму таких оборотов'
,isSumm = 1
,rowNum = 12


INSERT INTO finAnalytics.rep840_2_34
(REPMONTH, razdel, punkt, pokazatel, value, comment, isSumm, rownum)
--2.32.1
select
[Отчетный месяц] = @repmonth
,[Раздел] = '2.4'
,[Пункт] = '2.32.1'
,[Показатель] = 'физическими лицами, в том числе индивидуальными предпринимателями, не являющимися учредителями (членами, участниками, акционерами)'
,[Значение] = (select
				isnull(sum(a.Сумма),0)

				from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
				left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
				left join stg._1cUMFO.Справочник_Контрагенты c on a.СубконтоCt1_Ссылка=c.Ссылка
				left join finAnalytics.SPR_Affilage aff on c.Код=aff.affilName and aff.affilBeginDate <= @dateTo and isnull(aff.affilEndDate,@dateTo)>=@dateTo
				--left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка and crkt.ПометкаУдаления=0

				where 1=1
				and a.Период between @dateFrom and @dateTo
				and 
				(
					Kt.Код in ('42316') and Dt.Код in ('20501','20202','42317')
				)
				and a.Активность=0x01
				--and crkt.СЗД_ОсновнойЗайм_Ссылка=0x00000000000000000000000000000000
				--and crkt.Дата between @dateFrom and @dateTo
				and aff.client is null
				)
,[Примечание] = 'Кт 42316  Дт 20501, 20202, 42317. Посчитатьсумму таких оборотов если клиент по счету не входит в справочник "Связанные лица" Код клиента'
,isSumm = 1
,rowNum = 13





END
