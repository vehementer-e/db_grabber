





CREATE PROCEDURE [finAnalytics].[reportDAPPmassiv]

AS
BEGIN
	

select 
		[VIN]=vin
		,[машина]=nameAuto
		,[Клиент]=client
		,[Регион выдачи]=region
		,[Кол-во договоров займа] =countDog
		,[Номер договора]=numdog
		
		,[Сумма займов по всем договорам] =summAll
		,[задолженность на дату погашения залогом (Всего)]=dolgAllPoga
		,[задолженность на дату погашения залогом (ОД)]=dolgODPoga
		,[задолженность на дату погашения залогом (%)]=dolgPRCPoga
		,[задолженность на дату погашения залогом (прочее)]=dolgPeniPoga
		
		,[Состояние договора]=statusDog
		-- 
		,[задолженность на отчетную дату (Всего)]=dolgAllRepdate
		,[задолженность на отчетную дату (ОД)]=dolgODRepdate
		,[задолженность на отчетную дату (%)]=dolgPRCRepdate
		,[задолженность на отчетную дату (прочее)]=dolgPeniRepdate
		---
		,[наличие банкротства на отчетную дату]=isBankrot
		,[дата учета банкротства]=isBankrotDate
		---
		,[дата выхода в дефолт (90+)]=isDefoltDate
		-- 
	
		,[дата погашения залогом]=datePogaZalog
		----Землякова
		,[кол-во дней просрочки]=dpd
		--datediff(day,datePogaZalog,eomonth(datePogaZalog))
		---
		,[сумма ОД погашенная залогом]=summODPogaZalog
		,[сумма % погашенная залогом]=summPRCPogaZalog
		,[сумма пени и госпошлины погашенная залогом]=summPeniPogaZalog
		,[сумма списания на расходы]=summSpisRashod
		,[списание задолженности (ОД и %) на авто]=summSpisZadolODPRC
		,[сумма перечисление средств  ФССП]=summFSSP
		,[сумма перечисление в конкурсную массу 60323]=summAK
		,[сумма перечисление в конкурсную массу 60312]=summBK
		,[сумма возмещение понесенных расходов]=summVozmRashod
		,[возврат клиенту на переплату (47422) остатка стоимости а/м при внесудебной реализации]=ostPriceItogAfterZadol
		--
		,[Дата принятия на баланс]=dateBalance
		,[Цена принятия на баланс]=priceBalance

		--
		,[дата переоценки плюс]=datePriceChangePlus
		,[переоценка плюс]=changePricePlus
		,[дата переоценки минус]=datePriceChangeMinus
		,[переоценка минус-]=changePriceMinus
		
		--
		,[статус авто]=statusAuto
		,[дата продажи]=dateSale
		,[балансовая стоимость с учетом переценки]=priceItog
		,[цена продажи (расчеты с покупателем)]=priceSale
		,[НДС]=NDS
		,[Взнос в ФНС]=FNS
		--
		,[дата формирования ФР минус]=dateFRMinus
		,[ФР минус]=frMinus
		,[дата формирования ФР плюс]=dateFRPlus
		,[ФР плюс]=frPlus
		--
		,[ИТОГО ФР]=itogFR
		,[срок реализации]=periodSale

		,[ставка НДС]=ndsPRC

		,[деньги НДС расходы на управляющего]=moneyNDSManager
		,[минус % погашенные залогом]=minusPRCZalog
		,[минус ОД погашенная залогом]=minusODZalog
		,[срок между выходом в дефолт и погашения ОД залогом]=periodDefoltZalog
		,[срок между выходом в дефолт и реализацией залога]=periodDefoltSale

		,[соотношение цены реализации без НДС к цене принятия на баланс]=ratioPriceSalePriceBalanceIn

		,[соотношение цены реализации без НДС к балансовой стоимости на момент реализации]=ratioPriceSalePriceBalanceOut
		,[Проверка цены принятия на баланс]=checkPriceBalance
	from dwh2.finAnalytics.DAPP
	order by dateBalance
END
