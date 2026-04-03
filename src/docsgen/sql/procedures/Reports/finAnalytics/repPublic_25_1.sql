





CREATE PROCEDURE [finAnalytics].[repPublic_25_1]
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

from dwh2.finAnalytics.repPublicPL_25_1 a
where (repmonth = @repmonth or repmonth = datefromparts(year(dateadd(year,-1,@repmonth)),month(@repmonth),1))
and a.RowName in ('1','2','3','4','5','5 (1)','6','7','8','9','10','10 (1)','11','12'
				  ,'13','14','15','15 (1)','16','17','18','19','20','21','22','23')

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

from dwh2.finAnalytics.repPublicPL_25_1 a
where (repmonth = @repmonth or repmonth = datefromparts(year(dateadd(year,-1,@repmonth)),month(@repmonth),1))

end

END
