







CREATE PROCEDURE [finAnalytics].[reportDAPPregion]

AS
BEGIN
	

select 
		[Регион]=region
		,[Отчетный год]=format(repyear,'yyyy','RU-ru')
		,[Сумма погашения за счет залога]=summSpisZalog_datePogaZalog
		,[Сумма авто принятых на баланс]=summPriceBalance_dateBalance
		,[Балансовая цена реализованных авто]=summPriceBalance_dateSale
		,[Сумма оплаты]=summPriceSale_dateSale
		,[НДС]=summNDS_dateSale
		,[Количество поступивших машин]=countAutoIn_dateBalance
		,[Количество реализованных машин]=countSaleAuto_dateSale
	from dwh2.finAnalytics.DAPP_region


END
