-- =============================================
-- Author:		А.Никитин
-- Create date: 2026-01-24
-- Description:	DWH-445 Переписать отчет Коллекшн. ИП_Excel
-- =============================================
/*
EXEC Reports.dbo.Report_EnforcementOrders
	@DealNumber = '17100910070002'
	,@isDebug = 1
*/
create   PROC dbo.Report_EnforcementOrders
	@DealNumber varchar(100) = NULL
	,@ProcessGUID varchar(36) = NULL -- guid процесса
	,@isDebug int = 0
AS
BEGIN
	SET NOCOUNT ON;
BEGIN TRY

	SELECT @isDebug = isnull(@isDebug, 0)
	select @ProcessGUID = isnull(@ProcessGUID, newid())

	DECLARE @eventType nvarchar(50)
	DECLARE @description nvarchar(1024), @message nvarchar(1024), @error_number int

	--test
	--select @DealNumber = '17100910070002'

	drop table if exists #t_Deal
	create table #t_Deal(DealId int, DealNumber varchar(30))

	insert #t_Deal(DealId, DealNumber)
	select distinct Deal.Id, Deal.Number
	FROM Stg._Collection.Deals AS Deal
		inner join Stg._Collection.customers AS c ON c.Id = Deal.IdCustomer
		inner join Stg._Collection.JudicialProceeding AS jp ON Deal.Id = jp.DealId
		inner join Stg._Collection.JudicialClaims AS jc ON jp.Id = jc.JudicialProceedingId
		inner join Stg._Collection.EnforcementOrders AS eo ON jc.Id = eo.JudicialClaimId
	where 1=1
		and (Deal.Number = @DealNumber or @DealNumber is null)

	create index ix1 on #t_Deal(DealId)
	create index ix2 on #t_Deal(DealNumber)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Deal
		SELECT * INTO ##t_Deal FROM #t_Deal
	END

	drop table if exists #t_Customer
	create table #t_Customer(CustomerId int)

	insert #t_Customer(CustomerId)
	select distinct CustomerId = d.IdCustomer
	from #t_Deal as t
		inner join Stg._Collection.Deals as d
			on d.Id = t.DealId

	create index ix1 on #t_Customer(CustomerId)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Customer
		SELECT * INTO ##t_Customer FROM #t_Customer
	END

	drop table if exists #t_EnforcementOrder
	create table #t_EnforcementOrder(EnforcementOrderId int)

	insert #t_EnforcementOrder(EnforcementOrderId)
	select EnforcementOrderId = eo.Id
	FROM #t_Deal as d
		inner join Stg._Collection.JudicialProceeding AS jp 
			on jp.DealId = d.DealId
		inner join Stg._Collection.JudicialClaims AS jc 
			ON jp.Id = jc.JudicialProceedingId
		inner join Stg._Collection.EnforcementOrders AS eo
			ON jc.Id = eo.JudicialClaimId

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_EnforcementOrder
		SELECT * INTO ##t_EnforcementOrder FROM #t_EnforcementOrder
	END

	-------------------------------------------------------------------------
	drop table if exists #t_ka_new

	select [Наименование КА] 
		, [Дата передачи в КА]
		, [Дата отзыва]
		, external_id
		, rn = ROW_NUMBER() over(partition by external_id order by [Дата передачи в КА] desc)
	--DWH-257
	into #t_ka_new
	--select count(*) -- 3005
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
		where 1=1
			and (d.Number = @DealNumber or @DealNumber is null)
	) as t
	where [Текущий статус] <> N'Договор отозван из КА' 

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ka_new
		SELECT * INTO ##t_ka_new FROM #t_ka_new
	END

	-------------------------------------------------------------------------
	drop table if exists #t_payment_new

	select 
		sum(p.Amount) as Amount, 
		p.IdDeal
	into #t_payment_new
	--select top 100 * 
	from Stg._Collection.Payment as p
		inner join #t_Deal as d
			on d.DealId = p.IdDeal
	where 1=1
		and (
			year(p.PaymentDt) = year(getdate()) 
			and month(p.PaymentDt) = month(getdate())
		)
	group by p.IdDeal

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_payment_new
		SELECT * INTO ##t_payment_new FROM #t_payment_new
	END

	-------------------------------------------------------------------------
	drop table if exists #t_payment_last

	select 
		SUM(Amount) as Amount, 
		p.IdDeal,
		cast(p.PaymentDt as date) as PaymentDt
		,rn = ROW_NUMBER() over(
			partition by p.idDeal 
			order by cast(p.PaymentDt as date) desc
		)
	into #t_payment_last
	from Stg._Collection.Payment as p
		inner join #t_Deal as d
			on d.DealId = p.IdDeal
	where 1=1
		and (
			year(p.PaymentDt) = year(getdate()) 
			and month(p.PaymentDt) = month(getdate())
		)
	group by p.IdDeal, cast(p.PaymentDt as date)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_payment_last
		SELECT * INTO ##t_payment_last FROM #t_payment_last
	END

	-------------------------------------------------------------------------
	drop table if exists #t_payment_last_non_date

	select 
		SUM(p.Amount) as Amount, 
		p.idDeal,
		cast(p.PaymentDt as date) PaymentDt
		,rn = ROW_NUMBER() over(
			partition by p.idDeal 
			order by cast(p.PaymentDt as date) desc
		)
	into #t_payment_last_non_date
	from  stg._Collection.Payment as p
		inner join #t_Deal as d
			on d.DealId = p.IdDeal
	group by p.idDeal, cast(p.PaymentDt as date)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_payment_last_non_date
		SELECT * INTO ##t_payment_last_non_date FROM #t_payment_last_non_date
	END
	-------------------------------------------------------------------------
	drop table if exists #t_ka_risk

	select
		t.agent_name
		, t.st_date
		, t.end_date
		, t.external_id
		, rn = ROW_NUMBER() over(partition by t.external_id order by t.st_date desc)
	--DWH-257
	into #t_ka_risk
	from (
		select
			external_id = d.Number
			,agent_name = a.AgentName
			,reestr = cat.RegistryNumber
			,st_date  = cat.TransferDate
			,end_date = isnull(cat.ReturnDate, cat.PlannedReviewDate)
		from Stg._collection.CollectingAgencyTransfer as cat
			inner join Stg._collection.Deals as d
				on d.Id = cat.DealId
			inner join Stg._collection.CollectorAgencies as a
				on a.Id = cat.CollectorAgencyId
		where 1=1
			and (d.Number = @DealNumber or @DealNumber is null)
	) as t

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ka_risk
		SELECT * INTO ##t_ka_risk FROM #t_ka_risk
	END
	-------------------------------------------------------------------------
	drop table if exists #t_ka_state

	select distinct c.id --*
	into #t_ka_state
    from stg._Collection.CustomerStatus cs
		join stg._Collection.Customers c 
			on cs.CustomerId=c.id
		join stg._collection.CustomerState st 
			on st.id=cs.CustomerStateId
		join #t_Customer as t
			on t.CustomerId = c.Id
	where 1=1
		and st.name  in ('КА') 
		and cs.IsActive = 1

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ka_state
		SELECT * INTO ##t_ka_state FROM #t_ka_state
	END

	-------------------------------------------------------------------------
	drop table if exists #t_BV_state

	select distinct c.id --*
	into #t_BV_state
	from stg._Collection.CustomerStatus cs
		join stg._Collection.Customers c 
			on cs.CustomerId=c.id
		join stg._collection.CustomerState st 
			on st.id=cs.CustomerStateId
		join #t_Customer as t
			on t.CustomerId = c.Id
	where st.name  in ('БВ') 
		--and IsActive = 1

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_BV_state
		SELECT * INTO ##t_BV_state FROM #t_BV_state
	END

	-------------------------------------------------------------------------
	drop table if exists #t_FraudConfirmed_state

	select distinct c.id --*
	into #t_FraudConfirmed_state
    from stg._Collection.CustomerStatus cs
         join stg._Collection.Customers c 
			on cs.CustomerId=c.id
	    join stg._collection.CustomerState st
			on st.id=cs.CustomerStateId
		join #t_Customer as t
			on t.CustomerId = c.Id
    where st.name  in ('Fraud подтвержденный') 
		--and IsActive = 1

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_FraudConfirmed_state
		SELECT * INTO ##t_FraudConfirmed_state FROM #t_FraudConfirmed_state
	END

	-------------------------------------------------------------------------
	drop table if exists #t_HardFraud_state

	select distinct c.id --*
	into #t_HardFraud_state
	from stg._Collection.CustomerStatus cs
		join stg._Collection.Customers c
			on cs.CustomerId=c.id
		join stg._collection.CustomerState st
			on st.id=cs.CustomerStateId
		join #t_Customer as t
			on t.CustomerId = c.Id
	where st.name in ('HardFraud') 
		--and IsActive = 1

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_HardFraud_state
		SELECT * INTO ##t_HardFraud_state FROM #t_HardFraud_state
	END
	-------------------------------------------------------------------------
	drop table if exists #t_closed_data

	-- найдем dpd на дату закрытия
	select 
		--d.СсылкаДоговораЗайма as id1
		b.d AS ДатаДП
		, b.* 
	into #t_closed_data
	from #t_Deal as t
		inner join dwh2.dbo.dm_CMRStatBalance b with (nolock)
			on b.external_id = t.DealNumber
		--inner join dwh2.dm.ДоговорЗайма as d
		--	on b.external_id = d.КодДоговораЗайма
	where b.ContractEndDate = b.d

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_closed_data
		SELECT * INTO ##t_closed_data FROM #t_closed_data
	END

	-------------------------------------------------------------------------
	drop table if exists #t_BeforeGraph_data

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
	into #t_BeforeGraph_data
	from #t_closed_data AS t
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

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_BeforeGraph_data
		SELECT * INTO ##t_BeforeGraph_data FROM #t_BeforeGraph_data
	END
	-------------------------------------------------------------------------
	drop table if exists #t_Last_ClaimantId

	select 
		OldValue,
		ChangeDate,
		ObjectId, 
		LastEmployeyFIO = isnull(emp.LastName,'') + ' ' + isnull(emp.FirstName,'') + ' ' + isnull(emp.MiddleName,'')
	into #t_Last_ClaimantId
	from (
		select 
			h.*
			,rn = row_number() over(
				partition by h.ObjectId 
				order by h.ChangeDate desc
			)
		from Stg._Collection.CustomerHistory as h
			join #t_Customer as t
				on t.CustomerId = h.ObjectId
		where h.Field = 'Ответственный взыскатель'
			and h.NewValue is null
			and isNumeric(OldValue) = 1
			--and h.ObjectId = 13945
	) as history_emp
		left join Stg._Collection.Employee AS emp 
			ON history_emp.OldValue = emp.id
	where history_emp.rn = 1

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Last_ClaimantId
		SELECT * INTO ##t_Last_ClaimantId FROM #t_Last_ClaimantId
	END

	-------------------------------------------------------------------------
	drop table if exists #t_EnforcementProceeding

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
	into #t_EnforcementProceeding
	--select count(*) -- 29726
	from #t_EnforcementOrder as eo
		inner join Stg._Collection.EnforcementProceeding as ep
			on ep.EnforcementOrderId = eo.EnforcementOrderId
		left join Stg._Collection.EnforcementProceedingExcitation as epe
			on ep.id = epe.EnforcementProceedingId
		left join Stg._Collection.EnforcementProceedingSPI as eps
			on ep.id = eps.EnforcementProceedingId

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_EnforcementProceeding
		SELECT * INTO ##t_EnforcementProceeding FROM #t_EnforcementProceeding
	END

	-------------------------------------------------------------------------
	drop table if exists #t_monitoring

	select distinct
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
	into #t_monitoring		
	--select count(*) -- 29464
	--FROM Stg._Collection.EnforcementProceedingMonitoring as monitoring 
	from #t_EnforcementProceeding as ep
		inner join Stg._Collection.EnforcementProceedingMonitoring as monitoring
			ON monitoring.EnforcementProceedingId = ep.Id
		left join Stg._Collection.EnforcementProceedingMonitoringBeforeTrades as bt
			on bt.EnforcementProceedingMonitoringId = monitoring.Id
		left join Stg._Collection.EnforcementProceedingMonitoringFirstTrades as ft
			on ft.EnforcementProceedingMonitoringId = monitoring.Id
		left join Stg._Collection.EnforcementProceedingMonitoringSecondTrades as st
			on st.EnforcementProceedingMonitoringId = monitoring.Id
		left join Stg._Collection.EnforcementProceedingMonitoringImplementation as im
			on im.EnforcementProceedingMonitoringId = monitoring.Id

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_monitoring
		SELECT * INTO ##t_monitoring FROM #t_monitoring
	END

	-------------------------------------------------------------------------
	drop table if exists #t_Result

	SELECT distinct
		Deal.Number AS '№ договора'
		, c.LastName AS 'Фамилия'
		, c.Name AS 'Имя'
		, c.MiddleName AS 'Отчество'
		,  isnull(c.LastName,' ') + ' ' + isnull(c.Name,' ')  + ' ' + isnull(c.MiddleName,' ') AS 'ФИО'
		, cpd.BirthdayDt AS 'Дата рождения'
		, cpd.BirthPlace AS 'Место рождения'
		, cpd.Series AS 'Серия паспорта'
		, cpd.Number AS '№ паспорта'
		, cpd.PassportIssueDt AS 'Дата выдачи'
		, cpd.KpPassport AS 'Код подразделения'
		, cpd.WhoIssuedPassport AS 'Кем выдан паспорт'
		, dcfio.Genitive AS 'ФИО клиента в именительном падеже '
		, dcfio.Dative AS 'ФИО клиента в родительном падеже'
		, dcfio.Ablative AS 'ФИО клиента в творительном падеже'
		, reg.PermanentRegisteredAddress AS 'Адрес постоянной регистрации'
		, reg.ActualAddress AS 'Адрес фактического места жительства'
		, pl.Brand AS 'Марка, модель'
		, pl.Model as 'Модель' 
		, pl.YearOfIssue AS 'Год выпуска'
		, pl.Vin AS 'VIN'
		, pl.RegNumber AS 'Гос. номер'
		, court.Name AS 'Наименование суда'
		, ISNULL(eo.Number, 'Не указан') AS '№ ИЛ'
		, eo.Date AS 'Дата ИЛ'
		, eo.AcceptanceDate  ДатаПринятияИЛ
		, датаПринятияИЛСоставная = cast(coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date,ep.ExcitationDate) as date)
		, CASE 
		WHEN eo.Type = 1 THEN 'Обеспечительные меры' 
		WHEN eo.Type = 2 THEN 'Денежное требование' 
		WHEN eo.Type = 3 THEN 'Обращение взыскания' 
		WHEN eo.Type = 4 THEN 'Взыскание и обращение взыскания' 
		ELSE
			'Не указан' 
		END AS 'Тип ИЛ', eo.Amount AS 'Сумма ИЛ, руб.'
		, case 
		when eo.Accepted = 1 then 'Да'  
		when eo.Accepted = 0 then 'Нет' 
		else 'Другое' 
		end 'ИЛ принят'
		, fssp.Name AS 'Наименование отдела ФССП'
		, ep.ExcitationDate AS 'Дата возбуждения ИП'
		, ep.CaseNumberInFSSP AS '№ дела в ФССП'
		, ep.NameBailiff AS 'ФИО пристава'
		, ep.EmployerName AS 'Наименование работодателя'
		, ep.EmployerTIN AS 'ИНН работодателя'
		, ep.DateApplicationWithholding AS 'Дата последнего заявления на удержание'
		, ep.[OrderOnHoldDate] AS 'Дата постановления на удержание'
		, monitoring.ArestCarDate AS 'Дата ареста авто'
		, monitoring.CarStoragePlace AS 'Место хранения авто'
		, monitoring.ReevaluationDate AS 'Дата переоценки'
		, monitoring.FirstTradesDatePlanned AS 'Плановая дата первых торгов'
		, monitoring.FirstTradingResult AS 'Результат первых торгов'
		, monitoring.SecondTradesDatePlanned AS 'Плановая дата вторых торгов'
		, monitoring.SecondTradingResult AS 'Результат вторых торгов'
		, monitoring.DecisionDepositToBalance AS ' Решение о принятии на баланс'
		, monitoring.AdoptionBalanceDate AS 'Дата принятия на баланс'
		, ep.EndDate AS 'Дата окончания'		
		, ep.CommentExcitationEnforcementProceeding AS 'Основания окончания ИП'
		, ds.Name as 'Статус договора'
		, iif(ds.Name = 'Погашен', 'Да', 'Нет') as 'Погашен'
		, [Состояние в КА] = iif(ka_s.id is null, 'Нет','Да')
		, ka.[Наименование КА]
		, iif(bankrupt.DateResultOfCourtsDecisionBankrupt is not null, 'Да','Нет') as 'Бакнрот'	
		, bankrupt.DateResultOfCourtsDecisionBankrupt 'Дата банкротства подверждено решением'				
		, iif(bankrupt_not_confirm.DateResultOfCourtsDecisionBankrupt is not null, 'Да','Нет') as 'Бакнрот не подтвержденный'	
		, bankrupt_not_confirm.DateResultOfCourtsDecisionBankrupt 'Дата банкротства не подверждено'					
		, isnull(emp.LastName,'') + '  ' + isnull(emp.FirstName,'') +   '  ' + isnull(emp.MiddleName,'') 'Ответственный взыскатель'
		, JudgmentEntryIntoForceDate 'Вступпление решения суда в силу'
		, ka.[Дата передачи в КА]
		, ka.[Дата отзыва]					
		, NULL [Наименование КА риск]
		, NULL [Дата передачи в КА риск]
		, NULL [Дата возврата из КА риск]
		, p.Amount 'Сумма платежей за месяц'
		, p_l.Amount 'Сумма последнего платежа в день'
		, p_l.PaymentDt 'Дата последнего платежа в месяце'
		, p_l_non_date.Amount 'Сумма последнего платежа'
		, p_l_non_date.PaymentDt 'Дата последнего платежа'
		, cast(Deal.Date as date) 'Дата договора'
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
		, hc.IsAgreed  'БВ наличие соглашения'

			-- ПДП
		, dpd.d 'Дата ПДП'
		, [Сумма ПДП] = dpd.[основной долг уплачено] + dpd.[Проценты уплачено] + dpd.ПениУплачено + dpd.ГосПошлинаУплачено
		, dpd.dpd1 'DPD на Дата ПДП'
		, lcid.LastEmployeyFIO 'Ответственный взыскатель последний'
		, lcid.ChangeDate 'Дата последнего взыскателя'
		, monitoring.AmountDepositToBalance AS 'Сумма принятия на баланс'

		-- 08_09_2020
		, [Отправлено в РОСП] = ep.ErrorCorrectionNumberDate
		, iif(empIP.LastName is null , 'Не назначен', empIP.LastName + ' '  + empIP.FirstName + ' ' + empIP.MiddleName) 'КураторИП'
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
	into #t_Result
	from #t_Deal as d
		inner join Stg._Collection.Deals AS Deal
			on Deal.Id = d.DealId
		inner join Stg._Collection.customers AS c ON c.Id = Deal.IdCustomer
		inner join Stg._Collection.JudicialProceeding AS jp ON Deal.Id = jp.DealId
		inner join Stg._Collection.JudicialClaims AS jc ON jp.Id = jc.JudicialProceedingId
		inner join Stg._Collection.EnforcementOrders AS eo ON jc.Id = eo.JudicialClaimId

		left join #t_EnforcementProceeding as ep ON eo.Id = ep.EnforcementOrderId 
						 
		left join Stg._Collection.collectingStage AS cst_deals ON Deal.StageId = cst_deals.Id
		left join Stg._Collection.collectingStage AS cst_client ON c.IdCollectingStage = cst_client.Id
		left join Stg._Collection.CustomerPersonalData AS cpd ON cpd.IdCustomer = c.Id
		left join Stg._Collection.DadataCleanFIO AS dcfio 
			ON dcfio.Surname = c.LastName AND dcfio.Name = c.Name AND dcfio.Patronymic = c.MiddleName
		left join Stg._Collection.Courts AS court 
			ON court.Id = jp.CourtId
		left join Stg._Collection.DepartamentFSSP AS fssp
			ON ep.DepartamentFSSPId = fssp.Id 
		left join #t_monitoring as monitoring ON ep.Id = monitoring.EnforcementProceedingId 
		left join Stg._Collection.EnforcementProceedingMonitoringBeforeTrades bt 
			on bt.EnforcementProceedingMonitoringId = monitoring.Id
		left join Stg._Collection.DealPledgeItem AS dpi ON dpi.DealId = Deal.Id
		left join Stg._Collection.PledgeItem AS pl
			ON pl.Id = dpi.PledgeItemId
		left join Stg._Collection.Registration AS reg
			ON reg.IdCustomer = c.Id
		left join Stg._Collection.DealStatus ds
			on Deal.idstatus = ds.id
		left join (select * from #t_ka_new where rn=1) ka 
			on ka.external_id = deal.Number
		-- left join (select * from ka_risk where rn=1) kaRisk on kaRisk.external_id = deal.Number
		left join (
			select 
				DateResultOfCourtsDecisionBankrupt = 
				max(
					case 
						when cs.DateResultOfCourtsDecisionBankrupt is not null 
						then cs.DateResultOfCourtsDecisionBankrupt 
					else  
						case 
							when cs.CourtDecisionDate is not null 
							then cs.CourtDecisionDate
						else 
							case 
								when cs.CreateDate is not null 
								then cs.CreateDate
							else cs.UpdateDate
							end
						end
					end
				),
				cs.CustomerId
			from Stg._Collection.CustomerStatus as cs
				join #t_Customer as t
					on t.CustomerId = cs.CustomerId
			where CustomerStateId in (16) --15
				and isActive = 1
				--and  DateResultOfCourtsDecisionBankrupt is not null
			group by cs.CustomerId
			) as bankrupt 
			on bankrupt.CustomerId = c.Id
		left join (
			select 
				DateResultOfCourtsDecisionBankrupt = 
					max(
						case 
							when cs.DateResultOfCourtsDecisionBankrupt is not null 
							then cs.DateResultOfCourtsDecisionBankrupt 
						else  
							case 
								when cs.CourtDecisionDate is not null 
								then cs.CourtDecisionDate
							else 
								case 
									when cs.CreateDate is not null 
									then cs.CreateDate
								else cs.UpdateDate
								end
							end
						end
					),
				cs.CustomerId
			from Stg._Collection.CustomerStatus as cs
				join #t_Customer as t
					on t.CustomerId = cs.CustomerId
			where cs.CustomerStateId in (15) --15
				and isActive = 1
				--and  DateResultOfCourtsDecisionBankrupt is not null
			group by cs.CustomerId
			) bankrupt_not_confirm 
			on bankrupt_not_confirm.CustomerId = c.Id
	left join Stg._Collection.Employee AS emp 
		ON c.ClaimantId = emp.id
	left join #t_payment_new as p 
		on p.IdDeal = Deal.id
	left join #t_payment_last as p_l 
		on p_l.IdDeal = Deal.id and p_l.rn=1 
	left join #t_payment_last_non_date as p_l_non_date 
		on p_l_non_date.IdDeal = Deal.id and p_l_non_date.rn=1 
						
	left join #t_ka_state as ka_s 
		on ka_s.Id = c.Id
	--	left join bankropt_state_conf bankropt_s_c on bankropt_s_c.id=c.id
	--	left join bankropt_state_not_conf bankropt_s_n_c on bankropt_s_n_c.id=c.id
	left join #t_BeforeGraph_data as dpd 
		on dpd.external_id = Deal.Number
	--left join stg._collection.ImplementationProcess impprocess on pl.id = impprocess.PledgeItemId
	--left join [Stg].[_Collection].[Settlement] s on s.IdCustomer = c.id
	left join #t_BV_state as bv 
		on bv.Id = c.id
	--left join FraudConfirmed_state fc on fc.Id = c.id
	--left join HardFraud_state hf on hf.Id = c.id
	left join Stg._Collection.HopelessCollection hc 
		on hc.DealId = Deal.id
	left join #t_Last_ClaimantId as lcid 
		on lcid.ObjectId = c.id
	left join stg._Collection.Employee as empIP
		on c.ClaimantExecutiveProceedingId = empIP.id
	left join Stg._Collection.StatusAfterArrest as saa
		on saa.id = monitoring.StatusAfterArrestId
	WHERE (eo.Id IS NOT NULL)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Result
		SELECT * INTO ##t_Result FROM #t_Result
	END

	-----------------------------------------------
	select *
	from #t_Result
	-----------------------------------------------
END TRY
BEGIN CATCH
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	IF @@TRANCOUNT > 0
			ROLLBACK;

	SELECT @message = concat(
		'EXEC dbo.Report_EnforcementOrders ',
		--'@Page=''', @Page, ''', ',
		--'@dtFrom=', iif(@dtFrom IS NULL, 'NULL', ''''+convert(varchar(10), @dtFrom, 120)+''''), ', ',
		--'@dtTo=', iif(@dtTo IS NULL, 'NULL', ''''+convert(varchar(10), @dtTo, 120)+''''), ', ',
		'@ProcessGUID=', iif(@ProcessGUID IS NULL, 'NULL', ''''+@ProcessGUID+''''), ', ',
		'@isDebug=', convert(varchar(10), @isDebug)
	)

	--SELECT @eventType = concat(@Page, ' ERROR')
	SELECT @eventType = 'ERROR'

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = 'dbo.Report_EnforcementOrders',
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 0,
		@ProcessGUID = @ProcessGUID
	
	;THROW 51000, @description, 1
END CATCH


END