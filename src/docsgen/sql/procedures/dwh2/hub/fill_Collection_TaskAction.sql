/*
exec hub.fill_Collection_TaskAction
*/
create   PROC hub.fill_Collection_TaskAction
	@mode int = 1 -- 0 - full, 1 - increment
	--,@GuidCollection_TaskAction uniqueidentifier = NULL
	,@Id int = null
	,@DealId int = null
	,@isDebug int = 0
as
begin
	--truncate table hub.Collection_TaskAction
begin TRY
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_Collection_TaskAction

	if OBJECT_ID ('hub.Collection_TaskAction') is not NULL
		AND @mode = 1
		and @Id is null
		and @DealId is null
	begin
		set @rowVersion = isnull((select max(H.RowVersion) from hub.Collection_TaskAction as H), 0x0)
	end

	select distinct
		GuidCollection_TaskAction = try_cast(hashbytes('SHA2_256', cast(t.Id as varchar(30))) AS uniqueidentifier),

		t.Id,
		t.DateSettingsTask,

		t.RowVersion,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName,

		Link_GuidCollection_StrategyActionTask = try_cast(hashbytes('SHA2_256', cast(t.StrategyActionTaskId as varchar(30))) AS uniqueidentifier),
		Link_GuidДоговораЗайма = d.CmrId,
		Link_GuidКлиент = c.CrmCustomerId,
		Link_GuidCollection_JudicialProceeding = try_cast(hashbytes('SHA2_256', cast(t.JudicialProceedingId as varchar(30))) AS uniqueidentifier),
		Link_GuidCollection_EnforcementOrder = try_cast(hashbytes('SHA2_256', cast(t.EnforcementOrderId as varchar(30))) AS uniqueidentifier)

	into #t_Collection_TaskAction
	--SELECT top 100 *
	FROM Stg._Collection.TaskAction AS t
		left join Stg._Collection.Deals as d
			on d.Id = t.DealId
		left join Stg._Collection.customers as c
			on c.Id = t.CustomerId
	where 1=1
		and t.RowVersion > @rowVersion
		and (t.Id = @Id or @Id is null)
		and (t.DealId = @DealId or @DealId is null)

	create index ix_GuidCollection_TaskAction
	on #t_Collection_TaskAction(GuidCollection_TaskAction)


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Collection_TaskAction
		SELECT * INTO ##t_Collection_TaskAction FROM #t_Collection_TaskAction
		--RETURN 0
	END


	if OBJECT_ID('link.Collection_TaskAction_stage') is null
	begin
		CREATE TABLE link.Collection_TaskAction_stage
		(
			Id uniqueidentifier NOT NULL CONSTRAINT [DF_Collection_TaskAction_stage__Id] DEFAULT (newid()),
			GuidCollection_TaskAction uniqueidentifier NOT NULL,
			LinkName nvarchar(255) NULL,
			LinkGuid uniqueidentifier NULL,
			created_at datetime NOT NULL CONSTRAINT [DF_Collection_TaskAction_stage__created_at] DEFAULT (getdate()),
			TargetColName nvarchar(255) NULL
		) ON [PRIMARY]

		ALTER TABLE link.Collection_TaskAction_stage
		ADD CONSTRAINT PK__Collection_TaskAction_stage PRIMARY KEY CLUSTERED (Id) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [ix_LinkName] ON link.Collection_TaskAction_stage (LinkName) ON [PRIMARY]
	end

	insert into link.Collection_TaskAction_stage(
		GuidCollection_TaskAction
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		GuidCollection_TaskAction,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_Collection_TaskAction
		CROSS APPLY (
		VALUES 
			(Link_GuidCollection_StrategyActionTask, 'link.Collection_TaskAction_StrategyActionTask', 'GuidCollection_StrategyActionTask'),
			(Link_GuidДоговораЗайма, 'link.Collection_TaskAction_ДоговорЗайма', 'GuidДоговораЗайма'),
			(Link_GuidКлиент, 'link.Collection_TaskAction_Клиент', 'GuidКлиент'),
			(Link_GuidCollection_JudicialProceeding, 'link.Collection_TaskAction_JudicialProceeding', 'GuidCollection_JudicialProceeding'),
			(Link_GuidCollection_EnforcementOrder, 'link.Collection_TaskAction_EnforcementOrder', 'GuidCollection_EnforcementOrder')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null

	--заполнение таблиц с линками
	--BEGIN TRY
		EXEC link.exec_fill_link_between_Collection_TaskAction_and_other
		--EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_Collection_TaskAction_and_other'
	--END TRY
	--BEGIN CATCH
	--	--??
	--END CATCH


	if OBJECT_ID('hub.Collection_TaskAction') is null
	begin
		select top(0)
			GuidCollection_TaskAction,

			Id,
			DateSettingsTask,

			RowVersion,
            created_at,
            updated_at,
            spFillName
		into hub.Collection_TaskAction
		from #t_Collection_TaskAction

		alter table hub.Collection_TaskAction
			alter COLUMN GuidCollection_TaskAction uniqueidentifier not null

		ALTER TABLE hub.Collection_TaskAction
			ADD CONSTRAINT PK__Collection_TaskAction PRIMARY KEY CLUSTERED (GuidCollection_TaskAction)
	end
	
	--begin tran
		merge hub.Collection_TaskAction t
		using #t_Collection_TaskAction s
			on t.GuidCollection_TaskAction = s.GuidCollection_TaskAction
		when not matched then insert
		(
			GuidCollection_TaskAction,

			Id,
			DateSettingsTask,

			RowVersion,
            created_at,
            updated_at,
            spFillName
		) values
		(
			s.GuidCollection_TaskAction,

			s.Id,
			s.DateSettingsTask,

			s.RowVersion,
            s.created_at,
            s.updated_at,
            s.spFillName
		)
		when matched 
			and (t.RowVersion <> s.RowVersion
			OR @mode = 0)
		then update SET
			--t.GuidCollection_TaskAction = s.GuidCollection_TaskAction,
			--t.СсылкаCollection_TaskAction = s.СсылкаCollection_TaskAction,
			t.Id = s.Id,
			t.DateSettingsTask = s.DateSettingsTask,
			t.RowVersion = s.RowVersion,
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
