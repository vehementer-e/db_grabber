




CREATE PROCEDURE [finAnalytics].[repReservBuckets]
        @repmonthFrom date,
        @repmonthTo date
       
AS
BEGIN

select
bucketName
, sprName
, groupOrder
, loadDate
, repmonth
, pokazatel
, rest = case 
            when sprName ='для_факт' and pokazatel='Резервы по займам + %' then rest*-1 
            when sprName ='для_trans' and upper(pokazatel) like 'Резервы%'  then rest*-1 
            
            else rest end
, pokazatelOrder
, nomenkGroup
, overGroupName
, overGroupOrder
, nomenkGroupOrder = case
						when nomenkGroup = 'ПТС' then 1
						when nomenkGroup = 'Автокредит' then 2
						when nomenkGroup = 'PDL' then 3
						when nomenkGroup = 'Installment' then 4
						when nomenkGroup = 'Бизнес-займы' then 5
						else 6 end
from dwh2.finAnalytics.repReservBuckets
where repMonth between @repmonthFrom and @repmonthTo

END
