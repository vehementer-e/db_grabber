
CREATE   proc  [dbo].[_collection_подготовка_отчета_Конверсии_ИП]
as

begin

drop table if exists #monitoring
;

with  monitoring as
(
select 
		  monitoring.id
		, bt.ArestCarDate 
		, monitoring.EnforcementProceedingId 
		, bt.CarStoragePlace
		, ft.ReevaluationDate
		, ft.FirstTradesDate 
		, ft.FirstTradesDatePlanned 
		, ft.FirstTradingResult 
		, st.SecondTradesDatePlanned 
		, st.SecondTradingResult 
		, st.SecondTradesDate 
		, im.DecisionDepositToBalance 
		, im.AdoptionBalanceDate 
		, im.AmountDepositToBalance
		, im.OfferAdoptionBalanceDate
		, monitoring.StatusAfterArrestId
		
		
FROM [Stg].[_Collection].[EnforcementProceedingMonitoring] monitoring 
left join [Stg].[_Collection].EnforcementProceedingMonitoringBeforeTrades bt on bt.EnforcementProceedingMonitoringId = monitoring.Id
left join [Stg].[_Collection].[EnforcementProceedingMonitoringFirstTrades] ft on ft.EnforcementProceedingMonitoringId = monitoring.Id
left join [Stg].[_Collection].[EnforcementProceedingMonitoringSecondTrades] st on st.EnforcementProceedingMonitoringId = monitoring.Id
left join [Stg].[_Collection].[EnforcementProceedingMonitoringImplementation] im on im.EnforcementProceedingMonitoringId = monitoring.Id
)
select *
into #monitoring
from monitoring;
;


with v as (

select *, ROW_NUMBER() over(partition by EnforcementProceedingId order by ArestCarDate desc) rn from #monitoring

)
delete from v where rn>1

;


drop table if exists #v_repayments
select код, Сумма, дата into #v_repayments from v_repayments

create nonclustered index t on #v_repayments
(
дата, код
)



  select d.id
  , d.Number
  , d.IdCustomer
  , sp.Id [СП id]
  , isk.id [ИСК id]
  , eo.Id [ИЛ id]
  , ep.Id [ИП id]
  , isk.ClaimInCourtDate [Дата иск в суде]
  , isk.ReceiptOfJudgmentDate [Дата решение суда]
  , eo.AcceptanceDate  [Дата Принятия ИЛ]
  , eo.ReceiptDate  [Дата Получения ИЛ]
  , DATEDIFF(day, eo.ReceiptDate , eo.AcceptanceDate) [Дней от получения до принятия ИЛ]
  , eo.Date  [Дата ИЛ]
  , [Дата Принятия ИЛ составная] = cast(coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date,ep.ExcitationDate) as date)
  , epe.ExcitationDate [Дата возбуждения ИП]
  , ep_v.[Дата ареста авто]
  , x.Дата [Дата платежа после ареста авто]
  , ep_v.[Плановая дата первых торгов]
  , ep_v.[Плановая дата вторых торгов]
  ,MONITORING.FirstTradesDate [Фактическая дата первых торгов]
  ,MONITORING.SecondTradesDate [Фактическая дата вторых торгов]
  ,isnull(MONITORING.SecondTradesDate, MONITORING.FirstTradesDate) [Дата торгов]
  , ep_v.[Дата принятия на баланс]
  ,
  case 
  when ep_v.[Дата принятия на баланс]<=x1.Дата then ep_v.[Дата принятия на баланс]
  when ep_v.[Дата принятия на баланс]>x1.Дата then ep_v.[Дата принятия на баланс]
  end [Принятие на баланс или платеж после первых торгов]
  into #t1
  from 
  [Stg].[_Collection].Deals d
  join mv_loans l on d.Number=l.код
  left join [Stg].[_Collection].JudicialProceeding sp on sp.DealId=d.id
  left join [Stg].[_Collection].JudicialClaims isk   On isk.JudicialProceedingId = sp.id
  left join [Stg].[_Collection].[EnforcementOrders]   eo on eo.JudicialClaimId=isk.id
  left join [Stg].[_Collection].EnforcementProceeding ep on eo.id=ep.EnforcementOrderId
  left join [Stg].[_Collection].[EnforcementProceedingExcitation] epe on ep.id = epe.EnforcementProceedingId

  left join reports.dbo.dm_EnforcementProceeding_SP_IP ep_v on eo.id=ep_v.[id ИЛ ИП]
  LEFT JOIN #monitoring MONITORING ON EP.EnforcementOrderId=MONITORING.EnforcementProceedingId
  outer apply (select sum(Сумма) Сумма , min(p.Дата) Дата from #v_repayments p where p.Дата> ep_v.[Дата ареста авто] and p.Код=d.Number )x
  outer apply (select sum(Сумма) Сумма , min(p.Дата) Дата from #v_repayments p where p.Дата> MONITORING.FirstTradesDate and p.Код=d.Number )x1


drop table if exists [_collection_отчет_Конверсии_ИП]
select * into [_collection_отчет_Конверсии_ИП] from #t1

	end




