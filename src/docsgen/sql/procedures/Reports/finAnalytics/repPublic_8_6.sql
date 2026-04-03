




CREATE PROCEDURE [finAnalytics].[repPublic_8_6]
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
 ,[Диапазон процентных ставок] = concat(
										FORMAT(CAST([sumAmountCol3_1] AS DECIMAL(10,3)), '0.000')
										,' - '
										,FORMAT(CAST([sumAmountCol3_2] AS DECIMAL(10,3)), '0.000')
										)
 ,[Интервал сроков погашения ] = concat(
										FORMAT(CAST([sumAmountCol4_1] AS DECIMAL(10,0)), '0')
										,' - '
										,FORMAT(CAST([sumAmountCol4_2] AS DECIMAL(10,0)), '0')
										)
from dwh2.finAnalytics.repPublicPL_8_6 a
where (repmonth = @repmonth or repmonth = datefromparts(year(dateadd(year,-1,@repmonth)),12,1))
and a.RowName in ('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16')

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
 ,[Мин ставка] = cast(FORMAT(CAST([sumAmountCol3_1] AS DECIMAL(10,3)), '0.000') as varchar)
 ,[Макс ставка] = cast(FORMAT(CAST([sumAmountCol3_2] AS DECIMAL(10,3)), '0.000') as varchar)
 ,[Мин интервал] = a.[sumAmountCol4_1]
 ,[Макс интервал] = a.[sumAmountCol4_2]
 ,[Контроль] = a.checkResult

from dwh2.finAnalytics.repPublicPL_8_6 a
where (repmonth = @repmonth or repmonth = datefromparts(year(dateadd(year,-1,@repmonth)),12,1))

end

END
