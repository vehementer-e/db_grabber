-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[report_ManualChecks]
--      @StartDate = <value>,
--      @EndDate = <value>;
-- Параметры соответствуют объявлению процедуры ниже.
CREATE   PROCEDURE [dbo].[report_ManualChecks]
    @StartDate DATE,
    @EndDate   DATE
AS
BEGIN

    IF @StartDate > @EndDate
    BEGIN
        RAISERROR ('Start date cannot be greater than end date.', 16, 1);
        RETURN;
    END;

    SELECT 
        request_creation_date,  -- from ClientRequest
		request_number,         -- from ClientRequest
		request_client_name,    -- from ClientRequest
		request_status,         -- rs.request_status - это статус в ClientRequestHistory 
		request_stage_start,    -- дата в request_stages для данного request_status
		task_status,            -- ts.idTaskStatus
		task_stage_start,
		task_stage_end,
		next_stage,
		task_status_owner,
		check_list_item_id,
		checklist_name,
		checklist_status
    FROM dbo.reportManualChecks
    WHERE request_creation_date >= @StartDate
      AND request_creation_date < DATEADD(DAY, 1, @EndDate);
END;