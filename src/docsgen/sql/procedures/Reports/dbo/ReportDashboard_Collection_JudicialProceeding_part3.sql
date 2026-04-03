


-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-06-09
-- Description:	Третья вкладка требований
--             exec [dbo].[ReportDashboard_Collection_JudicialProceeding_part3]   --1
-- =============================================
CREATE     PROCEDURE [dbo].[ReportDashboard_Collection_JudicialProceeding_part3]
	
	-- Add the parameters for the stored procedure here
--	@DateReport datetime,
--	@DateReport2 int = datediff(day,0,getdate()),
--	@PageNo int 
	
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	Set datefirst 1;



	-- найдем дату перехода в легал
	if object_id('tempdb.dbo.#rs') is not null drop table #rs
	;with m
			as
			(
				select max(ДатаДобавления) max_dd
				,      max(ДатаДобавления) max_dex
				,      rs.договор         
				from [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СтадииКоллектинга] rs
				where ДатаДобавления<= dateadd(year,2000,cast(getdate() as date))
				group by rs.договор
			)
	select d.номер  external_id
	,      sc.Имя   CollectionStage
	,      m.max_dd
		into #rs
	from      m                                                                
	join      [prodsql02].[mfo].[dbo].[РегистрСведений_ГП_СтадииКоллектинга] rs on rs.договор=m.договор
			and rs.ДатаДобавления=m.max_dd
	left join [prodsql02].[mfo].[dbo].[Перечисление_ГП_СтадииКоллектинга]    sc on sc.ссылка=rs. Стадия
	join      [prodsql02].[mfo].[dbo].Документ_ГП_Договор                    d  on d.ссылка= rs.договор
	where sc.Имя='Legal'


		-- найдем дату погашения
		if object_id('tempdb.dbo.#endedContracts') is not null drop table #endedContracts

	   
	  select d.Код
		   , Период=dateadd(year,-2000,max(sd.Период))				
		into  #endedContracts
		from stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
		join stg._1ccmr.Справочник_Договоры d on d.Ссылка=sd.договор
		join stg._1ccmr.Справочник_СтатусыДоговоров  ssd on ssd.Ссылка=sd.Статус
	   where ssd.Наименование='Погашен' and d.Код in (select external_id from #rs)
	   group by d.Код

			-- получим матрицу для заполенния
	if object_id('tempdb.dbo.#JudicialProceeding_res') is not null drop table #JudicialProceeding_res

	select distinct
		--emp.Id
		--,
		c.LastName + ' '  + c.Name + ' ' + c.MiddleName 'Клиент'
		, d.Number
		, iif(emp.Id is null, 'Не указан', emp.LastName + ' '  + emp.FirstName + ' ' + emp.MiddleName) 'Куратор'
		, sp.AmountClaim  'Сумма требования'
		, sp.SubmissionClaimDate 'Дата отправки требования'
		, c.id 'idClient'
		, payment.Сумма 'Сумма платежа'
		, iif(payment.Дата is null or sp.SubmissionClaimDate is null
				, null
				, iif(cast(dateadd(year,-2000,payment.Дата) as date)>sp.SubmissionClaimDate and cast(dateadd(year,-2000,payment.Дата) as date)<isnull(CourtClaimSendingDate,'2999-01-01')
					,1
					,0)
				) *payment.Сумма 'СуммаОтТребованияДоОтправкиИскаВСуд'
		, AmountRequirements 'Сумма иска'
		,isk.CourtClaimSendingDate 'Дата отправки иска в суд'
		, iif(payment.Дата is null or CourtClaimSendingDate is null
				, null
				, iif(cast(dateadd(year,-2000,payment.Дата) as date)>CourtClaimSendingDate and cast(dateadd(year,-2000,payment.Дата) as date)<isnull(ReceiptOfJudgmentDate,'2999-01-01')
					,1
					,0)
				) *payment.Сумма 'СуммаОтОтправкиИскаДоРешенияСуда'
		, isk.ReceiptOfJudgmentDate 'Дата получения решения суда'
		, AmountJudgment  'Сумма по судебному решению'
		, iif(payment.Дата is null or isk.ReceiptOfJudgmentDate is null
				, null
				, iif(cast(dateadd(year,-2000,payment.Дата) as date)>isk.ReceiptOfJudgmentDate and cast(dateadd(year,-2000,payment.Дата) as date)<isnull(eo.AcceptanceDate,'2999-01-01')
					,1
					,0)
				) *payment.Сумма 'СуммаОтРешенияСудаДоПолученияИЛ'
		, eo.AcceptanceDate 'Дата получения ИЛ'
		, eo.Amount 'Сумма по ИЛ'
		, eo.AmountRequirementsPledge 'Требования к сумме залога'

				, iif(payment.Дата is null or eo.AcceptanceDate is null 
				, null
				, iif(cast(dateadd(year,-2000,payment.Дата) as date)>=eo.AcceptanceDate 
					,1
					,0)
				) *payment.Сумма 'СуммаОтПолученияИЛ'
       -- , monitoring.EndDate 'Дата закрытия'
	   , ep.EndDate 'Дата закрытия'
		,c.StatusNameList				
		, cst.Name Стадия	
		,eo.Accepted		
		
		, cast(dateadd(year, -2000, rs.max_dd ) as date) ДатаЛегал
		, cast(dateadd(year,-2000,payment.Дата) as date) ДатаПлатежа
		, iif(Bankrupt.CustomerId is null, null, 1) Bankrupt
		, Bankrupt.bancruptcy_date ДатаБанкротства
		, ec.Период ДатаПогашения

		
		

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
from [Stg].[_Collection].JudicialClaims isk
left join [Stg].[_Collection].JudicialProceeding sp On isk.JudicialProceedingId = sp.id
  left join [Stg].[_Collection].Deals d on d.Id = sp.DealId
  left join [Stg].[_Collection].customers c on c.id=d.IdCustomer
  left join stg._Collection.Employee emp on c.ClaimantId = emp.Id
  left join  [Stg].[_Collection].[CollectingStage] cst  on  c.[IdCollectingStage] = cst.id
  left join [Stg].[_Collection].[EnforcementOrders]   eo on eo.JudicialClaimId=isk.id
  left join [Stg].[_Collection].EnforcementProceeding ep on eo.id=ep.EnforcementOrderId
  left join #rs rs on rs.external_id = d.Number
  left join [Reports].[dbo].dm_Collection_IP_Payment  payment on payment.external_id = d.Number
  --left join (select CustomerId from  Stg._Collection.[CustomerStatus] cs 
  --          join Stg._Collection.Customers c on c.Id = cs.CustomerId  
  --          join Stg._Collection.CustomerStatusTypes cst on cs.StatusType=cst.Id and cst.name in 
  --        ('BankruptConfirmed','BankruptUnconfirmed')
  --         )Bankrupt  on Bankrupt.CustomerId=c.id
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
			where CustomerStateId in (15,16)
			and not (DateResultOfCourtsDecisionBankrupt is not null or CourtDecisionDate is not null)
			group by CustomerId
		) Bankrupt  on Bankrupt.CustomerId=c.id
   left join #endedContracts ec on ec.Код = d.Number
     left join 
  (
  --Declare  @DateReport date = cast(dateAdd(day,-2,GetDate()) as date)
  SELECT [EnforcementProceedingId], FIRST_VALUE(ArestCarDate) over(partition by [EnforcementProceedingId] order by ArestCarDate desc) as ArestCarDate , FIRST_VALUE(AdoptionBalanceDate) over(partition by [EnforcementProceedingId] order by AdoptionBalanceDate desc) as AdoptionBalanceDate
  --, FIRST_VALUE(EndDate) over(partition by [EnforcementProceedingId] order by EndDate desc) as EndDate 
  from [Stg].[_Collection].[EnforcementProceedingMonitoring]) monitoring on ep.id = monitoring.[EnforcementProceedingId]
 where  cst.Name = 'Legal'


  --	  	delete from Reports.dbo.dm_CollectionJudicialProceeding_Part3
		--drop table if exists  Reports.dbo.dm_CollectionJudicialProceeding_Part3

		--DWH-1764 
		TRUNCATE TABLE Reports.dbo.dm_CollectionJudicialProceeding_Part3
		--insert into Reports.dbo.dm_CollectionEnforcementProceeding_Part3

		INSERT Reports.dbo.dm_CollectionJudicialProceeding_Part3
		(
		    ДатаЛегал,
		    [ФИО клиента],
		    [Номер договора],
		    Куратор,
		    СуммаТребования,
		    [Дата отправки требования],
		    СуммаОтТребованияДоОтправкиИскаВСуд,
		    [Сумма иска],
		    [Дата отправки иска в суд],
		    СуммаОтОтправкиИскаДоРешенияСуда,
		    [Сумма по судебному решению],
		    [Дата получения решения суда],
		    СуммаОтРешенияСудаДоПолученияИЛ,
		    [Дата получения ИЛ],
		    [Сумма по ИЛ],
		    [Требования к сумме залога],
		    СуммаОтПолученияИЛ,
		    ПоследнаяДатаПлатежа,
		    ДатаОкончания,
		    rn,
		    Банкрот,
		    ДатаБанкротства,
		    ДатаПогашения,
		    ЕстьДатаПогашения
		)
		select --*, createdDate = Getdate(), rn = ROW_NUMBER() over (partition by Number order by isnull(SubmissionClaimDate,'1900-01-01') desc)
		ДатаЛегал,
		клиент 'ФИО клиента', 
		Number 'Номер договора',	
		Куратор 'Куратор',
			
		СуммаТребования =max([Сумма требования]) ,
		[Дата отправки требования] = max([Дата отправки требования]),
        [СуммаОтТребованияДоОтправкиИскаВСуд] = Sum([СуммаОтТребованияДоОтправкиИскаВСуд]),
		

		[Сумма иска] = max([Сумма иска]),
		[Дата отправки иска в суд] =max([Дата отправки иска в суд]),
		[СуммаОтОтправкиИскаДоРешенияСуда] = sum([СуммаОтОтправкиИскаДоРешенияСуда]),

		[Сумма по судебному решению] = max([Сумма по судебному решению]),
		[Дата получения решения суда] = max([Дата получения решения суда]),
		[СуммаОтРешенияСудаДоПолученияИЛ] = sum([СуммаОтРешенияСудаДоПолученияИЛ]),

		[Дата получения ИЛ] = max([Дата получения ИЛ]),
		[Сумма по ИЛ] = max([Сумма по ИЛ]),
		[Требования к сумме залога] = max([СуммаОтРешенияСудаДоПолученияИЛ]),
		[СуммаОтПолученияИЛ] = sum([СуммаОтПолученияИЛ]),

		ПоследнаяДатаПлатежа = max(ДатаПлатежа),
		ДатаОкончания = max([Дата закрытия]),
		rn = ROW_NUMBER() over (partition by Number order by isnull([Дата отправки требования],'1900-01-01') desc),
		Банкрот = max(Bankrupt),
		ДатаБанкротства = max(ДатаБанкротства),
		ДатаПогашения = max(ДатаПогашения),
		ЕстьДатаПогашения = iif(max(ДатаПогашения) is not null,1,0)


		--into Reports.dbo.dm_CollectionJudicialProceeding_Part3
		from #JudicialProceeding_res
		group by 
		клиент, 
		Куратор,
		Number,
		ДатаЛегал,
		[Дата отправки требования],
		[Дата отправки иска в суд]
		--where [№ договора] is not null
		delete from Reports.dbo.dm_CollectionJudicialProceeding_Part3 where rn>1

	--	select * from Reports.dbo.dm_CollectionJudicialProceeding_Part3 
		--where Number in(
		--select Number from Reports.dbo.dm_CollectionJudicialProceeding_Part3 where rn=2)


	--		-- получим список дат
	--if object_id('tempdb.dbo.#calend') is not null drop table #calend

	--select DT
	--into  #calend
	--FROM [dwh2].[Dictionary].[calendar]
	--where dt>=@dt_begin_of_month and dt<@dt_next_month

		--- данные по месяцам
		  SET DATEFIRST 1
		  --drop table if exists Reports.dbo.dm_CollectionJudicialProceeding_Part3_Summary
		  --DWH-1764 
		  TRUNCATE TABLE Reports.dbo.dm_CollectionJudicialProceeding_Part3_Summary
		  	--delete from Reports.dbo.dm_CollectionJudicialProceeding_Part3_Summary
		--insert into 	Reports.dbo.dm_CollectionJudicialProceeding_Part3_Summary
		INSERT Reports.dbo.dm_CollectionJudicialProceeding_Part3_Summary
		(
		    ПериодПогашения,
		    [Отчет по неделе],
		    [Отчет по периоду погашения],
		    НачалоМесяца,
		    КонецМесяца,
		    [1. Банкротов],
		    [2. ПослеОтправкиТребования],
		    [3. ПослеПодачиИска],
		    [4. ПослеВынесенияРешения],
		    [5. ПослеПолученияИЛ]
		)
		select cast(format(max(sp.ДатаПогашения), 'yyyy-MM-01') as date) 'ПериодПогашения'
		  , 0 'Отчет по неделе'
		  , 1 'Отчет по периоду погашения'
		  --, datepart(iso_week,sp.ДатаПогашения) as Неделя
		  --, dateadd(dd,-datepart(dw,DATEFROMPARTS(year(sp.ДатаПогашения),1,1))-6+datepart(iso_week,sp.ДатаПогашения)*7,DATEFROMPARTS(year(sp.ДатаПогашения),1,1)) НачалоНедели
		  --, dateadd(dd,-datepart(dw,DATEFROMPARTS(year(sp.ДатаПогашения),1,1))+datepart(iso_week,sp.ДатаПогашения)*7,DATEFROMPARTS(year(sp.ДатаПогашения),1,1)) КонецНедели
		  , cast(format(max(sp.ДатаПогашения), 'yyyy-MM-01') as date)  НачалоМесяца
		  , eomonth(cast(format(max(sp.ДатаПогашения), 'yyyy-MM-01') as date)) КонецМесяца
		  , 0  as '1. Банкротов'
		 -- , 0  as 'БанкротовВсего'
		 ,sum(iif(ЕстьДатаПогашения=0,
							0,
							iif(sp.ДатаПогашения>isnull(sp.[Дата отправки требования],'2999-01-01') and sp.ДатаПогашения<isnull(sp.[Дата отправки иска в суд],'2999-01-01'),
							1,
							0)
				)) as '2. ПослеОтправкиТребования'
		 ,sum(iif(ЕстьДатаПогашения=0,
							0,
							iif(sp.ДатаПогашения>isnull(sp.[Дата отправки иска в суд],'2999-01-01') and sp.ДатаПогашения<isnull(sp.[Дата получения решения суда],'2999-01-01'),
							1,
							0)
				)) as '3. ПослеПодачиИска'
		 ,sum(iif(ЕстьДатаПогашения=0,
							0,
							iif(sp.ДатаПогашения>isnull(sp.[Дата получения решения суда],'2999-01-01') and sp.ДатаПогашения<isnull(sp.[Дата получения ИЛ],'2999-01-01'),
							1,
							0)
				)) as '4. ПослеВынесенияРешения'
		 ,sum(iif(ЕстьДатаПогашения=0,
							0,
							iif(sp.ДатаПогашения>isnull(sp.[Дата получения ИЛ],'2999-01-01') ,
							1,
							0)
				)) as '5. ПослеПолученияИЛ'
	
		  --into 	Reports.dbo.dm_CollectionJudicialProceeding_Part3_Summary
		  from Reports.dbo.dm_CollectionJudicialProceeding_Part3 sp
		  where sp.ДатаЛегал is not null
		  group by cast(format((sp.ДатаПогашения), 'yyyy-MM-01') as date)


		  -- отдельно по банкротам
	----  новые -- за неделю
			UPDATE z
			SET [1. Банкротов] = cnt1
			FROM (
			SELECT sp.cnt1
			,      ps.[1. Банкротов]
			FROM      (select cast(format((sp.ДатаБанкротства), 'yyyy-MM-01') as date) ПериодБанкротства , Count([Номер договора]) as cnt1 from Reports.dbo.dm_CollectionJudicialProceeding_Part3  sp
			group by  cast(format((sp.ДатаБанкротства), 'yyyy-MM-01') as date)) sp

			LEFT JOIN Reports.dbo.dm_CollectionJudicialProceeding_Part3_Summary AS ps ON sp.ПериодБанкротства= ps.ПериодПогашения
					
			)z
	

		  --select * from Reports.dbo.dm_CollectionJudicialProceeding_Part3_Summary

  --where emp.id is not null
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
  left join (select * from  reports.dbo.dm_CollectionKPIByMonth kpi where (success_PTP_new = 1 or succes_partial_ptp_new =1)) kpi
			on
			kpi.НомерДоговора = com.Number
			and kpi.ДатаОбещания = com.PromiseDate

  left join  [Stg].[_Collection].[CollectingStage] cst
  on  c.[IdCollectingStage] = cst.id

  where emp.id is not null
  */
  --order by ep.createdate desc




