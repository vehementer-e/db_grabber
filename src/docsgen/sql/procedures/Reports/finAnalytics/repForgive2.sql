




CREATE PROCEDURE [finAnalytics].[repForgive2]
	@repmonth date
with recompile
AS
BEGIN

select
  l1.repMonth	
, l1.[Займ]	
, l1.[Заемщик]
, l1.[Паспорт серия]
, l1.[Паспорт номер]
, l1.[Паспорт дата выдачи]
, l1.[Паспорт кем выдан]
, l1.[Паспорт код подразделения]
, l1.[Адрес регистрации]
, l1.[Ссылка]
, l1.[Ссылка.Причина]
, l1.[Счет аналитического учета списания основного долга]
, l1.[Счет аналитического учета списания процентов]
, l1.[Счет учета расчетов с прочими дебиторами]
, l1.[Сумма начальный остаток]
, l1.[Проценты (Дт. 71001 - Кт. 48802)]
, l1.[Пени (Дт. 71701 - Кт. 60323)]
, l1.[Сумма задолженности]
, l1.[Основной долг (Дт. 71802 - Кт. 48801)]
, l1.[Проценты (Дт. 71802 - Кт. 48802)]
, l1.[Пени (Дт. 71802 - Кт. 60323)]
, l1.[Пени (по суду)]
, l1.[Штрафы]
, l1.[Сумма задолженности (штрафы, пени,прочие доходы)]
, l1.[Штрафы (по суду)]
, l1.[Прочие доходы]
, l1.[Прочие доходы (по суду)]
, l1.[Комиссии]
, l1.[Сумма погашено ОД]
, l1.[Сумма погашено проценты]
, l1.[Сумма погашено пени]
, l1.[Сумма погашено госпошлина]
, l1.[Сумма оборот платежи]
, l1.[Сумма восстанволено резервов]
, l1.[Сумма восстанволено резервов НУ]
, l1.[Номенклатурная группа]
, l1.[Номер договора]
, l1.[Дата акции]
--, bucket.REPMONTH
--,bucket.prosDaysTotal
--0 дней = "просрочка 0"; 1 день - "просрочка 1-90"; 91-360 дней = "просрочка 91-360"; больше/равно 361 день = "просрочка 360+")
,[Бакет просрочки] = case 
						when isnull(bucket.prosDaysTotal,0) = 0 then 'просрочка 0'
						when isnull(bucket.prosDaysTotal,0) between 1 and 90 then 'просрочка 1-90'
						when isnull(bucket.prosDaysTotal,0) between 91 and 360 then 'просрочка 91-360'
						when isnull(bucket.prosDaysTotal,0) >=361 then 'просрочка 360+'
					else '-' end
from (
select
repMonth = @repmonth
--,[Номер договора] = substring(zaim,CHARINDEX('№ ',zaim)+2,CHARINDEX(' от ',zaim)-8)
,[Займ] =  a.zaim
,[Заемщик] = a.client
,[Паспорт серия] =  a.passSeria
,[Паспорт номер] = a.passNum
,[Паспорт дата выдачи] = a.passDate
,[Паспорт кем выдан] = a.passIssuer
,[Паспорт код подразделения] = a.passCode
,[Адрес регистрации] = a.addressReg
,[Ссылка] = a.spisanieText
,[Ссылка.Причина] = case when upper(a.spisanieReason) = UPPER('Служебная записка') and upper(a.spisanieText) like upper('%Списание (прощение) займов%') then CONCAT(a.spisanieReason, ' («Прощаем займы»)') else a.spisanieReason end
,[Счет аналитического учета списания основного долга] = a.accOD
,[Счет аналитического учета списания процентов] = a.accPRC
,[Счет учета расчетов с прочими дебиторами] = a.accOther
,[Сумма начальный остаток] = a.sumRestBegin
,[Проценты (Дт. 71001 - Кт. 48802)] = a.sumSpisPRC
,[Пени (Дт. 71701 - Кт. 60323)] = a.sumSpisPenia
,[Сумма задолженности] = a.sumFogive
,[Основной долг (Дт. 71802 - Кт. 48801)] = a.sumFogiveOD
,[Проценты (Дт. 71802 - Кт. 48802)] = a.sumFogivePRC
,[Пени (Дт. 71802 - Кт. 60323)] = a.sumFogivePenia
,[Пени (по суду)] = a.sumFogivePeniaSUD
,[Штрафы] = a.sumFogiveShtraf
,[Сумма задолженности (штрафы, пени,прочие доходы)] = a.sumFogiveZadolg
,[Штрафы (по суду)] = a.sumFogiveShtrafSUD
,[Прочие доходы] = a.sumFogiveOther
,[Прочие доходы (по суду)] = a.sumFogiveOtherSUD
,[Комиссии] =  a.sumFogiveComiss
,[Сумма погашено ОД] = a.sumPogashOD
,[Сумма погашено проценты] = a.sumPogashPRC
,[Сумма погашено пени] = a.sumPogashPenia
,[Сумма погашено госпошлина] = a.sumPogashGP
,[Сумма оборот платежи] = a.sumOborot
,[Сумма восстанволено резервов] = a.sumReservBackBU
,[Сумма восстанволено резервов НУ] = a.sumReservBackNU
,[Номенклатурная группа] = /*case when upper(b.nomenkGroup) like upper('%основной%')
							or  upper(b.nomenkGroup) like upper('%ПТС31%')
							or  upper(b.nomenkGroup) like upper('%Рефинансирование%') then 'ПТС'
								when upper(b.nomenkGroup) like upper('%installment%') then 'IL'
								when upper(b.nomenkGroup) like upper('%PDL%') then 'PDL'
								when upper(b.nomenkGroup) like upper('%бизнес%займ%') then 'БЗ'
							else '-' end
							*/
							case 
					when dwh2.[finAnalytics].[nomenk2prod](b.nomenkGroup) = 'Бизнес-займ' then 'БЗ'
					when dwh2.[finAnalytics].[nomenk2prod](b.nomenkGroup) = 'Installment' then 'IL'
					when dwh2.[finAnalytics].[nomenk2prod](b.nomenkGroup) is null then '-'
			else dwh2.[finAnalytics].[nomenk2prod](b.nomenkGroup) end

, [Номер договора] = substring(a.zaim,CHARINDEX('№ ',a.zaim)+2,CHARINDEX(' от ',a.zaim)-8)
, [Дата акции] = convert(date,substring(a.spisanieText,CHARINDEX(' от ',a.spisanieText)+4,10),104)
--, dataLoadDate
from dwh2.finAnalytics.akcia_vzisk_MONTHLY a
left join dwh2.finAnalytics.PBR_MONTHLY b on b.REPMONTH=@repmonth and b.dogNum=substring(a.zaim,CHARINDEX('№ ',a.zaim)+2,CHARINDEX(' от ',a.zaim)-8)

where a.repMonth = @repmonth
) l1

left join (
select
dogNum
,repMonth
,prosDaysTotal
from dwh2.finAnalytics.PBR_MONTHLY
where repmonth = dateadd(month,-1,@repmonth)
) bucket on l1.[Номер договора] = bucket.dogNum 

--WHERE l1.[Номер договора] = '24070622201265'

  
END
