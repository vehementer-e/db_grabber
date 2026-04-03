
CREATE PROCEDURE [finAnalytics].[repPBR_BI_Gerdev]
        @repmonth date
        --,@repdate date
AS
BEGIN


declare @source int
declare @repDateMonthly date 
declare @repDateWeekly date

set @repDateWeekly = (select
                        maxRepDate = max(repdate)
                        from dwh2.finAnalytics.PBR_WEEKLY a
                        where a.REPDATE <= eomonth(@repmonth))

set @repDateMonthly = (select
                        maxRepDate = max(eomonth(@repmonth))
                        from dwh2.finAnalytics.PBR_monthly a
                        where a.repmonth <= eomonth(@repmonth))


if @repDateWeekly > @repDateMonthly 
set @source = 2
else set @source = 1

if @source = 1
begin
select
[Отчетный месяц] = @repmonth
,[Дата выгрузки] = a.[dataLoadDate]
,[Контрагент] = a.[Client]
,[Признак заемщика] = a.[isZaemshik]
,[МСП на дату выдачи] = a.isMSPbyDogDate
,[МСП на отчетную дату] = a.isMSPbyRepDate
,[Финансовый продукт] = a.[finProd]
,[Номер договора] = a.[dogNum]
,[Дата договора] = a.[dogDate]
,[Дата выдачи] = a.[saleDate]
,[Способ выдачи займа] = a.[saleType]
,[Дата погашения] = a.[pogashenieDate]
,[Дата погашения с учетом ДС] = a.[pogashenieDateDS]
,[Дата окончания по КК] = a.[KKEndDate]
,[Срок договора в месяцах] = a.[dogPeriodMonth]
,[Срок договора в днях] = a.[dogPeriodDays]
,[Сумма займа] = a.[dogSum]
,[Наличие залога поручительства] = a.[isDogPoruch]
,[ПДН на дату выдачи] = a.[PDNOnSaleDate]
,[Рефинансирование] = a.[isRefinance]
,[Реструктуризирован] = a.[isRestruk]
,[Итого дней просрочки общая] = a.[prosDaysTotal]
,[Состояние] = a.[dogStatus]
,[Ставка на дату выдачи] = a.[stavaOnSaleDate]
,[ПДН на отчетную дату] = a.[PDNOnRepDate]
,[Наличие просрочки] = a.[isPros]
,[Номенклатурная группа] = a.[nomenkGroup]
,[Акция 0%] = a.[isAkcia]

,[Дата выдачи_BI] = C.[Дата выдачи день]
,[Сумма_BI] = c.[Сумма]
,[Срок_BI] = c.[Срок]
,[Текущая ставка_BI] =c.[Текущая процентная ставка]
,[Канал_BI] = c.Канал
,[product_BI] = c.product
,[Вид займа_BI] = c.[Вид займа]
,[Сумма комиссионных продуктов снижающих ставку_BI] = c.[Сумма комиссионных продуктов снижающих ставку]
,[Сумма комиссионных продуктов_BI] = c.[Сумма комиссионных продуктов]
,[Сумма комиссионных продуктов Carmoney Net_BI] = c.[Сумма комиссионных продуктов Carmoney Net]
,[Сумма расторжений по КП_BI] = c.[Сумма расторжений по КП]
,[Онлайн выдача_BI] = case 
     when c.[Способ оформления займа] in ('Лкк клиента', 'МП') or c.[Признак ПЭП3]=1 then 1 
	 else 0 
                  end

,[Вид займа] = a.isnew
,[Группа каналов] = a.finChannelGroup
,[Канал (определяется по источнику заявки)] = a.finChannel
,[Направление] = a.finBusinessLine
,[Продукт от первичного] = a.prodFirst
,[Продукт Финансы] = a.productType
,[Продукт для Планов] = map.Продукт
,[Группа RBP] = a.[RBP_GROUP]
from dwh2.finAnalytics.PBR_MONTHLY a
left join Analytics.dbo.mv_loans c on a.dogNum=c.код and c.[Дата выдачи день]<=eomonth(@repmonth)
left join dwh2.[finAnalytics].[SPR_PBR_prodMapping] map on 
			--map.[Вид займа] = a.isnew
			--and map.[Группа каналов] = a.finChannelGroup
			--and map.[Канал (определяется по источнику заявки)] = a.finChannel
			--and map.[Направление] = a.finBusinessLine
			--and map.[Продукт от первичного] = a.prodFirst
			--and map.[Продукт Финансы] = a.productType
			isnull(map.[Вид займа],'-') = isnull(a.isnew,'-')
			and isnull(map.[Группа каналов],'-') = isnull(a.finChannelGroup,'-')
			and isnull(map.[Канал (определяется по источнику заявки)],'-') = isnull(a.finChannel,'-')
			and isnull(map.[Направление],'-') = isnull(a.finBusinessLine,'-')
			and isnull(map.[Продукт от первичного],'-') = isnull(a.prodFirst,'-')
			and isnull(map.[Продукт Финансы],'-') = isnull(a.productType,'-')