--- получим суммарные показатели по отчету за неделю
 -- Посчитаем общее количество в стадии легал ( и нет даты окончания)

 	--drop table if exists  Reports.dbo.dm_CollectionJudicialProceedingSummary

	

	--select cast('2020-05-01' as date) 'Период'
	--	  , 1 'Отчет по неделе'
	--	  , 0 'Отчет по периоду'
	--	  , 22 as Неделя
	--	  , cast(Getdate() as date) as НачалоНедели
	--, cast(Getdate() as date) as КонецНедели
	--		  , cast(Getdate() as date) as НачалоМесяца
	--, cast(Getdate() as date) as КонецМесяца
	--	  , 1500  as 'ОбщееЧислоКлиентовВРаботе'
	--	  , 1600 as 'ОбшееКоличествоДоговоровВРаботе'
	--	  , 51 as 'Новые'
	--	  , 51 as 'ПоступилоВРаботу'
	--	  , 41 as 'Отправлено в суд'
	--	  , 22 as 'Получено решение суда'
	--	  , 71 as 'В процессе подачи иска в суд'
	--	  , 53 as 'Полученно решений суда'
	--	  , 43 as 'Дата получения ИЛ'
	--	  into Reports.dbo.dm_CollectionJudicialProceedingSummary
		

--insert into 	Reports.dbo.dm_CollectionJudicialProceedingSummary
--		select cast('2020-05-01' as date) 'Период'
--		  , 1 'Отчет по неделе'
--		  , 0 'Отчет по периоду'
--		  , 23 as Неделя
--		  , 1500  as 'ОбщееЧислоКлиентовВРаботе'
--		  , 1600 as 'ОбшееКоличествоДоговоровВРаботе'
--		  , 51 as 'Новые'
--		  , 51 as 'ПоступилоВРаботу'
--		  , 41 as 'Отправлено в суд'
--		  , 22 as 'Получено решение суда'
--		  , 71 as 'В процессе подачи иска в суд'
--		  , 53 as 'Полученно решений суда'
--		  , 43 as 'Дата получения ИЛ'

		--insert into 	Reports.dbo.dm_CollectionJudicialProceedingSummary
		--select cast(format(sp.ДатаЛегал, 'yyyy-MM-01') as date) 'Период'
		--  , 0 'Отчет по неделе'
		--  , 1 'Отчет по периоду'
		--  , 23 as Неделя
		--  , 1500  as 'ОбщееЧислоКлиентовВРаботе'
		--  , 1600 as 'ОбшееКоличествоДоговоровВРаботе'
		--  , 51 as 'Новые'
		--  , 51 as 'ПоступилоВРаботу'
		--  , 41 as 'Отправлено в суд'
		--  , 22 as 'Получено решение суда'
		--  , 71 as 'В процессе подачи иска в суд'
		--  , 53 as 'Полученно решений суда'
		--  , 43 as 'Дата получения ИЛ'
		--  from Reports.dbo.dm_CollectionJudicialProceeding sp
		--  group by format(sp.ДатаЛегал, 'yyyy-MM-01')

