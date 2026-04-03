-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-07-31
-- Description:	
--             exec [dbo].[ReportDashboard_Collection_EnforcementProceeding_Period2]   '2020-12-29'
-- =============================================
CREATE PROC dbo.ReportDashboard_Collection_EnforcementProceeding_Period2
	-- Add the parameters for the stored procedure here
	@DateReport date = NULL,
--	@DateReport2 int = datediff(day,0,getdate()),
--	@PageNo int 
	@isDebug int = 0,
	@TestRows int = 0
	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--Declare  @DateReport date = cast(dateAdd(day,0,GetDate()) as date)
	Set datefirst 1

	SELECT @isDebug = isnull(@isDebug, 0)
	SELECT @TestRows = isnull(@TestRows, 0)

    DECLARE @StartDate datetime, @row_count int

	-- получим текущий месяц
	declare  @DateCalculate date = cast(dateadd(month,0, dateadd(year,0,getdate())) as date)
	--declare  @dt_begin_of_month date = cast(format(cast(dateadd(month,-7, dateadd(year,0,@DateCalculate)) as date),'yyyyMM01') as date)
	declare  @dt_begin_of_month date = cast(format(cast('2020-03-01' as date),'yyyyMM01') as date)
	declare  @dt_next_month date = @DateCalculate-- cast(dateadd(month,1, @dt_begin_of_month) as date)
	--select @DateCalculate

--test
--SELECT @dt_begin_of_month = @DateCalculate


drop table if exists #bankropt_state_conf;
with
bankropt_state_conf as
(
select distinct c.id
         from stg._Collection.CustomerStatus cs
         join  stg._Collection.Customers c on cs.CustomerId=c.id
                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
                 where st.name  in ('Банкрот подтверждённый') 
				 and IsActive = 1
)

select * into #bankropt_state_conf from bankropt_state_conf


drop table if exists #ka_state;
;with
ka_state as
(
select distinct c.id --*
         from stg._Collection.CustomerStatus cs
         join  stg._Collection.Customers c on cs.CustomerId=c.id
                 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
                 where st.name  in ('КА') 
				 and IsActive = 1
)
select * into #ka_state from ka_state




	-- получим список дат
	if object_id('tempdb.dbo.#calend') is not null drop table #calend

	select DT
	into  #calend
	FROM [dwh2].[Dictionary].[calendar]
	where dt>=@dt_begin_of_month and dt<=@dt_next_month


	-- найдем дату погашения (чтобы понять, что закрыт)
	 if object_id('tempdb.dbo.#endedContracts') is not null drop table #endedContracts
	   
	  select d.Код
		   , Период=dateadd(year,-2000,max(sd.Период))				
		into  #endedContracts
		from stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
		join stg._1ccmr.Справочник_Договоры d on d.Ссылка=sd.договор
		join stg._1ccmr.Справочник_СтатусыДоговоров  ssd on ssd.Ссылка=sd.Статус
	   where ssd.Наименование='Погашен' --and d.Код in (select Number from #loans)
	   group by d.Код

	SELECT @StartDate = getdate(), @row_count = 0
		
	-- получим договора для ИП (на самом деле на СП)
	if object_id('tempdb.dbo.#loans') is not null drop table #loans
	SELECT distinct eo.Id idEnforcementOrders, jc.Id idJudicialClaims
	, l.*
	, cst_deals.Name as 'StageDealFull'
	, c.id as ClientIdFull
	, c.LastName + ' '  + c.Name + ' ' + c.MiddleName 'ClientFull' 
	, cst_client.Name as 'StageClientFull'
	, reg.Region
	,  reg.ActualRegion
	, ec.Период ДатаПогашения
	--,l.id as DealIdFull
	, dp.PledgeItemId
	, ep.id as idEnforcementProceeding
	, pledge.vin
	,rn_EnforcementOrders = ROW_NUMBER() over(partition by l.id  order by isnull(eo.Id,0) desc)
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

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #loans', @row_count, datediff(SECOND, @StartDate, getdate())

		--DROP TABLE IF EXISTS Stg.tmp.TMP_AND_loans --##loans
		--SELECT * 
		--INTO Stg.tmp.TMP_AND_loans --##loans
		--FROM #loans
	END
	   
	delete from #loans where rn_EnforcementOrders>1 and idEnforcementOrders is  null
		
-------- данные по арестам
		-- исключим дубли в мониторинге
		drop table if exists #monitor
		

	SELECT @StartDate = getdate(), @row_count = 0
		
;with monitoring as
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
			, ArestCarDate2 = max( ArestCarDate) over (partition by l.PledgeItemId)
			, rn = ROW_NUMBER() over( partition by epm.[EnforcementProceedingId] order by isnull(epm.UpdateDate, '2099-01-01') desc,epm.id desc)
			from monitoring epm 
			
			left join #loans l on l.idEnforcementProceeding = epm.EnforcementProceedingId
		)
		select * into #monitor from monitor where rn=1
		
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #monitor', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	  --select * from #loans where Number =  '18031419610001'

	  --select * from #loans where -- rn_EnforcementOrders>1 and 
	  --number =18052506950003
	  --order by rn_EnforcementOrders

	IF @TestRows <> 0 BEGIN
		DELETE A
		--SELECT A.*
		--SELECT count(*)
		FROM #loans AS A
		WHERE A.Number NOT IN (
			SELECT TOP(@TestRows) L.Number
			FROM #loans AS L
			WHERE 1=1
				AND L.Date >='2022-01-01'
			ORDER BY L.Number
		)
	END
	

	-- получим матрицу для заполенния (чтобы получить таблицу фактов)
	if object_id('tempdb.dbo.#loans_calend') is not null drop table #loans_calend

	SELECT @StartDate = getdate(), @row_count = 0

	SELECT calend.dt Дата
		  , datepart(iso_week,calend.dt) as Неделя
		  , dateadd(dd,-datepart(dw,DATEFROMPARTS(year(calend.dt),1,1))-6+datepart(iso_week,calend.dt)*7,DATEFROMPARTS(year(calend.dt),1,1)) НачалоНедели
		  , dateadd(dd,-datepart(dw,DATEFROMPARTS(year(calend.dt),1,1))+datepart(iso_week,calend.dt)*7,DATEFROMPARTS(year(calend.dt),1,1)) КонецНедели
		  , cast(format((calend.dt), 'yyyy-MM-01') as date)  НачалоМесяца
		  , eomonth(cast(format((calend.dt), 'yyyy-MM-01') as date)) КонецМесяца
		  ,l.*
	into #loans_calend
	FROM #calend calend, #loans  l

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #loans_calend', @row_count, datediff(SECOND, @StartDate, getdate())
	END


	SELECT @StartDate = getdate(), @row_count = 0

	CREATE CLUSTERED INDEX clix_Id_Дата ON #loans_calend(Id, Дата)

	IF @isDebug = 1 BEGIN
		SELECT 'CREATE INDEX ON #loans_calend', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	/*
	SELECT DISTINCT 
		R.DateFull,
		R.DateFull
	FROM dbo.dm_CollectionEnforcementProceeding_Raw2 AS R
	*/




	
	/*
	--select * from #loans_calend where Number = '1708036170001'
	-- получим все коммуникации
	drop table if exists [dbo].dm_CommunicationsMat
	select com.* 
	into [dbo].dm_CommunicationsMat
	from [Stg].[_Collection].v_Communications com
	join [Stg].[_Collection].Deals l on l.Number = com.Number
	join [Stg].[_Collection].JudicialProceeding  jp on l.Id = jp.DealId
	where  CommunicationDate>=@dt_begin_of_month and CommunicationDate<=@dt_next_month -- cast(CommunicationDate as date)>=Dateadd(day,-124,GetDAte())
	*/

	--- 2021_03_15 все последние комментарии к коммуникции по ИП ФССП



	drop table if exists #t_fssp

	SELECT @StartDate = getdate(), @row_count = 0

	select *
	into #t_fssp
	from stg._Collection.mv_Communications
	where ContactTypeId  =  81

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #t_fssp', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	drop table if exists #t_fssp2

	SELECT @StartDate = getdate(), @row_count = 0

	select *
	, rn = row_number() over (partition by idDeal order by CommunicationDateTime desc, UpdateDate desc)
	into #t_fssp2
	from #t_fssp

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #t_fssp2', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	delete from  #t_fssp2 where rn>1

	--select * from #t_fssp2



	   		-- найдем суммы платежей от судебных приставов в том числе ( на рс)
	 if object_id('tempdb.dbo.#payments') is not null drop table #payments

	 select p.external_id 
		,p.[Платежная система]
		,p.Сумма
		, dateadd(year, -2000, p.Дата) as Дата
	 into #payments
	 from  [dbo].dm_Collection_IP_Payment p
	 --join #loans l on l.Number = p.external_id


	 --дополнительно данные берем из спейс
	if object_id('tempdb.dbo.#paymentsSpace') is not null drop table #paymentsSpace

	SELECT @StartDate = getdate(), @row_count = 0

	-- считаем, что клиент отправляет только через один канал. ФССП через Р/С
	;with
	paySp as
	(
		SELECT 
			p.[IdDeal], 
			sum(p.[Amount]) 'Сумма платежа',
			ps.name 'Платежная система', 
			Payer = isnull(p.Payer, ''),
			cast(p.[PaymentDt] as date) 'Дата платежа'				
		FROM [Stg].[_Collection].[Payment] p WITH(INDEX = ix_IdDeal) --DWH-1968
			LEFT join [Stg].[_Collection].[Paymentsystem] ps on ps.id = p.PaymentSystemId
		-- where p.PaymentSystemId <> 1
		group by p.[IdDeal], cast(p.[PaymentDt] as date), ps.name, isnull(p.Payer, '')
	)
	SELECT 
		p.[Дата платежа], 
		p.IdDeal, 
		pN.[Платежная система],
		pN.[Сумма платежа],
		pFSSP.[Платежная система ФССП], 
		pFSSP.[Сумма платежа ФССП]
	into #paymentsSpace
	from (
			SELECT [Дата платежа], iddeal 
			FROM paySp 
			GROUP BY [Дата платежа], iddeal
		) AS p
		LEFT JOIN
		(
			SELECT 
				sum([Сумма платежа]) [Сумма платежа],
				IdDeal,
				[Дата платежа],
				max([Платежная система]) [Платежная система]
			FROM paySp 
			WHERE Payer <> N'ФССП'
			GROUP by IdDeal,[Дата платежа]
		) AS pN
		ON p.IdDeal = pN.IdDeal and p.[Дата платежа] = pN.[Дата платежа]
		LEFT JOIN
		(
			SELECT 
				sum([Сумма платежа]) [Сумма платежа ФССП],
				IdDeal,
				[Дата платежа],
				max([Платежная система]) [Платежная система ФССП]
			FROM paySp 
			WHERE Payer = N'ФССП'
			GROUP by IdDeal,[Дата платежа]
		) pFSSP 
		ON p.IdDeal = pFSSP.IdDeal and p.[Дата платежа] = pFSSP.[Дата платежа]

	-- OLD
	/*
		;with
		paySp as
		(
			SELECT [IdDeal], sum([Amount]) 'Сумма платежа', ps.name 'Платежная система', Payer
			, cast([PaymentDt] as date) 'Дата платежа'				
			FROM [Stg].[_Collection].[Payment] p
			left join [Stg].[_Collection].[Paymentsystem] ps on ps.id = p.PaymentSystemId
			-- where p.PaymentSystemId <> 1
			group by [IdDeal], cast([PaymentDt] as date) ,ps.name, Payer
		)

		--select * from paySp
		-- where rn >1
		--select * from
		--(
		Select  p.[Дата платежа], p.IdDeal, pN.[Платежная система],  pN.[Сумма платежа]
		, pFSSP.[Платежная система ФССП], pFSSP.[Сумма платежа ФССП]
		--,rn = ROW_NUMBER() over (partition by p.[Дата платежа], p.IdDeal order by pN.[Платежная система])
		into #paymentsSpace
		from (select [Дата платежа], iddeal from paySp group by [Дата платежа], iddeal)  p
		left join
		(select sum([Сумма платежа]) [Сумма платежа],IdDeal,[Дата платежа]
	--	,FIRST_VALUE([Платежная система]) over(order by ([Сумма платежа]) desc) [Платежная система] 
		,max([Платежная система]) [Платежная система]
		from paySp where isnull(Payer,'') <> N'ФССП' group by IdDeal,[Дата платежа])
		pN on p.IdDeal = pN.IdDeal and p.[Дата платежа] = pN.[Дата платежа]
		left join
		(select sum([Сумма платежа]) [Сумма платежа ФССП],IdDeal,[Дата платежа]
	--	,FIRST_VALUE([Платежная система]) over(order by ([Сумма платежа]) desc) [Платежная система] 
		,max([Платежная система]) [Платежная система ФССП]
		from paySp where isnull(Payer,'') = N'ФССП' group by IdDeal,[Дата платежа])
		pFSSP on p.IdDeal = pFSSP.IdDeal and p.[Дата платежа] = pFSSP.[Дата платежа]
		--) pp
		--where pp.rn>1
		--order by pp.[Дата платежа] desc
	*/
	
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #paymentsSpace', @row_count, datediff(SECOND, @StartDate, getdate())
	END


	 --select * from #payments
	 --where external_id = '18031419610001'
	-- 	-- найдем дату перехода в легал
	--if object_id('tempdb.dbo.#rs') is not null drop table #rs
	--;with m
	--		as
	--		(
	--			select max(ДатаДобавления) max_dd
	--			,      max(ДатаДобавления) max_dex
	--			,      rs.договор         
	--			from [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СтадииКоллектинга] rs
	--			where ДатаДобавления<= dateadd(year,2000,cast(getdate() as date))
	--			group by rs.договор
	--		)
	--select d.номер  external_id
	--,      sc.Имя   CollectionStage
	--,      m.max_dd
	--	into #rs
	--from      m                                                                
	--join      [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СтадииКоллектинга] rs on rs.договор=m.договор
	--		and rs.ДатаДобавления=m.max_dd
	--left join [prodsql02].[mfo].[dbo].[Перечисление_ГП_СтадииКоллектинга]    sc on sc.ссылка=rs. Стадия
	--join      [prodsql02].[mfo].[dbo].Документ_ГП_Договор                    d  on d.ссылка= rs.договор
	--join #loans l on l.Number = d.номер
	----where sc.Имя='Legal'



	-- получим общую таблицу фактов
		--if object_id('tempdb.dbo.#EnforcementProceeding_res_tmp') is not null drop table #EnforcementProceeding_res_tmp
		if object_id('tempdb.dbo.#EnforcementProceeding_res') is not null drop table #EnforcementProceeding_res

	SELECT @StartDate = getdate(), @row_count = 0

