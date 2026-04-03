




CREATE PROCEDURE [finAnalytics].[CB_CHECK2024_c]
    @rep_date date

AS
BEGIN


select 
clientCat =(select sum(case when clientCat is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --1
,isEducation = null --2
,isInvalid = null --3
,isCredLimit = null --4
,credLimitSum = null --5
,credLimitSumGrow = null --6
,isGosProg = null --7
,isGroupMPL = (select sum(case when isGroupMPL is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --8
,dogUID  = (select sum(case when dogUID is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --9
,dogNumID  = (select sum(case when dogNumID is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --10
,saleCanal  = (select sum(case when dogNumID is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --11
,saleAdress = (select sum(case when saleAdress is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --12
,saleSposob = null --13 
,isCessiaBy = null --14
,client = (select sum(case when client is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --15
,clientID = (select sum(case when clientID is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --16
,clientBirthday = (select sum(case when clientBirthday is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --17
,clientIDDate = (select sum(case when clientIDDate is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --18
,dogDate = (select sum(case when dogDate is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --19 
,dogNum = (select sum(case when dogNum is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --20
,saleDate = (select sum(case when saleDate is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --21
,saleSum = (select sum(case when saleSum is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --22
,saleStavka = (select sum(case when saleStavka is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --23
,returnOrder = (select sum(case when returnOrder is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --24
,returnDate = (select sum(case when returnDate is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --25
,returnDateDS = (select sum(case when returnDateDS is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --26
,restOD = (select sum(case when restOD is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --27
,restPRC = (select sum(case when restPRC is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --28
,restPenya = (select sum(case when restPenya is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --29
,regAdress = (select sum(case when regAdress is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --30
,factAdress = (select sum(case when factAdress is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --31
,PDNonSaleDate = (select sum(case when PDNonSaleDate is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --32
,PDNcalcDate = (select sum(case when PDNcalcDate is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --33
,monthIncome = (select sum(case when monthIncome is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --34
,sourceIncome = (select sum(case when sourceIncome is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --35
,monthPay = (select sum(case when monthPay is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --36
,coClientFIO = null --37
,coClientPassport = null --38
,coClientIncome = null --39
,avgMonthlyPay = (select sum(case when avgMonthlyPay is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --40
,avgMonthlyPayOtherMFO = (select sum(case when avgMonthlyPayOtherMFO is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --41
,avgMonthlyPayOtherCred = (select sum(case when avgMonthlyPayOtherCred is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --42
,avgMonthlyPayOtherPoruch = (select sum(case when avgMonthlyPayOtherPoruch is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --43
,avgMonthlyPayCOClient = null --44
,isMSP = (select sum(case when isMSP is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --45
,isBunkrupt = (select sum(case when isBunkrupt is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --46
,isZalogPoruch = (select sum(case when isZalogPoruch is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --47
,zalogSum = (select sum(case when zalogSum is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --48
,zalogCheckDate = (select sum(case when zalogCheckDate is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --49
,poruchitelInfo = (select sum(case when poruchitelInfo is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --50
,poruchitelID = (select sum(case when poruchitelID is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --51
,isRestrukt = null --52
,restruktCount = (select sum(case when restruktCount is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --53
,restruktLastDate = (select sum(case when restruktLastDate is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --54
,restruktReturnDate = (select sum(case when restruktReturnDate is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --55
,prosAllDays = null --56
,prosTime1 = null --57
,prosTime2 = null --58
,reservStavka = null --59
,reservOD = (select sum(reservOD) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --60
,reservPRC = (select sum(reservPRC) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --61
,reservPenya = (select sum(reservPenya) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --62
,reservROStavka = null --63
,reservROOD = (select sum(reservROOD) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --64
,reservROPRC = (select sum(reservROPRC) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --65
,reservROPenya = (select sum(reservROPenya) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --66
,cessiaINDogDate = null --67
,cessiaINDogNum = null --68
,cessiaINName = null --69
,cessiaINID = null --70
,cessiaINFactDate = null --71
,cessiaINReturnDate = null --72
,isCessia = (select sum(case when isCessia is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --73
,balanseOutDate = (select sum(case when balanseOutDate is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --74
,cessiaOUTDogDate = (select sum(case when cessiaOUTDogDate is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --75
,cessiaOUTDogNum = (select sum(case when cessiaOUTDogNum is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --76
,cessiaOUTName = (select sum(case when cessiaOUTName is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --77
,cessiaOUTID = (select sum(case when cessiaOUTID is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --78
,cessiaDiscount = (select sum(case when cessiaDiscount is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --79
,isA1 = (select sum(case when isA1 is not null then 1 else 0 end) from dwh2.finAnalytics.CB_reestr2024 where repdate = @rep_date) --80
END
