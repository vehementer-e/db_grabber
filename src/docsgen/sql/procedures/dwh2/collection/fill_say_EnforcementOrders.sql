CREATE PROC collection.fill_say_EnforcementOrders
as
begin try

drop table if exists #udal_1;

drop table if exists #ka_new

select [Наименование КА] 
    , [Дата передачи в КА]
	, [Дата отзыва]
	, external_id
	, rn = ROW_NUMBER() over(partition by external_id order by [Дата передачи в КА] desc)
into #ka_new
from (
	select
		[Наименование КА] = a.AgentName
		,[№ реестра передачи] = RegistryNumber
		,external_id = d.Number
		,[Дата передачи в КА]  = cat.TransferDate
		,[Дата отзыва] = cat.ReturnDate
		,[Плановая дата отзыва] = cat.PlannedReviewDate
		,[Текущий статус] = cat.CurrentStatus
		,[ИНН КА] = a.INN
	from Stg._collection.CollectingAgencyTransfer as cat
		inner join Stg._collection.Deals as d
			on d.Id = cat.DealId
		inner join Stg._collection.CollectorAgencies as a
			on a.Id = cat.CollectorAgencyId
	) as t
where [Текущий статус] <> N'Договор отозван из КА' 
--order by [Дата передачи в КА] desc
drop table if exists #payment_new 


	select SUM(Amount) as Amount, iddeal 
	into #payment_new
	from  stg._Collection.[Payment]
	where year(PaymentDt) = year(getdate()) and  month(PaymentDt) = month(getdate())
	group by  iddeal

drop table if exists #payment_last 


	select SUM(Amount) as Amount, iddeal , cast(PaymentDt as date) PaymentDt
	, rn = ROW_NUMBER() over( partition by iddeal order by cast(PaymentDt as date) desc)
	into #payment_last
	from  stg._Collection.[Payment]
	where year(PaymentDt) = year(getdate()) and  month(PaymentDt) = month(getdate())
	group by  iddeal, cast(PaymentDt as date)
drop table if exists #payment_last_non_date

	select SUM(Amount) as Amount, iddeal , cast(PaymentDt as date) PaymentDt
	, rn = ROW_NUMBER() over( partition by iddeal order by cast(PaymentDt as date) desc)
	into #payment_last_non_date
	from  stg._Collection.[Payment]
	--where year(PaymentDt) = year(getdate()) and  month(PaymentDt) = month(getdate())
	group by  iddeal, cast(PaymentDt as date)

drop table if exists  #ka_risk 

select
    agent_name
    , st_date
	, end_date
	, external_id
	, rn = ROW_NUMBER() over(partition by external_id order by st_date desc)
into #ka_risk
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
	) as t

drop table if exists #ka_state 

select distinct c.id --*
         into #ka_state
		 from stg._Collection.CustomerStatus cs
         join  stg._Collection.Customers c on cs.CustomerId=c.id
                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
                 where st.name  in ('КА') 
				 and IsActive = 1
drop table if exists #BV_state 

select distinct c.id --*
         into #BV_state
		 from stg._Collection.CustomerStatus cs
         join  stg._Collection.Customers c on cs.CustomerId=c.id
                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
                 where st.name  in ('БВ') 
				 --and IsActive = 1

drop table if exists #FraudConfirmed_state

select distinct c.id --*
         into #FraudConfirmed_state
		 from stg._Collection.CustomerStatus cs
         join  stg._Collection.Customers c on cs.CustomerId=c.id
                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
                 where st.name  in ('Fraud подтвержденный') 
				 --and IsActive = 1
drop table if exists #HardFraud_state 

select distinct c.id --*
         into #HardFraud_state
		 from stg._Collection.CustomerStatus cs
         join  stg._Collection.Customers c on cs.CustomerId=c.id
                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
                 where st.name  in ('HardFraud') 
				 --and IsActive = 1
drop table if exists #closed_data 

-- найдем dpd на дату закрытия
--drop table  #tt
select 
	d.ссылка as id1
	, dateadd(year,2000,cast(b.d as datetime2(7))) ДатаДП
	, b.* 
into #closed_data 
from	dbo.dm_cmrstatbalance b with (nolock)
	     join [Stg].[_1cCMR].[Справочник_Договоры] d  with (nolock) on b.external_id = d.Код 
		 where b.ContractEndDate = b.d
drop table if exists #BeforeGraph_data 

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
		 into #BeforeGraph_data
		 from #closed_data t
			  left join [Stg].[_1cCMR].[РегистрНакопления_РасчетыПоЗаймам] r with (nolock) on t.id1=r.Договор and cast(r.Период as date)  = t.ДатаДП
			  left join [Stg].[_1cCMR].[Справочник_ТипыХозяйственныхОпераций] tp  with (nolock) on tp.Ссылка = r.ХозяйственнаяОперация
		 where r.ХозяйственнаяОперация = 0x80D900155D64100111E78663D3A87B83
		 group by external_id,d

