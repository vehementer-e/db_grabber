
-- Usage: запуск процедуры с параметрами
-- EXEC [_LF].[fill_product_type]
--      @productTypes = <value>,
--      @debug = 0;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   procedure [_LF].[fill_product_type]
	@productTypes [_lf].utt_productType readonly
	,@debug bit = 0
as
begin try
declare @startTime datetime = getdate()
	,@updateRows int
	, @insertedRows int
	, @procName nvarchar(255) = concat(
		SCHEMA_NAME(@@PROCID), '.' , OBJECT_NAME(@@PROCID))

	begin tran
		
		merge [_lf].product_type t
		using
		(
			select
				 [id]
				, [code]
				, [name]
				, [is_need_pts]
				, [min_sum]
				, [max_sum]
				, [created_at]
				, [updated_at]
				, [UPDATED_BY]			= @procName
				, [UPDATED_DT]			= getdate()
				--, created_at_time = DATEADD(s, s.created_at, '1970-01-01')
				--, updated_at_time = DATEADD(s, isnull(s.updated_at, s.created_at), '1970-01-01')
			from @productTypes s
		)s 
		on s.Id = t.Id
		when not matched then insert
		(
			[id]
			, [code]
			, [name]
			, [is_need_pts]
			, [min_sum]
			, [max_sum]
			, [created_at]
			, [updated_at]
			, [UPDATED_BY]		
			, [UPDATED_DT]		
			--, [created_at_time]
			--, [updated_at_time]
		)
		values
		(
			  [id]
			, [code]
			, [name]
			, [is_need_pts]
			, [min_sum]
			, [max_sum]
			, [created_at]
			, [updated_at]
			, [UPDATED_BY]		
			, [UPDATED_DT]		
			--, [created_at_time]
			--, [updated_at_time]
		)
		when matched and s.[updated_at] >t.[updated_at]
		then update set

			  t.[code]				= s.[code]				 
			, t.[name]				= s.[name]				 
			, t.[is_need_pts]		= s.[is_need_pts]		 
			, t.[min_sum]			= s.[min_sum]			 
			, t.[max_sum]			= s.[max_sum]			 
			, t.[created_at]		= s.[created_at]
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