--		  SET DATEFIRST 1
--declare @week int,@year datetime
--select @week=24,@year='20200101'

--select dateadd(dd,-datepart(dw,@year)-6+@week*7,@year)

--update Reports.dbo.dm_CollectionJudicialProceedingSummary 
--set [ОбщееЧислоКлиентовВРаботе] = count(*)
--from Reports.dbo.dm_CollectionJudicialProceeding sp
--group by Year(sp.ДатаЛегал), datepart(iso_week,sp.ДатаЛегал)
--where datepart(iso_week,sp.ДатаЛегал) = Reports.dbo.dm_CollectionJudicialProceedingSummary.Неделя
--and Year(sp.ДатаЛегал) = Year(Reports.dbo.dm_CollectionJudicialProceedingSummary.Период)

	----Select distinct Year(sp.ДатаЛегал) Год, datepart(iso_week,sp.ДатаЛегал) Неделя ,(number) as cnt1 from Reports.dbo.dm_CollectionJudicialProceeding  sp
	----join (select ДатаЛегал from Reports.dbo.dm_CollectionJudicialProceeding group by ДатаЛегал ) sp2 on sp.ДатаЛегал < sp2.ДатаЛегал
	------group by 
	--select КонецНедели, count(number) cnt2 from Reports.dbo.dm_CollectionJudicialProceedingSummary  sp
	--left join (select ДатаЛегал, number, isnull(EndDate,'1900-01-01') EndDate from Reports.dbo.dm_CollectionJudicialProceeding ) sp2 on sp2.ДатаЛегал < sp.КонецНедели 
	--and EndDate< sp.КонецНедели 
	--group by КонецНедели
	--order by КонецНедели desc

