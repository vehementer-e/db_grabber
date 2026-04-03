



CREATE PROCEDURE [finAnalytics].[CB_CHECK2024]
    @rep_date date

AS
BEGIN


select 
  a.clientCat, 
  a.isEducation, 
  a.isInvalid, 
  a.isCredLimit, 
  a.credLimitSum, 
  a.credLimitSumGrow, 
  a.isGosProg, 
  a.isGroupMPL, 
  a.dogUID, 
  a.dogNumID, 
  a.saleCanal, 
  a.saleAdress, 
  a.saleSposob, 
  a.isCessiaBy, 
  a.client, 
  a.clientID, 
  a.clientBirthday, 
  a.clientIDDate, 
  a.dogDate, 
  a.dogNum, 
  a.saleDate, 
  a.saleSum, 
  a.saleStavka, 
  a.returnOrder, 
  a.returnDate, 
  a.returnDateDS, 
  a.restOD, 
  a.restPRC, 
  a.restPenya, 
  a.regAdress, 
  a.factAdress, 
  a.PDNonSaleDate, 
  a.PDNcalcDate, 
  a.monthIncome, 
  a.sourceIncome, 
  a.monthPay, 
  a.coClientFIO, 
  a.coClientPassport, 
  a.coClientIncome, 
  a.avgMonthlyPay, 
  a.avgMonthlyPayOtherMFO, 
  a.avgMonthlyPayOtherCred, 
  a.avgMonthlyPayOtherPoruch, 
  a.avgMonthlyPayCOClient, 
  a.isMSP, 
  a.isBunkrupt, 
  a.isZalogPoruch, 
  a.zalogSum, 
  a.zalogCheckDate, 
  a.poruchitelInfo, 
  a.poruchitelID, 
  a.isRestrukt, 
  a.restruktCount, 
  a.restruktLastDate, 
  a.restruktReturnDate, 
  a.prosAllDays, 
  a.prosTime1, 
  a.prosTime2, 
  a.reservStavka, 
  a.reservOD, 
  a.reservPRC, 
  a.reservPenya, 
  a.reservROStavka, 
  a.reservROOD, 
  a.reservROPRC, 
  a.reservROPenya, 
  a.cessiaINDogDate, 
  a.cessiaINDogNum, 
  a.cessiaINName, 
  a.cessiaINID, 
  a.cessiaINFactDate, 
  a.cessiaINReturnDate, 
  a.isCessia, 
  a.balanseOutDate, 
  a.cessiaOUTDogDate, 
  a.cessiaOUTDogNum, 
  a.cessiaOUTName, 
  a.cessiaOUTID, 
  a.cessiaDiscount, 
  a.isA1,
  a.nomenkGroup,
  a.CloseDate,
  a.INN,
  a.dogVin,
  a.PBR_PDN_SALE,
  a.PBR_PDN_REP

  ,[restOD_3006] = b.restOD
  ,[restPRC_3006] = b.restPRC
  ,[restPenya_3006] = b.restPenya
  ,[reservOD_3006] = b.reservOD
  ,[reservPRC_3006] = b.reservPRC
  ,[reservPenya_3006] = b.reservPenya

  ,[restOD_3103] = c.zadolgOD
  ,[restPRC_3103] = c.zadolgPrc
  ,[restPenya_3103] = c.penyaSum
  ,[reservOD_3103] = c.reservOD
  ,[reservPRC_3103] = c.reservPRC
  ,[reservPenya_3103] = c.reservProchSumNU

from dwh2.finAnalytics.CB_reestr2024 a
left join dwh2.finAnalytics.CB_reestr2024 b on a.dogNum=b.dogNum and b.repdate=caSt('2024-06-30' as date)
left join dwh2.finAnalytics.PBR_MONTHLY c on a.dogNum=c.dogNum and c.repMonth=caSt('2024-03-01' as date)
where a.repdate = @rep_date

END
