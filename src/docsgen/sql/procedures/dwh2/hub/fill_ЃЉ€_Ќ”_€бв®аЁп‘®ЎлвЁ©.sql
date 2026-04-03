/*
exec hub.fill_БКИ_НФ_ИсторияСобытий
	--@mode = 1 -- 0 - full, 1 - increment
	@GuidБКИ_НФ_ИсторияСобытий = '060a34d9-cc49-4e83-b077-57fda938aae3'
	,@isDebug = 1

exec hub.fill_БКИ_НФ_ИсторияСобытий
	--@mode = 1 -- 0 - full, 1 - increment
	@GuidБКИ_НФ_ИсторияСобытий = '4f31963d-f9e7-41db-b185-cdecbac62712'
	,@isDebug = 1

exec hub.fill_БКИ_НФ_ИсторияСобытий
	@mode = 0 -- 0 - full, 1 - increment
	,@isDebug = 1

exec hub.fill_БКИ_НФ_ИсторияСобытий
*/
create   PROC hub.fill_БКИ_НФ_ИсторияСобытий
	@mode int = 1 -- 0 - full, 1 - increment
	,@GuidБКИ_НФ_ИсторияСобытий uniqueidentifier = NULL
	,@RecordDate datetime2(0) = null
	,@isDebug int = 0
as
begin
	--truncate table hub.БКИ_НФ_ИсторияСобытий
