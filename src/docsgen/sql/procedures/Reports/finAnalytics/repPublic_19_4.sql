






CREATE PROCEDURE [finAnalytics].[repPublic_19_4]
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
 ,[На Предыдущий] = a.[sumAmountCol3] / @aplicator
 ,[Изменения, обусловленные денежными потоками] = a.[sumAmountCol4] / @aplicator
 ,[Приобретение активов] = a.[sumAmountCol5] / @aplicator
 ,[Курсовая разница] = a.[sumAmountCol6] / @aplicator
 ,[Изменение амортизированной стоимости] = a.[sumAmountCol7] / @aplicator
 ,[Прочее] = a.[sumAmountCol8] / @aplicator
 ,[Итого] = a.[sumAmountCol9] / @aplicator
 ,[На Текущий] = a.[sumAmountCol10] / @aplicator

from dwh2.finAnalytics.repPublicPL_19_4 a
where repmonth = @repmonth
and a.RowName in ('1','2','3','4','5','6','7','8','9')

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
 ,[На Предыдущий] = a.[sumAmountCol3] / @aplicator
 ,[Изменения, обусловленные денежными потоками] = a.[sumAmountCol4] / @aplicator
 ,[Приобретение активов] = a.[sumAmountCol5] / @aplicator
 ,[Курсовая разница] = a.[sumAmountCol6] / @aplicator
 ,[Изменение амортизированной стоимости] = a.[sumAmountCol7] / @aplicator
 ,[Прочее] = a.[sumAmountCol8] / @aplicator
 ,[Итого] = a.[sumAmountCol9] / @aplicator
 ,[На Текущий] = a.[sumAmountCol10] / @aplicator
 ,[Контроль1] = a.checkResult1
 ,[Контроль2] = a.checkResult2
 
from dwh2.finAnalytics.repPublicPL_19_4 a
where repmonth = @repmonth

end

END
