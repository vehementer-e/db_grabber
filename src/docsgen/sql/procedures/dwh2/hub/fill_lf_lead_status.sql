--EXEC hub.fill_lf_lead_status @mode = 0
CREATE   PROC hub.fill_lf_lead_status
	@mode int = 1 -- 0 - full, 1 - increment
as
begin
	--truncate table hub.lf_lead_status
begin try
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	DECLARE @int_updated_at int = 0

	drop table if exists #t_lf_lead_status
	if OBJECT_ID ('hub.lf_lead_status') is not null
		AND @mode = 1
	begin
		SELECT 
			@int_updated_at = isnull(max(H.int_updated_at) - 1000, 0)
		from hub.lf_lead_status AS H
	end

	select distinct 
		guid_lead_status = try_cast(T.id AS uniqueidentifier),
		--
		T.technical_name,
		T.technical_description,
		T.marketing_name,
		T.marketing_description,
		T.initiator,
		--
		int_created_at = T.created_at,
		int_updated_at = T.updated_at,
		T.created_at_time,
		T.updated_at_time,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName
	into #t_lf_lead_status
	from Stg._lf.lead_status AS T
	where T.updated_at >= @int_updated_at
		AND try_cast(T.id  AS uniqueidentifier) IS NOT NULL

	;with cte_dublicate as  (
		select nRow = row_number() over(partition by guid_lead_status order by updated_at desc), *
		from #t_lf_lead_status
	)
	delete from cte_dublicate 
	where nRow>1

	if OBJECT_ID('hub.lf_lead_status') is null
	begin
	
		select top(0)
			guid_lead_status,
			technical_name,
			technical_description,
			marketing_name,
			marketing_description,
			initiator,
			int_created_at,
			int_updated_at,
			created_at_time,
			updated_at_time,
			created_at,
			updated_at,
			spFillName
		into hub.lf_lead_status
		from #t_lf_lead_status

		alter table hub.lf_lead_status
			alter column guid_lead_status uniqueidentifier not null

		ALTER TABLE hub.lf_lead_status
			ADD CONSTRAINT PK_lf_lead_status PRIMARY KEY CLUSTERED (guid_lead_status)
	end
	
	--begin tran
		merge hub.lf_lead_status t
		using #t_lf_lead_status s
			on t.guid_lead_status = s.guid_lead_status
		when not matched then insert
		(
			guid_lead_status,
			technical_name,
			technical_description,
			marketing_name,
			marketing_description,
			initiator,
			int_created_at,
			int_updated_at,
			created_at_time,
			updated_at_time,
			created_at,
			updated_at,
			spFillName
		) values
		(
			s.guid_lead_status,
			s.technical_name,
			s.technical_description,
			s.marketing_name,
			s.marketing_description,
			s.initiator,
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
			t.technical_name = s.technical_name,
			t.technical_description = s.technical_description,
			t.marketing_name = s.marketing_name,
			t.marketing_description = s.marketing_description,
			t.initiator = s.initiator,
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
