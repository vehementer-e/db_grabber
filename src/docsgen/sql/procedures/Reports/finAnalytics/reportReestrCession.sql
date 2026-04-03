




CREATE PROCEDURE [finAnalytics].[reportReestrCession]
		@startDate date,
		@endDate date
		,@id_choice int
AS
BEGIN

	--select 
	--[Период]=[REPDATE]
	--,[Номер договора займа]=[dogClient]
	--,[Дата договора займа]=[dogClientDate]
	--,[Заемщик]=[Client]
	--,[Дата цессии]=[REPDATE]
	--,[Номер и дата договора цессии]=[dogCesionary]
	--,[Цессионарий]=[Cesionary]
	--,[Номенклатурная группа]=[NomenkGroup]
	--,[Продукт]=[produkt]
	--,[Количество дней просрочки на дату цессии ]= [DayPros]
	--,[Основной долг]=[ZadolgOsnovDolg]
	--,[Проценты]=[ZadolgProc]
	--,[Выручка]=[viruchka]
	--,[Резерв БУ]=[reservBU]
	--,[Резерв НУ]=[reservNU]
	--,[ГП]=[gp]
	--,[Пени]=[ZadolgPeni]
	--,[Резерв по ГП и Пеням]=[reservGP_P]
	--,[Финрез БУ]=[finreservBU]
	--,[Финрез НУ]=[finreservNU]
	--,[Цена в процентах от балансовой стоимости ОД+Прц]=format([procPriceBalans],'0.00%')
	--,[Резерв БУ процент]=format([procReservBU],'0.00%')
	--,[Резерв НУ процент]=format([procReservNU],'0.00%')
	--,[Проверка финреза БУ]= [checkFinreservBU]
	--,[Проверка финреза НУ]=[checkFinreservNU]
	--,[Номер договора займа ВОЗВРАТ]=[numDogBack]
	--,[Дата возврата]=[dateBack]
	--,[Номер договора займа ИЗМЕНЕНИЕ ЦЕНЫ]=[numDogBackChangePrice]
	--,[Сумма корректировки по перерасчету цены прав требования ]=[summChangePrice]
	--,[Дата изменения цены договора цессии]=[dateChangePrice]
	--,[Новая цена договора цессии]=[newPriceDogCession]
	--,[Новый Финрез БУ]=[newFinreservBU]
	--,[Новый Финрез НУ]=[newFinreservNU]
	--,[Новая Цена в процентах от балансовой стоимости ОД+Прц]=format([newProcPriceBalans],'0.00%')
	--,[Резерв БУ по ОД]=[OdInReservBU]
 --   ,[Резерв БУ по %]=[PrcInReservBU]

	--from dwh2.[finAnalytics].ReestrCession
	--where [REPDATE] between @startDate and @endDate
	
	drop table if exists #ces 
	select 
	[Период]=[REPDATE]
	,[Номер договора займа]=[dogClient]
	,[Дата договора займа]=[dogClientDate]
	,[Заемщик]=[Client]
	,[Дата цессии]=[REPDATE]
	,[Номер и дата договора цессии]=[dogCesionary]
	,[Цессионарий]=[Cesionary]
	,[Номенклатурная группа]=[NomenkGroup]
	,[Продукт]=[produkt]
	,[Количество дней просрочки на дату цессии ]= [DayPros]
	,[Основной долг]=[ZadolgOsnovDolg]
	,[Проценты]=[ZadolgProc]
	,[Выручка]=[viruchka]
	,[Резерв БУ]=[reservBU]
	,[Резерв НУ]=[reservNU]
	,[ГП]=[gp]
	,[Пени]=[ZadolgPeni]
	,[Резерв по ГП и Пеням]=[reservGP_P]
	,[Финрез БУ]=[finreservBU]
	,[Финрез НУ]=[finreservNU]
	,[Цена в процентах от балансовой стоимости ОД+Прц]=format([procPriceBalans],'0.00%')
	,[Резерв БУ процент]=format([procReservBU],'0.00%')
	,[Резерв НУ процент]=format([procReservNU],'0.00%')
	,[Проверка финреза БУ]= [checkFinreservBU]
	,[Проверка финреза НУ]=[checkFinreservNU]
	,[Номер договора займа ВОЗВРАТ]=[numDogBack]
	,[Дата возврата]=[dateBack]
	,[Номер договора займа ИЗМЕНЕНИЕ ЦЕНЫ]=[numDogBackChangePrice]
	,[Сумма корректировки по перерасчету цены прав требования ]=[summChangePrice]
	,[Дата изменения цены договора цессии]=[dateChangePrice]
	,[Новая цена договора цессии]=[newPriceDogCession]
	,[Новый Финрез БУ]=[newFinreservBU]
	,[Новый Финрез НУ]=[newFinreservNU]
	,[Новая Цена в процентах от балансовой стоимости ОД+Прц]=format([newProcPriceBalans],'0.00%')
	,[Резерв БУ по ОД]=[OdInReservBU]
    ,[Резерв БУ по %]=[PrcInReservBU]
	into #ces
	from dwh2.[finAnalytics].ReestrCession
	if @id_choice=1
		select 
			*
		from #ces
		where Период between @startDate and @endDate
		order by Период
	if @id_choice=2
		select 
			*
		from #ces
		where [Дата возврата] between @startDate and @endDate
		order by Период
	if @id_choice=3
		select 
			*
		from #ces
		where [Дата изменения цены договора цессии] between @startDate and @endDate
		order by Период
	
	
END
