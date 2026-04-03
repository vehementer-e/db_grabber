

CREATE PROCEDURE [finAnalytics].[rep840_3_Detail]
        @repmonth date,
        --@repdate date,
        @sumRang int

AS
BEGIN
  
    select
   a.REPMONTH
   ,a.punkt
   ,a.BS
   ,a.groupName
   ,a.pokazatel
   ,summ = a.value--/@sumRang
   ,a.comment
   ,a.checkMethod1
   ,a.chekResult1
   ,a.checkMethod2
   ,a.chekResult2
   ,a.checkMethod3
   ,a.chekResult3
   ,a.rownum
   
    from dwh2.finAnalytics.rep840_3_detail a
	where a.REPMONTH=@repmonth
    
END
