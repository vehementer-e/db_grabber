
-- exec [dbo].[Create_dm_SpaceToLoginom]
CREATE PROC dbo.Create_dm_SpaceToLoginom 
AS
BEGIN
	SET NOCOUNT ON;
-- 
 declare  @dt date = cast(dateadd(day,0, getdate()) as date)


 drop table if exists #BeforeGraph_data;
 drop table if exists #closed_data;
;with closed_data as
(
-- найдем dpd на дату закрытия
--drop table  #tt
select 
	d.ссылка as id1
	--, dateadd(year,2000,cast(b.d as datetime2(7))) ДатаДП
	, b.d AS ДатаДП
	, b.* 
--into #tt
--from	dbo.dm_CMRStatBalance_2 b with (nolock)
from	dwh2.dbo.dm_CMRStatBalance b with (nolock)
	     join [Stg].[_1cCMR].[Справочник_Договоры] d  with (nolock) on b.external_id = d.Код 
		 where b.ContractEndDate = b.d
)
select * into #closed_data
from closed_data;

CREATE CLUSTERED INDEX [ci_Период_Договор] ON #closed_data
(
	ДатаДП ASC,
	id1 ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)-- ON [_1cCMR]

;
with BeforeGraph_data as
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
	--	 from #closed_data t
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
		from #closed_data AS t
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
)

select *
into #BeforeGraph_data
from BeforeGraph_data;

 drop table if exists #dm_SpaceToLoginom;

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
				,[ИНН КА] = a.INN
			from Stg._collection.CollectingAgencyTransfer as cat
				inner join Stg._collection.Deals as d
					on d.Id = cat.DealId
				inner join Stg._collection.CollectorAgencies as a
					on a.Id = cat.CollectorAgencyId
		) as t
	where [Текущий статус] <> N'Договор отозван из КА' 
	--order by [Дата передачи в КА] desc
),
payment_new as
(
	select SUM(Amount) as Amount, iddeal 
	from  stg._Collection.[Payment]
	where year(PaymentDt) = year(getdate()) and  month(PaymentDt) = month(getdate())

	group by  iddeal
)
,
payment_last as
(
	select SUM(Amount) as Amount, iddeal , cast(PaymentDt as date) PaymentDt
	, rn = ROW_NUMBER() over( partition by iddeal order by cast(PaymentDt as date) desc)
	from  stg._Collection.[Payment]
	where year(PaymentDt) = year(getdate()) and  month(PaymentDt) = month(getdate())

	group by  iddeal, cast(PaymentDt as date)
)

,
payment_last_non_date as
(
	select SUM(Amount) as Amount, iddeal , cast(PaymentDt as date) PaymentDt
	, rn = ROW_NUMBER() over( partition by iddeal order by cast(PaymentDt as date) desc)
	from  stg._Collection.[Payment]
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
	) as t
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


