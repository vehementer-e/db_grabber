



CREATE PROCEDURE [finAnalytics].[repPL843_part3]
	@repMonthFrom date,
	@repMonthTo date

AS
BEGIN

    /*SELECT
	[repmonth]  =a.[repmonth]
	,[BIrowNum] = 1
	,[pokazatel] = '2.39.1'
	,[amount] = sum([restOUT_BU]) *-1
	FROM [dwh2].[finAnalytics].[repPLAccRests] a
	inner join [dwh2].[finAnalytics].[SPR_PL_ACC] b on a.accUID=b.id
	where repmonth between @repmonthFrom and @repmonthTo
	and b.is840calc='2.39.1'
	group by a.[repmonth]  

	union all

	SELECT
	[repmonth]  =a.[repmonth]
	,[BIrowNum] = 2
	,[pokazatel] = '2.39.2'
	,[amount] = sum([restOUT_BU]) *-1
	FROM [dwh2].[finAnalytics].[repPLAccRests] a
	inner join [dwh2].[finAnalytics].[SPR_PL_ACC] b on a.accUID=b.id
	where repmonth between @repmonthFrom and @repmonthTo
	and b.is840calc='2.39.2'
	group by a.[repmonth]  

	union all

	SELECT
	[repmonth]  =a.[repmonth]
	,[BIrowNum] = 3
	,[pokazatel] = '2.39.3'
	,[amount] = sum([restOUT_BU]) *-1
	FROM [dwh2].[finAnalytics].[repPLAccRests] a
	inner join [dwh2].[finAnalytics].[SPR_PL_ACC] b on a.accUID=b.id
	where repmonth between @repmonthFrom and @repmonthTo
	and b.is840calc='2.39.3'
	group by a.[repmonth]  

	union all

	SELECT
	[repmonth]  =a.[repmonth]
	,[BIrowNum] = 4
	,[pokazatel] = '2.39.4'
	,[amount] = sum([restOUT_BU]) *-1
	FROM [dwh2].[finAnalytics].[repPLAccRests] a
	inner join [dwh2].[finAnalytics].[SPR_PL_ACC] b on a.accUID=b.id
	where repmonth between @repmonthFrom and @repmonthTo
	and b.is840calc='2.39.4'
	group by a.[repmonth]  

	union all

	SELECT
	[repmonth]  =a.[repmonth]
	,[BIrowNum] = 5
	,[pokazatel] = '2.39.5'
	,[amount] = sum([restOUT_BU]) *-1
	FROM [dwh2].[finAnalytics].[repPLAccRests] a
	inner join [dwh2].[finAnalytics].[SPR_PL_ACC] b on a.accUID=b.id
	where repmonth between @repmonthFrom and @repmonthTo
	and b.is840calc='2.39.5'
	group by a.[repmonth]  
	*/

	SELECT [repmonth]
      ,[BIrowNum]
      ,[pokazatel]
      ,[amount]
      ,[created]
  FROM [dwh2].[finAnalytics].[repPLf843_part3]
  where repmonth between @repmonthFrom and @repmonthTo

END
