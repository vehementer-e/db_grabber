-- =============================================
-- Author:		А.Никитин
-- Create date: 2023-11-01
-- Description:	DWH-2331 Разобраться в логике отчета Коллекшн. ИП. Аресты переданы в КА
-- =============================================
CREATE   PROC dbo.Report_Collection_Arest_in_agent_credits
as
begin
begin TRY
	SET XACT_ABORT ON;
	SET NOCOUNT ON;

	declare  @DateCalculate date = cast(dateadd(month,0, dateadd(year,0,getdate())) as date)
	declare  @dt_begin_of_month date = cast(format(cast('2020-03-01' as date),'yyyyMM01') as date)
	declare  @dt_next_month date = @DateCalculate 

	--TEST
	--SELECT @dt_begin_of_month = '2023-09-01', @dt_next_month = '2023-09-30'


	--конец месяца
	--DROP TABLE IF EXISTS #calend_eomonth

	--SELECT C.DT
	--INTO #calend_eomonth
	--FROM dwh2.Dictionary.calendar AS C
	--WHERE 1=1
	--	AND C.DT BETWEEN @dt_begin_of_month and @dt_next_month
	--	AND eomonth(C.DT) = C.DT
	--	--test
	--	--AND C.DT = '2023-09-30'

	-- найдем дату погашения (чтобы понять, что закрыт)
	DROP TABLE IF EXISTS #endedContracts
	   
	select d.Код
		, Период=dateadd(year,-2000,max(sd.Период))				
	into #endedContracts
	from stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
		join stg._1ccmr.Справочник_Договоры d on d.Ссылка=sd.договор
		join stg._1ccmr.Справочник_СтатусыДоговоров  ssd on ssd.Ссылка=sd.Статус
	where ssd.Наименование='Погашен'
	group by d.Код
	--примерно 79428

	DROP table IF EXISTS #loans

	SELECT DISTINCT 
		eo.Id idEnforcementOrders, 
		--jc.Id idJudicialClaims
		l.Id,
		l.Number,
		--l.Date,
		--l.Sum,
		--l.Term,
		--l.ProductType,
		--l.StageId,
		--l.LastPaymentDate,
		--l.LastPaymentSum,
		--l.CurrentAmountOwed,
		--l.DebtSum,
		--l.CreditAgencyStatus,
		--l.CreditAgencyName,
		--l.IdStatus,
		--l.IdCustomer,
		--l.OverdueDays,
		--l.PlaceOfContract,
		--l.RequestDate,
		--l.RequestNumber,
		--l.Phone,
		--l.CmrCustomerId,
		--l.CmrId,
		--l.InterestRate,
		--l.CmrRequestId,
		--l.CmrPublishDate,
		--l.OverdueStartDate,
		--l.Fulldebt,
		--l.DateOfChangePaymentDate,
		--l.PreviousPaymentDay,
		--l.CreateDate,
		--l.CreatedBy,
		--l.UpdateDate,
		--l.UpdatedBy,
		--l.DateStageWasLastUpdated,
		--l.IsNeedPTS,
		--l.CrmRequestDate,
		--l.InterestRate1,
		--l.IsPEP,
		--l.EngagementAgreementDate,
		--l.CreditVacationDateBegin,
		--l.CreditVacationDateEnd,
		--l.RiskSegmentId,
		--l.IsCreditVacation,
		--l.NextPayment,
		--l.FirstPayment,
		--l.HasEngagementAgreement,
		--l.NeedStartProcessJudicialProceeding,
		--l.IsSegmentVisible,
		--l.SegmentName,
		--l.SegmentNumber,
		--l.Fine,
		--l.OneDayLateDateMax,
		--l.OneDayLateDateMin,
		--l.[Percent],
		--l.StateFee,
		--l.AlternativeMatrixService,
		--l.TermOfService,
		--l.CreditVacationReason,
		--l.ControlDateArrivalOfValuesAtWithholding,
		--l.LastCommunicationsComment,
		--l.LastCommunicationsDate,
		--l.OfficeAddress,
		--l.IssueDate,
		--l.RepeatedCreditVacationRate,
		--l.RepeatedCreditVacationRateStartDate,
		--l.CallingCreditHolidays,
		--l.StateDate,
		--l.Probation,
		--l.DWHInsertedDate,
		--l.ProcessGUID,
		--l.CheckOutComment,
		--l.Installment,
		--l.IsFreeze,
		--l.LastCheckOutDate,
		--l.Overpayment,
		--l.PledgeAgreementId,
		--l.NeedToStartLegalProcess,
		--l.SmartInstallment
		--, cst_deals.Name as 'StageDealFull'
		c.id as ClientIdFull,
		--, c.LastName + ' '  + c.Name + ' ' + c.MiddleName 'ClientFull' 
		--, cst_client.Name as 'StageClientFull'
		--, reg.Region
		--,  reg.ActualRegion
		ec.Период ДатаПогашения,
			--,l.id as DealIdFull
		dp.PledgeItemId,
		ep.id as idEnforcementProceeding,
		--, pledge.vin
		rn_EnforcementOrders = ROW_NUMBER() over(partition by l.id  order by isnull(eo.Id,0) desc)
	into #loans
	FROM  [Stg].[_Collection].Deals l
		left join [Stg].[_Collection].customers c on c.id=l.IdCustomer
		join [Stg].[_Collection].JudicialProceeding  jp on l.Id = jp.DealId
		left join [Stg].[_Collection].JudicialClaims jc on jp.Id = jc.JudicialProceedingId -- суб
		left join [Stg].[_Collection].[EnforcementOrders]  eo  on jc.Id = eo.JudicialClaimId
		left join [Stg].[_Collection].[EnforcementProceeding]  ep  on ep.EnforcementOrderId = eo.id
		left join  [Stg].[_Collection].[CollectingStage] cst_deals  on  l.StageId = cst_deals.id
		left join  [Stg].[_Collection].[CollectingStage] cst_client  on  c.[IdCollectingStage] = cst_client.id
		left join [Stg].[_Collection].[registration] reg on c.id = reg.[IdCustomer]
		left join #endedContracts ec on ec.Код = l.Number
		left join [Stg].[_Collection].[DealPledgeItem] dp on dp.DealId = l.Id
		left join [Stg].[_Collection].[PledgeItem] pledge on  pledge.id = dp.PledgeItemId
	--примерно 30276

	--   
	DELETE FROM #loans 
	WHERE rn_EnforcementOrders>1 
		AND idEnforcementOrders is  null
	--примерно 360


	;with monitoring as
	(
	select 
		  monitoring.id
		, ArestCarDate1 = bt.ArestCarDate
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
		, im.ImplementationBalanceDate
		, im.AmountImplementationBalance
		--, im.ImplementationBalanceDate
		, ft.FirstTradesDate
		, ft.AmountFirstTrades
		, st.SecondTradesDate
		, im.SaleCarDate
		, im.AmountSaleCar
		, st.AmountSecondTrades
		, monitoring.UpdateDate
	FROM [Stg].[_Collection].[EnforcementProceedingMonitoring] monitoring 
	left join [Stg].[_Collection].EnforcementProceedingMonitoringBeforeTrades bt on bt.EnforcementProceedingMonitoringId = monitoring.Id
	left join [Stg].[_Collection].[EnforcementProceedingMonitoringFirstTrades] ft on ft.EnforcementProceedingMonitoringId = monitoring.Id
	left join [Stg].[_Collection].[EnforcementProceedingMonitoringSecondTrades] st on st.EnforcementProceedingMonitoringId = monitoring.Id
	left join [Stg].[_Collection].[EnforcementProceedingMonitoringImplementation] im on im.EnforcementProceedingMonitoringId = monitoring.Id
	),
	monitor as
	(
		select epm.* 
			, ArestCarDate2 = max(epm.ArestCarDate1) over (partition by l.PledgeItemId)
			, rn = ROW_NUMBER() over( partition by epm.EnforcementProceedingId order by isnull(epm.UpdateDate, '2099-01-01') desc,epm.id desc)
		from monitoring AS epm 
			left join #loans AS l on l.idEnforcementProceeding = epm.EnforcementProceedingId
	)
	select M.*
	INTO #monitor
	FROM monitor AS M
	WHERE M.rn=1
		AND M.ArestCarDate2 BETWEEN @dt_begin_of_month and @dt_next_month




	--DROP TABLE IF EXISTS #t_EnforcementOrders
	--CREATE TABLE #t_EnforcementOrders(
	--	Конец_месяца date,
	--	Уникальные_клиенты int,
	--	Сумма_по_ИЛ numeric(18, 2)
	--)

	DROP TABLE IF EXISTS #t_Arest_in_agent_credits
	CREATE TABLE #t_Arest_in_agent_credits(
		Период varchar(50), 
		Неделя int,
		Уникальные_клиенты int,
		Сумма_по_ИЛ numeric(18, 2)
	)

	INSERT #t_Arest_in_agent_credits
	(
	    Период,
	    Неделя,
	    Уникальные_клиенты,
	    Сумма_по_ИЛ
	)
	SELECT 
		Период = A.year_month_name, 
		Неделя = A.id_yearweek,
		Уникальные_клиенты = count(DISTINCT A.Уникальные_клиенты),
		Сумма_по_ИЛ = sum(A.Сумма_по_ИЛ)
	FROM (
		SELECT DISTINCT
			C.year_month_name, 
			C.id_yearweek,
			idDeal = Deals.Id,
			Уникальные_клиенты = Deals.ClientIdFull,
			Сумма_по_ИЛ = eo.Amount
		FROM Stg._Collection.EnforcementOrders as eo -- исполнительный лист
			--INNER JOIN #loans AS Deals

			--INNER JOIN #loans_calend_eomonth AS Deals
			--	ON Deals.idEnforcementOrders = eo.id

			--INNER JOIN (
			--	SELECT 
			--		Дата = C.DT,
			--		L.*
			--	--INTO #loans_calend_eomonth
			--	FROM #calend_eomonth AS C
			--		INNER JOIN #loans AS L
			--			ON 1=1
			--	) AS Deals
			--	ON Deals.idEnforcementOrders = eo.id

			INNER JOIN #loans AS Deals
				ON Deals.idEnforcementOrders = eo.id

			--left join (
			--	SELECT 
			--		CustomerId,
			--		bancruptcy_date = 
			--			max(
			--				CASE 
			--					WHEN DateResultOfCourtsDecisionBankrupt is not null then DateResultOfCourtsDecisionBankrupt 
			--					ELSE  
			--						CASE
			--							WHEN CourtDecisionDate is not null then CourtDecisionDate
			--							ELSE
			--								CASE 
			--									WHEN CreateDate is not null then CreateDate
			--									ELSE UpdateDate
			--								END
			--						END
			--				END
			--			)
			--		from  Stg._Collection.CustomerStatus 
			--		where CustomerStateId in (16)
			--		group by CustomerId
			--	) AS Bankrupt
			--	ON Bankrupt.CustomerId = Deals.ClientIdFull

			INNER JOIN (
				--EnforcementProceeding ep 
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
				from Stg._Collection.EnforcementProceeding AS ep
					left join Stg._Collection.EnforcementProceedingExcitation AS epe
						ON ep.id = epe.EnforcementProceedingId
					left join Stg._Collection.EnforcementProceedingSPI AS eps
						ON ep.id = eps.EnforcementProceedingId
				) AS ep
				ON eo.id = ep.EnforcementOrderId -- исполнительное производство

			INNER JOIN #monitor AS monitoring 
				ON ep.id = monitoring.EnforcementProceedingId

			INNER JOIN dwh2.cubes.v_Collection_Calendar AS C
				ON C.DT = monitoring.ArestCarDate2

		WHERE 1=1
			--AND monitoring.ArestCarDate2 BETWEEN @dt_begin_of_month and @dt_next_month

			----И isSumEnforcementOrder NOT IN (0)
			----И iif(УчетнаяДата IS NOT NULL, iif([Сумма по ИЛ] IS NULL, 0, 1), NULL) NOT IN (0, 100)
			--AND iif(eo.Amount IS NULL, 0, 1) NOT IN (0)
			----И isActive NOT IN (0, 100)
			--AND iif(
			--		cast(coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date,ep.ExcitationDate) as date) is null, 
			--		100, 
			--		iif(cast(coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date,ep.ExcitationDate) as date) <= Deals.Дата --'2023-09-30'
			--		,1,0
			--	)
			--) NOT IN (0, 100)
			----И isBankruptFromDate NOT IN (1)
			--AND iif(Bankrupt.bancruptcy_date is null,
			--		0,
			--		iif(Bankrupt.bancruptcy_date <= Deals.Дата, 1,0)
			--	) NOT IN (1)
			----И ПогашенНаДату NOT IN (1)
			--AND iif(Deals.ДатаПогашения is null, 
			--		0,
			--		iif(cast(Deals.ДатаПогашения as date) <= Deals.Дата, 1,0)
			--	) NOT IN (1)
			----И [Статья46] NOT IN (1)
			--AND iif(charindex('46', isnull(ep.CommentExcitationEnforcementProceeding,'')) > 0, 1, 0) NOT IN (1)
		) AS A
	GROUP BY A.year_month_name, A.id_yearweek


	SELECT 
		T.Период,
		T.Неделя,
		T.Уникальные_клиенты,
		T.Сумма_по_ИЛ 
	FROM #t_Arest_in_agent_credits AS T
	ORDER BY T.Неделя


END try
begin catch
	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end
