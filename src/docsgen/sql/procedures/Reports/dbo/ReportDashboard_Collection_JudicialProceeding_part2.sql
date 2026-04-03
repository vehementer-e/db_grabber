


-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-06-04
-- Description:	
--             exec [dbo].[ReportDashboard_Collection_JudicialProceeding_part2]   --1
-- =============================================
CREATE     PROCEDURE [dbo].[ReportDashboard_Collection_JudicialProceeding_part2]
	
	-- Add the parameters for the stored procedure here
	@DateReportBegin datetime,
	@DateReportEnd datetime,
	@curator nvarchar(4000)
--	@DateReport2 int = datediff(day,0,getdate()),
--	@PageNo int 
	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	if @DateReportBegin is null 
	begin
	SET @DateReportBegin = dateadd(month, -12, Getdate())
	end
		
	if @DateReportEnd is null 
	begin
	SET @DateReportEnd = dateadd(day, 0, Getdate())
	end

	if @curator is null 
	begin
	SET @curator = ''
	end




	-- получим матрицу для заполенния
	if object_id('tempdb.dbo.#JudicialProceeding_res') is not null drop table #JudicialProceeding_res

SELECT matrix1.[Name], matrix1.Id 'Порядок', data1.Куратор, data1.ВсегоЗадач, data1.ВыполненоВСрокЗадач 
into #JudicialProceeding_res
FROM
[Stg].[_Collection].[StrategyActionTask] matrix1
left join
(
select Задача, Порядок , Куратор, count(НомерЗадачи) ВсегоЗадач,  sum(ВыполненоВСрок) ВыполненоВСрокЗадач
from
(
select d.Number
		,a2.Name 'Задача'
		,a2.id 'Порядок'
		,a1.Id 'НомерЗадачи'
		,a1.StatusId   
		,a1.[ActualDateOfDecision]
		,a1.[DateSettingsTask]
		,a1.[PlannedDateOfDecision]
		,datediff(minute,a1.[DateSettingsTask], a1.[ActualDateOfDecision]) ВремяРешения
		,datediff(minute,a1.[DateSettingsTask], a1.[PlannedDateOfDecision]) ПланирумоеВремяРешения
		,iif(isnull(a1.[ActualDateOfDecision],'2999-01-01')<a1.[PlannedDateOfDecision],1,0) ВыполненоВСрок
		--,c.LastName
		,iif(e.LastName is null, 'Не указан',isnull(e.LastName,'-') + ' ' + isnull(e.FirstName,'-') + ' ' + isnull(e.MiddleName,'-')) 'Куратор'
		--,c.*
		--, * 
from [Stg].[_Collection].[TaskAction] a1
left join [Stg].[_Collection].[StrategyActionTask] a2
on a1.StrategyActionTaskId = a2.id
left join [Stg].[_Collection].Deals d
on d.id = a1.DealId
left join [Stg].[_Collection].customers  c
on c.id = d.IdCustomer
left join [Stg].[_Collection].Employee  e
on a1.EmployeeId = e.Id
--order by d.Number
Where a1.[DateSettingsTask] >=@DateReportBegin and a1.[DateSettingsTask] <=@DateReportEnd
and (e.LastName + ' ' + e.FirstName + ' ' + e.MiddleName) in (@curator)
) aa
group by Порядок, Задача, Куратор
) data1
on data1.Порядок = matrix1.id 



  	  	delete from dbo.dm_CollectionJudicialProceedingPart2
		--drop table if exists  dbo.dm_CollectionJudicialProceedingPart2
		insert into dbo.dm_CollectionJudicialProceedingPart2
		select res.*,sla_plan.[Плановый SLA], createdDate = Getdate()--, rn = ROW_NUMBER() over (partition by idClient order by Number)
			--into dbo.dm_CollectionJudicialProceedingPart2
		from #JudicialProceeding_res res
		left join [Stg].[files].[SP_SLA_buffer] sla_plan
		on res.Name = sla_plan.Задача
		--where [№ договора] is not null

	select * from dbo.dm_CollectionJudicialProceedingPart2 



		--- ===== временное решение
			-- получим матрицу для заполенния
	if object_id('tempdb.dbo.#JudicialProceeding_res2') is not null drop table #JudicialProceeding_res2

