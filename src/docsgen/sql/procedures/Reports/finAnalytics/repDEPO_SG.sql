



CREATE PROCEDURE [finAnalytics].[repDEPO_SG]
        @repmonth date
with recompile
AS
BEGIN

declare @daysInMonth int = day(eomonth(@repmonth))
declare @daysInYear int = dateDiff(day, dateFromParts(year(@repmonth),1,1),dateFromParts(year(@repmonth)+1,1,1))

--select @repmonth, @daysInMonth, @daysInYear

select
repMonth = l1.repMonth
, client = l1.client
, INN = l1.INN
, dogNum = l1.dogNum
, dogDSNum = l1.dogDSNum
, dogDate = l1.dogDate
, zaimSum = l1.zaimSum
, zaimVal = l1.zaimVal
, prodName = l1.prodName
, StavkaDogDate = l1.StavkaDogDate
, StavkaRepDate = l1.StavkaRepDate
, dogSaleDate = l1.dogSaleDate
, dogEndDate = l1.dogEndDate
, firstDogEndDate = l1.firstDogEndDate
, accOD = l1.accOD
, restOD = l1.restOD
, addOD = l1.addOD
, returnOD = l1.returnOD
, accPRC = l1.accPRC
, restPRC = l1.restPRC
, addPRC = l1.addPRC
, returnPRC = l1.returnPRC
, incNDFL = l1.incNDFL
, isMSP = l1.isMSP
, capitalType = l1.capitalType
, daysToClose = l1.daysToClose
, daysDog = l1.daysDog
, passport = l1.passport
, birthDay = l1.birthDay
, addressFact = l1.addressFact
, addressReg = l1.addressReg
, branchAddress = l1.branchAddress
, clientType = l1.clientType
, checkClientType = l1.checkClientType
, creditType = null/*case when l1.clientType in ('ФЛ','ИП','ЮЛ') then 'привлеченные займы'
                    else 'кредиты'
                    end
				*/
, yearIncome = l1.yearIncome
, yearIncome2 = l1.yearIncome2
, toEndSrok = l1.toEndSrok
, MonthBack = l1.MonthBack
, YearBack = l1.YearBack
, srok = l1.srok
, sumSrok = l1.sumSrok
, monthSale = l1.monthSale
, yearSale = l1.yearSale
, calcPRC = l1.calcPRC
, isMainDog = l1.isMainDog
, mainDogNum = l1.mainDogNum
, mainDogDate = l1.mainDogDate
, stavkaRepDateType = l1.stavkaRepDateType
, closeDate = l1.closeDate
, dogState = l1.dogState
, dataLoadDate = l1.dataLoadDate
, [avgRestOD] = l1.[avgRestOD]
, [addPRCRepMonth] = l1.addPRC - isnull(l2.addPRC,0)
, [capex] = (l1.addPRC - isnull(l2.addPRC,0)) / @daysInMonth * @daysInYear / l1.[avgRestOD]
from (

select
repMonth = EOMONTH(repMonth)
, client
, INN
, dogNum = trim(dogNum)
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
, accOD = trim(accOD)
, restOD = case when upper(a.dogState) = upper('Закрыт') then 0 else restOD end
, addOD
, returnOD
, accPRC = trim(accPRC)
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
,[clientType] = case when [clientType] = 'КО' then 'Банки' else [clientType] end
,[checkClientType] = 1
,[creditType] = null
,[yearIncome] =a.restOD * a.StavkaRepDate / 100 -- v2 -- a.zaimSum * StavkaRepDate --v1
,[yearIncome2] = null--a.restOD * a.StavkaDogDate / 100 --v2 --a.zaimSum * StavkaDogDate --v1
,[toEndSrok] = sp1.bucketName
,[MonthBack] = EOMONTH(a.dogEndDate)
,[YearBack] = YEAR(a.dogEndDate)
,[srok] =  DATEDIFF(day,a.dogDate,a.dogEndDate)
,[sumSrok] = DATEDIFF(day,a.dogDate,a.dogEndDate) * a.zaimSum
,[monthSale] = EOMONTH(a.dogSaleDate)
,[yearSale] = year(a.dogSaleDate)
,[calcPRC] = case when try_cast(a.StavkaDogDate as float) is not null then a.StavkaDogDate * a.restOD
				  when try_cast(a.StavkaDogDate as float) is null then 0-- replace(a.StavkaDogDate,',','.')  * a.restOD
				  when CHARINDEX(a.StavkaDogDate,';') >0 then null --(SELECT top 1 cast(replace(value,'.',',') as float) FROM STRING_SPLIT(a.StavkaDogDate, ';')) * a.restOD
				  else null end
, isMainDog = a.isMainDog
, mainDogNum = a.mainDogNum
, mainDogDate = a.mainDogDate
, stavkaRepDateType = a.stavkaRepDateType
, dataLoadDate
, closeDate = a.closeDate
, dogState = a.dogState
, [avgRestOD] = a.[avgRestOD]
from dwh2.finAnalytics.DEPO_MONTHLY_sg a
left join stg._1cUMFO.Справочник_Контрагенты c on /*a.INN=c.ИНН*/ a.client=c.Наименование /*and c.ИННВведенКорректно=0x01*/ and ПометкаУдаления=0x00
left join dwh2.finAnalytics.SPR_DEPOBuckets sp1 on a.daysToClose between sp1.srokFrom and sp1.srokTo

--where a.repMonth='2024-07-01'
--and a.INN='773472645682'
--order by 2

) l1

left join (
select
client
,dogNum
,dogDSNum
,addPRC
from dwh2.finAnalytics.DEPO_MONTHLY_sg a

where repMonth=dateadd(month,-1,@repmonth)
) l2 on l1.client = l2.client and l1.dogNum = l2.dogNum and l1.dogDSNum = l2.dogDSNum

where l1.repMonth=eomonth(@repmonth)

END
