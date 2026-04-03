








CREATE PROCEDURE [finAnalytics].[reportDAPPYear]

AS
BEGIN
		
		drop table if exists #repmonthDAPP

		select 
			distinct
			startDate=datefromparts(year(dateBalance),month(dateBalance),1)
			,endDate=eomonth(dateBalance)
			,gYear=year(eomonth(dateBalance))
	
		into #repmonthDAPP
		from
			dwh2.finAnalytics.DAPP
		where dateBalance is not null
		-----
		--and  year(dateBalance)!=2026
		
		declare @currentDateReport date = (select max(startDate) from #repmonthDAPP)
		

		drop table if exists #repmonthDAPP_Year
		create table #repmonthDAPP_Year (nameYear varchar(10),startDate date,endDate date)
		insert into #repmonthDAPP_Year (nameYear,startDate,endDate)
		select 
			convert(varchar(10),l1.gYear)
			,startDate=datefromparts(l1.gYear,1,1)
			,endDate=datefromparts(l1.gYear,12,31)
		
		from (
			select 
				*
				,countMonth=count(endDate)over(partition by gYear)
			from #repmonthDAPP
			--where gYear!=year(@currentDateReport)
			) l1
		group by l1.gYear
		union all
		--select 
		--	gMonthYear=convert(varchar(10),format(eomonth(l1.endDate),'MMM yyyy','Ru-ru'))
		--	,startDate=datefromparts(year(l1.endDate),month(l1.endDate),1)
		--	,endDate=l1.endDate
		--from (
		--	select 
		--		*
		--		,countMonth=count(endDate)over(partition by gYear)
		--	from #repmonthDAPP) l1
		--where countMonth<12
		--union all
		--текущий год по месячно
		select 
			gMonthYear=convert(varchar(10),format(eomonth(endDate),'MMM yyyy','Ru-ru'))
			,startDate
			,endDate
		from #repmonthDAPP
		where year(startDate)=year(@currentDateReport)
	
--select * from #repmonthDAPP
--select * from #repmonthDAPP_Year
	select 
		distinct
		l1.*
		
			
	from (
		select
			[Отчетный период]=nameYear
			,[Сумма погашения за счет залога]=sum(summSpisZalog_datePogaZalog)over(partition by nameYear)
			,[Сумма перечислений ФУ, ФССП]=sum(summFSSP_dateSale)over(partition by nameYear)
			,[Балансовая стоимость авто, принятых на баланc]=sum(summPriceBalance_dateBalance)over(partition by nameYear)
			,[Балансовая стоимость реализованных авто на момент реализации (с учетом переценки)]=sum(summPriceItog_dateSale)over(partition by nameYear)
			,[Количество принятых автомобилей]=sum(countAutoIn_dateBalance)over(partition by nameYear)
			,[Количество реализованных автомобилей]=sum(countSaleAuto_dateSale)over(partition by nameYear)
			,[Количество клиентов-банкротов]=sum(countIsBankrot_datePogaZalog)over(partition by nameYear)
			,[Количество клиентов, вышедших в дефолт]=sum(countIsDefoltDate_datePogaZalog)over(partition by nameYear)
			,[Средний срок реализации автомобиля]=avg(avgPeriodSale_dateSale)over(partition by nameYear)
			,[Средний срок с даты дефолта до даты погашения залогом (по винтажам)]=avg(v_avgPeriodDefoltZalog_datePogaZalog)over(partition by nameYear)
			,[Средний срок с даты дефолта до даты реализации залога (по винтажам)]=avg(v_avgPeriodDefoltSale_dateSale)over(partition by nameYear)

			--
			,[Сумма денежных средств от реализации автомобилей]=sum(summPriceSale_dateSale)over(partition by nameYear)
			,[НДС]=sum(summNDS_dateSale)over(partition by nameYear)
			,[Сумма %, пеней и госпошлин, погашенная за счет залога]=sum(summPogaZalogPRCPeni_dateSale)over(partition by nameYear)
			,[Сумма ОД, погашенная за счет залога]=sum(summODPogaZalog_dateSale)over(partition by nameYear)
			,[Дельта между поступлением денежных средств и НДС+перечисления ФУ]=sum(summPriceSale_dateSale)over(partition by nameYear)
					-sum(summNDS_dateSale)over(partition by nameYear)-sum(summFSSP_dateSale)over(partition by nameYear)
			,[Минус %, пени и госпошлины]=sum(summPriceSale_dateSale)over(partition by nameYear)
					-sum(summNDS_dateSale)over(partition by nameYear)-sum(summFSSP_dateSale)over(partition by nameYear)
					-sum(summPogaZalogPRCPeni_dateSale)over(partition by nameYear)
			,[Минус сумма ОД]=sum(summPriceSale_dateSale)over(partition by nameYear)
					-sum(summNDS_dateSale)over(partition by nameYear)-sum(summFSSP_dateSale)over(partition by nameYear)
					-sum(summPogaZalogPRCPeni_dateSale)over(partition by nameYear)
					-sum(summODPogaZalog_dateSale)over(partition by nameYear)
			,[Доходы / расходы по операциям с залогами]=sum(summFR_summChgMinus_summChgPlus)over(partition by nameYear)
			,[Соотношение цены реализации без НДС к цене принятия на баланс (по винтажам)]=
				(sum(v_summPriceSaleStatus_dateBalance)over(partition by nameYear)-sum(v_summNDSSale_dateBalance)over(partition by nameYear))
					/nullif(sum(v_summPriceBalanceStatus_dateBalance)over(partition by nameYear),0)

			,startDate


		from #repmonthDAPP_Year a
		left join dwh2.finAnalytics.DAPP_svod b on b.repmonth between a.startDate and a.endDate) l1
	order by l1.startDate asc
	


END
