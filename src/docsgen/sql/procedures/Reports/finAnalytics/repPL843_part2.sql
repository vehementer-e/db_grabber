


CREATE PROCEDURE [finAnalytics].[repPL843_part2]
	@repMonthFrom date,
	@repMonthTo date

AS
BEGIN

    /*SELECT
	[repmonth]  =a.[repmonth]
	,[BIrowNum] = 1
	,[pokazatel] = 'Амортизация ОС и НМА'
	,[symbolName1] = '55301'
	,[symbolName2] = '55303'
	,[amount] = sum([restOUT_BU]) *-1
	FROM [dwh2].[finAnalytics].[repPLAccRests] a
	inner join [dwh2].[finAnalytics].[SPR_PL_ACC] b on a.accUID=b.id
	where repmonth between @repmonthFrom and @repmonthTo
	and b.[acc1order] like '71%' 
	and simbol5 in ('55301','55303')
	group by a.[repmonth]  

	union all

	SELECT
	[repmonth]  =a.[repmonth]
	,[BIrowNum] = 2
	,[pokazatel] = 'Резервы по пене и госпошлине, всего'
	,[symbolName1] = '522'
	,[symbolName2] = '533'
	,[amount] = sum([restOUT_BU]) *-1
	FROM [dwh2].[finAnalytics].[repPLAccRests] a
	inner join [dwh2].[finAnalytics].[SPR_PL_ACC] b on a.accUID=b.id
	where repmonth between @repmonthFrom and @repmonthTo
	and b.[acc1order] like '71%' 
	and simbol3 in ('522','533')
	group by a.[repmonth]

	union all

	SELECT
	[repmonth]  =a.[repmonth]
	,[BIrowNum] = 3
	,[pokazatel] = 'Резервы по пене и госпошлине (мошенники)'
	,[symbolName1] = '522'
	,[symbolName2] = '533'
	,[amount] = sum([restOUT_BU]) *-1
	FROM [dwh2].[finAnalytics].[repPLAccRests] a
	inner join [dwh2].[finAnalytics].[SPR_PL_ACC] b on a.accUID=b.id
	where repmonth between @repmonthFrom and @repmonthTo
	and b.[accNUM] ='71702810005330400002' 
	and simbol3 in ('522','533')
	group by a.[repmonth]*/

	SELECT [repmonth]
      ,[BIrowNum]
      ,[pokazatel]
      ,[symbolName1]
      ,[symbolName2]
      ,[amount]
      ,[created]
  FROM [dwh2].[finAnalytics].[repPLf843_part2]
  where repmonth between @repmonthFrom and @repmonthTo

END
