




-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-10-07
-- Description:	Альтернативный вариант с акцентом на договора
--             exec [dbo].[ReportDashboard_Collection_Task_SP]  
-- =============================================
CREATE     PROCEDURE [dbo].[ReportDashboard_Collection_Task_SP]
as
begin

	SET NOCOUNT ON;
	--Declare  @DateReport date = cast(dateAdd(day,0,GetDate()) as date)
	Set datefirst 1

	-- получим три месяца месяц
	declare  @DateCalculate date = cast(dateadd(month,0, dateadd(year,0,getdate())) as date)
	--declare  @DateBegin date = cast(dateadd(month,-3, dateadd(year,0,getdate())) as date)
	declare  @DateBegin date = cast('2020-09-01' as date)
	--declare  @dt_begin_of_month date = cast(format(@DateBegin,'yyyyMM01') as date)
	declare  @dt_begin_of_month date = cast(format(@DateBegin,'yyyyMM01') as date)
	declare  @dt_next_month date = @DateCalculate-- cast(dateadd(month,1, @dt_begin_of_month) as date)
	--declare  @dt_next_month date =  cast(dateadd(month,3, @dt_begin_of_month) as date)
	--select @DateCalculate

	select  @DateCalculate, @DateBegin, @dt_begin_of_month, @dt_next_month
	-- получим список дат
	if object_id('tempdb.dbo.#calend') is not null drop table #calend

	select DT
	into  #calend
	FROM [dwh2].[Dictionary].[calendar]
	--where dt>=@dt_begin_of_month and dt<=@dt_next_month
	where dt>=@dt_begin_of_month and dt<=@dt_next_month

		-- найдем договора, у которых есть ИЛ
		-- учитываем только принятые ИЛ
	if object_id('tempdb.dbo.#loans_ip') is not null drop table #loans_ip
		select  l.id
		, (iif(eo.Type = 1, eo.Amount, 0)) 'Сумма Обеспечительные меры'
		, (iif(eo.Type = 2, eo.Amount, 0)) 'Сумма Денежное требование'
		, (iif(eo.Type = 3, eo.Amount, 0)) 'Сумма Обращение взыскания'
		, (iif(eo.Type = 4, eo.Amount, 0)) 'Сумма Взыскание и обращение взыскания'
		, (iif(eo.Type is null, eo.Amount, 0)) 'Сумма тип ИЛ не определ'
		, (isnull(eo.Amount,0)) 'Сумма всего'
		, (eo.id) 'идентификатор ИЛ'
		, eo.AcceptanceDate датаПринятияИЛ
		, датаПринятияИЛСоставная = cast(coalesce (eo.AcceptanceDate, eo.ReceiptDate, eo.Date, eo.createdate) as date)
		
		--, sum(iif(eo.Type = 1, eo.Amount, 0)) 'Сумма Обеспечительные меры'
		--, sum(iif(eo.Type = 2, eo.Amount, 0)) 'Сумма Денежное требование'
		--, sum(iif(eo.Type = 3, eo.Amount, 0)) 'Сумма Обращение взыскания'
		--, sum(iif(eo.Type = 4, eo.Amount, 0)) 'Сумма Взыскание и обращение взыскания'
		--, sum(iif(eo.Type is null, eo.Amount, 0)) 'Сумма тип ИЛ не определ'
		--, sum(isnull(eo.Amount,0)) 'Сумма всего'
		--, count(eo.id) 'Количество ИЛ'
	into #loans_ip
	FROM  [Stg].[_Collection].Deals l
		 join [Stg].[_Collection].JudicialProceeding  jp on l.Id = jp.DealId
		 join [Stg].[_Collection].JudicialClaims jc on jp.Id = jc.JudicialProceedingId -- суб
		 join [Stg].[_Collection].[EnforcementOrders]  eo  on jc.Id = eo.JudicialClaimId
		 where eo.Accepted = 1
		--Group by l.id
		--where eo.id is not null
		--select * from #loans_ip

	-- получим договора для матрицы
	if object_id('tempdb.dbo.#loans') is not null drop table #loans
	SELECT 

		c.id as ClientIdFull
		, cst_deals.Name as 'СтадияДоговора'	
		, isnull(c.LastName,'') + ' '  + isnull(c.Name,'') + ' ' + isnull(c.MiddleName,'') 'ClientFIO' 
	
		, l.id as DealIdFull
		, cst_client.Name as 'СтадияКлиента'
		, l.Number

		, stsp.NameStatus СтатусКлиента-- StatusOfSubprocessId 
	
		, iif(StatusOfSubprocessId = 2,1,0) ОжиданиеПоКлиенту
		--, taction.dateWait ДатаОжидания
		, iif(empIP.LastName is null , 'Не назначен', empIP.LastName + ' '  + empIP.FirstName + ' ' + empIP.MiddleName) 'КураторИП'
		, iif(empSP.LastName is null , 'Не назначен', empSP.LastName + ' '  + empSP.FirstName + ' ' + empSP.MiddleName) 'КураторСП'
		--, iif(l_ip.id is not null,1,0) 'Есть ИЛ'
		--, l_ip.[Количество ИЛ]
		--, l_ip.[Сумма всего]
		--, l_ip.[Сумма Взыскание и обращение взыскания]
		--, l_ip.[Сумма Денежное требование]
		--, l_ip.[Сумма Обеспечительные меры]
		--, l_ip.[Сумма Обращение взыскания]
		--, l_ip.[Сумма тип ИЛ не определ]
	
	into #loans
	FROM  [Stg].[_Collection].Deals l
		left join [Stg].[_Collection].customers c on c.id=l.IdCustomer
		left join stg._collection.[StatusOfSubprocess] stsp on c.StatusOfSubprocessId = stsp.id
		left join  [Stg].[_Collection].[CollectingStage] cst_deals  on  l.StageId = cst_deals.id
		left join  [Stg].[_Collection].[CollectingStage] cst_client  on  c.[IdCollectingStage] = cst_client.id
		left join stg.[_Collection].Employee empIP  on c.[ClaimantExecutiveProceedingId]  = empIP.id
		-- left join #loans_ip l_ip on  l_ip.id = l.id
		left join stg.[_Collection].Employee empSP  on c.ClaimantLegalId  = empSP.id
	 





	-- получим матрицу для заполенния (чтобы получить таблицу фактов)
	if object_id('tempdb.dbo.#loans_calend') is not null drop table #loans_calend

	SELECT calend.dt --Дата
		  , datepart(iso_week,calend.dt) as Неделя
		  , dateadd(dd,-datepart(dw,DATEFROMPARTS(year(calend.dt),1,1))-6+datepart(iso_week,calend.dt)*7,DATEFROMPARTS(year(calend.dt),1,1)) НачалоНедели
		  , dateadd(dd,-datepart(dw,DATEFROMPARTS(year(calend.dt),1,1))+datepart(iso_week,calend.dt)*7,DATEFROMPARTS(year(calend.dt),1,1)) КонецНедели
		  , cast(format((calend.dt), 'yyyy-MM-01') as date)  НачалоМесяца
		  , eomonth(cast(format((calend.dt), 'yyyy-MM-01') as date)) КонецМесяца
		  ,l.*
	into #loans_calend
	FROM #calend calend, #loans  l

	-- получим принадлежность задачи
	 if object_id('tempdb.dbo.#t_group') is not null drop table #t_group
	;with
	collectiong_group as 
	(
	select 'ИП' Collecting, id, name from [Stg].[_Collection].[StrategyActionTask]
	where name in ('Проверка ИЛ'
, 'Сформировать заявление в суд на исправление ошибок в ИЛ'
, 'Направить заявление в суд на исправление ошибок в ИЛ'
, 'Мониторинг принятия к производству (ручная подача)'
, 'Поиск и верификация СКИП-контактов'
, 'Выезд'
, 'Мониторинг - контакт с клиентом'
, 'Мониторинг - контроль ПДП'
, 'Ручное определение отдела ФССП'
, 'Формирование заявлений на возбуждение ИП'
, 'Запрос недостающей информации для формирования заявления на возбуждение ИП'
, 'Отправка заявления в ФССП'
, 'Мониторинг получения заявления в ФССП'
, 'Мониторинг возбуждения ИП'
, 'Коммуникация с приставом'
, 'Проверка действий СПИ'
, 'Запрос обзорной справки'
, 'Запрос недостающей информации для запроса обзорной справки'
, 'Мониторинг получения обзорной справки'
, 'Арест авто СПИ'
, 'Жалоба на бездействие'
, 'Заполнение недостающей информации для жалобы на бездействие'
, 'Контроль поступления взысканных ДС с депозита на РС компании, взысканных со счетов должника'
, 'Получение актуальных фото ПЗ, состояния авто, реальной стоимости'
, 'Пауза подачи иска'
, 'Принятие решения о дальнейших действиях в отношении просроченная задолженность'
, 'Контроль назначения 1-ых торгов'
, 'Контроль результата 1-ых торгов'
, 'Контроль поступления ДС после 1 торгов'
, 'Переоценка после 1-х торгов'
, 'Контроль назначения 2-ых торгов'
, 'Контроль результата 2-ых торгов'
, 'Решение о дальнейших шагах при несостоявшихся 2 торгах'
, 'Контроль поступления ДС после 2 торгов'
, 'Контроль получения Предложения о принятии на баланс'
, 'Проставить дальнейшие действия по делу'
, 'Прекращение ИП'
, 'Повторное возбуждение ИП'
, 'Проверка и согласование реестра передачи в КА'
, 'Акцепт реестра'
, 'Отправка уведомлений о передаче в КА'
, 'Передача реестра в КА'
, 'Плановый отзыв реестра'
, 'Проверка актуальности СКИП-контактов'
, 'Внеплановый отзыв'
, 'Внеплановый отзыв (запрещающий статус клиента или ПДП)'
, 'Получение ИЛ (после исправлений)'
, 'Проверка ИЛ (после исправлений)'
, 'Безнадёжное взыскание'
, 'Проверка недостающей информации для подачи иска'
)
union all
select 'СП' Collecting, id, name from [Stg].[_Collection].[StrategyActionTask]
	where name in  ('Формирование требований'
,'Отправка требований'
,'Ожидание'
,'Пауза подачи иска'
,'Подготовка иска'
,'Отправка иска должнику'
,'Ожидание документа «Платежное поручение на оплату госпошлины»'
,'Отправка иска в суд (эл. Подача)'
,'Направление заявление на отказ от иска и возврат госпошлины'
,'Ручная подача иска в суд (подготовка искового заявления)'
,'Отправка иска в суд (ручная подача)'
,'Заполнение недостающей информации для направления заявления на отказ от иска и возврат госпошлины (Погашение ПЗ)'
,'Заполнение недостающей информации для направления заявления на отказ от иска и возврат госпошлины (Банкрот или Смерть подтвержденная)'
,'Мониторинг принятия к производству'
,'Мониторинг дела в суде (заседание)'
,'Получение решения'
,'Мониторинг вступления решения в силу'
,'Мониторинг оплат при мировом соглашении'
,'Направить заявление в суд на выдачу ИЛ'
,'Получение ИЛ'
,'Проверка ИЛ'
,'Сформировать заявление в суд на исправление ошибок в ИЛ'
,'Направить заявление в суд на исправление ошибок в ИЛ'
,'Мониторинг принятия к производству (ручная подача)'
)
union all
select 'Требования в работе' Collecting, id, name from [Stg].[_Collection].[StrategyActionTask]
	where name in  (
		  'Формирование требований'
		, 'Заполнение недостающей информации'
		, 'Отправка требований'
		, 'Ожидание'
		, 'Ручное определение подсудности'
		, 'Пауза подачи иска'
		, 'Отправка иска должнику'
		, 'Ожидание документа «Платежное поручение на оплату госпошлины»'
		, 'Отправка иска в суд (эл. Подача)'
		--, 'Ручная подача иска в суд (подготовка искового заявления)'
		, 'Отправка иска в суд (ручная подача)'
	    --, 'Заполнение недостающей информации для направления заявления на отказ от иска и возврат госпошлины (Погашение ПЗ)'
		--, 'Заполнение недостающей информации для направления заявления на отказ от иска и возврат госпошлины (Банкрот или Смерть подтвержденная)'
		)
union all
select 'В суде' Collecting, id, name from [Stg].[_Collection].[StrategyActionTask]
	where name in  (
			'Мониторинг принятия к производству'
		  , 'Мониторинг принятия к производству (ручная подача)'
		  , 'Мониторинг дела в суде (заседание)'
		  , 'Получение решения'
		  , 'Направить заявление в суд на выдачу ИЛ'
		  , 'Получение ИЛ'
		)
union all
select 'Поступившие новые требования' Collecting, id, name from [Stg].[_Collection].[StrategyActionTask]
	where name in  (
			  'Формирование требований'
			, 'Заполнение недостающей информации'
			, 'Отправка требований'
			)
union all
select 'Подано в суд' Collecting, id, name from [Stg].[_Collection].[StrategyActionTask]
	where name in  (
			  'Отправка иска в суд (эл. Подача)'
			  --, 'Ручная подача иска в суд (подготовка искового заявления)'
			  --, 'Отправка иска в суд (ручная подача)'
				)
union all
select 'Договора в работе' Collecting, id, name from [Stg].[_Collection].[StrategyActionTask]
	where name in  (
		  'Формирование требований'
		, 'Заполнение недостающей информации'
		, 'Отправка требований'
		, 'Ожидание'
		, 'Ручное определение подсудности'
		, 'Пауза подачи иска'
		, 'Отправка иска должнику'
		, 'Ожидание документа «Платежное поручение на оплату госпошлины»'
		, 'Отправка иска в суд (эл. Подача)'
		--, 'Ручная подача иска в суд (подготовка искового заявления)'
		, 'Отправка иска в суд (ручная подача)'
	    --, 'Заполнение недостающей информации для направления заявления на отказ от иска и возврат госпошлины (Погашение ПЗ)'
		--, 'Заполнение недостающей информации для направления заявления на отказ от иска и возврат госпошлины (Банкрот или Смерть подтвержденная)'
		  , 'Мониторинг принятия к производству'
		  , 'Мониторинг принятия к производству (ручная подача)'
		  , 'Мониторинг дела в суде (заседание)'
		  , 'Получение решения'
		  , 'Направить заявление в суд на выдачу ИЛ'
		  , 'Получение ИЛ'
		)
)
Select * 
into #t_group
from collectiong_group

