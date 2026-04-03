
CREATE PROCEDURE [finAnalytics].[reestrCB_Q_Check2]
    @repMonth date
AS
BEGIN

declare @monthFrom date = dateadd(month,-2,@repMonth)
declare @month2 date = dateadd(month,-1,@repMonth)
declare @monthTo date = @repMonth


Drop Table if Exists #reestr
select
*
into #reestr
from dwh2.finAnalytics.reest_CB_Q a
where (a.monthFrom = @monthFrom and a.monthTo = @monthTo)



delete from dwh2.[finAnalytics].[reest_CB_Q_check2] where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo

--p1d1
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 1
,[Показатель] = 'Сумма задолженности по ОД'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = (
				select
				[SumBU] = sum([SumBU] )
				from(
				select
				[SumBU] = sum(isnull(value,0))
				from dwh2.[finAnalytics].[rep840]
				where [REPMONTH] = @monthFrom
				and punkt in ('2.1','2.11')
				union all
				select
				[SumBU] = sum(isnull(value,0))*-1
				from dwh2.[finAnalytics].[rep840_2_5]
				where [REPMONTH] = @monthFrom
				and punkt in ('2.35')
				) l1
)

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 1
,[Показатель] = 'Сумма задолженности по ОД'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = (
				select
				[SumBU] = sum(isnull(restOD1,0))
				from #reestr
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 1
,[Показатель] = 'Сумма задолженности по ОД'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=1
				and [Показатель] = 'Сумма задолженности по ОД'
)

--p1d2
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 1
,[Показатель] = 'Сумма задолженности по ОД'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = (
				select
				[SumBU] = sum([SumBU] )
				from(
				select
				[SumBU] = sum(isnull(value,0))
				from dwh2.[finAnalytics].[rep840]
				where [REPMONTH] = @month2
				and punkt in ('2.1','2.11')
				union all
				select
				[SumBU] = sum(isnull(value,0))*-1
				from dwh2.[finAnalytics].[rep840_2_5]
				where [REPMONTH] = @month2
				and punkt in ('2.35')
				) l1
)

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 1
,[Показатель] = 'Сумма задолженности по ОД'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = (
				select
				[SumBU] = sum(isnull(restOD2,0))
				from #reestr
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 1
,[Показатель] = 'Сумма задолженности по ОД'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=2
				and [Показатель] = 'Сумма задолженности по ОД'
)

--p1d3
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 1
,[Показатель] = 'Сумма задолженности по ОД'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = (
				select
				[SumBU] = sum([SumBU] )
				from(
				select
				[SumBU] = sum(isnull(value,0))
				from dwh2.[finAnalytics].[rep840]
				where [REPMONTH] = @monthTo
				and punkt in ('2.1','2.11')
				union all
				select
				[SumBU] = sum(isnull(value,0))*-1
				from dwh2.[finAnalytics].[rep840_2_5]
				where [REPMONTH] = @monthTo
				and punkt in ('2.35')
				) l1
)

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 1
,[Показатель] = 'Сумма задолженности по ОД'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = (
				select
				[SumBU] = sum(isnull(restOD3,0))
				from #reestr
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 1
,[Показатель] = 'Сумма задолженности по ОД'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=3
				and [Показатель] = 'Сумма задолженности по ОД'
)


--p2d1
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 2
,[Показатель] = 'Объем выдач'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = case when datepart(month,@monthFrom)=1 
						then (
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @monthFrom and punkt in ('2.6','2.16')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @monthFrom and punkt in ('2.34')
						) l1
						)
					when datepart(month,@monthFrom)>1 
					then(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @monthFrom and punkt in ('2.6','2.16')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @monthFrom and punkt in ('2.34')
						) l1
						)
						-
						(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = dateadd(month,-1,@monthFrom) and punkt in ('2.6','2.16')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = dateadd(month,-1,@monthFrom) and punkt in ('2.34')
						) l1
						)
						end

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 2
,[Показатель] = 'Объем выдач'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = (
				select
				[SumBU] = sum(isnull(dogSum,0))
				from #reestr
				where dogSale between @monthFrom and EOMONTH(@monthFrom)
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 2
,[Показатель] = 'Объем выдач'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=1
				and [Показатель] = 'Объем выдач'
)

