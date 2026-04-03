



CREATE PROCEDURE [finAnalytics].[reportNMAOS_Svod]
	@repmonth date
AS
BEGIN
create table #prognoz (
[repdate] [date] NULL,
	[typeRes] [nvarchar](30) NULL,
	[Account] [varchar](20) NULL,
	[n_Account] [int] NULL,
	[nameAccount] [nvarchar](500) NULL,
	[amAccount] [varchar](20) NULL,
	[n_AmAccount] [int] NULL,
	[nameAmAccount] [nvarchar](500) NULL,
	[dateBeginAmo] [date] NULL,
	[spiDay] [int] NULL,
	[dateEndAmo] [date] NULL,
	[agent] [nvarchar](500) NULL,
	[commet] [nvarchar](300) NULL,
	[spiMonthNu] [int] NULL,
	[firstPriceBeginYear] [float] NULL,
	[accumAmoBeginYear] [float] NULL,
	[resPriceBeginYear] [float] NULL,
	[firstPriceDate] [float] NULL,
	[summAmo_Date] [float] NULL,
	[accumAmo_Date] [float] NULL,
	[resPrice_Date] [float] NULL,
	[countDayOst_Date] [float] NULL,
	[countDayOst_Date_Calc] [float] NULL,
	[summAmo_Day] [float] NULL,
	[summAmo_Month] [float] NULL,
	[check1] [int] NULL,
	[check2] [int] NULL
)
	insert into #prognoz (repdate, typeRes, Account, n_Account, nameAccount, amAccount, n_AmAccount, nameAmAccount, dateBeginAmo
												, spiDay, dateEndAmo, agent, commet, spiMonthNu, firstPriceBeginYear, accumAmoBeginYear, resPriceBeginYear
												, firstPriceDate, summAmo_Date, accumAmo_Date, resPrice_Date
												, countDayOst_Date, countDayOst_Date_Calc, summAmo_Day, summAmo_Month, check1, check2)
	exec dwh2.finAnalytics.calcNMAOS_Prognoz	@repmonth
;with cte_TT as (
	select	
		
		[Дата]=cast (@repmonth as date)
		,[ОС, НМА]=l1.typeRes
		,[Первоначальная стоимость]=sum(l1.p1)
		,[Амортизация за месяц]=sum(l1.p2)
		,[Накопленная амортизация]=sum(l1.p3)
		,[Остаточная стоимость]=sum(l1.p4)
	from (
		select 
			typeRes=typeRes
			,Account
			,p1=max(firstPriceDate)--/1000000
			,p2=max(summAmo_Date)--/1000000
			,p3=max(accumAmo_Date)--/1000000
			,p4=max(resPrice_Date)--/1000000
		from #prognoz

		group by Account, typeRes
	)l1
	group by l1.typeRes
	union all
	select	
		[Дата]=l1.dat
		,[ОС, НМА]=l1.typeRes
		,[Первоначальная стоимость]=0
		,[Амортизация за месяц]=l1.p2
		,[Накопленная амортизация]=l1.p2
		,[Остаточная стоимость]=-1*l1.p2
	from (
		select 
			dat=repdate
			,typeRes=typeRes
			,p2=sum(summAmo_Month)--/1000000
		from #prognoz
		
		group by typeRes,repdate
	)l1

)

select 
	[Дата]
	,[ОС, НМА]
	,[Первоначальная стоимость]=first_value([Первоначальная стоимость])over(partition by [ОС, НМА] order by [Дата])
	,[Амортизация за месяц]
	,[Накопленная амортизация]=sum([Накопленная амортизация])over(partition by [ОС, НМА] order by [Дата])
	,[Остаточная стоимость]=sum([Остаточная стоимость])over(partition by [ОС, НМА] order by [Дата])
from cte_TT

order by [ОС, НМА],[Дата]
END
