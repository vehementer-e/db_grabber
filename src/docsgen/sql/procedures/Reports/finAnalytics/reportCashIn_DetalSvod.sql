

CREATE PROCEDURE [finAnalytics].[reportCashIn_DetalSvod]
	@repmonth date

AS
BEGIN

    select 
    [отчетная дата]=repdate
	,[отчетный месяц]=DATEFROMPARTS(DATEPART(year,repdate),datepart(month,repdate),1)
	,[номер договора]=numdog
	,[заемщик]=client
	,[дата начала договора]=beginDate
	,[количество дней просрочки (на начало дня)]=dpdBeginDay
	,[количество дней просрочки (на конец дня)]=dpdEndDay
	,[Продукт]=produkt
	,[бакет просрочки (на начало дня)]=bucketBeginDay
	,[суммарный платеж (за все врем жизни займа)]=summInAll
	,[поступления на счет клиента]=summIn
	,[поступление цессионарию]=summCes
	--,[итого поступило на счета клиента]=summIn_Ces
	,[сумма в счет погашения ОД]=summOD
	,[сумма в счет погашения процентов]=summPRC
	,[сумма в счет погашения пеней]=summPeni
	,[сумма в счет погашения ГП]=summGP
	,[доп.услуги оплачиваемые клиентом]=summDop
	,[списание суммы планового платежа со счета клиента]=summOut
	,[бакет просрочки (на конец дня)]=bucketEndDay
	,[Платежная cистема]=plat
	,[ПП]=pp
	,[ПДП (1/0)]=pdp
	,[ПДП14 (1/0)]=pdp14
	,[ПДП до первой даты погашения по графику (1/0)]=pdp1
	,[ЧДП (1/0)]=chdp
	from dwh2.finAnalytics.CashIn
	where eomonth(REPDATE)=@repmonth
    order by REPDATE,numdog
	
END