--p2d2
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 2
,[Показатель] = 'Объем выдач'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = case when datepart(month,@month2)=1 
						then (
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @month2 and punkt in ('2.6','2.16')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @month2 and punkt in ('2.34')
						) l1
						)
					when datepart(month,@month2)>1 
					then(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @month2 and punkt in ('2.6','2.16')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @month2 and punkt in ('2.34')
						) l1
						)
						-
						(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = dateadd(month,-1,@month2) and punkt in ('2.6','2.16')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = dateadd(month,-1,@month2) and punkt in ('2.34')
						) l1
						)
						end

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 2
,[Показатель] = 'Объем выдач'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = (
				select
				[SumBU] = sum(isnull(dogSum,0))
				from #reestr
				where dogSale between @month2 and EOMONTH(@month2)
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 2
,[Показатель] = 'Объем выдач'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=2
				and [Показатель] = 'Объем выдач'
)

--p2d3
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 2
,[Показатель] = 'Объем выдач'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = case when datepart(month,@monthTo)=1 
						then (
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @monthTo and punkt in ('2.6','2.16')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @monthTo and punkt in ('2.34')
						) l1
						)
					when datepart(month,@monthTo)>1 
					then(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @monthTo and punkt in ('2.6','2.16')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @monthTo and punkt in ('2.34')
						) l1
						)
						-
						(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = dateadd(month,-1,@monthTo) and punkt in ('2.6','2.16')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = dateadd(month,-1,@monthTo) and punkt in ('2.34')
						) l1
						)
						end

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 2
,[Показатель] = 'Объем выдач'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = (
				select
				[SumBU] = sum(isnull(dogSum,0))
				from #reestr
				where dogSale between @monthTo and EOMONTH(@monthTo)
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 2
,[Показатель] = 'Объем выдач'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=3
				and [Показатель] = 'Объем выдач'
)



--p3d1
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 3
,[Показатель] = 'Объем погашений по ОД'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = case when datepart(month,@monthFrom)=1 
						then (
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @monthFrom and punkt in ('2.7','2.17')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @monthFrom and punkt in ('2.38.2')
						) l1
						)
					when datepart(month,@monthFrom)>1 
					then(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @monthFrom and punkt in ('2.7','2.17')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @monthFrom and punkt in ('2.38.2')
						) l1
						)
						-
						(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = dateadd(month,-1,@monthFrom) and punkt in ('2.7','2.17')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = dateadd(month,-1,@monthFrom) and punkt in ('2.38.2')
						) l1
						)
						end

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 3
,[Показатель] = 'Объем погашений по ОД'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = (
				select
				[SumBU] = sum(isnull(credPayOD1,0))
				from #reestr
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 3
,[Показатель] = 'Объем погашений по ОД'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=1
				and [Показатель] = 'Объем погашений по ОД'
)

--p3d2
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 3
,[Показатель] = 'Объем погашений по ОД'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = case when datepart(month,@month2)=1 
						then (
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @month2 and punkt in ('2.7','2.17')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @month2 and punkt in ('2.38.2')
						) l1
						)
					when datepart(month,@month2)>1 
					then(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @month2 and punkt in ('2.7','2.17')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @month2 and punkt in ('2.38.2')
						) l1
						)
						-
						(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = dateadd(month,-1,@month2) and punkt in ('2.7','2.17')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = dateadd(month,-1,@month2) and punkt in ('2.38.2')
						) l1
						)
						end

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 3
,[Показатель] = 'Объем погашений по ОД'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = (
				select
				[SumBU] = sum(isnull(credPayOD2,0))
				from #reestr
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 3
,[Показатель] = 'Объем погашений по ОД'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=2
				and [Показатель] = 'Объем погашений по ОД'
)

--p3d3
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 3
,[Показатель] = 'Объем погашений по ОД'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = case when datepart(month,@monthTo)=1 
						then (
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @monthTo and punkt in ('2.7','2.17')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @monthTo and punkt in ('2.38.2')
						) l1
						)
					when datepart(month,@monthTo)>1 
					then(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @monthTo and punkt in ('2.7','2.17')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @monthTo and punkt in ('2.38.2')
						) l1
						)
						-
						(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = dateadd(month,-1,@monthTo) and punkt in ('2.7','2.17')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = dateadd(month,-1,@monthTo) and punkt in ('2.38.2')
						) l1
						)
						end

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 3
,[Показатель] = 'Объем погашений по ОД'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = (
				select
				[SumBU] = sum(isnull(credPayOD3,0))
				from #reestr
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 3
,[Показатель] = 'Объем погашений по ОД'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=3
				and [Показатель] = 'Объем погашений по ОД'
)


