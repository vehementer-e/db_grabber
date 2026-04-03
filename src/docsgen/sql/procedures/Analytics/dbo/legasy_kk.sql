CREATE PROC [dbo].[legasy_kk] as
begin


/*
	select cast(dateadd(yy,-2000,[ДатаОтчета]) as date) 'ДатаОтчета'
						,[НомерДоговора]
						,[ОстатокПроцентовВсего]
						,[ОстатокРезерв]
						,[ОстатокРезервНУ]
				into #t1
				from [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]
				where 1 = 1
						and cast([ДатаОтчета] as date) = 
							(select dateadd(dd,-2,max(cast([ДатаОтчета] as date))) from [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных])

	

	update devDB.dbo.say_log_dogovora_kk
	set [Проценты начисленные] = coalesce(t2.[ОстатокПроцентовВсего],0)
	,[Остаток резервов БУ] = coalesce(t2.[ОстатокРезерв],0)
	,[Остаток резервов НУ] = coalesce(t2.[ОстатокРезервНУ],0)
	from devDB.dbo.say_log_dogovora_kk t1
			left join #t1 t2 on t2.[НомерДоговора] = t1.[номер договора]
	where cast(t1.[дата время состовления отчёта] as date) = cast(getdate() as date)
*/

---------------------------------------------------------------------------------------------------------
--сбор таблицы deals с учетом того, что данных о заморозке в ней нет
	drop table if exists #deals
	;
	select *
	into #deals
	from stg._Collection.deals t


	
	;

	delete from #deals
	where number in (select t1.external_id
					from dwh2.[dm].[Collection_StrategyDataMart] t1
					left join (select external_id
								from dwh2.[dm].[Collection_StrategyDataMart]
								where strategydate = '2021-06-18'
										and HasFreezing = 1)	t2 on t2.external_id = t1.external_id
					left join stg._collection.deals				d on d.number = t1.external_id
					where t1.strategydate = '2021-06-19'
							and t1.HasFreezing = 1
							and t2.external_id is null
							and coalesce(d.IsCreditVacation,0) != 1)
	;

	


	drop table if exists #date;
	create table #date (dt date);
	insert #date VALUES ('4021-04-30');
	while (select max(dt) from #date) < '4030-01-01'
		begin 
			insert #date (dt)
			select distinct eomonth(dateadd(mm,1,(select max(dt) from #date)))
			from #date
		END
	;
	
	

	update #deals
	set 
			 IsCreditVacation = (case when d.IsCreditVacation = 1 then 1
									  else f.HasFreezing
									  end)
			,CreditVacationDateBegin = (case when f.HasFreezing = 1 then b.dt_max_kk
											 when d.CreditVacationDateBegin is null then b.dt_min_kk
											 else d.CreditVacationDateBegin
											 end)
			,CreditVacationDateEnd = (case when f.HasFreezing = 1 then a.CreditVacationDateEnd
										   else d.CreditVacationDateEnd
										   end)
	from #deals																			d
	left join (select s.external_id
						,s.HasFreezing
				from dwh2.[dm].[Collection_StrategyDataMart] s
				where 1 = 1
						and s.HasFreezing = 1
						and cast(s.strategydate as date) = cast(getdate() as date)
				group by s.external_id
						,s.HasFreezing)													f on f.external_id = d.number
	left join (select number
						,max(dt_kk) dt_max_kk
						,min(dt_kk) dt_min_kk
				from [devDB].[dbo].[say_log_peredachi_kk]
				group by number)														b on b.number = d.number
	left join (select s.код number
						,max(cast(dateadd(yy,-2000,g.ДатаПлатежа) as date)) CreditVacationDateEnd
				from [Stg].[_1cCMR].[РегистрСведений_ДанныеГрафикаПлатежей_today]	g
				left join [Stg].[_1cCMR].Справочник_Договоры						s on g.Договор=s.Ссылка
				where 1 = 1
						and cast(g.[Период] as date) in (select dt from #date where dt <= dateadd(yy,2000,cast(getdate() as date)))
						and g.ОстатокОД > 0
						and g.СуммаПлатежа = 0
				group by s.код)														a on a.number = d.number
	;

------------------------------------------------
--ежедневное логировние договоров с кк
	-- delete from devDB.dbo.say_log_dogovora_kk where cast([дата время состовления отчёта] as date) = '2021-07-22'

	--alter table devDB.dbo.say_log_dogovora_kk drop column employee_fio

	delete from devDB.dbo.say_log_dogovora_kk 
	where [дата время состовления отчёта]>cast(getdate() as date)

	INSERT INTO devDB.dbo.say_log_dogovora_kk 


	select distinct 
			cast(getdate() as smalldatetime) [дата время состовления отчёта]
			,1 cnt
			,cast(t1.[Number] as nvarchar(21)) [номер договора] 
			,t5.Name [стадия договора]
			,cast(case when (t5.Name = 'Closed' and t1.[DebtSum] = 0)
						or (t5.Name != 'Closed' and t1.fulldebt <= 0) then '01.договор_закрыт'
				  when cast(dateadd(dd,-1,getdate()) as date) > cast(dateadd(MM,1,t1.[CreditVacationDateEnd]) as date)
						and t1.[OverdueDays] = 0 then '02.каникулы_закончились_первый_платеж_внесен_договор_в_графике'
				  when cast(getdate() as date) > cast(t1.[CreditVacationDateEnd] as date)
						and t1.[NextPayment] <= 0 and DATEDIFF(day,GETDATE(),t4.NextPaymentDate) between 0 and 14 
						then '03.до_платежа_менее_15_дней_и_средств_на_счёте_хватает_для_первого_платежа'
				  when cast(getdate() as date) > cast(t1.[CreditVacationDateEnd]as date)
						and t1.[NextPayment] <= 0 and DATEDIFF(day,GETDATE(),t4.NextPaymentDate) not between 0 and 14 
						then '04.до_платежа_более_15_дней_и_средств_на_счёте_хватает_для_первого_платежа'
				  when cast(dateadd(MM,1,t1.[CreditVacationDateEnd]) as date) >= cast(getdate() as date) and t1.[OverdueDays] > 0
						then '05.1.!!ошибка_дата_окончания_КК_не_наступила_есть_просрочка'
				  when cast(t1.OverdueStartDate as date) < cast(dateadd(MM,1,t1.[CreditVacationDateEnd]) as date) and t1.[OverdueDays] > 0
						then '05.2.!!ошибка_кк_не_обнулили_срок_просрочки'
				  when cast(getdate() as date) > cast(t1.[CreditVacationDateEnd] as date) and t1.[OverdueDays] > 0
						then '06.каникулы_закончились_договор_на_просрочке'
				  when cast(getdate() as date) > cast(t1.[CreditVacationDateEnd] as date)
						and DATEDIFF(day,GETDATE(),t4.NextPaymentDate) between 0 and 14
						then '07.каникулы_окончились_до_даты_платежа_менее_15_дней'
				  when cast(getdate() as date) > cast(t1.[CreditVacationDateEnd] as date)
						and DATEDIFF(day,GETDATE(),t4.NextPaymentDate) not between 0 and 14
						then '08.каникулы_окончились_до_даты_платежа_более_15_дней'
				  else '09.каникулы_не_закончились' end as nvarchar(200)) [статус договора для стратегии кк]
			,case when t11.IdDeal is null then 'проблемность: закончился_график'
				  when t7.[Name]  is not null then 'проблемность: '+t7.[Name]
				  when t5.Name in ('ИП','СБ') then 'проблемность: стадия_'+t5.[Name]
				  else NULL end [проблема по договору] 
			,cast((case when t12.[ДатаПоГрафику] is not null then t12.[ДатаПоГрафику]
				  when t1.[CreditVacationDateBegin] is not null then t1.[CreditVacationDateBegin]
				  else dateadd(MM,-3,t1.[CreditVacationDateEnd])-- если поле не заполнено, тогда минус 3 месяца от даты завершения
				  end) as date) [дата начала каникул]
			,cast(t1.[CreditVacationDateEnd] as date) [дата окончания каникул] 
			,dateadd(day,- datepart(day, t1.[CreditVacationDateEnd]) + 1, convert(date, t1.[CreditVacationDateEnd])) [месяц окончания каникул]
			,cast(t1.[DebtSum] as float) principal_rest
			,cast(case when t1.[CurrentAmountOwed] < 0 then t1.[CurrentAmountOwed] * -1 else 0 end as float) переплата_на_счёте
			,cast(t1.[LastPaymentSum] as float) [сумма последнего платежа]
			,cast(t1.[LastPaymentDate] as date) [дата последнего платежа]
			,case when t1.[LastPaymentDate] is not null 
					and t1.[LastPaymentDate] between (case when t12.[ДатаПоГрафику] is not null then t12.[ДатаПоГрафику]
														when t1.[CreditVacationDateBegin] is not null then t1.[CreditVacationDateBegin]
														else dateadd(MM,-3,t1.[CreditVacationDateEnd])-- если поле не заполнено, тогда минус 3 месяца от даты завершения
														end) 
													and t1.[CreditVacationDateEnd]
					then 1 else 0 end [наличие платежа во время каникул]
			,case when datepart(yyyy,t4.NextPaymentDate) >= 2000 then cast(t4.NextPaymentDate as date)
					end [дата платежа по графику]
			,cast(coalesce(t4.NextPaymentSum,0) as float) [сумма платежа по графику]
			,t1.[OverdueDays] [срок просрочки]
			,cast(case when t1.[OverdueDays] between 1 and 30	 then '(2)_1_30'
								when t1.[OverdueDays] between 31 and 60 	 then '(3)_31_60'
								when t1.[OverdueDays] between 61 and 90	 then '(4)_61_90'
								when t1.[OverdueDays] >= 90	 then '(5)_91+'
								when t1.[OverdueDays] = 0					 then '(1)_0' end as nvarchar(10)) [бакет просрочки]
			,cast(case when t1.[NextPayment] > 0 then t1.[NextPayment] else 0 end as float) [нужно оплатить в следующем платеже] -- сумму, которую необходимо внести, чтобы покрыть следующий платеж
			,cast(case when t3.overdue_days between 1 and 30	 then '(2)_1_30'
								when t3.overdue_days between 31 and 60 	 then '(3)_31_60'
								when t3.overdue_days between 61 and 90	 then '(4)_61_90'
								when t3.overdue_days >= 90	 then '(5)_91+'
								when t3.overdue_days = 0					 then '(1)_0' 
								else '(1)_0' end as nvarchar(10)) [бакет перед выдачей каникул]
			,null [дата передачи в обзвон]
			,cast(t1.OverdueStartDate as date) [дата возникновения текущей просрочки]
			,case when t7.name is not null
						then '010.не_подходят_для_КК_клиент_со_статусом_'+t7.name
				  when cast(getdate() as date) > cast(t1.[CreditVacationDateEnd] as date) 
						and t1.[OverdueDays] > 0
						and datediff(day,t1.OverdueStartDate,t1.[CreditVacationDateEnd]) < -32
						then '011.не_подходят_для_КК_сейчас_на_просрочке_но_были_платежи_по_графику_после_окончания_КК'
				  when t5.Name in ('Legal','ИП')
						then '012.не_подходят_для_КК_договор_на_стадии_'+t5.Name
						end [проблемы с передачей в обзвон]		
			,null [тип выдачи каникул]
			,coalesce(t8.ActualAddress,t8.PermanentRegisteredAddress) [Адрес]
			,case when coalesce(t8.ActualAddress,t8.PermanentRegisteredAddress) like '%Москва%' then '01. Москва и область'
					when coalesce(t8.ActualAddress,t8.PermanentRegisteredAddress) like '%Московская%обл%' then '01. Москва и область'
					when coalesce(t8.ActualAddress,t8.PermanentRegisteredAddress) like '%Ленинградская%обл%' then '02. Санкт-Петербург и область'
					when coalesce(t8.ActualAddress,t8.PermanentRegisteredAddress) like '%Санкт-Петербург%' then '02. Санкт-Петербург и область'
					when coalesce(t8.ActualAddress,t8.PermanentRegisteredAddress) like '%Краснодарский%край%' then '03. Краснодарский край'
					when coalesce(t8.ActualAddress,t8.PermanentRegisteredAddress) like '%Ростовская%обл%' then '04. Ростовская область'
					when coalesce(t8.ActualAddress,t8.PermanentRegisteredAddress) like '%Нижегородская%обл%' then '05. Нижегородская область'
					when coalesce(t8.ActualAddress,t8.PermanentRegisteredAddress) like '%Воронежская%обл%' then '06. Воронежская область'
					when coalesce(t8.ActualAddress,t8.PermanentRegisteredAddress) like '%Башкортостан%Респ%' then '07. Башкортостан рес'
					when coalesce(t8.ActualAddress,t8.PermanentRegisteredAddress) like '%Татарстан%Респ%' then '08. Татарстан рес'
					when coalesce(t8.ActualAddress,t8.PermanentRegisteredAddress) like '%Волгоградская%обл%' then '09. Волгоградская область'
					when coalesce(t8.ActualAddress,t8.PermanentRegisteredAddress) like '%Югра%' then '10. ХМАО'
					else '99. Прочие' end [Регион]
			,dateadd(month,1,dateadd(day,- datepart(day, t1.[CreditVacationDateEnd]) + 1, convert(date, t1.[CreditVacationDateEnd]))) [месяц платежа после каникул]
			,t3.principal_rest [од на дату оформления кк]
			,null [дата передачи на рефинансирование]
			,null [дата отправки смс]
			,null [причина выхода на просрочку]
			,devdb.dbo.customer_fio(t14.id) 'ФИО заёмщика'
			,null [максимальный бакет просрочки в истории]
			,case when (t5.Name = 'Closed' and t1.[DebtSum] = 0)
						or (t5.Name != 'Closed' and t1.fulldebt <= 0) then 0
				  else coalesce(t13.[ОстатокПроцентовВсего],0) end 'Проценты начисленные'
			,null 'Тип ИЛ'
			,case when (t5.Name = 'Closed' and t1.[DebtSum] = 0)
						or (t5.Name != 'Closed' and t1.fulldebt <= 0) then 0
				  else coalesce(t13.[ОстатокРезерв],0) end 'Остаток резерв БУ'
			,case when (t5.Name = 'Closed' and t1.[DebtSum] = 0)
				or (t5.Name != 'Closed' and t1.fulldebt <= 0) then 0
			else coalesce(t13.[ОстатокРезервНУ],0) end 'Остаток резерв НУ'
			--null as agency_flag,
			--null as employee_fio

	  FROM #deals t1
	  left join   (select t01.[Договор]
							,t01.[ДатаПоГрафику]
					from 
					(select [Договор]
							,[ДатаПоГрафику]
							,ROW_NUMBER() over (partition by [Договор] order by [ДатаПоГрафику] desc) aa
					from [Reports].[dbo].[DWH_694_credit_vacation_cmr])t01
					where t01.aa = 1)t12 on t12.[Договор] = t1.number
	  left join stg._1cCMR.Справочник_Договоры t2 on t1.[Number] = t2.[Код]
	 left join (select d as r_date
						,[external_id]
						,dpd_coll as overdue_days
						,[остаток од] as principal_rest
				from dwh2.dbo.dm_cmrstatbalance
				where cast(d as date) >= '2020-01-01')t3 on t3.external_id = t1.Number
																						and t3.r_date = 
				  cast(dateadd(dd,-1,(case when t12.[ДатаПоГрафику] is not null then t12.[ДатаПоГрафику]
				  when t1.[CreditVacationDateBegin] is not null then t1.[CreditVacationDateBegin]
				  else dateadd(MM,-3,t1.[CreditVacationDateEnd])
				  end)) as date)
	 left join [Stg].[_Collection].[NextPaymentInfo] t4 on t4.[DealId] = t1.Id
	 left join [Stg].[_Collection].collectingStage t5 on t5.Id = t1.StageId
	 left join devDB.dbo.say_customer_non_reserves t6 on t6.external_id = t1.Number
	 left join (select [CustomerId]
			,[Name]
	from 
	(SELECT distinct 
		[CustomerId]
      ,[CustomerStateId]
	  ,t2.[Name]
	  ,ROW_NUMBER() over (partition by [CustomerId] order by t2.[order]) aa
   FROM [Stg].[_Collection].[CustomerStatus] t1
  join [Stg].[_Collection].[CustomerState] t2 on t2.[Id] = t1.[CustomerStateId]
  where t1.[IsActive] = 1 
		and t2.[Name] in (
							'Смерть подтвержденная',
							'Банкрот подтверждённый',
							'Fraud подтвержденный',
							'HardFraud',
							'Банкрот неподтверждённый'))t01
			where t01.aa = 1) t7 on t7.[CustomerId] = t1.[IdCustomer]
	 left join [Stg].[_Collection].[registration] t8 on t8.IdCustomer = t1.IdCustomer
	left join 	(select IdDeal
				from
					(select t1.paymentdt
							,t1.IdDeal
							,sum(1) over (partition by t1.IdDeal) aa
					FROM [c2-vsr-cl-sql].[collection_night00].[dbo].[PaymentPlan] t1 
					where t1.paymentdt >= cast(getdate() as date))t01
					where aa > 1
				group by IdDeal)t11 on t11.IdDeal =t1.id
	left join stg._Collection.customers t14 on t14.Id = t1.IdCustomer
	left join (select cast(dateadd(yy,-2000,[ДатаОтчета]) as date) 'ДатаОтчета'
						,[НомерДоговора]
						,[ОстатокПроцентовВсего]
						,[ОстатокРезерв]
						,[ОстатокРезервНУ]
				from [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]
				where 1 = 1
						and cast([ДатаОтчета] as date) = 
							(select dateadd(dd,-1,max(cast([ДатаОтчета] as date))) from [Stg].[_1cUMFO].[РегистрСведений_СЗД_ПоказателиЗаймовПредоставленных]))t13
							on t13.НомерДоговора = t1.Number
	where t1.IsCreditVacation = 1 
			and (case when t7.name = 'Банкрот подтверждённый' and t1.[OverdueDays] > 0 then 1 else 0 end) = 0 -- это договора фактически без КК, потому что заёмщики признаны банкротами и им откатили каникулы
			and devdb.dbo.customer_fio(t14.id) != 'ТЕСТ ТЕСТ ТЕСТ'
			;

-----------------------------
	declare @r_dare date;
	set @r_dare = (select cast(max([дата время состовления отчёта]) as date) from devDB.dbo.say_log_dogovora_kk);


--обновление глубины просрочки в истории
	
	drop table if exists #base_bucket_dpd_max;
	select d.Number
			,case when max(cast(dh.NewValue as int)) > 90 then '(5)_91+'
				  when max(cast(dh.NewValue as int)) > 60 then '(4)_61_90'
				  when max(cast(dh.NewValue as int)) > 30 then '(3)_31_60'
				  when max(cast(dh.NewValue as int)) > 0 then '(2)_1_30'
				  else '(1)_0'
				  end bucket_dpd_max
	into #base_bucket_dpd_max
	from stg._Collection.dealhistory dh
	join stg._Collection.deals d on d.Id = dh.ObjectId 
	where 1 = 1
			and dh.field = 'Количество дней просрочки'
	group by d.Number
	;

	update devDB.dbo.say_log_dogovora_kk
	set [максимальный бакет просрочки в истории] = (case when bd.[number] is null then '(1)_0'
									 else bd.bucket_dpd_max end)
	from devDB.dbo.say_log_dogovora_kk kk
	left join #base_bucket_dpd_max bd on bd.[number] = kk.[номер договора]
	where cast(kk.[дата время состовления отчёта] as date) = @r_dare
	;

-----------------------------

--обновление таблицы типов KK
	
	drop table if exists #udal_3;
	select [number]
		,count(dt_kk) 'кол-во раз на каникулах'
	into #udal_3
	from [devDB].[dbo].[say_log_peredachi_kk]
	group by [number]

	update devDB.dbo.say_log_dogovora_kk
	set [тип выдачи каникул] = (case when t2.[number] is null then 'кол-во передач: '+'1'
									 else 'кол-во передач: '+cast(t2.[кол-во раз на каникулах] as nvarchar) end)
	from devDB.dbo.say_log_dogovora_kk t1 
	left join #udal_3 t2 on t2.[number] = t1.[номер договора]
	where cast(t1.[дата время состовления отчёта] as date) = @r_dare

-----------------------------

--атрибут "причина выхода на просрочку"

	drop table if exists #base_date_overdue_start;
	select --собираю первую дату просрочки после окончившихся кк
			t4.number
			,t4.date_overdue_start
	into #base_date_overdue_start
	from 
	(
		select 
				t2.number
				,cast([ChangeDate] as date) date_overdue_start
				,row_number() over (partition by t2.number order by [ChangeDate] desc) rn
	
		from [Stg].[_Collection].[DealHistory] t1
		left join [Stg].[_Collection].[Deals] t2 on t2.id = t1.ObjectId
		left join (select [номер договора]
							,[дата окончания каникул]
					from devDB.dbo.say_log_dogovora_kk
					where [дата время состовления отчёта] = (select max([дата время состовления отчёта]) from devDB.dbo.say_log_dogovora_kk)
					)t3 on t3.[номер договора] = t2.number
		where t1.Field = 'Количество дней просрочки'
				and t1.OldValue = 0 --дата когда старое значение срока пз (0) сменилось на новое, отличное от 0
				and cast([ChangeDate] as date) >= cast([дата окончания каникул] as date) --начало просрочки после окончания последних каникул
	)t4
	where t4.rn = 1
	group by t4.number,date_overdue_start;

	
	drop table if exists #base_non_payment_reason_actual;
	select --собираю актуальное значения атрибута non_payment_reason
		t2.number
		,t03.date_non_payment_reason
		,t03.name
	into #base_non_payment_reason_actual
	from
	(
		select 
				t01.[IdCustomer]
				,t02.[name]
				,cast(t01.CreateDate as date) date_non_payment_reason
				,ROW_NUMBER() over(partition by t01.[IdCustomer] order by [CreateDate] desc) max_CreateDate
		from [c2-vsr-cl-sql].[collection_night00].[dbo].[NonPaymentReasonHistory] t01
		left join [c2-vsr-cl-sql].[collection_night00].[dbo].[NonPaymentReason] t02 on t02.id = t01.[NonPaymentReasonId]
		)t03
	left join [Stg].[_Collection].[Deals] t2 on t2.IdCustomer = t03.IdCustomer
	where t03.max_CreateDate = 1
			and t2.number is not null
			and t03.name != 'Pre-del'
	group by t2.number,t03.date_non_payment_reason,t03.name;
-----------------------------
	drop table if exists #base_non_payment_reason_kk;
	select t1.Number
			,t2.name name_non_payment_reason
	into #base_non_payment_reason_kk
	from #base_date_overdue_start t1
	join #base_non_payment_reason_actual t2 on t2.Number= t1.Number
	where t2.date_non_payment_reason >= t1.date_overdue_start;
-----------------------------
	update devDB.dbo.say_log_dogovora_kk
	set [причина выхода на просрочку] = name_non_payment_reason
	from devDB.dbo.say_log_dogovora_kk t1
	join #base_non_payment_reason_kk t2 on t2.Number = t1.[номер договора]
	where t1.[дата время состовления отчёта] = (select max([дата время состовления отчёта]) from devDB.dbo.say_log_dogovora_kk);

-----------------------------
	-- база наличия ил по типам
	drop table if exists #base_type_eo;
	select deal.number
			,max(coalesce(eo.Type,0)) il_type
	into #base_type_eo
	FROM            Stg._Collection.Deals AS												Deal LEFT OUTER JOIN
                         Stg._Collection.JudicialProceeding AS								jp ON Deal.Id = jp.DealId LEFT OUTER JOIN
                         Stg._Collection.JudicialClaims AS									jc ON jp.Id = jc.JudicialProceedingId LEFT OUTER JOIN
                         Stg._Collection.EnforcementOrders AS								eo ON jc.Id = eo.JudicialClaimId
	WHERE        (eo.Id IS NOT NULL)
	group by deal.number
	;

	update devDB.dbo.say_log_dogovora_kk
	set [Тип ИЛ] = case when eo.il_type > 1 then '1. есть ИЛ после решения суда'
						when eo.il_type = 1 then '2. есть ИЛ только на обечпечительные меры'
						else '3. нет ИЛ никакого типа' end
	from devDB.dbo.say_log_dogovora_kk			kk
	left join #base_type_eo						eo on eo.number = kk.[номер договора]
	where kk.[дата время состовления отчёта] = (select max([дата время состовления отчёта]) from devDB.dbo.say_log_dogovora_kk)
	;

-----------------------------

--флаги определения в прозвон и на смс

	drop table if exists #udal_2;
	create table #udal_2
	([номер договора] nvarchar(21) not null
	,flag int not null
	,priznak nvarchar(100));

	insert into #udal_2
	select distinct t01.[номер договора]
					,1 flag
					,'01.был контакт в первой волне прозвона для КК' priznak
	from
	(select cast(t1.[дата время состовления отчёта] as date) [дата время состовления отчёта]
			,cast(t1.[дата передачи в обзвон] as date) [дата передачи в обзвон]
			,t1.[номер договора]
			,t3.Commentary
	from devDB.dbo.say_log_dogovora_kk t1
	join [Stg].[_Collection].[Deals] t2 on t2.Number = t1.[номер договора]
	join [Stg].[_Collection].[Communications] t3 on t3.IdDeal = t2.Id
	join [Stg].[_Collection].[CommunicationResult] t4 on t4.Id = t3.CommunicationResultId
	join devDB.dbo.say_sprav_result_contact t5 on t5.CommunicationResultContacr = t4.Name
	where cast(t1.[дата время состовления отчёта] as date) = cast(t1.[дата передачи в обзвон] as date)
			and (case when t5.CommunicationResultContacr is not null then 1 else 0 end) = 1 -- yes contact
			and cast(t1.[дата передачи в обзвон] as date) = cast(t3.[Date] as date)
			and t3.Commentary is not null)t01
	union all
-----------------------------
	select distinct t01.Number
					,1 flag
					,'02.был контакт в soft/pre-del за последние 5 дней' priznak
	from
	(select t5.Number
	from [Stg].[_Collection].[Communications] t1
	join [Stg].[_Collection].[EmployeeCollectingStage] t2 on t2.EmployeeId = t1.EmployeeId
	join [Stg].[_Collection].[CommunicationResult] t3 on t3.Id = t1.CommunicationResultId
	join devDB.dbo.say_sprav_result_contact t4 on t4.CommunicationResultContacr = t3.Name
	join [Stg].[_Collection].[Deals] t5 on t5.Id = t1.IdDeal
	where cast(t1.[Date] as date) between dateadd(dd,-5,cast(getdate() as date)) and cast(getdate() as date)
			and t2.CollectingStageId = 1 -- soft/pre-del
			and (case when t4.CommunicationResultContacr is not null then 1 else 0 end) = 1 -- yes contact
	)t01
	union all
-----------------------------
	select distinct t01.number
					,1 flag
					,'03.есть активные обещания' priznak
	from
	(select t2.Number
	from [Stg].[_Collection].[Communications] t1
	join [Stg].[_Collection].[Deals] t2 on t2.Id = t1.IdDeal
	where cast(t1.PromiseDate as date) >= cast(getdate() as date)
			and t1.PromiseSum > 0)t01
	union all
-----------------------------
	select distinct number
					,1 flag
					,'04.есть проблемность по договору' priznak
	from	
	(select [CustomerId]
			,[Name]
			,number
	from 
	(SELECT distinct 
		[CustomerId]
      ,[CustomerStateId]
	  ,t2.[Name]
	  ,ROW_NUMBER() over (partition by [CustomerId] order by t2.[order]) aa
   FROM [Stg].[_Collection].[CustomerStatus] t1
   join [Stg].[_Collection].[CustomerState] t2 on t2.[Id] = t1.[CustomerStateId]
   where t1.[IsActive] = 1 
		and t2.[Name] in (
							'Смерть подтвержденная',
							'Банкрот подтверждённый',
							'Fraud подтвержденный',
							'Взаимодействие через представителя (230-ФЗ)',
							'Отказ от взаимодействия по 230 ФЗ',
							'Клиент в больнице (230-ФЗ)',
							'Клиент в тюрьме',
							'HardFraud'
	))t01
	join [Stg].[_Collection].[Deals] t2 on t2.IdCustomer = t01.CustomerId
	where t01.aa = 1)t02
	union all
-----------------------------
	select distinct number
					,1 flag
					,'05.отправляли смс о окончании каникул' priznak
	from
	(select number
	from
	(SELECT t1.[CommunicationId]
	FROM [Stg].[_Collection].[Message] t1
	where Body like '%срок%действия%кредитных%каникул%истек%'
			or body like '%наступает%дата%платежа%после%кредитных%каникул%'
			or body like '%рок%действия%кредитных%каникул%заканчивается%')t01
	join [Stg].[_Collection].[Communications] t2 on t2.Id = t01.[CommunicationId]
	join [Stg].[_Collection].[Deals] t3 on t3.id = t2.IdDeal)t02
	union all	
-----------------------------
	select number
				,1 flag
				,'06.были попытки не менее 3-х дней за из последних 10 дней' priznak
	from
	(select distinct t2.number
			,cast(t1.date as date) aa
	FROM [Stg].[_Collection].[Communications] t1
	join [Stg].[_Collection].[Deals] t2 on t2.id = t1.IdDeal
	join (select t01.[номер договора]
				,t01.[дата окончания каникул]
		  from devDB.dbo.say_log_dogovora_kk t01
		  where t01.[дата время состовления отчёта] = (select max([дата время состовления отчёта]) from devDB.dbo.say_log_dogovora_kk))t3
	on t3.[номер договора] = t2.number and t3.[дата окончания каникул] <= cast(t1.[Date] as date)
	join [Stg].[_Collection].[communicationType] t4 on t4.Id = t1.CommunicationType
	where t4.Name in ('Исходящий звонок',
								'Мессенджеры',
								'Входящий звонок',
								'Мобильное приложение',
								'Выезд',
								'Соц. сети',
								'Личная встреча в офисе')
	and datediff(dd,cast(t1.date as date),cast(getdate() as date)) <= 10)t01
	group by number
	having sum(1) >= 3;
-----------------------------------------------------------
/*
--в прозвон

	update devDB.dbo.say_log_dogovora_kk
	set [дата передачи в обзвон] = @r_dare
	from devDB.dbo.say_log_dogovora_kk t1
	left join (select distinct [номер договора]
				from #udal_2
				where priznak in ('01.был контакт в первой волне прозвона для КК'
					,'02.был контакт в soft/pre-del за последние 5 дней'
					,'03.есть активные обещания'
					,'04.есть проблемность по договору'
					,'06.были попытки не менее 3-х дней за из последних 10 дней'))t2 on t2.[номер договора] = t1.[номер договора]
	where cast(t1.[дата время состовления отчёта] as date) = @r_dare
			and t1.[статус договора для стратегии кк] in ('03.до_платежа_менее_15_дней_и_средств_на_счёте_хватает_для_первого_платежа'
															,'07.каникулы_окончились_до_даты_платежа_менее_15_дней')
			and t2.[номер договора] is null;
*/
-----------------------------------------------------------

--на смс

	update devDB.dbo.say_log_dogovora_kk
	set [дата отправки смс] = @r_dare
	from devDB.dbo.say_log_dogovora_kk t1
	left join (select distinct [номер договора]
				from #udal_2
				where priznak in ('04.есть проблемность по договору'
					,'05.отправляли смс о окончании каникул'))t2 on t2.[номер договора] = t1.[номер договора]
	where cast(t1.[дата время состовления отчёта] as date) = @r_dare
			and t1.[статус договора для стратегии кк] in ('04.до_платежа_более_15_дней_и_средств_на_счёте_хватает_для_первого_платежа'
															,'08.каникулы_окончились_до_даты_платежа_более_15_дней')
			and t1.[тип выдачи каникул] != 'вне_резервов'
			and t2.[номер договора] is null;
---------------------------------------------------------
/*
--рефинансирование
	
	update devDB.dbo.say_log_dogovora_kk
	set [дата передачи на рефинансирование] = @r_dare
	from devDB.dbo.say_log_dogovora_kk t1
	left join (select distinct [номер договора]
			  from devDB.dbo.say_log_dogovora_kk
			  where [дата передачи на рефинансирование] is not null)t2 on t2.[номер договора] = t1.[номер договора]
	where cast(t1.[дата время состовления отчёта] as date) = @r_dare
			and t1.[статус договора для стратегии кк] = '06.каникулы_закончились_договор_на_просрочке'
			and t1.[Регион] in ('01. Москва и область','02. Санкт-Петербург и область')
			and t2.[номер договора] is null;

	drop table if exists #udal_1;

	select t1.*
		  ,t5.[Brand]
		  ,t5.[Model]		
		  ,t5.[YearOfIssue]		
		  ,t5.[Volume]		
		  ,t5.[Vin]		
		  ,t5.[RegNumber]		
		  ,t5.[MarketPrice]		
		  ,t5.[Discont]		
		  ,t5.[AssessedPrice]		
		  ,t5.[LiquidityPercent]		
		  ,t3.debtsum	
		  ,t3.fulldebt	
		  ,t3.[Percent]	
		  ,t3.Fine	
		  ,t3.CurrentAmountOwed
	into #udal_1
	from devDB.dbo.say_log_dogovora_kk t1
	join [Stg].[_Collection].[Deals] t3	on t3.number = t1.[номер договора]
	join [Stg].[_Collection].[DealPledgeItem] t4 on t4.[DealId] = t3.id		
	join [Stg].[_Collection].[PledgeItem] t5 on t5.id = t4.[PledgeItemId]
	where cast(t1.[дата время состовления отчёта] as date) = cast(@r_dare as date)
			and t1.[дата передачи на рефинансирование] is not null;
	
	drop table if exists devDB.dbo.say_in_refinans_avtolombard;

	select *
	into devDB.dbo.say_in_refinans_avtolombard
	from #udal_1;
*/
-----------------------------------------------------------------------------------------------
				-- *** БЛОК ОПЕРПОКАЗАТЕЛЕЙ *** --
-----------------------------------------------------------------------------------------------	
	-- база договоров и дат для операционки predel
	drop table if exists #base_deals_predel;
	select 
			lkk.[номер договора] number
			,d.id id_deal_space
			,cast(lkk.[месяц окончания каникул] as date) mn_fn_kk
			,cast(lkk.[дата платежа по графику] as date) dt_pay
			,devdb.dbo.dt_st_month(lkk.[дата платежа по графику]) mn_pay
			,cast(dateadd(dd,-10,lkk.[дата платежа по графику])  as date) dt_st_predel
			,lkk.principal_rest
			,lkk.[Проценты начисленные] + lkk.principal_rest principal_rest_and_percent
			,case when d_h_2.CurrentAmountOwed is null
				  then 2
				  when d_h_2.CurrentAmountOwed > 0 then 
				  1 else 0 end fl_in_pz
			,lkk_1.[причина выхода на просрочку]
			--,case when d_h.StageId = 9 then 1 else 0 end fl_closed
			--,case when ka.external_id is not null then 1 else 0 end fl_ka
			--,case when d_h.NextPayment <= 0 then 1 else 0 end fl_not_payment
			--,case when d_h_1.idcustomer is not null then 1 else 0 end fl_deal_on_pz
	into #base_deals_predel
	from
			devdb.dbo.say_log_dogovora_kk						lkk
			join (select distinct max([дата время состовления отчёта]) over (partition by devdb.dbo.dt_st_month([дата время состовления отчёта])) dt_rp
					from devdb.dbo.say_log_dogovora_kk)			
																dtr on dtr.dt_rp = lkk.[дата время состовления отчёта]
																	and devdb.dbo.dt_st_month(dtr.dt_rp) = lkk.[месяц окончания каникул]
			left join stg._Collection.Deals_history				d_h on d_h.number = lkk.[номер договора]
																	and d_h.r_date = dateadd(dd,-10,lkk.[дата платежа по графику])
			left join (select r_date, idcustomer from stg._Collection.Deals_history where OverdueDays > 0 group by r_date, idcustomer)
																d_h_1 on d_h_1.idcustomer = d_h.idcustomer
																	and d_h_1.r_date = dateadd(dd,-10,lkk.[дата платежа по графику])
			left join Stg._Collection.dwh_ka_buffer				ka on ka.external_id = lkk.[номер договора]											
																   and dateadd(dd,-10,lkk.[дата платежа по графику]) between
			 														   ka.[Дата передачи в КА] and coalesce(ka.[Дата отзыва],ka.[Плановая дата отзыва])
			join stg._Collection.Deals							d on d.number = d_h.number
			left join stg._Collection.Deals_history				d_h_2 on d_h_2.number = lkk.[номер договора]
																	and d_h_2.r_date = dateadd(dd,1,lkk.[дата платежа по графику])
			left join (select [номер договора],[причина выхода на просрочку]
						from devdb.dbo.say_log_dogovora_kk
						where [дата время состовления отчёта] = 
							(select max([дата время состовления отчёта]) dt_max_rp
							from devdb.dbo.say_log_dogovora_kk))
																lkk_1 on lkk_1.[номер договора] = lkk.[номер договора]
	where 1 = 1
			and dateadd(dd,-10,lkk.[дата платежа по графику]) between '2021-07-01' and cast(dateadd(dd,-1,getdate()) as date)
			and (case when d_h.StageId = 9 then 1 else 0 end) = 0
			and (case when ka.external_id is not null then 1 else 0 end) = 0
			and (case when d_h.NextPayment <= 0 then 1 else 0 end) = 0
			and (case when d_h_1.idcustomer is not null then 1 else 0 end) = 0
	;

------------------------------------------------------------------------------
	--база последнего закрепления клиента за ответственным взыскателем	
	drop table if exists #base_lost_claimant_id;															
	select ObjectId															
			,coalesce(NewValue,0) ClaimantId													
			,dt_rt dt_st													
	into #base_lost_claimant_id															
	from (SELECT [ChangeDate]															
					,cast([ChangeDate] as date) dt_rt											
					,[OldValue]											
					,[NewValue]											
					,[ObjectId]											
					,ROW_NUMBER() over (partition by [ObjectId] order by [ChangeDate] desc) rn											
			FROM [Stg].[_Collection].[CustomerHistory]													
			where 1 = 1													
					and field = 'Ответственный взыскатель')aaa											
	where 1 = 1															
			and rn = 1
	;

------------------------------------------------------------------------------
	-- база договоров и дат для операционки hard
	drop table if exists #base_deals_hard;
	select
			lkk.[номер договора] number
			,devdb.dbo.customer_fio(d.idcustomer) customer_fio
			,lkk.[Адрес]
			,lkk.[Регион]
			,d.id id_deal_space
			,cast(lkk.[месяц окончания каникул] as date) mn_fn_kk
			,cast(lkk.[дата платежа по графику] as date) dt_pay
			,devdb.dbo.dt_st_month(lkk.[дата платежа по графику]) mn_pay
			,lkk.principal_rest
			,lkk.[Проценты начисленные] + lkk.principal_rest principal_rest_and_percent
			,case when d.OverdueDays = 0 then 1 else 0 end fl_return_schedule
			,devdb.dbo.employee_fio(c.claimantid) employee_fio
			,case when blc.ClaimantId = c.claimantid then blc.dt_st end dt_fixing_claimant
			,c.id customer_id
	into #base_deals_hard
	from
			devdb.dbo.say_log_dogovora_kk						lkk
			join (select distinct max([дата время состовления отчёта]) over (partition by devdb.dbo.dt_st_month([дата время состовления отчёта])) dt_rp
					from devdb.dbo.say_log_dogovora_kk)
																dtr on dtr.dt_rp = lkk.[дата время состовления отчёта]
																	and devdb.dbo.dt_st_month(dtr.dt_rp) = lkk.[месяц окончания каникул]
			join stg._Collection.Deals							d on d.number = lkk.[номер договора]
			left join stg._Collection.Deals_history				d_h_2 on d_h_2.number = lkk.[номер договора]
																	and d_h_2.r_date = dateadd(dd,1,lkk.[дата платежа по графику])
			left join Stg._Collection.dwh_ka_buffer				ka on ka.external_id = lkk.[номер договора]											
																   and ka.[Дата передачи в КА] <= dateadd(dd,14,lkk.[дата платежа по графику])
																   and coalesce(ka.[Дата отзыва],ka.[Плановая дата отзыва]) >= lkk.[дата платежа по графику]
			join stg._collection.customers						c on c.id = d.idcustomer
			left join #base_lost_claimant_id					blc on blc.ObjectId = d.idcustomer
	where 1 = 1
			and lkk.[дата платежа по графику] >= '2021-08-01'
			and coalesce(d_h_2.CurrentAmountOwed,0) > 0
			and (case when ka.[Дата передачи в КА] <= dateadd(dd,14,lkk.[дата платежа по графику])
						  and coalesce(ka.[Дата отзыва],ka.[Плановая дата отзыва]) >= lkk.[дата платежа по графику]
					 then 1 else 0 end) = 0
	;

------------------------------------------------------------------------------
	--база сотрудников predel и hard - они должны операционно обрабатывать "заморозку"
	drop table if exists #base_employee_hard;
	select 
			resh.Employeeid employee_id
			--,Employeefio fio_claimant
			,e.LastName+' '+e.FirstName+' '+e.MiddleName fio_claimant
			,resh.CollectingStageName employee_stage_collection
	into #base_employee_hard
	--from [c2-vsr-cl-sql].[collection_night00].[dbo].[ReportEmployeeStatisticsHistory]		resh
	FROM Stg._Collection.v_EmployeeCollectingStageHistory AS resh
	left join stg._collection.Employee														e on e.id = resh.Employeeid
	where 1 = 1
			and resh.CollectingStageName in ('Hard','Predelinquency')
			and resh.Employeeid != 11 -- исключен сотрудник Лебедев Александр Дмитриевич, который давно был на hard, но сейчас работает на prelegal
	group by resh.Employeeid
			,(e.LastName+' '+e.FirstName+' '+e.MiddleName)
			,resh.CollectingStageName
	union
	select id
			,e.LastName+' '+e.FirstName+' '+e.MiddleName
			,'Hard'
	from stg._Collection.Employee		e
	where id = 106 -- добавлен сотрудник Батнасунов Надбит Николаевич, который работает на розыске в ИП/hard и не имеет закрепленных договоров и скила
	;

------------------------------------------------------------------------------
	-- база коммуникаций всех
	drop table if exists #Communications;
	select * 
	into #Communications
	from stg._Collection.Communications 
	where cast(date as date) >= '2021-07-15'
	;
	
------------------------------------------------------------------------------
	-- база коммуникаций predel	
	drop table if exists #base_comm_predel;
	select 
			bdp.number
			,comm.[date] dt_comm
			,beh.fio_claimant
			,beh.employee_stage_collection
			,comm_type.name comm_type_name
			,comm_res.name comm_res_name
			,case when cont_type.Id = 3 then 'Не определен' else cont_type.name end cont_type_name
			,comm.Commentary
			,comm.CallingCreditHolidays
			,1 attemp
			,spav_comm.contact
	into #base_comm_predel
	from 
			#Communications										comm
			join  #base_deals_predel							bdp on bdp.id_deal_space = comm.IdDeal
			left join #base_employee_hard						beh on beh.employee_id = comm.EmployeeId
			join [Stg].[_Collection].[communicationType]		comm_type on comm_type.Id = comm.CommunicationType
			join [Stg].[_Collection].[CommunicationResult]		comm_res on comm_res.Id = comm.CommunicationResultId
			join [Stg].[_Collection].[ContactPersonType]		cont_type on cont_type.Id = comm.ContactPersonType
			join devdb.dbo.say_sprav_comm_convers_1_90			spav_comm on spav_comm.comm_type_id = comm.CommunicationType
																and spav_comm.comm_res_id = comm.CommunicationResultId
																and spav_comm.cont_type_id = comm.ContactPersonType
			join (select distinct 
							ccd.ProjectUID
							,cast(ccd.CreateDate as date) report_dt
					from [c2-vsr-cl-sql].[collection_night00].[dbo].[CallCaseData] ccd
					where 1 = 1
							and cast(ccd.CreateDate as date) >= '2021-07-01'
							and lower(ccd.ProjectName) like '%Predel%' or lower(ccd.ProjectName) like '%Pre-del%')
																cl on cl.ProjectUID = comm.NaumenProjectId
																	and cl.report_dt = cast(comm.[date] as date)
	where 
			1 = 1
			and cast(comm.date as date) between bdp.dt_st_predel and bdp.[dt_pay]
			and lower(comm.Commentary) not like '%подтвержден%доход%'
	;

------------------------------------------------------------------------------
	-- итоговая таблица predel для вставки в отчёт
	drop table if exists devDB.dbo.say_oper_pokazat_for_kk; -- здесь операционка по predel
	with base_comm_predel as
	(
		select 
				bca.number
				,cast(bca.dt_comm as date) dt_comm
				,bca.comm_res_name
				,case when (bca.CallingCreditHolidays = 1) -- 1 Будет платить по графику
						or (bca.contact = 1 and bca.cont_type_name = 'Третье лицо' and bca.comm_res_name = 'Обещание оплатить')
						or (bca.contact = 1 and bca.cont_type_name = 'Клиент' and bca.comm_res_name = 'Обещание оплатить')
						or lower(bca.Commentary) like '%окончание%кк%будет%платить% по%графику%'
						or lower(bca.Commentary) like '%окончание%кк%будет%платить%по%графику%'
						or lower(bca.Commentary) like '%окончание%кк%платит%по%графику%'
						or lower(bca.Commentary) like '%окончание%кк%будет%оплата%'
						or lower(bca.Commentary) like '%окончание%кк%внесет%оплату%'
					  then 1 -- обещание оплаты
					  when (bca.CallingCreditHolidays = 2) -- 2 Не будет платить по графику
						or (bca.contact = 1 and bca.cont_type_name = 'Третье лицо' and bca.comm_res_name = 'Отказ от оплаты')
						or (bca.contact = 1 and bca.cont_type_name = 'Клиент' and bca.comm_res_name = 'Отказ от оплаты')
						or (bca.contact = 1 and bca.cont_type_name = 'Клиент' and bca.comm_res_name = 'Отказ от разговора 1-е лицо')
						or lower(bca.Commentary) like '%окончание%кк%не%будет%платить% по%графику%'
					  then 2 -- отказ от оплаты
					  when (bca.CallingCreditHolidays = 3) -- 3 Сложности в оплате по графику
						or (bca.contact = 1 and bca.cont_type_name = 'Третье лицо' and bca.comm_res_name = 'Консультация')
						or (bca.contact = 1 and bca.cont_type_name = 'Клиент' and bca.comm_res_name = 'Просит "Прощение"')
						or (bca.contact = 1 and bca.cont_type_name = 'Клиент' and bca.comm_res_name = 'Хочет продать авто')
						or lower(bca.Commentary) like '%окончание%кк%сложности%в%оплате%по%графику%'
						or lower(bca.Commentary) like '%окончание%кк%не%уверен%в%оплате%'
						or lower(bca.Commentary) like '%окончание%кк%не%уверен%внесет%оплату%'
					  then 3 -- ожидает сложности в оплате
					  when bca.contact = 1
					  then 4 -- контакт с третьим лицом
					  else null 
					  end type_contact
				,bnpr.NonPaymentReason
				,bca.cont_type_name
				,bca.attemp
				,bca.contact
		from 
				#base_comm_predel						bca
				left join (select distinct t1.number
											,case when t3.[name] is null or t3.[name] = 'Pre-del' then 'Другое' 
													else t3.[name] end NonPaymentReason
							from #base_comm_predel t1
							left join [Stg].[_Collection].[Deals] t2 on t2.Number = t1.number
							left join (select t03.[IdCustomer]
												,t03.[name]
										from
											(select t01.[IdCustomer]
													,t02.[name]
													,ROW_NUMBER() over(partition by t01.[IdCustomer] order by [CreateDate] desc) max_CreateDate
											from [c2-vsr-cl-sql].[collection_night00].[dbo].[NonPaymentReasonHistory] t01
											left join [c2-vsr-cl-sql].[collection_night00].[dbo].[NonPaymentReason] t02 on t02.id = t01.[NonPaymentReasonId])t03
							where t03.max_CreateDate = 1)t3 on t3.IdCustomer = t2.IdCustomer)
														
														bnpr on bnpr.number = bca.number
		where 1 = 1
	)
	select distinct 
			bdp.number 'номер договора'
			,bdp.mn_fn_kk 'месяц окончания льготного периода'
			,bdp.dt_pay 'дата платежа после льготного периода'
			,bdp. mn_pay 'месяц платежа после каникул'
			,bdp.dt_st_predel 'дата начала prerdel'
			,1 cnt
			,case when bdp.fl_in_pz = 0 then '1. остался в графике'
				  when bdp.fl_in_pz = 1 then '2. вышел на ПЗ' 
				  else '3. дата платежа не наступила' end 'результат коллектинга predel' -- результат только на следующий день после даты платежа
			,bdp.[причина выхода на просрочку]
			,bdp.principal_rest 'основной долг'
			,bdp.principal_rest_and_percent 'основной долг и проценты'
			,max(coalesce(t1.attemp,0)) over (partition by t1.number) 'Попытка контакта predel'
			,max(coalesce(t1.contact,0)) over (partition by t1.number) 'Контакт predel'
			,case when t2.aa = 1 then 'Будет платить по графику'
				  when t2.aa = 2 then 'Отказ в оплате по графику'
				  when t2.aa = 3 then 'Ожидает сложности в оплате по графику'
				  when t2.aa = 4 then 'Нет контакта с заемщиком, только с третьим лицом'
				  end 'Результат контакта predel'
			,case when t2.aa = 2 then NonPaymentReason end 'Причина отказа'
			,max(coalesce(t1.attemp,0)) over (partition by t1.number) * bdp.principal_rest 'Попытка руб predel'
			,max(coalesce(t1.contact,0)) over (partition by t1.number) * bdp.principal_rest 'Контакт руб predel'
	into devDB.dbo.say_oper_pokazat_for_kk
	from 
			#base_deals_predel						bdp
			left join base_comm_predel				t1 on t1.number = bdp.number
			left join (select distinct 
								number
								,FIRST_VALUE(type_contact) over (partition by number order by dt_comm desc) aa
						from base_comm_predel
						where 1 = 1
							and contact = 1
							and type_contact is not null)
													t2 on t2.number = bdp.number
	;

------------------------------------------------------------------------------
	-- база коммуникаций hard	
	drop table if exists #base_comm_hard;
	select
			bdh.number
			,comm.[date] dt_comm
			,beh.fio_claimant
			,beh.employee_stage_collection
			,comm_type.name comm_type_name
			,comm_res.name comm_res_name
			,case when cont_type.Id = 3 then 'Не определен' else cont_type.name end cont_type_name
			,comm.Commentary
			,comm.CallingCreditHolidays
			,1 attemp
			,coalesce(spav_comm.contact,0) contact
			,case when comm_type.name = 'Выезд' then 1 else 0 end  visit
			,case when comm_type.name = 'Клиент' then 1 else 2 end fl_comm_type
	into #base_comm_hard
	from
			#Communications											comm
			join #base_employee_hard								beh on beh.employee_id = comm.EmployeeId
			join #base_deals_hard									bdh on bdh.id_deal_space = comm.IdDeal
			join [Stg].[_Collection].[communicationType]			comm_type on comm_type.Id = comm.CommunicationType
			join [Stg].[_Collection].[CommunicationResult]			comm_res on comm_res.Id = comm.CommunicationResultId
			join [Stg].[_Collection].[ContactPersonType]			cont_type on cont_type.Id = comm.ContactPersonType
			left join devdb.dbo.say_sprav_comm_convers_1_90			spav_comm on spav_comm.comm_type_id = comm.CommunicationType
																				and spav_comm.comm_res_id = comm.CommunicationResultId
																				and spav_comm.cont_type_id = comm.ContactPersonType
	where 1 = 1
			and beh.employee_stage_collection = 'Hard'
			and cast(comm.date as date) between dateadd(dd,1,bdh.dt_pay) and dateadd(dd,14,bdh.dt_pay)
	;

------------------------------------------------------------------------------
	-- итоговая таблица hard для вставки в отчёт
	drop table if exists devDB.dbo.say_oper_pokazat_hard_for_kk;
	select distinct
			bdh.number 'номер договора'
			,bdh.customer_fio
			,bdh.[Адрес]
			,bdh.[Регион]
			,bdh.mn_fn_kk 'месяц окончания льготного периода'
			,bdh.dt_pay 'дата платежа после льготного периода'
			,bdh.mn_pay 'месяц платежа после льготного периода'
			,1 cnt
			,bdh.principal_rest 'основной долг'
			,bdh.principal_rest_and_percent 'основной долг и проценты'
			,case when bdh.fl_return_schedule = 1 then '1. договор возвращен в график' else '2. договор на просрочке' end 'результат коллектинга hard'
			,bdh.employee_fio 'фио ответственного сотрудника'
			,bdh.dt_fixing_claimant 'дата закрепления за ответсвенным сотрудником'
			,max(coalesce(bch.attemp,0)) over (partition by bdh.number) 'Попытка контакта hard'
			,max(coalesce(bch.contact,0)) over (partition by bdh.number) 'Контакт hard'
			,max(coalesce(bch.visit,0)) over (partition by bdh.number) 'Визит hard'
			,case when bch_1.aa = 1 then 'Контакт с клиентом'
				  when bch_1.aa = 2 then 'Контакт с третьим лицом'
				  end 'Тип контактного лица'
			,max(coalesce(bch.attemp,0)) over (partition by bdh.number) * bdh.principal_rest 'Попытка руб hard'
			,max(coalesce(bch.contact,0)) over (partition by bdh.number) * bdh.principal_rest 'Контакт руб hard'
			,max(coalesce(bch.visit,0)) over (partition by bdh.number) * bdh.principal_rest 'Визит руб hard'
			,datediff(dd,bdh.dt_pay,cast(min(bch.dt_comm) over (partition by bdh.number) as date)) 'Кол-во дней на первую попытку'
			,coalesce(bd.flag,0) 'статус Смерть подтвержденная'
			,coalesce(bb.flag,0) 'статус Банкрот подтверждённый'
			,coalesce(bf.flag,0) 'статус Fraud подтвержденный'
			,coalesce(bhf.flag,0) 'статус HardFraud'
	into devDB.dbo.say_oper_pokazat_hard_for_kk
	from 
			#base_deals_hard					bdh
			left join #base_comm_hard			bch on bch.number = bdh.number
			left join (select distinct 
								number
								,FIRST_VALUE(fl_comm_type) over (partition by number order by dt_comm desc) aa
						from #base_comm_hard
						where 1 = 1
							and contact = 1
							and fl_comm_type is not null)
												bch_1 on bch_1.number = bdh.number
			left join (
							select [CustomerId] ,1 flag
							from    [Stg].[_Collection].[CustomerStatus] t1
									join [Stg].[_Collection].[CustomerState] t2 on t2.[Id] = t1.[CustomerStateId]
							where t1.[IsActive] = 1 and  t2.[Name] = 'Смерть подтвержденная'
							group by [CustomerId]
						)						bd on bd.CustomerId = bdh.customer_id
			left join (
							select [CustomerId] ,1 flag
							from    [Stg].[_Collection].[CustomerStatus] t1
									join [Stg].[_Collection].[CustomerState] t2 on t2.[Id] = t1.[CustomerStateId]
							where t1.[IsActive] = 1 and  t2.[Name] = 'Банкрот подтверждённый'
							group by [CustomerId]
						)						bb on bb.CustomerId = bdh.customer_id
			left join (
							select [CustomerId] ,1 flag
							from    [Stg].[_Collection].[CustomerStatus] t1
									join [Stg].[_Collection].[CustomerState] t2 on t2.[Id] = t1.[CustomerStateId]
							where t1.[IsActive] = 1 and  t2.[Name] = 'Fraud подтвержденный'
							group by [CustomerId]
						)						bf on bf.CustomerId = bdh.customer_id
			left join (
							select [CustomerId] ,1 flag
							from    [Stg].[_Collection].[CustomerStatus] t1
									join [Stg].[_Collection].[CustomerState] t2 on t2.[Id] = t1.[CustomerStateId]
							where t1.[IsActive] = 1 and  t2.[Name] = 'HardFraud'
							group by [CustomerId]
						)						bhf on bhf.CustomerId = bdh.customer_id
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	--для отчёта "В заморозке"
---------------------------------------------------------------------------------------------------------------------------------------------
	--база первой даты закрепления за последним ответственным взыскателем
	drop table if exists #base_customers_in_hard;
	with
	base_claimant_id as
	(
		SELECT cast([ChangeDate] as date) dt_rt											
				,[NewValue] claimant_id								
				,t02.fio_claimant
				,[ObjectId]	customer_id										
				,ROW_NUMBER() over (partition by [ObjectId] order by [ChangeDate] desc) rn_last_claimant_id
				,ROW_NUMBER() over (partition by [ObjectId],[NewValue] order by [ChangeDate]) rn_fr_claimant_id
		FROM [Stg].[_Collection].[CustomerHistory]				t01
		join (
				select distinct employee_id,fio_claimant from #base_employee_hard where employee_stage_collection = 'Hard'
				)												t02 on t02.employee_id = coalesce(t01.NewValue,0)
		where 1 = 1													
				and field = 'Ответственный взыскатель'
	)
	select
			t1.claimant_id
			,t1.fio_claimant
			,t1.customer_id
			,t2.dt_rt dt_st_hard
	into #base_customers_in_hard
	from
			base_claimant_id							t1
			join (
					select dt_rt,claimant_id,customer_id from base_claimant_id where rn_fr_claimant_id = 1
					)									t2 on t2.claimant_id = t1.claimant_id
															and t2.customer_id = t1.customer_id
	where 1=1
			and t1.rn_last_claimant_id = 1
	;

--------------------------------------------------------------------------------------
	drop table if exists devdb.dbo.say_log_deals_hard_in_kk;
	select
			lkk.[номер договора]
			,lkk.[дата окончания каникул]
			,case when bch.claimant_id = c.ClaimantId then bch.fio_claimant end 'фио ответственного взыскателя'
			,case when bch.claimant_id = c.ClaimantId then bch.dt_st_hard end 'дата начала работы ответственного взыскателя'
			,1 'колво договоров'
			,d.debtsum 'од'
			,sum(case when coalesce(bp.PaymentDt,'2000-01-01') >= (case when bch.claimant_id = c.ClaimantId then bch.dt_st_hard end)
					  then sum_pay else 0 end) 'сумма платежей'
			,sum(case when coalesce(bp.PaymentDt,'2000-01-01') >= (case when bch.claimant_id = c.ClaimantId then bch.dt_st_hard end)
					  then count_pay else 0 end) 'колво платежей'
	into devdb.dbo.say_log_deals_hard_in_kk
	from
			devdb.dbo.say_log_dogovora_kk						lkk
			join stg._collection.deals							d on d.number = lkk.[номер договора]
			join stg._collection.customers						c on c.id = d.idcustomer
			join #base_customers_in_hard						bch on bch.customer_id = d.idcustomer
			left join (
						select PaymentDt, iddeal, amount sum_pay, 1 count_pay from stg._collection.Payment
						)											bp on bp.iddeal = d.id
	where 1=1
			and cast(lkk.[дата время состовления отчёта] as date) = cast(getdate() as date)
			and lkk.[стадия договора] not in ('Closed','Продан')
			and lkk.[дата окончания каникул] >= cast(getdate() as date)
	group by lkk.[номер договора]
			,lkk.[дата окончания каникул]
			,case when bch.claimant_id = c.ClaimantId then bch.fio_claimant end
			,case when bch.claimant_id = c.ClaimantId then bch.dt_st_hard end
			,d.debtsum
	;

------------------------------------------------------------------------------
	-- для отчёта "Проработка после Заморозки"
------------------------------------------------------------------------------
	-- база дат для определения начала работы hard
	drop table if exists #base_dt_deals_hard;															
	select
			kk.[номер договора] number
			,d.id id_deal_space
			,case when beh.fio_claimant is not null then blc.dt_st
				  else dateadd(mm,1,kk.[дата окончания каникул]) end 'Дата начала учёта показателей'
	into #base_dt_deals_hard
	from
			devdb.dbo.say_log_dogovora_kk					kk
			join stg._collection.Deals						d on d.number = kk.[номер договора]
			join stg._Collection.customers					c on c.Id = d.IdCustomer
			left join #base_lost_claimant_id				blc on blc.ObjectId = d.idcustomer
			left join (
						select * from #base_employee_hard where employee_stage_collection = 'Hard'
						)									beh on beh.employee_id = c.ClaimantId
	where 1=1
			and kk.[дата время состовления отчёта] = (select max([дата время состовления отчёта]) a from devdb.dbo.say_log_dogovora_kk)
	;

------------------------------------------------------------------------------

	-- база коммуникаций агрегированная
	drop table if exists #base_comm_hard_agg;															
	select
			comm.iddeal
			,sum(spav_comm.attemp) attemp_count
			,sum(spav_comm.attemp_visit) visit_count
			,sum(spav_comm.attemp_call) call_count
			,sum(spav_comm.contact) contact_count
			,sum(spav_comm.promise) promise_count
	into #base_comm_hard_agg
	from
			stg._Collection.Communications							comm
			join (
					select * from #base_employee_hard where employee_stage_collection = 'Hard'
					)												beh on beh.employee_id = comm.EmployeeId
			join Reports.collection.say_hard_comm_for_kk_sprav		spav_comm on spav_comm.comm_type_id = comm.CommunicationType
																			 and spav_comm.comm_res_id = comm.CommunicationResultId
																			 and spav_comm.cont_type_id = comm.ContactPersonType
			join #base_dt_deals_hard								bdth on bdth.id_deal_space = comm.iddeal
																		 and cast(comm.[date] as date) >= bdth.[Дата начала учёта показателей]
	where 1=1
	group by
			comm.iddeal
	;

------------------------------------------------------------------------------
	-- база наступления этапов ИП
	drop table if exists #base_fl_eo;															
	select
			[№ договора] number
			,max(case when id_IL is not null then 1 else 0 end) fl_il
			,max(case when [Дата возбуждения ИП] is not null then 1 else 0 end) fl_eo
			,max(case when [Дата ареста авто] is not null then 1 else 0 end) fl_arest
			,max(case when [Дата первых торгов] is not null then 1 else 0 end) fl_trade
			,max(case when [Дата принятия на баланс] is not null then 1 else 0 end) fl_balance
	into #base_fl_eo
	from
			[Reports].[collection].[say_enforcement_proceedings_log_everyday]
	where 1=1
			and r_date = (select max(r_date) from [Reports].[collection].[say_enforcement_proceedings_log_everyday])
	group by
			[№ договора]
	;

------------------------------------------------------------------------------
	-- база платежей
	drop table if exists #base_payment;															
	select
			pay.iddeal
			,sum(pay.amount) sum_pay
	into #base_payment
	from
			stg._Collection.Payment									pay
			join #base_dt_deals_hard								bdth on bdth.id_deal_space = pay.iddeal
																		 and cast(pay.paymentdt as date) >= bdth.[Дата начала учёта показателей]
	group by
			pay.iddeal
	;

------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------
	--Блок определения незакреплённых договоров 
---------------------------------------------------------------------------------------------------------------------------------------------
	-- база подтверждённых банкротов
	drop table if exists #base_Bankrupt_Confirmed;															
	select id_Customer															
		,dt_Bankrupt_Confirmed														
	into #base_Bankrupt_Confirmed															
	from															
	(															
		select CustomerId id_Customer														
				,cast(ChangeDate as date) dt_Bankrupt_Confirmed												
				,ROW_NUMBER() over (partition by ObjectId order by ChangeDate) rn												
		FROM [C2-VSR-CL-SQL].[collection_night00].[dbo].[BankruptConfirmedHistory] t01														
		join [C2-VSR-CL-SQL].[collection_night00].[dbo].[CustomerStatus] t02 on t02.id = t01.ObjectId														
		where 1 = 1														
				and Field = 'Статус назначен'												
				and NewValue = 'True'												
	)t1															
	where 1 = 1															
			and t1.rn = 1													
	;															
															
----------------------------------------------------------------------------																
	-- база подтверждённых фродов
	drop table if exists #base_Fraud_Confirmed;															
	select id_Customer															
		,dt_Fraud_Confirmed														
	into #base_Fraud_Confirmed															
	from															
	(															
		select CustomerId id_Customer														
				,cast(ChangeDate as date) dt_Fraud_Confirmed												
				,ROW_NUMBER() over (partition by ObjectId order by ChangeDate) rn												
		FROM [C2-VSR-CL-SQL].[collection_night00].[dbo].[FraudConfirmedHistory] t01														
		join [C2-VSR-CL-SQL].[collection_night00].[dbo].[CustomerStatus] t02 on t02.id = t01.ObjectId														
		where 1 = 1														
				and Field = 'Статус назначен'												
				and NewValue = 'True'												
	)t1															
	where 1 = 1															
			and t1.rn = 1													
	;															
															
----------------------------------------------------------------------------																
	-- база подтверждённых смертей
	drop table if exists #base_Death_Confirmed;															
	select id_Customer															
		,dt_Death_Confirmed														
	into #base_Death_Confirmed															
	from															
	(															
		select CustomerId id_Customer														
				,cast(ChangeDate as date) dt_Death_Confirmed												
				,ROW_NUMBER() over (partition by ObjectId order by ChangeDate) rn												
		FROM [C2-VSR-CL-SQL].[collection_night00].[dbo].[ConfirmedDeathHistory] t01														
		join [C2-VSR-CL-SQL].[collection_night00].[dbo].[CustomerStatus] t02 on t02.id = t01.ObjectId														
		where 1 = 1														
				and Field = 'Статус назначен'												
				and NewValue = 'True'												
	)t1															
	where 1 = 1															
			and t1.rn = 1													
	;															
															
----------------------------------------------------------------------------																
	-- база хард-фрод
	drop table if exists #base_HardFraud_Confirmed;															
	select id_Customer															
		,dt_HardFraud_Confirmed														
	into #base_HardFraud_Confirmed															
	from															
	(															
		select CustomerId id_Customer														
				,cast(ChangeDate as date) dt_HardFraud_Confirmed												
				,ROW_NUMBER() over (partition by ObjectId order by ChangeDate) rn												
		FROM [C2-VSR-CL-SQL].[collection_night00].[dbo].[HardFraudHistory] t01														
		join [C2-VSR-CL-SQL].[collection_night00].[dbo].[CustomerStatus] t02 on t02.id = t01.ObjectId														
		where 1 = 1														
				and Field = 'Статус назначен'												
				and NewValue = 'True'												
	)t1															
	where 1 = 1															
			and t1.rn = 1													
	;															
----------------------------------------------------------------------------															
	-- база передач в ка
	drop table if exists #base_in_ka;															
	SELECT [external_id]															
	,[Дата передачи в КА] dt_st_in_ka															
	,isnull([Дата отзыва],[Плановая дата отзыва]) dt_end_in_ka															
	into #base_in_ka															
	from stg._Collection.[dwh_ka_buffer]															
	;

----------------------------------------------------------------------------
	-- итоговая таблица для вставки реестра не распределенных за сотрудниками договоров
	drop table if exists devdb.dbo.say_loose_deals_for_kk;
	select
			d.number 'номер договора'
			,devdb.dbo.customer_fio(d.IdCustomer) 'фио клиента'
			,d.OverdueDays 'срок просрочки'
			,cast(lkk.[месяц окончания каникул] as date) 'месяц окончания льготного периода'
			,cast(lkk.[дата платежа по графику] as date) 'дата платежа после льготного периода'
			,devdb.dbo.dt_st_month(lkk.[дата платежа по графику]) 'месяц платежа после льготного периода'
			,lkk.[Адрес]
			,lkk.[Регион]
	into devdb.dbo.say_loose_deals_for_kk
	from
			stg._Collection.Deals									d
			join (
					select external_id
					from dwh2.[dm].[Collection_StrategyDataMart]
					where strategydate = cast(getdate() as date)
							and HasFreezing = 1
					)												f on f.external_id = d.Number
			join stg._Collection.customers							c on c.id = d.IdCustomer
			left join 
					(
						select
								[номер договора]
								,[Адрес]
								,[Регион]
								,[месяц окончания каникул]
								,[дата платежа по графику]
						from
								devdb.dbo.say_log_dogovora_kk
						where cast([дата время состовления отчёта] as date) = cast(getdate() as date)
						
					)												lkk on lkk.[номер договора] = d.Number
			left join #base_Bankrupt_Confirmed						bbc on bbc.id_Customer = d.IdCustomer									
			left join #base_Fraud_Confirmed							bfc on bfc.id_Customer = d.IdCustomer								
			left join #base_Death_Confirmed							bdc on bdc.id_Customer = d.IdCustomer								
			left join #base_HardFraud_Confirmed						bhfc on bhfc.id_Customer = d.IdCustomer									
			left join #base_in_ka									bk on bk.external_id = d.number
																		and cast(getdate() as date) between bk.dt_st_in_ka and bk.dt_end_in_ka
			
			left join #base_comm_hard								bch on bch.number = d.number
	where 1 = 1															
			and (													
						(case when bbc.dt_Bankrupt_Confirmed is not null then 1 else 0 end) = 0										
					and (case when bfc.dt_Fraud_Confirmed is not null then 1 else 0 end) = 0											
					and (case when bdc.dt_Death_Confirmed is not null then 1 else 0 end) = 0											
					and (case when bhfc.dt_HardFraud_Confirmed is not null then 1 else 0 end) = 0										
				)										
			and d.Fulldebt > 0
			and d.OverdueDays > 0
			and c.ClaimantId is null
			and bk.external_id is null
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	--Блок СП по КК
---------------------------------------------------------------------------------------------------------------------------------------------
	-- сбор ЗТ по договорам, с выбором того, которое было отправлено позже (в базе по договорам может быть более 1-го требования)
	drop table if exists #Judicial_Proceeding;
	select *
	into #Judicial_Proceeding
	from
	(
		select distinct
				DealId
				,number
				,jp.id
				,amountclaim
				,cast(coalesce(SubmissionClaimDate,jp.createdate) as date) dt_max_submission_claim
				,ROW_NUMBER() over (partition by DealId order by SubmissionClaimDate desc) rn -- выбор даты отправки последнего требования по договору
		from stg._Collection.JudicialProceeding		jp
		join stg._Collection.deals					d on d.id = jp.DealId
		where 1 = 1
				and isfake != 1
	)aa
	where rn = 1
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	-- сбор отправки исков в суд
	drop table if exists #Judicial_Claims;
	select id
			,cast(CourtClaimSendingDate as date) dt_Court_Claim_Sending-- дата отправки иска в суд
			,JudicialProceedingId
			,PrincipalDebtOnClaim
			,PercentageOnClaim
			,PenaltiesOnClaim
			,StateDutyOnClaim
			,AmountRequirements
			,PrincipalDebtOnJudgment
			,PercentageOnJudgment
			,PenaltiesOnJudgment
			,StateDutyOnJudgment
			,AmountJudgment
	into #Judicial_Claims
	from Stg._Collection.JudicialClaims			jc
	;
	-- select * from #Judicial_Claims

---------------------------------------------------------------------------------------------------------------------------------------------
	-- сбор информации о наличии решения суда
	drop table if exists #base_judgment; 
	select 
			number
			,JudgmentDate dt_judgment
	into #base_judgment
	from
	(
	select 
			d.number
			,cast(jc.JudgmentDate as date) JudgmentDate
			,ROW_NUMBER() over (partition by d.number order by jc.JudgmentDate desc) rn
	from Stg._Collection.JudicialClaims			jc
	join stg._Collection.JudicialProceeding		jp on jp.id = jc.JudicialProceedingId
	join stg._Collection.Deals					d on d.id = jp.DealId
	where 1 = 1
			and jc.JudgmentDate is not null
			and coalesce(jc.ResultOfCourtsDecision,0) != 3
	)aa
	where rn = 1
	;
	-- select * from #base_judgment

---------------------------------------------------------------------------------------------------------------------------------------------
	-- сбор информации о получение решения суда
	drop table if exists #base_receipt_judgmen; 
	select 
			number
			,ReceiptOfJudgmentDate dt_receipt_judgment
	into #base_receipt_judgmen
	from
	(
	select 
			d.number
			,cast(jc.ReceiptOfJudgmentDate as date) ReceiptOfJudgmentDate
			,ROW_NUMBER() over (partition by d.number order by jc.ReceiptOfJudgmentDate desc) rn
	from Stg._Collection.JudicialClaims			jc
	join stg._Collection.JudicialProceeding		jp on jp.id = jc.JudicialProceedingId
	join stg._Collection.Deals					d on d.id = jp.DealId
	where 1 = 1
			and jc.ReceiptOfJudgmentDate is not null
			and coalesce(jc.ResultOfCourtsDecision,0) != 3
	)aa
	where rn = 1
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	-- сбор информации о наличии ИЛ
	drop table if exists #Enforcement_Orders;
	select DealId
			,id id_IL
			,dt_Receipt_IL
			,amount sum_IL
	into #Enforcement_Orders
	from
	(
		select eo.id
				,jp.DealId
				,eo.amount
				,cast(eo.ReceiptDate as date) dt_Receipt_IL
				,ROW_NUMBER() over (partition by jp.DealId order by eo.ReceiptDate desc) rn
		from Stg._Collection.EnforcementOrders			eo
		join  Stg._Collection.JudicialClaims			jc on jc.id = eo.JudicialClaimId
		join Stg._Collection.JudicialProceeding			jp on jp.Id = jc.JudicialProceedingId
		where eo.[Type] != 1 -- тип 'Обеспечительные меры' не является в прямом смысле ИЛ для взыскания 
	)aa
	where rn = 1
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	drop table if exists #base_problematic_status;-- выборка уникальных договоров, у клиентов которых на утро сегодня есть проблемности "Смерть подтвержденная" или "Банкрот подтверждённый"
	select distinct 
				CustomerId
				,number
				--,[name]
				--,dt_st_State
	into #base_problematic_status
	from
	(
		SELECT
				[CustomerId]
			,d.Number
			,[CustomerStateId]									
			,t2.[Name]									
			,ROW_NUMBER() over (partition by [CustomerId] order by t2.[order] desc) rn									
			,coalesce(cast(t1.createdate as date),'2000-01-01') dt_st_State									
		FROM stg._collection.[CustomerStatus]		t1										
		join stg._collection.[CustomerState]		t2 on t2.[Id] = t1.[CustomerStateId]
		join stg._Collection.Deals					d on d.IdCustomer = t1.CustomerId
		where 1 = 1 												
				and t1.[IsActive] = 1 										
				and t2.[Name] in 										
								(						
								'Смерть подтвержденная'					
								,'Банкрот подтверждённый'
								,'Банкрот неподтверждённый'
								)
	)aa
	where rn = 1
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	drop table if exists #base_deal_closed; 
	select distinct -- выборка уникальных договоров, которые на утро сегодня закрыты
			d.IdCustomer
			,d.Number
			--,'Договор закрыт'
			--,coalesce(cast(d.LastPaymentDate as date),'2000-01-01')
	into #base_deal_closed
	from stg._Collection.Deals				d
	join stg._Collection.collectingStage	cs on cs.id = d.StageId
	where 1 = 1 
			and ((cs.name = 'Closed' and d.[DebtSum] = 0)
				or (cs.Name != 'Closed' and d.fulldebt <= 0))
			and cast(SUBSTRING(d.Number, 1, 1) as int) != 0
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	-- выборка договоров, где в решение суда указано "Отказать" - договора с такими решениями исключаются из базы СП/ИП
	drop table if exists #base_deal_denied; 
	select distinct
			d.number
			--,jp.OutgoingRequirementNumber
			--,jc.*
	into #base_deal_denied
	from Stg._Collection.JudicialClaims			jc
	join stg._Collection.JudicialProceeding		jp on jp.id = jc.JudicialProceedingId
	join stg._Collection.Deals					d on d.id = jp.DealId
	where 1 = 1
			and jc.ResultOfCourtsDecision = 3
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	-- определение максимального срока просрочки по договорам в истории и первой даты наступления этой просрочки
	drop table if exists #base_bucket_dpd_max_;
	select Number
			,dpd_61_hs
			,dt_fir_dpd_61_hs
	into #base_bucket_dpd_max_
	from
	(
		select d.Number
				,cast(dh.newvalue as int) dpd_61_hs
				,cast(dh.changedate as date) dt_fir_dpd_61_hs
				,ROW_NUMBER() over (partition by dh.ObjectId order by cast(dh.newvalue as int), dh.changedate) rn
		from stg._Collection.dealhistory dh
		join stg._Collection.deals d on d.Id = dh.ObjectId 
		where 1 = 1
				and dh.field = 'Количество дней просрочки'
				and cast(dh.newvalue as int) between 61 and 65 -- по сути должна быть проверка только на один срок - 61, но так как в db бывают баги со сроками, то расширил границы проверки
				and cast(dh.changedate as date) >= cast(d.CreditVacationDateEnd as date)
	)bb
	where rn = 1
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	-- выборка основного долга в истории 
	drop table if exists #base_principal_rest;
	select external_id
			,d as r_date
			,[остаток од] principal_rest
	into #base_principal_rest
	from
	(
		--select *
		--from RiskDWH.dbo.zzz_coll_bal_cmr_apr_june
		--union all
		select *
		from dwh2.dbo.dm_cmrstatbalance
		where d < '2020-04-01' or d > '2020-06-30'
	)aa
	where 1 = 1
			and d >= '2018-08-01'
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	-- определение даты закрытия договора 
	drop table if exists #base_dt_closed;
	select d.number
			,cast(coalesce(d.LastPaymentDate,dt_closed) as date) dt_closed
	into #base_dt_closed
	from stg._Collection.deals																				d
	left join (select dt_closed
						,dealid
				from
				(
					select cast(dh.changedate as date) dt_closed
							,dh.ObjectId dealid
							,ROW_NUMBER() over (partition by dh.ObjectId order by dh.changedate) rn
					from stg._Collection.DealHistory dh
					where 1 = 1
							and field = 'Стадия коллектинга договора'
							and newvalue = '9'
				)aa
				where rn = 1)																				aa on aa.dealid = d.Id

	where 1 = 1
			and d.StageId = 9
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	-- пул договоров продукта "заморозка" 
	drop table if exists #base_HasFreezing;
	select s.external_id
			,s.HasFreezing
	into #base_HasFreezing
	from dwh2.[dm].[Collection_StrategyDataMart] s
	where 1 = 1
			and s.HasFreezing = 1
			and cast(s.strategydate as date) = cast(getdate() as date)
	group by s.external_id
			,s.HasFreezing
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	--сбор платежей
	drop table if exists #base_pay_all;
	select 
			 external_id = bcmr.external_id
			,d = bcmr.d 
			,[сумма поступлений] = bcmr.[сумма поступлений]  
	into #base_pay_all
	from dwh2.[dbo].[dm_CMRStatBalance]			bcmr
	where 1 = 1
			and bcmr.[сумма поступлений] > 0

	--		select 
	--		bcmr.external_id
	--		,bcmr.cdate d
	--		,bcmr.total_CF 'сумма поступлений'
	--into #base_pay_all
	--from dwh_new.dbo.stat_v_balance2			bcmr
	--where 1 = 1
	--		and bcmr.total_CF > 0

																    
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	-- сбор дат сп
	drop table if exists #base_dt_jp;
	select
			jp.number
			,jp.dt_max_submission_claim -- дата отправки зт клиенту
			,case when jc.dt_Court_Claim_Sending is not null 
				  then jc.dt_Court_Claim_Sending
				  when bjm.dt_judgment is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,bjm.dt_judgment) / 2),jp.dt_max_submission_claim)
				  when brjm.dt_receipt_judgment is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,brjm.dt_receipt_judgment) / 3),jp.dt_max_submission_claim)
				  when eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,eo.dt_Receipt_IL) / 4),jp.dt_max_submission_claim)
				  end dt_Court_Claim_Sending -- дата отправки иска в суд
			,case when bjm.dt_judgment is not null 
				  then bjm.dt_judgment
				  when brjm.dt_receipt_judgment is not null and jc.dt_Court_Claim_Sending is not null
				  then dateadd(dd,(datediff(dd,jc.dt_Court_Claim_Sending,brjm.dt_receipt_judgment) / 2),jc.dt_Court_Claim_Sending)
				  when brjm.dt_receipt_judgment is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,brjm.dt_receipt_judgment) / (3 / 2)),jp.dt_max_submission_claim)
				  when jc.dt_Court_Claim_Sending is not null and eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jc.dt_Court_Claim_Sending,eo.dt_Receipt_IL) / 3),jc.dt_Court_Claim_Sending)
				  when eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,eo.dt_Receipt_IL) / (4 / 2)),jp.dt_max_submission_claim)
				  end dt_max_judgment -- дата вынесения решения суда
			,case when brjm.dt_receipt_judgment is not null 
				  then brjm.dt_receipt_judgment
				  when bjm.dt_judgment is not null and eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,bjm.dt_judgment,eo.dt_Receipt_IL) / 2),bjm.dt_judgment)
				  when jc.dt_Court_Claim_Sending is not null and eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jc.dt_Court_Claim_Sending,eo.dt_Receipt_IL) / (3 / 2)),jc.dt_Court_Claim_Sending)
				  when eo.dt_Receipt_IL is not null
				  then dateadd(dd,(datediff(dd,jp.dt_max_submission_claim,eo.dt_Receipt_IL) / (4 / 3)),jp.dt_max_submission_claim)
				  end dt_max_receipt_judgment -- дата получения решения суда
			,eo.dt_Receipt_IL dt_max_Receipt_IL -- дата получения ил
	into #base_dt_jp
	from
			#Judicial_Proceeding						jp
			left join #Judicial_Claims					jc on jc.JudicialProceedingId = jp.id
			left join #base_judgment					bjm on bjm.Number = jp.Number
			left join #base_receipt_judgmen				brjm on brjm.Number = jp.Number
			left join #Enforcement_Orders				eo on eo.DealId = jp.DealId
	;
	-- select * from #base_dt_jp