SELECT matrix1.[Name], matrix1.Id 'Порядок', data1.Куратор, data1.ВсегоЗадач, data1.ВыполненоВСрокЗадач 
into #JudicialProceeding_res2
FROM
[Stg].[_Collection].[StrategyActionTask] matrix1
left join
(
select Задача, Порядок , Куратор, count(НомерЗадачи) ВсегоЗадач,  sum(ВыполненоВСрок) ВыполненоВСрокЗадач
from
(
select d.Number
		,a2.Name 'Задача'
		,a2.id 'Порядок'
		,a1.Id 'НомерЗадачи'
		,a1.StatusId   
		,a1.[ActualDateOfDecision]
		,a1.[DateSettingsTask]
		,a1.[PlannedDateOfDecision]
		,datediff(minute,a1.[DateSettingsTask], a1.[ActualDateOfDecision]) ВремяРешения
		,datediff(minute,a1.[DateSettingsTask], a1.[PlannedDateOfDecision]) ПланирумоеВремяРешения
		,iif(isnull(a1.[ActualDateOfDecision],'2999-01-01')<a1.[PlannedDateOfDecision],1,0) ВыполненоВСрок
		--,c.LastName
		,iif(e.LastName is null, 'Не указан',isnull(e.LastName,'-') + ' ' + isnull(e.FirstName,'-') + ' ' + isnull(e.MiddleName,'-')) 'Куратор'
		--,c.*
		--, * 
from [Stg].[_Collection].[TaskAction] a1
left join [Stg].[_Collection].[StrategyActionTask] a2
on a1.StrategyActionTaskId = a2.id
left join [Stg].[_Collection].Deals d
on d.id = a1.DealId
left join [Stg].[_Collection].customers  c
on c.id = d.IdCustomer
left join [Stg].[_Collection].Employee  e
on a1.EmployeeId = e.Id
--order by d.Number
--Where a1.[DateSettingsTask] >=@DateReportBegin and a1.[DateSettingsTask] <=@DateReportEnd
--and (e.LastName + ' ' + e.FirstName + ' ' + e.MiddleName) in (@curator)
) aa
group by Порядок, Задача, Куратор
) data1
on data1.Порядок = matrix1.id 



  	  	delete from dbo.dm_CollectionJudicialProceedingPart2
		--drop table if exists  dbo.dm_CollectionJudicialProceedingPart2
		insert into dbo.dm_CollectionJudicialProceedingPart2
		select res.*,sla_plan.[Плановый SLA], createdDate = Getdate()--, rn = ROW_NUMBER() over (partition by idClient order by Number)
			--into dbo.dm_CollectionJudicialProceedingPart2
		from #JudicialProceeding_res2 res
		left join [Stg].[files].[SP_SLA_buffer] sla_plan
		on res.Name = sla_plan.Задача

		---==== конец временного решения для получения куратора

		--where [№ договора] is not null

	/*

			-- получим матрицу для заполенния
	if object_id('tempdb.dbo.#JudicialProceeding_res') is not null drop table #JudicialProceeding_res

	select distinct
		--emp.Id
		--,
		emp.LastName + ' '  + emp.FirstName + ' ' + emp.MiddleName 'Куратор'
		,c.id 'idClient'
		, Deals.Number
		,c.LastName + ' '  + c.Name + ' ' + c.MiddleName 'Клиент'
		,c.StatusNameList
		,sp.SubmissionClaimDate
		, cst.Name Стадия
		,isk.CourtClaimSendingDate 
		, isk.ReceiptOfJudgmentDate

		,eo.Accepted
		,eo.AcceptanceDate
		,enddate
		--,fssp.name
		--,ep.ExcitationDate
		--,ep.CaseNumberInFSSP, ep.EndDate, ep.BasisEndEnforcementProceeding
		--,monitoring.ArestCarDate
		--,monitoring.[SaleCarDate]
		--,com.ContactPerson
		--,com.CommunicationDateTime
		--,com.Commentary
		--,com.PromiseDate ДатаОбещания
		--,com.PromiseSum СуммаОбещания
		--,kpi.ptpSum_if_succes_partial_ptp_new СуммаПолученная
		
		

--,* 
into #JudicialProceeding_res
from [Stg].[_Collection].JudicialProceeding sp
left join [Stg].[_Collection].JudicialClaims isk On isk.JudicialProceedingId = sp.id
  left join [Stg].[_Collection].Deals on Deals.Id = sp.DealId
  left join [Stg].[_Collection].customers c on c.id=deals.IdCustomer
  left join stg._Collection.Employee emp on c.ClaimantId = emp.Id
  left join  [Stg].[_Collection].[CollectingStage] cst  on  c.[IdCollectingStage] = cst.id
  left join [Stg].[_Collection].[EnforcementOrders]   eo on eo.JudicialClaimId=isk.id
  left join [Stg].[_Collection].EnforcementProceeding ep on eo.id=ep.EnforcementOrderId

  where emp.id is not null
/*
[Stg].[_Collection].EnforcementProceeding ep

left join [Stg].[_Collection].[EnforcementOrders]   eo on eo.id=ep.EnforcementOrderId
left join [Stg].[_Collection].JudicialClaims On JudicialClaims.id = eo.JudicialClaimId
  left join [Stg].[_Collection].JudicialProceeding on JudicialProceeding.Id = JudicialClaims.JudicialProceedingId
  left join [Stg].[_Collection].Deals on Deals.Id = JudicialProceeding.DealId
  left join [Stg].[_Collection].customers c on c.id=deals.IdCustomer
  left join stg._Collection.Employee emp on c.ClaimantId = emp.Id
  left join [Stg].[_Collection].[DepartamentFSSP] fssp on ep.DepartamentFSSPId = fssp.Id
  left join [Stg].[_Collection].[EnforcementProceedingMonitoring] monitoring on ep.id = monitoring.[EnforcementProceedingId]
  left join (select * from [Stg].[_Collection].v_Communications where CommunicationDate>'2020-01-01') com 
			on com.CustomerId = c.id
  left join (select * from  dbo.dm_CollectionKPIByMonth kpi where (success_PTP_new = 1 or succes_partial_ptp_new =1)) kpi
			on
			kpi.НомерДоговора = com.Number
			and kpi.ДатаОбещания = com.PromiseDate

  left join  [Stg].[_Collection].[CollectingStage] cst
  on  c.[IdCollectingStage] = cst.id

  where emp.id is not null
  */
  --order by ep.createdate desc


  --	  	delete from dbo.dm_CollectionEnforcementProceeding
		drop table if exists  dbo.dm_CollectionJudicialProceeding
		--insert into dbo.dm_CollectionEnforcementProceeding
		select *, createdDate = Getdate(), rn = ROW_NUMBER() over (partition by idClient order by Number)
			into dbo.dm_CollectionJudicialProceeding
		from #JudicialProceeding_res
		--where [№ договора] is not null
*/
END
