
CREATE PROCEDURE [finAnalytics].[rep840]
        @repmonth date,
        --@repdate date,
        @sumRang int

AS
BEGIN
    with ID_LIST as (
    select id
    from dwh2.finAnalytics.rep840 a
    where a.REPMONTH=@repmonth
    --and a.REPDATE=@repdate
    )

    select
    a.repmonth
    ,a.REPDATE
    ,a.razdel
    ,a.punkt
    ,a.pokazatel
    ,case when a.isSumm =1 then a.value/@sumRang else a.value end value
    ,a.comment
    ,a.checkMethod1
    ,a.chekResult1
    ,a.checkMethod2
    ,a.chekResult2
    ,a.checkMethod3
    ,a.chekResult3
    ,a.rownum
    from dwh2.finAnalytics.rep840 a
    inner join id_list on a.id=id_list.id
    
END
