
CREATE PROCEDURE [finAnalytics].[repMicrozaimRR]

AS
BEGIN
    select 
    [Отчетный месяц] = a.REPMONTH
    ,[Тип данных] = a.dataType
    ,[Отчетная дата] = a.REPDATE
    ,[Остаток ОД на конец дня]  =a.restOD
	----Остаток ОД = Остаток ОД на конец последнего дня предыдущего месяца 
	--				+ Итого RR выдачи за текущий месяц
	--				- Итого RR погашения за текущий месяц
	--				- Итого Цессия ОД за текущий месяц
	--				- Итого Погашение мошенники и резервы за текущий месяц
	,[Остаток ОД на конец дня с учетом RR]  =c.restOD
											+a.salesRR
											-iif(a.REPDATE<>eomonth(a.REPDATE),a.pogasheniaRR,sum(a.pogashenia-a.banRez) over(partition by a.REPMONTH))
											-sum(a.cessia)over(partition by a.REPMONTH)
											-sum(a.banRez)over(partition by a.REPMONTH)	
    ,[Выдачи] = a.sales
    ,[Погашения / Списания] = a.pogashenia-a.banRez
    ,[Прирост ОД (с начала месяца)] = a.restOD - b.restOD
    ,[Проверка] = case when abs(round(a.restOD - a.sales + a.pogashenia+a.cessia,0) - round(lead(a.restOD) over (order by a.REPDATE desc),0)) > 1000 then 'Ошибка' else 'ОК' end
    ,[Текущий - предыдущий остаток] = cast (round(a.restOD - a.sales + a.pogashenia+a.cessia,0) - round(lead(a.restOD) over (order by a.REPDATE desc),0) as money)
    ,[Цессия] = a.cessia
	,[Погашение мошенники и резервы]=a.banRez
	,[RR погашения]=iif(a.REPDATE<>eomonth(a.REPDATE),a.pogasheniaRR,sum(a.pogashenia-a.banRez) over(partition by a.REPMONTH))
	,[RR выдачи]=a.salesRR--iif(a.REPDATE<>eomonth(a.REPDATE),a.salesRR,sum(a.sales) over(partition by a.REPMONTH))
	,[Exp RR дата]=format(dateadd(day,1,c.REPDATE),'M','ru-RU')
	,[Exp RR погашения]=iif(a.REPDATE=eomonth(a.REPDATE),c.pogasheniaRR,0)
	,[Exp точность RR погашение]=iif(a.REPDATE=eomonth(a.REPDATE)
										,iif(sum(a.pogashenia-a.banRez)over (partition by a.repmonth)>0,1-abs(((sum(a.pogashenia-a.banRez) over (partition by a.repmonth)-c.pogasheniaRR)/
												sum(a.pogashenia-a.banRez)over (partition by a.repmonth))),0)
										,0)


    from dwh2.finAnalytics.repMicrozaim a
    left join dwh2.finAnalytics.repMicrozaim b on dateadd(DAY,-1,DATEFROMPARTS(year(a.REPMONTH),month(a.repmonth),1)) =b.REPDATE
	left join dwh2.finAnalytics.repMicrozaim c on eomonth(dateadd(month,-1,a.REPDATE)) =c.REPDATE
--	left join dwh2.finAnalytics.repMicrozaim c on eomonth(dateadd(month,-1,a.repdate))=c.REPDATE
    --where a.restOD !=0

    order by a.REPDATE desc
	
END
