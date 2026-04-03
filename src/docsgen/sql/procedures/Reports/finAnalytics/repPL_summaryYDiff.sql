




CREATE PROCEDURE [finAnalytics].[repPL_summaryYDiff]
	@repMonthFrom date,
	@repMonthTo date

AS
BEGIN

    select
l1.repmonth
,l1.rowNum
,l1.rowName
,l1.pokazatel
,amountTek = isnull(l1.amountTek,0)
,amountPrev = isnull(l2.amountTek,0)
,amountDiff = isnull(l1.amountTek,0) - isnull(l2.amountTek,0)
from(
select
a.repmonth
,a.rowNum
,a.rowName
,a.pokazatel
--,amountTek = a.amountTek + isnull(spod.sumAmount,0)
,amountTek = case when month(a.repmonth) = 12 then a.amountTek + isnull(spod.sumAmount,0) else a.amountTek end

from dwh2.finAnalytics.repPLf843_summary a
left join dwh2.[finAnalytics].[repPLf843SPOD] spod on 
						a.rowName = spod.[rowName] 
						and spod.repYear = DATEFROMPARTS(year(@repMonthTo),1,1)
						and spod.rowName in ('1','2','4','13','15','20','21','23','19')


where repmonth between @repMonthFrom and @repMonthTo
) l1

left join (
select
a.repmonth
,a.rowNum
,a.rowName
,a.pokazatel
--,amountTek = a.amountTek + isnull(spod.sumAmount,0)
,amountTek = case when month(a.repmonth) = 12 then a.amountTek + isnull(spod.sumAmount,0) else a.amountTek end

from dwh2.finAnalytics.repPLf843_summary a
left join dwh2.[finAnalytics].[repPLf843SPOD] spod on 
						a.rowName = spod.[rowName] 
						and spod.repYear = DATEFROMPARTS(year(dateadd(year,-1,@repMonthTo)),1,1)
						and spod.rowName in ('1','2','4','13','15','20','21','23','19')

where repmonth between dateadd(year,-1,@repMonthFrom) and dateadd(year,-1,@repMonthTo)
) l2 on month(l1.repmonth) = month(l2.repmonth) and l1.rowNum = l2.rowNum
  
END
