-- =============================================
-- Author:		Shubkin Aleksandr 
-- Create date: 21.01.2026
-- Description:	Процедура для заполнения/обновления dm
--				для отчета по входящей линии | dwh-418
-- USAGE:		exec [service].[fill_dm_report_inboundCalls_agg_NEW] @dtFrom = '2026-02-01', @dtTo = '2026-02-26' , @isDebug = 0
-- CHECK: select * from service.dm_report_inboundCalls_agg_new
-- =============================================
-- @changelog | sh.a.a. | 04.02.2026 | DWH-463 | Доработка отчета по входящей линии
-- =============================================
CREATE       PROCEDURE [service].[fill_dm_report_inboundCalls_agg_NEW] 
	@dtFrom date = NULL,
	@dtTo	date = NULL,
	@isDebug bit = 0
AS
BEGIN
	SET NOCOUNT ON;

	IF @dtFrom is null
	BEGIN
		declare @maxDt date;
		select @maxDt = MAX([Дата])
		FROM service.dm_report_inboundCalls_agg_new
		SET @dtTo   = dateadd(dd,1, cast(getdate() as date));		/*переписать, использовать дату из service.dm_report_inboundCalls_agg + 1 день */
		SET @dtFrom = DATEADD(day, -3, @maxDt);
	END

	if @isDebug = 1
	begin
		select @dtTo as dtTo
		select @dtFrom as dtFrom
	end
	-- Просто список всех входящих
	DROP TABLE IF EXISTS #t_inbound;
	SELECT
		session_id = cl.session_id,
		call_date  = cast(cl.created as date),
		client_number = try_cast(right(cl.src_id, 10) as bigint),
		created    = cl.created,
		dst_id	   = cl.dst_id,
		dst_id_name = CASE
						WHEN cl.dst_id IN ('84999290048', '8007004637', '84992710723', '8007004370') THEN 'ПСБ'
						WHEN cl.dst_id LIKE '60[0-9][0-9]' AND LEN(cl.dst_id) = 4 THEN NULL   -- короткие пока нул
						ELSE 'CarMoney'
					END
		-- is_callback = case when cl.dst_id in ('6000', '6034') then 1 else 0 end,
		-- is_short60 = case when LEN(cl.dst_id)	= 4 and cl.dst_id like '60%'  then 1 else 0 end
	INTO #t_inbound
	FROM NaumenDbReport.dbo.call_legs as cl	 
	WHERE 1=1
	AND NaumenDbReport.$PARTITION.[pfn_range_right_date_part_dbo_call_legs](cl.created) >=   NaumenDbReport.$PARTITION.[pfn_range_right_date_part_dbo_call_legs](@dtFrom)
		AND NaumenDbReport.$PARTITION.[pfn_range_right_date_part_dbo_call_legs](cl.created) <=   NaumenDbReport.$PARTITION.[pfn_range_right_date_part_dbo_call_legs](@dtTo)
		AND cl.created >= @dtFrom
		AND cl.created <  @dtTo
		--AND cl.leg_id >= 1
		AND cl.leg_id = 1
		AND cl.src_abonent IS NULL
		and session_id  ='node_0_domain_0_nauss_0_1769714642_680366'; 

	 CREATE CLUSTERED INDEX CX_session_id ON #t_inbound(session_id)
	
	-- срез по дате по обоим табличкам
	DROP TABLE IF EXISTS #t_cl;
	SELECT
	    session_id      = cl.session_id,
	    leg_id          = cl.leg_id,
	    dst_id          = cl.dst_id,
	    src_id          = cl.src_id,
	    created         = cl.created,
	    connected       = cl.connected,
	    ended           = cl.ended,
	    pickedup        = cl.pickedup
	INTO #t_cl
	FROM NaumenDbReport.dbo.call_legs AS cl	 --with(index = [idx_leg_id_session_id]) 
	WHERE 1 = 1											
	  AND EXISTS
	  (
	      SELECT 1
	      FROM #t_inbound AS ib
	      WHERE ib.session_id = cl.session_id
	  )
	  AND cl.leg_id >= 1; 
	
	CREATE CLUSTERED INDEX CX_session_id_leg_id ON #t_cl (session_id, leg_id);

	-- очередь
	DROP TABLE IF EXISTS #qc_raw;
	SELECT
		qc.session_id,
		qc.enqueued_time,
		qc.unblocked_time,
		qc.dequeued_time,
		qc.final_stage,
		qc.project_id,
		wait_time_sec =
			CASE
				WHEN qc.unblocked_time IS NOT NULL
					 AND qc.dequeued_time IS NOT NULL
					 AND qc.dequeued_time >= qc.unblocked_time
				THEN DATEDIFF(SECOND, qc.unblocked_time, qc.dequeued_time)
				ELSE 0
			END
	INTO #qc_raw
	FROM NaumenDbReport.dbo.queued_calls qc
	WHERE 1 = 1
	  AND NaumenDbReport.$PARTITION.[pfn_range_right_date_part_dbo_queued_calls](qc.enqueued_time)
			>= NaumenDbReport.$PARTITION.[pfn_range_right_date_part_dbo_queued_calls](@dtFrom)
	  AND NaumenDbReport.$PARTITION.[pfn_range_right_date_part_dbo_queued_calls](qc.enqueued_time)
			<= NaumenDbReport.$PARTITION.[pfn_range_right_date_part_dbo_queued_calls](@dtTo)
	  AND qc.enqueued_time >= @dtFrom
	  AND qc.enqueued_time <  @dtTo
	  AND EXISTS (SELECT 1 FROM #t_inbound ib WHERE ib.session_id = qc.session_id);

	CREATE INDEX IX_qc_raw ON #qc_raw(session_id, enqueued_time);

	DROP TABLE IF EXISTS #t_queue_events;
	SELECT
		session_id,
		enqueued_time,
		unblocked_time,
		dequeued_time,
		final_stage,
		project_id = MIN(project_id),
		wait_time_sec = MAX(wait_time_sec)
	INTO #t_queue_events
	FROM #qc_raw
	GROUP BY
		session_id,
		enqueued_time,
		unblocked_time,
		dequeued_time,
		final_stage;

	CREATE INDEX IX_t_queue_events ON #t_queue_events(session_id, enqueued_time);
	--

	-- для валидного проджект айди пронумеруем выходы в сессию
	DROP TABLE IF EXISTS #t_queue_events_rn;
	SELECT
		t.*,
		queue_event_no = ROW_NUMBER() OVER (
			PARTITION BY t.session_id
			ORDER BY t.enqueued_time--, t.unblocked_time, t.dequeued_time
		)
	INTO #t_queue_events_rn
	FROM #t_queue_events t;

	CREATE CLUSTERED INDEX CX_t_queue_events_rn ON #t_queue_events_rn(session_id, queue_event_no);

	DROP TABLE IF EXISTS #t_queue_metrics_session;
	SELECT
		e.session_id,
		operator_events_cnt = SUM(CASE WHEN e.final_stage = 'operator' THEN 1 ELSE 0 END),
		operator_lt20_cnt   = SUM(CASE WHEN e.final_stage = 'operator' AND e.wait_time_sec < 20 THEN 1 ELSE 0 END),
		operator_ge20_cnt   = SUM(CASE WHEN e.final_stage = 'operator' AND e.wait_time_sec >= 20 THEN 1 ELSE 0 END),
		lost_events_cnt     = SUM(CASE WHEN e.final_stage IN ('ivr','queue') THEN 1 ELSE 0 END),
		lost_lt20_cnt       = SUM(CASE WHEN e.final_stage IN ('ivr','queue') AND e.wait_time_sec < 20 THEN 1 ELSE 0 END),
		lost_ge20_cnt       = SUM(CASE WHEN e.final_stage IN ('ivr','queue') AND e.wait_time_sec >= 20 THEN 1 ELSE 0 END),
		operator_wait_sum   = SUM(CASE WHEN e.final_stage = 'operator' THEN e.wait_time_sec ELSE 0 END)

	INTO #t_queue_metrics_session
	FROM #t_queue_events e
	GROUP BY e.session_id;

	CREATE CLUSTERED INDEX CX_t_queue_metrics_session ON #t_queue_metrics_session(session_id);

	-- суммы ожиданий и выходов в очередь
	DROP TABLE IF EXISTS #t_queue_session;
	SELECT
		session_id,
		queue_events_cnt   = COUNT(1),
		wait_time_sec_sum  = SUM(wait_time_sec),
		operator_events_cnt = SUM(CASE WHEN final_stage = 'operator' THEN 1 ELSE 0 END),
		first_project_id   = MAX(CASE WHEN queue_event_no = 1 THEN project_id END),
		accepted_calls_cnt = SUM(CASE WHEN final_stage ='operator' THEN 1 ELSE 0 END),
		ivr_to_operator_event_cnt = SUM(CASE WHEN final_stage in ('ivr', 'operator') THEN 1 ELSE 0 END) 
	INTO #t_queue_session
	FROM #t_queue_events_rn					   
	GROUP BY session_id;

	CREATE CLUSTERED INDEX CX_t_queue_session ON #t_queue_session(session_id);
	
	-- сумма по событийным ивентам 
	DROP TABLE IF EXISTS #t_queue_sl_session;
	SELECT
		e.session_id,

		sl_num = SUM(CASE
			WHEN e.final_stage = 'operator'
			 AND e.wait_time_sec < 20
			THEN 1 ELSE 0 END),

		sl_den = SUM(CASE
			WHEN e.final_stage = 'operator'
			THEN 1 ELSE 0 END)
	INTO #t_queue_sl_session
	FROM #t_queue_events e
	GROUP BY e.session_id;

	CREATE CLUSTERED INDEX CX_t_queue_sl_session ON #t_queue_sl_session(session_id);

	-- затем базово
	DROP TABLE IF EXISTS #t_dictionary_psb_numbers;
	SELECT '4992710723' AS num INTO #t_dictionary_psb_numbers;

	DROP TABLE IF EXISTS #t_transfers;
	SELECT
	    session_id      = clt.session_id,
	    transfer_cnt    = COUNT(1),
		transfer_cnt_psb = SUM(CASE WHEN psb.hit = 1 then 1 else 0 end),
		transfer_cnt_internal = SUM(CASE WHEN psb.hit is null then 1 else 0 end)
	INTO #t_transfers
	FROM #t_cl AS clt
	OUTER APPLY
	(
		SELECT TOP(1) 1 as hit
		FROM #t_dictionary_psb_numbers p
		WHERE charindex(p.num,clt.src_id)>0
			or  charindex(p.num,clt.dst_id)>0
	) as psb
	WHERE 1 = 1
	  AND clt.leg_id >= 4
	  AND clt.dst_id <> '6009'
	GROUP BY clt.session_id;	

	CREATE CLUSTERED INDEX CX_session_id ON #t_transfers (session_id);
	
	DROP TABLE IF EXISTS #t_talk;
	SELECT
	    session_id      = clp.session_id,
	    talk_time_sec   = SUM(
	                          CASE
	                              WHEN clp.connected IS NOT NULL
	                               AND clp.ended     IS NOT NULL
	                               AND clp.ended     >= clp.connected
	                               AND clp.dst_id    <> '6009'
	                                  THEN DATEDIFF(second, clp.connected, clp.ended)
	                              ELSE 0
	                          END
	                      )
	INTO #t_talk
	FROM #t_cl AS clp
	GROUP BY
	    clp.session_id;
	
	CREATE CLUSTERED INDEX CX_session_id ON #t_talk (session_id);

	DROP TABLE IF EXISTS #t_rep_calls
	SELECT
		session_id		= ib.session_id,
		call_date		= call_date,
		client_number	= ib.client_number,
		rn				= ROW_NUMBER() OVER (
						  PARTITION BY ib.call_date, ib.client_number 
						  ORDER BY ib.call_date, ib.session_id
						 )
	INTO #t_rep_calls 
	FROM #t_inbound	ib

	DROP TABLE IF EXISTS #t_inbound_agg
	SELECT
		[Дата]                                                   = ib.call_date,
		--[Проект]                                                 = p.title,
		[Id Проекта]											 = qs.first_project_id, -- где q.rn=1,
		-- @changelog dwh-463
		[Набранный номер]										 = ib.dst_id,
		[Набранный номер расшифровка]							 = g.owner,
		call_kind = g.call_kind,
		--[Имя партнера]											 = p.partnername,
		[SL, %]                                                     = CAST(
																			100.0 * SUM( CASE
																					WHEN DATEPART(hour, ib.created) >= 8
																					 AND DATEPART(hour, ib.created) < 22
																					THEN COALESCE(qsl.sl_num, 0)
																					ELSE 0
																				END
																			)
																			/
																			NULLIF(
																				SUM( CASE
																					 WHEN DATEPART(hour, ib.created) >= 8
																					  AND DATEPART(hour, ib.created) < 22
																					 THEN COALESCE(qsl.sl_den, 0)
																					 ELSE 0
																				END),
																			0)
																		AS money),

		[Количество входящих звонков]                            = count(1),
		[Звонок завершен на IVR]                                 = SUM(CASE WHEN qs.session_id IS NULL THEN 1 ELSE 0 END),
		[Колличетво уникальних клиентов]                         = count(distinct ib.client_number),
		[Вышли в очередь]                                        = SUM(ISNULL(qs.queue_events_cnt, 0)),
		[Звонок переведен с IVR на оператора]                    = SUM(CASE WHEN ISNULL(qs.ivr_to_operator_event_cnt, 0) > 0 THEN 1 ELSE 0 END),
		[Количество принятых звонков]                            = SUM(ISNULL(qs.accepted_calls_cnt, 0)),
		[Количество повторных обращений]                         = SUM(CASE WHEN rc.rn > 1 THEN 1 ELSE 0 END),
		[Количество переводов]                                   = SUM(ISNULL(tr.transfer_cnt, 0)),
		[Количество переводов внутри компании]					 = SUM(ISNULL(tr.transfer_cnt_internal, 0)),
		[Количество переводов ПСБ]								 = SUM(ISNULL(tr.transfer_cnt_psb, 0)),
		[Количество звонков в нерабочее время]                   = SUM(CASE WHEN DATEPART(hour, ib.created) < 8 OR DATEPART(hour, ib.created) >= 22 THEN 1 ELSE 0 END),
		[Время ожидания]										 = CAST(SUM(qs.wait_time_sec_sum) as int),
		[Доля потерянных звонков до 20 секунд ожидания]          = CAST(SUM(ISNULL(qm.lost_lt20_cnt, 0) * 1.0) / NULLIF(COUNT(1), 0)AS money),
			--CAST(
		 --       SUM(CASE WHEN q.final_stage IN ('ivr', 'queue') AND q.wait_time_sec < 20 THEN 1.0 ELSE 0.0 END)
		 --       / NULLIF(COUNT(1), 0)
		 --       AS money  --smal money
		 --   ),
		[Доля потерянных звонков после 20 секунд ожидания]       = CAST(SUM(ISNULL(qm.lost_ge20_cnt, 0) * 1.0) / NULLIF(COUNT(1), 0)AS money),
			--CAST(
			--    SUM(CASE WHEN q.final_stage IN ('ivr', 'queue') AND q.wait_time_sec >= 20 THEN  1.0 ELSE 0.0 END)
			--    / NULLIF(COUNT(1), 0)
			--    AS money
			--),
		[Количество звонков, принятых до 20 секунд ожидания]     = CAST(SUM(ISNULL(qm.operator_lt20_cnt, 0) * 1.0) / NULLIF(COUNT(1), 0)AS money),
		[Количество звонков, принятых после 20 секунд ожидания]  = CAST(SUM(ISNULL(qm.operator_ge20_cnt, 0) * 1.0) / NULLIF(COUNT(1), 0)AS money),
		[Среднее время ожидания ответа]                          = CAST( SUM(COALESCE(qm.operator_wait_sum,0) * 1.0)/ NULLIF(SUM(COALESCE(qm.operator_events_cnt,0)), 0) AS money),
		[Среднее время разговора]                                = AVG(cast(tk.talk_time_sec as money))-- money
	INTO #t_inbound_agg
	FROM #t_inbound AS ib
	LEFT JOIN #t_queue_session		AS qs  ON  qs.session_id = ib.session_id --and q.rn = 1
	LEFT JOIN #t_queue_sl_session	AS qsl ON  qsl.session_id = ib.session_id 
	LEFT JOIN #t_queue_metrics_session as qm on qm.session_id = ib.session_id 
	LEFT JOIN #t_transfers			AS tr  ON tr.session_id = ib.session_id
	LEFT JOIN #t_talk				AS tk  ON tk.session_id = ib.session_id
	LEFT JOIN #t_rep_calls			AS rc  ON rc.session_id = ib.session_id
	LEFT JOIN NaumenDbReport.dbo.mv_incoming_call_project p
		ON p.uuid = qs.first_project_id
	CROSS APPLY (
		SELECT owner =
		CASE
			WHEN ib.dst_id IN ('84999290048','8007004637','84992710723','8007004370','6034') THEN N'ПСБ'
			WHEN p.title LIKE N'%СмартТехГрупп%' THEN N'СмартТехГрупп'
			WHEN p.title LIKE N'%Смарт Горизонт%' THEN N'Смарт Горизонт'
			WHEN p.title LIKE N'%инвестици%' THEN N'Инвестиции'
			WHEN p.title LIKE N'%Техмани%' THEN N'Техмани'
			ELSE N'CarMoney'
		END,
			call_kind =
			CASE
				WHEN ib.dst_id LIKE '60%' AND LEN(ib.dst_id)=4 AND ib.dst_id <> '6009' THEN N'Перезвон'
				ELSE N'Входящий'
			END
		) g
	GROUP BY ib.call_date, qs.first_project_id, ib.dst_id, g.owner, g.call_kind, p.partnername
	, CASE
		WHEN ib.dst_id LIKE '60%' AND LEN(ib.dst_id)=4 AND ib.dst_id <> '6009'
		THEN N'Перезвон'
		ELSE N'Входящий'
		END 

	-- delete + insert
	BEGIN TRY
	BEGIN TRAN
		if @isDebug = 1
		begin
			SELECT
		     [Дата]                                         
			 , [Проект]	 = ISNULL(p.title, 'Завершился на Ivr')
			 , [Id Проекта]	
			 , [Группа проекта] = CASE WHEN p.partnername IS NULL THEN N'Завершился на Ivr'
			 					  ELSE CONCAT(call_kind, N': ', p.partnername)
			 					  END
			 , [Набранный номер]
			 , call_kind
			 , [Набранный номер расшифровка]
			 , [SL, %]                                        		
			 , [Количество входящих звонков]                  
			 , [Звонок завершен на IVR]                       
			 , [Колличетво уникальних клиентов]               
			 , [Вышли в очередь]                              
			 , [Звонок переведен с IVR на оператора]          
			 , [Количество принятых звонков]                  
			 , [Количество повторных обращений]               
			 , [Количество переводов]
			 , [Количество переводов внутри компании]	
			 , [Количество переводов ПСБ]				
			 , [Количество звонков в нерабочее время]         
			 , [Время ожидания]                               
			 , [Доля потерянных звонков до 20 секунд ожидания]
			 , [Доля потерянных звонков после 20 секунд ожидания]
			 , [Количество звонков, принятых до 20 секунд ожидания]   
			 , [Количество звонков, принятых после 20 секунд ожидания]
			 , [Среднее время ожидания ответа]                        
			 , [Среднее время разговора]                              
		FROM #t_inbound_agg AS ia
		LEFT JOIN NaumenDbReport.dbo.mv_incoming_call_project p
			ON p.uuid = ia.[Id Проекта]
		ORDER BY [Дата]
		end
		DELETE R
		FROM service.dm_report_inboundCalls_agg_new AS R
		WHERE 1 = 1
		  AND R.[Дата] >= @dtFrom
		  AND R.[Дата] < @dtTo

		INSERT INTO service.dm_report_inboundCalls_agg_new
		(
			[Дата]                                         
			, [Проект]
			, [Id Проекта]	
			, [Группа проекта]
			, dialed_number
			, call_kind
			, [Набранный номер расшифровка]
			, [SL, %]                                        												
			, [Количество входящих звонков]                  
			, [Звонок завершен на IVR]                       
			, [Колличетво уникальних клиентов]               
			, [Вышли в очередь]                              
			, [Звонок переведен с IVR на оператора]          
			, [Количество принятых звонков]                  
			, [Количество повторных обращений]               
			, [Количество переводов]
			, transfer_cnt_internal
			, transfer_cnt_psb
			, [Количество звонков в нерабочее время]         
			, [Время ожидания]                               
			, [Доля потерянных звонков до 20 секунд ожидания]
			, [Доля потерянных звонков после 20 секунд ожидания]
			, [Количество звонков, принятых до 20 секунд ожидания]   
			, [Количество звонков, принятых после 20 секунд ожидания]
			, [Среднее время ожидания ответа]                        
			, [Среднее время разговора]                              
		)
		SELECT
		     [Дата]                                         
			 , [Проект]	 = ISNULL(p.title, 'Завершился на Ivr')
			 , [Id Проекта]	
			  , [Группа проекта] = CASE WHEN p.partnername IS NULL THEN N'Завершился на Ivr'
			 					  ELSE CONCAT(call_kind, N': ', p.partnername)
			 					  END
			 , [Набранный номер]
			 , call_kind
			 , [Набранный номер расшифровка]
			 , [SL, %]                                        		
			 , [Количество входящих звонков]                  
			 , [Звонок завершен на IVR]                       
			 , [Колличетво уникальних клиентов]               
			 , [Вышли в очередь]                              
			 , [Звонок переведен с IVR на оператора]          
			 , [Количество принятых звонков]                  
			 , [Количество повторных обращений]               
			 , [Количество переводов]
			 , [Количество переводов внутри компании]	
			 , [Количество переводов ПСБ]				
			 , [Количество звонков в нерабочее время]         
			 , [Время ожидания]                               
			 , [Доля потерянных звонков до 20 секунд ожидания]
			 , [Доля потерянных звонков после 20 секунд ожидания]
			 , [Количество звонков, принятых до 20 секунд ожидания]   
			 , [Количество звонков, принятых после 20 секунд ожидания]
			 , [Среднее время ожидания ответа]                        
			 , [Среднее время разговора]                              
		FROM #t_inbound_agg AS ia
		LEFT JOIN NaumenDbReport.dbo.mv_incoming_call_project p
			ON p.uuid = ia.[Id Проекта]

	--	ORDER BY ib.call_date;

		COMMIT; 
	END TRY
	BEGIN CATCH
       DECLARE 
             @description NVARCHAR(1024)
           , @message     NVARCHAR(1024)
           , @eventType   NVARCHAR(50)
		   , @spName nvarchar(255) =  concat('etl', '.', OBJECT_NAME(@@PROCID));

		SET @description = CONCAT(
	              'ErrorNumber: '   , CAST(ERROR_NUMBER()   AS NVARCHAR(50)), CHAR(13)
	            , 'ErrorSeverity: ' , CAST(ERROR_SEVERITY() AS NVARCHAR(50)), CHAR(13)
	            , 'ErrorState: '    , CAST(ERROR_STATE()    AS NVARCHAR(50)), CHAR(13)
	            , 'Procedure: '     , ISNULL(ERROR_PROCEDURE(), ''),          CHAR(13)
	            , 'Message: '       , ISNULL(ERROR_MESSAGE(), '')
	        );

       SET @eventType = 'Data Vault ERROR';

       --EXEC LogDb.dbo.LogAndSendMailToAdmin
       --      @eventName   = @spName
       --    , @eventType   = @eventType
       --    , @message     = @message
       --    , @description = @description
       --    , @SendEmail   = 1
       --    , @SendToSlack = 1;

       IF @@TRANCOUNT > 0
           ROLLBACK TRAN;

       THROW;
   END CATCH
END