---------------------------------------------------------------------------------------------------------------------------------------------
-- сбор дат ип
	drop table if exists #base_dt_eo;
	select 
			number
			,max(ExcitationDate) 'Дата возбуждения ИП'
			,max(ArestCarDate) 'Дата ареста авто'
			,max(SecondTradesDate) 'Дата состоявшихся вторых торгов'
			,max(AdoptionBalanceDate) 'Дата принятия на баланс'
	into #base_dt_eo
	from
	(		
		select Deal.number
				
				,cast(coalesce(epe.ExcitationDate,'2000-01-01') as date) ExcitationDate
				,cast(coalesce(epmbt.ArestCarDate,'2000-01-01') as date) ArestCarDate
				,case when epmst.SecondTradingResult is not null then cast(coalesce(epmst.SecondTradesDate,'2000-01-01') as date) 									
						else '2000-01-01' end SecondTradesDate
				,cast(coalesce(epmi.AdoptionBalanceDate,'2000-01-01') as date) AdoptionBalanceDate
		FROM    Stg._Collection.Deals AS											Deal LEFT OUTER JOIN
				Stg._Collection.customers AS										c ON c.Id = Deal.IdCustomer LEFT OUTER JOIN
				Stg._Collection.JudicialProceeding AS								jp ON Deal.Id = jp.DealId LEFT OUTER JOIN
				Stg._Collection.JudicialClaims AS									jc ON jp.Id = jc.JudicialProceedingId LEFT OUTER JOIN
				Stg._Collection.EnforcementOrders AS								eo ON jc.Id = eo.JudicialClaimId LEFT OUTER JOIN
				Stg._Collection.EnforcementProceeding AS							ep ON eo.Id = ep.EnforcementOrderId LEFT OUTER JOIN

				Stg._Collection.EnforcementProceedingExcitation as					epe on epe.EnforcementProceedingId = ep.Id LEFT OUTER JOIN
				Stg._Collection.EnforcementProceedingSPI as							SPI on SPI.EnforcementProceedingId = ep.Id LEFT OUTER JOIN
						 
				Stg._Collection.collectingStage AS									cst_deals ON Deal.StageId = cst_deals.Id LEFT OUTER JOIN
				Stg._Collection.collectingStage AS									cst_client ON c.IdCollectingStage = cst_client.Id LEFT OUTER JOIN
				Stg._Collection.CustomerPersonalData AS								cpd ON cpd.IdCustomer = c.Id LEFT OUTER JOIN
				[Stg].[_Collection].[DadataCleanFIO] AS								dcfio ON dcfio.Surname = c.LastName AND dcfio.Name = c.Name 
																					AND dcfio.Patronymic = c.MiddleName LEFT OUTER JOIN
				[Stg].[_Collection].Courts AS										court ON court.Id = jp.CourtId LEFT OUTER JOIN
				Stg._Collection.DepartamentFSSP AS									fssp ON epe.DepartamentFSSPId = fssp.Id LEFT OUTER JOIN
				Stg._Collection.EnforcementProceedingMonitoring AS					monitoring ON ep.Id = monitoring.EnforcementProceedingId LEFT OUTER JOIN
                         
				Stg._Collection.EnforcementProceedingMonitoringBeforeTrades as		epmbt on epmbt.EnforcementProceedingMonitoringId = monitoring.Id LEFT OUTER JOIN
				Stg._Collection.EnforcementProceedingMonitoringFirstTrades as		epmft on epmft.EnforcementProceedingMonitoringId = monitoring.Id LEFT OUTER JOIN
				Stg._Collection.EnforcementProceedingMonitoringSecondTrades as		epmst on epmst.EnforcementProceedingMonitoringId = monitoring.Id LEFT OUTER JOIN
				Stg._Collection.EnforcementProceedingMonitoringImplementation as	epmi on epmi.EnforcementProceedingMonitoringId = monitoring.Id
		where 1 = 1
				and eo.Id IS NOT NULL
	)base_dt_eo
	group by number
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	-- сбор платежей по этапам сп
	drop table if exists #base_pay_jp_stage;
	with base_pay_all as
	(
	select bdj.*
			,bpa.*
	from #base_dt_jp				bdj
	join #base_pay_all				bpa on bpa.external_id = bdj.Number
	)
	select distinct
			b1.number 
			,coalesce(b2.sum_pay_jp_all,0) sum_pay_jp_all
			,coalesce(b3.sum_pay_submission_claim,0) sum_pay_submission_claim
			,coalesce(b4.sum_pay_Court_Claim_Sending,0) sum_pay_Court_Claim_Sending
			,coalesce(b5.sum_pay_judgment,0) sum_pay_judgment
			,coalesce(b6.sum_pay_receipt_judgment,0) sum_pay_receipt_judgment
			,coalesce(b7.sum_pay_Receipt_IL,0) sum_pay_Receipt_IL
	into #base_pay_jp_stage
	from base_pay_all															b1
	left join (select number
						,sum(coalesce([сумма поступлений],0)) sum_pay_jp_all
				from base_pay_all
				where d >= dt_max_submission_claim
				group by number)												b2 on b2.Number = b1.Number
	left join (select number
						,sum(coalesce([сумма поступлений],0)) sum_pay_submission_claim
				from base_pay_all
				where d between dt_max_submission_claim and coalesce(dateadd(dd,-1,dt_Court_Claim_Sending),getdate())
				group by number)												b3 on b3.Number = b1.Number
	left join (select number
						,sum(coalesce([сумма поступлений],0)) sum_pay_Court_Claim_Sending
				from base_pay_all
				where d between dt_Court_Claim_Sending and coalesce(dateadd(dd,-1,dt_max_judgment),getdate())
				group by number)												b4 on b4.Number = b1.Number
	left join (select number
						,sum(coalesce([сумма поступлений],0)) sum_pay_judgment
				from base_pay_all
				where d between dt_max_judgment and coalesce(dateadd(dd,-1,dt_max_receipt_judgment),getdate())
				group by number)												b5 on b5.Number = b1.Number
	left join (select number
						,sum(coalesce([сумма поступлений],0)) sum_pay_receipt_judgment
				from base_pay_all
				where d between dt_max_receipt_judgment and coalesce(dateadd(dd,-1,dt_max_Receipt_IL),getdate())
				group by number)												b6 on b6.Number = b1.Number
	left join (select number
						,sum(coalesce([сумма поступлений],0)) sum_pay_Receipt_IL
				from base_pay_all
				where d between dt_max_Receipt_IL and getdate()
				group by number)												b7 on b7.Number = b1.Number
	where 1 = 1
			and coalesce(b2.sum_pay_jp_all,0) > 0
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	--сбор последнего результативного взаимодействия с должником
	drop table if exists #base_communication_result;
	select t01.*
	into #base_communication_result
	from
			(
			select 
					t2.number
					,cast(t1.date as date) date_communication
					,coalesce(t1.manager,devdb.dbo.employee_fio(t1.EmployeeId)) manager
					,t4.name communication_type_name
					,t5.Name communication_result_name
					,t1.commentary
					,ROW_NUMBER() over (partition by t2.number order by t1.date desc) rn
			FROM [Stg].[_Collection].[Communications] t1
			join stg._Collection.deals d on d.id = t1.IdDeal
			join #base_dt_jp t2 on t2.number = d.Number
			join [Stg].[_Collection].[communicationType] t4 on t1.CommunicationType = t4.Id
			join [Stg].[_Collection].[CommunicationResult] t5 on t5.Id = t1.CommunicationResultId
			where 1 = 1
					and t4.Name in ('Исходящий звонок','Мессенджеры','Входящий звонок','Мобильное приложение','Выезд','Соц. сети','Личная встреча в офисе')
					and t5.Name not in ('Отклонен/Cброс','Автоответчик','Нет ответа')
					and coalesce(t1.Manager,'aaa') not in ('Система','Administrator Admin Adminovich')
					and cast(t1.date as datetime) >= t2.dt_max_submission_claim
										)t01
	where t01.rn = 1
	group by number,date_communication,manager,communication_type_name,communication_result_name,commentary,rn
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	-- база адресов клиентов
	drop table if exists #base_region_customer;
	SELECT 
			r.IdCustomer
			,rp.Name RegionPresence
			,case 
				  when r.ActualRegion = 'Хабаровский край        '
				  then 'Хабаровский край'
				  when r.ActualRegion = '' 
				  then rp.Name
				  when r.ActualRegion is null
				  then rp.Name
				  else r.ActualRegion
				  end ActualRegion
	into #base_region_customer
	FROM stg._collection.Registration					r
	left join stg._collection.RegionPresence			rp on rp.Id = r.RegionPresenceId
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	--	итоговая таблица
	drop table if exists devdb.dbo.say_log_jp_for_kk;
	--	delete from devdb.dbo.say_log_jp_for_kk where cast(r_date as date) = '2021-11-24';
	--INSERT INTO devdb.dbo.say_log_jp_for_kk
	select distinct
			getdate() r_date 
			,d.number
			,1 cnt
			,coalesce(bhf.HasFreezing,0) 'Флаг отправки на заморозку' -- flag_freezing 
			,c.LastName+' '+c.[name]+' '+c.MiddleName 'ФИО'
			,cs.Name 'Стадия коллекшин' --stage_name 	
			,d.OverdueDays 'Срок просрочки' --dpd_today 
			,devdb.dbo.bucket_dpd(d.OverdueDays) 'Бакет просрочки' -- dpd_bucket_today бакет просрочки на сегодня
			,case when bdc.Number is not null
					   or (d.OverdueDays = 0 and coalesce(bhf.HasFreezing,0) != 1)
					   or (d.OverdueDays = 0 and coalesce(bhf.HasFreezing,0) = 1 and kk.[дата платежа по графику] < cast(getdate() as date))
				  then '10.договор закрыт или отсутствует ПЗ'
				  when bdeo.[Дата принятия на баланс] > '2000-01-01' 
				  then '09.принят на баланс залог'
				  when bdeo.[Дата состоявшихся вторых торгов] > '2000-01-01' 
				  then '08.торги вторые состоялись'
				  when bdeo.[Дата ареста авто] > '2000-01-01'
				  then '07.арест залога произведен'
				  when bdeo.[Дата возбуждения ИП] > '2000-01-01'
				  then '06.испол.производство возбуждено'
				  when bdjp.dt_max_Receipt_IL is not null 
				  then '05.получен ИЛ'
				  when bdjp.dt_max_receipt_judgment is not null
				  then '04.2.получено решение суда'
				  when bdjp.dt_max_judgment is not null
				  then '04.1.вынесено решение суда'
				  when bdjp.dt_Court_Claim_Sending is not null
				  then '03.иск направлен в суд'
				  when bdjp.dt_max_submission_claim is not null
				  then '02.требование направлено должнику'
				  else '01.СП не стартовал'
				  end 'Стадия судебного производства' -- stage_Judicial_Proceeding
			--------------------------------------------------------------------------------------------------------------------------
			,coalesce(bdjp.dt_max_submission_claim,bbd.dt_fir_dpd_61_hs) 'Дата начала судебного производства' -- dt_pl_st_Judicial_Proceeding
			,coalesce(devdb.dbo.dt_st_month(bdjp.dt_max_submission_claim),devdb.dbo.dt_st_month(bbd.dt_fir_dpd_61_hs)) 'Месяц начала судебного производства' -- mn_pl_st_Judicial_Proceeding плановый месяц старта судебного процесса, либо это дата отправки ЗТ, либо наступление 61 дня ПЗ после окончания последних каникул
			,datepart(mm,coalesce(bdjp.dt_max_submission_claim,bbd.dt_fir_dpd_61_hs)) 'Порядковый номер месяца начала судебного производства' --  month_report
			,datepart(yy,coalesce(bdjp.dt_max_submission_claim,bbd.dt_fir_dpd_61_hs)) 'Год начала судебного производства' -- year_report
			--------------------------------------------------------------------------------------------------------------------------
			,case when bdjp.dt_max_submission_claim is null then 0 else 1 end 'Флаг отправки ЗТ' -- flag_submission_claim -- флаг, что зт клиенту направлено
			,bdjp.dt_max_submission_claim 'Дата отправки ЗТ' -- дата отправки зт клиенту
			,case when bdjp.dt_Court_Claim_Sending is null then 0 else 1 end 'Флаг подачи иска' -- flag_Court_Claim_Sending -- флаг, что иск направлен в суд
			,bdjp.dt_Court_Claim_Sending 'Дата подачи иска' -- дата отправки иска в суд
			,case when bdjp.dt_max_judgment is null then 0 else 1 end 'Флаг вынесения решения' -- flag_Receipt_Judgment -- флаг, что решение суда получено
			,bdjp.dt_max_judgment 'Дата вынесения решения' -- дата получения решения суда
			,case when bdjp.dt_max_receipt_judgment is null then 0 else 1 end 'Флаг получения решения' -- flag_Receipt_Judgment -- флаг, что решение суда получено
			,bdjp.dt_max_receipt_judgment 'Дата получения решения' -- дата получения решения суда
			,case when bdjp.dt_max_Receipt_IL is null then 0 else 1 end 'Флаг получения ИЛ' -- flag_Receipt_IL -- флаг, что ил получен
			,bdjp.dt_max_Receipt_IL 'Дата получения ИЛ' -- дата получения ил
			--------------------------------------------------------------------------------------------------------------------------
			,'Долг на старте судебного производства' = cast((select max(debt) from (VALUES (coalesce(jc.AmountJudgment,0))
																			, (coalesce(jp.amountclaim,0))
																			, (coalesce(bpr_1.principal_rest,bpr_2.principal_rest)))  AS value(debt)) as int) -- principal_rest_st_jp
			,'Текущий долг в рамках судебного производства' = case when bdc.Number is not null
												or (d.OverdueDays = 0 and coalesce(bhf.HasFreezing,0) != 1)
												or (d.OverdueDays = 0 and coalesce(bhf.HasFreezing,0) = 1 and kk.[дата платежа по графику] < cast(getdate() as date))
											then 0
											else cast((select max(debt) from (VALUES (coalesce(jc.AmountJudgment,0))
																			, (coalesce(jp.amountclaim,0))
																			, (coalesce(bpr_1.principal_rest,bpr_2.principal_rest)))  AS value(debt)) as int)
											end  -- principal_rest_td

			,'Возват долга за время судебного производства' = (cast((select max(debt) from (VALUES (coalesce(jc.AmountJudgment,0))
																			, (coalesce(jp.amountclaim,0))
																			, (coalesce(bpr_1.principal_rest,bpr_2.principal_rest)))  AS value(debt)) as int))
										-
										(case when bdc.Number is not null
													or (d.OverdueDays = 0 and coalesce(bhf.HasFreezing,0) != 1)
													or (d.OverdueDays = 0 and coalesce(bhf.HasFreezing,0) = 1 and kk.[дата платежа по графику] < cast(getdate() as date))
												then 0
												else cast((select max(debt) from (VALUES (coalesce(jc.AmountJudgment,0))
																				, (coalesce(jp.amountclaim,0))
																				, (coalesce(bpr_1.principal_rest,bpr_2.principal_rest)))  AS value(debt)) as int)
												end)
																
																-- od_recovery
			--------------------------------------------------------------------------------------------------------------------------
			,coalesce(bpjp.sum_pay_jp_all,0) 'Cash за время судебного производства' -- sum_pay_jp_all
			,coalesce(bpjp.sum_pay_submission_claim,0) 'Cash стадии Отправка требования' -- sum_pay_submission_claim
			,coalesce(bpjp.sum_pay_Court_Claim_Sending,0) 'Cash стадии Подача иска' -- sum_pay_Court_Claim_Sending
			,coalesce(bpjp.sum_pay_judgment,0) 'Cash стадии Вынесено решение' -- sum_pay_Receipt_Judgment
			,coalesce(bpjp.sum_pay_receipt_judgment,0) 'Cash стадии Получено решение' -- sum_pay_Receipt_Judgment
			,coalesce(bpjp.sum_pay_Receipt_IL,0) 'Cash стадии Получен ИЛ' -- sum_pay_Receipt_IL
			--------------------------------------------------------------------------------------------------------------------------
			,bcr.date_communication 'Дата последней результативной коммуникации'
			,bcr.manager 'ФИО сотрудника коммуникации'
			,bcr.communication_type_name 'Тип коммуникации'
			,bcr.communication_result_name 'Результат коммуникации'
			,bcr.commentary 'Комментарий по результату коммуникации'
			--------------------------------------------------------------------------------------------------------------------------
			,bregc.RegionPresence 'Регион постоянной регистрации'
			,bregc.ActualRegion 'Регион фактического проживания'
			,case when bteo.il_type > 1 then '1. есть ИЛ после решения суда'
				  when bteo.il_type = 1 then '2. есть ИЛ только на обечпечительные меры'
				  else '3. нет ИЛ никакого типа' end 'Тип ИЛ'
	
	INTO devdb.dbo.say_log_jp_for_kk
	from devdb.dbo.say_log_dogovora_kk					kk
	join stg._Collection.Deals							d on d.Number = kk.[номер договора]
	left join stg._Collection.customers					c on c.id = d.IdCustomer
	left join stg._Collection.collectingStage			cs on cs.id = d.StageId
	left join #Judicial_Proceeding						jp on jp.DealId = d.Id
	left join #Judicial_Claims							jc on jc.JudicialProceedingId = jp.Id
	left join #base_judgment							bjm on bjm.Number = d.Number
	left join #base_receipt_judgmen						brjm on bjm.Number = d.Number
	left join #Enforcement_Orders						eo on eo.DealId = d.Id
	left join #base_problematic_status					bps on bps.Number = d.Number
	left join #base_deal_closed							bdc on bdc.Number = d.Number
	left join #base_deal_denied							bdd on bdd.Number = d.Number
	left join #base_bucket_dpd_max_						bbd on bbd.Number = d.Number
	left join #base_principal_rest						bpr_1 on bpr_1.external_id = d.Number
																 and bpr_1.r_date = coalesce(jp.dt_max_submission_claim,bbd.dt_fir_dpd_61_hs)
	left join #base_principal_rest						bpr_2 on bpr_2.external_id = d.Number
																 and bpr_2.r_date = (select max(r_date) from #base_principal_rest)
	left join #base_dt_closed							bdtc on bdtc.number = d.number 
	left join #base_HasFreezing							bhf on bhf.external_id = d.Number
	left join #base_dt_jp								bdjp on bdjp.Number = d.Number
	left join #base_pay_jp_stage						bpjp on bpjp.Number = d.Number
	left join #base_communication_result				bcr on bcr.number = d.Number
	left join #base_dt_eo								bdeo on bdeo.number = d.Number
	left join #base_region_customer						bregc on bregc.IdCustomer = c.id
	left join #base_type_eo								bteo on bteo.number = d.Number

	where 1 = 1
			and kk.[дата время состовления отчёта] = (select max([дата время состовления отчёта]) from devdb.dbo.say_log_dogovora_kk)
			-----------------------------------------------------------------------------
			/*
			ниже условие, по которому отбираются договора для дальнейшей оценки СП и ИП по КК
			1. исключаются договора, где в решение суда указано "Отказать" - это документы о кредите без подписи клиента
			2. исключаются незакрытые договора, со статусом клиент: 'Смерть подтвержденная','Банкрот подтверждённый','Банкрот неподтверждённый'
			3. исключаются договора, где дата отправки ЗТ позднее закрытия договора
			4. включаются все договора, кроме п.1, п.2, п.3, по которым было отправлено требование
			5. 
				5.1 договора, по которым после окончания последних КК срок просрочки был не менее 61 дня
				5.2 и такая просрочка возникла после 2020 году
				5.3 и на сегодня есть любой срок просрочки
				5.4 и договор не закрыт
			*/
			-----------------------------------------------------------------------------
			and (case when bdd.Number is not null
					  then 0
					  when bps.Number is not null
						   and bdc.Number is null
					  then 0
					  when jp.dt_max_submission_claim >= bdtc.dt_closed
					  then 0
					  when jp.id is not null 
					  then 1
					  when dpd_61_hs is not null
						   and datepart(yy,dt_fir_dpd_61_hs) > 2020
						   and d.OverdueDays > 0
						   and bdc.Number is null
					  then 1
					  else 0 end) = 1 -- база для возможной отправки требований, если в истории была просрочка более 60 дней и сейчас есть просрочка или требование было отправлено , то включается в базу договоров с возможностью отправки требования
	;

---------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
--для винтажнего анализа
-------------------------------------------------------------------------------------
	--сбор платежей для винтажа
	drop table if exists #sum_pay_for_vint;
	select 
			bcmr.external_id
			,devdb.dbo.dt_st_month(bcmr.cdate) mn_pay
			,sum(bcmr.total_CF) sum_pay -- cash
	into #sum_pay_for_vint
	from dwh_new.dbo.stat_v_balance2			bcmr
	left join (select Number
						,[Дата начала судебного производства]
				from devdb.dbo.say_log_jp_for_kk
				where r_date = (select max(r_date) from devdb.dbo.say_log_jp_for_kk))aa on aa.Number = bcmr.external_id
	where 1 = 1
			and bcmr.total_CF > 0
			and bcmr.cdate >= aa.[Дата начала судебного производства]
	group by 
			bcmr.external_id
			,devdb.dbo.dt_st_month(bcmr.cdate)
	;

---------------------------------------------------------------------------------------------------------------------------------------------
	drop table if exists #base_vintage_analysis;
	select jfk.number
			,jfk.[Дата отправки ЗТ] dt_st_Judicial_Proceeding
			,devdb.dbo.dt_st_month(jfk.[Дата отправки ЗТ]) mn_rp_Judicial_Proceeding
			,1 mob
			,[Долг на старте судебного производства] debt
	into #base_vintage_analysis
	from devdb.dbo.say_log_jp_for_kk jfk
	where 1 = 1
			and jfk.r_date = (select max(r_date) from devdb.dbo.say_log_jp_for_kk)
			and jfk.[Флаг отправки ЗТ] = 1
	;

	DECLARE @i int = 1;
	WHILE (select max(mn_rp_Judicial_Proceeding) 
			from #base_vintage_analysis 
			where dt_st_Judicial_Proceeding = (select min(dt_st_Judicial_Proceeding) from #base_vintage_analysis)
			) < devdb.dbo.dt_st_month(getdate())
		BEGIN
			insert #base_vintage_analysis (number,dt_st_Judicial_Proceeding,mn_rp_Judicial_Proceeding,mob,debt)
			select  number
					,dt_st_Judicial_Proceeding
					,dateadd(mm,1,mn_rp_Judicial_Proceeding)
					,mob + 1
					,debt
			from #base_vintage_analysis
			where mob = @i
		SET @i = @i + 1
		END
	;

	delete
	from #base_vintage_analysis
	where mn_rp_Judicial_Proceeding > getdate()
	;

	drop table if exists devdb.dbo.say_log_jp_for_kk_for_vintag;
	select distinct
			bva.number
			,devdb.dbo.dt_st_month(bva.dt_st_Judicial_Proceeding) dt_st_Judicial_Proceeding
			,bva.mn_rp_Judicial_Proceeding
			,bva.mob
			,bva.debt
			,coalesce(sum(bp.sum_pay) over (partition by bva.number, bva.mob) ,0)  sum_pay
			,coalesce(sum(bp.sum_pay) over (partition by bva.number order by bva.mob 
											 rows between unbounded preceding and current row) ,0) as sum_pay_cumulatively
			,case when coalesce(sum(bp.sum_pay) over (partition by bva.number order by bva.mob 
											 rows between unbounded preceding and current row) ,0) / bva.debt > 1
				  then 1
				  else coalesce(sum(bp.sum_pay) over (partition by bva.number order by bva.mob 
											 rows between unbounded preceding and current row) ,0) / bva.debt
				  end percent_recovery
	into devdb.dbo.say_log_jp_for_kk_for_vintag
	from #base_vintage_analysis			bva
	left join #sum_pay_for_vint			bp on bp.external_id = bva.number
											  and bp.mn_pay = bva.mn_rp_Judicial_Proceeding
	;

--drop table if exists riskdwh.[cm\d.timin].KK_report_list_of_agents;
--drop table if exists Analytics.dbo.KK_report_list_of_agents;

delete from Analytics.dbo.KK_report_list_of_agents

insert into Analytics.dbo.KK_report_list_of_agents


	select
t.[номер договора],
ag.agent_name,
e.LastName+' '+e.FirstName+' '+e.MiddleName fio_claimant,
case when ag.agent_name is null then 0 else 1 end as agency_flag

--into riskdwh.[cm\d.timin].KK_report_list_of_agents
--into Analytics.dbo.KK_report_list_of_agents


from
devDB.dbo.say_log_dogovora_kk t
join stg._Collection.Deals d on d.number = t.[номер договора]
join stg._collection.customers c on c.id = d.idcustomer
left join #base_lost_claimant_id blc on blc.ObjectId = d.idcustomer
left join stg._collection.Employee e on blc.claimantid=e.id

left join dwh_new.dbo.agent_credits ag on t.[номер договора]=ag.external_id and ag.fact_end_date is null
where cast(t.[дата время состовления отчёта] as date) =cast(getdate() as date)

--exec log_email 'Таблица для КК собрана', 'p.ilin@techmoney.ru; d.timin@carmoney.ru; d.bembiev@techmoney.ru'
exec log_email 'Таблица для КК собрана', 'd.timin@carmoney.ru; d.bembiev@techmoney.ru'

end