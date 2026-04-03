



CREATE PROCEDURE [finAnalytics].[PBR_Monthly_check1]

	@rep_month date

AS
BEGIN

declare @dateFrom datetime = dateadd(year,2000,@rep_month)
declare @dateToTmp datetime = dateadd(day,1,dateadd(year,2000,eomonth(@rep_month)))
declare @dateTo datetime = dateadd(second,-1,@dateToTmp)

select
[Название проверки] = l1.[Название проверки]
,[Данные ПБР] = sum(l1.[Данные ПБР])
,[Данные УМФО] = sum(l1.[Данные УМФО])
,[Контроль] = sum(l1.[Данные ПБР]) - sum(l1.[Данные УМФО])
from(
SELECT 
	[Название проверки] = 'Сумма по графе 1, 2 , 3 по всем договорам'
	,[Данные ПБР] = sum(isnull(a1.PRCIncome,0) + isnull(a1.PRCCorrection,0) + isnull(a2.PRCReservice,0))
	,[Данные УМФО] = 0	
  FROM dwh2.[finAnalytics].[PBR_MONTHLY] t1
  left join dwh2.finAnalytics.PA_PRCIncome a1 on t1.dogNum = a1.dogNum and t1.REPMONTH = a1.repmonth
  left join dwh2.finAnalytics.PA_CollectionAcia a2 on t1.dogNum = a2.dogNum and t1.REPMONTH = a2.repmonth
  where t1.repmonth = @rep_month

union all
  

SELECT 
[Название проверки] = 'Сумма по графе 1, 2 , 3 по всем договорам'
,[Данные ПБР] = 0
,[Данные УМФО] = sum(case when substring(Dt.Код,1,3) in ('710') then isnull(a.Сумма,0)*-1 else isnull(a.Сумма,0) end)
from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0

where a.Период between @dateFrom and @dateTo
and a.Активность=01
and ( 
		(Dt.Код in ('48802','48502','49402','48702') and substring(Kt.Код,1,3) in ('710'))
		or
		(substring(Dt.Код,1,3) in ('710') and Kt.Код in ('48802','48502','49402','48702'))
	)

union all

SELECT 
	[Название проверки] = 'Сумма по графе 4,5 по всем договорам'
	,[Данные ПБР] = sum(isnull(a1.PenyaIncome,0) + isnull(a2.PenyaReservice,0) )
	,[Данные УМФО] = 0	
  FROM dwh2.[finAnalytics].[PBR_MONTHLY] t1
  left join dwh2.finAnalytics.PA_PRCIncome a1 on t1.dogNum = a1.dogNum and t1.REPMONTH = a1.repmonth
  left join dwh2.finAnalytics.PA_CollectionAcia a2 on t1.dogNum = a2.dogNum and t1.REPMONTH = a2.repmonth
  where t1.repmonth = @rep_month

union all


SELECT 
[Название проверки] = 'Сумма по графе 4,5 по всем договорам'
,[Данные ПБР] = 0
,[Данные УМФО] = sum(case when Dt.Код in ('71701') then isnull(a.Сумма,0)*-1 else isnull(a.Сумма,0) end)

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
left join stg._1cUMFO.Справочник_ПрочиеДоходыИРасходы sprDT on a.СубконтоDt1_Ссылка=sprDT.Ссылка
left join stg._1cUMFO.Справочник_ПрочиеДоходыИРасходы sprKT on a.СубконтоCt1_Ссылка=sprKT.Ссылка

where a.Период between @dateFrom and @dateTo
and a.Активность=01
and ( 
		(Dt.Код in ('60323') and Kt.Код in ('71701'))
		or
		(Dt.Код in ('71701') and Kt.Код in ('60323'))
	)
and isnull(sprDT.Наименование,sprKT.Наименование) in (
													'Штрафы и пени по займам предоставленным (52402 сч.71701)'
													,'Неустойки (штрафы, пени) по операциям предоставления (размещения) денежных средств по МСБ (сч.71701 символ 52402)'
													)
) l1
group by [Название проверки]
  
END

