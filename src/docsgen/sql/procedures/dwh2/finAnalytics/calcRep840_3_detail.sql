CREATE PROCEDURE [finAnalytics].[calcRep840_3_detail]
	@repmonth date
AS
BEGIN

declare @sprCheck int

exec @sprCheck= finAnalytics.checkRep840SPR_razdel3 @repmonth 

if @sprCheck = 0 
begin

BEGIN TRY

		DROP TABLE IF EXISTS #OSV

		select
		a.acc2order
		, a.acc2orderName
		, a.accNum
		, a.accName
		, a.subconto1
		, a.subconto1UID
		, a.subconto2
		, a.subconto2UID
		, a.subconto3
		, a.subconto3UID
		, a.branch
		, a.nomenkGroup
		, a.restIN_BU
		, a.restIN_NU
		, a.sumDT_BU
		, a.sumDT_NU
		, a.sumKT_BU
		, a.sumKT_NU
		, a.restOUT_BU
		, a.restOUT_NU

		, cl.ИНН
		, sp1.Имя
		, cl.Код

		into #OSV

		from finAnalytics.OSV_MONTHLY a
		left join stg._1cUMFO.Справочник_Контрагенты cl on a.subconto1UID=cl.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		left join stg._1cUMFO.Перечисление_АЭ_ВидыЮридическихЛиц sp1 on cl.АЭ_ВидКонтрагента=sp1.Ссылка
		where a.repMonth = @repmonth


		DROP TABLE IF EXISTS #PBR

		select
		Client, isZaemshik, isBankrupt, isDosieBankrupt, isMSP, passport, birthday, addressPDN, addresFact, 
		addressReg, finProd, dogNum, dogDate, saleDate, saleType, isCessia, pogashenieDate, pogashenieDateDS, 
		KKEndDate, dogPeriodMonth, dogPeriodDays, dogSum, isDogPoruch, dogZalogNum, dogZalogDate, TsVin, dogVin, 
		isDocred, zalogSum, zalogSumRaspred, spravedSum, spravedSumRaspred, spravedSumProverObespech, PDNOnSaleDate, 
		monthIncom, primeSum, isRefinance, isRestruk, restrukNum, restrukDate, restrukDateEnd, restrukPeriod, 
		firsProsDate, zadolgOD, zadolgPrc, penyaSum, gosposhlSum, prosODSum, prosPRCSum, prosDays, prosHist, prosDaysTotal, 
		prosMax, reservODPRC, reservOD, reservPRCPrc, reservPRC, dogStatus, prosDaysNU, reservPrcODNU, reservPRCprcNU, 
		reservProchSumNU, reservBUODSum, reservBUpPrcSum, reservBUPenyaSum, DSType, stavaOnSaleDate, stavaOnRepDate, PSK, 
		PSKFirst, isObespechZaym, PDNOnRepDate, isPros, AccODNum, AccPrcNum, AccObespechNum, branch, branchAddress, ClientID, 
		INN, prosDaysLastYear, CloseDate, nomenkGroup, isAkcia, ODLastPayDate, ODLastPaySum, sum47422, Acc47422Num, isOutBalance, 
		LasPay47422Date, LasPay47422Sum, AccPenyaNum, LastProvDTDate, LastProvKTDate, trebPogashDate, zakritObazType, creditor, 
		creditorDogNum, IsMarked, ZalogInDate, ZalogOutDate, isZamoroz1, isZamoroz1Date, isZamoroz2, isZamoroz2Date, isStavkaChange, 
		isStavkaChangeDate, isCredKanik, isCredKanikDate, isCancelRestruk, isCancelRestrukDate, isProlong, isProlongDate, isResrukt, 
		isResruktDate, isResrukt2, isResrukt2Date, isRefinance2, isRefinance2Date, isSnigStavka, isSnigStavkaDate, isCredKanik2, 
		isCredKanik2Date, isCancleCredKanik, isCancleCredKanikDate, isProlongPDL, isProlongPDLDate, isMSPbyDogDate, isMSPbyRepDate, 
		dataLoadDate, PSK_prc

		into #PBR

		from finAnalytics.PBR_MONTHLY a
		where a.repmonth=@repmonth
		and upper(a.dogStatus) in (upper('Действует'),upper('Закрыт'))

		--select * from #PBR

		DROP TABLE IF EXISTS #ARENDA

		select
		client
		, dogNum
		, sum60804
		, sum60805
		, sum60806
		, sumOverflow
		, sum90days

		INTO #ARENDA

		from finAnalytics.SPR_Arenda
		where repMonth = @repmonth --добавить после актуализации справочников

		DROP TABLE IF EXISTS #TERMS

		select
		a.accNum
		, a.dogNum
		, a.prosBeginDate
		, a.dogStatus
		, a.prosAll
		, a.isBunkrupt
		, a.reservOD_BU
		, a.reservPRC_BU
		, b.reservPRC
		, a.reservStavka_BU
		, a.lastDatePlatGR1
		, a.lastDatePlatGR2
		, a.lastDatePlatGR3
		, a.lastDatePlatGR4
		, a.lastDatePlatGR5
		, a.lastDatePlatGR6
		, a.restOD_Acc
		, a.restPRC_Acc
		, a.returnOD_1
		, a.returnOD_30
		, a.returnOD_90
		, a.returnOD_360
		, a.returnOD_1800
		, a.returnOD_1801
		, a.returnOD_pros
		, a.returnPRC_1
		, a.returnPRC_30
		, a.returnPRC_90
		, a.returnPRC_360
		, a.returnPRC_1800
		, a.returnPRC_1801
		, a.returnPRC_pros
		, a.reservOD_BU_1
		, a.reservOD_BU_30
		, a.reservOD_BU_90
		, a.reservOD_BU_360
		, a.reservOD_BU_1800
		, a.reservOD_BU_1801
		, a.reservOD_BU_pros
		, a.reservPRC_BU_1
		, a.reservPRC_BU_30
		, a.reservPRC_BU_90
		, a.reservPRC_BU_360
		, a.reservPRC_BU_1800
		, a.reservPRC_BU_1801
		, a.reservPRC_BU_pros
		, a.isZamorozkaReserv
		, a.isZamorozkaReservDate
		, a.isZamorozka1
		, a.isZamorozka1Date
		, a.isKKEvac
		, a.isKKEvacDate
		, a.isKK
		, a.isKKDate
		, a.isKK377
		, a.isKK377Date
		, a.isKK377Cancel
		, a.isKK377CancelDate
		, minOD = case when restOD_Acc < returnOD_1+returnOD_30+returnOD_90  then restOD_Acc
						else returnOD_1+returnOD_30+returnOD_90 end
		, reservOD90 = case when restOD_Acc < returnOD_1+returnOD_30+returnOD_90  then restOD_Acc
						else returnOD_1+returnOD_30+returnOD_90 end
					 * b.reservPRC / 100
		, minPRC = case when restPRC_Acc < returnPRC_1+returnPRC_30+returnPRC_90  then restPRC_Acc
						else returnPRC_1+returnPRC_30+returnPRC_90 end
		, reservPRC90 = case when restPRC_Acc < returnPRC_1+returnPRC_30+returnPRC_90  then restPRC_Acc
						else returnPRC_1+returnPRC_30+returnPRC_90 end
					* b.reservPRC / 100


		INTO #TERMS

		from finAnalytics.termpayment_MONTHLY a
		left join finAnalytics.Reserv_NU b on a.dogNum = b.dogNum and a.repMonth=b.REPMONTH
		where a.repMonth=@repmonth
		and a.prosBeginDate is null
		and upper(a.dogStatus) = upper('Действует')
		and (a.prosAll is null or a.prosAll=0)
		and upper(a.isBunkrupt)=upper('Нет')
		/*https://tracker.yandex.ru/FINA-205*/
		--and a.isKK377 is null
		and (a.isKK377 is null 
			or
			(a.isKK377 is not null
				and
				(upper(a.isKK377Cancel) = upper('Да')
				or
				upper(a.isKK377Stop) = upper('Да')
				)
			)
			)
		and a.restOD_Acc+a.restPRC_Acc >0

		DROP TABLE IF EXISTS #DEPO
		select
		client
		, INN
		, dogNum
		, dogDSNum
		, dogDate
		, zaimSum
		, zaimVal
		, prodName
		, StavkaDogDate
		, StavkaRepDate
		, dogSaleDate
		, dogEndDate
		, firstDogEndDate
		, accOD
		, restOD
		, addOD
		, returnOD
		, accPRC
		, restPRC
		, addPRC
		, returnPRC
		, incNDFL
		, isMSP
		, capitalType
		, daysToClose
		, daysDog
		, passport
		, birthDay
		, addressFact
		, addressReg
		, branchAddress
		, dataLoadDate
		, isMainDog
		, mainDogNum
		, daysBetween = DATEDIFF(day,eomonth(@repmonth),a.dogEndDate)

		into #DEPO

		from finAnalytics.DEPO_MONTHLY a
		where a.repmonth = @repmonth
		--and DATEDIFF(day,eomonth(@repmonth),a.dogEndDate) between 1 and 90


delete from finAnalytics.rep840_3_detail where REPMONTH=@repmonth

--3.5.1.7
insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.7'
, BS = '20202'
, groupName = 'денежные средства'
, pokazatel = '20202 «Касса организации» '
, value = (
		  select isnull(SUM(isnull(restOUT_BU,0)),0) from #OSV where acc2order='20202'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 2

--3.5.1.7
-- не хватает справочника Справочник.БанковскиеСчета - ждем проброски
insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.7'
, BS = '20501'
, groupName = 'денежные средства'
, pokazatel = '20501 «Расчетные счета в кредитных организациях»'
, value = (
		  select isnull(SUM(isnull(case when lic.accNum IS not null and lic.licReturnDate>EOMONTH(@repmonth) then 0 else restOUT_BU end,0)),0)
		  from #OSV a
		  left join finAnalytics.SPR_BanksWOLicense lic on a.accNum=lic.accNum
		  --left join Stg._1cUMFO.Справочник_БанковскиеСчета bs on a.subconto1UID=bs.Ссылка

		  where a.acc2order='20501'
		  )
, comment = 'не хватает справочника Справочник.БанковскиеСчета - ждем проброски--Баланс. Сальдо на конец периода по дебету'
, rownum = 3

--3.5.1.7
insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.7'
, BS = '20601'
, groupName = 'денежные средства'
, pokazatel = '20601 "Депозиты в кредитных организациях"'
, value = (
		  select isnull(SUM(isnull(restOUT_BU,0)),0) from #OSV where acc2order='20601'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 4

--3.5.1.7
insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.7'
, BS = '47423'
, groupName = 'денежные средства'
, pokazatel = '47423 «Требования по прочим финансовым операциям»'
, value = (
		  select isnull(SUM(isnull(restOUT_BU,0)),0)
		  from #OSV a
		  left join stg._1cUMFO.Справочник_Контрагенты cl on a.subconto1UID=cl.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		  left join stg._1cUMFO.Справочник_Контрагенты cl2 on cl.Родитель=cl2.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		  left join finAnalytics.SPR_BanksWOLicense lic on upper(cl.Наименование) = lic.bankName
		  where acc2order='47423'
		  and upper(cl2.Наименование) = UPPER('Платежные системы')
		  and (lic.bankName is null or lic.licReturnDate >=eomonth(@repmonth))
		  )
, comment = 'Счет 47423 - остаток на дату отчета по счетам компаний, являющихся операторами по переводу денежных средств, за минусом остатка по КО с отозванной лицензией (см. выше). По счету 47423 в расчет строки берутся остатки только по тем Контрагентам, которые классифицированы в 1С-УМФО как Платежная система (юр.лица и КО)'
, rownum = 5

--3.5.1.7 ИТОГО по Пункту
insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.7'
, BS = ''
, groupName = 'денежные средства'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.5.1.7')
		  )
, comment = 'Сумма BS 20202, 20501, 20601, 47423'
, rownum = 1
---------------------------------------------------------------------------------

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.2
select
REPMONTH = @repmonth
, punkt = '3.5.1.2'
, BS = '48501'
, groupName = 'требования по договорам займа по основному долгу'
, pokazatel = '48501 «Займы, предоставленные юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(zadolgOD,0)),0)
		  from #PBR a
		  where substring(AccODNum,1,5)='48501'
		  and upper(a.isBankrupt) = UPPER('Нет')
		  )
, comment = 'ПБР:  "Задолженность ОД" (Графа AV)  для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48501 и в графе "Банкротство" (G) - значение "Нет" (обработать исключения)'
, rownum = 7

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.2
select
REPMONTH = @repmonth
, punkt = '3.5.1.2'
, BS = '48510'
, groupName = 'требования по договорам займа по основному долгу'
, pokazatel = '48510 «Резервы под обесценение по займам, выданным юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(reservOD,0)),0)  * -1
		  from #PBR a
		  where substring(AccODNum,1,5)='48501'
		  and upper(a.isBankrupt) = UPPER('Нет')
		  )
, comment = 'ПБР:  (BG (Резерв ОД)) *-1  для займов, отобранных выше'
, rownum = 8

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.2
select
REPMONTH = @repmonth
, punkt = '3.5.1.2'
, BS = '48601'
, groupName = 'требования по договорам займа по основному долгу'
, pokazatel = '48601 «Займы, выданные физическим лицам»'
, value = (
		  select isnull(SUM(isnull(zadolgOD,0)),0)
		  from #PBR a
		  where substring(AccODNum,1,5)='48601'
		  and upper(a.isBankrupt) = UPPER('Нет')
		  )
, comment = 'ПБР:  "Задолженность ОД" (Графа AV) для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48601 и в графе "Банкротство" (G) - значение "Нет" (обработать исключения)'
, rownum = 9

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.2
select
REPMONTH = @repmonth
, punkt = '3.5.1.2'
, BS = '48610'
, groupName = 'требования по договорам займа по основному долгу'
, pokazatel = '48610 «Резервы под обесценение по займам, выданным физическим лицам»'
, value = (
		  select isnull(SUM(isnull(reservOD,0)),0) * -1
		  from #PBR a
		  where substring(AccODNum,1,5)='48601'
		  and upper(a.isBankrupt) = UPPER('Нет')
		  )
, comment = 'ПБР: - (BG (Резерв ОД) )*-1 для займов, отобранных  выше'
, rownum = 10

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.2
select
REPMONTH = @repmonth
, punkt = '3.5.1.2'
, BS = '49001'
, groupName = 'требования по договорам займа по основному долгу'
, pokazatel = '49001 «Займы, выданные физическим лицам - нерезидентам»'
, value = (
		  select isnull(SUM(isnull(zadolgOD,0)),0)
		  from #PBR a
		  where substring(AccODNum,1,5)='49001'
		  and upper(a.isBankrupt) = UPPER('Нет')
		  )
, comment = 'ПБР:  "Задолженность ОД" (Графа AV) для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 49001 и в графе "Банкротство" (G) - значение "Нет" (обработать исключения)'
, rownum = 11

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.2
select
REPMONTH = @repmonth
, punkt = '3.5.1.2'
, BS = '49010'
, groupName = 'требования по договорам займа по основному долгу'
, pokazatel = '49010 «Резервы под обесценение по займам, выданным физическим лицам - нерезидентам»'
, value = (
		  select isnull(SUM(isnull(reservOD,0)),0) * -1
		  from #PBR a
		  where substring(AccODNum,1,5)='49001'
		  and upper(a.isBankrupt) = UPPER('Нет')
		  )
