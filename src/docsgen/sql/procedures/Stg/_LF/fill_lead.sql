
CREATE          PROCEDURE [_LF].[fill_lead]
	@leads [_lf].[utt_lead]  READONLY
	,@debug bit = 0
AS
BEGIN
declare @startTime datetime = getdate()
	,@updateRows int
	, @insertedRows int
	, @procName nvarchar(255) = concat(
		SCHEMA_NAME(@@PROCID), '.' , OBJECT_NAME(@@PROCID))
	begin try
	
		--;with cte as
		--(
		-- select 
		--	nRow = ROW_NUMBER() over(partition by Id order by isnull([created_at], [updated_at]))
		--	,*

		-- from @leads
		--)

		--delete from cte
		--where nRow>1
		declare  @UPDATED_BY	nvarchar(255)	= @procName
				,@UPDATED_DT	datetime		= getdate()

	begin tran

		update  t
			set 
			 t.[source_id]				= s.[source_id]
			, t.[entrypoint_id]			= s.[entrypoint_id]
			, t.[status_id]				= s.[status_id]
			, t.[name]					= s.[name]
			, t.[phone]					= s.[phone]
			, t.[partner_name]			= s.[partner_name]
			, t.[partner_id]			= s.[partner_id]
			, t.[phone_additional]		= s.[phone_additional]
			, t.[required_sum]			= s.[required_sum]
			, t.[required_month_count]	= s.[required_month_count]
			, t.[comment]				= s.[comment]
			, t.[city]					= s.[city]
			, t.[with_manager_taxi]		= s.[with_manager_taxi]
			, t.[filial]				= s.[filial]
			, t.auto_brand_id			= s.auto_brand_id
			, t.auto_model_id			= s.auto_model_id
			, t.[car_issue_year]		= s.[car_issue_year]
			, t.[car_cost]				= s.[car_cost]
			, t.[clt_name_first]		= s.[clt_name_first]
			, t.[clt_name_last]			= s.[clt_name_last]
			, t.[clt_name_third]		= s.[clt_name_third]
			, t.[clt_pass_id]			= s.[clt_pass_id]
			, t.[clt_birth_day]			= s.[clt_birth_day]
			, t.[clt_email]				= s.[clt_email]
			, t.[clt_avg_income]		= s.[clt_avg_income]
			, t.[clt_pass_city]			= s.[clt_pass_city]
			, t.[clt_marial_state]		= s.[clt_marial_state]
			, t.[org_name]				= s.[org_name]
			, t.[org_job]				= s.[org_job]
			, t.[lead_id]				= s.[lead_id]
			, t.[creator_id]			= s.[creator_id]
			, t.[creator_name]			= s.[creator_name]
			, t.[client_id]				= s.[client_id]
			, t.[visit_id]				= s.[visit_id]
			, t.[type_code]				= s.[type_code]
			, t.[lead_type_id]			= s.[lead_type_id]
			, t.[product_name]			= s.[product_name]
			, t.[product_type_id]		= s.[product_type_id]
			, t.[region_id]				= s.[region_id]
			, t.[mms_channel_id]		= s.[mms_channel_id]
			, t.[mms_channel_group_id]	= s.[mms_channel_group_id]
			, t.[mms_decline_reason_id]	= s.[mms_decline_reason_id]
			, t.[mms_priority]			= s.[mms_priority]
			, t.[has_marketing_reason]	= s.[has_marketing_reason]
			, t.fias_code				= s.fias_code
			, t.[updated_at]			= s.[updated_at]
			, t.[UPDATED_BY]			= @UPDATED_BY
			, t.[UPDATED_DT]			= @UPDATED_DT
			, t.[publishTime]			= s.[publishTime]
		from @leads s
		inner join _lf.[lead] t with(rowlock)
			on	t.Id =  s.id 
			and s.updated_at>=t.updated_at
			--and  $Partition.[pfn_range_right_date_part__crib2_lead](s.[created_at_time]) =  $Partition.[pfn_range_right_date_part__crib2_lead](t.[created_at_time])
			and isnull(s.[publishTime],s.updated_at)>=isnull(t.[publishTime], t.updated_at)
		OPTION(Recompile, QUERYTRACEON 610)
		set @updateRows = @@ROWCOUNT
	insert into [_lf].[lead]
	(
		[id]
		, [source_id]
		, [entrypoint_id]
		, [status_id]
		, [name]
		, [phone]
		, [partner_name]
		, [partner_id]
		, [phone_additional]
		, [required_sum]
		, [required_month_count]
		, [comment]
		, [city]
		, [with_manager_taxi]
		, [filial]
		, auto_brand_id
		, auto_model_id
		, [car_issue_year]
		, [car_cost]
		, [clt_name_first]
		, [clt_name_last]
		, [clt_name_third]
		, [clt_pass_id]
		, [clt_birth_day]
		, [clt_email]
		, [clt_avg_income]
		, [clt_pass_city]
		, [clt_marial_state]
		, [org_name]
		, [org_job]
		, [lead_id]
		, [creator_id]
		, [creator_name]
		, [client_id]
		, [visit_id]
		, [type_code]
		, [lead_type_id]
		, [product_name]
		, [product_type_id]
		, [region_id]
		, [mms_channel_id]
		, [mms_channel_group_id]
		, [mms_decline_reason_id]
		, [mms_priority]
		, [has_marketing_reason]
		, fias_code
		, [created_at]
		, [updated_at]
		, [UPDATED_BY]
		, [UPDATED_DT]
		, [publishTime]

	)

	select 
			  s.[id]
			, s.[source_id]
			, s.[entrypoint_id]
			, s.[status_id]
			, s.[name]
			, s.[phone]
			, s.[partner_name]
			, s.[partner_id]
			, s.[phone_additional]
			, s.[required_sum]
			, s.[required_month_count]
			, s.[comment]
			, s.[city]
			, s.[with_manager_taxi]
			, s.[filial]
			, s.auto_brand_id
			, s.auto_model_id
			, s.[car_issue_year]
			, s.[car_cost]
			, s.[clt_name_first]
			, s.[clt_name_last]
			, s.[clt_name_third]
			, s.[clt_pass_id]
			, s.[clt_birth_day]
			, s.[clt_email]
			, s.[clt_avg_income]
			, s.[clt_pass_city]
			, s.[clt_marial_state]
			, s.[org_name]
			, s.[org_job]
			, s.[lead_id]
			, s.[creator_id]
			, s.[creator_name]
			, s.[client_id]
			, s.[visit_id]
			, s.[type_code]
			, s.[lead_type_id]
			, s.[product_name]
			, s.[product_type_id]
			, s.[region_id]
			, s.[mms_channel_id]
			, s.[mms_channel_group_id]
			, s.[mms_decline_reason_id]
			, s.[mms_priority]
			, s.[has_marketing_reason]
			, s.fias_code
			, s.[created_at]
			, s.[updated_at]
			, @UPDATED_BY
			, @UPDATED_DT
			, s.[publishTime]
		from @leads s
		where not exists(select top(1) 1 from _LF.lead l with(index =cix_id )
			where l.id = s.id
			--and  $Partition.[pfn_range_right_date_part__crib2_lead](s.[created_at_time]) =  $Partition.[pfn_range_right_date_part__crib2_lead](t.[created_at_time])
			)
		--where l.id is null
		OPTION(Recompile, QUERYTRACEON 610)
		set @insertedRows = @@ROWCOUNT
	/*
	merge [_lf].[lead] t
		using (
		select 
				[id] = cast([id] as nvarchar(36))
			, [source_id]
			, [entrypoint_id]
			, [status_id]
			, [name]
			, [phone]
			, [partner_name]
			, [partner_id]
			, [phone_additional]
			, [required_sum]
			, [required_month_count]
			, [comment]
			, [city]
			, [with_manager_taxi]
			, [filial]
			, auto_brand_id
			, auto_model_id
			, [car_issue_year]
			, [car_cost]
			, [clt_name_first]
			, [clt_name_last]
			, [clt_name_third]
			, [clt_pass_id]
			, [clt_birth_day]
			, [clt_email]
			, [clt_avg_income]
			, [clt_pass_city]
			, [clt_marial_state]
			, [org_name]
			, [org_job]
			, [lead_id]
			, [creator_id]
			, [creator_name]
			, [client_id]
			, [visit_id]
			, [type_code]
			, [lead_type_id]
			, [product_name]
			, [product_type_id]
			, [region_id]
			, [mms_channel_id]
			, [mms_channel_group_id]
			, [mms_decline_reason_id]
			, [mms_priority]
			, [has_marketing_reason]
			, fias_code
			--, [created_at_time] = DATEADD(s, s.created_at, '1970-01-01')
			--, [updated_at_time] = DATEADD(s, isnull(s.updated_at, s.created_at), '1970-01-01')
			, [created_at]
			, [updated_at]
			
			, partition_id			= $partition.[pfn_range_right_date_part__crib2_lead]
				(dateadd(ss, [created_at], '1970-01-01'))
			from @leads s
		) s
		on t.Id = s.ID
			--and t.$partition.[pfn_range_right_date_part__crib2_lead]([created_at_time]) = s.partition_id
		when not matched then insert
		(
			[id]
			, [source_id]
			, [entrypoint_id]
			, [status_id]
			, [name]
			, [phone]
			, [partner_name]
			, [partner_id]
			, [phone_additional]
			, [required_sum]
			, [required_month_count]
			, [comment]
			, [city]
			, [with_manager_taxi]
			, [filial]
			, auto_brand_id
			, auto_model_id
			, [car_issue_year]
			, [car_cost]
			, [clt_name_first]
			, [clt_name_last]
			, [clt_name_third]
			, [clt_pass_id]
			, [clt_birth_day]
			, [clt_email]
			, [clt_avg_income]
			, [clt_pass_city]
			, [clt_marial_state]
			, [org_name]
			, [org_job]
			, [lead_id]
			, [creator_id]
			, [creator_name]
			, [client_id]
			, [visit_id]
			, [type_code]
			, [lead_type_id]
			, [product_name]
			, [product_type_id]
			, [region_id]
			, [mms_channel_id]
			, [mms_channel_group_id]
			, [mms_decline_reason_id]
			, [mms_priority]
			, [has_marketing_reason]
			, fias_code
			--, [created_at_time]
			--, [updated_at_time]
			, [created_at]
			, [updated_at]
			, [UPDATED_BY]
			, [UPDATED_DT]
		)
		values
		(	
			[id]
			, [source_id]
			, [entrypoint_id]
			, [status_id]
			, [name]
			, [phone]
			, [partner_name]
			, [partner_id]
			, [phone_additional]
			, [required_sum]
			, [required_month_count]
			, [comment]
			, [city]
			, [with_manager_taxi]
			, [filial]
			, auto_brand_id
			, auto_model_id
			, [car_issue_year]
			, [car_cost]
			, [clt_name_first]
			, [clt_name_last]
			, [clt_name_third]
			, [clt_pass_id]
			, [clt_birth_day]
			, [clt_email]
			, [clt_avg_income]
			, [clt_pass_city]
			, [clt_marial_state]
			, [org_name]
			, [org_job]
			, [lead_id]
			, [creator_id]
			, [creator_name]
			, [client_id]
			, [visit_id]
			, [type_code]
			, [lead_type_id]
			, [product_name]
			, [product_type_id]
			, [region_id]
			, [mms_channel_id]
			, [mms_channel_group_id]
			, [mms_decline_reason_id]
			, [mms_priority]
			, [has_marketing_reason]
			, fias_code
		--	, [created_at_time]
		--	, [updated_at_time]
			, [created_at]
			, [updated_at]
			, [UPDATED_BY]
			, [UPDATED_DT]
		)
		
		when matched and t.[updated_at]>s.[updated_at]
			then update 
			
	;
	*/
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
END
