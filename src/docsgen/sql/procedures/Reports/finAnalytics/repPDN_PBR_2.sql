
CREATE PROCEDURE [finAnalytics].[repPDN_PBR_2]
    @REP_MONTH date
  
AS
BEGIN

select
Repmonth, 
Repdate, 
tabName,
blockName, 
groupName, 
amount, 
groupSort,
blockSort

from dwh2.finAnalytics.repPDN
where Repmonth=@REP_MONTH
and calcDate = (select max(calcDate) from dwh2.finAnalytics.repPDN where Repmonth=@REP_MONTH)


END