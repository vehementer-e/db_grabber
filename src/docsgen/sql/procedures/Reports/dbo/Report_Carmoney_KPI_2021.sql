-- =============================================
-- Author:		Sabanin_a_a

-- =============================================

--exec [dbo].[Report_Carmoney_KPI_2021]
CREATE  PROCEDURE [dbo].[Report_Carmoney_KPI_2021]
	-- Add the parameters for the stored procedure here


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- создадим шаблон показателей
	--exec [dbo].[Report_Carmoney_KPI_template_2021]

	    -- загрузим планы продаж
	    --drop table if exists dbo.Report_Carmoney_KPI_SalesPlan_2021
		--DWH-1764 
		TRUNCATE TABLE dbo.Report_Carmoney_KPI_SalesPlan_2021

		INSERT dbo.Report_Carmoney_KPI_SalesPlan_2021
		(
		    [Дата начала месяца],
		    [Дата конец месяца],
		    ЗначениеПоказателя,
		    Показатель,
		    rws,
		    ind
		)
	    SELECT (DATEADD(month, DATEDIFF(month, 0, [Дата конец месяца]), 0) ) [Дата начала месяца],[Дата конец месяца], ЗначениеПоказателя, Показатель, templ.rws,templ.ind
	    --into dbo.Report_Carmoney_KPI_SalesPlan_2021
		FROM stg.files.ReportKPI_SalesPlan_buffer plan_sales
		UNPIVOT (
			ЗначениеПоказателя FOR Показатель IN ([Заявок],[Займов, шт]  ,[Займов, руб]
			  ,[КП шт]
			  ,[КП, руб gross]
			  ,[КП, руб net])
		) unpvt
		left join (select rws,ind,ind_plan from [dbo].[dm_Report_KPI_template_2021] group by rws ,ind ,ind_plan) templ on templ.ind_plan = unpvt.Показатель
		--where [Дата конец месяца] = '2021-01-31 00:00:00.000'

		-- загрузим подневные планы продаж
	   -- drop table if exists dbo.Report_Carmoney_KPI_DailyPlan_2021
	   drop table if exists #dailyPlan
	    SELECT [Дата],(DATEADD(month, DATEDIFF(month, 0, [Дата]), 0) ) [Дата начала месяца], eomonth([Дата]) [Дата конец месяца], ЗначениеПоказателя, Показатель --, templ.rws,templ.ind
	   -- into dbo.Report_Carmoney_KPI_SalesPlan_2021
	   --select *
	   into #dailyPlan
		FROM stg.files.ReportKPI_DailyPlanKPI_buffer plan_sales
		UNPIVOT (
			ЗначениеПоказателя FOR Показатель IN ([Кол-во заявок],[Кол-во займов]  ,[Сумма займов],[Кол-во займов со страховкой],[Сумма страховки по Договору],[Сумма страховки Полученная в ДОХОД])
		) unpvt
		--left join (select rws,ind,ind_plan from [dbo].[dm_Report_KPI_template_2021] group by rws ,ind ,ind_plan) templ on templ.ind_plan = unpvt.Показатель
		--where [Дата конец месяца] = '2021-01-31 00:00:00.000'

		--update #dailyPlan set Показатель = 'Кол-во заявок' where Показатель = 'Заявки'
		--update #dailyPlan set Показатель = 'Кол-во займов' where Показатель = 'Займы, шт'
		--update #dailyPlan set Показатель = 'Сумма займов' where Показатель = 'Займы, руб'

		--update #dailyPlan set Показатель = 'Заявок' where Показатель = 'Кол-во заявок'
		--update #dailyPlan set Показатель = 'Займов, шт' where Показатель = 'Кол-во займов'
		--update #dailyPlan set Показатель = 'Займов, руб' where Показатель = 'Сумма займов'

		--select * from #dailyPlan

		 -- загрузим планы продаж финансов
		 insert into dbo.Report_Carmoney_KPI_SalesPlan_2021
		SELECT (DATEADD(month, DATEDIFF(month, 0, [Период]), 0) ) [Дата начала месяца],[Период]
		,ЗначениеПоказателя, Показатель , templ.rws,templ.ind
	    from [Stg].[files].[ReportKPI_FinPlan_buffer] plan_fin
		UNPIVOT (
			ЗначениеПоказателя FOR Показатель IN ([Портфель всего, в т#ч#]
      ,[без просрочки]
      ,[просрочка 1-90 дней]
      ,[просрочка 90+ дней]
      ,[в т#ч# просрочка 360+ дней]
      ,[Активные займы всего, в т#ч#]
      ,[без просрочки1]
      ,[просрочка 1-90 дней1]
      ,[просрочка 90+ дней1]
      ,[в т#ч# просрочка 360+ дней1]
      ,[ВЫРУЧКА ПО ОПЛАТЕ]
      ,[НАЧИСЛЕННАЯ ВЫРУЧКА]
      ,[РЕЗЕРВ на ОД (на дату отчета)]
      ,[РЕЗЕРВ на % (на дату отчета)]
      ,[РЕЗЕРВ (ВСЕГО)  (на дату отчета)]
      ,[Доля РЕЗЕРВА от КП])
		) unpvt
		left join (select rws,ind,ind_plan from [dbo].[dm_Report_KPI_template_2021] group by rws ,ind ,ind_plan) templ on templ.ind_plan = unpvt.Показатель
		--where templ.ind_plan = 'Доля РЕЗЕРВА от КП'

		-- временно для целей теста проверим загрузку в витрину
		-- создадим календарь
		drop table if exists #calend
		select [Дата начала месяца], ДатаОтчетаКонецПериода = case when [Дата конец месяца] > Getdate() then cast(Getdate() as date) else [Дата конец месяца] end
		, rn = ROW_NUMBER() over (partition by null order by [Дата начала месяца] desc)
		into #calend
		from dbo.Report_Carmoney_KPI_SalesPlan_2021
		where Year([Дата начала месяца]) > 2019 and [Дата начала месяца] < Getdate()
		group by [Дата начала месяца], [Дата конец месяца]
		

		--select * from #calend

		-- заполним отчет на основании шаблона

		--select * from [dbo].[dm_Report_KPI_template_2021]

		truncate table [dbo].[dm_Report_KPI_2021]

		insert into [dbo].[dm_Report_KPI_2021]
		select 
		rk = rank() over(order by(calend.[Дата начала месяца]) desc) 
      
	  , 
	  calend.[Дата начала месяца]

      ,tmpl.[rws]
      ,tmpl.[col]
      ,tmpl.[ind]
      ,tmpl.[st]
      , [qty] =  case
					  when tmpl.st = N'План' then	  SalesPlan.ЗначениеПоказателя 
					  else null
				 end
	  from [dbo].[dm_Report_KPI_template_2021] tmpl
	  cross join #calend calend
	  left join dbo.Report_Carmoney_KPI_SalesPlan_2021 SalesPlan
	  on tmpl.st = N'План' and SalesPlan.[Дата начала месяца] = calend.[Дата начала месяца]
	  and SalesPlan.ind =tmpl.ind


		--SELECT TOP (1000) [rk]
  --    ,[acc_period]
  --    ,[rws]
  --    ,[col]
  --    ,[ind]
  --    ,[st]
  --    ,[qty]
  --FROM [dbo].[dm_Report_KPI_2021]
  --where ind = 'Кол-во заявок' and st = 'План'

  --select * FROM [dbo].[dm_Report_KPI_2021] 

  -- загрузим факты по кол-ву заявок
  --select top 100 *
  --FROM [dbo].[dm_Factor_Analysis_001]

  drop table if exists #cntRequestFact

  select  (DATEADD(month, DATEDIFF(month, 0, ДатаЗаявкиПолная), 0) ) [Дата начала месяца], sum(-Дубль+1) КолвоЗаявокФакт, N'Кол-во заявок' ind
  into #cntRequestFact
  FROM [dbo].[dm_Factor_Analysis_001] with(nolock)
  group by (DATEADD(month, DATEDIFF(month, 0, ДатаЗаявкиПолная), 0) ) 

  --select * from #cntRequestFact
  update u
  set u.qty = newFact.КолвоЗаявокФакт
  from [dbo].[dm_Report_KPI_2021] u
  inner join #cntRequestFact newFact on newFact.[Дата начала месяца] = u.acc_period
  and u.ind = newFact.ind and u.st = N'Факт'

  -- загрузим факты по кол-ву выданных займов
  --select top 100 *  FROM [dbo].[report_Agreement_InterestRate] where СуммаДопУслуг <>0

  drop table if exists #intRate

  select ДатаВыдачи
		,СуммаДопУслугЗаВычетомПартнерскойКомиссии_Net
		,КолвоЗаймов
		,СуммаВыдачи
		,ПризнакКП
		,СуммаДопУслуг
  into #intRate
  FROM [dbo].[report_Agreement_InterestRate]  (nolock)

  drop table if exists #cntLoansFact

    select  (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачи), 0) ) [Дата начала месяца]
  --, sum( (1 - 0.2/1.2)*СуммаДопУслуг) Факт
  --, sum(isnull([SumEnsur]       *0.95   , 0)+
	 -- isnull([SumRat]         *0.75   , 0)+
	 -- isnull([SumKasko]       *0.86   , 0)+
	 -- isnull([SumPositiveMood]*0.67   , 0)+
	 -- isnull([SumHelpBusiness]*0.73   , 0)+
	 -- isnull([SumTeleMedic]   *0.67   , 0)+
	 -- isnull([SumCushion]     *0.4    , 0)) 
	, Sum(СуммаДопУслугЗаВычетомПартнерскойКомиссии_Net)
	  Факт
  , N'Сумма страховки Полученная в ДОХОД' ind 
  into #cntLoansFact
  FROM #intRate --[dbo].[report_Agreement_InterestRate] --with(nolock)
  group by (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачи), 0) ) 

  --select * from #cntLoansFact order by [Дата начала месяца]

  insert  into #cntLoansFact
  select  (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачи), 0) ) [Дата начала месяца], sum(КолвоЗаймов) Факт, N'Кол-во займов' ind
  --into #cntLoansFact
  FROM #intRate --[dbo].[report_Agreement_InterestRate] --with(nolock)
  group by (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачи), 0) ) 

  insert  into #cntLoansFact
  select  (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачи), 0) ) [Дата начала месяца], sum(СуммаВыдачи) Факт, N'Сумма займов' ind 
  FROM #intRate --[dbo].[report_Agreement_InterestRate] --with(nolock)
  group by (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачи), 0) ) 
 -- order by (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачи), 0) )  desc
  
  insert  into #cntLoansFact
  select  (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачи), 0) ) [Дата начала месяца], sum(ПризнакКП) Факт, N'Кол-во займов со страховкой' ind 
  FROM #intRate --[dbo].[report_Agreement_InterestRate] --with(nolock)
  group by (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачи), 0) ) 

  insert  into #cntLoansFact
  select  (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачи), 0) ) [Дата начала месяца], sum(СуммаДопУслуг) Факт, N'Сумма страховки по Договору' ind 
  FROM #intRate --[dbo].[report_Agreement_InterestRate] --with(nolock)
  group by (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачи), 0) ) 


  /*
  select  (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачиПолн), 0) ) [Дата начала месяца]
  --, sum( (1 - 0.2/1.2)*СуммаДопУслуг) Факт
  , sum(isnull([SumEnsur]       *0.95   , 0)+
	  isnull([SumRat]         *0.75   , 0)+
	  isnull([SumKasko]       *0.86   , 0)+
	  isnull([SumPositiveMood]*0.67   , 0)+
	  isnull([SumHelpBusiness]*0.73   , 0)+
	  isnull([SumTeleMedic]   *0.67   , 0)+
	  isnull([SumCushion]     *0.4    , 0)) Факт
  , N'Сумма страховки Полученная в ДОХОД' ind 
  into #cntLoansFact
  FROM [dbo].[report_Agreement_InterestRate] with(nolock)
  group by (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачиПолн), 0) ) 

  insert  into #cntLoansFact
  select  (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачиПолн), 0) ) [Дата начала месяца], sum(КолвоЗаймов) Факт, N'Кол-во займов' ind
  --into #cntLoansFact
  FROM [dbo].[report_Agreement_InterestRate] with(nolock)
  group by (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачиПолн), 0) ) 

  insert  into #cntLoansFact
  select  (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачиПолн), 0) ) [Дата начала месяца], sum(СуммаВыдачи) Факт, N'Сумма займов' ind 
  FROM [dbo].[report_Agreement_InterestRate] with(nolock)
  group by (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачиПолн), 0) ) 
  order by (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачиПолн), 0) )  desc
  
  insert  into #cntLoansFact
  select  (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачиПолн), 0) ) [Дата начала месяца], sum(ПризнакКП) Факт, N'Кол-во займов со страховкой' ind 
  FROM [dbo].[report_Agreement_InterestRate] with(nolock)
  group by (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачиПолн), 0) ) 

  insert  into #cntLoansFact
  select  (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачиПолн), 0) ) [Дата начала месяца], sum(СуммаДопУслуг) Факт, N'Сумма страховки по Договору' ind 
  FROM [dbo].[report_Agreement_InterestRate] with(nolock)
  group by (DATEADD(month, DATEDIFF(month, 0, ДатаВыдачиПолн), 0) ) 
  */


  --select * from #cntLoansFact
  update u
  set u.qty = newFact.Факт
  from [dbo].[dm_Report_KPI_2021] u
  inner join #cntLoansFact newFact on newFact.[Дата начала месяца] = u.acc_period
  and u.ind = newFact.ind and u.st = N'Факт'

  -- прогноз - для прошлых периодов факт
  Declare @koof  numeric(10,8) = 0.0,
  @curDay numeric(10,8) = cast(Day(Getdate()) as numeric(10,8)) ,
  @lastDay numeric(10,8) = cast(Day(EOmonth(Getdate()))  as numeric(10,8))

 
  Set @koof = 1.0 + (1.0/@curDay)*(@lastDay - @curDay)


  select @koof

  update u
  set u.qty = newFuture.qty
  from [dbo].[dm_Report_KPI_2021] u
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'Факт') newFuture on newFuture.acc_period = u.acc_period
  and u.ind = newFuture.ind and u.st = N'Прогноз'
  and u.ind in (N'Кол-во заявок',N'Кол-во займов',N'Сумма займов',N'Кол-во займов со страховкой',N'Сумма страховки по Договору',N'Сумма страховки Полученная в ДОХОД')
  and newFuture.acc_period <> cast(DATEADD(month, DATEDIFF(month, 0, GetDate()), 0)  as date)

  
  update u
  set u.qty = @koof*newFuture.qty
  from [dbo].[dm_Report_KPI_2021] u
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'Факт') newFuture on newFuture.acc_period = u.acc_period
  and u.ind = newFuture.ind and u.st = N'Прогноз'
  and u.ind in (N'Кол-во заявок',N'Кол-во займов',N'Сумма займов',N'Кол-во займов со страховкой',N'Сумма страховки по Договору',N'Сумма страховки Полученная в ДОХОД')
  and newFuture.acc_period = cast(DATEADD(month, DATEDIFF(month, 0, GetDate()), 0)  as date)

  -- рассчитаем отношение к фактическим в виде нового --
  -- делаем таблицу коэф 
    drop table if exists #tKoof
	-- первое значение  это показатель
	-- второе значение это коэфициент
	-- третье значение это показатель RR
	-- четвертое значение это период
	Select 
	  cast( (tFact.qty/tPlan.qty) as float) as koof 
	, cast( (tFact.qty/tPlan.qty) as float) * tPlan_m.qty as qty --Prognoz
	--, tPlan_m.qty
	, 'Прогноз' as st
	, tFact.acc_period
	, tFact.ind
	--,  * --from #dailyPlan p
	into #tKoof
		from 
		-- будем сравнивать с фактом
		(select * from [dbo].[dm_Report_KPI_2021]  where st = N'Факт') tFact
		-- по текущую дату
	    join (
			select [Дата начала месяца] as acc_period
			, Sum(ЗначениеПоказателя) as qty
			, Показатель as ind 
			--, Дата
			from #dailyPlan p
			where cast(p.Дата as date) between cast(DATEADD(month, DATEDIFF(month, 0, GetDate()), 0)  as date) and cast(getdate() as date)
			group by [Дата начала месяца],  Показатель 
			) tPlan 
			on tFact.acc_period = tPlan.acc_period and tFact.ind = tPlan.ind  
		-- и за месяц
		join (
			select [Дата начала месяца] as acc_period
			, Sum(ЗначениеПоказателя) as qty
			, Показатель as ind 
			--, Дата			 
			from #dailyPlan p
			where cast(p.Дата as date) between cast(DATEADD(month, DATEDIFF(month, 0, GetDate()), 0)  as date) and cast([Дата конец месяца] as date)
			group by [Дата начала месяца],  Показатель 
			) tPlan_m 
			on tFact.acc_period = tPlan_m.acc_period and tFact.ind = tPlan_m.ind  


			-- собственно обновления за текущий месяц для расчета прогноза. Сам RR расчет внизу
  update u
  set u.qty = newFuture.qty
  from [dbo].[dm_Report_KPI_2021] u
  inner join #tKoof newFuture on newFuture.acc_period = u.acc_period
  and u.ind = newFuture.ind and u.st = newFuture.st --N'Прогноз'
  and u.ind in (N'Кол-во заявок',N'Кол-во займов',N'Сумма займов'
  ,N'Кол-во займов со страховкой',N'Сумма страховки по Договору',N'Сумма страховки Полученная в ДОХОД'
  )
  and newFuture.acc_period = cast(DATEADD(month, DATEDIFF(month, 0, GetDate()), 0)  as date)


  -- расчеты
  -- средний чек
  update u
  set u.qty = valSum.qty/valCount.qty
  from [dbo].[dm_Report_KPI_2021] u
  inner join [dbo].[dm_Report_KPI_2021] valSum
  on valSum.acc_period = u.acc_period and valSum.st = u.st and valSum.ind = N'Сумма займов'
  inner join [dbo].[dm_Report_KPI_2021] valCount
  on valCount.acc_period = u.acc_period and valCount.st = u.st and valCount.ind = N'Кол-во займов'
  where u.ind = N'Средний размер займа'
  and u.st in (N'Факт',N'План',N'Прогноз')
  --inner join (select * from [dbo].[dm_Report_KPI_2021] 

  --% выполнения
    update u
  set u.qty = newFact.qty/newFuture.qty
  from [dbo].[dm_Report_KPI_2021] u
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'Прогноз') newFact on newFact.acc_period = u.acc_period and u.ind = newFact.ind 
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'План') newFuture on newFuture.acc_period = u.acc_period and u.ind = newFuture.ind 
  where 
    u.st = N'% выполнения'
  and u.ind in (N'Кол-во заявок',N'Кол-во займов',N'Сумма займов',N'Кол-во займов со страховкой',N'Сумма страховки по Договору',N'Сумма страховки Полученная в ДОХОД',N'Средний размер займа')
  --and newFuture.acc_period <> cast(DATEADD(month, DATEDIFF(month, 0, GetDate()), 0)  as date)

  -- портфель
  drop table if exists #portfolio
  
  select Период, Sum([остаток од]) 'Остаток ОД', Count(external_id) as 'КолвоЗаймов', backet, backetCnt
  into #portfolio
  from 
  (
  select 
		external_id
	  --, b.d Период
	  , calend.[Дата начала месяца] Период
	  , [остаток од] --, dpd,
	  , case  
			when dpd = 0 then N'без просрочки (КП)'
			when dpd between 1 and 90 then N'просрочка 1-90 дней (КП)'
			when dpd between 91 and 360 then N'просрочка 91-360 дней (КП)'
			when dpd > 360 then N'в т.ч. просрочка 360+ дней (КП)'
			when dpd is null then N'без просрочки (КП)'
			else N'Нет'
		end backet
		, case  
			when dpd = 0 then N'без просрочки (КП), шт.'
			when dpd between 1 and 90 then N'просрочка 1-90 дней (КП), шт.'
			when dpd between 91 and 360 then N'просрочка 91-360 дней (КП), шт'
			when dpd > 360 then N'в т.ч. просрочка 360+ дней (КП), шт.'
			when dpd is null then N'без просрочки (КП), шт.'
			else N'Нет'
		end backetCnt
  from dbo.dm_CMRStatBalance_2 b
  left join #calend calend on b.d = calend.ДатаОтчетаКонецПериода
  where b.d in ( select [ДатаОтчетаКонецПериода] from  #calend)--= cast(Getdate() as date)
  ) portfolio
  group by Период,backet, backetCnt
  order by  Период,backet, backetCnt
  
  insert into #portfolio
  select Период, Sum([остаток од]) 'Остаток ОД', Count(external_id) as 'КолвоЗаймов', backet, backetCnt
  from 
  (
  select 
		external_id
	  --, b.d Период
	  , calend.[Дата начала месяца] Период
	  , [остаток од] --, dpd,
	  , N'Портфель всего (КП)' as backet
	  , N'Портфель всего (КП), шт.' as backetCnt
  from dbo.dm_CMRStatBalance_2 b
  left join #calend calend on b.d = calend.ДатаОтчетаКонецПериода
  where b.d in ( select [ДатаОтчетаКонецПериода] from  #calend)--= cast(Getdate() as date)
  ) portfolio
  group by Период,backet, backetCnt
  order by  Период,backet, backetCnt


   insert into #portfolio
   select Период, Sum([остаток од]) 'Остаток ОД', Count(external_id) as 'КолвоЗаймов', backet  , backetCnt
  from 
  (
  select 
		external_id
	  --, b.d Период
	  , calend.[Дата начала месяца] Период
	  , [остаток од] --, dpd,
	  , case 
			when dpd > 90 then N'просрочка 90+ дней (КП)'
			
			else N'Нет'
		end backet
	 , case 
			when dpd > 90 then N'просрочка 90+ дней (КП), шт.'
			
			else N'Нет'
		end backetCnt
  from dbo.dm_CMRStatBalance_2 b
  left join #calend calend on b.d = calend.ДатаОтчетаКонецПериода
  where b.d in ( select [ДатаОтчетаКонецПериода] from  #calend)--= cast(Getdate() as date)
  ) portfolio
  where backet = N'просрочка 90+ дней (КП)'
  group by Период,backet, backetCnt
  order by  Период,backet, backetCnt

  --select * from #portfolio
  --order by Период, backet

  -- обновим
    --select * from [dbo].[dm_Report_KPI_2021]
  update u
  set u.qty = newFact.[Остаток ОД]
  from [dbo].[dm_Report_KPI_2021] u
  inner join #portfolio newFact on newFact.Период = u.acc_period
  and u.ind = newFact.backet and u.st = N'Факт'

  update u
  set u.qty = newFact.КолвоЗаймов
  from [dbo].[dm_Report_KPI_2021] u
  inner join #portfolio newFact on newFact.Период = u.acc_period
  and u.ind = newFact.backetCnt and u.st = N'Факт'

  -- прогноз
  update u
  set u.qty = newFuture.qty
  from [dbo].[dm_Report_KPI_2021] u
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'Факт') newFuture on newFuture.acc_period = u.acc_period
  and u.ind = newFuture.ind and u.st = N'Прогноз'
  and u.ind in (N'Портфель всего (КП)'
				,N'без просрочки (КП)'
				,N'просрочка 1-90 дней (КП)'
				,N'просрочка 90+ дней (КП)'
				,N'в т.ч. просрочка 360+ дней (КП)'
				,N'Портфель всего (КП), шт.'
				,N'без просрочки (КП), шт.'
				,N'просрочка 1-90 дней (КП), шт.'
				,N'просрочка 90+ дней (КП), шт.'
				,N'в т.ч. просрочка 360+ дней (КП), шт.')
  and newFuture.acc_period <> cast(DATEADD(month, DATEDIFF(month, 0, GetDate()), 0)  as date)

    -- прогноз -  найдем новый коэфициент для расчета 
	  Declare @koof2 decimal(20,8)
	  Set @koof2 = (select top 1 
	  --qty
	  --,fv =  FIRST_VALUE(qty) over (partition by ind order by rk )
	  --, lv = LAST_VALUE(qty) over (partition by ind order by rk )
	  --,lag(qty) over (partition by ind order by rk desc)
	  --, qty - lag(qty) over (partition by ind order by rk desc)
	  --, 
	  koof = 1+(qty - lag(qty) over (partition by ind order by rk desc))/qty
	  --,*
	  from [dbo].[dm_Report_KPI_2021] u
	  where u.acc_period in (select [Дата начала месяца] from #calend where rn in(1,2))
	  and ind =N'Портфель всего (КП)' and st = 'Факт'
	  order by rk )

  update u
  set u.qty = newFuture.qty*@koof2
  from [dbo].[dm_Report_KPI_2021] u
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'Факт') newFuture on newFuture.acc_period = u.acc_period
  and u.ind = newFuture.ind and u.st = N'Прогноз'
  and u.ind in (N'Портфель всего (КП)'
				,N'без просрочки (КП)'
				,N'просрочка 1-90 дней (КП)'
				,N'просрочка 90+ дней (КП)'
				,N'в т.ч. просрочка 360+ дней (КП)'
				,N'Портфель всего (КП), шт.'
				,N'без просрочки (КП), шт.'
				,N'просрочка 1-90 дней (КП), шт.'
				,N'просрочка 90+ дней (КП), шт.'
				,N'в т.ч. просрочка 360+ дней (КП), шт.')
  and newFuture.acc_period = cast(DATEADD(month, DATEDIFF(month, 0, GetDate()), 0)  as date)


   --% выполнения
    update u
  --set u.qty = newFact.qty/newFuture.qty
  set u.qty = case when newFuture.qty =0 then 0 else newFact.qty/newFuture.qty end
  from [dbo].[dm_Report_KPI_2021] u
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'Прогноз') newFact on newFact.acc_period = u.acc_period and u.ind = newFact.ind 
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'План') newFuture on newFuture.acc_period = u.acc_period and u.ind = newFuture.ind 
  where 
    u.st = N'% выполнения'
  and u.ind in (N'Портфель всего (КП)'
				,N'без просрочки (КП)'
				,N'просрочка 1-90 дней (КП)'
				,N'просрочка 90+ дней (КП)'
				,N'в т.ч. просрочка 360+ дней (КП)'
				,N'Портфель всего (КП), шт.'
				,N'без просрочки (КП), шт.'
				,N'просрочка 1-90 дней (КП), шт.'
				,N'просрочка 90+ дней (КП), шт.'
				,N'в т.ч. просрочка 360+ дней (КП), шт.')

    -----------------------------------------
	-- сумма накопительно факт
	----------------------------------------
	drop table if exists #sum_accum
	select Сумма =sum(p.qty) over (partition by p.ind order by p.acc_period rows between unbounded preceding and current row) 
	+  10094100772   
	, p.acc_period
	, p.qty
	, N'Сумма займов накопительно' as ind
	, N'Факт' as st
	into #sum_accum
	 from [dbo].[dm_Report_KPI_2021] p
	 where ind = N'Сумма займов' and p.st = N'Факт'

	-- select * from  #sum_accum
  update u
  set u.qty = newFact.Сумма
  from [dbo].[dm_Report_KPI_2021] u
  inner join #sum_accum newFact on newFact.acc_period = u.acc_period
  and u.ind = newFact.ind and u.st = newFact.st -- N'Факт'


  -- накопительно план
  	drop table if exists #sum_accum_plan
	select Сумма = p.qty - sum_fact.qty + sum_plan.qty, 
	sum_fact.qty aa, sum_plan.qty bb
	, p.acc_period
	, p.qty
	, N'Сумма займов накопительно' as ind
	, N'План' st
	into #sum_accum_plan
	from [dbo].[dm_Report_KPI_2021] p
	left join (select * from [dbo].[dm_Report_KPI_2021] where ind = N'Сумма займов' and st = N'Факт') sum_fact on sum_fact.acc_period = p.acc_period 
    left join (select * from [dbo].[dm_Report_KPI_2021] where ind = N'Сумма займов'and st = N'План') sum_plan on sum_plan.acc_period = p.acc_period 
	 where p.ind = N'Сумма займов накопительно' and p.st = N'Факт'

	--select * from  #sum_accum_plan

  update u
  set u.qty = newPlan.Сумма
  from [dbo].[dm_Report_KPI_2021] u
  inner join #sum_accum_plan newPlan on newPlan.acc_period = u.acc_period
  and u.ind = newPlan.ind and u.st = newPlan.st -- N'Факт'

    -- накопительно прогноз
  	drop table if exists #sum_accum_prognoz
	select Сумма = p.qty - sum_fact.qty + sum_prognoz.qty, 
	sum_fact.qty aa, sum_prognoz.qty bb
	, p.acc_period
	, p.qty
	, N'Сумма займов накопительно' as ind
	, N'Прогноз' st
	into #sum_accum_prognoz
	from [dbo].[dm_Report_KPI_2021] p
	left join (select * from [dbo].[dm_Report_KPI_2021] where ind = N'Сумма займов' and st = N'Факт') sum_fact on sum_fact.acc_period = p.acc_period 
    left join (select * from [dbo].[dm_Report_KPI_2021] where ind = N'Сумма займов'and st = N'Прогноз') sum_prognoz on sum_prognoz.acc_period = p.acc_period 
	 where p.ind = N'Сумма займов накопительно' and p.st = N'Факт'

	select * from  #sum_accum_prognoz

  update u
  set u.qty = newprognoz.Сумма
  from [dbo].[dm_Report_KPI_2021] u
  inner join #sum_accum_prognoz newprognoz on newprognoz.acc_period = u.acc_period
  and u.ind = newprognoz.ind and u.st = newprognoz.st -- N'Факт'

   --% выполнения сумма выданных накопительно
    update u
  set u.qty = newFact.qty/newFuture.qty
  from [dbo].[dm_Report_KPI_2021] u
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'Прогноз') newFact on newFact.acc_period = u.acc_period and u.ind = newFact.ind 
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'План') newFuture on newFuture.acc_period = u.acc_period and u.ind = newFuture.ind 
  where 
    u.st = N'% выполнения'
  and u.ind in (N'Сумма займов накопительно')
  --and newFuture.acc_period <> cast(DATEADD(month, DATEDIFF(month, 0, GetDate()), 0)  as date)

  -- выручка
  drop table if exists  #procent
  select sum([Проценты уплачено]) уплачено
  ,sum([Проценты начислено]) начислено
  ,Year(b.d) y
  , Month(b.d) m
  ,min(calend.[Дата начала месяца]) acc_period
  , ind1 = N'ВЫРУЧКА ПО ОПЛАТЕ'
  ,ind2 = N'НАЧИСЛЕННАЯ ВЫРУЧКА'
  , N'Факт' as st
  into #procent
