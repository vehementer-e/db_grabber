




CREATE PROCEDURE [finAnalytics].[PBI_PBR_Sales]

	
AS
BEGIN


select
a.REPMONTH
,a.Client
,a.isZaemshik
,a.dogNum
,a.saleDate
,a.saleType
,a.dogPeriodMonth
,a.dogSum
,a.nomenkGroup
,prod = dwh2.finAnalytics.nomenk2prod(a.nomenkGroup)
,isnew = case when a.isnew is null then 'Нет маркировки' else a.isnew end
,finChannelGroup = case when a.finChannelGroup is null then 'Нет маркировки' else a.finChannelGroup end
,finChannel = case when a.finChannel is null then 'Нет маркировки' else a.finChannel end 	
,finBusinessLine = case when a.finBusinessLine is null then 'Нет маркировки' else a.finBusinessLine end 	 	
,prodFirst = case when a.prodFirst is null then 'Нет маркировки' else a.prodFirst end 	 	 	
,productType = case when a.productType is null then 'Нет маркировки' else a.productType end 	
,a.salesRegion
,a.stavaOnSaleDate
,[Stavka_DogSum] = case when 
						dwh2.finAnalytics.nomenk2prod(a.nomenkGroup) = 'PDL' 
						and b.isAciaResult = 'Сработала Акция' 
						then 0
						else a.dogSum * a.stavaOnSaleDate
						end
,[Группа RBP] = case when a.RBP_GROUP is null then 'Нет маркировки' else a.RBP_GROUP end 	
from dwh2.finAnalytics.PBR_MONTHLY a
left join [dwh2].[finAnalytics].[PBR_AKCIA0] b on a.dogNum=b.dogNum and a.REPMONTH=b.REPMONTH
where a.repmonth >= '2024-01-01'
--where a.repmonth = '2025-09-01'
and a.saleDate between a.repmonth and EOMONTH(a.repmonth)


END
