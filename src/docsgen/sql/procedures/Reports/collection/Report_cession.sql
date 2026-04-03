/*
EXEC collection.Report_cession_NEW 
	@report_type = 'common', 
	@deal_type = 'judicial_claims', 
	@persent = 21.75,
	@isFull = 1,
	@isDebug = 1 
WITH RECOMPILE

EXEC collection.Report_cession_NEW 
	@report_type = 'detail', 
	@deal_type = 'judicial_claims', 
	@persent = 21.75,
	@isFull = 1,
	@isDebug = 1 
WITH RECOMPILE

EXEC collection.Report_cession_NEW
	@report_type = 'detail', 
	@deal_type = 'without_claims', 
	@persent = 21.75,
	@isFull = 1,
	@isDebug = 1 

EXEC collection.Report_cession_NEW
	@report_type = 'common', 
	@deal_type = 'without_claims', 
	@persent = 21.75,
	@isFull = 1,
	@isDebug = 1 
*/
CREATE PROC collection.Report_cession
	@report_type varchar(100) = 'common',
	--common - Выгрузка для площадки, detail - Расширенный реестр

	@deal_type varchar(100) = 'without_claims', 
	-- without_claims - Договора без судебных исков, judicial_claims - Договора с судебными исками

	@persent smallmoney = 21.75,
	@isFull int = 0, -- 1-выгрузить всё, 0 - кроме тех, у которых [Есть причина исключения]
	@isDebug int = 0 
as
begin
declare @dt date 
	if cast(getdate() as date) = '2025-11-19'
		set @dt = '2025-11-17'
	else
		set  @dt = getdate()

set @persent = @persent / 100