drop table if exists #Last_ClaimantId

select OldValue,ChangeDate,ObjectId, isnull(emp.LastName,'') + ' ' + isnull(emp.FirstName,'') + ' ' + isnull(emp.MiddleName,'') LastEmployeyFIO 
into #Last_ClaimantId
from
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

SELECT   distinct     cast(getdate() as date) r_date
						,eo.Id id_IL
						,Deal.Number AS '№ договора'
						,  isnull(c.LastName,' ') + ' ' + isnull(c.Name,' ')  + ' ' + isnull(c.MiddleName,' ') AS 'ФИО'
						, reg.Region AS 'Регион постоянной регистрации'
						, court.Name AS 'Наименование суда'
						, ISNULL(eo.Number, 'Не указан') AS '№ ИЛ'
						, eo.Date AS 'Дата ИЛ'
						,eo.ReceiptDate AS 'Дата получения ИЛ'
						,eo.AcceptanceDate  'ДатаПринятияИЛ'
						,датаПринятияИЛСоставная = cast(coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date,epe.ExcitationDate) as date)
						,CASE WHEN eo.Type = 1 THEN 'Обеспечительные меры' 
							  WHEN eo.Type = 2 THEN 'Денежное требование' 
							  WHEN eo.Type = 3 THEN 'Обращение взыскания' 
							  WHEN eo.Type = 4 THEN 'Взыскание и обращение взыскания' 
							  ELSE 'Не указан' END AS 'Тип ИЛ'
						, eo.Amount AS 'Сумма ИЛ, руб.'
						,case when eo.Accepted = 1 then 'Да'  
							  when eo.Accepted = 0 then 'Нет' 
							  else 'Другое' end 'ИЛ принят'
						 , fssp.Name AS 'Наименование отдела ФССП'
						 , epe.ExcitationDate AS 'Дата возбуждения ИП'
						 , epe.CaseNumberInFSSP AS '№ дела в ФССП' 
						 ,spi.OrderOnHoldDate AS 'Дата постановления на удержание' 
						 ,epmbt.ArestCarDate AS 'Дата ареста авто'
                         ,epmft.ReevaluationDate AS 'Дата переоценки'
						 , epmft.FirstTradesDate AS 'Дата первых торгов'
						 , epmft.FirstTradingResult AS 'Результат первых торгов'
                         ,epmst.SecondTradesDate AS 'Дата вторых торгов'
						 , epmst.SecondTradingResult AS 'Результат вторых торгов'
						 , epmi.DecisionDepositToBalance AS ' Решение о принятии на баланс'
                         ,epmi.AdoptionBalanceDate AS 'Дата принятия на баланс'
						 ,epe.EndDate AS 'Дата окончания'		
						 , epe.CommentExcitationEnforcementProceeding AS 'Основания окончания ИП'
						 , iif(ds.Name = 'Погашен', 'Да', 'Нет') as 'Погашен'
						 , [Состояние в КА] = iif(ka_s.id is null, 'Нет','Да')
						 , ka.[Наименование КА]
						 , iif(bankrupt.DateResultOfCourtsDecisionBankrupt is not null, 'Да','Нет') as 'Бакнрот'	
						 , bankrupt.DateResultOfCourtsDecisionBankrupt 'Дата банкротства подверждено решением'
						 ,iif(bankrupt_not_confirm.DateResultOfCourtsDecisionBankrupt is not null, 'Да','Нет') as 'Бакнрот не подтвержденный'	
						 , bankrupt_not_confirm.DateResultOfCourtsDecisionBankrupt 'Дата банкротства не подверждено'
						 , isnull(emp.LastName,'') + '  ' + isnull(emp.FirstName,'') +   '  ' + isnull(emp.MiddleName,'') 'Ответственный взыскатель'
						 ,ka.[Дата передачи в КА]
						 ,ka.[Дата отзыва]
						 , concat_ws (',' ,fssp.[ZipCode]
										  ,fssp.[NameCity],fssp.[TypeCity]
										  ,fssp.[NameDistrict],fssp.[TypeDistrict]
										  ,fssp.[NameLocation],fssp.[TypeLocation]
										  ,fssp.[NameRegion],fssp.[TypeRegion]
										  ,fssp.[NameStreet],fssp.[TypeStreet]
										  ,fssp.[NumberHouse], fssp.[LetterBuilding]        
										  ) address_fssp
						, iif(bv.Id is null, 'Нет','Да')  'БВ'
						, iif(hc.isagreed = 1,'Да', 'Нет')  'БВ по договору'
						, hc.BasisEndEnforcementProceeding  'Основание БВ по договору'
						, hc.IsAgreed  'БВ согласовано'
						, dpd.d 'Дата ПДП'
						, [Сумма ПДП] = dpd.[основной долг уплачено] + dpd.[Проценты уплачено] + dpd.ПениУплачено + dpd.ГосПошлинаУплачено
						, dpd.dpd1 'DPD на Дата ПДП'
						, lcid.LastEmployeyFIO 'Ответственный взыскатель последний'
						, lcid.ChangeDate 'Дата последнего взыскателя'
						, epmi.AmountDepositToBalance AS 'Сумма принятия на баланс'
						, [Отправлено в РОСП] = epe.ErrorCorrectionNumberDate
						,iif(empIP.LastName is null , 'Не назначен', empIP.LastName + ' '  + empIP.FirstName + ' ' + empIP.MiddleName) 'КураторИП'
						, epmi.OfferAdoptionBalanceDate 'Дата предложения о принятии на баланс'
						, CASE WHEN epmi.DecisionDepositToBalance = 1 THEN 'Принимаем на баланс' WHEN epmi.DecisionDepositToBalance = 0 THEN 'Не принимаем на баланс'  ELSE
                          'Не выбран' END AS 'Решение о принятии на баланс текст'
						, CASE WHEN epe.HasID = 1 THEN 'Да' WHEN epe.HasID = 0  THEN 'Нет'  ELSE
                          'Не выбрано' END AS 'Наличие ИД'
						, jc.NumberCasesInCourt 'Номер дела в суде СП'
						, hc.DebtIsRepaidUnderAnIndividualAgreement 'Долг погашен по ИД'
						, hc.AcceptedOnBalance 'Принят на баланс'
						,epe.ErrorCorrectionNumberDate 'Дата отправки заявления в ФССП'
						,epmi.SaleCarDate 'Дата продажи с торгов'
						,epmft.FirstTradesDatePlanned 'Плановая дата первых торгов'
						,epmst.SecondTradesDatePlanned 'Плановая дата вторых торгов'
						,epmi.ImplementationBalanceDate 'Дата реализации с баланса'
						,epmi.AmountImplementationBalance 'Сумма реализации с баланса'
						,eo.ReceiptReturnDate 'Дата возврата ИЛ на доработку'
						,monitoring.PledgeItemId 'id_залога'
						,saa.name 'статус_после_ареста'
						,epmbt.statusafterarrestcomment  'коммент_после_ареста'
						,ep.Id 'id_ИП'
						,cast(cpd.BirthdayDt as date) 'дата_рождения_должника'
						,fssp.name	'росп_наименование'
						,coalesce(fssp.NameRegion,'')+' '+coalesce(fssp.TypeRegion,'')+'., '
						 +coalesce(fssp.TypeLocation,'')+' '+coalesce(fssp.NameLocation,'')+'., '
						 +coalesce(fssp.NameCity,'')+' '+coalesce(fssp.TypeCity,'')+'., '
						 +coalesce(fssp.NameStreet,'')+' '+coalesce(fssp.TypeStreet,'')+'., '+coalesce(fssp.NumberHouse,'') 'росп_адрес'
						,eo.Comment
						,epmi.AmountSaleCar
