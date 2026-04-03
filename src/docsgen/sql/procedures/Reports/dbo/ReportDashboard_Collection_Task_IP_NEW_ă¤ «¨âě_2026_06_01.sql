-- =============================================
-- Author:		Sabanin A.A.
-- Create date: 2020-09-18
-- Description:	
--             exec [dbo].[ReportDashboard_Collection_Task_IP]  -- '2020-07-31'
-- =============================================
CREATE PROC dbo.ReportDashboard_Collection_Task_IP_NEW
	@isDebug int = 0
as
begin

	SET NOCOUNT ON;
	--Declare  @DateReport date = cast(dateAdd(day,0,GetDate()) as date)
	Set datefirst 1

	SELECT @isDebug = isnull(@isDebug, 0)
    DECLARE @StartDate datetime, @row_count int

	-- получим три месяца месяц
	declare  @DateCalculate date = cast(dateadd(month,0, dateadd(year,0,getdate())) as date)
	--declare  @DateBegin date = cast(dateadd(month,-3, dateadd(year,0,getdate())) as date)
	declare  @DateBegin date = cast('2020-07-01' as date)
	--declare  @dt_begin_of_month date = cast(format(@DateBegin,'yyyyMM01') as date)
	declare  @dt_begin_of_month date = cast(format(@DateBegin,'yyyyMM01') as date)
	declare  @dt_next_month date = @DateCalculate-- cast(dateadd(month,1, @dt_begin_of_month) as date)
	--declare  @dt_next_month date =  cast(dateadd(month,3, @dt_begin_of_month) as date)
	--select @DateCalculate

	select  @DateCalculate, @DateBegin, @dt_begin_of_month, @dt_next_month

	--test
	SELECT @dt_begin_of_month = @DateCalculate

	-- получим список дат
	if object_id('tempdb.dbo.#calend') is not null drop table #calend

	select DT
	into  #calend
	FROM [dwh2].[Dictionary].[calendar]
	--where dt>=@dt_begin_of_month and dt<=@dt_next_month
	where dt>=@dt_begin_of_month and dt<=@dt_next_month


		-- найдем дату погашения (чтобы понять, что закрыт)
	 if object_id('tempdb.dbo.#endedContracts') is not null drop table #endedContracts
	   
	  select d.Код
		   --, Период=dateadd(year,-2000,max(sd.Период))				
		   , Период = cast(dateadd(year,-2000,max(sd.Период)) AS date)
		into  #endedContracts
		from stg._1cCMR.РегистрСведений_СтатусыДоговоров sd
		join stg._1ccmr.Справочник_Договоры d on d.Ссылка=sd.договор
		join stg._1ccmr.Справочник_СтатусыДоговоров  ssd on ssd.Ссылка=sd.Статус
	   where ssd.Наименование='Погашен' --and d.Код in (select Number from #loans)
	   group by d.Код


	   	drop table if exists #bankropt_state_conf;
		with
		bankropt_state_conf as
		(
		select distinct c.id
				 from stg._Collection.CustomerStatus cs
				 join  stg._Collection.Customers c on cs.CustomerId=c.id
						 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
						 where st.name  in ('Банкрот подтверждённый') 
						 and IsActive = 1
		)

		select * into #bankropt_state_conf from bankropt_state_conf

		drop table if exists #bankropt_state_not_conf;
		with
		bankropt_state_not_conf as
		(
		select distinct c.id
				 from stg._Collection.CustomerStatus cs
				 join  stg._Collection.Customers c on cs.CustomerId=c.id
						 join stg._collection.CustomerState st on st.id=cs.CustomerStateId
						 where st.name  in (N'Банкрот неподтверждённый')
						 and IsActive = 1
		)

		select * into #bankropt_state_not_conf from bankropt_state_not_conf

		-- найдем договора, у которых есть ИЛ
	if object_id('tempdb.dbo.#loans_ip') is not null drop table #loans_ip
	--select distinct l.id
	--into #loans_ip
	--FROM  [Stg].[_Collection].Deals l
	--	left join [Stg].[_Collection].JudicialProceeding  jp on l.Id = jp.DealId
	--	left join [Stg].[_Collection].JudicialClaims jc on jp.Id = jc.JudicialProceedingId -- суб
	--	left join [Stg].[_Collection].[EnforcementOrders]  eo  on jc.Id = eo.JudicialClaimId
	--	where eo.id is not null

	SELECT @StartDate = getdate(), @row_count = 0

		select  l.id
		, sum(iif(eo.Type = 1, eo.Amount, 0)) 'Сумма Обеспечительные меры'
		, sum(iif(eo.Type = 2, eo.Amount, 0)) 'Сумма Денежное требование'
		, sum(iif(eo.Type = 3, eo.Amount, 0)) 'Сумма Обращение взыскания'
		, sum(iif(eo.Type = 4, eo.Amount, 0)) 'Сумма Взыскание и обращение взыскания'
		, sum(iif(eo.Type is null, eo.Amount, 0)) 'Сумма тип ИЛ не определ'
		, sum(isnull(eo.Amount,0)) 'Сумма всего'
		, count(eo.id) 'Количество ИЛ'
	into #loans_ip
	FROM  [Stg].[_Collection].Deals l
		 join [Stg].[_Collection].JudicialProceeding  jp on l.Id = jp.DealId
		 join [Stg].[_Collection].JudicialClaims jc on jp.Id = jc.JudicialProceedingId -- суб
		 join [Stg].[_Collection].[EnforcementOrders]  eo  on jc.Id = eo.JudicialClaimId
		Group by l.id
		--where eo.id is not null
		--select * from #loans_ip

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #loans_ip', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	SELECT @StartDate = getdate(), @row_count = 0

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
	, iif(l_ip.id is not null,1,0) 'Есть ИЛ'
	, l_ip.[Количество ИЛ]
	, l_ip.[Сумма всего]
	, l_ip.[Сумма Взыскание и обращение взыскания]
	, l_ip.[Сумма Денежное требование]
	, l_ip.[Сумма Обеспечительные меры]
	, l_ip.[Сумма Обращение взыскания]
	, l_ip.[Сумма тип ИЛ не определ]
	, ec.Период ДатаПогашения
	, iif( bankropt.Id is null, 0,1) as 'Банкрот подтвержденный'
	, iif( bankropt_nc.Id is null, 0,1) as 'Банкрот неподтвержденный' 
	into #loans
	FROM  [Stg].[_Collection].Deals l
		left join [Stg].[_Collection].customers c on c.id=l.IdCustomer
		--left join (
		--			select 
		--				  CustomerId,StatusId
		--				, max(DateSettingsTask) as dateWait 
		--			from [Stg].[_Collection].[TaskAction] 
		--			--where StatusId=2 -- выполнено
		--			group by CustomerId, StatusId
		--			having count(CustomerId) >1
		--		 ) taction 
					
		--		on taction.CustomerId= c.id and taction.StatusId=c.StatusOfSubprocessId
		left join stg._collection.[StatusOfSubprocess] stsp on c.StatusOfSubprocessId = stsp.id
		left join  [Stg].[_Collection].[CollectingStage] cst_deals  on  l.StageId = cst_deals.id
		left join  [Stg].[_Collection].[CollectingStage] cst_client  on  c.[IdCollectingStage] = cst_client.id
		left join stg.[_Collection].Employee empIP  on c.[ClaimantExecutiveProceedingId]  = empIP.id
	 left join #loans_ip l_ip on  l_ip.id = l.id
	 left join stg.[_Collection].Employee empSP  on c.ClaimantLegalId  = empSP.id
	 left join #endedContracts ec on ec.Код = l.Number
	 left join #bankropt_state_conf bankropt on bankropt.Id = l.id
	 left join #bankropt_state_not_conf bankropt_nc on bankropt_nc.Id = l.id
	 
	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #loans', @row_count, datediff(SECOND, @StartDate, getdate())
	END



	SELECT @StartDate = getdate(), @row_count = 0

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

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #loans_calend', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	CREATE CLUSTERED INDEX clix_Id_Дата ON #loans_calend(DealIdFull)


	SELECT @StartDate = getdate(), @row_count = 0

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
)
Select * 
into #t_group
from collectiong_group

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #t_group', @row_count, datediff(SECOND, @StartDate, getdate())
	END

