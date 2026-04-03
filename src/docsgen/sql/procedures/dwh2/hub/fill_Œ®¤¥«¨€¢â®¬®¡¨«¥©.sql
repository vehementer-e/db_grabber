CREATE PROC hub.fill_МоделиАвтомобилей
as
begin
	--truncate table hub.МоделиАвтомобилей
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	drop table if exists #t_МоделиАвтомобилей
	if OBJECT_ID ('hub.МоделиАвтомобилей') is not null
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from hub.МоделиАвтомобилей), 0x0)
	end

	select distinct 
		GuidМодельАвтомобиля				= cast([dbo].[getGUIDFrom1C_IDRREF](МоделиАвтомобилей.Ссылка) as uniqueidentifier),
		isDelete = cast(МоделиАвтомобилей.ПометкаУдаления as bit),
		--МоделиАвтомобилей.ИмяПредопределенныхДанных,
		--МоделиАвтомобилей.Код,
		МоделиАвтомобилей.Наименование,
		--МоделиАвтомобилей.ОбластьДанныхОсновныеДанные,
		--МоделиАвтомобилей.DWHInsertedDate,
		--МоделиАвтомобилей.ProcessGUID,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		[spFillName]						= @spName,
		ВерсияДанных = cast(МоделиАвтомобилей.ВерсияДанных AS binary(8))
	into #t_МоделиАвтомобилей
	from Stg._1cCRM.Справочник_МоделиАвтомобилей AS МоделиАвтомобилей
	where МоделиАвтомобилей.ВерсияДанных >= @rowVersion 

	if OBJECT_ID('hub.МоделиАвтомобилей') is null
	begin
	
		select top(0)
			GuidМодельАвтомобиля,
			isDelete,
			--Код,
			Наименование,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		into hub.МоделиАвтомобилей
		from #t_МоделиАвтомобилей

		alter table hub.МоделиАвтомобилей
			alter column GuidМодельАвтомобиля uniqueidentifier not null

		ALTER TABLE hub.МоделиАвтомобилей
			ADD CONSTRAINT PK_МоделиАвтомобилей PRIMARY KEY CLUSTERED (GuidМодельАвтомобиля)
	end
	
	--begin tran
		merge hub.МоделиАвтомобилей t
		using #t_МоделиАвтомобилей s
			on t.GuidМодельАвтомобиля = s.GuidМодельАвтомобиля
		when not matched then insert
		(
			GuidМодельАвтомобиля,
			isDelete,
			--Код,
			Наименование,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		) values
		(
			s.GuidМодельАвтомобиля,
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
