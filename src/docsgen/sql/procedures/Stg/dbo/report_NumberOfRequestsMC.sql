-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[report_NumberOfRequestsMC] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   PROCEDURE [dbo].[report_NumberOfRequestsMC]
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
        request_number,
		request_creation_date,
		request_status,
		stage_start_date,
		task_status,
		time_in_status
    FROM dbo.reportNumberOfRequestsMC
    WHERE request_creation_date >= @StartDate
      AND request_creation_date < DATEADD(DAY, 1, @EndDate);
END;