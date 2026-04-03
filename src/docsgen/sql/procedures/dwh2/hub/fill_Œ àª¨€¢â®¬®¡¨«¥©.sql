CREATE PROC hub.fill_МаркиАвтомобилей
as
begin
	--truncate table hub.МаркиАвтомобилей
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	drop table if exists #t_МаркиАвтомобилей
	if OBJECT_ID ('hub.МаркиАвтомобилей') is not null
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from hub.МаркиАвтомобилей), 0x0)
	end

	select distinct 
		GuidМаркаМашины				= cast([dbo].[getGUIDFrom1C_IDRREF](МаркиАвтомобилей.Ссылка) as uniqueidentifier),
		isDelete = cast(МаркиАвтомобилей.ПометкаУдаления as bit),
		--МаркиАвтомобилей.ИмяПредопределенныхДанных,
		--МаркиАвтомобилей.Код,
		МаркиАвтомобилей.Наименование,
		--МаркиАвтомобилей.ОбластьДанныхОсновныеДанные,
		--МаркиАвтомобилей.DWHInsertedDate,
		--МаркиАвтомобилей.ProcessGUID,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		[spFillName]						= @spName,
		ВерсияДанных = cast(МаркиАвтомобилей.ВерсияДанных AS binary(8))
	into #t_МаркиАвтомобилей
	from Stg._1cCRM.Справочник_МаркиАвтомобилей AS МаркиАвтомобилей
	where МаркиАвтомобилей.ВерсияДанных >= @rowVersion 

	if OBJECT_ID('hub.МаркиАвтомобилей') is null
	begin
	
		select top(0)
			GuidМаркаМашины,
			isDelete,
			--Код,
			Наименование,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		into hub.МаркиАвтомобилей
		from #t_МаркиАвтомобилей

		alter table hub.МаркиАвтомобилей
			alter column GuidМаркаМашины uniqueidentifier not null

		ALTER TABLE hub.МаркиАвтомобилей
			ADD CONSTRAINT PK_МаркиАвтомобилей PRIMARY KEY CLUSTERED (GuidМаркаМашины)
	end
	
	--begin tran
		merge hub.МаркиАвтомобилей t
		using #t_МаркиАвтомобилей s
			on t.GuidМаркаМашины = s.GuidМаркаМашины
		when not matched then insert
		(
			GuidМаркаМашины,
			isDelete,
			--Код,
			Наименование,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		) values
		(
			s.GuidМаркаМашины,
			s.isDelete,
			--s.Код,
			s.Наименование,
			s.created_at,
			s.updated_at,
			s.spFillName,
			s.ВерсияДанных
		)
		when matched and t.ВерсияДанных !=s.ВерсияДанных
		then update SET
			t.isDelete = s.isDelete,
			--t.Код = s.Код,
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
