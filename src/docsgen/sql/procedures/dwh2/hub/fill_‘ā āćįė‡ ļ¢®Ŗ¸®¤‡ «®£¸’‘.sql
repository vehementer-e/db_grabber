CREATE PROC hub.fill_СтатусыЗаявокПодЗалогПТС
as
begin
	--truncate table hub.СтатусыЗаявокПодЗалогПТС
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	drop table if exists #t_СтатусыЗаявокПодЗалогПТС
	if OBJECT_ID ('hub.СтатусыЗаявокПодЗалогПТС') is not null
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from hub.СтатусыЗаявокПодЗалогПТС), 0x0)
	end

	select distinct 
		GuidСтатусЗаявкиПодЗалогПТС				= cast([dbo].[getGUIDFrom1C_IDRREF](СтатусыЗаявокПодЗалогПТС.Ссылка) as uniqueidentifier),
		isDelete = cast(СтатусыЗаявокПодЗалогПТС.ПометкаУдаления as bit),
		--СтатусыЗаявокПодЗалогПТС.ИмяПредопределенныхДанных,
		Код = СтатусыЗаявокПодЗалогПТС.КодСтатуса,
		СтатусыЗаявокПодЗалогПТС.Наименование,
		--СтатусыЗаявокПодЗалогПТС.ОбластьДанныхОсновныеДанные,
		--СтатусыЗаявокПодЗалогПТС.DWHInsertedDate,
		--СтатусыЗаявокПодЗалогПТС.ProcessGUID,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		[spFillName]						= @spName,
		ВерсияДанных = cast(СтатусыЗаявокПодЗалогПТС.ВерсияДанных AS binary(8))
	into #t_СтатусыЗаявокПодЗалогПТС
	from Stg._1cCRM.Справочник_СтатусыЗаявокПодЗалогПТС AS СтатусыЗаявокПодЗалогПТС
	where СтатусыЗаявокПодЗалогПТС.ВерсияДанных >= @rowVersion 

	if OBJECT_ID('hub.СтатусыЗаявокПодЗалогПТС') is null
	begin
	
		select top(0)
			GuidСтатусЗаявкиПодЗалогПТС,
			isDelete,
			Код,
			Наименование,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		into hub.СтатусыЗаявокПодЗалогПТС
		from #t_СтатусыЗаявокПодЗалогПТС

		alter table hub.СтатусыЗаявокПодЗалогПТС
			alter column GuidСтатусЗаявкиПодЗалогПТС uniqueidentifier not null

		ALTER TABLE hub.СтатусыЗаявокПодЗалогПТС
			ADD CONSTRAINT PK_СтатусыЗаявокПодЗалогПТС PRIMARY KEY CLUSTERED (GuidСтатусЗаявкиПодЗалогПТС)
	end
	
	--begin tran
		merge hub.СтатусыЗаявокПодЗалогПТС t
		using #t_СтатусыЗаявокПодЗалогПТС s
			on t.GuidСтатусЗаявкиПодЗалогПТС = s.GuidСтатусЗаявкиПодЗалогПТС
		when not matched then insert
		(
			GuidСтатусЗаявкиПодЗалогПТС,
			isDelete,
			Код,
			Наименование,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		) values
		(
			s.GuidСтатусЗаявкиПодЗалогПТС,
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