, comment = 'ПБР: - (BG (Резерв ОД) )*-1 для займов, отобранных  выше'
, rownum = 12

--3.5.1.2 ИТОГО по Пункту
insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.2'
, BS = ''
, groupName = 'требования по договорам займа по основному долгу'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.5.1.2')
		  and upper(a.groupName)=upper('требования по договорам займа по основному долгу')
		  )
, comment = 'Сумма BS 20202, 20501, 20601, 47423'
, rownum = 6
---------------------------------------------------------------------------------

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48701'
, groupName = 'требования по договорам микрозайма по основному долгу'
, pokazatel = '48701 «Микрозаймы (в том числе целевые микрозаймы), выданные юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(zadolgOD,0)),0)
		  from #PBR a
		  where substring(AccODNum,1,5)='48701'
		  --and upper(a.isBankrupt) = UPPER('Нет')
		  )
, comment = 'ПБР:  "Задолженность ОД" (Графа AV) для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48701'
, rownum = 14

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48710'
, groupName = 'требования по договорам микрозайма по основному долгу'
, pokazatel = '48710 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(reservOD,0)),0) * -1
		  from #PBR a
		  where substring(AccODNum,1,5)='48701'
		  --and upper(a.isBankrupt) = UPPER('Нет')
		  )
, comment = 'ПБР: - (BG (Резерв ОД) )*-1 для займов, отобранных выше'
, rownum = 15

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48801'
, groupName = 'требования по договорам микрозайма по основному долгу'
, pokazatel = '48801 «Микрозаймы (в том числе целевые микрозаймы), выданные физическим лицам»'
, value = (
		  select isnull(SUM(isnull(zadolgOD,0)),0)
		  from #PBR a
		  where substring(AccODNum,1,5)='48801'
		  --and upper(a.isBankrupt) = UPPER('Нет')
		  )
, comment = 'ПБР:  "Задолженность ОД" (Графа AV) для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48801'
, rownum = 16

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48810'
, groupName = 'требования по договорам микрозайма по основному долгу'
, pokazatel = '48810 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным физическим лицам»'
, value = (
		  select isnull(SUM(isnull(reservOD,0)),0) * -1
		  from #PBR a
		  where substring(AccODNum,1,5)='48801'
		  --and upper(a.isBankrupt) = UPPER('Нет')
		  )
, comment = 'ПБР: - (BG (Резерв ОД) )*-1 для займов, отобранных выше'
, rownum = 17

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '49401'
, groupName = 'требования по договорам микрозайма по основному долгу'
, pokazatel = '49401 «Микрозаймы (в том числе целевые микрозаймы), выданные индивидуальным предпринимателям»'
, value = (
		  select isnull(SUM(isnull(zadolgOD,0)),0)
		  from #PBR a
		  where substring(AccODNum,1,5)='49401'
		  --and upper(a.isBankrupt) = UPPER('Нет')
		  )
, comment = 'ПБР:  "Задолженность ОД" (Графа AV) для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 49401'
, rownum = 18

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '49410'
, groupName = 'требования по договорам микрозайма по основному долгу'
, pokazatel = '49410 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным индивидуальным предпринимателям»'
, value = (
		  select isnull(SUM(isnull(reservOD,0)),0) * -1
		  from #PBR a
		  where substring(AccODNum,1,5)='49401'
		  --and upper(a.isBankrupt) = UPPER('Нет')
		  )
, comment = 'ПБР:  (BG (Резерв ОД) )*-1 для займов, отобранных выше'
, rownum = 19

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48801'
, groupName = 'требования по договорам микрозайма по основному долгу'
, pokazatel = '48801 «Микрозаймы (в том числе целевые микрозаймы), выданные физическим лицам»: по договорам микрозайма, заключенным с физическими лицами, в отношении которых введена процедура банкротства в соответствии с законодательством Российской Федерации о несостоятельности (банкротстве)'
, value = (
		  select isnull(SUM(isnull(zadolgOD,0)),0) *-1
		  from #PBR a
		  where substring(AccODNum,1,5)='48801'
		  and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР:  "Задолженность ОД" (Графа AV) для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48801, у которых в графе "Банкротство" (G) - значение "Да" (обработать исключения). * -1'
, rownum = 20

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48810'
, groupName = 'требования по договорам микрозайма по основному долгу'
, pokazatel = '48810 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным физическим лицам»:по договорам микрозайма, заключенным с физическими лицами, в отношении которых введена процедура банкротства в соответствии с законодательством Российской Федерации о несостоятельности (банкротстве)'
, value = (
		  select isnull(SUM(isnull(reservOD,0)),0)
		  from #PBR a
		  where substring(AccODNum,1,5)='48801'
		  and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР:  (BG (Резерв ОД) ) для займов, отобранных выше'
, rownum = 21

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '49401'
, groupName = 'требования по договорам микрозайма по основному долгу'
, pokazatel = '49401 «Микрозаймы (в том числе целевые микрозаймы), выданные индивидуальным предпринимателям»: по договорам микрозайма, заключенным с физическими лицами, в отношении которых введена процедура банкротства в соответствии с законодательством Российской Федерации о несостоятельности (банкротстве)'
, value = (
		  select isnull(SUM(isnull(zadolgOD,0)),0) * -1
		  from #PBR a
		  where substring(AccODNum,1,5)='49401'
		  and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: ( "Задолженность ОД" (Графа AV) для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 49401, у которых в графе "Банкротство" (G) - значение "Да" (обработать исключения).)*-1'
, rownum = 22

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '49410'
, groupName = 'требования по договорам микрозайма по основному долгу'
, pokazatel = '49410 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным индивидуальным предпринимателям»: по договорам микрозайма, заключенным с физическими лицами, в отношении которых введена процедура банкротства в соответствии с законодательством Российской Федерации о несостоятельности (банкротстве)'
, value = (
		  select isnull(SUM(isnull(reservOD,0)),0)
		  from #PBR a
		  where substring(AccODNum,1,5)='49401'
		  and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР:  (BG (Резерв ОД) ) для займов, отобранных выше'
, rownum = 23

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48701'
, groupName = 'требования по договорам микрозайма по основному долгу'
, pokazatel = '48701 «Микрозаймы (в том числе целевые микрозаймы), выданные юридическим лицам» в отношении которых введена процедура банкротства в соответствии с законодательством Российской Федерации о несостоятельности (банкротстве)'
, value = (
		  select isnull(SUM(isnull(zadolgOD,0)),0) * -1
		  from #PBR a
		  where substring(AccODNum,1,5)='48701'
		  and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР:  "Задолженность ОД" (Графа AV) для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48701 у которых в графе "Банкротство" (G) - значение "Да" (обработать исключения). *-1'
, rownum = 24

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48710'
, groupName = 'требования по договорам микрозайма по основному долгу'
, pokazatel = '48710 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным юридическим лицам» в отношении которых введена процедура банкротства в соответствии с законодательством Российской Федерации о несостоятельности (банкротстве)'
, value = (
		  select isnull(SUM(isnull(reservOD,0)),0)
		  from #PBR a
		  where substring(AccODNum,1,5)='48701'
		  and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР:  (BG (Резерв ОД) ) для займов, отобранных выше'
, rownum = 25


--3.5.1.1 ИТОГО по Пункту
insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = ''
, groupName = 'требования по договорам микрозайма по основному долгу'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.5.1.1')
		  and upper(a.groupName)=upper('требования по договорам микрозайма по основному долгу')
		  )
, comment = 'Сумма BS 48701, 48710, 48801, 48810, 49401, 49410, 48801, 48810, 49401, 49410 '
, rownum = 13
---------------------------------------------------------------------------------


insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.2
select
REPMONTH = @repmonth
, punkt = '3.5.1.2'
, BS = '48502'
, groupName = 'требования по договорам займа по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '48502 «Начисленные проценты по займам, предоставленным юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(zadolgPrc,0)+isnull(penyaSum,0)),0)
		  from #PBR a
		  where substring(AccODNum,1,5)='48501'
		  --and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: "Задолженность проценты" (Графа AW) + "Сумма пени счета" (AX) для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48501'
, rownum = 27

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.2
select
REPMONTH = @repmonth
, punkt = '3.5.1.2'
, BS = '48510'
, groupName = 'требования по договорам займа по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '48510 «Резервы под обесценение по займам, выданным юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(reservPRC,0)+isnull(reservProchSumNU,0)),0) * -1
		  from #PBR a
		  where substring(AccODNum,1,5)='48501'
		  --and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: ("Резерв проценты" (BI) + "Сумма резервов прочие НУ" (BN) )*-1 для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48501'
, rownum = 28

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.2
select
REPMONTH = @repmonth
, punkt = '3.5.1.2'
, BS = '48602'
, groupName = 'требования по договорам займа по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '48602 «Начисленные проценты по займам, выданным физическим лицам»'
, value = (
		  select isnull(SUM(isnull(zadolgPrc,0)+isnull(penyaSum,0)),0)
		  from #PBR a
		  where substring(AccODNum,1,5)='48601'
		  --and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: "Задолженность проценты" (Графа AW) + "Сумма пени счета" (AX) для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48601'
, rownum = 29

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.2
select
REPMONTH = @repmonth
, punkt = '3.5.1.2'
, BS = '48610'
, groupName = 'требования по договорам займа по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '48610 «Резервы под обесценение по займам, выданным физическим лицам»'
, value = (
		  select isnull(SUM(isnull(reservPRC,0)+isnull(reservProchSumNU,0)),0) * -1
		  from #PBR a
		  where substring(AccODNum,1,5)='48501'
		  --and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: ("Резерв проценты" (BI) + "Сумма резервов прочие НУ" (BN))*-1  для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48601'
, rownum = 30

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.2
select
REPMONTH = @repmonth
, punkt = '3.5.1.2'
, BS = '49002'
, groupName = 'требования по договорам займа по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '49002 «Начисленныеп проценты по займам, выданнм физическим лицам-нерезидентам»'
, value = (
		  select isnull(SUM(isnull(zadolgPrc,0)+isnull(penyaSum,0)),0)
		  from #PBR a
		  where substring(AccODNum,1,5)='49001'
		  --and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: "Задолженность проценты" (Графа AW) + "Сумма пени счета" (AX) для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 49001'
, rownum = 31

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.2
select
REPMONTH = @repmonth
, punkt = '3.5.1.2'
, BS = '49010'
, groupName = 'требования по договорам займа по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '49010 «Резервы под обесценение по займам, выданным физическим лицам - нерезидентам»'
, value = (
		  select isnull(SUM(isnull(reservPRC,0)+isnull(reservProchSumNU,0)),0) * -1
		  from #PBR a
		  where substring(AccODNum,1,5)='49001'
		  --and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: ("Резерв проценты" (BI) + "Сумма резервов прочие НУ" (BN))*-1 для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 49001'
, rownum = 32

--3.5.1.2 ИТОГО по Пункту
insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.2'
, BS = ''
, groupName = 'требования по договорам займа по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.5.1.2')
		  and upper(a.groupName)=upper('требования по договорам займа по начисленным процентам, а также по неустойке (штрафу, пене)')
		  )
, comment = 'Сумма BS 48502, 48510, 48602, 48610, 49002, 49010'
, rownum = 26
---------------------------------------------------------------------------------

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48702'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '48702 «Начисленные проценты по микрозаймам (в том числе по целевым микрозаймам), выданным юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(zadolgPrc,0)),0)
		  from #PBR a
		  where substring(AccODNum,1,5)='48701'
		  --and upper(a.isBankrupt) = UPPER('Нет')
		  )
, comment = 'ПБР: "Задолженность проценты" (Графа AW) для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48701'
, rownum = 34

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48710'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '48710 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(reservPRC,0)),0) * -1
		  from #PBR a
		  where substring(AccODNum,1,5)='48701'
		  --and upper(a.isBankrupt) = UPPER('Нет')
		  )
