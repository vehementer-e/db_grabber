-- Usage: запуск процедуры с параметрами
-- EXEC [_LF].[fill_request] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
create   procedure [_LF].[fill_request]
	@request [_lf].[utt_request] readonly
	,@debug bit = 0 
as
begin try
declare @startTime datetime = getdate()
	,@updateRows int
	, @insertedRows int
	, @procName nvarchar(255) = concat(
		SCHEMA_NAME(@@PROCID), '.' , OBJECT_NAME(@@PROCID))
	begin tran
		merge [_LF].[request] t
		using
		(
			select
				[id]
				, [original_lead_id]
				, [marketing_lead_id]
				, [number]
				, [date]
				, [requested_sum]
				, [approved_sum]
				, [sum_contract]
				, [days]
				, [status_id]
				, [status_date]
				, [product_type_id]
				, [mobile_phone]
				, [last_name]
				, [first_name]
				, [second_name]
				, [credit_product_id]
				, [source]
				, [created_at]
				, [updated_at]
				, [UPDATED_BY]			= @procName
				, [UPDATED_DT]			= getdate()
				, [publishTime]
			from @request s
		)s 
		on s.Id = t.Id
		when not matched then insert
		(
			[id]
			, [original_lead_id]
			, [marketing_lead_id]
			, [number]
			, [date]
			, [requested_sum]
			, [approved_sum]
			, [sum_contract]
			, [days]
			, [status_id]
			, [status_date]
			, [product_type_id]
			, [mobile_phone]
			, [last_name]
			, [first_name]
			, [second_name]
			, [credit_product_id]
			, [source]
			, [created_at]
			, [updated_at]
			, [UPDATED_BY]		
			, [UPDATED_DT]	
			, [publishTime]
		)
		values
		(
			[id]
			, [original_lead_id]
			, [marketing_lead_id]
			, [number]
			, [date]
			, [requested_sum]
			, [approved_sum]
			, [sum_contract]
			, [days]
			, [status_id]
			, [status_date]
			, [product_type_id]
			, [mobile_phone]
			, [last_name]
			, [first_name]
			, [second_name]
			, [credit_product_id]
			, [source]
			, [created_at]
			, [updated_at]
			, [UPDATED_BY]		
			, [UPDATED_DT]	
			, [publishTime]
		)
		when matched and s.[updated_at] >=t.[updated_at]
			and isnull(s.[publishTime],s.[updated_at])>=isnull(t.[publishTime], t.[updated_at])
		then update set
		  [original_lead_id]	= s.[original_lead_id]	
		, [marketing_lead_id]	= s.[marketing_lead_id]	
		, [number]				= s.[number]				
		, [date]				= s.[date]				
		, [requested_sum]		= s.[requested_sum]		
		, [approved_sum]		= s.[approved_sum]		
		, [sum_contract]		= s.[sum_contract]		
		, [days]				= s.[days]				
		, [status_id]			= s.[status_id]			
		, [status_date]			= s.[status_date]			
		, [product_type_id]		= s.[product_type_id]		
		, [mobile_phone]		= s.[mobile_phone]		
		, [last_name]			= s.[last_name]			
		, [first_name]			= s.[first_name]			
		, [second_name]			= s.[second_name]			
		, [credit_product_id]	= s.[credit_product_id]	
		, [source]				= s.[source]				
		, [updated_at]			= s.[updated_at]			
		, [UPDATED_BY]			= s.[UPDATED_BY]
		, [UPDATED_DT]			= s.[UPDATED_DT]
		, [publishTime]			= s.[publishTime]
	;

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