--p4d1
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 4
,[Показатель] = 'Объем погашений по %'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = /*case when datepart(month,@monthFrom)=1 
						then (
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @monthFrom and punkt in ('2.8','2.18','2.9','2.19')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @monthFrom and punkt in ('2.38.3')
						) l1
						)
					when datepart(month,@monthFrom)>1 
					then(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @monthFrom and punkt in ('2.8','2.18','2.9','2.19')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @monthFrom and punkt in ('2.38.3')
						) l1
						)
						-
						(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = dateadd(month,-1,@monthFrom) and punkt in ('2.8','2.18','2.9','2.19')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = dateadd(month,-1,@monthFrom) and punkt in ('2.38.3')
						) l1
						)
						end*/
						(
						select
[Сумма БУ] = sum([Сумма БУ])
from(
--2.8 + 2.18
select
[Пункт] = '2.8+2.18'
,[Номер договора КТ]
,[Сумма БУ] = sum([Сумма БУ])
from(
select
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = case when Kt.Код = '61215' and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) then a.Сумма*-1 else  a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,@monthFrom) and dateadd(year,2000,EOMONTH(@monthFrom))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
--and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','61215','49409')) --v1
and (
    (Kt.Код in ('48802','48702','49402') and Dt.Код in ('48809','49409','48709'))
    or
    (Kt.Код in ('48802','48702','49402') and substring(Dt.Код,1,3) = '612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
								,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
                                )
    )
	or
	
    (Dt.Код in ('48802','48702','49402') and Kt.Код = '61215'
    and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) --Полное списание
	and sposobKT.Имя in ('Посреднический','Прямой')
    )
    )
) l1

group by [Номер договора КТ] 

union all

--2.9+2.19
select
'2.9+2.19'
,[Номер договора КТ]
,sum([Сумма БУ])
from(

SELECT 
[Номер договора КТ] = isnull(isnull(crkt.Номер,crdt.Номер),dog.Номер)
,[Сумма БУ] = case when Dt.Код = '60323' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 then a.Сумма * -1 else a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKTp on a.СубконтоCt2_Ссылка=spKTp.ДоговорКонтрагента and spktp.ДополнительноеСоглашение=0x00
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKTp on spKTp.СпособПодачиЗаявления=sposobKTp.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces2 on a.СубконтоCt3_Ссылка=ces2.Ссылка
left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов dog on a.СубконтоCt2_Ссылка=dog.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.Субконтоdt2_Ссылка=crdt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT2 on spKT.СпособПодачиЗаявления=sposobKT2.Ссылка
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,@monthFrom) and dateadd(year,2000,EOMONTH(@monthFrom))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
/*
and (
    (Kt.Код in ('60323') and (Dt.Код ='47422' or substring(Dt.Код,1,3)='612') and a.СубконтоCt3_Ссылка=0x00000000000000000000000000000000)
    or
    (Dt.Код in ('60323') and substring(kt.Код,1,3)='612')
    )
*/ --v1
and (
    (Kt.Код in ('60323') and Dt.Код ='47422' and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
    or
    (Kt.Код in ('60323') and substring(Dt.Код,1,3) ='612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
								,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
                                )
	and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
	or
	(Dt.Код = '60323' and Kt.Код = '47422' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 --Пени)
	) --v3
    )
) l1

group by [Номер договора КТ]

union all

