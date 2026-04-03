
CREATE PROC dbo.Create_dm_EnforcementProceeding_SP_IP
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
 where eo.id is not null or c.[ClaimantExecutiveProceedingId] is not null
 group by Deal.Number, Deal.Id 
)

select *
into #loans
from loans;


CREATE CLUSTERED INDEX [cl_id] ON #loans
(	
	[Number] ASC
	
)



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
	    --join dbo.dm_CMRStatBalance_2 b with (nolock) on b.external_id = l.Number
		join dwh2.dbo.dm_CMRStatBalance b with (nolock) on b.external_id = l.Number
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
		, ft.FirstTradesDatePlanned 
		, ft.FirstTradingResult 
		, st.SecondTradesDatePlanned 
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
	--DWH-257
	from (
	select
		agent_name = a.AgentName
		,external_id = d.Number
		,st_date  = cat.TransferDate
		,fact_end_date = cat.ReturnDate
		,plan_end_date = cat.PlannedReviewDate
		,end_date = isnull(cat.ReturnDate, cat.PlannedReviewDate)
	from Stg._collection.CollectingAgencyTransfer as cat
		inner join Stg._collection.Deals as d
			on d.Id = cat.DealId
		inner join Stg._collection.CollectorAgencies as a
			on a.Id = cat.CollectorAgencyId
	) as t
--join loans l on d_B.external_id = l.Number
)
select *
into #ka_risk_current
from ka_risk_current
where rn=1;

drop table if exists #ka_new;
with 
 ka_new as
(
select [Наименование КА] 
    , [Дата передачи в КА]
	, [Дата отзыва]
	, external_id
	, rn = ROW_NUMBER() over(partition by external_id order by [Дата передачи в КА] desc)
--DWH-257
from (
	select
		[Наименование КА] = a.AgentName
		,[№ реестра передачи] = RegistryNumber
		,external_id = d.Number
		,[Дата передачи в КА]  = cat.TransferDate
		,[Дата отзыва] = cat.ReturnDate
		,[Плановая дата отзыва] = cat.PlannedReviewDate
		,[Текущий статус] = cat.CurrentStatus
	from Stg._collection.CollectingAgencyTransfer as cat
		inner join Stg._collection.Deals as d
			on d.Id = cat.DealId
		inner join Stg._collection.CollectorAgencies as a
			on a.Id = cat.CollectorAgencyId
	) as d_b
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
--DWH-257
from (
	select
		external_id = d.Number
		,agent_name = a.AgentName
		,reestr = RegistryNumber
		,st_date  = cat.TransferDate
		,end_date = isnull(cat.ReturnDate, cat.PlannedReviewDate)
	from Stg._collection.CollectingAgencyTransfer as cat
		inner join Stg._collection.Deals as d
			on d.Id = cat.DealId
		inner join Stg._collection.CollectorAgencies as a
			on a.Id = cat.CollectorAgencyId
) as d_b
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
                 where st.name  in ('БВ') 
				 --and IsActive = 1

)
, FraudConfirmed_state as
(
select distinct c.id --*
         from stg._Collection.CustomerStatus cs
         join  stg._Collection.Customers c on cs.CustomerId=c.id
                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
                 where st.name  in ('Fraud подтвержденный') 
				 --and IsActive = 1

)
, HardFraud_state as
(
select distinct c.id --*
         from stg._Collection.CustomerStatus cs
         join  stg._Collection.Customers c on cs.CustomerId=c.id
                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
                 where st.name  in ('HardFraud') 
				 --and IsActive = 1

)
 

