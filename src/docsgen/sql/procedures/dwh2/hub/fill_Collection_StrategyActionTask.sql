--exec hub.fill_Collection_StrategyActionTask
CREATE   PROC hub.fill_Collection_StrategyActionTask
	--@mode int = 1
as
begin
	--truncate table hub.Collection_StrategyActionTask
begin TRY
	--SELECT @mode = isnull(@mode, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)

	drop table if exists #t_Collection_StrategyActionTask

	select distinct 
		GuidCollection_StrategyActionTask = try_cast(hashbytes('SHA2_256', cast(sat.Id as varchar(30))) AS uniqueidentifier),
		sat.Id,
		sat.Name,
		sat.ActionId,
		sat.Description,
		--CollectingStageId --link
		sat.HasCreateDublicate,
		sat.HasAdditionalParametersShow,
		--TargetTypeId --link?
		sat.HasPreSelectEmployee,
		sat.[Order],
		--StatusOfSubprocessId --link?
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName,

		Link_GuidCollection_collectingStage = try_cast(hashbytes('SHA2_256', cast(sat.CollectingStageId as varchar(30))) AS uniqueidentifier)
	into #t_Collection_StrategyActionTask
	from Stg._Collection.StrategyActionTask AS sat

	if OBJECT_ID('link.Collection_StrategyActionTask_stage') is null
	begin
		CREATE TABLE link.Collection_StrategyActionTask_stage
		(
			Id uniqueidentifier NOT NULL CONSTRAINT [DF_Collection_StrategyActionTask_stage__Id] DEFAULT (newid()),
			GuidCollection_StrategyActionTask uniqueidentifier NOT NULL,
			LinkName nvarchar(255) NULL,
			LinkGuid uniqueidentifier NULL,
			created_at datetime NOT NULL CONSTRAINT [DF_Collection_StrategyActionTask_stage__created_at] DEFAULT (getdate()),
			TargetColName nvarchar(255) NULL
		) ON [PRIMARY]

		ALTER TABLE link.Collection_StrategyActionTask_stage
		ADD CONSTRAINT PK__Collection_StrategyActionTask_stage PRIMARY KEY CLUSTERED (Id) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [ix_LinkName] ON link.Collection_StrategyActionTask_stage (LinkName) ON [PRIMARY]
	end

	insert into link.Collection_StrategyActionTask_stage(
		GuidCollection_StrategyActionTask
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		GuidCollection_StrategyActionTask,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_Collection_StrategyActionTask
		CROSS APPLY (
			VALUES 
				  (Link_GuidCollection_collectingStage, 'link.Collection_StrategyActionTask_collectingStage', 'GuidCollection_collectingStage')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null

	--заполнение таблиц с линками
	--BEGIN TRY
		EXEC link.exec_fill_link_between_Collection_StrategyActionTask_and_other
		--EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_Collection_StrategyActionTask_and_other'
	--END TRY
	--BEGIN CATCH
	--	--??


	if OBJECT_ID('hub.Collection_StrategyActionTask') is null
	begin
		select top(0)
			GuidCollection_StrategyActionTask,
			Id,
			Name,
			ActionId,
			Description,
			HasCreateDublicate,
			HasAdditionalParametersShow,
			HasPreSelectEmployee,
			[Order],

			created_at,
			updated_at,
			spFillName
		into hub.Collection_StrategyActionTask
		from #t_Collection_StrategyActionTask

		alter table hub.Collection_StrategyActionTask
			alter column GuidCollection_StrategyActionTask uniqueidentifier not null

		ALTER TABLE hub.Collection_StrategyActionTask
			ADD CONSTRAINT PK_Collection_StrategyActionTask PRIMARY KEY CLUSTERED (GuidCollection_StrategyActionTask)
	end
	
	--begin tran
		merge hub.Collection_StrategyActionTask t
		using #t_Collection_StrategyActionTask s
			on t.GuidCollection_StrategyActionTask = s.GuidCollection_StrategyActionTask
		when not matched then insert
		(
			GuidCollection_StrategyActionTask,
			Id,
			Name,
			ActionId,
			Description,
			HasCreateDublicate,
			HasAdditionalParametersShow,
			HasPreSelectEmployee,
			[Order],

			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidCollection_StrategyActionTask,
			s.Id,
			s.Name,
			s.ActionId,
			s.Description,
			s.HasCreateDublicate,
			s.HasAdditionalParametersShow,
			s.HasPreSelectEmployee,
			s.[Order],

			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched 
			--and t.ВерсияДанных !=s.ВерсияДанных
			--OR @mode = 0
		then update SET
			t.Id = s.Id,
			t.Name = s.Name,
			t.ActionId = s.ActionId,
			t.Description = s.Description,
			t.HasCreateDublicate = s.HasCreateDublicate,
			t.HasAdditionalParametersShow = s.HasAdditionalParametersShow,
			t.HasPreSelectEmployee = s.HasPreSelectEmployee,
			t.[Order] = s.[Order],
			--t.created_at = s.created_at,
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