, comment = 'ПБР: ("Резерв проценты" (BI))*-1  для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48701'
, rownum = 35

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48802'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '48802 «Начисленные проценты по микрозаймам (в том числе по целевым микрозаймам), выданным физическим лицам»'
, value = (
		  select isnull(SUM(isnull(zadolgPrc,0)/*+isnull(penyaSum,0)*/),0)
		  from #PBR a
		  where substring(AccODNum,1,5)='48801'
		  --and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: "Задолженность проценты" (Графа AW) для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48801'
, rownum = 36

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48810'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '48810 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным физическим лицам»'
, value = (
		  select isnull(SUM(isnull(reservPRC,0)),0) * -1
		  from #PBR a
		  where substring(AccODNum,1,5)='48801'
		  --and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: ("Резерв проценты" (BI))*-1 для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48801'
, rownum = 37

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '49402'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '49402 «Начисленные проценты по микрозаймам (в том числе по целевым микрозаймам), выданным индивидуальным предпринимателям»'
, value = (
		  select isnull(SUM(isnull(zadolgPrc,0)),0)
		  from #PBR a
		  where substring(AccODNum,1,5)='49401'
		  --and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: "Задолженность проценты" (Графа AW)  для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 49401'
, rownum = 38

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '49410'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '49410 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным индивидуальным предпринимателям»'
, value = (
		  select isnull(SUM(isnull(reservPRC,0)),0) * -1
		  from #PBR a
		  where substring(AccODNum,1,5)='49401'
		  --and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: ("Резерв проценты" (BI))*-1 для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 49401'
, rownum = 39

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '60323'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '60323 «Расчеты с прочими дебиторами»'
, value = (
		  select isnull(SUM(isnull(penyaSum,0)),0)
		  from #PBR a
		  --where substring(AccODNum,1,5)='49401'
		  --and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР:  "Сумма пени счета" (AX)'
, rownum = 40

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '60324'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '60324 «Резервы»'
, value = (
		  select isnull(SUM(isnull(reservProchSumNU,0)),0) * -1
		  from #PBR a
		  --where substring(AccODNum,1,5)='49401'
		  --and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: ("Сумма резервов прочие НУ" (BN))*-1'
, rownum = 41

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48802'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '48802 «Начисленные проценты по микрозаймам (в том числе по целевым микрозаймам), выданным физическим лицам»: по договорам микрозайма, заключенным с физическими лицами, в отношении которых введена процедура банкротства в соответствии с законодательством Российской Федерации о несостоятельности (банкротстве)'
, value = (
		  select isnull(SUM(isnull(zadolgPrc,0)),0) *-1
		  from #PBR a
		  where substring(AccODNum,1,5)='48801'
		  and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: ("Задолженность проценты" (Графа AW))*-1  для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48801, у которых в графе "Банкротство" (G) - значение "Да" (обработать исключения).'
, rownum = 42

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48810'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '48810 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным физическим лицам»: по договорам микрозайма, заключенным с физическими лицами, в отношении которых введена процедура банкротства в соответствии с законодательством Российской Федерации о несостоятельности (банкротстве)'
, value = (
		  select isnull(SUM(isnull(reservPRC,0)),0) 
		  from #PBR a
		  where substring(AccODNum,1,5)='48801'
		  and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: "Резерв проценты" (BI)  для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48801, у которых в графе "Банкротство" (G) - значение "Да" (обработать исключения).'
, rownum = 43

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '49402'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '49402 «Начисленные проценты по микрозаймам (в том числе по целевым микрозаймам), выданным индивидуальным предпринимателям»: по договорам микрозайма, заключенным с физическими лицами, в отношении которых введена процедура банкротства в соответствии с законодательством Российской Федерации о несостоятельности (банкротстве)'
, value = (
		  select isnull(SUM(isnull(zadolgPrc,0)),0) *-1
		  from #PBR a
		  where substring(AccODNum,1,5)='49401'
		  and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: ("Задолженность проценты" (Графа AW))*-1 для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 49401, у которых в графе "Банкротство" (G) - значение "Да" (обработать исключения).)'
, rownum = 44

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '49410'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '49410 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным индивидуальным предпринимателям»: по договорам микрозайма, заключенным с физическими лицами, в отношении которых введена процедура банкротства в соответствии с законодательством Российской Федерации о несостоятельности (банкротстве)'
, value = (
		  select isnull(SUM(isnull(reservPRC,0)),0) 
		  from #PBR a
		  where substring(AccODNum,1,5)='49401'
		  and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: "Резерв проценты" (BI)  для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 49401, у которых в графе "Банкротство" (G) - значение "Да" (обработать исключения).)'
, rownum = 45

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '60323'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '60323 «Расчеты с прочими дебиторами": по договорам микрозайма, заключенным с физическими лицами, в отношении которых введена процедура банкротства в соответствии с законодательством Российской Федерации о несостоятельности (банкротстве)'
, value = (
		  select isnull(SUM(isnull(penyaSum,0)),0) *-1
		  from #PBR a
		  where 1=1
		  and substring(AccODNum,1,5) in ('48801','49401')
		  and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: ( "Сумма пени счета" (AX))*-1   для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48801,49401, у которых в графе "Банкротство" (G) - значение "Да" (обработать исключения).'
, rownum = 46

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '60324'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '60324 «Резервы по договорам микрозайма, заключенным с физическими лицами, в отношении которых введена процедура банкротства в соответствии с законодательством Российской Федерации о несостоятельности (банкротстве)»'
, value = (
		  select isnull(SUM(isnull(reservProchSumNU,0)),0) 
		  from #PBR a
		  where 1=1
		  and substring(AccODNum,1,5) in ('48801','49401')
		  and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР:  "Сумма резервов прочие НУ" (BN)  для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48801,49401, у которых в графе "Банкротство" (G) - значение "Да" (обработать исключения).'
, rownum = 47

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48702'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '48702 «Начисленные проценты по микрозаймам (в том числе по целевым микрозаймам), выданным юридическим лицам» в отношении которых введена процедура банкротства в соответствии с законодательством Российской Федерации о несостоятельности (банкротстве)»'
, value = (
		  select isnull(SUM(isnull(zadolgPrc,0)),0) *-1
		  from #PBR a
		  where 1=1
		  and substring(AccODNum,1,5) in ('48701')
		  and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: ("Задолженность проценты" (Графа AW))*-1  для займов, у которых  в графе  BW (Счет учета основного долга) счет начинается на 48701, у которых в графе "Банкротство" (G) - значение "Да" (обработать исключения).'
, rownum = 48

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.1
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = '48710'
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = '48710 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным юридическим лицам» в отношении которых введена процедура банкротства в соответствии с законодательством Российской Федерации о несостоятельности (банкротстве)»'
, value = (
		  select isnull(SUM(isnull(reservPRC,0)),0) 
		  from #PBR a
		  where 1=1
		  and substring(AccODNum,1,5) in ('48701')
		  and upper(a.isBankrupt) = UPPER('Да')
		  )
, comment = 'ПБР: "Резерв проценты" (BI)  для займов, у которых  в графе  BW * -1 ((Счет учета основного долга) счет начинается на 48701, у которых в графе "Банкротство" (G) - значение "Да" (обработать исключения).'
, rownum = 49

--3.5.1.1 ИТОГО по Пункту
insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.1.1'
, BS = ''
, groupName = 'требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.5.1.1')
		  and upper(a.groupName)=upper('требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)')
		  )
, comment = 'Сумма BS 48702, 48710, 48802, 48810, 49402, 49410, 60323, 60324, 48802, 48810, 49402, 49410, 60323, 60324'
, rownum = 33
---------------------------------------------------------------------------------

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '60806'
, groupName = 'Обязательства'
, pokazatel = '60806 «Арендные обязательства»'
, value = (
		  select isnull(sum(ISNULL(a.sumOverflow,0)),0)
		  from #ARENDA a
		  where 1=1
		  )
, comment = 'Сумма арендных обязательств из справочника "Аренда".  Столбец G "Превышение обязательств на стоимостью активов с учетом амортизации"'
, rownum = 51

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '20503'
, groupName = 'Обязательства'
, pokazatel = 'Кредит, полученный в порядке расчетов по расчетному счету ("овердрафт") в кредитных организациях'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='20503'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 52

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '20504'
, groupName = 'Обязательства'
, pokazatel = 'Кредит, полученный в порядке расчетов по расчетному счету ("овердрафт") в банках-нерезидентах'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='20504'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 53

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42316'
, groupName = 'Обязательства'
, pokazatel = '42316 «Привлеченные средства физических лиц»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42316'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 54

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42317'
, groupName = 'Обязательства'
, pokazatel = '42317 «Начисленные проценты (к уплате) по привлеченным средствам физических лиц»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42317'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 55

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42318'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств физических лиц'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42318'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 56

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42319'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств физических лиц'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42319'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 57

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42320'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств физических лиц'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42320'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 58

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42321'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств физических лиц'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42321'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 59

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42322'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам физических лиц'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42322'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 60

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42323'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств физических лиц, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42323'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 61

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42324'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств физических лиц, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42324'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 62

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42616'
, groupName = 'Обязательства'
, pokazatel = 'Привлеченные средства физических лиц - нерезидентов'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42616'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 63

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42617'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к уплате) по привлеченным средствам физических лиц - нерезидентов'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42617'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 64

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42618'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств физических лиц - нерезидентов'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42618'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 65

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42619'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств физических лиц - нерезидентов'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42619'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 66

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42620'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств физических лиц - нерезидентов'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42620'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 67

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42621'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств физических лиц - нерезидентов'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42621'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 68

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42622'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам физических лиц - нерезидентов'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42622'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 69

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42623'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств физических лиц - нерезидентов, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42623'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 70

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42624'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств физических лиц - нерезидентов, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42624'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 71

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42708'
, groupName = 'Обязательства'
, pokazatel = 'Привлеченные средства Федерального казначейства'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42708'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 72

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42709'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к уплате) по привлеченным средствам Федерального казначейства'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42709'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 73

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42718'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств Федерального казначейства'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42718'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 74

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42719'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств Федерального казначейства'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42719'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 75

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42720'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств Федерального казначейства'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42720'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 76

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42721'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств Федерального казначейства'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42721'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 77

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42722'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам Федерального казначейства'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42722'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 78

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42723'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств Федерального казначейства, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42723'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 79

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42724'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств Федерального казначейства, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42724'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 80

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42808'
, groupName = 'Обязательства'
, pokazatel = 'Привлеченные средства финансовых органов субъектов Российской Федерации и органов местного самоуправления'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42808'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 81

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42809'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к уплате) по привлеченным средствам финансовых органов субъектов Российской Федерации и органов местного самоуправления'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42809'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 82

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42818'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств финансовых органов субъектов Российской Федерации и органов местного самоуправления'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42818'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 83

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42819'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств финансовых органов субъектов Российской Федерации и органов местного самоуправления'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42819'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 84

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42820'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств финансовых органов субъектов Российской Федерации и органов местного самоуправления'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42820'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 85

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42821'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств финансовых органов субъектов Российской Федерации и органов местного самоуправления'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42821'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 86

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42822'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам финансовых органов субъектов Российской Федерации и органов местного самоуправления'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42822'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 87

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42823'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств финансовых органов субъектов Российской Федерации и органов местного самоуправления, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42823'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 88

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42824'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств финансовых органов субъектов Российской Федерации и органов местного самоуправления, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42824'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 89

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42908'
, groupName = 'Обязательства'
, pokazatel = 'Привлеченные средства государственных внебюджетных фондов Российской Федерации'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42908'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 90

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42909'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к уплате) по привлеченным средствам государственных внебюджетных фондов Российской Федерации'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42909'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 91

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42918'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств государственных внебюджетных фондов Российской Федерации'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42918'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 92

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42919'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств государственных внебюджетных фондов Российской Федерации'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42919'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 93

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42920'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств государственных внебюджетных фондов Российской Федерации'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42920'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 94

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42921'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств государственных внебюджетных фондов Российской Федерации'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42921'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 95

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42922'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам государственных внебюджетных фондов Российской Федерации'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42922'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 96

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42923'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств государственных внебюджетных фондов Российской Федерации, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42923'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 97

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '42924'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств государственных внебюджетных фондов Российской Федерации, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='42924'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 98

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43008'
, groupName = 'Обязательства'
, pokazatel = 'Привлеченные средства внебюджетных фондов субъектов Российской Федерации и органов местного самоуправления'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43008'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 99

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43009'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к уплате) по привлеченным средствам внебюджетных фондов субъектов Российской Федерации и органов местного самоуправления'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43009'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 100

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43018'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств внебюджетных фондов субъектов Российской Федерации и органов местного самоуправления'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43018'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 101

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43019'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств внебюджетных фондов субъектов Российской Федерации и органов местного самоуправления'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43019'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 102

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43020'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств внебюджетных фондов субъектов Российской Федерации и органов местного самоуправления'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43020'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 103

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43021'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств внебюджетных фондов субъектов Российской Федерации и органов местного самоуправления'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43021'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 104

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43022'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам внебюджетных фондов субъектов Российской Федерации и органов местного самоуправления'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43022'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 105

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43023'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств внебюджетных фондов субъектов Российской Федерации и органов местного самоуправления, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43023'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 105

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43024'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств внебюджетных фондов субъектов Российской Федерации и органов местного самоуправления, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43024'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 107

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43108'
, groupName = 'Обязательства'
, pokazatel = 'Привлеченные средства финансовых организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43108'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 108

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43109'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к уплате) по привлеченным средствам финансовых организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43109'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 109

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43118'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств финансовых организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43118'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 110

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43119'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств финансовых организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43119'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 111

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43120'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств финансовых организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43120'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 112

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43121'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств финансовых организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43121'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 113

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43122'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам финансовых организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43122'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 114

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43123'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств финансовых организаций, находящихся в федеральной собственности, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43123'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 115

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43124'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств финансовых организаций, находящихся в федеральной собственности, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43124'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 116

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43208'
, groupName = 'Обязательства'
, pokazatel = 'Привлеченные средства коммерческих организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43208'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 117

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43209'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к уплате) по привлеченным средствам коммерческих организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43209'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 118

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43218'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств коммерческих организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43218'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 119

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43219'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств коммерческих организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43219'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 120

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43220'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств коммерческих организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43220'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 121

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43221'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств коммерческих организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43221'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 122

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43222'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам коммерческих организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43222'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 123

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43223'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств коммерческих организаций, находящихся в федеральной собственности, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43223'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 124

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43224'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств коммерческих организаций, находящихся в федеральной собственности, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43224'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 125

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43308'
, groupName = 'Обязательства'
, pokazatel = 'Привлеченные средства некоммерческих организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43308'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 126

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43309'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к уплате) по привлеченным средствам некоммерческих организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43309'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 127

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43318'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств некоммерческих организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43318'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 128

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43319'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств некоммерческих организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43319'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 129

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43320'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств некоммерческих организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43320'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 130

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43321'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств некоммерческих организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43321'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 131

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43322'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам некоммерческих организаций, находящихся в федеральной собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43322'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 132

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43323'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств некоммерческих организаций, находящихся в федеральной собственности, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43323'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 133

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43324'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств некоммерческих организаций, находящихся в федеральной собственности, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43324'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 134

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43408'
, groupName = 'Обязательства'
, pokazatel = 'Привлеченные средства финансовых организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43408'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 135

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43409'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к уплате) по привлеченным средствам финансовых организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43409'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 136

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43418'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств финансовых организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43418'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 137

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43419'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств финансовых организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43419'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 138

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43420'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств финансовых организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43420'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 139

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43421'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств финансовых организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43421'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 140

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43422'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам финансовых организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43422'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 141

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43423'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств финансовых организаций, находящихся в государственной (кроме федеральной) собственности, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43423'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 142

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43424'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств финансовых организаций, находящихся в государственной (кроме федеральной) собственности, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43424'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 143

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43508'
, groupName = 'Обязательства'
, pokazatel = 'Привлеченные средства коммерческих организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43508'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 144

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43509'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к уплате) по привлеченным средствам коммерческих организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43509'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 145

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43518'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств коммерческих организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43518'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 146

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43519'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств коммерческих организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43519'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 147

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43520'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств коммерческих организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43520'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 148

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43521'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств коммерческих организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43521'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 149

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43522'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам коммерческих организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43522'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 150

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43523'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств коммерческих организаций, находящихся в государственной (кроме федеральной) собственности, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43523'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 151

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43524'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств коммерческих организаций, находящихся в государственной (кроме федеральной) собственности, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43524'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 152

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43608'
, groupName = 'Обязательства'
, pokazatel = 'Привлеченные средства некоммерческих организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43608'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 153

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43609'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к уплате) по привлеченным средствам некоммерческих организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43609'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 154

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43618'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств некоммерческих организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43618'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 155

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43619'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств некоммерческих организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43619'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 156

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43620'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств некоммерческих организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43620'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 157

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43621'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств некоммерческих организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43621'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 158

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43622'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам некоммерческих организаций, находящихся в государственной (кроме федеральной) собственности'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43622'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 159

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43623'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств некоммерческих организаций, находящихся в государственной (кроме федеральной) собственности, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43623'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 160

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43624'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств некоммерческих организаций, находящихся в государственной (кроме федеральной) собственности, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43624'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 161

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43708'
, groupName = 'Обязательства'
, pokazatel = '43708 «Привлеченные средства негосударственных финансовых организаций»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43708'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 162

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43709'
, groupName = 'Обязательства'
, pokazatel = '43709 «Начисленные проценты (к уплате) по привлеченным средствам негосударственных финансовых организаций»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43709'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 163

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43718'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств негосударственных финансовых организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  		  from #OSV a
		  where 1=1
		  and a.acc2order='43718'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 164

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43719'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств негосударственных финансовых организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43719'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 165

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43720'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств негосударственных финансовых организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43720'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 166

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43721'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств негосударственных финансовых организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43721'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 167

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43722'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам негосударственных финансовых организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43722'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 168

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43723'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств негосударственных финансовых организаций, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43723'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 169

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43724'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств негосударственных финансовых организаций, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43724'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 170

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43808'
, groupName = 'Обязательства'
, pokazatel = '43808 «Привлеченные средства негосударственных коммерческих организаций»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43808'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 171

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43809'
, groupName = 'Обязательства'
, pokazatel = '43809 «Начисленные проценты (к уплате) по привлеченным средствам негосударственных коммерческих организаций»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43809'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 172

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43818'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств негосударственных коммерческих организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43818'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 173

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43819'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств негосударственных коммерческих организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43819'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 174

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43820'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств негосударственных коммерческих организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43820'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 175

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43821'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств негосударственных коммерческих организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43821'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 176

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43822'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам негосударственных коммерческих организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43822'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 177

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43823'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств негосударственных коммерческих организаций, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43823'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 178

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43824'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств негосударственных коммерческих организаций, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43824'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 179

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43908'
, groupName = 'Обязательства'
, pokazatel = 'Привлеченные средства негосударственных некоммерческих организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43908'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 180

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43909'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к уплате) по привлеченным средствам негосударственных некоммерческих организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43909'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 181

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43918'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств негосударственных некоммерческих организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43918'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 182

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43919'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств негосударственных некоммерческих организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43919'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 183

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43920'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств негосударственных некоммерческих организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43920'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 184

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43921'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств негосударственных некоммерческих организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43921'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 185

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43922'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам негосударственных некоммерческих организаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43922'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 186

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43923'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств негосударственных некоммерческих организаций, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43923'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 187

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '43924'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств негосударственных некоммерческих организаций, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='43924'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 188

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '44008'
, groupName = 'Обязательства'
, pokazatel = 'Привлеченные средства юридических лиц - нерезидентов'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='44008'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 189

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '44009'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к уплате) по привлеченным средствам юридических лиц - нерезидентов'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='44009'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 190

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '44018'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с привлечением средств юридических лиц - нерезидентов'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='44018'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 191

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '44019'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с привлечением средств юридических лиц - нерезидентов'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='44019'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 192

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '44020'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость привлеченных средств юридических лиц - нерезидентов'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='44020'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 193

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '44021'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость привлеченных средств юридических лиц - нерезидентов'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='44021'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 194

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '44022'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные проценты (к получению) по привлеченным средствам юридических лиц - нерезидентов'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='44022'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 195

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '44023'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость привлеченных средств юридических лиц - нерезидентов, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='44023'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 196

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '44024'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость привлеченных средств юридических лиц - нерезидентов, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='44024'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 197

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '52008'
, groupName = 'Обязательства'
, pokazatel = '52008 «Выпущенные облигации»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='52008'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 198

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '52018'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с выпуском и обращением облигаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='52018'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 199

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '52019'
, groupName = 'Обязательства'
, pokazatel = '52019 "Расчеты по расходам, связанным с выпуском и обращением облигаций"'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='52019'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 200

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '52020'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость выпущенных облигаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='52020'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 201

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '52021'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость выпущенных облигаций'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='52021'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 202

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '52022'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость выпущенных облигаций, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='52022'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 203

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '52023'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость выпущенных облигаций, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='52023'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 204

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '52308'
, groupName = 'Обязательства'
, pokazatel = 'Выпущенные векселя'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='52308'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 205

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '52318'
, groupName = 'Обязательства'
, pokazatel = 'Начисленные расходы, связанные с выпуском векселей'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='52318'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 206

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '52319'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по расходам, связанным с выпуском векселей'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='52319'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 207

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '52320'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, увеличивающие стоимость выпущенных векселей'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='52320'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 208

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '52321'
, groupName = 'Обязательства'
, pokazatel = 'Корректировки, уменьшающие стоимость выпущенных векселей'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='52321'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 209

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '52322'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, увеличивающая стоимость выпущенных векселей, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='52322'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 210

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '52323'
, groupName = 'Обязательства'
, pokazatel = 'Переоценка, уменьшающая стоимость выпущенных векселей, оцениваемых по справедливой стоимости через прибыль или убыток'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='52323'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 211

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '53701'
, groupName = 'Обязательства'
, pokazatel = 'Выпущенные цифровые финансовые активы, включающие денежные требования'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='53701'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 212

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '47407'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по конверсионным операциям, производным финансовым инструментам и прочим договорам (сделкам), по которым расчеты и поставка осуществляются не ранее следующего дня после дня заключения договора (сделки)'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='47407'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 213

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '47416'
, groupName = 'Обязательства'
, pokazatel = 'Суммы, поступившие на расчетные счета в кредитных организациях и банках-нерезидентах, до выяснения'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='47416'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 214

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '47422'
, groupName = 'Обязательства'
, pokazatel = '47422 «Обязательства по прочим финансовым операциям»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='47422'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 215

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '47903'
, groupName = 'Обязательства'
, pokazatel = 'Кредиторская задолженность по операциям доверительного управления'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='47903'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 216

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '60301'
, groupName = 'Обязательства'
, pokazatel = '60301 «Расчеты по налогам и сборам, кроме налога на прибыль»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60301'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 217

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '60305'
, groupName = 'Обязательства'
, pokazatel = '60305 «Обязательства по выплате краткосрочных вознаграждений работникам»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60305'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 218

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '60307'
, groupName = 'Обязательства'
, pokazatel = '60307 «Расчеты с работниками по подотчетным суммам»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60307'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 219

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '60311'
, groupName = 'Обязательства'
, pokazatel = '60311 «Расчеты с поставщиками и подрядчиками»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60311'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 220

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '60313'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты с организациями-нерезидентами по хозяйственным операциям'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60313'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 221

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '60320'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты с акционерами, участниками, пайщиками'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60320'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 222

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '60322'
, groupName = 'Обязательства'
, pokazatel = '60322 «Расчеты с прочими кредиторами»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60322'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 223

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '60328'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по налогу на прибыль'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60328'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 224

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '60331'
, groupName = 'Обязательства'
, pokazatel = '60331 «Расчеты с покупателями и клиентами»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60331'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 225

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '60333'
, groupName = 'Обязательства'
, pokazatel = 'Расчеты по договорам администрирования договоров обязательного пенсионного страхования и негосударственного пенсионного обеспечения'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60333'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 226

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '60335'
, groupName = 'Обязательства'
, pokazatel = '60335 «Расчеты по социальному страхованию и обеспечению»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60335'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 227

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.2
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = '60349'
, groupName = 'Обязательства'
, pokazatel = 'Обязательства по выплате долгосрочных вознаграждений работникам'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60349'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 228

--3.5.2 ИТОГО по Пункту
insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
select
REPMONTH = @repmonth
, punkt = '3.5.2'
, BS = ''
, groupName = 'Обязательства'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.5.2')
		  --and upper(a.groupName)=upper('требования по договорам микрозайма по начисленным процентам, а также по неустойке (штрафу, пене)')
		  )
, comment = 'Сумма всех BS пункта 3.5.2'
, rownum = 50
---------------------------------------------------------------------------------


insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5
select
REPMONTH = @repmonth
, punkt = '3.5'
, BS = ''
, groupName = 'Собственные средства (капитал)'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select sum(case when a.punkt ='3.5.2' then a.value*-1 else a.value end) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.5.1.7','3.5.1.2','3.5.1.1','3.5.2')
		  and a.pokazatel='ИТОГО по Пункту'
		  )
, comment = '3.5.1.7 + 3.5.1.2 + 3.5.1.1 - 3.5.2'
, rownum = 229

---------------------------------------------------------------------------------


insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.1
select
REPMONTH = @repmonth
, punkt = '3.1.1'
, BS = '48701'
, groupName = 'А1'
, pokazatel = '48701 «Микрозаймы (в том числе целевые микрозаймы), выданные юридическим лицам»'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.5.1.1')
		  and a.bs = '48701'
		  and upper(a.pokazatel) not like upper('%банкрот%')
		  )
, comment = 'Пункт 3.5.1.1 BS 48701'
, rownum = 231

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.1
select
REPMONTH = @repmonth
, punkt = '3.1.1'
, BS = '49401'
, groupName = 'А1'
, pokazatel = '49401 «Микрозаймы (в том числе целевые микрозаймы), выданные индивидуальным предпринимателям»'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.5.1.1')
		  and a.bs = '49401'
		  and upper(a.pokazatel) not like upper('%банкрот%')
		  )
, comment = 'Пункт 3.5.1.1 BS 49401'
, rownum = 232

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.1
select
REPMONTH = @repmonth
, punkt = '3.1.1'
, BS = '48702'
, groupName = 'А1'
, pokazatel = '48702 «Начисленные проценты по микрозаймам (в том числе по целевым микрозаймам), выданным юридическим лицам»'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.5.1.1')
		  and a.bs = '48702'
		  and upper(a.pokazatel) not like upper('%банкрот%')
		  )
, comment = 'Пункт 3.5.1.1 BS 48702'
, rownum = 233

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.1
select
REPMONTH = @repmonth
, punkt = '3.1.1'
, BS = '49402'
, groupName = 'А1'
, pokazatel = '49402 «Начисленные проценты по микрозаймам (в том числе по целевым микрозаймам), выданным индивидуальным предпринимателям»'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.5.1.1')
		  and a.bs = '49402'
		  and upper(a.pokazatel) not like upper('%банкрот%')
		  )
, comment = 'Пункт 3.5.1.1 BS 49402'
, rownum = 234

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.1
select
REPMONTH = @repmonth
, punkt = '3.1.1'
, BS = '48710'
, groupName = 'А1'
, pokazatel = '48710 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным юридическим лицам»'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.5.1.1')
		  and a.bs in ('48710')
		  and upper(a.pokazatel) not like upper('%банкрот%')
		  )
, comment = 'Пункт 3.5.1.1 BS 48710'
, rownum = 235

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.1
select
REPMONTH = @repmonth
, punkt = '3.1.1'
, BS = '49410'
, groupName = 'А1'
, pokazatel = '49410 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным индивидуальным предпринимателям»'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.5.1.1')
		  and a.bs in ('49410')
		  and upper(a.pokazatel) not like upper('%банкрот%')
		  )
