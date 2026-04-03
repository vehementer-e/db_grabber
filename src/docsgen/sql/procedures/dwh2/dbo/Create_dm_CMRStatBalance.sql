
--exec dbo.[Create_dm_CMRStatBalance] @Mode = 1, @ContractGuid = '76E3C9BC-6658-11EC-A2D0-005056839FE9', @isDebug = 1

/*
select  
[d], [ContractStartDate], [external_id], [Сумма], [СуммаДопПродуктов], [Срок], [ПроцентнаяСтавка], [Точка], [Период], [основной долг начислено], [основной долг уплачено], [Проценты начислено], [Проценты уплачено], [ПениНачислено], [ПениУплачено], [ГосПошлинаНачислено], [ГосПошлинаУплачено], [ПереплатаНачислено], [ПереплатаУплачено], [ОД начислено без Сторно по акции], [ОД уплачено без Сторно по акции], [Проценты начислено без Сторно по акции], [Проценты уплачено без Сторно по акции], [Пени начислено без Сторно по акции], [Пени уплачено без Сторно по акции], [ГосПошлина начислено без Сторно по акции], [ГосПошлина уплачено без Сторно по акции], [Переплата начислено без Сторно по акции], [Переплата уплачено без Сторно по акции], [остаток од], [остаток %], [остаток пени], [остаток иное (комиссии, пошлины и тд)], [остаток всего],  [основной долг начислено нарастающим итогом], [основной долг уплачено нарастающим итогом], [Проценты начислено  нарастающим итогом], [ПениНачислено  нарастающим итогом], [ГосПошлинаНачислено  нарастающим итогом], [Проценты уплачено  нарастающим итогом], [ПениУплачено  нарастающим итогом], [ГосПошлинаУплачено  нарастающим итогом], [ПереплатаНачислено нарастающим итогом], [ПереплатаУплачено нарастающим итогом], [ПроцентыПоГрафику], [ПроцентыПоГрафикуНарастающимИтогом], [ПроцентыГрейсПериода начислено], [ПроцентыГрейсПериода начислено нарастающим итогом], [ПроцентыГрейсПериода переведено], [ПроцентыГрейсПериода переведено нарастающим итогом], [ПениГрейсПериода начислено], [ПениГрейсПериода начислено нарастающим итогом], [ПениГрейсПериода переведено], [ПениГрейсПериода переведено нарастающим итогом], [dpd], [dpdMFO], [overdue], [bucket], [ContractEndDate], [dpd day-1], [Расчетный остаток всего], [ПроцентнаяСтавкаНаТекущийДень], [Остаток % расчетный], [Остаток пени расчетный], [dpd_begin_day], [dpd_coll], [dpd_p_coll], [_dpd_last_coll], [r_year], [r_month], [r_day], [bucket_coll], [bucket_p_coll], [dpd_last_coll], [bucket_last_coll], [prev_dpd_coll], [prev_dpd_p_coll], [prev_od], [principal_acc], [principal_cnl], [percents_acc], [percents_cnl], [fines_acc], [fines_cnl], [otherpayments_acc], [otherpayments_cnl], [Тип Продукта], [CMRClientGUID], [overpayments_acc], [overpayments_cnl]
from dbo.dm_CMRStatBalance
where external_id ='18112190420001'
and d='2018-11-21'
except
select CMRContractsGUID, 
[d], [ContractStartDate], [external_id], [Сумма], [СуммаДопПродуктов], [Срок], [ПроцентнаяСтавка], [Точка], [Период], [основной долг начислено], [основной долг уплачено], [Проценты начислено], [Проценты уплачено], [ПениНачислено], [ПениУплачено], [ГосПошлинаНачислено], [ГосПошлинаУплачено], [ПереплатаНачислено], [ПереплатаУплачено], [ОД начислено без Сторно по акции], [ОД уплачено без Сторно по акции], [Проценты начислено без Сторно по акции], [Проценты уплачено без Сторно по акции], [Пени начислено без Сторно по акции], [Пени уплачено без Сторно по акции], [ГосПошлина начислено без Сторно по акции], [ГосПошлина уплачено без Сторно по акции], [Переплата начислено без Сторно по акции], [Переплата уплачено без Сторно по акции], [остаток од], [остаток %], [остаток пени], [остаток иное (комиссии, пошлины и тд)], [остаток всего], [основной долг начислено нарастающим итогом], [основной долг уплачено нарастающим итогом], [Проценты начислено  нарастающим итогом], [ПениНачислено  нарастающим итогом], [ГосПошлинаНачислено  нарастающим итогом], [Проценты уплачено  нарастающим итогом], [ПениУплачено  нарастающим итогом], [ГосПошлинаУплачено  нарастающим итогом], [ПереплатаНачислено нарастающим итогом], [ПереплатаУплачено нарастающим итогом], [ПроцентыПоГрафику], [ПроцентыПоГрафикуНарастающимИтогом], [ПроцентыГрейсПериода начислено], [ПроцентыГрейсПериода начислено нарастающим итогом], [ПроцентыГрейсПериода переведено], [ПроцентыГрейсПериода переведено нарастающим итогом], [ПениГрейсПериода начислено], [ПениГрейсПериода начислено нарастающим итогом], [ПениГрейсПериода переведено], [ПениГрейсПериода переведено нарастающим итогом], [dpd], [dpdMFO], [overdue], [bucket], [ContractEndDate], [dpd day-1], [Расчетный остаток всего], [ПроцентнаяСтавкаНаТекущийДень], [Остаток % расчетный], [Остаток пени расчетный], [dpd_begin_day], [dpd_coll], [dpd_p_coll], [_dpd_last_coll], [r_year], [r_month], [r_day], [bucket_coll], [bucket_p_coll], [dpd_last_coll], [bucket_last_coll], [prev_dpd_coll], [prev_dpd_p_coll], [prev_od], [principal_acc], [principal_cnl], [percents_acc], [percents_cnl], [fines_acc], [fines_cnl], [otherpayments_acc], [otherpayments_cnl], [Тип Продукта], [CMRClientGUID], [overpayments_acc], [overpayments_cnl]
from dbo.dm_CMRStatBalance
where external_id ='20041110000123'
and d='2024-05-02'
exec dbo.[Create_dm_CMRStatBalance] @Mode = 1
	, @ContractGuid = '19690AF7-BD40-11EF-B81B-B1D282F786D6'
	, @isDebug = 1

	-33854,44




*/
CREATE   PROC [dbo].[Create_dm_CMRStatBalance]
	@Mode				int,		--0 - расчет по всем договорам(действующим когда либо);  1 - расчет по договорам в таблице (либо через параметры); @Mode = 2 - расчет по списку активных договоров из [Stg].[dbo].[_1cАналитическиеПоказатели]
	@isDebug			int = 0,
	@ContractGuid		nvarchar(36) = null,
	@ContractGuids		nvarchar(max) = null
WITH RECOMPILE
as
begin
	set XACT_ABORT  ON
	set nocount on
	declare @reloadDay smallint = 3
	SET DEADLOCK_PRIORITY NORMAL 
	SELECT @isDebug = isnull(@isDebug, 0)
    DECLARE @StartDate datetime, @row_count int, @duration int, @StartDate_0 datetime = getdate()
	DECLARE
		@logger_name nvarchar(127) = 'adminlog', -- например: 'adminlog', 'Airflow'
		@process_guid varchar(36) = newid(), -- guid процесса
		--
		@event_level varchar(30) = 'info', -- например: 'error', 'info', 'warning'
		@event_type varchar(127) =  OBJECT_NAME(@@PROCID), -- например: 'task_start', 'create_balance', 'create_indexes', 'data_quality_check'
		@event_name varchar(256) = 'Расчет баланса', -- например: 'Заполнение витрины ...', 'Расчет баланса'
		--
		@event_step_number int = 0, -- 1,2,3,...
		@event_step_type varchar(127), -- например: 'start load t1', 'create index ix1'
		@event_step_name varchar(256), -- например: 'Начало загрузки таблицы t1'
		--
		@event_status varchar(30) = 'succeeded', -- например: 'failed', 'running', 'skipped', 'succeeded'
		@event_message nvarchar(2048), -- текст сообщения в произвольной форме, например, сообщение об ошибке
		@event_description nvarchar(2048) -- структурированная информация, например, параметры в формате json, xml