SELECT @isDebug = isnull(@isDebug, 0)
--SELECT @report_type = isnull(@report_type, 'common')
SELECT @deal_type = isnull(@deal_type, 'without_claims') 
SELECT @report_type = replace(@report_type, '''', ''), @deal_type = replace(@deal_type, '''', '')

SELECT @isFull = isnull(@isFull, 0)


drop table if exists #Reasons2StoppingAccruals
select 
	дсд.ДоговорЗайма,
	external_id = д.КодДоговораЗайма,
	Период = dateadd(year, -2000, Период),
	ПричиныОстановкиНачислений = пон.Наименование
into #Reasons2StoppingAccruals
from dwh2.dm.ДоговорЗайма as д
	inner join stg._1cCMR.РегистрСведений_ДополнительныеСвойстваДоговоров as дсд
		on дсд.ДоговорЗайма = д.СсылкаДоговораЗайма
		and дсд.Значение_ТипСсылки = 0x000019FD
	inner join stg._1cCMR.Справочник_ПричиныОстановкиНачислений as пон
		on пон.Ссылка = дсд.Значение_Ссылка


	
IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##Reasons2StoppingAccruals
	SELECT * INTO ##Reasons2StoppingAccruals FROM #Reasons2StoppingAccruals AS T
END

 drop table if exists #CustomerContact
;with cte as (
select cc.IdCustomer, cc.Phone, ContactTypeName = ct.Name from stg.[_Collection].[CustomerContact] cc
inner join  stg.[_Collection].[ContactType] ct on ct.Id = cc.IdContactType
where ContactPersonType = 1
and ct.name in (
'Телефон домашний'
,'Телефон дополнительный'
,'Телефон рабочий'
,'Телефон мобильный')
)
select IdCustomer
	,[Телефон домашний] = min([Телефон домашний])
	,[Телефон дополнительный]  = min([Телефон дополнительный])
	,[Телефон рабочий] = min ([Телефон рабочий])
	,[Телефон мобильный] = min([Телефон мобильный])
into #CustomerContact
from cte
pivot (min(Phone)  for ContactTypeName in ([Телефон домашний]
	, [Телефон дополнительный]
	, [Телефон рабочий]
	, [Телефон мобильный]
	)) pvt
group by IdCustomer
	
IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##CustomerContact
	SELECT * INTO ##CustomerContact FROM #CustomerContact AS T
END


 drop table if exists #isk_sp_space
	SELECT   
			Deal.Number AS external_id
			-- СП
			, jc.CourtClaimSendingDate 'Дата отправки иска в суд'
			, jc.ReceiptOfJudgmentDate 'Дата решения суда' 
			--, jc.ResultOfCourtsDecision 'Решение суда'
			--, jc.AmountJudgment 'Сумма по решению суда' 

			--88 Способ обращения в суд (иск/приказ) - JudicialClaims.FeedWay 1-исковое, 2-приказное
			, jc.FeedWay

			--89 Наличие решения суда о взыскании задолженности (1-да, 0-нет)
			--Комментарий: вкладка СП, при условии заполнения поля - 1, если не заполнено - 0
			--JudicialClaims.JudgmentDate
			, jc.JudgmentDate

			--91 Дата вступления в законную силу решения суда (ДД.ММ.ГГГГ)
			--JudicialClaims.JudgmentEntryIntoForceDate
			, jc.JudgmentEntryIntoForceDate

			--93 Отмена судебного решения (1-да/ 0-нет)
			--Комментарий: 1 - в случае если значение данного поля = "отмена судебного приказа", "0" в случае иных значений данного поля
			--JudicialClaims.MonitoringResult Отмена судебного приказа = 5
			, jc.MonitoringResult

			--94 Сумма долга, признанная судом (руб.)
			--JudicialClaims.AmountJudgment
			, jc.AmountJudgment

			--97 Флаг наличия адреса суда, включая индекс (1-да/0-нет)
			--Комментарий: поле заполнено "1", не заполнено "0"
			--JudicialProceeding.CourtId - указан ли суд в требовании. 
			--данные по судам - таблица Courts, адрес в колонке FullAddress. 
			--данные получаем от внешнего поставщика, отдельно индекс не хранится
			, jp.CourtId

			--98 Дата возбуждения исполн пр-ва (ДД.ММ.ГГГГ)
			--Комментарий: вкладка “ИП”
			--EnforcementProceedingExcitation.ExcitationDate
			, epe.ExcitationDate

			--99 Дата постановления об окончании ИП (ДД.ММ.ГГГГ)
			--Дата окончания ИП? EnforcementProceedingExcitation.EndDate
			, epe.EndDate

			--Причина окончания - EnforcementProceedingExcitation.BasisEndEnforcementProceeding
			--, epe.BasisEndEnforcementProceeding

			--111 [Кадастровый номер залога / VIN автомобиля]
			--VIN автомобиля - приходит из сторонних систем, записывается в таблицу PledgeItem, колонка Vin
			, pl.VIN
			--
			,jc.NumberCasesInCourt -- Номер дела
			,CourtName = cr.Name -- Наименование суда
			,epe.CaseNumberInFSSP -- Номер исполнительного производства
			,epe.BasisEndEnforcementProceeding --Причина окончания ИП
	into #isk_sp_space
	FROM            Stg._Collection.Deals AS Deal 
		inner join stg._Collection.customers c on c.Id = Deal.IdCustomer
		LEFT JOIN Stg._Collection.JudicialProceeding AS jp ON jp.DealId  = Deal.Id
		LEFT JOIN Stg._Collection.JudicialClaims AS jc ON jc.JudicialProceedingId  = jp.Id

		LEFT JOIN Stg._Collection.EnforcementOrders AS eo ON jc.Id = eo.JudicialClaimId
		LEFT JOIN Stg._Collection.EnforcementProceeding AS ep ON eo.Id = ep.EnforcementOrderId
		LEFT JOIN Stg._Collection.EnforcementProceedingExcitation AS epe on ep.id = epe.EnforcementProceedingId

		LEFT JOIN Stg._Collection.DealPledgeItem AS dpi ON dpi.DealId = Deal.Id 
		LEFT JOIN Stg._Collection.PledgeItem AS pl ON pl.Id = dpi.PledgeItemId 

		LEFT JOIN Stg._Collection.Courts AS cr ON cr.Id = jp.CourtId
	where ( jc.CourtClaimSendingDate is not null
			or  ReceiptOfJudgmentDate is not null
		--isnull(jc.CourtClaimSendingDate, jc.ReceiptOfJudgmentDate)  is not null
		--or 
		--ISNULL(c.ClaimantExecutiveProceedingId, c.ClaimantLegalId) is not null
		)
		
IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##isk_sp_space
	SELECT * INTO ##isk_sp_space FROM #isk_sp_space AS T
END


declare @t table(external_id nvarchar(255))

drop table if exists #tresult

drop table if exists #groupedCustomerStatuses

select 
	Collection_CustomerId 
	, d.Number
      , [Клиент в больнице (230-ФЗ)]				= SIGN(sum(case when customer_status in ('Клиент в больнице (230-ФЗ)')                                              then 1 else 0           end))
      , [Инвалид 1 группы (230 ФЗ]                  = SIGN(sum(case when customer_status in ('Инвалид 1 группы (230 ФЗ)')                                               then 1 else 0           end))
      , [Смерть подтвержденная]                     = SIGN(sum(case when customer_status in ('Смерть подтвержденная')                                                   then 1 else 0           end))
      , [Смерть неподтвержденная]                   = SIGN(sum(case when customer_status in ('Смерть неподтвержденная')                                                 then 1 else 0           end))
      , [Банкрот подтверждённый]                    = SIGN(sum(case when customer_status in ('Банкрот подтверждённый')                                             then 1 else 0           end))
      , [Банкрот неподтверждённый]                  = SIGN(sum(case when customer_status in ('Банкрот неподтверждённый')                                           then 1 else 0           end))
      , [Отказ от взаимодействия по 230 ФЗ]         = SIGN(SUM(case when customer_status in ('Отказ от взаимодействия по 230 ФЗ')                                       then 1 else 0           end))
      , [Отказ от взаимодействия с 3-ми лицами (230-ФЗ)]    = SIGN(SUM(case when customer_status in ('Отказ от взаимодействия с 3-ми лицами (230-ФЗ)')                  then 1 else 0           end))
      , [Отзыв согласия о передаче третьим лицам сведений о должнике (230-ФЗ)]     = SIGN(SUM(case when customer_status in ('Отзыв согласия о передаче третьим лицам сведений о должнике (230-ФЗ)')    then 1 else 0           end))
      , [FRAUD]                                  = SIGN(SUM(case when customer_status in ('FRAUD')                                                                   then 1 else 0           end))
      , [Отсутствие согласия на обработку ПД]       = SIGN(SUM(case when customer_status in ('Отсутствие согласия на обработку ПД')                                     then 1 else 0           end))
      , [Отказ от обработки ПД (152-ФЗ)]			= SIGN(SUM(case when customer_status in ('Отказ от обработки ПД (152-ФЗ)')                                          then 1 else 0           end))
      , [Взаимодействие через представителя (230-ФЗ)]         = SIGN(SUM(case when customer_status in ('Взаимодействие через представителя (230-ФЗ)')                             then 1 else 0           end))
      , [Алкоголик/наркоман/игроман]                = SIGN(SUM(case when customer_status in ('Алкоголик/наркоман/игроман')                                        then 1 else 0           end))
      , [Клиент в тюрьме]                           = SIGN(SUM(case when customer_status in ('Клиент в тюрьме')                                                         then 1 else 0           end))
      , [КА]										= SIGN(SUM(case when customer_status in ('КА')                                                                      then 1 else 0           end))
      , [Fraud неподтвержденный]                    = SIGN(SUM(case when customer_status in ('Fraud неподтвержденный')                                                  then 1 else 0           end))
      , [Fraud подтвержденный]                      = SIGN(SUM(case when customer_status in ('Fraud подтвержденный')                                                    then 1 else 0           end))
      , HardFraud                                   = SIGN(SUM(case when customer_status in ('HardFraud')                                                               then 1 else 0           end))
      , [БВ]										= SIGN(SUM(case when customer_status in ('БВ')                                                                      then 1 else 0           end))
	  , [Банкротство завершено]						= SIGN(SUM(case when customer_status in ('Банкротство завершено')                                                 then 1 else 0           end))
	  , [Отзыв согласия на уступку прав (требования)] = SIGN(SUM(case when customer_status in ('Отзыв согласия на уступку прав (требования)')                                                 then 1 else 0           end))
into #groupedCustomerStatuses
from (
	select distinct Collection_CustomerId = cs.CustomerId
		,customer_status = cst.name
		--,customer_status_id = first_value(cst.id) OVER(PARTITION BY cs.CustomerId ORDER BY cst.[Order])
	  from  Stg._Collection.[CustomerStatus] cs 
		   join Stg._Collection.CustomerState cst on cs.CustomerStateId=cst.Id 
	  where cs.IsActive=1  
	) t
	inner join stg._Collection.Deals d 
		on d.IdCustomer = t.Collection_CustomerId

  group by t.Collection_CustomerId, d.Number


	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##groupedCustomerStatuses
		SELECT * INTO ##groupedCustomerStatuses FROM #groupedCustomerStatuses AS T
	END

drop table if exists #t_Дата_написания_заявления_об_отказе_от_взаимодействия

select CustomerId, 
	[Дата написания заявления об отказе от взаимодействия] =Date
into #t_Дата_написания_заявления_об_отказе_от_взаимодействия
from Stg._Collection.[CustomerStatus] cs 
	inner join Stg._Collection.CustomerState cst on cs.CustomerStateId=cst.Id 
where cst.name ='Отказ от взаимодействия по 230 ФЗ'
	and IsActive = 1

DROP TABLE IF EXISTS #cession

SELECT 
	external_id =cast(cast([№ договора] as decimal(20,0)) as nvarchar(20))
	,[Реестр для цессии] = ROW_NUMBER() over(order by getdate())
--from stg.files.cession t
INTO #cession
--select *
from stg.files.cession AS t
where [№ договора] is not null 
and (
	@report_type = 'common'
	OR
	NOT exists(
		select * 
		--select * from stg.files.cession_exclusion t1
		from stg.files.cession_exclusion t1
		where cast( cast(t1.[№ договора] as decimal(21,0)) as nvarchar(21)) = 
			cast( cast(t.[№ договора] as decimal(21,0)) as nvarchar(21))
	)
)

CREATE CLUSTERED INDEX ix1 ON #cession(external_id)

IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##cession
	SELECT * INTO ##cession FROM #cession AS T
END

--select * from @t
select distinct
--Реквизиты реестра	
--[№ п/п]	 = try_cast(t.[Реестр для цессии] as int)--ROW_NUMBER() over(order by  getdate())
--[№ п/п]	 = row_number() over( order by try_cast(t.external_id as bigint))
[№ п/п]	 = cast(null as int)

,[Дата выгрузки реестра (ДД.ММ.ГГГГ)]  = format(@dt, 'dd.MM.yyyy')

--ДЕТАЛИЗАЦИЯ
,[№ договора]								= t.external_id
,[Дата заключения договора]					= format(ДоговорЗайма.ДатаДоговораЗайма,  'dd.MM.yyyy')
,[Сумма выданного займа]					= ДоговорЗайма.СуммаВыдачи
,[Наименование Продукта]					= case OverdueIndicators.ProductType
											when 'Инстоллмент' then 'Installment'
											else OverdueIndicators.ProductType end
,[% ставка в день]							= cast(Balance.ПроцентнаяСтавкаНаТекущийДень / 365.0 as smallmoney) --	5	годовую /365	Толя
,[% ставка в год]							= Balance.ПроцентнаяСтавкаНаТекущийДень		
,[ПСК, %]									= cast(t_ГрафикПлатежей.ПСК as smallmoney) --7	Как рассчитать или откуда взять	Финансы
,[ПСК, руб.]								= cast(t_ГрафикПлатежей.СуммаПСК as money) --8	Как рассчитать или откуда взять	Финансы
,[Срок кредита, днях]						= datediff(dd, ДоговорЗайма.ДатаДоговораЗайма, isnull(OverdueIndicators.FactEndDate, OverdueIndicators.InitialEndDate) )
,[Срок кредита, мес.]						= ДоговорЗайма.Срок
,[Количество дней просрочки на дату цессии]	= Balance.dpd 
,[Дата выхода на просрочку]					= Balance_min_max.[Дата выхода на последнюю непогашенную просрочку]
,[Дата погашения договора]					= format(isnull(OverdueIndicators.FactEndDate, OverdueIndicators.InitialEndDate),'dd.MM.yyyy')
,[Основной долг, руб.]						= Balance.[остаток од]
,[Проценты, руб.]							= Balance.[Остаток % расчетный]
,[Неустойка за пропуск очередного платежа, руб.] = Balance.[остаток пени] --16	Пени	Толя
,[Недоплаченная комиссия, руб.]				= Balance.[остаток иное (комиссии, пошлины и тд)] --	17	Нет комиссии - пишем ноль	
,[Общая сумма задолженности, руб.]			= Balance.[остаток всего]
,[Цена покупки, руб.]						= round(Balance.[остаток всего] * @persent, 2)
,[УИД]										= ДоговорЗайма.УникальныйИдентификаторОбъектаБКИ
,Фамилия									= Клиент.Фамилия
,Имя										= Клиент.Имя
,Отчество									= Клиент.Отчество
,Пол										= Клиент.Пол
,[Дата рождения]							= format(Клиент.ДатаРождения, 'dd.MM.yyyy')
,[Место рождения]							= collection_CustomerPersonalData.BirthPlace
,[Серия паспорта]							= isnull(ПаспортныеДанные.Серия				, collection_CustomerPersonalData.Series			)
,[Номер паспорта]							= isnull(ПаспортныеДанные.Номер				, collection_CustomerPersonalData.Number			)
,[Код подразделения]						= isnull(ПаспортныеДанные.КодПодразделения	, collection_CustomerPersonalData.KpPassport		)
,[Орган выдавший паспорт]					= isnull(ПаспортныеДанные.КемВыдан			, collection_CustomerPersonalData.WhoIssuedPassport )
,[Дата выдачи паспорта]						= isnull(ПаспортныеДанные.ДатаВыдачи		, collection_CustomerPersonalData.PassportIssueDt	)
,[Недействительный Паспорт]					= iif(t_НедействительныеПаспорта.Серия is not null,1, 0)
,[адрес регистрации]						= collection_registration.PermanentRegisteredAddress
,[Индекс адреса регистрации]				= AddressParts_PermanentRegistered.[Почтовый индекс]
,[Область адреса регистрации]				= AddressParts_PermanentRegistered.Регион
,[Район адреса регистрации]					= AddressParts_PermanentRegistered.[Район в регионе]
,[Город / иной населенный пункт адреса регистрации]	=isnull(AddressParts_PermanentRegistered.[Населенный пункт], AddressParts_PermanentRegistered.[Внутригородская территория])
,[Улица адреса регистрации]					= AddressParts_PermanentRegistered.Улица
,[Дом адреса регистрации]					= AddressParts_PermanentRegistered.Дом
,[Корпус адреса регистрации]				= AddressParts_PermanentRegistered.Корпус
,[Квартира адреса регистрации]				= AddressParts_PermanentRegistered.Квартира
,[адрес проживания]							= collection_registration.ActualAddress
,[Индекс фактического проживания]			= AddressParts_ActualAddress.[Почтовый индекс]
,[Область фактического проживания]			= AddressParts_ActualAddress.Регион
,[Район фактического проживания]			= AddressParts_ActualAddress.[Район в регионе]
,[Город / иной населенный пункт фактического проживания]	= isnull(AddressParts_ActualAddress.[Населенный пункт], AddressParts_ActualAddress.[Внутригородская территория])
,[Улица фактического проживания]			= AddressParts_ActualAddress.Улица
,[Дом фактического проживания]				= AddressParts_ActualAddress.Дом
,[Корпус фактического проживания]			= AddressParts_ActualAddress.Корпус
,[Квартира фактического проживания]			= AddressParts_ActualAddress.Квартира
,ИНН										= Клиент_ИНН.ИНН
,СНИЛС										=case 
												when len(cr.snils)=14 then cr.Snils
												when len(replace(trim(collection_CustomerPersonalData.Snils), '-', ''))>9 then trim(collection_CustomerPersonalData.Snils)
												else null
												end COLLATE SQL_Latin1_General_CP1_CI_AS
,[Место работы]								= collection_PlaceOfWork.OrganizationName
,[Мобильный телефон]						= Клиент_Телефон.НомерТелефонаБезКодов		
,[Доп. телефон 1] =	iif(cc.[Телефон домашний]		!=Клиент_Телефон.НомерТелефонаБезКодов, cc.[Телефон домашний]		, null) 	
,[Доп. телефон 2] =	iif(cc.[Телефон дополнительный]	!=Клиент_Телефон.НомерТелефонаБезКодов, cc.[Телефон дополнительный]	, null)
,[Доп. телефон 3] =	iif(cc.[Телефон рабочий]		!=Клиент_Телефон.НомерТелефонаБезКодов, cc.[Телефон рабочий]		, null)
,[Доп. телефон 4] =	iif(cc.[Телефон мобильный]		!=Клиент_Телефон.НомерТелефонаБезКодов, cc.[Телефон мобильный]		, null)
,[Доп. телефон 5] =	null
,[E-mail]									= Клиент_Email.Email
,[Пролонгация договора (да/ нет)]			= iif(dm_res.TotalProlongation>0, 'Да', 'Нет')
,[Реструктуризация договора (да / нет)]		= 'Нет'
,[Номер первоначального договора займа]		= t.external_id

,[Подпись при заключении договора займа (АСП / ручная)] = 'АСП'--	69	АСП	Толя
--Номер телефона для кода СМС	70	Уточнить	Блинчевская
--Код электронной подписи/Код из СМС	71	Уточнить	Блинчевская
--Дата и время направления СМС с кодом	72	Уточнить	Блинчевская

--,[Способ выдачи займа (онлайн / оффлайн)]		= 'Онлайн'--	73	Онлайн	Толя
--,[Способ перечисления]							= 'Безнал'--74	Нал и Безнал	Мирошник
,[Наименование платежной системы / Банка]		= ВыдачаДенежныхСредств.СпособВыдачи --	75	Киви, Яндекс - провайдер кто подтверждает факт выдачи	Мирошник
--Номер карты получателя	76	Уточнить есть ли маскированная карта - 4 цифры со звездочками	Мирошник
,[Номер транзакции / ID перевода]				= ВыдачаДенежныхСредств.ПервичныйДокумент ---/ 	77	Проверить	Толя
,[Дата и время перевода]						= dateadd(year,-2000, ВыдачаДенежныхСредств.ДатаВыдачи) -- 78		
,[Начислено всего Основного долга]				= Balance.[основной долг начислено нарастающим итогом]
,[Начислено всего Процентов]					= Balance.[Проценты начислено  нарастающим итогом]
,[Начислено всего Неустойки / штрафов]			= Balance.[ПениНачислено  нарастающим итогом]
,[Начислено всего Комиссии]						= Balance.[ГосПошлинаНачислено  нарастающим итогом]
,[Начислено всего]								= Balance.[основной долг начислено нарастающим итогом] 
													+ Balance.[Проценты начислено  нарастающим итогом]
													+ Balance.[ПениНачислено  нарастающим итогом]
													+ Balance.[ГосПошлинаНачислено  нарастающим итогом]
,[Общая сумма поступивших платежей]				= Balance.[сумма поступлений  нарастающим итогом]
,[Погашено всего Основного долга]				= Balance.[основной долг уплачено нарастающим итогом]
,[Погашено всего Процентов]						= Balance.[Проценты уплачено  нарастающим итогом]
,[Погашено всего Неустойки / штрафов]			= Balance.[ПениУплачено  нарастающим итогом]
,[Погашено всего Комиссии]						= Balance.[ГосПошлинаУплачено  нарастающим итогом]
,[Погашено всего]								= Balance.[основной долг уплачено нарастающим итогом]
													+  Balance.[Проценты уплачено  нарастающим итогом]
													+  Balance.[ПениУплачено  нарастающим итогом]
													+  Balance.[ГосПошлинаУплачено  нарастающим итогом]

--,[Дата последнего платежа]						= format(last_pay.d, 'dd.MM.yyyy')
--,[Сумма последнего платежа]						= isnull(last_pay.[сумма поступлений],0)
--,[Платежи за последние 180 дней]				= Balance_min_max.[Сумма платежей за последние 180 дней]
--,[Платежей за последние 360 дней]				= Balance_min_max.[Сумма платежей за последние 360 дней]
,[Размещений в Коллекторских агентствах]		= iif(t_КА.[Кол-во передач в КА] > 0, 'Да', 'Нет') --	94	Нет	
--,[Дата последнего контакта]						= format([t_Дата последнего контакта].CommunicationDate, 'dd.MM.yyyy') -- 	121	Обязат.
--,[Количество ранее погашенных займов]			= [t_Кол-во ранее погашенных кредитов].[Кол-во ранее погашенных кредитов]
,[БКИ, куда ранее передавались данные по займу] = 'ОКБ, НБКИ, СкорингБюро'
--,[Согласие на взаимодействие с третьими лицами] = iif(collection_customers.ThirdPartiesInteractionAgreementSignedDate   is not null
			--and isnull(cs.[Отказ от взаимодействия с 3-ми лицами (230-ФЗ)],0) =0
			--,'Да', 'Нет')  -- 	126	Обязат. --(да/ нет)	98		
,[Отзыв согласия]			=  iif(cs.[Отказ от взаимодействия с 3-ми лицами (230-ФЗ)] =1, 'Да', 'Нет')
--,[ПДН на дату выдачи займа]			= t_pdn.pdn
--//ДЕТАЛИЗАЦИЯ




,[Организация/цедент]									= 'ООО МФК "КарМани"'--3	Обязат.
,[Название лота (при наличии)]							= null--4	-
,[ID кредитного договора в банке (уник. значения)]		= t.external_id --5	Обязат.
,[ID клиента (ИНН для юр. лица)]						= null --6	Рекоменд.
,[ОГРН\ОГРИП юридического лица]							= '1107746915781' --7	Рекоменд.
,[Наименование первичного кредитора (если применимо)]	= 'n/a' --8	Обязат.
,[Дата переуступки прав требования от первичного кредитора (дд.мм.гггг)]	= 'n/a' --9	Обязат.
,[Флаг наличия договоров цессии по всей цепочке переуступок (1-да; 0-нет)]	= 'n/a' --10	Обязат.

--Инфо о кредите	
,[Регион выдачи кредита]			= ЗаявкаНаЗайм.РегионПроживанияКакВЗаявке --Обязат.
,[Дата выдачи КД (ДД.ММ.ГГГГ)]		= format([ДоговорЗайма].ДатаДоговораЗайма, 'dd.MM.yyyy')

,[Дата окончания КД (ДД.ММ.ГГГГ)]	= format(isnull(OverdueIndicators.FactEndDate, OverdueIndicators.InitialEndDate)
	,'dd.MM.yyyy')

,[Кол-во пролонгаций займа]				= isnull(dm_res.TotalProlongation,0)  --14	Рекоменд.
,[Дата закрытия займа с учетом продлений (ДД.ММ.ГГГГ)] = format(t_ПоследняяДатаПлатежа.ПоследняяДатаПлатежа, 'dd.MM.yyyy')	--15	Обязат.
,[Займ со страховкой (1- да/0 - нет)]	= 0 --16	Рекоменд.
,[Способ выдачи займа (онлайн, офис)]	= 'онлайн' --17	Рекоменд.
,[Способ перечисления]							= 'Безнал'--74	Нал и Безнал	Мирошник
,[Сумма выданного кредита (в валюте КД)] = Balance.Сумма
,[Валюта кредита]						= 'RUB'--19	Обязат.
,[Продукт (вид кредита)]				= 
	case OverdueIndicators.ProductType
		when 'Инстоллмент' then 'Installment'
		else OverdueIndicators.ProductType end
	
,[Размер аннуитетного платежа]							= cast(t_график_платежей.СуммаПлатежа   as money) --	21	Рекоменд.
,[Срок займа (в мес)]									= ДоговорЗайма.[Срок]
,[текущая %-я ставка по кредиту в год]					= Balance.ПроцентнаяСтавкаНаТекущийДень
		
,[Флаг наличия в договоре согласия заемщика на уступку прав требования (1-да/ 0-нет)] 
		=cast(~cast(isnull(cs.[Отзыв согласия о передаче третьим лицам сведений о должнике (230-ФЗ)],0) as bit) as smallint)

--	24	Обязат.
--Информация о статусе задолженности	
,[Кол-во дней просрочки (на дату выгрузки)]								= Balance.dpd --25	Обязат.
,[Дата первого выхода на просрочку (ДД.ММ.ГГГГ)]						= format(Balance_min_max.[Дата первого выхода на просрочку], 'dd.MM.yyyy')	--26	Обязат.
,[Дата выхода на последнюю непогашенную просрочку (ДД.ММ.ГГГГ)]			= format(Balance_min_max.[Дата выхода на последнюю непогашенную просрочку], 'dd.MM.yyyy')	 --	27	Обязат.
,[Количество выходов на просрочку]										= OverdueIndicators.Count_overdue	--28	Обязат.
,[Максимальное количество дней просрочки по договору за всю историю]	= OverdueIndicators.MaxOverdue_CMR	--29	Рекоменд.

,[Сумма задолженности по основному долгу (в рублях)]					= Balance.[остаток од]	--	30	Обязат.
,[Сумма задолженности по процентам (в рублях)]							= Balance.[Остаток % расчетный]	-- 31	Обязат.
,[Пени, штрафы, неустойки (в рублях)]									= Balance.[остаток пени]-- 	32	Обязат.
,[Комиссии (в рублях)]													= 'N/A'--33	Обязат.
,[Комиссия за продление займа (в рублях)]								= 'N/A'						--	34	Рекоменд.
,[Госпошлина (в рублях)]												= Balance.[остаток иное (комиссии, пошлины и тд)]--	35	Обязат.
,[Прочее (в рублях) (при наличии)]										= 'N/A'	--36	Рекоменд.
,[Общая сумма задолженности (осз) с учетом Госпошлины (в рублях)]		= Balance.[остаток всего]	--37	Обязат.
,[Общая сумма задолженности (осз) без учета Госпошлины (в рублях)]		= Balance.[остаток всего]- Balance.[остаток иное (комиссии, пошлины и тд)]	--	38	Обязат.

 
--Информация о платежах	
,[Дата последнего платежа (ДД.ММ.ГГГГ)]									= format( Balance_min_max.[Дата последнего платежа], 'dd.MM.yyyy')--39	Обязат.
,[Сумма последнего платежа (в руб)]										= last_pay.[сумма поступлений]	--40	Обязат.
,[Сумма платежей за последние 90 дней ( в руб.)]						= Balance_min_max.[Сумма платежей за последние 90 дней]--(ДЛЯ МФО)	41	Обязат.
,[Сумма платежей за последние 180 дней ( в руб.)]						= Balance_min_max.[Сумма платежей за последние 180 дней]--42	Обязат.
,[Сумма платежей за последние 360 дней ( в руб.)]						= Balance_min_max.[Сумма платежей за последние 360 дней]--43	Обязат.
,[Сумма платежей за последние 720 дней ( в руб.)]						= Balance_min_max.[Сумма платежей за последние 720 дней]
,[Сумма платежей в период последних 0-30 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 0-30 дней]		-- 		44	Рекоменд.
,[Сумма платежей в период последних 31-60 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 31-60 дней]		-- 		45	Рекоменд.
,[Сумма платежей в период последних 61-90 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 61-90 дней]		-- 		46	Рекоменд.
,[Сумма платежей в период последних 91-120 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 91-120 дней]	--		47	Рекоменд.
,[Сумма платежей в период последних 121-150 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 121-150 дней]	--		48	Рекоменд.
,[Сумма платежей в период последних 151-180 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 151-180 дней]	--		49	Рекоменд.
,[Сумма платежей в период последних 181-210 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 181-210 дней]	--		50	Рекоменд.
,[Сумма платежей в период последних 211-240 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 211-240 дней]	--		51	Рекоменд.
,[Сумма платежей в период последних 241-270 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 241-270 дней]	--		52	Рекоменд.
,[Сумма платежей в период последних 271-300 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 271-300 дней]	--		53	Рекоменд.
,[Сумма платежей в период последних 301-330 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 301-330 дней]	--		54	Рекоменд.
,[Сумма платежей в период последних 331-360 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 331-360 дней]	--		55	Рекоменд.
,[Сумма платежей в период последних 361-390 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 361-390 дней]	--		56	Рекоменд.
,[Сумма платежей в период последних 391-420 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 391-420 дней]	--		57	Рекоменд.
,[Сумма платежей в период последних 421-450 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 421-450 дней]	--		58	Рекоменд.
,[Сумма платежей в период последних 451-480 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 451-480 дней]	--		59	Рекоменд.
,[Сумма платежей в период последних 481-510 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 481-510 дней]	--		60	Рекоменд.
,[Сумма платежей в период последних 511-540 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 511-540 дней]	--		61	Рекоменд.
,[Сумма платежей в период последних 541-570 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 541-570 дней]	--		62	Рекоменд.
,[Сумма платежей в период последних 571-600 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 571-600 дней]	--		63	Рекоменд.
,[Сумма платежей в период последних 601-630 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 601-630 дней]	--		64	Рекоменд.
,[Сумма платежей в период последних 631-660 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 631-660 дней]	--		65	Рекоменд.
,[Сумма платежей в период последних 661-690 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 661-690 дней]	--		66	Рекоменд.
,[Сумма платежей в период последних 691-720 дней ( в руб.)]				= Balance_min_max.[Сумма платежей в период последних 691-720 дней]	--		67	Рекоменд.
,[Общая сумма поступившая в счет оплаты по кредиту ( в руб.)]			= Balance.[сумма поступлений  нарастающим итогом]	--68	Обязат.
,[Общее кол-во платежей по кредиту]										= [t_Общее кол-во платежей по кредиту].[Общее кол-во платежей по кредиту]	--69	Обязат.
,[Кол-во ранее погашенных кредитов у цедента]							= [t_Кол-во ранее погашенных кредитов].[Кол-во ранее погашенных кредитов]--	70	Обязат.
--Инфо о должнике	
,[Дата рождения (ДД.ММ.ГГГГ)]											= format(ДоговорЗайма.ДатаРождения, 'dd.MM.yyyy')--	71	Обязат.
--,[Пол]																	= Клиент.Пол --ЗаявкаНаЗайм.Пол	--	72	Обязат.
,[Регион регистрации клиента]											= collection_registration.Region-- 	73	Обязат.
,[Регион проживания клиента]											= collection_registration.ActualRegion--	74	Обязат.

,[ПДН (Показатель долговой нагрузки), в %]								= t_pdn.pdn--	75	Рекоменд.
,[Созаемщики (кол-во)]													= 'n/a'--	76	Рекоменд. 
,[Поручители (кол-во)]													= 'n/a'--	77	Рекоменд.
,[Кол-во уникальных телефонов по клиенту]								= [t_Кол-во уникальных телефонов по клиенту].[Кол-во уникальных телефонов по клиенту] --	78	Рекоменд.
,[Кол-во уникальных адресов по клиенту]									= [t_Кол-во уникальных адресов по клиенту].[Кол-во уникальных адресов по клиенту] --	79	Рекоменд.
,[Банкротство заемщика (1-да/0-нет)]									= '0' --80	Обязат.
,[Номер арбитражного дела по банкротству]								= 'n/a' --81	Обязат.
,[Стадия банкротства 82 Рекоменд]									= 'n/a'
,[Факт смерти заемщика (1-да/0-нет)]									= 0	--83	Обязат.
,[Флаг наличия инфо о нахождении заемщика на лечении (1-да, 0-нет)]		= isnull(cs.[Клиент в больнице (230-ФЗ)],0) --	84	Рекоменд.
,[Флаг наличия информации об инвалидности (1 группа) (1-да/ 0-нет)]		= isnull(cs.[Инвалид 1 группы (230 ФЗ],0) --85	Рекоменд.
,[Факт мошенника или нахождения в МЛС (1-да/0-нет)]						= isnull(cs.[Клиент в тюрьме],0)	--86	Обязат.

,[Флаг наличия фото клиента]											= CASE
																			WHEN collection_deal.IsClientPhotoLoaded	= 1 THEN 'Да'
																			WHEN collection_deal.IsClientPhotoLoaded	= 0 THEN 'Нет'
																			ELSE null
																		END
,[Флаг наличия фото паспорта]											= CASE
																			WHEN collection_deal.IsPass23Loaded	= 1 THEN 'Да'
																			WHEN collection_deal.IsPass23Loaded	= 0 THEN 'Нет'
																			ELSE null
																		END

--Инфо о судебном производстве (при наличии судебных кейсов)	
,[Стадия взыскания: Досудебное / Судебная/ Испол. Пр-во]				= 'судебная' -- 'Досудебное'	--87	Обязат.
,[Способ обращения в суд (иск/приказ)]									= cast('n/a' AS varchar(30)) --'n/a'	--88	Обязат.
,[Наличие решения суда о взыскании задолженности (1-да, 0-нет)]			= cast('n/a' AS varchar(30)) --'n/a' -- 	89	Обязат.
,[Дата решения суда (ДД.ММ.ГГГГ)]										= cast('' AS varchar(30)) --'2 этап' -- 	90	Обязат.
,[Дата вступления в законную силу решения суда (ДД.ММ.ГГГГ)]			= cast('' AS varchar(30)) --'2 этап' -- 	91	Обязат.
,[Наличие документов по решению суда (оригинал\копия)]					= cast('' AS varchar(30)) --'2 этап' -- 	92	Обязат.
,[Отмена судебного решения (1-да/ 0-нет)]								= cast('' AS varchar(30)) --'2 этап' -- 	93	Обязат.
,[Сумма долга, признанная судом (руб.)]									= cast('' AS varchar(30)) --'2 этап' -- 	94	Обязат.
,[Наличие оригинала приказа/испол. листа (1-да/0-нет)]					= cast('' AS varchar(30)) --'2 этап' -- 	95	Обязат.
,[Дата выдачи приказа/испол. листа (ДД.ММ.ГГГГ)]						= cast('' AS varchar(30)) --'2 этап' -- 	96	Обязат.
,[Флаг наличия адреса суда, включая индекс (1-да/0-нет)]				= cast('' AS varchar(30)) --'2 этап'--	97	Рекоменд.
,[Дата возбуждения исполн пр-ва (ДД.ММ.ГГГГ)]							= cast('' AS varchar(30)) --'2 этап' -- 	98	Обязат.
,[Дата постановления об окончании ИП (ДД.ММ.ГГГГ)]						= cast('' AS varchar(30)) --'2 этап'--	99	Рекоменд.
,[Дата акта о невозможности взыскания (ДД.ММ.ГГГ)]						= cast('' AS varchar(30)) --'2 этап' -- 	100	Обязат.
,[Наличие полного кредитного досье (1-да/0-нет)]						= cast('' AS varchar(30)) --'2 этап' -- 	101	Обязат.
,[Наличие электронной версии досье (1-да/0-нет)]						= cast('' AS varchar(30)) --'2 этап' -- 	102	Обязат.
,[Наличие нотариальной подписи (1-имеется / 0 - не имеется)]			= cast('' AS varchar(30)) --'2 этап' -- 	103	Обязат.
,[Количество всего открытых ИП по заемщику]								= cast('' AS varchar(30)) --'2 этап' --   104	Рекоменд.
,[Сумма открытых ИП]													= cast('' AS varchar(30)) --'2 этап' --   105	Рекоменд.
--Инфо о залоге (при наличии залоговых кредитов)	
,[Наличие залога (1-да/0-нет)]											= cast('' AS varchar(30)) -- '2 этап' -- 	106	Обязат.

,[Предмет залога (недвижимость/авто)]									= cast('' AS varchar(30)) -- '2 этап' --	107	Рекоменд.
,[Оценочная стоимость залога (при выдаче)]								= cast('' AS varchar(30)) -- '2 этап' --108	Рекоменд.
,[Дата последней инкассации залога]										= cast('' AS varchar(30)) -- '2 этап' --	109	Рекоменд.
,[Результаты последней инкассации залога (1-есть залог/ 0-нет залога)]	= cast('' AS varchar(30)) -- '2 этап' --	110	Рекоменд.

,[Кадастровый номер залога / VIN автомобиля]							= cast('' AS varchar(30)) -- '2 этап' -- 	111	Обязат.

,[Регистрационный номер уведомления о возникновении залога в единой информационной системе нотариата] = cast('' AS varchar(30)) -- '2 этап' --	112	Рекоменд.
,[Площадь залоговой недвижимости]										= cast('' AS varchar(30)) -- '2 этап' --	113	Рекоменд.
,[Номер свидетельства о государственной регистрации]					= cast('' AS varchar(30)) -- '2 этап' --	114	Рекоменд.
,[Дата выдачи свидетельства о государственной регистрации (ДД.ММ.ГГГГ)] = cast('' AS varchar(30)) -- '2 этап' --	115	Рекоменд.
,[Год выпуска авто]														= cast('' AS varchar(30)) -- '2 этап' --	116	Рекоменд.
,[Марка авто]															= cast('' AS varchar(30)) -- '2 этап' --	117	Рекоменд.
,[Модель авто]															= cast('' AS varchar(30)) -- '2 этап' --	118	Рекоменд.
,[Наличие ПТС (1-да/0-нет)]												= cast('' AS varchar(30)) -- '2 этап' --	119	Рекоменд.
,[Регистрация обременения на залог (1-да/0-нет)]						= cast('' AS varchar(30)) -- '2 этап' --	120	Рекоменд.

--Доп информация	
,[Дата последнего контакта с должником (ДД.ММ.ГГГГ)]					= format([t_Дата последнего контакта].CommunicationDate, 'dd.MM.yyyy') -- 	121	Обязат.
,[Комментарии взыскателя]												= [t_Дата последнего контакта].Commentary---	122	Рекоменд.
,[Флаг наличия финальных выставленных требований заемщику от первичного кредитора (1-есть/ 0-нет)] 
	= iif(isnull(OverdueIndicators.FactEndDate, OverdueIndicators.InitialEndDate) > getdate(), 1, 0)
	--	123	Рекоменд.
,[Флаг наличия письменного заявления об отказе от взаимодействия (1-да/ 0-нет)] = isnull(cs.[Отзыв согласия о передаче третьим лицам сведений о должнике (230-ФЗ)],0) -- 	124	Обязат.
,[Дата написания заявления об отказе от взаимодействия (ДД.ММ.ГГГГ)]	= isnull(
	format([t_Дата_написания_заявления_об_отказе_от_взаимодействия].[Дата написания заявления об отказе от взаимодействия], 'dd.MM.yyyy')
	,'N/A') -- 	125	Обязат.
,[Флаг наличия письменного заявления о согласии на взаимодействие с 3-ми лицами] =
	iif(collection_customers.ThirdPartiesInteractionAgreementSignedDate   is not null
			and isnull(cs.[Отказ от взаимодействия с 3-ми лицами (230-ФЗ)],0) =0
			, 1, 0)  -- 	126	Обязат.
			
,[Кол-во передач в КА]							= isnull(t_КА.[Кол-во передач в КА],0) --	127	Рекоменд.
,[Срок передачи в КА (в мес)]					= isnull(cast(t_КА.[Срок передачи в КА (в мес)] as nvarchar(20)), 'N/A') --	128	Рекоменд.
,[Дата отзыва из последнего КА (дд.мм.гггг)]	= isnull(format(t_КА.[Дата отзыва из последнего КА], 'dd.MM.yyyy'), 'N/A') --	129	Рекоменд.
,[Семейное положение]							= Collection_MaritalStatus.Name
,[Информация о работе Должность]				= fedor_ClientRequest.Position
,[Информация о работе Зарплата]					= collection_PlaceOfWork.Salary

,[Номер дела] = cast(NULL AS nvarchar(1000))
,[Наименование суда] = cast(NULL AS nvarchar(1000))
,[Номер исполнительного производства] = cast(NULL AS nvarchar(1000))
,[Причина окончания ИП] = cast(NULL AS nvarchar(1000))

into #tresult
from #cession AS t
left join dwh2.[hub].[ДоговорЗайма] 
	on ДоговорЗайма.[КодДоговораЗайма] = t.external_id
left join dwh2.link.Клиент_ДоговорЗайма  Клиент_ДоговорЗайма
	on Клиент_ДоговорЗайма.КодДоговораЗайма = ДоговорЗайма.[КодДоговораЗайма]	
left join stg._collection.deals collection_deal 
	on collection_deal.number = ДоговорЗайма.[КодДоговораЗайма]
left join stg._collection.customers collection_customers 
	on collection_customers.id = collection_deal.IdCustomer
left join stg.[_Collection].[registration] collection_registration
	on collection_registration.IdCustomer  = collection_customers.id
left join #groupedCustomerStatuses cs on cs.Collection_CustomerId = collection_deal.IdCustomer

left join 
(
select 
 Договор
, [Общее кол-во платежей по кредиту] = count(Ссылка)  
from stg.[_1cCMR].[Документ_Платеж]
where Проведен = 0x01
group by Договор
) [t_Общее кол-во платежей по кредиту]
	on [t_Общее кол-во платежей по кредиту].Договор = ДоговорЗайма.[СсылкаДоговораЗайма]

left join dwh2.dbo.dm_OverdueIndicators OverdueIndicators
	on OverdueIndicators.Number = ДоговорЗайма.[КодДоговораЗайма]
left join 
	(
	select Balance.external_id
		,[Дата первого выхода на просрочку] = min(case when Balance.dpd_begin_day = 1
			and Balance.[dpd day-1] = 0 then d
		end )
		,[Дата выхода на последнюю непогашенную просрочку]
			 = max(case when Balance.dpd_begin_day = 1
			and Balance.[dpd day-1] = 0 then d
		end )
		,[Дата последнего платежа]	=	max(case when Balance.[сумма поступлений]>0 then  d
			end)
		,[Общее кол-во платежей по кредиту]	=
			sum(case when Balance.[сумма поступлений]>0 then  1
			end)
		,[Сумма платежей за последние 90 дней]	= sum(case when d between dateadd(dd, -90, @dt) and @dt  then [сумма поступлений] end)
		,[Сумма платежей за последние 180 дней]	= sum(case when d between dateadd(dd, -180, @dt) and @dt then [сумма поступлений] end)
		,[Сумма платежей за последние 360 дней]	= sum(case when d between dateadd(dd, -360, @dt) and @dt then [сумма поступлений] end)
		,[Сумма платежей за последние 720 дней]	= sum(case when d between dateadd(dd, -720, @dt) and @dt then [сумма поступлений] end)
		,[Сумма платежей в период последних 0-30 дней]		= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  0, [сумма поступлений], 0))
		,[Сумма платежей в период последних 31-60 дней]		= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  1, [сумма поступлений], 0))
		,[Сумма платежей в период последних 61-90 дней]		= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  2, [сумма поступлений], 0))
		,[Сумма платежей в период последних 91-120 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  3, [сумма поступлений], 0))
		,[Сумма платежей в период последних 121-150 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  4, [сумма поступлений], 0))
		,[Сумма платежей в период последних 151-180 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  5, [сумма поступлений], 0))
		,[Сумма платежей в период последних 181-210 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  6, [сумма поступлений], 0))
		,[Сумма платежей в период последних 211-240 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  7, [сумма поступлений], 0))
		,[Сумма платежей в период последних 241-270 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  8, [сумма поступлений], 0))
		,[Сумма платежей в период последних 271-300 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  9, [сумма поступлений], 0))
		,[Сумма платежей в период последних 301-330 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  10, [сумма поступлений], 0))
		,[Сумма платежей в период последних 331-360 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  11, [сумма поступлений], 0))
		,[Сумма платежей в период последних 361-390 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  12, [сумма поступлений], 0))
		,[Сумма платежей в период последних 391-420 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  13, [сумма поступлений], 0))
		,[Сумма платежей в период последних 421-450 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  14, [сумма поступлений], 0))
		,[Сумма платежей в период последних 451-480 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  15, [сумма поступлений], 0))
		,[Сумма платежей в период последних 481-510 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  16, [сумма поступлений], 0))
		,[Сумма платежей в период последних 511-540 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  17, [сумма поступлений], 0))
		,[Сумма платежей в период последних 541-570 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  18, [сумма поступлений], 0))
		,[Сумма платежей в период последних 571-600 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  19, [сумма поступлений], 0))
		,[Сумма платежей в период последних 601-630 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  20, [сумма поступлений], 0))
		,[Сумма платежей в период последних 631-660 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  21, [сумма поступлений], 0))
		,[Сумма платежей в период последних 661-690 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  22, [сумма поступлений], 0))
		,[Сумма платежей в период последних 691-720 дней]	= sum(iif(datediff(dd, d, dateadd(dd, -1, @dt))/30 =  23, [сумма поступлений], 0))

	from dwh2.dbo.dm_CMRStatBalance Balance
		INNER JOIN #cession AS ces
			ON ces.external_id = Balance.external_id
	group by Balance.external_id
	) Balance_min_max on Balance_min_max.external_id = ДоговорЗайма.[КодДоговораЗайма]
