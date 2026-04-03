
CREATE   procedure [dbo].[Create_dm_EnforcementProceeding_SP_IP]
as
begin
--set statistics time on;

drop table if exists #EnforcementProceeding_SP_IP;
drop table if exists #loans;
with
loans as
(
select  Deal.Number
--, Deal.Id 
from
 Stg._Collection.Deals AS Deal 
 LEFT OUTER JOIN                         Stg._Collection.customers AS c ON c.Id = Deal.IdCustomer 
 LEFT OUTER JOIN  Stg._Collection.JudicialProceeding AS jp ON Deal.Id = jp.DealId 
 LEFT OUTER JOIN    Stg._Collection.JudicialClaims AS jc ON jp.Id = jc.JudicialProceedingId
 LEFT OUTER JOIN   Stg._Collection.EnforcementOrders AS eo ON jc.Id = eo.JudicialClaimId
-- where eo.id is not null or c.[ClaimantExecutiveProceedingId] is not null
 group by Deal.Number--, Deal.Id 
)

select *
into #loans
from loans;


CREATE CLUSTERED INDEX [cl_id] ON #loans
(	
	[Number] ASC
	
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)



drop table if exists #balance_loans;
with 
balance_loans as
(SELECT  [основной долг уплачено]
	, [Проценты уплачено]
	, ГосПошлинаУплачено
	, [ПереплатаНачислено]
	, [ПениУплачено]
	, [ПереплатаУплачено]
	, dpd
	, [dpd day-1]
	, external_id
	, d
from	#loans l 
	    join reports.dbo.dm_CMRStatBalance_2 b with (nolock) on b.external_id = l.Number
		where b.ContractEndDate = b.d
) --select * from balance_loans
select *
into #balance_loans
from balance_loans;


drop table if exists #monitoring;
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
		, st.SecondTradesDate
		, st.SecondTradingResult 
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

drop table if exists #EnforcementProceeding;
with  EnforcementProceeding as
(
select    
		  ep.id
		, ep.EnforcementOrderId 
		, epe.EndDate 
		, epe.ExcitationDate 
		, epe.CaseNumberInFSSP 
		, epe.NameBailiff 
		, epe.CommentExcitationEnforcementProceeding
		, epe.DepartamentFSSPId
		, eps.EmployerName 
		, eps.EmployerTIN 
		, eps.DateApplicationWithholding 
		, eps.[OrderOnHoldDate] 
		, epe.ErrorCorrectionNumberDate
		, epe.HasID
		, eps.RecipientPFR
		, eps.ApplicationWithholdingDate

		--
		, epe.DuplicateInquiryDate 
						, epe.DuplicateReceivedDate 
						, epe.ApplicationForDuplicateInquiryDate 
						, epe.ApplicationDeliveryDate 
						, eps.ApplicationForWantedDate 
						, epe.ApplicationReviewResult 						
						, epe.DeliveryResult 
						, epe.StartCorrectionNumber  
						, epe.ErrorCorrectionSubmissionRegistryNumber 
						, epe.RejectionReason 
						, eps.LastProhibitionDate 
						, eps.WantedResult 
						, eps.OrderOnRDDate 
						, epe.InquiryReceivedDate 
						, eps.OutputResult 
						, epe.RePresentationDate 
						, eps.ResolutionDate 
		
		
from  Stg._Collection.EnforcementProceeding  ep
left join [Stg].[_Collection].[EnforcementProceedingExcitation] epe on ep.id = epe.EnforcementProceedingId
left join [Stg].[_Collection].[EnforcementProceedingSPI] eps on ep.id = eps.EnforcementProceedingId
)
select *
into #EnforcementProceeding
from EnforcementProceeding;

drop table if exists #arest;
with arest as
(
select  Deal.id from  Stg._Collection.Deals AS Deal  LEFT OUTER JOIN
						 --Stg._Collection.customers AS c ON c.Id = Deal.IdCustomer  LEFT OUTER JOIN
                         Stg._Collection.JudicialProceeding AS jp ON Deal.Id = jp.DealId LEFT OUTER JOIN
                         Stg._Collection.JudicialClaims AS jc ON jp.Id = jc.JudicialProceedingId LEFT OUTER JOIN
                         Stg._Collection.EnforcementOrders AS eo ON jc.Id = eo.JudicialClaimId LEFT OUTER JOIN
                         Stg._Collection.EnforcementProceeding AS ep ON eo.Id = ep.EnforcementOrderId  LEFT OUTER JOIN
                         Stg._Collection.EnforcementProceedingMonitoring AS monitoring ON ep.Id = monitoring.EnforcementProceedingId
						 left join [Stg].[_Collection].EnforcementProceedingMonitoringBeforeTrades bt on bt.EnforcementProceedingMonitoringId = monitoring.Id
						 where bt.ArestCarDate is not null
)
select *
into #arest
from arest;


