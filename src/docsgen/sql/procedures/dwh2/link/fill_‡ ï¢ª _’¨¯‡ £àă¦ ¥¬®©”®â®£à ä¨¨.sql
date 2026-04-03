--exec link.fill_Заявка_ТипЗагружаемойФотографии
create   PROC link.fill_Заявка_ТипЗагружаемойФотографии
	@mode int = 1,
	@СсылкаЗаявки binary(16) = null,
	@GuidЗаявки uniqueidentifier = null,
	@НомерЗаявки nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table link.Заявка_ТипЗагружаемойФотографии
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @request_file_updated_at datetime = '2000-01-01'

	if OBJECT_ID('link.Заявка_ТипЗагружаемойФотографии') is not null
		and @mode = 1
		and @СсылкаЗаявки is null
		and @GuidЗаявки is null
		and @НомерЗаявки is null
	begin
		--set @rowVersion = isnull((select max(s.ВерсияДанных) - 100 from link.Заявка_ТипЗагружаемойФотографии as s), 0x0)
		select @request_file_updated_at = isnull(
				(
					select dateadd(day, -10, max(s.request_file_updated_at))
					from link.Заявка_ТипЗагружаемойФотографии as s
				), 
				'2020-01-01'
			)
	end


	drop table if exists #t_Заявка_ТипЗагружаемойФотографии

	select distinct
		GuidLink_Заявка_ТипЗагружаемойФотографии = 
			try_cast(
				hashbytes('SHA2_256', concat(t.GuidЗаявки,'|',t.GuidТипЗагружаемойФотографии))
				as uniqueidentifier
			),
		t.GuidЗаявки,
		t.GuidТипЗагружаемойФотографии,
		t.request_file_updated_at,
		--
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_Заявка_ТипЗагружаемойФотографии
	from (
		select
			h.GuidЗаявки,
			td.GuidТипЗагружаемойФотографии,
			request_file_updated_at = max(rf.updated_at)
		from hub.Заявка as h
			inner join Stg._LK.requests as r
				on r.guid = cast(h.GuidЗаявки as varchar(36))
			inner join Stg._LK.request_file as rf
				on rf.request_id = r.Id
				and charindex('foto_', rf.file_bind) > 0
			inner join hub.ТипЗагружаемойФотографии as td
				on td.file_bind = rf.file_bind
		where 1=1
			and rf.updated_at > @request_file_updated_at
			and (h.СсылкаЗаявки = @СсылкаЗаявки or @СсылкаЗаявки is null)
			and (h.GuidЗаявки = @GuidЗаявки or @GuidЗаявки is null)
			and (h.НомерЗаявки = @НомерЗаявки or @НомерЗаявки is null)
		group by
			h.GuidЗаявки,
			td.GuidТипЗагружаемойФотографии

		union

		select
			h.GuidЗаявки,
			td.GuidТипЗагружаемойФотографии,
			request_file_updated_at = max(rf.updated_at)
		from hub.Заявка as h
			inner join Stg._LK.requests as r
				on r.guid = cast(h.GuidЗаявки as varchar(36))
			inner join Stg._LK.request_file as rf
				on rf.request_id = r.Id
				and charindex('pass', rf.file_bind) > 0
			inner join hub.ТипЗагружаемойФотографии as td
				on td.file_bind = rf.file_bind
		where 1=1
			and rf.updated_at > @request_file_updated_at
			and (h.СсылкаЗаявки = @СсылкаЗаявки or @СсылкаЗаявки is null)
			and (h.GuidЗаявки = @GuidЗаявки or @GuidЗаявки is null)
			and (h.НомерЗаявки = @НомерЗаявки or @НомерЗаявки is null)
		group by
			h.GuidЗаявки,
			td.GuidТипЗагружаемойФотографии
	) as t


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_Заявка_ТипЗагружаемойФотографии
		SELECT * INTO ##t_Заявка_ТипЗагружаемойФотографии FROM #t_Заявка_ТипЗагружаемойФотографии
		--test
		--RETURN 0
	END


	if OBJECT_ID('link.Заявка_ТипЗагружаемойФотографии') is null
	begin
		select top(0)
			GuidLink_Заявка_ТипЗагружаемойФотографии,
			GuidЗаявки,
			GuidТипЗагружаемойФотографии,
			request_file_updated_at,

            created_at,
            updated_at,
            spFillName
		into link.Заявка_ТипЗагружаемойФотографии
		from #t_Заявка_ТипЗагружаемойФотографии

		alter table link.Заявка_ТипЗагружаемойФотографии
		alter column GuidLink_Заявка_ТипЗагружаемойФотографии uniqueidentifier not null

		ALTER TABLE link.Заявка_ТипЗагружаемойФотографии
		ADD CONSTRAINT PK_Link_Заявка_ТипЗагружаемойФотографии PRIMARY KEY CLUSTERED (GuidLink_Заявка_ТипЗагружаемойФотографии)

		--drop index ix_GuidЗаявки on link.Заявка_ТипЗагружаемойФотографии
		create index ix_GuidЗаявки
		on link.Заявка_ТипЗагружаемойФотографии(GuidЗаявки, GuidТипЗагружаемойФотографии)
	end

	begin tran
		if @mode = 0 begin
			delete t
			from link.Заявка_ТипЗагружаемойФотографии as t
		end

		merge link.Заявка_ТипЗагружаемойФотографии t
		using #t_Заявка_ТипЗагружаемойФотографии s
			on t.GuidLink_Заявка_ТипЗагружаемойФотографии = s.GuidLink_Заявка_ТипЗагружаемойФотографии
		when not matched then insert
		(
			GuidLink_Заявка_ТипЗагружаемойФотографии,
			GuidЗаявки,
			GuidТипЗагружаемойФотографии,
			request_file_updated_at,

			created_at,
			updated_at,
			spFillName
		) values
		(
			s.GuidLink_Заявка_ТипЗагружаемойФотографии,
			s.GuidЗаявки,
			s.GuidТипЗагружаемойФотографии,
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
			t.GuidLink_Заявка_ТипЗагружаемойФотографии = s.GuidLink_Заявка_ТипЗагружаемойФотографии,
			t.GuidЗаявки = s.GuidЗаявки,
			t.GuidТипЗагружаемойФотографии = s.GuidТипЗагружаемойФотографии,
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
