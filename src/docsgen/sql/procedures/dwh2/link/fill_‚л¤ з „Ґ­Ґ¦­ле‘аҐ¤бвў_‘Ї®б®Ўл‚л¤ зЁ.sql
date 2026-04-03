--exec link.fill_ВыдачаДенежныхСредств_СпособыВыдачи
CREATE PROC link.fill_ВыдачаДенежныхСредств_СпособыВыдачи
	@mode int = 1,
	@СсылкаДоговораЗайма binary(16) = null,
	@GuidДоговораЗайма uniqueidentifier = null,
	@КодДоговораЗайма nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table link.ВыдачаДенежныхСредств_СпособыВыдачи
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_ВыдачаДенежныхСредств_СпособыВыдачи

	if OBJECT_ID ('link.ВыдачаДенежныхСредств_СпособыВыдачи') is not null
		and @mode = 1
		and @СсылкаДоговораЗайма is null
		and @GuidДоговораЗайма is null
		and @КодДоговораЗайма is null
	begin
		set @rowVersion = isnull((select max(s.ВерсияДанных) - 100 from link.ВыдачаДенежныхСредств_СпособыВыдачи as s), 0x0)
	end

	select 
		--t.СсылкаДоговораЗайма,
		--t.GuidДоговораЗайма,
		--GuidLink_ВыдачаДенежныхСредств_СпособыВыдачи = 
		--	try_cast(
		--		hashbytes('SHA2_256', concat(t.GuidВыдачаДенежныхСредств,'|',t.GuidСпособыВыдачиДенежныхСредств))
		--		as uniqueidentifier
		--	),
		t.GuidВыдачаДенежныхСредств,
		t.GuidСпособыВыдачиДенежныхСредств,
		t.ВерсияДанных,
		--
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_ВыдачаДенежныхСредств_СпособыВыдачи
	from (
		select distinct
			h.GuidВыдачаДенежныхСредств,
			GuidСпособыВыдачиДенежныхСредств = isnull(
				s.GuidСпособыВыдачиДенежныхСредств,
				s2.GuidСпособыВыдачиДенежныхСредств
			),
			v.ВерсияДанных
		FROM Stg._1cCMR.Документ_ВыдачаДенежныхСредств AS v
			inner join hub.ДоговорЗайма as d
				on d.СсылкаДоговораЗайма = v.Договор
			inner join hub.ВыдачаДенежныхСредств as h
				on h.СсылкаВыдачаДенежныхСредств = v.Ссылка
			left join dwh2.hub.СпособыВыдачиДенежныхСредств as s
				on s.СсылкаСпособыВыдачиДенежныхСредств = v.СпособВыдачиДенежныхСредств
			--для тех многих записей, у которых v.СпособВыдачиДенежныхСредств = 0x0
			--связь по тексту в v.СпособВыдачи
			left join dwh2.hub.СпособыВыдачиДенежныхСредств as s2
				on s.СсылкаСпособыВыдачиДенежныхСредств is null
				and s2.КодСпособаВыдачи	= 
					case 
						when v.СпособВыдачи = 'На банковскую карту по токену(ECommPay)'
							then 'ECommPayНаБанковскуюКартуПоТокену'
						when v.СпособВыдачи = 'Через ECommPay СБП'
							then 'ЧерезECommPayСБП'
						else v.СпособВыдачи
					end
		where 1=1
			and v.ВерсияДанных > @rowVersion
			and (d.СсылкаДоговораЗайма = @СсылкаДоговораЗайма or @СсылкаДоговораЗайма is null)
			and (d.GuidДоговораЗайма = @GuidДоговораЗайма or @GuidДоговораЗайма is null)
			and (d.КодДоговораЗайма = @КодДоговораЗайма or @КодДоговораЗайма is null)
		) as t
	where t.GuidСпособыВыдачиДенежныхСредств is not null


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ВыдачаДенежныхСредств_СпособыВыдачи
		SELECT * INTO ##t_ВыдачаДенежныхСредств_СпособыВыдачи FROM #t_ВыдачаДенежныхСредств_СпособыВыдачи
		--RETURN 0
	END


	if OBJECT_ID('link.ВыдачаДенежныхСредств_СпособыВыдачи') is null
	begin
		select top(0)
			--GuidLink_ВыдачаДенежныхСредств_СпособыВыдачи,
			GuidВыдачаДенежныхСредств,
			GuidСпособыВыдачиДенежныхСредств,
			ВерсияДанных,
            created_at,
            updated_at,
            spFillName
		into link.ВыдачаДенежныхСредств_СпособыВыдачи
		from #t_ВыдачаДенежныхСредств_СпособыВыдачи

		--alter table link.ВыдачаДенежныхСредств_СпособыВыдачи
		--alter column GuidLink_ВыдачаДенежныхСредств_СпособыВыдачи uniqueidentifier not null

		--ALTER TABLE link.ВыдачаДенежныхСредств_СпособыВыдачи
		--ADD CONSTRAINT PK_Link_ВыдачаДенежныхСредств_СпособыВыдачи 
		--PRIMARY KEY CLUSTERED (GuidLink_ВыдачаДенежныхСредств_СпособыВыдачи)

		--create index ix_GuidВыдачаДенежныхСредств
		--on link.ВыдачаДенежныхСредств_СпособыВыдачи(
		--	GuidВыдачаДенежныхСредств, 
		--	GuidСпособыВыдачиДенежныхСредств
		--)

		alter table link.ВыдачаДенежныхСредств_СпособыВыдачи
		alter column GuidВыдачаДенежныхСредств uniqueidentifier not null

		ALTER TABLE link.ВыдачаДенежныхСредств_СпособыВыдачи
		ADD CONSTRAINT PK_Link_ВыдачаДенежныхСредств_СпособыВыдачи 
		PRIMARY KEY CLUSTERED (GuidВыдачаДенежныхСредств)
	end

	begin tran
		if @mode = 0 begin
			delete t
			from link.ВыдачаДенежныхСредств_СпособыВыдачи as t
		end

		merge link.ВыдачаДенежныхСредств_СпособыВыдачи t
		using #t_ВыдачаДенежныхСредств_СпособыВыдачи s
			on t.GuidВыдачаДенежныхСредств = s.GuidВыдачаДенежныхСредств
		when not matched then insert
		(
			--GuidLink_ВыдачаДенежныхСредств_СпособыВыдачи,
			GuidВыдачаДенежныхСредств,
			GuidСпособыВыдачиДенежныхСредств,
			ВерсияДанных,

			created_at,
			updated_at,
			spFillName
		) values
		(
			--s.GuidLink_ВыдачаДенежныхСредств_СпособыВыдачи,
			s.GuidВыдачаДенежныхСредств,
			s.GuidСпособыВыдачиДенежныхСредств,
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
			--t.GuidLink_ВыдачаДенежныхСредств_СпособыВыдачи = s.GuidLink_ВыдачаДенежныхСредств_СпособыВыдачи,
			t.GuidВыдачаДенежныхСредств = s.GuidВыдачаДенежныхСредств,
			t.GuidСпособыВыдачиДенежныхСредств = s.GuidСпособыВыдачиДенежныхСредств,
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