--	select s.*,
--       coalesce(count(s.number) over (order by s.ДатаЛегал 
--                rows between unbounded preceding and current row), 
--                0) as total
--from Reports.dbo.dm_CollectionJudicialProceeding s
--order by s.ДатаЛегал;

		--  SET DATEFIRST 1
		--  --drop table if exists Reports.dbo.dm_CollectionJudicialProceedingSummary
		--  	delete from Reports.dbo.dm_CollectionJudicialProceedingSummary
		--insert into 	Reports.dbo.dm_CollectionJudicialProceedingSummary
		--select cast(format(max(sp.ДатаЛегал), 'yyyy-MM-01') as date) 'Период'
		--  , 1 'Отчет по неделе'
		--  , 0 'Отчет по периоду'
		--  , datepart(iso_week,sp.ДатаЛегал) as Неделя
		--  , dateadd(dd,-datepart(dw,DATEFROMPARTS(year(sp.ДатаЛегал),1,1))-6+datepart(iso_week,sp.ДатаЛегал)*7,DATEFROMPARTS(year(sp.ДатаЛегал),1,1)) НачалоНедели
		--  , dateadd(dd,-datepart(dw,DATEFROMPARTS(year(sp.ДатаЛегал),1,1))+datepart(iso_week,sp.ДатаЛегал)*7,DATEFROMPARTS(year(sp.ДатаЛегал),1,1)) КонецНедели
		--  , cast(format(max(sp.ДатаЛегал), 'yyyy-MM-01') as date)  НачалоМесяца
		--  , eomonth(cast(format(max(sp.ДатаЛегал), 'yyyy-MM-01') as date)) КонецМесяца
		--  , 0  as 'ОбщееЧислоКлиентовВРаботе'
		--  , 0 as 'ОбшееКоличествоДоговоровВРаботе'
		--  , 0 as 'Новые'
		--  , 0 as 'ПоступилоВРаботу'
		--  , 0 as 'Отправлено в суд'
		--  , 0 as 'Получено решение суда'
		--  , 0 as 'В процессе подачи иска в суд'
		--  , 0 as 'Полученно решений суда за неделю'
		--  , 0 as 'Получено ИЛ'
		--  , 0 as 'Получено ИЛ за неделю'
		--  --into 	Reports.dbo.dm_CollectionJudicialProceedingSummary
		--  from Reports.dbo.dm_CollectionJudicialProceeding sp
		--  where sp.ДатаЛегал is not null
		--  group by Year(sp.ДатаЛегал), datepart(iso_week,sp.ДатаЛегал)

		--insert into 	Reports.dbo.dm_CollectionJudicialProceedingSummary
		--select cast(format(max(sp.ДатаЛегал), 'yyyy-MM-01') as date) 'Период'
		--  , 0 'Отчет по неделе'
		--  , 1 'Отчет по периоду'
		--  , null Неделя
		--  , null НачалоНедели
		--  , null КонецНедели
		--  , cast(format(max(sp.ДатаЛегал), 'yyyy-MM-01') as date)  НачалоМесяца
		--  , eomonth(cast(format(max(sp.ДатаЛегал), 'yyyy-MM-01') as date)) КонецМесяца
		--  , 0  as 'ОбщееЧислоКлиентовВРаботе'
		--  , 0 as 'ОбшееКоличествоДоговоровВРаботе'
		--  , 0 as 'Новые'
		--  , 0 as 'ПоступилоВРаботу'
		--  , 0 as 'Отправлено в суд'
		--  , 0 as 'Получено решение суда'
		--  , 0 as 'В процессе подачи иска в суд'
		--  , 0 as 'Полученно решений суда за неделю'
		--  , 0 as 'Получено ИЛ'
		--  , 0 as 'Получено ИЛ за неделю'
		--  --into 	Reports.dbo.dm_CollectionJudicialProceedingSummary
		--  from Reports.dbo.dm_CollectionJudicialProceeding sp
		--  where sp.ДатаЛегал is not null
		--  group by cast(format((sp.ДатаЛегал), 'yyyy-MM-01') as date) 
		--  --Year(sp.ДатаЛегал), datepart(iso_week,sp.ДатаЛегал)
		  