begin TRY
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @record_date datetime2(0) = isnull(@RecordDate, '2000-01-01') --ДатаЗаписи

	drop table if exists #t_БКИ_НФ_ИсторияСобытий
	if OBJECT_ID ('hub.БКИ_НФ_ИсторияСобытий') is not NULL
		AND @mode = 1
		AND @GuidБКИ_НФ_ИсторияСобытий is null
		AND @RecordDate is null
	begin
		set @record_date = isnull((select dateadd(day, -2, max(ДатаЗаписи)) from hub.БКИ_НФ_ИсторияСобытий), '2000-01-01')
	end

	select distinct
		GuidБКИ_НФ_ИсторияСобытий = try_cast(ИсторияСобытий.УникальныйИдентификатор as uniqueidentifier)
		,Дата = dateadd(year, -2000, ИсторияСобытий.Дата)
		,isActive = cast(ИсторияСобытий.Активно as bit)
		,ДатаЗаписи = dateadd(year, -2000, ИсторияСобытий.ДатаЗаписи)

		,created_at							= CURRENT_TIMESTAMP
		,updated_at							= CURRENT_TIMESTAMP
		,spFillName							= @spName

		,Link_GuidБКИ_НФ_События = cast(nullif(dbo.getGUIDFrom1C_IDRREF(ИсторияСобытий.Событие), '00000000-0000-0000-0000-000000000000') as uniqueidentifier)

		,Link_GuidДоговорЗайма = 
			case ИсторияСобытий.Источник_ТипСсылки
				when 0x0000004C --'ДоговорЗайма'
				then cast(nullif(dbo.getGUIDFrom1C_IDRREF(ИсторияСобытий.Источник_Ссылка), '00000000-0000-0000-0000-000000000000') as uniqueidentifier)
				else cast(null as uniqueidentifier)
			end

		,Link_GuidЗаявка = 
			case ИсторияСобытий.Источник_ТипСсылки
				when 0x00001091 --'Заявка'
				then cast(nullif(dbo.getGUIDFrom1C_IDRREF(ИсторияСобытий.Источник_Ссылка), '00000000-0000-0000-0000-000000000000') as uniqueidentifier)
				else cast(null as uniqueidentifier)
			end
	into #t_БКИ_НФ_ИсторияСобытий
	--SELECT *
	FROM Stg._1cCMR.РегистрСведений_БКИ_НФ_ИсторияСобытий as ИсторияСобытий
	where 1=1
		and try_cast(ИсторияСобытий.УникальныйИдентификатор as uniqueidentifier) is not null
		and ИсторияСобытий.ДатаЗаписи >= dateadd(year, 2000, @record_date) 
		and (ИсторияСобытий.УникальныйИдентификатор = @GuidБКИ_НФ_ИсторияСобытий
			or @GuidБКИ_НФ_ИсторияСобытий is null)

	--Загружаем в hub только записи, связанные с договором/заявкой
	delete t
	from #t_БКИ_НФ_ИсторияСобытий as t
	where t.Link_GuidДоговорЗайма is null
		and t.Link_GuidЗаявка is null


	create index ix1
	on #t_БКИ_НФ_ИсторияСобытий(GuidБКИ_НФ_ИсторияСобытий)

	;with dup as (
		select *
			,rn = row_number() over(
				partition by GuidБКИ_НФ_ИсторияСобытий
				order by ДатаЗаписи desc, getdate()
			)
		from #t_БКИ_НФ_ИсторияСобытий
	)
	delete d 
	from dup as d
	where d.rn > 1
	

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_БКИ_НФ_ИсторияСобытий
		SELECT * INTO ##t_БКИ_НФ_ИсторияСобытий FROM #t_БКИ_НФ_ИсторияСобытий
		--RETURN 0
	END


	if OBJECT_ID('link.БКИ_НФ_ИсторияСобытий_stage') is null
	begin
		CREATE TABLE link.БКИ_НФ_ИсторияСобытий_stage
		(
			Id uniqueidentifier NOT NULL CONSTRAINT [DF_БКИ_НФ_ИсторияСобытий_stage__Id] DEFAULT (newid()),
			GuidБКИ_НФ_ИсторияСобытий uniqueidentifier NOT NULL,
			--GuidДоговораЗайма uniqueidentifier NOT NULL,
			--ВерсияДанныхДоговораЗайма binary(8) NULL,
			LinkName nvarchar(255) NULL,
			LinkGuid uniqueidentifier NULL,
			created_at datetime NOT NULL CONSTRAINT [DF_БКИ_НФ_ИсторияСобытий_stage__created_at] DEFAULT (getdate()),
			TargetColName nvarchar(255) NULL
		) ON [PRIMARY]

		ALTER TABLE link.БКИ_НФ_ИсторияСобытий_stage
		ADD CONSTRAINT PK__БКИ_НФ_ИсторияСобытий_stage PRIMARY KEY CLUSTERED (Id) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [ix_LinkName] ON link.БКИ_НФ_ИсторияСобытий_stage (LinkName) ON [PRIMARY]
	end

	insert into link.БКИ_НФ_ИсторияСобытий_stage(
		GuidБКИ_НФ_ИсторияСобытий
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		GuidБКИ_НФ_ИсторияСобытий,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_БКИ_НФ_ИсторияСобытий
		CROSS APPLY (
			VALUES 
				  (Link_GuidБКИ_НФ_События, 'link.БКИ_НФ_ИсторияСобытий_События', 'GuidБКИ_НФ_События')
				  ,(Link_GuidДоговорЗайма, 'link.БКИ_НФ_ИсторияСобытий_ДоговорЗайма', 'GuidДоговораЗайма')
				  ,(Link_GuidЗаявка, 'link.БКИ_НФ_ИсторияСобытий_Заявка', 'GuidЗаявки')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null

	--заполнение таблиц с линками
	--BEGIN TRY
		EXEC link.exec_fill_link_between_БКИ_НФ_ИсторияСобытий_and_other
		--EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_БКИ_НФ_ИсторияСобытий_and_other'
	--END TRY
	--BEGIN CATCH
	--	--??
	--END CATCH


	if OBJECT_ID('hub.БКИ_НФ_ИсторияСобытий') is null
	begin
		select top(0)
			GuidБКИ_НФ_ИсторияСобытий,
			Дата,
			isActive,
			ДатаЗаписи,
            created_at,
            updated_at,
            spFillName
		into hub.БКИ_НФ_ИсторияСобытий
		from #t_БКИ_НФ_ИсторияСобытий

		alter table hub.БКИ_НФ_ИсторияСобытий
			alter COLUMN GuidБКИ_НФ_ИсторияСобытий uniqueidentifier not null

		ALTER TABLE hub.БКИ_НФ_ИсторияСобытий
			ADD CONSTRAINT PK__БКИ_НФ_ИсторияСобытий PRIMARY KEY CLUSTERED (GuidБКИ_НФ_ИсторияСобытий)

		create index ix_ДатаЗаписи
		on hub.БКИ_НФ_ИсторияСобытий(ДатаЗаписи)

		alter table hub.БКИ_НФ_ИсторияСобытий
		add Дата_dt AS (cast(Дата as date)) PERSISTED

		create index ix_Дата_dt
		on hub.БКИ_НФ_ИсторияСобытий(Дата_dt)
	end
	
	--begin tran
		merge hub.БКИ_НФ_ИсторияСобытий t
		using #t_БКИ_НФ_ИсторияСобытий s
			on t.GuidБКИ_НФ_ИсторияСобытий = s.GuidБКИ_НФ_ИсторияСобытий
		when not matched then insert
		(
			GuidБКИ_НФ_ИсторияСобытий,
			Дата,
			isActive,
			ДатаЗаписи,
            created_at,
            updated_at,
            spFillName
		) values
		(
			s.GuidБКИ_НФ_ИсторияСобытий,
			s.Дата,
			s.isActive,
			s.ДатаЗаписи,
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
			--t.GuidБКИ_НФ_ИсторияСобытий = s.GuidБКИ_НФ_ИсторияСобытий,
			t.Дата = s.Дата,
			t.isActive = s.isActive,
			t.ДатаЗаписи = s.ДатаЗаписи,
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
