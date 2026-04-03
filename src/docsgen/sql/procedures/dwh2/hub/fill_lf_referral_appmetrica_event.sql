--EXEC hub.fill_lf_referral_appmetrica_event @mode = 0
CREATE   PROC hub.fill_lf_referral_appmetrica_event
	@mode int = 1 -- 0 - full, 1 - increment
as
begin
	--truncate table hub.lf_referral_appmetrica_event
begin try
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	DECLARE @int_updated_at int = 0

	drop table if exists #t_lf_referral_appmetrica_event
	if OBJECT_ID ('hub.lf_referral_appmetrica_event') is not null
		AND @mode = 1
	begin
		SELECT 
			@int_updated_at = isnull(max(H.int_updated_at) - 1000, 0)
		from hub.lf_referral_appmetrica_event AS H
	end

	DROP TABLE IF EXISTS #t_lf_referral_appmetrica_event_id_0
	CREATE TABLE #t_lf_referral_appmetrica_event_id_0(id nvarchar(36))

	INSERT #t_lf_referral_appmetrica_event_id_0(id)
	SELECT T.id
	from Stg._lf.referral_appmetrica_event AS T
	where T.updated_at >= @int_updated_at
		AND try_cast(T.id  AS uniqueidentifier) IS NOT NULL

	INSERT #t_lf_referral_appmetrica_event_id_0(id)
	SELECT id = guid_referral_appmetrica_event FROM link.lf_referral_visit_referral_appmetrica_event
	EXCEPT
	SELECT id = guid_referral_appmetrica_event FROM hub.lf_referral_appmetrica_event

	CREATE INDEX ix_id ON #t_lf_referral_appmetrica_event_id_0(id)

	DROP TABLE IF EXISTS #t_lf_referral_appmetrica_event_id
	CREATE TABLE #t_lf_referral_appmetrica_event_id(id nvarchar(36))

	INSERT #t_lf_referral_appmetrica_event_id(id)
	SELECT DISTINCT id FROM #t_lf_referral_appmetrica_event_id_0

	CREATE INDEX ix_id ON #t_lf_referral_appmetrica_event_id(id)


	select --distinct 
		guid_referral_appmetrica_event = try_cast(T.id AS uniqueidentifier),
		--
		T.device_id,
		T.click_datetime,
		T.click_id,
		T.click_user_agent,
		T.install_datetime,
		T.app_name,
		T.app_version,
		T.device_locale,
		T.device_manufacturer,
		T.device_model,
		T.device_type,
		T.device_os_name,
		T.device_os_version,
		T.tracker_name,
		T.tracker_id,
		T.temporary_generated,
		T.publisher_name,
		--
		int_created_at = T.created_at,
		int_updated_at = T.updated_at,
		T.created_at_time,
		T.updated_at_time,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName
	into #t_lf_referral_appmetrica_event
	--from Stg._lf.referral_appmetrica_event AS T
	--where T.updated_at >= @int_updated_at
	--	AND try_cast(T.id  AS uniqueidentifier) IS NOT NULL
	from Stg._lf.referral_appmetrica_event AS T
		INNER JOIN #t_lf_referral_appmetrica_event_id AS A
			ON A.id = T.id


	;with cte_dublicate as  (
		select nRow = row_number() over(partition by guid_referral_appmetrica_event order by updated_at desc), *
		from #t_lf_referral_appmetrica_event
	)
	delete from cte_dublicate 
	where nRow>1

	if OBJECT_ID('hub.lf_referral_appmetrica_event') is null
	begin
	
		select top(0)
			guid_referral_appmetrica_event,
			--
			device_id,
			click_datetime,
			click_id,
			click_user_agent,
			install_datetime,
			app_name,
			app_version,
			device_locale,
			device_manufacturer,
			device_model,
			device_type,
			device_os_name,
			device_os_version,
			tracker_name,
			tracker_id,
			temporary_generated,
			publisher_name,
			--
			int_created_at,
			int_updated_at,
			created_at_time,
			updated_at_time,
			created_at,
			updated_at,
			spFillName
		into hub.lf_referral_appmetrica_event
		from #t_lf_referral_appmetrica_event

		alter table hub.lf_referral_appmetrica_event
			alter column guid_referral_appmetrica_event uniqueidentifier not null

		ALTER TABLE hub.lf_referral_appmetrica_event
			ADD CONSTRAINT PK_lf_referral_appmetrica_event PRIMARY KEY CLUSTERED (guid_referral_appmetrica_event)
	end
	
	--begin tran
		merge hub.lf_referral_appmetrica_event t
		using #t_lf_referral_appmetrica_event s
			on t.guid_referral_appmetrica_event = s.guid_referral_appmetrica_event
		when not matched then insert
		(
			guid_referral_appmetrica_event,
			--
			device_id,
			click_datetime,
			click_id,
			click_user_agent,
			install_datetime,
			app_name,
			app_version,
			device_locale,
			device_manufacturer,
			device_model,
			device_type,
			device_os_name,
			device_os_version,
			tracker_name,
			tracker_id,
			temporary_generated,
			publisher_name,
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
			s.guid_referral_appmetrica_event,
			--
			s.device_id,
			s.click_datetime,
			s.click_id,
			s.click_user_agent,
			s.install_datetime,
			s.app_name,
			s.app_version,
			s.device_locale,
			s.device_manufacturer,
			s.device_model,
			s.device_type,
			s.device_os_name,
			s.device_os_version,
			s.tracker_name,
			s.tracker_id,
			s.temporary_generated,
			s.publisher_name,
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
			t.device_id = s.device_id,
			t.click_datetime = s.click_datetime,
			t.click_id = s.click_id,
			t.click_user_agent = s.click_user_agent,
			t.install_datetime = s.install_datetime,
			t.app_name = s.app_name,
			t.app_version = s.app_version,
			t.device_locale = s.device_locale,
			t.device_manufacturer = s.device_manufacturer,
			t.device_model = s.device_model,
			t.device_type = s.device_type,
			t.device_os_name = s.device_os_name,
			t.device_os_version = s.device_os_version,
			t.tracker_name = s.tracker_name,
			t.tracker_id = s.tracker_id,
			t.temporary_generated = s.temporary_generated,
			t.publisher_name = s.publisher_name,
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