, comment = 'Пункт 3.5.1.1 BS 49410'
, rownum = 236

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.1 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.1.1'
, BS = ''
, groupName = 'А1'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select sum(a.value) * 0.25
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.1.1')
		  )
, comment = 'Сумма всех BS пункта 3.1.1'
, rownum = 230

---------------------------------------------------------------------------------


insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.7
select
REPMONTH = @repmonth
, punkt = '3.1.7'
, BS = '48710'
, groupName = 'А1'
, pokazatel = '48710 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным юридическим лицам»'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.5.1.1')
		  and a.bs in ('48710')
		  and upper(a.pokazatel) not like upper('%банкрот%')
		  )
, comment = 'Пункт 3.5.1.1 BS 48710'
, rownum = 237

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.7
select
REPMONTH = @repmonth
, punkt = '3.1.7'
, BS = '49410'
, groupName = 'А1'
, pokazatel = '49410 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным индивидуальным предпринимателям»'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.5.1.1')
		  and a.bs in ('49410')
		  and upper(a.pokazatel) not like upper('%банкрот%')
		  )
, comment = 'Пункт 3.5.1.1 BS 49410'
, rownum = 238

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.2
select
REPMONTH = @repmonth
, punkt = '3.1.2'
, BS = ''
, groupName = 'А2'
, pokazatel = 'Сумма требований по основному долгу и начисленным процентным доходам (включая проценты за пользование потребительским займом, любые установленные договором потребительского займа доходы, а также неустойку (штрафы, пени) в суммах, присужденных судом или признанных должником, на дату вступления решения суда в законную силу или на дату признания должником) по договорам потребительского займа, заключенным на срок до 30 дней включительно в сумме до 30 тысяч рублей включительно'
, value = (
		  select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  from #PBR a
		  where 1=1
		  and a.dogPeriodDays <= 30
		  and a.dogSum <=30000
		  )
, comment = 'ПБР: Займы у которых в графе "Срок договора в днях" (Y) срок до 30 дней включительно И в графе "Сумма займа" (Z) сумма до 30 тысяч рублей включительно "Задолженность ОД" (AV) + "Задолженность проценты" (AW)  + "Сумма пени" (AX)'
, rownum = 240

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.2
select
REPMONTH = @repmonth
, punkt = '3.1.2'
, BS = ''
, groupName = 'А2'
, pokazatel = 'Резервы под требованиям'
, value = (
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and a.dogPeriodDays <= 30
		  and a.dogSum <=30000
		  ) * -1
, comment = 'ПБР: Займы у которых в графе "Срок договора в днях" (Y) срок до 30 дней включительно И в графе "Сумма займа" (Z) сумма до 30 тысяч рублей включительно  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 241



insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.2 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.1.2'
, BS = ''
, groupName = 'А2'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select --sum(case when a.pokazatel='Резервы под требованиям' then a.value * -1 else a.value end) * 0.1
		  sum(a.value) * 0.1
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.1.2')
		  )
, comment = 'Сумма ОД+ПРОЦЕНТЫ - Резервы пункта 3.1.2 * 10%'
, rownum = 239

---------------------------------------------------------------------------------

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.8
select
REPMONTH = @repmonth
, punkt = '3.1.8'
, BS = ''
, groupName = 'А2'
, pokazatel = 'Резервы под требованиям'
, value = (
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and a.dogPeriodDays <= 30
		  and a.dogSum <=30000
		  ) * -1
, comment = 'ПБР: Займы у которых в графе "Срок договора в днях" (Y) срок до 30 дней включительно И в графе "Сумма займа" (Z) сумма до 30 тысяч рублей включительно  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 242

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.3
select
REPMONTH = @repmonth
, punkt = '3.1.3'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств до 28.02.2022'
, pokazatel = 'Сумма требований по основному долгу и начисленным процентным доходам'
, value = (
		  select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  --select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and (a.PDNOnRepDate > 0.5 and a.PDNOnRepDate <= 0.8)
		  and a.saleDate <=CAST('2022-02-28' as date)
		  )
, comment = 'ПБР: отбираем займы, у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 50% И меньше или равно 80% В расчет берутся займы с датой выдачи (графа "Дата выдачи" (R))  по 28/29.2022 включительно "Задолженность ОД" (AV) + "Задолженность проценты" (AW)  + "Сумма пени" (AX)'
, rownum = 244

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.3
select
REPMONTH = @repmonth
, punkt = '3.1.3'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств до 28.02.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and (a.PDNOnRepDate > 0.5 and a.PDNOnRepDate <= 0.8)
		  and a.saleDate <=CAST('2022-02-28' as date)
		  ) * -1
, comment = 'ПБР: отбираем займы, у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 50% И меньше или равно 80% В расчет берутся займы с датой выдачи (графа "Дата выдачи" (R))  по 28/29.2022 включительно  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 245

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.3 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.1.3'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств до 28.02.2022'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select 
		  --sum(case when a.pokazatel='Резервы под требованиям' then a.value * -1 else a.value end) * 0
		  sum(a.value) * 0
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.1.3')
		  and upper(a.groupName) = upper('А3 (80 > ПДН > 50) Предоставление средств до 28.02.2022')
		  )
, comment = 'Сумма ОД+ПРОЦЕНТЫ - Резервы пункта 3.1.3 * 0% группы А3 (80 > ПДН > 50) Предоставление средств до 28.02.2022'
, rownum = 243

---------------------------------------------------------------------------------

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.9
select
REPMONTH = @repmonth
, punkt = '3.1.9'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств до 28.02.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and (a.PDNOnRepDate > 0.5 and a.PDNOnRepDate <= 0.8)
		  and a.saleDate <=CAST('2022-02-28' as date)
		  ) * -1
