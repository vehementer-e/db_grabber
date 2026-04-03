

CREATE PROCEDURE [finAnalytics].[reportReglament]

AS
BEGIN
declare @calend table(
	[Дата] date not null
	,[Номер рабочего дня] int not null
)

INSERT INTO @calend
select
[Дата] = dt
--,id_weekday
--,isRussiaDayOff
,[Номер рабочего дня] = ROW_NUMBER() over (order by dt)
from dwh2.Dictionary.calendar
where month(DT) = month(cast(getdate() as date)) and year(DT) = year(cast(getdate() as date))
and isRussiaDayOff != 1

select
	[nameReport] = r.[nameReport]
	,[respons]=r.[respons]
	,[link]=r.[link]
	,[typeDate]=r.[typeDate]
	,[preCalc]=r.[preCalc]
	,[interCalc]=r.[interCalc]
	,[finalCalc]=r.[finalCalc]
	,[lastCalcDate]=r.[lastCalcDate]
	,[maxDataDate]=r.[maxDataDate]

	,[preCalcCheck]= case 
						when dnum.[Номер рабочего дня] = r.preCalcDayNum
						and isnull([lastCalcDate],dateFromParts(2000,1,1)) < cast(getdate() as date) then 1
						when dnum.[Номер рабочего дня] > r.preCalcDayNum
						and isnull([lastCalcDate],dateFromParts(2000,1,1)) < day1.Дата then 2
						else 0 end
	,[interCalcCheck]= case 
						when dnum.[Номер рабочего дня] = r.[interCalcDayNum]
						and isnull([lastCalcDate],dateFromParts(2000,1,1)) < cast(getdate() as date) then 1
						when dnum.[Номер рабочего дня] > r.[interCalcDayNum]
						and isnull([lastCalcDate],dateFromParts(2000,1,1)) < day2.Дата then 2
						else 0 end
	,[maxDataDateSG]=r.[maxDataDateSG]
	,[maxDataDateSTG]=r.[maxDataDateSTG]
from dwh2.finAnalytics.reportReglament r

left join @calend dnum on dnum.[Дата] = cast(getdate() as date)

left join @calend day1 on day1.[Номер рабочего дня] = r.[preCalcDayNum]
left join @calend day2 on day2.[Номер рабочего дня] = r.[interCalcDayNum]

END
