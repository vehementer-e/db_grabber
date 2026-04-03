
CREATE   PROCEDURE [finAnalytics].[loadPBRWeekly] 
    
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
      drop table if exists #mainPrc
      create table #mainPrc (sp_name nvarchar(255))
      insert into #mainPrc (sp_name)
      values( @sp_name)
      declare @log_IsError bit=0
      declare @log_Mem nvarchar(2000)	='Ok'
      exec dwh2.finAnalytics.sys_log @sp_name,0, @sp_name

    
	DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
    declare @errCount int

    begin try

    declare @repdate date = (select max(CONVERT (date, [Отчетная дата], 104)) from stg.[files].[PBR_WEEKLY])
    declare @repmonth date = DATEFROMPARTS(DATEPART(year,@repdate),datepart(month,@repdate),1)
    --select @repmonthtemp
	
	-- проверка на соответвие полей таблиц из схемы STG и справочника STG ФинДеп
	exec finAnalytics.sys_checkSprStg @procName =@sp_name
	-- проверка поля Способ выдачи займа на пустые знаяения 
	exec finAnalytics.checkZaim 'weekly',@repdate, @errCount output
	--процедура проверки нулевого ПДН
	exec [finAnalytics].[loadPBR_PDNCheck] @repdate, 'weekly', @errCount output
	----процедура проверки номенклатурных групп по Самозанятым
	--exec [finAnalytics].[loadPBR_zamozanyatCheck] @repdate, 'weekly'
	
	declare @errorSaleDate int = 0
	-- процедура проверки Даты выдачи
    exec [finAnalytics].[loadPBR_saleDateCheck] @repdate, 'weekly', @errorSaleDate output
    if @errorSaleDate = 1 throw 51000 , 'Ошибка проверки поля Дата выдачи', 1

	-- процедура проверки ПСК для РВПЗ
	declare @errorPSK int = 0
	exec [finAnalytics].[loadPBR_PSKCheck] @repdate, 'weekly', @errorPSK output
	--if @errorPSK = 1 throw 51000 , 'Ошибка проверки ПСК для РВПЗ', 1

	
    declare @emailList varchar(255)=''
	
    exec finAnalytics.loadPBRweekly_doubleCheck @repdate

    delete from [finAnalytics].PBR_WEEKLY where (REPDATE=@repdate or repdate < DATEADD(day, -90, cast(getdate() as date)))

  begin tran  
    
    INSERT INTO [finAnalytics].PBR_WEEKLY
	(
	 REPDATE, [Client], [isZaemshik], [isBankrupt], isDosieBankrupt, [isMSP], [passport], [birthday], 
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
	 [isProlongPDL], [isProlongPDLDate], [dataLoadDate], PSK_prc, prosFrozenDays, isStopCredKanik, isStopCredKanikDate, KKEndMaxCHPD, KKEndMaxCHPDDate
	 ,KKEvac, KKEvacDate, KKEvacStop, KKEvacStopDate, KKEvacCancel, KKEvacCancelDate, KK353, KK353Date, KK353Stop, KK353StopDate, KK353Cancel, KK353CancelDate,
	 [isNotTarget], [salesRegion]
	 )
     
    select
        [repdate] ,[Client] ,[isZaemshik] ,[isBankrupt] ,[isDisieBanrupt] ,[isMSP] ,[passport] ,[birthday]
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
		,[isNotTarget], [salesRegion]
    from (
	SELECT -- top 10
        [repdate] = @repdate
		,[Client] = [Контрагент]
		--,[isZaemshik] = [Признак заемщика] 
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
		,[dogNum] = a.[Номер договора] 
		,[dogDate] = CONVERT (date, [Дата договора], 104) 
		,[saleDate] = CONVERT (date, a.[Дата выдачи], 104) 
		,[saleType] = [Способ выдачи займа] 
		,[isCessia] = [Цессия (проданные займы)] 
		,[pogashenieDate] = CONVERT (date, [Дата погашения], 104) 
		,[pogashenieDateDS] = CONVERT (date, [Дата погашения с учетом ДС], 104) 
		,[KKEndDate] = CONVERT (date, [Дата окончания по КК], 104) 
		,[dogPeriodMonth] = [Срок договора в месяцах]--cast([Срок договора в месяцах] as float) 
		,[dogPeriodDays] = [Срок договора в днях]--cast([Срок договора в днях] as float) 
        ,[dogSum] = [Сумма займа]--convert(money,[Сумма займа]) 
		,[isDogPoruch] = [Наличие залога поручительства] 
		,[dogZalogNum] = [Номер договора залога] 
		,[dogZalogDate] = CONVERT (date, [Дата договора залога], 104) 
		,[TsVin] = [Транспортное средство vin] 
		,[dogVin] = [Vin в договоре] 
		,[isDocred ] = [Докредитование] 
        ,[zalogSum ] = [Залоговая стоимость]--convert(money,[Залоговая стоимость])
		,[zalogSumRaspred] = [Залоговая стоимость распределение]--convert(money,[Залоговая стоимость распределение])
		,[spravedSum ] = [Справедливая стоимость]--convert(money,[Справедливая стоимость])
		,[spravedSumRaspred] = [Справедливая стоимость распределенная по vin]--convert(money,[Справедливая стоимость распределенная по vin])
		,[spravedSumProverObespech] = [Справедливая стоимость проверка обеспеченности]--convert(money,[Справедливая стоимость проверка обеспеченности])
		,[PDNOnSaleDate] = [ПДН на дату выдачи (НЕ для ЦБ)]--cast([ПДН на дату выдачи] as float)
		--,[PDNOnSaleDate] = case when [ПДН на дату выдачи (НЕ для ЦБ)] = 'NULL' then NULL else CAST([ПДН на дату выдачи (НЕ для ЦБ)] as float) end--cast([ПДН на дату выдачи] as float)
		,[monthIncom] = [Среднемесячный доход]--convert(money,[Среднемесячный доход])
		,[primeSum] = [Первичная сумма]--convert(money,[Первичная сумма])
		,[isRefinance] = [Рефинансирование] 
		,[isRestruk] = [Реструктуризирован] 
		,[restrukNum] = [Реструктуризирован номер]
		,[restrukDate] = CONVERT (date, [Реструктуризирован дата], 104) 
		,[restrukDateEnd] = CONVERT (date, [Реструктуризирован дата окончания], 104) 
		,[restrukPeriod] = [Реструктуризирован срок]--cast([Реструктуризирован срок] as float)
		,[firsProsDate] = CONVERT (date, [Дата первой просрочки], 104) 
		,[zadolgOD] = [Задолженность ОД]--convert(money,[Задолженность ОД])
		,[zadolgPrc] = [Задолженность проценты]--convert(money,[Задолженность проценты])
		,[penyaSum] = [Сумма пени счета]--convert(money,[Сумма пени счета])
		,[gosposhlSum] = [Сумма госпошлин счета]--convert(money,[Сумма госпошлин счета])
		,[prosODSum] = [Сумма просрочки основной долг]--convert(money,[Сумма просрочки основной долг])
		,[prosPRCSum] = [Сумма просрочки проценты]--convert(money,[Сумма просрочки проценты])
		,[prosDays] = [Дней просрочки]--cast([Дней просрочки] as float)
		,[prosHist] = [Историческая просрочка]--cast([Историческая просрочка] as float)
		,[prosDaysTotal] = [Итого дней просрочки общая]--cast([Итого дней просрочки общая] as float)
		,[prosMax] = [Максимальный срок просрочки по одному заемщику]--cast([Максимальный срок просрочки по одному заемщику] as float)
		,[reservODPRC] = [Процент резерва ОД]--cast([Процент резерва ОД] as float)
		,[reservOD] = [Резерв ОД]--convert(money,[Резерв ОД])
		,[reservPRCPrc] = [Процент резерва проценты]--convert(money,[Процент резерва проценты])
		,[reservPRC] = [Резерв проценты]--convert(money,[Резерв проценты])
		,[dogStatus] = [Состояние] 
		,[prosDaysNU] = [Дней просрочки1] --cast([Дней просрочки1] as float)
		,[reservPrcODNU] = [Процент резерва ОД1]--convert(money,[Процент резерва ОД1])
		,[reservPRCprcNU] = [Процент резерва проценты1]--convert(money,[Процент резерва проценты1])
		,[reservProchSumNU] = [Сумма резерв прочие НУ]--convert(money,[Сумма резерв прочие НУ])
		,[reservBUODSum] =  [Сумма резерва БУ ОД]--convert(money,[Сумма резерва БУ ОД])
		,[reservBUpPrcSum] = [Сумма резерва БУ проценты]--convert(money,[Сумма резерва БУ проценты])
		,[reservBUPenyaSum] = [Сумма резерва БУ пени и госпошлины]--convert(money,[Сумма резерва БУ пени и госпошлины])
		,[DSType] = [Вид ДС]
		,[stavaOnSaleDate] =  [Ставка на дату выдачи]--cast([Ставка на дату выдачи] as float)
		,[stavaOnRepDate] = [Ставка на дату формирования отчета]--cast([Ставка на дату формирования отчета] as float)
		,[PSK] = [ПСК]--cast([ПСК] as float)
		,[PSKFirst] = [ПСК первоначальная]--cast([ПСК первоначальная] as float)
		,[isObespechZaym] = [Обеспеченный займ] 
		,[PDNOnRepDate] = [ПДН на отчетную дату]--cast([ПДН на отчетную дату] as float)
		--,[PDNOnRepDate] = case when [ПДН на отчетную дату] = 'NULL' then NULL else CAST([ПДН на отчетную дату] as float) end--cast([ПДН на отчетную дату] as float)
		,[isPros] = [Наличие просрочки] 
		,[AccODNum] = [Счет учета основного долга] 
		,[AccPrcNum] = [Счет учета начисления процентов]
		,[AccObespechNum] = [Счет учета обеспечения] 
		,[branch] = [Подразделение организации] 
		,[branchAddress] = [Адрес подразделения] 
		,[ClientID] = [Контрагент код] 
		,[INN] = case when a.[ИНН] is null then cl.inn else a.[ИНН] end 
		,[prosDaysLastYear] = [Дней просрочки за последний год]--cast([Дней просрочки за последний год] as float)
		,[CloseDate] = CONVERT (date, [Дата закрыт], 104) 
		,[nomenkGroup] = --[Номенклатурная группа] 
								/*case when upper(sam.подТипКредитногоПродукта) like upper('%самозанят%') 
								and a.[Номенклатурная группа]  != sam.подТипКредитногоПродукта 
								then sam.подТипКредитногоПродукта
								else a.[Номенклатурная группа] 
								end*/
						case when sz.[Номер договора] is not null and upper(a.[Номенклатурная группа]) not like upper('%Самозанят%')
						then 'ПТС Займ для Самозанятых'
						else a.[Номенклатурная группа]
						end								
		,[isAkcia] = [Акция 0%]
		,[ODLastPayDate] = CONVERT (date, [Дата последнего платежа по ОД], 104) 
		,[ODLastPaySum] = [Сумма последнего платежа по ОД]--convert(money,[Сумма последнего платежа по ОД])
		,[sum47422] = [Сумма47422]--convert(money,[Сумма47422])
		,[Acc47422Num] = [Счет аналитического учета47422] 
		,[isOutBalance] = [Забаланс]
		,[LasPay47422Date] = CONVERT (date, [Последний платеж 47422], 104) 
		,[LasPay47422Sum] = [Сумма последнего платежа 47422]--convert(money,[Сумма последнего платежа 47422])
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
		,[prosFrozenDays] = a.[Замороженные дни просрочки]

        ,[dataLoadDate] = a.created
        ,[row_num] = row_number() over (Partition by a.[Номер договора] order by a.[№ п/п])
        ,[PSK_prc] = cast(isnull(a.[ПСК для РВПЗ],0) as float)
		,[isNotTarget] = a.[Использование не по целевому назначению]
		,[salesRegion] = a.[Территория выдачи]

	from stg.[files].[PBR_WEEKLY] a
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
	--left join dwh2.dm.v_ЗаявкаНаЗаймПодПТС_и_СтатусыИСобытия sam on a.[Номер договора]=sam.номерзаявки
	left join stg.[files].[Samozanyat] sz on a.[Номер договора] = sz.[Номер договора]

	--берем только выданные кредиты
	where a.[Дата выдачи] is not null
		and CONVERT (date, a.[Дата договора],104) <= @repDate
		and CONVERT (date, a.[Дата выдачи],104) <= @repDate
    ) l1

    where 1=1
    and l1.row_num=1

	/*Обновление данных по МСП*/
    merge into finAnalytics.PBR_weekly t1
    using(
 --   select
 --   a.ID
 --   ,a.REPdate
 --   ,a.saleDate
 --   ,b.reestrInDate
 --   ,b.reestrOutDate
 --   ,a.dogNum
 --   ,a.Client
 --   ,a.isMSP
 --   ,isMSPbyDogDate = case when EOMONTH(a.saleDate) between b.reestrInDate and isnull(b.reestrOutDate,cast(getdate() as date)) then 'Да' else 'Нет' end
 --   ,isMSPbyRepDate = case when EOMONTH(a.repdate) between b.reestrInDate and isnull(b.reestrOutDate,cast(getdate() as date)) then 'Да' else 'Нет' end
 --   from finAnalytics.PBR_weekly a
 --   --inner join finAnalytics.MSP_reestr b on a.INN=b.INN
	--inner join finAnalytics.MSP_reestr b on 
	--											a.INN=b.INN 
	--											and upper(a.isZaemshik) != 'ФЛ'
	--											and EOMONTH(a.repdate) between b.reestrInDate and isnull(b.reestrOutDate,EOMONTH(a.repdate))
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

	merge into finAnalytics.PBR_WEEKLY t1
	using
	(
	select 
	external_id
	,psk_int
	from #stg_psk
	) t2 on (t1.dogNum=t2.external_id and t1.repdate=@repdate)

	when matched then update
	set t1.PSK_prc = t2.psk_int;
	*/
	commit tran

	--Расчет дополнительных столбцов
	exec [finAnalytics].[loadPBR_addMoreData] 'weekly', @repdate

    exec finAnalytics.calcPDNrepData_Weekly @repmonth, @repdate
    
    
    
    --order by l2.[Отчетная дата]
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repdate) from finAnalytics.PBR_WEEKLY) as varchar)
    

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - Загрузка ПБР за '
                ,FORMAT( @repdate, 'MMMM yyyy', 'ru-RU' )
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
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,31))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
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
			,@copy_recipients =''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch
END
