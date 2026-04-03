
--exec  risk.[strategy_datamart_hourly_update] @CMRClientGUID = '36B65798-58BA-44DA-83B4-FAFC369EA2AA'
--select *  from risk.strategy_datamart_hourly where client_inn is not null 
--where person_id = 4961375496307103640
CREATE PROC [risk].[strategy_datamart_hourly_update]
	@CMRClientGUID nvarchar(36) = null,
	@CMRClientGUIDs nvarchar(max) = null
	with recompile
as
begin
	DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	,@msg NVARCHAR(255)
	,@subject NVARCHAR(255)
	;
	set @CMRClientGUIDs = nullif(CONCAT_WS(',', @CMRClientGUID, @CMRClientGUIDs), '')

	DECLARE @calc_date date = cast(getdate() as date) --дата расчета

begin try
	drop table if exists #ContractIds

	create table #ContractIds (ContractId nvarchar(14) primary key)
	if @CMRClientGUIDs is not null
	begin
		insert into #ContractIds(ContractId)
		select distinct [Код] from [Stg].[_1cCMR].[Справочник_Договоры] d
		where (d.Клиент  in (select [dbo].[get1CIDRREF_FromGUID](trim(value)) from string_split(@CMRClientGUIDs, ',')))
	end
	-- DWH-1396
	-- DWH-1397
	--Берем договора у которых дата подачи иска в суд или назначен  куратор BP-1781
	drop table if exists #isk_sp_space
	SELECT   
			Deal.Number AS external_id
			-- СП
			--, jc.CourtClaimSendingDate 'Дата отправки иска в суд'
			--, jc.ReceiptOfJudgmentDate 'Дата решения суда' 
			--, jc.ResultOfCourtsDecision 'Решение суда'
			--, jc.AmountJudgment 'Сумма по решению суда' 
	into #isk_sp_space
	FROM            Stg._Collection.Deals AS Deal 
		inner join stg._Collection.customers c on c.Id = Deal.IdCustomer
		LEFT JOIN Stg._Collection.JudicialProceeding AS jp ON jp.DealId  = Deal.Id
		LEFT JOIN Stg._Collection.JudicialClaims AS jc ON jc.JudicialProceedingId  = jp.Id
	where (
		isnull(jc.CourtClaimSendingDate, jc.ReceiptOfJudgmentDate)  is not null
		or 
		ISNULL(c.ClaimantExecutiveProceedingId, c.ClaimantLegalId) is not null
		)
		and (exists(Select top(1) 1 from #ContractIds t where t.ContractId = Deal.Number)
			or @CMRClientGUIDs is null)
		--  and isFake = 0
	group by Deal.Number


	drop table if exists #loans 

	SELECT 	
		--cr.*
		 cr.Number as [Номер]
		, crh.CreatedOn Дата
		,  [product_type] = 	iif (pt.code is not null
		,pt.code
		,case cr.Type
			when 0 then 'PTS'
			when 2 then 'INST'
			when 4 then 'SmInst'
			when 5 then 'PDL'
		else 'PTS' end) Collate Cyrillic_General_CI_AS
		, client_External_id = cast(c.IdExternal as nvarchar(36))
		, brand = brand.Name Collate Cyrillic_General_CI_AS  	
		, model = model.Name Collate Cyrillic_General_CI_AS 
		, client_inn = COALESCE(cr.InnFromService
			, cr.InnFromLeadGen
			, cr.Inn
			, cr_ci.InnFromService
			, cr_ci.InnFromLeadGen
			, cr_ci.Inn) Collate Cyrillic_General_CI_AS 
		, client_phone = cr.ClientPhoneMobile Collate Cyrillic_General_CI_AS 
		, initial_end_date	= cast(null as date)
		
		,ClientBirthDay = COALESCE(cr.ClientBirthDay, cr_ci.BirthDay)
		,[passport_number] = concat_ws(' '
			,COALESCE (cr.ClientPassportSerial, cr_ci.PassportSerial) 
			,COALESCE (cr.ClientPassportNumber, cr_ci.PassportNumber)
			) Collate Cyrillic_General_CI_AS
		, ClientPassportIssuedDate = COALESCE(cr.ClientPassportIssuedDate			, cr_ci.PassportIssuedDate)
		 ,[last_name] =  COALESCE(cr.ClientLastName		, cr_ci.LastName)Collate Cyrillic_General_CI_AS
		 ,[first_name] = COALESCE(cr.ClientFirstName	, cr_ci.FirstName)Collate Cyrillic_General_CI_AS
		 ,[patronymic] = COALESCE(cr.ClientMiddleName	, cr_ci.MiddleName) Collate Cyrillic_General_CI_AS
		 ,cr.VIN
		 ,cr.TsYear
		 ,cr.TsMarketPrice
		 ,cr.SumContract
		 ,productSubType_Code = pst.Code Collate Cyrillic_General_CI_AS
		into #loans
		FROM   [Stg].[_fedor].[core_ClientRequest] cr 
		inner join  [Stg].[_fedor].core_Client c on c.Id = cr.IdClient
		left join stg._fedor.core_ClientRequestClientInfo cr_ci on cr_ci.Id = cr.Id
		join ( 
				select  crh.IdClientRequest , 
					crh.CreatedOn
				from [Stg].[_fedor].[core_ClientRequestHistory]  crh
				where IdClientRequestStatus = 10
				and crh.IsDeleted = 0
				and  cast(dateadd(hour,3, crh.CreatedOn  ) as date) > cast(dateadd(day,-30,getdate()) as date)
				) crh on crh.IdClientRequest = cr.id
		left join [Stg].[_fedor].[dictionary_CreditProduct] cp on cp.Id = cr.IdCreditProduct
		left join [Stg].[_fedor].[dictionary_TsBrand] brand on cr.idTsBrand = brand.id
		left join [Stg].[_fedor].[dictionary_TsModel] model on cr.idTsModel = model.id
		left join [Stg].[_fedor].[dictionary_ProductType] pt on pt.Id = ProductTypeId
		left join stg.[_fedor].[dictionary_ProductSubType] pst on pst.Id = cr.ProductSubTypeId
		where cr.IsDeleted = 0 
			--and cr.IdStatus not in(11,13,14)  --исключаем 
			and cr.IdStatus not in(11,14, 5) 

		and (exists(Select top(1) 1 from #ContractIds t where t.ContractId =  cr.[Number] Collate Cyrillic_General_CI_AS)
			or @CMRClientGUIDs is null)	
		

	drop table if exists #actual 
	select distinct  [Номер]
	into #actual
	from   #loans

	
	drop table if exists  #intrestrate

	select  ДоговорНомер, СуммаВыдачи 
	into #intrestrate
	from reports.dbo.report_Agreement_InterestRate
	where (exists(Select top(1) 1 from #ContractIds t where t.ContractId =  ДоговорНомер Collate Cyrillic_General_CI_AS)
			or @CMRClientGUIDs is null)	


	-- получим даты начала и завершения договоров
	drop table if exists #startend
	select 
		t.external_id
		,ContractStartDate
		,ContractEndDate
		,[КоличествоПолныхДнейПросрочкиMFO]
		,[КоличествоПолныхДнейПросрочки]
		,lifetime_days_b = datediff(day, ContractStartDate, isnull(ContractEndDate,getdate())) 
		into #startend
	from (
		select 
			external_id, 
			ContractStartDate = min(b.ContractStartDate) ,
			ContractEndDate = max(b.ContractEndDate) ,
			[КоличествоПолныхДнейПросрочкиMFO] = max(b.dpdMFO) ,
			[КоличествоПолныхДнейПросрочки] = max(b.dpd) 
		from dbo.dm_CMRStatBalance b
		where (exists(Select top(1) 1 from #ContractIds t where t.ContractId =  b.external_id)
			or @CMRClientGUIDs is null)
		group by external_id
		) t
		option(recompile)



	
	--выбираем новые займы за сегодня, фильтруем по external_id чтобы небыло дублей
	--если находим соответствие клента по фио + пд то записываем общий долг по клиенту как сумму существующего и нового займа и берем макс просрочку с найденного клиента
	--иначе общий долг по клиенту равен сумме нового займа а макс просрочка 0

	drop table if exists #today
	select distinct

		   [person_id] = isnull(cast(Клиент.Ссылка as bigint), cast(-1 as bigint))
		  ,[fio] =  concat_ws(' '
				, d.[last_name] 
				,  d.[first_name] 
				,  d.[patronymic]) Collate Cyrillic_General_CI_AS
		  ,[birth_date] = dateadd(year,0,d.ClientBirthDay)
		  ,[passport_number] = d.passport_number Collate Cyrillic_General_CI_AS
		  ,[passport_date] = dateadd(year,0,d.ClientPassportIssuedDate)
		  ,[vin] = d.VIN Collate Cyrillic_General_CI_AS
		  ,[brand] = d.brand
		  ,[model] = d.model
		  ,[year] = d.TsYear
		  ,[market_price] = d.TsMarketPrice
		  ,[external_id] = d.[Номер] Collate Cyrillic_General_CI_AS
		  ,[is_active] = 1
		  ,[start_date] = cast(dateadd(year,0,d.[Дата]) as date)
		  ,[end_date] = cast(null as date)
		  ,[risk_criteria] = ''
		  ,[overdue_days] = 0
		  ,[overdue_days_max] = 0
		  ,[client_overdue_days_max] = 0
		  ,overdue_days_cmr				= 0
		  ,overdue_days_max_cmr			= 0
		  ,client_overdue_days_max_cmr	= 0
		  ,[total_rest] = d.SumContract --isnull(ir.СуммаВыдачи,d.SumContract)
		--  ,[total_rest_client] = isnull(cp.total_rest_client ,0) + isnull(ir.СуммаВыдачи,d.SumContract)
		  ,[lifetime_days] = 0
		  ,[product_type] = d.[product_type] Collate Cyrillic_General_CI_AS
	  
		
		  --isnull(iif(d.IsInstallment = 1,'INST', 'PTS'),'PTS') Collate Cyrillic_General_CI_AS
		  ,CMRClientGUID = isnull(nullif([dbo].[getGUIDFrom1C_IDRREF]( Клиент.Ссылка), 0x), d.client_External_id)
		  ,[last_name] =  d.[last_name]	 Collate Cyrillic_General_CI_AS
		  ,[first_name] = d.[first_name]	 Collate Cyrillic_General_CI_AS
		  ,[patronymic] = d.[patronymic] Collate Cyrillic_General_CI_AS
		  ,amount = d.SumContract--isnull(ir.СуммаВыдачи,d.SumContract)
		  ,row_version_CMRClient = cast(nullif(Клиент.ВерсияДанных, 0x)  as binary(8))
		  ,uid218Fz = isnull(BKI.УникальныйИдентификаторОбъектаБКИ, BKI2.УникальныйИдентификаторДоговора) --DWH-2596
		  ,averageMonthlyPayment = AP.CреднемесячныйПлатеж
		  ,client_inn = d.client_inn
		  ,client_phone = d.client_phone
		  , d.initial_end_date	
		  , productSubType_Code = d.productSubType_Code Collate Cyrillic_General_CI_AS
	into #today
	/***/
	from #loans d
	join #actual a on a.[Номер] = d.[Номер] Collate Cyrillic_General_CI_AS
	
	--left join #client_params cp on cp.fio = (d.ClientLastName + ' ' + d.ClientFirstName + ' ' + d.ClientMiddleName) Collate Cyrillic_General_CI_AS and cp.passport_number = (d.ClientPassportSerial + ' ' + d.ClientPassportNumber) Collate Cyrillic_General_CI_AS
	--left join #intrestrate ir on ir.ДоговорНомер = d.[Номер] Collate Cyrillic_General_CI_AS
	left join stg._1cCMR.Справочник_Клиенты Клиент on d.client_External_id = 
				[dbo].[getGUIDFrom1C_IDRREF]( Клиент.Ссылка)

		--DWH-2583 Уникальный Идентификатор Объекта БКИ (uid218Fz)
		LEFT JOIN (
				SELECT
					D.Код
					,T.ДоговорЗайма
					,УникальныйИдентификаторОбъектаБКИ = T.Значение_Строка
					,RN = row_number() OVER(PARTITION BY T.ДоговорЗайма ORDER BY T.Период DESC)
				FROM Stg._1cCMR.РегистрСведений_ДополнительныеСвойстваДоговоров AS T
					INNER JOIN Stg._1cCMR.Справочник_ВидыДополнительнойИнформацииДоговоры AS S
						ON S.Ссылка = T.ВидДополнительнойИнформации
						AND S.Наименование ='Уникальный идентификатор объекта БКИ'
					INNER JOIN Stg._1cCMR.Справочник_Договоры AS D
						ON D.Ссылка = T.ДоговорЗайма
				WHERE T.Значение_Строка IS NOT NULL
			) AS BKI
			ON BKI.Код = d.Номер Collate Cyrillic_General_CI_AS
			AND BKI.RN = 1
		--DWH-2596
		LEFT JOIN Stg._1cIntegration.РегистрСведений_УникальныеИдентификаторыДоговоров AS BKI2
			ON BKI2.ОбъектЗайма = d.Номер Collate Cyrillic_General_CI_AS

		--DWH-2583 Cреднемесячный Платеж (averageMonthlyPayment)
		LEFT JOIN (
			SELECT 
				Код = B.external_id,
				CреднемесячныйПлатеж = 
				CASE 
					--если в балансе есть ContractEndDate И overdue <= 0, то CреднемесячныйПлатеж := 0
					WHEN S2.ContractEndDate IS NOT NULL AND isnull(B.overdue, 0) <= 0 THEN 0
					--в качестве Даты окончания договора берется ДатаПоследнегоПлатежа из Графика
					ELSE 
						round(
							iif(
								isnull(G.СуммаПлатежей, 0) <> 0,

								--A.Borisov 17.05.24 06:19
								--Т должен считаться по формуле от ЦБ, но слегка не такой, как в комменте выше, а вот такой:
								--WHEN ДатаРасчета > ДатаОкончанияДоговора 
								--THEN 1
								--WHEN DAY(ДатаОкончанияДоговора) > DAY(ДатаРасчета)
								--THEN MONTH(ДатаОкончанияДоговора) - MONTH(ДатаРасчета) + 12 * YEAR(ДатаОкончанияДоговора) - 12 * YEAR(ДатаРасчета) + 1
								--ELSE MONTH(ДатаОкончанияДоговора) - MONTH(ДатаРасчета) + 12 * YEAR(ДатаОкончанияДоговора) - 12 * YEAR(ДатаРасчета)
								--END
								isnull(G.СуммаПлатежей, 0) / 
									CASE
										WHEN G.ДатаПоследнегоПлатежа IS NULL
											THEN 1
										WHEN @calc_date > G.ДатаПоследнегоПлатежа
											THEN 1
										WHEN day(G.ДатаПоследнегоПлатежа) > day(@calc_date)
											THEN month(G.ДатаПоследнегоПлатежа) - month(@calc_date) + 12 * year(G.ДатаПоследнегоПлатежа) - 12 * year(@calc_date) + 1
										WHEN month(G.ДатаПоследнегоПлатежа) - month(@calc_date) + 12 * year(G.ДатаПоследнегоПлатежа) - 12 * year(@calc_date) = 0
											THEN 1
										ELSE month(G.ДатаПоследнегоПлатежа) - month(@calc_date) + 12 * year(G.ДатаПоследнегоПлатежа) - 12 * year(@calc_date)
									END,
								0
							)
							+
							iif(isnull(B.overdue, 0) >= 0, isnull(B.overdue, 0), 0)
						, 0)
				END
			FROM dbo.dm_CMRStatBalance AS B
				INNER JOIN #startend AS S2
					ON B.external_id = S2.external_id
				
				LEFT JOIN (
					SELECT 
						R.Код,
						СуммаПлатежей = sum(R.СуммаПлатежа), --сумма оставшихся платежей по графику
						ДатаПоследнегоПлатежа = max(R.ДатаПлатежа)
						--T - количество месяцев, оставшихся до дня прекращения обязательства по договору
						--КоличествоМесяцев = datediff(MONTH, cast(getdate() as date), max(R.ДатаПлатежа))
					FROM dm.CMRExpectedRepayments AS R
					WHERE R.ДатаПлатежа >= cast(getdate() as date)
					GROUP BY R.Код
				) AS G
				ON B.external_id = G.Код
			WHERE 1=1
				AND B.d = @calc_date
		) AP
		ON AP.Код = d.Номер Collate Cyrillic_General_CI_AS


	where not exists(select top(1) 1 from risk.strategy_datamart sm 
		where sm.external_id = d.[Номер] Collate Cyrillic_General_CI_AS)
	

	

	--записываем результат
	drop table if exists #strategy_datamart_with_update_tmp 
	;with cte_summary as 
	(

		--oбединяем с сегодняшними данными 
	 
		SELECT 
			 dm.[person_id]
			,dm.[fio]
			,dm.[birth_date]
			,dm.[passport_number]
			--	,cast(dm.[passport_date] as date)
			,dm.[passport_date]
			,dm.[vin]
			,dm.[brand]
			,dm.[model]
			,dm.[year]
			,dm.[market_price]
			,dm.[external_id]
			,dm.[is_active]
			,dm.[start_date]
			,dm.[end_date]
			,dm.[risk_criteria]
			,dm.[overdue_days]
			,dm.[overdue_days_max]
			,dm.[total_rest]
			,dm.[lifetime_days]
			,dm.[product_type] --=  cast([product_type] as nvarchar(64))  
			,dm.CMRClientGUID
			,dm.[last_name]
			,dm.[first_name]
			,dm.[patronymic]
			,dm.amount
			,dm.row_version_CMRClient
			,dm.uid218Fz --УникальныйИдентификаторОбъектаБКИ
			,dm.averageMonthlyPayment --CреднемесячныйПлатеж
			,dm.overdue_days_cmr
			,dm.overdue_days_max_cmr
			,dm.client_overdue_days_max_cmr
			,dm.client_inn
			,dm.client_phone
		    ,dm.initial_end_date	
			,dm.productSubType_Code
			,dm.maxDpdOver30DaysL6M		
			,dm.lastDateMaxDpdOver30DaysL6M
		  FROM risk.[strategy_datamart] dm
		  where (exists(Select top(1) 1 from #ContractIds t where t.ContractId = dm.external_id)
				or @CMRClientGUIDs is null)
		  --left join #today t on 
		  --1=1
		  --and t.birth_date = dm.birth_date
		  --and t.fio = dm.fio
	  
		  union all
	  		--увеличиваем на всех займах [total_rest_client] у пользователей где есть совпадение по фио + пд с сегодняшними займами
		select 
			 td.[person_id]
			,td.[fio]
			,td.[birth_date]
			,td.[passport_number]
			,cast(td.[passport_date] as datetime2(7))  [passport_date]
			,td.[vin]
			,td.[brand]
			,td.[model]
			,td.[year]
			,td.[market_price]
			,td.[external_id]
			,td.[is_active]
			,td.[start_date] 
			,td.[end_date] 
			,td.[risk_criteria]
			,td.[overdue_days]
			,td.[overdue_days_max]
			,td.[total_rest]
			,td.[lifetime_days]
			,td.[product_type] 
			,CMRClientGUID
			,[last_name]
			,[first_name]
			,[patronymic]
			, amount
			,td.row_version_CMRClient
			--into devdb.dbo.today
			,td.uid218Fz --УникальныйИдентификаторОбъектаБКИ
			,td.averageMonthlyPayment --CреднемесячныйПлатеж
			,td.overdue_days_cmr
			,td.overdue_days_max_cmr
			,td.client_overdue_days_max_cmr
			,td.client_inn
			,td.client_phone
		    ,td.initial_end_date	
			,td.productSubType_Code
			,maxDpdOver30DaysL6M		= null
			,lastDateMaxDpdOver30DaysL6M= null
		from #today AS td
	)

	select 
			 t.[person_id]
			,t.[fio]
			,t.[birth_date]
			,t.[passport_number]
			,cast (t.[passport_date] as datetime2(7)) as [passport_date]
			,t.[vin]
			,t.[brand]
			,t.[model]
			,t.[year]
			,t.[market_price]
			,t.[external_id]
			,t.[is_active]
			,t.[start_date] 
			,t.[end_date] 
			,t.[risk_criteria]
			,t.[overdue_days]
			,t.[overdue_days_max]
			,s.[client_overdue_days_max]
			,t.[total_rest]
			,[total_rest_client]  = isnull(s.total_rest_client, 0)
			,t.[lifetime_days]
			,t.[product_type] 
			,t.CMRClientGUID
			,t.[last_name]
			,t.[first_name]
			,t.[patronymic]
			,t.amount
			,t.row_version_CMRClient
			,t.uid218Fz --УникальныйИдентификаторОбъектаБКИ
			,t.averageMonthlyPayment --CреднемесячныйПлатеж
			,overdue_days_cmr			 = t.overdue_days
			,overdue_days_max_cmr		 = t.overdue_days_max
			,client_overdue_days_max_cmr = isnull(s.client_overdue_days_max_cmr,0)
			,t.client_inn
			,t.client_phone
		    ,t.initial_end_date	
			,t.productSubType_Code
			,t.maxDpdOver30DaysL6M		
			,t.lastDateMaxDpdOver30DaysL6M
	into #strategy_datamart_with_update_tmp --[LoginomDB].dbo.strategy_datamart_with_update_new
	from cte_summary t
	left join 
	(
		select CMRClientGUID, 
				total_rest_client = sum(isnull([total_rest],0)), [client_overdue_days_max] = max([overdue_days_max]),
				 client_overdue_days_max_cmr = max(client_overdue_days_max_cmr)
			from cte_summary
		group by CMRClientGUID
	) s on s.CMRClientGUID = t.CMRClientGUID 
	
	 
	

	-- добавим сведения по судебному производству
	drop table if exists #strategy_datamart_with_update
	select t1.*, is_Claim = iif(sp.external_id is null, 0,1) 
	into #strategy_datamart_with_update
	from  #strategy_datamart_with_update_tmp t1
	-- 2021_11_16
    left join #isk_sp_space sp on sp.external_id = t1.[external_id]

	---- дополнительный процесс очистки в случае аннулирования договора
	---- производим обратное вычитание, на основе сохраненного значения по сумме

	--- 1. Найдем все аннулированные договора за 2 дня

	drop table if exists #loans_annul 

	SELECT 	cr.*, cr.Number as [Номер], crh.CreatedOn Дата
	into #loans_annul 
	FROM   [Stg].[_fedor].[core_ClientRequest] cr
	join ( 
				select IdClientRequest, max(CreatedOn) CreatedOn 
				from [Stg].[_fedor].[core_ClientRequestHistory] 
				where IdClientRequestStatus in (11,14
				,5/*Отказ 09.02.2026 по  согласованию с П. Прокопенко*/
				
				) and IsDeleted = 0 
				group by IdClientRequest
				) crh on crh.IdClientRequest = cr.id
	where 
	--cr.IsDeleted = 0 
	--and  
	cast(dateadd(hour,3, crh.CreatedOn  ) as date) > cast(dateadd(day,-2,getdate()) as date)
	/*
	--		cr.IdStatus in(11,14))  -- Id	Name
	--								--11	Заем аннулирован
	--								--12	Заем выдан
	--								--13	Заем погашен
	--								--14	Аннулировано
	--								--5		Отказано
	--
	*/
	--select *
	--from   #loans_annul --where ClientLastName = 'БАХТИЯРОВ'


	drop table if exists #loans_annul_update 

	select nn.external_id,total_rest, birth_date, fio , Дата
	into #loans_annul_update
	from #strategy_datamart_with_update nn
	join  #loans_annul na on nn.external_id = na.Номер Collate Cyrillic_General_CI_AS

	--select * from #loans_annul_update --where fio  like '%БАХТИЯРОВ%'



	--- 2. Найдем общую сумму по аннулированным договорам клиента
	drop table if exists #total_rest_client_update 
	select birth_date, fio, Sum(total_rest) total_rest, Count(*) cnt 
	into #total_rest_client_update
	from  #loans_annul_update na 
	group by  birth_date, fio

	--select * from #total_rest_client_update
	
	----- удалим из результирующего набора аннулированные
	--select nn.*
	--from  #strategy_datamart_with_update_new nn
	--join  #total_rest_client_update na 
	--on  nn.birth_date = na.birth_date
	--  and nn.fio = na.fio 
	--order by fio

	delete from #strategy_datamart_with_update
	where external_id in (select external_id from #loans_annul_update)

	---3. Обновим total_rest_client
	--select nn.*, na.total_rest ups, nn.total_rest_client - na.total_rest newvalue
	update nn
	set nn.total_rest_client = nn.total_rest_client - na.total_rest
	from  #strategy_datamart_with_update nn
	join  #total_rest_client_update na 
	on  nn.birth_date = na.birth_date
	  and nn.fio = na.fio 
	--order by fio

	/*
	alter table [LoginomDB].dbo.strategy_datamart_CMR_hourly
		add [CMRClientGUID] nvarchar(36)

	alter table [LoginomDB].dbo.strategy_datamart_CMR_hourly
		add [last_name] nvarchar(255)
			,[first_name] nvarchar(255)
			,patronymic nvarchar(255)

		*/

	update #strategy_datamart_with_update
		set FIO = 'СЕВОСТЬЯНОВА ИРИНА ВИТАЛЬЕВНА'
	where vin='X7MCF41GP8A200816';
	update #strategy_datamart_with_update
		set FIO = 'МУРАШОВА ЕКАТЕРИНА АЛЕКСЕЕВНА'
	where vin='W0L0SDL68E4067214';

	update #strategy_datamart_with_update
		  set fio='КУРОЧКИНА ТАТЬЯНА АЛЕКСЕЕВНА'
		  where vin='JMZKE197600113853'
	update #strategy_datamart_with_update
		set last_name = 'ЩУРОВА'
			,FIO = 'ЩУРОВА ОЛЬГА АНАТОЛЬЕВНА'
	where  person_id=5236739649218366765
	--person_id = 5250702209421663589 Сменил ФИО Назарова ->РАЗОРЕНОВА 20.10 по договорености с Ставничей.
	update #strategy_datamart_with_update
		set last_name = 'РАЗОРЕНОВА'
			,FIO  ='РАЗОРЕНОВА ИННА ОЛЕГОВНА'
		where person_id = 5250702209421663589

		--По договореностям с Полиной Прокопенко 17.03 Сменила ФИО 
	update	#strategy_datamart_with_update
		set last_name = 'НЕХОРОШЕВА'
		, FIO  = 'НЕХОРОШЕВА ЕЛЕНА ЕВГЕНЬЕВНА'
	where person_id =  4961375496307103640 
	--По договореностям с Полиной Прокопенко 07.04 Сменила ФИО 
	update	#strategy_datamart_with_update
		set last_name = 'ГЕРАСИМОВА'
		, FIO  = 'ГЕРАСИМОВА ДАРЬЯ ВАСИЛЕВНА'
	where person_id =  5562840887529455354 

	

	--По договореностям с Полиной Прокопенко 16.04 Сменила ФИО 
	update	#strategy_datamart_with_update
		set last_name = 'ДЯТЛОВА'
		, FIO  = 'ДЯТЛОВА НАТАЛЬЯ НИКОЛАЕВНА'
	where person_id =  5519289912718488675 


	/*
		Обновление данных за день DWH-2025
	*/
	drop table if exists  #t_CMRStatBalance
	select external_id 
	,is_active			= iif(b.external_id is null or ContractEndDate = cast(getdate() as date) , 0,1)
	,end_date			= iif(ContractEndDate = cast(getdate() as date),  ContractEndDate, null)
	,total_rest			= isnull(b.[остаток од], 0) 
	,total_rest_client  = sum(b.[остаток од]) over (partition by CMRClientGUID)  	
	into #t_CMRStatBalance
	from dbo.dm_CMRStatBalance b 
		where b.d = cast(getdate() as date)
		and (exists(Select top(1) 1 from #ContractIds t where t.ContractId =  b.external_id)
			or @CMRClientGUIDs is null) 
		and DWHInsertedDate > (select min(DWHInsertedDate) from dbo.dm_CMRStatBalance b 
		where b.d = cast(getdate() as date))


	update t
		set 
		is_active			 = b.is_active			
		,end_date			 = b.end_date			
		,total_rest			 = isnull(b.total_rest, 0)
		,total_rest_client 	 = isnull(b.total_rest_client, 0)

	from #strategy_datamart_with_update t
	inner join #t_CMRStatBalance b on b.external_id =  t.external_id


	;with cte as 
	(
	select 
		 person_id = cast(Клиент.Ссылка as bigint)
		,passport_date = coalesce( 
					nullif(iif(year(Клиент.ПаспортДатаВыдачи) > 3000, dateadd(year, -2000, Клиент.ПаспортДатаВыдачи),null),'')
				 ,t.passport_date)
		,passport_number = coalesce(
			nullif(replace(Клиент.ПаспортСерия,' ', ''),'') +' ' + nullif(replace(Клиент.ПаспортНомер,' ', ''),'')
			,t.passport_number)
		,birth_date = cast(dateadd(year, -2000, isnull(nullif(Клиент.[ДатаРождения],'2000-01-01'),t.birth_date)
				) as date)
		, last_name = trim(isnull(nullif(Клиент.Фамилия,''), t.last_name))
		, first_name = trim(isnull(nullif(Клиент.Имя,''), t.first_name))
		, patronymic = trim(isnull(nullif(Клиент.Отчество,''), t.patronymic))
		, row_version_CMRClient = Клиент.ВерсияДанных
		, CMRClientGUID
	from #strategy_datamart_with_update t
	inner join  stg._1cCMR.Справочник_Клиенты Клиент 
		on	t.CMRClientGUID = [dbo].[getGUIDFrom1C_IDRREF]( Клиент.Ссылка)
		and isnull(t.row_version_CMRClient, 0x) !=  Клиент.ВерсияДанных
	)
	update t
		set 
		fio =  concat(s.last_name, ' ', s.first_name, ' ', s.patronymic)
		,passport_date = s.passport_date
		,last_name = s.last_name
		,first_name = s.first_name
		,patronymic = s.patronymic
		,birth_date = s.birth_date
		,row_version_CMRClient = s.row_version_CMRClient
	from cte  s
	inner join #strategy_datamart_with_update  t
		on s.CMRClientGUID = t.CMRClientGUID
	

	
	
		

	begin tran
		/*
			alter table risk.strategy_datamart_hourly
				add amount money
			alter table risk.strategy_datamart_hourly
				add client_inn varchar(12)
			alter table risk.strategy_datamart_hourly
				add client_phone nvarchar(20)
			alter table risk.strategy_datamart_hourly
			add loan_term_in_days  smallint
		    ,initial_end_date	date
				
			alter table risk.strategy_datamart_hourly
				add productSubType_Code nvarchar(255)
			alter table risk.strategy_datamart_hourly add
	 maxDpdOver30DaysL6M		 smallint
	,lastDateMaxDpdOver30DaysL6M date
		*/
		delete t from risk.strategy_datamart_hourly t
		  where (exists(Select top(1) 1 from #ContractIds s where s.ContractId =  t.external_id)
		or @CMRClientGUIDs is null) 
		
		insert into risk.strategy_datamart_hourly(
			[person_id]
			,[fio]
			,[birth_date]
			,[passport_number]
			,[passport_date]
			,[vin]
			,[brand]
			,[model]
			,[year]
			,[market_price]
			,[external_id]
			,[is_active]
			,[start_date]
			,[end_date]
			,[risk_criteria]
			,[overdue_days]
			,[overdue_days_max]
			,[client_overdue_days_max]
			,[total_rest]
			,[total_rest_client] 
			,[lifetime_days]
			,[product_type]
			, is_Claim
			,created_at
			,CMRClientGUID
			,[last_name]
			,[first_name]
			,[patronymic]
			,amount
			,row_version_CMRClient
			,uid218Fz --УникальныйИдентификаторОбъектаБКИ
			,averageMonthlyPayment --CреднемесячныйПлатеж
			,overdue_days_cmr
			,overdue_days_max_cmr
			,client_overdue_days_max_cmr
			,client_inn
			,client_phone
		    ,initial_end_date	
			,productSubType_Code
			,maxDpdOver30DaysL6M		 
			,lastDateMaxDpdOver30DaysL6M 
		)
		select 
			[person_id]
			,[fio]
			,[birth_date]
			,[passport_number]
			,passport_date
			,[vin]
			,[brand]
			,[model]
			,[year]
			,[market_price]
			,[external_id]
			,[is_active]
			,[start_date]
			,[end_date]
			,[risk_criteria]
			,[overdue_days]
			,[overdue_days_max]
			,[client_overdue_days_max]
			,[total_rest]
			,[total_rest_client] = isnull([total_rest_client], 0)
			,[lifetime_days]
			,[product_type]
			,is_Claim
			,created_at = getdate()
			,CMRClientGUID
			,[last_name]
			,[first_name]
			,[patronymic]
			,amount
			,row_version_CMRClient
			,uid218Fz --УникальныйИдентификаторОбъектаБКИ
			,averageMonthlyPayment --CреднемесячныйПлатеж
			,overdue_days_cmr
			,overdue_days_max_cmr
			,client_overdue_days_max_cmr
			--into [LoginomDB].dbo.strategy_datamart_CMR_hourly_test_2021_11_22_2
			,client_inn
			,client_phone
		    ,initial_end_date	
			,productSubType_Code
			,maxDpdOver30DaysL6M		 
			,lastDateMaxDpdOver30DaysL6M 
		from #strategy_datamart_with_update --;

	commit tran
	
/**/
end try
begin catch
	SET @msg = CONCAT (
			'Ошибка выполнения процедуры - '
			,@sp_name
			,'. Ошибка '
			,ERROR_MESSAGE()
			)
	SET @subject = CONCAT (
			'Ошибка выполнение процедуры '
			,@sp_name
			)
	if @@TRANCOUNT<>0
		rollback tran;
			EXEC msdb.dbo.sp_send_dbmail @recipients = 'ala.kurikalov@smarthorizon.ru'
			--,@copy_recipients = 'dwh112@carmoney.ru'
			,@body = @msg
			,@body_format = 'TEXT'
			,@subject = @subject;
	throw
end catch
end