--2.38.3
select
'2.38.3'
,[Номер договора КТ]
,sum([Сумма БУ])
from(
select
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = a.Сумма
,[Способ выдачи займа КТ] = 
    case when sposobKT.Имя = 'Дистанционный' then 'Онлайн'
         when sposobKT.Имя = 'Посреднический' then 'Дистанционный'
         when sposobKT.Имя = 'Прямой' then 'Дистанционный'
         end

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,@monthFrom) and dateadd(year,2000,EOMONTH(@monthFrom))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
--and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','61215','49409')) --v1
and Kt.Код in ('48502') and Dt.Код in ('48509')
	--[СчетДтКод] in ('48509') and [СчетКтКод] in ('48502')
    
	
) l1
group by [Номер договора КТ]
) l2
						)

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 4
,[Показатель] = 'Объем погашений по %'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = (
				select
				[SumBU] = sum(isnull(credPayPRC1,0))
				from #reestr
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 4
,[Показатель] = 'Объем погашений по %'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=1
				and [Показатель] = 'Объем погашений по %'
)

--p4d2
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 4
,[Показатель] = 'Объем погашений по %'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = /*case when datepart(month,@month2)=1 
						then (
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @month2 and punkt in ('2.8','2.18','2.9','2.19')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @month2 and punkt in ('2.38.3')
						) l1
						)
					when datepart(month,@month2)>1 
					then(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @month2 and punkt in ('2.8','2.18','2.9','2.19')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @month2 and punkt in ('2.38.3')
						) l1
						)
						-
						(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = dateadd(month,-1,@month2) and punkt in ('2.8','2.18','2.9','2.19')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = dateadd(month,-1,@month2) and punkt in ('2.38.3')
						) l1
						)
						end*/
						(
						select
[Сумма БУ] = sum([Сумма БУ])
from(
--2.8 + 2.18
select
[Пункт] = '2.8+2.18'
,[Номер договора КТ]
,[Сумма БУ] = sum([Сумма БУ])
from(
select
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = case when Kt.Код = '61215' and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) then a.Сумма*-1 else  a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,@month2) and dateadd(year,2000,EOMONTH(@month2))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
--and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','61215','49409')) --v1
and (
    (Kt.Код in ('48802','48702','49402') and Dt.Код in ('48809','49409','48709'))
    or
    (Kt.Код in ('48802','48702','49402') and substring(Dt.Код,1,3) = '612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
								,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
                                )
    )
	or
	
    (Dt.Код in ('48802','48702','49402') and Kt.Код = '61215'
    and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) --Полное списание
	and sposobKT.Имя in ('Посреднический','Прямой')
    )
    )
) l1

group by [Номер договора КТ] 

union all

--2.9+2.19
select
'2.9+2.19'
,[Номер договора КТ]
,sum([Сумма БУ])
from(

SELECT 
[Номер договора КТ] = isnull(isnull(crkt.Номер,crdt.Номер),dog.Номер)
,[Сумма БУ] = case when Dt.Код = '60323' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 then a.Сумма * -1 else a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKTp on a.СубконтоCt2_Ссылка=spKTp.ДоговорКонтрагента and spktp.ДополнительноеСоглашение=0x00
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKTp on spKTp.СпособПодачиЗаявления=sposobKTp.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces2 on a.СубконтоCt3_Ссылка=ces2.Ссылка
left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов dog on a.СубконтоCt2_Ссылка=dog.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.Субконтоdt2_Ссылка=crdt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT2 on spKT.СпособПодачиЗаявления=sposobKT2.Ссылка
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,@month2) and dateadd(year,2000,EOMONTH(@month2))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
/*
and (
    (Kt.Код in ('60323') and (Dt.Код ='47422' or substring(Dt.Код,1,3)='612') and a.СубконтоCt3_Ссылка=0x00000000000000000000000000000000)
    or
    (Dt.Код in ('60323') and substring(kt.Код,1,3)='612')
    )
*/ --v1
and (
    (Kt.Код in ('60323') and Dt.Код ='47422' and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
    or
    (Kt.Код in ('60323') and substring(Dt.Код,1,3) ='612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
								,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
                                )
	and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
	or
	(Dt.Код = '60323' and Kt.Код = '47422' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 --Пени)
	) --v3
    )
) l1

group by [Номер договора КТ]

union all