----  новые -- за неделю
--UPDATE z
--SET [Новые] = cnt1
--FROM (
--SELECT sp.cnt1
--,      ps.[Новые]
--FROM     (select Year(sp.ДатаЛегал) Год, datepart(iso_week,sp.ДатаЛегал) Неделя , Count(number) as cnt1 from Reports.dbo.dm_CollectionJudicialProceeding  sp
--group by  Year(sp.ДатаЛегал), datepart(iso_week,sp.ДатаЛегал)) sp

--LEFT JOIN Reports.dbo.dm_CollectionJudicialProceedingSummary AS ps ON sp.Неделя= ps.Неделя
--		and Год = Year(ps.Период)
--)z
--	--

----  Получено ИЛ за неделю
--UPDATE z
--SET [Получено ИЛ за неделю] = cnt1
--FROM (
--SELECT sp.cnt1
--,      ps.[Получено ИЛ за неделю]
--FROM     (
--			select Year(sp.AcceptanceDate) Год, datepart(iso_week,sp.AcceptanceDate) Неделя , Count(number) as cnt1 
--			from Reports.dbo.dm_CollectionJudicialProceeding  sp
--			group by  Year(sp.AcceptanceDate), datepart(iso_week,sp.AcceptanceDate)
--		 ) sp

--		LEFT JOIN Reports.dbo.dm_CollectionJudicialProceedingSummary AS ps 
--		ON sp.Неделя= ps.Неделя	and Год = Year(ps.Период)
--)z
--	--

