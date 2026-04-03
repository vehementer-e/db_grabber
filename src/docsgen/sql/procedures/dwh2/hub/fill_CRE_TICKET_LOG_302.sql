/*
exec hub.fill_CRE_TICKET_LOG_302
*/
create   PROC hub.fill_CRE_TICKET_LOG_302
	@mode int = 1 -- 0 - full, 1 - increment
	--,@GuidCRE_TICKET_LOG_302 uniqueidentifier = NULL
	,@ID int = null
	,@TicketDate datetime = null
	,@isDebug int = 0
as
begin
	--truncate table hub.CRE_TICKET_LOG_302
begin TRY
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @TICKET_DATE datetime = isnull(@TicketDate, '2000-01-01')

	drop table if exists #t_CRE_TICKET_LOG_302
	if OBJECT_ID ('hub.CRE_TICKET_LOG_302') is not NULL
		AND @mode = 1
		and @ID is null
		and @TicketDate is null
	begin
		set @TICKET_DATE = isnull((select dateadd(day, -2, max(TICKET_DATE)) from hub.CRE_TICKET_LOG_302), '2000-01-01')
	end

	select distinct
		GuidCRE_TICKET_LOG_302 = try_cast(hashbytes('SHA2_256', cast(L.ID as varchar(30))) AS uniqueidentifier),
		L.ID,

		BKI_NAME = 
			CASE
				WHEN left(L.EXPORT_FILENAME, 3) = '4yj' THEN 'Скоринг Бюро'
				WHEN left(L.EXPORT_FILENAME, 9) = 'CHP_01492' THEN 'ОКБ'
				WHEN left(L.EXPORT_FILENAME, 12) = '2701FF000000' THEN 'НБКИ'
				ELSE 'Не определено'
			END,

		L.EXPORT_FILENAME,
		L.TICKET_FILENAME,
		L.TICKET_DATE,
		L.JOURNAL_ID,
		L.ERROR_FILE

		,created_at							= CURRENT_TIMESTAMP
		,updated_at							= CURRENT_TIMESTAMP
		,spFillName							= @spName

		--,Link_GuidБКИ_НФ_События = События_ТипОбъекта.GuidБКИ_НФ_События
	into #t_CRE_TICKET_LOG_302
	--SELECT *
	FROM Stg._CRE.TICKET_LOG_302 AS L
	where 1=1
		and try_cast(hashbytes('SHA2_256', cast(L.ID as varchar(30))) AS uniqueidentifier) is not null
		and L.TICKET_DATE >= @TICKET_DATE
		and (L.ID = @ID or @ID is null)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_CRE_TICKET_LOG_302
		SELECT * INTO ##t_CRE_TICKET_LOG_302 FROM #t_CRE_TICKET_LOG_302
		--RETURN 0
	END


	/*
	if OBJECT_ID('link.TICKET_LOG_302_stage') is null
	begin
		CREATE TABLE link.TICKET_LOG_302_stage
		(
			Id uniqueidentifier NOT NULL CONSTRAINT [DF_TICKET_LOG_302_stage__Id] DEFAULT (newid()),
			GuidCRE_TICKET_LOG_302 uniqueidentifier NOT NULL,
			--GuidДоговораЗайма uniqueidentifier NOT NULL,
			--ВерсияДанныхДоговораЗайма binary(8) NULL,
			LinkName nvarchar(255) NULL,
			LinkGuid uniqueidentifier NULL,
			created_at datetime NOT NULL CONSTRAINT [DF_TICKET_LOG_302_stage__created_at] DEFAULT (getdate()),
			TargetColName nvarchar(255) NULL
		) ON [PRIMARY]

		ALTER TABLE link.TICKET_LOG_302_stage
		ADD CONSTRAINT PK__TICKET_LOG_302_stage PRIMARY KEY CLUSTERED (Id) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [ix_LinkName] ON link.TICKET_LOG_302_stage (LinkName) ON [PRIMARY]
	end
	*/

	/*
	insert into link.TICKET_LOG_302_stage(
		GuidCRE_TICKET_LOG_302
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		GuidCRE_TICKET_LOG_302,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_CRE_TICKET_LOG_302
		CROSS APPLY (
			VALUES 
				  (Link_GuidБКИ_НФ_События, 'link.TICKET_LOG_302_События', 'GuidБКИ_НФ_События')
				  ,(Link_GuidДоговорЗайма, 'link.TICKET_LOG_302_ДоговорЗайма', 'GuidДоговораЗайма')
				  ,(Link_GuidЗаявка, 'link.TICKET_LOG_302_Заявка', 'GuidЗаявки')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null
	*/

	/*
	insert into link.TICKET_LOG_302_stage(
		GuidCRE_TICKET_LOG_302
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		R.GuidCRE_TICKET_LOG_302,
		LinkName = 'link.TICKET_LOG_302_EXPORT',
		LinkGuid = E.GuidCRE_EXPORT_LOG_302,
		TargetColName = 'GuidCRE_EXPORT_LOG_302'
	from hub.CRE_EXPORT_LOG_302 as E
		inner join #t_CRE_TICKET_LOG_302 AS R
			ON E.EXPORT_FILENAME = R.EXPORT_FILENAME --Наименование файла реджекта.
			AND E.ORDER_NUM = R.ORDER_NUM	--Порядковый номер (orderNum) в файле экспорта
	*/


	--link к hub.CRE_EXPORT_LOG_302
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
			LinkName = 'link.CRE_EXPORT_LOG_302_TICKET',
			LinkGuid = t.GuidCRE_TICKET_LOG_302,
			TargetColName = 'GuidCRE_TICKET_LOG_302',
			rn = row_number() over(
				partition by e.GuidCRE_EXPORT_LOG_302
				order by t.TICKET_DATE desc, getdate()
			)
		from #t_CRE_TICKET_LOG_302 as t
			inner join hub.CRE_EXPORT_LOG_302 as e
				on e.EXPORT_FILENAME = t.EXPORT_FILENAME
		) as a
	where a.rn = 1


	--заполнение таблиц с линками
	--BEGIN TRY
		--EXEC link.exec_fill_link_between_TICKET_LOG_302_and_other
		--EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_TICKET_LOG_302_and_other'
		EXEC link.exec_fill_link_between_CRE_EXPORT_LOG_302_and_other
	--END TRY
	--BEGIN CATCH
	--	--??
	--END CATCH


	if OBJECT_ID('hub.CRE_TICKET_LOG_302') is null
	begin
		select top(0)
			GuidCRE_TICKET_LOG_302,
			ID,
			BKI_NAME,
			EXPORT_FILENAME,
			TICKET_FILENAME,
			TICKET_DATE,
			JOURNAL_ID,
			ERROR_FILE,
            created_at,
            updated_at,
            spFillName
		into hub.CRE_TICKET_LOG_302
		from #t_CRE_TICKET_LOG_302

		alter table hub.CRE_TICKET_LOG_302
			alter COLUMN GuidCRE_TICKET_LOG_302 uniqueidentifier not null

		ALTER TABLE hub.CRE_TICKET_LOG_302
			ADD CONSTRAINT PK__TICKET_LOG_302 PRIMARY KEY CLUSTERED (GuidCRE_TICKET_LOG_302)

		create index ix_EXPORT_FILENAME
		on hub.CRE_TICKET_LOG_302(EXPORT_FILENAME)

		create index ix_TICKET_DATE
		on hub.CRE_TICKET_LOG_302(TICKET_DATE)
	end
	
	--begin tran
		merge hub.CRE_TICKET_LOG_302 t
		using #t_CRE_TICKET_LOG_302 s
			on t.GuidCRE_TICKET_LOG_302 = s.GuidCRE_TICKET_LOG_302
		when not matched then insert
		(
			GuidCRE_TICKET_LOG_302,
			ID,
			BKI_NAME,
			EXPORT_FILENAME,
			TICKET_FILENAME,
			TICKET_DATE,
			JOURNAL_ID,
			ERROR_FILE,
            created_at,
            updated_at,
            spFillName
		) values
		(
			s.GuidCRE_TICKET_LOG_302,
			s.ID,
			s.BKI_NAME,
			s.EXPORT_FILENAME,
			s.TICKET_FILENAME,
			s.TICKET_DATE,
			s.JOURNAL_ID,
			s.ERROR_FILE,
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
			--t.GuidCRE_TICKET_LOG_302 = s.GuidCRE_TICKET_LOG_302,
			t.ID = s.ID,
			t.BKI_NAME = s.BKI_NAME,
			t.EXPORT_FILENAME = s.EXPORT_FILENAME,
			t.TICKET_FILENAME = s.TICKET_FILENAME,
			t.TICKET_DATE = s.TICKET_DATE,
			t.JOURNAL_ID = s.JOURNAL_ID,
			t.ERROR_FILE = s.ERROR_FILE,
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