left join dwh2.dbo.dm_CMRStatBalance Balance
	on Balance.d= @dt
	and Balance.external_id = ДоговорЗайма.[КодДоговораЗайма]
left join dwh2.dbo.dm_CMRStatBalance last_pay
	on last_pay.external_id = Balance_min_max.external_id
	and last_pay.d = Balance_min_max.[Дата последнего платежа]
outer apply(
	select 
		[Кол-во ранее погашенных кредитов] = COUNT(distinct t_Клиент_ДоговорЗайма.КодДоговораЗайма)
	from dwh2.link.Клиент_ДоговорЗайма t_Клиент_ДоговорЗайма
	where t_Клиент_ДоговорЗайма.GuidКлиент = Клиент_ДоговорЗайма.GuidКлиент
	and t_Клиент_ДоговорЗайма.КодДоговораЗайма != Клиент_ДоговорЗайма.КодДоговораЗайма
	and exists(select top(1) 1 from dwh2.dbo.dm_OverdueIndicators oi
		where oi.Number = t_Клиент_ДоговорЗайма.КодДоговораЗайма
		and IsActive = 0)
		
) [t_Кол-во ранее погашенных кредитов]
left join (
	select IdCustomer, 
		[Кол-во уникальных телефонов по клиенту] = Count(distinct Phone) 
		from stg._Collection.CustomerContact 
	where IsVerified = 1
		and ContactPersonType in(1) --Клиент
	and IdContactType in (5)--тел. мобильный
	group by IdCustomer

) [t_Кол-во уникальных телефонов по клиенту] on 
	[t_Кол-во уникальных телефонов по клиенту].IdCustomer = collection_deal.IdCustomer
