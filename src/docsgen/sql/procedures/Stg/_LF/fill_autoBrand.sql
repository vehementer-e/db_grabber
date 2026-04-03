

-- Usage: запуск процедуры с параметрами
-- EXEC [_LF].[fill_autoBrand] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE procedure [_LF].[fill_autoBrand]
	@autoBrands _lf.[utt_autoBrand] readonly 
	,@debug bit = 0
as
begin try
declare @startTime datetime = getdate()
	,@updateRows int
	, @insertedRows int
	, @procName nvarchar(255) = concat(
		SCHEMA_NAME(@@PROCID), '.' , OBJECT_NAME(@@PROCID))

	begin tran
		merge [_lf].auto_brands t
	using 
	(
		select 
			[id]
			, [name]
			, [active]
			, [sort]
			, [created_at]
			, [updated_at]
			--, created_at_time = DATEADD(s, s.created_at, '1970-01-01')
			--, updated_at_time = DATEADD(s, isnull(s.updated_at, s.created_at), '1970-01-01')
			, [UPDATED_BY]			= @procName
			, [UPDATED_DT]			= getdate()
		from @autoBrands s
	) s on s.id =t.Id
	when not matched then insert
	(
		  [id]
		, [name]
		, [active]
		, [sort]
		, [created_at]
		, [updated_at]
		, [UPDATED_BY]
		, [UPDATED_DT]
	)
	values
	(
		  s.[id]
		, s.[name]
		, s.[active]
		, s.[sort]
		, s.[created_at]
		, s.[updated_at]
		--, s.[created_at_time]
		--, s.[updated_at_time]
		, [UPDATED_BY]
		, [UPDATED_DT]
	)
	when matched and s.[updated_at]>t.[updated_at]
		then update set
		 t.[name]				= s.[name]
		, t.[active]			= s.[active]
		, t.[sort]				= s.[sort]
		, t.[updated_at]		= s.[updated_at]
		--, t.[created_at_time]	= s.[created_at_time]
		--, t.[updated_at_time]	= s.[updated_at_time]
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
