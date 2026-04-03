-- ============================================= 
-- Author: А. Никитин
-- Create date: 24.07.2022
-- Description: DWH-1679 Регулярная отчистка лог таблицы
-- ============================================= 
CREATE   PROC dbo.ShrinkTable_log_older_2_months
	@RowsCountToDelete int = 100000 -- количество удаляемых строк
AS
BEGIN
	--оставлять записи только за текущий и прошедший месяц.
	DECLARE @MinLogDate date
	SELECT @MinLogDate = dateadd(DAY, 1, eomonth(dateadd(MONTH, -2, convert(date, getdate()))))

	DELETE TOP(@RowsCountToDelete) 
	FROM LogDb.dbo._log
	WHERE logDateTime < @MinLogDate

	WHILE @@ROWCOUNT > 0
	BEGIN
		DELETE TOP(@RowsCountToDelete) 
		FROM LogDb.dbo._log
		WHERE logDateTime < @MinLogDate
	END
END

