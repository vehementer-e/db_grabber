
-- Usage: запуск процедуры с параметрами
-- EXEC [_LF].[fill_status]
--      @statuses = <value>,
--      @debug = 0;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE procedure [_LF].[fill_status]
	@statuses _lf.utt_status readonly
	,@debug bit = 0 
as
begin try
declare @startTime datetime = getdate()
	,@updateRows int
	, @insertedRows int
	, @procName nvarchar(255) = concat(
		SCHEMA_NAME(@@PROCID), '.' , OBJECT_NAME(@@PROCID))
	begin tran
		
		merge [_lf].lead_status t
		using
		(
			select
				[id]
				, [technical_name]
				, [technical_description]
				, [marketing_name]
				, [marketing_description]
				, [initiator]
				, [created_at]
				, [updated_at]
				, [UPDATED_BY]			= @procName
				, [UPDATED_DT]			= getdate()
			from @statuses s
		)s 
		on s.Id = t.Id
		when not matched then insert
		(
			[id]
			, [technical_name]
			, [technical_description]
			, [marketing_name]
			, [marketing_description]
			, [initiator]
			, [created_at]
			, [updated_at]
			, [UPDATED_BY]			
			, [UPDATED_DT]			
		)
		values
		(
				[id]
			, [technical_name]
			, [technical_description]
			, [marketing_name]
			, [marketing_description]
			, [initiator]
			, [created_at]
			, [updated_at]
			, [UPDATED_BY]			
			, [UPDATED_DT]			
		)
		when matched and s.[updated_at] >t.[updated_at]
		then update set
			 t.[technical_name]			= s.[technical_name]
			, t.[technical_description]	= s.[technical_description]
			, t.[marketing_name]		= s.[marketing_name]
			, t.[marketing_description]	= s.[marketing_description]
			, t.[initiator]				= s.[initiator]
			, t.[updated_at]			= s.[updated_at]
			, t.[UPDATED_BY]			= s.[UPDATED_BY]
			, t.[UPDATED_DT]			= s.[UPDATED_DT]
			;
	commit tran
	if @debug = 1
		select procName = @procName
			, duration = cast(getdate() - @startTime as time(2))
			, insertedRows = @insertedRows
			, updateRows = @updateRows
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