left join 
(
	
	select IdCustomer
		, [Кол-во уникальных адресов по клиенту] = count(distinct Address)
	from (select distinct IdCustomer, Address = ActualAddress
		from stg._Collection.registration
	union
	select distinct IdCustomer, PermanentRegisteredAddress
	from stg._Collection.registration
	) t
	group by IdCustomer
	
) [t_Кол-во уникальных адресов по клиенту]
	on [t_Кол-во уникальных адресов по клиенту].IdCustomer = collection_customers.Id
left join (
	select 
		Number
		,CommunicationDate
		,Commentary
	from (select 
		Number
		,CommunicationDate
		,Commentary
		,rn = Row_Number() over(partition by Number order by CommunicationDateTime desc)
	from stg._Collection.mv_Communications
		where Контакт = 'Да'
		and PersonType = 'Клиент'
	) t
	where t.rn = 1
) [t_Дата последнего контакта]
	on [t_Дата последнего контакта].Number = ДоговорЗайма.[КодДоговораЗайма]
left join #t_Дата_написания_заявления_об_отказе_от_взаимодействия	 
	[t_Дата_написания_заявления_об_отказе_от_взаимодействия] on [t_Дата_написания_заявления_об_отказе_от_взаимодействия].CustomerId
		=	 collection_customers.Id
