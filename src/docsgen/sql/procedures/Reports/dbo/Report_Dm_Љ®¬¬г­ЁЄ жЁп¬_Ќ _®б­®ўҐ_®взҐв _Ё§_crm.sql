-- =======================================================
-- Create: 8.02.2022. А.Никитин
-- Description:	DWH-1412. Изменить источник данных для отчета 
--		SalesDepartment. ОКК. Коммуникациям на основе отчета из crm
-- =======================================================
--exec dbo.Report_Dm_Коммуникациям_На_основе_отчета_из_crm '2022-01-21', '2022-01-31'
--CREATE procedure dbo.Report_Dm_Коммуникациям_На_основе_отчета_из_crm
CREATE procedure dbo.Report_Dm_Коммуникациям_На_основе_отчета_из_crm
	@dateBegin date,
	@dateEnd date
as
begin
	select 
		Звонок = T.Звонок_Ссылка,
		ДатаВзаимодействия = cast(ДатаВзаимодействия as datetime) + cast(ВремяВзаимодействия as datetime),
		T.ФИО_оператора,
		T.НомерТелефонаОператора,
		T.Направление,
		T.ФИО_клиента,
		T.НомерТелефона,
		T.ДлительностьЗвонка,
		T.ТипОбращения,
		T.ДеталиОбращения,
		T.ТипУслуги,
		T.Описание,
		T.Результат,
		T.ДатаНазначенияЗадачи,
		T.ВремяНазначенияЗадачи,
		T.НазваниеЗадачи,
		T.РезультатЗадачи,
		T.ПричинаОтказа,
		T.ЛИД_ID,
		T.ЛИД,
		T.Session_id,
		ЗаявкаНаЗайм = T.НомерЗаявки,
		[просроченная сумма на дату коммуникации]=nullif(sb.overdue,0),
		[просроченная сумма на текущий момент] = nullif(sb2.overdue,0),
		reportdate = getdate()
	from dbo.dm_Все_коммуникации_На_основе_отчета_из_crm as T

		-- остатки на дату коммуникации
		left join dbo.dm_CMRStatBalance_2 as sb with(nolock)
			on sb.external_id = T.НомерЗаявки
			and sb.d = cast(T.ДатаВзаимодействия as date)
			and sb.overdue > 0
		-- остатки на текущий момент
		left join dbo.dm_CMRStatBalance_2 as sb2 with(nolock) 
			on sb2.external_id = T.НомерЗаявки
			and sb2.d = cast(getdate() as date)
			and sb2.overdue > 0	
	where T.ДатаВзаимодействия between @dateBegin and @dateEnd
		and T.Звонок_Ссылка is not null
	--order by T.ДатаВзаимодействия, T.ВремяВзаимодействия
	order by T.ДатаВзаимодействия, T.ВремяВзаимодействия, T.ФИО_оператора
	--order by T.ДатаВзаимодействия, T.ВремяВзаимодействия, T.Звонок_Ссылка
end