SELECT   distinct
		 isnull(c.LastName,' ') + ' ' + isnull(c.Name,' ')  + ' ' + isnull(c.MiddleName,' ') AS 'ФИО клиента'
		, Deal.Number AS '№ договора'
		, ds.Name as 'Статус договора'
		, pl.Brand AS 'Марка, модель'
		, pl.Model as 'Модель' 
		, pl.Vin AS 'VIN'		
		
		--, dpd.[основной долг уплачено]
		--, dpd.[Проценты уплачено]
		--, dpd.ПениУплачено
		--, dpd.ГосПошлинаУплачено
		--, dpd.ПереплатаНачислено
		--, dpd.[ПереплатаУплачено]
		
		-- ПДП
		, dpd.d 'Дата ПДП'
		, [Сумма ПДП] = dpd.[основной долг уплачено] + dpd.[Проценты уплачено] + dpd.ПениУплачено + dpd.ГосПошлинаУплачено
		, dpd.dpd1 'DPD на Дата ПДП'

		-- блок Добровольная реализация 		
		, impprocess.ActualSaleDate 'Фактическая дата продажи'
		, impprocess.ActualSalePrice 'Фактическая сумма продажи'
		, impprocess.AmountOfForgiveness  'Сумма прощения'
		, impprocess.RequestResultOfCarImplementation  'Итог работы с запросом'

		-- СП
		, jc.CourtClaimSendingDate 'Дата отправки иска в суд'
		, jc.ReceiptOfJudgmentDate 'Дата решения суда' 
		, jc.ResultOfCourtsDecision 'Решение суда'
		, jc.AmountJudgment 'Сумма по решению суда' 

		-- ИП
		, case when eo.Accepted = 1 then 'Да'  when eo.Accepted = 0 then 'Нет' else 'Другое' end 'ИЛ принят'
		, ep.CaseNumberInFSSP '№ дела в ФССП'
		, monitoring.FirstTradingResult 'Результат первых торгов'
		, monitoring.AmountFirstTrades 'Фактическая сумма первых торгов'  -- (если результат первых торгов = состоялись)
		, monitoring.SecondTradingResult 'Результат вторых торгов' 
		, monitoring.AmountSecondTrades 'Фактическая сумма вторых торгов' -- (если результат вторых торгов = состоялись)
		, monitoring.AdoptionBalanceDate 'Дата принятия на баланс'
		, monitoring.AmountDepositToBalance 'Сумма принятия на баланс'
		, monitoring.AmountImplementationBalance 'Дата реализации с баланса'
		, monitoring.AmountImplementationBalance 'Сумма реализации с баланса'

		, iif(bv.Id is null, 'Нет','Да')  'БВ'
		, iif(fc.Id is null, 'Нет','Да')  'Fraud подтвержденный'
		, iif(hf.Id is null, 'Нет','Да')  'HARD FRAUD'
		
		-- блок урегулирования
		, s.ForgivenessDate 'Дата прощения'
		, s.AmountContribution 'Сумма взноса'
		, s.ProposalDate 'Дата предложения' 
		, s.Conditions 'Условия'
		, s.AgreementOfConditionsDate 'Срок действия согласования'
		into #dm_SpaceToLoginom
FROM            Stg._Collection.Deals AS Deal LEFT OUTER JOIN
                         Stg._Collection.customers AS c ON c.Id = Deal.IdCustomer LEFT OUTER JOIN
                         Stg._Collection.JudicialProceeding AS jp ON Deal.Id = jp.DealId LEFT OUTER JOIN
                         Stg._Collection.JudicialClaims AS jc ON jp.Id = jc.JudicialProceedingId LEFT OUTER JOIN
                         Stg._Collection.EnforcementOrders AS eo ON jc.Id = eo.JudicialClaimId LEFT OUTER JOIN
                         Stg._Collection.EnforcementProceeding AS ep ON eo.Id = ep.EnforcementOrderId LEFT OUTER JOIN
                         Stg._Collection.collectingStage AS cst_deals ON Deal.StageId = cst_deals.Id LEFT OUTER JOIN

                         Stg._Collection.EnforcementProceedingMonitoring AS monitoring ON ep.Id = monitoring.EnforcementProceedingId LEFT OUTER JOIN
                         [Stg].[_Collection].DealPledgeItem AS dpi ON dpi.DealId = Deal.Id LEFT OUTER JOIN
                         [Stg].[_Collection].[PledgeItem] AS pl ON pl.Id = dpi.PledgeItemId 
					
						 left join [Stg].[_Collection].[DealStatus] ds on Deal.idstatus = ds.id
					
					    left join #BeforeGraph_data dpd on dpd.external_id = Deal.Number
						left join stg._collection.ImplementationProcess impprocess on pl.id = impprocess.PledgeItemId
						left join [Stg].[_Collection].[Settlement] s on s.IdCustomer = c.id
						left join BV_state bv on bv.Id = c.id
						left join FraudConfirmed_state fc on fc.Id = c.id
						left join HardFraud_state hf on hf.Id = c.id
						
WHERE      cst_deals.[Name] = 'Closed' 

 begin tran

	  delete from [dbo].[dm_SpaceToLoginom] where Период=@dt

	  insert into [dbo].[dm_SpaceToLoginom] 
	  Select @dt 'Период', *
	  --into [dbo].[dm_SpaceToLoginom] 
	  FROM #dm_SpaceToLoginom
	  --[dbo].[v_dm_SpaceToLoginom]

  commit tran

END
