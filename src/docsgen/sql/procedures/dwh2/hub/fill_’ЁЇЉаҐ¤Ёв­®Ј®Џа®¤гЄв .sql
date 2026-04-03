CREATE   PROC [hub].[fill_ТипКредитногоПродукта]
	@mode int = 1
as
begin
	--truncate table hub.ТипКредитногоПродукта
begin TRY
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_ТипКредитногоПродукта

	if OBJECT_ID ('hub.ТипКредитногоПродукта') is not NULL
		AND @mode = 1
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from hub.ТипКредитногоПродукта), 0x0)
	end

	select distinct 
		GuidТипКредитногоПродукта = cast([dbo].[getGUIDFrom1C_IDRREF](ТипКредитногоПродукта.Ссылка) as uniqueidentifier),
		ВерсияДанных = cast(ТипКредитногоПродукта.ВерсияДанных AS binary(8)),
		isDelete = cast(ТипКредитногоПродукта.ПометкаУдаления as bit),
		ТипКредитногоПродукта.Код,
		ТипКредитногоПродукта.Наименование,
		ОставлятьПТСУКлиента = cast(ТипКредитногоПродукта.ОставлятьПТСУКлиента as bit),
		МинимальнаяСумма = cast(ТипКредитногоПродукта.МинимальнаяСумма AS money),
		МаксимальнаяСумма = cast(ТипКредитногоПродукта.МаксимальнаяСумма AS money),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		[spFillName]						= @spName
	into #t_ТипКредитногоПродукта
	from Stg._1cCRM.Справочник_тмТипыКредитногоПродукта AS ТипКредитногоПродукта
	where ТипКредитногоПродукта.ВерсияДанных >= @rowVersion

	if OBJECT_ID('hub.ТипКредитногоПродукта') is null
	begin
		select top(0)
			GuidТипКредитногоПродукта,
			ВерсияДанных,
			isDelete,
			Код,
			Наименование,
			ОставлятьПТСУКлиента,
			МинимальнаяСумма,
			МаксимальнаяСумма,
			created_at,
			updated_at,
			spFillName
		into hub.ТипКредитногоПродукта
		from #t_ТипКредитногоПродукта

		alter table hub.ТипКредитногоПродукта
			alter column GuidТипКредитногоПродукта uniqueidentifier not null
		
		ALTER TABLE hub.ТипКредитногоПродукта
			ADD CONSTRAINT PK_ТипКредитногоПродукта PRIMARY KEY CLUSTERED (GuidТипКредитногоПродукта)
	end
	
	--begin tran
		merge hub.ТипКредитногоПродукта t
		using #t_ТипКредитногоПродукта s
			on t.GuidТипКредитногоПродукта = s.GuidТипКредитногоПродукта
		when not matched then insert
		(
			GuidТипКредитногоПродукта,
			ВерсияДанных,
			isDelete,
			Код,
			Наименование,
			ОставлятьПТСУКлиента,
			МинимальнаяСумма,
			МаксимальнаяСумма,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidТипКредитногоПродукта,
			s.ВерсияДанных,
			s.isDelete,
			s.Код,
			s.Наименование,
			s.ОставлятьПТСУКлиента,
			s.МинимальнаяСумма,
			s.МаксимальнаяСумма,
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
			t.ОставлятьПТСУКлиента = s.ОставлятьПТСУКлиента,
			t.МинимальнаяСумма = s.МинимальнаяСумма,
			t.МаксимальнаяСумма = s.МаксимальнаяСумма,
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
