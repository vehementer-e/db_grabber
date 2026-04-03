
-- =============================================
-- Author:		A.Kotelevec
-- Create date: <Create Date,,>
-- Description:	DWH-805 Заполнение отдельных таблиц с кейсами и сессиями повторников и докредо
-- =============================================
CREATE PROCEDURE [dbo].[fill_dm_report_DIP_detail_outbound_sessions]
	@reloadDay int = 14
	as
BEGIN

drop table if exists #NaumenProjects_DokrNPovt_prod
select [ProjectUUID] into #NaumenProjects_DokrNPovt_prod FROM [Stg].[_mds].[NaumenProjects_DokrNPovt_prod]
union
select  project_id
		from (values
				('corebo00000000000mm1tts6og6rs2fk') --Докреды					--old
				,('corebo00000000000n25qgnvfnogtjf8') --Докреды Новые			--old
				,('corebo00000000000n25qereimll7884') --Докреды Перезвоны		--old
				,('corebo00000000000mn2eg74l4nb9950') --Повторные - Перезвоны	--old


				,('corebo00000000000palme673n6njdhs') --CRM Повторные					--new
				,('corebo00000000000pallp7sskqdpifo') --CRM Докреды			--new
				,('corebo00000000000pallps4t1qi8prs') --CRM Докреды Перезвоны		--new
				,('corebo00000000000palmf0r7gh7c2m8') --CRM Повторные - Перезвоны	--new

				,('corebo00000000000oe3p1ashjvi3rho')--код проекта по повторникам инстолмент
				,('corebo00000000000oe3p4rec7ip91ks')--Перезвоны по повторникам
				--new
				,('corebo00000000000palmbv48njpfhp8') --CRM Повторники Инст
				,('corebo00000000000palmcvs9gpenh84') --CRM Повторники Инст Перезвон



			) t(project_id)
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
from NaumenDbReport.dbo.detail_outbound_sessions with(nolock)

where project_id in( 
select ProjectUUID from #NaumenProjects_DokrNPovt_prod)
and cast([attempt_start] as date) > =cast(dateadd(dd, - @reloadDay, getdate()) as date)


	declare @dt datetime=getdate()
	declare @batcSize int =100000

	begin try
		begin tran
			delete top(@batcSize) from dbo.dm_report_DIP_detail_outbound_sessions
			where cast([attempt_start] as date) > =cast(dateadd(dd, - @reloadDay, getdate()) as date)
			
			
			while @@ROWCOUNT > 0
			BEGIN
				delete top(@batcSize) from dbo.dm_report_DIP_detail_outbound_sessions
				where cast([attempt_start] as date) > =cast(dateadd(dd, - @reloadDay, getdate()) as date)

			END
			
			insert into dbo.dm_report_DIP_detail_outbound_sessions(
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
