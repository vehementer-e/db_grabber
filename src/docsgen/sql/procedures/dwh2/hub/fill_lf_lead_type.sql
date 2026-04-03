--EXEC hub.fill_lf_lead_type @mode = 0
CREATE   PROC hub.fill_lf_lead_type
	@mode int = 1 -- 0 - full, 1 - increment
as
begin
	--truncate table hub.lf_lead_type
begin try
	SELECT @mode = isnull(@mode, 1)

	DECLARE @eventType nvarchar(50), @description nvarchar(1024), @message nvarchar(1024)
	declare @spName nvarchar(255)  =  ISNULL(OBJECT_SCHEMA_NAME(@@PROCID)+'.','')+OBJECT_NAME(@@PROCID)
	DECLARE @int_updated_at int = 0

	drop table if exists #t_lf_lead_type
	if OBJECT_ID ('hub.lf_lead_type') is not null
		AND @mode = 1
	begin
		SELECT 
			@int_updated_at = isnull(max(H.int_updated_at) - 1000, 0)
		from hub.lf_lead_type AS H
	end

	select distinct 
		guid_lead_type = try_cast(T.id AS uniqueidentifier),
		--
		T.code_name,
		T.name,
		--
		int_created_at = T.created_at,
		int_updated_at = T.updated_at,
		T.created_at_time,
		T.updated_at_time,
		--
		created_at = CURRENT_TIMESTAMP,
		updated_at = CURRENT_TIMESTAMP,
		spFillName = @spName
	into #t_lf_lead_type
	from Stg._lf.lead_type AS T
	where T.updated_at >= @int_updated_at
		AND try_cast(T.id  AS uniqueidentifier) IS NOT NULL

	;with cte_dublicate as  (
		select nRow = row_number() over(partition by guid_lead_type order by updated_at desc), *
		from #t_lf_lead_type
	)
	delete from cte_dublicate 
	where nRow>1

	if OBJECT_ID('hub.lf_lead_type') is null
	begin
	
		select top(0)
			guid_lead_type,
			code_name,
			name,
			int_created_at,
			int_updated_at,
			created_at_time,
			updated_at_time,
			created_at,
			updated_at,
			spFillName
		into hub.lf_lead_type
		from #t_lf_lead_type

		alter table hub.lf_lead_type
			alter column guid_lead_type uniqueidentifier not null

		ALTER TABLE hub.lf_lead_type
			ADD CONSTRAINT PK_lf_lead_type PRIMARY KEY CLUSTERED (guid_lead_type)
	end
	
	--begin tran
		merge hub.lf_lead_type t
		using #t_lf_lead_type s
			on t.guid_lead_type = s.guid_lead_type
		when not matched then insert
		(
			guid_lead_type,
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
			s.guid_lead_type,
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