--2.38.3
select
'2.38.3'
,[Номер договора КТ]
,sum([Сумма БУ])
from(
select
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = a.Сумма
,[Способ выдачи займа КТ] = 
    case when sposobKT.Имя = 'Дистанционный' then 'Онлайн'
         when sposobKT.Имя = 'Посреднический' then 'Дистанционный'
         when sposobKT.Имя = 'Прямой' then 'Дистанционный'
         end

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,@month2) and dateadd(year,2000,EOMONTH(@month2))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
--and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','61215','49409')) --v1
and Kt.Код in ('48502') and Dt.Код in ('48509')
	--[СчетДтКод] in ('48509') and [СчетКтКод] in ('48502')
    
	
) l1
group by [Номер договора КТ]
) l2
						)

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 4
,[Показатель] = 'Объем погашений по %'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = (
				select
				[SumBU] = sum(isnull(credPayPRC2,0))
				from #reestr
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 4
,[Показатель] = 'Объем погашений по %'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=2
				and [Показатель] = 'Объем погашений по %'
)

--p4d3
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 4
,[Показатель] = 'Объем погашений по %'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = /*case when datepart(month,@monthTo)=1 
						then (
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @monthTo and punkt in ('2.8','2.18','2.9','2.19')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @monthTo and punkt in ('2.38.3')
						) l1
						)
					when datepart(month,@monthTo)>1 
					then(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = @monthTo and punkt in ('2.8','2.18','2.9','2.19')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = @monthTo and punkt in ('2.38.3')
						) l1
						)
						-
						(
						select [SumBU] = sum([SumBU])
						from(
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840]
						where [REPMONTH] = dateadd(month,-1,@monthTo) and punkt in ('2.8','2.18','2.9','2.19')
						union all
						select [SumBU] = sum(isnull(value,0)) from dwh2.[finAnalytics].[rep840_2_5]
						where [REPMONTH] = dateadd(month,-1,@monthTo) and punkt in ('2.38.3')
						) l1
						)
						end*/
						(
						select
[Сумма БУ] = sum([Сумма БУ])
from(
--2.8 + 2.18
select
[Пункт] = '2.8+2.18'
,[Номер договора КТ]
,[Сумма БУ] = sum([Сумма БУ])
from(
select
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = case when Kt.Код = '61215' and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) then a.Сумма*-1 else  a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,@monthTo) and dateadd(year,2000,EOMONTH(@monthTo))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
--and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','61215','49409')) --v1
and (
    (Kt.Код in ('48802','48702','49402') and Dt.Код in ('48809','49409','48709'))
    or
    (Kt.Код in ('48802','48702','49402') and substring(Dt.Код,1,3) = '612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
								,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
                                )
    )
	or
	
    (Dt.Код in ('48802','48702','49402') and Kt.Код = '61215'
    and a.СубконтоCt3_Ссылка in (0xB2877DD787D69AF1431AA1944A24E2D9) --Полное списание
	and sposobKT.Имя in ('Посреднический','Прямой')
    )
    )
) l1

group by [Номер договора КТ] 

union all

--2.9+2.19
select
'2.9+2.19'
,[Номер договора КТ]
,sum([Сумма БУ])
from(

SELECT 
[Номер договора КТ] = isnull(isnull(crkt.Номер,crdt.Номер),dog.Номер)
,[Сумма БУ] = case when Dt.Код = '60323' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 then a.Сумма * -1 else a.Сумма end --v3

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKTp on a.СубконтоCt2_Ссылка=spKTp.ДоговорКонтрагента and spktp.ДополнительноеСоглашение=0x00
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKTp on spKTp.СпособПодачиЗаявления=sposobKTp.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces2 on a.СубконтоCt3_Ссылка=ces2.Ссылка
left join stg._1cUMFO.Справочник_ДоговорыКонтрагентов dog on a.СубконтоCt2_Ссылка=dog.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.Субконтоdt2_Ссылка=crdt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT2 on spKT.СпособПодачиЗаявления=sposobKT2.Ссылка
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,@monthTo) and dateadd(year,2000,EOMONTH(@monthTo))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
/*
and (
    (Kt.Код in ('60323') and (Dt.Код ='47422' or substring(Dt.Код,1,3)='612') and a.СубконтоCt3_Ссылка=0x00000000000000000000000000000000)
    or
    (Dt.Код in ('60323') and substring(kt.Код,1,3)='612')
    )
*/ --v1
and (
    (Kt.Код in ('60323') and Dt.Код ='47422' and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
    or
    (Kt.Код in ('60323') and substring(Dt.Код,1,3) ='612'
    and a.СубконтоDt3_Ссылка in (
                                0x882A18899049E7E8475798BFB0F8DDC7 --ПолноеДосрочноеПогашение
                                ,0x820EEA6915217FEC421CB51FA9C9B936 --ЧастичноеСписание
								,0xB2877DD787D69AF1431AA1944A24E2D9 --Полное списание
                                )
	and a.СубконтоCt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336) --Пени)
	or
	(Dt.Код = '60323' and Kt.Код = '47422' and a.Субконтоdt3_Ссылка = 0xA2EB0050568397CF11EDB7B497B65336 --Пени)
	) --v3
    )
) l1

