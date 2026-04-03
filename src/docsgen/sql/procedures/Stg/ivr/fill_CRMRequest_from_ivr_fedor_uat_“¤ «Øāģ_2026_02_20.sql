--select * from dbo.IVR
--where IVRDate = cast(getdate() as date)	
	
--truncate table ivr.IVR_Data_uat

--select * from ivr.IVR_Data_uat
	

-- Usage: запуск процедуры с параметрами
-- EXEC ivr.fill_CRMRequest_from_ivr_fedor_uat
--      @t_fedor_request = <value>,
--      @isDebug = 0;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   PROC ivr.fill_CRMRequest_from_ivr_fedor_uat
	@t_fedor_request ivr.utt_ivr_fedor_request READONLY,
	@isDebug bit = 0
	--@reLoadAll bit = 0 
as
begin
SET XACT_ABORT ON
begin try
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @StartDate datetime, @row_count int
	--DECLARE @t_ivr_data ivr.utt_ivr_data
	DECLARE @IVR_Data_json_array nvarchar(max)

	SELECT @StartDate = getdate(), @row_count = 0

	DROP TABLE IF EXISTS #t_hasRejection
	CREATE TABLE #t_hasRejection([МобильныйТелефон] [nvarchar] (16) NULL)

	/*
	--OLD
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
	*/

	INSERT #t_hasRejection(МобильныйТелефон)
	SELECT DISTINCT
		МобильныйТелефон = R.mobilePhone
	FROM @t_fedor_request AS R
		INNER JOIN _1cCRM.Документ_ЗаявкаНаЗаймПодПТС AS CRM_Requests_any 
			with(nolock, index = ix_mobilePhone)
			--ON trim(right(replace(replace(replace(trim(CRM_Requests_any.МобильныйТелефон),')',''),'(',''),'-',''),10)) = R.mobilePhone
			ON CRM_Requests_any.mobilePhone = R.mobilePhone
	WHERE 1=1 -- CRM_Requests_any.ПометкаУдаления = 0x00
		AND EXISTS(
			SELECT top(1) 1 
			FROM _1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС AS s with(nolock)
				--INNER JOIN _1cCRM.[Справочник_СтатусыЗаявокПодЗалогПТС] AS st
				--	ON st.Ссылка=s.Статус 
				--	AND st.Наименование = 'Отказано'
			where 1=1
				AND s.Заявка = CRM_Requests_any.Ссылка
				AND s.Статус = 0xA81400155D94190011E80784923C609E --'Отказано'
				--AND s.Период >= dateadd(year, 2000, dateadd(dd, -3, cast(getdate() as date)))
		)
	--OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))

	SELECT @row_count = @@ROWCOUNT

	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #t_hasRejection', @row_count, cast(getdate() - @StartDate as time(2)) as duration
	END
	--CREATE CLUSTERED INDEX ix1 ON #t_hasRejection(МобильныйТелефон)


	SELECT @StartDate = getdate(), @row_count = 0

	DROP TABLE IF EXISTS #t_hasContract
	CREATE TABLE #t_hasContract([МобильныйТелефон] [nvarchar] (16) NULL)

	/*
	--OLD
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
	*/

	INSERT #t_hasContract(МобильныйТелефон)
	SELECT DISTINCT
		МобильныйТелефон = R.mobilePhone
	FROM @t_fedor_request AS R
		INNER JOIN _1cCRM.Документ_ЗаявкаНаЗаймПодПТС 
			AS CRM_Requests_any with(nolock, index = ix_mobilePhone)
			--ON trim(right(replace(replace(replace(trim(CRM_Requests_any.МобильныйТелефон),')',''),'(',''),'-',''),10)) = R.mobilePhone
			ON CRM_Requests_any.mobilePhone = R.mobilePhone
	WHERE EXISTS(
			SELECT top(1) 1 
			FROM _1cCMR.Справочник_Договоры AS Договоры  with(nolock)
			WHERE Договоры.Код = CRM_Requests_any.Номер
				AND Договоры.ПометкаУдаления = 0x00
		)
		AND CRM_Requests_any.ПометкаУдаления = 0x00

	SELECT @row_count = @@ROWCOUNT

	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #t_hasContract', @row_count, cast(getdate() - @StartDate as time(2)) as duration
	END
	--CREATE CLUSTERED INDEX ix1 ON #t_hasContract(МобильныйТелефон)


	SELECT @StartDate = getdate(), @row_count = 0
	
	--declare @lastRequstDate date= isnull(
	--	dateadd(dd,-1, (select max(CRMRequestDate) from ivr.IVR_Data_uat with(nolock))), '2000-01-01')
		
	drop table if exists #crm_fillType
	create table #crm_fillType(
		dt datetime,
		Заявка binary(16),
		заявка_guid  nvarchar(36),
		RequestType nvarchar(255)
		)

	/*
	--OLD
	insert into #crm_fillType(dt,Заявка, заявка_guid,  RequestType)
	select  dt=dateadd(year,-2000,dt),
		v.Заявка, 
		заявка_guid = cast(dbo.getGUIDFrom1C_IDRREF(v.Заявка)  as nvarchar(36)),
		RequestType = case when  spr.Наименование='Заполняется в мобильном приложении' then 'Mobile'
								   when  spr.Наименование='Заполняется партнером' then 'Partner'
								   else 'Unknown'
							  end
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
	*/
	
	/*
	--var 1
	insert into #crm_fillType(dt,Заявка, заявка_guid,  RequestType)
	select  
		dt=dateadd(year,-2000,dt),
		v.Заявка, 
		заявка_guid = cast(dbo.getGUIDFrom1C_IDRREF(v.Заявка)  as nvarchar(36)),
		RequestType = case when  spr.Наименование='Заполняется в мобильном приложении' then 'Mobile'
								   when  spr.Наименование='Заполняется партнером' then 'Partner'
								   else 'Unknown'
							  end
	FROM @t_fedor_request AS R
		inner join (
			select 
				v1.Заявка, 
				dt = max(v1.ДатаИзменения) 
			from @t_fedor_request AS R1
				INNER JOIN _1cCrm.РегистрСведений_ИзмененияВидаЗаполненияВЗаявках AS v1
					ON R1.requestBinaryID = v.Заявка
			where not exists(
				select top(1) 1 
				FROM _1cCrm.Справочник_СтатусыЗаявокПодЗалогПТС AS st
				where st.ссылка = v1.Статус
					AND st.Наименование in (
						'Аннулировано',
						'Заем аннулирован',
						'Заем выдан',
						'Заем погашен',
						'Оценка качества',
						'Платеж опаздывает',
						'Проблемный',
						'Просрочен',
						'ТС продано'
					)
				)
				--and [ДатаИзменения] >=@lastRequstDate
			group by v1.Заявка
			) AS v0 
			ON R.requestBinaryID = v0.заявка 
		INNER JOIN _1cCrm.РегистрСведений_ИзмененияВидаЗаполненияВЗаявках AS v
			ON v.заявка = v0.заявка 
			and v.ДатаИзменения = v0.dt
		INNER JOIN _1cCrm.Справочник_ВидыЗаполненияЗаявокНаЗаймПодПТС AS spr
			ON spr.ссылка = v.видЗаполнения
	*/

	--var 2
	insert into #crm_fillType(dt, Заявка, заявка_guid, RequestType)
	select
		--dt=dateadd(year,-2000,dt),
		dt = getdate(),
		Заявка = R.requestBinaryID, 
		заявка_guid = R.requestGuid,
		RequestType = 
			CASE spr.Наименование 
				WHEN 'Заполняется в мобильном приложении'		then 'Mobile'
				WHEN 'Заполняется партнером'					then 'Partner'
				when 'Заполняется в личном кабинете клиента'	then 'LKK'
				ELSE 'Unknown'
			END
	FROM @t_fedor_request AS R
		INNER JOIN _1cCrm.Справочник_ВидыЗаполненияЗаявокНаЗаймПодПТС AS spr
			ON spr.Ссылка = dbo.get1CIDRREF_FromGUID(R.fillView)

	SELECT @row_count = @@ROWCOUNT

	--create clustered index ix on #crm_fillType(Заявка, заявка_guid)

	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #crm_fillType', @row_count, cast(getdate() - @StartDate as time(2)) as duration
	END
	

	DROP TABLE IF EXISTS #t_ВерификацияКЦ
	SELECT DISTINCT	R.requestGuid
	INTO #t_ВерификацияКЦ
	FROM @t_fedor_request AS R
		INNER JOIN _1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС AS H
			ON H.Заявка = dbo.get1CIDRREF_FromGUID(R.requestGuid)
		INNER JOIN _1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС AS ST 
			on ST.Ссылка = H.Статус
			AND ST.Наименование IN ('Верификация КЦ')

	DROP TABLE IF EXISTS #t_Забраковано
	SELECT 
		R.requestGuid,
		status_date = min(cast(dateadd(YEAR, -2000, H.Период) AS date))
	INTO #t_Забраковано
	FROM @t_fedor_request AS R
		INNER JOIN _1cCRM.РегистрСведений_СтатусыЗаявокНаЗаймПодПТС AS H
			ON H.Заявка = dbo.get1CIDRREF_FromGUID(R.requestGuid)
		INNER JOIN _1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС AS ST 
			on ST.Ссылка = H.Статус
			AND ST.Наименование IN ('Забраковано')
	GROUP BY R.requestGuid

	SELECT @StartDate = getdate(), @row_count = 0

	DROP TABLE IF EXISTS #t_ЗаявкаНаЗаймПодПТС

	/*
	--OLD
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
		, isActive = iif(st.Наименование not in 
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

		,isInstallment =
				iif(CRM_Requests.Инстолмент =0x01
					and st.Наименование in ('Черновик',
						'Верификация КЦ',
						'Предварительное одобрение',
						'Заполнение полной анкеты',
						'Загрузка фото в МП',
						'Прикрепление карты',
						'Контроль данных',
						'Верификация документов клиента',
						'Одобрено',
						'Выбор предложения',
						'Контроль подписания договора',
						'Договор зарегистрирован',
						'Договор подписан',
						'Контроль получения ДС')
						, 1 
					,0)
		,isSmartInstallment =
		iif(CRM_Requests.СмартИнстолмент =0x01
			and st.Наименование in ('Черновик',
				'Верификация КЦ',
				'Предварительное одобрение',
				'Заполнение полной анкеты',
				'Загрузка фото в МП',
				'Прикрепление карты',
				'Контроль данных',
				'Верификация документов клиента',
				'Одобрено',
				'Выбор предложения',
				'Контроль подписания договора',
				'Договор зарегистрирован',
				'Договор подписан',
				'Контроль получения ДС')
				, 1 
			,0)
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
		, productType = 
			CASE 
				WHEN isnull(CRM_Requests.СмартИнстолмент, 0) = 1 THEN 'Смарт-инстоллмент'
				WHEN isnull(CRM_Requests.Инстолмент, 0) = 1 THEN 'Инстоллмент'
				WHEN isnull(CRM_Requests.ИспытательныйСрок, 0) = 1 THEN 'ПТС31'
				when isnull(CRM_Requests.ПДЛ,0) = 1 theN 'PDL'
				ELSE 'ПТС'
			END

	into #t_ЗаявкаНаЗаймПодПТС
	from _1cCRM.Документ_ЗаявкаНаЗаймПодПТС CRM_Requests --WITH(INDEX=ix_Номер)
		left join _1cCRM.[Справочник_СтатусыЗаявокПодЗалогПТС] st 
				on st.Ссылка=CRM_Requests.Статус 

		LEFT JOIN #t_hasRejection AS t_hasRejection
			ON t_hasRejection.МобильныйТелефон = trim(right(replace(replace(replace(trim(CRM_Requests.МобильныйТелефон),')',''),'(',''),'-',''),10))
		LEFT JOIN #t_hasContract AS t_hasContract
			ON t_hasContract.МобильныйТелефон = trim(right(replace(replace(replace(trim(CRM_Requests.МобильныйТелефон),')',''),'(',''),'-',''),10))
		LEFT JOIN #crm_fillType ft 
			ON ft.Заявка= CRM_Requests.Ссылка
	where CRM_Requests.ПометкаУдаления = 0x00
		and CRM_Requests.ВерсияДанных >=@CRMRequest_RowVersion

	 --and (not exists(Select top(1) 1 from _1cCMR.Справочник_Договоры договор 
		--where договор.Код = CRM_Requests.Номер)
		--	or
		OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))
	*/

	SELECT DISTINCT
		requestTime = dateadd(HOUR, 3, dateadd(SECOND, R.publishTime, convert(datetime, '1970-01-01 00:00:00', 120)))
		,CRMRequestGUID = lower(R.requestGuid)
		,CRMRequestID = R.requestNumber
		,МобильныйТелефон = R.mobilePhone
		,Caller = '8' +  R.mobilePhone
		,fio = cast(concat(left(R.lastName,50),' ',left(R.firstName,50),' ',left(R.secondName,50)) as nvarchar(150))
		,Cmclient =
		CASE 
			WHEN st.Наименование in (
				'Договор подписан',
				'Заем выдан',
				'Заем погашен',
				'Контроль получения ДС',
				'Платеж опаздывает',
				'Проблемный',
				'Просрочен'
			)
			THEN 1 
			ELSE 0
		END
		, CRMRequestDate = R.requestDate
		--, isActive = 
		--	iif(st.Наименование not in (
		--		'Аннулировано'
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
		--	), 1, 0
		--	)

		, isActive = 
			CASE
				--DWH-1849
				--есть текущий статус Забраковано и он был установлен более 5 дней назад, 
				--а также в истории статусов не было "Верификация КЦ", ставим isActive = false
				WHEN st.Наименование = 'Забраковано' --текущий статус Забраковано
					AND datediff(DAY, br.status_date, cast(getdate() AS date)) > 5 --был установлен более 5 дней назад
					AND vk.requestGuid IS NULL --не было "Верификация КЦ"
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

		,isInstallment = isnull(
			iif(R.isInstallment = 1
				and st.Наименование in (
					'Черновик',
					'Верификация КЦ',
					'Предварительное одобрение',
					'Заполнение полной анкеты',
					'Загрузка фото в МП',
					'Прикрепление карты',
					'Контроль данных',
					'Верификация документов клиента',
					'Одобрено',
					'Выбор предложения',
					'Контроль подписания договора',
					'Договор зарегистрирован',
					'Договор подписан',
					'Контроль получения ДС'
				), 1, 0
			), 0) 
		,isSmartInstallment = isnull(
			iif(R.isSmartInstallment = 1
				AND st.Наименование in (
					'Черновик',
					'Верификация КЦ',
					'Предварительное одобрение',
					'Заполнение полной анкеты',
					'Загрузка фото в МП',
					'Прикрепление карты',
					'Контроль данных',
					'Верификация документов клиента',
					'Одобрено',
					'Выбор предложения',
					'Контроль подписания договора',
					'Договор зарегистрирован',
					'Договор подписан',
					'Контроль получения ДС'
				), 1,0
			), 0) 
		, CRMRequest_RowVersion = NULL --CRM_Requests.ВерсияДанных
		, hasContract = isnull(iif(t_hasContract.МобильныйТелефон is not null, 1, 0), 0)
		, hasRejection = isnull(iif(t_hasRejection.МобильныйТелефон is not null, 1, 0), 0)
		, RequestType = isnull(ft.RequestType, 'Unknown')
		, CRMRequestsLastStatus = st.Наименование
		, CRMClientGUID = lower(R.clientGUID)
		, [Type] = 'CRM_Requests'
		, IVRDate = getdate()  
		, created = getdate() 
		, updated = getdate()
		, isHistory = 0
		, Legal = 0
		, ExecutionOrder = 0

		--OLD:
		--, productType = 
		--	CASE 
		--		WHEN isnull(CRM_Requests.СмартИнстолмент, 0) = 1 THEN 'Смарт-инстоллмент'
		--		WHEN isnull(CRM_Requests.Инстолмент, 0) = 1 THEN 'Инстоллмент'
		--		WHEN isnull(CRM_Requests.ИспытательныйСрок, 0) = 1 THEN 'ПТС31'
		--		when isnull(CRM_Requests.ПДЛ,0) = 1 theN 'PDL'
		--		ELSE 'ПТС'
		--	END
		, productType = 
			CASE 
				WHEN isnull(R.isSmartInstallment, 0) = 1 THEN 'Смарт-инстоллмент'
				WHEN ТипПродукта.Код = 'installment' THEN 'Инстоллмент'
				WHEN ПодТипПродукта.Наименование = 'ПТС31' THEN 'ПТС31'
				WHEN ТипПродукта.Код = 'pdl' THEN 'PDL'
				ELSE 'ПТС'
			END

	into #t_ЗаявкаНаЗаймПодПТС
	from @t_fedor_request AS R
		--_1cCRM.Документ_ЗаявкаНаЗаймПодПТС CRM_Requests --WITH(INDEX=ix_Номер)
		LEFT JOIN _1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС AS st 
			ON st.Ссылка = dbo.get1CIDRREF_FromGUID(R.requestStatus)
		LEFT JOIN #t_hasRejection AS t_hasRejection
			ON t_hasRejection.МобильныйТелефон = R.mobilePhone
		LEFT JOIN #t_hasContract AS t_hasContract
			ON t_hasContract.МобильныйТелефон = R.mobilePhone
		LEFT JOIN #crm_fillType AS ft 
			ON ft.заявка_guid = R.requestGuid
		LEFT JOIN _1cCRM.Справочник_тмТипыКредитногоПродукта AS ТипПродукта
			ON ТипПродукта.Ссылка = dbo.get1CIDRREF_FromGUID(R.productType)
		LEFT JOIN _1cCRM.Справочник_тмПодТипыКредитногоПродукта AS ПодТипПродукта
			ON ПодТипПродукта.Ссылка = dbo.get1CIDRREF_FromGUID(R.productSubType)
		LEFT JOIN #t_Забраковано AS br
			ON br.requestGuid = R.requestGuid
		LEFT JOIN #t_ВерификацияКЦ AS vk
			ON vk.requestGuid = R.requestGuid

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #t_ЗаявкаНаЗаймПодПТС', @row_count, cast(getdate() - @StartDate as time(2)) as duration 
	END


	delete from #t_ЗаявкаНаЗаймПодПТС
	where 1=1
		--AND nullif(МобильныйТелефон,'') is NULL
        AND nullif(CRMRequestGUID,'') is null



	select @StartDate= getdate() , @row_count = 0

	;with cte_doubles as 
	(
		SELECT
			rn = row_number() OVER(
				PARTITION BY [Caller]
				ORDER BY  
				isActive desc,  -- по Договорености с В. Данилов сначала отдаем активные заявки
				CRMRequestDate desc, 
				CRMRequestID DESC
			)
			,*
		FROM #t_ЗаявкаНаЗаймПодПТС
	)
	DELETE FROM cte_doubles WHERE rn > 1

	set @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'delete doubles', @row_count, cast(getdate() - @StartDate as time(2)) as duration 

		DROP TABLE IF EXISTS ##t_ЗаявкаНаЗаймПодПТС
		SELECT * INTO ##t_ЗаявкаНаЗаймПодПТС FROM #t_ЗаявкаНаЗаймПодПТС
	END
	
	BEGIN TRAN
		select @StartDate= getdate() , @row_count = 0

		merge ivr.IVR_Data_uat t
		using #t_ЗаявкаНаЗаймПодПТС s
			--on t.[Caller] = s.[Caller]
			on t.CRMRequestGUID = s.CRMRequestGUID
			and  t.[Type] = 'CRM_Requests'
		when not matched 
		THEN INSERT (
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
			, requestTime
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
			, s.requestTime
		)
		when  matched  
			AND isnull(t.requestTime, '2000-01-01') <= s.requestTime
			--and isnull(t.[CRMRequest_RowVersion], 0) != s.[CRMRequest_RowVersion]
			--or isnull(t.[CRMClientGUID], cast(null as uniqueidentifier )) != isnull(s.[CRMClientGUID], cast(null as uniqueidentifier ))
			--OR isnull(t.[CRMRequestGUID], cast(null as uniqueidentifier )) !=isnull(s.[CRMRequestGUID], cast(null as uniqueidentifier ))
		THEN UPDATE 
		SET
			[Caller] = s.[Caller]
			, МобильныйТелефон = s.МобильныйТелефон
			, [Cmclient] = s.[Cmclient]
			, [CRMClientGUID] = s. [CRMClientGUID]
			--, [CRMRequestGUID] = s.[CRMRequestGUID]
			, [CRMRequestID] = s.[CRMRequestID]
			, [fio] = s.[fio]
			, [RequestType] = s.[RequestType]
			, [CRMRequestDate] = s.[CRMRequestDate]
			, [isActive] = s.[isActive]
			, [hasContract] = s.[hasContract]
			, [hasRejection] = s.[hasRejection]
			, [CRMRequestsLastStatus] = s.[CRMRequestsLastStatus]
			, [CRMRequest_RowVersion] = s.[CRMRequest_RowVersion]
			, Legal = s.Legal
			, ExecutionOrder = s.ExecutionOrder
			--, [Type]
			, [IVRDate] = s.[IVRDate]
			--, [created] = s.[created]
			, [updated] = s.[updated]
			, [isHistory] = s.[isHistory]
			, productType = s.productType
			, requestTime = s.requestTime
			;

		SELECT @row_count = @@ROWCOUNT

		IF @isDebug = 1 BEGIN
			SELECT 'merge ivr.IVR_Data_uat', @row_count, cast(getdate() - @StartDate as time(2)) as duration
		END

		/*
		update t
		set t.[hasRejection] =iif(t_hasRejection.МобильныйТелефон is not null, 1, 0)
		from ivr.IVR_Data_uat t
		LEFT join #t_hasRejection AS t_hasRejection
			ON t_hasRejection.МобильныйТелефон = trim(t.МобильныйТелефон)
		where t.[Type] = 'CRM_Requests'
			and isnull([hasRejection],0) != iif(t_hasRejection.МобильныйТелефон is not null, 1, 0)

		SELECT @row_count += @@ROWCOUNT

		update t
			set t.hasContract = iif(t_hasContract.МобильныйТелефон is not null, 1, 0)
		from ivr.IVR_Data_uat t
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
		from ivr.IVR_Data_uat t
		LEFT join #crm_fillType ft ON ft.заявка_guid= t.CRMRequestGUID
			and t.RequestType !=ft.RequestType
		where t.[Type] = 'CRM_Requests'

		SELECT @row_count += @@ROWCOUNT
		*/	
	COMMIT TRAN	



	/*
	INSERT @t_ivr_data
	(
		[Caller], 
		[Cmclient], 
		[CRMClientGUID], 
		[Dpd], 
		[Legal], 
		[ExecutionOrder], 
		[ProblemClient], 
		[CRMRequestGUID], 
		[CRMRequestID], 
		[fio], 
		[IVRDate], 
		[created], 
		[updated], 
		[isHistory], 
		[ClientStage], 
		[RequestType], 
		[CRMRequestDate], 
		[isActive], 
		[ClaimantFio], 
		[ClaimantCorporatePhone], 
		[IsInstallment], 
		[hasContract], 
		[hasRejection], 
		[isSmartInstallment], 
		[CRMRequestsLastStatus], 
		[claimantStage], 
		[Type], 
		[МобильныйТелефон],
		[channellid],
		productType
	)
	SELECT 
		[Caller], 
		[Cmclient], 
		[CRMClientGUID], 
		[Dpd] = NULL, 
		[Legal], 
		[ExecutionOrder], 
		[ProblemClient] = NULL, 
		[CRMRequestGUID], 
		[CRMRequestID], 
		[fio], 
		[IVRDate], 
		[created], 
		[updated], 
		[isHistory], 
		[ClientStage] = NULL, 
		[RequestType], 
		[CRMRequestDate], 
		[isActive], 
		[ClaimantFio] = NULL, 
		[ClaimantCorporatePhone] = NULL, 
		[IsInstallment], 
		[hasContract], 
		[hasRejection], 
		[isSmartInstallment], 
		[CRMRequestsLastStatus], 
		[claimantStage] = NULL, 
		[Type], 
		[МобильныйТелефон],
		[channellid] = NULL,
		productType
	FROM #t_ЗаявкаНаЗаймПодПТС AS S

	--EXEC ivr.ExportIVRFromDWH_byRequest
	--	@t_ivr_data = @t_ivr_data
	--	,@isDebug = @isDebug
	*/

	SELECT @IVR_Data_json_array = (
		SELECT 
			[Caller], 
			[Cmclient], 
			[CRMClientGUID], 
			[Dpd] = NULL, 
			[Legal], 
			[ExecutionOrder], 
			[ProblemClient] = NULL, 
			[CRMRequestGUID], 
			[CRMRequestID], 
			[fio], 
			[IVRDate], 
			[created], 
			[updated], 
			[isHistory], 
			[ClientStage] = NULL, 
			[RequestType], 
			[CRMRequestDate], 
			[isActive], 
			[ClaimantFio] = NULL, 
			[ClaimantCorporatePhone] = NULL, 
			[hasContract], 
			[hasRejection], 
			[CRMRequestsLastStatus], 
			[claimantStage] = NULL, 
			[Type], 
			--[МобильныйТелефон],
			mobilePhone = МобильныйТелефон,
			[channellid] = NULL,
			productType,
			requestTime = convert(varchar(19), requestTime, 120)
		FROM #t_ЗаявкаНаЗаймПодПТС AS S
		FOR JSON PATH, INCLUDE_NULL_VALUES --, WITHOUT_ARRAY_WRAPPER
	)

	IF @isDebug = 1 BEGIN
		SELECT @IVR_Data_json_array 
		--RETURN 0
	END

	EXEC [DWH-EX].Dialer.dbo.ImportIVRFromDWH_byRequest_uat
		@IVR_Data_json_array = @IVR_Data_json_array,
		@isDebug = @isDebug
	
end try
begin catch
	if @@TRANCOUNT>1
		rollback tran;
	;throw
end catch
end
