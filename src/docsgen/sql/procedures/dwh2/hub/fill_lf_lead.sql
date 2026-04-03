--hub.fill_lf_lead @Guids = '0EEEFF90-D4E5-4830-95FD-1FC56FBD550C'
CREATE PROC hub.fill_lf_lead
	@mode int = 1 -- 0 - full, 1 - increment
	,@Guids nvarchar(max) = null -- список id ЗАЯВОК для загрузки (!! не id lead !!)
	,@isDebug int = 0
as
begin
	--truncate table hub.lf_lead
	SELECT @isDebug = isnull(@isDebug, 0)
	set @Guids = nullif(@Guids, '')
begin TRY
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	DECLARE @int_updated_at int = 0
	--declare @rowVersion binary(8) = 0x0
	--DECLARE @ВерсияДанных_CRM binary(8) = 0x0, @int_updated_at_LK datetime = '2000-01-01', @RowVersion_FEDOR binary(8) = 0x0

	if OBJECT_ID ('hub.lf_lead') is not NULL
		AND @mode = 1
	begin
		SELECT 
			@int_updated_at = isnull(max(H.int_updated_at) - 300000, 0) --175800 обновление за 2д
		from hub.lf_lead AS H
	END

	-- список id заявок для загрузки
	drop table if exists #t_lf_lead_id_0
	CREATE TABLE #t_lf_lead_id_0(guid_lead nvarchar(36))

	drop table if exists #t_lf_lead_id
	CREATE TABLE #t_lf_lead_id(guid_lead nvarchar(36))

	IF @Guids is NOT NULL BEGIN
		INSERT #t_lf_lead_id_0(guid_lead)
		SELECT guid_lead = R.marketing_lead_id
		from Stg._LF.request AS R
		where R.id in (select trim(value) from string_split(@Guids, ','))

		INSERT #t_lf_lead_id_0(guid_lead)
		SELECT guid_lead = R.original_lead_id
		from Stg._LF.request AS R
		where R.id in (select trim(value) from string_split(@Guids, ','))
	END
	ELSE BEGIN
		INSERT #t_lf_lead_id_0(guid_lead)
		SELECT guid_lead = L.id
		from Stg._LF.request AS R
			INNER JOIN Stg._lf.lead AS L (nolock)
				ON R.marketing_lead_id = L.id
		where L.updated_at >= @int_updated_at

		INSERT #t_lf_lead_id_0(guid_lead)
		SELECT guid_lead = L.id
		from Stg._LF.request AS R
			INNER JOIN Stg._lf.lead AS L (nolock)
				ON R.original_lead_id = L.id
		where L.updated_at >= @int_updated_at

		--добавить лиды, которых нет в hub.lf_lead
		INSERT #t_lf_lead_id_0(guid_lead)
		SELECT guid_lead = guid_marketing_lead FROM link.lf_request_marketing_lead
		EXCEPT
		SELECT guid_lead from hub.lf_lead

		INSERT #t_lf_lead_id_0(guid_lead)
		--UNION
		SELECT guid_lead = guid_original_lead FROM link.lf_request_original_lead
		EXCEPT
		SELECT guid_lead from hub.lf_lead
	END

	CREATE INDEX ix_guid_lead ON #t_lf_lead_id_0(guid_lead)

	INSERT #t_lf_lead_id(guid_lead)
	SELECT DISTINCT I.guid_lead
	FROM #t_lf_lead_id_0 AS I
	WHERE try_cast(I.guid_lead  AS uniqueidentifier) IS NOT NULL

	CREATE UNIQUE INDEX ix_guid_lead ON #t_lf_lead_id(guid_lead)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_lf_lead_id
		SELECT * INTO ##t_lf_lead_id FROM #t_lf_lead_id AS T
	END



	drop table if exists #t_lf_lead

	select --distinct 
		guid_lead = L.id
		--,L.source_id
		--,L.entrypoint_id
		--,L.status_id
		,L.name
		,L.phone
		,L.partner_name
		,L.partner_id
		,L.phone_additional
		,L.required_sum
		,L.required_month_count
		,L.comment
		,L.city
		,L.with_manager_taxi
		----,L.filial
		--,L.auto_brand_id
		--,L.auto_model_id
		,L.car_issue_year
		,L.car_cost
		,L.car_vin
		,L.clt_name_first
		,L.clt_name_last
		,L.clt_name_third
		,L.clt_pass_id
		,L.clt_birth_day
		,L.clt_email
		,L.clt_avg_income
		,L.clt_pass_city
		,L.clt_marial_state
		,L.org_name
		,L.org_job
		,L.lead_id
		,L.creator_id
		,L.creator_name
		----,L.client_id
		--,L.visit_id
		,L.type_code
		--,L.lead_type_id
		,L.product_name
		--,L.product_type_id
		--,L.region_id
		----,L.fias_code
		--,L.mms_channel_id
		--,L.mms_channel_group_id
		--,L.mms_decline_reason_id
		,L.mms_priority
		,L.has_marketing_reason
		--
		,int_created_at = L.created_at
		,int_updated_at = L.updated_at
		,L.created_at_time
		,L.updated_at_time
		,L.publishTime
		,L.publishDateTime
		--
		,created_at = CURRENT_TIMESTAMP
		,updated_at = CURRENT_TIMESTAMP
		,spFillName = @spName

		,Link_Guid_source = try_cast(nullif(L.source_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_entrypoint = try_cast(nullif(L.entrypoint_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_status = try_cast(nullif(L.status_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_filial = try_cast(nullif(L.filial, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_auto_brands = try_cast(nullif(L.auto_brand_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_auto_models = try_cast(nullif(L.auto_model_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_client = try_cast(nullif(L.client_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_visit = try_cast(nullif(L.visit_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_lead_type = try_cast(nullif(L.lead_type_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_product_type = try_cast(nullif(L.product_type_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_region = try_cast(nullif(L.region_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_fias_code = try_cast(nullif(L.fias_code, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_mms_channel = try_cast(nullif(L.mms_channel_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_mms_channel_group = try_cast(nullif(L.mms_channel_group_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_mms_decline_reason = try_cast(nullif(L.mms_decline_reason_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)

	into #t_lf_lead
	from #t_lf_lead_id AS I
		INNER JOIN Stg._lf.lead AS L (nolock)
			ON I.guid_lead = L.id

	CREATE INDEX ix1 ON #t_lf_lead(guid_lead)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_lf_lead
		SELECT * INTO ##t_lf_lead FROM #t_lf_lead AS T
		--RETURN 0
	END

	--deduplicate
	;with cte_d as  (
		select nRow =  Row_Number() over(partition by guid_lead order by updated_at desc), *
		from #t_lf_lead
	)
	delete from cte_d
	where nRow>1

	if OBJECT_ID('link.lf_lead_stage') is null
	begin
		create table link.lf_lead_stage(
			Id					uniqueidentifier not null primary KEY CLUSTERED default newid(),
			guid_lead			uniqueidentifier not null,
			updated_at_time		datetime,
			LinkName			nvarchar(255),
			LinkGuid			uniqueidentifier,
			TargetColName		nvarchar(255),
			created_at			datetime not null default getdate()
		)
		create index ix_LinkName on link.lf_lead_stage(LinkName)

		--ALTER TABLE link.lf_lead_stage
		--ADD CONSTRAINT PK_lf_lead_stage
		--PRIMARY KEY CLUSTERED (Id)
	END
    
	--линки из lf_lead
	insert into link.lf_lead_stage(
		guid_lead
		,updated_at_time
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		guid_lead,
		updated_at_time,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_lf_lead
	CROSS APPLY (
    VALUES 
          (Link_Guid_source, 'link.lf_lead_source_account', 'guid_source_account')
          ,(Link_Guid_entrypoint, 'link.lf_lead_entrypoint', 'guid_entrypoint')
          ,(Link_Guid_status, 'link.lf_lead_lead_status', 'guid_lead_status')
          ,(Link_Guid_filial, 'link.lf_lead_filial', 'guid_filial')
          ,(Link_Guid_auto_brands, 'link.lf_lead_auto_brands', 'guid_auto_brands')

          ,(Link_Guid_auto_models, 'link.lf_lead_auto_models', 'guid_auto_models')
          ,(Link_Guid_client, 'link.lf_lead_client', 'guid_client')
          ,(Link_Guid_visit, 'link.lf_lead_referral_visit', 'guid_referral_visit')
          ,(Link_Guid_lead_type, 'link.lf_lead_lead_type', 'guid_lead_type')
          ,(Link_Guid_product_type, 'link.lf_lead_product_type', 'guid_product_type')

          ,(Link_Guid_region, 'link.lf_lead_region', 'guid_region')
          ,(Link_Guid_fias_code, 'link.lf_lead_fias_code', 'guid_fias_code')
          ,(Link_Guid_mms_channel, 'link.lf_lead_mms_channel', 'guid_mms_channel')
          ,(Link_Guid_mms_channel_group, 'link.lf_lead_mms_channel_group', 'guid_mms_channel_group')
          ,(Link_Guid_mms_decline_reason, 'link.lf_lead_mms_decline_reason', 'guid_mms_decline_reason')

		) t(LinkGuid, LinkName, TargetColName)
		where LinkGuid is not null

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##t_lf_request_stage
		SELECT * INTO ##t_lf_request_stage FROM link.lf_lead_stage
	END

	--заполнение таблиц с линками
	BEGIN TRY
		--последовательный запуск
		EXEC link.exec_fill_link_between_lf_lead_and_other

		--параллельный запуск
		--EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_lf_lead_and_other'
	END TRY
	BEGIN CATCH
		--??
	END CATCH


	--drop table hub.lf_lead
	if OBJECT_ID('hub.lf_lead') is null
	begin
	
		select top(0)
			--СсылкаЗаявки,
			--НомерЗаявки,
			--GuidЗаявки,
			guid_lead,
			name,
			phone,
			partner_name,
			partner_id,
			phone_additional,
			required_sum,
			required_month_count,
			comment,
			city,
			with_manager_taxi,
			car_issue_year,
			car_cost,
			car_vin,
			clt_name_first,
			clt_name_last,
			clt_name_third,
			clt_pass_id,
			clt_birth_day,
			clt_email,
			clt_avg_income,
			clt_pass_city,
			clt_marial_state,
			org_name,
			org_job,
			lead_id,
			creator_id,
			creator_name,
			type_code,
			product_name,
			mms_priority,
			has_marketing_reason,
			int_created_at,
			int_updated_at,
			created_at_time,
			updated_at_time,
			publishTime,
			publishDateTime,
			created_at,
			updated_at,
			spFillName
		into hub.lf_lead
		from #t_lf_lead

		--alter table hub.lf_lead
		--	alter column СсылкаЗаявки binary(16) not null

		--alter table  hub.lf_lead
		--	alter column НомерЗаявки nvarchar(14) not null

		--alter table hub.lf_lead
		--	alter column GuidЗаявки uniqueidentifier not null

		alter table hub.lf_lead
			alter column guid_lead uniqueidentifier not null
		
		ALTER TABLE hub.lf_lead
			ADD CONSTRAINT PK_lf_lead PRIMARY KEY CLUSTERED (guid_lead)
	end 
	
	--begin tran
		merge hub.lf_lead AS t
		using #t_lf_lead AS s
			on t.guid_lead = s.guid_lead
		when not matched then insert
		(
			--СсылкаЗаявки,
			--НомерЗаявки,
			--GuidЗаявки,
			guid_lead,
			name,
			phone,
			partner_name,
			partner_id,
			phone_additional,
			required_sum,
			required_month_count,
			comment,
			city,
			with_manager_taxi,
			car_issue_year,
			car_cost,
			car_vin,
			clt_name_first,
			clt_name_last,
			clt_name_third,
			clt_pass_id,
			clt_birth_day,
			clt_email,
			clt_avg_income,
			clt_pass_city,
			clt_marial_state,
			org_name,
			org_job,
			lead_id,
			creator_id,
			creator_name,
			type_code,
			product_name,
			mms_priority,
			has_marketing_reason,
			int_created_at,
			int_updated_at,
			created_at_time,
			updated_at_time,
			publishTime,
			publishDateTime,
			created_at,
			updated_at,
			spFillName
		) values
		(
			--s.СсылкаЗаявки,
			--s.НомерЗаявки,
			--s.GuidЗаявки,
			s.guid_lead,
			s.name,
			s.phone,
			s.partner_name,
			s.partner_id,
			s.phone_additional,
			s.required_sum,
			s.required_month_count,
			s.comment,
			s.city,
			s.with_manager_taxi,
			s.car_issue_year,
			s.car_cost,
			s.car_vin,
			s.clt_name_first,
			s.clt_name_last,
			s.clt_name_third,
			s.clt_pass_id,
			s.clt_birth_day,
			s.clt_email,
			s.clt_avg_income,
			s.clt_pass_city,
			s.clt_marial_state,
			s.org_name,
			s.org_job,
			s.lead_id,
			s.creator_id,
			s.creator_name,
			s.type_code,
			s.product_name,
			s.mms_priority,
			s.has_marketing_reason,
			s.int_created_at,
			s.int_updated_at,
			s.created_at_time,
			s.updated_at_time,
			s.publishTime,
			s.publishDateTime,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched and (
				isnull(t.int_updated_at, 0) <> isnull(s.int_updated_at, 0)
				OR @mode = 0
			)
		then update SET
			--t.СсылкаЗаявки = s.СсылкаЗаявки,
			--t.НомерЗаявки = s.НомерЗаявки,
			--t.GuidЗаявки = s.GuidЗаявки,
			t.guid_lead = s.guid_lead,
			t.name = s.name,
			t.phone = s.phone,
			t.partner_name = s.partner_name,
			t.partner_id = s.partner_id,
			t.phone_additional = s.phone_additional,
			t.required_sum = s.required_sum,
			t.required_month_count = s.required_month_count,
			t.comment = s.comment,
			t.city = s.city,
			t.with_manager_taxi = s.with_manager_taxi,
			t.car_issue_year = s.car_issue_year,
			t.car_cost = s.car_cost,
			t.car_vin = s.car_vin,
			t.clt_name_first = s.clt_name_first,
			t.clt_name_last = s.clt_name_last,
			t.clt_name_third = s.clt_name_third,
			t.clt_pass_id = s.clt_pass_id,
			t.clt_birth_day = s.clt_birth_day,
			t.clt_email = s.clt_email,
			t.clt_avg_income = s.clt_avg_income,
			t.clt_pass_city = s.clt_pass_city,
			t.clt_marial_state = s.clt_marial_state,
			t.org_name = s.org_name,
			t.org_job = s.org_job,
			t.lead_id = s.lead_id,
			t.creator_id = s.creator_id,
			t.creator_name = s.creator_name,
			t.type_code = s.type_code,
			t.product_name = s.product_name,
			t.mms_priority = s.mms_priority,
			t.has_marketing_reason = s.has_marketing_reason,
			t.int_created_at = s.int_created_at,
			t.int_updated_at = s.int_updated_at,
			t.created_at_time = s.created_at_time,
			t.updated_at_time = s.updated_at_time,
			t.publishTime = s.publishTime,
			t.publishDateTime = s.publishDateTime,
			t.created_at = s.created_at,
			t.updated_at = s.updated_at,
			t.spFillName = s.spFillName
			;
	--commit tran

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