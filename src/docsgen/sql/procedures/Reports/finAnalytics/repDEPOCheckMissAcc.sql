




CREATE PROCEDURE [finAnalytics].[repDEPOCheckMissAcc]
        @repmonth date
with recompile
AS
BEGIN

declare @daysInMonth int = day(eomonth(@repmonth))

drop table if exists #accMiss
select
*
into #accMiss

from (
Select
accNum
,accName
,restOUT_NU = sum(restOUT_NU)

from dwh2.finAnalytics.OSV_MONTHLY a

where a.repmonth = @repmonth
and a.acc2order in ('42316','43708','43108','43808'/*,'52008'*/)
group by 
accNum
,accName
) l1

left join (
select distinct
accOD
from dwh2.finAnalytics.DEPO_MONTHLY a
where a.repMonth = @repmonth
) l2 on l1.accNum = l2.accOD

where l2.accOD is null

select
*
from (
select
[Номер счета] = c.accNum
,[Наименование счета] = c.accName

,[Среднемесячный остаток] = sum(a.СуммаНачальныйОстатокКт) / @daysInMonth

from stg._1cUMFO.РегистрСведений_СЗД_ДанныеПоСчетамДляDWH a
left join stg._1cUMFO.Справочник_БНФОСчетаАналитическогоУчета k on a.СчетАналитическогоУчета=k.Ссылка
inner join #accMiss c on k.Код = c.accNum

where cast(dateadd(year,-2000,a.Период) as date) between @repmonth and EOMONTH(@repmonth)

group by 
c.accNum
,c.accName
) l1

where l1.[Среднемесячный остаток] !=0


END
