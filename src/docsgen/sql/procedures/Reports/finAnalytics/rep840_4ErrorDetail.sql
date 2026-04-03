
CREATE PROCEDURE [finAnalytics].[rep840_4ErrorDetail]
        @repmonth date
        --@repdate date

AS
BEGIN
    select
    REPMONTH, REPDATE, stroka, pokazatel, prosPeriod, dogNumn, sumReservNU, sumPBR, delta
    from dwh2.finAnalytics.rep840_4_errorDetail
    where REPMONTH=@repmonth --and REPDATE=@repdate

END