, comment = 'ПБР: отбираем займы, у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 50% И меньше или равно 80% В расчет берутся займы с датой выдачи (графа "Дата выдачи" (R))  по 28/29.2022 включительно  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 246

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.3
select
REPMONTH = @repmonth
, punkt = '3.1.3'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.03.2022'
, pokazatel = 'Сумма требований по основному долгу и начисленным процентным доходам'
, value = (
		  select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  --select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and (a.PDNOnRepDate > 0.5 and a.PDNOnRepDate <= 0.8)
		  and (a.saleDate >= CAST('2022-03-01' as date) and a.saleDate <= CAST('2022-09-30' as date))
		  )
, comment = 'ПБР: отбираем займы, у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 50% И меньше или равно 80% В расчет берутся займы с датой выдачи (графа "Дата выдачи" (R)), начиная с 01.03.2022 по 30.09.2022 включительно "Задолженность ОД" (AV) + "Задолженность проценты" (AW)  + "Сумма пени" (AX)'
, rownum = 248

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.3
select
REPMONTH = @repmonth
, punkt = '3.1.3'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.03.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and (a.PDNOnRepDate > 0.5 and a.PDNOnRepDate <= 0.8)
		  and (a.saleDate >= CAST('2022-03-01' as date) and a.saleDate <= CAST('2022-09-30' as date))
		  ) * -1
, comment = 'ПБР: отбираем займы, у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 50% И меньше или равно 80% В расчет берутся займы с датой выдачи (графа "Дата выдачи" (R)), начиная с 01.03.2022 по 30.09.2022 включительно  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 249

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.3 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.1.3'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.03.2022'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select 
		  --sum(case when a.pokazatel='Резервы под требованиям' then a.value * -1 else a.value end) * 0
		  sum(a.value) * 0
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.1.3')
		  and upper(a.groupName) = upper('А3 (80 > ПДН > 50) Предоставление средств с 01.03.2022')
		  )
, comment = 'Сумма ОД+ПРОЦЕНТЫ - Резервы пункта 3.1.3 * 0% группы А3 (80 > ПДН > 50) Предоставление средств с 01.03.2022'
, rownum = 247

---------------------------------------------------------------------------------

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.9
select
REPMONTH = @repmonth
, punkt = '3.1.9'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.03.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and (a.PDNOnRepDate > 0.5 and a.PDNOnRepDate <= 0.8)
		  and (a.saleDate >= CAST('2022-03-01' as date) and a.saleDate <= CAST('2022-09-30' as date))
		  ) * -1
, comment = 'ПБР: отбираем займы, у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 50% И меньше или равно 80% В расчет берутся займы с датой выдачи (графа "Дата выдачи" (R)), начиная с 01.03.2022 по 30.09.2022 включительно  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 250

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.3
select
REPMONTH = @repmonth
, punkt = '3.1.3'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.10.2022'
, pokazatel = 'Сумма требований по основному долгу и начисленным процентным доходам'
, value = (
		  select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  --select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and (a.PDNOnRepDate > 0.5 and a.PDNOnRepDate <= 0.8)
		  and (a.saleDate >= CAST('2022-10-01' as date) and a.saleDate <= CAST('2022-10-31' as date))
		  )
, comment = 'ПБР: отбираем займы, у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 50% И меньше или равно 80% В расчет берутся займы с датой выдачи (графа "Дата выдачи" (R)), начиная с 01.10.2022 по 31.10.2022 включительно Значение показателя А3 = "Задолженность ОД" (AV) + "Задолженность проценты" (AW)  + "Сумма пени" (AX)'
, rownum = 252

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.3
select
REPMONTH = @repmonth
, punkt = '3.1.3'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.10.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and (a.PDNOnRepDate > 0.5 and a.PDNOnRepDate <= 0.8)
		  and (a.saleDate >= CAST('2022-10-01' as date) and a.saleDate <= CAST('2022-10-31' as date))
		  ) * -1
, comment = 'ПБР: отбираем займы, у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 50% И меньше или равно 80% В расчет берутся займы с датой выдачи (графа "Дата выдачи" (R)), начиная с 01.10.2022 по 31.10.2022 включительно  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 253

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.3 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.1.3'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.10.2022'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select 
		  --sum(case when a.pokazatel='Резервы под требованиям' then a.value * -1 else a.value end) * 0
		  sum(a.value) * 0
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.1.3')
		  and upper(a.groupName) = upper('А3 (80 > ПДН > 50) Предоставление средств с 01.10.2022')
		  )
, comment = 'Сумма ОД+ПРОЦЕНТЫ - Резервы пункта 3.1.3 * 0% группы А3 (80 > ПДН > 50) Предоставление средств с 01.10.2022'
, rownum = 251

---------------------------------------------------------------------------------

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.9
select
REPMONTH = @repmonth
, punkt = '3.1.9'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.10.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and (a.PDNOnRepDate > 0.5 and a.PDNOnRepDate <= 0.8)
		  and (a.saleDate >= CAST('2022-10-01' as date) and a.saleDate <= CAST('2022-10-31' as date))
		  ) * -1
, comment = 'ПБР: отбираем займы, у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 50% И меньше или равно 80% В расчет берутся займы с датой выдачи (графа "Дата выдачи" (R)), начиная с 01.10.2022 по 31.10.2022 включительно  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 254

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.3
select
REPMONTH = @repmonth
, punkt = '3.1.3'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.11.2022'
, pokazatel = 'Сумма требований по основному долгу и начисленным процентным доходам'
, value = (
		  select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  --select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and (a.PDNOnRepDate > 0.5 and a.PDNOnRepDate <= 0.8)
		  and a.saleDate >= CAST('2022-11-01' as date)
		  )
, comment = 'ПБР: отбираем займы, у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 50% И меньше или равно 80% В расчет берутся займы с датой выдачи (графа "Дата выдачи" (R)), начиная с 01.11.2022  "Задолженность ОД" (AV) + "Задолженность проценты" (AW)  + "Сумма пени" (AX)'
, rownum = 256

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.3
select
REPMONTH = @repmonth
, punkt = '3.1.3'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.11.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and (a.PDNOnRepDate > 0.5 and a.PDNOnRepDate <= 0.8)
		  and a.saleDate >= CAST('2022-11-01' as date)
		  ) * -1
, comment = 'ПБР: отбираем займы, у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 50% И меньше или равно 80% В расчет берутся займы с датой выдачи (графа "Дата выдачи" (R)), начиная с 01.11.2022  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 257

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.3 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.1.3'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.11.2022'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select 
		  --sum(case when a.pokazatel='Резервы под требованиям' then a.value * -1 else a.value end) * 150 / 100
		  sum(a.value) * 150 / 100
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.1.3')
		  and upper(a.groupName) = upper('А3 (80 > ПДН > 50) Предоставление средств с 01.11.2022')
		  )
, comment = 'Сумма ОД+ПРОЦЕНТЫ - Резервы пункта 3.1.3 * 150% группы А3 (80 > ПДН > 50) Предоставление средств с 01.11.2022'
, rownum = 255

---------------------------------------------------------------------------------

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.9
select
REPMONTH = @repmonth
, punkt = '3.1.9'
, BS = ''
, groupName = 'А3 (80 > ПДН > 50) Предоставление средств с 01.11.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and (a.PDNOnRepDate > 0.5 and a.PDNOnRepDate <= 0.8)
		  and a.saleDate >= CAST('2022-11-01' as date)
		  ) * -1
, comment = 'ПБР: отбираем займы, у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 50% И меньше или равно 80% В расчет берутся займы с датой выдачи (графа "Дата выдачи" (R)), начиная с 01.11.2022  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 258

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.4
select
REPMONTH = @repmonth
, punkt = '3.1.4'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств до 28.02.2022'
, pokazatel = 'Сумма требований по основному долгу и начисленным процентным доходам'
, value = (
		  select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  --select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and a.PDNOnRepDate > 0.8
		  and a.saleDate <= CAST('2022-02-28' as date)
		  )
, comment = 'ПБР: отбираем займы, у которых у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 80% Средства по договору займа предоставлены (графа "Дата выдачи" (R))  по 28/29.02.2022 "Задолженность ОД" (AV) + "Задолженность проценты" (AW)  + "Сумма пени" (AX)'
, rownum = 260

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.4
select
REPMONTH = @repmonth
, punkt = '3.1.4'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств до 28.02.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and a.PDNOnRepDate > 0.8
		  and a.saleDate <= CAST('2022-02-28' as date)
		  )* -1
, comment = 'ПБР: отбираем займы, у которых у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 80% Средства по договору займа предоставлены (графа "Дата выдачи" (R))  по 28/29.02.2022  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 261

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.4 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.1.4'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств до 28.02.2022'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select 
		  --sum(case when a.pokazatel='Резервы под требованиям' then a.value * -1 else a.value end) * 0
		  sum(a.value) * 0
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.1.4')
		  and upper(a.groupName) = upper('А4 (ПДН > 80) Предоставление средств до 28.02.2022')
		  )
, comment = 'Сумма ОД+ПРОЦЕНТЫ - Резервы пункта 3.1.4 * 0% группы А4 (ПДН > 80) Предоставление средств до 28.02.2022'
, rownum = 259

---------------------------------------------------------------------------------

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.10
select
REPMONTH = @repmonth
, punkt = '3.1.10'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств до 28.02.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and a.PDNOnRepDate > 0.8
		  and a.saleDate <= CAST('2022-02-28' as date)
		  ) * -1
, comment = 'ПБР: отбираем займы, у которых у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 80% Средства по договору займа предоставлены (графа "Дата выдачи" (R))  по 28/29.02.2022  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 262

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.4
select
REPMONTH = @repmonth
, punkt = '3.1.4'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств с 01.03.2022'
, pokazatel = 'Сумма требований по основному долгу и начисленным процентным доходам'
, value = (
		  select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  --select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and a.PDNOnRepDate > 0.8
		  and (a.saleDate >= CAST('2022-03-01' as date) and a.saleDate <= CAST('2022-09-30' as date))
		  )
, comment = 'ПБР: отбираем займы, у которых у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 80% Средства по договору займа предоставлены (графа "Дата выдачи" (R)) с  01.03.2022 по 30.09.2022 "Задолженность ОД" (AV) + "Задолженность проценты" (AW)  + "Сумма пени" (AX)'
, rownum = 264

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.4
select
REPMONTH = @repmonth
, punkt = '3.1.4'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств с 01.03.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and a.PDNOnRepDate > 0.8
		  and (a.saleDate >= CAST('2022-03-01' as date) and a.saleDate <= CAST('2022-09-30' as date))
		  )* -1
, comment = 'ПБР: отбираем займы, у которых у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 80% Средства по договору займа предоставлены (графа "Дата выдачи" (R)) с  01.03.2022 по 30.09.2022  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 265

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.4 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.1.4'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств с 01.03.2022'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select 
		  --sum(case when a.pokazatel='Резервы под требованиям' then a.value * -1 else a.value end) * 65 / 100
		  sum(a.value) * 65 / 100
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.1.4')
		  and upper(a.groupName) = upper('А4 (ПДН > 80) Предоставление средств с 01.03.2022')
		  )
, comment = 'Сумма ОД+ПРОЦЕНТЫ - Резервы пункта 3.1.4 * 65% группы А4 (ПДН > 80) Предоставление средств до 28.02.2022'
, rownum = 263

---------------------------------------------------------------------------------
insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.10
select
REPMONTH = @repmonth
, punkt = '3.1.10'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств с 01.03.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and a.PDNOnRepDate > 0.8
		  and (a.saleDate >= CAST('2022-03-01' as date) and a.saleDate <= CAST('2022-09-30' as date))
		  )* -1
, comment = 'ПБР: отбираем займы, у которых у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 80% Средства по договору займа предоставлены (графа "Дата выдачи" (R)) с  01.03.2022 по 30.09.2022  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 266

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.4
select
REPMONTH = @repmonth
, punkt = '3.1.4'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств с 01.10.2022'
, pokazatel = 'Сумма требований по основному долгу и начисленным процентным доходам'
, value = (
		  select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  --select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and a.PDNOnRepDate > 0.8
		  and (a.saleDate >= CAST('2022-10-01' as date) and a.saleDate <= CAST('2022-10-31' as date))
		  )
, comment = 'ПБР: отбираем займы, у которых у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 80% Средства по договору займа предоставлены (графа "Дата выдачи" (R)) с 01.10.2022 по 31.10.2022 "Задолженность ОД" (AV) + "Задолженность проценты" (AW)  + "Сумма пени" (AX)'
, rownum = 268

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.4
select
REPMONTH = @repmonth
, punkt = '3.1.4'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств с 01.10.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and a.PDNOnRepDate > 0.8
		  and (a.saleDate >= CAST('2022-10-01' as date) and a.saleDate <= CAST('2022-10-31' as date))
		  )* -1
, comment = 'ПБР: отбираем займы, у которых у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 80% Средства по договору займа предоставлены (графа "Дата выдачи" (R)) с 01.10.2022 по 31.10.2022  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 269

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.4 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.1.4'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств с 01.10.2022'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select 
		  --sum(case when a.pokazatel='Резервы под требованиям' then a.value * -1 else a.value end) * 200 / 100
		  sum(a.value) * 200 / 100
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.1.4')
		  and upper(a.groupName) = upper('А4 (ПДН > 80) Предоставление средств с 01.10.2022')
		  )
, comment = 'Сумма ОД+ПРОЦЕНТЫ - Резервы пункта 3.1.4 * 200% группы А4 (ПДН > 80) Предоставление средств с 01.10.2022'
, rownum = 267

---------------------------------------------------------------------------------
insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.10
select
REPMONTH = @repmonth
, punkt = '3.1.10'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств с 01.10.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and a.PDNOnRepDate > 0.8
		  and (a.saleDate >= CAST('2022-10-01' as date) and a.saleDate <= CAST('2022-10-31' as date))
		  )* -1
, comment = 'ПБР: отбираем займы, у которых у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 80% Средства по договору займа предоставлены (графа "Дата выдачи" (R)) с 01.10.2022 по 31.10.2022  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 270


insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.4
select
REPMONTH = @repmonth
, punkt = '3.1.4'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств с 01.11.2022'
, pokazatel = 'Сумма требований по основному долгу и начисленным процентным доходам'
, value = (
		  select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  --select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and a.PDNOnRepDate > 0.8
		  and a.saleDate >= CAST('2022-11-01' as date)
		  )
, comment = 'ПБР: отбираем займы, у которых у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 80% Средства по договору займа предоставлены (графа "Дата выдачи" (R)) с 01.11.2022 "Задолженность ОД" (AV) + "Задолженность проценты" (AW)  + "Сумма пени" (AX)'
, rownum = 272

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.4
select
REPMONTH = @repmonth
, punkt = '3.1.4'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств с 01.11.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and a.PDNOnRepDate > 0.8
		  and a.saleDate >= CAST('2022-11-01' as date)
		  )* -1
, comment = 'ПБР: отбираем займы, у которых у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 80% Средства по договору займа предоставлены (графа "Дата выдачи" (R)) с 01.11.2022  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 273

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.4 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.1.4'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств с 01.11.2022'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select 
		  --sum(case when a.pokazatel='Резервы под требованиям' then a.value * -1 else a.value end) * 200 / 100
		  sum(a.value) * 200 / 100
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.1.4')
		  and upper(a.groupName) = upper('А4 (ПДН > 80) Предоставление средств с 01.11.2022')
		  )