group by [Номер договора КТ]

union all

--2.38.3
select
'2.38.3'
,[Номер договора КТ]
,sum([Сумма БУ])
from(
select
[Номер договора КТ] = crkt.Номер
,[Сумма БУ] = a.Сумма
,[Способ выдачи займа КТ] = 
    case when sposobKT.Имя = 'Дистанционный' then 'Онлайн'
         when sposobKT.Имя = 'Посреднический' then 'Дистанционный'
         when sposobKT.Имя = 'Прямой' then 'Дистанционный'
         end

from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка
left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка
left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crkt on a.СубконтоCt2_Ссылка=crkt.Ссылка
left join stg._1cUMFO.Документ_АЭ_ЗаймПредоставленный spKT on crkt.АЭ_ДокументОснование_Ссылка=spKT.Ссылка
left join stg._1cUMFO.Перечисление_АЭ_СпособыПодачиЗаявления sposobKT on spKT.СпособПодачиЗаявления=sposobKT.Ссылка
--left join stg._1cUMFO.Перечисление_АЭ_ВидыВыбытияЗаймов ces on a.СубконтоDt3_Ссылка=ces.Ссылка --v1
--where cast(dateadd(year,-2000,a.Период) as date) between DATEFROMPARTS(year(@repmonth),1,1) and EOMONTH(@REPMONTH)
where cast(a.Период as date) between dateadd(year,2000,@monthTo) and dateadd(year,2000,EOMONTH(@monthTo))
and a.Активность=01
and (dt.ПометкаУдаления=0 or kt.ПометкаУдаления=0)
and crkt.ПометкаУдаления=0
--and (Kt.Код in ('48802','49402') and Dt.Код in ('48809','61215','49409')) --v1
and Kt.Код in ('48502') and Dt.Код in ('48509')
	--[СчетДтКод] in ('48509') and [СчетКтКод] in ('48502')
    
	
) l1
group by [Номер договора КТ]
) l2
						)

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 4
,[Показатель] = 'Объем погашений по %'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = (
				select
				[SumBU] = sum(isnull(credPayPRC3,0))
				from #reestr
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 4
,[Показатель] = 'Объем погашений по %'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=3
				and [Показатель] = 'Объем погашений по %'
)


--p5d1
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 5
,[Показатель] = 'Задолженность PDL по ОД'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = (select
				[SumBU] = sum(isnull(value,0))
				from dwh2.[finAnalytics].[rep840]
				where [REPMONTH] = @monthFrom
				and punkt in ('2.1.3.2','2.11.3.2')
				)

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 5
,[Показатель] = 'Задолженность PDL по ОД'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = (
				select
				[SumBU] = sum(isnull(restOD1,0))
				from #reestr
				where upper(clientType) = upper('ФЛ')
				and dogSum <= 30000
				and dogDays <= 30
				)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 5
,[Показатель] = 'Задолженность PDL по ОД'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=1
				and [Показатель] = 'Задолженность PDL по ОД'
)

--p5d2
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 5
,[Показатель] = 'Задолженность PDL по ОД'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = (select
				[SumBU] = sum(isnull(value,0))
				from dwh2.[finAnalytics].[rep840]
				where [REPMONTH] = @month2
				and punkt in ('2.1.3.2','2.11.3.2')
				)

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 5
,[Показатель] = 'Задолженность PDL по ОД'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = (
				select
				[SumBU] = sum(isnull(restOD2,0))
				from #reestr
				where upper(clientType) = upper('ФЛ')
				and dogSum <= 30000
				and dogDays <= 30
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 5
,[Показатель] = 'Задолженность PDL по ОД'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=2
				and [Показатель] = 'Задолженность PDL по ОД'
)