drop table if exists #ka_risk_current;
with ka_risk_current as
(
select
      agent_name
    , st_date
	, end_date
	, external_id
	, rn = ROW_NUMBER() over(partition by external_id order by st_date desc)
from [dwh_new].dbo.v_agent_credits d_b
--join loans l on d_B.external_id = l.Number
)
select *
into #ka_risk_current
from ka_risk_current
where rn=1;

drop table if exists #repaymnets
select код, сумма, Дата into #repaymnets from v_repayments
create clustered index d on #repaymnets
(код, Дата)





-------------------------------------------------------------
drop table if exists #f;

drop table if exists #ka_new;
with 
 ka_new as
(
select [Наименование КА] 
    , [Дата передачи в КА]
	, [Дата отзыва]
	, external_id
	, rn = ROW_NUMBER() over(partition by external_id order by [Дата передачи в КА] desc)
from [Stg].[_Collection].[dwh_ka_buffer]  d_b
join #loans l on d_B.external_id = l.Number
where [Текущий статус] <> N'Договор отозван из КА' 
--order by [Дата передачи в КА] desc
)
--select * from ka_new
,
payment_new as
(
	select SUM(Amount) as Amount, iddeal 
	from  stg._Collection.[Payment] p
	--join loans l on p.IdDeal = l.Id
	where year(PaymentDt) = year(getdate()) and  month(PaymentDt) = month(getdate())

	group by  iddeal
) --select * from payment_new
,
payment_last as
(
	select SUM(Amount) as Amount, iddeal , cast(PaymentDt as date) PaymentDt
	, rn = ROW_NUMBER() over( partition by iddeal order by cast(PaymentDt as date) desc)
	from  stg._Collection.[Payment] p
	--join loans l on p.IdDeal = l.Id
	where year(PaymentDt) = year(getdate()) and  month(PaymentDt) = month(getdate())

	group by  iddeal, cast(PaymentDt as date)
)
--,
--payment_new_non_date as
--(
--	select SUM(Amount) as Amount, iddeal 
--	from  stg._Collection.[Payment]
--	--where year(PaymentDt) = year(getdate()) and  month(PaymentDt) = month(getdate())

--	group by  iddeal
--)
,
payment_last_non_date as
(
	select SUM(Amount) as Amount, iddeal , cast(PaymentDt as date) PaymentDt
	, rn = ROW_NUMBER() over( partition by iddeal order by cast(PaymentDt as date) desc)
	from  stg._Collection.[Payment] p
	--join loans l on p.IdDeal = l.Id
	--where year(PaymentDt) = year(getdate()) and  month(PaymentDt) = month(getdate())

	group by  iddeal, cast(PaymentDt as date)
)
, ka_risk as
(
select
    agent_name
    , st_date
	, end_date
	, external_id
	, rn = ROW_NUMBER() over(partition by external_id order by st_date desc)
from [Stg].[_Collection].[ka_buffer] d_b
--join loans l on d_B.external_id = l.Number
)

, ka_state as
(
select distinct c.id --*
         from stg._Collection.CustomerStatus cs
         join  stg._Collection.Customers c on cs.CustomerId=c.id
                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
                 where st.name  in ('КА') 
				 and IsActive = 1

)
, BV_state as
(
select distinct c.id --*
         from stg._Collection.CustomerStatus cs
         join  stg._Collection.Customers c on cs.CustomerId=c.id
                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
                 where st.name  in ('Безнадёжное взыскание подтверждено') 
                -- where st.name  in ('БВ') 
				 and IsActive = 1

				 --select * from stg._collection.CustomerState


)
, FraudConfirmed_state as
(
select distinct c.id --*
         from stg._Collection.CustomerStatus cs
         join  stg._Collection.Customers c on cs.CustomerId=c.id
                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
                 where st.name  in ('Fraud подтвержденный') 
				 and IsActive = 1

)
, HardFraud_state as
(
select distinct c.id --*
         from stg._Collection.CustomerStatus cs
         join  stg._Collection.Customers c on cs.CustomerId=c.id
                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
                 where st.name  in ('HardFraud') 
				 and IsActive = 1

)
 

