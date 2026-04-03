/*
exec sat.fill_ВыдачаДенежныхСредств_Платежи
*/
CREATE   PROC [sat].[fill_ВыдачаДенежныхСредств_Платежи]
	@mode int = 1,
	@СсылкаДоговораЗайма binary(16) = null,
	@GuidДоговораЗайма uniqueidentifier = null,
	@КодДоговораЗайма nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table sat.ВыдачаДенежныхСредств_Платежи
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	declare @ДатаПлатежа date = '2000-01-01'

	if OBJECT_ID ('sat.ВыдачаДенежныхСредств_Платежи') is not null
		AND @mode = 1
		and @СсылкаДоговораЗайма is null
		and @GuidДоговораЗайма is null
		and @КодДоговораЗайма is null
	begin
		select 
			@rowVersion = isnull(max(ВерсияДанных) - 100, 0x0),
			@ДатаПлатежа = isnull(dateadd(day, -20, max(ДатаПлатежа)), '2000-01-01')
		from sat.ВыдачаДенежныхСредств_Платежи
	end

	drop table if exists #t_ВыдачаДенежныхСредств_Платежи

	select distinct 
		GuidВыдачаДенежныхСредств = cast(dbo.getGUIDFrom1C_IDRREF(p.Ссылка) as uniqueidentifier),
		СсылкаВыдачаДенежныхСредств = p.Ссылка,
		--
		p.НомерСтроки,
		ДатаПлатежа = dateadd(year, -2000, p.ДатаПлатежа),
		p.НомерПлатежа,
		СуммаПлатежа = cast(p.СуммаПлатежа as money),
		ИдентификаторПлатежа = nullif(trim(p.ИдентификаторПлатежа), ''),
		ИдентификаторПлатежнойСистемы = nullif(trim(p.ИдентификаторПлатежнойСистемы), ''),
		p.ПлатежныйПроект,
		p.КлючЗаписи,
		--
		ВерсияДанных = cast(v.ВерсияДанных AS binary(8)),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_ВыдачаДенежныхСредств_Платежи
	--SELECT *,v.ВерсияДанных
	from Stg._1cCMR.Документ_ВыдачаДенежныхСредств_Платежи as p
		inner join Stg._1cCMR.Документ_ВыдачаДенежныхСредств AS v
			on v.Ссылка = p.Ссылка
		inner join hub.ДоговорЗайма as d
			on d.СсылкаДоговораЗайма = v.Договор
	where (
			v.ВерсияДанных > @rowVersion
			or p.ДатаПлатежа >= dateadd(year, 2000, @ДатаПлатежа)
		)
		and (d.СсылкаДоговораЗайма = @СсылкаДоговораЗайма or @СсылкаДоговораЗайма is null)
		and (d.GuidДоговораЗайма = @GuidДоговораЗайма or @GuidДоговораЗайма is null)
		and (d.КодДоговораЗайма = @КодДоговораЗайма or @КодДоговораЗайма is null)

	if @isDebug = 1
	begin
		drop table if exists ##t_ВыдачаДенежныхСредств_Платежи
		SELECT * INTO ##t_ВыдачаДенежныхСредств_Платежи FROM #t_ВыдачаДенежныхСредств_Платежи
	end

	if OBJECT_ID('sat.ВыдачаДенежныхСредств_Платежи') is null
	begin
	
		select top(0)
			GuidВыдачаДенежныхСредств,
			СсылкаВыдачаДенежныхСредств,
			--
			НомерСтроки,
			ДатаПлатежа,
			НомерПлатежа,
			СуммаПлатежа,
			ИдентификаторПлатежа,
			ИдентификаторПлатежнойСистемы,
			ПлатежныйПроект,
			КлючЗаписи,
			--
			ВерсияДанных,
			created_at,
			updated_at,
			spFillName
		into sat.ВыдачаДенежныхСредств_Платежи
		from #t_ВыдачаДенежныхСредств_Платежи

		alter table sat.ВыдачаДенежныхСредств_Платежи
			alter column GuidВыдачаДенежныхСредств uniqueidentifier not null

		alter table sat.ВыдачаДенежныхСредств_Платежи
			alter column НомерСтроки numeric(5,0) not null

		ALTER TABLE sat.ВыдачаДенежныхСредств_Платежи
			ADD CONSTRAINT PK_ВыдачаДенежныхСредств_Платежи 
			PRIMARY KEY CLUSTERED (GuidВыдачаДенежныхСредств, НомерСтроки)

		create index ix_СсылкаВыдачаДенежныхСредств
		on sat.ВыдачаДенежныхСредств_Платежи(СсылкаВыдачаДенежныхСредств, НомерСтроки)
	end
	
	begin tran
		if @mode = 0 begin
			delete v from sat.ВыдачаДенежныхСредств_Платежи as v
		end

		merge sat.ВыдачаДенежныхСредств_Платежи t
		using #t_ВыдачаДенежныхСредств_Платежи s
			on t.GuidВыдачаДенежныхСредств = s.GuidВыдачаДенежныхСредств
			and t.НомерСтроки = s.НомерСтроки
		when not matched then insert
		(
			GuidВыдачаДенежныхСредств,
			СсылкаВыдачаДенежныхСредств,
			--
			НомерСтроки,
			ДатаПлатежа,
			НомерПлатежа,
			СуммаПлатежа,
			ИдентификаторПлатежа,
			ИдентификаторПлатежнойСистемы,
			ПлатежныйПроект,
			КлючЗаписи,
			--
			ВерсияДанных,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidВыдачаДенежныхСредств,
			s.СсылкаВыдачаДенежныхСредств,
			--
			s.НомерСтроки,
			s.ДатаПлатежа,
			s.НомерПлатежа,
			s.СуммаПлатежа,
			s.ИдентификаторПлатежа,
			s.ИдентификаторПлатежнойСистемы,
			s.ПлатежныйПроект,
			s.КлючЗаписи,
			--
			s.ВерсияДанных,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched and (
			t.ВерсияДанных <> s.ВерсияДанных
			or t.ДатаПлатежа <> s.ДатаПлатежа
			or t.ИдентификаторПлатежнойСистемы<> s.ИдентификаторПлатежнойСистемы 
			or t.ИдентификаторПлатежа<> s.ИдентификаторПлатежа
			OR @mode = 0
			OR @СсылкаДоговораЗайма is not null
			OR @GuidДоговораЗайма is not null
			OR @КодДоговораЗайма is not null
		)
		then update SET
			--t.GuidВыдачаДенежныхСредств = s.GuidВыдачаДенежныхСредств,
			t.СсылкаВыдачаДенежныхСредств = s.СсылкаВыдачаДенежныхСредств,
			--
			--t.НомерСтроки = s.НомерСтроки,
			t.ДатаПлатежа = s.ДатаПлатежа,
			t.НомерПлатежа = s.НомерПлатежа,
			t.СуммаПлатежа = s.СуммаПлатежа,
			t.ИдентификаторПлатежа = s.ИдентификаторПлатежа,
			t.ИдентификаторПлатежнойСистемы = s.ИдентификаторПлатежнойСистемы,
			t.ПлатежныйПроект = s.ПлатежныйПроект,
			t.КлючЗаписи = s.КлючЗаписи,
			--
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
