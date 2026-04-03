--exec link.fill_ДоговорЗайма_ВыдачаДенежныхСредств
create   PROC link.fill_ДоговорЗайма_ВыдачаДенежныхСредств
	@mode int = 1,
	@СсылкаДоговораЗайма binary(16) = null,
	@GuidДоговораЗайма uniqueidentifier = null,
	@КодДоговораЗайма nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table link.ДоговорЗайма_ВыдачаДенежныхСредств
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	declare @rowVersion binary(8) = 0x0

	drop table if exists #t_ДоговорЗайма_ВыдачаДенежныхСредств

	if OBJECT_ID ('link.ДоговорЗайма_ВыдачаДенежныхСредств') is not null
		and @mode = 1
		and @СсылкаДоговораЗайма is null
		and @GuidДоговораЗайма is null
		and @КодДоговораЗайма is null
	begin
		set @rowVersion = isnull((select max(s.ВерсияДанных) - 100 from link.ДоговорЗайма_ВыдачаДенежныхСредств as s), 0x0)
	end

	select 
		--t.СсылкаДоговораЗайма,
		--t.GuidДоговораЗайма,
		GuidLink_ДоговорЗайма_ВыдачаДенежныхСредств = 
			try_cast(
				hashbytes('SHA2_256', concat(t.КодДоговораЗайма,'|',t.GuidВыдачаДенежныхСредств))
				as uniqueidentifier
			),

		t.КодДоговораЗайма,
		t.GuidВыдачаДенежныхСредств,
		t.ВерсияДанных,
		--
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_ДоговорЗайма_ВыдачаДенежныхСредств
	from (
		select distinct
			--d.СсылкаДоговораЗайма,
			--d.GuidДоговораЗайма,
			d.КодДоговораЗайма,
			s.GuidВыдачаДенежныхСредств,

			v.ВерсияДанных
			--rn = row_number() over(
			--	partition by d.КодДоговораЗайма, p.GuidВыдачаДенежныхСредств
			--	order by dp.ВерсияДанных desc, getdate()
			--)
		FROM Stg._1cCMR.Документ_ВыдачаДенежныхСредств AS v
			inner join hub.ДоговорЗайма as d
				on d.СсылкаДоговораЗайма = v.Договор
			inner join hub.ВыдачаДенежныхСредств as s
				on s.СсылкаВыдачаДенежныхСредств = v.Ссылка
		where 1=1
			and v.ВерсияДанных > @rowVersion
			and (d.СсылкаДоговораЗайма = @СсылкаДоговораЗайма or @СсылкаДоговораЗайма is null)
			and (d.GuidДоговораЗайма = @GuidДоговораЗайма or @GuidДоговораЗайма is null)
			and (d.КодДоговораЗайма = @КодДоговораЗайма or @КодДоговораЗайма is null)
		) as t
		--where t.rn = 1


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_ДоговорЗайма_ВыдачаДенежныхСредств
		SELECT * INTO ##t_ДоговорЗайма_ВыдачаДенежныхСредств FROM #t_ДоговорЗайма_ВыдачаДенежныхСредств
		--RETURN 0
	END


	if OBJECT_ID('link.ДоговорЗайма_ВыдачаДенежныхСредств') is null
	begin
		select top(0)
			GuidLink_ДоговорЗайма_ВыдачаДенежныхСредств,
			КодДоговораЗайма,
			GuidВыдачаДенежныхСредств,
			ВерсияДанных,

            created_at,
            updated_at,
            spFillName
		into link.ДоговорЗайма_ВыдачаДенежныхСредств
		from #t_ДоговорЗайма_ВыдачаДенежныхСредств

		alter table link.ДоговорЗайма_ВыдачаДенежныхСредств
		alter column GuidLink_ДоговорЗайма_ВыдачаДенежныхСредств uniqueidentifier not null

		ALTER TABLE link.ДоговорЗайма_ВыдачаДенежныхСредств
		ADD CONSTRAINT PK_Link_ДоговорЗайма_ВыдачаДенежныхСредств PRIMARY KEY CLUSTERED (GuidLink_ДоговорЗайма_ВыдачаДенежныхСредств)

		create index ix_КодДоговораЗайма 
		on link.ДоговорЗайма_ВыдачаДенежныхСредств(КодДоговораЗайма, GuidВыдачаДенежныхСредств)
	end

	begin tran
		if @mode = 0 begin
			delete t
			from link.ДоговорЗайма_ВыдачаДенежныхСредств as t
		end

		merge link.ДоговорЗайма_ВыдачаДенежныхСредств t
		using #t_ДоговорЗайма_ВыдачаДенежныхСредств s
			on t.GuidLink_ДоговорЗайма_ВыдачаДенежныхСредств = s.GuidLink_ДоговорЗайма_ВыдачаДенежныхСредств
		when not matched then insert
		(
			GuidLink_ДоговорЗайма_ВыдачаДенежныхСредств,
			КодДоговораЗайма,
			GuidВыдачаДенежныхСредств,
			ВерсияДанных,

			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidLink_ДоговорЗайма_ВыдачаДенежныхСредств,
			s.КодДоговораЗайма,
			s.GuidВыдачаДенежныхСредств,
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
			t.GuidLink_ДоговорЗайма_ВыдачаДенежныхСредств = s.GuidLink_ДоговорЗайма_ВыдачаДенежныхСредств,
			t.КодДоговораЗайма = s.КодДоговораЗайма,
			t.GuidВыдачаДенежныхСредств = s.GuidВыдачаДенежныхСредств,
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