into #udal_1
FROM            Stg._Collection.Deals AS													Deal LEFT OUTER JOIN
                         Stg._Collection.customers AS										c ON c.Id = Deal.IdCustomer LEFT OUTER JOIN
                         Stg._Collection.JudicialProceeding AS								jp ON Deal.Id = jp.DealId LEFT OUTER JOIN
                         Stg._Collection.JudicialClaims AS									jc ON jp.Id = jc.JudicialProceedingId LEFT OUTER JOIN
                         Stg._Collection.EnforcementOrders AS								eo ON jc.Id = eo.JudicialClaimId LEFT OUTER JOIN
                         Stg._Collection.EnforcementProceeding AS							ep ON eo.Id = ep.EnforcementOrderId LEFT OUTER JOIN
                         
						 Stg._Collection.EnforcementProceedingExcitation as					epe on epe.EnforcementProceedingId = ep.Id LEFT OUTER JOIN
						 Stg._Collection.EnforcementProceedingSPI as						SPI on SPI.EnforcementProceedingId = ep.Id LEFT OUTER JOIN
						 
						 Stg._Collection.collectingStage AS									cst_deals ON Deal.StageId = cst_deals.Id LEFT OUTER JOIN
                         Stg._Collection.collectingStage AS									cst_client ON c.IdCollectingStage = cst_client.Id LEFT OUTER JOIN
                         Stg._Collection.CustomerPersonalData AS							cpd ON cpd.IdCustomer = c.Id LEFT OUTER JOIN
                         [Stg].[_Collection].[DadataCleanFIO] AS							dcfio ON dcfio.Surname = c.LastName AND dcfio.Name = c.Name 
																								AND dcfio.Patronymic = c.MiddleName LEFT OUTER JOIN
                         [Stg].[_Collection].Courts AS										court ON court.Id = jp.CourtId LEFT OUTER JOIN
                         Stg._Collection.DepartamentFSSP AS									fssp ON epe.DepartamentFSSPId = fssp.Id LEFT OUTER JOIN
                         Stg._Collection.EnforcementProceedingMonitoring AS					monitoring ON ep.Id = monitoring.EnforcementProceedingId LEFT OUTER JOIN
                         
						 Stg._Collection.EnforcementProceedingMonitoringBeforeTrades as		epmbt on epmbt.EnforcementProceedingMonitoringId = monitoring.Id LEFT OUTER JOIN
						 Stg._Collection.EnforcementProceedingMonitoringFirstTrades as		epmft on epmft.EnforcementProceedingMonitoringId = monitoring.Id LEFT OUTER JOIN
						 Stg._Collection.EnforcementProceedingMonitoringSecondTrades as		epmst on epmst.EnforcementProceedingMonitoringId = monitoring.Id LEFT OUTER JOIN
						 Stg._Collection.EnforcementProceedingMonitoringImplementation as	epmi on epmi.EnforcementProceedingMonitoringId = monitoring.Id LEFT OUTER JOIN

						 [Stg].[_Collection].DealPledgeItem AS								dpi ON dpi.DealId = Deal.Id LEFT OUTER JOIN
                         [Stg].[_Collection].[PledgeItem] AS								pl ON pl.Id = dpi.PledgeItemId LEFT OUTER JOIN
                         [Stg].[_Collection].[Registration] AS								reg ON reg.IdCustomer = c.Id
						 left join [Stg].[_Collection].[DealStatus]							ds on Deal.idstatus = ds.id
						 left join #ka_new ka on ka.external_id = deal.Number and rn=1
						 left join (select DateResultOfCourtsDecisionBankrupt  = max(case when DateResultOfCourtsDecisionBankrupt is not null then DateResultOfCourtsDecisionBankrupt 
						else  
							case when CourtDecisionDate is not null then CourtDecisionDate
								else 
									case when CreateDate is not null then CreateDate
									else UpdateDate
								end
								end
						end),CustomerId  from Stg._Collection.[CustomerStatus] 
									where [CustomerStateId] in (16) --15
									and isActive = 1
									group by CustomerId) bankrupt on bankrupt.CustomerId = c.Id
						left join (select DateResultOfCourtsDecisionBankrupt  = max(case when DateResultOfCourtsDecisionBankrupt is not null then DateResultOfCourtsDecisionBankrupt 
						else  
							case when CourtDecisionDate is not null then CourtDecisionDate
								else 
									case when CreateDate is not null then CreateDate
									else UpdateDate
								end
								end
						end),CustomerId  from Stg._Collection.[CustomerStatus] 
									where [CustomerStateId] in (15) --15
									and isActive = 1
									group by CustomerId) bankrupt_not_confirm on bankrupt_not_confirm.CustomerId = c.Id
						left join [Stg].[_Collection].Employee AS emp ON c.ClaimantId = emp.id
						left join #payment_new p on p.IdDeal = Deal.id
						left join #payment_last p_l on p_l.IdDeal = Deal.id and p_l.rn=1 
						left join #payment_last_non_date p_l_non_date on p_l_non_date.IdDeal = Deal.id and p_l_non_date.rn=1 
						left join #ka_state ka_s on ka_s.Id = c.Id
						left join #BeforeGraph_data dpd on dpd.external_id = Deal.Number
						left join #BV_state bv on bv.Id = c.id
						left join [Stg].[_Collection].[HopelessCollection] hc on hc.DealId = Deal.id
						left join #Last_ClaimantId lcid on lcid.ObjectId = c.id
						left join stg.[_Collection].Employee empIP  on c.[ClaimantExecutiveProceedingId]  = empIP.id
						left join stg.[_Collection].StatusAfterArrest saa on monitoring.statusafterarrestid = saa.id 
WHERE        (eo.Id IS NOT NULL);
begin tran
   TRUNCATE TABLE [collection].[say_EnforcementOrders];
	insert [collection].[say_EnforcementOrders] --change [devDB].[dbo].say_EnforcementOrders
	select *
	from #udal_1;

commit tran
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
