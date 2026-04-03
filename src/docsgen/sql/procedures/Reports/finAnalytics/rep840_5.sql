

CREATE PROCEDURE [finAnalytics].[rep840_5]
        @repmonth date

AS
BEGIN
    
	declare @maxRowNum int
set @maxRowNum = (select max([rownum]) + 1 FROM [dwh2].[finAnalytics].[rep840_5]
       where repYear = Year(@repmonth))

SELECT [repYear]
      ,[REPMONTH]
      ,[rownum]
      ,[repCode]
      ,[sumODSales]
      ,[sumProsSales]
      ,[countDog]
      ,[sumSales]
  FROM [dwh2].[finAnalytics].[rep840_5]
  where repYear = Year(@repmonth)

union all

select
[repYear] = null
,[REPMONTH] = null
,[rownum] = @maxRowNum
,[repCode] = 'Контроль: '
,[sumODSales] = (select
					sumAmount = sum(sumAmount)
					from(
					select
					sumAmount = sum(value) * -1
					from dwh2.[finAnalytics].[rep840]
					where repmonth = @repmonth
					and punkt in ('2.1','2.11')

					union all

					SELECT sum([sumODSales])
					  FROM [dwh2].[finAnalytics].[rep840_5]
					  where repYear = Year(@repmonth)
					  and ([countDog] >0 or [sumSales] >0)
					) l1)
,[sumProsSales] = (
					select
						sumAmount = round(sum(sumAmount),0)
						from(
						select
						sumAmount = sum(col3 + col4 + col5 + col6 + col7 + col8 + col9 + col10 + col11 + col12 + col13 + col14 + col15 + col16 + col17) * -1

						from dwh2.[finAnalytics].[rep840_4]
						where repmonth = @repmonth
						and col1 in ('4.6.1','4.7.1','4.8.1','4.9.1','4.10.1')

						union all

						SELECT round(sum([sumProsSales]),0)
						  FROM [dwh2].[finAnalytics].[rep840_5]
						  where repYear = Year(@repmonth)
						) l1
					)
,[countDog] = (
				select
					sumAmount = sum(sumAmount)
					from(
					select
					sumAmount = sum(value) * -1
					from dwh2.[finAnalytics].[rep840]
					where repmonth = @repmonth
					and punkt in ('2.5','2.15')


					union all

					SELECT sum([countDog])
					FROM [dwh2].[finAnalytics].[rep840_5]
					where repYear = Year(@repmonth)
					) l1
				)
,[sumSales] = (
				select
					sumAmount = sum(sumAmount)
					from(
					select
					sumAmount = sum(value) * -1
					from dwh2.[finAnalytics].[rep840]
					where repmonth = @repmonth
					and punkt in ('2.6','2.16')


					union all

					SELECT sum([sumSales])
					FROM [dwh2].[finAnalytics].[rep840_5]
					where repYear = Year(@repmonth)
					) l1
				)

END
