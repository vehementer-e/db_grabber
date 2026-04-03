

/*

CREATE type [_lf].[utt_source]as table(
	[id] [uniqueidentifier] NOT NULL,
	[name] [nvarchar](255) NULL,
	[auth_target] [nvarchar](255) NULL,
	[auth_token] [nvarchar](1024) NULL,
	[product_type_code] [nvarchar](255) NULL,
	[state] [smallint] NULL,
	[is_own] [bit] NULL,
	[created_at] [int] NULL,
	[updated_at] [int] NULL,
	[description] [nvarchar](510) NULL,
	[mms_channel_id] [uniqueidentifier] NULL
	PRIMARY KEY NONCLUSTERED 
	(
		[id] ASC
	)

) 


*/
create   procedure [_LF].[fill_source_account]
	@source_accounts  [_lf].[utt_source_account] readonly
	,@debug bit = 0 
as
begin try
declare @startTime datetime = getdate()
	,@updateRows int
	, @insertedRows int
	, @procName nvarchar(255) = concat(
		SCHEMA_NAME(@@PROCID), '.' , OBJECT_NAME(@@PROCID))
	begin tran
		merge [_lf].source_account t
		using 
		(
			select 
				  [id]
				, [name]
				, [auth_target]
				, [auth_token]
				, [product_type_code]
				, [state]
				, [is_own]
				--, created_at_time = DATEADD(s, s.created_at, '1970-01-01')
				--, updated_at_time = DATEADD(s, isnull(s.updated_at, s.created_at), '1970-01-01')
				, [created_at]
				, [updated_at]
				, [description]
				, [mms_channel_id]
				, [UPDATED_BY]			= @procName
				, [UPDATED_DT]			= getdate()

			from @source_accounts s
		)s 
		on s.Id = t.Id
		when not matched then insert
			(
				[id]
				, [name]
				, [auth_target]
				, [auth_token]
				, [product_type_code]
				, [state]
				, [is_own]
				, [created_at]
				, [updated_at]
				, [description]
				, [mms_channel_id]
				, [UPDATED_BY]		
				, [UPDATED_DT]		
			)
			values
			(
				  s.[id]
				, s.[name]
				, s.[auth_target]
				, s.[auth_token]
				, s.[product_type_code]
				, s.[state]
				, s.[is_own]
				, s.[created_at]
				, s.[updated_at]
				, s.[description]
				, s.[mms_channel_id]
				, s.[UPDATED_BY]		
				, s.[UPDATED_DT]		
			)
		when matched and s.[updated_at]>t.[updated_at]
		then update set
			  t.[name]				= s.[name]
			, t.[auth_target]		= s.[auth_target]
			, t.[auth_token]		= s.[auth_token]
			, t.[product_type_code] = s.[product_type_code]
			, t.[state]				= s.[state]
			, t.[is_own]			= s.[is_own]
			, t.[updated_at]		= s.[updated_at]
			, t.[description]		= s.[description]
			, t.[mms_channel_id]	= s.[mms_channel_id]
			, t.[UPDATED_BY]		= s.[UPDATED_BY]
			, t.[UPDATED_DT]		= s.[UPDATED_DT]
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
end catch
