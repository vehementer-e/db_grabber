
/****** Object:  StoredProcedure [_LF].[fill_request]    Script Date: 26.04.2024 21:03:13 ******/




CREATE   procedure [_LF].[fill_naumenCallCase]
	@naumenCallCases _lf.[utt_naumen_call_case] readonly
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
			set
			  [lead_id]			 = s.[lead_id]			
			, [mms_decision_id]	 = s.[mms_decision_id]	
			, [url]				 = s.[url]				
			, [method]			 = s.[method]			
			, [phone]			 = s.[phone]			
			, [payload]			 = s.[payload]			
			, [status]			 = s.[status]			
			, [response_code]	 = s.[response_code]	
			, [response_body]	 = s.[response_body]	
			, [updated_at]		 = s.[updated_at]		
			, [UPDATED_BY]		 = @UPDATED_BY
			, [UPDATED_DT]		 = @UPDATED_DT
			, [publishTime]		 = s.[publishTime]
		from @naumenCallCases s
		inner join _lf.naumen_call_case t
			on t.id = s.id
			and s.updated_at>=t.updated_at
			and isnull(s.[publishTime], s.updated_at)>= isnull(t.[publishTime], t.updated_at)
		OPTION(Recompile, QUERYTRACEON 610)
		set @updateRows =@@ROWCOUNT

		insert into _lf.naumen_call_case
		(
			  [id]
			, [lead_id]
			, [mms_decision_id]
			, [url]
			, [method]
			, [phone]
			, [payload]
			, [status]
			, [response_code]
			, [response_body]
			, [created_at]
			, [updated_at]
			, [UPDATED_BY]		
			, [UPDATED_DT]
			, [publishTime]
		)
		select 
			  s.[id]
			, s.[lead_id]
			, s.[mms_decision_id]
			, s.[url]
			, s.[method]
			, s.[phone]
			, s.[payload]
			, s.[status]
			, s.[response_code]
			, s.[response_body]
			, s.[created_at]
			, s.[updated_at]
			, @UPDATED_BY		
			, @UPDATED_DT
			, s.[publishTime]
		from @naumenCallCases s
		where not exists(select top(1) 1 from _lf.naumen_call_case t with(nolock, index =[cix_id])
			where t.id = s.id)
		OPTION(Recompile, QUERYTRACEON 610)
		
		set @insertedRows =@@ROWCOUNT
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