, comment = 'Сумма ОД+ПРОЦЕНТЫ - Резервы пункта 3.1.4 * 200% группы А4 (ПДН > 80) Предоставление средств с 01.11.2022'
, rownum = 271

---------------------------------------------------------------------------------
insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.10
select
REPMONTH = @repmonth
, punkt = '3.1.10'
, BS = ''
, groupName = 'А4 (ПДН > 80) Предоставление средств с 01.11.2022'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and a.PDNOnRepDate > 0.8
		  and a.saleDate >= CAST('2022-11-01' as date)
		  )* -1
, comment = 'ПБР: отбираем займы, у которых у которых заемщик ФЛ, в графе "ПДН на отчетную дату" (BX) значение  не пустое или не ноль И больше 80% Средства по договору займа предоставлены (графа "Дата выдачи" (R)) с 01.11.2022  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 274

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.5
select
REPMONTH = @repmonth
, punkt = '3.1.5'
, BS = ''
, groupName = 'А5 (ПДН пусто или 0)'
, pokazatel = 'Сумма требований по основному долгу и начисленным процентным доходам'
, value = (
		  select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  --select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and upper(a.isZaemshik) = upper('ФЛ')
		  and (a.PDNOnRepDate = 0 or a.PDNOnRepDate is null)
		  and (a.saleDate >= CAST('2022-11-01' as date) and a.saleDate <= CAST('2023-12-31' as date))
		  and a.dogSum < 10000
		  )
, comment = 'ПБР: отбираем займы, у которых заемщик ФЛ,  с датой выдачи (графа "Дата выдачи" (O)), больше или равно  01.11.2022 и меньше или равно 31.12.2023 И суммой выдачи  (графа "Сумма займа" (W)) строго меньше 10000 руб. И в графе "ПДН на отчетную дату" (BU) значение  пустое или  ноль "Задолженность ОД" (AV) + "Задолженность проценты" (AW)  + "Сумма пени" (AX)'
, rownum = 276

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.5
select
REPMONTH = @repmonth
, punkt = '3.1.5'
, BS = ''
, groupName = 'А5 (ПДН пусто или 0)'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and upper(a.isZaemshik) = upper('ФЛ')
		  and (a.PDNOnRepDate = 0 or a.PDNOnRepDate is null)
		  and (a.saleDate >= CAST('2022-11-01' as date) and a.saleDate <= CAST('2023-12-31' as date))
		  and a.dogSum < 10000
		  )* -1
, comment = 'ПБР: отбираем займы, у которых заемщик ФЛ,  с датой выдачи (графа "Дата выдачи" (O)), больше или равно  01.11.2022 и меньше или равно 31.12.2023 И суммой выдачи  (графа "Сумма займа" (W)) строго меньше 10000 руб. И в графе "ПДН на отчетную дату" (BU) значение  пустое или  ноль  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 277

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.5 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.1.5'
, BS = ''
, groupName = 'А5 (ПДН пусто или 0)'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select 
		  --sum(case when a.pokazatel='Резервы под требованиям' then a.value * -1 else a.value end) * 150 / 100
		  sum(a.value) * 150 / 100
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.1.5')
		  and upper(a.groupName) = upper('А5 (ПДН пусто или 0)')
		  )
, comment = 'Сумма ОД+ПРОЦЕНТЫ - Резервы пункта 3.1.5 * 150% группы А5 (ПДН пусто или 0)'
, rownum = 275

---------------------------------------------------------------------------------
insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1.11
select
REPMONTH = @repmonth
, punkt = '3.1.11'
, BS = ''
, groupName = 'А5 (ПДН пусто или 0)'
, pokazatel = 'Резервы под требованиям'
, value = (
		  --select sum(isnull(a.zadolgOD,0) + ISNULL(a.zadolgPrc,0) + ISNULL(a.penyaSum,0)) 
		  select sum(isnull(a.reservOD,0) + ISNULL(a.reservPRC,0) + ISNULL(a.reservProchSumNU,0)) 
		  from #PBR a
		  where 1=1
		  and upper(a.isZaemshik) = upper('ФЛ')
		  and (a.PDNOnRepDate = 0 or a.PDNOnRepDate is null)
		  and (a.saleDate >= CAST('2022-11-01' as date) and a.saleDate <= CAST('2023-12-31' as date))
		  and a.dogSum < 10000
		  )* -1
, comment = 'ПБР: отбираем займы, у которых заемщик ФЛ,  с датой выдачи (графа "Дата выдачи" (O)), больше или равно  01.11.2022 и меньше или равно 31.12.2023 И суммой выдачи  (графа "Сумма займа" (W)) строго меньше 10000 руб. И в графе "ПДН на отчетную дату" (BU) значение  пустое или  ноль  "Резерв ОД" (BG) + "Резерв проценты" (BI) + "Сумма резерва прочие НУ" (BN) '
, rownum = 278

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.1 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.1'
, BS = ''
, groupName = 'Норматив достаточности собственных средств микрофинансовой компании (НМФК1), %'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select 
			[val] = a.value / b.val2 * 100
			from finAnalytics.rep840_3_detail a
			left join (
			select val2 = sum(case when a.punkt='3.1.1' then a.value * -1 else a.value end)
			from finAnalytics.rep840_3_detail a
			where 1=1
			and a.REPMONTH=@repmonth
			and a.punkt in ('3.5.1.7','3.5.1.2','3.5.1.1','3.1.1','3.1.2','3.1.3','3.1.4','3.1.5')
			and a.pokazatel = 'ИТОГО по Пункту'
			) b on 1=1
			where 1=1
			and a.REPMONTH=@repmonth
			and a.punkt in ('3.5')
		  )
, comment = '3.5 /  (3.5.1.7 + 3.5.1.2 + 3.5.1.1 - 3.1.1 + 3.1.2 + 3.1.3 + 3.1.4 + 3.1.5) * 100'
, rownum = 279
---------------------------------------------------------------------------------

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.3
select
REPMONTH = @repmonth
, punkt = '3.2.1.3'
, BS = '20202'
, groupName = 'денежные средства'
, pokazatel = '20202 «Касса организации» '
, value = (
		  select isnull(SUM(isnull(restOUT_BU,0)),0) from #OSV where acc2order='20202'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 280

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.3
-- не хватает справочника Справочник.БанковскиеСчета - ждем проброски
select
REPMONTH = @repmonth
, punkt = '3.2.1.3'
, BS = '20501'
, groupName = 'денежные средства'
, pokazatel = '20501 «Расчетные счета в кредитных организациях»'
, value = (
		  select isnull(SUM(isnull(case when lic.accNum IS not null and lic.licReturnDate>EOMONTH(@repmonth) then 0 else restOUT_BU end,0)),0)
		  from #OSV a
		  left join finAnalytics.SPR_BanksWOLicense lic on a.accNum=lic.accNum
		  where a.acc2order='20501'
		  )
, comment = 'не хватает справочника Справочник.БанковскиеСчета - ждем проброски--Баланс. Сальдо на конец периода по дебету'
, rownum = 281

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.3
select
REPMONTH = @repmonth
, punkt = '3.2.1.3'
, BS = '20601'
, groupName = 'денежные средства'
, pokazatel = '20601 "Депозиты в кредитных организациях"'
, value = (
		  select isnull(SUM(isnull(restOUT_BU,0)),0) from #OSV where acc2order='20601'
		  )
, comment = 'Баланс. Сальдо на конец периода по дебету'
, rownum = 282

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.3
select
REPMONTH = @repmonth
, punkt = '3.2.1.3'
, BS = '47423'
, groupName = 'денежные средства'
, pokazatel = '47423 «Требования по прочим финансовым операциям»'
, value = (
		  select isnull(SUM(isnull(restOUT_BU,0)),0)
		  from #OSV a
		  left join stg._1cUMFO.Справочник_Контрагенты cl on a.subconto1UID=cl.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		  left join stg._1cUMFO.Справочник_Контрагенты cl2 on cl.Родитель=cl2.Ссылка and cl.ИННВведенКорректно=0x01 and cl.ПометкаУдаления=0x00 
		  left join finAnalytics.SPR_BanksWOLicense lic on upper(cl.Наименование) = lic.bankName
		  where acc2order='47423'
		  and upper(cl2.Наименование) = UPPER('Платежные системы')
		  and (lic.bankName is null or lic.licReturnDate >=eomonth(@repmonth))
		  )
, comment = 'Счет 47423 - остаток на дату отчета по счетам компаний, являющихся операторами по переводу денежных средств, за минусом остатка по КО с отозванной лицензией (см. выше). По счету 47423 в расчет строки берутся остатки только по тем Контрагентам, которые классифицированы в 1С-УМФО как Платежная система (юр.лица и КО)'
, rownum = 283

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.5.1.7 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.2.1.3'
, BS = ''
, groupName = 'денежные средства'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.2.1.3')
		  )
, comment = 'Сумма BS 20202, 20501, 20601, 47423'
, rownum = 284
---------------------------------------------------------------------------------

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.1
select
REPMONTH = @repmonth
, punkt = '3.2.1.1'
, BS = '48801'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '48801 «Микрозаймы (в том числе целевые микрозаймы), выданные физическим лицам»'
, value = (
		  select isnull(SUM(isnull(minOD,0)),0) from #TERMS where substring(accNum,1,5) = '48801'
		  )
, comment = 'ОД по сроку до 90 дней = MIN из остатка на счете ОД (S) и суммы значений в графах  "До востребования или на 1 день" (U), "До 30 дней" (V), "От 30 дней ≤ 90 дней" (W) по договору, у которого в графе А Отчета по срокам погашения БУ счет начинается на 48801'
, rownum = 286

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.2
select
REPMONTH = @repmonth
, punkt = '3.2.2'
, BS = '48810'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '48810 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным физическим лицам»'
, value = (
		  select isnull(SUM(isnull(reservOD90,0)),0) * -1 from #TERMS where substring(accNum,1,5) = '48801'
		  )
, comment = 'Резерв по ОД по сроку до 90 дней = ОД по сроку до 90 дней *  Ставка резерва по договору /100, у которого в графе А Отчета по срокам погашения БУ счет начинается на 48801'
, rownum = 287


insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.1
select
REPMONTH = @repmonth
, punkt = '3.2.1.1'
, BS = '48802'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '48802 «Начисленные проценты по микрозаймам (в том числе по целевым микрозаймам), выданным физическим лицам»'
/* Бурлакова сказала обнулить 04.02.2025
, value = (
		  select isnull(SUM(isnull(returnPRC_1,0)+isnull(returnPRC_30,0)+isnull(returnPRC_90,0)),0) 
		  from #TERMS where substring(accNum,1,5) = '48802' and prosBeginDate is null and (prosAll is null or prosAll=0) and isKK377 is NULL and upper(isKK)='ДА'
		  )
*/
, value =0
, comment = 'Дата начала просрочки - пустое, Дата дней просрочки - пустое, Банкротство - НЕТ, Кредитные каникулы по 377-ФЗ - Пустое, Кредитные каникулы - Да = суммы значений в графе "Сумма погашения процентов" "До востребования или на 1 день", "До 30 дней", "От 30 дней ≤ 90 дней" по договору, у которого в графе "Счет аналитического учета" Отчета по срокам погашения БУ счет начинается на 48802'
, rownum = 288

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.2
select
REPMONTH = @repmonth
, punkt = '3.2.2'
, BS = '48820'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '48820 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным физическим лицам»'
/* Бурлакова сказала обнулить 04.02.2025
, value = (
		  select isnull(SUM(isnull(reservPRC90,0)),0) * -1 
		  from #TERMS where substring(accNum,1,5) = '48802' and prosBeginDate is null and (prosAll is null or prosAll=0) and isKK377 is NULL and upper(isKK)='ДА'
		  )
*/
, value =0
, comment = 'Резерв по ОД по сроку до 90 дней = ОД по сроку до 90 дней *  Ставка резерва по договору /100, у которого в графе А Отчета по срокам погашения БУ счет начинается на 48801'
, rownum = 289


insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.6
select
REPMONTH = @repmonth
, punkt = '3.2.1.6'
, BS = '48802'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '48802 «Начисленные проценты по микрозаймам (в том числе по целевым микрозаймам), выданным физическим лицам»'
, value = (
		  select isnull(SUM(isnull(minPRC,0)),0) from #TERMS where substring(accNum,1,5) = '48801' or substring(accNum,1,5) = '48802'
		  )
, comment = '% по сроку 90 дней = MIN из остатка на счете процентов (T) и суммы значений в графах  "До востребования или на 1 день" (AB), "До 30 дней" (AC), "От 30 дней ≤ 90 дней" (AD) по договору, у которого в графе А Отчета по срокам погашения БУ счет начинается на 48801'
, rownum = 290

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.6
select
REPMONTH = @repmonth
, punkt = '3.2.1.6'
, BS = '48810'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '48810 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным физическим лицам»'
, value = (
		  select isnull(SUM(isnull(reservPRC90,0)),0) * -1 from #TERMS where substring(accNum,1,5) = '48801' or substring(accNum,1,5) = '48802'
		  )
, comment = 'Резерв по % по сроку 90 дней = % по сроку 90 дней *  Ставка резерва по договору /100 по договору, у которого в графе А Отчета по срокам погашения БУ счет начинается на 48801 *-1'
, rownum = 291

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.1
select
REPMONTH = @repmonth
, punkt = '3.2.1.1'
, BS = '48501'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '48501 «Займы, предоставленные юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(minOD,0)),0)  from #TERMS where substring(accNum,1,5) = '48501'
		  )
, comment = 'ОД по сроку до 90 дней = MIN из остатка на счете ОД (S) и суммы значений в графах  "До востребования или на 1 день" (U), "До 30 дней" (V), "От 30 дней ≤ 90 дней" (W) по договору, у которого в графе А Отчета по срокам погашения БУ счет начинается на 48501'
, rownum = 292

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.2
select
REPMONTH = @repmonth
, punkt = '3.2.2'
, BS = '48510'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '48510 «Резервы под обесценение по займам, выданным юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(reservOD90,0)),0) * -1 from #TERMS where substring(accNum,1,5) = '48501'
		  )
, comment = 'Резерв по ОД по сроку до 90 дней = ОД по сроку до 90 дней *  Ставка резерва по договору /100, у которого в графе А Отчета по срокам погашения БУ счет начинается на 48501 *-1'
, rownum = 293

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.6
select
REPMONTH = @repmonth
, punkt = '3.2.1.6'
, BS = '48502'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '48502 «Начисленные проценты по займам, предоставленным юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(minPRC,0)),0)  from #TERMS where substring(accNum,1,5) = '48501'
		  )
, comment = '% по сроку 90 дней = MIN из остатка на счете процентов (T) и суммы значений в графах  "До востребования или на 1 день" (AB), "До 30 дней" (AC), "От 30 дней ≤ 90 дней" (AD) по договору, у которого в графе А Отчета по срокам погашения БУ счет начинается на 48501'
, rownum = 294

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.6
select
REPMONTH = @repmonth
, punkt = '3.2.1.6'
, BS = '48510'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '48510 «Резервы под обесценение по займам, выданным юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(reservPRC90,0)),0) * -1  from #TERMS where substring(accNum,1,5) = '48501'
		  )
