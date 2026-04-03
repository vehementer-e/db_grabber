--exec sat.fill_link_Заявка_ТипЗагружаемойФотографии
CREATE PROC sat.fill_link_Заявка_ТипЗагружаемойФотографии
	@mode int = 1,
	@СсылкаЗаявки binary(16) = null,
	@GuidЗаявки uniqueidentifier = null,
	@НомерЗаявки nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table sat.link_Заявка_ТипЗагружаемойФотографии
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @request_file_updated_at datetime = '2000-01-01'
	declare @file_created_at datetime = '2000-01-01'
	declare @file_updated_at datetime = '2000-01-01'

	if OBJECT_ID ('sat.link_Заявка_ТипЗагружаемойФотографии') is not null
		and @mode = 1
		and @СсылкаЗаявки is null
		and @GuidЗаявки is null
		and @НомерЗаявки is null
	begin
		select 
			@request_file_updated_at = isnull(dateadd(day, -30, max(s.request_file_updated_at)), '2000-01-01'),
			@file_created_at = isnull(dateadd(day, -30, max(s.file_created_at)), '2000-01-01'),
			@file_updated_at = isnull(dateadd(day, -30, max(s.file_updated_at)), '2000-01-01')
		from sat.link_Заявка_ТипЗагружаемойФотографии as s
	end

	--список договоров, у которых появились/обновились файлы
	drop table if exists #t_Заявка
	create table #t_Заявка
	(
		СсылкаЗаявки binary(16),
		GuidЗаявки uniqueidentifier,
		НомерЗаявки nvarchar(14)
	)

	insert #t_Заявка(
		СсылкаЗаявки,
		GuidЗаявки,
		НомерЗаявки
	)
	select distinct
		h.СсылкаЗаявки,
		h.GuidЗаявки,
		h.НомерЗаявки
	FROM link.Заявка_ТипЗагружаемойФотографии as link
		inner join hub.Заявка as h
			on h.GuidЗаявки = link.GuidЗаявки
		inner join hub.ТипЗагружаемойФотографии as tp
			on tp.GuidТипЗагружаемойФотографии = link.GuidТипЗагружаемойФотографии
		inner join Stg._LK.requests as r
			on r.guid = cast(link.GuidЗаявки as varchar(36))
		inner join Stg._LK.request_file as rf
			on rf.request_id = r.Id
			and rf.file_bind = tp.file_bind
		inner join Stg._LK.[file] as f
			on f.id = rf.file_id
	where 1=1
		and (
			--1 появились/обновились записи в link
			link.request_file_updated_at > @request_file_updated_at
			--2 появились/обновились документы, подписанные электронно
			or f.created_at > @file_created_at
			or f.updated_at > @file_updated_at
		)
		and (h.СсылкаЗаявки = @СсылкаЗаявки or @СсылкаЗаявки is null)
		and (h.GuidЗаявки = @GuidЗаявки or @GuidЗаявки is null)
		and (h.НомерЗаявки = @НомерЗаявки or @НомерЗаявки is null)
	group by
		h.СсылкаЗаявки,
		h.GuidЗаявки,
		h.НомерЗаявки

	if @isDebug = 1
	begin
		drop table if exists ##t_Заявка
		SELECT * INTO ##t_Заявка FROM #t_Заявка
	end


	drop table if exists #t_sat_link_Заявка_ТипЗагружаемойФотографии

	select distinct --top 10 
		link.GuidLink_Заявка_ТипЗагружаемойФотографии,
		--
		t.СсылкаЗаявки,
		t.GuidЗаявки,
		t.НомерЗаявки,
		--
		file_id = f.id,
		--guid
		file_code = f.code,
		file_name = f.name,
		file_path = f.path,
		file_height = f.height,
		file_width = f.width,
		file_type = f.type,
		file_size = f.size,
		--description
		file_sim_link = f.sim_link,
		--short_link
		--active
		--sort
		--form_type_guid
		--page_count
		--
		--link.request_file_updated_at
		request_file_updated_at = rf.updated_at,
		file_created_at = f.created_at,
		file_updated_at = f.updated_at,
		--
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName,
		--
		rn = row_number() over(
			partition by link.GuidLink_Заявка_ТипЗагружаемойФотографии, f.id
			order by f.updated_at desc
		)
	into #t_sat_link_Заявка_ТипЗагружаемойФотографии
	FROM #t_Заявка as t
		inner join link.Заявка_ТипЗагружаемойФотографии as link
			on link.GuidЗаявки = t.GuidЗаявки
		inner join hub.ТипЗагружаемойФотографии as tp
			on tp.GuidТипЗагружаемойФотографии = link.GuidТипЗагружаемойФотографии
		inner join Stg._LK.requests as r
			on r.guid = cast(link.GuidЗаявки as varchar(36))
		inner join Stg._LK.request_file as rf
			on rf.request_id = r.Id
			and rf.file_bind = tp.file_bind
		inner join Stg._LK.[file] as f
			on f.id = rf.file_id

	--дедупликация
	delete t
	from #t_sat_link_Заявка_ТипЗагружаемойФотографии as t
	where t.rn <> 1

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_sat_link_Заявка_ТипЗагружаемойФотографии
		SELECT * INTO ##t_sat_link_Заявка_ТипЗагружаемойФотографии FROM #t_sat_link_Заявка_ТипЗагружаемойФотографии
		--RETURN 0
	END


	if OBJECT_ID('sat.link_Заявка_ТипЗагружаемойФотографии') is null
	begin
		select top(0)
			GuidLink_Заявка_ТипЗагружаемойФотографии,
			--
			--СсылкаЗаявки,
			--GuidЗаявки,
			--НомерЗаявки,
			--
			file_id,
			file_code,
			file_name,
			file_path,
			file_height,
			file_width,
			file_type,
			file_size,
			file_sim_link,
			--
			request_file_updated_at,
			file_created_at,
			file_updated_at,
			--
            created_at,
            updated_at,
            spFillName
		into sat.link_Заявка_ТипЗагружаемойФотографии
		from #t_sat_link_Заявка_ТипЗагружаемойФотографии

		alter table sat.link_Заявка_ТипЗагружаемойФотографии
			alter column GuidLink_Заявка_ТипЗагружаемойФотографии uniqueidentifier not null

		alter table sat.link_Заявка_ТипЗагружаемойФотографии
			alter column file_id int not null

		ALTER TABLE sat.link_Заявка_ТипЗагружаемойФотографии
			ADD CONSTRAINT PK_Link_Заявка_ТипЗагружаемойФотографии 
			PRIMARY KEY CLUSTERED (GuidLink_Заявка_ТипЗагружаемойФотографии, file_id)
	end

	begin tran
		if @mode = 0 begin
			delete t
			from sat.link_Заявка_ТипЗагружаемойФотографии as t
		end

		--удалить/вставить все доп продукты для списка договоров
		delete s
		FROM #t_Заявка as t
			inner join link.Заявка_ТипЗагружаемойФотографии as link
				on link.GuidЗаявки = t.GuidЗаявки
			inner join sat.link_Заявка_ТипЗагружаемойФотографии as s
				on s.GuidLink_Заявка_ТипЗагружаемойФотографии = link.GuidLink_Заявка_ТипЗагружаемойФотографии

		insert sat.link_Заявка_ТипЗагружаемойФотографии
		(
			GuidLink_Заявка_ТипЗагружаемойФотографии,
			--
			--СсылкаЗаявки,
			--GuidЗаявки,
			--НомерЗаявки,
			--
			file_id,
			file_code,
			file_name,
			file_path,
			file_height,
			file_width,
			file_type,
			file_size,
			file_sim_link,
			--
			request_file_updated_at,
			file_created_at,
			file_updated_at,
			--
            created_at,
            updated_at,
            spFillName
		)
		select 
			GuidLink_Заявка_ТипЗагружаемойФотографии,
			--
			--СсылкаЗаявки,
			--GuidЗаявки,
			--НомерЗаявки,
			--
			file_id,
			file_code,
			file_name,
			file_path,
			file_height,
			file_width,
			file_type,
			file_size,
			file_sim_link,
			--
			request_file_updated_at,
			file_created_at,
			file_updated_at,
			--
            created_at,
            updated_at,
            spFillName
		from #t_sat_link_Заявка_ТипЗагружаемойФотографии
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