--	--  Полученно решений суда за неделю'
--UPDATE z
--SET [Полученно решений суда за неделю] = cnt1
--FROM (
--SELECT sp.cnt1
--,      ps.[Полученно решений суда за неделю]
--FROM     (
--			select Year(sp.ReceiptOfJudgmentDate) Год, datepart(iso_week,sp.ReceiptOfJudgmentDate) Неделя , Count(number) as cnt1 
--			from Reports.dbo.dm_CollectionJudicialProceeding  sp
--			group by  Year(sp.ReceiptOfJudgmentDate), datepart(iso_week,sp.ReceiptOfJudgmentDate)
--		 ) sp

--		LEFT JOIN Reports.dbo.dm_CollectionJudicialProceedingSummary AS ps 
--		ON sp.Неделя= ps.Неделя	and Год = Year(ps.Период)
--)z
--	--


--	--  Отправлены в суд
--UPDATE z
--SET [Отправлено в суд] = cnt1
--FROM (
--SELECT sp.cnt1
--,      ps.[Отправлено в суд]
--FROM     (select Year(sp.CourtClaimSendingDate) Год, datepart(iso_week,sp.CourtClaimSendingDate) Неделя , Count(number) as cnt1 from Reports.dbo.dm_CollectionJudicialProceeding  sp
--group by  Year(sp.CourtClaimSendingDate), datepart(iso_week,sp.CourtClaimSendingDate)) sp

--LEFT JOIN Reports.dbo.dm_CollectionJudicialProceedingSummary AS ps ON sp.Неделя= ps.Неделя
--		and Год = Year(ps.Период)
--)z
--	--

