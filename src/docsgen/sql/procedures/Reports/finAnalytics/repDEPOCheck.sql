



CREATE PROCEDURE [finAnalytics].[repDEPOCheck]
        @repmonth date
with recompile
AS
BEGIN


declare @dateFrom datetime = dateadd(year,2000,@repmonth)
declare @dateToTmp datetime = dateadd(day,1,dateadd(year,2000,eomonth(@repmonth)))
declare @dateTo datetime = dateadd(second,-1,@dateToTmp)
declare @daysInMonth int = day(eomonth(@repmonth))

declare @acc2 table (
	[acc2] nvarchar(5) not null,
	[repmonthFrom] date not null,
	[repmonthTo] date not null
)

/*Таблица периодов действия счетов для сверки*/
insert into @acc2 values ('42316','1900-01-01','2300-01-01')
insert into @acc2 values ('43708','1900-01-01','2025-12-01')
insert into @acc2 values ('43108','2025-12-01','2300-01-01')
insert into @acc2 values ('43808','1900-01-01','2300-01-01')
insert into @acc2 values ('52008','2100-01-01','2300-01-01')


select
[repmonth] = r1.[repmonth]
,[avgRestODRep] = r1.[avgRestOD]
,[avgRestODDWH] = r2.[avgRestOD]
,[avgRestODCheck] = case when abs(r1.[avgRestOD] - r2.[avgRestOD]) > 100 then 'Ошибка' else 'ОК' end
from(
select
[repmonth] = [repmonth]
,[avgRestOD] = sum([avgRestOD])
from dwh2.[finAnalytics].[DEPO_MONTHLY]
where [repmonth] = @repmonth
group by [repmonth]
) r1

left join (
select
[repmonth] = l1.[repmonth]
,[AVGRestOD] = round(sum(l1.[restOD]) / @daysInMonth, 2)

from(
 select
 [repmonth] = @repmonth
 ,[СчетУчета] = b.Код
 ,[Аналитический счет] = k.Код
 ,[restOD] = a.СуммаНачальныйОстатокКт	
 
 from  Stg._1cUMFO.РегистрСведений_СЗД_ДанныеПоСчетамДляDWH a
    left join stg._1cUMFO.ПланСчетов_БНФОБанковский b on a.СчетУчета=b.Ссылка
    left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета k on a.СчетАналитическогоУчета=k.Ссылка
	inner join @acc2 acc on b.Код = acc.acc2 and @repmonth between acc.repmonthFrom and acc.repmonthTo
    where a.период between @dateFrom and @dateTo
	--and b.Код in ('42316'/*, '43708'*/, '43808', '43108'/*, '52008'*/)
) l1
group by 
l1.[repmonth]
) r2 on 1=1



END
