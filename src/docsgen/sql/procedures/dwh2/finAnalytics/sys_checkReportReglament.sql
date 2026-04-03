

CREATE PROCEDURE [finAnalytics].[sys_checkReportReglament]

AS
BEGIN
declare @calend table(
	[Дата] date not null
	,[Номер рабочего дня] int not null
)

INSERT INTO @calend
select
[Дата] = dt
,[Номер рабочего дня] = ROW_NUMBER() over (order by dt)
from dwh2.Dictionary.calendar
where month(DT) = month(cast(getdate() as date)) and year(DT) = year(cast(getdate() as date))
and isRussiaDayOff != 1

drop table if exists #check
select 
	id=row_number()over (order by l1.emailUID)
	,msg=string_agg(nameReport,',')
	,emailUID
	,respons

into #check

from 
(
		select
			[nameReport] = r.[nameReport]
			,r.emailUID
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
			,respons
		from dwh2.finAnalytics.reportReglament r
		left join @calend dnum on dnum.[Дата] = cast(getdate() as date)
		left join @calend day1 on day1.[Номер рабочего дня] = r.[preCalcDayNum]
		left join @calend day2 on day2.[Номер рабочего дня] = r.[interCalcDayNum]
	) l1
 where l1.interCalcCheck=2 or l1.preCalcCheck=2
 group by emailUID,respons

 select * from #check

 --select * from #check

declare @countRow int = (select count(*) from #check)
declare @i int = @countRow
declare @emailUID varchar(20), @msg nvarchar(200)
while @i>0 
	begin
		select @emailUID=emailUID, @msg=msg from #check where id=@i and emailUID!='1'
		exec dwh2.finAnalytics.sendEmail 'Регламент ФинДепа нарушен!',@msg,@emailUID
		set @i=@i-1
	end

set @i=@countRow
set @msg=''
while @i>0 
	begin
		
		select @msg=concat(@msg,concat('[',msg,']','   ',respons,char(10))) from #check where id=@i
	print 'fff'	
		set @i=@i-1
	end
 if @countRow>0 exec dwh2.finAnalytics.sendEmail 'Регламент ФинДепа нарушен!',@msg,'1'

END