--select count(*),id from #t_group
--group by id


	SELECT @StartDate = getdate(), @row_count = 0

	 -- получим количество задач по договорам и статусам
  if object_id('tempdb.dbo.#ttask') is not null drop table #ttask
  SELECT 
		 ta.id
		,dealId
		,DateSettingsTask = cast(DateSettingsTask AS date)
		,PlannedDateOfDecision = cast(PlannedDateOfDecision AS date)
		,ActualDateOfDecision = cast(ActualDateOfDecision AS date)
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

--OLD
/*
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
*/

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #ttask', @row_count, datediff(SECOND, @StartDate, getdate())
	END

	CREATE CLUSTERED INDEX clix_DealId ON #ttask(DealId)

--select top 100 * from #ttask

  --drop table if exists dbo.dm_CollectionJudicialProceeding_Task
  --Select deal.Number, cst_client.Name as 'StageClientFull', task.* 
  --into dbo.dm_CollectionJudicialProceeding_Task
  --from 
  --#ttask  task 
  --left join   [Stg].[_Collection].Deals deal on deal.id = task.DealId
  --left join [Stg].[_Collection].customers c on c.id=deal.IdCustomer
  --left join  [Stg].[_Collection].[CollectingStage] cst_client  on  c.[IdCollectingStage] = cst_client.id

