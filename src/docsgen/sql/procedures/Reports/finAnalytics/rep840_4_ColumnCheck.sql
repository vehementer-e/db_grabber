
CREATE PROCEDURE [finAnalytics].[rep840_4_ColumnCheck]
        @repmonth date
        --@repdate date

AS
BEGIN
   
    select
    REPMONTH, 
    REPDATE, 
    Pokazatel, 
    Check3algo, 
    Check3result, 
    Check4algo, 
    Check4result, 
    Check6algo, 
    Check6result, 
    Check8algo, 
    Check8result, 
    Check10algo, 
    Check10result, 
    Check11algo, 
    Check11result, 
    Check13algo, 
    Check13result, 
    Check14algo, 
    Check14result, 
    Check15algo, 
    Check15result, 
    Check17algo, 
    Check17result

    
    from dwh2.finAnalytics.rep840_4_columnCheck a
    where a.repmonth = @repmonth --and a.repdate=@repdate
    order by rownum

END
