--exec link.fill_ВыдачаДенежныхСредств_Банки
create   PROC link.fill_ВыдачаДенежныхСредств_Банки
	@mode int = 1,
	@СсылкаДоговораЗайма binary(16) = null,
	@GuidДоговораЗайма uniqueidentifier = null,
	@КодДоговораЗайма nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table link.ВыдачаДенежныхСредств_Банки
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_ВыдачаДенежныхСредств_Банки

	if OBJECT_ID ('link.ВыдачаДенежныхСредств_Банки') is not null
		and @mode = 1
		and @СсылкаДоговораЗайма is null
		and @GuidДоговораЗайма is null
		and @КодДоговораЗайма is null
	begin
		set @rowVersion = isnull((select max(s.ВерсияДанных) - 100000 from link.ВыдачаДенежныхСредств_Банки as s), 0x0)
	end

	select 
		--t.СсылкаДоговораЗайма,
		--t.GuidДоговораЗайма,
		GuidLink_ВыдачаДенежныхСредств_Банки = 
			try_cast(
				hashbytes('SHA2_256', concat(t.GuidВыдачаДенежныхСредств,'|',t.GuidБанки))
				as uniqueidentifier
			),

		t.GuidВыдачаДенежныхСредств,
		t.GuidБанки,
		t.ВерсияДанных,
		--
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_ВыдачаДенежныхСредств_Банки
	from (
		select distinct
			--d.СсылкаДоговораЗайма,
			--d.GuidДоговораЗайма,
			v.GuidВыдачаДенежныхСредств,
			b.GuidБанки,

			v.ВерсияДанных
			--rn = row_number() over(
			--	partition by d.КодДоговораЗайма, p.GuidВыдачаДенежныхСредств
			--	order by dp.ВерсияДанных desc, getdate()
			--)
		--select top 100 v.GuidВыдачаДенежныхСредств, b.GuidБанки, d.КодДоговораЗайма
		FROM hub.ВыдачаДенежныхСредств as v
			inner join link.ДоговорЗайма_ВыдачаДенежныхСредств as l
				on l.GuidВыдачаДенежныхСредств = v.GuidВыдачаДенежныхСредств
			inner join hub.ДоговорЗайма as d
				on d.КодДоговораЗайма = l.КодДоговораЗайма
			inner join link.ВыдачаДенежныхСредств_СпособыВыдачи as ls
				on ls.GuidВыдачаДенежныхСредств = v.GuidВыдачаДенежныхСредств
			inner join hub.СпособыВыдачиДенежныхСредств as s
				on s.GuidСпособыВыдачиДенежныхСредств = ls.GuidСпособыВыдачиДенежныхСредств
				and s.КодСпособаВыдачи = 'forceFnpWaitTransfer' --На счет дилера
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
				on ПлатежноеПоручение.СчетКонтрагента = БанковскиеСчета.Ссылка
			--inner join Stg._1cUMFO.Справочник_Банки as Банки
			--	on БанковскиеСчета.Банк = Банки.Ссылка
			--
			inner join hub.Банки as b
				on b.СсылкаБанки = БанковскиеСчета.Банк
		where 1=1
			and v.ВерсияДанных > @rowVersion
			and (d.СсылкаДоговораЗайма = @СсылкаДоговораЗайма or @СсылкаДоговораЗайма is null)
			and (d.GuidДоговораЗайма = @GuidДоговораЗайма or @GuidДоговораЗайма is null)
			and (d.КодДоговораЗайма = @КодДоговораЗайма or @КодДоговораЗайма is null)
		) as t
		--where t.rn = 1


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ВыдачаДенежныхСредств_Банки
		SELECT * INTO ##t_ВыдачаДенежныхСредств_Банки FROM #t_ВыдачаДенежныхСредств_Банки
		--RETURN 0
	END


	if OBJECT_ID('link.ВыдачаДенежныхСредств_Банки') is null
	begin
		select top(0)
			GuidLink_ВыдачаДенежныхСредств_Банки,
			GuidВыдачаДенежныхСредств,
			GuidБанки,
			ВерсияДанных,

            created_at,
            updated_at,
            spFillName
		into link.ВыдачаДенежныхСредств_Банки
		from #t_ВыдачаДенежныхСредств_Банки

		alter table link.ВыдачаДенежныхСредств_Банки
		alter column GuidLink_ВыдачаДенежныхСредств_Банки uniqueidentifier not null

		ALTER TABLE link.ВыдачаДенежныхСредств_Банки
		ADD CONSTRAINT PK_Link_ВыдачаДенежныхСредств_Банки 
		PRIMARY KEY CLUSTERED (GuidLink_ВыдачаДенежныхСредств_Банки)

		create index ix_КодДоговораЗайма 
		on link.ВыдачаДенежныхСредств_Банки(
			GuidВыдачаДенежныхСредств,
			GuidБанки
		)
	end

	begin tran
		if @mode = 0 begin
			delete t
			from link.ВыдачаДенежныхСредств_Банки as t
		end

		merge link.ВыдачаДенежныхСредств_Банки t
		using #t_ВыдачаДенежныхСредств_Банки s
			on t.GuidLink_ВыдачаДенежныхСредств_Банки = s.GuidLink_ВыдачаДенежныхСредств_Банки
		when not matched then insert
		(
			GuidLink_ВыдачаДенежныхСредств_Банки,
			GuidВыдачаДенежныхСредств,
			GuidБанки,
			ВерсияДанных,

			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidLink_ВыдачаДенежныхСредств_Банки,
			s.GuidВыдачаДенежныхСредств,
			s.GuidБанки,
			s.ВерсияДанных,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched and (
				t.ВерсияДанных <> s.ВерсияДанных
				or @mode = 0
			)
		then update SET
			t.GuidLink_ВыдачаДенежныхСредств_Банки = s.GuidLink_ВыдачаДенежныхСредств_Банки,
			t.GuidВыдачаДенежныхСредств = s.GuidВыдачаДенежныхСредств,
			t.GuidБанки = s.GuidБанки,
			t.ВерсияДанных = s.ВерсияДанных,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
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