--select * from #ttask where  dealid=25100


	SELECT @StartDate = getdate(), @row_count = 0

-- посчитаем по каждому дню по каждому договору динамику
-- 
  -- получим количество задач по договорам и статусам
  if object_id('tempdb.dbo.#ttask_calend') is not null drop table #ttask_calend
select c.*
, iif(c.ДатаПогашения <= dt,1,0) 'Договор погашен'
, dealid
, id
, Задача
, Сотрудник
, [Статус задачи]
, iif(t.DateSettingsTask = dt,1,0) 'СозданаЗадача'
, iif(t.ActualDateOfDecision = dt and [Статус задачи] <> 'Отменена',1,0) 'ОконченаЗадача'
, iif(t.ActualDateOfDecision = dt and [Статус задачи] = 'Отменена',1,0) 'ОтмененаЗадача'

, iif(t.ActualDateOfDecision = dt,1,0) 'ОконченаИлиОтмененаЗадача'
, iif(t.PlannedDateOfDecision = dt 
AND isnull(t.PlannedDateOfDecision, cast('2099-01-01' as date)) < isnull(t.ActualDateOfDecision, cast('2099-01-01' as date))
--and isnull(t.ActualDateOfDecision, cast('2099-01-01' as date)) > dt
,1,0) 'ПросроченаЗадача'

, iif((t.DateSettingsTask <= dt and [Статус задачи] = 'В работе')
	OR (t.DateSettingsTask <= dt and t.ActualDateOfDecision > dt) ,1,0) 'В работе на дату'
, iif(t.ActualDateOfDecision <= dt and [Статус задачи] = 'Отменена' ,1,0) 'Отменена на дату'
, iif(t.ActualDateOfDecision <= dt and [Статус задачи] = 'Выполнено' ,1,0) 'Выполнена на дату'
, iif(t.DateSettingsTask <= dt and [Статус задачи] = 'Обрабатывается' ,1,0) 'Обрабатывается на дату'
, iif(t.PlannedDateOfDecision < dt  -- не просрочен
	and isnull(t.PlannedDateOfDecision, cast('2099-01-01' as date))  >= isnull(t.ActualDateOfDecision, cast('1900-01-01' as date)) -- не просрочен
	--and [Статус задачи] not in ('Отменена', 'Выполнено') 
	,0,1) 'Просрочена на дату'

	--03 > 01  true - не просрочнео
	--03 > 01 true - не просрочено
	--  выполнено  в выполнено   true не просрочено
