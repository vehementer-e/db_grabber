

create    procedure [dbo].[ShrinkTable_etlLog_older_3_months]
@RowsCountToDelete int = 100000-- количество удаляемых строк
as

--Создано в рамках задачи: https://jira.carmoney.ru/browse/DWH-1323

DELETE top(@RowsCountToDelete) FROM [LogDb].[dbo].[etlLog]
WHERE EventDateTime < dateadd(MONTH,-3, getdate())

while @@ROWCOUNT > 0
	begin

			DELETE top(@RowsCountToDelete) FROM [LogDb].[dbo].[etlLog]
			WHERE EventDateTime < dateadd(MONTH,-3, getdate())

	end



