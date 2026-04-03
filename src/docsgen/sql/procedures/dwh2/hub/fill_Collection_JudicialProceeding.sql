/*
exec hub.fill_Collection_JudicialProceeding
*/
create   PROC hub.fill_Collection_JudicialProceeding
	@mode int = 1 -- 0 - full, 1 - increment
	--,@GuidCollection_JudicialProceeding uniqueidentifier = NULL
	,@Id int = null
	,@DealId int = null
	,@isDebug int = 0
as
begin
	--truncate table hub.Collection_JudicialProceeding
begin TRY
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_Collection_JudicialProceeding

	if OBJECT_ID ('hub.Collection_JudicialProceeding') is not NULL
		AND @mode = 1
		and @Id is null
		and @DealId is null
	begin
		set @rowVersion = isnull((select max(H.RowVersion) from hub.Collection_JudicialProceeding as H), 0x0)
	end

	select distinct
		GuidCollection_JudicialProceeding = try_cast(hashbytes('SHA2_256', cast(t.Id as varchar(30))) AS uniqueidentifier),

		t.Id,
		t.UpdateDate,
		SubmissionClaimDate = cast(t.SubmissionClaimDate as date), --Дата отправки требования клиенту
		AmountClaim = cast(t.AmountClaim as money), -- 'Сумма требования'
		t.UpdatedBy,
		t.CreatedBy,
		t.CreateDate,
		--CourtId,
		t.OutgoingRegistryRequirementNumber,
		t.OutgoingRequirementNumber,
		t.TotalRequirement,
		--DealId,
		--DocumentGuid,
		t.StatusCourtDetermination,
		t.IsFake,
		--DepartamentFSSPId
		t.IsCmrStateDutyClaimPackageSend,

		t.RowVersion,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName,

		Link_GuidCollection_Courts = try_cast(hashbytes('SHA2_256', cast(t.CourtId as varchar(30))) AS uniqueidentifier),
		Link_GuidДоговораЗайма = d.CmrId

	into #t_Collection_JudicialProceeding
	--SELECT top 100 *
	FROM Stg._Collection.JudicialProceeding AS t
		left join Stg._Collection.Deals as d
			on d.Id = t.DealId
	where 1=1
		and t.RowVersion > @rowVersion
		and (t.Id = @Id or @Id is null)
		and (t.DealId = @DealId or @DealId is null)

	create index ix_GuidCollection_JudicialProceeding
	on #t_Collection_JudicialProceeding(GuidCollection_JudicialProceeding)


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Collection_JudicialProceeding
		SELECT * INTO ##t_Collection_JudicialProceeding FROM #t_Collection_JudicialProceeding
		--RETURN 0
	END


	if OBJECT_ID('link.Collection_JudicialProceeding_stage') is null
	begin
		CREATE TABLE link.Collection_JudicialProceeding_stage
		(
			Id uniqueidentifier NOT NULL CONSTRAINT [DF_Collection_JudicialProceeding_stage__Id] DEFAULT (newid()),
			GuidCollection_JudicialProceeding uniqueidentifier NOT NULL,
			LinkName nvarchar(255) NULL,
			LinkGuid uniqueidentifier NULL,
			created_at datetime NOT NULL CONSTRAINT [DF_Collection_JudicialProceeding_stage__created_at] DEFAULT (getdate()),
			TargetColName nvarchar(255) NULL
		) ON [PRIMARY]

		ALTER TABLE link.Collection_JudicialProceeding_stage
		ADD CONSTRAINT PK__Collection_JudicialProceeding_stage PRIMARY KEY CLUSTERED (Id) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [ix_LinkName] ON link.Collection_JudicialProceeding_stage (LinkName) ON [PRIMARY]
	end

	insert into link.Collection_JudicialProceeding_stage(
		GuidCollection_JudicialProceeding
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		GuidCollection_JudicialProceeding,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_Collection_JudicialProceeding
		CROSS APPLY (
		VALUES 
			(Link_GuidCollection_Courts, 'link.Collection_JudicialProceeding_Courts', 'GuidCollection_Courts'),
			(Link_GuidДоговораЗайма, 'link.Collection_JudicialProceeding_ДоговорЗайма', 'GuidДоговораЗайма')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null

	--заполнение таблиц с линками
	--BEGIN TRY
		EXEC link.exec_fill_link_between_Collection_JudicialProceeding_and_other
		--EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_Collection_JudicialProceeding_and_other'
	--END TRY
	--BEGIN CATCH
	--	--??
	--END CATCH


	if OBJECT_ID('hub.Collection_JudicialProceeding') is null
	begin
		select top(0)
			GuidCollection_JudicialProceeding,

			Id,
			UpdateDate,
			SubmissionClaimDate,
			AmountClaim,
			UpdatedBy,
			CreatedBy,
			CreateDate,
			OutgoingRegistryRequirementNumber,
			OutgoingRequirementNumber,
			TotalRequirement,
			StatusCourtDetermination,
			IsFake,
			IsCmrStateDutyClaimPackageSend,

			RowVersion,

            created_at,
            updated_at,
            spFillName
		into hub.Collection_JudicialProceeding
		from #t_Collection_JudicialProceeding

		alter table hub.Collection_JudicialProceeding
			alter COLUMN GuidCollection_JudicialProceeding uniqueidentifier not null

		ALTER TABLE hub.Collection_JudicialProceeding
			ADD CONSTRAINT PK__Collection_JudicialProceeding PRIMARY KEY CLUSTERED (GuidCollection_JudicialProceeding)
	end
	
	--begin tran
		merge hub.Collection_JudicialProceeding t
		using #t_Collection_JudicialProceeding s
			on t.GuidCollection_JudicialProceeding = s.GuidCollection_JudicialProceeding
		when not matched then insert
		(
			GuidCollection_JudicialProceeding,

			Id,
			UpdateDate,
			SubmissionClaimDate,
			AmountClaim,
			UpdatedBy,
			CreatedBy,
			CreateDate,
			OutgoingRegistryRequirementNumber,
			OutgoingRequirementNumber,
			TotalRequirement,
			StatusCourtDetermination,
			IsFake,
			IsCmrStateDutyClaimPackageSend,

			RowVersion,

            created_at,
            updated_at,
            spFillName
		) values
		(
			s.GuidCollection_JudicialProceeding,

			s.Id,
			s.UpdateDate,
			s.SubmissionClaimDate,
			s.AmountClaim,
			s.UpdatedBy,
			s.CreatedBy,
			s.CreateDate,
			s.OutgoingRegistryRequirementNumber,
			s.OutgoingRequirementNumber,
			s.TotalRequirement,
			s.StatusCourtDetermination,
			s.IsFake,
			s.IsCmrStateDutyClaimPackageSend,

			s.RowVersion,

            s.created_at,
            s.updated_at,
            s.spFillName
		)
		when matched 
			and (t.RowVersion <> s.RowVersion
			OR @mode = 0)
		then update SET
			--t.GuidCollection_JudicialProceeding = s.GuidCollection_JudicialProceeding,
			--t.СсылкаCollection_JudicialProceeding = s.СсылкаCollection_JudicialProceeding,
			t.Id = s.Id,
			t.UpdateDate = s.UpdateDate,
			t.SubmissionClaimDate = s.SubmissionClaimDate,
			t.AmountClaim = s.AmountClaim,
			t.UpdatedBy = s.UpdatedBy,
			t.CreatedBy = s.CreatedBy,
			t.CreateDate = s.CreateDate,
			t.OutgoingRegistryRequirementNumber = s.OutgoingRegistryRequirementNumber,
			t.OutgoingRequirementNumber = s.OutgoingRequirementNumber,
			t.TotalRequirement = s.TotalRequirement,
			t.StatusCourtDetermination = s.StatusCourtDetermination,
			t.IsFake = s.IsFake,
			t.IsCmrStateDutyClaimPackageSend = s.IsCmrStateDutyClaimPackageSend,

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
