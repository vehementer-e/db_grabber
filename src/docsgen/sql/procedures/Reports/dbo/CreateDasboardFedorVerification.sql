-- 
/*
select * from   dbo.dm_FedorVerificationRequests where [Дата статуса]>cast(getdate() as date)
order by [Номер заявки],[Дата статуса]
*/
CREATE PROC dbo.CreateDasboardFedorVerification
	@isDebug int = 0
AS
BEGIN
	SET NOCOUNT ON;

	SELECT @isDebug = isnull(@isDebug, 0)

  declare @dt_from date=--dateadd(day,-20,
                                cast(getdate() as date)
                          --      )
  declare @dt_to date
  set @dt_to=dateadd(day,1,cast(getdate() as date))

	DECLARE @ProductType_Group varchar(100)
	declare @t_ProductType_Group table (ProductType_Group varchar(100))
	insert @t_ProductType_Group (ProductType_Group)
	values
		('pts'), -- ПТС
		('autoCredit'), --Автокредит
		('ptsLite') --ПТС-Лайт


-- сотрудники КД
  drop table if exists #curr_employee_cd
  create table #curr_employee_cd([Employee] nvarchar(255) )
  --комментарю по DWH-1988
  --insert into #curr_employee_cd select employee from feodor.dbo.KDEmployees
	--DWH-1988
	INSERT #curr_employee_cd(Employee)
	SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedor.core_user AS U
		INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
		INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
			ON R.Id = UR.IdUserRole
	WHERE 1=1
		AND U.IsDeleted = 0
		AND UR.IsDeleted = 0
		AND R.Name IN ('Чекер')

