/*
exec hub.fill_CRE_EXPORT_LOG_302
*/
CREATE PROC hub.fill_CRE_EXPORT_LOG_302
	@mode int = 1 -- 0 - full, 1 - increment
	--,@GuidCRE_EXPORT_LOG_302 uniqueidentifier = NULL
	,@ID int = null
	,@InsertDate datetime = null
	,@isDebug int = 0
as
begin
	--truncate table hub.CRE_EXPORT_LOG_302
begin TRY
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @INSERT_DATE datetime = isnull(@InsertDate, '2000-01-01')

	drop table if exists #t_CRE_EXPORT_LOG_302
	if OBJECT_ID ('hub.CRE_EXPORT_LOG_302') is not NULL
		AND @mode = 1
		and @ID is null
		and @InsertDate is null
	begin
		set @INSERT_DATE = isnull((select dateadd(day, -1, max(INSERT_DATE)) from hub.CRE_EXPORT_LOG_302), '2000-01-01')
	end

	--IF @isDebug = 1 BEGIN
	--	SELECT INSERT_DATE = @INSERT_DATE
	--	RETURN 0
	--END

	select distinct
		GuidCRE_EXPORT_LOG_302 = try_cast(hashbytes('SHA2_256', cast(L.ID as varchar(30))) AS uniqueidentifier),
		L.ID,

		BKI_NAME = 
			CASE
				WHEN left(L.EXPORT_FILENAME, 3) = '4yj' THEN 'Скоринг Бюро'
				WHEN left(L.EXPORT_FILENAME, 9) = 'CHP_01492' THEN 'ОКБ'
				WHEN left(L.EXPORT_FILENAME, 12) = '2701FF000000' THEN 'НБКИ'
				ELSE 'Не определено'
			END,

		L.INSERT_DATE,
		L.EVENT_ID,
		L.EVENT_DATE,
		L.OPERATION_TYPE,
		L.SOURCE_CODE,
		L.REF_CODE,
		L.UUID,
		L.APPLICATION_NUMBER,
		L.APPLICANT_CODE,
		L.ORDER_NUM,
		L.EXPORT_FILENAME,
		L.IMPORT_FILENAME,
		L.EXPORT_EVENT_SUCCESS,
		L.ERROR_CODE,
		L.ERROR_DESC,
		L.CHANGE_CODE,
		L.SPECIAL_CHANGE_CODE,
		L.ACCOUNT,
		L.JOURNAL_ID,
		L.TRADE_ID,
		L.TRADEDETAIL_ID,
		L.IMPORT_ID,
		L.EXPORT_META_ID

		,created_at							= CURRENT_TIMESTAMP
		,updated_at							= CURRENT_TIMESTAMP
		,spFillName							= @spName

		--,Link_GuidБКИ_НФ_События = cast(nullif(dbo.getGUIDFrom1C_IDRREF(ИсторияСобытий.Событие), '00000000-0000-0000-0000-000000000000') as uniqueidentifier)
		,Link_GuidБКИ_НФ_События = События_ТипОбъекта.GuidБКИ_НФ_События

		--,Link_GuidДоговорЗайма = 
		--	case ИсторияСобытий.Источник_ТипСсылки
		--		when 0x0000004C --'ДоговорЗайма'
		--		then cast(nullif(dbo.getGUIDFrom1C_IDRREF(ИсторияСобытий.Источник_Ссылка), '00000000-0000-0000-0000-000000000000') as uniqueidentifier)
		--		else cast(null as uniqueidentifier)
		--	end
		,Link_GuidДоговорЗайма = ДоговорЗайма.GuidДоговораЗайма

		--,Link_GuidЗаявка = 
		--	case ИсторияСобытий.Источник_ТипСсылки
		--		when 0x00001091 --'Заявка'
		--		then cast(nullif(dbo.getGUIDFrom1C_IDRREF(ИсторияСобытий.Источник_Ссылка), '00000000-0000-0000-0000-000000000000') as uniqueidentifier)
		--		else cast(null as uniqueidentifier)
		--	end
		,Link_GuidЗаявка = Заявка.GuidЗаявки

		,Link_GuidКлиент = Клиент.GuidКлиент

		,EVENT_DATE_dt = cast(L.EVENT_DATE as date)
		,ТипОбъекта = События_ТипОбъекта.ТипОбъекта

		,НомерОбъекта = coalesce(
			Заявка.НомерЗаявки, 
			ДоговорЗайма.КодДоговораЗайма
			--Клиент.Наименование, 
			--Клиент2.Наименование,
			--Заявка2.ФИО
		)

		,НаименованиеКлиент = coalesce(
			Клиент.Наименование, 
			Клиент2.Наименование,
			Заявка2.ФИО
		)

		--,СсылкаОбъекта = coalesce(Заявка.СсылкаЗаявки, ДоговорЗайма.СсылкаДоговораЗайма, Клиент.СсылкаКлиент, Клиент2.СсылкаКлиент)
		--,GuidОбъекта = coalesce(Заявка.GuidЗаявки, ДоговорЗайма.GuidДоговораЗайма, Клиент.GuidКлиент, Клиент2.GuidКлиент)

	into #t_CRE_EXPORT_LOG_302
	--SELECT *
	FROM Stg._CRE.EXPORT_LOG_302 AS L
		left join link.v_БКИ_НФ_События_ТипОбъекта as События_ТипОбъекта
			on События_ТипОбъекта.КодСобытия = L.EVENT_ID
		left join hub.Заявка as Заявка
			on События_ТипОбъекта.ТипОбъекта in ('Заявка', 'Субъект')
			and Заявка.НомерЗаявки = coalesce(L.APPLICATION_NUMBER, L.ACCOUNT, L.UUID)
		left join hub.ДоговорЗайма as ДоговорЗайма
			on События_ТипОбъекта.ТипОбъекта = 'ДоговорЗайма'
			and ДоговорЗайма.КодДоговораЗайма = coalesce(L.APPLICATION_NUMBER, L.ACCOUNT, L.UUID)
		left join hub.Клиенты as Клиент
			--on События_ТипОбъекта.ТипОбъекта = 'Субъект'
			on 1=1
			and Клиент.GuidКлиент = try_cast(
				concat_ws('-',
					substring(L.REF_CODE,1,8),
					substring(L.REF_CODE,9,4),
					substring(L.REF_CODE,13,4),
					substring(L.REF_CODE,17,4),
					substring(L.REF_CODE,21,12)
					) as uniqueidentifier
				)
		--если событие, относящееся к 'Субъект' привязано к конкретной Заявке и не указан REF_CODE
		--попытаемся дотянуться до Клиента через Заявку
		left join hub.Заявка as Заявка2
			on События_ТипОбъекта.ТипОбъекта = 'Субъект'
			and Заявка2.НомерЗаявки = coalesce(L.APPLICATION_NUMBER, L.ACCOUNT, L.UUID)
		left join link.v_Клиент_Заявка as Клиент2
			on Клиент2.GuidЗаявки = Заявка2.GuidЗаявки

	where 1=1
		and try_cast(hashbytes('SHA2_256', cast(L.ID as varchar(30))) AS uniqueidentifier) is not null
		and L.INSERT_DATE >= @INSERT_DATE
		and (L.ID = @ID or @ID is null)
		--Загружаем в hub только записи, связанные с договором/заявкой
		--and coalesce(ДоговорЗайма.GuidДоговораЗайма, Заявка.GuidЗаявки) is not null --?
		and (
			try_cast(coalesce(L.APPLICATION_NUMBER, L.ACCOUNT, L.UUID) as bigint) is not null
			or 
			try_cast(
				concat_ws('-',
					substring(L.REF_CODE,1,8),
					substring(L.REF_CODE,9,4),
					substring(L.REF_CODE,13,4),
					substring(L.REF_CODE,17,4),
					substring(L.REF_CODE,21,12)
				) as uniqueidentifier
			) is not null
		)

	create index ix0
	on #t_CRE_EXPORT_LOG_302(GuidCRE_EXPORT_LOG_302)

	--create index ix1
	--on #t_CRE_EXPORT_LOG_302(EVENT_DATE_dt, ТипОбъекта, EVENT_ID, GuidОбъекта, INSERT_DATE)

	--create index ix2
	--on #t_CRE_EXPORT_LOG_302(EVENT_DATE_dt, EVENT_ID, GuidОбъекта, INSERT_DATE)

	create index ix3
	on #t_CRE_EXPORT_LOG_302(EVENT_DATE_dt, EVENT_ID, НомерОбъекта, INSERT_DATE)

	create index ix5
	on #t_CRE_EXPORT_LOG_302(EVENT_DATE_dt, EVENT_ID, НаименованиеКлиент, INSERT_DATE)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_CRE_EXPORT_LOG_302
		SELECT * INTO ##t_CRE_EXPORT_LOG_302 FROM #t_CRE_EXPORT_LOG_302
		--RETURN 0
	END


	if OBJECT_ID('link.CRE_EXPORT_LOG_302_stage') is null
	begin
		CREATE TABLE link.CRE_EXPORT_LOG_302_stage
		(
			Id uniqueidentifier NOT NULL CONSTRAINT [DF_CRE_EXPORT_LOG_302_stage__Id] DEFAULT (newid()),
			GuidCRE_EXPORT_LOG_302 uniqueidentifier NOT NULL,
			--GuidДоговораЗайма uniqueidentifier NOT NULL,
			--ВерсияДанныхДоговораЗайма binary(8) NULL,
			LinkName nvarchar(255) NULL,
			LinkGuid uniqueidentifier NULL,
			created_at datetime NOT NULL CONSTRAINT [DF_CRE_EXPORT_LOG_302_stage__created_at] DEFAULT (getdate()),
			TargetColName nvarchar(255) NULL
		) ON [PRIMARY]

		ALTER TABLE link.CRE_EXPORT_LOG_302_stage
		ADD CONSTRAINT PK__CRE_EXPORT_LOG_302_stage PRIMARY KEY CLUSTERED (Id) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [ix_LinkName] ON link.CRE_EXPORT_LOG_302_stage (LinkName) ON [PRIMARY]
	end

	insert into link.CRE_EXPORT_LOG_302_stage(
		GuidCRE_EXPORT_LOG_302
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		GuidCRE_EXPORT_LOG_302,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_CRE_EXPORT_LOG_302
		CROSS APPLY (
			VALUES 
				(Link_GuidБКИ_НФ_События, 'link.CRE_EXPORT_LOG_302_События', 'GuidБКИ_НФ_События')
				,(Link_GuidДоговорЗайма, 'link.CRE_EXPORT_LOG_302_ДоговорЗайма', 'GuidДоговораЗайма')
				,(Link_GuidЗаявка, 'link.CRE_EXPORT_LOG_302_Заявка', 'GuidЗаявки')
				,(Link_GuidКлиент, 'link.CRE_EXPORT_LOG_302_Клиент', 'GuidКлиент')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null

	--link к hub.БКИ_НФ_ИсторияСобытий
	/*
	--1. ТипОбъекта in ('Заявка', 'ДоговорЗайма')
	insert into link.CRE_EXPORT_LOG_302_stage(
		GuidCRE_EXPORT_LOG_302
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select 
		a.GuidCRE_EXPORT_LOG_302,
		a.LinkName,
		a.LinkGuid,
		a.TargetColName
	from (
		select --distinct 
			e.GuidCRE_EXPORT_LOG_302,
			LinkName = 'link.CRE_EXPORT_LOG_302_ИсторияСобытий',
			LinkGuid = h.GuidБКИ_НФ_ИсторияСобытий,
			TargetColName = 'GuidБКИ_НФ_ИсторияСобытий',
			rn = row_number() over(
				partition by e.GuidCRE_EXPORT_LOG_302
				--order by h.Дата desc, h.ДатаЗаписи desc, getdate()
				order by h.ДатаЗаписи desc, getdate()
			)
		from #t_CRE_EXPORT_LOG_302 as e
			--inner join dm.v_БКИ_НФ_ИсторияСобытий as h
			inner join dm.БКИ_НФ_ИсторияСобытий as h
				on h.Дата_dt = e.EVENT_DATE_dt
				and h.ТипОбъекта = e.ТипОбъекта
				and h.КодСобытия = e.EVENT_ID
				and h.GuidОбъекта = e.GuidОбъекта
				-- ДатаЗаписи в ИсториюСобытий должна быть меньше, 
				-- чем INSERT_DATE в EXPORT
				and h.ДатаЗаписи < e.INSERT_DATE
		where e.ТипОбъекта in ('Заявка', 'ДоговорЗайма')
		) as a
	where a.rn = 1
	*/

	--ВАЖНО: в CMR события,  относящиеся в целом к субъекту (например, 1.7, 1.9, 1.10)
	--привязаны не к клиентам, а к конкретным договорам или заявкам
	--поэтому нужно найти клиента

	--1 ищем событие по НомерОбъекта
	insert into link.CRE_EXPORT_LOG_302_stage(
		GuidCRE_EXPORT_LOG_302
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select 
		a.GuidCRE_EXPORT_LOG_302,
		a.LinkName,
		a.LinkGuid,
		a.TargetColName
	from (
		select --distinct 
			e.GuidCRE_EXPORT_LOG_302,
			LinkName = 'link.CRE_EXPORT_LOG_302_ИсторияСобытий',
			LinkGuid = h.GuidБКИ_НФ_ИсторияСобытий,
			TargetColName = 'GuidБКИ_НФ_ИсторияСобытий',
			rn = row_number() over(
				partition by e.GuidCRE_EXPORT_LOG_302
				--order by h.Дата desc, h.ДатаЗаписи desc, getdate()
				order by h.ДатаЗаписи desc, getdate()
			)
		from #t_CRE_EXPORT_LOG_302 as e
			--inner join dm.v_БКИ_НФ_ИсторияСобытий as h
			inner join dm.БКИ_НФ_ИсторияСобытий as h
				on h.Дата_dt = e.EVENT_DATE_dt
				--and h.ТипОбъекта = e.ТипОбъекта
				and h.КодСобытия = e.EVENT_ID
				--and h.GuidКлиент = e.GuidОбъекта
				and h.НомерОбъекта = e.НомерОбъекта
				-- ДатаЗаписи в ИсториюСобытий должна быть меньше, 
				-- чем INSERT_DATE в EXPORT
				and h.ДатаЗаписи < e.INSERT_DATE
		--where e.ТипОбъекта in ('Субъект')
		) as a
	where a.rn = 1

	--2. если НомерОбъекта is null 
	-- ищем по НаименованиеКлиент
	insert into link.CRE_EXPORT_LOG_302_stage(
		GuidCRE_EXPORT_LOG_302
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select 
		a.GuidCRE_EXPORT_LOG_302,
		a.LinkName,
		a.LinkGuid,
		a.TargetColName
	from (
		select --distinct 
			e.GuidCRE_EXPORT_LOG_302,
			LinkName = 'link.CRE_EXPORT_LOG_302_ИсторияСобытий',
			LinkGuid = h.GuidБКИ_НФ_ИсторияСобытий,
			TargetColName = 'GuidБКИ_НФ_ИсторияСобытий',
			rn = row_number() over(
				partition by e.GuidCRE_EXPORT_LOG_302
				--order by h.Дата desc, h.ДатаЗаписи desc, getdate()
				order by h.ДатаЗаписи desc, getdate()
			)
		from #t_CRE_EXPORT_LOG_302 as e
			--inner join dm.v_БКИ_НФ_ИсторияСобытий as h
			inner join dm.БКИ_НФ_ИсторияСобытий as h
				on h.Дата_dt = e.EVENT_DATE_dt
				--and h.ТипОбъекта = e.ТипОбъекта
				and h.КодСобытия = e.EVENT_ID

				and e.НомерОбъекта is null
				and h.НаименованиеКлиент = e.НаименованиеКлиент

				-- ДатаЗаписи в ИсториюСобытий должна быть меньше, 
				-- чем INSERT_DATE в EXPORT
				and h.ДатаЗаписи < e.INSERT_DATE
		--where e.ТипОбъекта in ('Субъект')
		) as a
	where a.rn = 1



	--link к hub.CRE_IMPORT_LOG_302
	--1
	--связываются по совпадению полей IMPORT_ID, UUID, EVENT_ID, EVENT_DATE
	insert into link.CRE_EXPORT_LOG_302_stage(
		GuidCRE_EXPORT_LOG_302
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select 
		a.GuidCRE_EXPORT_LOG_302,
		a.LinkName,
		a.LinkGuid,
		a.TargetColName
	from (
		select --distinct 
			e.GuidCRE_EXPORT_LOG_302,
			LinkName = 'link.CRE_EXPORT_LOG_302_IMPORT',
			LinkGuid = i.GuidCRE_IMPORT_LOG_302,
			TargetColName = 'GuidCRE_IMPORT_LOG_302',
			rn = row_number() over(
				partition by e.GuidCRE_EXPORT_LOG_302
				order by i.INSERT_DATE desc, getdate()
			)
		from #t_CRE_EXPORT_LOG_302 as e
			inner join hub.CRE_IMPORT_LOG_302 as i
				on e.IMPORT_ID = i.IMPORT_ID
				and e.UUID = i.UUID
				and e.EVENT_ID = i.EVENT_ID
				and e.EVENT_DATE = i.EVENT_DATE
		) as a
	where a.rn = 1

	--2
	--события, относящиеся к субъекту, у которых не проставлен UUID
	--можно связывать по REF_CODE (код клиента).
	insert into link.CRE_EXPORT_LOG_302_stage(
		GuidCRE_EXPORT_LOG_302
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select 
		a.GuidCRE_EXPORT_LOG_302,
		a.LinkName,
		a.LinkGuid,
		a.TargetColName
	from (
		select --distinct 
			e.GuidCRE_EXPORT_LOG_302,
			LinkName = 'link.CRE_EXPORT_LOG_302_IMPORT',
			LinkGuid = i.GuidCRE_IMPORT_LOG_302,
			TargetColName = 'GuidCRE_IMPORT_LOG_302',
			rn = row_number() over(
				partition by e.GuidCRE_EXPORT_LOG_302
				order by i.INSERT_DATE desc, getdate()
			)
		from #t_CRE_EXPORT_LOG_302 as e
			inner join hub.CRE_IMPORT_LOG_302 as i
				on e.IMPORT_ID = i.IMPORT_ID
				--and e.UUID = i.UUID
				and e.UUID is null
				and i.UUID is null
				and e.REF_CODE = i.REF_CODE
				and e.EVENT_ID = i.EVENT_ID
				and e.EVENT_DATE = i.EVENT_DATE
		) as a
	where a.rn = 1



	--заполнение таблиц с линками
	--BEGIN TRY
		EXEC link.exec_fill_link_between_CRE_EXPORT_LOG_302_and_other
		--EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_CRE_EXPORT_LOG_302_and_other'
	--END TRY
	--BEGIN CATCH
	--	--??
	--END CATCH


	if OBJECT_ID('hub.CRE_EXPORT_LOG_302') is null
	begin
		select top(0)
			GuidCRE_EXPORT_LOG_302,
			ID,
			BKI_NAME,
			INSERT_DATE,
			EVENT_ID,
			EVENT_DATE,
			OPERATION_TYPE,
			SOURCE_CODE,
			REF_CODE,
			UUID,
			APPLICATION_NUMBER,
			APPLICANT_CODE,
			ORDER_NUM,
			EXPORT_FILENAME,
			IMPORT_FILENAME,
			EXPORT_EVENT_SUCCESS,
			ERROR_CODE,
			ERROR_DESC,
			CHANGE_CODE,
			SPECIAL_CHANGE_CODE,
			ACCOUNT,
			JOURNAL_ID,
			TRADE_ID,
			TRADEDETAIL_ID,
			IMPORT_ID,
			EXPORT_META_ID,
            created_at,
            updated_at,
            spFillName
		into hub.CRE_EXPORT_LOG_302
		from #t_CRE_EXPORT_LOG_302

		alter table hub.CRE_EXPORT_LOG_302
			alter COLUMN GuidCRE_EXPORT_LOG_302 uniqueidentifier not null

		ALTER TABLE hub.CRE_EXPORT_LOG_302
			ADD CONSTRAINT PK__CRE_EXPORT_LOG_302 PRIMARY KEY CLUSTERED (GuidCRE_EXPORT_LOG_302)

		create index ix_EXPORT_FILENAME_ORDER_NUM
		on hub.CRE_EXPORT_LOG_302(EXPORT_FILENAME, ORDER_NUM)

		create index ix_INSERT_DATE
		on hub.CRE_EXPORT_LOG_302(INSERT_DATE)
	end
	
	--begin tran
		merge hub.CRE_EXPORT_LOG_302 t
		using #t_CRE_EXPORT_LOG_302 s
			on t.GuidCRE_EXPORT_LOG_302 = s.GuidCRE_EXPORT_LOG_302
		when not matched then insert
		(
			GuidCRE_EXPORT_LOG_302,
			ID,
			BKI_NAME,
			INSERT_DATE,
			EVENT_ID,
			EVENT_DATE,
			OPERATION_TYPE,
			SOURCE_CODE,
			REF_CODE,
			UUID,
			APPLICATION_NUMBER,
			APPLICANT_CODE,
			ORDER_NUM,
			EXPORT_FILENAME,
			IMPORT_FILENAME,
			EXPORT_EVENT_SUCCESS,
			ERROR_CODE,
			ERROR_DESC,
			CHANGE_CODE,
			SPECIAL_CHANGE_CODE,
			ACCOUNT,
			JOURNAL_ID,
			TRADE_ID,
			TRADEDETAIL_ID,
			IMPORT_ID,
			EXPORT_META_ID,
            created_at,
            updated_at,
            spFillName
		) values
		(
			s.GuidCRE_EXPORT_LOG_302,
			s.ID,
			s.BKI_NAME,
			s.INSERT_DATE,
			s.EVENT_ID,
			s.EVENT_DATE,
			s.OPERATION_TYPE,
			s.SOURCE_CODE,
			s.REF_CODE,
			s.UUID,
			s.APPLICATION_NUMBER,
			s.APPLICANT_CODE,
			s.ORDER_NUM,
			s.EXPORT_FILENAME,
			s.IMPORT_FILENAME,
			s.EXPORT_EVENT_SUCCESS,
			s.ERROR_CODE,
			s.ERROR_DESC,
			s.CHANGE_CODE,
			s.SPECIAL_CHANGE_CODE,
			s.ACCOUNT,
			s.JOURNAL_ID,
			s.TRADE_ID,
			s.TRADEDETAIL_ID,
			s.IMPORT_ID,
			s.EXPORT_META_ID,
            s.created_at,
            s.updated_at,
            s.spFillName
		)
		when matched 
		--and (
		--	@mode = 0 
		--	OR @DealNumber IS NOT NULL
		--)
		then update SET
			--t.GuidCRE_EXPORT_LOG_302 = s.GuidCRE_EXPORT_LOG_302,
			t.ID = s.ID,
			t.BKI_NAME = s.BKI_NAME,
			t.INSERT_DATE = s.INSERT_DATE,
			t.EVENT_ID = s.EVENT_ID,
			t.EVENT_DATE = s.EVENT_DATE,
			t.OPERATION_TYPE = s.OPERATION_TYPE,
			t.SOURCE_CODE = s.SOURCE_CODE,
			t.REF_CODE = s.REF_CODE,
			t.UUID = s.UUID,
			t.APPLICATION_NUMBER = s.APPLICATION_NUMBER,
			t.APPLICANT_CODE = s.APPLICANT_CODE,
			t.ORDER_NUM = s.ORDER_NUM,
			t.EXPORT_FILENAME = s.EXPORT_FILENAME,
			t.IMPORT_FILENAME = s.IMPORT_FILENAME,
			t.EXPORT_EVENT_SUCCESS = s.EXPORT_EVENT_SUCCESS,
			t.ERROR_CODE = s.ERROR_CODE,
			t.ERROR_DESC = s.ERROR_DESC,
			t.CHANGE_CODE = s.CHANGE_CODE,
			t.SPECIAL_CHANGE_CODE = s.SPECIAL_CHANGE_CODE,
			t.ACCOUNT = s.ACCOUNT,
			t.JOURNAL_ID = s.JOURNAL_ID,
			t.TRADE_ID = s.TRADE_ID,
			t.TRADEDETAIL_ID = s.TRADEDETAIL_ID,
			t.IMPORT_ID = s.IMPORT_ID,
			t.EXPORT_META_ID = s.EXPORT_META_ID,
            t.created_at = s.created_at,
            t.updated_at = s.updated_at,
            t.spFillName = s.spFillName
			;
	--commit tran
	

end try
begin catch
	SET @description ='ErrorNumber: '+  cast(format(ERROR_NUMBER(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorSEVERITY: '+  cast(format(ERROR_SEVERITY(),'0') as nvarchar(50))
		+char(10)+char(13)+' ErrorState: '+  cast(format(ERROR_State(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorProcedure: '+ isnull( ERROR_PROCEDURE() ,'')
		+char(10)+char(13)+' Error_line: '+  cast(format(ERROR_LINE(),'0') as nvarchar(50))+char(10)+char(13)+' ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	
	SELECT @message = concat('exec ', @spName)

	SELECT @eventType = 'Data Valut ERROR'

	EXEC LogDb.dbo.LogAndSendMailToAdmin 
		@eventName = @spName,
		@eventType = @eventType, --'Info',
		@message = @message,
		@description = @description,
		@SendEmail = 1,
		@SendToSlack = 1

	if @@TRANCOUNT>0
		rollback tran;
	;throw
end catch

end
