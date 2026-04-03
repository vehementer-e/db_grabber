

-- =============================================
-- Author:		A.Kotelevec
-- Create date: <Create Date,,>
-- Description:	DWH-805 Заполнение отдельных таблиц с кейсами и сессиями повторников и докредо
-- =============================================
CREATE   PROCEDURE [dbo].[fill_dm_report_commissions_detail_outbound_sessions]
	@reloadDay int = 14
	as
BEGIN

drop table if exists #NaumenProjects
select [ProjectUUID] into #NaumenProjects FROM [Stg].[_mds].[NaumenProjects_commissions_prod]
drop table if exists #t_data
			select
				[session_id], 
				[case_uuid], 
				[attempt_start], 
				[attempt_end], 
				[number_type], 
				[client_number], 
				[out_number], 
				[pickup_time], 
				[queue_time], 
				[operator_pickup_time], 
				[speaking_time], 
				[wrapup_time], 
				[login], 
				[attempt_result], 
				[voip_reason], 
				[hangup_initiator], 
				[dialer_mode], 
				[attempt_number], 
				[sort_segment], 
				[amd_pattern], 
				[project_id], 
				[holds], 
				[hold_time]
into #t_data
from NaumenDbReport.dbo.detail_outbound_sessions dos with(nolock)

where exists (select top(1) 1 
from #NaumenProjects t
where dos.project_id = t.ProjectUUID
)
and cast([attempt_start] as date) > =cast(dateadd(dd, - @reloadDay, getdate()) as date)


	declare @dt datetime=getdate()
	declare @batcSize int =100000

	begin try
		if OBJECT_ID('dbo.dm_report_commissions_detail_outbound_sessions') is null
		begin
			select top(0)
			* 
			,[loaded_into_reports] = @dt
			into dbo.dm_report_commissions_detail_outbound_sessions
			from #t_data
		end
		
		begin tran
			delete top(@batcSize) from dbo.dm_report_commissions_detail_outbound_sessions
			where cast([attempt_start] as date) > =cast(dateadd(dd, - @reloadDay, getdate()) as date)
			
			
			while @@ROWCOUNT > 0
			BEGIN
				delete top(@batcSize) from dbo.dm_report_commissions_detail_outbound_sessions
				where cast([attempt_start] as date) > =cast(dateadd(dd, - @reloadDay, getdate()) as date)

			END
			
			insert into dbo.dm_report_commissions_detail_outbound_sessions(
				[session_id], 
				[case_uuid], 
				[attempt_start], 
				[attempt_end], 
				[number_type], 
				[client_number], 
				[out_number], 
				[pickup_time], 
				[queue_time], 
				[operator_pickup_time], 
				[speaking_time], 
				[wrapup_time], 
				[login], 
				[attempt_result], 
				[voip_reason], 
				[hangup_initiator], 
				[dialer_mode], 
				[attempt_number], 
				[sort_segment], 
				[amd_pattern], 
				[project_id], 
				[holds], 
				[hold_time], 
				[loaded_into_reports]
			
			)
			select
				[session_id], 
				[case_uuid], 
				[attempt_start], 
				[attempt_end], 
				[number_type], 
				[client_number], 
				[out_number], 
				[pickup_time], 
				[queue_time], 
				[operator_pickup_time], 
				[speaking_time], 
				[wrapup_time], 
				[login], 
				[attempt_result], 
				[voip_reason], 
				[hangup_initiator], 
				[dialer_mode], 
				[attempt_number], 
				[sort_segment], 
				[amd_pattern], 
				[project_id], 
				[holds], 
				[hold_time], 
				[loaded_into_reports] = @dt
			from #t_data
		commit tran
	end try
	begin catch
		IF XACT_STATE() <>0
		BEGIN
			ROLLBACK TRAN
		END
		;throw
	end catch
END
