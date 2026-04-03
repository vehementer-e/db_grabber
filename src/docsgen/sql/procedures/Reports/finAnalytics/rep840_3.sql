


CREATE PROCEDURE [finAnalytics].[rep840_3]
        @repmonth date,
        --@repdate date,
        @sumRang int

AS
BEGIN
  
    select
   a.REPMONTH
   ,a.punkt
   ,a.pokazatel
   ,summ = case when a.punkt in ('3.1','3.2','3.3','3.4') then a.value else a.value/@sumRang end
   ,a.comment
   ,a.checkMethod1
   ,a.chekResult1
   ,a.checkMethod2
   ,a.chekResult2
   ,a.checkMethod3
   ,a.chekResult3
   ,a.rownum
   
    from dwh2.finAnalytics.rep840_3 a
	where a.REPMONTH=@repmonth
    
END
