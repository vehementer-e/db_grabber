-- =======================================================
-- Created: 09.03.2022. А.Никитин
-- Description:	DWH-1602 Мониторинг заявок. МФО с не корректным телефонным номером
-- =======================================================
-- Usage: запуск процедуры с параметрами
-- EXEC [dbo].[Monitoring_MFO_incorrect_phone_number] @param1 = <value>, @param2 = <value>;
-- Список и типы параметров смотрите в объявлении процедуры ниже.
CREATE PROCEDURE [dbo].[Monitoring_MFO_incorrect_phone_number]
AS
BEGIN

	
	drop table if exists #t_result
	select 
				nRow = ROW_NUMBER() OVER(order by t.Дата desc),
				t.Номер,
				Дата = convert(varchar(19), dateadd(year,-2000, t.Дата), 120),
				t.ТелефонМобильный
	into #t_result
	from _1cMFO.Документ_ГП_Заявка as t
			Where ISNUMERIC(t.ТелефонМобильный) = 0
			and t.ТелефонМобильный > ''
			and dateadd(year,-2000, t.Дата) >'2022-01-01'
		
	if exists (select top(1) 1 from #t_result)
	begin 
		DECLARE @tableHTML NVARCHAR(MAX) ;
		SELECT @tableHTML =
			N'<H1>МФО с не корректным телефонным номером</H1>' +
			N'<table border="1">' +
			N'<tr><th>№</th><th>НомерЗаявки</th><th>Дата</th><th>ТелефонМобильный</th></tr>' +
			CAST ( ( 
				select 
					td = nRow,'',
					td = t.Номер,'',
					td = t.Дата,'',
					td = t.ТелефонМобильный
				from #t_result t
				order by t.nRow
			FOR XML PATH('tr'), TYPE
			) AS NVARCHAR(MAX) ) +
			N'</table>'


		--check
		--SELECT @tableHTML

		EXEC msdb.dbo.sp_send_dbmail 
			@recipients   = '112@carmoney.ru',
			@copy_recipients = 'dwh112@carmoney.ru',
			--@recipients   = 'AnYu.Nikitin@techmoney.ru',
			@profile_name = 'Default',
			@subject      = 'Мониторинг заявок. МФО с не корректным телефонным номером',
			@body         = @tableHTML,
			@body_format  = 'HTML'
	end 
END
