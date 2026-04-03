--exec hub.fill_Collection_ReturnReasons
CREATE   PROC hub.fill_Collection_ReturnReasons
	@mode int = 1
	,@isDebug int = 0
as
begin
	--truncate table hub.Collection_ReturnReasons
begin TRY
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	if OBJECT_ID ('hub.Collection_ReturnReasons') is not NULL
		AND @mode = 1
	begin
		set @rowVersion = isnull((select max(H.RowVersion) from hub.Collection_ReturnReasons as H), 0x0)
	end

	drop table if exists #t_Collection_ReturnReasons

	select distinct 
		GuidCollection_ReturnReasons = try_cast(hashbytes('SHA2_256', cast(c.Id as varchar(30))) AS uniqueidentifier),

		c.Id,
		c.Name,
		c.[Order],

		c.RowVersion,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName

		--Link_GuidCollection_collectingStage = try_cast(hashbytes('SHA2_256', cast(c.CollectingStageId as varchar(30))) AS uniqueidentifier)
	into #t_Collection_ReturnReasons
	from Stg._Collection.ReturnReasons AS c
	where 1=1
		and c.RowVersion >= @rowVersion

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Collection_ReturnReasons
		SELECT * INTO ##t_Collection_ReturnReasons FROM #t_Collection_ReturnReasons
		--RETURN 0
	END

	/*
	if OBJECT_ID('link.Collection_ReturnReasons_stage') is null
	begin
		CREATE TABLE link.Collection_ReturnReasons_stage
		(
			Id uniqueidentifier NOT NULL CONSTRAINT [DF_Collection_ReturnReasons_stage__Id] DEFAULT (newid()),
			GuidCollection_ReturnReasons uniqueidentifier NOT NULL,
			LinkName nvarchar(255) NULL,
			LinkGuid uniqueidentifier NULL,
			created_at datetime NOT NULL CONSTRAINT [DF_Collection_ReturnReasons_stage__created_at] DEFAULT (getdate()),
			TargetColName nvarchar(255) NULL
		) ON [PRIMARY]

		ALTER TABLE link.Collection_ReturnReasons_stage
		ADD CONSTRAINT PK__Collection_ReturnReasons_stage PRIMARY KEY CLUSTERED (Id) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [ix_LinkName] ON link.Collection_ReturnReasons_stage (LinkName) ON [PRIMARY]
	end

	insert into link.Collection_ReturnReasons_stage(
		GuidCollection_ReturnReasons
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		GuidCollection_ReturnReasons,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_Collection_ReturnReasons
		CROSS APPLY (
			VALUES 
				  (Link_GuidCollection_collectingStage, 'link.Collection_ReturnReasons_collectingStage', 'GuidCollection_collectingStage')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null

	--заполнение таблиц с линками
	--BEGIN TRY
		EXEC link.exec_fill_link_between_Collection_ReturnReasons_and_other
		--EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_Collection_ReturnReasons_and_other'
	--END TRY
	--BEGIN CATCH
	--	--??
	*/

	if OBJECT_ID('hub.Collection_ReturnReasons') is null
	begin
		select top(0)
			GuidCollection_ReturnReasons,

			Id,
			Name,
			[Order],

			RowVersion,

			created_at,
			updated_at,
			spFillName
		into hub.Collection_ReturnReasons
		from #t_Collection_ReturnReasons

		alter table hub.Collection_ReturnReasons
			alter column GuidCollection_ReturnReasons uniqueidentifier not null

		ALTER TABLE hub.Collection_ReturnReasons
			ADD CONSTRAINT PK_Collection_ReturnReasons PRIMARY KEY CLUSTERED (GuidCollection_ReturnReasons)
	end
	
	--begin tran
		merge hub.Collection_ReturnReasons t
		using #t_Collection_ReturnReasons s
			on t.GuidCollection_ReturnReasons = s.GuidCollection_ReturnReasons
		when not matched then insert
		(
			GuidCollection_ReturnReasons,

			Id,
			Name,
			[Order],

			RowVersion,

			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidCollection_ReturnReasons,

			s.Id,
			s.Name,
			s.[Order],

			s.RowVersion,

			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched 
			and (t.RowVersion <> s.RowVersion
			OR @mode = 0)
		then update SET

			t.Id = s.Id,
			t.Name = s.Name,
			t.[Order] = s.[Order],

			t.RowVersion = s.RowVersion,

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