--	--  всего клиентов в работе
--UPDATE z
--SET [ОбщееЧислоКлиентовВРаботе] = cnt2
--FROM (
--SELECT sp.cnt2
--,      ps.[ОбщееЧислоКлиентовВРаботе]
--FROM     (	select КонецНедели, count(number) cnt2 from Reports.dbo.dm_CollectionJudicialProceedingSummary  sp
--	left join (select ДатаЛегал, number, isnull(EndDate,'1900-01-01') EndDate from Reports.dbo.dm_CollectionJudicialProceeding ) sp2 on sp2.ДатаЛегал < sp.КонецНедели 
--	and EndDate< sp.КонецНедели 
--	group by КонецНедели) sp

--LEFT JOIN Reports.dbo.dm_CollectionJudicialProceedingSummary AS ps ON sp.КонецНедели= ps.КонецНедели
		
--)z
--	--

--	--- В процессе подачи иска в суд

--	UPDATE z
--SET [В процессе подачи иска в суд] = cnt2
--FROM (
--SELECT sp.cnt2
--,      ps.[В процессе подачи иска в суд]
--FROM     (	select КонецНедели, count(number) cnt2 from Reports.dbo.dm_CollectionJudicialProceedingSummary  sp
--	left join (select ДатаЛегал, number, isnull(EndDate,'1900-01-01') EndDate, CourtClaimSendingDate, SubmissionClaimDate  from Reports.dbo.dm_CollectionJudicialProceeding ) sp2 
--	on sp2.ДатаЛегал < sp.КонецНедели 
--	and EndDate< sp.КонецНедели
--	where  (CourtClaimSendingDate is null or isnull(CourtClaimSendingDate,'2999-01-01')>sp.КонецНедели ) and (SubmissionClaimDate is not null or isnull(SubmissionClaimDate,'2999-01-01')<sp.КонецНедели )
--	group by КонецНедели) sp

--LEFT JOIN Reports.dbo.dm_CollectionJudicialProceedingSummary AS ps ON sp.КонецНедели= ps.КонецНедели
		
--)z
--	--