, comment = 'Резерв по % по сроку 90 дней = % по сроку 90 дней *  Ставка резерва по договору /100 по договору, у которого в графе А Отчета по срокам погашения БУ счет начинается на 48501'
, rownum = 295

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.1
select
REPMONTH = @repmonth
, punkt = '3.2.1.1'
, BS = '48701'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '48701 «Микрозаймы (в том числе целевые микрозаймы), выданные юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(minOD,0)),0)   from #TERMS where substring(accNum,1,5) = '48701'
		  )
, comment = 'ОД по сроку до 90 дней = MIN из остатка на счете ОД (S) и суммы значений в графах  "До востребования или на 1 день" (U), "До 30 дней" (V), "От 30 дней ≤ 90 дней" (W) по договору, у которого в графе А Отчета по срокам погашения БУ счет начинается на 48701'
, rownum = 296

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.2
select
REPMONTH = @repmonth
, punkt = '3.2.2'
, BS = '48710'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '48710 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(reservOD90,0)),0) * -1   from #TERMS where substring(accNum,1,5) = '48701'
		  )
, comment = 'Резерв по ОД по сроку до 90 дней = ОД по сроку до 90 дней *  Ставка резерва по договору /100, у которого в графе А Отчета по срокам погашения БУ счет начинается на 48701 * -1'
, rownum = 297

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.6
select
REPMONTH = @repmonth
, punkt = '3.2.1.6'
, BS = '48702'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '48702 «Начисленные проценты по микрозаймам (в том числе по целевым микрозаймам), выданным юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(minPRC,0)),0) from #TERMS where substring(accNum,1,5) = '48701'
		  )
, comment = '% по сроку 90 дней = MIN из остатка на счете процентов (T) и суммы значений в графах  "До востребования или на 1 день" (AB), "До 30 дней" (AC), "От 30 дней ≤ 90 дней" (AD) по договору, у которого в графе А Отчета по срокам погашения БУ счет начинается на 48701'
, rownum = 298

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.6
select
REPMONTH = @repmonth
, punkt = '3.2.1.6'
, BS = '48710'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '48710 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным юридическим лицам»'
, value = (
		  select isnull(SUM(isnull(reservPRC90,0)),0) * -1 from #TERMS where substring(accNum,1,5) = '48701'
		  )
, comment = 'Резерв по % по сроку 90 дней = % по сроку 90 дней *  Ставка резерва по договору /100 по договору, у которого в графе А Отчета по срокам погашения БУ счет начинается на 48701 * -1'
, rownum = 299

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.1
select
REPMONTH = @repmonth
, punkt = '3.2.1.1'
, BS = '49401'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '49401 «Микрозаймы (в том числе целевые микрозаймы), выданные индивидуальным предпринимателям»'
, value = (
		  select isnull(SUM(isnull(minOD,0)),0)  from #TERMS where substring(accNum,1,5) = '49401'
		  )
, comment = 'ОД по сроку до 90 дней = MIN из остатка на счете ОД (S) и суммы значений в графах  "До востребования или на 1 день" (U), "До 30 дней" (V), "От 30 дней ≤ 90 дней" (W) по договору, у которого в графе А Отчета по срокам погашения БУ счет начинается на 49401'
, rownum = 300

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.2
select
REPMONTH = @repmonth
, punkt = '3.2.2'
, BS = '49410'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '49410 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным индивидуальным предпринимателям»'
, value = (
		  select isnull(SUM(isnull(reservOD90,0)),0) * -1  from #TERMS where substring(accNum,1,5) = '49401'
		  )
, comment = 'Резерв по ОД по сроку до 90 дней = ОД по сроку до 90 дней *  Ставка резерва по договору /100, у которого в графе А Отчета по срокам погашения БУ счет начинается на 49401 * -1'
, rownum = 301

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.6
select
REPMONTH = @repmonth
, punkt = '3.2.1.6'
, BS = '49402'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '49402 «Начисленные проценты по микрозаймам (в том числе по целевым микрозаймам), выданным индивидуальным предпринимателям»'
, value = (
		  select isnull(SUM(isnull(minPRC,0)),0) from #TERMS where substring(accNum,1,5) = '49401'
		  )
, comment = '% по сроку 90 дней = MIN из остатка на счете процентов (T) и суммы значений в графах  "До востребования или на 1 день" (AB), "До 30 дней" (AC), "От 30 дней ≤ 90 дней" (AD) по договору, у которого в графе А Отчета по срокам погашения БУ счет начинается на 49401'
, rownum = 302

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.1.6
select
REPMONTH = @repmonth
, punkt = '3.2.1.6'
, BS = '49410'
, groupName = 'микрозаймы со сроком возврата до 90 дней'
, pokazatel = '49410 «Резервы под обесценение по микрозаймам (в том числе целевым микрозаймам), выданным индивидуальным предпринимателям»'
, value = (
		  select isnull(SUM(isnull(reservPRC90,0)),0) * -1 from #TERMS where substring(accNum,1,5) = '49401'
		  )
, comment = 'Резерв по % по сроку 90 дней = % по сроку 90 дней *  Ставка резерва по договору /100 по договору, у которого в графе А Отчета по срокам погашения БУ счет начинается на 49401 * -1'
, rownum = 303

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '60301'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '60301 «Расчеты по налогам и сборам, кроме налога на прибыль»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60301'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 304

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '60305'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '60305 «Обязательства по выплате краткосрочных вознаграждений работникам»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60305'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 305

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '60307'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '60307 «Расчеты с работниками по подотчетным суммам»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60307'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 306

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '60806'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '60806 «Арендные обязательства»'
, value = (
		  select isnull(sum(ISNULL(a.sum90days,0)),0)
		  from #ARENDA a
		  where 1=1
		  --and a.acc2order='60307'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 307

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '60311'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '60311 «Расчеты с поставщиками и подрядчиками»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60311'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 308

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '60313'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '60313 «Расчеты с организациями-нерезидентами по хозяйственным операциям»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60313'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 309

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '60320'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '60320 «Расчеты с акционерами, участниками, пайщиками»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60320'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 310

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '60322'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '60322 «Расчеты с прочими кредиторами»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60322'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 311

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '60328'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '60328 «Расчеты по налогу на прибыль»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60328'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 312

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '60331'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '60331 «Расчеты с покупателями и клиентами»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60331'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 313

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '60335'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '60335 «Расчеты по социальному страхованию и обеспечению»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60335'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 314

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '60349'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '60349 «Обязательства по выплате долгосрочных вознаграждений работникам»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='60349'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 315

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '42316'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '42316 «Привлеченные средства физических лиц»'
, value = (
		  select isnull(sum(ISNULL(a.restOD,0)),0)
		  --select isnull(sum(ISNULL(a.restPRC,0)),0)
		  from #DEPO a
		  where 1=1
		  and substring(a.accOD,1,5)='42316'
		  --and substring(a.accPRC,1,5)='42317'
		  --and (upper(a.capitalType) = upper('капитализация') or a.capitalType is null)
		  and a.daysBetween < 90--between 1 and 90 https://tracker.yandex.ru/FINA-228
		  )
, comment = 'Портфель сбережений: Отбираются остатки из графы Q (Остаток по ОД) для записей, у которых в графе P (Счет ОД) счет начинается на 42316 и срок погашения от 1 до 90'
, rownum = 316

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '42317'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '42317 «Начисленные проценты (к уплате) по привлеченным средствам физических лиц»'
, value = (
		  --select isnull(sum(ISNULL(a.restOD,0)),0)
		  select 
		  --isnull(sum(ISNULL(a.restPRC,0)),0)
		  isnull(sum(case	
						when a.capitalType is null then isnull(a.restPRC,0)
						when a.capitalType is not null and a.daysBetween < 90 /*between 0 and 90 https://tracker.yandex.ru/FINA-228*/ then isnull(a.restPRC,0)
						--when upper(a.capitalType) = upper('Выплата в конце срока') and a.daysBetween > 90 then 0 else isnull(a.restPRC,0) end),0)
						else 0 end),0)
		  from #DEPO a
		  where 1=1
		  --and substring(a.accOD,1,5)='42316'
		  and substring(a.accPRC,1,5)='42317'
		  --and a.capitalType is null
		  --and not (upper(a.capitalType) = upper('Выплата в конце срока') and a.daysBetween > 90)
		  --and a.daysBetween between 1 and 90
		  )
, comment = 'Портфель сбережений: Отбираются остатки из графы U (Остаток по %) для записей, у которых в графе T (Счет %) счет начинается на 42317'
, rownum = 317

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '43708'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '43708 «Привлеченные средства негосударственных финансовых организаций»'
, value = (
		  select isnull(sum(ISNULL(a.restOD,0)),0)
		  --select isnull(sum(ISNULL(a.restPRC,0)),0)
		  from #DEPO a
		  where 1=1
		  and substring(a.accOD,1,5)='43708'
		  --and substring(a.accPRC,1,5)='43708'
		  --and not (upper(a.capitalType) = upper('Выплата в конце срока') and a.daysBetween > 90)
		  and a.daysBetween < 90 -- between 1 and 90 https://tracker.yandex.ru/FINA-228
		  )
, comment = 'Портфель сбережений: Отбираются остатки из графы Q (Остаток по ОД) для записей, у которых в графе P (Счет ОД) счет начинается на 43708'
, rownum = 318

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '43709'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '43709 «Начисленные проценты (к уплате) по привлеченным средствам негосударственных финансовых организаций»'
, value = (
		  --select isnull(sum(ISNULL(a.restOD,0)),0)
		  select 
		  --isnull(sum(ISNULL(a.restPRC,0)),0)
		  isnull(sum(case when upper(a.capitalType) = upper('Выплата в конце срока') and a.daysBetween > 90 then 0 else isnull(a.restPRC,0) end),0)
		  from #DEPO a
		  where 1=1
		  --and substring(a.accOD,1,5)='43708'
		  and substring(a.accPRC,1,5)='43709'
		  --and not (upper(a.capitalType) = upper('Выплата в конце срока') and a.daysBetween > 90)
		  --and a.daysBetween between 1 and 90
		  )
, comment = 'Портфель сбережений: Отбираются остатки из графы U (Остаток по %) для записей, у которых в графе T (Счет %) счет начинается на 43709'
, rownum = 319

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '43808'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '43708 «Привлеченные средства негосударственных финансовых организаций»'
, value = (
		  select isnull(sum(ISNULL(a.restOD,0)),0)
		  --select isnull(sum(ISNULL(a.restPRC,0)),0)
		  from #DEPO a
		  where 1=1
		  and substring(a.accOD,1,5)='43808'
		  --and substring(a.accPRC,1,5)='43709'
		  --and not (upper(a.capitalType) = upper('Выплата в конце срока') and a.daysBetween > 90)
		  and a.daysBetween < 90 --between 1 and 90 https://tracker.yandex.ru/FINA-228
		  )
, comment = 'Портфель сбережений: Отбираются остатки из графы Q (Остаток по ОД) для записей, у которых в графе P (Счет ОД) счет начинается на 43808'
, rownum = 320

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '43809'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '43809 «Начисленные проценты (к уплате) по привлеченным средствам негосударственных коммерческих организаций»'
, value = (
		  --select isnull(sum(ISNULL(a.restOD,0)),0)
		  select 
		  --isnull(sum(ISNULL(a.restPRC,0)),0)
		  isnull(sum(case when upper(a.capitalType) = upper('Выплата в конце срока') and a.daysBetween > 90 then 0 else isnull(a.restPRC,0) end),0)
		  from #DEPO a
		  where 1=1
		  --and substring(a.accOD,1,5)='43808'
		  and substring(a.accPRC,1,5)='43809'
		  --and not (upper(a.capitalType) = upper('Выплата в конце срока') and a.daysBetween > 90)
		  --and a.daysBetween between 1 and 90
		  )
, comment = 'Портфель сбережений: Отбираются остатки из графы U (Остаток по %) для записей, у которых в графе T (Счет %) счет начинается на 43809'
, rownum = 321

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '47416'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '47416 «Суммы, поступившие на расчетные счета в кредитных организациях и банках-нерезидентах, до выяснения»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='47416'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 322

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '47422'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '47422 «Обязательства по прочим финансовым операциям»'
, value = (
		  select isnull(sum(ISNULL(a.restOUT_BU,0)),0) * -1
		  from #OSV a
		  where 1=1
		  and a.acc2order='47422'
		  )
, comment = 'Баланс. Сальдо на конец периода по кредиту'
, rownum = 323

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '52008'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '52008 «Выпущенные облигации»'
, value = (select isnull(SUM(cupon + restOD) * 1000,0) from finAnalytics.SPR_ObligacGrafic where repMonth=@repmonth)
, comment = 'Столбец "Купон" * 1000 + Столбец "Основной долг" * 1000'
, rownum = 324

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = '52019'
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = '52019 «Расчеты по расходам, связанным с выпуском и обращением облигаций»'
, value = (select isnull(SUM(moneyForIssue) * 1000,0) *-1 from finAnalytics.SPR_ObligacGrafic where repMonth=@repmonth)
, comment = 'Столбец "Расходы по выпуску" * 1000 справочника *-1 '
, rownum = 325

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2.4 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.2.4'
, BS = ''
, groupName = 'обязательства со сроком погашения до 90 дней'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select sum(a.value) 
		  from finAnalytics.rep840_3_detail a
		  where 1=1
		  and a.REPMONTH=@repmonth
		  and a.punkt in ('3.2.4')
		  )
, comment = 'Сумма всех BS по пункту 3.2.4'
, rownum = 326
---------------------------------------------------------------------------------

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.2 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.2'
, BS = ''
, groupName = 'Норматив ликвидности (НМФК2),%'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select
			val = l1.val / b.val2 * 100
			from (
			select 
			[val] = sum(a.value)
			from finAnalytics.rep840_3_detail a
			where 1=1
			and a.REPMONTH=@repmonth
			and 
			(
			(a.punkt ='3.2.1.3' and upper(a.pokazatel)=upper('ИТОГО по Пункту'))
			or upper(a.groupName) = upper('микрозаймы со сроком возврата до 90 дней')
			)
			) l1
			left join (
			select val2 = a.value
			from finAnalytics.rep840_3_detail a
			where 1=1
			and a.REPMONTH=@repmonth
			and a.punkt in ('3.2.4')
			and a.pokazatel = 'ИТОГО по Пункту'
			) b on 1=1
		  )
