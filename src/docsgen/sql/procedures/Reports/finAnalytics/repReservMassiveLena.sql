




CREATE PROCEDURE [finAnalytics].[repReservMassiveLena]
        @repmonth date
       
AS
BEGIN

select
    [repmonth]
	, [prosFrom]
	, [prosTo]
	, [bucketName]
	, [sprName]
	, [groupOrder]
	, [restODPrc]
	, [restODPrcPred]
	, [reserv_NU]
	, [reserv_NUPred]
	, [reserv_BU]
	, [reserv_BUPred]
	, [AVGStavkaNU]
	, [AVGStavkaNUPred]
	, [AVGStavkaBU]
	, [AVGStavkaBUPred]
	, [nomenkGroup]
	, [loadDate]
    , repType = case when repmonth=@repmonth then 'Отчетный месяц' else 'Предыдущий месяц' end 
from dwh2.finanalytics.repReservMassiveLena
where repMonth between dateadd(month,-1,@repmonth) and @repmonth

END
