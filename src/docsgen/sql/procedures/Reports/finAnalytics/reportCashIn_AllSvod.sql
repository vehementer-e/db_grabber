

CREATE PROCEDURE [finAnalytics].[reportCashIn_AllSvod]
	@repmonth date

AS
BEGIN
	--declare @repmonth date='2025-08-31'
    select 
    [отчетная дата]=repdate
	,[бакет просрочки (на начало дня)]=bucketBeginDay
	,[поступления на счет клиента]=sum(summIn)
	,[поступление цессионарию]=abs(sum(summCes))
	,[итого поступило на счета клиента]=sum(summIn_Ces)
	,[сумма в счет погашения ОД]=sum(summOD)
	,[сумма в счет погашения процентов]=sum(summPRC)
	,[сумма в счет погашения пеней,штрафов,ГП]=sum(summPeni+summGP)
	,[доп.услуги оплачиваемые клиентом]=sum(summDop)
	,[списание суммы планового платежа со счета клиента]=sum(summOut)
	
	,[ПП]=sum(pp)
	,[ПДП (1/0)]=sum(pdp)
	,[ПДП14 (1/0)]=sum(pdp14)
	,[ПДП до первой даты погашения по графику (1/0)]=sum(pdp1)
	,[ЧДП (1/0)]=sum(chdp)
	from dwh2.finAnalytics.CashIn
	where eomonth(REPDATE)=@repmonth
	group by repdate,bucketBeginDay
	order by repdate, case 
							when bucketBeginDay='0' then 0
							when bucketBeginDay='360+' then 360
							else 
								cast(substring(bucketBeginDay,1,iif(charindex('-',bucketBeginDay)=2,1,charindex('-',bucketBeginDay)-1)) as int)
							end



END
