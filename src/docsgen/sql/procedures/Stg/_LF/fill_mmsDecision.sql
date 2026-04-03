


CREATE procedure [_LF].[fill_mmsDecision]
	@mmsDecisions [_lf].[utt_mmsDecision] readonly 
	,@debug bit = 0
as
begin try
declare @startTime datetime = getdate()
	,@updateRows int
	, @insertedRows int
	, @procName nvarchar(255) = concat(
		SCHEMA_NAME(@@PROCID), '.' , OBJECT_NAME(@@PROCID))
	declare @UPDATED_BY nvarchar(255) =@procName
		,@UPDATED_DT datetime = getdate()
	begin tran
	
		update t
			set t.[lead_id]				= s.[lead_id]
			, t.[mms_decision_type_id]	= s.[mms_decision_type_id]
			, t.[updated_at]			= s.[updated_at]
			, t.[UPDATED_BY]			= @UPDATED_BY
			, t.[UPDATED_DT]			= @UPDATED_DT
		 from @mmsDecisions s
		 inner join  [_lf].mms_decision t
			on s.id = t.id
			and s.updated_at>=t.updated_at
			set @updateRows =@@ROWCOUNT
		insert into  [_lf].mms_decision
			([id]
			, [lead_id]
			, [mms_decision_type_id]
			, [created_at]
			, [updated_at]
			, [UPDATED_BY]		
			, [UPDATED_DT]	
			)
		select 
			  s.[id]
			, s.[lead_id]
			, s.[mms_decision_type_id]
			, s.[created_at]
			, s.[updated_at]
			, [UPDATED_BY]		= @UPDATED_BY
			, [UPDATED_DT]		= @UPDATED_DT
		from @mmsDecisions s
		left join [_lf].mms_decision t 
			on t.id = s.id
		where t.id is null
		set @insertedRows =@@ROWCOUNT
	
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