--p5d3
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 5
,[Показатель] = 'Задолженность PDL по ОД'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] =( select
				[SumBU] = sum(isnull(value,0))
				from dwh2.[finAnalytics].[rep840]
				where [REPMONTH] = @monthTo
				and punkt in ('2.1.3.2','2.11.3.2')
			)

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 5
,[Показатель] = 'Задолженность PDL по ОД'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = (
				select
				[SumBU] = sum(isnull(restOD3,0))
				from #reestr
				where upper(clientType) = upper('ФЛ')
				and dogSum <= 30000
				and dogDays <= 30
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 5
,[Показатель] = 'Задолженность PDL по ОД'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=3
				and [Показатель] = 'Задолженность PDL по ОД'
)


--p6d1
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 6
,[Показатель] = 'Задолженность по оффлайн микрозаймам по ОД'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = (select
				[SumBU] = sum(isnull(value,0))
				from dwh2.[finAnalytics].[rep840]
				where [REPMONTH] = @monthFrom
				and punkt in ('2.1')
				)

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 6
,[Показатель] = 'Задолженность по оффлайн микрозаймам по ОД'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = (
				select
				[SumBU] = sum(isnull(restOD1,0))
				from #reestr
				where upper(isOnline) = upper('Оффлайн')
				and upper(dogType) = upper('Договор микрозайма')
				)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 6
,[Показатель] = 'Задолженность по оффлайн микрозаймам по ОД'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 1 (последний день первого месяца отчетного квартала)'
,[Номер даты] = 1
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=1
				and [Показатель] = 'Задолженность по оффлайн микрозаймам по ОД'
)

--p6d2
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 6
,[Показатель] = 'Задолженность по оффлайн микрозаймам по ОД'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = (select
				[SumBU] = sum(isnull(value,0))
				from dwh2.[finAnalytics].[rep840]
				where [REPMONTH] = @month2
				and punkt in ('2.1')
				)

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 6
,[Показатель] = 'Задолженность по оффлайн микрозаймам по ОД'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = (
				select
				[SumBU] = sum(isnull(restOD2,0))
				from #reestr
				where upper(isOnline) = upper('Оффлайн')
				and upper(dogType) = upper('Договор микрозайма')
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 6
,[Показатель] = 'Задолженность по оффлайн микрозаймам по ОД'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 2 (последний день второго месяца отчетного квартала)'
,[Номер даты] = 2
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=2
				and [Показатель] = 'Задолженность по оффлайн микрозаймам по ОД'
)

--p6d3
insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 6
,[Показатель] = 'Задолженность по оффлайн микрозаймам по ОД'
,[Источник] = 'Отчет'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] =( select
				[SumBU] = sum(isnull(value,0))
				from dwh2.[finAnalytics].[rep840]
				where [REPMONTH] = @monthTo
				and punkt in ('2.1')
			)

insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 6
,[Показатель] = 'Задолженность по оффлайн микрозаймам по ОД'
,[Источник] = 'Реестр'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = (
				select
				[SumBU] = sum(isnull(restOD3,0))
				from #reestr
				where upper(isOnline) = upper('Оффлайн')
				and upper(dogType) = upper('Договор микрозайма')
)


insert into dwh2.[finAnalytics].[reest_CB_Q_check2]
([Месяц начала квартала], [Месяц конца квартала], [Номер показателя], [Показатель], 
[Источник], [Дата проверки], [Номер даты], [Значение])

select
[Месяц начала квартала] = @monthFrom
,[Месяц конца квартала] = @monthTo
,[Номер показателя] = 6
,[Показатель] = 'Задолженность по оффлайн микрозаймам по ОД'
,[Источник] = 'Сверка Отчет - Реестр'
,[Дата проверки] = 'дата 3 (последний день третьего месяца отчетного квартала)'
,[Номер даты] = 3
,[Значение] = (

				select
				[SumBU] = round(sum(case when Источник = 'Отчет' then isnull(Значение,0) * -1 else isnull(Значение,0) end ),0)
				from dwh2.[finAnalytics].[reest_CB_Q_check2]
				where [Месяц начала квартала] = @monthFrom and [Месяц конца квартала] = @monthTo
				and [Номер даты]=3
				and [Показатель] = 'Задолженность по оффлайн микрозаймам по ОД'
)

END

