


-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-05-27
-- Description:	
--             exec [dbo].[ReportDashboard_Collection_EnforcementProceeding]   '2020-06-08'
-- =============================================
CREATE PROC dbo.ReportDashboard_Collection_EnforcementProceeding
	
	-- Add the parameters for the stored procedure here
	@DateReport date
--	@DateReport2 int = datediff(day,0,getdate()),
--	@PageNo int 
	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--Declare  @DateReport date = cast(dateAdd(day,0,GetDate()) as date)
	Set datefirst 1



	-- 01.06.2020 изменение требований на основе презентации
	-- добавим КА
	-- учтем статусы клиента
	-- учтем количество за 7 дней (для получения дельты)


   -- для целей определения платежей
 

	-- для целей единоразовой загрузки


	
/*
	drop table if exists [dbo].dm_CommunicationsMat
	select * 
	into [dbo].dm_CommunicationsMat
	from [Stg].[_Collection].v_Communications where cast(CommunicationDate as date)>=Dateadd(day,-124,GetDAte())
*/

--select * from [dbo].dm_Collection_IP_Payment
	

			-- получим матрицу для заполенния
	if object_id('tempdb.dbo.#EnforcementProceeding_res') is not null drop table #EnforcementProceeding_res

	select distinct
		--emp.Id
		--,
		iif(emp.LastName is null , 'Не назначен', emp.LastName + ' '  + emp.FirstName + ' ' + emp.MiddleName) 'Куратор'
		,c.id 'idClient'
		 ,Deals.Number as номерДоговора
		,c.LastName + ' '  + c.Name + ' ' + c.MiddleName 'Клиент'
		,c.StatusNameList
		,eo.Accepted
		,eo.AcceptanceDate
		,fssp.name
		,ep.ExcitationDate
		,ep.CaseNumberInFSSP
		--2020_10_08, monitoring.EndDate as EndDate --2020_08_20 ep.EndDate
		, ep.EndDate
		, ep.[CommentExcitationEnforcementProceeding] BasisEndEnforcementProceeding --2020_08_20 ep.BasisEndEnforcementProceeding
		,monitoring.ArestCarDate
		,monitoring.AdoptionBalanceDate as SaleCarDate --  чтобы не менять дизайн
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
		,ep.ErrorCorrectionNumberDate ДатаОтправкиЗаявления
		,idClientFSSP = iif(ep.ErrorCorrectionNumberDate is not null and fssp.name is not null, c.id, Null)
	--    ,idClientFSSP = iif(ep.FilingDate is not null and fssp.name is not null, c.id, Null) -- так как поле пустое, пишем другое
		,NumberExcitation = iif(ep.ExcitationDate is not null, Deals.Number, Null)
		,NumberNoExcitation = iif(ep.ExcitationDate is null, Deals.Number, Null)
		,Статья46 = iif(CHARINDEX('46',isnull(ep.[CommentExcitationEnforcementProceeding],''))>0,Deals.Number,NULL) 
		,idClientArestCar = iif(monitoring.ArestCarDate is not null , c.id, Null) 
		,idClientBalanceCar = iif(monitoring.AdoptionBalanceDate is not null , c.id, Null) 
		,idClientComment = iif(com.Commentary is not null , c.id, Null) 
		, iif( cs8.IsActive = 1,  iif(cs8.CustomerStateId=8,c.id,null),null) isKA
		, iif( cs16.IsActive = 1,  iif(cs16.CustomerStateId=16,c.id,null),null) isBankrupt
		, DATEPART ( ISO_WEEK , cast(@DateReport as date)) УчетнаяНеделя
		, eo.ReceiptDate ПолученИЛДата
		, iif(isnull(eo.ReceiptDate,'2999-01-01')<=@DateReport, Deals.Number, Null) ПолученИЛ
		, com.ЧислоКомментариевДоговора
		, NULL NumberEnd --iif(ep.EndDate is not null,Deals.Number, Null) NumberEnd
		, дублиИЛ = row_number() over (partition by Deals.Number order by isnull(ep.UpdateDate,'1900-01-01') )
		, ka.agent_name nameКА
		, ka.external_id НомерДоговораКА
		, iif(  ka.agent_name = 'Povoljie',  ka.external_id,null) Povoljie
		, iif(  ka.agent_name = 'Alfa',  ka.external_id,null) Alfa
		, iif(  ka.agent_name = 'Prime Collection',  ka.external_id,null) 'Prime Collection'
		, iif(  payment.[Платежная система] = 'Р/С',  payment.Сумма, 0) 'Сумма на р/с'
		, payment.Сумма 'Сумма'
		, payment.[Платежная система]
