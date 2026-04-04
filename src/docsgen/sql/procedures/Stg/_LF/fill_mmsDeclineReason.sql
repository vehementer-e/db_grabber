


-- Usage: запуск процедуры с параметрами
-- EXEC [_LF].[fill_mmsDeclineReason]
--      @mmsDeclineReasons = <value>,
--      @debug = 0;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE procedure [_LF].[fill_mmsDeclineReason]
	@mmsDeclineReasons [_lf].utt_mmsDeclineReason readonly 
	,@debug bit = 0
as
begin try
declare @startTime datetime = getdate()
	,@updateRows int
	, @insertedRows int
	, @procName nvarchar(255) = concat(
		SCHEMA_NAME(@@PROCID), '.' , OBJECT_NAME(@@PROCID))

	begin tran
		merge [_lf].[mms_decline_reason] t
	using 
	(
		select 
			[id]
			, [name]
			, [code_name]
			, [lead_status_id]
			, [created_at]
			, [updated_at]
			--, created_at_time = DATEADD(s, s.created_at, '1970-01-01')
			--, updated_at_time = DATEADD(s, isnull(s.updated_at, s.created_at), '1970-01-01')
			, [UPDATED_BY]			= @procName
			, [UPDATED_DT]			= getdate()
		from @mmsDeclineReasons s
	) s on s.id =try_cast(t.Id as uniqueidentifier)
	when not matched then insert
	(
		[id]
		, [name]
		, [code_name]
		, [lead_status_id]
		, [created_at]
		, [updated_at]
		, [UPDATED_BY]		
		, [UPDATED_DT]		
	)
	values
	(
		  s.[id]
		, s.[name]
		, s.[code_name]
		, s.[lead_status_id]
		, s.[created_at]
		, s.[updated_at]
		, s.[UPDATED_BY]		
		, s.[UPDATED_DT]		
	)
	when matched and s.[updated_at]>t.[updated_at]
		then update set
		 t.[name]				= s.[name]
		, t.[code_name]			= s.[code_name]
		, t.[lead_status_id]	= s.[lead_status_id]
		, t.[updated_at]		= s.[updated_at]
		, t.[UPDATED_BY]		= s.[UPDATED_BY]
		, t.[UPDATED_DT]		= s.[UPDATED_DT]
		--, t.[created_at_time]	= s.[created_at_time]
		--, t.[updated_at_time]	= s.[updated_at_time]
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
