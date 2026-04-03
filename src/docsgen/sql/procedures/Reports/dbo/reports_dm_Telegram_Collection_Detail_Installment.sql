CREATE procedure [dbo].[reports_dm_Telegram_Collection_Detail_Installment]
as
begin
SELECT
di.ДоговорНомер,  
 cast(di.ДатаОперации as date) as ДатаОперации,
 Sum(di.ОДОплачено + di.ПроцентыОплачено + di.ПениОплачено + di.ГосПошлинаОплачено
+di.ПереплатаНачислено -di.ПереплатаОплачено) as Сумма
  ,di.КоличествоПолныхДнейПросрочки
  ,di.Бакет3
FROM
  dbo.[dm_Telegram_Collection_Detail_Installment] di
inner join STG.[_1Ccmr].Справочник_Договоры AS d
	on di.Договор =  d.Ссылка
		inner join [Stg].[_1cCMR].[Справочник_типыПродуктов] cmr_ТипыПродуктов
			on d.ТипПродукта = cmr_ТипыПродуктов.ссылка	
where cast(ДатаОперации as date) = cast(GetDate() as date)
and lower(cmr_ТипыПродуктов.ИдентификаторMDS) = 'installment'
group by ДоговорНомер, cast(ДатаОперации as date) ,КоличествоПолныхДнейПросрочки
  ,Бакет3
having  Sum(di.ОДОплачено + di.ПроцентыОплачено + di.ПениОплачено + di.ГосПошлинаОплачено
+di.ПереплатаНачислено -di.ПереплатаОплачено) > 0
order by di.КоличествоПолныхДнейПросрочки, di.ДоговорНомер



end