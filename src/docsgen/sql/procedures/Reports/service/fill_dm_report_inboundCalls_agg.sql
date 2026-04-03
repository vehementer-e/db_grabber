-- =============================================
-- Author:		Shubkin Aleksandr 
-- Create date: 21.01.2026
-- Description:	Процедура для заполнения/обновления dm
--				для отчета по входящей линии | dwh-418
-- USAGE:		exec [service].[fill_dm_report_inboundCalls_agg] @dtFrom = '2024-01-01', @dtTo = '2026-03-25', @isDebug = 0
-- CHECK:       select * from reports.service.dm_report_inboundCalls_agg order by [Дата]	desc
-- COUNT:       select count(1) q from reports.service.dm_report_inboundCalls_agg
-- DROP:            drop table reports.service.dm_report_inboundCalls_agg
-- CREATE FROM OLD: select top(0) * into reports.service.dm_report_inboundCalls_agg from reports.service.dm_report_inboundCalls_agg_old
-- =============================================
-- @changelog | sh.a.a. | 04.02.2026 | DWH-463 | Доработка отчета по входящей линии
-- @changelog | sh.a.a. | 19.03.2026 | DWH-546 | Переименовать столбцы
-- @changelog | sh.a.a  | 20.03.2026 | DWH-547 | Добавить столбец "Количество уникальных клиентов"
-- @changelog | sh.a.a  | 25.03.2026 | DWH-XXX | Добавить столбец с количеством успешных звонков bigInstallment
-- @changelog | sh.a.a  | 25.03.2026 | DWH-XXX | Добавить столбец с количеством открытых договоров bigInstallment на начало дня
-- =============================================
CREATE       PROCEDURE [service].[fill_dm_report_inboundCalls_agg] 
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
		FROM service.dm_report_inboundCalls_agg
		SET @dtTo   = dateadd(dd,1, cast(getdate() as date));	
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
	  AND cl.src_abonent IS NULL; 

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
	DROP TABLE IF EXISTS #t_queue;
	SELECT
	    session_id      = qc.session_id,
	    wait_time_sec   =
	        CASE
	            WHEN qc.unblocked_time IS NOT NULL
	             AND qc.dequeued_time  IS NOT NULL
	             AND qc.dequeued_time  >= qc.unblocked_time
	                THEN DATEDIFF(second, qc.unblocked_time, qc.dequeued_time)
	            ELSE 0
	        END,
	    final_stage     = qc.final_stage,
		project_id		= project_id,
		nRow = ROw_number() over(partition by session_id order by enqueued_time) 
	INTO #t_queue
	FROM NaumenDbReport.dbo.queued_calls AS qc	-- with(index = [NonClusteredIndexSessionID])
	WHERE 1 = 1
	AND NaumenDbReport.$PARTITION.[pfn_range_right_date_part_dbo_queued_calls](qc.enqueued_time) >=   NaumenDbReport.$PARTITION.[pfn_range_right_date_part_dbo_queued_calls](@dtFrom)
		AND NaumenDbReport.$PARTITION.[pfn_range_right_date_part_dbo_queued_calls](qc.enqueued_time) <=   NaumenDbReport.$PARTITION.[pfn_range_right_date_part_dbo_queued_calls](@dtTo)

	  AND qc.enqueued_time >= @dtFrom
	  AND qc.enqueued_time <  @dtTo
	  AND EXISTS				  
	  (
	      SELECT 1
	      FROM #t_inbound AS ib
	      WHERE ib.session_id = qc.session_id
	  );
	
	CREATE CLUSTERED INDEX CX_session_id ON #t_queue (session_id);
	
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
	WHERE clp.leg_id = 1
	GROUP BY clp.session_id;
	
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

	DROP TABLE IF EXISTS #t_crm_phones;
	-- просто логика по телефонам что есть в срм
	SELECT DISTINCT
		interaction_date = TRY_CAST(c.[ДатаВзаимодействия] AS date),
		client_number    = TRY_CAST(RIGHT(CAST(c.[НомерТелефона] AS varchar(50)), 10) AS bigint)
	INTO #t_crm_phones
	FROM Reports.dbo.[dm_Все_коммуникации_На_основе_отчета_из_crm] c
	WHERE TRY_CAST(c.[ДатаВзаимодействия] AS date) >= @dtFrom
	  AND TRY_CAST(c.[ДатаВзаимодействия] AS date) <  @dtTo
	  AND c.[НомерТелефона] IS NOT NULL
	  AND TRY_CAST(RIGHT(CAST(c.[НомерТелефона] AS varchar(50)), 10) AS bigint) IS NOT NULL
	  --AND NULLIF(c.[Session_id], '') IS NOT NULL
	  AND c.[Направление] = N'Входящее'
	  AND c.[ВидВзаимодействия] LIKE N'%Телефонный звонок Входящий%'
	  AND EXISTS
	  (
		  SELECT 1
		  FROM #t_inbound ib
		  WHERE ib.call_date = TRY_CAST(c.[ДатаВзаимодействия] AS date)
			AND ib.client_number = TRY_CAST(RIGHT(CAST(c.[НомерТелефона] AS varchar(50)), 10) AS bigint)
	  );

	CREATE CLUSTERED INDEX CX_t_crm_phones
		ON #t_crm_phones (interaction_date, client_number);

	DROP TABLE IF EXISTS #t_crm_big_installment;
	SELECT 
		interaction_date = TRY_CAST(c.[ДатаВзаимодействия] AS date),
		client_number    = TRY_CAST(RIGHT(CAST(c.[НомерТелефона] AS varchar(50)), 10) AS bigint)
	INTO #t_crm_big_installment
	FROM Reports.dbo.[dm_Все_коммуникации_На_основе_отчета_из_crm] c
	WHERE TRY_CAST(c.[ДатаВзаимодействия] AS date) >= @dtFrom
	  AND TRY_CAST(c.[ДатаВзаимодействия] AS date) <  @dtTo
	  AND c.[НомерТелефона] IS NOT NULL
	  AND TRY_CAST(RIGHT(CAST(c.[НомерТелефона] AS varchar(50)), 10) AS bigint) IS NOT NULL
	  AND c.[Направление] = N'Входящее'
	  AND c.[ВидВзаимодействия] LIKE N'%Телефонный звонок Входящий%'
	  AND c.[подтиппродукта_code] = 'bigInstallment'
	  AND EXISTS
	  (
		  SELECT 1
		  FROM #t_inbound ib
		  WHERE ib.call_date = TRY_CAST(c.[ДатаВзаимодействия] AS date)
			AND ib.client_number = TRY_CAST(RIGHT(CAST(c.[НомерТелефона] AS varchar(50)), 10) AS bigint)
	  );

	CREATE CLUSTERED INDEX CX_t_crm_big_installment
		ON #t_crm_big_installment (interaction_date, client_number);

	-- по идее та же логика что и с номерами в наумене только подтвердившиеся в в срм
	-- возможно будет значение меньше чем в наумен тк не все строки в срм
	DROP TABLE IF EXISTS #t_unique_clients_agg;
	SELECT
		[Дата]                        = ib.call_date,
		[Id Проекта]                  = q.project_id,
		[Набранный номер]             = ib.dst_id,
		[Набранный номер расшифровка] = g.owner,
		call_kind                     = g.call_kind,
		[Количество уникальных клиентов] = COUNT(DISTINCT ib.client_number)
	INTO #t_unique_clients_agg
	FROM #t_inbound ib
	LEFT JOIN #t_queue q
		ON q.session_id = ib.session_id
	   AND q.nRow = 1
	LEFT JOIN NaumenDbReport.dbo.mv_incoming_call_project p
		ON p.uuid = q.project_id
	INNER JOIN #t_crm_phones cp
		ON cp.interaction_date = ib.call_date
	   AND cp.client_number    = ib.client_number
	CROSS APPLY
	(
		SELECT
			owner =
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
					WHEN ib.dst_id LIKE '60%' AND LEN(ib.dst_id) = 4 AND ib.dst_id <> '6009' THEN N'Перезвон'
					ELSE N'Входящий'
				END
	) g
	GROUP BY
		ib.call_date,
		q.project_id,
		ib.dst_id,
		g.owner,
		g.call_kind;

	CREATE CLUSTERED INDEX CX_t_unique_clients_agg
		ON #t_unique_clients_agg ([Дата], [Id Проекта], [Набранный номер], call_kind);

	DROP TABLE IF EXISTS #t_big_installment_success_agg;
	SELECT
		[Дата]                        = ib.call_date,
		[Id Проекта]                  = q.project_id,
		[Набранный номер]             = ib.dst_id,
		[Набранный номер расшифровка] = g.owner,
		call_kind                     = g.call_kind,
		[Количество успешных звонков bigInstallment] = COUNT(1)
	INTO #t_big_installment_success_agg
	FROM #t_inbound ib
	LEFT JOIN #t_queue q
		ON q.session_id = ib.session_id
	   AND q.nRow = 1
	LEFT JOIN NaumenDbReport.dbo.mv_incoming_call_project p
		ON p.uuid = q.project_id
	INNER JOIN #t_crm_big_installment cbi
		ON cbi.interaction_date = ib.call_date
	   AND cbi.client_number = ib.client_number
	CROSS APPLY
	(
		SELECT
			owner =
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
					WHEN ib.dst_id LIKE '60%' AND LEN(ib.dst_id) = 4 AND ib.dst_id <> '6009' THEN N'Перезвон'
					ELSE N'Входящий'
				END
	) g
	WHERE q.final_stage = 'operator'
	GROUP BY
		ib.call_date,
		q.project_id,
		ib.dst_id,
		g.owner,
		g.call_kind;

	CREATE CLUSTERED INDEX CX_t_big_installment_success_agg
		ON #t_big_installment_success_agg ([Дата], [Id Проекта], [Набранный номер], call_kind);

	DROP TABLE IF EXISTS #t_big_installment_open_contracts_agg;
	SELECT
		cd.call_date AS [Дата],
		[Количество открытых договоров bigInstallment на начало дня] = COUNT(1)
	INTO #t_big_installment_open_contracts_agg
	FROM
	(
		SELECT DISTINCT ib.call_date
		FROM #t_inbound ib
	) cd
	INNER JOIN [dwh2].[hub].[ДоговорЗайма] dz
		ON dz.[ПодТипПродукта_Code] = 'bigInstallment'
	   AND dz.[ДатаДоговораЗайма] < cd.call_date
	   AND (
				dz.[ДатаЗакрытияДоговора] IS NULL
				OR dz.[ДатаЗакрытияДоговора] >= cd.call_date
		   )
	GROUP BY cd.call_date;

	CREATE CLUSTERED INDEX CX_t_big_installment_open_contracts_agg
		ON #t_big_installment_open_contracts_agg ([Дата]);

	-- старая логика запроса
	DROP TABLE IF EXISTS #t_inbound_agg
	SELECT
	    [Дата]                                                   = ib.call_date,
	    --[Проект]                                                 = p.title,
		[Id Проекта]											 = q.project_id,
		-- @changelog dwh-463
		[Набранный номер]										 = ib.dst_id,
		[Набранный номер расшифровка]							 = g.owner,
		call_kind = g.call_kind,
		--[Имя партнера]											 = p.partnername,
	    [SL, %]                                                     = CAST(
																		 100.0
																		 * SUM(
																		       CASE
																		           WHEN q.final_stage = 'operator'
																		            AND q.wait_time_sec < 20
																		            AND DATEPART(hour, ib.created) >= 8
																		            AND DATEPART(hour, ib.created) < CASE WHEN lower(p.partnername) like '%service%' THEN 20 ELSE 22 END
																		               THEN 1
																		           ELSE 0
																		       END
																		   )
																		 /
																		 NULLIF(
																		     SUM(
																		         CASE
																		             WHEN DATEPART(hour, ib.created) >= 8
																		              AND DATEPART(hour, ib.created) < CASE WHEN lower(p.partnername) like '%service%' THEN 20 ELSE 22 END
																		                 THEN 1
																		             ELSE 0
																		         END
																		     ),
																		     0
																		 )
																		 AS money),

	    [Количество входящих звонков]                            = count(1),
	    --[Звонок завершен на IVR]                                 = SUM(CASE WHEN q.session_id IS NULL THEN 1 ELSE 0 END),
		[Звонок завершен на IVR]								 = SUM(CASE WHEN q.session_id IS NULL THEN 1 ELSE 0 END)
																 + SUM(CASE WHEN q.session_id IS NOT NULL AND q.final_stage = 'ivr' THEN 1 ELSE 0 END),

		-- old[Колличетво уникальних клиентов]                         = count(distinct ib.client_number),
		-- @changelog dwh-546
		[Количеcтво уникальных номеров клиентов]                 = count(distinct ib.client_number),
		[Вышли в очередь]                                        = SUM(CASE WHEN q.session_id IS NOT NULL THEN 1 ELSE 0 END),
	    [Звонок переведен с IVR на оператора]                    = SUM(CASE WHEN q.final_stage in ('ivr', 'queue') THEN 1 ELSE 0 END),
		[Количество ?колбэков?]									 = SUM(CASE	WHEN q.final_stage in ('callback') THEN 1 ELSE 0 END),
	    [Количество принятых звонков]                            = SUM(CASE WHEN q.final_stage = 'operator' THEN 1 ELSE 0 END),
	    [Количество повторных обращений]                         = SUM(CASE WHEN rc.rn > 1 THEN 1 ELSE 0 END),
	    [Количество переводов]                                   = SUM(ISNULL(tr.transfer_cnt, 0)),
		[Количество переводов внутри компании]					 = SUM(ISNULL(tr.transfer_cnt_internal, 0)),
		[Количество переводов ПСБ]								 = SUM(ISNULL(tr.transfer_cnt_psb, 0)),
	    [Количество звонков в нерабочее время]                   = SUM(CASE WHEN DATEPART(hour, ib.created) < 8 OR DATEPART(hour, ib.created) >= CASE WHEN g.owner = N'ПСБ' THEN 20 ELSE 22 END THEN 1 ELSE 0 END),
	    [Время ожидания]										 = CAST(SUM(q.wait_time_sec) as int),
	    [Доля потерянных звонков до 20 секунд ожидания]          = 
			CAST(
	            SUM(CASE WHEN q.final_stage IN ('ivr', 'queue') AND q.wait_time_sec < 20 THEN 1.0 ELSE 0.0 END)
	            / NULLIF(COUNT(1), 0)
	            AS money
	        ),
	    [Доля потерянных звонков после 20 секунд ожидания]       =
	        CAST(
	            SUM(CASE WHEN q.final_stage IN ('ivr', 'queue') AND q.wait_time_sec >= 20 THEN  1.0 ELSE 0.0 END)
	            / NULLIF(COUNT(1), 0)
	            AS money
	        ),
	    [Количество звонков, принятых до 20 секунд ожидания]     = SUM(CASE WHEN q.final_stage = 'operator' AND q.wait_time_sec < 20 THEN 1 ELSE 0 END),
	    [Количество звонков, принятых после 20 секунд ожидания]  = SUM(CASE WHEN q.final_stage = 'operator' AND q.wait_time_sec >= 20 THEN 1 ELSE 0 END),
	    -- old [Среднее время ожидания ответа]                          = AVG(CASE WHEN q.final_stage = 'operator' THEN cast(q.wait_time_sec as money) END),
	    -- @changelog DWH-546
		[FRT]													 = AVG(CASE WHEN q.final_stage = 'operator' THEN cast(q.wait_time_sec as money) END),
		[Среднее время разговора]                                = AVG(cast(tk.talk_time_sec as money)) -- money по первому плечу переделать
	INTO #t_inbound_agg
	FROM #t_inbound AS ib
	LEFT JOIN #t_queue		AS q  ON  q.session_id = ib.session_id
		and q.nRow =1 
	LEFT JOIN #t_transfers	AS tr ON tr.session_id = ib.session_id
	LEFT JOIN #t_talk		AS tk ON tk.session_id = ib.session_id
	LEFT JOIN #t_rep_calls  AS rc ON rc.session_id = ib.session_id
	LEFT JOIN NaumenDbReport.dbo.mv_incoming_call_project p
		ON p.uuid = q.project_id
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
	GROUP BY ib.call_date, q.project_id, ib.dst_id, g.owner, g.call_kind, p.partnername
	, CASE
		WHEN ib.dst_id LIKE '60%' AND LEN(ib.dst_id)=4 AND ib.dst_id <> '6009'
		THEN N'Перезвон'
		ELSE N'Входящий'
	  END
	  
	-- @changelog dwh-547
	-- добавляем наше поле в табличку
	ALTER TABLE #t_inbound_agg
	ADD [Количество уникальных клиентов] int NULL;

	UPDATE agg
	SET agg.[Количество уникальных клиентов] = 	isnull(uca.[Количество уникальных клиентов], 0)
	FROM #t_inbound_agg agg
	LEFT JOIN #t_unique_clients_agg uca on uca.Дата = agg.[Дата]
		  AND isnull(uca.[Id Проекта], '0x0') = 
			  isnull(agg.[Id Проекта], '0x0')
		  and uca.[Набранный номер] = agg.[Набранный номер]
		  and uca.[Набранный номер расшифровка] = agg.[Набранный номер расшифровка]
		  and uca.call_kind	= agg.call_kind

	ALTER TABLE #t_inbound_agg
	ADD [Количество успешных звонков bigInstallment] int NULL;

	UPDATE agg
	SET agg.[Количество успешных звонков bigInstallment] = isnull(bisa.[Количество успешных звонков bigInstallment], 0)
	FROM #t_inbound_agg agg
	LEFT JOIN #t_big_installment_success_agg bisa on bisa.Дата = agg.[Дата]
		  AND isnull(bisa.[Id Проекта], '0x0') =
			  isnull(agg.[Id Проекта], '0x0')
		  and bisa.[Набранный номер] = agg.[Набранный номер]
		  and bisa.[Набранный номер расшифровка] = agg.[Набранный номер расшифровка]
		  and bisa.call_kind = agg.call_kind

	ALTER TABLE #t_inbound_agg
	ADD [Количество открытых договоров bigInstallment на начало дня] int NULL;

	UPDATE agg
	SET agg.[Количество открытых договоров bigInstallment на начало дня] = isnull(bioca.[Количество открытых договоров bigInstallment на начало дня], 0)
	FROM #t_inbound_agg agg
	LEFT JOIN #t_big_installment_open_contracts_agg bioca
		ON bioca.[Дата] = agg.[Дата]

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
				 , [Количеcтво уникальных номеров клиентов]
				 -- @chnglg 547
				 , [Количество уникальных клиентов]
				 , [Количество успешных звонков bigInstallment]
				 , [Количество открытых договоров bigInstallment на начало дня]
				 , [Вышли в очередь]                              
				 , [Звонок переведен с IVR на оператора]
				 , [Количество ?колбэков?]
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
				, [FRT]                        
				 , [Среднее время разговора]                              
			FROM #t_inbound_agg AS ia
			LEFT JOIN NaumenDbReport.dbo.mv_incoming_call_project p
				ON p.uuid = ia.[Id Проекта]
			ORDER BY [Дата]
		end

		DELETE R
		FROM 
			service.dm_report_inboundCalls_agg AS R
		WHERE 1 = 1
			AND R.[Дата] >= @dtFrom
			AND R.[Дата] < @dtTo
		
		INSERT INTO service.dm_report_inboundCalls_agg
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
			, callbacks_count
			, [Количеcтво уникальных номеров клиентов]
			-- @chnglg 547
			, [Количество уникальных клиентов]
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
			, [FRT]                        
			, [Среднее время разговора]
			, [Количество успешных звонков bigInstallment]
			, [Количество открытых договоров bigInstallment на начало дня]
			, created_at
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
			 , [Количество ?колбэков?]
			 , [Количеcтво уникальных номеров клиентов]
			 -- @chnglg 547
			 , [Количество уникальных клиентов]
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
			 , [FRT]                        
			 , [Среднее время разговора]
			 , [Количество успешных звонков bigInstallment]
			 , [Количество открытых договоров bigInstallment на начало дня]
			 , getdate()
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