,closed_data as
(
-- найдем dpd на дату закрытия
--drop table  #tt
select 
	d.ссылка as id1
	--, dateadd(year,2000,cast(b.d as datetime2(7))) ДатаДП
	, b.d AS ДатаДП
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
 --select  
	--	 d
	--	 ,external_id
	--	 , max([основной долг уплачено]) [основной долг уплачено]
	--	 , max([Проценты уплачено]) [Проценты уплачено]
	--	 , max(t.[ПениУплачено]) [ПениУплачено]
	--	 , max(t.ГосПошлинаУплачено) ГосПошлинаУплачено
	--	 , max(t.[ПереплатаНачислено]) [ПереплатаНачислено]
	--	 , max(t.[ПереплатаУплачено]) [ПереплатаУплачено]
	--	 , max(t.dpd) dpd
	--	 , max(t.[dpd day-1]) dpd1
	--	 , max(r.Период) DP
	--	 from closed_data t
	--		  left join [Stg].[_1cCMR].[РегистрНакопления_РасчетыПоЗаймам] r with (nolock) on t.id1=r.Договор and cast(r.Период as date)  = t.ДатаДП
	--		  left join [Stg].[_1cCMR].[Справочник_ТипыХозяйственныхОпераций] tp  with (nolock) on tp.Ссылка = r.ХозяйственнаяОперация
	--	 where r.ХозяйственнаяОперация = 0x80D900155D64100111E78663D3A87B83
	--	 group by external_id,d

	--DWH-2548
	 select  
			 t.d
			 ,t.external_id
			 , max(t.[основной долг уплачено]) [основной долг уплачено]
			 , max(t.[Проценты уплачено]) [Проценты уплачено]
			 , max(t.[ПениУплачено]) [ПениУплачено]
			 , max(t.ГосПошлинаУплачено) ГосПошлинаУплачено
			 , max(t.[ПереплатаНачислено]) [ПереплатаНачислено]
			 , max(t.[ПереплатаУплачено]) [ПереплатаУплачено]
			 , max(t.dpd) dpd
			 , max(t.[dpd day-1]) dpd1
			 , dateadd(YEAR, 2000, max(b.d)) DP
			 from closed_data AS t
				INNER JOIN dwh2.dbo.dm_CMRStatBalance AS b with (nolock)
					ON b.external_id = t.external_id
					AND b.d = t.ДатаДП
					AND (
							b.[ДП ОДПоГрафику Начислено] <> 0
						OR b.[ДП ОДПоГрафику Уплачено] <> 0
						OR b.[ДП ПроцентыПоГрафику Начислено] <> 0
						OR b.[ДП ПроцентыПоГрафику Уплачено] <> 0
						OR b.[ДП Основной долг Начислено] <> 0
						OR b.[ДП Основной долг Уплачено] <> 0
						OR b.[ДП Проценты Начислено] <> 0
						OR b.[ДП Проценты Уплачено] <> 0
						OR b.[ДП Пени Начислено] <> 0
						OR b.[ДП Пени Уплачено] <> 0
						OR b.[ДП ГосПошлина Начислено] <> 0
						OR b.[ДП ГосПошлина Уплачено] <> 0
						OR b.[ДП Переплата Начислено] <> 0
						OR b.[ДП Переплата Уплачено] <> 0
					)
			 group by t.external_id, t.d
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
SELECT   distinct     
						Deal.Number AS '№ договора'
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
						, monitoring.FirstTradingResult AS 'Результат первых торгов'
						,  monitoring.SecondTradesDatePlanned AS 'Плановая дата вторых торгов'
						, monitoring.SecondTradingResult AS 'Результат вторых торгов'
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
						 , JudgmentEntryIntoForceDate 'Вступпление решения суда в силу'
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
						 , jp.Id ' id ИспПроиз ИП'
						 , jc.Id 'id Иск ИП'
						 , eo.id 'id ИЛ ИП'

						
					into #EnforcementProceeding_SP_IP	

FROM            #loans l join Stg._Collection.Deals AS Deal on Deal.Number = l.Number  LEFT OUTER JOIN
                         Stg._Collection.customers AS c ON c.Id = Deal.IdCustomer LEFT OUTER JOIN
                         Stg._Collection.JudicialProceeding AS jp ON Deal.Id = jp.DealId LEFT OUTER JOIN
                         Stg._Collection.JudicialClaims AS jc ON jp.Id = jc.JudicialProceedingId LEFT OUTER JOIN
                         Stg._Collection.EnforcementOrders AS eo ON jc.Id = eo.JudicialClaimId LEFT OUTER JOIN
                         #EnforcementProceeding  AS ep ON eo.Id = ep.EnforcementOrderId LEFT OUTER JOIN
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

						
WHERE        (eo.Id IS NOT NULL)

--drop table if exists dbo.dm_EnforcementProceeding_SP_IP
begin tran
truncate table dbo.dm_EnforcementProceeding_SP_IP
insert into dbo.dm_EnforcementProceeding_SP_IP
select *
from #EnforcementProceeding_SP_IP
commit tran

--set statistics time off;
end
--GO
