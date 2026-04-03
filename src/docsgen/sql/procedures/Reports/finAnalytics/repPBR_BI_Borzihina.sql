

CREATE PROCEDURE [finAnalytics].[repPBR_BI_Borzihina]
        @repmonth date
        --,@repdate date
AS
BEGIN

--IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dwh2.[finAnalytics].#ID_LIST') AND type in (N'U'))
DROP TABLE IF  EXISTS dwh2.[finAnalytics].#ID_LIST

Create table dwh2.[finAnalytics].#ID_LIST(
    [ID] bigint NOT NULL
    )

insert into dwh2.[finAnalytics].#ID_LIST
select
a.ID
from dwh2.finAnalytics.PBR_MONTHLY a
where a.REPMONTH=@REPMONTH --and a.REPDATE=@REPDATE

/* select * from #ID_LIST */
-------------------------------------------------------------------

select
[Отчетный месяц] = @repmonth
,[Дата выгрузки] = eomonth(@repmonth)
,[Контрагент] = a.[Client]
,[Признак заемщика] = a.[isZaemshik]
,[Банкротство] = a.[isBankrupt]
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
,[ПДН на дату выдачи] = a.[PDNOnSaleDate]
,[Итого дней просрочки общая] = a.[prosDaysTotal]
,[Задолженность ОД] = a.[zadolgOD]
,[Задолженность проценты] = a.[zadolgPrc]
,[Сумма пени счета] = a.[penyaSum]
,[Сумма госпошлин счета] = a.[gosposhlSum]
,[Резерв ОД] = a.[reservOD]
,[Резерв проценты] = a.[reservPRC]
,[Состояние] = a.[dogStatus]
,[Сумма резерва БУ ОД] = a.[reservBUODSum]
,[Сумма резерва БУ проценты] = a.[reservBUpPrcSum]
,[Ставка на дату выдачи] = a.[stavaOnSaleDate]
,[Ставка на дату формирования отчета] =a.[stavaOnRepDate]
,[ПДН на отчетную дату] = a.[PDNOnRepDate]
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
,[Агент партнер] = c.[Агент партнер]
,[Признак КП снижающий ставку] = c.[Признак КП снижающий ставку]
,[CP info] = c.CP_info
,[Дата закрыт] = a.[CloseDate]
,[Способ закрытия обязательств] = a.[zakritObazType]
,[Пролонгация PDL] = a.isProlongPDL
,[Дата ДС] = a.isProlongPDLDate
from dwh2.finAnalytics.PBR_MONTHLY a
inner join #ID_LIST b on b.ID=a.ID
left join Analytics.dbo.mv_loans c on a.dogNum=c.код and c.[Дата выдачи день]<=eomonth(@repmonth)

END
