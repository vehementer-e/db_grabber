-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[report_IncomingFlows] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE   PROCEDURE [dbo].[report_IncomingFlows]
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
        *
    FROM dbo.reportIncomingFlows
    WHERE request_creation_date >= @StartDate
      AND request_creation_date < DATEADD(DAY, 1, @EndDate);
END;