





CREATE PROCEDURE [finAnalytics].[repForgive4]
	@repmonth date
	with recompile

AS
BEGIN

select 
pokazatel = 'Сверено с оборотами' 
,sumAmountAll = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth )
,sumAmountPTS = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'ПТС')
,sumAmountIL = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'IL')
,sumAmountPDL = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'PDL')
,sumAmountAuto = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'Автокредит')
,sumAmountBI = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'Big Installment')
,sumAmountBZ = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'БЗ')
,rowNum = 1

union all
--https://tracker.yandex.ru/FINA-11
select 
pokazatel = 'Прочие доходы (расходы) (52802,53803; сч.71701,71702)' 
,sumAmountAll = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and [Наименование счёта Дт.] like '%52802%53803%' and upper([Есть в отчёте по акциям]) = 'НЕТ')
,sumAmountPTS = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'ПТС' and [Наименование счёта Дт.] like '%52802%53803%' and upper([Есть в отчёте по акциям]) = 'НЕТ')
,sumAmountIL = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'IL' and [Наименование счёта Дт.] like '%52802%53803%' and upper([Есть в отчёте по акциям]) = 'НЕТ')
,sumAmountPDL = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'PDL' and [Наименование счёта Дт.] like '%52802%53803%' and upper([Есть в отчёте по акциям]) = 'НЕТ')
,sumAmountAuto = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'Автокредит' and [Наименование счёта Дт.] like '%52802%53803%' and upper([Есть в отчёте по акциям]) = 'НЕТ')
,sumAmountBI = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'Big Installment' and [Наименование счёта Дт.] like '%52802%53803%' and upper([Есть в отчёте по акциям]) = 'НЕТ')
,sumAmountBZ = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'БЗ' and [Наименование счёта Дт.] like '%52802%53803%' and upper([Есть в отчёте по акциям]) = 'НЕТ')
,rowNum = 2

union all
--https://tracker.yandex.ru/FINA-11
select 
pokazatel = 'Штрафы и пени по займам предоставленным (52402 сч.71701)' 
,sumAmountAll = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and [Наименование счёта Дт.] like '%52402%' and upper([Есть в отчёте по акциям]) = 'НЕТ')--and [Признак мем.ордера] = 'Да')
,sumAmountPTS = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'ПТС' and [Наименование счёта Дт.] like '%52402%' and upper([Есть в отчёте по акциям]) = 'НЕТ')--and [Признак мем.ордера] = 'Да')
,sumAmountIL = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'IL' and [Наименование счёта Дт.] like '%52402%' and upper([Есть в отчёте по акциям]) = 'НЕТ')--and [Признак мем.ордера] = 'Да')
,sumAmountPDL = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'PDL' and [Наименование счёта Дт.] like '%52402%' and upper([Есть в отчёте по акциям]) = 'НЕТ')--and [Признак мем.ордера] = 'Да')
,sumAmountAuto = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'Автокредит' and [Наименование счёта Дт.] like '%52402%' and upper([Есть в отчёте по акциям]) = 'НЕТ')--and [Признак мем.ордера] = 'Да')
,sumAmountBI = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'Big Installment' and [Наименование счёта Дт.] like '%52402%' and upper([Есть в отчёте по акциям]) = 'НЕТ')--and [Признак мем.ордера] = 'Да')
,sumAmountBZ = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'БЗ' and [Наименование счёта Дт.] like '%52402%' and upper([Есть в отчёте по акциям]) = 'НЕТ')--and [Признак мем.ордера] = 'Да')
,rowNum = 3

union all

select 
pokazatel = 'Всего Не коллекшн' 
,sumAmountAll = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and ([Наименование счёта Дт.] like '%52802%53803%' or [Наименование счёта Дт.] like '%52402%' and [Признак мем.ордера] = 'Да'))
,sumAmountPTS = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'ПТС' and ([Наименование счёта Дт.] like '%52802%53803%' or [Наименование счёта Дт.] like '%52402%' and [Признак мем.ордера] = 'Да'))
,sumAmountIL = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'IL' and ([Наименование счёта Дт.] like '%52802%53803%' or [Наименование счёта Дт.] like '%52402%' and [Признак мем.ордера] = 'Да'))
,sumAmountPDL = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'PDL' and ([Наименование счёта Дт.] like '%52802%53803%' or [Наименование счёта Дт.] like '%52402%' and [Признак мем.ордера] = 'Да'))
,sumAmountAuto = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'Автокредит' and ([Наименование счёта Дт.] like '%52802%53803%' or [Наименование счёта Дт.] like '%52402%' and [Признак мем.ордера] = 'Да'))
,sumAmountBI = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'Big Installment' and ([Наименование счёта Дт.] like '%52802%53803%' or [Наименование счёта Дт.] like '%52402%' and [Признак мем.ордера] = 'Да'))
,sumAmountBZ = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'БЗ' and ([Наименование счёта Дт.] like '%52802%53803%' or [Наименование счёта Дт.] like '%52402%' and [Признак мем.ордера] = 'Да'))
,rowNum = 4

union all

select 
pokazatel = 'Разница' 
,sumAmountAll = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and ([Наименование счёта Дт.] not like '%52802%53803%' and [Наименование счёта Дт.] like '%52402%' and [Признак мем.ордера] = 'Нет'))
,sumAmountPTS = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'ПТС' and ([Наименование счёта Дт.] not like '%52802%53803%' and [Наименование счёта Дт.] like '%52402%' and [Признак мем.ордера] = 'Нет'))
,sumAmountIL = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'IL' and ([Наименование счёта Дт.] not like '%52802%53803%' and [Наименование счёта Дт.] like '%52402%' and [Признак мем.ордера] = 'Нет'))
,sumAmountPDL = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'PDL' and ([Наименование счёта Дт.] not like '%52802%53803%' and [Наименование счёта Дт.] like '%52402%' and [Признак мем.ордера] = 'Нет'))
,sumAmountAuto = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'Автокредит' and ([Наименование счёта Дт.] not like '%52802%53803%' and [Наименование счёта Дт.] like '%52402%' and [Признак мем.ордера] = 'Нет'))
,sumAmountBI = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'Big Installment' and ([Наименование счёта Дт.] not like '%52802%53803%' and [Наименование счёта Дт.] like '%52402%' and [Признак мем.ордера] = 'Нет'))
,sumAmountBZ = (select isnull(sum([Сумма проводки]),0) from dwh2.finAnalytics.repForgive3 where repmonth=@repmonth and  [Номенклатурная группа] = 'БЗ' and ([Наименование счёта Дт.] not like '%52802%53803%' and [Наименование счёта Дт.] like '%52402%' and [Признак мем.ордера] = 'Нет'))
,rowNum = 5

  
END