left join dwh2.hub.Заявка AS ЗаявкаНаЗайм
	on ЗаявкаНаЗайм.НомерЗаявки = ДоговорЗайма.КодДоговораЗайма
left join dwh2.dm.CMRExpectedRepayments t_график_платежей
	on t_график_платежей.Договор = ДоговорЗайма.[СсылкаДоговораЗайма]
	and НомерПлатежа = 1
left join (
	select  Договор
	 ,ПоследняяДатаПлатежа = max(ДатаПлатежа) 
	from dwh2.dm.CMRExpectedRepayments t_график_платежей
	group by Договор
) t_ПоследняяДатаПлатежа
	on t_ПоследняяДатаПлатежа.Договор = ДоговорЗайма.[СсылкаДоговораЗайма]
left join 
(
	select External_id
		,[Кол-во передач в КА] = count(1) 
		,[Срок передачи в КА (в мес)] = isnull(
			sum(datediff(dd, st_date, fact_end_date))/ 30, 0) +1
		,[Дата отзыва из последнего КА] = max(fact_end_date)
	from (
		select 
			d.Number as External_id
			,cat.TransferDate as st_date 
			,cat.ReturnDate as fact_end_date
			,cat.PlannedReviewDate as plan_end_date
		from Stg._collection.CollectingAgencyTransfer as cat
			inner join Stg._collection.Deals as d
				on d.Id = cat.DealId
		) as t
	group by External_id	
) t_КА on t_КА.External_id = ДоговорЗайма.КодДоговораЗайма
left join stg._1cCMR.Документ_ВыдачаДенежныхСредств	ВыдачаДенежныхСредств	
	on ВыдачаДенежныхСредств.Договор = ДоговорЗайма.СсылкаДоговораЗайма
		and ВыдачаДенежныхСредств.Проведен = 0x01
