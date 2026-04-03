
CREATE PROCEDURE [finAnalytics].[rep840_4]
        @repmonth date,
        --@repdate date,
        @sumRang int

AS
BEGIN
    with ID_LIST as (
    select id
    from dwh2.finAnalytics.rep840_4 a
    where a.REPMONTH=@repmonth
    --and a.REPDATE=@repdate
    )

    select
    REPMONTH, 
    REPDATE, 
    rownum,
    col1, 
    col2, 
    [col3] = col3 / @sumRang , 
    [col4] = col4 / @sumRang , 
    [col5] = col5 / @sumRang , 
    [col6] = col6 / @sumRang , 
    [col7] = col7 / @sumRang , 
    [col8] = col8 / @sumRang , 
    [col9] = col9 / @sumRang , 
    [col10] = col10 / @sumRang , 
    [col11] = col11 / @sumRang , 
    [col12] = col12 / @sumRang , 
    [col13] = col13 / @sumRang , 
    [col14] = col14 / @sumRang , 
    [col15] = col15 / @sumRang , 
    [col16] = col16 / @sumRang , 
    [col17] = col17 / @sumRang , 
    col18, 
    comment, 
    checkMethod2, 
    chekResult2, 
    checkMethod3, 
    chekResult3

    from dwh2.finAnalytics.rep840_4 a
    inner join id_list on a.id=id_list.id

END
