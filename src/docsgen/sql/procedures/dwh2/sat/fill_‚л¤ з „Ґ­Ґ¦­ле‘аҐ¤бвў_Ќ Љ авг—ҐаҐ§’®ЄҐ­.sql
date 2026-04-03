--exec sat.fill_ВыдачаДенежныхСредств_НаКартуЧерезТокен
create   PROC sat.fill_ВыдачаДенежныхСредств_НаКартуЧерезТокен
	@mode int = 1,
	@СсылкаДоговораЗайма binary(16) = null,
	@GuidДоговораЗайма uniqueidentifier = null,
	@КодДоговораЗайма nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table sat.ВыдачаДенежныхСредств_НаКартуЧерезТокен
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0
	--declare @ДатаСтатусаДействует datetime2(0) = '2000-01-01'
	--declare @ДатаВыдачиДенежныхСредств datetime2(0) = '2000-01-01'

	declare @ВерсияДанных_ВыдачаДенежныхСредств binary(8) = 0x0
	declare @RowVersion_ClientRequest binary(8) = 0x0

	if OBJECT_ID ('sat.ВыдачаДенежныхСредств_НаКартуЧерезТокен') is not null
		and @mode = 1
		and @СсылкаДоговораЗайма is null
		and @GuidДоговораЗайма is null
		and @КодДоговораЗайма is null
	begin
		--select 
		--	@rowVersion = isnull(cast(max(cast(s.ВерсияДанных as bigint)) - 100000 as binary(8)), 0x0),
		--	@ДатаСтатусаДействует = isnull(dateadd(day, -30, max(s.ДатаСтатусаДействует)), '2000-01-01'),
		--	@ДатаВыдачиДенежныхСредств = isnull(dateadd(day, -30, max(s.ДатаВыдачиДенежныхСредств)), '2000-01-01')
		--from sat.ВыдачаДенежныхСредств_НаКартуЧерезТокен as s

		select 
			--@rowVersion = isnull(max(s.ВерсияДанных) - 100, 0x0),
			@ВерсияДанных_ВыдачаДенежныхСредств = isnull(cast(max(cast(s.ВерсияДанных_ВыдачаДенежныхСредств as bigint)) - 100000 as binary(8)), 0x0),
			@RowVersion_ClientRequest = isnull(cast(max(cast(s.RowVersion_ClientRequest as bigint)) - 100000 as binary(8)), 0x0)
		from sat.ВыдачаДенежныхСредств_НаКартуЧерезТокен as s
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
		inner join link.ВыдачаДенежныхСредств_СпособыВыдачи as ls
			on ls.GuidВыдачаДенежныхСредств = v.GuidВыдачаДенежныхСредств
		inner join hub.СпособыВыдачиДенежныхСредств as s
			on s.GuidСпособыВыдачиДенежныхСредств = ls.GuidСпособыВыдачиДенежныхСредств
			and s.КодСпособаВыдачи = 'ECommPayНаБанковскуюКартуПоТокену' -- На карту через токен
		--
		inner join link.ДоговорЗайма_Заявка as ldr
			on ldr.КодДоговораЗайма = d.КодДоговораЗайма
		inner join Stg._fedor.core_ClientRequest as cr
			on cr.Id = ldr.GuidЗаявки
	where 1=1
		--
		and (
			--1 появились/обновились записи в hub.ВыдачаДенежныхСредств
			v.ВерсияДанных > @ВерсияДанных_ВыдачаДенежныхСредств
			--2 появились/обновились записи в ПлатежноеПоручение
			or cr.RowVersion > @RowVersion_ClientRequest
		)
		and (d.СсылкаДоговораЗайма = @СсылкаДоговораЗайма or @СсылкаДоговораЗайма is null)
		and (d.GuidДоговораЗайма = @GuidДоговораЗайма or @GuidДоговораЗайма is null)
		and (d.КодДоговораЗайма = @КодДоговораЗайма or @КодДоговораЗайма is null)

	if @isDebug = 1
	begin
		drop table if exists ##t_ДоговорЗайма
		SELECT * INTO ##t_ДоговорЗайма FROM #t_ДоговорЗайма
	end


	drop table if exists #t_sat_ВыдачаДенежныхСредств_НаКартуЧерезТокен



	select distinct
		l.GuidВыдачаДенежныхСредств,
		cr.IssuanceCardToken,
		--
		ВерсияДанных_ВыдачаДенежныхСредств = v.ВерсияДанных,
		RowVersion_ClientRequest = cr.RowVersion,
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_sat_ВыдачаДенежныхСредств_НаКартуЧерезТокен
	from #t_ДоговорЗайма as d
		inner join link.ДоговорЗайма_ВыдачаДенежныхСредств as l
			on l.КодДоговораЗайма = d.КодДоговораЗайма
		inner join hub.ВыдачаДенежныхСредств as v
			on v.GuidВыдачаДенежныхСредств = l.GuidВыдачаДенежныхСредств
		inner join link.ВыдачаДенежныхСредств_СпособыВыдачи as ls
			on ls.GuidВыдачаДенежныхСредств = v.GuidВыдачаДенежныхСредств
		inner join hub.СпособыВыдачиДенежныхСредств as s
			on s.GuidСпособыВыдачиДенежныхСредств = ls.GuidСпособыВыдачиДенежныхСредств
			and s.КодСпособаВыдачи = 'ECommPayНаБанковскуюКартуПоТокену' -- На карту через токен
		--
		inner join link.ДоговорЗайма_Заявка as ldr
			on ldr.КодДоговораЗайма = d.КодДоговораЗайма
		inner join Stg._fedor.core_ClientRequest as cr
			on cr.Id = ldr.GuidЗаявки
	where 1=1

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_sat_ВыдачаДенежныхСредств_НаКартуЧерезТокен
		SELECT * INTO ##t_sat_ВыдачаДенежныхСредств_НаКартуЧерезТокен FROM #t_sat_ВыдачаДенежныхСредств_НаКартуЧерезТокен
		--RETURN 0
	END


	if OBJECT_ID('sat.ВыдачаДенежныхСредств_НаКартуЧерезТокен') is null
	begin
		select top(0)
			GuidВыдачаДенежныхСредств,
			IssuanceCardToken,
			--
			ВерсияДанных_ВыдачаДенежныхСредств,
			RowVersion_ClientRequest,
            created_at,
            updated_at,
            spFillName
		into sat.ВыдачаДенежныхСредств_НаКартуЧерезТокен
		from #t_sat_ВыдачаДенежныхСредств_НаКартуЧерезТокен

		alter table sat.ВыдачаДенежныхСредств_НаКартуЧерезТокен
		alter column GuidВыдачаДенежныхСредств uniqueidentifier not null

		ALTER TABLE sat.ВыдачаДенежныхСредств_НаКартуЧерезТокен
		ADD CONSTRAINT PK_ВыдачаДенежныхСредств_НаКартуЧерезТокен 
		PRIMARY KEY CLUSTERED (GuidВыдачаДенежныхСредств)
	end

	begin tran
		if @mode = 0 begin
			delete s
			from sat.ВыдачаДенежныхСредств_НаКартуЧерезТокен as s
		end

		--удалить/вставить все для списка договоров
		delete s
		from #t_ДоговорЗайма as d
			inner join link.ДоговорЗайма_ВыдачаДенежныхСредств as l
				on l.КодДоговораЗайма = d.КодДоговораЗайма
			inner join sat.ВыдачаДенежныхСредств_НаКартуЧерезТокен as s
				on s.GuidВыдачаДенежныхСредств = l.GuidВыдачаДенежныхСредств

		insert sat.ВыдачаДенежныхСредств_НаКартуЧерезТокен
		(
			GuidВыдачаДенежныхСредств,
			IssuanceCardToken,
			--
			ВерсияДанных_ВыдачаДенежныхСредств,
			RowVersion_ClientRequest,
            created_at,
            updated_at,
            spFillName
		)
		select 
			GuidВыдачаДенежныхСредств,
			IssuanceCardToken,
			--
			ВерсияДанных_ВыдачаДенежныхСредств,
			RowVersion_ClientRequest,
            created_at,
            updated_at,
            spFillName
		from #t_sat_ВыдачаДенежныхСредств_НаКартуЧерезТокен
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