--;with monitoring1 as
--(
--select 
--		  monitoring.id
--		, bt.ArestCarDate 
--		, monitoring.EnforcementProceedingId 
--		, bt.CarStoragePlace
--		, ft.ReevaluationDate
--		, ft.FirstTradesDatePlanned 
--		, ft.FirstTradingResult 
--		, st.SecondTradesDatePlanned 
--		, st.SecondTradingResult 
--		, im.DecisionDepositToBalance 
--		, im.AdoptionBalanceDate 
--		, im.AmountDepositToBalance
--		, im.OfferAdoptionBalanceDate
--		, monitoring.StatusAfterArrestId
--		, im.ImplementationBalanceDate
--		, im.AmountImplementationBalance
--		--, im.ImplementationBalanceDate
--		, ft.FirstTradesDate
--		, ft.AmountFirstTrades
--		, st.SecondTradesDate
--		, im.SaleCarDate
--		, im.AmountSaleCar
--		, st.AmountSecondTrades
--FROM [Stg].[_Collection].[EnforcementProceedingMonitoring] monitoring 
--left join [Stg].[_Collection].EnforcementProceedingMonitoringBeforeTrades bt on bt.EnforcementProceedingMonitoringId = monitoring.Id
--left join [Stg].[_Collection].[EnforcementProceedingMonitoringFirstTrades] ft on ft.EnforcementProceedingMonitoringId = monitoring.Id
--left join [Stg].[_Collection].[EnforcementProceedingMonitoringSecondTrades] st on st.EnforcementProceedingMonitoringId = monitoring.Id
--left join [Stg].[_Collection].[EnforcementProceedingMonitoringImplementation] im on im.EnforcementProceedingMonitoringId = monitoring.Id
--)
--,
;with EnforcementProceeding as
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
		
		
from  Stg._Collection.EnforcementProceeding  ep
left join [Stg].[_Collection].[EnforcementProceedingExcitation] epe on ep.id = epe.EnforcementProceedingId
left join [Stg].[_Collection].[EnforcementProceedingSPI] eps on ep.id = eps.EnforcementProceedingId
)
--,loans_calend AS (
--	SELECT calend.dt Дата
--		  , datepart(iso_week,calend.dt) as Неделя
--		  , dateadd(dd,-datepart(dw,DATEFROMPARTS(year(calend.dt),1,1))-6+datepart(iso_week,calend.dt)*7,DATEFROMPARTS(year(calend.dt),1,1)) НачалоНедели
--		  , dateadd(dd,-datepart(dw,DATEFROMPARTS(year(calend.dt),1,1))+datepart(iso_week,calend.dt)*7,DATEFROMPARTS(year(calend.dt),1,1)) КонецНедели
--		  , cast(format((calend.dt), 'yyyy-MM-01') as date)  НачалоМесяца
--		  , eomonth(cast(format((calend.dt), 'yyyy-MM-01') as date)) КонецМесяца
--		  ,l.*
--	--into #loans_calend
--	FROM #calend calend, #loans  l
--)
		select --top 100
		--emp.Id
		--,
		deals.Дата УчетнаяДата
		, DATEPART ( ISO_WEEK , cast(deals.Дата as date)) УчетнаяНеделя
		, deals.НачалоНедели
		, deals.КонецНедели
		,iif(emp.LastName is null , 'Не назначен', emp.LastName + ' '  + emp.FirstName + ' ' + emp.MiddleName) 'Куратор'
		,c.id 'idClient'
		,Deals.Id 'idDeal'
		,eo.Id idEnforcementOrder
		 ,Deals.Number as номерДоговора
		,c.LastName + ' '  + c.Name + ' ' + c.MiddleName 'Клиент'
		,c.StatusNameList
		,eo.Accepted
		,eo.AcceptanceDate
		,isnull(eo.Number,'Не указан') 'Номер ИЛ'
		
		,fssp.name
		,ep.ExcitationDate
		,ep.CaseNumberInFSSP
		-- 2020-10-08, monitoring.EndDate -- 2020_08_20 
		, ep.EndDate
		, ep.[CommentExcitationEnforcementProceeding] as BasisEndEnforcementProceeding -- 2020_08_20 ep.BasisEndEnforcementProceeding
		,monitoring.ArestCarDate2 as ArestCarDate
		,monitoring.AdoptionBalanceDate as SaleCarDate --  чтобы не менять дизайн
		--, com.ЧислоКомментариевДоговора
		
				,com.ContactPerson
				,com.CommunicationDateTime
		,com.Commentary
		--,com.PromiseDate ДатаОбещания
		
		,kpi.ДатаОбещания ДатаОбещания
		--, kpi.СуммаОбещания
		,com.PromiseSum СуммаОбещания
		,kpi.ptpSum_if_succes_partial_ptp_new СуммаПолученная
		,idClientBankroptOrClosed = iif(StatusNameList='Банкрот подтверждённый' ,c.id, Null)
		,idClientAccepted = iif(Accepted=1 ,c.id, Null)
		,idClientAcceptedWithSum = iif(Accepted=1 and isnull(amount,0)>0 ,c.id, Null)
		,КлиентПринятИЛ_КА_или_Сумма = iif((Accepted=1 and isnull(amount,0)>0) or ka.agent_name is not null  ,c.id, Null)
		,ep.ErrorCorrectionNumberDate ДатаОтправкиЗаявления
		,idClientFSSP = iif(ep.ErrorCorrectionNumberDate is not null and fssp.name is not null, c.id, Null)
	--    ,idClientFSSP = iif(ep.FilingDate is not null and fssp.name is not null, c.id, Null) -- так как поле пустое, пишем другое
		,NumberExcitation = iif(ep.ExcitationDate is not null, Deals.Number, Null)
		,NumberNoExcitation = iif(ep.id is not null and ep.ExcitationDate is null, Deals.Number, Null)
		--,Статья46 =  iif(CHARINDEX('46',isnull(ep.BasisEndEnforcementProceeding,''))>0,1,0)
		,Статья46 =  iif(CHARINDEX('46',isnull(ep.[CommentExcitationEnforcementProceeding],''))>0,1,0)
		,idClientArestCar = iif(monitoring.ArestCarDate2 is not null , c.id, Null) 
		,idClientBalanceCar = iif(monitoring.AdoptionBalanceDate is not null , c.id, Null) 
		,idClientComment = iif(com.Commentary is not null , c.id, Null) 
		, iif(cs8.id is not null,c.id,null) isKA
		--, null isKA		
		, iif(cs16.id is not null,c.id,null) isBankrupt
		--, null isBankrupt
		
		, eo.ReceiptDate ПолученИЛДата
		, iif(isnull(eo.ReceiptDate,'2999-01-01')<=deals.Дата, Deals.Number, Null) ПолученИЛ
		, iif(isnull(eo.ReceiptDate,'2999-01-01')<=deals.Дата, Deals.Number, Null) ПолученИЛсСуммой
		, com.ЧислоКомментариевДоговора
		, NULL as NumberEnd --2020_08_20 iif(ep.EndDate=Deals.Дата,Deals.Number, Null) NumberEnd
		, NULL as NumberLoansEnd --2020_08_20 iif(ec.Период=Deals.Дата,Deals.Number, Null) NumberLoansEnd

		--, дублиИЛ = row_number() over (partition by Deals.Number, Deals.Дата order by isnull(Accepted, -1) desc,  isnull(eo.AcceptanceDate,isnull(eo.ReceiptDate,'1900-01-01')) desc)
		, дублиИЛ = row_number() over (partition by Deals.Number, Deals.Дата order by isnull(eo.Amount, -1) desc,  isnull(ep.ExcitationDate,isnull(eo.AcceptanceDate,isnull(eo.ReceiptDate,'1900-01-01'))) desc)
		, порядокИЛ = row_number() over (partition by Deals.Number, Deals.Дата order by  coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date,ep.ExcitationDate,'1900-01-01') desc,isnull(eo.Amount, -1) desc)
		, порядокПлатежаИЛ = row_number() over (partition by Deals.Number, Deals.Дата order by  isnull(eo.Amount, -1) desc,coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date,ep.ExcitationDate,'1900-01-01') desc)
		, iif(isnull(ka.agent_name, 'CarMoney') ='ACB','CarMoney', isnull(ka.agent_name, 'CarMoney')) nameКА
		, ka.agent_name nameКА_old
		, ka.external_id НомерДоговораКА
		, iif(  ka.agent_name = 'Povoljie',  ka.external_id,null) Povoljie
		, iif(  ka.agent_name = 'Alfa',  ka.external_id,null) Alfa
		, iif(  ka.agent_name = 'Prime Collection',  ka.external_id,null) 'Prime Collection'
		--, iif(  payment.[Платежная система] = 'Р/С',  payment.Сумма, null) 'Сумма на р/с'
		--, payment.Сумма 'Сумма'
		--, payment.[Платежная система]
		
		--, ec.Период ДатаПогашения
		--, ДатаПогашения ДатаПогашения
		
		, iif(Accepted=1 and isnull(isnull(eo.AcceptanceDate,ReceiptDate),'2999-01-01') <= Deals.Дата, c.id, null) RealIdClient
		, iif(Accepted=1 and isnull(isnull(eo.AcceptanceDate,ReceiptDate),'2999-01-01') <= Deals.Дата, Deals.number ,null) RealNumberLoan
		, iif((Accepted=1 and isnull(isnull(eo.AcceptanceDate,ReceiptDate),'2999-01-01') <= Deals.Дата) or ka.external_id is not null, Deals.number ,null) RealNumberLoanOrKA
		, cst.Name Стадия
		, eo.Amount 'Сумма по ИЛ'
		, eo.JudicialClaimId 'Идентификатора судебного иска'
		, eo.Date ДатаИЛ
		, датаПринятияИЛСоставная = iif(cast(coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date,ep.ExcitationDate) as date) <'2012-01-01', null, cast(coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date,ep.ExcitationDate) as date))
		,idJudicialClaims
		, isActive =iif(cast(coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date,ep.ExcitationDate) as date) is null, 100, iif(cast(coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date,ep.ExcitationDate) as date)<=Deals.Дата 
		--2020_08_20 and isnull(ep.EndDate,'2099-01-01') > Deals.Дата
		,1,0
		)
		)
		, iif(ka.external_id is null, null, iif(ka.st_date = Deals.Дата, 1, iif(ka.end_date = Deals.Дата,-1,0))) IncrementKA

		--2020_09_16 поправить дату отправки заявления в РОСП
		, ep.ErrorCorrectionNumberDate 'Дата отправления ИЛ в РОСП'
		, iif(isnull(ep.ErrorCorrectionNumberDate,'2999-01-01')<=deals.Дата, 1, 0) 'ИЛ отправлен в РОСП'
		, iif(isnull(ep.ExcitationDate,'2999-01-01')<=deals.Дата, 1, 0) 'Возбуждено ИП_old'
		, iif(isnull(ep.ExcitationDate,'2999-01-01')<=deals.Дата  -- есть возбуждение до даты

			and  isnull(ep.ExcitationDate,'2999-01-01')<isnull(ep.EndDate,'2999-01-02') -- дата возбуж до даты окончания
			, 1, 0) 'Возбуждено ИП'
		, ep.CaseNumberInFSSP AS '№ дела в ФССП'
		, ep.id 'Идентификатор ИП'
		, monitoring.AmountDepositToBalance
		, monitoring.ImplementationBalanceDate
		, monitoring.AmountImplementationBalance
		,  monitoring.AdoptionBalanceDate 
		, iif(isnull(monitoring.AdoptionBalanceDate,'2999-01-01')<=deals.Дата, 1, 0) 'Принятие на баланс'
		, iif(isnull(monitoring.ImplementationBalanceDate,'2999-01-01')<=deals.Дата, 1, 0) 'Реализация с баланса'
		, iif(isnull(monitoring.ArestCarDate,'2999-01-01')<=deals.Дата, 1, 0) 'Арест машины'
		, monitoring.FirstTradesDate 'Дата первых торгов'
		, iif(isnull(monitoring.FirstTradesDate,'2999-01-01')<=deals.Дата, 1, 0) 'Первые торги'
		, monitoring.FirstTradingResult 'Результат первых торгов'
		, monitoring.AmountFirstTrades 'Фактическая сумма первых торгов'  -- (если результат первых торгов = состоялись)
		, monitoring.SecondTradesDate 'Дата вторых торгов'
		, iif(isnull(monitoring.SecondTradesDate,'2999-01-01')<=deals.Дата, 1, 0) 'Вторые торги'
		, monitoring.SecondTradingResult 'Результат вторых торгов' 
		, monitoring.AmountSecondTrades 'Фактическая сумма вторых торгов' -- (если результат вторых торгов = состоялись)
		, CASE WHEN eo.Type = 1 THEN 'Обеспечительные меры' WHEN eo.Type = 2 THEN 'Денежное требование' WHEN eo.Type = 3 THEN 'Обращение взыскания' WHEN eo.Type = 4 THEN 'Взыскание и обращение взыскания' ELSE
                          'Не указан' END AS 'Тип ИЛ'
		--, empIP
		,iif(empIP.LastName is null , 'Не назначен', empIP.LastName + ' '  + empIP.FirstName + ' ' + empIP.MiddleName) 'КураторИП'
		, iif(isnull(monitoring.AdoptionBalanceDate,'2999-01-01')=deals.Дата, monitoring.AmountDepositToBalance, null) 'СуммаПринятНаБаланс'
		, fssp.[NameRegion]
		
		/*

		Есть арест авто - все клиенты (договор погашен/не погашен), если 1 - торги не назначены выводить значение "ожидание 1-х торгов"

		Есть арест авто + Плановая дата первых торгов = "дата", выводить значение Назначено на 1 - е торги

		Если Результат первых торгов = "состоялись", выводить значение авто реализовано с 1-х торгов - "Дата реализации авто на торгах" "Стоимость реал. авто на торгах, руб"

		Если Результат первых торгов = "не состоялись", выводить значение "ожидание 2-х торгов

		есть арест авто + Плановая дата вторых торгов = "дата", выводить значение Назначено на 2 - е торги 

		Если Результат вторых торгов = "состоялись", выводить значение авто реализовано с 2-х торгов - "Дата реализации авто на торгах" "Стоимость реал. авто на торгах, руб"

		Если авто на 2- х торгах не реализовалось, выводить значение "ожидание предложения на баланс"

		*/
		, StatusTrade =
		case 
		when (ArestCarDate2 is not null) 
				and (ДатаПогашения  is not null)
				then 'Закрыто'
		when (ArestCarDate2 is not null)	
				and (isnull([DecisionDepositToBalance],-1) = 1)	
				and (AdoptionBalanceDate is not null)  
				then 'Принято на баланс'
		when (ArestCarDate2 is not null)	
				and (isnull([DecisionDepositToBalance],-1) = 0)	
				and (AdoptionBalanceDate is null)  
				then 'Не принято на баланс'
		when (ArestCarDate2 is not null) 		 
				--and (FirstTradesDate is not null)
				--and (SecondTradesDate is not null) 
				--and (SecondTradingResult=1)  
				--and( (AdoptionBalanceDate is null)  or (isnull([DecisionDepositToBalance],-1) = 0)	)
				and ([DecisionDepositToBalance] is null)
				and ((OfferAdoptionBalanceDate is not null) or 
				(isnull(SecondTradingResult,-1)=1)
				)
				then 'Ожидание предложения на баланс'
		when (ArestCarDate2 is not null) 		 
				and (FirstTradesDate is not null)
				and (SecondTradesDate is not null) 
				and (isnull(SecondTradingResult,-1)=0)  
				then 'Авто реализовано с 2-х торгов'
		when (ArestCarDate2 is not null) 
				and (FirstTradesDate is not null)
				and (SecondTradesDate is not null)
				and (SecondTradingResult is null)  
				then 'Назначено на 2 - е торги'
		when (ArestCarDate2 is not null) 
				and (FirstTradesDate is not null)
				and (SecondTradesDate is null) 
				and (isnull(FirstTradingResult,-1)=1)  
				then 'Ожидание 2-х торгов'
		when (ArestCarDate2 is not null) 
				and (FirstTradesDate is not null)
				and (SecondTradesDate is null) 
				and (isnull(FirstTradingResult,-1)=0)  
				then 'Авто реализовано с 1-х торгов'
		when (ArestCarDate2 is not null) 
				and (FirstTradesDate is not null)
				and (SecondTradesDate is null) 
				and (FirstTradingResult is null)  
				then 'Назначено на 1 - е торги'
		when (ArestCarDate2 is not null) 
				and (FirstTradesDate is null)
				and (SecondTradesDate is null) 
				then 'Ожидание 1-х торгов'
		else 'Не определен'
		end
		, DateTrade =
		case 
		when (ArestCarDate2 is not null) 
				and (FirstTradesDate is null)
				and (SecondTradesDate is null) 
				then null
		when (ArestCarDate2 is not null) 
				and (FirstTradesDate is not null)
				and (SecondTradesDate is null) 
				and (FirstTradingResult is null)  
				then null
		when (ArestCarDate2 is not null) 
				and (FirstTradesDate is not null)
				and (SecondTradesDate is null) 
				and (FirstTradingResult=0)  
				then SaleCarDate
		when (ArestCarDate2 is not null) 
				and (FirstTradesDate is not null)
				and (SecondTradesDate is null) 
				and (FirstTradingResult=1)  
				then null
		when (ArestCarDate2 is not null) 
				and (SecondTradesDate is not null)
				and (SecondTradingResult is null)  
				then null
		when (ArestCarDate2 is not null) 
				and (SecondTradesDate is not null) 
				and (SecondTradingResult=0)  
				then SaleCarDate
		when (ArestCarDate2 is not null) 
				and (SecondTradesDate is not null) 
				and (SecondTradingResult=1)  
				then null
		else null
		end
		, AmountTrade =
		case 
		when (ArestCarDate2 is not null) 
				and (FirstTradesDate is null)
				and (SecondTradesDate is null) 
				then null
		when (ArestCarDate2 is not null) 
				and (FirstTradesDate is not null)
				and (SecondTradesDate is null) 
				and (FirstTradingResult is null)  
				then null
		when (ArestCarDate2 is not null) 
				and (FirstTradesDate is not null)
				and (SecondTradesDate is null) 
				and (FirstTradingResult=0)  
				then AmountSaleCar --стоимость
		when (ArestCarDate2 is not null) 
				and (FirstTradesDate is not null)
				and (SecondTradesDate is null) 
				and (FirstTradingResult=1)  
				then null
		when (ArestCarDate2 is not null) 
				and (SecondTradesDate is not null)
				and (SecondTradingResult is null)  
				then null
		when (ArestCarDate2 is not null) 
				and (SecondTradesDate is not null) 
				and (SecondTradingResult=0)  
				then AmountSaleCar -- стоимость
		when (ArestCarDate2 is not null) 
				and (SecondTradesDate is not null) 
				and (SecondTradingResult=1)  
				then null
		else null
		end
		/*
		   iif( ArestDate is not null
				 -- если нет даты торгов
				, iif (FirstTradesDatePlanned is not null
						, ''
						, ''
						)
				,'Не определен')
				*/
		, monitoring.ArestCarDate2 ArestDate1
		, monitoring.FirstTradesDatePlanned f_DatePlan
		, monitoring.FirstTradesDate f_DateTrade
		, monitoring.FirstTradingResult f_ResultTrade
		, monitoring.AmountFirstTrades f_AmountTrade
		, monitoring.SecondTradesDatePlanned s_DatePlan
		, monitoring.SecondTradesDate s_DateTrade
		, monitoring.SecondTradingResult s_ResultTrade
		, monitoring.AmountSecondTrades s_AmountTrade
		, monitoring.AmountSaleCar r_AmountTrade
		, monitoring.SaleCarDate _r_DateTrade
		, saa.Name as StatusAfterArest
		--,*
		, deals.PledgeItemId
		, deals.Vin


		