--select *,id from #t_group
--group by id



	 -- получим количество задач по договорам и статусам
  if object_id('tempdb.dbo.#ttask') is not null drop table #ttask
  SELECT 
		 ta.id
		,dealId
		,DateSettingsTask
		,PlannedDateOfDecision
		,ActualDateOfDecision
		, case 
			when StatusID = 0 then 'В работе' 
			when StatusID = 1 then 'Обрабатывается' 
			when StatusID = 2 then 'Выполнено' 
			when StatusID = 3 then 'Отменена' 
			else 'Не указан' 
		end as 'Статус задачи'
		,sat.name 'Задача'
		,sat.id idNameTask
		, iif(emp.LastName is null , 'Не назначен', emp.LastName + ' '  + emp.FirstName + ' ' + emp.MiddleName) 'Сотрудник'
		, ФактическаяДлительностьВыполнения = datediff(day,DateSettingsTask,ActualDateOfDecision)
		, ПланируемаяДлительностьВыполнения = datediff(day,DateSettingsTask,isnull(PlannedDateOfDecision, '2025-01-01'))
into #ttask
FROM [Stg].[_Collection].[TaskAction] ta
left join [Stg].[_Collection].[StrategyActionTask] sat
on ta.StrategyActionTaskId = sat.id
left join  stg.[_Collection].Employee emp 
on emp.id = ta.EmployeeId
--where --StrategyActionTaskId <=26
--name in (select name from #t_group where 'ИП' = Collecting )



--select * from #ttask where  dealid=25100

-- посчитаем по каждому дню по каждому договору динамику
-- 
  -- получим количество задач по договорам и статусам
  if object_id('tempdb.dbo.#ttask_calend') is not null drop table #ttask_calend
select c.*
, dealid
, id
, Задача
, Сотрудник
, [Статус задачи]
, iif(cast(t.DateSettingsTask as date) = dt,1,0) 'СозданаЗадача'
, iif(cast(t.ActualDateOfDecision as date) = dt and [Статус задачи] <> 'Отменена',1,0) 'ОконченаЗадача'
, iif(cast(t.ActualDateOfDecision as date) = dt and [Статус задачи] = 'Отменена',1,0) 'ОтмененаЗадача'

, iif(cast(t.ActualDateOfDecision as date) = dt,1,0) 'ОконченаИлиОтмененаЗадача'
, iif(cast(t.PlannedDateOfDecision as date) = dt 
and isnull(t.PlannedDateOfDecision, cast('2099-01-01' as date))  < isnull(t.ActualDateOfDecision, cast('2099-01-01' as date))
--and isnull(t.ActualDateOfDecision, cast('2099-01-01' as date)) > dt
,1,0) 'ПросроченаЗадача'

, iif((cast(t.DateSettingsTask as date) <= dt and [Статус задачи] = 'В работе') or (cast(t.DateSettingsTask as date) <= dt and cast(t.ActualDateOfDecision as date)>dt) ,1,0) 'В работе на дату'
, iif(cast(t.ActualDateOfDecision as date) <= dt and [Статус задачи] = 'Отменена' ,1,0) 'Отменена на дату'
, iif(cast(t.ActualDateOfDecision as date) <= dt and [Статус задачи] = 'Выполнено' ,1,0) 'Выполнена на дату'
, iif(cast(t.DateSettingsTask as date) <= dt and [Статус задачи] = 'Обрабатывается' ,1,0) 'Обрабатывается на дату'
, iif(cast(t.PlannedDateOfDecision as date) < dt  -- не просрочен
	and isnull(t.PlannedDateOfDecision, cast('2099-01-01' as date))  >= isnull(t.ActualDateOfDecision, cast('1900-01-01' as date)) -- не просрочен
	--and [Статус задачи] not in ('Отменена', 'Выполнено') 
	,0,1) 'Просрочена на дату'

	--03 > 01  true - не просрочнео
	--03 > 01 true - не просрочено
	--  выполнено  в выполнено   true не просрочено
, iif(cast(t.DateSettingsTask as date) <= dt ,1,0) 'Всего задач на дату'
,cast(t.DateSettingsTask as date) DateSettingsTask
,cast( t.ActualDateOfDecision as date) ActualDateOfDecision
,cast(t.PlannedDateOfDecision as date) PlannedDateOfDecision
--, t.*
, iif([Статус задачи] = 'В работе',1,0) 'В работе по статусу'
, iif([Статус задачи] = 'Обрабатывается',1,0) 'Обрабатывается по статусу'
, iif([Статус задачи] = 'Отменена',1,0) 'Отменена по статусу'
, iif([Статус задачи] = 'Выполнено',1,0) 'Выполнено по статусу'
, iif(id is not null,1,0) 'Всего задач по статусу'
, iif(Task_IP.id1 is not null,1,0) 'Задача ИП'
, iif(Task_SP.id2 is not null,1,0) 'Задача СП'



into #ttask_calend
 from  #loans_calend c 
 left join #ttask t on t.dealid = c.DealIdFull --#calend c
 left join (select id id1 from #t_group where 'ИП' = Collecting) Task_IP on Task_IP.id1 = t.idNameTask
 left join (select id id2 from #t_group where 'СП' = Collecting) Task_SP on Task_SP.id2 = t.idNameTask
 --where dealid=22665
 --where [Статус задачи] = 'Отменена'

  drop table if exists dbo.dm_CollectionJudicailProceeding_Tasks
  Select * 
  into dbo.dm_CollectionJudicailProceeding_Tasks
  from #ttask_calend

  --select top 100 * from dbo.dm_CollectionEnforcementProceeding_Tasks where [Длительность выполнения задачи] is not null

  end