, comment = '(3.2.1.3 + ИТОГО "микрозаймы со сроком возврата до 90 дней" ) / 3.2.4 * 100'
, rownum = 285
---------------------------------------------------------------------------------


		DROP TABLE IF EXISTS #TOPCRED

		select top 1
		l3.client	
		,l3.restOD	
		,l3.restPRC	
		,l3.restPenia	
		,l3.restGP
		,l3.restReservAll	
		,l3.restAllCred	
		,l3.restAllOther474	
		,l3.restAllOther603
		,l3.restAll

		INTO #TOPCRED

		from(
		select
		l1.client
		,l1.restOD
		,l1.restPRC
		,l1.restPenia
		,l1.restGP
		,l1.restReservAll
		, restAllCred = l1.restOD + l1.restPRC + l1.restPenia + l1.restReservAll
		, restAllOther474 = isnull(l2.restOther474,0)
		, restAllOther603 = isnull(l2.restOther603,0)
		, restAll = l1.restOD + l1.restPRC + l1.restPenia + l1.restReservAll + isnull(l2.restOther474,0) + isnull(l2.restOther603,0)
		from (
		select
		client = a.client
		,restOD = sum(isnull(a.zadolgOD,0))
		,restPRC = sum(isnull(a.zadolgPrc,0))
		,restPenia = sum(isnull(a.penyaSum,0))
		,restGP =  sum(isnull(a.gosposhlSum,0))
		,restReservAll = sum(isnull(b.sumOD,0)+isnull(b.sumPRC,0)+isnull(b.sumPenia,0)) * -1
		from #PBR a
		left join finAnalytics.Reserv_NU b on a.dogNum=b.dogNum and b.repmonth=@repmonth
		where upper(a.dogStatus) = upper('Действует')
		group by a.client
		) l1

		left join (
		select
		client = subconto1
		--,restOther474 = abs(sum(isnull( case when substring(acc2order,1,3) ='474' then restOUT_BU else 0 end,0)))
		--,restOther603 = abs(sum(isnull( case when substring(acc2order,1,3) ='603' then restOUT_BU else 0 end,0)))
		,restOther474 = sum(isnull( case when substring(acc2order,1,3) ='474' then restOUT_BU else 0 end,0))
		,restOther603 = sum(isnull( case when substring(acc2order,1,3) ='603' then restOUT_BU else 0 end,0))
		from #OSV
		where acc2order in ('47423','60312','60323','60332')
		and accNum != '60323810000000000000'
		and isnull(subconto3,'-') not in ('Пени','Госпошлина')
		group by subconto1
		) l2 on l1.client = l2.client

		) l3
		--where l3.restAllCred != 0
		order by l3.restAll desc


insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.3.1
select
REPMONTH = @repmonth
, punkt = '3.3.1'
, BS = 'ОД'
, groupName = 'Максимальный размер риска на одного заемщика или группу связанных заемщиков (НМФК3), %'
, pokazatel = (SELECT CLIENT FROM #TOPCRED)
, value = (SELECT restOD FROM #TOPCRED)
, comment = '1. По всем заемщикам в ПБР определяется сумму задолженности: 2. К ним подтягиваем остатки по счетам ОСВ (603,474) 3. Выбираем максимальный из полученого списка'
, rownum = 328

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.3.1
select
REPMONTH = @repmonth
, punkt = '3.3.1'
, BS = '%%'
, groupName = 'Максимальный размер риска на одного заемщика или группу связанных заемщиков (НМФК3), %'
, pokazatel = (SELECT CLIENT FROM #TOPCRED)
, value = (SELECT restPRC FROM #TOPCRED)
, comment = '1. По всем заемщикам в ПБР определяется сумму задолженности: 2. К ним подтягиваем остатки по счетам ОСВ (603,474) 3. Выбираем максимальный из полученого списка'
, rownum = 329

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.3.1
select
REPMONTH = @repmonth
, punkt = '3.3.1'
, BS = 'Пени'
, groupName = 'Максимальный размер риска на одного заемщика или группу связанных заемщиков (НМФК3), %'
, pokazatel = (SELECT CLIENT FROM #TOPCRED)
, value = (SELECT restPenia FROM #TOPCRED)
, comment = '1. По всем заемщикам в ПБР определяется сумму задолженности: 2. К ним подтягиваем остатки по счетам ОСВ (603,474) 3. Выбираем максимальный из полученого списка'
, rownum = 330

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.3.1
select
REPMONTH = @repmonth
, punkt = '3.3.1'
, BS = 'ГП'
, groupName = 'Максимальный размер риска на одного заемщика или группу связанных заемщиков (НМФК3), %'
, pokazatel = (SELECT CLIENT FROM #TOPCRED)
, value = (SELECT restGP FROM #TOPCRED)
, comment = '1. По всем заемщикам в ПБР определяется сумму задолженности: 2. К ним подтягиваем остатки по счетам ОСВ (603,474) 3. Выбираем максимальный из полученого списка'
, rownum = 331

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.3.1
select
REPMONTH = @repmonth
, punkt = '3.3.1'
, BS = '603'
, groupName = 'Максимальный размер риска на одного заемщика или группу связанных заемщиков (НМФК3), %'
, pokazatel = (SELECT CLIENT FROM #TOPCRED)
, value = (SELECT restAllOther603 FROM #TOPCRED)
, comment = '1. По всем заемщикам в ПБР определяется сумму задолженности: 2. К ним подтягиваем остатки по счетам ОСВ (603,474) 3. Выбираем максимальный из полученого списка'
, rownum = 332

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.3.1
select
REPMONTH = @repmonth
, punkt = '3.3.1'
, BS = '474'
, groupName = 'Максимальный размер риска на одного заемщика или группу связанных заемщиков (НМФК3), %'
, pokazatel = (SELECT CLIENT FROM #TOPCRED)
, value = (SELECT restAllOther474 FROM #TOPCRED)
, comment = '1. По всем заемщикам в ПБР определяется сумму задолженности: 2. К ним подтягиваем остатки по счетам ОСВ (603,474) 3. Выбираем максимальный из полученого списка'
, rownum = 333

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.3.2
select
REPMONTH = @repmonth
, punkt = '3.3.2'
, BS = 'РВПЗ'
, groupName = 'Максимальный размер риска на одного заемщика или группу связанных заемщиков (НМФК3), %'
, pokazatel = (SELECT CLIENT FROM #TOPCRED)
, value = (SELECT restReservAll FROM #TOPCRED)
, comment = '1. По всем заемщикам в ПБР определяется сумму задолженности: 2. К ним подтягиваем остатки по счетам ОСВ (603,474) 3. Выбираем максимальный из полученого списка'
, rownum = 334


insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.3 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.3'
, BS = ''
, groupName = 'Максимальный размер риска на одного заемщика или группу связанных заемщиков (НМФК3), %'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select
			val = l1.val / b.val2 * 100
			from (
			select 
			[val] = sum(a.value)
			from finAnalytics.rep840_3_detail a
			where 1=1
			and a.REPMONTH=@repmonth
			and a.punkt in ('3.3.1','3.3.2')
			) l1
			left join (
			select val2 = a.value
			from finAnalytics.rep840_3_detail a
			where 1=1
			and a.REPMONTH=@repmonth
			and a.punkt in ('3.5')
			--and a.pokazatel = 'ИТОГО по Пункту'
			) b on 1=1
		  )
, comment = 'Сумма 3.3.1 / 3.5 * 100'
, rownum = 327
---------------------------------------------------------------------------------

DROP TABLE IF EXISTS #TOPAFILLAGE

		select top(1)
		*
		INTO #TOPAFILLAGE

		from(
		select 
		l3.client	
		,restOD = sum(isnull(l3.restOD,0))
		,restPRC = sum(isnull(l3.restPRC,0))
		,restPenia = sum(Isnull(l3.restPenia,0))
		,restGP = sum(isnull(l3.restGP,0))
		,restReservAll = sum(isnull(l3.restReservAll,0))
		,restAllCred = sum(Isnull(l3.restAllCred,0))
		,restAllOther474 = sum(isnull(l3.restAllOther474,0))
		,restAllOther603 = sum(Isnull(l3.restAllOther603,0))
		,restAll = sum(isnull(l3.restOD,0))
				+  sum(isnull(l3.restPRC,0))
				+  sum(Isnull(l3.restPenia,0))
				+  sum(isnull(l3.restGP,0))
				+  sum(isnull(l3.restReservAll,0))
				+  sum(isnull(l3.restAllOther474,0))
				+  sum(Isnull(l3.restAllOther603,0))

		

		from(
		
		select
		l1.client
		,l1.restOD
		,l1.restPRC
		,l1.restPenia
		,l1.restGP
		,l1.restReservAll
		, restAllCred = l1.restOD + l1.restPRC + l1.restPenia + l1.restReservAll
		, restAllOther474 = 0--isnull(l2.restOther474,0)
		, restAllOther603 = 0--isnull(l2.restOther603,0)
		, restAll = 0--l1.restOD + l1.restPRC + l1.restPenia + l1.restReservAll + isnull(l2.restOther474,0) + isnull(l2.restOther603,0)
		from (
		select
		client = a.client
		,restOD = sum(isnull(a.zadolgOD,0))
		,restPRC = sum(isnull(a.zadolgPrc,0))
		,restPenia = sum(isnull(a.penyaSum,0))
		,restGP =  sum(isnull(a.gosposhlSum,0))
		,restReservAll = sum(isnull(b.sumOD,0)+isnull(b.sumPRC,0)+isnull(b.sumPenia,0)) * -1
		from #PBR a
		left join finAnalytics.Reserv_NU b on a.dogNum=b.dogNum and b.repmonth=@repmonth
		inner join finAnalytics.SPR_Affilage c on a.ClientID=c.affilName and c.affilName is not null and c.repMonth=@repmonth
		where upper(a.dogStatus) = upper('Действует')
		group by a.client
		) l1

		union all

		select
		client = subconto1
		,restOD = 0
		,restPRC = 0
		,restPenia = 0
		,restGP = 0
		,restReservAll = 0
		,restAllCred = 0
		,restOther474 = sum(isnull( case when substring(acc2order,1,3) ='474' then restOUT_BU else 0 end,0))
		,restOther603 = sum(isnull( case when substring(acc2order,1,3) ='603' then restOUT_BU else 0 end,0))
		,restAll = 0
		from #OSV
		inner join finAnalytics.SPR_Affilage c on Код=c.affilName and c.affilName is not null and c.repMonth=@repmonth
		where acc2order in ('47423','60312','60323','60332')
		and accNum != '60323810000000000000'

		group by subconto1


		) l3
		----where l3.restAllCred != 0
		group by l3.client	
		
		) l4 
		order by l4.restAll desc

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.4.1
select
REPMONTH = @repmonth
, punkt = '3.4.1'
, BS = 'ОД'
, groupName = 'Максимальный размер риска на связанное с микрофинансовой компанией лицо (группу лиц, связанных с микрофинансовой компанией) (НМФК4), %'
, pokazatel = isnull((SELECT CLIENT FROM #TOPAFILLAGE),'-')
, value = isnull((SELECT restOD FROM #TOPAFILLAGE),0)
, comment = '1. По связанным заемщикам в ПБР и ОСВ определяется сумму задолженности/остатков 603, 747: 2. Выбираем максимальный из полученого списка'
, rownum = 336

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.4.1
select
REPMONTH = @repmonth
, punkt = '3.4.1'
, BS = '%%'
, groupName = 'Максимальный размер риска на связанное с микрофинансовой компанией лицо (группу лиц, связанных с микрофинансовой компанией) (НМФК4), %'
, pokazatel = isnull((SELECT CLIENT FROM #TOPAFILLAGE),'-')
, value = isnull((SELECT restPRC FROM #TOPAFILLAGE),0)
, comment = '1. По связанным заемщикам в ПБР и ОСВ определяется сумму задолженности/остатков 603, 747: 2. Выбираем максимальный из полученого списка'
, rownum = 337

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.4.1
select
REPMONTH = @repmonth
, punkt = '3.4.1'
, BS = 'Пени'
, groupName = 'Максимальный размер риска на связанное с микрофинансовой компанией лицо (группу лиц, связанных с микрофинансовой компанией) (НМФК4), %'
, pokazatel = isnull((SELECT CLIENT FROM #TOPAFILLAGE),'-')
, value = isnull((SELECT restPenia FROM #TOPAFILLAGE),0)
, comment = '1. По связанным заемщикам в ПБР и ОСВ определяется сумму задолженности/остатков 603, 747: 2. Выбираем максимальный из полученого списка'
, rownum = 338

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.4.1
select
REPMONTH = @repmonth
, punkt = '3.4.1'
, BS = 'ГП'
, groupName = 'Максимальный размер риска на связанное с микрофинансовой компанией лицо (группу лиц, связанных с микрофинансовой компанией) (НМФК4), %'
, pokazatel = isnull((SELECT CLIENT FROM #TOPAFILLAGE),'-')
, value = isnull((SELECT restGP FROM #TOPAFILLAGE),0)
, comment = '1. По связанным заемщикам в ПБР и ОСВ определяется сумму задолженности/остатков 603, 747: 2. Выбираем максимальный из полученого списка'
, rownum = 339

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.4.1
select
REPMONTH = @repmonth
, punkt = '3.4.1'
, BS = '603'
, groupName = 'Максимальный размер риска на связанное с микрофинансовой компанией лицо (группу лиц, связанных с микрофинансовой компанией) (НМФК4), %'
, pokazatel = isnull((SELECT CLIENT FROM #TOPAFILLAGE),'-')
, value = isnull((SELECT restAllOther603 FROM #TOPAFILLAGE),0)
, comment = '1. По связанным заемщикам в ПБР и ОСВ определяется сумму задолженности/остатков 603, 747: 2. Выбираем максимальный из полученого списка'
, rownum = 340

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.4.1
select
REPMONTH = @repmonth
, punkt = '3.4.1'
, BS = '474'
, groupName = 'Максимальный размер риска на связанное с микрофинансовой компанией лицо (группу лиц, связанных с микрофинансовой компанией) (НМФК4), %'
, pokazatel = isnull((SELECT CLIENT FROM #TOPAFILLAGE),'-')
, value = isnull((SELECT restAllOther474 FROM #TOPAFILLAGE),0)
, comment = '1. По связанным заемщикам в ПБР и ОСВ определяется сумму задолженности/остатков 603, 747: 2. Выбираем максимальный из полученого списка'
, rownum = 341

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.4.2
select
REPMONTH = @repmonth
, punkt = '3.4.2'
, BS = 'РВПЗ'
, groupName = 'Максимальный размер риска на связанное с микрофинансовой компанией лицо (группу лиц, связанных с микрофинансовой компанией) (НМФК4), %'
, pokazatel = isnull((SELECT CLIENT FROM #TOPAFILLAGE),'-')
, value = isnull((SELECT restReservAll FROM #TOPAFILLAGE),0)
, comment = '1. По связанным заемщикам в ПБР и ОСВ определяется сумму задолженности/остатков 603, 747: 2. Выбираем максимальный из полученого списка'
, rownum = 342

insert into finAnalytics.rep840_3_detail
(REPMONTH, punkt, BS, groupName, pokazatel, value, comment, rownum)
--3.4 ИТОГО по Пункту
select
REPMONTH = @repmonth
, punkt = '3.4'
, BS = ''
, groupName = 'Максимальный размер риска на связанное с микрофинансовой компанией лицо (группу лиц, связанных с микрофинансовой компанией) (НМФК4), %'
, pokazatel = 'ИТОГО по Пункту'
, value = (
		  select
			val = isnull(l1.val / b.val2 * 100,0)
			from (
			select 
			[val] = sum(a.value)
			from finAnalytics.rep840_3_detail a
			where 1=1
			and a.REPMONTH=@repmonth
			and a.punkt ='3.4.1'
			) l1
			left join (
			select val2 = a.value
			from finAnalytics.rep840_3_detail a
			where 1=1
			and a.REPMONTH=@repmonth
			and a.punkt in ('3.5')
			and a.pokazatel = 'ИТОГО по Пункту'
			) b on 1=1
		  )
, comment = 'Сумма 3.4.1 / 3.5 * 100'
, rownum = 335
---------------------------------------------------------------------------------

	end try

	BEGIN CATCH  
    SELECT   
        ERROR_NUMBER() AS ErrorNumber  
       ,ERROR_MESSAGE() AS ErrorMessage;  
	END CATCH  
END --if

END