, iif(t.DateSettingsTask <= dt ,1,0) 'Всего задач на дату'
,t.DateSettingsTask AS DateSettingsTask
,t.ActualDateOfDecision AS ActualDateOfDecision
,t.PlannedDateOfDecision AS PlannedDateOfDecision
--, t.*
, iif([Статус задачи] = 'В работе',1,0) 'В работе по статусу'
, iif([Статус задачи] = 'Обрабатывается',1,0) 'Обрабатывается по статусу'
, iif([Статус задачи] = 'Отменена',1,0) 'Отменена по статусу'
, iif([Статус задачи] = 'Выполнено',1,0) 'Выполнено по статусу'
, iif(id is not null,1,0) 'Всего задач по статусу'
, iif(Task_IP.id1 is not null,1,0) 'Задача ИП'
, iif(Task_SP.id2 is not null,1,0) 'Задача СП'

-- факт выполенния учтем в представлении
, [Осталось дней] = datediff(day,dt,isnull(PlannedDateOfDecision, '2025-01-01'))
--, [Осталось дней] = iif(cast(isnull(t.ActualDateOfDecision, '2025-01-01') as date) < dt,datediff(day,dt,isnull(PlannedDateOfDecision, '2025-01-01')),null)
, iif(t.ActualDateOfDecision = dt,ФактическаяДлительностьВыполнения,null) 'Длительность выполнения задачи'
, [Отличия от плана] = iif(t.ActualDateOfDecision = dt, ПланируемаяДлительностьВыполнения - ФактическаяДлительностьВыполнения,null)

