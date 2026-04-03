


CREATE PROCEDURE [finAnalytics].[repPublic_8_1]
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
 ,[Полная балансовая стоимость] = a.sumAmountCol1 / @aplicator
 ,[Оценочный резерв под убытки] = a.sumAmountCol2 / @aplicator
 ,[Балансовая стоимость] = a.sumAmountItog / @aplicator

from dwh2.finAnalytics.repPublicPL_8_1 a
where (repmonth = @repmonth or repmonth = datefromparts(year(dateadd(year,-1,@repmonth)),12,1))
and a.RowName in ('1','2','3','4','5')

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
 ,[Полная балансовая стоимость] = a.sumAmountCol1 / @aplicator
 ,[Оценочный резерв под убытки] = a.sumAmountCol2 / @aplicator
 ,[Балансовая стоимость] = a.sumAmountItog / @aplicator
 ,[Контроль] = a.checkResult

from dwh2.finAnalytics.repPublicPL_8_1 a
where (repmonth = @repmonth or repmonth = datefromparts(year(dateadd(year,-1,@repmonth)),12,1))

end

END
