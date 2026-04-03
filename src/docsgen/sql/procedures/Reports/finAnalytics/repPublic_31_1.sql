







CREATE PROCEDURE [finAnalytics].[repPublic_31_1]
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
 ,[Номер строки] = a.RowName
 ,[Наименование показателя] = a.Pokazatel
 ,[Остаток] = a.sumAmountItog / @aplicator

from dwh2.finAnalytics.repPublicPL_31_1 a
where (repmonth = @repmonth or repmonth = datefromparts(year(dateadd(year,-1,@repmonth)),month(@repmonth),1))
and a.RowName in ('1','2','3','4','5','6','7','8','9','10','11','12','13','14')

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
 ,[Symbol] = a.Symbol
 ,[Остаток] = a.sumAmountItog / @aplicator
 ,[Контроль1] = a.checkResult1

from dwh2.finAnalytics.repPublicPL_31_1 a
where (repmonth = @repmonth or repmonth = datefromparts(year(dateadd(year,-1,@repmonth)),month(@repmonth),1))

end

END
