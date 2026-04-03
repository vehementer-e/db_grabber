CREATE   procedure [dbo].[fill_incomingCallDetail]
	 @monthAgo smallint = 3
	 ,@dayAfter smallint = 0
as
begin
declare @minDuration int = 3
begin try
	drop table if exists #incomingCallDetail
	select
		leadId
		,lastIncomingCall
		,uniqueIncomingCallDate = t_dd.incomingCallDate
		,totalIncomingCall
	into #incomingCallDetail
	from (select 
		leadId
		,lastIncomingCall = max(dateadd(year,-2000, тз.Дата))
		,incomingCallDate = STRING_AGG(cast(dateadd(year,-2000, тз.Дата) as date), ';')
		,totalIncomingCall = count(1) 
	from dbo.dm_lead_ml l
	inner join stg._1cCRM.Документ_ТелефонныйЗвонок тз
		on тз.АбонентКакСвязаться = l.leadPhone
		and тз.Входящий = 0x01
		and dateadd(year,-2000, тз.Дата)  between dateadd(mm, -@monthAgo, l.leadCreated_at_time) and dateadd(dd,@dayAfter,l.leadCreated_at_time)
		and сфпДлительностьЗвонка >@minDuration
	group by leadId
	) t
	outer apply 
	(
		
		select  incomingCallDate = string_agg(value, ';')
		from (select  distinct value
		from string_split(t.incomingCallDate,';')
		--for xml path('')))),1,1,''))
		) t
	) t_dd
	option (recompile)
	create clustered index cix on #incomingCallDetail(leadId)

	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastIncomingCall') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add lastIncomingCall datetime
	END
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalIncomingCall') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add totalIncomingCall int
	END
	IF COL_LENGTH('[dbo].[dm_lead_ml]','uniqueIncomingCallDate') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add uniqueIncomingCallDate nvarchar(max)
	END


	begin tran
		update t
			set lastIncomingCall = icd.lastIncomingCall
				,totalIncomingCall = icd.totalIncomingCall
				,uniqueIncomingCallDate = icd.uniqueIncomingCallDate
		from [dbo].[dm_lead_ml]  t
		left join #incomingCallDetail icd on icd.leadId = t.leadId
	commit tran

end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end
