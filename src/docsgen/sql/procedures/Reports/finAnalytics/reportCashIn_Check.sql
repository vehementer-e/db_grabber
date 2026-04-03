


CREATE PROCEDURE [finAnalytics].[reportCashIn_Check]
	@repmonth date

AS
BEGIN
	--declare @repmonth date='2025-12-31'

select 
 [Дата]=l1.repdate
 ,[остаток на начало дня]=round(ostBeginDayUMFO,2)
 ,[поступления на счет клиента]=l1.summIn
 ,[поступление цессионарию]=l1.summCes
 ,[Невыявленные]=l1.summUnIdent
 ,[сумма в счет погашения ОД]=l1.summOD
 ,[сумма в счет погашения процентов]=l1.summPRC
 ,[сумма в счет погашения пеней]=l1.summPeni
 ,[сумма в счет погашения ГП]=l1.summGP
 ,[доп.услуги оплачиваемые клиентом]=l1.summDop
 ,[Поступление на переплату по внесудебной реализации]=l1.summZalog
 ,[Нестандартные операции]=l1.summNotStandart
 ,[Остаток на конец дня]=round(l1.ostBeginDayUMFO+l1.ss,2)
 ,checkOst=iif(round(l1.ostBeginDayUMFO+l1.ss,0)!=round(l1.ostEndDayUMFO,0),1,0)
from (
		select 
		a.repdate
		,summIn=sum(a.summIn)
		,summCes=sum(a.summCes)
		,summUnIdent=isnull(ch1.summ,0)
		,summOD=sum(a.summOD)
		,summPRC=sum(a.summPRC)
		,summPeni=sum(a.summPeni)
		,summGP=sum(a.summGP)
		,summDop=sum(a.summDop)
		,summZalog=sum(a.summZalog)
		,summNotStandart=isnull(ch2.summ,0)
		,ss=sum(a.summIn)-sum(a.summCes)-sum(a.summOD)-sum(a.summPRC)-sum(a.summPeni)-sum(a.summGP)-sum(a.summDop)+sum(a.summZalog)-isnull(ch1.summ,0)-isnull(ch2.summ,0)
		,ostBeginDayUMFO =ostBeginDayUMFO
		,ostEndDayUMFO=ostEndDayUMFO
		from dwh2.finAnalytics.CashIn a
		left join 
				(select 
					repdate 
					,summ=sum(summ)
				from dwh2.finAnalytics.CashIn_CheckList
				where kt='47416'
				group by repdate)  ch1 on a.repdate=ch1.repdate
		left join 
				(select 
					repdate 
					,summ=sum(iif(dt=kt,0,iif(dt ='47422' or kt='71501',summ,summ*-1)))
				from dwh2.finAnalytics.CashIn_CheckList
				where kt!='47416'
				group by repdate)  ch2 on a.repdate=ch2.repdate
	
		group by a.repdate,isnull(ch1.summ,0),isnull(ch2.summ,0),ostBeginDayUMFO,ostEndDayUMFO
		) l1
		
where eomonth(l1.repdate)=@repmonth
--month(l1.repdate)=month(@repmonth)
order by l1.repdate




END