left join dwh2.risk.pdn_calculation_2gen t_pdn
	on t_pdn.Number =  ДоговорЗайма.КодДоговораЗайма
left join stg._Collection.CustomerPersonalData   collection_CustomerPersonalData
	on collection_CustomerPersonalData.IdCustomer = collection_customers.Id
left join stg._Collection.MaritalStatus Collection_MaritalStatus
	on Collection_MaritalStatus.Id =collection_CustomerPersonalData.MaritalStatusId 
left join stg._Collection.PlaceOfWork collection_PlaceOfWork
	on collection_PlaceOfWork.IdCustomer = collection_customers.Id
left join stg._fedor.core_ClientRequest fedor_ClientRequest
	on fedor_ClientRequest.Number = ДоговорЗайма.КодДоговораЗайма
		COLLATE  Cyrillic_General_CI_AS
left join (select 
	number
	,TotalProlongation = count(1) 
	from dwh2.dbo.dm_restructurings r
where  r.reason_credit_vacation = 'Пролонгация PDL'
group by number
) dm_res on dm_res.number = ДоговорЗайма.КодДоговораЗайма

left join  dwh2.dm.CMRExpectedRepayments t_ExpectedRepayments
	on t_ExpectedRepayments.Код =  ДоговорЗайма.[КодДоговораЗайма]
	and t_ExpectedRepayments.НомерПлатежа = 1
left join stg._1cCMR.Документ_ГрафикПлатежей t_ГрафикПлатежей
	on t_ГрафикПлатежей.Договор = t_ExpectedRepayments.Договор
	and t_ГрафикПлатежей.Ссылка = t_ExpectedRepayments.Регистратор
left join dwh2.hub.Клиенты	Клиент
	on Клиент.GuidКлиент = Клиент_ДоговорЗайма.GuidКлиент
left join dwh2.[sat].[Клиент_ПаспортныеДанные] ПаспортныеДанные
	on ПаспортныеДанные.GuidКлиент = Клиент.GuidКлиент
left join dwh2.sat.Клиент_Телефон	 Клиент_Телефон
	on Клиент_Телефон.GuidКлиент = Клиент.GuidКлиент
	and Клиент_Телефон.nRow = 1
left join dwh2.dm.v_Клиент_ИНН	Клиент_ИНН
	on	Клиент_ИНН.GuidКлиент = Клиент.GuidКлиент
	
left join dwh2.sat.Клиент_Email Клиент_Email
	on Клиент_Email.GuidКлиент = Клиент.GuidКлиент
	and Клиент_Email.nRow = 1
left join stg._fedor.core_ClientRequest cr on cr.Number = t.external_id COLLATE SQL_Latin1_General_CP1_CI_AS
left join #CustomerContact cc on cc.IdCustomer = collection_customers.Id

left join stg._1CIntegration.РегистрСведений_НедействительныеПаспорта t_НедействительныеПаспорта 
	on t_НедействительныеПаспорта.Серия =ПаспортныеДанные.Серия
		and t_НедействительныеПаспорта.Номер = ПаспортныеДанные.Номер 
outer apply stg.dbo.tvf_GetAddressWithPartsPvt(Collection_registration.ActualAddress) AddressParts_ActualAddress
outer apply stg.dbo.tvf_GetAddressWithPartsPvt(Collection_registration.PermanentRegisteredAddress) AddressParts_PermanentRegistered

where 1=1
/*23.07.2025 ПО ЧС не проверяем, согласовано с М. Блинчевской
and not exists (select top(1) 1 from dwh2.dm.blacklists blacklists 
	where blacklists.fio = concat_ws(' ', ДоговорЗайма.Фамилия
		, ДоговорЗайма.Имя
		, ДоговорЗайма.Отчество)
		and cast(blacklists.birthdate as date) = cast(ДоговорЗайма.ДатаРождения as date)
		)
	*/	
--order by 	[№ п/п]
UPDATE R
SET 
	--88 Способ обращения в суд (иск/приказ) - JudicialClaims.FeedWay 1-исковое, 2-приказное
	[Способ обращения в суд (иск/приказ)] = isnull(cast(i.FeedWay AS varchar(10)) ,'')

	--89 Наличие решения суда о взыскании задолженности (1-да, 0-нет)
	--Комментарий: вкладка СП, при условии заполнения поля - 1, если не заполнено - 0
	--JudicialClaims.JudgmentDate
	,[Наличие решения суда о взыскании задолженности (1-да, 0-нет)] = cast(iif(i.JudgmentDate IS NULL, 0 , 1) AS varchar(10))

	--90 Дата решения суда (ДД.ММ.ГГГГ)
	--если исковое производство, то суд выдает решение. 
	--если приказное, то судебный приказ для приставов - по идее так это устроено. 
	--поэтому там это одно поле (= 96 Дата выдачи приказа/испол. листа)
	,[Дата решения суда (ДД.ММ.ГГГГ)] = i.JudgmentDate

	--91 Дата вступления в законную силу решения суда (ДД.ММ.ГГГГ)
	--JudicialClaims.JudgmentEntryIntoForceDate
	,[Дата вступления в законную силу решения суда (ДД.ММ.ГГГГ)] = isnull(format(i.JudgmentEntryIntoForceDate, 'dd.MM.yyyy'), '')

	--92 Наличие документов по решению суда (оригинал\копия)
	--Комментарий: в случае если в столбце 89 результат 1, то в столбце 92 - "оригинал", если 0 - "null"
	,[Наличие документов по решению суда (оригинал\копия)] = cast(iif(i.JudgmentDate IS NULL, '', 'оригинал') AS varchar(10))

	--93 Отмена судебного решения (1-да/ 0-нет)
	--Комментарий: 1 - в случае если значение данного поля = "отмена судебного приказа", "0" в случае иных значений данного поля
	--JudicialClaims.MonitoringResult Отмена судебного приказа = 5
	,[Отмена судебного решения (1-да/ 0-нет)] = cast(iif(i.MonitoringResult IN (5), 1, 0) AS varchar(10))

	--94 Сумма долга, признанная судом (руб.)
	--JudicialClaims.AmountJudgment
	,[Сумма долга, признанная судом (руб.)] = isnull(convert(varchar(20), i.AmountJudgment), '')

	--95 Наличие оригинала приказа/испол. листа (1-да/0-нет)
	--Комментарий: в случае если в столбце 89 результат 1, то в столбце 95 - "1", если 0 - "0"
	,[Наличие оригинала приказа/испол. листа (1-да/0-нет)] = cast(iif(i.JudgmentDate IS NULL, 0, 1) AS varchar(10))

	--96 Дата выдачи приказа/испол. листа (ДД.ММ.ГГГГ)
	--JudicialClaims.JudgmentDate
	,[Дата выдачи приказа/испол. листа (ДД.ММ.ГГГГ)] = isnull(format(i.JudgmentDate, 'dd.MM.yyyy'), '')

	--97 Флаг наличия адреса суда, включая индекс (1-да/0-нет)
	--Комментарий: поле заполнено "1", не заполнено "0"
	--JudicialProceeding.CourtId - указан ли суд в требовании. 
	--данные по судам - таблица Courts, адрес в колонке FullAddress. 
	--данные получаем от внешнего поставщика, отдельно индекс не хранится
	,[Флаг наличия адреса суда, включая индекс (1-да/0-нет)] = cast(iif(i.CourtId IS NULL, 0, 1) AS varchar(10))

	--98 Дата возбуждения исполн пр-ва (ДД.ММ.ГГГГ)
	--Комментарий: вкладка “ИП”
	--EnforcementProceedingExcitation.ExcitationDate
	,[Дата возбуждения исполн пр-ва (ДД.ММ.ГГГГ)] = isnull(format(i.ExcitationDate, 'dd.MM.yyyy'), '')

	--99 Дата постановления об окончании ИП (ДД.ММ.ГГГГ)
	--Дата окончания ИП? EnforcementProceedingExcitation.EndDate
	,[Дата постановления об окончании ИП (ДД.ММ.ГГГГ)] = isnull(format(i.EndDate, 'dd.MM.yyyy'), '')

	--100 Дата акта о невозможности взыскания (ДД.ММ.ГГГ)
	--В Спейсе не вижу такой даты
	,[Дата акта о невозможности взыскания (ДД.ММ.ГГГ)] = ''

	--101 Наличие полного кредитного досье (1-да/0-нет)
	--Комментарий: всегда “1”
	,[Наличие полного кредитного досье (1-да/0-нет)] = '1'

	--102 Наличие электронной версии досье (1-да/0-нет)
	--Комментарий: всегда “1”
	,[Наличие электронной версии досье (1-да/0-нет)] = '1'

	--103 Наличие нотариальной подписи (1-имеется / 0 - не имеется)
	--Комментарий: всегда “0”
	,[Наличие нотариальной подписи (1-имеется / 0 - не имеется)] = '0'

	--104 Количество всего открытых ИП по заемщику 
	--- Такой информации у нас нет, потенциальный покупатель самостоятельно может оценить сторонние ИП
	,[Количество всего открытых ИП по заемщику]	= '' --   104	Рекоменд.

	--105 Сумма открытых ИП 
	--- такой информации у нас нет.
	,[Сумма открытых ИП] = ''

	--111 [Кадастровый номер залога / VIN автомобиля]
	--VIN автомобиля - приходит из сторонних систем, записывается в таблицу PledgeItem, колонка Vin
	,[Кадастровый номер залога / VIN автомобиля] = i.VIN

	,[Номер дела] = left(trim(i.NumberCasesInCourt), 1000)
	,[Наименование суда] = left(trim(i.CourtName), 1000)
	,[Номер исполнительного производства] = left(trim(i.CaseNumberInFSSP), 1000)
	,[Причина окончания ИП] = left(trim(i.BasisEndEnforcementProceeding), 1000)

