

CREATE PROCEDURE [finAnalytics].[PBR_shortVers]

	@rep_month date,
    @REP_DATE date

AS
BEGIN

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dwh2.[finAnalytics].#ID_LIST') AND type in (N'U'))
DROP TABLE dwh2.[finAnalytics].#ID_LIST

Create table dwh2.[finAnalytics].#ID_LIST(
    [ID] bigint NOT NULL
    )

insert into dwh2.[finAnalytics].#ID_LIST
select
a.ID
from dwh2.finAnalytics.PBR_MONTHLY a
where a.REPMONTH=@REP_MONTH --and a.REPDATE=@REP_DATE

/* select * from #ID_LIST */
-------------------------------------------------------------------

SELECT 

        [П/н] = ROW_NUMBER() over (order by client) 
        ,[Отчетный месяц] = REPMONTH 
        ,[Дата выгрузки] = cast(REPDATE as date)
        --,[Отчетный месяц2] = [CALMON]
    	,[Контрагент] = [Client]
	    ,[Признак заемщика] = [isZaemshik]
	    ,[Банкротство] = [isBankrupt]
	    ,[Досье контрагента (банкрот)] = [isDosieBankrupt]
	    ,[МСП] = [isMSP]
	    ,[Паспортные данные] = [passport] 
	    ,[Дата рождения] = [birthday]
	    ,[Адрес для расчет ПДН] = [addressPDN]
	    ,[Адрес проживания] = [addresFact]
	    ,[Адрес регистрации] = [addressReg]
	    ,[Финансовый продукт] = [finProd]
	    ,[Номер договора] = [dogNum]
	    ,[Дата договора] = [dogDate]
	    ,[Дата выдачи] = [saleDate]
	    ,[Способ выдачи займа] = [saleType]
	    ,[Цессия (проданные займы)] = [isCessia]
	    ,[Дата погашения] = [pogashenieDate]
	    ,[Дата погашения с учетом ДС] = [pogashenieDateDS]
	    ,[Дата окончания по КК] = [KKEndDate]
	    ,[Срок договора в месяцах] = [dogPeriodMonth]
	    ,[Срок договора в днях] = [dogPeriodDays]
	    ,[Сумма займа] = [dogSum]
	    ,[Наличие залога поручительства] = [isDogPoruch]
	    ,[Номер договора залога] = [dogZalogNum]
	    ,[Дата договора залога] = [dogZalogDate]
	    ,[Транспортное средство vin] = [TsVin]
	    ,[Vin в договоре] = [dogVin]
	    ,[Докредитование] = [isDocred]
	    ,[Залоговая стоимость] = [zalogSum]
	    ,[Залоговая стоимость распределение] = [zalogSumRaspred]
	    ,[Справедливая стоимость] = [spravedSum]
	    ,[Справедливая стоимость распределенная по vin] = [spravedSumRaspred]
	    ,[Справедливая стоимость проверка обеспеченности] = [spravedSumProverObespech]
	    ,[ПДН на дату выдачи] = [PDNOnSaleDate]
	    ,[Среднемесячный доход] = [monthIncom]
	    ,[Первичная сумма] = [primeSum]
	    ,[Рефинансирование] = [isRefinance]
	    ,[Реструктуризирован] = [isRestruk]
	    ,[Реструктуризирован номер] = [restrukNum]
	    ,[Реструктуризирован дата] = [restrukDate]
	    ,[Реструктуризирован дата окончания] = [restrukDateEnd]
	    ,[Реструктуризирован срок] = [restrukPeriod]
	    ,[Дата первой просрочки] = [firsProsDate]
	    ,[Задолженность ОД] = [zadolgOD]
	    ,[Задолженность проценты] = [zadolgPrc]
	    ,[Сумма пени счета] = [penyaSum]
	    ,[Сумма госпошлин счета] = [gosposhlSum]
	    ,[Сумма просрочки основной долг] = [prosODSum]
	    ,[Сумма просрочки проценты] = [prosPRCSum]
	    ,[Дней просрочки] = [prosDays]
	    ,[Историческая просрочка] = [prosHist]
	    ,[Итого дней просрочки общая] = [prosDaysTotal]
	    ,[Максимальный срок просрочки по одному заемщику] = [prosMax]
	    ,[Процент резерва ОД] = [reservODPRC]
	    ,[Резерв ОД] = [reservOD]
	    ,[Процент резерва проценты] = [reservPRCPrc]
	    ,[Резерв проценты] = [reservPRC]
	    ,[Состояние] = [dogStatus]
	    ,[Дней просрочки НУ] = [prosDaysNU]
	    ,[Процент резерва ОД НУ] = [reservPrcODNU]
	    ,[Процент резерва проценты НУ] = [reservPRCprcNU]
	    ,[Сумма резерв прочие НУ] = [reservProchSumNU]
	    ,[Сумма резерва БУ ОД] = [reservBUODSum]
	    ,[Сумма резерва БУ проценты] = [reservBUpPrcSum]
	    ,[Сумма резерва БУ пени и госпошлины] = [reservBUPenyaSum]
	    ,[Вид ДС] = [DSType]
	    ,[Ставка на дату выдачи] = [stavaOnSaleDate]
	    ,[Ставка на дату формирования отчета] = [stavaOnRepDate]
	    ,[ПСК] = [PSK]
	    ,[ПСК первоначальная] = [PSKFirst]
	    ,[Обеспеченный займ] = [isObespechZaym]
	    ,[ПДН на отчетную дату] = [PDNOnRepDate]
	    ,[Наличие просрочки] = [isPros]
	    ,[Счет учета основного долга] = [AccODNum]
	    ,[Счет учета начисления процентов] = [AccPrcNum]
	    ,[Счет учета обеспечения] = [AccObespechNum]
	    ,[Подразделение организации] = [branch]
	    ,[Адрес подразделения] = [branchAddress]
	    ,[Контрагент код] = [ClientID]
	    ,[ИНН] = [INN]
	    ,[Дней просрочки за последний год] = [prosDaysLastYear]
	    ,[Дата закрыт] = [CloseDate]
	    ,[Номенклатурная группа] = [nomenkGroup]
	    ,[Акция 0%] = [isAkcia]
	    ,[Дата последнего платежа по ОД] = [ODLastPayDate]
	    ,[Сумма последнего платежа по ОД] = [ODLastPaySum]
	    ,[Сумма47422] = [sum47422]
	    ,[Счет аналитического учета47422] = [Acc47422Num]
	    ,[Забаланс] = [isOutBalance]
	    ,[Последний платеж 47422] = [LasPay47422Date]
	    ,[Сумма последнего платежа 47422] = [LasPay47422Sum]
	    ,[Лицевой счет учета пени] = [AccPenyaNum]
	    ,[Дата последней проводки дт] = [LastProvDTDate]
	    ,[Дата последней проводки кт] = [LastProvKTDate]
	    ,[Дата погашения требований] = [trebPogashDate]
	    ,[Способ закрытия обязательств] = [zakritObazType]
	    ,[Кредитор] = [creditor]
	    ,[Договор с кредитором] = [creditorDogNum]
	    ,[Маркирован] = [IsMarked]
	    ,[Дата входа в залог] = [ZalogInDate]
	    ,[Дата выхода из залога] = [ZalogOutDate]
	    ,[Заморозка (для резервов 30.06.21)] = [isZamoroz1]
	    ,[Дата ДС1] = [isZamoroz1Date]
	    ,[Заморозка 1.0] = [isZamoroz2]
	    ,[Дата ДС2] = [isZamoroz2Date]
	    ,[Изм.ставки, пополнение ОД] = [isStavkaChange]
	    ,[Дата ДС3] = [isStavkaChangeDate]
	    ,[Кредитные каникулы] = [isCredKanik]
	    ,[Дата ДС4] = [isCredKanikDate]
	    ,[Отмена Реструктуризации] = [isCancelRestruk]
	    ,[Дата ДС5] = [isCancelRestrukDate]
	    ,[Пролонгация] = [isProlong]
	    ,[Дата ДС6] = [isProlongDate]
	    ,[Реструктуризация] = [isResrukt]
	    ,[Дата ДС7] = [isResruktDate]
	    ,[Реструктуризация (перенос даты)] = [isResrukt2]
	    ,[Дата ДС8] = [isResrukt2Date]
	    ,[Рефинансирование1] = [isRefinance2]
	    ,[Дата ДС9] = [isRefinance2Date]
	    ,[Снижение ставки (реструктуризация)] = [isSnigStavka]
	    ,[Дата ДС10] = [isSnigStavkaDate]
	    ,[Кредитные каникулы по 377-ФЗ] = [isCredKanik2]
	    ,[Дата ДС11] = [isCredKanik2Date]
	    ,[Отмена Кредитных каникул по 377-ФЗ] = [isCancleCredKanik]
	    ,[Дата ДС12] = [isCancleCredKanikDate]
	    ,[Пролонгация PDL] = [isProlongPDL]
	    ,[Дата ДС13] = [isProlongPDLDate]
        ,[Признак МСП по дате выдачи] = t1.isMSPbyDogDate
        ,[Признак МСП по дате отчета] = t1.isMSPbyRepDate

  FROM dwh2.[finAnalytics].[PBR_MONTHLY] t1
  inner join #ID_LIST as t2 on t1.ID=t2.id
  
END
