
CREATE   PROCEDURE [finAnalytics].[loadPBRMonthly] 
    
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
	--старт лог
      drop table if exists #mainPrc
      create table #mainPrc (sp_name nvarchar(255))
      insert into #mainPrc (sp_name)
      values( @sp_name)
      declare @log_IsError bit=0
      declare @log_Mem nvarchar(2000)	='Ok'
      exec dwh2.finAnalytics.sys_log @sp_name,0, @sp_name

   begin try

    declare @repmonthtemp date = (select max(CONVERT (date, [Отчетная дата], 104)) from stg.[files].[PBR_MONTHLY])
    declare @repmonth date = DATEFROMPARTS(DATEPART(year,@repmonthtemp),datepart(month,@repmonthtemp),1)
	
	declare @emailList varchar(255)=''
	
	drop table if exists #errorCount
	create table #errorCount(
		checkName nvarchar(300) null,
		errCount nvarchar(100) null,
		errNum int null
		)
	declare @errCount int

	-- проверка на соответвие полей таблиц из схемы STG и справочника STG ФинДеп
	exec finAnalytics.sys_checkSprStg @procName =@sp_name
    
	-- проверка поля Способ выдачи займа на пустые знаяения 

	exec finAnalytics.checkZaim 'monthly', @repmonth, @errCount output
	insert into #errorCount values('Способ выдачи займа не равно пусто: ',concat(
																				trim(str(isnull(@errCount,0)))
																				,' ошибок'
																				)
																				,1)
	
	-- проверка "Наличие залога поручительства"
	exec finAnalytics.checkPTSAutocredit @repmonth, @errCount output
	insert into #errorCount values('Наличие залога поручительства равно пусто: ',concat(
																				trim(str(isnull(@errCount,0)))
																				,' ошибок'
																				)
																				,2)

	--процедура проверки на актуальную дату в реестре остатков 60323
	exec [finAnalytics].[loadPBR_60323Check] @repmonth
	
	--процедура проверки нулевого ПДН
	exec [finAnalytics].[loadPBR_PDNCheck] @repmonth, 'monthly' , @errCount output
	insert into #errorCount values('Проверка ПДН пусто или 0 по договорам ФЛ (кроме самозанятых): ',concat(
																				trim(str(isnull(@errCount,0)))
																				,' ошибок'
																				)
																				,3)
	
	-- процедура проверки пристутствия номенклатурных групп в таблице nomenkGroup 
	exec [finAnalytics].[loadPBR_nomenkGroupCheck] 'monthly'
	
	-- процедура проверки дублирующихся договоров
    exec finAnalytics.loadPBRMonthly_doubleCheck @repmonth

	---- процедура проверки номенклатурных груп по займам для Самозанятых
	--exec [finAnalytics].[loadPBR_zamozanyatCheck] 'monthly'

	-- процедура проверки корректности закрытых договоров
	declare @errorCloseDate int = 0
	exec [finAnalytics].[loadPBR_closeDateCheck] @repmonthtemp, 'monthly', @errorCloseDate output
	--if @errorCloseDate = 1 throw 51000 , 'Ошибка проверки поля Дата закрытия', 1
	insert into #errorCount values('Корректность дат закрытых договоров (по цессии, если есть причина закрытия но нет даты): ',concat(
																				trim(str(Isnull(@errorCloseDate,0)))
																				,' ошибок'
																				)
																				,4)

	-- процедура проверки Даты выдачи
	declare @errorSaleDate int = 0
	exec [finAnalytics].[loadPBR_saleDateCheck] @repmonthtemp, 'monthly', @errorSaleDate output
	insert into #errorCount values('Корректность Даты выдачи (нет даты выдачи при ненулевом остатке ОД): ',concat(
																				trim(str(Isnull(@errorSaleDate,0)))
																				,' ошибок'
																				)
																				,5)
    if @errorSaleDate = 1 throw 51000 , 'Ошибка проверки поля Дата выдачи', 1

	-- процедура проверки ПСК для РВПЗ
	declare @errorPSK int = 0
	exec [finAnalytics].[loadPBR_PSKCheck] @repmonthtemp, 'monthly', @errorPSK output
	insert into #errorCount values('Наличие ненулевого ПСК по действующим договорам ФЛ (кроме Самозанятых): ',concat(
																				trim(str(Isnull(@errorPSK,0)))
																				,' ошибок'
																				)
																				,6)
	--if @errorPSK = 1 throw 51000 , 'Ошибка проверки ПСК для РВПЗ', 1

	exec [finAnalytics].[loadPBR_checkAllresult] @repmonthtemp

  begin tran  

    delete from [finAnalytics].PBR_MONTHLY	where REPMONTH=@repmonth
    
    INSERT INTO [finAnalytics].PBR_MONTHLY
	(
	 REPMONTH, [Client], [isZaemshik], [isBankrupt], isDosieBankrupt, [isMSP], [passport], [birthday], 
	 [addressPDN], [addresFact], [addressReg], [finProd], [dogNum], [dogDate], [saleDate], [saleType], [isCessia], 
	 [pogashenieDate], [pogashenieDateDS], [KKEndDate], [dogPeriodMonth], [dogPeriodDays], [dogSum], [isDogPoruch], 
	 [dogZalogNum], [dogZalogDate], [TsVin], [dogVin], [isDocred], [zalogSum], [zalogSumRaspred], [spravedSum], [spravedSumRaspred], 
	 [spravedSumProverObespech], [PDNOnSaleDate], [monthIncom], [primeSum], [isRefinance], [isRestruk], [restrukNum], 
	 [restrukDate], [restrukDateEnd], [restrukPeriod], [firsProsDate], [zadolgOD], [zadolgPrc], [penyaSum], [gosposhlSum], 
	 [prosODSum], [prosPRCSum], [prosDays], [prosHist], [prosDaysTotal], [prosMax], [reservODPRC], [reservOD], [reservPRCPrc], 
	 [reservPRC], [dogStatus], [prosDaysNU], [reservPrcODNU], [reservPRCprcNU], [reservProchSumNU], [reservBUODSum], 
	 [reservBUpPrcSum], [reservBUPenyaSum], [DSType], [stavaOnSaleDate], [stavaOnRepDate], [PSK], [PSKFirst], [isObespechZaym], 
	 [PDNOnRepDate], [isPros], [AccODNum], [AccPrcNum], [AccObespechNum], [branch], [branchAddress], [ClientID], [INN], 
	 [prosDaysLastYear], [CloseDate], [nomenkGroup], [isAkcia], [ODLastPayDate], [ODLastPaySum], [sum47422], [Acc47422Num], 
	 [isOutBalance], [LasPay47422Date], [LasPay47422Sum], [AccPenyaNum], [LastProvDTDate], [LastProvKTDate], [trebPogashDate], 
	 [zakritObazType], [creditor], [creditorDogNum], [IsMarked], [ZalogInDate], [ZalogOutDate], [isZamoroz1], [isZamoroz1Date], 
	 [isZamoroz2], [isZamoroz2Date], [isStavkaChange], [isStavkaChangeDate], [isCredKanik], [isCredKanikDate], [isCancelRestruk], 
	 [isCancelRestrukDate], [isProlong], [isProlongDate], [isResrukt], [isResruktDate], [isResrukt2], [isResrukt2Date], [isRefinance2], 
	 [isRefinance2Date], [isSnigStavka], [isSnigStavkaDate], [isCredKanik2], [isCredKanik2Date], [isCancleCredKanik], [isCancleCredKanikDate], 
	 [isProlongPDL], [isProlongPDLDate], [dataLoadDate], PSK_prc, prosFrozenDays, isStopCredKanik, isStopCredKanikDate, KKEndMaxCHPD, KKEndMaxCHPDDate,
	 KKEvac, KKEvacDate, KKEvacStop, KKEvacStopDate, KKEvacCancel, KKEvacCancelDate, KK353, KK353Date, KK353Stop, KK353StopDate, KK353Cancel, KK353CancelDate,
	 isNotTarget, [salesRegion], [isZaemshik2], [A1_A6]
	 )
     
    select
        [repmonth] ,[Client] ,[isZaemshik] ,[isBankrupt] ,[isDisieBanrupt] ,[isMSP] ,[passport] ,[birthday]
		,[addressPDN] ,[addresFact] ,[addressReg] ,[finProd] ,[dogNum] ,[dogDate] ,[saleDate] ,[saleType] ,[isCessia]
		,[pogashenieDate] ,[pogashenieDateDS] ,[KKEndDate] ,[dogPeriodMonth] ,[dogPeriodDays] ,[dogSum] ,[isDogPoruch]
		,[dogZalogNum] ,[dogZalogDate] ,[TsVin] ,[dogVin] ,[isDocred ] ,[zalogSum ] ,[zalogSumRaspred] ,[spravedSum ] ,[spravedSumRaspred]
		,[spravedSumProverObespech] ,[PDNOnSaleDate] ,[monthIncom] ,[primeSum] ,[isRefinance] ,[isRestruk] ,[restrukNum]
		,[restrukDate] ,[restrukDateEnd] ,[restrukPeriod] ,[firsProsDate] ,[zadolgOD] ,[zadolgPrc] ,[penyaSum] ,[gosposhlSum]
		,[prosODSum] ,[prosPRCSum] ,[prosDays] ,[prosHist] ,[prosDaysTotal] ,[prosMax] ,[reservODPRC] ,[reservOD] ,[reservPRCPrc]
		,[reservPRC] ,[dogStatus] ,[prosDaysNU] ,[reservPrcODNU] ,[reservPRCprcNU] ,[reservProchSumNU] ,[reservBUODSum]
		,[reservBUpPrcSum] ,[reservBUPenyaSum] ,[DSType] ,[stavaOnSaleDate] ,[stavaOnRepDate] ,[PSK] ,[PSKFirst] ,[isObespechZaym]
		,[PDNOnRepDate] ,[isPros] ,[AccODNum] ,[AccPrcNum] ,[AccObespechNum] ,[branch] ,[branchAddress] ,[ClientID] ,[INN]
		,[prosDaysLastYear] ,[CloseDate] ,[nomenkGroup] ,[isAkcia] ,[ODLastPayDate] ,[ODLastPaySum] ,[sum47422] ,[Acc47422Num]
		,[isOutBalance] ,[LasPay47422Date] ,[LasPay47422Sum] ,[AccPenyaNum] ,[LastProvDTDate] ,[LastProvKTDate] ,[trebPogashDate]
		,[zakritObazType] ,[creditor] ,[creditorDogNum] ,[IsMarked] ,[ZalogInDate] ,[ZalogOutDate] ,[isZamoroz1] ,[isZamoroz1Date]
		,[isZamoroz2] ,[isZamoroz2Date] ,[isStavkaChange] ,[isStavkaChangeDate] ,[isCredKanik] ,[isCredKanikDate] ,[isCancelRestruk]
		,[isCancelRestrukDate] ,[isProlong] ,[isProlongDate] ,[isResrukt] ,[isResruktDate] ,[isResrukt2] ,[isResrukt2Date] ,[isRefinance2]
		,[isRefinance2Date] ,[isSnigStavka] ,[isSnigStavkaDate] ,[isCredKanik2] ,[isCredKanik2Date] ,[isCancleCredKanik] ,[isCancleCredKanikDate]
		,[isProlongPDL] ,[isProlongPDLDate] ,[dataLoadDate], PSK_PRC, prosFrozenDays, isStopCredKanik, isStopCredKanikDate, KKEndMaxCHPD, KKEndMaxCHPDDate
		,KKEvac, KKEvacDate, KKEvacStop, KKEvacStopDate, KKEvacCancel, KKEvacCancelDate, KK353, KK353Date, KK353Stop, KK353StopDate, KK353Cancel, KK353CancelDate
		,isNotTarget, [salesRegion], [isZaemshik2], [A1_A6]
    from (
	SELECT 
        [repmonth] = @repmonth
		,[Client] = [Контрагент]
		/*Обход нововведения*/
		,[isZaemshik] = case when [Признак заемщика] = 'Самозанятый' then 'ФЛ' else [Признак заемщика] end

		,[isBankrupt] = case when bnkrupt.[Заемщик] is not null and bnkrupt.[Исключить] = 0 then 'Да' else 'Нет' end--[Банкротство] 
		,[isDisieBanrupt] = [Досье контрагента (банкрот)] 
		,[isMSP] = isnull([МСП],'') 
		,[passport] = [Паспортные данные]
		,[birthday] = CONVERT (date, [Дата рождения], 104)
		,[addressPDN] = isnull([Адрес для расчет ПДН],'')
		,[addresFact] = [Адрес проживания]
		,[addressReg] = [Адрес регистрации] 
		,[finProd] = [Финансовый продукт] 
		,[dogNum] = [Номер договора] 
		,[dogDate] = CONVERT (date, [Дата договора], 104) 
		,[saleDate] = CONVERT (date, [Дата выдачи], 104) 
		,[saleType] = [Способ выдачи займа] 
		,[isCessia] = [Цессия (проданные займы)] 
		,[pogashenieDate] = CONVERT (date, [Дата погашения], 104) 
		,[pogashenieDateDS] = CONVERT (date, [Дата погашения с учетом ДС], 104) 
		,[KKEndDate] = CONVERT (date, [Дата окончания по КК], 104) 
		,[dogPeriodMonth] = cast([Срок договора в месяцах] as float)
		,[dogPeriodDays] = cast([Срок договора в днях] as float)
        ,[dogSum] = cast([Сумма займа] as float)
		,[isDogPoruch] = [Наличие залога поручительства] 
		,[dogZalogNum] = [Номер договора залога] 
		,[dogZalogDate] = CONVERT (date, [Дата договора залога], 104) 
		,[TsVin] = [Транспортное средство vin] 
		,[dogVin] = [Vin в договоре] 
		,[isDocred ] = [Докредитование] 
        ,[zalogSum ] = cast(isnull([Залоговая стоимость],0) as float)
		,[zalogSumRaspred] = cast(isnull([Залоговая стоимость распределение],0) as float)
		,[spravedSum ] = cast(isnull([Справедливая стоимость],0) as float)
		,[spravedSumRaspred] = cast(isnull([Справедливая стоимость распределенная по vin],0) as float)
		,[spravedSumProverObespech] = cast(isnull([Справедливая стоимость проверка обеспеченности],0) as float)
		,[PDNOnSaleDate] = cast([ПДН на дату выдачи (НЕ для ЦБ)] as float)
		,[monthIncom] = cast(isnull([Среднемесячный доход],0) as float)
		,[primeSum] = cast(isnull([Первичная сумма],0) as float)
		,[isRefinance] = [Рефинансирование] 
		,[isRestruk] = [Реструктуризирован] 
		,[restrukNum] = [Реструктуризирован номер]
		,[restrukDate] = CONVERT (date, [Реструктуризирован дата], 104) 
		,[restrukDateEnd] = CONVERT (date, [Реструктуризирован дата окончания], 104) 
		,[restrukPeriod] = cast([Реструктуризирован срок] as float)
		,[firsProsDate] = case when 
									cast(isnull([Задолженность ОД],0) as float)=0 
									and cast(isnull([Задолженность ОД],0) as float)=0 
									and cast(isnull([Сумма пени счета],0) as float)=0 
									and cast(isnull([Сумма госпошлин счета],0) as float) !=0 
									then r60323.prosDateBegin
									else CONVERT (date, [Дата первой просрочки], 104) end
		,[zadolgOD] = cast(isnull([Задолженность ОД],0) as float)
		,[zadolgPrc] = cast(isnull([Задолженность проценты],0) as float)
		,[penyaSum] = cast(isnull([Сумма пени счета],0) as float)
		,[gosposhlSum] = cast(isnull([Сумма госпошлин счета],0) as float)
		,[prosODSum] = cast(isnull([Сумма просрочки основной долг],0) as float)
		,[prosPRCSum] = cast(isnull([Сумма просрочки проценты],0) as float)
		,[prosDays] = cast([Дней просрочки] as float)
		,[prosHist] = cast([Историческая просрочка] as float)
		,[prosDaysTotal] = case when 
								cast(isnull([Задолженность ОД],0) as float)=0 
								and cast(isnull([Задолженность проценты],0) as float)=0 
								and cast(isnull([Сумма пени счета],0) as float)=0 
								and cast(isnull([Сумма госпошлин счета],0) as float)!=0 
								and cast([Итого дней просрочки общая] as float)=0 
                                then abs(DATEDIFF(day,EOMONTH(@repmonth),r60323.prosDateBegin))
                                else cast([Итого дней просрочки общая] as float) end
		,[prosMax] = cast([Максимальный срок просрочки по одному заемщику] as float)
		,[reservODPRC] = cast(isnull([Процент резерва ОД],0) as float)
		,[reservOD] = cast(isnull([Резерв ОД],0) as float)
		,[reservPRCPrc] = cast(isnull([Процент резерва проценты],0) as float)
		,[reservPRC] = cast(isnull([Резерв проценты],0) as float)
		,[dogStatus] = [Состояние] 
		,[prosDaysNU] = cast([Дней просрочки1] as float)
		,[reservPrcODNU] = cast(isnull([Процент резерва ОД1],0) as float)
		,[reservPRCprcNU] = cast(isnull([Процент резерва проценты1],0) as float)
		,[reservProchSumNU] = cast(isnull([Сумма резерв прочие НУ],0) as float)
		,[reservBUODSum] =  cast(isnull([Сумма резерва БУ ОД],0) as float)
		,[reservBUpPrcSum] = cast(isnull([Сумма резерва БУ проценты],0) as float)
		,[reservBUPenyaSum] = cast(isnull([Сумма резерва БУ пени и госпошлины],0) as float)
		,[DSType] = [Вид ДС]
		,[stavaOnSaleDate] =  cast(isnull([Ставка на дату выдачи],0) as float)
		,[stavaOnRepDate] = cast(isnull([Ставка на дату формирования отчета],0) as float)
		,[PSK] = cast(isnull([ПСК],0) as float)
		,[PSKFirst] = cast(isnull([ПСК первоначальная],0) as float)
		,[isObespechZaym] = [Обеспеченный займ] 
		,[PDNOnRepDate] = cast(isnull([ПДН на отчетную дату],0) as float)
		--,[PDNOnRepDate] = case when [ПДН на отчетную дату] = 'NULL' then NULL else CAST([ПДН на отчетную дату] as float) end--cast([ПДН на отчетную дату] as float)
		,[isPros] = [Наличие просрочки] 
		,[AccODNum] = [Счет учета основного долга] 
		,[AccPrcNum] = [Счет учета начисления процентов]
		,[AccObespechNum] = [Счет учета обеспечения] 
		,[branch] = [Подразделение организации] 
		,[branchAddress] = [Адрес подразделения] 
		,[ClientID] = [Контрагент код] 
		,[INN] = case when a.[ИНН] is null then cl.inn else a.[ИНН] end 
		,[prosDaysLastYear] = cast([Дней просрочки за последний год] as float)
		,[CloseDate] = CONVERT (date, [Дата закрыт], 104) 
		,[nomenkGroup] = [Номенклатурная группа]
		,[isAkcia] = [Акция 0%]
		,[ODLastPayDate] = CONVERT (date, [Дата последнего платежа по ОД], 104) 
		,[ODLastPaySum] = cast(isnull([Сумма последнего платежа по ОД],0) as float)
		,[sum47422] = cast(isnull([Сумма47422],0) as float)
		,[Acc47422Num] = [Счет аналитического учета47422] 
		,[isOutBalance] = [Забаланс]
		,[LasPay47422Date] = CONVERT (date, [Последний платеж 47422], 104) 
		,[LasPay47422Sum] = cast(isnull([Сумма последнего платежа 47422],0) as float)
		,[AccPenyaNum] = [Лицевой счет учета пени] 
		,[LastProvDTDate] = CONVERT (date, [Дата последней проводки дт], 104) 
		,[LastProvKTDate] = CONVERT (date, [Дата последней проводки кт], 104)
		,[trebPogashDate] = CONVERT (date, [Дата погашения требований], 104)
		,[zakritObazType] = [Способ закрытия обязательств]
		,[creditor] = [Кредитор] 
		,[creditorDogNum] = [Договор с кредитором] 
		,[IsMarked] = [Маркирован] 
		,[ZalogInDate] = CONVERT (date, [Дата входа в залог], 104)
		,[ZalogOutDate] = CONVERT (date, [Дата выхода из залога], 104)
		,[isZamoroz1] = [Заморозка (для резервов 30#06#21)] 
		,[isZamoroz1Date] = CONVERT (date, [Дата ДС], 104)
		,[isZamoroz2] = [Заморозка 1#0]
		,[isZamoroz2Date] = CONVERT (date, [Дата ДС1], 104) 
		,[isStavkaChange] = [Изм#ставки, пополнение ОД] 
		,[isStavkaChangeDate] = CONVERT (date, [Дата ДС2], 104) 
		,[isCredKanik] = [Кредитные каникулы] 
		,[isCredKanikDate] = CONVERT (date, [Дата ДС3], 104) 
		,[isCancelRestruk] = [Отмена Реструктуризации] 
		,[isCancelRestrukDate] = CONVERT (date, [Дата ДС4], 104) 
		,[isProlong] = [Пролонгация] 
		,[isProlongDate] = CONVERT (date, [Дата ДС5], 104) 
		,[isResrukt] = [Реструктуризация] 
		,[isResruktDate] = CONVERT (date, [Дата ДС6], 104) 
		,[isResrukt2] = [Реструктуризация (перенос даты)] 
		,[isResrukt2Date] = CONVERT (date, [Дата ДС7], 104) 
		,[isRefinance2] = [Рефинансирование1] 
		,[isRefinance2Date] = CONVERT (date, [Дата ДС8], 104) 
		,[isSnigStavka] = [Снижение ставки (реструктуризация)] 
		,[isSnigStavkaDate] = CONVERT (date, [Дата ДС9], 104) 
		,[isCredKanik2] = [Кредитные каникулы по 377-ФЗ] 
		,[isCredKanik2Date] = CONVERT (date, [Дата ДС10], 104) 
				
		,[isStopCredKanik] = a.[Остановка Кредитных каникул по 377-ФЗ]
		,[isStopCredKanikDate] = CONVERT (date, a.[Дата ДС11], 104)
		
		,[isCancleCredKanik] = [Отмена Кредитных каникул по 377-ФЗ] 
		,[isCancleCredKanikDate] = CONVERT (date, [Дата ДС12], 104) 

		,[isProlongPDL] = [Пролонгация PDL] 
		,[isProlongPDLDate] = CONVERT (date, [Дата ДС13], 104) 
        
		,[KKEndMaxCHPD] = [Завершение КК# Максимальное ЧДП]
		,[KKEndMaxCHPDDate] = CONVERT (date, a.[Дата ДС14], 104)
		,[KKEvac] = [КК по эвакуированным/ЧС (ФЗ-106)]
		,[KKEvacDate] = CONVERT (date, a.[Дата ДС15], 104)
		,[KKEvacStop] = [Остановка КК по эвакуированным/ЧС (ФЗ-106)]
		,[KKEvacStopDate] = CONVERT (date, a.[Дата ДС16], 104)
		,[KKEvacCancel] = [Отмена КК по эвакуированным/ЧС (ФЗ-106)]
		,[KKEvacCancelDate] = CONVERT (date, a.[Дата ДС17], 104)
		,[KK353] = [Кредитные каникулы по 353-ФЗ]
		,[KK353Date] = CONVERT (date, a.[Дата ДС18], 104)
		,[KK353Stop] = [Остановка Кредитных каникул по 353-ФЗ]
		,[KK353StopDate] = CONVERT (date, a.[Дата ДС19], 104)
		,[KK353Cancel] = [Отмена Кредитных каникул по 353-ФЗ]
		,[KK353CancelDate] = CONVERT (date, a.[Дата ДС20], 104)

		,[dataLoadDate] = created
        ,[row_num] = row_number() over (Partition by a.[Номер договора] order by a.[№ п/п])
        ,[PSK_prc] = cast(isnull(a.[ПСК для РВПЗ],0) as float)
		
		,[prosFrozenDays] = cast(a.[Замороженные дни просрочки] as float)
		,[isNotTarget] = a.[Использование не по целевому назначению]
		,[salesRegion] = a.[Территория выдачи]
		,[isZaemshik2] = a.[Признак заемщика]
		,[A1_A6] = a.[Включение займа в категории А1 - А6]
	from stg.[files].[PBR_MONTHLY] a
    left join (
        select [Дата] = cast(dateadd(year,-2000,a.Дата) as date)
        ,[Заемщик] = b.Наименование
        ---Признак исключения для проброски в ПБР
        --,[Исключить] = case when a.Номер in ('00БП-0266','00БП-0302','00БП-0496','00БП-0637','00БП-0733') then 1 else 0 end
		,[Исключить] = case when 
							c.[client] is not null and @repmonth between c.nonBunkruptStartDate and isnull(c.nonBunkruptEndDate,getdate())
							then 1 else 0 end
        ---Считаем дубли и берем максимальное по дате в кореляции с отчетной датой
        ,ROW_NUMBER() over (Partition by b.Наименование order by a.Дата desc) rn

        from stg._1cUMFO.Документ_АЭ_БанкротствоЗаемщика a
        left join stg._1cUMFO.Справочник_Контрагенты b on a.Контрагент=b.Ссылка
		left join dwh2.[finAnalytics].[SPR_notBunkrupt] c on b.Наименование = c.[client]
        where 1=1
        and a.ПометкаУдаления =  0x00
        and a.Проведен=0x01
        and cast(dateadd(year,-2000,a.Дата) as date) <=EOMONTH(@repmonth)
        ) bnkrupt on a.[Контрагент]=bnkrupt.[Заемщик] and bnkrupt.rn=1

    left join finAnalytics.credClients cl on a.[Номер договора] =cl.dogNum
    left join (
        select
        a.repMonth
        ,a.dogNum
        ,prosDateBegin = min(a.prosDateBegin)
        from finAnalytics.rests60323 a
        --where dogNum='17102010380001'
        group by a.repMonth
        ,a.dogNum
    ) r60323 on a.[Номер договора]=r60323.dogNum --and r60323.repmonth=@repmonth

	--берем только выданные кредиты
	where a.[Дата выдачи] is not null
		and CONVERT (date, a.[Дата договора],104) <= EOMONTH(@repmonth)
		and CONVERT (date, a.[Дата выдачи],104) <= EOMONTH(@repmonth)
    ) l1

    where 1=1
    and l1.row_num=1

	/*Обновление данных по МСП*/
    merge into finAnalytics.PBR_MONTHLY t1
    using(
 --   select
 --   a.ID
 --   ,a.REPMONTH
 --   ,a.saleDate
 --   ,b.reestrInDate
 --   ,b.reestrOutDate
 --   ,a.dogNum
 --   ,a.Client
 --   ,a.isMSP
 --   ,isMSPbyDogDate = case when EOMONTH(a.saleDate) between b.reestrInDate and isnull(b.reestrOutDate,EOMONTH(a.repmonth)/*cast(getdate() as date)*/) then 'Да' else 'Нет' end
 --   ,isMSPbyRepDate = case when EOMONTH(a.repmonth) between b.reestrInDate and isnull(b.reestrOutDate,EOMONTH(a.repmonth)/*cast(getdate() as date)*/) then 'Да' else 'Нет' end
 --   from finAnalytics.PBR_MONTHLY a
 --   --inner join finAnalytics.MSP_reestr b on a.INN=b.INN and upper(a.isZaemshik) != 'ФЛ'
	--inner join finAnalytics.MSP_reestr b on 
	--											a.INN=b.INN 
	--											and upper(a.isZaemshik) != 'ФЛ'
	--											and EOMONTH(a.repmonth) between b.reestrInDate and isnull(b.reestrOutDate,EOMONTH(a.repmonth))
	select
		a.ID
		,a.REPMONTH
		,a.saleDate
		,b1.reestrInDate
		,b1.reestrOutDate
		,a.dogNum
		,a.Client
		,a.isMSP
		,isMSPbyDogDate = case when EOMONTH(a.saleDate) between b2.reestrInDate and isnull(b2.reestrOutDate,EOMONTH(a.repmonth)/*cast(getdate() as date)*/) then 'Да' else 'Нет' end
		,isMSPbyRepDate = case when EOMONTH(a.repmonth) between b1.reestrInDate and isnull(b1.reestrOutDate,EOMONTH(a.repmonth)/*cast(getdate() as date)*/) then 'Да' else 'Нет' end
		from finAnalytics.PBR_MONTHLY a
		left join finAnalytics.MSP_reestr b1 on 
												a.INN=b1.INN 
												and EOMONTH(a.repmonth) between b1.reestrInDate and isnull(b1.reestrOutDate,EOMONTH(a.repmonth))
		left join finAnalytics.MSP_reestr b2 on 
												a.INN=b2.INN 
												and a.saleDate between b2.reestrInDate and isnull(b2.reestrOutDate,EOMONTH(a.repmonth))
		where 1=1--a.INN = '690706648816'
		and upper(a.isZaemshik) != 'ФЛ'
		--order by a.REPMONTH
    ) t2 on (t1.id=t2.id)
    when matched then update
    set
    t1.isMSPbyDogDate=t2.isMSPbyDogDate,
    t1.isMSPbyRepDate=t2.isMSPbyRepDate;

	/* отменено с 25.09.2025
	-----------Добавление данных по ПСК от Рисков
	select 
	q1.external_id
	,q1.ПСК as psk_int

	into #stg_psk

	from(
	select
	d.код AS external_id
	, p.Период
	, p.ПСК
	, row_number() over (partition by d.код order by p.Период) rnn
	from stg._1cCMR.Справочник_Договоры d
	inner join stg._1cCMR.РегистрСведений_ИнформацияПоДоговору as p on d.Ссылка = p.Договор
	) q1

	where rnn = 1

	merge into finAnalytics.PBR_MONTHLY t1
	using
	(
	select 
	external_id
	,psk_int
	from #stg_psk
	) t2 on (t1.dogNum=t2.external_id and t1.repmonth=@repmonth)

	when matched then update
	set t1.PSK_prc = t2.psk_int;
	-----------------------
	*/
	commit tran

	--Добавление данных в ПБР (каналы, среднемесячные ОД, RBP)
	exec [finAnalytics].[loadPBR_addMoreData] 'monthly', @repmonth

    --Запуск процедуры расчета данных для отчета Андрея по ПДН
    exec finAnalytics.calcPDNrepData_Monthly @repmonth, @repmonthtemp
    
	--Запуск процедуры расчета данных для отчета Леры по Резервам
    exec finAnalytics.loadRepReservData @repmonth
	
	--Запуск процедуры расчета данных для отчета по Акции 0%
	--exec finAnalytics.calcAcia0prcFirstRun @repmonth
	
	--Запуск процедуры расчета данных для отчета по Остановке %%
	exec [finAnalytics].[calcRepStopPRC] @repmonth

	--Запуск процедуры расчета данных для формы 832
	EXEC [finAnalytics].[calcRep832] @repmonth

	----Запуск процедуры расчета данных по ДАПП
	--EXEC [finAnalytics].[addDAPP] @repmonth

	--Запуск проверки маппинга Проудкта для планов
	declare @errorMapping int = 0
	EXEC [finAnalytics].[loadPBR_productMappingCheck] @repmonth, 'monthly', @errorMapping output
	--if @errorMapping = 1 throw 51000 , 'Ошибка проверки поля Дата выдачи', 1
	
	DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repmonth) from finAnalytics.PBR_MONTHLY ) as varchar)
    /*Фиксация времени расчета*/
	update dwh2.[finAnalytics].[reportReglament]
	set lastCalcDate = getdate(),[maxDataDate] = @maxDateRest
	where [reportUID]  in (5,14,9,10)

    
    
    
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

      

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Загрузка ПБР за '
                ,FORMAT( @REPMONTH, 'MMMM yyyy', 'ru-RU' )
                ,char(10)
                ,char(13)
                ,'Время начала выполнения: '
                ,@procStartTime
                ,char(10)
                ,char(13)
                ,'Время окончания выполнения: '
                ,@procEndTime
                ,char(10)
                ,char(13)
                ,'Время выполнения: '
                ,@timeDuration
                ,char(10)
                ,char(13)
                ,'Максимальная дата остатков: '
                ,@maxDateRest
				)

   	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,103))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;

	--финиш
     exec dwh2.finAnalytics.sys_log @sp_name,1, @sp_name

    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	--кэтч
        set @log_IsError =1
        set @log_Mem =ERROR_MESSAGE()
       exec finAnalytics.sys_log @sp_name,1, @sp_name, @log_IsError, @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	--настройка адресатов рассылки
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients =@emailList
			,@copy_recipients = ''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch
END