--		--- Получено решение суда

--	UPDATE z
--SET [Получено решение суда] = cnt2
--FROM (
--SELECT sp.cnt2
--,      ps.[Получено решение суда]
--FROM     (	select КонецНедели, count(number) cnt2 from Reports.dbo.dm_CollectionJudicialProceedingSummary  sp
--	left join (select ДатаЛегал, number, isnull(EndDate,'1900-01-01') EndDate, CourtClaimSendingDate, SubmissionClaimDate, ReceiptOfJudgmentDate from Reports.dbo.dm_CollectionJudicialProceeding ) sp2 
--	on sp2.ДатаЛегал < sp.КонецНедели 
--	and EndDate< sp.КонецНедели
--	where  (isnull(ReceiptOfJudgmentDate,'2999-01-01')<sp.КонецНедели ) 
--	group by КонецНедели) sp

--LEFT JOIN Reports.dbo.dm_CollectionJudicialProceedingSummary AS ps ON sp.КонецНедели= ps.КонецНедели
		
--)z
--	--
--	--==========================================
--	--- теперь за месяц
--	-- ==========================================
--		--  всего клиентов в работе
--UPDATE z
--SET [ОбщееЧислоКлиентовВРаботе] = cnt2
--FROM (
--SELECT sp.cnt2
--,      ps.[ОбщееЧислоКлиентовВРаботе]
--FROM     (	select Период, [Отчет по периоду], count(number) cnt2 from Reports.dbo.dm_CollectionJudicialProceedingSummary  sp
--	left join (select ДатаЛегал, number, isnull(EndDate,'1900-01-01') EndDate from Reports.dbo.dm_CollectionJudicialProceeding ) sp2 on sp2.ДатаЛегал <= sp.КонецМесяца 
--	and EndDate<= sp.КонецМесяца 
--	where  [Отчет по периоду] = 1
--	group by Период, [Отчет по периоду]) sp

--LEFT JOIN Reports.dbo.dm_CollectionJudicialProceedingSummary AS ps ON sp.Период= ps.Период --and sp.[Отчет по периоду] = ps.[Отчет по периоду]
--	where ps.[Отчет по периоду] = 1	
--)z
--	--

--	--  новые -- за месяц
--UPDATE z
--SET [Новые] = cnt1
--FROM (
--SELECT sp.cnt1
--,      ps.[Новые]
--FROM     (select  cast(format((sp.ДатаЛегал), 'yyyy-MM-01') as date) Период , Count(number) as cnt1 from Reports.dbo.dm_CollectionJudicialProceeding  sp
--group by  cast(format((sp.ДатаЛегал), 'yyyy-MM-01') as date)) sp

--LEFT JOIN Reports.dbo.dm_CollectionJudicialProceedingSummary AS ps ON sp.Период= ps.Период
--	where ps.[Отчет по периоду] = 1	

--)z
--	--

--			  	select * from   Reports.dbo.dm_CollectionJudicialProceedingSummary 
--				where [Отчет по периоду] = 1
--				order by Период, Неделя


END
