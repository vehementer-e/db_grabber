
CREATE PROCEDURE [finAnalytics].[repMicrozaim]

AS
BEGIN

    select 
    [Отчетный месяц] = a.REPMONTH
    ,[Тип данных] = a.dataType
    ,[Отчетная дата] = a.REPDATE
    ,[Остаток ОД на конец дня]  =a.restOD
    ,[Выдачи] = a.sales
    ,[Погашения / Списания] = a.pogashenia
    ,[Прирост ОД (с начала месяца)] = a.restOD - b.restOD
    ,[Проверка] = case when abs(round(a.restOD - a.sales + a.pogashenia+a.cessia,0) - round(lead(a.restOD) over (order by a.REPDATE desc),0)) > 1000 then 'Ошибка' else 'ОК' end
    ,[Текущий - предыдущий остаток] = cast (round(a.restOD - a.sales + a.pogashenia+a.cessia,0) - round(lead(a.restOD) over (order by a.REPDATE desc),0) as money)
    ,[Цессия] = a.cessia
	,[Погашение мошенники и резервы]=a.banRez
    from dwh2.finAnalytics.repMicrozaim a
    left join dwh2.finAnalytics.repMicrozaim b on dateadd(DAY,-1,DATEFROMPARTS(year(a.REPMONTH),month(a.repmonth),1)) =b.REPDATE

    --where a.restOD !=0

    order by a.REPDATE desc

END
