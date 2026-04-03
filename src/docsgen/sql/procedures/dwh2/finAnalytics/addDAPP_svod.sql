




/*

*/
CREATE PROCEDURE [finAnalytics].[addDAPP_svod] 
    
AS
BEGIN
	declare @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

	declare @subjectHeader  nvarchar(250) ='ДАПП Свод', @subject nvarchar(250)
	declare @msgHeader nvarchar(max)=concat('Обновление данных в ДАПП Свод: ',FORMAT(getdate(), 'MMMM yyyy', 'ru-RU' ),char(10))
	declare @msgFloor nvarchar(max) =concat(char(10),'Отработала процедура: ',@sp_name)
	declare @message nvarchar(max)=''
	

 begin try	
  begin tran 
	truncate table dwh2.finAnalytics.DAPP_svod
	drop table if exists #repmonthDAPP
	
	select 
		distinct
		startDate=datefromparts(year(dateBalance),month(dateBalance),1)
		,endDate=eomonth(dateBalance)
	into #repmonthDAPP
	from
		dwh2.finAnalytics.DAPP
	where dateBalance is not null
	
	--select * from #repmonthDAPP order by startDate
	
	insert into dwh2.finAnalytics.DAPP_svod
	select
		repmonth=l2.endDate
		,summSpisZalog_datePogaZalog=l2.a1 --[Сумма погашения за счет залога]
		,summPriceBalance_dateBalance=l2.a2 --[Сумма авто принятых на баланс]
		,summPriceBalance_dateSale=l2.a3 --[Балансовая цена реализованных авто]
		,summPriceSale_dateSale=l2.a4 --[сумма оплаты]
		,summNDS_dateSale=l2.a5 --[НДС]
		,summChangePricePlus_dateChangePricePlus=l2.a6 --[переоценка +]
		,summChangePriceMinus_dateChangePriceMinus=l2.a7 --[переоценка -]
		,summFRMinus_dateFRMinus=l2.a8 --[ФР-]
		,summFRPlus_dateFRPlus=l2.a9 --[ФР+]
		,summFR=l2.a10 --[ФР продажи]
		,summFR_summChgMinus_summChgPlus=l2.a11 --[ИТОГО]
		,countAutoIn_dateBalance=l2.a12 --[количество поступивших машин]
		,countSaleAuto_dateSale=l2.a13 --[количество реализованных машин]
		,countBalance_dateBalanceSale=l2.a14 --[количество на балансе]
		,avgPeriodSale_dateSale=l2.a15 --[средний срок реализации]
		,summStoiBalance_dateBalanceSale=l2.a16 --[стоимость на балансе на конец месяца]
		,summFSSP_dateSale=l2.a17 --[сумма перечислений ФССП и ФУ]
		,summPogaZalogPRCPeni_dateSale=l2.a18 --[%, пени и госпошлины]
		,summODPogaZalog_dateSale=l2.a19 --[ОД]
		,countIsBankrot_datePogaZalog=l2.a20 --[Количество банкротов]
		,countIsDefoltDate_datePogaZalog=l2.a21 --[Количество "дефолт" (проверка)]
		,avgPeriodDefoltZalog_datePogaZalog=l2.a22 --[Средний срок между выходом в дефолт и погашения ОД залогом]
		,avgPeriodDefoltSale_dateSale=l2.a23 --[Средний срок между выходом в дефолт и реализацией залога по реализованным авто]
		,ratioPricSaleNDS_PriceBalance=l2.a24 --[Соотношение цены реализации без НДС к цене принятия на баланс]
		,ratioPricSaleNDS_StoiBalance=l2.a25 --[Соотношение цены реализации без НДС к балансовой стоимости на момент реализации]
		,summPriceItog_dateSale=l2.a26 --[Балансовая стоимость реализованных авто на момент реализации (с учетом переценки)]
	
		,v_summSpisZalog_datePogaZalog=l2.b1 --[сумма погашения за счет залога V]
		,v_summPriceBalance_dateBalance=l2.b2 --[сумма авто принятых на баланс V]
		,v_summPriceBalanceStatus_dateBalance=l2.b3 --[балансовая стоимость реализованных авто V]
		,v_summPriceSaleStatus_dateBalance=l2.b4 --[сумма оплаты V]
		,v_summNDSSale_dateBalance=l2.b5 --[НДС V]
		,v_summChangePricePlus_dateBalance=l2.b6 --[переоценка + V]
		,v_summChangePriceMinus_dateBalance=l2.b7 --[переоценка - V]
		,v_summFRMinus_dateBalance=l2.b8 --[ФР- V]
		,v_summFRPlus_dateBalance=l2.b9 --[ФР+ V]
		,v_summFR=l2.b10 --[ФР продажи V]
		,v_summFR_summChgMinus_summChgPlus=l2.b11 --[ИТОГО V]
		,v_countAutoIn_dateBalance=l2.b12 --[количество поступивших машин V]
		,v_countSaleAutoStatus_dateSale=l2.b13 --[количество реализованных машин V]
		,v_countBalanceStatus_dateBalanceSale=l2.b14 --[количество на балансе V]
		,v_avgPeriodSale_dateBalance=l2.b15 --[средний срок реализации V]
		,v_summStoiBalanceStatus_dateBalance=l2.b16 --[стоимость на балансе на конец месяца V]
		,v_summPriceItogStatus_dateBalance=l2.b17 --[Балансовая стоимость реализованных авто на момент реализации (с учетом переценки) V]
		,v_summFSSP_datePogaZalog=l2.b18 --[сумма перечислений ФССП и ФУ V]
		,v_summPogaZalogPRCPeni_datePogaZalog=l2.b19 --[%, пени и госпошлины V]
		,v_summODPogaZalog_datePogaZalog=l2.b20 --[ОД V]
		,v_countIsBankrot_datePogaZalog=l2.b21 --[Количество банкротов V]
		,v_countIsDefoltDate_datePogaZalog=l2.b22 --[Количество "дефолт" (проверка) V]
		,v_avgPeriodDefoltZalog_datePogaZalog=l2.b23 --[Средний срок между выходом в дефолт и погашения ОД залогом V]
		,v_avgPeriodDefoltSale_dateSale=l2.b24 --[Средний срок между выходом в дефолт и реализацией залога по реализованным авто V]
		,v_ratioPricSaleNDS_PriceBalance=l2.b25 --[Соотношение цены реализации без НДС к цене принятия на баланс V]
		,v_ratioPricSaleNDS_PriceItogStatus=l2.b26 --[Соотношение цены реализации без НДС к балансовой стоимости на момент реализации V]
		,v_partPriceBalanceStatus_PriceBalance=l2.b27--[Доля реализованных авто от принятых на баланс, % (по цене принятия на баланс) V]
		,osv71=0.0
		,osv62=0.0
		,check1=0.0
		,check71=0.0
		,check62=0.0
	
	from(
		select
			l1.endDate
			,l1.a1,l1.a2,l1.a3,l1.a4,l1.a5,l1.a6,l1.a7,l1.a8,l1.a9
			,a10=l1.a8+l1.a9
			,a11=l1.a8+l1.a9+l1.a6+l1.a7
			,l1.a12,l1.a13,l1.a14
			,a15=isnull((select sum(isnull(PeriodSale,0)) from dwh2.finAnalytics.DAPP where dateSale between l1.startDate and l1.endDate)/nullif(l1.a13,0),0)
			,l1.a16
			,l1.a17,l1.a18,l1.a19,l1.a20,l1.a21
			,a22=isnull((select sum(isnull(periodDefoltZalog,0)) from dwh2.finAnalytics.DAPP where datePogaZalog between l1.startDate and l1.endDate)/nullif(l1.a21,0),0)
			,a23=isnull((select sum(isnull(periodDefoltSale,0)) from dwh2.finAnalytics.DAPP where dateSale between l1.startDate and l1.endDate)/nullif(l1.a13,0),0)
			,a24=isnull((l1.a4-l1.a5)/nullif(l1.a3,0),0)
			,a25=isnull((l1.a4-l1.a5)/nullif(l1.a16,0),0)
			,l1.a26
			---------------
			,b1=l1.a1
			,b2=l1.a2
			,l1.b3,l1.b4,l1.b5,l1.b6,l1.b7,l1.b8,l1.b9
			,b10=l1.b8+l1.b9
			,b11=l1.b8+l1.b9+l1.b6+l1.b7
			,b12=l1.a12
			,l1.b13,l1.b14
			,b15=isnull((select sum(isnull(PeriodSale,0)) from dwh2.finAnalytics.DAPP where dateBalance between l1.startDate and l1.endDate)/nullif(l1.b13,0),0)
			,l1.b16
			,b17=isnull((select sum(isnull(priceItog,0)) from dwh2.finAnalytics.DAPP where dateBalance between l1.startDate and l1.endDate and statusAuto='реализован'),0)
			,b18=l1.a17
			--isnull((select sum(isnull(summFSSP,0))+sum(isnull(summAK,0))+sum(isnull(summBK,0)) from dwh2.finAnalytics.DAPP where datePogaZalog between l1.startDate and l1.endDate)/nullif(l1.b13,0),0)
			,b19=l1.a18
			--isnull((select sum(isnull(summPRCPogaZalog,0))+sum(isnull(summPeniPogaZalog,0)) from dwh2.finAnalytics.DAPP where datePogaZalog between l1.startDate and l1.endDate)/nullif(l1.b13,0),0)
			,b20=l1.a19
			---isnull((select sum(isnull(summODPogaZalog,0)) from dwh2.finAnalytics.DAPP where datePogaZalog between l1.startDate and l1.endDate)/nullif(l1.b13,0),0) 
			,b21=l1.a20
			,b22=l1.a21
			,b23=isnull((select sum(isnull(periodDefoltZalog,0)) from dwh2.finAnalytics.DAPP where datePogaZalog between l1.startDate and l1.endDate)/nullif(l1.a21,0),0)
			,b24=isnull((select sum(isnull(periodDefoltSale,0)) from dwh2.finAnalytics.DAPP where datePogaZalog between l1.startDate and l1.endDate)/nullif(l1.b13,0),0)
			,b25=isnull((l1.b4-l1.b5)/nullif(l1.b3,0),0)
			,b26=isnull((l1.b4-l1.b5)/nullif((select sum(isnull(priceItog,0)) from dwh2.finAnalytics.DAPP where dateBalance between l1.startDate and l1.endDate and statusAuto='реализован'),0)
				,0)
			,b27=isnull(l1.b3/nullif(l1.a2,0),0)
		from(
			select 
				startDate
				,endDate
				--a1 /*[сумма погашения за счет залога]сумма по "списание задолженности (ОД и %) на авто", у которых "дата погашения залогом" больше или равна Дате1 и меньше или равна Дате2*/
				,a1=isnull((select sum(isnull(summSpisZadolODPRC,0)) from dwh2.finAnalytics.DAPP where datePogaZalog between startDate and endDate),0)
	
				--a2 /*[сумма авто принятых на баланс]сумма по "цене принятия на баланс", у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2*/
				,a2=isnull((select sum(isnull(priceBalance,0)) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate),0)

				--a3 /*[балансовая стоимость реализованных авто]сумма по "цене принятия на баланс", у которых "дата продажи" больше или равна Дате1 и меньше или равна Дате2*/
				,a3=isnull((select sum(isnull(priceBalance,0)) from dwh2.finAnalytics.DAPP where dateSale between startDate and endDate),0)
	
				--a4 /*[сумма оплаты] сумма по ""цена продажи(расчеты с покупателем)"", у которых ""дата продажи"" больше или равна Дате1 и меньше или равна Дате2"*/
				,a4=isnull((select sum(isnull(priceSale,0)) from dwh2.finAnalytics.DAPP where dateSale between startDate and endDate),0)
	
				--a5 /*[НДС]сумма по "НДС", у которых "дата продажи" больше или равна Дате1 и меньше или равна Дате2*/
				,a5=isnull((select sum(isnull(NDS,0)) from dwh2.finAnalytics.DAPP where dateSale between startDate and endDate)	,0)
	
				--a6 /*[переоценка +]сумма по "переоценка+", у которых "дата переоценки+" больше или равна Дате1 и меньше или равна Дате2*/
				,a6=isnull((select sum(isnull(summ,0)) from #changePriceAll where dateadd(year,-2000,dat) between startDate and endDate and st='plus'),0)
	
				--a7 /*[переоценка -]сумма по "переоценка-", у которых "дата переоценки-" больше или равна Дате1 и меньше или равна Дате2*/
				,a7=isnull((select sum(isnull(summ,0)) from #changePriceAll where dateadd(year,-2000,dat) between startDate and endDate and st='minus'),0)
	
				--a8 /*[ФР-]сумма по "ФР-", у которых "дата формирования ФР -" больше или равна Дате1 и меньше или равна Дате2*/
				--,a8=isnull((select sum(isnull(frMinus,0)) from dwh2.finAnalytics.DAPP where dateFRMinus between startDate and endDate),0)
				,a8=isnull((select sum(isnull(summ,0)) from #frAll where dateadd(year,-2000,dat) between startDate and endDate and st='minus'),0)
					--вслучаи присутвия мемориальных ордеров когда машина уже продана
					+isnull((select sum(isnull(sumOrderFrMinus,0)) from dwh2.finAnalytics.DAPP where dateOrderFRMinus between startDate and endDate ),0)
				
				--a9 /*[ФР+]сумма по "ФР+", у которых "дата формирования ФР +" больше или равна Дате1 и меньше или равна Дате2*/
				--,a9=isnull((select sum(isnull(frPlus,0)) from dwh2.finAnalytics.DAPP where dateFRPlus between startDate and endDate),0)
				,a9=isnull((select sum(isnull(summ,0)) from #frAll where dateadd(year,-2000,dat) between startDate and endDate and st='plus'),0)
				--a10 /*[ФР продажи]столбец 8 + столбец 9*/
				,a10=0
	
				--a11 /*[ИТОГО]столбец 10 + столбец 6 + столбец 7*/
				,a11=0

				--a12 /*[количество поступивших машин]количество записей, у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2*/
				,a12=isnull((select count(*) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate),0)
	
				--a13 /*[количество реализованных машин]количество записей, у которых "дата продажи" больше или равна Дате1 и меньше или равна Дате2*/
				,a13=isnull((select count(*) from dwh2.finAnalytics.DAPP where dateSale between startDate and endDate),0)
	
				--a14 /*[количество на балансе]количество записей, у которых "дата принятия на баланс" меньше Даты2 минус количество записей, у которых "дата продажи" меньше Даты 2*/
				,a14=isnull(((select count(*) from dwh2.finAnalytics.DAPP where dateBalance<=endDate)-(select count(*) from dwh2.finAnalytics.DAPP where dateSale<=endDate)),0)

				--a15 /*[средний срок реализации]сумма по "срок реализации", у которых "дата продажи" больше или равна Дате1 и меньше или равна Дате2 деленная на столбец 13*/
				,a15=0
    			--версия 1
				--a16 /*[стоимость на балансе на конец месяца]"равно сумма ""цена принятия на баланс"", у которых  ""дата принятия на баланс"" меньше Даты2,минус сумма ""цена принятия на баланс"", у которых ""дата продажи"" меньше Даты 2плюс ""переоценка"", у которых ""дата переоценки""  меньше Даты 2 и ""дата продажи"" больше или равна  Даты 2плюс ""переоценка"", у которых ""дата переоценки""  меньше Даты 2 и ""дата продажи"" равна "" """*/
			
				--,a16=isnull((select sum(isnull(priceBalance,0)) from dwh2.finAnalytics.DAPP where dateBalance <=endDate),0)
				--	-isnull((select sum(isnull(priceBalance,0)) from dwh2.finAnalytics.DAPP where dateSale <=endDate),0)	
				--	+isnull((select sum(isnull(changePricePlus,0)) from dwh2.finAnalytics.DAPP where datePriceChangePlus<=endDate and dateSale>endDate),0)
				--	+isnull((select sum(isnull(changePricePlus,0)) from dwh2.finAnalytics.DAPP where datePriceChangePlus<=endDate and 
				--			dateSale is null),0)
				--	+isnull((select sum(isnull(changePriceMinus,0)) from dwh2.finAnalytics.DAPP where datePriceChangeMinus<=endDate and dateSale>endDate),0)
				--	+isnull((select sum(isnull(changePriceMinus,0)) from dwh2.finAnalytics.DAPP where datePriceChangeMinus<=endDate and 
				--			dateSale is null),0)
				--версия 2
				,a16=(select
						summ=isnull((select sum(isnull(priceBalance,0)) from dwh2.finAnalytics.DAPP where dateBalance <=endDate),0)
										-isnull((select sum(isnull(priceBalance,0)) from dwh2.finAnalytics.DAPP where dateSale <=endDate),0)
										+sum(l1.summ)
					from (
						select
							dat=endDate
							,summ=sum(a.summ)
						from #changePriceAll a
						left join #balance b on a.nomlink=b.nomLink
						left join #statusAuto c on a.nomlink=c.nomlink
						where a.dat<=dateadd(year,2000,endDate) and (c.dat is null or c.dat>dateadd(year,2000,endDate))
						group by b.nameAuto
						union all
						select endDate,0 -- в случаи если нет переоценки
						)l1
					group by l1.dat)
				--a17 /*[сумма перечислений ФССП и ФУ]сумма по "перечисление ФССП и конкурсную массу", у которых "дата продажи" больше или равна Дате1 и меньше или равна Дате2 деленная на столбец 13*/
				,a17=isnull((select sum(isnull(summFSSP,0))+sum(isnull(summAK,0))+sum(isnull(summBK,0)) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate),0)

				--a18 /*[%, пени и госпошлины]сумма по "погашение залогом задолженности %","погашение залогом пени" и "погашение залогом госпошлины", у которых "дата продажи" больше или равна Дате1 и меньше или равна Дате2 деленная на столбец 13*/
				,a18=isnull((select sum(isnull(summPRCPogaZalog,0))+sum(isnull(summPeniPogaZalog,0)) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate),0)

				--a19 /*[ОД]сумма по "погашение залогом задолженности ОД", у которых "дата продажи" больше или равна Дате1 и меньше или равна Дате2 деленная на столбец 13*/
				,a19=isnull((select sum(isnull(summODPogaZalog,0)) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate),0)
	
				--a20 /*[Количество банкротов]количество записей, у которых "дата погашения залогом" больше или равна Дате1 и меньше или равна Дате2 и "наличие банкротства на отчетную дату (да/нет)" равно "Да"*/
				,a20=isnull((select count(*) from dwh2.finAnalytics.DAPP where datePogaZalog between startDate and endDate and isBankrot='банкрот'),0)
	
				--a21 /*[Количество "дефолт" (проверка)]количество записей, у которых "дата погашения залогом" больше или равна Дате1 и меньше или равна Дате2 и "дата выхода в дефолт (90+)" неравно "0"*/
				,a21=isnull((select count(*) from dwh2.finAnalytics.DAPP where datePogaZalog between startDate and endDate and isDefoltDate is not null),0)
	
				--a22 /*[Средний срок между выходом в дефолт и погашения ОД залогом]сумма по "срок между выходом в дефолт и погашения ОД залогом", у которых "дата погашения залогом" больше или равна Дате1 и меньше или равна Дате2, деленная на Столбец 21*/
				,a22=0
	
				--a23 /*[Средний срок между выходом в дефолт и реализацией залога по реализованным авто]сумма по "срок между выходом в дефолт и реализацией залога", у которых "дата продажи" больше или равна Дате1 и меньше или равна Дате2, деленная на Столбец 21*/
				,a23=0
	
				--a24 /*[Соотношение цены реализации без НДС к цене принятия на баланс]равно разности между Столбец 4 и Столбец 5, деленной на Столбец 3*/
				,a24=0
	
				--a25 /*[Соотношение цены реализации без НДС к балансовой стоимости на момент реализации](столбец 4 - столбец 5) / столбец 16*/
				,a25=0
				--a26 /*[Балансовая стоимость реализованных авто на момент реализации (с учетом переценки)]сумма по "балансовая стоимсть с учетом переценки", у которых "дата продажи" больше или равна Дате1 и меньше или равна Дате2*/
				,a26=isnull((select sum(isnull(priceItog,0)) from dwh2.finAnalytics.DAPP where dateSale between startDate and endDate),0)

				---------------------------
				--b1 /*[сумма погашения за счет залога]сумма по "списание задолженности (ОД и %) на авто", у которых "дата погашения залогом" больше или равна Дате1 и меньше или равна Дате2*/
				,b1=0
		
				--b2 /*[сумма авто принятых на баланс]сумма по "цене принятия на баланс", у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2*/
				,b2=0
		
				--b3 /*[балансовая стоимость реализованных авто]сумма по "цене принятия на баланс", у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2 и признак "Статус авто" равен либо "ОС", либо "реализован"*/
				,b3=isnull((select sum(isnull(priceBalance,0)) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate and statusAuto in('ОС','реализован')),0)
		
				--b4 /*[сумма оплаты]"сумма по ""цена продажи(расчеты с покупателем)"",  у которых ""дата принятия на баланс"" больше или равна Дате1 и меньше или равна Дате2 и признак ""Статус авто"" равен либо ""ОС"", либо ""реализован"""*/
				,b4=isnull((select sum(isnull(priceSale,0)) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate and statusAuto in('ОС','реализован')),0)

				--b5 /*[НДС]сумма по "НДС",  у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2 и признак "Статус авто" равен либо "ОС", либо "реализован"*/
				,b5=isnull((select sum(isnull(NDS,0)) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate and statusAuto in('ОС','реализован')),0)

				--b6 /*[переоценка +]сумма по "переоценка+", у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2*/
				,b6=isnull((select sum(isnull(changePricePlus,0)) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate),0)
		
				--b7 /*[переоценка -]сумма по "переоценка-", у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2*/
				,b7=isnull((select sum(isnull(changePriceMinus,0)) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate),0)
		
				--b8 /*[ФР-]сумма по "ФР-", у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2*/
				,b8=isnull((select sum(isnull(frMinus,0)) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate),0)
		
				--b9 /*[ФР+]сумма по "ФР+", у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2*/
				,b9=isnull((select sum(isnull(frPlus,0)) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate),0)
		
				--b10 /*[ФР продажи]столбец 8 + столбец 9*/
				,b10=0
		
				--b11 /*[ИТОГО]столбец 10 + столбец 6 + столбец 7*/
				,b11=0

				--b12 /*[количество поступивших машин]количество записей, у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2*/
				,b12=0
		
				--b13 /*[количество реализованных машин]количество записей, у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2 и признак "Статус авто" равен "реализован"*/
				,b13=isnull((select count(*) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate and statusAuto ='реализован'),0)
		
				--b14 /*[количество на балансе]количество записей, у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2 и признак "Статус авто" равен "нереализован"*/
				,b14=isnull((select count(*) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate and statusAuto ='нереализован'),0)
		
				--b15 /*[средний срок реализации] сумма по "срок реализации", у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2 деленная на столбец 13*/
				,b15=0
				--b16 /*[стоимость на балансе на конец месяца]"равно сумма ""цена принятия на баланс"", у которых  ""дата принятия на баланс""  больше или равна Дате1 и меньше Даты2 и ""статус  авто"" равен ""нереализован""
					/*	плюс ""переоценка"", у которых ""дата принятия на баланс""  больше или равна Дате1 и меньше Даты2 и ""статус  авто"" равен ""нереализован""*/
				,b16=isnull((select sum(isnull(priceBalance,0)) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate  and statusAuto ='нереализован'),0)
					+isnull((select sum(isnull(changePricePlus,0)) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate  and statusAuto ='нереализован'),0)
					+isnull((select sum(isnull(changePriceMinus,0)) from dwh2.finAnalytics.DAPP where dateBalance between startDate and endDate  and statusAuto ='нереализован'),0)

				--b17/*[балансовая стоимость на момент реализации]сумма по "балансовая стоимость с учетом переценки", у которых "дата принятия на баланс" больше или равна Дате1 и меньше или равна Дате2 деленная на столбец 13 и признак "Статус авто" равен "реализован"*/
				,b17=0
		
				--b18 /*[сумма перечислений ФССП и ФУ]сумма по "перечисление ФССП и конкурсную массу", у которых "дата погашения залогом" больше или равна Дате1 и меньше или равна Дате2 деленная на столбец 13*/
				,b18=0
		
				--b19 /*[%, пени и госпошлины]сумма по "погашение залогом задолженности %","погашение залогом пени" и "погашение залогом госпошлины", у которых "дата погашения залогом" больше или равна Дате1 и меньше или равна Дате2 деленная на столбец 13*/
				,b19=0
		
				--b20 /*[ОД]сумма по "погашение залогом задолженности ОД", у которых "дата погашения залогом" больше или равна Дате1 и меньше или равна Дате2 деленная на столбец 13*/
				,b20=0
		
				--b21 /*[Количество банкротов]количество записей, у которых "дата погашения залогом" больше или равна Дате1 и меньше или равна Дате2 и "наличие банкротства на отчетную дату (да/нет)" равно "Да"*/
				,b21=0
		
				--b22 /*[Количество "дефолт" (проверка)]количество записей, у которых "дата погашения залогом" больше или равна Дате1 и меньше или равна Дате2 и "дата выхода в дефолт (90+)" неравно "0"*/
				,b22=0
		
				--b23/*[Средний срок между выходом в дефолт и погашения ОД залогом]сумма по "срок между выходом в дефолт и погашения ОД залогом", у которых "дата погашения залогом" больше или равна Дате1 и меньше или равна Дате2, деленная на Столбец 21*/
				,b23=0
		
				--b24/*[Средний срок между выходом в дефолт и реализацией залога по реализованным авто]сумма по "срок между выходом в дефолт и реализацией залога", у которых "дата погашения залогом" больше или равна Дате1 и меньше или равна Дате2, деленная на Столбец 21*/
				,b24=0

				--b25 /*[Соотношение цены реализации без НДС к цене принятия на баланс]равно разности между Столбец 4 и Столбец 5, деленной на Столбец 3*/
				,b25=0
	
				--b26 /*[Соотношение цены реализации без НДС к балансовой стоимости на момент реализации]равно разности между Столбец 4 и Столбец 5, деленной на Столбец 17*/
				,b26=0
		
				--b27/*[Доля реализованных авто от принятых на баланс, % (по цене принятия на баланс)]равно отношению столбца 3 к столбцу 2*/
				,b27=0


			from  #repmonthDAPP) l1
		)l2
	
  commit tran
	-- костыль для  КРУГЛИКОВ ВАСИЛИЙ АЛЕКСАНДРОВИЧ 09.05.1979 Z8NTBNT31CS054435
	--update dwh2.finAnalytics.DAPP_svod
	--	set summFRMinus_dateFRMinus=summFRMinus_dateFRMinus+(-272000)
	--where repmonth='2024-06-30'
	-- костыль для НОВИКОВ ЮРИЙ АЛЕКСАНДРОВИЧ 07.04.1983 JMZBK14Z251250645
	--update dwh2.finAnalytics.DAPP_svod
	--	set summChangePriceMinus_dateChangePriceMinus=summChangePriceMinus_dateChangePriceMinus+(-2050)
	--where repmonth='2023-12-31'
	
	
	--проверка 1 Проверка фин.результата накопительно
	declare @check1 float =(select round(sum(summFR_summChgMinus_summChgPlus)-sum(v_summFR_summChgMinus_summChgPlus),0) from dwh2.finAnalytics.DAPP_svod)
	update dwh2.finAnalytics.DAPP_svod 
	 set check1=isnull(@check1,0);
	
	--проверка 2 Проверка фин.результата за месяц с ОСВ
	with cte_chk71 as(
		select 
			a.repmonth
			,chk=round(a.summFR_summChgMinus_summChgPlus+isnull(osv.summ*-1,a.summFR_summChgMinus_summChgPlus*-1),0)
			,summ=isnull(osv.summ,a.summFR_summChgMinus_summChgPlus)
		from dwh2.finAnalytics.DAPP_svod a
		left join 
			(select
				repmonth =eomonth(l1.repMonth)
				,summ=sum(l1.sumDohod)-sum(l1.sumRashod) 
 
			from (
				select	
					distinct
						repMonth=eomonth(repMonth)
						,acc2order
						,sumDohod=iif(acc2order='71701',sum(isnull(sumKT_BU,0)-
																iif(month(repMonth)!=1 --исключаем из расчета если первый месяц года
																	,isnull(sumDT_BU,0)
																	,0)
															)over (partition by acc2order,repMonth),0)
						,sumRashod=iif(acc2order='71702',sum(isnull(sumDT_BU,0)-
																iif(month(repMonth)!=1--исключаем из расчета если первый месяц года
																	,isnull(sumKT_BU,0)
																	,0)
															)over (partition by acc2order,repMonth),0)
				from dwh2.finAnalytics.OSV_MONTHLY
				 where acc2order in ('71701','71702') and subconto1 in ('Реализация залогов (ДАПП) - доходы (убытки) (52601,53601; сч.71701,71702)','Доходы от переоценки ДАПП (сч. 71701 символ 52602)','Расходы по переоценке ДАПП (сч. 71702 символ 53602)')
				)l1
			group by eomonth(repMonth)	
			) osv on a.repmonth=osv.repmonth
		)
			
		--left join 
		--	(select
		--		repmonth =eomonth(l1.repMonth)
		--		,summ=sum(l1.sumDohod)-sum(l1.sumRashod) 
		--	from (
		--		select	
		--			distinct
		--				repMonth=eomonth(repMonth)
		--				,acc2order
		--				,sumDohod=iif(acc2order='71701',sum(isnull(sumKT_BU,0))over (partition by acc2order,repMonth),0)
		--				,sumRashod=iif(acc2order='71702',sum(isnull(sumDT_BU,0))over (partition by acc2order,repMonth),0)
		--		from dwh2.finAnalytics.OSV_MONTHLY
		--		 where acc2order in ('71701','71702') and subconto1 in ('Реализация залогов (ДАПП) - доходы (убытки) (52601,53601; сч.71701,71702)','Доходы от переоценки ДАПП (сч. 71701 символ 52602)','Расходы по переоценке ДАПП (сч. 71702 символ 53602)')
		--		)l1
		--	group by eomonth(repMonth)	
		--	) osv on a.repmonth=osv.repmonth
		--)
	merge dwh2.finAnalytics.DAPP_svod trg
	using cte_chk71 src 
		on trg.repmonth=src.repmonth
		when matched then update  set  trg.osv71=src.summ, trg.check71=isnull(src.chk,0);
	
	--проверка 3 Проверка стоимости на балансе на конец месяца
	--значение колонки 16 "стоимость на балансе на конец месяца, руб" на отчетную дату минус остаток в УМФО из ОСВ по счету 62001 на отчетную дату
	with cte_chk62 as(
		select
		 a.repmonth
		 ,chk=round(a.summStoiBalance_dateBalanceSale-isnull(osv.ost,a.summStoiBalance_dateBalanceSale),0)
		 ,summ=isnull(osv.ost,a.summStoiBalance_dateBalanceSale)
		from dwh2.finAnalytics.DAPP_svod a
		left join 
				(select
					repmonth =eomonth(repMonth)
					,ost=sum(isnull(restOUT_BU,0))
				from dwh2.finAnalytics.OSV_MONTHLY
				where acc2order='62001'
				group by  eomonth(repMonth)
				) osv on a.repmonth=osv.repmonth
		)
	merge dwh2.finAnalytics.DAPP_svod trg
	using cte_chk62 src 
		on trg.repmonth=src.repmonth
		when matched then update  set trg.osv62=src.summ,trg.check62=isnull(src.chk,0);
	
	--set @subject=concat('OK! ',@subjectHeader) 
	--set @message=''
	--set @message=concat(@msgHeader,@message,@msgFloor)
	
	--declare @chkResult1 int=0,  @chkResult2 int=0, @chkResult3 int=0
	--select @chkResult1=convert(int ,sum(check1)),@chkResult2=convert(int,sum(check71)),@chkResult3=convert(int,sum(check62)) from dwh2.finAnalytics.DAPP_svod
	--if @chkResult1!=0 or  @chkResult2=0 or @chkResult3!=0 
	--	begin 
	--		set @subject=concat('Внимание! ',@subjectHeader) 
	--		set @message=concat('КC -"Проверка фин.результата накопительно" ',iif(@chkResult1!=0,'Ошибка','Ок'),char(10)
	--						   ,'КC -"Проверка фин.результата за месяц с ОСВ" ',iif(@chkResult2!=0,'Ошибка','Ок'),char(10)
	--						   ,'КC -"Проверка стоимости на балансе на конец месяца" ',iif(@chkResult3!=0,'Ошибка','Ок'),char(10)
	--						   )
	--	end


	--	set @message=concat(@msgHeader,@message,@msgFloor)
	--	exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '99'
	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

	 end try 

 begin catch
 ----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    ROLLBACK TRANSACTION
	set @message=CONCAT('Ошибка выполнения процедуры - ',@sp_name,'. Ошибка ',ERROR_MESSAGE()) 
	set @subject='Ошибка! '
	set @message=concat(@msgHeader,@message)
	exec finAnalytics.sendEmail @subject ,@message ,@strRcp = '99'
   ;throw 51000 
			,@message
			,1;    
  end catch

END


