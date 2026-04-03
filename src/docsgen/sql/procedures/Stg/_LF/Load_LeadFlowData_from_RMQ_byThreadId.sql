--[_lf].[Load_LeadFlowData_from_RMQ_byThreadId] @ThreadId = 0, @debug = 1

CREATE       procedure [_LF].[Load_LeadFlowData_from_RMQ_byThreadId]
	@ThreadId smallint = null
	,@ThreadIds nvarchar(max) = null 
	,@batchSize int = 15000
	,@debug bit = 0
WITH RECOMPILE
as
begin
	SET ARITHABORT ON
	DECLARE @error_description nvarchar(1024)
	declare @sp_name nvarchar(255) = 	concat_ws('.', OBJECT_SCHEMA_NAME(@@PROCID),	OBJECT_NAME(@@PROCID))
	set @ThreadIds = concat_ws(',', @ThreadIds, @ThreadId)
	set @batchSize = isnull(nullif(@batchSize,0), 15000)
	
--	SET DEADLOCK_PRIORITY 'NORMAL';

begin try
	if @ThreadIds is null
	begin
		;throw 51000, 'Значение ThreadId/s не задано', 16
	end
	 DECLARE 
		@StartDate datetime 
		, @procStartTime datetime = getdate()
		, @row_count int
		, @text varchar(max)
		, @dublicateRows int 
		, @uniqueRows int
		, @maxReceiveDate datetime 
		-- из stg таблицы
		, @dt datetime --= getdate()

	declare @dt_csv datetime --= (select receivedate FROM _LCRM.RMQ_Read_Logs where queue_name ='CSV')
	
	
		declare @partitionIds table (partitionId int primary key, queue_name nvarchar(255), lastReceivedate datetime2(7))

		insert into @partitionIds(partitionId, queue_name, lastReceivedate)

		select 
			partitionId = stgRmq.$PARTITION.[pfn_range_right_abs_leadId_mode_32_part_rmq_ReceivedMessages_LF_LeadRows_newRows](t.ThreadId)
			,queue_name = concat('LF_LeadRows', '_' , t.ThreadId)
			,lastReceivedate = isnull(
						iif(
						rl.ReceiveDate<@dt_csv
						, @dt_csv
						, rl.ReceiveDate)
				, cast(getdate() as date)) 
		from 
		(
			select 
				ThreadId = try_cast(t.value  as smallint)
			from string_split(@ThreadIds, ',') t
			where try_cast(t.value  as smallint) is not null
		) t
		
			left join _lf.RMQ_Read_Logs rl
				on rl.queue_name = concat('LF_LeadRows', '_' , t.ThreadId)
	declare @messageToProccesed int =( select count(1)
		from @partitionIds p
			inner join stgRmq.rmq.ReceivedMessages_lf_LeadRows_byThread rm with(NOLOCK)
			on stgRMQ.$PARTITION.[pfn_range_right_abs_leadId_mode_32_part_rmq_ReceivedMessages_LF_LeadRows_newRows]([ThreadId])    = p.partitionId
			and rm.PublishDateTime >=p.lastReceivedate
		)
	if @debug = 1
	begin
	
		select * from @partitionIds
	end
	declare  @result table (queue_name nvarchar(255), lastReceiveDate datetime2(7), totalMessageProccesed int)
	if @messageToProccesed>0
	begin
		
		
		select @batchSize = iif(@messageToProccesed>@batchSize, @batchSize, @messageToProccesed)
		--insert into #ReceivedMessages_LF_LeadRows_byThread
		--SET LOCK_TIMEOUT 50000
		drop table if exists #ReceivedMessages_LF_LeadRows_byThread
		create table #ReceivedMessages_LF_LeadRows_byThread
		(
			ThreadId			smallint
			,messageId			nvarchar(36)
			,publishDateTime		datetime2(7)
			,[publishTime]		decimal(20,6)
			,ReceivedMessage	nvarchar(max)
			,leadId					nvarchar(36)
			,queue_name			nvarchar(255)
		)
		insert into #ReceivedMessages_LF_LeadRows_byThread
		(
			ThreadId			
			,messageId	
			,publishDateTime 
			,[publishTime]
			,ReceivedMessage	
			,leadId					
			,queue_name			
		)
		select 
			 rm.ThreadId
			,rm.messageId
			,rm.publishDateTime
			,rm.[publishTime]
			,rm.ReceivedMessage
			,leadId = rm.leadId
			,p.queue_name
		
		from @partitionIds p
		outer apply (select top(@batchSize)
				rm.ThreadId
				,rm.messageId
				,rm.publishDateTime
				,rm.[publishTime]
				,rm.ReceivedMessage
				,rm.leadId
			from stgRmq.rmq.ReceivedMessages_lf_LeadRows_byThread rm with(NOLOCK)
			where stgRmq.$PARTITION.[pfn_range_right_abs_leadId_mode_32_part_rmq_ReceivedMessages_LF_LeadRows_newRows]([ThreadId])    
				= p.partitionId
				and rm.PublishDateTime >=p.lastReceivedate
			order by publishDateTime
			) rm
		OPTION(Recompile)  

		declare @leads _lf.utt_lead
		Insert into @leads
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
			, [auto_brand_id]
			, [auto_model_id]
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
			, [created_at]
			, [updated_at]
			, [fias_code]
			, [publishTime]

		)
	select 
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
			, [auto_brand_id]
			, [auto_model_id]
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
			, [created_at]
			, [updated_at]
			, [fias_code]
			, [publishTime]
		
		from (
	select  nRow					= ROW_NUMBER() over (partition by t.leadId  order by attributes.updated_at  desc, t.publishTime desc)
			,id  = t.leadId
			,source_id				= try_cast(attributes.source_id as uniqueidentifier)
			,entrypoint_id			= try_cast(attributes.entrypoint_id as uniqueidentifier)
			,status_id				= try_cast(attributes.status_id as uniqueidentifier)
			,attributes.name
			,attributes.phone
			,attributes.partner_name
			,attributes.partner_id		 
			,attributes.phone_additional
			,attributes.required_sum
			,attributes.required_month_count
			,attributes.comment
			,attributes.city
			,attributes.with_manager_taxi
			,attributes.filial
			,auto_brand_id			= try_cast(attributes.auto_brand_id as uniqueidentifier) 
			,auto_model_id			= try_cast(attributes.auto_model_id as uniqueidentifier) 
			,attributes.car_issue_year
			,attributes.car_cost
			,attributes.clt_name_first
			,attributes.clt_name_last
			,attributes.clt_name_third
			,clt_pass_id			= try_cast(attributes.clt_pass_id				as uniqueidentifier)
			,attributes.clt_birth_day
			,attributes.clt_email
			,attributes.clt_avg_income
			,attributes.clt_pass_city
			,attributes.clt_marial_state
			,attributes.org_name
			,attributes.org_job
			,lead_id				= try_cast(attributes.lead_id					as uniqueidentifier)
			,creator_id				= try_cast(attributes.creator_id				as uniqueidentifier)
			,attributes.creator_name
			,client_id				= try_cast(attributes.client_id					as uniqueidentifier)
			,visit_id				= try_cast(attributes.visit_id					as uniqueidentifier)
			,attributes.type_code
			,lead_type_id			= try_cast(attributes.lead_type_id				as uniqueidentifier)
			,attributes.product_name
			,product_type_id		= try_cast(attributes.product_type_id			as uniqueidentifier)
			,region_id				= try_cast(attributes.region_id					as uniqueidentifier)
			,mms_channel_id			= try_cast(attributes.mms_channel_id			as uniqueidentifier)
			,mms_channel_group_id	= try_cast(attributes.mms_channel_group_id		as uniqueidentifier)
			,mms_decline_reason_id	= try_cast(attributes.mms_decline_reason_id		as uniqueidentifier)
			,attributes.mms_priority				
			,attributes.has_marketing_reason		
			,attributes.created_at
			,attributes.updated_at
			,fias_code				= try_cast(attributes.fias_code					as uniqueidentifier)
			
			,publishTime			= t.[publishTime]
		from #ReceivedMessages_LF_LeadRows_byThread t
		outer apply openjson (ReceivedMessage, '$.data')
		with(
			type	nvarchar(255)	'$.type'
			,attributes nvarchar(max) '$.attributes' as json
		) t_data
		outer apply openjson (t_data.attributes, '$')
		with (
			source_id					nvarchar(36)	'$.source_id'
			,entrypoint_id				nvarchar(36)	'$.entrypoint_id'
			,status_id					nvarchar(36)	'$.status_id'
			,name						nvarchar(510)	'$.name'
			,phone						nvarchar(510)	'$.phone'
			,partner_name				nvarchar(510)	'$.partner_name'
			,partner_id					nvarchar(36)	'$.partner_id'
			,phone_additional			nvarchar(510)	'$.phone_additional'
			,required_sum				int				'$.required_sum'
			,required_month_count		int				'$.required_month_count'
			,comment					nvarchar(510)	'$.comment'
			,city						nvarchar(510)	'$.city'
			,with_manager_taxi			tinyint			'$.with_manager_taxi'
			,filial						nvarchar(510)	'$.filial'
			,auto_brand_id				nvarchar(510)	'$.auto_brand_id'
			,auto_model_id				nvarchar(510)	'$.auto_model_id'

			,car_issue_year				smallint		'$.car_issue_year'
			,car_cost					int				'$.car_cost'
			,clt_name_first				nvarchar(510)	'$.clt_name_first'
			,clt_name_last				nvarchar(510)	'$.clt_name_last'
			,clt_name_third				nvarchar(510)	'$.clt_name_third'
			,clt_pass_id				nvarchar(36)	'$.clt_pass_id'
			,clt_birth_day				nvarchar(510)	'$.clt_birth_day'
			,clt_email					nvarchar(510)	'$.clt_email'
			,clt_avg_income				int				'$.clt_avg_income'
			,clt_pass_city				nvarchar(510)	'$.clt_pass_city'
			,clt_marial_state			nvarchar(510)	'$.clt_marial_state'
			,org_name					nvarchar(510)	'$.org_name'
			,org_job					nvarchar(510)	'$.org_job'
			,lead_id					nvarchar(36)	'$.lead_id'
			,creator_id					nvarchar(36)	'$.creator_id'
			,creator_name				nvarchar(510)	'$.creator_name'
			,client_id					nvarchar(36)	'$.client_id'
			,visit_id					nvarchar(36)	'$.visit_id'
			,type_code					nvarchar(510)	'$.type_code'
			,lead_type_id				nvarchar(36)	'$.lead_type_id'
			,product_name				nvarchar(510)	'$.product_name'
			,product_type_id			nvarchar(36)	'$.product_type_id'
			,region_id					nvarchar(36)	'$.region_id'
			,mms_channel_id				nvarchar(36)	'$.mms_channel_id'
			,mms_channel_group_id		nvarchar(36)	'$.mms_channel_group_id'
			,mms_decline_reason_id		nvarchar(36)	'$.mms_decline_reason_id'
			,mms_priority				int				'$.mms_priority'
			,has_marketing_reason		bit				'$.has_marketing_reason'
			,fias_code					nvarchar(36)	'$.fias_code'
			,created_at					int				'$.created_at'
			,updated_at					int				'$.updated_at'
			) attributes
			where t.leadId is not null
		and t_data.type = 'Lead'
		) t
		where nRow = 1
		
		exec _lf.fill_lead @leads = @leads, @debug =  @debug

		drop table if exists #lead_includeds
		select 
			--t.leadId
			t.publishDateTime
			,t.publishTime
			,inc.includeds
			into #lead_includeds
			from #ReceivedMessages_LF_LeadRows_byThread t
			outer apply openjson (ReceivedMessage, '$')
			with
			(
				includeds nvarchar(max) '$.included' as json 
			) inc
	
		declare @source_accounts [_lf].[utt_source_account]
		insert into @source_accounts
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
		)
		select 
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
		from (
				select 
					 Id				= try_cast(t_source.Id	as uniqueidentifier)
					,Source_id = t_source.Id
					,t_source.type				
					,t_source.Name				
					,t_source.description		
					,t_source.auth_target		
					,t_source.auth_token			
					,t_source.product_type_code	
					,t_source.state				
					,t_source.is_own				
					,mms_channel_id = try_cast(t_source.mms_channel_id		 as uniqueidentifier)
					,t_source.created_at			
					,t_source.updated_at			
					,nRow = Row_Number()  over(partition by t_source.id 
						order by updated_at desc, publishTime desc)
				from #lead_includeds t_data
				OUTER APPLY OPENJSON (t_data.includeds, '$')with
				(
					Id					nvarchar(36)			'$.id'
					,type				nvarchar(255)			'$.type'
					,Name				nvarchar(255)			'$.attributes.name'
					,description		nvarchar(510)			'$.attributes.description'
					,auth_target		nvarchar(255)			'$.attributes.auth_target'
					,auth_token			nvarchar(1024)			'$.attributes.auth_token'
					,product_type_code	nvarchar(255)			'$.attributes.product_type_code'
					,state				smallint				'$.attributes.state'
					,is_own				bit						'$.attributes.is_own'
					,mms_channel_id		nvarchar(36)			'$.attributes.mms_channel_id'
					,created_at			int						'$.attributes.created_at'
					,updated_at			int						'$.attributes.updated_at'
				) t_source
				where type = 'source'
				and try_cast(t_source.Id	as uniqueidentifier) is not null
			) t
			where nRow = 1

		exec [_lf].fill_source_account @source_accounts = @source_accounts, @debug =  @debug

		declare @entrypoints  [_lf].[utt_entrypoint]

		insert into @entrypoints
		(
			[id]
			, [name]
			, [description]
			, [created_at]
			, [updated_at]
		)
		select 
			[id]
			, [name]
			, [description]
			, [created_at]
			, [updated_at]
		from (
		select 
			Id = try_cast(t_entrypoint.Id  as uniqueidentifier)
			,t_entrypoint.Name
			,t_entrypoint.description
			,t_entrypoint.created_at			
			,t_entrypoint.updated_at			
			,nRow = Row_Number()  over(partition by t_entrypoint.id 
				order by t_entrypoint.updated_at desc, publishTime desc)
		from #lead_includeds t_data
		OUTER APPLY OPENJSON (t_data.includeds, '$')with
		(
			Id					nvarchar(36)			'$.id'
			,type				nvarchar(255)			'$.type'
			,Name				nvarchar(510)			'$.attributes.name'
			,description		nvarchar(510)			'$.attributes.description'
			,created_at			int						'$.attributes.created_at'
			,updated_at			int						'$.attributes.updated_at'
		) t_entrypoint
		where type = 'entrypoint'
			and try_cast(t_entrypoint.Id	as uniqueidentifier) is not null
		) t where t.nRow = 1
		exec _lf.fill_entrypoint @entrypoints = @entrypoints, @debug =  @debug

		declare @statuses [_lf].[utt_status]
		insert into @statuses
		(
			[id]
			, [technical_name]
			, [technical_description]
			, [marketing_name]
			, [marketing_description]
			, [initiator]
			, [created_at]
			, [updated_at]
		)
		Select 
			[id]
			, [technical_name]
			, [technical_description]
			, [marketing_name]
			, [marketing_description]
			, [initiator]
			, [created_at]
			, [updated_at]
		from 
		(
		select 
			Id = try_cast(t_status.Id  as uniqueidentifier)
			,status_id = t_status.id
			,t_status.technical_name		
			,t_status.technical_description	
			,t_status.marketing_name		
			,t_status.marketing_description	 
			,t_status.initiator				
			,t_status.created_at			
			,t_status.updated_at			
			,nRow = Row_Number()  over(partition by t_status.id 
				order by t_status.updated_at desc, publishTime desc)
		from #lead_includeds t_data
		OUTER APPLY OPENJSON (t_data.includeds, '$')with
		(
			Id					nvarchar(37)			'$.id'
			,type				nvarchar(255)			'$.type'
			,technical_name				nvarchar(255)	'$.attributes.technical_name'
			,technical_description		nvarchar(510)	'$.attributes.technical_description'
			,marketing_name				nvarchar(510)	'$.attributes.marketing_name'
			,marketing_description		nvarchar(510)	'$.attributes.marketing_description'
			,initiator					nvarchar(510)	'$.attributes.initiator'
			,created_at					int				'$.attributes.created_at'
			,updated_at					int				'$.attributes.updated_at'
		) t_status
		where type = 'status'
			and try_cast(t_status.Id	as uniqueidentifier) is not null
		) t
		where t.nRow=1
	
		exec _lf.fill_status @statuses = @statuses, @debug =  @debug

	
		declare @productTypes _lf.utt_productType
		insert into @productTypes
		(
			  [id]
			, [code]
			, [name]
			, [is_need_pts]
			, [min_sum]
			, [max_sum]
			, [created_at]
			, [updated_at]
		)
		select 
			  [id]
			, [code]
			, [name]
			, [is_need_pts]
			, [min_sum]
			, [max_sum]
			, [created_at]
			, [updated_at]
		from (
		select 
			Id = try_cast(t_productType.Id  as uniqueidentifier)
			,t_productType_id = t_productType.id
			,t_productType.code		
			,t_productType.name	
			,t_productType.is_need_pts		
			,t_productType.min_sum	 
			,t_productType.max_sum				
			,t_productType.created_at			
			,t_productType.updated_at			
			,nRow = Row_Number()  over(partition by t_productType.id 
				order by t_productType.updated_at desc,  publishTime desc)
		from #lead_includeds t_data
		OUTER APPLY OPENJSON (t_data.includeds, '$')with
		(
			Id					nvarchar(37)	'$.id'
			,type				nvarchar(255)	'$.type'
			,code				nvarchar(510)	'$.attributes.code'
			,name				nvarchar(510)	'$.attributes.name'
			,is_need_pts		bit				'$.attributes.is_need_pts'
			,min_sum			int				'$.attributes.min_sum'
			,max_sum			int				'$.attributes.max_sum'
			,created_at			int				'$.attributes.created_at'
			,updated_at			int				'$.attributes.updated_at'
		) t_productType
		where type = 'productType'
			and try_cast(t_productType.Id	as uniqueidentifier) is not null
			) t
			where  nRow = 1 
	
		exec _lf.fill_product_type @productTypes = @productTypes, @debug =  @debug


		declare @leadTypes	[_lf].[utt_leadType]
		insert into @leadTypes 
		(
			[id]
			, [name]
			, [code_name]
			, [created_at]
			, [updated_at]
		)
		select 
			[id]
			, [name]
			, [code_name]
			, [created_at]
			, [updated_at]
		from 
		(
		select 
			Id = try_cast(t_leadType.Id  as uniqueidentifier)
			,t_leadType.Name
			,t_leadType.code_name
			,t_leadType.created_at			
			,t_leadType.updated_at			
			,nRow = Row_Number()  over(partition by t_leadType.id 
			
				order by t_leadType.updated_at desc, publishTime desc)
		from #lead_includeds t_data
		OUTER APPLY OPENJSON (t_data.includeds, '$')with
		(
			Id					nvarchar(36)			'$.id'
			,type				nvarchar(255)			'$.type'
			,Name				nvarchar(510)			'$.attributes.name'
			,code_name			nvarchar(510)			'$.attributes.code_name'
			,created_at			int						'$.attributes.created_at'
			,updated_at			int						'$.attributes.updated_at'
		) t_leadType
		where type = 'leadType'
			and try_cast(t_leadType.Id	as uniqueidentifier) is not null
		) t
		where nRow = 1
		exec _lf.fill_leadType @leadTypes = @leadTypes, @debug =  @debug


		declare @mmsChannelGroups [_lf].[utt_mmsChannelGroup]

		insert into @mmsChannelGroups
		(
			  [id]
			, [name]
			, [description]
			, [created_at]
			, [updated_at]
			 
		)
		select 
			  [id]
			, [name]
			, [description]
			, [created_at]
			, [updated_at]
		from (
		select 
			Id = try_cast(t_mmsChannelGroup.Id  as uniqueidentifier)
			,t_mmsChannelGroup = t_mmsChannelGroup.id
			,t_mmsChannelGroup.name	
			,t_mmsChannelGroup.description	
			,t_mmsChannelGroup.created_at			
			,t_mmsChannelGroup.updated_at	
			,nRow = Row_Number()  over(partition by t_mmsChannelGroup.id 
				order by t_mmsChannelGroup.updated_at desc, publishTime desc)
		from #lead_includeds t_data
		OUTER APPLY OPENJSON (t_data.includeds, '$')with
		(
			Id					nvarchar(37)	'$.id'
			,type				nvarchar(255)	'$.type'
			,name				nvarchar(510)	'$.attributes.name'
			,[description]		nvarchar(510)	'$.attributes.description'
			,created_at			int				'$.attributes.created_at'
			,updated_at			int				'$.attributes.updated_at'
		) t_mmsChannelGroup
		where type = 'mmsChannelGroup'
			and try_cast(t_mmsChannelGroup.Id	as uniqueidentifier) is not null
			) t
			where  nRow = 1 
		exec [_lf].[fill_mmsChannelGroup] @mmsChannelGroups = @mmsChannelGroups, @debug =  @debug



		declare @mmsChannels [_lf].[utt_mmsChannel]

		insert into @mmsChannels
		(
			  [id]
			, [name]
			, [description]
			, [mms_channel_group_id]
			, [created_at]
			, [updated_at]
			 
		)
		select 
			  [id]
			, [name]
			, [description]
			, [mms_channel_group_id]
			, [created_at]
			, [updated_at]
		from (
		select 
			Id = try_cast(t_mmsChannel.Id  as uniqueidentifier)
			,t_mmsChannel = t_mmsChannel.id
			,t_mmsChannel.name	
			,t_mmsChannel.description	
			,mms_channel_group_id =  try_cast(t_mmsChannel.mms_channel_group_id  as uniqueidentifier)
			,t_mmsChannel.created_at			
			,t_mmsChannel.updated_at	
			,nRow = Row_Number()  over(partition by t_mmsChannel.id 
				order by t_mmsChannel.updated_at desc, publishTime desc)
		from #lead_includeds t_data
		OUTER APPLY OPENJSON (t_data.includeds, '$')with
		(
			Id					nvarchar(37)	'$.id'
			,type				nvarchar(255)	'$.type'
			,name				nvarchar(510)	'$.attributes.name'
			,mms_channel_group_id nvarchar(36)	'$.attributes.mms_channel_group_id'
			,[description]		nvarchar(510)	'$.attributes.description'
			,created_at			int				'$.attributes.created_at'
			,updated_at			int				'$.attributes.updated_at'
		) t_mmsChannel
		where type = 'mmsChannel'
			and try_cast(t_mmsChannel.Id	as uniqueidentifier) is not null
			) t
			where  nRow = 1 
		exec [_lf].[fill_mmsChannel] @mmsChannels = @mmsChannels ,@debug =  @debug



		declare @mmsDeclineReasons [_lf].[utt_mmsDeclineReason]

		insert into @mmsDeclineReasons
		(
			[id]
			, [name]
			, [code_name]
			, [lead_status_id]
			, [created_at]
			, [updated_at]
		)
		select 
			  [id]
			, [name]
			, [code_name]
			, [lead_status_id]
			, [created_at]
			, [updated_at]
		from (
		select 
			Id = try_cast(t_mmsDeclineReason.Id  as uniqueidentifier)
			,t_mmsDeclineReason = t_mmsDeclineReason.id
			,t_mmsDeclineReason.name	
			,t_mmsDeclineReason.code_name	
			,lead_status_id =  try_cast(t_mmsDeclineReason.lead_status_id  as uniqueidentifier)
			,t_mmsDeclineReason.created_at			
			,t_mmsDeclineReason.updated_at	
			,nRow = Row_Number()  over(partition by t_mmsDeclineReason.id 
				order by t_mmsDeclineReason.updated_at desc, publishTime desc)
		from #lead_includeds t_data
		OUTER APPLY OPENJSON (t_data.includeds, '$')with
		(
			Id					nvarchar(37)	'$.id'
			,type				nvarchar(255)	'$.type'
			,name				nvarchar(255)	'$.attributes.name'
			,[code_name]		nvarchar(255)	'$.attributes.code_name'
			,[lead_status_id]   nvarchar(36)	'$.attributes.lead_status_id'
			,created_at			int				'$.attributes.created_at'
			,updated_at			int				'$.attributes.updated_at'
			
		) t_mmsDeclineReason
		where type = 'mmsDeclineReason'
			and try_cast(t_mmsDeclineReason.Id	as uniqueidentifier) is not null
			) t
			where  nRow = 1 
		exec[_lf].[fill_mmsDeclineReason] @mmsDeclineReasons  =@mmsDeclineReasons
			, @debug = @debug

		
		declare @mmsDecisions [_lf].[utt_mmsDecision]

		insert into @mmsDecisions
		(
			  [id]
			, [lead_id]
			, [mms_decision_type_id]
			, [created_at]
			, [updated_at]
		)
		select 
			  [id]
			, [lead_id]
			, [mms_decision_type_id]
			, [created_at]
			, [updated_at]
		from (
		select 
			Id							= try_cast(t_mmsDecision.Id  as uniqueidentifier)
			,t_mmsDecision				= t_mmsDecision.id
			,[lead_id]					= try_cast(t_mmsDecision.[lead_id] as uniqueidentifier)	
			,[mms_decision_type_id]		= try_cast(t_mmsDecision.[mms_decision_type_id] as uniqueidentifier)
			,t_mmsDecision.created_at			
			,t_mmsDecision.updated_at	
			,nRow = Row_Number()  over(partition by t_mmsDecision.id 
				order by t_mmsDecision.updated_at desc, publishTime desc)
		from #lead_includeds t_data
		OUTER APPLY OPENJSON (t_data.includeds, '$')with
		(
			Id					nvarchar(37)	'$.id'
			,type				nvarchar(255)	'$.type'
			,lead_id				nvarchar(255)	'$.attributes.lead_id'
			,mms_decision_type_id   nvarchar(36)	'$.attributes.mms_decision_type_id'
			,created_at			int				'$.attributes.created_at'
			,updated_at			int				'$.attributes.updated_at'
			
		) t_mmsDecision
		where type = 'mmsDecision'
			and try_cast(t_mmsDecision.Id	as uniqueidentifier) is not null
			) t
			where  nRow = 1 
		exec[_lf].[fill_mmsDecision] @mmsDecisions  =@mmsDecisions
			, @debug = @debug

		
		declare @naumenCallCases [_lf].utt_naumen_call_case
		insert into @naumenCallCases
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
			, publishTime
		)
		select 
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
			, publishTime
		from (
		select 
			Id						= try_cast(t_naumenCallCase.Id  as uniqueidentifier)
			, t_naumenCallCase_id	= t_naumenCallCase.id
			, [lead_id]				= try_cast(t_naumenCallCase.[lead_id] as uniqueidentifier)	
			, [mms_decision_id]		= try_cast(t_naumenCallCase.[mms_decision_id] as uniqueidentifier)
			, [url]
			, [method]
			, [phone]
			, [payload]
			, [status]
			, [response_code]
			, [response_body]
			, t_naumenCallCase.created_at			
			, t_naumenCallCase.updated_at	
			, nRow = Row_Number()  over(partition by t_naumenCallCase.id 
				order by t_naumenCallCase.updated_at desc, publishTime desc)
			,t_data.publishTime
		from #lead_includeds t_data
		OUTER APPLY OPENJSON (t_data.includeds, '$')with
		(
			Id					nvarchar(36)	'$.id'
			,type				nvarchar(255)	'$.type'
			,lead_id			nvarchar(36)	'$.attributes.lead_id'
			,[mms_decision_id]  nvarchar(36)	'$.attributes.mms_decision_id'
			,[url]				nvarchar(510)	'$.attributes.url'
			,method				nvarchar(510)	'$.attributes.method'
			,phone				nvarchar(510)	'$.attributes.phone'
			,[payload]			nvarchar(510)	'$.attributes.payload'
			,status				int				'$.attributes.status'
			,response_code		nvarchar(510)	'$.attributes.response_code'
			,response_body		nvarchar(2048)	'$.attributes.response_body'
			,created_at			int				'$.attributes.created_at'
			,updated_at			int				'$.attributes.updated_at'
		) t_naumenCallCase
		where type = 'naumenCallCase'
			and try_cast(t_naumenCallCase.Id	as uniqueidentifier) is not null
			) t
			where  nRow = 1 
		
		exec [_lf].[fill_naumenCallCase] @naumenCallCases  =@naumenCallCases
			, @debug = @debug

		
		declare @autoBrands [_lf].utt_autoBrand
		insert into @autoBrands
		(
			[id]
			, [name]
			, [active]
			, [sort]
			, [created_at]
			, [updated_at]
		)
		select 
			  [id]
			, [name]
			, [active]
			, [sort]
			, [created_at]
			, [updated_at]
		from (
		select 
			Id						= try_cast(t_autoBrand.Id  as uniqueidentifier)
			, t_autoBrand_id	= t_autoBrand.id
			, [name]
			, [active]
			, [sort]
			, t_autoBrand.created_at			
			, t_autoBrand.updated_at	
			, nRow = Row_Number()  over(partition by t_autoBrand.id 
				order by t_autoBrand.updated_at desc, publishTime desc)
		from #lead_includeds t_data
		OUTER APPLY OPENJSON (t_data.includeds, '$')with
		(
			Id				nvarchar(36)	'$.id'
			,type			nvarchar(255)	'$.type'
			,[name]			nvarchar(510)	'$.attributes.name'
			,[active]		bit				'$.attributes.active'
			,[sort]			int				'$.attributes.sort'
			,created_at		int				'$.attributes.created_at'
			,updated_at		int				'$.attributes.updated_at'
		) t_autoBrand
		where type = 'autoBrand'
			and try_cast(t_autoBrand.Id	as uniqueidentifier) is not null
			) t
			where  nRow = 1 

		exec [_lf].[fill_autoBrand] @autoBrands  =@autoBrands
			, @debug = @debug



		
	
	declare @autoModels [_lf].[utt_autoModel]
		insert into @autoModels
		(
			[id]
			, [name]
			, [active]
			, [sort]
			, auto_brand_id
			, [created_at]
			, [updated_at]
		)
		select 
			  [id]
			, [name]
			, [active]
			, [sort]
			, auto_brand_id
			, [created_at]
			, [updated_at]
		from (
		select 
			Id						= try_cast(t_autoModel.Id  as uniqueidentifier)
			, t_autoModel_id	= t_autoModel.id
			, [name]
			, [active]
			, [sort]
			, auto_brand_id = try_cast(t_autoModel.id		as uniqueidentifier)
			, t_autoModel.created_at			
			, t_autoModel.updated_at	
			, nRow = Row_Number()  over(partition by t_autoModel.id 
				order by  t_autoModel.updated_at desc, publishTime desc)
		from #lead_includeds t_data
		OUTER APPLY OPENJSON (t_data.includeds, '$')with
		(
			Id				nvarchar(36)	'$.id'
			,type			nvarchar(255)	'$.type'
			,[name]			nvarchar(510)	'$.attributes.name'
			,[active]		bit				'$.attributes.active'
			,[sort]			int				'$.attributes.sort'
			,[auto_brand_id] nvarchar(36)	'$.attributes.auto_brand_id'
			,created_at		int				'$.attributes.created_at'
			,updated_at		int				'$.attributes.updated_at'
		) t_autoModel
		where type = 'autoModel'
			and try_cast(t_autoModel.Id	as uniqueidentifier) is not null
			) t
			where  nRow = 1 

		exec [_lf].[fill_autoModel] @autoModels  =@autoModels
			, @debug = @debug


		declare @request [_LF].[utt_request]

		insert into @request
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
			, publishTime
		)

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
			, publishTime
			
			
		from (
		select 
			id					= try_cast(t_RequestOriginal.Id  as uniqueidentifier)
			,type				
			,original_lead_id	= try_cast(t_RequestOriginal.original_lead_id  as uniqueidentifier)
			,marketing_lead_id	= try_cast(t_RequestOriginal.marketing_lead_id  as uniqueidentifier)
			,number				
			,date				
			,requested_sum		
			,approved_sum		
			,sum_contract		
			,days				
			,status_id			
			,status_date		= iif(year(status_date)<2000, null, status_date)
			,product_type_id	= try_cast(t_RequestOriginal.product_type_id  as uniqueidentifier)
			,mobile_phone		
			,last_name			
			,first_name			
			,second_name		
			,credit_product_id	= try_cast(t_RequestOriginal.credit_product_id  as uniqueidentifier)
			,[source]		
			,created_at			
			,updated_at			
			, nRow = Row_Number()  over(partition by t_RequestOriginal.id 
				order by t_RequestOriginal.updated_at desc, t_data.publishTime desc)
			,t_data.publishTime
		from #lead_includeds t_data
		OUTER APPLY OPENJSON (t_data.includeds, '$')with
		(
			id					nvarchar(36)	'$.id'
			,type				nvarchar(255)	'$.type'
			,original_lead_id	nvarchar(36)	'$.attributes.original_lead_id'
			,marketing_lead_id	nvarchar(36)	'$.attributes.marketing_lead_id'
			,number				nvarchar(510)	'$.attributes.number'
			,date				datetime		'$.attributes.date'
			,requested_sum		int				'$.attributes.requested_sum'
			,approved_sum		int				'$.attributes.approved_sum'
			,sum_contract		int				'$.attributes.sum_contract'
			,days				int				'$.attributes.days'
			,status_id			nvarchar(36)	'$.attributes.status_id'
			,status_date		datetime2(7)	'$.attributes.status_date'
			,product_type_id	nvarchar(36)	'$.attributes.product_type_id'
			,mobile_phone		nvarchar(510)	'$.attributes.mobile_phone'
			,last_name			nvarchar(510)	'$.attributes.last_name'
			,first_name			nvarchar(510)	'$.attributes.first_name'
			,second_name		nvarchar(510)	'$.attributes.second_name'
			,credit_product_id	nvarchar(36)	'$.attributes.credit_product_id'
			,[source]			nvarchar(510)	'$.attributes.source'
			,created_at			int				'$.attributes.created_at'
			,updated_at			int				'$.attributes.updated_at'
		) t_RequestOriginal
		where type in('fedorRequestOriginal', 'fedorRequestMarketing')

			and try_cast(t_RequestOriginal.Id	as uniqueidentifier) is not null
		) t
			where  nRow = 1 

		exec [_lf].[fill_Request] @request  =@request
			, @debug = @debug



		--select @maxReceiveDate = max(ReceiveDate) 
		--,@TotalMessageToProccesed = count(1)
		--from #ReceivedMessages_LF_LeadRows_byThread
		--(queue_name nvarchar(255), lastReceiveDate datetime, totalMessageProccesed int)
		insert into @result(queue_name, lastReceiveDate, totalMessageProccesed)
		select 
			queue_name = t.queue_name
			,ReceiveDate = max(t.publishDateTime)
			,RowsCount = count(1)
		from #ReceivedMessages_LF_LeadRows_byThread t
		group by queue_name
		
	
	end
	

	if @debug = 1
	begin
		select * from @result
		select  *from #ReceivedMessages_LF_LeadRows_byThread
	end
	merge _lf.RMQ_Read_Logs with(rowlock, updlock) t 
		using 
		(
			select 
				queue_name 
				,RowsCount = isnull(totalMessageProccesed, 0)
				,receiveDate = lastReceivedate
				,Duration = getdate() - @procStartTime 
				,updated_at = getdate()
				from @result
		) s on  s.queue_name = t.queue_name
		when matched then update 
			set ReceiveDate  = s.ReceiveDate
				,RowsCount = s.RowsCount
				,Duration = getdate() - @procStartTime 
				,updated_at = getdate()
		when not matched then insert(ReceiveDate, queue_name, RowsCount, Duration, updated_at )
		values(s.ReceiveDate, s.queue_name, s.RowsCount, s.Duration, s.updated_at);
			

	
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran

	SELECT @error_description = concat_ws(',',
			'ErrorNumber: ', cast(format(error_number(),'0') as nvarchar(50)),
			'ErrorSEVERITY: ', cast(format(error_severity(),'0') as nvarchar(50)),
			'ErrorState: ', cast(format(error_state(),'0') as nvarchar(50)),
			'ErrorProcedure: ', isnull( error_procedure() ,''),
			'Error_line: ', cast(format(error_line(),'0') AS nvarchar(50)),
			'ErrorMessage: '+  isnull(ERROR_MESSAGE(),'')
	)

	SELECT @text = concat_ws(
		'Ошибка выполнения: ', @sp_name
		,'поток: ',  @ThreadId
		,'Описание ошибки: ', @error_description
	) 
	if ERROR_NUMBER() in (1219 --Your session has been disconnected because of a high priority DDL operation
		,  596 --Cannot continue the execution because the session is in the kill stat
		, 1222 --
		, 1205 --
		
	--	, 539 --Schema changed after the target table was created
		) --Kill 
	begin
		print @text
		if @debug =0
		begin
			return 1 --выходим без ошибки
		end
	end
	else if error_number() not in (
		1222
		, 1205 --
		) 
	begin
		EXEC [LogDb].[dbo].[SendToSlack_lcrm-backup-restore-dwh-monitoring] @text
		
	end
	;throw

end catch
end
