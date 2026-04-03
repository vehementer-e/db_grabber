-- =============================================
-- Author:		shubkin aleksandr
-- Create date: 13.11.25
-- Description:	BP-314
-- =============================================
CREATE   PROCEDURE dbo.report_outboundCalls
	@dtFrom datetime	= null,
	@dtTo datetime		= null
AS
BEGIN
	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #t_period;
	
	SELECT
	      CAST(dos.attempt_start AS date) AS call_date
	    , dos.attempt_start
	    , dos.project_id                  AS project_uuid
	    , dos.session_id
	    , dos.client_number
	    , dos.attempt_result
	    , ISNULL(dos.pickup_time, 0)          AS pickup_time
	    , ISNULL(dos.queue_time, 0)           AS queue_time
	    , ISNULL(dos.operator_pickup_time, 0) AS operator_pickup_time
	    , ISNULL(dos.speaking_time, 0)        AS speaking_time
	    , ISNULL(dos.wrapup_time, 0)          AS wrapup_time
	    , ISNULL(dos.holds, 0)                AS holds
	    , ISNULL(dos.hold_time, 0)            AS hold_time
	INTO #t_period
	FROM [NaumenDbReport].dbo.detail_outbound_sessions dos WITH (NOLOCK)
	WHERE (@dtFrom is NULL OR dos.attempt_start >= @dtFrom) AND
		(@dtTo is NULL or dos.attempt_start < DATEADD(DAY, 1, @dtTo))
	-- distinct
	
	DROP TABLE IF EXISTS #t_attempt_result;
	
	SELECT DISTINCT
	      p.attempt_result
		  , call_success_type =  cast(null as nvarchar)
	INTO #t_attempt_result
	FROM #t_period p
	
	-- статус через TVF
	UPDATE ar
	SET ar.call_success_type = s.Result
	FROM #t_attempt_result ar
	CROSS APPLY Reports.dbo.dict_naumenDb_attempt_result_encoding(ar.attempt_result) s;
	
	
	-- обогащенный дс
	DROP TABLE IF EXISTS #t_period_enriched;
	SELECT
	      p.call_date
	    , p.project_uuid
	    , p.session_id
	    , p.client_number
	    , p.attempt_result
	    , ar.call_success_type       -- 'success' / 'nonsuccess'
	    , p.pickup_time
	    , p.queue_time
	    , p.operator_pickup_time
	    , p.speaking_time
	    , p.wrapup_time
	    , p.holds
	    , p.hold_time
	INTO #t_period_enriched
	FROM #t_period p
	LEFT JOIN #t_attempt_result ar
	       ON ar.attempt_result = p.attempt_result

	-- 
	
	DROP TABLE IF EXISTS #t_period_proj;
	
	SELECT
	      e.call_date
	    , ocp.uuid          -- числовой / бизнес-ID проекта
	    , ocp.title
		, e.attempt_result
	    , e.call_success_type
	    , e.session_id
	    , e.client_number
	    , e.pickup_time
	    , e.queue_time
	    , e.operator_pickup_time
	    , e.speaking_time
	    , e.wrapup_time
	    , e.holds
	    , e.hold_time
	INTO #t_period_proj
	FROM #t_period_enriched e
	LEFT JOIN [NaumenDbReport].dbo.mv_outcoming_call_project ocp 
	       ON ocp.uuid = e.project_uuid;
	
	
	--
	
	DROP TABLE IF EXISTS #t_report_agg;
	
	SELECT
	      p.call_date
	    , project_id	= p.uuid
	    , project_name	= p.title
	
	    -- объёмы
	    , COUNT(*)                                                 AS total_calls
	    , SUM(CASE WHEN p.call_success_type = 'success'    THEN 1 ELSE 0 END) AS success_calls
	    , SUM(CASE WHEN p.call_success_type = 'nonsuccess' THEN 1 ELSE 0 END) AS fail_calls
		, SUM(CASE WHEN p.attempt_result IN (
						'CallDisconnect',
						'CRR_DISCONNECT',
						'complaint',
						'recallRequest'
					) THEN 1 else 0 end) as refuse_calls
	    -- доля успеха
	    , CASE 
	        WHEN COUNT(*) > 0 
	             THEN CAST(SUM(CASE WHEN p.call_success_type = 'success' THEN 1 ELSE 0 END) AS decimal(18,4))
	                  / COUNT(*)
	      END                                                      AS success_rate
	
	    -- среднее время ожидания ответа (по успешным)
	    , AVG(CASE WHEN p.call_success_type = 'success'
	               THEN CAST(p.pickup_time + p.queue_time + p.operator_pickup_time AS decimal(18,4))
	          END)                                                 AS avg_success_wait_time
	
	    -- среднее время ожидания по неуспешным
	    , AVG(CASE WHEN p.call_success_type = 'nonsuccess'
	               THEN CAST(p.pickup_time + p.queue_time + p.operator_pickup_time AS decimal(18,4))
	          END)                                                 AS avg_fail_wait_time
	
	    -- среднее время разговора
	    , AVG(CASE WHEN p.call_success_type = 'success'
	               THEN CAST(p.speaking_time AS decimal(18,4))
	          END)                                                 AS avg_success_speaking_time
	    , AVG(CASE WHEN p.call_success_type = 'nonsuccess'
	               THEN CAST(p.speaking_time AS decimal(18,4))
	          END)                                                 AS avg_fail_speaking_time
	
	    -- средняя постобработка
	    , AVG(CASE WHEN p.call_success_type = 'success'
	               THEN CAST(p.wrapup_time AS decimal(18,4))
	          END)                                                 AS avg_success_wrapup_time
	    , AVG(CASE WHEN p.call_success_type = 'nonsuccess'
	               THEN CAST(p.wrapup_time AS decimal(18,4))
	          END)                                                 AS avg_fail_wrapup_time
	
	    -- можно добавить суммы, если нужны
	    , SUM(p.speaking_time)                                     AS sum_speaking_time
	    , SUM(p.wrapup_time)                                       AS sum_wrapup_time
	INTO #t_report_agg
	FROM #t_period_proj p
	GROUP BY
	      p.call_date
	    , p.uuid
	    , p.title;
	
	
	select *
	from #t_report_agg
	order by call_date, project_name, project_id
	
	
END
