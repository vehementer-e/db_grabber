--select * from dbo.IVR
--where IVRDate = cast(getdate() as date)	
	
--truncate table ivr.IVR_Data

--	select * from ivr.IVR_Data
	--[ivr].[fill_CRMRequest] @reLoadAll = 1
		
-- Usage: запуск процедуры с параметрами
-- EXEC [ivr].[fill_CRMRequest] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROC [ivr].[fill_CRMRequest]
	@isDebug bit  = 0,
	@reLoadAll bit = 0 
as
begin
SET XACT_ABORT ON
begin try
	declare @CRMRequest_RowVersion binary(8) = 
	iif(@reLoadAll = 0 ,	
	isnull((select max([CRMRequest_RowVersion]) from [ivr].[IVR_Data]	with(nolock)
		where [Type] = 'CRM_Requests'), 0)
	,0x0)
	DECLARE @StartDate datetime, @row_count int
	SELECT @StartDate = getdate(), @row_count = 0

	DROP TABLE IF EXISTS #t_hasRejection
	CREATE TABLE #t_hasRejection([МобильныйТелефон] [nvarchar] (16) NULL)
	--SELECT @StartDate = getdate(), @row_count = 0
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
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #t_hasContract', @row_count, cast(getdate() - @StartDate as time(2)) as duration
	END
	CREATE CLUSTERED INDEX ix1 ON #t_hasContract(МобильныйТелефон)
	
	SELECT @StartDate = getdate(), @row_count = 0
	
	declare @lastRequstDate date= isnull(
		dateadd(dd,-1, (select max(CRMRequestDate) from ivr.IVR_Data with(nolock))), '2000-01-01')
		
	
	drop table if exists #crm_fillType
	create table #crm_fillType(
		dt datetime,
		Заявка binary(16),
		заявка_guid  nvarchar(36),
		RequestType nvarchar(255)
		)
	insert into #crm_fillType(dt,Заявка, заявка_guid,  RequestType)
	select  dt=dateadd(year,-2000,dt),
		v.Заявка, 
		заявка_guid = cast(dbo.getGUIDFrom1C_IDRREF(v.Заявка)  as nvarchar(36)),
		RequestType = 
		CASE
			WHEN spr.Наименование = 'Заполняется в личном кабинете клиента' then 'LKK'
			WHEN spr.Наименование = 'Заполняется в мобильном приложении' then 'Mobile'
			WHEN spr.Наименование = 'Заполняется партнером' then 'Partner'
			ELSE 'Unknown'
		END
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
			and [ДатаИзменения] >=@lastRequstDate
			group by v.Заявка
		) v0 ON v.заявка=v0.заявка 
			and v.[ДатаИзменения]=v0.dt
		INNER JOIN _1cCrm.[Справочник_ВидыЗаполненияЗаявокНаЗаймПодПТС] spr on spr.ссылка=v.видЗаполнения
		
	--WHERE r.Номер<>''
	SELECT @row_count = @@ROWCOUNT
	create clustered index ix on #crm_fillType(Заявка, заявка_guid)
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #crm_fillType', @row_count, cast(getdate() - @StartDate as time(2)) as duration
	END
	

	DROP TABLE IF EXISTS #t_ВерификацияКЦ
	SELECT DISTINCT	R.Ссылка
	INTO #t_ВерификацияКЦ
	FROM _1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS R
		INNER JOIN _1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС AS H
			ON H.Заявка = R.Ссылка
		INNER JOIN _1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС AS ST 
			on ST.Ссылка = H.Статус
			AND ST.Наименование IN ('Верификация КЦ')
	WHERE 1=1
		AND R.ПометкаУдаления = 0x00
		AND R.ВерсияДанных >= @CRMRequest_RowVersion

	DROP TABLE IF EXISTS #t_Забраковано
	SELECT 
		R.Ссылка,
		status_date = min(cast(dateadd(YEAR, -2000, H.Период) AS date))
	INTO #t_Забраковано
	FROM _1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS R
		INNER JOIN _1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС AS H
			ON H.Заявка = R.Ссылка
		INNER JOIN _1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС AS ST 
			on ST.Ссылка = H.Статус
			AND ST.Наименование IN ('Забраковано')
	WHERE 1=1
		AND R.ПометкаУдаления = 0x00
		AND R.ВерсияДанных >= @CRMRequest_RowVersion
	GROUP BY R.Ссылка		




	SELECT @StartDate = getdate(), @row_count = 0

	DROP TABLE IF EXISTS #t_ЗаявкаНаЗаймПодПТС
	select DISTINCT
		CRMRequestGUID = cast(dbo.getGUIDFrom1C_IDRREF(CRM_Requests.Ссылка)  as nvarchar(64))
		,CRMRequestID   =  CRM_Requests.Номер
		,МобильныйТелефон = trim(right(replace(replace(replace(trim(CRM_Requests.МобильныйТелефон),')',''),'(',''),'-',''),10))
		,Caller='8'+ trim(right(replace(replace(replace(trim(CRM_Requests.МобильныйТелефон),')',''),'(',''),'-',''),10))
		,fio			= cast(concat(left(CRM_Requests.Фамилия,50),' ',left(CRM_Requests.Имя,50),' ',left(CRM_Requests.Отчество,50) ) as nvarchar(150))
	
		,Cmclient		= case when st.Наименование in ('Договор подписан',
					'Заем выдан',
					'Заем погашен',
					'Контроль получения ДС',
					'Платеж опаздывает',
					'Проблемный',
					'Просрочен')
								then 1 
								else 0
						   end
		, [CRMRequestDate] = dateadd(year,-2000, CRM_Requests.Дата)

		--, isActive = iif(st.Наименование not in 
		--		( 'Аннулировано'
		--		,'Заем аннулирован'
		--		,'Заем выдан'
		--		,'Заем погашен'
		--		,'Оценка качества'
		--		,'Платеж опаздывает'
		--		,'Проблемный'
		--		,'Просрочен'
		--		,'ТС продано'
		--		,'Отказано'
		--		,'Забраковано' --BP-2816
		--		,'Действует' -- BP-2809
		--		), 1, 0)

		, isActive = 
			CASE
				--DWH-1849
				--есть текущий статус Забраковано и он был установлен более 5 дней назад, 
				--а также в истории статусов не было "Верификация КЦ", ставим isActive = false
				WHEN st.Наименование = 'Забраковано' --текущий статус Забраковано
					AND datediff(DAY, br.status_date, cast(getdate() AS date)) > 5 --был установлен более 5 дней назад
					AND vk.Ссылка IS NULL --не было "Верификация КЦ"
				THEN 0
				WHEN st.Наименование NOT IN (
					'Аннулировано'
					,'Заем аннулирован'
					,'Заем выдан'
					,'Заем погашен'
					,'Оценка качества'
					,'Платеж опаздывает'
					,'Проблемный'
					,'Просрочен'
					,'ТС продано'
					,'Отказано'
					--,'Забраковано'
					,'Действует' -- BP-2809
					)
				THEN 1
				ELSE 0
			END

		, CRMRequest_RowVersion = CRM_Requests.ВерсияДанных
		, hasContract		= iif(t_hasContract.МобильныйТелефон is not null, 1, 0)
		, hasRejection		= iif(t_hasRejection.МобильныйТелефон is not null, 1, 0)
		, RequestType		= isnull(ft.RequestType, 'Unknown')
		, CRMRequestsLastStatus = st .Наименование
		, CRMClientGUID    = cast(dbo.getGUIDFrom1C_IDRREF(CRM_Requests.Партнер)  as nvarchar(64))
		, [Type] = 'CRM_Requests'
		, [IVRDate] = getdate()  
		, [created] = getdate() 
		, [updated] = getdate()
		, [isHistory] = 0
		, Legal = 0
		, ExecutionOrder = 0
		, productType = ТипыПродуктов.Код
		/*
			CASE 
				WHEN isnull(CRM_Requests.СмартИнстолмент, 0) = 1 THEN 'Смарт-инстоллмент'
				WHEN isnull(CRM_Requests.Инстолмент, 0) = 1 THEN 'Инстоллмент'
				WHEN isnull(CRM_Requests.ИспытательныйСрок, 0) = 1 THEN 'ПТС31'
				when isnull(CRM_Requests.ПДЛ,0) = 1 theN 'PDL'
				ELSE 'ПТС'
			END
			*/
	into #t_ЗаявкаНаЗаймПодПТС
	from _1cCRM.Документ_ЗаявкаНаЗаймПодПТС CRM_Requests --WITH(INDEX=ix_Номер)
		left join _1cCRM.[Справочник_СтатусыЗаявокПодЗалогПТС] st 
			on st.Ссылка=CRM_Requests.Статус 
		LEFT join [_1cCRM].[Справочник_тмТипыКредитногоПродукта] ТипыПродуктов
			on ТипыПродуктов.Ссылка = CRM_Requests.ТипКредитногоПродукта
		LEFT JOIN #t_hasRejection AS t_hasRejection
			ON t_hasRejection.МобильныйТелефон = trim(right(replace(replace(replace(trim(CRM_Requests.МобильныйТелефон),')',''),'(',''),'-',''),10))
		LEFT JOIN #t_hasContract AS t_hasContract
			ON t_hasContract.МобильныйТелефон = trim(right(replace(replace(replace(trim(CRM_Requests.МобильныйТелефон),')',''),'(',''),'-',''),10))
		LEFT JOIN #crm_fillType ft 
			ON ft.Заявка= CRM_Requests.Ссылка
		LEFT JOIN #t_Забраковано AS br
			ON br.Ссылка = CRM_Requests.Ссылка
		LEFT JOIN #t_ВерификацияКЦ AS vk
			ON vk.Ссылка = CRM_Requests.Ссылка
			
	where CRM_Requests.ПометкаУдаления = 0x00
		and CRM_Requests.ВерсияДанных >=@CRMRequest_RowVersion

	 --and (not exists(Select top(1) 1 from _1cCMR.Справочник_Договоры договор 
		--where договор.Код = CRM_Requests.Номер)
		--	or
		OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #t_Номер_ЗаявкаНаЗаймПодПТС', @row_count, cast(getdate() - @StartDate as time(2)) as duration 

		DROP TABLE IF EXISTS ##t_ЗаявкаНаЗаймПодПТС
		SELECT * INTO ##t_ЗаявкаНаЗаймПодПТС FROM #t_ЗаявкаНаЗаймПодПТС
	END
	delete from #t_ЗаявкаНаЗаймПодПТС
	where nullif(МобильныйТелефон,'') is null



	select @StartDate= getdate() , @row_count = 0
	;with cte_doubles as 
	(
		select  
			rn=row_number() over(partition by caller order by  
				isActive desc,  -- по Договорености с В. Данилов сначала отдаем активные заявки
				CRMRequestDate desc, 
				CRMRequestID desc) 
		
		,* from #t_ЗаявкаНаЗаймПодПТС
	)
	delete  from cte_doubles where rn>1
	set @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'delete doubles', @row_count, cast(getdate() - @StartDate as time(2)) as duration 
	END

	
	
	 begin tran
		 select @StartDate= getdate() , @row_count = 0
		merge [ivr].[IVR_Data] t
		using #t_ЗаявкаНаЗаймПодПТС s
			on t.[Caller] = s.[Caller]
			and t.[CRMRequestGUID] = s.[CRMRequestGUID]
			and  t.[Type] = 'CRM_Requests'
		when not matched then insert (
			  [Caller]
			, МобильныйТелефон
			, [Cmclient]
			, [CRMClientGUID] 
			, [CRMRequestGUID]
			, [CRMRequestID]
			, [fio]
			, [RequestType]
			, [CRMRequestDate]
			, [isActive]
			, [hasContract]
			, [hasRejection]
			, [CRMRequestsLastStatus]
			, [CRMRequest_RowVersion]
			, Legal
			, ExecutionOrder
			, [Type]
			, [IVRDate] 
			, [created] 
			, [updated]
			, [isHistory]
			, productType
		)
		values(
			  s.[Caller]
			, s.МобильныйТелефон
			, s.[Cmclient]
			, s.[CRMClientGUID]
			, s.[CRMRequestGUID]
			, s.[CRMRequestID]
			, s.[fio]
			, s.[RequestType]
			, s.[CRMRequestDate]
			, s.[isActive]
			, s.[hasContract] 
			, s.[hasRejection]
			, s.[CRMRequestsLastStatus]
			, s.[CRMRequest_RowVersion]
			, s.Legal
			, s.ExecutionOrder
			, s.[Type]
			, s.[IVRDate] 
			, s.[created] 
			, s.[updated]
			, s.[isHistory]
			, s.productType
		)
		when  matched  
			 and isnull(t.[CRMRequest_RowVersion], 0) != s.[CRMRequest_RowVersion]
				or isnull(t.[CRMClientGUID], cast(null as uniqueidentifier )) != isnull(s.[CRMClientGUID], cast(null as uniqueidentifier ))
				OR isnull(t.[CRMRequestGUID], cast(null as uniqueidentifier )) !=isnull(s.[CRMRequestGUID], cast(null as uniqueidentifier ))
			then update set
			[fio]					= s.[fio]
			,Cmclient				= s.Cmclient
			,[CRMRequestDate]		= s.[CRMRequestDate]
			,[CRMClientGUID]		= s.[CRMClientGUID]
			,CRMRequestGUID			= s.CRMRequestGUID
			,CRMRequestID			= s.CRMRequestID
			,[isActive]				= s.[isActive]
			,[CRMRequestsLastStatus] = s.[CRMRequestsLastStatus] 
			,[CRMRequest_RowVersion] = s.[CRMRequest_RowVersion]
			,МобильныйТелефон		 = s.МобильныйТелефон
			,[updated]				 = s.updated
			,productType			 = s.productType
			;
		SELECT @row_count += @@ROWCOUNT
		update t
			set t.[hasRejection] =iif(t_hasRejection.МобильныйТелефон is not null, 1, 0)
		from ivr.[IVR_Data] t
		LEFT join #t_hasRejection AS t_hasRejection
			ON t_hasRejection.МобильныйТелефон = trim(t.МобильныйТелефон)
		where t.[Type] = 'CRM_Requests'
			and isnull([hasRejection],0) != iif(t_hasRejection.МобильныйТелефон is not null, 1, 0)
		SELECT @row_count += @@ROWCOUNT
		update t
			set t.hasContract = iif(t_hasContract.МобильныйТелефон is not null, 1, 0)
		from ivr.[IVR_Data] t
		LEFT join #t_hasContract AS t_hasContract
			ON t_hasContract.МобильныйТелефон = trim(t.МобильныйТелефон)
		where t.[Type] = 'CRM_Requests'
			and  t.hasContract != iif(t_hasContract.МобильныйТелефон is not null, 1, 0)

		SELECT @row_count += @@ROWCOUNT
		update t
			set RequestType =	case
				when ft.RequestType is null then isnull(t.RequestType,'Unknown')
				else ft.RequestType
				end
		from ivr.[IVR_Data] t
		LEFT join #crm_fillType ft ON ft.заявка_guid= t.CRMRequestGUID
			and isnull(t.RequestType,'Unknown') !=isnull(ft.RequestType,'Unknown')
		where t.[Type] = 'CRM_Requests'
			
		

	SELECT @row_count += @@ROWCOUNT
	commit tran	
	
	IF @isDebug = 1 BEGIN
		SELECT 'merge [ivr].[IVR_Data]', @row_count, cast(getdate() - @StartDate as time(2)) as duration
	END
end try
begin catch
	if @@TRANCOUNT>1
		rollback tran;
	;throw
end catch
end
