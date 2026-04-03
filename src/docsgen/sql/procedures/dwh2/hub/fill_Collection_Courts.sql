--exec hub.fill_Collection_Courts
CREATE   PROC hub.fill_Collection_Courts
	@mode int = 1
	,@isDebug int = 0
as
begin
	--truncate table hub.Collection_Courts
begin TRY
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	if OBJECT_ID ('hub.Collection_Courts') is not NULL
		AND @mode = 1
	begin
		set @rowVersion = isnull((select max(H.RowVersion) from hub.Collection_Courts as H), 0x0)
	end

	drop table if exists #t_Collection_Courts

	select distinct 
		GuidCollection_Courts = try_cast(hashbytes('SHA2_256', cast(c.Id as varchar(30))) AS uniqueidentifier),

		c.Id,
		c.Name,
		c.BIK,
		c.Code,
		c.Email,
		c.INN,
		c.KPP,
		c.KBK,
		c.NameBank,
		c.NameRegion,
		c.NumberExpenseAccount,
		c.OKTMO,
		c.Phone,
		c.Recipient,
		c.ZipCode,
		c.TaxBlockNumber,
		c.TaxName,
		c.TaxNameLocality,
		c.TaxNameRegion,
		c.TaxNameStreet,
		c.TaxNameTown,
		c.TaxStreetNumber,
		c.TaxZipCode,
		c.UploadDate,
		c.AddresseeInDativeCase,
		c.CorrespondentAccount,
		c.CourtType,
		c.CourtWebsite,
		c.DigitApplicationAllowed,
		c.IfnsAddress,
		c.IfnsCode,
		c.IfnsPhone,
		c.IfnsWebsite,
		c.SblId,
		c.DepartmentFsspId,
		c.FullAddress,

		c.RowVersion,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName

		--Link_GuidCollection_collectingStage = try_cast(hashbytes('SHA2_256', cast(c.CollectingStageId as varchar(30))) AS uniqueidentifier)
	into #t_Collection_Courts
	from Stg._Collection.Courts AS c
	where 1=1
		and c.RowVersion >= @rowVersion

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Collection_Courts
		SELECT * INTO ##t_Collection_Courts FROM #t_Collection_Courts
		--RETURN 0
	END

	/*
	if OBJECT_ID('link.Collection_Courts_stage') is null
	begin
		CREATE TABLE link.Collection_Courts_stage
		(
			Id uniqueidentifier NOT NULL CONSTRAINT [DF_Collection_Courts_stage__Id] DEFAULT (newid()),
			GuidCollection_Courts uniqueidentifier NOT NULL,
			LinkName nvarchar(255) NULL,
			LinkGuid uniqueidentifier NULL,
			created_at datetime NOT NULL CONSTRAINT [DF_Collection_Courts_stage__created_at] DEFAULT (getdate()),
			TargetColName nvarchar(255) NULL
		) ON [PRIMARY]

		ALTER TABLE link.Collection_Courts_stage
		ADD CONSTRAINT PK__Collection_Courts_stage PRIMARY KEY CLUSTERED (Id) ON [PRIMARY]

		CREATE NONCLUSTERED INDEX [ix_LinkName] ON link.Collection_Courts_stage (LinkName) ON [PRIMARY]
	end

	insert into link.Collection_Courts_stage(
		GuidCollection_Courts
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		GuidCollection_Courts,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_Collection_Courts
		CROSS APPLY (
			VALUES 
				  (Link_GuidCollection_collectingStage, 'link.Collection_Courts_collectingStage', 'GuidCollection_collectingStage')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null

	--заполнение таблиц с линками
	--BEGIN TRY
		EXEC link.exec_fill_link_between_Collection_Courts_and_other
		--EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_Collection_Courts_and_other'
	--END TRY
	--BEGIN CATCH
	--	--??
	*/

	if OBJECT_ID('hub.Collection_Courts') is null
	begin
		select top(0)
			GuidCollection_Courts,

			Id,
			Name,
			BIK,
			Code,
			Email,
			INN,
			KPP,
			KBK,
			NameBank,
			NameRegion,
			NumberExpenseAccount,
			OKTMO,
			Phone,
			Recipient,
			ZipCode,
			TaxBlockNumber,
			TaxName,
			TaxNameLocality,
			TaxNameRegion,
			TaxNameStreet,
			TaxNameTown,
			TaxStreetNumber,
			TaxZipCode,
			UploadDate,
			AddresseeInDativeCase,
			CorrespondentAccount,
			CourtType,
			CourtWebsite,
			DigitApplicationAllowed,
			IfnsAddress,
			IfnsCode,
			IfnsPhone,
			IfnsWebsite,
			SblId,
			DepartmentFsspId,
			FullAddress,

			RowVersion,

			created_at,
			updated_at,
			spFillName
		into hub.Collection_Courts
		from #t_Collection_Courts

		alter table hub.Collection_Courts
			alter column GuidCollection_Courts uniqueidentifier not null

		ALTER TABLE hub.Collection_Courts
			ADD CONSTRAINT PK_Collection_Courts PRIMARY KEY CLUSTERED (GuidCollection_Courts)
	end
	
	--begin tran
		merge hub.Collection_Courts t
		using #t_Collection_Courts s
			on t.GuidCollection_Courts = s.GuidCollection_Courts
		when not matched then insert
		(
			GuidCollection_Courts,

			Id,
			Name,
			BIK,
			Code,
			Email,
			INN,
			KPP,
			KBK,
			NameBank,
			NameRegion,
			NumberExpenseAccount,
			OKTMO,
			Phone,
			Recipient,
			ZipCode,
			TaxBlockNumber,
			TaxName,
			TaxNameLocality,
			TaxNameRegion,
			TaxNameStreet,
			TaxNameTown,
			TaxStreetNumber,
			TaxZipCode,
			UploadDate,
			AddresseeInDativeCase,
			CorrespondentAccount,
			CourtType,
			CourtWebsite,
			DigitApplicationAllowed,
			IfnsAddress,
			IfnsCode,
			IfnsPhone,
			IfnsWebsite,
			SblId,
			DepartmentFsspId,
			FullAddress,

			RowVersion,

			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidCollection_Courts,

			s.Id,
			s.Name,
			s.BIK,
			s.Code,
			s.Email,
			s.INN,
			s.KPP,
			s.KBK,
			s.NameBank,
			s.NameRegion,
			s.NumberExpenseAccount,
			s.OKTMO,
			s.Phone,
			s.Recipient,
			s.ZipCode,
			s.TaxBlockNumber,
			s.TaxName,
			s.TaxNameLocality,
			s.TaxNameRegion,
			s.TaxNameStreet,
			s.TaxNameTown,
			s.TaxStreetNumber,
			s.TaxZipCode,
			s.UploadDate,
			s.AddresseeInDativeCase,
			s.CorrespondentAccount,
			s.CourtType,
			s.CourtWebsite,
			s.DigitApplicationAllowed,
			s.IfnsAddress,
			s.IfnsCode,
			s.IfnsPhone,
			s.IfnsWebsite,
			s.SblId,
			s.DepartmentFsspId,
			s.FullAddress,

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
			t.BIK = s.BIK,
			t.Code = s.Code,
			t.Email = s.Email,
			t.INN = s.INN,
			t.KPP = s.KPP,
			t.KBK = s.KBK,
			t.NameBank = s.NameBank,
			t.NameRegion = s.NameRegion,
			t.NumberExpenseAccount = s.NumberExpenseAccount,
			t.OKTMO = s.OKTMO,
			t.Phone = s.Phone,
			t.Recipient = s.Recipient,
			t.ZipCode = s.ZipCode,
			t.TaxBlockNumber = s.TaxBlockNumber,
			t.TaxName = s.TaxName,
			t.TaxNameLocality = s.TaxNameLocality,
			t.TaxNameRegion = s.TaxNameRegion,
			t.TaxNameStreet = s.TaxNameStreet,
			t.TaxNameTown = s.TaxNameTown,
			t.TaxStreetNumber = s.TaxStreetNumber,
			t.TaxZipCode = s.TaxZipCode,
			t.UploadDate = s.UploadDate,
			t.AddresseeInDativeCase = s.AddresseeInDativeCase,
			t.CorrespondentAccount = s.CorrespondentAccount,
			t.CourtType = s.CourtType,
			t.CourtWebsite = s.CourtWebsite,
			t.DigitApplicationAllowed = s.DigitApplicationAllowed,
			t.IfnsAddress = s.IfnsAddress,
			t.IfnsCode = s.IfnsCode,
			t.IfnsPhone = s.IfnsPhone,
			t.IfnsWebsite = s.IfnsWebsite,
			t.SblId = s.SblId,
			t.DepartmentFsspId = s.DepartmentFsspId,
			t.FullAddress = s.FullAddress,

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
