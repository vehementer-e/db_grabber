





CREATE PROCEDURE [finAnalytics].[PBI_calendar]

	
AS
BEGIN

declare @minDate date
declare @maxDate date

set @minDate = (select min(repmonth) from dwh2.finAnalytics.PBR_MONTHLY)
set @maxDate = (select max(repmonth) from dwh2.finAnalytics.PBR_MONTHLY)
select
dt = a.dt
,[repmonth] = a.Month_Value
,[repWeek] = a.Week_Value
,[repmonthName] = FORMAT(a.dt,'MMMM yyyy', 'ru-ru')
,[repmonthShortName] = FORMAT(a.dt,'MMM yy', 'ru-ru')
,[QName] = concat(
					a.id_quartal 
					,' кв. '
					,FORMAT(a.dt,'yy', 'ru-ru')
				)
,[repYear] = YEAR(a.dt)
,[repNum] = concat(
					FORMAT(a.dt,'yyyy', 'ru-ru')
					,FORMAT(a.dt,'MM', 'ru-ru')
					,FORMAT(a.dt,'dd', 'ru-ru')
				  )
,[repMonthNum] = concat(
					FORMAT(a.dt,'yyyy', 'ru-ru')
					,FORMAT(a.dt,'MM', 'ru-ru')
				  )
from dwh2.Dictionary.calendar a --select * from dwh2.Dictionary.calendar
where a.DT between @minDate and EOMONTH(@maxDate)

END
