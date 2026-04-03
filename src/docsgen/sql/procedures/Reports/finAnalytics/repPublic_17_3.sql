





CREATE PROCEDURE [finAnalytics].[repPublic_17_3]
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
 ,[Расчеты с саморегулируемой организацией] = a.[sumAmountCol3] / @aplicator
 ,[Расчеты с кредитными потребительскими кооперативами второго уровня] = a.[sumAmountCol4] / @aplicator
 ,[Расчеты с союзами, ассоциациями кредитных потребительских кооперативов] = a.[sumAmountCol5] / @aplicator
 ,[Расчеты с персоналом] = a.[sumAmountCol6] / @aplicator
 ,[Расчеты с поставщиками и подрядчиками] = a.[sumAmountCol7] / @aplicator
 ,[Запасы] = a.[sumAmountCol8] / @aplicator
 ,[Прочее] = a.[sumAmountCol9] / @aplicator
 ,[Итого] = a.sumAmountItog / @aplicator

from dwh2.finAnalytics.repPublicPL_17_3 a
where repmonth = @repmonth
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
 ,[Расчеты с саморегулируемой организацией] = a.[sumAmountCol3] / @aplicator
 ,[Расчеты с кредитными потребительскими кооперативами второго уровня] = a.[sumAmountCol4] / @aplicator
 ,[Расчеты с союзами, ассоциациями кредитных потребительских кооперативов] = a.[sumAmountCol5] / @aplicator
 ,[Расчеты с персоналом] = a.[sumAmountCol6] / @aplicator
 ,[Расчеты с поставщиками и подрядчиками] = a.[sumAmountCol7] / @aplicator
 ,[Запасы] = a.[sumAmountCol8] / @aplicator
 ,[Прочее] = a.[sumAmountCol9] / @aplicator
 ,[Итого] = a.sumAmountItog / @aplicator
 ,[Контроль1] = a.checkResult1
 ,[Контроль2] = a.checkResult2

from dwh2.finAnalytics.repPublicPL_17_3 a
where repmonth = @repmonth

end

END
