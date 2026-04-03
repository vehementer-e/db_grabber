--exec sat.fill_Клиент_Collection_CustomerStatus
create   PROC sat.fill_Клиент_Collection_CustomerStatus
	@mode int = 1,
	@Id int = null,
	@CustomerId int = null,
	@GuidКлиент uniqueidentifier = null,
	@isDebug int = 0
as
begin
	--truncate table sat.Клиент_Collection_CustomerStatus
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_Клиент_Collection_CustomerStatus

	if OBJECT_ID ('sat.Клиент_Collection_CustomerStatus') is not null
		and @mode = 1
		and @Id is null
		and @CustomerId is null
		and @GuidКлиент is null
	begin
		set @rowVersion = isnull((select max(s.RowVersion) from sat.Клиент_Collection_CustomerStatus as s), 0x0)
	end

	select 
		t.GuidКлиент,
		t.СсылкаКлиент,

		t.UpdatedBy,
		t.CreatedBy,
		t.CreateDate,
		t.UpdateDate,

		t.CustomerId,
		t.IsActive,

		t.Date,
		t.ActivationDate,
		t.ActivatedBy,

		t.CustomerStateId,
		t.CustomerStateName,
		t.CustomerStateOrder,

		t.RowVersion,

		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_Клиент_Collection_CustomerStatus
	from (
		select distinct
			h.GuidКлиент,
			h.СсылкаКлиент,

			s.UpdatedBy,
			s.CreatedBy,
			s.CreateDate,
			s.UpdateDate,

			s.CustomerId,
			s.IsActive, --Статус активен

			s.Date,
			s.ActivationDate, --Дата активации статуса.
			s.ActivatedBy, --Идентификатор сотрудника, активировавшего статус

			s.CustomerStateId, --Идентификатор на справочник статусов клиента
			CustomerStateName = cs.Name,
			CustomerStateOrder = cs.[Order],

			s.RowVersion,
			rn = row_number() over(
				partition by h.GuidКлиент, s.CustomerStateId
				--order by s.ActivationDate
				order by s.RowVersion desc, s.ActivationDate
			)
		FROM Stg._Collection.CustomerStatus AS s
			inner join Stg._Collection.customers AS c
				on c.Id = s.CustomerId
			inner join Stg._Collection.CustomerState as cs
				on cs.Id = s.CustomerStateId
			inner join hub.Клиенты as h
				on h.GuidКлиент = c.CrmCustomerId
		where 1=1
			and try_cast(c.CrmCustomerId AS uniqueidentifier) is not null
			--and s.RowVersion is not null
			and s.RowVersion >= @rowVersion --or (s.rowVersion is null and @mode = 0)
			and (s.Id = @Id or @Id is null)
			and (s.CustomerId = @CustomerId or @CustomerId is null)
			and (c.CrmCustomerId = @GuidКлиент or @GuidКлиент is null)
		) as t
		where t.rn = 1

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Клиент_Collection_CustomerStatus
		SELECT * INTO ##t_Клиент_Collection_CustomerStatus FROM #t_Клиент_Collection_CustomerStatus
		--RETURN 0
	END


	if OBJECT_ID('sat.Клиент_Collection_CustomerStatus') is null
	begin
		select top(0)
			GuidКлиент,
            СсылкаКлиент,

			UpdatedBy,
			CreatedBy,
			CreateDate,
			UpdateDate,

			CustomerId,
			IsActive,

			Date,
			ActivationDate,
			ActivatedBy,

			CustomerStateId,
			CustomerStateName,
			CustomerStateOrder,

			RowVersion,

            created_at,
            updated_at,
            spFillName
		into sat.Клиент_Collection_CustomerStatus
		from #t_Клиент_Collection_CustomerStatus

		alter table sat.Клиент_Collection_CustomerStatus
			alter column GuidКлиент uniqueidentifier not null

		alter table sat.Клиент_Collection_CustomerStatus
			alter column CustomerStateId int not null

		ALTER TABLE sat.Клиент_Collection_CustomerStatus
			ADD CONSTRAINT PK_Клиент_Collection_CustomerStatus 
			PRIMARY KEY CLUSTERED (GuidКлиент, CustomerStateId)
	end

	--begin tran
	merge sat.Клиент_Collection_CustomerStatus t
	using #t_Клиент_Collection_CustomerStatus s
		on t.GuidКлиент = s.GuidКлиент
		and t.CustomerStateId = s.CustomerStateId
	when not matched then insert
	(
		GuidКлиент,
        СсылкаКлиент,

		UpdatedBy,
		CreatedBy,
		CreateDate,
		UpdateDate,

		CustomerId,
		IsActive,

		Date,
		ActivationDate,
		ActivatedBy,

		CustomerStateId,
		CustomerStateName,
		CustomerStateOrder,

		RowVersion,

        created_at,
        updated_at,
        spFillName
	) values
	(
		s.GuidКлиент,
        s.СсылкаКлиент,

		s.UpdatedBy,
		s.CreatedBy,
		s.CreateDate,
		s.UpdateDate,

		s.CustomerId,
		s.IsActive,

		s.Date,
		s.ActivationDate,
		s.ActivatedBy,

		s.CustomerStateId,
		s.CustomerStateName,
		s.CustomerStateOrder,

		s.RowVersion,

        s.created_at,
        s.updated_at,
        s.spFillName
	)
	when matched and 
		(t.RowVersion <> s.RowVersion
		or @mode = 0)
	then update SET
		t.UpdatedBy = s.UpdatedBy,
		t.CreatedBy = s.CreatedBy,
		t.CreateDate = s.CreateDate,
		t.UpdateDate = s.UpdateDate,

		t.CustomerId = s.CustomerId,
		t.IsActive = s.IsActive,

		t.Date = s.Date,
		t.ActivationDate = s.ActivationDate,
		t.ActivatedBy = s.ActivatedBy,

		t.CustomerStateId = s.CustomerStateId,
		t.CustomerStateName = s.CustomerStateName,
		t.CustomerStateOrder = s.CustomerStateOrder,

		t.RowVersion = s.RowVersion,

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
