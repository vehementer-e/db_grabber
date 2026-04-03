CREATE PROC hub.fill_Пользователи
as
begin
	--truncate table hub.Пользователи
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	drop table if exists #t_Пользователи
	if OBJECT_ID ('hub.Пользователи') is not null
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from hub.Пользователи), 0x0)
	end

	select distinct 
		GuidПользователь				= cast([dbo].[getGUIDFrom1C_IDRREF](Пользователи.Ссылка) as uniqueidentifier),
		isDelete = cast(Пользователи.ПометкаУдаления as bit),
		--Пользователи.ИмяПредопределенныхДанных,
		--Код
		Недействителен = cast(Пользователи.Недействителен as bit),
		Пользователи.Наименование,
		--Пользователи.ОбластьДанныхОсновныеДанные,
		--Пользователи.DWHInsertedDate,
		--Пользователи.ProcessGUID,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		[spFillName]						= @spName,
		ВерсияДанных = cast(Пользователи.ВерсияДанных AS binary(8))
	into #t_Пользователи
	from Stg._1cCRM.Справочник_Пользователи AS Пользователи
	where Пользователи.ВерсияДанных >= @rowVersion 

	if OBJECT_ID('hub.Пользователи') is null
	begin
	
		select top(0)
			GuidПользователь,
			isDelete,
			Недействителен,
			Наименование,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		into hub.Пользователи
		from #t_Пользователи

		alter table hub.Пользователи
			alter column GuidПользователь uniqueidentifier not null

		ALTER TABLE hub.Пользователи
			ADD CONSTRAINT PK_Пользователи PRIMARY KEY CLUSTERED (GuidПользователь)
	end
	
	--begin tran
		merge hub.Пользователи t
		using #t_Пользователи s
			on t.GuidПользователь = s.GuidПользователь
		when not matched then insert
		(
			GuidПользователь,
			isDelete,
			Недействителен,
			Наименование,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		) values
		(
			s.GuidПользователь,
			s.isDelete,
			s.Недействителен,
			s.Наименование,
			s.created_at,
			s.updated_at,
			s.spFillName,
			s.ВерсияДанных
		)
		when matched and t.ВерсияДанных !=s.ВерсияДанных
		then update SET
			t.isDelete = s.isDelete,
			t.Недействителен = s.Недействителен,
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