,closed_data as
(
-- найдем dpd на дату закрытия
--drop table  #tt
select 
	d.ссылка as id1
	, dateadd(year,2000,cast(b.d as datetime2(7))) ДатаДП
	--, b.* 
	, [основной долг уплачено]
	, [Проценты уплачено]
	, ГосПошлинаУплачено
	, [ПереплатаНачислено]
	, [ПениУплачено]
	, [ПереплатаУплачено]
	, dpd
	, [dpd day-1]
	, external_id
	, d

--into #tt
from	#balance_loans b
	     join [Stg].[_1cCMR].[Справочник_Договоры] d  with (nolock) on b.external_id = d.Код 
		-- where b.ContractEndDate = b.d
) --select * from closed_data
, BeforeGraph_data as
(
-- найдем статус ДП
 select  
		 d
		 ,external_id
		 , max([основной долг уплачено]) [основной долг уплачено]
		 , max([Проценты уплачено]) [Проценты уплачено]
		 , max(t.[ПениУплачено]) [ПениУплачено]
		 , max(t.ГосПошлинаУплачено) ГосПошлинаУплачено
		 , max(t.[ПереплатаНачислено]) [ПереплатаНачислено]
		 , max(t.[ПереплатаУплачено]) [ПереплатаУплачено]
		 , max(t.dpd) dpd
		 , max(t.[dpd day-1]) dpd1
		 , max(r.Период) DP
		 from closed_data t
			  left join [Stg].[_1cCMR].[РегистрНакопления_РасчетыПоЗаймам] r with (nolock) on t.id1=r.Договор and cast(r.Период as date)  = t.ДатаДП
			  left join [Stg].[_1cCMR].[Справочник_ТипыХозяйственныхОпераций] tp  with (nolock) on tp.Ссылка = r.ХозяйственнаяОперация
		 where r.ХозяйственнаяОперация = 0x80D900155D64100111E78663D3A87B83
		 group by external_id,d
), Last_ClaimantId as
(
select OldValue,ChangeDate,ObjectId, isnull(emp.LastName,'') + ' ' + isnull(emp.FirstName,'') + ' ' + isnull(emp.MiddleName,'') LastEmployeyFIO from
  (
  select *
  ,rn = ROW_NUMBER() over(partition by ObjectId order by [ChangeDate] desc)
  FROM [Stg].[_Collection].[CustomerHistory]
  where Field = 'Ответственный взыскатель'
  and NewValue is null
  --and ObjectId = 13945
  and  isNumeric(OldValue) = 1
  ) as history_emp
  left join [Stg].[_Collection].Employee AS emp ON history_emp.OldValue = emp.id
 
  where history_emp.rn=1
  --order by ObjectId
)
, bankropt as
(
select distinct c.id as id --*
         from stg._Collection.CustomerStatus cs
         join  stg._Collection.Customers c on cs.CustomerId=c.id
                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
                 where st.name  in (N'Банкрот подтверждённый') 
				 and IsActive = 1
)
, bankropt_not_confirm as
(
select distinct c.id as id --*
         from stg._Collection.CustomerStatus cs
         join  stg._Collection.Customers c on cs.CustomerId=c.id
                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
                 where st.name  in (N'Банкрот неподтверждённый') 
				 and IsActive = 1
)


--select * from stg._Collection.HopelessCollection
--
--
--
--select a.*, [Дата принятия на баланс] , acceptedonbalance from _collection a
--left join stg._collection.deals d on a.код=d.number
--left join stg._collection.hopelesscollection b on d.id=b.dealid
--where [бв по договору]='Да'



