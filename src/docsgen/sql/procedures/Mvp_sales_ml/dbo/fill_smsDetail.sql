
CREATE   procedure [dbo].[fill_smsDetail]
	@monthAgo int = 3
	,@dayAfter smallint = 0
as
begin
begin try 
	declare @sms_method nvarchar(36) = (select top(1) guid from stg._COMCENTER.methods m
	where LOWER(m.name) = LOWER('sms'))
	select top(10) * from stg._COMCENTER.communications
	declare @tSystems table (SystemId   nvarchar(36) primary key)
	insert into @tSystems 
	select guid from stg._COMCENTER.system_codes
	where code not in ('Space')

	drop table if exists #smsDetail
	select [leadId]
		, lastSendSmsDate	= max(c.created_at) --дата отправки последней sms
		, totalSendSms		= count(c.guid) --Количество отправленных СМС
	into #smsDetail
	from [dbo].[dm_lead_ml] l
	inner join stg._COMCENTER.contacts_methods cm
		on cm.value = l.leadPhone
		and cm.method_guid = @sms_method
	inner join stg._COMCENTER.communications c on c.contact_method_guid = cm.guid
		and c.created_at between  dateadd(mm, -@monthAgo,l.leadCreated_at_time  )  and dateadd(dd,@dayAfter, l.leadCreated_at_time)
		and exists(select top(1) 1 from @tSystems systems 
		where 	systems.SystemId = c.system_code_guid 	)

	group by [leadId]
	option (recompile)
	create index cix_leadId on #smsDetail([leadId])


	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastSendSmsDate') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add lastSendSmsDate datetime
	END
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalSendSms') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add totalSendSms int
	END


	begin tran
		update t
			set lastSendSmsDate = sd.lastSendSmsDate
				,totalSendSms = sd.totalSendSms
		from [dbo].[dm_lead_ml]  t
		left join #smsDetail sd on sd.leadId = t.leadId
	commit tran

end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end



