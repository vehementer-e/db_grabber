

CREATE PROCEDURE [finAnalytics].[repDinamikaPortf]

AS
BEGIN
    select
    [Дата] = a.REPDATE
    ,[ДЕНЬ НЕД.] = a.dayWeekNum
    ,[Тип отчета] = a.repType
    ,[ПОРТФЕЛЬ ОД] = a.restODfull
    ,[РАБОТАЮЩИЙ ПОРТФЕЛЬ] = a.restODwork
    ,[НЕРАБОТАЮЩИЙ ПОРТФЕЛЬ (90+)] = a.restODnotWork
    ,[ДОЛЯ НЕРАБОТАЮЩЕГО  ПОРТФЕЛЯ] = a.restODnotWorkPart
    ,rn = row_number () over (order by a.REPDATE desc) 

    from dwh2.finAnalytics.repDinamikaPortf a

END
