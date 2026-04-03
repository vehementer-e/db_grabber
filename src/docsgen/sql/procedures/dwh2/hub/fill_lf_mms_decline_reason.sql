--drop table hub.lf_mms_decline_reason
--EXEC hub.fill_lf_mms_decline_reason @mode = 0
CREATE   PROC hub.fill_lf_mms_decline_reason
	@mode int = 1 -- 0 - full, 1 - increment
as
begin
	--truncate table hub.lf_mms_decline_reason
begin try
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	DECLARE @int_updated_at int = 0

	drop table if exists #t_lf_mms_decline_reason
	if OBJECT_ID ('hub.lf_mms_decline_reason') is not null
		AND @mode = 1
	begin
		SELECT 
			@int_updated_at = isnull(max(H.int_updated_at) - 1000, 0)
		from hub.lf_mms_decline_reason AS H
	end

	select distinct 
		guid_mms_decline_reason = try_cast(T.id AS uniqueidentifier),
		--
		T.code_name,
		T.name,
		--T.lead_status_id, -- link
		--
		int_created_at = T.created_at,
		int_updated_at = T.updated_at,
		T.created_at_time,
		T.updated_at_time,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName
		,Link_Guid_lead_status = try_cast(nullif(T.lead_status_id, '00000000-0000-0000-0000-000000000000') AS uniqueidentifier)
	into #t_lf_mms_decline_reason
	from Stg._lf.mms_decline_reason AS T
	where T.updated_at >= @int_updated_at
		AND try_cast(T.id  AS uniqueidentifier) IS NOT NULL

	;with cte_dublicate as  (
		select nRow = row_number() over(partition by guid_mms_decline_reason order by updated_at desc), *
		from #t_lf_mms_decline_reason
	)
	delete from cte_dublicate 
	where nRow>1

	if OBJECT_ID('link.lf_mms_decline_reason_stage') is null
	BEGIN
		--DROP TABLE link.lf_mms_decline_reason_stage
		create table link.lf_mms_decline_reason_stage(
			Id					uniqueidentifier not NULL CONSTRAINT PK_lf_mms_decline_reason_stage primary key default newid(),
			guid_mms_decline_reason	uniqueidentifier not null,
			updated_at_time		datetime,
			LinkName			nvarchar(255),
			LinkGuid			uniqueidentifier,
			TargetColName		nvarchar(255),
			created_at			datetime not null default getdate()
		)
		create index ix_LinkName on link.lf_mms_decline_reason_stage(LinkName)

		--ALTER TABLE link.lf_mms_decline_reason_stage
		--ADD CONSTRAINT PK_lf_mms_decline_reason_stage
		--PRIMARY KEY CLUSTERED (Id)
	END

	--линки
	insert into link.lf_mms_decline_reason_stage(
		guid_mms_decline_reason
		,updated_at_time
		,LinkName
		,LinkGuid
		,TargetColName
	)
	select distinct 
		guid_mms_decline_reason,
		updated_at_time,
		LinkName,
		LinkGuid,
		TargetColName
	from #t_lf_mms_decline_reason
	CROSS APPLY (
    VALUES 
          (Link_Guid_lead_status, 'link.lf_mms_decline_reason_lead_status', 'guid_lead_status')
		) t(LinkGuid, LinkName, TargetColName)
	where LinkGuid is not null

	EXEC link.exec_fill_link_between_lf_mms_decline_reason_and_other

	if OBJECT_ID('hub.lf_mms_decline_reason') is null
	begin
	
		select top(0)
			guid_mms_decline_reason,
			code_name,
			name,
			int_created_at,
			int_updated_at,
			created_at_time,
			updated_at_time,
			created_at,
			updated_at,
			spFillName
		into hub.lf_mms_decline_reason
		from #t_lf_mms_decline_reason

		alter table hub.lf_mms_decline_reason
			alter column guid_mms_decline_reason uniqueidentifier not null

		ALTER TABLE hub.lf_mms_decline_reason
			ADD CONSTRAINT PK_lf_mms_decline_reason PRIMARY KEY CLUSTERED (guid_mms_decline_reason)
	end
	
	--begin tran
		merge hub.lf_mms_decline_reason t
		using #t_lf_mms_decline_reason s
			on t.guid_mms_decline_reason = s.guid_mms_decline_reason
		when not matched then insert
		(
			guid_mms_decline_reason,
			code_name,
			name,
			int_created_at,
			int_updated_at,
			created_at_time,
			updated_at_time,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.guid_mms_decline_reason,
			s.code_name,
			s.name,
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
			t.code_name = s.code_name,
			t.name = s.name,
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