-- Верификаторы
  drop table if exists #curr_employee_vr
  create table #curr_employee_vr([Employee] nvarchar(255) )
	--комментарю по DWH-1988
  --insert into #curr_employee_vr select employee from feodor.dbo.VEmployees
	--DWH-1988
	INSERT #curr_employee_vr(Employee)
	SELECT Employee = concat(U.LastName, ' ', U.FirstName, ' ', U.MiddleName) COLLATE Cyrillic_General_CI_AS
	FROM Stg._fedor.core_user AS U
		INNER JOIN Stg._fedor.core_UserAndUserRole AS UR
			ON UR.IdUser = U.Id
		INNER JOIN Stg._fedor.core_UserRoleDictionary AS R
			ON R.Id = UR.IdUserRole
	WHERE 1=1
		AND U.IsDeleted = 0
		AND UR.IsDeleted = 0
		AND R.Name IN ('Верификатор')

  drop table if exists #fedor_verificator_report
  drop table if exists #details_KD
        
	select 
		ProductType_Group = d.КодТипКредитногоПродукта,
		d.* 
	into #details_KD 
	from dbo.dm_FedorVerificationRequests as d --where [Номер заявки]='20092400036174'
	--where [ФИО сотрудника верификации/чекер] not in (select * from #curr_employee_vr) 
	where (d.[ФИО сотрудника верификации/чекер] not in (select * from #curr_employee_vr) 
		OR d.[ФИО сотрудника верификации/чекер] in (select * from #curr_employee_cd))
		and( d.[Дата статуса]>@dt_from and  d.[Дата статуса]<@dt_to) --or (Статус='Контроль данных' and [Состояние заявки]='Отложена')
		and d.КодТипКредитногоПродукта in (
			'pts', --ПТС
			'autoCredit', --Автокредит
			'ptsLite' --ПТС-Лайт
		)

	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##details_KD
		SELECT * INTO ##details_KD FROM #details_KD
	END

  --- количество Доработка и Отложенно, отправленных сегодня LastStage=1
	;with 
          rework as (
          select ProductType_Group, КодТипКредитногоПродукта, 'Доработка' [status], cast([Дата статуса] as date) Дата, [Дата статуса], [ФИО клиента], [Номер заявки] , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_KD
           where Задача='task:Требуется доработка' and [Состояние заявки]='Отложена' and Статус in('Контроль данных') 
          )
          ,rework1 as (
          select ProductType_Group, КодТипКредитногоПродукта, 'Доработка' [status], cast([Дата статуса] as date) Дата, [Дата статуса], [ФИО клиента], [Номер заявки] , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 1 LastStage
            from #details_KD
           where [Задача следующая]='task:Требуется доработка' and [Состояние заявки следующая]='Отложена' and Статус in('Контроль данных') and ШагЗаявки= ПоследнийШаг
          )
          ,postpone as (
          select ProductType_Group, КодТипКредитногоПродукта, 'Отложена' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_KD
           where Задача='task:Отложена' and [Состояние заявки] in('Отложена') and Статус in('Контроль данных')
           )
           ,postpone1 as (
		   select ProductType_Group, КодТипКредитногоПродукта, 'Отложена' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 1 LastStage
            from #details_KD
           where [Задача следующая]='task:Отложена' and [Состояние заявки следующая] in('Отложена') and Статус in('Контроль данных') and ШагЗаявки= ПоследнийШаг
           )
           select ProductType_Group, КодТипКредитногоПродукта, 'Отказано' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
             into #fedor_verificator_report
             from #details_KD
            where [Статус следующий]='Отказано' and Статус in('Верификация Call 1.5')
           -- 
           union all
           select * from postpone 
		   union all
		   select * from postpone1
           union 
           -- доработка
           select * from rework 
		   union all
		   select * from rework1
           union 
			select ProductType_Group, КодТипКредитногоПродукта, 'ВК' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]   , 0 LastStage
            from #details_KD R
			where ((R.Статус IN ('Верификация Call 1.5') 
				AND R.[Статус следующий] IN ('Ожидание подписи документов EDO', 'Переподписание первого пакета', 'Верификация Call 2'))
				)
		   --[Статус следующий]='Ожидание подписи документов EDO' and Статус in('Верификация Call 1.5')
           union
			select ProductType_Group, КодТипКредитногоПродукта, 'Новая' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage 
            from #details_KD
           where Задача='task:Новая' and Статус in('Контроль данных')
           union 
          select ProductType_Group, КодТипКредитногоПродукта, 'task:В работе' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_KD
           where [Задача]='task:В работе'  and Статус in('Контроль данных')
           union 
           select ProductType_Group, КодТипКредитногоПродукта, 'Ожидание' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_KD
          where Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and Статус in('Контроль данных')
 

--select * from  #fedor_verificator_report
		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##fedor_verificator_report
			select * INTO ##fedor_verificator_report from #fedor_verificator_report
		END

        drop table if exists #fedor_verificator_report_VK
        drop table if exists #details_VK

         select 
			ProductType_Group = d.КодТипКредитногоПродукта,
			d.*
         into #details_VK
         from dbo.dm_FedorVerificationRequests as d 
         where (d.[ФИО сотрудника верификации/чекер] not in (select * from #curr_employee_cd)
			OR d.[ФИО сотрудника верификации/чекер] in (select * from #curr_employee_vr))
			and d.[Дата статуса]>@dt_from and d.[Дата статуса]<@dt_to
			and d.КодТипКредитногоПродукта in (
				'pts', --ПТС
				'autoCredit', --Автокредит
				'ptsLite' --ПТС-Лайт
			)

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##details_VK
			select * INTO ##details_VK from #details_VK
		END

         ;
         with 
          rework as (          
          select ProductType_Group, КодТипКредитногоПродукта, 'Доработка' [status], cast([Дата статуса] as date) Дата, [Дата статуса] , [ФИО клиента], [Номер заявки] , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_VK 
           where Задача='task:Требуется доработка' and [Состояние заявки]='Отложена' and Статус in('Верификация клиента') 
          )
          ,rework1 as (
          select ProductType_Group, КодТипКредитногоПродукта, 'Доработка' [status], cast([Дата статуса] as date) Дата, [Дата статуса], [ФИО клиента], [Номер заявки] , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 1 LastStage
            from #details_VK
           where [Задача следующая]='task:Требуется доработка' and [Состояние заявки следующая]='Отложена' and Статус in('Верификация клиента') and ШагЗаявки= ПоследнийШаг
          
          )
        ,postpone1 as (
           select ProductType_Group, КодТипКредитногоПродукта, 'Отложена' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_VK
           where Задача='task:Отложена' and [Состояние заявки] in('Отложена') and Статус in('Верификация клиента') 
        )
       ,postpone as (
           select ProductType_Group, КодТипКредитногоПродукта, 'Отложена' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 1 LastStage
             from #details_VK
            where  [Задача следующая]='task:Отложена' and [Состояние заявки следующая] in('Отложена') and Статус in('Верификация клиента') and ШагЗаявки= ПоследнийШаг
        )
           -- доработка
          select ProductType_Group, КодТипКредитногоПродукта, [status],  Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек] , 0 LastStage  
            into #fedor_verificator_report_VK
            from rework
           union all 
          select ProductType_Group, КодТипКредитногоПродукта, [status], Дата, [Дата статуса], [ФИО клиента], [Номер заявки]  , Сотрудник, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек] , 1 LastStage   from rework1
           union 
          select * from postpone 
		  union 
		  select * from postpone1
           union 
          select ProductType_Group, КодТипКредитногоПродукта, 'Отказано' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_VK
           where [Статус следующий]='Отказано' and Статус in('Верификация Call 3')
           union 
          select ProductType_Group, КодТипКредитногоПродукта, 'VTS' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]   , 0 LastStage
            from #details_VK
           where [Статус следующий]='Одобрен клиент' and Статус in('Верификация Call 3')
           union 
          select ProductType_Group, КодТипКредитногоПродукта, 'task:В работе' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_VK
             where [Задача]='task:В работе'  and Статус in('Верификация клиента')
           union
          select ProductType_Group, КодТипКредитногоПродукта, 'Новая' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]   , 0 LastStage
            from #details_VK
           where Задача='task:Новая' and Статус in('Верификация клиента')
           union all
           select ProductType_Group, КодТипКредитногоПродукта, 'Ожидание' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_VK
          where Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and Статус in('Верификация клиента')
        
	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##fedor_verificator_report_VK
		SELECT * INTO ##fedor_verificator_report_VK FROM #fedor_verificator_report_VK
		--RETURN 0
	END

	drop table if exists #fedor_verificator_report_TS
	drop table if exists #details_ts        
  
        select 
			ProductType_Group = d.КодТипКредитногоПродукта,
			d.* 
          into #details_TS
          from dbo.dm_FedorVerificationRequests as d 
          where ([ФИО сотрудника верификации/чекер] not in (select * from #curr_employee_cd)
			OR [ФИО сотрудника верификации/чекер] in (select * from #curr_employee_vr))
			AND [Дата статуса]>@dt_from and  [Дата статуса]<@dt_to
			and КодТипКредитногоПродукта in (
				'pts', --ПТС
				'autoCredit', --Автокредит
				'ptsLite' --ПТС-Лайт
			)
          --and  Статус in ('Верификация клиента') 

		IF @isDebug = 1 BEGIN
			DROP TABLE IF EXISTS ##details_TS
			select * INTO ##details_TS from #details_TS
		END

         ;with
          rework as (
          select ProductType_Group, КодТипКредитногоПродукта, 'Доработка' [status], cast([Дата статуса] as date) Дата, [Дата статуса] , [ФИО клиента], [Номер заявки] , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_TS
           where Задача='task:Требуется доработка' and [Состояние заявки]='Отложена' and Статус in('Верификация ТС') 
          )
          ,rework1 as (
          select ProductType_Group, КодТипКредитногоПродукта, 'Доработка' [status], cast([Дата статуса] as date) Дата, [Дата статуса], [ФИО клиента], [Номер заявки] , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 1 LastStage
            from #details_TS
           where [Задача следующая]='task:Требуется доработка' and [Состояние заявки следующая]='Отложена' and Статус in('Верификация ТС') and ШагЗаявки= ПоследнийШаг
          )
          ,postpone1 as (
           select ProductType_Group, КодТипКредитногоПродукта, 'Отложена' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек] , 0 LastStage 
            from #details_TS
           where Задача='task:Отложена' and [Состояние заявки] in('Отложена')  and Статус in('Верификация ТС') 
        )
		,postpone as (
           select ProductType_Group, КодТипКредитногоПродукта, 'Отложена' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 1 LastStage
            from #details_TS
           where  [Задача следующая]='task:Отложена' and [Состояние заявки следующая] in('Отложена') and Статус in('Верификация ТС') and ШагЗаявки= ПоследнийШаг
        )
        
           -- доработка
          select ProductType_Group, КодТипКредитногоПродукта, [status],  Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек] , 0 LastStage  
            into #fedor_verificator_report_TS
            from rework
           union all 
          select ProductType_Group, КодТипКредитногоПродукта, [status], Дата, [Дата статуса], [ФИО клиента], [Номер заявки]  , Сотрудник, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]   , 1 LastStage
            from rework1
           union 
          select * from postpone 
		  union 
		  select * from postpone1
           union 
			select ProductType_Group, КодТипКредитногоПродукта, 'Отказано' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки]  , Сотрудник=СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_TS
			where [Статус следующий]='Отказано' and Статус in('Верификация ТС')
           union
          select ProductType_Group, КодТипКредитногоПродукта, 'Новая' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]   , 0 LastStage
            from #details_TS
           where Задача='task:Новая'  and Статус in('Верификация ТС')
           union 
          select ProductType_Group, КодТипКредитногоПродукта, 'Одобрено' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]   , 0 LastStage
            from #details_TS
           where [Статус следующий]='Одобрено' and Статус in('Верификация ТС')
           union 
          select ProductType_Group, КодТипКредитногоПродукта, 'task:В работе' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_TS
             where [Задача]='task:В работе'  and Статус in('Верификация ТС')
            union all
          select ProductType_Group, КодТипКредитногоПродукта, 'Ожидание' [status], cast([Дата статуса] as date) Дата, [Дата статуса] ДатаИВремяСтатуса, [ФИО клиента], [Номер заявки] , СотрудникПоследнегоСтатуса, [ФИО сотрудника верификации/чекер], ВремяЗатрачено, [Время, час:мин:сек]  , 0 LastStage
            from #details_TS
          where Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and Статус in('Верификация ТС')
 
	IF @isDebug = 1 BEGIN
		DROP TABLE IF EXISTS ##fedor_verificator_report_TS
		SELECT * INTO ##fedor_verificator_report_TS FROM #fedor_verificator_report_TS
		--RETURN 0
	END
 --   
 --drop table if exists  dbo.dashboard_Verification_fedor_details

 --DWH-1764 
 TRUNCATE TABLE dbo.dashboard_Verification_fedor_details

 INSERT dbo.dashboard_Verification_fedor_details
 (
     stage,
     stage_status,
	 ProductType_Group,
	 КодТипКредитногоПродукта,
     status,
     Дата,
     ДатаИВремяСтатуса,
     [ФИО клиента],
     [Номер заявки],
     Сотрудник,
     [ФИО сотрудника верификации/чекер],
     ВремяЗатрачено,
     [Время, час:мин:сек],
     LastStage
 )
 select 'KD' stage, stage_status='All',*
 --into  dbo.dashboard_Verification_fedor_details
 FROM  #fedor_verificator_report r
 union all select 'KD' stage, stage_status='Отложена',*  from  #fedor_verificator_report r  where   status='Отложена' 
 union all select 'KD' stage, stage_status='Доработка',*  from  #fedor_verificator_report r  where   status='Доработка' 
 union all select 'KD' stage, stage_status='В работе',*  from  #fedor_verificator_report r  where   status='task:В работе' 
 union all select 'KD' stage, stage_status='Ожидание',*  from  #fedor_verificator_report r  where   status='Ожидание' 
 
 union all select 'VK' stage, stage_status='All',*  from  #fedor_verificator_report_VK  r
 union all select 'VK' stage, stage_status='Отложена',*  from  #fedor_verificator_report_VK r  where   status='Отложена' 
 union all select 'VK' stage, stage_status='Доработка',*  from  #fedor_verificator_report_VK r  where   status='Доработка' 
 union all select 'VK' stage, stage_status='В работе',*  from  #fedor_verificator_report_VK r  where   status='task:В работе' 
 union all select 'VK' stage, stage_status='Ожидание',*  from  #fedor_verificator_report_VK r  where   status='Ожидание' 


 union all select 'TS' stage, stage_status='All',*  from  #fedor_verificator_report_TS  r
 union all select 'TS' stage, stage_status='Отложена',*  from  #fedor_verificator_report_TS r  where   status='Отложена' 
 union all select 'TS' stage, stage_status='Доработка',*  from  #fedor_verificator_report_TS r  where   status='Доработка' 
 union all select 'TS' stage, stage_status='В работе',*  from  #fedor_verificator_report_TS r  where   status='task:В работе' 
 union all select 'TS' stage, stage_status='Ожидание',*  from  #fedor_verificator_report_TS r  where   status='Ожидание' 
 --select * from  dbo.dashboard_Verification_fedor_details 

 ---drop table if exists dbo.dashboard_Verification_fedor  
