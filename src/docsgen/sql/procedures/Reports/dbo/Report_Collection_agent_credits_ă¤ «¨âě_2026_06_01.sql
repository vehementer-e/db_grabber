-- =============================================
-- Author:		А.Никитин
-- Create date: 2023-11-14
-- Description:	DWH-2330 Разобраться в логике отчета Коллекшн. ИП. Коллекторские агенства
-- =============================================
CREATE PROC dbo.Report_Collection_agent_credits
as
begin
begin TRY
	SET XACT_ABORT ON;
	SET NOCOUNT ON;

	declare  @DateCalculate date = cast(dateadd(month,0, dateadd(year,0,getdate())) as date)
	declare  @dt_begin_of_month date = cast(format(cast('2020-03-01' as date),'yyyyMM01') as date)
	declare  @dt_next_month date = @DateCalculate 

	--конец месяца
	DROP TABLE IF EXISTS #calend_eomonth

	SELECT C.DT
	INTO #calend_eomonth
	FROM dwh2.Dictionary.calendar AS C
	WHERE 1=1
		AND C.DT BETWEEN @dt_begin_of_month and @dt_next_month
		AND eomonth(C.DT) = C.DT
		--test
		--AND C.DT = '2023-09-30'
		--AND C.DT = '2022-02-28'

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
		--, dp.PledgeItemId
		--, ep.id as idEnforcementProceeding
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

	/*
	DROP TABLE IF EXISTS #loans_calend_eomonth

	SELECT 
		Дата = C.DT,
		L.*
	INTO #loans_calend_eomonth
	FROM #calend_eomonth AS C
		INNER JOIN #loans AS L
			ON 1=1

	CREATE CLUSTERED INDEX clix_Id_Дата ON #loans_calend_eomonth(Id, Дата)
	*/

	--DROP TABLE IF EXISTS #t_EnforcementOrders
	--CREATE TABLE #t_EnforcementOrders(
	--	Конец_месяца date,
	--	Уникальные_клиенты int,
	--	Сумма_по_ИЛ numeric(18, 2)
	--)

	DROP TABLE IF EXISTS #t_Collection_agent_credits
	CREATE TABLE #t_Collection_agent_credits
	(
		Конец_месяца date,
		Уникальные_клиенты int,
		Коллекторское_агенство nvarchar(255)
	)


	--INSERT #t_EnforcementOrders
	--(
	--    Конец_месяца,
	--    Уникальные_клиенты,
	--    Сумма_по_ИЛ
	--)
	INSERT #t_Collection_agent_credits
	(
	    Конец_месяца,
	    Уникальные_клиенты,
	    Коллекторское_агенство
	)
	SELECT 
		A.Конец_месяца,
		Уникальные_клиенты = count(DISTINCT A.[Уникальные клиенты]),
	    A.Коллекторское_агенство
	FROM (
		SELECT --TOP 100 
			[Конец_месяца] = Deals.Дата, -- '2023-09-30',
			[Уникальные клиенты] = Deals.ClientIdFull,
			--[Сумма по ИЛ] = eo.Amount
			Коллекторское_агенство = iif(
					isnull(ka.agent_name, 'CarMoney') = 'ACB',
					'CarMoney', 
					isnull(ka.agent_name, 'CarMoney')
				)
		FROM Stg._Collection.EnforcementOrders as eo -- исполнительный лист
			--INNER JOIN #loans AS Deals

			--INNER JOIN #loans_calend_eomonth AS Deals
			--	ON Deals.idEnforcementOrders = eo.id

			INNER JOIN (
				SELECT 
					Дата = C.DT,
					L.*
				--INTO #loans_calend_eomonth
				FROM #calend_eomonth AS C
					INNER JOIN #loans AS L
						ON 1=1
				) AS Deals
				ON Deals.idEnforcementOrders = eo.id

			left join (
				SELECT 
					CustomerId,
					bancruptcy_date = 
						max(
							CASE 
								WHEN DateResultOfCourtsDecisionBankrupt is not null then DateResultOfCourtsDecisionBankrupt 
								ELSE  
									CASE
										WHEN CourtDecisionDate is not null then CourtDecisionDate
										ELSE
											CASE 
												WHEN CreateDate is not null then CreateDate
												ELSE UpdateDate
											END
									END
							END
						)
					from  Stg._Collection.CustomerStatus 
					where CustomerStateId in (16)
					group by CustomerId
				) AS Bankrupt
				ON Bankrupt.CustomerId = Deals.ClientIdFull
			LEFT JOIN (
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
			LEFT JOIN (
				select
					agent_name = a.AgentName
					,reestr = RegistryNumber
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
				) as ka
				ON ka.external_id = Deals.Number 
				AND Deals.Дата BETWEEN ka.st_date AND ka.end_date
		WHERE 1=1
			--AND isSumEnforcementOrder NOT IN (0)
			--AND iif(УчетнаяДата IS NOT NULL, iif([Сумма по ИЛ] IS NULL, 0, 1), NULL) NOT IN (0, 100)
			AND iif(eo.Amount IS NULL, 0, 1) NOT IN (0)
			--AND isActive NOT IN (0, 100)
			AND iif(
					cast(coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date,ep.ExcitationDate) as date) is null, 
					100, 
					iif(cast(coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date,ep.ExcitationDate) as date) <= Deals.Дата --'2023-09-30'
					,1,0
				)
			) NOT IN (0, 100)
			--AND isBankruptFromDate NOT IN (1)
			AND iif(Bankrupt.bancruptcy_date is null,
					0,
					iif(Bankrupt.bancruptcy_date <= Deals.Дата, 1,0)
				) NOT IN (1)
			--AND ПогашенНаДату NOT IN (1)
			AND iif(Deals.ДатаПогашения is null, 
					0,
					iif(cast(Deals.ДатаПогашения as date) <= Deals.Дата, 1,0)
				) NOT IN (1)
			--AND [Статья46] NOT IN (1)
			AND iif(charindex('46', isnull(ep.CommentExcitationEnforcementProceeding,'')) > 0, 1, 0) NOT IN (1)
		) AS A
	GROUP BY A.Конец_месяца, A.Коллекторское_агенство


	SELECT 
		T.Конец_месяца,
		T.Коллекторское_агенство,
		T.Уникальные_клиенты
	FROM #t_Collection_agent_credits AS T
	ORDER BY T.Конец_месяца, T.Коллекторское_агенство

END try
begin catch
	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end
