/*
exec hub.fill_Collection_JudicialClaims
*/
create   PROC hub.fill_Collection_JudicialClaims
	@mode int = 1 -- 0 - full, 1 - increment
	--,@GuidCollection_JudicialClaims uniqueidentifier = NULL
	,@Id int = null
	,@DealId int = null
	,@isDebug int = 0
as
begin
	--truncate table hub.Collection_JudicialClaims
begin TRY
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_Collection_JudicialClaims

	if OBJECT_ID ('hub.Collection_JudicialClaims') is not NULL
		AND @mode = 1
		and @Id is null
		and @DealId is null
	begin
		set @rowVersion = isnull((select max(H.RowVersion) from hub.Collection_JudicialClaims as H), 0x0)
	end

	select distinct
		GuidCollection_JudicialClaims = try_cast(hashbytes('SHA2_256', cast(t.Id as varchar(30))) AS uniqueidentifier),

		t.Id,
		t.RowVersion,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName,

		Link_GuidCollection_JudicialProceeding = try_cast(hashbytes('SHA2_256', cast(t.JudicialProceedingId as varchar(30))) AS uniqueidentifier),
		Link_GuidCollection_ClaimRevocationReasons = try_cast(hashbytes('SHA2_256', cast(t.ClaimRevocationReasonId as varchar(30))) AS uniqueidentifier),
		Link_GuidCollection_ReturnReasons = try_cast(hashbytes('SHA2_256', cast(t.ReturnReasonId as varchar(30))) AS uniqueidentifier)
		
		--Link_GuidДоговораЗайма = d.CmrId

	into #t_Collection_JudicialClaims
	--SELECT top 100 *
	FROM Stg._Collection.JudicialClaims AS t
		left join Stg._Collection.JudicialProceeding as jp
			on t.JudicialProceedingId = jp.Id
	where 1=1
		and t.RowVersion > @rowVersion
		and (t.Id = @Id or @Id is null)
		and (jp.DealId = @DealId or @DealId is null)

	create index ix_GuidCollection_JudicialClaims
	on #t_Collection_JudicialClaims(GuidCollection_JudicialClaims)


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Collection_JudicialClaims
		SELECT * INTO ##t_Collection_JudicialClaims FROM #t_Collection_JudicialClaims
		--RETURN 0
	END


	if OBJECT_ID('link.Collection_JudicialClaims_stage') is null
	begin
		CREATE TABLE link.Collection_JudicialClaims_stage
		(
			Id uniqueidentifier NOT NULL CONSTRAINT [DF_Collection_JudicialClaims_stage__Id] DEFAULT (newid()),
			GuidCollection_JudicialClaims uniqueidentifier NOT NULL,
			LinkName nvarchar(255) NULL,
			LinkGuid uniqueidentifier NULL,
			created_at datetime NOT NULL CONSTRAINT [DF_Collection_JudicialClaims_stage__created_at] DEFAULT (getdate()),
			TargetColName nvarchar(255) NULL
		) ON [PRIMARY]

		ALTER TABLE link.Collection_JudicialClaims_stage
		ADD CONSTRAINT PK__Collection_JudicialClaims_stage PRIMARY KEY CLUSTERED (Id) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [ix_LinkName] ON link.Collection_JudicialClaims_stage (LinkName) ON [PRIMARY]
	end

	insert into link.Collection_JudicialClaims_stage(
		GuidCollection_JudicialClaims
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		GuidCollection_JudicialClaims,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_Collection_JudicialClaims
		CROSS APPLY (
		VALUES 
			(Link_GuidCollection_JudicialProceeding, 'link.Collection_JudicialClaims_JudicialProceeding', 'GuidCollection_JudicialProceeding'),
			(Link_GuidCollection_ClaimRevocationReasons, 'link.Collection_JudicialClaims_ClaimRevocationReasons', 'GuidCollection_ClaimRevocationReasons'),
			(Link_GuidCollection_ReturnReasons, 'link.Collection_JudicialClaims_ReturnReasons', 'GuidCollection_ReturnReasons')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null

	--заполнение таблиц с линками
	--BEGIN TRY
		EXEC link.exec_fill_link_between_Collection_JudicialClaims_and_other
		--EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_Collection_JudicialClaims_and_other'
	--END TRY
	--BEGIN CATCH
	--	--??
	--END CATCH


	if OBJECT_ID('hub.Collection_JudicialClaims') is null
	begin
		select top(0)
			GuidCollection_JudicialClaims,

			Id,
			RowVersion,

            created_at,
            updated_at,
            spFillName
		into hub.Collection_JudicialClaims
		from #t_Collection_JudicialClaims

		alter table hub.Collection_JudicialClaims
			alter COLUMN GuidCollection_JudicialClaims uniqueidentifier not null

		ALTER TABLE hub.Collection_JudicialClaims
			ADD CONSTRAINT PK__Collection_JudicialClaims PRIMARY KEY CLUSTERED (GuidCollection_JudicialClaims)
	end
	
	--begin tran
		merge hub.Collection_JudicialClaims t
		using #t_Collection_JudicialClaims s
			on t.GuidCollection_JudicialClaims = s.GuidCollection_JudicialClaims
		when not matched then insert
		(
			GuidCollection_JudicialClaims,

			Id,
			RowVersion,

            created_at,
            updated_at,
            spFillName
		) values
		(
			s.GuidCollection_JudicialClaims,

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
			--t.GuidCollection_JudicialClaims = s.GuidCollection_JudicialClaims,
			--t.СсылкаCollection_JudicialClaims = s.СсылкаCollection_JudicialClaims,
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
