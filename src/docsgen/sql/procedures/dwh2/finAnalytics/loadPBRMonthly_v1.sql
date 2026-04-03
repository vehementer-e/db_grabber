

CREATE   PROCEDURE [finAnalytics].[loadPBRMonthly_v1] 
    
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,@sp_name
				)
       
    begin try

    declare @repmonthtemp date = (select max(CONVERT (date, [Отчетная дата], 104)) from stg.[files].[PBR_MONTHLY])
    declare @repmonth date = DATEFROMPARTS(DATEPART(year,@repmonthtemp),datepart(month,@repmonthtemp),1)
    --select @repmonth

    -----Проверка на актуальную дату в реестре остатков 60323
    declare @rests60323Date date = (select max(repmonth) from finAnalytics.rests60323)
    --select @rests60323Date
    if (@rests60323Date < @repmonth or @rests60323Date is null)
    begin
        declare @body_text2 nvarchar(MAX) = CONCAT(
                                                    'В реестре остатков 60323 максимальная дата: '
                                                    , FORMAT( eoMONTH(@rests60323Date), 'MMMM yyyy', 'ru-RU' )
                                                    ,char(10)
                                                    ,char(13)
                                                    ,'При загрузке ПБР не будут учтены корректировки даты выхода на просрочку.'
                                                    ,char(10)
                                                    ,char(13)
                                                    ,'Для корректной загрузки необходимо актуальный реестр выложить в сетевую папку и перевыгрузить ПБР.'
                                                    )
        declare @subject2  nvarchar(200)  = CONCAT('Нет данных в реестре остатков 60323 на дату загрузки ПБР: ',FORMAT( eoMONTH(@REPMONTH), 'MMMM yyyy', 'ru-RU' ))
        EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'd.detkin@smarthorizon.ru;a.hasanshin@smarthorizon.ru;s.bagmet@carmoney.ru;o.agaeva@carmoney.ru'
			,@copy_recipients = ''--'dwh112@carmoney.ru'
			,@body = @body_text2
			,@body_format = 'TEXT'
			,@subject = @subject2;
     
     

     end

	 -----Проверка на нулевой ПДН
	 declare @isNullPDN1 varchar(max) = null
	 declare @isNullPDN2 varchar(max) = null
    
	set @isNullPDN1 = (
	select
	dogs = isnull(STRING_AGG([Номер договора],'; '),'-')
	from stg.[files].[PBR_MONTHLY] a
	where [Признак заемщика] = 'ФЛ'
	and convert(date,[Дата выдачи],104) between @repmonth and EOMONTH(@repmonth)
	and 
	(
		--cast([ПДН на дату выдачи (НЕ для ЦБ)]as float) = 0 
		[ПДН на дату выдачи (НЕ для ЦБ)] = 0 
		or
		[ПДН на дату выдачи (НЕ для ЦБ)] is null
	))
	set @isNullPDN2 = (
	select
	dogs = isnull(STRING_AGG([Номер договора],'; '),'-')
	from stg.[files].[PBR_MONTHLY] a
	where [Признак заемщика] = 'ФЛ'
	and convert(date,[Дата выдачи],104) between @repmonth and EOMONTH(@repmonth)
	and 
	(
		--cast([ПДН на отчетную дату]as float) = 0 
		[ПДН на отчетную дату] = 0 
		or
		[ПДН на отчетную дату] is null
	))

    if (@isNullPDN1 != '-' or @isNullPDN2 != '-')
    begin
        declare @body_text3 nvarchar(MAX) = CONCAT(
                                                    'В ПБР найдены договора ФЛ с датой выдачи в отчетном месяце с нулевым ПДН: '
                                                    ,'Отчетный месяц: '
													,FORMAT( @repmonth, 'MMMM yyyy', 'ru-RU' )
                                                    ,char(10)
                                                    ,char(13)
                                                    ,'ПДН на дату выдачи (НЕ для ЦБ): '
													,@isNullPDN1
                                                    ,char(10)
                                                    ,char(13)
                                                    ,'ПДН на отчетную дату: '
													,@isNullPDN2
													,char(10)
                                                    ,char(13)
													,'Загрузка не остановлена.'
                                                    )
        declare @subject3  nvarchar(200)  = CONCAT('В ПБР найдены новые договора ФЛ с нулевым ПДН за ',FORMAT( eoMONTH(@REPMONTH), 'MMMM yyyy', 'ru-RU' ))
        EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'd.detkin@smarthorizon.ru;a.hasanshin@smarthorizon.ru;olv.burlakova@carmoney.ru;n.moskvicheva@smarthorizon.ru'
			,@copy_recipients = ''--'dwh112@carmoney.ru'
			,@body = @body_text3
			,@body_format = 'TEXT'
			,@subject = @subject3;
     
     

     end

     exec finAnalytics.loadPBRMonthly_doubleCheck @repmonth

    delete from [finAnalytics].PBR_MONTHLY	where REPMONTH=@repmonth

  begin tran  
    
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
	 KKEvac, KKEvacDate, KKEvacStop, KKEvacStopDate, KKEvacCancel, KKEvacCancelDate, KK353, KK353Date, KK353Stop, KK353StopDate, KK353Cancel, KK353CancelDate
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
    from (
	SELECT 
        [repmonth] = @repmonth
		,[Client] = [Контрагент]
		,[isZaemshik] = [Признак заемщика] 
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
		,[PDNOnSaleDate] = [ПДН на дату выдачи (НЕ для ЦБ)]--[ПДН на дату выдачи]--cast([ПДН на дату выдачи] as float)
		--,[PDNOnSaleDate] = case when [ПДН на дату выдачи (НЕ для ЦБ)] = 'NULL' then NULL else CAST([ПДН на дату выдачи (НЕ для ЦБ)] as float) end--cast([ПДН на дату выдачи] as float)
		,[monthIncom] = [Среднемесячный доход]--convert(money,[Среднемесячный доход])
		,[primeSum] = [Первичная сумма]--convert(money,[Первичная сумма])
		,[isRefinance] = [Рефинансирование] 
		,[isRestruk] = [Реструктуризирован] 
		,[restrukNum] = [Реструктуризирован номер]
		,[restrukDate] = CONVERT (date, [Реструктуризирован дата], 104) 
		,[restrukDateEnd] = CONVERT (date, [Реструктуризирован дата окончания], 104) 
		,[restrukPeriod] = [Реструктуризирован срок]--cast([Реструктуризирован срок] as float)
		,[firsProsDate] = case when cast([Задолженность ОД] as money)=0 and cast([Задолженность проценты] as money)=0 and cast([Сумма пени счета] as money)=0 and cast([Сумма госпошлин счета] as money)!=0 then r60323.prosDateBegin
                          else CONVERT (date, [Дата первой просрочки], 104) end
		,[zadolgOD] = [Задолженность ОД]--convert(money,[Задолженность ОД])
		,[zadolgPrc] = [Задолженность проценты]--convert(money,[Задолженность проценты])
		,[penyaSum] = [Сумма пени счета]--convert(money,[Сумма пени счета])
		,[gosposhlSum] = [Сумма госпошлин счета]--convert(money,[Сумма госпошлин счета])
		,[prosODSum] = [Сумма просрочки основной долг]--convert(money,[Сумма просрочки основной долг])
		,[prosPRCSum] = [Сумма просрочки проценты]--convert(money,[Сумма просрочки проценты])
		,[prosDays] = [Дней просрочки]--cast([Дней просрочки] as float)
		,[prosHist] = [Историческая просрочка]--cast([Историческая просрочка] as float)
		,[prosDaysTotal] = case when cast([Задолженность ОД] as money)=0 and cast([Задолженность проценты] as money)=0 and cast([Сумма пени счета] as money)=0 and cast([Сумма госпошлин счета] as money)!=0 and [Итого дней просрочки общая]=0 
                                then abs(DATEDIFF(day,EOMONTH(@repmonth),r60323.prosDateBegin))
                                else [Итого дней просрочки общая] end
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
		,[nomenkGroup] = [Номенклатурная группа]
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

		,[dataLoadDate] = created
        ,[row_num] = row_number() over (Partition by a.[Номер договора] order by a.[№ п/п])
        ,[PSK_prc] = a.[ПСК для РВПЗ]
		
		,[prosFrozenDays] = a.[Замороженные дни просрочки]
		
	from stg.[files].[PBR_MONTHLY] a
    left join (
        select --top 1

        [Дата] = cast(dateadd(year,-2000,a.Дата) as date)
        ,[Заемщик] = b.Наименование
        ---Признак исключения для проброски в ПБР
        ,[Исключить] = case when a.Номер in ('00БП-0266','00БП-0302','00БП-0496','00БП-0637','00БП-0733') then 1 else 0 end
        ---Считаем дубли и берем максимальное по дате в кореляции с отчетной датой
        ,ROW_NUMBER() over (Partition by b.Наименование order by a.Дата desc) rn

        from stg._1cUMFO.Документ_АЭ_БанкротствоЗаемщика a
        left join stg._1cUMFO.Справочник_Контрагенты b on a.Контрагент=b.Ссылка
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
    ) l1

    where 1=1
    and l1.row_num=1

    merge into finAnalytics.PBR_MONTHLY t1
    using(
    select
    a.ID
    ,a.REPMONTH
    ,a.saleDate
    ,b.reestrInDate
    ,b.reestrOutDate
    ,a.dogNum
    ,a.Client
    ,a.isMSP
    ,isMSPbyDogDate = case when EOMONTH(a.saleDate) between b.reestrInDate and isnull(b.reestrOutDate,EOMONTH(a.repmonth)/*cast(getdate() as date)*/) then 'Да' else 'Нет' end
    ,isMSPbyRepDate = case when EOMONTH(a.repmonth) between b.reestrInDate and isnull(b.reestrOutDate,EOMONTH(a.repmonth)/*cast(getdate() as date)*/) then 'Да' else 'Нет' end
    from finAnalytics.PBR_MONTHLY a
    inner join finAnalytics.MSP_reestr b on a.INN=b.INN
    ) t2 on (t1.id=t2.id)
    when matched then update
    set
    t1.isMSPbyDogDate=t2.isMSPbyDogDate,
    t1.isMSPbyRepDate=t2.isMSPbyRepDate;

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
    
    --Запуск процедуры расчета данных для отчета Андрея по ПДН
    exec finAnalytics.calcPDNrepData_Monthly @repmonth, @repmonthtemp
    --Запуск процедуры расчета данных для отчета Леры по Резервам
    exec finAnalytics.loadRepReservData @repmonth
	
    
    commit tran
    
    --order by l2.[Отчетная дата]
    DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRest NVARCHAR(30)
    set @maxDateRest = cast((select max(repmonth) from finAnalytics.PBR_MONTHLY ) as varchar)
    

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

    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'd.detkin@smarthorizon.ru;a.hasanshin@smarthorizon.ru'
			,@copy_recipients = ''--'dwh112@carmoney.ru'
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;


    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = 'd.detkin@smarthorizon.ru;a.hasanshin@smarthorizon.ru'
			,@copy_recipients =''-- 'dwh112@carmoney.ru'
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch
END
