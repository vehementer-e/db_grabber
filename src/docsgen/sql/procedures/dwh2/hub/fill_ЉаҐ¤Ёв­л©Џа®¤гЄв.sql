-- hub -  fill_КредитныйПродукт
CREATE PROC hub.fill_КредитныйПродукт
as
begin
	--truncate table hub.КредитныйПродукт
begin try
	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	drop table if exists #t_КредитныйПродукт
	if OBJECT_ID ('hub.КредитныйПродукт') is not null
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) from hub.КредитныйПродукт), 0x0)
	end

	select distinct 
		GuidКредитныйПродукт				= cast([dbo].[getGUIDFrom1C_IDRREF](КредитныйПродукт.Ссылка) as uniqueidentifier),
		isDelete = cast(КредитныйПродукт.ПометкаУдаления as bit),
		--КредитныйПродукт.ИмяПредопределенныхДанных,
		КредитныйПродукт.Код,
		КредитныйПродукт.Наименование,
		КодДлительностиПродукта = cast(КредитныйПродукт.КодДлительностиПродукта AS int),
		КредитныйПродукт.Ставка,
		МинимальныйВозрастЗаемщика = cast(КредитныйПродукт.МинимальныйВозрастЗаемщика AS int),
		МаксимальныйВозрастЗаемщика = cast(КредитныйПродукт.МаксимальныйВозрастЗаемщика AS int),
		МинимальнаяСуммаЗайма = cast(КредитныйПродукт.МинимальнаяСуммаЗайма AS money),
		МаксимальнаяСуммаЗайма = cast(КредитныйПродукт.МаксимальнаяСуммаЗайма AS money),
		ДоступенДляВыбора = cast(КредитныйПродукт.ДоступенДляВыбора AS bit),
		Докредитование = cast(КредитныйПродукт.Докредитование AS bit),
		ШагРанжированияСуммы = cast(КредитныйПродукт.ШагРанжированияСуммы AS money),
		ПеременнаяСтавка = cast(КредитныйПродукт.ПеременнаяСтавка as bit),
		КредитныйПродукт.НаборВариантовЛимитовСуммJSON,
		МинимальнаяСуммаЗаймаДокред = cast(КредитныйПродукт.МинимальнаяСуммаЗаймаДокред AS money),
		--КредитныйПродукт.ОбластьДанныхОсновныеДанные,
		--КредитныйПродукт.DWHInsertedDate,
		--КредитныйПродукт.ProcessGUID,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		[spFillName]						= @spName,
		КредитныйПродукт.ВерсияДанных
	into #t_КредитныйПродукт
	from Stg._1cCRM.Справочник_КредитныеПродукты AS КредитныйПродукт
	where КредитныйПродукт.ВерсияДанных >= @rowVersion 

	if OBJECT_ID('hub.КредитныйПродукт') is null
	begin
	
		select top(0)
			GuidКредитныйПродукт,
			isDelete,
			Код,
			Наименование,
			КодДлительностиПродукта,
			Ставка,
			МинимальныйВозрастЗаемщика,
			МаксимальныйВозрастЗаемщика,
			МинимальнаяСуммаЗайма,
			МаксимальнаяСуммаЗайма,
			ДоступенДляВыбора,
			Докредитование,
			ШагРанжированияСуммы,
			ПеременнаяСтавка,
			НаборВариантовЛимитовСуммJSON,
			МинимальнаяСуммаЗаймаДокред,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		into hub.КредитныйПродукт
		from #t_КредитныйПродукт

		alter table hub.КредитныйПродукт
			alter column GuidКредитныйПродукт uniqueidentifier not null

		ALTER TABLE hub.КредитныйПродукт
			ADD CONSTRAINT PK_КредитныйПродукт PRIMARY KEY CLUSTERED (GuidКредитныйПродукт)
	end
	
	--begin tran
		merge hub.КредитныйПродукт t
		using #t_КредитныйПродукт s
			on t.GuidКредитныйПродукт = s.GuidКредитныйПродукт
		when not matched then insert
		(
			GuidКредитныйПродукт,
			isDelete,
			Код,
			Наименование,
			КодДлительностиПродукта,
			Ставка,
			МинимальныйВозрастЗаемщика,
			МаксимальныйВозрастЗаемщика,
			МинимальнаяСуммаЗайма,
			МаксимальнаяСуммаЗайма,
			ДоступенДляВыбора,
			Докредитование,
			ШагРанжированияСуммы,
			ПеременнаяСтавка,
			НаборВариантовЛимитовСуммJSON,
			МинимальнаяСуммаЗаймаДокред,
			created_at,
			updated_at,
			spFillName,
			ВерсияДанных
		) values
		(
			s.GuidКредитныйПродукт,
			s.isDelete,
			s.Код,
			s.Наименование,
			s.КодДлительностиПродукта,
			s.Ставка,
			s.МинимальныйВозрастЗаемщика,
			s.МаксимальныйВозрастЗаемщика,
			s.МинимальнаяСуммаЗайма,
			s.МаксимальнаяСуммаЗайма,
			s.ДоступенДляВыбора,
			s.Докредитование,
			s.ШагРанжированияСуммы,
			s.ПеременнаяСтавка,
			s.НаборВариантовЛимитовСуммJSON,
			s.МинимальнаяСуммаЗаймаДокред,
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
			t.КодДлительностиПродукта = s.КодДлительностиПродукта,
			t.Ставка = s.Ставка,
			t.МинимальныйВозрастЗаемщика = s.МинимальныйВозрастЗаемщика,
			t.МаксимальныйВозрастЗаемщика = s.МаксимальныйВозрастЗаемщика,
			t.МинимальнаяСуммаЗайма = s.МинимальнаяСуммаЗайма,
			t.МаксимальнаяСуммаЗайма = s.МаксимальнаяСуммаЗайма,
			t.ДоступенДляВыбора = s.ДоступенДляВыбора,
			t.Докредитование = s.Докредитование,
			t.ШагРанжированияСуммы = s.ШагРанжированияСуммы,
			t.ПеременнаяСтавка = s.ПеременнаяСтавка,
			t.НаборВариантовЛимитовСуммJSON = s.НаборВариантовЛимитовСуммJSON,
			t.МинимальнаяСуммаЗаймаДокред = s.МинимальнаяСуммаЗаймаДокред,
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
