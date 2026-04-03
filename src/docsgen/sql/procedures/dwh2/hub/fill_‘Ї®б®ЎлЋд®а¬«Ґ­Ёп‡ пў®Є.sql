CREATE PROC hub.fill_СпособыОформленияЗаявок
as
begin
	--truncate table hub.СпособыОформленияЗаявок
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	drop table if exists #t_СпособыОформленияЗаявок
	--if OBJECT_ID ('hub.СпособыОформленияЗаявок') is not null
	--begin
	--	set @rowVersion = isnull((select max(ВерсияДанных) from hub.СпособыОформленияЗаявок), 0x0)
	--end

	select distinct 
		GuidСпособОформления				= cast([dbo].[getGUIDFrom1C_IDRREF](СпособыОформленияЗаявок.Ссылка) as uniqueidentifier),
		--isDelete = cast(СпособыОформленияЗаявок.ПометкаУдаления as bit),
		--СпособыОформленияЗаявок.ИмяПредопределенныхДанных,
		Код = СпособыОформленияЗаявок.Имя,
		Наименование = СпособыОформленияЗаявок.Представление,
		--СпособыОформленияЗаявок.ОбластьДанныхОсновныеДанные,
		--СпособыОформленияЗаявок.DWHInsertedDate,
		--СпособыОформленияЗаявок.ProcessGUID,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		[spFillName]						= @spName
		--ВерсияДанных = cast(СпособыОформленияЗаявок.ВерсияДанных AS binary(8))
	into #t_СпособыОформленияЗаявок
	--SELECT *
	from Stg._1cCRM.Перечисление_СпособыОформленияЗаявок AS СпособыОформленияЗаявок
	--where СпособыОформленияЗаявок.ВерсияДанных >= @rowVersion 

	if OBJECT_ID('hub.СпособыОформленияЗаявок') is null
	begin
	
		select top(0)
			GuidСпособОформления,
			Код,
			Наименование,
			created_at,
			updated_at,
			spFillName
			--ВерсияДанных
		into hub.СпособыОформленияЗаявок
		from #t_СпособыОформленияЗаявок

		alter table hub.СпособыОформленияЗаявок
			alter column GuidСпособОформления uniqueidentifier not null

		ALTER TABLE hub.СпособыОформленияЗаявок
			ADD CONSTRAINT PK_СпособыОформленияЗаявок PRIMARY KEY CLUSTERED (GuidСпособОформления)
	end
	
	--begin tran
		merge hub.СпособыОформленияЗаявок t
		using #t_СпособыОформленияЗаявок s
			on t.GuidСпособОформления = s.GuidСпособОформления
		when not matched then insert
		(
			GuidСпособОформления,
			Код,
			Наименование,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidСпособОформления,
			s.Код,
			s.Наименование,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched 
			AND (t.Код <> s.Код OR t.Наименование <> s.Наименование)
		then update SET
			t.Код = s.Код,
			t.Наименование = s.Наименование,
			t.updated_at = s.updated_at
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
