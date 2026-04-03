






CREATE PROCEDURE [finAnalytics].[repPublic_40_2]
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
 ,[group] = a.[group]
 ,[RowNum] = a.RowNum	
 ,[Номер строки] = a.Razdel
 ,[Наименование показателя] = a.Pokazatel
 ,[До 3 месяцев] = a.[sumAmountCol3] / @aplicator
 ,[От 3 месяцев до 1 года] = a.[sumAmountCol4] / @aplicator
 ,[Свыше 1 года] = a.[sumAmountCol5] / @aplicator
 ,[Итого] = a.[sumAmountCol6] / @aplicator

from dwh2.finAnalytics.repPublicPL_40_2 a
where repmonth = @repmonth
and a.RowName in ('1','2','3','4','5','7','8','9','10','11','12','13','14','15')

end

if @repselector = 2
begin

select
 [repmonth] = eomonth(a.repmonth)
 ,[group] = a.[group]
 ,[RowNum] = a.RowNum
 ,[isBold] = a.isBold
 ,[Номер строки] = a.RowName
 ,[Наименование показателя] = a.Pokazatel
 ,[ОСВ остаток БС] = a.Acc2
 ,[До 3 месяцев] = a.[sumAmountCol3] / @aplicator
 ,[От 3 месяцев до 1 года] = a.[sumAmountCol4] / @aplicator
 ,[Свыше 1 года] = a.[sumAmountCol5] / @aplicator
 ,[Итого] = a.[sumAmountCol6] / @aplicator
 ,[Контроль1] = a.checkResult1

from dwh2.finAnalytics.repPublicPL_40_2 a
where repmonth = @repmonth

end

END
