/*
exec hub.fill_ВыдачаДенежныхСредств
*/
CREATE PROC hub.fill_ВыдачаДенежныхСредств
	@mode int = 1,
	@СсылкаДоговораЗайма binary(16) = null,
	@GuidДоговораЗайма uniqueidentifier = null,
	@КодДоговораЗайма nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table hub.ВыдачаДенежныхСредств
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	if OBJECT_ID ('hub.ВыдачаДенежныхСредств') is not null
		AND @mode = 1
		and @СсылкаДоговораЗайма is null
		and @GuidДоговораЗайма is null
		and @КодДоговораЗайма is null
	begin
		set @rowVersion = isnull((select max(ВерсияДанных) - 100 from hub.ВыдачаДенежныхСредств), 0x0)
	end

	drop table if exists #t_ВыдачаДенежныхСредств

	select distinct 
		GuidВыдачаДенежныхСредств = cast(dbo.getGUIDFrom1C_IDRREF(v.Ссылка) as uniqueidentifier),
		СсылкаВыдачаДенежныхСредств = v.Ссылка,
		isDelete = cast(v.ПометкаУдаления as bit),
		--
		Дата = dateadd(year, -2000, v.Дата),
		v.Номер,
		v.Проведен,
		--Договор link
		Сумма = cast(v.Сумма as money),
		--Основание
		--СпособВыдачи link
		--Статус link ?
		--Ответственный
		--Комментарий
		v.ПервичныйДокумент,
		--ДатаВыдачи = dateadd(year, -2000, v.ДатаВыдачи),
		ДатаВыдачи = dateadd(year, -2000, nullif(v.ДатаВыдачи,'2001-01-01 00:00:00')),
		--ПлатежнаяСистема link ?
		--Клиент
		v.ИдентификаторПС,
		v.DOC_ID,
		--
		ВерсияДанных = cast(v.ВерсияДанных AS binary(8)),
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_ВыдачаДенежныхСредств
	--SELECT *,v.ВерсияДанных
	from Stg._1cCMR.Документ_ВыдачаДенежныхСредств AS v
		inner join hub.ДоговорЗайма as d
			on d.СсылкаДоговораЗайма = v.Договор
	where v.ВерсияДанных > @rowVersion
		and (d.СсылкаДоговораЗайма = @СсылкаДоговораЗайма or @СсылкаДоговораЗайма is null)
		and (d.GuidДоговораЗайма = @GuidДоговораЗайма or @GuidДоговораЗайма is null)
		and (d.КодДоговораЗайма = @КодДоговораЗайма or @КодДоговораЗайма is null)

	if @isDebug = 1
	begin
		drop table if exists ##t_ВыдачаДенежныхСредств
		SELECT * INTO ##t_ВыдачаДенежныхСредств FROM #t_ВыдачаДенежныхСредств
	end

	if OBJECT_ID('hub.ВыдачаДенежныхСредств') is null
	begin
	
		select top(0)
			GuidВыдачаДенежныхСредств,
			СсылкаВыдачаДенежныхСредств,
			isDelete,
			Дата,
			Номер,
			Проведен,
			Сумма,
			ПервичныйДокумент,
			ДатаВыдачи,
			ИдентификаторПС,
			DOC_ID,
			ВерсияДанных,
			created_at,
			updated_at,
			spFillName
		into hub.ВыдачаДенежныхСредств
		from #t_ВыдачаДенежныхСредств

		alter table hub.ВыдачаДенежныхСредств
			alter column GuidВыдачаДенежныхСредств uniqueidentifier not null

		ALTER TABLE hub.ВыдачаДенежныхСредств
			ADD CONSTRAINT PK_ВыдачаДенежныхСредств PRIMARY KEY CLUSTERED (GuidВыдачаДенежныхСредств)

		create index ix_СсылкаВыдачаДенежныхСредств
		on hub.ВыдачаДенежныхСредств(СсылкаВыдачаДенежныхСредств)

		create index ix_isDelete_ДатаВыдачи
		on hub.ВыдачаДенежныхСредств(isDelete, ДатаВыдачи)
	end
	
	begin tran
		if @mode = 0 begin
			delete v from hub.ВыдачаДенежныхСредств as v
		end

		merge hub.ВыдачаДенежныхСредств t
		using #t_ВыдачаДенежныхСредств s
			on t.GuidВыдачаДенежныхСредств = s.GuidВыдачаДенежныхСредств
		when not matched then insert
		(
			GuidВыдачаДенежныхСредств,
			СсылкаВыдачаДенежныхСредств,
			isDelete,
			Дата,
			Номер,
			Проведен,
			Сумма,
			ПервичныйДокумент,
			ДатаВыдачи,
			ИдентификаторПС,
			DOC_ID,
			ВерсияДанных,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidВыдачаДенежныхСредств,
			s.СсылкаВыдачаДенежныхСредств,
			s.isDelete,
			s.Дата,
			s.Номер,
			s.Проведен,
			s.Сумма,
			s.ПервичныйДокумент,
			s.ДатаВыдачи,
			s.ИдентификаторПС,
			s.DOC_ID,
			s.ВерсияДанных,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched and (
			t.ВерсияДанных <> s.ВерсияДанных
			OR @mode = 0
			OR @СсылкаДоговораЗайма is not null
			OR @GuidДоговораЗайма is not null
			OR @КодДоговораЗайма is not null
		)
		then update SET
			t.СсылкаВыдачаДенежныхСредств = s.СсылкаВыдачаДенежныхСредств,
			t.isDelete = s.isDelete,
			t.Дата = s.Дата,
			t.Номер = s.Номер,
			t.Проведен = s.Проведен,
			t.Сумма = s.Сумма,
			t.ПервичныйДокумент = s.ПервичныйДокумент,
			t.ДатаВыдачи = s.ДатаВыдачи,
			t.ИдентификаторПС = s.ИдентификаторПС,
			t.DOC_ID = s.DOC_ID,
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