FROM #tresult AS R
	LEFT JOIN #isk_sp_space AS i
		ON i.external_id = R.[ID кредитного договора в банке (уник. значения)]

--and not exists(Select top(1) 1 from #isk_sp_space t1
--	where t1.external_id = t.[ID кредитного договора в банке (уник. значения)])


--T_DWH-274 причины исключения
alter table #tresult
add 
	--0
	[Есть причина исключения] nvarchar(10),
	--1
	[Кол-во дней просрочки (на дату выгрузки) меньше 90] nvarchar(10),
	--2
	[Неактивный договор] nvarchar(10),
	--3
	[Неподходящий статус Клиента] nvarchar(1000),
	--4
	[Реструктуризация] nvarchar(10),
	--5
	[Военные кредитные каникулы] nvarchar(10),
	--6 не заполнять для @deal_type = 'judicial_claims' -- Договора с судебными исками
	[Нет Причины остановки начислений] nvarchar(10),
	--7 не заполнять для @deal_type = 'judicial_claims' -- Договора с судебными исками
	[Есть судебный иск] nvarchar(10)


--1
update t 
set [Кол-во дней просрочки (на дату выгрузки) меньше 90] = 'Да'
from #tresult as t
where NOT ([Кол-во дней просрочки (на дату выгрузки)] >90)

--2
update t 
set [Неактивный договор] = 'Да'
from #tresult as t
where exists(
		select top(1) 1 from dwh2.dbo.dm_OverdueIndicators oi
		where oi.IsActive = 0
			and oi.Number = t.[ID кредитного договора в банке (уник. значения)]
	)


--3
update t 
set [Неподходящий статус Клиента] = trim(concat(
iif(isnull(cs.[Банкрот неподтверждённый],0) = 1,'Банкрот неподтверждённый, ',''),
iif(isnull(cs.[Банкрот подтверждённый],0) = 1,'Банкрот подтверждённый, ',''),
iif(isnull(cs.[Банкротство завершено],0) = 1,'Банкротство завершено, ',''),
iif(isnull(cs.[Смерть неподтвержденная],0) = 1,'Смерть неподтвержденная, ',''),
iif(isnull(cs.[Смерть подтвержденная],0) = 1,'Смерть подтвержденная, ',''),
iif(isnull(cs.HardFraud,0) = 1,'HardFraud, ',''),
iif(isnull(cs.[КА],0) = 1,'КА, ',''),
iif(isnull(cs.[Отзыв согласия о передаче третьим лицам сведений о должнике (230-ФЗ)],0) = 1,'Отзыв согласия о передаче третьим лицам сведений о должнике (230-ФЗ), ',''),
iif(isnull(cs.[Отзыв согласия на уступку прав (требования)],0) = 1,'Отзыв согласия на уступку прав (требования), ','')
	))
from #tresult as t
	inner join #groupedCustomerStatuses as cs
		on cs.Number = t.[ID кредитного договора в банке (уник. значения)]
where exists(
		select top(1) 1 from #groupedCustomerStatuses as gcs
			--inner join stg._Collection.Deals d on d.IdCustomer = cs.Collection_CustomerId
		--where d.Number = t.[ID кредитного договора в банке (уник. значения)]
		where gcs.Number = t.[ID кредитного договора в банке (уник. значения)]
			and 1 in (
				isnull(gcs.[Банкрот неподтверждённый],0)
				,isnull(gcs.[Банкрот подтверждённый],0)
				,isnull(gcs.[Банкротство завершено],0)
				,isnull(gcs.[Смерть неподтвержденная],0)
				,isnull(gcs.[Смерть подтвержденная],0)
				,isnull(gcs.HardFraud,0)
				,isnull(gcs.[КА],0)
				,isnull(gcs.[Отзыв согласия о передаче третьим лицам сведений о должнике (230-ФЗ)],0)
				,isnull(gcs.[Отзыв согласия на уступку прав (требования)],0)
			)
	)

update t 
set [Неподходящий статус Клиента] = substring(t.[Неподходящий статус Клиента],1,len(t.[Неподходящий статус Клиента])-1)
from #tresult as t
where t.[Неподходящий статус Клиента] is not null


--4
update t 
set [Реструктуризация] = 'Да'
from #tresult as t
where exists(
		Select top(1) 1 
		from dwh2.dbo.dm_restructurings r
		where r.number = t.[ID кредитного договора в банке (уник. значения)]
			and (getdate() between r.period_start and r.period_end
				and r.reason_credit_vacation <> 'Военные кредитные каникулы'
			)
	)

--5
update t 
set [Военные кредитные каникулы] = 'Да'
from #tresult as t
where exists(
		Select top(1) 1 
		from dwh2.dbo.dm_restructurings r
		where r.number = t.[ID кредитного договора в банке (уник. значения)]
			and r.reason_credit_vacation = 'Военные кредитные каникулы'
	)

--6 не заполнять для @deal_type = 'judicial_claims' -- Договора с судебными исками
update t 
set [Нет Причины остановки начислений] = 'Да'
from #tresult as t
where NOT (
		@deal_type = 'judicial_claims'
		OR
		EXISTS(
			SELECT top(1) 1 
			FROM #Reasons2StoppingAccruals rsa
			WHERE rsa.external_id = t.[ID кредитного договора в банке (уник. значения)]
		)
	)


--7 не заполнять для @deal_type = 'judicial_claims' -- Договора с судебными исками
update t 
set [Есть судебный иск] = 'Да'
from #tresult as t
where NOT(
		(
			@deal_type = 'judicial_claims'
			OR
			NOT EXISTS(
				SELECT top(1) 1 
				FROM #isk_sp_space t1
				where t1.external_id = t.[ID кредитного договора в банке (уник. значения)]
			)
		)
	)


--0
update t 
set [Есть причина исключения] = 'Да'
from #tresult as t
where coalesce(
		[Кол-во дней просрочки (на дату выгрузки) меньше 90],
		[Неактивный договор],
		[Неподходящий статус Клиента],
		[Реструктуризация],
		[Военные кредитные каникулы],
		[Нет Причины остановки начислений],
		[Есть судебный иск]
	) is not null



IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##tresult
	SELECT * INTO ##tresult FROM #tresult AS T
END







DROP TABLE IF EXISTS #t_result_2

/*
--var 1
select DISTINCT	t.*
INTO #t_result_2
FROM #tresult as t
where 1=1

--обязательные условия 
and [Кол-во дней просрочки (на дату выгрузки)] >90
and not 
	exists(select top(1) 1 from dwh2.dbo.dm_OverdueIndicators oi
	where oi.IsActive = 0
	and oi.Number = t.[ID кредитного договора в банке (уник. значения)])
	
AND ( 
	not exists(
		select top(1) 1 from #groupedCustomerStatuses cs
			--inner join stg._Collection.Deals d on d.IdCustomer = cs.Collection_CustomerId
		--where d.Number = t.[ID кредитного договора в банке (уник. значения)]
		where cs.Number = t.[ID кредитного договора в банке (уник. значения)]
			and 1 in (
				isnull(cs.[Банкрот неподтверждённый],0)
				,isnull(cs.[Банкрот подтверждённый],0)
				,isnull(cs.[Банкротство завершено],0)
				,isnull(cs.[Смерть неподтвержденная],0)
				,isnull(cs.[Смерть подтвержденная],0)
				,isnull(cs.HardFraud,0)
				,isnull(cs.[КА],0)
				,isnull(cs.[Отзыв согласия о передаче третьим лицам сведений о должнике (230-ФЗ)],0)
				,isnull(cs.[Отзыв согласия на уступку прав (требования)],0)
			)
	)

	or 
	/*--добавить договора Диана Сухинина. письмо 2025-09-11 08:47 */
	t.[ID кредитного договора в банке (уник. значения)] in (
		'1611234010001'
		,'1702162140001'
		,'1703294590002'
		,'1705076870001'
		,'1704063020003'
		,'1707078500001'
		,'1706235620006'
		,'1612023760003'
	)
)

AND not exists(
	Select top(1) 1 from dwh2.dbo.dm_restructurings r
	where r.number = t.[ID кредитного договора в банке (уник. значения)]
		and (getdate() between r.period_start and r.period_end
			or  r.reason_credit_vacation = 'Военные кредитные каникулы'
		)
)
--

	AND (
		@deal_type = 'judicial_claims'
		OR
		EXISTS(
			SELECT top(1) 1 
			FROM #Reasons2StoppingAccruals rsa
			WHERE rsa.external_id = t.[ID кредитного договора в банке (уник. значения)]
		)
		--добавить договора с возращенной гп в реестры досудебного портфеля
		--Диана Сухинина. письмо 2025-08-07 08:47
		or t.[ID кредитного договора в банке (уник. значения)] in (
			'21120820158179',
			'21120920159296',
			'21123020184145',
			'22010520189727',
			'22011020195510',
			'22011620203995',
			'22012820221002',
			'22020420231376',
			'22020620235021',
			'22112120587363',
			'22112420592807',
			'22112520594524',
			'22120720610210',
			'22121420616937',
			'22121920622215'
		)
	)

	and (
		@deal_type = 'judicial_claims'
		OR
		NOT EXISTS(
			SELECT top(1) 1 
			FROM #isk_sp_space t1
			where t1.external_id = t.[ID кредитного договора в банке (уник. значения)]
		)
	)