--delete from dbo.dashboard_Verification_fedor
TRUNCATE TABLE dbo.dashboard_Verification_fedor

--var 1
/*
INSERT into dbo.dashboard_Verification_fedor
(
    rdate,
    Уникальное_количество_заявок_КД,
    Отложено_количество_заявок_КД,
    Отправлено_в_доработку_количество_заявок_КД,
    Ср_время_рассмотрения_КД_день,
    Ср_время_Ожидания_КД_день,
    Ср_время_рассмотрения_КД_час,
    Ср_время_Ожидания_КД_час,
    Уровень_одобрения_КД,
    Уникальное_количество_заявок_ВК,
    Отложено_количество_заявок_ВК,
    Отправлено_в_доработку_количество_заявок_ВК,
    Ср_время_рассмотрения_ВК_день,
    Ср_время_Ожидания_ВК_день,
    Ср_время_рассмотрения_ВK_час,
    Ср_время_Ожидания_ВK_час,
    Уникальное_количество_заявок_ТС,
    Отложено_количество_заявок_ТС,
    Отправлено_в_доработку_количество_заявок_ТС,
    Ср_время_рассмотрения_ТС_день,
    Ср_время_Ожидания_ТС_день,
    Ср_время_рассмотрения_ТС_час,
    Ср_время_Ожидания_ТС_час,
    Ср_время_рассмотрения_ВК_ТС_день,
    Ср_время_рассмотрения_ВК_ТС_час,
    Уровень_одобрения_ВК_ТС,
    Ср_время_рассмотрения_КД_ВК_ТС_день,
    Ср_время_Ожидания_КД_ВК_ТС_день
)
   select [rdate]	= getdate()
	      , [Уникальное_количество_заявок_КД]		             = cast(format( (select count(distinct [Номер заявки] )from #fedor_verificator_report ) ,'0') as nvarchar(50))
        , [Отложено_количество_заявок_КД]			             = cast(format( (select count(distinct [Номер заявки] )from #fedor_verificator_report
                                                                            where   status='Отложена'  and LastStage=1 )
                                                             ,'0') as nvarchar(50))
        , [Отправлено_в_доработку_количество_заявок_КД]		 = cast(format( (select count(distinct [Номер заявки] )from #fedor_verificator_report
                                                                            where    status='Доработка' and LastStage=1  ) 
                                                             ,'0') as nvarchar(50))
	    
	      , [Ср_время_рассмотрения_КД_день]		               =   format(cast(case when	
                                                                  (select count(distinct [Номер заявки] )from #fedor_verificator_report )<>0
                                                                then 
                                                                ( (select sum([ВремяЗатрачено]) from  #fedor_verificator_report where status in ('task:В работе'))
                                                                / (select count(distinct [Номер заявки] )from #fedor_verificator_report )
                                                                )
                                                                 else 0

                                                           end  as datetime), N'HH:mm:ss')
         , [Ср_время_Ожидания_КД_день]		               =   format(cast(case when	
                                                                  (select count(distinct [Номер заявки] )from #fedor_verificator_report )<>0
                                                                then 
                                                                ( (select sum([ВремяЗатрачено]) from  #fedor_verificator_report where status in ('Ожидание'))
                                                                / (select count(distinct [Номер заявки] )from #fedor_verificator_report )
                                                                )
                                                                else 0                                                               

                                                           end  as datetime), N'HH:mm:ss')
        , [Ср_время_рассмотрения_КД_час]		               = format(cast(
                                                              case when  
                                                                     (select count(distinct [Номер заявки])  from #details_KD  where [Статус] = 'Контроль данных' and  [Задача] = 'task:В работе' and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
                                                                  then 
                                                                       (select sum([ВремяЗатрачено]) from #details_KD  where [Статус] = 'Контроль данных' and  [Задача] = 'task:В работе' and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                                                                     /
                                                                     (select count(distinct [Номер заявки])  from #details_KD  where [Статус] = 'Контроль данных' and  [Задача] = 'task:В работе' and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                                                                  else 0
                                                               end
                                                               as datetime), N'HH:mm:ss')
   , [Ср_время_Ожидания_КД_час]		               = format(cast(
                                                              case when  
                                                                     (select count(distinct [Номер заявки])  from #details_KD  where [Статус] = 'Контроль данных' and  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
                                                                  then 
                                                                       (select sum([ВремяЗатрачено]) from #details_KD  where [Статус] = 'Контроль данных' and  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                                                                     /
                                                                     (select count(distinct [Номер заявки])  from #details_KD  where [Статус] = 'Контроль данных' and  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                                                                  else 0
                                                               end
                                                               as datetime), N'HH:mm:ss')
	      , [Уровень_одобрения_КД]				                   = case when	(select count(distinct [Номер заявки] )from #fedor_verificator_report where status in('ВК','Отказано'))  <> 0 
                                                                  then 1.0*(select count(distinct [Номер заявки] )from #fedor_verificator_report where status='ВК' )
                                                                     / (select count(distinct [Номер заявки] )from #fedor_verificator_report where status  in('ВК','Отказано')) 
                                                                  else 0.0 
                                                              end
        , [Уникальное_количество_заявок_ВК]					       =  cast(format( (select count(distinct [Номер заявки] )from #fedor_verificator_report_VK )  ,'0') as nvarchar(50))
        , [Отложено_количество_заявок_ВК]			             = (select count(distinct [Номер заявки] )from #fedor_verificator_report_vk
                                                               where   status='Отложена' and LastStage=1   
                                                             )
        , [Отправлено_в_доработку_количество_заявок_ВК]		 = (select count(distinct [Номер заявки] )from #fedor_verificator_report_vk
                                                               where    status='Доработка'  and LastStage=1 
                                                             )
        , [Ср_время_рассмотрения_ВК_день]		               = format(cast(
                                                             case when	
                                                                    (select count(distinct [Номер заявки] )from #fedor_verificator_report_VK ) <>0
                                                                  then
                                                                  ( (select sum([ВремяЗатрачено]) from  #fedor_verificator_report_vk where status in ('task:В работе'))
                                                                  /(select count(distinct [Номер заявки] )from #fedor_verificator_report_VK ) 
                                                                  )
                                                                  else 0
                                                             end
                                                             as datetime), N'HH:mm:ss')
        , [Ср_время_Ожидания_ВК_день]		               = format(cast(
                                                             case when	
                                                                    (select count(distinct [Номер заявки] )from #fedor_verificator_report_VK ) <>0
                                                                  then
                                                                  ( (select sum([ВремяЗатрачено]) from  #fedor_verificator_report_vk where status in ('Ожидание'))
                                                                  /(select count(distinct [Номер заявки] )from #fedor_verificator_report_VK ) 
                                                                  )
                                                                  else 0
                                                             end
                                                             as datetime), N'HH:mm:ss')
        , [Ср_время_рассмотрения_ВK_час]                    = format(cast(
                                                                 case when  
                                                                        (select count(distinct [Номер заявки])  from #details_VK  where   [Задача] = 'task:В работе' and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
                                                                     then 
                                                                          (select sum([ВремяЗатрачено]) from #details_VK  where  [Задача] = 'task:В работе' and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                                                                        /
                                                                        (select count(distinct [Номер заявки])  from #details_VK  where  [Задача] = 'task:В работе' and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                                                                     else 0
                                                                  end
                                                                  as datetime), N'HH:mm:ss')
  , [Ср_время_Ожидания_ВK_час]                    = format(cast(
                                                                 case when  
                                                                        (select count(distinct [Номер заявки])  from #details_VK  where    Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
                                                                     then 
                                                                          (select sum([ВремяЗатрачено]) from #details_VK  where   Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                                                                        /
                                                                        (select count(distinct [Номер заявки])  from #details_VK  where  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                                                                     else 0                                                                end
                                                                  as datetime), N'HH:mm:ss')
--select *  from #details_VK  where  [Дата статуса]>=dateadd(hh ,-1 ,getdate())  [Задача] = 'task:В работе' and Статус in('Верификация клиента') and 
	      , [Уникальное_количество_заявок_ТС]					       =  cast(format( (select count(distinct [Номер заявки] )from #fedor_verificator_report_TS )  ,'0') as nvarchar(50))
        , [Отложено_количество_заявок_ТС]			             = (select count(distinct [Номер заявки] )from #fedor_verificator_report_TS
                                                               where   status='Отложена'   and LastStage=1 
                                                             )
        , [Отправлено_в_доработку_количество_заявок_ТС]		 = (select count(distinct [Номер заявки] )from #fedor_verificator_report_TS
                                                               where    status='Доработка'  and LastStage=1 
                                                             )

       , [Ср_время_рассмотрения_ТС_день]		               = format(cast(
                                                             case when	
                                                                      (select count(distinct [Номер заявки] )from #fedor_verificator_report_TS ) <>0
                                                                  then
                                                                  ( (select sum([ВремяЗатрачено]) from  #fedor_verificator_report_TS  where status in ('task:В работе'))
                                                                  /  (select count(distinct [Номер заявки] )from #fedor_verificator_report_TS ) 
                                                                  )
                                                                  else 0
                                                             end
                                                             as datetime), N'HH:mm:ss')
 , [Ср_время_Ожидания_ТС_день]		               = format(cast(
                                                             case when	
                                                                      (select count(distinct [Номер заявки] )from #fedor_verificator_report_TS ) <>0
                                                                  then
                                                                  ( (select sum([ВремяЗатрачено]) from  #fedor_verificator_report_TS  where status in ('Ожидание'))
                                                                  /  (select count(distinct [Номер заявки] )from #fedor_verificator_report_TS ) 
                                                                  )
                                                                  else 0
                                                             end
                                                             as datetime), N'HH:mm:ss')
        , [Ср_время_рассмотрения_ТС_час]                    = format(cast(
                                                                 case when  
                                                                        (select count(distinct [Номер заявки])  from  #details_TS   where   [Задача] = 'task:В работе' and Статус in('Верификация ТС') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
                                                                     then 
                                                                          (select sum([ВремяЗатрачено]) from #details_TS  where  [Задача] = 'task:В работе' and Статус in('Верификация ТС')and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                                                                        /
                                                                        (select count(distinct [Номер заявки])  from #details_TS  where  [Задача] = 'task:В работе'  and Статус in('Верификация ТС')and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                                                                     else 0
                                                                  end
                                                                  as datetime), N'HH:mm:ss')
  , [Ср_время_Ожидания_ТС_час]                    = format(cast(
                                                                 case when  
                                                                        (select count(distinct [Номер заявки])  from  #details_TS   where   Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация ТС') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
                                                                     then 
                                                                          (select sum([ВремяЗатрачено]) from #details_TS  where  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация ТС')and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                                                                        /
                                                                        (select count(distinct [Номер заявки])  from #details_TS  where  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')   and Статус in('Верификация ТС')and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                                                                     else 0
                                                                  end
                                                                  as datetime), N'HH:mm:ss')
        , [Ср_время_рассмотрения_ВК_ТС_день]		               = format(cast(
                                                             case when	
                                                                     (select   count(distinct [Номер заявки])  from  (select * from  #fedor_verificator_report_TS union all select * from #fedor_verificator_report_VK) q)<>0
                                                                  then
                                                                  ( (select sum([ВремяЗатрачено]) from (select * from  #fedor_verificator_report_TS union all select * from #fedor_verificator_report_VK) q where status in ('task:В работе'))
                                                                  /  (select   count(distinct [Номер заявки])  from  (select * from  #fedor_verificator_report_TS union all select * from #fedor_verificator_report_VK) q)
                                                                  )
                                                                  else 0
                                                             end
                                                             as datetime), N'HH:mm:ss')
        , [Ср_время_рассмотрения_ВК_ТС_час]                    = format(cast(
                                                                 case when  
                                                                        (select count(distinct [Номер заявки])  from  #details_TS   where   [Задача] = 'task:В работе'  and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
                                                                     then 
                                                                          (select sum([ВремяЗатрачено]) from #details_TS  where  [Задача] = 'task:В работе' and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                                                                        /
                                                                        (select count(distinct [Номер заявки])  from #details_TS  where  [Задача] = 'task:В работе'  and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
                                                                     else 0
                                                                  end
                                                                  as datetime), N'HH:mm:ss')

        , [Уровень_одобрения_ВК_ТС]				                   = case when	(select count(distinct [Номер заявки] )from #fedor_verificator_report_VK where status in('VTS','Отказано'))  <> 0 
                                                                  then 1.0*(select count(distinct [Номер заявки] )from #fedor_verificator_report_VK where status='VTS' )
                                                                     / (select count(distinct [Номер заявки] )from #fedor_verificator_report_VK where status  in('VTS','Отказано')) 
                                                                  else 0.0 
                                                              end
 , [Ср_время_рассмотрения_КД_ВК_ТС_день]		               = format(cast(
                                                             case when	
                                                                     (select  count(distinct [Номер заявки])  from  (select * from  #fedor_verificator_report union all select * from  #fedor_verificator_report_TS union all select * from #fedor_verificator_report_VK) q)<>0
                                                                  then
                                                                  ( (select sum([ВремяЗатрачено]) from (select * from  #fedor_verificator_report union all select * from  #fedor_verificator_report_TS union all select * from #fedor_verificator_report_VK) q where status in ('task:В работе'))
                                                                  /(select  count(distinct [Номер заявки])  from  (select * from  #fedor_verificator_report union all select * from  #fedor_verificator_report_TS union all select * from #fedor_verificator_report_VK) q)
                                                                  )
                                                                  else 0
                                                             end
                                                             as datetime), N'HH:mm:ss')
, [Ср_время_Ожидания_КД_ВК_ТС_день]		               = format(cast(
                                                             case when	
                                                                     (select  count(distinct [Номер заявки])  from  (select * from  #fedor_verificator_report union all select * from  #fedor_verificator_report_TS union all select * from #fedor_verificator_report_VK) q)<>0
                                                                  then
                                                                  ( (select sum([ВремяЗатрачено]) from (select * from  #fedor_verificator_report union all select * from  #fedor_verificator_report_TS union all select * from #fedor_verificator_report_VK) q where status in ('Ожидание'))
                                                                  /(select  count(distinct [Номер заявки])  from  (select * from  #fedor_verificator_report union all select * from  #fedor_verificator_report_TS union all select * from #fedor_verificator_report_VK) q)
                                                                  )
                                                                  else 0
                                                             end
                                                             as datetime), N'HH:mm:ss')
       --  into dbo.dashboard_Verification_fedor
*/
	--var 2
	--цикл по @t_ProductType_Group
	DECLARE cur_ProductType_Group CURSOR FOR
	SELECT C.ProductType_Group
	FROM @t_ProductType_Group AS C
	ORDER BY C.ProductType_Group

	OPEN cur_ProductType_Group
	FETCH NEXT FROM cur_ProductType_Group INTO @ProductType_Group
	WHILE @@FETCH_STATUS = 0
	BEGIN
		;with t_fedor_verificator_report as (
			select t.*
			from #fedor_verificator_report as t
			where t.ProductType_Group = @ProductType_Group
		),
		t_details_KD as (
			select t.*
			from #details_KD as t
			where t.ProductType_Group = @ProductType_Group
		),
		t_fedor_verificator_report_VK as (
			select t.*
			from #fedor_verificator_report_VK as t
			where t.ProductType_Group = @ProductType_Group
		),
		t_details_VK as (
			select t.*
			from #details_VK as t
			where t.ProductType_Group = @ProductType_Group
		),
		t_fedor_verificator_report_TS as (
			select t.*
			from #fedor_verificator_report_TS as t
			where t.ProductType_Group = @ProductType_Group
		),
		t_details_TS as (
			select t.*
			from #details_TS as t
			where t.ProductType_Group = @ProductType_Group
		)
		INSERT into dbo.dashboard_Verification_fedor
		(
			rdate,
			Уникальное_количество_заявок_КД,
			Отложено_количество_заявок_КД,
			Отправлено_в_доработку_количество_заявок_КД,
			Ср_время_рассмотрения_КД_день,
			Ср_время_Ожидания_КД_день,
			Ср_время_рассмотрения_КД_час,
			Ср_время_Ожидания_КД_час,
			Уровень_одобрения_КД,
			Уникальное_количество_заявок_ВК,
			Отложено_количество_заявок_ВК,
			Отправлено_в_доработку_количество_заявок_ВК,
			Ср_время_рассмотрения_ВК_день,
			Ср_время_Ожидания_ВК_день,
			Ср_время_рассмотрения_ВK_час,
			Ср_время_Ожидания_ВK_час,
			Уникальное_количество_заявок_ТС,
			Отложено_количество_заявок_ТС,
			Отправлено_в_доработку_количество_заявок_ТС,
			Ср_время_рассмотрения_ТС_день,
			Ср_время_Ожидания_ТС_день,
			Ср_время_рассмотрения_ТС_час,
			Ср_время_Ожидания_ТС_час,
			Ср_время_рассмотрения_ВК_ТС_день,
			Ср_время_рассмотрения_ВК_ТС_час,
			Уровень_одобрения_ВК_ТС,
			Ср_время_рассмотрения_КД_ВК_ТС_день,
			Ср_время_Ожидания_КД_ВК_ТС_день,
			ProductType_Group
		)
		   select [rdate]	= getdate()
				  , [Уникальное_количество_заявок_КД]		             = cast(format( (select count(distinct [Номер заявки] )from t_fedor_verificator_report ) ,'0') as nvarchar(50))
				, [Отложено_количество_заявок_КД]			             = cast(format( (select count(distinct [Номер заявки] )from t_fedor_verificator_report
																					where   status='Отложена'  and LastStage=1 )
																	 ,'0') as nvarchar(50))
				, [Отправлено_в_доработку_количество_заявок_КД]		 = cast(format( (select count(distinct [Номер заявки] )from t_fedor_verificator_report
																					where    status='Доработка' and LastStage=1  ) 
																	 ,'0') as nvarchar(50))
	    
				  , [Ср_время_рассмотрения_КД_день]		               =   format(cast(case when	
																		  (select count(distinct [Номер заявки] )from t_fedor_verificator_report )<>0
																		then 
																		( (select sum([ВремяЗатрачено]) from  t_fedor_verificator_report where status in ('task:В работе'))
																		/ (select count(distinct [Номер заявки] )from t_fedor_verificator_report )
																		)
																		 else 0

																   end  as datetime), N'HH:mm:ss')
				 , [Ср_время_Ожидания_КД_день]		               =   format(cast(case when	
																		  (select count(distinct [Номер заявки] )from t_fedor_verificator_report )<>0
																		then 
																		( (select sum([ВремяЗатрачено]) from  t_fedor_verificator_report where status in ('Ожидание'))
																		/ (select count(distinct [Номер заявки] )from t_fedor_verificator_report )
																		)
																		else 0                                                               

																   end  as datetime), N'HH:mm:ss')
				, [Ср_время_рассмотрения_КД_час]		               = format(cast(
																	  case when  
																			 (select count(distinct [Номер заявки])  from t_details_KD  where [Статус] = 'Контроль данных' and  [Задача] = 'task:В работе' and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
																		  then 
																			   (select sum([ВремяЗатрачено]) from t_details_KD  where [Статус] = 'Контроль данных' and  [Задача] = 'task:В работе' and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
																			 /
																			 (select count(distinct [Номер заявки])  from t_details_KD  where [Статус] = 'Контроль данных' and  [Задача] = 'task:В работе' and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
																		  else 0
																	   end
																	   as datetime), N'HH:mm:ss')
		   , [Ср_время_Ожидания_КД_час]		               = format(cast(
																	  case when  
																			 (select count(distinct [Номер заявки])  from t_details_KD  where [Статус] = 'Контроль данных' and  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
																		  then 
																			   (select sum([ВремяЗатрачено]) from t_details_KD  where [Статус] = 'Контроль данных' and  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
																			 /
																			 (select count(distinct [Номер заявки])  from t_details_KD  where [Статус] = 'Контроль данных' and  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
																		  else 0
																	   end
																	   as datetime), N'HH:mm:ss')
				  , [Уровень_одобрения_КД]				                   = case when	(select count(distinct [Номер заявки] )from t_fedor_verificator_report where status in('ВК','Отказано'))  <> 0 
																		  then 1.0*(select count(distinct [Номер заявки] )from t_fedor_verificator_report where status='ВК' )
																			 / (select count(distinct [Номер заявки] )from t_fedor_verificator_report where status  in('ВК','Отказано')) 
																		  else 0.0 
																	  end
				, [Уникальное_количество_заявок_ВК]					       =  cast(format( (select count(distinct [Номер заявки] )from t_fedor_verificator_report_VK )  ,'0') as nvarchar(50))
				, [Отложено_количество_заявок_ВК]			             = (select count(distinct [Номер заявки] )from t_fedor_verificator_report_vk
																	   where   status='Отложена' and LastStage=1   
																	 )
				, [Отправлено_в_доработку_количество_заявок_ВК]		 = (select count(distinct [Номер заявки] )from t_fedor_verificator_report_vk
																	   where    status='Доработка'  and LastStage=1 
																	 )
				, [Ср_время_рассмотрения_ВК_день]		               = format(cast(
																	 case when	
																			(select count(distinct [Номер заявки] )from t_fedor_verificator_report_VK ) <>0
																		  then
																		  ( (select sum([ВремяЗатрачено]) from  t_fedor_verificator_report_vk where status in ('task:В работе'))
																		  /(select count(distinct [Номер заявки] )from t_fedor_verificator_report_VK ) 
																		  )
																		  else 0
																	 end
																	 as datetime), N'HH:mm:ss')
				, [Ср_время_Ожидания_ВК_день]		               = format(cast(
																	 case when	
																			(select count(distinct [Номер заявки] )from t_fedor_verificator_report_VK ) <>0
																		  then
																		  ( (select sum([ВремяЗатрачено]) from  t_fedor_verificator_report_vk where status in ('Ожидание'))
																		  /(select count(distinct [Номер заявки] )from t_fedor_verificator_report_VK ) 
																		  )
																		  else 0
																	 end
																	 as datetime), N'HH:mm:ss')
				, [Ср_время_рассмотрения_ВK_час]                    = format(cast(
																		 case when  
																				(select count(distinct [Номер заявки])  from t_details_VK  where   [Задача] = 'task:В работе' and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
																			 then 
																				  (select sum([ВремяЗатрачено]) from t_details_VK  where  [Задача] = 'task:В работе' and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
																				/
																				(select count(distinct [Номер заявки])  from t_details_VK  where  [Задача] = 'task:В работе' and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
																			 else 0
																		  end
																		  as datetime), N'HH:mm:ss')
		  , [Ср_время_Ожидания_ВK_час]                    = format(cast(
																		 case when  
																				(select count(distinct [Номер заявки])  from t_details_VK  where    Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
																			 then 
																				  (select sum([ВремяЗатрачено]) from t_details_VK  where   Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
																				/
																				(select count(distinct [Номер заявки])  from t_details_VK  where  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация клиента') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
																			 else 0                                                                end
																		  as datetime), N'HH:mm:ss')
		--select *  from t_details_VK  where  [Дата статуса]>=dateadd(hh ,-1 ,getdate())  [Задача] = 'task:В работе' and Статус in('Верификация клиента') and 
				  , [Уникальное_количество_заявок_ТС]					       =  cast(format( (select count(distinct [Номер заявки] )from t_fedor_verificator_report_TS )  ,'0') as nvarchar(50))
				, [Отложено_количество_заявок_ТС]			             = (select count(distinct [Номер заявки] )from t_fedor_verificator_report_TS
																	   where   status='Отложена'   and LastStage=1 
																	 )
				, [Отправлено_в_доработку_количество_заявок_ТС]		 = (select count(distinct [Номер заявки] )from t_fedor_verificator_report_TS
																	   where    status='Доработка'  and LastStage=1 
																	 )

			   , [Ср_время_рассмотрения_ТС_день]		               = format(cast(
																	 case when	
																			  (select count(distinct [Номер заявки] )from t_fedor_verificator_report_TS ) <>0
																		  then
																		  ( (select sum([ВремяЗатрачено]) from  t_fedor_verificator_report_TS  where status in ('task:В работе'))
																		  /  (select count(distinct [Номер заявки] )from t_fedor_verificator_report_TS ) 
																		  )
																		  else 0
																	 end
																	 as datetime), N'HH:mm:ss')
		 , [Ср_время_Ожидания_ТС_день]		               = format(cast(
																	 case when	
																			  (select count(distinct [Номер заявки] )from t_fedor_verificator_report_TS ) <>0
																		  then
																		  ( (select sum([ВремяЗатрачено]) from  t_fedor_verificator_report_TS  where status in ('Ожидание'))
																		  /  (select count(distinct [Номер заявки] )from t_fedor_verificator_report_TS ) 
																		  )
																		  else 0
																	 end
																	 as datetime), N'HH:mm:ss')
				, [Ср_время_рассмотрения_ТС_час]                    = format(cast(
																		 case when  
																				(select count(distinct [Номер заявки])  from  t_details_TS   where   [Задача] = 'task:В работе' and Статус in('Верификация ТС') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
																			 then 
																				  (select sum([ВремяЗатрачено]) from t_details_TS  where  [Задача] = 'task:В работе' and Статус in('Верификация ТС')and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
																				/
																				(select count(distinct [Номер заявки])  from t_details_TS  where  [Задача] = 'task:В работе'  and Статус in('Верификация ТС')and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
																			 else 0
																		  end
																		  as datetime), N'HH:mm:ss')
		  , [Ср_время_Ожидания_ТС_час]                    = format(cast(
																		 case when  
																				(select count(distinct [Номер заявки])  from  t_details_TS   where   Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация ТС') and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
																			 then 
																				  (select sum([ВремяЗатрачено]) from t_details_TS  where  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')  and Статус in('Верификация ТС')and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
																				/
																				(select count(distinct [Номер заявки])  from t_details_TS  where  Задача in ('task:Вернулась из отложенных','task:Вернулась с доработки','task:Новая','task:Переназначена')   and Статус in('Верификация ТС')and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
																			 else 0
																		  end
																		  as datetime), N'HH:mm:ss')
				, [Ср_время_рассмотрения_ВК_ТС_день]		               = format(cast(
																	 case when	
																			 (select   count(distinct [Номер заявки])  from  (select * from  t_fedor_verificator_report_TS union all select * from t_fedor_verificator_report_VK) q)<>0
																		  then
																		  ( (select sum([ВремяЗатрачено]) from (select * from  t_fedor_verificator_report_TS union all select * from t_fedor_verificator_report_VK) q where status in ('task:В работе'))
																		  /  (select   count(distinct [Номер заявки])  from  (select * from  t_fedor_verificator_report_TS union all select * from t_fedor_verificator_report_VK) q)
																		  )
																		  else 0
																	 end
																	 as datetime), N'HH:mm:ss')
				, [Ср_время_рассмотрения_ВК_ТС_час]                    = format(cast(
																		 case when  
																				(select count(distinct [Номер заявки])  from  t_details_TS   where   [Задача] = 'task:В работе'  and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))<>0
																			 then 
																				  (select sum([ВремяЗатрачено]) from t_details_TS  where  [Задача] = 'task:В работе' and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
																				/
																				(select count(distinct [Номер заявки])  from t_details_TS  where  [Задача] = 'task:В работе'  and [Дата статуса]>=dateadd(hh ,-1 ,getdate()))
																			 else 0
																		  end
																		  as datetime), N'HH:mm:ss')

				, [Уровень_одобрения_ВК_ТС]				                   = case when	(select count(distinct [Номер заявки] )from t_fedor_verificator_report_VK where status in('VTS','Отказано'))  <> 0 
																		  then 1.0*(select count(distinct [Номер заявки] )from t_fedor_verificator_report_VK where status='VTS' )
																			 / (select count(distinct [Номер заявки] )from t_fedor_verificator_report_VK where status  in('VTS','Отказано')) 
																		  else 0.0 
																	  end
		 , [Ср_время_рассмотрения_КД_ВК_ТС_день]		               = format(cast(
																	 case when	
																			 (select  count(distinct [Номер заявки])  from  (select * from  t_fedor_verificator_report union all select * from  t_fedor_verificator_report_TS union all select * from t_fedor_verificator_report_VK) q)<>0
																		  then
																		  ( (select sum([ВремяЗатрачено]) from (select * from  t_fedor_verificator_report union all select * from  t_fedor_verificator_report_TS union all select * from t_fedor_verificator_report_VK) q where status in ('task:В работе'))
																		  /(select  count(distinct [Номер заявки])  from  (select * from  t_fedor_verificator_report union all select * from  t_fedor_verificator_report_TS union all select * from t_fedor_verificator_report_VK) q)
																		  )
																		  else 0
																	 end
																	 as datetime), N'HH:mm:ss')
		, [Ср_время_Ожидания_КД_ВК_ТС_день]		               = format(cast(
																	 case when	
																			 (select  count(distinct [Номер заявки])  from  (select * from  t_fedor_verificator_report union all select * from  t_fedor_verificator_report_TS union all select * from t_fedor_verificator_report_VK) q)<>0
																		  then
																		  ( (select sum([ВремяЗатрачено]) from (select * from  t_fedor_verificator_report union all select * from  t_fedor_verificator_report_TS union all select * from t_fedor_verificator_report_VK) q where status in ('Ожидание'))
																		  /(select  count(distinct [Номер заявки])  from  (select * from  t_fedor_verificator_report union all select * from  t_fedor_verificator_report_TS union all select * from t_fedor_verificator_report_VK) q)
																		  )
																		  else 0
																	 end
																	 as datetime), N'HH:mm:ss')

			,ProductType_Group = @ProductType_Group

		FETCH NEXT FROM cur_ProductType_Group INTO @ProductType_Group
	END

	CLOSE cur_ProductType_Group
	DEALLOCATE cur_ProductType_Group


END
  --select * from #fedor_verificator_report_VK
