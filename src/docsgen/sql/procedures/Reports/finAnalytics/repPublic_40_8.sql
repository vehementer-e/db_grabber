







CREATE PROCEDURE [finAnalytics].[repPublic_40_8]
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
 ,[До востребования, в пределах месяца] = a.[sumAmountCol3] / @aplicator
 ,[От 1 до 3 месяцев] = a.[sumAmountCol4] / @aplicator
 ,[От 3 до 12 месяцев] = a.[sumAmountCol5] / @aplicator
 ,[От 1 года до 5 лет] = a.[sumAmountCol6] / @aplicator
 ,[Более 5 лет] = a.[sumAmountCol7] / @aplicator
 ,[Просроченные] = a.[sumAmountCol8] / @aplicator
 ,[Итого] = a.[sumAmountCol9] / @aplicator

from dwh2.finAnalytics.repPublicPL_40_8 a
where repmonth = @repmonth
and a.RowName in ('1','2','3','4','5','7','8','9','10','11','12','13','14','15','16','17')

end

if @repselector = 2
begin

select
 [repmonth] = eomonth(a.repmonth)
 ,[RowNum] = a.RowNum
 ,[isBold] = a.isBold
 ,[Номер строки] = a.RowName
 ,[Наименование показателя] = a.Pokazatel
 ,[ОСВ остаток БС] = a.[Acc2]
 ,[До востребования, в пределах месяца] = a.[sumAmountCol3] / @aplicator
 ,[От 1 до 3 месяцев] = a.[sumAmountCol4] / @aplicator
 ,[От 3 до 12 месяцев] = a.[sumAmountCol5] / @aplicator
 ,[От 1 года до 5 лет] = a.[sumAmountCol6] / @aplicator
 ,[Более 5 лет] = a.[sumAmountCol7] / @aplicator
 ,[Просроченные] = a.[sumAmountCol8] / @aplicator
 ,[Итого] = a.[sumAmountCol9] / @aplicator
 ,[Контроль1] = a.checkResult1

from dwh2.finAnalytics.repPublicPL_40_8 a
where repmonth = @repmonth

end

END
