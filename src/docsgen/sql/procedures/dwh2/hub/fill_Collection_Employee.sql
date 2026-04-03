--exec hub.fill_Collection_Employee
CREATE   PROC hub.fill_Collection_Employee
	@mode int = 1
	,@isDebug int = 0
as
begin
	--truncate table hub.Collection_Employee
begin TRY
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	if OBJECT_ID ('hub.Collection_Employee') is not NULL
		AND @mode = 1
	begin
		set @rowVersion = isnull((select max(H.RowVersion) from hub.Collection_Employee as H), 0x0)
	end

	drop table if exists #t_Collection_Employee

	select distinct 
		GuidCollection_Employee = try_cast(hashbytes('SHA2_256', cast(c.Id as varchar(30))) AS uniqueidentifier),

		c.Id,
		c.FirstName,
		c.LastName,
		c.MiddleName,
		FullName = concat(
			trim(C.LastName), ' ', 
			trim(C.FirstName), ' ', 
			CASE WHEN trim(C.MiddleName) IN ('-') THEN '' ELSE trim(C.MiddleName) END
		),
		c.NaumenUserLogin,
		c.CorporatePhone,
		c.ExtensionNumber,
		c.Chat2DeskLogin,
		c.TypeClaimantLegal,
		c.IsFired,
		c.Position,

		c.RowVersion,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName

		--Link_GuidCollection_collectingStage = try_cast(hashbytes('SHA2_256', cast(c.CollectingStageId as varchar(30))) AS uniqueidentifier)
	into #t_Collection_Employee
	from Stg._Collection.Employee AS c
	where 1=1
		and c.RowVersion >= @rowVersion

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Collection_Employee
		SELECT * INTO ##t_Collection_Employee FROM #t_Collection_Employee
		--RETURN 0
	END

	/*
	if OBJECT_ID('link.Collection_Employee_stage') is null
	begin
		CREATE TABLE link.Collection_Employee_stage
		(
			Id uniqueidentifier NOT NULL CONSTRAINT [DF_Collection_Employee_stage__Id] DEFAULT (newid()),
			GuidCollection_Employee uniqueidentifier NOT NULL,
			LinkName nvarchar(255) NULL,
			LinkGuid uniqueidentifier NULL,
			created_at datetime NOT NULL CONSTRAINT [DF_Collection_Employee_stage__created_at] DEFAULT (getdate()),
			TargetColName nvarchar(255) NULL
		) ON [PRIMARY]

		ALTER TABLE link.Collection_Employee_stage
		ADD CONSTRAINT PK__Collection_Employee_stage PRIMARY KEY CLUSTERED (Id) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [ix_LinkName] ON link.Collection_Employee_stage (LinkName) ON [PRIMARY]
	end

	insert into link.Collection_Employee_stage(
		GuidCollection_Employee
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		GuidCollection_Employee,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_Collection_Employee
		CROSS APPLY (
			VALUES 
				  (Link_GuidCollection_collectingStage, 'link.Collection_Employee_collectingStage', 'GuidCollection_collectingStage')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null

	--заполнение таблиц с линками
	--BEGIN TRY
		EXEC link.exec_fill_link_between_Collection_Employee_and_other
		--EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_Collection_Employee_and_other'
	--END TRY
	--BEGIN CATCH
	--	--??
	*/

	if OBJECT_ID('hub.Collection_Employee') is null
	begin
		select top(0)
			GuidCollection_Employee,

			Id,
			FirstName,
			LastName,
			MiddleName,
			FullName,
			NaumenUserLogin,
			CorporatePhone,
			ExtensionNumber,
			Chat2DeskLogin,
			TypeClaimantLegal,
			IsFired,
			Position,

			RowVersion,

			created_at,
			updated_at,
			spFillName
		into hub.Collection_Employee
		from #t_Collection_Employee

		alter table hub.Collection_Employee
			alter column GuidCollection_Employee uniqueidentifier not null

		ALTER TABLE hub.Collection_Employee
			ADD CONSTRAINT PK_Collection_Employee PRIMARY KEY CLUSTERED (GuidCollection_Employee)
	end
	
	--begin tran
		merge hub.Collection_Employee t
		using #t_Collection_Employee s
			on t.GuidCollection_Employee = s.GuidCollection_Employee
		when not matched then insert
		(
			GuidCollection_Employee,

			Id,
			FirstName,
			LastName,
			MiddleName,
			FullName,
			NaumenUserLogin,
			CorporatePhone,
			ExtensionNumber,
			Chat2DeskLogin,
			TypeClaimantLegal,
			IsFired,
			Position,

			RowVersion,

			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidCollection_Employee,

			s.Id,
			s.FirstName,
			s.LastName,
			s.MiddleName,
			s.FullName,
			s.NaumenUserLogin,
			s.CorporatePhone,
			s.ExtensionNumber,
			s.Chat2DeskLogin,
			s.TypeClaimantLegal,
			s.IsFired,
			s.Position,

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

			t.FirstName = s.FirstName,
			t.LastName = s.LastName,
			t.MiddleName = s.MiddleName,
			t.FullName = s.FullName,
			t.NaumenUserLogin = s.NaumenUserLogin,
			t.CorporatePhone = s.CorporatePhone,
			t.ExtensionNumber = s.ExtensionNumber,
			t.Chat2DeskLogin = s.Chat2DeskLogin,
			t.TypeClaimantLegal = s.TypeClaimantLegal,
			t.IsFired = s.IsFired,
			t.Position = s.Position,

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
