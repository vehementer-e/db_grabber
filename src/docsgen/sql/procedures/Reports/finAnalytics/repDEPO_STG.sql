




CREATE PROCEDURE [finAnalytics].[repDEPO_STG]
        @repmonth date
with recompile
AS
BEGIN

select
repMonth
, client
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
, clientType
, checkClientType
, creditType = null/*case when l1.clientType in ('ФЛ','ИП','ЮЛ') then 'привлеченные займы'
                    else 'кредиты'
                    end
				*/
, yearIncome
, yearIncome2
, toEndSrok
, MonthBack
, YearBack
, srok
, sumSrok
, monthSale
, yearSale
, calcPRC
, isMainDog
, mainDogNum
, mainDogDate
, stavkaRepDateType
, closeDate
, dogState
, dataLoadDate
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
,[clientType] = case when [clientType] = 'КО' then 'Банки' else [clientType] end,[checkClientType] = 1
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
from dwh2.finAnalytics.DEPO_MONTHLY_stg a
left join stg._1cUMFO.Справочник_Контрагенты c on /*a.INN=c.ИНН*/ a.client=c.Наименование /*and c.ИННВведенКорректно=0x01*/ and ПометкаУдаления=0x00
left join dwh2.finAnalytics.SPR_DEPOBuckets sp1 on a.daysToClose between sp1.srokFrom and sp1.srokTo

--where a.repMonth='2024-07-01'
--and a.INN='773472645682'
--order by 2

) l1

where l1.repMonth=eomonth(@repmonth)

END
