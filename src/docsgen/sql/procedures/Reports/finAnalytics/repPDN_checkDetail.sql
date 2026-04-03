
CREATE PROCEDURE [finAnalytics].[repPDN_checkDetail]
    @REP_MONTH date
  
AS
BEGIN

select
Repmonth
, calcDate
, repType
, dogNum
, pbr_restOD
, umfo_restOD
, diff_restOD
, pbr_restPRC
, umfo_restPRC
, diff_restPRC
, pbr_reservOD_NU
, umfo_reservOD_NU
, diff_reservOD_NU
, pbr_reservPRC_NU
, umfo_reservPRC_NU
, diff_reservPRC_NU
, pbr_reservOD_BU
, umfo_reservOD_BU
, diff_reservOD_BU
, pbr_reservPrc_BU
, umfo_reservPrc_BU
, diff_reservPrc_BU

from dwh2.finAnalytics.repPDNcheckDetail
where Repmonth=@REP_MONTH
and calcDate = (select max(calcDate) from dwh2.finAnalytics.repPDNcheckDetail where Repmonth=@REP_MONTH)


END