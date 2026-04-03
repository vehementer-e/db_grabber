


CREATE PROCEDURE [finAnalytics].[rep840_2_5]
        @repmonth date,
        --@repdate date,
        @sumRang int

AS
BEGIN
  
	select
    REPMONTH
	, punkt
	, pokazatel
	, case when a.isSumm =1 then a.value/@sumRang else a.value end value
	, comment
	, checkMethod1
	, chekResult1
	, checkMethod2
	, chekResult2
	, checkMethod3
	, chekResult3
	, rownum
    from dwh2.finAnalytics.rep840_2_5 a
	where REPMONTH= @repmonth
	

    
END
