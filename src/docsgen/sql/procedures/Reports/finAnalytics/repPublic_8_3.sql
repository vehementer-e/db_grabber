




CREATE PROCEDURE [finAnalytics].[repPublic_8_3]
	@repmonth date,
	@repselector int,
	@aplicator int
with recompile
AS
BEGIN
--declare @repselector int

--set @repselector =2

if @repselector = 1
begin

select
 [repmonth] = eomonth(a.repmonth)
 ,[RowNum] = a.RowNum	
 ,[Номер строки] = a.Razdel
 ,[Наименование показателя] = a.Pokazatel
 ,[Остаток основного долга] = a.sumAmountCol3 / @aplicator
 ,[Остаток задолженности по процентным доходам] = a.sumAmountCol4 / @aplicator
 ,[Остаток на счетах по учету прочих доходов и расходов] = a.sumAmountCol5 / @aplicator
 ,[Cумма корректировок, увеличивающих (уменьшающих) балансовую стоимость] = a.sumAmountCol6 / @aplicator
 ,[Оценочный резерв под убытки] = a.sumAmountCol7 / @aplicator
 ,[Балансовая стоимость] = a.sumAmountItog / @aplicator

from dwh2.finAnalytics.repPublicPL_8_3 a
where (repmonth = @repmonth or repmonth = datefromparts(year(dateadd(year,-1,@repmonth)),12,1))
and a.RowName in ('1','2','3','4','5','6','7','8','9','10','11','12','13')

end

if @repselector = 2
begin

select
 [repmonth] = eomonth(a.repmonth)
 ,[RowNum] = a.RowNum
 ,[isBold] = a.isBold
 ,[Номер строки] = a.RowName
 ,[Наименование показателя] = a.Pokazatel
 ,[ОСВ остаток БС] = a.Acc2
 ,[Остаток основного долга] = a.sumAmountCol3 / @aplicator
 ,[Остаток задолженности по процентным доходам] = a.sumAmountCol4 / @aplicator
 ,[Остаток на счетах по учету прочих доходов и расходов] = a.sumAmountCol5 / @aplicator
 ,[Cумма корректировок, увеличивающих (уменьшающих) балансовую стоимость] = a.sumAmountCol6 / @aplicator
 ,[Оценочный резерв под убытки] = a.sumAmountCol7 / @aplicator
 ,[Балансовая стоимость] = a.sumAmountItog / @aplicator
 ,[Контроль1] = a.checkResult1
 ,[Контроль2] = a.checkResult2
 ,[Контроль3] = a.checkResult3

from dwh2.finAnalytics.repPublicPL_8_3 a
where (repmonth = @repmonth or repmonth = datefromparts(year(dateadd(year,-1,@repmonth)),12,1))

end

END
