CREATE PROC hub.fill_ПодТипКредитногоПродукта
	@mode int = 1
as
begin
	--truncate table hub.ПодТипКредитногоПродукта
begin TRY
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_ПодТипКредитногоПродукта

	if OBJECT_ID ('hub.ПодТипКредитногоПродукта') is not NULL
		AND @mode = 1
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from hub.ПодТипКредитногоПродукта), 0x0)
	end

	select distinct 
		GuidПодТипКредитногоПродукта = cast([dbo].[getGUIDFrom1C_IDRREF](ПодТипКредитногоПродукта.Ссылка) as uniqueidentifier),
		ВерсияДанных = cast(ПодТипКредитногоПродукта.ВерсияДанных AS binary(8)),
		isDelete = cast(ПодТипКредитногоПродукта.ПометкаУдаления as bit),
		ПодТипКредитногоПродукта.Код,
		ПодТипКредитногоПродукта.Наименование,
		isActive = cast(ПодТипКредитногоПродукта.Активный as bit),
		--
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		[spFillName]						= @spName
	into #t_ПодТипКредитногоПродукта
	from Stg._1cCRM.Справочник_тмПодТипыКредитногоПродукта AS ПодТипКредитногоПродукта
	where ПодТипКредитногоПродукта.ВерсияДанных >= @rowVersion

	if OBJECT_ID('hub.ПодТипКредитногоПродукта') is null
	begin
		select top(0)
			GuidПодТипКредитногоПродукта,
			ВерсияДанных,
			isDelete,
			Код,
			Наименование,
			isActive,
			created_at,
			updated_at,
			spFillName
		into hub.ПодТипКредитногоПродукта
		from #t_ПодТипКредитногоПродукта

		alter table hub.ПодТипКредитногоПродукта
			alter column GuidПодТипКредитногоПродукта uniqueidentifier not null

		ALTER TABLE hub.ПодТипКредитногоПродукта
			ADD CONSTRAINT PK_ПодТипКредитногоПродукта PRIMARY KEY CLUSTERED (GuidПодТипКредитногоПродукта)
	end
	
	--begin tran
		merge hub.ПодТипКредитногоПродукта t
		using #t_ПодТипКредитногоПродукта s
			on t.GuidПодТипКредитногоПродукта = s.GuidПодТипКредитногоПродукта
		when not matched then insert
		(
			GuidПодТипКредитногоПродукта,
			ВерсияДанных,
			isDelete,
			Код,
			Наименование,
			isActive,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidПодТипКредитногоПродукта,
			s.ВерсияДанных,
			s.isDelete,
			s.Код,
			s.Наименование,
			s.isActive,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched and t.ВерсияДанных !=s.ВерсияДанных
			OR @mode = 0
		then update SET
			t.ВерсияДанных = s.ВерсияДанных,
			t.isDelete = s.isDelete,
			t.Код = s.Код,
			t.Наименование = s.Наименование,
			t.isActive = s.isActive,
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
