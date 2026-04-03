--exec link.fill_Заявка_ТипДокументаНаПодпись
create   PROC link.fill_Заявка_ТипДокументаНаПодпись
	@mode int = 1,
	@СсылкаЗаявки binary(16) = null,
	@GuidЗаявки uniqueidentifier = null,
	@НомерЗаявки nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table link.Заявка_ТипДокументаНаПодпись
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @request_file_updated_at datetime = '2000-01-01'

	if OBJECT_ID('link.Заявка_ТипДокументаНаПодпись') is not null
		and @mode = 1
		and @СсылкаЗаявки is null
		and @GuidЗаявки is null
		and @НомерЗаявки is null
	begin
		--set @rowVersion = isnull((select max(s.ВерсияДанных) - 100 from link.Заявка_ТипДокументаНаПодпись as s), 0x0)
		select @request_file_updated_at = isnull(
				(
					select dateadd(day, -10, max(s.request_file_updated_at))
					from link.Заявка_ТипДокументаНаПодпись as s
				), 
				'2020-01-01'
			)
	end


	drop table if exists #t_Заявка_ТипДокументаНаПодпись

	select 
		GuidLink_Заявка_ТипДокументаНаПодпись = 
			try_cast(
				hashbytes('SHA2_256', concat(t.GuidЗаявки,'|',t.GuidТипДокументаНаПодпись))
				as uniqueidentifier
			),
		t.GuidЗаявки,
		t.GuidТипДокументаНаПодпись,
		--t.file_id,
		--t.file_guid,
		t.request_file_updated_at,
		--
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_Заявка_ТипДокументаНаПодпись
	from (
		select distinct --top 10 
			h.GuidЗаявки,
			td.GuidТипДокументаНаПодпись,
			--rf.file_id,
			--file_guid = f.guid,
			request_file_updated_at = rf.updated_at,
			rn = row_number() over(
				partition by h.GuidЗаявки, td.GuidТипДокументаНаПодпись
				order by rf.updated_at desc, getdate()
			)
		from hub.Заявка as h
			inner join Stg._LK.requests as r
				--on r.guid = h.GuidЗаявки
				on r.guid = cast(h.GuidЗаявки as varchar(36))
			inner join Stg._LK.request_file as rf
				on rf.request_id = r.Id
				and charindex('doc_pack', rf.file_bind) > 0
			inner join Stg._LK.[file] as f 
				on f.id = rf.file_id
			inner join hub.ТипДокументаНаПодпись as td
				on td.GuidТипДокументаНаПодпись = f.form_type_guid
		where 1=1
			and rf.updated_at > @request_file_updated_at
			and (h.СсылкаЗаявки = @СсылкаЗаявки or @СсылкаЗаявки is null)
			and (h.GuidЗаявки = @GuidЗаявки or @GuidЗаявки is null)
			and (h.НомерЗаявки = @НомерЗаявки or @НомерЗаявки is null)
		) as t
	where t.rn = 1


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Заявка_ТипДокументаНаПодпись
		SELECT * INTO ##t_Заявка_ТипДокументаНаПодпись FROM #t_Заявка_ТипДокументаНаПодпись
		--test
		--RETURN 0
	END


	if OBJECT_ID('link.Заявка_ТипДокументаНаПодпись') is null
	begin
		select top(0)
			GuidLink_Заявка_ТипДокументаНаПодпись,
			GuidЗаявки,
			GuidТипДокументаНаПодпись,
			--file_id,
			--file_guid,
			request_file_updated_at,

            created_at,
            updated_at,
            spFillName
		into link.Заявка_ТипДокументаНаПодпись
		from #t_Заявка_ТипДокументаНаПодпись

		alter table link.Заявка_ТипДокументаНаПодпись
		alter column GuidLink_Заявка_ТипДокументаНаПодпись uniqueidentifier not null

		ALTER TABLE link.Заявка_ТипДокументаНаПодпись
		ADD CONSTRAINT PK_Link_Заявка_ТипДокументаНаПодпись PRIMARY KEY CLUSTERED (GuidLink_Заявка_ТипДокументаНаПодпись)

		create index ix_GuidЗаявки
		on link.Заявка_ТипДокументаНаПодпись(GuidЗаявки)
	end

	begin tran
		if @mode = 0 begin
			delete t
			from link.Заявка_ТипДокументаНаПодпись as t
		end

		merge link.Заявка_ТипДокументаНаПодпись t
		using #t_Заявка_ТипДокументаНаПодпись s
			on t.GuidLink_Заявка_ТипДокументаНаПодпись = s.GuidLink_Заявка_ТипДокументаНаПодпись
		when not matched then insert
		(
			GuidLink_Заявка_ТипДокументаНаПодпись,
			GuidЗаявки,
			GuidТипДокументаНаПодпись,
			--file_id,
			--file_guid,
			request_file_updated_at,

			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidLink_Заявка_ТипДокументаНаПодпись,
			s.GuidЗаявки,
			s.GuidТипДокументаНаПодпись,
			--s.file_id,
			--s.file_guid,
			s.request_file_updated_at,

			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched and (
				t.request_file_updated_at <> s.request_file_updated_at
				or @mode = 0
			)
		then update SET
			t.GuidLink_Заявка_ТипДокументаНаПодпись = s.GuidLink_Заявка_ТипДокументаНаПодпись,
			t.GuidЗаявки = s.GuidЗаявки,
			t.GuidТипДокументаНаПодпись = s.GuidТипДокументаНаПодпись,
			--t.file_id = s.file_id,
			--t.file_guid = s.file_guid,
			t.request_file_updated_at = s.request_file_updated_at,

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