--, *
  from dbo.dm_CMRStatBalance_2 b
   join #calend calend on Year(b.d) = Year(calend.ДатаОтчетаКонецПериода) 
  and Month(b.d) = Month(calend.ДатаОтчетаКонецПериода)
  --where [Проценты начислено  нарастающим итогом] > 0    
  --and b.d in ( select [ДатаОтчетаКонецПериода] from  #calend)
  group by Year(b.d)
  , Month(b.d)
  order by  Year(b.d)
  , Month(b.d)


  -- новый вариант с 2021 года расчет
  --delete from #procent where y >=2021
  --select --p.уплачено as qq,
  --select * from #procent
  

  drop table if exists #new_procent
  select 
    Year(ПериодУчета) y
   , Month(ПериодУчета) m
   , Sum(ПроцентыОплачено)  уплачено
   into #new_procent
from [dbo].[dm_Telegram_Collection_Detail_New_Alternative] t
where ПериодУчета > '2020-09-30'
group by ПериодУчета


--select * from #new_procent
    update p
  set p.уплачено = t.уплачено
--Year(ПериодУчета) y
--, Month(ПериодУчета) m
--,  Sum(ПроцентыОплачено)  уплачено
from #procent p
 join #new_procent t on p.m = t.m and p.y = t.y

  --
  --select * from #procent
  --select * from #procent

    update u
  set u.qty = newFact.уплачено
  from [dbo].[dm_Report_KPI_2021] u
  inner join #procent newFact on newFact.acc_period = u.acc_period
  and u.ind = newFact.ind1 and u.st = newFact.st -- N'Факт'

      update u
  set u.qty = newFact.начислено
  from [dbo].[dm_Report_KPI_2021] u
  inner join #procent newFact on newFact.acc_period = u.acc_period
  and u.ind = newFact.ind2 and u.st = newFact.st -- N'Факт'

    -- прогноз - для прошлых периодов факт
  Declare @koof3  numeric(10,8) = 0.0,
  @curDay3 numeric(10,8) = cast(Day(Getdate()) as numeric(10,8)) ,
  @lastDay3 numeric(10,8) = cast(Day(EOmonth(Getdate()))  as numeric(10,8))

 
  Set @koof3 = 1.0 + (1.0/@curDay3)*(@lastDay3 - @curDay3)


  select @koof3

  update u
  set u.qty = newFuture.qty
  from [dbo].[dm_Report_KPI_2021] u
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'Факт') newFuture on newFuture.acc_period = u.acc_period
  and u.ind = newFuture.ind and u.st = N'Прогноз'
  and u.ind in  (N'ВЫРУЧКА ПО ОПЛАТЕ',N'НАЧИСЛЕННАЯ ВЫРУЧКА')
  and newFuture.acc_period <> cast(DATEADD(month, DATEDIFF(month, 0, GetDate()), 0)  as date)

  
  update u
  set u.qty = @koof3*newFuture.qty
  from [dbo].[dm_Report_KPI_2021] u
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'Факт') newFuture on newFuture.acc_period = u.acc_period
  and u.ind = newFuture.ind and u.st = N'Прогноз'
  and u.ind in (N'ВЫРУЧКА ПО ОПЛАТЕ',N'НАЧИСЛЕННАЯ ВЫРУЧКА')
  and newFuture.acc_period = cast(DATEADD(month, DATEDIFF(month, 0, GetDate()), 0)  as date)


   --% выполнения выручка
    update u
  set u.qty = newFact.qty/newFuture.qty
  from [dbo].[dm_Report_KPI_2021] u
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'Прогноз') newFact on newFact.acc_period = u.acc_period and u.ind = newFact.ind 
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'План') newFuture on newFuture.acc_period = u.acc_period and u.ind = newFuture.ind 
  where 
    u.st = N'% выполнения'
  and u.ind in (N'ВЫРУЧКА ПО ОПЛАТЕ',N'НАЧИСЛЕННАЯ ВЫРУЧКА')
  --and newFuture.acc_period <> cast(DATEADD(month, DATEDIFF(month, 0, GetDate()), 0)  as date)


  --- резервы

  Declare @cdate_max date
  , @calend_max date

  Set @cdate_max = (select max(cdate) from dbo.dm_UMFO_reserve)
  Set @calend_max = (select max(ДатаОтчетаКонецПериода) from #calend)
  /*

  -- резервы не всегда есть
  drop table if exists #calend_reserve
  select * into #calend_reserve from #calend
  --select *from #calend
  --select *from #calend_reserve
  update u
  set u.ДатаОтчетаКонецПериода = @cdate_max
  from #calend_reserve u
  where u.ДатаОтчетаКонецПериода = @calend_max
  --select *from #calend_reserve
   -- резервы
  drop table if exists  #reserve
  select sum(rserve_sum) reserve
    , Year(cdate) y
	, Month(cdate) m
	, min(calend.[Дата начала месяца]) acc_period
    , ind = N'РЕЗЕРВ (ВСЕГО)  (на дату отчета)'  
  , N'Факт' as st
  into #reserve
  from dbo.dm_UMFO_reserve b
   join #calend_reserve calend on cast(cdate as date) = cast(calend.ДатаОтчетаКонецПериода as date)
  
  where  cdate in ( select [ДатаОтчетаКонецПериода] from  #calend) or cdate = @cdate_max
  group by Year(cdate)
  , Month(cdate)
  order by  Year(cdate)
  , Month(cdate)

  --select * from #reserve
  --order by acc_period

  
      update u
  set u.qty = newFact.reserve
  from [dbo].[dm_Report_KPI_2021] u
  inner join #reserve newFact on newFact.acc_period = u.acc_period
  and u.ind = newFact.ind and u.st = newFact.st -- N'Факт'
  */

     ------------- [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]-----------------
   ------------- новый вариант резервов	
     --Declare @cdate_max date
     --      , @calend_max date
		   -----------------
     Set @cdate_max = (select dateadd(year, -2000,max(ДатаОтчета)) from [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]
	 where dateadd(year, -2000,(ДатаОтчета))  < cast(getdate() as date))
    -- Set @calend_max = (select max(ДатаОтчетаКонецПериода) from #calend)

	
	 select @cdate_max

	 drop table if exists #t_resrv
	select dateadd(year, -2000,max(ДатаОтчета)) ДатаОтчета,Sum(ОстатокРезерв) reserve, sum(res.[РезервБУОД])  + Sum(res.[РезервБУПроценты]) РезервыВсего, sum(res.[РезервБУОД]) РезервОД
      ,Sum(res.[РезервБУПроценты]) РезервПроценты  
	  into #t_resrv
	  from [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]  res
	--where --Статус ='Действует' and 
	--ДатаОтчета ='4021-01-31 00:00:00'
	group by ДатаОтчета

 -- резервы не всегда есть - выводим последний доступный
  drop table if exists #calend_reserve2
  select * into #calend_reserve2 from #calend
  --select *from #calend
  --select *from #calend_reserve
  update u
  set u.ДатаОтчетаКонецПериода = @cdate_max
  from #calend_reserve2 u
  where u.ДатаОтчетаКонецПериода = @calend_max
  --select *from #calend_reserve



   -- резервы
  drop table if exists  #reserve_new

    --insert into #reserve_new
    select reserve reserve
	--,b.* --
	, (calend.[Дата начала месяца]) acc_period
    , ind = N'РЕЗЕРВ (ВСЕГО)  (на дату отчета)'  
  , N'Факт' as st
  into #reserve_new
  from #t_resrv b
   join #calend_reserve2 calend on cast(ДатаОтчета as date) = cast(calend.ДатаОтчетаКонецПериода as date)     
  where  cast(ДатаОтчета as date) in ( select [ДатаОтчетаКонецПериода] from  #calend) or cast(ДатаОтчета as date) = @cdate_max

  insert into #reserve_new
  select РезервОД reserve
	--,b.* --
	, (calend.[Дата начала месяца]) acc_period
    , ind = N'РЕЗЕРВ на ОД (на дату отчета)'  
  , N'Факт' as st
  --into #reserve_new
  from #t_resrv b
   join #calend_reserve2 calend on cast(ДатаОтчета as date) = cast(calend.ДатаОтчетаКонецПериода as date)     
  where  cast(ДатаОтчета as date) in ( select [ДатаОтчетаКонецПериода] from  #calend) or cast(ДатаОтчета as date) = @cdate_max
  
  --      update u
  --set u.qty = newFact.reserve
  --from [dbo].[dm_Report_KPI_2021] u
  --inner join #reserve_new newFact on newFact.acc_period = u.acc_period
  --and u.ind = newFact.ind and u.st = newFact.st -- N'Факт'

  insert into #reserve_new
    select РезервПроценты reserve
	--,b.* --
	, (calend.[Дата начала месяца]) acc_period
    , ind = N'РЕЗЕРВ на % (на дату отчета)'  
  , N'Факт' as st
  
  from #t_resrv b
   join #calend_reserve2 calend on cast(ДатаОтчета as date) = cast(calend.ДатаОтчетаКонецПериода as date)     
  where  cast(ДатаОтчета as date) in ( select [ДатаОтчетаКонецПериода] from  #calend) or cast(ДатаОтчета as date) = @cdate_max
  
  --      update u
  --set u.qty = newFact.reserve
  --from [dbo].[dm_Report_KPI_2021] u
  --inner join #reserve_new newFact on newFact.acc_period = u.acc_period
  --and u.ind = newFact.ind and u.st = newFact.st -- N'Факт'


  
        update u
  set u.qty = newFact.reserve
  from [dbo].[dm_Report_KPI_2021] u
  inner join #reserve_new newFact on newFact.acc_period = u.acc_period
  and u.ind = newFact.ind and u.st = newFact.st -- N'Факт'

	/*

	     Declare @cdate_max date
           , @calend_max date
	Set @cdate_max = (select max(cdate) from dbo.dm_UMFO_reserve)

	select  sum(rserve_sum) from dbo.dm_UMFO_reserve
	where cast(cdate as date) = '2021-01-31'

	select top 10 cdate,external_id,rserve_sum, '--новый отчет--', ОстатокРезерв, РезервБУОД, РезервБУПроценты, РезервБУПрочие, ОстатокРезервНУ, РезервНУОД, РезервНУПроценты, РезервНУПрочие from dbo.dm_UMFO_reserve r1
	left join [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных] r2
	on r1.external_id = r2.НомерДоговора
	where cast(cdate as date) = '2021-01-31' and ДатаОтчета ='4021-01-31 00:00:00'
	and external_id ='18042622380001'
	*/



   ---

  -- прогноз резервов
  update u
  set u.qty = newFuture.qty
  from [dbo].[dm_Report_KPI_2021] u
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'Факт') newFuture on newFuture.acc_period = u.acc_period
  and u.ind = newFuture.ind and u.st = N'Прогноз'
  --and u.ind in (N'РЕЗЕРВ (ВСЕГО)  (на дату отчета)' )
  and u.ind in (N'РЕЗЕРВ (ВСЕГО)  (на дату отчета)',N'РЕЗЕРВ на ОД (на дату отчета)' ,N'РЕЗЕРВ на % (на дату отчета)'  )
  and newFuture.acc_period <> cast(DATEADD(month, DATEDIFF(month, 0, GetDate()), 0)  as date)

    -- прогноз -  найдем новый коэфициент для расчета 
	  Declare @koof4 decimal(20,8),
	  @check1 decimal(20,8)

	   Set @check1 = (select top 1 qty
	  --,*
	  from [dbo].[dm_Report_KPI_2021] u
	  where u.acc_period in (select [Дата начала месяца] from #calend where rn in(1,2))
	  and ind =N'РЕЗЕРВ (ВСЕГО)  (на дату отчета)' and st = 'Факт'
	  order by rk )
	  
	  --select iif(isnull(@check1,0.0) = 0, 0,1)

	  if iif(isnull(@check1,0.0) = 0.0, 0,1) = 1
	  begin
	 -- select @check1
	  Set @koof4 = (select top 1 
	  --qty
	  --,fv =  FIRST_VALUE(qty) over (partition by ind order by rk )
	  --, lv = LAST_VALUE(qty) over (partition by ind order by rk )
	  --,lag(qty) over (partition by ind order by rk desc)
	  --, qty - lag(qty) over (partition by ind order by rk desc)
	  --, 
	  koof = 1+(qty - lag(qty) over (partition by ind order by rk desc))/qty
	  --,*
	  from [dbo].[dm_Report_KPI_2021] u
	  where u.acc_period in (select [Дата начала месяца] from #calend where rn in(1,2))
	  and ind =N'РЕЗЕРВ (ВСЕГО)  (на дату отчета)' and st = 'Факт'
	  order by rk )
	  end
	  else
	  begin
	   Set @koof4  = 0
	  end
	 -- select @koof4

  update u
  set u.qty = newFuture.qty*@koof4
  from [dbo].[dm_Report_KPI_2021] u
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'Факт') newFuture on newFuture.acc_period = u.acc_period
  and u.ind = newFuture.ind and u.st = N'Прогноз'
  and u.ind in (N'РЕЗЕРВ (ВСЕГО)  (на дату отчета)',N'РЕЗЕРВ на ОД (на дату отчета)' ,N'РЕЗЕРВ на % (на дату отчета)' )

  and newFuture.acc_period = cast(DATEADD(month, DATEDIFF(month, 0, GetDate()), 0)  as date)


   --% выполнения
    update u
  --set u.qty = newFact.qty/newFuture.qty
  set u.qty = case when newFuture.qty =0 then 0 else newFact.qty/newFuture.qty end
  from [dbo].[dm_Report_KPI_2021] u
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'Прогноз') newFact on newFact.acc_period = u.acc_period and u.ind = newFact.ind 
  inner join (select * from [dbo].[dm_Report_KPI_2021] where st = N'План') newFuture on newFuture.acc_period = u.acc_period and u.ind = newFuture.ind 
  where 
    u.st = N'% выполнения'
  and u.ind in  (N'РЕЗЕРВ (ВСЕГО)  (на дату отчета)',N'РЕЗЕРВ на ОД (на дату отчета)' ,N'РЕЗЕРВ на % (на дату отчета)' )

  -- 
   -----------------------------------------
  -- Доля РЕЗЕРВА от КП
  -- ---------------------------------------
  update u
  set u.qty = reserv.qty/portfolio.qty
 -- select reserv.qty/portfolio.qty, * 
  from [dbo].[dm_Report_KPI_2021] u
  left join (select * from [dbo].[dm_Report_KPI_2021] where ind = N'РЕЗЕРВ (ВСЕГО)  (на дату отчета)') reserv on reserv.acc_period = u.acc_period and u.st = reserv.st 
  left join (select * from [dbo].[dm_Report_KPI_2021] where ind = N'Портфель всего (КП)') portfolio on portfolio.acc_period = u.acc_period and u.st = portfolio.st 
  where u.ind in (N'Доля РЕЗЕРВА от КП') and u.st not in (N'План')

  -----------------------------------------
  -- конвертация
  -- ---------------------------------------
  update u
  set u.qty = loans.qty/requests.qty
 -- select loans.qty/requests.qty, * 
  from [dbo].[dm_Report_KPI_2021] u
  left join (select * from [dbo].[dm_Report_KPI_2021] where ind = N'Кол-во займов') loans on loans.acc_period = u.acc_period and u.st = loans.st 
  left join (select * from [dbo].[dm_Report_KPI_2021] where ind = N'Кол-во заявок') requests on requests.acc_period = u.acc_period and u.st = requests.st 
  where u.ind in (N'Конвертация') --and u.st not in (N'% выполнения')

  --select *   from [dbo].[dm_Report_KPI_2021] 
  --where ind in (N'Конвертация')

  -- take rate
  drop table if exists #cntRequestTakeRate

  select  (DATEADD(month, DATEDIFF(month, 0, ДатаЗаявкиПолная), 0) ) [Дата начала месяца], sum(-Дубль+1) КолвоЗаявокОдобрено, N'Кол-во заявок' ind
  ,count(*) КоличестоЗаявокПризнакОдобрено
  into #cntRequestTakeRate
  FROM [dbo].[dm_Factor_Analysis_001] fa with(nolock)
  where Дубль = 0 and fa.ПризнакОдобрено = 1
  group by (DATEADD(month, DATEDIFF(month, 0, ДатаЗаявкиПолная), 0) ) 

  select * from #cntRequestTakeRate

   -- 
  update u
  set u.qty = loans.qty/requests.КоличестоЗаявокПризнакОдобрено
 -- select loans.qty/requests.qty, * 
  from [dbo].[dm_Report_KPI_2021] u
  left join (select * from [dbo].[dm_Report_KPI_2021] where ind = N'Кол-во займов') loans on loans.acc_period = u.acc_period and u.st = loans.st 
  left join #cntRequestTakeRate requests on requests.[Дата начала месяца] = u.acc_period --and u.st = requests.st 
  where u.ind in (N'Take Rate') and u.st  in (N'Факт')

   -- Approval Rate 
  drop table if exists #cntRequestApprovalRate

  select  (DATEADD(month, DATEDIFF(month, 0, ДатаЗаявкиПолная), 0) ) [Дата начала месяца], sum(-Дубль+1) КолвоЗаявокApprovalRate, N'Кол-во заявок' ind
  ,count(*) cntRequestApprovalRate
  into #cntRequestApprovalRate
  FROM [dbo].[dm_Factor_Analysis_001] fa with(nolock)
 where ((([Отказ документов клиента] is not null or Отказано is not null) and 
  [Верификация КЦ] is not null) or ПризнакОдобрено = 1)
  and Дубль = 0 
  group by (DATEADD(month, DATEDIFF(month, 0, ДатаЗаявкиПолная), 0) ) 

  --select * from #cntRequestApprovalRate

   -- 
  update u
  set u.qty = cast(requestsTake.КоличестоЗаявокПризнакОдобрено as float)/cast(requestsApproval.cntRequestApprovalRate as float)
 --select cast(requestsTake.КоличестоЗаявокПризнакОдобрено as float)/cast(requestsTake.КоличестоЗаявокПризнакОдобрено+requestsApproval.cntRequestApprovalRate as float),requestsTake.КоличестоЗаявокПризнакОдобрено,requestsApproval.cntRequestApprovalRate, * 
  from [dbo].[dm_Report_KPI_2021] u
  left join #cntRequestTakeRate requestsTake on requestsTake.[Дата начала месяца] = u.acc_period --and u.st = requests.st 
  left join #cntRequestApprovalRate requestsApproval on requestsApproval.[Дата начала месяца] = u.acc_period --and u.st = requests.st 
  where u.ind in (N'Approval Rate') and u.st  in (N'Факт')


  --select top 100 * from  [dbo].[dm_Factor_Analysis_001] fa with(nolock)
  --where ([Отказ документов клиента] is not null or Отказано is not null ) and 
  --[Верификация КЦ] is not null

END
--exec [dbo].[Report_Carmoney_KPI_2021]
