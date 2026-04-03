CREATE   procedure [dbo].[fill_dm_lead_ml]
	@isReCreateTable bit = 0
	,@rows int = 1e7
as
begin
begin try

drop table if exists #t

select 
	 leadId		= l.leadId
	,leadPhone		= l.leadPhone 
	,sourceId		= l.sourceId --Источник --_lf.lead.source_id-> на справочник источников
	,channelId		= l.channelId
	,callCaseResult = cr.result --Результат звонка
	,callCaseResult_at_time = cr.created_at_time
	,regionId		= l.regionId--Регион  --_LF.lead.[region_id] -> на справочник регионов
	,partnerId		= l.partnerId --Вебмастер --_lf.lead.[partner_id] - > на справочник партнеров
	,phoneTimezone		= naumen_cc.timezone 	--Часовой пояс
	--Регистрация в МП
	,hasRegisterMP = cast(iif(register_MP.username is not null, 1, 0) as bit)
	,leadCreated_at_time	= l.leadCreated_at_time
	,isCompletedRequest = 	cast(iif(r.request is not null, 1,0) as bit)
	,nRow =ROW_NUMBER() over(partition by l.leadId order by cr.created_at_time desc)
	into #t
	from (
		 select top(@rows) 
			leadId					= l.id
			,leadPhone				= l.phone 
			--Источник --_lf.lead.source_id-> на справочник источников
			,sourceId				= l.source_id
			,regionId				= l.region_id
			,partnerId				= l.partner_id
			,leadCreated_at			= l.created_at
			,leadCreated_at_time	= l.created_at_time
			,channelId				= l.mms_channel_id
			from stg._lf.lead l with(nolock)
			
			where l.created_at_time >='2024-05-10'
			and l.phone is not null
	) l 
	left join stg._lf.naumen_call_case cc with(nolock,index = cix_id) 
		on cc.lead_id = l.leadId
		and stg.$partition.[pfn_range_right_date_part_naumen_call_case](cc.[created_at_time])>=
			stg.$partition.[pfn_range_right_date_part_naumen_call_case](l.leadCreated_at_time	)-1
	left join [NaumenDbReport].[dbo].[mv_call_case] naumen_cc with(nolock)
		on naumen_cc.uuid = cc.payload
	left join stg._lf.naumen_call_result cr with(nolock) on 
		cr.naumen_case_id = cc.id
		and stg.$partition.[pfn_range_right_date_part_naumen_call_result](cc.[created_at_time])>=
			stg.$partition.[pfn_range_right_date_part_naumen_call_result](l.leadCreated_at_time	)-1
	left join 
	(
		select username
		from stg._lk.register_MP with(nolock) 
		inner join stg._lk.users u with(nolock) on u.id = register_MP.user_id
		group by username
	) register_MP
		on register_MP.username = l.leadPhone
	left join 
	(
		select original_lead_id
			,request = max(number)
		from stg._lf.request r
		where exists(select top(1) 1 
		from dwh2.[dm].[ЗаявкаНаЗаймПодПТС_СтатусыИСобытия] заявка
		where заявка.НомерЗаявки = r.number
		and coalesce( заявка.[Предварительное одобрение], заявка.Отказано) is not null
		)
		group by original_lead_id
	) r on r.original_lead_id = l.leadId

option(recompile)	

delete from #t
where nRow>1

if OBJECT_ID('Mvp_sales_ml.dbo.dm_lead_ml') is null or @isReCreateTable = 1
begin
	alter table #t
		 drop column nRow

	drop table if exists Mvp_sales_ml.dbo.dm_lead_ml

	select top(0)
		 [leadId]
		, [leadPhone]
		, [sourceId]
		, [channelId]
		, [callCaseResult]
		, [callCaseResult_at_time]
		, [regionId]
		, [partnerId]
		, phoneTimezone
		, [hasRegisterMP]
		, [leadCreated_at_time]
		, isCompletedRequest
		into Mvp_sales_ml.dbo.dm_lead_ml
	from #t
	drop index if exists cix_leadId on dbo.dm_lead_ml
	create clustered index cix_leadId on dbo.dm_lead_ml([leadId])
	drop index if exists ix_leadPhone on dbo.dm_lead_ml
	create index  ix_leadPhone on dbo.dm_lead_ml([leadPhone]) include(leadCreated_at_time)
end
IF COL_LENGTH('[dbo].[dm_lead_ml]','isCompletedRequest') IS NULL
BEGIN
	
	alter table [dbo].[dm_lead_ml]
		add isCompletedRequest bit
END

begin tran
	truncate table dbo.dm_lead_ml
	insert into dbo.dm_lead_ml
	(
		 [leadId]
		, [leadPhone]
		, [sourceId]
		, [channelId]
		, [callCaseResult]
		, [callCaseResult_at_time]
		, [regionId]
		, [partnerId]
		, phoneTimezone
		, [hasRegisterMP]
		, [leadCreated_at_time]
		, isCompletedRequest
	)
	select 
		[leadId]
		, [leadPhone]
		, [sourceId]
		, [channelId]
		, [callCaseResult]
		, [callCaseResult_at_time]
		, [regionId]
		, [partnerId]
		, phoneTimezone
		, [hasRegisterMP]
		, [leadCreated_at_time]
		, isCompletedRequest

	from #t

commit tran
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end
