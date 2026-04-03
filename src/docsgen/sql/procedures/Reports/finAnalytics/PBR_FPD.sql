



CREATE PROCEDURE [finAnalytics].[PBR_FPD]
	@repmonth date
AS
BEGIN

select
[Контрагент] = a.Client
,[Признак заемщика] = a.isZaemshik
,[Банкротство] = a.isBankrupt
,[Финансовый продукт] = a.finProd
,[Номенклатурная группа] = a.nomenkGroup
,[Продукт] = dwh2.finAnalytics.nomenk2prod(a.nomenkGroup)
,[Номер договора] = a.dogNum
,[Дата договора] = a.dogDate
,[Дата выдачи] = a.saleDate
,[Дата погашения] = a.pogashenieDate
,[Дата погашения с учетом ДС] = a.pogashenieDateDS
,[Сумма займа] = a.dogSum
,[Дата первой просрочки] = a.firsProsDate
,[Задолженность ОД] = a.zadolgOD
,[Задолженность проценты] = a.zadolgPrc
,[Состояние] = a.dogStatus
,[Наличие просрочки] = a.isPros
,[Дата закрыт] = a.CloseDate
,[FPD 0] = b.fpd0
,[FPD 4] = b.fpd4
,[FPD 7] = b.fpd7
,[FPD 30] = b.fpd30


from dwh2.finanalytics.pbr_monthly a
left join [dwh2].[dbo].[dm_OverdueIndicators] b on a.dogNum = b.Number
where a.repmonth = @repmonth

END
