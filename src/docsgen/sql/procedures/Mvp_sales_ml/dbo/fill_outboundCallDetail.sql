
CREATE   procedure [dbo].[fill_outboundCallDetail]
	@monthAgo smallint = 3
	,@dayAfter smallint = 0

as
begin
declare @minDuration int = 3
begin try


	create table #project(projectId nvarchar(255) primary  key)
	insert into #project(projectId)
	select distinct 
	IdExternal
	from feodor.dbo.dm_feodor_projects
	where id>0
	drop table if exists #outboundCallDetail
	
	select 
		t.leadId
		,totalCallsWithLogin			
		,totalCallsWithSession_id	
		,totalCallsWithConnected 	
		,maxSpeakingTime			
		,minSpeakingTime			
		,avgSpeakingTime			
		,avgPickupTime				
		,medianSpeakingTime			
		,medianPickupTime			
		,lastConnectedDateTIme			
		,lastSessionDateTime			
		,lastSpeakingTime
		,lastConnectedTime
		,totalCallsWithSessionResult_Connected						
		,lastCallWithSessionResult_Connected_DateTime				
		,totalCallsWithSessionResult_NonTarget						
		,lastCallWithSessionResult_NonTarget_DateTime				
		,totalCallsWithSessionResult_Amd_cti						
		,lastCallWithSessionResult_Amd_cti_DateTime					
		,totalCallsWithSessionResult_Transfer						
		,lastCallWithSessionResult_Transfer_DateTime				
		,totalCallsWithSessionResult_MP								
		,lastCallWithSessionResult_MP_DateTime						
		,totalCallsWithSessionResult_UNKNOWN_ERROR					
		,lastCallWithSessionResult_UNKNOWN_ERROR_DateTime			
		,totalCallsWithSessionResult_Not_found						
		,lastCallWithSessionResult_Not_found_DateTime				
		,totalCallsWithSessionResult_CallDisconnect					
		,lastCallWithSessionResult_CallDisconnect_DateTime			
		,totalCallsWithSessionResult_Busy							
		,lastCallWithSessionResult_Busy_DateTime					
		,totalCallsWithSessionResult_No_answer						
		,lastCallWithSessionResult_No_answer_DateTime				
		,totalCallsWithSessionResult_Abandoned						
		,lastCallWithSessionResult_Abandoned_DateTime				
		,totalCallsWithSessionResult_Operator_no_answer				
		,lastCallWithSessionResult_Operator_no_answer_DateTime		
		,totalCallsWithSessionResult_Amd							
		,lastCallWithSessionResult_Amd_DateTime						
		,totalCallsWithSessionResult_Consent						
		,lastCallWithSessionResult_Consent_DateTime					
		,totalCallsWithSessionResult_Consultation					
		,lastCallWithSessionResult_Consultation_DateTime			
		,totalCallsWithSessionResult_RefuseClient					
		,lastCallWithSessionResult_RefuseClient_DateTime			
		,totalCallsWithSessionResult_RecallRequest					
		,lastCallWithSessionResult_RecallRequest_DateTime			
		,totalCallsWithSessionResult_LKK							
		,lastCallWithSessionResult_LKK_DateTime						
		,totalCallsWithSessionResult_Operator_rejected				
		,lastCallWithSessionResult_Operator_rejected_DateTime		
	into #outboundCallDetail
	from 
	(select 
		t.leadId
		,totalCallsWithLogin		= sum(iif(t.login is not null, 1,0)) --Кол. Дозвон
		,totalCallsWithSession_id	= sum(iif(t.session_id is not null, 1, 0)) --Кол. Соединение
		,totalCallsWithConnected 	= sum(iif(t.connectedDateTime  is not null, 1, 0))--Кол. звонков
		,maxSpeakingTime			= max(t.speaking_time) --Максимальная длительность разговора
		,minSpeakingTime			= min(t.speaking_time) --Минимальная длительность разговора
		,avgSpeakingTime			= avg(cast(t.speaking_time as money)) --Средняя длительность разговора 
		,avgPickupTime				= avg(cast(t.pickup_time	 as money))  --Среднее время ответа на звонок
		,medianSpeakingTime			= max(t.medianSpeakingTime)--Медиана длительность разговора 
		,medianPickupTime			= max(t.medianPickupTime)--Медиана время, через которое клиент отвечает на звонок. pickup_time
		,lastConnectedDateTime		= max(lastConnectedDateTIme)--Дата последнего звонка у которого (connected is not null)
		,lastSessionDateTime		= max(lastSessionDateTime)--дата последнего звонка
		,lastSpeakingTime	= max (case when t.attempt_start = t.lastSessionDateTime
				then t.speaking_time
				end)
		--Дата последнего звонка у которого (connected is not null)
		,lastConnectedTime	= max (case when connectedDateTime = t.lastConnectedDateTIme
				then t.connectedTime
				end)
		,totalCallsWithSessionResult_Connected						= count(iif(attempt_result = 'connected'			, session_id, null))
		,lastCallWithSessionResult_Connected_DateTime				= max(iif(attempt_result = 'connected'				, attempt_start, null))	
		,totalCallsWithSessionResult_NonTarget						= count(iif(attempt_result = 'nonTarget'			, session_id, null))
		,lastCallWithSessionResult_NonTarget_DateTime				= max(iif(attempt_result = 'nonTarget'				, attempt_start, null))	
		,totalCallsWithSessionResult_Amd_cti						= count(iif(attempt_result = 'amd_cti'				, session_id, null))
		,lastCallWithSessionResult_Amd_cti_DateTime					= max(iif(attempt_result = 'amd_cti'				, attempt_start, null))	
		,totalCallsWithSessionResult_Transfer						= count(iif(attempt_result = 'transfer'				, session_id, null))
		,lastCallWithSessionResult_Transfer_DateTime				= max(iif(attempt_result = 'transfer'				, attempt_start, null))	
		,totalCallsWithSessionResult_MP								= count(iif(attempt_result = 'MP'					, session_id, null))
		,lastCallWithSessionResult_MP_DateTime						= max(iif(attempt_result = 'MP'						, attempt_start, null))	
		,totalCallsWithSessionResult_UNKNOWN_ERROR					= count(iif(attempt_result = 'UNKNOWN_ERROR'		, session_id, null))
		,lastCallWithSessionResult_UNKNOWN_ERROR_DateTime			= max(iif(attempt_result = 'UNKNOWN_ERROR'			, attempt_start, null))	
		,totalCallsWithSessionResult_Not_found						= count(iif(attempt_result = 'not_found'			, session_id, null))
		,lastCallWithSessionResult_Not_found_DateTime				= max(iif(attempt_result = 'not_found'				, attempt_start, null))	
		,totalCallsWithSessionResult_CallDisconnect					= count(iif(attempt_result = 'CallDisconnect'		, session_id, null))
		,lastCallWithSessionResult_CallDisconnect_DateTime			= max(iif(attempt_result = 'CallDisconnect'			, attempt_start, null))	
		,totalCallsWithSessionResult_Busy							= count(iif(attempt_result = 'busy'					, session_id, null))
		,lastCallWithSessionResult_Busy_DateTime					= max(iif(attempt_result = 'busy'					, attempt_start, null))	
		,totalCallsWithSessionResult_No_answer						= count(iif(attempt_result = 'no_answer'			, session_id, null))
		,lastCallWithSessionResult_No_answer_DateTime				= max(iif(attempt_result = 'no_answer'				, attempt_start, null))	
		,totalCallsWithSessionResult_Abandoned						= count(iif(attempt_result = 'abandoned'			, session_id, null))
		,lastCallWithSessionResult_Abandoned_DateTime				= max(iif(attempt_result = 'abandoned'				, attempt_start, null))	
		,totalCallsWithSessionResult_Operator_no_answer				= count(iif(attempt_result = 'operator_no_answer'	, session_id, null))
		,lastCallWithSessionResult_Operator_no_answer_DateTime		= max(iif(attempt_result = 'operator_no_answer'		, attempt_start, null))	
		,totalCallsWithSessionResult_Amd							= count(iif(attempt_result = 'amd'					, session_id, null))
		,lastCallWithSessionResult_Amd_DateTime						= max(iif(attempt_result = 'amd'					, attempt_start, null))	
		,totalCallsWithSessionResult_Consent						= count(iif(attempt_result = 'Consent'				, session_id, null))
		,lastCallWithSessionResult_Consent_DateTime					= max(iif(attempt_result = 'Consent'				, attempt_start, null))	
		,totalCallsWithSessionResult_Consultation					= count(iif(attempt_result = 'consultation'			, session_id, null))
		,lastCallWithSessionResult_Consultation_DateTime			= max(iif(attempt_result = 'consultation'			, attempt_start, null))	
		,totalCallsWithSessionResult_RefuseClient					= count(iif(attempt_result = 'refuseClient'			, session_id, null))
		,lastCallWithSessionResult_RefuseClient_DateTime			= max(iif(attempt_result = 'refuseClient'			, attempt_start, null))	
		,totalCallsWithSessionResult_RecallRequest					= count(iif(attempt_result = 'recallRequest'		, session_id, null))
		,lastCallWithSessionResult_RecallRequest_DateTime			= max(iif(attempt_result = 'RecallRequest'			, attempt_start, null))	
		,totalCallsWithSessionResult_LKK							= count(iif(attempt_result = 'LKK'					, session_id, null))
		,lastCallWithSessionResult_LKK_DateTime						= max(iif(attempt_result = 'LKK'					, attempt_start, null))	
		,totalCallsWithSessionResult_Operator_rejected				= count(iif(attempt_result = 'operator_rejected'	, session_id, null))
		,lastCallWithSessionResult_Operator_rejected_DateTime		= max(iif(attempt_result = 'operator_rejected'		, attempt_start, null))	
	from (select 
		 l.leadId
		,dos.login 
		,dos.session_id
		,connectedDateTime = cl.connected 
		,dos.speaking_time
		,dos.pickup_time
		,dos.attempt_end
		,dos.attempt_result
		,connectedTime =  iif(cl.connected is not null, datediff(second, cl.connected, dos.attempt_end), null)
		,dos.attempt_start
		,medianSpeakingTime = PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cast(dos.speaking_time as money))
			OVER (PARTITION BY l.leadId)
		,medianPickupTime = PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cast(dos.pickup_time as money))
			OVER (PARTITION BY l.leadId)
		,lastSessionDateTime	= max(iif(dos.session_id is not null, dos.attempt_start, null)) over(partition by l.leadId)
		,lastConnectedDateTIme  = max(iif(cl.connected  is not null, cl.connected, null)) over(partition by l.leadId)
	from dbo.dm_lead_ml l
	inner join NaumenDbReport.dbo.detail_outbound_sessions dos  (NOLOCK)
		--with(index = [ix_attempt_start_3])
		on dos.client_number = concat('8', l.leadPhone)
		and exists(select top(1) 1 from #project p where p.projectId = dos.project_id)
	and dos.attempt_start between DATEADD(mm, -@monthAgo, l.leadCreated_at_time)
		and dateadd(dd,@dayAfter, l.leadCreated_at_time)
	and [NaumenDbReport].$partition.[pfn_range_right_date_part_detail_outbound_sessions](dos.attempt_start)
	between [NaumenDbReport].$partition.[pfn_range_right_date_part_detail_outbound_sessions](DATEADD(mm, -@monthAgo, l.leadCreated_at_time))
		and [NaumenDbReport].$partition.[pfn_range_right_date_part_detail_outbound_sessions](dateadd(dd,@dayAfter, l.leadCreated_at_time))
	inner JOIN NaumenDbReport.dbo.call_legs AS cl (NOLOCK)
			--with(index = [idx_leg_id_session_id])
			ON    cl.session_id = dos.session_id    
			AND cl.leg_id = 1 
			and NaumenDbReport.$partition.[pfn_range_right_date_part_call_legs](cl.[created])
				=[NaumenDbReport].$partition.[pfn_range_right_date_part_call_legs](dos.attempt_start)
	 ) t
	group by leadId
	) t
	option (recompile)
	

	
		
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithLogin') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add totalCallWithLogin int
	END
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSession_id') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add totalCallWithSession_id int
	END
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithConnected') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add totalCallWithConnected int
	END
	IF COL_LENGTH('[dbo].[dm_lead_ml]','maxSpeakingTime') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add maxSpeakingTime int
	END
	IF COL_LENGTH('[dbo].[dm_lead_ml]','minSpeakingTime') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add minSpeakingTime	int
	END			
	IF COL_LENGTH('[dbo].[dm_lead_ml]','avgSpeakingTime') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add avgSpeakingTime	money
	END
	IF COL_LENGTH('[dbo].[dm_lead_ml]','avgPickupTime') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add avgPickupTime	 money
	END
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastConnectedDateTIme') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add lastConnectedDateTIme	 datetime
	END				
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastSessionDateTime') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add lastSessionDateTime	 datetime
	END		
	IF COL_LENGTH('[dbo].[dm_lead_ml]','percentageOfSuccessfulCalls') IS NULL
	BEGIN
		--Процент успешных звонков (соединение) Кол. Соединение / Кол. звонков ранее
		alter table [dbo].[dm_lead_ml]
			add percentageOfSuccessfulCalls	 as cast(totalCallsWithConnected*1.0/nullif(totalCallsWithSession_id,0) as money)
	END		
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastSpeakingTime') IS NULL
	BEGIN
		
		alter table [dbo].[dm_lead_ml]
			add lastSpeakingTime int 
	END	
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastConnectedTime') IS NULL
	BEGIN
		alter table [dbo].[dm_lead_ml]
			add lastConnectedTime int 
	END	

	IF COL_LENGTH('[dbo].[dm_lead_ml]','medianSpeakingTime') IS NULL
	BEGIN
		
		alter table [dbo].[dm_lead_ml]
			add medianSpeakingTime money 
	END	
	IF COL_LENGTH('[dbo].[dm_lead_ml]','medianPickupTime') IS NULL
	BEGIN
		
		alter table [dbo].[dm_lead_ml]
			add medianPickupTime money 
	END
	
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_Connected') IS NULL
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_Connected			int	
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_NonTarget') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_NonTarget			int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_Amd_cti') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_Amd_cti				int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_Transfer') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_Transfer			int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_MP') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_MP					int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_UNKNOWN_ERROR') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_UNKNOWN_ERROR		int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_Not_found') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_Not_found			int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_CallDisconnect') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_CallDisconnect		int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_Busy') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_Busy				int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_No_answer') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_No_answer			int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_Abandoned') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_Abandoned			int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_Operator_no_answer') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_Operator_no_answer 	int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_Amd') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_Amd					int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_Consent') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_Consent				int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_Consultation') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_Consultation		int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_RefuseClient') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_RefuseClient		int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_RecallRequest') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_RecallRequest		int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_LKK') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_LKK					int
	IF COL_LENGTH('[dbo].[dm_lead_ml]','totalCallsWithSessionResult_operator_rejected') IS NULL 
		alter table [dbo].[dm_lead_ml] add totalCallsWithSessionResult_operator_rejected	int


	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_Connected_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_Connected_DateTime			datetime		
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_NonTarget_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_NonTarget_DateTime			datetime			
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_Amd_cti_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_Amd_cti_DateTime				datetime	
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_Transfer_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_Transfer_DateTime				datetime		
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_MP_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_MP_DateTime					datetime			
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_UNKNOWN_ERROR_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_UNKNOWN_ERROR_DateTime		datetime			
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_Not_found_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_Not_found_DateTime			datetime			
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_CallDisconnect_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_CallDisconnect_DateTime		datetime			
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_Busy_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_Busy_DateTime					datetime		
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_No_answer_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_No_answer_DateTime			datetime		
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_Abandoned_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_Abandoned_DateTime			datetime		
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_Operator_no_answer_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_Operator_no_answer_DateTime	datetime	
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_Amd_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_Amd_DateTime					datetime			
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_Consent_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_Consent_DateTime				datetime			
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_Consultation_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_Consultation_DateTime			datetime		
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_RefuseClient_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_RefuseClient_DateTime			datetime		
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_RecallRequest_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_RecallRequest_DateTime		datetime			
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_LKK_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_LKK_DateTime					datetime					
	IF COL_LENGTH('[dbo].[dm_lead_ml]','lastCallWithSessionResult_Operator_rejected_DateTime') IS NULL 
		alter table [dbo].[dm_lead_ml]	add lastCallWithSessionResult_Operator_rejected_DateTime	datetime	

	
	begin tran
		update t
			set	
				 totalCallsWithLogin										= s.totalCallsWithLogin
				,totalCallsWithSession_id									= s.totalCallsWithSession_id
				,totalCallsWithConnected									= s.totalCallsWithConnected
				,maxSpeakingTime											= s.maxSpeakingTime
				,minSpeakingTime											= s.minSpeakingTime
				,avgSpeakingTime											= s.avgSpeakingTime
				,avgPickupTime												= s.avgPickupTime
				,lastConnectedDateTime										= s.lastConnectedDateTIme
				,lastSessionDateTime										= s.lastSessionDateTime
				,lastConnectedTime											= s.lastConnectedTime
				,lastSpeakingTime											= s.lastSpeakingTime
				,medianPickupTime											= s.medianPickupTime
				,medianSpeakingTime											= s.medianSpeakingTime
				,totalCallsWithSessionResult_Connected						= s.totalCallsWithSessionResult_Connected						
				,lastCallWithSessionResult_Connected_DateTime				= s.lastCallWithSessionResult_Connected_DateTime				
				,totalCallsWithSessionResult_NonTarget						= s.totalCallsWithSessionResult_NonTarget						
				,lastCallWithSessionResult_NonTarget_DateTime				= s.lastCallWithSessionResult_NonTarget_DateTime				
				,totalCallsWithSessionResult_Amd_cti						= s.totalCallsWithSessionResult_Amd_cti						
				,lastCallWithSessionResult_Amd_cti_DateTime					= s.lastCallWithSessionResult_Amd_cti_DateTime					
				,totalCallsWithSessionResult_Transfer						= s.totalCallsWithSessionResult_Transfer						
				,lastCallWithSessionResult_Transfer_DateTime				= s.lastCallWithSessionResult_Transfer_DateTime				
				,totalCallsWithSessionResult_MP								= s.totalCallsWithSessionResult_MP								
				,lastCallWithSessionResult_MP_DateTime						= s.lastCallWithSessionResult_MP_DateTime						
				,totalCallsWithSessionResult_UNKNOWN_ERROR					= s.totalCallsWithSessionResult_UNKNOWN_ERROR					
				,lastCallWithSessionResult_UNKNOWN_ERROR_DateTime			= s.lastCallWithSessionResult_UNKNOWN_ERROR_DateTime			
				,totalCallsWithSessionResult_Not_found						= s.totalCallsWithSessionResult_Not_found						
				,lastCallWithSessionResult_Not_found_DateTime				= s.lastCallWithSessionResult_Not_found_DateTime				
				,totalCallsWithSessionResult_CallDisconnect					= s.totalCallsWithSessionResult_CallDisconnect					
				,lastCallWithSessionResult_CallDisconnect_DateTime			= s.lastCallWithSessionResult_CallDisconnect_DateTime			
				,totalCallsWithSessionResult_Busy							= s.totalCallsWithSessionResult_Busy							
				,lastCallWithSessionResult_Busy_DateTime					= s.lastCallWithSessionResult_Busy_DateTime					
				,totalCallsWithSessionResult_No_answer						= s.totalCallsWithSessionResult_No_answer						
				,lastCallWithSessionResult_No_answer_DateTime				= s.lastCallWithSessionResult_No_answer_DateTime				
				,totalCallsWithSessionResult_Abandoned						= s.totalCallsWithSessionResult_Abandoned						
				,lastCallWithSessionResult_Abandoned_DateTime				= s.lastCallWithSessionResult_Abandoned_DateTime				
				,totalCallsWithSessionResult_Operator_no_answer				= s.totalCallsWithSessionResult_Operator_no_answer				
				,lastCallWithSessionResult_Operator_no_answer_DateTime		= s.lastCallWithSessionResult_Operator_no_answer_DateTime		
				,totalCallsWithSessionResult_Amd							= s.totalCallsWithSessionResult_Amd							
				,lastCallWithSessionResult_Amd_DateTime						= s.lastCallWithSessionResult_Amd_DateTime						
				,totalCallsWithSessionResult_Consent						= s.totalCallsWithSessionResult_Consent						
				,lastCallWithSessionResult_Consent_DateTime					= s.lastCallWithSessionResult_Consent_DateTime					
				,totalCallsWithSessionResult_Consultation					= s.totalCallsWithSessionResult_Consultation					
				,lastCallWithSessionResult_Consultation_DateTime			= s.lastCallWithSessionResult_Consultation_DateTime			
				,totalCallsWithSessionResult_RefuseClient					= s.totalCallsWithSessionResult_RefuseClient					
				,lastCallWithSessionResult_RefuseClient_DateTime			= s.lastCallWithSessionResult_RefuseClient_DateTime			
				,totalCallsWithSessionResult_RecallRequest					= s.totalCallsWithSessionResult_RecallRequest					
				,lastCallWithSessionResult_RecallRequest_DateTime			= s.lastCallWithSessionResult_RecallRequest_DateTime			
				,totalCallsWithSessionResult_LKK							= s.totalCallsWithSessionResult_LKK							
				,lastCallWithSessionResult_LKK_DateTime						= s.lastCallWithSessionResult_LKK_DateTime						
				,totalCallsWithSessionResult_Operator_rejected				= s.totalCallsWithSessionResult_Operator_rejected				
				,lastCallWithSessionResult_Operator_rejected_DateTime		= s.lastCallWithSessionResult_Operator_rejected_DateTime		


		from dbo.dm_lead_ml t
		left join #outboundCallDetail s on s.leadId = t.leadId
	commit tran
	
end try
begin catch
	if @@TRANCOUNT>0
		rollback tran
	;throw
end catch
end
