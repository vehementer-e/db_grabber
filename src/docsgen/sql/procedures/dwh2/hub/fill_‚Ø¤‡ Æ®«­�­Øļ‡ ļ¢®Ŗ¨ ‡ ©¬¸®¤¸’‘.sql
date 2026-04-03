CREATE PROC hub.fill_ВидЗаполненияЗаявокНаЗаймПодПТС
as
begin
	--truncate table hub.ВидЗаполненияЗаявокНаЗаймПодПТС
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	drop table if exists #t_ВидЗаполненияЗаявокНаЗаймПодПТС
	if OBJECT_ID ('hub.ВидЗаполненияЗаявокНаЗаймПодПТС') is not null
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from hub.ВидЗаполненияЗаявокНаЗаймПодПТС), 0x0)
	end

	select distinct 
		GuidВидЗаполненияЗаявокНаЗаймПодПТС				= cast([dbo].[getGUIDFrom1C_IDRREF](ВидЗаполненияЗаявокНаЗаймПодПТС.Ссылка) as uniqueidentifier),
		isDelete = cast(ВидЗаполненияЗаявокНаЗаймПодПТС.ПометкаУдаления as bit),
		--ВидЗаполненияЗаявокНаЗаймПодПТС.ИмяПредопределенныхДанных,
		ВидЗаполненияЗаявокНаЗаймПодПТС.Код,
		ВидЗаполненияЗаявокНаЗаймПодПТС.Наименование,
		--ВидЗаполненияЗаявокНаЗаймПодПТС.ОбластьДанныхОсновныеДанные,
		--ВидЗаполненияЗаявокНаЗаймПодПТС.DWHInsertedDate,
		--ВидЗаполненияЗаявокНаЗаймПодПТС.ProcessGUID,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		[spFillName]						= @spName,
		ВерсияДанных = cast(ВидЗаполненияЗаявокНаЗаймПодПТС.ВерсияДанных AS binary(8))
	into #t_ВидЗаполненияЗаявокНаЗаймПодПТС
	from Stg._1cCRM.Справочник_ВидыЗаполненияЗаявокНаЗаймПодПТС AS ВидЗаполненияЗаявокНаЗаймПодПТС
	where ВидЗаполненияЗаявокНаЗаймПодПТС.ВерсияДанных >= @rowVersion 

	if OBJECT_ID('hub.ВидЗаполненияЗаявокНаЗаймПодПТС') is null
	begin
	
		select top(0)
			GuidВидЗаполненияЗаявокНаЗаймПодПТС,
			isDelete,
			Код,
			Наименование,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		into hub.ВидЗаполненияЗаявокНаЗаймПодПТС
		from #t_ВидЗаполненияЗаявокНаЗаймПодПТС

		alter table hub.ВидЗаполненияЗаявокНаЗаймПодПТС
			alter column GuidВидЗаполненияЗаявокНаЗаймПодПТС uniqueidentifier not null

		ALTER TABLE hub.ВидЗаполненияЗаявокНаЗаймПодПТС
			ADD CONSTRAINT PK_ВидЗаполненияЗаявокНаЗаймПодПТС PRIMARY KEY CLUSTERED (GuidВидЗаполненияЗаявокНаЗаймПодПТС)
	end
	
	--begin tran
		merge hub.ВидЗаполненияЗаявокНаЗаймПодПТС t
		using #t_ВидЗаполненияЗаявокНаЗаймПодПТС s
			on t.GuidВидЗаполненияЗаявокНаЗаймПодПТС = s.GuidВидЗаполненияЗаявокНаЗаймПодПТС
		when not matched then insert
		(
			GuidВидЗаполненияЗаявокНаЗаймПодПТС,
			isDelete,
			Код,
			Наименование,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		) values
		(
			s.GuidВидЗаполненияЗаявокНаЗаймПодПТС,
			s.isDelete,
			s.Код,
			s.Наименование,
			s.created_at,
			s.updated_at,
			s.spFillName,
			s.ВерсияДанных
		)
		when matched and t.ВерсияДанных !=s.ВерсияДанных
		then update SET
			t.isDelete = s.isDelete,
			t.Код = s.Код,
			t.Наименование = s.Наименование,
			t.updated_at = s.updated_at,
			t.ВерсияДанных = s.ВерсияДанных
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
