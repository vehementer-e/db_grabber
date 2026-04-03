

CREATE PROCEDURE [finAnalytics].[calcRep840_5]
	@repmonth date

AS
BEGIN

declare @repYear int = year(@repmonth)

drop table if exists #rep
CREATE TABLE #rep(
	[repYear] int NOT NULL,
	[REPMONTH] [date] NOT NULL,
	[rownum] [int] NOT NULL,
	[repCode] [nvarchar](300) NOT NULL,
	[sumODSales] [money] NULL,
	[sumProsSales] [money] NULL,
	[countDog] [int] NULL,
	[sumSales] [money] NULL
)

Insert into #rep
select
repYear = @repYear
,repmonth = @repmonth
,rowNum = ROW_NUMBER() over (order by repCode)
,repCode	

,sumODSales = sum(zadolgOD)
,sumProsSales = sum(case when prosDaysTotal > 90 then zadolgOD else 0 end)
,countDog = sum(dogCount)
,sumSales = sum(dogSum)
from(
select
orderNum = s.[orderNum]
,repCode = concat(
				s.[regNum]
				,' - '
				,[repName]
				)
,l1.*

from(
select
a.client
,a.dogNum
,a.isZaemshik
,a.addresFact	
,a.addressReg
,b.regionReg
,b.regionFact
,a.saleType
,a.saleDate
,a.salesRegion
--,salesRegForRep = case
--					when upper(a.saleType) = upper('Дистанционный') then isnull(a.salesRegion,regionFact)
--					when upper(a.saleType) = upper('Онлайн') then
--						case 
--							when upper(a.isZaemshik) = 'ФЛ' then isnull(isnull(b.regionReg,b.regionFact),a.salesRegion)
--							when upper(a.isZaemshik) = 'ЮЛ' then a.addressReg
--						else '-'
--						end
--					else '-'
--					end
,salesRegForRep = isnull(a.salesRegion,b.regionFact)
,a.zadolgOD
,a.prosDaysTotal
,dogCount = case when year(a.saleDate) = year(@repmonth) then 1 else 0 end
,dogSum = case when year(a.saleDate) = year(@repmonth) then a.dogSum else 0 end
from dwh2.finAnalytics.PBR_MONTHLY a
left join dwh2.finAnalytics.credClients b on a.dogNum = b.dogNum

where a.repmonth = @repmonth
and SUBSTRING(a.AccODNum,1,5) in ('48801','48701','49401')
and (
		year(a.saleDate) = year(@repmonth)
		or
		year(a.CloseDate) = year(@repmonth)
		or
		a.CloseDate is null
	)
) l1

left join dwh2.[finAnalytics].[spr_OKATO_region] s on upper(l1.salesRegForRep) = upper(s.[UMFOName])
--where l1.salesRegion is null
) l2

--where (l2.dogCount >0 or l2.dogSum > 0 )

group by
repCode	

delete from dwh2.[finAnalytics].rep840_5 where repYear = @repYear

insert into dwh2.[finAnalytics].rep840_5
select
*
from #rep --where ([countDog]	 > 0 or [sumSales]  >0)

END
