--exec sat.fill_link_Заявка_ТипДокументаНаПодпись
create   PROC sat.fill_link_Заявка_ТипДокументаНаПодпись
	@mode int = 1,
	@СсылкаЗаявки binary(16) = null,
	@GuidЗаявки uniqueidentifier = null,
	@НомерЗаявки nvarchar(14) = null,
	@isDebug int = 0
as
begin
	--truncate table sat.link_Заявка_ТипДокументаНаПодпись
begin try
	SELECT @mode = isnull(@mode, 1)
	SELECT @isDebug = isnull(@isDebug, 0)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	--declare @rowVersion binary(8) = 0x0
	declare @request_file_updated_at datetime = '2000-01-01'
	declare @paper_created_at datetime = '2000-01-01'
	declare @pep_created_at datetime = '2000-01-01'
	declare @pep_updated_at datetime = '2000-01-01'

	if OBJECT_ID ('sat.link_Заявка_ТипДокументаНаПодпись') is not null
		and @mode = 1
		and @СсылкаЗаявки is null
		and @GuidЗаявки is null
		and @НомерЗаявки is null
	begin
		select 
			@request_file_updated_at = isnull(dateadd(day, -10, max(s.request_file_updated_at)), '2000-01-01'),
			@paper_created_at = isnull(dateadd(day, -10, max(s.paper_created_at)), '2000-01-01'),
			@pep_created_at = isnull(dateadd(day, -10, max(s.pep_created_at)), '2000-01-01'),
			@pep_updated_at = isnull(dateadd(day, -10, max(s.pep_updated_at)), '2000-01-01')
		from sat.link_Заявка_ТипДокументаНаПодпись as s
	end

	--1
	--список договоров, у которых появились/обновились документы, подписанные на бумаге
	drop table if exists #t_Заявка_paper
	create table #t_Заявка_paper
	(
		СсылкаЗаявки binary(16),
		GuidЗаявки uniqueidentifier,
		НомерЗаявки nvarchar(14)
	)

	insert #t_Заявка_paper
	(
		СсылкаЗаявки,
		GuidЗаявки,
		НомерЗаявки
	)
	select distinct
		h.СсылкаЗаявки,
		h.GuidЗаявки,
		h.НомерЗаявки
	FROM link.Заявка_ТипДокументаНаПодпись as link
		inner join hub.Заявка as h
			on h.GuidЗаявки = link.GuidЗаявки
		inner join Stg._LK.requests as r
			on r.guid = link.GuidЗаявки
		inner join Stg._LK.request_file as rf
			on rf.request_id = r.Id
			and charindex('doc_pack', rf.file_bind) > 0
		inner join Stg._LK.[file] as f 
			on f.id = rf.file_id
			and f.form_type_guid = cast(link.GuidТипДокументаНаПодпись as varchar(36))
		inner join Stg._LK.paper_sign_log as p
			on p.document_guid = f.guid
	where 1=1
		and (
			--1 появились/обновились записи в link
			link.request_file_updated_at > @request_file_updated_at
			--2 появились/обновились документы, подписанные на бумаге
			or p.created_at > @paper_created_at
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
		drop table if exists ##t_Заявка_paper
		SELECT * INTO ##t_Заявка_paper FROM #t_Заявка_paper
	end


	--2
	--список договоров, у которых появились/обновились документы, подписанные электронно
	drop table if exists #t_Заявка_pep
	create table #t_Заявка_pep
	(
		СсылкаЗаявки binary(16),
		GuidЗаявки uniqueidentifier,
		НомерЗаявки nvarchar(14)
	)

	insert #t_Заявка_pep
	(
		СсылкаЗаявки,
		GuidЗаявки,
		НомерЗаявки
	)
	select distinct
		h.СсылкаЗаявки,
		h.GuidЗаявки,
		h.НомерЗаявки
	FROM link.Заявка_ТипДокументаНаПодпись as link
		inner join hub.Заявка as h
			on h.GuidЗаявки = link.GuidЗаявки
		inner join Stg._LK.requests as r
			on r.guid = link.GuidЗаявки
		inner join Stg._LK.request_file as rf
			on rf.request_id = r.Id
			and charindex('doc_pack', rf.file_bind) > 0
		inner join Stg._LK.[file] as f 
			on f.id = rf.file_id
			and f.form_type_guid = cast(link.GuidТипДокументаНаПодпись as varchar(36))
		inner join Stg._LK.pep_activity_log as p
			on p.document_guid = f.guid
			--and cast(p.package_doc as varchar(5)) = substring(rf.file_bind, 10, 5) --replace(rf.file_bind, 'doc_pack_', '')
	where 1=1
		and (
			--1 появились/обновились записи в link
			link.request_file_updated_at > @request_file_updated_at
			--2 появились/обновились документы, подписанные электронно
			or p.created_at > @pep_created_at
			or p.updated_at > @pep_updated_at
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
		drop table if exists ##t_Заявка_pep
		SELECT * INTO ##t_Заявка_pep FROM #t_Заявка_pep
	end



	--список договоров
	drop table if exists #t_Заявка
	create table #t_Заявка
	(
		СсылкаЗаявки binary(16),
		GuidЗаявки uniqueidentifier,
		НомерЗаявки nvarchar(14)
	)

	insert #t_Заявка(СсылкаЗаявки, GuidЗаявки, НомерЗаявки)
	select distinct t.СсылкаЗаявки, t.GuidЗаявки, t.НомерЗаявки
	FROM #t_Заявка_paper as t
	union
	select distinct t.СсылкаЗаявки, t.GuidЗаявки, t.НомерЗаявки
	FROM #t_Заявка_pep as t

	if @isDebug = 1
	begin
		drop table if exists ##t_Заявка
		SELECT * INTO ##t_Заявка FROM #t_Заявка
	end

	--подписи на бумаге по всем документам для заявок из #t_Заявка
	drop table if exists #t_sat_link_paper

	select distinct --top 10 
		link.GuidLink_Заявка_ТипДокументаНаПодпись,
		--
		t.СсылкаЗаявки,
		t.GuidЗаявки,
		t.НомерЗаявки,
		--
		rf.file_bind,
		p.document_guid,
		rf.file_id,
		sign_id = p.id,
		--
		paper_num_pack = p.num_pack,
		paper_sign_date = p.sign_date,
		paper_partner_user_id_sign = p.partner_user_id_sign,
		paper_created_at = p.created_at,
		--
		link.request_file_updated_at
		--
		--created_at							= CURRENT_TIMESTAMP,
		--updated_at							= CURRENT_TIMESTAMP,
		--spFillName							= @spName
	into #t_sat_link_paper
	FROM #t_Заявка as t
		inner join link.Заявка_ТипДокументаНаПодпись as link
			on link.GuidЗаявки = t.GuidЗаявки
		inner join Stg._LK.requests as r
			--on r.guid = link.GuidЗаявки
			on r.guid = cast(link.GuidЗаявки as varchar(36))
		inner join Stg._LK.request_file as rf
			on rf.request_id = r.Id
			and charindex('doc_pack', rf.file_bind) > 0
		inner join Stg._LK.[file] as f
			on f.id = rf.file_id
			and f.form_type_guid = cast(link.GuidТипДокументаНаПодпись as varchar(36))
		inner join Stg._LK.paper_sign_log as p
			on p.document_guid = f.guid
			and cast(p.num_pack as varchar(5)) = substring(rf.file_bind, 10, 5) --replace(rf.file_bind, 'doc_pack_', '')


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_sat_link_paper
		SELECT * INTO ##t_sat_link_paper FROM #t_sat_link_paper
		--RETURN 0
	END


	--электронные подписи по всем документам для заявок из #t_Заявка
	drop table if exists #t_sat_link_pep

	select distinct --top 10 
		link.GuidLink_Заявка_ТипДокументаНаПодпись,
		--
		t.СсылкаЗаявки,
		t.GuidЗаявки,
		t.НомерЗаявки,
		--
		rf.file_bind,
		p.document_guid,
		rf.file_id,
		sign_id = p.id,
		--
		pep_package_doc = p.package_doc,
		pep_client_id = p.client_id,
		pep_login = p.login,
		pep_last_name = p.last_name,
		pep_first_name = p.first_name,
		pep_patronymic = p.patronymic,
		pep_phone = p.phone,
		pep_passport_serial = p.passport_serial,
		pep_passport_number = p.passport_number,
		pep_passport_issued_by = p.passport_issued_by,
		pep_passport_issue_date = p.passport_issue_date,
		pep_registration_address = p.registration_address,
		pep_document_name = p.document_name,
		pep_document_status = p.document_status,
		pep_document_guid = p.document_guid,
		pep_document_url = p.document_url,
		pep_type_is = p.type_is,
		pep_user_agent = p.user_agent,
		pep_os = p.os,
		pep_sms_code = p.sms_code,
		pep_sms_send = p.sms_send,
		pep_sms_send_date = p.sms_send_date,
		pep_sms_id = p.sms_id,
		pep_sms_delivery_status = p.sms_delivery_status,
		pep_sms_delivery_date = p.sms_delivery_date,
		pep_sms_input = p.sms_input,
		pep_sms_input_date = p.sms_input_date,
		pep_updated_at = p.updated_at,
		pep_created_at = p.created_at,
		pep_source_sign = p.source_sign,
		pep_sub_package = p.sub_package,
		--
		link.request_file_updated_at
		--
		--created_at							= CURRENT_TIMESTAMP,
		--updated_at							= CURRENT_TIMESTAMP,
		--spFillName							= @spName
	into #t_sat_link_pep
	FROM #t_Заявка as t
		inner join link.Заявка_ТипДокументаНаПодпись as link
			on link.GuidЗаявки = t.GuidЗаявки
		inner join Stg._LK.requests as r
			--on r.guid = link.GuidЗаявки
			on r.guid = cast(link.GuidЗаявки as varchar(36))
		inner join Stg._LK.request_file as rf
			on rf.request_id = r.Id
			and charindex('doc_pack', rf.file_bind) > 0
		inner join Stg._LK.[file] as f
			on f.id = rf.file_id
			and f.form_type_guid = cast(link.GuidТипДокументаНаПодпись as varchar(36))
		inner join Stg._LK.pep_activity_log as p
			on p.document_guid = f.guid
			and cast(p.package_doc as varchar(5)) = substring(rf.file_bind, 10, 5) --replace(rf.file_bind, 'doc_pack_', '')


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_sat_link_pep
		SELECT * INTO ##t_sat_link_pep FROM #t_sat_link_pep
		--RETURN 0
	END


	drop table if exists #t_sat_link_Заявка_ТипДокументаНаПодпись

	select --top 10 
		t.GuidLink_Заявка_ТипДокументаНаПодпись,
		--
		t.СсылкаЗаявки,
		t.GuidЗаявки,
		t.НомерЗаявки,
		--
		t.file_bind,
		t.document_guid,
		t.file_id,
		t.sign_id,
		--
		t.paper_num_pack,
		t.paper_sign_date,
		t.paper_partner_user_id_sign,
		t.paper_created_at,
		--
		pep_package_doc = null,
		pep_client_id = null,
		pep_login = null,
		pep_last_name = null,
		pep_first_name = null,
		pep_patronymic = null,
		pep_phone = null,
		pep_passport_serial = null,
		pep_passport_number = null,
		pep_passport_issued_by = null,
		pep_passport_issue_date = null,
		pep_registration_address = null,
		pep_document_name = null,
		pep_document_status = null,
		pep_document_guid = null,
		pep_document_url = null,
		pep_type_is = null,
		pep_user_agent = null,
		pep_os = null,
		pep_sms_code = null,
		pep_sms_send = null,
		pep_sms_send_date = null,
		pep_sms_id = null,
		pep_sms_delivery_status = null,
		pep_sms_delivery_date = null,
		pep_sms_input = null,
		pep_sms_input_date = null,
		pep_updated_at = null,
		pep_created_at = null,
		pep_source_sign = null,
		pep_sub_package = null,
		--
		t.request_file_updated_at,
		--
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	into #t_sat_link_Заявка_ТипДокументаНаПодпись
	FROM #t_sat_link_paper as t
	union all
	select --top 10 
		t.GuidLink_Заявка_ТипДокументаНаПодпись,
		--
		t.СсылкаЗаявки,
		t.GuidЗаявки,
		t.НомерЗаявки,
		--
		t.file_bind,
		t.document_guid,
		t.file_id,
		t.sign_id,
		--
		paper_num_pack = null,
		paper_sign_date = null,
		paper_partner_user_id_sign = null,
		paper_created_at = null,
		--
		t.pep_package_doc,
		t.pep_client_id,
		t.pep_login,
		t.pep_last_name,
		t.pep_first_name,
		t.pep_patronymic,
		t.pep_phone,
		t.pep_passport_serial,
		t.pep_passport_number,
		t.pep_passport_issued_by,
		t.pep_passport_issue_date,
		t.pep_registration_address,
		t.pep_document_name,
		t.pep_document_status,
		t.pep_document_guid,
		t.pep_document_url,
		t.pep_type_is,
		t.pep_user_agent,
		t.pep_os,
		t.pep_sms_code,
		t.pep_sms_send,
		t.pep_sms_send_date,
		t.pep_sms_id,
		t.pep_sms_delivery_status,
		t.pep_sms_delivery_date,
		t.pep_sms_input,
		t.pep_sms_input_date,
		t.pep_updated_at,
		t.pep_created_at,
		t.pep_source_sign,
		t.pep_sub_package,
		--
		t.request_file_updated_at,
		--
		created_at							= CURRENT_TIMESTAMP,
		updated_at							= CURRENT_TIMESTAMP,
		spFillName							= @spName
	FROM #t_sat_link_pep as t

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_sat_link_Заявка_ТипДокументаНаПодпись
		SELECT * INTO ##t_sat_link_Заявка_ТипДокументаНаПодпись FROM #t_sat_link_Заявка_ТипДокументаНаПодпись
		--RETURN 0
	END


	if OBJECT_ID('sat.link_Заявка_ТипДокументаНаПодпись') is null
	begin
		select top(0)
			GuidLink_Заявка_ТипДокументаНаПодпись,
			--
			--СсылкаЗаявки,
			--GuidЗаявки,
			--НомерЗаявки,
			--
			file_bind,
			document_guid,
			file_id,
			sign_id,
			--
			paper_num_pack,
			paper_sign_date,
			paper_partner_user_id_sign,
			paper_created_at,
			--
			pep_package_doc,
			pep_client_id,
			pep_login,
			pep_last_name,
			pep_first_name,
			pep_patronymic,
			pep_phone,
			pep_passport_serial,
			pep_passport_number,
			pep_passport_issued_by,
			pep_passport_issue_date,
			pep_registration_address,
			pep_document_name,
			pep_document_status,
			pep_document_guid,
			pep_document_url,
			pep_type_is,
			pep_user_agent,
			pep_os,
			pep_sms_code,
			pep_sms_send,
			pep_sms_send_date,
			pep_sms_id,
			pep_sms_delivery_status,
			pep_sms_delivery_date,
			pep_sms_input,
			pep_sms_input_date,
			pep_updated_at,
			pep_created_at,
			pep_source_sign,
			pep_sub_package,
			--
			request_file_updated_at,
			--
            created_at,
            updated_at,
            spFillName
		into sat.link_Заявка_ТипДокументаНаПодпись
		from #t_sat_link_Заявка_ТипДокументаНаПодпись

		alter table sat.link_Заявка_ТипДокументаНаПодпись
			alter column GuidLink_Заявка_ТипДокументаНаПодпись uniqueidentifier not null

		alter table sat.link_Заявка_ТипДокументаНаПодпись
			alter column document_guid uniqueidentifier not null
			
		alter table sat.link_Заявка_ТипДокументаНаПодпись
			alter column file_bind nvarchar(255) not null

		alter table sat.link_Заявка_ТипДокументаНаПодпись
			alter column sign_id int not null

		alter table sat.link_Заявка_ТипДокументаНаПодпись
			alter column file_id int not null

		ALTER TABLE sat.link_Заявка_ТипДокументаНаПодпись
			ADD CONSTRAINT PK_Link_Заявка_ТипДокументаНаПодпись 
			PRIMARY KEY CLUSTERED (GuidLink_Заявка_ТипДокументаНаПодпись, document_guid, file_id, sign_id)
	end

	begin tran
		if @mode = 0 begin
			delete t
			from sat.link_Заявка_ТипДокументаНаПодпись as t
		end

		--удалить/вставить все доп продукты для списка договоров
		delete s
		FROM #t_Заявка as t
			inner join link.Заявка_ТипДокументаНаПодпись as link
				on link.GuidЗаявки = t.GuidЗаявки
			inner join sat.link_Заявка_ТипДокументаНаПодпись as s
				on s.GuidLink_Заявка_ТипДокументаНаПодпись = link.GuidLink_Заявка_ТипДокументаНаПодпись

		insert sat.link_Заявка_ТипДокументаНаПодпись
		(
			GuidLink_Заявка_ТипДокументаНаПодпись,
			--
			--СсылкаЗаявки,
			--GuidЗаявки,
			--НомерЗаявки,
			--
			file_bind,
			document_guid,
			file_id,
			sign_id,
			--
			paper_num_pack,
			paper_sign_date,
			paper_partner_user_id_sign,
			paper_created_at,
			--
			pep_package_doc,
			pep_client_id,
			pep_login,
			pep_last_name,
			pep_first_name,
			pep_patronymic,
			pep_phone,
			pep_passport_serial,
			pep_passport_number,
			pep_passport_issued_by,
			pep_passport_issue_date,
			pep_registration_address,
			pep_document_name,
			pep_document_status,
			pep_document_guid,
			pep_document_url,
			pep_type_is,
			pep_user_agent,
			pep_os,
			pep_sms_code,
			pep_sms_send,
			pep_sms_send_date,
			pep_sms_id,
			pep_sms_delivery_status,
			pep_sms_delivery_date,
			pep_sms_input,
			pep_sms_input_date,
			pep_updated_at,
			pep_created_at,
			pep_source_sign,
			pep_sub_package,
			request_file_updated_at,
			--
            created_at,
            updated_at,
            spFillName
		)
		select 
			GuidLink_Заявка_ТипДокументаНаПодпись,
			--
			--СсылкаЗаявки,
			--GuidЗаявки,
			--НомерЗаявки,
			--
			file_bind,
			document_guid,
			file_id,
			sign_id,
			--
			paper_num_pack,
			paper_sign_date,
			paper_partner_user_id_sign,
			paper_created_at,
			--
			pep_package_doc,
			pep_client_id,
			pep_login,
			pep_last_name,
			pep_first_name,
			pep_patronymic,
			pep_phone,
			pep_passport_serial,
			pep_passport_number,
			pep_passport_issued_by,
			pep_passport_issue_date,
			pep_registration_address,
			pep_document_name,
			pep_document_status,
			pep_document_guid,
			pep_document_url,
			pep_type_is,
			pep_user_agent,
			pep_os,
			pep_sms_code,
			pep_sms_send,
			pep_sms_send_date,
			pep_sms_id,
			pep_sms_delivery_status,
			pep_sms_delivery_date,
			pep_sms_input,
			pep_sms_input_date,
			pep_updated_at,
			pep_created_at,
			pep_source_sign,
			pep_sub_package,
			--
			request_file_updated_at,
			--
            created_at,
            updated_at,
            spFillName
		from #t_sat_link_Заявка_ТипДокументаНаПодпись
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
