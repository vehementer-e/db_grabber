


CREATE   PROCEDURE [Risk].[etl_Allocation]
    @DateRep DATE = '2025-01-01'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @cols NVARCHAR(MAX);

        SELECT @cols = STRING_AGG(QUOTENAME(period_), ',')
        FROM (
            SELECT DISTINCT FORMAT(request_date, 'yyyy-MM') AS period_
            FROM stg._loginom.Original_response WITH (NOLOCK)
            WHERE request_date >= @DateRep
              AND request_date < CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATE)
        ) AS p;

        IF @cols IS NULL
        BEGIN
            DECLARE @msg NVARCHAR(200) = N'Allocation: нет данных после ' + CONVERT(NVARCHAR(23), @DateRep, 23);
            RAISERROR(@msg, 16, 1);
        END

        IF OBJECT_ID('reports.risk.allocation', 'U') IS NOT NULL
            DROP TABLE reports.risk.allocation;

        DECLARE @sql NVARCHAR(MAX) = N'
;WITH smp AS (
    SELECT 
        person_id, request_date, process, source, cache_flg, validReport_flg, stage, rn, a.is_installment
    FROM (
        SELECT 
            person_id, request_date, process, source, cache_flg, validReport_flg, stage,
            ROW_NUMBER() OVER (PARTITION BY person_id, source, stage ORDER BY request_date) AS rn
        FROM stg._loginom.Original_response WITH (NOLOCK)
        WHERE request_date >= @pDate
          AND process = ''Origination''
          AND source IN (''equifax'', ''JuicyScore'', ''nbch'', ''nbch PV2 score'', ''okbscore'', ''DBrain'', ''fincard'', ''KbkiEqx'')
          AND person_id NOT IN (''19061300000088'', ''19061300000089'', ''20101300041806'', ''21011900071506'', ''21011900071507'')
          AND username = ''service''
    ) r
    LEFT JOIN (
        SELECT DISTINCT number, is_installment
        FROM stg._loginom.application WITH (NOLOCK)
        WHERE stage_date >= DATEADD(DAY, -10, @pDate)
          AND stage = ''Call 1''
    ) a ON a.number = r.person_id
    WHERE r.rn = 1
),
valid_requests AS (
    SELECT 
        FORMAT(request_date, ''yyyy-MM'') AS period_,
        source,
        is_installment,
        SUM(CASE 
                WHEN stage IN (''Call 1'', ''Call 1.2'', ''Call 2'', ''Call 5'')
                     AND (cache_flg IS NULL OR cache_flg = 0)
                     AND validReport_flg = 1
                THEN 1 ELSE 0
            END) AS requests_valid_nocache
    FROM smp
    WHERE request_date < CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATE)
    GROUP BY FORMAT(request_date, ''yyyy-MM''), source, is_installment
),
summed AS (
    SELECT 
        source,
        period_,
        SUM(requests_valid_nocache) OVER (PARTITION BY source, period_) AS total_requests,
        is_installment,
        requests_valid_nocache * 1.0 AS this_type_requests
    FROM valid_requests
),
percentages AS (
    SELECT 
        source,
        CASE WHEN is_installment = 1 THEN ''БЕЗЗАЛОГ'' ELSE ''ПТС'' END AS product_type,
        period_,
        CASE 
            WHEN total_requests = 0 THEN 0.000 
            ELSE ROUND(this_type_requests / total_requests, 3)
        END AS share
    FROM summed
),
all_possible AS (
    SELECT DISTINCT s.source, p.product_type, d.period_
    FROM (SELECT DISTINCT source FROM percentages) s
    CROSS JOIN (SELECT ''БЕЗЗАЛОГ'' AS product_type UNION ALL SELECT ''ПТС'') p
    CROSS JOIN (SELECT DISTINCT period_ FROM percentages) d
),
expanded AS (
    SELECT 
        ap.source,
        ap.product_type,
        ap.period_,
        ISNULL(p.share, 0.000) AS share
    FROM all_possible ap
    LEFT JOIN percentages p
        ON p.source = ap.source AND p.product_type = ap.product_type AND p.period_ = ap.period_
)
SELECT 
    source, 
    product_type, ' + @cols + '
INTO reports.risk.allocation
FROM (
    SELECT source, product_type, period_, share
    FROM expanded
) AS src
PIVOT (
    MAX(share)
    FOR period_ IN (' + @cols + ')
) AS pvt
ORDER BY source, product_type;';

        EXEC sp_executesql @sql, N'@pDate DATE', @pDate = @DateRep;

select*from reports.risk.allocation
ORDER BY source, product_type

        COMMIT TRAN;

    END TRY

    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;

        DECLARE @Body NVARCHAR(MAX) =
        N'Ошибка при выполнении процедуры reports.risk.Allocation

Дата партии: ' + CONVERT(NVARCHAR(23), @DateRep, 23) + '
Строка:      ' + CAST(ERROR_LINE() AS NVARCHAR) + '
Сообщение:   ' + ERROR_MESSAGE() + '
Время сервера: ' + CONVERT(NVARCHAR(19), SYSDATETIME(), 120);

        EXEC msdb.dbo.sp_send_dbmail
             @recipients   = N'a.vlasov@smarthorizon.ru',   
             @subject      = N'Ошибка в reports.risk.Allocation',
             @body         = @Body;

        RAISERROR(@Body, 16, 1);
    END CATCH
END;

