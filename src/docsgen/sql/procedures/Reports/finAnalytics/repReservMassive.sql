



CREATE PROCEDURE [finAnalytics].[repReservMassive]
        @repmonth date
       
AS
BEGIN

select
    repmonth 
    , prosFrom
    , prosTo
    , bucketName
    , sprName
    , groupOrder
    , restOD
    , restODPred
    , restPrc
    , restPrcPred
    , restPenya
    , restPenyaPred
    , restGP
    , restGPPred
    , reserv_NU
    , reserv_NUPred
    , reserv_BU
    , reserv_BUPred
    , reservOD_NU
    , reservOD_NUPred
    , reservPRC_NU
    , reservPRC_NUPred
    , reservOD_BU
    , reservOD_BUPred
    , reservPRC_BU
    , reservPRC_BUPred
    , reservProch_NU
    , reservProch_NUPred
    , reservProch_BU
    , reservProch_BUPred
    , c16restODPRC
    , c17restChange
    , c18reservBUChange
    , c19reservNUChange
    , c20AVGStavkaBU
    , c21AVGStavkaBUChange
    , c22AVGStavkaNU
    , c23AVGStavkaNUChange
    , c24FA_BU_1
    , c25FA_BU_2
    , c26Check1
    , c27FA_NU_1
    , c28FA_NU_2
    , c29Check2
    , c30Check3
    , c30Check4
    , nomenkGroup
    , loadDate
    , repType = case when repmonth=@repmonth then 'Отчетный месяц' else 'Предыдущий месяц' end 
from dwh2.finanalytics.repReservMassive
where repMonth between dateadd(month,-1,@repmonth) and @repmonth

END
