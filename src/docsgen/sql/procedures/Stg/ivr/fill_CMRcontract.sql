/*exec ivr.[fill_CMRcontract]
   @CRMClientGUID = 'C0E50673-A36F-4E07-AD52-18F5B5DCE82E'
   ,@isDebug =1 , @reLoadAll = 1
*/
-- Usage: запуск процедуры с параметрами
-- EXEC [ivr].[fill_CMRcontract] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   PROC [ivr].[fill_CMRcontract]
	@isDebug bit= 0,
	@reLoadAll bit = 0,
	@CRMClientGUID nvarchar(36) = null
as
begin
SET XACT_ABORT ON
	SELECT @isDebug = isnull(@isDebug, 0)
begin try

	declare @partitionId int =   $partition.[pfn_range_right_Type_part_IVR_Data]('CMR_contract')
		,@StartDate datetime
		, @row_count int
		,@CRMRequest_RowVersion binary(8)   = 0x00
		,@CMRContract_RowVersion binary(8)  = 0x00
	if @reLoadAll = 0
	begin
		select 
			@CRMRequest_RowVersion = max(CRMRequest_RowVersion)
			,@CMRContract_RowVersion = max([CMRContract_RowVersion]) 
			from [ivr].[IVR_Data]
			where $partition.[pfn_range_right_Type_part_IVR_Data](Type) = @partitionId
		end		
	select 	@CRMRequest_RowVersion = isnull(@CRMRequest_RowVersion, 0x00)
			,@CMRContract_RowVersion = isnull(@CMRContract_RowVersion, 0x00)

	SELECT @StartDate = getdate(), @row_count = 0
	
	 if OBJECT_ID('ivr.IVR_Data_CMR_contract_stage') is null
	 begin
		select top(0)
			*
		into ivr.IVR_Data_CMR_contract_stage --on [pschema_pfn_range_right_Type_part_IVR_Data](type)
		from ivr.IVR_Data 
		create clustered index cix on  ivr.IVR_Data_CMR_contract_stage([Caller])
			on [pschema_pfn_range_right_Type_part_IVR_Data](type)

		create index [ix_CRMRequestGUID]on  ivr.IVR_Data_CMR_contract_stage(CRMRequestGUID)
		on [pschema_pfn_range_right_Type_part_IVR_Data](type)
	end

	truncate table ivr.IVR_Data_CMR_contract_stage
	insert into ivr.IVR_Data_CMR_contract_stage
	(
		[Caller]
		, [Cmclient]
		, [CRMClientGUID]
		, [Dpd]
		, [Legal]
		, [ExecutionOrder]
		, [ProblemClient]
		, [CRMRequestGUID]
		, [CRMRequestID]
		, [fio]
		, [IVRDate]
		, [created]
		, [updated]
		, [isHistory]
		, [ClientStage]
		, [RequestType]
		, [CRMRequestDate]
		, [isActive]
		, [ClaimantFio]
		, [ClaimantCorporatePhone]
		, [IsInstallment]
		, [hasContract]
		, [hasRejection]
		, [isSmartInstallment]
		, [CRMRequestsLastStatus]
		, [claimantStage]
		, [CRMRequest_RowVersion]
		, [Type]
		, [CMRContract_RowVersion]
		, [МобильныйТелефон]
		, [CMRContractGuid]
		, [channellid]
		, [productType]
		, [salesstage]
		, [requestTime]
		, [salesstageTime]
		, [naumenCase4MarketProposal]
		, requestLastStatusCode
		
	)
	select 
		[Caller]
		, [Cmclient]
		, [CRMClientGUID]
		, [Dpd]
		, [Legal]
		, [ExecutionOrder]
		, [ProblemClient]
		, [CRMRequestGUID]
		, [CRMRequestID]
		, [fio]
		, [IVRDate]
		, [created]
		, [updated]
		, [isHistory]
		, [ClientStage]
		, [RequestType]
		, [CRMRequestDate]
		, [isActive]
		, [ClaimantFio]
		, [ClaimantCorporatePhone]
		, [IsInstallment]
		, [hasContract]
		, [hasRejection]
		, [isSmartInstallment]
		, [CRMRequestsLastStatus]
		, [claimantStage]
		, [CRMRequest_RowVersion]
		, [Type]
		, [CMRContract_RowVersion]
		, [МобильныйТелефон]
		, [CMRContractGuid]
		, [channellid]
		, [productType]
		, [salesstage]
		, [requestTime]
		, [salesstageTime]
		, [naumenCase4MarketProposal]
		, requestLastStatusCode
		
	
	from ivr.IVR_Data
	where $partition.[pfn_range_right_Type_part_IVR_Data](Type) = @partitionId

	select external_id = Договоры.Код
	  ,КоличествоПолныхДнейПросрочкиУМФО = isnull(a.КоличествоПолныхДнейПросрочкиУМФО,0)
	  into #a 
	  from _1cCMR.Справочник_Договоры AS Договоры   
	  left join  (
	  
	  select 
	   a.Договор,
	  КоличествоПолныхДнейПросрочкиУМФО = min(a.КоличествоПолныхДнейПросрочкиУМФО)
	  
	  from (
		select last_Период = max(Период)
			,Договор
		from dbo._1cАналитическиеПоказатели
		group by Договор
	  ) t_last
		inner join dbo._1cАналитическиеПоказатели a 
		on a.Договор = t_last.Договор
			and a.Период = last_Период
			group by a.Договор
	  ) a
	  ON Договоры.Ссылка = a.Договор
	SELECT @row_count = @@ROWCOUNT
	--select * from #a
	CREATE CLUSTERED INDEX ix1 ON #a(external_id)
	
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #a', @row_count, cast(getdate() - @StartDate as time(2)) as duration
	END
	--
	drop table if exists #Client_Stage
	select distinct 
		cs.CRMClientGUID,
		Client_Stage = [Client_Stage]
	into #Client_Stage
	from [_loginom].[v_Collection_Client_Stage_lastDay] cs
	
	/*
	from (select CRMClientGUID
		,last_call_date  = max(call_date)
	from [_loginom].Collection_Client_Stage_history
	group by CRMClientGUID
	) [cs_last]
	inner join	[_loginom].Collection_Client_Stage_history cs
		on cs.CRMClientGUID = [cs_last].CRMClientGUID
		and cs.call_date = cs_last.last_call_date
	*/
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #Client_Stage', @row_count, cast(getdate() - @StartDate as time(2)) as duration
	END
	create clustered index cix on #Client_Stage(CRMClientGUID)

	SELECT @StartDate = getdate(), @row_count = 0
	
	


	DROP TABLE IF EXISTS #t_hasRejection
		CREATE TABLE #t_hasRejection([МобильныйТелефон] [nvarchar] (16) NULL)
	
		INSERT #t_hasRejection(МобильныйТелефон)
		SELECT DISTINCT
			--CRM_Requests_any.Номер,
			МобильныйТелефон = trim(right(replace(replace(replace(trim(CRM_Requests_any.МобильныйТелефон),')',''),'(',''),'-',''),10))
		from _1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS CRM_Requests_any
			where CRM_Requests_any.ПометкаУдаления = 0x00
			and exists(select top(1) 1 from _1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС AS s
			INNER JOIN _1cCRM.[Справочник_СтатусыЗаявокПодЗалогПТС] AS st
				ON st.Ссылка=s.Статус 
				AND st.Наименование = 'Отказано'
				where s.Заявка = CRM_Requests_any.Ссылка
				AND s.Период >= dateadd(year, 2000, dateadd(dd, -3, cast(getdate() as date)))
				)
	
			OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))
			SELECT @row_count = @@ROWCOUNT
		IF @isDebug = 1 BEGIN
			SELECT 'INSERT #t_hasRejection', @row_count, cast(getdate() - @StartDate as time(2)) as duration
		END
		CREATE CLUSTERED INDEX ix1 ON #t_hasRejection(МобильныйТелефон)


		SELECT @StartDate = getdate(), @row_count = 0
		DROP TABLE IF EXISTS #t_hasContract
		CREATE TABLE #t_hasContract([МобильныйТелефон] [nvarchar] (16) NULL)

		INSERT #t_hasContract(МобильныйТелефон)
		SELECT DISTINCT
			--Договоры.Код 
			МобильныйТелефон = trim(right(replace(replace(replace(trim(CRM_Requests_any.МобильныйТелефон),')',''),'(',''),'-',''),10))
		from _1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS CRM_Requests_any
		where  exists(select top(1) 1 from _1cCMR.Справочник_Договоры AS Договоры 
				where Договоры.Код = CRM_Requests_any.Номер
				AND Договоры.ПометкаУдаления = 0x00
				)
		and CRM_Requests_any.ПометкаУдаления = 0x00
		SELECT @row_count = @@ROWCOUNT
		CREATE CLUSTERED INDEX ix1 ON #t_hasContract(МобильныйТелефон)
		IF @isDebug = 1 BEGIN
			SELECT 'INSERT #t_hasContract', @row_count, cast(getdate() - @StartDate as time(2)) as duration
		END
	



		SELECT @StartDate = getdate(), @row_count = 0
	
		drop table if exists #crm_fillType
		create table #crm_fillType(
			dt datetime,
			Заявка binary(16),
			RequestType nvarchar(255),
			GUIDЗаявка nvarchar(36)
			)
		insert into #crm_fillType(dt,Заявка, RequestType, GUIDЗаявка)
		select  dt=dateadd(year,-2000,dt),
			v.Заявка, 
			RequestType = 
			CASE
				WHEN spr.Наименование = 'Заполняется в личном кабинете клиента' then 'LKK'
				WHEN spr.Наименование = 'Заполняется в мобильном приложении' then 'Mobile'
				WHEN spr.Наименование = 'Заполняется партнером' then 'Partner'
				ELSE 'Unknown'
			END,
			dbo.getGUIDFrom1C_IDRREF(v.Заявка)
		FROM _1cCrm.[РегистрСведений_ИзмененияВидаЗаполненияВЗаявках] AS v
			inner join (
				select v.Заявка, dt = max(v.[ДатаИзменения]) 
					from _1cCrm.[РегистрСведений_ИзмененияВидаЗаполненияВЗаявках] v
				where not exists(
					select top(1) 1 from _1cCrm.[Справочник_СтатусыЗаявокПодЗалогПТС] st
					where st.ссылка=v.Статус
					and st.Наименование 
					in ('Аннулировано',
					'Заем аннулирован',
					'Заем выдан',
					'Заем погашен',
					'Оценка качества',
					'Платеж опаздывает',
					'Проблемный','Просрочен','ТС продано')
				)
				group by v.Заявка
			) v0 ON v.заявка=v0.заявка and v.[ДатаИзменения]=v0.dt
			INNER JOIN _1cCrm.[Справочник_ВидыЗаполненияЗаявокНаЗаймПодПТС] spr on spr.ссылка=v.видЗаполнения
		--WHERE r.Номер<>''
		SELECT @row_count = @@ROWCOUNT
		create clustered index cix on #crm_fillType([GUIDЗаявка])

	--	CREATE NONCLUSTERED INDEX [GUIDЗаявка] ON [#crm_fillType] ([GUIDЗаявка])
			


		IF @isDebug = 1 BEGIN
			SELECT 'INSERT #crm_fillType', @row_count, cast(getdate() - @StartDate as time(2)) as duration
		END
	

	    /*
	 drop table if exists #CmrStatuses
 
	SELECT @StartDate = getdate(), @row_count = 0

	 ;
	
	 select sd.Договор 
		  , st.Наименование LastStatus
	   into #CmrStatuses
	   FROM (
		 SELECT sd.Договор
			  ,Период = max(Период)
		  FROM [_1cCMR].[РегистрСведений_СтатусыДоговоров]     sd
		  group by sd.Договор 
	   ) last_status 
	   inner join [_1cCMR].[РегистрСведений_СтатусыДоговоров]    sd
		on last_status.Договор    = sd.Договор 
		and last_status.Период  = sd.Период
    
	   inner join [_1cCMR].[Справочник_СтатусыДоговоров]          st on st.Ссылка  = sd.Статус
   
	 --  select distinct LastStatus  from #CmrStatuses
	  SELECT @row_count = @@ROWCOUNT
	 IF @isDebug = 1 BEGIN
		SELECT 'INSERT #CmrStatuses', @row_count, cast(getdate() - @StartDate as time(2)) as duration
	END
		*/
	drop table if exists #il 

	SELECT @StartDate = getdate(), @row_count = 0

	  select distinct Deal.Number  external_id into #il
		from _Collection.Deals AS Deal   JOIN
			 _Collection.customers AS c ON c.Id = Deal.IdCustomer   JOIN
			 _Collection.JudicialProceeding AS jp ON Deal.Id = jp.DealId   JOIN
			 _Collection.JudicialClaims AS jc ON jp.Id = jc.JudicialProceedingId   JOIN
			 _Collection.EnforcementOrders AS eo ON jc.Id = eo.JudicialClaimId   JOIN
			 _Collection.EnforcementProceeding AS ep ON eo.Id = ep.EnforcementOrderId   JOIN
			 _Collection.EnforcementProceedingMonitoring AS monitoring ON ep.Id = monitoring.EnforcementProceedingId 
		 
	   where ep.EndDate is  null

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #il', @row_count, cast(getdate() - @StartDate as time(2)) as duration
	END


	   --DWH-1343
	 drop table if exists #t_Claimants

	SELECT @StartDate = getdate(), @row_count = 0

	;with cte_Claimants as(select 
	nRow = ROW_NUMBER() Over(partition by external_id, ClaimantId order by getdate()), *
	from (
	select distinct Deal.Number  external_id, 
	c.ClaimantId,
	ClaimantFio = CONCAT(e.LastName,  ' ', e.FirstName, ' ', e.MiddleName),
	ClaimantCorporatePhone = Trim(p.Phone)
		from _Collection.Deals AS Deal   JOIN
			 _Collection.customers AS c ON c.Id = Deal.IdCustomer join 
			 _Collection.Employee e on e.id = c.ClaimantId
			 outer apply 
			(
				select Phone =Replace(
					iif(CHARINDEX('8', TRIM(value))=1, RIGHT(TRIM(value),10), TRIM(value))
					, '+7', '')
				from STRING_SPLIT(CorporatePhone, ',')   
			) p
		where nullif(CorporatePhone, '') <> ''
	
		) t
	)
	select * 

	into #t_Claimants
	from cte_Claimants
	where nRow = 1
 
	 SELECT @row_count = @@ROWCOUNT
 		 
	CREATE CLUSTERED INDEX ix1 ON #t_Claimants(external_id)
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #t_Claimants', @row_count, cast(getdate() - @StartDate as time(2)) as duration
	END
	



	SELECT @StartDate = getdate(), @row_count = 0
	  if object_id('tempdb.dbo.#rs') is not null drop table #rs
	  ;with m as (select max(ДатаДобавления) max_dd,rs.договор  
		from _1cMFO.[РегистрСведений_ГП_СтадииКоллектинга] rs   
			where ДатаДобавления<= dateadd(year,2000,cast(getdate() as date)) group by rs.договор
			) 


	  select d.номер external_id,sc.Имя CollectionStage
	  into #rs
	   from m join  _1cMFO.[РегистрСведений_ГП_СтадииКоллектинга]  rs on rs.договор=m.договор and rs.ДатаДобавления=m.max_dd
		 left join _1cMFO.[Перечисление_ГП_СтадииКоллектинга] sc on sc.ссылка=rs. Стадия
     
		   join _1cMFO.Документ_ГП_Договор d on d.ссылка=     rs.договор    

		--   select distinct CollectionStage  from #rs
	SELECT @row_count = @@ROWCOUNT
	CREATE CLUSTERED INDEX ix1 ON #rs(external_id)
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #rs', @row_count, cast(getdate() - @StartDate as time(2)) as duration
	END
	SELECT @StartDate = getdate(), @row_count = 0
	drop table if exists #t_CRM_Requests
	select 
		CRMClientGUID = dbo.getGUIDFrom1C_IDRREF(CRM_Requests.Партнер)
	    ,CRMRequestsGUID =  dbo.getGUIDFrom1C_IDRREF(CRM_Requests.Ссылка)
		,МобильныйТелефон  = trim(right(replace(replace(replace(trim(CRM_Requests.МобильныйТелефон),')',''),'(',''),'-',''),10))
		,Ссылка = CRM_Requests.Ссылка
		,Номер =  CRM_Requests.Номер
		,FIO = cast(concat(left(CRM_Requests.Фамилия,50),' ',left(CRM_Requests.Имя,50),' ',left(CRM_Requests.Отчество,50) ) as nvarchar(150))
		,isActive = iif(st.Наименование not in 
					( 'Аннулировано'
					,'Заем аннулирован'
					,'Заем выдан'
					,'Заем погашен'
					,'Оценка качества'
					,'Платеж опаздывает'
					,'Проблемный'
					,'Просрочен'
					,'ТС продано'
					,'Отказано'
					,'Забраковано' --BP-2816
					,'Действует' -- BP-2809
			
					), 1, 0)
		 ,RequestsLastStatus = st.Наименование
		 ,[isCmclient]				= case when st.Наименование in ('Договор подписан',
						'Заем выдан',
						'Заем погашен',
						'Контроль получения ДС',
						'Платеж опаздывает',
						'Проблемный',
						'Просрочен')
									then 1 
									else 0
							   end
			,CRMRequestDate  = dateadd(year,-2000, CRM_Requests.Дата)
			,requestLastStatusCode = st.КодСтатуса
			,CRM_Requests_ВерсияДанных = CRM_Requests.ВерсияДанных
		into #t_CRM_Requests
		from		_1cCRM.Документ_ЗаявкаНаЗаймПодПТС CRM_Requests --WITH(INDEX=ix_Номер)
		INNER join _1cCRM.[Справочник_СтатусыЗаявокПодЗалогПТС] st 
			on st.Ссылка=CRM_Requests.Статус 
		where (exists(select top(1) 1 from _1cCMR.Справочник_Договоры [Contract]
			where [Contract].Код = CRM_Requests.Номер
			and [Contract].ВерсияДанных>= @CMRContract_RowVersion
			)	  
			or CRM_Requests.ВерсияДанных>=@CRMRequest_RowVersion
			or dbo.getGUIDFrom1C_IDRREF(CRM_Requests.Партнер) = @CRMClientGUID
			)
		SELECT @row_count = @@ROWCOUNT
		CREATE CLUSTERED INDEX #t_CRM_Requests ON #t_CRM_Requests(Номер)
		IF @isDebug = 1 BEGIN
			SELECT 'INSERT #t_CRM_Requests', @row_count, cast(getdate() - @StartDate as time(2)) as duration
		END



	SELECT @StartDate = getdate(), @row_count = 0
	drop table if exists  #t_ClaimantStage

	 select external_id = Deal.Number
		,ClaimantStage = cs.Name
	into #t_ClaimantStage
	 from _Collection.Deals AS Deal   JOIN
			 _Collection.customers AS c ON c.Id = Deal.IdCustomer join 
			 _Collection.CollectingStage cs on cs.Id =  c.IdClaimantStage

			 SELECT @row_count = @@ROWCOUNT
			 CREATE CLUSTERED INDEX ix1 ON  #t_ClaimantStage(external_id)

	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #t_ClaimantStage', @row_count, cast(getdate() - @StartDate as time(2)) as duration
	END
	
	SELECT @StartDate = getdate(), @row_count = 0
	drop table if exists #t_Contract
	select 
		  [Caller]					= '8'+trim(right(coalesce(Tel.НомерТелефонаБезКодов, CRM_Requests.МобильныйТелефон),10))
		, МобильныйТелефон			= trim(right(coalesce(Tel.НомерТелефонаБезКодов, CRM_Requests.МобильныйТелефон),10))
		, [Cmclient]				= CRM_Requests.[isCmclient]
		, [CRMClientGUID]			= CRM_Requests.CRMClientGUID
		, [Dpd]						= a.КоличествоПолныхДнейПросрочкиУМФО
		, [Legal]					= case when r.CollectionStage='Legal' then 1 else 0 end
		, [ExecutionOrder]			= case when il.external_id is not null then 1 else 0 end
		, [ProblemClient]			= null
		, [CRMRequestGUID]			= CRM_Requests.CRMRequestsGUID
		, [CRMRequestID]			= CRM_Requests.Номер
		, [fio]						= CRM_Requests.FIO
		, [ClientStage]				= LoginomCS.Client_Stage
		, [RequestType]				= isnull(ft.RequestType, 'Unknown')
								  
		, [CRMRequestDate]			= CRM_Requests.CRMRequestDate
		, isActive					= CRM_Requests.isActive
		, [ClaimantFio]				= c.ClaimantFio
		, [ClaimantCorporatePhone]	= c.ClaimantCorporatePhone
		, [hasContract]				= iif(t_hasContract.МобильныйТелефон is not null, 1, 0)
		, [hasRejection]			= iif(t_hasRejection.МобильныйТелефон is not null, 1, 0)
		, [CRMRequestsLastStatus]	= CRM_Requests.RequestsLastStatus
		, [ClaimantStage]			= cs.ClaimantStage
		, [Type]					= 'CMR_contract'
		, [IVRDate]					= getdate()
		, [created]					= getdate()
		, [updated]					= getdate()
		, [isHistory]				= 0
		, CMRContract_RowVersion	= [Contract].ВерсияДанных
		, CMRContractGuid			= cast(dbo.getGUIDFrom1C_IDRREF([Contract].ссылка)  as nvarchar(64))
		--DWH-2105
		, productType				= ТипыПродуктов.ИдентификаторMDS
		--DWH-525
		,requestLastStatusCode		= CRM_Requests.requestLastStatusCode
		,CRMRequest_RowVersion		= CRM_Requests.CRM_Requests_ВерсияДанных
		into #t_Contract
	from _1cCMR.Справочник_Договоры [Contract]
		inner join #t_CRM_Requests  CRM_Requests
			on CRM_Requests.Номер = [Contract].Код
		inner join [_1cCMR].[Справочник_Заявка] cmr_Заявка
			on cmr_Заявка.Ссылка = [Contract].Заявка
		left join [_1cCMR].[Справочник_ТипыПродуктов] ТипыПродуктов
			on ТипыПродуктов.Ссылка  = cmr_Заявка.ТипПродукта
		--left join [_1cCMR].[Справочник_ПодтипыПродуктов] cmr_ПодтипыПродуктов
		--	on cmr_Заявка.ПодтипПродукта = cmr_ПодтипыПродуктов.ссылка	
		--DWH-2345
		
		
		LEFT JOIN dwh2.sat.Клиент_Телефон AS Tel
			ON Tel.GuidКлиент = CRM_Requests.CRMClientGUID
			AND Tel.nRow = 1

		left join #a a on a.external_id = [Contract].Код
		left join #t_ClaimantStage cs on cs.external_id  =[Contract].Код
		left join #t_Claimants c on c.external_id = [Contract].Код
		left join #Client_Stage LoginomCS 
			on LoginomCS.CRMClientGUID=CRM_Requests.CRMClientGUID
		left join #il il on il.external_id = [Contract].Код
		left join #rs r on r.external_id=[Contract].Код
		LEFT JOIN #crm_fillType ft ON ft.GUIDЗаявка= CRM_Requests.CRMClientGUID
		left join #t_hasRejection t_hasRejection on t_hasRejection.МобильныйТелефон 
			= coalesce(Tel.НомерТелефонаБезКодов, CRM_Requests.МобильныйТелефон)
		left join #t_hasContract t_hasContract on t_hasContract.МобильныйТелефон 
			= coalesce(Tel.НомерТелефонаБезКодов, CRM_Requests.МобильныйТелефон)
		LEFT JOIN _1cCMR.Справочник_Заявка AS Request
			ON [Contract].Заявка = Request.Ссылка
		

	where ([Contract].ВерсияДанных>= @CMRContract_RowVersion
		 or  CRM_Requests.CRMClientGUID = @CRMClientGUID
			or CRM_Requests.CRM_Requests_ВерсияДанных >=@CRMRequest_RowVersion
		)


 SELECT @row_count = @@ROWCOUNT

	;with cte_dublicate as
		(
			select nRow = ROW_NUMBER() over(partition by Caller, CRMRequestGUID order by isnull(dpd,0) desc, 
			isActive desc,
				CRMRequestDate desc),
			cnt = count(1)  over(partition by Caller)
			, *
				from #t_Contract
			
		)	
	delete from cte_dublicate
	where nRow > 1
	
	IF @isDebug = 1 BEGIN
		SELECT 'delete dublicate', @row_count, cast(getdate() - @StartDate as time(2)) as duration
	END
	begin tran

		merge [ivr].IVR_Data_CMR_contract_stage t
		using #t_Contract s
			on t.Caller = s.Caller
			and t.CRMRequestGUID = s.CRMRequestGUID
		when not matched then insert (
			  [Caller]
			, МобильныйТелефон
			, [Cmclient]
			, [CRMClientGUID] 
			, [CRMRequestGUID]
			, [CRMRequestID]
			, [fio]
			, Dpd
			, [RequestType]
			, [CRMRequestDate]
			, [isActive]
			, [hasContract]
			, [hasRejection]
			
			, [CRMRequestsLastStatus]
			, CMRContract_RowVersion
			, Legal
			, ExecutionOrder
			, [ClientStage]
			, ClaimantFio
			, ClaimantCorporatePhone
			, ClaimantStage
			, [Type]
			, [IVRDate] 
			, [created] 
			, [updated]
			, [isHistory]
			, CMRContractGuid
			, productType
			, requestLastStatusCode
			,CRMRequest_RowVersion
		)
		values(
			  s.[Caller]
			, s.МобильныйТелефон
			, s.[Cmclient]
			, s.[CRMClientGUID]
			, s.[CRMRequestGUID]
			, s.[CRMRequestID]
			, s.[fio]
			, s.Dpd
			, s.[RequestType]
			, s.[CRMRequestDate]
			, s.[isActive]
			, s.[hasContract] 
			, s.[hasRejection]
			, s.[CRMRequestsLastStatus]
			, s.CMRContract_RowVersion
			, s.Legal
			, s.ExecutionOrder
			, s.[ClientStage]
			, s.ClaimantFio
			, s.ClaimantCorporatePhone
			, s.ClaimantStage
			, s.[Type]
			, s.[IVRDate] 
			, s.[created] 
			, s.[updated]
			, s.[isHistory]
			, s.CMRContractGuid
			, s.productType
			, requestLastStatusCode
			, CRMRequest_RowVersion 
		)
		when matched 
			
			then update set
			 [Caller]				= s.[Caller]
			,[fio]					= s.[fio]
			,[RequestType]			= s.[RequestType]
			,[CRMRequestDate]		= s.[CRMRequestDate]
			,[CRMClientGUID]		= s.[CRMClientGUID]
			,CRMRequestID			= s.CRMRequestID
			,[isActive]				= s.[isActive]
			,[hasContract]			= s.[hasContract] 
			,[hasRejection]			= s.[hasRejection]
			,[CRMRequestsLastStatus] = s.[CRMRequestsLastStatus] 
			,CMRContract_RowVersion = s.CMRContract_RowVersion
			,МобильныйТелефон		= s.МобильныйТелефон
			,[updated]				= s.updated
			,CMRContractGuid		= s.CMRContractGuid
			,dpd					= s.dpd
			,productType			= s.productType
			,requestLastStatusCode  = s.requestLastStatusCode
			,CRMRequest_RowVersion  = s.CRMRequest_RowVersion 
			;
		SELECT @row_count += @@ROWCOUNT

		--Обновление статуса
		update t
			set t.requestLastStatusCode = isnull(t_Requests.requestLastStatusCode 	, t.requestLastStatusCode)
			,t.CRMRequestsLastStatus	= isnull(t_Requests.RequestsLastStatus		, t.CRMRequestsLastStatus)
			,[updated] = getdate()
		from ivr.IVR_Data_CMR_contract_stage t with(rowlock)
		left join #t_CRM_Requests AS t_Requests
			ON t_Requests.CRMRequestsGUID = t.CRMRequestGUID
		where isnull(t.requestLastStatusCode,'') !=isnull(t_Requests.requestLastStatusCode, '')
		
		SELECT @row_count += @@ROWCOUNT

		IF @isDebug = 1 BEGIN
			SELECT 'Update requestLastStatusCode', cast(getdate() - @StartDate as time(2)) as duration
		END
		 SELECT @row_count += @@ROWCOUNT
		--Обновление hasRejection
		update t
			set t.[hasRejection] = IIF(t_hasRejection.МобильныйТелефон is not null, 1, 0)
			,[updated] = getdate()
		from ivr.IVR_Data_CMR_contract_stage t with(rowlock)
		LEFT join #t_hasRejection AS t_hasRejection
			ON t_hasRejection.МобильныйТелефон = trim(t.МобильныйТелефон)
		where t.[hasRejection] != IIF(t_hasRejection.МобильныйТелефон is not null, 1, 0)
		 SELECT @row_count += @@ROWCOUNT
		IF @isDebug = 1 BEGIN
			SELECT 'Update hasRejection',  cast(getdate() - @StartDate as time(2)) as duration
		END

		--Обновление 	hasContract			 
		update t
			set t.hasContract =IIF(t_hasContract.МобильныйТелефон is not null, 1, 0)
			,[updated] = getdate()
		from ivr.IVR_Data_CMR_contract_stage t with(rowlock)
		LEFT join #t_hasContract AS t_hasContract
			ON t_hasContract.МобильныйТелефон = trim(t.МобильныйТелефон)
		where t.hasContract ! =IIF(t_hasContract.МобильныйТелефон is not null, 1, 0)
		IF @isDebug = 1 BEGIN
			SELECT 'Update hasContract',  cast(getdate() - @StartDate as time(2)) as duration
		END
		
		SELECT @row_count += @@ROWCOUNT
		--Обновление КоличествоПолныхДнейПросрочкиУМФО
		update t
			set dpd = isnull(a.КоличествоПолныхДнейПросрочкиУМФО,0)
			,[updated] = getdate()
		from ivr.IVR_Data_CMR_contract_stage  t with(rowlock)
			inner join #a a on a.external_id = t.CRMRequestID
		where isnull(a.КоличествоПолныхДнейПросрочкиУМФО,0) != isnull(t.Dpd,0)
		IF @isDebug = 1 BEGIN
			SELECT 'Update dpd',  cast(getdate() - @StartDate as time(2)) as duration
		END
		SELECT @row_count += @@ROWCOUNT
		--Обновление ft.RequestType
		update t
			set RequestType =	case
				when ft.RequestType is null then isnull(t.RequestType,'Unknown')
				else ft.RequestType
				end
		from ivr.IVR_Data_CMR_contract_stage t with(rowlock)
		LEFT join #crm_fillType ft ON ft.GUIDЗаявка= t.CRMRequestGUID
	--		and t.RequestType !=ft.RequestType
		IF @isDebug = 1 BEGIN
			SELECT 'Update RequestType',  cast(getdate() - @StartDate as time(2)) as duration
		END	
		SELECT @row_count += @@ROWCOUNT
		--Обновление [ClaimantStage]
		update t
			set [ClaimantStage] = cs.ClaimantStage
			,[updated] = getdate()
		from ivr.IVR_Data_CMR_contract_stage t with(rowlock)
		LEFT join #t_ClaimantStage cs on cs.external_id  =t.CRMRequestID 
		IF @isDebug = 1 BEGIN
			SELECT 'Update RequestType',  cast(getdate() - @StartDate as time(2)) as duration
		END	

		
		SELECT @row_count += @@ROWCOUNT
		--Обновление [Claimant]
		update t
			set ClaimantFio= c.ClaimantFio
				,ClaimantCorporatePhone = c.ClaimantCorporatePhone
				,[updated] = getdate()
		from ivr.[IVR_Data_CMR_contract_stage] t with(rowlock)
		LEFT join #t_Claimants c on c.external_id = t.CRMRequestID 

		IF @isDebug = 1 BEGIN
			SELECT 'Update ClaimantFio',  cast(getdate() - @StartDate as time(2)) as duration
		END	

		SELECT @row_count += @@ROWCOUNT

		update t
			set t.ClientStage = LoginomCS.Client_Stage
			,[updated] = getdate()
		from ivr.IVR_Data_CMR_contract_stage t with(rowlock)
		LEFT join #Client_Stage LoginomCS 
			on LoginomCS.CRMClientGUID=t.CRMClientGUID
		--where isnull(t.ClientStage,'') != LoginomCS.Client_Stage
		IF @isDebug = 1 BEGIN
			SELECT 'Update ClientStage',  cast(getdate() - @StartDate as time(2)) as duration
		END	

		--update 
		SELECT @row_count += @@ROWCOUNT
			update t
				set t.[ExecutionOrder] = IIF(il.external_id is not null, 1, 0)
				,[updated] = getdate()
			from ivr.IVR_Data_CMR_contract_stage t with(rowlock)
				LEFT join #il il on il.external_id = t.CRMRequestID 
			--where t.[ExecutionOrder] != IIF(il.external_id is not null, 1, 0)
		SELECT @row_count += @@ROWCOUNT
		IF @isDebug = 1 BEGIN
			SELECT 'Update ExecutionOrder',  cast(getdate() - @StartDate as time(2)) as duration
		END	
		--update [Legal]
	
		update t
			set  t.[Legal]	= case when r.CollectionStage='Legal' then 1 else 0 end
			,[updated] = getdate()
			from ivr.IVR_Data_CMR_contract_stage t with(rowlock)
			left join #rs r on r.external_id=t.CRMRequestID 
			--where isnull(t.[Legal], '') != case when r.CollectionStage='Legal' then 1 else 0 end
		SELECT @row_count += @@ROWCOUNT
		IF @isDebug = 1 BEGIN
			SELECT 'INSERT #t_Contract', @row_count, cast(getdate() - @StartDate as time(2)) as duration
		END

		
	
	commit tran	

	
	if exists(select top(1) 1 from ivr.IVR_Data_CMR_contract_stage
		where  $partition.[pfn_range_right_Type_part_IVR_Data](type) = @partitionId)
		begin
			begin tran			
				truncate table ivr.IVR_Data   WITH (PARTITIONS(@partitionId))
				alter table ivr.IVR_Data_CMR_contract_stage 
					SWITCH PARTITION @partitionId TO ivr.IVR_Data    PARTITION @partitionId
					WITH (WAIT_AT_LOW_PRIORITY ( MAX_DURATION = 1,
					ABORT_AFTER_WAIT = BLOCKERS))
			commit tran
		end
		else
		begin
			declare @error_msg  nvarchar(255) = concat_ws(' ', 'not exists data in IVR_Data_CMR_contract_stage for partition:', @partitionId)
			;throw 51000, @error_msg, 16
		end
	
end try
begin catch
	if @@TRANCOUNT>1
		rollback tran;
	;throw
end catch
end
