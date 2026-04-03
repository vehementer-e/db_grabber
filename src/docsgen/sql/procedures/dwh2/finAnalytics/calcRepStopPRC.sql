


CREATE PROC [finAnalytics].[calcRepStopPRC] 
    @repmonth date
AS
BEGIN

    DECLARE @sp_name NVARCHAR(255) = OBJECT_NAME(@@PROCID)
	--старт лог
       declare @log_IsError bit=0
       declare @log_Mem nvarchar(2000)	='Ok'
       declare @mainPrc nvarchar(255)=''
      if (select OBJECT_ID( N'tempdb..#mainPrc')) is not null
                          set @mainPrc=(select top(1) sp_name from #mainPrc)
      exec finAnalytics.sys_log @sp_name,0, @mainPrc

    DECLARE @procStartTimeraw datetime = getdate()  -- Переменная фиксирует начало выполнения
    DECLARE @subject NVARCHAR(255) = CONCAT (
				'Выполнение процедуры '
				,'"Расчет данных для отчета по Остановке начислений %%"'
				)
       
    begin try

	delete from dwh2.[finAnalytics].[repStopPRC] where [Отчетный месяц] = @repmonth

    declare @maxDateToFormula date ='2200-01-01'


			---Данные по Проводкам
			declare @dateFrom datetime = dateadd(year,2000,@repmonth)
			declare @dateToTmp datetime = dateadd(day,1,dateadd(year,2000,eomonth(@repmonth)))
			declare @dateTo datetime = dateadd(second,-1,@dateToTmp)

			--select @dateFrom, @dateTo

			Drop table if exists #prov

			select
			dogNum = l1.[Номер договора ДТ]
			--,l1.[СчетДтКод]
			--,l1.[СчетКтКод]
			,[sumMonth] = sum(l1.[Сумма БУ])
			,[sumEOM] = sum(l1.[Сумма БУ eom])

			into #prov

			from(
			SELECT 

			[Дата операции] = cast(dateadd(year,-2000,a.Период) as date)
			,[СчетДтКод] = Dt.Код
			,[СчетКтКод] = Kt.Код

			,[КлиентДТ] = cldt.Наименование
			,[КлиентДТ_ИНН] = cldt.ИНН

			,[Сумма БУ] = isnull(a.Сумма,0)
			,[Сумма БУ eom] = case when cast(dateadd(year,-2000,a.Период) as date) = EOMONTH(@repmonth) then isnull(a.Сумма,0) else 0 end
			,[Содержание] = a.Содержание

			,[Номер договора ДТ] = crdt.Номер
			--,[Дата договора ДТ] = crdt.Дата

			from stg._1cUMFO.РегистрБухгалтерии_БНФОБанковский a
			left join stg._1cUMFO.ПланСчетов_БНФОБанковский Dt on a.СчетДт=Dt.Ссылка and dt.ПометкаУдаления=0
			left join stg._1cUMFO.ПланСчетов_БНФОБанковский Kt on a.СчетКт=Kt.Ссылка and kt.ПометкаУдаления=0
			left join stg._1cUMFO.Справочник_БНФОДоговорыКредитовИДепозитов crdt on a.СубконтоDt2_Ссылка=crdt.Ссылка and crdt.ПометкаУдаления=0
			left join stg._1cUMFO.Справочник_Контрагенты cldt on a.Субконтоdt1_Ссылка=cldt.Ссылка

			where a.Период between @dateFrom and @dateTo
			and a.Активность=01
			and (
					(Dt.Код = '48802' and substring(Kt.Код,1,3) = '710')
					or
					(Dt.Код = '48502' and substring(Kt.Код,1,3) = '710')
					or
					(Dt.Код = '49402' and substring(Kt.Код,1,3) = '710')
					or
					(Dt.Код = '48702' and substring(Kt.Код,1,3) = '710')
				)
			--and crdt.Номер = '18111702190001'
			--в зависимости от признака заемщика:
			--- сумма проводки Дт 48802/ Кт 710 (по заемщикам с признаком "ФЛ") за отчетный период;
			--- сумма проводки Дт 48502/ Кт 710 (по заемщикам с признаком "ЮЛ") за отчетный период;
			--- сумма проводки Дт 49402/ Кт 710 (по заемщикам с признаком "ИП") за отчетный период;
			--- сумма проводки Дт 48702/ Кт 710 (по заемщикам с признаком "ЮЛ") за отчетный период.
			) l1

			group by
			l1.[Номер договора ДТ]

			INSERT INTO dwh2.[finAnalytics].[repStopPRC]

			select
			[Отчетный месяц]
			,[Контрагент]
			,[Признак заемщика]
			,[Банкротство]
			,[Банкротство Дата]
			,[Номер договора]
			,[Дата выдачи]
			,[Задолженность ОД]
			,[Задолженность проценты]
			,[Итого дней просрочки общая]
			,[Состояние]
			,[Продукт]
			,[Номенклатурная группа]
			,[Фин продукт]
			,[Заморозка (для резервов 30.06.21)]
			,[Заморозка 1.0]
			,[Кредитные каникулы]
			,[Кредитные каникулы по 377-ФЗ]
			,[Дата погашения]
			,[Дата погашения с учетом ДС]
			,[Дата последнего платежа по ОД]
			,[Начисленные %% за месяц]
			,[Начисленные %% последний день месяца]
			,[Начисления в месяц]
			,[Начисления в последний день месяца]
			,[Бакеты]
			,[КК / Не КК]
			,[Остановка начисления]
			,[Дата остановки начисления из ЦМР]
			,[Закончился срок]
			,[Дата окончания срока]
			,[Отсутствие ОД]
			,[Дата погашения ОД]
			,[Причина] = case when l3.[Причина] is null then 'Причина не определена' else l3.[Причина] end
			,[Поколение]
			,[Вид займа]
			,[Группа каналов]
			,[Канал]
			,[Направление]
			,[Продукт от первичного]
			,[Продукт Финансы]
			,[Среднемесячный остаток] 
			,[Группа RBP]
			--into dwh2.[finAnalytics].[repStopPRC]

			from(
			select
			[Отчетный месяц] = l2.[Отчетный месяц]
			,[Контрагент] = l2.Контрагент
			,[Признак заемщика]	= l2.[Признак заемщика]
			,[Банкротство] = l2.Банкротство	
			,[Банкротство Дата] = l2.[Банкротство Дата]	
			,[Номер договора] = l2.[Номер договора]
			,[Дата выдачи] = l2.[Дата выдачи]
			,[Задолженность ОД] = l2.[Задолженность ОД]
			,[Задолженность проценты] = l2.[Задолженность проценты]
			,[Итого дней просрочки общая] = l2.[Итого дней просрочки общая]
			,[Состояние] = l2.Состояние	
			,[Номенклатурная группа] = l2.[Номенклатурная группа]
			,[Фин продукт] = l2.[Фин продукт]
			,[Заморозка (для резервов 30.06.21)] = l2.[Заморозка (для резервов 30.06.21)]
			,[Заморозка 1.0] = l2.[Заморозка 1.0]
			,[Кредитные каникулы] = l2.[Кредитные каникулы]
			,[Кредитные каникулы по 377-ФЗ] = l2.[Кредитные каникулы по 377-ФЗ]
			,[Дата погашения] = l2.[Дата погашения]
			,[Дата погашения с учетом ДС] = l2.[Дата погашения с учетом ДС]
			,[Дата последнего платежа по ОД] = l2.[Дата последнего платежа по ОД]
			,[Начисленные %% за месяц] = l2.[Начисленные %% за месяц]
			,[Начисленные %% последний день месяца] = l2.[Начисленные %% последний день месяца]
			,[Начисления в месяц] = l2.[Начисления в месяц]
			,[Начисления в последний день месяца] = l2.[Начисления в последний день месяца]
			,[Бакеты] = l2.Бакеты	
			,[Продукт] = l2.Продукт	
			,[КК / Не КК] = l2.[КК / Не КК]	
			,[Остановка начисления] = l2.[Остановка начисления]
			,[Дата остановки начисления из ЦМР] = l2.[Дата остановки начисления из ЦМР]
			,[Закончился срок] = l2.[Закончился срок]
			,[Дата окончания срока] = l2.[Дата окончания срока]
			,[Отсутствие ОД] = l2.[Отсутствие ОД]
			,[Дата погашения ОД] = l2.[Дата погашения ОД]
			--	иначе равно значению в столбце до столбца с МИН из (столбец 141;столбец 139;значение в столбце 137;значение в столбце 143) 
			--   ЕСЛИ ОШИБКА, то ЕСЛИ(значение в столбце значение в столбце 45 "Задолженность ОД" =" " или =0, то ="Причина не определена"; "Отсутствие ОД")
			--иначе " "
			,[Причина] = case
								--ЕСЛИ значение в столбце 131="Нет начисл."; то 
								when l2.[Начисления в месяц] = 'Нет начислений' then 
									case 
										when l2.Продукт = 'PDL' then 
										--	ЕСЛИ значение в столбце 134="PDL"; то равно значению в столбце до столбца с МИН из (столбец 141 ;столбец 139;значение в столбце 137);
											case
												when	(isnull(l2.[Дата погашения ОД],cast(getdate() as date)) /*141*/ <=  isnull(l2.[Банкротство Дата],cast(getdate() as date)) /*139*/)
														and 
														(isnull(l2.[Дата погашения ОД],cast(getdate() as date)) /*141*/  <=  isnull(l2.[Дата остановки начисления из ЦМР],cast(getdate() as date)) /*137*/) then l2.[Отсутствие ОД]
									
												when    (isnull(l2.[Банкротство Дата],cast(getdate() as date)) /*139*/ <= isnull(l2.[Дата погашения ОД],cast(getdate() as date)) /*141*/)
														and 
														(isnull(l2.[Банкротство Дата],cast(getdate() as date)) /*139*/ <=  isnull(l2.[Дата остановки начисления из ЦМР],cast(getdate() as date)) /*137*/) then 'Банкрот'
									
												when    (isnull(l2.[Дата остановки начисления из ЦМР],cast(getdate() as date)) /*137*/ <= isnull(l2.[Дата погашения ОД],cast(getdate() as date)) /*141*/)
														and 
														(isnull(l2.[Дата остановки начисления из ЦМР],cast(getdate() as date)) /*137*/ <= isnull(l2.[Банкротство Дата],cast(getdate() as date)) /*139*/) then l2.[Остановка начисления]
												else 'Причина не определена'
											end
										when l2.Продукт != 'PDL' then 
										--	ЕСЛИ значение в столбце 134="Installment" то равно значению в столбце до столбца с МИН из (значение в столбце 143;столбец 139;значение в столбце 137;столбец 141);
											case
												when	(isnull(l2.[Дата погашения ОД],cast(getdate() as date)) /*141*/ <=  isnull(l2.[Банкротство Дата],cast(getdate() as date)) /*139*/)
														and 
														(isnull(l2.[Дата погашения ОД],cast(getdate() as date)) /*141*/  <=  isnull(l2.[Дата остановки начисления из ЦМР],cast(getdate() as date)) /*137*/) 
														and
														(isnull(l2.[Дата погашения ОД],cast(getdate() as date)) /*141*/  <=  isnull(l2.[Дата окончания срока],cast(getdate() as date)) /*143*/) 
														then l2.[Отсутствие ОД]
									
												when    (isnull(l2.[Банкротство Дата],cast(getdate() as date)) /*139*/ <= isnull(l2.[Дата погашения ОД],cast(getdate() as date)) /*141*/)
														and 
														(isnull(l2.[Банкротство Дата],cast(getdate() as date)) /*139*/ <=  isnull(l2.[Дата остановки начисления из ЦМР],cast(getdate() as date)) /*137*/) 
														and 
														(isnull(l2.[Банкротство Дата],cast(getdate() as date)) /*139*/ <=  isnull(l2.[Дата окончания срока],cast(getdate() as date)) /*143*/) 
														then 'Банкрот'

												when    (isnull(l2.[Дата остановки начисления из ЦМР],cast(getdate() as date)) /*137*/ <= isnull(l2.[Дата погашения ОД],cast(getdate() as date)) /*141*/)
														and 
														(isnull(l2.[Дата остановки начисления из ЦМР],cast(getdate() as date)) /*137*/ <= isnull(l2.[Банкротство Дата],cast(getdate() as date)) /*139*/) 
														and 
														(isnull(l2.[Дата остановки начисления из ЦМР],cast(getdate() as date)) /*137*/ <= isnull(l2.[Дата окончания срока],cast(getdate() as date)) /*143*/) 
														then l2.[Остановка начисления]
									
												when    (isnull(l2.[Дата окончания срока],cast(getdate() as date)) /*143*/ <= isnull(l2.[Дата погашения ОД],cast(getdate() as date)) /*141*/)
														and 
														(isnull(l2.[Дата окончания срока],cast(getdate() as date)) /*143*/ <= isnull(l2.[Банкротство Дата],cast(getdate() as date)) /*139*/) 
														and 
														(isnull(l2.[Дата окончания срока],cast(getdate() as date)) /*143*/ <= isnull(l2.[Дата остановки начисления из ЦМР],cast(getdate() as date)) /*143*/) 
														then l2.[Закончился срок]
												else 'Причина не определена'
											end
									end
							else '-'
							end
									
			,[Поколение] = l2.Поколение

			,[Вид займа] = l2.[Вид займа]
			,[Группа каналов] = l2.[Группа каналов]
			,[Канал] = l2.[Канал]
			,[Направление] = l2.[Направление]
			,[Продукт от первичного] = l2.[Продукт от первичного]
			,[Продукт Финансы] = l2.[Продукт Финансы]
			,[Среднемесячный остаток] = l2.[Среднемесячный остаток]
			,[Группа RBP] = l2.[Группа RBP]
			from(
			select 
			[Отчетный месяц] = l1.[Отчетный месяц]
			,[Контрагент] = l1.Контрагент
			,[Признак заемщика]	= l1.[Признак заемщика]
			,[Банкротство] = l1.Банкротство	
			,[Банкротство Дата] = l1.[Банкротство Дата]	
			,[Номер договора] = l1.[Номер договора]
			,[Дата выдачи] = l1.[Дата выдачи]
			,[Задолженность ОД] = l1.[Задолженность ОД]
			,[Задолженность проценты] = l1.[Задолженность проценты]
			,[Итого дней просрочки общая] = l1.[Итого дней просрочки общая]
			,[Состояние] = l1.Состояние	
			,[Номенклатурная группа] = l1.[Номенклатурная группа]
			,[Фин продукт] = l1.[Фин продукт]
			,[Заморозка (для резервов 30.06.21)] = l1.[Заморозка (для резервов 30.06.21)]
			,[Заморозка 1.0] = [Заморозка 1.0]
			,[Кредитные каникулы] = l1.[Кредитные каникулы]
			,[Кредитные каникулы по 377-ФЗ] = l1.[Кредитные каникулы по 377-ФЗ]
			,[Дата погашения] = l1.[Дата погашения]
			,[Дата погашения с учетом ДС] = l1.[Дата погашения с учетом ДС]
			,[Дата последнего платежа по ОД] = l1.[Дата последнего платежа по ОД]
			,[Дата погашения ОД] = l1.[Дата погашения ОД]
			,[Начисленные %% за месяц] = l1.[Начисленные %% за месяц]
			,[Начисленные %% последний день месяца] = l1.[Начисленные %% последний день месяца]
			,[Начисления в месяц] = l1.[Начисления в месяц]
			,[Начисления в последний день месяца] = l1.[Начисления в последний день месяца]
			,[Бакеты] = l1.Бакеты	
			,[Продукт] = l1.Продукт	
			,[КК / Не КК] = l1.[КК / Не КК]	
			,[Остановка начисления] = case
										when l1.[Остановка начисления] = 'Остановка по решению суда банкрот' then 'Банкрот'
										when l1.[Остановка начисления] = 'Остановка по превышению коэф.' then 'Предел начислений (1,5х/1,3х)'
										when l1.[Остановка начисления] = 'Превышение коэффициента без отметки в ЦМР' then 'Предел начислений (1,5х/1,3х)'
										else l1.[Остановка начисления] end
			,[Дата остановки начисления из ЦМР] = l1.[Дата остановки начисления из ЦМР]
			,[Закончился срок] = l1.[Закончился срок]
			,[Отсутствие ОД] = case when l1.[Задолженность ОД] = 0 then 'Отсутствие ОД' else null end
			,[Дата окончания срока] = case
										--Если значение в столбце 136 "Остановка начисления" = "Превышение коэффициента", то проставляется " ";
										when upper(l1.[Остановка начисления]) = upper('Остановка по превышению коэф.') then null
							
										else 
										--         если значение в столбце 134 = "Installment" или "PDL", то:
										case when l1.Продукт in ('Installment','PDL') then  
										--                   если значение в столбце 142 = "Срок закончился", то в ячейке протавляется "-";
											case when l1.[Закончился срок] = 'Срок закончился' then null--''
										--                   если значение в столбце 142 = " ", то в ячейке протавляется "-";
												 when l1.[Закончился срок] = '' then null--''
										--                   иначе значение ячейки = значению в столбце 19 (если оно пустое, то значение в столбце 18)
												 else isnull(l1.[Дата погашения с учетом ДС],l1.[Дата погашения])
											end
										--        если значение в столбце 134 не равно "Installment" или "PDL", то:
											when l1.Продукт not in ('Installment','PDL') then
										--                   если значение в столбце 142 =" ", то в ячейке протавляется "-";
											case when l1.[Закончился срок] = '' then null--'-'
										--                   иначе значение ячейки = значению вв столбце 19 (если оно пустое, то значение в столбце 18)
												 else isnull(l1.[Дата погашения с учетом ДС],l1.[Дата погашения])
											end
										end
										end
			,[Причина] = null
			,[Поколение] = l1.Поколение

			,[Вид займа] = l1.[Вид займа]
			,[Группа каналов] = l1.[Группа каналов]
			,[Канал] = l1.[Канал]
			,[Направление] = l1.[Направление]
			,[Продукт от первичного] = l1.[Продукт от первичного]
			,[Продукт Финансы] = l1.[Продукт Финансы]
			,[Среднемесячный остаток] = l1.[Среднемесячный остаток]
			,[Группа RBP] = l1.[Группа RBP]
			from(

			select
			[Отчетный месяц] = a.repmonth
			,[Контрагент] = a.Client
			,[Признак заемщика] = a.isZaemshik
			,[Банкротство] = case when bnkrupt.Заемщик is not null then 'Да' else 'Нет' end
			,[Банкротство Дата] = case when bnkrupt.Заемщик is not null then bnkrupt.Дата else null end
			,[Номер договора] = a.dogNum
			,[Дата выдачи] = a.saleDate
			,[Задолженность ОД] = a.zadolgOD
			,[Задолженность проценты] = a.zadolgPrc
			,[Итого дней просрочки общая] = a.prosDaysTotal
			,[Состояние] = a.dogStatus
			,[Номенклатурная группа] = a.nomenkGroup
			,[Фин продукт] = a.finProd
			,[Заморозка (для резервов 30.06.21)] = a.isZamoroz1
			,[Заморозка 1.0] = a.isZamoroz2
			,[Кредитные каникулы] = a.isCredKanik
			,[Кредитные каникулы по 377-ФЗ] = a.isCredKanik2
			,[Дата погашения] = a.pogashenieDate
			,[Дата погашения с учетом ДС] = a.pogashenieDateDS
			,[Дата последнего платежа по ОД] = a.ODLastPayDate
			,[Дата погашения ОД] = case
								   --ЕСЛИ значение в значение в столбце 45 "Задолженность ОД" =" " или =0, то:
								   when a.zadolgOD = 0 then	
										--        ЕСЛИ значение в столбце 86 = " ", то = "текущая дата"; 
										case when a.ODLastPayDate is null then EOMONTH(@repmonth)
										--        иначе = графе 86
											else a.ODLastPayDate
											end
									--иначе "-"
									else null end

			--Расчетные значения
			,[Начисленные %% за месяц] = p.sumMonth
			,[Начисленные %% последний день месяца] = p.sumEOM
			,[Начисления в месяц] = case when (p.sumMonth is null or p.sumMonth = 0) and a.saleDate< eomonth(a.repmonth) then 'Нет начислений' else 'Есть начисления' end
			,[Начисления в последний день месяца] = case when p.sumEOM is null or p.sumEOM = 0 then 'Нет начислений' else 'Есть начисления' end
			,[Бакеты] = buck.bucketName
			,[Продукт] = case when a.nomenkGroup is null 
								and (
										upper(a.finProd) like upper('ПТСзайм%')
										or
										upper(a.finProd) like upper('Автомобиль%')
										or
										upper(a.finProd) like upper('Автозайм%')
									) then 'ПТС'
								else dwh2.finAnalytics.nomenk2prod(a.nomenkGroup)
								end
			,[КК / Не КК] = case when kk.dogNum is not null then 'КК'
								 else 'не КК'
								 end
			,[Остановка начисления] = case 
										when prich.dogNum is null then 'Нет остановки'
											else prich.ПричиныОстановкиНачислений
											end
			,[Дата остановки начисления из ЦМР] = prich.Период
			,[Закончился срок] = case when isnull(a.pogashenieDateDS,a.pogashenieDate) is null then '' --"Если значение в столбце 19 и в столбце 18 = "" "", то проставляется "" "";
									  --если значение в столбце 134 = ""Installment"" или ""PDL"", то:
									  when dwh2.finAnalytics.nomenk2prod(a.nomenkGroup) in ('Installment','PDL') then  
													--если значение в столбце 19 (если оно пустое, то значение в столбце 18)  <= 30.09.2022, то в ячейке проставляется признак ""Срок закончился до 30.09.2022"";
											case when isnull(a.pogashenieDateDS,a.pogashenieDate) <= '2022-09-30' then 'Срок закончился до 30.09.2022' 
													--если значение в столбце 19 (если оно пустое, то значение в столбце 18)  <= 31.07.2023, то  в ячейке проставляется признак  ""Превышение коэффициента без отметки в ЦМР"";
												 when isnull(a.pogashenieDateDS,a.pogashenieDate) <= '2023-07-31' then 'Предел начислений (1,5х/1,3х)' 
													--если значение в столбце 19 (если оно пустое, то значение в столбце 18) > 31.07.2023 и <= последний день отчетного месяца, то  в ячейке проставляется признак ""Срок закончился""
												 when isnull(a.pogashenieDateDS,a.pogashenieDate) > '2023-07-31' and isnull(a.pogashenieDateDS,a.pogashenieDate) <= eomonth(a.repmonth) then 'Срок закончился' 
											else '' end
									  --если значение в столбце 134 не равно ""Installment"" или ""PDL"", то:
									  when (dwh2.finAnalytics.nomenk2prod(a.nomenkGroup) not in ('Installment','PDL') or a.nomenkGroup is null) then  
									  --если значение в столбце 19 (если оно пустое, то значение в столбце 18)  <= последний день отчетного месяца, то  в ячейке проставляется признак ""Срок закончился"";иначе "" """				
										case when isnull(a.pogashenieDateDS,a.pogashenieDate) <= eomonth(a.repmonth) then 'Срок закончился' 
										else '' end
									end
			,[дата окончания срока] = null							
			,[Причина] = null
			,[Поколение] = case 
								--ЕСЛИ значение года в графе 15 >=2016 и <=2019); то = "2016-2019"; 
								when year(a.saleDate) between 2016 and 2019 then '2016-2019'
								--иначе = году выдачи в графе 15
								else cast(year(a.saleDate) as varchar)
								end
			--,rn=row_Number() over (Partition by a.dogNum order by a.dogNum)
			,[Вид займа] = [isnew]	
			,[Группа каналов] = [finChannelGroup]	
			,[Канал] = [finChannel]	
			,[Направление] = [finBusinessLine]	
			,[Продукт от первичного] = [prodFirst]	
			,[Продукт Финансы] = [productType]
			,[Среднемесячный остаток] = [dayRestAVG]
			,[Группа RBP] = [RBP_GROUP]
			from dwh2.finAnalytics.pbr_monthly a
			left join [dwh2].[finAnalytics].[SPR_bucketsForReserv] buck on buck.sprName = 'Для массива Лена' 
																		and a.prosDaysTotal between buck.prosFrom and buck.prosTo
			 -------Привязываем КК обычные
					left join (
					SELECT 
						 [dogNum] = a.number
						,[KKBegDate] = isnull(a.dateClientRequest,a.period_start)
						,ROW_NUMBER() over (partition by a.number order by isnull(a.dateClientRequest,a.period_start) /*desc*/) rn
					 FROM dwh2.dbo.dm_restructurings a
					 where 1=1
						and a.period_start<=EOMONTH(@REPMONTH)
						and upper(a.operation_type) in (upper('Кредитные каникулы'),upper('Заморозка 1.0'))
						--and upper(a.reason_credit_vacation) = upper('Военные кредитные каникулы')
					) kk on a.dogNum=kk.dogNum and kk.rn=1
			----Привязываем причину остановки
			left join (
			select 
				дсд.ДоговорЗайма,
				dogNum = д.Код,
				Период = cast(dateadd(year, -2000, Период) as date),
				ПричиныОстановкиНачислений = пон.Наименование

			from stg._1cCMR.РегистрСведений_ДополнительныеСвойстваДоговоров дсд
			inner join stg._1cCMR.Справочник_Договоры д on д.Ссылка = дсд.ДоговорЗайма
			inner join stg._1cCMR.Справочник_ПричиныОстановкиНачислений пон
				on пон.Ссылка = дсд.Значение_Ссылка
					and дсд.Значение_ТипСсылки = 0x000019FD
			) prich on a.dogNum = prich.dogNum and prich.Период <= eomonth(@repmonth)

			--Привязываем банкротов
			left join (
					select [Дата] = cast(dateadd(year,-2000,a.Дата) as date)
					,[Заемщик] = b.Наименование
					,[Исключить] = case when 
										c.[client] is not null and @repmonth between c.nonBunkruptStartDate and isnull(c.nonBunkruptEndDate,getdate())
										then 1 else 0 end
					,ROW_NUMBER() over (Partition by b.Наименование order by a.Дата desc) rn

					from stg._1cUMFO.Документ_АЭ_БанкротствоЗаемщика a
					left join stg._1cUMFO.Справочник_Контрагенты b on a.Контрагент=b.Ссылка
					left join dwh2.[finAnalytics].[SPR_notBunkrupt] c on b.Наименование = c.[client]
					where 1=1
					and a.ПометкаУдаления =  0x00
					and a.Проведен=0x01
					and cast(dateadd(year,-2000,a.Дата) as date) <=EOMONTH(@repmonth)
					) bnkrupt on upper(a.Client)=upper(bnkrupt.[Заемщик]) and bnkrupt.rn=1

			--Привязываем проводки 
			left join #prov p on a.dogNum = p.dogNum


			where a.repmonth = @repmonth
			--and a.dogNum='23101921313503'
			) l1
			) l2
			--where l1.[Закончился срок] is null
			) l3
	

    
	DECLARE @procEndTimeraw datetime = getdate()   -- Переменная фиксирует окончание выполнения

    DECLARE @procStartTime varchar(40) = format(@procStartTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @procEndTime varchar(40) =  format(@procEndTimeraw,'dd.MM.yyyy HH:mm:ss', 'ru-RU')
    DECLARE @timeDuration varchar(40) = concat(cast (datediff(second,@procStartTimeraw,@procEndTimeraw) as varchar),' секунд')

    DECLARE @maxDateRep NVARCHAR(30)
    set @maxDateRep = cast((select max([Отчетный месяц]) from [finAnalytics].[repStopPRC]) as varchar)
	
    
	--/*Фиксация времени расчета*/
	--update dwh2.[finAnalytics].[reportReglament]
	--set lastCalcDate = getdate(),[maxDataDate] = @maxDateRep1
	--where [reportUID]= 8

	--/*Обновление данных PBI*/
	--EXEC [C3-SQL-BIRS01].RS_Jobs.dbo.StartReportJob
	--@subscription_id = 'e5c59e3f-d9ee-46a9-b496-1779c0536a04',
	--@await_success = 0

    DECLARE @msg_good NVARCHAR(2048) = CONCAT (
				'Успешное выполнение процедуры - данные расчитаны за :'
				,FORMAT( eoMONTH(@REPMONTH), 'MMMM yyyy', 'ru-RU' )
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
                ,'Максимальная дата: '
                ,@maxDateRep
				)

	declare @emailList varchar(255)=''
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1,2,31))
    
	EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_good
			,@body_format = 'TEXT'
			,@subject = @subject;

	
	--финиш
   exec dwh2.finAnalytics.sys_log  @sp_name,1, @mainPrc

    end try
    
    begin catch

    DECLARE @msg_bad NVARCHAR(2048) = CONCAT (
				'Ошибка выполнения процедуры - '
				,@sp_name
				,'. Ошибка '
				,ERROR_MESSAGE()
				)
	----кэтч

   set  @log_IsError =1
   set  @log_Mem =ERROR_MESSAGE()
   exec finAnalytics.sys_log  @sp_name,1, @mainPrc,  @log_IsError,  @log_Mem

    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
	
	set @emailList = (select STRING_AGG(email,';') from finAnalytics.emailList where emailUID in (1))
    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'Default'
			,@recipients = @emailList
			,@copy_recipients = ''
			,@body = @msg_bad
			,@body_format = 'TEXT'
			,@subject = @subject;
        
    throw 51000 
			,@msg_bad
			,1;
    

    end catch
END