into #ttask_calend
 from  #loans_calend c 
 left join #ttask t on t.dealid = c.DealIdFull --#calend c
 left join (select id id1 from #t_group where 'ИП' = Collecting) Task_IP on Task_IP.id1 = t.idNameTask
 left join (select id id2 from #t_group where 'СП' = Collecting) Task_SP on Task_SP.id2 = t.idNameTask
 --where dealid=22665
 --where [Статус задачи] = 'Отменена'



/*
select c.*
, iif(cast(c.ДатаПогашения  as date) <= dt,1,0) 'Договор погашен'
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

-- факт выполенния учтем в представлении
, [Осталось дней] = datediff(day,dt,isnull(PlannedDateOfDecision, '2025-01-01'))
--, [Осталось дней] = iif(cast(isnull(t.ActualDateOfDecision, '2025-01-01') as date) < dt,datediff(day,dt,isnull(PlannedDateOfDecision, '2025-01-01')),null)
, iif(cast(t.ActualDateOfDecision as date) = dt,ФактическаяДлительностьВыполнения,null) 'Длительность выполнения задачи'
, [Отличия от плана] = iif(cast(t.ActualDateOfDecision as date) = dt, ПланируемаяДлительностьВыполнения - ФактическаяДлительностьВыполнения,null)

into #ttask_calend
 from  #loans_calend c 
 left join #ttask t on t.dealid = c.DealIdFull --#calend c
 left join (select id id1 from #t_group where 'ИП' = Collecting) Task_IP on Task_IP.id1 = t.idNameTask
 left join (select id id2 from #t_group where 'СП' = Collecting) Task_SP on Task_SP.id2 = t.idNameTask
 --where dealid=22665
 --where [Статус задачи] = 'Отменена'
*/



	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT #ttask_calend', @row_count, datediff(SECOND, @StartDate, getdate())
	END



	SELECT @StartDate = getdate(), @row_count = 0

  --DWH-1764 
  TRUNCATE TABLE dbo.dm_CollectionEnforcementProceeding_Tasks_NEW

  INSERT dbo.dm_CollectionEnforcementProceeding_Tasks_NEW
  (
      dt,
      Неделя,
      НачалоНедели,
      КонецНедели,
      НачалоМесяца,
      КонецМесяца,
      ClientIdFull,
      СтадияДоговора,
      ClientFIO,
      DealIdFull,
      СтадияКлиента,
      Number,
      СтатусКлиента,
      ОжиданиеПоКлиенту,
      КураторИП,
      КураторСП,
      [Есть ИЛ],
      [Количество ИЛ],
      [Сумма всего],
      [Сумма Взыскание и обращение взыскания],
      [Сумма Денежное требование],
      [Сумма Обеспечительные меры],
      [Сумма Обращение взыскания],
      [Сумма тип ИЛ не определ],
      ДатаПогашения,
      [Банкрот подтвержденный],
      [Банкрот неподтвержденный],
      [Договор погашен],
      dealid,
      id,
      Задача,
      Сотрудник,
      [Статус задачи],
      СозданаЗадача,
      ОконченаЗадача,
      ОтмененаЗадача,
      ОконченаИлиОтмененаЗадача,
      ПросроченаЗадача,
      [В работе на дату],
      [Отменена на дату],
      [Выполнена на дату],
      [Обрабатывается на дату],
      [Просрочена на дату],
      [Всего задач на дату],
      DateSettingsTask,
      ActualDateOfDecision,
      PlannedDateOfDecision,
      [В работе по статусу],
      [Обрабатывается по статусу],
      [Отменена по статусу],
      [Выполнено по статусу],
      [Всего задач по статусу],
      [Задача ИП],
      [Задача СП],
      [Осталось дней],
      [Длительность выполнения задачи],
      [Отличия от плана]
  )
  Select 
      dt,
      Неделя,
      НачалоНедели,
      КонецНедели,
      НачалоМесяца,
      КонецМесяца,
      ClientIdFull,
      СтадияДоговора,
      ClientFIO,
      DealIdFull,
      СтадияКлиента,
      Number,
      СтатусКлиента,
      ОжиданиеПоКлиенту,
      КураторИП,
      КураторСП,
      [Есть ИЛ],
      [Количество ИЛ],
      [Сумма всего],
      [Сумма Взыскание и обращение взыскания],
      [Сумма Денежное требование],
      [Сумма Обеспечительные меры],
      [Сумма Обращение взыскания],
      [Сумма тип ИЛ не определ],
      ДатаПогашения,
      [Банкрот подтвержденный],
      [Банкрот неподтвержденный],
      [Договор погашен],
      dealid,
      id,
      Задача,
      Сотрудник,
      [Статус задачи],
      СозданаЗадача,
      ОконченаЗадача,
      ОтмененаЗадача,
      ОконченаИлиОтмененаЗадача,
      ПросроченаЗадача,
      [В работе на дату],
      [Отменена на дату],
      [Выполнена на дату],
      [Обрабатывается на дату],
      [Просрочена на дату],
      [Всего задач на дату],
      DateSettingsTask,
      ActualDateOfDecision,
      PlannedDateOfDecision,
      [В работе по статусу],
      [Обрабатывается по статусу],
      [Отменена по статусу],
      [Выполнено по статусу],
      [Всего задач по статусу],
      [Задача ИП],
      [Задача СП],
      [Осталось дней],
      [Длительность выполнения задачи],
      [Отличия от плана]
  --into dbo.dm_CollectionEnforcementProceeding_Tasks_NEW
  from #ttask_calend

	SELECT @row_count = @@ROWCOUNT
	IF @isDebug = 1 BEGIN
		SELECT 'INSERT dbo.dm_CollectionEnforcementProceeding_Tasks_NEW', @row_count, datediff(SECOND, @StartDate, getdate())
	END

  --select top 100 * from dbo.dm_CollectionEnforcementProceeding_Tasks where [Длительность выполнения задачи] is not null

  end
