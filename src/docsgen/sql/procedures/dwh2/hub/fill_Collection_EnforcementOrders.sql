/*
exec hub.fill_Collection_EnforcementOrders
*/
create   PROC hub.fill_Collection_EnforcementOrders
	@mode int = 1 -- 0 - full, 1 - increment
	--,@GuidCollection_EnforcementOrders uniqueidentifier = NULL
	,@Id int = null
	,@DealId int = null
	,@isDebug int = 0
as
begin
	--truncate table hub.Collection_EnforcementOrders
begin TRY
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_Collection_EnforcementOrders

	if OBJECT_ID ('hub.Collection_EnforcementOrders') is not NULL
		AND @mode = 1
		and @Id is null
		and @DealId is null
	begin
		set @rowVersion = isnull((select max(H.RowVersion) from hub.Collection_EnforcementOrders as H), 0x0)
	end

	select distinct
		GuidCollection_EnforcementOrders = try_cast(hashbytes('SHA2_256', cast(t.Id as varchar(30))) AS uniqueidentifier),

		t.Id,
		t.RowVersion,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName,

		Link_GuidCollection_JudicialClaims = try_cast(hashbytes('SHA2_256', cast(t.JudicialClaimId as varchar(30))) AS uniqueidentifier)

		--Link_GuidДоговораЗайма = d.CmrId

	into #t_Collection_EnforcementOrders
	--SELECT top 100 *
	FROM Stg._Collection.EnforcementOrders AS t
		left join Stg._Collection.JudicialClaims AS jc
			on t.JudicialClaimId = jc.Id
		left join Stg._Collection.JudicialProceeding as jp
			on jc.JudicialProceedingId = jp.Id
	where 1=1
		and t.RowVersion > @rowVersion
		and (t.Id = @Id or @Id is null)
		and (jp.DealId = @DealId or @DealId is null)

	create index ix_GuidCollection_EnforcementOrders
	on #t_Collection_EnforcementOrders(GuidCollection_EnforcementOrders)


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Collection_EnforcementOrders
		SELECT * INTO ##t_Collection_EnforcementOrders FROM #t_Collection_EnforcementOrders
		--RETURN 0
	END


	if OBJECT_ID('link.Collection_EnforcementOrders_stage') is null
	begin
		CREATE TABLE link.Collection_EnforcementOrders_stage
		(
			Id uniqueidentifier NOT NULL CONSTRAINT [DF_Collection_EnforcementOrders_stage__Id] DEFAULT (newid()),
			GuidCollection_EnforcementOrders uniqueidentifier NOT NULL,
			LinkName nvarchar(255) NULL,
			LinkGuid uniqueidentifier NULL,
			created_at datetime NOT NULL CONSTRAINT [DF_Collection_EnforcementOrders_stage__created_at] DEFAULT (getdate()),
			TargetColName nvarchar(255) NULL
		) ON [PRIMARY]

		ALTER TABLE link.Collection_EnforcementOrders_stage
		ADD CONSTRAINT PK__Collection_EnforcementOrders_stage PRIMARY KEY CLUSTERED (Id) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [ix_LinkName] ON link.Collection_EnforcementOrders_stage (LinkName) ON [PRIMARY]
	end

	insert into link.Collection_EnforcementOrders_stage(
		GuidCollection_EnforcementOrders
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		GuidCollection_EnforcementOrders,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_Collection_EnforcementOrders
		CROSS APPLY (
		VALUES 
			(Link_GuidCollection_JudicialClaims, 'link.Collection_EnforcementOrders_JudicialClaims', 'GuidCollection_JudicialClaims')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null

	--заполнение таблиц с линками
	--BEGIN TRY
		EXEC link.exec_fill_link_between_Collection_EnforcementOrders_and_other
		--EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_Collection_EnforcementOrders_and_other'
	--END TRY
	--BEGIN CATCH
	--	--??
	--END CATCH


	if OBJECT_ID('hub.Collection_EnforcementOrders') is null
	begin
		select top(0)
			GuidCollection_EnforcementOrders,

			Id,
			RowVersion,

            created_at,
            updated_at,
            spFillName
		into hub.Collection_EnforcementOrders
		from #t_Collection_EnforcementOrders

		alter table hub.Collection_EnforcementOrders
			alter COLUMN GuidCollection_EnforcementOrders uniqueidentifier not null

		ALTER TABLE hub.Collection_EnforcementOrders
			ADD CONSTRAINT PK__Collection_EnforcementOrders PRIMARY KEY CLUSTERED (GuidCollection_EnforcementOrders)
	end
	
	--begin tran
		merge hub.Collection_EnforcementOrders t
		using #t_Collection_EnforcementOrders s
			on t.GuidCollection_EnforcementOrders = s.GuidCollection_EnforcementOrders
		when not matched then insert
		(
			GuidCollection_EnforcementOrders,

			Id,
			RowVersion,

            created_at,
            updated_at,
            spFillName
		) values
		(
			s.GuidCollection_EnforcementOrders,

			s.Id,
			s.RowVersion,

            s.created_at,
            s.updated_at,
            s.spFillName
		)
		when matched 
			and (t.RowVersion <> s.RowVersion
			OR @mode = 0)
		then update SET
			--t.GuidCollection_EnforcementOrders = s.GuidCollection_EnforcementOrders,
			--t.СсылкаCollection_EnforcementOrders = s.СсылкаCollection_EnforcementOrders,
			t.Id = s.Id,
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