where a.repmonth = @repmonth--@repDateMonthly
end

if @source = 2
begin
select
[Отчетный месяц] = @repDateWeekly
,[Дата выгрузки] = a.[dataLoadDate]
,[Контрагент] = a.[Client]
,[Признак заемщика] = a.[isZaemshik]
,[МСП на дату выдачи] = a.isMSPbyDogDate
,[МСП на отчетную дату] = a.isMSPbyRepDate
,[Финансовый продукт] = a.[finProd]
,[Номер договора] = a.[dogNum]
,[Дата договора] = a.[dogDate]
,[Дата выдачи] = a.[saleDate]
,[Способ выдачи займа] = a.[saleType]
,[Дата погашения] = a.[pogashenieDate]
,[Дата погашения с учетом ДС] = a.[pogashenieDateDS]
,[Дата окончания по КК] = a.[KKEndDate]
,[Срок договора в месяцах] = a.[dogPeriodMonth]
,[Срок договора в днях] = a.[dogPeriodDays]
,[Сумма займа] = a.[dogSum]
,[Наличие залога поручительства] = a.[isDogPoruch]
,[ПДН на дату выдачи] = a.[PDNOnSaleDate]
,[Рефинансирование] = a.[isRefinance]
,[Реструктуризирован] = a.[isRestruk]
,[Итого дней просрочки общая] = a.[prosDaysTotal]
,[Состояние] = a.[dogStatus]
,[Ставка на дату выдачи] = a.[stavaOnSaleDate]
,[ПДН на отчетную дату] = a.[PDNOnRepDate]
,[Наличие просрочки] = a.[isPros]
,[Номенклатурная группа] = a.[nomenkGroup]
,[Акция 0%] = a.[isAkcia]

,[Дата выдачи_BI] = C.[Дата выдачи день]
,[Сумма_BI] = c.[Сумма]
,[Срок_BI] = c.[Срок]
,[Текущая ставка_BI] =c.[Текущая процентная ставка]
,[Канал_BI] = c.Канал
,[product_BI] = c.product
,[Вид займа_BI] = c.[Вид займа]
,[Сумма комиссионных продуктов снижающих ставку_BI] = c.[Сумма комиссионных продуктов снижающих ставку]
,[Сумма комиссионных продуктов_BI] = c.[Сумма комиссионных продуктов]
,[Сумма комиссионных продуктов Carmoney Net_BI] = c.[Сумма комиссионных продуктов Carmoney Net]
,[Сумма расторжений по КП_BI] = c.[Сумма расторжений по КП]
,[Онлайн выдача_BI] = case 
     when c.[Способ оформления займа] in ('Лкк клиента', 'МП') or c.[Признак ПЭП3]=1 then 1 
	 else 0 
                  end

,[Вид займа] = a.isnew
,[Группа каналов] = a.finChannelGroup
,[Канал (определяется по источнику заявки)] = a.finChannel
,[Направление] = a.finBusinessLine
,[Продукт от первичного] = a.prodFirst
,[Продукт Финансы] = a.productType
,[Продукт для Планов] = map.Продукт

from dwh2.finAnalytics.PBR_weekly a
left join Analytics.dbo.mv_loans c on a.dogNum=c.код and c.[Дата выдачи день]<=@repDateWeekly
left join dwh2.[finAnalytics].[SPR_PBR_prodMapping] map on 
			isnull(map.[Вид займа],'-') = isnull(a.isnew,'-')
			and isnull(map.[Группа каналов],'-') = isnull(a.finChannelGroup,'-')
			and isnull(map.[Канал (определяется по источнику заявки)],'-') = isnull(a.finChannel,'-')
			and isnull(map.[Направление],'-') = isnull(a.finBusinessLine,'-')
			and isnull(map.[Продукт от первичного],'-') = isnull(a.prodFirst,'-')
			and isnull(map.[Продукт Финансы],'-') = isnull(a.productType,'-')


where a.repdate = @repDateWeekly

end

END