--, bankropt_state_conf as
--(

--select distinct c.id
--         from stg._Collection.CustomerStatus cs
--         join  stg._Collection.Customers c on cs.CustomerId=c.id
--                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
--                 where st.name  in ('Банкрот подтверждённый') 
--				 and IsActive = 1

--)
--, bankropt_state_not_conf as
--(

--select distinct c.id
--         from stg._Collection.CustomerStatus cs
--         join  stg._Collection.Customers c on cs.CustomerId=c.id
--                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
--                 where st.name  in ('Банкрот неподтверждённый') 
--				 and IsActive = 1

--)
, f as (
SELECT   distinct     
						Deal.Number AS '№ договора'
--						,c.id [id клиента]
						
						----, c.LastName AS 'Фамилия'
						----, c.Name AS 'Имя'
						----, c.MiddleName AS 'Отчество'
						,  isnull(c.LastName,' ') + ' ' + isnull(c.Name,' ')  + ' ' + isnull(c.MiddleName,' ') AS 'ФИО'
						, cpd.BirthdayDt AS 'Дата рождения'
						, cpd.BirthPlace AS 'Место рождения'
						, cpd.Series AS 'Серия паспорта'
						, cpd.Number AS '№ паспорта'
						, cpd.PassportIssueDt AS 'Дата выдачи'
						--, cpd.KpPassport AS 'Код подразделения'
						--, cpd.WhoIssuedPassport AS 'Кем выдан паспорт'
						----, dcfio.Genitive AS 'ФИО клиента в именительном падеже '
						----, dcfio.Dative AS 'ФИО клиента в родительном падеже'
						----, dcfio.Ablative AS 'ФИО клиента в творительном падеже'
						, reg.PermanentRegisteredAddress AS 'Адрес постоянной регистрации'
						, reg.ActualAddress AS 'Адрес фактического места жительства'
						, pl.Brand AS 'Марка, модель'
						, pl.Model as 'Модель' 
						--, pl. as 'Модель'
						, pl.YearOfIssue AS 'Год выпуска'
						, pl.Vin AS 'VIN'
						, pl.RegNumber AS 'Гос. номер'
						, court.Name AS 'Наименование суда'
						, ISNULL(eo.Number, 'Не указан') AS '№ ИЛ'
						, eo.Date AS 'Дата ИЛ'
						, eo.AcceptanceDate  ДатаПринятияИЛ
						, eo.ReceiptDate  [Дата получения ИЛ]
						, датаПринятияИЛСоставная = cast(coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date,ep.ExcitationDate) as date)
						, CASE WHEN eo.Type = 1 THEN 'Обеспечительные меры' WHEN eo.Type = 2 THEN 'Денежное требование' WHEN eo.Type = 3 THEN 'Обращение взыскания' WHEN eo.Type = 4 THEN 'Взыскание и обращение взыскания' ELSE 'Не указан' END AS 'Тип ИЛ'
						, eo.Amount AS 'Сумма ИЛ, руб.'
						,  case when eo.Accepted = 1 then 'Да'  when eo.Accepted = 0 then 'Нет' else 'Другое' end 'ИЛ принят'
						, fssp.Name AS 'Наименование отдела ФССП'
						, ep.ExcitationDate AS 'Дата возбуждения ИП'
						, ep.CaseNumberInFSSP AS '№ дела в ФССП'
						, ep.NameBailiff AS 'ФИО пристава'
						, ep.EmployerName AS 'Наименование работодателя'
						, ep.EmployerTIN AS 'ИНН работодателя'
						, ep.DateApplicationWithholding AS 'Дата последнего заявления на удержание'
						, ep.[OrderOnHoldDate] AS 'Дата постановления на удержание'
						--,  ep.ControlDateArrivalOfValuesAtWithholding AS 'Дата постановления на удержание'
						, monitoring.ArestCarDate AS 'Дата ареста авто'
						, monitoring.CarStoragePlace AS 'Место хранения авто'
						,  monitoring.ReevaluationDate AS 'Дата переоценки'
						, monitoring.FirstTradesDatePlanned AS 'Плановая дата первых торгов'
						, monitoring.FirstTradesDate  AS 'Фактическая дата первых торгов'
						, monitoring.FirstTradingResult AS 'Результат первых торгов'
						,  monitoring.SecondTradesDatePlanned AS 'Плановая дата вторых торгов'
						,  monitoring.SecondTradesDate  AS 'Фактическая дата вторых торгов'

						, monitoring.SecondTradingResult AS 'Результат вторых торгов'
						, case when monitoring.FirstTradingResult=0 then monitoring.FirstTradesDate
						        when monitoring.SecondTradingResult=0 then monitoring.SecondTradesDate end [Дата состоявшихся торгов]
						, monitoring.DecisionDepositToBalance AS ' Решение о принятии на баланс'
						, monitoring.AdoptionBalanceDate AS 'Дата принятия на баланс'
						 --, monitoring.EndDate AS 'Дата окончания' --  
						,ep.EndDate AS 'Дата окончания'		
						-- ep.
						 --,  monitoring. --ep.BasisEndEnforcementProceeding AS 'Основания окончания ИП'
						 , ep.CommentExcitationEnforcementProceeding AS 'Основания окончания ИП'
						 , ds.Name as 'Статус договора'
						 , iif(ds.Name = 'Погашен', 'Да', 'Нет') as 'Погашен'
						 , [Состояние в КА] = iif(ka_s.id is null, 'Нет','Да')
						 , ka.agent_name as [Наименование КА есть]
						 , iif(ka_s.id is null, '', ka.agent_name) [Наименование КА]
						 , iif(bankrupt.id is not null, 'Да','Нет') as 'Бакнрот'	
						 --, bankrupt.DateResultOfCourtsDecisionBankrupt 'Дата банкротства подверждено решением'
						-- , [Состояние банкрот подтвержденный] = iif(bankropt_s_c.id is null, 'Нет','Да')
						 ,iif(bankrupt_not_confirm.id is not null, 'Да','Нет') as 'Бакнрот не подтвержденный'	
						 --, bankrupt_not_confirm.DateResultOfCourtsDecisionBankrupt 'Дата банкротства не подверждено'
						 --, [Состояние банкрот не подтвержденный] = iif(bankropt_s_n_c.id is null, 'Нет','Да')
						 --
						 , jc.JudgmentEntryIntoForceDate 'Вступпление решения суда в силу'
						 --,ka.[Дата передачи в КА]
						 --,ka.[Дата отзыва]
						 --,kaRisk.agent_name [Наименование КА риск]
						 --,kaRisk.st_date [Дата передачи в КА риск]
						 --,kaRisk.end_date [Дата возврата из КА риск]
						 --,NULL [Наименование КА риск]
						 --,NULL [Дата передачи в КА риск]
						 --,NULL [Дата возврата из КА риск]
						 ,p.Amount 'Сумма платежей за месяц'
						 ,p_l.Amount 'Сумма последнего платежа в день'
						 ,p_l.PaymentDt 'Дата последнего платежа в месяце'
						 ,p_l_non_date.Amount 'Сумма последнего платежа'
						 ,p_l_non_date.PaymentDt 'Дата последнего платежа'
						 ,cast(Deal.Date as date) 'Дата договора'
						 , concat_ws (',' ,fssp.[ZipCode]
										  ,fssp.[NameCity],fssp.[TypeCity]
										  ,fssp.[NameDistrict],fssp.[TypeDistrict]
										  ,fssp.[NameLocation],fssp.[TypeLocation]
										  ,fssp.[NameRegion],fssp.[TypeRegion]
										  ,fssp.[NameStreet],fssp.[TypeStreet]
										  ,fssp.[NumberHouse], fssp.[LetterBuilding]        
										  ) address_fssp
						, iif(bv.Id is null, 'Нет','Да')  'БВ'
						, iif(hc.Id is null, 'Нет','Да')  'БВ по договору'
						, hc.BasisEndEnforcementProceeding  'Основание БВ по договору'
						--, hc.AvailabilityOfAnIndividualAgreement  'БВ наличие соглашения'
						, hc.IsAgreed  'БВ наличие соглашения'

								-- ПДП
						, dpd.d 'Дата ПДП'
						, [Сумма ПДП] = dpd.[основной долг уплачено] + dpd.[Проценты уплачено] + dpd.ПениУплачено + dpd.ГосПошлинаУплачено
						, dpd.dpd1 'DPD на Дата ПДП'
						--, lcid.LastEmployeyFIO 'Ответственный взыскатель последний'
						, isnull(emp.LastName,'') + '  ' + isnull(emp.FirstName,'') +   '  ' + isnull(emp.MiddleName,'') 'Ответственный взыскатель последний' --'Ответственный взыскатель'
						, lcid.ChangeDate 'Дата последнего взыскателя'
						, monitoring.AmountDepositToBalance AS 'Сумма принятия на баланс'

						-- 08_09_2020
						, [Отправлено в РОСП] = ep.ErrorCorrectionNumberDate
						,iif(empIP.LastName is null , 'Не назначен', empIP.LastName + ' '  + empIP.FirstName + ' ' + empIP.MiddleName) 'КураторИП'
						, monitoring.OfferAdoptionBalanceDate 'Дата предложения о принятии на баланс'
						, CASE WHEN monitoring.DecisionDepositToBalance = 1 THEN 'Принимаем на баланс' WHEN monitoring.DecisionDepositToBalance = 0 THEN 'Не принимаем на баланс'  ELSE
                          'Не выбран' END AS 'Решение о принятии на баланс текст'
						, CASE WHEN ep.HasID = 1 THEN 'Да' WHEN ep.HasID = 0  THEN 'Нет'  ELSE
                          'Не выбрано' END AS 'Наличие ИД'
						, RecipientPFR as 'Получатель ПФР'
						, ep.ApplicationWithholdingDate 'Заявление на удержание'
						, jc.NumberCasesInCourt 'Номер дела в суде СП'
						, eo.[Comment] 'Комментарий'
						, hc.DebtIsRepaidUnderAnIndividualAgreement 'Долг погашен по ИД'
						, hc.AcceptedOnBalance 'Принят на баланс'
						,hc.EndEnforcementProceedingDate [БВ Дата окончания ИП] 
						, empIP.CorporatePhone 'Телефон'
						, empIP.ExtensionNumber 'Дополнительно'
						, cst_deals.Name 'Стадия коллектинга'
						, saa.Name as 'Статус после ареста'
						, ep.DuplicateInquiryDate 'Дата запроса дубликата'
						, ep.DuplicateReceivedDate 'Дата получения дубликата'
						, ep.ApplicationForDuplicateInquiryDate 'Дата заявления на дубликат'
						, ep.ApplicationDeliveryDate 'Дата доставки заявления'
						, ep.ApplicationForWantedDate  'Дата заявления на розыск'
						, ep.ApplicationReviewResult 'Рузультата рассмотрения заявления'
						--, ep.ApplicationWithholdingDate
						, ep.DeliveryResult 'Результат доставки'
						,ep.StartCorrectionNumber  'Номер исходящего'
						--,ep.StartCorrectionNumber
						, ep.ErrorCorrectionSubmissionRegistryNumber 'Номер исходящего ШПИ отправки заявления'
						, ep.RejectionReason 'Причина отказа'
						, ep.LastProhibitionDate 'Дата последнего запрета'
						, ep.WantedResult 'Результат заявления на розыск'
						, ep.OrderOnRDDate 'Дата постановления на РД'
						, ep.InquiryReceivedDate 'Дата ответа на запрос'
						, ep.OutputResult 'Результат выходной'
						, ep.RePresentationDate 'Дата репрезентации'
						, ep.ResolutionDate 'Дата резолюции'
						, fssp.NameRegion 'Регион ФССП'
						, court.NameRegion 'Регион суда'
						, concat_ws (',' ,court.[ZipCode]
										  ,court.[NameCity],court.[TypeCity]
										  ,court.[NameDistrict],court.[TypeDistrict]
										  ,court.[NameLocation],court.[TypeLocation]
										  ,court.[NameRegion],court.[TypeRegion]
										  ,court.[NameStreet],court.[TypeStreet]
										  ,court.[NumberHouse], court.[LetterBuilding]        
										  ) 'Адрес суда'
						 , iif(arest.Id is not null, 'Да', 'Нет') 'Арест машины по договору'
						 , eo.newOwner 'Новый собственник'
						 , Deal.Id 'id Договор ИП'
						 , ep.Id ' id ИспПроиз ИП'
						 , jc.Id 'id Иск ИП'
						 , eo.id 'id ИЛ ИП'
						 , jp.id 'id СП'
						 , jp.SubmissionClaimDate [СП дата]
						 , jc.CourtClaimSendingDate [Дата отправки иска в суд]
						 , jc.OrderRequestSendingData [Дата отправки заявления на выдачу ИЛ / судебного приказа]
						 
						 , jc.DebtClaimSendingDate [Дата иска]
						 , jc.JudgmentDate [Иск дата решения]
						 , jc.ReceiptOfJudgmentDate [Иск дата получения решения]
						 , jc.AmountJudgment [Сумма по судебному решению]
						
					

