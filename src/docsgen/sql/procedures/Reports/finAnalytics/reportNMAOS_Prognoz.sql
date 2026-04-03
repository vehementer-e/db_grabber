


CREATE PROCEDURE [finAnalytics].[reportNMAOS_Prognoz]
	@repmonth date
AS
BEGIN
--declare @repmonth date ='2025-08-31'
drop table if exists #prognoz
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

	delete  #prognoz where commet='справочно' and typeres='НМА'
--declare @repmonth date ='2025-08-31'
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
		[Отчетный месяц]=repdate
		,[ОС, НМА]=typeRes
		,[Счет учета перв.ст]=Account
		,[Номер счета]=n_Account
		,[Название счета учета перв.ст]=nameAccount
		,[Счет учета накопл.аморт]=amAccount
		,[Номер счета Ам]=n_AmAccount
		,[Название счета учета накопл.аморт]=nameAmAccount
		,[Дата начала амортизации]=dateBeginAmo
		,[СПИ, дней (БУ)]=spiDay
		,[Дата окончания амортизации]=dateEndAmo
		,[Контрагент]=agent
		,[Комментарий]=commet
		,[СПИ, месяцев (НУ)]=spiMonthNu
		,[Первоначальная стоимость на начало года]=firstPriceBeginYear
		,[Накопленная амортизация на начало года]= accumAmoBeginYear
		,[Остаточная стоимость на начало года]= resPriceBeginYear
		,[Первоначальная стоимость на дату]=firstPriceDate
		,[Амортизация за период]= summAmo_Date
		,[Накопленная амортизация на дату]= accumAmo_Date
		,[Остаточная стоимость на дату]= resPrice_Date
		,[Оставшийся срок, дней, на дату]=countDayOst_Date
		,[Оставшийся срок, дн. Расчетный]= countDayOst_Date_Calc
		,[Амортизация за 1 день]= summAmo_Day
		,[Амортизация за месяц]=summAmo_Month
		,[Контроль]= check1
		,[Контроль остаточной стоимости]= check2
		,flag=0
from #prognoz
union all
select
		[Отчетный месяц]=[Дата]
		,[ОС, НМА]=[ОС, НМА]
		,[Счет учета перв.ст]=''
		,[Номер счета]=0
		,[Название счета учета перв.ст]=''
		,[Счет учета накопл.аморт]=''
		,[Номер счета Ам]=0
		,[Название счета учета накопл.аморт]=''
		,[Дата начала амортизации]=null
		,[СПИ, дней (БУ)]=0
		,[Дата окончания амортизации]=null
		,[Контрагент]=''
		,[Комментарий]=''
		,[СПИ, месяцев (НУ)]=0
		,[Первоначальная стоимость на начало года]=0
		,[Накопленная амортизация на начало года]= 0
		,[Остаточная стоимость на начало года]= 0
		,[Первоначальная стоимость на дату]=first_value([Первоначальная стоимость])over(partition by [ОС, НМА] order by [Дата])
		,[Амортизация за период]= 0
		,[Накопленная амортизация на дату]= sum([Накопленная амортизация])over(partition by [ОС, НМА] order by [Дата])
		,[Остаточная стоимость на дату]= sum([Остаточная стоимость])over(partition by [ОС, НМА] order by [Дата])
		,[Оставшийся срок, дней, на дату]=0
		,[Оставшийся срок, дн. Расчетный]= 0
		,[Амортизация за 1 день]= 0
		,[Амортизация за месяц]=[Амортизация за месяц]
		,[Контроль]= 0
		,[Контроль остаточной стоимости]= 0
		,flag=1
from cte_TT

order by [Счет учета перв.ст],[Отчетный месяц]
END