--order by [№ п/п]
	--and isnull(cs.HardFraud,0) = 0 --не хард фрод
	--and isnull(cs.[Смерть подтвержденная],0) = 0 
*/

--var 2
select DISTINCT	t.*
INTO #t_result_2
FROM #tresult as t
where @isFull = 1 -- 1-выгрузить всё, 0 - кроме
	or t.[Есть причина исключения] is null
	or 
	/*--добавить договора Диана Сухинина. письмо 2025-09-11 08:47 */
	t.[ID кредитного договора в банке (уник. значения)] in (
		'1611234010001'
		,'1702162140001'
		,'1703294590002'
		,'1705076870001'
		,'1704063020003'
		,'1707078500001'
		,'1706235620006'
		,'1612023760003'
	)
	--добавить договора с возращенной гп в реестры досудебного портфеля
	--Диана Сухинина. письмо 2025-08-07 08:47
	or t.[ID кредитного договора в банке (уник. значения)] in (
		'21120820158179',
		'21120920159296',
		'21123020184145',
		'22010520189727',
		'22011020195510',
		'22011620203995',
		'22012820221002',
		'22020420231376',
		'22020620235021',
		'22112120587363',
		'22112420592807',
		'22112520594524',
		'22120720610210',
		'22121420616937',
		'22121920622215'
	)
	



UPDATE A SET [№ п/п] = B.[№ п/п]
FROM #t_result_2 AS A
	INNER JOIN (
		SELECT 
			[№ п/п]	 = row_number() over( order by try_cast([№ договора] as bigint)),
			T.[№ договора]
		FROM #t_result_2 AS T
	) AS B
	ON B.[№ договора] = A.[№ договора]

IF @isDebug = 1 BEGIN
	DROP TABLE IF EXISTS ##t_result_2
	SELECT * INTO ##t_result_2 FROM #t_result_2 AS T
END

--test
--IF 1=1 BEGIN
--	DROP TABLE IF EXISTS tmp.TMP_AND_Report_cession
--	SELECT * INTO tmp.TMP_AND_Report_cession FROM #t_result_2 AS T
--	--DROP TABLE IF EXISTS ##TMP_AND_Report_cession
--	--SELECT * INTO ##TMP_AND_Report_cession FROM #t_result_2 AS T
--END

	--SELECT * 
	--FROM #t_result_2
	--order by [№ п/п]

--NEW
IF @report_type = 'detail' AND @deal_type = 'judicial_claims'
BEGIN
	--Цессия договоров с судебными исками. Расширенный реестр
	SELECT distinct
		[№ п/п],
		[№ договора],
		[Дата заключения договора],
		[Сумма выданного займа],
		[Наименование Продукта],
		[% ставка в день],
		[% ставка в год],
		[ПСК, %],
		[ПСК, руб.],
		[Срок кредита, днях],
		[Срок кредита, мес.],
		[Количество дней просрочки на дату цессии],
		[Дата выхода на просрочку],
		[Дата погашения договора],
			[Количество выходов на просрочку],
			[Максимальное количество дней просрочки по договору за всю историю],
		[Основной долг, руб.],
		[Проценты, руб.],
		[Пени, штрафы, неустойки, руб.] = R.[Пени, штрафы, неустойки (в рублях)],
		[Недоплаченная комиссия, руб.],
		[Госпошлина, руб.] = R.[Госпошлина (в рублях)],
		[Общая сумма задолженности с учетом Госпошлины, руб.] = R.[Общая сумма задолженности (осз) с учетом Госпошлины (в рублях)],
		[Общая сумма задолженности без учета Госпошлины, руб.] = R.[Общая сумма задолженности (осз) без учета Госпошлины (в рублях)],
		[Цена покупки, руб.],
		[УИД],
		[Фамилия],
		[Имя],
		[Отчество],
		[Пол],
		[Дата рождения],
		[Место рождения],
		[Серия паспорта],
		[Номер паспорта],
		[Код подразделения],
		[Орган выдавший паспорт],
		[Дата выдачи паспорта],
		[Флаг наличия фото клиента],
		[Флаг наличия фото паспорта],
		[Адрес регистрации (полностью)] = R.[адрес регистрации],
		[Индекс адреса регистрации],
		[Область адреса регистрации],
		[Район адреса регистрации],
		[Город / иной населенный пункт адреса регистрации],
		[Улица адреса регистрации],
		[Дом адреса регистрации],
		[Корпус адреса регистрации],
		[Квартира адреса регистрации],
		[Адрес фактического проживания (полностью)] = R.[адрес проживания],
		[Индекс фактического проживания],
		[Область фактического проживания],
		[Район фактического проживания],
		[Город / иной населенный пункт фактического проживания],
		[Улица фактического проживания],
		[Дом фактического проживания],
		[Корпус фактического проживания],
		[Квартира фактического проживания],
			[ПДН (Показатель долговой нагрузки), %] = R.[ПДН (Показатель долговой нагрузки), в %],
		[ИНН],
		[СНИЛС],
		[Место работы],
		[Мобильный телефон],
		[Доп. телефон 1],
		[Доп. телефон 2],
		[Доп. телефон 3],
		[Доп. телефон 4],
		[Доп. телефон 5],
		[E-mail],
		[Пролонгация договора] = R.[Пролонгация договора (да/ нет)],
		[Реструктуризация договора] = R.[Реструктуризация договора (да / нет)],
		[Номер первоначального займа] = R.[Номер первоначального договора займа],
		[Регион выдачи займа] = R.[Регион выдачи кредита],
		[Подпись при заключении договора займа (АСП / ручная)],
			[Номер телефона для кода СМС] = '',
			[Код электронной подписи/Код из СМС ] = '',
			[Дата и время направления СМС с кодом] = '',
		[Способ выдачи займа (онлайн / оффлайн)] = R.[Способ выдачи займа (онлайн, офис)],
		[Способ перечисления],
		[Наименование платежной системы / Банка],
			[Номер карты получателя] = '',
		[Номер транзакции / ID перевода],
		[Дата и время перевода],
		[Начислено всего Основного долга],
		[Начислено всего Процентов],
		[Начислено всего Неустойки / штрафов],
		[Начислено всего Комиссии],
		[Начислено всего],
		[Общая сумма поступивших платежей],
		[Погашено всего Основного долга],
		[Погашено всего Процентов],
		[Погашено всего Неустойки / штрафов],
		[Погашено всего Комиссии],
		[Погашено всего],
		[Дата последнего платежа] = R.[Дата последнего платежа (ДД.ММ.ГГГГ)],
		[Сумма последнего платежа] = R.[Сумма последнего платежа (в руб)],
		[Сумма платежей за последние 180 дней] = R.[Сумма платежей за последние 180 дней ( в руб.)],
		[Сумма платежей за последние 360 дней] = R.[Сумма платежей за последние 360 дней ( в руб.)],
		[Сумма платежей за последние 720 дней] = R.[Сумма платежей за последние 720 дней ( в руб.)],
		[Общее количество платежей] = R.[Общее кол-во платежей по кредиту],
		[Количество размещений в Коллекторских агентствах] = R.[Кол-во передач в КА],
			[Срок передачи в КА] = R.[Срок передачи в КА (в мес)],
			[Дата отзыва из последнего КА] = R.[Дата отзыва из последнего КА (дд.мм.гггг)],
		[Дата последнего контакта] = R.[Дата последнего контакта с должником (ДД.ММ.ГГГГ)],
		[Количество ранее погашенных займов] = R.[Кол-во ранее погашенных кредитов у цедента],
		[БКИ, куда ранее передавались данные по займу],
		[Согласие на взаимодействие с третьими лицами (да/ нет) ] = R.[Флаг наличия письменного заявления о согласии на взаимодействие с 3-ми лицами],
		[Отзыв согласия (да/нет)] = R.[Отзыв согласия],
		[ПДН на дату выдачи займа] = R.[ПДН (Показатель долговой нагрузки), в %],
		[Флаг наличия в договоре согласия заемщика на уступку прав требования] = R.[Флаг наличия в договоре согласия заемщика на уступку прав требования (1-да/ 0-нет)],
		[Стадия взыскания] = R.[Стадия взыскания: Досудебное / Судебная/ Испол. Пр-во],
		[Способ обращения в суд (иск/приказ)],
		[Наличие решения суда о взыскании задолженности] = R.[Наличие решения суда о взыскании задолженности (1-да, 0-нет)],
		[Дата решения суда] = cast(R.[Дата решения суда (ДД.ММ.ГГГГ)] AS date),
		R.[Номер дела],
		[Дата вступления в законную силу решения суда] = R.[Дата вступления в законную силу решения суда (ДД.ММ.ГГГГ)],
		[Наличие документов по решению суда] = R.[Наличие документов по решению суда (оригинал\копия)],
		[Отмена судебного решения] = R.[Отмена судебного решения (1-да/ 0-нет)],
		[Сумма долга, признанная судом, руб.] = cast(R.[Сумма долга, признанная судом (руб.)] AS money),
			[Наличие оригинала приказа/испол. листа] = R.[Наличие оригинала приказа/испол. листа (1-да/0-нет)],
		[Дата выдачи приказа/испол. листа] = R.[Дата выдачи приказа/испол. листа (ДД.ММ.ГГГГ)],
		[Флаг наличия адреса суда, включая индекс] = R.[Флаг наличия адреса суда, включая индекс (1-да/0-нет)],
		R.[Наименование суда],
		R.[Номер исполнительного производства],
		[Дата возбуждения испол. производства] = R.[Дата возбуждения исполн пр-ва (ДД.ММ.ГГГГ)],
		[Дата постановления об окончании ИП] = R.[Дата постановления об окончании ИП (ДД.ММ.ГГГГ)],
			[Наличие полного кредитного досье] = R.[Наличие электронной версии досье (1-да/0-нет)],
			[Наличие электронной версии досье] = R.[Наличие электронной версии досье (1-да/0-нет)],
			[Наличие нотариальной подписи] = R.[Наличие нотариальной подписи (1-имеется / 0 - не имеется)],
		R.[Причина окончания ИП],

		R.[Есть причина исключения],
		R.[Кол-во дней просрочки (на дату выгрузки) меньше 90],
		R.[Неактивный договор],
		R.[Неподходящий статус Клиента],
		R.[Реструктуризация],
		R.[Военные кредитные каникулы],
		R.[Нет Причины остановки начислений],
		R.[Есть судебный иск]

	FROM #t_result_2 AS R
	order by [№ п/п]
END
ELSE BEGIN
	SELECT distinct * 
	FROM #t_result_2
	order by [№ п/п]
END





	
end