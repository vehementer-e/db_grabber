create   PROC sat.fill_Клиент_Collection_customers
	@mode int = 1,
	@Id int = null,
	@GuidКлиент uniqueidentifier = null,
	@isDebug int = 0
as
begin
	--truncate table sat.Клиент_Collection_customers
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_Клиент_Collection_customers

	if OBJECT_ID ('sat.Клиент_Collection_customers') is not null
		and @mode = 1
		and @Id is null
		and @GuidКлиент is null
	begin
		set @rowVersion = isnull((select max(s.RowVersion) from sat.Клиент_Collection_customers as s), 0x0)
	end

	select distinct
		GuidКлиент = try_cast(C.CrmCustomerId AS uniqueidentifier),
		СсылкаКлиент = dbo.get1CIDRREF_FromGUID(try_cast(C.CrmCustomerId AS uniqueidentifier)),
		C.Id,
		LastName= nullif(trim(C.LastName),''),
		Name = nullif(trim(C.Name),''),
		MiddleName = nullif(CASE WHEN trim(C.MiddleName) IN ('-') THEN '' ELSE trim(C.MiddleName) END,''),
		FullName = concat(
			trim(C.LastName), ' ', 
			trim(C.Name), ' ', 
			CASE WHEN trim(C.MiddleName) IN ('-') THEN '' ELSE trim(C.MiddleName) END
		),
		C.RowVersion,
		--
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName,
		Link_GuidCollection_Claimant = try_cast(hashbytes('SHA2_256', cast(C.ClaimantId as varchar(30))) AS uniqueidentifier),
		Link_GuidCollection_ClaimantLegal = try_cast(hashbytes('SHA2_256', cast(C.ClaimantLegalId as varchar(30))) AS uniqueidentifier)
	into #t_Клиент_Collection_customers
	--SELECT top 10 C.CrmCustomerId, *
	FROM Stg._Collection.customers AS C
		inner join hub.Клиенты as h
			on h.GuidКлиент = C.CrmCustomerId
	where 1=1
		and try_cast(C.CrmCustomerId AS uniqueidentifier) is not null
		and C.RowVersion >= @rowVersion
		and (C.Id = @Id or @Id is null)
		and (C.CrmCustomerId = @GuidКлиент or @GuidКлиент is null)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Клиент_Collection_customers
		SELECT * INTO ##t_Клиент_Collection_customers FROM #t_Клиент_Collection_customers
		--RETURN 0
	END


	if OBJECT_ID('sat.Клиент_Collection_customers') is null
	begin
		select top(0)
			GuidКлиент,
            СсылкаКлиент,

			Id,
			LastName,
			Name,
			MiddleName,
			FullName,
			RowVersion,

            created_at,
            updated_at,
            spFillName
		into sat.Клиент_Collection_customers
		from #t_Клиент_Collection_customers

		alter table sat.Клиент_Collection_customers
			alter column GuidКлиент uniqueidentifier not null

		ALTER TABLE sat.Клиент_Collection_customers
			ADD CONSTRAINT PK_Клиент_Collection_customers PRIMARY KEY CLUSTERED (GuidКлиент)
	end

	--begin tran
	merge sat.Клиент_Collection_customers t
	using #t_Клиент_Collection_customers s
		on t.GuidКлиент = s.GuidКлиент
	when not matched then insert
	(
		GuidКлиент,
        СсылкаКлиент,

		Id,
		LastName,
		Name,
		MiddleName,
		FullName,
		RowVersion,

        created_at,
        updated_at,
        spFillName
	) values
	(
		s.GuidКлиент,
        s.СсылкаКлиент,

		s.Id,
		s.LastName,
		s.Name,
		s.MiddleName,
		s.FullName,
		s.RowVersion,

        s.created_at,
        s.updated_at,
        s.spFillName
	)
	when matched and t.RowVersion != s.RowVersion
	then update SET
		t.Id = s.Id,
		t.LastName = s.LastName,
		t.Name = s.Name,
		t.MiddleName = s.MiddleName,
		t.FullName = s.FullName,
		t.RowVersion = s.RowVersion,

		t.updated_at = s.updated_at,
		t.spFillName = s.spFillName
		;
	--commit tran

	INSERT link.Клиент_stage
	(
		GuidКлиент,
		date_from,
		LinkName,
		LinkGuid,
		TargetColName
	)
	SELECT 
		R.GuidКлиент,
		date_from = '2000-01-01',
		LinkName,
		LinkGuid,
		TargetColName
	FROM #t_Клиент_Collection_customers AS R
		CROSS APPLY (
		VALUES 
			(Link_GuidCollection_Claimant, 'link.Клиент_Collection_Claimant', 'GuidCollection_Claimant'),
			(Link_GuidCollection_ClaimantLegal, 'link.Клиент_Collection_ClaimantLegal', 'GuidCollection_ClaimantLegal')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null

	EXEC link.fill_link_between_Клиент_and_other
		@LinkName='link.Клиент_Collection_Claimant'

	EXEC link.fill_link_between_Клиент_and_other
		@LinkName='link.Клиент_Collection_ClaimantLegal'

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
