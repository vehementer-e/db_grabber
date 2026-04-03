--exec sat.fill_link_ВыдачаДенежныхСредств_Банки_НаСчетДилера
create   PROC sat.fill_link_ВыдачаДенежныхСредств_Банки_НаСчетДилера
	@mode int = 1,
	@СсылкаДоговораЗайма binary(16) = null,
	@GuidДоговораЗайма uniqueidentifier = null,
	@КодДоговораЗайма nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table sat.link_ВыдачаДенежныхСредств_Банки_НаСчетДилера
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	declare @ВерсияДанных_ВыдачаДенежныхСредств binary(8) = 0x0
	declare @ВерсияДанных_ПлатежноеПоручение binary(8) = 0x0
	

	if OBJECT_ID ('sat.link_ВыдачаДенежныхСредств_Банки_НаСчетДилера') is not null
		and @mode = 1
		and @СсылкаДоговораЗайма is null
		and @GuidДоговораЗайма is null
		and @КодДоговораЗайма is null
	begin
		select 
			@ВерсияДанных_ВыдачаДенежныхСредств = isnull(cast(max(cast(s.ВерсияДанных_ВыдачаДенежныхСредств as bigint)) - 100000 as binary(8)), 0x0),
			@ВерсияДанных_ПлатежноеПоручение = isnull(cast(max(cast(s.ВерсияДанных_ПлатежноеПоручение as bigint)) - 100000 as binary(8)), 0x0)
		from sat.link_ВыдачаДенежныхСредств_Банки_НаСчетДилера as s
	end

	--список договоров, у которых появились/обновились доп продукты
	drop table if exists #t_ДоговорЗайма
	create table #t_ДоговорЗайма
	(
		СсылкаДоговораЗайма binary(16),
		GuidДоговораЗайма uniqueidentifier,
		КодДоговораЗайма nvarchar(14)
	)

	insert #t_ДоговорЗайма
	(
		СсылкаДоговораЗайма,
		GuidДоговораЗайма,
		КодДоговораЗайма
	)
	select distinct
		d.СсылкаДоговораЗайма,
		d.GuidДоговораЗайма,
		d.КодДоговораЗайма
	from hub.ДоговорЗайма as d
		inner join link.ДоговорЗайма_ВыдачаДенежныхСредств as l
			on l.КодДоговораЗайма = d.КодДоговораЗайма
		inner join hub.ВыдачаДенежныхСредств as v
			on v.GuidВыдачаДенежныхСредств = l.GuidВыдачаДенежныхСредств
		inner join link.ВыдачаДенежныхСредств_Банки as lvb
			on lvb.GuidВыдачаДенежныхСредств = l.GuidВыдачаДенежныхСредств
		inner join hub.Банки as b
			on b.GuidБанки = lvb.GuidБанки
		--
		inner join Stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный as ЗаймПредоставленный
			on ЗаймПредоставленный.НомерДоговора = d.КодДоговораЗайма
		inner join Stg._1cUMFO.Документ_ЗаявкаНаРасходованиеДенежныхСредств as ЗРДС
			on ЗРДС.Займ = ЗаймПредоставленный.Ссылка
		inner join Stg._1cUMFO.Документ_ПлатежноеПоручение as ПлатежноеПоручение
			on ПлатежноеПоручение.ЗаявкаНаРасходованиеДенежныхСредств = ЗРДС.Ссылка
		inner join Stg._1cUMFO.Перечисление_ТипыАвтоматическихЗаявок as ТипыАвтоматическихЗаявок
			on ТипыАвтоматическихЗаявок.Ссылка = ЗРДС.ТипАвтоматическойЗаявки
			and ТипыАвтоматическихЗаявок.Имя = 'acVtb'
		inner join Stg._1cUMFO.Справочник_БанковскиеСчета as БанковскиеСчета
			on БанковскиеСчета.Ссылка = ПлатежноеПоручение.СчетКонтрагента
			and БанковскиеСчета.Банк = b.СсылкаБанки
		--inner join Stg._1cUMFO.Справочник_Банки as Банки
		--	on БанковскиеСчета.Банк = Банки.Ссылка
	where 1=1
		--
		and (
			--1 появились/обновились записи в hub.ВыдачаДенежныхСредств
			v.ВерсияДанных > @ВерсияДанных_ВыдачаДенежныхСредств
			--2 появились/обновились записи в ПлатежноеПоручение
			or ПлатежноеПоручение.ВерсияДанных > @ВерсияДанных_ПлатежноеПоручение
		)
		and (d.СсылкаДоговораЗайма = @СсылкаДоговораЗайма or @СсылкаДоговораЗайма is null)
		and (d.GuidДоговораЗайма = @GuidДоговораЗайма or @GuidДоговораЗайма is null)
		and (d.КодДоговораЗайма = @КодДоговораЗайма or @КодДоговораЗайма is null)

	if @isDebug = 1
	begin
		drop table if exists ##t_ДоговорЗайма
		SELECT * INTO ##t_ДоговорЗайма FROM #t_ДоговорЗайма
	end


	drop table if exists #t_sat_link_ВыдачаДенежныхСредств_Банки_НаСчетДилера



	select distinct
		lvb.GuidLink_ВыдачаДенежныхСредств_Банки,
		--
		СсылкаПлатежноеПоручение = ПлатежноеПоручение.Ссылка,
		GuidПлатежноеПоручение = dbo.getGUIDFrom1C_IDRREF(ПлатежноеПоручение.Ссылка),
		--Займ = ЗаймПредоставленный.НомерДоговора,
		НомерСчетаЗаемщика = БанковскиеСчета.НомерСчета,
		--БИКбанкаЗаемщика = Банки.Код,
		ПлатежноеПоручение.Проведен,
		Дата = cast(dateadd(year, -2000, ПлатежноеПоручение.Дата) as datetime2(0)),
		СуммаДокумента = cast(ПлатежноеПоручение.СуммаДокумента as money),
		СуммаНДС = cast(ПлатежноеПоручение.СуммаНДС as money),
		ПлатежноеПоручение.НазначениеПлатежа,
		--
		ВерсияДанных_ВыдачаДенежныхСредств = v.ВерсияДанных,
		ВерсияДанных_ПлатежноеПоручение = ПлатежноеПоручение.ВерсияДанных,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_sat_link_ВыдачаДенежныхСредств_Банки_НаСчетДилера
	from #t_ДоговорЗайма as d
		inner join link.ДоговорЗайма_ВыдачаДенежныхСредств as l
			on l.КодДоговораЗайма = d.КодДоговораЗайма
		inner join hub.ВыдачаДенежныхСредств as v
			on v.GuidВыдачаДенежныхСредств = l.GuidВыдачаДенежныхСредств
		inner join link.ВыдачаДенежныхСредств_Банки as lvb
			on lvb.GuidВыдачаДенежныхСредств = l.GuidВыдачаДенежныхСредств
		inner join hub.Банки as b
			on b.GuidБанки = lvb.GuidБанки
		--
		inner join Stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный as ЗаймПредоставленный
			on ЗаймПредоставленный.НомерДоговора = d.КодДоговораЗайма
		inner join Stg._1cUMFO.Документ_ЗаявкаНаРасходованиеДенежныхСредств as ЗРДС
			on ЗРДС.Займ = ЗаймПредоставленный.Ссылка
		inner join Stg._1cUMFO.Документ_ПлатежноеПоручение as ПлатежноеПоручение
			on ПлатежноеПоручение.ЗаявкаНаРасходованиеДенежныхСредств = ЗРДС.Ссылка
		inner join Stg._1cUMFO.Перечисление_ТипыАвтоматическихЗаявок as ТипыАвтоматическихЗаявок
			on ТипыАвтоматическихЗаявок.Ссылка = ЗРДС.ТипАвтоматическойЗаявки
			and ТипыАвтоматическихЗаявок.Имя = 'acVtb'
		inner join Stg._1cUMFO.Справочник_БанковскиеСчета as БанковскиеСчета
			on БанковскиеСчета.Ссылка = ПлатежноеПоручение.СчетКонтрагента
			and БанковскиеСчета.Банк = b.СсылкаБанки
		--left join Stg._1cUMFO.Справочник_Банки as Банки
		--	on БанковскиеСчета.Банк = Банки.Ссылка
	where 1=1

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_sat_link_ВыдачаДенежныхСредств_Банки_НаСчетДилера
		SELECT * INTO ##t_sat_link_ВыдачаДенежныхСредств_Банки_НаСчетДилера FROM #t_sat_link_ВыдачаДенежныхСредств_Банки_НаСчетДилера
		--RETURN 0
	END


	if OBJECT_ID('sat.link_ВыдачаДенежныхСредств_Банки_НаСчетДилера') is null
	begin
		select top(0)
			GuidLink_ВыдачаДенежныхСредств_Банки,
			СсылкаПлатежноеПоручение,
			GuidПлатежноеПоручение,
			НомерСчетаЗаемщика,
			Проведен,
			Дата,
			СуммаДокумента,
			СуммаНДС,
			НазначениеПлатежа,
			--
			ВерсияДанных_ВыдачаДенежныхСредств,
			ВерсияДанных_ПлатежноеПоручение,
            created_at,
            updated_at,
            spFillName
		into sat.link_ВыдачаДенежныхСредств_Банки_НаСчетДилера
		from #t_sat_link_ВыдачаДенежныхСредств_Банки_НаСчетДилера

		alter table sat.link_ВыдачаДенежныхСредств_Банки_НаСчетДилера
		alter column GuidLink_ВыдачаДенежныхСредств_Банки uniqueidentifier not null

		alter table sat.link_ВыдачаДенежныхСредств_Банки_НаСчетДилера
		alter column GuidПлатежноеПоручение uniqueidentifier not null

		ALTER TABLE sat.link_ВыдачаДенежныхСредств_Банки_НаСчетДилера
		ADD CONSTRAINT PK_link_ВыдачаДенежныхСредств_Банки_НаСчетДилера 
		PRIMARY KEY CLUSTERED (
			GuidLink_ВыдачаДенежныхСредств_Банки,
			GuidПлатежноеПоручение
		)

	end

	begin tran
		if @mode = 0 begin
			delete s
			from sat.link_ВыдачаДенежныхСредств_Банки_НаСчетДилера as s
		end

		--удалить/вставить все для списка договоров
		delete s
		from #t_ДоговорЗайма as d
			inner join link.ДоговорЗайма_ВыдачаДенежныхСредств as l
				on l.КодДоговораЗайма = d.КодДоговораЗайма
			inner join link.ВыдачаДенежныхСредств_Банки as lvb
				on lvb.GuidВыдачаДенежныхСредств = l.GuidВыдачаДенежныхСредств
			inner join sat.link_ВыдачаДенежныхСредств_Банки_НаСчетДилера as s
				on s.GuidLink_ВыдачаДенежныхСредств_Банки = lvb.GuidLink_ВыдачаДенежныхСредств_Банки

		insert sat.link_ВыдачаДенежныхСредств_Банки_НаСчетДилера
		(
			GuidLink_ВыдачаДенежныхСредств_Банки,
			СсылкаПлатежноеПоручение,
			GuidПлатежноеПоручение,
			НомерСчетаЗаемщика,
			Проведен,
			Дата,
			СуммаДокумента,
			СуммаНДС,
			НазначениеПлатежа,
			--
			ВерсияДанных_ВыдачаДенежныхСредств,
			ВерсияДанных_ПлатежноеПоручение,
            created_at,
            updated_at,
            spFillName
		)
		select 
			GuidLink_ВыдачаДенежныхСредств_Банки,
			СсылкаПлатежноеПоручение,
			GuidПлатежноеПоручение,
			НомерСчетаЗаемщика,
			Проведен,
			Дата,
			СуммаДокумента,
			СуммаНДС,
			НазначениеПлатежа,
			--
			ВерсияДанных_ВыдачаДенежныхСредств,
			ВерсияДанных_ПлатежноеПоручение,
            created_at,
            updated_at,
            spFillName
		from #t_sat_link_ВыдачаДенежныхСредств_Банки_НаСчетДилера
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
