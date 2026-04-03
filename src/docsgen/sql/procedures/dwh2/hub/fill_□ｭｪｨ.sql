/*
exec hub.fill_Банки
*/
create   PROC hub.fill_Банки
	@mode int = 1,
	@isDebug int = 0
as
begin
	--truncate table hub.Банки
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	if OBJECT_ID ('hub.Банки') is not null
		AND @mode = 1
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) - 100 from hub.Банки), 0x0)
	end

	drop table if exists #t_Банки

	select distinct 
		GuidБанки = cast(dbo.getGUIDFrom1C_IDRREF(v.Ссылка) as uniqueidentifier),
		СсылкаБанки = v.Ссылка,
		isDelete = cast(v.ПометкаУдаления as bit),
		--
		Родитель,
		ЭтоГруппа,
		Код,
		Наименование,
		КоррСчет,
		Город,
		Адрес,
		Телефоны,
		РучноеИзменение,
		СВИФТБИК,
		Страна,
		--
		ВерсияДанных = cast(v.ВерсияДанных AS binary(8)),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_Банки
	--SELECT *,v.ВерсияДанных
	from Stg._1cUMFO.Справочник_Банки AS v
	where 1=1
		and v.Страна in (0x9B7650E549564EF611E72051DD6F9D26)
		and v.ВерсияДанных > @rowVersion

	if @isDebug = 1
	begin
		drop table if exists ##t_Банки
		SELECT * INTO ##t_Банки FROM #t_Банки
	end

	if OBJECT_ID('hub.Банки') is null
	begin
	
		select top(0)
			GuidБанки,
			СсылкаБанки,
			isDelete,
			Родитель,
			ЭтоГруппа,
			Код,
			Наименование,
			КоррСчет,
			Город,
			Адрес,
			Телефоны,
			РучноеИзменение,
			СВИФТБИК,
			Страна,
			ВерсияДанных,
			created_at,
			updated_at,
			spFillName
		into hub.Банки
		from #t_Банки

		alter table hub.Банки
			alter column GuidБанки uniqueidentifier not null

		ALTER TABLE hub.Банки
			ADD CONSTRAINT PK_Банки PRIMARY KEY CLUSTERED (GuidБанки)

		create index ix_СсылкаБанки
		on hub.Банки(СсылкаБанки)
	end
	
	begin tran
		if @mode = 0 begin
			delete v from hub.Банки as v
		end

		merge hub.Банки t
		using #t_Банки s
			on t.GuidБанки = s.GuidБанки
		when not matched then insert
		(
			GuidБанки,
			СсылкаБанки,
			isDelete,
			Родитель,
			ЭтоГруппа,
			Код,
			Наименование,
			КоррСчет,
			Город,
			Адрес,
			Телефоны,
			РучноеИзменение,
			СВИФТБИК,
			Страна,
			ВерсияДанных,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidБанки,
			s.СсылкаБанки,
			s.isDelete,
			s.Родитель,
			s.ЭтоГруппа,
			s.Код,
			s.Наименование,
			s.КоррСчет,
			s.Город,
			s.Адрес,
			s.Телефоны,
			s.РучноеИзменение,
			s.СВИФТБИК,
			s.Страна,
			s.ВерсияДанных,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched and t.ВерсияДанных !=s.ВерсияДанных
			OR @mode = 0
		then update SET
			t.СсылкаБанки = s.СсылкаБанки,
			t.isDelete = s.isDelete,
			t.Родитель = s.Родитель,
			t.ЭтоГруппа = s.ЭтоГруппа,
			t.Код = s.Код,
			t.Наименование = s.Наименование,
			t.КоррСчет = s.КоррСчет,
			t.Город = s.Город,
			t.Адрес = s.Адрес,
			t.Телефоны = s.Телефоны,
			t.РучноеИзменение = s.РучноеИзменение,
			t.СВИФТБИК = s.СВИФТБИК,
			t.Страна = s.Страна,
			t.ВерсияДанных = s.ВерсияДанных,
			t.updated_at = s.updated_at
			;
	commit tran
	

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
