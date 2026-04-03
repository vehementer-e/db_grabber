

CREATE procedure [_LF].[fill_mmsChannel]
	@mmsChannels [_lf].[utt_mmsChannel] readonly 
	,@debug bit = 0
as
begin try
declare @startTime datetime = getdate()
	,@updateRows int
	, @insertedRows int
	, @procName nvarchar(255) = concat(
		SCHEMA_NAME(@@PROCID), '.' , OBJECT_NAME(@@PROCID))

	begin tran
		merge [_lf].mms_channel t
	using 
	(
		select 
			[id]
			, [name]
			, [description]
			, [mms_channel_group_id]
			, [created_at]
			, [updated_at]
			--,created_at_time = DATEADD(s, s.created_at, '1970-01-01')
			--,updated_at_time = DATEADD(s, isnull(s.updated_at, s.created_at), '1970-01-01')
			, [UPDATED_BY]			= @procName
			, [UPDATED_DT]			= getdate()
		from @mmsChannels s
	) s on s.id =t.Id
	when not matched then insert
	(
		[id]
		, [name]
		, [description]
		, [mms_channel_group_id]
		, [created_at]
		, [updated_at]
		--, [created_at_time]
		--, [updated_at_time]
		, [UPDATED_BY]	
		, [UPDATED_DT]	
	)
	values
	(
		  s.[id]
		, s.[name]
		, s.[description]
		, s.[mms_channel_group_id]
		, s.[created_at]
		, s.[updated_at]
		--, s.[created_at_time]
		--, s.[updated_at_time]
		, s.[UPDATED_BY]	
		, s.[UPDATED_DT]	
	)
	when matched and s.[updated_at]>t.[updated_at]
		then update set
		 t.[name]				= s.[name]
		, t.[description]		= s.[description]
		, t.[mms_channel_group_id]	= s.[mms_channel_group_id]
		, t.[updated_at]		= s.[updated_at]
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
