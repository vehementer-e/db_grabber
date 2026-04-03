

CREATE PROCEDURE [finAnalytics].[repPDN_PBR_check]
    @REP_MONTH date
  
AS
BEGIN

select
Repmonth, 
calcDate, 
blockName, 
checkMethod,
repValue, 
UMFOValue, 
diff

from dwh2.finAnalytics.repPDNcheck
where Repmonth=@REP_MONTH


END
