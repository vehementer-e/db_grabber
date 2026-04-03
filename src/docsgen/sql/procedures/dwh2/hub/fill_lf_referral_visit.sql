--EXEC hub.fill_lf_referral_visit @mode = 0
CREATE   PROC hub.fill_lf_referral_visit
	@mode int = 1 -- 0 - full, 1 - increment
as
begin
	--truncate table hub.lf_referral_visit
begin try
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	DECLARE @int_updated_at int = 0

	drop table if exists #t_lf_referral_visit
	if OBJECT_ID ('hub.lf_referral_visit') is not NULL
		AND @mode = 1
	begin
		SELECT 
			@int_updated_at = isnull(max(H.int_updated_at) - 1000, 0)
		from hub.lf_referral_visit AS H
	end

	DROP TABLE IF EXISTS #t_referral_visit_id_0
	CREATE TABLE #t_referral_visit_id_0(id nvarchar(36))
	
	INSERT #t_referral_visit_id_0(id)
	SELECT T.id
	from Stg._lf.referral_visit AS T
		INNER JOIN dwh2.link.lf_lead_referral_visit AS L
			ON L.guid_referral_visit = try_cast(T.id AS uniqueidentifier)
	where T.updated_at >= @int_updated_at
		AND try_cast(T.id  AS uniqueidentifier) IS NOT NULL

	INSERT #t_referral_visit_id_0(id)
	SELECT id = guid_referral_visit FROM link.lf_lead_referral_visit
	EXCEPT
	SELECT id = guid_referral_visit FROM hub.lf_referral_visit

	CREATE INDEX ix_id ON #t_referral_visit_id_0(id)

	DROP TABLE IF EXISTS #t_referral_visit_id
	CREATE TABLE #t_referral_visit_id(id nvarchar(36))

	INSERT #t_referral_visit_id(id)
	SELECT DISTINCT id FROM #t_referral_visit_id_0

	CREATE INDEX ix_id ON #t_referral_visit_id(id)


	select distinct 
		guid_referral_visit = try_cast(T.id AS uniqueidentifier),

		--T.source_id, --link
		T.client_yandex_id,
		T.client_google_id,
		T.click_yandex_id,
		T.click_google_id,
		T.stat_system,
		T.stat_source,
		T.stat_type,
		T.stat_campaign,
		T.stat_info,
		T.stat_term,
		T.referer,
		T.page,
		T.comagic_vid,
		T.ip,
		T.userAgent,
		T.language,
		T.platform,
		T.adriverPostView,
		T.jivoVid,
		T.created_type,
		--T.appmetrica_event_id, --link
		--T.client_id, --link
		--
		int_created_at = T.created_at,
		int_updated_at = T.updated_at,
		T.created_at_time,
		T.updated_at_time,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName
		,Link_Guid_source = try_cast(nullif(T.source_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_appmetrica_event = try_cast(nullif(T.appmetrica_event_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
		,Link_Guid_client = try_cast(nullif(T.client_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
	into #t_lf_referral_visit
	--from Stg._lf.referral_visit AS T
	--	INNER JOIN dwh2.link.lf_lead_referral_visit AS L
	--		ON L.guid_referral_visit = try_cast(T.id AS uniqueidentifier)
	--where T.updated_at >= @int_updated_at
	--	AND try_cast(T.id  AS uniqueidentifier) IS NOT NULL
	from Stg._lf.referral_visit AS T
		INNER JOIN #t_referral_visit_id AS A
			ON A.id = T.id


	;with cte_dublicate as  (
		select nRow = row_number() over(partition by guid_referral_visit order by updated_at desc), *
		from #t_lf_referral_visit
	)
	delete from cte_dublicate 
	where nRow>1

	if OBJECT_ID('link.lf_referral_visit_stage') is null
	BEGIN
		--DROP TABLE link.lf_referral_visit_stage
		create table link.lf_referral_visit_stage(
			Id					uniqueidentifier not NULL CONSTRAINT PK_lf_referral_visit_stage primary key default newid(),
			guid_referral_visit	uniqueidentifier not null,
			updated_at_time		datetime,
			LinkName			nvarchar(255),
			LinkGuid			uniqueidentifier,
			TargetColName		nvarchar(255),
			created_at			datetime not null default getdate()
		)
		create index ix_LinkName on link.lf_referral_visit_stage(LinkName)

		--ALTER TABLE link.lf_referral_visit_stage
		--ADD CONSTRAINT PK_lf_referral_visit_stage
		--PRIMARY KEY CLUSTERED (Id)
	END

	--линки
	insert into link.lf_referral_visit_stage(
		guid_referral_visit
		,updated_at_time
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		guid_referral_visit,
		updated_at_time,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_lf_referral_visit
	CROSS APPLY (
    VALUES 
		(Link_Guid_source, 'link.lf_referral_visit_source_account', 'guid_source_account')
		,(Link_Guid_appmetrica_event, 'link.lf_referral_visit_referral_appmetrica_event', 'guid_referral_appmetrica_event')
		,(Link_Guid_client, 'link.lf_referral_visit_client', 'guid_client')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null

	--заполнение таблиц с линками
	BEGIN TRY
		EXEC msdb.dbo.sp_start_job N'DWH2. fill_link_between_lf_referral_visit_and_other'
	END TRY
	BEGIN CATCH
		--??
	END CATCH

	if OBJECT_ID('hub.lf_referral_visit') is null
	begin
	
		select top(0)
			guid_referral_visit,
			--
			client_yandex_id,
			client_google_id,
			click_yandex_id,
			click_google_id,
			stat_system,
			stat_source,
			stat_type,
			stat_campaign,
			stat_info,
			stat_term,
			referer,
			page,
			comagic_vid,
			ip,
			userAgent,
			language,
			platform,
			adriverPostView,
			jivoVid,
			created_type,
			--
			int_created_at,
			int_updated_at,
			created_at_time,
			updated_at_time,
			created_at,
			updated_at,
			spFillName
		into hub.lf_referral_visit
		from #t_lf_referral_visit

		alter table hub.lf_referral_visit
			alter column guid_referral_visit uniqueidentifier not null

		ALTER TABLE hub.lf_referral_visit
			ADD CONSTRAINT PK_lf_referral_visit PRIMARY KEY CLUSTERED (guid_referral_visit)
	end
	
	--begin tran
		merge hub.lf_referral_visit t
		using #t_lf_referral_visit s
			on t.guid_referral_visit = s.guid_referral_visit
		when not matched then insert
		(
			guid_referral_visit,
			--
			client_yandex_id,
			client_google_id,
			click_yandex_id,
			click_google_id,
			stat_system,
			stat_source,
			stat_type,
			stat_campaign,
			stat_info,
			stat_term,
			referer,
			page,
			comagic_vid,
			ip,
			userAgent,
			language,
			platform,
			adriverPostView,
			jivoVid,
			created_type,
			--
			int_created_at,
			int_updated_at,
			created_at_time,
			updated_at_time,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.guid_referral_visit,
			--
			s.client_yandex_id,
			s.client_google_id,
			s.click_yandex_id,
			s.click_google_id,
			s.stat_system,
			s.stat_source,
			s.stat_type,
			s.stat_campaign,
			s.stat_info,
			s.stat_term,
			s.referer,
			s.page,
			s.comagic_vid,
			s.ip,
			s.userAgent,
			s.language,
			s.platform,
			s.adriverPostView,
			s.jivoVid,
			s.created_type,
			--
			s.int_created_at,
			s.int_updated_at,
			s.created_at_time,
			s.updated_at_time,
			s.created_at,
			s.updated_at,
			s.spFillName
		)
		when matched and (
				isnull(t.int_updated_at, 0) <> isnull(s.int_updated_at, 0)
				OR @mode = 0
			)
		then update SET
			t.client_yandex_id = s.client_yandex_id,
			t.client_google_id = s.client_google_id,
			t.click_yandex_id = s.click_yandex_id,
			t.click_google_id = s.click_google_id,
			t.stat_system = s.stat_system,
			t.stat_source = s.stat_source,
			t.stat_type = s.stat_type,
			t.stat_campaign = s.stat_campaign,
			t.stat_info = s.stat_info,
			t.stat_term = s.stat_term,
			t.referer = s.referer,
			t.page = s.page,
			t.comagic_vid = s.comagic_vid,
			t.ip = s.ip,
			t.userAgent = s.userAgent,
			t.language = s.language,
			t.platform = s.platform,
			t.adriverPostView = s.adriverPostView,
			t.jivoVid = s.jivoVid,
			t.created_type = s.created_type,
			--
			t.int_created_at = s.int_created_at,
			t.int_updated_at = s.int_updated_at,
			t.created_at_time = s.created_at_time,
			t.updated_at_time = s.updated_at_time,
			--t.created_at = s.created_at,
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