--,* 
into #EnforcementProceeding_res
from  [Stg].[_Collection].[EnforcementOrders]  eo  -- исполнительный лист
left join [Stg].[_Collection].EnforcementProceeding ep on eo.id=ep.EnforcementOrderId  -- исполнительное производство
left join [Stg].[_Collection].JudicialClaims On JudicialClaims.id = eo.JudicialClaimId --  судебный иск
  left join [Stg].[_Collection].JudicialProceeding on JudicialProceeding.Id = JudicialClaims.JudicialProceedingId -- субедное производство
  left join [Stg].[_Collection].Deals on Deals.Id = JudicialProceeding.DealId
  left join [Stg].[_Collection].customers c on c.id=deals.IdCustomer
  left join (select top 1 * from [Stg].[_Collection].[CustomerStatus] where [CustomerStateId]=8) cs8 on cs8.CustomerId=c.id
  left join (select top 1 * from [Stg].[_Collection].[CustomerStatus] where [CustomerStateId]=16) cs16 on cs16.CustomerId=c.id
  left join stg._Collection.Employee emp on c.ClaimantId = emp.Id
  left join [Stg].[_Collection].[DepartamentFSSP] fssp on ep.DepartamentFSSPId = fssp.Id
  left join (
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
  left join 
  (
  --Declare  @DateReport date = cast(dateAdd(day,-2,GetDate()) as date)
  SELECT [EnforcementProceedingId], FIRST_VALUE(ArestCarDate) over(partition by [EnforcementProceedingId] order by ArestCarDate desc) as ArestCarDate , FIRST_VALUE(AdoptionBalanceDate) over(partition by [EnforcementProceedingId] order by AdoptionBalanceDate desc) as AdoptionBalanceDate
  --, FIRST_VALUE(EndDate) over(partition by [EnforcementProceedingId] order by EndDate desc) as EndDate 
  from [Stg].[_Collection].[EnforcementProceedingMonitoring]) monitoring on ep.id = monitoring.[EnforcementProceedingId] -- вытащим только два показателя по мониторингу 
  --left join (
  -- --Declare  @DateReport date = cast(dateAdd(day,-2,GetDate()) as date)
  -- select * from [Stg].[_Collection].v_CommunicationsMat where cast(CommunicationDate as date)<=Dateadd(day,0,@DateReport) and cast(CommunicationDate as date)>Dateadd(day,-1,@DateReport)) com --заменить на дату расчета
		--	on com.CustomerId = c.id

			  left join (
   --Declare  @DateReport date = cast(dateAdd(day,-2,GetDate()) as date)
   select count(id_1) ЧислоКомментариевДоговора, Number , Sum(PromiseSum) PromiseSum,   min(CommunicationDateTime) CommunicationDateTime, min(Commentary) Commentary, min(ContactPerson) ContactPerson
		from [dbo].dm_CommunicationsMat
		where cast(CommunicationDate as date)<=Dateadd(day,0,@DateReport) and cast(CommunicationDate as date)>Dateadd(day,-1,@DateReport)
		group by Number) com --заменить на дату расчета
			on com.number = Deals.Number
  left join (
		--Declare  @DateReport date = cast(dateAdd(day,-2,GetDate()) as date)
		select kpi.НомерДоговора,Sum(kpi.ptpSum_if_succes_partial_ptp_new) as ptpSum_if_succes_partial_ptp_new, max(kpi.ДатаОбещания) as ДатаОбещания --, Sum(СуммаОбещания) as СуммаОбещания
		from  dbo.dm_CollectionKPIByMonth kpi where ((success_PTP_new = 1 or succes_partial_ptp_new =1) 
			and  cast(ДатаОбещания as date)<=Dateadd(day,0,@DateReport) and cast(ДатаОбещания as date)>Dateadd(day,-1,@DateReport)) group by kpi.НомерДоговора
			) kpi
		on kpi.НомерДоговора = Deals.Number

left join (select * from [dbo].dm_Collection_IP_Payment 
			where  cast(Дата as date)<=Dateadd(day,0,dateadd(year,2000,@DateReport)) and cast(Дата as date)>Dateadd(day,-1,dateadd(year,2000,@DateReport))
			) payment 
			on payment.external_id = Deals.Number
  where -- emp.id is not null
  cast(isnull(eo.CreateDate,'1900-01-01') as date) <= cast(@DateReport as date)
  --and cast(isnull(ep.EndDate,'2999-01-01') as date) >= cast(@DateReport as date)
  

  delete from #EnforcementProceeding_res where дублиИЛ>1
  --order by ep.createdate desc
  -- select *  from #EnforcementProceeding_res where НомерДоговора='1702275340002'  order by idclient
  -- select *  from dbo.dm_CollectionEnforcementProceeding where НомерДоговора='1702275340002' order by idclient

  	  	delete from dbo.dm_CollectionEnforcementProceeding where УчетнаяДата=cast(@DateReport as date)
		--drop table if exists dbo.dm_CollectionEnforcementProceeding
		insert into dbo.dm_CollectionEnforcementProceeding
		--Declare  @DateReport date = cast(dateAdd(day,-1,GetDate()) as date)
		select *, createdDate = getDAte(), УчетнаяДата=cast(@DateReport as date),  rn = rank() over (partition by idClient order by CommunicationDateTime)
		, cnt_comm = count(CommunicationDateTime) over (partition by idClient order by CommunicationDateTime)
		, cnt_end7 = count(NumberEnd) over (partition by Куратор, УчетнаяНеделя)		
		, cnt_commentary7 = sum(ЧислоКомментариевДоговора) over (partition by номерДоговора,УчетнаяНеделя)
		, sum_raschetshet7 = sum([Сумма на р/с]) over (partition by номерДоговора,УчетнаяНеделя)
		, sum7 = sum([Сумма]) over (partition by номерДоговора,УчетнаяНеделя)
			--into dbo.dm_CollectionEnforcementProceeding
			--into devdb.dbo.dm_CollectionEnforcementProceeding
		from #EnforcementProceeding_res
		--where НомерДоговора='1702275340002' 
		--where [№ договора] is not null
		--where
		--Accepted = 1


		--27.05.2020
		-- делаем витрину по дням где учитываем в том числе разность
		-- считаем каждый день с утра за предыдущий день
		--drop table if exists dbo.dm_CollectionEnforcementProceedingSummary
		--Declare  @DateReport date = cast(dateAdd(day,0,GetDate()) as date)
		delete from dbo.dm_CollectionEnforcementProceedingSummary where Дата=cast(@DateReport as date)
		insert into  dbo.dm_CollectionEnforcementProceedingSummary
		Select УчетнаяДата as Дата, Format(УчетнаяДата, 'yyyy-MM') as Период, DATEPART ( ISO_WEEK , УчетнаяДата) Неделя,  Куратор, count(distinct idClient) Клиентов,  count(distinct номерДоговора) Договоров, Банкротов = count(distinct idClientBankroptOrClosed)
		, БанкротовНовое = count(distinct isBankrupt)
		--, ДоговоровКА = count(distinct isKA)
		, ДоговоровКА = count(distinct НомерДоговораКА)	
		, ДоговоровКА_Alfa = count(distinct [Alfa])	
		, ДоговоровКА_Povoljie = count(distinct [Povoljie])	
		, ДоговоровКА_Prime_Collection = count(distinct [Prime Collection])	
		, ИЛПринят = count(distinct idClientAccepted), Sum(ЧислоКомментариевДоговора) ЧислоКомментариевДоговора
		,ОтправленВРОСП = count(distinct idClientFSSP)  
		,ВозбужденныеИП = count(distinct NumberExcitation)  
		,НеВозбужденныеИП = count(distinct NumberNoExcitation) 
		,Статья46 = count(distinct Статья46)
		,АрестМашины = count(distinct idClientArestCar)
		,МашинаНаБалансе = count(distinct idClientBalanceCar)
		,ЕстьКомментарий = count(distinct idClientComment)
		,СуммаОбещания = Sum(СуммаОбещания)
		, СуммаПолученная = Sum(СуммаПолученная)
		, ПолученИЛ = count(ПолученИЛ)
		, ЗакрытоНаНеделеПоКуратору = min(cnt_end7)
		, КомментариевНаНеделе = sum(cnt_commentary7)
		, СуммаНаРсНаНеделе = sum(sum_raschetshet7)
		, СуммаНаНеделе = sum(sum7)

		--into dbo.dm_CollectionEnforcementProceedingSummary
		from dbo.dm_CollectionEnforcementProceeding
		--where rn=1 and УчетнаяДата = @DateReport
		where УчетнаяДата=cast(@DateReport as date)
		Group by УчетнаяДата, Куратор

END