FROM            #loans l join Stg._Collection.Deals AS Deal on Deal.Number = l.Number  LEFT OUTER JOIN
                         Stg._Collection.customers AS c ON c.Id = Deal.IdCustomer LEFT OUTER JOIN
                         Stg._Collection.JudicialProceeding AS jp ON Deal.Id = jp.DealId LEFT OUTER JOIN
                         Stg._Collection.JudicialClaims AS jc ON jp.Id = jc.JudicialProceedingId LEFT OUTER JOIN
                         Stg._Collection.EnforcementOrders AS eo ON jc.Id = eo.JudicialClaimId LEFT OUTER JOIN
                         #EnforcementProceeding  AS ep ON eo.Id = ep.EnforcementOrderId LEFT OUTER JOIN
						 --select * from #EnforcementProceeding where EnforcementOrderId=984
                         Stg._Collection.collectingStage AS cst_deals ON Deal.StageId = cst_deals.Id LEFT OUTER JOIN
                         Stg._Collection.collectingStage AS cst_client ON c.IdCollectingStage = cst_client.Id LEFT OUTER JOIN
                         Stg._Collection.CustomerPersonalData AS cpd ON cpd.IdCustomer = c.Id 
						 --LEFT OUTER JOIN
       --                  [Stg].[_Collection].[DadataCleanFIO] AS dcfio ON dcfio.Surname = c.LastName AND dcfio.Name = c.Name AND dcfio.Patronymic = c.MiddleName 
						 LEFT OUTER JOIN
                         [Stg].[_Collection].Courts AS court ON court.Id = jp.CourtId LEFT OUTER JOIN
                         Stg._Collection.DepartamentFSSP AS fssp ON ep.DepartamentFSSPId = fssp.Id LEFT OUTER JOIN
                         #monitoring monitoring ON ep.Id = monitoring.EnforcementProceedingId LEFT OUTER JOIN
                         [Stg].[_Collection].DealPledgeItem AS dpi ON dpi.DealId = Deal.Id LEFT OUTER JOIN
                         [Stg].[_Collection].[PledgeItem] AS pl ON pl.Id = dpi.PledgeItemId LEFT OUTER JOIN
                         [Stg].[_Collection].[Registration] AS reg ON reg.IdCustomer = c.Id
						 left join [Stg].[_Collection].[DealStatus] ds on Deal.idstatus = ds.id
						 --left join (select * from ka_new where rn=1) ka on ka.external_id = deal.Number
						-- left join (select * from ka_risk where rn=1) kaRisk on kaRisk.external_id = deal.Number

						-- в рамках общения со Спейс
						left join #ka_risk_current  ka  on ka.external_id = deal.Number

						--left join (select DateResultOfCourtsDecisionBankrupt  = max(case when DateResultOfCourtsDecisionBankrupt is not null then DateResultOfCourtsDecisionBankrupt 
						--else  
						--	case when CourtDecisionDate is not null then CourtDecisionDate
						--		else 
						--			case when CreateDate is not null then CreateDate
						--			else UpdateDate
						--		end
						--		end
						--end),CustomerId  from Stg._Collection.[CustomerStatus] 
						--			where [CustomerStateId] in (16) --15
						--			and isActive = 1
						--			--and  DateResultOfCourtsDecisionBankrupt is not null
						--			group by CustomerId) bankrupt on bankrupt.CustomerId = c.Id
						--left join (select DateResultOfCourtsDecisionBankrupt  = max(case when DateResultOfCourtsDecisionBankrupt is not null then DateResultOfCourtsDecisionBankrupt 
						--else  
						--	case when CourtDecisionDate is not null then CourtDecisionDate
						--		else 
						--			case when CreateDate is not null then CreateDate
						--			else UpdateDate
						--		end
						--		end
						--end),CustomerId  from Stg._Collection.[CustomerStatus] 
						--			where [CustomerStateId] in (15) --15
						--			and isActive = 1
						--			--and  DateResultOfCourtsDecisionBankrupt is not null
						--			group by CustomerId) bankrupt_not_confirm on bankrupt_not_confirm.CustomerId = c.Id
						left join bankropt_not_confirm bankrupt_not_confirm on bankrupt_not_confirm.id = c.Id
						left join bankropt  bankrupt on bankrupt.id = c.Id

						left join [Stg].[_Collection].Employee AS emp ON c.ClaimantId = emp.id
						left join payment_new p on p.IdDeal = Deal.id
						left join payment_last p_l on p_l.IdDeal = Deal.id and p_l.rn=1 
						left join payment_last_non_date p_l_non_date on p_l_non_date.IdDeal = Deal.id and p_l_non_date.rn=1 
						
						left join ka_state ka_s on ka_s.Id = c.Id
					--	left join bankropt_state_conf bankropt_s_c on bankropt_s_c.id=c.id
					--	left join bankropt_state_not_conf bankropt_s_n_c on bankropt_s_n_c.id=c.id
						left join BeforeGraph_data dpd on dpd.external_id = Deal.Number
						--left join stg._collection.ImplementationProcess impprocess on pl.id = impprocess.PledgeItemId
						--left join [Stg].[_Collection].[Settlement] s on s.IdCustomer = c.id
						left join BV_state bv on bv.Id = c.id
						--left join FraudConfirmed_state fc on fc.Id = c.id
						--left join HardFraud_state hf on hf.Id = c.id
						left join [Stg].[_Collection].[HopelessCollection] hc on hc.DealId = Deal.id
						left join Last_ClaimantId lcid on lcid.ObjectId = c.id
						left join stg.[_Collection].Employee empIP  on c.[ClaimantExecutiveProceedingId]  = empIP.id
						left join stg._Collection.StatusAfterArrest saa on saa.id = monitoring.StatusAfterArrestId
						left join #arest arest on arest.Id = Deal.Id

						