begin try	

	IF @isDebug = 1 BEGIN
		--SELECT @duration = datediff(SECOND, @StartDate_0, getdate())
		--SELECT @event_step_number = @event_step_number + 1
		SELECT @event_step_type = CONCAT_WS(' ', 'Start EXEC ', OBJECT_NAME(@@PROCID))
		SELECT @event_message = concat('@Mode: ', @Mode)
		SELECT @event_description = (SELECT mode = @Mode FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END
	
	set @ContractGuids = CONCAT_WS(',', @ContractGuids, @ContractGuid)
	set @ContractGuids = nullif(@ContractGuids, '')


	declare @t_contracts table(contractId binary(16) primary key, contractGuid nvarchar(36))
	insert into @t_contracts(contractId, contractGuid)
	select distinct 
		contractId = [dbo].[get1CIDRREF_FromGUID](trim(value))
		, contractGuid = trim(value)
	from string_split(@contractGuids, ',')
		

	-- 2021-10-19	
	-- необходимо добавить максимальное dpd на первую дату в день по аналитическим показателям dpdMax dpdMax-1. Аналогично данные УМФО dpd
	-- необходимо исключить расчеты по займам после даты закрытия (например предложить провести все в один день закрытия) -  В рамках работ CMR.


	-- 05/02/2020 0 - расчет по всем договорам
	--, 1 - расчет по договорам в таблице
	--Declare @Mode int = 1

	-- 09.10.2022 
	-- @Mode = 2 - расчет по списку активных договоров из [Stg].[dbo].[_1cАналитическиеПоказатели]
	-- признак активности: в таблице есть запись за сегодня

	drop table if exists [#CalculationContracts]
	CREATE TABLE #CalculationContracts
	(
		[Ссылка] binary(16) NOT NULL,
		[external_id] nvarchar(21) NOT NULL,
		DateStart date null,
		
	)
	CREATE CLUSTERED INDEX cix ON #CalculationContracts(Ссылка, external_id) 
	
	--if @Mode <> 1
	if @Mode NOT IN (1, 2)
	begin
		Set @Mode = 0
	end

	declare @cntContracts int =0

	SELECT @StartDate = getdate(), @row_count = 0

	if @Mode = 1
	begin
		if @ContractGuids  is null
		begin
			begin tran
			-- Так как источников может быть много, проводим дедубликацию
			insert into #CalculationContracts(external_id, Ссылка )
			SELECT distinct Y.external_id, d.Ссылка
			FROM [Stg].[dbo].[CMRStatBalanceListTioCalculation] AS Y
				INNER JOIN Stg._1cCMR.Справочник_Договоры AS d
					ON Y.external_id = d.Код
			GROUP BY Y.external_id, d.Ссылка

			SELECT @row_count = @@ROWCOUNT

			-- Очистим таблицу, так как скопировали для расчета
			delete from [Stg].[dbo].[CMRStatBalanceListTioCalculation]
			where [external_id] in (select [external_id]
				from #CalculationContracts)
			commit tran
		end
		else 
		begin
			insert into #CalculationContracts(external_id, Ссылка)
			SELECT distinct 
				external_id = Dogovor.Код,
				Dogovor.Ссылка
			FROM stg.[_1cCMR].[Справочник_Договоры]  Dogovor (NOLOCK)
			where exists(select top(1) 1 from @t_contracts t
			where t.contractId = Dogovor.Ссылка)

			SELECT @row_count = @@ROWCOUNT
		end
		select @cntContracts = count(1)
			from #CalculationContracts
	end
	--else

	-- расчет по списку активных договоров из [Stg].[dbo].[_1cАналитическиеПоказатели]
	-- признак активности: в таблице есть запись за сегодня
	if @Mode = 2
	begin
		INSERT #CalculationContracts with(tablockx) (external_id, Ссылка, DateStart) 
		select distinct d.Код
			, d.Ссылка
			, DateStart = min(DateStart) 
		from Stg._1ccmr.Справочник_Договоры AS d
		INNER JOIN  (
			SELECT
				ap.Договор
				, DateStart = min(ap.Период)
			FROM [Stg].[dbo].[_1cАналитическиеПоказатели] AS ap
			WHERE 1=1
				AND cast(ap.Период as date) >= dateadd(DAY, -@reloadDay, convert(date, getdate()))
				--AND cast(ap.Период as date) >='2024-10-01'
				group by ap.НомерДоговора, ap.Договор
			union
			--Договора которые были погашены за последние 15дней
			SELECT last_status.договор , DateStart = dateadd(year,-2000, last_status.Период)
			FROM 
			(
				select 
					--Период = dateadd(year,-2000,min(sd.Период))
					Период =max(sd.Период)
					,sd.договор
				from
				Stg._1cCMR.РегистрСведений_СтатусыДоговоров AS sd 
				group by sd.договор
			) last_status 
			inner join Stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
				on sd.Период = last_status.Период
				and  sd.Договор = last_status.Договор
			INNER JOIN Stg._1ccmr.Справочник_СтатусыДоговоров AS ssd
					ON ssd.Ссылка=sd.Статус
				 and ssd.Наименование in ('Погашен', 'Продан', 'Аннулирован'
				, 'Внебаланс'--2024.04.03 - учитываем еще и этот статус
					)
			WHERE 
				(cast(last_status.Период as date) >= dateadd(DAY, -@reloadDay*5, convert(date, getdate()))
				
					--dateadd(year,-2000, last_status.Период) >= dateadd(DAY, - 15 , convert(date, getdate()))
					or sd.Статус = 0xB81700155D4D0B5211E9F50AF09A29DF --Внебаланс
				--если крайни статус Внебаланс то его также считаем
				) 
		) t ON d.Ссылка= t.Договор
			group by 
				d.Код
				, d.Ссылка
				/*
		--DWH-2572. расчет договоров с ДП
		UNION
		SELECT DISTINCT TOP 10000 
			external_id = d.Код,
			Ссылка = rpz.Договор,
			DateStart = cast(NULL AS date)
		from stg._1Ccmr.РегистрНакопления_РасчетыПоЗаймам AS rpz
			INNER JOIN Stg._1ccmr.Справочник_Договоры AS d
				ON d.Ссылка = rpz.Договор
		where rpz.ХозяйственнаяОперация = 0x80D900155D64100111E78663D3A87B83 --ДП
			AND NOT EXISTS(
				SELECT top(1) 1 
				FROM dbo.dm_CMRStatBalance AS b
				WHERE d.Код = b.external_id
					AND isnull(b.[ДП Основной долг Уплачено],0) <> 0
			)

		--DWH-2616. расчет договоров с ЧДП
		UNION
		SELECT DISTINCT TOP 10000 
			external_id = d.Код,
			Ссылка = rpz.Договор,
			DateStart = cast(NULL AS date)
		from stg._1Ccmr.РегистрНакопления_РасчетыПоЗаймам AS rpz
			INNER JOIN Stg._1ccmr.Справочник_Договоры AS d
				ON d.Ссылка = rpz.Договор
		where rpz.ХозяйственнаяОперация = 0x80D900155D64100111E78663D3A87B8F --ЧДП
			AND NOT EXISTS(
				SELECT top(1) 1 
				FROM dbo.dm_CMRStatBalance AS b
				WHERE d.Код = b.external_id
					AND isnull(b.[ЧДП Основной долг Уплачено],0) <> 0
			)
			*/
		option (hash join, maxdop 8)


		SELECT @row_count = @@ROWCOUNT

		select @cntContracts = count(1)
		from #CalculationContracts
	end

	if @Mode = 0
	begin
		set @cntContracts = 0
		--список всех договоров, необходимых для отчета
		INSERT #CalculationContracts(external_id, Ссылка)
		SELECT DISTINCT external_id = d.Код, d.Ссылка
		from Stg._1ccmr.Справочник_Договоры AS d
		where exists(select top(1) 1
		from Stg._1cCMR.РегистрСведений_СтатусыДоговоров AS sd 
			INNER JOIN Stg._1ccmr.Справочник_СтатусыДоговоров AS ssd
				ON ssd.Ссылка = sd.Статус
		WHERE ssd.Наименование='Действует'
		and d.Ссылка = sd.Договор)

		SELECT @row_count = @@ROWCOUNT
	end

	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'INSERT into #CalculationContracts'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END

	if @cntContracts =0
		and @Mode IN (1, 2)
	BEGIN
		RETURN
	END
	else 
	begin
		print concat_ws(' ', 'договоров в работу ', @cntContracts)
	end

	select @StartDate = getdate()
	drop table if exists #endedContracts
	CREATE TABLE #endedContracts ( 
		Договор    binary(16) not null primary key,
		dt date ) ON [PRIMARY]

	INSERT INTO #endedContracts(Договор,  dt)
	SELECT sd.Договор                          
	,      dt=dateadd(year,-2000,max(sd.Период))
	FROM 
	(
		select 
			--Период = dateadd(year,-2000,min(sd.Период))
			last_Период =max(sd.Период)
			,sd.договор
		from
		Stg._1cCMR.РегистрСведений_СтатусыДоговоров AS sd 
		group by sd.договор
	) last_status 
	inner join Stg._1cCMR.РегистрСведений_СтатусыДоговоров AS sd 
		on sd.Договор = last_status.Договор
		and sd.Период = last_status.last_Период
	INNER JOIN Stg._1ccmr.Справочник_СтатусыДоговоров AS ssd
			ON ssd.Ссылка=sd.Статус
		-- всегда по списку договоров
		and ssd.Наименование in('Погашен', 'Продан', 'Аннулирован')
	WHERE exists (select top(1) 1 from #CalculationContracts AS Y
			where Y.Ссылка = sd.Договор)
	group by sd.Договор  


	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'INSERT INTO #endedContracts'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END



	select @StartDate = getdate()
	drop table if exists #contracts 
	CREATE TABLE #contracts
	(
		Договор				binary(16) primary key,
		[external_id]		nvarchar (21) ,
		[ContractStartDate] date ,
		PeriodStartDate		date,
		[ContractEndDate]	date ,
		[Сумма]				money,
		[СуммаДопПродуктов] money,
		[Срок]				smallint,
		[ПроцентнаяСтавка]	smallmoney,
		[Точка]				[nvarchar] (200) NULL,
		[Тип Продукта]		nvarchar(50) NULL, -- 'ПТС', 'ПТС31', 'Инстоллмент', 'Смарт-инстоллмент'
		CMRContractsGUID	nvarchar(36) null,
		CMRClientGUID		nvarchar(36) null
	)

	insert into #contracts
	(
		Договор				
		,[external_id]		
		,[ContractStartDate] 
		,PeriodStartDate
		,[ContractEndDate]	
		,[Сумма]				
		,[СуммаДопПродуктов] 
		,[Срок]				
		,[ПроцентнаяСтавка]	
		,[Точка]				
		,[Тип Продукта]		
		,CMRContractsGUID	
		,CMRClientGUID		
	)
	SELECT distinct
		Договор = d.Ссылка
	,	external_id =  d.Код
	,	[ContractStartDate] =cast(dateadd(year,-2000, d.Дата) as date)
	,	PeriodStartDate = 	COALESCE(start_dt.start_dt, cast(dateadd(year,-2000, d.Дата) as date))
	,	[ContractEndDate] = ed.dt
	,   d.Сумма
	,   d.СуммаДопПродуктов
	,   D.Срок
	,   D.ПроцентнаяСтавка
	,   Точка = t.Наименование
	--DWH-1822
		--Если isSmartInstallment = Истина - 'Смартинстолмент'
		--иначеесли isInstallment = Истина - 'Инстоллмент'
		--иначеесли Заявка.ИспытательныйСрок = Истина - 'ПТС31'
		--Иначе 'ПТС'
	,		[Тип Продукта] = 
				cast(
					CASE lower(cmr_ПодтипыПродуктов.ИдентификаторMDS)
						when 'installment'			then 'Инстоллмент'
						when 'smart-installment'	then 'Смарт-инстоллмент'
						else cmr_ПодтипыПродуктов.Наименование
					END AS nvarchar(50))
	,	   CMRContractsGUID = [dbo].[getGUIDFrom1C_IDRREF](d.Ссылка)
	,	   CMRClientGUID = [dbo].[getGUIDFrom1C_IDRREF](d.Клиент)
	FROM STG.[_1Ccmr].Справочник_Договоры AS d
		inner join [Stg].[_1cCMR].[Справочник_Заявка] cmr_Заявка
			on cmr_Заявка.Ссылка = d.Заявка
		left join [Stg].[_1cCMR].[Справочник_ПодтипыПродуктов] cmr_ПодтипыПродуктов
			on cmr_Заявка.ПодтипПродукта = cmr_ПодтипыПродуктов.ссылка	
		LEFT JOIN Stg._1cCMR.Справочник_Точки AS t
			ON t.Ссылка=d.Точка
		--только те договора у которых был статус --Действует
		inner join 
		(
			select Договор
			,start_dt = dateadd(year, -2000, min(cast(Период as date)))
			from stg._1cCMR.РегистрСведений_СтатусыДоговоров t
			where exists(select top(1) 1 from Stg._1ccmr.Справочник_СтатусыДоговоров  СтатусыДоговоров
				where СтатусыДоговоров.Ссылка = t.Статус
				and СтатусыДоговоров.Наименование in ('Действует'))
			group by Договор

		) start_dt on start_dt.Договор = d.Ссылка
		left join #endedContracts ed on ed.Договор = d.Ссылка

		where exists(select top(1) 1 from #CalculationContracts AS Y
		where y.Ссылка = d.Ссылка)
	
	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'insert into #contracts'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END

	select @StartDate = getdate()
	drop table if exists  #Contract_calendar
	create table #Contract_calendar
	(
		Договор binary(16), 
		external_id nvarchar(21), 
		ContractStartDate date,
		PeriodStartDate date,
		ContractEndDate date,
		dt date
	)
	/* через рекусрию дольше получается
	;with cte_calendar as
	(
		select 
			Договор
			,dt = ContractStartDate
			from #contracts
			--where Договор = 0xA2C7005056839FE911EAD97378DBCF20
			union all
			select 
				 c.Договор
				,dt = dateadd(dd,1, calendar.dt)
			from cte_calendar calendar
			inner join #contracts  c on c.Договор = calendar.Договор
				where calendar.dt<isnull(c.ContractEndDate, getdate())
			
	)
	insert into #Contract_calendar with(tablockx) 
		(Договор, dt) 
	
	select Договор, dt
	from cte_calendar
	option (recompile, hash join, MAXRECURSION 0)
	SELECT '#Contract_calendar',  cast((getdate()- @StartDate ) as time(0))
	*/
	insert into #Contract_calendar with(tablockx) 
		(Договор, external_id, ContractStartDate, PeriodStartDate, ContractEndDate, dt)
	select distinct
		c.Договор
		,c.external_id
		,c.ContractStartDate
		,c.PeriodStartDate
		,c.ContractEndDate
		,calendar.DT
		from #contracts c
		inner  join Dictionary.calendar  calendar 
		on calendar.dt between c.periodStartDate and isnull(c.ContractEndDate, getdate())

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'INSERT #Contract_calendar'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END
	
	select @StartDate = getdate()
	create clustered index ix_Договор_dt on #Contract_calendar(Договор, dt) 
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'create clustered index #Contract_calendar'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END
	select @StartDate = getdate()
	create index ix_external_id_dt on #Contract_calendar(external_id, dt)
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'create index ix_external_id_dt on #Contract_calendar'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END

	drop table if exists #payments
	CREATE TABLE #payments ( Договор		binary(16)
	,                        [dt]           date
	,                        [summ]         money
	,						 summTotal	   money
	,                        payment_system nvarchar(100) ) 
	insert into #payments with(tablockx)
	(
		Договор,
		[dt],
		[summ],
		summTotal,
		payment_system
	)
	
	select 
		cc.Договор
		,cc.dt
		,summ = isnull(pay.summ,0)
		,summTotal = sum(isnull(summ,0)) over (partition by cc.Договор  order by cc.dt  rows between unbounded preceding and current row)                           
		,pay.payment_system
	from  #Contract_calendar cc
	left join (
		select 
			p.Договор
			,dt = cast(dateadd(year,-2000, p.дата) as date)  
			,summ=sum(isnull(p.Сумма,0))
			,payment_system = first_value(max(ps.наименование)) over (partition by p.Договор, cast(dateadd(year,-2000, p.дата) as date)
				order by (select null)) 
		from stg._1cCMR.[Документ_Платеж]             p 	
		left join stg._1cCMR.[Справочник_ПлатежныеСистемы] ps on p.ПлатежнаяСистема=ps.ссылка
		where Проведен=0x01
		group by Договор, cast(dateadd(year,-2000, p.дата) as date)  
	) pay
		on pay.Договор = cc.Договор
		and pay.dt= cc.dt
	option (hash join)
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'insert into #payments'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END
	select @StartDate = getdate()
	create clustered index cix on #payments(Договор, dt)
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'create clustered index cix on #payments'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END	 
	select @StartDate = getdate()
	
	drop table if exists #ap_reg
	CREATE TABLE #ap_reg(
		[Договор]										binary (16) not null,
		dt												date not null,
		[АналитическиеПоказатели_Договор]				binary (16),
		[АналитическиеПоказатели_dt]					date,
		[КоличествоПолныхДнейПросрочкиУМФО]				smallint,
		[КоличествоПолныхДнейПросрочки]					smallint,
		[ПросроченнаяЗадолженность]						money,
		ПросроченнаяЗадолженность_begin_day				money,
		[КоличествоПолныхДнейПросрочкиУМФО_begin_day]	smallint,
		[КоличествоПолныхДнейПросрочки_begin_day]		smallint,
		
		fix_cmr_dpd_overdue_days						smallint,
		fix_cmr_dpd_overdue_days_p						smallint,
		
		_dpd_last_coll									smallint,
		[КоличествоПолныхДнейПросрочкиУМФО - 1]			smallint,
		prev_dpd_coll									smallint,
		prev_dpd_p_coll									smallint,

		bucket											nvarchar(255),
		[bucket_coll]									nvarchar(255),
		[bucket_p_coll]									nvarchar(255),
		bucket_last_coll								nvarchar(255),

		dpd_coll										as coalesce(fix_cmr_dpd_overdue_days,	[КоличествоПолныхДнейПросрочкиУМФО], 0),
		dpd_p_coll										as coalesce(fix_cmr_dpd_overdue_days_p , [КоличествоПолныхДнейПросрочкиУМФО_begin_day], 0),
		dpd_begin_day									as [КоличествоПолныхДнейПросрочкиУМФО_begin_day],
		dpd												as [КоличествоПолныхДнейПросрочкиУМФО],
		dpdMFO											as [КоличествоПолныхДнейПросрочки] ,
		dpdMFO_begin_day								as [КоличествоПолныхДнейПросрочки_begin_day] ,
		overdue											as [ПросроченнаяЗадолженность] ,
		overdue_begin_day								as [ПросроченнаяЗадолженность_begin_day],
		[dpd day-1]										as [КоличествоПолныхДнейПросрочкиУМФО - 1] ,
		dpd_last_coll									as coalesce(_dpd_last_coll,[КоличествоПолныхДнейПросрочкиУМФО - 1],0)
		,bucket_last_p_coll								nvarchar(255)--DWH-2924
	)
	insert into #ap_reg
	with(tablockX)
	(
		[Договор]							
		,dt			
		,[АналитическиеПоказатели_Договор]				
		,[АналитическиеПоказатели_dt]					
		,[КоличествоПолныхДнейПросрочкиУМФО] 
		,[КоличествоПолныхДнейПросрочки]		
		,[ПросроченнаяЗадолженность]			
		
		,[КоличествоПолныхДнейПросрочкиУМФО_begin_day]				
		,[КоличествоПолныхДнейПросрочки_begin_day]						
		,ПросроченнаяЗадолженность_begin_day 
		,fix_cmr_dpd_overdue_days
		,fix_cmr_dpd_overdue_days_p
		,_dpd_last_coll
		,[КоличествоПолныхДнейПросрочкиУМФО - 1]
		,prev_dpd_coll
		,prev_dpd_p_coll
	)
	
	select 
		 [Договор]										= cc.Договор
		,dt												= cc.dt
		--Если данных нет на начало действия договора, странно, но бывает
		,[АналитическиеПоказатели_Договор]				= iif(cc.dt = cc.ContractStartDate, cc.Договор, ap.Договор						)	
		,[АналитическиеПоказатели_dt]					= iif(cc.dt = cc.ContractStartDate, cc.dt, ap.Период_dt						)
		,[КоличествоПолныхДнейПросрочкиУМФО] 			= iif(cc.dt = cc.ContractStartDate, 0, t_max.КоличествоПолныхДнейПросрочкиУМФО	)
		,[КоличествоПолныхДнейПросрочки]				= iif(cc.dt = cc.ContractStartDate, 0, t_max.КоличествоПолныхДнейПросрочки		)
		--БЫвает сразу переплата в первый же день
		,[ПросроченнаяЗадолженность]					= iif(cc.dt = cc.ContractStartDate, isnull(t_max.ПросроченнаяЗадолженность,0), 	t_max.ПросроченнаяЗадолженность)
		,[КоличествоПолныхДнейПросрочкиУМФО_begin_day]	= iif(cc.dt = cc.ContractStartDate, 0, t_min.КоличествоПолныхДнейПросрочкиУМФО	)
		,[КоличествоПолныхДнейПросрочки_begin_day]		= iif(cc.dt = cc.ContractStartDate, 0, t_min.КоличествоПолныхДнейПросрочки		)
		,ПросроченнаяЗадолженность_begin_day 			= iif(cc.dt = cc.ContractStartDate, isnull(t_min.ПросроченнаяЗадолженность,0), t_min.ПросроченнаяЗадолженность)
		,fix_cmr_dpd_overdue_days						= iif(cc.dt = cc.ContractStartDate, 0, fcd.overdue_days							)
		,fix_cmr_dpd_overdue_days_p						= iif(cc.dt = cc.ContractStartDate, 0, fcd.overdue_days_p						)
		
		,_dpd_last_coll									= fcd.last_dpd 
		,[КоличествоПолныхДнейПросрочкиУМФО - 1]		= lag(t_max.КоличествоПолныхДнейПросрочкиУМФО) 
				over (partition by cc.Договор order by  cc.dt)  

		,prev_dpd_coll = lag( coalesce(fcd.overdue_days,	t_max.[КоличествоПолныхДнейПросрочкиУМФО], 0),1,0) 
			over (partition by cc.Договор order by  cc.dt)  
		,prev_dpd_p_coll= lag( coalesce(fcd.overdue_days_p , t_min.КоличествоПолныхДнейПросрочкиУМФО, 0),1,0) 
			over (partition by cc.Договор order by  cc.dt)  
	FROM  #Contract_calendar cc
	left join (select  Договор
		,Период_dt = cast(Период as date)
		,min_Период = min(Период)
		,max_Период = max(Период)
		from 
		[Stg].[dbo].[_1cАналитическиеПоказатели] AS ap
		where 1=1
			and exists(select top(1) 1 from #CalculationContracts  cc 
			where ap.Договор = CC.Ссылка)
		group by Договор, cast(Период as date)
		) ap on ap.Договор = cc.Договор
			and ap.Период_dt = cc.dt
	left join (
		select Договор
			,Период_dt=  cast(Период as date)
			,Период
			,nRow = ROW_NUMBER() over(partition by Договор, cast(Период as date) order by Период) -- только первая запись в рамках дня
			,t_min.КоличествоПолныхДнейПросрочкиУМФО
			,t_min.КоличествоПолныхДнейПросрочки
			,t_min.ПросроченнаяЗадолженность
		from [Stg].[dbo].[_1cАналитическиеПоказатели] t_min
			where 1=1
			and exists(select top(1) 1 from #CalculationContracts  cc 
			where t_min.Договор = CC.Ссылка)
	)t_min on   --данные на начало дня
		t_min.Договор  = ap.Договор
		and t_min.Период_dt = ap.Период_dt
		and t_min.Период = ap.min_Период
		and t_min.nRow = 1--интересует только первая запись
	left join (
			select Договор
			,Период_dt=  cast(Период as date)
			,Период
			,nRow = ROW_NUMBER() over(partition by Договор, cast(Период as date) order by Период desc, Регистратор_Ссылка desc ) -- только крайня запись в рамках дня
			,КоличествоПолныхДнейПросрочкиУМФО
			,КоличествоПолныхДнейПросрочки
			,ПросроченнаяЗадолженность
		from [Stg].[dbo].[_1cАналитическиеПоказатели] t_max
		where 1=1
			and exists(select top(1) 1 from #CalculationContracts  cc 
			where t_max.Договор = CC.Ссылка)
	) t_max on ----данные на конец дня
		t_max.Договор		= ap.Договор
		and t_max.Период_dt = ap.Период_dt
		and t_max.Период	= ap.max_Период
		and t_max.nRow		= 1--интересует только первая запись
	left join dbo.fix_cmr_dpd fcd on fcd.external_id =cc.external_id
		and fcd.r_date = cc.dt
	option(hash join)	

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'insert into #ap_reg'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END	 
	select @StartDate = getdate()
	create clustered index cix on #ap_reg([Договор], dt)  with(MAXDOP=8)
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'create clustered index cix on #ap_reg'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END	 

	select @StartDate = getdate()
	/*
	--Найдем договора по которым нет данных в _1cАналитическиеПоказатели
		причины
		1. ДЫрка в данных в DWH - проблема в репликации
		2. Дыргка в данных ЦМР - дефект, такого не должно быть.
	*/
	;with cte_ap as
	(
		select Договор, dt from #ap_reg ap
		where АналитическиеПоказатели_Договор is NULL 
	)
	--Проставляем те значения который были напредыдущий день, чтобы небыло "дырок в балансе"
	update ap
		set
		 [КоличествоПолныхДнейПросрочкиУМФО]			= isnull(ap_last.[КоличествоПолныхДнейПросрочкиУМФО]			,ap.[КоличествоПолныхДнейПросрочкиУМФО]				)
		,[КоличествоПолныхДнейПросрочки]				= isnull(ap_last.[КоличествоПолныхДнейПросрочки]				,ap.[КоличествоПолныхДнейПросрочки]					)
		,[ПросроченнаяЗадолженность]					= isnull(ap_last.[ПросроченнаяЗадолженность]					,ap.[ПросроченнаяЗадолженность]						)
		,[КоличествоПолныхДнейПросрочкиУМФО_begin_day]	= isnull(ap_last.[КоличествоПолныхДнейПросрочкиУМФО_begin_day]	,ap.[КоличествоПолныхДнейПросрочкиУМФО_begin_day]	)
		,[КоличествоПолныхДнейПросрочки_begin_day]		= isnull(ap_last.[КоличествоПолныхДнейПросрочки_begin_day] 		,ap.[КоличествоПолныхДнейПросрочки_begin_day]		)		
		,ПросроченнаяЗадолженность_begin_day 			= isnull(ap_last.ПросроченнаяЗадолженность_begin_day			,ap.ПросроченнаяЗадолженность_begin_day 			)
		,[КоличествоПолныхДнейПросрочкиУМФО - 1]		= isnull(ap_last.[КоличествоПолныхДнейПросрочкиУМФО - 1]		,ap.[КоличествоПолныхДнейПросрочкиУМФО - 1])
		,prev_dpd_coll									= isnull(ap_last.prev_dpd_coll									,ap.prev_dpd_coll)
		,prev_dpd_p_coll								= isnull(ap_last.prev_dpd_p_coll								,ap.prev_dpd_p_coll)

	 from #ap_reg ap
	outer apply (
		select 
			top(1) *	
		from #ap_reg ap_last
		where ap_last.Договор =  ap.Договор
		and ap_last.dt <=ap.dt
		and ap_last.АналитическиеПоказатели_Договор is not NULL
		order by ap_last.dt desc
	) ap_last
	where exists(select top(1) 1 from cte_ap t where t.Договор = ap.Договор
		and t.dt = ap.dt)
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'update #ap_reg проставили не заполненые данные'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END	 

	/*
	Особой разницы между скалярной ф-ции (имено в 2 потокаА) и табличной фции и более чем 2 потока нет +- время тоже
	
	update #ap_reg
		set bucket				= dbo.GetBucketName(dpd)
			,[bucket_coll]		= dbo.GetCollectionBucketName(dpd_coll)
			,[bucket_p_coll]	= dbo.GetCollectionBucketName(dpd_p_coll)
			,[bucket_last_coll]	= dbo.GetCollectionBucketName(dpd_last_coll)
	option( maxdop 2)	
	*/

	select @StartDate = getdate()
	
	update rg
		set bucket			= bn.bucketName
		,[bucket_coll]		= bn_coll.bucketName
		,[bucket_p_coll]	= bn_p_coll.bucketName
		,[bucket_last_coll]	= bn_last_coll.bucketName
		,bucket_last_p_coll = bn_last_p_coll.bucketName --DWH-2924
	from #ap_reg rg
	--напряму через запрос 7мин
	left join [dbo].[tvf_GetBucketName](null) bn 
		on rg.dpd between bn.dpdMin and bn.dpdMax
	left join dbo.tvf_GetCollectionBucketName(null) bn_coll 
		on rg.dpd_coll between bn_coll.dpdMin and bn_coll.dpdMax
	left join dbo.tvf_GetCollectionBucketName(null) bn_p_coll
		on rg.dpd_p_coll between bn_p_coll.dpdMin and bn_p_coll.dpdMax
	left join dbo.tvf_GetCollectionBucketName(null) bn_last_coll
		on rg.dpd_last_coll between bn_last_coll.dpdMin and bn_last_coll.dpdMax
	left join dbo.tvf_GetCollectionBucketName(null) bn_last_p_coll
		on rg.prev_dpd_p_coll between bn_last_p_coll.dpdMin and bn_last_p_coll.dpdMax
	option( maxdop 16)	
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'update #ap_reg bucket_name*'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END	 

	SELECT @StartDate = getdate()
	drop table if exists #t_Период_ПроцентнаяСтавка
	create table #t_Период_ПроцентнаяСтавка
	(
		[Договор] binary(16),
		Период_c date,
		Период_По date,
		[ПроцентнаяСтавкаНаТекущийДень] money
	)
	insert into #t_Период_ПроцентнаяСтавка
	SELECT distinct 
		ПараметрыДоговора.Договор,
		Период_c							= dateadd(year, -2000, cast(ПараметрыДоговора.Период AS date)),
		Период_По = lead(dateadd(year, -2000, dateadd(dd,-1, cast(ПараметрыДоговора.Период AS date)))
			, 1, getdate()) 
				over(partition by ПараметрыДоговора.Договор order by ПараметрыДоговора.Период),
		ПроцентнаяСтавкаНаТекущийДень = coalesce(nullif(ПараметрыДоговора.[ПроцентнаяСтавка], 0), ПараметрыДоговора.[НачисляемыеПроценты])
	FROM Stg.[_1Ccmr].[РегистрСведений_ПараметрыДоговора] AS ПараметрыДоговора
		where Активность = 0x01
		and Регистратор_ТипСсылки = 0x0000005E --График платежей
		and exists(select top(1) 1 from [#CalculationContracts] cc
		where cc.ССылка = ПараметрыДоговора.Договор)
	SELECT @row_count = @@ROWCOUNT

	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'insert into #t_Период_ПроцентнаяСтавка'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END
	select @StartDate =getdate()
	CREATE CLUSTERED INDEX cix ON #t_Период_ПроцентнаяСтавка(Договор, Период_c, Период_По)
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'CREATE CLUSTERED INDEX cix ON #t_Период_ПроцентнаяСтавка'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END

	SELECT @StartDate = getdate(), @row_count = 0
	DROP TABLE IF EXISTS #t_Расчеты
	create table #t_Расчеты
	(
		  Договор												binary(16)
		, dt													date
		, [ОДПоГрафику Начислено]								money
		, [ОДПоГрафику Начислено нарастающим итогом]			money
		, [ОДПоГрафику Уплачено]								money
		, [ОДПоГрафику Уплачено нарастающим итогом]				money
		, [ПроцентыПоГрафику Начислено]							money
		, [ПроцентыПоГрафику Начислено нарастающим итогом]		money
		, [ПроцентыПоГрафику Уплачено]							money
		, [ПроцентыПоГрафику Уплачено нарастающим итогом]		money
		, [Основной долг Начислено]								money
		, [Основной долг Начислено нарастающим итогом]			money
		, [Основной долг Уплачено]								money
		, [Основной долг Уплачено нарастающим итогом]			money
		, [Проценты Начислено]									money
		, [Проценты Начислено нарастающим итогом]				money
		, [Проценты Уплачено]									money
		, [Проценты Уплачено нарастающим итогом]				money
		, [ПроцентыГрейсПериода Начислено]						money
		, [ПроцентыГрейсПериода Начислено нарастающим итогом]	money
		, [ПроцентыГрейсПериода Уплачено]						money
		, [ПроцентыГрейсПериода Уплачено нарастающим итогом]	money
		, [ПроцентыГрейсПериода Переведено]						money
		, [ПроцентыГрейсПериода Переведено нарастающим итогом]	money
		, [Пени Начислено]										money
		, [Пени Начислено нарастающим итогом]					money
		, [Пени Уплачено]										money
		, [Пени Уплачено нарастающим итогом]					money
		, [ПениГрейсПериода Начислено]							money
		, [ПениГрейсПериода Начислено нарастающим итогом]		money
		, [ПениГрейсПериода Уплачено]							money
		, [ПениГрейсПериода Уплачено нарастающим итогом]		money
		, [ПениГрейсПериода Переведено]							money
		, [ПениГрейсПериода Переведено нарастающим итогом]		money
		, [ГосПошлина Начислено]								money
		, [ГосПошлина Начислено нарастающим итогом]				money
		, [ГосПошлина Уплачено]									money
		, [ГосПошлина Уплачено нарастающим итогом]				money
		, [Переплата Начислено]									money
		, [Переплата Начислено нарастающим итогом]				money
		, [Переплата Уплачено]									money
		, [Переплата Уплачено нарастающим итогом]				money
		, ПроцентыПоГрафику										money
		, [ПроцентыПоГрафику нарастающим итогом]				money		
		, [ОД начислено без Сторно по акции]					money	
		, [ОД уплачено без Сторно по акции]						money	
		, [Проценты начислено без Сторно по акции]				money	
		, [Проценты уплачено без Сторно по акции]				money	
		, [Пени начислено без Сторно по акции]					money	
		, [Пени уплачено без Сторно по акции]					money	
		, [ГосПошлина начислено без Сторно по акции]			money	
		, [ГосПошлина уплачено без Сторно по акции]				money	
		, [Переплата начислено без Сторно по акции]				money	
		, [Переплата уплачено без Сторно по акции]				money
		
		
		, [Остаток всего]										money
		, [Остаток % расчетный]									money 
		, [prev_od]												money
			
		--вычисляемы поля
		--,[Остаток од]	as 	
		--	[ОДПоГрафику начислено]
		--	- [ОДПоГрафику уплачено] 
		--	+ [основной долг начислено] 
		--	- [основной долг уплачено]							PERSISTED

		,[Остаток од нарастающим итогом] as	
			[ОДПоГрафику начислено нарастающим итогом]
			- [ОДПоГрафику уплачено нарастающим итогом] 
			+ [основной долг начислено нарастающим итогом]
			- [основной долг уплачено нарастающим итогом]		PERSISTED
		--, [Остаток %]  as
		--	 [ПроцентыПоГрафику Начислено]
		--	-[ПроцентыПоГрафику Уплачено]
		--	+[Проценты Начислено]
		--	-[Проценты Уплачено]								PERSISTED

			
		, [Остаток % нарастающим итогом]  as
			[ПроцентыПоГрафику Начислено нарастающим итогом] 
			- [ПроцентыПоГрафику Уплачено нарастающим итогом]
			+ [Проценты Начислено нарастающим итогом]
			- [Проценты Уплачено нарастающим итогом]			PERSISTED

		,[Остаток иное (комиссии, пошлины и тд) нарастающим итогом] as 
			[ГосПошлина Начислено нарастающим итогом] 
			- [ГосПошлина Уплачено нарастающим итогом]			PERSISTED

		,[Остаток пени нарастающим итогом] as 
			[Пени Начислено нарастающим итогом] 
			- [Пени Уплачено нарастающим итогом]				PERSISTED
		,[Остаток пени расчетный нарастающим итогом]		as
			[Пени Начислено нарастающим итогом] 
			- [Пени Уплачено нарастающим итогом]
			+ [ПениГрейсПериода начислено нарастающим итогом] 
			+ [ПениГрейсПериода переведено нарастающим итогом] PERSISTED,

		[Остаток ПроцентыГрейсПериода нарастающим итогом] as
				[ПроцентыГрейсПериода начислено нарастающим итогом]  
				+ [ПроцентыГрейсПериода переведено нарастающим итогом] PERSISTED,

		
		--ДП (полное досрочное погашение)
		[ДП ОДПоГрафику Начислено] money NULL,
		[ДП ОДПоГрафику Уплачено] money NULL,
		[ДП ПроцентыПоГрафику Начислено] money NULL,
		[ДП ПроцентыПоГрафику Уплачено] money NULL,
		[ДП Основной долг Начислено] money NULL,
		[ДП Основной долг Уплачено] money NULL,
		[ДП Проценты Начислено] money NULL,
		[ДП Проценты Уплачено] money NULL,
		[ДП Пени Начислено] money NULL,
		[ДП Пени Уплачено] money NULL,
		[ДП ГосПошлина Начислено] money NULL,
		[ДП ГосПошлина Уплачено] money NULL,
		[ДП Переплата Начислено] money NULL,
		[ДП Переплата Уплачено] money NULL,

		--ЧДП (частичное досрочное погашение)
		[ЧДП ОДПоГрафику Начислено] money NULL,
		[ЧДП ОДПоГрафику Уплачено] money NULL,
		[ЧДП ПроцентыПоГрафику Начислено] money NULL,
		[ЧДП ПроцентыПоГрафику Уплачено] money NULL,
		[ЧДП Основной долг Начислено] money NULL,
		[ЧДП Основной долг Уплачено] money NULL,
		[ЧДП Проценты Начислено] money NULL,
		[ЧДП Проценты Уплачено] money NULL,
		[ЧДП Пени Начислено] money NULL,
		[ЧДП Пени Уплачено] money NULL,
		[ЧДП ГосПошлина Начислено] money NULL,
		[ЧДП ГосПошлина Уплачено] money NULL,
		[ЧДП Переплата Начислено] money NULL,
		[ЧДП Переплата Уплачено] money NULL
	)
	
	/*
	+ [ПениГрейсПериода начислено нарастающим итогом] 
						+ [ПениГрейсПериода переведено нарастающим итогом] 
	*/
	
	insert into #t_Расчеты with(TABLOCKX) (
		  Договор							
		, dt	
		, [ОДПоГрафику Начислено]								
		, [ОДПоГрафику Начислено нарастающим итогом]			
		, [ОДПоГрафику Уплачено]								
		, [ОДПоГрафику Уплачено нарастающим итогом]				
		, [ПроцентыПоГрафику Начислено]							
		, [ПроцентыПоГрафику Начислено нарастающим итогом]		
		, [ПроцентыПоГрафику Уплачено]							
		, [ПроцентыПоГрафику Уплачено нарастающим итогом]		
		, [Основной долг Начислено]								
		, [Основной долг Начислено нарастающим итогом]			
		, [Основной долг Уплачено]								
		, [Основной долг Уплачено нарастающим итогом]			
		, [Проценты Начислено]									
		, [Проценты Начислено нарастающим итогом]				
		, [Проценты Уплачено]									
		, [Проценты Уплачено нарастающим итогом]				
		, [ПроцентыГрейсПериода Начислено]						
		, [ПроцентыГрейсПериода Начислено нарастающим итогом]	
		, [ПроцентыГрейсПериода Уплачено]						
		, [ПроцентыГрейсПериода Уплачено нарастающим итогом]	
		, [ПроцентыГрейсПериода Переведено]						
		, [ПроцентыГрейсПериода Переведено нарастающим итогом]	
		, [Пени Начислено]										
		, [Пени Начислено нарастающим итогом]					
		, [Пени Уплачено]										
		, [Пени Уплачено нарастающим итогом]					
		, [ПениГрейсПериода Начислено]							
		, [ПениГрейсПериода Начислено нарастающим итогом]		
		, [ПениГрейсПериода Уплачено]							
		, [ПениГрейсПериода Уплачено нарастающим итогом]		
		, [ПениГрейсПериода Переведено]							
		, [ПениГрейсПериода Переведено нарастающим итогом]		
		, [ГосПошлина Начислено]								
		, [ГосПошлина Начислено нарастающим итогом]				
		, [ГосПошлина Уплачено]									
		, [ГосПошлина Уплачено нарастающим итогом]				
		, [Переплата Начислено]									
		, [Переплата Начислено нарастающим итогом]				
		, [Переплата Уплачено]									
		, [Переплата Уплачено нарастающим итогом]				
		, ПроцентыПоГрафику										
		, [ПроцентыПоГрафику нарастающим итогом]											
		, [ОД начислено без Сторно по акции]			
		, [ОД уплачено без Сторно по акции]				
		, [Проценты начислено без Сторно по акции]		
		, [Проценты уплачено без Сторно по акции]		
		, [Пени начислено без Сторно по акции]			
		, [Пени уплачено без Сторно по акции]			
		, [ГосПошлина начислено без Сторно по акции]	
		, [ГосПошлина уплачено без Сторно по акции]		
		, [Переплата начислено без Сторно по акции]		
		, [Переплата уплачено без Сторно по акции]		
		--ДП (полное досрочное погашение)
		, [ДП ОДПоГрафику Начислено]
		, [ДП ОДПоГрафику Уплачено]
		, [ДП ПроцентыПоГрафику Начислено]
		, [ДП ПроцентыПоГрафику Уплачено]
		, [ДП Основной долг Начислено]
		, [ДП Основной долг Уплачено]
		, [ДП Проценты Начислено]
		, [ДП Проценты Уплачено]
		, [ДП Пени Начислено]
		, [ДП Пени Уплачено]
		, [ДП ГосПошлина Начислено]
		, [ДП ГосПошлина Уплачено]
		, [ДП Переплата Начислено]
		, [ДП Переплата Уплачено]
		--ЧДП (частичное досрочное погашение)
		, [ЧДП ОДПоГрафику Начислено]
		, [ЧДП ОДПоГрафику Уплачено]
		, [ЧДП ПроцентыПоГрафику Начислено]
		, [ЧДП ПроцентыПоГрафику Уплачено]
		, [ЧДП Основной долг Начислено]
		, [ЧДП Основной долг Уплачено]
		, [ЧДП Проценты Начислено]
		, [ЧДП Проценты Уплачено]
		, [ЧДП Пени Начислено]
		, [ЧДП Пени Уплачено]
		, [ЧДП ГосПошлина Начислено]
		, [ЧДП ГосПошлина Уплачено]
		, [ЧДП Переплата Начислено]
		, [ЧДП Переплата Уплачено]
	)
	SELECT 
	  Договор
	, dt
	, [ОДПоГрафику Начислено]								=   sum([ОДПоГрафику Начислено])
	, [ОДПоГрафику Начислено нарастающим итогом]			=	sum(sum([ОДПоГрафику Начислено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           
	
	, [ОДПоГрафику Уплачено]								=	sum([ОДПоГрафику Уплачено])
	, [ОДПоГрафику Уплачено нарастающим итогом]				=	sum(sum([ОДПоГрафику Уплачено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           
	
	, [ПроцентыПоГрафику Начислено]							=	sum([ПроцентыПоГрафику Начислено])
	, [ПроцентыПоГрафику Начислено нарастающим итогом]		=	sum(sum([ПроцентыПоГрафику Начислено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           

	, [ПроцентыПоГрафику Уплачено]							=	sum([ПроцентыПоГрафику Уплачено])
	, [ПроцентыПоГрафику Уплачено нарастающим итогом]		=	sum(sum([ПроцентыПоГрафику Уплачено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           

	, [Основной долг Начислено]								=	sum([Основной долг Начислено])
	, [Основной долг Начислено нарастающим итогом]			=	sum(sum([Основной долг Начислено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           
	
	, [Основной долг Уплачено]								=	sum([Основной долг Уплачено])
	, [Основной долг Уплачено нарастающим итогом]			=	sum(sum([Основной долг Уплачено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           

	, [Проценты Начислено]									=	sum([Проценты Начислено])
	, [Проценты Начислено нарастающим итогом]				=	sum(sum([Проценты Начислено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           

	, [Проценты Уплачено]									=	sum([Проценты Уплачено])
	, [Проценты Уплачено нарастающим итогом]				=	sum(sum([Проценты Уплачено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           

	, [ПроцентыГрейсПериода Начислено]						=	sum([ПроцентыГрейсПериода Начислено])
	, [ПроцентыГрейсПериода Начислено нарастающим итогом]	=	sum(sum([ПроцентыГрейсПериода Начислено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           
		
	, [ПроцентыГрейсПериода Уплачено]						=	sum([ПроцентыГрейсПериода Уплачено])
	, [ПроцентыГрейсПериода Уплачено нарастающим итогом]	=	sum(sum([ПроцентыГрейсПериода Уплачено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           
	
	, [ПроцентыГрейсПериода Переведено]						=	sum([ПроцентыГрейсПериода переведено])
	, [ПроцентыГрейсПериода Переведено нарастающим итогом]	=	sum(sum([ПроцентыГрейсПериода переведено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           
	
	, [Пени Начислено]										=	sum([Пени Начислено])
	, [Пени Начислено нарастающим итогом]					=	sum(sum([Пени Начислено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           

	, [Пени Уплачено]										=	sum([Пени Уплачено])
	, [Пени Уплачено нарастающим итогом]					=	sum(sum([Пени Уплачено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           
	
	, [ПениГрейсПериода Начислено]							=	sum([ПениГрейсПериода Начислено])
	, [ПениГрейсПериода Начислено нарастающим итогом]		=	sum(sum([ПениГрейсПериода Начислено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           
	
	, [ПениГрейсПериода Уплачено]							=	sum([ПениГрейсПериода Уплачено])
	, [ПениГрейсПериода Уплачено нарастающим итогом]		=	sum(sum([ПениГрейсПериода Уплачено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           
	
	, [ПениГрейсПериода Переведено]							=	sum([ПениГрейсПериода переведено])
	, [ПениГрейсПериода Переведено нарастающим итогом]		=	sum(sum([ПениГрейсПериода переведено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           

	, [ГосПошлина Начислено]								=	sum([ГосПошлина Начислено])
	, [ГосПошлина Начислено нарастающим итогом]				=	sum(sum([ГосПошлина Начислено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           

	, [ГосПошлина Уплачено]									=	sum([ГосПошлина Уплачено])
	, [ГосПошлина Уплачено нарастающим итогом]				=	sum(sum([ГосПошлина Уплачено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           
	
	, [Переплата Начислено]									=	sum([Переплата Начислено])
	, [Переплата Начислено нарастающим итогом]				=	sum(sum([Переплата Начислено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           

	, [Переплата Уплачено]									=	sum([Переплата Уплачено])
	, [Переплата Уплачено нарастающим итогом]				=	sum(sum([Переплата Уплачено])) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           
	
	, ПроцентыПоГрафику										=	sum(ПроцентыПоГрафику)
	, [ПроцентыПоГрафику нарастающим итогом]				=	sum(sum(ПроцентыПоГрафику)) over (partition by Договор  order by dt  rows between unbounded preceding and current row)                           

	, [ОД начислено без Сторно по акции]					=	sum([ОД начислено без Сторно по акции])
	, [ОД уплачено без Сторно по акции]						=	sum([ОД уплачено без Сторно по акции])
	  
	, [Проценты начислено без Сторно по акции]				=	sum([Проценты начислено без Сторно по акции])
	, [Проценты уплачено без Сторно по акции]				=	sum([Проценты уплачено без Сторно по акции])
	, [Пени начислено без Сторно по акции]					=	sum([Пени начислено без Сторно по акции])
	, [Пени уплачено без Сторно по акции]					=	sum([Пени уплачено без Сторно по акции])
	, [ГосПошлина начислено без Сторно по акции]			=	sum([ГосПошлина начислено без Сторно по акции])
	, [ГосПошлина уплачено без Сторно по акции]				=	sum([ГосПошлина уплачено без Сторно по акции])
	, [Переплата начислено без Сторно по акции]				=	sum([Переплата начислено без Сторно по акции])
	, [Переплата уплачено без Сторно по акции]				=	sum([Переплата уплачено без Сторно по акции])

	--ДП (полное досрочное погашение)
	, [ДП ОДПоГрафику Начислено]							= sum(t.[ДП ОДПоГрафику Начислено])
	, [ДП ОДПоГрафику Уплачено]								= sum(t.[ДП ОДПоГрафику Уплачено])
	, [ДП ПроцентыПоГрафику Начислено]						= sum(t.[ДП ПроцентыПоГрафику Начислено])
	, [ДП ПроцентыПоГрафику Уплачено]						= sum(t.[ДП ПроцентыПоГрафику Уплачено])
	, [ДП Основной долг Начислено]							= sum(t.[ДП Основной долг Начислено])
	, [ДП Основной долг Уплачено]							= sum(t.[ДП Основной долг Уплачено])
	, [ДП Проценты Начислено] 								= sum(t.[ДП Проценты Начислено])
	, [ДП Проценты Уплачено] 								= sum(t.[ДП Проценты Уплачено])
	, [ДП Пени Начислено] 									= sum(t.[ДП Пени Начислено])
	, [ДП Пени Уплачено] 									= sum(t.[ДП Пени Уплачено])
	, [ДП ГосПошлина Начислено]								= sum(t.[ДП ГосПошлина Начислено])
	, [ДП ГосПошлина Уплачено] 								= sum(t.[ДП ГосПошлина Уплачено])
	, [ДП Переплата Начислено] 								= sum(t.[ДП Переплата Начислено])
	, [ДП Переплата Уплачено] 								= sum(t.[ДП Переплата Уплачено])

	--ЧДП (частичное досрочное погашение)
	, [ЧДП ОДПоГрафику Начислено]							= sum(t.[ЧДП ОДПоГрафику Начислено])
	, [ЧДП ОДПоГрафику Уплачено]							= sum(t.[ЧДП ОДПоГрафику Уплачено])
	, [ЧДП ПроцентыПоГрафику Начислено]						= sum(t.[ЧДП ПроцентыПоГрафику Начислено])
	, [ЧДП ПроцентыПоГрафику Уплачено]						= sum(t.[ЧДП ПроцентыПоГрафику Уплачено])
	, [ЧДП Основной долг Начислено]							= sum(t.[ЧДП Основной долг Начислено])
	, [ЧДП Основной долг Уплачено]							= sum(t.[ЧДП Основной долг Уплачено])
	, [ЧДП Проценты Начислено] 								= sum(t.[ЧДП Проценты Начислено])
	, [ЧДП Проценты Уплачено] 								= sum(t.[ЧДП Проценты Уплачено])
	, [ЧДП Пени Начислено] 									= sum(t.[ЧДП Пени Начислено])
	, [ЧДП Пени Уплачено] 									= sum(t.[ЧДП Пени Уплачено])
	, [ЧДП ГосПошлина Начислено]							= sum(t.[ЧДП ГосПошлина Начислено])
	, [ЧДП ГосПошлина Уплачено] 							= sum(t.[ЧДП ГосПошлина Уплачено])
	, [ЧДП Переплата Начислено] 							= sum(t.[ЧДП Переплата Начислено])
	, [ЧДП Переплата Уплачено] 								= sum(t.[ЧДП Переплата Уплачено])
	from (
	select 
		  cc.Договор
		, dt											=	cc.dt
	--	, РасчетыПоЗаймам_Договор						=   rpz.Договор
	--	, РасчетыПоЗаймам_dt							=	cast(rpz.Период_2000 as date)
		, [ОДПоГрафику Начислено]						=	iif(ВидДвижения = 0,	ОДПоГрафику,				0) 
		, [ОДПоГрафику Уплачено]						=	iif(ВидДвижения = 1,	ОДПоГрафику,				0) 
		, [ПроцентыПоГрафику Начислено]					=	iif(ВидДвижения = 0,	ПроцентыПоГрафику,			0) 
		, [ПроцентыПоГрафику Уплачено]					=	iif(ВидДвижения = 1,	ПроцентыПоГрафику,			0) 
		, [Основной долг Начислено]						=	iif(ВидДвижения = 0,	ОДНачисленоУплачено,		0) 
		, [Основной долг Уплачено]						=	iif(ВидДвижения = 1,	ОДНачисленоУплачено,		0) 
		, [Проценты Начислено]							=	iif(ВидДвижения = 0,	ПроцентыНачисленоУплачено,	0) 
		, [Проценты Уплачено]							=	iif(ВидДвижения = 1,	ПроцентыНачисленоУплачено,	0) 
		, [ПроцентыГрейсПериода Начислено]				=	iif(ВидДвижения = 0,	ПроцентыГрейсПериода,		0) 
		, [ПроцентыГрейсПериода Уплачено]				=	iif(ВидДвижения = 1,	ПроцентыГрейсПериода,		0) 
		, [ПроцентыГрейсПериода переведено]				=	iif(ВидДвижения = 1 , -ПроцентыГрейсПериода,		0) 
		, [Пени Начислено]								=	iif(ВидДвижения = 0,	ПениНачисленоУплачено,		0) 
		, [Пени Уплачено]								=	iif(ВидДвижения = 1,	ПениНачисленоУплачено,		0) 
	
		, [ПениГрейсПериода Начислено]					=	iif(ВидДвижения = 0,	ПениГрейсПериода,			0) 
		, [ПениГрейсПериода Уплачено]					=	iif(ВидДвижения = 1,	ПениГрейсПериода,			0) 
		, [ПениГрейсПериода переведено]					=	iif(ВидДвижения = 1 ,	-ПениГрейсПериода,			0) 
		, [ГосПошлина Начислено]						=	iif(ВидДвижения = 0,	ГосПошлина,					0) 
		, [ГосПошлина Уплачено]							=	iif(ВидДвижения = 1,	ГосПошлина,					0) 
		, [Переплата Начислено]							=	iif(ВидДвижения = 0,	Переплата,					0) 
		, [Переплата Уплачено]							=	iif(ВидДвижения = 1,	Переплата,					0) 
		, ПроцентыПоГрафику								=	isnull(iif(ВидДвижения = 0,	ПроцентыПоГрафику, -ПроцентыПоГрафику),0)

		, [ОД начислено без Сторно по акции]			=	iif(ВидДвижения = 0 AND rpz.ХозяйственнаяОперация not in (0xB81200155D4D085911E944418439AF38), ОДНачисленоУплачено, 0 )
		, [ОД уплачено без Сторно по акции]				=	iif(ВидДвижения = 1 AND rpz.ХозяйственнаяОперация not in (0xB81200155D4D085911E944418439AF38), ОДНачисленоУплачено, 0)
	  
		, [Проценты начислено без Сторно по акции]		=	iif(ВидДвижения = 0 AND rpz.ХозяйственнаяОперация not in (0xB81200155D4D085911E944418439AF38), ПроцентыНачисленоУплачено, 0)
		, [Проценты уплачено без Сторно по акции]		=	iif(ВидДвижения = 1 AND rpz.ХозяйственнаяОперация not in (0xB81200155D4D085911E944418439AF38), ПроцентыНачисленоУплачено, 0)
		, [Пени начислено без Сторно по акции]			=	iif(ВидДвижения = 0 AND rpz.ХозяйственнаяОперация not in (0xB81200155D4D085911E944418439AF38), ПениНачисленоУплачено, 0 )
		, [Пени уплачено без Сторно по акции]			=	iif(ВидДвижения = 1 AND rpz.ХозяйственнаяОперация not in (0xB81200155D4D085911E944418439AF38), ПениНачисленоУплачено, 0)
		, [ГосПошлина начислено без Сторно по акции]	=	iif(ВидДвижения = 0 AND rpz.ХозяйственнаяОперация not in (0xB81200155D4D085911E944418439AF38), ГосПошлина ,0)
		, [ГосПошлина уплачено без Сторно по акции]		=	iif(ВидДвижения = 1 AND rpz.ХозяйственнаяОперация not in (0xB81200155D4D085911E944418439AF38), ГосПошлина ,0)
		, [Переплата начислено без Сторно по акции]		=	iif(ВидДвижения = 0 AND rpz.ХозяйственнаяОперация not in (0xB81200155D4D085911E944418439AF38), Переплата ,0)
		, [Переплата уплачено без Сторно по акции]		=	iif(ВидДвижения = 1 AND rpz.ХозяйственнаяОперация not in (0xB81200155D4D085911E944418439AF38), Переплата ,0)

		--ДП (полное досрочное погашение)
		, [ДП ОДПоГрафику Начислено] = iif(rpz.ВидДвижения = 0 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B83), rpz.ОДПоГрафику, 0)
		, [ДП ОДПоГрафику Уплачено] = iif(rpz.ВидДвижения = 1 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B83), rpz.ОДПоГрафику, 0)
		, [ДП ПроцентыПоГрафику Начислено] = iif(rpz.ВидДвижения = 0 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B83), rpz.ПроцентыПоГрафику, 0)
		, [ДП ПроцентыПоГрафику Уплачено] = iif(rpz.ВидДвижения = 1 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B83), rpz.ПроцентыПоГрафику, 0)
		, [ДП Основной долг Начислено] = iif(rpz.ВидДвижения = 0 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B83), rpz.ОДНачисленоУплачено, 0)
		, [ДП Основной долг Уплачено] = iif(rpz.ВидДвижения = 1 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B83), rpz.ОДНачисленоУплачено, 0)
		, [ДП Проценты Начислено] = iif(rpz.ВидДвижения = 0 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B83), rpz.ПроцентыНачисленоУплачено, 0)
		, [ДП Проценты Уплачено] = iif(rpz.ВидДвижения = 1 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B83), rpz.ПроцентыНачисленоУплачено, 0)
		, [ДП Пени Начислено] = iif(rpz.ВидДвижения = 0 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B83), rpz.ПениНачисленоУплачено, 0)
		, [ДП Пени Уплачено] = iif(rpz.ВидДвижения = 1 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B83), rpz.ПениНачисленоУплачено, 0)
		, [ДП ГосПошлина Начислено] = iif(rpz.ВидДвижения = 0 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B83), rpz.ГосПошлина, 0)
		, [ДП ГосПошлина Уплачено] = iif(rpz.ВидДвижения = 1 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B83), rpz.ГосПошлина, 0)
		, [ДП Переплата Начислено] = iif(rpz.ВидДвижения = 0 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B83), rpz.Переплата, 0)
		, [ДП Переплата Уплачено] = iif(rpz.ВидДвижения = 1 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B83), rpz.Переплата, 0)

		--ЧДП (частичное досрочное погашение)
		, [ЧДП ОДПоГрафику Начислено] = iif(rpz.ВидДвижения = 0 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B8F), rpz.ОДПоГрафику, 0)
		, [ЧДП ОДПоГрафику Уплачено] = iif(rpz.ВидДвижения = 1 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B8F), rpz.ОДПоГрафику, 0)
		, [ЧДП ПроцентыПоГрафику Начислено] = iif(rpz.ВидДвижения = 0 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B8F), rpz.ПроцентыПоГрафику, 0)
		, [ЧДП ПроцентыПоГрафику Уплачено] = iif(rpz.ВидДвижения = 1 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B8F), rpz.ПроцентыПоГрафику, 0)
		, [ЧДП Основной долг Начислено] = iif(rpz.ВидДвижения = 0 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B8F), rpz.ОДНачисленоУплачено, 0)
		, [ЧДП Основной долг Уплачено] = iif(rpz.ВидДвижения = 1 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B8F), rpz.ОДНачисленоУплачено, 0)
		, [ЧДП Проценты Начислено] = iif(rpz.ВидДвижения = 0 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B8F), rpz.ПроцентыНачисленоУплачено, 0)
		, [ЧДП Проценты Уплачено] = iif(rpz.ВидДвижения = 1 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B8F), rpz.ПроцентыНачисленоУплачено, 0)
		, [ЧДП Пени Начислено] = iif(rpz.ВидДвижения = 0 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B8F), rpz.ПениНачисленоУплачено, 0)
		, [ЧДП Пени Уплачено] = iif(rpz.ВидДвижения = 1 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B8F), rpz.ПениНачисленоУплачено, 0)
		, [ЧДП ГосПошлина Начислено] = iif(rpz.ВидДвижения = 0 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B8F), rpz.ГосПошлина, 0)
		, [ЧДП ГосПошлина Уплачено] = iif(rpz.ВидДвижения = 1 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B8F), rpz.ГосПошлина, 0)
		, [ЧДП Переплата Начислено] = iif(rpz.ВидДвижения = 0 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B8F), rpz.Переплата, 0)
		, [ЧДП Переплата Уплачено] = iif(rpz.ВидДвижения = 1 AND rpz.ХозяйственнаяОперация in (0x80D900155D64100111E78663D3A87B8F), rpz.Переплата, 0)

	FROM #Contract_calendar cc
	left join stg._1Ccmr.РегистрНакопления_РасчетыПоЗаймам AS rpz
		on rpz.Договор  = cc.Договор
			and cast(rpz.Период_2000 as date) = cc.dt
			and stg.$partition.pfn_range_right_date_part_РегистрНакопления_РасчетыПоЗаймам(rpz.Период_2000)
				=	stg.$partition.pfn_range_right_date_part_РегистрНакопления_РасчетыПоЗаймам(cc.dt)
		--where exists(select top(1) 1 from #CalculationContracts AS Y
		--		where Y.Ссылка = rpz.Договор
		--		and (@isAllPeriod = 1 or (cast(dateadd(year,-2000,rpz.Период) as date) >=y.DateStart and @isAllPeriod =0))
		--		)
	
	union all
	--iif(ВидДвижения =1, -1.0*[ОД], [ОД] ) 	 до момента решения дефекта на цмр , после вернуть на формулу iif(ВидДвижения =0, [ОД] )  + остальной коммент раскомментировать https://jira.carmoney.ru/browse/CMR-3737
	select 
		  cc.Договор
		, dt											=	cc.dt
		, [ОДПоГрафику Начислено]						=	0				
		, [ОДПоГрафику Уплачено]						=	0				
		, [ПроцентыПоГрафику Начислено]					=	0	 
		, [ПроцентыПоГрафику Уплачено]					=	0	
		, [Основной долг Начислено]						=	iif(ВидДвижения =1, -1.0*[ОД], [ОД] ) 				 
		, [Основной долг Уплачено]						=	0--iif(ВидДвижения = 1,	[ОД],		0) 				 
		, [Проценты Начислено]							=	iif(ВидДвижения =1, -1.0*[Проценты], [Проценты] ) 
		, [Проценты Уплачено]							=	0--iif(ВидДвижения = 1,	[Проценты],	0) 				  
		, [ПроцентыГрейсПериода Начислено]				=	0
		, [ПроцентыГрейсПериода Уплачено]				=	0
		, [ПроцентыГрейсПериода переведено]				=	0
		, [Пени Начислено]								=	iif(ВидДвижения =1, -1.0*[Пени], [Пени] ) 
		, [Пени Уплачено]								=	0 --iif(ВидДвижения = 1,	[Пени],		0) 				 
		, [ПениГрейсПериода Начислено]					=	0
		, [ПениГрейсПериода Уплачено]					=	0
		, [ПениГрейсПериода переведено]					=	0
		, [ГосПошлина Начислено]						=	iif(ВидДвижения =1, -1.0*[Госпошлина], [Госпошлина] )  
		, [ГосПошлина Уплачено]							=	0--iif(ВидДвижения = 1,	[Госпошлина], 0) 			
		, [Переплата Начислено]							=	0
		, [Переплата Уплачено]							=	0
		, ПроцентыПоГрафику								=	0
		, [ОД начислено без Сторно по акции]			=   iif(ВидДвижения =1, -1.0*[ОД], [ОД] )  
		, [ОД уплачено без Сторно по акции]				=   0--iif(ВидДвижения = 1,	[ОД],		0) 
		, [Проценты начислено без Сторно по акции]		=   iif(ВидДвижения =1, -1.0*[Проценты], [Проценты] ) 
		, [Проценты уплачено без Сторно по акции]		=   0--iif(ВидДвижения = 1,	[Проценты],	0) 		
		, [Пени начислено без Сторно по акции]			=   iif(ВидДвижения =1, -1.0*[Пени], [Пени] ) 
		, [Пени уплачено без Сторно по акции]			=   0--iif(ВидДвижения = 1,	[Пени],		0)
		, [ГосПошлина начислено без Сторно по акции]	=   iif(ВидДвижения =1, -1.0*[Госпошлина], [Госпошлина] ) 
		, [ГосПошлина уплачено без Сторно по акции]		=   0--iif(ВидДвижения = 1,	[Госпошлина],					0) 	
		, [Переплата начислено без Сторно по акции]		=   0
		, [Переплата уплачено без Сторно по акции]		=   0
		--ДП (полное досрочное погашение)
		, [ДП ОДПоГрафику Начислено] = 0
		, [ДП ОДПоГрафику Уплачено] = 0
		, [ДП ПроцентыПоГрафику Начислено] = 0
		, [ДП ПроцентыПоГрафику Уплачено] = 0
		, [ДП Основной долг Начислено] = 0
		, [ДП Основной долг Уплачено] = 0
		, [ДП Проценты Начислено] = 0
		, [ДП Проценты Уплачено] = 0
		, [ДП Пени Начислено] = 0
		, [ДП Пени Уплачено] = 0
		, [ДП ГосПошлина Начислено] = 0
		, [ДП ГосПошлина Уплачено] = 0
		, [ДП Переплата Начислено] = 0
		, [ДП Переплата Уплачено] = 0
		--ЧДП (частичное досрочное погашение)
		, [ЧДП ОДПоГрафику Начислено] = 0
		, [ЧДП ОДПоГрафику Уплачено] = 0
		, [ЧДП ПроцентыПоГрафику Начислено] = 0
		, [ЧДП ПроцентыПоГрафику Уплачено] = 0
		, [ЧДП Основной долг Начислено] = 0
		, [ЧДП Основной долг Уплачено] = 0
		, [ЧДП Проценты Начислено] = 0
		, [ЧДП Проценты Уплачено] = 0
		, [ЧДП Пени Начислено] = 0
		, [ЧДП Пени Уплачено] = 0
		, [ЧДП ГосПошлина Начислено] = 0
		, [ЧДП ГосПошлина Уплачено] = 0
		, [ЧДП Переплата Начислено] = 0
		, [ЧДП Переплата Уплачено] = 0
	FROM #Contract_calendar cc
	inner join stg.[_1cCMR].[РегистрНакопления_УчетСуммПоРешениюСуда] rpz
		on rpz.Договор  = cc.Договор
			and cast(rpz.Период_2000 as date) = cc.dt
		--group by 
		-- cc.Договор
		--, dt											=	cc.dt
		--, РасчетыПоЗаймам_Договор						=   rpz.Договор
		--, РасчетыПоЗаймам_dt							=	cast(rpz.Период_2000 as date)
	
	) t
	
	group by 
	  Договор
	, dt

	OPTION(HASH JOIN)
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'insert into #t_Расчеты'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description

		DROP TABLE IF EXISTS ##t_Расчеты
		SELECT * INTO ##t_Расчеты FROM #t_Расчеты

	END

	select @StartDate = getdate()
	CREATE CLUSTERED INDEX cix_Договор_dt ON #t_Расчеты(Договор, dt) with(MAXDOP=8)
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'CREATE CLUSTERED INDEX ix_Договор_Период'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END

	select @StartDate = getdate()

	;with cte_Расчеты as
	(
		select 
			Договор
			,dt
			,[Остаток % расчетный]
			,[Остаток всего]
			,[_Остаток % расчетный] = 	
				[остаток % нарастающим итогом]
				+ [Остаток ПроцентыГрейсПериода нарастающим итогом]
			,[_остаток всего] =
						  [остаток од нарастающим итогом]
						+ [остаток % нарастающим итогом]
						+ [Остаток пени расчетный нарастающим итогом]
						+ [остаток иное (комиссии, пошлины и тд) нарастающим итогом] --b2.[ГосПошлинаНачислено  нарастающим итогом] - b2.[ГосПошлинаУплачено  нарастающим итогом]
						+ [Остаток ПроцентыГрейсПериода нарастающим итогом] --b2.[ПроцентыГрейсПериода начислено нарастающим итогом]  + b2.[ПроцентыГрейсПериода переведено нарастающим итогом]
			,prev_od
			,_prev_od = lag([остаток од нарастающим итогом], 1, 0) over(partition by Договор order by dt)
		from #t_Расчеты 
	)
	update cte_Расчеты 
		set [Остаток % расчетный] = [_Остаток % расчетный]
			,[остаток всего] = [_остаток всего]
			,prev_od = _prev_od	
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		--SELECT 'INSERT #new_b2', @row_count, datediff(SECOND, @StartDate, getdate())
		SELECT @duration = datediff(SECOND, @StartDate, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'update #t_Расчеты set *Остаток'
		SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END
	begin tran
		SELECT @StartDate = getdate()
		if @Mode = 0
		begin
		 truncate table dbo.dm_CMRStatBalance
		 SELECT @row_count = @@ROWCOUNT
		end
		else
		begin
		
			DELETE B 
			FROM dbo.dm_CMRStatBalance AS B
			where exists(select top(1) 1 from #CalculationContracts AS Y
					where B.external_id = Y.external_id
					and 
					$partition.[pfn_range_right_externalId_mode_16_part_dm_CMRStatBalance](b.[partitionID])
						= $partition.[pfn_range_right_externalId_mode_16_part_dm_CMRStatBalance](cast(isnull(try_cast(Y.external_id as bigint),0) %16 as smallint))
					)
			OPTION (QUERYTRACEON 610)
			SELECT @row_count = @@ROWCOUNT
		end
		IF @isDebug = 1 BEGIN
			--SELECT 'DELETE dbo.dm_CMRStatBalance', @row_count, datediff(SECOND, @StartDate, getdate())
			SELECT @duration = datediff(SECOND, @StartDate, getdate())
			SELECT @event_step_number = @event_step_number + 1
				, @event_step_type = 'DELETE dbo.dm_CMRStatBalance'
			SELECT @event_message = concat('Удалено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
			SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
			EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
				@logger_name, @process_guid, @event_level, @event_type, @event_name, 
				@event_step_number, @event_step_type, @event_step_name, @event_status, 
				@event_message, @event_description
		end
		


		
	/*
	alter table dbo.dm_CMRStatBalance
		add CMRContractsGUID nvarchar(36)
		*/
	/*
	alter table dbo.dm_CMRStatBalance
		alter column [Проценты начислено (dpdmore360)] money null  

	alter table dbo.dm_CMRStatBalance
		add dpdMFO_begin_day	smallint								
				,overdue_begin_day		 money			
	alter table dbo.dm_CMRStatBalance
		add bucket_last_p_coll nvarchar(255)
	
		*/
			insert into dbo.dm_CMRStatBalance
		--WITH(TABLOCKX)
			(
				[DWHInsertedDate]	
				,[d]													
				,[ContractStartDate]									
				,[external_id]											
				,[Сумма]												
				,[СуммаДопПродуктов]									
				,[Срок]												
				,[ПроцентнаяСтавка]									
				,[Точка]												
				,[основной долг начислено]								
				,[основной долг уплачено]								
				,[Проценты начислено]									
				,[Проценты уплачено]									
				,[ПениНачислено]										
				,[ПениУплачено]										
				,[ГосПошлинаНачислено]									
				,[ГосПошлинаУплачено]									
				,[ПереплатаНачислено]									
				,[ПереплатаУплачено]									
				,[ОД начислено без Сторно по акции]					
				,[ОД уплачено без Сторно по акции]						
				,[Проценты начислено без Сторно по акции]				
				,[Проценты уплачено без Сторно по акции]				
				,[Пени начислено без Сторно по акции]					
				,[Пени уплачено без Сторно по акции]					
				,[ГосПошлина начислено без Сторно по акции]			
				,[ГосПошлина уплачено без Сторно по акции]				
				,[Переплата начислено без Сторно по акции]				
				,[Переплата уплачено без Сторно по акции]				
				,[остаток од]											
				,[остаток %]											
				,[остаток пени]										
				,[остаток иное (комиссии, пошлины и тд)]				
				,[остаток всего]										
				,[сумма поступлений]									
				,[ПлатежнаяСистема]									
				,[сумма поступлений  нарастающим итогом]				
				,[основной долг начислено нарастающим итогом]			
				,[основной долг уплачено нарастающим итогом]			
				,[Проценты начислено  нарастающим итогом]				
				,[ПениНачислено  нарастающим итогом]					
				,[ГосПошлинаНачислено  нарастающим итогом]				
				,[Проценты уплачено  нарастающим итогом]				
				,[ПениУплачено  нарастающим итогом]					
				,[ГосПошлинаУплачено  нарастающим итогом]				
				,[ПереплатаНачислено нарастающим итогом]				
				,[ПереплатаУплачено нарастающим итогом]				
				,[ПроцентыПоГрафику]									
				,[ПроцентыПоГрафикуНарастающимИтогом]					
				,[ПроцентыГрейсПериода начислено]						
				,[ПроцентыГрейсПериода начислено нарастающим итогом]	
				,[ПроцентыГрейсПериода переведено]						
				,[ПроцентыГрейсПериода переведено нарастающим итогом]	
				,[ПениГрейсПериода начислено]							
				,[ПениГрейсПериода начислено нарастающим итогом]		
				,[ПениГрейсПериода переведено]							
				,[ПениГрейсПериода переведено нарастающим итогом]		
				,[dpd]													
				,[dpdMFO]												
				,[overdue]												
				,[bucket]												
				,[ContractEndDate]										
				,[dpd day-1]											
				,[Расчетный остаток всего]								
				,[ПроцентнаяСтавкаНаТекущийДень]						
				,[Остаток % расчетный]									
				,[Остаток пени расчетный]								
				,[dpd_begin_day]										
				,[dpd_coll]											
				,[dpd_p_coll]											
				,[_dpd_last_coll]										
				,[bucket_coll]											
				,[bucket_p_coll]										
				,[dpd_last_coll]										
				,[bucket_last_coll]									
				,[prev_dpd_coll]										
				,[prev_dpd_p_coll]
				,bucket_last_p_coll
				,[prev_od]												
				,[Тип Продукта]										
				,[CMRClientGUID]										
				,CMRContractsGUID		
				,dpdMFO_begin_day										
				,overdue_begin_day										

				--ДП (полное досрочное погашение)
				, [ДП ОДПоГрафику Начислено]
				, [ДП ОДПоГрафику Уплачено]
				, [ДП ПроцентыПоГрафику Начислено]
				, [ДП ПроцентыПоГрафику Уплачено]
				, [ДП Основной долг Начислено]
				, [ДП Основной долг Уплачено]
				, [ДП Проценты Начислено]
				, [ДП Проценты Уплачено]
				, [ДП Пени Начислено]
				, [ДП Пени Уплачено]
				, [ДП ГосПошлина Начислено]
				, [ДП ГосПошлина Уплачено]
				, [ДП Переплата Начислено]
				, [ДП Переплата Уплачено]

				--ЧДП (частичное досрочное погашение)
				, [ЧДП ОДПоГрафику Начислено]
				, [ЧДП ОДПоГрафику Уплачено]
				, [ЧДП ПроцентыПоГрафику Начислено]
				, [ЧДП ПроцентыПоГрафику Уплачено]
				, [ЧДП Основной долг Начислено]
				, [ЧДП Основной долг Уплачено]
				, [ЧДП Проценты Начислено]
				, [ЧДП Проценты Уплачено]
				, [ЧДП Пени Начислено]
				, [ЧДП Пени Уплачено]
				, [ЧДП ГосПошлина Начислено]
				, [ЧДП ГосПошлина Уплачено]
				, [ЧДП Переплата Начислено]
				, [ЧДП Переплата Уплачено]
			)
			select 
			[DWHInsertedDate]										= getdate()		
			, [d]													= cc.dt
			, [ContractStartDate]									= c.ContractStartDate
			, [external_id]											= c.[external_id]
			, [Сумма]												= c.Сумма
			, [СуммаДопПродуктов]									= c.СуммаДопПродуктов
			, [Срок]												= c.Срок
			, [ПроцентнаяСтавка]									= c.ПроцентнаяСтавка
			, [Точка]												= c.Точка
			, [основной долг начислено]								= p.[основной долг начислено]
			, [основной долг уплачено]								= p.[основной долг уплачено]
			, [Проценты начислено]									= p.[Проценты начислено]
			, [Проценты уплачено]									= p.[Проценты уплачено]
			, [ПениНачислено]										= p.[Пени Начислено]
			, [ПениУплачено]										= p.[Пени Уплачено]
			, [ГосПошлинаНачислено]									= p.[ГосПошлина Начислено]
			, [ГосПошлинаУплачено]									= p.[ГосПошлина Уплачено]
			, [ПереплатаНачислено]									= p.[Переплата Начислено]
			, [ПереплатаУплачено]									= p.[Переплата Уплачено]
			, [ОД начислено без Сторно по акции]					= p.[ОД начислено без Сторно по акции]
			, [ОД уплачено без Сторно по акции]						= p.[ОД уплачено без Сторно по акции]
			, [Проценты начислено без Сторно по акции]				= p.[Проценты начислено без Сторно по акции]
			, [Проценты уплачено без Сторно по акции]				= p.[Проценты уплачено без Сторно по акции]
			, [Пени начислено без Сторно по акции]					= p.[Пени начислено без Сторно по акции]
			, [Пени уплачено без Сторно по акции]					= p.[Пени уплачено без Сторно по акции]
			, [ГосПошлина начислено без Сторно по акции]			= p.[ГосПошлина начислено без Сторно по акции]
			, [ГосПошлина уплачено без Сторно по акции]				= p.[ГосПошлина уплачено без Сторно по акции]
			, [Переплата начислено без Сторно по акции]				= p.[Переплата начислено без Сторно по акции]
			, [Переплата уплачено без Сторно по акции]				= p.[Переплата уплачено без Сторно по акции]
			, [остаток од]											= p.[остаток од нарастающим итогом]
			, [остаток %]											= p.[остаток % нарастающим итогом]
			, [остаток пени]										= p.[остаток пени нарастающим итогом]
			, [остаток иное (комиссии, пошлины и тд)]				= p.[остаток иное (комиссии, пошлины и тд) нарастающим итогом]
			, [остаток всего]										= p.[остаток всего]
			, [сумма поступлений]									= pay.Summ
			, [ПлатежнаяСистема]									= pay.payment_system
			, [сумма поступлений  нарастающим итогом]				= pay.summTotal
			, [основной долг начислено нарастающим итогом]			= p.[основной долг начислено нарастающим итогом]
			, [основной долг уплачено нарастающим итогом]			= p.[основной долг уплачено нарастающим итогом]
			, [Проценты начислено  нарастающим итогом]				= p.[Проценты начислено нарастающим итогом]
			, [ПениНачислено  нарастающим итогом]					= p.[Пени Начислено нарастающим итогом]
			, [ГосПошлинаНачислено  нарастающим итогом]				= p.[ГосПошлина Начислено нарастающим итогом]
			, [Проценты уплачено  нарастающим итогом]				= p.[Проценты уплачено нарастающим итогом]
			, [ПениУплачено  нарастающим итогом]					= p.[Пени Уплачено нарастающим итогом]
			, [ГосПошлинаУплачено  нарастающим итогом]				= p.[ГосПошлина Уплачено нарастающим итогом]
			, [ПереплатаНачислено нарастающим итогом]				= p.[Переплата Начислено нарастающим итогом]
			, [ПереплатаУплачено нарастающим итогом]				= p.[Переплата Уплачено нарастающим итогом]
			, [ПроцентыПоГрафику]									= p.[ПроцентыПоГрафику]									
			, [ПроцентыПоГрафикуНарастающимИтогом]					= p.[ПроцентыПоГрафику Нарастающим Итогом]					
			, [ПроцентыГрейсПериода начислено]						= p.[ПроцентыГрейсПериода начислено]						
			, [ПроцентыГрейсПериода начислено нарастающим итогом]	= p.[ПроцентыГрейсПериода начислено нарастающим итогом]	
			, [ПроцентыГрейсПериода переведено]						= p.[ПроцентыГрейсПериода переведено]						
			, [ПроцентыГрейсПериода переведено нарастающим итогом]	= p.[ПроцентыГрейсПериода переведено нарастающим итогом]	
			, [ПениГрейсПериода начислено]							= p.[ПениГрейсПериода начислено]							
			, [ПениГрейсПериода начислено нарастающим итогом]		= p.[ПениГрейсПериода начислено нарастающим итогом]		
			, [ПениГрейсПериода переведено]							= p.[ПениГрейсПериода переведено]							
			, [ПениГрейсПериода переведено нарастающим итогом]		= p.[ПениГрейсПериода переведено нарастающим итогом]		
			, [dpd]													= ap.dpd
			, [dpdMFO]												= ap.[dpdMFO]
			, [overdue]												= ap.[overdue]
			, [bucket]												= ap.[bucket]
			, [ContractEndDate]										= c.ContractEndDate
			, [dpd day-1]											= ap.[dpd day-1]
			, [Расчетный остаток всего]								= isnull(p.[остаток од нарастающим итогом],0) 
																			+ isnull(p.[Остаток % расчетный], 0 ) 
																			+ isnull(p.[Остаток пени расчетный нарастающим итогом] ,0) 
																			+ isnull(p.[остаток иное (комиссии, пошлины и тд) нарастающим итогом] ,0)
			, [ПроцентнаяСтавкаНаТекущийДень]						= ПроцентнаяСтавка.[ПроцентнаяСтавкаНаТекущийДень]
			, [Остаток % расчетный]									= p.[Остаток % расчетный]
			, [Остаток пени расчетный]								= p.[Остаток пени расчетный нарастающим итогом]
			, [dpd_begin_day]										= ap.[dpd_begin_day]
			, [dpd_coll]											= ap.[dpd_coll]
			, [dpd_p_coll]											= ap.[dpd_p_coll]
			, [_dpd_last_coll]										= ap.[_dpd_last_coll]
			, [bucket_coll]											= ap.[bucket_coll]
			, [bucket_p_coll]										= ap.[bucket_p_coll]
			, [dpd_last_coll]										= ap.dpd_last_coll
			, [bucket_last_coll]									= ap.bucket_last_coll
			, [prev_dpd_coll]										= ap.prev_dpd_coll
			, [prev_dpd_p_coll]										= ap.[prev_dpd_p_coll]
			, [bucket_last_p_coll]									= ap.bucket_last_p_coll
			, [prev_od]												= p.prev_od 
			, [Тип Продукта]										= c.[Тип Продукта]
			, [CMRClientGUID]										= c.[CMRClientGUID]
			, CMRContractsGUID										= c.CMRContractsGUID
			, dpdMFO_begin_day										= ap.dpdMFO_begin_day
			, overdue_begin_day										= ap.overdue_begin_day
			--ДП (полное досрочное погашение)
			, p.[ДП ОДПоГрафику Начислено]
			, p.[ДП ОДПоГрафику Уплачено]
			, p.[ДП ПроцентыПоГрафику Начислено]
			, p.[ДП ПроцентыПоГрафику Уплачено]
			, p.[ДП Основной долг Начислено]
			, p.[ДП Основной долг Уплачено]
			, p.[ДП Проценты Начислено]
			, p.[ДП Проценты Уплачено]
			, p.[ДП Пени Начислено]
			, p.[ДП Пени Уплачено]
			, p.[ДП ГосПошлина Начислено]
			, p.[ДП ГосПошлина Уплачено]
			, p.[ДП Переплата Начислено]
			, p.[ДП Переплата Уплачено]
			--ЧДП (частичное досрочное погашение)
			, p.[ЧДП ОДПоГрафику Начислено]
			, p.[ЧДП ОДПоГрафику Уплачено]
			, p.[ЧДП ПроцентыПоГрафику Начислено]
			, p.[ЧДП ПроцентыПоГрафику Уплачено]
			, p.[ЧДП Основной долг Начислено]
			, p.[ЧДП Основной долг Уплачено]
			, p.[ЧДП Проценты Начислено]
			, p.[ЧДП Проценты Уплачено]
			, p.[ЧДП Пени Начислено]
			, p.[ЧДП Пени Уплачено]
			, p.[ЧДП ГосПошлина Начислено]
			, p.[ЧДП ГосПошлина Уплачено]
			, p.[ЧДП Переплата Начислено]
			, p.[ЧДП Переплата Уплачено]
			 from #contracts c
				inner join #Contract_calendar cc 
					on cc.Договор = c.Договор
				left join #ap_reg ap 
					on ap.Договор = cc.Договор
					and ap.dt = cc.dt
				left join #t_Расчеты p on 
					p.Договор  = cc.Договор
					and p.dt = cc.dt
				left join #payments pay  on
					pay.Договор  = cc.Договор
					and pay.dt = cc.dt
				left join #t_Период_ПроцентнаяСтавка ПроцентнаяСтавка on 
					ПроцентнаяСтавка.Договор  = cc.Договор
					and cc.dt between ПроцентнаяСтавка.Период_c and ПроцентнаяСтавка.Период_по
			where 1=1
			option (hash join, QUERYTRACEON 610)
			

			 /*надо сравнить с  OFFSET @totalCount ROWS   FETCH NEXT @batch ROWS ONLY, но тут требуется сортировка, а не хочется добавлять*/
			select @row_count = @@ROWCOUNT
			
			IF @isDebug = 1 BEGIN
			--SELECT 'INSERT dbo.dm_CMRStatBalance', @row_count, datediff(SECOND, @StartDate, getdate())
				SELECT @duration = datediff(SECOND, @StartDate, getdate())
				SELECT @event_step_number = @event_step_number + 1
					, @event_step_type = 'INSERT dbo.dm_CMRStatBalance'
				SELECT @event_message = concat('Добавлено записей: ', @row_count, '. Продолжительность (сек.): ', @duration)
				SELECT @event_description = (SELECT row_count = @row_count, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
				EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
					@logger_name, @process_guid, @event_level, @event_type, @event_name, 
					@event_step_number, @event_step_type, @event_step_name, @event_status, 
					@event_message, @event_description
			END
				
	commit tran
	

	IF @isDebug = 1 BEGIN
		SELECT @duration = datediff(SECOND, @StartDate_0, getdate())
		SELECT @event_step_number = @event_step_number + 1, @event_step_type = 'End EXEC dbo.Create_dm_CMRStatBalance'
		SELECT @event_message = concat('@Mode: ', @Mode, '. Продолжительность (сек.): ', @duration)
		SELECT @event_description = (SELECT mode = @Mode, duration = @duration FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER)
		EXEC logDb.dbo.AddEventLog_SendEmail_SendToSlack
			@logger_name, @process_guid, @event_level, @event_type, @event_name, 
			@event_step_number, @event_step_type, @event_step_name, @event_status, 
			@event_message, @event_description
	END
end try
begin catch
	IF @@TRANCOUNT >0
	BEGIN
		ROLLBACK TRANSACTION
	END  
	;throw
end catch
end
