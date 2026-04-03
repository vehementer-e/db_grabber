
--a.kotelevec 
--15/02/20201
--DWH-981
CREATE PROC collection.create_dm_register_of_contracts
as

begin
set xact_abort on
begin try
	----------------------------------------------------------------------------------
	--промежуточная таблица # 1 для отчета
		drop table if exists #udal_1;

	;with ka_new as
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
	, closed_data as
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
	FROM dwh2.dbo.dm_CMRStatBalance b with (nolock)
			 join [Stg].[_1cCMR].[Справочник_Договоры] d  with (nolock) on b.external_id = d.Код 
			 where b.ContractEndDate = b.d
	)
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
							,датаПринятияИЛСоставная = cast(coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date,ep.ExcitationDate) as date)
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
							 , ep.ExcitationDate AS 'Дата возбуждения ИП'
							 , ep.CaseNumberInFSSP AS '№ дела в ФССП' 
							 ,ep.[OrderOnHoldDate] AS 'Дата постановления на удержание' 
							 ,monitoring.ArestCarDate AS 'Дата ареста авто'
							 ,monitoring.ReevaluationDate AS 'Дата переоценки'
							 , monitoring.FirstTradesDate AS 'Дата первых торгов'
							 , monitoring.FirstTradingResult AS 'Результат первых торгов'
							 ,monitoring.SecondTradesDate AS 'Дата вторых торгов'
							 , monitoring.SecondTradingResult AS 'Результат вторых торгов'
							 , monitoring.DecisionDepositToBalance AS ' Решение о принятии на баланс'
							 ,monitoring.AdoptionBalanceDate AS 'Дата принятия на баланс'
							 ,ep.EndDate AS 'Дата окончания'		
							 , ep.CommentExcitationEnforcementProceeding AS 'Основания окончания ИП'
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
							, monitoring.AmountDepositToBalance AS 'Сумма принятия на баланс'
							, [Отправлено в РОСП] = ep.ErrorCorrectionNumberDate
							,iif(empIP.LastName is null , 'Не назначен', empIP.LastName + ' '  + empIP.FirstName + ' ' + empIP.MiddleName) 'КураторИП'
							, monitoring.OfferAdoptionBalanceDate 'Дата предложения о принятии на баланс'
							, CASE WHEN monitoring.DecisionDepositToBalance = 1 THEN 'Принимаем на баланс' WHEN monitoring.DecisionDepositToBalance = 0 THEN 'Не принимаем на баланс'  ELSE
							  'Не выбран' END AS 'Решение о принятии на баланс текст'
							, CASE WHEN ep.HasID = 1 THEN 'Да' WHEN ep.HasID = 0  THEN 'Нет'  ELSE
							  'Не выбрано' END AS 'Наличие ИД'
							, jc.NumberCasesInCourt 'Номер дела в суде СП'
							, hc.DebtIsRepaidUnderAnIndividualAgreement 'Долг погашен по ИД'
							, hc.AcceptedOnBalance 'Принят на баланс'
							,ep.ErrorCorrectionNumberDate 'Дата отправки заявления в ФССП'
							,monitoring.SaleCarDate 'Дата продажи с торгов'
							,monitoring.FirstTradesDatePlanned 'Плановая дата первых торгов'
							,monitoring.SecondTradesDatePlanned 'Плановая дата вторых торгов'
							,monitoring.ImplementationBalanceDate 'Дата реализации с баланса'
							,monitoring.AmountImplementationBalance 'Сумма реализации с баланса'
							,eo.ReceiptReturnDate 'Дата возврата ИЛ на доработку'
							,monitoring.PledgeItemId 'id_залога'
							,saa.name 'статус_после_ареста'
							,monitoring.statusafterarrestcomment  'коммент_после_ареста'
							,ep.Id 'id_ИП'
							,cast(cpd.BirthdayDt as date) 'дата_рождения_должника'
							,fssp.name	'росп_наименование'
							,coalesce(fssp.NameRegion,'')+' '+coalesce(fssp.TypeRegion,'')+'., '
							 +coalesce(fssp.TypeLocation,'')+' '+coalesce(fssp.NameLocation,'')+'., '
							 +coalesce(fssp.NameCity,'')+' '+coalesce(fssp.TypeCity,'')+'., '
							 +coalesce(fssp.NameStreet,'')+' '+coalesce(fssp.TypeStreet,'')+'., '+coalesce(fssp.NumberHouse,'') 'росп_адрес'
							 ,eo.Comment as 'комментарий к ИЛ'
		into #udal_1
		FROM            Stg._Collection.Deals AS Deal LEFT OUTER JOIN
							 Stg._Collection.customers AS c ON c.Id = Deal.IdCustomer LEFT OUTER JOIN
							 Stg._Collection.JudicialProceeding AS jp ON Deal.Id = jp.DealId LEFT OUTER JOIN
							 Stg._Collection.JudicialClaims AS jc ON jp.Id = jc.JudicialProceedingId LEFT OUTER JOIN
							 Stg._Collection.EnforcementOrders AS eo ON jc.Id = eo.JudicialClaimId LEFT OUTER JOIN
							 Stg._Collection.EnforcementProceeding AS ep ON eo.Id = ep.EnforcementOrderId LEFT OUTER JOIN
							 Stg._Collection.collectingStage AS cst_deals ON Deal.StageId = cst_deals.Id LEFT OUTER JOIN
							 Stg._Collection.collectingStage AS cst_client ON c.IdCollectingStage = cst_client.Id LEFT OUTER JOIN
							 Stg._Collection.CustomerPersonalData AS cpd ON cpd.IdCustomer = c.Id LEFT OUTER JOIN
							 [Stg].[_Collection].[DadataCleanFIO] AS dcfio ON dcfio.Surname = c.LastName AND dcfio.Name = c.Name AND dcfio.Patronymic = c.MiddleName LEFT OUTER JOIN
							 [Stg].[_Collection].Courts AS court ON court.Id = jp.CourtId LEFT OUTER JOIN
							 Stg._Collection.DepartamentFSSP AS fssp ON ep.DepartamentFSSPId = fssp.Id LEFT OUTER JOIN
							 Stg._Collection.EnforcementProceedingMonitoring AS monitoring ON ep.Id = monitoring.EnforcementProceedingId LEFT OUTER JOIN
							 [Stg].[_Collection].DealPledgeItem AS dpi ON dpi.DealId = Deal.Id LEFT OUTER JOIN
							 [Stg].[_Collection].[PledgeItem] AS pl ON pl.Id = dpi.PledgeItemId LEFT OUTER JOIN
							 [Stg].[_Collection].[Registration] AS reg ON reg.IdCustomer = c.Id
							 left join [Stg].[_Collection].[DealStatus] ds on Deal.idstatus = ds.id
							 left join (select * from ka_new where rn=1) ka on ka.external_id = deal.Number
							-- left join (select * from ka_risk where rn=1) kaRisk on kaRisk.external_id = deal.Number
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
										--and  DateResultOfCourtsDecisionBankrupt is not null
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
										--and  DateResultOfCourtsDecisionBankrupt is not null
										group by CustomerId) bankrupt_not_confirm on bankrupt_not_confirm.CustomerId = c.Id
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
							left join stg.[_Collection].StatusAfterArrest saa on monitoring.statusafterarrestid = saa.id 

		WHERE        (eo.Id IS NOT NULL);
	------------------------------------------------------------------------------------------------------------
	--из этой таблицы собирается отчет
		drop table if exists #udal_2;
		select distinct
				t1.r_date 'Дата формирование реестра'											
				,t1.id_IL									
				,t1.[№ договора] 'Номер договора'									
				,t5.id 'id клиента'
				,t1.[id_залога] 'id_залога'
				,t5.LastName+' '+t5.Name+' '+t5.MiddleName 'ФИО клиента'
				,cast(t1.[дата_рождения_должника] as date) 'Дата рождения должника'
				,t1.[№ ИЛ] 'ИЛ номер'
				,ISNULL(STUFF(t1.[№ ИЛ],1, NULLIF(PATINDEX('%[0-9]%',t1.[№ ИЛ]),0)-1,''),t1.[№ ИЛ]) 'цифры_в_ИЛ'
				,1 cnt									
				,t1.[Тип ИЛ] 'ИЛ тип'									
				,case when lower(t1.[№ ИЛ]) like '%сп%' or lower(t1.[№ ИЛ]) like '%/%'									
					  then '02.судебный приказ' else '01.исполнительный лист' end 'Судебный документ тип'								
				,case when (t3.StageId = 9 and t3.DebtSum = 0) -- t3.StageId = 9 - договор на стадии 'Closed'									
							or t3.fulldebt <= 0 then '08.договор закрыт'						
					  when t1.[Дата банкротства подверждено решением] is not null then '07.банкрот'								
					  when t1.[Дата принятия на баланс] is not null then '06.принят на баланс актив'								
					  when t1.[Результат вторых торгов] is not null then '05.торги проведены'								
					  when t1.[Дата ареста авто] is not null then '04.арест актива произведен'								
					  when t1.[Дата возбуждения ИП] is not null then '03.возбуждено ИП в ФССП'								
					  when t1.[ДатаПринятияИЛ] is not null and t1.[ИЛ принят] = 'Да' then '02.ИЛ принят в работу СП'								
					  else '01.ИЛ получен из суда'								
					  end [cтатус для конверсии]								
				,t1.[КураторИП]									
				,t4.Name 'Стадия сопровождения'									
				,cast(t1.[Дата ИЛ] as date) 'ИЛ дата создания судом'									
				,cast(t1.[Дата получения ИЛ] as date) 'ИЛ дата получения Carmoney'									
				,dateadd(day,- datepart(day, cast(t1.[Дата получения ИЛ] as date)) + 1, convert(date, cast(t1.[Дата получения ИЛ] as date))) 'ИЛ месяц получения'									
				,cast(t1.[ДатаПринятияИЛ] as date)  'ИЛ дата принятия в работу ИП'									
				,cast(t1.[Дата отправки заявления в ФССП] as date) 'Заявление в ФССП о ИП дата отправки'									
				,cast(t1.[Дата возбуждения ИП] as date)  'ИП дата возбуждения'									
				,cast(t1.[Дата ареста авто] as date)  'Арест дата'									
				,case when t1.[Результат вторых торгов] is not null then cast(t1.[Дата вторых торгов] as date) 									
					  else null end 'Торги вторые дата'								
				,cast(t1.[Дата принятия на баланс] as date) 'Принятие на баланс дата'									
				,case when t1.[Погашен] = 'Да' and t3.lastpaymentdate is not null then cast(t3.lastpaymentdate as date) -- это условие охватывает не все договора, но процентов на 97% соответствует действительности									
					  else null end 'ПДП дата'								
				,cast(t1.[Дата банкротства подверждено решением] as date) 'Дата банкротства подверждено решением'									
				,null 'Дата начала каникул' --t6.[дата начала каникул]									
				,null  'Дата окончания каникул'	--t6.[дата окончания каникул]								
				,case when t7.[Наименование КА]	= 'ООО «Прайм Коллекшен»' then 'ПРАЙМ'								
					  when t7.[Наименование КА]	= 'ООО «Поволжский центр урегулирования убытков»' then 'ПЦУУ'							
					  when t7.[Наименование КА]	= 'ООО «Коллекторское агентство «АЛЬФА»' then 'АЛЬФА'							
					  else t7.[Наименование КА] end 'Наименование КА'								
				,cast(t7.[Дата передачи в КА] as date) 'Дата текущей передачи в КА'									
				,cast(coalesce(t7.[Дата отзыва],t7.[Плановая дата отзыва]) as date) 'Дата текущего отзыва из КА'									
				,cast(t1.[Дата возврата ИЛ на доработку] as date) 'Дата возврата ИЛ на доработку'
				,t1.[Регион постоянной регистрации]
				,t1.[росп_наименование] 'РОСП наименование'
				,t1.[росп_адрес] 'РОСП адрес'
				,case when cast(t1.[ДатаПринятияИЛ] as date) < cast(t1.[Дата получения ИЛ] as date) 
					  then 0
					  when (case when t1.[Погашен] = 'Да' and t3.lastpaymentdate is not null then cast(t3.lastpaymentdate as date) else null end)
							<= cast(t1.[Дата получения ИЛ] as date)
					  then 0
					  when cast(t1.[Дата банкротства подверждено решением] as date) <= cast(t1.[Дата получения ИЛ] as date)
					  then 0
					  when coalesce(cast(t1.[Дата возврата ИЛ на доработку] as date),'2000-01-01') 
							>= cast(t1.[Дата получения ИЛ] as date)
					  then 0
					  else 1 end 'Флаг_1 "ИЛ поступил в ИП"'
				,case when cast(t1.[Дата возбуждения ИП] as date) < cast(t1.[Дата получения ИЛ] as date) 
					  then 0
					  when cast(t1.[Дата возбуждения ИП] as date) is not null
					  then 1
					  when t1.[Погашен] = 'Да' and t3.lastpaymentdate is not null and cast(t3.lastpaymentdate as date)
						   <= dateadd(dd,30,cast(t1.[Дата получения ИЛ] as date))
					  then 0
					  when cast(t1.[Дата банкротства подверждено решением] as date)
						   <= dateadd(dd,30,cast(t1.[Дата получения ИЛ] as date))
					  then 0
					  when cast(t1.[Дата возврата ИЛ на доработку] as date)
						   <= dateadd(dd,30,cast(t1.[Дата получения ИЛ] as date))
					  then 0
					  when 1=0
					  --when t6.[дата окончания каникул] is not null and dateadd(dd,30,t6.[дата окончания каникул])
						--   >= cast(t1.r_date as date)
					  then 0
					  else 1 end '"Флаг_1 ИЛ доступен для ИП"'
				 ,t1.[комментарий к ИЛ]
		into #udal_2
		from #udal_1 t1							
		left join stg._collection.deals t3 on t3.number = t1.[№ договора]											
		left join stg._Collection.collectingStage t4 on t4.Id = t3.StageId											
		left join stg._Collection.customers t5 on t5.id = t3.IdCustomer											
		--left join (	select distinct t1.[номер договора]										
		--			,min(t1.[дата начала каникул]) over (partition by t1.[номер договора]) 'дата начала каникул'								
		--			,max(t1.[дата окончания каникул]) over (partition by t1.[номер договора]) 'дата окончания каникул'								
		--	from devDB.dbo.say_log_dogovora_kk t1)t6 on t6.[номер договора] = t1.[№ договора]										
		left join (
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
		) as t7
			on t7.external_id = t1.[№ договора]											
			and t1.r_date between t7.[Дата передачи в КА] and coalesce(t7.[Дата отзыва],t7.[Плановая дата отзыва])
		where 1 = 1											
				and cast(t1.[Дата получения ИЛ] as date) is not null -- в статистику включаются договора, по которым установлена дата получения CarMoney
				and dateadd(day,- datepart(day, cast(t1.[Дата получения ИЛ] as date)) + 1, convert(date, cast(t1.[Дата получения ИЛ] as date))) >= '2020-01-01'
				and (case when t1.[Погашен] = 'Да' and t3.lastpaymentdate is not null then cast(t3.lastpaymentdate as date) else null end) is null
				and cast(t1.[Дата банкротства подверждено решением] as date) is null
		;

		if exists(select top(1) 1 from #udal_1)
		begin
			begin tran
				if OBJECT_ID('collection.dm_stg_register_of_contracts') is null
				begin
					select top(0) 
						[r_date], [id_IL], [№ договора], [ФИО], [Регион постоянной регистрации], [Наименование суда], [№ ИЛ], [Дата ИЛ], [Дата получения ИЛ], [ДатаПринятияИЛ], [датаПринятияИЛСоставная], [Тип ИЛ], [Сумма ИЛ, руб.], [ИЛ принят], [Наименование отдела ФССП], [Дата возбуждения ИП], [№ дела в ФССП], [Дата постановления на удержание], [Дата ареста авто], [Дата переоценки], [Дата первых торгов], [Результат первых торгов], [Дата вторых торгов], [Результат вторых торгов], [ Решение о принятии на баланс], [Дата принятия на баланс], [Дата окончания], [Основания окончания ИП], [Погашен], [Состояние в КА], [Наименование КА], [Бакнрот], [Дата банкротства подверждено решением], [Бакнрот не подтвержденный], [Дата банкротства не подверждено], [Ответственный взыскатель], [Дата передачи в КА], [Дата отзыва], [address_fssp], [БВ], [БВ по договору], [Основание БВ по договору], [БВ согласовано], [Дата ПДП], [Сумма ПДП], [DPD на Дата ПДП], [Ответственный взыскатель последний], [Дата последнего взыскателя], [Сумма принятия на баланс], [Отправлено в РОСП], [КураторИП], [Дата предложения о принятии на баланс], [Решение о принятии на баланс текст], [Наличие ИД], [Номер дела в суде СП], [Долг погашен по ИД], [Принят на баланс], [Дата отправки заявления в ФССП], [Дата продажи с торгов], [Плановая дата первых торгов], [Плановая дата вторых торгов], [Дата реализации с баланса], [Сумма реализации с баланса], [Дата возврата ИЛ на доработку], [id_залога], [статус_после_ареста], [коммент_после_ареста], [id_ИП], [дата_рождения_должника], [росп_наименование], [росп_адрес], [комментарий к ИЛ]
					into [collection].dm_stg_register_of_contracts
					from #udal_1
				end
				truncate table  [collection].dm_stg_register_of_contracts
				insert into [collection].dm_stg_register_of_contracts
					([r_date], [id_IL], [№ договора], [ФИО], [Регион постоянной регистрации], [Наименование суда], [№ ИЛ], [Дата ИЛ], [Дата получения ИЛ], [ДатаПринятияИЛ], [датаПринятияИЛСоставная], [Тип ИЛ], [Сумма ИЛ, руб.], [ИЛ принят], [Наименование отдела ФССП], [Дата возбуждения ИП], [№ дела в ФССП], [Дата постановления на удержание], [Дата ареста авто], [Дата переоценки], [Дата первых торгов], [Результат первых торгов], [Дата вторых торгов], [Результат вторых торгов], [ Решение о принятии на баланс], [Дата принятия на баланс], [Дата окончания], [Основания окончания ИП], [Погашен], [Состояние в КА], [Наименование КА], [Бакнрот], [Дата банкротства подверждено решением], [Бакнрот не подтвержденный], [Дата банкротства не подверждено], [Ответственный взыскатель], [Дата передачи в КА], [Дата отзыва], [address_fssp], [БВ], [БВ по договору], [Основание БВ по договору], [БВ согласовано], [Дата ПДП], [Сумма ПДП], [DPD на Дата ПДП], [Ответственный взыскатель последний], [Дата последнего взыскателя], [Сумма принятия на баланс], [Отправлено в РОСП], [КураторИП], [Дата предложения о принятии на баланс], [Решение о принятии на баланс текст], [Наличие ИД], [Номер дела в суде СП], [Долг погашен по ИД], [Принят на баланс], [Дата отправки заявления в ФССП], [Дата продажи с торгов], [Плановая дата первых торгов], [Плановая дата вторых торгов], [Дата реализации с баланса], [Сумма реализации с баланса], [Дата возврата ИЛ на доработку], [id_залога], [статус_после_ареста], [коммент_после_ареста], [id_ИП], [дата_рождения_должника], [росп_наименование], [росп_адрес], [комментарий к ИЛ])
				select 
						[r_date], [id_IL], [№ договора], [ФИО], [Регион постоянной регистрации], [Наименование суда], [№ ИЛ], [Дата ИЛ], [Дата получения ИЛ], [ДатаПринятияИЛ], [датаПринятияИЛСоставная], [Тип ИЛ], [Сумма ИЛ, руб.], [ИЛ принят], [Наименование отдела ФССП], [Дата возбуждения ИП], [№ дела в ФССП], [Дата постановления на удержание], [Дата ареста авто], [Дата переоценки], [Дата первых торгов], [Результат первых торгов], [Дата вторых торгов], [Результат вторых торгов], [ Решение о принятии на баланс], [Дата принятия на баланс], [Дата окончания], [Основания окончания ИП], [Погашен], [Состояние в КА], [Наименование КА], [Бакнрот], [Дата банкротства подверждено решением], [Бакнрот не подтвержденный], [Дата банкротства не подверждено], [Ответственный взыскатель], [Дата передачи в КА], [Дата отзыва], [address_fssp], [БВ], [БВ по договору], [Основание БВ по договору], [БВ согласовано], [Дата ПДП], [Сумма ПДП], [DPD на Дата ПДП], [Ответственный взыскатель последний], [Дата последнего взыскателя], [Сумма принятия на баланс], [Отправлено в РОСП], [КураторИП], [Дата предложения о принятии на баланс], [Решение о принятии на баланс текст], [Наличие ИД], [Номер дела в суде СП], [Долг погашен по ИД], [Принят на баланс], [Дата отправки заявления в ФССП], [Дата продажи с торгов], [Плановая дата первых торгов], [Плановая дата вторых торгов], [Дата реализации с баланса], [Сумма реализации с баланса], [Дата возврата ИЛ на доработку], [id_залога], [статус_после_ареста], [коммент_после_ареста], [id_ИП], [дата_рождения_должника], [росп_наименование], [росп_адрес], [комментарий к ИЛ]
				from #udal_1
			commit tran
		end
		if exists(select top(1) 1 from #udal_2)
		begin
			begin tran
				delete from [collection].dm_register_of_contracts where 1=1
				insert into [collection].dm_register_of_contracts
				(
					 [Дата формирование реестра], 
					 [id_IL], 
					 [Номер договора], 
					 [id клиента], 
					 [id_залога], [ФИО клиента], 
					 [Дата рождения должника], 
					 [ИЛ номер], [цифры_в_ИЛ], [cnt], [ИЛ тип], [Судебный документ тип], [cтатус для конверсии], [КураторИП], 
					 [Стадия сопровождения], [ИЛ дата создания судом], [ИЛ дата получения Carmoney], [ИЛ месяц получения], 
					 [ИЛ дата принятия в работу ИП], 
					 [Заявление в ФССП о ИП дата отправки], 
					 [ИП дата возбуждения], 
					 [Арест дата], 
					 [Торги вторые дата], 
					 [Принятие на баланс дата], 
					 [ПДП дата], 
					 [Дата банкротства подверждено решением], 
					 --[Дата начала каникул], 
					 --[Дата окончания каникул], 
					 [Наименование КА], [Дата текущей передачи в КА], [Дата текущего отзыва из КА], [Дата возврата ИЛ на доработку], [Регион постоянной регистрации], [РОСП наименование], [РОСП адрес], [Флаг_1 "ИЛ поступил в ИП"], ["Флаг_1 ИЛ доступен для ИП"], [комментарий к ИЛ]
				)
				select  [Дата формирование реестра], 
				[id_IL], [Номер договора], [id клиента], [id_залога], [ФИО клиента], 
				[Дата рождения должника], 
				[ИЛ номер], [цифры_в_ИЛ], [cnt], [ИЛ тип], [Судебный документ тип], [cтатус для конверсии], [КураторИП], 
				[Стадия сопровождения], [ИЛ дата создания судом], [ИЛ дата получения Carmoney], [ИЛ месяц получения], 
				[ИЛ дата принятия в работу ИП], 
				[Заявление в ФССП о ИП дата отправки], 
				[ИП дата возбуждения], 
				[Арест дата], 
				[Торги вторые дата], 
				[Принятие на баланс дата], 
				[ПДП дата], 
				[Дата банкротства подверждено решением], 
				--[Дата начала каникул], 
				--[Дата окончания каникул], 
				[Наименование КА], [Дата текущей передачи в КА], [Дата текущего отзыва из КА], [Дата возврата ИЛ на доработку], [Регион постоянной регистрации], [РОСП наименование], [РОСП адрес], [Флаг_1 "ИЛ поступил в ИП"], ["Флаг_1 ИЛ доступен для ИП"], [комментарий к ИЛ]
				--into dbo.dm_register_of_contracts
				from #udal_2
			commit tran
		end
end try
begin catch
	if @@TRANCOUNT>0
		ROLLBACK TRAN
	;throw
end catch
end