WHERE        (jp.Id IS NOT NULL)
)


select * into #f from f




drop table if exists #statuses
select a.id
, max(case when IsActive=1 and b.CustomerState='Банкрот подтверждённый'  then DateResultOfCourtsDecisionBankrupt end) [Банкрот подтвержденный дата] 
, max(case when IsActive=1 and b.CustomerState='Банкрот неподтверждённый'   then BankruptcyFilingDate end) [Банкрот неподтвержденный дата] 
, max(case when IsActive=1 and b.CustomerState='Смерть подтвержденная'   then Date end) [Смерть дата] 
, max(case when IsActive=1 and b.CustomerState in ('HardFraud' )   then ActivationDate end) [HardFraud дата] 



into #statuses 

from stg._Collection.customers a
left join _collection_CustomerStatus b on a.id=b.CustomerId
group by a.id

drop table if exists #EnforcementProceeding_SP_IP
; 

select b.код, b.isInstallment, b.[id клиента Спейс] [id клиента], b.CRMClientGUID, b.[Дата выдачи] [Дата выдачи займа] , isnull( b.[Дата погашения], b.[Дата статуса продан] ) [Дата погашения] 
,a.*
, x1.[Дата платежа после первых торгов]
, x2.[Дата платежа после вторых торгов] 
, x21.[Дата платежа после состоявшихся торгов] 
, x3.[Сумма платежей после даты иска] 
, s.[HardFraud дата]
, s.[Банкрот подтвержденный дата]
, s.[Банкрот неподтвержденный дата]
, s.[Смерть дата]
into #EnforcementProceeding_SP_IP	
from 
mv_loans b left join
#f a on b.код=a.[№ договора]
outer apply (select top 1 Дата [Дата платежа после первых торгов] from #repaymnets r where r.Код=a.[№ договора] and r.Дата>=a.[Фактическая дата первых торгов] order by r.Дата)  x1
outer apply (select top 1 Дата [Дата платежа после вторых торгов] from #repaymnets r where r.Код=a.[№ договора] and r.Дата>=a.[Фактическая дата вторых торгов] order by r.Дата)  x2
outer apply (select top 1 Дата [Дата платежа после состоявшихся торгов] from #repaymnets r where r.Код=a.[№ договора] and  r.Дата>=a.[Дата состоявшихся торгов]   order by r.Дата)  x21
outer apply (select sum(r.Сумма) [Сумма платежей после даты иска] from #repaymnets r where r.Код=a.[№ договора] and r.Дата>=a.[Дата иска]  )  x3
left join #statuses s on b.[id клиента Спейс]=s.Id

drop table if exists #EnforcementProceeding_SP_IP_balance
select a.*, b.[Остаток ОД] [Остаток ОД на сегодня], b.[dpd начало дня] into #EnforcementProceeding_SP_IP_balance from #EnforcementProceeding_SP_IP a
left join v_balance b on a.код=b.Код and b.d=cast(getdate() as date)

drop table if exists #EnforcementProceeding_SP_IP_balance_rn
select *, ROW_NUMBER() over(partition by Код order by case when [Тип ИЛ]<>'Обеспечительные меры'  then 1 else 0 end desc
,case when [Дата платежа после состоявшихся торгов] is not null then 1 else 0 end desc
,case when [Дата принятия на баланс]                is not null then 1 else 0 end desc
,case when [Фактическая дата вторых торгов]         is not null then 1 else 0 end desc
,case when [Фактическая дата первых торгов]         is not null then 1 else 0 end desc
,case when [Дата ареста авто]                       is not null then 1 else 0 end desc
,case when [Дата возбуждения ИП]                    is not null then 1 else 0 end desc
,case when [ДатаПринятияИЛ]              is not null then 1 else 0 end desc
,case when [Дата получения ИЛ]                      is not null then 1 else 0 end desc
,case when [Дата ИЛ]                                is not null then 1 else 0 end desc
,[Дата платежа после состоявшихся торгов]
,[Дата принятия на баланс]               
,[Фактическая дата вторых торгов]        
,[Фактическая дата первых торгов]        
,[Дата ареста авто]                      
,[Дата возбуждения ИП]                   
,[ДатаПринятияИЛ]             
,[Дата получения ИЛ]                     
,[Дата ИЛ]                               







) rn_Договор into #EnforcementProceeding_SP_IP_balance_rn
from #EnforcementProceeding_SP_IP_balance


begin tran

--drop table if exists analytics.dbo.dm_EnforcementProceeding_SP_IP 
--select * into analytics.dbo.dm_EnforcementProceeding_SP_IP  from #EnforcementProceeding_SP_IP_balance_rn

truncate table analytics.dbo.dm_EnforcementProceeding_SP_IP
insert into  analytics.dbo.dm_EnforcementProceeding_SP_IP
select * from #EnforcementProceeding_SP_IP_balance_rn

--select *   from  analytics.dbo.dm_EnforcementProceeding_SP_IP  
--truncate table analytics.dbo.dm_EnforcementProceeding_SP_IP
--insert into analytics.dbo.dm_EnforcementProceeding_SP_IP
--select *
--from #EnforcementProceeding_SP_IP
commit tran


exec [C2-VSR-BIRS].[RS_Jobs].dbo.StartReportJob  '2DB7790D-456F-490D-A009-66B10450758B'

--set statistics time off;
end
--GO