--,* 
into #EnforcementProceeding_res --_tmp
from  [Stg].[_Collection].[EnforcementOrders]  eo  -- исполнительный лист
left join EnforcementProceeding ep on eo.id=ep.EnforcementOrderId  -- исполнительное производство
--left join [Stg].[_Collection].JudicialClaims On JudicialClaims.id = eo.JudicialClaimId --  судебный иск
--  left join [Stg].[_Collection].JudicialProceeding on JudicialProceeding.Id = JudicialClaims.JudicialProceedingId -- субедное производство

  left join #loans_calend Deals on Deals.idEnforcementOrders = eo.id
  --LEFT JOIN loans_calend as Deals on Deals.idEnforcementOrders = eo.id


  left join [Stg].[_Collection].customers c on c.id=deals.IdCustomer
  left join  [Stg].[_Collection].[CollectingStage] cst  on  c.[IdCollectingStage] = cst.id
  --left join (select top 1 * from [Stg].[_Collection].[CustomerStatus] where [CustomerStateId]=8) cs8 on cs8.CustomerId=c.id
  left join #ka_state cs8 on cs8.id=c.id
  --left join (select top 1 * from [Stg].[_Collection].[CustomerStatus] where [CustomerStateId]=16) cs16 on cs16.CustomerId=c.id
  left join #bankropt_state_conf  cs16 on cs16.id=c.id
  left join stg._Collection.Employee emp on c.ClaimantId = emp.Id
  left join stg.[_Collection].Employee empIP  on c.[ClaimantExecutiveProceedingId]  = empIP.id
  left join [Stg].[_Collection].[DepartamentFSSP] fssp on ep.DepartamentFSSPId = fssp.Id
  --DWH-257
  left join  (
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
	on ka.external_id = deals.Number 
	and Deals.Дата between ka.st_date and ka.end_date
  left join #monitor monitoring on ep.id = monitoring.[EnforcementProceedingId]
  left join [Stg].[_Collection].StatusAfterArrest saa on  saa.id = monitoring.StatusAfterArrestId
  /*
  left join 
  (

  SELECT [EnforcementProceedingId], FIRST_VALUE(ArestCarDate) over(partition by [EnforcementProceedingId] order by ArestCarDate desc) as ArestCarDate , FIRST_VALUE(AdoptionBalanceDate) over(partition by [EnforcementProceedingId] order by AdoptionBalanceDate desc) as AdoptionBalanceDate,
    FIRST_VALUE(EndDate) over(partition by [EnforcementProceedingId] order by EndDate desc) as EndDate
	, FIRST_VALUE(ImplementationBalanceDate) over(partition by [EnforcementProceedingId] order by ImplementationBalanceDate desc) as ImplementationBalanceDate
	, FIRST_VALUE(AmountDepositToBalance) over(partition by [EnforcementProceedingId] order by AmountDepositToBalance desc) as AmountDepositToBalance
	, FIRST_VALUE(AmountImplementationBalance) over(partition by [EnforcementProceedingId] order by AmountImplementationBalance desc) as AmountImplementationBalance
  from [Stg].[_Collection].[EnforcementProceedingMonitoring]) monitoring on ep.id = monitoring.[EnforcementProceedingId] -- вытащим только два показателя по мониторингу 
  */
 left join (
		--DWH-1968. странный код - какой смысл в "TOP 10" ?
		--таблица dbo.dm_CommunicationsMat содержит неактуальные данные
		/*
		--Declare  @DateReport date = cast(dateAdd(day,-2,GetDate()) as date)
		select TOP 10 
			count(id_1) ЧислоКомментариевДоговора, 
			Number , 
			sum(PromiseSum) PromiseSum,
			min(CommunicationDateTime) CommunicationDateTime,
			min(Commentary) Commentary,
			min(ContactPerson) ContactPerson,
			CommunicationDate
		from [dbo].dm_CommunicationsMat
			--where cast(CommunicationDate as date)<=Dateadd(day,0,@DateReport) and cast(CommunicationDate as date)>Dateadd(day,-1,@DateReport)
		group by Number, CommunicationDate
		*/
		select 
			cast(NULL AS int) AS ЧислоКомментариевДоговора, 
			cast(NULL AS nvarchar(255)) AS Number, 
			cast(NULL AS numeric(18, 2)) AS PromiseSum,
			cast(NULL AS datetime2(7)) CommunicationDateTime,
			cast(NULL AS nvarchar(255)) AS Commentary,
			cast(NULL AS nvarchar(255)) AS ContactPerson,
			cast(NULL AS date) AS CommunicationDate
		) AS com --заменить на дату расчета
		on com.number = Deals.Number and com.CommunicationDate = Deals.Дата
  left join (
			--Declare  @DateReport date = cast(dateAdd(day,-2,GetDate()) as date)
			select --TOP 10 
				kpi.НомерДоговора,
				sum(kpi.ptpSum_if_succes_partial_ptp_new) as ptpSum_if_succes_partial_ptp_new, 
				(kpi.ДатаОбещания) as ДатаОбещания --, Sum(СуммаОбещания) as СуммаОбещания
			from  dbo.dm_CollectionKPIByMonth AS kpi 
			WHERE (success_PTP_new = 1 or succes_partial_ptp_new =1) 
			group by kpi.НомерДоговора, kpi.ДатаОбещания
		) kpi
		on kpi.НомерДоговора = Deals.Number and Deals.Дата = kpi.ДатаОбещания

  --left join (select CustomerId,
		--			bancruptcy_date = max(case when DateResultOfCourtsDecisionBankrupt is not null then DateResultOfCourtsDecisionBankrupt 
		--				else  
		--					case when CourtDecisionDate is not null then CourtDecisionDate
		--						else 
		--							case when CreateDate is not null then CreateDate
		--							else UpdateDate
		--						end
		--						end
		--				end)
		--	from  Stg._Collection.[CustomerStatus] 
		--	where [CustomerStateId] in (16) --15
		--	--and  (DateResultOfCourtsDecisionBankrupt is not null 
		--	----or CourtDecisionDate is not null
		--	--) --and CustomerId=13942
		--	group by CustomerId
		--) Bankrupt  on Bankrupt.CustomerId=c.id
   --left join #endedContracts ec on ec.Код = Deals.Number

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #EnforcementProceeding_res', @row_count, datediff(SECOND, @StartDate, getdate())
	END




		--where Deals.Number = '18031419610001'
		--and deals.Дата = '2020-07-15'
		--and eo.id = 676
		/*
			if object_id('tempdb.dbo.#EnforcementProceeding_res') is not null drop table #EnforcementProceeding_res

			select re_tmp.*
					--, iif(  payment.[Платежная система] = 'Р/С',  payment.Сумма, null) 'Сумма на р/с'
					--, payment.Сумма 'Сумма'
					--, payment.[Платежная система]
					--, paymentsSpace.[Платежная система] as [Платежная система Спейс]
					--, paymentsSpace.[Платежная система ФССП] as [Платежная система ФССП Спейс]
					--, paymentsSpace.[Сумма платежа] as [Сумма платежа Спейс]
					--, paymentsSpace.[Сумма платежа ФССП] as [Сумма платежа ФССП Спейс]
			into #EnforcementProceeding_res 
			from  #EnforcementProceeding_res_tmp re_tmp			
			 --left join #payments payment
				--on payment.external_id = re_tmp.номерДоговора and payment.Дата = re_tmp.УчетнаяДата and re_tmp.порядокПлатежаИЛ=1
			 --left join #paymentsSpace paymentsSpace
			 --   on paymentsSpace.IdDeal = re_tmp.idDeal and paymentsSpace.[Дата платежа] = re_tmp.УчетнаяДата  and re_tmp.порядокПлатежаИЛ=1
		 */

 --   select *from  #EnforcementProceeding_res re where re.номерДоговора = '18031419610001' and re.УчетнаяДата ='2020-07-15'	
	--order by УчетнаяДата
	--select *from  #EnforcementProceeding_res re where re.номерДоговора = '18052506950003' and re.УчетнаяДата ='2020-07-02'	
	--order by УчетнаяДата

	--select *from  #EnforcementProceeding_res re where re.idEnforcementOrder = '1513' and re.УчетнаяДата ='2020-07-15'

--	select *
--		from  [Stg].[_Collection].[EnforcementOrders]  eo 
--		left join [Stg].[_Collection].EnforcementProceeding ep on eo.id=ep.EnforcementOrderId  -- исполнительное производство
--left join [Stg].[_Collection].JudicialClaims On JudicialClaims.id = eo.JudicialClaimId --  судебный иск
--  left join [Stg].[_Collection].JudicialProceeding on JudicialProceeding.Id = JudicialClaims.JudicialProceedingId -- субедное производство
--		where eo.id=2039

	
  --select*from  #EnforcementProceeding_res
  --select*from #loans_calend Deals where Deals.Number = '1708036170001'	
		--and deals.Дата = '2020-07-01'

  --drop table if exists dbo.dm_CollectionEnforcementProceeding_Raw23


  --var.1
  /*
  --DWH-1764 
  TRUNCATE TABLE dbo.dm_CollectionEnforcementProceeding_Raw23

  --delete from dbo.dm_CollectionEnforcementProceeding_Raw2 where DateFull>=@dt_begin_of_month
  --insert into dbo.dm_CollectionEnforcementProceeding_Raw2

	SELECT @StartDate = getdate(), @row_count = 0

  INSERT dbo.dm_CollectionEnforcementProceeding_Raw23
  (
      DateFull,
      ClientIdFull,
      ClientFull,
      StageClientFull,
      Number,
      StageDealFull,
      Region,
      ActualRegion,
      ДатаПогашения,
      УчетнаяДата,
      УчетнаяНеделя,
      НачалоНедели,
      КонецНедели,
      Куратор,
      idClient,
      idDeal,
      idEnforcementOrder,
      номерДоговора,
      Клиент,
      StatusNameList,
      Accepted,
      AcceptanceDate,
      [Номер ИЛ],
      name,
      ExcitationDate,
      CaseNumberInFSSP,
      EndDate,
      BasisEndEnforcementProceeding,
      ArestCarDate,
      SaleCarDate,
      ContactPerson,
      CommunicationDateTime,
      Commentary,
      ДатаОбещания,
      СуммаОбещания,
      СуммаПолученная,
      idClientBankroptOrClosed,
      idClientAccepted,
      idClientAcceptedWithSum,
      КлиентПринятИЛ_КА_или_Сумма,
      ДатаОтправкиЗаявления,
      idClientFSSP,
      NumberExcitation,
      NumberNoExcitation,
      Статья46,
      idClientArestCar,
      idClientBalanceCar,
      idClientComment,
      isKA,
      isBankrupt,
      ПолученИЛДата,
      ПолученИЛ,
      ПолученИЛсСуммой,
      ЧислоКомментариевДоговора,
      NumberEnd,
      NumberLoansEnd,
      дублиИЛ,
      порядокИЛ,
      порядокПлатежаИЛ,
      nameКА,
      nameКА_old,
      НомерДоговораКА,
      Povoljie,
      Alfa,
      [Prime Collection],
      RealIdClient,
      RealNumberLoan,
      RealNumberLoanOrKA,
      Стадия,
      [Сумма по ИЛ],
      [Идентификатора судебного иска],
      ДатаИЛ,
      датаПринятияИЛСоставная,
      idJudicialClaims,
      isActive,
      IncrementKA,
      [Дата отправления ИЛ в РОСП],
      [ИЛ отправлен в РОСП],
      [Возбуждено ИП_old],
      [Возбуждено ИП],
      [№ дела в ФССП],
      [Идентификатор ИП],
      AmountDepositToBalance,
      ImplementationBalanceDate,
      AmountImplementationBalance,
      AdoptionBalanceDate,
      [Принятие на баланс],
      [Реализация с баланса],
      [Арест машины],
      [Дата первых торгов],
      [Первые торги],
      [Результат первых торгов],
      [Фактическая сумма первых торгов],
      [Дата вторых торгов],
      [Вторые торги],
      [Результат вторых торгов],
      [Фактическая сумма вторых торгов],
      [Тип ИЛ],
      КураторИП,
      СуммаПринятНаБаланс,
      NameRegion,
      StatusTrade,
      DateTrade,
      AmountTrade,
      ArestDate1,
      f_DatePlan,
      f_DateTrade,
      f_ResultTrade,
      f_AmountTrade,
      s_DatePlan,
      s_DateTrade,
      s_ResultTrade,
      s_AmountTrade,
      r_AmountTrade,
      _r_DateTrade,
      StatusAfterArest,
      PledgeItemId,
      Vin,
      bancruptcy_date,
      ПогашенНаДату,
      ПогашенНаДатуOld,
      isBankruptFromDate,
      isBankruptFromDateOld,
      [Сумма на р/с],
      Сумма,
      [Платежная система],
      [Платежная система Спейс],
      [Платежная система ФССП Спейс],
      [Сумма платежа Спейс],
      [Сумма платежа ФССП Спейс],
      КомментарийФССП,
      ДатаПоследнейКоммуникацииФССП,
      НомерКоммуникации
  )
  Select Deals.Дата DateFull,Deals.ClientIdFull, deals.ClientFull, deals.StageClientFull, deals.Number,deals.StageDealFull --,*
  , deals.Region
  , deals.ActualRegion
  , deals.ДатаПогашения
  , res.УчетнаяДата,
    res.УчетнаяНеделя,
    res.НачалоНедели,
    res.КонецНедели,
    res.Куратор,
    res.idClient,
    res.idDeal,
    res.idEnforcementOrder,
    res.номерДоговора,
    res.Клиент,
    res.StatusNameList,
    res.Accepted,
    res.AcceptanceDate,
    res.[Номер ИЛ],
    res.Name,
    res.ExcitationDate,
    res.CaseNumberInFSSP,
    res.EndDate,
    res.BasisEndEnforcementProceeding,
    res.ArestCarDate,
    res.SaleCarDate,
    res.ContactPerson,
    res.CommunicationDateTime,
    res.Commentary,
    res.ДатаОбещания,
    res.СуммаОбещания,
    res.СуммаПолученная,
    res.idClientBankroptOrClosed,
    res.idClientAccepted,
    res.idClientAcceptedWithSum,
    res.КлиентПринятИЛ_КА_или_Сумма,
    res.ДатаОтправкиЗаявления,
    res.idClientFSSP,
    res.NumberExcitation,
    res.NumberNoExcitation,
    res.Статья46,
    res.idClientArestCar,
    res.idClientBalanceCar,
    res.idClientComment,
    res.isKA,
    res.isBankrupt,
    res.ПолученИЛДата,
    res.ПолученИЛ,
    res.ПолученИЛсСуммой,
    res.ЧислоКомментариевДоговора,
    res.NumberEnd,
    res.NumberLoansEnd,
    res.дублиИЛ,
    res.порядокИЛ,
    res.порядокПлатежаИЛ,
    res.nameКА,
    res.nameКА_old,
    res.НомерДоговораКА,
    res.Povoljie,
    res.Alfa,
    res.[Prime Collection],
    res.RealIdClient,
    res.RealNumberLoan,
    res.RealNumberLoanOrKA,
    res.Стадия,
    res.[Сумма по ИЛ],
    res.[Идентификатора судебного иска],
    res.ДатаИЛ,
    res.датаПринятияИЛСоставная,
    res.idJudicialClaims,
    res.isActive,
    res.IncrementKA,
    res.[Дата отправления ИЛ в РОСП],
    res.[ИЛ отправлен в РОСП],
    res.[Возбуждено ИП_old],
    res.[Возбуждено ИП],
    res.[№ дела в ФССП],
    res.[Идентификатор ИП],
    res.AmountDepositToBalance,
    res.ImplementationBalanceDate,
    res.AmountImplementationBalance,
    res.AdoptionBalanceDate,
    res.[Принятие на баланс],
    res.[Реализация с баланса],
    res.[Арест машины],
    res.[Дата первых торгов],
    res.[Первые торги],
    res.[Результат первых торгов],
    res.[Фактическая сумма первых торгов],
    res.[Дата вторых торгов],
    res.[Вторые торги],
    res.[Результат вторых торгов],
    res.[Фактическая сумма вторых торгов],
    res.[Тип ИЛ],
    res.КураторИП,
    res.СуммаПринятНаБаланс,
    res.NameRegion,
    res.StatusTrade,
    res.DateTrade,
    res.AmountTrade,
    res.ArestDate1,
    res.f_DatePlan,
    res.f_DateTrade,
    res.f_ResultTrade,
    res.f_AmountTrade,
    res.s_DatePlan,
    res.s_DateTrade,
    res.s_ResultTrade,
    res.s_AmountTrade,
    res.r_AmountTrade,
    res._r_DateTrade,
    res.StatusAfterArest,
    res.PledgeItemId,
    res.Vin 
  , Bankrupt.bancruptcy_date
  , iif( ДатаПогашения is null, 0,iif(cast(ДатаПогашения as date) <= Deals.Дата, 1,0)) ПогашенНаДату
  , iif( ДатаПогашения is null, 0,iif(ДатаПогашения <= Deals.Дата, 1,0)) ПогашенНаДатуOld
  , iif( Bankrupt.bancruptcy_date is null, 0,iif(Bankrupt.bancruptcy_date <= Deals.Дата, 1,0)) isBankruptFromDate
  , iif( Bankrupt.bancruptcy_date is null, null,iif(Bankrupt.bancruptcy_date <= Deals.Дата, Deals.ClientIdFull,null)) isBankruptFromDateOld
  				, iif(  payment.[Платежная система] = 'Р/С',  payment.Сумма, null) 'Сумма на р/с'
					, payment.Сумма 'Сумма'
					, payment.[Платежная система]
					, paymentsSpace.[Платежная система] as [Платежная система Спейс]
					, paymentsSpace.[Платежная система ФССП] as [Платежная система ФССП Спейс]
					, paymentsSpace.[Сумма платежа] as [Сумма платежа Спейс]
					, paymentsSpace.[Сумма платежа ФССП] as [Сумма платежа ФССП Спейс]
, com_fssp.Commentary КомментарийФССП
, com_fssp.CommunicationDateTime ДатаПоследнейКоммуникацииФССП
, com_fssp.id_1 НомерКоммуникации
  --into dbo.dm_CollectionEnforcementProceeding_Raw23

  --from #loans_calend Deals 

  FROM (
	SELECT calend.dt Дата
		  , datepart(iso_week,calend.dt) as Неделя
		  , dateadd(dd,-datepart(dw,DATEFROMPARTS(year(calend.dt),1,1))-6+datepart(iso_week,calend.dt)*7,DATEFROMPARTS(year(calend.dt),1,1)) НачалоНедели
		  , dateadd(dd,-datepart(dw,DATEFROMPARTS(year(calend.dt),1,1))+datepart(iso_week,calend.dt)*7,DATEFROMPARTS(year(calend.dt),1,1)) КонецНедели
		  , cast(format((calend.dt), 'yyyy-MM-01') as date)  НачалоМесяца
		  , eomonth(cast(format((calend.dt), 'yyyy-MM-01') as date)) КонецМесяца
		  ,l.*
	--into #loans_calend
	FROM #calend calend, #loans  l
  ) AS Deals

  left join
  --select * from 
  #EnforcementProceeding_res res
  on Deals.id = res.idDeal
  and deals.дАТА = res.УчетнаяДата
  and deals.idEnforcementOrders = res.idEnforcementOrder
  --where Number = '1708036170001'
    left join (select CustomerId,
					bancruptcy_date = max(case when DateResultOfCourtsDecisionBankrupt is not null then DateResultOfCourtsDecisionBankrupt 
						else  
							case when CourtDecisionDate is not null then CourtDecisionDate
								else 
									case when CreateDate is not null then CreateDate
									else UpdateDate
								end
								end
						end)
			from  Stg._Collection.[CustomerStatus] 
			where [CustomerStateId] in (16) --15
			--and  (DateResultOfCourtsDecisionBankrupt is not null 
			----or CourtDecisionDate is not null
			--) --and CustomerId=13942
			group by CustomerId
		) Bankrupt  on Bankrupt.CustomerId=Deals.ClientIdFull
	left join #payments payment
	on payment.external_id = Deals.Number and payment.Дата = Deals.Дата and (res.порядокПлатежаИЛ=1 or res.порядокПлатежаИЛ is null) 
	left join #paymentsSpace paymentsSpace
	on paymentsSpace.IdDeal = Deals.id and paymentsSpace.[Дата платежа] = Deals.Дата  and (res.порядокПлатежаИЛ=1 or res.порядокПлатежаИЛ is null) 
	left join #t_fssp2 com_fssp on com_fssp.IdDeal = Deals.Id

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT dbo.dm_CollectionEnforcementProceeding_Raw23', @row_count, datediff(SECOND, @StartDate, getdate())
	END
	*/

	--drop table if exists dbo.dm_CollectionEnforcementProceeding_Raw2

	--DWH-1764 
	TRUNCATE TABLE dbo.dm_CollectionEnforcementProceeding_Raw2

	SELECT @StartDate = getdate(), @row_count = 0

	/*
	--var.1
	INSERT dbo.dm_CollectionEnforcementProceeding_Raw2
	(
	    DateFull,
	    ClientIdFull,
	    ClientFull,
	    StageClientFull,
	    Number,
	    StageDealFull,
	    Region,
	    ActualRegion,
	    ДатаПогашения,
	    УчетнаяДата,
	    УчетнаяНеделя,
	    НачалоНедели,
	    КонецНедели,
	    Куратор,
	    idClient,
	    idDeal,
	    idEnforcementOrder,
	    номерДоговора,
	    Клиент,
	    StatusNameList,
	    Accepted,
	    AcceptanceDate,
	    [Номер ИЛ],
	    name,
	    ExcitationDate,
	    CaseNumberInFSSP,
	    EndDate,
	    BasisEndEnforcementProceeding,
	    ArestCarDate,
	    SaleCarDate,
	    ContactPerson,
	    CommunicationDateTime,
	    Commentary,
	    ДатаОбещания,
	    СуммаОбещания,
	    СуммаПолученная,
	    idClientBankroptOrClosed,
	    idClientAccepted,
	    idClientAcceptedWithSum,
	    КлиентПринятИЛ_КА_или_Сумма,
	    ДатаОтправкиЗаявления,
	    idClientFSSP,
	    NumberExcitation,
	    NumberNoExcitation,
	    Статья46,
	    idClientArestCar,
	    idClientBalanceCar,
	    idClientComment,
	    isKA,
	    isBankrupt,
	    ПолученИЛДата,
	    ПолученИЛ,
	    ПолученИЛсСуммой,
	    ЧислоКомментариевДоговора,
	    NumberEnd,
	    NumberLoansEnd,
	    дублиИЛ,
	    порядокИЛ,
	    порядокПлатежаИЛ,
	    nameКА,
	    nameКА_old,
	    НомерДоговораКА,
	    Povoljie,
	    Alfa,
	    [Prime Collection],
	    RealIdClient,
	    RealNumberLoan,
	    RealNumberLoanOrKA,
	    Стадия,
	    [Сумма по ИЛ],
	    [Идентификатора судебного иска],
	    ДатаИЛ,
	    датаПринятияИЛСоставная,
	    idJudicialClaims,
	    isActive,
	    IncrementKA,
	    [Дата отправления ИЛ в РОСП],
	    [ИЛ отправлен в РОСП],
	    [Возбуждено ИП_old],
	    [Возбуждено ИП],
	    [№ дела в ФССП],
	    [Идентификатор ИП],
	    AmountDepositToBalance,
	    ImplementationBalanceDate,
	    AmountImplementationBalance,
	    AdoptionBalanceDate,
	    [Принятие на баланс],
	    [Реализация с баланса],
	    [Арест машины],
	    [Дата первых торгов],
	    [Первые торги],
	    [Результат первых торгов],
	    [Фактическая сумма первых торгов],
	    [Дата вторых торгов],
	    [Вторые торги],
	    [Результат вторых торгов],
	    [Фактическая сумма вторых торгов],
	    [Тип ИЛ],
	    КураторИП,
	    СуммаПринятНаБаланс,
	    NameRegion,
	    StatusTrade,
	    DateTrade,
	    AmountTrade,
	    ArestDate1,
	    f_DatePlan,
	    f_DateTrade,
	    f_ResultTrade,
	    f_AmountTrade,
	    s_DatePlan,
	    s_DateTrade,
	    s_ResultTrade,
	    s_AmountTrade,
	    r_AmountTrade,
	    _r_DateTrade,
	    StatusAfterArest,
	    PledgeItemId,
	    Vin,
	    bancruptcy_date,
	    ПогашенНаДату,
	    ПогашенНаДатуOld,
	    isBankruptFromDate,
	    isBankruptFromDateOld,
	    [Сумма на р/с],
	    Сумма,
	    [Платежная система],
	    [Платежная система Спейс],
	    [Платежная система ФССП Спейс],
	    [Сумма платежа Спейс],
	    [Сумма платежа ФССП Спейс],
	    КомментарийФССП,
	    ДатаПоследнейКоммуникацииФССП,
	    НомерКоммуникации,
	    [Сумма платежей на р/с по договору],
	    [Сумма платежей на р/с по клиенту],
	    [Сумма платежей по договору],
	    [Сумма платежей по клиенту],
	    [Сумма платежа Спейс по договору],
	    [Сумма платежа Спейс по клиенту],
	    [Сумма платежа ФССП Спейс по договору],
	    [Сумма платежа ФССП Спейс по клиенту]
	)
	Select 
	 DateFull,
     ClientIdFull,
     ClientFull,
     StageClientFull,
     Number,
     StageDealFull,
     Region,
     ActualRegion,
     ДатаПогашения,
     УчетнаяДата,
     УчетнаяНеделя,
     НачалоНедели,
     КонецНедели,
     Куратор,
     idClient,
     idDeal,
     idEnforcementOrder,
     номерДоговора,
     Клиент,
     StatusNameList,
     Accepted,
     AcceptanceDate,
     [Номер ИЛ],
     name,
     ExcitationDate,
     CaseNumberInFSSP,
     EndDate,
     BasisEndEnforcementProceeding,
     ArestCarDate,
     SaleCarDate,
     ContactPerson,
     CommunicationDateTime,
     Commentary,
     ДатаОбещания,
     СуммаОбещания,
     СуммаПолученная,
     idClientBankroptOrClosed,
     idClientAccepted,
     idClientAcceptedWithSum,
     КлиентПринятИЛ_КА_или_Сумма,
     ДатаОтправкиЗаявления,
     idClientFSSP,
     NumberExcitation,
     NumberNoExcitation,
     Статья46,
     idClientArestCar,
     idClientBalanceCar,
     idClientComment,
     isKA,
     isBankrupt,
     ПолученИЛДата,
     ПолученИЛ,
     ПолученИЛсСуммой,
     ЧислоКомментариевДоговора,
     NumberEnd,
     NumberLoansEnd,
     дублиИЛ,
     порядокИЛ,
     порядокПлатежаИЛ,
     nameКА,
     nameКА_old,
     НомерДоговораКА,
     Povoljie,
     Alfa,
     [Prime Collection],
     RealIdClient,
     RealNumberLoan,
     RealNumberLoanOrKA,
     Стадия,
     [Сумма по ИЛ],
     [Идентификатора судебного иска],
     ДатаИЛ,
     датаПринятияИЛСоставная,
     idJudicialClaims,
     isActive,
     IncrementKA,
     [Дата отправления ИЛ в РОСП],
     [ИЛ отправлен в РОСП],
     [Возбуждено ИП_old],
     [Возбуждено ИП],
     [№ дела в ФССП],
     [Идентификатор ИП],
     AmountDepositToBalance,
     ImplementationBalanceDate,
     AmountImplementationBalance,
     AdoptionBalanceDate,
     [Принятие на баланс],
     [Реализация с баланса],
     [Арест машины],
     [Дата первых торгов],
     [Первые торги],
     [Результат первых торгов],
     [Фактическая сумма первых торгов],
     [Дата вторых торгов],
     [Вторые торги],
     [Результат вторых торгов],
     [Фактическая сумма вторых торгов],
     [Тип ИЛ],
     КураторИП,
     СуммаПринятНаБаланс,
     NameRegion,
     StatusTrade,
     DateTrade,
     AmountTrade,
     ArestDate1,
     f_DatePlan,
     f_DateTrade,
     f_ResultTrade,
     f_AmountTrade,
     s_DatePlan,
     s_DateTrade,
     s_ResultTrade,
     s_AmountTrade,
     r_AmountTrade,
     _r_DateTrade,
     StatusAfterArest,
     PledgeItemId,
     Vin,
     bancruptcy_date,
     ПогашенНаДату,
     ПогашенНаДатуOld,
     isBankruptFromDate,
     isBankruptFromDateOld,
     [Сумма на р/с],
     Сумма,
     [Платежная система],
     [Платежная система Спейс],
     [Платежная система ФССП Спейс],
     [Сумма платежа Спейс],
     [Сумма платежа ФССП Спейс],
     КомментарийФССП,
     ДатаПоследнейКоммуникацииФССП,
     НомерКоммуникации	
	,[Сумма платежей на р/с по договору] = sum([Сумма на р/с]) over(partition by Number, DateFull )
	,[Сумма платежей на р/с по клиенту]  =  Sum([Сумма на р/с]) over(partition by ClientIdFull, DateFull )
	,[Сумма платежей по договору] = sum([Сумма]) over(partition by Number, DateFull )
	,[Сумма платежей по клиенту]  =  Sum([Сумма]) over(partition by ClientIdFull, DateFull )
	,[Сумма платежа Спейс по договору] = sum([Сумма платежа Спейс]) over(partition by Number, DateFull )
	,[Сумма платежа Спейс по клиенту]  =  Sum([Сумма платежа Спейс]) over(partition by ClientIdFull, DateFull )
	,[Сумма платежа ФССП Спейс по договору] = sum([Сумма платежа ФССП Спейс]) over(partition by Number, DateFull )
	,[Сумма платежа ФССП Спейс по клиенту]  =  Sum([Сумма платежа ФССП Спейс]) over(partition by ClientIdFull, DateFull )	
	--into dbo.dm_CollectionEnforcementProceeding_Raw2
	from dbo.dm_CollectionEnforcementProceeding_Raw23
	--where Number = '18091090040001'

		--where Deals.Дата>=@dt_begin_of_month
	*/
	--//end var.2






	--var.2
	INSERT dbo.dm_CollectionEnforcementProceeding_Raw2
	(
	    DateFull,
	    ClientIdFull,
	    ClientFull,
	    StageClientFull,
	    Number,
	    StageDealFull,
	    Region,
	    ActualRegion,
	    ДатаПогашения,
	    УчетнаяДата,
	    УчетнаяНеделя,
	    НачалоНедели,
	    КонецНедели,
	    Куратор,
	    idClient,
	    idDeal,
	    idEnforcementOrder,
	    номерДоговора,
	    Клиент,
	    StatusNameList,
	    Accepted,
	    AcceptanceDate,
	    [Номер ИЛ],
	    name,
	    ExcitationDate,
	    CaseNumberInFSSP,
	    EndDate,
	    BasisEndEnforcementProceeding,
	    ArestCarDate,
	    SaleCarDate,
	    ContactPerson,
	    CommunicationDateTime,
	    Commentary,
	    ДатаОбещания,
	    СуммаОбещания,
	    СуммаПолученная,
	    idClientBankroptOrClosed,
	    idClientAccepted,
	    idClientAcceptedWithSum,
	    КлиентПринятИЛ_КА_или_Сумма,
	    ДатаОтправкиЗаявления,
	    idClientFSSP,
	    NumberExcitation,
	    NumberNoExcitation,
	    Статья46,
	    idClientArestCar,
	    idClientBalanceCar,
	    idClientComment,
	    isKA,
	    isBankrupt,
	    ПолученИЛДата,
	    ПолученИЛ,
	    ПолученИЛсСуммой,
	    ЧислоКомментариевДоговора,
	    NumberEnd,
	    NumberLoansEnd,
	    дублиИЛ,
	    порядокИЛ,
	    порядокПлатежаИЛ,
	    nameКА,
	    nameКА_old,
	    НомерДоговораКА,
	    Povoljie,
	    Alfa,
	    [Prime Collection],
	    RealIdClient,
	    RealNumberLoan,
	    RealNumberLoanOrKA,
	    Стадия,
	    [Сумма по ИЛ],
	    [Идентификатора судебного иска],
	    ДатаИЛ,
	    датаПринятияИЛСоставная,
	    idJudicialClaims,
	    isActive,
	    IncrementKA,
	    [Дата отправления ИЛ в РОСП],
	    [ИЛ отправлен в РОСП],
	    [Возбуждено ИП_old],
	    [Возбуждено ИП],
	    [№ дела в ФССП],
	    [Идентификатор ИП],
	    AmountDepositToBalance,
	    ImplementationBalanceDate,
	    AmountImplementationBalance,
	    AdoptionBalanceDate,
	    [Принятие на баланс],
	    [Реализация с баланса],
	    [Арест машины],
	    [Дата первых торгов],
	    [Первые торги],
	    [Результат первых торгов],
	    [Фактическая сумма первых торгов],
	    [Дата вторых торгов],
	    [Вторые торги],
	    [Результат вторых торгов],
	    [Фактическая сумма вторых торгов],
	    [Тип ИЛ],
	    КураторИП,
	    СуммаПринятНаБаланс,
	    NameRegion,
	    StatusTrade,
	    DateTrade,
	    AmountTrade,
	    ArestDate1,
	    f_DatePlan,
	    f_DateTrade,
	    f_ResultTrade,
	    f_AmountTrade,
	    s_DatePlan,
	    s_DateTrade,
	    s_ResultTrade,
	    s_AmountTrade,
	    r_AmountTrade,
	    _r_DateTrade,
	    StatusAfterArest,
	    PledgeItemId,
	    Vin,
	    bancruptcy_date,
	    ПогашенНаДату,
	    ПогашенНаДатуOld,
	    isBankruptFromDate,
	    isBankruptFromDateOld,
	    [Сумма на р/с],
	    Сумма,
	    [Платежная система],
	    [Платежная система Спейс],
	    [Платежная система ФССП Спейс],
	    [Сумма платежа Спейс],
	    [Сумма платежа ФССП Спейс],
	    КомментарийФССП,
	    ДатаПоследнейКоммуникацииФССП,
	    НомерКоммуникации,
	    [Сумма платежей на р/с по договору],
	    [Сумма платежей на р/с по клиенту],
	    [Сумма платежей по договору],
	    [Сумма платежей по клиенту],
	    [Сумма платежа Спейс по договору],
	    [Сумма платежа Спейс по клиенту],
	    [Сумма платежа ФССП Спейс по договору],
	    [Сумма платежа ФССП Спейс по клиенту]
	)
  Select Deals.Дата DateFull,Deals.ClientIdFull, deals.ClientFull, deals.StageClientFull, deals.Number,deals.StageDealFull --,*
  , deals.Region
  , deals.ActualRegion
  , deals.ДатаПогашения
  , res.УчетнаяДата,
    res.УчетнаяНеделя,
    res.НачалоНедели,
    res.КонецНедели,
    res.Куратор,
    res.idClient,
    res.idDeal,
    res.idEnforcementOrder,
    res.номерДоговора,
    res.Клиент,
    res.StatusNameList,
    res.Accepted,
    res.AcceptanceDate,
    res.[Номер ИЛ],
    res.Name,
    res.ExcitationDate,
    res.CaseNumberInFSSP,
    res.EndDate,
    res.BasisEndEnforcementProceeding,
    res.ArestCarDate,
    res.SaleCarDate,
    res.ContactPerson,
    res.CommunicationDateTime,
    res.Commentary,
    res.ДатаОбещания,
    res.СуммаОбещания,
    res.СуммаПолученная,
    res.idClientBankroptOrClosed,
    res.idClientAccepted,
    res.idClientAcceptedWithSum,
    res.КлиентПринятИЛ_КА_или_Сумма,
    res.ДатаОтправкиЗаявления,
    res.idClientFSSP,
    res.NumberExcitation,
    res.NumberNoExcitation,
    res.Статья46,
    res.idClientArestCar,
    res.idClientBalanceCar,
    res.idClientComment,
    res.isKA,
    res.isBankrupt,
    res.ПолученИЛДата,
    res.ПолученИЛ,
    res.ПолученИЛсСуммой,
    res.ЧислоКомментариевДоговора,
    res.NumberEnd,
    res.NumberLoansEnd,
    res.дублиИЛ,
    res.порядокИЛ,
    res.порядокПлатежаИЛ,
    res.nameКА,
    res.nameКА_old,
    res.НомерДоговораКА,
    res.Povoljie,
    res.Alfa,
    res.[Prime Collection],
    res.RealIdClient,
    res.RealNumberLoan,
    res.RealNumberLoanOrKA,
    res.Стадия,
    res.[Сумма по ИЛ],
    res.[Идентификатора судебного иска],
    res.ДатаИЛ,
    res.датаПринятияИЛСоставная,
    res.idJudicialClaims,
    res.isActive,
    res.IncrementKA,
    res.[Дата отправления ИЛ в РОСП],
    res.[ИЛ отправлен в РОСП],
    res.[Возбуждено ИП_old],
    res.[Возбуждено ИП],
    res.[№ дела в ФССП],
    res.[Идентификатор ИП],
    res.AmountDepositToBalance,
    res.ImplementationBalanceDate,
    res.AmountImplementationBalance,
    res.AdoptionBalanceDate,
    res.[Принятие на баланс],
    res.[Реализация с баланса],
    res.[Арест машины],
    res.[Дата первых торгов],
    res.[Первые торги],
    res.[Результат первых торгов],
    res.[Фактическая сумма первых торгов],
    res.[Дата вторых торгов],
    res.[Вторые торги],
    res.[Результат вторых торгов],
    res.[Фактическая сумма вторых торгов],
    res.[Тип ИЛ],
    res.КураторИП,
    res.СуммаПринятНаБаланс,
    res.NameRegion,
    res.StatusTrade,
    res.DateTrade,
    res.AmountTrade,
    res.ArestDate1,
    res.f_DatePlan,
    res.f_DateTrade,
    res.f_ResultTrade,
    res.f_AmountTrade,
    res.s_DatePlan,
    res.s_DateTrade,
    res.s_ResultTrade,
    res.s_AmountTrade,
    res.r_AmountTrade,
    res._r_DateTrade,
    res.StatusAfterArest,
    res.PledgeItemId,
    res.Vin 
  , Bankrupt.bancruptcy_date
  , iif( ДатаПогашения is null, 0,iif(cast(ДатаПогашения as date) <= Deals.Дата, 1,0)) ПогашенНаДату
  , iif( ДатаПогашения is null, 0,iif(ДатаПогашения <= Deals.Дата, 1,0)) ПогашенНаДатуOld
  , iif( Bankrupt.bancruptcy_date is null, 0,iif(Bankrupt.bancruptcy_date <= Deals.Дата, 1,0)) isBankruptFromDate
  , iif( Bankrupt.bancruptcy_date is null, null,iif(Bankrupt.bancruptcy_date <= Deals.Дата, Deals.ClientIdFull,null)) isBankruptFromDateOld
  				, iif(  payment.[Платежная система] = 'Р/С',  payment.Сумма, null) 'Сумма на р/с'
					, payment.Сумма 'Сумма'
					, payment.[Платежная система]
					, paymentsSpace.[Платежная система] as [Платежная система Спейс]
					, paymentsSpace.[Платежная система ФССП] as [Платежная система ФССП Спейс]
					, paymentsSpace.[Сумма платежа] as [Сумма платежа Спейс]
					, paymentsSpace.[Сумма платежа ФССП] as [Сумма платежа ФССП Спейс]
, com_fssp.Commentary КомментарийФССП
, com_fssp.CommunicationDateTime ДатаПоследнейКоммуникацииФССП
, com_fssp.id_1 НомерКоммуникации

	,[Сумма платежей на р/с по договору] = sum(iif(  payment.[Платежная система] = 'Р/С',  payment.Сумма, null)) over(partition by deals.Number, Deals.Дата )
	,[Сумма платежей на р/с по клиенту]  =  Sum(iif(  payment.[Платежная система] = 'Р/С',  payment.Сумма, null)) over(partition by Deals.ClientIdFull, Deals.Дата )
	,[Сумма платежей по договору] = sum(payment.Сумма) over(partition by deals.Number, Deals.Дата )
	,[Сумма платежей по клиенту]  =  Sum(payment.Сумма) over(partition by Deals.ClientIdFull, Deals.Дата )
	,[Сумма платежа Спейс по договору] = sum(paymentsSpace.[Сумма платежа]) over(partition by deals.Number, Deals.Дата )
	,[Сумма платежа Спейс по клиенту]  =  Sum(paymentsSpace.[Сумма платежа]) over(partition by Deals.ClientIdFull, Deals.Дата )
	,[Сумма платежа ФССП Спейс по договору] = sum(paymentsSpace.[Сумма платежа ФССП]) over(partition by deals.Number, Deals.Дата )
	,[Сумма платежа ФССП Спейс по клиенту]  =  Sum(paymentsSpace.[Сумма платежа ФССП]) over(partition by Deals.ClientIdFull, Deals.Дата )	

  --into dbo.dm_CollectionEnforcementProceeding_Raw23

  from #loans_calend Deals 
 -- FROM (
	--SELECT calend.dt Дата
	--	  , datepart(iso_week,calend.dt) as Неделя
	--	  , dateadd(dd,-datepart(dw,DATEFROMPARTS(year(calend.dt),1,1))-6+datepart(iso_week,calend.dt)*7,DATEFROMPARTS(year(calend.dt),1,1)) НачалоНедели
	--	  , dateadd(dd,-datepart(dw,DATEFROMPARTS(year(calend.dt),1,1))+datepart(iso_week,calend.dt)*7,DATEFROMPARTS(year(calend.dt),1,1)) КонецНедели
	--	  , cast(format((calend.dt), 'yyyy-MM-01') as date)  НачалоМесяца
	--	  , eomonth(cast(format((calend.dt), 'yyyy-MM-01') as date)) КонецМесяца
	--	  ,l.*
	----into #loans_calend
	--FROM #calend calend, #loans  l
 -- ) AS Deals

  left join
  --select * from 
  #EnforcementProceeding_res res
  on Deals.id = res.idDeal
  and deals.дАТА = res.УчетнаяДата
  and deals.idEnforcementOrders = res.idEnforcementOrder
  --where Number = '1708036170001'
    left join (select CustomerId,
					bancruptcy_date = max(case when DateResultOfCourtsDecisionBankrupt is not null then DateResultOfCourtsDecisionBankrupt 
						else  
							case when CourtDecisionDate is not null then CourtDecisionDate
								else 
									case when CreateDate is not null then CreateDate
									else UpdateDate
								end
								end
						end)
			from  Stg._Collection.[CustomerStatus] 
			where [CustomerStateId] in (16) --15
			--and  (DateResultOfCourtsDecisionBankrupt is not null 
			----or CourtDecisionDate is not null
			--) --and CustomerId=13942
			group by CustomerId
		) Bankrupt  on Bankrupt.CustomerId=Deals.ClientIdFull
	left join #payments payment
	on payment.external_id = Deals.Number and payment.Дата = Deals.Дата and (res.порядокПлатежаИЛ=1 or res.порядокПлатежаИЛ is null) 
	left join #paymentsSpace paymentsSpace
	on paymentsSpace.IdDeal = Deals.id and paymentsSpace.[Дата платежа] = Deals.Дата  and (res.порядокПлатежаИЛ=1 or res.порядокПлатежаИЛ is null) 
	left join #t_fssp2 com_fssp on com_fssp.IdDeal = Deals.Id



	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT dbo.dm_CollectionEnforcementProceeding_Raw2', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	--DWH-2301
	--TRUNCATE TABLE dbo.dm_CollectionEnforcementProceeding_Raw23


--select top 100 * from dbo.dm_CollectionEnforcementProceeding_Raw2 where nameКА = 'ACB' order by DateFull desc
--

END
