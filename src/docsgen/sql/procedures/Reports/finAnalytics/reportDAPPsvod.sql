






CREATE PROCEDURE [finAnalytics].[reportDAPPsvod]

AS
BEGIN
	

select 
		[Отчетный период]=format(repmonth,'MMMM yyyy','Ru-ru')
		,[Сумма погашения за счет залога]=summSpisZalog_datePogaZalog
		,[Сумма авто принятых на баланс]=summPriceBalance_dateBalance
		,[Балансовая цена реализованных авто]=summPriceBalance_dateSale
		,[Сумма оплаты]=summPriceSale_dateSale
		,[НДС]=summNDS_dateSale
		,[Переоценка плюс]=summChangePricePlus_dateChangePricePlus
		,[Переоценка минус]=summChangePriceMinus_dateChangePriceMinus
		,[ФР минус]=summFRMinus_dateFRMinus
		,[ФР плюс]=summFRPlus_dateFRPlus
		,[ФР продажи]=summFR
		,[ИТОГО]=summFR_summChgMinus_summChgPlus
		,[Количество поступивших машин]=countAutoIn_dateBalance
		,[Количество реализованных машин]=countSaleAuto_dateSale
		,[Количество на балансе]=countBalance_dateBalanceSale
		,[Средний срок реализации]=avgPeriodSale_dateSale
		,[Стоимость на балансе на конец месяца]=summStoiBalance_dateBalanceSale
		,[Сумма перечислений ФССП и ФУ]=summFSSP_dateSale
		,[%, пени и госпошлины]=summPogaZalogPRCPeni_dateSale
		,[ОД]=summODPogaZalog_dateSale
		,[Количество банкротов]=countIsBankrot_datePogaZalog
		,[Количество "дефолт" (проверка)]=countIsDefoltDate_datePogaZalog
		,[Средний срок между выходом в дефолт и погашения ОД залогом]=avgPeriodDefoltZalog_datePogaZalog
		,[Средний срок между выходом в дефолт и реализацией залога по реализованным авто]=avgPeriodDefoltSale_dateSale
		,[Соотношение цены реализации без НДС к цене принятия на баланс]=ratioPricSaleNDS_PriceBalance
		,[Соотношение цены реализации без НДС к балансовой стоимости на момент реализации]=ratioPricSaleNDS_StoiBalance
		,[Балансовая стоимость реализованных авто на момент реализации (с учетом переценки)]=summPriceItog_dateSale
		,[V Сумма погашения за счет залога]=v_summSpisZalog_datePogaZalog
		,[V Сумма авто принятых на баланс]=v_summPriceBalance_dateBalance
		,[V балансовая стоимость реализованных авто]=v_summPriceBalanceStatus_dateBalance
		,[V Сумма оплаты]=v_summPriceSaleStatus_dateBalance
		,[V НДС]=v_summNDSSale_dateBalance
		,[V Переоценка плюс]=v_summChangePricePlus_dateBalance
		,[V Переоценка минус]=v_summChangePriceMinus_dateBalance
		,[V ФР минус]=v_summFRMinus_dateBalance
		,[V ФР плюс]=v_summFRPlus_dateBalance
		,[V ФР продажи]=v_summFR
		,[V ИТОГО]=v_summFR_summChgMinus_summChgPlus
		,[V Количество поступивших машин]=v_countAutoIn_dateBalance
		,[V Количество реализованных машин]=v_countSaleAutoStatus_dateSale
		,[V Количество на балансе]=v_countBalanceStatus_dateBalanceSale
		,[V Средний срок реализации]=v_avgPeriodSale_dateBalance
		,[V Стоимость на балансе на конец месяца]=v_summStoiBalanceStatus_dateBalance
		,[V Балансовая стоимость реализованных авто на момент реализации (с учетом переценки)]=v_summPriceItogStatus_dateBalance
		,[V Сумма перечислений ФССП и ФУ]=v_summFSSP_datePogaZalog
		,[V %, пени и госпошлины]=v_summPogaZalogPRCPeni_datePogaZalog
		,[V ОД]=v_summODPogaZalog_datePogaZalog
		,[V Количество банкротов]=v_countIsBankrot_datePogaZalog
		,[V Количество "дефолт" (проверка)]=v_countIsDefoltDate_datePogaZalog
		,[V Средний срок между выходом в дефолт и погашения ОД залогом]=v_avgPeriodDefoltZalog_datePogaZalog
		,[V Средний срок между выходом в дефолт и реализацией залога по реализованным авто]=v_avgPeriodDefoltSale_dateSale
		,[V Соотношение цены реализации без НДС к цене принятия на баланс]=v_ratioPricSaleNDS_PriceBalance
		,[V Соотношение цены реализации без НДС к балансовой стоимости на момент реализации]=v_ratioPricSaleNDS_PriceItogStatus
		,[V Доля реализованных авто от принятых на баланс, % (по цене принятия на баланс)]=v_partPriceBalanceStatus_PriceBalance
		,[Остатки по УМФО 71701 7102]=osv71
		,[Остатки по УМФО 62001]=osv62
		,[Результа проверки 1]=check1
		,[Результа проверки 2]=check71
		,[Результа проверки 3]=check62
	from dwh2.finAnalytics.DAPP_svod
	order by repmonth
END
