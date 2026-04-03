-- =============================================
-- Author:		shubkin aleksandr
-- Create date: 17.12.2025
-- Description:	Процедура, которая собирает и аггрегирует данные
--				для статистики по исходящим звонкам. Автоматическим и ручным.
--				Итоговая выборка обновляет/заполняет таблицу-источник для отчета
--				в зависимости от выбранного режима.
-- =============================================
/*
-- USAGE		EXEC Reports.[service].[fill_report_outboundCalls_agg] 
	@reloadDD = 200, @isDebug = 1 
	*/
-- =============================================
-- SYNAPSIS. 
-- * extract:	NaumenDbReport.dbo.detail_outbound_sessions (авто) UNION NaumenDbReport.dbo.dm_call_legs_outcoming_service (ручные)  INTO стейджинг~
-- * transform: аггрегируем по date + project, считаем метрики по звонкам. .
-- * load:		В транзакции delete where date between + insert
-- =============================================
CREATE   PROCEDURE [service].[fill_dm_report_outboundCalls_agg] 
	@reloadDD tinyint  = 2,
--	@regime	  tinyint  = 3, -- 1 = regular, 2 = manual, 3 = all
	@dtTo	  date		= null,
	@dtFrom date		= NULL,
    @isDebug  bit      = 0
AS
BEGIN
	SET NOCOUNT ON;

	--IF @regime NOT IN (1, 2, 3)			 
	--	THROW 51001, 'Неверный параметр @regime. Разрешенные значения: 1 = regular, 2 = manual, 3 = all.', 1;
	IF @dtFrom is null 
	begin 
		declare @maxDt date;
		select @maxDt = MAX([Дата])
		FROM service.dm_report_inboundCalls_agg
		SET @dtTo   = dateadd(dd,1, cast(getdate() as date));		/*переписать, использовать дату из service.dm_report_inboundCalls_agg + 1 день */
		SET @dtFrom = DATEADD(day, -3, @dtTo);
	end
	--DECLARE @dtFrom datetime  = DATEADD(day, -@reloadDD, @dtTo);

	if @isDebug = 1
	begin
		select @dtTo as dtTo
		select @dtFrom as dtFrom
	end

	drop table if exists #t_period_all
	create table #t_period_all(
		  call_date				date    
		, attempt_start			datetime2(3)
		, project_id			nvarchar(255)
		, project_name			nvarchar(255)
		, partner_name			nvarchar(255)
		, session_id			nvarchar(255)
		, client_number			nvarchar(20)
		, attempt_result_code	bit
		, attempt_result_txt	nvarchar(100)
		, pickup_time			int
		, speaking_time			int
		, queue_time			int	
		, operator_pickup_time	int 
		, wrapup_time			int
	)

	DROP TABLE IF EXISTS #t_dict_result_code_decoded
	SELECT attempt_result_txt  = attempt_result_code,
		   attempt_result_code = IsSuccess
	INTO #t_dict_result_code_decoded
	FROM reports.service.[tvf_naumenDb_attempt_result_decoding](null)

	DROP TABLE IF EXISTS #t_manual_projects 
	SELECT
		project_id = dict.uuid
		, project_name = dict.title
		, partnername = dict.partnername
	INTO #t_manual_projects
	FROM NaumenDbReport.dbo.[mv_outcoming_call_project]	dict
	WHERE partnername		= 'Carmoney: Service'
	AND   title				= 'Сервис ручные обзвоны'

	--IF @regime in (1, 3)
	--BEGIN
	---- блок только про regular
	--END
	CREATE CLUSTERED INDEX cix_period_all ON #t_period_all(call_date, project_id);

	INSERT INTO	#t_period_all
	(
		  call_date				
		, attempt_start			
		, project_id			
		, project_name			
		, partner_name			
		, session_id			
		, client_number			
		, attempt_result_code
		, attempt_result_txt
		, pickup_time			
		, speaking_time			
		, queue_time			
		, operator_pickup_time	
		, wrapup_time			
	)
	SELECT
		call_date				= CAST(dos.attempt_start AS date),
		attempt_start			= dos.attempt_start,
		project_id			    = dos.project_id,
		project_name  			= ocp.title,
		partner_name  			= ocp.partnername,
		session_id  			= dos.session_id,
		client_number			= try_cast( dos.client_number as bigint), 
		attempt_result_code		= cd.attempt_result_code,
		attempt_result_txt		= cd.attempt_result_txt,
		pickup_time				= ISNULL(dos.pickup_time, -1), 
		speaking_time			= ISNULL(dos.speaking_time, -1),
		queue_time				= ISNULL(dos.queue_time, -1),
		operator_pickup_time	= ISNULL(dos.operator_pickup_time, -1),
		wrapup_time				= ISNULL(dos.wrapup_time, -1) 
	FROM		NaumenDbReport.dbo.detail_outbound_sessions dos
	LEFT JOIN	NaumenDbReport.dbo.mv_outcoming_call_project ocp 
		ON ocp.uuid = dos.project_id
	LEFT JOIN 	#t_dict_result_code_decoded cd
		ON 	dos.attempt_result = cd.attempt_result_txt
	WHERE	dos.attempt_start >= @dtFrom 
			AND dos.attempt_start < DATEADD(DAY, 1, @dtTo)

	

	--IF @regime in (2, 3)
	--BEGIN
	---- блок только про manual
	--END
	INSERT INTO	#t_period_all
	(
		  call_date				
		, attempt_start			
		, project_id			
		, project_name			
		, partner_name			
		, session_id			
		, client_number			
		, attempt_result_code
		, pickup_time			
		, speaking_time			
		, queue_time			
		, operator_pickup_time	
		, wrapup_time			
	)
	select 
		 t.call_date				
		 ,t.attempt_start			
		 ,t.project_id			
		 ,t.project_name			
		 ,t.partner_name			
		 ,t.session_id			
		 ,t.client_number			
		 ,attempt_result_code = cast(iif(speaking_time>3, 1, 0) as bit)
		 ,t.pickup_time			
		 ,t.speaking_time			
		 , queue_time			= ISNULL(null, -1)
		 , operator_pickup_time	= ISNULL(null, -1)
		 , wrapup_time			= ISNULL(null, -1)
	from (
	SELECT
		  call_date				= CAST(d.created AS date)
		, attempt_start			= d.created
		, project_id			= mp.project_id
		, project_name			= mp.project_name
		, partner_name			= mp.partnername
		, session_id			= d.session_id
		, client_number			= try_cast(d.dst_id as bigint)
		, pickup_time			=
				iif ( COALESCE(d.connected, d.ended) IS NOT NULL
					,DATEDIFF(SECOND, d.created, COALESCE(d.connected, d.ended))
				,-1)
		, speaking_time			=
				iif(d.connected IS NOT NULL AND d.ended IS NOT NULL
					 ,DATEDIFF(SECOND, d.connected, d.ended)
				,- 1
				)
	
	FROM NaumenDbReport.dbo.dm_call_legs_outcoming_service d
	CROSS JOIN #t_manual_projects mp
	WHERE d.leg_id = 1
	  AND d.created >= @dtFrom
	  AND d.created <  DATEADD(DAY, 1, @dtTo)
	)   t
	

	DROP TABLE IF EXISTS #t_report_agg;
	SELECT
		  call_date					= p.call_date
		, project_id				= p.project_id
		, partner_name				= p.partner_name
		, project_name				= p.project_name
		, total_calls				= COUNT(*)
		, success_calls				= SUM(cast(p.attempt_result_code as tinyint))
		, fail_calls				= SUM(cast(~p.attempt_result_code as tinyint))
		, refuse_calls				= SUM(CASE WHEN p.attempt_result_txt IN ('CallDisconnect',
																			 'CRR_DISCONNECT',
																			 'complaint',
																			 'recallRequest')
											   THEN 1 else 0 end)
		, avg_success_wait_time		= 
			AVG(CASE WHEN p.attempt_result_code = 1
					 THEN CAST(isnull(nullif(p.pickup_time,		     -1), 0) + 
							   isnull(nullif(p.queue_time,		     -1), 0) + 
							   isnull(nullif(p.operator_pickup_time, -1), 0) 
						  AS money)
					 END)
	
		, avg_fail_wait_time		=
			AVG(CASE WHEN p.attempt_result_code = 0
					 THEN CAST(isnull(nullif(p.pickup_time,			 -1), 0) + 
							   isnull(nullif(p.queue_time,			 -1), 0) + 
							   isnull(nullif(p.operator_pickup_time, -1), 0) 
						  AS money)
					 END)
		, avg_success_speaking_time = 
			AVG(CASE WHEN p.attempt_result_code = 1 THEN NULLIF(CAST(p.speaking_time AS money), -1) END) 
		, avg_fail_speaking_time = 
			AVG(CASE WHEN p.attempt_result_code = 0 THEN NULLIF(CAST(p.speaking_time AS money), -1) END) 
		, avg_success_wrapup_time =
			AVG(CASE WHEN p.attempt_result_code = 1 THEN NULLIF(CAST(p.wrapup_time AS money), -1) END)
		, avg_fail_wrapup_time =
			AVG(CASE WHEN p.attempt_result_code = 0 THEN NULLIF(CAST(p.wrapup_time AS money), -1) END)
	INTO #t_report_agg
	FROM #t_period_all p
	GROUP BY
		  p.call_date
		, p.project_id
		, p.partner_name
		, p.project_name;


	IF @isDebug = 1
	BEGIN
	    SELECT '#t_report_agg (TOP 100)' AS _dbg;
	    SELECT TOP (100) *
	    FROM #t_report_agg
	    ORDER BY call_date DESC, project_id;
		RETURN;
	END

	BEGIN TRY
	BEGIN TRAN

		DELETE FROM service.dm_report_outboundCalls_agg
		WHERE call_date >= cast(@dtFrom	 as date)
		 AND  call_date < DATEADD(DAY, 1, cast(@dtTo as date))
		
		/* consider this
			DELETE t
			FROM service.report_outboundCalls_agg t
			where exists (SELECT top(1) FROM #t_report_agg s
			  ON s.call_date  = t.call_date
			 AND s.project_id = t.project_id
			)
		-- По индексу вроде джоин ок  ? 
		-- мастхев при реализации @regime

		*/

		INSERT INTO service.dm_report_outboundCalls_agg
        (
              call_date
            , project_id
            , partnername
            , project_name
            , total_calls
            , success_calls
            , fail_calls
            , refuse_calls
            , avg_success_wait_time
            , avg_fail_wait_time
            , avg_success_speaking_time
            , avg_fail_speaking_time
            , avg_success_wrapup_time
            , avg_fail_wrapup_time
        )
        SELECT
              call_date
            , project_id
            , partner_name
            , project_name
            , total_calls
            , success_calls
            , fail_calls
            , refuse_calls
            , avg_success_wait_time
            , avg_fail_wait_time
            , avg_success_speaking_time
            , avg_fail_speaking_time
            , avg_success_wrapup_time
            , avg_fail_wrapup_time
        FROM #t_report_agg;
	COMMIT;
	END TRY
	BEGIN CATCH
		DECLARE @error_description nvarchar(max) = CONCAT(
            'ErrorNumber: ', CAST(FORMAT(ERROR_NUMBER(),'0') AS nvarchar(50)), CHAR(10), CHAR(13),
            ' ErrorState: ', CAST(FORMAT(ERROR_STATE(),'0')  AS nvarchar(50)), CHAR(10), CHAR(13),
            ' Error_line: ', CAST(FORMAT(ERROR_LINE(),'0')   AS nvarchar(50)), CHAR(10), CHAR(13),
            ' ErrorMessage: ', ISNULL(ERROR_MESSAGE(),'')
        );

        IF @@TRANCOUNT > 0
            ROLLBACK;

        ;THROW 51000, @error_description, 1;
	END CATCH
END
