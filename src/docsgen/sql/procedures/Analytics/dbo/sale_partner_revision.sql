/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/

CREATE proc [dbo].[sale_partner_revision]   @month date 
as


SELECT [Номер]
,case when productType = 'AUTOCREDIT' then 'Автокредитование'  when productType = 'PTS' then 'ПТС' when  productType = 'BIG INST' then 'БИ' when ispts=0 then 'Беззалог' else 'ПТС' end [Тип продукта]
      ,issuedSum [Выданная сумма]
      ,issuedMonth [Заем выдан месяц]
      , issuedDay [Заем выдан день]
      ,[Заем выдан]
      ,[РО_регион]
      ,[Партнер]
      ,[Юрлицо]
, ФИО
,[Заем погашен]
,[Текущий Статус]

      ,[Привлечение]
      ,[ПризнакСтраховка]
      ,[ПризнакРАТ]
      ,[Признак Защита от потери работы]
      ,[ПризнакПомощьБизнесу]
      ,[ПризнакТелемедицина]
      ,[Сумма за оформление Агентом (Digital)]
      ,[Процент вознаграждения Агента (Партнер)]
      ,[Вознаграждение РАТ]
      ,[Вознаграждение Позитив.Настрой Д2]
      ,[Вознаграждение Юр.помощь]
      ,[Вознаграждение Телемедицина]
      ,[Общая сумма вознаграждения Агента (в руб)]
      ,isPreviousMonth [Признак реестр за предыдущий месяц]
      ,isCurrentMonth [Признак реестр за текущий месяц кроме сегодняшнего дня]
  FROM v_request_cost_partner

  where issuedMonth = @month
 --where case when @type_ssrs= 'реестр за предыдущий месяц' then isPreviousMonth when @type_ssrs= 'реестр за текущий месяц' then 
 --     isCurrentMonth end=1

 

